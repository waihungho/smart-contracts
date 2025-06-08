Okay, here is a smart contract for an `AdvancedDecentralizedArtGallery`. This contract incorporates several advanced concepts like:

1.  **Role-Based Access Control:** Using OpenZeppelin roles for owner, admins, and artists.
2.  **Multi-Party Programmable Royalties:** Artists can define multiple recipients and their percentage shares for royalties on future sales.
3.  **Internal Fractionalization:** A mechanism to split ownership of a single ERC-721 token into multiple internal "fractions" with a time-bound sale period and a reconstruction mechanism. *This is distinct from wrapping the NFT in an ERC-1155.*
4.  **Basic On-Chain Governance:** A simple proposal and voting system for modifying certain gallery parameters (like fees).
5.  **Dynamic Art Metadata Concept:** A mechanism to track on-chain activity (like total value traded) for an art piece and potentially allow updating its metadata URI based on predefined thresholds or states.
6.  **Detailed State Tracking:** Keeping track of art details, sales history, fractionalization status, proposal states, etc.
7.  **Fee Collection:** Gallery collects a fee on sales.

It aims to provide a platform for artists to submit unique art, enable novel ownership structures, and allow community input on gallery operations.

Let's start with the outline and function summary.

---

## Contract: AdvancedDecentralizedArtGallery

**Description:**
This contract implements a decentralized art gallery platform built on ERC-721. It goes beyond standard marketplaces by introducing features like programmable multi-party royalties, a unique internal fractionalization system with reconstruction, basic on-chain governance for gallery parameters, and a concept for dynamic art metadata based on on-chain activity.

**Concepts Covered:**
*   ERC-721 Non-Fungible Tokens (Basic art representation)
*   Role-Based Access Control (OpenZeppelin AccessControl)
*   Multi-Party Royalty Distribution
*   Internal Fractional Ownership (Custom Logic)
*   Time-Based Mechanics (Fractionalization periods)
*   Basic On-Chain Proposal & Voting Governance
*   Dynamic Metadata (Based on on-chain state)
*   Fee Collection

**Modules:**
1.  **Core:** Basic setup, roles, fees.
2.  **Art Management:** Minting, tracking art details, handling dynamic states.
3.  **Sales & Listings:** Direct purchase listings.
4.  **Royalties:** Setting and distributing multi-party royalties.
5.  **Fractionalization:** Splitting, selling fractions, and reconstructing.
6.  **Governance:** Proposing, voting, and executing changes.
7.  **Queries:** View functions for retrieving state.

---

## Function Summary:

