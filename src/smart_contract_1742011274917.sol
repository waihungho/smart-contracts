```solidity
/**
 * @title Dynamic Reputation and Data Marketplace Contract
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a dynamic reputation system and a marketplace for data access NFTs.
 *      This contract introduces the concept of "Reputation-Gated NFTs" and "Dynamic Data Access Tokens",
 *      allowing for tiered access to data based on user reputation and evolving data access rights.
 *
 * Function Summary:
 *
 * **NFT Management & Core:**
 * 1. `mintReputationNFT(address _to, string memory _metadataURI)`: Mints a Reputation NFT to a user.
 * 2. `transferReputationNFT(address _from, address _to, uint256 _tokenId)`: Transfers a Reputation NFT.
 * 3. `approveReputationNFT(address _approved, uint256 _tokenId)`: Approves an address to transfer a Reputation NFT.
 * 4. `getApprovedReputationNFT(uint256 _tokenId)`: Gets the approved address for a Reputation NFT.
 * 5. `setApprovalForAllReputationNFT(address _operator, bool _approved)`: Sets approval for an operator to manage all Reputation NFTs.
 * 6. `isApprovedForAllReputationNFT(address _owner, address _operator)`: Checks if an operator is approved for all Reputation NFTs.
 * 7. `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of a Reputation NFT.
 * 8. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.
 *
 * **Reputation System:**
 * 9. `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation score.
 * 10. `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation score.
 * 11. `getReputation(address _user)`: Retrieves a user's reputation score.
 * 12. `setReputationThreshold(uint256 _threshold, uint256 _level)`: Sets a reputation threshold for a specific level.
 * 13. `getReputationLevel(address _user)`: Determines a user's reputation level based on thresholds.
 *
 * **Data Access NFT Marketplace:**
 * 14. `createDataListing(uint256 _reputationLevelRequired, string memory _dataDescription, uint256 _price)`: Creates a listing for data access, requiring a minimum reputation level.
 * 15. `buyDataAccess(uint256 _listingId)`: Allows a user with sufficient reputation to buy data access.
 * 16. `removeDataListing(uint256 _listingId)`: Removes a data listing from the marketplace.
 * 17. `getDataListingDetails(uint256 _listingId)`: Retrieves details of a specific data listing.
 * 18. `getDataListingsByReputationLevel(uint256 _reputationLevel)`: Gets listings filtered by required reputation level.
 *
 * **Dynamic Access Control & Features:**
 * 19. `grantDynamicDataAccess(uint256 _listingId, address _user, uint256 _accessDurationSeconds)`: Grants dynamic access to data for a limited time, tied to a listing.
 * 20. `checkDynamicDataAccess(uint256 _listingId, address _user)`: Checks if a user has dynamic access to data from a listing.
 * 21. `extendDynamicDataAccess(uint256 _listingId, address _user, uint256 _extensionDurationSeconds)`: Extends dynamic data access for a user.
 * 22. `withdrawPlatformFees()`: Allows the contract owner to withdraw platform fees collected from data access sales.
 * 23. `setDataAccessFeePercentage(uint25percent _feePercentage)`: Allows the contract owner to set the platform fee percentage for data access sales.
 * 24. `pauseContract()`: Pauses the contract functionalities (except emergency functions).
 * 25. `unpauseContract()`: Unpauses the contract functionalities.
 * 26. `isContractPaused()`: Checks if the contract is paused.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicReputationDataMarketplace is ERC721, Ownable, IERC2981, ERC165, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _reputationNFTCounter;
    mapping(uint256 => string) private _reputationNFTMetadataURIs;
    mapping(address => uint256) public userReputation;
    mapping(uint256 => uint256) public reputationThresholds; // Level => Threshold (e.g., level 1 needs 100 reputation)
    uint256 public constant MAX_REPUTATION_LEVELS = 5; // Example: 5 reputation levels

    struct DataListing {
        uint256 reputationLevelRequired;
        string dataDescription;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => DataListing) public dataListings;
    Counters.Counter private _dataListingCounter;
    uint25percent public dataAccessFeePercentage = 5; // 5% platform fee
    address payable public platformFeeRecipient;

    mapping(uint256 => mapping(address => uint256)) public dynamicDataAccessTimestamps; // listingId => user => expiryTimestamp

    event ReputationNFTMinted(address indexed to, uint256 tokenId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationThresholdSet(uint256 level, uint256 threshold);
    event DataListingCreated(uint256 listingId, uint256 reputationLevelRequired, string dataDescription, uint256 price, address seller);
    event DataAccessPurchased(uint256 listingId, address buyer, uint256 price);
    event DataListingRemoved(uint256 listingId);
    event DynamicDataAccessGranted(uint256 listingId, address user, uint256 expiryTimestamp);
    event DynamicDataAccessExtended(uint256 listingId, address user, uint256 newExpiryTimestamp);
    event PlatformFeePercentageSet(uint25percent feePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    constructor() ERC721("ReputationNFT", "RPTNFT") {
        platformFeeRecipient = payable(owner()); // Default platform fee recipient is contract owner
    }

    /**
     * =========================================================
     *                        NFT Management
     * =========================================================
     */

    /**
     * @dev Mints a new Reputation NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _metadataURI The URI for the NFT metadata.
     */
    function mintReputationNFT(address _to, string memory _metadataURI) public onlyOwner whenNotPaused {
        _reputationNFTCounter.increment();
        uint256 tokenId = _reputationNFTCounter.current();
        _safeMint(_to, tokenId);
        _reputationNFTMetadataURIs[tokenId] = _metadataURI;
        emit ReputationNFTMinted(_to, tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function transferReputationNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function approveReputationNFT(address _approved, uint256 _tokenId) public whenNotPaused {
        approve(_approved, _tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function getApprovedReputationNFT(uint256 _tokenId) public view returns (address) {
        return getApproved(_tokenId);
    }

    /**
     * @inheritdoc ERC721
     */
    function setApprovalForAllReputationNFT(address _operator, bool _approved) public whenNotPaused {
        setApprovalForAll(_operator, _approved);
    }

    /**
     * @inheritdoc ERC721
     */
    function isApprovedForAllReputationNFT(address _owner, address _operator) public view returns (bool) {
        return isApprovedForAll(_owner, _operator);
    }

    /**
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _reputationNFTMetadataURIs[_tokenId];
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
     * =========================================================
     *                      Reputation System
     * =========================================================
     */

    /**
     * @dev Increases the reputation score of a user.
     * @param _user The address of the user.
     * @param _amount The amount to increase the reputation by.
     */
    function increaseReputation(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputation[_user]);
    }

    /**
     * @dev Decreases the reputation score of a user.
     * @param _user The address of the user.
     * @param _amount The amount to decrease the reputation by.
     */
    function decreaseReputation(address _user, uint256 _amount) public onlyOwner whenNotPaused {
        require(userReputation[_user] >= _amount, "Reputation: Decrease amount exceeds current reputation.");
        userReputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, userReputation[_user]);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Sets the reputation threshold for a specific level.
     * @param _threshold The reputation score required to reach this level.
     * @param _level The reputation level (e.g., 1, 2, 3...).
     */
    function setReputationThreshold(uint256 _threshold, uint256 _level) public onlyOwner whenNotPaused {
        require(_level > 0 && _level <= MAX_REPUTATION_LEVELS, "Reputation: Invalid level.");
        reputationThresholds[_level] = _threshold;
        emit ReputationThresholdSet(_level, _threshold);
    }

    /**
     * @dev Determines the reputation level of a user based on predefined thresholds.
     * @param _user The address of the user.
     * @return The reputation level of the user (0 if below level 1).
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        uint256 reputationScore = userReputation[_user];
        for (uint256 level = MAX_REPUTATION_LEVELS; level >= 1; level--) {
            if (reputationScore >= reputationThresholds[level]) {
                return level;
            }
        }
        return 0; // Level 0 if below level 1 threshold
    }


    /**
     * =========================================================
     *              Data Access NFT Marketplace
     * =========================================================
     */

    /**
     * @dev Creates a listing for data access.
     * @param _reputationLevelRequired The minimum reputation level required to purchase access.
     * @param _dataDescription A description of the data being offered.
     * @param _price The price of data access.
     */
    function createDataListing(uint256 _reputationLevelRequired, string memory _dataDescription, uint256 _price) public whenNotPaused {
        _dataListingCounter.increment();
        uint256 listingId = _dataListingCounter.current();
        dataListings[listingId] = DataListing({
            reputationLevelRequired: _reputationLevelRequired,
            dataDescription: _dataDescription,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit DataListingCreated(listingId, _reputationLevelRequired, _dataDescription, _price, msg.sender);
    }

    /**
     * @dev Allows a user to buy data access for a specific listing, if they meet the reputation level requirement.
     * @param _listingId The ID of the data listing.
     */
    function buyDataAccess(uint256 _listingId) public payable whenNotPaused {
        require(dataListings[_listingId].isActive, "Marketplace: Listing is not active.");
        require(getReputationLevel(msg.sender) >= dataListings[_listingId].reputationLevelRequired, "Marketplace: Insufficient reputation level.");
        require(msg.value >= dataListings[_listingId].price, "Marketplace: Insufficient payment.");

        uint256 platformFee = (dataListings[_listingId].price * dataAccessFeePercentage) / 100;
        uint256 sellerPayout = dataListings[_listingId].price - platformFee;

        payable(dataListings[_listingId].seller).transfer(sellerPayout);
        payable(platformFeeRecipient).transfer(platformFee);

        emit DataAccessPurchased(_listingId, msg.sender, dataListings[_listingId].price);
    }

    /**
     * @dev Removes a data listing from the marketplace. Only the seller can remove their listing.
     * @param _listingId The ID of the data listing to remove.
     */
    function removeDataListing(uint256 _listingId) public whenNotPaused {
        require(dataListings[_listingId].seller == msg.sender, "Marketplace: Only seller can remove listing.");
        dataListings[_listingId].isActive = false;
        emit DataListingRemoved(_listingId);
    }

    /**
     * @dev Retrieves details of a specific data listing.
     * @param _listingId The ID of the data listing.
     * @return DataListing struct containing listing details.
     */
    function getDataListingDetails(uint256 _listingId) public view returns (DataListing memory) {
        require(dataListings[_listingId].isActive, "Marketplace: Listing is not active."); // Added active check for safety
        return dataListings[_listingId];
    }

    /**
     * @dev Gets all active data listings that require a specific reputation level or lower.
     * @param _reputationLevel The reputation level to filter by (inclusive).
     * @return An array of listing IDs that meet the criteria.
     */
    function getDataListingsByReputationLevel(uint256 _reputationLevel) public view returns (uint256[] memory) {
        uint256[] memory listingIds = new uint256[](_dataListingCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _dataListingCounter.current(); i++) {
            if (dataListings[i].isActive && dataListings[i].reputationLevelRequired <= _reputationLevel) {
                listingIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of results
        uint256[] memory results = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            results[i] = listingIds[i];
        }
        return results;
    }


    /**
     * =========================================================
     *              Dynamic Access Control & Features
     * =========================================================
     */

    /**
     * @dev Grants dynamic data access to a user for a limited time.
     * @param _listingId The ID of the data listing.
     * @param _user The address of the user to grant access to.
     * @param _accessDurationSeconds The duration of access in seconds.
     */
    function grantDynamicDataAccess(uint256 _listingId, address _user, uint256 _accessDurationSeconds) public whenNotPaused {
        require(dataListings[_listingId].seller == msg.sender || owner() == msg.sender, "Dynamic Access: Only seller or owner can grant access.");
        uint256 expiryTimestamp = block.timestamp + _accessDurationSeconds;
        dynamicDataAccessTimestamps[_listingId][_user] = expiryTimestamp;
        emit DynamicDataAccessGranted(_listingId, _user, expiryTimestamp);
    }

    /**
     * @dev Checks if a user has dynamic access to data from a listing.
     * @param _listingId The ID of the data listing.
     * @param _user The address of the user to check access for.
     * @return True if the user has access, false otherwise.
     */
    function checkDynamicDataAccess(uint256 _listingId, address _user) public view returns (bool) {
        return dynamicDataAccessTimestamps[_listingId][_user] > block.timestamp;
    }

    /**
     * @dev Extends dynamic data access for a user.
     * @param _listingId The ID of the data listing.
     * @param _user The address of the user to extend access for.
     * @param _extensionDurationSeconds The duration to extend access by in seconds.
     */
    function extendDynamicDataAccess(uint256 _listingId, address _user, uint256 _extensionDurationSeconds) public whenNotPaused {
        require(dataListings[_listingId].seller == msg.sender || owner() == msg.sender, "Dynamic Access: Only seller or owner can extend access.");
        uint256 currentExpiry = dynamicDataAccessTimestamps[_listingId][_user];
        uint256 newExpiryTimestamp = currentExpiry + _extensionDurationSeconds;
        dynamicDataAccessTimestamps[_listingId][_user] = newExpiryTimestamp;
        emit DynamicDataAccessExtended(_listingId, _user, newExpiryTimestamp);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Subtract msg.value if called with gas
        require(contractBalance > 0, "Withdraw: No platform fees to withdraw.");
        uint256 amountToWithdraw = contractBalance;
        platformFeeRecipient.transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(platformFeeRecipient, amountToWithdraw);
    }

    /**
     * @dev Sets the platform fee percentage for data access sales. Only owner can set.
     * @param _feePercentage The new platform fee percentage (e.g., 5 for 5%).
     */
    function setDataAccessFeePercentage(uint25percent _feePercentage) public onlyOwner whenNotPaused {
        dataAccessFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /**
     * =========================================================
     *                      Pausable Functionality
     * =========================================================
     */

    /**
     * @dev Pauses the contract, preventing most functionalities.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring functionalities.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused();
    }

    /**
     * @dev Modifier to check if the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: Contract is paused");
        _;
    }

    /**
     * @dev Modifier to check if the contract is paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: Contract is not paused");
        _;
    }

    /**
     * @inheritdoc IERC2981
     * Royalty info - In this example, no royalties are set, but can be easily implemented here for Reputation NFTs or Data Access NFTs.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        pure
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(0), 0); // No royalties in this example
    }
}
```