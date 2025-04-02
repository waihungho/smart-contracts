```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation and Social Features
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT marketplace with advanced features like AI-driven curation,
 *      social interactions, and decentralized governance aspects. This contract aims to be creative and go beyond
 *      basic NFT marketplace functionalities, incorporating trendy web3 concepts without directly duplicating
 *      existing open-source solutions.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Management (Dynamic & Evolving NFTs):**
 *    - `mintDynamicNFT(address _to, string memory _baseURI, bytes[] memory _initialTraits)`: Mints a new dynamic NFT with an initial base URI and traits.
 *    - `updateNFTTraits(uint256 _tokenId, bytes[] memory _newTraits)`: Allows updating the traits of a dynamic NFT, potentially triggering visual or metadata changes.
 *    - `getNFTTraits(uint256 _tokenId) view returns (bytes[] memory)`: Retrieves the current traits of a specific NFT.
 *    - `setNFTBaseURI(uint256 _tokenId, string memory _newBaseURI)`:  Updates the base URI for an NFT, affecting metadata resolution.
 *    - `getNFTMetadataURI(uint256 _tokenId) view returns (string memory)`: Constructs and returns the full metadata URI for an NFT based on base URI and traits.
 *
 * **2. Marketplace Listing & Trading:**
 *    - `listItemForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale at a fixed price.
 *    - `buyNFT(uint256 _listingId)`: Allows anyone to purchase an NFT listed for sale.
 *    - `cancelListing(uint256 _listingId)`: Allows the seller to cancel a listing before it's bought.
 *    - `makeOffer(uint256 _tokenId, uint256 _price)`: Allows users to make offers on NFTs that are not currently listed for sale.
 *    - `acceptOffer(uint256 _offerId)`: Allows the NFT owner to accept a specific offer on their NFT.
 *    - `withdrawOffer(uint256 _offerId)`: Allows the offer maker to withdraw their offer before it's accepted or rejected.
 *    - `getListingsByNFT(uint256 _tokenId) view returns (uint256[] memory)`: Retrieves listing IDs for a specific NFT.
 *    - `getOffersByNFT(uint256 _tokenId) view returns (uint256[] memory)`: Retrieves offer IDs for a specific NFT.
 *
 * **3. AI-Powered Curation (Simulated & On-Chain Voting):**
 *    - `submitCurationScore(uint256 _tokenId, uint8 _score)`: Allows users to submit a curation score (e.g., 1-5 stars) for an NFT, simulating AI input.
 *    - `getAverageCurationScore(uint256 _tokenId) view returns (uint256)`: Calculates and returns the average curation score for an NFT.
 *    - `getTrendingNFTs(uint256 _count) view returns (uint256[] memory)`: Returns a list of trending NFTs based on curation scores and recent activity (simplified trending logic).
 *
 * **4. Social Features & Community Interaction:**
 *    - `createUserProfile(string memory _username, string memory _profileURI)`: Allows users to create a profile with a username and profile URI.
 *    - `updateUserProfile(string memory _username, string memory _newProfileURI)`: Allows users to update their profile URI.
 *    - `getUserProfile(address _user) view returns (string memory, string memory)`: Retrieves a user's profile information.
 *    - `followUser(address _userToFollow)`: Allows users to follow other users, creating a social graph.
 *    - `unfollowUser(address _userToUnfollow)`: Allows users to unfollow other users.
 *    - `getFollowersCount(address _user) view returns (uint256)`: Returns the number of followers a user has.
 *    - `getFollowingCount(address _user) view returns (uint256)`: Returns the number of users a user is following.
 *
 * **5. Platform Governance & Management (Simple):**
 *    - `setPlatformFee(uint256 _newFeePercentage)`: Allows the contract owner to set the platform fee percentage for sales.
 *    - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows the contract owner to pause core marketplace functions in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _offerIdCounter;

    // NFT Data Structures
    struct DynamicNFT {
        string baseURI;
        bytes[] traits; // Represented as bytes for flexibility, could be enums or structs in a real application
    }
    mapping(uint256 => DynamicNFT) public dynamicNFTs;

    // Marketplace Data Structures
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public nftToListingId; // Map tokenId to active listingId
    mapping(uint256 => uint256[]) public nftListings; // Map tokenId to array of listingIds (including inactive/historical)

    struct Offer {
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => uint256[]) public nftOffers; // Map tokenId to array of offerIds

    // Curation Data Structures
    mapping(uint256 => uint256[]) public nftCurationScores; // Map tokenId to array of scores
    uint256 public curationScoreWeight = 10; // Weighting factor for curation scores in trending calculation

    // Social Features Data Structures
    struct UserProfile {
        string username;
        string profileURI;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => bool)) public followers; // User -> Follower -> isFollowing
    mapping(address => mapping(address => bool)) public following; // User -> Following -> isFollowed

    // Platform Fees
    uint256 public platformFeePercentage = 2; // 2% platform fee
    address payable public platformFeeRecipient;

    // Contract State
    bool public paused = false;

    event NFTMinted(uint256 tokenId, address to);
    event NFTTraitsUpdated(uint256 tokenId);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address offerer, uint256 price);
    event OfferWithdrawn(uint256 offerId, uint256 tokenId, address offerer);
    event CurationScoreSubmitted(uint256 tokenId, address submitter, uint8 score);
    event UserProfileCreated(address user, string username);
    event UserProfileUpdated(address user, string username, string profileURI);
    event UserFollowed(address follower, address followed);
    event UserUnfollowed(address follower, address unfollowed);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    constructor(string memory _name, string memory _symbol, address payable _platformFeeRecipient) ERC721(_name, _symbol) {
        platformFeeRecipient = _platformFeeRecipient;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == _msgSender(), "You are not the seller of this listing");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        _;
    }

    // 1. NFT Management Functions

    /// @notice Mints a new dynamic NFT with initial base URI and traits.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The base URI for the NFT's metadata.
    /// @param _initialTraits Initial traits of the NFT (represented as bytes for flexibility).
    function mintDynamicNFT(address _to, string memory _baseURI, bytes[] memory _initialTraits) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        dynamicNFTs[tokenId] = DynamicNFT({
            baseURI: _baseURI,
            traits: _initialTraits
        });
        emit NFTMinted(tokenId, _to);
        return tokenId;
    }

    /// @notice Updates the traits of a dynamic NFT. Only owner can update.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newTraits The new traits to set for the NFT.
    function updateNFTTraits(uint256 _tokenId, bytes[] memory _newTraits) public onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].traits = _newTraits;
        emit NFTTraitsUpdated(_tokenId);
    }

    /// @notice Retrieves the current traits of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return bytes[] The traits of the NFT.
    function getNFTTraits(uint256 _tokenId) public view returns (bytes[] memory) {
        return dynamicNFTs[_tokenId].traits;
    }

    /// @notice Sets the base URI for an NFT. Only owner can set.
    /// @param _tokenId The ID of the NFT.
    /// @param _newBaseURI The new base URI for the NFT.
    function setNFTBaseURI(uint256 _tokenId, string memory _newBaseURI) public onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].baseURI = _newBaseURI;
    }

    /// @notice Constructs and returns the full metadata URI for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return string The metadata URI for the NFT.
    function getNFTMetadataURI(uint256 _tokenId) public view override returns (string memory) {
        // In a real application, you might use traits to dynamically construct the metadata URI.
        // For simplicity, we just append the tokenId to the baseURI here.
        return string(abi.encodePacked(dynamicNFTs[_tokenId].baseURI, _tokenId.toString(), ".json"));
    }

    // 2. Marketplace Listing & Trading Functions

    /// @notice Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The sale price in wei.
    function listItemForSale(uint256 _tokenId, uint256 _price) public whenNotPaused onlyNFTOwner(_tokenId) {
        require(getApproved(_tokenId) == address(this) || isApprovedForAll(ownerOf(_tokenId), address(this)), "Contract not approved to transfer NFT");
        require(nftToListingId[_tokenId] == 0, "NFT is already listed for sale"); // Only one active listing per NFT at a time

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();
        listings[listingId] = Listing({
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        nftToListingId[_tokenId] = listingId;
        nftListings[_tokenId].push(listingId);

        emit NFTListed(listingId, _tokenId, _msgSender(), _price);
    }

    /// @notice Allows anyone to purchase an NFT listed for sale.
    /// @param _listingId The ID of the listing to purchase.
    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");
        require(msg.value >= listing.price, "Insufficient funds sent");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        // Transfer platform fee
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;

        (bool successFee, ) = platformFeeRecipient.call{value: platformFee}("");
        require(successFee, "Platform fee transfer failed");
        (bool successSeller, ) = payable(seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed");

        // Transfer NFT
        _transfer(seller, _msgSender(), tokenId);

        // Update listing state
        listing.isActive = false;
        nftToListingId[tokenId] = 0; // Clear active listing

        emit NFTBought(_listingId, tokenId, _msgSender(), price);
    }

    /// @notice Cancels a listing before it's bought.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) public whenNotPaused onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");

        listing.isActive = false;
        nftToListingId[listing.tokenId] = 0; // Clear active listing

        emit ListingCancelled(_listingId, listing.tokenId);
    }

    /// @notice Allows users to make offers on NFTs that are not currently listed for sale.
    /// @param _tokenId The ID of the NFT to make an offer on.
    /// @param _price The offer price in wei.
    function makeOffer(uint256 _tokenId, uint256 _price) public payable whenNotPaused {
        require(nftToListingId[_tokenId] == 0, "NFT is already listed for sale, buy listing instead");
        require(msg.value >= _price, "Insufficient funds sent for offer");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        offers[offerId] = Offer({
            tokenId: _tokenId,
            offerer: _msgSender(),
            price: _price,
            isActive: true
        });
        nftOffers[_tokenId].push(offerId);

        emit OfferMade(offerId, _tokenId, _msgSender(), _price);
    }

    /// @notice Allows the NFT owner to accept a specific offer on their NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) public whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active");
        require(ownerOf(offer.tokenId) == _msgSender(), "You are not the owner of the NFT");

        uint256 tokenId = offer.tokenId;
        address offerer = offer.offerer;
        uint256 price = offer.price;

        // Transfer platform fee
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerProceeds = price - platformFee;

        (bool successFee, ) = platformFeeRecipient.call{value: platformFee}("");
        require(successFee, "Platform fee transfer failed");
        (bool successSeller, ) = payable(_msgSender()).call{value: sellerProceeds}(""); // Send to current owner (seller)
        require(successSeller, "Seller payment failed");

        // Transfer NFT
        _transfer(_msgSender(), offerer, tokenId); // Transfer from current owner to offerer

        // Update offer state and invalidate other offers for this NFT (for simplicity, could be improved)
        offer.isActive = false;
        for (uint i = 0; i < nftOffers[tokenId].length; i++) {
            uint256 currentOfferId = nftOffers[tokenId][i];
            if (offers[currentOfferId].isActive && currentOfferId != _offerId) {
                offers[currentOfferId].isActive = false; // Invalidate other offers
                payable(offers[currentOfferId].offerer).transfer(offers[currentOfferId].price); // Return funds
            }
        }
        nftOffers[tokenId] = new uint256[](0); // Clear all offers for this NFT (simplified)


        emit OfferAccepted(_offerId, tokenId, _msgSender(), offerer, price);
    }

    /// @notice Allows the offer maker to withdraw their offer before it's accepted or rejected.
    /// @param _offerId The ID of the offer to withdraw.
    function withdrawOffer(uint256 _offerId) public whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active");
        require(offer.offerer == _msgSender(), "You are not the offerer");

        offer.isActive = false;
        payable(_msgSender()).transfer(offer.price);

        emit OfferWithdrawn(_offerId, offer.tokenId, _msgSender());
    }

    /// @notice Retrieves listing IDs for a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256[] An array of listing IDs for the NFT.
    function getListingsByNFT(uint256 _tokenId) public view returns (uint256[] memory) {
        return nftListings[_tokenId];
    }

    /// @notice Retrieves offer IDs for a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256[] An array of offer IDs for the NFT.
    function getOffersByNFT(uint256 _tokenId) public view returns (uint256[] memory) {
        return nftOffers[_tokenId];
    }


    // 3. AI-Powered Curation Functions (Simulated & On-Chain Voting)

    /// @notice Allows users to submit a curation score for an NFT.
    /// @param _tokenId The ID of the NFT to score.
    /// @param _score The curation score (e.g., 1-5).
    function submitCurationScore(uint256 _tokenId, uint8 _score) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(_score > 0 && _score <= 5, "Score must be between 1 and 5"); // Example score range
        nftCurationScores[_tokenId].push(_score);
        emit CurationScoreSubmitted(_tokenId, _msgSender(), _score);
    }

    /// @notice Calculates and returns the average curation score for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return uint256 The average curation score (scaled by 100 for decimal representation).
    function getAverageCurationScore(uint256 _tokenId) public view returns (uint256) {
        uint256[] memory scores = nftCurationScores[_tokenId];
        if (scores.length == 0) {
            return 0; // No scores yet
        }
        uint256 sum = 0;
        for (uint i = 0; i < scores.length; i++) {
            sum += scores[i];
        }
        return (sum * 100) / scores.length; // Average scaled by 100
    }

    /// @notice Returns a list of trending NFTs based on curation scores and recent activity (simplified trending logic).
    /// @param _count The number of trending NFTs to return.
    /// @return uint256[] An array of trending NFT token IDs.
    function getTrendingNFTs(uint256 _count) public view returns (uint256[] memory) {
        uint256 nftCount = _tokenIdCounter.current();
        uint256[] memory trendingNFTs = new uint256[](_count);
        uint256[] memory scores = new uint256[](nftCount + 1); // Index 0 is unused

        // Simplified trending logic: higher curation score is more trending
        for (uint256 i = 1; i <= nftCount; i++) {
            scores[i] = getAverageCurationScore(i); // In a real app, consider more factors for trending
        }

        // Simple bubble sort to get top _count NFTs (not efficient for large scale, optimize in real app)
        for (uint256 i = 0; i < _count; i++) {
            uint256 bestNFT = 0;
            uint256 bestScore = 0;
            for (uint256 j = 1; j <= nftCount; j++) {
                bool alreadyInTrending = false;
                for (uint256 k = 0; k < i; k++) {
                    if (trendingNFTs[k] == j) {
                        alreadyInTrending = true;
                        break;
                    }
                }
                if (!alreadyInTrending && scores[j] > bestScore) {
                    bestScore = scores[j];
                    bestNFT = j;
                }
            }
            trendingNFTs[i] = bestNFT;
        }
        return trendingNFTs;
    }


    // 4. Social Features & Community Interaction

    /// @notice Creates a user profile.
    /// @param _username The desired username.
    /// @param _profileURI URI pointing to the user's profile information (e.g., IPFS link).
    function createUserProfile(string memory _username, string memory _profileURI) public whenNotPaused {
        require(!userProfiles[_msgSender()].exists, "Profile already exists");
        userProfiles[_msgSender()] = UserProfile({
            username: _username,
            profileURI: _profileURI,
            exists: true
        });
        emit UserProfileCreated(_msgSender(), _username);
    }

    /// @notice Updates a user's profile URI.
    /// @param _username The username (must match existing profile's username, for simplicity in this example).
    /// @param _newProfileURI The new profile URI.
    function updateUserProfile(string memory _username, string memory _newProfileURI) public whenNotPaused {
        require(userProfiles[_msgSender()].exists, "Profile does not exist");
        require(keccak256(bytes(userProfiles[_msgSender()].username)) == keccak256(bytes(_username)), "Username cannot be changed in this example"); // Simplified username check
        userProfiles[_msgSender()].profileURI = _newProfileURI;
        emit UserProfileUpdated(_msgSender(), _username, _newProfileURI);
    }

    /// @notice Retrieves a user's profile information.
    /// @param _user The address of the user.
    /// @return string The username of the user.
    /// @return string The profile URI of the user.
    function getUserProfile(address _user) public view returns (string memory, string memory) {
        require(userProfiles[_user].exists, "Profile does not exist");
        return (userProfiles[_user].username, userProfiles[_user].profileURI);
    }

    /// @notice Allows a user to follow another user.
    /// @param _userToFollow The address of the user to follow.
    function followUser(address _userToFollow) public whenNotPaused {
        require(_userToFollow != _msgSender(), "Cannot follow yourself");
        require(userProfiles[_userToFollow].exists, "User to follow does not have a profile");
        require(!followers[_userToFollow][_msgSender()], "Already following this user");

        followers[_userToFollow][_msgSender()] = true;
        following[_msgSender()][_userToFollow] = true;
        emit UserFollowed(_msgSender(), _userToFollow);
    }

    /// @notice Allows a user to unfollow another user.
    /// @param _userToUnfollow The address of the user to unfollow.
    function unfollowUser(address _userToUnfollow) public whenNotPaused {
        require(followers[_userToUnfollow][_msgSender()], "Not following this user");

        followers[_userToUnfollow][_msgSender()] = false;
        following[_msgSender()][_userToUnfollow] = false;
        emit UserUnfollowed(_msgSender(), _userToUnfollow);
    }

    /// @notice Returns the number of followers a user has.
    /// @param _user The address of the user.
    /// @return uint256 The number of followers.
    function getFollowersCount(address _user) public view returns (uint256) {
        uint256 count = 0;
        address[] memory allUsers = new address[](_tokenIdCounter.current() + 1); // Approximation, not scalable for large user base
        uint userCount = 0;
        for (uint i = 1; i <= _tokenIdCounter.current(); i++) {
             address owner = ownerOf(i);
             if (userProfiles[owner].exists) {
                 allUsers[userCount] = owner;
                 userCount++;
             }
        }

        for (uint i = 0; i < userCount; i++) { // Iterate through approximate user list
            if (followers[_user][allUsers[i]]) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the number of users a user is following.
    /// @param _user The address of the user.
    /// @return uint256 The number of users being followed.
    function getFollowingCount(address _user) public view returns (uint256) {
        uint256 count = 0;
        address[] memory allUsers = new address[](_tokenIdCounter.current() + 1); // Approximation, not scalable for large user base
        uint userCount = 0;
        for (uint i = 1; i <= _tokenIdCounter.current(); i++) {
             address owner = ownerOf(i);
             if (userProfiles[owner].exists) {
                 allUsers[userCount] = owner;
                 userCount++;
             }
        }
        for (uint i = 0; i < userCount; i++) { // Iterate through approximate user list
            if (following[_user][allUsers[i]]) {
                count++;
            }
        }
        return count;
    }


    // 5. Platform Governance & Management Functions (Simple)

    /// @notice Sets the platform fee percentage. Only owner can set.
    /// @param _newFeePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = platformFeeRecipient.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit PlatformFeesWithdrawn(platformFeeRecipient, balance);
    }

    /// @notice Pauses core marketplace functions. Only owner can pause.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses core marketplace functions. Only owner can unpause.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // Override _beforeTokenTransfer to ensure contract is approved for transfers when listing/selling
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) { // Transferring, not minting/burning
            if (nftToListingId[tokenId] != 0 && listings[nftToListingId[tokenId]].isActive && from == listings[nftToListingId[tokenId]].seller) {
                // Allowed transfer if part of a listing sale
            } else if (nftOffers[tokenId].length > 0) {
                bool offerAccepted = false;
                for (uint i = 0; i < nftOffers[tokenId].length; i++) {
                    if (offers[nftOffers[tokenId][i]].isActive && offers[nftOffers[tokenId][i]].offerer == to) {
                        offerAccepted = true;
                        break;
                    }
                }
                if (offerAccepted) {
                    // Allowed transfer if part of offer acceptance
                } else {
                    require(getApproved(tokenId) == address(this) || isApprovedForAll(from, address(this)), "Contract must be approved to transfer NFT outside of marketplace flow");
                }
            } else {
                require(getApproved(tokenId) == address(this) || isApprovedForAll(from, address(this)), "Contract must be approved to transfer NFT outside of marketplace flow");
            }
        }
    }

    // The following functions are overrides required by Solidity when inheriting ERC721.
    // They are left as default implementations as they are not customized for this example.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return getNFTMetadataURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```