```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Recommendations
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace that incorporates simulated AI-powered NFT recommendations based on user preferences and NFT attributes.
 *
 * **Outline & Function Summary:**
 *
 * **Core NFT Functionality:**
 * 1. `createNFT(string memory _metadataURI, string memory _dynamicTraits)`: Mints a new Dynamic NFT with associated metadata and dynamic traits.
 * 2. `updateNFTDynamicTraits(uint256 _nftId, string memory _newTraits)`: Allows the NFT owner to update the dynamic traits of their NFT.
 * 3. `getNFTDetails(uint256 _nftId)`: Retrieves detailed information about a specific NFT.
 * 4. `transferNFT(address _to, uint256 _nftId)`: Transfers ownership of an NFT to another address.
 * 5. `burnNFT(uint256 _nftId)`: Allows the NFT owner to burn their NFT, removing it from circulation.
 * 6. `tokenURI(uint256 _nftId)`:  Returns the metadata URI for a given NFT ID (ERC721 standard function).
 * 7. `ownerOf(uint256 _nftId)`: Returns the owner of a given NFT ID (ERC721 standard function).
 * 8. `totalSupply()`: Returns the total number of NFTs minted in this contract (ERC721 standard function).
 * 9. `balanceOf(address _owner)`: Returns the number of NFTs owned by a given address (ERC721 standard function).
 *
 * **Marketplace Functionality:**
 * 10. `listNFTForSale(uint256 _nftId, uint256 _price)`: Lists an NFT for sale in the marketplace at a specified price.
 * 11. `buyNFT(uint256 _listingId)`: Allows anyone to buy an NFT listed in the marketplace.
 * 12. `cancelListing(uint256 _listingId)`: Allows the seller to cancel their NFT listing.
 * 13. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 * 14. `getAllListings()`: Returns a list of all active NFT listings in the marketplace.
 * 15. `offerBid(uint256 _listingId, uint256 _bidAmount)`: Allows users to offer bids on NFTs listed for auction.
 * 16. `acceptBid(uint256 _listingId, uint256 _bidId)`: Allows the seller to accept a specific bid on their NFT auction.
 * 17. `finalizeAuction(uint256 _listingId)`:  Allows the seller to finalize an auction after a bidding period (can be time-based or bid count based - simplified here).
 * 18. `withdrawFunds()`: Allows sellers to withdraw their earnings from NFT sales.
 *
 * **AI-Powered Recommendation Simulation:**
 * 19. `setUserPreferences(string memory _preferences)`: Allows users to set their NFT preferences (e.g., categories, traits they like).
 * 20. `getUserPreferences(address _user)`: Retrieves the preferences of a specific user.
 * 21. `getRecommendedNFTsForUser(address _user)`: Simulates AI-powered recommendations by suggesting NFTs based on user preferences and NFT dynamic traits (simplified matching logic).
 * 22. `setRecommendationWeight(string memory _trait, uint256 _weight)`: Allows the contract owner to adjust the "weight" or importance of certain traits in the recommendation algorithm (simplistic).
 *
 * **Admin & Utility Functions:**
 * 23. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set the platform fee percentage for marketplace transactions.
 * 24. `getPlatformFee()`: Returns the current platform fee percentage.
 * 25. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 26. `pauseMarketplace()`: Pauses marketplace functionalities (buying, selling, bidding).
 * 27. `unpauseMarketplace()`: Resumes marketplace functionalities.
 */

contract DynamicNFTMarketplaceAI {
    // ** State Variables **

    // NFT Data
    struct NFT {
        uint256 nftId;
        address owner;
        string metadataURI;
        string dynamicTraits; // Can be JSON or structured string representing dynamic attributes
        uint256 creationTimestamp;
    }
    mapping(uint256 => NFT) public nfts;
    uint256 public nftCounter;

    // Marketplace Listing Data
    struct Listing {
        uint256 listingId;
        uint256 nftId;
        address seller;
        uint256 price; // Price in wei
        bool isActive;
        uint256 listingTimestamp;
        bool isAuction; // Flag to indicate if it's an auction
        uint256 auctionEndTime; // Optional: For time-based auctions
    }
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    // Bidding Data (for Auctions)
    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidAmount;
        uint256 bidTimestamp;
    }
    mapping(uint256 => Bid[]) public bidsForListing; // Listing ID => Array of Bids
    uint256 public bidCounter;

    // User Preferences for Recommendations
    mapping(address => string) public userPreferences; // User address => Preferences (e.g., comma-separated traits, JSON string)

    // Recommendation Trait Weights (Simplistic AI simulation)
    mapping(string => uint256) public recommendationWeights; // Trait name => Weight (higher weight = more important)

    // Platform Fees
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address payable public platformOwner;
    uint256 public accumulatedPlatformFees;

    // Pausable Marketplace
    bool public paused = false;

    // ** Events **
    event NFTCreated(uint256 nftId, address owner, string metadataURI);
    event NFTDynamicTraitsUpdated(uint256 nftId, string newTraits);
    event NFTListedForSale(uint256 listingId, uint256 nftId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 nftId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event BidOffered(uint256 bidId, uint256 listingId, address bidder, uint256 bidAmount);
    event BidAccepted(uint256 listingId, uint256 bidId, address seller, address bidder, uint256 price);
    event AuctionFinalized(uint256 listingId, uint256 nftId, address winner, uint256 finalPrice);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event UserPreferencesSet(address user, string preferences);
    event RecommendationWeightSet(string trait, uint256 weight);
    event NFTTransferred(uint256 nftId, address from, address to);
    event NFTBurned(uint256 nftId, address owner);

    // ** Modifiers **
    modifier onlyOwnerOfNFT(uint256 _nftId) {
        require(nfts[_nftId].owner == msg.sender, "Not the NFT owner");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "Not the listing seller");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Not platform owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused");
        _;
    }

    // ** Constructor **
    constructor() payable {
        platformOwner = payable(msg.sender);
    }

    // ** Core NFT Functionality **

    /**
     * @dev Creates a new Dynamic NFT.
     * @param _metadataURI URI pointing to the NFT's metadata (off-chain).
     * @param _dynamicTraits String representing dynamic traits of the NFT (e.g., JSON, CSV, etc.).
     */
    function createNFT(string memory _metadataURI, string memory _dynamicTraits) public returns (uint256) {
        nftCounter++;
        uint256 newNftId = nftCounter;
        nfts[newNftId] = NFT({
            nftId: newNftId,
            owner: msg.sender,
            metadataURI: _metadataURI,
            dynamicTraits: _dynamicTraits,
            creationTimestamp: block.timestamp
        });
        emit NFTCreated(newNftId, msg.sender, _metadataURI);
        return newNftId;
    }

    /**
     * @dev Updates the dynamic traits of an NFT. Only the NFT owner can call this.
     * @param _nftId ID of the NFT to update.
     * @param _newTraits New string representing the dynamic traits.
     */
    function updateNFTDynamicTraits(uint256 _nftId, string memory _newTraits) public onlyOwnerOfNFT(_nftId) {
        nfts[_nftId].dynamicTraits = _newTraits;
        emit NFTDynamicTraitsUpdated(_nftId, _newTraits);
    }

    /**
     * @dev Retrieves detailed information about a specific NFT.
     * @param _nftId ID of the NFT.
     * @return NFT struct containing NFT details.
     */
    function getNFTDetails(uint256 _nftId) public view returns (NFT memory) {
        require(nfts[_nftId].nftId != 0, "NFT does not exist");
        return nfts[_nftId];
    }

    /**
     * @dev Transfers ownership of an NFT to another address.
     * @param _to Address to transfer the NFT to.
     * @param _nftId ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _nftId) public onlyOwnerOfNFT(_nftId) {
        require(_to != address(0), "Invalid recipient address");
        nfts[_nftId].owner = _to;
        emit NFTTransferred(_nftId, msg.sender, _to);
    }

    /**
     * @dev Burns an NFT, removing it from circulation. Only the NFT owner can call this.
     * @param _nftId ID of the NFT to burn.
     */
    function burnNFT(uint256 _nftId) public onlyOwnerOfNFT(_nftId) {
        require(nfts[_nftId].nftId != 0, "NFT does not exist");
        address owner = nfts[_nftId].owner;
        delete nfts[_nftId]; // Remove NFT from mapping effectively burning it
        emit NFTBurned(_nftId, owner);
    }

    /**
     * @dev ERC721 standard function to get the token URI. In this example, directly returns stored URI.
     * @param _nftId ID of the NFT.
     * @return Metadata URI string.
     */
    function tokenURI(uint256 _nftId) public view returns (string memory) {
        require(nfts[_nftId].nftId != 0, "NFT does not exist");
        return nfts[_nftId].metadataURI;
    }

    /**
     * @dev ERC721 standard function to get the owner of an NFT.
     * @param _nftId ID of the NFT.
     * @return Owner address.
     */
    function ownerOf(uint256 _nftId) public view returns (address) {
        require(nfts[_nftId].nftId != 0, "NFT does not exist");
        return nfts[_nftId].owner;
    }

    /**
     * @dev ERC721 standard function to get the total supply of NFTs.
     * @return Total NFT count.
     */
    function totalSupply() public view returns (uint256) {
        return nftCounter;
    }

    /**
     * @dev ERC721 standard function to get the balance of NFTs owned by an address.
     * @param _owner Address to check balance for.
     * @return Number of NFTs owned.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 1; i <= nftCounter; i++) {
            if (nfts[i].owner == _owner) {
                balance++;
            }
        }
        return balance;
    }

    // ** Marketplace Functionality **

    /**
     * @dev Lists an NFT for sale in the marketplace.
     * @param _nftId ID of the NFT to list.
     * @param _price Price in wei.
     */
    function listNFTForSale(uint256 _nftId, uint256 _price) public onlyOwnerOfNFT(_nftId) whenNotPaused {
        require(nfts[_nftId].nftId != 0, "NFT does not exist");
        require(listings[listingCounter].nftId == 0, "Listing ID already exists, internal error"); // Sanity check - should not happen normally

        listingCounter++;
        uint256 newListingId = listingCounter;
        listings[newListingId] = Listing({
            listingId: newListingId,
            nftId: _nftId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            listingTimestamp: block.timestamp,
            isAuction: false,
            auctionEndTime: 0 // Not an auction
        });
        emit NFTListedForSale(newListingId, _nftId, msg.sender, _price);
    }

    /**
     * @dev Allows anyone to buy an NFT listed in the marketplace.
     * @param _listingId ID of the listing to buy.
     */
    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        require(!listings[_listingId].isAuction, "Cannot buy an auction listing directly"); // Ensure not an auction
        require(msg.value >= listings[_listingId].price, "Insufficient funds");

        Listing memory currentListing = listings[_listingId];
        NFT storage nftToBuy = nfts[currentListing.nftId];

        // Transfer funds (seller + platform fee)
        uint256 platformFee = (currentListing.price * platformFeePercentage) / 100;
        uint256 sellerPayout = currentListing.price - platformFee;

        accumulatedPlatformFees += platformFee;
        payable(currentListing.seller).transfer(sellerPayout);

        // Transfer NFT ownership
        nftToBuy.owner = msg.sender;
        listings[_listingId].isActive = false; // Deactivate listing

        emit NFTBought(_listingId, currentListing.nftId, msg.sender, currentListing.price);
        emit NFTTransferred(currentListing.nftId, currentListing.seller, msg.sender);

        // Refund any extra ETH sent
        if (msg.value > currentListing.price) {
            payable(msg.sender).transfer(msg.value - currentListing.price);
        }
    }

    /**
     * @dev Cancels an NFT listing. Only the seller can cancel.
     * @param _listingId ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public onlyListingSeller(_listingId) whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId);
    }

    /**
     * @dev Retrieves details of a specific marketplace listing.
     * @param _listingId ID of the listing.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        require(listings[_listingId].listingId != 0, "Listing does not exist");
        return listings[_listingId];
    }

    /**
     * @dev Returns a list of all active NFT listings in the marketplace.
     * @return Array of active Listing structs.
     */
    function getAllListings() public view returns (Listing[] memory) {
        Listing[] memory activeListings = new Listing[](listingCounter); // Maximum possible size, might be less
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].isActive) {
                activeListings[count] = listings[i];
                count++;
            }
        }

        // Resize array to actual count of active listings
        Listing[] memory resultListings = new Listing[](count);
        for (uint256 i = 0; i < count; i++) {
            resultListings[i] = activeListings[i];
        }
        return resultListings;
    }

    /**
     * @dev Allows users to offer bids on NFTs listed for auction.
     * @param _listingId ID of the auction listing.
     * @param _bidAmount Amount of ETH offered in wei.
     */
    function offerBid(uint256 _listingId, uint256 _bidAmount) public payable whenNotPaused {
        require(listings[_listingId].isActive, "Auction listing is not active");
        require(listings[_listingId].isAuction, "Listing is not an auction");
        require(msg.value >= _bidAmount, "Insufficient funds for bid");

        Bid[] storage currentBids = bidsForListing[_listingId];
        if (currentBids.length > 0) {
            require(_bidAmount > currentBids[currentBids.length - 1].bidAmount, "Bid amount must be higher than current highest bid");
        } else {
            require(_bidAmount > 0, "Bid amount must be greater than zero"); // First bid must be positive
        }

        bidCounter++;
        uint256 newBidId = bidCounter;
        bidsForListing[_listingId].push(Bid({
            bidId: newBidId,
            listingId: _listingId,
            bidder: msg.sender,
            bidAmount: _bidAmount,
            bidTimestamp: block.timestamp
        }));

        emit BidOffered(newBidId, _listingId, msg.sender, _bidAmount);

        // Refund any extra ETH sent (only refund if overbid in a real auction scenario, simplified here)
        if (msg.value > _bidAmount) {
            payable(msg.sender).transfer(msg.value - _bidAmount);
        }
    }

    /**
     * @dev Allows the seller to accept a specific bid on their NFT auction.
     * @param _listingId ID of the auction listing.
     * @param _bidId ID of the bid to accept.
     */
    function acceptBid(uint256 _listingId, uint256 _bidId) public onlyListingSeller(_listingId) whenNotPaused {
        require(listings[_listingId].isActive, "Auction listing is not active");
        require(listings[_listingId].isAuction, "Listing is not an auction");

        Bid[] storage currentBids = bidsForListing[_listingId];
        Bid memory acceptedBid;
        bool bidFound = false;
        for (uint256 i = 0; i < currentBids.length; i++) {
            if (currentBids[i].bidId == _bidId) {
                acceptedBid = currentBids[i];
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Bid not found for this listing");

        NFT storage nftToAuction = nfts[listings[_listingId].nftId];

        // Transfer funds (seller + platform fee)
        uint256 platformFee = (acceptedBid.bidAmount * platformFeePercentage) / 100;
        uint256 sellerPayout = acceptedBid.bidAmount - platformFee;

        accumulatedPlatformFees += platformFee;
        payable(listings[_listingId].seller).transfer(sellerPayout);

        // Transfer NFT ownership
        nftToAuction.owner = acceptedBid.bidder;
        listings[_listingId].isActive = false; // Deactivate listing

        emit BidAccepted(_listingId, _bidId, listings[_listingId].seller, acceptedBid.bidder, acceptedBid.bidAmount);
        emit AuctionFinalized(_listingId, listings[_listingId].nftId, acceptedBid.bidder, acceptedBid.bidAmount);
        emit NFTTransferred(listings[_listingId].nftId, listings[_listingId].seller, acceptedBid.bidder);
    }

    /**
     * @dev Allows the seller to finalize an auction after a bidding period (simplified, no time limit implemented here).
     *      In a real system, you would have auctionEndTime and a check against block.timestamp.
     * @param _listingId ID of the auction listing.
     */
    function finalizeAuction(uint256 _listingId) public onlyListingSeller(_listingId) whenNotPaused {
        require(listings[_listingId].isActive, "Auction listing is not active");
        require(listings[_listingId].isAuction, "Listing is not an auction");

        Bid[] storage currentBids = bidsForListing[_listingId];
        require(currentBids.length > 0, "No bids placed on this auction");

        Bid memory highestBid = currentBids[currentBids.length - 1]; // Assuming bids are sorted by amount

        acceptBid(_listingId, highestBid.bidId); // Re-use acceptBid logic for finalization
    }

    /**
     * @dev Allows sellers to withdraw their earnings from NFT sales.
     */
    function withdrawFunds() public whenNotPaused {
        uint256 sellerBalance = 0; // In a real system, you would track individual seller balances
        // For simplicity, assuming seller's earnings are directly sent during buyNFT/acceptBid

        // In a more complex system, you would track balances and allow withdrawal.
        // This function here is a placeholder to illustrate the idea.
        // In this simplified example, sellers receive funds immediately during sales.
        // Consider implementing a balance tracking system for more realistic withdrawal functionality.
        revert("Withdrawal functionality not fully implemented in this simplified example. Funds are transferred directly during sales.");
    }

    // ** AI-Powered Recommendation Simulation **

    /**
     * @dev Allows users to set their NFT preferences.
     * @param _preferences String representing user preferences (e.g., "art, cyberpunk, futuristic").
     */
    function setUserPreferences(string memory _preferences) public whenNotPaused {
        userPreferences[msg.sender] = _preferences;
        emit UserPreferencesSet(msg.sender, _preferences);
    }

    /**
     * @dev Retrieves the preferences of a specific user.
     * @param _user Address of the user.
     * @return String representing user preferences.
     */
    function getUserPreferences(address _user) public view returns (string memory) {
        return userPreferences[_user];
    }

    /**
     * @dev Simulates AI-powered recommendations for a user based on their preferences and NFT traits.
     *      Simplified matching logic: Checks for keyword overlap between user preferences and NFT dynamic traits.
     * @param _user Address of the user to get recommendations for.
     * @return Array of NFT IDs recommended for the user.
     */
    function getRecommendedNFTsForUser(address _user) public view whenNotPaused returns (uint256[] memory) {
        string memory userPrefs = userPreferences[_user];
        require(bytes(userPrefs).length > 0, "Set user preferences first");

        string[] memory prefKeywords = _splitString(userPrefs, ","); // Simple comma-separated keyword split

        uint256[] memory recommendedNFTIds = new uint256[](nftCounter); // Max possible size
        uint256 recommendationCount = 0;

        for (uint256 i = 1; i <= nftCounter; i++) {
            if (nfts[i].nftId != 0) { // Check if NFT exists (not burned)
                string memory nftTraits = nfts[i].dynamicTraits;
                string[] memory nftTraitKeywords = _splitString(nftTraits, ","); // Assume NFT traits are also comma-separated

                uint256 matchScore = 0;
                for (uint256 j = 0; j < prefKeywords.length; j++) {
                    for (uint256 k = 0; k < nftTraitKeywords.length; k++) {
                        if (keccak256(bytes(prefKeywords[j])) == keccak256(bytes(nftTraitKeywords[k]))) {
                            uint256 weight = recommendationWeights[prefKeywords[j]]; // Get weight for this trait
                            if (weight == 0) {
                                weight = 1; // Default weight if not set
                            }
                            matchScore += weight;
                        }
                    }
                }

                if (matchScore > 0) { // Simple threshold - any match is considered a recommendation
                    recommendedNFTIds[recommendationCount] = nfts[i].nftId;
                    recommendationCount++;
                }
            }
        }

        // Resize to actual number of recommendations
        uint256[] memory finalRecommendations = new uint256[](recommendationCount);
        for (uint256 i = 0; i < recommendationCount; i++) {
            finalRecommendations[i] = recommendedNFTIds[i];
        }
        return finalRecommendations;
    }

    /**
     * @dev Allows the contract owner to set the recommendation weight for a specific trait.
     *      This is a very simplistic way to influence the "AI" recommendation algorithm.
     * @param _trait Trait name (keyword).
     * @param _weight Weight value (higher = more important).
     */
    function setRecommendationWeight(string memory _trait, uint256 _weight) public onlyPlatformOwner whenNotPaused {
        recommendationWeights[_trait] = _weight;
        emit RecommendationWeightSet(_trait, _weight);
    }


    // ** Admin & Utility Functions **

    /**
     * @dev Sets the platform fee percentage for marketplace transactions. Only callable by the platform owner.
     * @param _feePercentage Fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyPlatformOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Returns the current platform fee percentage.
     * @return Platform fee percentage.
     */
    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyPlatformOwner whenNotPaused {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(platformOwner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, platformOwner);
    }

    /**
     * @dev Pauses marketplace functionalities (buying, selling, bidding). Only callable by the platform owner.
     */
    function pauseMarketplace() public onlyPlatformOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Resumes marketplace functionalities. Only callable by the platform owner.
     */
    function unpauseMarketplace() public onlyPlatformOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused();
    }

    // ** Internal Utility Function **
    /**
     * @dev Internal helper function to split a string by a delimiter.
     * @param _str String to split.
     * @param _delimiter Delimiter string.
     * @return Array of strings after splitting.
     */
    function _splitString(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);

        if (delimiterBytes.length == 0 || strBytes.length == 0) {
            return new string[](0);
        }

        uint256[] memory delimiterIndices = new uint256[](strBytes.length);
        uint256 delimiterCount = 0;
        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                delimiterIndices[delimiterCount] = i;
                delimiterCount++;
                i += delimiterBytes.length - 1;
            }
        }

        string[] memory result = new string[](delimiterCount + 1);
        uint256 startIndex = 0;
        for (uint256 i = 0; i < delimiterCount; i++) {
            uint256 endIndex = delimiterIndices[i];
            bytes memory tempBytes = new bytes(endIndex - startIndex);
            for (uint256 j = 0; j < endIndex - startIndex; j++) {
                tempBytes[j] = strBytes[startIndex + j];
            }
            result[i] = string(tempBytes);
            startIndex = endIndex + delimiterBytes.length;
        }

        bytes memory lastPartBytes = new bytes(strBytes.length - startIndex);
        for (uint256 i = 0; i < strBytes.length - startIndex; i++) {
            lastPartBytes[i] = strBytes[startIndex + i];
        }
        result[delimiterCount] = string(lastPartBytes);

        return result;
    }
}
```