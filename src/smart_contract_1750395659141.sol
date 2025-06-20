Okay, here is a Solidity smart contract called "QuantumLock". The concept is based on defining potential future "states" with associated actions, creating "commitments" to transition to these states under specific triggers, and holding assets locked until a commitment's trigger is met. It blends ideas of programmable asset release, conditional logic, and time/event-based triggers.

It aims for creativity by allowing flexible state definitions with multiple actions (transferring different assets or calling other contracts) and different trigger types (time, manual, dependent on another commitment's state). It includes features like asset assignment to commitments (though assets are pooled internally), dynamic state definitions, and permissioned triggering.

It's designed to be more complex than a simple vault or multi-sig, incorporating structured data for states and commitments and a state transition logic based on configurable triggers.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Helper to receive ERC721
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Good practice for external calls

/**
 * @title QuantumLock
 * @dev A smart contract for defining conditional future states and locking assets within "commitments"
 *      that are released upon meeting a specific trigger condition.
 *
 * Outline:
 * 1. Contract Overview & Concept
 * 2. Events
 * 3. Enums (TriggerType, ActionType)
 * 4. Structs (Trigger, Action, StateDefinition, AssignedAsset, Commitment)
 * 5. State Variables
 * 6. Modifiers
 * 7. Constructor
 * 8. Core Functionality (State Definitions, Commitments, Triggering)
 * 9. Asset Management (Deposits, Assignment, Rescue)
 * 10. Query Functions
 * 11. Access Control & Ownership
 * 12. ERC721 Receiver Hook
 *
 * Function Summary:
 * - State Definition Management: Functions to add, update, remove state definitions, and control their activation.
 * - Commitment Management: Functions to create, cancel commitments, and assign assets to them.
 * - Triggering: Functions to attempt triggering a commitment based on its defined conditions.
 * - Asset Handling: Functions to deposit ETH, ERC20, ERC721, assign them to commitments, and owner rescue for unassigned assets.
 * - Querying: Functions to retrieve details about states, commitments, and contract balances.
 * - Access Control: Standard Ownable functions and setting a specific address for manual triggers.
 * - ERC721 Receiving: Hook to accept ERC721 transfers.
 */
contract QuantumLock is Ownable, ERC721Holder, ReentrancyGuard {
    using Address for address;

    // --- 2. Events ---
    event StateDefinitionAdded(uint256 indexed stateId, string description);
    event StateDefinitionUpdated(uint256 indexed stateId, string description);
    event StateDefinitionRemoved(uint256 indexed stateId);
    event StateActivationStatusChanged(uint256 indexed stateId, bool isActive);

    event CommitmentCreated(uint256 indexed commitmentId, uint256 indexed stateId, address indexed creator);
    event CommitmentCancelled(uint256 indexed commitmentId, address indexed canceller);
    event AssetsAssignedToCommitment(uint256 indexed commitmentId, address indexed tokenAddress, uint256 amountOrId, bool isERC721);
    event AssetsRemovedFromCommitment(uint256 indexed commitmentId, address indexed tokenAddress, uint256 amountOrId, bool isERC721);
    event CommitmentTriggered(uint256 indexed commitmentId, uint256 indexed stateId, address indexed triggerCaller, uint256 timestamp);

    event ETHDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed depositor, address indexed token, uint256 indexed tokenId);

    event ETHRescued(address indexed recipient, uint256 amount);
    event ERC20Rescued(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Rescued(address indexed token, uint256 indexed tokenId, address indexed recipient);

    // --- 3. Enums ---
    enum TriggerType { Time, Manual, DependentState }
    enum ActionType { TransferETH, TransferERC20, TransferERC721, CallContract }

    // --- 4. Structs ---

    struct Trigger {
        TriggerType triggerType;
        uint256 timestamp;         // For Time trigger
        uint256 requiredStateId;   // For DependentState trigger
        address permissionedAddress; // For Manual trigger (if different from owner/creator)
    }

    struct Action {
        ActionType actionType;
        address payable recipient;    // Recipient for transfers, target for CallContract
        address tokenAddress;       // Token address for ERC20/ERC721
        uint256 amountOrTokenId;    // Amount for ETH/ERC20, tokenId for ERC721
        bytes callData;             // Data for CallContract
    }

    struct StateDefinition {
        uint256 id;
        string description;
        Trigger trigger;
        Action[] actions; // Sequence of actions executed upon trigger
        bool isActive;    // Can new commitments be created for this state?
    }

    // Tracks assets *conceptually assigned* to a commitment.
    // The contract holds assets in a pool; assignment is for user intent and queryability.
    struct AssignedAsset {
        address tokenAddress; // Address(0) for ETH
        uint256 amountOrTokenId;
        bool isERC721;
    }

    struct Commitment {
        uint256 id;
        uint256 stateId;         // Reference to the StateDefinition
        address creator;         // Address that created the commitment
        AssignedAsset[] assignedAssets; // Assets conceptually assigned to this commitment
        bool triggered;          // Has this commitment been triggered?
        uint256 triggeredTimestamp; // When it was triggered
    }

    // --- 5. State Variables ---

    uint256 private _nextStateId = 1;
    mapping(uint256 => StateDefinition) public stateDefinitions;
    mapping(uint256 => bool) private _stateExists; // To track if an ID is used
    mapping(uint256 => uint256) private _stateCommitmentCount; // How many active commitments use a state

    uint256 private _nextCommitmentId = 1;
    mapping(uint256 => Commitment) public commitments;
    mapping(uint256 => bool) private _commitmentExists; // To track if an ID is used

    address public manualTriggerPermissionedAddress;

    // --- 6. Modifiers ---

    modifier onlyManualTriggerPermissioned() {
        require(msg.sender == manualTriggerPermissionedAddress, "QuantumLock: Caller not manual trigger permissioned");
        _;
    }

    // --- 7. Constructor ---

    constructor(address initialManualTriggerPermissioned) Ownable(msg.sender) {
        manualTriggerPermissionedAddress = initialManualTriggerPermissioned;
    }

    // --- 8. Core Functionality ---

    /**
     * @dev Adds a new State Definition. Only callable by the owner.
     * @param description A brief description of the state.
     * @param trigger The trigger condition for this state.
     * @param actions An array of actions to perform when the state is triggered.
     * @return The ID of the newly added state definition.
     */
    function addStateDefinition(
        string memory description,
        Trigger memory trigger,
        Action[] memory actions
    ) external onlyOwner returns (uint256) {
        uint256 newStateId = _nextStateId++;
        require(!_stateExists[newStateId], "QuantumLock: State ID already exists"); // Should not happen with _nextStateId logic, but safe check

        // Basic validation for triggers and actions (can be extended)
        if (trigger.triggerType == TriggerType.DependentState) {
             // Dependent state must exist and not be the new state itself
            require(_stateExists[trigger.requiredStateId] && trigger.requiredStateId != newStateId, "QuantumLock: Invalid dependent state ID");
        }
         // Add more action validation if necessary (e.g., recipient != address(0))

        stateDefinitions[newStateId] = StateDefinition({
            id: newStateId,
            description: description,
            trigger: trigger,
            actions: actions,
            isActive: true // New states are active by default
        });
        _stateExists[newStateId] = true;

        emit StateDefinitionAdded(newStateId, description);
        return newStateId;
    }

    /**
     * @dev Updates an existing State Definition. Only callable by the owner.
     *      Cannot update if there are active commitments using this state.
     * @param stateId The ID of the state definition to update.
     * @param description The new description.
     * @param trigger The new trigger condition.
     * @param actions The new array of actions.
     */
    function updateStateDefinition(
        uint256 stateId,
        string memory description,
        Trigger memory trigger,
        Action[] memory actions
    ) external onlyOwner {
        require(_stateExists[stateId], "QuantumLock: State ID does not exist");
        require(_stateCommitmentCount[stateId] == 0, "QuantumLock: State has active commitments, cannot update");

        // Basic validation
         if (trigger.triggerType == TriggerType.DependentState) {
             // Dependent state must exist and not be the state being updated
            require(_stateExists[trigger.requiredStateId] && trigger.requiredStateId != stateId, "QuantumLock: Invalid dependent state ID");
        }
        // Add more action validation

        stateDefinitions[stateId].description = description;
        stateDefinitions[stateId].trigger = trigger;
        stateDefinitions[stateId].actions = actions; // This replaces the actions array

        emit StateDefinitionUpdated(stateId, description);
    }

    /**
     * @dev Removes a State Definition. Only callable by the owner.
     *      Cannot remove if there are active commitments using this state.
     * @param stateId The ID of the state definition to remove.
     */
    function removeStateDefinition(uint256 stateId) external onlyOwner {
        require(_stateExists[stateId], "QuantumLock: State ID does not exist");
        require(_stateCommitmentCount[stateId] == 0, "QuantumLock: State has active commitments, cannot remove");

        delete stateDefinitions[stateId];
        _stateExists[stateId] = false;
        // No need to reset _stateCommitmentCount as it's already 0

        emit StateDefinitionRemoved(stateId);
    }

    /**
     * @dev Sets the activation status of a State Definition. Only callable by the owner.
     *      Inactive states cannot be used to create new commitments.
     * @param stateId The ID of the state definition.
     * @param isActive The new activation status.
     */
    function setStateActivationStatus(uint256 stateId, bool isActive) external onlyOwner {
        require(_stateExists[stateId], "QuantumLock: State ID does not exist");
        require(stateDefinitions[stateId].isActive != isActive, "QuantumLock: State already in desired status");

        stateDefinitions[stateId].isActive = isActive;
        emit StateActivationStatusChanged(stateId, isActive);
    }

    /**
     * @dev Creates a new Commitment based on an active State Definition.
     * @param stateId The ID of the State Definition to use.
     * @return The ID of the newly created commitment.
     */
    function createCommitment(uint256 stateId) external returns (uint256) {
        require(_stateExists[stateId], "QuantumLock: State ID does not exist");
        require(stateDefinitions[stateId].isActive, "QuantumLock: State Definition is not active");

        uint256 newCommitmentId = _nextCommitmentId++;
        require(!_commitmentExists[newCommitmentId], "QuantumLock: Commitment ID already exists"); // Should not happen

        commitments[newCommitmentId] = Commitment({
            id: newCommitmentId,
            stateId: stateId,
            creator: msg.sender,
            assignedAssets: new AssignedAsset[](0), // Starts with no assigned assets
            triggered: false,
            triggeredTimestamp: 0
        });
        _commitmentExists[newCommitmentId] = true;
        _stateCommitmentCount[stateId]++;

        emit CommitmentCreated(newCommitmentId, stateId, msg.sender);
        return newCommitmentId;
    }

    /**
     * @dev Cancels a Commitment. Callable by the creator or the owner.
     *      Can only be cancelled if it hasn't been triggered.
     *      Note: Assets assigned to the commitment are NOT automatically returned upon cancellation.
     *      They remain in the contract and must be rescued by the owner if intended.
     * @param commitmentId The ID of the commitment to cancel.
     */
    function cancelCommitment(uint256 commitmentId) external {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        Commitment storage commitment = commitments[commitmentId];
        require(msg.sender == commitment.creator || msg.sender == owner(), "QuantumLock: Only creator or owner can cancel");
        require(!commitment.triggered, "QuantumLock: Commitment already triggered");

        // Decrement the count for the state definition
        _stateCommitmentCount[commitment.stateId]--;

        // Mark as triggered to prevent re-triggering (simpler than deleting)
        commitment.triggered = true; // Use triggered flag to mark as cancelled/inactive
        commitment.triggeredTimestamp = block.timestamp; // Record cancellation time

        // Clear assigned assets data for gas efficiency on reads (optional, but good practice)
        delete commitment.assignedAssets;

        // Note: Assigned assets remain in the contract. Owner must use rescue functions.

        emit CommitmentCancelled(commitmentId, msg.sender);
    }


    /**
     * @dev Assigns assets (already held by the contract) to a specific commitment conceptually.
     *      This function does *not* transfer assets *into* the contract.
     *      It adds metadata to the commitment struct indicating which assets are intended for it.
     *      Requires the assets to be present in the contract's balance *before* calling.
     *      Callable by the commitment creator or owner.
     * @param commitmentId The ID of the commitment.
     * @param tokenAddress The address of the token (address(0) for ETH).
     * @param amountOrId The amount for ETH/ERC20, or the tokenId for ERC721.
     * @param isERC721 True if it's an ERC721 token, false otherwise (and for ETH/ERC20).
     */
    function addAssetsToCommitment(uint256 commitmentId, address tokenAddress, uint256 amountOrId, bool isERC721) external {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        Commitment storage commitment = commitments[commitmentId];
        require(msg.sender == commitment.creator || msg.sender == owner(), "QuantumLock: Only creator or owner can assign assets");
        require(!commitment.triggered, "QuantumLock: Commitment already triggered");

        // Note: This function doesn't verify if the contract *actually* holds these specific assets.
        // That check happens during the trigger attempt. This is merely metadata.

        commitment.assignedAssets.push(AssignedAsset({
            tokenAddress: tokenAddress,
            amountOrTokenId: amountOrId,
            isERC721: isERC721
        }));

        emit AssetsAssignedToCommitment(commitmentId, tokenAddress, amountOrId, isERC721);
    }

     /**
     * @dev Removes the *last* assigned asset from a commitment's metadata.
     *      This function does *not* transfer assets *out* of the contract.
     *      Only callable by the commitment creator or owner.
     *      Only removes the last entry for simplicity.
     * @param commitmentId The ID of the commitment.
     */
    function removeLastAssignedAssetFromCommitment(uint256 commitmentId) external {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        Commitment storage commitment = commitments[commitmentId];
        require(msg.sender == commitment.creator || msg.sender == owner(), "QuantumLock: Only creator or owner can remove assigned assets");
        require(!commitment.triggered, "QuantumLock: Commitment already triggered");
        require(commitment.assignedAssets.length > 0, "QuantumLock: No assets assigned to remove");

        AssignedAsset memory removedAsset = commitment.assignedAssets[commitment.assignedAssets.length - 1];
        commitment.assignedAssets.pop(); // Remove the last element

        emit AssetsRemovedFromCommitment(commitmentId, removedAsset.tokenAddress, removedAsset.amountOrTokenId, removedAsset.isERC721);
    }


    /**
     * @dev Internal helper to check if a commitment's trigger condition is met.
     * @param commitment The commitment struct.
     * @param stateDef The state definition struct linked to the commitment.
     * @return bool True if the trigger is met, false otherwise.
     */
    function _isTriggerMet(Commitment memory commitment, StateDefinition memory stateDef) internal view returns (bool) {
        Trigger memory trigger = stateDef.trigger;

        if (trigger.triggerType == TriggerType.Time) {
            return block.timestamp >= trigger.timestamp;
        } else if (trigger.triggerType == TriggerType.Manual) {
            // Manual triggers are checked explicitly in triggerManualCommitment
            return false; // Cannot be met by generic attemptTriggerCommitment
        } else if (trigger.triggerType == TriggerType.DependentState) {
            // Check if the required dependent commitment (using the required state ID) is triggered
            // This requires iterating through commitments to find one linked to the required state ID
            // For simplicity, let's assume the requiredStateId in the trigger refers to
            // a *commitment ID* that needs to be triggered. This is simpler to check.
            // **Revised concept**: DependentState trigger requires a *specific other commitment* to be triggered.
            // The `requiredStateId` field will store the `commitmentId` that must be triggered.
            uint256 requiredCommitmentId = trigger.requiredStateId; // Using requiredStateId field for commitmentId
            if (!_commitmentExists[requiredCommitmentId]) return false; // Dependent commitment must exist
            return commitments[requiredCommitmentId].triggered;
        }
        return false; // Should not happen
    }

    /**
     * @dev Attempts to trigger a commitment if its non-manual trigger condition is met.
     *      Callable by anyone (gas cost paid by caller).
     * @param commitmentId The ID of the commitment to attempt triggering.
     */
    function attemptTriggerCommitment(uint256 commitmentId) external nonReentrant {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        Commitment storage commitment = commitments[commitmentId];
        require(!commitment.triggered, "QuantumLock: Commitment already triggered");

        require(_stateExists[commitment.stateId], "QuantumLock: Commitment target state does not exist");
        StateDefinition storage stateDef = stateDefinitions[commitment.stateId];

        require(stateDef.trigger.triggerType != TriggerType.Manual, "QuantumLock: Use triggerManualCommitment for this type");

        // Check if trigger is met based on definition (Time or DependentState)
        require(_isTriggerMet(commitment, stateDef), "QuantumLock: Trigger condition not met");

        _executeCommitmentActions(commitmentId, stateDef.actions);

        // Mark as triggered after actions succeed
        commitment.triggered = true;
        commitment.triggeredTimestamp = block.timestamp;
        _stateCommitmentCount[commitment.stateId]--; // Decrement active count

        // Clear assigned assets data
        delete commitment.assignedAssets;

        emit CommitmentTriggered(commitmentId, commitment.stateId, msg.sender, block.timestamp);
    }

    /**
     * @dev Triggers a commitment with a Manual trigger type.
     *      Callable only by the address set as `manualTriggerPermissionedAddress`.
     * @param commitmentId The ID of the commitment to trigger.
     */
    function triggerManualCommitment(uint256 commitmentId) external onlyManualTriggerPermissioned nonReentrant {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        Commitment storage commitment = commitments[commitmentId];
        require(!commitment.triggered, "QuantumLock: Commitment already triggered");

        require(_stateExists[commitment.stateId], "QuantumLock: Commitment target state does not exist");
        StateDefinition storage stateDef = stateDefinitions[commitment.stateId];

        require(stateDef.trigger.triggerType == TriggerType.Manual, "QuantumLock: Commitment trigger is not Manual type");

        _executeCommitmentActions(commitmentId, stateDef.actions);

        // Mark as triggered after actions succeed
        commitment.triggered = true;
        commitment.triggeredTimestamp = block.timestamp;
        _stateCommitmentCount[commitment.stateId]--; // Decrement active count

        // Clear assigned assets data
        delete commitment.assignedAssets;

        emit CommitmentTriggered(commitmentId, commitment.stateId, msg.sender, block.timestamp);
    }

     /**
     * @dev Internal function to execute the actions defined for a state transition.
     *      Performs transfers and external calls. Reverts if any action fails.
     *      Uses Checks-Effects-Interactions pattern where possible (transfers before arbitrary calls).
     * @param commitmentId The ID of the commitment being triggered (for context/logging).
     * @param actions The array of actions to execute.
     */
    function _executeCommitmentActions(uint256 commitmentId, Action[] memory actions) internal {
         // Before executing, check if contract has sufficient *total* assets for all actions combined.
         // This is a simplified check. A more robust contract might track assets per commitment.
         // Here, we just ensure the contract has enough *now* for the required transfers.
         // This assumes assignedAssets metadata is just for user info, not strict enforcement.
         // The actions define the *actual* transfers from the contract pool.
        for (uint i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            if (action.actionType == ActionType.TransferETH) {
                require(address(this).balance >= action.amountOrTokenId, "QuantumLock: Insufficient ETH balance for action");
                require(action.recipient != address(0), "QuantumLock: ETH recipient cannot be zero address");
            } else if (action.actionType == ActionType.TransferERC20) {
                require(action.tokenAddress != address(0), "QuantumLock: ERC20 token address cannot be zero address");
                require(action.recipient != address(0), "QuantumLock: ERC20 recipient cannot be zero address");
                // Simplified check: Does contract have *at least* this much of the token?
                require(IERC20(action.tokenAddress).balanceOf(address(this)) >= action.amountOrTokenId, "QuantumLock: Insufficient ERC20 balance for action");
            } else if (action.actionType == ActionType.TransferERC721) {
                 require(action.tokenAddress != address(0), "QuantumLock: ERC721 token address cannot be zero address");
                 require(action.recipient != address(0), "QuantumLock: ERC721 recipient cannot be zero address");
                 // Check if the contract owns the specific token ID
                 require(IERC721(action.tokenAddress).ownerOf(action.amountOrTokenId) == address(this), "QuantumLock: Contract does not own ERC721 token ID for action");
            } else if (action.actionType == ActionType.CallContract) {
                 require(action.recipient.code.length > 0, "QuantumLock: Call target is not a contract");
            }
        }

        // Execute actions sequentially. Reverts if any action fails.
        for (uint i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            if (action.actionType == ActionType.TransferETH) {
                (bool success, ) = action.recipient.call{value: action.amountOrTokenId}("");
                require(success, "QuantumLock: ETH transfer failed");
            } else if (action.actionType == ActionType.TransferERC20) {
                // Using safeTransfer might be better, but standard transfer is often sufficient
                // and slightly less gas. Assume recipient is not malicious here or use safetransfer.
                bool success = IERC20(action.tokenAddress).transfer(action.recipient, action.amountOrTokenId);
                require(success, "QuantumLock: ERC20 transfer failed");
            } else if (action.actionType == ActionType.TransferERC721) {
                 // Using safeTransferFrom is recommended for ERC721
                 IERC721(action.tokenAddress).safeTransferFrom(address(this), action.recipient, action.amountOrTokenId);
            } else if (action.actionType == ActionType.CallContract) {
                (bool success, ) = action.recipient.call(action.callData);
                require(success, "QuantumLock: External contract call failed");
            }
        }
    }


    // --- 9. Asset Management ---

    // Receive ETH directly
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    // Fallback function to accept ETH if no other function matches (less common with receive())
    fallback() external payable {
       emit ETHDeposited(msg.sender, msg.value);
    }


    /**
     * @dev Deposits ERC20 tokens into the contract. Requires prior approval.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount) external {
        require(tokenAddress != address(0), "QuantumLock: Token address cannot be zero");
        require(amount > 0, "QuantumLock: Amount must be greater than zero");
        IERC20 token = IERC20(tokenAddress);
        // TransferFrom requires the caller to have approved this contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "QuantumLock: ERC20 transfer failed");
        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Deposits an ERC721 token into the contract. Requires prior approval or `safeTransferFrom` call by user.
     *      The user should call `approve(contractAddress, tokenId)` then this function,
     *      OR call `safeTransferFrom(from, contractAddress, tokenId)` from their wallet.
     *      This function specifically handles the pull mechanism using `transferFrom`.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address tokenAddress, uint256 tokenId) external {
         require(tokenAddress != address(0), "QuantumLock: Token address cannot be zero");
         IERC721 token = IERC721(tokenAddress);
         // TransferFrom requires the caller to have approved this contract for the token ID
         token.transferFrom(msg.sender, address(this), tokenId);
         // ERC721Holder will handle the onERC721Received hook automatically
         emit ERC721Deposited(msg.sender, tokenAddress, tokenId);
    }

    /**
     * @dev Allows the owner to rescue stranded ETH that is not conceptually assigned
     *      to any active commitment. This is a broad rescue function; owner should
     *      exercise caution not to withdraw funds needed for active commitments.
     * @param amount The amount of ETH to rescue.
     * @param recipient The address to send the ETH to.
     */
    function rescueETH(uint256 amount, address payable recipient) external onlyOwner {
         require(amount > 0, "QuantumLock: Rescue amount must be greater than zero");
         require(address(this).balance >= amount, "QuantumLock: Not enough ETH in contract");
         require(recipient != address(0), "QuantumLock: Recipient cannot be zero address");

         // Note: This does NOT check if the rescued ETH is needed for active commitments.
         // Owner must manually verify assigned assets vs contract balance.

         (bool success, ) = recipient.call{value: amount}("");
         require(success, "QuantumLock: ETH rescue failed");
         emit ETHRescued(recipient, amount);
    }

    /**
     * @dev Allows the owner to rescue stranded ERC20 tokens that are not conceptually assigned
     *      to any active commitment. Owner must exercise caution.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to rescue.
     * @param recipient The address to send the tokens to.
     */
    function rescueERC20(address tokenAddress, uint256 amount, address recipient) external onlyOwner {
         require(tokenAddress != address(0), "QuantumLock: Token address cannot be zero");
         require(amount > 0, "QuantumLock: Rescue amount must be greater than zero");
         require(recipient != address(0), "QuantumLock: Recipient cannot be zero address");
         IERC20 token = IERC20(tokenAddress);

         // Note: This does NOT check if the rescued tokens are needed for active commitments.
         // Owner must manually verify assigned assets vs contract balance.
         require(token.balanceOf(address(this)) >= amount, "QuantumLock: Not enough ERC20 tokens in contract");

         bool success = token.transfer(recipient, amount);
         require(success, "QuantumLock: ERC20 rescue failed");
         emit ERC20Rescued(tokenAddress, recipient, amount);
    }

    /**
     * @dev Allows the owner to rescue a specific stranded ERC721 token ID that is not conceptually assigned
     *      to any active commitment. Owner must exercise caution.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token to rescue.
     * @param recipient The address to send the token to.
     */
    function rescueERC721(address tokenAddress, uint256 tokenId, address recipient) external onlyOwner {
         require(tokenAddress != address(0), "QuantumLock: Token address cannot be zero");
         require(recipient != address(0), "QuantumLock: Recipient cannot be zero address");
         IERC721 token = IERC721(tokenAddress);

         // Note: This does NOT check if the rescued token is needed for active commitments.
         // Owner must manually verify assigned assets vs contract holdings.
         require(token.ownerOf(tokenId) == address(this), "QuantumLock: Contract does not own the ERC721 token ID");

         token.safeTransferFrom(address(this), recipient, tokenId);
         emit ERC721Rescued(tokenAddress, tokenId, recipient);
    }

    // --- 10. Query Functions ---

    /**
     * @dev Gets the count of all state definitions created.
     * @return uint256 The total number of state definitions.
     */
    function getStateCount() external view returns (uint256) {
         return _nextStateId - 1; // Since we start from 1
    }

     /**
     * @dev Gets the count of active commitments for a given state definition ID.
     * @param stateId The ID of the state definition.
     * @return uint256 The number of active commitments using this state.
     */
    function getActiveCommitmentCountForState(uint256 stateId) external view returns (uint256) {
         require(_stateExists[stateId], "QuantumLock: State ID does not exist");
         return _stateCommitmentCount[stateId];
    }

    /**
     * @dev Gets the count of all commitments created.
     * @return uint256 The total number of commitments.
     */
    function getCommitmentCount() external view returns (uint256) {
         return _nextCommitmentId - 1; // Since we start from 1
    }

    /**
     * @dev Gets the creator of a specific commitment.
     * @param commitmentId The ID of the commitment.
     * @return address The creator's address.
     */
    function getCommitmentCreator(uint256 commitmentId) external view returns (address) {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        return commitments[commitmentId].creator;
    }

    /**
     * @dev Gets the target state ID for a specific commitment.
     * @param commitmentId The ID of the commitment.
     * @return uint256 The target state ID.
     */
    function getCommitmentTargetState(uint256 commitmentId) external view returns (uint256) {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        return commitments[commitmentId].stateId;
    }

    /**
     * @dev Gets the triggered status of a specific commitment.
     * @param commitmentId The ID of the commitment.
     * @return bool True if the commitment has been triggered or cancelled.
     */
    function getCommitmentStatus(uint256 commitmentId) external view returns (bool) {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        return commitments[commitmentId].triggered;
    }

     /**
     * @dev Gets the timestamp when a commitment was triggered or cancelled.
     * @param commitmentId The ID of the commitment.
     * @return uint256 The timestamp, or 0 if not triggered/cancelled.
     */
    function getCommitmentTriggeredTimestamp(uint256 commitmentId) external view returns (uint256) {
        require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
        return commitments[commitmentId].triggeredTimestamp;
    }

     /**
     * @dev Gets the details of a specific state definition.
     *      Note: Retrieving large arrays like `actions` might hit gas limits for read calls.
     * @param stateId The ID of the state definition.
     * @return StateDefinition The state definition struct.
     */
    function getStateDefinition(uint256 stateId) external view returns (StateDefinition memory) {
         require(_stateExists[stateId], "QuantumLock: State ID does not exist");
         return stateDefinitions[stateId];
     }

    /**
     * @dev Gets the details of a specific commitment.
     *      Note: Retrieving large arrays like `assignedAssets` might hit gas limits for read calls.
     * @param commitmentId The ID of the commitment.
     * @return Commitment The commitment struct.
     */
    function getCommitment(uint256 commitmentId) external view returns (Commitment memory) {
         require(_commitmentExists[commitmentId], "QuantumLock: Commitment ID does not exist");
         return commitments[commitmentId];
     }


    /**
     * @dev Checks the contract's ETH or ERC20 balance.
     * @param tokenAddress The address of the token (address(0) for ETH).
     * @return uint256 The balance.
     */
    function getContractAssetBalance(address tokenAddress) external view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
    }

     /**
     * @dev Checks if the contract owns a specific ERC721 token.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token.
     * @return bool True if the contract owns the token.
     */
    function doesContractOwnNFT(address tokenAddress, uint256 tokenId) external view returns (bool) {
         require(tokenAddress != address(0), "QuantumLock: Token address cannot be zero");
         try IERC721(tokenAddress).ownerOf(tokenId) returns (address owner) {
             return owner == address(this);
         } catch {
             // ownerOf might revert if token ID doesn't exist or tokenAddress is not ERC721
             return false;
         }
    }

    /**
     * @dev Gets the current manual trigger permissioned address.
     * @return address The permissioned address.
     */
    function getManualTriggerPermissionedAddress() external view returns (address) {
        return manualTriggerPermissionedAddress;
    }


    // --- 11. Access Control & Ownership ---

    // Ownable functions are inherited: owner(), transferOwnership(), renounceOwnership()

    /**
     * @dev Sets the address that is allowed to trigger Manual commitments.
     *      Only callable by the owner.
     * @param _manualTriggerPermissionedAddress The new permissioned address.
     */
    function setPermissionedAddressForTrigger(address _manualTriggerPermissionedAddress) external onlyOwner {
        require(_manualTriggerPermissionedAddress != address(0), "QuantumLock: Permissioned address cannot be zero");
        manualTriggerPermissionedAddress = _manualTriggerPermissionedAddress;
    }


    // --- 12. ERC721 Receiver Hook ---

    // ERC721Holder provides the onERC721Received implementation needed for safeTransferFrom
    // No need to override unless custom logic is needed.
}
```