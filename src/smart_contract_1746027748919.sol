Okay, here is a smart contract concept called `CryptoSculptor`. It's an advanced NFT contract where the NFTs are not static images, but rather dynamic data structures ("sculptures") that owners can modify over time by applying predefined "sculpting operations". These operations have costs and alter the on-chain parameters of the sculpture, leading to an evolving digital art piece (where the rendering/visualization happens off-chain based on the on-chain data).

This design incorporates:
*   **Dynamic NFTs:** The core asset changes state on-chain.
*   **Operation-Based Modification:** Users interact by applying specific, defined operations.
*   **On-Chain Data Representation:** The state of the art is stored directly in the contract.
*   **Admin-Configurable Mechanics:** Operations and costs can be managed by the owner/admin.
*   **Modification History:** A record of changes is kept.
*   **Freezing:** Ability to make a sculpture immutable.
*   **ERC-721 Compliance (Implemented manually to avoid direct OZ duplication):** Standard NFT ownership and transfer mechanics.
*   **ERC-165 Compliance:** Standard interface detection.
*   **Cost Mechanism:** Operations require ETH.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract implements a dynamic NFT system called CryptoSculptor.
// Users mint base sculptures, which are represented by on-chain parameters.
// Owners can apply predefined 'sculpting operations' to their sculptures
// by paying ETH, which modifies the sculpture's parameters stored on-chain.
// The resulting art visualization is generated off-chain based on the
// current on-chain parameters.

// --- OUTLINE ---
// 1. Imports (ERC721, ERC165 interfaces)
// 2. Error Definitions
// 3. Event Definitions
// 4. Enums and Structs (Sculpture data, SculptingOperation)
// 5. Main Contract Definition (Inherits interfaces)
// 6. State Variables (NFT data, Sculptures, Operations, Admin, Base URI, Pause state)
// 7. Constructor
// 8. ERC721 Core Functions (Manual Implementation)
//    - balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
//    - transferFrom, safeTransferFrom
//    - tokenURI (Custom logic)
// 9. ERC165 Support
// 10. IERC721Receiver Implementation (for safeTransferFrom to contracts)
// 11. Sculpting Core Logic
//    - mintBaseSculpture
//    - applySculptingOperation
//    - getSculptureParameters
//    - getSculptingOperationHistory
//    - getSculptureModificationCount
//    - getSculptureCreationTime
//    - getSculptureDataHash (Deterministic hash of parameters)
// 12. Sculpture State Control
//    - freezeSculpture
//    - unfreezeSculpture
//    - isSculptureFrozen
//    - burnSculpture
// 13. Sculpting Operation Management (Admin Only)
//    - addSculptingOperation
//    - removeSculptingOperation
//    - updateSculptingOperation
//    - getSculptingOperationDetails
//    - getAvailableOperationsCount
//    - getAllSculptingOperationIds (Helper)
// 14. Admin/Owner Controls (Basic Ownership, Pause, Withdraw, Base URI)
//    - transferOwnership
//    - renounceOwnership
//    - withdrawEth
//    - toggleSculptingPause
//    - setBaseTokenURI

// --- FUNCTION SUMMARY ---
// ERC721 Functions (Basic Implementation):
// - name() view: Returns the contract name.
// - symbol() view: Returns the contract symbol.
// - totalSupply() view: Returns the total number of sculptures minted.
// - balanceOf(owner) view: Returns the number of sculptures owned by an address.
// - ownerOf(tokenId) view: Returns the owner of a specific sculpture.
// - approve(to, tokenId): Approves an address to transfer a specific sculpture.
// - getApproved(tokenId) view: Returns the approved address for a specific sculpture.
// - setApprovalForAll(operator, approved): Approves or revokes approval for an operator for all owner's sculptures.
// - isApprovedForAll(owner, operator) view: Checks if an operator is approved for all of owner's sculptures.
// - transferFrom(from, to, tokenId): Transfers a sculpture, checks approval/ownership.
// - safeTransferFrom(from, to, tokenId): Transfers a sculpture, checks if receiver contract handles ERC721.
// - safeTransferFrom(from, to, tokenId, data): Transfers with extra data, checks if receiver contract handles ERC721.
// - tokenURI(tokenId) view: Returns the URI pointing to the metadata for a sculpture (dynamic based on state).

// ERC165 Functions:
// - supportsInterface(interfaceId) view: Indicates which interfaces the contract supports.

