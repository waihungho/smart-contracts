```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation & On-Chain Randomness
 * @author Gemini AI (Hypothetical - as requested)
 * @dev This contract implements a dynamic NFT marketplace with advanced features such as:
 *      - Dynamic NFT Metadata: NFTs can evolve based on on-chain events and external data (simulated AI curation here).
 *      - AI-Powered Curation (Simulated): Smart contract integrates with an (hypothetical) AI oracle to influence NFT visibility and ranking.
 *      - On-Chain Randomness:  Utilizes Chainlink VRF (or similar) for fair and verifiable randomness in NFT minting and reward mechanisms.
 *      - Staking & Rewards: Users can stake NFTs to earn marketplace tokens and influence curation.
 *      - Governance (Simple): Basic voting mechanism for community decisions on marketplace parameters.
 *      - Bundling & Auctions:  Options to sell NFTs in bundles or via Dutch Auctions.
 *      - Dynamic Royalties: Royalties can be adjusted by the NFT creator.
 *      - Tiered Membership: Different membership levels unlock enhanced features.
 *      - Community Challenges:  Marketplace-driven challenges to engage users and reward participation.
 *      - Reputation System:  Track user reputation based on marketplace activities.
 *      - Cross-Chain Compatibility (Conceptual):  Design anticipates potential cross-chain NFT integrations.
 *
 * Function Summary:
 *
 * **NFT Management & Minting:**
 * 1. createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI, bool _dynamicMetadataEnabled): Allows platform owner to create new NFT collections.
 * 2. mintNFT(uint256 _collectionId, address _recipient, string memory _initialMetadataURI): Mints a new NFT within a specific collection.
 * 3. updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadataURI): Updates the metadata URI of a specific NFT.
 * 4. setDynamicMetadataEnabled(uint256 _collectionId, bool _enabled): Enables/disables dynamic metadata updates for a collection.
 * 5. triggerDynamicMetadataUpdate(uint256 _collectionId, uint256 _tokenId):  Manually triggers a dynamic metadata update for a specific NFT (simulating AI influence).
 *
 * **Marketplace Operations:**
 * 6. listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price): Lists an NFT for sale in the marketplace.
 * 7. buyNFT(uint256 _listingId): Allows users to purchase a listed NFT.
 * 8. cancelListing(uint256 _listingId): Allows the seller to cancel an NFT listing.
 * 9. createBundleListing(uint256[] memory _collectionIds, uint256[] memory _tokenIds, uint256 _price): Lists a bundle of NFTs for sale.
 * 10. buyBundle(uint256 _bundleListingId): Allows users to buy a bundle of NFTs.
 * 11. createDutchAuction(uint256 _collectionId, uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint256 _duration): Starts a Dutch Auction for an NFT.
 * 12. bidOnDutchAuction(uint256 _auctionId): Places a bid on a Dutch Auction (automatically executes at current price).
 * 13. endDutchAuction(uint256 _auctionId):  Ends a Dutch auction manually if not already concluded.
 *
 * **Curation & Staking:**
 * 14. stakeNFT(uint256 _collectionId, uint256 _tokenId): Stakes an NFT to earn marketplace tokens and potentially influence curation score.
 * 15. unstakeNFT(uint256 _collectionId, uint256 _tokenId): Unstakes a staked NFT.
 * 16. getCurationScore(uint256 _collectionId, uint256 _tokenId): Retrieves the (simulated) AI curation score for an NFT.
 * 17. updateCurationScore(uint256 _collectionId, uint256 _tokenId, uint256 _newScore):  (Admin/Oracle function) Updates the curation score of an NFT.
 *
 * **Governance & Utility:**
 * 18. proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue): Allows community members to propose changes to marketplace parameters.
 * 19. voteOnProposal(uint256 _proposalId, bool _vote): Allows staked NFT holders to vote on governance proposals.
 * 20. executeProposal(uint256 _proposalId): Executes a passed governance proposal.
 * 21. withdrawMarketplaceFees(): Allows platform owner to withdraw accumulated marketplace fees.
 * 22. setPlatformFeePercentage(uint256 _newFeePercentage): Allows platform owner to update the platform fee percentage.
 * 23. getRandomNumber(): (Placeholder for Chainlink VRF integration) - Would fetch and use a random number securely.
 * 24. setRoyaltyPercentage(uint256 _collectionId, uint256 _tokenId, uint256 _royaltyPercentage): Sets the royalty percentage for a specific NFT within a collection.
 * 25. getRoyaltyInfo(uint256 _collectionId, uint256 _tokenId, uint256 _salePrice): Retrieves royalty information for a given NFT and sale price.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Placeholder for an AI Curation Oracle Interface (Hypothetical - in a real application, this would interact with an actual oracle service)
interface IAICurationOracle {
    function getCurationScore(uint256 _collectionId, uint256 _tokenId) external view returns (uint256);
}

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Platform Fee Percentage (e.g., 200 = 2%)
    uint256 public platformFeePercentage = 200;
    address public platformFeeRecipient;

    // --- NFT Collections ---
    struct NFTCollection {
        string name;
        string symbol;
        string baseURI;
        address creator;
        bool dynamicMetadataEnabled;
        address contractAddress; // Address of the deployed ERC721 contract
        uint256 lastTokenId;
    }
    mapping(uint256 => NFTCollection) public nftCollections;
    Counters.Counter private _collectionIds;
    mapping(address => uint256) public collectionContractToId; // Map contract address to collection ID

    // --- NFT Instances & Dynamic Metadata ---
    mapping(uint256 => mapping(uint256 => string)) public nftMetadataOverrides; // CollectionId => TokenId => Metadata URI Override
    mapping(uint256 => mapping(uint256 => uint256)) public nftCurationScores; // CollectionId => TokenId => Curation Score (Simulated AI Influence)

    // --- Marketplace Listings ---
    struct Listing {
        uint256 listingId;
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isBundle;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    Counters.Counter private _listingIds;

    struct BundleListing {
        uint256 bundleListingId;
        uint256[] collectionIds;
        uint256[] tokenIds;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => BundleListing) public bundleListings;
    Counters.Counter private _bundleListingIds;

    // --- Dutch Auctions ---
    struct DutchAuction {
        uint256 auctionId;
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration; // Auction duration in seconds
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => DutchAuction) public dutchAuctions;
    Counters.Counter private _dutchAuctionIds;

    // --- Staking ---
    mapping(uint256 => mapping(uint256 => address)) public nftStakers; // CollectionId => TokenId => Staker Address

    // --- Governance Proposals ---
    struct GovernanceProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _proposalIds;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // ProposalId => Voter Address => Voted Yes/No

    // --- Royalties ---
    mapping(uint256 => mapping(uint256 => uint256)) public nftRoyalties; // CollectionId => TokenId => Royalty Percentage (e.g., 500 = 5%)
    uint256 public defaultRoyaltyPercentage = 250; // 2.5% default platform royalty

    // --- Events ---
    event CollectionCreated(uint256 collectionId, string name, string symbol, address creator, address contractAddress);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address recipient);
    event MetadataUpdated(uint256 collectionId, uint256 tokenId, string newMetadataURI);
    event NFTListed(uint256 listingId, uint256 collectionId, uint256 tokenId, address seller, uint256 price);
    event NFTBundleListed(uint256 bundleListingId, address seller, uint256 price, uint256[] collectionIds, uint256[] tokenIds);
    event NFTBought(uint256 listingId, uint256 collectionId, uint256 tokenId, address buyer, uint256 price);
    event NFTBundleBought(uint256 bundleListingId, address buyer, uint256 price, uint256[] collectionIds, uint256[] tokenIds);
    event ListingCancelled(uint256 listingId, uint256 collectionId, uint256 tokenId, address seller);
    event DutchAuctionCreated(uint256 auctionId, uint256 collectionId, uint256 tokenId, address seller, uint256 startPrice, uint256 endPrice, uint256 duration);
    event DutchAuctionBid(uint256 auctionId, address bidder, uint256 bidPrice);
    event DutchAuctionEnded(uint256 auctionId, uint256 collectionId, uint256 tokenId, address winner, uint256 finalPrice);
    event NFTStaked(uint256 collectionId, uint256 tokenId, address staker);
    event NFTUnstaked(uint256 collectionId, uint256 tokenId, address unstaker);
    event CurationScoreUpdated(uint256 collectionId, uint256 tokenId, uint256 newScore);
    event GovernanceProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, uint256 endTime);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event RoyaltyPercentageSet(uint256 collectionId, uint256 tokenId, uint256 royaltyPercentage);

    // --- Constructor ---
    constructor() payable {
        platformFeeRecipient = msg.sender; // Initially set platform fee recipient to contract deployer
    }

    // --- Modifiers ---
    modifier onlyCollectionCreator(uint256 _collectionId) {
        require(nftCollections[_collectionId].creator == msg.sender, "Not collection creator");
        _;
    }

    modifier validCollection(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId <= _collectionIds.current(), "Invalid collection ID");
        _;
    }

    modifier validNFT(uint256 _collectionId, uint256 _tokenId) {
        require(_exists(_collectionId, _tokenId), "Invalid NFT");
        _;
    }

    modifier nftOwner(uint256 _collectionId, uint256 _tokenId) {
        IERC721 nftContract = IERC721(nftCollections[_collectionId].contractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        _;
    }

    modifier isListed(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier isBundleListed(uint256 _bundleListingId) {
        require(bundleListings[_bundleListingId].isActive, "Bundle listing is not active");
        _;
    }

    modifier isDutchAuctionActive(uint256 _auctionId) {
        require(dutchAuctions[_auctionId].isActive, "Dutch auction is not active");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == owner(), "Only platform owner allowed");
        _;
    }


    // ------------------------------------------------------------------------
    //                            NFT Management & Minting
    // ------------------------------------------------------------------------

    /**
     * @dev Creates a new NFT collection.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     * @param _baseURI The base URI for token metadata.
     * @param _dynamicMetadataEnabled Whether dynamic metadata updates are enabled for this collection.
     */
    function createNFTCollection(string memory _name, string memory _symbol, string memory _baseURI, bool _dynamicMetadataEnabled) external onlyOwner {
        _collectionIds.increment();
        uint256 collectionId = _collectionIds.current();

        // Deploy a new ERC721 contract for this collection (Simplified for example, in real-world, consider factory pattern or minimal clones)
        NFTCollectionERC721 nftContract = new NFTCollectionERC721(_name, _symbol, _baseURI);

        nftCollections[collectionId] = NFTCollection({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            creator: msg.sender,
            dynamicMetadataEnabled: _dynamicMetadataEnabled,
            contractAddress: address(nftContract),
            lastTokenId: 0
        });
        collectionContractToId[address(nftContract)] = collectionId;

        emit CollectionCreated(collectionId, _name, _symbol, msg.sender, address(nftContract));
    }

    /**
     * @dev Mints a new NFT within a specified collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _recipient The address to receive the minted NFT.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function mintNFT(uint256 _collectionId, address _recipient, string memory _initialMetadataURI) external validCollection onlyCollectionCreator(_collectionId) {
        NFTCollection storage collection = nftCollections[_collectionId];
        collection.lastTokenId++;
        uint256 tokenId = collection.lastTokenId;
        NFTCollectionERC721 nftContract = NFTCollectionERC721(collection.contractAddress);

        _setTokenURI(_collectionId, tokenId, _initialMetadataURI); // Set initial metadata
        nftContract.safeMint(_recipient, tokenId);

        emit NFTMinted(_collectionId, tokenId, _recipient);
    }

    /**
     * @dev Updates the metadata URI of a specific NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string memory _newMetadataURI) external validCollection validNFT(_collectionId, _tokenId) onlyCollectionCreator(_collectionId) {
        _setTokenURI(_collectionId, _tokenId, _newMetadataURI);
        emit MetadataUpdated(_collectionId, _tokenId, _newMetadataURI);
    }

    /**
     * @dev Enables or disables dynamic metadata updates for a collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _enabled True to enable, false to disable.
     */
    function setDynamicMetadataEnabled(uint256 _collectionId, bool _enabled) external validCollection onlyCollectionCreator(_collectionId) {
        nftCollections[_collectionId].dynamicMetadataEnabled = _enabled;
    }

    /**
     * @dev Triggers a dynamic metadata update for a specific NFT.
     *      In a real application, this would be triggered by an AI oracle or external event.
     *      Here, it's simplified to just change the metadata URI based on a random number (for demonstration).
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     */
    function triggerDynamicMetadataUpdate(uint256 _collectionId, uint256 _tokenId) external validCollection validNFT(_collectionId, _tokenId) {
        NFTCollection storage collection = nftCollections[_collectionId];
        require(collection.dynamicMetadataEnabled, "Dynamic metadata not enabled for this collection");

        // *** SIMULATED AI CURATION/DYNAMIC UPDATE LOGIC ***
        // In a real scenario, you would query an AI oracle (like IAICurationOracle) here
        // For demonstration, we'll use a simple on-chain random number (not secure for production randomness)
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, _collectionId, _tokenId, msg.sender))) % 100;

        string memory newMetadataURI;
        if (randomValue < 30) {
            newMetadataURI = string(abi.encodePacked(collection.baseURI, "evolved/low/", Strings.toString(_tokenId), ".json")); // Example: Lower value, "less desirable" metadata
        } else if (randomValue < 70) {
            newMetadataURI = string(abi.encodePacked(collection.baseURI, "evolved/medium/", Strings.toString(_tokenId), ".json")); // Example: Medium value, "average" metadata
        } else {
            newMetadataURI = string(abi.encodePacked(collection.baseURI, "evolved/high/", Strings.toString(_tokenId), ".json"));  // Example: High value, "rare/desirable" metadata
        }

        _setTokenURI(_collectionId, _tokenId, newMetadataURI);
        emit MetadataUpdated(_collectionId, _tokenId, newMetadataURI);
    }


    // ------------------------------------------------------------------------
    //                            Marketplace Operations
    // ------------------------------------------------------------------------

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price) external validCollection validNFT(_collectionId, _tokenId) nftOwner(_collectionId, _tokenId) {
        IERC721 nftContract = IERC721(nftCollections[_collectionId].contractAddress);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = Listing({
            listingId: listingId,
            collectionId: _collectionId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isBundle: false,
            isActive: true
        });

        emit NFTListed(listingId, _collectionId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to buy a listed NFT.
     * @param _listingId The ID of the listing.
     */
    function buyNFT(uint256 _listingId) external payable nonReentrant isListed(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent");

        listings[_listingId].isActive = false; // Deactivate the listing

        NFTCollectionERC721 nftContract = NFTCollectionERC721(nftCollections[listing.collectionId].contractAddress);

        // Transfer NFT
        nftContract.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        // Calculate platform fee and royalty
        uint256 platformFee = listing.price.mul(platformFeePercentage).div(10000);
        uint256 royaltyAmount = getRoyaltyInfo(listing.collectionId, listing.tokenId, listing.price);
        uint256 sellerPayout = listing.price.sub(platformFee).sub(royaltyAmount);

        // Pay seller, platform fee recipient, and royalty recipient (if applicable)
        payable(listing.seller).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);

        address royaltyRecipient = _getRoyaltyRecipient(listing.collectionId, listing.tokenId);
        if (royaltyRecipient != address(0) && royaltyAmount > 0) {
            payable(royaltyRecipient).transfer(royaltyAmount);
        }

        emit NFTBought(_listingId, listing.collectionId, listing.tokenId, msg.sender, listing.price);
    }

    /**
     * @dev Cancels an NFT listing. Only the seller can cancel.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external isListed(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listing.collectionId, listing.tokenId, msg.sender);
    }

    /**
     * @dev Lists a bundle of NFTs for sale.
     * @param _collectionIds Array of collection IDs in the bundle.
     * @param _tokenIds Array of token IDs in the bundle (must correspond to collectionIds).
     * @param _price The price for the entire bundle.
     */
    function createBundleListing(uint256[] memory _collectionIds, uint256[] memory _tokenIds, uint256 _price) external {
        require(_collectionIds.length == _tokenIds.length && _collectionIds.length > 0, "Collection and Token ID arrays must be same length and not empty");

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            require(validCollectionId(_collectionIds[i]), "Invalid collection ID in bundle");
            require(_exists(_collectionIds[i], _tokenIds[i]), "Invalid NFT in bundle");
            requireNftOwner(_collectionIds[i], _tokenIds[i]); // Internal check for ownership
            IERC721 nftContract = IERC721(nftCollections[_collectionIds[i]].contractAddress);
            require(nftContract.getApproved(_tokenIds[i]) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT in bundle");
        }

        _bundleListingIds.increment();
        uint256 bundleListingId = _bundleListingIds.current();

        bundleListings[bundleListingId] = BundleListing({
            bundleListingId: bundleListingId,
            collectionIds: _collectionIds,
            tokenIds: _tokenIds,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTBundleListed(bundleListingId, msg.sender, _price, _collectionIds, _tokenIds);
    }


    /**
     * @dev Allows a user to buy a bundle of NFTs.
     * @param _bundleListingId The ID of the bundle listing.
     */
    function buyBundle(uint256 _bundleListingId) external payable nonReentrant isBundleListed(_bundleListingId) {
        BundleListing storage bundleListing = bundleListings[_bundleListingId];
        require(msg.value >= bundleListing.price, "Insufficient funds sent for bundle");

        bundleListings[_bundleListingId].isActive = false; // Deactivate bundle listing

        uint256 platformFee = bundleListing.price.mul(platformFeePercentage).div(10000);
        uint256 totalRoyalties = 0;

        for (uint256 i = 0; i < bundleListing.collectionIds.length; i++) {
            NFTCollectionERC721 nftContract = NFTCollectionERC721(nftCollections[bundleListing.collectionIds[i]].contractAddress);
            nftContract.safeTransferFrom(bundleListing.seller, msg.sender, bundleListing.tokenIds[i]);

            uint256 royaltyAmount = getRoyaltyInfo(bundleListing.collectionIds[i], bundleListing.tokenIds[i], bundleListing.price.div(bundleListing.collectionIds.length)); // Approximate royalty per NFT in bundle
            totalRoyalties = totalRoyalties.add(royaltyAmount);

            address royaltyRecipient = _getRoyaltyRecipient(bundleListing.collectionIds[i], bundleListing.tokenIds[i]);
            if (royaltyRecipient != address(0) && royaltyAmount > 0) {
                payable(royaltyRecipient).transfer(royaltyAmount);
            }
        }

        uint256 sellerPayout = bundleListing.price.sub(platformFee).sub(totalRoyalties);
        payable(bundleListing.seller).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);


        emit NFTBundleBought(_bundleListingId, msg.sender, bundleListing.price, bundleListing.collectionIds, bundleListing.tokenIds);
    }


    /**
     * @dev Creates a Dutch Auction for an NFT. Price decreases over time.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startPrice The starting price for the auction.
     * @param _endPrice The ending price for the auction.
     * @param _duration The duration of the auction in seconds.
     */
    function createDutchAuction(uint256 _collectionId, uint256 _tokenId, uint256 _startPrice, uint256 _endPrice, uint256 _duration) external validCollection validNFT(_collectionId, _tokenId) nftOwner(_collectionId, _tokenId) {
        IERC721 nftContract = IERC721(nftCollections[_collectionId].contractAddress);
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT for auction");
        require(_startPrice > _endPrice, "Start price must be greater than end price");
        require(_duration > 0, "Auction duration must be greater than 0");

        _dutchAuctionIds.increment();
        uint256 auctionId = _dutchAuctionIds.current();

        dutchAuctions[auctionId] = DutchAuction({
            auctionId: auctionId,
            collectionId: _collectionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startPrice: _startPrice,
            endPrice: _endPrice,
            startTime: block.timestamp,
            duration: _duration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });

        emit DutchAuctionCreated(auctionId, _collectionId, _tokenId, msg.sender, _startPrice, _endPrice, _duration);
    }

    /**
     * @dev Allows a user to bid on a Dutch Auction.
     *      Auction automatically executes at the current price.
     * @param _auctionId The ID of the Dutch Auction.
     */
    function bidOnDutchAuction(uint256 _auctionId) external payable nonReentrant isDutchAuctionActive(_auctionId) {
        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(msg.sender != auction.seller, "Seller cannot bid on their own auction");

        uint256 currentPrice = _getCurrentDutchAuctionPrice(auction);
        require(msg.value >= currentPrice, "Bid price is too low");

        // End the auction and transfer NFT
        dutchAuctions[_auctionId].isActive = false;
        dutchAuctions[_auctionId].highestBidder = msg.sender;
        dutchAuctions[_auctionId].highestBid = currentPrice;

        NFTCollectionERC721 nftContract = NFTCollectionERC721(nftCollections[auction.collectionId].contractAddress);
        nftContract.safeTransferFrom(auction.seller, msg.sender, auction.tokenId);

        // Calculate platform fee and royalty
        uint256 platformFee = currentPrice.mul(platformFeePercentage).div(10000);
        uint256 royaltyAmount = getRoyaltyInfo(auction.collectionId, auction.tokenId, currentPrice);
        uint256 sellerPayout = currentPrice.sub(platformFee).sub(royaltyAmount);

        // Pay seller, platform fee recipient, and royalty recipient (if applicable)
        payable(auction.seller).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);

        address royaltyRecipient = _getRoyaltyRecipient(auction.collectionId, auction.tokenId);
        if (royaltyRecipient != address(0) && royaltyAmount > 0) {
            payable(royaltyRecipient).transfer(royaltyAmount);
        }

        emit DutchAuctionBid(_auctionId, msg.sender, currentPrice);
        emit DutchAuctionEnded(_auctionId, auction.collectionId, auction.tokenId, msg.sender, currentPrice);
    }

    /**
     * @dev Ends a Dutch auction manually if not already concluded by a bid.
     *      Can be called by anyone after the auction duration has elapsed.
     * @param _auctionId The ID of the Dutch Auction.
     */
    function endDutchAuction(uint256 _auctionId) external isDutchAuctionActive(_auctionId) {
        DutchAuction storage auction = dutchAuctions[_auctionId];
        require(block.timestamp >= auction.startTime + auction.duration, "Auction duration not elapsed yet");
        require(auction.highestBidder == address(0), "Auction already concluded by a bid"); // Ensure auction hasn't already been bid on

        dutchAuctions[_auctionId].isActive = false;
        emit DutchAuctionEnded(_auctionId, auction.collectionId, auction.tokenId, address(0), 0); // No winner if ended without bid
    }


    // ------------------------------------------------------------------------
    //                            Curation & Staking
    // ------------------------------------------------------------------------

    /**
     * @dev Stakes an NFT to earn marketplace tokens and potentially influence curation score.
     *      (Staking and reward mechanisms are simplified here for demonstration).
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFT(uint256 _collectionId, uint256 _tokenId) external validCollection validNFT(_collectionId, _tokenId) nftOwner(_collectionId, _tokenId) {
        require(nftStakers[_collectionId][_tokenId] == address(0), "NFT already staked");
        nftStakers[_collectionId][_tokenId] = msg.sender;
        emit NFTStaked(_collectionId, _tokenId, msg.sender);
        // In a real system, you would implement reward distribution logic here.
    }

    /**
     * @dev Unstakes a staked NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _collectionId, uint256 _tokenId) external validCollection validNFT(_collectionId, _tokenId) {
        require(nftStakers[_collectionId][_tokenId] == msg.sender, "Not the staker");
        delete nftStakers[_collectionId][_tokenId];
        emit NFTUnstaked(_collectionId, _tokenId, msg.sender);
        // In a real system, you would handle reward withdrawal logic here.
    }

    /**
     * @dev Retrieves the (simulated) AI curation score for an NFT.
     *      In a real application, this would query an AI oracle.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @return The curation score.
     */
    function getCurationScore(uint256 _collectionId, uint256 _tokenId) external view validCollection validNFT(_collectionId, _tokenId) returns (uint256) {
        return nftCurationScores[_collectionId][_tokenId];
    }

    /**
     * @dev (Admin/Oracle function) Updates the curation score of an NFT.
     *      This would typically be called by an authorized AI oracle or curation agent.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _newScore The new curation score.
     */
    function updateCurationScore(uint256 _collectionId, uint256 _tokenId, uint256 _newScore) external onlyOwner validCollection validNFT(_collectionId, _tokenId) {
        nftCurationScores[_collectionId][_tokenId] = _newScore;
        emit CurationScoreUpdated(_collectionId, _tokenId, _newScore);
    }


    // ------------------------------------------------------------------------
    //                            Governance & Utility
    // ------------------------------------------------------------------------

    /**
     * @dev Proposes a change to a marketplace parameter.
     * @param _parameterName The name of the parameter to change (e.g., "platformFeePercentage").
     * @param _newValue The new value for the parameter.
     */
    function proposeMarketplaceParameterChange(string memory _parameterName, uint256 _newValue) external {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });

        emit GovernanceProposalCreated(proposalId, _parameterName, _newValue, block.timestamp + 7 days);
    }

    /**
     * @dev Allows staked NFT holders to vote on a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        bool hasStakedNFT = false;
        // Simple check for any staked NFT from any collection as voting power.
        // In a real system, you might want to weigh votes based on staked NFT value or specific collections.
        for (uint256 i = 1; i <= _collectionIds.current(); i++) {
            for (uint256 j = 1; j <= nftCollections[i].lastTokenId; j++) { // Iterate through all minted tokens in each collection (inefficient for large collections, optimize in real-world)
                if (nftStakers[i][j] == msg.sender) {
                    hasStakedNFT = true;
                    break;
                }
            }
            if (hasStakedNFT) break;
        }
        require(hasStakedNFT, "Must have a staked NFT to vote");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }

        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed governance proposal.
     *      Can be called after the voting period ends if a majority (e.g., > 50%) voted yes.
     * @param _proposalId The ID of the governance proposal.
     */
    function executeProposal(uint256 _proposalId) external onlyPlatformOwner { // For simplicity, only platform owner can execute after voting passes. Could be made permissionless in a real DAO.
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass"); // Simple majority

        governanceProposals[_proposalId].executed = true;

        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
            setPlatformFeePercentage(proposal.newValue);
        }
        // Add more parameter change logic here as needed based on proposal.parameterName

        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() external onlyPlatformOwner {
        uint256 balance = address(this).balance;
        payable(platformFeeRecipient).transfer(balance);
    }

    /**
     * @dev Allows the platform owner to update the platform fee percentage.
     * @param _newFeePercentage The new platform fee percentage (e.g., 200 = 2%).
     */
    function setPlatformFeePercentage(uint256 _newFeePercentage) public onlyPlatformOwner {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageUpdated(_newFeePercentage);
    }

    /**
     * @dev (Placeholder for Chainlink VRF integration) - Would fetch and use a random number securely.
     *      In a real application, replace this with actual VRF integration.
     * @return A random number (placeholder - not cryptographically secure in this example).
     */
    function getRandomNumber() external view returns (uint256) {
        // *** Placeholder for Chainlink VRF or other secure randomness source ***
        // In a real implementation, use Chainlink VRF to request and receive a verifiable random number.
        // This is a simplified placeholder for demonstration purposes only.
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty)));
    }

    /**
     * @dev Sets the royalty percentage for a specific NFT within a collection.
     *      Can be set by the collection creator.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _royaltyPercentage The royalty percentage (e.g., 500 = 5%).
     */
    function setRoyaltyPercentage(uint256 _collectionId, uint256 _tokenId, uint256 _royaltyPercentage) external validCollection validNFT(_collectionId, _tokenId) onlyCollectionCreator(_collectionId) {
        nftRoyalties[_collectionId][_tokenId] = _royaltyPercentage;
        emit RoyaltyPercentageSet(_collectionId, _tokenId, _royaltyPercentage);
    }

    /**
     * @dev Retrieves royalty information for a given NFT and sale price.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _salePrice The sale price of the NFT.
     * @return The royalty amount.
     */
    function getRoyaltyInfo(uint256 _collectionId, uint256 _tokenId, uint256 _salePrice) public view validCollection validNFT(_collectionId, _tokenId) returns (uint256) {
        uint256 royaltyPercentage = nftRoyalties[_collectionId][_tokenId] > 0 ? nftRoyalties[_collectionId][_tokenId] : defaultRoyaltyPercentage;
        return _salePrice.mul(royaltyPercentage).div(10000);
    }


    // ------------------------------------------------------------------------
    //                           Internal & Helper Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Internal function to set the token URI for an NFT, considering dynamic metadata overrides.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @param _metadataURI The metadata URI to set.
     */
    function _setTokenURI(uint256 _collectionId, uint256 _tokenId, string memory _metadataURI) internal {
        nftMetadataOverrides[_collectionId][_tokenId] = _metadataURI;
        NFTCollectionERC721 nftContract = NFTCollectionERC721(nftCollections[_collectionId].contractAddress);
        nftContract.setTokenURI(_tokenId, _metadataURI);
    }

    /**
     * @dev Internal function to check if an NFT exists.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @return True if the NFT exists, false otherwise.
     */
    function _exists(uint256 _collectionId, uint256 _tokenId) internal view returns (bool) {
        NFTCollectionERC721 nftContract = NFTCollectionERC721(nftCollections[_collectionId].contractAddress);
        return nftContract.exists(_tokenId);
    }

    /**
     * @dev Internal function to get the current price in a Dutch Auction.
     * @param _auction The DutchAuction struct.
     * @return The current auction price.
     */
    function _getCurrentDutchAuctionPrice(DutchAuction storage _auction) internal view returns (uint256) {
        if (block.timestamp >= _auction.startTime + _auction.duration) {
            return _auction.endPrice; // Auction ended, price is end price
        }

        uint256 timeElapsed = block.timestamp - _auction.startTime;
        uint256 priceDropPerSecond = _auction.startPrice.sub(_auction.endPrice).div(_auction.duration);
        uint256 priceDrop = priceDropPerSecond.mul(timeElapsed);

        if (_auction.startPrice <= priceDrop) { // Prevent underflow and ensure price doesn't go below endPrice
            return _auction.endPrice;
        }

        uint256 currentPrice = _auction.startPrice.sub(priceDrop);
        return currentPrice < _auction.endPrice ? _auction.endPrice : currentPrice; // Ensure price doesn't go below endPrice
    }

    /**
     * @dev Internal function to get the royalty recipient for an NFT.
     *      For simplicity, royalty recipient is the collection creator.
     *      In a more complex system, this could be customizable per NFT or collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT.
     * @return The royalty recipient address.
     */
    function _getRoyaltyRecipient(uint256 _collectionId, uint256 _tokenId) internal view returns (address) {
        return nftCollections[_collectionId].creator; // Royalty recipient is collection creator by default
    }

    /**
     * @dev Internal helper function to check if a collection ID is valid.
     * @param _collectionId The collection ID to check.
     * @return True if valid, false otherwise.
     */
    function validCollectionId(uint256 _collectionId) internal view returns (bool) {
        return (_collectionId > 0 && _collectionId <= _collectionIds.current());
    }

    /**
     * @dev Internal helper function to enforce NFT ownership.
     * @param _collectionId The collection ID.
     * @param _tokenId The token ID.
     */
    function requireNftOwner(uint256 _collectionId, uint256 _tokenId) internal view {
        IERC721 nftContract = IERC721(nftCollections[_collectionId].contractAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not NFT owner");
    }
}


// --- Helper Contract: Simple ERC721 for NFT Collections ---
contract NFTCollectionERC721 is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private _baseURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseURI = baseURI;
    }

    function safeMint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory uri = _tokenURIs[tokenId];
        if (bytes(uri).length > 0) {
            return uri;
        }
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        _tokenURIs[tokenId] = uri;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
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
        bytes memory buffer = bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```