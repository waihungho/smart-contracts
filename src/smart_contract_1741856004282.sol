```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Gamified User Profiles and Reputation System
 * @author Gemini AI (Conceptual Example)
 * @dev This smart contract outlines a decentralized marketplace for Dynamic NFTs, incorporating gamified user profiles,
 *      a reputation system, and basic community governance. It's designed to be creative and showcase advanced
 *      concepts beyond typical open-source examples.
 *
 * **Outline:**
 * 1. **NFT Collection Management:**
 *    - Create NFT Collections with customizable metadata structure.
 *    - Mint NFTs within a collection, allowing dynamic metadata updates.
 *    - Set royalty fees for creators.
 * 2. **Dynamic NFT Features:**
 *    - Define rules for dynamic metadata updates based on on-chain events or oracle data (simulated).
 *    - Trigger dynamic updates based on predefined conditions.
 * 3. **Marketplace Functionality:**
 *    - List NFTs for sale with different listing types (fixed price, auction - basic example).
 *    - Buy NFTs directly or participate in auctions.
 *    - Delist NFTs.
 *    - Offer and accept bids on NFTs.
 * 4. **Gamified User Profiles:**
 *    - Create user profiles with customizable avatars and descriptions.
 *    - Implement experience points (XP) and levels based on marketplace activities (buying, selling, listing, etc.).
 *    - Offer challenges or quests to earn XP and rewards (NFTs, tokens, reputation).
 * 5. **Reputation System:**
 *    - Allow users to upvote or downvote other users based on their marketplace interactions.
 *    - Calculate user reputation score based on votes.
 *    - Reputation can unlock features or influence marketplace visibility.
 * 6. **Community Governance (Basic):**
 *    - Allow users to propose and vote on marketplace feature suggestions or parameter changes.
 *    - Implement basic voting mechanism (e.g., token-weighted voting).
 * 7. **Oracle Integration (Simulated):**
 *    - Demonstrate a mechanism to fetch external data (e.g., NFT rarity, game events) to trigger dynamic NFT updates.
 *    - This example uses a simplified, on-chain "oracle" for demonstration.
 * 8. **Admin and Utility Functions:**
 *    - Pause/Unpause contract for emergency situations.
 *    - Set marketplace fees.
 *    - Withdraw collected fees.
 *
 * **Function Summary:**
 * 1. `createNFTCollection(string _name, string _symbol, string _baseMetadataURI, address _royaltyRecipient, uint256 _royaltyPercentage)`: Allows admin to create a new NFT collection.
 * 2. `mintNFT(address _collectionAddress, address _recipient, string _initialMetadataURI)`: Mints a new NFT within a specified collection.
 * 3. `setCollectionRoyalty(address _collectionAddress, address _royaltyRecipient, uint256 _royaltyPercentage)`: Updates royalty settings for a collection.
 * 4. `defineDynamicRule(address _collectionAddress, uint256 _tokenId, string _triggerEvent, string _metadataUpdate)`: Defines a rule for dynamic metadata update based on a trigger event.
 * 5. `triggerDynamicEvent(address _collectionAddress, uint256 _tokenId, string _eventData)`: Simulates triggering a dynamic event to update NFT metadata.
 * 6. `listNFT(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 * 7. `buyNFT(address _collectionAddress, uint256 _tokenId)`: Allows a user to buy a listed NFT.
 * 8. `delistNFT(address _collectionAddress, uint256 _tokenId)`: Allows the NFT owner to delist their NFT from the marketplace.
 * 9. `offerBid(address _collectionAddress, uint256 _tokenId)`: Allows a user to place a bid on an NFT (basic auction example).
 * 10. `acceptBid(address _collectionAddress, uint256 _tokenId, address _bidder)`: Allows the NFT owner to accept a bid.
 * 11. `createUserProfile(string _avatarURI, string _description)`: Creates a user profile with avatar and description.
 * 12. `updateUserProfile(string _avatarURI, string _description)`: Updates an existing user profile.
 * 13. `getUserProfile(address _user)`: Retrieves the profile information of a user.
 * 14. `completeChallenge(string _challengeId)`: Allows a user to claim completion of a challenge and earn XP/rewards.
 * 15. `upvoteUser(address _targetUser)`: Allows a user to upvote another user's reputation.
 * 16. `downvoteUser(address _targetUser)`: Allows a user to downvote another user's reputation.
 * 17. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 18. `proposeFeature(string _proposalTitle, string _proposalDescription)`: Allows users to propose new features or changes.
 * 19. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on a feature proposal.
 * 20. `setOracleData(string _dataKey, string _dataValue)`: (Simulated Oracle) Allows admin to set oracle data for dynamic NFT updates.
 * 21. `pauseContract()`: Allows admin to pause the contract.
 * 22. `unpauseContract()`: Allows admin to unpause the contract.
 * 23. `setMarketplaceFee(uint256 _feePercentage)`: Allows admin to set the marketplace fee percentage.
 * 24. `withdrawFees()`: Allows admin to withdraw accumulated marketplace fees.
 * 25. `getListingDetails(address _collectionAddress, uint256 _tokenId)`: Retrieves listing details for an NFT.
 * 26. `getCollectionDetails(address _collectionAddress)`: Retrieves details of an NFT collection.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Structs and Enums ---

    struct NFTCollection {
        string name;
        string symbol;
        string baseMetadataURI;
        address royaltyRecipient;
        uint256 royaltyPercentage; // Percentage (e.g., 500 for 5%)
        address contractAddress;
    }

    struct NFTListing {
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isListed;
    }

    struct UserProfile {
        string avatarURI;
        string description;
        uint256 experiencePoints;
        uint256 reputationScore;
    }

    struct DynamicRule {
        string triggerEvent;
        string metadataUpdate; // Could be a URI, or a function call instruction (more complex)
    }

    enum ListingStatus { NotListed, Listed, Sold }

    struct FeatureProposal {
        string title;
        string description;
        address proposer;
        uint256 upvotes;
        uint256 downvotes;
        ProposalStatus status;
    }

    enum ProposalStatus { Pending, Approved, Rejected }


    // --- State Variables ---

    mapping(address => NFTCollection) public nftCollections;
    mapping(address => mapping(uint256 => NFTListing)) public nftListings;
    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(uint256 => mapping(string => DynamicRule))) public dynamicRules; // collection -> tokenId -> event -> rule
    mapping(address => uint256) public reputationScores; // User reputation scores
    mapping(uint256 => FeatureProposal) public featureProposals;
    mapping(string => string) public oracleData; // Simulated oracle data storage

    Counters.Counter private _collectionCounter;
    Counters.Counter private _proposalCounter;

    uint256 public marketplaceFeePercentage = 200; // Default 2% fee (200 basis points)
    address public feeRecipient;

    // --- Events ---

    event CollectionCreated(address collectionAddress, string name, string symbol, address creator);
    event NFTMinted(address collectionAddress, uint256 tokenId, address recipient);
    event NFTListed(address collectionAddress, uint256 tokenId, uint256 price, address seller);
    event NFTBought(address collectionAddress, uint256 tokenId, address buyer, uint256 price);
    event NFTDelisted(address collectionAddress, uint256 tokenId, address seller);
    event DynamicRuleDefined(address collectionAddress, uint256 tokenId, string triggerEvent, string metadataUpdate);
    event DynamicEventTriggered(address collectionAddress, uint256 tokenId, string eventData);
    event UserProfileCreated(address user, string avatarURI);
    event UserProfileUpdated(address user, string avatarURI);
    event ReputationUpdated(address user, int256 reputationChange);
    event FeatureProposalCreated(uint256 proposalId, string title, address proposer);
    event FeatureProposalVoted(uint256 proposalId, address voter, bool vote);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event MarketplaceFeeUpdated(uint256 feePercentage, address admin);
    event FeesWithdrawn(uint256 amount, address recipient);

    // --- Constructor ---
    constructor() {
        feeRecipient = msg.sender; // Initially set fee recipient to contract deployer
    }


    // --- Modifiers ---
    modifier onlyAdminOrRoyaltyRecipient(address _collectionAddress) {
        require(msg.sender == owner() || msg.sender == nftCollections[_collectionAddress].royaltyRecipient, "Not admin or royalty recipient");
        _;
    }

    modifier validCollection(address _collectionAddress) {
        require(nftCollections[_collectionAddress].contractAddress != address(0), "Invalid collection address");
        _;
    }

    modifier validNFT(address _collectionAddress, uint256 _tokenId) {
        require(ERC721(_collectionAddress).ownerOf(_tokenId) != address(0), "Invalid NFT");
        _;
    }

    modifier isOwnerOrApproved(address _collectionAddress, uint256 _tokenId) {
        require(ERC721(_collectionAddress).ownerOf(_tokenId) == msg.sender || ERC721(_collectionAddress).getApproved(_tokenId) == msg.sender || ERC721(_collectionAddress).isApprovedForAll(ERC721(_collectionAddress).ownerOf(_tokenId), msg.sender), "Not NFT owner or approved");
        _;
    }

    modifier isNFTListed(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].isListed, "NFT is not listed");
        _;
    }

    modifier isNFTNotListed(address _collectionAddress, uint256 _tokenId) {
        require(!nftListings[_collectionAddress][_tokenId].isListed, "NFT is already listed");
        _;
    }

    modifier isSeller(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].seller == msg.sender, "Not the seller");
        _;
    }

    modifier notSeller(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].seller != msg.sender, "Seller cannot perform this action");
        _;
    }

    modifier profileExists(address _user) {
        require(bytes(userProfiles[_user].avatarURI).length > 0, "User profile does not exist");
        _;
    }

    modifier profileDoesNotExist(address _user) {
        require(bytes(userProfiles[_user].avatarURI).length == 0, "User profile already exists");
        _;
    }


    // --- NFT Collection Management Functions ---

    function createNFTCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseMetadataURI,
        address _royaltyRecipient,
        uint256 _royaltyPercentage
    ) public onlyOwner whenNotPaused returns (address collectionAddress) {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%"); // Max 100% royalty
        require(_royaltyRecipient != address(0), "Royalty recipient address cannot be zero");

        Counters.increment(_collectionCounter);
        address newCollectionAddress = address(new DynamicNFTCollection(
            _name,
            _symbol,
            _baseMetadataURI,
            address(this) // Marketplace contract as owner for initial control if needed
        ));

        nftCollections[newCollectionAddress] = NFTCollection({
            name: _name,
            symbol: _symbol,
            baseMetadataURI: _baseMetadataURI,
            royaltyRecipient: _royaltyRecipient,
            royaltyPercentage: _royaltyPercentage,
            contractAddress: newCollectionAddress
        });

        emit CollectionCreated(newCollectionAddress, _name, _symbol, msg.sender);
        return newCollectionAddress;
    }

    function mintNFT(address _collectionAddress, address _recipient, string memory _initialMetadataURI)
        public
        onlyAdminOrRoyaltyRecipient(_collectionAddress)
        validCollection(_collectionAddress)
        whenNotPaused
        returns (uint256 tokenId)
    {
        DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
        tokenId = collection.mintNFT(_recipient, _initialMetadataURI);
        emit NFTMinted(_collectionAddress, tokenId, _recipient);
    }

    function setCollectionRoyalty(address _collectionAddress, address _royaltyRecipient, uint256 _royaltyPercentage)
        public
        onlyOwner
        validCollection(_collectionAddress)
        whenNotPaused
    {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%");
        require(_royaltyRecipient != address(0), "Royalty recipient address cannot be zero");

        nftCollections[_collectionAddress].royaltyRecipient = _royaltyRecipient;
        nftCollections[_collectionAddress].royaltyPercentage = _royaltyPercentage;
    }


    // --- Dynamic NFT Features ---

    function defineDynamicRule(
        address _collectionAddress,
        uint256 _tokenId,
        string memory _triggerEvent,
        string memory _metadataUpdate
    ) public onlyAdminOrRoyaltyRecipient(_collectionAddress) validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) whenNotPaused {
        dynamicRules[_collectionAddress][_tokenId][_triggerEvent] = DynamicRule({
            triggerEvent: _triggerEvent,
            metadataUpdate: _metadataUpdate
        });
        emit DynamicRuleDefined(_collectionAddress, _tokenId, _triggerEvent, _metadataUpdate);
    }

    function triggerDynamicEvent(address _collectionAddress, uint256 _tokenId, string memory _eventData)
        public
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        whenNotPaused
    {
        DynamicRule storage rule = dynamicRules[_collectionAddress][_tokenId][_eventData]; // Simplified event matching
        if (bytes(rule.metadataUpdate).length > 0) {
            DynamicNFTCollection collection = DynamicNFTCollection(_collectionAddress);
            collection.updateTokenMetadataURI(_tokenId, rule.metadataUpdate); // Assuming updateTokenMetadataURI exists in DynamicNFTCollection
            emit DynamicEventTriggered(_collectionAddress, _tokenId, _eventData);
        }
        // In a real scenario, more complex logic for event matching and metadata updates would be needed.
    }


    // --- Marketplace Functionality ---

    function listNFT(address _collectionAddress, uint256 _tokenId, uint256 _price)
        public
        payable
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        isOwnerOrApproved(_collectionAddress, _tokenId)
        isNFTNotListed(_collectionAddress, _tokenId)
        whenNotPaused
    {
        require(_price > 0, "Price must be greater than zero");

        // Transfer NFT to marketplace contract to hold during listing (optional - could also use approval)
        ERC721(_collectionAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        nftListings[_collectionAddress][_tokenId] = NFTListing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListed(_collectionAddress, _tokenId, _price, msg.sender);
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId)
        public
        payable
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        isNFTListed(_collectionAddress, _tokenId)
        notSeller(_collectionAddress, _tokenId)
        whenNotPaused
    {
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(10000);
        uint256 sellerProceeds = listing.price.sub(marketplaceFee);

        // Royalty Calculation
        uint256 royaltyAmount = listing.price.mul(nftCollections[_collectionAddress].royaltyPercentage).div(10000);
        sellerProceeds = sellerProceeds.sub(royaltyAmount);

        // Transfer funds
        payable(feeRecipient).transfer(marketplaceFee);
        payable(nftCollections[_collectionAddress].royaltyRecipient).transfer(royaltyAmount);
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer NFT to buyer
        ERC721(_collectionAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Update listing status
        listing.isListed = false;
        delete nftListings[_collectionAddress][_tokenId]; // Clean up listing data

        emit NFTBought(_collectionAddress, _tokenId, msg.sender, listing.price);

        // Award XP for buying an NFT (Gamification example)
        _awardExperiencePoints(msg.sender, 10);
    }

    function delistNFT(address _collectionAddress, uint256 _tokenId)
        public
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        isNFTListed(_collectionAddress, _tokenId)
        isSeller(_collectionAddress, _tokenId)
        whenNotPaused
    {
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];

        // Transfer NFT back to seller
        ERC721(_collectionAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        // Update listing status
        listing.isListed = false;
        delete nftListings[_collectionAddress][_tokenId]; // Clean up listing data

        emit NFTDelisted(_collectionAddress, _tokenId, msg.sender);
    }

    function offerBid(address _collectionAddress, uint256 _tokenId)
        public
        payable
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        isNFTListed(_collectionAddress, _tokenId) // For simplicity, bidding only on listed NFTs
        notSeller(_collectionAddress, _tokenId)
        whenNotPaused
    {
        // Basic bid handling - could be extended for more complex auction logic
        NFTListing storage listing = nftListings[_collectionAddress][_tokenId];
        require(msg.value > listing.price, "Bid must be greater than current price"); // Example: Bids must exceed current price

        // In a real auction, you'd store bids, handle bid increments, auction timers etc.
        // This is a very simplified example.
        // For now, we'll just consider the bid as a direct purchase if it's above the listed price.
        buyNFT(_collectionAddress, _tokenId); // Directly buy if bid is valid in this simplified case
    }

    function acceptBid(address _collectionAddress, uint256 _tokenId, address _bidder)
        public
        validCollection(_collectionAddress)
        validNFT(_collectionAddress, _tokenId)
        isNFTListed(_collectionAddress, _tokenId)
        isSeller(_collectionAddress, _tokenId)
        whenNotPaused
    {
        // In a more complex auction system, this would handle accepting a specific bidder's bid.
        // In this simplified example (offerBid just triggers buyNFT if price is met),
        // this function is less relevant.  It's included to illustrate potential auction flow.
        // For now, we'll just assume accepting any valid "bid" means accepting a price equal to or above the listed price.
        buyNFT(_collectionAddress, _tokenId); // Accepting any "bid" in this simplified model.
    }


    // --- Gamified User Profiles ---

    function createUserProfile(string memory _avatarURI, string memory _description)
        public
        profileDoesNotExist(msg.sender)
        whenNotPaused
    {
        userProfiles[msg.sender] = UserProfile({
            avatarURI: _avatarURI,
            description: _description,
            experiencePoints: 0,
            reputationScore: 0
        });
        emit UserProfileCreated(msg.sender, _avatarURI);
    }

    function updateUserProfile(string memory _avatarURI, string memory _description)
        public
        profileExists(msg.sender)
        whenNotPaused
    {
        userProfiles[msg.sender].avatarURI = _avatarURI;
        userProfiles[msg.sender].description = _description;
        emit UserProfileUpdated(msg.sender, _avatarURI);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function completeChallenge(string memory _challengeId) public whenNotPaused profileExists(msg.sender) {
        // Example challenge completion logic - replace with actual challenge definitions and rewards.
        if (keccak256(abi.encodePacked(_challengeId)) == keccak256(abi.encodePacked("FIRST_NFT_PURCHASE"))) {
            _awardExperiencePoints(msg.sender, 50); // Example: 50 XP for first NFT purchase challenge
            // Could also reward with NFTs, tokens, etc. here.
        } else if (keccak256(abi.encodePacked(_challengeId)) == keccak256(abi.encodePacked("LIST_FIRST_NFT"))) {
            _awardExperiencePoints(msg.sender, 30); // Example: 30 XP for listing first NFT
        }
        // Add more challenge IDs and corresponding rewards logic here.
    }

    function _awardExperiencePoints(address _user, uint256 _points) internal {
        userProfiles[_user].experiencePoints = userProfiles[_user].experiencePoints.add(_points);
        // Implement leveling up logic based on experience points if needed.
    }


    // --- Reputation System ---

    function upvoteUser(address _targetUser) public whenNotPaused profileExists(msg.sender) profileExists(_targetUser) {
        require(msg.sender != _targetUser, "Cannot upvote yourself");
        reputationScores[_targetUser]++;
        emit ReputationUpdated(_targetUser, 1);
    }

    function downvoteUser(address _targetUser) public whenNotPaused profileExists(msg.sender) profileExists(_targetUser) {
        require(msg.sender != _targetUser, "Cannot downvote yourself");
        reputationScores[_targetUser]--;
        emit ReputationUpdated(_targetUser, -1);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }


    // --- Community Governance (Basic) ---

    function proposeFeature(string memory _proposalTitle, string memory _proposalDescription) public whenNotPaused profileExists(msg.sender) {
        Counters.increment(_proposalCounter);
        uint256 proposalId = _proposalCounter.current();
        featureProposals[proposalId] = FeatureProposal({
            title: _proposalTitle,
            description: _proposalDescription,
            proposer: msg.sender,
            upvotes: 0,
            downvotes: 0,
            status: ProposalStatus.Pending
        });
        emit FeatureProposalCreated(proposalId, _proposalTitle, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused profileExists(msg.sender) {
        require(featureProposals[_proposalId].proposer != address(0), "Invalid proposal ID");
        require(featureProposals[_proposalId].status == ProposalStatus.Pending, "Proposal voting is closed");

        if (_vote) {
            featureProposals[_proposalId].upvotes++;
        } else {
            featureProposals[_proposalId].downvotes++;
        }
        emit FeatureProposalVoted(_proposalId, msg.sender, _vote);

        // Basic approval logic - could be more sophisticated (quorum, time limits etc.)
        if (featureProposals[_proposalId].upvotes > featureProposals[_proposalId].downvotes.mul(2)) { // Example: More than double upvotes than downvotes
            featureProposals[_proposalId].status = ProposalStatus.Approved;
            // Implement action based on approval (e.g., change contract parameter - carefully consider security implications)
        } else if (featureProposals[_proposalId].downvotes > featureProposals[_proposalId].upvotes.mul(2)) {
            featureProposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }


    // --- Oracle Integration (Simulated) ---

    function setOracleData(string memory _dataKey, string memory _dataValue) public onlyOwner whenNotPaused {
        // This is a simplified on-chain "oracle" for demonstration purposes.
        // In a real application, you would use a proper decentralized oracle like Chainlink or Band Protocol.
        oracleData[_dataKey] = _dataValue;
    }

    function getOracleData(string memory _dataKey) public view returns (string memory) {
        return oracleData[_dataKey];
    }


    // --- Admin and Utility Functions ---

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage, msg.sender);
    }

    function withdrawFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(feeRecipient).transfer(balance);
        emit FeesWithdrawn(balance, feeRecipient);
    }

    function setFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Recipient address cannot be zero");
        feeRecipient = _newRecipient;
    }


    // --- Getter/View Functions ---

    function getListingDetails(address _collectionAddress, uint256 _tokenId) public view returns (NFTListing memory) {
        return nftListings[_collectionAddress][_tokenId];
    }

    function getCollectionDetails(address _collectionAddress) public view returns (NFTCollection memory) {
        return nftCollections[_collectionAddress];
    }

    function getProposalDetails(uint256 _proposalId) public view returns (FeatureProposal memory) {
        return featureProposals[_proposalId];
    }

    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }


    // --- Fallback and Receive Functions ---

    receive() external payable {}
    fallback() external payable {}
}


