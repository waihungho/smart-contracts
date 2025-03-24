```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Social Graph Contract
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a decentralized reputation and social graph system.
 *
 * **Outline:**
 * 1. **User Profile Management:**
 *    - `registerUser`: Allows users to register with a unique username.
 *    - `updateProfileBio`: Allows users to update their profile bio.
 *    - `getUserProfile`: Retrieves a user's profile information.
 *
 * 2. **Social Graph (Following/Followers):**
 *    - `followUser`: Allows a user to follow another user.
 *    - `unfollowUser`: Allows a user to unfollow another user.
 *    - `getFollowersCount`: Retrieves the number of followers a user has.
 *    - `getFollowingCount`: Retrieves the number of users a user is following.
 *    - `isFollowing`: Checks if user A is following user B.
 *    - `getFollowersList`: Retrieves a list of followers for a user (paginated).
 *    - `getFollowingList`: Retrieves a list of users being followed by a user (paginated).
 *
 * 3. **Reputation System (Basic - Upvotes/Downvotes):**
 *    - `upvoteUser`: Allows a registered user to upvote another user.
 *    - `downvoteUser`: Allows a registered user to downvote another user.
 *    - `getUserReputation`: Retrieves a user's reputation score.
 *    - `getVoteCount`: Retrieves the total number of votes (upvotes - downvotes) a user has received.
 *    - `resetUserReputation`: (Admin only) Resets a user's reputation score.
 *
 * 4. **Content Moderation (Decentralized - Reporting):**
 *    - `reportUser`: Allows users to report another user for inappropriate behavior.
 *    - `getReportCount`: Retrieves the number of reports a user has received.
 *    - `moderateUser`: (Admin only) Action to take on a user based on reports (e.g., reduce reputation, temporary ban - example only).
 *    - `clearUserReports`: (Admin only) Clears report count for a user.
 *
 * 5. **Utility and Admin Functions:**
 *    - `getUsername`: Retrieves the username associated with an address.
 *    - `getUserId`: Retrieves the user ID (address) associated with a username.
 *    - `isAdmin`: Checks if an address is an admin.
 *    - `setAdmin`: (Owner only) Sets an address as an admin.
 *    - `renounceAdmin`: (Admin only) Removes admin privileges from an address.
 *
 * **Function Summary:**
 *
 * **User Profile Management:**
 * - `registerUser(string _username, string _bio)`: Registers a new user with a unique username and bio.
 * - `updateProfileBio(string _newBio)`: Updates the bio of the calling user.
 * - `getUserProfile(address _userAddress)`: Returns the profile information (username, bio, registration timestamp) of a given user.
 *
 * **Social Graph (Following/Followers):**
 * - `followUser(address _userToFollow)`: Allows the caller to follow another registered user.
 * - `unfollowUser(address _userToUnfollow)`: Allows the caller to unfollow another user they are following.
 * - `getFollowersCount(address _userAddress)`: Returns the number of followers a user has.
 * - `getFollowingCount(address _userAddress)`: Returns the number of users a user is following.
 * - `isFollowing(address _follower, address _followed)`: Checks if `_follower` is following `_followed`.
 * - `getFollowersList(address _userAddress, uint256 _startIndex, uint256 _count)`: Returns a paginated list of followers for `_userAddress`.
 * - `getFollowingList(address _userAddress, uint256 _startIndex, uint256 _count)`: Returns a paginated list of users followed by `_userAddress`.
 *
 * **Reputation System (Basic Upvotes/Downvotes):**
 * - `upvoteUser(address _userToUpvote)`: Allows a registered user to upvote another user, increasing their reputation.
 * - `downvoteUser(address _userToDownvote)`: Allows a registered user to downvote another user, decreasing their reputation.
 * - `getUserReputation(address _userAddress)`: Returns the reputation score of a user.
 * - `getVoteCount(address _userAddress)`: Returns the net vote count (upvotes - downvotes) for a user.
 * - `resetUserReputation(address _userAddress)`: (Admin function) Resets the reputation of a user to the initial value.
 *
 * **Content Moderation (Decentralized Reporting):**
 * - `reportUser(address _userToReport, string _reason)`: Allows registered users to report another user for a specific reason.
 * - `getReportCount(address _userAddress)`: Returns the number of reports a user has received.
 * - `moderateUser(address _userAddress, int256 _reputationChange, bool _temporaryBan)`: (Admin function) Allows admins to moderate a user by changing their reputation and potentially temporarily banning them (example ban, not fully implemented ban logic here).
 * - `clearUserReports(address _userAddress)`: (Admin function) Clears the report count for a user.
 *
 * **Utility and Admin Functions:**
 * - `getUsername(address _userAddress)`: Returns the username of a user given their address.
 * - `getUserId(string _username)`: Returns the address of a user given their username.
 * - `isAdmin(address _account)`: Checks if an account has admin privileges.
 * - `setAdmin(address _account)`: (Owner function) Assigns admin privileges to an account.
 * - `renounceAdmin()`: (Admin function) Allows an admin to renounce their admin privileges.
 */
contract DecentralizedReputationSocialGraph {
    // --- Data Structures ---

    struct UserProfile {
        string username;
        string bio;
        uint256 registrationTimestamp;
        bool isRegistered;
    }

    struct Reputation {
        int256 score;
        int256 upvotes;
        int256 downvotes;
    }

    // --- State Variables ---

    address public owner;
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress;
    mapping(address => Reputation) public userReputations;
    mapping(address => mapping(address => bool)) public following; // follower => followed => isFollowing
    mapping(address => uint256) public followerCounts;
    mapping(address => uint256) public followingCounts;
    mapping(address => uint256) public reportCounts;
    mapping(address => bool) public admins;
    address[] public userList; // Keep track of registered users for iteration if needed (not heavily used in this example)

    uint256 public initialReputation = 100; // Initial reputation for new users
    uint256 public reputationUpvoteIncrement = 10;
    uint256 public reputationDownvoteDecrement = 5;
    uint256 public moderationReputationChange = 50; // Reputation change by admin moderation
    uint256 public maxUsernameLength = 30;
    uint256 public maxBioLength = 200;

    // --- Events ---

    event UserRegistered(address indexed userAddress, string username);
    event ProfileUpdated(address indexed userAddress);
    event UserFollowed(address indexed follower, address indexed followed);
    event UserUnfollowed(address indexed follower, address indexed unfollowed);
    event UserUpvoted(address indexed voter, address indexed votedUser);
    event UserDownvoted(address indexed voter, address indexed votedUser);
    event ReputationChanged(address indexed userAddress, int256 newReputation);
    event UserReported(address indexed reporter, address indexed reportedUser, string reason);
    event UserModerated(address indexed moderatedUser, int256 reputationChange, bool temporaryBan, address indexed moderator);
    event AdminSet(address indexed account, address indexed adminSetter);
    event AdminRenounced(address indexed account);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admins can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User must be registered to call this function.");
        _;
    }

    modifier validUsername(string memory _username) {
        require(bytes(_username).length > 0 && bytes(_username).length <= maxUsernameLength, "Username must be between 1 and 30 characters.");
        _;
    }

    modifier validBio(string memory _bio) {
        require(bytes(_bio).length <= maxBioLength, "Bio must be less than 200 characters.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admins[owner] = true; // Owner is initially an admin
    }

    // --- 1. User Profile Management ---

    function registerUser(string memory _username, string memory _bio)
        public
        validUsername(_username)
        validBio(_bio)
    {
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        require(!userProfiles[msg.sender].isRegistered, "User already registered.");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            registrationTimestamp: block.timestamp,
            isRegistered: true
        });
        usernameToAddress[_username] = msg.sender;
        userReputations[msg.sender] = Reputation({
            score: int256(initialReputation),
            upvotes: 0,
            downvotes: 0
        });
        userList.push(msg.sender);
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfileBio(string memory _newBio)
        public
        onlyRegisteredUser
        validBio(_newBio)
    {
        userProfiles[msg.sender].bio = _newBio;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress)
        public
        view
        returns (string memory username, string memory bio, uint256 registrationTimestamp, bool isRegistered)
    {
        UserProfile memory profile = userProfiles[_userAddress];
        return (profile.username, profile.bio, profile.registrationTimestamp, profile.isRegistered);
    }

    // --- 2. Social Graph (Following/Followers) ---

    function followUser(address _userToFollow)
        public
        onlyRegisteredUser
    {
        require(_userToFollow != msg.sender, "Cannot follow yourself.");
        require(userProfiles[_userToFollow].isRegistered, "User to follow must be registered.");
        require(!following[msg.sender][_userToFollow], "Already following this user.");

        following[msg.sender][_userToFollow] = true;
        followerCounts[_userToFollow]++;
        followingCounts[msg.sender]++;
        emit UserFollowed(msg.sender, _userToFollow);
    }

    function unfollowUser(address _userToUnfollow)
        public
        onlyRegisteredUser
    {
        require(_userToUnfollow != msg.sender, "Cannot unfollow yourself.");
        require(following[msg.sender][_userToUnfollow], "Not following this user.");

        following[msg.sender][_userToUnfollow] = false;
        followerCounts[_userToUnfollow]--;
        followingCounts[msg.sender]--;
        emit UserUnfollowed(msg.sender, _userToUnfollow);
    }

    function getFollowersCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return followerCounts[_userAddress];
    }

    function getFollowingCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return followingCounts[_userAddress];
    }

    function isFollowing(address _follower, address _followed)
        public
        view
        returns (bool)
    {
        return following[_follower][_followed];
    }

    function getFollowersList(address _userAddress, uint256 _startIndex, uint256 _count)
        public
        view
        returns (address[] memory followers)
    {
        require(_startIndex < followerCounts[_userAddress], "Start index out of bounds.");
        uint256 count = _count;
        if (_startIndex + _count > followerCounts[_userAddress]) {
            count = followerCounts[_userAddress] - _startIndex;
        }
        followers = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < userList.length; i++) {
            if (following[userList[i]][_userAddress]) { // Check if userList[i] is following _userAddress (reverse for followers)
                if (index >= _startIndex && index < _startIndex + count) {
                    followers[index - _startIndex] = userList[i];
                }
                index++;
            }
        }
        return followers;
    }

    function getFollowingList(address _userAddress, uint256 _startIndex, uint256 _count)
        public
        view
        returns (address[] memory followingUsers)
    {
        require(_startIndex < followingCounts[_userAddress], "Start index out of bounds.");
        uint256 count = _count;
        if (_startIndex + _count > followingCounts[_userAddress]) {
            count = followingCounts[_userAddress] - _startIndex;
        }
        followingUsers = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < userList.length; i++) {
            if (following[_userAddress][userList[i]]) { // Check if _userAddress is following userList[i]
                if (index >= _startIndex && index < _startIndex + count) {
                    followingUsers[index - _startIndex] = userList[i];
                }
                index++;
            }
        }
        return followingUsers;
    }

    // --- 3. Reputation System (Basic Upvotes/Downvotes) ---

    function upvoteUser(address _userToUpvote)
        public
        onlyRegisteredUser
    {
        require(_userToUpvote != msg.sender, "Cannot upvote yourself.");
        require(userProfiles[_userToUpvote].isRegistered, "User to upvote must be registered.");

        userReputations[_userToUpvote].score += int256(reputationUpvoteIncrement);
        userReputations[_userToUpvote].upvotes++;
        emit UserUpvoted(msg.sender, _userToUpvote);
        emit ReputationChanged(_userToUpvote, userReputations[_userToUpvote].score);
    }

    function downvoteUser(address _userToDownvote)
        public
        onlyRegisteredUser
    {
        require(_userToDownvote != msg.sender, "Cannot downvote yourself.");
        require(userProfiles[_userToDownvote].isRegistered, "User to downvote must be registered.");

        userReputations[_userToDownvote].score -= int256(reputationDownvoteDecrement);
        userReputations[_userToDownvote].downvotes++;
        emit UserDownvoted(msg.sender, _userToDownvote);
        emit ReputationChanged(_userToDownvote, userReputations[_userToDownvote].score);
    }

    function getUserReputation(address _userAddress)
        public
        view
        returns (int256)
    {
        return userReputations[_userAddress].score;
    }

    function getVoteCount(address _userAddress)
        public
        view
        returns (int256)
    {
        return userReputations[_userAddress].upvotes - userReputations[_userAddress].downvotes;
    }

    function resetUserReputation(address _userAddress)
        public
        onlyAdmin
    {
        userReputations[_userAddress].score = int256(initialReputation);
        userReputations[_userAddress].upvotes = 0;
        userReputations[_userAddress].downvotes = 0;
        emit ReputationChanged(_userAddress, userReputations[_userAddress].score);
    }

    // --- 4. Content Moderation (Decentralized Reporting) ---

    function reportUser(address _userToReport, string memory _reason)
        public
        onlyRegisteredUser
    {
        require(_userToReport != msg.sender, "Cannot report yourself.");
        require(userProfiles[_userToReport].isRegistered, "User to report must be registered.");

        reportCounts[_userToReport]++;
        emit UserReported(msg.sender, _userToReport, _reason);
    }

    function getReportCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return reportCounts[_userAddress];
    }

    function moderateUser(address _userAddress, int256 _reputationChange, bool _temporaryBan)
        public
        onlyAdmin
    {
        // Example: Simple reputation change and a flag for "temporary ban" (actual ban logic not implemented here)
        userReputations[_userAddress].score += _reputationChange;
        if (_temporaryBan) {
            // In a real system, you would implement a ban mechanism, e.g., block user actions for a period.
            // For this example, we just emit an event indicating a temporary ban was requested.
        }
        emit UserModerated(_userAddress, _reputationChange, _temporaryBan, msg.sender);
        emit ReputationChanged(_userAddress, userReputations[_userAddress].score);
    }

    function clearUserReports(address _userAddress)
        public
        onlyAdmin
    {
        reportCounts[_userAddress] = 0;
    }

    // --- 5. Utility and Admin Functions ---

    function getUsername(address _userAddress)
        public
        view
        returns (string memory)
    {
        return userProfiles[_userAddress].username;
    }

    function getUserId(string memory _username)
        public
        view
        returns (address)
    {
        return usernameToAddress[_username];
    }

    function isAdmin(address _account)
        public
        view
        returns (bool)
    {
        return admins[_account];
    }

    function setAdmin(address _account)
        public
        onlyOwner
    {
        admins[_account] = true;
        emit AdminSet(_account, msg.sender);
    }

    function renounceAdmin()
        public
        onlyAdmin
    {
        delete admins[msg.sender];
        emit AdminRenounced(msg.sender);
    }
}
```