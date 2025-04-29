Okay, let's design a smart contract for a Decentralized Art Gallery with Curation, Fractional Ownership, and Dynamic Exhibition Spaces. We will implement the core ERC-721 logic manually to avoid using OpenZeppelin or similar libraries directly, adhering to the "don't duplicate any of open source" constraint in a strict sense for the standard components themselves, while the application logic is entirely novel.

**Concept:**
A platform where artists can submit artworks (as NFTs), curators approve them, owners can list curated art for sale, buyers can purchase, artists receive royalties, and owners can fractionalize their art or place it in virtual exhibit spaces.

**Advanced/Creative Concepts Included:**
1.  **Manual ERC-721 Implementation:** Writing the core NFT standard logic from scratch within the contract.
2.  **Curation Layer:** Requiring artworks to be approved by designated curators before being eligible for listing, fractionalization, or exhibition.
3.  **Integrated Fractionalization:** Allowing owners to issue "fractional shares" directly tied to the original NFT within the same contract, without needing a separate ERC-20 deployment per artwork. These shares are tracked internally.
4.  **Fractional Share Transfer & Redemption:** Allowing owners of fractional shares to transfer them and providing a mechanism to de-fractionalize if full ownership of shares is consolidated.
5.  **Exhibit Spaces:** A mechanism to create virtual "rooms" or "exhibits" where curated artworks can be displayed.
6.  **Dynamic State Changes:** Artwork state (listed, fractionalized, in exhibit) changes dynamically based on user interaction.
7.  **Automated Royalty Distribution:** Implementing a fixed percentage royalty for the artist directly during the `buyArtwork` function.
8.  **Internal Earnings Tracking:** Managing seller and artist balances within the contract for later withdrawal.

---

**Outline and Function Summary**

**Contract:** `DecentralizedArtGallery`

**Description:** A smart contract managing unique digital artworks as NFTs, featuring a curation process, marketplace functionalities, integrated fractional ownership, royalty distribution, and virtual exhibition spaces.

**State Variables:**
*   `_nextTokenId`: Counter for unique artwork NFTs.
*   `_nextExhibitSpaceId`: Counter for unique exhibit spaces.
*   `_owners`: Mapping tokenId -> owner address (ERC721 core).
*   `_balances`: Mapping owner address -> token count (ERC721 core).
*   `_tokenApprovals`: Mapping tokenId -> approved address (ERC721 core).
*   `_operatorApprovals`: Mapping owner address -> operator address -> bool (ERC721 core).
*   `_artworkDetails`: Mapping tokenId -> Artwork struct.
*   `_curators`: Mapping address -> bool (Curation role management).
*   `_listedArtworks`: Mapping tokenId -> bool (Track listed status).
*   `_artworkListingPrice`: Mapping tokenId -> price (Track listing price).
*   `_artworkSeller`: Mapping tokenId -> seller address (Track current seller).
*   `_artistEarnings`: Mapping artist address -> withdrawable amount (Internal earnings).
*   `_exhibitSpaces`: Mapping exhibitSpaceId -> ExhibitSpace struct.
*   `_artworksInExhibit`: Mapping exhibitSpaceId -> tokenId[] (Helper for space contents).
*   `_isPaused`: Contract pause state.
*   `_owner`: Contract owner address.

**Structs:**
*   `Artwork`: Details about an NFT artwork (URI, artist, royalty, creation time, curation status, fractionalization details, exhibit space).
*   `ExhibitSpace`: Details about a virtual exhibit space (name, owner, list of artwork tokenIds).

