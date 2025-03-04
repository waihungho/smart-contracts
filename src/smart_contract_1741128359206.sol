```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Data Monetization & Reputation Platform
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a decentralized platform for data providers to monetize their data
 *      and build reputation, while consumers can access and utilize this data in a transparent and secure manner.
 *
 * **Outline & Function Summary:**
 *
 * **Data Provider Management:**
 *   1. `registerDataProvider(string _providerName, string _providerDescription)`: Allows users to register as data providers, storing their name and description.
 *   2. `updateDataProviderProfile(string _newProviderName, string _newProviderDescription)`: Allows data providers to update their profile information.
 *   3. `getDataProviderProfile(address _providerAddress)`: Retrieves the profile information of a data provider.
 *   4. `getDataProviderDataListings(address _providerAddress)`: Retrieves a list of data listing IDs associated with a specific provider.
 *   5. `deactivateDataProvider()`: Allows a data provider to temporarily deactivate their provider status.
 *   6. `activateDataProvider()`: Allows a deactivated data provider to reactivate their status.
 *
 * **Data Listing Management:**
 *   7. `createDataListing(string _dataTitle, string _dataDescription, string _dataCID, uint256 _pricePerAccess)`: Allows data providers to create new data listings with title, description, CID (content identifier), and price.
 *   8. `updateDataListing(uint256 _listingId, string _newDataTitle, string _newDataDescription, string _newDataCID, uint256 _newPricePerAccess)`: Allows data providers to update existing data listings.
 *   9. `getDataListingDetails(uint256 _listingId)`: Retrieves detailed information about a specific data listing.
 *  10. `removeDataListing(uint256 _listingId)`: Allows data providers to remove a data listing.
 *  11. `setDataListingCategory(uint256 _listingId, string _category)`: Allows data providers to categorize their data listings.
 *  12. `getDataListingsByCategory(string _category)`: Retrieves a list of data listing IDs within a specific category.
 *  13. `getAllDataListings()`: Retrieves a list of all active data listing IDs in the platform.
 *
 * **Data Access & Monetization:**
 *  14. `purchaseDataAccess(uint256 _listingId)`: Allows users to purchase access to a data listing, paying the specified price.
 *  15. `checkDataAccess(uint256 _listingId, address _consumer)`: Allows users to verify if they have purchased access to a specific data listing.
 *  16. `withdrawProviderEarnings()`: Allows data providers to withdraw their accumulated earnings from data access purchases.
 *  17. `setMarketplaceFee(uint256 _feePercentage)`: (Admin function) Sets the marketplace fee percentage charged on each data access purchase.
 *  18. `withdrawMarketplaceFees()`: (Admin function) Allows the marketplace owner to withdraw accumulated marketplace fees.
 *
 * **Reputation & Moderation:**
 *  19. `rateDataProvider(address _providerAddress, uint8 _rating)`: Allows consumers who purchased data access to rate a data provider.
 *  20. `getAverageProviderRating(address _providerAddress)`: Retrieves the average rating of a data provider.
 *  21. `reportDataListing(uint256 _listingId, string _reportReason)`: Allows users to report a data listing for inappropriate content.
 *  22. `resolveDataListingReport(uint256 _listingId, bool _isApproved)`: (Admin function) Resolves a data listing report, potentially removing the listing if disapproved.
 *
 * **Admin & Platform Management:**
 *  23. `pauseMarketplace()`: (Admin function) Pauses the marketplace, preventing new listings and purchases.
 *  24. `unpauseMarketplace()`: (Admin function) Resumes the marketplace functionality.
 *  25. `transferOwnership(address _newOwner)`: (Admin function) Allows the current owner to transfer contract ownership.
 */

contract DecentralizedDataPlatform {
    address public owner;
    uint256 public marketplaceFeePercentage = 5; // Default 5% marketplace fee
    bool public marketplacePaused = false;

    struct DataProviderProfile {
        string providerName;
        string providerDescription;
        bool isActive;
        uint256 totalEarnings;
        uint256 ratingCount;
        uint256 ratingSum;
    }

    struct DataListing {
        uint256 listingId;
        address providerAddress;
        string dataTitle;
        string dataDescription;
        string dataCID; // Content Identifier (e.g., IPFS CID)
        uint256 pricePerAccess;
        string category;
        bool isActive;
        uint256 reportCount;
        bool isReported;
    }

    mapping(address => DataProviderProfile) public dataProviders;
    mapping(uint256 => DataListing) public dataListings;
    mapping(uint256 => mapping(address => bool)) public dataAccessPurchased; // listingId => consumerAddress => hasAccess
    mapping(address => uint256[]) public providerDataListings; // providerAddress => array of listingIds
    mapping(string => uint256[]) public categoryDataListings; // category => array of listingIds
    uint256[] public allListings; // Array of all active listing IDs
    uint256 public nextListingId = 1;

    event DataProviderRegistered(address providerAddress, string providerName);
    event DataProviderProfileUpdated(address providerAddress, string newProviderName);
    event DataListingCreated(uint256 listingId, address providerAddress, string dataTitle);
    event DataListingUpdated(uint256 listingId, string newDataTitle);
    event DataListingRemoved(uint256 listingId);
    event DataAccessPurchased(uint256 listingId, address consumerAddress);
    event ProviderRatingGiven(address providerAddress, address rater, uint8 rating);
    event DataListingReported(uint256 listingId, address reporter, string reason);
    event DataListingReportResolved(uint256 listingId, bool isApproved, bool listingRemoved);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event EarningsWithdrawn(address providerAddress, uint256 amount);
    event MarketplaceFeesWithdrawn(address owner, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier marketplaceActive() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier onlyDataProvider() {
        require(dataProviders[msg.sender].isActive, "You are not a registered and active data provider.");
        _;
    }

    modifier validListingId(uint256 _listingId) {
        require(dataListings[_listingId].listingId == _listingId, "Invalid listing ID.");
        _;
    }

    modifier listingActive(uint256 _listingId) {
        require(dataListings[_listingId].isActive, "Data listing is not active.");
        _;
    }

    modifier dataAccessNotPurchased(uint256 _listingId) {
        require(!dataAccessPurchased[_listingId][msg.sender], "Data access already purchased.");
        _;
    }

    modifier dataAccessPurchasedRequired(uint256 _listingId) {
        require(dataAccessPurchased[_listingId][msg.sender], "Data access not purchased.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Fallback function to receive Ether for data purchases and marketplace fees.
     */
    receive() external payable {}

    /**
     * @dev Allows users to register as data providers.
     * @param _providerName The name of the data provider.
     * @param _providerDescription A brief description of the data provider or their offerings.
     */
    function registerDataProvider(string memory _providerName, string memory _providerDescription) public marketplaceActive {
        require(!dataProviders[msg.sender].isActive, "Already registered as a data provider.");
        dataProviders[msg.sender] = DataProviderProfile({
            providerName: _providerName,
            providerDescription: _providerDescription,
            isActive: true,
            totalEarnings: 0,
            ratingCount: 0,
            ratingSum: 0
        });
        emit DataProviderRegistered(msg.sender, _providerName);
    }

    /**
     * @dev Allows data providers to update their profile information.
     * @param _newProviderName The new name of the data provider.
     * @param _newProviderDescription The new description of the data provider.
     */
    function updateDataProviderProfile(string memory _newProviderName, string memory _newProviderDescription) public onlyDataProvider marketplaceActive {
        dataProviders[msg.sender].providerName = _newProviderName;
        dataProviders[msg.sender].providerDescription = _newProviderDescription;
        emit DataProviderProfileUpdated(msg.sender, _newProviderName);
    }

    /**
     * @dev Retrieves the profile information of a data provider.
     * @param _providerAddress The address of the data provider.
     * @return DataProviderProfile struct containing provider's profile information.
     */
    function getDataProviderProfile(address _providerAddress) public view returns (DataProviderProfile memory) {
        return dataProviders[_providerAddress];
    }

    /**
     * @dev Retrieves a list of data listing IDs associated with a specific provider.
     * @param _providerAddress The address of the data provider.
     * @return An array of listing IDs created by the provider.
     */
    function getDataProviderDataListings(address _providerAddress) public view returns (uint256[] memory) {
        return providerDataListings[_providerAddress];
    }

    /**
     * @dev Allows a data provider to temporarily deactivate their provider status, making their listings inactive.
     */
    function deactivateDataProvider() public onlyDataProvider marketplaceActive {
        dataProviders[msg.sender].isActive = false;
        // Optionally deactivate all listings of this provider in a more complex implementation.
        // For simplicity, listings remain but provider is marked as inactive.
    }

    /**
     * @dev Allows a deactivated data provider to reactivate their status.
     */
    function activateDataProvider() public onlyDataProvider marketplaceActive {
        dataProviders[msg.sender].isActive = true;
    }

    /**
     * @dev Allows data providers to create new data listings.
     * @param _dataTitle The title of the data listing.
     * @param _dataDescription A description of the data.
     * @param _dataCID The Content Identifier (CID) of the data (e.g., IPFS hash).
     * @param _pricePerAccess The price to access the data.
     */
    function createDataListing(
        string memory _dataTitle,
        string memory _dataDescription,
        string memory _dataCID,
        uint256 _pricePerAccess
    ) public onlyDataProvider marketplaceActive {
        uint256 listingId = nextListingId++;
        DataListing storage newListing = dataListings[listingId];
        newListing.listingId = listingId;
        newListing.providerAddress = msg.sender;
        newListing.dataTitle = _dataTitle;
        newListing.dataDescription = _dataDescription;
        newListing.dataCID = _dataCID;
        newListing.pricePerAccess = _pricePerAccess;
        newListing.isActive = true;
        allListings.push(listingId);
        providerDataListings[msg.sender].push(listingId);
        emit DataListingCreated(listingId, msg.sender, _dataTitle);
    }

    /**
     * @dev Allows data providers to update existing data listings.
     * @param _listingId The ID of the data listing to update.
     * @param _newDataTitle The new title of the data listing.
     * @param _newDataDescription The new description of the data.
     * @param _newDataCID The new Content Identifier (CID) of the data.
     * @param _newPricePerAccess The new price to access the data.
     */
    function updateDataListing(
        uint256 _listingId,
        string memory _newDataTitle,
        string memory _newDataDescription,
        string memory _newDataCID,
        uint256 _newPricePerAccess
    ) public onlyDataProvider validListingId(_listingId) listingActive(_listingId) marketplaceActive {
        require(dataListings[_listingId].providerAddress == msg.sender, "You are not the owner of this listing.");
        dataListings[_listingId].dataTitle = _newDataTitle;
        dataListings[_listingId].dataDescription = _newDataDescription;
        dataListings[_listingId].dataCID = _newDataCID;
        dataListings[_listingId].pricePerAccess = _newPricePerAccess;
        emit DataListingUpdated(_listingId, _newDataTitle);
    }

    /**
     * @dev Retrieves detailed information about a specific data listing.
     * @param _listingId The ID of the data listing.
     * @return DataListing struct containing listing details.
     */
    function getDataListingDetails(uint256 _listingId) public view validListingId(_listingId) returns (DataListing memory) {
        return dataListings[_listingId];
    }

    /**
     * @dev Allows data providers to remove a data listing, making it inactive.
     * @param _listingId The ID of the data listing to remove.
     */
    function removeDataListing(uint256 _listingId) public onlyDataProvider validListingId(_listingId) listingActive(_listingId) marketplaceActive {
        require(dataListings[_listingId].providerAddress == msg.sender, "You are not the owner of this listing.");
        dataListings[_listingId].isActive = false;
        // Optionally remove from allListings and categoryListings for cleaner data management in a more complex system.
        emit DataListingRemoved(_listingId);
    }

    /**
     * @dev Allows data providers to categorize their data listings.
     * @param _listingId The ID of the data listing to categorize.
     * @param _category The category name for the data listing.
     */
    function setDataListingCategory(uint256 _listingId, string memory _category) public onlyDataProvider validListingId(_listingId) listingActive(_listingId) marketplaceActive {
        require(dataListings[_listingId].providerAddress == msg.sender, "You are not the owner of this listing.");
        string memory oldCategory = dataListings[_listingId].category;
        if (bytes(oldCategory).length > 0) {
            // Remove from old category list if it exists. (Basic implementation, could be optimized)
            uint256[] storage listingsInCategory = categoryDataListings[oldCategory];
            for (uint256 i = 0; i < listingsInCategory.length; i++) {
                if (listingsInCategory[i] == _listingId) {
                    listingsInCategory[i] = listingsInCategory[listingsInCategory.length - 1];
                    listingsInCategory.pop();
                    break;
                }
            }
        }
        dataListings[_listingId].category = _category;
        if (bytes(_category).length > 0) {
            categoryDataListings[_category].push(_listingId);
        }
    }

    /**
     * @dev Retrieves a list of data listing IDs within a specific category.
     * @param _category The category name to search for.
     * @return An array of listing IDs belonging to the specified category.
     */
    function getDataListingsByCategory(string memory _category) public view returns (uint256[] memory) {
        return categoryDataListings[_category];
    }

    /**
     * @dev Retrieves a list of all active data listing IDs in the platform.
     * @return An array of all active listing IDs.
     */
    function getAllDataListings() public view returns (uint256[] memory) {
        return allListings;
    }

    /**
     * @dev Allows users to purchase access to a data listing.
     * @param _listingId The ID of the data listing to purchase access to.
     */
    function purchaseDataAccess(uint256 _listingId) public payable validListingId(_listingId) listingActive(_listingId) marketplaceActive dataAccessNotPurchased(_listingId) {
        uint256 price = dataListings[_listingId].pricePerAccess;
        require(msg.value >= price, "Insufficient payment for data access.");

        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 providerEarning = price - marketplaceFee;

        payable(dataListings[_listingId].providerAddress).transfer(providerEarning);
        payable(owner).transfer(marketplaceFee); // Marketplace fee goes to owner

        dataProviders[dataListings[_listingId].providerAddress].totalEarnings += providerEarning;
        dataAccessPurchased[_listingId][msg.sender] = true;
        emit DataAccessPurchased(_listingId, msg.sender);

        // Return any excess Ether sent by the buyer
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev Allows users to verify if they have purchased access to a specific data listing.
     * @param _listingId The ID of the data listing to check access for.
     * @param _consumer The address of the user to check access for.
     * @return True if the user has purchased access, false otherwise.
     */
    function checkDataAccess(uint256 _listingId, address _consumer) public view validListingId(_listingId) returns (bool) {
        return dataAccessPurchased[_listingId][_consumer];
    }

    /**
     * @dev Allows data providers to withdraw their accumulated earnings from data access purchases.
     */
    function withdrawProviderEarnings() public onlyDataProvider marketplaceActive {
        uint256 earnings = dataProviders[msg.sender].totalEarnings;
        require(earnings > 0, "No earnings to withdraw.");
        dataProviders[msg.sender].totalEarnings = 0; // Reset earnings to zero after withdrawal
        payable(msg.sender).transfer(earnings);
        emit EarningsWithdrawn(msg.sender, earnings);
    }

    /**
     * @dev (Admin function) Sets the marketplace fee percentage charged on each data access purchase.
     * @param _feePercentage The new marketplace fee percentage (0-100).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner marketplaceActive {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev (Admin function) Allows the marketplace owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner marketplaceActive {
        uint256 contractBalance = address(this).balance;
        uint256 providerEarnings = 0;
        for (uint256 i = 0; i < allListings.length; i++) {
            providerEarnings += dataProviders[dataListings[allListings[i]].providerAddress].totalEarnings;
        }
        uint256 marketplaceFees = contractBalance - providerEarnings;

        require(marketplaceFees > 0, "No marketplace fees to withdraw.");
        payable(owner).transfer(marketplaceFees);
        emit MarketplaceFeesWithdrawn(owner, marketplaceFees);
    }


    /**
     * @dev Allows consumers who purchased data access to rate a data provider.
     * @param _providerAddress The address of the data provider to rate.
     * @param _rating The rating given by the consumer (e.g., 1-5).
     */
    function rateDataProvider(address _providerAddress, uint8 _rating) public marketplaceActive {
        require(dataProviders[_providerAddress].isActive, "Provider is not active.");
        // In a real-world scenario, you might want to track which listing the rating is for and ensure the rater purchased access.
        // For simplicity here, we just allow rating any active provider.
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        dataProviders[_providerAddress].ratingSum += _rating;
        dataProviders[_providerAddress].ratingCount++;
        emit ProviderRatingGiven(_providerAddress, msg.sender, _rating);
    }

    /**
     * @dev Retrieves the average rating of a data provider.
     * @param _providerAddress The address of the data provider.
     * @return The average rating (calculated as ratingSum / ratingCount). Returns 0 if no ratings yet.
     */
    function getAverageProviderRating(address _providerAddress) public view returns (uint256) {
        if (dataProviders[_providerAddress].ratingCount == 0) {
            return 0;
        }
        return dataProviders[_providerAddress].ratingSum / dataProviders[_providerAddress].ratingCount;
    }

    /**
     * @dev Allows users to report a data listing for inappropriate content.
     * @param _listingId The ID of the data listing being reported.
     * @param _reportReason The reason for reporting the listing.
     */
    function reportDataListing(uint256 _listingId, string memory _reportReason) public validListingId(_listingId) listingActive(_listingId) marketplaceActive {
        dataListings[_listingId].reportCount++;
        dataListings[_listingId].isReported = true;
        emit DataListingReported(_listingId, msg.sender, _reportReason);
    }

    /**
     * @dev (Admin function) Resolves a data listing report, potentially removing the listing if disapproved.
     * @param _listingId The ID of the reported data listing.
     * @param _isApproved True if the report is approved (listing should be removed), false otherwise.
     */
    function resolveDataListingReport(uint256 _listingId, bool _isApproved) public onlyOwner validListingId(_listingId) marketplaceActive {
        bool listingRemoved = false;
        if (_isApproved) {
            dataListings[_listingId].isActive = false; // Deactivate the listing if report is approved
            listingRemoved = true;
        }
        dataListings[_listingId].isReported = false; // Reset report status
        emit DataListingReportResolved(_listingId, _isApproved, listingRemoved);
    }

    /**
     * @dev (Admin function) Pauses the marketplace, preventing new listings and purchases.
     */
    function pauseMarketplace() public onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev (Admin function) Resumes the marketplace functionality.
     */
    function unpauseMarketplace() public onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev (Admin function) Allows the current owner to transfer contract ownership to a new address.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
```