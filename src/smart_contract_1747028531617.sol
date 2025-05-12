Okay, let's design a smart contract for a curated digital art gallery with dynamic properties, curation, membership, and a built-in marketplace. This combines aspects of NFTs, governance, staking, and on-chain interactivity in a unique way.

We'll call it `CryptoArtGallery`.

**Concept:**

A decentralized gallery where artists submit art proposals (represented by metadata/URIs), curators vote on submissions, approved art is minted as dynamic NFTs, collectors can buy/sell these NFTs within the gallery, and users can stake tokens to become members and gain privileges (like curator nomination or reduced fees). The art itself can have properties that change based on gallery activity or curator votes.

**Outline:**

1.  **Contract Definition:** Inherit necessary interfaces (ERC721, potentially ERC721Enumerable, Ownable, ReentrancyGuard).
2.  **State Variables:** Store gallery configuration, token counter, mappings for art details, owners, approvals, marketplace listings, submissions, curators, member stakes, fees, etc.
3.  **Structs:** Define data structures for Art Pieces, Submissions, Listings, Art Properties, and potentially Art History entries.
4.  **Events:** Announce key actions (Minting, Transfer, Listing, Sale, Curation actions, Membership changes, Fee withdrawals).
5.  **Modifiers:** Enforce access control (`onlyOwner`, `onlyCurator`, `onlyMember`, `onlyArtOwner`, `whenNotPaused`).
6.  **ERC721 Implementation:** Core NFT functions (minting, transfer, approval, ownership). Override `tokenURI` for dynamic properties.
7.  **Curation System:** Functions for submitting art, voting on submissions, managing curators, setting curation thresholds.
8.  **Dynamic Art System:** Structures and logic to store and update dynamic properties of art pieces. A function to trigger property evolution (e.g., based on sales, votes, time). Custom `tokenURI` generation based on static and dynamic properties.
9.  **Gallery Membership & Staking:** Functions to stake tokens for membership, check membership status, manage stake.
10. **Internal Marketplace:** Functions to list art for sale, buy art, cancel listings, calculate fees and royalties.
11. **Fee & Royalty Management:** Functions to set rates and withdraw accumulated fees/royalties.
12. **Admin/Configuration:** Functions for the owner/governance to configure gallery parameters.
13. **Query Functions:** Read-only functions to retrieve gallery state, art details, listings, submissions, etc.

**Function Summary (More than 20):**

1.  `constructor(string memory name, string memory symbol, uint256 initialStakeThreshold)`: Initializes the gallery, NFT collection, and membership stake requirement.
2.  `submitArtForCuration(string memory _metadataURI, address _artist)`: Allows an artist (or proposer) to submit a piece for curator review.
3.  `voteOnSubmission(uint256 _submissionId, bool _approve)`: Allows a curator to vote on a specific art submission.
4.  `addCurator(address _curator)`: Owner/Governance adds a new curator.
5.  `removeCurator(address _curator)`: Owner/Governance removes a curator.
6.  `stakeForMembership(uint256 _amount)`: Allows a user to stake tokens to meet the membership threshold.
7.  `unstakeMembership()`: Allows a member to unstake their tokens (requires meeting minimum stake post-unstake or relinquishing membership).
8.  `listArtForSale(uint256 _tokenId, uint256 _price)`: Allows the owner of a token to list it for sale in the gallery marketplace.
9.  `buyArtPiece(uint256 _tokenId)`: Allows a user to purchase a listed art piece. Handles payment, fee/royalty distribution, and ownership transfer.
10. `cancelListing(uint256 _tokenId)`: Allows the seller to remove their art from the marketplace listing.
11. `triggerArtEvolution(uint256 _tokenId)`: Callable by anyone (potentially with incentives later) to update the dynamic properties of a specific art piece based on accrued interactions/votes/time.
12. `curatorInfluenceArt(uint256 _tokenId, int256 _influenceScore)`: Allows a curator to directly apply a score modifier impacting the dynamic properties of an *existing* art piece.
13. `addOwnerNoteToArt(uint256 _tokenId, string memory _note)`: Allows the current owner of an art piece to add a short, on-chain note/tag to it.
14. `withdrawGalleryFees()`: Allows the owner/governance to withdraw accumulated gallery fees.
15. `withdrawArtistRoyalties(address _artist)`: Allows an artist to withdraw their accumulated royalties.
16. `setGalleryFee(uint256 _feeRate)`: Owner/Governance sets the percentage fee taken by the gallery on sales.
17. `setArtistRoyaltyRate(address _artist, uint256 _royaltyRate)`: Owner/Governance sets a specific royalty rate for an artist (or a default rate).
18. `setCurationThreshold(uint256 _threshold)`: Owner/Governance sets the number of approval votes needed for a submission to be accepted.
19. `setMembershipStakeThreshold(uint256 _threshold)`: Owner/Governance sets the minimum stake required for membership.
20. `getArtDetails(uint256 _tokenId)`: Query function to get static details (artist, submission URI) of an art piece.
21. `getArtProperties(uint256 _tokenId)`: Query function to get the current dynamic properties of an art piece.
22. `getListing(uint256 _tokenId)`: Query function to get details of a marketplace listing.
23. `getSubmissions()`: Query function to get a list of current submissions and their status.
24. `getCurators()`: Query function to get the list of active curators.
25. `getMemberStake(address _member)`: Query function to get the staked amount for a specific address.
26. `isMember(address _address)`: Query function to check if an address is a current member.
27. `tokenURI(uint256 _tokenId)`: ERC721 standard override - generates a dynamic URI incorporating base URI, token ID, and current dynamic properties.
28. `ownerOf(uint256 _tokenId)`: ERC721 standard query.
29. `balanceOf(address _owner)`: ERC721 standard query.
30. `totalSupply()`: ERC721 standard query.
    *(Note: ERC721Enumerable functions like `tokenByIndex`, `tokenOfOwnerByIndex` could be added if needed, increasing the count further)*.
    *(Standard ERC721 transfer/approval functions like `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll` are also part of the contract, bringing the total well over 20).*