// IERC721Receiver Function:
// - onERC721Received(operator, from, tokenId, data) external: Callback for safeTransferFrom when transferring to a contract.

// Sculpting & NFT Management:
// - mintBaseSculpture() payable: Mints a new base sculpture for the caller. Requires payment.
// - applySculptingOperation(tokenId, operationId) payable: Applies a specified sculpting operation to the sculpture. Requires payment and checks permissions/state.
// - getSculptureParameters(tokenId) view: Retrieves the current array of parameters for a sculpture.
// - getSculptingOperationHistory(tokenId) view: Retrieves the list of operation IDs applied to a sculpture.
// - getSculptureModificationCount(tokenId) view: Returns the number of operations applied to a sculpture.
// - getSculptureCreationTime(tokenId) view: Returns the block timestamp when the sculpture was minted.
// - getSculptureDataHash(tokenId) view: Returns a hash of the sculpture's parameters and modification count (useful for off-chain verification).
// - freezeSculpture(tokenId): Freezes a sculpture, preventing further operations (only owner or approved).
// - unfreezeSculpture(tokenId): Unfreezes a sculpture (only owner or approved, or contract owner).
// - isSculptureFrozen(tokenId) view: Checks if a sculpture is frozen.
// - burnSculpture(tokenId): Destroys a sculpture (only owner or approved).

// Sculpting Operation Management (Admin Only):
// - addSculptingOperation(id, name, cost, opType, params) onlyContractOwner: Adds a new available sculpting operation.
// - removeSculptingOperation(id) onlyContractOwner: Removes an existing sculpting operation.
// - updateSculptingOperation(id, name, cost, opType, params) onlyContractOwner: Updates details of an existing sculpting operation.
// - getSculptingOperationDetails(id) view: Retrieves details about a specific sculpting operation.
// - getAvailableOperationsCount() view: Returns the total number of defined sculpting operations.
// - getAllSculptingOperationIds() view: Returns an array of all defined sculpting operation IDs.

// Admin/Owner Controls (Basic Ownable-like, Pause, Withdraw, Base URI):
// - owner() view: Returns the address of the contract owner.
// - transferOwnership(newOwner): Transfers contract ownership.
// - renounceOwnership(): Renounces contract ownership (sets to zero address).
// - withdrawEth(): Allows the contract owner to withdraw accumulated ETH from operation costs.
// - toggleSculptingPause(): Pauses/unpauses the ability to apply sculpting operations (doesn't affect minting or transfers).
// - setBaseTokenURI(baseURI): Sets the base URI for token metadata.

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol"; // Assume standard interface files are available
import {IERC721Receiver} from "./IERC721Receiver.sol"; // Assume standard interface files are available
import {IERC165} from "./IERC165.sol"; // Assume standard interface files are available

// Define interfaces manually or use standard ones available (e.g., in Remix or via importing standard libraries).
// For demonstration and adhering to "don't duplicate open source" rule in spirit,
// we will manually implement the logic corresponding to ERC721/ERC165 interfaces,
// rather than inheriting directly from OpenZeppelin's ERC721 contract.
// NOTE: A production contract would *always* use battle-tested libraries like OpenZeppelin.

// --- ERROR DEFINITIONS ---
error NotOwnerOrApproved();
error NotContractOwner();
error SculptureDoesNotExist();
error SculptureFrozen();
error SculptingPaused();
error OperationDoesNotExist();
error InsufficientPayment(uint256 required, uint256 provided);
error InvalidOperationParameters();
error ParameterIndexOutOfRange(uint256 index, uint256 length);
error MaxParametersExceeded(uint256 current, uint256 max);
error ApprovalCallerIsNotOwnerNorApproved();
error InvalidRecipient();
error TransferToERC721ReceiverRejected();
error ERC721InvalidApprove();

// --- EVENT DEFINITIONS ---
event SculptureMinted(uint256 indexed tokenId, address indexed owner, uint256 creationTime);
event OperationApplied(uint256 indexed tokenId, uint256 indexed operationId, address indexed applicant, uint256 cost);
event SculptureFrozen(uint256 indexed tokenId, address indexed freezer);
event SculptureUnfrozen(uint256 indexed tokenId, address indexed unfrozer);
event SculptureBurned(uint256 indexed tokenId, address indexed owner);
event OperationAdded(uint256 indexed operationId, string name, uint256 cost);
event OperationRemoved(uint256 indexed operationId);
event OperationUpdated(uint256 indexed operationId, string name, uint256 cost);
event SculptingPaused(bool isPaused);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event EthWithdrawn(address indexed recipient, uint256 amount);

