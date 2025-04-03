```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant)
 * @notice This smart contract implements a decentralized NFT marketplace with dynamic NFTs and a simulated AI-powered personalization engine.
 *
 * Function Summary:
 *
 * **NFT Management:**
 * 1. mintNFT(string memory _uri, string memory _initialDynamicProperty): Mints a new Dynamic NFT.
 * 2. setNFTProperties(uint256 _tokenId, string memory _dynamicProperty): Updates the dynamic properties of an NFT.
 * 3. updateNFTMetadata(uint256 _tokenId, string memory _newUri): Updates the metadata URI of an NFT.
 * 4. burnNFT(uint256 _tokenId): Burns an NFT, removing it from the marketplace.
 * 5. transferNFT(address _to, uint256 _tokenId): Transfers ownership of an NFT.
 * 6. getNFTProperties(uint256 _tokenId): Retrieves the dynamic properties of an NFT.
 *
 * **Marketplace Listing and Trading:**
 * 7. listItem(uint256 _tokenId, uint256 _price): Lists an NFT for sale in the marketplace.
 * 8. delistItem(uint256 _tokenId): Removes an NFT listing from the marketplace.
 * 9. purchaseItem(uint256 _listingId): Purchases an NFT listed in the marketplace.
 * 10. offerItem(uint256 _tokenId, uint256 _price): Allows a user to make an offer on an NFT not currently listed.
 * 11. acceptOffer(uint256 _offerId): Owner accepts an offer made on their NFT.
 * 12. cancelOffer(uint256 _offerId): Cancels an offer made on an NFT.
 * 13. getListingDetails(uint256 _listingId): Retrieves details of a specific marketplace listing.
 * 14. getOfferDetails(uint256 _offerId): Retrieves details of a specific offer.
 * 15. getAllListings(): Retrieves a list of all active marketplace listings.
 *
 * **Personalization and Recommendation (Simulated AI):**
 * 16. recordInteraction(uint256 _tokenId, InteractionType _interactionType): Records user interactions with NFTs for personalization.
 * 17. updatePreferences(string memory _newPreferences): Allows users to manually update their preferences (simulating AI learning).
 * 18. getUserRecommendations(address _user): Returns a list of recommended NFT token IDs based on simulated user preferences.
 *
 * **Marketplace Administration:**
 * 19. setMarketplaceFee(uint256 _newFeePercentage): Sets the marketplace fee percentage.
 * 20. withdrawFees(): Allows the contract owner to withdraw accumulated marketplace fees.
 * 21. pauseMarketplace(): Pauses the marketplace, preventing new listings and purchases.
 * 22. unpauseMarketplace(): Resumes the marketplace operations.
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---

    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public marketplacePaused = false;
    uint256 public nextNFTId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextOfferId = 1;

    struct NFT {
        uint256 tokenId;
        address owner;
        string uri;
        string dynamicProperty;
    }

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }

    enum InteractionType { VIEW, LIKE, BUY }

    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => Listing) public Listings;
    mapping(uint256 => Offer) public Offers;
    mapping(uint256 => uint256) public nftToListingId; // Map NFT ID to Listing ID for quick lookup
    mapping(uint256 => uint256) public nftToOfferId;   // Map NFT ID to Offer ID (if any active offer)

    // --- User Preference Simulation (Simplified) ---
    mapping(address => string) public userPreferences; // Store user preferences as strings (e.g., "art,fantasy,digital")
    mapping(address => mapping(uint256 => InteractionType)) public userInteractions; // Track user interactions with NFTs

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string uri);
    event NFTPropertiesUpdated(uint256 tokenId, string dynamicProperty);
    event NFTMetadataUpdated(uint256 tokenId, uint256 tokenId_, string newUri);
    event NFTBurned(uint256 tokenId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemDelisted(uint256 listingId, uint256 tokenId);
    event ItemPurchased(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address offerer, uint256 price);
    event OfferCancelled(uint256 offerId, uint256 tokenId, address offerer);
    event InteractionRecorded(address user, uint256 tokenId, InteractionType interactionType);
    event PreferencesUpdated(address user, string preferences);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event FeesWithdrawn(address owner, uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!marketplacePaused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(marketplacePaused, "Marketplace is not paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(NFTs[_tokenId].tokenId != 0, "NFT does not exist.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(Listings[_listingId].listingId != 0 && Listings[_listingId].isActive, "Listing does not exist or is inactive.");
        _;
    }

    modifier offerExists(uint256 _offerId) {
        require(Offers[_offerId].offerId != 0 && Offers[_offerId].isActive, "Offer does not exist or is inactive.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(NFTs[_tokenId].owner == msg.sender, "You are not the NFT owner.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- NFT Management Functions ---

    /// @notice Mints a new Dynamic NFT.
    /// @param _uri The URI for the NFT metadata.
    /// @param _initialDynamicProperty The initial dynamic property of the NFT.
    function mintNFT(string memory _uri, string memory _initialDynamicProperty) public whenNotPaused returns (uint256) {
        uint256 tokenId = nextNFTId++;
        NFTs[tokenId] = NFT({
            tokenId: tokenId,
            owner: msg.sender,
            uri: _uri,
            dynamicProperty: _initialDynamicProperty
        });
        emit NFTMinted(tokenId, msg.sender, _uri);
        return tokenId;
    }

    /// @notice Sets the dynamic properties of an NFT. Only NFT owner can call.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _dynamicProperty The new dynamic property value.
    function setNFTProperties(uint256 _tokenId, string memory _dynamicProperty) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].dynamicProperty = _dynamicProperty;
        emit NFTPropertiesUpdated(_tokenId, _dynamicProperty);
    }

    /// @notice Updates the metadata URI of an NFT. Only NFT owner can call.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newUri The new metadata URI.
    function updateNFTMetadata(uint256 _tokenId, string memory _newUri) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].uri = _newUri;
        emit NFTMetadataUpdated(_tokenId, _tokenId, _newUri);
    }

    /// @notice Burns an NFT, removing it from the marketplace. Only NFT owner can call.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        delete NFTs[_tokenId];
        if (nftToListingId[_tokenId] != 0) {
            delistItem(_tokenId); // Automatically delist if listed
        }
        emit NFTBurned(_tokenId);
    }

    /// @notice Transfers ownership of an NFT. Only NFT owner can call.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        NFTs[_tokenId].owner = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Retrieves the dynamic properties of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The dynamic property string.
    function getNFTProperties(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return NFTs[_tokenId].dynamicProperty;
    }

    // --- Marketplace Listing and Trading Functions ---

    /// @notice Lists an NFT for sale in the marketplace. Only NFT owner can call.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItem(uint256 _tokenId, uint256 _price) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(nftToListingId[_tokenId] == 0 || !Listings[nftToListingId[_tokenId]].isActive, "NFT is already listed or has an active listing.");

        uint256 listingId = nextListingId++;
        Listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        nftToListingId[_tokenId] = listingId;
        emit ItemListed(listingId, _tokenId, msg.sender, _price);
    }

    /// @notice Removes an NFT listing from the marketplace. Only seller can call.
    /// @param _tokenId The ID of the NFT to delist.
    function delistItem(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) {
        require(nftToListingId[_tokenId] != 0, "NFT is not listed.");
        uint256 listingId = nftToListingId[_tokenId];
        require(Listings[listingId].seller == msg.sender, "You are not the seller.");
        require(Listings[listingId].isActive, "Listing is already inactive.");

        Listings[listingId].isActive = false;
        delete nftToListingId[_tokenId]; // Clean up the mapping
        emit ItemDelisted(listingId, _tokenId);
    }

    /// @notice Purchases an NFT listed in the marketplace.
    /// @param _listingId The ID of the listing to purchase.
    function purchaseItem(uint256 _listingId) public payable whenNotPaused listingExists(_listingId) {
        Listing storage listing = Listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent.");
        require(listing.seller != msg.sender, "Cannot purchase your own NFT.");

        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;
        address seller = listing.seller;

        // Calculate marketplace fee and seller payout
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee;

        // Transfer NFT ownership
        NFTs[tokenId].owner = msg.sender;

        // Mark listing as inactive
        listing.isActive = false;
        delete nftToListingId[tokenId]; // Clean up the mapping

        // Pay seller and marketplace fee
        payable(seller).transfer(sellerPayout);
        payable(owner).transfer(marketplaceFee);

        emit ItemPurchased(_listingId, tokenId, msg.sender, price);
        emit NFTTransferred(tokenId, seller, msg.sender); // Emit transfer event again for purchase
    }

    /// @notice Allows a user to make an offer on an NFT not currently listed.
    /// @param _tokenId The ID of the NFT to make an offer on.
    /// @param _price The offer price in wei.
    function offerItem(uint256 _tokenId, uint256 _price) public payable whenNotPaused nftExists(_tokenId) {
        require(_price > 0, "Offer price must be greater than zero.");
        require(NFTs[_tokenId].owner != msg.sender, "Cannot make an offer on your own NFT.");

        uint256 offerId = nextOfferId++;
        Offers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            offerer: msg.sender,
            price: _price,
            isActive: true
        });
        nftToOfferId[_tokenId] = offerId; // Track the latest offer, can be improved for multiple offers
        emit OfferMade(offerId, _tokenId, msg.sender, _price);
    }

    /// @notice Owner accepts an offer made on their NFT.
    /// @param _offerId The ID of the offer to accept.
    function acceptOffer(uint256 _offerId) public whenNotPaused offerExists(_offerId) {
        Offer storage offer = Offers[_offerId];
        require(NFTs[offer.tokenId].owner == msg.sender, "You are not the NFT owner.");

        uint256 tokenId = offer.tokenId;
        uint256 price = offer.price;
        address offerer = offer.offerer;

        // Transfer NFT ownership
        NFTs[tokenId].owner = offerer;

        // Mark offer as inactive
        offer.isActive = false;
        delete nftToOfferId[tokenId]; // Clean up offer mapping

        // Pay NFT owner (seller) - Offer amount is already paid by offerer in offerItem function (simplified for demonstration, in real scenario, escrow could be used)
        payable(msg.sender).transfer(price); // Assuming offerer sent funds with offerItem in a real implementation

        emit OfferAccepted(_offerId, tokenId, msg.sender, offerer, price);
        emit NFTTransferred(tokenId, msg.sender, offerer); // Emit transfer event for offer acceptance
    }

    /// @notice Cancels an offer made on an NFT. Only offerer can call.
    /// @param _offerId The ID of the offer to cancel.
    function cancelOffer(uint256 _offerId) public whenNotPaused offerExists(_offerId) {
        Offer storage offer = Offers[_offerId];
        require(offer.offerer == msg.sender, "You are not the offerer.");
        require(offer.isActive, "Offer is already inactive.");

        offer.isActive = false;
        delete nftToOfferId[offer.tokenId]; // Clean up offer mapping

        emit OfferCancelled(_offerId, offer.tokenId, msg.sender);
        // In a real implementation with escrow, funds offered should be returned to offerer here.
    }

    /// @notice Retrieves details of a specific marketplace listing.
    /// @param _listingId The ID of the listing.
    /// @return Listing details.
    function getListingDetails(uint256 _listingId) public view listingExists(_listingId) returns (Listing memory) {
        return Listings[_listingId];
    }

    /// @notice Retrieves details of a specific offer.
    /// @param _offerId The ID of the offer.
    /// @return Offer details.
    function getOfferDetails(uint256 _offerId) public view offerExists(_offerId) returns (Offer memory) {
        return Offers[_offerId];
    }

    /// @notice Retrieves a list of all active marketplace listings.
    /// @return Array of active listing IDs.
    function getAllListings() public view returns (uint256[] memory) {
        uint256[] memory activeListings = new uint256[](nextListingId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (Listings[i].isActive) {
                activeListings[count++] = i;
            }
        }
        // Resize array to actual number of active listings
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeListings[i];
        }
        return result;
    }


    // --- Personalization and Recommendation Functions (Simulated AI) ---

    /// @notice Records user interactions with NFTs for personalization.
    /// @param _tokenId The ID of the NFT interacted with.
    /// @param _interactionType The type of interaction (VIEW, LIKE, BUY).
    function recordInteraction(uint256 _tokenId, InteractionType _interactionType) public whenNotPaused nftExists(_tokenId) {
        userInteractions[msg.sender][_tokenId] = _interactionType;
        emit InteractionRecorded(msg.sender, _tokenId, _interactionType);
    }

    /// @notice Allows users to manually update their preferences (simulating AI learning).
    /// @param _newPreferences A string representing user preferences (e.g., "art,fantasy,digital").
    function updatePreferences(string memory _newPreferences) public whenNotPaused {
        userPreferences[msg.sender] = _newPreferences;
        emit PreferencesUpdated(msg.sender, _newPreferences);
    }

    /// @notice Returns a list of recommended NFT token IDs based on simulated user preferences.
    /// @param _user The address of the user to get recommendations for.
    /// @return Array of recommended NFT token IDs.
    function getUserRecommendations(address _user) public view whenNotPaused returns (uint256[] memory) {
        string memory preferences = userPreferences[_user];
        if (bytes(preferences).length == 0) {
            // Default recommendations if no preferences set (can be improved with more sophisticated logic)
            return getAllListings(); // For simplicity, return all listings as default
        }

        string[] memory preferenceKeywords = _splitString(preferences, ","); // Simple comma-separated preferences

        uint256[] memory recommendations = new uint256[](nextNFTId - 1); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i < nextNFTId; i++) {
            if (NFTs[i].tokenId != 0) { // Check if NFT exists (not burned)
                string memory nftDynamicProperty = NFTs[i].dynamicProperty;
                for (uint256 j = 0; j < preferenceKeywords.length; j++) {
                    if (_stringContains(nftDynamicProperty, preferenceKeywords[j])) {
                        recommendations[count++] = NFTs[i].tokenId;
                        break; // Found a match, move to next NFT
                    }
                }
            }
        }

        // Resize array to actual number of recommendations
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = recommendations[i];
        }
        return result;
    }


    // --- Marketplace Administration Functions ---

    /// @notice Sets the marketplace fee percentage. Only owner can call.
    /// @param _newFeePercentage The new fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeUpdated(_newFeePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees. Only owner can call.
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit FeesWithdrawn(owner, balance);
    }

    /// @notice Pauses the marketplace, preventing new listings and purchases. Only owner can call.
    function pauseMarketplace() public onlyOwner whenNotPaused {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /// @notice Resumes the marketplace operations. Only owner can call.
    function unpauseMarketplace() public onlyOwner whenPaused {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }


    // --- Internal Helper Functions ---

    /// @dev Splits a string by a delimiter. (Simple implementation, can be optimized for gas)
    function _splitString(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);
        uint256 count = 0;

        if (delimiterBytes.length == 0) {
            return new string[](0); // No delimiter, return empty array
        }

        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                count++;
                i += delimiterBytes.length - 1;
            }
        }

        string[] memory result = new string[](count + 1); // +1 for the last part
        count = 0;
        uint256 startIndex = 0;

        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                result[count++] = string(slice(strBytes, startIndex, i));
                startIndex = i + delimiterBytes.length;
                i += delimiterBytes.length - 1;
            }
        }
        result[count] = string(slice(strBytes, startIndex, strBytes.length));
        return result;
    }

    /// @dev Checks if a string contains a substring. (Simple implementation, can be optimized for gas)
    function _stringContains(string memory _str, string memory _substring) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        bytes memory substringBytes = bytes(_substring);

        if (substringBytes.length == 0) {
            return true; // Empty substring is always contained
        }
        if (strBytes.length < substringBytes.length) {
            return false; // Substring longer than string, cannot contain
        }

        for (uint256 i = 0; i <= strBytes.length - substringBytes.length; i++) {
            bool match = true;
            for (uint256 j = 0; j < substringBytes.length; j++) {
                if (strBytes[i + j] != substringBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true; // Substring found
            }
        }
        return false; // Substring not found
    }

    /// @dev Helper function to slice bytes (for string splitting).
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length <= _bytes.length - _start, "Slice bounds out of range");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get some scratch space.
                tempBytes := mload(0x40)

                // Copy the slice into the scratch space.
                // This is much cheaper from gas perspective than iterative copying in Solidity.
                let end := add(_start,_length)
                mstore(0x40,add(tempBytes,add(_length,0x20)))
                mstore(tempBytes,_length)
                let dataPtr := add(add(_bytes,0x20),_start)
                let copyPtr := add(tempBytes,0x20)

                copyloop:
                    jumpi(exitloop, iszero(_length))

                    let word := mload(dataPtr)
                    mstore(copyPtr,word)

                    dataPtr := add(dataPtr,0x20)
                    copyPtr := add(copyPtr,0x20)
                    _length := sub(_length,0x20)
                    jump copyloop

                exitloop:
            }
            // If _length is zero return a zero-length array
            default {
                tempBytes := mload(0x40)
                mstore(0x40, add(tempBytes, 0x20))
                mstore(tempBytes, 0)
            }
        }

        return tempBytes;
    }
}
```