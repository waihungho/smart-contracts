```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace with personalized features.
 *
 * **Outline & Function Summary:**
 *
 * **1. Marketplace Core Functions:**
 *   - `listItem(uint256 _tokenId, uint256 _price)`: Allows users to list their NFTs for sale.
 *   - `buyItem(uint256 _listingId)`: Allows users to purchase listed NFTs.
 *   - `cancelListing(uint256 _listingId)`: Allows users to cancel their NFT listings.
 *   - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows users to update the price of their listed NFTs.
 *   - `getListing(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 *   - `getAllListings()`: Retrieves a list of all active NFT listings.
 *   - `getUserListings(address _user)`: Retrieves a list of listings created by a specific user.
 *   - `getMarketplaceBalance()`: Retrieves the contract's current balance.
 *   - `withdrawMarketplaceBalance(address _recipient)`: Allows the contract owner to withdraw marketplace fees.
 *   - `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 *   - `getMarketplaceFee()`: Retrieves the current marketplace fee percentage.
 *
 * **2. Dynamic NFT Features:**
 *   - `setDynamicPropertyRule(uint256 _tokenId, string memory _propertyName, string memory _rule)`: Allows NFT creators to set rules for dynamic properties (e.g., based on external data or on-chain events).
 *   - `updateDynamicProperty(uint256 _tokenId, string memory _propertyName, string memory _newValue)`: (Simulated external trigger) Allows an authorized entity to update dynamic properties based on defined rules.
 *   - `getDynamicProperties(uint256 _tokenId)`: Retrieves the dynamic properties and their current values for an NFT.
 *
 * **3. Personalized Recommendation (Simulated AI):**
 *   - `recordUserInteraction(address _user, uint256 _tokenId, string memory _interactionType)`: Records user interactions with NFTs (e.g., view, like, purchase).
 *   - `getUserRecommendations(address _user)`: (Basic recommendation engine) Returns a list of NFT listing IDs recommended to a user based on interaction history (simplified example, can be expanded).
 *   - `likeNFT(uint256 _listingId)`: Allows users to "like" an NFT listing, influencing recommendations.
 *   - `getNFTLikes(uint256 _listingId)`: Retrieves the number of likes for an NFT listing.
 *
 * **4. NFT Contract Management & Royalties:**
 *   - `setNFTContract(address _nftContractAddress)`: Allows the contract owner to set the address of the supported NFT contract.
 *   - `getNFTContract()`: Retrieves the address of the supported NFT contract.
 *   - `setDefaultRoyalty(uint256 _royaltyPercentage)`: Allows the contract owner to set a default royalty percentage for all NFTs.
 *   - `setTokenRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Allows NFT creators to override the default royalty for specific tokens.
 *   - `getRoyaltyInfo(uint256 _tokenId)`: Retrieves the royalty percentage for a given NFT token.
 *
 * **5. Utility & Admin Functions:**
 *   - `pauseMarketplace()`: Allows the contract owner to pause the marketplace.
 *   - `unpauseMarketplace()`: Allows the contract owner to unpause the marketplace.
 *   - `isMarketplacePaused()`: Checks if the marketplace is currently paused.
 *   - `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTMarketplace is Ownable, ERC165 {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC721 public nftContract; // Address of the supported NFT contract
    uint256 public marketplaceFeePercentage = 2; // Default marketplace fee percentage (2%)
    uint256 public defaultRoyaltyPercentage = 5; // Default royalty percentage for creators (5%)

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings; // listingId => Listing details
    uint256 public listingCounter = 0; // Counter for listing IDs

    mapping(uint256 => uint256) public tokenRoyalties; // tokenId => Royalty percentage (overrides default)

    mapping(uint256 => mapping(string => string)) public nftDynamicRules; // tokenId => propertyName => rule (e.g., "weather" => "getWeather()")
    mapping(uint256 => mapping(string => string)) public nftDynamicProperties; // tokenId => propertyName => currentValue

    mapping(address => mapping(uint256 => string)) public userInteractions; // user => tokenId => interactionType (e.g., "view", "like", "purchase")
    mapping(uint256 => uint256) public nftLikes; // listingId => Number of likes

    bool public paused = false;

    // --- Events ---

    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event DynamicPropertyRuleSet(uint256 tokenId, string propertyName, string rule);
    event DynamicPropertyUpdated(uint256 tokenId, string propertyName, string newValue);
    event UserInteractionRecorded(address user, uint256 tokenId, string interactionType);
    event NFTLiked(uint256 listingId, address user);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeSet(uint256 newFeePercentage);
    event DefaultRoyaltySet(uint256 newRoyaltyPercentage);
    event TokenRoyaltySet(uint256 tokenId, uint256 newRoyaltyPercentage);


    // --- Modifiers ---

    modifier onlyNFTContractOwner(uint256 _tokenId) {
        address tokenOwner = nftContract.ownerOf(_tokenId);
        require(tokenOwner == msg.sender, "Not NFT owner");
        _;
    }

    modifier onlyActiveListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier notPaused() {
        require(!paused, "Marketplace is paused");
        _;
    }

    // --- Constructor ---

    constructor(address _nftContractAddress) payable {
        setNFTContract(_nftContractAddress);
    }

    // --- 1. Marketplace Core Functions ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listItem(uint256 _tokenId, uint256 _price) external onlyNFTContractOwner(_tokenId) notPaused {
        require(_price > 0, "Price must be greater than zero");
        require(nftContract.getApproved(_tokenId) == address(this) || nftContract.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to transfer NFT");

        listingCounter++;
        listings[listingCounter] = Listing({
            listingId: listingCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        // Transfer NFT to marketplace contract (for escrow, optional, can be removed for non-custodial model)
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        emit ItemListed(listingCounter, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to buy a listed NFT.
     * @param _listingId The ID of the listing to buy.
     */
    function buyItem(uint256 _listingId) external payable notPaused onlyActiveListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds sent");
        require(listing.seller != msg.sender, "Cannot buy your own listing");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 royaltyAmount = listing.price.mul(getRoyaltyInfo(listing.tokenId)).div(100);
        uint256 sellerProceeds = listing.price.sub(marketplaceFee).sub(royaltyAmount);

        // Transfer proceeds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer royalty to creator (assuming creator is the original minter, can be more complex)
        // In a real implementation, you'd need to track creator address more accurately, possibly in the NFT contract itself.
        // For simplicity, we assume the seller is the creator in this example royalty distribution.
        payable(listing.seller).transfer(royaltyAmount); // Simplified royalty distribution - adjust as needed.

        // Transfer marketplace fee to contract owner
        payable(owner()).transfer(marketplaceFee);

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        listing.isActive = false; // Mark listing as inactive

        emit ItemBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) external notPaused onlyActiveListing(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.isActive = false; // Mark listing as inactive

        // Return NFT to seller (if escrow model was used)
        nftContract.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit ListingCancelled(_listingId);
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _listingId The ID of the listing to update.
     * @param _newPrice The new price in wei.
     */
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external notPaused onlyActiveListing(_listingId) {
        require(_newPrice > 0, "Price must be greater than zero");
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can update price");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _listingId The ID of the listing to retrieve.
     * @return Listing struct containing listing details.
     */
    function getListing(uint256 _listingId) external view returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Retrieves a list of all active NFT listings.
     * @return An array of Listing structs representing active listings.
     */
    function getAllListings() external view returns (Listing[] memory) {
        Listing[] memory activeListings = new Listing[](listingCounter); // Over-allocate, then filter
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].isActive) {
                activeListings[count] = listings[i];
                count++;
            }
        }

        // Resize the array to the actual number of active listings
        Listing[] memory trimmedListings = new Listing[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedListings[i] = activeListings[i];
        }
        return trimmedListings;
    }

    /**
     * @dev Retrieves a list of listings created by a specific user.
     * @param _user The address of the user.
     * @return An array of Listing structs representing listings by the user.
     */
    function getUserListings(address _user) external view returns (Listing[] memory) {
        Listing[] memory userListings = new Listing[](listingCounter); // Over-allocate, then filter
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].seller == _user && listings[i].isActive) {
                userListings[count] = listings[i];
                count++;
            }
        }

        // Resize the array to the actual number of user listings
        Listing[] memory trimmedListings = new Listing[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedListings[i] = userListings[i];
        }
        return trimmedListings;
    }

    /**
     * @dev Retrieves the contract's current balance.
     * @return The contract's balance in wei.
     */
    function getMarketplaceBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Allows the contract owner to withdraw marketplace fees.
     * @param _recipient The address to receive the withdrawn funds.
     */
    function withdrawMarketplaceBalance(address _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    /**
     * @dev Allows the contract owner to set the marketplace fee percentage.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Retrieves the current marketplace fee percentage.
     * @return The current marketplace fee percentage.
     */
    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFeePercentage;
    }


    // --- 2. Dynamic NFT Features ---

    /**
     * @dev Sets a rule for a dynamic property of an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _propertyName The name of the dynamic property.
     * @param _rule A string representing the rule (e.g., "getWeather()", "onChainEvent()").
     */
    function setDynamicPropertyRule(uint256 _tokenId, string memory _propertyName, string memory _rule) external onlyNFTContractOwner(_tokenId) {
        nftDynamicRules[_tokenId][_propertyName] = _rule;
        emit DynamicPropertyRuleSet(_tokenId, _propertyName, _rule);
    }

    /**
     * @dev Updates a dynamic property of an NFT based on its defined rule.
     *  (Simulated external trigger - in a real application, this would be triggered by an oracle or external service based on the rules)
     * @param _tokenId The ID of the NFT.
     * @param _propertyName The name of the dynamic property to update.
     * @param _newValue The new value for the dynamic property.
     */
    function updateDynamicProperty(uint256 _tokenId, string memory _propertyName, string memory _newValue) external onlyOwner { // For demonstration, onlyOwner can trigger updates. In real use, this would be more controlled.
        nftDynamicProperties[_tokenId][_propertyName] = _newValue;
        emit DynamicPropertyUpdated(_tokenId, _propertyName, _newValue);
    }

    /**
     * @dev Retrieves the dynamic properties and their current values for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return A mapping of property names to their current values.
     */
    function getDynamicProperties(uint256 _tokenId) external view returns (mapping(string => string) memory) {
        return nftDynamicProperties[_tokenId];
    }


    // --- 3. Personalized Recommendation (Simulated AI) ---

    /**
     * @dev Records a user interaction with an NFT.
     * @param _user The address of the user interacting.
     * @param _tokenId The ID of the NFT interacted with.
     * @param _interactionType The type of interaction (e.g., "view", "like", "purchase").
     */
    function recordUserInteraction(address _user, uint256 _tokenId, string memory _interactionType) external {
        userInteractions[_user][_tokenId] = _interactionType;
        emit UserInteractionRecorded(_user, _tokenId, _interactionType);
    }

    /**
     * @dev Gets basic NFT recommendations for a user based on their interaction history.
     *  (Simplified recommendation engine example - can be greatly expanded and improved)
     * @param _user The address of the user to get recommendations for.
     * @return An array of listing IDs recommended for the user.
     */
    function getUserRecommendations(address _user) external view returns (uint256[] memory) {
        // Simple recommendation logic: Recommend NFTs that are popular (have many likes)
        uint256[] memory recommendedListings = new uint256[](5); // Recommend up to 5 NFTs
        uint256 recommendationCount = 0;
        uint256 bestListingId = 0;
        uint256 maxLikes = 0;

        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].isActive) {
                if (nftLikes[i] > maxLikes) { // Simple popularity based on likes
                    maxLikes = nftLikes[i];
                    bestListingId = i;
                }
            }
        }

        if (bestListingId > 0) {
            recommendedListings[recommendationCount++] = bestListingId;
        }

        // In a real recommendation system, you'd use more sophisticated algorithms,
        // consider user interaction history, NFT categories, etc.

        // Resize to actual recommendations count
        uint256[] memory trimmedRecommendations = new uint256[](recommendationCount);
        for (uint256 i = 0; i < recommendationCount; i++) {
            trimmedRecommendations[i] = recommendedListings[i];
        }
        return trimmedRecommendations;
    }

    /**
     * @dev Allows a user to "like" an NFT listing.
     * @param _listingId The ID of the listing to like.
     */
    function likeNFT(uint256 _listingId) external notPaused onlyActiveListing(_listingId) {
        nftLikes[_listingId]++;
        emit NFTLiked(_listingId, msg.sender);
    }

    /**
     * @dev Retrieves the number of likes for an NFT listing.
     * @param _listingId The ID of the listing.
     * @return The number of likes for the listing.
     */
    function getNFTLikes(uint256 _listingId) external view returns (uint256) {
        return nftLikes[_listingId];
    }


    // --- 4. NFT Contract Management & Royalties ---

    /**
     * @dev Sets the address of the supported NFT contract.
     * @param _nftContractAddress The address of the ERC721 NFT contract.
     */
    function setNFTContract(address _nftContractAddress) public onlyOwner {
        require(_nftContractAddress != address(0), "Invalid NFT contract address");
        nftContract = IERC721(_nftContractAddress);
    }

    /**
     * @dev Retrieves the address of the supported NFT contract.
     * @return The address of the NFT contract.
     */
    function getNFTContract() external view returns (address) {
        return address(nftContract);
    }

    /**
     * @dev Sets the default royalty percentage for all NFTs.
     * @param _royaltyPercentage The default royalty percentage (e.g., 5 for 5%).
     */
    function setDefaultRoyalty(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        defaultRoyaltyPercentage = _royaltyPercentage;
        emit DefaultRoyaltySet(_royaltyPercentage);
    }

    /**
     * @dev Sets a specific royalty percentage for a given NFT token, overriding the default.
     * @param _tokenId The ID of the NFT token.
     * @param _royaltyPercentage The royalty percentage for this token.
     */
    function setTokenRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) external onlyNFTContractOwner(_tokenId) {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        tokenRoyalties[_tokenId] = _royaltyPercentage;
        emit TokenRoyaltySet(_tokenId, _royaltyPercentage);
    }

    /**
     * @dev Retrieves the royalty percentage for a given NFT token.
     * @param _tokenId The ID of the NFT token.
     * @return The royalty percentage for the token.
     */
    function getRoyaltyInfo(uint256 _tokenId) public view returns (uint256) {
        if (tokenRoyalties[_tokenId] > 0) {
            return tokenRoyalties[_tokenId];
        } else {
            return defaultRoyaltyPercentage;
        }
    }


    // --- 5. Utility & Admin Functions ---

    /**
     * @dev Pauses the marketplace, preventing new listings and purchases.
     */
    function pauseMarketplace() external onlyOwner {
        paused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace, allowing listings and purchases.
     */
    function unpauseMarketplace() external onlyOwner {
        paused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Checks if the marketplace is currently paused.
     * @return True if paused, false otherwise.
     */
    function isMarketplacePaused() external view returns (bool) {
        return paused;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}
```