Let's write the code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming a staking token

// --- Outline ---
// 1. Contract Definition: Inherits ERC721, Ownable, ReentrancyGuard.
// 2. State Variables: Gallery config, token counter, art data, marketplace, curation, membership.
// 3. Structs: ArtPiece, Submission, Listing, ArtProperties.
// 4. Events: Minting, Transfer, Listing, Sale, Curation, Membership, Withdrawals.
// 5. Modifiers: Access control (owner, curator, member, art owner).
// 6. ERC721 Implementation: Core functions, dynamic tokenURI.
// 7. Curation System: Submissions, voting, curator management.
// 8. Dynamic Art System: Storing/updating properties, evolution trigger, influenced by curators/activity.
// 9. Gallery Membership & Staking: Stake ERC20, manage membership status.
// 10. Internal Marketplace: List, buy, cancel art listings. Handles fees and royalties.
// 11. Fee & Royalty Management: Set rates, withdraw funds.
// 12. Admin/Configuration: Set parameters.
// 13. Query Functions: Get gallery state, art details, listings, etc.

// --- Function Summary ---
// Core NFT & Gallery Management:
// 1.  constructor(string memory name, string memory symbol, address _stakeTokenAddress, uint256 initialStakeThreshold): Initializes the gallery, NFT collection, and membership stake requirement.
// 2.  tokenURI(uint256 _tokenId): ERC721 standard override - generates a dynamic URI.
// 3.  ownerOf(uint256 _tokenId): ERC721 standard query.
// 4.  balanceOf(address _owner): ERC721 standard query.
// 5.  totalSupply(): ERC721 standard query.
// 6.  safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard transfer.
// 7.  approve(address to, uint256 tokenId): ERC721 standard approval.
// 8.  setApprovalForAll(address operator, bool approved): ERC721 standard approval.
// 9.  getApproved(uint256 tokenId): ERC721 standard query.
// 10. isApprovedForAll(address owner, address operator): ERC721 standard query.

// Curation & Minting:
// 11. submitArtForCuration(string memory _metadataURI, address _artist): Allows an artist (or proposer) to submit a piece for curator review.
// 12. voteOnSubmission(uint256 _submissionId, bool _approve): Allows a curator to vote on a specific art submission.
// 13. addCurator(address _curator): Owner/Governance adds a new curator.
// 14. removeCurator(address _curator): Owner/Governance removes a curator.

// Dynamic Art & Interaction:
// 15. triggerArtEvolution(uint256 _tokenId): Updates dynamic properties based on accrued data (sales, votes, time).
// 16. curatorInfluenceArt(uint256 _tokenId, int256 _influenceScore): Allows a curator to directly apply influence to art properties.
// 17. addOwnerNoteToArt(uint256 _tokenId, string memory _note): Allows current owner to add an on-chain note.

// Membership & Staking:
// 18. stakeForMembership(uint256 _amount): Stake tokens for membership.
// 19. unstakeMembership(): Unstake tokens.
// 20. setMembershipStakeThreshold(uint256 _threshold): Owner/Governance sets minimum stake.

// Marketplace:
// 21. listArtForSale(uint256 _tokenId, uint256 _price): List art for sale.
// 22. buyArtPiece(uint256 _tokenId): Purchase listed art. Handles payments, fees, royalties.
// 23. cancelListing(uint256 _tokenId): Seller removes listing.