// --- Dynamic NFT Collection Contract (Separate Contract for Each Collection - Example) ---
// --- This is a simplified example and can be further extended (e.g., upgradeable, more features) ---
contract DynamicNFTCollection is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string public baseMetadataURI;

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _marketplaceOwner) ERC721(_name, _symbol) Ownable(address(_marketplaceOwner)) {
        baseMetadataURI = _baseURI;
    }

    function mintNFT(address _recipient, string memory _initialMetadataURI) public onlyOwner returns (uint256) {
        Counters.increment(_tokenIds);
        uint256 newItemId = _tokenIds.current();
        _mint(_recipient, newItemId);
        _setTokenURI(newItemId, _initialMetadataURI); // Initial metadata
        return newItemId;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return string(abi.encodePacked(baseMetadataURI, Strings.toString(tokenId))); // Default to baseURI + tokenId if not explicitly set
    }

    function updateTokenMetadataURI(uint256 _tokenId, string memory _metadataURI) public onlyOwner {
        require(_exists(_tokenId), "Token does not exist");
        _setTokenURI(_tokenId, _metadataURI);
    }

    // Internal function to set token URI (used by both mint and update)
    function _setTokenURI(uint256 tokenId, string memory tokenURI_) internal virtual {
        _tokenURIs[tokenId] = tokenURI_;
    }

    // _tokenURIs is declared private in ERC721Enumerable, so we need to redeclare it here for internal access in _setTokenURI
    mapping(uint256 => string) private _tokenURIs;

    // Override _beforeTokenTransfer to implement royalty payments if needed on direct transfers within the collection.
    // For marketplace sales, royalty is handled in the marketplace contract's buyNFT function.
    // override
    // function _beforeTokenTransfer(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Implement royalty logic here for direct transfers if needed.
    // }

    // Override supportsInterface to indicate support for ERC2981 if needed.
    // function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC721Enumerable) returns (bool) {
    //     return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    // }
}
```