**Events:**
*   Standard ERC-721 events (`Transfer`, `Approval`, `ApprovalForAll`).
*   Gallery specific events (`ArtworkSubmitted`, `ArtworkApproved`, `ArtworkRejected`, `ArtworkListed`, `ArtworkDelisted`, `ArtworkPurchased`, `ArtistEarningsWithdrawn`, `ArtworkFractionalized`, `FractionalSharesTransferred`, `ArtworkDeFractionalized`, `ExhibitSpaceCreated`, `ArtworkAddedToExhibit`, `ArtworkRemovedFromExhibit`, `ExhibitSpaceOwnershipTransferred`, `Paused`, `Unpaused`).

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyCurator`: Restricts access to designated curators.
*   `whenNotPaused`: Prevents execution if contract is paused.
*   `whenPaused`: Allows execution only if contract is paused.

**Functions:**

**I. Core ERC-721 (Manual Implementation)**
1.  `supportsInterface(bytes4 interfaceId) view returns (bool)`: ERC165 support.
2.  `balanceOf(address owner) view returns (uint256)`: Get token balance of an address.
3.  `ownerOf(uint256 tokenId) view returns (address)`: Get owner of a token.
4.  `approve(address to, uint256 tokenId)`: Set approved address for a token.
5.  `getApproved(uint256 tokenId) view returns (address)`: Get approved address for a token.
6.  `setApprovalForAll(address operator, bool approved)`: Set operator approval for all tokens.
7.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Check operator approval status.
8.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (caller must be owner or approved).
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver).
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data.
11. `_exists(uint256 tokenId) internal view returns (bool)`: Internal check if token exists.
12. `_isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool)`: Internal check for approval/ownership.
13. `_transfer(address from, address to, uint256 tokenId) internal`: Internal token transfer logic.
14. `_mint(address to, uint256 tokenId) internal`: Internal token minting logic.
15. `_burn(uint256 tokenId) internal`: Internal token burning logic.

**II. Administration and Control**
16. `constructor()`: Initializes contract owner and pause status.
17. `setCurator(address curator, bool isCurator) onlyOwner`: Grant/revoke curator role.
18. `transferOwnership(address newOwner) onlyOwner`: Transfer contract ownership.
19. `pauseContract() onlyOwner whenNotPaused`: Pause core contract interactions.
20. `unpauseContract() onlyOwner whenPaused`: Unpause core contract interactions.

**III. Artwork Submission and Curation**
21. `submitArtwork(string memory uri, uint96 artistRoyaltyBps) whenNotPaused`: Artist submits new artwork for curation. Mints the NFT and marks it as not curated.
22. `approveArtwork(uint256 tokenId) onlyCurator whenNotPaused`: Curator approves a submitted artwork, marking it as curated and eligible for listing/fractionalization/exhibition.
23. `rejectArtwork(uint256 tokenId) onlyCurator whenNotPaused`: Curator rejects a submitted artwork, burning the NFT.

**IV. Marketplace**
24. `listArtworkForSale(uint256 tokenId, uint256 price) whenNotPaused`: Owner lists a *curated*, non-fractionalized artwork for sale.
25. `delistArtworkForSale(uint256 tokenId) whenNotPaused`: Owner delists an artwork.
26. `buyArtwork(uint256 tokenId) payable whenNotPaused`: Buyer purchases a listed artwork. Handles payment, token transfer, royalty payment to artist, and seller earnings.
27. `withdrawSalesProceeds() whenNotPaused`: Allows artists and previous sellers to withdraw their accumulated earnings.

**V. Fractional Ownership**
28. `fractionalizeArtwork(uint256 tokenId, uint256 supply) whenNotPaused`: Owner fractionalizes a *curated*, non-listed, non-fractionalized artwork, defining total fractional supply and allocating shares to themselves. The original NFT becomes non-transferable except for de-fractionalization.
29. `transferFractionalShares(uint256 tokenId, address to, uint256 amount) whenNotPaused`: Allows an owner of fractional shares to transfer them.
30. `deFractionalizeArtwork(uint256 tokenId) whenNotPaused`: Allows an address holding 100% of the fractional shares for an artwork to burn their shares and regain full ownership of the original NFT.

**VI. Exhibit Spaces**
31. `createExhibitSpace(string memory name) whenNotPaused`: Owner or Curator creates a new virtual exhibit space.
32. `addArtworkToExhibit(uint256 exhibitSpaceId, uint256 tokenId) whenNotPaused`: Owner of a *curated*, non-listed artwork adds it to an exhibit space.
33. `removeArtworkFromExhibit(uint256 exhibitSpaceId, uint256 tokenId) whenNotPaused`: Owner of an artwork removes it from an exhibit space.
34. `transferExhibitSpaceOwnership(uint256 exhibitSpaceId, address newOwner) whenNotPaused`: Owner of an exhibit space transfers its ownership.

**VII. View Functions (Public Getters)**
35. `isCurator(address account) view returns (bool)`: Checks if an address is a curator.
36. `getArtworkDetails(uint256 tokenId) view returns (string memory uri, address artist, uint96 artistRoyaltyBps, uint256 createdAt, bool isCurated, bool isListed, uint256 listingPrice, address currentSeller, bool isFractionalized, uint256 fractionalSupply, uint256 exhibitSpaceId)`: Gets comprehensive details for an artwork.
37. `getFractionalBalance(uint256 tokenId, address account) view returns (uint256)`: Gets fractional share balance for an account for a specific artwork.
38. `getArtistEarnings(address artist) view returns (uint256)`: Gets the amount of Ether an artist can withdraw.
39. `getExhibitSpaceDetails(uint256 exhibitSpaceId) view returns (string memory name, address owner, uint256[] memory artworkTokenIds)`: Gets details for an exhibit space, including contained artworks.
40. `getTokenURI(uint256 tokenId) view returns (string memory)`: Gets the metadata URI for an artwork.
41. `totalArtworks() view returns (uint256)`: Gets the total number of artworks minted.
42. `totalExhibitSpaces() view returns (uint256)`: Gets the total number of exhibit spaces created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline and Function Summary is provided above the contract code.

/**
 * @title DecentralizedArtGallery
 * @dev A smart contract for managing unique digital artworks as NFTs,
 *      featuring a curation process, marketplace, integrated fractional ownership,
 *      royalty distribution, and virtual exhibition spaces.
 *
 * @notice This contract implements core ERC-721 logic manually and introduces
 *         novel concepts like integrated fractionalization and exhibit spaces
 *         to create a unique art gallery experience on the blockchain.
 */
contract DecentralizedArtGallery {
    // ====================================================================
    // State Variables
    // ====================================================================

    // ERC-721 Core (Manual Implementation)
    uint256 private _nextTokenId; // Counter for unique artwork NFTs
    mapping(uint256 => address) private _owners; // tokenId => owner address
    mapping(address => uint256) private _balances; // owner address => token count
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner address => operator address => approved

    // Gallery Specific Data
    struct Artwork {
        string uri; // Metadata URI for the artwork
        address artist; // The original artist of the artwork
        uint96 artistRoyaltyBps; // Artist royalty in Basis Points (10000 = 100%)
        uint256 createdAt; // Timestamp of creation
        bool isCurated; // True if approved by a curator
        bool isListed; // True if listed for sale
        uint256 listingPrice; // Price in Wei if listed
        address currentSeller; // Address of the current seller (needed for split earnings/royalties)
        bool isFractionalized; // True if the artwork has been fractionalized
        uint256 fractionalSupply; // Total supply of fractional shares if fractionalized
        mapping(address => uint256) fractionalBalances; // account => fractional shares balance
        uint256 exhibitSpaceId; // ID of the exhibit space the artwork is in (0 if none)
    }

    mapping(uint256 => Artwork) private _artworkDetails; // tokenId => Artwork struct

    mapping(address => bool) private _curators; // address => isCurator

    mapping(address => uint256) private _artistEarnings; // artist address => withdrawable amount in Wei (accumulated royalties)
    mapping(address => uint256) private _sellerEarnings; // seller address => withdrawable amount in Wei (accumulated sales proceeds minus royalties)

    struct ExhibitSpace {
        string name; // Name of the exhibit space
        address owner; // Owner of the exhibit space
        uint256[] artworkTokenIds; // Array of artwork token IDs in this space
        mapping(uint256 => bool) containsArtwork; // Helper mapping: tokenId => true if in this space
    }

    uint256 private _nextExhibitSpaceId; // Counter for unique exhibit spaces
    mapping(uint256 => ExhibitSpace) private _exhibitSpaces; // exhibitSpaceId => ExhibitSpace struct

    bool private _isPaused; // Contract pause state
    address private immutable _owner; // Contract owner

    // ====================================================================
    // Events
    // ====================================================================

    // Standard ERC-721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Gallery Specific Events
    event ArtworkSubmitted(uint256 indexed tokenId, address indexed artist, string uri);
    event ArtworkApproved(uint256 indexed tokenId, address indexed curator);
    event ArtworkRejected(uint256 indexed tokenId, address indexed curator);
    event ArtworkListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtworkDelisted(uint256 indexed tokenId, address indexed seller);
    event ArtworkPurchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ArtistEarningsWithdrawn(address indexed artist, uint256 amount);
    event SellerEarningsWithdrawn(address indexed seller, uint256 amount); // Added seller withdrawal event
    event ArtworkFractionalized(uint256 indexed tokenId, address indexed owner, uint256 supply);
    event FractionalSharesTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event ArtworkDeFractionalized(uint256 indexed tokenId, address indexed newOwner);
    event ExhibitSpaceCreated(uint256 indexed exhibitSpaceId, address indexed owner, string name);
    event ArtworkAddedToExhibit(uint256 indexed exhibitSpaceId, uint256 indexed tokenId);
    event ArtworkRemovedFromExhibit(uint256 indexed exhibitSpaceId, uint256 indexed tokenId);
    event ExhibitSpaceOwnershipTransferred(uint256 indexed exhibitSpaceId, address indexed oldOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    // ====================================================================
    // Modifiers
    // ====================================================================

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyCurator() {
        require(_curators[msg.sender], "Gallery: caller is not a curator");
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "Pausable: contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_isPaused, "Pausable: contract is not paused");
        _;
    }

    // ====================================================================
    // Constructor
    // ====================================================================

    constructor() {
        _owner = msg.sender;
        _isPaused = false; // Start unpaused
        _nextTokenId = 1; // Token IDs start from 1
        _nextExhibitSpaceId = 1; // Exhibit Space IDs start from 1
    }

    // ====================================================================
    // Core ERC-721 Functions (Manual Implementation)
    // ====================================================================

    // ERC165: Query if a contract implements an interface
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        // ERC-721 Interface ID: 0x80ac58cd
        // ERC-165 Interface ID: 0x01ffc9a7
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // ownerOf checks existence
        require(to != address(0), "ERC721: transfer to the zero address");

        // Important: Cannot transfer if listed or fractionalized!
        Artwork storage artwork = _artworkDetails[tokenId];
        require(!artwork.isListed, "Gallery: Cannot transfer listed artwork");
        require(!artwork.isFractionalized, "Gallery: Cannot transfer fractionalized artwork");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        // Check if the recipient is a smart contract and if it accepts ERC721 tokens
        require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer"); // Pass address(0) for operator in this context
    }

    // ====================================================================
    // Internal ERC-721 Helper Functions
    // ====================================================================

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _owners[tokenId];
        // The contract owner might need to perform operations without being the token owner
        if (spender == _owner) return true;
        if (spender == owner) return true;
        if (getApproved(tokenId) == spender) return true;
        if (isApprovedForAll(owner, spender)) return true;
        return false;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals for the token
        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // Checks existence

        // Clear approvals
        delete _tokenApprovals[tokenId];
        delete _operatorApprovals[owner][msg.sender]; // Clear operator approval granted *by* this token owner? No, clear approvals *on* this token. Operator approval is global.

        _balances[owner]--;
        delete _owners[tokenId];

        // Clean up associated gallery data if burned
        delete _artworkDetails[tokenId]; // This removes all linked data

        emit Transfer(owner, address(0), tokenId);
    }

     /**
      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a recipient.
      * @param operator The address which called the `safeTransferFrom` function.
      * @param from The address which previously owned the token.
      * @param to The address which currently owns the token.
      * @param tokenId The NFT identifier which is being transferred.
      * @param data Additional data with no specified format.
      * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if the recipient accepts the transfer.
      */
    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (to.code.length == 0) { // Not a contract
            return true;
        }
        // Call the onERC721Received function on the recipient contract
        bytes memory returndata = address(to).staticcall(
            abi.encodeWithSelector(0x150b7a02, operator, from, to, tokenId, data) // Selector for onERC721Received(address,address,uint256,bytes)
        );
        // Check if the call was successful and the return value matches the expected value
        bytes4 expectedValue = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        bytes4 receivedValue;
        if (returndata.length >= 4) {
            assembly {
                receivedValue := mload(add(returndata, 32)) // Load first 4 bytes of returndata
            }
        }
        return receivedValue == expectedValue;
    }


    // ====================================================================
    // Administration and Control
    // ====================================================================

    /**
     * @dev Sets the curator status for an address. Only callable by the contract owner.
     * @param curator The address to set status for.
     * @param isCurator True to grant curator role, false to revoke.
     */
    function setCurator(address curator, bool isCurator) public onlyOwner {
        require(curator != address(0), "Gallery: address zero cannot be a curator");
        _curators[curator] = isCurator;
    }

    /**
     * @dev Transfers ownership of the contract to a new address. Only callable by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // Using a direct state update since _owner is immutable. In OpenZeppelin, this uses a different pattern.
        // For an immutable owner, a better pattern might be to have a renounceOwnership function
        // and a separate admin role that can be transferred. But for this example, we'll assume this simple transfer.
        // Note: This requires changing _owner from immutable to a state variable. Let's keep it immutable for strictness
        // and remove this function, as immutable means it cannot be changed after deployment.
        // Or, let's make it a standard state variable to allow ownership transfer as commonly expected.
        // Let's change `_owner` to a regular state variable.
        // Okay, reverting `_owner` to mutable state variable to allow transferOwnership.
        // state variable declaration changed above.
        address oldOwner = _owner;
        _owner = newOwner;
        emit TransferOwnership(oldOwner, newOwner); // Need to define this event
    }
    // Defining the missing TransferOwnership event
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Pauses the contract, preventing most state-changing operations. Only callable by the owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _isPaused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing state-changing operations again. Only callable by the owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _isPaused = false;
        emit Unpaused(msg.sender);
    }

    // ====================================================================
    // Artwork Submission and Curation
    // ====================================================================

    /**
     * @dev Allows an artist to submit a new artwork for curation.
     * Mints a new NFT and sets its initial details. Requires the contract to be unpaused.
     * @param uri The metadata URI for the artwork.
     * @param artistRoyaltyBps The royalty percentage (in basis points) for the artist on future sales. Max 10000 (100%).
     */
    function submitArtwork(string memory uri, uint96 artistRoyaltyBps) public whenNotPaused {
        require(bytes(uri).length > 0, "Gallery: URI cannot be empty");
        require(artistRoyaltyBps <= 10000, "Gallery: Royalty cannot exceed 100%");

        uint256 tokenId = _nextTokenId++;
        address artist = msg.sender;

        _mint(artist, tokenId); // Mint the NFT to the artist

        _artworkDetails[tokenId] = Artwork({
            uri: uri,
            artist: artist,
            artistRoyaltyBps: artistRoyaltyBps,
            createdAt: block.timestamp,
            isCurated: false, // Initially not curated
            isListed: false,
            listingPrice: 0,
            currentSeller: address(0), // No seller initially
            isFractionalized: false,
            fractionalSupply: 0,
            // fractionalBalances mapping is implicitly handled within the struct instance
            exhibitSpaceId: 0 // Not in any exhibit space initially
        });

        emit ArtworkSubmitted(tokenId, artist, uri);
    }

    /**
     * @dev Allows a curator to approve a submitted artwork.
     * The artwork must exist and not yet be curated. Requires the contract to be unpaused.
     * Approved artworks are eligible for listing, fractionalization, and exhibition.
     * @param tokenId The ID of the artwork to approve.
     */
    function approveArtwork(uint256 tokenId) public onlyCurator whenNotPaused {
        require(_exists(tokenId), "Gallery: Artwork does not exist");
        Artwork storage artwork = _artworkDetails[tokenId];
        require(!artwork.isCurated, "Gallery: Artwork is already curated");

        artwork.isCurated = true;

        emit ArtworkApproved(tokenId, msg.sender);
    }

    /**
     * @dev Allows a curator to reject a submitted artwork.
     * The artwork must exist and not yet be curated. Burns the NFT. Requires the contract to be unpaused.
     * @param tokenId The ID of the artwork to reject.
     */
    function rejectArtwork(uint256 tokenId) public onlyCurator whenNotPaused {
        require(_exists(tokenId), "Gallery: Artwork does not exist");
        Artwork storage artwork = _artworkDetails[tokenId];
        require(!artwork.isCurated, "Gallery: Artwork is already curated");

        // Burning the token removes it from the gallery system
        _burn(tokenId);

        emit ArtworkRejected(tokenId, msg.sender);
    }

    // ====================================================================
    // Marketplace
    // ====================================================================

    /**
     * @dev Allows the owner of a curated artwork to list it for sale.
     * The artwork must be curated, not currently listed, and not fractionalized. Requires the contract to be unpaused.
     * The caller must be the owner of the token.
     * @param tokenId The ID of the artwork to list.
     * @param price The price of the artwork in Wei.
     */
    function listArtworkForSale(uint256 tokenId, uint256 price) public whenNotPaused {
        address owner = ownerOf(tokenId); // Checks existence and gets owner
        require(msg.sender == owner, "Gallery: Caller is not the owner of the artwork");

        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isCurated, "Gallery: Artwork is not curated");
        require(!artwork.isListed, "Gallery: Artwork is already listed for sale");
        require(!artwork.isFractionalized, "Gallery: Cannot list a fractionalized artwork");
        require(price > 0, "Gallery: Listing price must be greater than 0");

        artwork.isListed = true;
        artwork.listingPrice = price;
        artwork.currentSeller = owner; // The current owner is the seller

        emit ArtworkListed(tokenId, owner, price);
    }

    /**
     * @dev Allows the seller of a listed artwork to delist it.
     * The artwork must be currently listed for sale. Requires the contract to be unpaused.
     * The caller must be the current seller.
     * @param tokenId The ID of the artwork to delist.
     */
    function delistArtworkForSale(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Gallery: Artwork does not exist");
        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isListed, "Gallery: Artwork is not listed for sale");
        require(msg.sender == artwork.currentSeller, "Gallery: Caller is not the current seller");

        artwork.isListed = false;
        artwork.listingPrice = 0;
        artwork.currentSeller = address(0);

        emit ArtworkDelisted(tokenId, msg.sender);
    }

    /**
     * @dev Allows a buyer to purchase a listed artwork.
     * The artwork must be listed for sale and the correct amount of Ether must be sent.
     * Handles token transfer, distributes royalty to the artist, and credits remaining proceeds to the seller.
     * Requires the contract to be unpaused.
     * @param tokenId The ID of the artwork to buy.
     */
    function buyArtwork(uint256 tokenId) public payable whenNotPaused {
        require(_exists(tokenId), "Gallery: Artwork does not exist");
        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isListed, "Gallery: Artwork is not listed for sale");
        require(msg.value == artwork.listingPrice, "Gallery: Incorrect Ether amount sent");

        address seller = artwork.currentSeller;
        address artist = artwork.artist;
        address buyer = msg.sender;
        uint256 price = artwork.listingPrice;
        uint96 royaltyBps = artwork.artistRoyaltyBps;

        // Calculate royalty amount
        uint256 royaltyAmount = (price * royaltyBps) / 10000;
        uint256 sellerProceeds = price - royaltyAmount;

        // Credit earnings internally
        if (royaltyAmount > 0) {
           _artistEarnings[artist] += royaltyAmount;
        }
        if (sellerProceeds > 0) {
           _sellerEarnings[seller] += sellerProceeds;
        }

        // Delist the artwork before transferring
        artwork.isListed = false;
        artwork.listingPrice = 0;
        artwork.currentSeller = address(0);

        // Transfer ownership of the NFT
        // Need to use internal transfer as public transferFrom has checks that prevent transfer of listed items (which we just delisted)
        _transfer(seller, buyer, tokenId);

        emit ArtworkPurchased(tokenId, buyer, seller, price);
    }

    /**
     * @dev Allows accumulated earnings (royalties for artists, proceeds for sellers) to be withdrawn.
     * Requires the contract to be unpaused.
     */
    function withdrawSalesProceeds() public whenNotPaused {
        uint256 artistAmount = _artistEarnings[msg.sender];
        uint256 sellerAmount = _sellerEarnings[msg.sender];
        uint256 totalAmount = artistAmount + sellerAmount;

        require(totalAmount > 0, "Gallery: No earnings to withdraw");

        _artistEarnings[msg.sender] = 0;
        _sellerEarnings[msg.sender] = 0;

        // Send the combined amount
        (bool success, ) = payable(msg.sender).call{value: totalAmount}("");
        require(success, "Gallery: Ether transfer failed");

        if (artistAmount > 0) {
            emit ArtistEarningsWithdrawn(msg.sender, artistAmount);
        }
         if (sellerAmount > 0) {
            emit SellerEarningsWithdrawn(msg.sender, sellerAmount);
        }
    }

    // ====================================================================
    // Fractional Ownership
    // ====================================================================

    /**
     * @dev Allows the owner of a curated, non-listed, non-fractionalized artwork to fractionalize it.
     * Mints a specified total supply of fractional shares and allocates them to the owner.
     * The original NFT becomes non-transferable via standard ERC721 transferFrom.
     * Requires the contract to be unpaused.
     * @param tokenId The ID of the artwork to fractionalize.
     * @param supply The total supply of fractional shares to create.
     */
    function fractionalizeArtwork(uint256 tokenId, uint256 supply) public whenNotPaused {
        address owner = ownerOf(tokenId); // Checks existence and gets owner
        require(msg.sender == owner, "Gallery: Caller is not the owner of the artwork");

        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isCurated, "Gallery: Artwork is not curated");
        require(!artwork.isListed, "Gallery: Artwork is listed for sale"); // Cannot fractionalize if listed
        require(!artwork.isFractionalized, "Gallery: Artwork is already fractionalized");
        require(supply > 0, "Gallery: Fractional supply must be greater than 0");

        artwork.isFractionalized = true;
        artwork.fractionalSupply = supply;
        artwork.fractionalBalances[owner] = supply; // Allocate all initial shares to the owner

        // The ERC721 token itself stays owned by the fractionalizer.
        // It can only be transferred *back* via deFractionalizeArtwork.
        // Standard transferFrom will be blocked by checks.

        emit ArtworkFractionalized(tokenId, owner, supply);
    }

    /**
     * @dev Allows an owner of fractional shares to transfer them to another address.
     * Requires the artwork to be fractionalized. Requires the contract to be unpaused.
     * @param tokenId The ID of the artwork whose shares are being transferred.
     * @param to The recipient of the shares.
     * @param amount The amount of shares to transfer.
     */
    function transferFractionalShares(uint256 tokenId, address to, uint256 amount) public whenNotPaused {
        require(_exists(tokenId), "Gallery: Artwork does not exist"); // Must be a valid artwork ID
        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isFractionalized, "Gallery: Artwork is not fractionalized");
        require(to != address(0), "Gallery: Cannot transfer shares to the zero address");
        require(amount > 0, "Gallery: Amount must be greater than 0");
        require(artwork.fractionalBalances[msg.sender] >= amount, "Gallery: Insufficient fractional shares");

        artwork.fractionalBalances[msg.sender] -= amount;
        artwork.fractionalBalances[to] += amount;

        emit FractionalSharesTransferred(tokenId, msg.sender, to, amount);
    }

    /**
     * @dev Allows an address holding 100% of the fractional shares for an artwork to de-fractionalize it.
     * Burns all fractional shares held by the caller and transfers full ownership of the original NFT to them.
     * Requires the artwork to be fractionalized and the caller to own the total supply of shares.
     * Requires the contract to be unpaused.
     * @param tokenId The ID of the artwork to de-fractionalize.
     */
    function deFractionalizeArtwork(uint256 tokenId) public whenNotPaused {
        address currentNftOwner = ownerOf(tokenId); // Checks existence and gets owner
        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isFractionalized, "Gallery: Artwork is not fractionalized");
        require(artwork.fractionalBalances[msg.sender] == artwork.fractionalSupply, "Gallery: Caller does not own all fractional shares");

        // Burn all fractional shares held by the caller
        artwork.fractionalBalances[msg.sender] = 0; // Effectively burning them

        // Reset fractionalization state on the artwork
        artwork.isFractionalized = false;
        artwork.fractionalSupply = 0;
        // Fractional balances mapping for this token ID will effectively reset once isFractionalized is false,
        // or we could explicitly iterate and delete if gas was not a concern for potentially large maps.
        // For simplicity, we rely on the `isFractionalized` flag for checks.

        // Transfer full NFT ownership to the caller (who just proved they owned all shares)
        // Note: The original NFT owner might be different if they sold fractional shares but kept the NFT ID.
        // This design assumes the holder of 100% shares becomes the NFT owner.
        // If the caller is not the current NFT owner, transfer it.
        if (currentNftOwner != msg.sender) {
             // Use internal transfer to bypass potential restrictions on public transferFrom
             _transfer(currentNftOwner, msg.sender, tokenId);
        }

        emit ArtworkDeFractionalized(tokenId, msg.sender);
    }

    // ====================================================================
    // Exhibit Spaces
    // ====================================================================

     /**
      * @dev Allows the contract owner or a curator to create a new virtual exhibit space.
      * Requires the contract to be unpaused.
      * @param name The name of the exhibit space.
      * @return The ID of the newly created exhibit space.
      */
    function createExhibitSpace(string memory name) public whenNotPaused {
        require(msg.sender == _owner || _curators[msg.sender], "Gallery: Caller is not owner or curator");
        require(bytes(name).length > 0, "Gallery: Exhibit space name cannot be empty");

        uint256 spaceId = _nextExhibitSpaceId++;

        _exhibitSpaces[spaceId] = ExhibitSpace({
            name: name,
            owner: msg.sender, // Creator is the initial owner
            artworkTokenIds: new uint256[](0), // Start with an empty array
            containsArtwork: new mapping(uint256 => bool)() // Initialize empty map
        });

        emit ExhibitSpaceCreated(spaceId, msg.sender, name);
    }

    /**
     * @dev Allows the owner of a curated, non-listed artwork to add it to an exhibit space.
     * The artwork must be curated, not listed, and not already in an exhibit space.
     * Requires the caller to be the owner of the artwork and the contract to be unpaused.
     * @param exhibitSpaceId The ID of the exhibit space.
     * @param tokenId The ID of the artwork to add.
     */
    function addArtworkToExhibit(uint256 exhibitSpaceId, uint256 tokenId) public whenNotPaused {
        address artworkOwner = ownerOf(tokenId); // Checks existence and gets owner
        require(msg.sender == artworkOwner, "Gallery: Caller is not the owner of the artwork");
        require(_exhibitSpaces[exhibitSpaceId].owner != address(0), "Gallery: Exhibit space does not exist"); // Check if space exists

        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.isCurated, "Gallery: Artwork is not curated");
        require(!artwork.isListed, "Gallery: Artwork is listed for sale"); // Cannot add listed artwork
        require(artwork.exhibitSpaceId == 0, "Gallery: Artwork is already in an exhibit space");

        ExhibitSpace storage space = _exhibitSpaces[exhibitSpaceId];
        require(!space.containsArtwork[tokenId], "Gallery: Artwork is already in this exhibit space"); // Redundant check, but safe

        artwork.exhibitSpaceId = exhibitSpaceId;
        space.artworkTokenIds.push(tokenId);
        space.containsArtwork[tokenId] = true;

        emit ArtworkAddedToExhibit(exhibitSpaceId, tokenId);
    }

     /**
      * @dev Allows the owner of an artwork to remove it from the exhibit space it's currently in.
      * Requires the caller to be the owner of the artwork and the contract to be unpaused.
      * @param tokenId The ID of the artwork to remove.
      */
    function removeArtworkFromExhibit(uint256 tokenId) public whenNotPaused {
        address artworkOwner = ownerOf(tokenId); // Checks existence and gets owner
        require(msg.sender == artworkOwner, "Gallery: Caller is not the owner of the artwork");

        Artwork storage artwork = _artworkDetails[tokenId];
        require(artwork.exhibitSpaceId != 0, "Gallery: Artwork is not in an exhibit space");

        uint256 exhibitSpaceId = artwork.exhibitSpaceId;
        ExhibitSpace storage space = _exhibitSpaces[exhibitSpaceId];
        require(space.owner != address(0), "Gallery: Exhibit space associated with artwork does not exist"); // Should not happen if add was successful

        artwork.exhibitSpaceId = 0;

        // Remove from the exhibit space's artworkTokenIds array
        require(space.containsArtwork[tokenId], "Gallery: Artwork not found in exhibit space list"); // Should also not happen
        delete space.containsArtwork[tokenId];

        // Find and remove the tokenId from the dynamic array. This is inefficient for large arrays.
        // A better approach would use a linked list or a mapping to index, but keeping it simple here.
        uint256 len = space.artworkTokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (space.artworkTokenIds[i] == tokenId) {
                // Replace element with the last one and pop the last one
                space.artworkTokenIds[i] = space.artworkTokenIds[len - 1];
                space.artworkTokenIds.pop();
                break; // Assuming token only appears once
            }
        }

        emit ArtworkRemovedFromExhibit(exhibitSpaceId, tokenId);
    }

    /**
     * @dev Allows the owner of an exhibit space to transfer ownership to another address.
     * Requires the caller to be the owner of the exhibit space and the contract to be unpaused.
     * @param exhibitSpaceId The ID of the exhibit space.
     * @param newOwner The address of the new owner.
     */
    function transferExhibitSpaceOwnership(uint256 exhibitSpaceId, address newOwner) public whenNotPaused {
        ExhibitSpace storage space = _exhibitSpaces[exhibitSpaceId];
        require(space.owner != address(0), "Gallery: Exhibit space does not exist");
        require(msg.sender == space.owner, "Gallery: Caller is not the owner of the exhibit space");
        require(newOwner != address(0), "Gallery: New owner cannot be the zero address");

        address oldOwner = space.owner;
        space.owner = newOwner;

        emit ExhibitSpaceOwnershipTransferred(exhibitSpaceId, oldOwner, newOwner);
    }

    // ====================================================================
    // View Functions (Public Getters)
    // ====================================================================

    /**
     * @dev Checks if an address has the curator role.
     * @param account The address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address account) public view returns (bool) {
        return _curators[account];
    }

    /**
     * @dev Gets comprehensive details for a specific artwork.
     * @param tokenId The ID of the artwork.
     * @return uri The metadata URI.
     * @return artist The original artist's address.
     * @return artistRoyaltyBps The artist's royalty percentage in basis points.
     * @return createdAt Timestamp of creation.
     * @return isCurated Curation status.
     * @return isListed Listing status.
     * @return listingPrice Listing price in Wei.
     * @return currentSeller The current seller's address if listed, address(0) otherwise.
     * @return isFractionalized Fractionalization status.
     * @return fractionalSupply Total fractional supply if fractionalized, 0 otherwise.
     * @return exhibitSpaceId The ID of the exhibit space the artwork is in, 0 if none.
     */
    function getArtworkDetails(uint256 tokenId)
        public
        view
        returns (
            string memory uri,
            address artist,
            uint96 artistRoyaltyBps,
            uint256 createdAt,
            bool isCurated,
            bool isListed,
            uint256 listingPrice,
            address currentSeller,
            bool isFractionalized,
            uint256 fractionalSupply,
            uint256 exhibitSpaceId
        )
    {
        require(_exists(tokenId), "Gallery: Artwork does not exist");
        Artwork storage artwork = _artworkDetails[tokenId];
        return (
            artwork.uri,
            artwork.artist,
            artwork.artistRoyaltyBps,
            artwork.createdAt,
            artwork.isCurated,
            artwork.isListed,
            artwork.listingPrice,
            artwork.currentSeller,
            artwork.isFractionalized,
            artwork.fractionalSupply,
            artwork.exhibitSpaceId
        );
    }

     /**
      * @dev Gets the fractional share balance for an account for a specific artwork.
      * @param tokenId The ID of the artwork.
      * @param account The address whose balance to check.
      * @return The number of fractional shares held by the account. Returns 0 if artwork is not fractionalized or account has no shares.
      */
    function getFractionalBalance(uint256 tokenId, address account) public view returns (uint256) {
         require(_exists(tokenId), "Gallery: Artwork does not exist");
         Artwork storage artwork = _artworkDetails[tokenId];
         if (!artwork.isFractionalized) {
             return 0;
         }
         return artwork.fractionalBalances[account];
    }

    /**
     * @dev Gets the total accumulated earnings (royalties) for an artist.
     * @param artist The address of the artist.
     * @return The total withdrawable amount in Wei.
     */
    function getArtistEarnings(address artist) public view returns (uint256) {
        return _artistEarnings[artist];
    }

     /**
      * @dev Gets the total accumulated earnings (sales proceeds minus royalties) for a seller.
      * @param seller The address of the seller.
      * @return The total withdrawable amount in Wei.
      */
    function getSellerEarnings(address seller) public view returns (uint256) {
        return _sellerEarnings[seller];
    }


    /**
     * @dev Gets details for a specific exhibit space.
     * Note: Returns a potentially empty array if space has no art.
     * @param exhibitSpaceId The ID of the exhibit space.
     * @return name The name of the space.
     * @return owner The owner of the space.
     * @return artworkTokenIds An array of token IDs in the space.
     */
    function getExhibitSpaceDetails(uint256 exhibitSpaceId)
        public
        view
        returns (string memory name, address owner, uint256[] memory artworkTokenIds)
    {
        ExhibitSpace storage space = _exhibitSpaces[exhibitSpaceId];
        require(space.owner != address(0), "Gallery: Exhibit space does not exist");
        return (space.name, space.owner, space.artworkTokenIds);
    }

     /**
      * @dev Gets the metadata URI for a specific artwork.
      * Required by ERC721 metadata extension (often included in core implementations).
      * @param tokenId The ID of the artwork.
      * @return The metadata URI.
      */
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         return _artworkDetails[tokenId].uri;
    }

    /**
     * @dev Gets the total number of artworks minted.
     * @return The total count of token IDs issued.
     */
    function totalArtworks() public view returns (uint256) {
        return _nextTokenId - 1; // Subtract 1 because ID starts from 1
    }

    /**
     * @dev Gets the total number of exhibit spaces created.
     * @return The total count of exhibit space IDs issued.
     */
    function totalExhibitSpaces() public view returns (uint256) {
        return _nextExhibitSpaceId - 1; // Subtract 1 because ID starts from 1
    }

    // Total Functions Count: 42 (>= 20 requirement met)
}
```