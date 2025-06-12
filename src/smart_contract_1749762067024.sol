Okay, let's design a smart contract for a Decentralized Art Gallery with some advanced features like dynamic art states, community curation, and fractionalization built directly into the gallery logic (not separate ERC-20s per piece, but managed internally for simplicity in this example).

This contract will not be a simple ERC721 wrapper. It will manage the lifecycle of art pieces, from proposal and curation to minting, listing, sale, dynamic changes, and fractional ownership.

**Disclaimer:** This is a complex example for educational purposes. Deploying such a contract to a live network would require extensive auditing and gas optimization. Features like on-chain fractionalization handled *within* the main contract have significant gas implications and complexity compared to dedicated fractionalization protocols.

---

**Outline:**

1.  **Pragma & Imports:** Define Solidity version and import necessary OpenZeppelin libraries (ERC721, AccessControl).
2.  **Error Definitions:** Define custom errors for better revert reasons.
3.  **Events:** Define events for state changes (minting, listing, purchase, voting, state changes, etc.).
4.  **Structs:** Define data structures for Art Pieces, Marketplace Listings, Art Proposals, Dynamic Rules, and Fractionation details.
5.  **State Variables:** Declare mappings and variables to store contract state (owner, roles, art details, listings, proposals, votes, fractions, fees).
6.  **Access Control:** Define roles (DEFAULT_ADMIN_ROLE, CURATOR_ROLE).
7.  **Constructor:** Initialize the contract, assign the admin role.
8.  **Modifiers:** Define custom modifiers for access control or state checks.
9.  **Core ERC721 Overrides:** Override standard ERC721 functions to add custom logic (e.g., preventing transfer if fractionalized).
10. **Art Proposal & Curation Functions:**
    *   `submitArtProposal`: Allow users to propose art with metadata.
    *   `voteOnArtProposal`: Allow users with voting power/role (Curators) to vote.
    *   `approveArtProposal`: Admin/Curator approves a proposal, triggering minting.
    *   `rejectArtProposal`: Admin/Curator rejects a proposal.
11. **Art Creation & Management:**
    *   `safeMint`: Internal function called upon proposal approval.
    *   `updateArtMetadata`: Allow artist/owner to update metadata URI (under certain conditions).
    *   `assignArtistRole`: Assign the artist address associated with an ArtPiece (done during minting but potentially updatable).
12. **Marketplace Functions:**
    *   `listArtForSale`: Owner lists their piece for a price.
    *   `buyArt`: Purchase a listed piece. Handles ETH transfer and fees.
    *   `cancelListing`: Owner cancels a listing.
    *   `setListingPrice`: Owner changes the price of a listing.
13. **Dynamic Art Features:**
    *   `setDynamicRule`: Define a rule for how an art piece can change states (e.g., based on time, owner action, purchase count).
    *   `triggerDynamicStateChange`: Execute a state change based on a defined rule.
    *   `getCurrentArtState`: Get the current state index of an art piece.
    *   `getDynamicRule`: Retrieve the defined dynamic rule for a piece.
14. **Fractionalization Features:**
    *   `fractionalizeArt`: Burn the original NFT and issue internal "fractions" to the owner.
    *   `transferFractions`: Transfer internal fractions between users.
    *   `redeemArtFromFractions`: Burn all fractions for a piece and re-mint the original NFT to the redeemer.
    *   `getFractionSupply`: Get the total supply of fractions for a fractionalized piece.
    *   `getFractionBalance`: Get a user's fraction balance for a specific piece.
15. **Administrative & Utility Functions:**
    *   `setPlatformFeePercentage`: Set the percentage fee for sales.
    *   `setFeeRecipient`: Set the address that receives fees.
    *   `withdrawPlatformFees`: Fee recipient withdraws collected fees.
    *   `grantRole`: Admin grants a role (like CURATOR).
    *   `revokeRole`: Admin revokes a role.
    *   `getArtDetails`: Retrieve all details for an art piece.
    *   `getListingDetails`: Retrieve details for a marketplace listing.
    *   `getProposalDetails`: Retrieve details for an art proposal.
    *   `getVotesForProposal`: Get the list of voters and counts for a proposal.

**Function Summary (20+ Functions):**

