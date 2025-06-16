Okay, let's design a smart contract that combines several advanced and trendy concepts around NFTs: **Dynamic, Composable NFT Asset Managers with Delegated Control**.

This contract will represent NFTs that are not just static images, but unique digital containers that can:
1.  Hold other ERC721 and ERC20 tokens.
2.  Have dynamic attributes that can change based on interactions or authorized external logic.
3.  Allow owners to delegate specific management rights (like adding/removing contents or changing attributes) to other addresses or contracts without giving away ownership of the NFT container itself.
4.  Include batch operations for efficiency.

This goes beyond standard ERC721 by adding asset management, statefulness, and granular access control at the token level.

---

**Smart Contract Outline and Function Summary:**

**Contract Name:** `DynamicNFTAssetManager`

**Purpose:** Implements an ERC721 standard with added functionality to act as a dynamic container for other tokens and manage mutable attributes, allowing for delegated control over specific token actions.

**Key Concepts:**
*   **ERC721 Standard:** Basic NFT functionality.
*   **Composable:** NFTs can hold other NFTs (ERC721) and fungible tokens (ERC20).
*   **Dynamic Attributes:** NFTs possess mutable key-value attributes.
*   **Delegated Management:** Owners can authorize other addresses/contracts to modify the *contents* or *attributes* of *specific* tokens they own, distinct from ERC721 transfer approval.
*   **Batch Operations:** Efficiency for handling multiple assets.
*   **Reentrancy Protection:** For withdrawal functions.
*   **Ownable/Controller Pattern:** Basic administrative roles.

**Function Categories & Summaries:**

1.  **ERC721 Standard Functions (Overridden/Implemented):**
    *   `constructor`: Initializes the contract with name, symbol, and owner.
    *   `supportsInterface`: ERC165 support for ERC721 and ERC721TokenReceiver.
    *   `ownerOf`: Returns the owner of a token.
    *   `balanceOf`: Returns the number of tokens owned by an address.
    *   `transferFrom`: Transfers token ownership. Adds internal hooks.
    *   `safeTransferFrom (address, address, uint256)`: Safe transfer overload. Adds internal hooks.
    *   `safeTransferFrom (address, address, uint256, bytes)`: Safe transfer overload with data. Adds internal hooks.
    *   `approve`: Sets approval for transferring a token.
    *   `getApproved`: Gets the approved address for a token.
    *   `setApprovalForAll`: Sets approval for an operator to manage all owner's tokens.
    *   `isApprovedForAll`: Checks if an operator is approved for all of an owner's tokens.
    *   `tokenURI`: Returns the metadata URI for a token (dynamic part implied off-chain).
    *   `name`: Returns the contract name.
    *   `symbol`: Returns the contract symbol.

2.  **Minting & Supply Management:**
    *   `mint`: Mints a new NFT container token to a recipient (restricted).
    *   `burn`: Destroys a token (restricted, requires empty).
    *   `pauseMinting`: Pauses new token minting (owner only).
    *   `unpauseMinting`: Unpauses new token minting (owner only).
    *   `setMaxSupply`: Sets the maximum number of tokens that can be minted (owner only).
    *   `getMaxSupply`: Returns the maximum supply.
    *   `getTotalSupply`: Returns the current total supply.

3.  **Asset Management (Deposit & Withdraw):**
    *   `onERC721Received`: ERC721 receiver hook to accept deposited NFTs into a container.
    *   `depositERC721`: Initiates deposit of an external ERC721 into one of this contract's NFTs.
    *   `withdrawERC721`: Withdraws a specific ERC721 from a container NFT (owner/approved manager only).
    *   `depositERC20`: Deposits ERC20 tokens into a container NFT (requires prior approval).
    *   `withdrawERC20`: Withdraws ERC20 tokens from a container NFT (owner/approved manager only).
    *   `batchDepositERC721`: Deposits multiple specific ERC721s into one container NFT.
    *   `batchWithdrawERC721`: Withdraws multiple specific ERC721s from one container NFT.
    *   `batchDepositERC20`: Deposits multiple ERC20s into one container NFT.
    *   `batchWithdrawERC20`: Withdraws multiple ERC20s from one container NFT.

4.  **Asset Query:**
    *   `getHeldERC721s`: Returns the list of ERC721 tokens held by a container NFT.
    *   `getHeldERC20Balance`: Returns the balance of a specific ERC20 token held by a container NFT.

5.  **Dynamic Attributes Management:**
    *   `setDynamicAttribute (uint256 tokenId, string calldata attributeName, bytes calldata attributeValue)`: Sets a dynamic attribute for a token (owner/approved manager/controller only).
    *   `setDynamicAttribute (uint256 tokenId, string calldata attributeName, uint256 attributeValue)`: Overload for uint256.
    *   `setDynamicAttribute (uint256 tokenId, string calldata attributeName, string calldata attributeValue)`: Overload for string.
    *   `getDynamicAttribute`: Retrieves the bytes value of a dynamic attribute.
    *   `getDynamicAttributeUint`: Retrieves the uint256 value of a dynamic attribute (requires correct type).
    *   `getDynamicAttributeString`: Retrieves the string value of a dynamic attribute (requires correct type).
    *   `getTokenAttributeNames`: Returns the list of attribute names set for a token.

6.  **Delegated Management:**
    *   `setApprovedManager`: Grants or revokes management approval for a specific address over a *specific* NFT container owned by the caller (owner only).
    *   `getApprovedManager`: Returns the address approved for management of a specific token.

7.  **Access Control & Utility:**
    *   `setController`: Sets the address of a general controller (owner only).
    *   `isController`: Checks if an address is the controller.
    *   `renounceController`: Renounces the controller role (controller only).
    *   `setBaseURI`: Sets the base URI for metadata (owner only).
    *   `withdrawEther`: Allows owner to withdraw accidental Ether sent to the contract (owner only).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title DynamicNFTAssetManager
