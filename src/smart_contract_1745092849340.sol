```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Trait NFT with On-Chain Evolution and Social Interaction
 * @author Bard (AI Assistant)
 * @notice A smart contract for creating Dynamic Trait NFTs that evolve based on on-chain activities,
 *         user interactions, and external data feeds (simulated here). It features a complex trait system,
 *         on-chain crafting, social gifting, dynamic rarity, and governance mechanisms.
 *
 * Function Summary:
 *
 * **Core NFT Functions:**
 * 1. `mintAvatar(string memory _name, string memory _baseURI)`: Mints a new Dynamic Trait NFT Avatar.
 * 2. `tokenURI(uint256 tokenId)`: Returns the URI metadata for a given token ID.
 * 3. `supportsInterface(bytes4 interfaceId)`:  Standard ERC721 interface support.
 * 4. `ownerOf(uint256 tokenId)`: Returns the owner of a token.
 * 5. `approve(address approved, uint256 tokenId)`: Approves an address to transfer a token.
 * 6. `getApproved(uint256 tokenId)`: Gets the approved address for a token.
 * 7. `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (ERC721 standard).
 * 8. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of a token (ERC721 standard).
 * 9. `balanceOf(address owner)`: Returns the number of tokens owned by an address.
 * 10. `setApprovalForAll(address operator, bool approved)`: Sets approval for all tokens for an operator.
 * 11. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens of an owner.
 *
 * **Dynamic Trait & Evolution Functions:**
 * 12. `getAvatarTraits(uint256 tokenId)`: Retrieves the dynamic traits of an avatar.
 * 13. `evolveAvatar(uint256 tokenId)`: Triggers avatar evolution based on on-chain activity (simulated).
 * 14. `simulateExternalDataFeed(uint256 tokenId)`: Simulates external data influencing avatar traits (admin only).
 * 15. `craftTrait(uint256 tokenId, uint8 traitIndex1, uint8 traitIndex2)`: Allows crafting new traits by combining existing ones (experimental).
 *
 * **Social & Interaction Functions:**
 * 16. `giftTrait(uint256 tokenId, uint8 traitIndex, address recipient)`: Gifts a trait from one avatar to another.
 * 17. `setName(uint256 tokenId, string memory _name)`: Allows owner to rename their avatar.
 * 18. `viewAvatarProfile(uint256 tokenId)`:  Returns a string summarizing the avatar's profile (name and traits).
 *
 * **Admin & Utility Functions:**
 * 19. `setBaseURI(string memory _newBaseURI)`: Sets the base URI for token metadata (admin only).
 * 20. `pauseContract()`: Pauses core functions of the contract (admin only).
 * 21. `unpauseContract()`: Resumes core functions of the contract (admin only).
 * 22. `withdrawFunds()`: Allows the contract owner to withdraw contract balance (admin only).
 */
