Okay, here is a Solidity smart contract featuring a Decentralized AI-Collaborative Art Marketplace. It incorporates several interesting and advanced concepts like:

1.  **Collaborative Art Creation:** Artists can initiate art pieces and invite other artists to collaborate.
2.  **AI Contribution Tracking:** The contract records metadata related to AI suggestions or contributions used in the art creation process (AI processing happens off-chain, but its *use* is recorded on-chain).
3.  **Dynamic Metadata:** The NFT metadata URI can be updated based on collaboration progress or accepted AI suggestions.
4.  **Flexible Royalty Splits:** Artists and collaborators can define custom royalty percentages that are enforced by the marketplace.
5.  **Dual Marketplace Listings:** NFTs can be listed for full ownership transfer (sale) or for acquiring a specific usage license.
6.  **ERC2981 Royalties:** Standard compliant royalties are supported.
7.  **ERC721 Enumerable:** Allows iterating through tokens (useful for marketplace UIs).
8.  **State Management:** Tracks the lifecycle of an art piece from draft to minted and listed.
9.  **Role-Based Actions:** Different actions are restricted based on whether a user is the primary artist, a collaborator, or the contract owner.

This contract aims to be creative by blending artistic workflow elements (collaboration, AI tools) with blockchain functionalities (NFTs, royalties, marketplace listings, state tracking). It's more than just a standard NFT minting or marketplace contract.

---

## Contract Outline: Decentralized AI-Collaborative Art Marketplace

*   **Purpose:** A platform for creating, collaborating on, and trading unique digital art NFTs, with built-in features for tracking AI assistance and offering flexible licensing.
*   **Inheritance:** ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard.
*   **State Variables:** Stores data about art pieces, collaborations, AI suggestions, listings, earnings, royalties, and marketplace settings.
*   **Structs:**
    *   `ArtPiece`: Details about a piece in creation/finalized state.
    *   `CollaborationInvite`: Tracks invitation state.
    *   `AISuggestion`: Records details of an AI contribution.
    *   `RoyaltyConfig`: Defines a single recipient and percentage for royalties.
    *   `Listing`: Details about an active marketplace listing (sale or license).
*   **Enums:**
    *   `ArtPieceState`: Draft, Finalized, Minted.
    *   `CollaborationState`: Pending, Accepted, Rejected.
    *   `ListingType`: Sale, License.
