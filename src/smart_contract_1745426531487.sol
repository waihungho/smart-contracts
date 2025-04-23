Okay, here is a Solidity smart contract implementing a "Multi-Modal, Resource-Bound, Evolving NFT" concept. This goes beyond standard NFTs by allowing tokens to:

1.  Reference multiple types of external data (not just one `tokenURI`).
2.  Have dynamic properties stored on-chain.
3.  Exist in different "modes" or states.
4.  Be bound to or *own* other digital assets (ERC20, ERC721, ERC1155) as "resources".
5.  "Evolve" or change properties based on internal state or resource bindings.
6.  "Consume" other tokens, transferring resources/properties.

It avoids duplicating basic ERC721 implementations found everywhere by adding these layers of interaction and data management.

---

**Outline and Function Summary**

**Contract Name:** `MultiModalNFTProtocol`

**Inheritance:** ERC721, ERC721Enumerable, Ownable, Pausable, ERC165

**Core Concepts:**
*   **Multi-Modal Data:** An NFT can have multiple references to external data (e.g., different IPFS hashes for image, audio, 3D model, text) categorized by `bytes32` data types.
*   **Dynamic Properties:** On-chain storage of key-value properties that can change over time or interaction.
*   **Modes:** NFTs can transition between predefined "modes" affecting their appearance or behavior (off-chain).
*   **Resource Binding:** NFTs can be "bound" to other tokens (ERC20, ERC721, ERC1155), effectively owning or having access to them.
*   **Evolution:** A function that changes the NFT's properties or mode, potentially triggered by resource bindings or other conditions.
*   **Consumption:** An NFT can "consume" another token, transferring its properties and/or resources before the consumed token is burned.

**Functions:**

1.  **ERC721/Enumerable/Basic:**
    *   `constructor(string name, string symbol, string baseURI)`: Initializes the contract with name, symbol, and a base URI for metadata.
    *   `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface check.
    *   `tokenURI(uint256 tokenId)`: Returns the standard token URI, potentially incorporating dynamic state (points to a service).
    *   `totalSupply()`: Returns the total number of tokens minted.
    *   `tokenByIndex(uint256 index)`: Returns the token ID at a given index.
    *   `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns the token ID owned by an address at a given index.
    *   `mint(address to, uint256 tokenId)`: Mints a new token to an address. Only callable by owner.

2.  **Multi-Modal Data Management:**
    *   `addSupportedDataType(bytes32 dataType)`: Owner adds a new supported data type identifier.
    *   `removeSupportedDataType(bytes32 dataType)`: Owner removes a supported data type identifier.
    *   `isSupportedDataType(bytes32 dataType)`: Checks if a data type is supported.
    *   `addDataReference(uint256 tokenId, bytes32 dataType, string uri)`: Adds or updates a data reference for a token and type. Callable by token owner or approved.
    *   `removeDataReference(uint256 tokenId, bytes32 dataType)`: Removes a data reference. Callable by token owner or approved.
    *   `getDataReference(uint256 tokenId, bytes32 dataType)`: Gets the URI for a specific data type and token ID.
    *   `getAllDataTypesForToken(uint256 tokenId)`: Returns a list of all data types associated with a token ID.

3.  **Mode Management:**
    *   `addAvailableMode(bytes32 mode)`: Owner adds a new available mode identifier.
    *   `removeAvailableMode(bytes32 mode)`: Owner removes an available mode identifier.
    *   `setMode(uint256 tokenId, bytes32 mode)`: Sets the mode of a token. Callable by token owner or approved.
    *   `getMode(uint256 tokenId)`: Gets the current mode of a token.
    *   `getAvailableModes()`: Returns a list of all available mode identifiers.

4.  **Dynamic Property Management:**
    *   `setProperty(uint256 tokenId, string propertyName, bytes propertyValue)`: Sets a dynamic property (key-value) for a token. Callable by token owner or approved. Value is stored as bytes for flexibility.
    *   `getProperty(uint256 tokenId, string propertyName)`: Gets the value of a dynamic property.
    *   `getAllPropertiesForToken(uint256 tokenId)`: Returns a list of all property names associated with a token.

