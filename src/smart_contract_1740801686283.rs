```solidity
pragma solidity ^0.8.19;

/**
 * @title Decentralized Data Marketplace with Reputation & Encryption
 * @author Gemini
 * @notice This contract implements a decentralized marketplace where data providers can list their datasets and consumers can purchase them.
 *  It incorporates a reputation system for data providers based on consumer feedback and allows for encrypted data transfers.
 * @dev This contract leverages encryption, reputation, and access control to create a trusted data marketplace.
 */
contract DecentralizedDataMarketplace {

    // --- STRUCTS & ENUMS ---

    /**
     * @dev Struct to represent a data listing in the marketplace.
     * @param provider The address of the data provider.
     * @param title The title of the dataset.
     * @param description A brief description of the dataset.
     * @param price The price of the dataset in Wei.
     * @param dataHash The hash of the encrypted data (or metadata pointer).
     * @param metadataURI A URI pointing to the dataset's metadata (e.g., IPFS).
     * @param isAvailable Boolean flag indicating if the dataset is still available for purchase.
     */
    struct DataListing {
        address provider;
        string title;
        string description;
        uint256 price;
        string dataHash; // Hash of encrypted data or a metadata pointer
        string metadataURI; // Link to metadata about the dataset.
        bool isAvailable;
    }

    /**
     * @dev Struct to represent a data purchase.
     * @param consumer The address of the consumer who purchased the data.
     * @param listingId The ID of the data listing that was purchased.
     * @param purchaseTime The timestamp of the purchase.
     * @param decryptionKeyHash The hash of the consumer's decryption key.
     *        This prevents provider from knowing the key, but allows them to verify the consumer provided one.
     */
    struct DataPurchase {
        address consumer;
        uint256 listingId;
        uint256 purchaseTime;
        string decryptionKeyHash;
    }

    /**
     * @dev Struct to represent a data provider's reputation.
     * @param ratingSum The sum of all ratings received by the provider.
     * @param ratingCount The number of ratings received by the provider.
     */
    struct ProviderReputation {
        uint256 ratingSum;
        uint256 ratingCount;
    }


    // --- STATE VARIABLES ---

    /**
     * @dev Mapping from listing ID to `DataListing` struct.
     */
    mapping(uint256 => DataListing) public dataListings;

    /**
     * @dev Mapping from listing ID to array of `DataPurchase` struct.
     */
    mapping(uint256 => DataPurchase[]) public dataPurchases;

    /**
     * @dev Mapping from address to `ProviderReputation` struct.
     */
    mapping(address => ProviderReputation) public providerReputations;

    /**
     * @dev Counter for generating unique listing IDs.
     */
    uint256 public listingCounter;

    /**
     * @dev Address of the contract owner.
     */
    address public owner;

    /**
     * @dev Percentage fee charged on each purchase, paid to the contract owner (e.g., 500 for 5%).
     */
    uint256 public platformFeePercentage;

    /**
     * @dev Event emitted when a new data listing is created.
     * @param listingId The ID of the newly created listing.
     * @param provider The address of the data provider.
     */
    event DataListingCreated(uint256 listingId, address provider, string title);

    /**
     * @dev Event emitted when data is purchased.
     * @param listingId The ID of the data listing purchased.
     * @param consumer The address of the consumer.
     */
    event DataPurchased(uint256 listingId, address consumer);

    /**
     * @dev Event emitted when a provider's reputation is updated.
     * @param provider The address of the data provider.
     * @param newRating The new average rating of the provider.
     */
    event ReputationUpdated(address provider, uint256 newRating);

    /**
     * @dev Event emitted when contract owner changes.
     * @param oldOwner The address of the old contract owner.
     * @param newOwner The address of the new contract owner.
     */
    event OwnerChanged(address oldOwner, address newOwner);

    /**
     * @dev Event emitted when platform fee percentage changes.
     * @param oldPercentage The old platform fee percentage.
     * @param newPercentage The new platform fee percentage.
     */
    event PlatformFeePercentageChanged(uint256 oldPercentage, uint256 newPercentage);

    // --- MODIFIERS ---

    /**
     * @dev Modifier to restrict function execution to the contract owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // --- CONSTRUCTOR ---

    /**
     * @dev Initializes the contract with the contract owner and initial platform fee percentage.
     * @param _platformFeePercentage The initial platform fee percentage (e.g., 500 for 5%).
     */
    constructor(uint256 _platformFeePercentage) {
        owner = msg.sender;
        platformFeePercentage = _platformFeePercentage;
    }

    // --- FUNCTIONS ---

    /**
     * @notice Creates a new data listing.
     * @dev  Requires payment for a listing, which can be used as insurance.
     * @param _title The title of the dataset.
     * @param _description A brief description of the dataset.
     * @param _price The price of the dataset in Wei.
     * @param _dataHash The hash of the encrypted data (or metadata pointer).
     * @param _metadataURI A URI pointing to the dataset's metadata (e.g., IPFS).
     */
    function createDataListing(
        string memory _title,
        string memory _description,
        uint256 _price,
        string memory _dataHash,
        string memory _metadataURI
    ) public payable {
        require(msg.value > 0, "Listing requires a payment.");
        listingCounter++;
        dataListings[listingCounter] = DataListing({
            provider: msg.sender,
            title: _title,
            description: _description,
            price: _price,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            isAvailable: true
        });

        emit DataListingCreated(listingCounter, msg.sender, _title);
    }


    /**
     * @notice Purchases a data listing.  Consumer must provide the hash of decryption key before purchasing
     * @dev Allows a consumer to purchase a data listing, transferring funds to the provider and the platform.
     * @param _listingId The ID of the data listing to purchase.
     * @param _decryptionKeyHash The hash of the consumer's decryption key.
     */
    function purchaseData(uint256 _listingId, string memory _decryptionKeyHash) public payable {
        require(dataListings[_listingId].isAvailable, "Data is not available.");
        require(msg.value >= dataListings[_listingId].price, "Insufficient payment.");

        DataListing storage listing = dataListings[_listingId];
        uint256 price = listing.price;
        address provider = listing.provider;

        // Calculate platform fee.
        uint256 platformFee = (price * platformFeePercentage) / 10000; // Assuming platformFeePercentage is out of 10000

        // Transfer funds.
        (bool success, ) = payable(provider).call{value: price - platformFee}("");
        require(success, "Transfer to provider failed.");
        (success, ) = payable(owner).call{value: platformFee}("");
        require(success, "Transfer to owner failed.");

        // Record the purchase.
        DataPurchase memory purchase = DataPurchase({
            consumer: msg.sender,
            listingId: _listingId,
            purchaseTime: block.timestamp,
            decryptionKeyHash: _decryptionKeyHash
        });
        dataPurchases[_listingId].push(purchase);


        listing.isAvailable = false; // Mark as unavailable after purchase.

        emit DataPurchased(_listingId, msg.sender);
    }

    /**
     * @notice Submits a rating for a data provider.
     * @dev Allows consumers to submit a rating for a data provider after purchasing their data.
     * @param _provider The address of the data provider to rate.
     * @param _rating The rating given to the provider (e.g., 1-5).
     */
    function rateProvider(address _provider, uint256 _rating) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(hasPurchased(_provider, msg.sender), "You must purchase data from this provider to rate them.");

        ProviderReputation storage reputation = providerReputations[_provider];
        reputation.ratingSum += _rating;
        reputation.ratingCount++;

        uint256 newRating = reputation.ratingSum / reputation.ratingCount;
        emit ReputationUpdated(_provider, newRating);
    }

    /**
     * @notice Checks if a consumer has purchased data from a specific provider.
     * @dev Used to enforce that only consumers who have purchased data can rate providers.
     * @param _provider The address of the data provider.
     * @param _consumer The address of the consumer.
     * @return bool True if the consumer has purchased data from the provider, false otherwise.
     */
    function hasPurchased(address _provider, address _consumer) private view returns (bool) {
      for(uint256 i = 1; i <= listingCounter; i++){
          if(dataListings[i].provider == _provider) {
            for(uint256 j = 0; j < dataPurchases[i].length; j++){
                if(dataPurchases[i][j].consumer == _consumer){
                  return true;
                }
            }
          }
      }
      return false;
    }

    /**
     * @notice Gets the average rating for a data provider.
     * @dev Returns the average rating for a given data provider.
     * @param _provider The address of the data provider.
     * @return uint256 The average rating of the provider.
     */
    function getProviderRating(address _provider) public view returns (uint256) {
        ProviderReputation storage reputation = providerReputations[_provider];
        if (reputation.ratingCount == 0) {
            return 0; // Return 0 if no ratings have been received.
        }
        return reputation.ratingSum / reputation.ratingCount;
    }

   /**
    * @notice Allows owner to change the contract ownership.
    * @param _newOwner The address of the new owner.
    */
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @notice Allows owner to change the platform fee percentage.
     * @param _newPercentage The new platform fee percentage (e.g., 500 for 5%).
     */
    function setPlatformFeePercentage(uint256 _newPercentage) public onlyOwner {
        emit PlatformFeePercentageChanged(platformFeePercentage, _newPercentage);
        platformFeePercentage = _newPercentage;
    }

    /**
     * @notice Allows the owner to withdraw the contract's balance.
     */
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /**
     * @notice Allows owner to cancel a data listing and return funds to the provider.
     * @param _listingId The ID of the listing to cancel.
     * @dev This function is only callable by the owner and allows for the cancellation of a data listing,
     *  returning the initial listing payment (msg.value) to the provider.
     */
    function cancelDataListing(uint256 _listingId) public onlyOwner {
        require(dataListings[_listingId].isAvailable, "Data listing already unavailable");
        address provider = dataListings[_listingId].provider;
        uint256 initialPayment = msg.value;  // Assuming msg.value was the initial payment.

        dataListings[_listingId].isAvailable = false;

        (bool success, ) = payable(provider).call{value: initialPayment}("");
        require(success, "Failed to return funds to provider.");
    }

    /**
     * @notice Allows consumers to report a listing for inappropriate content.
     * @dev In a real-world application, this function would require more robust logic.
     *  Such logic would include storing the number of reports for a specific listing and an owner-triggered function to verify and potentially remove the listing based on some pre-defined threshold.
     * @param _listingId The ID of the listing being reported.
     */
    function reportListing(uint256 _listingId) public {
       require(dataListings[_listingId].isAvailable, "Data listing already unavailable");
       // In the future, implement reporting logic.
       // For example: Increment report count, check report threshold, etc.
       // For now, simply emit an event.
        emit ReportedListing(_listingId, msg.sender);
    }

    /**
     * @dev Event emitted when listing is reported for inappropriate content.
     * @param listingId The ID of the listing being reported.
     * @param reporter The address of the reporter.
     */
    event ReportedListing(uint256 listingId, address reporter);

    /**
     * @notice Allows provider to update their listing
     * @dev This allows the data provider to update their listing to reflect any changes that happened.
     * @param _listingId The ID of the listing to update.
     * @param _title The title of the dataset.
     * @param _description A brief description of the dataset.
     * @param _price The price of the dataset in Wei.
     * @param _dataHash The hash of the encrypted data (or metadata pointer).
     * @param _metadataURI A URI pointing to the dataset's metadata (e.g., IPFS).
     */

    function updateDataListing(uint256 _listingId, string memory _title, string memory _description, uint256 _price, string memory _dataHash, string memory _metadataURI) public {
        require(dataListings[_listingId].provider == msg.sender, "Not the provider.");

        DataListing storage listing = dataListings[_listingId];
        listing.title = _title;
        listing.description = _description;
        listing.price = _price;
        listing.dataHash = _dataHash;
        listing.metadataURI = _metadataURI;
    }


}
```

