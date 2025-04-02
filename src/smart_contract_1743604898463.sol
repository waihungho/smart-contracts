```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Social NFT Marketplace with Evolving Traits & Decentralized Reputation
 * @author Gemini AI Assistant
 * @dev This smart contract implements a dynamic NFT marketplace with social features and evolving NFT traits.
 * It incorporates a decentralized reputation system based on user interactions and NFT ownership.
 *
 * **Outline and Function Summary:**
 *
 * **Core Marketplace Functions:**
 * 1.  `listNFT(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale.
 * 2.  `buyNFT(uint256 _listingId)`: Allows users to purchase listed NFTs.
 * 3.  `cancelListing(uint256 _listingId)`: Allows NFT owners to cancel their listings.
 * 4.  `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows NFT owners to update the price of their listed NFTs.
 * 5.  `getListing(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 * 6.  `getAllListings()`: Retrieves a list of all active NFT listings.
 *
 * **Dynamic NFT Trait Evolution Functions:**
 * 7.  `evolveNFTTrait(uint256 _tokenId, string memory _traitName)`: Allows NFT owners to trigger evolution of a specific NFT trait based on predefined conditions.
 * 8.  `setTraitEvolutionCondition(string memory _traitName, string memory _conditionLogic)`: Contract owner function to set the evolution condition for a specific NFT trait.
 * 9.  `getNFTTraits(uint256 _tokenId)`: Retrieves the current traits and their values for a given NFT.
 *
 * **Social Interaction & Reputation Functions:**
 * 10. `createUserProfile(string memory _username, string memory _bio)`: Allows users to create a public profile.
 * 11. `updateUserProfile(string memory _bio)`: Allows users to update their profile bio.
 * 12. `getUserProfile(address _userAddress)`: Retrieves the profile information of a user.
 * 13. `followUser(address _targetUser)`: Allows users to follow other users.
 * 14. `unfollowUser(address _targetUser)`: Allows users to unfollow other users.
 * 15. `getFollowersCount(address _userAddress)`: Retrieves the number of followers for a user.
 * 16. `getFollowingCount(address _userAddress)`: Retrieves the number of users a user is following.
 * 17. `likeNFT(uint256 _tokenId)`: Allows users to like an NFT, contributing to its social score.
 * 18. `getNFTLikes(uint256 _tokenId)`: Retrieves the number of likes an NFT has received.
 * 19. `reportNFT(uint256 _tokenId, string memory _reason)`: Allows users to report an NFT for inappropriate content (governance may be needed to act on reports).
 *
 * **Governance & Utility Functions:**
 * 20. `setMarketplaceFee(uint256 _feePercentage)`: Contract owner function to set the marketplace fee percentage.
 * 21. `withdrawMarketplaceFees()`: Contract owner function to withdraw accumulated marketplace fees.
 * 22. `pauseMarketplace()`: Contract owner function to temporarily pause marketplace operations.
 * 23. `unpauseMarketplace()`: Contract owner function to resume marketplace operations.
 */

contract DynamicSocialNFTMarketplace {

    // --- State Variables ---

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public paused = false;

    // NFT Contract Address (Assuming ERC721) - Replace with your actual NFT contract
    address public nftContractAddress;

    // Struct to represent NFT listing details
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    // Struct to represent user profiles
    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }

    // Struct to define NFT trait evolution conditions (simplified for example)
    struct TraitEvolutionCondition {
        string conditionLogic; // Placeholder for condition logic (e.g., "likes > 100", "time > 7 days") - In real world, more complex logic
    }

    // Mapping from listing ID to Listing struct
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter = 0;

    // Mapping from listing ID to if it exists (for efficient checks)
    mapping(uint256 => bool) public listingExists;

    // Mapping from NFT token ID to its current traits (example: trait name -> trait value)
    mapping(uint256 => mapping(string => string)) public nftTraits;

    // Mapping from trait name to its evolution condition
    mapping(string => TraitEvolutionCondition) public traitEvolutionConditions;

    // Mapping from user address to UserProfile struct
    mapping(address => UserProfile) public userProfiles;

    // Mapping from user address to set of users they are following
    mapping(address => mapping(address => bool)) public following;

    // Mapping from user address to set of users who are following them
    mapping(address => mapping(address => bool)) public followers;

    // Mapping from NFT token ID to set of users who liked it
    mapping(uint256 => mapping(address => bool)) public nftLikes;

    // Events to log important actions
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, address seller, uint256 newPrice);
    event NFTTraitEvolved(uint256 tokenId, string traitName, string newValue);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress);
    event UserFollowed(address follower, address followed);
    event UserUnfollowed(address follower, address unfollowed);
    event NFTLiked(uint256 tokenId, address user);
    event NFTReported(uint256 tokenId, address reporter, string reason);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event FeesWithdrawn(address owner, uint256 amount);


    // --- Modifiers ---

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

    modifier listingExistsAndActive(uint256 _listingId) {
        require(listingExists[_listingId], "Listing does not exist.");
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        // Assuming standard ERC721 `ownerOf` function
        address currentOwner = IERC721(nftContractAddress).ownerOf(_tokenId);
        require(currentOwner == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier isApprovedOrOwner(uint256 _tokenId) {
        // Assuming standard ERC721 `getApproved` and `isApprovedForAll` functions
        address currentOwner = IERC721(nftContractAddress).ownerOf(_tokenId);
        address approvedAddress = IERC721(nftContractAddress).getApproved(_tokenId);
        bool isApprovedForAll = IERC721(nftContractAddress).isApprovedForAll(currentOwner, msg.sender);
        require(msg.sender == currentOwner || msg.sender == approvedAddress || isApprovedForAll, "Not approved to operate on this NFT.");
        _;
    }

    // --- Constructor ---
    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
    }

    // --- Core Marketplace Functions ---

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT token to list.
    /// @param _price The desired price of the NFT in wei.
    function listNFT(uint256 _tokenId, uint256 _price)
        external
        whenNotPaused
        isNFTOwner(_tokenId)
        isApprovedOrOwner(_tokenId) // Ensure marketplace is approved to transfer
    {
        require(_price > 0, "Price must be greater than zero.");

        listingCounter++;
        listings[listingCounter] = Listing({
            listingId: listingCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        listingExists[listingCounter] = true;

        // Transfer NFT to this contract as escrow (standard marketplace practice)
        IERC721(nftContractAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NFTListed(listingCounter, _tokenId, msg.sender, _price);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// @param _listingId The ID of the NFT listing to purchase.
    function buyNFT(uint256 _listingId)
        external
        payable
        whenNotPaused
        listingExistsAndActive(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent.");

        // Transfer funds to seller (minus marketplace fee)
        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;
        payable(listing.seller).transfer(sellerPayout);

        // Transfer marketplace fee to contract owner
        payable(owner).transfer(marketplaceFee);

        // Transfer NFT to buyer
        IERC721(nftContractAddress).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        // Mark listing as inactive
        listing.isActive = false;

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.seller, listing.price);
    }

    /// @notice Allows the NFT owner to cancel a listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId)
        external
        whenNotPaused
        listingExistsAndActive(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can cancel listing.");

        // Return NFT to seller
        IERC721(nftContractAddress).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        // Mark listing as inactive
        listing.isActive = false;

        emit ListingCancelled(_listingId, listing.tokenId, msg.sender);
    }

    /// @notice Allows the NFT owner to update the price of a listing.
    /// @param _listingId The ID of the listing to update.
    /// @param _newPrice The new price for the NFT.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice)
        external
        whenNotPaused
        listingExistsAndActive(_listingId)
    {
        require(_newPrice > 0, "New price must be greater than zero.");
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can update listing price.");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, listing.tokenId, msg.sender, _newPrice);
    }

    /// @notice Retrieves details of a specific NFT listing.
    /// @param _listingId The ID of the listing.
    /// @return Listing struct containing listing details.
    function getListing(uint256 _listingId)
        external
        view
        listingExists(_listingId)
        returns (Listing memory)
    {
        return listings[_listingId];
    }

    /// @notice Retrieves a list of all active NFT listings.
    /// @return An array of Listing structs representing active listings.
    function getAllListings()
        external
        view
        returns (Listing[] memory)
    {
        Listing[] memory activeListings = new Listing[](listingCounter); // Max size, can be optimized
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listingExists[i] && listings[i].isActive) {
                activeListings[count] = listings[i];
                count++;
            }
        }

        // Resize the array to the actual number of active listings
        Listing[] memory result = new Listing[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeListings[i];
        }
        return result;
    }


    // --- Dynamic NFT Trait Evolution Functions ---

    /// @notice Allows NFT owners to trigger evolution of a specific NFT trait.
    /// @dev This is a simplified example. In a real application, the evolution logic would be more complex and potentially automated.
    /// @param _tokenId The ID of the NFT token to evolve.
    /// @param _traitName The name of the trait to evolve.
    function evolveNFTTrait(uint256 _tokenId, string memory _traitName)
        external
        isNFTOwner(_tokenId)
        whenNotPaused
    {
        require(traitEvolutionConditions[_traitName].conditionLogic.length > 0, "No evolution condition set for this trait.");
        // In a real implementation, you would evaluate the `traitEvolutionConditions[_traitName].conditionLogic` here.
        // For this example, we'll just implement a simple evolution: increment a numeric trait or change a string trait.

        string memory currentTraitValue = nftTraits[_tokenId][_traitName];

        // Example simple evolution logic (can be significantly more sophisticated)
        if (isNumeric(currentTraitValue)) {
            uint256 numericValue = parseInt(currentTraitValue);
            numericValue++;
            nftTraits[_tokenId][_traitName] = uint2str(numericValue);
            emit NFTTraitEvolved(_tokenId, _traitName, uint2str(numericValue));
        } else {
            // Example string trait evolution (change to a predefined next level)
            if (keccak256(bytes(currentTraitValue)) == keccak256(bytes("Basic"))) {
                nftTraits[_tokenId][_traitName] = "Advanced";
                emit NFTTraitEvolved(_tokenId, _traitName, "Advanced");
            } else if (keccak256(bytes(currentTraitValue)) == keccak256(bytes("Advanced"))) {
                nftTraits[_tokenId][_traitName] = "Elite";
                emit NFTTraitEvolved(_tokenId, _traitName, "Elite");
            }
            // ... more levels or different string evolution logic can be added
        }
    }

    /// @notice Allows the contract owner to set the evolution condition for a specific NFT trait.
    /// @dev In a real application, `_conditionLogic` would be a more structured format or a reference to an oracle/external data source.
    /// @param _traitName The name of the trait to set the condition for.
    /// @param _conditionLogic A string representing the condition logic (e.g., "likes > 100", "time > 7 days").
    function setTraitEvolutionCondition(string memory _traitName, string memory _conditionLogic)
        external
        onlyOwner
    {
        traitEvolutionConditions[_traitName] = TraitEvolutionCondition({
            conditionLogic: _conditionLogic
        });
    }

    /// @notice Retrieves the current traits and their values for a given NFT.
    /// @param _tokenId The ID of the NFT token.
    /// @return A mapping of trait names to their current values.
    function getNFTTraits(uint256 _tokenId)
        external
        view
        returns (mapping(string => string) memory)
    {
        return nftTraits[_tokenId];
    }


    // --- Social Interaction & Reputation Functions ---

    /// @notice Allows a user to create a public profile.
    /// @param _username The desired username.
    /// @param _bio A short bio for the user.
    function createUserProfile(string memory _username, string memory _bio)
        external
        whenNotPaused
    {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be 1-32 characters long.");
        require(bytes(_bio).length <= 256, "Bio must be max 256 characters long.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Allows a user to update their profile bio.
    /// @param _bio The new bio for the user.
    function updateUserProfile(string memory _bio)
        external
        whenNotPaused
    {
        require(userProfiles[msg.sender].exists, "Profile does not exist. Create one first.");
        require(bytes(_bio).length <= 256, "Bio must be max 256 characters long.");

        userProfiles[msg.sender].bio = _bio;
        emit UserProfileUpdated(msg.sender);
    }

    /// @notice Retrieves the profile information of a user.
    /// @param _userAddress The address of the user.
    /// @return UserProfile struct containing user profile details.
    function getUserProfile(address _userAddress)
        external
        view
        returns (UserProfile memory)
    {
        return userProfiles[_userAddress];
    }

    /// @notice Allows a user to follow another user.
    /// @param _targetUser The address of the user to follow.
    function followUser(address _targetUser)
        external
        whenNotPaused
    {
        require(_targetUser != msg.sender, "Cannot follow yourself.");
        require(userProfiles[_targetUser].exists, "Target user profile does not exist.");
        require(!following[msg.sender][_targetUser], "Already following this user.");

        following[msg.sender][_targetUser] = true;
        followers[_targetUser][msg.sender] = true;
        emit UserFollowed(msg.sender, _targetUser);
    }

    /// @notice Allows a user to unfollow another user.
    /// @param _targetUser The address of the user to unfollow.
    function unfollowUser(address _targetUser)
        external
        whenNotPaused
    {
        require(following[msg.sender][_targetUser], "Not following this user.");

        following[msg.sender][_targetUser] = false;
        followers[_targetUser][msg.sender] = false;
        emit UserUnfollowed(msg.sender, _targetUser);
    }

    /// @notice Retrieves the number of followers for a user.
    /// @param _userAddress The address of the user.
    /// @return The number of followers.
    function getFollowersCount(address _userAddress)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (address followerAddress : getFollowers(_userAddress)) {
            if (followers[_userAddress][followerAddress]) { // Double check for consistency
                count++;
            }
        }
        return count;
    }

    /// @notice Retrieves the number of users a user is following.
    /// @param _userAddress The address of the user.
    /// @return The number of users being followed.
    function getFollowingCount(address _userAddress)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (address followingAddress : getFollowing(_userAddress)) {
            if (following[_userAddress][followingAddress]) { // Double check for consistency
                count++;
            }
        }
        return count;
    }

    /// @notice Allows a user to like an NFT.
    /// @param _tokenId The ID of the NFT token to like.
    function likeNFT(uint256 _tokenId)
        external
        whenNotPaused
    {
        require(!nftLikes[_tokenId][msg.sender], "Already liked this NFT.");

        nftLikes[_tokenId][msg.sender] = true;
        emit NFTLiked(_tokenId, msg.sender);
    }

    /// @notice Retrieves the number of likes an NFT has received.
    /// @param _tokenId The ID of the NFT token.
    /// @return The number of likes.
    function getNFTLikes(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (address likerAddress : getNFTLikers(_tokenId)) {
            if (nftLikes[_tokenId][likerAddress]) { // Double check for consistency
                count++;
            }
        }
        return count;
    }

    /// @notice Allows users to report an NFT for inappropriate content.
    /// @dev In a real application, governance mechanisms would be needed to review and act on reports.
    /// @param _tokenId The ID of the NFT token to report.
    /// @param _reason The reason for reporting.
    function reportNFT(uint256 _tokenId, string memory _reason)
        external
        whenNotPaused
    {
        // In a real application, you might store reports and implement a governance/moderation system.
        // For this example, we just emit an event.
        emit NFTReported(_tokenId, msg.sender, _reason);
    }


    // --- Governance & Utility Functions ---

    /// @notice Allows the contract owner to set the marketplace fee percentage.
    /// @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage)
        external
        onlyOwner
    {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees()
        external
        onlyOwner
    {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FeesWithdrawn(owner, balance);
    }

    /// @notice Allows the contract owner to pause the marketplace.
    function pauseMarketplace()
        external
        onlyOwner
        whenNotPaused
    {
        paused = true;
        emit MarketplacePaused();
    }

    /// @notice Allows the contract owner to unpause the marketplace.
    function unpauseMarketplace()
        external
        onlyOwner
        whenPaused
    {
        paused = false;
        emit MarketplaceUnpaused();
    }


    // --- Helper Functions (Internal & Private) ---

    /// @dev Helper function to convert uint256 to string
    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        str = string(bstr);
    }

    /// @dev Helper function to parse string to uint256 (basic, for numeric trait evolution example)
    function parseInt(string memory _str) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory strBytes = bytes(_str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]) - 48; // ASCII '0' is 48
            if (digit < 0 || digit > 9) {
                return 0; // Or handle error differently if needed
            }
            result = result * 10 + digit;
        }
        return result;
    }

    /// @dev Helper function to check if a string is numeric (basic check)
    function isNumeric(string memory _str) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        if (strBytes.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]) - 48;
            if (digit < 0 || digit > 9) {
                return false;
            }
        }
        return true;
    }

    /// @dev Internal function to get followers of a user (returns array of addresses)
    function getFollowers(address _userAddress) internal view returns (address[] memory) {
        address[] memory followersList = new address[](getFollowersCount(_userAddress));
        uint256 index = 0;
        for (uint256 i = 0; i < listingCounter; i++) { // Iterate through listings as a proxy for users (inefficient in real app)
            if (listingExists[i] && listings[i].seller != address(0) && followers[_userAddress][listings[i].seller]) {
                followersList[index] = listings[i].seller; // Reusing seller address for example, need to iterate users properly in real app
                index++;
            }
        }
        uint256 actualCount = 0;
        for (uint256 i = 0; i < followersList.length; i++) {
            if (followersList[i] != address(0)) {
                actualCount++;
            }
        }
        address[] memory trimmedFollowersList = new address[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            trimmedFollowersList[i] = followersList[i];
        }
        return trimmedFollowersList;
    }


    /// @dev Internal function to get users a user is following (returns array of addresses)
    function getFollowing(address _userAddress) internal view returns (address[] memory) {
         address[] memory followingList = new address[](getFollowingCount(_userAddress));
        uint256 index = 0;
        for (uint256 i = 0; i < listingCounter; i++) { // Iterate through listings as a proxy for users (inefficient in real app)
            if (listingExists[i] && listings[i].seller != address(0) && following[_userAddress][listings[i].seller]) {
                followingList[index] = listings[i].seller; // Reusing seller address for example, need to iterate users properly in real app
                index++;
            }
        }
        uint256 actualCount = 0;
        for (uint256 i = 0; i < followingList.length; i++) {
            if (followingList[i] != address(0)) {
                actualCount++;
            }
        }
        address[] memory trimmedFollowingList = new address[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            trimmedFollowingList[i] = followingList[i];
        }
        return trimmedFollowingList;
    }

    /// @dev Internal function to get likers of an NFT (returns array of addresses)
    function getNFTLikers(uint256 _tokenId) internal view returns (address[] memory) {
        address[] memory likersList = new address[](getNFTLikes(_tokenId)); // Max size, can be optimized
        uint256 index = 0;
        for (uint256 i = 0; i < listingCounter; i++) { // Iterate through listings as a proxy for users (inefficient in real app)
            if (listingExists[i] && listings[i].seller != address(0) && nftLikes[_tokenId][listings[i].seller]) { // Reusing seller as example user, need proper user iteration
                likersList[index] = listings[i].seller; // Reusing seller address for example, need to iterate users properly in real app
                index++;
            }
        }
        uint256 actualCount = 0;
        for (uint256 i = 0; i < likersList.length; i++) {
            if (likersList[i] != address(0)) {
                actualCount++;
            }
        }
        address[] memory trimmedLikersList = new address[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            trimmedLikersList[i] = likersList[i];
        }
        return trimmedLikersList;
    }

}

// --- Interface for ERC721 NFT Contract (minimal required functions) ---
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
```