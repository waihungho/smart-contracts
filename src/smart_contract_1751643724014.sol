Okay, here is a Solidity smart contract attempting to be interesting, advanced, creative, and trendy by implementing a system of "Dimensional Fragments" that can be created, evolved, synthesized, linked, and interacted with, incorporating concepts like state change, dynamic parameters, granular permissions, and internal 'interaction' logic. It avoids directly copying common ERC-721/ERC-1155 logic, governance models, or standard DeFi pools, instead focusing on unique digital entities and their relationships.

**Outline and Function Summary**

**Contract: DimensionalNexus**

This contract manages a collection of unique digital entities called "Fragments". Each Fragment has parameters, a status, can be linked to another Fragment, and its state can evolve through various interactions triggered by its owner or authorized third parties.

**Core Concepts:**

*   **Fragments:** Non-fungible entities represented by an ID, owner, status, dynamic parameters (`uint256[]`), creation/evolution history, and a link to another fragment.
*   **Dynamic State:** Fragments' parameters and status can change over time through evolution, synthesis, and interactions.
*   **Linking:** Fragments can be directionally linked, allowing interactions on one to potentially affect the linked one.
*   **Synthesis:** Two Fragments can be combined to create a new, potentially more complex Fragment, consuming the parents.
*   **Interactions:** A generic mechanism (`interfaceWithFragment`) allows triggering specific internal logic based on interaction codes and data.
*   **Granular Permissions:** Owners can authorize specific addresses to perform certain actions (like evolving) on their individual Fragments.
*   **Fees:** Certain actions require payment in native currency (Ether).

**Function Categories & Summary:**

1.  **Fragment Creation & Generation:**
    *   `createFragment()`: Mints a new Fragment with initial parameters derived semi-randomly. (Payable)
    *   `synthesizeFragment(uint256 parent1Id, uint256 parent2Id)`: Creates a new Fragment by combining two existing ones. Consumes parent Fragments. (Payable)

2.  **Fragment State Modification & Evolution:**
    *   `evolveFragment(uint256 fragmentId, uint256[] newParameters)`: Updates a Fragment's parameters. Checks evolution cooldown. (Payable)
    *   `setParameter(uint256 fragmentId, uint256 index, uint256 value)`: Modifies a specific parameter by index.
    *   `addParameter(uint256 fragmentId, uint256 value)`: Appends a new parameter.
    *   `removeParameter(uint256 fragmentId, uint256 index)`: Removes a parameter by index.
    *   `setFragmentStatus(uint256 fragmentId, FragmentStatus newStatus)`: Changes the Fragment's lifecycle status.

3.  **Fragment Linking & Relationships:**
    *   `linkFragments(uint256 fragmentId1, uint256 fragmentId2)`: Establishes a directional link from fragmentId1 to fragmentId2.
    *   `unlinkFragment(uint256 fragmentId)`: Removes the outgoing link from a Fragment.

4.  **Fragment Interaction & Logic:**
    *   `interfaceWithFragment(uint256 targetFragmentId, uint256 interactionCode, bytes memory interactionData)`: Triggers internal logic based on the code and data, potentially affecting the target Fragment or its linked Fragment. (This function acts as a hook for potentially complex future interactions).
    *   `triggerLinkedEffect(uint256 sourceFragmentId)`: Explicitly triggers the effect on a Fragment linked from the source Fragment.

5.  **Access Control & Permissions:**
    *   `transferFragmentOwnership(address to, uint256 fragmentId)`: Transfers ownership of a Fragment (similar to ERC-721 `transferFrom`).
    *   `lockFragment(uint256 fragmentId)`: Sets Fragment status to `Locked`, preventing most modifications.
    *   `unlockFragment(uint256 fragmentId)`: Sets Fragment status back from `Locked` to `Active`.
    *   `authorizeInteractor(uint256 fragmentId, address interactor, bool authorized)`: Grants/revokes permission for an address to call certain functions (like `evolveFragment` or `interfaceWithFragment`) on a specific Fragment.

6.  **Fees & Contract Administration:**
    *   `setFees(uint256 createFee, uint256 evolveFee, uint256 synthesizeFee)`: Sets the fees for creation, evolution, and synthesis. (Owner only)
    *   `withdrawFees(address payable recipient)`: Allows the contract owner to withdraw accumulated fees. (Owner only)
    *   `renounceOwnership()`: Standard Ownable function. (Owner only)
    *   `transferOwnership(address newOwner)`: Standard Ownable function. (Owner only)
    *   `rescueERC20(address tokenAddress, uint256 amount)`: Allows the owner to rescue accidentally sent ERC20 tokens. (Owner only)