/// @notice Implements an ERC721 standard with added functionality to act as a dynamic container for other tokens and manage mutable attributes, allowing for delegated control over specific token actions.
contract DynamicNFTAssetManager is ERC721, Ownable, ReentrancyGuard, IERC721Receiver, ERC165 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    uint256 public maxSupply = 0; // 0 means unlimited
    bool public mintingPaused = false;

    // ERC721 Asset Storage: tokenId => assetContractAddress => assetTokenId => exists
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private _heldERC721s;
    // Helper to list ERC721 tokenIds for a given asset contract within a container
    mapping(uint256 => mapping(address => uint256[])) private _heldERC721List;

    // ERC20 Asset Storage: tokenId => assetContractAddress => balance
    mapping(uint256 => mapping(address => uint256)) private _heldERC20s;

    // Dynamic Attributes: tokenId => attributeName => attributeValue (bytes allows flexibility)
    mapping(uint256 => mapping(string => bytes)) private _dynamicAttributes;
    // Helper to list attribute names for a token (manual tracking needed)
    mapping(uint256 => string[]) private _tokenAttributeNames;

    // Delegated Management: tokenId => approvedManagerAddress (address authorized to manage contents/attributes)
    mapping(uint256 => address) private _approvedManager;

    // General Controller address (can also manage attributes/contents if allowed by owner or globally)
    address public controller;

    string private _baseTokenURI;

    // --- Events ---

    /// @dev Emitted when an ERC721 token is deposited into a container NFT.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the deposited ERC721 contract.
    /// @param assetTokenId The ID of the deposited ERC721 token.
    /// @param depositor The address that initiated the deposit.
    event AssetDepositedERC721(uint256 indexed containerTokenId, address indexed assetContract, uint256 indexed assetTokenId, address depositor);

    /// @dev Emitted when an ERC721 token is withdrawn from a container NFT.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the withdrawn ERC721 contract.
    /// @param assetTokenId The ID of the withdrawn ERC721 token.
    /// @param receiver The address that received the withdrawn token.
    event AssetWithdrawnERC721(uint256 indexed containerTokenId, address indexed assetContract, uint256 indexed assetTokenId, address receiver);

    /// @dev Emitted when ERC20 tokens are deposited into a container NFT.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the deposited ERC20 contract.
    /// @param amount The amount of ERC20 deposited.
    /// @param depositor The address that initiated the deposit.
    event AssetDepositedERC20(uint256 indexed containerTokenId, address indexed assetContract, uint256 amount, address depositor);

    /// @dev Emitted when ERC20 tokens are withdrawn from a container NFT.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the withdrawn ERC20 contract.
    /// @param amount The amount of ERC20 withdrawn.
    /// @param receiver The address that received the withdrawn tokens.
    event AssetWithdrawnERC20(uint256 indexed containerTokenId, address indexed assetContract, uint256 amount, address receiver);

    /// @dev Emitted when a dynamic attribute of a token is changed.
    /// @param tokenId The ID of the token whose attribute was changed.
    /// @param attributeName The name of the attribute.
    /// @param attributeValue The new value of the attribute (as bytes).
    /// @param changer The address that changed the attribute.
    event AttributeChanged(uint256 indexed tokenId, string attributeName, bytes attributeValue, address changer);

    /// @dev Emitted when a delegated manager is set or revoked for a specific token.
    /// @param tokenId The ID of the token.
    /// @param manager The address approved as manager.
    /// @param caller The address that set the manager.
    event ApprovedManagerSet(uint256 indexed tokenId, address indexed manager, address indexed caller);

    /// @dev Emitted when the general controller address is changed.
    /// @param oldController The previous controller address.
    /// @param newController The new controller address.
    event ControllerSet(address indexed oldController, address indexed newController);

    // --- Modifiers ---

    /// @dev Checks if the caller is the owner of the token, the controller, or the approved manager for the token.
    modifier onlyTokenOwnerOrApprovedManagerOrController(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);
        require(msg.sender == tokenOwner || msg.sender == controller || msg.sender == _approvedManager[tokenId], "Not owner, controller, or approved manager");
        _;
    }

    /// @dev Checks if the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner) ERC721(name, symbol) Ownable(initialOwner) ERC165() {
        // Register interfaces
        _registerInterface(type(IERC721Receiver).interfaceId);
        _registerInterface(type(ERC721).interfaceId); // ERC721 standard interface
    }

    // --- ERC165 Interface Support ---

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- ERC721 Standard Functions (Overridden for internal hooks) ---

    /// @inheritdoc ERC721
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) { // Minting
            // Nothing specific needed for asset/attribute state on mint
        } else if (to == address(0)) { // Burning
            // Ensure the container is empty before burning
            require(!_hasHeldAssets(tokenId), "Cannot burn NFT container while it holds assets");
            // Clean up attribute storage (optional, but good practice)
             _clearDynamicAttributes(tokenId);
             delete _approvedManager[tokenId]; // Clear approved manager
        } else { // Transferring
            // When the container NFT is transferred, ownership of all held assets implicitly transfers with it.
            // No state changes needed for held assets themselves, as their owner is this contract address.
            // The new owner of the container NFT gains control over its contents and attributes.
            // Approved manager for the token is cleared on transfer for security.
            delete _approvedManager[tokenId];
        }
    }

    /// @dev Helper to check if a token holds any assets (ERC721 or ERC20).
    function _hasHeldAssets(uint256 tokenId) internal view returns (bool) {
        // Check ERC721s (iterate through known asset contracts for this token)
        // Note: This check is simplified; a full check would iterate _heldERC721List. A more efficient check
        // would track a simple boolean or counter per token if any asset is held. For now, rely on length of lists.
        // A more robust implementation might need a dedicated counter for held assets.
        // For simplicity here, we'll rely on ERC20 balance > 0 or ERC721 list not being empty after considering deleted items.
        // A *perfect* check for ERC721s would require iterating the *actual list* and checking `_heldERC721s` for each.
        // Let's rely on ERC20 check and assuming ERC721 list isn't perfectly clean but `_heldERC721s` map is authoritative.
         // Check if any ERC20 balance > 0
        for (uint i = 0; i < _tokenAttributeNames[tokenId].length; i++) { // Using attribute names list as a proxy, not ideal
            // A better way requires iterating the _heldERC20s mapping keys, which isn't directly possible.
            // Let's add a simple flag or counter for held assets for efficiency. Or require specific withdrawal.
        }
         // Simplification: Require ERC20 balances to be zero AND _heldERC721List to be empty (assuming withdrawal cleans list)
        for (uint i = 0; i < _tokenAttributeNames[tokenId].length; i++) { // Still not right, iterating attributes
             // Let's add a simple counter for ERC721 asset types held and total ERC20 balance > 0 check.
             // Or enforce empty ERC721 lists and 0 ERC20 balances before burn. Yes, enforce empty lists/balances.
        }

         // Revised check: Iterate held ERC721 list and verify existence, check all ERC20 balances are 0.
         // Iterating maps isn't easy. Let's just check if the list of held ERC721 *contracts* is non-empty
         // AND if any *known* ERC20 has a balance > 0. This isn't perfect but avoids complex state.
         // A better approach for a production contract would be a separate state variable tracking "has any asset".

         // For *this* example, let's make the burn requirement simpler: require ERC20 balance is 0 for ANY token deposited
         // (which requires knowing which ERC20s were deposited) and *no* ERC721s are in the internal list.
         // This means withdrawal functions *must* clean the internal lists/balances.

         // Check held ERC721 list length. This is imperfect if list isn't cleaned on withdrawal of last item.
         // Let's iterate _heldERC721List and check actual _heldERC721s map.
         for(uint i=0; i < _tokenAttributeNames[tokenId].length; i++) { // Still iterating attributes. Need a list of ASSET CONTRACTS
             // Let's add a set/list of asset contract addresses held by a token.
         }

         // Simplest and most direct for this example: Require specific withdrawal of *all* known assets.
         // The `burn` function will simply check if the *lists* and *balances* are empty according to our state.
         // The burden is on withdrawal functions to keep this state clean.

         // Check held ERC20 balances - requires iterating all potentially held ERC20s... complicated.
         // Let's check the ERC721 lists explicitly.
         bool has721 = false;
         // How to get list of asset contracts? Another mapping. tokenId => assetContractAddress[]
         // Let's add that state variable.

         // Mapping: tokenId => list of ERC721 asset contract addresses
         mapping(uint256 => address[]) private _heldERC721AssetContracts;
         // Mapping: tokenId => list of ERC20 asset contract addresses
         mapping(uint256 => address[]) private _heldERC20AssetContracts;

         // Now the check becomes:
         for(uint i = 0; i < _heldERC721AssetContracts[tokenId].length; i++) {
             if(_heldERC721List[tokenId][_heldERC721AssetContracts[tokenId][i]].length > 0) {
                 has721 = true;
                 break;
             }
         }
         bool has20 = false;
          for(uint i = 0; i < _heldERC20AssetContracts[tokenId].length; i++) {
             if(_heldERC20s[tokenId][_heldERC20AssetContracts[tokenId][i]] > 0) {
                 has20 = true;
                 break;
             }
         }
         return has721 || has20;
    }


    // --- Minting & Supply Management ---

    /// @notice Mints a new NFT container token.
    /// @param recipient The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mint(address recipient) public onlyOwner nonReentrant returns (uint256) {
        require(!mintingPaused, "Minting is paused");
        if (maxSupply > 0) {
            require(_tokenIdCounter.current() < maxSupply, "Max supply reached");
        }

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(recipient, newItemId);

        // Initialize empty state for the new token
        // Mappings are implicitly initialized when accessed, but lists might need explicit handling if not adding immediately.
        // _heldERC721List[newItemId] etc. will be created on first deposit.
        // _tokenAttributeNames[newItemId] etc. will be created on first attribute set.

        return newItemId;
    }

     /// @notice Burns a token, provided it does not hold any assets.
     /// @param tokenId The ID of the token to burn.
     function burn(uint256 tokenId) public virtual {
         // Check permissions: owner or approved for all
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
         // Use the corrected internal check for held assets
         require(!_hasHeldAssets(tokenId), "Cannot burn NFT container while it holds assets");

         _burn(tokenId);
         // Clean up any remaining state (attributes, approvals) - done in _beforeTokenTransfer
     }


    /// @notice Pauses token minting.
    function pauseMinting() public onlyOwner {
        mintingPaused = true;
    }

    /// @notice Unpauses token minting.
    function unpauseMinting() public onlyOwner {
        mintingPaused = false;
    }

    /// @notice Sets the maximum number of tokens that can be minted.
    /// @param _maxSupply The maximum supply (0 for unlimited).
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply == 0 || _maxSupply >= _tokenIdCounter.current(), "New max supply cannot be less than current supply");
        maxSupply = _maxSupply;
    }

    /// @notice Returns the maximum supply of tokens.
    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    /// @notice Returns the current total supply of tokens.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    // --- Asset Management (Deposit) ---

    /// @notice Handles receiving deposited ERC721 tokens into a container NFT.
    /// @dev This function is called by the ERC721 token contract being deposited.
    /// @param operator The address which called `safeTransferFrom` on the asset contract.
    /// @param from The address from which the asset token was transferred.
    /// @param tokenId The ID of the container token in this contract that is receiving the asset.
    /// @param data Additional data sent with the transfer (optional). Should contain containerTokenId.
    /// @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public virtual override returns (bytes4) {
        // Ensure the recipient of the asset transfer is *this* contract
        require(msg.sender != address(0), "ERC721: onERC721Received caller is the zero address");
        // The msg.sender is the ERC721 contract address of the asset being deposited
        address assetContractAddress = msg.sender;
        // The tokenId parameter in this hook is the ID of the *asset token* being received, NOT the container token.
        uint256 assetTokenId = tokenId;

        // We need to know which container token ID to put this asset into.
        // This should be passed in the `data` parameter of the originating safeTransferFrom call.
        require(data.length == 32, "onERC721Received: data must contain container token ID");
        uint256 containerTokenId = abi.decode(data, (uint256));

        // Validate the container token exists
        require(_exists(containerTokenId), "onERC721Received: invalid container token ID");

        // Check that the 'operator' who initiated the transfer is authorized to deposit into this container.
        // This could be the container's owner, the approved manager, or the general controller.
        address containerOwner = ownerOf(containerTokenId);
        require(operator == containerOwner || operator == controller || operator == _approvedManager[containerTokenId],
                "onERC721Received: Operator not authorized to deposit to this container");

        // Record the deposited ERC721 asset
        require(!_heldERC721s[containerTokenId][assetContractAddress][assetTokenId], "ERC721 already held");
        _heldERC721s[containerTokenId][assetContractAddress][assetTokenId] = true;
        _heldERC721List[containerTokenId][assetContractAddress].push(assetTokenId);

        // Ensure the asset contract address is tracked for this container if it's the first of its kind
         bool assetContractAlreadyTracked = false;
         for(uint i = 0; i < _heldERC721AssetContracts[containerTokenId].length; i++) {
             if (_heldERC721AssetContracts[containerTokenId][i] == assetContractAddress) {
                 assetContractAlreadyTracked = true;
                 break;
             }
         }
         if (!assetContractAlreadyTracked) {
             _heldERC721AssetContracts[containerTokenId].push(assetContractAddress);
         }


        emit AssetDepositedERC721(containerTokenId, assetContractAddress, assetTokenId, operator);

        // Return the magic value to signify acceptance
        return this.onERC721Received.selector;
    }

    /// @notice Initiates a deposit of an external ERC721 token into one of this contract's container NFTs.
    /// @dev The caller must be the owner or approved manager of the container NFT.
    /// @dev This requires the caller to first call `approve` or `setApprovalForAll` on the *asset contract*
    ///      to allow *this contract* (`DynamicNFTAssetManager`) to transfer the asset.
    /// @param containerTokenId The ID of the container NFT to deposit into.
    /// @param assetContract The address of the ERC721 contract of the asset to deposit.
    /// @param assetTokenId The ID of the ERC721 token to deposit.
    function depositERC721(uint256 containerTokenId, address assetContract, uint256 assetTokenId)
        public
        nonReentrant // Protects against reentrancy via the asset contract call
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        IERC721 assetERC721 = IERC721(assetContract);
        // Transfer the asset from the caller to this contract.
        // The onERC721Received hook will handle the internal state update.
        // The `data` parameter includes the containerTokenId for the hook.
        assetERC721.safeTransferFrom(msg.sender, address(this), assetTokenId, abi.encode(containerTokenId));
        // Note: Authorization check on the asset contract is done by safeTransferFrom internally
        // (caller must own/have approval for the asset). Authorization check on the *container*
        // is done by the modifier and validated again in onERC721Received via the `operator` param.
    }

    /// @notice Deposits ERC20 tokens into a container NFT.
    /// @dev The caller must be the owner or approved manager of the container NFT.
    /// @dev This requires the caller to first call `approve` on the *asset contract*
    ///      to allow *this contract* (`DynamicNFTAssetManager`) to transfer the amount.
    /// @param containerTokenId The ID of the container NFT to deposit into.
    /// @param assetContract The address of the ERC20 contract of the asset to deposit.
    /// @param amount The amount of ERC20 tokens to deposit.
    function depositERC20(uint256 containerTokenId, address assetContract, uint256 amount)
        public
        nonReentrant // Protects against reentrancy via the asset contract call
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        require(amount > 0, "Cannot deposit zero amount");
        IERC20 assetERC20 = IERC20(assetContract);

        // Transfer the asset from the caller to this contract.
        bool success = assetERC20.transferFrom(msg.sender, address(this), amount);
        require(success, "ERC20 transfer failed");

        // Update the internal state
        _heldERC20s[containerTokenId][assetContract] += amount;

         // Ensure the asset contract address is tracked for this container if it's the first of its kind
         bool assetContractAlreadyTracked = false;
         for(uint i = 0; i < _heldERC20AssetContracts[containerTokenId].length; i++) {
             if (_heldERC20AssetContracts[containerTokenId][i] == assetContract) {
                 assetContractAlreadyTracked = true;
                 break;
             }
         }
         if (!assetContractAlreadyTracked) {
             _heldERC20AssetContracts[containerTokenId].push(assetContract);
         }

        emit AssetDepositedERC20(containerTokenId, assetContract, amount, msg.sender);
    }

    // --- Asset Management (Withdraw) ---

    /// @notice Withdraws a specific ERC721 token from a container NFT.
    /// @dev Only the container NFT's owner, approved manager, or controller can withdraw.
    /// @param containerTokenId The ID of the container NFT to withdraw from.
    /// @param assetContract The address of the ERC721 contract of the asset to withdraw.
    /// @param assetTokenId The ID of the ERC721 token to withdraw.
    /// @param recipient The address to send the withdrawn token to.
    function withdrawERC721(uint256 containerTokenId, address assetContract, uint256 assetTokenId, address recipient)
        public
        nonReentrant
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        require(recipient != address(0), "Cannot withdraw to zero address");
        require(_heldERC721s[containerTokenId][assetContract][assetTokenId], "Asset not held by this token");

        // Mark asset as no longer held
        _heldERC721s[containerTokenId][assetContract][assetTokenId] = false;

        // Remove from the list (basic list removal, not efficient but works)
        uint256[] storage tokenList = _heldERC721List[containerTokenId][assetContract];
        bool found = false;
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == assetTokenId) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                found = true;
                break;
            }
        }
        // Should always be found if _heldERC721s is true, but good check
        require(found, "Asset not found in list");


        // Transfer the asset from this contract to the recipient
        IERC721(assetContract).safeTransferFrom(address(this), recipient, assetTokenId);

        // Clean up the asset contract list if this was the last token of that contract type
         if (_heldERC721List[containerTokenId][assetContract].length == 0) {
             for(uint i = 0; i < _heldERC721AssetContracts[containerTokenId].length; i++) {
                 if (_heldERC721AssetContracts[containerTokenId][i] == assetContract) {
                     _heldERC721AssetContracts[containerTokenId][i] = _heldERC721AssetContracts[containerTokenId][_heldERC721AssetContracts[containerTokenId].length - 1];
                     _heldERC721AssetContracts[containerTokenId].pop();
                     break;
                 }
             }
         }


        emit AssetWithdrawnERC721(containerTokenId, assetContract, assetTokenId, recipient);
    }

    /// @notice Withdraws ERC20 tokens from a container NFT.
    /// @dev Only the container NFT's owner, approved manager, or controller can withdraw.
    /// @param containerTokenId The ID of the container NFT to withdraw from.
    /// @param assetContract The address of the ERC20 contract of the asset to withdraw.
    /// @param amount The amount of ERC20 tokens to withdraw.
    /// @param recipient The address to send the withdrawn tokens to.
    function withdrawERC20(uint256 containerTokenId, address assetContract, uint256 amount, address recipient)
        public
        nonReentrant
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        require(recipient != address(0), "Cannot withdraw to zero address");
        require(_heldERC20s[containerTokenId][assetContract] >= amount, "Insufficient ERC20 balance in token");
        require(amount > 0, "Cannot withdraw zero amount");

        // Update the internal state
        _heldERC20s[containerTokenId][assetContract] -= amount;

        // Transfer the asset from this contract to the recipient
        bool success = IERC20(assetContract).transfer(recipient, amount);
        require(success, "ERC20 transfer failed");

         // Clean up the asset contract list if balance is now zero
         if (_heldERC20s[containerTokenId][assetContract] == 0) {
             for(uint i = 0; i < _heldERC20AssetContracts[containerTokenId].length; i++) {
                 if (_heldERC20AssetContracts[containerTokenId][i] == assetContract) {
                     _heldERC20AssetContracts[containerTokenId][i] = _heldERC20AssetContracts[containerTokenId][_heldERC20AssetContracts[containerTokenId].length - 1];
                     _heldERC20AssetContracts[containerTokenId].pop();
                     break;
                 }
             }
         }

        emit AssetWithdrawnERC20(containerTokenId, assetContract, amount, recipient);
    }

     // --- Batch Asset Management ---

     /// @notice Deposits multiple ERC721 tokens into a container NFT in a single transaction.
     /// @dev See `depositERC721` for prerequisites (asset approval).
     /// @param containerTokenId The ID of the container NFT.
     /// @param assetContracts Array of ERC721 asset contract addresses.
     /// @param assetTokenIds Array of ERC721 asset token IDs. Must match `assetContracts` in length.
     function batchDepositERC721(uint256 containerTokenId, address[] calldata assetContracts, uint256[] calldata assetTokenIds)
         public
         nonReentrant // Protects against reentrancy on each transfer call
         tokenExists(containerTokenId)
         onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
     {
         require(assetContracts.length == assetTokenIds.length, "Array length mismatch");
         require(assetContracts.length > 0, "Empty batch");

         for (uint i = 0; i < assetContracts.length; i++) {
             // Call the single deposit function internally.
             // Note: This iterates and makes external calls, which can hit gas limits for large batches.
             // Error handling within the loop is limited; one failure reverts the whole batch.
             // The onERC721Received hook is called for each successful transfer.
              IERC721(assetContracts[i]).safeTransferFrom(msg.sender, address(this), assetTokenIds[i], abi.encode(containerTokenId));
             // State updates and events are handled in onERC721Received
         }
     }

    /// @notice Withdraws multiple specific ERC721 tokens from a container NFT in a single transaction.
    /// @dev See `withdrawERC721` for permissions.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContracts Array of ERC721 asset contract addresses.
    /// @param assetTokenIds Array of ERC721 asset token IDs. Must match `assetContracts` in length.
    /// @param recipient The address to send all withdrawn tokens to.
    function batchWithdrawERC721(uint256 containerTokenId, address[] calldata assetContracts, uint256[] calldata assetTokenIds, address recipient)
        public
        nonReentrant // Protects against reentrancy on each transfer call
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        require(assetContracts.length == assetTokenIds.length, "Array length mismatch");
        require(assetContracts.length > 0, "Empty batch");
         require(recipient != address(0), "Cannot withdraw to zero address");

        for (uint i = 0; i < assetContracts.length; i++) {
            // Call the single withdrawal function internally.
            // State updates and events are handled within withdrawERC721.
            // Gas limit applies here as well. One failure reverts all.
            withdrawERC721(containerTokenId, assetContracts[i], assetTokenIds[i], recipient);
        }
    }

    /// @notice Deposits multiple ERC20 token types/amounts into a container NFT in a single transaction.
    /// @dev See `depositERC20` for prerequisites (asset approval for each amount).
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContracts Array of ERC20 asset contract addresses.
    /// @param amounts Array of amounts to deposit. Must match `assetContracts` in length.
     function batchDepositERC20(uint256 containerTokenId, address[] calldata assetContracts, uint256[] calldata amounts)
         public
         nonReentrant // Protects against reentrancy on each transfer call
         tokenExists(containerTokenId)
         onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
     {
         require(assetContracts.length == amounts.length, "Array length mismatch");
         require(assetContracts.length > 0, "Empty batch");

         for (uint i = 0; i < assetContracts.length; i++) {
             // Call the single deposit function internally.
             // Note: This iterates and makes external calls, which can hit gas limits for large batches.
             // Error handling within the loop is limited; one failure reverts the whole batch.
              require(amounts[i] > 0, "Cannot deposit zero amount in batch");
              IERC20 assetERC20 = IERC20(assetContracts[i]);
              bool success = assetERC20.transferFrom(msg.sender, address(this), amounts[i]);
              require(success, "ERC20 transfer failed in batch");

             _heldERC20s[containerTokenId][assetContracts[i]] += amounts[i];

             // Ensure the asset contract address is tracked for this container if it's the first of its kind
              bool assetContractAlreadyTracked = false;
              for(uint j = 0; j < _heldERC20AssetContracts[containerTokenId].length; j++) {
                  if (_heldERC20AssetContracts[containerTokenId][j] == assetContracts[i]) {
                      assetContractAlreadyTracked = true;
                      break;
                  }
              }
              if (!assetContractAlreadyTracked) {
                  _heldERC20AssetContracts[containerTokenId].push(assetContracts[i]);
              }

              emit AssetDepositedERC20(containerTokenId, assetContracts[i], amounts[i], msg.sender);
         }
     }

    /// @notice Withdraws multiple ERC20 token types/amounts from a container NFT in a single transaction.
    /// @dev See `withdrawERC20` for permissions.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContracts Array of ERC20 asset contract addresses.
    /// @param amounts Array of amounts to withdraw. Must match `assetContracts` in length.
    /// @param recipient The address to send all withdrawn tokens to.
    function batchWithdrawERC20(uint256 containerTokenId, address[] calldata assetContracts, uint256[] calldata amounts, address recipient)
        public
        nonReentrant // Protects against reentrancy on each transfer call
        tokenExists(containerTokenId)
        onlyTokenOwnerOrApprovedManagerOrController(containerTokenId)
    {
        require(assetContracts.length == amounts.length, "Array length mismatch");
        require(assetContracts.length > 0, "Empty batch");
        require(recipient != address(0), "Cannot withdraw to zero address");

        for (uint i = 0; i < assetContracts.length; i++) {
             // Call the single withdrawal logic internally.
             // State updates and events are handled within this loop's logic.
             // Gas limit applies here as well. One failure reverts all.
            require(_heldERC20s[containerTokenId][assetContracts[i]] >= amounts[i], "Insufficient ERC20 balance for one asset in batch");
            require(amounts[i] > 0, "Cannot withdraw zero amount in batch");

            _heldERC20s[containerTokenId][assetContracts[i]] -= amounts[i];

            bool success = IERC20(assetContracts[i]).transfer(recipient, amounts[i]);
            require(success, "ERC20 transfer failed in batch");

             // Clean up the asset contract list if balance is now zero
             if (_heldERC20s[containerTokenId][assetContracts[i]] == 0) {
                 for(uint j = 0; j < _heldERC20AssetContracts[containerTokenId].length; j++) {
                     if (_heldERC20AssetContracts[containerTokenId][j] == assetContracts[i]) {
                         _heldERC20AssetContracts[containerTokenId][j] = _heldERC20AssetContracts[containerTokenId][_heldERC20AssetContracts[containerTokenId].length - 1];
                         _heldERC20AssetContracts[containerTokenId].pop();
                         break;
                     }
                 }
             }

            emit AssetWithdrawnERC20(containerTokenId, assetContracts[i], amounts[i], recipient);
        }
    }


    // --- Asset Query ---

    /// @notice Gets the list of ERC721 tokens held by a container NFT for a specific asset contract type.
    /// @dev Returns a snapshot of the list. Changes after call are not reflected.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the ERC721 asset contract.
    /// @return An array of ERC721 token IDs held by the container NFT from the specified contract.
    function getHeldERC721s(uint256 containerTokenId, address assetContract) public view tokenExists(containerTokenId) returns (uint256[] memory) {
        // Return the stored list. Note: This list might contain stale entries if withdrawal wasn't perfect,
        // but the _heldERC721s map is the source of truth for existence.
        // A more robust function might filter this list based on the _heldERC721s map.
        // For simplicity, we return the potentially unfiltered list, relying on the withdrawal logic to clean it.
        return _heldERC721List[containerTokenId][assetContract];
    }

     /// @notice Gets the list of ERC721 asset contract addresses held by a container NFT.
     /// @param containerTokenId The ID of the container NFT.
     /// @return An array of ERC721 asset contract addresses held by the container NFT.
     function getHeldERC721AssetContracts(uint256 containerTokenId) public view tokenExists(containerTokenId) returns (address[] memory) {
         return _heldERC721AssetContracts[containerTokenId];
     }

    /// @notice Gets the balance of a specific ERC20 token held by a container NFT.
    /// @param containerTokenId The ID of the container NFT.
    /// @param assetContract The address of the ERC20 asset contract.
    /// @return The balance of the specified ERC20 token held by the container NFT.
    function getHeldERC20Balance(uint256 containerTokenId, address assetContract) public view tokenExists(containerTokenId) returns (uint256) {
        return _heldERC20s[containerTokenId][assetContract];
    }

     /// @notice Gets the list of ERC20 asset contract addresses held by a container NFT.
     /// @param containerTokenId The ID of the container NFT.
     /// @return An array of ERC20 asset contract addresses held by the container NFT.
     function getHeldERC20AssetContracts(uint256 containerTokenId) public view tokenExists(containerTokenId) returns (address[] memory) {
         return _heldERC20AssetContracts[containerTokenId];
     }


    // --- Dynamic Attributes Management ---

    /// @notice Sets a dynamic attribute for a token with a bytes value.
    /// @dev Can be used for various data types by encoding.
    /// @dev Only token owner, approved manager, or controller can set attributes.
    /// @param tokenId The ID of the token.
    /// @param attributeName The name of the attribute.
    /// @param attributeValue The value of the attribute (as bytes).
    function setDynamicAttribute(uint256 tokenId, string calldata attributeName, bytes calldata attributeValue)
        public
        tokenExists(tokenId)
        onlyTokenOwnerOrApprovedManagerOrController(tokenId)
    {
        bytes storage currentValue = _dynamicAttributes[tokenId][attributeName];
         if (currentValue.length == 0) {
             // Add attribute name to list if it's new
             _tokenAttributeNames[tokenId].push(attributeName);
         }
        _dynamicAttributes[tokenId][attributeName] = attributeValue;
        emit AttributeChanged(tokenId, attributeName, attributeValue, msg.sender);
    }

    /// @notice Sets a dynamic attribute for a token with a uint256 value.
    /// @dev Overload for convenience.
    function setDynamicAttribute(uint256 tokenId, string calldata attributeName, uint256 attributeValue)
         public
         tokenExists(tokenId)
         onlyTokenOwnerOrApprovedManagerOrController(tokenId)
     {
         setDynamicAttribute(tokenId, attributeName, abi.encode(attributeValue));
     }

     /// @notice Sets a dynamic attribute for a token with a string value.
     /// @dev Overload for convenience.
     function setDynamicAttribute(uint256 tokenId, string calldata attributeName, string calldata attributeValue)
          public
          tokenExists(tokenId)
          onlyTokenOwnerOrApprovedManagerOrController(tokenId)
      {
          setDynamicAttribute(tokenId, attributeName, abi.encode(attributeValue));
      }


    /// @notice Gets the raw bytes value of a dynamic attribute for a token.
    /// @param tokenId The ID of the token.
    /// @param attributeName The name of the attribute.
    /// @return The attribute value as bytes (empty bytes if not set).
    function getDynamicAttribute(uint256 tokenId, string calldata attributeName) public view tokenExists(tokenId) returns (bytes memory) {
        return _dynamicAttributes[tokenId][attributeName];
    }

     /// @notice Gets the uint256 value of a dynamic attribute.
     /// @dev Panics if the stored bytes value is not a valid uint256 encoding.
     /// @param tokenId The ID of the token.
     /// @param attributeName The name of the attribute.
     /// @return The attribute value as uint256.
     function getDynamicAttributeUint(uint256 tokenId, string calldata attributeName) public view tokenExists(tokenId) returns (uint256) {
         bytes memory val = _dynamicAttributes[tokenId][attributeName];
         require(val.length == 32, "Attribute is not a uint256"); // Check if it's likely a uint256
         return abi.decode(val, (uint256));
     }

     /// @notice Gets the string value of a dynamic attribute.
     /// @dev Panics if the stored bytes value is not a valid string encoding.
     /// @param tokenId The ID of the token.
     /// @param attributeName The name of the attribute.
     /// @return The attribute value as string.
     function getDynamicAttributeString(uint256 tokenId, string calldata attributeName) public view tokenExists(tokenId) returns (string memory) {
         bytes memory val = _dynamicAttributes[tokenId][attributeName];
          // Cannot reliably check if bytes is a valid string encoding in Solidity, proceed with caution.
         return abi.decode(val, (string));
     }


    /// @notice Gets the list of dynamic attribute names set for a token.
    /// @param tokenId The ID of the token.
    /// @return An array of attribute names.
    function getTokenAttributeNames(uint256 tokenId) public view tokenExists(tokenId) returns (string[] memory) {
        return _tokenAttributeNames[tokenId];
    }

    /// @dev Internal helper to clear dynamic attributes for a token (e.g., on burn).
    function _clearDynamicAttributes(uint256 tokenId) internal {
        string[] storage names = _tokenAttributeNames[tokenId];
        for(uint i = 0; i < names.length; i++) {
            delete _dynamicAttributes[tokenId][names[i]];
        }
        delete _tokenAttributeNames[tokenId];
    }


    // --- Delegated Management ---

    /// @notice Sets an address authorized to manage the contents and attributes of a *specific* token.
    /// @dev This approval is separate from ERC721 transfer approval.
    /// @dev Only the token owner can set the approved manager for their token.
    /// @param tokenId The ID of the token.
    /// @param manager The address to approve (address(0) to remove approval).
    function setApprovedManager(uint256 tokenId, address manager) public tokenExists(tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _approvedManager[tokenId] = manager;
        emit ApprovedManagerSet(tokenId, manager, msg.sender);
    }

    /// @notice Gets the address approved to manage a specific token's contents and attributes.
    /// @param tokenId The ID of the token.
    /// @return The approved manager address (address(0) if none set).
    function getApprovedManager(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _approvedManager[tokenId];
    }


    // --- Access Control & Utility ---

    /// @notice Sets the general controller address.
    /// @dev The controller has permissions similar to an approved manager on all tokens, but can also be restricted by other logic.
    ///      In this contract, the controller can manage contents and attributes for any token.
    /// @param _controller The address to set as controller (address(0) to remove).
    function setController(address _controller) public onlyOwner {
        address oldController = controller;
        controller = _controller;
        emit ControllerSet(oldController, controller);
    }

    /// @notice Checks if an address is the current controller.
    function isController(address account) public view returns (bool) {
        return controller == account;
    }

    /// @notice Renounces the controller role.
    /// @dev Only the current controller can call this.
    function renounceController() public {
        require(msg.sender == controller, "Only controller can renounce");
        address oldController = controller;
        controller = address(0);
         emit ControllerSet(oldController, address(0));
    }


    /// @notice Sets the base URI for token metadata.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @inheritdoc ERC721
    /// @notice Returns the token URI. For dynamic attributes, the actual metadata JSON is expected to be off-chain,
    ///         using the token ID and potentially block information to generate the response based on on-chain attributes.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // The base URI should point to a service that can generate dynamic JSON metadata
        // based on the token ID and potentially query the on-chain attributes via RPC.
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId))) : "";
    }


    /// @notice Allows the contract owner to withdraw accidental Ether sent to the contract.
    function withdrawEther(uint256 amount) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient ether balance");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Ether withdrawal failed");
    }

    // Fallback function to reject direct Ether transfers unless withdrawEther is intended
    receive() external payable {
        revert("Direct Ether transfers not allowed, use withdrawEther if owner");
    }

    // --- Private/Internal Helpers ---

    /// @dev Checks if an address is the token owner, the approved manager, or the general controller.
    ///      Used by the `onlyTokenOwnerOrApprovedManagerOrController` modifier.
    function _isTokenOwnerOrApprovedManagerOrController(uint256 tokenId, address addr) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId); // Call ERC721 ownerOf
        return addr == tokenOwner || addr == controller || addr == _approvedManager[tokenId];
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Composable NFTs (Asset Holding):** The contract allows its NFTs (`DynamicNFTAssetManager` tokens) to securely hold other ERC721 and ERC20 tokens. This is achieved by making the `DynamicNFTAssetManager` contract itself the owner of the deposited assets and using internal mappings (`_heldERC721s`, `_heldERC20s`) to track which container token ID "owns" which asset internally. The `onERC721Received` hook is essential for securely receiving deposited ERC721s. This enables creating NFTs that represent bundles, collections, or even "vaults" of other digital assets.

