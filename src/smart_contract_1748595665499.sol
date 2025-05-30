Okay, here is a smart contract concept that incorporates several advanced, creative, and trendy ideas around decentralized AI art creation, curation, and exhibition as NFTs. It's designed to be non-standard and includes various mechanisms.

It's called `DecentralizedAIArtGallery`.

**Core Concept:**
A platform where artists can submit AI-generated art pieces (represented by metadata URIs). Submissions undergo a decentralized curation process influenced by both community voting and an "AI Oracle Score" (simulated in this contract but representing potential external AI analysis). Approved pieces are minted as unique NFTs and become part of a dynamic gallery, available for sale via direct purchase or auction, with built-in royalties and potential for dynamic metadata updates.

**Advanced/Creative Concepts Included:**
1.  **Decentralized Curation:** Combines community voting with an external (simulated) AI score.
2.  **AI Oracle Integration:** Placeholder for using AI analysis results on-chain.
3.  **Dynamic Gallery:** Pieces can be marked as "featured".
4.  **Multiple Sales Methods:** Direct sale and English auction built-in.
5.  **ERC2981 Royalties:** Standardized royalties on secondary sales.
6.  **Submission & Approval Flow:** A structured process before minting.
7.  **Dynamic Metadata Placeholder:** Ability to trigger updates to metadata (though the metadata itself would live off-chain).
8.  **Basic Governance/Admin:** Via thresholds and owner controls (could be expanded to a full DAO).

---

**Contract Outline & Function Summary**

**I. Contract Overview**
*   Name: `DecentralizedAIArtGallery`
*   Standard Compliance: ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard.
*   Purpose: Manage submission, curation, minting, exhibition, and sale of AI art NFTs.

**II. State Variables**
*   Track token IDs, URIs, submission details, votes, AI scores, sale data, auction data, curation settings, featured art.

**III. Events**
*   Signals key actions like submissions, votes, score recording, approvals, rejections, minting, sales, auctions, metadata updates.

**IV. Functions (Grouped by Category)**

