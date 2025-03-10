```solidity
/**
 * @title Dynamic NFT Marketplace with AI Personalization & DAO Governance
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing an advanced NFT marketplace with dynamic NFTs,
 *      AI-powered personalization (simulated on-chain), and DAO governance for platform evolution.
 *
 * **Outline and Function Summary:**
 *
 * **1. Collection Management:**
 *    - `createCollection(string _name, string _symbol, address _royaltyRecipient, uint256 _royaltyFee)`: Allows platform admin to create new NFT collections with name, symbol, royalty settings.
 *    - `approveCollection(address _collectionAddress)`: DAO-governed function to approve a collection for listing on the marketplace.
 *    - `isCollectionApproved(address _collectionAddress) view returns (bool)`: Checks if a collection is approved.
 *
 * **2. NFT Listing and Trading:**
 *    - `listItem(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale.
 *    - `buyItem(address _collectionAddress, uint256 _tokenId)`: Allows users to purchase listed NFTs.
 *    - `delistItem(address _collectionAddress, uint256 _tokenId)`: Allows NFT owners to delist their NFTs.
 *    - `updateListingPrice(address _collectionAddress, uint256 _tokenId, uint256 _newPrice)`: Allows NFT owners to update the price of their listed NFTs.
 *    - `offerItem(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Allows users to make offers on NFTs (even if not listed).
 *    - `acceptOffer(address _collectionAddress, uint256 _tokenId, address _offerer)`: Allows NFT owners to accept specific offers.
 *    - `cancelOffer(address _collectionAddress, uint256 _tokenId, address _offerer)`: Allows offerers to cancel their offers.
 *    - `batchBuyItems(Listing[] calldata _listings)`: Allows users to buy multiple NFTs in a single transaction.
 *
 * **3. Dynamic NFT Functionality (Simulated AI Influence):**
 *    - `triggerDynamicEvent(address _collectionAddress, uint256 _tokenId, uint256 _eventType)`: Simulates an external event that can dynamically update NFT metadata (controlled by admin/DAO).
 *    - `getNFTDynamicMetadata(address _collectionAddress, uint256 _tokenId) view returns (string)`: Retrieves the dynamic metadata URI for an NFT based on its current state.
 *
 * **4. AI-Powered Personalization (Simulated On-Chain):**
 *    - `setUserPreferences(string _preferences)`: Allows users to set their preferences (simulated input for AI).
 *    - `getUserPreferences(address _user) view returns (string)`: Retrieves a user's preferences.
 *    - `recommendNFTs(address _user) view returns (Listing[])`: Simulates AI recommendation engine to suggest NFTs based on user preferences and marketplace data.
 *    - `getTrendingNFTs() view returns (Listing[])`: Returns a list of NFTs considered "trending" based on simulated on-chain activity.
 *
 * **5. DAO Governance & Platform Management:**
 *    - `createProposal(string _title, string _description, bytes _calldata)`: Allows DAO members to create proposals for platform changes.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to vote on proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed proposal (after quorum and approval).
 *    - `setPlatformFee(uint256 _newFee)`: DAO-governed function to set the platform fee percentage.
 *    - `withdrawPlatformFees(address _recipient)`: Allows platform admin/DAO to withdraw accumulated platform fees.
 *    - `pauseMarketplace()`: DAO-governed function to pause all marketplace operations.
 *    - `unpauseMarketplace()`: DAO-governed function to resume marketplace operations.
 *
 * **6. Utility and View Functions:**
 *    - `getListing(address _collectionAddress, uint256 _tokenId) view returns (Listing)`: Retrieves listing details for a specific NFT.
 *    - `getCollectionListings(address _collectionAddress) view returns (Listing[])`: Retrieves all active listings for a specific collection.
 *    - `getUserListings(address _user) view returns (Listing[])`: Retrieves all listings created by a specific user.
 *    - `getPlatformFee() view returns (uint256)`: Returns the current platform fee percentage.
 *    - `getTotalPlatformFees() view returns (uint256)`: Returns the total accumulated platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIds;

    // Platform Fee (in percentage, e.g., 200 for 2%)
    uint256 public platformFee = 200;
    uint256 public totalPlatformFees;

    // DAO Governance Parameters (Simplified)
    uint256 public proposalQuorum = 50; // Percentage of DAO members required for quorum
    uint256 public proposalVotingPeriod = 7 days; // Voting period in seconds

    // Data Structures
    struct Collection {
        string name;
        string symbol;
        address royaltyRecipient;
        uint256 royaltyFee;
        bool approved;
    }

    struct Listing {
        address collectionAddress;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Offer {
        address offerer;
        uint256 price;
        bool isActive;
    }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        bytes calldataData; // Calldata for execution
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    // Mappings and Arrays
    mapping(address => Collection) public collections;
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => mapping(uint256 => mapping(address => Offer))) public offers; // Collection -> Token -> Offerer -> Offer
    mapping(uint256 => Proposal) public proposals;
    mapping(address => string) public userPreferences; // Simulated user preferences for AI
    mapping(address => bool) public approvedCollections; // Collections approved by DAO
    address[] public daoMembers; // Simplified DAO member list (for demonstration)
    Listing[] public trendingNFTs; // Simulated trending NFTs
    bool public marketplacePaused = false;

    // Events
    event CollectionCreated(address collectionAddress, string name, string symbol, address royaltyRecipient, uint256 royaltyFee);
    event CollectionApproved(address collectionAddress);
    event ItemListed(address collectionAddress, uint256 tokenId, address seller, uint256 price);
    event ItemBought(address collectionAddress, uint256 tokenId, address buyer, uint256 price);
    event ItemDelisted(address collectionAddress, uint256 tokenId, address seller);
    event ListingPriceUpdated(address collectionAddress, uint256 tokenId, uint256 newPrice);
    event ItemOffered(address collectionAddress, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(address collectionAddress, uint256 tokenId, address seller, address offerer, uint256 price);
    event OfferCancelled(address collectionAddress, uint256 tokenId, address offerer);
    event DynamicEventTriggered(address collectionAddress, uint256 tokenId, uint256 eventType);
    event UserPreferencesSet(address user, string preferences);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event PlatformFeeUpdated(uint256 newFee);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // Modifiers
    modifier onlyApprovedCollection(address _collectionAddress) {
        require(isCollectionApproved(_collectionAddress), "Collection not approved for marketplace.");
        _;
    }

    modifier onlyListedItem(address _collectionAddress, uint256 _tokenId) {
        require(listings[_collectionAddress][_tokenId].isActive, "Item not listed.");
        _;
    }

    modifier onlyItemOwner(address _collectionAddress, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not item owner.");
        _;
    }

    modifier onlySeller(address _collectionAddress, uint256 _tokenId) {
        require(listings[_collectionAddress][_tokenId].seller == msg.sender, "Not listing seller.");
        _;
    }

    modifier onlyDAOMember() {
        bool isMember = false;
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Not a DAO member.");
        _;
    }

    modifier notPaused() {
        require(!marketplacePaused, "Marketplace is paused.");
        _;
    }

    constructor() payable Ownable() {
        // Initialize DAO members (for demonstration, owner is also a DAO member)
        daoMembers.push(owner());
    }

    // --------------------------------------------------
    // 1. Collection Management
    // --------------------------------------------------

    function createCollection(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint256 _royaltyFee // In basis points (e.g., 200 for 2%)
    ) public onlyOwner {
        // For simplicity, collection address is implicitly derived (could be deployed externally and then registered)
        address collectionAddress = address(0); // Placeholder for demonstration - in real world, collection address is pre-existing or deployed separately.
        collections[collectionAddress] = Collection({
            name: _name,
            symbol: _symbol,
            royaltyRecipient: _royaltyRecipient,
            royaltyFee: _royaltyFee,
            approved: false // Initially not approved, needs DAO approval
        });
        emit CollectionCreated(collectionAddress, _name, _symbol, _royaltyRecipient, _royaltyFee);
    }

    function approveCollection(address _collectionAddress) public onlyDAOMember {
        require(!isCollectionApproved(_collectionAddress), "Collection already approved.");
        collections[_collectionAddress].approved = true;
        approvedCollections[_collectionAddress] = true;
        emit CollectionApproved(_collectionAddress);
    }

    function isCollectionApproved(address _collectionAddress) public view returns (bool) {
        return approvedCollections[_collectionAddress];
    }


    // --------------------------------------------------
    // 2. NFT Listing and Trading
    // --------------------------------------------------

    function listItem(address _collectionAddress, uint256 _tokenId, uint256 _price)
        public
        notPaused
        onlyApprovedCollection(_collectionAddress)
        onlyItemOwner(_collectionAddress, _tokenId)
        nonReentrant
    {
        IERC721 nftContract = IERC721(_collectionAddress);
        // Approve marketplace to transfer NFT (if not already approved)
        if (nftContract.getApproved(_tokenId) != address(this)) {
            nftContract.approve(address(this), _tokenId);
        }

        listings[_collectionAddress][_tokenId] = Listing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        emit ItemListed(_collectionAddress, _tokenId, msg.sender, _price);
    }

    function buyItem(address _collectionAddress, uint256 _tokenId)
        public
        payable
        notPaused
        onlyApprovedCollection(_collectionAddress)
        onlyListedItem(_collectionAddress, _tokenId)
        nonReentrant
    {
        Listing storage listing = listings[_collectionAddress][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds.");

        IERC721 nftContract = IERC721(_collectionAddress);

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Calculate and distribute funds
        uint256 platformFeeAmount = (listing.price * platformFee) / 10000;
        uint256 royaltyFeeAmount = 0;

        // Check for royalty interface (IERC2981)
        IERC2981 royaltyContract = IERC2981(_collectionAddress);
        (address royaltyRecipient, uint256 royaltyValue) = royaltyContract.getRoyalties(listing.tokenId, listing.price);
        if (royaltyValue > 0) {
            royaltyFeeAmount = royaltyValue;
            payable(collections[_collectionAddress].royaltyRecipient).transfer(royaltyFeeAmount);
        }

        uint256 sellerProceeds = listing.price - platformFeeAmount - royaltyFeeAmount;
        payable(listing.seller).transfer(sellerProceeds);

        totalPlatformFees += platformFeeAmount;

        // Deactivate listing
        listing.isActive = false;
        emit ItemBought(_collectionAddress, _tokenId, msg.sender, listing.price);
    }

    function delistItem(address _collectionAddress, uint256 _tokenId)
        public
        notPaused
        onlyApprovedCollection(_collectionAddress)
        onlyListedItem(_collectionAddress, _tokenId)
        onlySeller(_collectionAddress, _tokenId)
    {
        listings[_collectionAddress][_tokenId].isActive = false;
        emit ItemDelisted(_collectionAddress, _tokenId, msg.sender);
    }

    function updateListingPrice(address _collectionAddress, uint256 _tokenId, uint256 _newPrice)
        public
        notPaused
        onlyApprovedCollection(_collectionAddress)
        onlyListedItem(_collectionAddress, _tokenId)
        onlySeller(_collectionAddress, _tokenId)
    {
        listings[_collectionAddress][_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_collectionAddress, _tokenId, _newPrice);
    }

    function offerItem(address _collectionAddress, uint256 _tokenId, uint256 _price)
        public
        payable
        notPaused
        onlyApprovedCollection(_collectionAddress)
        nonReentrant
    {
        require(msg.value >= _price, "Insufficient funds for offer.");
        offers[_collectionAddress][_tokenId][msg.sender] = Offer({
            offerer: msg.sender,
            price: _price,
            isActive: true
        });
        emit ItemOffered(_collectionAddress, _tokenId, msg.sender, _price);
    }

    function acceptOffer(address _collectionAddress, uint256 _tokenId, address _offerer)
        public
        notPaused
        onlyApprovedCollection(_collectionAddress)
        onlyItemOwner(_collectionAddress, _tokenId)
        nonReentrant
    {
        require(offers[_collectionAddress][_tokenId][_offerer].isActive, "Offer is not active.");
        Offer storage offer = offers[_collectionAddress][_tokenId][_offerer];
        uint256 offerPrice = offer.price;

        IERC721 nftContract = IERC721(_collectionAddress);
        // Approve marketplace to transfer NFT (if not already approved)
        if (nftContract.getApproved(_tokenId) != address(this)) {
            nftContract.approve(address(this), _tokenId);
        }
        nftContract.safeTransferFrom(msg.sender, offer.offerer, _tokenId);

        // Calculate and distribute funds (similar to buyItem logic, potentially simplified)
        uint256 platformFeeAmount = (offerPrice * platformFee) / 10000;
        uint256 royaltyFeeAmount = 0;

        // Check for royalty interface (IERC2981)
        IERC2981 royaltyContract = IERC2981(_collectionAddress);
        (address royaltyRecipient, uint256 royaltyValue) = royaltyContract.getRoyalties(_tokenId, offerPrice);
        if (royaltyValue > 0) {
            royaltyFeeAmount = royaltyValue;
            payable(collections[_collectionAddress].royaltyRecipient).transfer(royaltyFeeAmount);
        }

        uint256 sellerProceeds = offerPrice - platformFeeAmount - royaltyFeeAmount;
        payable(msg.sender).transfer(sellerProceeds);

        totalPlatformFees += platformFeeAmount;

        // Deactivate offer and listing (if any)
        offer.isActive = false;
        if (listings[_collectionAddress][_tokenId].isActive) {
            listings[_collectionAddress][_tokenId].isActive = false;
        }

        emit OfferAccepted(_collectionAddress, _tokenId, msg.sender, offer.offerer, offerPrice);

        // Refund any overpayment from the offerer (if any - in real world, offer would be exact price)
        if (msg.value > offerPrice) {
            payable(offer.offerer).transfer(msg.value - offerPrice);
        }
    }

    function cancelOffer(address _collectionAddress, uint256 _tokenId, address _offerer)
        public
        notPaused
        onlyApprovedCollection(_collectionAddress)
    {
        require(msg.sender == _offerer, "Only offerer can cancel.");
        require(offers[_collectionAddress][_tokenId][_offerer].isActive, "Offer is not active.");
        offers[_collectionAddress][_tokenId][_offerer].isActive = false;
        emit OfferCancelled(_collectionAddress, _offerer);
    }

    struct ListingBatchItem {
        address collectionAddress;
        uint256 tokenId;
    }
    struct ListingBatch {
        ListingBatchItem[] items;
    }

    function batchBuyItems(ListingBatch calldata _batch)
        public
        payable
        notPaused
        nonReentrant
    {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _batch.items.length; i++) {
            ListingBatchItem memory item = _batch.items[i];
            require(isCollectionApproved(item.collectionAddress), "Collection not approved in batch.");
            require(listings[item.collectionAddress][item.tokenId].isActive, "Item not listed in batch.");
            totalValue += listings[item.collectionAddress][item.tokenId].price;
        }
        require(msg.value >= totalValue, "Insufficient funds for batch buy.");

        uint256 currentPayment = msg.value; // Keep track of remaining payment

        for (uint256 i = 0; i < _batch.items.length; i++) {
            ListingBatchItem memory item = _batch.items[i];
            Listing storage listing = listings[item.collectionAddress][item.tokenId];
            uint256 itemPrice = listing.price;

            // Payment handling for each item (deduct from currentPayment)
            if (currentPayment >= itemPrice) {
                currentPayment -= itemPrice;
            } else {
                // Should not happen if initial check is correct, but for safety.
                revert("Batch buy payment error.");
            }

            IERC721 nftContract = IERC721(item.collectionAddress);
            nftContract.safeTransferFrom(listing.seller, msg.sender, item.tokenId);

            // Calculate and distribute funds (similar to buyItem logic)
            uint256 platformFeeAmount = (itemPrice * platformFee) / 10000;
            uint256 royaltyFeeAmount = 0;

            IERC2981 royaltyContract = IERC2981(item.collectionAddress);
            (address royaltyRecipient, uint256 royaltyValue) = royaltyContract.getRoyalties(item.tokenId, itemPrice);
            if (royaltyValue > 0) {
                royaltyFeeAmount = royaltyValue;
                payable(collections[item.collectionAddress].royaltyRecipient).transfer(royaltyFeeAmount);
            }

            uint256 sellerProceeds = itemPrice - platformFeeAmount - royaltyFeeAmount;
            payable(listing.seller).transfer(sellerProceeds);

            totalPlatformFees += platformFeeAmount;
            listing.isActive = false;
            emit ItemBought(item.collectionAddress, item.tokenId, msg.sender, itemPrice);
        }

        // Refund any remaining payment after batch buy
        if (currentPayment > 0) {
            payable(msg.sender).transfer(currentPayment);
        }
    }


    // --------------------------------------------------
    // 3. Dynamic NFT Functionality (Simulated AI Influence)
    // --------------------------------------------------

    function triggerDynamicEvent(address _collectionAddress, uint256 _tokenId, uint256 _eventType) public onlyOwner {
        // Example: eventType could represent "price surge", "artist collaboration", "community event", etc.
        // In a real application, this could be triggered by an off-chain oracle or AI service.
        // Here, we just emit an event for demonstration.
        emit DynamicEventTriggered(_collectionAddress, _tokenId, _eventType);

        // In a more complex implementation, this function would update on-chain state
        // or call an external oracle to update the NFT's metadata URI dynamically.
        // (e.g., update a state variable that affects getNFTDynamicMetadata)
    }

    function getNFTDynamicMetadata(address _collectionAddress, uint256 _tokenId) public view returns (string) {
        // This is a simplified example. In a real dynamic NFT, the metadata URI would be generated
        // based on on-chain state, external data, or even AI-driven factors.
        // For now, it returns a static URI.

        // Example of dynamic metadata URI generation based on a hypothetical on-chain state
        // (replace with actual dynamic logic)
        // uint256 dynamicState = ...; // Get some dynamic on-chain state related to the NFT
        // string memory baseURI = "ipfs://.../"; // Base IPFS URI for metadata
        // string memory dynamicMetadataURI = string(abi.encodePacked(baseURI, Strings.toString(tokenId), "-", Strings.toString(dynamicState), ".json"));

        // For this example, return a static URI to demonstrate the concept
        return "ipfs://static-dynamic-nft-metadata.json";
    }


    // --------------------------------------------------
    // 4. AI-Powered Personalization (Simulated On-Chain)
    // --------------------------------------------------

    function setUserPreferences(string memory _preferences) public {
        userPreferences[msg.sender] = _preferences;
        emit UserPreferencesSet(msg.sender, _preferences);
    }

    function getUserPreferences(address _user) public view returns (string) {
        return userPreferences[_user];
    }

    function recommendNFTs(address _user) public view returns (Listing[] memory) {
        // **Simplified Recommendation Logic (On-Chain Simulation):**
        // In a real-world scenario, this would involve more complex AI/ML models and off-chain data.
        // Here, we simulate a basic recommendation engine based on user preferences and trending NFTs.

        string memory preferences = getUserPreferences(_user);
        Listing[] memory recommendations = new Listing[](5); // Recommend up to 5 NFTs

        // 1. Check for trending NFTs that might align with preferences (very basic keyword matching)
        uint256 recommendationCount = 0;
        for (uint256 i = 0; i < trendingNFTs.length; i++) {
            if (recommendationCount >= 5) break; // Limit recommendations
            Listing memory trendingListing = trendingNFTs[i];
            // Very basic preference matching (replace with more sophisticated logic)
            if (stringContains(preferences, collections[trendingListing.collectionAddress].name) ||
                stringContains(preferences, collections[trendingListing.collectionAddress].symbol)) {
                recommendations[recommendationCount] = trendingListing;
                recommendationCount++;
            }
        }

        // 2. If not enough recommendations from trending, add some random listings (for demonstration)
        if (recommendationCount < 5) {
            // Iterate through all collections and listings (inefficient in real-world - use indexed data)
            // For demonstration, let's just pick from the first collection for simplicity
            address sampleCollection = address(0); // Replace with a valid sample collection address
            if (isCollectionApproved(sampleCollection)) {
                uint256 tokenId = 1; // Start from tokenId 1 (example)
                while (recommendationCount < 5 && tokenId < 100) { // Limit to first 100 tokens for example
                    if (listings[sampleCollection][tokenId].isActive) {
                        bool alreadyRecommended = false;
                        for(uint256 j=0; j<recommendationCount; j++){
                            if(recommendations[j].collectionAddress == sampleCollection && recommendations[j].tokenId == tokenId){
                                alreadyRecommended = true;
                                break;
                            }
                        }
                        if(!alreadyRecommended){
                            recommendations[recommendationCount] = listings[sampleCollection][tokenId];
                            recommendationCount++;
                        }
                    }
                    tokenId++;
                }
            }
        }

        // Trim the array to the actual number of recommendations
        Listing[] memory finalRecommendations = new Listing[](recommendationCount);
        for(uint256 i=0; i<recommendationCount; i++){
            finalRecommendations[i] = recommendations[i];
        }

        return finalRecommendations;
    }

    function getTrendingNFTs() public view returns (Listing[] memory) {
        // **Simplified Trending NFT Logic (On-Chain Simulation):**
        // In a real-world scenario, trending NFTs would be determined by more complex on-chain activity analysis
        // (volume, price changes, etc.) or even off-chain social media trends.
        // Here, we return a pre-defined list for demonstration.

        // For demonstration, let's assume NFTs from collection address(0) are "trending"
        address trendingCollectionAddress = address(0); // Replace with actual trending collection if applicable
        Listing[] memory currentTrendingNFTs = new Listing[](3); // Example: Top 3 trending NFTs
        uint256 count = 0;
        if (isCollectionApproved(trendingCollectionAddress)) {
            for (uint256 tokenId = 1; tokenId <= 3; tokenId++) { // Example: Token IDs 1, 2, 3 from collection 0 are trending
                if (listings[trendingCollectionAddress][tokenId].isActive) {
                    currentTrendingNFTs[count] = listings[trendingCollectionAddress][tokenId];
                    count++;
                }
            }
        }
        trendingNFTs = currentTrendingNFTs; // Update trendingNFTs for recommendation engine
        return trendingNFTs;
    }

    // --------------------------------------------------
    // 5. DAO Governance & Platform Management
    // --------------------------------------------------

    function createProposal(string memory _title, string memory _description, bytes memory _calldataData) public onlyDAOMember {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            calldataData: _calldataData,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ProposalCreated(proposalId, msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDAOMember {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "Voting period expired.");
        require(!proposal.executed, "Proposal already executed.");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyDAOMember {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalDAOMembers = daoMembers.length;
        uint256 quorumVotesNeeded = (totalDAOMembers * proposalQuorum) / 100;
        require(proposal.votesFor >= quorumVotesNeeded, "Proposal quorum not reached.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved by majority.");

        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Execute proposal call data
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    function setPlatformFee(uint256 _newFee) public onlyDAOMember {
        platformFee = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function withdrawPlatformFees(address _recipient) public onlyDAOMember {
        uint256 amount = totalPlatformFees;
        totalPlatformFees = 0;
        payable(_recipient).transfer(amount);
        emit PlatformFeesWithdrawn(_recipient, amount);
    }

    function pauseMarketplace() public onlyDAOMember {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() public onlyDAOMember {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }


    // --------------------------------------------------
    // 6. Utility and View Functions
    // --------------------------------------------------

    function getListing(address _collectionAddress, uint256 _tokenId) public view returns (Listing memory) {
        return listings[_collectionAddress][_tokenId];
    }

    function getCollectionListings(address _collectionAddress) public view returns (Listing[] memory) {
        uint256 listingCount = 0;
        for (uint256 i = 1; i <= 1000; i++) { // Iterate up to 1000 tokenIds (adjust as needed)
            if (listings[_collectionAddress][i].isActive) {
                listingCount++;
            }
        }
        Listing[] memory collectionListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= 1000; i++) {
            if (listings[_collectionAddress][i].isActive) {
                collectionListings[index] = listings[_collectionAddress][i];
                index++;
            }
        }
        return collectionListings;
    }

    function getUserListings(address _user) public view returns (Listing[] memory) {
        uint256 listingCount = 0;
        for (address collectionAddr in approvedCollections) { // Iterate through approved collections
            for (uint256 i = 1; i <= 1000; i++) { // Iterate up to 1000 tokenIds (adjust as needed)
                if (listings[collectionAddr][i].isActive && listings[collectionAddr][i].seller == _user) {
                    listingCount++;
                }
            }
        }

        Listing[] memory userListings = new Listing[](listingCount);
        uint256 index = 0;
        for (address collectionAddr in approvedCollections) {
            for (uint256 i = 1; i <= 1000; i++) {
                if (listings[collectionAddr][i].isActive && listings[collectionAddr][i].seller == _user) {
                    userListings[index] = listings[collectionAddr][i];
                    index++;
                }
            }
        }
        return userListings;
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFee;
    }

    function getTotalPlatformFees() public view returns (uint256) {
        return totalPlatformFees;
    }

    // --- Helper function for string contains (basic, for demonstration) ---
    function stringContains(string memory _haystack, string memory _needle) internal pure returns (bool) {
        return stringToBytes(_haystack).indexOf(stringToBytes(_needle)) != -1;
    }

    function stringToBytes(string memory s) internal pure returns (bytes memory) {
        bytes memory b = bytes(s);
        return b;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```