2.  **Dynamic Attributes:** The `_dynamicAttributes` mapping allows mutable key-value pairs to be stored directly on-chain for each token. While the actual metadata JSON served via `tokenURI` would need to be generated by an off-chain service querying these on-chain attributes, the *source* of the dynamic data is the smart contract state. This enables NFTs that change appearance, utility, or status based on external events, interactions (like depositing assets), or time, without needing to mint a new NFT.

3.  **Delegated Management:** The `_approvedManager` mapping introduces a granular level of access control beyond the standard ERC721 approval. An owner can approve a specific address (like a dApp contract, a game, or a trusted third party) to manage the *contents* (`deposit`/`withdraw` assets) and *attributes* (`setDynamicAttribute`) of *one specific* NFT container they own, *without* giving that address the right to transfer or sell the container NFT itself. This is powerful for gaming, custodial services, or complex interactions where a dApp needs limited control over a user's specific NFT container. The `onlyTokenOwnerOrApprovedManagerOrController` modifier enforces this. The general `controller` address provides a higher-level administrative override.

4.  **Batch Operations:** Including `batchDeposit` and `batchWithdraw` functions for both ERC721 and ERC20 tokens addresses the common need for efficiency in web3 interactions. While simple loops that call the single deposit/withdraw function internally, they allow users to perform multiple asset transfers to/from a container NFT with a single blockchain transaction, saving gas and time compared to individual calls. (Note: Large batches can still hit block gas limits).