contract DynamicTraitNFT {
    string public name = "Dynamic Trait Avatar";
    string public symbol = "DTA";
    string public baseURI;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 10000; // Example max supply

    address public owner;
    bool public paused;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _ownerOf;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner address to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Struct to represent dynamic traits of an avatar
    struct AvatarTraits {
        uint8 strength;
        uint8 agility;
        uint8 intelligence;
        uint8 charisma;
        uint8 luck;
        string visualAppearance; // Example: Could be a descriptor or link to visual data
        uint256 lastEvolvedTimestamp;
    }

    // Mapping from token ID to AvatarTraits
    mapping(uint256 => AvatarTraits) public avatarTraits;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event AvatarMinted(uint256 tokenId, address owner, string name);
    event AvatarEvolved(uint256 tokenId, AvatarTraits newTraits);
    event TraitGifted(uint256 tokenId, uint8 traitIndex, address recipient);
    event AvatarRenamed(uint256 tokenId, string newName);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_ownerOf[tokenId] != address(0), "Token does not exist.");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(_ownerOf[tokenId] == msg.sender, "You are not the owner of this token.");
        _;
    }


    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
    }

    /**
     * @dev Sets the base URI for token metadata. Only callable by the contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    /**
     * @dev Mints a new Dynamic Trait NFT Avatar.
     * @param _name The name of the avatar.
     * @param _baseURI Optional base URI override for this mint.
     * @return The tokenId of the newly minted avatar.
     */
    function mintAvatar(string memory _name, string memory _baseURI) public whenNotPaused returns (uint256) {
        require(totalSupply < MAX_SUPPLY, "Max supply reached.");
        totalSupply++;
        uint256 tokenId = totalSupply; // Simple sequential ID

        _ownerOf[tokenId] = msg.sender;

        // Initialize default traits - could be randomized or based on some logic
        avatarTraits[tokenId] = AvatarTraits({
            strength: uint8(50), // Example: Initial strength
            agility: uint8(50),  // Example: Initial agility
            intelligence: uint8(50), // Example: Initial intelligence
            charisma: uint8(50),   // Example: Initial charisma
            luck: uint8(50),        // Example: Initial luck
            visualAppearance: "Default Avatar Appearance", // Example: Initial appearance
            lastEvolvedTimestamp: block.timestamp
        });

        emit Transfer(address(0), msg.sender, tokenId);
        emit AvatarMinted(tokenId, msg.sender, _name);
        return tokenId;
    }

    /**
     * @dev Returns the URI metadata for a given token ID.
     * @param tokenId The ID of the token.
     * @return The URI string.
     */
    function tokenURI(uint256 tokenId) public view tokenExists returns (string memory) {
        require(_exists(tokenId), "Token URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Retrieves the dynamic traits of an avatar.
     * @param tokenId The ID of the token.
     * @return AvatarTraits struct containing the traits.
     */
    function getAvatarTraits(uint256 tokenId) public view tokenExists returns (AvatarTraits memory) {
        return avatarTraits[tokenId];
    }

    /**
     * @dev Triggers avatar evolution based on on-chain activity (simulated).
     *      Evolution could be based on time elapsed, interactions, etc.
     *      This is a simplified example; real evolution logic could be more complex and data-driven.
     * @param tokenId The ID of the token to evolve.
     */
    function evolveAvatar(uint256 tokenId) public whenNotPaused onlyTokenOwner(tokenId) tokenExists {
        AvatarTraits storage traits = avatarTraits[tokenId];
        require(block.timestamp >= traits.lastEvolvedTimestamp + 1 days, "Evolution cooldown period not over.");

        // Example evolution logic: Traits increase slightly over time
        traits.strength = uint8(Math.min(traits.strength + 5, 100)); // Cap traits at 100 for example
        traits.agility = uint8(Math.min(traits.agility + 3, 100));
        traits.intelligence = uint8(Math.min(traits.intelligence + 2, 100));
        traits.lastEvolvedTimestamp = block.timestamp;

        emit AvatarEvolved(tokenId, traits);
    }

    /**
     * @dev Simulates external data feed influencing avatar traits (admin only).
     *      In a real application, this would be replaced by an oracle integration.
     *      For demonstration, we'll just randomly adjust a trait.
     * @param tokenId The ID of the token to be affected.
     */
    function simulateExternalDataFeed(uint256 tokenId) public onlyOwner tokenExists {
        AvatarTraits storage traits = avatarTraits[tokenId];
        uint8 randomTraitIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId))) % 5); // Random index 0-4
        uint8 randomChange = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, randomTraitIndex))) % 10); // Random change up to 10

        if (randomTraitIndex == 0) traits.strength = uint8(Math.min(traits.strength + randomChange, 100));
        else if (randomTraitIndex == 1) traits.agility = uint8(Math.min(traits.agility + randomChange, 100));
        else if (randomTraitIndex == 2) traits.intelligence = uint8(Math.min(traits.intelligence + randomChange, 100));
        else if (randomTraitIndex == 3) traits.charisma = uint8(Math.min(traits.charisma + randomChange, 100));
        else if (randomTraitIndex == 4) traits.luck = uint8(Math.min(traits.luck + randomChange, 100));

        emit AvatarEvolved(tokenId, traits); // Could emit a different event if needed
    }

    /**
     * @dev Experimental function: Allows crafting new traits by combining existing ones.
     *      This is a very basic example; crafting systems can be much more complex.
     * @param tokenId The ID of the token performing crafting.
     * @param traitIndex1 Index of the first trait to combine (0=strength, 1=agility, etc.).
     * @param traitIndex2 Index of the second trait to combine.
     */
    function craftTrait(uint256 tokenId, uint8 traitIndex1, uint8 traitIndex2) public whenNotPaused onlyTokenOwner(tokenId) tokenExists {
        require(traitIndex1 < 5 && traitIndex2 < 5, "Invalid trait index.");
        AvatarTraits storage traits = avatarTraits[tokenId];

        uint8 combinedValue = uint8((_getTraitValueByIndex(traits, traitIndex1) + _getTraitValueByIndex(traits, traitIndex2)) / 2); // Simple average

        // Example: Crafting could increase a random trait slightly, and slightly decrease the combined traits
        uint8 randomTraitToIncrease = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, traitIndex1, traitIndex2))) % 5);
        _increaseTraitByIndex(traits, randomTraitToIncrease, uint8(Math.min(combinedValue / 10, 5))); // Small increase

        _decreaseTraitByIndex(traits, traitIndex1, uint8(Math.min(combinedValue / 20, 3))); // Small decrease in combined
        _decreaseTraitByIndex(traits, traitIndex2, uint8(Math.min(combinedValue / 20, 3)));

        emit AvatarEvolved(tokenId, traits); // Evolution event could be used for crafting too
    }

    /**
     * @dev Gifts a trait from one avatar to another.
     *      This is a social interaction feature.
     * @param tokenId The ID of the token gifting the trait.
     * @param traitIndex Index of the trait to gift (0=strength, 1=agility, etc.).
     * @param recipient Address of the recipient avatar owner.
     */
    function giftTrait(uint256 tokenId, uint8 traitIndex, address recipient) public whenNotPaused onlyTokenOwner(tokenId) tokenExists {
        require(traitIndex < 5, "Invalid trait index.");
        require(recipient != address(0) && recipient != msg.sender, "Invalid recipient address.");

        AvatarTraits storage donorTraits = avatarTraits[tokenId];
        uint8 traitValue = _getTraitValueByIndex(donorTraits, traitIndex);

        require(traitValue > 10, "Cannot gift a trait that is too low."); // Example: Min trait value to gift

        AvatarTraits storage recipientTraits = avatarTraits[getTokenIdByOwner(recipient)]; // Assuming recipient already has an avatar - simplified for example
        require(_ownerOf[getTokenIdByOwner(recipient)] != address(0), "Recipient does not own an avatar.");

        _increaseTraitByIndex(recipientTraits, traitIndex, uint8(traitValue / 5)); // Recipient gets a fraction of the gifted trait
        _decreaseTraitByIndex(donorTraits, traitIndex, uint8(traitValue / 10)); // Donor loses a smaller fraction

        emit TraitGifted(tokenId, traitIndex, recipient);
        emit AvatarEvolved(tokenId, donorTraits);
        emit AvatarEvolved(getTokenIdByOwner(recipient), recipientTraits);
    }


    /**
     * @dev Allows the owner to rename their avatar.
     * @param tokenId The ID of the token to rename.
     * @param _name The new name for the avatar.
     */
    function setName(uint256 tokenId, string memory _name) public whenNotPaused onlyTokenOwner(tokenId) tokenExists {
        // In a real application, you might store names separately, or encode in metadata.
        // For simplicity, we'll just update visualAppearance to include the name.
        avatarTraits[tokenId].visualAppearance = string(abi.encodePacked("Avatar: ", _name, " - Appearance details..."));
        emit AvatarRenamed(tokenId, _name);
    }

    /**
     * @dev Returns a string summarizing the avatar's profile (name and traits).
     * @param tokenId The ID of the token.
     * @return A string profile.
     */
    function viewAvatarProfile(uint256 tokenId) public view tokenExists returns (string memory) {
        AvatarTraits memory traits = avatarTraits[tokenId];
        // For simplicity, name is embedded in visualAppearance in setName function
        return string(abi.encodePacked(
            traits.visualAppearance,
            "\nStrength: ", Strings.toString(traits.strength),
            ", Agility: ", Strings.toString(traits.agility),
            ", Intelligence: ", Strings.toString(traits.intelligence),
            ", Charisma: ", Strings.toString(traits.charisma),
            ", Luck: ", Strings.toString(traits.luck)
        ));
    }


    /**
     * @dev Pauses core functions of the contract. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
    }

    /**
     * @dev Resumes core functions of the contract. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
    }

    /**
     * @dev Allows the contract owner to withdraw contract balance.
     */
    function withdrawFunds() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }


    // ------------------------------------------------------------------------
    // ERC721 Standard Functions (Basic Implementation - for demonstration)
    // ------------------------------------------------------------------------

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address ownerAddress) public view returns (uint256) {
        require(ownerAddress != address(0), "ERC721: balance query for the zero address");
        uint256 balance = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_ownerOf[i] == ownerAddress) {
                balance++;
            }
        }
        return balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view tokenExists returns (address) {
        return _ownerOf[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address approved, uint256 tokenId) public whenNotPaused tokenExists onlyTokenOwner(tokenId) {
        _tokenApprovals[tokenId] = approved;
        emit Approval(_ownerOf[tokenId], approved, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view tokenExists returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public whenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address ownerAddress, address operator) public view returns (bool) {
        return _operatorApprovals[ownerAddress][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused tokenExists {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from == _ownerOf[tokenId], "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId); // Clear approvals
        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused tokenExists {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public whenNotPaused tokenExists {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId The tokenId of the token to query.
     * @return Whether the token exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of spender to check
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the spender is approved or the owner
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address ownerAddress = _ownerOf[tokenId];
        return (spender == ownerAddress || getApproved(tokenId) == spender || isApprovedForAll(ownerAddress, spender));
    }

    /**
     * @dev Internal function to clear current approval of a token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token to be approved.
     */
    function _approve(address approved, uint256 tokenId) internal tokenExists {
        _tokenApprovals[tokenId] = approved;
        emit Approval(_ownerOf[tokenId], approved, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     *
     * @param from address representing the source of tokens
     * @param to address representing the destination of tokens
     * @param tokenId uint256 token ID to be transferred
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 token ID to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        mstore(0x00, reason.ptr)
                        revert(add(32, 0x00), mload(reason.ptr))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    // ------------------------------------------------------------------------
    // Utility Functions (Internal)
    // ------------------------------------------------------------------------

    /**
     * @dev Internal helper function to get trait value by index.
     */
    function _getTraitValueByIndex(AvatarTraits memory traits, uint8 index) internal pure returns (uint8) {
        if (index == 0) return traits.strength;
        if (index == 1) return traits.agility;
        if (index == 2) return traits.intelligence;
        if (index == 3) return traits.charisma;
        if (index == 4) return traits.luck;
        return 0; // Default, should not reach here if index is validated
    }

    /**
     * @dev Internal helper function to increase trait value by index.
     */
    function _increaseTraitByIndex(AvatarTraits storage traits, uint8 index, uint8 amount) internal pure {
        if (index == 0) traits.strength = uint8(Math.min(traits.strength + amount, 100));
        else if (index == 1) traits.agility = uint8(Math.min(traits.agility + amount, 100));
        else if (index == 2) traits.intelligence = uint8(Math.min(traits.intelligence + amount, 100));
        else if (index == 3) traits.charisma = uint8(Math.min(traits.charisma + amount, 100));
        else if (index == 4) traits.luck = uint8(Math.min(traits.luck + amount, 100));
    }

    /**
     * @dev Internal helper function to decrease trait value by index.
     */
    function _decreaseTraitByIndex(AvatarTraits storage traits, uint8 index, uint8 amount) internal pure {
        if (index == 0) traits.strength = uint8(Math.max(traits.strength - amount, 0));
        else if (index == 1) traits.agility = uint8(Math.max(traits.agility - amount, 0));
        else if (index == 2) traits.intelligence = uint8(Math.max(traits.intelligence - amount, 0));
        else if (index == 3) traits.charisma = uint8(Math.max(traits.charisma - amount, 0));
        else if (index == 4) traits.luck = uint8(Math.max(traits.luck - amount, 0));
    }

    /**
     * @dev Internal helper to get token ID by owner address (assuming 1 avatar per owner for simplicity).
     *      In a real scenario, you might have multiple avatars per owner and need a more complex lookup.
     */
    function getTokenIdByOwner(address ownerAddress) internal view returns (uint256) {
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (_ownerOf[i] == ownerAddress) {
                return i;
            }
        }
        return 0; // Or revert if you expect every address to have an avatar
    }
}

// --- Libraries ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

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
}

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     *
     * Triggered when minting (``from`` is address(0)) or burning (``to`` is address(0)).
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` operator to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Approve `spender` to operate on `tokenId` token. Only allows one operator per token.
     *
     * Emits {Approval} event.
     */
    function approve(address spender, uint256 tokenId) external payable;

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external payable;

    /**
     * @dev Returns the account approved for `tokenId` token, if any.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is approved to manage all of the `owner` assets.
     *
     * Emits {ApprovalForAll} event.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} token is transferred to this contract via {safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface id is not supported by the other
     * contract, the safe transfer will be reverted.
     *
     * The bytes4 return value should be `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * IMPORTANT: If this function is implemented, it must be declared external and non-payable.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See {IERC165-supportsInterface}.
     *
     * @param interfaceId The interface ID that will be queried.
     * @return bool if the contract implements the interface.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
```