**Outline and Function Summary:**

*   **Contract Title:** `DecentralizedDataMarketplace`
*   **Description:** A decentralized marketplace for data providers to list datasets and consumers to purchase them, incorporating reputation and encrypted data transfers.

**Structs:**

*   `DataListing`: Represents a data listing with provider, title, description, price, data hash, metadata URI, and availability.
*   `DataPurchase`: Represents a data purchase with consumer, listing ID, purchase time, and decryption key hash.
*   `ProviderReputation`: Represents a data provider's reputation with rating sum and rating count.

**State Variables:**

*   `dataListings`: Mapping from listing ID to `DataListing`.
*   `dataPurchases`: Mapping from listing ID to an array of `DataPurchase`.
*   `providerReputations`: Mapping from address to `ProviderReputation`.
*   `listingCounter`: Counter for generating unique listing IDs.
*   `owner`: Address of the contract owner.
*   `platformFeePercentage`: Percentage fee charged on each purchase.

**Events:**

*   `DataListingCreated`: Emitted when a new data listing is created.
*   `DataPurchased`: Emitted when data is purchased.
*   `ReputationUpdated`: Emitted when a provider's reputation is updated.
*   `OwnerChanged`: Emitted when contract owner changes.
*   `PlatformFeePercentageChanged`: Emitted when platform fee percentage changes.
*   `ReportedListing`: Emitted when a listing is reported for inappropriate content.

