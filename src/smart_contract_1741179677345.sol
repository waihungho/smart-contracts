```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (Example Smart Contract - Conceptual and for Demonstration)
 * @dev A smart contract for a decentralized platform that hosts dynamic content,
 *      leveraging user interaction, reputation, and potentially AI-driven elements
 *      for content personalization and discovery. This is a conceptual example
 *      and is not intended for production use without thorough security audits
 *      and further development.
 *
 * Outline & Function Summary:
 *
 * 1.  **Content Management:**
 *     - `submitContent(string memory title, string memory content, string[] memory tags)`: Allows users to submit new content with title, content, and tags.
 *     - `editContent(uint256 contentId, string memory newTitle, string memory newContent, string[] memory newTags)`: Allows content owners to edit their content.
 *     - `deleteContent(uint256 contentId)`: Allows content owners to delete their content.
 *     - `getContent(uint256 contentId)`: Retrieves content details by ID.
 *     - `getContentList(uint256 page, uint256 pageSize)`: Retrieves a paginated list of content IDs.
 *     - `getContentByTag(string memory tag, uint256 page, uint256 pageSize)`: Retrieves content IDs filtered by a specific tag (paginated).
 *     - `getContentCount()`: Returns the total number of content items.
 *
 * 2.  **Voting and Reputation System:**
 *     - `upvoteContent(uint256 contentId)`: Allows users to upvote content.
 *     - `downvoteContent(uint256 contentId)`: Allows users to downvote content.
 *     - `getVoteCount(uint256 contentId)`: Retrieves the upvote and downvote count for a content item.
 *     - `getUserVote(uint256 contentId, address user)`: Checks if a user has voted on a specific content item and their vote type.
 *     - `getUserReputation(address user)`: Retrieves the reputation score of a user.
 *     - `adjustReputation(address user, int256 reputationChange)` (Admin/Internal): Allows admin or internal functions to adjust user reputation.
 *     - `getReputationThresholdForFeature(string memory featureName)`: Retrieves the reputation threshold required to access a specific feature.
 *
 * 3.  **Content Recommendation (Conceptual - AI Integration Placeholder):**
 *     - `getRecommendedContentForUser(address user)`: (Conceptual) Placeholder for a function that would recommend content to a user based on their preferences/history (AI integration point).
 *     - `updateUserPreferences(address user, string[] memory tags)`: (Conceptual) Placeholder for allowing users to update their content preferences (for recommendation systems).
 *
 * 4.  **Content Moderation (Basic - Expandable):**
 *     - `reportContent(uint256 contentId, string memory reason)`: Allows users to report content for moderation.
 *     - `moderateContent(uint256 contentId, bool isApproved)` (Admin): Allows admin to moderate reported content and approve/reject it.
 *     - `getContentModerationStatus(uint256 contentId)`: Retrieves the moderation status of a content item.
 *
 * 5.  **Platform Settings & Admin Functions:**
 *     - `setReputationThreshold(string memory featureName, uint256 threshold)` (Admin): Sets the reputation threshold for a specific feature.
 *     - `setVotingWeight(uint256 upvoteWeight, uint256 downvoteWeight)` (Admin): Sets the weight of upvotes and downvotes on content score and reputation.
 *     - `pauseContract()` (Admin): Pauses the contract functionality (emergency stop).
 *     - `unpauseContract()` (Admin): Resumes the contract functionality.
 *     - `transferOwnership(address newOwner)` (Admin): Transfers contract ownership to a new address.
 */

contract DecentralizedDynamicContentPlatform {
    // -------- Data Structures --------

    struct ContentItem {
        uint256 id;
        address author;
        string title;
        string content;
        string[] tags;
        uint256 upvotes;
        uint256 downvotes;
        uint256 createdAt;
        ModerationStatus moderationStatus;
    }

    enum ModerationStatus {
        PENDING,
        APPROVED,
        REJECTED
    }

    struct UserReputation {
        uint256 score;
    }

    // -------- State Variables --------

    mapping(uint256 => ContentItem) public contentItems; // Content ID => Content Item
    uint256 public contentCount;
    mapping(address => UserReputation) public userReputations; // User Address => Reputation
    mapping(uint256 => mapping(address => int8)) public contentVotes; // Content ID => User Address => Vote (-1: downvote, 0: no vote, 1: upvote)
    mapping(string => uint256) public reputationThresholds; // Feature Name => Reputation Threshold
    mapping(uint256 => ModerationStatus) public contentModerationStatuses; // Content ID => Moderation Status

    address public owner;
    bool public paused;
    uint256 public upvoteWeight = 1; // Default upvote weight
    uint256 public downvoteWeight = 1; // Default downvote weight

    // -------- Events --------

    event ContentSubmitted(uint256 contentId, address author, string title);
    event ContentEdited(uint256 contentId, address author, string title);
    event ContentDeleted(uint256 contentId, address author);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ReputationChanged(address user, int256 change, uint256 newReputation);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, ModerationStatus status, address moderator);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier reputationAboveThreshold(string memory featureName) {
        require(userReputations[msg.sender].score >= reputationThresholds[featureName], "Reputation too low for this feature.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        paused = false;
        reputationThresholds["editContent"] = 10; // Example threshold for editing content
        reputationThresholds["downvoteContent"] = 5; // Example threshold for downvoting
        reputationThresholds["reportContent"] = 0; // Example threshold for reporting
    }

    // -------- 1. Content Management Functions --------

    /// @notice Allows users to submit new content.
    /// @param title The title of the content.
    /// @param content The main content text.
    /// @param tags An array of tags associated with the content.
    function submitContent(string memory title, string memory content, string[] memory tags) external whenNotPaused {
        contentCount++;
        uint256 contentId = contentCount;
        contentItems[contentId] = ContentItem({
            id: contentId,
            author: msg.sender,
            title: title,
            content: content,
            tags: tags,
            upvotes: 0,
            downvotes: 0,
            createdAt: block.timestamp,
            moderationStatus: ModerationStatus.PENDING // Initial status is pending moderation
        });
        contentModerationStatuses[contentId] = ModerationStatus.PENDING;
        emit ContentSubmitted(contentId, msg.sender, title);
    }

    /// @notice Allows content owners to edit their content, requires reputation.
    /// @param contentId The ID of the content to edit.
    /// @param newTitle The new title of the content.
    /// @param newContent The new content text.
    /// @param newTags The new array of tags.
    function editContent(uint256 contentId, string memory newTitle, string memory newContent, string[] memory newTags) external whenNotPaused reputationAboveThreshold("editContent") {
        require(contentItems[contentId].author == msg.sender, "Only content author can edit.");
        contentItems[contentId].title = newTitle;
        contentItems[contentId].content = newContent;
        contentItems[contentId].tags = newTags;
        contentModerationStatuses[contentId] = ModerationStatus.PENDING; // Re-set to pending after edit
        emit ContentEdited(contentId, msg.sender, newTitle);
    }

    /// @notice Allows content owners to delete their content.
    /// @param contentId The ID of the content to delete.
    function deleteContent(uint256 contentId) external whenNotPaused {
        require(contentItems[contentId].author == msg.sender, "Only content author can delete.");
        delete contentItems[contentId];
        emit ContentDeleted(contentId, msg.sender);
    }

    /// @notice Retrieves content details by ID.
    /// @param contentId The ID of the content to retrieve.
    /// @return ContentItem struct containing content details.
    function getContent(uint256 contentId) external view whenNotPaused returns (ContentItem memory) {
        require(contentItems[contentId].id == contentId, "Content not found."); // Check if content exists
        return contentItems[contentId];
    }

    /// @notice Retrieves a paginated list of content IDs.
    /// @param page The page number (starting from 1).
    /// @param pageSize The number of content IDs per page.
    /// @return An array of content IDs for the requested page.
    function getContentList(uint256 page, uint256 pageSize) external view whenNotPaused returns (uint256[] memory) {
        require(pageSize > 0, "Page size must be greater than 0.");
        uint256 start = (page - 1) * pageSize;
        uint256 end = start + pageSize;
        if (start >= contentCount) {
            return new uint256[](0); // Return empty array if page is out of range
        }
        if (end > contentCount) {
            end = contentCount;
        }
        uint256[] memory contentIdList = new uint256[](end - start);
        uint256 index = 0;
        for (uint256 i = start + 1; i <= end; i++) { // Content IDs start from 1
            if (contentItems[i].id != 0) { // Check if content exists (in case of deletions)
                contentIdList[index] = i;
                index++;
            }
        }
        assembly { // Assembly optimization to remove empty slots if content was deleted
            let originalLength := mload(contentIdList)
            let newLength := index
            mstore(contentIdList, newLength) // Update the length to actual filled slots
        }
        return contentIdList;
    }

    /// @notice Retrieves content IDs filtered by a specific tag (paginated).
    /// @param tag The tag to filter by.
    /// @param page The page number (starting from 1).
    /// @param pageSize The number of content IDs per page.
    /// @return An array of content IDs matching the tag for the requested page.
    function getContentByTag(string memory tag, uint256 page, uint256 pageSize) external view whenNotPaused returns (uint256[] memory) {
        require(pageSize > 0, "Page size must be greater than 0.");
        uint256 start = (page - 1) * pageSize;
        uint256 end = start + pageSize;
        uint256[] memory matchingContentIds = new uint256[](pageSize); // Max size, will be trimmed
        uint256 matchCount = 0;
        uint256 contentIndex = 1; // Start checking from content ID 1

        while (contentIndex <= contentCount && matchCount < pageSize) {
            if (contentItems[contentIndex].id != 0) { // Check if content exists
                bool tagFound = false;
                for (uint256 i = 0; i < contentItems[contentIndex].tags.length; i++) {
                    if (keccak256(bytes(contentItems[contentIndex].tags[i])) == keccak256(bytes(tag))) {
                        tagFound = true;
                        break;
                    }
                }
                if (tagFound) {
                    if (matchCount >= start && matchCount < end) {
                        matchingContentIds[matchCount - start] = contentIndex;
                    }
                    matchCount++;
                }
            }
            contentIndex++;
        }

        assembly { // Assembly optimization to trim array to actual number of matches
            let originalLength := mload(matchingContentIds)
            let newLength := sub(matchCount, start) // Number of matches in current page
            if gt(newLength, originalLength) { // In case calculated length is larger than allocated
                newLength := originalLength
            }
             if lt(newLength, 0) { // In case start page is beyond matches
                newLength := 0
            }
            mstore(matchingContentIds, newLength)
        }

        return matchingContentIds;
    }


    /// @notice Returns the total number of content items.
    /// @return The total content count.
    function getContentCount() external view whenNotPaused returns (uint256) {
        return contentCount;
    }

    // -------- 2. Voting and Reputation System Functions --------

    /// @notice Allows users to upvote content.
    /// @param contentId The ID of the content to upvote.
    function upvoteContent(uint256 contentId) external whenNotPaused {
        require(contentItems[contentId].id == contentId, "Content not found.");
        require(contentModerationStatuses[contentId] == ModerationStatus.APPROVED, "Content is not approved yet or rejected.");

        int8 currentVote = contentVotes[contentId][msg.sender];
        require(currentVote != 1, "You have already upvoted this content.");

        if (currentVote == -1) { // User is changing from downvote to upvote
            contentItems[contentId].downvotes--;
        }
        contentItems[contentId].upvotes++;
        contentVotes[contentId][msg.sender] = 1;

        // Reputation adjustment for content author on upvote
        adjustReputation(contentItems[contentId].author, int256(upvoteWeight)); // Positive reputation change
        emit ContentUpvoted(contentId, msg.sender);
    }

    /// @notice Allows users to downvote content, requires reputation.
    /// @param contentId The ID of the content to downvote.
    function downvoteContent(uint256 contentId) external whenNotPaused reputationAboveThreshold("downvoteContent") {
        require(contentItems[contentId].id == contentId, "Content not found.");
        require(contentModerationStatuses[contentId] == ModerationStatus.APPROVED, "Content is not approved yet or rejected.");

        int8 currentVote = contentVotes[contentId][msg.sender];
        require(currentVote != -1, "You have already downvoted this content.");

        if (currentVote == 1) { // User is changing from upvote to downvote
            contentItems[contentId].upvotes--;
        }
        contentItems[contentId].downvotes++;
        contentVotes[contentId][msg.sender] = -1;

        // Reputation adjustment for content author on downvote
        adjustReputation(contentItems[contentId].author, -int256(downvoteWeight)); // Negative reputation change
        emit ContentDownvoted(contentId, msg.sender);
    }

    /// @notice Retrieves the upvote and downvote count for a content item.
    /// @param contentId The ID of the content.
    /// @return Upvote count and downvote count.
    function getVoteCount(uint256 contentId) external view whenNotPaused returns (uint256 upvotes, uint256 downvotes) {
        require(contentItems[contentId].id == contentId, "Content not found.");
        return (contentItems[contentId].upvotes, contentItems[contentId].downvotes);
    }

    /// @notice Checks if a user has voted on a specific content item and their vote type.
    /// @param contentId The ID of the content.
    /// @param user The address of the user.
    /// @return The vote type: -1 for downvote, 1 for upvote, 0 for no vote.
    function getUserVote(uint256 contentId, address user) external view whenNotPaused returns (int8) {
        require(contentItems[contentId].id == contentId, "Content not found.");
        return contentVotes[contentId][user];
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address user) external view whenNotPaused returns (uint256) {
        return userReputations[user].score;
    }

    /// @notice Adjusts user reputation score (Admin/Internal function).
    /// @param user The address of the user to adjust reputation for.
    /// @param reputationChange The amount to change the reputation by (positive or negative).
    function adjustReputation(address user, int256 reputationChange) internal { // Made internal for more controlled access
        userReputations[user].score = uint256(int256(userReputations[user].score) + reputationChange);
        emit ReputationChanged(user, reputationChange, userReputations[user].score);
    }

    /// @notice Retrieves the reputation threshold required to access a specific feature.
    /// @param featureName The name of the feature.
    /// @return The reputation threshold.
    function getReputationThresholdForFeature(string memory featureName) external view whenNotPaused returns (uint256) {
        return reputationThresholds[featureName];
    }

    // -------- 3. Content Recommendation (Conceptual - AI Integration Placeholder) --------

    /// @notice (Conceptual) Placeholder for a function that would recommend content to a user based on their preferences/history (AI integration point).
    /// @param user The address of the user to get recommendations for.
    /// @return An array of recommended content IDs (currently empty placeholder).
    function getRecommendedContentForUser(address user) external view whenNotPaused returns (uint256[] memory) {
        // In a real implementation, this would integrate with an off-chain AI/ML service
        // or use some on-chain (less efficient) recommendation logic.
        // For now, it returns an empty array as a placeholder.
        return new uint256[](0);
    }

    /// @notice (Conceptual) Placeholder for allowing users to update their content preferences (for recommendation systems).
    /// @param user The address of the user.
    /// @param tags An array of tags representing user preferences.
    function updateUserPreferences(address user, string[] memory tags) external whenNotPaused {
        // In a real implementation, this would store user preferences for use in recommendation logic.
        // For now, it's a placeholder function.
        // Example: Store user preferences in a mapping or struct.
        // userPreferences[user].preferredTags = tags;
        // ... (Further logic to use these preferences)
    }

    // -------- 4. Content Moderation (Basic - Expandable) --------

    /// @notice Allows users to report content for moderation.
    /// @param contentId The ID of the content to report.
    /// @param reason The reason for reporting the content.
    function reportContent(uint256 contentId, string memory reason) external whenNotPaused reputationAboveThreshold("reportContent") {
        require(contentItems[contentId].id == contentId, "Content not found.");
        // In a more advanced system, you might want to track multiple reports, reasons, etc.
        contentModerationStatuses[contentId] = ModerationStatus.PENDING; // Set back to pending when reported again
        emit ContentReported(contentId, msg.sender, reason);
    }

    /// @notice Allows admin to moderate reported content and approve/reject it.
    /// @param contentId The ID of the content to moderate.
    /// @param isApproved True to approve, false to reject.
    function moderateContent(uint256 contentId, bool isApproved) external onlyOwner whenNotPaused {
        require(contentItems[contentId].id == contentId, "Content not found.");
        ModerationStatus newStatus = isApproved ? ModerationStatus.APPROVED : ModerationStatus.REJECTED;
        contentModerationStatuses[contentId] = newStatus;
        emit ContentModerated(contentId, newStatus, msg.sender);
    }

    /// @notice Retrieves the moderation status of a content item.
    /// @param contentId The ID of the content.
    /// @return The moderation status enum value.
    function getContentModerationStatus(uint256 contentId) external view whenNotPaused returns (ModerationStatus) {
        require(contentItems[contentId].id == contentId, "Content not found.");
        return contentModerationStatuses[contentId];
    }


    // -------- 5. Platform Settings & Admin Functions --------

    /// @notice Sets the reputation threshold for a specific feature.
    /// @param featureName The name of the feature.
    /// @param threshold The reputation threshold value.
    function setReputationThreshold(string memory featureName, uint256 threshold) external onlyOwner whenNotPaused {
        reputationThresholds[featureName] = threshold;
    }

    /// @notice Sets the weight of upvotes and downvotes on content score and reputation.
    /// @param upvoteWeightValue The weight for upvotes.
    /// @param downvoteWeightValue The weight for downvotes.
    function setVotingWeight(uint256 upvoteWeightValue, uint256 downvoteWeightValue) external onlyOwner whenNotPaused {
        require(upvoteWeightValue > 0 && downvoteWeightValue > 0, "Weights must be greater than 0.");
        upvoteWeight = upvoteWeightValue;
        downvoteWeight = downvoteWeightValue;
    }

    /// @notice Pauses the contract functionality (emergency stop).
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes the contract functionality.
    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Transfers contract ownership to a new address.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
```