// Financials & Admin:
// 24. withdrawGalleryFees(): Owner/Governance withdraws fees.
// 25. withdrawArtistRoyalties(address _artist): Artist withdraws royalties.
// 26. setGalleryFee(uint256 _feeRate): Owner/Governance sets gallery fee rate.
// 27. setArtistRoyaltyRate(address _artist, uint256 _royaltyRate): Owner/Governance sets artist royalty rate.
// 28. setCurationThreshold(uint256 _threshold): Owner/Governance sets needed approval votes.
// 29. setBaseURI(string memory _newBaseURI): Owner sets the base URI for metadata.

// Query Functions:
// 30. getArtDetails(uint256 _tokenId): Get static art details.
// 31. getArtProperties(uint256 _tokenId): Get current dynamic properties.
// 32. getListing(uint256 _tokenId): Get marketplace listing details.
// 33. getSubmissions(): Get list of current submissions.
// 34. getCurators(): Get list of active curators.
// 35. getMemberStake(address _member): Get stake amount for an address.
// 36. isMember(address _address): Check if address is a member.
// 37. getOwnerNoteForArt(uint256 _tokenId): Get the owner's note for an art piece.

contract CryptoArtGallery is ERC721, Ownable, ReentrancyGuard {

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique token IDs

    struct ArtPiece {
        uint256 submissionId;    // Link back to the original submission
        address artist;          // Address of the artist
        string metadataURI;      // Base URI for static metadata (e.g., IPFS hash)
        ArtProperties properties; // Dynamic properties
        string ownerNote;        // Note added by the current owner
    }

    struct ArtProperties {
        int256 curationScore;   // Aggregate score from curator influence
        uint256 saleCount;      // Number of times this piece has been sold in the gallery
        uint256 viewScore;      // Simplified view/interaction metric (e.g., incremented on sale/transfer)
        uint256 lastEvolution;  // Block number when dynamic properties were last updated
        // Add more dynamic properties here as needed (e.g., time since mint, related art interactions)
    }

    struct Submission {
        string metadataURI;      // URI for the proposed art metadata
        address artist;          // Address proposing the art
        uint256 approvalVotes;   // Number of curator approval votes
        uint256 rejectionVotes;  // Number of curator rejection votes
        mapping(address => bool) voted; // Keep track of which curators have voted
        SubmissionStatus status; // Current status of the submission
    }

    enum SubmissionStatus { Pending, Approved, Rejected, Minted }

    struct Listing {
        uint256 price;          // Price in native currency (e.g., Wei)
        address seller;         // Address of the seller
        bool active;            // Is the listing active?
    }

    mapping(uint256 => ArtPiece) private _artPieces;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => Submission) private _submissions; // submissionId => Submission
    uint256 private _nextSubmissionId; // Counter for submissions

    mapping(address => bool) public isCurator;
    address[] public curators; // Dynamic array of curators for easy iteration

    mapping(address => uint256) private _memberStakes; // Staked token amount
    IERC20 public stakeToken; // Address of the ERC20 token used for staking
    uint256 public membershipStakeThreshold; // Minimum stake required for membership

    uint256 public galleryFeeRate; // Percentage fee taken by the gallery (e.g., 500 for 5%)
    mapping(address => uint256) private _artistRoyaltyRates; // Percentage royalty rate for artists
    uint256 public defaultArtistRoyaltyRate; // Default royalty rate if not set per artist

    uint256 public curationThreshold; // Minimum number of *approval* votes required for approval

    string private _baseURI; // Base URI for token metadata (can be updated)

    mapping(address => uint256) private _galleryFeesCollected;
    mapping(address => uint256) private _artistRoyaltiesCollected;

    // --- Events ---

    event ArtSubmittedForCuration(uint256 indexed submissionId, address indexed artist, string metadataURI);
    event SubmissionVoted(uint256 indexed submissionId, address indexed curator, bool approved);
    event SubmissionApproved(uint256 indexed submissionId);
    event SubmissionRejected(uint256 indexed submissionId);
    event ArtMinted(uint256 indexed tokenId, uint256 indexed submissionId, address indexed artist);
    event CuratorAdded(address indexed curator);
    event CuratorRemoved(address indexed curator);

    event MembershipStaked(address indexed member, uint256 amount, uint256 totalStaked);
    event MembershipUnstaked(address indexed member, uint256 amount, uint256 totalStaked);

    event ArtListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ArtSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);

    event ArtEvolutionTriggered(uint256 indexed tokenId, ArtProperties newProperties);
    event ArtInfluencedByCurator(uint256 indexed tokenId, address indexed curator, int256 influenceApplied);
    event OwnerNoteAdded(uint256 indexed tokenId, address indexed owner, string note);

    event GalleryFeesWithdrawn(address indexed recipient, uint256 amount);
    event ArtistRoyaltiesWithdrawn(address indexed artist, uint256 amount);
    event GalleryFeeRateUpdated(uint256 newRate);
    event ArtistRoyaltyRateUpdated(address indexed artist, uint256 newRate);
    event DefaultArtistRoyaltyRateUpdated(uint256 newRate);
    event CurationThresholdUpdated(uint256 newThreshold);
    event MembershipStakeThresholdUpdated(uint256 newThreshold);
    event BaseURIUpdated(string newURI);

    // --- Modifiers ---

    modifier onlyCurator() {
        require(isCurator[msg.sender], "CryptoArtGallery: Not a curator");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "CryptoArtGallery: Not a member");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "CryptoArtGallery: Caller is not the owner or approved");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address _stakeTokenAddress, uint256 initialStakeThreshold)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _nextTokenId = 0;
        _nextSubmissionId = 0;
        stakeToken = IERC20(_stakeTokenAddress);
        membershipStakeThreshold = initialStakeThreshold; // e.g., 1 ether * 100 (if token has 18 decimals)
        galleryFeeRate = 500; // Default 5%
        defaultArtistRoyaltyRate = 1000; // Default 10%
        curationThreshold = 3; // Default 3 positive votes
        _baseURI = "ipfs://"; // Default IPFS base
    }

    // --- ERC721 Core Functions (Overridden or Standard) ---

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        ArtPiece storage art = _artPieces[_tokenId];

        // In a real scenario, this would construct a complex JSON URI pointing
        // to an off-chain server/service that generates the metadata JSON
        // dynamically based on the _baseURI, art.metadataURI, and art.properties.
        // For this example, we'll return a simplified URI that includes the base
        // and indicates dynamism.

        string memory base = _baseURI; // e.g., ipfs:// or https://api.mygallery.xyz/metadata/
        string memory staticPart = art.metadataURI; // e.g., Qm... (for static art data)

        // Indicate dynamic nature - actual dynamism happens off-chain when resolving the URI
        // A real implementation might pass parameters or encode properties into the URI.
        // Example: "https://api.mygallery.xyz/metadata/1?curationScore=..."
        // Or simply: "https://api.mygallery.xyz/metadata/1/dynamic"

        // Simplified placeholder:
        return string(abi.encodePacked(base, uint256(_tokenId).toString(), "/dynamic"));
    }

    // Standard ERC721 functions inherited: ownerOf, balanceOf, totalSupply, approve, getApproved, setApprovalForAll, isApprovedForAll, safeTransferFrom, transferFrom.
    // The `_update` and `_increaseBalance` internal functions from ERC721 handle ownership/balance updates.

    // --- Curation System ---

    /// @notice Allows an artist or proposer to submit art metadata for curator review.
    /// @param _metadataURI URI pointing to the art's static metadata (e.g., IPFS).
    /// @param _artist Address of the artist who created the piece.
    function submitArtForCuration(string memory _metadataURI, address _artist) public {
        uint256 submissionId = _nextSubmissionId++;
        _submissions[submissionId] = Submission({
            metadataURI: _metadataURI,
            artist: _artist,
            approvalVotes: 0,
            rejectionVotes: 0,
            voted: new mapping(address => bool)(), // Initialize mapping
            status: SubmissionStatus.Pending
        });
        emit ArtSubmittedForCuration(submissionId, _artist, _metadataURI);
    }

    /// @notice Allows a curator to vote on a pending art submission.
    /// @param _submissionId The ID of the submission to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnSubmission(uint256 _submissionId, bool _approve) public onlyCurator {
        Submission storage submission = _submissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "CryptoArtGallery: Submission not pending");
        require(!submission.voted[msg.sender], "CryptoArtGallery: Curator already voted");

        submission.voted[msg.sender] = true;

        if (_approve) {
            submission.approvalVotes++;
            if (submission.approvalVotes >= curationThreshold) {
                submission.status = SubmissionStatus.Approved;
                // Auto-mint upon approval
                _mintArtPiece(submission.metadataURI, submission.artist, _submissionId);
                emit SubmissionApproved(_submissionId);
            }
        } else {
            submission.rejectionVotes++;
            // Optional: auto-reject if rejection threshold is met
            // For now, just track rejections
        }

        emit SubmissionVoted(_submissionId, msg.sender, _approve);
    }

    /// @notice Mints a new art piece token after a submission is approved.
    /// @dev Internal function, only called by voteOnSubmission when threshold is met.
    /// @param _metadataURI The URI for the art's static metadata.
    /// @param _artist The artist's address.
    /// @param _submissionId The ID of the approved submission.
    function _mintArtPiece(string memory _metadataURI, address _artist, uint256 _submissionId) internal {
        uint256 tokenId = _nextTokenId++;
        _safeMint(_artist, tokenId); // Mint to the artist first

        _artPieces[tokenId] = ArtPiece({
            submissionId: _submissionId,
            artist: _artist,
            metadataURI: _metadataURI,
            properties: ArtProperties({
                curationScore: int256(_submissions[_submissionId].approvalVotes), // Initial score from approval votes
                saleCount: 0,
                viewScore: 0, // Starts at 0
                lastEvolution: block.number
            }),
            ownerNote: "" // Empty initial note
        });

        _submissions[_submissionId].status = SubmissionStatus.Minted;

        emit ArtMinted(tokenId, _submissionId, _artist);
    }

    /// @notice Adds a new address to the list of curators.
    /// @param _curator The address to add as a curator.
    function addCurator(address _curator) public onlyOwner {
        require(_curator != address(0), "CryptoArtGallery: Zero address");
        require(!isCurator[_curator], "CryptoArtGallery: Address is already a curator");
        isCurator[_curator] = true;
        curators.push(_curator);
        emit CuratorAdded(_curator);
    }

    /// @notice Removes an address from the list of curators.
    /// @param _curator The address to remove as a curator.
    function removeCurator(address _curator) public onlyOwner {
        require(isCurator[_curator], "CryptoArtGallery: Address is not a curator");
        isCurator[_curator] = false;
        // Find and remove from dynamic array (inefficient for large arrays)
        for (uint i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                curators[i] = curators[curators.length - 1];
                curators.pop();
                break;
            }
        }
        emit CuratorRemoved(_curator);
    }

    // --- Dynamic Art System ---

    /// @notice Triggers an update to the dynamic properties of an art piece.
    /// @dev This function can be called by anyone to potentially update the art's state.
    /// Real-world usage might include incentives or be tied to specific actions.
    /// The logic for evolution is simplified here.
    /// @param _tokenId The ID of the art piece to evolve.
    function triggerArtEvolution(uint256 _tokenId) public {
        require(_exists(_tokenId), "CryptoArtGallery: Token does not exist");
        ArtPiece storage art = _artPieces[_tokenId];

        // Simplified evolution logic:
        // - curatorScore is updated directly by curatorInfluenceArt
        // - saleCount is updated on sale
        // - viewScore could increment per trigger call (simplified)
        // - Add time decay or other factors here if desired

        art.properties.viewScore++; // Simulate interaction/view score increment

        // Example: Apply time decay to a score (needs block.timestamp instead of number for seconds)
        // int256 scoreDecay = int256(block.number - art.properties.lastEvolution) / 100; // Example: Decay every 100 blocks
        // art.properties.curationScore -= scoreDecay;
        // if (art.properties.curationScore < 0) art.properties.curationScore = 0; // Prevent negative score

        art.properties.lastEvolution = block.number; // Update last evolution block

        emit ArtEvolutionTriggered(_tokenId, art.properties);
    }

    /// @notice Allows a curator to directly influence the curation score of an existing art piece.
    /// @param _tokenId The ID of the art piece.
    /// @param _influenceScore The integer amount to add/subtract from the curation score.
    function curatorInfluenceArt(uint256 _tokenId, int256 _influenceScore) public onlyCurator {
        require(_exists(_tokenId), "CryptoArtGallery: Token does not exist");
        ArtPiece storage art = _artPieces[_tokenId];

        art.properties.curationScore += _influenceScore;
        art.properties.lastEvolution = block.number; // Mark as influenced

        emit ArtInfluencedByCurator(_tokenId, msg.sender, _influenceScore);
        emit ArtEvolutionTriggered(_tokenId, art.properties); // Trigger general evolution event as well
    }

    /// @notice Allows the current owner to add a personal note to their art piece.
    /// @param _tokenId The ID of the art piece.
    /// @param _note The note string to add.
    function addOwnerNoteToArt(uint256 _tokenId, string memory _note) public onlyArtOwner(_tokenId) {
        _artPieces[_tokenId].ownerNote = _note;
        emit OwnerNoteAdded(_tokenId, msg.sender, _note);
    }


    // --- Gallery Membership & Staking ---

    /// @notice Allows users to stake the designated ERC20 token to become members.
    /// @param _amount The amount of tokens to stake.
    function stakeForMembership(uint256 _amount) public nonReentrant {
        require(_amount > 0, "CryptoArtGallery: Stake amount must be greater than 0");
        uint256 currentStake = _memberStakes[msg.sender];
        uint256 totalNewStake = currentStake + _amount;

        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "CryptoArtGallery: Token transfer failed");

        _memberStakes[msg.sender] = totalNewStake;

        emit MembershipStaked(msg.sender, _amount, totalNewStake);
    }

    /// @notice Allows members to unstake their tokens.
    /// @dev Users must unstake all or maintain above the threshold if it changes.
    /// If unstaking partial amount, must still meet or exceed the current threshold.
    /// @param _amount The amount of tokens to unstake.
    function unstakeMembership(uint256 _amount) public nonReentrant {
         require(_amount > 0, "CryptoArtGallery: Unstake amount must be greater than 0");
         uint256 currentStake = _memberStakes[msg.sender];
         require(currentStake >= _amount, "CryptoArtGallery: Not enough staked tokens");

         uint256 remainingStake = currentStake - _amount;
         require(remainingStake == 0 || remainingStake >= membershipStakeThreshold,
                 "CryptoArtGallery: Remaining stake must meet threshold or be zero");

         _memberStakes[msg.sender] = remainingStake;

         require(stakeToken.transfer(msg.sender, _amount), "CryptoArtGallery: Token transfer failed");

         emit MembershipUnstaked(msg.sender, _amount, remainingStake);
    }

    /// @notice Checks if an address is a current member based on their stake.
    /// @param _address The address to check.
    /// @return True if the address meets the membership stake threshold.
    function isMember(address _address) public view returns (bool) {
        return _memberStakes[_address] >= membershipStakeThreshold;
    }


    // --- Internal Marketplace ---

    /// @notice Lists an owned art piece for sale in the gallery marketplace.
    /// @param _tokenId The ID of the art piece to list.
    /// @param _price The price in native currency (e.g., Wei).
    function listArtForSale(uint256 _tokenId, uint256 _price) public onlyArtOwner(_tokenId) {
        // Require approval for the gallery contract to manage the token
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(ownerOf(_tokenId), address(this)),
                "CryptoArtGallery: Gallery contract not approved to manage token");
        require(_price > 0, "CryptoArtGallery: Listing price must be greater than 0");

        // Cancel any existing listing first
        if (_listings[_tokenId].active) {
            cancelListing(_tokenId); // This emits ListingCancelled
        }

        _listings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            active: true
        });

        emit ArtListed(_tokenId, msg.sender, _price);
    }

    /// @notice Allows a user to buy a listed art piece.
    /// @param _tokenId The ID of the art piece to buy.
    function buyArtPiece(uint256 _tokenId) public payable nonReentrant {
        Listing storage listing = _listings[_tokenId];
        require(listing.active, "CryptoArtGallery: Token not listed for sale");
        require(msg.value >= listing.price, "CryptoArtGallery: Insufficient funds");
        require(msg.sender != listing.seller, "CryptoArtGallery: Cannot buy your own art");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Deactivate listing BEFORE transfers
        listing.active = false;

        // Calculate fees and royalties
        uint256 galleryFee = (price * galleryFeeRate) / 10000; // Fee in basis points (10000 = 100%)
        address artist = _artPieces[_tokenId].artist;
        uint256 artistRoyaltyRate = _artistRoyaltyRates[artist];
        if (artistRoyaltyRate == 0) { // Use default if artist specific not set
             artistRoyaltyRate = defaultArtistRoyaltyRate;
        }
        uint256 artistRoyalty = (price * artistRoyaltyRate) / 10000;

        uint256 amountToSeller = price - galleryFee - artistRoyalty;

        // Transfer funds
        // Send royalties to artist first
        if (artistRoyalty > 0) {
            // Store royalties to be withdrawn by the artist
             _artistRoyaltyCollected[artist] += artistRoyalty;
        }

        // Send gallery fees
        if (galleryFee > 0) {
             _galleryFeesCollected[owner()] += galleryFee; // Send to owner's collection balance
        }

        // Send remaining amount to seller
        (bool successSeller, ) = payable(seller).call{value: amountToSeller}("");
        require(successSeller, "CryptoArtGallery: Seller payment failed");

        // Handle potential overpayment refund (send remaining msg.value back to buyer)
        if (msg.value > price) {
             uint256 refund = msg.value - price;
             (bool successRefund, ) = payable(msg.sender).call{value: refund}("");
             require(successRefund, "CryptoArtGallery: Refund failed"); // Refund failure should ideally not revert the sale
        }


        // Transfer NFT ownership
        // Use _safeTransfer since we know the receiver is a contract or EOA
        // _safeTransfer also requires approval handled in listArtForSale or explicit approve
        _safeTransfer(seller, msg.sender, _tokenId);

        // Update art properties for the sale
        _artPieces[_tokenId].properties.saleCount++;
        _artPieces[_tokenId].properties.viewScore++; // Increment view score on sale
        _artPieces[_tokenId].properties.lastEvolution = block.number; // Mark as evolved by sale

        emit ArtSold(_tokenId, msg.sender, seller, price);
        emit ArtEvolutionTriggered(_tokenId, _artPieces[_tokenId].properties);
    }

    /// @notice Allows the seller to cancel an active listing.
    /// @param _tokenId The ID of the art piece listing to cancel.
    function cancelListing(uint256 _tokenId) public {
        Listing storage listing = _listings[_tokenId];
        require(listing.active, "CryptoArtGallery: Token not currently listed");
        // Only the original seller OR the current owner can cancel (owner takes precedence)
        address currentOwner = ownerOf(_tokenId);
        require(msg.sender == listing.seller || msg.sender == currentOwner,
                "CryptoArtGallery: Only seller or owner can cancel listing");

        listing.active = false; // Deactivate listing

        // Optional: Remove gallery's approval if it was set for this token
        // _approve(address(0), _tokenId); // This requires owner to be msg.sender, use clearApproval if needed

        emit ListingCancelled(_tokenId);
    }

    // --- Fee & Royalty Management ---

    /// @notice Allows the owner/governance to withdraw accumulated gallery fees.
    function withdrawGalleryFees() public onlyOwner nonReentrant {
        uint256 amount = _galleryFeesCollected[msg.sender];
        require(amount > 0, "CryptoArtGallery: No fees collected for withdrawal");
        _galleryFeesCollected[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "CryptoArtGallery: Fee withdrawal failed");
        emit GalleryFeesWithdrawn(msg.sender, amount);
    }

    /// @notice Allows an artist to withdraw their accumulated royalties.
    /// @param _artist The address of the artist to withdraw for (usually msg.sender).
    function withdrawArtistRoyalties(address _artist) public nonReentrant {
         // Allow artist to withdraw their own royalties
         require(msg.sender == _artist, "CryptoArtGallery: Can only withdraw your own royalties");

         uint256 amount = _artistRoyaltiesCollected[_artist];
         require(amount > 0, "CryptoArtGallery: No royalties collected for withdrawal");
         _artistRoyaltyCollected[_artist] = 0;
         (bool success, ) = payable(_artist).call{value: amount}("");
         require(success, "CryptoArtGallery: Royalty withdrawal failed");
         emit ArtistRoyaltiesWithdrawn(_artist, amount);
    }

    /// @notice Allows the owner/governance to set the gallery fee rate on sales.
    /// @param _feeRate The fee rate in basis points (10000 = 100%). Max 10000.
    function setGalleryFee(uint256 _feeRate) public onlyOwner {
        require(_feeRate <= 10000, "CryptoArtGallery: Fee rate cannot exceed 100%");
        galleryFeeRate = _feeRate;
        emit GalleryFeeRateUpdated(_feeRate);
    }

    /// @notice Allows the owner/governance to set a specific royalty rate for an artist.
    /// @param _artist The artist's address.
    /// @param _royaltyRate The royalty rate in basis points (10000 = 100%). Max 10000.
    function setArtistRoyaltyRate(address _artist, uint256 _royaltyRate) public onlyOwner {
         require(_artist != address(0), "CryptoArtGallery: Zero address");
         require(_royaltyRate <= 10000, "CryptoArtGallery: Royalty rate cannot exceed 100%");
         _artistRoyaltyRates[_artist] = _royaltyRate;
         emit ArtistRoyaltyRateUpdated(_artist, _royaltyRate);
    }

    /// @notice Allows the owner/governance to set the default royalty rate for artists.
    /// @param _royaltyRate The royalty rate in basis points (10000 = 100%). Max 10000.
    function setDefaultArtistRoyaltyRate(uint256 _royaltyRate) public onlyOwner {
         require(_royaltyRate <= 10000, "CryptoArtGallery: Default royalty rate cannot exceed 100%");
         defaultArtistRoyaltyRate = _royaltyRate;
         emit DefaultArtistRoyaltyRateUpdated(_royaltyRate);
    }

    // --- Admin / Configuration ---

    /// @notice Allows the owner/governance to set the curation threshold for approving submissions.
    /// @param _newThreshold The minimum number of approval votes required.
    function setCurationThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "CryptoArtGallery: Threshold must be greater than 0");
        curationThreshold = _newThreshold;
        emit CurationThresholdUpdated(_newThreshold);
    }

    /// @notice Allows the owner/governance to set the minimum stake required for membership.
    /// @param _threshold The minimum stake amount in stake token units.
    function setMembershipStakeThreshold(uint256 _threshold) public onlyOwner {
        membershipStakeThreshold = _threshold;
        emit MembershipStakeThresholdUpdated(_threshold);
    }

     /// @notice Allows the owner/governance to set the base URI for token metadata.
     /// @param _newBaseURI The new base URI string.
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }


    // --- Query Functions ---

    /// @notice Gets the static details of an art piece.
    /// @param _tokenId The ID of the art piece.
    /// @return submissionId, artist, metadataURI, ownerNote
    function getArtDetails(uint256 _tokenId) public view returns (uint256 submissionId, address artist, string memory metadataURI, string memory ownerNote) {
        require(_exists(_tokenId), "CryptoArtGallery: Token does not exist");
        ArtPiece storage art = _artPieces[_tokenId];
        return (art.submissionId, art.artist, art.metadataURI, art.ownerNote);
    }

    /// @notice Gets the current dynamic properties of an art piece.
    /// @param _tokenId The ID of the art piece.
    /// @return curationScore, saleCount, viewScore, lastEvolutionBlock
    function getArtProperties(uint256 _tokenId) public view returns (int256 curationScore, uint256 saleCount, uint256 viewScore, uint256 lastEvolutionBlock) {
        require(_exists(_tokenId), "CryptoArtGallery: Token does not exist");
        ArtPiece storage art = _artPieces[_tokenId];
        return (art.properties.curationScore, art.properties.saleCount, art.properties.viewScore, art.properties.lastEvolution);
    }

    /// @notice Gets the details of a marketplace listing for an art piece.
    /// @param _tokenId The ID of the art piece.
    /// @return price, seller, active
    function getListing(uint256 _tokenId) public view returns (uint256 price, address seller, bool active) {
        Listing storage listing = _listings[_tokenId];
        return (listing.price, listing.seller, listing.active);
    }

     /// @notice Gets the owner's note for an art piece.
     /// @param _tokenId The ID of the art piece.
     /// @return The owner's note string.
    function getOwnerNoteForArt(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "CryptoArtGallery: Token does not exist");
        return _artPieces[_tokenId].ownerNote;
    }

    /// @notice Gets the list of current submissions and their basic status.
    /// @dev This is inefficient for many submissions. A real dapp would likely query subgraph.
    /// @return submissionIds, statuses, artists
    function getSubmissions() public view returns (uint256[] memory submissionIds, SubmissionStatus[] memory statuses, address[] memory artists) {
        submissionIds = new uint256[](_nextSubmissionId);
        statuses = new SubmissionStatus[](_nextSubmissionId);
        artists = new address[](_nextSubmissionId);

        for (uint256 i = 0; i < _nextSubmissionId; i++) {
            submissionIds[i] = i;
            statuses[i] = _submissions[i].status;
            artists[i] = _submissions[i].artist;
        }
        return (submissionIds, statuses, artists);
    }

    /// @notice Gets the list of current curators.
    /// @return An array of curator addresses.
    function getCurators() public view returns (address[] memory) {
        // Return a copy of the dynamic array
        return curators;
    }

    /// @notice Gets the staked amount for a specific address.
    /// @param _member The address to check.
    /// @return The staked amount in stake token units.
    function getMemberStake(address _member) public view returns (uint256) {
        return _memberStakes[_member];
    }

    // --- Internal Helpers ---

    // @dev Override _beforeTokenTransfer to potentially hook into transfers for history tracking etc.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     // Add history tracking logic here if needed
    // }

    // @dev Override _baseURI() internal function from ERC721 to make setBaseURI work
    // function _baseURI() internal view virtual override returns (string memory) {
    //     return _baseURI;
    // }

    // Note: The standard ERC721 includes _baseURI internally. Setting _baseURI
    // as a state variable and overriding tokenURI is a valid alternative approach
    // for dynamic URIs that don't just rely on a simple base + token ID structure.
    // If we wanted the default ERC721 tokenURI behavior for *static* parts, we could
    // override _baseURI and have a separate function to get the dynamic properties.
    // The current tokenURI override generates the *entire* URI dynamically.

    // toString() helper from OpenZeppelin's Strings.sol could be useful if not inheriting directly.
    // For 0.8.20, we can just use abi.encodePacked with uint256.toString().
    // But let's add a simple internal helper for clarity or if complex string formatting is needed.
    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic NFTs:** The `ArtProperties` struct and the `triggerArtEvolution` / `curatorInfluenceArt` functions enable the art's metadata/properties to change *after* minting, based on on-chain events (sales, curator actions, theoretical 'views'/interactions). The `tokenURI` function is designed to reflect this dynamism (though the actual dynamic JSON generation would happen off-chain by a service resolving this URI).