5.  **Resource Binding:**
    *   `bindResource(uint256 tokenId, address resourceAddress, uint256 resourceId, uint256 amount)`: Binds a specified amount of a resource token (ERC20, ERC721, ERC1155) to this NFT. Requires prior approval/transfer of the resource token. Callable by token owner or approved. `resourceId` is 0 for ERC20.
    *   `unbindResource(uint256 tokenId, address resourceAddress, uint256 resourceId, uint256 amount)`: Unbinds and transfers a specified amount of a resource token back to the owner of the NFT. Callable by token owner or approved.
    *   `getResourceBindings(uint256 tokenId, address resourceAddress, uint256 resourceId)`: Gets the amount of a specific resource bound to a token.
    *   `getTotalBoundResourceAmount(uint256 tokenId, address resourceAddress)`: Gets the total amount of an ERC20 resource bound (summing across all potential resourceIds, though typically ERC20 resourceId is 0).
    *   `getAllResourceBindingsForToken(uint256 tokenId)`: Returns a list of all resource addresses bound to a token. (Note: Getting full details like resourceId/amount in one call is complex due to mappings of mappings; this version lists addresses). A more complex version would return structs/tuples.

6.  **Advanced Interaction:**
    *   `evolve(uint256 tokenId, bytes32 evolutionType)`: Triggers an evolution process for the token, potentially changing properties or mode based on `evolutionType` and current state/resources. Callable by token owner or approved. Example internal logic checks: sufficient resources bound, specific property values met, etc.
    *   `consumeToken(uint256 consumerTokenId, uint256 consumedTokenId)`: Allows `consumerTokenId` to consume `consumedTokenId`. Transfers resources and/or properties from consumed to consumer, then burns `consumedTokenId`. Callable by the owner/approved of `consumerTokenId` (and requires owner/approved status for `consumedTokenId`).
    *   `batchSetProperties(uint256 tokenId, string[] propertyNames, bytes[] propertyValues)`: Sets multiple properties in a single transaction. Callable by token owner or approved.
    *   `batchBindResources(uint256 tokenId, address[] resourceAddresses, uint256[] resourceIds, uint256[] amounts)`: Binds multiple resources in a single transaction. Callable by token owner or approved.

7.  **Access Control/Pausable:**
    *   `pause()`: Owner pauses the contract.
    *   `unpause()`: Owner unpauses the contract.
    *   `renounceOwnership()`: Owner renounces ownership.
    *   `transferOwnership(address newOwner)`: Owner transfers ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For resource binding examples
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol"; // For resource binding examples

// --- Outline and Function Summary ---
// Contract Name: MultiModalNFTProtocol
// Inheritance: ERC721, ERC721Enumerable, Ownable, Pausable, ERC165
// Core Concepts: Multi-Modal Data, Dynamic Properties, Modes, Resource Binding, Evolution, Consumption
// Function Categories:
// 1. ERC721/Enumerable/Basic: constructor, supportsInterface, tokenURI, totalSupply, tokenByIndex, tokenOfOwnerByIndex, mint
// 2. Multi-Modal Data Management: addSupportedDataType, removeSupportedDataType, isSupportedDataType, addDataReference, removeDataReference, getDataReference, getAllDataTypesForToken
// 3. Mode Management: addAvailableMode, removeAvailableMode, setMode, getMode, getAvailableModes
// 4. Dynamic Property Management: setProperty, getProperty, getAllPropertiesForToken
// 5. Resource Binding: bindResource, unbindResource, getResourceBindings, getTotalBoundResourceAmount, getAllResourceBindingsForToken
// 6. Advanced Interaction: evolve, consumeToken, batchSetProperties, batchBindResources
// 7. Access Control/Pausable: pause, unpause, renounceOwnership, transferOwnership

/**
 * @title MultiModalNFTProtocol
 * @dev An advanced ERC721 contract supporting multi-modal data references,
 * dynamic on-chain properties, discrete modes, resource binding to other tokens,
 * evolution mechanics, and token consumption.
 * This contract is designed to be more than just a pointer to off-chain metadata.
 */