// --- ENUMS AND STRUCTS ---

enum OperationType {
    ModifyParameter,      // Changes value of a specific parameter index
    RandomizeParameter,   // Sets a parameter index to a random value within a range
    AddParameter,         // Adds a new parameter at the end
    RemoveLastParameter,  // Removes the last parameter
    ShiftParameters,      // Adds a value to all parameters
    ConditionalModify     // Modify a parameter based on another parameter's value
    // More complex types could involve multiple parameters, hashing, etc.
}

struct SculptingOperation {
    uint256 id;              // Unique ID for the operation
    string name;             // Human-readable name (e.g., "Increase Brightness", "Randomize Shape")
    uint256 cost;            // Cost in wei to apply this operation
    OperationType opType;    // Type of operation
    uint256[] params;        // Parameters specific to the operation type (e.g., [index, value] for ModifyParameter, [index, min, max] for RandomizeParameter)
    bool exists;             // Helper to check if the operation ID is valid
}

struct Sculpture {
    uint256 id;                       // Token ID
    address owner;                    // Owner address
    uint256 creationTime;             // Block timestamp of minting
    uint256 modificationCount;        // Number of operations applied
    bool frozen;                      // If true, operations cannot be applied
    uint256[] parameters;             // The core data representing the sculpture's state
    uint256[] appliedOperationIds;    // History of applied operation IDs
    address approved;                 // ERC721 single approval
}


