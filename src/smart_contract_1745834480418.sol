Okay, let's create a smart contract for a *Decentralized Art Gallery* that incorporates several advanced and creative concepts: community curation, dynamic NFT metadata, potential fractionalization initiation, and on-chain gallery room displays.

We will use concepts like ERC-721 for the art pieces, a curation process involving voting, on-chain storage of metadata attributes that influence dynamism, a simple marketplace mechanism, and a conceptual framework for display in user-managed "gallery rooms".

**Outline and Function Summary:**

**Contract Name:** `DecentralizedArtGallery`

**Description:**
A comprehensive smart contract platform for a decentralized art gallery. It allows creators to submit artwork for community curation, mint successful submissions as unique ERC-721 NFTs, facilitates direct sales, supports potential future fractionalization of owned pieces, allows owners to display their art in conceptual on-chain "gallery rooms", and incorporates dynamic metadata influenced by curation scores and display activity. The gallery parameters are managed via a basic role-based system.

**Key Concepts:**
1.  **ERC-721 NFTs:** Standard representation of art pieces.
2.  **Community Curation:** A voting system for submitted art before minting.
3.  **Dynamic Metadata:** NFT attributes (like "Status" or "Reputation") that change based on on-chain interactions (votes, display counts).
4.  **Fractionalization Initiation:** A signal/feature allowing an owner to mark an NFT for potential future fractionalization via an external protocol (the contract only initiates, not executes fractionalization).
5.  **On-chain Gallery Rooms:** A way for users to register and manage a list of their owned art pieces intended for display.
6.  **Marketplace:** Basic fixed-price listing and buying of NFTs.
7.  **Role-Based Access:** Using OpenZeppelin's `AccessControl` for managing curators and potentially governors.

**Function Summary (Target: 20+ custom/overridden functions):**

*   **Core ERC-721 (Inherited & Overridden):**
    *   `tokenURI(uint256 tokenId)`: Overridden to potentially include dynamic attributes.
    *   `supportsInterface(bytes4 interfaceId)`: Standard ERC721/ERC165.

*   **Submission & Curation:**
    *   `submitArtForCuration(string memory metadataURI)`: Allows creators to submit art (metadata hash) for review. Requires a fee.
    *   `voteForArt(uint256 submissionId, bool approve)`: Allows eligible users/roles to vote on submissions.
    *   `processCurationResults(uint256[] memory submissionIds)`: Owner/Curator processes votes for submissions, minting successful ones.
    *   `getArtSubmissionDetails(uint256 submissionId)`: View details of a pending submission.
    *   `getSubmissionVoteCount(uint256 submissionId)`: View the current vote count for a submission.
    *   `hasVoted(uint256 submissionId, address voter)`: Check if an address has already voted on a submission.
    *   `burnRejectedArtSubmissions(uint256[] memory submissionIds)`: Cleans up submissions that failed curation.

*   **Marketplace:**
    *   `listArtForSale(uint256 tokenId, uint256 price)`: Owner lists their minted NFT for sale.
    *   `cancelArtListing(uint256 tokenId)`: Owner cancels a sale listing.
    *   `buyArt(uint256 tokenId)`: Allows users to purchase a listed NFT. Handles payment distribution (seller, creator royalty, gallery fee).
    *   `getArtListing(uint256 tokenId)`: View details of an art listing.

*   **Ownership & Fractionalization:**
    *   `initiateFractionalization(uint256 tokenId)`: Owner signals intent to fractionalize an NFT (marks it on-chain).
    *   `isFractionalizationInitiated(uint256 tokenId)`: Check if fractionalization has been initiated for an NFT.
    *   `updateArtDescription(uint256 tokenId, string memory newDescription)`: Allows owner to update a non-critical part of metadata.

*   **Gallery Rooms & Display:**
    *   `setupGalleryRoom(string memory roomName)`: Register an address as having a gallery room.
    *   `addArtToGalleryRoom(uint256[] memory tokenIds)`: Owner adds their owned art to their gallery room display list.
    *   `removeArtFromGalleryRoom(uint256[] memory tokenIds)`: Owner removes art from their display list.
    *   `getGalleryRoomArt(address owner)`: View the list of token IDs displayed in an owner's room.
    *   `incrementDisplayCount(uint256 tokenId)`: Function called conceptually by a frontend/external system to track how many times art is displayed.

*   **Dynamic Metadata:**
    *   `getDynamicArtAttributes(uint256 tokenId)`: View the dynamic attributes (score, display count) of an NFT.
    *   `getBaseMetadataURI(uint256 tokenId)`: Get the original immutable metadata URI submitted.