1.  `constructor()`: Initializes ERC721 and AccessControl, sets admin.
2.  `supportsInterface()`: ERC165 standard for interface detection.
3.  `safeMint()`: Internal function to mint a new token after proposal approval.
4.  `transferFrom()`: Override ERC721; add checks for fractionalization/listings.
5.  `safeTransferFrom()`: Override ERC721; add checks.
6.  `approve()`: Override ERC721; add checks if necessary.
7.  `setApprovalForAll()`: Override ERC721; add checks if necessary.
8.  `submitArtProposal()`: User proposes art for consideration.
9.  `voteOnArtProposal()`: Curator votes on a proposal.
10. `approveArtProposal()`: Admin/Curator approves, triggers minting.
11. `rejectArtProposal()`: Admin/Curator rejects a proposal.
12. `updateArtMetadata()`: Artist/Owner updates token URI.
13. `listArtForSale()`: Owner lists their art NFT on the marketplace.
14. `buyArt()`: Purchase listed art.
15. `cancelListing()`: Owner cancels a listing.
16. `setListingPrice()`: Owner changes the price of a listing.
17. `setDynamicRule()`: Artist/Owner defines how an art piece can change states.
18. `triggerDynamicStateChange()`: Artist/Owner triggers a state change based on rules.
19. `getCurrentArtState()`: Get the current dynamic state of an art piece.
20. `getDynamicRule()`: Get the dynamic rule definition for an art piece.
21. `fractionalizeArt()`: Converts an NFT into internal fractions.
22. `transferFractions()`: Transfer internal fractions.
23. `redeemArtFromFractions()`: Combine fractions to reclaim the original NFT.
24. `getFractionSupply()`: Get fraction count for a piece.
25. `getFractionBalance()`: Get user's fraction balance for a piece.
26. `setPlatformFeePercentage()`: Admin sets marketplace fee %.
27. `setFeeRecipient()`: Admin sets address for fees.
28. `withdrawPlatformFees()`: Fee recipient withdraws fees.
29. `grantRole()`: Admin grants roles (e.g., Curator).
30. `revokeRole()`: Admin revokes roles.
31. `getArtDetails()`: Retrieve detailed art information.
32. `getListingDetails()`: Retrieve detailed listing information.
33. `getProposalDetails()`: Retrieve detailed proposal information.
34. `getVotesForProposal()`: Retrieve voting status for a proposal.
35. `hasRole()`: Standard AccessControl function.
36. `getRoleAdmin()`: Standard AccessControl function.

This easily exceeds 20 unique, non-standard ERC721 functions by incorporating proposal, voting, dynamic states, and internal fractionalization logic.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // Using SafeERC20 for potential future token payments, though example uses ETH

// --- Outline ---
// 1. Pragma & Imports
// 2. Error Definitions
// 3. Events
// 4. Structs
// 5. State Variables (Mappings, Counters, etc.)
// 6. Access Control Roles
// 7. Constructor
// 8. Modifiers
// 9. Core ERC721 Overrides (Transfer, Approval logic)
// 10. Art Proposal & Curation Functions
// 11. Art Creation & Management
// 12. Marketplace Functions
// 13. Dynamic Art Features
// 14. Fractionalization Features (Internal)
// 15. Administrative & Utility Functions

// --- Function Summary (>20 Functions) ---
// ERC721 Overrides:
// 1.  supportsInterface(bytes4 interfaceId) view returns (bool)
// 2.  transferFrom(address from, address to, uint256 tokenId)
// 3.  safeTransferFrom(address from, address to, uint256 tokenId)
// 4.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 5.  approve(address to, uint256 tokenId)
// 6.  setApprovalForAll(address operator, bool approved)
//
// Art Proposal & Curation:
// 7.  submitArtProposal(string memory uri, address artist)
// 8.  voteOnArtProposal(uint256 proposalId, bool support)
// 9.  approveArtProposal(uint256 proposalId)
// 10. rejectArtProposal(uint256 proposalId)
//
// Art Creation & Management:
// 11. safeMint(address to, string memory uri, address artist, uint256 proposalId) internal
// 12. updateArtMetadata(uint256 tokenId, string memory newUri)
// 13. assignArtistRole(uint256 tokenId, address artistAddress)
//
// Marketplace:
// 14. listArtForSale(uint256 tokenId, uint256 price)
// 15. buyArt(uint256 tokenId) payable
// 16. cancelListing(uint256 tokenId)
// 17. setListingPrice(uint256 tokenId, uint256 newPrice)
//
// Dynamic Art:
// 18. setDynamicRule(uint256 tokenId, uint256[] memory stateURIs, uint256 triggerType, uint256 triggerParam)
// 19. triggerDynamicStateChange(uint256 tokenId)
// 20. getCurrentArtState(uint256 tokenId) view returns (uint256)
// 21. getDynamicRule(uint256 tokenId) view returns (uint256[] memory, uint256, uint256)
//
// Fractionalization (Internal):
// 22. fractionalizeArt(uint256 tokenId, uint256 totalFractions)
// 23. transferFractions(uint256 tokenId, address from, address to, uint256 amount)
// 24. redeemArtFromFractions(uint256 tokenId)
// 25. getFractionSupply(uint256 tokenId) view returns (uint256)
// 26. getFractionBalance(uint256 tokenId, address owner) view returns (uint256)
//
// Administrative & Utility:
// 27. setPlatformFeePercentage(uint256 feeBps)
// 28. setFeeRecipient(address recipient)
// 29. withdrawPlatformFees()
// 30. grantRole(bytes32 role, address account)
// 31. revokeRole(bytes32 role, address account)
// 32. getArtDetails(uint256 tokenId) view returns (uint256, address, address, string memory, uint256)
// 33. getListingDetails(uint256 tokenId) view returns (bool, uint256, address)
// 34. getProposalDetails(uint256 proposalId) view returns (uint256, string memory, address, uint256, uint256, uint256, bool, bool, address[])
// 35. getVotesForProposal(uint256 proposalId) view returns (address[] memory, uint256[] memory)
// 36. hasRole(bytes32 role, address account) view returns (bool)
// 37. getRoleAdmin(bytes32 role) view returns (bytes32)

