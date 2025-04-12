```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with DAO Governance and Social Features
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a dynamic NFT marketplace with advanced features like
 *      dynamic NFT traits, DAO governance for marketplace parameters, and social interactions.
 *      It is designed to be creative, trendy, and showcase advanced Solidity concepts, avoiding duplication
 *      of common open-source contracts.
 *
 * **Outline:**
 *
 * **1. NFT Management:**
 *    - mintNFT: Allows contract owner to mint new NFTs with dynamic traits.
 *    - setBaseURI: Sets the base URI for NFT metadata.
 *    - updateNFTMetadata: Allows updating metadata for a specific NFT, triggering dynamic changes.
 *    - transferNFT: Standard NFT transfer functionality.
 *    - burnNFT: Allows owner to burn an NFT.
 *
 * **2. Marketplace Listing and Trading:**
 *    - listItem: Allows NFT owners to list their NFTs for sale.
 *    - purchaseNFT: Allows users to purchase listed NFTs.
 *    - createAuction: Allows NFT owners to create auctions for their NFTs.
 *    - bidOnAuction: Allows users to bid on active auctions.
 *    - finalizeAuction: Finalizes an auction and transfers NFT to the highest bidder.
 *    - cancelListing: Allows NFT owners to cancel their NFT listings.
 *    - setMarketplaceFee: DAO-governed function to set the marketplace fee percentage.
 *
 * **3. Dynamic NFT Traits and Evolution:**
 *    - evolveNFT: Function to trigger NFT evolution based on certain conditions (example: time-based).
 *    - setNFTTrait: Allows setting specific traits for an NFT (owner-controlled or dynamic).
 *    - getNFTTraits: Retrieves the current traits of an NFT.
 *
 * **4. DAO Governance (Simplified):**
 *    - createProposal: Allows DAO members to create governance proposals.
 *    - voteOnProposal: Allows DAO members to vote on active proposals.
 *    - executeProposal: Executes a successful proposal (e.g., changing marketplace fee).
 *    - getProposalState: Retrieves the state of a proposal.
 *
 * **5. Social and Community Features:**
 *    - createUserProfile: Allows users to create a profile with basic information.
 *    - followUser: Allows users to follow other users (basic social interaction).
 *    - reportUser: Allows users to report other users (basic moderation feature).
 *    - postToCommunityFeed: Allows users to post messages to a community feed (on-chain or link to off-chain).
 *
 * **Function Summary:**
 * - `mintNFT(address _to, string memory _tokenURI, string memory _initialTraits)`: Mints a new NFT with dynamic traits to a specified address.
 * - `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata.
 * - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the metadata for a specific NFT, potentially triggering dynamic trait changes.
 * - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * - `burnNFT(uint256 _tokenId)`: Burns a specific NFT, removing it from circulation.
 * - `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 * - `purchaseNFT(uint256 _tokenId)`: Allows anyone to purchase a listed NFT.
 * - `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Creates an auction for an NFT with a starting bid and duration.
 * - `bidOnAuction(uint256 _tokenId)`: Allows users to place bids on an active auction.
 * - `finalizeAuction(uint256 _tokenId)`: Finalizes an auction, transferring the NFT to the highest bidder and distributing funds.
 * - `cancelListing(uint256 _tokenId)`: Cancels an active listing for an NFT.
 * - `setMarketplaceFee(uint256 _newFeePercentage)`: DAO-governed function to set the marketplace fee percentage.
 * - `evolveNFT(uint256 _tokenId)`: Triggers the evolution of an NFT based on predefined conditions (example implementation).
 * - `setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Sets a specific trait for an NFT.
 * - `getNFTTraits(uint256 _tokenId)`: Retrieves the current traits of an NFT as a string.
 * - `createProposal(string memory _description, bytes memory _calldata)`: Creates a governance proposal with a description and calldata to execute if passed.
 * - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to vote on a proposal.
 * - `executeProposal(uint256 _proposalId)`: Executes a passed proposal if the voting period has ended.
 * - `getProposalState(uint256 _proposalId)`: Retrieves the current state of a proposal (active, passed, failed).
 * - `createUserProfile(string memory _username, string memory _bio)`: Creates a user profile with a username and bio.
 * - `followUser(address _userToFollow)`: Allows a user to follow another user.
 * - `reportUser(address _reportedUser, string memory _reason)`: Allows a user to report another user for moderation purposes.
 * - `postToCommunityFeed(string memory _message)`: Allows users to post messages to a community feed.
 */
contract DynamicNFTMarketplace {
    // ** State Variables **

    string public name = "DynamicNFTMarketplace";
    string public symbol = "DNFTM";
    string public baseURI;
    uint256 public totalSupply;
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenTraits; // Store dynamic traits as strings (can be JSON or other formats)
    mapping(uint256 => string) public tokenMetadata;
    mapping(uint256 => bool) public exists;

    // Marketplace Listings
    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;

    // Auctions
    struct Auction {
        uint256 startingBid;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Auction) public nftAuctions;

    // DAO Governance (Simplified - Requires more robust implementation for production)
    struct Proposal {
        string description;
        bytes calldata;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    address[] public daoMembers; // Example DAO members - In real DAO, this would be more sophisticated.

    // Social Features (Simplified)
    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(address => bool)) public followers; // User -> Follower -> isFollowing

    // Events
    event NFTMinted(uint256 tokenId, address to, string tokenURI, string traits);
    event MetadataUpdated(uint256 tokenId, string newMetadata);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event AuctionCreated(uint256 tokenId, uint256 startingBid, uint256 endTime, address seller);
    event BidPlaced(uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 tokenId, address winner, uint256 finalPrice);
    event ListingCancelled(uint256 tokenId);
    event MarketplaceFeeUpdated(uint256 newFeePercentage, address proposer);
    event NFTEvolved(uint256 tokenId, string newTraits);
    event NFTTraitSet(uint256 tokenId, string traitName, string traitValue);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event UserProfileCreated(address user, string username);
    event UserFollowed(address follower, address followedUser);
    event UserReported(address reporter, address reportedUser, string reason);
    event CommunityPostCreated(address poster, string message);

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyDAO() {
        bool isDAOMember = false;
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                isDAOMember = true;
                break;
            }
        }
        require(isDAOMember, "Only DAO members can call this function.");
        _;
    }

    // ** Constructor **
    constructor(address[] memory _initialDAOMembers) {
        owner = msg.sender;
        daoMembers = _initialDAOMembers;
    }

    // ** 1. NFT Management Functions **

    /// @notice Mints a new NFT with dynamic traits to a specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _tokenURI The URI for the NFT metadata (can be updated later for dynamic changes).
    /// @param _initialTraits Initial traits of the NFT (can be JSON or other string format).
    function mintNFT(address _to, string memory _tokenURI, string memory _initialTraits) public onlyOwner {
        totalSupply++;
        uint256 tokenId = totalSupply;
        tokenOwner[tokenId] = _to;
        tokenTraits[tokenId] = _initialTraits;
        tokenMetadata[tokenId] = _tokenURI;
        exists[tokenId] = true;
        emit NFTMinted(tokenId, _to, _tokenURI, _initialTraits);
    }

    /// @notice Sets the base URI for NFT metadata.
    /// @param _baseURI The new base URI.
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Updates the metadata for a specific NFT, potentially triggering dynamic trait changes.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newMetadata The new metadata URI.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadata) public onlyOwner { // Or allow token owner to update (with restrictions)
        require(exists[_tokenId], "NFT does not exist.");
        tokenMetadata[_tokenId] = _newMetadata;
        emit MetadataUpdated(_tokenId, _newMetadata);
        // You can add logic here to trigger dynamic trait changes based on metadata update
    }

    /// @notice Transfers ownership of an NFT.
    /// @param _from The current owner of the NFT.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) public {
        require(tokenOwner[_tokenId] == _from, "Not the owner of this NFT.");
        tokenOwner[_tokenId] = _to;
        // Consider adding event for NFT transfer
    }

    /// @notice Burns a specific NFT, removing it from circulation.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public onlyOwner {
        require(exists[_tokenId], "NFT does not exist.");
        delete tokenOwner[_tokenId];
        delete tokenTraits[_tokenId];
        delete tokenMetadata[_tokenId];
        delete exists[_tokenId];
        // Consider adding event for NFT burned
    }

    // ** 2. Marketplace Listing and Trading Functions **

    /// @notice Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price to list the NFT for (in wei).
    function listItem(uint256 _tokenId, uint256 _price) public {
        require(exists[_tokenId], "NFT does not exist.");
        require(tokenOwner[_tokenId] == msg.sender, "Not the owner of this NFT.");
        require(!nftListings[_tokenId].isActive, "NFT already listed.");
        require(!nftAuctions[_tokenId].isActive, "NFT is in auction.");

        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListed(_tokenId, _price, msg.sender);
    }

    /// @notice Allows anyone to purchase a listed NFT.
    /// @param _tokenId The ID of the NFT to purchase.
    function purchaseNFT(uint256 _tokenId) public payable {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds.");

        uint256 fee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - fee;

        listing.isActive = false;
        tokenOwner[_tokenId] = msg.sender;

        payable(listing.seller).transfer(sellerAmount);
        payable(owner).transfer(fee); // Marketplace fee goes to contract owner

        emit NFTPurchased(_tokenId, msg.sender, listing.price);
    }

    /// @notice Creates an auction for an NFT with a starting bid and duration.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingBid The starting bid price (in wei).
    /// @param _auctionDuration The duration of the auction in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public {
        require(exists[_tokenId], "NFT does not exist.");
        require(tokenOwner[_tokenId] == msg.sender, "Not the owner of this NFT.");
        require(!nftListings[_tokenId].isActive, "NFT is already listed for sale.");
        require(!nftAuctions[_tokenId].isActive, "NFT is already in auction.");

        nftAuctions[_tokenId] = Auction({
            startingBid: _startingBid,
            endTime: block.timestamp + _auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            seller: msg.sender,
            isActive: true
        });
        emit AuctionCreated(_tokenId, _startingBid, block.timestamp + _auctionDuration, msg.sender);
    }

    /// @notice Allows users to place bids on an active auction.
    /// @param _tokenId The ID of the NFT auction.
    function bidOnAuction(uint256 _tokenId) public payable {
        require(nftAuctions[_tokenId].isActive, "Auction is not active.");
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");
        require(msg.value >= auction.startingBid || auction.highestBid > 0, "Bid must be at least the starting bid.");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Refund previous bidder
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(_tokenId, msg.sender, msg.value);
    }

    /// @notice Finalizes an auction, transferring the NFT to the highest bidder and distributing funds.
    /// @param _tokenId The ID of the NFT auction.
    function finalizeAuction(uint256 _tokenId) public {
        require(nftAuctions[_tokenId].isActive, "Auction is not active.");
        Auction storage auction = nftAuctions[_tokenId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");

        auction.isActive = false;
        uint256 finalPrice = auction.highestBid;
        address winner = auction.highestBidder;

        if (winner != address(0)) {
            uint256 fee = (finalPrice * marketplaceFeePercentage) / 100;
            uint256 sellerAmount = finalPrice - fee;

            tokenOwner[_tokenId] = winner;
            payable(auction.seller).transfer(sellerAmount);
            payable(owner).transfer(fee); // Marketplace fee goes to contract owner
            emit AuctionFinalized(_tokenId, winner, finalPrice);
        } else {
            // No bids, auction ends without sale
            // Optionally, return NFT to seller or handle differently
        }
    }

    /// @notice Cancels an active listing for an NFT.
    /// @param _tokenId The ID of the NFT listing to cancel.
    function cancelListing(uint256 _tokenId) public {
        require(nftListings[_tokenId].isActive, "NFT is not listed.");
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can cancel listing.");
        nftListings[_tokenId].isActive = false;
        emit ListingCancelled(_tokenId);
    }

    /// @notice DAO-governed function to set the marketplace fee percentage.
    /// @param _newFeePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyDAO {
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeUpdated(_newFeePercentage, msg.sender);
        // This would ideally be controlled by a more robust DAO proposal and execution process.
    }

    // ** 3. Dynamic NFT Traits and Evolution Functions **

    /// @notice Triggers the evolution of an NFT based on predefined conditions (example: time-based).
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFT(uint256 _tokenId) public {
        require(exists[_tokenId], "NFT does not exist.");
        require(tokenOwner[_tokenId] == msg.sender, "Only owner can evolve NFT.");

        // Example evolution logic (can be much more complex):
        string memory currentTraits = tokenTraits[_tokenId];
        // Parse currentTraits (e.g., if it's JSON) and update traits based on some logic
        // For example, after a certain time, upgrade a "level" trait or change an appearance trait.
        string memory newTraits = string(abi.encodePacked(currentTraits, ", evolved at time: ", block.timestamp)); // Simple append for example
        tokenTraits[_tokenId] = newTraits;
        emit NFTEvolved(_tokenId, newTraits);

        // Optionally, update metadata URI to reflect trait changes
        updateNFTMetadata(_tokenId, string(abi.encodePacked(baseURI, "/", _tokenId, "?traits=", newTraits)));
    }

    /// @notice Sets a specific trait for an NFT.
    /// @param _tokenId The ID of the NFT to set the trait for.
    /// @param _traitName The name of the trait.
    /// @param _traitValue The value of the trait.
    function setNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) public onlyOwner { // Or owner can delegate this
        require(exists[_tokenId], "NFT does not exist.");
        // Implement logic to update traits string based on _traitName and _traitValue
        // Example: If traits are stored as JSON, parse, update, and serialize back.
        string memory currentTraits = tokenTraits[_tokenId];
        string memory newTraits = string(abi.encodePacked(currentTraits, ", ", _traitName, ": ", _traitValue)); // Simple append for example
        tokenTraits[_tokenId] = newTraits;
        emit NFTTraitSet(_tokenId, _traitName, _traitValue);
        // Optionally, update metadata URI to reflect trait changes
        updateNFTMetadata(_tokenId, string(abi.encodePacked(baseURI, "/", _tokenId, "?traits=", newTraits)));
    }

    /// @notice Retrieves the current traits of an NFT as a string.
    /// @param _tokenId The ID of the NFT.
    /// @return string The traits of the NFT (format depends on implementation).
    function getNFTTraits(uint256 _tokenId) public view returns (string memory) {
        require(exists[_tokenId], "NFT does not exist.");
        return tokenTraits[_tokenId];
    }

    // ** 4. DAO Governance Functions (Simplified) **

    /// @notice Creates a governance proposal with a description and calldata to execute if passed.
    /// @param _description A description of the proposal.
    /// @param _calldata The calldata to execute if the proposal passes.
    function createProposal(string memory _description, bytes memory _calldata) public onlyDAO {
        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.description = _description;
        proposal.calldata = _calldata;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + 7 days; // Example: 7 days voting period
        emit ProposalCreated(proposalCount, _description, msg.sender);
    }

    /// @notice Allows DAO members to vote on a proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'For' vote, false for 'Against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "Proposal does not exist."); // Check if proposal is initialized
        require(block.timestamp < proposal.endTime, "Voting period has ended.");
        // In a real DAO, you would track votes per voter to prevent multiple votes from same member.
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed proposal if the voting period has ended.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyDAO {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.startTime != 0, "Proposal does not exist.");
        require(block.timestamp >= proposal.endTime, "Voting period is not yet ended.");
        require(!proposal.executed, "Proposal already executed.");

        if (proposal.votesFor > proposal.votesAgainst) { // Simple majority example
            (bool success, ) = address(this).call(proposal.calldata);
            require(success, "Proposal execution failed.");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            // Proposal failed - Optionally emit event
        }
    }

    /// @notice Retrieves the current state of a proposal (active, passed, failed).
    /// @param _proposalId The ID of the proposal.
    /// @return string The state of the proposal.
    function getProposalState(uint256 _proposalId) public view returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.startTime == 0) {
            return "Non-existent";
        } else if (block.timestamp < proposal.endTime) {
            return "Active";
        } else if (proposal.executed) {
            return "Passed and Executed";
        } else if (proposal.votesFor > proposal.votesAgainst) {
            return "Passed (Not Executed)";
        } else {
            return "Failed";
        }
    }

    // ** 5. Social and Community Features Functions (Simplified) **

    /// @notice Allows users to create a profile with a username and bio.
    /// @param _username The username for the profile.
    /// @param _bio A short bio for the profile.
    function createUserProfile(string memory _username, string memory _bio) public {
        require(!userProfiles[msg.sender].exists, "Profile already exists.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Allows a user to follow another user.
    /// @param _userToFollow The address of the user to follow.
    function followUser(address _userToFollow) public {
        require(userProfiles[_userToFollow].exists, "User to follow does not have a profile.");
        followers[msg.sender][_userToFollow] = true;
        emit UserFollowed(msg.sender, _userToFollow);
    }

    /// @notice Allows a user to report another user for moderation purposes.
    /// @param _reportedUser The address of the user being reported.
    /// @param _reason The reason for reporting.
    function reportUser(address _reportedUser, string memory _reason) public {
        require(userProfiles[_reportedUser].exists, "Reported user does not have a profile.");
        emit UserReported(msg.sender, _reportedUser, _reason);
        // In a real application, you would have moderation logic to handle reports.
    }

    /// @notice Allows users to post messages to a community feed.
    /// @param _message The message to post.
    function postToCommunityFeed(string memory _message) public {
        emit CommunityPostCreated(msg.sender, _message);
        // In a real application, you might store messages on-chain (expensive) or use off-chain solutions
        // and just store message hashes on-chain for verification.
    }

    // ** Utility Functions **

    /// @notice Gets the owner of the contract.
    /// @return address The owner address.
    function getOwner() public view returns (address) {
        return owner;
    }

    /// @notice Gets the current marketplace fee percentage.
    /// @return uint256 The marketplace fee percentage.
    function getMarketplaceFeePercentage() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /// @notice Gets the base URI for NFT metadata.
    /// @return string The base URI.
    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    /// @notice Gets the total supply of NFTs.
    /// @return uint256 The total supply.
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /// @notice Gets the owner of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return address The owner address or address(0) if NFT does not exist.
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tokenOwner[_tokenId];
    }

    /// @notice Gets the metadata URI of a specific NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return string The metadata URI.
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(exists[_tokenId], "NFT does not exist.");
        return tokenMetadata[_tokenId];
    }

    /// @notice Gets the listing details for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return Listing The listing details.
    function getListing(uint256 _tokenId) public view returns (Listing memory) {
        return nftListings[_tokenId];
    }

    /// @notice Gets the auction details for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return Auction The auction details.
    function getAuction(uint256 _tokenId) public view returns (Auction memory) {
        return nftAuctions[_tokenId];
    }

    /// @notice Gets the profile of a user.
    /// @param _userAddress The address of the user.
    /// @return UserProfile The user profile.
    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    /// @notice Checks if a user is following another user.
    /// @param _follower The address of the follower.
    /// @param _followedUser The address of the user being followed.
    /// @return bool True if _follower is following _followedUser, false otherwise.
    function isFollowing(address _follower, address _followedUser) public view returns (bool) {
        return followers[_follower][_followedUser];
    }
}
```