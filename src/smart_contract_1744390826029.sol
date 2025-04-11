```solidity
/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Gemini AI
 * @dev A smart contract for a decentralized content platform with dynamic access control,
 * reputation-based rewards, and governance features. This contract allows users to submit content,
 * access content based on roles and reputation, participate in content curation, and govern platform parameters.
 *
 * Function Summary:
 *
 * **User & Profile Management:**
 * 1. `registerUser(string _username, string _profileHash)`: Allows users to register with a unique username and profile metadata (IPFS hash).
 * 2. `updateProfile(string _newProfileHash)`: Allows users to update their profile metadata.
 * 3. `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 * 4. `getUsername(address _userAddress)`: Retrieves a user's username.
 * 5. `setUserRole(address _userAddress, Role _role)`: (Admin/Governance) Assigns a role to a user.
 * 6. `getUserRole(address _userAddress)`: Retrieves a user's role.
 *
 * **Content Submission & Retrieval:**
 * 7. `submitContent(string _contentHash, string _metadataHash, ContentCategory _category)`: Allows users to submit content with metadata and category.
 * 8. `getContentById(uint256 _contentId)`: Retrieves content details by its ID.
 * 9. `getContentByCategory(ContentCategory _category)`: Retrieves content IDs belonging to a specific category.
 * 10. `getAllContentIds()`: Retrieves all content IDs in the platform.
 *
 * **Access Control & Reputation:**
 * 11. `setContentAccessRole(uint256 _contentId, Role _requiredRole)`: (Admin/Governance) Sets the minimum role required to access specific content.
 * 12. `getContentAccessRole(uint256 _contentId)`: Retrieves the access role required for specific content.
 * 13. `upvoteContent(uint256 _contentId)`: Allows users to upvote content, increasing the author's reputation.
 * 14. `downvoteContent(uint256 _contentId)`: Allows users to downvote content, potentially decreasing the author's reputation.
 * 15. `getUserReputation(address _userAddress)`: Retrieves a user's reputation score.
 *
 * **Governance & Platform Management:**
 * 16. `addContentCategory(string _categoryName)`: (Admin/Governance) Adds a new content category.
 * 17. `getContentCategoryName(ContentCategory _category)`: Retrieves the name of a content category.
 * 18. `setPlatformFee(uint256 _newFee)`: (Admin/Governance) Sets the platform fee percentage for content interactions (e.g., premium content access - future enhancement).
 * 19. `getPlatformFee()`: Retrieves the current platform fee percentage.
 * 20. `pauseContract()`: (Admin/Governance) Pauses core contract functionalities.
 * 21. `unpauseContract()`: (Admin/Governance) Resumes core contract functionalities.
 * 22. `withdrawPlatformFees()`: (Admin/Governance) Allows admin to withdraw accumulated platform fees.
 * 23. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 * 24. `moderateContent(uint256 _contentId, ContentStatus _newStatus)`: (Moderator/Governance) Updates content status after review.
 */
pragma solidity ^0.8.0;

