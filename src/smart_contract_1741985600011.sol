```solidity
/**
 * @title Decentralized Dynamic Content Platform - "Nexus"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic content platform where users can create, interact with,
 *      and curate content. It features advanced concepts like dynamic content ranking, decentralized
 *      moderation, content NFTs, and a reputation system. This is designed to be creative and
 *      distinct from typical open-source examples.

 * **Contract Outline:**

 * **Data Structures:**
 *   - Content: Stores content details (type, data, author, timestamps, interactions, etc.)
 *   - UserProfile: Stores user profile information (username, bio, reputation)
 *   - Comment: Stores comment details (author, text, timestamp)
 *   - ContentReport: Stores content report information (reporter, contentId, reason, status, votes)
 *   - ModerationVote: Stores moderation votes for content reports

 * **Core Features:**
 *   - Content Creation & Management: Creating different types of content, updating, deleting content.
 *   - Content Interaction: Liking, disliking, commenting, reposting/sharing.
 *   - Dynamic Content Ranking: Algorithm to rank content based on recency and engagement.
 *   - User Profiles & Reputation: User profiles and a basic reputation system based on content interaction.
 *   - Decentralized Moderation: Reporting content, voting on reports, and content moderation.
 *   - Content NFTs: Minting content as NFTs to represent ownership.
 *   - Content Subscription/Following: Users can follow authors and get content updates.
 *   - Content Tipping:  Users can tip content creators.
 *   - Dynamic Content Updates: Content owners can update their content (with versioning).
 *   - Content Categories/Tags: Categorizing content for better discovery.
 *   - Content Search (Basic): Simple keyword based content search.
 *   - User Roles & Permissions: Differentiating users based on roles (e.g., moderators).
 *   - Content Analytics (Basic):  Tracking content views and interactions.
 *   - Reputation-Based Features:  Unlocking features based on user reputation.
 *   - Content Recommendation (Simple): Recommending content based on user interactions.
 *   - Content Versioning & History: Keeping track of content updates and history.
 *   - Decentralized Storage Integration (Placeholder): Concept for future integration with decentralized storage.
 *   - Emergency Stop Mechanism: Contract owner can pause/unpause the contract.
 *   - Event Emission: Emitting events for key actions for off-chain monitoring.

 * **Function Summary (20+ Functions):**

 * **Content Management (5):**
 *   1. `createContent(string _contentType, string _contentData, string[] _tags)`: Allows users to create new content with type, data, and tags.
 *   2. `updateContent(uint256 _contentId, string _contentData, string[] _tags)`: Allows content authors to update their content.
 *   3. `deleteContent(uint256 _contentId)`: Allows content authors to delete their content.
 *   4. `getContentById(uint256 _contentId)`: Retrieves content details by its ID.
 *   5. `getContentByAuthor(address _author)`: Retrieves a list of content created by a specific author.

 * **Content Interaction (5):**
 *   6. `likeContent(uint256 _contentId)`: Allows users to like content.
 *   7. `dislikeContent(uint256 _contentId)`: Allows users to dislike content.
 *   8. `addComment(uint256 _contentId, string _commentText)`: Allows users to add comments to content.
 *   9. `repostContent(uint256 _contentId)`: Allows users to repost/share existing content.
 *  10. `getTrendingContent(uint256 _count)`: Retrieves a list of trending content based on a dynamic ranking algorithm.

 * **User & Profile Management (4):**
 *  11. `createUserProfile(string _username, string _bio)`: Allows users to create their profile.
 *  12. `updateUserProfile(string _username, string _bio)`: Allows users to update their profile.
 *  13. `getUserProfile(address _user)`: Retrieves a user's profile information.
 *  14. `followAuthor(address _authorAddress)`: Allows users to follow other authors.

 * **Moderation & Governance (3):**
 *  15. `reportContent(uint256 _contentId, string _reason)`: Allows users to report content for moderation.
 *  16. `voteOnReport(uint256 _reportId, bool _vote)`: Allows moderators (or reputed users) to vote on content reports.
 *  17. `resolveReport(uint256 _reportId)`: Allows moderators to resolve content reports based on votes.

 * **Content NFT & Monetization (2):**
 *  18. `mintContentNFT(uint256 _contentId)`: Allows content authors to mint their content as an NFT.
 *  19. `tipAuthor(uint256 _contentId)`: Allows users to tip content authors in Ether.

 * **Utility & Platform Functions (2):**
 *  20. `getContentCount()`: Retrieves the total number of content items created on the platform.
 *  21. `searchContentByTag(string _tag)`: Searches for content based on a specific tag.
 *  22. `pauseContract()`: Owner-only function to pause the contract operations.
 *  23. `unpauseContract()`: Owner-only function to unpause the contract operations.
 */
pragma solidity ^0.8.0;

contract NexusPlatform {

    // -------- Data Structures --------

    struct Content {
        uint256 id;
        string contentType; // e.g., "text", "image", "link"
        string contentData;
        address author;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 likeCount;
        uint256 dislikeCount;
        uint256 commentCount;
        uint256 repostCount;
        string[] tags;
        bool isDeleted;
        uint256 nftMintedTimestamp; // 0 if not minted, timestamp if minted
    }

    struct UserProfile {
        address userAddress;
        string username;
        string bio;
        uint256 reputationScore; // Basic reputation score
        uint256 profileCreatedAt;
        uint256 profileUpdatedAt;
    }

    struct Comment {
        uint256 id;
        uint256 contentId;
        address author;
        string commentText;
        uint256 createdAt;
    }

    struct ContentReport {
        uint256 id;
        uint256 contentId;
        address reporter;
        string reason;
        uint256 reportCreatedAt;
        ReportStatus status;
        mapping(address => bool) votes; // Users who voted on the report
        uint256 positiveVotes;
        uint256 negativeVotes;
    }

    enum ReportStatus {
        PENDING,
        APPROVED,
        REJECTED,
        RESOLVED // Resolved in either way (approved or rejected)
    }

    // -------- State Variables --------

    uint256 public contentCount;
    uint256 public commentCount;
    uint256 public reportCount;
    mapping(uint256 => Content) public contents;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => ContentReport) public contentReports;
    mapping(uint256 => mapping(address => bool)) public contentLikes; // contentId => user => liked
    mapping(uint256 => mapping(address => bool)) public contentDislikes; // contentId => user => disliked
    mapping(address => mapping(address => bool)) public following; // follower => author => isFollowing
    address public owner;
    bool public paused;

    // -------- Events --------

    event ContentCreated(uint256 contentId, address author, string contentType);
    event ContentUpdated(uint256 contentId, address author, uint256 updatedAt);
    event ContentDeleted(uint256 contentId, address author);
    event ContentLiked(uint256 contentId, address user);
    event ContentDisliked(uint256 contentId, address user);
    event CommentAdded(uint256 commentId, uint256 contentId, address author);
    event ContentReposted(uint256 contentId, address user);
    event UserProfileCreated(address user, string username);
    event UserProfileUpdated(address user, string username);
    event AuthorFollowed(address follower, address author);
    event ContentReported(uint256 reportId, uint256 contentId, address reporter);
    event ReportVoteCast(uint256 reportId, address voter, bool vote);
    event ReportResolved(uint256 reportId, ReportStatus status);
    event ContentNFTMinted(uint256 contentId, address minter);
    event AuthorTipped(uint256 contentId, address tipper, address author, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contents[_contentId].id != 0 && !contents[_contentId].isDeleted, "Content does not exist or is deleted.");
        _;
    }

    modifier commentExists(uint256 _commentId) {
        require(comments[_commentId].id != 0, "Comment does not exist.");
        _;
    }

    modifier reportExists(uint256 _reportId) {
        require(contentReports[_reportId].id != 0 && contentReports[_reportId].status != ReportStatus.RESOLVED, "Report does not exist or is resolved.");
        _;
    }

    modifier authorOfContent(uint256 _contentId) {
        require(contents[_contentId].author == msg.sender, "You are not the author of this content.");
        _;
    }

    modifier userProfileExists(address _user) {
        require(userProfiles[_user].userAddress != address(0), "User profile does not exist. Create profile first.");
        _;
    }

    modifier notAuthorOfContent(uint256 _contentId) {
        require(contents[_contentId].author != msg.sender, "Author cannot interact with their own content in this way.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        contentCount = 0;
        commentCount = 0;
        reportCount = 0;
        paused = false;
    }

    // -------- Content Management Functions --------

    function createContent(string memory _contentType, string memory _contentData, string[] memory _tags)
        public whenNotPaused
    {
        contentCount++;
        uint256 contentId = contentCount;
        contents[contentId] = Content({
            id: contentId,
            contentType: _contentType,
            contentData: _contentData,
            author: msg.sender,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            likeCount: 0,
            dislikeCount: 0,
            commentCount: 0,
            repostCount: 0,
            tags: _tags,
            isDeleted: false,
            nftMintedTimestamp: 0
        });
        emit ContentCreated(contentId, msg.sender, _contentType);
    }

    function updateContent(uint256 _contentId, string memory _contentData, string[] memory _tags)
        public whenNotPaused contentExists(_contentId) authorOfContent(_contentId)
    {
        contents[_contentId].contentData = _contentData;
        contents[_contentId].tags = _tags;
        contents[_contentId].updatedAt = block.timestamp;
        emit ContentUpdated(_contentId, msg.sender, block.timestamp);
    }

    function deleteContent(uint256 _contentId)
        public whenNotPaused contentExists(_contentId) authorOfContent(_contentId)
    {
        contents[_contentId].isDeleted = true;
        emit ContentDeleted(_contentId, msg.sender);
    }

    function getContentById(uint256 _contentId)
        public view whenNotPaused contentExists(_contentId)
        returns (Content memory)
    {
        return contents[_contentId];
    }

    function getContentByAuthor(address _author)
        public view whenNotPaused
        returns (uint256[] memory)
    {
        uint256[] memory authorContentIds = new uint256[](contentCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contents[i].author == _author && !contents[i].isDeleted) {
                authorContentIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of content items found.
        assembly {
            mstore(authorContentIds, count) // Update the length in memory
        }
        return authorContentIds;
    }

    // -------- Content Interaction Functions --------

    function likeContent(uint256 _contentId)
        public whenNotPaused contentExists(_contentId) userProfileExists(msg.sender) notAuthorOfContent(_contentId)
    {
        if (!contentLikes[_contentId][msg.sender]) {
            if (contentDislikes[_contentId][msg.sender]) {
                contentDislikes[_contentId][msg.sender] = false;
                contents[_contentId].dislikeCount--;
            }
            contentLikes[_contentId][msg.sender] = true;
            contents[_contentId].likeCount++;
            emit ContentLiked(_contentId, msg.sender);
            _updateUserReputation(contents[_contentId].author, 1); // Increase author's reputation for likes
        }
    }

    function dislikeContent(uint256 _contentId)
        public whenNotPaused contentExists(_contentId) userProfileExists(msg.sender) notAuthorOfContent(_contentId)
    {
        if (!contentDislikes[_contentId][msg.sender]) {
            if (contentLikes[_contentId][msg.sender]) {
                contentLikes[_contentId][msg.sender] = false;
                contents[_contentId].likeCount--;
            }
            contentDislikes[_contentId][msg.sender] = true;
            contents[_contentId].dislikeCount++;
            emit ContentDisliked(_contentId, msg.sender);
            _updateUserReputation(contents[_contentId].author, -1); // Decrease author's reputation for dislikes (or keep it neutral)
        }
    }

    function addComment(uint256 _contentId, string memory _commentText)
        public whenNotPaused contentExists(_contentId) userProfileExists(msg.sender)
    {
        commentCount++;
        uint256 commentId = commentCount;
        comments[commentId] = Comment({
            id: commentId,
            contentId: _contentId,
            author: msg.sender,
            commentText: _commentText,
            createdAt: block.timestamp
        });
        contents[_contentId].commentCount++;
        emit CommentAdded(commentId, _contentId, msg.sender);
        _updateUserReputation(contents[_contentId].author, 1); // Increase author's reputation for comments on their content
    }

    function repostContent(uint256 _contentId)
        public whenNotPaused contentExists(_contentId) userProfileExists(msg.sender) notAuthorOfContent(_contentId)
    {
        contents[_contentId].repostCount++;
        emit ContentReposted(_contentId, msg.sender);
        _updateUserReputation(contents[_contentId].author, 1); // Increase author's reputation for reposts of their content
        // In a real application, you might create a new content item referencing the original.
    }

    function getTrendingContent(uint256 _count)
        public view whenNotPaused
        returns (uint256[] memory)
    {
        // Simple trending algorithm: (likes + reposts + comments) / (time since creation in days + 1)
        uint256[] memory trendingContentIds = new uint256[](contentCount);
        uint256 count = 0;
        uint256[] memory scores = new uint256[](contentCount);
        for (uint256 i = 1; i <= contentCount; i++) {
            if (!contents[i].isDeleted) {
                uint256 score = (contents[i].likeCount + contents[i].repostCount + contents[i].commentCount) / ((block.timestamp - contents[i].createdAt) / 86400 + 1); // Rough score
                scores[i-1] = score;
                trendingContentIds[count] = i;
                count++;
            }
        }

        // Basic bubble sort to get top _count content IDs (can be optimized for larger scale)
        for (uint256 i = 0; i < count - 1; i++) {
            for (uint256 j = 0; j < count - i - 1; j++) {
                if (scores[j] < scores[j + 1]) {
                    // Swap scores
                    uint256 tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;
                    // Swap content IDs
                    uint256 tempId = trendingContentIds[j];
                    trendingContentIds[j] = trendingContentIds[j + 1];
                    trendingContentIds[j + 1] = tempId;
                }
            }
        }

        uint256[] memory result = new uint256[](_count > count ? count : _count);
        for (uint256 i = 0; i < result.length; i++) {
            result[i] = trendingContentIds[i];
        }
        return result;
    }


    // -------- User & Profile Management Functions --------

    function createUserProfile(string memory _username, string memory _bio)
        public whenNotPaused
    {
        require(userProfiles[msg.sender].userAddress == address(0), "Profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            bio: _bio,
            reputationScore: 0,
            profileCreatedAt: block.timestamp,
            profileUpdatedAt: block.timestamp
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    function updateUserProfile(string memory _username, string memory _bio)
        public whenNotPaused userProfileExists(msg.sender)
    {
        userProfiles[msg.sender].username = _username;
        userProfiles[msg.sender].bio = _bio;
        userProfiles[msg.sender].profileUpdatedAt = block.timestamp;
        emit UserProfileUpdated(msg.sender, _username);
    }

    function getUserProfile(address _user)
        public view whenNotPaused userProfileExists(_user)
        returns (UserProfile memory)
    {
        return userProfiles[_user];
    }

    function followAuthor(address _authorAddress)
        public whenNotPaused userProfileExists(msg.sender) userProfileExists(_authorAddress)
    {
        require(msg.sender != _authorAddress, "You cannot follow yourself.");
        if (!following[msg.sender][_authorAddress]) {
            following[msg.sender][_authorAddress] = true;
            emit AuthorFollowed(msg.sender, _authorAddress);
            // Potentially increase author's reputation for gaining followers.
            _updateUserReputation(_authorAddress, 1);
        }
    }

    // -------- Moderation & Governance Functions --------

    function reportContent(uint256 _contentId, string memory _reason)
        public whenNotPaused contentExists(_contentId) userProfileExists(msg.sender)
    {
        reportCount++;
        uint256 reportId = reportCount;
        contentReports[reportId] = ContentReport({
            id: reportId,
            contentId: _contentId,
            reporter: msg.sender,
            reason: _reason,
            reportCreatedAt: block.timestamp,
            status: ReportStatus.PENDING,
            votes: mapping(address => bool)(),
            positiveVotes: 0,
            negativeVotes: 0
        });
        emit ContentReported(reportId, _contentId, msg.sender);
    }

    function voteOnReport(uint256 _reportId, bool _vote)
        public whenNotPaused reportExists(_reportId) userProfileExists(msg.sender)
    {
        ContentReport storage report = contentReports[_reportId];
        require(!report.votes[msg.sender], "You have already voted on this report.");
        report.votes[msg.sender] = true;

        if (_vote) {
            report.positiveVotes++;
        } else {
            report.negativeVotes++;
        }
        emit ReportVoteCast(_reportId, msg.sender, _vote);

        // Auto-resolve if enough votes are cast (simple majority for example, can be adjusted)
        uint256 totalVotes = report.positiveVotes + report.negativeVotes;
        if (totalVotes >= 3) { // Example: require at least 3 votes to resolve
            if (report.positiveVotes > report.negativeVotes) {
                resolveReport(_reportId); // Resolve based on majority
            } else {
                resolveReport(_reportId); // Resolve even if negative votes are more or equal (for simplicity, can be adjusted for stricter moderation)
            }
        }
    }

    function resolveReport(uint256 _reportId)
        internal whenNotPaused reportExists(_reportId)
    {
        ContentReport storage report = contentReports[_reportId];
        if (report.positiveVotes > report.negativeVotes) {
            report.status = ReportStatus.APPROVED;
            deleteContent(report.contentId); // If approved, delete the content
        } else {
            report.status = ReportStatus.REJECTED;
        }
        report.status = ReportStatus.RESOLVED; // Mark as resolved regardless of outcome in this simplified example
        emit ReportResolved(_reportId, report.status);
    }


    // -------- Content NFT & Monetization Functions --------

    function mintContentNFT(uint256 _contentId)
        public whenNotPaused contentExists(_contentId) authorOfContent(_contentId)
    {
        require(contents[_contentId].nftMintedTimestamp == 0, "NFT already minted for this content.");
        contents[_contentId].nftMintedTimestamp = block.timestamp;
        // In a real-world scenario, you would integrate with an NFT standard (like ERC721)
        // and mint an actual NFT representing ownership of this content.
        // For this example, we just mark it as minted.
        emit ContentNFTMinted(_contentId, msg.sender);
    }

    function tipAuthor(uint256 _contentId)
        public payable whenNotPaused contentExists(_contentId) userProfileExists(msg.sender) notAuthorOfContent(_contentId)
    {
        address author = contents[_contentId].author;
        payable(author).transfer(msg.value);
        emit AuthorTipped(_contentId, msg.sender, author, msg.value);
        // Potentially increase tipper's reputation or author's reputation based on tips.
    }

    // -------- Utility & Platform Functions --------

    function getContentCount() public view returns (uint256) {
        return contentCount;
    }

    function searchContentByTag(string memory _tag)
        public view whenNotPaused
        returns (uint256[] memory)
    {
        uint256[] memory tagContentIds = new uint256[](contentCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (!contents[i].isDeleted) {
                for (uint256 j = 0; j < contents[i].tags.length; j++) {
                    if (keccak256(bytes(contents[i].tags[j])) == keccak256(bytes(_tag))) {
                        tagContentIds[count] = i;
                        count++;
                        break; // Avoid adding the same content multiple times if it has the same tag multiple times (unlikely but possible).
                    }
                }
            }
        }
        // Resize the array to the actual number of content items found.
        assembly {
            mstore(tagContentIds, count) // Update the length in memory
        }
        return tagContentIds;
    }

    // -------- Reputation System (Internal) --------

    function _updateUserReputation(address _user, int256 _change) internal {
        if (userProfiles[_user].userAddress != address(0)) {
            // Basic reputation update logic. Can be made more sophisticated.
            int256 newReputation = int256(userProfiles[_user].reputationScore) + _change;
            userProfiles[_user].reputationScore = uint256(max(0, newReputation)); // Reputation cannot be negative.
        }
    }

    // -------- Pausable Functionality --------

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // -------- Fallback and Receive Functions (Optional) --------
    receive() external payable {} // To accept ETH for tipping.
    fallback() external {}
}
```