1.  `constructor()`: Initializes the contract, sets roles and default fee.
2.  `setGalleryFee(uint256 newFee)`: Allows ADMIN_ROLE to set the gallery's sales fee.
3.  `withdrawFees(address payable recipient)`: Allows ADMIN_ROLE to withdraw accumulated fees.
4.  `submitArt(string memory tokenURI, bool isDynamic)`: Allows ARTIST_ROLE to mint a new art NFT with initial metadata.
5.  `updateArtURI(uint256 tokenId, string memory newTokenURI)`: Allows the art owner to update the token URI (intended for static updates or linking to dynamic metadata outside the contract logic).
6.  `getArtDetails(uint256 tokenId)`: Retrieves detailed information about an art piece.
7.  `listArtForSale(uint256 tokenId, uint256 price)`: Allows the owner of an art piece to list it for direct purchase.
8.  `buyListedArt(uint256 tokenId)`: Allows a buyer to purchase a listed art piece. Handles payment, ownership transfer, fee collection, and royalty distribution.
9.  `cancelListing(uint256 tokenId)`: Allows the seller to cancel an active listing.
10. `setArtRoyalties(uint256 tokenId, address[] memory recipients, uint256[] memory shares)`: Allows the art owner to define multiple royalty recipients and their shares for future sales of this token.
11. `getArtRoyalties(uint256 tokenId)`: Retrieves the defined royalty structure for a specific art piece.
12. `fractionalizeArt(uint256 tokenId, uint256 totalFractions, uint256 pricePerFraction, uint256 duration)`: Allows the art owner (or ADMIN_ROLE?) to initiate the fractionalization of an art piece. Starts a time-limited sale of fractions.
13. `buyFraction(uint256 tokenId, uint256 amount)`: Allows users to buy fractions of a fractionalized art piece during the active sale period.
14. `transferFraction(uint256 tokenId, address from, address to, uint256 amount)`: Allows transferring ownership of internal fractions between addresses. Emulates ERC-1155 transfer for fractions.
15. `getFractionBalance(uint256 tokenId, address account)`: Retrieves the fraction balance for a specific account and art piece.
16. `reconstructArt(uint256 tokenId)`: Allows a user who owns ALL fractions of an art piece to burn their fractions and reclaim the original ERC-721 token.
17. `collectFractionSaleProceeds(uint256 tokenId)`: Allows the original owner of a fractionalized art piece to collect the Ether accumulated from fraction sales after the sale period ends.
18. `getFractionalizationDetails(uint256 tokenId)`: Retrieves details about the fractionalization status of an art piece.
19. `submitProposal(string memory description, address targetContract, bytes memory callData)`: Allows a privileged role (e.g., ADMIN_ROLE or a custom GOVERNOR_ROLE) to submit a governance proposal to change gallery parameters (via targetContract and callData).
20. `voteOnProposal(uint256 proposalId, bool supports)`: Allows users (potentially based on a specific criteria, here simplified to 1 address 1 vote) to vote on an active proposal.
21. `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal if the voting period is over and it has passed the required threshold.
22. `getProposalStatus(uint256 proposalId)`: Retrieves the current status of a proposal.
23. `getProposalDetails(uint256 proposalId)`: Retrieves the full details of a proposal.
24. `triggerDynamicMetadataUpdate(uint256 tokenId)`: (Conceptual/Simplified) Allows anyone to trigger an update check for dynamic metadata based on the art piece's accumulated trading value. *Note: The actual dynamic metadata generation and URI logic is complex and often involves off-chain components, this function provides the on-chain trigger and state update.*
25. `getDynamicMetadataURI(uint256 tokenId)`: Returns the current token URI, potentially updated if `triggerDynamicMetadataUpdate` has been called and conditions met.
26. `getTotalValueTraded(uint256 tokenId)`: View function to see the total Ether value traded for a specific art piece through this contract.
27. `getTokenIdsForArtist(address artist)`: (Helper view) Returns a list of token IDs minted by a specific artist.
28. `getListedArtIds()`: (Helper view) Returns a list of token IDs currently listed for sale.
29. `_distributeRoyalties(uint256 tokenId, uint256 totalAmount)`: Internal helper function to distribute royalties based on the set structure.
30. `_updateDynamicMetadataState(uint256 tokenId)`: Internal helper function to update the dynamic state based on total value traded.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Custom Errors for clarity
error AdvancedGallery__InsufficientPayment(uint256 tokenId, uint256 required, uint256 provided);
error AdvancedGallery__NotListedForSale(uint256 tokenId);
error AdvancedGallery__NotOwnerOfListing(uint256 tokenId, address caller);
error AdvancedGallery__RoyaltySharesMustSumTo10000(); // Using basis points
error AdvancedGallery__RoyaltyRecipientsAndSharesMismatch();
error AdvancedGallery__ArtAlreadyFractionalized(uint256 tokenId);
error AdvancedGallery__FractionalizationPeriodActive(uint256 tokenId);
error AdvancedGallery__FractionalizationPeriodNotActive(uint256 tokenId);
error AdvancedGallery__FractionSalePeriodActiveCannotCollect(uint256 tokenId);
error AdvancedGallery__FractionSalePeriodNotEndedCannotCollect(uint256 tokenId);
error AdvancedGallery__FractionalizationNotInitiated(uint256 tokenId);
error AdvancedGallery__NotEnoughFractionsOwned(uint256 tokenId, uint256 required, uint256 owned);
error AdvancedGallery__CannotReconstructUnlessAllFractionsOwned(uint256 tokenId, uint256 totalFractions, uint256 owned);
error AdvancedGallery__ProposalDoesNotExist(uint256 proposalId);
error AdvancedGallery__ProposalVotingPeriodNotActive(uint256 proposalId);
error AdvancedGallery__ProposalAlreadyVoted(uint256 proposalId, address voter);
error AdvancedGallery__ProposalExecutionPeriodNotReached(uint256 proposalId);
error AdvancedGallery__ProposalAlreadyExecuted(uint256 proposalId);
error AdvancedGallery__ProposalExecutionFailed(uint256 proposalId);
error AdvancedGallery__OnlyFractionOwner(uint256 tokenId, address caller);
error AdvancedGallery__TransferAmountExceedsBalance(uint256 tokenId, address account, uint256 requested, uint256 owned);


contract AdvancedDecentralizedArtGallery is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    // Could add a GOVERNOR_ROLE if governance voting power was different from user base

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public galleryFeeBps; // Fee in basis points (e.g., 500 for 5%)
    address payable public feeRecipient;

    // --- Art Details ---
    struct ArtInfo {
        address artist;
        string initialURI;
        bool isDynamic;
        uint256 totalValueTraded; // Accumulated value from sales
        string currentDynamicURI; // Could store a dynamic URI based on state
    }
    mapping(uint256 => ArtInfo) private _artInfo;
    mapping(address => uint256[]) private _artistTokens; // Track tokens per artist

    // --- Sales & Listings ---
    struct Listing {
        uint256 price;
        address payable seller; // Store payable address here for easier withdrawal
    }
    mapping(uint256 => Listing) private _listings; // tokenId => Listing
    uint256[] private _listedTokenIds; // Simple array to track listed IDs (less efficient for large lists, but works)
    mapping(uint256 => bool) private _isListed; // Check if a token is listed

    // --- Royalties ---
    struct RoyaltyInfo {
        address[] recipients;
        uint256[] shares; // Shares in basis points, sum must be 10000
    }
    mapping(uint256 => RoyaltyInfo) private _royalties; // tokenId => RoyaltyInfo

    // --- Fractionalization ---
    struct FractionalizationInfo {
        bool isFractionalized;
        uint256 totalFractions;
        uint256 pricePerFraction;
        uint256 startTime;
        uint256 endTime;
        address originalOwner; // The owner who initiated fractionalization
        uint256 fractionsSold;
        uint256 collectedProceeds; // Ether collected from fraction sales
    }
    mapping(uint256 => FractionalizationInfo) private _fractionalizationInfo;
    // Mapping for tracking internal fraction balances: tokenId => owner => balance
    mapping(uint256 => mapping(address => uint256)) private _fractionBalances;

    // --- Governance ---
    struct Proposal {
        address proposer;
        string description;
        address targetContract;
        bytes callData;
        uint256 submissionTime;
        uint256 votingEndTime; // Could be fixed duration or set per proposal
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool exists; // To check if proposalId is valid
    }
    mapping(uint256 => Proposal) private _proposals;
    // Users can vote once per proposal (simplified 1 address 1 vote)
    mapping(uint256 => mapping(address => bool)) private _hasVoted;
    uint256 public proposalVotingPeriod = 7 days; // Example: 7 days voting period

    // --- Events ---
    event GalleryFeeUpdated(uint256 oldFee, uint256 newFee);
    event GalleryFeesWithdrawn(uint256 amount, address recipient);
    event ArtSubmitted(uint256 indexed tokenId, address indexed artist, string tokenURI, bool isDynamic);
    event ArtURIUpdated(uint256 indexed tokenId, string newTokenURI);
    event ArtListedForSale(uint256 indexed tokenId, uint256 price, address indexed seller);
    event ArtSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event RoyaltiesSet(uint256 indexed tokenId, address indexed owner, address[] recipients, uint256[] shares);
    event RoyaltyDistributed(uint256 indexed tokenId, uint256 totalAmount, address indexed recipient, uint256 amount);
    event ArtFractionalized(uint256 indexed tokenId, address indexed originalOwner, uint256 totalFractions, uint256 pricePerFraction, uint256 endTime);
    event FractionBought(uint256 indexed tokenId, address indexed buyer, uint256 amount, uint256 totalPrice);
    event FractionTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event ArtReconstructed(uint256 indexed tokenId, address indexed newOwner);
    event FractionSaleProceedsCollected(uint256 indexed tokenId, address indexed originalOwner, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool supports);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event DynamicMetadataStateUpdated(uint256 indexed tokenId, uint256 totalValueTraded, string newUri);

    constructor(address payable _feeRecipient) ERC721("Advanced Decentralized Art Gallery", "ADAG") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender); // Grant admin role to deployer
        feeRecipient = _feeRecipient;
        galleryFeeBps = 500; // 5% default fee
    }

    // --- Core ---
    function setGalleryFee(uint256 newFee) external onlyRole(ADMIN_ROLE) {
        uint256 oldFee = galleryFeeBps;
        galleryFeeBps = newFee;
        emit GalleryFeeUpdated(oldFee, newFee);
    }

    function withdrawFees(address payable recipient) external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "AdvancedGallery: No fees to withdraw");
        feeRecipient = recipient; // Allow changing recipient on withdrawal if needed, or keep fixed. Let's allow changing.
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "AdvancedGallery: Fee withdrawal failed");
        emit GalleryFeesWithdrawn(balance, recipient);
    }

    // --- Art Management ---
    function submitArt(string memory tokenURI, bool isDynamic) external onlyRole(ARTIST_ROLE) returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, tokenId);

        _artInfo[tokenId] = ArtInfo({
            artist: msg.sender,
            initialURI: tokenURI,
            isDynamic: isDynamic,
            totalValueTraded: 0,
            currentDynamicURI: tokenURI // Start with the initial URI
        });

        _artistTokens[msg.sender].push(tokenId);

        emit ArtSubmitted(tokenId, msg.sender, tokenURI, isDynamic);
    }

    function updateArtURI(uint256 tokenId, string memory newTokenURI) external {
        // Only owner can update static URI, or base for dynamic
        require(_isApprovedOrOwner(msg.sender, tokenId), "AdvancedGallery: Not authorized to update URI");
        _artInfo[tokenId].initialURI = newTokenURI;
         if (!_artInfo[tokenId].isDynamic) {
            _artInfo[tokenId].currentDynamicURI = newTokenURI; // Update current for non-dynamic
        }
        _setTokenURI(tokenId, newTokenURI); // Update ERC721 metadata URI
        emit ArtURIUpdated(tokenId, newTokenURI);
    }

     // Override ERC721's tokenURI to potentially return the dynamic URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _artInfo[tokenId].currentDynamicURI;
    }


    function getArtDetails(uint256 tokenId) external view returns (
        address artist,
        string memory initialURI,
        bool isDynamic,
        uint256 totalValueTraded,
        string memory currentDynamicURI,
        address owner
    ) {
        ArtInfo storage art = _artInfo[tokenId];
        require(art.artist != address(0), "AdvancedGallery: Art does not exist");
        return (
            art.artist,
            art.initialURI,
            art.isDynamic,
            art.totalValueTraded,
            art.currentDynamicURI,
            ownerOf(tokenId)
        );
    }

    // --- Sales & Listings ---
    function listArtForSale(uint256 tokenId, uint256 price) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AdvancedGallery: Not authorized to list");
        require(!_isListed[tokenId], "AdvancedGallery: Art already listed");
        // Ensure contract can transfer the token
        require(isApprovedForAll(msg.sender, address(this)) || getApproved(tokenId) == address(this),
            "AdvancedGallery: Gallery contract not approved for transfer");

        _listings[tokenId] = Listing({
            price: price,
            seller: payable(msg.sender)
        });
        _listedTokenIds.push(tokenId); // Add to tracking array
        _isListed[tokenId] = true;

        emit ArtListedForSale(tokenId, price, msg.sender);
    }

    function buyListedArt(uint256 tokenId) external payable {
        Listing storage listing = _listings[tokenId];
        require(_isListed[tokenId], AdvancedGallery__NotListedForSale(tokenId));
        require(msg.value >= listing.price, AdvancedGallery__InsufficientPayment(tokenId, listing.price, msg.value));

        address payable seller = listing.seller;
        uint256 salePrice = listing.price;
        uint256 galleryFeeAmount = salePrice.mul(galleryFeeBps).div(10000);
        uint256 amountAfterFee = salePrice.sub(galleryFeeAmount);

        // 1. Transfer NFT to buyer
        _safeTransfer(seller, msg.sender, tokenId);

        // 2. Update art trading stats
        _artInfo[tokenId].totalValueTraded = _artInfo[tokenId].totalValueTraded.add(salePrice);

        // 3. Collect gallery fee
        (bool successFee, ) = feeRecipient.call{value: galleryFeeAmount}("");
        require(successFee, "AdvancedGallery: Fee transfer failed");

        // 4. Distribute royalties and send remaining to seller
        _distributeRoyalties(tokenId, amountAfterFee); // This handles sending to seller as part of royalties

        // 5. Clean up listing
        delete _listings[tokenId];
        _isListed[tokenId] = false;
        // Remove from _listedTokenIds array (inefficient, but simple example)
        for (uint i = 0; i < _listedTokenIds.length; i++) {
            if (_listedTokenIds[i] == tokenId) {
                _listedTokenIds[i] = _listedTokenIds[_listedTokenIds.length - 1];
                _listedTokenIds.pop();
                break;
            }
        }

        // 6. Handle potential refund for overpayment
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }

        // 7. Trigger dynamic metadata update check
        if (_artInfo[tokenId].isDynamic) {
            _updateDynamicMetadataState(tokenId);
        }


        emit ArtSold(tokenId, msg.sender, seller, salePrice);
    }

    function cancelListing(uint256 tokenId) external {
        require(_isListed[tokenId], AdvancedGallery__NotListedForSale(tokenId));
        require(_listings[tokenId].seller == msg.sender, AdvancedGallery__NotOwnerOfListing(tokenId, msg.sender));

        delete _listings[tokenId];
        _isListed[tokenId] = false;
         // Remove from _listedTokenIds array (inefficient, but simple example)
        for (uint i = 0; i < _listedTokenIds.length; i++) {
            if (_listedTokenIds[i] == tokenId) {
                _listedTokenIds[i] = _listedTokenIds[_listedTokenIds.length - 1];
                _listedTokenIds.pop();
                break;
            }
        }

        emit ListingCancelled(tokenId);
    }

    // --- Royalties ---
    function setArtRoyalties(uint256 tokenId, address[] memory recipients, uint256[] memory shares) external {
        // Only owner or artist? Let's allow owner to set/update
        require(_isApprovedOrOwner(msg.sender, tokenId), "AdvancedGallery: Not authorized to set royalties");
        require(recipients.length == shares.length, AdvancedGallery__RoyaltyRecipientsAndSharesMismatch());

        uint256 totalShares = 0;
        for (uint i = 0; i < shares.length; i++) {
            totalShares = totalShares.add(shares[i]);
        }
        require(totalShares <= 10000, AdvancedGallery__RoyaltySharesMustSumTo10000()); // Allow less than 100% for owner cut

        _royalties[tokenId] = RoyaltyInfo({
            recipients: recipients,
            shares: shares
        });

        emit RoyaltiesSet(tokenId, msg.sender, recipients, shares);
    }

    function getArtRoyalties(uint256 tokenId) external view returns (address[] memory recipients, uint256[] memory shares) {
        return (_royalties[tokenId].recipients, _royalties[tokenId].shares);
    }

    // Internal function to distribute royalties and remaining amount to the seller
    function _distributeRoyalties(uint256 tokenId, uint256 totalAmount) internal {
        RoyaltyInfo storage royalty = _royalties[tokenId];
        address payable seller = _listings[tokenId].seller; // Get seller from listing

        uint256 distributedAmount = 0;

        for (uint i = 0; i < royalty.recipients.length; i++) {
            uint256 royaltyAmount = totalAmount.mul(royalty.shares[i]).div(10000);
            if (royaltyAmount > 0) {
                 (bool success, ) = payable(royalty.recipients[i]).call{value: royaltyAmount}("");
                 // Optionally handle failed transfers, for simplicity here, just require success
                 require(success, string(abi.encodePacked("AdvancedGallery: Royalty transfer failed for recipient ", Address.toString(royalty.recipients[i]))));
                 distributedAmount = distributedAmount.add(royaltyAmount);
                 emit RoyaltyDistributed(tokenId, totalAmount, royalty.recipients[i], royaltyAmount);
            }
        }

        // Send remaining amount to the seller (original owner at time of listing)
        uint256 sellerAmount = totalAmount.sub(distributedAmount);
        if (sellerAmount > 0) {
            (bool success, ) = seller.call{value: sellerAmount}("");
            require(success, "AdvancedGallery: Seller payment failed");
            // Consider emitting an event for seller payment too if needed
        }
    }

    // --- Fractionalization ---
    function fractionalizeArt(
        uint256 tokenId,
        uint256 totalFractions,
        uint256 pricePerFraction,
        uint256 duration
    ) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "AdvancedGallery: Not authorized to fractionalize");
        require(!_fractionalizationInfo[tokenId].isFractionalized, AdvancedGallery__ArtAlreadyFractionalized(tokenId));
        require(totalFractions > 1, "AdvancedGallery: Total fractions must be more than 1");
        require(duration > 0, "AdvancedGallery: Duration must be greater than 0");

        // Transfer the original NFT to the contract
        _safeTransfer(msg.sender, address(this), tokenId);

        _fractionalizationInfo[tokenId] = FractionalizationInfo({
            isFractionalized: true,
            totalFractions: totalFractions,
            pricePerFraction: pricePerFraction,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            originalOwner: msg.sender, // The address that receives Ether from fraction sales
            fractionsSold: 0,
            collectedProceeds: 0
        });

        emit ArtFractionalized(tokenId, msg.sender, totalFractions, pricePerFraction, block.timestamp + duration);
    }

    function buyFraction(uint256 tokenId, uint256 amount) external payable {
        FractionalizationInfo storage fracInfo = _fractionalizationInfo[tokenId];
        require(fracInfo.isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));
        require(block.timestamp >= fracInfo.startTime && block.timestamp <= fracInfo.endTime, AdvancedGallery__FractionalizationPeriodNotActive(tokenId));

        uint256 cost = amount.mul(fracInfo.pricePerFraction);
        require(msg.value >= cost, AdvancedGallery__InsufficientPayment(tokenId, cost, msg.value));
        require(fracInfo.fractionsSold.add(amount) <= fracInfo.totalFractions, "AdvancedGallery: Not enough fractions remaining");

        _fractionBalances[tokenId][msg.sender] = _fractionBalances[tokenId][msg.sender].add(amount);
        fracInfo.fractionsSold = fracInfo.fractionsSold.add(amount);

        // Excess payment is refunded automatically by payable function
        if (msg.value > cost) {
             payable(msg.sender).transfer(msg.value - cost);
        }

        emit FractionBought(tokenId, msg.sender, amount, cost);
    }

    function transferFraction(uint256 tokenId, address from, address to, uint256 amount) external {
        require(_fractionalizationInfo[tokenId].isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));
        require(from == msg.sender || isApprovedForAll(from, msg.sender), AdvancedGallery__OnlyFractionOwner(tokenId, msg.sender));
        require(amount <= _fractionBalances[tokenId][from], AdvancedGallery__TransferAmountExceedsBalance(tokenId, from, amount, _fractionBalances[tokenId][from]));
        require(to != address(0), "ERC1155: transfer to the zero address"); // Standard check

        _fractionBalances[tokenId][from] = _fractionBalances[tokenId][from].sub(amount);
        _fractionBalances[tokenId][to] = _fractionBalances[tokenId][to].add(amount);

        emit FractionTransferred(tokenId, from, to, amount);
    }

    function getFractionBalance(uint256 tokenId, address account) external view returns (uint256) {
         require(_fractionalizationInfo[tokenId].isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));
         return _fractionBalances[tokenId][account];
    }

    function reconstructArt(uint256 tokenId) external {
        FractionalizationInfo storage fracInfo = _fractionalizationInfo[tokenId];
        require(fracInfo.isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));
        // Can only reconstruct AFTER the fraction sale period ends
        require(block.timestamp > fracInfo.endTime, AdvancedGallery__FractionalizationPeriodActive(tokenId));

        uint256 ownerFractions = _fractionBalances[tokenId][msg.sender];
        require(ownerFractions == fracInfo.totalFractions, AdvancedGallery__CannotReconstructUnlessAllFractionsOwned(tokenId, fracInfo.totalFractions, ownerFractions));

        // Burn the fractions
        _fractionBalances[tokenId][msg.sender] = 0;

        // Transfer the original NFT back to the reconstructor
        _safeTransfer(address(this), msg.sender, tokenId);

        // Reset fractionalization state
        delete _fractionalizationInfo[tokenId];
        // Note: Historical fraction balances remain in _fractionBalances mapping

        emit ArtReconstructed(tokenId, msg.sender);
    }

    function collectFractionSaleProceeds(uint256 tokenId) external {
        FractionalizationInfo storage fracInfo = _fractionalizationInfo[tokenId];
        require(fracInfo.isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));
        require(msg.sender == fracInfo.originalOwner, "AdvancedGallery: Only original owner can collect proceeds");
        require(block.timestamp > fracInfo.endTime, AdvancedGallery__FractionSalePeriodNotEndedCannotCollect(tokenId));
        require(fracInfo.fractionsSold > 0, "AdvancedGallery: No fractions were sold");
        require(fracInfo.collectedProceeds < fracInfo.fractionsSold.mul(fracInfo.pricePerFraction), "AdvancedGallery: Proceeds already collected");

        uint256 totalProceeds = fracInfo.fractionsSold.mul(fracInfo.pricePerFraction);
        uint256 uncollectedProceeds = totalProceeds.sub(fracInfo.collectedProceeds);

        fracInfo.collectedProceeds = totalProceeds; // Mark all as collected

        (bool success, ) = payable(fracInfo.originalOwner).call{value: uncollectedProceeds}("");
        require(success, "AdvancedGallery: Proceed collection failed");

        emit FractionSaleProceedsCollected(tokenId, fracInfo.originalOwner, uncollectedProceeds);
    }

    function getFractionalizationDetails(uint256 tokenId) external view returns (
        bool isFractionalized,
        uint256 totalFractions,
        uint256 pricePerFraction,
        uint256 startTime,
        uint256 endTime,
        address originalOwner,
        uint256 fractionsSold,
        uint256 collectedProceeds
    ) {
        FractionalizationInfo storage fracInfo = _fractionalizationInfo[tokenId];
        require(fracInfo.isFractionalized, AdvancedGallery__FractionalizationNotInitiated(tokenId));

        return (
            fracInfo.isFractionalized,
            fracInfo.totalFractions,
            fracInfo.pricePerFraction,
            fracInfo.startTime,
            fracInfo.endTime,
            fracInfo.originalOwner,
            fracInfo.fractionsSold,
            fracInfo.collectedProceeds
        );
    }


    // --- Governance ---
    // Simplified governance: ADMIN_ROLE can submit proposals. Anyone can vote (1 address 1 vote). Simple majority wins.
    function submitProposal(string memory description, address targetContract, bytes memory callData) external onlyRole(ADMIN_ROLE) returns (uint256 proposalId) {
        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        _proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            targetContract: targetContract,
            callData: callData,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            exists: true
        });

        emit ProposalSubmitted(proposalId, msg.sender, description);
        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool supports) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, AdvancedGallery__ProposalDoesNotExist(proposalId));
        require(block.timestamp >= proposal.submissionTime && block.timestamp <= proposal.votingEndTime, AdvancedGallery__ProposalVotingPeriodNotActive(proposalId));
        require(!_hasVoted[proposalId][msg.sender], AdvancedGallery__ProposalAlreadyVoted(proposalId, msg.sender));

        _hasVoted[proposalId][msg.sender] = true;

        if (supports) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }

        emit VoteCast(proposalId, msg.sender, supports);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.exists, AdvancedGallery__ProposalDoesNotExist(proposalId));
        require(block.timestamp > proposal.votingEndTime, AdvancedGallery__ProposalExecutionPeriodNotReached(proposalId));
        require(!proposal.executed, AdvancedGallery__ProposalAlreadyExecuted(proposalId));

        // Simple majority threshold: More votes FOR than AGAINST
        bool passed = proposal.votesFor > proposal.votesAgainst;

        if (passed) {
            // Execute the proposal's call data
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, AdvancedGallery__ProposalExecutionFailed(proposalId));
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, passed);
    }

    function getProposalStatus(uint256 proposalId) external view returns (bool exists, bool active, bool passed, bool executed) {
        Proposal storage proposal = _proposals[proposalId];
        exists = proposal.exists;
        if (!exists) return (false, false, false, false);

        active = block.timestamp >= proposal.submissionTime && block.timestamp <= proposal.votingEndTime && !proposal.executed;
        passed = proposal.votesFor > proposal.votesAgainst; // Status at current time
        executed = proposal.executed;

        return (exists, active, passed, executed);
    }

     function getProposalDetails(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        address targetContract,
        bytes memory callData,
        uint256 submissionTime,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst
    ) {
        Proposal storage proposal = _proposals[proposalId];
         require(proposal.exists, AdvancedGallery__ProposalDoesNotExist(proposalId));

        return (
            proposal.proposer,
            proposal.description,
            proposal.targetContract,
            proposal.callData,
            proposal.submissionTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst
        );
    }

    // --- Dynamic Art (Conceptual/Simplified) ---
    // This is a simplified approach. A real dynamic NFT would likely involve
    // off-chain services monitoring on-chain state and updating metadata via signed messages
    // or requiring a trusted oracle. Here, we allow anyone to trigger an update check
    // based on a simple on-chain metric (totalValueTraded).
    // The actual URI generation logic based on the state would happen off-chain,
    // and the function here would update the `currentDynamicURI` based on this logic.
    // For demonstration, we'll just update the URI based on reaching a certain threshold.
    uint256 public dynamicThreshold1 = 10 ether; // Example threshold

    function triggerDynamicMetadataUpdate(uint256 tokenId) external {
        ArtInfo storage art = _artInfo[tokenId];
        require(art.artist != address(0), "AdvancedGallery: Art does not exist");
        require(art.isDynamic, "AdvancedGallery: Art is not dynamic");

        _updateDynamicMetadataState(tokenId);

        // In a real scenario, this would fetch/calculate a new URI based on the state
        // and update _artInfo[tokenId].currentDynamicURI
        // For this example, let's simulate an update based on a threshold
        string memory oldUri = art.currentDynamicURI;
        string memory newUri = art.initialURI; // Start with initial

        if (art.totalValueTraded >= dynamicThreshold1) {
             // Example: Append a state indicator to the URI
             // In practice, this would resolve to different content off-chain
             newUri = string(abi.encodePacked(art.initialURI, "?state=traded_tier_1")); // Conceptual
        }
        // Add more thresholds/states if needed

        if (bytes(oldUri).length != bytes(newUri).length || keccak256(bytes(oldUri)) != keccak256(bytes(newUri))) {
             art.currentDynamicURI = newUri;
             _setTokenURI(tokenId, newUri); // Update ERC721 metadata for OpenSea etc.
             emit DynamicMetadataStateUpdated(tokenId, art.totalValueTraded, newUri);
        }
         // If no change in state, no event or URI update happens
    }

    // Internal helper to just update the state logic within the contract
     function _updateDynamicMetadataState(uint256 tokenId) internal {
        // Read art.totalValueTraded and potentially update internal state variables
        // that the off-chain service would read to determine the metadata.
        // For this example, we just rely on totalValueTraded directly in triggerDynamicMetadataUpdate logic.
     }

    function getDynamicMetadataURI(uint256 tokenId) external view returns (string memory) {
         require(_artInfo[tokenId].artist != address(0), "AdvancedGallery: Art does not exist");
         return _artInfo[tokenId].currentDynamicURI;
    }

    function getTotalValueTraded(uint256 tokenId) external view returns (uint256) {
         require(_artInfo[tokenId].artist != address(0), "AdvancedGallery: Art does not exist");
         return _artInfo[tokenId].totalValueTraded;
    }


    // --- Queries (Helper Views) ---
    function getTokenIdsForArtist(address artist) external view returns (uint256[] memory) {
        return _artistTokens[artist];
    }

    function getListedArtIds() external view returns (uint256[] memory) {
        // This array tracks additions but not removals efficiently.
        // For production, a more robust way to iterate active listings is needed.
        // Simple filtered list:
        uint256[] memory activeListings = new uint256[](_listedTokenIds.length); // Max possible size
        uint256 count = 0;
        for(uint i = 0; i < _listedTokenIds.length; i++) {
            uint256 tokenId = _listedTokenIds[i];
            if (_isListed[tokenId]) { // Check if it's still actually listed
                activeListings[count] = tokenId;
                count++;
            }
        }
        // Resize array
        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = activeListings[i];
        }
        return result;
    }

    // Override required ERC721 functions related to approvals
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not token owner or approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    // Make roles viewable
    function getAdminRole() external pure returns (bytes32) { return ADMIN_ROLE; }
    function getArtistRole() external pure returns (bytes32) { return ARTIST_ROLE; }
}
```