*   **Governance & Roles (Simplified):**
    *   `grantCuratorRole(address account)`: Grant the CURATOR_ROLE.
    *   `revokeCuratorRole(address account)`: Revoke the CURATOR_ROLE.
    *   `setSubmissionFee(uint256 fee)`: Set the required fee for art submission.
    *   `setCurationThreshold(uint256 threshold)`: Set the minimum approval votes needed for curation success.
    *   `setGalleryFeeBasisPoints(uint16 basisPoints)`: Set the gallery commission percentage (in basis points).
    *   `withdrawCreatorEarnings(address creator)`: Creator withdraws their accumulated earnings.
    *   `withdrawGalleryFees()`: Owner/Admin withdraws accumulated gallery fees.

*   **Utility:**
    *   `getSubmissionFee()`: View the current submission fee.
    *   `getCurationThreshold()`: View the current curation threshold.
    *   `getGalleryFeeBasisPoints()`: View the current gallery fee percentage.
    *   `getGalleryBalance()`: View the contract's balance reserved for gallery fees.
    *   `getCreatorBalance(address creator)`: View a creator's balance of earnings.

Total Custom/Overridden Functions: ~32+ (More than 20 required).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. State Variables: Store contract settings, art data, submissions, listings, gallery rooms, balances.
// 2. Events: Signal key actions like submissions, minting, sales, votes, etc.
// 3. Modifiers: Access control (roles, ownership).
// 4. Constructor: Initialize ERC721, roles, initial parameters.
// 5. Access Control (via AccessControl.sol).
// 6. Submission & Curation Logic: Handling new art submissions, voting, processing votes, minting.
// 7. Marketplace Logic: Listing, buying, cancelling sales, fee distribution.
// 8. Fractionalization Initiation: Function to mark an NFT for future fractionalization (external).
// 9. Gallery Rooms & Display Logic: Allowing owners to curate lists of art they display, tracking display counts.
// 10. Dynamic Metadata Generation: Function to compute dynamic attributes based on on-chain data.
// 11. Parameter Management: Functions to set gallery fees, thresholds (role-restricted).
// 12. Fund Management: Withdrawals for creators and gallery owner.
// 13. View Functions: Read state variables and derived data.

// Function Summary:
// ERC721 Overrides:
// - tokenURI(uint256 tokenId): Returns the metadata URI, potentially including dynamic attributes.
// - supportsInterface(bytes4 interfaceId): Standard ERC165/ERC721/ERC721Enumerable.
//
// Submission & Curation:
// - submitArtForCuration(string memory metadataURI): Submit art hash for voting.
// - voteForArt(uint256 submissionId, bool approve): Cast a vote on a submission.
// - processCurationResults(uint256[] memory submissionIds): Process votes and mint successful art.
// - getArtSubmissionDetails(uint256 submissionId): View submission data.
// - getSubmissionVoteCount(uint256 submissionId): View current vote count.
// - hasVoted(uint256 submissionId, address voter): Check if address voted.
// - burnRejectedArtSubmissions(uint256[] memory submissionIds): Remove failed submissions.
//
// Marketplace:
// - listArtForSale(uint256 tokenId, uint256 price): List owned art for sale.
// - cancelArtListing(uint256 tokenId): Cancel an art listing.
// - buyArt(uint256 tokenId): Purchase listed art.
// - getArtListing(uint256 tokenId): View listing details.
//
// Ownership & Fractionalization:
// - initiateFractionalization(uint256 tokenId): Mark art for fractionalization.
// - isFractionalizationInitiated(uint256 tokenId): Check fractionalization status.
// - updateArtDescription(uint256 tokenId, string memory newDescription): Update art description string.
//
// Gallery Rooms & Display:
// - setupGalleryRoom(string memory roomName): Register a gallery room for an address.
// - addArtToGalleryRoom(uint256[] memory tokenIds): Add owned art to a room's display list.
// - removeArtFromGalleryRoom(uint256[] memory tokenIds): Remove art from a room's display list.
// - getGalleryRoomArt(address owner): View art in a room.
// - incrementDisplayCount(uint256 tokenId): Track art display count.
//
// Dynamic Metadata:
// - getDynamicArtAttributes(uint256 tokenId): View calculated dynamic attributes.
// - getBaseMetadataURI(uint256 tokenId): Get original submission URI.
//
// Governance & Roles:
// - grantCuratorRole(address account): Grant curator role.
// - revokeCuratorRole(address account): Revoke curator role.
// - setSubmissionFee(uint256 fee): Set art submission fee.
// - setCurationThreshold(uint256 threshold): Set votes needed to mint.
// - setGalleryFeeBasisPoints(uint16 basisPoints): Set gallery commission rate.
//
// Fund Management:
// - withdrawCreatorEarnings(address creator): Creator claims funds.
// - withdrawGalleryFees(): Admin claims gallery fees.
//
// Utility Views:
// - getSubmissionFee(): Get current submission fee.
// - getCurationThreshold(): Get current curation threshold.
// - getGalleryFeeBasisPoints(): Get current gallery fee rate.
// - getGalleryBalance(): Get contract's gallery fee balance.
// - getCreatorBalance(address creator): Get a creator's pending earnings.
// - getCurrentSubmissionId(): Get next available submission ID.
// - getTokenCreator(uint256 tokenId): Get the original creator of a minted token.


