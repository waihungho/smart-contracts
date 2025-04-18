```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (Example - Feel free to change)
 * @dev A smart contract for a decentralized platform where users can create, curate, and dynamically update content NFTs.
 *
 * Function Summary:
 * -----------------
 * **Content Creation & Management:**
 * 1. `createContentNFT(string memory _metadataURI)`: Allows members to create a new Content NFT with initial metadata.
 * 2. `updateContentMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows the content creator to update the metadata of their NFT.
 * 3. `setContentState(uint256 _tokenId, ContentState _newState)`: Allows the content creator to change the state of their content (e.g., Active, Draft, Archived).
 * 4. `setContentPricing(uint256 _tokenId, uint256 _price)`: Allows the content creator to set a price for accessing their content.
 * 5. `setContentAccessType(uint256 _tokenId, AccessType _accessType)`: Allows the content creator to set the access type (Free, Paid, Gated).
 * 6. `transferContentOwnership(uint256 _tokenId, address _newOwner)`: Allows the content owner to transfer ownership of their content NFT.
 * 7. `burnContentNFT(uint256 _tokenId)`: Allows the content owner to permanently burn their content NFT.
 * 8. `getContentDetails(uint256 _tokenId)`: Retrieves detailed information about a specific content NFT.
 * 9. `getContentState(uint256 _tokenId)`: Retrieves the current state of a content NFT.
 * 10. `getContentOwner(uint256 _tokenId)`: Retrieves the owner of a content NFT.
 *
 * **Access Control & Gating:**
 * 11. `purchaseContentAccess(uint256 _tokenId)`: Allows users to purchase access to paid content.
 * 12. `grantContentAccess(uint256 _tokenId, address _user)`: Allows the content owner to manually grant access to a user (for gated content).
 * 13. `revokeContentAccess(uint256 _tokenId, address _user)`: Allows the content owner to revoke access from a user.
 * 14. `hasContentAccess(uint256 _tokenId, address _user)`: Checks if a user has access to a specific content NFT.
 *
 * **Dynamic Updates & Versioning:**
 * 15. `createContentVersion(uint256 _tokenId, string memory _versionMetadataURI)`: Allows the content owner to create a new version of the content with updated metadata, while preserving history.
 * 16. `getVersionMetadata(uint256 _tokenId, uint256 _versionId)`: Retrieves the metadata for a specific version of a content NFT.
 * 17. `getCurrentVersionId(uint256 _tokenId)`: Retrieves the ID of the current active version of a content NFT.
 *
 * **Platform Features & Utility:**
 * 18. `setPlatformFee(uint256 _feePercentage)`: Allows the platform owner to set a fee percentage on content purchases.
 * 19. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 * 20. `supportContentCreator(uint256 _tokenId)`: Allows users to directly support content creators by sending ETH/tokens.
 * 21. `getContentSalesCount(uint256 _tokenId)`: Retrieves the number of times a content NFT's access has been purchased.
 * 22. `getContentCreationTimestamp(uint256 _tokenId)`: Retrieves the timestamp when the content NFT was created.
 * 23. `getContentLastUpdatedTimestamp(uint256 _tokenId)`: Retrieves the timestamp when the content NFT was last updated (metadata or version).
 */