*   **Events:** Signify key actions like creation, collaboration updates, finalization, minting, listing, purchase, withdrawal, etc.
*   **Functions (categorized):**
    *   **Art Piece Creation & Collaboration:** Create draft, invite/manage collaborators, add contributions, add AI suggestions, finalize.
    *   **NFT Minting & Royalties:** Mint the finalized piece, set royalty configurations.
    *   **Marketplace:** List for sale, list for license, buy NFT, acquire license, cancel listing, withdraw funds/royalties.
    *   **NFT Management:** Update metadata URI, standard ERC721 transfers (with marketplace checks).
    *   **Query Functions:** Retrieve details about art pieces, collaborations, AI suggestions, listings, earnings, royalties.
    *   **Admin Functions:** Set marketplace fee, withdraw marketplace fees, manage contract pause state, feature art.
    *   **Standard ERC721/ERC2981:** `name`, `symbol`, `tokenURI`, `ownerOf`, `balanceOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `supportsInterface`, `royaltyInfo`.

---

## Function Summary:

1.  `constructor(string memory name_, string memory symbol_, address marketplaceFeeRecipient_)`: Initializes the contract, ERC721, and Ownable. Sets the initial marketplace fee recipient.
2.  `createArtPiece(string memory title, string memory description, string memory initialMetadataUri)`: Creates a new art piece draft, setting the caller as the primary artist.
3.  `inviteCollaborator(uint256 pieceId, address collaborator)`: Allows the primary artist to invite another address to collaborate on a draft piece.
4.  `acceptCollaborationInvite(uint256 pieceId)`: Allows an invited collaborator to accept the invitation.
5.  `rejectCollaborationInvite(uint256 pieceId)`: Allows an invited collaborator to reject the invitation.
6.  `submitContributionMetadata(uint256 pieceId, string memory contributionUri, string memory description)`: Allows primary artist or accepted collaborators to record metadata about their contribution.
7.  `addAISuggestion(uint256 pieceId, string memory suggestionUri, string memory description)`: Allows primary artist or accepted collaborators to record metadata about an AI suggestion used.
8.  `finalizeArtPiece(uint256 pieceId)`: Allows the primary artist to finalize the art piece draft, locking collaborators and contributions.
9.  `mintNFT(uint256 pieceId)`: Allows the primary artist to mint the ERC721 token for a finalized art piece. Increases `_nextTokenId`.
10. `setRoyalties(uint256 tokenId, RoyaltyConfig[] memory configs)`: Allows the primary artist (initial owner) to define royalty split percentages for the minted NFT. Must sum to 10000 (100%).
11. `listForSale(uint256 tokenId, uint256 price)`: Allows the NFT owner to list it for sale on the marketplace.
12. `listForLicense(uint256 tokenId, uint256 fee, string memory licenseDetailsUri)`: Allows the NFT owner to list it for licensing, defining a fee and linking to off-chain license terms.
13. `cancelListing(uint256 tokenId)`: Allows the seller/licensor to cancel an active listing.
14. `buyNFT(uint256 tokenId)`: Allows a buyer to purchase the full ownership of an NFT listed for sale. Transfers ETH and NFT ownership.
15. `acquireLicense(uint256 tokenId)`: Allows a user to acquire a license for an NFT listed for licensing. Transfers ETH to licensor.
16. `withdrawFunds()`: Allows users with accumulated marketplace earnings (from sales/licenses) to withdraw them.
17. `claimRoyalties(uint256 tokenId)`: Allows royalty recipients to claim their share of royalties collected for a specific token.
18. `updateMetadataUri(uint256 tokenId, string memory newUri)`: Allows the NFT owner to update the token's metadata URI (enabling dynamic NFTs).
19. `featureArtPiece(uint256 tokenId, bool featured)`: (Admin function) Marks an art piece as featured. (Simple state toggle for potential UI use).
20. `setMarketplaceFee(uint256 feeBasisPoints)`: (Admin function) Sets the marketplace fee percentage (in basis points).
21. `withdrawMarketplaceFees()`: (Admin function) Allows the marketplace fee recipient to withdraw collected fees.
22. `getArtPieceDetails(uint256 pieceId)`: Returns details of an art piece draft/finalized state.
23. `getCollaborationDetails(uint256 pieceId, address collaborator)`: Returns the collaboration state for a specific piece and collaborator.
24. `getAISuggestions(uint256 pieceId)`: Returns the list of AI suggestions recorded for a piece.
25. `getListingDetails(uint256 tokenId)`: Returns details of an active marketplace listing for an NFT.
26. `getUserEarnings(address user)`: Returns the total pending marketplace earnings for a user.
27. `getUserRoyalties(address user, uint256 tokenId)`: Returns the pending royalty amount for a user for a specific token.
28. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: ERC2981 standard function to get royalty distribution for a sale price.
29. `supportsInterface(bytes4 interfaceId)`: ERC165 standard function to indicate supported interfaces (ERC721, ERC721Enumerable, ERC2981).
30. **Inherited/Overridden ERC721 Functions:** `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `tokenURI`, `totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol"; // Added Pausable for safety
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // Explicitly import IERC2981

// Note: OpenZeppelin's ERC721 natively implements ERC165 and ERC721 metadata/enumerable.
// ERC2981 (Royalties) needs to be implemented separately or inherited from an extension.
// We'll implement ERC2981 royaltyInfo and supportsInterface.

/**
 * @title Decentralized AI-Collaborative Art Marketplace
 * @dev A smart contract for creating, collaborating on, and trading unique digital art NFTs
 *      with features for tracking AI assistance and offering flexible listing types (sale/license).
 *
 * Outline:
 * - Purpose: Facilitate collaborative digital art creation, AI contribution tracking, dynamic NFTs,
 *            flexible royalties, and a marketplace with sale and licensing options.
 * - Inheritance: ERC721Enumerable, ERC721Pausable, Ownable, ReentrancyGuard. Implements IERC2981.
 * - State Variables: Store art piece data, collaboration states, AI suggestions, listings, earnings, royalties.
 * - Structs: ArtPiece, CollaborationInvite, AISuggestion, RoyaltyConfig, Listing.
 * - Enums: ArtPieceState, CollaborationState, ListingType.
 * - Events: Track key lifecycle and marketplace actions.
 * - Functions: Cover creation, collaboration, minting, royalties, marketplace, admin, and queries (>20 custom functions).
 */
contract DecentralizedAIArtMarketplace is ERC721Enumerable, ERC721Pausable, Ownable, ReentrancyGuard, IERC2981 {

    using Strings for uint256;

    // --- Enums ---

    enum ArtPieceState { Draft, Finalized, Minted }
    enum CollaborationState { Pending, Accepted, Rejected }
    enum ListingType { Sale, License }

    // --- Structs ---

    struct ArtPiece {
        uint256 id; // Same as pieceId
        address primaryArtist;
        string title;
        string description;
        uint256 creationTimestamp;
        uint256 finalizationTimestamp;
        string currentMetadataUri; // IPFS or similar link to metadata JSON
        ArtPieceState state;
        uint256 tokenId; // 0 if not yet minted
        bool isFeatured; // For admin to highlight art
    }

    struct CollaborationInvite {
        address inviter;
        uint256 inviteTimestamp;
        CollaborationState state;
        string contributionUri; // URI to collaborator's off-chain contribution
        string contributionDescription;
    }

    struct AISuggestion {
        address submitter; // Address who recorded using the suggestion
        uint256 timestamp;
        string suggestionUri; // URI to AI output/details
        string description;
    }

    struct RoyaltyConfig {
        address recipient;
        uint96 percentageBasisPoints; // Percentage in basis points (e.g., 500 for 5%)
    }

    struct Listing {
        uint256 tokenId;
        address sellerOrLicensor;
        ListingType listingType;
        uint256 priceOrFee; // Price for Sale, Fee for License
        uint256 listingTimestamp;
        bool active;
        string licenseDetailsUri; // URI to off-chain license terms (for License type)
    }

    // --- State Variables ---

    uint256 private _nextPieceId = 1;
    uint256 private _nextTokenId = 0; // Token IDs start from 1 upon first mint

    // Mapping pieceId to ArtPiece details
    mapping(uint256 => ArtPiece) public artPieces;
    // Mapping pieceId => collaborator address => CollaborationInvite details
    mapping(uint256 => mapping(address => CollaborationInvite)) public collaborationInvites;
    // Mapping pieceId => array of AISuggestions
    mapping(uint256 => AISuggestion[]) public aiSuggestions;
    // Mapping tokenId => array of RoyaltyConfig
    mapping(uint256 => RoyaltyConfig[]) private _royaltyConfigs;
    // Mapping tokenId => Listing details
    mapping(uint256 => Listing) public listings;

    // Mapping user address => accumulated earnings from sales/licenses
    mapping(address => uint256) private _userEarnings;
    // Mapping user address => tokenId => accumulated royalties
    mapping(address => mapping(uint256 => uint256)) private _userRoyalties;
    // Total marketplace fees collected
    uint256 private _totalMarketplaceFees;

    address public marketplaceFeeRecipient;
    uint256 public marketplaceFeeBasisPoints = 250; // 2.5% default fee

    // Mapping pieceId => address => isAcceptedCollaborator
    mapping(uint256 => mapping(address => bool)) private _isAcceptedCollaborator;

    // --- Events ---

    event ArtPieceCreated(uint256 indexed pieceId, address indexed primaryArtist, string title);
    event CollaborationInviteSent(uint256 indexed pieceId, address indexed inviter, address indexed invited);
    event CollaborationInviteAccepted(uint256 indexed pieceId, address indexed collaborator);
    event CollaborationInviteRejected(uint256 indexed pieceId, address indexed collaborator);
    event ContributionMetadataSubmitted(uint256 indexed pieceId, address indexed submitter, string uri, string description);
    event AISuggestionAdded(uint256 indexed pieceId, address indexed submitter, string uri, string description);
    event ArtPieceFinalized(uint256 indexed pieceId, address indexed primaryArtist);
    event NFTMinted(uint256 indexed pieceId, uint256 indexed tokenId, address indexed owner);
    event RoyaltiesSet(uint256 indexed tokenId, RoyaltyConfig[] configs);
    event ArtPieceFeatured(uint256 indexed tokenId, bool featured);

    event ListingCreated(uint256 indexed tokenId, ListingType indexed listingType, uint256 priceOrFee, address indexed sellerOrLicensor);
    event ListingCancelled(uint256 indexed tokenId);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event LicenseAcquired(uint256 indexed tokenId, address indexed licensee, address indexed licensor, uint256 fee);

    event EarningsWithdrawn(address indexed user, uint256 amount);
    event RoyaltiesClaimed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event MarketplaceFeesWithdrawn(address indexed recipient, uint256 amount);
    event MetadataUriUpdated(uint256 indexed tokenId, string newUri);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address marketplaceFeeRecipient_)
        ERC721(name_, symbol_)
        Ownable(msg.sender) // Deployer is the initial owner
    {
        require(marketplaceFeeRecipient_ != address(0), "Fee recipient cannot be zero address");
        marketplaceFeeRecipient = marketplaceFeeRecipient_;
    }

    // --- Pausability ---
    // The pause/unpause functionality from ERC721Pausable is inherited.
    // Only the contract owner can pause/unpause.
    // When paused, core marketplace functions like minting, transfers, listings, purchases are blocked.
    // Withdrawals and claims might still be allowed depending on how `_beforeTokenTransfer` and `_afterTokenTransfer` handle state.
    // Let's override _beforeTokenTransfer to ensure crucial marketplace actions stop.

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Override _beforeTokenTransfer to check for paused state, as required by ERC721Pausable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Pausable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Add marketplace-specific checks here if needed before transfer,
        // e.g., preventing transfer of a listed token via standard transfer methods.
        // The `buyNFT` function handles the transfer for sales.
        // We should disallow standard transfer of a token if it's currently listed.
        Listing storage listing = listings[tokenId];
        require(!listing.active || from == address(this), "Token is listed on the marketplace"); // Allow transfer *from* the contract during a sale

        // The `whenNotPaused` modifier is NOT used here directly.
        // ERC721Pausable's _beforeTokenTransfer already includes the check: `require(!paused(), "Pausable: paused");`
    }

    // --- Art Piece Creation & Collaboration Functions (>= 8) ---

    /**
     * @dev Creates a new art piece in Draft state.
     * @param title The title of the art piece.
     * @param description A description of the art piece.
     * @param initialMetadataUri URI pointing to the initial metadata JSON (IPFS).
     */
    function createArtPiece(string memory title, string memory description, string memory initialMetadataUri)
        public
        whenNotPaused
        returns (uint256 pieceId)
    {
        pieceId = _nextPieceId++;
        artPieces[pieceId] = ArtPiece({
            id: pieceId,
            primaryArtist: msg.sender,
            title: title,
            description: description,
            creationTimestamp: block.timestamp,
            finalizationTimestamp: 0,
            currentMetadataUri: initialMetadataUri,
            state: ArtPieceState.Draft,
            tokenId: 0, // Not minted yet
            isFeatured: false
        });

        // Primary artist is implicitly a collaborator
        _isAcceptedCollaborator[pieceId][msg.sender] = true;

        emit ArtPieceCreated(pieceId, msg.sender, title);
    }

    /**
     * @dev Allows the primary artist to invite another address to collaborate.
     * @param pieceId The ID of the art piece.
     * @param collaborator The address to invite.
     */
    function inviteCollaborator(uint256 pieceId, address collaborator)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.primaryArtist == msg.sender, "Only primary artist can invite");
        require(piece.state == ArtPieceState.Draft, "Piece must be in Draft state");
        require(collaborator != address(0), "Cannot invite zero address");
        require(collaborator != piece.primaryArtist, "Cannot invite primary artist");

        CollaborationInvite storage invite = collaborationInvites[pieceId][collaborator];
        require(invite.state == CollaborationState.Pending || invite.inviteTimestamp == 0, "Collaborator already invited or status not pending");

        invite.inviter = msg.sender;
        invite.inviteTimestamp = block.timestamp;
        invite.state = CollaborationState.Pending;

        emit CollaborationInviteSent(pieceId, msg.sender, collaborator);
    }

    /**
     * @dev Allows an invited address to accept a collaboration invitation.
     * @param pieceId The ID of the art piece.
     */
    function acceptCollaborationInvite(uint256 pieceId)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.state == ArtPieceState.Draft, "Piece must be in Draft state");

        CollaborationInvite storage invite = collaborationInvites[pieceId][msg.sender];
        require(invite.state == CollaborationState.Pending, "No pending invitation for this user");

        invite.state = CollaborationState.Accepted;
        _isAcceptedCollaborator[pieceId][msg.sender] = true;

        emit CollaborationInviteAccepted(pieceId, msg.sender);
    }

    /**
     * @dev Allows an invited address to reject a collaboration invitation.
     * @param pieceId The ID of the art piece.
     */
    function rejectCollaborationInvite(uint256 pieceId)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.state == ArtPieceState.Draft, "Piece must be in Draft state");

        CollaborationInvite storage invite = collaborationInvites[pieceId][msg.sender];
        require(invite.state == CollaborationState.Pending, "No pending invitation for this user");

        invite.state = CollaborationState.Rejected;

        emit CollaborationInviteRejected(pieceId, msg.sender);
    }

    /**
     * @dev Allows an accepted collaborator or primary artist to record their contribution metadata.
     *      The actual art contribution happens off-chain.
     * @param pieceId The ID of the art piece.
     * @param contributionUri URI pointing to the off-chain contribution details.
     * @param description A description of the contribution.
     */
    function submitContributionMetadata(uint256 pieceId, string memory contributionUri, string memory description)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.state == ArtPieceState.Draft || piece.state == ArtPieceState.Finalized, "Piece must be in Draft or Finalized state");
        require(_isAcceptedCollaborator[pieceId][msg.sender], "Only accepted collaborators can submit contributions");

        // Note: This simply records *a* contribution. More complex logic might track versions or require consensus.
        // For simplicity, we'll just update the latest contribution URI/description for this collaborator.
        // This could be extended to store an array of contributions per collaborator.
        CollaborationInvite storage invite = collaborationInvites[pieceId][msg.sender];
        invite.contributionUri = contributionUri;
        invite.contributionDescription = description;

        emit ContributionMetadataSubmitted(pieceId, msg.sender, contributionUri, description);
    }

    /**
     * @dev Allows an accepted collaborator or primary artist to record metadata about an AI suggestion used.
     *      The actual AI processing happens off-chain.
     * @param pieceId The ID of the art piece.
     * @param suggestionUri URI pointing to the AI output or details.
     * @param description A description of the AI suggestion/how it was used.
     */
    function addAISuggestion(uint256 pieceId, string memory suggestionUri, string memory description)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.state == ArtPieceState.Draft || piece.state == ArtPieceState.Finalized, "Piece must be in Draft or Finalized state");
        require(_isAcceptedCollaborator[pieceId][msg.sender], "Only accepted collaborators can add AI suggestions");

        aiSuggestions[pieceId].push(AISuggestion({
            submitter: msg.sender,
            timestamp: block.timestamp,
            suggestionUri: suggestionUri,
            description: description
        }));

        emit AISuggestionAdded(pieceId, msg.sender, suggestionUri, description);
    }

    /**
     * @dev Allows the primary artist to finalize the art piece, locking collaborators and state before minting.
     * @param pieceId The ID of the art piece.
     */
    function finalizeArtPiece(uint256 pieceId)
        public
        whenNotPaused
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.primaryArtist == msg.sender, "Only primary artist can finalize");
        require(piece.state == ArtPieceState.Draft, "Piece must be in Draft state");

        piece.state = ArtPieceState.Finalized;
        piece.finalizationTimestamp = block.timestamp;

        // Note: At this point, no more *new* invites can be accepted.
        // Submitted contributions and AI suggestions *could* technically still be added
        // if we allowed it in the check, but finalization implies the creative process is mostly done.
        // Current logic allows adding contributions/suggestions up to Finalized state.

        emit ArtPieceFinalized(pieceId, msg.sender);
    }

    // --- NFT Minting & Royalties Functions (>= 2) ---

    /**
     * @dev Mints the NFT for a finalized art piece.
     * @param pieceId The ID of the art piece to mint.
     */
    function mintNFT(uint256 pieceId)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        ArtPiece storage piece = artPieces[pieceId];
        require(piece.primaryArtist == msg.sender, "Only primary artist can mint");
        require(piece.state == ArtPieceState.Finalized, "Piece must be in Finalized state");
        require(piece.tokenId == 0, "NFT already minted for this piece");

        tokenId = ++_nextTokenId;
        _safeMint(msg.sender, tokenId); // Mints to the primary artist
        piece.state = ArtPieceState.Minted;
        piece.tokenId = tokenId;

        // The tokenURI is initially set to the piece's currentMetadataUri
        // _setTokenURI(tokenId, piece.currentMetadataUri); // ERC721Enumerable handles tokenURI via _baseURI or _tokenURI

        emit NFTMinted(pieceId, tokenId, msg.sender);
    }

     /**
     * @dev Sets the royalty configuration for a minted NFT. Can only be called by the initial minter (primary artist).
     *      Must be called after minting and before the first transfer away from the primary artist.
     * @param tokenId The ID of the token.
     * @param configs An array of RoyaltyConfig structs defining recipients and percentages.
     */
    function setRoyalties(uint256 tokenId, RoyaltyConfig[] memory configs)
        public
        whenNotPaused
    {
        ArtPiece storage piece;
        bool found = false;
        // Find the pieceId associated with the tokenId
        for (uint256 i = 1; i < _nextPieceId; i++) {
             if (artPieces[i].tokenId == tokenId) {
                 piece = artPieces[i];
                 found = true;
                 break;
             }
        }
        require(found, "Invalid tokenId");
        // Royalties should ideally be set by the original minter, who is the primary artist
        require(_tokenOwners[tokenId] == piece.primaryArtist, "Only initial minter can set royalties");
        // Royalties should be set before the first transfer away from the minter
        require(_tokenOwners[tokenId] != address(0), "Token not minted");
        require(_royaltyConfigs[tokenId].length == 0, "Royalties already set for this token");

        uint96 totalPercentage = 0;
        for (uint i = 0; i < configs.length; i++) {
            require(configs[i].recipient != address(0), "Royalty recipient cannot be zero address");
            totalPercentage += configs[i].percentageBasisPoints;
        }
        // Max total royalty is 100% (10000 basis points)
        require(totalPercentage <= 10000, "Total royalty percentage exceeds 100%");

        _royaltyConfigs[tokenId] = configs;

        emit RoyaltiesSet(tokenId, configs);
    }

    // Implement ERC2981 royaltyInfo
    /**
     * @dev Returns the royalty payment information for a given token and sale price.
     *      Required function for ERC2981.
     * @param tokenId The NFT token ID.
     * @param salePrice The price the NFT is selling for.
     * @return receiver The address of the royalty receiver.
     * @return royaltyAmount The amount of royalty payment due.
     * Note: This standard only supports a single recipient. We'll return the first recipient
     * and the total royalty amount to *that* recipient based on our configured splits.
     * A more advanced implementation might aggregate royalties internally and distribute.
     * For compatibility, we'll return the *primary* royalty recipient's share.
     * A frontend would need to call getRoyaltyConfigs to see the full split.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        override
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyConfig[] memory configs = _royaltyConfigs[tokenId];
        uint96 totalRoyaltyPercentage = 0;
         for (uint i = 0; i < configs.length; i++) {
             totalRoyaltyPercentage += configs[i].percentageBasisPoints;
         }

        if (totalRoyaltyPercentage > 0 && configs.length > 0) {
            // ERC2981 expects a single recipient. We'll return the first recipient's share.
            // In a real-world complex split, this might need a different approach or just signal *if* royalties exist.
            // Let's return the *total* royalty amount calculated based on the sum of percentages,
            // and maybe the primary artist or a designated recipient as the 'receiver'.
            // A better interpretation for a multi-recipient system is to return the total sum and
            // a recipient that can be used to query the full split (like the contract itself).
            // Let's return the total royalty amount split among recipients and use the contract address as receiver.
             uint256 totalRoyaltyAmount = (salePrice * totalRoyaltyPercentage) / 10000;
             return (address(this), totalRoyaltyAmount);
        }

        return (address(0), 0);
    }


    // --- Marketplace Functions (>= 6) ---

    /**
     * @dev Allows the owner of a token to list it for sale.
     * @param tokenId The ID of the token to list.
     * @param price The price in native currency (ETH) for the sale.
     */
    function listForSale(uint256 tokenId, uint256 price)
        public
        whenNotPaused
        nonReentrant
    {
        require(_exists(tokenId), "Token does not exist");
        require(_tokenOwners[tokenId] == msg.sender, "Only token owner can list");
        require(price > 0, "Price must be greater than zero");
        require(!listings[tokenId].active, "Token is already listed");

        listings[tokenId] = Listing({
            tokenId: tokenId,
            sellerOrLicensor: msg.sender,
            listingType: ListingType.Sale,
            priceOrFee: price,
            listingTimestamp: block.timestamp,
            active: true,
            licenseDetailsUri: "" // Not applicable for sale
        });

        // Approve the marketplace contract to transfer the token
        // If the token is already approved for the contract, this is redundant but safe.
        _approve(address(this), tokenId);

        emit ListingCreated(tokenId, ListingType.Sale, price, msg.sender);
    }

    /**
     * @dev Allows the owner of a token to list it for licensing.
     * @param tokenId The ID of the token to list.
     * @param fee The fee in native currency (ETH) for acquiring the license.
     * @param licenseDetailsUri URI pointing to the off-chain license terms.
     */
    function listForLicense(uint256 tokenId, uint256 fee, string memory licenseDetailsUri)
        public
        whenNotPaused
        nonReentrant
    {
        require(_exists(tokenId), "Token does not exist");
        require(_tokenOwners[tokenId] == msg.sender, "Only token owner can list");
        require(fee > 0, "Fee must be greater than zero");
        require(!listings[tokenId].active, "Token is already listed");

        listings[tokenId] = Listing({
            tokenId: tokenId,
            sellerOrLicensor: msg.sender,
            listingType: ListingType.License,
            priceOrFee: fee,
            listingTimestamp: block.timestamp,
            active: true,
            licenseDetailsUri: licenseDetailsUri
        });

        // No token transfer happens for licensing, so no approval is needed.

        emit ListingCreated(tokenId, ListingType.License, fee, msg.sender);
    }

     /**
     * @dev Allows the seller/licensor to cancel an active listing.
     * @param tokenId The ID of the token with the listing to cancel.
     */
    function cancelListing(uint256 tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        Listing storage listing = listings[tokenId];
        require(listing.active, "Token is not listed");
        require(listing.sellerOrLicensor == msg.sender, "Only listing owner can cancel");

        listing.active = false;
        listing.sellerOrLicensor = address(0); // Clear details
        listing.priceOrFee = 0;
        listing.licenseDetailsUri = "";

        // Revoke approval for sale listings if necessary (safe to call even if not needed)
        if (listing.listingType == ListingType.Sale) {
             _approve(address(0), tokenId); // Clear approval from the marketplace contract
        }


        emit ListingCancelled(tokenId);
    }

    /**
     * @dev Allows a user to buy a listed NFT.
     * @param tokenId The ID of the token to buy.
     */
    function buyNFT(uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Listing storage listing = listings[tokenId];
        require(listing.active && listing.listingType == ListingType.Sale, "Token is not listed for sale");
        require(listing.sellerOrLicensor != msg.sender, "Cannot buy your own listing");
        require(msg.value >= listing.priceOrFee, "Insufficient funds");

        uint256 salePrice = listing.priceOrFee;
        address seller = listing.sellerOrLicensor;

        // Deactivate listing BEFORE transfer
        listing.active = false;
        listing.sellerOrLicensor = address(0);
        listing.priceOrFee = 0;

        // Calculate marketplace fee
        uint256 marketplaceFee = (salePrice * marketplaceFeeBasisPoints) / 10000;
        uint256 amountForSeller = salePrice - marketplaceFee;

        // Calculate royalties
        RoyaltyConfig[] memory configs = _royaltyConfigs[tokenId];
        uint256 totalRoyaltyAmount = 0;
        // Calculate total royalty amount based on configured percentages
        for(uint i = 0; i < configs.length; i++) {
            totalRoyaltyAmount += (salePrice * configs[i].percentageBasisPoints) / 10000;
        }

        uint256 amountAfterRoyalties = amountForSeller;
        if (totalRoyaltyAmount > amountForSeller) {
             // Should not happen if fee + royalty <= 100%, but handle defensively
             totalRoyaltyAmount = amountForSeller; // Cap royalties at amount available after marketplace fee
        }
        amountAfterRoyalties -= totalRoyaltyAmount;


        // Distribute earnings:
        // 1. Marketplace fee goes to fee recipient's balance
        if (marketplaceFee > 0) {
            _totalMarketplaceFees += marketplaceFee;
        }

        // 2. Royalties go to royalty recipients' balances
        for(uint i = 0; i < configs.length; i++) {
            uint256 royaltyShare = (totalRoyaltyAmount * configs[i].percentageBasisPoints) / (totalRoyaltyAmount > 0 ? totalRoyaltyPercentage(tokenId) : 10000); // Distribute total royalty amount proportionally
            _userRoyalties[configs[i].recipient][tokenId] += royaltyShare;
        }

        // 3. Remaining amount goes to seller's balance
        _userEarnings[seller] += amountAfterRoyalties;


        // Transfer the NFT ownership
        _safeTransferFrom(seller, msg.sender, tokenId);

        // Handle any excess ETH sent by the buyer
        if (msg.value > salePrice) {
            payable(msg.sender).call{value: msg.value - salePrice}("");
        }

        emit NFTBought(tokenId, msg.sender, seller, salePrice);
    }

    /**
     * @dev Allows a user to acquire a license for a listed NFT.
     * @param tokenId The ID of the token to acquire a license for.
     */
    function acquireLicense(uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        Listing storage listing = listings[tokenId];
        require(listing.active && listing.listingType == ListingType.License, "Token is not listed for license");
        require(msg.value >= listing.priceOrFee, "Insufficient funds");

        uint256 licenseFee = listing.priceOrFee;
        address licensor = listing.sellerOrLicensor;

        // Note: Licensing logic is complex and often requires off-chain agreement.
        // This contract only facilitates the payment for a license linked via URI.
        // It DOES NOT enforce license terms or track active licensees on-chain.
        // A more advanced version could potentially mint a Soulbound Token (SBT)
        // or a separate access token representing the license.

        // Calculate marketplace fee for the license fee
        uint256 marketplaceFee = (licenseFee * marketplaceFeeBasisPoints) / 10000;
        uint256 amountForLicensor = licenseFee - marketplaceFee;

        // Distribute earnings:
        // 1. Marketplace fee goes to fee recipient's balance
        if (marketplaceFee > 0) {
            _totalMarketplaceFees += marketplaceFee;
        }
        // 2. Remaining amount goes to licensor's balance
        _userEarnings[licensor] += amountForLicensor;

        // Handle any excess ETH sent by the buyer
        if (msg.value > licenseFee) {
            payable(msg.sender).call{value: msg.value - licenseFee}("");
        }

        // The listing remains active after licensing, unless the owner cancels or lists for sale.
        // This allows multiple licenses to be acquired for the same listing.

        emit LicenseAcquired(tokenId, msg.sender, licensor, licenseFee);
    }

    /**
     * @dev Allows users with accumulated earnings (from sales/licenses) to withdraw them.
     */
    function withdrawFunds()
        public
        nonReentrant
    {
        uint256 amount = _userEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        _userEarnings[msg.sender] = 0; // Reset balance BEFORE transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit EarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows royalty recipients to claim their accumulated royalties for a specific token.
     * @param tokenId The ID of the token for which to claim royalties.
     */
    function claimRoyalties(uint256 tokenId)
        public
        nonReentrant
    {
        uint256 amount = _userRoyalties[msg.sender][tokenId];
        require(amount > 0, "No royalties to claim for this token");

        _userRoyalties[msg.sender][tokenId] = 0; // Reset balance BEFORE transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Royalty claim failed");

        emit RoyaltiesClaimed(msg.sender, tokenId, amount);
    }


    // --- NFT Management Functions (>= 1) ---

    /**
     * @dev Allows the owner of an NFT to update its metadata URI.
     *      This enables dynamic NFTs where the linked metadata can change.
     * @param tokenId The ID of the token to update.
     * @param newUri The new URI pointing to the updated metadata JSON.
     */
    function updateMetadataUri(uint256 tokenId, string memory newUri)
        public
        whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");
        require(_tokenOwners[tokenId] == msg.sender, "Only token owner can update metadata");

        // Find the corresponding ArtPiece and update its metadataUri
        bool found = false;
        for (uint256 i = 1; i < _nextPieceId; i++) {
             if (artPieces[i].tokenId == tokenId) {
                 artPieces[i].currentMetadataUri = newUri;
                 found = true;
                 break;
             }
        }
        require(found, "ArtPiece not found for this tokenId");

        // If using _setTokenURI, you'd call: _setTokenURI(tokenId, newUri);
        // With ERC721Enumerable, the tokenURI is generated, so we update the source data.

        emit MetadataUriUpdated(tokenId, newUri);
    }

     /**
     * @dev Overrides ERC721Enumerable's tokenURI to fetch the URI from our ArtPiece struct.
     * @param tokenId The token ID.
     * @return The metadata URI for the token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Find the corresponding ArtPiece
        for (uint256 i = 1; i < _nextPieceId; i++) {
             if (artPieces[i].tokenId == tokenId && artPieces[i].state == ArtPieceState.Minted) {
                 return artPieces[i].currentMetadataUri;
             }
        }
        // Should not reach here if token exists and is minted, but fallback
        return super.tokenURI(tokenId); // Fallback to potential baseURI if piece not found
    }

    // Override transferFrom and safeTransferFrom to prevent direct transfers of listed tokens
    // The _beforeTokenTransfer hook handles this check.

    // --- Admin Functions (>= 3) ---

    /**
     * @dev Allows the contract owner to feature an art piece. (For UI purposes).
     * @param tokenId The ID of the token to feature.
     * @param featured Whether to feature (true) or unfeature (false).
     */
    function featureArtPiece(uint256 tokenId, bool featured)
        public
        onlyOwner
        whenNotPaused
    {
        require(_exists(tokenId), "Token does not exist");

        // Find the corresponding ArtPiece
        bool found = false;
        for (uint256 i = 1; i < _nextPieceId; i++) {
             if (artPieces[i].tokenId == tokenId && artPieces[i].state == ArtPieceState.Minted) {
                 artPieces[i].isFeatured = featured;
                 found = true;
                 break;
             }
        }
         require(found, "ArtPiece not found for this tokenId");


        emit ArtPieceFeatured(tokenId, featured);
    }

    /**
     * @dev Sets the marketplace fee percentage.
     * @param feeBasisPoints The fee percentage in basis points (100 = 1%). Max 10000 (100%).
     */
    function setMarketplaceFee(uint256 feeBasisPoints)
        public
        onlyOwner
    {
        require(feeBasisPoints <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = feeBasisPoints;
    }

    /**
     * @dev Allows the marketplace fee recipient to withdraw accumulated fees.
     */
    function withdrawMarketplaceFees()
        public
        nonReentrant
    {
        require(msg.sender == marketplaceFeeRecipient, "Only fee recipient can withdraw");
        uint256 amount = _totalMarketplaceFees;
        require(amount > 0, "No fees to withdraw");

        _totalMarketplaceFees = 0; // Reset balance BEFORE transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit MarketplaceFeesWithdrawn(msg.sender, amount);
    }

    // --- Query Functions (>= 6) ---

    /**
     * @dev Gets details of an art piece by its piece ID.
     * @param pieceId The ID of the art piece.
     * @return ArtPiece struct details.
     */
    function getArtPieceDetails(uint256 pieceId)
        public
        view
        returns (ArtPiece memory)
    {
        require(pieceId > 0 && pieceId < _nextPieceId, "Invalid pieceId");
        return artPieces[pieceId];
    }

    /**
     * @dev Gets the collaboration status for a specific piece and potential collaborator.
     * @param pieceId The ID of the art piece.
     * @param collaborator The address of the potential collaborator.
     * @return CollaborationInvite struct details.
     */
    function getCollaborationDetails(uint256 pieceId, address collaborator)
        public
        view
        returns (CollaborationInvite memory)
    {
        require(pieceId > 0 && pieceId < _nextPieceId, "Invalid pieceId");
        return collaborationInvites[pieceId][collaborator];
    }

    /**
     * @dev Checks if an address is an accepted collaborator (including primary artist).
     * @param pieceId The ID of the art piece.
     * @param collaborator The address to check.
     * @return True if the address is an accepted collaborator, false otherwise.
     */
    function isAcceptedCollaborator(uint256 pieceId, address collaborator)
        public
        view
        returns (bool)
    {
         require(pieceId > 0 && pieceId < _nextPieceId, "Invalid pieceId");
         return _isAcceptedCollaborator[pieceId][collaborator];
    }


    /**
     * @dev Gets all AI suggestions recorded for a piece.
     * @param pieceId The ID of the art piece.
     * @return An array of AISuggestion structs.
     */
    function getAISuggestions(uint256 pieceId)
        public
        view
        returns (AISuggestion[] memory)
    {
         require(pieceId > 0 && pieceId < _nextPieceId, "Invalid pieceId");
         return aiSuggestions[pieceId];
    }

    /**
     * @dev Gets the details of an active listing for a token.
     * @param tokenId The ID of the token.
     * @return Listing struct details.
     */
    function getListingDetails(uint256 tokenId)
        public
        view
        returns (Listing memory)
    {
         require(_exists(tokenId), "Token does not exist");
         return listings[tokenId];
    }

    /**
     * @dev Gets the pending marketplace earnings for a user.
     * @param user The address of the user.
     * @return The amount of pending earnings in native currency (ETH).
     */
    function getUserEarnings(address user)
        public
        view
        returns (uint256)
    {
        return _userEarnings[user];
    }

    /**
     * @dev Gets the pending royalty amount for a user for a specific token.
     * @param user The address of the user.
     * @param tokenId The ID of the token.
     * @return The amount of pending royalties in native currency (ETH).
     */
    function getUserRoyalties(address user, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(tokenId), "Token does not exist");
        return _userRoyalties[user][tokenId];
    }

    /**
     * @dev Gets the royalty configuration for a token.
     * @param tokenId The ID of the token.
     * @return An array of RoyaltyConfig structs.
     */
    function getRoyaltyConfigs(uint256 tokenId)
        public
        view
        returns (RoyaltyConfig[] memory)
    {
         require(_exists(tokenId), "Token does not exist");
         return _royaltyConfigs[tokenId];
    }

     /**
     * @dev Calculates the total royalty percentage for a token in basis points.
     * @param tokenId The ID of the token.
     * @return Total percentage in basis points.
     */
    function totalRoyaltyPercentage(uint256 tokenId)
        public
        view
        returns (uint96)
    {
         require(_exists(tokenId), "Token does not exist");
         RoyaltyConfig[] memory configs = _royaltyConfigs[tokenId];
         uint96 total = 0;
         for(uint i = 0; i < configs.length; i++) {
             total += configs[i].percentageBasisPoints;
         }
         return total;
    }

    // --- Standard ERC721/ERC2981 Overrides ---
    // Most are handled by inheritance, but supportsInterface needs custom implementation.

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Pausable, IERC2981)
        returns (bool)
    {
        // Add ERC2981 interface ID (0x2a55205a)
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // The following ERC721 functions are inherited and work with the Pausable override:
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
    // - transferFrom(address from, address to, uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - getApproved(uint256 tokenId)
    // - isApprovedForAll(address owner, address operator)

    // ERC721Enumerable functions:
    // - totalSupply()
    // - tokenByIndex(uint256 index)
    // - tokenOfOwnerByIndex(address owner, uint256 index)

    // ERC721Pausable functions:
    // - paused()

    // Ownable functions:
    // - owner()
    // - renounceOwnership()
    // - transferOwnership(address newOwner)
}
```