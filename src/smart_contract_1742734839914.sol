```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * ----------------------------------------------------------------------------------
 *                      Dynamic NFT Marketplace with Social Features
 * ----------------------------------------------------------------------------------
 *
 * Outline:
 * This smart contract implements a dynamic NFT marketplace with advanced social features,
 * going beyond typical listing and selling. It incorporates dynamic NFT properties,
 * user reputation based on marketplace activity, social interactions like likes and comments,
 * personalized NFT recommendations, and a basic governance mechanism for marketplace parameters.
 *
 * Function Summary:
 *
 * **Core Marketplace Functions:**
 * 1. listItem(uint256 _tokenId, uint256 _price): Allows NFT owners to list their NFTs for sale.
 * 2. buyItem(uint256 _listingId): Allows users to purchase listed NFTs.
 * 3. delistItem(uint256 _listingId): Allows NFT owners to delist their NFTs from sale.
 * 4. updateListingPrice(uint256 _listingId, uint256 _newPrice): Allows NFT owners to update the price of their listed NFTs.
 * 5. getListingDetails(uint256 _listingId): Retrieves detailed information about a specific NFT listing.
 * 6. getAllListings(): Retrieves a list of all active NFT listings.
 * 7. getListingsBySeller(address _seller): Retrieves a list of NFT listings by a specific seller.
 * 8. acceptOffer(uint256 _listingId, uint256 _offerId): Seller can accept a specific offer on their listed NFT.
 * 9. makeOffer(uint256 _listingId, uint256 _price): Buyer can make an offer on a listed NFT.
 * 10. withdrawFunds(): Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Dynamic NFT & Reputation Functions:**
 * 11. setDynamicTraitRule(uint256 _tokenId, string memory _traitName, string memory _rule): Sets a rule for dynamically updating an NFT's trait based on marketplace activity. (Example rule: "price_increase_on_sale").
 * 12. updateDynamicNFTMetadata(uint256 _tokenId): Manually triggers the update of an NFT's metadata based on dynamic rules.
 * 13. calculateUserReputation(address _user): Calculates a user's reputation score based on their buying and selling activity on the marketplace.
 * 14. getUserReputation(address _user): Retrieves a user's reputation score.
 *
 * **Social Interaction Functions:**
 * 15. likeListing(uint256 _listingId): Allows users to "like" an NFT listing, influencing its visibility and recommendations.
 * 16. commentOnListing(uint256 _listingId, string memory _comment): Allows users to comment on NFT listings for discussion and community engagement.
 * 17. getListingLikesCount(uint256 _listingId): Retrieves the number of likes for a specific NFT listing.
 * 18. getListingComments(uint256 _listingId): Retrieves all comments for a specific NFT listing.
 *
 * **Personalized Recommendation & Governance Functions:**
 * 19. generatePersonalizedRecommendations(address _user): Generates personalized NFT recommendations for a user based on their liked listings and purchase history (simplified recommendation logic).
 * 20. proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue): Allows users to propose changes to marketplace parameters like platform fees (basic governance).
 * 21. voteOnProposal(uint256 _proposalId, bool _vote): Allows users to vote on marketplace parameter change proposals.
 * 22. executeProposal(uint256 _proposalId): Executes a marketplace parameter change proposal if it passes a voting threshold.
 * 23. setPlatformFee(uint256 _feePercentage): Allows the contract owner to set the platform fee percentage.
 * 24. getPlatformFee(): Retrieves the current platform fee percentage.
 * 25. pauseMarketplace(): Allows the contract owner to pause all marketplace functions in case of emergency.
 * 26. unpauseMarketplace(): Allows the contract owner to unpause marketplace functions.
 *
 * **Events:**
 * - ItemListed: Emitted when an NFT is listed for sale.
 * - ItemSold: Emitted when an NFT is sold.
 * - ItemDelisted: Emitted when an NFT is delisted from sale.
 * - ListingPriceUpdated: Emitted when the price of a listing is updated.
 * - OfferMade: Emitted when an offer is made on a listing.
 * - OfferAccepted: Emitted when an offer is accepted.
 * - ListingLiked: Emitted when a listing is liked.
 * - ListingCommented: Emitted when a comment is added to a listing.
 * - DynamicTraitRuleSet: Emitted when a dynamic trait rule is set for an NFT.
 * - MetadataUpdated: Emitted when NFT metadata is updated dynamically.
 * - ReputationCalculated: Emitted when a user's reputation is calculated.
 * - ParameterProposalCreated: Emitted when a marketplace parameter change proposal is created.
 * - ProposalVoted: Emitted when a user votes on a proposal.
 * - ProposalExecuted: Emitted when a proposal is executed.
 * - PlatformFeeSet: Emitted when the platform fee is set.
 * - MarketplacePaused: Emitted when the marketplace is paused.
 * - MarketplaceUnpaused: Emitted when the marketplace is unpaused.
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    IERC721 public nftContract;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    bool public isPaused = false;

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        address bidder;
        uint256 price;
        bool isActive;
    }

    struct DynamicTraitRule {
        string traitName;
        string rule; // e.g., "price_increase_on_sale", "rarity_based_on_likes" - can be extended with more complex rules
    }

    struct UserProfile {
        uint256 reputationScore;
        // Can add more profile data like interests, collections, etc.
    }

    struct Comment {
        address commenter;
        string text;
        uint256 timestamp;
    }

    struct Proposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isExecuted;
    }

    mapping(uint256 => NFTListing) public listings;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => mapping(uint256 => Offer)) public listingOffers; // listingId => offerId => Offer
    mapping(uint256 => DynamicTraitRule) public dynamicNFTTraits; // tokenId => DynamicTraitRule
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => mapping(address => bool)) public listingLikes; // listingId => userAddress => liked
    mapping(uint256 => Comment[]) public listingComments; // listingId => array of Comments
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => address[]) public proposalVotes; // proposalId => array of voters
    mapping(address => uint256) public userReputations;

    Counters.Counter private _listingIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _proposalIdCounter;

    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemSold(uint256 listingId, uint256 tokenId, address seller, address buyer, uint256 price);
    event ItemDelisted(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event OfferMade(uint256 offerId, uint256 listingId, address bidder, uint256 price);
    event OfferAccepted(uint256 offerId, uint256 listingId, address seller, address buyer, uint256 price);
    event ListingLiked(uint256 listingId, address user);
    event ListingCommented(uint256 listingId, address commenter, string comment);
    event DynamicTraitRuleSet(uint256 tokenId, string traitName, string rule);
    event MetadataUpdated(uint256 tokenId, string metadataURI); // Example event - actual metadata update mechanism is off-chain in many cases
    event ReputationCalculated(address user, uint256 reputationScore);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event PlatformFeeSet(uint256 feePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();


    constructor(address _nftContractAddress) payable {
        nftContract = IERC721(_nftContractAddress);
    }

    modifier onlyWhenNotPaused() {
        require(!isPaused, "Marketplace is paused");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Listing does not exist");
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier validOffer(uint256 _offerId) {
        require(offers[_offerId].offerId == _offerId, "Offer does not exist");
        require(offers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(!proposals[_proposalId].isExecuted, "Proposal already executed");
        _;
    }

    modifier notSelfListing(uint256 _tokenId) {
        require(nftContract.ownerOf(_tokenId) != msg.sender, "Cannot list an NFT you don't own");
        _;
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _;
    }

    modifier isListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "You are not the seller of this listing");
        _;
    }


    // --- Core Marketplace Functions ---

    function listItem(uint256 _tokenId, uint256 _price) public onlyWhenNotPaused notSelfListing(_tokenId) isTokenOwner(_tokenId) {
        require(_price > 0, "Price must be greater than 0");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        nftContract.approve(address(this), _tokenId); // Approve marketplace to handle token transfer

        emit ItemListed(listingId, _tokenId, msg.sender, _price);
    }

    function buyItem(uint256 _listingId) public payable onlyWhenNotPaused validListing(_listingId) {
        NFTListing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 platformFee = listing.price.mul(platformFeePercentage).div(100);
        uint256 sellerPayout = listing.price.sub(platformFee);

        listing.isActive = false;

        nftContract.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        payable(listing.seller).transfer(sellerPayout);
        payable(owner()).transfer(platformFee); // Platform fee goes to contract owner

        emit ItemSold(listing.listingId, listing.tokenId, listing.seller, msg.sender, listing.price);

        _updateDynamicNFTOnSale(listing.tokenId); // Example dynamic NFT rule trigger
        _updateUserReputationOnTransaction(listing.seller);
        _updateUserReputationOnTransaction(msg.sender);
    }

    function delistItem(uint256 _listingId) public onlyWhenNotPaused validListing(_listingId) isListingSeller(_listingId) {
        listings[_listingId].isActive = false;
        emit ItemDelisted(_listingId, listings[_listingId].tokenId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public onlyWhenNotPaused validListing(_listingId) isListingSeller(_listingId) {
        require(_newPrice > 0, "New price must be greater than 0");
        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }

    function getListingDetails(uint256 _listingId) public view validListing(_listingId) returns (NFTListing memory) {
        return listings[_listingId];
    }

    function getAllListings() public view returns (NFTListing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        NFTListing[] memory activeListings = new NFTListing[](listingCount);
        uint256 activeListingIndex = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListings[activeListingIndex] = listings[i];
                activeListingIndex++;
            }
        }
        // Resize array to actual number of active listings
        NFTListing[] memory finalActiveListings = new NFTListing[](activeListingIndex);
        for (uint256 i = 0; i < activeListingIndex; i++) {
            finalActiveListings[i] = activeListings[i];
        }
        return finalActiveListings;
    }

    function getListingsBySeller(address _seller) public view returns (NFTListing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        NFTListing[] memory sellerListings = new NFTListing[](listingCount); // Max size, will resize later
        uint256 sellerListingIndex = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive && listings[i].seller == _seller) {
                sellerListings[sellerListingIndex] = listings[i];
                sellerListingIndex++;
            }
        }
        // Resize array to actual number of seller listings
        NFTListing[] memory finalSellerListings = new NFTListing[](sellerListingIndex);
        for (uint256 i = 0; i < sellerListingIndex; i++) {
            finalSellerListings[i] = sellerListings[i];
        }
        return finalSellerListings;
    }

    function makeOffer(uint256 _listingId, uint256 _price) public payable onlyWhenNotPaused validListing(_listingId) {
        require(msg.value >= _price, "Insufficient funds for offer");
        require(_price < listings[_listingId].price, "Offer price must be less than listing price");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        offers[offerId] = Offer({
            offerId: offerId,
            bidder: msg.sender,
            price: _price,
            isActive: true
        });
        listingOffers[_listingId][offerId] = offers[offerId];

        emit OfferMade(offerId, _listingId, msg.sender, _price);
    }

    function acceptOffer(uint256 _listingId, uint256 _offerId) public onlyWhenNotPaused validListing(_listingId) validOffer(_offerId) isListingSeller(_listingId) {
        Offer storage offerToAccept = offers[_offerId];
        require(listingOffers[_listingId][_offerId].offerId == _offerId, "Offer not associated with this listing");

        NFTListing storage listing = listings[_listingId];
        require(offerToAccept.price < listing.price, "Cannot accept offer greater than or equal to listing price, use buyItem for full price sale");


        uint256 platformFee = offerToAccept.price.mul(platformFeePercentage).div(100);
        uint256 sellerPayout = offerToAccept.price.sub(platformFee);

        listing.isActive = false;
        offerToAccept.isActive = false; // Deactivate offer

        nftContract.safeTransferFrom(listing.seller, offerToAccept.bidder, listing.tokenId);

        payable(listing.seller).transfer(sellerPayout);
        payable(owner()).transfer(platformFee);

        emit OfferAccepted(offerToAccept.offerId, _listingId, listing.seller, offerToAccept.bidder, offerToAccept.price);

        _updateDynamicNFTOnSale(listing.tokenId);
        _updateUserReputationOnTransaction(listing.seller);
        _updateUserReputationOnTransaction(offerToAccept.bidder);

        // Refund other bidders (simplified - in real system, track all offers and refund)
        // For simplicity, assuming only one offer is active per listing in this example.
        for (uint256 offerID in listingOffers[_listingId]) {
            if (offerID != _offerId && offers[offerID].isActive) {
                payable(offers[offerID].bidder).transfer(offers[offerID].price);
                offers[offerID].isActive = false; // Deactivate other offers
            }
        }
        delete listingOffers[_listingId]; // Clear all offers for this listing after acceptance
    }

    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // --- Dynamic NFT & Reputation Functions ---

    function setDynamicTraitRule(uint256 _tokenId, string memory _traitName, string memory _rule) public onlyOwner {
        dynamicNFTTraits[_tokenId] = DynamicTraitRule({
            traitName: _traitName,
            rule: _rule
        });
        emit DynamicTraitRuleSet(_tokenId, _traitName, _rule);
    }

    function updateDynamicNFTMetadata(uint256 _tokenId) public {
        // This is a simplified example. In a real-world scenario, metadata updates often happen off-chain
        // and the URI is updated on-chain.
        DynamicTraitRule memory rule = dynamicNFTTraits[_tokenId];
        if (bytes(rule.rule).length > 0) { // Check if a rule is set
            if (keccak256(bytes(rule.rule)) == keccak256(bytes("price_increase_on_sale"))) {
                // Example rule: Increase price trait on sale. (This is just a placeholder logic for demonstration)
                // In a real scenario, you might update an on-chain data structure that the NFT metadata URI points to.
                // For simplicity, we'll just emit an event indicating metadata "update".
                emit MetadataUpdated(_tokenId, "UpdatedMetadataURI_Sale"); // Placeholder URI
            }
             // Add more rule handling logic here based on `rule.rule` string
        }
        // In real applications, you'd typically interact with an off-chain metadata service to generate new metadata URI
    }

    function _updateDynamicNFTOnSale(uint256 _tokenId) private {
        updateDynamicNFTMetadata(_tokenId); // Trigger dynamic metadata update after a sale.
    }


    function calculateUserReputation(address _user) public onlyOwner {
        // Simplified reputation calculation based on transaction count (can be expanded)
        uint256 transactionCount = 0;
        uint256 listingCount = _listingIdCounter.current();
        for (uint256 i = 1; i <= listingCount; i++) {
            if (!listings[i].isActive && (listings[i].seller == _user || msg.sender == _user)) { // Check past transactions
                transactionCount++;
            }
        }
        uint256 reputationScore = transactionCount * 10; // Example: 10 points per transaction
        userReputations[_user] = reputationScore;
        emit ReputationCalculated(_user, reputationScore);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputations[_user];
    }

    function _updateUserReputationOnTransaction(address _user) private {
        calculateUserReputation(_user); // Recalculate reputation after each transaction
    }


    // --- Social Interaction Functions ---

    function likeListing(uint256 _listingId) public onlyWhenNotPaused validListing(_listingId) {
        require(!listingLikes[_listingId][msg.sender], "You have already liked this listing");
        listingLikes[_listingId][msg.sender] = true;
        emit ListingLiked(_listingId, msg.sender);
    }

    function commentOnListing(uint256 _listingId, string memory _comment) public onlyWhenNotPaused validListing(_listingId) {
        require(bytes(_comment).length > 0, "Comment cannot be empty");
        listingComments[_listingId].push(Comment({
            commenter: msg.sender,
            text: _comment,
            timestamp: block.timestamp
        }));
        emit ListingCommented(_listingId, msg.sender, _comment);
    }

    function getListingLikesCount(uint256 _listingId) public view validListing(_listingId) returns (uint256) {
        uint256 likeCount = 0;
        mapping(address => bool) storage likes = listingLikes[_listingId];
        for (address user in likes) {
            if (likes[user]) {
                likeCount++;
            }
        }
        return likeCount;
    }

    function getListingComments(uint256 _listingId) public view validListing(_listingId) returns (Comment[] memory) {
        return listingComments[_listingId];
    }


    // --- Personalized Recommendation & Governance Functions ---

    function generatePersonalizedRecommendations(address _user) public view returns (NFTListing[] memory) {
        // Simplified recommendation logic: Recommend listings with more likes.
        // In a real system, use more advanced algorithms based on user history, interests, etc.

        uint256 listingCount = _listingIdCounter.current();
        NFTListing[] memory allListings = new NFTListing[](listingCount);
        uint256 listingIndex = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                allListings[listingIndex++] = listings[i];
            }
        }

        // Sort listings by like count in descending order (simplistic recommendation)
        for (uint256 i = 0; i < listingIndex; i++) {
            for (uint256 j = i + 1; j < listingIndex; j++) {
                if (getListingLikesCount(allListings[j].listingId) > getListingLikesCount(allListings[i].listingId)) {
                    NFTListing memory temp = allListings[i];
                    allListings[i] = allListings[j];
                    allListings[j] = temp;
                }
            }
        }

        uint256 recommendationsCount = Math.min(listingIndex, 5); // Recommend top 5 (or fewer if less listings)
        NFTListing[] memory recommendations = new NFTListing[](recommendationsCount);
        for (uint256 i = 0; i < recommendationsCount; i++) {
            recommendations[i] = allListings[i];
        }
        return recommendations;
    }

    function proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue) public onlyWhenNotPaused {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty");
        require(_newValue > 0, "New value must be greater than 0"); // Example validation

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            yesVotes: 0,
            noVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            isActive: true,
            isExecuted: false
        });

        emit ParameterProposalCreated(proposalId, _parameterName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyWhenNotPaused validProposal(_proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(_hasUserVoted(_proposalId, msg.sender) == false, "User has already voted");

        proposalVotes[_proposalId].push(msg.sender); // Record voter
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner onlyWhenNotPaused validProposal(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period has not ended");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal did not pass"); // Simple majority

        Proposal storage proposal = proposals[_proposalId];
        proposal.isActive = false;
        proposal.isExecuted = true;

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("platformFeePercentage"))) {
            platformFeePercentage = proposal.newValue;
            emit PlatformFeeSet(platformFeePercentage);
            emit ProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            // Handle other parameters if needed, or revert if parameter not recognized.
            revert("Unknown parameter to update");
        }
    }

    function _hasUserVoted(uint256 _proposalId, address _user) private view returns (bool) {
        address[] storage voters = proposalVotes[_proposalId];
        for (uint256 i = 0; i < voters.length; i++) {
            if (voters[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    function pauseMarketplace() public onlyOwner {
        isPaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyOwner {
        isPaused = false;
        emit MarketplaceUnpaused();
    }

    // Fallback function to receive Ether for platform fees
    receive() external payable {}
}
```