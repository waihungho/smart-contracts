```solidity
/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized platform that allows creators to publish dynamic content (text, images, links)
 *      that can evolve based on community interaction and creator updates.
 *
 * **Outline:**
 * 1. **Content Creation and Management:**
 *    - `createContent()`: Allows creators to submit new content with initial metadata.
 *    - `updateContentMetadata()`: Creators can update the metadata of their content (title, description, tags).
 *    - `addContentVersion()`: Creators can add new versions of the content, making it dynamic and evolving.
 *    - `getContentDetails()`: Retrieves detailed information about a specific content item, including versions.
 *    - `listCreatorContent()`: Lists all content created by a specific address.
 *    - `listContentByTag()`: Lists content items associated with a specific tag.
 *    - `archiveContent()`: Allows creators to archive content, making it read-only and removing it from active listings.
 *    - `reactivateContent()`: Reactivates archived content.
 *
 * 2. **Community Interaction and Governance:**
 *    - `upvoteContent()`: Allows community members to upvote content.
 *    - `downvoteContent()`: Allows community members to downvote content.
 *    - `reportContent()`: Allows community members to report content for moderation.
 *    - `moderateContent()`: (Governance/Admin function) Allows designated moderators to review and moderate reported content (e.g., hide, delete).
 *    - `proposeTag()`: Allows community members to propose new tags for content categorization.
 *    - `voteOnTagProposal()`: (Governance/Admin function) Allows designated governors to vote on tag proposals.
 *
 * 3. **Content Discovery and Personalization:**
 *    - `getTrendingContent()`: Returns a list of content items sorted by upvotes in a recent period.
 *    - `getPopularContent()`: Returns a list of content items sorted by total upvotes.
 *    - `getNewestContent()`: Returns a list of the most recently created content.
 *    - `searchContent()`: Allows searching for content based on keywords (basic keyword matching).
 *    - `followCreator()`: Allows users to follow creators and get updates on their new content.
 *    - `getFollowingContentFeed()`: Returns a personalized feed of content from creators followed by a user.
 *
 * 4. **Utility and System Functions:**
 *    - `setPlatformFee()`: (Admin function) Sets a platform fee for certain actions (e.g., content creation, advanced features - optional).
 *    - `withdrawPlatformFees()`: (Admin function) Allows the platform owner to withdraw accumulated fees.
 *    - `getContentCount()`: Returns the total number of content items on the platform.
 *    - `getTagCount()`: Returns the total number of tags used on the platform.
 *
 * **Function Summary:**
 * - `createContent(string _title, string _description, string _initialVersionContent, string[] _tags)`: Allows creators to submit new content.
 * - `updateContentMetadata(uint256 _contentId, string _title, string _description, string[] _tags)`: Updates content metadata.
 * - `addContentVersion(uint256 _contentId, string _newVersionContent)`: Adds a new version of the content.
 * - `getContentDetails(uint256 _contentId)`: Retrieves details of a specific content item.
 * - `listCreatorContent(address _creator)`: Lists content by a creator.
 * - `listContentByTag(string _tag)`: Lists content by tag.
 * - `archiveContent(uint256 _contentId)`: Archives content.
 * - `reactivateContent(uint256 _contentId)`: Reactivates content.
 * - `upvoteContent(uint256 _contentId)`: Upvotes content.
 * - `downvoteContent(uint256 _contentId)`: Downvotes content.
 * - `reportContent(uint256 _contentId, string _reportReason)`: Reports content.
 * - `moderateContent(uint256 _contentId, ModerationAction _action)`: Moderates reported content.
 * - `proposeTag(string _tagName)`: Proposes a new tag.
 * - `voteOnTagProposal(uint256 _proposalId, bool _approve)`: Votes on a tag proposal.
 * - `getTrendingContent(uint256 _timeWindow)`: Gets trending content.
 * - `getPopularContent()`: Gets popular content.
 * - `getNewestContent()`: Gets newest content.
 * - `searchContent(string _keywords)`: Searches content by keywords.
 * - `followCreator(address _creator)`: Follows a creator.
 * - `getFollowingContentFeed()`: Gets content feed for followed creators.
 * - `setPlatformFee(uint256 _fee)`: Sets platform fee.
 * - `withdrawPlatformFees()`: Withdraws platform fees.
 * - `getContentCount()`: Gets total content count.
 * - `getTagCount()`: Gets total tag count.
 */
pragma solidity ^0.8.0;

contract DecentralizedDynamicContentPlatform {

    enum ModerationAction { HIDE, DELETE, NO_ACTION }
    enum ProposalStatus { PENDING, APPROVED, REJECTED }

    struct ContentItem {
        uint256 id;
        address creator;
        string title;
        string description;
        string[] tags;
        string[] versions; // Array of content versions (dynamic content)
        uint256 createdAtTimestamp;
        uint256 lastUpdatedTimestamp;
        int256 upvotes;
        int256 downvotes;
        bool isArchived;
    }

    struct TagProposal {
        uint256 id;
        string tagName;
        address proposer;
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
    }

    uint256 public platformFee = 0; // Optional platform fee
    address public platformOwner;
    uint256 public contentCount = 0;
    uint256 public tagProposalCount = 0;
    uint256 public tagCount = 0;

    mapping(uint256 => ContentItem) public contentItems;
    mapping(address => uint256[]) public creatorContentList; // List of content IDs for each creator
    mapping(string => uint256[]) public tagContentList;     // List of content IDs for each tag
    mapping(uint256 => TagProposal) public tagProposals;
    mapping(address => mapping(address => bool)) public creatorFollowers; // Follower -> Creator -> isFollowing
    mapping(uint256 => mapping(address => bool)) public contentUpvotes; // ContentID -> User -> hasUpvoted
    mapping(uint256 => mapping(address => bool)) public contentDownvotes; // ContentID -> User -> hasDownvoted
    mapping(uint256 => address[]) public contentReports; // ContentID -> List of reporters

    string[] public availableTags; // List of approved tags

    address[] public moderators; // Addresses authorized to moderate content
    address[] public governors;  // Addresses authorized to govern tag proposals

    event ContentCreated(uint256 contentId, address creator, string title);
    event ContentUpdated(uint256 contentId, string title);
    event ContentVersionAdded(uint256 contentId, uint256 versionIndex);
    event ContentArchived(uint256 contentId);
    event ContentReactivated(uint256 contentId);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, ModerationAction action, address moderator);
    event TagProposed(uint256 proposalId, string tagName, address proposer);
    event TagProposalVoted(uint256 proposalId, bool approved, address governor);
    event TagApproved(string tagName);
    event CreatorFollowed(address follower, address creator);
    event PlatformFeeSet(uint256 newFee);
    event PlatformFeesWithdrawn(address owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        bool isModerator = false;
        for (uint i = 0; i < moderators.length; i++) {
            if (moderators[i] == msg.sender) {
                isModerator = true;
                break;
            }
        }
        require(isModerator, "Only moderators can call this function.");
        _;
    }

    modifier onlyGovernor() {
        bool isGovernor = false;
        for (uint i = 0; i < governors.length; i++) {
            if (governors[i] == msg.sender) {
                isGovernor = true;
                break;
            }
        }
        require(isGovernor, "Only governors can call this function.");
        _;
    }

    constructor() {
        platformOwner = msg.sender;
        moderators.push(msg.sender); // Platform owner is also a moderator initially
        governors.push(msg.sender);  // Platform owner is also a governor initially
    }

    /**
     * @dev Allows creators to submit new content.
     * @param _title The title of the content.
     * @param _description A brief description of the content.
     * @param _initialVersionContent The initial content text.
     * @param _tags An array of tags to categorize the content.
     */
    function createContent(string memory _title, string memory _description, string memory _initialVersionContent, string[] memory _tags) public payable {
        // Optional: if platformFee > 0, require payment
        // if (platformFee > 0) {
        //     require(msg.value >= platformFee, "Insufficient platform fee.");
        //     // Transfer fee to platform owner (or treasury) - omitted for simplicity in this example
        // }

        contentCount++;
        uint256 contentId = contentCount;

        ContentItem memory newContent = ContentItem({
            id: contentId,
            creator: msg.sender,
            title: _title,
            description: _description,
            tags: _tags,
            versions: new string[](1), // Initialize versions array
            createdAtTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            isArchived: false
        });
        newContent.versions[0] = _initialVersionContent; // Set initial version

        contentItems[contentId] = newContent;
        creatorContentList[msg.sender].push(contentId);

        // Add content to tag lists
        for (uint i = 0; i < _tags.length; i++) {
            string memory tag = _tags[i];
            bool tagExists = false;
            for(uint j=0; j < availableTags.length; j++) {
                if (keccak256(bytes(availableTags[j])) == keccak256(bytes(tag))) {
                    tagExists = true;
                    break;
                }
            }
            if(tagExists) {
                tagContentList[tag].push(contentId);
            }
        }

        emit ContentCreated(contentId, msg.sender, _title);
    }

    /**
     * @dev Allows creators to update the metadata of their content.
     * @param _contentId The ID of the content to update.
     * @param _title New title for the content.
     * @param _description New description for the content.
     * @param _tags New array of tags for the content.
     */
    function updateContentMetadata(uint256 _contentId, string memory _title, string memory _description, string[] memory _tags) public {
        require(contentItems[_contentId].creator == msg.sender, "Only content creator can update metadata.");
        require(!contentItems[_contentId].isArchived, "Cannot update metadata of archived content.");

        contentItems[_contentId].title = _title;
        contentItems[_contentId].description = _description;
        contentItems[_contentId].tags = _tags;
        contentItems[_contentId].lastUpdatedTimestamp = block.timestamp;

        // Update tag lists (more complex logic could be added to handle tag changes more efficiently)
        // For simplicity, we are just re-indexing tags - could be optimized
        for (string memory tag : availableTags) {
            delete tagContentList[tag]; // Clear existing tag lists for this content - inefficient, but simple for example
        }
        for (uint i = 1; i <= contentCount; i++) { // Rebuild tag lists
            if (!contentItems[i].isArchived) {
                for (string memory tag : contentItems[i].tags) {
                    bool tagExists = false;
                    for(uint j=0; j < availableTags.length; j++) {
                        if (keccak256(bytes(availableTags[j])) == keccak256(bytes(tag))) {
                            tagExists = true;
                            break;
                        }
                    }
                    if(tagExists) {
                        tagContentList[tag].push(i);
                    }
                }
            }
        }


        emit ContentUpdated(_contentId, _title);
    }

    /**
     * @dev Allows creators to add a new version of the content.
     * @param _contentId The ID of the content to update.
     * @param _newVersionContent The new content version.
     */
    function addContentVersion(uint256 _contentId, string memory _newVersionContent) public {
        require(contentItems[_contentId].creator == msg.sender, "Only content creator can add versions.");
        require(!contentItems[_contentId].isArchived, "Cannot add version to archived content.");

        contentItems[_contentId].versions.push(_newVersionContent);
        contentItems[_contentId].lastUpdatedTimestamp = block.timestamp;

        emit ContentVersionAdded(_contentId, contentItems[_contentId].versions.length - 1);
    }

    /**
     * @dev Retrieves detailed information about a specific content item.
     * @param _contentId The ID of the content to retrieve.
     * @return ContentItem struct containing content details.
     */
    function getContentDetails(uint256 _contentId) public view returns (ContentItem memory) {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");
        return contentItems[_contentId];
    }

    /**
     * @dev Lists all content created by a specific address.
     * @param _creator The address of the creator.
     * @return An array of content IDs created by the address.
     */
    function listCreatorContent(address _creator) public view returns (uint256[] memory) {
        return creatorContentList[_creator];
    }

    /**
     * @dev Lists content items associated with a specific tag.
     * @param _tag The tag to search for.
     * @return An array of content IDs with the given tag.
     */
    function listContentByTag(string memory _tag) public view returns (uint256[] memory) {
        return tagContentList[_tag];
    }

    /**
     * @dev Allows creators to archive content, making it read-only.
     * @param _contentId The ID of the content to archive.
     */
    function archiveContent(uint256 _contentId) public {
        require(contentItems[_contentId].creator == msg.sender, "Only content creator can archive content.");
        require(!contentItems[_contentId].isArchived, "Content is already archived.");

        contentItems[_contentId].isArchived = true;
        emit ContentArchived(_contentId);
    }

    /**
     * @dev Reactivates archived content, making it editable again.
     * @param _contentId The ID of the content to reactivate.
     */
    function reactivateContent(uint256 _contentId) public {
        require(contentItems[_contentId].creator == msg.sender, "Only content creator can reactivate content.");
        require(contentItems[_contentId].isArchived, "Content is not archived.");

        contentItems[_contentId].isArchived = false;
        emit ContentReactivated(_contentId);
    }

    /**
     * @dev Allows community members to upvote content.
     * @param _contentId The ID of the content to upvote.
     */
    function upvoteContent(uint256 _contentId) public {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");
        require(!contentItems[_contentId].isArchived, "Cannot upvote archived content.");
        require(!contentUpvotes[_contentId][msg.sender], "Already upvoted this content.");

        if (contentDownvotes[_contentId][msg.sender]) {
            contentDownvotes[_contentId][msg.sender] = false; // Remove downvote if previously downvoted
            contentItems[_contentId].downvotes--;
        }

        contentUpvotes[_contentId][msg.sender] = true;
        contentItems[_contentId].upvotes++;
        emit ContentUpvoted(_contentId, msg.sender);
    }

    /**
     * @dev Allows community members to downvote content.
     * @param _contentId The ID of the content to downvote.
     */
    function downvoteContent(uint256 _contentId) public {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");
        require(!contentItems[_contentId].isArchived, "Cannot downvote archived content.");
        require(!contentDownvotes[_contentId][msg.sender], "Already downvoted this content.");

        if (contentUpvotes[_contentId][msg.sender]) {
            contentUpvotes[_contentId][msg.sender] = false; // Remove upvote if previously upvoted
            contentItems[_contentId].upvotes--;
        }

        contentDownvotes[_contentId][msg.sender] = true;
        contentItems[_contentId].downvotes--;
        emit ContentDownvoted(_contentId, msg.sender);
    }

    /**
     * @dev Allows community members to report content for moderation.
     * @param _contentId The ID of the content to report.
     * @param _reportReason The reason for reporting.
     */
    function reportContent(uint256 _contentId, string memory _reportReason) public {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");
        require(!contentItems[_contentId].isArchived, "Cannot report archived content.");

        // Prevent duplicate reports from the same user (optional)
        for (uint i = 0; i < contentReports[_contentId].length; i++) {
            if (contentReports[_contentId][i] == msg.sender) {
                return; // Already reported
            }
        }

        contentReports[_contentId].push(msg.sender);
        // In a real application, you'd likely store _reportReason and potentially trigger notifications for moderators.
        emit ContentReported(_contentId, msg.sender, _reportReason);
    }

    /**
     * @dev Allows moderators to review and moderate reported content.
     * @param _contentId The ID of the content to moderate.
     * @param _action The moderation action to take (HIDE, DELETE, NO_ACTION).
     */
    function moderateContent(uint256 _contentId, ModerationAction _action) public onlyModerator {
        require(_contentId > 0 && _contentId <= contentCount, "Invalid content ID.");

        if (_action == ModerationAction.HIDE) {
            contentItems[_contentId].isArchived = true; // Hiding can be implemented as archiving
        } else if (_action == ModerationAction.DELETE) {
            // More complex deletion logic might be needed in a real application (e.g., remove from lists)
            delete contentItems[_contentId];
            // Invalidate content ID in creatorContentList and tagContentList (more complex cleanup needed for production)
            // For simplicity, leaving it as basic delete in this example.
        } // NO_ACTION does nothing

        emit ContentModerated(_contentId, _action, msg.sender);
    }

    /**
     * @dev Allows community members to propose new tags.
     * @param _tagName The name of the proposed tag.
     */
    function proposeTag(string memory _tagName) public {
        require(bytes(_tagName).length > 0, "Tag name cannot be empty.");

        // Check if tag already exists (optional - can allow duplicate proposals for governance)
        for (uint i = 0; i < availableTags.length; i++) {
            if (keccak256(bytes(availableTags[i])) == keccak256(bytes(_tagName))) {
                return; // Tag already exists
            }
        }

        tagProposalCount++;
        uint256 proposalId = tagProposalCount;
        tagProposals[proposalId] = TagProposal({
            id: proposalId,
            tagName: _tagName,
            proposer: msg.sender,
            status: ProposalStatus.PENDING,
            upvotes: 0,
            downvotes: 0
        });

        emit TagProposed(proposalId, _tagName, msg.sender);
    }

    /**
     * @dev Allows governors to vote on tag proposals.
     * @param _proposalId The ID of the tag proposal.
     * @param _approve True to approve the tag, false to reject.
     */
    function voteOnTagProposal(uint256 _proposalId, bool _approve) public onlyGovernor {
        require(tagProposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");

        if (_approve) {
            tagProposals[_proposalId].upvotes++;
            if (tagProposals[_proposalId].upvotes >= (governors.length / 2) + 1) { // Simple majority
                tagProposals[_proposalId].status = ProposalStatus.APPROVED;
                availableTags.push(tagProposals[_proposalId].tagName);
                tagCount++;
                emit TagApproved(tagProposals[_proposalId].tagName);
            }
        } else {
            tagProposals[_proposalId].downvotes++;
            if (tagProposals[_proposalId].downvotes >= (governors.length / 2) + 1) { // Simple majority
                tagProposals[_proposalId].status = ProposalStatus.REJECTED;
            }
        }
        emit TagProposalVoted(_proposalId, _approve, msg.sender);
    }

    /**
     * @dev Returns a list of content items sorted by upvotes in a recent period (e.g., last 24 hours).
     * @param _timeWindow Time window in seconds (e.g., 24 hours = 86400 seconds).
     * @return An array of content IDs, sorted by trending score.
     */
    function getTrendingContent(uint256 _timeWindow) public view returns (uint256[] memory) {
        uint256[] memory trendingContentIds = new uint256[](contentCount);
        uint256 count = 0;
        for (uint i = 1; i <= contentCount; i++) {
            if (!contentItems[i].isArchived && block.timestamp - contentItems[i].createdAtTimestamp <= _timeWindow) {
                trendingContentIds[count++] = i;
            }
        }

        // Basic bubble sort for demonstration - use more efficient sorting for large datasets
        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (contentItems[trendingContentIds[j]].upvotes < contentItems[trendingContentIds[j + 1]].upvotes) {
                    uint256 temp = trendingContentIds[j];
                    trendingContentIds[j] = trendingContentIds[j + 1];
                    trendingContentIds[j + 1] = temp;
                }
            }
        }

        // Resize array to actual size
        uint256[] memory result = new uint256[](count);
        for(uint i=0; i<count; i++) {
            result[i] = trendingContentIds[i];
        }
        return result;
    }

    /**
     * @dev Returns a list of content items sorted by total upvotes.
     * @return An array of content IDs, sorted by popularity.
     */
    function getPopularContent() public view returns (uint256[] memory) {
        uint256[] memory popularContentIds = new uint256[](contentCount);
        uint256 count = 0;
        for (uint i = 1; i <= contentCount; i++) {
            if (!contentItems[i].isArchived) {
                popularContentIds[count++] = i;
            }
        }

        // Basic bubble sort for demonstration - use more efficient sorting for large datasets
        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (contentItems[popularContentIds[j]].upvotes < contentItems[popularContentIds[j + 1]].upvotes) {
                    uint256 temp = popularContentIds[j];
                    popularContentIds[j] = popularContentIds[j + 1];
                    popularContentIds[j + 1] = temp;
                }
            }
        }
        // Resize array to actual size
        uint256[] memory result = new uint256[](count);
        for(uint i=0; i<count; i++) {
            result[i] = popularContentIds[i];
        }
        return result;
    }

    /**
     * @dev Returns a list of the most recently created content.
     * @return An array of content IDs, sorted by creation date (newest first).
     */
    function getNewestContent() public view returns (uint256[] memory) {
        uint256[] memory newestContentIds = new uint256[](contentCount);
        uint256 count = 0;
        for (uint i = 1; i <= contentCount; i++) {
            if (!contentItems[i].isArchived) {
                newestContentIds[count++] = i;
            }
        }

        // Basic bubble sort for demonstration - use more efficient sorting for large datasets
        for (uint i = 0; i < count - 1; i++) {
            for (uint j = 0; j < count - i - 1; j++) {
                if (contentItems[newestContentIds[j]].createdAtTimestamp < contentItems[newestContentIds[j + 1]].createdAtTimestamp) {
                    uint256 temp = newestContentIds[j];
                    newestContentIds[j] = newestContentIds[j + 1];
                    newestContentIds[j + 1] = temp;
                }
            }
        }
        // Resize array to actual size
        uint256[] memory result = new uint256[](count);
        for(uint i=0; i<count; i++) {
            result[i] = newestContentIds[i];
        }
        return result;
    }

    /**
     * @dev Allows searching for content based on keywords (basic keyword matching - can be improved).
     * @param _keywords Space-separated keywords to search for in content titles and descriptions.
     * @return An array of content IDs that match the keywords.
     */
    function searchContent(string memory _keywords) public view returns (uint256[] memory) {
        string[] memory keywordsArray = split(_keywords, " "); // Basic split by space
        uint256[] memory searchResults = new uint256[](contentCount); // Max possible results
        uint256 resultCount = 0;

        for (uint i = 1; i <= contentCount; i++) {
            if (contentItems[i].isArchived) continue;

            string memory lowerTitle = toLower(contentItems[i].title);
            string memory lowerDescription = toLower(contentItems[i].description);

            bool match = false;
            for (uint j = 0; j < keywordsArray.length; j++) {
                string memory keyword = toLower(keywordsArray[j]);
                if (stringContains(lowerTitle, keyword) || stringContains(lowerDescription, keyword)) {
                    match = true;
                    break;
                }
            }
            if (match) {
                searchResults[resultCount++] = i;
            }
        }
        // Resize array to actual size
        uint256[] memory result = new uint256[](resultCount);
        for(uint i=0; i<resultCount; i++) {
            result[i] = searchResults[i];
        }
        return result;
    }

    /**
     * @dev Allows users to follow creators.
     * @param _creator The address of the creator to follow.
     */
    function followCreator(address _creator) public {
        require(_creator != address(0) && _creator != msg.sender, "Invalid creator address.");
        creatorFollowers[msg.sender][_creator] = true;
        emit CreatorFollowed(msg.sender, _creator);
    }

    /**
     * @dev Returns a personalized feed of content from creators followed by a user.
     * @return An array of content IDs from followed creators, sorted by creation date (newest first).
     */
    function getFollowingContentFeed() public view returns (uint256[] memory) {
        uint256[] memory feedContentIds;
        uint256 feedCount = 0;

        address[] memory followedCreators;
        uint256 creatorCount = 0;
        for (address creator in creatorFollowers[msg.sender]) {
            if (creatorFollowers[msg.sender][creator]) {
                creatorCount++;
            }
        }
        followedCreators = new address[](creatorCount);
        uint256 idx = 0;
        for (address creator in creatorFollowers[msg.sender]) {
             if (creatorFollowers[msg.sender][creator]) {
                followedCreators[idx++] = creator;
             }
        }


        for (uint i = 0; i < followedCreators.length; i++) {
            address creator = followedCreators[i];
            uint256[] memory creatorContent = creatorContentList[creator];
            for (uint j = 0; j < creatorContent.length; j++) {
                uint256 contentId = creatorContent[j];
                if (!contentItems[contentId].isArchived) {
                    // Dynamically resize feedContentIds - inefficient for large feeds, use better data structures for real app
                    uint256[] memory tempFeed = new uint256[](feedCount + 1);
                    for (uint k = 0; k < feedCount; k++) {
                        tempFeed[k] = feedContentIds[k];
                    }
                    tempFeed[feedCount] = contentId;
                    feedContentIds = tempFeed;
                    feedCount++;
                }
            }
        }

        // Sort feed by creation date (newest first) - basic sort, optimize for large feeds
        for (uint i = 0; i < feedCount - 1; i++) {
            for (uint j = 0; j < feedCount - i - 1; j++) {
                if (contentItems[feedContentIds[j]].createdAtTimestamp < contentItems[feedContentIds[j + 1]].createdAtTimestamp) {
                    uint256 temp = feedContentIds[j];
                    feedContentIds[j] = feedContentIds[j + 1];
                    feedContentIds[j + 1] = temp;
                }
            }
        }

        return feedContentIds;
    }

    /**
     * @dev Admin function to set the platform fee for certain actions (optional).
     * @param _fee The new platform fee amount.
     */
    function setPlatformFee(uint256 _fee) public onlyOwner {
        platformFee = _fee;
        emit PlatformFeeSet(_fee);
    }

    /**
     * @dev Admin function to withdraw accumulated platform fees (if any).
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(platformOwner).transfer(balance);
        emit PlatformFeesWithdrawn(platformOwner, balance);
    }

    /**
     * @dev Returns the total number of content items on the platform.
     * @return The total content count.
     */
    function getContentCount() public view returns (uint256) {
        return contentCount;
    }

    /**
     * @dev Returns the total number of tags used on the platform.
     * @return The total tag count.
     */
    function getTagCount() public view returns (uint256) {
        return tagCount;
    }

    // --- Utility functions (for string manipulation - basic implementations) ---
    function split(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);

        if (delimiterBytes.length == 0 || strBytes.length == 0) {
            return new string[](0);
        }

        uint256 count = 1;
        for (uint256 i = 0; i < strBytes.length - delimiterBytes.length + 1; i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                count++;
                i += delimiterBytes.length - 1;
            }
        }

        string[] memory result = new string[](count);
        uint256 resultIndex = 0;
        uint256 startIndex = 0;

        for (uint256 i = 0; i < strBytes.length - delimiterBytes.length + 1; i++) {
            bool found = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                result[resultIndex++] = string(slice(strBytes, startIndex, i));
                startIndex = i + delimiterBytes.length;
                i += delimiterBytes.length - 1;
            }
        }

        result[resultIndex++] = string(slice(strBytes, startIndex, strBytes.length));

        return result;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length <= _bytes.length - _start, "Slice bounds out of range");

        bytes memory tempBytes = new bytes(_length);

        for (uint256 i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function stringContains(string memory _str, string memory _substring) internal pure returns (bool) {
        if (bytes(_substring).length == 0) {
            return true; // Empty substring is always contained
        }
        if (bytes(_str).length < bytes(_substring).length) {
            return false; // Substring longer than string
        }

        for (uint i = 0; i <= bytes(_str).length - bytes(_substring).length; i++) {
            bool match = true;
            for (uint j = 0; j < bytes(_substring).length; j++) {
                if (bytes(_str)[i + j] != bytes(_substring)[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true;
            }
        }
        return false;
    }
}
```