---

**Explanation of Advanced Concepts & Creativity:**

1.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` is standard but crucial for defining who can perform sensitive actions like setting fees (`ADMIN_ROLE`) or minting art (`ARTIST_ROLE`), moving beyond simple `onlyOwner`.
2.  **Multi-Party Programmable Royalties:** Instead of a single fixed percentage to one address, the `setArtRoyalties` function allows the *owner* (which could change after sales) to define *multiple* recipients (e.g., original artist, a collaborator, a charity) and their respective shares (in basis points, summing up to 100%). The `_distributeRoyalties` function handles splitting the proceeds on sale.
3.  **Internal Fractionalization:** This is a custom implementation, not relying on wrapping in an ERC-1155.
    *   The original ERC-721 is held by the contract.
    *   Ownership is tracked internally using `_fractionBalances`.
    *   There's a defined `fractionalizeArt` period during which fractions can be bought at a fixed price.
    *   `transferFraction` allows trading these internal fractions *within* the contract.
    *   `reconstructArt` provides a unique mechanism: if someone accumulates *all* fractions, they can burn them to retrieve the original ERC-721 token from the contract. This differs from ERC-1155 pooling where you often need to buy back from a pool or marketplace.
    *   `collectFractionSaleProceeds` allows the original owner to claim the Ether from the initial fraction sale.
4.  **Basic On-Chain Governance:** The `submitProposal`, `voteOnProposal`, and `executeProposal` functions form a simple DAO-like structure. While very basic (1 address 1 vote, simple majority, ADMIN_ROLE proposal submission), it demonstrates how governance could be implemented on-chain to allow the community (or a defined set of users) to influence contract parameters (like the `galleryFeeBps`) by voting on `callData` targeting the contract itself or another governed contract.
5.  **Dynamic Art Metadata Concept:** The `isDynamic` flag and `triggerDynamicMetadataUpdate` function, coupled with `totalValueTraded`, provide an on-chain state change that *could* be used by off-chain services (like IPFS gateways or metadata APIs) to serve different metadata based on how much the art has been traded or its accumulated value. The contract itself stores `currentDynamicURI` and updates the ERC721 `tokenURI` based on this (in the example, a simplified URI change). This moves beyond static JPEGs to art that evolves with its history.
6.  **Detailed State Tracking:** Mappings and structs store a richer set of data per token than a standard ERC721 (artist, dynamic status, trading value, royalty info, fractionalization state).
7.  **20+ Functions:** The contract provides the required number of functions covering the different modules, including internal helpers and view functions.

This contract provides a foundation for a more complex and interactive decentralized art platform, incorporating concepts that enable new forms of ownership, creator incentives, and community involvement. Remember that deploying such a contract would require thorough auditing and careful consideration of gas costs and potential attack vectors, especially around Ether transfers and complex state transitions.