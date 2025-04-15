```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace focusing on dynamic NFTs with evolving properties and advanced trading mechanisms.
 *
 * **Outline and Function Summary:**
 *
 * **1. Dynamic NFT Management:**
 *    - `createDynamicNFT(string _name, string _description, string _baseMetadataURI)`: Mints a new Dynamic NFT with initial metadata and creator.
 *    - `updateNFTMetadata(uint256 _tokenId, string _newMetadataURI)`: Allows the NFT creator to update the metadata URI of their NFT.
 *    - `addDynamicProperty(uint256 _tokenId, string _propertyName, string _initialValue)`: Adds a new dynamic property to an NFT, modifiable later through voting or creator action.
 *    - `getDynamicPropertyValue(uint256 _tokenId, string _propertyName)`: Retrieves the current value of a dynamic property for an NFT.
 *    - `proposePropertyUpdate(uint256 _tokenId, string _propertyName, string _newValue, uint256 _votingDuration)`: Allows anyone to propose an update to a dynamic property, initiating a voting period.
 *    - `voteOnPropertyUpdate(uint256 _proposalId, bool _vote)`: Allows users holding the NFT to vote on a proposed property update.
 *    - `executePropertyUpdate(uint256 _proposalId)`: Executes a property update if the voting threshold is met, updating the dynamic property value.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a property update proposal (status, votes, etc.).
 *
 * **2. Marketplace Core Functions:**
 *    - `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists a Dynamic NFT for sale at a fixed price.
 *    - `buyNFT(uint256 _listingId)`: Allows anyone to buy a listed NFT, transferring ownership and funds.
 *    - `cancelListing(uint256 _listingId)`: Allows the seller to cancel an NFT listing.
 *    - `makeOffer(uint256 _tokenId, uint256 _offerPrice)`: Allows users to make an offer on an NFT that is not currently listed or to make a lower offer on a listed NFT.
 *    - `acceptOffer(uint256 _offerId)`: Allows the NFT owner to accept a specific offer, executing the sale.
 *    - `rejectOffer(uint256 _offerId)`: Allows the NFT owner to reject an offer.
 *    - `createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration)`: Starts an auction for a Dynamic NFT with a starting price and duration.
 *    - `bidOnAuction(uint256 _auctionId, uint256 _bidPrice)`: Allows users to bid on an active auction.
 *    - `endAuction(uint256 _auctionId)`: Ends an active auction after the duration, transferring the NFT to the highest bidder.
 *
 * **3. Advanced Marketplace Features:**
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set a marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *    - `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Allows the contract owner to set a default royalty percentage for all NFTs.
 *    - `setCustomRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Allows the NFT creator to set a custom royalty percentage for their specific NFT, overriding the default.
 *    - `withdrawCreatorRoyalty(uint256 _tokenId)`: Allows the NFT creator to withdraw accumulated royalties earned from secondary sales of their NFT.
 *    - `reportNFT(uint256 _tokenId, string _reason)`: Allows users to report an NFT for inappropriate content or policy violations.
 *    - `resolveReport(uint256 _reportId, bool _isResolved)`: Allows the contract owner to resolve a reported NFT, potentially taking actions like delisting (implementation detail - not in this basic version).
 *    - `pauseMarketplace(bool _pause)`: Allows the contract owner to pause/unpause all marketplace trading activities in case of emergency or maintenance.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _auctionIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _reportIdCounter;

    string public baseMetadataURI;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    uint256 public defaultRoyaltyPercentage = 5; // Default 5% royalty
    bool public isMarketplacePaused = false;

    struct DynamicNFT {
        address creator;
        string metadataURI;
        mapping(string => string) dynamicProperties;
    }

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Offer {
        uint256 tokenId;
        uint256 offerPrice;
        address bidder;
        bool isActive;
    }

    struct Auction {
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
    }

    struct PropertyUpdateProposal {
        uint256 tokenId;
        string propertyName;
        string newValue;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool isExecuted;
    }

    struct NFTReport {
        uint256 tokenId;
        string reason;
        address reporter;
        bool isResolved;
    }

    mapping(uint256 => DynamicNFT) public dynamicNFTs;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => PropertyUpdateProposal) public propertyUpdateProposals;
    mapping(uint256 => NFTReport) public nftReports;
    mapping(uint256 => uint256) public customRoyalties; // tokenId => royaltyPercentage
    mapping(uint256 => uint256) public creatorRoyaltiesBalance; // tokenId => balance

    event NFTCreated(uint256 tokenId, address creator, string name);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event DynamicPropertyAdded(uint256 tokenId, string propertyName, string initialValue);
    event DynamicPropertyUpdated(uint256 tokenId, string propertyName, string newValue);
    event PropertyUpdateProposed(uint256 proposalId, uint256 tokenId, string propertyName, string newValue, uint256 votingDuration);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event PropertyUpdateExecuted(uint256 proposalId, uint256 tokenId, string propertyName, string newValue);

    event NFTListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event OfferMade(uint256 offerId, uint256 tokenId, uint256 offerPrice, address bidder);
    event OfferAccepted(uint256 offerId, uint256 tokenId, uint256 price, address seller, address buyer);
    event OfferRejected(uint256 offerId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingPrice, uint256 endTime, address seller);
    event BidPlaced(uint256 auctionId, uint256 tokenId, uint256 bidPrice, address bidder);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);

    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address owner);
    event RoyaltyPercentageSet(uint256 royaltyPercentage);
    event CustomRoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event CreatorRoyaltyWithdrawn(uint256 tokenId, uint256 amount, address creator);
    event NFTReported(uint256 reportId, uint256 tokenId, address reporter, string reason);
    event ReportResolved(uint256 reportId, uint256 tokenId, bool isResolved);
    event MarketplacePaused(bool paused);

    constructor(string memory _name, string memory _symbol, string memory _baseMetadataURI) ERC721(_name, _symbol) {
        baseMetadataURI = _baseMetadataURI;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner or approved");
        _;
    }

    modifier onlyMarketplaceActive() {
        require(!isMarketplacePaused, "Marketplace is currently paused");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier validOffer(uint256 _offerId) {
        require(offers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active");
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended");
        _;
    }

    modifier auctionEnded(uint256 _auctionId) {
        require(!auctions[_auctionId].isActive, "Auction is still active");
        require(block.timestamp >= auctions[_auctionId].endTime, "Auction end time not reached");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(propertyUpdateProposals[_proposalId].isActive, "Proposal is not active");
        require(!propertyUpdateProposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp < propertyUpdateProposals[_proposalId].votingEndTime, "Voting period ended");
        _;
    }

    modifier proposalVotingEnded(uint256 _proposalId) {
        require(propertyUpdateProposals[_proposalId].isActive, "Proposal is not active");
        require(!propertyUpdateProposals[_proposalId].isExecuted, "Proposal already executed");
        require(block.timestamp >= propertyUpdateProposals[_proposalId].votingEndTime, "Voting period not ended");
        _;
    }

    // ------------------------ Dynamic NFT Management ------------------------

    function createDynamicNFT(string memory _name, string memory _description, string memory _baseMetadataURI) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_msgSender(), tokenId);

        string memory metadataURI = string(abi.encodePacked(_baseMetadataURI, "/", tokenId.toString(), ".json"));

        dynamicNFTs[tokenId] = DynamicNFT({
            creator: _msgSender(),
            metadataURI: metadataURI,
            dynamicProperties: mapping(string => string)() // Initialize empty dynamic properties mapping
        });

        _setTokenURI(tokenId, metadataURI); // Set initial metadata URI

        emit NFTCreated(tokenId, _msgSender(), _name);
        return tokenId;
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].metadataURI = _newMetadataURI;
        _setTokenURI(_tokenId, _newMetadataURI);
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    function addDynamicProperty(uint256 _tokenId, string memory _propertyName, string memory _initialValue) public onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].dynamicProperties[_propertyName] = _initialValue;
        emit DynamicPropertyAdded(_tokenId, _propertyName, _initialValue);
    }

    function getDynamicPropertyValue(uint256 _tokenId, string memory _propertyName) public view returns (string memory) {
        return dynamicNFTs[_tokenId].dynamicProperties[_propertyName];
    }

    function proposePropertyUpdate(uint256 _tokenId, string memory _propertyName, string memory _newValue, uint256 _votingDuration) public onlyNFTOwner(_tokenId) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        propertyUpdateProposals[proposalId] = PropertyUpdateProposal({
            tokenId: _tokenId,
            propertyName: _propertyName,
            newValue: _newValue,
            votingEndTime: block.timestamp + _votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            isExecuted: false
        });

        emit PropertyUpdateProposed(proposalId, _tokenId, _propertyName, _newValue, _votingDuration);
    }

    function voteOnPropertyUpdate(uint256 _proposalId, bool _vote) public validProposal(_proposalId) onlyNFTOwner(propertyUpdateProposals[_proposalId].tokenId) {
        PropertyUpdateProposal storage proposal = propertyUpdateProposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    function executePropertyUpdate(uint256 _proposalId) public proposalVotingEnded(_proposalId) {
        PropertyUpdateProposal storage proposal = propertyUpdateProposals[_proposalId];
        uint256 totalVoters = balanceOf(proposal.tokenId); // Simple voting: NFT holders are voters
        require(totalVoters > 0, "No voters for this NFT"); // Prevent division by zero
        uint256 requiredVotes = (totalVoters * 50) / 100; // 50% majority needed (can be adjusted)
        require(proposal.yesVotes > requiredVotes, "Voting threshold not met");

        dynamicNFTs[proposal.tokenId].dynamicProperties[proposal.propertyName] = proposal.newValue;
        proposal.isActive = false;
        proposal.isExecuted = true;

        emit PropertyUpdateExecuted(_proposalId, proposal.tokenId, proposal.propertyName, proposal.newValue);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (PropertyUpdateProposal memory) {
        return propertyUpdateProposals[_proposalId];
    }

    // ------------------------ Marketplace Core Functions ------------------------

    function listItemForSale(uint256 _tokenId, uint256 _price) public onlyMarketplaceActive onlyNFTOwner(_tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");
        require(listings[_tokenId].isActive == false, "NFT already listed");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: _msgSender(),
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to handle transfer
        emit NFTListed(listingId, _tokenId, _price, _msgSender());
    }

    function buyNFT(uint256 _listingId) public payable onlyMarketplaceActive validListing(_listingId) nonReentrant {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 creatorRoyalty = (listing.price * getRoyaltyPercentage(listing.tokenId)) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee - creatorRoyalty;

        // Transfer NFT to buyer
        _transfer(listing.seller, _msgSender(), listing.tokenId);

        // Transfer funds
        payable(listing.seller).transfer(sellerPayout);
        payable(owner()).transfer(marketplaceFee); // Marketplace fee to owner

        // Royalty to creator (if applicable)
        if (creatorRoyalty > 0) {
            creatorRoyaltiesBalance[listing.tokenId] += creatorRoyalty;
        }

        listing.isActive = false; // Deactivate listing

        emit NFTBought(_listingId, listing.tokenId, _msgSender(), listing.price);
    }

    function cancelListing(uint256 _listingId) public onlyMarketplaceActive validListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == _msgSender(), "Only seller can cancel listing");

        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listing.tokenId);
    }

    function makeOffer(uint256 _tokenId, uint256 _offerPrice) public payable onlyMarketplaceActive nonReentrant {
        require(msg.value >= _offerPrice, "Insufficient funds sent for offer");
        require(_offerPrice > 0, "Offer price must be greater than zero");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        offers[offerId] = Offer({
            tokenId: _tokenId,
            offerPrice: _offerPrice,
            bidder: _msgSender(),
            isActive: true
        });

        emit OfferMade(offerId, _tokenId, _offerPrice, _msgSender());
    }

    function acceptOffer(uint256 _offerId) public onlyMarketplaceActive validOffer(_offerId) nonReentrant {
        Offer storage offer = offers[_offerId];
        uint256 tokenId = offer.tokenId;
        require(ownerOf(tokenId) == _msgSender(), "You are not the owner of this NFT");

        uint256 offerPrice = offer.offerPrice;
        uint256 marketplaceFee = (offerPrice * marketplaceFeePercentage) / 100;
        uint256 creatorRoyalty = (offerPrice * getRoyaltyPercentage(tokenId)) / 100;
        uint256 sellerPayout = offerPrice - marketplaceFee - creatorRoyalty;

        // Transfer NFT to bidder
        _transfer(_msgSender(), offer.bidder, tokenId);

        // Transfer funds
        payable(_msgSender()).transfer(sellerPayout);
        payable(owner()).transfer(marketplaceFee); // Marketplace fee to owner

        // Royalty to creator (if applicable)
        if (creatorRoyalty > 0) {
            creatorRoyaltiesBalance[tokenId] += creatorRoyalty;
        }

        offer.isActive = false; // Deactivate offer

        emit OfferAccepted(_offerId, tokenId, offerPrice, _msgSender(), offer.bidder);
    }

    function rejectOffer(uint256 _offerId) public onlyMarketplaceActive validOffer(_offerId) {
        Offer storage offer = offers[_offerId];
        require(ownerOf(offer.tokenId) == _msgSender(), "Only NFT owner can reject offer");

        offers[_offerId].isActive = false;
        emit OfferRejected(_offerId, offer.tokenId);
    }

    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public onlyMarketplaceActive onlyNFTOwner(_tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_startingPrice > 0, "Starting price must be greater than zero");
        require(_duration > 0, "Auction duration must be greater than zero");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            endTime: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: 0,
            seller: _msgSender(),
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve marketplace to handle transfer
        emit AuctionCreated(auctionId, _tokenId, _startingPrice, block.timestamp + _duration, _msgSender());
    }

    function bidOnAuction(uint256 _auctionId, uint256 _bidPrice) public payable onlyMarketplaceActive validAuction(_auctionId) nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(msg.value >= _bidPrice, "Insufficient bid amount");
        require(_bidPrice > auction.highestBid, "Bid must be higher than current highest bid");

        // Return previous highest bid to previous bidder (if any)
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = _bidPrice;
        emit BidPlaced(_auctionId, auction.tokenId, _bidPrice, _msgSender());
    }

    function endAuction(uint256 _auctionId) public onlyMarketplaceActive auctionEnded(_auctionId) nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.isActive, "Auction not active");
        require(auction.seller == _msgSender() || _msgSender() == owner(), "Only seller or owner can end auction after time"); // Allow owner to end in case of issues

        auction.isActive = false; // Deactivate auction
        uint256 finalPrice = auction.highestBid;
        address winner = auction.highestBidder;

        if (winner != address(0)) {
            uint256 marketplaceFee = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 creatorRoyalty = (finalPrice * getRoyaltyPercentage(auction.tokenId)) / 100;
            uint256 sellerPayout = finalPrice - marketplaceFee - creatorRoyalty;

            // Transfer NFT to winner
            _transfer(auction.seller, winner, auction.tokenId);

            // Transfer funds
            payable(auction.seller).transfer(sellerPayout);
            payable(owner()).transfer(marketplaceFee); // Marketplace fee to owner

            // Royalty to creator (if applicable)
            if (creatorRoyalty > 0) {
                creatorRoyaltiesBalance[auction.tokenId] += creatorRoyalty;
            }

            emit AuctionEnded(_auctionId, auction.tokenId, winner, finalPrice);
        } else {
            // No bids, return NFT to seller
            _transfer(address(this), auction.seller, auction.tokenId); // Transfer back from marketplace contract
            emit AuctionEnded(_auctionId, auction.tokenId, address(0), 0); // Indicate no winner
        }
    }


    // ------------------------ Advanced Marketplace Features ------------------------

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, owner());
    }

    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        defaultRoyaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_royaltyPercentage);
    }

    function setCustomRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) public onlyNFTOwner(_tokenId) {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        customRoyalties[_tokenId] = _royaltyPercentage;
        emit CustomRoyaltySet(_tokenId, _royaltyPercentage);
    }

    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint256) {
        if (customRoyalties[_tokenId] > 0) {
            return customRoyalties[_tokenId];
        }
        return defaultRoyaltyPercentage;
    }

    function withdrawCreatorRoyalty(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        require(dynamicNFTs[_tokenId].creator == _msgSender(), "Only creator can withdraw royalty");
        uint256 royaltyBalance = creatorRoyaltiesBalance[_tokenId];
        require(royaltyBalance > 0, "No royalty balance to withdraw");

        creatorRoyaltiesBalance[_tokenId] = 0; // Reset balance before transfer to prevent reentrancy issues
        payable(_msgSender()).transfer(royaltyBalance);
        emit CreatorRoyaltyWithdrawn(_tokenId, royaltyBalance, _msgSender());
    }

    function reportNFT(uint256 _tokenId, string memory _reason) public onlyMarketplaceActive {
        _reportIdCounter.increment();
        uint256 reportId = _reportIdCounter.current();

        nftReports[reportId] = NFTReport({
            tokenId: _tokenId,
            reason: _reason,
            reporter: _msgSender(),
            isResolved: false
        });
        emit NFTReported(reportId, _tokenId, _msgSender(), _reason);
    }

    function resolveReport(uint256 _reportId, bool _isResolved) public onlyOwner {
        require(!nftReports[_reportId].isResolved, "Report already resolved");
        nftReports[_reportId].isResolved = _isResolved;
        emit ReportResolved(_reportId, nftReports[_reportId].tokenId, _isResolved);
        // In a real application, you might add logic here to delist the NFT if _isResolved is true
        // or take other actions based on report resolution.
    }

    function pauseMarketplace(bool _pause) public onlyOwner {
        isMarketplacePaused = _pause;
        emit MarketplacePaused(_pause);
    }

    // Override _beforeTokenTransfer to handle approvals clearing on transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) { // Only clear approvals on transfers between accounts, not mint/burn
            _approve(address(0), tokenId); // Clear approval when NFT is transferred
        }
    }

    // The following functions are overrides required by Solidity when inheriting ERC721.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return dynamicNFTs[tokenId].metadataURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```