```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EtherealCanvas
 * @author Your Name (or a pseudonym)
 * @notice A dynamic, community-influenced digital canvas where art parameters evolve over time,
 * controlled by owners of linked NFTs. Elements decay unless refreshed, and the canvas state
 * is periodically influenced by simulated external factors. This contract manages the *state*
 * of the art; rendering is handled off-chain based on the parameters provided by the contract.
 *
 * Outline:
 * 1. State Variables: Define the core data representing the canvas state, configuration, and roles.
 * 2. Events: Declare events to signal significant changes for off-chain monitoring.
 * 3. Errors: Define custom errors for clearer failure reasons.
 * 4. Structs: Define the structure for individual elements on the canvas.
 * 5. Access Control: Simple manual roles (Owner, Curator, NFT Holder).
 * 6. Modifiers: Implement access control logic using modifiers.
 * 7. Constructor: Initialize the contract with base parameters.
 * 8. Admin Functions (Owner Only): Setup and critical configuration.
 * 9. Curator Functions (Curator Only): Management and high-level control.
 * 10. NFT Holder Functions (Requires NFT & Fee): Core interaction with the canvas.
 * 11. Canvas Evolution Functions (Callable by Anyone, designed for automation): Trigger time-based and external influences.
 * 12. Query Functions (Public): Read the current state of the canvas and contract settings.
 *
 * Function Summary:
 * - State Variables: Stores global config (fees, rates), element data, roles, and canvas state.
 * - Events: Logs actions like adding/modifying elements, role changes, canvas freezing, evolution.
 * - Errors: Custom error messages for failed operations.
 * - Struct Element: Defines properties of a single visual element (id, creator, parameters, timestamps, energy).
 * - onlyOwner/onlyCurator/onlyNFTHolder: Modifiers to restrict function access.
 * - constructor: Initializes contract owner, curator, linked NFT contract, and base fees/rates.
 * - transferOwnership: Transfers contract ownership (Owner).
 * - setCurator: Sets or changes the curator address (Owner).
 * - setOwnershipNFTContract: Sets the address of the qualifying NFT contract (Owner).
 * - setBaseInteractionFee: Sets the base fee required for most NFT holder actions (Owner).
 * - setDecayRate: Sets the rate at which element energy decays (Owner).
 * - transferCuratorRole: Transfers the curator role to another address (Curator).
 * - addCuratorMessage: Allows the curator to embed a message in the canvas state (Curator).
 * - freezeCanvas: Temporarily prevents all canvas modifications and evolution (Curator).
 * - unfreezeCanvas: Unfreezes the canvas (Curator).
 * - withdrawFees: Allows the curator to withdraw accumulated interaction fees (Curator).
 * - addElement: Adds a new element to the canvas state (NFT Holder, Fee).
 * - modifyElement: Modifies parameters of an existing element (NFT Holder, Fee).
 * - removeElement: Removes an element from the canvas (NFT Holder, Fee).
 * - lockElement: Locks an element to prevent modifications/removal (NFT Holder, Fee).
 * - unlockElement: Unlocks a previously locked element (NFT Holder, Fee).
 * - refreshElementEnergy: Resets an element's decay energy/timer (NFT Holder, Fee).
 * - applyCanvasEvolution: Triggers decay, applies external influence, and potentially removes zero-energy elements (Any Caller, batched, time-gated).
 * - getCanvasStateSummary: Returns basic counts and status of the canvas.
 * - getElementCount: Returns the total number of elements ever added.
 * - getActiveElementCount: Returns the number of elements currently stored (not necessarily visible after decay).
 * - getElementParameters: Retrieves the full details of a specific element by ID.
 * - getElementEnergy: Gets the current energy level of an element.
 * - isElementLocked: Checks if an element is currently locked.
 * - getCuratorMessage: Retrieves the current message set by the curator.
 * - isCanvasFrozen: Checks if the canvas is currently frozen.
 * - getBaseInteractionFee: Retrieves the current base interaction fee.
 * - getDecayRate: Retrieves the current decay rate.
 * - getOwnershipNFTContract: Retrieves the address of the linked NFT contract.
 * - getCurator: Retrieves the address of the current curator.
 * - getOwner: Retrieves the address of the contract owner.
 * - checkNFTEligibility: Checks if an address holds a qualifying NFT from the linked contract.
 */

// --- Interfaces ---
// Minimal interface for checking NFT balance without importing a full library
interface IERC721Minimal {
    function balanceOf(address owner) external view returns (uint256);
}

// --- Custom Errors ---
error Unauthorized();
error InvalidElementId(uint256 elementId);
error ElementLocked(uint256 elementId);
error ElementNotLocked(uint256 elementId);
error CanvasFrozen();
error InsufficientPayment(uint256 required);
error NFTNotOwned();
error EvolutionTooFrequent();
error NoFeesToWithdraw();

// --- Contract ---
contract EtherealCanvas {

    // --- State Variables ---
    address public owner;
    address public curator;
    address public ownershipNFTContract; // Address of the ERC721 contract that grants interaction rights

    uint256 public baseInteractionFee; // Base fee required for actions like adding/modifying elements (in wei)
    uint256 public decayRate;          // Rate at which elements lose energy (e.g., 1 unit per block)
    uint256 public maxElementEnergy = 1000; // Maximum energy an element can have

    struct Element {
        uint256 id;
        address creator;
        bytes parameters; // Flexible parameter storage (e.g., ABI encoded struct, JSON string, etc.)
        uint256 creationBlock;
        uint256 lastModifiedBlock; // Also updated when energy is refreshed
        uint256 energy; // Represents vitality, decays over time/blocks
    }

    mapping(uint256 => Element) private elements; // Element ID => Element data
    mapping(uint256 => bool) public isElementActive; // Element ID => Is it currently active? (Allows gaps in elements mapping after removal)
    mapping(uint256 => bool) public lockedElements; // Element ID => Is it locked?

    uint256 private _elementCount; // Total number of elements ever added (acts as next ID)
    uint256 private _activeElementCount; // Current number of active elements

    bool public canvasFrozen; // If true, no modifications or evolution can occur

    string public curatorMessage; // A message the curator can embed

    uint256 public lastEvolutionBlock; // Block number when applyCanvasEvolution was last called
    uint256 public evolutionMinInterval = 10; // Minimum blocks between evolution calls

    address payable private feeRecipient; // Where collected fees are sent

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CuratorTransferred(address indexed previousCurator, address indexed newCurator);
    event OwnershipNFTContractSet(address indexed oldContract, address indexed newContract);
    event BaseInteractionFeeSet(uint256 indexed oldFee, uint256 indexed newFee);
    event DecayRateSet(uint256 indexed oldRate, uint256 indexed newRate);

    event ElementAdded(uint256 indexed elementId, address indexed creator, bytes parameters);
    event ElementModified(uint256 indexed elementId, bytes newParameters);
    event ElementRemoved(uint256 indexed elementId, address indexed remover);
    event ElementEnergyRefreshed(uint256 indexed elementId, uint256 newEnergy);
    event ElementLocked(uint256 indexed elementId);
    event ElementUnlocked(uint256 indexed elementId);

    event CanvasFrozenEvent();
    event CanvasUnfrozenEvent();
    event CuratorMessageSet(string message);

    event FeesWithdrawn(address indexed recipient, uint256 amount);

    event CanvasEvolutionApplied(uint256 blockNumber, uint256 elementsProcessed, uint256 elementsRemovedByDecay);

    // --- Access Control Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyCurator() {
        if (msg.sender != curator && msg.sender != owner) revert Unauthorized(); // Owner can also act as curator
        _;
    }

    modifier onlyNFTHolder() {
        if (!checkNFTEligibility(msg.sender)) revert NFTNotOwned();
        _;
    }

    modifier requireCanvasNotFrozen() {
        if (canvasFrozen) revert CanvasFrozen();
        _;
    }

    modifier requirePayment(uint256 amount) {
        if (msg.value < amount) revert InsufficientPayment(amount);
        _;
    }

    // --- Constructor ---
    constructor(address _curator, address _ownershipNFTContract, uint256 _baseInteractionFee, uint256 _decayRate) payable {
        owner = msg.sender;
        curator = _curator;
        ownershipNFTContract = _ownershipNFTContract;
        baseInteractionFee = _baseInteractionFee;
        decayRate = _decayRate;
        feeRecipient = payable(msg.sender); // By default, fees go to the owner
        lastEvolutionBlock = block.number; // Initialize last evolution block
    }

    // --- Admin Functions (Owner Only) ---
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setCurator(address newCurator) external onlyOwner {
        address oldCurator = curator;
        curator = newCurator;
        emit CuratorTransferred(oldCurator, newCurator);
    }

    function setOwnershipNFTContract(address _ownershipNFTContract) external onlyOwner {
        address oldContract = ownershipNFTContract;
        ownershipNFTContract = _ownershipNFTContract;
        emit OwnershipNFTContractSet(oldContract, _ownershipNFTContract);
    }

    function setBaseInteractionFee(uint256 _baseInteractionFee) external onlyOwner {
        uint256 oldFee = baseInteractionFee;
        baseInteractionFee = _baseInteractionFee;
        emit BaseInteractionFeeSet(oldFee, _baseInteractionFee);
    }

    function setDecayRate(uint256 _decayRate) external onlyOwner {
        uint256 oldRate = decayRate;
        decayRate = _decayRate;
        emit DecayRateSet(oldRate, _decayRate);
    }

    function setFeeRecipient(address payable _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setEvolutionMinInterval(uint256 _interval) external onlyOwner {
        evolutionMinInterval = _interval;
    }

    // --- Curator Functions (Curator Only) ---
    function transferCuratorRole(address newCurator) external onlyCurator {
         // Note: This only transfers the *curator* role, not owner. Owner can still act as curator.
        address oldCurator = curator;
        curator = newCurator;
        emit CuratorTransferred(oldCurator, newCurator);
    }

    function addCuratorMessage(string calldata message) external onlyCurator requireCanvasNotFrozen {
        curatorMessage = message;
        emit CuratorMessageSet(message);
    }

    function freezeCanvas() external onlyCurator {
        if (!canvasFrozen) {
            canvasFrozen = true;
            emit CanvasFrozenEvent();
        }
    }

    function unfreezeCanvas() external onlyCurator {
        if (canvasFrozen) {
            canvasFrozen = false;
            emit CanvasUnfrozenEvent();
        }
    }

    function withdrawFees() external onlyCurator {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFeesToWithdraw();
        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(feeRecipient, balance);
    }

    // --- NFT Holder Functions (Requires NFT & Fee) ---
    function addElement(bytes calldata parameters)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee)
        returns (uint256 newElementId)
    {
        require(parameters.length > 0, "Parameters cannot be empty"); // Basic validation

        newElementId = _elementCount;
        _elementCount++;
        _activeElementCount++;

        elements[newElementId] = Element({
            id: newElementId,
            creator: msg.sender,
            parameters: parameters,
            creationBlock: block.number,
            lastModifiedBlock: block.number,
            energy: maxElementEnergy // New elements start with full energy
        });
        isElementActive[newElementId] = true;
        lockedElements[newElementId] = false; // New elements are not locked by default

        // Send payment to the fee recipient
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementAdded(newElementId, msg.sender, parameters);
    }

    function modifyElement(uint256 elementId, bytes calldata newParameters)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee)
    {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId);
        if (lockedElements[elementId]) revert ElementLocked(elementId);
        require(newParameters.length > 0, "Parameters cannot be empty"); // Basic validation

        elements[elementId].parameters = newParameters;
        elements[elementId].lastModifiedBlock = block.number; // Modifying also refreshes vitality partially? Let's just update the block. Energy refresh is separate.

        // Send payment
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementModified(elementId, newParameters);
    }

    function removeElement(uint256 elementId)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee)
    {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId);
        if (lockedElements[elementId]) revert ElementLocked(elementId);

        // Mark as inactive rather than deleting directly from map for ID consistency
        isElementActive[elementId] = false;
        _activeElementCount--;

        // Optional: Zero out sensitive data for privacy, though struct fields are public
        // elements[elementId].creator = address(0);
        // delete elements[elementId].parameters; // Deleting bytes array saves gas

        // Send payment
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementRemoved(elementId, msg.sender);
    }

    function lockElement(uint256 elementId)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee * 2) // Locking is more expensive
    {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId);
        if (lockedElements[elementId]) revert ElementLocked(elementId); // Already locked

        lockedElements[elementId] = true;

        // Send payment
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementLocked(elementId);
    }

    function unlockElement(uint256 elementId)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee * 2) // Unlocking is also expensive
    {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId);
        if (!lockedElements[elementId]) revert ElementNotLocked(elementId); // Not locked

        lockedElements[elementId] = false;

        // Send payment
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementUnlocked(elementId);
    }

    function refreshElementEnergy(uint256 elementId)
        external
        payable
        onlyNFTHolder
        requireCanvasNotFrozen
        requirePayment(baseInteractionFee)
    {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId);
        if (lockedElements[elementId]) revert ElementLocked(elementId); // Locked elements can't be refreshed? Or should they? Let's allow refresh but not modify/remove. Okay, let's *disallow* refresh too if locked, keeps it simple.

        elements[elementId].energy = maxElementEnergy;
        elements[elementId].lastModifiedBlock = block.number; // Update block to prevent immediate decay

        // Send payment
        if (msg.value > 0) {
             (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
             require(success, "Fee payment failed");
        }

        emit ElementEnergyRefreshed(elementId, maxElementEnergy);
    }

    // --- Canvas Evolution (Callable by Anyone, designed for Automation) ---
    // This function applies time-based decay and potential external influences.
    // It's batched to prevent excessive gas usage.
    // A keeper network (like Chainlink Keepers) or similar automation should call this periodically.
    uint256 private _evolutionBatchSize = 20; // How many elements to process per call
    uint256 private _nextElementIdForEvolution = 0; // Where to start processing in the next call

    function applyCanvasEvolution() external requireCanvasNotFrozen {
        // Prevent calling too frequently
        if (block.number < lastEvolutionBlock + evolutionMinInterval) revert EvolutionTooFrequent();

        lastEvolutionBlock = block.number;

        uint256 elementsProcessed = 0;
        uint256 elementsRemoved = 0;

        uint256 startIndex = _nextElementIdForEvolution;
        uint256 endIndex = startIndex + _evolutionBatchSize;
        uint256 totalElementsToCheck = _elementCount; // Check up to the total ever added

        for (uint256 i = 0; i < _evolutionBatchSize; ++i) {
            uint256 currentElementId = (startIndex + i) % totalElementsToCheck; // Loop through elements

            // If we've wrapped around and processed all active elements, stop
            // This is a simple wrap-around; more robust logic needed for huge number of elements / long-running contract
            // A better approach might be to store active element IDs in a dynamic array or linked list,
            // but that adds complexity and gas costs for add/remove.
            // For this example, modulo is sufficient to cycle through potential IDs. We check `isElementActive`.
            if (totalElementsToCheck == 0) break; // Handle case with no elements

            if (isElementActive[currentElementId] && !lockedElements[currentElementId]) {
                 // Calculate decay based on blocks since last modification/refresh
                uint256 blocksSinceLastModification = block.number - elements[currentElementId].lastModifiedBlock;
                uint256 decayAmount = (blocksSinceLastModification * decayRate) / evolutionMinInterval; // Scale decay by interval

                if (elements[currentElementId].energy > decayAmount) {
                    elements[currentElementId].energy -= decayAmount;
                } else {
                    // Element energy depleted, remove it
                    isElementActive[currentElementId] = false;
                    _activeElementCount--;
                    elementsRemoved++;
                    // Optional: delete elements[currentElementId]; // Saves gas but removes history lookup
                }
                elementsProcessed++;
            } else if (isElementActive[currentElementId] && lockedElements[currentElementId]) {
                // Locked elements still refresh their decay clock but don't decay
                 elements[currentElementId].lastModifiedBlock = block.number; // Prevents huge decay if unlocked later
                 elementsProcessed++; // Count locked elements as processed in the batch check
            }

             if (elementsProcessed >= _evolutionBatchSize) {
                 // Processed enough for this batch
                 _nextElementIdForEvolution = (currentElementId + 1) % totalElementsToCheck; // Set start for next call
                 break; // Exit loop
             }
        }

        // Simulate external influence on global canvas parameters (example: slightly shift 'color' based on block hash)
        // Real-world usage would involve an oracle call or verifiable randomness
        _simulateOracleInfluence();

        emit CanvasEvolutionApplied(block.number, elementsProcessed, elementsRemoved);
    }

    // Internal helper for simulating external data influence
    function _simulateOracleInfluence() private {
        // Example: Introduce some "cosmic static" by subtly affecting parameters or adding ephemeral elements
        // This is a simple example using blockhash - NOT secure or truly random.
        // A real dApp would use Chainlink VRF or similar.
        if (block.number % 100 == 0) { // Trigger influence every 100 blocks (example)
             bytes32 blockHash = blockhash(block.number - 1); // Use previous block hash
             uint256 influenceFactor = uint256(blockHash);

             // Example influence: if factor is even, subtly change a global parameter (which we don't have yet)
             // if (influenceFactor % 2 == 0) {
             //     // Apply some effect... needs global parameters state variable
             // }

             // Example influence: add a temporary "glitch" element that decays quickly
             // This would require a different element type or special handling
             // For now, we just perform a check, illustrating where external influence logic would go.
             if (_activeElementCount < 500 && influenceFactor % 50 == 0) { // Add glitch if canvas isn't too full and factor is right
                 // In a real scenario, parameters could be derived from oracle data
                 bytes memory glitchParams = abi.encodePacked("glitch", influenceFactor % 255, influenceFactor % 100); // Example params
                 // We can't add a new element with msg.sender=address(this) and requirePayment easily here.
                 // A better pattern is to have evolution *modify* existing elements or global state
                 // based on oracle data, not add new ones this way.
                 // Let's skip adding a new element in this internal function for complexity reasons,
                 // and just leave the hook for state modification based on simulated data.
             }
        }
    }

    // --- Query Functions (Public) ---

    // Returns overall counts and status
    function getCanvasStateSummary() external view returns (uint256 totalElementsEverAdded, uint256 activeElementsCount, bool frozen, uint256 currentTotalFees) {
        return (_elementCount, _activeElementCount, canvasFrozen, address(this).balance);
    }

    // Returns the total number of element IDs ever created
    function getElementCount() external view returns (uint256) {
        return _elementCount;
    }

     // Returns the number of elements currently marked as active
    function getActiveElementCount() external view returns (uint256) {
        return _activeElementCount;
    }

    // Retrieves the full data for a specific element
    function getElementParameters(uint256 elementId) external view returns (Element memory) {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId); // Only return active elements
        return elements[elementId];
    }

     // Gets the current energy level of an element (might be partially decayed off-chain renderers calculate)
    function getElementEnergy(uint256 elementId) external view returns (uint256) {
         if (!isElementActive[elementId]) revert InvalidElementId(elementId);
         // Off-chain renderers should calculate current energy based on lastModifiedBlock and decayRate
         // Returning stored energy + calculation is gas intensive. Just return stored energy.
        return elements[elementId].energy;
    }

    // Checks if a specific element is locked
    function isElementLocked(uint256 elementId) external view returns (bool) {
        if (!isElementActive[elementId]) revert InvalidElementId(elementId); // Can only check lock status for active elements
        return lockedElements[elementId];
    }

    // Retrieves the message set by the curator
    function getCuratorMessage() external view returns (string memory) {
        return curatorMessage;
    }

    // Checks if the canvas is currently frozen
    function isCanvasFrozen() external view returns (bool) {
        return canvasFrozen;
    }

    // Retrieves the current base interaction fee
    function getBaseInteractionFee() external view returns (uint256) {
        return baseInteractionFee;
    }

    // Retrieves the current decay rate
    function getDecayRate() external view returns (uint256) {
        return decayRate;
    }

    // Retrieves the address of the linked NFT contract
    function getOwnershipNFTContract() external view returns (address) {
        return ownershipNFTContract;
    }

    // Retrieves the address of the current curator
    function getCurator() external view returns (address) {
        return curator;
    }

    // Retrieves the address of the contract owner
    function getOwner() external view returns (address) {
        return owner;
    }

    // Checks if an address holds at least one token from the linked NFT contract
    function checkNFTEligibility(address _address) public view returns (bool) {
        if (ownershipNFTContract == address(0)) return false; // No NFT contract set
        try IERC721Minimal(ownershipNFTContract).balanceOf(_address) returns (uint256 balance) {
            return balance > 0;
        } catch {
            // Handle cases where the address is not a valid contract or doesn't have balanceOf
            return false;
        }
    }

    // Returns the fee recipient address
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    // Returns the batch size used in evolution
    function getEvolutionBatchSize() external view returns (uint256) {
        return _evolutionBatchSize;
    }

     // Returns the starting ID for the next evolution batch
    function getNextElementIdForEvolution() external view returns (uint256) {
        return _nextElementIdForEvolution;
    }

     // Returns the block number of the last evolution
    function getLastEvolutionBlock() external view returns (uint256) {
        return lastEvolutionBlock;
    }

    // Fallback function to receive Ether for fees if sent directly (not recommended for interaction fees)
    receive() external payable {
        // Optional: Log receipt, or just let it accumulate
    }
}
```