contract DynamicContentPlatform {

    // Enums for roles, content categories and content status
    enum Role { VIEWER, CONTRIBUTOR, MODERATOR, ADMIN }
    enum ContentCategory { GENERAL, NEWS, EDUCATION, ART, TECHNOLOGY, ENTERTAINMENT }
    enum ContentStatus { PENDING, PUBLISHED, REJECTED, REPORTED }

    // Structs to hold user and content information
    struct UserProfile {
        string username;
        string profileHash; // IPFS hash for profile metadata
        Role role;
        uint256 reputation;
        bool exists;
    }

    struct Content {
        uint256 id;
        address author;
        string contentHash; // IPFS hash for content
        string metadataHash; // IPFS hash for content metadata
        ContentCategory category;
        ContentStatus status;
        uint256 upvotes;
        uint256 downvotes;
        Role accessRole; // Minimum role required to access this content
        bool exists;
    }

    // State variables
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Content) public contentRegistry;
    mapping(ContentCategory => string) public contentCategoryNames;
    uint256 public contentCount;
    uint256 public platformFeePercentage; // Percentage fee for platform operations
    address public platformAdmin;
    bool public paused;

    // Events
    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress, string newProfileHash);
    event RoleAssigned(address userAddress, Role role);
    event ContentSubmitted(uint256 contentId, address author, ContentCategory category);
    event ContentUpvoted(uint256 contentId, address userAddress);
    event ContentDownvoted(uint256 contentId, address userAddress);
    event ContentAccessRoleSet(uint256 contentId, Role requiredRole);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, ContentStatus newStatus);
    event ContentCategoryAdded(ContentCategory category, string categoryName);


    // Modifiers for access control
    modifier onlyAdmin() {
        require(msg.sender == platformAdmin, "Only admin can perform this action");
        _;
    }

    modifier onlyRole(Role _role) {
        require(userProfiles[msg.sender].role >= _role, "Insufficient role");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // Constructor to set admin and initial platform fee
    constructor() {
        platformAdmin = msg.sender;
        platformFeePercentage = 0; // Default to 0% fee
        paused = false;
        // Initialize default content categories
        addContentCategory("General");
        addContentCategory("News");
        addContentCategory("Education");
        addContentCategory("Art");
        addContentCategory("Technology");
        addContentCategory("Entertainment");
    }

    // --------------------------------------------------
    // User & Profile Management Functions
    // --------------------------------------------------

    function registerUser(string memory _username, string memory _profileHash) public whenNotPaused {
        require(!userProfiles[msg.sender].exists, "User already registered");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            role: Role.VIEWER, // Default role upon registration
            reputation: 0,
            exists: true
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _newProfileHash) public whenNotPaused {
        require(userProfiles[msg.sender].exists, "User not registered");
        userProfiles[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newProfileHash);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        require(userProfiles[_userAddress].exists, "User not registered");
        return userProfiles[_userAddress];
    }

    function getUsername(address _userAddress) public view returns (string memory) {
        require(userProfiles[_userAddress].exists, "User not registered");
        return userProfiles[_userAddress].username;
    }

    function setUserRole(address _userAddress, Role _role) public onlyAdmin whenNotPaused {
        require(userProfiles[_userAddress].exists, "User not registered");
        userProfiles[_userAddress].role = _role;
        emit RoleAssigned(_userAddress, _role);
    }

    function getUserRole(address _userAddress) public view returns (Role) {
        require(userProfiles[_userAddress].exists, "User not registered");
        return userProfiles[_userAddress].role;
    }

    // --------------------------------------------------
    // Content Submission & Retrieval Functions
    // --------------------------------------------------

    function submitContent(string memory _contentHash, string memory _metadataHash, ContentCategory _category) public onlyRole(Role.CONTRIBUTOR) whenNotPaused {
        contentCount++;
        contentRegistry[contentCount] = Content({
            id: contentCount,
            author: msg.sender,
            contentHash: _contentHash,
            metadataHash: _metadataHash,
            category: _category,
            status: ContentStatus.PENDING, // Initially pending status
            upvotes: 0,
            downvotes: 0,
            accessRole: Role.VIEWER, // Default access role
            exists: true
        });
        emit ContentSubmitted(contentCount, msg.sender, _category);
    }

    function getContentById(uint256 _contentId) public view returns (Content memory) {
        require(contentRegistry[_contentId].exists, "Content not found");
        require(userProfiles[msg.sender].role >= contentRegistry[_contentId].accessRole, "Insufficient role to access content");
        return contentRegistry[_contentId];
    }

    function getContentByCategory(ContentCategory _category) public view returns (uint256[] memory) {
        uint256[] memory contentIds = new uint256[](contentCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentRegistry[i].exists && contentRegistry[i].category == _category && userProfiles[msg.sender].role >= contentRegistry[i].accessRole) {
                contentIds[index] = i;
                index++;
            }
        }
        // Resize the array to remove empty slots
        uint256[] memory filteredContentIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            filteredContentIds[i] = contentIds[i];
        }
        return filteredContentIds;
    }

    function getAllContentIds() public view returns (uint256[] memory) {
        uint256[] memory contentIds = new uint256[](contentCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentRegistry[i].exists && userProfiles[msg.sender].role >= contentRegistry[i].accessRole) {
                contentIds[index] = i;
                index++;
            }
        }
         // Resize the array to remove empty slots
        uint256[] memory filteredContentIds = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            filteredContentIds[i] = contentIds[i];
        }
        return filteredContentIds;
    }

    // --------------------------------------------------
    // Access Control & Reputation Functions
    // --------------------------------------------------

    function setContentAccessRole(uint256 _contentId, Role _requiredRole) public onlyAdmin whenNotPaused {
        require(contentRegistry[_contentId].exists, "Content not found");
        contentRegistry[_contentId].accessRole = _requiredRole;
        emit ContentAccessRoleSet(_contentId, _requiredRole);
    }

    function getContentAccessRole(uint256 _contentId) public view returns (Role) {
        require(contentRegistry[_contentId].exists, "Content not found");
        return contentRegistry[_contentId].accessRole;
    }

    function upvoteContent(uint256 _contentId) public onlyRole(Role.VIEWER) whenNotPaused {
        require(contentRegistry[_contentId].exists, "Content not found");
        require(contentRegistry[_contentId].status == ContentStatus.PUBLISHED, "Content must be published to be upvoted");
        contentRegistry[_contentId].upvotes++;
        userProfiles[contentRegistry[_contentId].author].reputation++; // Increase author's reputation
        emit ContentUpvoted(_contentId, msg.sender);
    }

    function downvoteContent(uint256 _contentId) public onlyRole(Role.VIEWER) whenNotPaused {
        require(contentRegistry[_contentId].exists, "Content not found");
        require(contentRegistry[_contentId].status == ContentStatus.PUBLISHED, "Content must be published to be downvoted");
        contentRegistry[_contentId].downvotes++;
        if (userProfiles[contentRegistry[_contentId].author].reputation > 0) {
            userProfiles[contentRegistry[_contentId].author].reputation--; // Decrease author's reputation
        }
        emit ContentDownvoted(_contentId, msg.sender);
    }

    function getUserReputation(address _userAddress) public view returns (uint256) {
        require(userProfiles[_userAddress].exists, "User not registered");
        return userProfiles[_userAddress].reputation;
    }

    // --------------------------------------------------
    // Governance & Platform Management Functions
    // --------------------------------------------------

    function addContentCategory(string memory _categoryName) public onlyAdmin whenNotPaused {
        ContentCategory newCategory = ContentCategory(uint256(ContentCategory.ENTERTAINMENT) + 1); // Add new category enum value (basic approach, more robust enum handling needed in production)
        contentCategoryNames[newCategory] = _categoryName;
        emit ContentCategoryAdded(newCategory, _categoryName);
    }

    function getContentCategoryName(ContentCategory _category) public view returns (string memory) {
        return contentCategoryNames[_category];
    }


    function setPlatformFee(uint256 _newFee) public onlyAdmin whenNotPaused {
        require(_newFee <= 100, "Fee percentage cannot exceed 100");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawPlatformFees() public onlyAdmin {
        // In a real application, fee collection and withdrawal logic would be more complex,
        // potentially involving token transfers and tracking.
        // This is a placeholder for fee withdrawal functionality.
        // For simplicity, assuming fees are accumulated in the contract balance (not implemented in this example)
        payable(platformAdmin).transfer(address(this).balance);
    }

    function reportContent(uint256 _contentId, string memory _reportReason) public onlyRole(Role.VIEWER) whenNotPaused {
        require(contentRegistry[_contentId].exists, "Content not found");
        // In a real application, store reports in a more structured way (e.g., mapping of contentId to report details)
        emit ContentReported(_contentId, msg.sender, _reportReason);
        contentRegistry[_contentId].status = ContentStatus.REPORTED; // Update content status to reported
    }

    function moderateContent(uint256 _contentId, ContentStatus _newStatus) public onlyRole(Role.MODERATOR) whenNotPaused {
        require(contentRegistry[_contentId].exists, "Content not found");
        require(_newStatus != ContentStatus.PENDING, "Cannot set status back to pending via moderation");
        contentRegistry[_contentId].status = _newStatus;
        emit ContentModerated(_contentId, _newStatus);
    }
}
```