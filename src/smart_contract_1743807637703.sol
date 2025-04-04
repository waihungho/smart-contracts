```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Gemini AI (Example - not for production)
 * @dev This contract implements a decentralized NFT marketplace with dynamic NFT capabilities,
 *      advanced listing options, governance features, and more. It aims to showcase creative and
 *      trendy functionalities beyond basic marketplace contracts, without duplicating common open-source patterns.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Management:**
 *   1. `registerNFTCollection(address _nftContract, string memory _collectionName)`: Allows the marketplace owner to register supported NFT collections.
 *   2. `isSupportedNFTCollection(address _nftContract)`: Checks if an NFT collection is registered and supported by the marketplace.
 *   3. `setDynamicMetadataFunction(address _nftContract, bytes4 _functionSignature)`:  Sets the function signature on the NFT contract to fetch dynamic metadata.
 *   4. `getDynamicNFTMetadata(address _nftContract, uint256 _tokenId)`: Fetches and returns dynamic metadata for a specific NFT from a registered collection.
 *
 * **Advanced Listing and Marketplace Features:**
 *   5. `listNFTForSale(address _nftContract, uint256 _tokenId, uint256 _price, ListingType _listingType, uint256 _duration)`: Lists an NFT for sale in the marketplace with various listing types and durations.
 *   6. `buyNFT(uint256 _listingId)`: Allows users to purchase an NFT listed in the marketplace.
 *   7. `cancelListing(uint256 _listingId)`: Allows the seller to cancel an active NFT listing.
 *   8. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows the seller to update the price of an active NFT listing.
 *   9. `offerBidOnNFT(uint256 _listingId, uint256 _bidAmount)`: Allows users to place bids on NFTs listed as auctions.
 *  10. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows the seller to accept a bid on an auctioned NFT.
 *  11. `rentNFT(uint256 _listingId, uint256 _rentDuration)`: Allows users to rent NFTs for a specified duration.
 *  12. `returnRentedNFT(uint256 _listingId)`: Allows the renter to return a rented NFT before the rental period ends.
 *
 * **Governance and Community Features:**
 *  13. `proposeNewFeature(string memory _proposalDescription)`: Allows users to propose new features for the marketplace via governance.
 *  14. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on active governance proposals.
 *  15. `executeProposal(uint256 _proposalId)`: Allows the marketplace owner to execute a passed governance proposal.
 *
 * **Reputation and Trust System:**
 *  16. `rateUser(address _userAddress, uint8 _rating, string memory _feedback)`: Allows users to rate other users based on marketplace interactions.
 *  17. `getUserRating(address _userAddress)`: Retrieves the average rating of a user.
 *  18. `reportListing(uint256 _listingId, string memory _reportReason)`: Allows users to report listings for inappropriate content or policy violations.
 *
 * **Utility and Admin Functions:**
 *  19. `setMarketplaceFee(uint256 _newFeePercentage)`: Allows the marketplace owner to set the marketplace fee percentage.
 *  20. `withdrawMarketplaceFees()`: Allows the marketplace owner to withdraw accumulated marketplace fees.
 *  21. `pauseMarketplace()`: Allows the marketplace owner to pause all marketplace functionalities for maintenance.
 *  22. `unpauseMarketplace()`: Allows the marketplace owner to unpause the marketplace.
 */

contract DynamicNFTMarketplace {
    // ---------- State Variables ----------

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public paused = false;

    struct NFTCollection {
        string collectionName;
        bytes4 dynamicMetadataFunctionSig; // Function signature to fetch dynamic metadata from NFT contract
        bool isRegistered;
    }
    mapping(address => NFTCollection) public registeredNFTCollections;
    address[] public supportedNFTContracts;

    enum ListingType { FIXED_PRICE, AUCTION, RENTAL }

    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        ListingType listingType;
        uint256 listingTime;
        uint256 duration; // For auctions/rentals
        bool isActive;
        address renter; // For rentals
        uint256 rentEndTime; // For rentals
        Bid[] bids; // For auctions
    }
    mapping(uint256 => Listing) public listings;
    uint256 public nextListingId = 1;

    struct Bid {
        address bidder;
        uint256 bidAmount;
        uint256 bidTime;
    }

    struct Proposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isActive;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => bidder => voted

    struct UserRating {
        uint256 totalRating;
        uint256 ratingCount;
    }
    mapping(address => UserRating) public userRatings;

    struct Report {
        uint256 reportId;
        uint256 listingId;
        address reporter;
        string reason;
        uint256 reportTime;
        bool resolved;
    }
    mapping(uint256 => Report) public reports;
    uint256 public nextReportId = 1;


    // ---------- Events ----------
    event NFTCollectionRegistered(address nftContract, string collectionName);
    event DynamicMetadataFunctionSet(address nftContract, bytes4 functionSignature);
    event NFTListed(uint256 listingId, address nftContract, uint256 tokenId, address seller, uint256 price, ListingType listingType);
    event NFTBought(uint256 listingId, address buyer);
    event ListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event BidPlaced(uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 listingId, uint256 bidId, address winner);
    event NFTRented(uint256 listingId, address renter, uint256 rentDuration);
    event NFTReturned(uint256 listingId, address renter);
    event NewFeatureProposed(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event UserRated(address userAddress, address rater, uint8 rating, string feedback);
    event ListingReported(uint256 reportId, uint256 listingId, address reporter, string reason);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplaceFeesWithdrawn(address owner, uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();


    // ---------- Modifiers ----------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Invalid listing ID.");
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier validNFTCollection(address _nftContract) {
        require(registeredNFTCollections[_nftContract].isRegistered, "NFT Collection not registered.");
        _;
    }

    modifier isNFTOwner(address _nftContract, uint256 _tokenId) {
        // Assuming standard ERC721 interface for ownerOf function
        address ownerOfNFT = IERC721(_nftContract).ownerOf(_tokenId);
        require(ownerOfNFT == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier isApprovedOrOwner(address _nftContract, uint256 _tokenId) {
        // Assuming standard ERC721 interface for getApproved and isApprovedForAll
        address ownerOfNFT = IERC721(_nftContract).ownerOf(_tokenId);
        address approvedAddress = IERC721(_nftContract).getApproved(_tokenId);
        bool isApprovedForAll = IERC721(_nftContract).isApprovedForAll(ownerOfNFT, msg.sender);

        require(ownerOfNFT == msg.sender || approvedAddress == msg.sender || isApprovedForAll, "Not approved or owner of NFT.");
        _;
    }


    // ---------- Constructor ----------
    constructor() {
        owner = msg.sender;
    }

    // ---------- Core NFT Management Functions ----------

    /// @dev Registers a new NFT collection to be supported by the marketplace.
    /// @param _nftContract Address of the NFT contract.
    /// @param _collectionName Name of the NFT collection.
    function registerNFTCollection(address _nftContract, string memory _collectionName) external onlyOwner {
        require(!registeredNFTCollections[_nftContract].isRegistered, "NFT Collection already registered.");
        registeredNFTCollections[_nftContract] = NFTCollection({
            collectionName: _collectionName,
            dynamicMetadataFunctionSig: 0, // Initially no dynamic metadata function
            isRegistered: true
        });
        supportedNFTContracts.push(_nftContract);
        emit NFTCollectionRegistered(_nftContract, _collectionName);
    }

    /// @dev Checks if an NFT collection is registered and supported by the marketplace.
    /// @param _nftContract Address of the NFT contract.
    /// @return True if the collection is supported, false otherwise.
    function isSupportedNFTCollection(address _nftContract) external view returns (bool) {
        return registeredNFTCollections[_nftContract].isRegistered;
    }

    /// @dev Sets the function signature on the NFT contract to fetch dynamic metadata.
    /// @param _nftContract Address of the NFT contract.
    /// @param _functionSignature Function signature (e.g., keccak256("getNFTMetadata(uint256)")) of the dynamic metadata function in the NFT contract.
    function setDynamicMetadataFunction(address _nftContract, bytes4 _functionSignature) external onlyOwner validNFTCollection(_nftContract) {
        registeredNFTCollections[_nftContract].dynamicMetadataFunctionSig = _functionSignature;
        emit DynamicMetadataFunctionSet(_nftContract, _functionSignature);
    }

    /// @dev Fetches and returns dynamic metadata for a specific NFT from a registered collection.
    /// @param _nftContract Address of the NFT contract.
    /// @param _tokenId Token ID of the NFT.
    /// @return Dynamic metadata (bytes) fetched from the NFT contract.
    function getDynamicNFTMetadata(address _nftContract, uint256 _tokenId) external view validNFTCollection(_nftContract) returns (bytes memory) {
        bytes4 functionSig = registeredNFTCollections[_nftContract].dynamicMetadataFunctionSig;
        require(functionSig != bytes4(0), "Dynamic metadata function not set for this collection.");

        // Low-level call to the NFT contract to fetch dynamic metadata
        (bool success, bytes memory data) = _nftContract.staticcall(abi.encodeWithSelector(functionSig, _tokenId));
        require(success, "Failed to fetch dynamic metadata from NFT contract.");
        return data;
    }


    // ---------- Advanced Listing and Marketplace Functions ----------

    /// @dev Lists an NFT for sale in the marketplace.
    /// @param _nftContract Address of the NFT contract.
    /// @param _tokenId Token ID of the NFT.
    /// @param _price Price of the NFT (in wei).
    /// @param _listingType Type of listing (FIXED_PRICE, AUCTION, RENTAL).
    /// @param _duration Duration for auction or rental (in seconds). Set to 0 for fixed price.
    function listNFTForSale(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        ListingType _listingType,
        uint256 _duration
    ) external whenNotPaused validNFTCollection(_nftContract) isNFTOwner(_nftContract, _tokenId) isApprovedOrOwner(_nftContract, _tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(_listingType != ListingType.RENTAL || _duration > 0, "Rental duration must be set for rental listings.");
        require(_listingType != ListingType.AUCTION || _duration > 0, "Auction duration must be set for auction listings.");

        // Transfer NFT ownership to the marketplace contract temporarily for secure trading.
        // Assuming standard ERC721 safeTransferFrom function
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingType: _listingType,
            listingTime: block.timestamp,
            duration: _duration,
            isActive: true,
            renter: address(0),
            rentEndTime: 0,
            bids: new Bid[](0)
        });

        emit NFTListed(nextListingId, _nftContract, _tokenId, msg.sender, _price, _listingType);
        nextListingId++;
    }

    /// @dev Allows users to purchase an NFT listed in the marketplace.
    /// @param _listingId ID of the listing to buy.
    function buyNFT(uint256 _listingId) external payable whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.listingType == ListingType.FIXED_PRICE, "Listing is not a fixed price listing.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;

        listing.isActive = false;

        // Transfer NFT to buyer
        IERC721(listing.nftContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        // Pay seller and marketplace fee
        payable(listing.seller).transfer(sellerPayout);
        payable(owner).transfer(marketplaceFee);

        emit NFTBought(_listingId, msg.sender);
    }

    /// @dev Allows the seller to cancel an active NFT listing.
    /// @param _listingId ID of the listing to cancel.
    function cancelListing(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing.");

        listing.isActive = false;

        // Return NFT to seller
        IERC721(listing.nftContract).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit ListingCancelled(_listingId);
    }

    /// @dev Allows the seller to update the price of an active fixed price NFT listing.
    /// @param _listingId ID of the listing to update.
    /// @param _newPrice New price for the NFT.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can update the listing price.");
        require(listing.listingType == ListingType.FIXED_PRICE, "Price can only be updated for fixed price listings.");
        require(_newPrice > 0, "New price must be greater than zero.");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    /// @dev Allows users to place bids on NFTs listed as auctions.
    /// @param _listingId ID of the auction listing.
    /// @param _bidAmount Amount to bid (in wei).
    function offerBidOnNFT(uint256 _listingId, uint256 _bidAmount) external payable whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.listingType == ListingType.AUCTION, "Listing is not an auction.");
        require(block.timestamp < listing.listingTime + listing.duration, "Auction has ended.");
        require(msg.value >= _bidAmount, "Insufficient funds sent.");

        uint256 currentHighestBid = 0;
        if (listing.bids.length > 0) {
            currentHighestBid = listing.bids[listing.bids.length - 1].bidAmount; // Assuming bids are sorted by amount
        }
        require(_bidAmount > currentHighestBid, "Bid must be higher than the current highest bid.");

        // Refund previous highest bidder (if any)
        if (listing.bids.length > 0) {
            payable(listing.bids[listing.bids.length - 1].bidder).transfer(listing.bids[listing.bids.length - 1].bidAmount);
        }

        Bid memory newBid = Bid({
            bidder: msg.sender,
            bidAmount: _bidAmount,
            bidTime: block.timestamp
        });
        listing.bids.push(newBid);

        emit BidPlaced(_listingId, msg.sender, _bidAmount);
    }

    /// @dev Allows the seller to accept a bid on an auctioned NFT and conclude the auction.
    /// @param _listingId ID of the auction listing.
    /// @param _bidId Index of the bid in the `bids` array to accept.
    function acceptBid(uint256 _listingId, uint256 _bidId) external whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can accept bids.");
        require(listing.listingType == ListingType.AUCTION, "Listing is not an auction.");
        require(block.timestamp >= listing.listingTime + listing.duration, "Auction has not ended yet."); // Seller can only accept after auction ends
        require(_bidId < listing.bids.length, "Invalid bid ID.");
        require(listing.bids.length > 0, "No bids placed on this auction.");

        Bid memory acceptedBid = listing.bids[_bidId];
        uint256 marketplaceFee = (acceptedBid.bidAmount * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = acceptedBid.bidAmount - marketplaceFee;

        listing.isActive = false;

        // Transfer NFT to the winning bidder
        IERC721(listing.nftContract).safeTransferFrom(address(this), acceptedBid.bidder, listing.tokenId);

        // Pay seller and marketplace fee
        payable(listing.seller).transfer(sellerPayout);
        payable(owner).transfer(marketplaceFee);

        // Refund losing bidders
        for (uint256 i = 0; i < listing.bids.length; i++) {
            if (i != _bidId) {
                payable(listing.bids[i].bidder).transfer(listing.bids[i].bidAmount);
            }
        }

        emit BidAccepted(_listingId, _bidId, acceptedBid.bidder);
    }

    /// @dev Allows users to rent NFTs for a specified duration.
    /// @param _listingId ID of the rental listing.
    /// @param _rentDuration Duration of the rental in seconds.
    function rentNFT(uint256 _listingId, uint256 _rentDuration) external payable whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.listingType == ListingType.RENTAL, "Listing is not a rental listing.");
        require(msg.value >= listing.price, "Insufficient funds sent for rental."); // Price is the rent price here

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;
        uint256 rentEndTime = block.timestamp + _rentDuration;

        listing.isActive = false; // Mark listing as inactive during rental
        listing.renter = msg.sender;
        listing.rentEndTime = rentEndTime;

        // Transfer NFT to renter (temporarily - logic needs to be handled in NFT contract if needed for temporary access)
        IERC721(listing.nftContract).safeTransferFrom(address(this), msg.sender, listing.tokenId); // Consider if transfer is needed for rental, might just track ownership in NFT contract.

        // Pay seller and marketplace fee
        payable(listing.seller).transfer(sellerPayout);
        payable(owner).transfer(marketplaceFee);

        emit NFTRented(_listingId, msg.sender, _rentDuration);
    }

    /// @dev Allows the renter to return a rented NFT before the rental period ends.
    /// @param _listingId ID of the rental listing.
    function returnRentedNFT(uint256 _listingId) external whenNotPaused validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.listingType == ListingType.RENTAL, "Listing is not a rental listing.");
        require(listing.renter == msg.sender, "Only the renter can return the NFT.");
        require(listing.renter != address(0), "NFT is not currently rented.");

        listing.isActive = true; // Reactivate listing for potential future rentals/sales
        listing.renter = address(0);
        listing.rentEndTime = 0;

        // Return NFT to marketplace (or seller - decide rental logic)
        IERC721(listing.nftContract).safeTransferFrom(msg.sender, address(this), listing.tokenId); // Return to marketplace, seller can relist.

        emit NFTReturned(_listingId, msg.sender);
    }


    // ---------- Governance and Community Functions ----------

    /// @dev Allows users to propose new features for the marketplace via governance.
    /// @param _proposalDescription Description of the new feature proposal.
    function proposeNewFeature(string memory _proposalDescription) external whenNotPaused {
        proposals[nextProposalId] = Proposal({
            proposalId: nextProposalId,
            description: _proposalDescription,
            proposer: msg.sender,
            voteCount: 0,
            againstVoteCount: 0,
            isActive: true,
            passed: false
        });
        emit NewFeatureProposed(nextProposalId, _proposalDescription, msg.sender);
        nextProposalId++;
    }

    /// @dev Allows users to vote on active governance proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active.");
        require(!hasVoted[_proposalId][msg.sender], "You have already voted on this proposal.");

        if (_vote) {
            proposals[_proposalId].voteCount++;
        } else {
            proposals[_proposalId].againstVoteCount++;
        }
        hasVoted[_proposalId][msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Allows the marketplace owner to execute a passed governance proposal.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active.");
        require(!proposals[_proposalId].passed, "Proposal already executed.");
        require(proposals[_proposalId].voteCount > proposals[_proposalId].againstVoteCount, "Proposal not passed.");

        proposals[_proposalId].isActive = false;
        proposals[_proposalId].passed = true;

        // TODO: Implement actual execution logic based on proposal description.
        // This is where you would add code to modify contract behavior based on the governance outcome.
        // Example: if proposal was to change marketplace fee, update `marketplaceFeePercentage` here.
        // For security, complex changes might require a separate upgrade mechanism or modular contract design.

        emit ProposalExecuted(_proposalId);
    }


    // ---------- Reputation and Trust System Functions ----------

    /// @dev Allows users to rate other users based on marketplace interactions.
    /// @param _userAddress Address of the user to rate.
    /// @param _rating Rating given (1-5 scale, for example).
    /// @param _feedback Optional feedback string.
    function rateUser(address _userAddress, uint8 _rating, string memory _feedback) external whenNotPaused {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example 1-5 scale
        require(_userAddress != msg.sender, "Cannot rate yourself.");

        UserRating storage ratingData = userRatings[_userAddress];
        ratingData.totalRating += _rating;
        ratingData.ratingCount++;

        emit UserRated(_userAddress, msg.sender, _rating, _feedback);
    }

    /// @dev Retrieves the average rating of a user.
    /// @param _userAddress Address of the user to get the rating for.
    /// @return Average rating of the user (or 0 if no ratings yet).
    function getUserRating(address _userAddress) external view returns (uint256) {
        UserRating storage ratingData = userRatings[_userAddress];
        if (ratingData.ratingCount == 0) {
            return 0;
        }
        return ratingData.totalRating / ratingData.ratingCount;
    }

    /// @dev Allows users to report listings for inappropriate content or policy violations.
    /// @param _listingId ID of the listing to report.
    /// @param _reportReason Reason for reporting the listing.
    function reportListing(uint256 _listingId, string memory _reportReason) external whenNotPaused validListing(_listingId) {
        reports[nextReportId] = Report({
            reportId: nextReportId,
            listingId: _listingId,
            reporter: msg.sender,
            reason: _reportReason,
            reportTime: block.timestamp,
            resolved: false
        });
        emit ListingReported(nextReportId, _listingId, msg.sender, _reportReason);
        nextReportId++;
        // TODO: Implement admin panel or function to review and resolve reports.
    }


    // ---------- Utility and Admin Functions ----------

    /// @dev Sets the marketplace fee percentage.
    /// @param _newFeePercentage New fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeUpdated(_newFeePercentage);
    }

    /// @dev Allows the marketplace owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit MarketplaceFeesWithdrawn(owner, balance);
    }

    /// @dev Pauses all marketplace functionalities.
    function pauseMarketplace() external onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    /// @dev Unpauses the marketplace functionalities.
    function unpauseMarketplace() external onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // ---------- Fallback and Receive Functions ----------
    receive() external payable {} // To receive ETH for marketplace fees and bids
    fallback() external {}
}

// ---------- Interface for ERC721 (Minimal Required Functions) ----------
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
```