7.  **View & Pure Functions (Read-Only):**
    *   `getFragment(uint256 fragmentId)`: Retrieves the full Fragment struct data.
    *   `getFragmentOwner(uint256 fragmentId)`: Gets the owner of a Fragment.
    *   `getFragmentParameters(uint256 fragmentId)`: Gets the parameters array of a Fragment.
    *   `getLinkedFragmentId(uint256 fragmentId)`: Gets the ID of the Fragment linked from this one.
    *   `getFragmentStatus(uint256 fragmentId)`: Gets the current status of a Fragment.
    *   `getDataURI(uint256 fragmentId)`: Gets the metadata URI associated with a Fragment.
    *   `calculateComplexity(uint256 fragmentId)`: Calculates a complexity score based on parameters (pure function example).
    *   `simulateNextEvolutionState(uint256 fragmentId, uint256[] proposedParameters)`: Predicts the outcome of an evolution (view function, no state change).
    *   `checkEvolutionReadiness(uint256 fragmentId)`: Checks if a Fragment is off its evolution cooldown.
    *   `isInteractorAuthorized(uint256 fragmentId, address interactor)`: Checks if an address is authorized to interact with a specific Fragment.
    *   `getTotalFragments()`: Gets the total number of Fragments minted.
    *   `getCreationFee()`, `getEvolveFee()`, `getSynthesizeFee()`: Get current fee amounts. (Could also be a single `getFees` function).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // For rescue function

// Error definitions for clarity and gas efficiency
error FragmentDoesNotExist(uint256 fragmentId);
error NotFragmentOwner(uint256 fragmentId, address caller);
error InvalidFragmentStatus(uint256 fragmentId, FragmentStatus currentStatus);
error EvolutionOnCooldown(uint256 fragmentId, uint256 blocksRemaining);
error CannotSynthesizeInactiveOrLocked(uint256 fragmentId);
error CannotLinkToSelf(uint256 fragmentId);
error LinkRequiresActiveStatus(uint256 fragmentId);
error InteractionNotAuthorized(uint256 fragmentId, address caller);
error InvalidParameterIndex(uint256 fragmentId, uint256 index);
error ZeroAddressRecipient();
error PaymentRequired(uint256 required, uint256 sent);