contract DecentralizedArtGallery is ERC721Enumerable, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _submissionIds;
    Counters.Counter private _tokenIds;

    // --- State Variables ---

    // Roles
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // For parameter changes

    // Gallery Parameters
    uint256 public submissionFee; // Fee required to submit art for curation
    uint256 public curationThreshold; // Minimum net approval votes needed to pass curation
    uint16 public galleryFeeBasisPoints; // Percentage of sale price as gallery fee (e.g., 500 = 5%)

    // --- Art Submission & Curation ---
    struct ArtSubmission {
        address creator;
        string metadataURI; // IPFS hash or similar
        uint256 submitTime;
        int256 votes; // Net votes: positive for approve, negative for reject
        bool processed; // Has this submission been reviewed/minted?
        bool approved; // Was it approved during processing?
    }
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => mapping(address => bool)) private _votedOnSubmission; // Track who voted on which submission

    // --- Minted Art Data ---
    struct ArtData {
        address creator;
        uint256 submissionId; // Link back to original submission
        uint256 mintTime;
        uint256 displayCount; // How many times it's been 'displayed' in a room
        bool fractionalizationInitiated; // Flag for potential future fractionalization
        string originalMetadataURI; // Store the original URI submitted
        string currentDescription; // A dynamic string owners can potentially update
    }
    mapping(uint256 => ArtData) public artData;
    mapping(uint256 => uint256) private _submissionIdToTokenId; // Mapping from processed submission ID to minted token ID

    // --- Marketplace ---
    struct Listing {
        uint256 price;
        address seller; // Redundant with ERC721.ownerOf, but useful for quick lookup
        bool isListed;
    }
    mapping(uint256 => Listing) public artListings;

    // --- Gallery Rooms ---
    struct GalleryRoom {
        string name;
        address owner; // Should be msg.sender
        bool exists;
    }
    mapping(address => GalleryRoom) public galleryRooms;
    mapping(address => uint256[]) public galleryRoomArt; // Array of token IDs displayed in a room

    // --- Financials ---
    mapping(address => uint256) public creatorBalances; // Balances owed to creators
    uint256 public galleryBalance; // Balance owed to the gallery owner/admin

    // --- Events ---
    event ArtSubmitted(uint256 indexed submissionId, address indexed creator, string metadataURI);
    event VoteCast(uint256 indexed submissionId, address indexed voter, bool approve);
    event SubmissionProcessed(uint256 indexed submissionId, bool approved, uint256 indexed tokenId);
    event ArtMinted(uint256 indexed tokenId, address indexed creator, string metadataURI);
    event ArtListed(uint256 indexed tokenId, uint256 price, address indexed seller);
    event ArtListingCancelled(uint256 indexed tokenId);
    event ArtBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event FractionalizationInitiated(uint256 indexed tokenId);
    event ArtDescriptionUpdated(uint256 indexed tokenId, string newDescription);
    event GalleryRoomSetup(address indexed owner, string name);
    event ArtAddedToRoom(address indexed owner, uint256 indexed tokenId);
    event ArtRemovedFromRoom(address indexed owner, uint256 indexed tokenId);
    event DisplayCountIncremented(uint256 indexed tokenId, uint256 newCount);
    event SubmissionFeeSet(uint256 indexed fee);
    event CurationThresholdSet(uint256 indexed threshold);
    event GalleryFeeBasisPointsSet(uint16 indexed basisPoints);
    event CreatorEarningsWithdrawn(address indexed creator, uint256 amount);
    event GalleryFeesWithdrawn(uint256 amount);
    event RejectedArtBurned(uint256 indexed submissionId);


    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        ReentrancyGuard()
    {
        // Grant default admin role to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant curator and governor roles to the deployer initially
        _grantRole(CURATOR_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender);

        // Set initial parameters (can be changed later by GOVERNOR_ROLE)
        submissionFee = 0.01 ether; // Example fee
        curationThreshold = 5; // Example: 5 net votes needed
        galleryFeeBasisPoints = 250; // Example: 2.5% gallery fee
    }

    // --- ERC-165 Interface Support ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IAccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Overridden tokenURI for Dynamic Metadata ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Check if the token exists
        _requireOwned(tokenId);

        ArtData storage data = artData[tokenId];
        require(bytes(data.originalMetadataURI).length > 0, "Invalid token");

        // Conceptually, we would fetch the base metadata from IPFS using data.originalMetadataURI
        // and then inject/override attributes based on on-chain state (data.displayCount, calculated status based on it, etc.).
        // In Solidity, we can't fetch external data directly. We can either:
        // 1. Return a static URI and assume the frontend handles dynamic parts.
        // 2. Return a URI that points to a service endpoint that fetches base data and injects dynamic data.
        // 3. Construct a *partial* URI or just provide dynamic attributes separately (via getDynamicArtAttributes).
        // For this example, let's assume the base URI might point to a service that uses the on-chain attributes we provide.
        // We'll return the original URI, but provide a separate function for dynamic attributes.

        // A more advanced approach would return a base URI + query parameters reflecting state,
        // or point to an API that takes the token ID and returns combined data.
        // Example of returning a base URI + query (conceptual, needs URL encoding):
        // string memory dynamicPart = string(abi.encodePacked(
        //     "?displayCount=", Strings.toString(data.displayCount),
        //     "&curationScore=", Strings.toString(data.votes) // If we stored final score
        // ));
        // return string(abi.encodePacked(data.originalMetadataURI, dynamicPart));

        // Simple approach: Just return the original URI. Frontends use getDynamicArtAttributes
        return data.originalMetadataURI;
    }

    // --- Submission & Curation ---

    /// @notice Allows a creator to submit art for community curation.
    /// @param metadataURI The URI (e.g., IPFS hash) pointing to the art's metadata.
    function submitArtForCuration(string memory metadataURI) public payable nonReentrant {
        require(bytes(metadataURI).length > 0, "Metadata URI required");
        require(msg.value >= submissionFee, "Insufficient submission fee");

        uint256 newSubmissionId = _submissionIds.current();
        artSubmissions[newSubmissionId] = ArtSubmission({
            creator: msg.sender,
            metadataURI: metadataURI,
            submitTime: block.timestamp,
            votes: 0, // Start with 0 votes
            processed: false,
            approved: false
        });
        _submissionIds.increment();

        // Send excess ETH back if any
        if (msg.value > submissionFee) {
            payable(msg.sender).transfer(msg.value - submissionFee);
        }

        emit ArtSubmitted(newSubmissionId, msg.sender, metadataURI);
    }

    /// @notice Allows an account with CURATOR_ROLE or DEFAULT_ADMIN_ROLE to vote on a submission.
    /// @param submissionId The ID of the submission to vote on.
    /// @param approve True to approve, False to reject.
    function voteForArt(uint256 submissionId, bool approve) public onlyRole(CURATOR_ROLE) {
        ArtSubmission storage submission = artSubmissions[submissionId];
        require(submission.creator != address(0), "Invalid submission ID");
        require(!submission.processed, "Submission already processed");
        require(!_votedOnSubmission[submissionId][msg.sender], "Already voted on this submission");

        if (approve) {
            submission.votes++;
        } else {
            submission.votes--;
        }

        _votedOnSubmission[submissionId][msg.sender] = true;

        emit VoteCast(submissionId, msg.sender, approve);
    }

    /// @notice Processes the curation results for given submissions. Mints NFTs for approved art.
    /// Can only be called by accounts with CURATOR_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param submissionIds An array of submission IDs to process.
    function processCurationResults(uint256[] memory submissionIds) public onlyRole(CURATOR_ROLE) {
        for (uint i = 0; i < submissionIds.length; i++) {
            uint256 submissionId = submissionIds[i];
            ArtSubmission storage submission = artSubmissions[submissionId];

            if (submission.creator == address(0) || submission.processed) {
                // Skip invalid or already processed submissions
                continue;
            }

            bool approved = submission.votes >= int256(curationThreshold);
            submission.processed = true;
            submission.approved = approved;

            uint256 newTokenId = 0;
            if (approved) {
                newTokenId = _tokenIds.current();
                _tokenIds.increment();

                // Mint the new NFT
                _safeMint(submission.creator, newTokenId); // Mints to the creator
                _submissionIdToTokenId[submissionId] = newTokenId;

                // Store art data
                artData[newTokenId] = ArtData({
                    creator: submission.creator,
                    submissionId: submissionId,
                    mintTime: block.timestamp,
                    displayCount: 0,
                    fractionalizationInitiated: false,
                    originalMetadataURI: submission.metadataURI,
                    currentDescription: "" // Optional: Initial description from metadata
                });

                emit ArtMinted(newTokenId, submission.creator, submission.metadataURI);
            }

            emit SubmissionProcessed(submissionId, approved, newTokenId);
        }
    }

    /// @notice Returns details of a specific art submission.
    /// @param submissionId The ID of the submission.
    /// @return creator The address of the creator.
    /// @return metadataURI The metadata URI.
    /// @return submitTime The submission timestamp.
    /// @return votes The current vote count.
    /// @return processed Whether the submission has been processed.
    /// @return approved Whether the submission was approved (if processed).
    function getArtSubmissionDetails(uint256 submissionId) public view returns (address creator, string memory metadataURI, uint256 submitTime, int256 votes, bool processed, bool approved) {
        ArtSubmission storage submission = artSubmissions[submissionId];
        require(submission.creator != address(0), "Invalid submission ID");
        return (submission.creator, submission.metadataURI, submission.submitTime, submission.votes, submission.processed, submission.approved);
    }

    /// @notice Returns the current vote count for a submission.
    /// @param submissionId The ID of the submission.
    /// @return The net vote count.
    function getSubmissionVoteCount(uint256 submissionId) public view returns (int256) {
        require(artSubmissions[submissionId].creator != address(0), "Invalid submission ID");
        return artSubmissions[submissionId].votes;
    }

     /// @notice Checks if a specific address has voted on a specific submission.
     /// @param submissionId The ID of the submission.
     /// @param voter The address to check.
     /// @return True if the address has voted, false otherwise.
    function hasVoted(uint256 submissionId, address voter) public view returns (bool) {
        require(artSubmissions[submissionId].creator != address(0), "Invalid submission ID");
        return _votedOnSubmission[submissionId][voter];
    }

    /// @notice Allows an account with CURATOR_ROLE to burn (effectively delete) rejected submissions.
    /// This is a cleanup function.
    /// @param submissionIds An array of submission IDs to burn.
    function burnRejectedArtSubmissions(uint256[] memory submissionIds) public onlyRole(CURATOR_ROLE) {
        for (uint i = 0; i < submissionIds.length; i++) {
            uint256 submissionId = submissionIds[i];
            ArtSubmission storage submission = artSubmissions[submissionId];

            // Only burn processed and *not* approved submissions
            if (submission.creator != address(0) && submission.processed && !submission.approved) {
                 // Clear storage for the submission
                delete artSubmissions[submissionId];
                // Note: _votedOnSubmission entries are small and can be left or iterated/cleared if needed for gas.
                // For simplicity, we leave them.

                emit RejectedArtBurned(submissionId);
            }
        }
    }


    // --- Marketplace ---

    /// @notice Allows the owner of an NFT to list it for sale.
    /// @param tokenId The ID of the token to list.
    /// @param price The price in Wei.
    function listArtForSale(uint256 tokenId, uint256 price) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(price > 0, "Price must be positive");
        require(!artListings[tokenId].isListed, "Art is already listed");

        // Remove from any active display room listing temporarily? (Optional, complex state interaction)
        // For simplicity, listing and display are independent states for now.

        artListings[tokenId] = Listing({
            price: price,
            seller: msg.sender,
            isListed: true
        });

        emit ArtListed(tokenId, price, msg.sender);
    }

    /// @notice Allows the seller of an NFT to cancel their listing.
    /// @param tokenId The ID of the token whose listing to cancel.
    function cancelArtListing(uint256 tokenId) public nonReentrant {
        Listing storage listing = artListings[tokenId];
        require(listing.isListed, "Art not listed");
        require(listing.seller == msg.sender, "Not the seller");

        delete artListings[tokenId];

        emit ArtListingCancelled(tokenId);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// Handles transfer of ownership and distribution of funds.
    /// @param tokenId The ID of the token to buy.
    function buyArt(uint256 tokenId) public payable nonReentrant {
        Listing storage listing = artListings[tokenId];
        require(listing.isListed, "Art not listed");
        require(msg.value >= listing.price, "Insufficient funds");
        require(ownerOf(tokenId) == listing.seller, "Seller mismatch or ownership changed"); // Double check ownership

        address seller = listing.seller;
        address creator = artData[tokenId].creator; // Get original creator

        // Delete the listing first to prevent reentrancy issues with state
        delete artListings[tokenId];

        // Transfer ownership of the NFT
        _safeTransfer(seller, msg.sender, tokenId);

        // Calculate fee amounts
        uint256 totalPayment = msg.value;
        uint256 pricePaid = listing.price; // Buyer might send more than list price, we only distribute list price
        uint256 galleryFeeAmount = (pricePaid * galleryFeeBasisPoints) / 10000;
        // Standard ERC2981 royalty concept: Royalties are *part* of the sale price paid by the buyer.
        // Here, let's implement a simple system where the creator also gets a share.
        // Let's say creator gets a fixed percentage *of the sale price* as well.
        // Example: Gallery 2.5%, Creator 5%. Total fees are 7.5%.
        // Seller receives 100% - 7.5% = 92.5%.
        // Let's modify: galleryFeeBasisPoints covers *both* gallery and creator, then we split it.
        // Or, let's add a separate creatorRoyaltyBasisPoints.
        // Let's simplify: Gallery takes a fee, Creator gets a fee on primary sale (minting) and secondary (marketplace).
        // Creator already got the NFT on mint. For secondary sale:
        // Seller gets: pricePaid - galleryFee - creatorRoyalty.
        // Let's define a separate creator royalty percentage for secondary sales.
        // Add creatorRoyaltyBasisPoints state variable.
        // For now, let's assume galleryFeeBasisPoints is the *total* fee taken from the seller,
        // and we'll split that between gallery and creator. E.g., 50/50 split of the fee.
        // This is a simplified example. A real system would use ERC2981 or more complex logic.
        // Let's use the simpler model: seller pays gallery fee, *and* seller pays creator royalty.
        // Both are percentages of the sale price.
        // We need a creatorRoyaltyBasisPoints state var. Let's add it in state and constructor/setters.
        // Reworking the fee logic:
        // Buyer pays `listing.price`.
        // `creatorRoyalty = (listing.price * creatorRoyaltyBasisPoints) / 10000;`
        // `galleryFee = (listing.price * galleryFeeBasisPoints) / 10000;`
        // `sellerProceeds = listing.price - creatorRoyalty - galleryFee;`
        // Let's add `creatorRoyaltyBasisPoints` state var and setter.

        // Re-doing calculation assuming creatorRoyaltyBasisPoints exists (adding state/setter later)
        uint16 creatorRoyaltyBasisPoints = 500; // Example: 5% royalty for creator on secondary sale
        uint256 creatorRoyaltyAmount = (pricePaid * creatorRoyaltyBasisPoints) / 10000;
        galleryFeeAmount = (pricePaid * galleryFeeBasisPoints) / 10000;
        uint256 sellerProceeds = pricePaid - creatorRoyaltyAmount - galleryFeeAmount;

        // Accumulate funds instead of direct transfer for security (reentrancy)
        creatorBalances[creator] += creatorRoyaltyAmount;
        creatorBalances[seller] += sellerProceeds; // Seller receives their part
        galleryBalance += galleryFeeAmount;

        // Refund any excess ETH sent by the buyer
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }

        emit ArtBought(tokenId, msg.sender, listing.price);
    }

    /// @notice Returns the details of an art listing.
    /// @param tokenId The ID of the token.
    /// @return price The listed price.
    /// @return seller The address of the seller.
    /// @return isListed Whether the art is currently listed.
    function getArtListing(uint256 tokenId) public view returns (uint256 price, address seller, bool isListed) {
        Listing storage listing = artListings[tokenId];
        return (listing.price, listing.seller, listing.isListed);
    }


    // --- Ownership & Fractionalization ---

    /// @notice Allows the owner of an NFT to signal their intent to fractionalize it.
    /// This function only updates an on-chain flag; the actual fractionalization must be
    /// performed by an external fractionalization protocol or contract.
    /// @param tokenId The ID of the token to mark for fractionalization.
    function initiateFractionalization(uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(!artData[tokenId].fractionalizationInitiated, "Fractionalization already initiated");

        artData[tokenId].fractionalizationInitiated = true;

        // Note: A real implementation would likely require the NFT to be transferred to a vault contract
        // of the fractionalization protocol. This function just signals intent on *this* contract.
        // It doesn't lock the NFT here. The owner must manually transfer it to the vault after calling this.

        emit FractionalizationInitiated(tokenId);
    }

    /// @notice Checks if fractionalization has been initiated for an NFT.
    /// @param tokenId The ID of the token.
    /// @return True if fractionalization is initiated, false otherwise.
    function isFractionalizationInitiated(uint256 tokenId) public view returns (bool) {
        _requireOwned(tokenId); // Ensure token exists
        return artData[tokenId].fractionalizationInitiated;
    }

    /// @notice Allows the owner of an NFT to update its on-chain description string.
    /// This is an example of a mutable metadata field.
    /// @param tokenId The ID of the token.
    /// @param newDescription The new description string.
    function updateArtDescription(uint256 tokenId, string memory newDescription) public {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
         // Optional: Add length limits or content validation
         artData[tokenId].currentDescription = newDescription;
         emit ArtDescriptionUpdated(tokenId, newDescription);
    }


    // --- Gallery Rooms & Display ---

    /// @notice Allows an address to set up their gallery room.
    /// Only one room per address.
    /// @param roomName The name for the gallery room.
    function setupGalleryRoom(string memory roomName) public {
        require(!galleryRooms[msg.sender].exists, "Gallery room already exists");
        require(bytes(roomName).length > 0, "Room name cannot be empty");

        galleryRooms[msg.sender] = GalleryRoom({
            name: roomName,
            owner: msg.sender,
            exists: true
        });

        // Initialize the art array for this room
        galleryRoomArt[msg.sender] = new uint256[](0);

        emit GalleryRoomSetup(msg.sender, roomName);
    }

    /// @notice Allows a gallery room owner to add their owned art to the display list.
    /// @param tokenIds An array of token IDs to add.
    function addArtToGalleryRoom(uint256[] memory tokenIds) public {
        require(galleryRooms[msg.sender].exists, "Gallery room not set up");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved for all tokens");

            // Check if already in the room list (basic check, can be optimized with a mapping)
            bool alreadyAdded = false;
            for (uint j = 0; j < galleryRoomArt[msg.sender].length; j++) {
                if (galleryRoomArt[msg.sender][j] == tokenId) {
                    alreadyAdded = true;
                    break;
                }
            }
            if (!alreadyAdded) {
                 galleryRoomArt[msg.sender].push(tokenId);
                 emit ArtAddedToRoom(msg.sender, tokenId);
            }
        }
    }

    /// @notice Allows a gallery room owner to remove art from their display list.
    /// @param tokenIds An array of token IDs to remove.
    function removeArtFromGalleryRoom(uint256[] memory tokenIds) public {
        require(galleryRooms[msg.sender].exists, "Gallery room not set up");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenIdToRemove = tokenIds[i];
            uint256[] storage currentArt = galleryRoomArt[msg.sender];
            uint256 initialLength = currentArt.length;

            // Find and remove the token ID
            for (uint j = 0; j < currentArt.length; j++) {
                if (currentArt[j] == tokenIdToRemove) {
                    // Swap with last element and pop
                    currentArt[j] = currentArt[currentArt.length - 1];
                    currentArt.pop();
                    emit ArtRemovedFromRoom(msg.sender, tokenIdToRemove);
                    break; // Assume unique tokens in the list, move to next tokenToRemove
                }
            }
             // Optional: require that at least one token was removed if needed
             // require(currentArt.length < initialLength, "Token not found in room");
        }
    }

    /// @notice Returns the list of token IDs displayed in a gallery room.
    /// @param owner The address of the gallery room owner.
    /// @return An array of token IDs.
    function getGalleryRoomArt(address owner) public view returns (uint256[] memory) {
        require(galleryRooms[owner].exists, "Gallery room not set up for this address");
        return galleryRoomArt[owner];
    }

    /// @notice Increments the display count for an art piece.
    /// This function is intended to be called by a frontend application or an external system
    /// when the art is viewed in a gallery room or elsewhere.
    /// @param tokenId The ID of the token that was displayed.
    function incrementDisplayCount(uint256 tokenId) public {
        // Add restrictions if needed, e.g., only callable by a trusted contract or after a delay per user/token.
        // For simplicity, anyone can call it for now.
        _requireOwned(tokenId); // Ensure token exists

        artData[tokenId].displayCount++;
        emit DisplayCountIncremented(tokenId, artData[tokenId].displayCount);
    }


    // --- Dynamic Metadata ---

    /// @notice Returns dynamic attributes for a given token ID.
    /// These attributes can be used by a frontend or metadata service to augment the base metadata.
    /// @param tokenId The ID of the token.
    /// @return displayCount The number of times the art has been 'displayed'.
    /// @return fractionalizationInitiated Whether fractionalization has been initiated.
    /// @return currentDescription The current mutable description string.
    /// @return curationScore (Conceptual) The score it received during curation (if we stored it per token, currently only submission).
    function getDynamicArtAttributes(uint256 tokenId) public view returns (uint256 displayCount, bool fractionalizationInitiated, string memory currentDescription, int256 curationScore) {
        _requireOwned(tokenId); // Ensure token exists
        ArtData storage data = artData[tokenId];
        ArtSubmission storage submission = artSubmissions[data.submissionId]; // Link back to get original score if needed

        // Note: Storing final curation score per token could be added to ArtData struct.
        // Using submission.votes here is okay IF submission.processed is true and it was approved.
        // A more robust system might store the final score in ArtData upon minting.
        int256 finalCurationScore = submission.processed && submission.approved ? submission.votes : 0;

        return (data.displayCount, data.fractionalizationInitiated, data.currentDescription, finalCurationScore);
    }

    /// @notice Returns the original immutable metadata URI submitted for the art.
    /// @param tokenId The ID of the token.
    /// @return The original metadata URI.
    function getBaseMetadataURI(uint256 tokenId) public view returns (string memory) {
         _requireOwned(tokenId); // Ensure token exists
         return artData[tokenId].originalMetadataURI;
    }


    // --- Governance & Roles ---

    /// @notice Grants the CURATOR_ROLE to an account.
    /// @param account The address to grant the role to.
    function grantCuratorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(CURATOR_ROLE, account);
    }

    /// @notice Revokes the CURATOR_ROLE from an account.
    /// @param account The address to revoke the role from.
    function revokeCuratorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(CURATOR_ROLE, account);
    }

    /// @notice Grants the GOVERNOR_ROLE to an account.
    /// @param account The address to grant the role to.
    function grantGovernorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GOVERNOR_ROLE, account);
    }

    /// @notice Revokes the GOVERNOR_ROLE from an account.
    /// @param account The address to revoke the role from.
    function revokeGovernorRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(GOVERNOR_ROLE, account);
    }

    /// @notice Sets the fee required to submit art for curation.
    /// Can only be called by accounts with GOVERNOR_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param fee The new submission fee in Wei.
    function setSubmissionFee(uint256 fee) public onlyRole(GOVERNOR_ROLE) {
        submissionFee = fee;
        emit SubmissionFeeSet(fee);
    }

    /// @notice Sets the minimum net approval votes needed to pass curation.
    /// Can only be called by accounts with GOVERNOR_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param threshold The new curation threshold.
    function setCurationThreshold(uint256 threshold) public onlyRole(GOVERNOR_ROLE) {
        curationThreshold = threshold;
        emit CurationThresholdSet(threshold);
    }

    /// @notice Sets the percentage of the sale price that goes to the gallery as commission.
    /// Can only be called by accounts with GOVERNOR_ROLE or DEFAULT_ADMIN_ROLE.
    /// @param basisPoints The new gallery fee in basis points (10000 = 100%).
    function setGalleryFeeBasisPoints(uint16 basisPoints) public onlyRole(GOVERNOR_ROLE) {
        require(basisPoints <= 10000, "Basis points must be <= 10000");
        // Note: If adding creatorRoyaltyBasisPoints, add checks that totalBasisPoints <= 10000
        galleryFeeBasisPoints = basisPoints;
        emit GalleryFeeBasisPointsSet(basisPoints);
    }

     // --- (Optional) Add setCreatorRoyaltyBasisPoints similar to setGalleryFeeBasisPoints ---
     // uint16 public creatorRoyaltyBasisPoints;
     // function setCreatorRoyaltyBasisPoints(uint16 basisPoints) public onlyRole(GOVERNOR_ROLE) { ... }


    // --- Fund Management ---

    /// @notice Allows a creator to withdraw their accumulated earnings from sales royalties.
    /// @param creator The address of the creator withdrawing funds.
    function withdrawCreatorEarnings(address creator) public nonReentrant {
        require(msg.sender == creator || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        uint256 amount = creatorBalances[creator];
        require(amount > 0, "No earnings to withdraw");

        creatorBalances[creator] = 0; // Reset balance before sending

        (bool success, ) = payable(creator).call{value: amount}("");
        require(success, "Transfer failed");

        emit CreatorEarningsWithdrawn(creator, amount);
    }

    /// @notice Allows the gallery admin to withdraw accumulated gallery fees.
    function withdrawGalleryFees() public onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 amount = galleryBalance;
        require(amount > 0, "No fees to withdraw");

        galleryBalance = 0; // Reset balance before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit GalleryFeesWithdrawn(amount);
    }

    // --- Utility View Functions ---

    /// @notice Returns the current submission fee.
    function getSubmissionFee() public view returns (uint256) {
        return submissionFee;
    }

    /// @notice Returns the current curation threshold.
    function getCurationThreshold() public view returns (uint256) {
        return curationThreshold;
    }

    /// @notice Returns the current gallery fee basis points.
    function getGalleryFeeBasisPoints() public view returns (uint16) {
        return galleryFeeBasisPoints;
    }

    /// @notice Returns the contract's balance reserved for gallery fees.
    function getGalleryBalance() public view returns (uint256) {
        return galleryBalance;
    }

    /// @notice Returns a creator's balance of pending earnings.
    /// @param creator The address of the creator.
    function getCreatorBalance(address creator) public view returns (uint256) {
        return creatorBalances[creator];
    }

    /// @notice Returns the ID that will be assigned to the next art submission.
    function getCurrentSubmissionId() public view returns (uint256) {
        return _submissionIds.current();
    }

    /// @notice Returns the original creator of a minted token.
    /// @param tokenId The ID of the token.
    /// @return The creator's address.
    function getTokenCreator(uint256 tokenId) public view returns (address) {
        _requireOwned(tokenId); // Ensure token exists
        return artData[tokenId].creator;
    }


    // --- Internal Helper ---

    /// @dev Internal function to check if a token exists.
    function _requireOwned(uint256 tokenId) internal view {
         require(_exists(tokenId), "Token does not exist");
    }
}
```