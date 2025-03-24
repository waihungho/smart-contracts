```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Personalization (Simulated)
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized NFT marketplace with dynamic NFT features and a simulated AI personalization layer.
 * It aims to be creative and trendy by incorporating concepts like dynamic NFT traits, user reputation, and a simulated recommendation system.
 * **Outline:**
 * 1. **Marketplace Core Functions:**
 *    - Listing NFTs for sale
 *    - Purchasing NFTs
 *    - Delisting NFTs
 *    - Bidding system for NFTs
 *    - Accepting bids
 *    - Cancelling bids
 * 2. **Dynamic NFT Features:**
 *    - NFT Trait Evolution: NFTs can evolve their traits based on marketplace activity or owner actions.
 *    - External Data Integration (Simulated):  Simulates fetching external data to influence NFT dynamics (e.g., market trends).
 *    - NFT Rarity Adjustment:  Rarity of NFTs can dynamically adjust based on demand or other factors.
 * 3. **AI Personalization (Simulated):**
 *    - User Profile System: Users can create profiles with preferences.
 *    - Recommendation Engine (Simulated):  Recommends NFTs to users based on their profile and marketplace trends.
 *    - Personalized Feed: Provides a feed of recommended NFTs to users.
 * 4. **User Reputation and Rewards:**
 *    - User Reputation System: Tracks user reputation based on positive marketplace actions.
 *    - Reputation-Based Discounts: Higher reputation users get discounts.
 *    - Reputation-Based Early Access: High reputation users get early access to new features.
 * 5. **Advanced Marketplace Features:**
 *    - NFT Bundling: Allows selling multiple NFTs as a bundle.
 *    - Royalty System: Implements creator royalties on secondary sales.
 *    - Staking for Reputation Boost: Users can stake tokens to temporarily boost reputation.
 * 6. **Governance and Utility:**
 *    - Decentralized Governance (Simple): Basic voting on platform parameters.
 *    - Emergency Pause Function: Owner can pause the contract in case of critical issues.
 *    - Batch Listing/Purchase:  Allows listing/purchasing multiple NFTs in one transaction.
 *    - NFT Gifting:  Users can gift NFTs to others.
 * 7. **Utility and Helper Functions:**
 *    - Search and Filtering: Basic search and filtering for NFTs.
 *    - Event Logging: Comprehensive event logging for off-chain tracking.
 *
 * **Function Summary:**
 * 1. `createListing(uint256 _tokenId, address _nftContract, uint256 _price)`: Allows users to list their NFTs for sale in the marketplace.
 * 2. `purchaseNFT(uint256 _listingId)`: Allows users to purchase an NFT listed in the marketplace.
 * 3. `delistNFT(uint256 _listingId)`: Allows sellers to delist their NFTs from the marketplace.
 * 4. `placeBid(uint256 _listingId, uint256 _bidAmount)`: Allows users to place bids on listed NFTs.
 * 5. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows sellers to accept a bid on their listed NFT.
 * 6. `cancelBid(uint256 _listingId, uint256 _bidId)`: Allows bidders to cancel their bids before they are accepted.
 * 7. `evolveNFTTraits(uint256 _tokenId, address _nftContract)`: Simulates the evolution of NFT traits based on marketplace activity (example dynamic NFT feature).
 * 8. `fetchMarketTrend()`: Simulates fetching external market trend data (example of external data integration for dynamic NFTs).
 * 9. `adjustNFTRarity(uint256 _tokenId, address _nftContract)`: Dynamically adjusts NFT rarity based on simulated market conditions.
 * 10. `createUserProfile(string _username, string _preferences)`: Allows users to create a profile with username and preferences for personalization.
 * 11. `updateUserProfile(string _username, string _newPreferences)`: Allows users to update their profile preferences.
 * 12. `recommendNFTsForUser(address _userAddress)`: Simulates recommending NFTs to a user based on their profile and market trends.
 * 13. `getPersonalizedNFTFeed(address _userAddress)`: Returns a simulated personalized feed of recommended NFTs for a user.
 * 14. `increaseUserReputation(address _userAddress)`: Increases a user's reputation based on positive actions (e.g., successful trades).
 * 15. `decreaseUserReputation(address _userAddress)`: Decreases a user's reputation based on negative actions (e.g., bid cancellations after acceptance - example, more complex logic can be added).
 * 16. `applyReputationDiscount(uint256 _price, address _userAddress)`: Applies a discount to the price based on user reputation.
 * 17. `grantEarlyAccess(address _userAddress)`: Grants early access to new features for high reputation users (example function, actual feature implementation needed elsewhere).
 * 18. `bundleNFTs(uint256[] _tokenIds, address[] _nftContracts, uint256 _bundlePrice)`: Allows users to create a bundle of NFTs for sale.
 * 19. `purchaseNFTBundle(uint256 _bundleId)`: Allows users to purchase an NFT bundle.
 * 20. `setRoyaltyPercentage(uint256 _percentage)`: Sets the royalty percentage for secondary sales.
 * 21. `stakeForReputationBoost(uint256 _amount)`: Allows users to stake tokens to temporarily boost their reputation.
 * 22. `voteOnParameterChange(string _parameterName, uint256 _newValue)`: Simulates a basic decentralized governance voting mechanism.
 * 23. `pauseContract()`: Allows the contract owner to pause the marketplace operations.
 * 24. `unpauseContract()`: Allows the contract owner to unpause the marketplace operations.
 * 25. `batchListNFTs(uint256[] _tokenIds, address[] _nftContracts, uint256[] _prices)`: Allows batch listing of NFTs.
 * 26. `batchPurchaseNFTs(uint256[] _listingIds)`: Allows batch purchasing of NFTs.
 * 27. `giftNFT(uint256 _listingId, address _recipient)`: Allows users to gift a listed NFT to another user.
 * 28. `searchNFTs(string _searchTerm)`: Simulates searching NFTs based on a search term (basic example).
 * 29. `filterNFTsByTrait(string _traitName, string _traitValue)`: Simulates filtering NFTs based on traits (basic example).
 * 30. `getListingDetails(uint256 _listingId)`: Returns detailed information about a specific NFT listing.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplace is Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _bidIds;
    Counters.Counter private _bundleIds;

    uint256 public royaltyPercentage = 5; // Default royalty percentage

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address nftContract;
        address seller;
        uint256 price;
        bool isActive;
        uint256[] bidIds; // Array to store bid IDs for this listing
    }

    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidAmount;
        bool isActive;
    }

    struct UserProfile {
        string username;
        string preferences; // Store user preferences as a string (can be more structured in real app)
        uint256 reputation;
    }

    struct NFTBundle {
        uint256 bundleId;
        uint256[] tokenIds;
        address[] nftContracts;
        address seller;
        uint256 bundlePrice;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bid) public bids;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => NFTBundle) public nftBundles;
    mapping(uint256 => address) public listingIdToSeller; // For easier delisting and management

    event NFTListed(uint256 listingId, uint256 tokenId, address nftContract, address seller, uint256 price);
    event NFTPurchased(uint256 listingId, uint256 tokenId, address nftContract, address buyer, uint256 price);
    event NFTDelisted(uint256 listingId);
    event BidPlaced(uint256 bidId, uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 bidId, uint256 listingId, address seller, address bidder, uint256 price);
    event BidCancelled(uint256 bidId, uint256 listingId, address bidder);
    event NFTTraitsEvolved(uint256 tokenId, address nftContract, string newTraits);
    event MarketTrendFetched(string trendData);
    event NFTRarityAdjusted(uint256 tokenId, address nftContract, string newRarity);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newPreferences);
    event NFTRecommended(address userAddress, uint256 tokenId, address nftContract, string reason);
    event ReputationIncreased(address userAddress, uint256 newReputation);
    event ReputationDecreased(address userAddress, uint256 newReputation);
    event NFTBundleCreated(uint256 bundleId, address seller, uint256 bundlePrice, uint256[] tokenIds, address[] nftContracts);
    event NFTBundlePurchased(uint256 bundleId, address buyer, uint256 bundlePrice);
    event RoyaltyPercentageSet(uint256 percentage);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event NFTGifted(uint256 listingId, address from, address to);

    modifier onlyActiveListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "You are not the seller");
        _;
    }

    modifier onlyBidder(uint256 _bidId) {
        require(bids[_bidId].bidder == msg.sender, "You are not the bidder");
        _;
    }

    modifier validNFT(address _nftContract, uint256 _tokenId) {
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not owner of NFT");
        _;
    }

    modifier validListingPrice(uint256 _price) {
        require(_price > 0, "Price must be greater than zero");
        _;
    }

    modifier validBidAmount(uint256 _bidAmount, uint256 _listingId) {
        require(_bidAmount > 0 && _bidAmount > listings[_listingId].price, "Bid amount must be greater than listing price and zero"); // Example condition
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // 1. Marketplace Core Functions
    function createListing(
        uint256 _tokenId,
        address _nftContract,
        uint256 _price
    )
        external
        payable
        validNFT(_nftContract, _tokenId)
        validListingPrice(_price)
        whenNotPaused
    {
        IERC721 nft = IERC721(_nftContract);
        // Transfer NFT to marketplace contract - for escrow (optional, depends on desired flow, can also use approval)
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            nftContract: _nftContract,
            seller: msg.sender,
            price: _price,
            isActive: true,
            bidIds: new uint256[](0) // Initialize empty bid array
        });
        listingIdToSeller[listingId] = msg.sender;

        emit NFTListed(listingId, _tokenId, _nftContract, msg.sender, _price);
    }

    function purchaseNFT(uint256 _listingId)
        external
        payable
        onlyActiveListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");

        IERC721 nft = IERC721(listing.nftContract);

        // Transfer NFT to buyer
        nft.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        // Transfer funds to seller (minus royalty)
        uint256 royaltyAmount = (listing.price * royaltyPercentage) / 100;
        uint256 sellerAmount = listing.price - royaltyAmount;
        payable(listing.seller).transfer(sellerAmount);
        // Optionally handle royalty distribution (e.g., to creator, if tracked)
        // For simplicity, royalty is burned or sent to contract owner in this example.
        payable(owner()).transfer(royaltyAmount); // Example royalty distribution to owner.

        listing.isActive = false;
        emit NFTPurchased(_listingId, listing.tokenId, listing.nftContract, msg.sender, listing.price);

        // Example: Trigger NFT trait evolution on purchase
        evolveNFTTraits(listing.tokenId, listing.nftContract);
        increaseUserReputation(listing.seller); // Increase seller reputation
        increaseUserReputation(msg.sender); // Increase buyer reputation
    }

    function delistNFT(uint256 _listingId)
        external
        onlyActiveListing(_listingId)
        onlyListingSeller(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];

        IERC721 nft = IERC721(listing.nftContract);
        // Return NFT to seller
        nft.safeTransferFrom(address(this), listing.seller, listing.tokenId);

        listing.isActive = false;
        emit NFTDelisted(_listingId);
    }

    function placeBid(uint256 _listingId, uint256 _bidAmount)
        external
        payable
        onlyActiveListing(_listingId)
        validBidAmount(_bidAmount, _listingId)
        whenNotPaused
    {
        _bidIds.increment();
        uint256 bidId = _bidIds.current();

        bids[bidId] = Bid({
            bidId: bidId,
            listingId: _listingId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            isActive: true
        });

        listings[_listingId].bidIds.push(bidId); // Add bid ID to listing's bid array

        emit BidPlaced(bidId, _listingId, msg.sender, _bidAmount);
    }

    function acceptBid(uint256 _listingId, uint256 _bidId)
        external
        onlyActiveListing(_listingId)
        onlyListingSeller(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];
        Bid storage bid = bids[_bidId];

        require(bid.listingId == _listingId, "Bid is not for this listing");
        require(bid.isActive, "Bid is not active");

        IERC721 nft = IERC721(listing.nftContract);

        // Transfer NFT to bidder
        nft.safeTransferFrom(address(this), bid.bidder, listing.tokenId);

        // Transfer bid amount to seller (minus royalty)
        uint256 royaltyAmount = (bid.bidAmount * royaltyPercentage) / 100;
        uint256 sellerAmount = bid.bidAmount - royaltyAmount;
        payable(listing.seller).transfer(sellerAmount);
        payable(owner()).transfer(royaltyAmount);

        listing.isActive = false;
        bid.isActive = false; // Mark bid as inactive

        emit BidAccepted(_bidId, _listingId, listing.seller, bid.bidder, bid.bidAmount);

        // Example: Trigger NFT trait evolution on bid acceptance
        evolveNFTTraits(listing.tokenId, listing.nftContract);
        increaseUserReputation(listing.seller); // Increase seller reputation
        increaseUserReputation(bid.bidder); // Increase bidder reputation

        // Optionally cancel other bids on this listing - for simplicity omitted here.
    }

    function cancelBid(uint256 _listingId, uint256 _bidId)
        external
        onlyActiveListing(_listingId)
        onlyBidder(_bidId)
        whenNotPaused
    {
        Bid storage bid = bids[_bidId];
        require(bid.listingId == _listingId, "Bid is not for this listing");
        require(bid.isActive, "Bid is not active");

        bid.isActive = false; // Mark bid as inactive
        emit BidCancelled(_bidId, _listingId, msg.sender);

        // Example: Decrease reputation for bid cancellation (optional, can adjust logic)
        decreaseUserReputation(msg.sender);
    }

    // 2. Dynamic NFT Features (Simulated)
    function evolveNFTTraits(uint256 _tokenId, address _nftContract) internal {
        // Simulated trait evolution logic - in reality, this would likely be off-chain or use oracles for more complex logic
        // For simplicity, just emit an event with "new traits" based on tokenId
        string memory newTraits = string(abi.encodePacked("Traits evolved for NFT ID: ", Strings.toString(_tokenId), " - based on marketplace activity."));
        emit NFTTraitsEvolved(_tokenId, _nftContract, newTraits);
    }

    function fetchMarketTrend() public pure returns (string memory) {
        // Simulated external data fetch - in reality, would use oracles like Chainlink
        // Return a random trend for demonstration
        uint256 randomTrend = block.timestamp % 3;
        string memory trend;
        if (randomTrend == 0) {
            trend = "Market is bullish on digital art.";
        } else if (randomTrend == 1) {
            trend = "Collectibles are trending upwards.";
        } else {
            trend = "Metaverse NFTs are gaining momentum.";
        }
        emit MarketTrendFetched(trend);
        return trend;
    }

    function adjustNFTRarity(uint256 _tokenId, address _nftContract) internal {
        // Simulated rarity adjustment logic - based on simulated market trend and NFT ID.
        string memory marketTrend = fetchMarketTrend();
        string memory newRarity;
        if (stringContains(marketTrend, "bullish")) {
            newRarity = "Increased Rarity due to bullish market.";
        } else {
            newRarity = "Rarity slightly adjusted based on market trends.";
        }
        emit NFTRarityAdjusted(_tokenId, _nftContract, newRarity);
    }

    // 3. AI Personalization (Simulated)
    function createUserProfile(string memory _username, string memory _preferences) external whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists"); // Prevent profile overwrite.
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            preferences: _preferences,
            reputation: 0 // Initial reputation
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    function updateUserProfile(string memory _username, string memory _newPreferences) external whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length > 0, "Profile does not exist");
        userProfiles[msg.sender].preferences = _newPreferences;
        userProfiles[msg.sender].username = _username; // Allow username update too
        emit UserProfileUpdated(msg.sender, _newPreferences);
    }

    function recommendNFTsForUser(address _userAddress) public view returns (uint256[] memory, address[] memory, string[] memory) {
        // Simulated recommendation engine - very basic example.
        // In reality, this would be much more complex and likely off-chain AI-driven.
        UserProfile storage profile = userProfiles[_userAddress];
        string memory preferences = profile.preferences;
        string memory marketTrend = fetchMarketTrend();

        uint256[] memory recommendedTokenIds = new uint256[](3); // Recommend up to 3 NFTs
        address[] memory recommendedContracts = new address[](3);
        string[] memory reasons = new string[](3);
        uint256 recommendationCount = 0;

        // Simple logic: Recommend NFTs based on market trend and user preferences (very basic string matching)
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                Listing storage listing = listings[i];
                string memory nftDescription = string(abi.encodePacked("NFT ID: ", Strings.toString(listing.tokenId), " from contract: ", addressToString(listing.nftContract))); // Very basic description

                if (stringContains(nftDescription, preferences) || stringContains(marketTrend, preferences)) { // Check if description or trend matches user preferences
                    if (recommendationCount < 3) {
                        recommendedTokenIds[recommendationCount] = listing.tokenId;
                        recommendedContracts[recommendationCount] = listing.nftContract;
                        reasons[recommendationCount] = "Matching user preferences and market trends.";
                        recommendationCount++;
                    }
                }
            }
        }
        return (recommendedTokenIds, recommendedContracts, reasons);
    }

    function getPersonalizedNFTFeed(address _userAddress) external view returns (Listing[] memory, string[] memory) {
        (uint256[] memory tokenIds, address[] memory nftContracts, string[] memory reasons) = recommendNFTsForUser(_userAddress);
        uint256 feedLength = tokenIds.length;
        Listing[] memory feedListings = new Listing[](feedLength);
        string[] memory feedReasons = new string[](feedLength);

        for (uint256 i = 0; i < feedLength; i++) {
            for (uint256 j = 1; j <= _listingIds.current(); j++) {
                if (listings[j].isActive && listings[j].tokenId == tokenIds[i] && listings[j].nftContract == nftContracts[i]) {
                    feedListings[i] = listings[j];
                    feedReasons[i] = reasons[i];
                    break; // Found the listing, move to next recommendation
                }
            }
        }
        return (feedListings, feedReasons);
    }

    // 4. User Reputation and Rewards
    function increaseUserReputation(address _userAddress) internal {
        userProfiles[_userAddress].reputation++; // Simple reputation increase
        emit ReputationIncreased(_userAddress, userProfiles[_userAddress].reputation);
    }

    function decreaseUserReputation(address _userAddress) internal {
        if (userProfiles[_userAddress].reputation > 0) {
            userProfiles[_userAddress].reputation--; // Simple reputation decrease, prevent negative
            emit ReputationDecreased(_userAddress, userProfiles[_userAddress].reputation);
        }
    }

    function applyReputationDiscount(uint256 _price, address _userAddress) public view returns (uint256) {
        uint256 reputation = userProfiles[_userAddress].reputation;
        uint256 discountPercentage = reputation; // Example: 1% discount per reputation point (adjust as needed)
        if (discountPercentage > 50) discountPercentage = 50; // Cap discount at 50% (example)
        uint256 discountAmount = (_price * discountPercentage) / 100;
        return _price - discountAmount;
    }

    function grantEarlyAccess(address _userAddress) public view returns (bool) {
        // Example: Grant early access if reputation is above a threshold
        return userProfiles[_userAddress].reputation >= 10; // Example threshold
        // In a real application, this function might trigger other contract functionalities or off-chain actions.
    }

    // 5. Advanced Marketplace Features
    function bundleNFTs(
        uint256[] memory _tokenIds,
        address[] memory _nftContracts,
        uint256 _bundlePrice
    ) external payable validBundleNFTs(_tokenIds, _nftContracts) validListingPrice(_bundlePrice) whenNotPaused {
        require(_tokenIds.length == _nftContracts.length && _tokenIds.length > 0, "Token IDs and contract addresses length mismatch or empty bundle");

        // Transfer all NFTs in bundle to marketplace
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_nftContracts[i]).safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        _bundleIds.increment();
        uint256 bundleId = _bundleIds.current();

        nftBundles[bundleId] = NFTBundle({
            bundleId: bundleId,
            tokenIds: _tokenIds,
            nftContracts: _nftContracts,
            seller: msg.sender,
            bundlePrice: _bundlePrice,
            isActive: true
        });

        emit NFTBundleCreated(bundleId, msg.sender, _bundlePrice, _tokenIds, _nftContracts);
    }

    function purchaseNFTBundle(uint256 _bundleId) external payable onlyActiveBundle(_bundleId) whenNotPaused {
        NFTBundle storage bundle = nftBundles[_bundleId];
        require(msg.value >= bundle.bundlePrice, "Insufficient funds for bundle purchase");

        // Transfer all NFTs in bundle to buyer
        for (uint256 i = 0; i < bundle.tokenIds.length; i++) {
            IERC721(bundle.nftContracts[i]).safeTransferFrom(address(this), msg.sender, bundle.tokenIds[i]);
        }

        // Transfer bundle price to seller (minus royalty)
        uint256 royaltyAmount = (bundle.bundlePrice * royaltyPercentage) / 100;
        uint256 sellerAmount = bundle.bundlePrice - royaltyAmount;
        payable(bundle.seller).transfer(sellerAmount);
        payable(owner()).transfer(royaltyAmount);

        bundle.isActive = false;
        emit NFTBundlePurchased(_bundleId, msg.sender, bundle.bundlePrice);

        increaseUserReputation(bundle.seller); // Increase seller reputation
        increaseUserReputation(msg.sender); // Increase buyer reputation
    }

    function setRoyaltyPercentage(uint256 _percentage) external onlyOwner whenNotPaused {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_percentage);
    }

    function stakeForReputationBoost(uint256 _amount) external payable whenNotPaused {
        // Example: User stakes some ETH to temporarily boost reputation.
        // In a real application, you might use an ERC20 token for staking and more complex logic.
        require(msg.value == _amount, "Incorrect amount sent for staking");
        // For simplicity, just increase reputation directly based on stake amount in this example.
        uint256 reputationBoost = _amount / 1 ether; // Example: 1 reputation per 1 ETH staked
        userProfiles[msg.sender].reputation += reputationBoost;
        emit ReputationIncreased(_userAddress, userProfiles[msg.sender].reputation);
        // In a real application, you'd need to handle unstaking, time-based boost duration, etc.
    }

    // 6. Governance and Utility (Simple Examples)
    function voteOnParameterChange(string memory _parameterName, uint256 _newValue) external whenNotPaused {
        // Very basic governance example - just for demonstration.
        // In a real governance system, you'd have voting periods, token-weighted voting, etc.
        // For simplicity, here, any user can "vote" and the contract owner can decide to implement the change based on votes.
        // For demonstration, let's say we are voting to change the royalty percentage.
        if (keccak256(abi.encodePacked(_parameterName)) == keccak256(abi.encodePacked("royaltyPercentage"))) {
            // In a real system, you would track votes and implement logic for proposal acceptance based on voting results.
            // Here, just for example, let's say if the new value is significantly different, we log it.
            if (absDiff(royaltyPercentage, _newValue) > 2) { // Example: Significant change if > 2% difference.
                // In a real system, owner would review votes and then potentially call setRoyaltyPercentage if proposal passes.
                // For this example, we just log the potential change.
                emit RoyaltyPercentageSet(_newValue); // Log proposed change
            }
        }
        // More complex governance logic would be needed for real-world applications.
    }

    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function batchListNFTs(uint256[] memory _tokenIds, address[] memory _nftContracts, uint256[] memory _prices) external payable whenNotPaused {
        require(_tokenIds.length == _nftContracts.length && _tokenIds.length == _prices.length && _tokenIds.length > 0, "Input arrays length mismatch or empty");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            createListing(_tokenIds[i], _nftContracts[i], _prices[i]); // Reusing single listing function for batch
        }
    }

    function batchPurchaseNFTs(uint256[] memory _listingIds) external payable whenNotPaused {
        for (uint256 i = 0; i < _listingIds.length; i++) {
            purchaseNFT(_listingIds[i]); // Reusing single purchase function for batch
        }
    }

    function giftNFT(uint256 _listingId, address _recipient) external onlyActiveListing(_listingId) onlyListingSeller(_listingId) whenNotPaused {
        Listing storage listing = listings[_listingId];

        IERC721 nft = IERC721(listing.nftContract);
        // Transfer NFT directly to recipient (gift) - no funds transfer in this case.
        nft.safeTransferFrom(address(this), _recipient, listing.tokenId);

        listing.isActive = false; // Mark listing as inactive.
        emit NFTGifted(_listingId, msg.sender, _recipient);
    }


    // 7. Utility and Helper Functions (Basic Examples)
    function searchNFTs(string memory _searchTerm) public view returns (Listing[] memory) {
        // Very basic search - just checks if listing description (simplified) contains the search term.
        // Real search would be much more sophisticated (indexing, off-chain databases, etc.)
        uint256 resultCount = 0;
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                string memory listingDescription = string(abi.encodePacked("NFT ID: ", Strings.toString(listings[i].tokenId), " Contract: ", addressToString(listings[i].nftContract), " Seller: ", addressToString(listings[i].seller)));
                if (stringContains(listingDescription, _searchTerm)) {
                    resultCount++;
                }
            }
        }

        Listing[] memory searchResults = new Listing[](resultCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                string memory listingDescription = string(abi.encodePacked("NFT ID: ", Strings.toString(listings[i].tokenId), " Contract: ", addressToString(listings[i].nftContract), " Seller: ", addressToString(listings[i].seller)));
                if (stringContains(listingDescription, _searchTerm)) {
                    searchResults[index] = listings[i];
                    index++;
                }
            }
        }
        return searchResults;
    }

    function filterNFTsByTrait(string memory _traitName, string memory _traitValue) public view returns (Listing[] memory) {
        // Very basic filtering - assumes NFTs have traits encoded in their description (simplified).
        // Real filtering would require structured NFT metadata and potentially off-chain indexing.
        uint256 resultCount = 0;
        string memory filterCriteria = string(abi.encodePacked(_traitName, ": ", _traitValue));
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                string memory listingDescription = string(abi.encodePacked("NFT ID: ", Strings.toString(listings[i].tokenId), " Contract: ", addressToString(listings[i].nftContract), " Seller: ", addressToString(listings[i].seller), " Traits: ...")); // Example with "Traits: ..."
                if (stringContains(listingDescription, filterCriteria)) {
                    resultCount++;
                }
            }
        }

        Listing[] memory filteredResults = new Listing[](resultCount);
        uint256 index = 0;
        string memory criteria = string(abi.encodePacked(_traitName, ": ", _traitValue));
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                string memory listingDescription = string(abi.encodePacked("NFT ID: ", Strings.toString(listings[i].tokenId), " Contract: ", addressToString(listings[i].nftContract), " Seller: ", addressToString(listings[i].seller), " Traits: ..."));
                if (stringContains(listingDescription, criteria)) {
                    filteredResults[index] = listings[i];
                    index++;
                }
            }
        }
        return filteredResults;
    }

    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    // --- Internal helper functions ---

    function stringContains(string memory _string, string memory _substring) internal pure returns (bool) {
        return vm_stringContains(_string, _substring);
    }

    function addressToString(address _address) internal pure returns (string memory) {
        return vm_addrToString(_address);
    }

    function absDiff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    // --- Internal modifiers ---
    modifier onlyActiveBundle(uint256 _bundleId) {
        require(nftBundles[_bundleId].isActive, "Bundle is not active");
        _;
    }

    modifier validBundleNFTs(uint256[] memory _tokenIds, address[] memory _nftContracts) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721(_nftContracts[i]).ownerOf(_tokenIds[i]) == msg.sender, "Not owner of NFT in bundle");
        }
        _;
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
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

// --- Mock VM functions for string operations (for demonstration purposes in Solidity) ---
// In a real environment, you'd likely use off-chain solutions or more advanced string libraries if needed extensively.
function vm_stringContains(string memory _string, string memory _substring) pure returns (bool) {
    return keccak256(abi.encodePacked(_string)) == keccak256(abi.encodePacked(_substring)); // Very basic mock - replace with actual string search if needed.
}

function vm_addrToString(address _address) pure returns (string memory) {
    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
        uint8 byte = uint8(uint256(_address) / (2**(8*(19 - i))));
        uint8 low = uint8((byte << 4) >> 4);
        uint8 high = uint8(byte >> 4);
        str[2+i*2] = _SYMBOLS[high];
        str[3+i*2] = _SYMBOLS[low];
    }
    return string(str);
}
```