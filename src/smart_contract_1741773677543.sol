```solidity
/**
 * @title Decentralized Content and Reputation Platform - ContentVerse
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized platform where users can create, share, curate, and monetize content.
 *      It incorporates advanced concepts like content NFTs, reputation system, community moderation, dynamic content pricing,
 *      and decentralized governance for platform features. This contract aims to be a comprehensive ecosystem for content creators and consumers.
 *
 * **Outline and Function Summary:**
 *
 * **Content Creation & Management:**
 * 1. `createContent(string _title, string _metadataURI, string[] _tags)`: Allows users to create new content with title, metadata URI, and tags.
 * 2. `editContentMetadata(uint256 _contentId, string _newMetadataURI)`: Allows content creators to update the metadata URI of their content.
 * 3. `setContentTags(uint256 _contentId, string[] _newTags)`: Allows content creators to update the tags associated with their content.
 * 4. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 * 5. `getContentCount()`: Returns the total number of content items created on the platform.
 *
 * **Content NFT & Ownership:**
 * 6. `mintContentNFT(uint256 _contentId)`: Mints an NFT representing ownership of a specific content item for the creator.
 * 7. `transferContentNFT(uint256 _contentId, address _to)`: Allows NFT owners to transfer ownership of content NFTs.
 * 8. `getContentNFTOwner(uint256 _contentId)`: Retrieves the current owner of the NFT associated with a content item.
 *
 * **Reputation & User Profiles:**
 * 9. `upvoteContent(uint256 _contentId)`: Allows users to upvote content, increasing author's reputation.
 * 10. `downvoteContent(uint256 _contentId)`: Allows users to downvote content, potentially decreasing author's reputation.
 * 11. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 12. `updateUserProfile(string _profileMetadataURI)`: Allows users to update their profile metadata URI.
 * 13. `getUserProfile(address _user)`: Retrieves the profile metadata URI of a user.
 *
 * **Content Monetization & Access Control:**
 * 14. `setContentPrice(uint256 _contentId, uint256 _price)`: Allows content creators to set a price for accessing their content.
 * 15. `purchaseContentAccess(uint256 _contentId)`: Allows users to purchase access to paid content.
 * 16. `checkContentAccess(uint256 _contentId, address _user)`: Checks if a user has access to a specific content item.
 *
 * **Community & Moderation:**
 * 17. `reportContent(uint256 _contentId, string _reason)`: Allows users to report content for moderation.
 * 18. `moderateContent(uint256 _contentId, bool _isApproved)`: Allows moderators to approve or disapprove reported content. (Moderator Role Required)
 * 19. `addModerator(address _moderator)`: Adds a new moderator to the platform. (Admin Role Required)
 * 20. `removeModerator(address _moderator)`: Removes a moderator from the platform. (Admin Role Required)
 * 21. `getContentByTag(string _tag)`: Retrieves content IDs associated with a specific tag.
 * 22. `getTrendingContent()`: Retrieves content IDs considered trending based on upvotes (basic implementation).
 *
 * **Platform Governance (Basic - Can be extended with DAO logic):**
 * 23. `setPlatformFee(uint256 _newFee)`: Allows admin to set a platform fee percentage for content purchases. (Admin Role Required)
 * 24. `platformWithdrawFees()`: Allows admin to withdraw accumulated platform fees. (Admin Role Required)
 * 25. `pausePlatform()`: Allows admin to pause core platform functionalities in case of emergency. (Admin Role Required)
 * 26. `unpausePlatform()`: Allows admin to resume platform functionalities after pausing. (Admin Role Required)
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ContentVerse is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _contentIds;
    Counters.Counter private _nftTokenIds;

    uint256 public platformFeePercentage = 5; // Platform fee in percentage (e.g., 5 for 5%)
    address public platformFeeRecipient;

    bool public platformPaused = false;

    mapping(uint256 => Content) public contents;
    mapping(uint256 => address) public contentNFTs; // Content ID to NFT Token ID
    mapping(address => uint256) public userReputations;
    mapping(address => string) public userProfiles;
    mapping(uint256 => address[]) public contentAccessList; // Content ID to list of addresses with access
    mapping(uint256 => bool) public contentModerationStatus; // Content ID to moderation status (true = approved)
    mapping(uint256 => string[]) public contentTags; // Content ID to array of tags
    mapping(string => uint256[]) public tagToContent; // Tag to array of content IDs
    mapping(address => bool) public moderators;

    struct Content {
        uint256 id;
        address creator;
        string title;
        string metadataURI;
        uint256 price;
        uint256 upvotes;
        uint256 downvotes;
        uint256 createdAt;
    }

    event ContentCreated(uint256 contentId, address creator, string title);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentTagsUpdated(uint256 contentId, uint256 indexed contentIdVal, string[] newTags);
    event ContentNFTMinted(uint256 contentId, uint256 nftTokenId, address owner);
    event ContentNFTTransferred(uint256 contentId, uint256 nftTokenId, address from, address to);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event UserProfileUpdated(address user, string profileMetadataURI);
    event ContentPriceSet(uint256 contentId, uint256 price);
    event ContentAccessPurchased(uint256 contentId, address buyer);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);
    event ModeratorAdded(address moderator, address admin);
    event ModeratorRemoved(address moderator, address admin);
    event PlatformFeeSet(uint256 newFeePercentage, address admin);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event PlatformPaused(address admin);
    event PlatformUnpaused(address admin);

    modifier onlyModerator() {
        require(moderators[_msgSender()] || _msgSender() == owner(), "Caller is not a moderator");
        _;
    }

    modifier whenNotPaused() {
        require(!platformPaused, "Platform is paused");
        _;
    }

    modifier whenPaused() {
        require(platformPaused, "Platform is not paused");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _platformFeeRecipient) ERC721(_name, _symbol) {
        platformFeeRecipient = _platformFeeRecipient;
        _contentIds.increment(); // Start content IDs from 1
    }

    /**
     * @dev Creates new content on the platform.
     * @param _title The title of the content.
     * @param _metadataURI URI pointing to the content metadata (e.g., IPFS link).
     * @param _tags Array of tags to categorize the content.
     */
    function createContent(string memory _title, string memory _metadataURI, string[] memory _tags) external whenNotPaused {
        _contentIds.increment();
        uint256 contentId = _contentIds.current();

        contents[contentId] = Content({
            id: contentId,
            creator: _msgSender(),
            title: _title,
            metadataURI: _metadataURI,
            price: 0, // Default price is 0 (free)
            upvotes: 0,
            downvotes: 0,
            createdAt: block.timestamp
        });
        contentModerationStatus[contentId] = true; // Automatically approve new content for now, can be changed for stricter moderation

        // Add tags and update tag mappings
        setContentTags(contentId, _tags);

        emit ContentCreated(contentId, _msgSender(), _title);
    }

    /**
     * @dev Edits the metadata URI of existing content. Only content creator can call this.
     * @param _contentId The ID of the content to edit.
     * @param _newMetadataURI The new metadata URI.
     */
    function editContentMetadata(uint256 _contentId, string memory _newMetadataURI) external whenNotPaused {
        require(contents[_contentId].creator == _msgSender(), "Only content creator can edit metadata");
        contents[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    /**
     * @dev Sets or updates tags for a content item. Only content creator can call this.
     * @param _contentId The ID of the content to update tags for.
     * @param _newTags Array of new tags.
     */
    function setContentTags(uint256 _contentId, string[] memory _newTags) public whenNotPaused {
        require(contents[_contentId].creator == _msgSender(), "Only content creator can set tags");

        // Remove old tags from tagToContent mapping
        string[] memory oldTags = contentTags[_contentId];
        for (uint i = 0; i < oldTags.length; i++) {
            removeContentFromTagMapping(oldTags[i], _contentId);
        }

        contentTags[_contentId] = _newTags;

        // Add new tags to tagToContent mapping
        for (uint i = 0; i < _newTags.length; i++) {
            addContentToTagMapping(_newTags[i], _contentId);
        }

        emit ContentTagsUpdated(_contentId, _contentId, _newTags);
    }

    /**
     * @dev Retrieves detailed information about a specific content item.
     * @param _contentId The ID of the content.
     * @return Content struct containing content details.
     */
    function getContentDetails(uint256 _contentId) external view returns (Content memory) {
        return contents[_contentId];
    }

    /**
     * @dev Gets the total number of content items created.
     * @return uint256 Total content count.
     */
    function getContentCount() external view returns (uint256) {
        return _contentIds.current();
    }

    /**
     * @dev Mints an NFT for a specific content item, representing ownership. Only content creator can call.
     * @param _contentId The ID of the content to mint NFT for.
     */
    function mintContentNFT(uint256 _contentId) external whenNotPaused {
        require(contents[_contentId].creator == _msgSender(), "Only content creator can mint NFT");
        require(contentNFTs[_contentId] == address(0), "NFT already minted for this content");

        _nftTokenIds.increment();
        uint256 nftTokenId = _nftTokenIds.current();
        _mint(_msgSender(), nftTokenId);
        contentNFTs[_contentId] = address(nftTokenId); // Store NFT token ID in contentNFTs mapping

        emit ContentNFTMinted(_contentId, nftTokenId, _msgSender());
    }

    /**
     * @dev Transfers the ownership of a content NFT. Standard ERC721 transfer.
     * @param _contentId The ID of the content associated with the NFT.
     * @param _to The address to transfer the NFT to.
     */
    function transferContentNFT(uint256 _contentId, address _to) external whenNotPaused {
        uint256 nftTokenId = uint256(uint160(contentNFTs[_contentId])); // Convert address to uint256 for token ID
        require(ownerOf(nftTokenId) == _msgSender(), "You are not the owner of this content NFT");
        safeTransferFrom(_msgSender(), _to, nftTokenId);
        emit ContentNFTTransferred(_contentId, nftTokenId, _msgSender(), _to);
    }

    /**
     * @dev Retrieves the owner of the NFT associated with a content item.
     * @param _contentId The ID of the content.
     * @return address The owner of the content NFT.
     */
    function getContentNFTOwner(uint256 _contentId) external view returns (address) {
        uint256 nftTokenId = uint256(uint160(contentNFTs[_contentId])); // Convert address to uint256 for token ID
        if (nftTokenId == 0) {
            return address(0); // No NFT minted yet
        }
        return ownerOf(nftTokenId);
    }

    /**
     * @dev Allows users to upvote content, increasing the content creator's reputation.
     * @param _contentId The ID of the content to upvote.
     */
    function upvoteContent(uint256 _contentId) external whenNotPaused {
        contents[_contentId].upvotes++;
        userReputations[contents[_contentId].creator]++; // Increase creator's reputation
        emit ContentUpvoted(_contentId, _msgSender());
    }

    /**
     * @dev Allows users to downvote content, potentially decreasing the content creator's reputation.
     * @param _contentId The ID of the content to downvote.
     */
    function downvoteContent(uint256 _contentId) external whenNotPaused {
        contents[_contentId].downvotes++;
        if (userReputations[contents[_contentId].creator] > 0) { // Prevent negative reputation
            userReputations[contents[_contentId].creator]--; // Decrease creator's reputation
        }
        emit ContentDownvoted(_contentId, _msgSender());
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return uint256 The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputations[_user];
    }

    /**
     * @dev Allows users to update their profile metadata URI.
     * @param _profileMetadataURI URI pointing to the user's profile metadata (e.g., personal website, social links).
     */
    function updateUserProfile(string memory _profileMetadataURI) external whenNotPaused {
        userProfiles[_msgSender()] = _profileMetadataURI;
        emit UserProfileUpdated(_msgSender(), _profileMetadataURI);
    }

    /**
     * @dev Retrieves the profile metadata URI of a user.
     * @param _user The address of the user.
     * @return string The user's profile metadata URI.
     */
    function getUserProfile(address _user) external view returns (string memory) {
        return userProfiles[_user];
    }

    /**
     * @dev Sets a price for accessing a content item. Only content creator can call.
     * @param _contentId The ID of the content.
     * @param _price The price in wei.
     */
    function setContentPrice(uint256 _contentId, uint256 _price) external whenNotPaused {
        require(contents[_contentId].creator == _msgSender(), "Only content creator can set price");
        contents[_contentId].price = _price;
        emit ContentPriceSet(_contentId, _price);
    }

    /**
     * @dev Allows users to purchase access to paid content.
     * @param _contentId The ID of the content to purchase access to.
     */
    function purchaseContentAccess(uint256 _contentId) external payable whenNotPaused {
        require(contents[_contentId].price > 0, "Content is not paid");
        require(msg.value >= contents[_contentId].price, "Insufficient payment");
        require(!checkContentAccess(_contentId, _msgSender()), "You already have access to this content");

        contentAccessList[_contentId].push(_msgSender());

        // Transfer funds to content creator and platform fee recipient
        uint256 platformFee = (contents[_contentId].price * platformFeePercentage) / 100;
        uint256 creatorShare = contents[_contentId].price - platformFee;

        payable(contents[_contentId].creator).transfer(creatorShare);
        payable(platformFeeRecipient).transfer(platformFee);

        emit ContentAccessPurchased(_contentId, _msgSender());
    }

    /**
     * @dev Checks if a user has access to a content item (either free or purchased access).
     * @param _contentId The ID of the content.
     * @param _user The address of the user to check.
     * @return bool True if user has access, false otherwise.
     */
    function checkContentAccess(uint256 _contentId, address _user) public view returns (bool) {
        if (contents[_contentId].price == 0) {
            return true; // Free content, everyone has access
        }
        for (uint i = 0; i < contentAccessList[_contentId].length; i++) {
            if (contentAccessList[_contentId][i] == _user) {
                return true; // User is in the access list
            }
        }
        return false; // User does not have access
    }

    /**
     * @dev Allows users to report content for moderation.
     * @param _contentId The ID of the content to report.
     * @param _reason Reason for reporting the content.
     */
    function reportContent(uint256 _contentId, string memory _reason) external whenNotPaused {
        contentModerationStatus[_contentId] = false; // Set moderation status to false upon report - pending review
        emit ContentReported(_contentId, _msgSender(), _reason);
    }

    /**
     * @dev Allows moderators to approve or disapprove reported content.
     * @param _contentId The ID of the content to moderate.
     * @param _isApproved True to approve content, false to disapprove (hide).
     */
    function moderateContent(uint256 _contentId, bool _isApproved) external onlyModerator whenNotPaused {
        contentModerationStatus[_contentId] = _isApproved;
        emit ContentModerated(_contentId, _isApproved, _msgSender());
    }

    /**
     * @dev Adds a new moderator. Only admin (contract owner) can call.
     * @param _moderator The address of the moderator to add.
     */
    function addModerator(address _moderator) external onlyOwner whenNotPaused {
        moderators[_moderator] = true;
        emit ModeratorAdded(_moderator, _msgSender());
    }

    /**
     * @dev Removes a moderator. Only admin (contract owner) can call.
     * @param _moderator The address of the moderator to remove.
     */
    function removeModerator(address _moderator) external onlyOwner whenNotPaused {
        moderators[_moderator] = false;
        emit ModeratorRemoved(_moderator, _msgSender());
    }

    /**
     * @dev Retrieves content IDs associated with a specific tag.
     * @param _tag The tag to search for.
     * @return uint256[] Array of content IDs matching the tag.
     */
    function getContentByTag(string memory _tag) external view returns (uint256[] memory) {
        return tagToContent[_tag];
    }

    /**
     * @dev Retrieves trending content based on upvotes. (Basic implementation, can be improved with more sophisticated algorithms)
     * @return uint256[] Array of trending content IDs, sorted by upvotes in descending order (limited to top 10 for example).
     */
    function getTrendingContent() external view returns (uint256[] memory) {
        uint256 contentCount = getContentCount();
        uint256[] memory allContentIds = new uint256[](contentCount);
        uint256[] memory trendingContentIds = new uint256[](contentCount); // Max size, could be smaller in reality
        uint256 trendingCount = 0;

        for (uint256 i = 1; i <= contentCount; i++) {
            allContentIds[i-1] = i;
        }

        // Basic sorting by upvotes (inefficient for large datasets, can be optimized)
        for (uint256 i = 0; i < contentCount; i++) {
            for (uint256 j = i + 1; j < contentCount; j++) {
                if (contents[allContentIds[i]].upvotes < contents[allContentIds[j]].upvotes) {
                    uint256 tempId = allContentIds[i];
                    allContentIds[i] = allContentIds[j];
                    allContentIds[j] = tempId;
                }
            }
        }

        // Take top 10 trending content (or fewer if less than 10 content items)
        uint256 limit = Math.min(contentCount, 10);
        for (uint256 i = 0; i < limit; i++) {
            trendingContentIds[trendingCount++] = allContentIds[i];
        }

        // Resize the trendingContentIds array to the actual number of trending content items
        assembly {
            mstore(trendingContentIds, trendingCount) // Update the length of the array in memory
        }

        return trendingContentIds;
    }

    /**
     * @dev Sets the platform fee percentage for content purchases. Only admin can call.
     * @param _newFeePercentage The new platform fee percentage.
     */
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage, _msgSender());
    }

    /**
     * @dev Allows the platform admin to withdraw accumulated platform fees.
     */
    function platformWithdrawFees() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 withdrawableAmount = balance; // In a real-world scenario, track platform fees separately for more accurate withdrawal.
        payable(owner()).transfer(withdrawableAmount); // Admin receives platform fees for now, can be changed to platformFeeRecipient
        emit PlatformFeesWithdrawn(withdrawableAmount, _msgSender());
    }

    /**
     * @dev Pauses core platform functionalities. Only admin can call.
     */
    function pausePlatform() external onlyOwner whenNotPaused {
        platformPaused = true;
        emit PlatformPaused(_msgSender());
    }

    /**
     * @dev Resumes platform functionalities after pausing. Only admin can call.
     */
    function unpausePlatform() external onlyOwner whenPaused {
        platformPaused = false;
        emit PlatformUnpaused(_msgSender());
    }

    // --- Internal helper functions for tag management ---
    function addContentToTagMapping(string memory _tag, uint256 _contentId) internal {
        tagToContent[_tag].push(_contentId);
    }

    function removeContentFromTagMapping(string memory _tag, uint256 _contentId) internal {
        uint256[] storage contentIdsForTag = tagToContent[_tag];
        for (uint i = 0; i < contentIdsForTag.length; i++) {
            if (contentIdsForTag[i] == _contentId) {
                // Remove the contentId from the array (shift elements to the left)
                for (uint j = i; j < contentIdsForTag.length - 1; j++) {
                    contentIdsForTag[j] = contentIdsForTag[j + 1];
                }
                contentIdsForTag.pop(); // Remove the last element (duplicate from shift)
                break; // Exit loop after removing the contentId
            }
        }
    }
}
```