// --- MAIN CONTRACT ---
contract CryptoSculptor is IERC721, IERC165, IERC721Receiver {

    // --- STATE VARIABLES ---

    // ERC721 Standard State
    string private _name;
    string private _symbol;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners; // Maps token ID to owner
    uint256 private _totalSupply;
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Mapping from owner to operator to approval status

    // CryptoSculptor Specific State
    address private _contractOwner; // Basic ownership mechanism, similar to OpenZeppelin's Ownable
    uint256 private _nextTokenId; // Counter for minting new sculptures
    string private _baseTokenURI; // Base URI for metadata
    bool private _sculptingPaused; // Global pause for sculpting operations
    uint256 private constant MAX_PARAMETERS_PER_SCULPTURE = 100; // Example limit to prevent unbounded growth

    // Sculpture data storage
    mapping(uint256 => Sculpture) private _sculptures;

    // Sculpting Operations storage
    mapping(uint256 => SculptingOperation) private _sculptingOperations;
    uint256[] private _availableOperationIds; // Array to keep track of operation IDs

    // Interface IDs for ERC165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // Optional metadata interface

    // --- MODIFIERS ---
    modifier onlyContractOwner() {
        if (msg.sender != _contractOwner) revert NotContractOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_sculptingPaused) revert SculptingPaused();
        _;
    }

    modifier whenSculptingEnabled(uint256 tokenId) {
        if (_sculptures[tokenId].frozen) revert SculptureFrozen();
        _;
    }

    modifier onlySculptureOwnerOrApproved(uint256 tokenId) {
        if (_sculptures[tokenId].owner != msg.sender && _sculptures[tokenId].approved != msg.sender && !_operatorApprovals[_sculptures[tokenId].owner][msg.sender]) {
             revert ApprovalCallerIsNotOwnerNorApproved();
        }
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(string memory name_, string memory symbol_, string memory baseTokenURI_) {
        _name = name_;
        _symbol = symbol_;
        _contractOwner = msg.sender;
        _baseTokenURI = baseTokenURI_;
        _nextTokenId = 1; // Start token IDs from 1
        _sculptingPaused = false;

        emit OwnershipTransferred(address(0), _contractOwner);
    }

    // --- ERC721 CORE FUNCTIONS (Manual Implementation) ---

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert InvalidRecipient();
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert SculptureDoesNotExist();
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _owners[tokenId];
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerIsNotOwnerNorApproved();
        }
        if (to == owner) revert ERC721InvalidApprove();

        _sculptures[tokenId].approved = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        return _sculptures[tokenId].approved;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert ERC721InvalidApprove(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        if (_owners[tokenId] != from) revert NotOwnerOrApproved(); // Owner must be 'from'

        // Check approval: must be the owner, the approved address for the token, or an approved operator
        if (msg.sender != from && getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender)) {
             revert NotOwnerOrApproved();
        }
        if (to == address(0)) revert InvalidRecipient();

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        transferFrom(from, to, tokenId); // Perform the transfer
        // Check if the recipient is a contract and, if so, if it implements IERC721Receiver
        if (to.code.length > 0) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            if (retval != IERC721Receiver.onERC721Received.selector) {
                revert TransferToERC721ReceiverRejected();
            }
        }
    }

    // Internal transfer function (used by transferFrom and safeTransferFrom)
    function _transfer(address from, address to, uint256 tokenId) internal {
        // Clear approval before transfer
        _sculptures[tokenId].approved = address(0);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;
        _sculptures[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        // Return a URI that points to an external service resolving the metadata based on the on-chain state
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    // Helper to convert uint256 to string (simplified)
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    // --- ERC165 SUPPORT ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA; // Optional metadata support
    }

    // --- IERC721RECEIVER IMPLEMENTATION ---
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external virtual override returns (bytes4) {
        // Default behavior: accept the transfer only if the recipient contract is this contract
        // This prevents sculptures from being locked in arbitrary contracts via safeTransferFrom
        // If you wanted to allow transfers to other specific ERC721Receiver contracts, you'd
        // need more complex logic or a registry.
        if (msg.sender != address(this)) {
            revert TransferToERC721ReceiverRejected();
        }
        // This default implementation doesn't do anything with operator, from, tokenId, or data
        // but confirms the contract is ERC721Receiver compliant.
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- SCULPTING & NFT MANAGEMENT ---

    /**
     * @notice Mints a new base sculpture NFT.
     * @dev Initializes a new sculpture with a base set of parameters.
     */
    function mintBaseSculpture() public payable returns (uint256) {
        // Optional: require a minting fee
        // require(msg.value >= MINT_COST, "Insufficient ETH for minting");
        // (Currently minting is free in this example unless you add a fee check)

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        // Initialize base parameters (example: 3 parameters, all set to 0 initially)
        uint256[] memory initialParams = new uint256[](3);
        initialParams[0] = 0;
        initialParams[1] = 0;
        initialParams[2] = 0;
        // You could make the base parameters slightly random or based on sender address/timestamp

        _sculptures[tokenId] = Sculpture({
            id: tokenId,
            owner: msg.sender,
            creationTime: block.timestamp,
            modificationCount: 0,
            frozen: false,
            parameters: initialParams,
            appliedOperationIds: new uint256[](0),
            approved: address(0)
        });

        _owners[tokenId] = msg.sender;
        _balances[msg.sender]++;
        _totalSupply++;

        emit SculptureMinted(tokenId, msg.sender, block.timestamp);

        return tokenId;
    }

    /**
     * @notice Applies a predefined sculpting operation to a sculpture.
     * @param tokenId The ID of the sculpture to modify.
     * @param operationId The ID of the sculpting operation to apply.
     * @dev Requires payment of the operation cost and checks sculpture state (frozen, paused).
     */
    function applySculptingOperation(uint256 tokenId, uint256 operationId) public payable whenNotPaused whenSculptingEnabled(tokenId) {
        Sculpture storage sculpture = _sculptures[tokenId];
        if (sculpture.owner == address(0)) revert SculptureDoesNotExist();
        if (sculpture.owner != msg.sender && sculpture.approved != msg.sender && !isApprovedForAll(sculpture.owner, msg.sender)) {
             revert ApprovalCallerIsNotOwnerNorApproved();
        }

        SculptingOperation storage operation = _sculptingOperations[operationId];
        if (!operation.exists) revert OperationDoesNotExist();

        if (msg.value < operation.cost) revert InsufficientPayment(operation.cost, msg.value);

        // Apply the state change based on operation type
        _applyOperationLogic(sculpture, operation);

        sculpture.modificationCount++;
        sculpture.appliedOperationIds.push(operationId);

        // Transfer the operation cost to the contract owner
        if (operation.cost > 0) {
            // Note: using transfer() for simplicity, send() or call() might be preferred in production
            // based on desired reentrancy protection vs guarantee of execution.
            (bool success,) = payable(_contractOwner).call{value: operation.cost}("");
            require(success, "ETH transfer failed");
        }

        // Refund excess ETH if any
        if (msg.value > operation.cost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - operation.cost}("");
             require(success, "ETH refund failed");
        }


        emit OperationApplied(tokenId, operationId, msg.sender, operation.cost);
    }

    /**
     * @notice Internal function to apply the actual state change based on operation type.
     * @dev Handles different operation types and their specific parameters.
     */
    function _applyOperationLogic(Sculpture storage sculpture, SculptingOperation storage operation) internal {
        uint256[] storage params = sculpture.parameters;
        uint256[] memory opParams = operation.params; // Use memory copy for opParams

        if (operation.opType == OperationType.ModifyParameter) {
            // opParams: [parameterIndex, newValue]
            if (opParams.length != 2) revert InvalidOperationParameters();
            uint256 paramIndex = opParams[0];
            uint256 newValue = opParams[1];
            if (paramIndex >= params.length) revert ParameterIndexOutOfRange(paramIndex, params.length);
            params[paramIndex] = newValue;

        } else if (operation.opType == OperationType.RandomizeParameter) {
            // opParams: [parameterIndex, minValue, maxValue]
             if (opParams.length != 3) revert InvalidOperationParameters();
            uint256 paramIndex = opParams[0];
            uint256 minValue = opParams[1];
            uint256 maxValue = opParams[2];
            if (paramIndex >= params.length) revert ParameterIndexOutOfRange(paramIndex, params.length);
            if (minValue > maxValue) revert InvalidOperationParameters();

            // Basic pseudo-randomness (NOT secure for high-value operations!)
            // Combining various block and transaction data
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                block.number,
                tx.origin,
                msg.sender,
                sculpture.id,
                sculpture.modificationCount,
                operation.id
            )));

            uint256 range = maxValue - minValue + 1;
            if (range == 0) { // Handle case where minValue == maxValue
                 params[paramIndex] = minValue;
            } else {
                 params[paramIndex] = minValue + (randomSeed % range);
            }


        } else if (operation.opType == OperationType.AddParameter) {
            // opParams: [initialValue] (optional, default 0)
            if (params.length >= MAX_PARAMETERS_PER_SCULPTURE) revert MaxParametersExceeded(params.length, MAX_PARAMETERS_PER_SCULPTURE);
            uint256 initialValue = (opParams.length > 0) ? opParams[0] : 0;
            params.push(initialValue);

        } else if (operation.opType == OperationType.RemoveLastParameter) {
            // opParams: []
            if (opParams.length != 0) revert InvalidOperationParameters();
            if (params.length > 0) {
                params.pop();
            }
            // Silently fail if no parameters to remove, or add an error? Let's allow popping an empty array silently.

        } else if (operation.opType == OperationType.ShiftParameters) {
            // opParams: [shiftValue]
            if (opParams.length != 1) revert InvalidOperationParameters();
            uint256 shiftValue = opParams[0];
            for (uint256 i = 0; i < params.length; i++) {
                params[i] += shiftValue; // Note: potential overflow if adding large values to max uint256
            }

        } else if (operation.opType == OperationType.ConditionalModify) {
             // opParams: [conditionParamIndex, conditionValue, modifyParamIndex, modifyValue]
             if (opParams.length != 4) revert InvalidOperationParameters();
             uint256 conditionParamIndex = opParams[0];
             uint256 conditionValue = opParams[1];
             uint256 modifyParamIndex = opParams[2];
             uint256 modifyValue = opParams[3];

             if (conditionParamIndex >= params.length) revert ParameterIndexOutOfRange(conditionParamIndex, params.length);
             if (modifyParamIndex >= params.length) revert ParameterIndexOutOfRange(modifyParamIndex, params.length);

             if (params[conditionParamIndex] == conditionValue) {
                 params[modifyParamIndex] = modifyValue;
             }
        }
        // Add more operation types here as needed for complexity/creativity
    }

    /**
     * @notice Retrieves the current array of parameters for a sculpture.
     * @param tokenId The ID of the sculpture.
     * @return The array of uint256 parameters.
     */
    function getSculptureParameters(uint256 tokenId) public view returns (uint256[] memory) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        return _sculptures[tokenId].parameters;
    }

    /**
     * @notice Retrieves the history of applied sculpting operation IDs for a sculpture.
     * @param tokenId The ID of the sculpture.
     * @return An array of operation IDs applied in order.
     */
    function getSculptingOperationHistory(uint256 tokenId) public view returns (uint256[] memory) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        return _sculptures[tokenId].appliedOperationIds;
    }

     /**
     * @notice Returns the number of sculpting operations applied to a sculpture.
     * @param tokenId The ID of the sculpture.
     * @return The total modification count.
     */
    function getSculptureModificationCount(uint256 tokenId) public view returns (uint256) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        return _sculptures[tokenId].modificationCount;
    }

    /**
     * @notice Returns the block timestamp when the sculpture was minted.
     * @param tokenId The ID of the sculpture.
     * @return The creation timestamp.
     */
    function getSculptureCreationTime(uint256 tokenId) public view returns (uint256) {
         if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
         return _sculptures[tokenId].creationTime;
    }

     /**
     * @notice Generates a hash representing the current state of a sculpture (parameters + modification count).
     * @dev Useful for off-chain verification or deterministic rendering.
     * @param tokenId The ID of the sculpture.
     * @return A keccak256 hash of the sculpture's state data.
     */
    function getSculptureDataHash(uint256 tokenId) public view returns (bytes32) {
        if (_owners[tokenId] == address(0)) revert SculptureDoesNotExist();
        Sculpture storage sculpture = _sculptures[tokenId];
        // Encode parameters and modification count. Adding ID and creation time for robustness.
        return keccak256(abi.encode(
            sculpture.id,
            sculpture.creationTime,
            sculpture.modificationCount,
            sculpture.parameters // abi.encode handles dynamic arrays
        ));
    }

    // --- SCULPTURE STATE CONTROL ---

    /**
     * @notice Freezes a sculpture, preventing further sculpting operations.
     * @param tokenId The ID of the sculpture to freeze.
     * @dev Can only be called by the sculpture owner, approved address, or contract owner.
     */
    function freezeSculpture(uint256 tokenId) public onlySculptureOwnerOrApproved(tokenId) {
        Sculpture storage sculpture = _sculptures[tokenId];
        if (sculpture.owner == address(0)) revert SculptureDoesNotExist();
        if (sculpture.frozen) return; // Already frozen

        sculpture.frozen = true;
        emit SculptureFrozen(tokenId, msg.sender);
    }

     /**
     * @notice Unfreezes a sculpture, allowing further sculpting operations.
     * @param tokenId The ID of the sculpture to unfreeze.
     * @dev Can only be called by the sculpture owner, approved address, or contract owner.
     *      Contract owner can unfreeze regardless of who froze it.
     */
    function unfreezeSculpture(uint256 tokenId) public {
        Sculpture storage sculpture = _sculptures[tokenId];
        if (sculpture.owner == address(0)) revert SculptureDoesNotExist();

         // Allow owner/approved OR contract owner to unfreeze
        if (sculpture.owner != msg.sender && sculpture.approved != msg.sender && !isApprovedForAll(sculpture.owner, msg.sender) && msg.sender != _contractOwner) {
             revert NotOwnerOrApproved();
        }

        if (!sculpture.frozen) return; // Not frozen

        sculpture.frozen = false;
        emit SculptureUnfrozen(tokenId, msg.sender);
    }

     /**
     * @notice Checks if a sculpture is frozen.
     * @param tokenId The ID of the sculpture.
     * @return True if frozen, false otherwise.
     */
    function isSculptureFrozen(uint256 tokenId) public view returns (bool) {
        if (_owners[tokenId] == address(0)) return false; // Non-existent is not frozen
        return _sculptures[tokenId].frozen;
    }

    /**
     * @notice Burns (destroys) a sculpture.
     * @param tokenId The ID of the sculpture to burn.
     * @dev Can only be called by the sculpture owner or approved address.
     */
    function burnSculpture(uint256 tokenId) public onlySculptureOwnerOrApproved(tokenId) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert SculptureDoesNotExist();

        // Clear state
        _balances[owner]--;
        delete _owners[tokenId];
        delete _sculptures[tokenId]; // This clears the struct including parameters and history
        _totalSupply--;

        emit Transfer(owner, address(0), tokenId); // Standard ERC721 burn event format
        emit SculptureBurned(tokenId, owner);
    }

    // --- SCULPTING OPERATION MANAGEMENT (Admin Only) ---

    /**
     * @notice Adds a new type of sculpting operation available for use.
     * @param id Unique ID for the operation.
     * @param name Name of the operation.
     * @param cost ETH cost in wei.
     * @param opType The type of operation logic.
     * @param params Parameters for the operation logic.
     * @dev Only callable by the contract owner. Reverts if ID already exists.
     */
    function addSculptingOperation(uint256 id, string memory name, uint256 cost, OperationType opType, uint256[] memory params) public onlyContractOwner {
        if (_sculptingOperations[id].exists) {
            revert("Operation ID already exists");
        }
        _sculptingOperations[id] = SculptingOperation({
            id: id,
            name: name,
            cost: cost,
            opType: opType,
            params: params, // Store a copy of the params array
            exists: true
        });
        _availableOperationIds.push(id);
        emit OperationAdded(id, name, cost);
    }

     /**
     * @notice Removes an existing sculpting operation.
     * @param id The ID of the operation to remove.
     * @dev Only callable by the contract owner. Note: Does not affect already applied operations stored in sculpture history.
     */
    function removeSculptingOperation(uint256 id) public onlyContractOwner {
        if (!_sculptingOperations[id].exists) {
            revert OperationDoesNotExist();
        }
        // Remove from the list of available IDs (simple but potentially inefficient for large arrays)
        for (uint i = 0; i < _availableOperationIds.length; i++) {
            if (_availableOperationIds[i] == id) {
                _availableOperationIds[i] = _availableOperationIds[_availableOperationIds.length - 1];
                _availableOperationIds.pop();
                break;
            }
        }
        delete _sculptingOperations[id];
        emit OperationRemoved(id);
    }

    /**
     * @notice Updates details of an existing sculpting operation.
     * @param id The ID of the operation to update.
     * @param name New name.
     * @param cost New ETH cost.
     * @param opType New operation type.
     * @param params New parameters.
     * @dev Only callable by the contract owner. Reverts if ID does not exist.
     */
    function updateSculptingOperation(uint256 id, string memory name, uint256 cost, OperationType opType, uint256[] memory params) public onlyContractOwner {
        if (!_sculptingOperations[id].exists) {
            revert OperationDoesNotExist();
        }
        SculptingOperation storage op = _sculptingOperations[id];
        op.name = name;
        op.cost = cost;
        op.opType = opType;
        op.params = params; // Overwrite existing params

        emit OperationUpdated(id, name, cost);
    }

    /**
     * @notice Retrieves details about a specific sculpting operation.
     * @param id The ID of the operation.
     * @return operationId, name, cost, opType, params, exists.
     */
    function getSculptingOperationDetails(uint256 id) public view returns (uint256 operationId, string memory name, uint256 cost, OperationType opType, uint256[] memory params, bool exists) {
        SculptingOperation storage op = _sculptingOperations[id];
        if (!op.exists) revert OperationDoesNotExist(); // Or return empty/default values? Reverting is safer.
        return (op.id, op.name, op.cost, op.opType, op.params, op.exists);
    }

     /**
     * @notice Returns the number of currently defined sculpting operations.
     * @dev This counts unique IDs added, including any that might have been "removed" from the array but still exist in the map. Use getAllSculptingOperationIds for active ones.
     * @return The count of operations.
     */
     function getAvailableOperationsCount() public view returns (uint256) {
         return _availableOperationIds.length; // This counts the IDs currently in the array
     }

     /**
      * @notice Returns an array of all currently active sculpting operation IDs.
      * @dev Useful for off-chain applications to list available operations.
      * @return An array of uint256 operation IDs.
      */
     function getAllSculptingOperationIds() public view returns (uint256[] memory) {
         return _availableOperationIds;
     }


    // --- ADMIN/OWNER CONTROLS (Basic Ownable-like, Pause, Withdraw, Base URI) ---

    /**
     * @notice Returns the address of the current contract owner.
     */
    function owner() public view returns (address) {
        return _contractOwner;
    }

    /**
     * @notice Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     * @dev Only callable by the current contract owner. Renounces ownership if newOwner is zero address.
     */
    function transferOwnership(address newOwner) public onlyContractOwner {
        if (newOwner == address(0)) {
             renounceOwnership();
        } else {
             address oldOwner = _contractOwner;
            _contractOwner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

    /**
     * @notice Renounces contract ownership.
     * @dev The contract will no longer have a designated owner. This action is irreversible.
     */
    function renounceOwnership() public onlyContractOwner {
        address oldOwner = _contractOwner;
        _contractOwner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }


    /**
     * @notice Allows the contract owner to withdraw accumulated ETH from operation costs.
     * @dev Transfers the entire contract balance to the owner's address.
     */
    function withdrawEth() public onlyContractOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(_contractOwner).call{value: balance}("");
        require(success, "ETH withdrawal failed");
        emit EthWithdrawn(_contractOwner, balance);
    }

    /**
     * @notice Toggles the global pause state for sculpting operations.
     * @dev When paused, applySculptingOperation will revert. Does not affect minting or transfers. Only callable by the contract owner.
     */
    function toggleSculptingPause() public onlyContractOwner {
        _sculptingPaused = !_sculptingPaused;
        emit SculptingPaused(_sculptingPaused);
    }

     /**
     * @notice Sets the base URI for token metadata.
     * @param baseURI The new base URI (e.g., "ipfs://<cid>/").
     * @dev The tokenURI function will append the tokenId to this base. Only callable by the contract owner.
     */
    function setBaseTokenURI(string memory baseURI) public onlyContractOwner {
        _baseTokenURI = baseURI;
        // Optional: Emit an event indicating the URI change
    }

    // Fallback/Receive functions to accept ETH for operations
    receive() external payable {
        // Allow receiving ETH. It will accumulate until withdrawn by the owner.
        // If a sculpting operation is called with value, it will check the amount.
        // Unsolicited ETH goes to the contract balance.
    }

    fallback() external payable {
        // Allow receiving ETH if someone sends data along with it.
    }
}

