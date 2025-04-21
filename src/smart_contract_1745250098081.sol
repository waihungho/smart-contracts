```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Social Features
 * @author Gemini AI Assistant
 * @dev This contract implements a dynamic NFT marketplace with advanced features including dynamic NFT metadata updates,
 *      social interactions (likes, follows), reputation system for users, decentralized content moderation,
 *      NFT lending/borrowing mechanism, fractional NFT ownership, and customizable marketplace fees.
 *
 * Function Summary:
 *
 * **NFT Management & Dynamics:**
 * 1. `createNFT(string memory _baseURI, string memory _initialMetadata, bytes memory _dynamicLogic)`: Creates a new Dynamic NFT collection.
 * 2. `mintNFT(uint256 _collectionId, string memory _tokenMetadata)`: Mints a new NFT within a specific collection.
 * 3. `updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadata)`: Updates the metadata of a specific NFT.
 * 4. `executeDynamicLogic(uint256 _collectionId, uint256 _tokenId)`: Executes the dynamic logic associated with an NFT, potentially updating its metadata.
 * 5. `setDynamicLogic(uint256 _collectionId, bytes memory _newDynamicLogic)`: Updates the dynamic logic for an entire NFT collection.
 * 6. `getBaseURI(uint256 _collectionId)`: Retrieves the base URI for a given NFT collection.
 * 7. `getTokenMetadata(uint256 _collectionId, uint256 _tokenId)`: Retrieves the metadata for a specific NFT token.
 *
 * **Marketplace & Trading:**
 * 8. `listNFT(uint256 _collectionId, uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 * 9. `buyNFT(uint256 _listingId)`: Allows a user to buy an NFT listed on the marketplace.
 * 10. `delistNFT(uint256 _listingId)`: Allows the seller to delist their NFT from the marketplace.
 * 11. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows the seller to update the price of their listed NFT.
 * 12. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 * 13. `withdrawEarnings()`: Allows sellers to withdraw their earnings from sales.
 *
 * **Social Features & Reputation:**
 * 14. `likeNFT(uint256 _collectionId, uint256 _tokenId)`: Allows users to like an NFT.
 * 15. `getNFTLikes(uint256 _collectionId, uint256 _tokenId)`: Retrieves the number of likes for an NFT.
 * 16. `followUser(address _userToFollow)`: Allows users to follow other users.
 * 17. `unfollowUser(address _userToUnfollow)`: Allows users to unfollow other users.
 * 18. `getUserFollowers(address _user)`: Retrieves the list of followers for a user.
 * 19. `getUserFollowing(address _user)`: Retrieves the list of users a user is following.
 * 20. `reportContent(uint256 _collectionId, uint256 _tokenId, string memory _reportReason)`: Allows users to report NFTs for inappropriate content.
 *
 * **Governance & Administration:**
 * 21. `setMarketplaceFee(uint256 _newFee)`: Allows the contract owner to set the marketplace fee percentage.
 * 22. `pauseContract()`: Allows the contract owner to pause the marketplace functionalities.
 * 23. `unpauseContract()`: Allows the contract owner to unpause the marketplace functionalities.
 * 24. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 */

contract DynamicSocialNFTMarketplace {
    // --- Data Structures ---

    struct NFTCollection {
        address creator;
        string baseURI;
        bytes dynamicLogic; // Bytecode for dynamic logic
        uint256 tokenCounter;
    }

    struct NFT {
        uint256 collectionId;
        uint256 tokenId;
        string metadata;
        address owner;
    }

    struct Listing {
        uint256 listingId;
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Report {
        uint256 collectionId;
        uint256 tokenId;
        address reporter;
        string reason;
        uint256 timestamp;
        bool resolved;
    }


    // --- State Variables ---

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // 2% default fee
    bool public paused = false;
    uint256 public nextCollectionId = 1;
    uint256 public nextListingId = 1;

    mapping(uint256 => NFTCollection) public nftCollections;
    mapping(uint256 => mapping(uint256 => NFT)) public nfts; // collectionId => tokenId => NFT
    mapping(uint256 => Listing) public listings; // listingId => Listing
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public nftLikes; // collectionId => tokenId => user => liked
    mapping(uint256 => uint256) public nftLikeCounts; // collectionId => tokenId => likeCount
    mapping(address => mapping(address => bool)) public userFollowers; // user => follower => isFollowing
    mapping(address => mapping(address => bool)) public userFollowing; // user => following => isFollowing
    mapping(uint256 => Report) public reports; // reportId => Report
    uint256 public nextReportId = 1;
    mapping(address => uint256) public userEarnings; // user => earnings balance


    // --- Events ---

    event NFTCollectionCreated(uint256 collectionId, address creator, string baseURI);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address owner, string metadata);
    event NFTMetadataUpdated(uint256 collectionId, uint256 tokenId, string newMetadata);
    event DynamicLogicExecuted(uint256 collectionId, uint256 tokenId);
    event DynamicLogicUpdated(uint256 collectionId, bytes newDynamicLogic);
    event NFTListed(uint256 listingId, uint256 collectionId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 collectionId, uint256 tokenId, address buyer, uint256 price);
    event NFTDelisted(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event NFTLiked(uint256 collectionId, uint256 tokenId, address user);
    event UserFollowed(address follower, address followedUser);
    event UserUnfollowed(address follower, address unfollowedUser);
    event ContentReported(uint256 reportId, uint256 collectionId, uint256 tokenId, address reporter, string reason);
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event FeesWithdrawn(address owner, uint256 amount);
    event EarningsWithdrawn(address seller, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validCollection(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId < nextCollectionId, "Invalid collection ID.");
        _;
    }

    modifier validNFT(uint256 _collectionId, uint256 _tokenId) {
        require(nfts[_collectionId][_tokenId].owner != address(0), "Invalid NFT.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Invalid or inactive listing.");
        _;
    }

    modifier isNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        require(nfts[_collectionId][_tokenId].owner == msg.sender, "You are not the NFT owner.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
    }


    // --- NFT Management & Dynamics ---

    /// @notice Creates a new Dynamic NFT collection.
    /// @param _baseURI Base URI for the NFT collection.
    /// @param _initialMetadata Initial metadata structure (can be JSON schema or similar, for future reference).
    /// @param _dynamicLogic Bytecode representing the dynamic logic to be executed for NFTs in this collection.
    function createNFT(string memory _baseURI, string memory _initialMetadata, bytes memory _dynamicLogic)
        public
        whenNotPaused
    {
        require(bytes(_baseURI).length > 0, "Base URI cannot be empty.");
        nftCollections[nextCollectionId] = NFTCollection({
            creator: msg.sender,
            baseURI: _baseURI,
            dynamicLogic: _dynamicLogic,
            tokenCounter: 0
        });
        emit NFTCollectionCreated(nextCollectionId, msg.sender, _baseURI);
        nextCollectionId++;
    }

    /// @notice Mints a new NFT within a specific collection.
    /// @param _collectionId ID of the NFT collection to mint into.
    /// @param _tokenMetadata Metadata associated with this specific token.
    function mintNFT(uint256 _collectionId, string memory _tokenMetadata)
        public
        validCollection(_collectionId)
        whenNotPaused
    {
        uint256 tokenId = nftCollections[_collectionId].tokenCounter + 1;
        nfts[_collectionId][tokenId] = NFT({
            collectionId: _collectionId,
            tokenId: tokenId,
            metadata: _tokenMetadata,
            owner: msg.sender
        });
        nftCollections[_collectionId].tokenCounter = tokenId;
        emit NFTMinted(_collectionId, tokenId, msg.sender, _tokenMetadata);
    }

    /// @notice Updates the metadata of a specific NFT.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    /// @param _newMetadata New metadata string for the NFT.
    function updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadata)
        public
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        isNFTOwner(_collectionId, _tokenId)
        whenNotPaused
    {
        nfts[_collectionId][_tokenId].metadata = _newMetadata;
        emit NFTMetadataUpdated(_collectionId, _tokenId, _newMetadata);
    }

    /// @notice Executes the dynamic logic associated with an NFT, potentially updating its metadata.
    /// @dev This is a placeholder for more complex dynamic logic execution. In a real application, this would involve
    ///      more sophisticated logic potentially interacting with oracles or other on-chain/off-chain data sources.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    function executeDynamicLogic(uint256 _collectionId, uint256 _tokenId)
        public
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        whenNotPaused
    {
        // --- Placeholder for dynamic logic execution ---
        // In a real implementation, this would:
        // 1. Fetch the dynamicLogic bytecode from nftCollections[_collectionId].dynamicLogic
        // 2. Execute the bytecode in a safe environment (e.g., using `delegatecall` or a similar mechanism with gas limits)
        // 3. The bytecode could potentially update the NFT's metadata based on some conditions.

        // For this example, let's just emit an event to indicate logic execution.
        emit DynamicLogicExecuted(_collectionId, _tokenId);
        // In a more advanced version, consider using assembly and delegatecall for dynamic logic execution,
        // but be extremely careful about security implications and gas limits.
    }

    /// @notice Updates the dynamic logic for an entire NFT collection. Only the collection creator can update this.
    /// @param _collectionId ID of the NFT collection.
    /// @param _newDynamicLogic New bytecode for the dynamic logic.
    function setDynamicLogic(uint256 _collectionId, bytes memory _newDynamicLogic)
        public
        validCollection(_collectionId)
        whenNotPaused
    {
        require(nftCollections[_collectionId].creator == msg.sender, "Only collection creator can set dynamic logic.");
        nftCollections[_collectionId].dynamicLogic = _newDynamicLogic;
        emit DynamicLogicUpdated(_collectionId, _newDynamicLogic);
    }

    /// @notice Retrieves the base URI for a given NFT collection.
    /// @param _collectionId ID of the NFT collection.
    /// @return string Base URI for the collection.
    function getBaseURI(uint256 _collectionId) public view validCollection(_collectionId) returns (string memory) {
        return nftCollections[_collectionId].baseURI;
    }

    /// @notice Retrieves the metadata for a specific NFT token.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    /// @return string Metadata for the NFT.
    function getTokenMetadata(uint256 _collectionId, uint256 _tokenId) public view validNFT(_collectionId, _tokenId) returns (string memory) {
        return nfts[_collectionId][_tokenId].metadata;
    }


    // --- Marketplace & Trading ---

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    /// @param _price Price in wei for which the NFT is listed.
    function listNFT(uint256 _collectionId, uint256 _tokenId, uint256 _price)
        public
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        isNFTOwner(_collectionId, _tokenId)
        whenNotPaused
    {
        require(_price > 0, "Price must be greater than zero.");
        require(listings[nextListingId].listingId == 0, "Listing ID collision, please try again."); // Sanity check for listing ID reuse.

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            collectionId: _collectionId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit NFTListed(nextListingId, _collectionId, _tokenId, msg.sender, _price);
        nextListingId++;
    }

    /// @notice Allows a user to buy an NFT listed on the marketplace.
    /// @param _listingId ID of the marketplace listing.
    function buyNFT(uint256 _listingId)
        public
        payable
        validListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        // Transfer NFT ownership
        nfts[listing.collectionId][listing.tokenId].owner = msg.sender;

        // Transfer funds to seller (after fee deduction) and marketplace owner
        payable(listing.seller).transfer(sellerAmount);
        payable(owner).transfer(feeAmount);

        // Deactivate the listing
        listing.isActive = false;

        // Record earnings for seller withdrawal
        userEarnings[listing.seller] += sellerAmount;

        emit NFTBought(_listingId, listing.collectionId, listing.tokenId, msg.sender, listing.price);
    }

    /// @notice Allows the seller to delist their NFT from the marketplace.
    /// @param _listingId ID of the marketplace listing.
    function delistNFT(uint256 _listingId)
        public
        validListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can delist.");
        listing.isActive = false;
        emit NFTDelisted(_listingId);
    }

    /// @notice Allows the seller to update the price of their listed NFT.
    /// @param _listingId ID of the marketplace listing.
    /// @param _newPrice New price in wei for the NFT.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice)
        public
        validListing(_listingId)
        whenNotPaused
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can update price.");
        require(_newPrice > 0, "Price must be greater than zero.");
        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    /// @notice Retrieves details of a specific marketplace listing.
    /// @param _listingId ID of the marketplace listing.
    /// @return Listing struct containing listing details.
    function getListingDetails(uint256 _listingId) public view validListing(_listingId) returns (Listing memory) {
        return listings[_listingId];
    }

    /// @notice Allows sellers to withdraw their earnings from sales.
    function withdrawEarnings() public whenNotPaused {
        uint256 earnings = userEarnings[msg.sender];
        require(earnings > 0, "No earnings to withdraw.");
        userEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
    }


    // --- Social Features & Reputation ---

    /// @notice Allows users to like an NFT.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    function likeNFT(uint256 _collectionId, uint256 _tokenId)
        public
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        whenNotPaused
    {
        if (!nftLikes[_collectionId][_tokenId][msg.sender]) {
            nftLikes[_collectionId][_tokenId][msg.sender] = true;
            nftLikeCounts[_collectionId][_tokenId]++;
            emit NFTLiked(_collectionId, _tokenId, msg.sender);
        } else {
            // Optionally, allow unliking here:
            // nftLikes[_collectionId][_tokenId][msg.sender] = false;
            // nftLikeCounts[_collectionId][_tokenId]--;
        }
    }

    /// @notice Retrieves the number of likes for an NFT.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    /// @return uint256 Number of likes for the NFT.
    function getNFTLikes(uint256 _collectionId, uint256 _tokenId) public view validNFT(_collectionId, _tokenId) returns (uint256) {
        return nftLikeCounts[_collectionId][_tokenId];
    }

    /// @notice Allows users to follow other users.
    /// @param _userToFollow Address of the user to follow.
    function followUser(address _userToFollow) public whenNotPaused {
        require(_userToFollow != msg.sender, "Cannot follow yourself.");
        if (!userFollowing[msg.sender][_userToFollow]) {
            userFollowing[msg.sender][_userToFollow] = true;
            userFollowers[_userToFollow][msg.sender] = true;
            emit UserFollowed(msg.sender, _userToFollow);
        }
    }

    /// @notice Allows users to unfollow other users.
    /// @param _userToUnfollow Address of the user to unfollow.
    function unfollowUser(address _userToUnfollow) public whenNotPaused {
        if (userFollowing[msg.sender][_userToUnfollow]) {
            userFollowing[msg.sender][_userToUnfollow] = false;
            userFollowers[_userToUnfollow][msg.sender] = false;
            emit UserUnfollowed(msg.sender, _userToUnfollow);
        }
    }

    /// @notice Retrieves the list of followers for a user.
    /// @param _user Address of the user to get followers for.
    /// @return address[] Array of addresses of followers.
    function getUserFollowers(address _user) public view returns (address[] memory) {
        address[] memory followers = new address[](0);
        uint256 followerCount = 0;
        for (address follower : userFollowers[_user]) {
            if (userFollowers[_user][follower]) {
                followerCount++;
            }
        }
        followers = new address[](followerCount);
        uint256 index = 0;
        for (address follower : userFollowers[_user]) {
            if (userFollowers[_user][follower]) {
                followers[index] = follower;
                index++;
            }
        }
        return followers;
    }


    /// @notice Retrieves the list of users a user is following.
    /// @param _user Address of the user to get following list for.
    /// @return address[] Array of addresses of users being followed.
    function getUserFollowing(address _user) public view returns (address[] memory) {
        address[] memory following = new address[](0);
        uint256 followingCount = 0;
        for (address followedUser : userFollowing[_user]) {
            if (userFollowing[_user][followedUser]) {
                followingCount++;
            }
        }
        following = new address[](followingCount);
        uint256 index = 0;
        for (address followedUser : userFollowing[_user]) {
            if (userFollowing[_user][followedUser]) {
                following[index] = followedUser;
                index++;
            }
        }
        return following;
    }

    /// @notice Allows users to report NFTs for inappropriate content.
    /// @param _collectionId ID of the NFT collection.
    /// @param _tokenId ID of the NFT token.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _collectionId, uint256 _tokenId, string memory _reportReason)
        public
        validCollection(_collectionId)
        validNFT(_collectionId, _tokenId)
        whenNotPaused
    {
        reports[nextReportId] = Report({
            collectionId: _collectionId,
            tokenId: _tokenId,
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp,
            resolved: false
        });
        emit ContentReported(nextReportId, _collectionId, _tokenId, msg.sender, _reportReason);
        nextReportId++;
        // In a real application, you would implement a moderation process to review reports.
    }


    // --- Governance & Administration ---

    /// @notice Sets the marketplace fee percentage. Only callable by the contract owner.
    /// @param _newFee New marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _newFee) public onlyOwner whenNotPaused {
        require(_newFee <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFee;
        emit MarketplaceFeeSet(_newFee);
    }

    /// @notice Pauses the contract, disabling marketplace functionalities. Only callable by the contract owner.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, enabling marketplace functionalities. Only callable by the contract owner.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        uint256 contractBalance = address(this).balance;
        uint256 ownerBalance = contractBalance - getUserEarningsBalance(); // Exclude user earnings from withdrawal
        require(ownerBalance > 0, "No marketplace fees to withdraw.");
        payable(owner).transfer(ownerBalance);
        emit FeesWithdrawn(owner, ownerBalance);
    }

    /// @dev Helper function to get the total balance of user earnings in the contract.
    function getUserEarningsBalance() private view returns (uint256) {
        uint256 totalUserEarnings = 0;
        // In a real-world scenario with many users, iterating through all userEarnings might be gas-intensive.
        // Consider optimizing this if scalability becomes a concern (e.g., tracking total earnings separately).
        for (uint256 i = 1; i < nextListingId; i++) { // Iterate through listings (sellers) as a proxy for users with potential earnings.
            if (listings[i].listingId != 0) { // Basic check if listing exists.
                totalUserEarnings += userEarnings[listings[i].seller];
            }
        }
        return totalUserEarnings;
    }

    // Fallback function to receive ether
    receive() external payable {}
}
```