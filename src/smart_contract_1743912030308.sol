```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Social Features - "EvoNFT Market"
 * @author Bard (Example - Not for Production)
 * @dev This contract implements a dynamic NFT marketplace with social features, allowing for evolving NFTs and community interaction.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Functionality:**
 *  1. `mintDynamicNFT(string memory _baseURI, string memory _initialMetadata, string memory _dynamicAttributeName)`: Mints a new Dynamic NFT, setting a base URI, initial metadata, and a name for a dynamic attribute that can be updated.
 *  2. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *  3. `getNFTOwner(uint256 _tokenId)`: Returns the owner of a specific NFT.
 *  4. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for an NFT.
 *  5. `updateDynamicNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata of a Dynamic NFT, potentially based on external factors or owner actions (dynamic aspect).
 *  6. `burnNFT(uint256 _tokenId)`: Allows the NFT owner to burn (destroy) their NFT.
 *  7. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support check.
 *
 * **Marketplace Functionality:**
 *  8. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owner to list their NFT for sale at a specified price.
 *  9. `buyNFT(uint256 _tokenId)`: Allows anyone to purchase a listed NFT.
 * 10. `cancelNFTListing(uint256 _tokenId)`: Allows the NFT owner to cancel an active listing.
 * 11. `updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice)`: Allows the NFT owner to update the price of a listed NFT.
 * 12. `getNFTListingDetails(uint256 _tokenId)`: Retrieves details of an NFT listing (price, seller, status).
 * 13. `withdrawMarketplaceBalance()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *
 * **Social and Community Features:**
 * 14. `createUserProfile(string memory _username, string memory _profileDescription)`: Allows users to create a public profile with a username and description.
 * 15. `updateUserProfileDescription(string memory _newDescription)`: Allows users to update their profile description.
 * 16. `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 * 17. `likeNFT(uint256 _tokenId)`: Allows users to "like" an NFT.
 * 18. `getNFTLikesCount(uint256 _tokenId)`: Returns the number of likes an NFT has received.
 * 19. `followUser(address _userToFollow)`: Allows users to follow other users.
 * 20. `getFollowerCount(address _userAddress)`: Returns the number of followers a user has.
 * 21. `isFollowing(address _follower, address _followed)`: Checks if a user is following another user.
 *
 * **Governance/Utility Features:**
 * 22. `setMarketplaceFee(uint256 _newFeePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 23. `getMarketplaceFee()`: Returns the current marketplace fee percentage.
 * 24. `pauseMarketplace()`: Allows the contract owner to pause marketplace functionalities (listing, buying).
 * 25. `unpauseMarketplace()`: Allows the contract owner to unpause marketplace functionalities.
 */

contract EvoNFTMarket {
    string public name = "EvoNFT";
    string public symbol = "EVNFT";

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public isMarketplacePaused = false;

    // NFT Data
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftMetadataURIs;
    uint256 public nextTokenId = 1;

    // Marketplace Listings
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;

    // User Profiles
    struct UserProfile {
        string username;
        string description;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;

    // NFT Likes
    mapping(uint256 => uint256) public nftLikesCount;
    mapping(uint256 => mapping(address => bool)) public userLikedNFT; // To prevent multiple likes from same user

    // User Following
    mapping(address => mapping(address => bool)) public userFollowing; // follower => followed
    mapping(address => uint256) public followerCount;

    // Events
    event NFTMinted(uint256 tokenId, address owner, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTBurned(uint256 tokenId, address owner);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event NFTListingPriceUpdated(uint256 tokenId, uint256 newPrice);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newDescription);
    event NFTLiked(uint256 tokenId, address user);
    event UserFollowed(address follower, address followed);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceBalanceWithdrawn(address owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenMarketplaceNotPaused() {
        require(!isMarketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier whenMarketplacePaused() {
        require(isMarketplacePaused, "Marketplace is not paused.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ------------------------ Core NFT Functionality ------------------------

    /**
     * @dev Mints a new Dynamic NFT.
     * @param _baseURI Base URI for the NFT metadata.
     * @param _initialMetadata Initial metadata for the NFT.
     * @param _dynamicAttributeName Name of the attribute that can be dynamically updated in metadata.
     */
    function mintDynamicNFT(string memory _baseURI, string memory _initialMetadata, string memory _dynamicAttributeName) public returns (uint256) {
        uint256 tokenId = nextTokenId++;
        nftOwner[tokenId] = msg.sender;
        nftMetadataURIs[tokenId] = string(abi.encodePacked(_baseURI, _initialMetadata)); // Example: Combine base URI and initial metadata
        emit NFTMinted(tokenId, msg.sender, nftMetadataURIs[tokenId]);
        return tokenId;
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _to Address to transfer the NFT to.
     * @param _tokenId ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Transfer address cannot be zero address.");
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /**
     * @dev Gets the owner of an NFT.
     * @param _tokenId ID of the NFT.
     * @return Address of the NFT owner.
     */
    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        return nftOwner[_tokenId];
    }

    /**
     * @dev Gets the metadata URI of an NFT.
     * @param _tokenId ID of the NFT.
     * @return Metadata URI of the NFT.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        return nftMetadataURIs[_tokenId];
    }

    /**
     * @dev Updates the metadata of a Dynamic NFT. Can be used to reflect changes in the NFT's state.
     * @param _tokenId ID of the NFT to update.
     * @param _newMetadata New metadata URI for the NFT.
     */
    function updateDynamicNFTMetadata(uint256 _tokenId, string memory _newMetadata) public onlyNFTOwner(_tokenId) {
        nftMetadataURIs[_tokenId] = _newMetadata;
        emit NFTMetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @dev Burns (destroys) an NFT.
     * @param _tokenId ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        delete nftOwner[_tokenId];
        delete nftMetadataURIs[_tokenId];
        delete nftListings[_tokenId]; // Remove from marketplace if listed
        emit NFTBurned(_tokenId, msg.sender);
    }

    /**
     * @dev ERC165 interface support.
     * @param interfaceId Interface ID to check.
     * @return True if interface is supported.
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165.
               interfaceId == 0x80ac58cd;   // ERC165 Interface ID for ERC721Metadata.
    }

    // ------------------------ Marketplace Functionality ------------------------

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId ID of the NFT to list.
     * @param _price Price in wei for the NFT.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(nftListings[_tokenId].isActive == false, "NFT is already listed for sale.");
        require(_price > 0, "Price must be greater than zero.");

        nftListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    /**
     * @dev Buys a listed NFT.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable whenMarketplaceNotPaused {
        require(nftListings[_tokenId].isActive == true, "NFT is not listed for sale.");
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        nftOwner[_tokenId] = msg.sender;
        listing.isActive = false;
        payable(listing.seller).transfer(sellerProceeds);
        payable(owner).transfer(marketplaceFee); // Marketplace fee goes to contract owner
        emit NFTBought(_tokenId, msg.sender, listing.seller, listing.price);
        emit NFTTransferred(_tokenId, listing.seller, msg.sender); // Emit transfer event as well
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _tokenId ID of the NFT listing to cancel.
     */
    function cancelNFTListing(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        require(nftListings[_tokenId].isActive == true, "NFT is not listed for sale.");
        nftListings[_tokenId].isActive = false;
        emit NFTListingCancelled(_tokenId, msg.sender);
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _tokenId ID of the NFT listing to update.
     * @param _newPrice New price for the NFT.
     */
    function updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice) public onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        require(nftListings[_tokenId].isActive == true, "NFT is not listed for sale.");
        require(_newPrice > 0, "Price must be greater than zero.");
        nftListings[_tokenId].price = _newPrice;
        emit NFTListingPriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @dev Gets details of an NFT listing.
     * @param _tokenId ID of the NFT listing.
     * @return Listing details (seller, price, isActive).
     */
    function getNFTListingDetails(uint256 _tokenId) public view returns (address seller, uint256 price, bool isActive) {
        Listing storage listing = nftListings[_tokenId];
        return (listing.seller, listing.price, listing.isActive);
    }

    /**
     * @dev Allows the contract owner to withdraw marketplace balance (fees collected).
     */
    function withdrawMarketplaceBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit MarketplaceBalanceWithdrawn(owner, balance);
    }


    // ------------------------ Social and Community Features ------------------------

    /**
     * @dev Creates a user profile.
     * @param _username Username for the profile.
     * @param _profileDescription Description for the profile.
     */
    function createUserProfile(string memory _username, string memory _profileDescription) public {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            description: _profileDescription,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /**
     * @dev Updates the description of a user profile.
     * @param _newDescription New profile description.
     */
    function updateUserProfileDescription(string memory _newDescription) public {
        require(userProfiles[msg.sender].exists, "Profile does not exist. Create one first.");
        userProfiles[msg.sender].description = _newDescription;
        emit UserProfileUpdated(msg.sender, _newDescription);
    }

    /**
     * @dev Gets a user's profile information.
     * @param _userAddress Address of the user.
     * @return Username and description of the user profile.
     */
    function getUserProfile(address _userAddress) public view returns (string memory username, string memory description, bool exists) {
        UserProfile storage profile = userProfiles[_userAddress];
        return (profile.username, profile.description, profile.exists);
    }

    /**
     * @dev Allows a user to "like" an NFT.
     * @param _tokenId ID of the NFT to like.
     */
    function likeNFT(uint256 _tokenId) public {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        require(!userLikedNFT[_tokenId][msg.sender], "You have already liked this NFT.");

        nftLikesCount[_tokenId]++;
        userLikedNFT[_tokenId][msg.sender] = true;
        emit NFTLiked(_tokenId, msg.sender);
    }

    /**
     * @dev Gets the number of likes an NFT has received.
     * @param _tokenId ID of the NFT.
     * @return Number of likes for the NFT.
     */
    function getNFTLikesCount(uint256 _tokenId) public view returns (uint256) {
        return nftLikesCount[_tokenId];
    }

    /**
     * @dev Allows a user to follow another user.
     * @param _userToFollow Address of the user to follow.
     */
    function followUser(address _userToFollow) public {
        require(_userToFollow != msg.sender, "You cannot follow yourself.");
        require(!userFollowing[msg.sender][_userToFollow], "You are already following this user.");

        userFollowing[msg.sender][_userToFollow] = true;
        followerCount[_userToFollow]++;
        emit UserFollowed(msg.sender, _userToFollow);
    }

    /**
     * @dev Gets the number of followers a user has.
     * @param _userAddress Address of the user.
     * @return Number of followers for the user.
     */
    function getFollowerCount(address _userAddress) public view returns (uint256) {
        return followerCount[_userAddress];
    }

    /**
     * @dev Checks if a user is following another user.
     * @param _follower Address of the follower.
     * @param _followed Address of the followed user.
     * @return True if follower is following followed.
     */
    function isFollowing(address _follower, address _followed) public view returns (bool) {
        return userFollowing[_follower][_followed];
    }


    // ------------------------ Governance/Utility Features ------------------------

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _newFeePercentage New fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeSet(_newFeePercentage);
    }

    /**
     * @dev Gets the current marketplace fee percentage.
     * @return Current marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /**
     * @dev Pauses marketplace functionalities (listing, buying). Only callable by the contract owner.
     */
    function pauseMarketplace() public onlyOwner whenMarketplaceNotPaused {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses marketplace functionalities. Only callable by the contract owner.
     */
    function unpauseMarketplace() public onlyOwner whenMarketplacePaused {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }
}
```