contract DimensionalNexus is Ownable {

    enum FragmentStatus { Dormant, Active, Evolving, Locked, Synthesized, Inactive }

    struct Fragment {
        address owner;
        uint256 creationBlock;
        uint256 lastEvolutionBlock;
        uint256[] parameters; // Represents the fragment's unique state/properties
        FragmentStatus status;
        uint256 linkedFragment; // ID of another fragment this one is linked to (0 if none)
        string dataURI; // External metadata URI, potentially dynamic
    }

    uint256 private _nextTokenId;
    mapping(uint256 => Fragment) private _fragments;
    mapping(uint256 => mapping(address => bool)) private _fragmentInteractors; // fragmentId => interactorAddress => authorized

    uint256 public creationFee;
    uint256 public evolveFee;
    uint256 public synthesizeFee;
    uint256 public evolutionCooldownBlocks = 10; // Blocks required between evolutions

    event FragmentCreated(uint256 indexed fragmentId, address indexed owner, uint256[] initialParameters);
    event FragmentEvolved(uint256 indexed fragmentId, uint256[] newParameters, uint256 complexity);
    event FragmentSynthesized(uint256 indexed newFragmentId, uint256 indexed parent1Id, uint256 indexed parent2Id, address indexed owner);
    event FragmentTransfered(uint256 indexed fragmentId, address indexed from, address indexed to);
    event FragmentLinked(uint256 indexed sourceFragmentId, uint256 indexed targetFragmentId);
    event FragmentUnlinked(uint256 indexed sourceFragmentId);
    event FragmentStatusChanged(uint256 indexed fragmentId, FragmentStatus oldStatus, FragmentStatus newStatus);
    event DataURISet(uint256 indexed fragmentId, string uri);
    event InteractorAuthorized(uint256 indexed fragmentId, address indexed interactor, bool authorized);
    event InteractionTriggered(uint256 indexed fragmentId, address indexed caller, uint256 interactionCode);
    event FeesSet(uint256 createFee, uint256 evolveFee, uint256 synthesizeFee);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {
        _nextTokenId = 1; // Start fragment IDs from 1
        creationFee = 0.01 ether; // Example fees
        evolveFee = 0.005 ether;
        synthesizeFee = 0.02 ether;
    }

    // --- Internal Helper Functions ---

    function _fragmentExists(uint256 fragmentId) internal view returns (bool) {
        return _fragments[fragmentId].creationBlock > 0; // Use creationBlock as a check
    }

    function _requireFragmentExists(uint256 fragmentId) internal view {
        if (!_fragmentExists(fragmentId)) {
            revert FragmentDoesNotExist(fragmentId);
        }
    }

    function _requireFragmentOwner(uint256 fragmentId) internal view {
        _requireFragmentExists(fragmentId);
        if (_fragments[fragmentId].owner != msg.sender) {
            revert NotFragmentOwner(fragmentId, msg.sender);
        }
    }

    function _requireActiveOrEvolving(uint256 fragmentId) internal view {
        _requireFragmentExists(fragmentId);
        FragmentStatus status = _fragments[fragmentId].status;
        if (status != FragmentStatus.Active && status != FragmentStatus.Evolving) {
             revert InvalidFragmentStatus(fragmentId, status);
        }
    }

    function _requireNotLocked(uint256 fragmentId) internal view {
        _requireFragmentExists(fragmentId);
        if (_fragments[fragmentId].status == FragmentStatus.Locked) {
             revert InvalidFragmentStatus(fragmentId, FragmentStatus.Locked);
        }
    }

    function _requireInteractorAuthorized(uint256 fragmentId) internal view {
        _requireFragmentExists(fragmentId);
        // Owner is always authorized
        if (_fragments[fragmentId].owner == msg.sender) {
            return;
        }
        // Check specific authorization
        if (!_fragmentInteractors[fragmentId][msg.sender]) {
            revert InteractionNotAuthorized(fragmentId, msg.sender);
        }
    }

    function _mintFragment(address to, uint256[] memory initialParameters, FragmentStatus status) internal returns (uint256) {
        uint256 newId = _nextTokenId++;
        _fragments[newId] = Fragment({
            owner: to,
            creationBlock: block.number,
            lastEvolutionBlock: block.number, // Set initial evolution block
            parameters: initialParameters,
            status: status,
            linkedFragment: 0, // No link initially
            dataURI: "" // No URI initially
        });
        return newId;
    }

    function _burnFragment(uint256 fragmentId) internal {
         // In this conceptual contract, "burning" means setting status to Synthesized/Inactive
         // and potentially clearing sensitive data, rather than actual deletion for historical state.
         // For true burning (like ERC721), you'd remove from mappings.
         // Here, we mark it consumed and potentially reset some fields.
        _fragments[fragmentId].status = FragmentStatus.Synthesized; // Mark as consumed by synthesis
        _fragments[fragmentId].linkedFragment = 0; // Remove links
        _fragmentInteractors[fragmentId][msg.sender] = false; // Revoke all interactor permissions
        // Keep parameters/owner for historical queries if needed, or clear them:
        // delete _fragments[fragmentId].parameters;
        // _fragments[fragmentId].owner = address(0); // Optional: clear owner
    }

    // --- Fragment Creation & Generation ---

    /**
     * @notice Mints a new Fragment with initial, semi-random parameters.
     * @dev Requires payment of `creationFee`. Parameters are seeded using block data.
     * @return The ID of the newly created Fragment.
     */
    function createFragment() external payable returns (uint256) {
        if (msg.value < creationFee) {
            revert PaymentRequired(creationFee, msg.value);
        }

        // Simple pseudo-randomness based on block data
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextTokenId));
        uint256[] memory initialParams = new uint256[](3); // Example: 3 initial parameters
        initialParams[0] = uint256(seed) % 100 + 1; // Param 1: 1-100
        initialParams[1] = uint256(keccak256(abi.encodePacked(seed, 1))) % 255 + 1; // Param 2: 1-255
        initialParams[2] = uint256(keccak256(abi.encodePacked(seed, 2))) % 1000 + 1; // Param 3: 1-1000

        uint256 newFragmentId = _mintFragment(msg.sender, initialParams, FragmentStatus.Active);

        emit FragmentCreated(newFragmentId, msg.sender, initialParams);
        return newFragmentId;
    }

    /**
     * @notice Synthesizes a new Fragment from two parent Fragments.
     * @dev Requires payment of `synthesizeFee`. Parents must be Active and not Locked.
     *      Parents are consumed (status set to Synthesized).
     *      New parameters are derived from parent parameters and randomness.
     * @param parent1Id The ID of the first parent Fragment.
     * @param parent2Id The ID of the second parent Fragment.
     * @return The ID of the newly synthesized Fragment.
     */
    function synthesizeFragment(uint256 parent1Id, uint256 parent2Id) external payable returns (uint256) {
        if (msg.value < synthesizeFee) {
            revert PaymentRequired(synthesizeFee, msg.value);
        }

        _requireFragmentOwner(parent1Id);
        _requireFragmentOwner(parent2Id);
        _requireNotLocked(parent1Id);
        _requireNotLocked(parent2Id);

        Fragment storage parent1 = _fragments[parent1Id];
        Fragment storage parent2 = _fragments[parent2Id];

        if (parent1.status != FragmentStatus.Active || parent2.status != FragmentStatus.Active) {
            revert CannotSynthesizeInactiveOrLocked(parent1Id); // Reusing error for both
        }

        // Simple synthesis logic: take first half params from parent1, second half from parent2
        uint256 len1 = parent1.parameters.length;
        uint256 len2 = parent2.parameters.length;
        uint256 newLen = len1 / 2 + len2 - len2 / 2 + 1; // Add 1 new param
        uint256[] memory newParams = new uint256[](newLen);

        for (uint i = 0; i < len1 / 2; i++) {
            newParams[i] = parent1.parameters[i];
        }
        for (uint i = 0; i < len2 - len2 / 2; i++) {
            newParams[len1 / 2 + i] = parent2.parameters[len2 / 2 + i];
        }

        // Add a new param based on parents' complexity and block data
        uint256 parent1Complexity = calculateComplexity(parent1Id); // Using pure function
        uint256 parent2Complexity = calculateComplexity(parent2Id);
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, parent1Id, parent2Id));
        newParams[newLen - 1] = (parent1Complexity + parent2Complexity + uint256(seed)) % 2000 + 1; // Example range

        // Burn parents
        _burnFragment(parent1Id);
        _burnFragment(parent2Id);

        uint256 newFragmentId = _mintFragment(msg.sender, newParams, FragmentStatus.Active);

        emit FragmentSynthesized(newFragmentId, parent1Id, parent2Id, msg.sender);
        return newFragmentId;
    }

    // --- Fragment State Modification & Evolution ---

    /**
     * @notice Evolves a Fragment by updating its parameters.
     * @dev Requires payment of `evolveFee`, Fragment must be Active, not Locked, and off cooldown.
     *      Can only be called by owner or authorized interactor.
     * @param fragmentId The ID of the Fragment to evolve.
     * @param newParameters The new set of parameters for the Fragment.
     */
    function evolveFragment(uint256 fragmentId, uint256[] memory newParameters) external payable {
        if (msg.value < evolveFee) {
            revert PaymentRequired(evolveFee, msg.value);
        }
        _requireInteractorAuthorized(fragmentId); // Owner or authorized interactor
        _requireActiveOrEvolving(fragmentId);
        _requireNotLocked(fragmentId);

        Fragment storage fragment = _fragments[fragmentId];

        // Check evolution cooldown
        uint256 blocksSinceLastEvolution = block.number - fragment.lastEvolutionBlock;
        if (blocksSinceLastEvolution < evolutionCooldownBlocks) {
            revert EvolutionOnCooldown(fragmentId, evolutionCooldownBlocks - blocksSinceLastEvolution);
        }

        fragment.parameters = newParameters; // Replace parameters
        fragment.lastEvolutionBlock = block.number;
        fragment.status = FragmentStatus.Active; // Assume active after evolution

        uint256 currentComplexity = calculateComplexity(fragmentId);

        emit FragmentEvolved(fragmentId, newParameters, currentComplexity);
    }

    /**
     * @notice Modifies a specific parameter of a Fragment by index.
     * @dev Requires Fragment to be Active or Evolving and not Locked.
     *      Can only be called by owner.
     * @param fragmentId The ID of the Fragment.
     * @param index The index of the parameter to modify.
     * @param value The new value for the parameter.
     */
    function setParameter(uint256 fragmentId, uint256 index, uint256 value) external {
         _requireFragmentOwner(fragmentId);
         _requireActiveOrEvolving(fragmentId);
         _requireNotLocked(fragmentId);

         Fragment storage fragment = _fragments[fragmentId];
         if (index >= fragment.parameters.length) {
            revert InvalidParameterIndex(fragmentId, index);
         }

         fragment.parameters[index] = value;
         // No specific event for single param change, implied by potential future state checks
    }

     /**
     * @notice Adds a new parameter to a Fragment.
     * @dev Requires Fragment to be Active or Evolving and not Locked.
     *      Can only be called by owner.
     * @param fragmentId The ID of the Fragment.
     * @param value The value of the new parameter.
     */
    function addParameter(uint256 fragmentId, uint256 value) external {
        _requireFragmentOwner(fragmentId);
        _requireActiveOrEvolving(fragmentId);
        _requireNotLocked(fragmentId);

        _fragments[fragmentId].parameters.push(value);
    }

    /**
     * @notice Removes a parameter from a Fragment by index.
     * @dev Requires Fragment to be Active or Evolving and not Locked.
     *      Can only be called by owner. Note: Removing from middle of array is gas-expensive.
     * @param fragmentId The ID of the Fragment.
     * @param index The index of the parameter to remove.
     */
    function removeParameter(uint256 fragmentId, uint256 index) external {
        _requireFragmentOwner(fragmentId);
        _requireActiveOrEvolving(fragmentId);
        _requireNotLocked(fragmentId);

        Fragment storage fragment = _fragments[fragmentId];
        if (index >= fragment.parameters.length) {
            revert InvalidParameterIndex(fragmentId, index);
        }

        // Shift elements to fill the gap (gas-expensive operation)
        for (uint i = index; i < fragment.parameters.length - 1; i++) {
            fragment.parameters[i] = fragment.parameters[i + 1];
        }
        fragment.parameters.pop(); // Remove the last element
    }

    /**
     * @notice Changes the status of a Fragment.
     * @dev Can only be called by owner. Some status changes might have specific requirements.
     * @param fragmentId The ID of the Fragment.
     * @param newStatus The new status to set.
     */
    function setFragmentStatus(uint256 fragmentId, FragmentStatus newStatus) external {
        _requireFragmentOwner(fragmentId);
        _requireFragmentExists(fragmentId); // Can change status even if not Active/Evolving/Locked

        Fragment storage fragment = _fragments[fragmentId];
        FragmentStatus oldStatus = fragment.status;

        // Add specific checks for status transitions if needed (e.g., can't go from Synthesized back to Active)
        if (oldStatus == FragmentStatus.Synthesized && newStatus != FragmentStatus.Synthesized) {
             revert InvalidFragmentStatus(fragmentId, oldStatus);
        }
         if (oldStatus == FragmentStatus.Inactive && (newStatus == FragmentStatus.Active || newStatus == FragmentStatus.Evolving || newStatus == FragmentStatus.Locked) ) {
             revert InvalidFragmentStatus(fragmentId, oldStatus);
        }


        fragment.status = newStatus;
        emit FragmentStatusChanged(fragmentId, oldStatus, newStatus);
    }

    // --- Fragment Linking & Relationships ---

    /**
     * @notice Links one Fragment to another.
     * @dev Requires both Fragments to exist and the caller to own the source Fragment.
     *      Source Fragment must be Active. Cannot link a Fragment to itself.
     * @param sourceFragmentId The ID of the Fragment from which the link originates.
     * @param targetFragmentId The ID of the Fragment being linked to.
     */
    function linkFragments(uint256 sourceFragmentId, uint256 targetFragmentId) external {
        _requireFragmentOwner(sourceFragmentId);
        _requireFragmentExists(targetFragmentId);

        if (sourceFragmentId == targetFragmentId) {
            revert CannotLinkToSelf(sourceFragmentId);
        }

        Fragment storage sourceFragment = _fragments[sourceFragmentId];
        if (sourceFragment.status != FragmentStatus.Active) {
            revert LinkRequiresActiveStatus(sourceFragmentId);
        }

        sourceFragment.linkedFragment = targetFragmentId;
        emit FragmentLinked(sourceFragmentId, targetFragmentId);
    }

    /**
     * @notice Removes the link from a Fragment.
     * @dev Requires the caller to own the Fragment.
     * @param sourceFragmentId The ID of the Fragment whose link should be removed.
     */
    function unlinkFragment(uint256 sourceFragmentId) external {
        _requireFragmentOwner(sourceFragmentId);
        _fragments[sourceFragmentId].linkedFragment = 0;
        emit FragmentUnlinked(sourceFragmentId);
    }

    // --- Fragment Interaction & Logic ---

    /**
     * @notice A generic function to trigger specific interaction logic on a Fragment.
     * @dev Can only be called by owner or authorized interactor.
     *      The interpretation of `interactionCode` and `interactionData` is application-specific.
     *      This acts as an extensible hook.
     * @param targetFragmentId The ID of the Fragment to interact with.
     * @param interactionCode A code defining the type of interaction.
     * @param interactionData Arbitrary data for the interaction.
     */
    function interfaceWithFragment(uint256 targetFragmentId, uint256 interactionCode, bytes memory interactionData) external {
        _requireInteractorAuthorized(targetFragmentId); // Owner or authorized interactor
        _requireActiveOrEvolving(targetFragmentId);
        _requireNotLocked(targetFragmentId);

        // --- Advanced/Creative Interaction Logic Hook ---
        // Implement logic based on interactionCode and interactionData here.
        // Examples:
        // - 0x01: "Resonance" - Increase/decrease parameters based on linked fragment's state.
        // - 0x02: "Data Infusion" - Attempt to parse interactionData to add/modify a parameter.
        // - 0x03: "Status Ping" - Simple check, perhaps triggers a minor param change or event.
        // - 0x04: "Catalyze" - If linked to a specific type of fragment, trigger a synthesis attempt (more complex, would likely require another function call and fees).

        Fragment storage fragment = _fragments[targetFragmentId];

        if (interactionCode == 1) { // Example: Resonance Interaction
            uint256 linkedId = fragment.linkedFragment;
            if (linkedId != 0 && _fragmentExists(linkedId)) {
                 Fragment storage linkedFragment = _fragments[linkedId];
                 if (linkedFragment.status == FragmentStatus.Active || linkedFragment.status == FragmentStatus.Evolving) {
                    // Example effect: slightly modify target params based on linked params' sum
                    uint256 linkedComplexity = calculateComplexity(linkedId);
                    for(uint i = 0; i < fragment.parameters.length; i++) {
                        fragment.parameters[i] = fragment.parameters[i] + (linkedComplexity % 10); // Simple adjustment
                    }
                 }
            }
        } else if (interactionCode == 2) { // Example: Data Infusion
             // Attempt to decode interactionData and add as parameter
             if (interactionData.length == 32) { // Assuming a single uint256 is passed
                 uint256 infusedValue = abi.decode(interactionData, (uint256));
                 fragment.parameters.push(infusedValue);
             }
        }
        // Add more complex interaction logic here...

        // Update last evolution/interaction block to prevent rapid spamming if needed
        // fragment.lastEvolutionBlock = block.number; // Can use this as an interaction cooldown too

        emit InteractionTriggered(targetFragmentId, msg.sender, interactionCode);
    }

    /**
     * @notice Triggers an effect on the Fragment that the source Fragment is linked to.
     * @dev Requires owner of the source Fragment and an active link.
     *      The nature of the effect is defined internally (example provided).
     * @param sourceFragmentId The ID of the Fragment initiating the linked effect.
     */
    function triggerLinkedEffect(uint256 sourceFragmentId) external {
        _requireFragmentOwner(sourceFragmentId);
        _requireActiveOrEvolving(sourceFragmentId);

        Fragment storage sourceFragment = _fragments[sourceFragmentId];
        uint256 targetFragmentId = sourceFragment.linkedFragment;

        if (targetFragmentId != 0 && _fragmentExists(targetFragmentId)) {
             Fragment storage targetFragment = _fragments[targetFragmentId];

             // Example Linked Effect Logic:
             if (targetFragment.status == FragmentStatus.Active || targetFragment.status == FragmentStatus.Evolving) {
                 // Modify target parameters based on source parameters
                 uint256 sourceComplexity = calculateComplexity(sourceFragmentId);
                 for(uint i = 0; i < targetFragment.parameters.length; i++) {
                     targetFragment.parameters[i] = targetFragment.parameters[i] + (sourceComplexity % 5); // Simple adjustment
                 }
                 // Optionally, trigger an event on the target or change its status slightly
                 targetFragment.status = FragmentStatus.Evolving; // Mark as evolving due to external influence
             }
             // Could add more complex logic, e.g., if target is locked, maybe the link breaks?
        }
        // No effect if no link or target doesn't exist/is inactive
    }


    // --- Access Control & Permissions ---

    /**
     * @notice Transfers ownership of a Fragment.
     * @dev Only the current owner can transfer ownership.
     * @param to The address to transfer ownership to.
     * @param fragmentId The ID of the Fragment to transfer.
     */
    function transferFragmentOwnership(address to, uint256 fragmentId) external {
        _requireFragmentOwner(fragmentId);
         if (to == address(0)) {
            revert ZeroAddressRecipient();
        }

        address from = msg.sender;
        _fragments[fragmentId].owner = to;

        // Revoke all interactor permissions upon ownership transfer
        delete _fragmentInteractors[fragmentId];

        emit FragmentTransfered(fragmentId, from, to);
    }

    /**
     * @notice Locks a Fragment, preventing most state modifications (evolution, parameter changes, interaction).
     * @dev Only the owner can lock/unlock.
     * @param fragmentId The ID of the Fragment to lock.
     */
    function lockFragment(uint256 fragmentId) external {
        _requireFragmentOwner(fragmentId);
        _requireFragmentExists(fragmentId); // Can lock any existing fragment

        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.status != FragmentStatus.Locked) {
             emit FragmentStatusChanged(fragmentId, fragment.status, FragmentStatus.Locked);
             fragment.status = FragmentStatus.Locked;
        }
    }

    /**
     * @notice Unlocks a Locked Fragment, returning it to Active status.
     * @dev Only the owner can lock/unlock.
     * @param fragmentId The ID of the Fragment to unlock.
     */
    function unlockFragment(uint224 fragmentId) external { // Use uint224 as a creative parameter size example (though unnecessary here)
        _requireFragmentOwner(fragmentId);
        _requireFragmentExists(fragmentId);

        Fragment storage fragment = _fragments[fragmentId];
        if (fragment.status == FragmentStatus.Locked) {
             emit FragmentStatusChanged(fragmentId, fragment.status, FragmentStatus.Active);
             fragment.status = FragmentStatus.Active;
        }
    }

    /**
     * @notice Grants or revokes authorization for an address to interact with a specific Fragment.
     * @dev Only the owner of the Fragment can grant/revoke authorization.
     *      Authorized interactors can call `evolveFragment` and `interfaceWithFragment`.
     * @param fragmentId The ID of the Fragment.
     * @param interactor The address to authorize/deauthorize.
     * @param authorized True to grant, False to revoke.
     */
    function authorizeInteractor(uint256 fragmentId, address interactor, bool authorized) external {
        _requireFragmentOwner(fragmentId);
        _fragmentInteractors[fragmentId][interactor] = authorized;
        emit InteractorAuthorized(fragmentId, interactor, authorized);
    }


    // --- Fees & Contract Administration ---

    /**
     * @notice Sets the fees required for various operations.
     * @dev Only callable by the contract owner.
     * @param _createFee Fee for creating a new Fragment.
     * @param _evolveFee Fee for evolving a Fragment.
     * @param _synthesizeFee Fee for synthesizing Fragments.
     */
    function setFees(uint256 _createFee, uint256 _evolveFee, uint256 _synthesizeFee) external onlyOwner {
        creationFee = _createFee;
        evolveFee = _evolveFee;
        synthesizeFee = _synthesizeFee;
        emit FeesSet(creationFee, evolveFee, synthesizeFee);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated Ether fees.
     * @dev Only callable by the contract owner.
     * @param recipient The address to send the fees to.
     */
    function withdrawFees(address payable recipient) external onlyOwner {
         if (recipient == address(0)) {
            revert ZeroAddressRecipient();
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = recipient.call{value: balance}("");
            require(success, "Withdrawal failed");
            emit FeesWithdrawn(recipient, balance);
        }
    }

     /**
     * @notice Allows the owner to rescue ERC20 tokens accidentally sent to the contract.
     * @dev Only callable by the contract owner. Standard rescue pattern.
     * @param tokenAddress Address of the ERC20 token.
     * @param amount Amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(owner(), amount);
    }


    // --- View & Pure Functions (Read-Only) ---

    /**
     * @notice Retrieves the full details of a Fragment.
     * @dev Returns the Fragment struct.
     * @param fragmentId The ID of the Fragment.
     * @return The Fragment struct.
     */
    function getFragment(uint256 fragmentId) external view returns (Fragment memory) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId];
    }

    /**
     * @notice Gets the owner of a Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return The owner address.
     */
    function getFragmentOwner(uint256 fragmentId) external view returns (address) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId].owner;
    }

     /**
     * @notice Gets the parameters array of a Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return An array of uint256 parameters.
     */
    function getFragmentParameters(uint256 fragmentId) external view returns (uint256[] memory) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId].parameters;
    }

    /**
     * @notice Gets the ID of the Fragment that a given Fragment is linked to.
     * @param fragmentId The ID of the source Fragment.
     * @return The ID of the linked Fragment, or 0 if none.
     */
    function getLinkedFragmentId(uint256 fragmentId) external view returns (uint256) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId].linkedFragment;
    }

     /**
     * @notice Gets the current status of a Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return The Fragment's status enum value.
     */
    function getFragmentStatus(uint256 fragmentId) external view returns (FragmentStatus) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId].status;
    }

    /**
     * @notice Gets the external data URI for a Fragment.
     * @param fragmentId The ID of the Fragment.
     * @return The data URI string.
     */
    function getDataURI(uint256 fragmentId) external view returns (string memory) {
        _requireFragmentExists(fragmentId);
        return _fragments[fragmentId].dataURI;
    }

    /**
     * @notice Sets the external data URI for a Fragment.
     * @dev Only the owner can set the data URI. Useful for off-chain metadata.
     * @param fragmentId The ID of the Fragment.
     * @param uri The new data URI string.
     */
    function setDataURI(uint256 fragmentId, string memory uri) external {
        _requireFragmentOwner(fragmentId);
        _fragments[fragmentId].dataURI = uri;
        emit DataURISet(fragmentId, uri);
    }


    /**
     * @notice Calculates a complexity score for a Fragment based on its parameters.
     * @dev This is a pure function; it doesn't read or write state. Example calculation.
     * @param fragmentId The ID of the Fragment.
     * @return The calculated complexity score.
     */
    function calculateComplexity(uint256 fragmentId) public view returns (uint256) {
        // Note: Calling this from another state-changing function (like synthesize)
        // means it effectively *does* read state via the internal call.
        // Marking `public view` allows both external calls and internal/public calls.
        _requireFragmentExists(fragmentId); // Check existence even in view

        uint256 totalComplexity = 0;
        uint256[] memory params = _fragments[fragmentId].parameters;
        for (uint i = 0; i < params.length; i++) {
            totalComplexity += params[i]; // Simple sum of parameters
        }
        // Could add multipliers, exponents, etc. for more complex logic
        return totalComplexity;
    }

    /**
     * @notice Simulates the potential outcome state (parameters) of an evolution.
     * @dev A view function that allows potential evolutions to be previewed off-chain
     *      without committing the state change.
     * @param fragmentId The ID of the Fragment to simulate evolution for.
     * @param proposedParameters The parameters proposed for the evolution.
     * @return The parameters the Fragment would have after this evolution.
     */
    function simulateNextEvolutionState(uint256 fragmentId, uint256[] memory proposedParameters) external view returns (uint256[] memory) {
        _requireFragmentExists(fragmentId);
        // This simulation is simple: just shows the proposed parameters.
        // A more complex simulation could apply evolution rules based on current state + proposed changes.
        // For this example, it's primarily to show the input would become the output params.
        return proposedParameters;
    }

    /**
     * @notice Checks if a Fragment is ready to be evolved (i.e., off cooldown).
     * @dev A view function.
     * @param fragmentId The ID of the Fragment.
     * @return True if ready for evolution, false otherwise.
     */
    function checkEvolutionReadiness(uint256 fragmentId) external view returns (bool) {
        _requireFragmentExists(fragmentId);
        uint256 blocksSinceLastEvolution = block.number - _fragments[fragmentId].lastEvolutionBlock;
        return blocksSinceLastEvolution >= evolutionCooldownBlocks;
    }

    /**
     * @notice Checks if an address is authorized to interact with a specific Fragment.
     * @dev A view function. Owners are always authorized.
     * @param fragmentId The ID of the Fragment.
     * @param interactor The address to check authorization for.
     * @return True if authorized, false otherwise.
     */
    function isInteractorAuthorized(uint256 fragmentId, address interactor) external view returns (bool) {
        _requireFragmentExists(fragmentId);
        if (_fragments[fragmentId].owner == interactor) {
            return true; // Owner is always authorized
        }
        return _fragmentInteractors[fragmentId][interactor];
    }

    /**
     * @notice Gets the total number of Fragments ever minted.
     * @return The total count of Fragments.
     */
    function getTotalFragments() external view returns (uint256) {
        return _nextTokenId - 1;
    }

     /**
     * @notice Gets the current fee for creating a Fragment.
     */
    function getCreationFee() external view returns (uint256) {
        return creationFee;
    }

    /**
     * @notice Gets the current fee for evolving a Fragment.
     */
    function getEvolveFee() external view returns (uint256) {
        return evolveFee;
    }

     /**
     * @notice Gets the current fee for synthesizing Fragments.
     */
    function getSynthesizeFee() external view returns (uint256) {
        return synthesizeFee;
    }
}
```