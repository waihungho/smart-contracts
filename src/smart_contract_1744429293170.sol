```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic content platform, enabling creators to publish,
 *      manage, and monetize content with advanced features like content morphing,
 *      AI-driven curation, decentralized access control, and community governance.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. Content Creation and Management:**
 *    - `createContent(string _cid, string _metadataURI, ContentType _contentType)`: Allows creators to register new content with IPFS CID and metadata URI.
 *    - `updateContentMetadata(uint256 _contentId, string _newMetadataURI)`: Updates the metadata URI of existing content.
 *    - `setContentPrice(uint256 _contentId, uint256 _price)`: Sets the price for accessing specific content.
 *    - `setContentAvailability(uint256 _contentId, bool _isAvailable)`: Toggles content availability for purchase/access.
 *    - `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 *    - `listContentByCreator(address _creator)`: Lists all content created by a specific address.
 *    - `getContentCount()`: Returns the total number of content items registered.
 *
 * **2. Content Access and Monetization:**
 *    - `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to content, transferring funds to the creator and platform.
 *    - `checkContentAccess(uint256 _contentId, address _user)`: Checks if a user has purchased access to specific content.
 *    - `withdrawCreatorEarnings()`: Allows creators to withdraw their accumulated earnings.
 *    - `getPlatformBalance()`: Returns the current balance of the platform's commission wallet.
 *    - `withdrawPlatformCommission(address _recipient, uint256 _amount)`: Allows the platform admin to withdraw accumulated commission.
 *
 * **3. Dynamic Content Morphing (Advanced Concept):**
 *    - `morphContent(uint256 _contentId, string _morphData)`: Allows authorized entities (e.g., AI agents, creators) to morph content based on predefined rules and `_morphData`.
 *    - `getContentMorphData(uint256 _contentId)`: Retrieves the current morph data associated with content, reflecting its dynamic state.
 *    - `addMorphAuthority(address _authority)`: Adds an address authorized to morph content.
 *    - `removeMorphAuthority(address _authority)`: Removes an address from the morph authority list.
 *    - `isMorphAuthority(address _authority)`: Checks if an address is authorized to morph content.
 *
 * **4. AI-Driven Curation and Recommendations (Trendy Concept - Basic Implementation):**
 *    - `upvoteContent(uint256 _contentId)`: Allows users to upvote content, influencing its curation score.
 *    - `downvoteContent(uint256 _contentId)`: Allows users to downvote content, influencing its curation score.
 *    - `getContentCurationScore(uint256 _contentId)`: Retrieves the current curation score of content, based on upvotes and downvotes.
 *
 * **5. Decentralized Access Control (Advanced Concept):**
 *    - `grantAccessToContent(uint256 _contentId, address _user)`: Allows creators to directly grant free access to specific content for users (e.g., for promotional purposes, whitelisting).
 *    - `revokeAccessFromContent(uint256 _contentId, address _user)`: Revokes previously granted access from a user.
 *    - `isGrantedAccess(uint256 _contentId, address _user)`: Checks if a user has been granted direct access to content.
 *
 * **6. Platform Governance (Trendy & Advanced - Basic Framework):**
 *    - `setPlatformCommissionRate(uint256 _newRate)`: Allows the platform admin to set the commission rate (in basis points).
 *    - `getPlatformCommissionRate()`: Retrieves the current platform commission rate.
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to change the platform admin address.
 *    - `getAdmin()`: Retrieves the current platform admin address.
 *
 * **7. Utility and Information Functions:**
 *    - `getContentTypeString(ContentType _contentType)`: Returns the string representation of a ContentType enum value.
 *    - `getVersion()`: Returns the contract version.
 */

contract DecentralizedDynamicContentPlatform {
    // -------- Enums --------
    enum ContentType {
        TEXT,
        IMAGE,
        VIDEO,
        AUDIO,
        DOCUMENT,
        OTHER
    }

    // -------- Structs --------
    struct Content {
        uint256 id;
        address creator;
        string cid;             // IPFS CID for content data
        string metadataURI;     // URI pointing to content metadata (e.g., JSON)
        ContentType contentType;
        uint256 price;          // Price to access content (in wei)
        bool isAvailable;       // Whether content is currently available for purchase
        int256 curationScore;   // Score based on upvotes/downvotes
        string morphData;       // Data to control content morphing/dynamic behavior
    }

    // -------- State Variables --------
    Content[] public contents;
    mapping(uint256 => mapping(address => bool)) public contentAccessPurchased; // contentId => user => hasAccess
    mapping(uint256 => mapping(address => bool)) public grantedContentAccess;   // contentId => user => hasGrantedAccess
    mapping(address => uint256) public creatorEarnings;
    uint256 public platformCommissionRate = 500; // Basis points (500 = 5%)
    address public platformAdmin;
    address payable public platformCommissionWallet;
    mapping(address => bool) public morphAuthorities; // Addresses authorized to morph content
    string public contractName = "Decentralized Dynamic Content Platform";
    string public contractVersion = "1.0.0";

    // -------- Events --------
    event ContentCreated(uint256 contentId, address creator, string cid, string metadataURI, ContentType contentType);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentAvailabilityChanged(uint256 contentId, bool isAvailable);
    event ContentAccessPurchased(uint256 contentId, address user, uint256 pricePaid);
    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event PlatformCommissionWithdrawn(address recipient, uint256 amount);
    event ContentMorphed(uint256 contentId, string morphData, address morphAuthority);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event AccessGranted(uint256 contentId, address user);
    event AccessRevoked(uint256 contentId, address user);
    event PlatformCommissionRateSet(uint256 newRate);
    event AdminChanged(address newAdmin, address oldAdmin);
    event MorphAuthorityAdded(address authority);
    event MorphAuthorityRemoved(address authority);

    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(msg.sender == platformAdmin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMorphAuthority() {
        require(morphAuthorities[msg.sender], "Not authorized to morph content.");
        _;
    }

    // -------- Constructor --------
    constructor(address payable _platformCommissionWallet) payable {
        platformAdmin = msg.sender;
        platformCommissionWallet = _platformCommissionWallet;
    }

    // ------------------------------------------------------------------------
    // 1. Content Creation and Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows creators to register new content.
     * @param _cid IPFS CID of the content data.
     * @param _metadataURI URI pointing to content metadata.
     * @param _contentType Type of the content.
     */
    function createContent(string memory _cid, string memory _metadataURI, ContentType _contentType) public {
        uint256 contentId = contents.length;
        contents.push(Content({
            id: contentId,
            creator: msg.sender,
            cid: _cid,
            metadataURI: _metadataURI,
            contentType: _contentType,
            price: 0, // Default price is free
            isAvailable: true,
            curationScore: 0,
            morphData: "" // Initial morph data is empty
        }));
        emit ContentCreated(contentId, msg.sender, _cid, _metadataURI, _contentType);
    }

    /**
     * @dev Updates the metadata URI of existing content.
     * @param _contentId ID of the content to update.
     * @param _newMetadataURI New metadata URI.
     */
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].creator == msg.sender, "Only creator can update metadata.");
        contents[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /**
     * @dev Sets the price for accessing specific content.
     * @param _contentId ID of the content.
     * @param _price Price in wei.
     */
    function setContentPrice(uint256 _contentId, uint256 _price) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].creator == msg.sender, "Only creator can set price.");
        contents[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    /**
     * @dev Toggles content availability for purchase/access.
     * @param _contentId ID of the content.
     * @param _isAvailable True to make available, false to make unavailable.
     */
    function setContentAvailability(uint256 _contentId, bool _isAvailable) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].creator == msg.sender, "Only creator can set availability.");
        contents[_contentId].isAvailable = _isAvailable;
        emit ContentAvailabilityChanged(_contentId, _isAvailable);
    }

    /**
     * @dev Retrieves detailed information about a specific content item.
     * @param _contentId ID of the content.
     * @return Content struct containing content details.
     */
    function getContentDetails(uint256 _contentId) public view returns (Content memory) {
        require(_contentId < contents.length, "Content ID does not exist.");
        return contents[_contentId];
    }

    /**
     * @dev Lists all content created by a specific address.
     * @param _creator Address of the creator.
     * @return Array of content IDs created by the address.
     */
    function listContentByCreator(address _creator) public view returns (uint256[] memory) {
        uint256[] memory creatorContentIds = new uint256[](contents.length);
        uint256 count = 0;
        for (uint256 i = 0; i < contents.length; i++) {
            if (contents[i].creator == _creator) {
                creatorContentIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of content items
        assembly {
            mstore(creatorContentIds, count) // Update array length
        }
        return creatorContentIds;
    }

    /**
     * @dev Returns the total number of content items registered.
     * @return Total content count.
     */
    function getContentCount() public view returns (uint256) {
        return contents.length;
    }

    // ------------------------------------------------------------------------
    // 2. Content Access and Monetization Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to purchase access to content.
     * @param _contentId ID of the content to purchase access to.
     */
    function purchaseContentAccess(uint256 _contentId) payable public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].isAvailable, "Content is not currently available.");
        require(!contentAccessPurchased[_contentId][msg.sender], "Access already purchased.");
        require(msg.value >= contents[_contentId].price, "Insufficient payment.");

        uint256 creatorShare = (contents[_contentId].price * (10000 - platformCommissionRate)) / 10000;
        uint256 platformCommission = contents[_contentId].price - creatorShare;

        creatorEarnings[contents[_contentId].creator] += creatorShare;
        platformCommissionWallet.transfer(platformCommission); // Send platform commission directly

        contentAccessPurchased[_contentId][msg.sender] = true;
        emit ContentAccessPurchased(_contentId, msg.sender, contents[_contentId].price);

        // Refund extra payment if any
        if (msg.value > contents[_contentId].price) {
            payable(msg.sender).transfer(msg.value - contents[_contentId].price);
        }
    }

    /**
     * @dev Checks if a user has purchased access to specific content.
     * @param _contentId ID of the content.
     * @param _user Address of the user.
     * @return True if user has access, false otherwise.
     */
    function checkContentAccess(uint256 _contentId, address _user) public view returns (bool) {
        require(_contentId < contents.length, "Content ID does not exist.");
        return contentAccessPurchased[_contentId][_user] || grantedContentAccess[_contentId][_user];
    }

    /**
     * @dev Allows creators to withdraw their accumulated earnings.
     */
    function withdrawCreatorEarnings() public {
        uint256 amount = creatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");
        creatorEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit CreatorEarningsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Returns the current balance of the platform's commission wallet.
     * @return Platform commission wallet balance.
     */
    function getPlatformBalance() public view returns (uint256) {
        return address(platformCommissionWallet).balance;
    }

    /**
     * @dev Allows the platform admin to withdraw accumulated commission.
     * @param _recipient Address to send the commission to.
     * @param _amount Amount to withdraw.
     */
    function withdrawPlatformCommission(address _recipient, uint256 _amount) public onlyAdmin {
        require(address(platformCommissionWallet).balance >= _amount, "Insufficient platform balance.");
        payable(_recipient).transfer(_amount);
        emit PlatformCommissionWithdrawn(_recipient, _amount);
    }

    // ------------------------------------------------------------------------
    // 3. Dynamic Content Morphing Functions (Advanced Concept)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows authorized entities to morph content based on predefined rules.
     * @param _contentId ID of the content to morph.
     * @param _morphData Data that dictates the morphing process (e.g., instructions, parameters).
     */
    function morphContent(uint256 _contentId, string memory _morphData) public onlyMorphAuthority {
        require(_contentId < contents.length, "Content ID does not exist.");
        contents[_contentId].morphData = _morphData;
        emit ContentMorphed(_contentId, _morphData, msg.sender);
    }

    /**
     * @dev Retrieves the current morph data associated with content.
     * @param _contentId ID of the content.
     * @return Current morph data of the content.
     */
    function getContentMorphData(uint256 _contentId) public view returns (string memory) {
        require(_contentId < contents.length, "Content ID does not exist.");
        return contents[_contentId].morphData;
    }

    /**
     * @dev Adds an address to the list of morph authorities.
     * @param _authority Address to add as a morph authority.
     */
    function addMorphAuthority(address _authority) public onlyAdmin {
        morphAuthorities[_authority] = true;
        emit MorphAuthorityAdded(_authority);
    }

    /**
     * @dev Removes an address from the list of morph authorities.
     * @param _authority Address to remove from morph authorities.
     */
    function removeMorphAuthority(address _authority) public onlyAdmin {
        morphAuthorities[_authority] = false;
        emit MorphAuthorityRemoved(_authority);
    }

    /**
     * @dev Checks if an address is authorized to morph content.
     * @param _authority Address to check.
     * @return True if address is a morph authority, false otherwise.
     */
    function isMorphAuthority(address _authority) public view returns (bool) {
        return morphAuthorities[_authority];
    }

    // ------------------------------------------------------------------------
    // 4. AI-Driven Curation and Recommendations (Trendy Concept - Basic Implementation)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to upvote content, increasing its curation score.
     * @param _contentId ID of the content to upvote.
     */
    function upvoteContent(uint256 _contentId) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        contents[_contentId].curationScore++;
        emit ContentUpvoted(_contentId, msg.sender);
    }

    /**
     * @dev Allows users to downvote content, decreasing its curation score.
     * @param _contentId ID of the content to downvote.
     */
    function downvoteContent(uint256 _contentId) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        contents[_contentId].curationScore--;
        emit ContentDownvoted(_contentId, msg.sender);
    }

    /**
     * @dev Retrieves the current curation score of content.
     * @param _contentId ID of the content.
     * @return Curation score.
     */
    function getContentCurationScore(uint256 _contentId) public view returns (int256) {
        require(_contentId < contents.length, "Content ID does not exist.");
        return contents[_contentId].curationScore;
    }

    // ------------------------------------------------------------------------
    // 5. Decentralized Access Control Functions (Advanced Concept)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows creators to grant free access to specific content for users.
     * @param _contentId ID of the content.
     * @param _user Address to grant access to.
     */
    function grantAccessToContent(uint256 _contentId, address _user) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].creator == msg.sender, "Only creator can grant access.");
        grantedContentAccess[_contentId][_user] = true;
        emit AccessGranted(_contentId, _user);
    }

    /**
     * @dev Revokes previously granted access from a user.
     * @param _contentId ID of the content.
     * @param _user Address to revoke access from.
     */
    function revokeAccessFromContent(uint256 _contentId, address _user) public {
        require(_contentId < contents.length, "Content ID does not exist.");
        require(contents[_contentId].creator == msg.sender, "Only creator can revoke access.");
        grantedContentAccess[_contentId][_user] = false;
        emit AccessRevoked(_contentId, _user);
    }

    /**
     * @dev Checks if a user has been granted direct access to content.
     * @param _contentId ID of the content.
     * @param _user Address to check.
     * @return True if user has granted access, false otherwise.
     */
    function isGrantedAccess(uint256 _contentId, address _user) public view returns (bool) {
        require(_contentId < contents.length, "Content ID does not exist.");
        return grantedContentAccess[_contentId][_user];
    }


    // ------------------------------------------------------------------------
    // 6. Platform Governance Functions (Trendy & Advanced - Basic Framework)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows the platform admin to set the commission rate.
     * @param _newRate New commission rate in basis points (e.g., 500 for 5%).
     */
    function setPlatformCommissionRate(uint256 _newRate) public onlyAdmin {
        platformCommissionRate = _newRate;
        emit PlatformCommissionRateSet(_newRate);
    }

    /**
     * @dev Retrieves the current platform commission rate.
     * @return Platform commission rate in basis points.
     */
    function getPlatformCommissionRate() public view returns (uint256) {
        return platformCommissionRate;
    }

    /**
     * @dev Allows the current admin to change the platform admin address.
     * @param _newAdmin Address of the new platform admin.
     */
    function setAdmin(address _newAdmin) public onlyAdmin {
        address oldAdmin = platformAdmin;
        platformAdmin = _newAdmin;
        emit AdminChanged(_newAdmin, oldAdmin);
    }

    /**
     * @dev Retrieves the current platform admin address.
     * @return Platform admin address.
     */
    function getAdmin() public view returns (address) {
        return platformAdmin;
    }

    // ------------------------------------------------------------------------
    // 7. Utility and Information Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Returns the string representation of a ContentType enum value.
     * @param _contentType ContentType enum value.
     * @return String representation of the content type.
     */
    function getContentTypeString(ContentType _contentType) public pure returns (string memory) {
        if (_contentType == ContentType.TEXT) {
            return "TEXT";
        } else if (_contentType == ContentType.IMAGE) {
            return "IMAGE";
        } else if (_contentType == ContentType.VIDEO) {
            return "VIDEO";
        } else if (_contentType == ContentType.AUDIO) {
            return "AUDIO";
        } else if (_contentType == ContentType.DOCUMENT) {
            return "DOCUMENT";
        } else {
            return "OTHER";
        }
    }

    /**
     * @dev Returns the contract version.
     * @return Contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return contractVersion;
    }

    // Fallback function to receive Ether, if needed for platform commission wallet.
    receive() external payable {}
}
```