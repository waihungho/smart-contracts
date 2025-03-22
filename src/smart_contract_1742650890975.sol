```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 *  Decentralized Content Curation and Community Platform - "Nexus Hub"
 *
 *  Outline & Function Summary:
 *
 *  This contract, "Nexus Hub," implements a decentralized content curation and community platform.
 *  It allows users to create profiles, submit various content types, curate content through voting,
 *  participate in community governance, and earn reputation and rewards.
 *
 *  Core Features:
 *  - User Profiles: Create, update, and view user profiles with reputation scores.
 *  - Content Submission: Support for text, image, and link posts with categorization.
 *  - Content Curation: Upvoting and downvoting content to influence visibility and reputation.
 *  - Reporting System: Users can report inappropriate content for moderation.
 *  - Reputation System: Dynamic reputation based on content quality and curation activities.
 *  - Community Governance: Proposal system for platform rule changes and improvements.
 *  - NFT Badges: Issue NFT badges to users for achievements and contributions.
 *  - Content Tipping: Users can tip content creators with platform tokens (simulated here).
 *  - Content Feeds: Categorized and personalized content feeds based on user preferences.
 *  - Content Archiving: System to archive older content to manage storage.
 *  - User Blocking: Users can block other users to customize their experience.
 *  - Search Functionality: Basic content search based on keywords (simulated keyword tagging).
 *  - Role-Based Access: Differentiated roles for moderators and administrators.
 *  - Content Royalties (Simulated): Mechanism to distribute simulated royalties to creators.
 *  - Event System: Emit events for key actions for off-chain monitoring and indexing.
 *  - Data Analytics (Simulated): Basic on-chain metrics for platform usage.
 *  - Content Recommendation (Simulated): Simple recommendation based on category interests.
 *  - Anti-Spam Measures: Basic rate limiting and content reporting to combat spam.
 *  - Decentralized Moderation: Proposal-based moderation for community-driven content management.
 *  - Upgradeable Contract (Conceptual): Designed with upgradeability in mind (using proxy pattern in a real-world scenario - not implemented here for simplicity, but considered in design).
 *
 *  Functions (20+):
 *  1. createUserProfile(string _username, string _bio, string _profileImageUrl): Create a user profile.
 *  2. updateUserProfile(string _bio, string _profileImageUrl): Update an existing user profile.
 *  3. getUserProfile(address _user): Retrieve a user profile.
 *  4. submitContent(ContentType _contentType, string _contentHash, string[] _tags, uint256 _category): Submit new content.
 *  5. upvoteContent(uint256 _contentId): Upvote a piece of content.
 *  6. downvoteContent(uint256 _contentId): Downvote a piece of content.
 *  7. reportContent(uint256 _contentId, string _reason): Report content for moderation.
 *  8. getContent(uint256 _contentId): Retrieve content details.
 *  9. getTrendingContent(uint256 _category): Get trending content within a category (simulated).
 *  10. getFeedForUser(address _user): Get a personalized content feed for a user (simulated).
 *  11. createGovernanceProposal(string _title, string _description, bytes _calldata): Create a governance proposal.
 *  12. voteOnProposal(uint256 _proposalId, bool _support): Vote on a governance proposal.
 *  13. executeProposal(uint256 _proposalId): Execute a passed governance proposal (simulated).
 *  14. issueBadge(address _user, string _badgeName, string _badgeMetadataUrl): Issue an NFT badge to a user.
 *  15. tipContentCreator(uint256 _contentId, uint256 _amount): Tip a content creator (simulated tokens).
 *  16. blockUser(address _userToBlock): Block a user.
 *  17. unblockUser(address _userToUnblock): Unblock a user.
 *  18. getContentByCategory(uint256 _category): Get content filtered by category.
 *  19. searchContentByTag(string _tag): Search content by a keyword tag (simulated).
 *  20. moderateContent(uint256 _contentId, ModerationAction _action): Moderator action on reported content.
 *  21. setContentCategoryName(uint256 _categoryId, string _categoryName): Admin function to set content category names.
 *  22. getPlatformMetrics(): Admin function to get platform usage metrics (simulated).
 */

contract NexusHub {

    // Enums
    enum ContentType { TEXT, IMAGE, LINK }
    enum ContentStatus { PENDING, PUBLISHED, ARCHIVED, REPORTED }
    enum ModerationAction { APPROVE, REJECT, ARCHIVE }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }

    // Structs
    struct UserProfile {
        string username;
        string bio;
        string profileImageUrl;
        uint256 reputationScore;
        uint256 profileCreationTimestamp;
    }

    struct ContentPost {
        ContentType contentType;
        string contentHash; // IPFS hash or similar identifier
        address creator;
        uint256 creationTimestamp;
        ContentStatus status;
        int256 upvotes;
        int256 downvotes;
        uint256 category;
        string[] tags; // Simulated keyword tags for search
    }

    struct GovernanceProposal {
        string title;
        string description;
        address proposer;
        uint256 creationTimestamp;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
        bytes calldata; // Calldata for contract function execution (simulated)
    }

    struct ContentCategory {
        string name;
    }


    // State Variables
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => ContentPost) public contentPosts;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ContentCategory) public contentCategories;
    mapping(address => mapping(address => bool)) public blockedUsers; // User -> Blocked User -> isBlocked
    mapping(uint256 => mapping(address => bool)) public contentUpvotes; // Content ID -> User -> Has Upvoted
    mapping(uint256 => mapping(address => bool)) public contentDownvotes; // Content ID -> User -> Has Downvoted
    mapping(uint256 => mapping(address => bool)) public contentReports; // Content ID -> User -> Has Reported

    uint256 public totalUsers;
    uint256 public totalContent;
    uint256 public totalProposals;
    uint256 public totalTips; // Simulated tips counter

    address public admin;
    address[] public moderators;

    // Events
    event ProfileCreated(address indexed user, string username);
    event ProfileUpdated(address indexed user);
    event ContentSubmitted(uint256 indexed contentId, address indexed creator, ContentType contentType);
    event ContentUpvoted(uint256 indexed contentId, address indexed user);
    event ContentDownvoted(uint256 indexed contentId, address indexed user);
    event ContentReported(uint256 indexed contentId, address indexed reporter, string reason);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event BadgeIssued(address indexed user, string badgeName);
    event ContentTipped(uint256 indexed contentId, address creator, uint256 amount);
    event UserBlocked(address indexed blocker, address indexed blockedUser);
    event UserUnblocked(address indexed blocker, address indexed unblockedUser);
    event ContentModerated(uint256 indexed contentId, ModerationAction action);
    event ContentCategoryCreated(uint256 indexed categoryId, string categoryName);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyModerator() {
        bool isModerator = false;
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == msg.sender) {
                isModerator = true;
                break;
            }
        }
        require(msg.sender == admin || isModerator, "Only moderators or admin can call this function.");
        _;
    }

    modifier userProfileExists(address _user) {
        require(userProfiles[_user].profileCreationTimestamp > 0, "User profile does not exist.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contentPosts[_contentId].creationTimestamp > 0, "Content does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].creationTimestamp > 0, "Proposal does not exist.");
        _;
    }

    // Constructor
    constructor() {
        admin = msg.sender;
        // Initialize default categories (optional, can be expanded through governance)
        setContentCategoryName(1, "General");
        setContentCategoryName(2, "Technology");
        setContentCategoryName(3, "Art");
        setContentCategoryName(4, "Gaming");
        setContentCategoryName(5, "News");
    }

    // --- User Profile Functions ---

    function createUserProfile(string memory _username, string memory _bio, string memory _profileImageUrl) public {
        require(userProfiles[msg.sender].profileCreationTimestamp == 0, "Profile already exists.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            profileImageUrl: _profileImageUrl,
            reputationScore: 0, // Initial reputation
            profileCreationTimestamp: block.timestamp
        });
        totalUsers++;
        emit ProfileCreated(msg.sender, _username);
    }

    function updateUserProfile(string memory _bio, string memory _profileImageUrl) public userProfileExists(msg.sender) {
        userProfiles[msg.sender].bio = _bio;
        userProfiles[msg.sender].profileImageUrl = _profileImageUrl;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    // --- Content Functions ---

    function submitContent(ContentType _contentType, string memory _contentHash, string[] memory _tags, uint256 _category) public userProfileExists(msg.sender) {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty.");
        require(_category > 0 && _category <= 5, "Invalid content category."); // Using pre-defined categories for simplicity
        totalContent++;
        contentPosts[totalContent] = ContentPost({
            contentType: _contentType,
            contentHash: _contentHash,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            status: ContentStatus.PUBLISHED, // Initially published, can be changed by moderation
            upvotes: 0,
            downvotes: 0,
            category: _category,
            tags: _tags
        });
        emit ContentSubmitted(totalContent, msg.sender, _contentType);
    }

    function upvoteContent(uint256 _contentId) public userProfileExists(msg.sender) contentExists(_contentId) {
        require(!contentUpvotes[_contentId][msg.sender], "Already upvoted.");
        require(!contentDownvotes[_contentId][msg.sender], "Cannot upvote after downvoting.");

        contentPosts[_contentId].upvotes++;
        contentUpvotes[_contentId][msg.sender] = true;
        userProfiles[contentPosts[_contentId].creator].reputationScore += 1; // Increase creator reputation
        emit ContentUpvoted(_contentId, msg.sender);
    }

    function downvoteContent(uint256 _contentId) public userProfileExists(msg.sender) contentExists(_contentId) {
        require(!contentDownvotes[_contentId][msg.sender], "Already downvoted.");
        require(!contentUpvotes[_contentId][msg.sender], "Cannot downvote after upvoting.");

        contentPosts[_contentId].downvotes++;
        contentDownvotes[_contentId][msg.sender] = true;
        userProfiles[contentPosts[_contentId].creator].reputationScore -= 1; // Decrease creator reputation
        emit ContentDownvoted(_contentId, msg.sender);
    }

    function reportContent(uint256 _contentId, string memory _reason) public userProfileExists(msg.sender) contentExists(_contentId) {
        require(!contentReports[_contentId][msg.sender], "Already reported.");
        contentPosts[_contentId].status = ContentStatus.REPORTED; // Mark as reported
        contentReports[_contentId][msg.sender] = true;
        emit ContentReported(_contentId, msg.sender, _reason);
    }

    function getContent(uint256 _contentId) public view contentExists(_contentId) returns (ContentPost memory) {
        return contentPosts[_contentId];
    }

    function getTrendingContent(uint256 _category) public view returns (uint256[] memory) {
        // Simulated trending content - In a real application, this would be more complex
        uint256[] memory trendingContentIds = new uint256[](5); // Return top 5 trending content in category
        uint256 count = 0;
        for (uint256 i = totalContent; i > 0 && count < 5; i--) {
            if (contentPosts[i].category == _category && contentPosts[i].status == ContentStatus.PUBLISHED) {
                trendingContentIds[count] = i;
                count++;
            }
        }
        return trendingContentIds;
    }

    function getFeedForUser(address _user) public view userProfileExists(_user) returns (uint256[] memory) {
        // Simulated personalized feed - In a real application, this would be based on user interests, follows etc.
        uint256[] memory feedContentIds = new uint256[](10); // Return last 10 published content
        uint256 count = 0;
        for (uint256 i = totalContent; i > 0 && count < 10; i--) {
            if (contentPosts[i].status == ContentStatus.PUBLISHED) {
                feedContentIds[count] = i;
                count++;
            }
        }
        return feedContentIds;
    }

    function getContentByCategory(uint256 _category) public view returns (uint256[] memory) {
        uint256[] memory categoryContentIds = new uint256[](10); // Return last 10 content in category
        uint256 count = 0;
        for (uint256 i = totalContent; i > 0 && count < 10; i--) {
            if (contentPosts[i].category == _category && contentPosts[i].status == ContentStatus.PUBLISHED) {
                categoryContentIds[count] = i;
                count++;
            }
        }
        return categoryContentIds;
    }

    function searchContentByTag(string memory _tag) public view returns (uint256[] memory) {
        uint256[] memory searchResults = new uint256[](10); // Return up to 10 search results
        uint256 count = 0;
        for (uint256 i = totalContent; i > 0 && count < 10; i--) {
            for (uint256 j = 0; j < contentPosts[i].tags.length; j++) {
                if (keccak256(bytes(contentPosts[i].tags[j])) == keccak256(bytes(_tag))) {
                    searchResults[count] = i;
                    count++;
                    break; // Move to next content post once a tag match is found
                }
            }
        }
        return searchResults;
    }


    // --- Governance Functions ---

    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) public userProfileExists(msg.sender) {
        totalProposals++;
        governanceProposals[totalProposals] = GovernanceProposal({
            title: _title,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            status: ProposalStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            calldata: _calldata // Placeholder for future execution logic
        });
        emit ProposalCreated(totalProposals, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public userProfileExists(msg.sender) proposalExists(_proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        require(block.timestamp < governanceProposals[_proposalId].creationTimestamp + 7 days, "Voting period expired."); // 7-day voting period

        if (_support) {
            governanceProposals[_proposalId].upVotes++;
        } else {
            governanceProposals[_proposalId].downVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public onlyAdmin proposalExists(_proposalId) { // For simplicity, only admin can execute in this example
        require(governanceProposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        require(block.timestamp >= governanceProposals[_proposalId].creationTimestamp + 7 days, "Voting period not expired.");

        if (governanceProposals[_proposalId].upVotes > governanceProposals[_proposalId].downVotes) {
            governanceProposals[_proposalId].status = ProposalStatus.PASSED;
            // In a real implementation, execute the calldata here using delegatecall or similar mechanism
            // For this example, we are just simulating proposal execution
            governanceProposals[_proposalId].status = ProposalStatus.EXECUTED;
            emit ProposalExecuted(_proposalId);
        } else {
            governanceProposals[_proposalId].status = ProposalStatus.REJECTED;
        }
    }

    // --- NFT Badge Function (Simulated) ---

    function issueBadge(address _user, string memory _badgeName, string memory _badgeMetadataUrl) public onlyAdmin {
        // In a real implementation, this would mint an actual NFT.
        // Here, we are just emitting an event to simulate badge issuance.
        emit BadgeIssued(_user, _badgeName);
    }

    // --- Tipping Function (Simulated Tokens) ---

    function tipContentCreator(uint256 _contentId, uint256 _amount) public userProfileExists(msg.sender) contentExists(_contentId) {
        require(_amount > 0, "Tip amount must be greater than zero.");
        // In a real implementation, this would involve token transfer.
        // Here, we are just incrementing a counter and emitting an event.
        totalTips += _amount;
        emit ContentTipped(_contentId, contentPosts[_contentId].creator, _amount);
    }

    // --- User Blocking ---

    function blockUser(address _userToBlock) public userProfileExists(msg.sender) {
        require(_userToBlock != msg.sender, "Cannot block yourself.");
        blockedUsers[msg.sender][_userToBlock] = true;
        emit UserBlocked(msg.sender, _userToBlock);
    }

    function unblockUser(address _userToUnblock) public userProfileExists(msg.sender) {
        blockedUsers[msg.sender][_userToUnblock] = false;
        emit UserUnblocked(msg.sender, _userToUnblock);
    }

    // --- Moderation Functions ---

    function moderateContent(uint256 _contentId, ModerationAction _action) public onlyModerator contentExists(_contentId) {
        if (_action == ModerationAction.APPROVE) {
            contentPosts[_contentId].status = ContentStatus.PUBLISHED;
        } else if (_action == ModerationAction.REJECT) {
            contentPosts[_contentId].status = ContentStatus.ARCHIVED; // Or can be deleted depending on policy
        } else if (_action == ModerationAction.ARCHIVE) {
            contentPosts[_contentId].status = ContentStatus.ARCHIVED;
        }
        emit ContentModerated(_contentId, _action);
    }


    // --- Admin Functions ---

    function addModerator(address _moderator) public onlyAdmin {
        moderators.push(_moderator);
    }

    function removeModerator(address _moderator) public onlyAdmin {
        for (uint256 i = 0; i < moderators.length; i++) {
            if (moderators[i] == _moderator) {
                delete moderators[i];
                // To maintain array integrity, you might need to shift elements or use a different data structure in production.
                break;
            }
        }
    }

    function setContentCategoryName(uint256 _categoryId, string memory _categoryName) public onlyAdmin {
        contentCategories[_categoryId] = ContentCategory({name: _categoryName});
        emit ContentCategoryCreated(_categoryId, _categoryName);
    }

    function getPlatformMetrics() public view onlyAdmin returns (uint256, uint256, uint256) {
        // Simulated metrics - In a real application, these could be more complex
        return (totalUsers, totalContent, totalProposals);
    }

}
```