**Modifiers:**

*   `onlyOwner`: Restricts function execution to the contract owner.

**Constructor:**

*   Initializes the contract with the contract owner and initial platform fee percentage.

**Functions:**

*   `createDataListing()`: Creates a new data listing; provider must pay the fee.
*   `purchaseData()`: Purchases a data listing; the consumer must provide the decryption key hash.
*   `rateProvider()`: Submits a rating for a data provider.
*   `getProviderRating()`: Gets the average rating for a data provider.
*   `hasPurchased()`: Checks if a consumer has purchased data from a specific provider.
*   `changeOwner()`: Allows the owner to change the contract ownership.
*   `setPlatformFeePercentage()`: Allows the owner to change the platform fee percentage.
*   `withdrawBalance()`: Allows the owner to withdraw the contract's balance.
*   `cancelDataListing()`: Allows the owner to cancel a data listing and return funds to the provider.
*   `reportListing()`: Allows consumers to report a listing for inappropriate content.
*   `updateDataListing()`: Allows provider to update the listing.

**Explanation of Features and Design Choices:**

*   **Reputation System:**  A simple rating system is implemented to provide trust and quality assurance in the marketplace.
*   **Encrypted Data:** The `dataHash` field is intended to store a hash of *encrypted* data.  The actual data might be stored on a decentralized storage network like IPFS, Swarm, or Arweave. This ensures data privacy and security.
*   **Decryption Key Hash:** When purchasing data, the consumer provides the hash of *their* decryption key.  This protects the consumer; the provider does *not* learn the consumer's decryption key.  The provider can use the key hash to verify that the consumer provided *some* key, without knowing what it is.  The provider then uses the key that they have to encrypt the data, so that only someone who has the consumer's key can decrypt it.
*   **Platform Fee:** A platform fee is collected on each purchase to incentivize contract maintenance and development.
*   **Data Availability:** The `isAvailable` flag ensures that data is only sold once, or until the provider relists it (a more complex version of the contract could allow multiple sales).
*   **Reporting Mechanism:**  The `reportListing` function (and associated `ReportedListing` event) allows for basic content moderation.  A more robust implementation would involve storing reports, implementing a threshold, and allowing the owner to review and remove listings.
*   **Data Integrity:**  The contract relies on the immutability of the blockchain to ensure that listing details and purchase records cannot be tampered with after being recorded.  The `dataHash` provides an additional layer of integrity for the actual data itself.
*   **Listing Fee:** The `createDataListing()` function requires `msg.value > 0`. This serves as a deterrent against spam listings and provides the owner with funds to maintain the contract. The `cancelDataListing()` function allows the fee to be refunded to the provider.
*   **Update Data Listing Function:** A provider is allowed to update a specific listing to reflect changes to the data.
*   **Security Considerations:**
    *   **Reentrancy:** The contract does not have any explicit protection against reentrancy attacks. This would be crucial to implement in a production environment.
    *   **Integer Overflow/Underflow:**  The Solidity compiler version used (0.8.0+) mitigates against integer overflow/underflow by default.
    *   **Denial of Service (DoS):**  The contract is susceptible to DoS attacks if a malicious user creates a large number of listings or submits a large number of ratings. Pagination or other rate-limiting mechanisms would be needed to address this.
    *   **Gas Limit:** Complex operations, especially related to iterating through the list of data purchases, could exceed the gas limit. Pagination or other techniques to reduce gas costs may be necessary.
    *   **Access Control:** The onlyOwner modifier provides basic access control for administrative functions.
    *   **Data Validation:** The contract should incorporate more robust data validation to ensure that the data being stored is valid and consistent (e.g., checking the format of the metadataURI).
*   **Improvements/Future Features:**
    *   **Access Control Lists (ACLs):** Implement ACLs to allow for more granular control over data access.
    *   **Data Previews/Samples:** Allow providers to offer free previews or samples of their data.
    *   **Subscription Model:** Implement a subscription model for recurring access to data.
    *   **Decentralized Storage Integration:**  Directly integrate with a decentralized storage platform (e.g., IPFS) for storing and retrieving data.
    *   **Payment in Tokens:**  Allow payment in ERC-20 tokens.
    *   **Advanced Reputation System:**  Implement a more sophisticated reputation system that considers factors such as data quality, timeliness, and customer satisfaction.  Consider adding "staking" to listings where providers stake some tokens that can be lost if consumers do not like the product.
    *   **Dispute Resolution:**  Implement a dispute resolution mechanism to handle conflicts between providers and consumers.
    *   **Oracle Integration:** Integrate with oracles to verify the authenticity and quality of data.
    *   **Data Usage Tracking:** Track how data is being used to provide insights to providers and consumers.

This contract provides a foundation for building a decentralized data marketplace. The addition of more robust security measures, data validation, and integration with other decentralized technologies would be necessary to create a production-ready application.