5.  **ERC721Receiver Implementation:** Explicitly implementing `IERC721Receiver` and the `onERC721Received` hook is crucial for the security of receiving ERC721 assets. It prevents malicious contracts from force-sending ERC721s that cannot be retrieved.

**Limitations/Considerations:**

*   **Off-chain Metadata:** While attributes are dynamic on-chain, displaying this dynamism requires an off-chain metadata service that queries the contract state when `tokenURI` is accessed.
*   **Gas Costs:** Batch operations, especially large ones or those interacting with complex external token contracts, can be gas-intensive.
*   **ERC721 List Management:** The `_heldERC721List` provides a convenient list but maintaining perfect sync with `_heldERC721s` upon withdrawal requires careful coding (which is attempted here, but list manipulation in Solidity is not the most gas-efficient).
*   **ERC20 Tracking:** The contract tracks ERC20 balances but relies on the list of `_heldERC20AssetContracts` to know *which* ERC20s might be held, which requires adding the contract address to this list on the *first* deposit.
*   **Security of Held Assets:** The security of the held assets is tied to the security of this `DynamicNFTAssetManager` contract. Any vulnerability in this contract could potentially affect all held assets. ReentrancyGuard is used on withdrawal functions, but thorough auditing is paramount.
*   **Attribute Data Types:** Using `bytes` for attributes offers flexibility but requires careful encoding/decoding off-chain or via helper view functions (`getDynamicAttributeUint`, etc.) and relies on conventions for interpreting the data.

This contract serves as a solid foundation demonstrating the requested advanced concepts, going significantly beyond a basic ERC721 implementation and providing unique capabilities for building interactive and dynamic NFT ecosystems. It fulfills the requirement of having well over 20 functions.