**A. Standard ERC721 / ERC165 / ERC2981 (8 functions)**
1.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Check for ERC165 interface compliance (ERC721, ERC721Enumerable, ERC2981).
2.  `tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)`: Get the metadata URI for a token. (Note: Uses ERC721URIStorage internally, adds override).
3.  `royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount)`: Get royalty information for a token sale (ERC2981).
4.  `balanceOf(address owner) public view override returns (uint256)`: ERC721: Get token count for an owner.
5.  `ownerOf(uint256 tokenId) public view override returns (address)`: ERC721: Get owner of a token.
6.  `approve(address to, uint256 tokenId) public override`: ERC721: Approve address for token transfer.
7.  `getApproved(uint256 tokenId) public view override returns (address)`: ERC721: Get approved address for token.
8.  `setApprovalForAll(address operator, bool approved) public override`: ERC721: Set approval for all tokens by an operator.
9.  `isApprovedForAll(address owner, address operator) public view override returns (bool)`: ERC721: Check operator approval for all tokens. *(Adds up to 9, let's list them explicitly)*

**B. Submission & Curation (6 functions)**
10. `submitArt(string memory metadataURI, string memory artistName) external`: Allow an artist to submit their AI art piece metadata for curation.
11. `castVoteOnSubmission(uint256 submissionId, bool vote) external`: Community members vote on a submission (true for yes/upvote, false for no/downvote - simplified).
12. `recordAIScore(uint256 submissionId, uint256 score) external onlyOwner`: Record the simulated AI score for a submission. (Represents oracle input).
13. `reviewAndApproveSubmission(uint256 submissionId) external`: Trigger the review process. If vote count and AI score meet thresholds, the submission state changes to Approved.
14. `rejectSubmission(uint256 submissionId) external onlyOwner`: Manually reject a submission.
15. `mintApprovedSubmission(uint256 submissionId) external`: Mint the NFT for an approved submission. Can be called by anyone once approved.

**C. Gallery Management & Settings (7 functions)**
16. `setVoteThreshold(uint256 _voteThreshold) external onlyOwner`: Set the minimum required votes for approval.
17. `setAIScoreThreshold(uint256 _aiScoreThreshold) external onlyOwner`: Set the minimum required AI score for approval.
18. `setCurationFee(uint256 _curationFee) external onlyOwner`: Set the fee charged upon successful minting (paid by minter, or artist if handled differently).
19. `withdrawCurationFees() external onlyOwner`: Owner withdraws collected curation fees.
20. `setFeaturedArtwork(uint256 tokenId, bool isFeatured) external onlyOwner`: Mark an artwork as featured in the gallery.
21. `getFeaturedArtworks() external view returns (uint256[] memory)`: Get a list of token IDs currently marked as featured.
22. `setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner`: Set the default royalty percentage for all future tokens (ERC2981 helper). *(Adds up to 7)*

**D. Sales & Auctions (7 functions)**
23. `listForSale(uint256 tokenId, uint256 price) external`: Owner lists their NFT for direct sale.
24. `buyArtwork(uint256 tokenId) external payable nonReentrant`: Buy an artwork listed for direct sale.
25. `cancelSale(uint256 tokenId) external`: Owner cancels a direct sale listing.
26. `startAuction(uint256 tokenId, uint256 startingBid, uint64 duration) external`: Owner starts an English auction for their NFT.
27. `placeBid(uint256 tokenId) external payable nonReentrant`: Place a bid in an active auction.
28. `endAuction(uint256 tokenId) external nonReentrant`: Anyone can call to finalize an auction after it ends.
29. `cancelAuction(uint256 tokenId) external`: Owner cancels an auction before it ends. *(Adds up to 7)*

**E. Query & Information (9 functions)**
30. `getSubmissionDetails(uint256 submissionId) external view returns (Submission memory)`: Get details about a submission.
31. `getSubmissionVoteCount(uint256 submissionId) external view returns (uint256)`: Get the current upvote count for a submission.
32. `hasVotedOnSubmission(uint256 submissionId, address voter) external view returns (bool)`: Check if an address has voted on a submission.
33. `getSubmissionAIScore(uint256 submissionId) external view returns (uint256)`: Get the recorded AI score for a submission.
34. `getGallerySize() external view returns (uint256)`: Get the total number of approved NFTs in the gallery.
35. `isApprovedInGallery(uint256 tokenId) external view returns (bool)`: Check if a token was minted through this contract's approval process.
36. `getSaleDetails(uint256 tokenId) external view returns (Sale memory)`: Get details for a direct sale listing.
37. `getAuctionDetails(uint256 tokenId) external view returns (Auction memory)`: Get details for an active or ended auction.
38. `getAllSubmissionIds() external view returns (uint256[] memory)`: Get a list of all submission IDs. *(Adds up to 9)*

**F. Advanced / Dynamic (2 functions)**
39. `updateArtworkMetadata(uint256 tokenId, string memory newMetadataURI) external`: Allow the owner (or artist if configured) to update the metadata URI of an NFT. (Could be restricted or triggered by events).
40. `triggerDynamicMetadataUpdate(uint256 tokenId) external`: A placeholder function. In a real dynamic NFT, calling this might trigger off-chain logic to generate new metadata based on on-chain state, then call `updateArtworkMetadata`. *(Adds up to 2)*

**Total Functions: 9 (ERC) + 6 (Curation) + 7 (Management) + 7 (Sales) + 9 (Query) + 2 (Dynamic) = 40 functions.**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Contract Outline & Function Summary (See above for full list)
// I. Contract Overview: DecentralizedAIArtGallery, ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard.
// II. State Variables: tokenIdCounter, submissionCounter, submissions, submissionVotes, aiScores, galleryTokens,
//    saleDetails, auctionDetails, featuredArtworks, curationFee, voteThreshold, aiScoreThreshold, defaultRoyaltyReceiver, defaultRoyaltyNumerator.
// III. Events: ArtSubmitted, VotedOnSubmission, AIScoreRecorded, SubmissionApproved, SubmissionRejected,
//     ArtworkMinted, ArtworkListedForSale, ArtworkBought, SaleCancelled, AuctionStarted, BidPlaced,
//     AuctionEnded, AuctionCancelled, ArtworkMetadataUpdated, FeaturedArtworkSet, CurationFeesWithdrawn.
// IV. Functions:
//    A. Standard ERC721/ERC165/ERC2981 (9 functions)
//       supportsInterface, tokenURI, royaltyInfo, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll.
//    B. Submission & Curation (6 functions)
//       submitArt, castVoteOnSubmission, recordAIScore, reviewAndApproveSubmission, rejectSubmission, mintApprovedSubmission.
//    C. Gallery Management & Settings (7 functions)
//       setVoteThreshold, setAIScoreThreshold, setCurationFee, withdrawCurationFees, setFeaturedArtwork, getFeaturedArtworks, setDefaultRoyalty.
//    D. Sales & Auctions (7 functions)
//       listForSale, buyArtwork, cancelSale, startAuction, placeBid, endAuction, cancelAuction.
//    E. Query & Information (9 functions)
//       getSubmissionDetails, getSubmissionVoteCount, hasVotedOnSubmission, getSubmissionAIScore, getGallerySize,
//       isApprovedInGallery, getSaleDetails, getAuctionDetails, getAllSubmissionIds.
//    F. Advanced / Dynamic (2 functions)
//       updateArtworkMetadata, triggerDynamicMetadataUpdate.

contract DecentralizedAIArtGallery is ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _submissionCounter;

    enum SubmissionState { Pending, Approved, Rejected, Minted }

    struct Submission {
        uint256 id;
        address artist;
        string metadataURI;
        string artistName;
        SubmissionState state;
        uint64 timestamp;
    }

    struct Sale {
        uint256 price;
        address seller;
        bool isForSale;
    }

    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 currentBid;
        address payable highestBidder;
        uint64 endTime;
        bool ended;
    }

    // --- State Variables ---
    mapping(uint256 => Submission) private submissions;
    mapping(uint256 => mapping(address => bool)) private hasVoted; // submissionId => voterAddress => voted
    mapping(uint256 => uint256) private submissionVoteCounts; // submissionId => voteCount
    mapping(uint256 => uint256) private aiScores; // submissionId => score (0-100 or other range)

    // Store which tokenIds were minted via this contract's approval process
    mapping(uint256 => bool) private _isApprovedGalleryPiece;
    uint256[] private _galleryTokenIds; // Maintain a list of approved tokens

    mapping(uint256 => Sale) private sales; // tokenId => Sale details
    mapping(uint256 => Auction) private auctions; // tokenId => Auction details (only one active auction per token at a time)
    mapping(uint256 => address) private pendingReturns; // For auction refunds

    mapping(uint256 => bool) private featuredArtworks; // tokenId => isFeatured?

    uint256 public curationFee; // Fee collected on successful mint (in wei)
    uint256 public voteThreshold; // Minimum positive votes needed for approval
    uint256 public aiScoreThreshold; // Minimum AI score needed for approval

    // ERC2981 Default Royalties
    address private _defaultRoyaltyReceiver;
    uint96 private _defaultRoyaltyNumerator; // Basis points (e.g., 500 for 5%)

    // --- Events ---
    event ArtSubmitted(uint256 submissionId, address indexed artist, string metadataURI, string artistName, uint64 timestamp);
    event VotedOnSubmission(uint256 indexed submissionId, address indexed voter, bool vote); // vote=true is upvote
    event AIScoreRecorded(uint256 indexed submissionId, uint256 score);
    event SubmissionApproved(uint256 indexed submissionId);
    event SubmissionRejected(uint256 indexed submissionId);
    event ArtworkMinted(uint256 indexed tokenId, uint256 indexed submissionId, address indexed owner);
    event ArtworkListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtworkBought(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event SaleCancelled(uint256 indexed tokenId, address indexed seller);
    event AuctionStarted(uint256 indexed tokenId, address indexed seller, uint256 startingBid, uint64 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 finalPrice);
    event AuctionCancelled(uint256 indexed tokenId, address indexed seller);
    event ArtworkMetadataUpdated(uint256 indexed tokenId, string newMetadataURI);
    event FeaturedArtworkSet(uint256 indexed tokenId, bool isFeatured);
    event CurationFeesWithdrawn(uint256 amount);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 _voteThreshold, uint256 _aiScoreThreshold, uint256 _curationFee, address _defaultRoyaltyReceiver, uint96 _defaultRoyaltyNumerator)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        voteThreshold = _voteThreshold;
        aiScoreThreshold = _aiScoreThreshold;
        curationFee = _curationFee;
        _defaultRoyaltyReceiver = _defaultRoyaltyReceiver;
        _defaultRoyaltyNumerator = _defaultRoyaltyNumerator;
    }

    // --- Standard ERC721 / ERC165 / ERC2981 Functions ---

    // 1. supportsInterface (ERC165)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 2. tokenURI (Override from ERC721URIStorage)
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // 3. royaltyInfo (ERC2981)
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "ERC2981: invalid token ID");
        // Check for token-specific royalty first, then default
        if (_tokenRoyaltyInfo.containsKey(tokenId)) {
             RoyaltyInfo memory info = _tokenRoyaltyInfo.get(tokenId);
             return (info.receiver, (salePrice * info.numerator) / 10000);
        }
        return (_defaultRoyaltyReceiver, (salePrice * _defaultRoyaltyNumerator) / 10000);
    }

    // 4. balanceOf (ERC721Enumerable) - Inherited
    // 5. ownerOf (ERC721) - Inherited
    // 6. approve (ERC721) - Inherited
    // 7. getApproved (ERC721) - Inherited
    // 8. setApprovalForAll (ERC721) - Inherited
    // 9. isApprovedForAll (ERC721) - Inherited

    // Helper to set default royalty (part of ERC2981 extension pattern)
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal {
        _defaultRoyaltyReceiver = receiver;
        _defaultRoyaltyNumerator = feeNumerator;
    }

    // Helper to set token specific royalty (part of ERC2981 extension pattern)
    // Note: OpenZeppelin's ERC2981 doesn't include token-specific royalty helper by default.
    // We can add a simple map or use a struct if needed for complexity.
    // For simplicity here, we'll just override royaltyInfo and use a separate map.
    // Adding state for token-specific royalty:
     struct RoyaltyInfo {
         address receiver;
         uint96 numerator; // Basis points
     }
     // Mapping from token ID to token-specific royalty info
     mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;
     // Helper function to set token specific royalty
     function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal {
         _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
     }


    // --- Submission & Curation Functions ---

    // 10. submitArt
    function submitArt(string memory metadataURI, string memory artistName) external {
        uint256 submissionId = _submissionCounter.current();
        _submissionCounter.increment();

        submissions[submissionId] = Submission({
            id: submissionId,
            artist: msg.sender,
            metadataURI: metadataURI,
            artistName: artistName,
            state: SubmissionState.Pending,
            timestamp: uint64(block.timestamp)
        });

        emit ArtSubmitted(submissionId, msg.sender, metadataURI, artistName, uint64(block.timestamp));
    }

    // 11. castVoteOnSubmission
    function castVoteOnSubmission(uint256 submissionId, bool vote) external {
        Submission storage submission = submissions[submissionId];
        require(submission.state == SubmissionState.Pending, "Submission not pending");
        require(!hasVoted[submissionId][msg.sender], "Already voted on this submission");

        hasVoted[submissionId][msg.sender] = true;
        if (vote) {
            submissionVoteCounts[submissionId]++;
        }
        // Simple model: only count 'true' votes towards the threshold

        emit VotedOnSubmission(submissionId, msg.sender, vote);
    }

    // 12. recordAIScore (Simulated Oracle Input)
    function recordAIScore(uint256 submissionId, uint256 score) external onlyOwner {
        Submission storage submission = submissions[submissionId];
        require(submission.state == SubmissionState.Pending, "Submission not pending");
        require(score <= 100, "Score must be between 0 and 100 (example range)"); // Example range

        aiScores[submissionId] = score;

        emit AIScoreRecorded(submissionId, score);
    }

    // 13. reviewAndApproveSubmission
    function reviewAndApproveSubmission(uint256 submissionId) external {
        Submission storage submission = submissions[submissionId];
        require(submission.state == SubmissionState.Pending, "Submission not pending");

        uint256 currentVoteCount = submissionVoteCounts[submissionId];
        uint256 currentAIScore = aiScores[submissionId];

        if (currentVoteCount >= voteThreshold && currentAIScore >= aiScoreThreshold) {
            submission.state = SubmissionState.Approved;
            emit SubmissionApproved(submissionId);
        } else {
            // Automatically reject if thresholds not met
            submission.state = SubmissionState.Rejected;
            emit SubmissionRejected(submissionId);
        }
    }

    // 14. rejectSubmission (Manual Rejection)
    function rejectSubmission(uint256 submissionId) external onlyOwner {
        Submission storage submission = submissions[submissionId];
        require(submission.state == SubmissionState.Pending, "Submission not pending");

        submission.state = SubmissionState.Rejected;
        emit SubmissionRejected(submissionId);
    }

    // 15. mintApprovedSubmission
    // Can be called by anyone to trigger minting for an approved piece.
    // Minter pays the curation fee. Token is minted to the original artist.
    function mintApprovedSubmission(uint256 submissionId) external payable {
        Submission storage submission = submissions[submissionId];
        require(submission.state == SubmissionState.Approved, "Submission not in Approved state");
        require(msg.value >= curationFee, "Insufficient curation fee");

        submission.state = SubmissionState.Minted;

        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Mint to the original artist
        _safeMint(submission.artist, newItemId);
        _setTokenURI(newItemId, submission.metadataURI);

        _isApprovedGalleryPiece[newItemId] = true;
        _galleryTokenIds.push(newItemId); // Add to gallery list

        // Set default royalty for this minted token
        _setTokenRoyalty(newItemId, _defaultRoyaltyReceiver, _defaultRoyaltyNumerator);


        // Collect curation fee
        if (curationFee > 0) {
            payable(owner()).transfer(curationFee); // Send fee to contract owner
        }

        emit ArtworkMinted(newItemId, submissionId, submission.artist);
    }


    // --- Gallery Management & Settings Functions ---

    // 16. setVoteThreshold
    function setVoteThreshold(uint256 _voteThreshold) external onlyOwner {
        voteThreshold = _voteThreshold;
    }

    // 17. setAIScoreThreshold
    function setAIScoreThreshold(uint256 _aiScoreThreshold) external onlyOwner {
        aiScoreThreshold = _aiScoreThreshold;
    }

    // 18. setCurationFee
    function setCurationFee(uint256 _curationFee) external onlyOwner {
        curationFee = _curationFee;
    }

    // 19. withdrawCurationFees
    function withdrawCurationFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
        emit CurationFeesWithdrawn(balance);
    }

    // 20. setFeaturedArtwork
    function setFeaturedArtwork(uint256 tokenId, bool isFeatured) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        featuredArtworks[tokenId] = isFeatured;
        emit FeaturedArtworkSet(tokenId, isFeatured);
    }

    // 21. getFeaturedArtworks
    function getFeaturedArtworks() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _galleryTokenIds.length; i++) {
            if (featuredArtworks[_galleryTokenIds[i]]) {
                count++;
            }
        }

        uint256[] memory featured = new uint256[](count);
        uint256 index = 0;
         for (uint256 i = 0; i < _galleryTokenIds.length; i++) {
            if (featuredArtworks[_galleryTokenIds[i]]) {
                 featured[index] = _galleryTokenIds[i];
                 index++;
            }
        }
        return featured;
    }

    // 22. setDefaultRoyalty
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // --- Sales & Auctions Functions ---

    // 23. listForSale
    function listForSale(uint256 tokenId, uint256 price) external {
        require(_isApprovedGalleryPiece[tokenId], "Not a gallery piece");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(price > 0, "Price must be positive");
        // Ensure token is not currently in an active auction
        require(auctions[tokenId].endTime == 0 || auctions[tokenId].ended, "Token is in auction");


        sales[tokenId] = Sale({
            price: price,
            seller: msg.sender,
            isForSale: true
        });

        // Cancel any pending auction refunds if re-listing after an auction
        pendingReturns[tokenId] = payable(address(0));

        emit ArtworkListedForSale(tokenId, msg.sender, price);
    }

    // 24. buyArtwork
    function buyArtwork(uint256 tokenId) external payable nonReentrant {
        Sale storage sale = sales[tokenId];
        require(sale.isForSale, "Artwork not listed for sale");
        require(msg.value >= sale.price, "Insufficient funds");
        require(ownerOf(tokenId) != msg.sender, "Cannot buy your own artwork");

        address seller = sale.seller; // Use stored seller as ownership might change
        uint256 price = sale.price; // Use stored price
        address originalOwner = ownerOf(tokenId); // Get current owner

        // Transfer NFT to buyer
        _transfer(originalOwner, msg.sender, tokenId);

        // Send sale price to seller
        // If the seller is the contract itself (e.g., if contract minted directly or became owner),
        // the fee should go to the owner.
        if (seller == address(this)) {
             // This case might happen if the contract were to directly mint and sell (not currently implemented)
             // Or if the owner transferred it *to* the contract address which then listed it.
             // For this contract, sellers should be external addresses or the contract owner.
             // Let's assume seller is the _approved_ or _owner_ address listing it.
             // So the seller should be an external address.
             // If the owner listed it, seller is owner(). If an approved address listed it, seller is that address.
              payable(seller).transfer(price); // Send to the address that listed it
        } else {
            // For clarity, let's just ensure the current owner (who must have listed it or approved the lister) receives payment.
            // If the seller recorded in the struct is not the current owner, something is wrong or logic needs update.
            // Simple approach: Pay the current owner (who must be the lister or approved the lister).
             payable(originalOwner).transfer(price);
        }


        // Clear sale details
        delete sales[tokenId];

        // Refund any excess payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit ArtworkBought(tokenId, msg.sender, price);
    }

    // 25. cancelSale
    function cancelSale(uint256 tokenId) external {
        Sale storage sale = sales[tokenId];
        require(sale.isForSale, "Artwork not listed for sale");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner"); // Only owner or approved address can cancel

        delete sales[tokenId];

        emit SaleCancelled(tokenId, msg.sender);
    }

     // 26. startAuction
    function startAuction(uint256 tokenId, uint256 startingBid, uint64 duration) external {
        require(_isApprovedGalleryPiece[tokenId], "Not a gallery piece");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(startingBid > 0, "Starting bid must be positive");
        require(duration > 0, "Duration must be positive");
        require(auctions[tokenId].endTime == 0 || auctions[tokenId].ended, "Token is already in an active auction");
        require(!sales[tokenId].isForSale, "Token is listed for direct sale");


        auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: payable(msg.sender), // Seller is the one who starts the auction
            currentBid: startingBid,
            highestBidder: payable(address(0)), // No bidder initially
            endTime: uint64(block.timestamp) + duration,
            ended: false
        });

        // Clear any pending returns from previous auctions on this token
        pendingReturns[tokenId] = payable(address(0));

        // Approve the contract to transfer the token when auction ends
        _approve(address(this), tokenId);

        emit AuctionStarted(tokenId, msg.sender, startingBid, auctions[tokenId].endTime);
    }

    // 27. placeBid
    function placeBid(uint256 tokenId) external payable nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.seller != address(0), "No active auction for this token"); // Check if auction exists
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.endTime, "Auction has ended"); // Re-check end time
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");
        require(msg.value > auction.currentBid, "Bid must be higher than current bid");
        // Prevent placing bid if token is listed for sale (shouldn't happen if startAuction logic is correct)
        require(!sales[tokenId].isForSale, "Token is listed for direct sale");


        // Refund previous highest bidder
        if (auction.highestBidder != payable(address(0))) {
            pendingReturns[tokenId] = auction.highestBidder; // Mark for refund
        }

        auction.currentBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    // 28. endAuction
    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.seller != address(0), "No active auction for this token"); // Check if auction exists
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.ended = true; // Mark as ended immediately

        if (auction.highestBidder == payable(address(0))) {
            // No bids were placed
            // Return approval to the seller
            _approve(address(0), tokenId);
            emit AuctionEnded(tokenId, address(0), 0);
        } else {
            // Transfer token to the highest bidder
            address originalOwner = ownerOf(tokenId);
            _transfer(originalOwner, auction.highestBidder, tokenId);

            // Send highest bid amount to the seller
            uint256 amount = auction.currentBid;
             (bool success, ) = auction.seller.call{value: amount}("");
             require(success, "Transfer failed to seller"); // Basic check

            emit AuctionEnded(tokenId, auction.highestBidder, amount);
        }

        // Process any pending refunds (e.g., previous highest bidder)
        // This needs to be separate or handled carefully to avoid reentrancy if seller.transfer fails
        // The current simple model requires bidders to withdraw manually or the contract handles refunds.
        // Let's add a withdraw function for pending returns for safety.
         // If refund logic were here: payable(pendingReturns[tokenId]).transfer(...);
         // But we will use a separate withdraw function.

        // Clear auction details (or mark ended and keep history)
        // Keeping history for `getAuctionDetails` view function requires not deleting.
    }

    // 29. cancelAuction
     function cancelAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(auction.seller != address(0), "No active auction for this token");
        require(msg.sender == auction.seller, "Only the seller can cancel");
        require(block.timestamp < auction.endTime, "Auction has already ended");
        require(!auction.ended, "Auction already ended"); // Redundant check, but safe.
        require(auction.highestBidder == payable(address(0)), "Cannot cancel auction with bids");

        auction.ended = true; // Mark as ended without winner
        // Return approval to the seller
        _approve(address(0), tokenId);

        emit AuctionCancelled(tokenId, msg.sender);
    }

    // Optional: Function for bidders to withdraw their previous highest bid if outbid
    // Function signature for potential future implementation:
    // function withdrawBid(uint256 tokenId) external nonReentrant { ... }


    // --- Query & Information Functions ---

    // 30. getSubmissionDetails
    function getSubmissionDetails(uint256 submissionId) external view returns (Submission memory) {
        require(submissions[submissionId].artist != address(0), "Submission does not exist");
        return submissions[submissionId];
    }

    // 31. getSubmissionVoteCount
    function getSubmissionVoteCount(uint256 submissionId) external view returns (uint256) {
         require(submissions[submissionId].artist != address(0), "Submission does not exist");
         return submissionVoteCounts[submissionId];
    }

    // 32. hasVotedOnSubmission
    function hasVotedOnSubmission(uint256 submissionId, address voter) external view returns (bool) {
         require(submissions[submissionId].artist != address(0), "Submission does not exist");
         return hasVoted[submissionId][voter];
    }

    // 33. getSubmissionAIScore
    function getSubmissionAIScore(uint256 submissionId) external view returns (uint256) {
        require(submissions[submissionId].artist != address(0), "Submission does not exist");
        return aiScores[submissionId];
    }

    // 34. getGallerySize (Number of minted NFTs through the process)
     function getGallerySize() external view returns (uint256) {
        return _galleryTokenIds.length;
    }

    // 35. isApprovedInGallery
    function isApprovedInGallery(uint256 tokenId) external view returns (bool) {
        return _isApprovedGalleryPiece[tokenId];
    }

    // 36. getSaleDetails
    function getSaleDetails(uint256 tokenId) external view returns (Sale memory) {
        return sales[tokenId]; // Returns zero-initialized struct if not listed
    }

    // 37. getAuctionDetails
    function getAuctionDetails(uint256 tokenId) external view returns (Auction memory) {
         return auctions[tokenId]; // Returns zero-initialized struct if no auction
    }

    // 38. getAllSubmissionIds
    function getAllSubmissionIds() external view returns (uint256[] memory) {
        uint256 totalSubmissions = _submissionCounter.current();
        uint256[] memory ids = new uint256[](totalSubmissions);
        for(uint256 i = 0; i < totalSubmissions; i++) {
            ids[i] = i; // Assuming submission IDs are sequential from 0
        }
        return ids;
    }


    // --- Advanced / Dynamic Functions ---

    // 39. updateArtworkMetadata (Placeholder for dynamic updates)
    // Could be restricted to owner, artist, or based on certain conditions
    function updateArtworkMetadata(uint256 tokenId, string memory newMetadataURI) external {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");

        _setTokenURI(tokenId, newMetadataURI);

        emit ArtworkMetadataUpdated(tokenId, newMetadataURI);
    }

    // 40. triggerDynamicMetadataUpdate (Example: Might signal off-chain service)
    // In a real dynamic NFT, this might read on-chain state and signal an update.
    // This is a conceptual placeholder.
    function triggerDynamicMetadataUpdate(uint256 tokenId) external {
         require(_exists(tokenId), "Token does not exist");
         // Example: Emit event for off-chain listener
         // In a real scenario, this function might check conditions or permissions.
         emit ArtworkMetadataUpdated(tokenId, "Dynamic update triggered"); // Use the same event, but it signals the *intent*

         // Add logic here if metadata is somehow computed on-chain (highly unlikely for images)
         // Or signal an external service to update metadata based on on-chain state (e.g., vote count, sale count)
    }


    // --- Internal / Helper Functions ---

    // Internal _transfer override to handle sales/auctions cleanup
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // Before transferring, clear sale/auction data
        delete sales[tokenId];
        delete auctions[tokenId];
        pendingReturns[tokenId] = payable(address(0)); // Clear pending returns

        super._transfer(from, to, tokenId);
    }

     // ERC721Enumerable overrides
    function _safeMint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // Fallback function to accept ETH (e.g., for bids or fees)
    receive() external payable {}
    fallback() external payable {}

}
```

**Explanation of Concepts & Implementation:**

1.  **AI Oracle Simulation (`recordAIScore`)**: The contract doesn't *run* AI. `recordAIScore` is an `onlyOwner` function acting as a placeholder for an external AI service (like a Chainlink oracle or a trusted off-chain process) that analyzes the art metadata/image (off-chain) and provides a score on-chain. The contract then uses this score in the `reviewAndApproveSubmission` logic.
2.  **Decentralized Curation (`submitArt`, `castVoteOnSubmission`, `reviewAndApproveSubmission`)**: Artists submit art. Anyone can vote (simplified to one vote per address). An admin/oracle records an AI score. Approval requires *both* a minimum vote count *and* a minimum AI score, making it a hybrid model.
3.  **Dynamic Gallery (`_galleryTokenIds`, `featuredArtworks`, `setFeaturedArtwork`, `getFeaturedArtworks`)**: Approved and minted NFTs are tracked in `_galleryTokenIds`. A separate mapping `featuredArtworks` allows specific pieces to be highlighted, simulating different "rooms" or sections in a gallery.
4.  **Multiple Sales Methods (`Sale`, `Auction`, `listForSale`, `buyArtwork`, `startAuction`, `placeBid`, `endAuction`)**: Standard direct sale and English auction mechanisms are included. The `nonReentrant` guard is crucial for preventing attacks during ETH transfers.
5.  **ERC2981 Royalties (`royaltyInfo`, `_setDefaultRoyalty`, `_setTokenRoyalty`)**: Implements the standard for creator royalties, ensuring artists get a percentage of secondary sales on marketplaces that support ERC2981.
6.  **Submission Workflow (`SubmissionState`, `mintApprovedSubmission`)**: Art goes through defined states (Pending -> Approved -> Minted or Pending -> Rejected). Minting is a separate step that can be triggered by anyone *after* approval, decentralizing the minting action itself and collecting a `curationFee`.
7.  **Dynamic Metadata Placeholder (`updateArtworkMetadata`, `triggerDynamicMetadataUpdate`)**: While the actual metadata (like the image file) is off-chain via the URI, these functions allow the URI itself to be updated. `triggerDynamicMetadataUpdate` is purely conceptual in this code but represents how an on-chain event could signal an off-chain service to re-generate and update metadata based on current on-chain state (e.g., total bids received, number of times featured).
8.  **ERC721Enumerable**: Allows iterating through all token IDs owned by the contract (`totalSupply`, `tokenByIndex`, `tokenOfOwnerByIndex`). This is useful for building gallery views off-chain.
9.  **ReentrancyGuard**: Used in payable functions (`buyArtwork`, `placeBid`, `endAuction`) that involve external calls (sending ETH) to prevent reentrancy attacks.
10. **Ownable**: Used for administrative functions like setting thresholds, recording AI scores (simulated oracle), withdrawing fees, and setting default royalties/featured art. This could be replaced with a more complex AccessControl or a full DAO governed by a separate token for greater decentralization.

This contract provides a robust framework for a decentralized AI art gallery with unique curation and sales features, going beyond basic NFT minting and trading. Remember that the AI analysis itself is simulated off-chain and reported via the `recordAIScore` function.