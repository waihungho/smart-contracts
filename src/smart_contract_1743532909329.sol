```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Trait Evolution and Gamified Staking
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized NFT marketplace with advanced features:
 *      - Dynamic NFTs: NFTs whose traits can evolve based on market conditions and owner actions.
 *      - AI-Powered Trait Evolution:  Simulates trait evolution based on a simplified "market sentiment" (represented by token price) and owner's "care" (staking).
 *      - Gamified Staking:  Staking NFTs to influence their evolution and earn platform tokens.
 *      - Decentralized Governance (Simplified): Platform fee and royalty percentage can be adjusted by admin.
 *      - Advanced Listing and Offer System: Supports fixed price and auction listings, as well as direct offers.
 *      - Rarity System:  NFTs have a rarity score calculated based on their traits.
 *      - Dynamic Metadata: NFT metadata (image, description) can change based on traits.
 *      - Staking Rewards: Stakers receive platform tokens.
 *      - Batch Operations: Allows for batch listing and buying of NFTs.
 *      - Event-Driven Architecture: Emits detailed events for all major actions.
 *
 * Function Summary:
 *
 * // --- Core NFT Functionality ---
 * 1. mintDynamicNFT(string memory _baseURI, string memory _namePrefix, string memory _descriptionPrefix) - Mints a new Dynamic NFT.
 * 2. getNFTTraits(uint256 _tokenId) - Returns the current traits of an NFT.
 * 3. getNFTRarityScore(uint256 _tokenId) - Calculates and returns the rarity score of an NFT.
 * 4. updateNFTMetadata(uint256 _tokenId) - Updates the NFT metadata based on its current traits.
 * 5. getTokenURI(uint256 _tokenId) - Returns the token URI for an NFT (dynamic metadata).
 *
 * // --- Marketplace Listing and Buying ---
 * 6. listNFTForFixedPrice(uint256 _tokenId, uint256 _price) - Lists an NFT for sale at a fixed price.
 * 7. listNFTForAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _auctionDuration) - Lists an NFT for auction.
 * 8. buyNFT(uint256 _listingId) - Buys an NFT listed for fixed price or auction (if auction ended).
 * 9. cancelListing(uint256 _listingId) - Cancels a listing.
 * 10. makeOffer(uint256 _tokenId, uint256 _offerPrice) - Makes a direct offer on an NFT.
 * 11. acceptOffer(uint256 _offerId) - Accepts a direct offer on an NFT.
 * 12. withdrawOffer(uint256 _offerId) - Withdraws a direct offer.
 * 13. getListingDetails(uint256 _listingId) - Retrieves details of a listing.
 * 14. getOfferDetails(uint256 _offerId) - Retrieves details of an offer.
 * 15. batchBuyNFTs(uint256[] memory _listingIds) - Allows buying multiple NFTs in a single transaction.
 * 16. batchListNFTsForFixedPrice(uint256[] memory _tokenIds, uint256[] memory _prices) - Allows listing multiple NFTs at fixed prices in a single transaction.
 *
 * // --- Dynamic NFT Evolution and Staking ---
 * 17. stakeNFT(uint256 _tokenId) - Stakes an NFT to "care" for it and potentially influence trait evolution.
 * 18. unstakeNFT(uint256 _tokenId) - Unstakes an NFT.
 * 19. evolveNFTTraits(uint256 _tokenId) - Manually triggers trait evolution for an NFT (can be automated or event-driven in a real-world scenario).
 * 20. getStakingReward(uint256 _tokenId) - Claims staking rewards for an NFT.
 *
 * // --- Platform Management ---
 * 21. setPlatformFeePercentage(uint256 _feePercentage) - Admin function to set platform fee percentage.
 * 22. setRoyaltyPercentage(uint256 _royaltyPercentage) - Admin function to set royalty percentage.
 * 23. withdrawPlatformFees() - Admin function to withdraw accumulated platform fees.
 * 24. pauseContract() - Admin function to pause the contract.
 * 25. unpauseContract() - Admin function to unpause the contract.
 * 26. supportsInterface(bytes4 interfaceId) - Interface support for ERC721 and ERC2981.
 */
contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public name = "DynamicNFT";
    string public symbol = "DYNFT";
    string public baseURI;
    string public namePrefix;
    string public descriptionPrefix;

    address public platformOwner;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public royaltyPercentage = 5;    // 5% creator royalty

    uint256 public nextNFTId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextOfferId = 1;

    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftTokenURIs;
    mapping(uint256 => uint256[5]) public nftTraits; // Example: [Strength, Agility, Intelligence, Luck, Charisma] - can be expanded
    mapping(uint256 => bool) public nftStaked;
    mapping(uint256 => uint256) public nftStakeStartTime;
    mapping(uint256 => uint256) public nftLastEvolutionTime;

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        ListingType listingType; // FixedPrice, Auction
        uint256 auctionEndTime; // 0 for fixed price
        bool isActive;
    }
    enum ListingType { FixedPrice, Auction }
    mapping(uint256 => Listing) public listings;

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 offerPrice;
        bool isActive;
    }
    mapping(uint256 => Offer) public offers;

    uint256 public platformFeesCollected;
    bool public paused = false;

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price, ListingType listingType);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event OfferMade(uint256 offerId, uint256 tokenId, address buyer, uint256 offerPrice);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price);
    event OfferWithdrawn(uint256 offerId);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, uint256 tokenId, address unstaker);
    event NFTTraitsEvolved(uint256 tokenId, uint256[5] newTraits);
    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event RoyaltyPercentageUpdated(uint256 newPercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier onlyOwnerOfNFT(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "Not owner of NFT");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory _baseURI, string memory _namePrefix, string memory _descriptionPrefix) {
        platformOwner = msg.sender;
        baseURI = _baseURI;
        namePrefix = _namePrefix;
        descriptionPrefix = _descriptionPrefix;
    }

    // --- Core NFT Functionality ---

    /// @notice Mints a new Dynamic NFT.
    /// @param _baseURI Base URI for token metadata.
    /// @param _namePrefix Prefix for NFT name.
    /// @param _descriptionPrefix Prefix for NFT description.
    function mintDynamicNFT(string memory _baseURI, string memory _namePrefix, string memory _descriptionPrefix) external whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = msg.sender;
        nftTraits[tokenId] = [50, 50, 50, 50, 50]; // Initialize with base traits (example)
        nftLastEvolutionTime[tokenId] = block.timestamp;
        baseURI = _baseURI; // Update baseURI if needed for future mints
        namePrefix = _namePrefix;
        descriptionPrefix = _descriptionPrefix;

        _updateNFTMetadata(tokenId); // Generate initial metadata

        emit NFTMinted(tokenId, msg.sender);
    }

    /// @notice Returns the current traits of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return An array representing the NFT's traits.
    function getNFTTraits(uint256 _tokenId) external view returns (uint256[5] memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        return nftTraits[_tokenId];
    }

    /// @notice Calculates and returns the rarity score of an NFT based on its traits.
    /// @param _tokenId The ID of the NFT.
    /// @return The rarity score of the NFT.
    function getNFTRarityScore(uint256 _tokenId) public view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        uint256[5] memory traits = nftTraits[_tokenId];
        uint256 rarityScore = 0;
        for (uint256 i = 0; i < traits.length; i++) {
            rarityScore += traits[i]; // Simple sum of traits for rarity, can be more complex
        }
        return rarityScore;
    }

    /// @notice Updates the NFT metadata based on its current traits.
    /// @param _tokenId The ID of the NFT.
    function updateNFTMetadata(uint256 _tokenId) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        _updateNFTMetadata(_tokenId);
    }

    /// @dev Internal function to update NFT metadata.
    function _updateNFTMetadata(uint256 _tokenId) internal {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        uint256[5] memory traits = nftTraits[_tokenId];
        uint256 rarityScore = getNFTRarityScore(_tokenId);

        // Generate dynamic metadata based on traits and rarity
        string memory metadata = string(abi.encodePacked(
            '{"name": "', namePrefix, " #", Strings.toString(_tokenId), '",',
            '"description": "', descriptionPrefix, ' - Evolving Traits: ', _traitDescription(traits), ' - Rarity Score: ', Strings.toString(rarityScore), '",',
            '"image": "', baseURI, Strings.toString(_tokenId), '.png",', // Example: dynamic image URL based on tokenId or traits
            '"attributes": [',
                '{"trait_type": "Strength", "value": "', Strings.toString(traits[0]), '"},',
                '{"trait_type": "Agility", "value": "', Strings.toString(traits[1]), '"},',
                '{"trait_type": "Intelligence", "value": "', Strings.toString(traits[2]), '"},',
                '{"trait_type": "Luck", "value": "', Strings.toString(traits[3]), '"},',
                '{"trait_type": "Charisma", "value": "', Strings.toString(traits[4]), '"},',
                '{"trait_type": "Rarity Score", "value": "', Strings.toString(rarityScore), '"}]',
            '}'
        ));
        nftTokenURIs[_tokenId] = metadata;
    }

    /// @dev Helper function to generate trait description string.
    function _traitDescription(uint256[5] memory _traits) internal pure returns (string memory) {
        return string(abi.encodePacked(
            "Strength: ", Strings.toString(_traits[0]), ", ",
            "Agility: ", Strings.toString(_traits[1]), ", ",
            "Intelligence: ", Strings.toString(_traits[2]), ", ",
            "Luck: ", Strings.toString(_traits[3]), ", ",
            "Charisma: ", Strings.toString(_traits[4])
        ));
    }


    /// @notice Returns the token URI for an NFT (dynamic metadata).
    /// @param _tokenId The ID of the NFT.
    /// @return The token URI string.
    function getTokenURI(uint256 _tokenId) external view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        return nftTokenURIs[_tokenId];
    }

    // --- Marketplace Listing and Buying ---

    /// @notice Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The fixed price in wei.
    function listNFTForFixedPrice(uint256 _tokenId, uint256 _price) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(nftOwner[_tokenId] == msg.sender, "Not owner of NFT");
        require(listings[nextListingId].isActive == false, "Listing ID collision, try again"); // Very rare, but a safety check
        _transferNFT(_tokenId, address(this)); // Escrow NFT to marketplace

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingType: ListingType.FixedPrice,
            auctionEndTime: 0,
            isActive: true
        });

        emit NFTListed(nextListingId, _tokenId, msg.sender, _price, ListingType.FixedPrice);
        nextListingId++;
    }

    /// @notice Lists an NFT for auction.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _startingPrice The starting price in wei.
    /// @param _auctionDuration Auction duration in seconds.
    function listNFTForAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _auctionDuration) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(_auctionDuration > 0, "Auction duration must be positive");
        require(listings[nextListingId].isActive == false, "Listing ID collision, try again"); // Very rare, but a safety check
        _transferNFT(_tokenId, address(this)); // Escrow NFT to marketplace

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _startingPrice,
            listingType: ListingType.Auction,
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });

        emit NFTListed(nextListingId, _tokenId, msg.sender, _startingPrice, ListingType.Auction);
        nextListingId++;
    }

    /// @notice Buys an NFT listed for fixed price or auction (if auction ended).
    /// @param _listingId The ID of the listing to buy.
    function buyNFT(uint256 _listingId) external payable whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        if (listing.listingType == ListingType.FixedPrice) {
            require(msg.value >= listing.price, "Insufficient funds");
        } else if (listing.listingType == ListingType.Auction) {
            require(block.timestamp > listing.auctionEndTime, "Auction has not ended");
            require(msg.value >= listing.price, "Insufficient funds"); // Price is current auction price, in this simple version it's starting price

        }

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 royaltyFee = (listing.price * royaltyPercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee - royaltyFee;

        platformFeesCollected += platformFee;

        // Transfer funds
        (bool successSeller, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed");

        // In a real implementation, you would handle royalty payments to the original creator if applicable.
        // For simplicity, this example omits explicit royalty tracking and payment to a creator address.

        _transferNFT(listing.tokenId, msg.sender); // Transfer NFT to buyer

        listing.isActive = false; // Deactivate listing

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    /// @notice Cancels a listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) external whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        _transferNFT(listing.tokenId, msg.sender); // Return NFT to seller
        listing.isActive = false;

        emit ListingCancelled(_listingId);
    }

    /// @notice Makes a direct offer on an NFT.
    /// @param _tokenId The ID of the NFT to make an offer on.
    /// @param _offerPrice The offer price in wei.
    function makeOffer(uint256 _tokenId, uint256 _offerPrice) external whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist");
        require(nftOwner[_tokenId] != msg.sender, "Cannot offer on your own NFT");
        require(_offerPrice > 0, "Offer price must be positive");
        require(offers[nextOfferId].isActive == false, "Offer ID collision, try again"); // Very rare, but a safety check

        offers[nextOfferId] = Offer({
            offerId: nextOfferId,
            tokenId: _tokenId,
            buyer: msg.sender,
            offerPrice: _offerPrice,
            isActive: true
        });

        emit OfferMade(nextOfferId, _tokenId, msg.sender, _offerPrice);
        nextOfferId++;
    }

    /// @notice Accepts a direct offer on an NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) external onlyOwnerOfNFT(offers[_offerId].tokenId) whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active");
        require(nftOwner[offer.tokenId] == msg.sender, "Not owner of NFT");

        uint256 platformFee = (offer.offerPrice * platformFeePercentage) / 100;
        uint256 royaltyFee = (offer.offerPrice * royaltyPercentage) / 100;
        uint256 sellerProceeds = offer.offerPrice - platformFee - royaltyFee;

        platformFeesCollected += platformFee;

        // Transfer funds
        (bool successSeller, ) = payable(msg.sender).call{value: sellerProceeds}(""); // Seller is current owner in onlyOwnerOfNFT modifier
        require(successSeller, "Seller payment failed");

        // In a real implementation, you would handle royalty payments to the original creator if applicable.

        _transferNFT(offer.tokenId, offer.buyer); // Transfer NFT to buyer

        offer.isActive = false; // Deactivate offer

        emit OfferAccepted(_offerId, offer.tokenId, msg.sender, offer.buyer, offer.offerPrice);
    }

    /// @notice Withdraws a direct offer.
    /// @param _offerId The ID of the offer to withdraw.
    function withdrawOffer(uint256 _offerId) external whenNotPaused {
        Offer storage offer = offers[_offerId];
        require(offer.isActive, "Offer is not active");
        require(offer.buyer == msg.sender, "Only offer creator can withdraw");
        offer.isActive = false;
        emit OfferWithdrawn(_offerId);
    }

    /// @notice Retrieves details of a listing.
    /// @param _listingId The ID of the listing.
    /// @return Listing details.
    function getListingDetails(uint256 _listingId) external view returns (Listing memory) {
        return listings[_listingId];
    }

    /// @notice Retrieves details of an offer.
    /// @param _offerId The ID of the offer.
    /// @return Offer details.
    function getOfferDetails(uint256 _offerId) external view returns (Offer memory) {
        return offers[_offerId];
    }

    /// @notice Allows buying multiple NFTs in a single transaction.
    /// @param _listingIds Array of listing IDs to buy.
    function batchBuyNFTs(uint256[] memory _listingIds) external payable whenNotPaused {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < _listingIds.length; i++) {
            Listing storage listing = listings[_listingIds[i]];
            require(listing.isActive, "Listing is not active");
            require(listing.seller != msg.sender, "Cannot buy your own NFT");
            if (listing.listingType == ListingType.FixedPrice || (listing.listingType == ListingType.Auction && block.timestamp > listing.auctionEndTime)) {
                totalValue += listing.price;
            } else {
                revert("Invalid listing type or auction not ended");
            }
        }
        require(msg.value >= totalValue, "Insufficient funds for batch buy");

        for (uint256 i = 0; i < _listingIds.length; i++) {
            _buySingleNFT(_listingIds[i]); // Internal function to handle single buy logic
        }
    }

    /// @dev Internal function to handle single NFT buy logic (reused in batch buy).
    function _buySingleNFT(uint256 _listingId) internal {
        Listing storage listing = listings[_listingId];
        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 royaltyFee = (listing.price * royaltyPercentage) / 100;
        uint256 sellerProceeds = listing.price - platformFee - royaltyFee;

        platformFeesCollected += platformFee;

        // Transfer funds
        (bool successSeller, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(successSeller, "Seller payment failed in batch buy");

        _transferNFT(listing.tokenId, msg.sender); // Transfer NFT to buyer

        listing.isActive = false; // Deactivate listing

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    /// @notice Allows listing multiple NFTs at fixed prices in a single transaction.
    /// @param _tokenIds Array of NFT token IDs to list.
    /// @param _prices Array of fixed prices for each NFT.
    function batchListNFTsForFixedPrice(uint256[] memory _tokenIds, uint256[] memory _prices) external whenNotPaused {
        require(_tokenIds.length == _prices.length, "Token IDs and prices arrays must have the same length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _listSingleNFTForFixedPrice(_tokenIds[i], _prices[i]); // Internal function for single listing
        }
    }

    /// @dev Internal function to handle single NFT fixed price listing logic (reused in batch listing).
    function _listSingleNFTForFixedPrice(uint256 _tokenId, uint256 _price) internal {
        require(nftOwner[_tokenId] == msg.sender, "Not owner of NFT in batch listing");
        require(listings[nextListingId].isActive == false, "Listing ID collision in batch listing, try again"); // Very rare, but a safety check
        _transferNFT(_tokenId, address(this)); // Escrow NFT to marketplace

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            listingType: ListingType.FixedPrice,
            auctionEndTime: 0,
            isActive: true
        });

        emit NFTListed(nextListingId, _tokenId, msg.sender, _price, ListingType.FixedPrice);
        nextListingId++;
    }


    // --- Dynamic NFT Evolution and Staking ---

    /// @notice Stakes an NFT to "care" for it and potentially influence trait evolution.
    /// @param _tokenId The ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(!nftStaked[_tokenId], "NFT already staked");
        nftStaked[_tokenId] = true;
        nftStakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Unstakes an NFT.
    /// @param _tokenId The ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(nftStaked[_tokenId], "NFT not staked");
        nftStaked[_tokenId] = false;
        emit NFTUnstaked(_tokenId, _tokenId, msg.sender);
    }

    /// @notice Manually triggers trait evolution for an NFT (can be automated or event-driven in a real-world scenario).
    /// @param _tokenId The ID of the NFT to evolve.
    function evolveNFTTraits(uint256 _tokenId) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(block.timestamp >= nftLastEvolutionTime[_tokenId] + 1 days, "Evolution cooldown not finished"); // Example: 1 day cooldown
        uint256[5] memory currentTraits = nftTraits[_tokenId];
        uint256[5] memory newTraits = currentTraits;

        // Simplified AI-Powered Trait Evolution Logic (Example):
        // - "Market Sentiment" - simplified to random fluctuation (can be replaced by price oracle data or other on-chain/off-chain data)
        // - "Owner Care" - represented by staking duration (longer stake = more "care")

        uint256 marketSentiment = (block.timestamp % 100) < 50 ? 1 : 0; // 50% chance of positive sentiment
        uint256 stakeDurationBonus = nftStaked[_tokenId] ? (block.timestamp - nftStakeStartTime[_tokenId]) / (7 days) : 0; // Bonus for every 7 days staked

        for (uint256 i = 0; i < newTraits.length; i++) {
            int256 traitChange = 0;
            if (marketSentiment == 1) { // Positive Market Sentiment
                traitChange += int256(1 + stakeDurationBonus); // Increase trait, bonus for staking
            } else { // Negative Market Sentiment
                traitChange -= int256(1); // Decrease trait
            }

            newTraits[i] = uint256(int256(currentTraits[i]) + traitChange);

            // Clamp traits to a reasonable range (example: 1 to 100)
            if (newTraits[i] < 1) newTraits[i] = 1;
            if (newTraits[i] > 100) newTraits[i] = 100;
        }

        nftTraits[_tokenId] = newTraits;
        nftLastEvolutionTime[_tokenId] = block.timestamp;
        _updateNFTMetadata(_tokenId); // Update metadata after evolution

        emit NFTTraitsEvolved(_tokenId, newTraits);
    }

    /// @notice Claims staking rewards for an NFT. (Simplified reward system, for demonstration)
    /// @param _tokenId The ID of the staked NFT.
    function getStakingReward(uint256 _tokenId) external onlyOwnerOfNFT(_tokenId) whenNotPaused {
        require(nftStaked[_tokenId], "NFT is not staked");
        uint256 stakeDuration = block.timestamp - nftStakeStartTime[_tokenId];
        uint256 rewardAmount = (stakeDuration / (1 days)) * 10; // Example: 10 platform tokens per day staked

        // In a real implementation, you would have a platform token and transfer logic.
        // For simplicity, this example just emits an event with the reward amount.

        emit PlatformFeesWithdrawn(rewardAmount, msg.sender); // Reusing event for simplicity - replace with proper token transfer

        // Reset stake start time after claiming reward (optional - depends on reward mechanics)
        nftStakeStartTime[_tokenId] = block.timestamp;
    }


    // --- Platform Management ---

    /// @notice Admin function to set platform fee percentage.
    /// @param _feePercentage New platform fee percentage (0-100).
    function setPlatformFeePercentage(uint256 _feePercentage) external onlyPlatformOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be <= 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageUpdated(_feePercentage);
    }

    /// @notice Admin function to set royalty percentage.
    /// @param _royaltyPercentage New royalty percentage (0-100).
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyPlatformOwner whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be <= 100");
        royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageUpdated(_royaltyPercentage);
    }

    /// @notice Admin function to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyPlatformOwner whenNotPaused {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        (bool success, ) = payable(platformOwner).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit PlatformFeesWithdrawn(amount, platformOwner);
    }

    /// @notice Admin function to pause the contract.
    function pauseContract() external onlyPlatformOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyPlatformOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Internal NFT Transfer Function ---
    function _transferNFT(uint256 _tokenId, address _to) internal {
        address currentOwner = nftOwner[_tokenId];
        require(currentOwner != address(0), "NFT does not exist");

        nftOwner[_tokenId] = _to;
        emit Transfer(currentOwner, _to, _tokenId); // ERC721 Transfer event
    }


    // --- ERC721 Interface Support (Minimal - for demonstration) ---
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return nftOwner[_tokenId];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextNFTId; i++) {
            if (nftOwner[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(nftOwner[_tokenId] == _from, "Not owner");
        require(_from == msg.sender || msg.sender == address(this), "Not authorized"); // Allow marketplace to transfer
        _transferNFT(_tokenId, _to);
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        revert("Approve not supported in this simplified ERC721 implementation"); // For brevity - implement if needed
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        revert("getApproved not supported in this simplified ERC721 implementation"); // For brevity - implement if needed
    }

    function setApprovalForAll(address _operator, bool _approved) external payable {
        revert("setApprovalForAll not supported in this simplified ERC721 implementation"); // For brevity - implement if needed
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        revert("isApprovedForAll not supported in this simplified ERC721 implementation"); // For brevity - implement if needed
    }

    // --- ERC2981 Royalty Interface Support (Minimal - for demonstration) ---
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (platformOwner, (_salePrice * royaltyPercentage) / 100); // Royalties go to platform owner in this example
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x80ac58cd || // ERC721 Interface ID
               interfaceId == 0x2a55205a || // ERC2981 Interface ID
               interfaceId == 0x5b5e139f;   // ERC721Metadata Interface ID (for name, symbol, tokenURI)
    }

    // --- Helper Libraries (Import or Include) ---
    // Using OpenZeppelin's Strings library for simplicity (you can copy the relevant part or import it)
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
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }

    // ERC721 Events (for interface compliance - minimal)
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

}
```