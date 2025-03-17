```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation (Simulated)
 * @author Bard (AI Assistant)
 * @notice This smart contract implements a dynamic NFT marketplace with simulated AI-powered curation features.
 * It goes beyond basic marketplace functionalities by incorporating dynamic NFT metadata updates,
 * a simulated AI curation system based on on-chain interactions (likes, views, curator recommendations),
 * and advanced governance features for marketplace management.
 *
 * **Outline:**
 * 1. **NFT Management:** Minting Dynamic NFTs, Updating NFT Metadata, Setting Royalty.
 * 2. **Marketplace Core:** Listing NFTs, Buying NFTs, Selling NFTs, Bidding System, Offers.
 * 3. **Dynamic Metadata & Evolution:** Functions to trigger NFT metadata updates based on external events or on-chain conditions.
 * 4. **Simulated AI Curation:** Liking, Viewing, Curator Recommendations, Featured NFTs, "AI" Ranking (simple).
 * 5. **User Profiles & Reputation:** Basic user profile management and reputation system (likes received).
 * 6. **Governance & Admin:** Marketplace Fee Setting, Curator Management, Pausing/Unpausing Marketplace.
 * 7. **Utility & Helper Functions:** Getters, setters, and utility functions.
 *
 * **Function Summary:**
 * 1. `mintDynamicNFT(address _to, string memory _baseURI)`: Mints a new dynamic NFT with an initial base URI.
 * 2. `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Allows the NFT owner or curator to update the NFT's metadata.
 * 3. `setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Sets the royalty percentage for secondary sales of an NFT.
 * 4. `listNFT(uint256 _tokenId, uint256 _price)`: Allows an NFT owner to list their NFT for sale on the marketplace.
 * 5. `buyNFT(uint256 _listingId)`: Allows a buyer to purchase an NFT listed on the marketplace.
 * 6. `sellNFT(uint256 _listingId)`: Allows the marketplace admin to force sell a listed NFT (e.g., in dispute resolution, admin control).
 * 7. `bidOnNFT(uint256 _listingId, uint256 _bidAmount)`: Allows users to place bids on NFTs listed with bidding enabled.
 * 8. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows the seller to accept a specific bid on their NFT.
 * 9. `makeOffer(uint256 _tokenId, uint256 _offerPrice)`: Allows users to make direct offers on NFTs not currently listed.
 * 10. `acceptOffer(uint256 _offerId)`: Allows the NFT owner to accept a direct offer on their NFT.
 * 11. `cancelListing(uint256 _listingId)`: Allows the NFT owner to cancel their NFT listing.
 * 12. `likeNFT(uint256 _tokenId)`: Allows users to "like" an NFT, contributing to simulated AI curation.
 * 13. `viewNFT(uint256 _tokenId)`: Tracks NFT views, contributing to simulated AI curation.
 * 14. `recommendNFT(uint256 _tokenId)`: Allows curators to manually recommend NFTs, boosting their visibility.
 * 15. `getAIRecommendations(uint256 _count)`: Returns a list of NFT token IDs based on a simple "AI" ranking algorithm (likes, views, recommendations).
 * 16. `featureNFT(uint256 _tokenId)`: Allows the marketplace admin to feature specific NFTs on the homepage or prominent sections.
 * 17. `createUserProfile(string memory _username, string memory _profileData)`: Allows users to create profiles with usernames and additional data.
 * 18. `updateUserProfile(string memory _username, string memory _newProfileData)`: Allows users to update their profile data.
 * 19. `setMarketplaceFee(uint256 _feePercentage)`: Allows the marketplace admin to set the marketplace fee percentage.
 * 20. `addCurator(address _curatorAddress)`: Allows the marketplace admin to add a new curator.
 * 21. `removeCurator(address _curatorAddress)`: Allows the marketplace admin to remove a curator.
 * 22. `pauseMarketplace()`: Allows the marketplace admin to pause all marketplace functionalities.
 * 23. `unpauseMarketplace()`: Allows the marketplace admin to unpause the marketplace.
 * 24. `getListingDetails(uint256 _listingId)`: Returns detailed information about a specific NFT listing.
 * 25. `getUserProfile(address _userAddress)`: Returns the profile data associated with a user address.
 * 26. `isCurator(address _address)`: Checks if an address is a registered curator.
 */
contract DynamicAICuratorNFTMarketplace {
    // --- State Variables ---

    string public name = "Dynamic AICurator NFT Marketplace";
    string public symbol = "DAICNFT";
    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public getApproved;
    mapping(uint256 => address) public tokenApprovals;
    mapping(uint256 => string) public tokenMetadata;
    mapping(uint256 => uint256) public tokenRoyalties; // Royalty percentage (e.g., 500 for 5%)
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;
    mapping(uint256 => Offer) public offers;
    uint256 public offerCounter;
    mapping(uint256 => mapping(uint256 => Bid)) public bids; // listingId => bidId => Bid
    uint256 public bidCounter;
    mapping(uint256 => uint256) public nftLikes;
    mapping(uint256 => uint256) public nftViews;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public curators;
    address public marketplaceAdmin;
    uint256 public marketplaceFeePercentage = 250; // Default 2.5% (basis points)
    bool public paused = false;

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
        bool isAuction; // Future: Implement auction logic
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }

    struct Bid {
        uint256 bidId;
        address bidder;
        uint256 amount;
        bool isActive;
    }

    struct UserProfile {
        string username;
        string profileData;
        uint256 likesReceived;
    }

    // --- Events ---
    event NFTMinted(uint256 tokenId, address to, string metadata);
    event MetadataUpdated(uint256 tokenId, string newMetadata);
    event RoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTSoldAdmin(uint256 listingId, uint256 tokenId, address buyer, uint256 price); // Admin forced sell
    event NFTBidPlaced(uint256 listingId, uint256 bidId, address bidder, uint256 amount);
    event NFTBidAccepted(uint256 listingId, uint256 bidId, address buyer, uint256 price);
    event NFTOfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 price);
    event NFTOfferAccepted(uint256 offerId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event NFTLiked(uint256 tokenId, address user);
    event NFTViewed(uint256 tokenId, address user);
    event NFTRecommended(uint256 tokenId, address curator);
    event NFTFeatured(uint256 tokenId);
    event UserProfileCreated(address user, string username);
    event UserProfileUpdated(address user, string username);
    event MarketplaceFeeSet(uint256 feePercentage);
    event CuratorAdded(address curatorAddress);
    event CuratorRemoved(address curatorAddress);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "Not owner of NFT");
        _;
    }

    modifier onlyMarketplaceAdmin() {
        require(msg.sender == marketplaceAdmin, "Not marketplace admin");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Not a curator");
        _;
    }

    modifier isNotPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Listing does not exist");
        _;
    }

    modifier listingActive(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier offerExists(uint256 _offerId) {
        require(offers[_offerId].offerId == _offerId, "Offer does not exist");
        _;
    }

    modifier offerActive(uint256 _offerId) {
        require(offers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier bidExists(uint256 _listingId, uint256 _bidId) {
        require(bids[_listingId][_bidId].bidId == _bidId, "Bid does not exist");
        _;
    }

    modifier bidActive(uint256 _listingId, uint256 _bidId) {
        require(bids[_listingId][_bidId].isActive, "Bid is not active");
        _;
    }


    // --- Constructor ---
    constructor() {
        marketplaceAdmin = msg.sender;
    }

    // --- 1. NFT Management Functions ---

    /**
     * @notice Mints a new dynamic NFT.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The initial base URI for the NFT's metadata.
     */
    function mintDynamicNFT(address _to, string memory _baseURI) public onlyMarketplaceAdmin {
        totalSupply++;
        uint256 newTokenId = totalSupply;
        ownerOf[newTokenId] = _to;
        balanceOf[_to]++;
        tokenMetadata[newTokenId] = _baseURI; // Initial base URI, can be updated dynamically
        emit NFTMinted(newTokenId, _to, _baseURI);
    }

    /**
     * @notice Updates the metadata URI for a specific NFT. Can be called by the NFT owner or a curator.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadata The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public {
        require(ownerOf[_tokenId] == msg.sender || curators[msg.sender], "Not owner or curator");
        tokenMetadata[_tokenId] = _newMetadata;
        emit MetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @notice Sets the royalty percentage for secondary sales of an NFT. Only NFT owner can set.
     * @param _tokenId The ID of the NFT.
     * @param _royaltyPercentage The royalty percentage (e.g., 500 for 5%).
     */
    function setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) public onlyOwnerOfToken(_tokenId) {
        require(_royaltyPercentage <= 10000, "Royalty percentage too high (max 100%)");
        tokenRoyalties[_tokenId] = _royaltyPercentage;
        emit RoyaltySet(_tokenId, _royaltyPercentage);
    }


    // --- 2. Marketplace Core Functions ---

    /**
     * @notice Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listNFT(uint256 _tokenId, uint256 _price) public onlyOwnerOfToken(_tokenId) isNotPaused {
        require(ownerOf[_tokenId] == msg.sender, "Not owner");
        require(tokenApprovals[_tokenId] == address(this) || getApproved[_tokenId][msg.sender], "Marketplace not approved");
        require(_price > 0, "Price must be greater than zero");

        listingCounter++;
        listings[listingCounter] = Listing({
            listingId: listingCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            isAuction: false // Future: Implement auction logic
        });

        // Transfer NFT to marketplace contract for escrow (optional for simpler implementation, but recommended for trustless setup)
        // SafeTransferFrom functionality needs to be implemented (ERC721 standard) if you want to escrow NFTs.
        // For this example, we assume approval is sufficient and no escrow is implemented for simplicity.

        emit NFTListed(listingCounter, _tokenId, msg.sender, _price);
    }

    /**
     * @notice Allows a buyer to purchase an NFT listed on the marketplace.
     * @param _listingId The ID of the listing to purchase.
     */
    function buyNFT(uint256 _listingId) public payable isNotPaused listingExists(_listingId) listingActive(_listingId) {
        Listing storage currentListing = listings[_listingId];
        require(msg.value >= currentListing.price, "Insufficient funds");
        require(currentListing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 tokenId = currentListing.tokenId;
        uint256 price = currentListing.price;
        address seller = currentListing.seller;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        uint256 royaltyFee = (price * tokenRoyalties[tokenId]) / 10000;
        uint256 sellerProceeds = price - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(marketplaceAdmin).transfer(marketplaceFee);
        if (royaltyFee > 0 && ownerOf[tokenId] != address(0)) { // Check if royalty exists and NFT has an owner (minted)
            address originalCreator = ownerOf[tokenId]; // In a real scenario, track creator address during minting
            payable(originalCreator).transfer(royaltyFee); // Assuming creator is same as initial owner for simplicity
        }
        payable(seller).transfer(sellerProceeds);

        // Transfer NFT ownership
        ownerOf[tokenId] = msg.sender;
        balanceOf[seller]--;
        balanceOf[msg.sender]++;

        // Deactivate listing
        currentListing.isActive = false;

        emit NFTBought(_listingId, tokenId, msg.sender, price);
    }

    /**
     * @notice Allows the marketplace admin to force sell a listed NFT (admin control/dispute resolution).
     * @param _listingId The ID of the listing to sell.
     */
    function sellNFT(uint256 _listingId) public onlyMarketplaceAdmin isNotPaused listingExists(_listingId) listingActive(_listingId) {
        Listing storage currentListing = listings[_listingId];
        uint256 tokenId = currentListing.tokenId;
        uint256 price = currentListing.price;
        address seller = currentListing.seller;
        address buyer = marketplaceAdmin; // Admin is forced buyer in this case

        // No funds are transferred in this forced sell scenario (admin control, dispute resolution etc.).
        // In a real-world scenario, you might have a more complex logic for fund handling in admin sells.

        // Transfer NFT ownership to admin (as forced buyer for admin control scenario)
        ownerOf[tokenId] = buyer;
        balanceOf[seller]--;
        balanceOf[buyer]++;

        // Deactivate listing
        currentListing.isActive = false;

        emit NFTSoldAdmin(_listingId, tokenId, buyer, price);
    }

    /**
     * @notice Allows users to place bids on NFTs listed with bidding enabled (Future feature).
     * @param _listingId The ID of the listing to bid on.
     * @param _bidAmount The amount of wei to bid.
     */
    function bidOnNFT(uint256 _listingId, uint256 _bidAmount) public payable isNotPaused listingExists(_listingId) listingActive(_listingId) {
        Listing storage currentListing = listings[_listingId];
        require(currentListing.isAuction, "Bidding is not enabled for this listing"); // Future: Auction logic
        require(msg.value >= _bidAmount, "Insufficient bid amount");
        require(_bidAmount > 0, "Bid amount must be greater than zero");
        require(currentListing.seller != msg.sender, "Cannot bid on your own NFT");

        bidCounter++;
        bids[_listingId][bidCounter] = Bid({
            bidId: bidCounter,
            bidder: msg.sender,
            amount: _bidAmount,
            isActive: true
        });

        // Future: Implement logic to handle previous bids, refunds, etc.
        // For simplicity, this example just records the bid.

        emit NFTBidPlaced(_listingId, bidCounter, msg.sender, _bidAmount);
    }

    /**
     * @notice Allows the seller to accept a specific bid on their NFT (Future auction feature).
     * @param _listingId The ID of the listing.
     * @param _bidId The ID of the bid to accept.
     */
    function acceptBid(uint256 _listingId, uint256 _bidId) public onlyOwnerOfToken(listings[_listingId].tokenId) isNotPaused listingExists(_listingId) listingActive(_listingId) bidExists(_listingId, _bidId) bidActive(_listingId, _bidId) {
        Listing storage currentListing = listings[_listingId];
        Bid storage currentBid = bids[_listingId][_bidId];
        require(currentListing.seller == msg.sender, "Not the seller of the NFT");
        require(currentListing.isAuction, "Bidding is not enabled for this listing"); // Future: Auction logic

        uint256 tokenId = currentListing.tokenId;
        uint256 price = currentBid.amount;
        address seller = currentListing.seller;
        address buyer = currentBid.bidder;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        uint256 royaltyFee = (price * tokenRoyalties[tokenId]) / 10000;
        uint256 sellerProceeds = price - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(marketplaceAdmin).transfer(marketplaceFee);
        if (royaltyFee > 0 && ownerOf[tokenId] != address(0)) {
            address originalCreator = ownerOf[tokenId]; // In a real scenario, track creator address during minting
            payable(originalCreator).transfer(royaltyFee);
        }
        payable(seller).transfer(sellerProceeds);
        payable(buyer).transfer(price); // Refund buyer their bid amount (assuming bid amount is already held in escrow - future feature)


        // Transfer NFT ownership
        ownerOf[tokenId] = buyer;
        balanceOf[seller]--;
        balanceOf[buyer]++;

        // Deactivate listing and bid
        currentListing.isActive = false;
        currentBid.isActive = false;

        emit NFTBidAccepted(_listingId, _bidId, buyer, price);
    }

    /**
     * @notice Allows users to make direct offers on NFTs that are not currently listed.
     * @param _tokenId The ID of the NFT to make an offer on.
     * @param _offerPrice The price offered in wei.
     */
    function makeOffer(uint256 _tokenId, uint256 _offerPrice) public payable isNotPaused {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist"); // Check if NFT is minted
        require(_offerPrice > 0, "Offer price must be greater than zero");
        require(ownerOf[_tokenId] != msg.sender, "Cannot make offer on your own NFT");

        offerCounter++;
        offers[offerCounter] = Offer({
            offerId: offerCounter,
            tokenId: _tokenId,
            offerer: msg.sender,
            price: _offerPrice,
            isActive: true
        });

        emit NFTOfferMade(offerCounter, _tokenId, msg.sender, _offerPrice);
    }

    /**
     * @notice Allows the NFT owner to accept a direct offer made on their NFT.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) public payable isNotPaused offerExists(_offerId) offerActive(_offerId) {
        Offer storage currentOffer = offers[_offerId];
        uint256 tokenId = currentOffer.tokenId;
        require(ownerOf[tokenId] == msg.sender, "Not owner of the NFT");

        uint256 price = currentOffer.price;
        address seller = msg.sender;
        address buyer = currentOffer.offerer;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        uint256 royaltyFee = (price * tokenRoyalties[tokenId]) / 10000;
        uint256 sellerProceeds = price - marketplaceFee - royaltyFee;

        // Transfer funds
        payable(marketplaceAdmin).transfer(marketplaceFee);
        if (royaltyFee > 0 && ownerOf[tokenId] != address(0)) {
            address originalCreator = ownerOf[tokenId]; // In a real scenario, track creator address during minting
            payable(originalCreator).transfer(royaltyFee);
        }
        payable(seller).transfer(sellerProceeds);
        payable(buyer).transfer(price); // Assuming offer amount is already held in escrow - future feature

        // Transfer NFT ownership
        ownerOf[tokenId] = buyer;
        balanceOf[seller]--;
        balanceOf[buyer]++;

        // Deactivate offer
        currentOffer.isActive = false;

        emit NFTOfferAccepted(_offerId, tokenId, buyer, price);
    }


    /**
     * @notice Allows the NFT owner to cancel an active listing.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public isNotPaused listingExists(_listingId) listingActive(_listingId) onlyOwnerOfToken(listings[_listingId].tokenId) {
        require(listings[_listingId].seller == msg.sender, "Not the seller of the NFT");
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId);
    }


    // --- 4. Simulated AI Curation Functions ---

    /**
     * @notice Allows users to "like" an NFT. Contributes to simulated AI curation.
     * @param _tokenId The ID of the NFT to like.
     */
    function likeNFT(uint256 _tokenId) public isNotPaused {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist"); // Check if NFT is minted
        nftLikes[_tokenId]++;
        UserProfile storage profile = userProfiles[ownerOf[_tokenId]];
        profile.likesReceived++;
        emit NFTLiked(_tokenId, msg.sender);
    }

    /**
     * @notice Tracks NFT views. Contributes to simulated AI curation.
     * @param _tokenId The ID of the NFT viewed.
     */
    function viewNFT(uint256 _tokenId) public isNotPaused {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist"); // Check if NFT is minted
        nftViews[_tokenId]++;
        emit NFTViewed(_tokenId, msg.sender);
    }

    /**
     * @notice Allows curators to manually recommend NFTs, boosting their visibility.
     * @param _tokenId The ID of the NFT to recommend.
     */
    function recommendNFT(uint256 _tokenId) public onlyCurator isNotPaused {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist"); // Check if NFT is minted
        nftLikes[_tokenId] += 5; // Boost likes as a simple recommendation metric
        emit NFTRecommended(_tokenId, msg.sender);
    }

    /**
     * @notice Returns a list of NFT token IDs based on a simple "AI" ranking algorithm (likes, views, recommendations).
     *  This is a simplified simulation of AI curation. In a real-world scenario, this would be much more complex
     *  and likely handled off-chain.
     * @param _count The number of recommendations to return.
     * @return An array of NFT token IDs, ranked by a simple "AI" score.
     */
    function getAIRecommendations(uint256 _count) public view isNotPaused returns (uint256[] memory) {
        require(totalSupply > 0, "No NFTs minted yet");
        uint256[] memory rankedTokenIds = new uint256[](_count);
        uint256[] memory scores = new uint256[](totalSupply);
        uint256[] memory tokenIds = new uint256[](totalSupply);

        for (uint256 i = 1; i <= totalSupply; i++) {
            tokenIds[i - 1] = i;
            scores[i - 1] = nftLikes[i] + (nftViews[i] / 2); // Simple score: likes + half views
        }

        // Simple Bubble Sort for ranking (inefficient for large datasets, but fine for example)
        for (uint256 i = 0; i < totalSupply - 1; i++) {
            for (uint256 j = 0; j < totalSupply - i - 1; j++) {
                if (scores[j] < scores[j + 1]) {
                    // Swap scores
                    uint256 tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;
                    // Swap tokenIds
                    uint256 tempTokenId = tokenIds[j];
                    tokenIds[j] = tokenIds[j + 1];
                    tokenIds[j + 1] = tempTokenId;
                }
            }
        }

        uint256 recommendationsCount = 0;
        for (uint256 i = 0; i < totalSupply && recommendationsCount < _count; i++) {
            rankedTokenIds[recommendationsCount] = tokenIds[i];
            recommendationsCount++;
        }

        return rankedTokenIds;
    }

    /**
     * @notice Allows the marketplace admin to feature specific NFTs on prominent sections.
     * @param _tokenId The ID of the NFT to feature.
     */
    function featureNFT(uint256 _tokenId) public onlyMarketplaceAdmin isNotPaused {
        require(ownerOf[_tokenId] != address(0), "NFT does not exist"); // Check if NFT is minted
        nftLikes[_tokenId] += 100; // Give featured NFTs a significant like boost for ranking
        emit NFTFeatured(_tokenId);
    }


    // --- 5. User Profile Functions ---

    /**
     * @notice Allows users to create a profile.
     * @param _username The desired username.
     * @param _profileData Additional profile information (e.g., bio, links).
     */
    function createUserProfile(string memory _username, string memory _profileData) public isNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists"); // Only create once
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileData: _profileData,
            likesReceived: 0
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /**
     * @notice Allows users to update their profile data.
     * @param _username The new username (optional, can keep same).
     * @param _newProfileData The updated profile information.
     */
    function updateUserProfile(string memory _username, string memory _newProfileData) public isNotPaused {
        require(bytes(userProfiles[msg.sender].username).length > 0, "No profile to update"); // Profile must exist
        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].profileData = _newProfileData;
        emit UserProfileUpdated(msg.sender, _username);
    }


    // --- 6. Governance & Admin Functions ---

    /**
     * @notice Sets the marketplace fee percentage. Only admin can call.
     * @param _feePercentage The new fee percentage (basis points, e.g., 250 for 2.5%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyMarketplaceAdmin isNotPaused {
        require(_feePercentage <= 10000, "Fee percentage too high (max 100%)");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @notice Adds a new curator. Only admin can call.
     * @param _curatorAddress The address of the curator to add.
     */
    function addCurator(address _curatorAddress) public onlyMarketplaceAdmin isNotPaused {
        curators[_curatorAddress] = true;
        emit CuratorAdded(_curatorAddress);
    }

    /**
     * @notice Removes a curator. Only admin can call.
     * @param _curatorAddress The address of the curator to remove.
     */
    function removeCurator(address _curatorAddress) public onlyMarketplaceAdmin isNotPaused {
        curators[_curatorAddress] = false;
        emit CuratorRemoved(_curatorAddress);
    }

    /**
     * @notice Pauses all marketplace functionalities. Only admin can call.
     */
    function pauseMarketplace() public onlyMarketplaceAdmin {
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @notice Unpauses all marketplace functionalities. Only admin can call.
     */
    function unpauseMarketplace() public onlyMarketplaceAdmin {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // --- 7. Utility & Helper Functions ---

    /**
     * @notice Returns detailed information about a specific NFT listing.
     * @param _listingId The ID of the listing.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) public view listingExists(_listingId) returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @notice Returns the profile data associated with a user address.
     * @param _userAddress The address of the user.
     * @return UserProfile struct containing user profile data.
     */
    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    /**
     * @notice Checks if an address is a registered curator.
     * @param _address The address to check.
     * @return True if the address is a curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        return curators[_address];
    }

    // --- ERC721 Interface (Simplified - for full ERC721, implement interfaces) ---

    function approve(address _approved, uint256 _tokenId) public payable onlyOwnerOfToken(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf[_tokenId], _approved, _tokenId); // Assuming Approval event from ERC721
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        getApproved[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved); // Assuming ApprovalForAll event from ERC721
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public payable {
        require(ownerOf[_tokenId] == _from, "Not owner");
        require(_to != address(0), "Transfer to zero address");
        require(msg.sender == _from || tokenApprovals[_tokenId] == msg.sender || getApproved[_from][msg.sender], "Not approved");

        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
        require(ownerOf[_tokenId] == _from, "Not owner");
        require(_to != address(0), "Transfer to zero address");
        require(msg.sender == _from || tokenApprovals[_tokenId] == msg.sender || getApproved[_from][msg.sender], "Not approved");
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721Receiver rejected transfer");

        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        delete tokenApprovals[_tokenId]; // Reset approval after transfer
        emit Transfer(_from, _to, _tokenId); // Assuming Transfer event from ERC721
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721Receiver rejected transfer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // --- ERC721 Interface Events (For proper ERC721 compliance, these should be defined in an interface) ---
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

// --- Interface for ERC721Receiver (For safeTransferFrom) ---
interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}
```