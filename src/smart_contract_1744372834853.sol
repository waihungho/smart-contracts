```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform - "ContentNexus"
 * @author Bard (AI Assistant)
 * @dev A Smart Contract for a decentralized content platform with dynamic content updates, reputation system,
 *      content NFTs, community curation, and advanced features.
 *
 * **Outline & Function Summary:**
 *
 * **I. Platform Setup & Admin Functions:**
 *   1. `constructor(string _platformName)`: Initializes the platform with a name.
 *   2. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage (admin only).
 *   3. `setReputationThresholds(uint256 _bronze, uint256 _silver, uint256 _gold)`: Sets reputation thresholds for user tiers (admin only).
 *   4. `pausePlatform()`: Pauses core platform functionalities (admin only).
 *   5. `unpausePlatform()`: Resumes platform functionalities (admin only).
 *
 * **II. User Profile & Reputation:**
 *   6. `registerUser(string _username, string _profileDescription)`: Registers a new user with a username and profile description.
 *   7. `updateUserProfile(string _profileDescription)`: Updates the user's profile description.
 *   8. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 *   9. `getUserTier(address _user)`: Retrieves the reputation tier of a user (Bronze, Silver, Gold).
 *   10. `addReputation(address _user, uint256 _amount)`: Adds reputation points to a user (internal/admin function, use with care).
 *   11. `deductReputation(address _user, uint256 _amount)`: Deducts reputation points from a user (internal/admin function, use with care).
 *
 * **III. Content Creation & Management:**
 *   12. `createContentNFT(string _contentHash, string _metadataURI, uint256 _royaltyPercentage, uint256 _initialPrice)`: Creates a Content NFT.
 *   13. `updateContentMetadataURI(uint256 _tokenId, string _newMetadataURI)`: Updates the metadata URI of a Content NFT (NFT owner only).
 *   14. `setContentPrice(uint256 _tokenId, uint256 _newPrice)`: Sets a new price for a Content NFT (NFT owner only).
 *   15. `buyContentNFT(uint256 _tokenId)`: Allows users to buy a Content NFT.
 *   16. `getContentOwner(uint256 _tokenId)`: Retrieves the owner of a Content NFT.
 *
 * **IV. Dynamic Content Updates & Versioning:**
 *   17. `updateContentHash(uint256 _tokenId, string _newContentHash)`: Updates the content hash of a Content NFT, creating a new version (NFT owner & reputation gated).
 *   18. `getContentVersionHash(uint256 _tokenId, uint256 _version)`: Retrieves the content hash for a specific version of a Content NFT.
 *   19. `getCurrentContentHash(uint256 _tokenId)`: Retrieves the latest content hash of a Content NFT.
 *   20. `getContentVersionCount(uint256 _tokenId)`: Retrieves the total number of versions for a Content NFT.
 *
 * **V. Community Curation & Reporting (Example - can be expanded):**
 *   21. `reportContent(uint256 _tokenId, string _reportReason)`: Allows users to report content for moderation.
 *   22. `moderateContent(uint256 _tokenId, bool _isApproved)`: Admin function to moderate reported content.
 *
 * **VI. Platform Revenue & Royalties:**
 *   23. `withdrawPlatformRevenue()`: Allows the platform owner to withdraw collected platform fees.
 *   24. `calculateRoyaltyAmount(uint256 _price, uint256 _royaltyPercentage)`: Internal function to calculate royalty amounts.
 */

contract ContentNexus {
    // --- State Variables ---
    string public platformName;
    address public platformOwner;
    uint256 public platformFeePercentage; // Percentage of sales taken as platform fee
    bool public platformPaused;

    // User Data
    mapping(address => string) public usernames;
    mapping(address => string) public userProfiles;
    mapping(address => uint256) public userReputation;

    // Reputation Tiers
    uint256 public bronzeTierThreshold = 100;
    uint256 public silverTierThreshold = 500;
    uint256 public goldTierThreshold = 1000;

    // Content NFT Data
    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public contentNFTOwners;
    mapping(uint256 => string) public contentMetadataURIs;
    mapping(uint256 => uint256) public contentRoyalties; // Percentage royalty for creators
    mapping(uint256 => uint256) public contentPrices;
    mapping(uint256 => mapping(uint256 => string)) public contentVersionHashes; // tokenId => version => contentHash
    mapping(uint256 => uint256) public contentVersionCounts; // tokenId => versionCount (starts at 1)

    // Platform Revenue
    uint256 public platformBalance;

    // Events
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ReputationThresholdsUpdated(uint256 bronze, uint256 silver, uint256 gold);
    event PlatformPaused();
    event PlatformUnpaused();
    event UserRegistered(address userAddress, string username);
    event UserProfileUpdated(address userAddress);
    event ReputationAdded(address userAddress, uint256 amount);
    event ReputationDeducted(address userAddress, uint256 amount);
    event ContentNFTCreated(uint256 tokenId, address creator, string metadataURI);
    event ContentMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ContentPriceUpdated(uint256 tokenId, uint256 newPrice);
    event ContentNFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event ContentHashUpdated(uint256 tokenId, uint256 version, string newContentHash);
    event ContentReported(uint256 tokenId, address reporter, string reason);
    event ContentModerated(uint256 tokenId, uint256 contentId, bool isApproved);
    event PlatformRevenueWithdrawn(address owner, uint256 amount);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!platformPaused, "Platform is currently paused.");
        _;
    }

    modifier whenPaused() {
        require(platformPaused, "Platform is not paused.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(bytes(usernames[msg.sender]).length > 0, "User not registered.");
        _;
    }

    modifier onlyContentOwner(uint256 _tokenId) {
        require(contentNFTOwners[_tokenId] == msg.sender, "You are not the owner of this content.");
        _;
    }

    modifier reputationAtLeast(uint256 _minReputation) {
        require(userReputation[msg.sender] >= _minReputation, "Insufficient reputation.");
        _;
    }


    // --- Constructor ---
    constructor(string memory _platformName) {
        platformName = _platformName;
        platformOwner = msg.sender;
        platformFeePercentage = 5; // Default 5% platform fee
        platformPaused = false;
    }

    // --- I. Platform Setup & Admin Functions ---

    /**
     * @dev Sets the platform fee percentage. Only callable by the platform owner.
     * @param _feePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /**
     * @dev Sets the reputation thresholds for user tiers. Only callable by the platform owner.
     * @param _bronze Reputation threshold for Bronze tier.
     * @param _silver Reputation threshold for Silver tier.
     * @param _gold Reputation threshold for Gold tier.
     */
    function setReputationThresholds(uint256 _bronze, uint256 _silver, uint256 _gold) external onlyOwner {
        bronzeTierThreshold = _bronze;
        silverTierThreshold = _silver;
        goldTierThreshold = _gold;
        emit ReputationThresholdsUpdated(_bronze, _silver, _gold);
    }

    /**
     * @dev Pauses core platform functionalities. Only callable by the platform owner.
     */
    function pausePlatform() external onlyOwner whenNotPaused {
        platformPaused = true;
        emit PlatformPaused();
    }

    /**
     * @dev Resumes platform functionalities. Only callable by the platform owner.
     */
    function unpausePlatform() external onlyOwner whenPaused {
        platformPaused = false;
        emit PlatformUnpaused();
    }

    // --- II. User Profile & Reputation ---

    /**
     * @dev Registers a new user with a username and profile description.
     * @param _username The desired username.
     * @param _profileDescription A brief description of the user's profile.
     */
    function registerUser(string memory _username, string memory _profileDescription) external whenNotPaused {
        require(bytes(usernames[msg.sender]).length == 0, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be 1-32 characters.");
        usernames[msg.sender] = _username;
        userProfiles[msg.sender] = _profileDescription;
        userReputation[msg.sender] = 0; // Initial reputation is 0
        emit UserRegistered(msg.sender, _username);
    }

    /**
     * @dev Updates the user's profile description.
     * @param _profileDescription The new profile description.
     */
    function updateUserProfile(string memory _profileDescription) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender] = _profileDescription;
        emit UserProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Retrieves the reputation tier of a user based on predefined thresholds.
     * @param _user The address of the user.
     * @return A string representing the user's tier (Bronze, Silver, Gold, or Basic).
     */
    function getUserTier(address _user) external view returns (string memory) {
        uint256 reputation = userReputation[_user];
        if (reputation >= goldTierThreshold) {
            return "Gold";
        } else if (reputation >= silverTierThreshold) {
            return "Silver";
        } else if (reputation >= bronzeTierThreshold) {
            return "Bronze";
        } else {
            return "Basic";
        }
    }

    /**
     * @dev Adds reputation points to a user. Internal/Admin function - use carefully.
     * @param _user The address of the user to add reputation to.
     * @param _amount The amount of reputation to add.
     */
    function addReputation(address _user, uint256 _amount) internal onlyOwner { // Can be adjusted to be called by specific roles
        userReputation[_user] += _amount;
        emit ReputationAdded(_user, _amount);
    }

    /**
     * @dev Deducts reputation points from a user. Internal/Admin function - use carefully.
     * @param _user The address of the user to deduct reputation from.
     * @param _amount The amount of reputation to deduct.
     */
    function deductReputation(address _user, uint256 _amount) internal onlyOwner { // Can be adjusted to be called by specific roles
        require(userReputation[_user] >= _amount, "Insufficient reputation to deduct.");
        userReputation[_user] -= _amount;
        emit ReputationDeducted(_user, _amount);
    }


    // --- III. Content Creation & Management ---

    /**
     * @dev Creates a Content NFT.
     * @param _contentHash The hash of the content itself (e.g., IPFS hash).
     * @param _metadataURI URI pointing to the content metadata (e.g., JSON file).
     * @param _royaltyPercentage Royalty percentage for future sales (0-100).
     * @param _initialPrice The initial price of the NFT in wei.
     */
    function createContentNFT(
        string memory _contentHash,
        string memory _metadataURI,
        uint256 _royaltyPercentage,
        uint256 _initialPrice
    ) external onlyRegisteredUser whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100.");
        require(_initialPrice >= 0, "Initial price must be non-negative.");

        uint256 tokenId = nextTokenId++;
        contentNFTOwners[tokenId] = msg.sender;
        contentMetadataURIs[tokenId] = _metadataURI;
        contentRoyalties[tokenId] = _royaltyPercentage;
        contentPrices[tokenId] = _initialPrice;
        contentVersionHashes[tokenId][1] = _contentHash; // Version 1 is the initial content
        contentVersionCounts[tokenId] = 1;

        emit ContentNFTCreated(tokenId, msg.sender, _metadataURI);
    }

    /**
     * @dev Updates the metadata URI of a Content NFT. Only callable by the NFT owner.
     * @param _tokenId The ID of the Content NFT.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateContentMetadataURI(uint256 _tokenId, string memory _newMetadataURI) external onlyContentOwner(_tokenId) whenNotPaused {
        contentMetadataURIs[_tokenId] = _newMetadataURI;
        emit ContentMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Sets a new price for a Content NFT. Only callable by the NFT owner.
     * @param _tokenId The ID of the Content NFT.
     * @param _newPrice The new price in wei.
     */
    function setContentPrice(uint256 _tokenId, uint256 _newPrice) external onlyContentOwner(_tokenId) whenNotPaused {
        require(_newPrice >= 0, "Price must be non-negative.");
        contentPrices[_tokenId] = _newPrice;
        emit ContentPriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @dev Allows users to buy a Content NFT.
     * @param _tokenId The ID of the Content NFT to buy.
     */
    function buyContentNFT(uint256 _tokenId) external payable onlyRegisteredUser whenNotPaused {
        require(contentNFTOwners[_tokenId] != msg.sender, "Cannot buy your own content.");
        uint256 price = contentPrices[_tokenId];
        require(msg.value >= price, "Insufficient funds sent.");

        address seller = contentNFTOwners[_tokenId];

        // Calculate platform fee and royalty
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 royaltyAmount = calculateRoyaltyAmount(price - platformFee, contentRoyalties[_tokenId]);
        uint256 sellerPayout = price - platformFee - royaltyAmount;

        // Transfer funds
        platformBalance += platformFee;
        payable(platformOwner).transfer(platformFee); // Platform Fee to Owner
        payable(seller).transfer(sellerPayout);        // Seller gets payout after fees and royalties
        payable(contentNFTOwners[_tokenId]).transfer(royaltyAmount); // Creator Royalty (in this simplified example, creator is same as owner)

        // Update ownership
        contentNFTOwners[_tokenId] = msg.sender;
        emit ContentNFTBought(_tokenId, msg.sender, seller, price);

        // Return any excess funds
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev Retrieves the owner of a Content NFT.
     * @param _tokenId The ID of the Content NFT.
     * @return The address of the NFT owner.
     */
    function getContentOwner(uint256 _tokenId) external view returns (address) {
        return contentNFTOwners[_tokenId];
    }

    // --- IV. Dynamic Content Updates & Versioning ---

    /**
     * @dev Updates the content hash of a Content NFT, creating a new version.
     *      Requires the content owner and a minimum reputation level (e.g., Silver tier).
     * @param _tokenId The ID of the Content NFT to update.
     * @param _newContentHash The new content hash.
     */
    function updateContentHash(uint256 _tokenId, string memory _newContentHash)
        external
        onlyContentOwner(_tokenId)
        onlyRegisteredUser
        reputationAtLeast(silverTierThreshold) // Example: Silver tier or higher can update content
        whenNotPaused
    {
        uint256 currentVersion = contentVersionCounts[_tokenId];
        uint256 nextVersion = currentVersion + 1;
        contentVersionHashes[_tokenId][nextVersion] = _newContentHash;
        contentVersionCounts[_tokenId] = nextVersion;
        emit ContentHashUpdated(_tokenId, nextVersion, _newContentHash);
    }

    /**
     * @dev Retrieves the content hash for a specific version of a Content NFT.
     * @param _tokenId The ID of the Content NFT.
     * @param _version The version number.
     * @return The content hash for the specified version.
     */
    function getContentVersionHash(uint256 _tokenId, uint256 _version) external view returns (string memory) {
        require(_version > 0 && _version <= contentVersionCounts[_tokenId], "Invalid content version.");
        return contentVersionHashes[_tokenId][_version];
    }

    /**
     * @dev Retrieves the latest (current) content hash of a Content NFT.
     * @param _tokenId The ID of the Content NFT.
     * @return The latest content hash.
     */
    function getCurrentContentHash(uint256 _tokenId) external view returns (string memory) {
        uint256 currentVersion = contentVersionCounts[_tokenId];
        return contentVersionHashes[_tokenId][currentVersion];
    }

    /**
     * @dev Retrieves the total number of versions for a Content NFT.
     * @param _tokenId The ID of the Content NFT.
     * @return The total version count.
     */
    function getContentVersionCount(uint256 _tokenId) external view returns (uint256) {
        return contentVersionCounts[_tokenId];
    }

    // --- V. Community Curation & Reporting (Example) ---

    /**
     * @dev Allows users to report content for moderation.
     * @param _tokenId The ID of the Content NFT being reported.
     * @param _reportReason Reason for reporting the content.
     */
    function reportContent(uint256 _tokenId, string memory _reportReason) external onlyRegisteredUser whenNotPaused {
        // In a real application, you would store report details and potentially implement a moderation queue.
        // This is a simplified example.
        emit ContentReported(_tokenId, msg.sender, _reportReason);
        // Further implementation would involve admin functions to review and moderate reports.
    }

    /**
     * @dev Admin function to moderate reported content (example - simplified).
     * @param _tokenId The ID of the Content NFT being moderated.
     * @param _isApproved Whether the content is approved (true) or rejected/removed (false).
     */
    function moderateContent(uint256 _tokenId, bool _isApproved) external onlyOwner whenNotPaused {
        // Example action: If not approved, potentially disable content access or take other actions.
        emit ContentModerated(_tokenId, _tokenId, _isApproved);
        // Further implementation would depend on the desired moderation actions.
    }


    // --- VI. Platform Revenue & Royalties ---

    /**
     * @dev Allows the platform owner to withdraw accumulated platform revenue.
     */
    function withdrawPlatformRevenue() external onlyOwner {
        uint256 balanceToWithdraw = platformBalance;
        platformBalance = 0;
        payable(platformOwner).transfer(balanceToWithdraw);
        emit PlatformRevenueWithdrawn(platformOwner, balanceToWithdraw);
    }

    /**
     * @dev Internal function to calculate royalty amount.
     * @param _price The base price of the content after platform fee.
     * @param _royaltyPercentage The royalty percentage.
     * @return The calculated royalty amount.
     */
    function calculateRoyaltyAmount(uint256 _price, uint256 _royaltyPercentage) internal pure returns (uint256) {
        return (_price * _royaltyPercentage) / 100;
    }

    // Fallback function to receive ETH in case of direct transfer to contract.
    receive() external payable {}
}
```