// Minimal ERC721 and ERC165 interface definitions just to make the above compile
// assuming they are not imported from a library. In a real scenario, you'd import them.
// NOTE: If you use actual OpenZeppelin imports, you would inherit like `contract CryptoSculptor is ERC721, ERC165, IERC721Receiver, Ownable`.
// The manual implementation above is purely to satisfy the "don't duplicate" rule by
// not relying on specific internal OZ helper functions or state variables.

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // Optional ERC721Metadata
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```

**Explanation of Advanced/Creative/Trendy Aspects:**

1.  **Dynamic, Mutable NFTs:** The core idea isn't a static image linked via IPFS. The actual *state* of the "art" (the `parameters` array) is stored and changed on-chain. This creates a different interaction model than typical NFTs.
2.  **Operation-Based Evolution:** Instead of free-form changes, modifications are governed by predefined `SculptingOperation` types. This is a structured way to allow evolution and can represent different "tools" or "actions" available to the owner.
3.  **On-Chain Parameter Storage:** Storing the `uint256[] parameters` directly allows anyone to read the current state of any sculpture from the blockchain. This is gas-intensive for large parameter sets but guarantees transparency and permanence of the state.
4.  **Configurable Operations:** The contract owner can add, remove, and update operations. This allows for evolving mechanics, limited-time events (adding/removing operations), or balancing costs over time. This is more dynamic than a fixed set of contract functions.
5.  **Modification History:** Storing `appliedOperationIds` provides a lineage for each sculpture. You can trace back the sequence of operations that led to its current state. This adds narrative and historical depth to the NFT.
6.  **Freezing Mechanism:** Owners can choose to lock their sculpture's state, making it immutable from that point on. This is like finalizing a piece of art.
7.  **On-Chain Randomness (with Caveats):** The `RandomizeParameter` operation demonstrates using on-chain data (`block.timestamp`, `block.difficulty`, etc.) to introduce variation. While not truly cryptographically secure randomness, it provides a common, verifiable source of entropy for on-chain processes within the game/art context. The code includes a warning about its limitations.
8.  **Deterministic Data Hash:** `getSculptureDataHash` provides a verifiable on-chain fingerprint of the sculpture's state. Off-chain rendering services can use this to ensure they are visualizing the correct, unaltered state.
9.  **Decoupled Rendering:** The contract manages the *data* of the art. The `tokenURI` points to a service that *interprets* this data (via `getSculptureParameters`, `getSculptingOperationHistory`, etc.) to generate images, animations, or other visualizations. This separation of concerns is crucial for complex on-chain data art.
10. **Manual ERC-721 Implementation:** While less safe than using OpenZeppelin, implementing the core ERC-721 functions manually (as requested by the "don't duplicate open source" constraint in spirit) demonstrates understanding of the standard's mechanics and avoids relying on pre-built library functions for the core NFT behavior.
11. **Extensible Operation Types:** The `OperationType` enum and the `_applyOperationLogic` function are designed to be easily extended with new, creative ways to modify the parameters (e.g., operations that affect multiple parameters, operations based on external data if using oracles, operations that cost a different token).

This contract provides a framework for an interactive, evolving NFT project where the art itself is a living data structure on the blockchain, manipulated through controlled, costly operations.