2.  **On-chain Curation System:** Instead of anyone being able to mint, there's a structured submission and voting process managed by designated `curators`. This introduces a decentralized (depending on how curators are chosen/governed) layer of quality control or thematic focus for the gallery.
3.  **Gallery Membership with Staking:** Users stake a separate ERC20 token (`stakeToken`) to become `members`. This can be a mechanism for access control, governance participation (if voting rights were added), or unlocking features (like reduced fees or ability to trigger art evolution more often).
4.  **Internal Marketplace with Fee/Royalty Splitting:** The contract handles the entire sale process, including transferring native currency (ETH/MATIC/etc.), calculating and distributing fees to the gallery owner (or treasury) and royalties to the artist directly within the `buyArtPiece` function. Uses `ReentrancyGuard` for safety.
5.  **Owner Notes:** A small but creative feature allowing the *current* owner of a token to add a personal, on-chain string note to their specific art piece, adding a layer of personal interaction tied to ownership history.
6.  **Parameterization by Governance/Owner:** Key parameters like gallery fee, royalty rates, curation threshold, and membership stake are not hardcoded but can be updated by the owner (or a future DAO governance system), allowing the gallery to adapt over time.
7.  **Separation of Static/Dynamic Metadata:** The `metadataURI` stores the immutable, static art data, while `ArtProperties` stores the mutable, dynamic data, allowing the `tokenURI` to combine them off-chain.

This contract goes beyond a simple ERC721 or a basic marketplace by integrating curation, staking-based membership, and dynamic art properties, offering a more complex and interactive on-chain gallery experience.