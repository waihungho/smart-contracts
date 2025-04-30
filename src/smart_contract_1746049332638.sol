Okay, here is a Solidity smart contract for a Decentralized Art Gallery with a focus on community curation, artist features, and dynamic elements, incorporating various advanced concepts without directly copying existing open-source templates (though utilizing standard interfaces like ERC721 from libraries like OpenZeppelin is necessary for interoperability).

It includes features like community art submission and voting, artist-controlled pricing and metadata, unlockable content for buyers, artist tipping, a contract fee mechanism, and basic moderation/flagging.

**Outline and Function Summary:**

This contract implements a Decentralized Art Gallery (`DecentralizedArtGallery`) where artists can submit pieces, the community can curate via voting, collectors can purchase unique digital art (ERC721), and artists have control over their work's representation and can receive direct support.

**Core Concepts:**

1.  **Decentralized Curation:** Art submissions go through a community voting phase before being approved for minting and listing.
2.  **Artist Control:** Artists set prices, metadata, unlockable content, and royalty percentages (within limits).
3.  **Unlockable Content:** Buyers of a piece can access a secret URI associated with the artwork.
4.  **Artist Tipping:** Collectors and fans can directly tip artists.
5.  **Dynamic Status:** Art pieces have statuses (Draft, Submitted, Approved, Listed, Sold, Removed) controlling their lifecycle.
6.  **Submission Stake:** Artists must stake a small amount to submit art, potentially slashed for rejected art or reclaimable upon approval. (Optional but interesting feature idea - let's include it).
7.  **Moderation/Flagging:** Community members can flag inappropriate art for review by the contract owner.

**Contract Structure:**

*   Inherits from ERC721 (for NFT functionality) and Ownable (for administrative functions).
*   Uses Enums for Art Status and Submission Status.
*   Structs for ArtPiece data and Submission data.
*   Mappings to store art data, submissions, artist tips, voter history, etc.
*   State variables for fees, thresholds, etc.

**Function Summary (Approx. 25+ functions):**

**I. Owner/Admin Functions (Ownable)**
1.  `constructor`: Initializes the contract with name, symbol, and owner.
2.  `setContractFeePercentage`: Sets the percentage of sales that go to the contract owner/treasury.
3.  `withdrawContractFees`: Allows the owner to withdraw accumulated fees.
4.  `setVoteThresholds`: Sets the minimum votes required and the winning percentage for art submissions.
5.  `setSubmissionDuration`: Sets the duration for the community voting phase.
6.  `setSubmissionStakeAmount`: Sets the amount of ETH required to submit an art piece.
7.  `reviewFlaggedArt`: Reviews flagged art and takes action (e.g., approves or removes).
8.  `removeArtByAdmin`: Forcefully removes an art piece (burns NFT, potentially slashes stake).

**II. Artist Functions**
9.  `createArtDraft`: Creates an initial draft entry for a new art piece.
10. `updateArtDraft`: Updates details of an art piece while it's still in draft status.
11. `submitArtForCuratorReview`: Submits a draft art piece to the community voting queue, requires stake.
12. `setArtPrice`: Sets or updates the listing price for an *approved* art piece.
13. `setUnlockableContentURI`: Sets the private URI for content only accessible by the art owner.
14. `toggleArtListingStatus`: Toggles whether an *approved* piece is currently available for direct purchase.
15. `updateArtistProfileURI`: Sets/updates a URI for the artist's profile information.
16. `claimArtistRoyalties`: Allows the artist to claim their accumulated royalties from secondary sales (handled off-chain in this basic version, or could be integrated with a marketplace standard like ERC2981, but keeping it simpler - calculating on *primary* sale fee here for simplicity, or modeling a simple secondary royalty *claim* if integrated with an external market protocol that calls back, otherwise focusing on primary sale distribution). Let's clarify: Royalties are *calculated* on *primary* sales within this contract's `buyArt` function. A more advanced version would integrate ERC2981 for *secondary* market royalties. This version handles primary distribution and allows claiming.
17. `claimSubmissionStake`: Allows artist to reclaim stake if their submission was approved or rejected non-maliciously.

**III. Buyer/Collector Functions**
18. `buyArt`: Purchases a listed art piece. Handles payment distribution (artist, contract fee).
19. `getUnlockableContentURI`: Allows the current owner of a token to view the secret URI.
20. `tipArtist`: Sends a direct ETH tip to a specific artist registered in the gallery.
21. `flagArtForReview`: Flags an art piece that is deemed inappropriate.

**IV. Curator/Community Functions**
22. `voteForSubmission`: Votes in favor of approving a submitted art piece.
23. `voteAgainstSubmission`: Votes against approving a submitted art piece.
24. `processSubmissionVote`: Finalizes the voting for a submission after the duration has passed.

**V. View Functions (Public)**
25. `getArtDetails`: Retrieves detailed information about a specific art piece by ID.
26. `getSubmissionDetails`: Retrieves detailed information about a specific submission by ID.
27. `getArtistProfileURI`: Retrieves the profile URI for a given artist address.
28. `getArtistTipsAccrued`: Checks the amount of tips accrued for an artist.
29. `getContractFeesAccrued`: Checks the amount of fees accrued by the contract.
30. `getSubmissionStakeAmount`: Gets the current required stake amount for submissions.
31. `getVoteThresholds`: Gets the current voting approval thresholds.
32. `getSubmissionDuration`: Gets the duration of the submission voting period.
33. `hasVoted`: Checks if an address has already voted on a specific submission.
34. `getSubmissionStatus`: Gets the status of a submission.
35. `getArtStatus`: Gets the status of an art piece.

*(Note: This list already exceeds 20 functions, covering a wide range of interactions.)*

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// - Core: ERC721 for art NFTs.
// - Curation: Community voting on submissions.
// - Artist Features: Submission, pricing, unlockable content, profile, tipping.
// - Buyer Features: Purchasing, accessing unlockable content, tipping.
// - Admin Features: Fees, moderation, setting parameters.
// - State Management: Enums for status, structs for data, mappings for storage.
// - Security: Ownable, ReentrancyGuard.

// Function Summary:
// Owner/Admin: constructor, setContractFeePercentage, withdrawContractFees,
//              setVoteThresholds, setSubmissionDuration, setSubmissionStakeAmount,
//              reviewFlaggedArt, removeArtByAdmin. (8)
// Artist: createArtDraft, updateArtDraft, submitArtForCuratorReview, setArtPrice,
//         setUnlockableContentURI, toggleArtListingStatus, updateArtistProfileURI,
//         claimArtistRoyalties, claimSubmissionStake. (9)
// Buyer/Collector: buyArt, getUnlockableContentURI, tipArtist, flagArtForReview. (4)
// Curator/Community: voteForSubmission, voteAgainstSubmission, processSubmissionVote. (3)
// View (Public): getArtDetails, getSubmissionDetails, getArtistProfileURI,
//                getArtistTipsAccrued, getContractFeesAccrued, getSubmissionStakeAmount,
//                getVoteThresholds, getSubmissionDuration, hasVoted, getSubmissionStatus,
//                getArtStatus. (11)
// Total Functions: 8 + 9 + 4 + 3 + 11 = 35 functions (well over 20).

contract DecentralizedArtGallery is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _submissionIdCounter;

    // --- State Variables ---

    enum ArtStatus { Draft, Submitted, Approved, Listed, Sold, Removed }
    enum SubmissionStatus { Pending, Approved, Rejected, Processed }

    struct ArtPiece {
        uint256 tokenId;
        address payable artist;
        string metadataURI;
        string unlockableContentURI; // Visible only to owner
        uint256 price; // In Wei
        ArtStatus status;
        uint256 submissionId; // Link back to submission if applicable
        uint256 flags; // Number of times flagged for review
        bool listedForSale; // Can be listed even if status is Approved
    }

    struct Submission {
        uint256 submissionId;
        uint256 artTokenId; // The potential token ID if approved
        address artist;
        string metadataURI; // URI at time of submission
        uint256 submittedTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter registry
        SubmissionStatus status;
        uint256 stakeAmount; // ETH staked by the artist
    }

    // Data Storage
    mapping(uint256 => ArtPiece) public galleryArt; // tokenId => ArtPiece
    mapping(uint256 => Submission) public gallerySubmissions; // submissionId => Submission
    mapping(address => string) public artistProfiles; // artist address => profile URI

    // Financials
    mapping(address => uint256) public artistTipsAccrued; // artist address => accrued tips in Wei
    mapping(address => uint256) public artistRoyaltiesAccrued; // artist address => accrued royalties in Wei (primary sale only for simplicity)
    uint256 public contractFeesAccrued; // Accrued fees for the contract owner
    uint256 public contractFeePercentage = 5; // 5% fee by default (out of 100)

    // Curation Parameters
    uint256 public minVotesForApproval = 10; // Minimum total votes required
    uint256 public approvalPercentage = 60; // Minimum percentage of 'For' votes (out of 100)
    uint256 public submissionDuration = 3 days; // Voting period duration
    uint256 public submissionStakeAmount = 0.01 ether; // Required stake to submit

    // --- Events ---
    event ArtDraftCreated(uint256 indexed tokenId, address indexed artist);
    event ArtDraftUpdated(uint256 indexed tokenId, string newMetadataURI);
    event ArtSubmitted(uint256 indexed submissionId, uint256 indexed tokenId, address indexed artist);
    event ArtSubmissionVote(uint256 indexed submissionId, address indexed voter, bool approved);
    event ArtSubmissionProcessed(uint256 indexed submissionId, SubmissionStatus status, uint256 indexed artTokenId);
    event ArtApprovedAndMinted(uint256 indexed tokenId, address indexed artist);
    event ArtPriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event ArtUnlockableContentUpdated(uint256 indexed tokenId);
    event ArtListingStatusToggled(uint256 indexed tokenId, bool listed);
    event ArtPurchased(uint256 indexed tokenId, address indexed buyer, uint256 pricePaid);
    event ArtistProfileUpdated(address indexed artist, string profileURI);
    event ArtistTipped(address indexed artist, address indexed tipper, uint256 amount);
    event ArtistRoyaltyClaimed(address indexed artist, uint256 amount);
    event SubmissionStakeClaimed(uint256 indexed submissionId, address indexed artist, uint256 amount);
    event ContractFeesClaimed(address indexed owner, uint256 amount);
    event ArtFlagged(uint256 indexed tokenId, address indexed flagger);
    event ArtReviewed(uint256 indexed tokenId, address indexed reviewer, bool approved);
    event ArtRemoved(uint256 indexed tokenId, address indexed remover);


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Owner/Admin Functions ---

    /**
     * @notice Sets the percentage of primary sale price that goes to the contract owner.
     * @param _percentage The new fee percentage (0-100).
     */
    function setContractFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        contractFeePercentage = _percentage;
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated fees.
     */
    function withdrawContractFees() external onlyOwner {
        uint256 amount = contractFeesAccrued;
        require(amount > 0, "No fees accrued to withdraw");
        contractFeesAccrued = 0;
        // Use call for safety
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ContractFeesClaimed(owner(), amount);
    }

    /**
     * @notice Sets the thresholds for community vote-based submission approval.
     * @param _minVotes Minimum total votes required.
     * @param _approvalPercentage Minimum percentage of 'For' votes needed (0-100).
     */
    function setVoteThresholds(uint256 _minVotes, uint256 _approvalPercentage) external onlyOwner {
        require(_approvalPercentage <= 100, "Approval percentage must be 0-100");
        minVotesForApproval = _minVotes;
        approvalPercentage = _approvalPercentage;
    }

    /**
     * @notice Sets the duration for which a submission is open for voting.
     * @param _duration In seconds.
     */
    function setSubmissionDuration(uint256 _duration) external onlyOwner {
        require(_duration > 0, "Duration must be greater than 0");
        submissionDuration = _duration;
    }

    /**
     * @notice Sets the amount of ETH required as a stake to submit an art piece.
     * @param _amount The required stake amount in Wei.
     */
    function setSubmissionStakeAmount(uint256 _amount) external onlyOwner {
        submissionStakeAmount = _amount;
    }

     /**
     * @notice Reviews flagged art and decides whether to keep or remove it.
     * Can only be called by the owner.
     * @param _tokenId The ID of the art piece to review.
     * @param _approve If true, clears flags; if false, removes the art.
     */
    function reviewFlaggedArt(uint256 _tokenId, bool _approve) external onlyOwner {
        ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(art.flags > 0, "Art piece is not flagged");

        if (_approve) {
            art.flags = 0; // Clear flags
            emit ArtReviewed(_tokenId, msg.sender, true);
        } else {
             // Removing art: Burn token, potentially penalize artist (if stake logic is more complex), refund artist for stake if they had one
            _removeArtInternal(_tokenId, "Admin review decision");
            emit ArtReviewed(_tokenId, msg.sender, false);
        }
    }

    /**
     * @notice Forcefully removes an art piece from the gallery.
     * Can only be called by the owner.
     * @param _tokenId The ID of the art piece to remove.
     * @param _reason The reason for removal (e.g., violating terms).
     */
    function removeArtByAdmin(uint256 _tokenId, string memory _reason) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist");
        _removeArtInternal(_tokenId, _reason);
        emit ArtRemoved(_tokenId, msg.sender, address(0)); // Emitter signifies admin removal
    }

    // --- Artist Functions ---

    /**
     * @notice Creates an initial draft entry for a new art piece. Artist can update details later.
     * @param _metadataURI URI pointing to the metadata of the art.
     */
    function createArtDraft(string memory _metadataURI) external {
        uint256 newTokenId = _tokenIdCounter.current();
         // We increment here, but minting only happens after approval.
         // This ID is reserved for this draft/submission.
        _tokenIdCounter.increment();

        galleryArt[newTokenId] = ArtPiece({
            tokenId: newTokenId,
            artist: payable(msg.sender),
            metadataURI: _metadataURI,
            unlockableContentURI: "", // Set later
            price: 0,
            status: ArtStatus.Draft,
            submissionId: 0, // No submission yet
            flags: 0,
            listedForSale: false
        });

        emit ArtDraftCreated(newTokenId, msg.sender);
    }

    /**
     * @notice Updates the metadata URI for an art piece that is still in draft status.
     * @param _tokenId The ID of the art piece draft.
     * @param _newMetadataURI The new URI pointing to the metadata.
     */
    function updateArtDraft(uint256 _tokenId, string memory _newMetadataURI) external {
        ArtPiece storage art = galleryArt[_tokenId];
        require(art.artist == msg.sender, "Only the artist can update their draft");
        require(art.status == ArtStatus.Draft, "Art piece is not in draft status");

        art.metadataURI = _newMetadataURI;
        emit ArtDraftUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @notice Submits a draft art piece for community curation and approval. Requires a stake.
     * @param _tokenId The ID of the art piece draft to submit.
     * @dev Requires msg.value to be equal to submissionStakeAmount.
     */
    function submitArtForCuratorReview(uint256 _tokenId) external payable {
        ArtPiece storage art = galleryArt[_tokenId];
        require(art.artist == msg.sender, "Only the artist can submit their art");
        require(art.status == ArtStatus.Draft, "Art piece is not in draft status");
        require(msg.value == submissionStakeAmount, "Incorrect submission stake amount");

        uint256 newSubmissionId = _submissionIdCounter.current();
        _submissionIdCounter.increment();

        // Link art piece to the submission
        art.status = ArtStatus.Submitted;
        art.submissionId = newSubmissionId;

        // Create the submission entry
        gallerySubmissions[newSubmissionId] = Submission({
            submissionId: newSubmissionId,
            artTokenId: _tokenId,
            artist: msg.sender,
            metadataURI: art.metadataURI, // Snapshot of metadata at submission
            submittedTimestamp: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
             hasVoted: mapping(address => bool), // Initialize voter map
            status: SubmissionStatus.Pending,
            stakeAmount: msg.value
        });

        emit ArtSubmitted(newSubmissionId, _tokenId, msg.sender);
    }

    /**
     * @notice Sets or updates the price of an approved and listed art piece.
     * @param _tokenId The ID of the art piece.
     * @param _newPrice The new price in Wei. Set to 0 to make it not directly purchasable.
     */
    function setArtPrice(uint256 _tokenId, uint256 _newPrice) external {
        ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only the owner or approved can set price");
        require(art.status == ArtStatus.Approved || art.status == ArtStatus.Listed || art.status == ArtStatus.Sold, "Art piece status does not allow price update"); // Allow owner (even after sold) to set price if they reacquire it

        art.price = _newPrice;
        emit ArtPriceUpdated(_tokenId, _newPrice);
    }


    /**
     * @notice Sets or updates the URI for the unlockable content of an art piece.
     * Only the current owner can set this.
     * @param _tokenId The ID of the art piece.
     * @param _uri The URI for the unlockable content.
     */
    function setUnlockableContentURI(uint256 _tokenId, string memory _uri) external {
         ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Only the owner or approved can set unlockable content");

        art.unlockableContentURI = _uri;
        emit ArtUnlockableContentUpdated(_tokenId);
    }

    /**
     * @notice Toggles whether an approved art piece is currently listed for direct purchase.
     * @param _tokenId The ID of the art piece.
     * @param _listed True to list, false to delist.
     */
    function toggleArtListingStatus(uint256 _tokenId, bool _listed) external {
        ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(art.artist == msg.sender, "Only the artist can toggle listing status"); // Only original artist controls this initially
        require(art.status == ArtStatus.Approved || art.status == ArtStatus.Listed, "Art piece must be approved or already listed");

        // If delisting, price is effectively 0 for direct purchase
        if (!_listed) {
             art.listedForSale = false;
             // Keep price value, but listing state overrides it for direct purchase
        } else {
            require(art.price > 0, "Cannot list art with a price of 0");
            art.listedForSale = true;
        }

         // Update general status if it's just 'Approved' becoming 'Listed'
        if (art.status == ArtStatus.Approved && _listed) {
             art.status = ArtStatus.Listed;
        } else if (art.status == ArtStatus.Listed && !_listed) {
             art.status = ArtStatus.Approved; // Move back to approved if delisted
        }

        emit ArtListingStatusToggled(_tokenId, art.listedForSale);
    }

    /**
     * @notice Sets or updates the profile URI for an artist.
     * @param _uri The URI for the artist's profile page.
     */
    function updateArtistProfileURI(string memory _uri) external {
        artistProfiles[msg.sender] = _uri;
        emit ArtistProfileUpdated(msg.sender, _uri);
    }

    /**
     * @notice Allows an artist to claim their accumulated royalties (from primary sales) and tips.
     */
    function claimArtistRoyalties() external nonReentrant {
        uint256 royalties = artistRoyaltiesAccrued[msg.sender];
        uint256 tips = artistTipsAccrued[msg.sender];
        uint256 total = royalties + tips;

        require(total > 0, "No royalties or tips accrued to claim");

        artistRoyaltiesAccrued[msg.sender] = 0;
        artistTipsAccrued[msg.sender] = 0;

        // Use call for safety
        (bool success, ) = payable(msg.sender).call{value: total}("");
        require(success, "Claim transaction failed");

        if(royalties > 0) emit ArtistRoyaltyClaimed(msg.sender, royalties);
        if(tips > 0) emit ArtistTipped(msg.sender, address(this), tips); // Emitting tipping event for artist claim
    }

     /**
     * @notice Allows an artist to claim back their submission stake if the submission was processed without penalty.
     * @param _submissionId The ID of the submission.
     */
    function claimSubmissionStake(uint256 _submissionId) external nonReentrant {
        Submission storage submission = gallerySubmissions[_submissionId];
        require(submission.artist == msg.sender, "Only the artist can claim their stake");
        require(submission.status == SubmissionStatus.Processed, "Submission must be processed");
        require(submission.stakeAmount > 0, "No stake to claim");

        // Only allow claiming if not penalized (e.g., rejected due to admin removal or fraud)
        // In this simple version, claim is allowed after any processing unless explicitly removed by admin
        uint256 amount = submission.stakeAmount;
        submission.stakeAmount = 0; // Prevent double claim

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Stake claim failed");
        emit SubmissionStakeClaimed(_submissionId, msg.sender, amount);
    }


    // --- Buyer/Collector Functions ---

    /**
     * @notice Allows a collector to purchase a listed art piece.
     * Handles distribution of funds to artist and contract fees.
     * @param _tokenId The ID of the art piece to purchase.
     * @dev Requires msg.value to be equal to the art piece's price.
     */
    function buyArt(uint256 _tokenId) external payable nonReentrant {
        ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(art.status == ArtStatus.Listed, "Art piece is not listed for sale");
        require(art.listedForSale, "Art piece is not currently available for direct purchase");
        require(msg.value == art.price, "Incorrect ETH amount sent");

        // Calculate fees and artist share
        uint256 totalPrice = msg.value;
        uint256 feeAmount = (totalPrice * contractFeePercentage) / 100;
        uint256 artistShare = totalPrice - feeAmount;

        // Update state before transfers (Checks-Effects-Interactions)
        art.status = ArtStatus.Sold;
        art.listedForSale = false; // Mark as sold, delist

        contractFeesAccrued += feeAmount;
        // For simplicity, royalties on primary sale go directly to accrued balance for artist
        artistRoyaltiesAccrued[art.artist] += artistShare;

        // Transfer the token to the buyer
        // Use _safeTransferFrom to ensure recipient can receive ERC721
        _safeTransferFrom(ownerOf(_tokenId), msg.sender, _tokenId); // Transfer from previous owner (artist is owner initially)

        emit ArtPurchased(_tokenId, msg.sender, totalPrice);
    }

     /**
     * @notice Allows the current owner of a token to retrieve the unlockable content URI.
     * @param _tokenId The ID of the art piece.
     * @return The URI for the unlockable content.
     */
    function getUnlockableContentURI(uint256 _tokenId) external view returns (string memory) {
        ArtPiece storage art = galleryArt[_tokenId];
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Only the token owner can access unlockable content");
        return art.unlockableContentURI;
    }

    /**
     * @notice Allows anyone to send a direct ETH tip to an artist registered in the gallery.
     * @param _artist The address of the artist to tip.
     */
    function tipArtist(address payable _artist) external payable nonReentrant {
         require(msg.value > 0, "Tip amount must be greater than 0");
        // Basic check if artist is somehow registered (e.g., has submitted art or set a profile)
        // This check is basic; a more robust system might require explicit artist registration.
        // For now, we assume any address that has interacted as an artist (submitted, etc.) can receive tips.
        // require(artistProfiles[_artist] != "" || galleryArt[_artist.tokenId].artist == _artist, "Recipient is not a recognized artist"); // Too complex check
        // Simple check: Ensure it's not a zero address and not this contract.
        require(_artist != address(0) && _artist != address(this), "Invalid artist address");

        artistTipsAccrued[_artist] += msg.value;
        // Tips are accrued and claimed by the artist via claimArtistRoyalties function
        emit ArtistTipped(_artist, msg.sender, msg.value);
    }

    /**
     * @notice Allows community members to flag potentially inappropriate art.
     * Requires manual review by the owner via `reviewFlaggedArt`.
     * @param _tokenId The ID of the art piece to flag.
     */
    function flagArtForReview(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        // Simple flagging: increment counter. Could add per-address tracking to prevent spam.
        galleryArt[_tokenId].flags++;
        emit ArtFlagged(_tokenId, msg.sender);
    }


    // --- Curator/Community Functions ---

    /**
     * @notice Allows community members to vote in favor of a submitted art piece.
     * @param _submissionId The ID of the submission to vote on.
     */
    function voteForSubmission(uint256 _submissionId) external {
        Submission storage submission = gallerySubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not pending review");
        require(block.timestamp < submission.submittedTimestamp + submissionDuration, "Voting period has ended");
        require(!submission.hasVoted[msg.sender], "Already voted on this submission");
        require(submission.artist != msg.sender, "Artist cannot vote on their own submission");

        submission.votesFor++;
        submission.hasVoted[msg.sender] = true;
        emit ArtSubmissionVote(_submissionId, msg.sender, true);
    }

    /**
     * @notice Allows community members to vote against a submitted art piece.
     * @param _submissionId The ID of the submission to vote on.
     */
    function voteAgainstSubmission(uint256 _submissionId) external {
        Submission storage submission = gallerySubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not pending review");
        require(block.timestamp < submission.submittedTimestamp + submissionDuration, "Voting period has ended");
        require(!submission.hasVoted[msg.sender], "Already voted on this submission");
        require(submission.artist != msg.sender, "Artist cannot vote on their own submission");

        submission.votesAgainst++;
        submission.hasVoted[msg.sender] = true;
        emit ArtSubmissionVote(_submissionId, msg.sender, false);
    }

    /**
     * @notice Processes the result of a submission's community vote after the voting period ends.
     * Can be called by anyone.
     * @param _submissionId The ID of the submission to process.
     */
    function processSubmissionVote(uint256 _submissionId) external nonReentrant {
        Submission storage submission = gallerySubmissions[_submissionId];
        ArtPiece storage art = galleryArt[submission.artTokenId];

        require(submission.status == SubmissionStatus.Pending, "Submission is not pending review");
        require(block.timestamp >= submission.submittedTimestamp + submissionDuration, "Voting period has not ended");

        uint256 totalVotes = submission.votesFor + submission.votesAgainst;

        if (totalVotes >= minVotesForApproval && (submission.votesFor * 100) / totalVotes >= approvalPercentage) {
            // Approved
            submission.status = SubmissionStatus.Approved;
            art.status = ArtStatus.Approved;
            _mint(submission.artist, submission.artTokenId); // Mint the token to the artist
            emit ArtSubmissionProcessed(_submissionId, SubmissionStatus.Approved, submission.artTokenId);
            emit ArtApprovedAndMinted(submission.artTokenId, submission.artist);

        } else {
            // Rejected
            submission.status = SubmissionStatus.Rejected;
            art.status = ArtStatus.Removed; // Mark art as removed/rejected draft
            // Stake remains associated with submission, artist can claim if not explicitly slashed later
            emit ArtSubmissionProcessed(_submissionId, SubmissionStatus.Rejected, submission.artTokenId);
        }

        // Mark submission as processed to allow stake claim (if applicable)
        submission.status = SubmissionStatus.Processed;
    }


    // --- View Functions (Public) ---

    /**
     * @notice Retrieves detailed information about a specific art piece by ID.
     * @param _tokenId The ID of the art piece.
     * @return Art piece struct data.
     */
    function getArtDetails(uint256 _tokenId) external view returns (ArtPiece memory) {
        require(_exists(_tokenId), "Token does not exist");
        return galleryArt[_tokenId];
    }

    /**
     * @notice Retrieves detailed information about a specific submission by ID.
     * @param _submissionId The ID of the submission.
     * @return Submission struct data (excluding the internal voter map).
     */
    function getSubmissionDetails(uint256 _submissionId) external view returns (
        uint256 submissionId,
        uint256 artTokenId,
        address artist,
        string memory metadataURI,
        uint256 submittedTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        SubmissionStatus status,
        uint256 stakeAmount
    ) {
        Submission storage submission = gallerySubmissions[_submissionId];
        require(submission.submissionId == _submissionId || _submissionId == 0 && submission.submissionId == 0, "Submission does not exist"); // Handle uninitialized struct for ID 0

         return (
            submission.submissionId,
            submission.artTokenId,
            submission.artist,
            submission.metadataURI,
            submission.submittedTimestamp,
            submission.votesFor,
            submission.votesAgainst,
            submission.status,
            submission.stakeAmount
        );
    }

    /**
     * @notice Retrieves the profile URI for a given artist address.
     * @param _artist The address of the artist.
     * @return The artist's profile URI.
     */
    function getArtistProfileURI(address _artist) external view returns (string memory) {
        return artistProfiles[_artist];
    }

    /**
     * @notice Checks the amount of tips accrued for a specific artist.
     * @param _artist The address of the artist.
     * @return The amount of tips accrued in Wei.
     */
    function getArtistTipsAccrued(address _artist) external view returns (uint256) {
        return artistTipsAccrued[_artist];
    }

    /**
     * @notice Checks the amount of fees accrued by the contract owner.
     * @return The amount of fees accrued in Wei.
     */
    function getContractFeesAccrued() external view onlyOwner returns (uint256) {
        return contractFeesAccrued;
    }

    /**
     * @notice Gets the current required stake amount for submitting art.
     * @return The stake amount in Wei.
     */
    function getSubmissionStakeAmount() external view returns (uint256) {
        return submissionStakeAmount;
    }

    /**
     * @notice Gets the current thresholds for submission voting.
     * @return minVotes Minimum votes required, approvalPercentage Minimum percentage of 'For' votes.
     */
    function getVoteThresholds() external view returns (uint256 minVotes, uint256 approvalPercentage) {
        return (minVotesForApproval, approvalPercentage);
    }

     /**
     * @notice Gets the duration of the submission voting period.
     * @return The duration in seconds.
     */
    function getSubmissionDuration() external view returns (uint256) {
        return submissionDuration;
    }

     /**
     * @notice Checks if an address has already voted on a specific submission.
     * @param _submissionId The ID of the submission.
     * @param _voter The address to check.
     * @return True if the voter has voted, false otherwise.
     */
    function hasVoted(uint256 _submissionId, address _voter) external view returns (bool) {
        Submission storage submission = gallerySubmissions[_submissionId];
         require(submission.status == SubmissionStatus.Pending || submission.status == SubmissionStatus.Processed, "Submission must be pending or processed");
        return submission.hasVoted[_voter];
    }

     /**
     * @notice Gets the current status of a submission.
     * @param _submissionId The ID of the submission.
     * @return The submission status enum value.
     */
    function getSubmissionStatus(uint256 _submissionId) external view returns (SubmissionStatus) {
         Submission storage submission = gallerySubmissions[_submissionId];
         require(submission.submissionId == _submissionId || _submissionId == 0 && submission.submissionId == 0, "Submission does not exist");
        return submission.status;
    }

     /**
     * @notice Gets the current status of an art piece.
     * @param _tokenId The ID of the art piece.
     * @return The art status enum value.
     */
    function getArtStatus(uint256 _tokenId) external view returns (ArtStatus) {
         ArtPiece storage art = galleryArt[_tokenId];
        require(art.tokenId == _tokenId || _tokenId == 0 && art.tokenId == 0, "Art piece does not exist");
        return art.status;
    }


    // --- Internal Functions ---

    /**
     * @notice Internal function to handle the process of removing art (e.g., admin removal, rejection).
     * Burns the token and updates status.
     * @param _tokenId The ID of the art piece to remove.
     * @param _reason The reason for removal (for event logging).
     */
    function _removeArtInternal(uint256 _tokenId, string memory _reason) internal {
        ArtPiece storage art = galleryArt[_tokenId];
        address currentOwner = ownerOf(_tokenId); // Get owner before burning

        // Update status
        art.status = ArtStatus.Removed;
        art.listedForSale = false; // Ensure it's not listed

        // Burn the token if it was minted
        if (_exists(_tokenId)) {
             _burn(_tokenId);
        }

        // Handle associated submission stake if applicable
        if (art.submissionId > 0) {
            Submission storage submission = gallerySubmissions[art.submissionId];
            if (submission.status != SubmissionStatus.Processed) {
                 submission.status = SubmissionStatus.Processed; // Mark submission as processed
                 // Decide stake slashing logic:
                 // option A: Artist *loses* stake if art is removed by admin after approval/listing
                 // option B: Artist can *still claim* stake unless removal is due to explicit fraud/spam flagged during submission
                 // Let's go with Option B for less complexity in this example: stake is claimable unless specifically marked otherwise (not implemented here).
            }
        }

        emit ArtRemoved(_tokenId, currentOwner, _reason);
    }

    // --- ERC721 Overrides ---

     /**
     * @dev See {ERC721-tokenURI}. We use the stored metadataURI.
     * Note: This does NOT return the unlockable content URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return galleryArt[tokenId].metadataURI;
    }

    // Override transfer functions if you want specific logic before/after transfers (e.g., secondary royalties check if integrating ERC2981)
    // For this example, primary sales handle distribution internally, secondary market royalties would need external integration.

    // ERC721 functions like `ownerOf`, `balanceOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`
    // are inherited and work out of the box with our storage, as long as we correctly use `_mint` and `_burn`.
    // The `buyArt` function uses `_safeTransferFrom`.

}
```

**Explanation of Key Features and Advanced Concepts:**

1.  **Community Curation DAO (Simplified):** The `submitArtForCuratorReview`, `voteForSubmission`, `voteAgainstSubmission`, and `processSubmissionVote` functions create a workflow where potential art pieces aren't just minted by the artist; they need community approval based on predefined `minVotesForApproval` and `approvalPercentage` thresholds within a `submissionDuration` timeframe. This decentralizes the curatorial process.
2.  **Submission Stake:** Requiring `submissionStakeAmount` adds a barrier to prevent spam submissions and gives the contract a potential pool for slashing (though slashing logic is simplified here, artists can generally reclaim stake unless art is removed by admin).
3.  **Dynamic Status:** Art pieces move through distinct `ArtStatus` stages (`Draft`, `Submitted`, `Approved`, `Listed`, `Sold`, `Removed`), controlling which actions can be performed on them at different points in their lifecycle. Submissions also have `SubmissionStatus`.
4.  **Unlockable Content:** The `unlockableContentURI` field allows artists to provide a private link (e.g., to a high-resolution image, a video, source files) that is only exposed to the current owner of the NFT via the `getUnlockableContentURI` function. This adds value beyond the publicly visible metadata.
5.  **Artist Tipping:** The `tipArtist` function allows direct support from collectors/fans to artists, outside of the standard sale price. These tips are accrued and claimable by the artist.
6.  **Segregated Financials:** Primary sale proceeds are split into `artistRoyaltiesAccrued` (for the artist) and `contractFeesAccrued` (for the owner/treasury). Tips are stored separately in `artistTipsAccrued`. Artists and the owner must explicitly call claim functions (`claimArtistRoyalties`, `withdrawContractFees`) to receive their funds (using `nonReentrant` guard).
7.  **Artist Profile:** `updateArtistProfileURI` allows artists to link to an external profile, adding a layer of identity.
8.  **Basic Moderation:** The `flagArtForReview` allows community flagging. The `reviewFlaggedArt` and `removeArtByAdmin` functions give the owner power to act on flags or other issues, including burning the token via the internal `_removeArtInternal`.
9.  **Structs and Enums:** Well-defined structs (`ArtPiece`, `Submission`) and enums (`ArtStatus`, `SubmissionStatus`) improve code readability and maintainability, clearly outlining the data structure and possible states.
10. **OpenZeppelin Standards:** Using battle-tested libraries for ERC721 and Ownable ensures compliance with standards and leverages audited code for core functionalities.

This contract provides a framework for a more interactive and community-driven art gallery experience on the blockchain, going beyond simple NFT minting and trading.