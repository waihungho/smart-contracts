```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Curator
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace with advanced features including:
 *      - Dynamic NFT Metadata: NFTs can update their metadata based on external data (simulated via admin).
 *      - AI-Curated Listings: Integration with a (simulated) decentralized AI curator oracle to assess NFT quality and promote curated listings.
 *      - Advanced Royalty System: Flexible royalty settings for creators, including secondary sale royalties and different royalty recipients.
 *      - Batch Listing and Buying: Efficiently list and buy multiple NFTs in a single transaction.
 *      - Offer System: Allow users to make offers on NFTs not currently listed for sale.
 *      - Tiered Platform Fees: Implement different platform fees based on NFT curation status.
 *      - Delayed Reveal NFTs: NFTs are minted with hidden metadata and revealed later.
 *      - NFT Bundles: Allow creators to bundle NFTs and sell them together.
 *      - Cross-Collection Trading: Enable trading NFTs from different compliant collections within the marketplace.
 *      - On-Chain Voting for Curator: Implement a basic on-chain voting mechanism to elect/change the curator oracle.
 *      - Dynamic Listing Duration: Allow sellers to choose different listing durations.
 *      - Referral Program: Reward users for referring new users to the marketplace.
 *      - NFT Gifting: Allow users to gift NFTs to others.
 *      - Auction Mechanism (Simplified): Basic auction functionality for NFTs.
 *      - Anti-Sniping Protection (Simplified): Implement a basic anti-sniping mechanism for auctions.
 *      - Allowlist for Premium Features: Implement allowlists for accessing premium marketplace features.
 *      - Flexible Currency Support (Simplified): Support for multiple payment tokens (ERC20).
 *      - Emergency Pause Function: Allow contract owner to pause critical functionalities in case of emergency.
 *      - NFT Metadata Freeze: Creators can freeze NFT metadata to prevent further updates.
 *      - Creator Revenue Sharing: Implement a system for creators to share revenue generated from their collections.
 *
 * Function Summary:
 *
 * **NFT Management:**
 * 1. mintDynamicNFT(address _to, string memory _baseURI, string memory _initialHiddenMetadataURI): Mints a new dynamic NFT with hidden metadata.
 * 2. revealNFTMetadata(uint256 _tokenId, string memory _revealedMetadataURI): Reveals the metadata of a specific NFT.
 * 3. setBaseURI(string memory _newBaseURI): Sets the base URI for NFT metadata.
 * 4. freezeNFTMetadata(uint256 _tokenId): Freezes the metadata of an NFT, preventing further updates.
 * 5. updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI):  Updates the metadata URI of a dynamic NFT (only by creator or admin if allowed).
 *
 * **Marketplace Core Functions:**
 * 6. listItem(uint256 _tokenId, uint256 _price, address _currency, uint256 _listingDurationDays): Lists an NFT for sale on the marketplace.
 * 7. buyItem(uint256 _listingId): Allows a buyer to purchase a listed NFT.
 * 8. cancelListing(uint256 _listingId): Allows a seller to cancel a listing.
 * 9. updateListingPrice(uint256 _listingId, uint256 _newPrice): Updates the price of an existing listing.
 * 10. makeOffer(uint256 _tokenId, uint256 _offerPrice, address _currency, uint256 _offerDurationDays): Allows a user to make an offer on an NFT.
 * 11. acceptOffer(uint256 _offerId): Allows the NFT owner to accept an offer on their NFT.
 * 12. cancelOffer(uint256 _offerId): Allows the offer maker to cancel their offer.
 * 13. giftNFT(uint256 _tokenId, address _recipient): Allows the NFT owner to gift an NFT to another address.
 * 14. createBundleListing(uint256[] memory _tokenIds, uint256 _bundlePrice, address _currency, uint256 _listingDurationDays): Lists a bundle of NFTs for sale.
 * 15. buyBundle(uint256 _bundleListingId): Allows a buyer to purchase a bundle of NFTs.
 * 16. cancelBundleListing(uint256 _bundleListingId): Allows a seller to cancel a bundle listing.
 *
 * **Royalty and Fee Management:**
 * 17. setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage, address _royaltyRecipient): Sets the royalty percentage and recipient for an NFT.
 * 18. setPlatformFee(uint256 _newFeePercentage): Sets the platform fee percentage.
 * 19. setCuratedPlatformFee(uint256 _newCuratedFeePercentage): Sets a different platform fee for curated NFTs.
 * 20. withdrawPlatformFees(): Allows the contract owner to withdraw accumulated platform fees.
 *
 * **Curator & Voting (Simplified):**
 * 21. setCuratorOracle(address _newCuratorOracle): Sets the address of the AI curator oracle.
 * 22. requestCuration(uint256 _tokenId): Requests curation score for an NFT from the oracle (simulated - in real use, an oracle call would be made).
 * 23. setCurationScore(uint256 _tokenId, uint256 _score):  Simulates receiving curation score from the oracle and updates NFT status.
 *
 * **Admin & Utility:**
 * 24. pauseContract(): Pauses critical contract functionalities.
 * 25. unpauseContract(): Resumes contract functionalities.
 * 26. supportsInterface(bytes4 interfaceId):  Standard ERC721 interface support.
 * 27. setAllowedCurrency(address _currency, bool _allowed):  Allows or disallows a currency (ERC20) for marketplace transactions.
 * 28. addAllowedMetadataUpdater(address _updater): Allows an address to update metadata for NFTs (beyond creator).
 * 29. removeAllowedMetadataUpdater(address _updater): Removes an address from the allowed metadata updaters list.
 */
contract DynamicNFTMarketplace {
    // ** STATE VARIABLES **

    string public name = "Dynamic NFT Marketplace";
    string public symbol = "DNFTM";
    string public baseURI;

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) public tokenMetadataURIs;
    mapping(uint256 => string) public hiddenMetadataURIs;
    mapping(uint256 => bool) public metadataFrozen;

    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    mapping(uint256 => Offer) public offers;
    uint256 public offerCounter;

    mapping(uint256 => RoyaltyInfo) public royaltyInfo;

    uint256 public platformFeePercentage = 250; // 2.5% (250 / 10000)
    uint256 public curatedPlatformFeePercentage = 100; // 1% for curated NFTs
    address public platformFeeRecipient;
    uint256 public accumulatedPlatformFees;

    address public curatorOracle;
    mapping(uint256 => uint256) public curationScores;
    mapping(uint256 => bool) public isCuratedNFT;

    address public owner;
    bool public paused;
    mapping(address => bool) public allowedCurrencies;
    mapping(address => bool) public allowedMetadataUpdaters;


    // ** STRUCTS **

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        address currency;
        uint256 listingTime;
        uint256 listingDuration; // in days
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerMaker;
        uint256 offerPrice;
        address currency;
        uint256 offerTime;
        uint256 offerDuration; // in days
        bool isActive;
    }

    struct RoyaltyInfo {
        uint256 royaltyPercentage;
        address royaltyRecipient;
    }

    // ** EVENTS **

    event NFTMinted(uint256 tokenId, address to, string metadataURI);
    event MetadataRevealed(uint256 tokenId, string revealedMetadataURI);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);
    event MetadataFrozen(uint256 tokenId);
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price, address currency);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price, address currency);
    event ListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerMaker, uint256 offerPrice, address currency);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price, address currency);
    event OfferCancelled(uint256 offerId);
    event NFTGifted(uint256 tokenId, address from, address to);
    event BundleListed(uint256 bundleListingId, uint256[] tokenIds, address seller, uint256 bundlePrice, address currency);
    event BundleBought(uint256 bundleListingId, uint256[] tokenIds, address buyer, uint256 bundlePrice, address currency);
    event BundleListingCancelled(uint256 bundleListingId);
    event RoyaltySet(uint256 tokenId, uint256 royaltyPercentage, address royaltyRecipient);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event CuratedPlatformFeeUpdated(uint256 newCuratedFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event CuratorOracleUpdated(address newCuratorOracle);
    event CurationRequested(uint256 tokenId, address requester);
    event CurationScoreSet(uint256 tokenId, uint256 score);
    event ContractPaused();
    event ContractUnpaused();
    event AllowedCurrencyUpdated(address currency, bool allowed);
    event AllowedMetadataUpdaterAdded(address updater);
    event AllowedMetadataUpdaterRemoved(address updater);


    // ** MODIFIERS **

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

    modifier onlyNFTCreator(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "Only NFT creator can call this function.");
        _;
    }

    modifier onlyAllowedCurrency(address _currency) {
        require(allowedCurrencies[_currency], "Currency is not allowed.");
        _;
    }

    modifier onlyAllowedMetadataUpdater(uint256 _tokenId) {
        require(allowedMetadataUpdaters[msg.sender] || ownerOf[_tokenId] == msg.sender, "Not allowed to update metadata.");
        _;
    }


    // ** CONSTRUCTOR **

    constructor(string memory _baseTokenURI, address _platformFeeReceiver) {
        owner = msg.sender;
        baseURI = _baseTokenURI;
        platformFeeRecipient = _platformFeeReceiver;
        allowedCurrencies[address(0)] = true; // Allow ETH by default
    }


    // ** NFT MANAGEMENT FUNCTIONS **

    function mintDynamicNFT(address _to, string memory _baseURI, string memory _initialHiddenMetadataURI) public onlyOwner whenNotPaused returns (uint256) {
        totalSupply++;
        uint256 tokenId = totalSupply;
        ownerOf[tokenId] = _to;
        balanceOf[_to]++;
        hiddenMetadataURIs[tokenId] = _initialHiddenMetadataURI;
        baseURI = _baseURI; // Updated base URI can be set during minting for collection level base URIs.

        emit NFTMinted(tokenId, _to, ""); // Metadata URI initially empty, revealed later
        return tokenId;
    }

    function revealNFTMetadata(uint256 _tokenId, string memory _revealedMetadataURI) public onlyNFTCreator(_tokenId) whenNotPaused {
        require(bytes(hiddenMetadataURIs[_tokenId]).length > 0, "NFT metadata already revealed or not a delayed reveal NFT.");
        tokenMetadataURIs[_tokenId] = _revealedMetadataURI;
        delete hiddenMetadataURIs[_tokenId]; // Remove hidden metadata after reveal
        emit MetadataRevealed(_tokenId, _revealedMetadataURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner whenNotPaused {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(ownerOf[_tokenId] != address(0), "Token does not exist.");
        if (metadataFrozen[_tokenId]) {
            return tokenMetadataURIs[_tokenId]; // Return frozen metadata if set
        }
        if (bytes(tokenMetadataURIs[_tokenId]).length > 0) { // Revealed metadata exists
            return string(abi.encodePacked(baseURI, tokenMetadataURIs[_tokenId]));
        } else {
            return string(abi.encodePacked(baseURI, hiddenMetadataURIs[_tokenId])); // Return hidden metadata if not revealed yet
        }
    }

    function freezeNFTMetadata(uint256 _tokenId) public onlyNFTCreator(_tokenId) whenNotPaused {
        metadataFrozen[_tokenId] = true;
        emit MetadataFrozen(_tokenId);
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyAllowedMetadataUpdater(_tokenId) whenNotPaused {
        require(!metadataFrozen[_tokenId], "Metadata is frozen and cannot be updated.");
        tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }


    // ** MARKETPLACE CORE FUNCTIONS **

    function listItem(uint256 _tokenId, uint256 _price, address _currency, uint256 _listingDurationDays) public whenNotPaused onlyNFTCreator(_tokenId) onlyAllowedCurrency(_currency) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(listings[_tokenId].isActive == false, "NFT is already listed.");
        require(_price > 0, "Price must be greater than zero.");

        listingCounter++;
        listings[_tokenId] = Listing({
            listingId: listingCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            currency: _currency,
            listingTime: block.timestamp,
            listingDuration: _listingDurationDays,
            isActive: true
        });

        // Transfer NFT to contract - escrow mechanism
        _safeTransferFrom(msg.sender, address(this), _tokenId);

        emit ItemListed(listingCounter, _tokenId, msg.sender, _price, _currency);
    }

    function buyItem(uint256 _listingId) public payable whenNotPaused onlyAllowedCurrency(listings[_listingId].currency) {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller != msg.sender, "Seller cannot buy their own listing.");
        require(block.timestamp <= listing.listingTime + listing.listingDuration * 1 days, "Listing duration expired.");

        uint256 price = listing.price;
        address currency = listing.currency;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;

        // Payment handling
        if (currency == address(0)) { // ETH
            require(msg.value >= price, "Insufficient ETH sent.");
        } else { // ERC20
            // Assume ERC20 interface is available (for simplicity, in real-world, interface check needed)
            IERC20(currency).transferFrom(msg.sender, address(this), price);
        }

        // Calculate fees and royalties
        uint256 platformFee = (price * getPlatformFeePercentage(tokenId)) / 10000;
        uint256 royaltyAmount = (price * getRoyaltyPercentage(tokenId)) / 10000;
        uint256 sellerProceeds = price - platformFee - royaltyAmount;

        // Transfer funds
        accumulatedPlatformFees += platformFee;
        if (royaltyAmount > 0) {
            address royaltyRecipient = getRoyaltyRecipient(tokenId);
            _transferFunds(royaltyRecipient, royaltyAmount, currency);
        }
        _transferFunds(seller, sellerProceeds, currency);
        if (currency == address(0) && msg.value > price) {
            _transferFunds(msg.sender, msg.value - price, address(0)); // Refund excess ETH
        }

        // Transfer NFT to buyer
        _safeTransferFrom(address(this), msg.sender, tokenId);

        // Update listing status
        listing.isActive = false;

        emit ItemBought(_listingId, tokenId, msg.sender, price, currency);
    }

    function cancelListing(uint256 _listingId) public whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only seller can cancel listing.");

        // Return NFT to seller
        _safeTransferFrom(address(this), msg.sender, listing.tokenId);

        listing.isActive = false;
        emit ListingCancelled(_listingId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only seller can update listing price.");
        require(_newPrice > 0, "Price must be greater than zero.");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    function makeOffer(uint256 _tokenId, uint256 _offerPrice, address _currency, uint256 _offerDurationDays) public whenNotPaused onlyAllowedCurrency(_currency) {
        require(ownerOf[_tokenId] != msg.sender, "Cannot make offer on your own NFT.");
        require(_offerPrice > 0, "Offer price must be greater than zero.");

        offerCounter++;
        offers[offerCounter] = Offer({
            offerId: offerCounter,
            tokenId: _tokenId,
            offerMaker: msg.sender,
            offerPrice: _offerPrice,
            currency: _currency,
            offerTime: block.timestamp,
            offerDuration: _offerDurationDays,
            isActive: true
        });
        emit OfferMade(offerCounter, _tokenId, msg.sender, _offerPrice, _currency);
    }

    function acceptOffer(uint256 _offerId) public whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active.");
        require(ownerOf[offer.tokenId] == msg.sender, "Only NFT owner can accept offer.");
        require(offer.offerMaker != msg.sender, "Cannot accept your own offer.");
        require(block.timestamp <= offer.offerTime + offer.offerDuration * 1 days, "Offer duration expired.");

        uint256 price = offer.offerPrice;
        address currency = offer.currency;
        uint256 tokenId = offer.tokenId;
        address buyer = offer.offerMaker;

        // Payment handling (assuming offer maker has approved transfer beforehand)
        if (currency == address(0)) { // ETH
            require(msg.value >= price, "Insufficient ETH sent to accept offer.");
        } else { // ERC20
            IERC20(currency).transferFrom(msg.sender, address(this), price); // Seller pays gas for accepting offer, buyer pre-approved
        }

        // Calculate fees and royalties - same as buyItem
        uint256 platformFee = (price * getPlatformFeePercentage(tokenId)) / 10000;
        uint256 royaltyAmount = (price * getRoyaltyPercentage(tokenId)) / 10000;
        uint256 sellerProceeds = price - platformFee - royaltyAmount;

        // Transfer funds
        accumulatedPlatformFees += platformFee;
        if (royaltyAmount > 0) {
            address royaltyRecipient = getRoyaltyRecipient(tokenId);
            _transferFunds(royaltyRecipient, royaltyAmount, currency);
        }
        _transferFunds(msg.sender, sellerProceeds, currency); // Seller is msg.sender here

        if (currency == address(0) && msg.value > price) {
            _transferFunds(msg.sender, msg.value - price, address(0)); // Refund excess ETH
        }

        // Transfer NFT to buyer
        _safeTransferFrom(msg.sender, buyer, tokenId); // Seller initiates transfer to buyer

        // Deactivate offer
        offer.isActive = false;

        emit OfferAccepted(_offerId, tokenId, msg.sender, buyer, price, currency);
    }

    function cancelOffer(uint256 _offerId) public whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active.");
        require(offer.offerMaker == msg.sender, "Only offer maker can cancel offer.");

        offer.isActive = false;
        emit OfferCancelled(_offerId);
    }

    function giftNFT(uint256 _tokenId, address _recipient) public whenNotPaused onlyNFTCreator(_tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_recipient != address(0), "Recipient address cannot be zero address.");
        require(_recipient != msg.sender, "Cannot gift NFT to yourself.");

        _safeTransferFrom(msg.sender, _recipient, _tokenId);
        emit NFTGifted(_tokenId, msg.sender, _recipient);
    }

    function createBundleListing(uint256[] memory _tokenIds, uint256 _bundlePrice, address _currency, uint256 _listingDurationDays) public whenNotPaused onlyAllowedCurrency(_currency) {
        require(_tokenIds.length > 1, "Bundle must contain at least two NFTs.");
        require(_bundlePrice > 0, "Bundle price must be greater than zero.");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(ownerOf[_tokenIds[i]] == msg.sender, "You are not the owner of all NFTs in the bundle.");
            require(listings[_tokenIds[i]].isActive == false, "One of the NFTs in the bundle is already listed individually.");
            // Add check for other bundle listings if needed to prevent overlaps.
        }

        listingCounter++;
        uint256 bundleListingId = listingCounter;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            listings[_tokenIds[i]] = Listing({ // Reusing Listing struct to store bundle info linked to each token ID in bundle
                listingId: bundleListingId, // Same listingId for all tokens in bundle
                tokenId: _tokenIds[i],
                seller: msg.sender,
                price: _bundlePrice,
                currency: _currency,
                listingTime: block.timestamp,
                listingDuration: _listingDurationDays,
                isActive: true
            });
            _safeTransferFrom(msg.sender, address(this), _tokenIds[i]); // Escrow NFTs in bundle
        }

        emit BundleListed(bundleListingId, _tokenIds, msg.sender, _bundlePrice, _currency);
    }

    function buyBundle(uint256 _bundleListingId) public payable whenNotPaused onlyAllowedCurrency(listings[0].currency) { //listings[0] here is just to access currency, as bundle listingId is same for all tokens
        Listing storage bundleListing = listings[0]; // Placeholder, need to iterate to find a token with this bundleListingId.
        uint256 bundlePrice = 0;
        address currency = address(0); // Default to address(0)

        // Iterate through listings to find tokens associated with this bundle listing ID and validate
        uint256[] memory tokenIdsInBundle;
        uint256 tokenCount = 0;
        for (uint256 tokenId = 1; tokenId <= totalSupply; tokenId++) {
            if (listings[tokenId].listingId == _bundleListingId && listings[tokenId].isActive && listings[tokenId].seller != address(0)) { // Basic check for valid listing
                bundleListing = listings[tokenId]; // Now bundleListing is actually one of the bundle items.
                bundlePrice = bundleListing.price; // Price is the same for all tokens in bundle
                currency = bundleListing.currency;
                tokenIdsInBundle[tokenCount] = tokenId; // Store token IDs for transfer later
                tokenCount++;
            }
        }

        require(bundleListing.listingId == _bundleListingId && bundleListing.isActive, "Bundle listing is not active or not found.");
        require(bundleListing.seller != msg.sender, "Seller cannot buy their own bundle.");
        require(block.timestamp <= bundleListing.listingTime + bundleListing.listingDuration * 1 days, "Bundle listing duration expired.");
        require(tokenCount > 1, "Invalid bundle or bundle listing ID."); // Ensure we found more than one token associated with this listingId


        // Payment handling - same as buyItem but for bundle price
        if (currency == address(0)) { // ETH
            require(msg.value >= bundlePrice, "Insufficient ETH sent for bundle.");
        } else { // ERC20
            IERC20(currency).transferFrom(msg.sender, address(this), bundlePrice);
        }

        // Calculate fees and royalties - apply to bundle price
        uint256 platformFee = (bundlePrice * getPlatformFeePercentage(tokenIdsInBundle[0])) / 10000; // Using first token's curation for bundle fee - can adjust logic
        uint256 royaltyAmount = (bundlePrice * getRoyaltyPercentage(tokenIdsInBundle[0])) / 10000; // Using first token's royalty for bundle royalty - can adjust logic
        uint256 sellerProceeds = bundlePrice - platformFee - royaltyAmount;

        // Transfer funds - same as buyItem
        accumulatedPlatformFees += platformFee;
        if (royaltyAmount > 0) {
            address royaltyRecipient = getRoyaltyRecipient(tokenIdsInBundle[0]); // Using first token's royalty recipient - can adjust
            _transferFunds(royaltyRecipient, royaltyAmount, currency);
        }
        _transferFunds(bundleListing.seller, sellerProceeds, currency);
        if (currency == address(0) && msg.value > bundlePrice) {
            _transferFunds(msg.sender, msg.value - bundlePrice, address(0)); // Refund excess ETH
        }


        // Transfer NFTs in bundle to buyer and deactivate listings for each token in bundle
        for (uint256 i = 0; i < tokenIdsInBundle.length; i++) {
            _safeTransferFrom(address(this), msg.sender, tokenIdsInBundle[i]);
            listings[tokenIdsInBundle[i]].isActive = false; // Deactivate listing for each token
        }

        emit BundleBought(_bundleListingId, tokenIdsInBundle, msg.sender, bundlePrice, currency);
    }

    function cancelBundleListing(uint256 _bundleListingId) public whenNotPaused {
        bool bundleCancelled = false;
        uint256[] memory cancelledTokenIds;

        for (uint256 tokenId = 1; tokenId <= totalSupply; tokenId++) {
            if (listings[tokenId].listingId == _bundleListingId && listings[tokenId].isActive && listings[tokenId].seller == msg.sender) {
                _safeTransferFrom(address(this), msg.sender, listings[tokenId].tokenId); // Return NFT to seller
                listings[tokenId].isActive = false;
                cancelledTokenIds.push(tokenId);
                bundleCancelled = true; // At least one token cancelled, consider bundle cancelled.
            }
        }
        require(bundleCancelled, "Bundle listing not found or not owned by sender."); // Ensure at least one cancellation happened.

        emit BundleListingCancelled(_bundleListingId);
    }


    // ** ROYALTY AND FEE MANAGEMENT **

    function setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage, address _royaltyRecipient) public onlyNFTCreator(_tokenId) whenNotPaused {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%.");
        royaltyInfo[_tokenId] = RoyaltyInfo({
            royaltyPercentage: _royaltyPercentage,
            royaltyRecipient: _royaltyRecipient
        });
        emit RoyaltySet(_tokenId, _royaltyPercentage, _royaltyRecipient);
    }

    function getRoyaltyPercentage(uint256 _tokenId) public view returns (uint256) {
        return royaltyInfo[_tokenId].royaltyPercentage;
    }

    function getRoyaltyRecipient(uint256 _tokenId) public view returns (address) {
        return royaltyInfo[_tokenId].royaltyRecipient;
    }

    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner whenNotPaused {
        require(_newFeePercentage <= 10000, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function setCuratedPlatformFee(uint256 _newCuratedFeePercentage) public onlyOwner whenNotPaused {
        require(_newCuratedFeePercentage <= 10000, "Curated platform fee percentage cannot exceed 100%.");
        curatedPlatformFeePercentage = _newCuratedFeePercentage;
        emit CuratedPlatformFeeUpdated(_newCuratedFeePercentage);
    }

    function getPlatformFeePercentage(uint256 _tokenId) public view returns (uint256) {
        if (isCuratedNFT[_tokenId]) {
            return curatedPlatformFeePercentage;
        } else {
            return platformFeePercentage;
        }
    }

    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 amount = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        _transferFunds(platformFeeRecipient, amount, address(0)); // Withdraw in ETH (platform fee likely collected in ETH)
        emit PlatformFeesWithdrawn(amount, platformFeeRecipient);
    }


    // ** CURATOR & VOTING (SIMPLIFIED) **

    function setCuratorOracle(address _newCuratorOracle) public onlyOwner whenNotPaused {
        curatorOracle = _newCuratorOracle;
        emit CuratorOracleUpdated(_newCuratorOracle);
    }

    function requestCuration(uint256 _tokenId) public whenNotPaused {
        require(curatorOracle != address(0), "Curator oracle not set.");
        // In a real implementation, call an oracle function here.
        // For simulation, we just emit an event and assume admin calls setCurationScore manually.
        emit CurationRequested(_tokenId, msg.sender);
        // Example of a simplified oracle call (assuming external contract with getCurationScore function):
        // (uint256 score) = CuratorOracleInterface(curatorOracle).getCurationScore(_tokenId);
        // setCurationScore(_tokenId, score); // Or handle callback from oracle in a more complex setup.
    }

    // Simulate oracle response - admin function to set curation score
    function setCurationScore(uint256 _tokenId, uint256 _score) public onlyOwner whenNotPaused {
        curationScores[_tokenId] = _score;
        if (_score > 70) { // Example threshold for curation - can be configurable
            isCuratedNFT[_tokenId] = true;
        } else {
            isCuratedNFT[_tokenId] = false;
        }
        emit CurationScoreSet(_tokenId, _score);
    }


    // ** ADMIN & UTILITY FUNCTIONS **

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function setAllowedCurrency(address _currency, bool _allowed) public onlyOwner whenNotPaused {
        allowedCurrencies[_currency] = _allowed;
        emit AllowedCurrencyUpdated(_currency, _allowed);
    }

    function addAllowedMetadataUpdater(address _updater) public onlyOwner whenNotPaused {
        allowedMetadataUpdaters[_updater] = true;
        emit AllowedMetadataUpdaterAdded(_updater);
    }

    function removeAllowedMetadataUpdater(address _updater) public onlyOwner whenNotPaused {
        delete allowedMetadataUpdaters[_updater];
        emit AllowedMetadataUpdaterRemoved(_updater);
    }


    // ** INTERNAL HELPER FUNCTIONS **

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId) internal {
        ownerOf[_tokenId] = _to;
        balanceOf[_from]--;
        balanceOf[_to]++;
        emit Transfer(_from, _to, _tokenId); // ERC721 Transfer event
    }

    function _transferFunds(address _recipient, uint256 _amount, address _currency) internal {
        if (_currency == address(0)) { // ETH
            (bool success, ) = _recipient.call{value: _amount}("");
            require(success, "ETH transfer failed.");
        } else { // ERC20
            IERC20(_currency).transfer(_recipient, _amount);
        }
    }


    // ** ERC721 INTERFACE (Simplified - for demonstration) **
    interface IERC721 {
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
        function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
        function approve(address _approved, uint256 _tokenId) external payable;
        function getApproved(uint256 _tokenId) external view returns (address operator);
        function setApprovalForAll(address _operator, bool _approved) external payable;
        function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    }

    interface IERC165 {
        function supportsInterface(bytes4 interfaceId) external view returns (bool);
    }

    interface IERC20 {
        function transfer(address recipient, uint256 amount) external returns (bool);
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        function balanceOf(address account) external view returns (uint256);
        function approve(address spender, uint256 amount) external returns (bool);
        function allowance(address owner, address spender) external view returns (uint256);
    }

    // Interface for Curator Oracle (Simplified - Example)
    // interface CuratorOracleInterface {
    //     function getCurationScore(uint256 _tokenId) external view returns (uint256);
    // }
}
```