contract MultiModalNFTProtocol is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.StringSet;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Maps tokenId -> dataType -> uri (for multi-modal data references)
    mapping(uint256 tokenId => mapping(bytes32 dataType => string uri)) private _dataReferences;

    // Set of supported data types (defined by owner)
    EnumerableSet.Bytes32Set private _supportedDataTypes;

    // Maps tokenId -> current mode (bytes32 for flexibility)
    mapping(uint256 tokenId => bytes32) private _tokenMode;

    // Set of available modes (defined by owner)
    EnumerableSet.Bytes32Set private _availableModes;

    // Maps tokenId -> propertyName -> propertyValue (dynamic on-chain properties)
    mapping(uint256 tokenId => mapping(string propertyName => bytes propertyValue)) private _tokenProperties;

    // Tracks property names set for each token for retrieval
    mapping(uint256 tokenId => EnumerableSet.StringSet) private _tokenPropertyNames;

    // Maps tokenId -> resourceAddress -> resourceId -> amount bound
    mapping(uint256 tokenId => mapping(address resourceAddress => mapping(uint256 resourceId => uint256 amount))) private _resourceBindings;

    // Tracks resource addresses bound for each token for retrieval
    mapping(uint256 tokenId => EnumerableSet.AddressSet) private _tokenBoundResourceAddresses;

    string private _baseTokenURI;

    // --- Events ---
    event DataTypeSupported(bytes32 indexed dataType, bool supported);
    event DataReferenceUpdated(uint256 indexed tokenId, bytes32 indexed dataType, string uri);
    event DataReferenceRemoved(uint256 indexed tokenId, bytes32 indexed dataType);
    event ModeAvailable(bytes32 indexed mode, bool available);
    event ModeChanged(uint256 indexed tokenId, bytes32 indexed oldMode, bytes32 indexed newMode);
    event PropertySet(uint256 indexed tokenId, string indexed propertyName, bytes propertyValue);
    event ResourceBound(uint256 indexed tokenId, address indexed resourceAddress, uint256 indexed resourceId, uint256 amount);
    event ResourceUnbound(uint256 indexed tokenId, address indexed resourceAddress, uint256 indexed resourceId, uint256 amount);
    event Evolved(uint256 indexed tokenId, bytes32 indexed evolutionType);
    event TokenConsumed(uint256 indexed consumerTokenId, uint256 indexed consumedTokenId);

    // --- Modifiers ---
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
        _;
    }

    // --- Constructor ---
    constructor(string name, string symbol, string baseURI)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- ERC721Enumerable Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._burn(tokenId);
        // Clean up state associated with the burned token
        // Note: Resource bindings are NOT automatically unbound.
        // They remain tracked but inaccessible via this NFT owner.
        // A separate process would be needed to reclaim them or they are lost.
        // For simplicity, we only clean up mappings directly owned by the token.
        delete _dataReferences[tokenId];
        delete _tokenMode[tokenId];
        // Clear property names set
        string[] memory propNames = getAllPropertiesForToken(tokenId);
        for(uint i = 0; i < propNames.length; i++) {
             delete _tokenProperties[tokenId][propNames[i]];
        }
        _tokenPropertyNames[tokenId].clear();
         _tokenBoundResourceAddresses[tokenId].clear(); // Just clears the list of addresses, not the mappings
    }


    // --- Basic Functionality ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This implementation returns a base URI followed by the token ID.
     * An off-chain service is expected to use this URI to retrieve token data
     * by querying the contract's view functions (e.g., getDataReference, getProperty, getMode, getResourceBindings).
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: token query for nonexistent token");
        // Off-chain service should handle the base URI + token ID and query contract view functions
        // to build the full dynamic metadata JSON based on current state.
        return string.concat(_baseTokenURI, Strings.toString(tokenId));
    }

    /**
     * @dev Mints a new token. Only callable by the contract owner.
     * @param to The address to mint the token to.
     * @param tokenId The ID for the new token.
     */
    function mint(address to, uint256 tokenId) public onlyOwner whenNotPaused {
        _mint(to, tokenId);
        _tokenIdCounter.increment(); // Assuming tokenId is incremented sequentially for simplicity
        emit ModeChanged(tokenId, bytes32(0), bytes32(0)); // Initialize mode to default/empty
    }

    // --- Multi-Modal Data Management ---

    /**
     * @dev Owner adds a supported data type identifier.
     * @param dataType The bytes32 identifier for the data type (e.g., keccak256("image"), keccak256("audio")).
     */
    function addSupportedDataType(bytes32 dataType) public onlyOwner {
        require(dataType != bytes32(0), "Invalid data type");
        bool added = _supportedDataTypes.add(dataType);
        if (added) {
            emit DataTypeSupported(dataType, true);
        }
    }

    /**
     * @dev Owner removes a supported data type identifier.
     * @param dataType The bytes32 identifier for the data type.
     */
    function removeSupportedDataType(bytes32 dataType) public onlyOwner {
         require(dataType != bytes32(0), "Invalid data type");
        bool removed = _supportedDataTypes.remove(dataType);
         if (removed) {
            emit DataTypeSupported(dataType, false);
        }
    }

    /**
     * @dev Checks if a data type is supported.
     * @param dataType The bytes32 identifier.
     */
    function isSupportedDataType(bytes32 dataType) public view returns (bool) {
        return _supportedDataTypes.contains(dataType);
    }

    /**
     * @dev Adds or updates a data reference for a token and specific data type.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the token.
     * @param dataType The bytes32 identifier for the data type. Must be a supported type.
     * @param uri The URI pointing to the external data (e.g., IPFS hash).
     */
    function addDataReference(uint256 tokenId, bytes32 dataType, string memory uri) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(isSupportedDataType(dataType), "Unsupported data type");
        _dataReferences[tokenId][dataType] = uri;
        emit DataReferenceUpdated(tokenId, dataType, uri);
    }

    /**
     * @dev Removes a data reference for a token and specific data type.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the token.
     * @param dataType The bytes32 identifier for the data type.
     */
    function removeDataReference(uint256 tokenId, bytes32 dataType) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        // No need to check isSupportedDataType here, allows removing old references
        string memory oldUri = _dataReferences[tokenId][dataType];
        delete _dataReferences[tokenId][dataType];
        // Emit event only if something was actually removed
        if (bytes(oldUri).length > 0) {
             emit DataReferenceRemoved(tokenId, dataType);
        }
    }

    /**
     * @dev Gets the URI for a specific data type and token ID.
     * @param tokenId The ID of the token.
     * @param dataType The bytes32 identifier for the data type.
     * @return The URI string. Returns empty string if not set.
     */
    function getDataReference(uint256 tokenId, bytes32 dataType) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        // No require for supported type here, allows retrieving references to unsupported types
        return _dataReferences[tokenId][dataType];
    }

    /**
     * @dev Returns a list of all data types that have a reference set for a token.
     * Note: This iterates over supported types. For very large numbers of supported types, gas could be an issue.
     * @param tokenId The ID of the token.
     * @return An array of bytes32 data type identifiers.
     */
    function getAllDataTypesForToken(uint256 tokenId) public view returns (bytes32[] memory) {
        require(_exists(tokenId), "Token does not exist");
        bytes32[] memory supportedTypes = _supportedDataTypes.values();
        uint256 count = 0;
        bytes32[] memory typesWithData = new bytes32[](supportedTypes.length);

        for(uint i = 0; i < supportedTypes.length; i++) {
            if (bytes(_dataReferences[tokenId][supportedTypes[i]]).length > 0) {
                typesWithData[count] = supportedTypes[i];
                count++;
            }
        }

        bytes32[] memory result = new bytes32[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = typesWithData[i];
        }
        return result;
    }

    // --- Mode Management ---

    /**
     * @dev Owner adds an available mode identifier.
     * @param mode The bytes32 identifier for the mode.
     */
    function addAvailableMode(bytes32 mode) public onlyOwner {
        require(mode != bytes32(0), "Invalid mode");
        bool added = _availableModes.add(mode);
        if (added) {
            emit ModeAvailable(mode, true);
        }
    }

    /**
     * @dev Owner removes an available mode identifier.
     * @param mode The bytes32 identifier for the mode.
     */
    function removeAvailableMode(bytes32 mode) public onlyOwner {
        require(mode != bytes32(0), "Invalid mode");
        bool removed = _availableModes.remove(mode);
         if (removed) {
            emit ModeAvailable(mode, false);
        }
    }

    /**
     * @dev Sets the mode of a token.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the token.
     * @param mode The bytes32 identifier for the mode. Must be an available mode.
     */
    function setMode(uint256 tokenId, bytes32 mode) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(_availableModes.contains(mode), "Mode is not available");
        bytes32 oldMode = _tokenMode[tokenId];
        _tokenMode[tokenId] = mode;
        if (oldMode != mode) {
            emit ModeChanged(tokenId, oldMode, mode);
        }
    }

    /**
     * @dev Gets the current mode of a token.
     * @param tokenId The ID of the token.
     * @return The bytes32 mode identifier. Returns bytes32(0) if no mode is set.
     */
    function getMode(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenMode[tokenId];
    }

     /**
     * @dev Returns a list of all available mode identifiers.
     * @return An array of bytes32 mode identifiers.
     */
    function getAvailableModes() public view returns (bytes32[] memory) {
        return _availableModes.values();
    }

    // --- Dynamic Property Management ---

    /**
     * @dev Sets a dynamic property for a token.
     * Only callable by the token owner or an approved operator.
     * Property names are case-sensitive. Value is stored as bytes.
     * @param tokenId The ID of the token.
     * @param propertyName The name of the property (e.g., "strength", "color").
     * @param propertyValue The value of the property, encoded as bytes.
     */
    function setProperty(uint256 tokenId, string memory propertyName, bytes memory propertyValue) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(bytes(propertyName).length > 0, "Property name cannot be empty");

        // If setting a value (non-empty), add property name to the set
        if (propertyValue.length > 0) {
             _tokenPropertyNames[tokenId].add(propertyName);
        } else {
            // If setting an empty value, remove property name from the set
             _tokenPropertyNames[tokenId].remove(propertyName);
        }

        _tokenProperties[tokenId][propertyName] = propertyValue; // Allow setting empty bytes to "unset"
        emit PropertySet(tokenId, propertyName, propertyValue);
    }

    /**
     * @dev Gets the value of a dynamic property for a token.
     * @param tokenId The ID of the token.
     * @param propertyName The name of the property.
     * @return The property value as bytes. Returns empty bytes if the property is not set.
     */
    function getProperty(uint256 tokenId, string memory propertyName) public view returns (bytes memory) {
         require(_exists(tokenId), "Token does not exist");
        return _tokenProperties[tokenId][propertyName];
    }

    /**
     * @dev Returns a list of all property names set for a token.
     * @param tokenId The ID of the token.
     * @return An array of property names (strings).
     */
    function getAllPropertiesForToken(uint256 tokenId) public view returns (string[] memory) {
         require(_exists(tokenId), "Token does not exist");
        return _tokenPropertyNames[tokenId].values();
    }

    // --- Resource Binding ---

    /**
     * @dev Binds a specified amount of a resource token (ERC20/ERC721/ERC1155) to this NFT.
     * Requires the resource tokens to have been transferred to this contract address *before* calling this function.
     * For ERC20, resourceId should be 0. For ERC721, amount is always 1, resourceId is the token ID. For ERC1155, resourceId is the token ID.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the NFT to bind resources to.
     * @param resourceAddress The address of the resource token contract.
     * @param resourceId The ID of the resource token (0 for ERC20, token ID for ERC721/ERC1155).
     * @param amount The amount of the resource to bind (always 1 for ERC721).
     */
    function bindResource(uint256 tokenId, address resourceAddress, uint256 resourceId, uint256 amount) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(resourceAddress != address(0), "Invalid resource address");
        require(amount > 0, "Amount must be greater than 0");

        // Note: This function *assumes* the tokens are already in this contract's balance.
        // The user must approve this contract and transfer the tokens prior to calling bindResource.
        // For ERC721, this contract must own the `resourceId`.
        // For ERC20/ERC1155, the amount must be in this contract's balance.

        _resourceBindings[tokenId][resourceAddress][resourceId] += amount;
         _tokenBoundResourceAddresses[tokenId].add(resourceAddress);

        emit ResourceBound(tokenId, resourceAddress, resourceId, amount);
    }

     /**
     * @dev Unbinds and transfers a specified amount of a resource token back to the owner of the NFT.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the NFT to unbind resources from.
     * @param resourceAddress The address of the resource token contract.
     * @param resourceId The ID of the resource token (0 for ERC20, token ID for ERC721/ERC1155).
     * @param amount The amount of the resource to unbind (always 1 for ERC721).
     */
    function unbindResource(uint256 tokenId, address resourceAddress, uint256 resourceId, uint256 amount) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(resourceAddress != address(0), "Invalid resource address");
        require(amount > 0, "Amount must be greater than 0");
        require(_resourceBindings[tokenId][resourceAddress][resourceId] >= amount, "Insufficient bound resources");

        _resourceBindings[tokenId][resourceAddress][resourceId] -= amount;

        // If resource amount becomes 0, potentially clean up mapping? (Gas costly)
        // For simplicity, leave entry in mapping but it will show 0.
        // If resource amount becomes 0 for *all* resourceIds for this address,
        // we could remove resourceAddress from the set, but that's complex.
        // Leaving it in the set is simpler for `getAllResourceBindingsForToken`.

        address nftOwner = ownerOf(tokenId);

        // Attempt to transfer resource back to the NFT owner
        // This requires the contract to be able to call transfer/safeTransferFrom on the resource contract
        // Depending on the resource token standard, this might need different logic or interfaces.
        // Basic examples:
        try IERC20(resourceAddress).transfer(nftOwner, amount) returns (bool success) {
             require(success, "ERC20 transfer failed");
        } catch Error(string memory reason) {
            // Not ERC20 or transfer failed. Try ERC721/ERC1155?
            // ERC721 unbinding: resourceId is the token ID, amount must be 1
            if (amount == 1) {
                try IERC721(resourceAddress).safeTransferFrom(address(this), nftOwner, resourceId) {
                    // Success
                } catch Error(string memory reason721) {
                     // Not ERC721 or transfer failed. Try ERC1155?
                     try IERC1155(resourceAddress).safeTransferFrom(address(this), nftOwner, resourceId, amount, "") {
                         // Success
                     } catch Error(string memory reason1155) {
                         // If all attempts fail, revert.
                          revert(string.concat("Resource transfer failed: ", reason1155));
                     }
                }
            } else {
                 // If amount > 1 and not ERC20, must be ERC1155 batch or something similar.
                 // For simplicity, this example only handles amount=1 for ERC721/1155 transfer attempts
                 // and requires explicit ERC1155 batch transfer interface support for >1 amounts.
                  try IERC1155(resourceAddress).safeTransferFrom(address(this), nftOwner, resourceId, amount, "") {
                    // Success
                  } catch Error(string memory reason1155Batch) {
                       revert(string.concat("Resource transfer failed: ", reason1155Batch));
                  }
            }
        } catch {
            // Fallback for general failures
             revert("Resource transfer failed: Unknown error");
        }

        emit ResourceUnbound(tokenId, resourceAddress, resourceId, amount);
    }

    /**
     * @dev Gets the amount of a specific resource (address+id) bound to a token.
     * For ERC20, use resourceId 0.
     * @param tokenId The ID of the token.
     * @param resourceAddress The address of the resource token contract.
     * @param resourceId The ID of the resource (0 for ERC20, token ID for ERC721/ERC1155).
     * @return The amount bound.
     */
    function getResourceBindings(uint256 tokenId, address resourceAddress, uint256 resourceId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        require(resourceAddress != address(0), "Invalid resource address");
        return _resourceBindings[tokenId][resourceAddress][resourceId];
    }

    /**
     * @dev Gets the total amount of an ERC20 resource bound to a token (resourceId 0).
     * Provided as a convenience, assuming ERC20 resources are typically bound with ID 0.
     * @param tokenId The ID of the token.
     * @param resourceAddress The address of the ERC20 resource token contract.
     * @return The total ERC20 amount bound.
     */
    function getTotalBoundResourceAmount(uint256 tokenId, address resourceAddress) public view returns (uint256) {
         require(_exists(tokenId), "NFT does not exist");
        require(resourceAddress != address(0), "Invalid resource address");
        // Assumes ERC20 resources are always bound with resourceId 0
        return _resourceBindings[tokenId][resourceAddress][0];
    }

     /**
     * @dev Returns a list of all resource contract addresses that have resources bound to a token.
     * Note: This lists addresses, not specific resourceIds or amounts. Query `getResourceBindings` for details.
     * @param tokenId The ID of the token.
     * @return An array of resource contract addresses.
     */
    function getAllResourceBindingsForToken(uint256 tokenId) public view returns (address[] memory) {
         require(_exists(tokenId), "NFT does not exist");
        return _tokenBoundResourceAddresses[tokenId].values();
    }


    // --- Advanced Interaction ---

    /**
     * @dev Triggers an evolution process for the token.
     * This is a flexible function where the internal logic (which properties/mode change)
     * depends on the `evolutionType` parameter and the token's current state/resources.
     * This function would contain custom logic based on the specific NFT collection's rules.
     * Example: Requires minimum "experience" property and consumption of a specific "catalyst" resource.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the token to evolve.
     * @param evolutionType A bytes32 identifier specifying the type of evolution.
     */
    function evolve(uint256 tokenId, bytes32 evolutionType) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(evolutionType != bytes32(0), "Invalid evolution type");

        // --- CUSTOM EVOLUTION LOGIC GOES HERE ---
        // This is a placeholder. Implement specific rules based on your game/collection design.
        // Example:
        // bytes memory currentLevelBytes = getProperty(tokenId, "level");
        // uint256 currentLevel = currentLevelBytes.length > 0 ? abi.decode(currentLevelBytes, (uint256)) : 0;
        // require(currentLevel < 5, "Max evolution level reached");
        // uint256 requiredCatalyst = 1; // Example requirement
        // address catalystAddress = 0x...; // Example catalyst token address
        // require(getResourceBindings(tokenId, catalystAddress, 0) >= requiredCatalyst, "Not enough catalyst");

        // // If requirements met:
        // // 1. Consume resources (if required)
        // // unbindResource(tokenId, catalystAddress, 0, requiredCatalyst); // This also transfers! Consider burning instead?
        // // A better approach for consumption within evolve:
        // _resourceBindings[tokenId][catalystAddress][0] -= requiredCatalyst;
        // emit ResourceUnbound(tokenId, catalystAddress, 0, requiredCatalyst); // Log consumption event


        // // 2. Update properties
        // uint256 newLevel = currentLevel + 1;
        // setProperty(tokenId, "level", abi.encode(newLevel));
        // setProperty(tokenId, "attack", abi.encode(currentLevel * 10 + 20)); // Example stat increase

        // // 3. Potentially change mode
        // // if (newLevel == 5) setMode(tokenId, keccak256("final_form"));

        // --- END OF CUSTOM LOGIC ---

        // Placeholder logic: Just set a dummy property and emit event
        string memory evolutionPropertyName = string.concat("evolved_", Strings.toString(block.timestamp));
        setProperty(tokenId, evolutionPropertyName, abi.encodePacked(evolutionType));

        emit Evolved(tokenId, evolutionType);
    }

    /**
     * @dev Allows a `consumerTokenId` to consume `consumedTokenId`.
     * This transfers resource bindings and dynamic properties from the consumed token
     * to the consumer token, and then burns the consumed token.
     * Requires the caller to be the owner or approved operator for *both* tokens.
     * @param consumerTokenId The ID of the token that is consuming.
     * @param consumedTokenId The ID of the token being consumed.
     */
    function consumeToken(uint256 consumerTokenId, uint256 consumedTokenId) public whenNotPaused {
        require(_exists(consumerTokenId), "Consumer token does not exist");
        require(_exists(consumedTokenId), "Consumed token does not exist");
        require(consumerTokenId != consumedTokenId, "Token cannot consume itself");

        // Check ownership/approval for BOTH tokens
        require(_isApprovedOrOwner(_msgSender(), consumerTokenId), "Not owner or approved for consumer token");
        require(_isApprovedOrOwner(_msgSender(), consumedTokenId), "Not owner or approved for consumed token");

        // --- Transfer Resource Bindings ---
        address[] memory consumedResourceAddresses = getAllResourceBindingsForToken(consumedTokenId);
        for (uint i = 0; i < consumedResourceAddresses.length; i++) {
             address resAddr = consumedResourceAddresses[i];
             // Note: Getting all resourceIds for a given address is non-trivial/gas-intensive
             // with a simple mapping. This transfers *all* amounts for *all* resourceIds
             // bound to that address on the consumed token.
             // A more granular approach would require iterating through resourceIds if needed,
             // which might require a different storage structure or off-chain processing.
             // For this example, we iterate through resource addresses and transfer the total
             // bound amount *at resourceId 0* for ERC20s, and assume ERC721/1155 are handled by ID.
             // A robust implementation would need to iterate over resourceIds.

             // Iterating over possible resourceIds is needed for correctness.
             // This basic example only copies the binding values in storage, it doesn't
             // move the underlying tokens (they are already in the contract).
             // The tokens remain in the contract's balance, now associated with consumerTokenId.
             // The resource addresses themselves are added to the consumer token's list.
             address[] memory addressesToIterate = new address[](1); // Placeholder to make compiler happy, actual needed logic is complex
             addressesToIterate[0] = resAddr; // Simplified

             for (uint j = 0; j < addressesToIterate.length; j++) { // This loop needs proper iteration over resourceIds
                 // Simplified: assume resourceId is 0 or 1 for example
                 uint256[] memory resourceIdsToIterate = new uint256[](2);
                 resourceIdsToIterate[0] = 0;
                 resourceIdsToIterate[1] = 1; // Example: cover ERC20 and a potential ERC721/1155 ID

                 for(uint k = 0; k < resourceIdsToIterate.length; k++) {
                      uint256 resId = resourceIdsToIterate[k];
                      uint256 amountToTransfer = _resourceBindings[consumedTokenId][resAddr][resId];
                      if (amountToTransfer > 0) {
                          _resourceBindings[consumerTokenId][resAddr][resId] += amountToTransfer;
                          _resourceBindings[consumedTokenId][resAddr][resId] = 0; // Clear binding on consumed token
                          emit ResourceBound(consumerTokenId, resAddr, resId, amountToTransfer); // Log transfer to consumer
                          // No unbind event from consumed here, as tokens aren't transferred out
                      }
                 }
                 _tokenBoundResourceAddresses[consumerTokenId].add(resAddr); // Add address to consumer's list
             }
        }
         _tokenBoundResourceAddresses[consumedTokenId].clear(); // Clear address list on consumed token


        // --- Transfer Dynamic Properties ---
        string[] memory consumedPropertyNames = getAllPropertiesForToken(consumedTokenId);
        for (uint i = 0; i < consumedPropertyNames.length; i++) {
            string memory propName = consumedPropertyNames[i];
            bytes memory propValue = getProperty(consumedTokenId, propName);

            // Decision: Overwrite consumer properties or merge? Here we overwrite/set
            // If merging is needed, custom logic would be required per property name/type.
            setProperty(consumerTokenId, propName, propValue); // Uses setProperty to handle adding name to set
            // Clear property on consumed token
            delete _tokenProperties[consumedTokenId][propName];
        }
         _tokenPropertyNames[consumedTokenId].clear(); // Clear property names list on consumed token


        // --- Potentially Transfer Data References? (Optional) ---
        // Decide if data references should transfer. Simple: they don't, consumer retains its own.
        // If needed, iterate getAllDataTypesForToken and copy mappings.

        // --- Burn Consumed Token ---
        _burn(consumedTokenId);

        emit TokenConsumed(consumerTokenId, consumedTokenId);
    }

    /**
     * @dev Sets multiple dynamic properties for a token in a single transaction.
     * Only callable by the token owner or an approved operator.
     * Requires `propertyNames` and `propertyValues` arrays to have the same length.
     * @param tokenId The ID of the token.
     * @param propertyNames Array of property names.
     * @param propertyValues Array of property values (as bytes).
     */
    function batchSetProperties(uint256 tokenId, string[] memory propertyNames, bytes[] memory propertyValues) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(propertyNames.length == propertyValues.length, "Arrays must have same length");

        for(uint i = 0; i < propertyNames.length; i++) {
            setProperty(tokenId, propertyNames[i], propertyValues[i]); // Reuses setProperty logic
        }
    }

    /**
     * @dev Binds multiple resources to a token in a single transaction.
     * Requires `resourceAddresses`, `resourceIds`, and `amounts` arrays to have the same length.
     * Requires the resource tokens to have been transferred to this contract address *before* calling.
     * Only callable by the token owner or an approved operator.
     * @param tokenId The ID of the NFT to bind resources to.
     * @param resourceAddresses Array of resource token contract addresses.
     * @param resourceIds Array of resource token IDs (0 for ERC20).
     * @param amounts Array of amounts to bind (always 1 for ERC721).
     */
    function batchBindResources(uint256 tokenId, address[] memory resourceAddresses, uint256[] memory resourceIds, uint256[] memory amounts) public onlyOwnerOrApproved(tokenId) whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(resourceAddresses.length == resourceIds.length && resourceIds.length == amounts.length, "Arrays must have same length");

        for(uint i = 0; i < resourceAddresses.length; i++) {
            bindResource(tokenId, resourceAddresses[i], resourceIds[i], amounts[i]); // Reuses bindResource logic
        }
    }

    // --- Pausable Functions ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal/Helper Functions ---
    // No additional internal helpers beyond OpenZeppelin's _isApprovedOrOwner needed for function access control.
}
```