contract DecentralizedArtGallery is ERC721Enumerable, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20; // Just in case we extend to ERC20 payments later

    // --- Error Definitions ---
    error NotArtOwner();
    error ArtNotListed();
    error ListingNotFound();
    error NotEnoughEth();
    error TransferNotAllowedWhileListedOrFractionalized();
    error ApprovalNotAllowedWhileListedOrFractionalized();
    error ArtAlreadyFractionalized();
    error ArtNotFractionalized();
    error NotEnoughFractions();
    error RedemptionRequiresAllFractions();
    error VotingPeriodEnded(); // Not implemented explicitly but good for future
    error AlreadyVoted();
    error NotCuratorOrAdmin();
    error ZeroAddressRecipient();
    error InvalidFee(); // Fee > 100%
    error ArtNotProposal();
    error ProposalAlreadyApprovedOrRejected();
    error DynamicRuleNotSet();
    error InvalidDynamicStateChange();
    error NotArtistOrOwner();
    error CannotUpdateMetadataWhileListedOrFractionalized();
    error CannotFractionalizeWhileListed();
    error CannotListWhileFractionalized();

    // --- Events ---
    event ArtProposed(uint256 indexed proposalId, string uri, address indexed proposer, address indexed artist);
    event ArtProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ArtMinted(uint256 indexed tokenId, address indexed owner, string uri, address indexed artist, uint256 proposalId);
    event ArtProposalApproved(uint256 indexed proposalId, uint256 indexed tokenId);
    event ArtProposalRejected(uint256 indexed proposalId);
    event ArtMetadataUpdated(uint256 indexed tokenId, string newUri);
    event ArtListed(uint256 indexed tokenId, uint256 price, address indexed seller);
    event ArtPurchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event ListingPriceUpdated(uint256 indexed tokenId, uint256 newPrice);
    event DynamicRuleSet(uint256 indexed tokenId, uint256 triggerType, uint256 triggerParam);
    event DynamicStateChanged(uint256 indexed tokenId, uint256 oldState, uint256 newState);
    event ArtFractionalized(uint256 indexed tokenId, address indexed owner, uint256 totalFractions);
    event FractionsTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event ArtRedeemedFromFractions(uint256 indexed tokenId, address indexed redeemer);
    event PlatformFeeUpdated(uint256 oldFeeBps, uint256 newFeeBps);
    event FeeRecipientUpdated(address oldRecipient, address newRecipient);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs ---
    struct ArtPiece {
        uint256 tokenId;
        address artist;
        string uri; // Initial URI
        uint256 proposalId;
        uint256 currentState; // For dynamic art
        bool isFractionalized;
        uint256 totalFractions; // For fractionalized art
        address currentOwner; // Redundant with ERC721 owner, but helpful for clarity
    }

    struct MarketplaceListing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct ArtProposal {
        string uri;
        address proposer;
        address artist;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 voteEndTime; // For future timed voting
        bool approved;
        bool rejected;
        bool exists; // To check if proposalId is valid
        address[] voters; // Simple list for this example; more complex systems might use a mapping
    }

    struct DynamicRule {
        uint256[] stateURIs; // URIs for each state
        uint256 triggerType; // 0: Manual (by owner/artist), 1: Time-based, 2: Purchase count, etc. (Simple enum for example)
        uint256 triggerParam; // e.g., Timestamp for time-based, count for purchase count
        bool exists; // To check if rule is set
    }

    // --- State Variables ---
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    Counters.Counter private _artTokenIds;
    Counters.Counter private _artProposalIds;

    mapping(uint256 => ArtPiece) private _artPieces;
    mapping(uint256 => MarketplaceListing) private _listings;
    mapping(uint256 => ArtProposal) private _proposals;
    mapping(uint256 => DynamicRule) private _dynamicRules;

    // Internal fractional ownership representation
    mapping(uint256 => mapping(address => uint256)) private _fractionBalances;

    uint256 private _platformFeeBps; // Basis points (e.g., 100 = 1%)
    address private _feeRecipient;
    uint256 private _totalPlatformFeesEth; // ETH fees collected

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialFeeBps, address initialFeeRecipient)
        ERC721(name, symbol)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Admin can later grant CURATOR_ROLE
        _platformFeeBps = initialFeeBps;
        _feeRecipient = initialFeeRecipient;
        require(initialFeeBps <= 10000, InvalidFee()); // Max 100%
        require(initialFeeRecipient != address(0), ZeroAddressRecipient());
    }

    // --- Modifiers ---
    modifier onlyArtOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert NotArtOwner();
        _;
    }

    modifier onlyCuratorOrAdmin() {
        if (!hasRole(CURATOR_ROLE, msg.sender) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotCuratorOrAdmin();
        _;
    }

    modifier notListedOrFractionalized(uint256 tokenId) {
        if (_listings[tokenId].isListed) revert TransferNotAllowedWhileListedOrFractionalized();
        if (_artPieces[tokenId].isFractionalized) revert TransferNotAllowedWhileListedOrFractionalized();
        _;
    }

    // --- Core ERC721 Overrides ---
    // Override transfer functions to prevent transfers for listed or fractionalized art
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) notListedOrFractionalized(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) notListedOrFractionalized(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721Enumerable, ERC721) notListedOrFractionalized(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Override approval functions to prevent approvals for listed or fractionalized art
    function approve(address to, uint256 tokenId) public override(ERC721, IERC721) notListedOrFractionalized(tokenId) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {
        // Allow setting approval for all, but the transfer/approval logic will still block for listed/fractionalized tokens
        super.setApprovalForAll(operator, approved);
    }

    // Override tokenURI to handle dynamic art states
    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
        _requireOwned(tokenId); // Standard check from ERC721
        ArtPiece storage art = _artPieces[tokenId];
        DynamicRule storage rule = _dynamicRules[tokenId];

        if (rule.exists) {
             // Check bounds
            if (art.currentState >= rule.stateURIs.length) {
                 // Should not happen if logic is correct, fallback to initial URI
                 return art.uri;
            }
            return rule.stateURIs[art.currentState];
        } else {
            // No dynamic rule, return initial URI
            return art.uri;
        }
    }

    // --- Art Proposal & Curation Functions ---

    /// @notice Submits a new art proposal for gallery consideration.
    /// @param uri Metadata URI for the proposed art.
    /// @param artist Address of the artist.
    function submitArtProposal(string memory uri, address artist) public {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        _proposals[proposalId] = ArtProposal({
            uri: uri,
            proposer: msg.sender,
            artist: artist,
            votesFor: 0,
            votesAgainst: 0,
            voteEndTime: block.timestamp + 7 days, // Example: Voting lasts 7 days
            approved: false,
            rejected: false,
            exists: true,
            voters: new address[](0)
        });
        emit ArtProposed(proposalId, uri, msg.sender, artist);
    }

    /// @notice Allows a Curator or Admin to vote on an art proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a 'yes' vote, false for a 'no' vote.
    function voteOnArtProposal(uint256 proposalId, bool support) public onlyCuratorOrAdmin {
        ArtProposal storage proposal = _proposals[proposalId];
        if (!proposal.exists || proposal.approved || proposal.rejected) revert ArtNotProposal();
        // if (block.timestamp > proposal.voteEndTime) revert VotingPeriodEnded(); // For future timed voting
        
        // Simple voting: prevent double voting per curator
        for (uint i = 0; i < proposal.voters.length; i++) {
            if (proposal.voters[i] == msg.sender) revert AlreadyVoted();
        }

        proposal.voters.push(msg.sender);

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ArtProposalVoted(proposalId, msg.sender, support);

        // Auto-approve or reject based on simple majority from CURATOR_ROLE count (example logic)
        // In a real DAO, this would involve more complex quorum/threshold logic
        uint256 totalCurators = getRoleMemberCount(CURATOR_ROLE);
        if (proposal.votesFor > totalCurators / 2 && totalCurators > 0) {
             approveArtProposal(proposalId); // Auto-approve if majority of curators vote yes
        } else if (proposal.votesAgainst > totalCurators / 2 && totalCurators > 0) {
             rejectArtProposal(proposalId); // Auto-reject if majority of curators vote no
        }
         // Note: If totalCurators is 0, or no majority, admin must manually approve/reject
    }

    /// @notice Admin or Curator manually approves an art proposal, triggering minting.
    /// @param proposalId The ID of the proposal to approve.
    function approveArtProposal(uint256 proposalId) public onlyCuratorOrAdmin {
        ArtProposal storage proposal = _proposals[proposalId];
        if (!proposal.exists || proposal.approved || proposal.rejected) revert ArtNotProposal();

        proposal.approved = true;
        // Mint the token
        safeMint(proposal.proposer, proposal.uri, proposal.artist, proposalId);

        emit ArtProposalApproved(proposalId, _artTokenIds.current());
    }

    /// @notice Admin or Curator manually rejects an art proposal.
    /// @param proposalId The ID of the proposal to reject.
    function rejectArtProposal(uint256 proposalId) public onlyCuratorOrAdmin {
        ArtProposal storage proposal = _proposals[proposalId];
        if (!proposal.exists || proposal.approved || proposal.rejected) revert ArtNotProposal();

        proposal.rejected = true;
        emit ArtProposalRejected(proposalId);
    }

    // --- Art Creation & Management ---

    /// @dev Mints a new art piece NFT. Called internally after proposal approval.
    /// @param to The address to mint the token to.
    /// @param uri The initial metadata URI.
    /// @param artist The address of the artist.
    /// @param proposalId The ID of the proposal this art corresponds to.
    function safeMint(address to, string memory uri, address artist, uint256 proposalId) internal {
        _artTokenIds.increment();
        uint256 newTokenId = _artTokenIds.current();

        _safeMint(to, newTokenId);

        _artPieces[newTokenId] = ArtPiece({
            tokenId: newTokenId,
            artist: artist,
            uri: uri,
            proposalId: proposalId,
            currentState: 0, // Initial state
            isFractionalized: false,
            totalFractions: 0,
            currentOwner: to // Store owner explicitly for easier lookup in some cases
        });

        emit ArtMinted(newTokenId, to, uri, artist, proposalId);
    }

    /// @notice Allows the artist or owner to update the metadata URI of an art piece.
    /// @param tokenId The ID of the token.
    /// @param newUri The new metadata URI.
    function updateArtMetadata(uint256 tokenId, string memory newUri) public {
        ArtPiece storage art = _artPieces[tokenId];
        // Allow only the artist or current owner
        if (msg.sender != art.artist && msg.sender != ownerOf(tokenId)) revert NotArtistOrOwner();
        if (_listings[tokenId].isListed || art.isFractionalized) revert CannotUpdateMetadataWhileListedOrFractionalized();

        art.uri = newUri;
        // Note: tokenURI function uses the dynamic rule URIs if set, otherwise this base URI
        // This update affects the base URI if no dynamic rule is active.
        emit ArtMetadataUpdated(tokenId, newUri);
    }

    /// @notice Allows Admin to assign or update the artist address associated with a token.
    /// Primarily for initial setup or corrections.
    /// @param tokenId The ID of the token.
    /// @param artistAddress The new artist address.
    function assignArtistRole(uint256 tokenId, address artistAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _artPieces[tokenId].artist = artistAddress;
        // Consider adding an event here if needed
    }


    // --- Marketplace Functions ---

    /// @notice Lists an art piece NFT for sale on the marketplace.
    /// @param tokenId The ID of the token to list.
    /// @param price The price in wei.
    function listArtForSale(uint256 tokenId, uint256 price) public onlyArtOwner(tokenId) {
        ArtPiece storage art = _artPieces[tokenId];
        if (art.isFractionalized) revert CannotListWhileFractionalized(); // Cannot list fractionalized art as a single piece

        _listings[tokenId] = MarketplaceListing({
            price: price,
            seller: msg.sender,
            isListed: true
        });
        emit ArtListed(tokenId, price, msg.sender);
    }

    /// @notice Purchases a listed art piece NFT.
    /// @param tokenId The ID of the token to buy.
    function buyArt(uint256 tokenId) public payable {
        MarketplaceListing storage listing = _listings[tokenId];
        if (!listing.isListed) revert ArtNotListed();
        if (msg.value < listing.price) revert NotEnoughEth();

        uint256 platformFee = listing.price.mul(_platformFeeBps).div(10000);
        uint256 sellerProceeds = listing.price.sub(platformFee);

        // Transfer ETH to seller and fee recipient
        // Use low-level call for robustness in case seller is a contract that reverts on receive
        (bool successSeller, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(successSeller, "ETH transfer to seller failed");

        // Accumulate fees internally, recipient withdraws later
        _totalPlatformFeesEth = _totalPlatformFeesEth.add(platformFee);
        emit FeesWithdrawn(_feeRecipient, platformFee); // Indicate fee collected

        // Transfer the NFT ownership
        address seller = listing.seller; // Store seller before deleting listing
        delete _listings[tokenId]; // Remove listing before transferring ownership
        _transfer(seller, msg.sender, tokenId);

        // Update art piece owner and emit purchase event
        _artPieces[tokenId].currentOwner = msg.sender;
        emit ArtPurchased(tokenId, msg.sender, seller, listing.price);

        // Refund any excess ETH sent by buyer
        if (msg.value > listing.price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value.sub(listing.price)}("");
            require(successRefund, "ETH refund failed");
        }
    }

    /// @notice Cancels a marketplace listing for an art piece.
    /// @param tokenId The ID of the token.
    function cancelListing(uint256 tokenId) public onlyArtOwner(tokenId) {
        MarketplaceListing storage listing = _listings[tokenId];
        if (!listing.isListed || listing.seller != msg.sender) revert ListingNotFound();

        delete _listings[tokenId];
        emit ListingCancelled(tokenId);
    }

    /// @notice Changes the price of an existing marketplace listing.
    /// @param tokenId The ID of the token.
    /// @param newPrice The new price in wei.
    function setListingPrice(uint256 tokenId, uint256 newPrice) public onlyArtOwner(tokenId) {
        MarketplaceListing storage listing = _listings[tokenId];
        if (!listing.isListed || listing.seller != msg.sender) revert ListingNotFound();

        listing.price = newPrice;
        emit ListingPriceUpdated(tokenId, newPrice);
    }

    // --- Dynamic Art Features ---

    /// @notice Sets the rules for how an art piece's state (and thus URI) can change.
    /// Only the artist or owner can set dynamic rules.
    /// @param tokenId The ID of the token.
    /// @param stateURIs Array of URIs representing different states (index 0 is initial).
    /// @param triggerType Integer representing the trigger type (0: Manual, 1: Time, 2: Purchase count, etc.).
    /// @param triggerParam Parameter for the trigger type (e.g., timestamp, count threshold).
    function setDynamicRule(uint256 tokenId, uint256[] memory stateURIs, uint256 triggerType, uint256 triggerParam) public {
        ArtPiece storage art = _artPieces[tokenId];
        if (msg.sender != art.artist && msg.sender != ownerOf(tokenId)) revert NotArtistOrOwner();
        require(stateURIs.length > 0, "Must provide at least one state URI");

        _dynamicRules[tokenId] = DynamicRule({
            stateURIs: stateURIs,
            triggerType: triggerType,
            triggerParam: triggerParam,
            exists: true
        });
        emit DynamicRuleSet(tokenId, triggerType, triggerParam);
    }

    /// @notice Attempts to trigger a state change for a dynamic art piece based on its rules.
    /// Anyone can call this, but the change only happens if the conditions are met.
    /// @param tokenId The ID of the token.
    function triggerDynamicStateChange(uint256 tokenId) public {
        ArtPiece storage art = _artPieces[tokenId];
        DynamicRule storage rule = _dynamicRules[tokenId];

        if (!rule.exists) revert DynamicRuleNotSet();

        uint256 oldState = art.currentState;
        uint256 newState = oldState;
        bool stateChanged = false;

        if (oldState >= rule.stateURIs.length - 1) {
             // Already at the final state, no more changes possible
             revert InvalidDynamicStateChange(); // Or just return without error
        }

        // Example trigger logic (can be extended)
        if (rule.triggerType == 0) { // Manual trigger by Owner/Artist
             if (msg.sender != art.artist && msg.sender != ownerOf(tokenId)) revert NotArtistOrOwner();
             newState = oldState + 1;
             stateChanged = true;
        }
        // Add more trigger types here (e.g., time-based, purchase count)
        // else if (rule.triggerType == 1) { // Time-based trigger
        //      if (block.timestamp >= rule.triggerParam) {
        //           newState = oldState + 1;
        //           stateChanged = true;
        //      }
        // }
        // else if (rule.triggerType == 2) { // Purchase count trigger (requires tracking purchases)
        //      // Example: if purchaseCount[tokenId] >= rule.triggerParam
        //      // newState = oldState + 1;
        //      // stateChanged = true;
        // }


        if (stateChanged && newState < rule.stateURIs.length) {
            art.currentState = newState;
            emit DynamicStateChanged(tokenId, oldState, newState);
        } else {
             revert InvalidDynamicStateChange(); // Conditions not met or already max state
        }
    }

    /// @notice Gets the current dynamic state index of an art piece.
    /// @param tokenId The ID of the token.
    /// @return The current state index.
    function getCurrentArtState(uint256 tokenId) public view returns (uint256) {
        return _artPieces[tokenId].currentState;
    }

    /// @notice Gets the dynamic rule definition for an art piece.
    /// @param tokenId The ID of the token.
    /// @return An array of state URIs, the trigger type, and the trigger parameter.
    function getDynamicRule(uint256 tokenId) public view returns (string[] memory stateURIs, uint256 triggerType, uint256 triggerParam) {
        DynamicRule storage rule = _dynamicRules[tokenId];
         if (!rule.exists) revert DynamicRuleNotSet();
         // Copy stateURIs to memory array to return
        string[] memory uris = new string[](rule.stateURIs.length);
        for(uint i = 0; i < rule.stateURIs.length; i++){
            uris[i] = tokenURI(tokenId); // Note: This might return the *current* state's URI if dynamic rule exists, not the full list.
                                         // A dedicated storage variable would be better if returning the *full list* is needed.
                                         // Let's update the struct to store the *list* explicitly. (Done in struct definition)
            uris[i] = rule.stateURIs[i]; // Correctly return the stored list.
        }
        return (uris, rule.triggerType, rule.triggerParam);
    }


    // --- Fractionalization Features (Internal) ---
    // Note: This is a simplified internal fractionalization. A production system would likely
    // deploy separate ERC20 contracts for each fractionalized piece or use a dedicated protocol.
    // This internal method avoids ERC20 deployment costs per piece but is less standard/composable.

    /// @notice Fractionalizes an art piece NFT into a specified number of internal fractions.
    /// Burns the original NFT.
    /// @param tokenId The ID of the token to fractionalize.
    /// @param totalFractions The total number of fractions to create. Must be > 0.
    function fractionalizeArt(uint256 tokenId, uint256 totalFractions) public onlyArtOwner(tokenId) {
        ArtPiece storage art = _artPieces[tokenId];
        if (art.isFractionalized) revert ArtAlreadyFractionalized();
        if (_listings[tokenId].isListed) revert CannotFractionalizeWhileListed();
        require(totalFractions > 0, "Total fractions must be greater than zero");

        address owner = ownerOf(tokenId);

        // Burn the ERC721 token
        _burn(tokenId);

        // Mark as fractionalized and store total fractions
        art.isFractionalized = true;
        art.totalFractions = totalFractions;
        // Update owner in our struct record as ERC721 owner is now address(0)
        art.currentOwner = address(0);

        // Issue all fractions to the original owner
        _fractionBalances[tokenId][owner] = totalFractions;

        emit ArtFractionalized(tokenId, owner, totalFractions);
    }

    /// @notice Transfers internal fractions of a fractionalized art piece.
    /// @param tokenId The ID of the fractionalized token.
    /// @param from The address to transfer fractions from.
    /// @param to The address to transfer fractions to.
    /// @param amount The amount of fractions to transfer.
    function transferFractions(uint256 tokenId, address from, address to, uint256 amount) public {
        ArtPiece storage art = _artPieces[tokenId];
        if (!art.isFractionalized) revert ArtNotFractionalized();
        require(from != address(0), "ERC721: transfer from the zero address");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(amount > 0, "Must transfer a non-zero amount");
        // Simple authorization: Only the 'from' address can transfer their own fractions in this basic example.
        // A full ERC1155-like approval system would be more complex.
        require(msg.sender == from, "Only the fraction owner can transfer");

        uint256 senderBalance = _fractionBalances[tokenId][from];
        if (senderBalance < amount) revert NotEnoughFractions();

        _fractionBalances[tokenId][from] = senderBalance.sub(amount);
        _fractionBalances[tokenId][to] = _fractionBalances[tokenId][to].add(amount);

        emit FractionsTransferred(tokenId, from, to, amount);
    }

    /// @notice Allows a user who owns all fractions of a piece to redeem them for the original NFT.
    /// Burns the fractions and re-mints the NFT to the redeemer.
    /// @param tokenId The ID of the fractionalized token.
    function redeemArtFromFractions(uint256 tokenId) public {
        ArtPiece storage art = _artPieces[tokenId];
        if (!art.isFractionalized) revert ArtNotFractionalized();

        uint256 redeemerBalance = _fractionBalances[tokenId][msg.sender];
        if (redeemerBalance < art.totalFractions) revert RedemptionRequiresAllFractions();

        // Burn all fractions held by the redeemer
        _fractionBalances[tokenId][msg.sender] = 0;

        // Re-mint the ERC721 token to the redeemer
        _safeMint(msg.sender, tokenId);

        // Mark as no longer fractionalized
        art.isFractionalized = false;
        art.totalFractions = 0;
        // Update owner in our struct record
        art.currentOwner = msg.sender;

        emit ArtRedeemedFromFractions(tokenId, msg.sender);
    }

    /// @notice Gets the total supply of fractions for a fractionalized art piece.
    /// @param tokenId The ID of the token.
    /// @return The total number of fractions. Returns 0 if not fractionalized.
    function getFractionSupply(uint256 tokenId) public view returns (uint256) {
        ArtPiece storage art = _artPieces[tokenId];
        if (!art.isFractionalized) return 0;
        return art.totalFractions;
    }

    /// @notice Gets a user's fraction balance for a fractionalized art piece.
    /// @param tokenId The ID of the token.
    /// @param owner The address to check the balance of.
    /// @return The user's fraction balance. Returns 0 if not fractionalized or balance is zero.
    function getFractionBalance(uint256 tokenId, address owner) public view returns (uint256) {
        return _fractionBalances[tokenId][owner];
    }


    // --- Administrative & Utility Functions ---

    /// @notice Sets the platform fee percentage for marketplace sales.
    /// @param feeBps The fee percentage in basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setPlatformFeePercentage(uint256 feeBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(feeBps <= 10000, InvalidFee());
        uint256 oldFee = _platformFeeBps;
        _platformFeeBps = feeBps;
        emit PlatformFeeUpdated(oldFee, feeBps);
    }

    /// @notice Sets the address that receives platform fees.
    /// @param recipient The address to receive fees.
    function setFeeRecipient(address recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(recipient != address(0), ZeroAddressRecipient());
        address oldRecipient = _feeRecipient;
        _feeRecipient = recipient;
        emit FeeRecipientUpdated(oldRecipient, recipient);
    }

    /// @notice Allows the fee recipient to withdraw collected platform fees.
    function withdrawPlatformFees() public {
        require(msg.sender == _feeRecipient, "Only fee recipient can withdraw");
        uint256 amount = _totalPlatformFeesEth;
        require(amount > 0, "No fees to withdraw");

        _totalPlatformFeesEth = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    /// @notice Grants a role to an account.
    /// @param role The role to grant (e.g., `CURATOR_ROLE`).
    /// @param account The account to grant the role to.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    /// @notice Revokes a role from an account.
    /// @param role The role to revoke.
    /// @param account The account to revoke the role from.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    /// @notice Retrieves details about an art piece.
    /// @param tokenId The ID of the token.
    /// @return Returns tokenId, artist, currentOwner, initialUri, currentState.
    function getArtDetails(uint256 tokenId) public view returns (uint256 id, address artist, address currentOwner, string memory initialUri, uint256 currentState) {
        ArtPiece storage art = _artPieces[tokenId];
        // Check if token exists using ERC721 ownerOf or our mapping
        if (ownerOf(tokenId) == address(0) && !art.isFractionalized) {
             // Token doesn't exist and isn't fractionalized
             revert ERC721: owner query for nonexistent token; // Standard ERC721 error
        }
        return (art.tokenId, art.artist, art.isFractionalized ? address(0) : ownerOf(tokenId), art.uri, art.currentState);
    }

     /// @notice Retrieves marketplace listing details for an art piece.
     /// @param tokenId The ID of the token.
     /// @return Returns isListed, price, seller.
    function getListingDetails(uint256 tokenId) public view returns (bool isListed, uint256 price, address seller) {
        MarketplaceListing storage listing = _listings[tokenId];
        return (listing.isListed, listing.price, listing.seller);
    }

    /// @notice Retrieves details about an art proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Returns id, uri, proposer, artist, votesFor, votesAgainst, voteEndTime, approved, rejected, voters.
    function getProposalDetails(uint256 proposalId) public view returns (uint256 id, string memory uri, address proposer, address artist, uint256 votesFor, uint256 votesAgainst, uint256 voteEndTime, bool approved, bool rejected, address[] memory votersList) {
        ArtProposal storage proposal = _proposals[proposalId];
        if (!proposal.exists) revert ArtNotProposal();
         // Copy voters array to memory to return
        address[] memory votersCopy = new address[](proposal.voters.length);
        for(uint i = 0; i < proposal.voters.length; i++){
            votersCopy[i] = proposal.voters[i];
        }

        return (proposalId, proposal.uri, proposal.proposer, proposal.artist, proposal.votesFor, proposal.votesAgainst, proposal.voteEndTime, proposal.approved, proposal.rejected, votersCopy);
    }

    /// @notice Gets the vote count for a specific proposal.
    /// @dev This function is technically redundant with getProposalDetails but requested for summary count.
    /// @param proposalId The ID of the proposal.
    /// @return Returns an array of voter addresses and their vote (1 for support, 0 for against - simplified, needs more logic).
    /// Note: In this simple example, we only store the voter address, not how they voted individually.
    /// Returning voters list only for demonstration. A real system would track vote choice per voter.
    function getVotesForProposal(uint256 proposalId) public view returns (address[] memory voters, uint256[] memory voteValues) {
         ArtProposal storage proposal = _proposals[proposalId];
         if (!proposal.exists) revert ArtNotProposal();

        // In this simple implementation, we only track *who* voted, not *how*.
        // To return individual vote values, we'd need a mapping like mapping(uint256 => mapping(address => bool)) voterSupport;
        // For demonstration, we'll return the voters list and a dummy array for vote values.
        address[] memory votersCopy = new address[](proposal.voters.length);
        uint256[] memory dummyVoteValues = new uint256[](proposal.voters.length); // Placeholder

        for(uint i = 0; i < proposal.voters.length; i++){
            votersCopy[i] = proposal.voters[i];
            // In a real system, populate dummyVoteValues based on actual stored vote choice
            // dummyVoteValues[i] = voterSupport[proposalId][votersCopy[i]] ? 1 : 0;
        }
        return (votersCopy, dummyVoteValues); // Return voters list, dummy vote values
    }

    // ERC165 support for ERC721 and AccessControl
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Standard AccessControl view functions
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return super.hasRole(role, account);
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return super.getRoleAdmin(role);
    }

    // Internal function required by ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // Required by ERC721Enumerable for tokenByIndex/tokenOfOwnerByIndex
    function _increaseBalance(address account, uint256 amount) internal override(ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

     // Required by ERC721Enumerable for tokenByIndex/tokenOfOwnerByIndex
    function _decreaseBalance(address account, uint256 amount) internal override(ERC721Enumerable) {
        super._decreaseBalance(account, amount);
    }
}
```