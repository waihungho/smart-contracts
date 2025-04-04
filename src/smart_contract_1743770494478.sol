```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Data Marketplace with Privacy & Reputation
 * @author Bard (Example Smart Contract)
 * @dev A sophisticated decentralized data marketplace with features for dynamic data updates,
 *      privacy-preserving data access using encryption key exchange, and a reputation system
 *      for data providers and buyers. This contract aims to be a novel implementation and
 *      avoid duplication of common open-source patterns.
 *
 * **Outline & Function Summary:**
 *
 * **Data Listing & Management:**
 * 1. `listData(string _title, string _description, string _dataHash, uint256 _price, string _encryptionHint)`: Allows data providers to list new data.
 * 2. `updateDataListing(uint256 _listingId, string _title, string _description, uint256 _price, string _encryptionHint)`: Allows providers to update listing details.
 * 3. `removeDataListing(uint256 _listingId)`: Allows providers to remove their data listing.
 * 4. `getDataListing(uint256 _listingId)`: Retrieves details of a specific data listing.
 * 5. `getDataListingsByProvider(address _provider)`: Retrieves all listings by a specific provider.
 * 6. `searchDataListings(string _searchTerm)`: Searches data listings based on keywords in title or description.
 * 7. `getTotalListings()`: Returns the total number of active data listings.
 * 8. `getAllListingIds()`: Returns an array of all active listing IDs.
 *
 * **Data Access & Purchase:**
 * 9. `buyDataAccess(uint256 _listingId)`: Allows buyers to purchase access to a data listing.
 * 10. `requestDecryptionKey(uint256 _listingId)`: Allows buyers to request the decryption key from the provider after purchase.
 * 11. `provideDecryptionKey(uint256 _listingId, string _decryptionKey)`: Allows providers to securely provide the decryption key to the buyer (off-chain communication is assumed for actual key delivery after this function).
 * 12. `checkDataAccess(uint256 _listingId, address _buyer)`: Checks if a buyer has purchased access to a specific data listing.
 *
 * **Reputation System:**
 * 13. `rateDataProvider(uint256 _listingId, uint8 _rating, string _review)`: Allows buyers to rate and review data providers after purchase.
 * 14. `getProviderRating(address _provider)`: Retrieves the average rating of a data provider.
 * 15. `getProviderReviews(address _provider)`: Retrieves reviews for a data provider.
 * 16. `reportDataListing(uint256 _listingId, string _reportReason)`: Allows users to report a data listing for inappropriate content or issues.
 *
 * **Dynamic Data Updates:**
 * 17. `updateDataHash(uint256 _listingId, string _newDataHash)`: Allows providers to update the data hash for a listing (dynamic data).
 * 18. `getDataHash(uint256 _listingId)`: Retrieves the latest data hash for a listing.
 *
 * **Platform Management & Fees:**
 * 19. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set the platform fee percentage.
 * 20. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 21. `pauseMarketplace()`: Allows the contract owner to pause the marketplace in case of emergency.
 * 22. `unpauseMarketplace()`: Allows the contract owner to unpause the marketplace.
 */

contract DynamicDataMarketplace {

    // --- State Variables ---

    struct DataListing {
        uint256 listingId;
        address provider;
        string title;
        string description;
        string dataHash; // Hash of the data (stored off-chain)
        uint256 price;
        string encryptionHint; // Hint about encryption method (e.g., "AES-256")
        uint256 createdAt;
        uint256 lastUpdated;
        bool isActive;
    }

    struct PurchaseRecord {
        uint256 listingId;
        address buyer;
        uint256 purchaseTime;
        bool decryptionKeyRequested;
        bool decryptionKeyProvided;
    }

    struct ProviderRating {
        uint256 totalRating;
        uint256 ratingCount;
    }

    mapping(uint256 => DataListing) public dataListings; // listingId => DataListing
    mapping(uint256 => PurchaseRecord) public purchaseRecords; // (listingId, buyer) => PurchaseRecord - Using listingId as primary key for simplicity, might need to adjust for scalability
    mapping(address => ProviderRating) public providerRatings; // provider address => ProviderRating
    mapping(address => mapping(uint256 => string[])) public providerReviews; // provider address => listingId => reviews array
    mapping(uint256 => address[]) public listingBuyers; // listingId => array of buyer addresses
    mapping(uint256 => string[]) public listingReports; // listingId => array of report reasons

    uint256 public listingCounter;
    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address public owner;
    bool public paused = false;


    // --- Events ---

    event DataListed(uint256 listingId, address provider, string title);
    event DataUpdated(uint256 listingId, string title);
    event DataRemoved(uint256 listingId);
    event DataAccessPurchased(uint256 listingId, address buyer);
    event DecryptionKeyRequested(uint256 listingId, address buyer);
    event DecryptionKeyProvided(uint256 listingId, address provider, address buyer);
    event DataProviderRated(uint256 listingId, address buyer, address provider, uint8 rating);
    event DataListingReported(uint256 listingId, address reporter, string reason);
    event DataHashUpdated(uint256 listingId, string newDataHash);
    event MarketplacePaused(address owner);
    event MarketplaceUnpaused(address owner);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(address owner, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Marketplace is not paused.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(dataListings[_listingId].isActive, "Data listing does not exist or is inactive.");
        _;
    }

    modifier onlyDataProvider(uint256 _listingId) {
        require(dataListings[_listingId].provider == msg.sender, "Only the data provider can call this function.");
        _;
    }

    modifier onlyBuyer(uint256 _listingId) {
        bool hasPurchased = false;
        for (uint i = 0; i < listingBuyers[_listingId].length; i++) {
            if (listingBuyers[_listingId][i] == msg.sender) {
                hasPurchased = true;
                break;
            }
        }
        require(hasPurchased, "You have not purchased access to this data.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        listingCounter = 0;
    }


    // --- Data Listing & Management Functions ---

    /// @notice Allows data providers to list new data on the marketplace.
    /// @param _title Title of the data listing.
    /// @param _description Description of the data listing.
    /// @param _dataHash Hash of the data (stored off-chain).
    /// @param _price Price to access the data in wei.
    /// @param _encryptionHint Hint about the encryption method used.
    function listData(
        string memory _title,
        string memory _description,
        string memory _dataHash,
        uint256 _price,
        string memory _encryptionHint
    ) public whenNotPaused {
        listingCounter++;
        dataListings[listingCounter] = DataListing({
            listingId: listingCounter,
            provider: msg.sender,
            title: _title,
            description: _description,
            dataHash: _dataHash,
            price: _price,
            encryptionHint: _encryptionHint,
            createdAt: block.timestamp,
            lastUpdated: block.timestamp,
            isActive: true
        });
        emit DataListed(listingCounter, msg.sender, _title);
    }

    /// @notice Allows data providers to update details of an existing data listing.
    /// @param _listingId ID of the data listing to update.
    /// @param _title New title for the listing.
    /// @param _description New description for the listing.
    /// @param _price New price to access the data.
    /// @param _encryptionHint New encryption hint.
    function updateDataListing(
        uint256 _listingId,
        string memory _title,
        string memory _description,
        uint256 _price,
        string memory _encryptionHint
    ) public whenNotPaused listingExists(_listingId) onlyDataProvider(_listingId) {
        DataListing storage listing = dataListings[_listingId];
        listing.title = _title;
        listing.description = _description;
        listing.price = _price;
        listing.encryptionHint = _encryptionHint;
        listing.lastUpdated = block.timestamp;
        emit DataUpdated(_listingId, _title);
    }

    /// @notice Allows data providers to remove their data listing from the marketplace.
    /// @param _listingId ID of the data listing to remove.
    function removeDataListing(uint256 _listingId) public whenNotPaused listingExists(_listingId) onlyDataProvider(_listingId) {
        dataListings[_listingId].isActive = false;
        emit DataRemoved(_listingId);
    }

    /// @notice Retrieves details of a specific data listing.
    /// @param _listingId ID of the data listing to retrieve.
    /// @return DataListing struct containing listing details.
    function getDataListing(uint256 _listingId) public view listingExists(_listingId) returns (DataListing memory) {
        return dataListings[_listingId];
    }

    /// @notice Retrieves all data listings created by a specific provider.
    /// @param _provider Address of the data provider.
    /// @return An array of DataListing structs.
    function getDataListingsByProvider(address _provider) public view returns (DataListing[] memory) {
        DataListing[] memory providerListings = new DataListing[](listingCounter); // Max size initially, will resize later
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (dataListings[i].isActive && dataListings[i].provider == _provider) {
                providerListings[count] = dataListings[i];
                count++;
            }
        }
        // Resize the array to the actual number of listings
        DataListing[] memory result = new DataListing[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = providerListings[i];
        }
        return result;
    }

    /// @notice Searches data listings based on keywords in the title or description.
    /// @param _searchTerm Keyword to search for.
    /// @return An array of DataListing structs that match the search term.
    function searchDataListings(string memory _searchTerm) public view returns (DataListing[] memory) {
        DataListing[] memory searchResults = new DataListing[](listingCounter); // Max size initially, will resize later
        uint256 count = 0;
        string memory lowerSearchTerm = _stringToLowerCase(_searchTerm); // For case-insensitive search
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (dataListings[i].isActive) {
                string memory lowerTitle = _stringToLowerCase(dataListings[i].title);
                string memory lowerDescription = _stringToLowerCase(dataListings[i].description);
                if (_stringContains(lowerTitle, lowerSearchTerm) || _stringContains(lowerDescription, lowerSearchTerm)) {
                    searchResults[count] = dataListings[i];
                    count++;
                }
            }
        }
        // Resize the array to the actual number of search results
        DataListing[] memory result = new DataListing[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = searchResults[i];
        }
        return result;
    }

    /// @notice Returns the total number of active data listings in the marketplace.
    /// @return Total number of active listings.
    function getTotalListings() public view returns (uint256) {
        uint256 activeListings = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (dataListings[i].isActive) {
                activeListings++;
            }
        }
        return activeListings;
    }

    /// @notice Returns an array of all active data listing IDs.
    /// @return An array of listing IDs.
    function getAllListingIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](listingCounter); // Max size initially, will resize later
        uint256 count = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (dataListings[i].isActive) {
                ids[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active listing IDs
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ids[i];
        }
        return result;
    }


    // --- Data Access & Purchase Functions ---

    /// @notice Allows buyers to purchase access to a data listing.
    /// @param _listingId ID of the data listing to purchase access for.
    function buyDataAccess(uint256 _listingId) public payable whenNotPaused listingExists(_listingId) {
        require(msg.value >= dataListings[_listingId].price, "Insufficient funds to purchase data access.");

        uint256 platformFee = (dataListings[_listingId].price * platformFeePercentage) / 100;
        uint256 providerShare = dataListings[_listingId].price - platformFee;

        // Transfer funds to provider and platform
        payable(dataListings[_listingId].provider).transfer(providerShare);
        payable(owner).transfer(platformFee);

        // Record purchase
        purchaseRecords[_listingId].listingId = _listingId; // Potentially redundant but for clarity
        purchaseRecords[_listingId].buyer = msg.sender;
        purchaseRecords[_listingId].purchaseTime = block.timestamp;
        purchaseRecords[_listingId].decryptionKeyRequested = false;
        purchaseRecords[_listingId].decryptionKeyProvided = false;

        listingBuyers[_listingId].push(msg.sender); // Add buyer to the listing's buyer list

        emit DataAccessPurchased(_listingId, msg.sender);

        // Refund any excess ETH sent
        if (msg.value > dataListings[_listingId].price) {
            payable(msg.sender).transfer(msg.value - dataListings[_listingId].price);
        }
    }

    /// @notice Allows buyers to request the decryption key from the provider after purchasing access.
    /// @param _listingId ID of the data listing.
    function requestDecryptionKey(uint256 _listingId) public whenNotPaused listingExists(_listingId) onlyBuyer(_listingId) {
        require(!purchaseRecords[_listingId].decryptionKeyRequested, "Decryption key already requested.");
        purchaseRecords[_listingId].decryptionKeyRequested = true;
        emit DecryptionKeyRequested(_listingId, msg.sender);
        // In a real-world scenario, trigger off-chain communication to the data provider to deliver the key.
        // This could involve events, oracle services, or direct provider notification.
    }

    /// @notice Allows data providers to securely indicate on-chain that they have provided the decryption key to the buyer.
    /// @param _listingId ID of the data listing.
    /// @param _decryptionKey String representing the decryption key (Note: In a real application, key exchange would be handled off-chain securely).
    function provideDecryptionKey(uint256 _listingId, string memory _decryptionKey) public whenNotPaused listingExists(_listingId) onlyDataProvider(_listingId) {
        require(purchaseRecords[_listingId].decryptionKeyRequested, "Decryption key must be requested first.");
        require(!purchaseRecords[_listingId].decryptionKeyProvided, "Decryption key already provided.");
        purchaseRecords[_listingId].decryptionKeyProvided = true;
        emit DecryptionKeyProvided(_listingId, msg.sender, purchaseRecords[_listingId].buyer);
        // In a real-world scenario, the actual decryption key _decryptionKey would be delivered securely off-chain
        // using methods like encrypted messaging, P2P channels, or secure key exchange protocols.
        // This on-chain function just serves as a record that the provider has initiated the key delivery process.
    }

    /// @notice Checks if a buyer has purchased access to a specific data listing.
    /// @param _listingId ID of the data listing.
    /// @param _buyer Address of the buyer to check.
    /// @return True if the buyer has purchased access, false otherwise.
    function checkDataAccess(uint256 _listingId, address _buyer) public view listingExists(_listingId) returns (bool) {
        for (uint i = 0; i < listingBuyers[_listingId].length; i++) {
            if (listingBuyers[_listingId][i] == _buyer) {
                return true;
            }
        }
        return false;
    }


    // --- Reputation System Functions ---

    /// @notice Allows buyers to rate and review a data provider after purchasing data access.
    /// @param _listingId ID of the data listing related to the provider being rated.
    /// @param _rating Rating given by the buyer (e.g., 1 to 5).
    /// @param _review Text review provided by the buyer.
    function rateDataProvider(uint256 _listingId, uint8 _rating, string memory _review) public whenNotPaused listingExists(_listingId) onlyBuyer(_listingId) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        address providerAddress = dataListings[_listingId].provider;
        ProviderRating storage ratingData = providerRatings[providerAddress];

        ratingData.totalRating += _rating;
        ratingData.ratingCount++;

        providerReviews[providerAddress][_listingId].push(_review);

        emit DataProviderRated(_listingId, msg.sender, providerAddress, _rating);
    }

    /// @notice Retrieves the average rating of a data provider.
    /// @param _provider Address of the data provider.
    /// @return Average rating (or 0 if no ratings yet).
    function getProviderRating(address _provider) public view returns (uint256) {
        ProviderRating storage ratingData = providerRatings[_provider];
        if (ratingData.ratingCount == 0) {
            return 0;
        }
        return ratingData.totalRating / ratingData.ratingCount;
    }

    /// @notice Retrieves all reviews for a data provider associated with a specific listing (for now, can be extended).
    /// @param _provider Address of the data provider.
    /// @return An array of review strings.
    function getProviderReviews(address _provider) public view returns (string[][] memory) {
         return providerReviews[_provider];
    }

    /// @notice Allows users to report a data listing for inappropriate content or other issues.
    /// @param _listingId ID of the data listing being reported.
    /// @param _reportReason Reason for reporting the listing.
    function reportDataListing(uint256 _listingId, string memory _reportReason) public whenNotPaused listingExists(_listingId) {
        listingReports[_listingId].push(_reportReason);
        emit DataListingReported(_listingId, msg.sender, _reportReason);
        // In a real-world scenario, consider implementing moderation tools for the platform owner to review reports.
    }


    // --- Dynamic Data Updates Functions ---

    /// @notice Allows data providers to update the data hash for an existing listing (for dynamic data).
    /// @param _listingId ID of the data listing to update.
    /// @param _newDataHash New hash of the updated data.
    function updateDataHash(uint256 _listingId, string memory _newDataHash) public whenNotPaused listingExists(_listingId) onlyDataProvider(_listingId) {
        dataListings[_listingId].dataHash = _newDataHash;
        dataListings[_listingId].lastUpdated = block.timestamp;
        emit DataHashUpdated(_listingId, _newDataHash);
    }

    /// @notice Retrieves the latest data hash for a specific data listing.
    /// @param _listingId ID of the data listing.
    /// @return The current data hash.
    function getDataHash(uint256 _listingId) public view listingExists(_listingId) returns (string memory) {
        return dataListings[_listingId].dataHash;
    }


    // --- Platform Management & Fees Functions ---

    /// @notice Allows the contract owner to set the platform fee percentage.
    /// @param _feePercentage New platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance; // For simplicity, withdraw all contract balance, could be refined.
        payable(owner).transfer(withdrawableAmount);
        emit PlatformFeesWithdrawn(owner, withdrawableAmount);
    }

    /// @notice Allows the contract owner to pause the marketplace.
    function pauseMarketplace() public onlyOwner whenNotPaused {
        paused = true;
        emit MarketplacePaused(owner);
    }

    /// @notice Allows the contract owner to unpause the marketplace.
    function unpauseMarketplace() public onlyOwner whenPaused {
        paused = false;
        emit MarketplaceUnpaused(owner);
    }


    // --- Helper Functions (String manipulation - rudimentary for demonstration) ---

    function _stringToLowerCase(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(strBytes.length);
        for (uint i = 0; i < strBytes.length; i++) {
            if (uint8(strBytes[i]) >= 65 && uint8(strBytes[i]) <= 90) { // A-Z
                result[i] = bytes1(uint8(strBytes[i]) + 32); // Convert to lowercase
            } else {
                result[i] = strBytes[i];
            }
        }
        return string(result);
    }

    function _stringContains(string memory str, string memory searchTerm) private pure returns (bool) {
        return string.find(str, searchTerm) != -1; // Simple string search, solidity string utils are limited
    }

    // Fallback function to prevent accidental sending of Ether to contract
    fallback() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }
}
```