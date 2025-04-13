```solidity
/**
 * @title Dynamic NFT Marketplace with Social Features and Gamification
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a dynamic NFT marketplace with advanced features
 * including dynamic NFT metadata, social interactions, gamification elements like staking and leaderboards,
 * and innovative functionalities such as NFT bundling, renting, and escrow services.
 * It aims to be a comprehensive platform for trading and interacting with NFTs in a dynamic and engaging way.

 * **Contract Outline:**
 * 1. **Core NFT Functionality:**
 *    - `mintNFT(address _to, string memory _tokenURI)`: Mints a new NFT with dynamic metadata.
 *    - `burnNFT(uint256 _tokenId)`: Burns an NFT, removing it from circulation.
 *    - `updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI)`: Updates the metadata URI of an NFT.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership.
 *    - `approveNFT(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT.
 *    - `setApprovalForAllNFT(address _operator, bool _approved)`: Enables or disables approval for all of an owner's NFTs.
 *    - `getNFTMetadata(uint256 _tokenId)`: Retrieves the metadata URI of an NFT.
 *    - `getNFTOwner(uint256 _tokenId)`: Retrieves the owner of an NFT.
 *    - `getTotalNFTSupply()`: Returns the total number of NFTs minted.

 * 2. **Marketplace Operations:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 *    - `cancelNFTSale(uint256 _tokenId)`: Cancels an NFT listing, removing it from sale.
 *    - `makeOfferForNFT(uint256 _tokenId, uint256 _price)`: Allows users to make offers on NFTs.
 *    - `acceptOfferForNFT(uint256 _offerId)`: Allows NFT owners to accept specific offers.
 *    - `getNFTListingDetails(uint256 _tokenId)`: Retrieves details of an NFT listing (price, seller).
 *    - `getAllListedNFTs()`: Returns a list of all NFTs currently listed for sale.

 * 3. **Dynamic NFT Mechanics:**
 *    - `evolveNFT(uint256 _tokenId)`: Simulates NFT evolution based on predefined rules (e.g., time-based, interaction-based - placeholder logic).
 *    - `setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Allows setting dynamic traits for NFTs (e.g., rarity, level, status).

 * 4. **Social & Community Features:**
 *    - `createUserProfile(string memory _username, string memory _bio)`: Allows users to create profiles with usernames and bios.
 *    - `getUserProfile(address _user)`: Retrieves a user's profile information.
 *    - `followUser(address _userToFollow)`: Allows users to follow other users.
 *    - `getFollowers(address _user)`: Retrieves the list of followers for a user.
 *    - `createCommunity(string memory _communityName, string memory _description)`: Allows users to create communities around NFT collections or interests.
 *    - `joinCommunity(uint256 _communityId)`: Allows users to join communities.
 *    - `getCommunityMembers(uint256 _communityId)`: Retrieves the list of members in a community.

 * 5. **Gamification & Advanced Features:**
 *    - `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFTs to earn rewards (placeholder for reward mechanism).
 *    - `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs.
 *    - `getNFTStakingStatus(uint256 _tokenId)`: Retrieves the staking status of an NFT.
 *    - `createNFTBundle(uint256[] memory _tokenIds, string memory _bundleName)`: Allows users to bundle multiple NFTs into a single tradable bundle.
 *    - `rentNFT(uint256 _tokenId, address _renter, uint256 _rentDuration)`: Allows NFT owners to rent out their NFTs for a specified duration.
 *    - `endNFTRental(uint256 _tokenId)`: Allows renters or owners to end an NFT rental.
 *    - `reportNFT(uint256 _tokenId, string memory _reason)`: Allows users to report NFTs for inappropriate content or policy violations.
 *    - `pauseContract()`: Allows the contract owner to pause certain functionalities in case of emergency.
 *    - `unpauseContract()`: Allows the contract owner to resume contract functionalities.
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.

 * **Function Summary:**
 * This contract provides a comprehensive NFT marketplace with 30+ functions covering core NFT operations,
 * marketplace trading functionalities, dynamic NFT metadata management, social features like profiles and communities,
 * and gamification elements such as staking. It also introduces advanced features like NFT bundling, renting,
 * reporting, and contract pausing for enhanced platform utility and management.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _tokenIdCounter;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    // NFT Listing Data
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isListed;
    }
    mapping(uint256 => Listing) public nftListings;

    // NFT Offers Data
    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address bidder;
        uint256 price;
        bool isActive;
    }
    Counters.Counter private _offerIdCounter;
    mapping(uint256 => Offer) public nftOffers;
    EnumerableSet.UintSet private activeOfferIds;

    // User Profiles
    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;

    // User Following
    mapping(address => EnumerableSet.AddressSet) public userFollowers;

    // Communities
    struct Community {
        uint256 communityId;
        string name;
        string description;
        address creator;
        EnumerableSet.AddressSet members;
        bool exists;
    }
    Counters.Counter private _communityIdCounter;
    mapping(uint256 => Community) public communities;

    // NFT Staking Status
    mapping(uint256 => bool) public nftStakingStatus;

    // NFT Bundles
    struct NFTBundle {
        uint256 bundleId;
        string bundleName;
        address creator;
        uint256[] tokenIds;
        bool exists;
    }
    Counters.Counter private _bundleIdCounter;
    mapping(uint256 => NFTBundle) public nftBundles;

    // NFT Rental Data
    struct Rental {
        uint256 tokenId;
        address renter;
        uint256 rentStartTime;
        uint256 rentDuration; // in seconds
        bool isActive;
    }
    mapping(uint256 => Rental) public nftRentals;

    // Marketplace Fee Balance
    uint256 public marketplaceFeeBalance;

    // Events
    event NFTMinted(uint256 tokenId, address to, string tokenURI);
    event NFTBurned(uint256 tokenId);
    event NFTMetadataUpdated(uint256 tokenId, string newTokenURI);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTSaleCancelled(uint256 tokenId);
    event OfferMadeForNFT(uint256 offerId, uint256 tokenId, address bidder, uint256 price);
    event OfferAcceptedForNFT(uint256 offerId, uint256 tokenId, address seller, address bidder, uint256 price);
    event UserProfileCreated(address user, string username);
    event UserFollowed(address follower, address followedUser);
    event CommunityCreated(uint256 communityId, string communityName, address creator);
    event UserJoinedCommunity(uint256 communityId, address user);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event NFTBundleCreated(uint256 bundleId, string bundleName, address creator, uint256[] tokenIds);
    event NFTRented(uint256 tokenId, address renter, uint256 rentDuration);
    event NFTRentalEnded(uint256 tokenId, address renter);
    event NFTReported(uint256 tokenId, address reporter, string reason);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event MarketplaceFeeSet(uint256 feePercentage, address admin);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event DynamicTraitSet(uint256 tokenId, string traitName, string traitValue);
    event NFTTransferred(address from, address to, uint256 tokenId);
    event NFTApproved(address approved, uint256 tokenId, address owner);
    event NFTApprovalForAllSet(address owner, address operator, bool approved);


    constructor() ERC721("DynamicNFT", "DNFT") {}

    modifier nftExists(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId), "Not NFT owner");
        _;
    }

    modifier isListedForSale(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier isNotListedForSale(uint256 _tokenId) {
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        _;
    }

    modifier offerExists(uint256 _offerId) {
        require(nftOffers[_offerId].isActive, "Offer does not exist or is inactive");
        _;
    }

    modifier isOfferBidder(uint256 _offerId) {
        require(nftOffers[_offerId].bidder == _msgSender(), "Not offer bidder");
        _;
    }

    modifier isNFTRenter(uint256 _tokenId) {
        require(nftRentals[_tokenId].renter == _msgSender() && nftRentals[_tokenId].isActive, "Not NFT renter");
        _;
    }

    modifier isRentalActive(uint256 _tokenId) {
        require(nftRentals[_tokenId].isActive, "NFT is not currently rented");
        _;
    }

    modifier isRentalNotActive(uint256 _tokenId) {
        require(!nftRentals[_tokenId].isActive, "NFT is currently rented");
        _;
    }

    modifier communityExists(uint256 _communityId) {
        require(communities[_communityId].exists, "Community does not exist");
        _;
    }

    modifier isCommunityMember(uint256 _communityId) {
        require(communities[_communityId].members.contains(_msgSender()), "Not a community member");
        _;
    }

    modifier bundleExists(uint256 _bundleId) {
        require(nftBundles[_bundleId].exists, "Bundle does not exist");
        _;
    }

    modifier profileExists(address _user) {
        require(userProfiles[_user].exists, "User profile does not exist");
        _;
    }

    // 1. Core NFT Functionality

    function mintNFT(address _to, string memory _tokenURI) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit NFTMinted(tokenId, _to, _tokenURI);
        return tokenId;
    }

    function burnNFT(uint256 _tokenId) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) {
        _burn(_tokenId);
        emit NFTBurned(_tokenId);
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) {
        _setTokenURI(_tokenId, _newTokenURI);
        emit NFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused nftExists(_tokenId) {
        safeTransferFrom(_msgSender(), _to, _tokenId);
        emit NFTTransferred(_msgSender(), _to, _tokenId);
    }

    function approveNFT(address _approved, uint256 _tokenId) public whenNotPaused nftExists(_tokenId) {
        approve(_approved, _tokenId);
        emit NFTApproved(_approved, _tokenId, ownerOf(_tokenId));
    }

    function setApprovalForAllNFT(address _operator, bool _approved) public whenNotPaused {
        setApprovalForAll(_operator, _approved);
        emit NFTApprovalForAllSet(_msgSender(), _operator, _approved);
    }

    function getNFTMetadata(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return tokenURI(_tokenId);
    }

    function getNFTOwner(uint256 _tokenId) public view nftExists(_tokenId) returns (address) {
        return ownerOf(_tokenId);
    }

    function getTotalNFTSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // 2. Marketplace Operations

    function listNFTForSale(uint256 _tokenId, uint256 _price) public payable isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) isNotListedForSale(_tokenId) isRentalNotActive(_tokenId) {
        require(_price > 0, "Price must be greater than zero");
        nftListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, _msgSender());
    }

    function buyNFT(uint256 _tokenId) public payable whenNotPaused nftExists(_tokenId) isListedForSale(_tokenId) {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        marketplaceFeeBalance += marketplaceFee;

        listing.isListed = false; // Remove from listing immediately to prevent double buying

        _transfer(listing.seller, _msgSender(), _tokenId);

        (bool success,) = payable(listing.seller).call{value: sellerProceeds}("");
        require(success, "Transfer to seller failed");

        emit NFTBought(_tokenId, _msgSender(), listing.seller, listing.price);
    }

    function cancelNFTSale(uint256 _tokenId) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) isListedForSale(_tokenId) {
        nftListings[_tokenId].isListed = false;
        emit NFTSaleCancelled(_tokenId);
    }

    function makeOfferForNFT(uint256 _tokenId, uint256 _price) public payable whenNotPaused nftExists(_tokenId) isNotListedForSale(_tokenId) {
        require(_price > 0, "Offer price must be greater than zero");
        require(msg.value >= _price, "Insufficient funds for offer");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();
        nftOffers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            bidder: _msgSender(),
            price: _price,
            isActive: true
        });
        activeOfferIds.add(offerId);
        emit OfferMadeForNFT(offerId, _tokenId, _msgSender(), _price);
    }

    function acceptOfferForNFT(uint256 _offerId) public isNFTOwner(nftOffers[_offerId].tokenId) whenNotPaused offerExists(_offerId) {
        Offer storage offer = nftOffers[_offerId];
        require(offer.tokenId == nftOffers[_offerId].tokenId, "Offer Token ID mismatch"); // Sanity check

        Listing storage listing = nftListings[offer.tokenId];
        if (listing.isListed) {
            listing.isListed = false; // Cancel listing if still listed
        }

        offer.isActive = false;
        activeOfferIds.remove(_offerId);

        uint256 marketplaceFee = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offer.price - marketplaceFee;

        marketplaceFeeBalance += marketplaceFee;

        _transfer(ownerOf(offer.tokenId), offer.bidder, offer.tokenId);

        (bool success,) = payable(ownerOf(offer.tokenId)).call{value: sellerProceeds}("");
        require(success, "Transfer to seller failed");

        emit OfferAcceptedForNFT(_offerId, offer.tokenId, ownerOf(offer.tokenId), offer.bidder, offer.price);
    }

    function getNFTListingDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (Listing memory) {
        return nftListings[_tokenId];
    }

    function getAllListedNFTs() public view returns (uint256[] memory) {
        uint256 listedCount = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (nftListings[i].isListed) {
                listedCount++;
            }
        }
        uint256[] memory listedTokenIds = new uint256[](listedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (nftListings[i].isListed) {
                listedTokenIds[index] = nftListings[i].tokenId;
                index++;
            }
        }
        return listedTokenIds;
    }


    // 3. Dynamic NFT Mechanics (Placeholder - Needs more complex logic for real evolution)

    function evolveNFT(uint256 _tokenId) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) {
        // Placeholder evolution logic - can be expanded to be time-based, interaction-based, etc.
        string memory currentURI = tokenURI(_tokenId);
        string memory evolvedURI = string(abi.encodePacked(currentURI, "?evolved=true&time=", block.timestamp.toString())); // Simple example
        _setTokenURI(_tokenId, evolvedURI);
    }

    function setDynamicTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) {
        // Example: Could store dynamic traits in a mapping or append to metadata URI (more complex parsing needed on frontend)
        // For simplicity, just emit an event here. In a real application, you'd need a more structured way to handle dynamic traits.
        emit DynamicTraitSet(_tokenId, _traitName, _traitValue);
    }

    // 4. Social & Community Features

    function createUserProfile(string memory _username, string memory _bio) public whenNotPaused {
        require(!userProfiles[_msgSender()].exists, "Profile already exists");
        userProfiles[_msgSender()] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        emit UserProfileCreated(_msgSender(), _username);
    }

    function getUserProfile(address _user) public view profileExists(_user) returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function followUser(address _userToFollow) public whenNotPaused profileExists(_userToFollow) {
        require(_userToFollow != _msgSender(), "Cannot follow yourself");
        userFollowers[_userToFollow].add(_msgSender());
        emit UserFollowed(_msgSender(), _userToFollow);
    }

    function getFollowers(address _user) public view profileExists(_user) returns (address[] memory) {
        return userFollowers[_user].values();
    }

    function createCommunity(string memory _communityName, string memory _description) public whenNotPaused {
        _communityIdCounter.increment();
        uint256 communityId = _communityIdCounter.current();
        communities[communityId] = Community({
            communityId: communityId,
            name: _communityName,
            description: _description,
            creator: _msgSender(),
            members: EnumerableSet.AddressSet(),
            exists: true
        });
        communities[communityId].members.add(_msgSender()); // Creator automatically joins
        emit CommunityCreated(communityId, _communityName, _msgSender());
    }

    function joinCommunity(uint256 _communityId) public whenNotPaused communityExists(_communityId) {
        require(!communities[_communityId].members.contains(_msgSender()), "Already a member");
        communities[_communityId].members.add(_msgSender());
        emit UserJoinedCommunity(_communityId, _msgSender());
    }

    function getCommunityMembers(uint256 _communityId) public view communityExists(_communityId) returns (address[] memory) {
        return communities[_communityId].members.values();
    }


    // 5. Gamification & Advanced Features

    function stakeNFT(uint256 _tokenId) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) isNotListedForSale(_tokenId) isRentalNotActive(_tokenId) {
        require(!nftStakingStatus[_tokenId], "NFT already staked");
        nftStakingStatus[_tokenId] = true;
        // Implement staking reward logic here in a real application (e.g., accrue tokens over time)
        emit NFTStaked(_tokenId, _msgSender());
    }

    function unstakeNFT(uint256 _tokenId) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) {
        require(nftStakingStatus[_tokenId], "NFT not staked");
        nftStakingStatus[_tokenId] = false;
        // Implement reward claiming logic here if applicable
        emit NFTUnstaked(_tokenId, _msgSender());
    }

    function getNFTStakingStatus(uint256 _tokenId) public view nftExists(_tokenId) returns (bool) {
        return nftStakingStatus[_tokenId];
    }

    function createNFTBundle(uint256[] memory _tokenIds, string memory _bundleName) public whenNotPaused {
        require(_tokenIds.length > 1, "Bundle must contain at least 2 NFTs");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(isNFTOwner(_tokenIds[i]), "Not owner of all NFTs in bundle");
        }

        _bundleIdCounter.increment();
        uint256 bundleId = _bundleIdCounter.current();
        nftBundles[bundleId] = NFTBundle({
            bundleId: bundleId,
            bundleName: _bundleName,
            creator: _msgSender(),
            tokenIds: _tokenIds,
            exists: true
        });

        // Consider locking/transferring NFTs into the bundle for secure trading in a real application.
        emit NFTBundleCreated(bundleId, _bundleName, _msgSender(), _tokenIds);
    }


    function rentNFT(uint256 _tokenId, address _renter, uint256 _rentDuration) public isNFTOwner(_tokenId) whenNotPaused nftExists(_tokenId) isNotListedForSale(_tokenId) isRentalNotActive(_tokenId) {
        require(_renter != address(0) && _renter != ownerOf(_tokenId), "Invalid renter address");
        require(_rentDuration > 0, "Rent duration must be greater than zero");

        nftRentals[_tokenId] = Rental({
            tokenId: _tokenId,
            renter: _renter,
            rentStartTime: block.timestamp,
            rentDuration: _rentDuration,
            isActive: true
        });

        // Consider transferring NFT ownership to the contract during rental for security in a real application.
        emit NFTRented(_tokenId, _renter, _rentDuration);
    }

    function endNFTRental(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) isRentalActive(_tokenId) {
        require(_msgSender() == nftRentals[_tokenId].renter || _msgSender() == ownerOf(_tokenId), "Only renter or owner can end rental");
        nftRentals[_tokenId].isActive = false;
        emit NFTRentalEnded(_tokenId, nftRentals[_tokenId].renter);
        // Consider returning NFT ownership to the original owner in a real application if it was transferred during rental.
    }

    function reportNFT(uint256 _tokenId, string memory _reason) public whenNotPaused nftExists(_tokenId) {
        // Placeholder - In a real application, implement moderation/reporting workflow, potentially involving admin review.
        emit NFTReported(_tokenId, _msgSender(), _reason);
    }

    // Admin Functions

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage, _msgSender());
    }

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 amount = marketplaceFeeBalance;
        marketplaceFeeBalance = 0;
        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit MarketplaceFeesWithdrawn(amount, _msgSender());
    }

    // Override for ERC721 tokenURI to allow dynamic metadata (optional, or can be handled off-chain)
    function tokenURI(uint256 _tokenId) public view override nftExists(_tokenId) returns (string memory) {
        string memory baseURI = _tokenURI(_tokenId);
        // Here you could add logic to dynamically construct the URI based on NFT state/traits if needed.
        // For example, fetching data from an external source or based on internal state.
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any pre-transfer checks here if needed, e.g., rental status checks.
        require(!nftRentals[tokenId].isActive || to == nftRentals[tokenId].renter || to == ownerOf(tokenId) || from == ownerOf(tokenId), "NFT is currently rented and cannot be transferred.");
    }

    // Fallback and Receive functions to handle direct ETH transfers (if needed for buying, etc.)
    receive() external payable {}
    fallback() external payable {}
}
```