contract DecentralizedDynamicContentPlatform {

    // -------- Enums and Structs --------

    enum ContentState { Draft, Active, Archived, Removed }
    enum AccessType { Free, Paid, Gated }

    struct ContentNFT {
        address owner;
        string currentMetadataURI;
        ContentState state;
        AccessType accessType;
        uint256 price;
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        uint256 salesCount;
        uint256 currentVersionId;
    }

    struct ContentVersion {
        string metadataURI;
        uint256 timestamp;
    }

    // -------- State Variables --------

    mapping(uint256 => ContentNFT) public contentNFTs;
    mapping(uint256 => mapping(uint256 => ContentVersion)) public contentVersions; // tokenId => versionId => ContentVersion
    mapping(uint256 => mapping(address => bool)) public contentAccessList; // tokenId => userAddress => hasAccess
    uint256 public contentNFTCounter;
    address public platformOwner;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    uint256 public platformFeesCollected;

    // -------- Events --------

    event ContentNFTCreated(uint256 tokenId, address owner, string metadataURI);
    event ContentMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ContentStateChanged(uint256 tokenId, ContentState newState);
    event ContentPriceSet(uint256 tokenId, uint256 newPrice);
    event ContentAccessTypeChanged(uint256 tokenId, AccessType newAccessType);
    event ContentOwnershipTransferred(uint256 tokenId, address oldOwner, address newOwner);
    event ContentNFTBurned(uint256 tokenId, address owner);
    event ContentAccessPurchased(uint256 tokenId, address buyer, uint256 price);
    event ContentAccessGranted(uint256 tokenId, address grantedTo, address grantedBy);
    event ContentAccessRevoked(uint256 tokenId, address revokedFrom, address revokedBy);
    event ContentVersionCreated(uint256 tokenId, uint256 versionId, string versionMetadataURI);
    event PlatformFeeUpdated(uint256 newFeePercentage, address updatedBy);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event ContentCreatorSupported(uint256 tokenId, address supporter, uint256 amount);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier onlyContentOwner(uint256 _tokenId) {
        require(contentNFTs[_tokenId].owner == msg.sender, "Only content owner can call this function.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(contentNFTs[_tokenId].owner != address(0), "Invalid Content NFT ID.");
        _;
    }

    modifier contentInActiveState(uint256 _tokenId) {
        require(contentNFTs[_tokenId].state == ContentState.Active, "Content must be in Active state.");
        _;
    }

    modifier hasAccess(uint256 _tokenId, address _user) {
        AccessType accessType = contentNFTs[_tokenId].accessType;
        if (accessType == AccessType.Paid || accessType == AccessType.Gated) {
            require(contentAccessList[_tokenId][_user] || contentNFTs[_tokenId].owner == _user, "Access required for this content.");
        }
        _;
    }


    // -------- Constructor --------

    constructor() {
        platformOwner = msg.sender;
    }

    // -------- Content Creation & Management Functions --------

    /**
     * @dev Creates a new Content NFT.
     * @param _metadataURI URI pointing to the initial metadata of the content.
     */
    function createContentNFT(string memory _metadataURI) public returns (uint256 tokenId) {
        tokenId = contentNFTCounter++;
        contentNFTs[tokenId] = ContentNFT({
            owner: msg.sender,
            currentMetadataURI: _metadataURI,
            state: ContentState.Draft, // Initial state is Draft
            accessType: AccessType.Free, // Default access is Free
            price: 0,
            creationTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            salesCount: 0,
            currentVersionId: 0
        });
        contentVersions[tokenId][0] = ContentVersion({ // Create initial version
            metadataURI: _metadataURI,
            timestamp: block.timestamp
        });
        emit ContentNFTCreated(tokenId, msg.sender, _metadataURI);
        return tokenId;
    }

    /**
     * @dev Updates the metadata URI of a Content NFT.
     * @param _tokenId ID of the Content NFT to update.
     * @param _newMetadataURI New URI pointing to the updated metadata.
     */
    function updateContentMetadata(uint256 _tokenId, string memory _newMetadataURI)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        contentNFTs[_tokenId].currentMetadataURI = _newMetadataURI;
        contentNFTs[_tokenId].lastUpdatedTimestamp = block.timestamp;
        emit ContentMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Sets the state of a Content NFT (Draft, Active, Archived, Removed).
     * @param _tokenId ID of the Content NFT to update.
     * @param _newState New state for the Content NFT.
     */
    function setContentState(uint256 _tokenId, ContentState _newState)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        contentNFTs[_tokenId].state = _newState;
        contentNFTs[_tokenId].lastUpdatedTimestamp = block.timestamp;
        emit ContentStateChanged(_tokenId, _newState);
    }

    /**
     * @dev Sets the price for accessing a Paid Content NFT.
     * @param _tokenId ID of the Content NFT to update.
     * @param _price Price in wei for accessing the content.
     */
    function setContentPricing(uint256 _tokenId, uint256 _price)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        require(contentNFTs[_tokenId].accessType == AccessType.Paid, "Price can only be set for Paid content.");
        contentNFTs[_tokenId].price = _price;
        contentNFTs[_tokenId].lastUpdatedTimestamp = block.timestamp;
        emit ContentPriceSet(_tokenId, _price);
    }

    /**
     * @dev Sets the access type of a Content NFT (Free, Paid, Gated).
     * @param _tokenId ID of the Content NFT to update.
     * @param _accessType New access type for the Content NFT.
     */
    function setContentAccessType(uint256 _tokenId, AccessType _accessType)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        contentNFTs[_tokenId].accessType = _accessType;
        contentNFTs[_tokenId].lastUpdatedTimestamp = block.timestamp;
        if (_accessType != AccessType.Paid) {
            contentNFTs[_tokenId].price = 0; // Reset price if not Paid
        }
        emit ContentAccessTypeChanged(_tokenId, _accessType);
    }

    /**
     * @dev Transfers ownership of a Content NFT to a new address.
     * @param _tokenId ID of the Content NFT to transfer.
     * @param _newOwner Address of the new owner.
     */
    function transferContentOwnership(uint256 _tokenId, address _newOwner)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        address oldOwner = contentNFTs[_tokenId].owner;
        contentNFTs[_tokenId].owner = _newOwner;
        emit ContentOwnershipTransferred(_tokenId, oldOwner, _newOwner);
    }

    /**
     * @dev Burns a Content NFT, permanently removing it from the platform.
     * @param _tokenId ID of the Content NFT to burn.
     */
    function burnContentNFT(uint256 _tokenId)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        address owner = contentNFTs[_tokenId].owner;
        delete contentNFTs[_tokenId];
        delete contentVersions[_tokenId];
        delete contentAccessList[_tokenId];
        emit ContentNFTBurned(_tokenId, owner);
    }

    /**
     * @dev Retrieves detailed information about a Content NFT.
     * @param _tokenId ID of the Content NFT to query.
     * @return ContentNFT struct containing details.
     */
    function getContentDetails(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (ContentNFT memory)
    {
        return contentNFTs[_tokenId];
    }

    /**
     * @dev Retrieves the current state of a Content NFT.
     * @param _tokenId ID of the Content NFT to query.
     * @return ContentState enum representing the current state.
     */
    function getContentState(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (ContentState)
    {
        return contentNFTs[_tokenId].state;
    }

    /**
     * @dev Retrieves the owner address of a Content NFT.
     * @param _tokenId ID of the Content NFT to query.
     * @return address of the content owner.
     */
    function getContentOwner(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (address)
    {
        return contentNFTs[_tokenId].owner;
    }

    // -------- Access Control & Gating Functions --------

    /**
     * @dev Allows a user to purchase access to a Paid Content NFT.
     * @param _tokenId ID of the Content NFT to purchase access to.
     */
    function purchaseContentAccess(uint256 _tokenId)
        public
        payable
        validTokenId(_tokenId)
        contentInActiveState(_tokenId)
    {
        require(contentNFTs[_tokenId].accessType == AccessType.Paid, "Content is not Paid access type.");
        require(msg.value >= contentNFTs[_tokenId].price, "Insufficient payment for content access.");

        uint256 platformFee = (contentNFTs[_tokenId].price * platformFeePercentage) / 100;
        uint256 creatorShare = contentNFTs[_tokenId].price - platformFee;

        // Transfer platform fee to platform owner
        payable(platformOwner).transfer(platformFee);
        platformFeesCollected += platformFee;

        // Transfer creator share to content owner
        payable(contentNFTs[_tokenId].owner).transfer(creatorShare);

        contentAccessList[_tokenId][msg.sender] = true; // Grant access to purchaser
        contentNFTs[_tokenId].salesCount++;
        emit ContentAccessPurchased(_tokenId, msg.sender, contentNFTs[_tokenId].price);

        // Return any excess ETH sent by the buyer
        if (msg.value > contentNFTs[_tokenId].price) {
            payable(msg.sender).transfer(msg.value - contentNFTs[_tokenId].price);
        }
    }

    /**
     * @dev Grants content access to a user for a Gated Content NFT. Only content owner can grant access.
     * @param _tokenId ID of the Content NFT to grant access for.
     * @param _user Address of the user to grant access to.
     */
    function grantContentAccess(uint256 _tokenId, address _user)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        require(contentNFTs[_tokenId].accessType == AccessType.Gated, "Content is not Gated access type.");
        contentAccessList[_tokenId][_user] = true;
        emit ContentAccessGranted(_tokenId, _user, msg.sender);
    }

    /**
     * @dev Revokes content access from a user for a Gated Content NFT. Only content owner can revoke access.
     * @param _tokenId ID of the Content NFT to revoke access from.
     * @param _user Address of the user to revoke access from.
     */
    function revokeContentAccess(uint256 _tokenId, address _user)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        require(contentNFTs[_tokenId].accessType == AccessType.Gated, "Content is not Gated access type.");
        contentAccessList[_tokenId][_user] = false;
        emit ContentAccessRevoked(_tokenId, _user, msg.sender);
    }

    /**
     * @dev Checks if a user has access to a Content NFT.
     * @param _tokenId ID of the Content NFT to check access for.
     * @param _user Address of the user to check.
     * @return bool indicating whether the user has access.
     */
    function hasContentAccess(uint256 _tokenId, address _user)
        public
        view
        validTokenId(_tokenId)
        returns (bool)
    {
        AccessType accessType = contentNFTs[_tokenId].accessType;
        if (accessType == AccessType.Free) {
            return true; // Free content, everyone has access
        } else if (accessType == AccessType.Paid || accessType == AccessType.Gated) {
            return contentAccessList[_tokenId][_user] || contentNFTs[_tokenId].owner == _user;
        }
        return false; // Should not reach here, but for completeness
    }

    // -------- Dynamic Updates & Versioning Functions --------

    /**
     * @dev Creates a new version of the content with updated metadata, preserving history.
     * @param _tokenId ID of the Content NFT to create a new version for.
     * @param _versionMetadataURI URI pointing to the metadata of the new version.
     */
    function createContentVersion(uint256 _tokenId, string memory _versionMetadataURI)
        public
        validTokenId(_tokenId)
        onlyContentOwner(_tokenId)
    {
        uint256 newVersionId = contentNFTs[_tokenId].currentVersionId + 1;
        contentVersions[_tokenId][newVersionId] = ContentVersion({
            metadataURI: _versionMetadataURI,
            timestamp: block.timestamp
        });
        contentNFTs[_tokenId].currentVersionId = newVersionId;
        contentNFTs[_tokenId].currentMetadataURI = _versionMetadataURI; // Update current metadata to latest version
        contentNFTs[_tokenId].lastUpdatedTimestamp = block.timestamp;
        emit ContentVersionCreated(_tokenId, newVersionId, _versionMetadataURI);
    }

    /**
     * @dev Retrieves the metadata URI for a specific version of a Content NFT.
     * @param _tokenId ID of the Content NFT.
     * @param _versionId ID of the version to retrieve.
     * @return string URI of the metadata for the specified version.
     */
    function getVersionMetadata(uint256 _tokenId, uint256 _versionId)
        public
        view
        validTokenId(_tokenId)
        returns (string memory)
    {
        require(contentVersions[_tokenId][_versionId].metadataURI.length > 0, "Version not found.");
        return contentVersions[_tokenId][_versionId].metadataURI;
    }

    /**
     * @dev Retrieves the ID of the current active version of a Content NFT.
     * @param _tokenId ID of the Content NFT.
     * @return uint256 ID of the current version.
     */
    function getCurrentVersionId(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        return contentNFTs[_tokenId].currentVersionId;
    }

    // -------- Platform Features & Utility Functions --------

    /**
     * @dev Sets the platform fee percentage charged on content purchases. Only platform owner can call this.
     * @param _feePercentage New platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage, msg.sender);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 amountToWithdraw = platformFeesCollected;
        platformFeesCollected = 0;
        payable(platformOwner).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, msg.sender);
    }

    /**
     * @dev Allows users to directly support content creators by sending ETH to the contract and specifying the Content NFT ID.
     * @param _tokenId ID of the Content NFT to support.
     */
    function supportContentCreator(uint256 _tokenId)
        public
        payable
        validTokenId(_tokenId)
    {
        require(msg.value > 0, "Support amount must be greater than zero.");
        payable(contentNFTs[_tokenId].owner).transfer(msg.value);
        emit ContentCreatorSupported(_tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Retrieves the number of times access to a content NFT has been purchased.
     * @param _tokenId ID of the Content NFT to query.
     * @return uint256 The number of sales.
     */
    function getContentSalesCount(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        return contentNFTs[_tokenId].salesCount;
    }

    /**
     * @dev Retrieves the timestamp when a content NFT was created.
     * @param _tokenId ID of the Content NFT to query.
     * @return uint256 The creation timestamp.
     */
    function getContentCreationTimestamp(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        return contentNFTs[_tokenId].creationTimestamp;
    }

    /**
     * @dev Retrieves the timestamp when a content NFT was last updated (metadata or version).
     * @param _tokenId ID of the Content NFT to query.
     * @return uint256 The last updated timestamp.
     */
    function getContentLastUpdatedTimestamp(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        return contentNFTs[_tokenId].lastUpdatedTimestamp;
    }

    // -------- Fallback and Receive Functions (Optional, for receiving ETH) --------

    receive() external payable {}
    fallback() external payable {}
}
```