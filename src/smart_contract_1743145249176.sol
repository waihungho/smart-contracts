```solidity
/**
 * @title Decentralized Reputation and Social Graph Protocol
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation and social graph protocol.
 *      This contract allows users to build a reputation based on endorsements, interactions,
 *      and contributions within a decentralized ecosystem. It also facilitates the creation
 *      of a social graph by allowing users to follow and be followed by others.
 *
 * Function Summary:
 * -----------------
 * **Profile Management:**
 * 1. `registerProfile(string _username, string _bio)`: Allows a user to register a profile with a unique username and bio.
 * 2. `updateProfileBio(string _newBio)`: Allows a user to update their profile bio.
 * 3. `updateProfileUsername(string _newUsername)`: Allows a user to update their profile username (with uniqueness check).
 * 4. `getProfile(address _user)`: Retrieves the profile information of a user.
 * 5. `getUsername(address _user)`: Retrieves the username of a user.
 * 6. `getBio(address _user)`: Retrieves the bio of a user.
 * 7. `profileExists(address _user)`: Checks if a user profile exists.
 *
 * **Social Graph (Following/Followers):**
 * 8. `followUser(address _targetUser)`: Allows a user to follow another user.
 * 9. `unfollowUser(address _targetUser)`: Allows a user to unfollow another user.
 * 10. `getFollowers(address _user)`: Retrieves a list of followers for a given user.
 * 11. `getFollowing(address _user)`: Retrieves a list of users a given user is following.
 * 12. `isFollowing(address _follower, address _target)`: Checks if a user is following another user.
 *
 * **Reputation System (Endorsements):**
 * 13. `endorseUser(address _targetUser, string _endorsementMessage)`: Allows a user to endorse another user with a message.
 * 14. `getEndorsements(address _user)`: Retrieves a list of endorsements received by a user.
 * 15. `getEndorsementCount(address _user)`: Retrieves the number of endorsements received by a user.
 * 16. `getEndorsementMessages(address _user)`: Retrieves a list of endorsement messages received by a user.
 * 17. `getEndorsementMessagesFromEndorser(address _user, address _endorser)`: Retrieves endorsement messages from a specific endorser to a user.
 *
 * **Moderation & Reporting (Basic Example - can be expanded):**
 * 18. `reportUser(address _reportedUser, string _reportReason)`: Allows users to report other users for inappropriate behavior.
 * 19. `moderateReport(uint256 _reportId, bool _acceptReport)`: (Admin/Moderator function) Moderates a user report and potentially applies penalties (placeholder).
 * 20. `getPendingReports()`: (Admin/Moderator function) Retrieves a list of pending user reports.
 * 21. `addModerator(address _moderator)`: (Admin function) Adds an address as a moderator.
 * 22. `removeModerator(address _moderator)`: (Admin function) Removes an address from being a moderator.
 * 23. `isModerator(address _user)`: Checks if an address is a moderator.
 *
 * **Admin & Utility:**
 * 24. `pauseContract()`: (Admin function) Pauses the contract functionality.
 * 25. `unpauseContract()`: (Admin function) Unpauses the contract functionality.
 * 26. `ownerWithdraw(uint256 _amount)`: (Admin function) Allows the contract owner to withdraw contract balance.
 * 27. `getContractBalance()`: Retrieves the current balance of the contract.
 * 28. `getVersion()`: Returns the contract version.
 *
 * Outline:
 * --------
 * 1. State Variables (profiles, usernames, followers, following, endorsements, reports, moderators, etc.)
 * 2. Structs (UserProfile, Endorsement, Report)
 * 3. Modifiers (onlyRegisteredUser, onlyModerator, onlyOwner, whenNotPaused, whenPaused)
 * 4. Events (ProfileRegistered, ProfileUpdated, UserFollowed, UserUnfollowed, UserEndorsed, UserReported, ReportModerated, ContractPaused, ContractUnpaused, ModeratorAdded, ModeratorRemoved)
 * 5. Profile Management Functions (registerProfile, updateProfileBio, updateProfileUsername, getProfile, getUsername, getBio, profileExists)
 * 6. Social Graph Functions (followUser, unfollowUser, getFollowers, getFollowing, isFollowing)
 * 7. Reputation System Functions (endorseUser, getEndorsements, getEndorsementCount, getEndorsementMessages, getEndorsementMessagesFromEndorser)
 * 8. Moderation & Reporting Functions (reportUser, moderateReport, getPendingReports, addModerator, removeModerator, isModerator)
 * 9. Admin & Utility Functions (pauseContract, unpauseContract, ownerWithdraw, getContractBalance, getVersion)
 */
pragma solidity ^0.8.0;

contract DecentralizedReputationSocialGraph {
    // State Variables

    // User Profiles
    struct UserProfile {
        string username;
        string bio;
        bool exists;
    }
    mapping(address => UserProfile) public profiles;
    mapping(string => address) public usernameToAddress; // For username uniqueness check

    // Social Graph
    mapping(address => mapping(address => bool)) public following; // user => targetUser => isFollowing
    mapping(address => address[]) public followersList; // user => list of follower addresses
    mapping(address => address[]) public followingList; // user => list of following addresses

    // Reputation (Endorsements)
    struct Endorsement {
        address endorser;
        string message;
        uint256 timestamp;
    }
    mapping(address => Endorsement[]) public endorsementsReceived; // user => list of endorsements received

    // Moderation & Reporting
    struct Report {
        address reporter;
        address reportedUser;
        string reason;
        uint256 timestamp;
        bool isPending;
    }
    Report[] public reports;
    mapping(address => bool) public moderators;

    // Contract State
    bool public paused;
    address public owner;
    string public constant VERSION = "1.0.0"; // Contract Version

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(profiles[msg.sender].exists, "User profile not registered.");
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

    // Events

    event ProfileRegistered(address indexed user, string username);
    event ProfileUpdated(address indexed user, string newBio);
    event UsernameUpdated(address indexed user, string newUsername);
    event UserFollowed(address indexed follower, address indexed targetUser);
    event UserUnfollowed(address indexed follower, address indexed targetUser);
    event UserEndorsed(address indexed user, address indexed endorser, string message);
    event UserReported(uint256 reportId, address indexed reporter, address indexed reportedUser, string reason);
    event ReportModerated(uint256 reportId, bool accepted, address moderator);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ModeratorAdded(address indexed moderator, address admin);
    event ModeratorRemoved(address indexed moderator, address admin);
    event OwnerWithdrawal(address indexed owner, uint256 amount);

    // Constructor
    constructor() {
        owner = msg.sender;
        paused = false; // Contract starts unpaused
    }

    // ------------------------------------------------------------------------
    // Profile Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Registers a new user profile.
     * @param _username The desired username. Must be unique.
     * @param _bio The user's profile bio.
     */
    function registerProfile(string memory _username, string memory _bio) external whenNotPaused {
        require(!profiles[msg.sender].exists, "Profile already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        require(bytes(_bio).length <= 256, "Bio must be at most 256 characters.");

        profiles[msg.sender] = UserProfile({
            username: _username,
            bio: _bio,
            exists: true
        });
        usernameToAddress[_username] = msg.sender;

        emit ProfileRegistered(msg.sender, _username);
    }

    /**
     * @dev Updates the bio of the user's profile.
     * @param _newBio The new bio to set.
     */
    function updateProfileBio(string memory _newBio) external onlyRegisteredUser whenNotPaused {
        require(bytes(_newBio).length <= 256, "Bio must be at most 256 characters.");
        profiles[msg.sender].bio = _newBio;
        emit ProfileUpdated(msg.sender, _newBio);
    }

    /**
     * @dev Updates the username of the user's profile.
     * @param _newUsername The new username to set. Must be unique.
     */
    function updateProfileUsername(string memory _newUsername) external onlyRegisteredUser whenNotPaused {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be between 1 and 32 characters.");
        require(usernameToAddress[_newUsername] == address(0), "Username already taken.");

        string memory oldUsername = profiles[msg.sender].username;
        usernameToAddress[oldUsername] = address(0); // Remove old username mapping
        profiles[msg.sender].username = _newUsername;
        usernameToAddress[_newUsername] = msg.sender; // Add new username mapping
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    /**
     * @dev Retrieves the profile information of a user.
     * @param _user The address of the user.
     * @return UserProfile struct containing profile details.
     */
    function getProfile(address _user) external view returns (UserProfile memory) {
        return profiles[_user];
    }

    /**
     * @dev Retrieves the username of a user.
     * @param _user The address of the user.
     * @return string The username.
     */
    function getUsername(address _user) external view returns (string memory) {
        return profiles[_user].username;
    }

    /**
     * @dev Retrieves the bio of a user.
     * @param _user The address of the user.
     * @return string The bio.
     */
    function getBio(address _user) external view returns (string memory) {
        return profiles[_user].bio;
    }

    /**
     * @dev Checks if a user profile exists.
     * @param _user The address of the user.
     * @return bool True if profile exists, false otherwise.
     */
    function profileExists(address _user) external view returns (bool) {
        return profiles[_user].exists;
    }


    // ------------------------------------------------------------------------
    // Social Graph (Following/Followers) Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to follow another user.
     * @param _targetUser The address of the user to follow.
     */
    function followUser(address _targetUser) external onlyRegisteredUser whenNotPaused {
        require(_targetUser != msg.sender, "Cannot follow yourself.");
        require(profiles[_targetUser].exists, "Target user profile does not exist.");
        require(!following[msg.sender][_targetUser], "Already following this user.");

        following[msg.sender][_targetUser] = true;
        followersList[_targetUser].push(msg.sender);
        followingList[msg.sender].push(_targetUser);

        emit UserFollowed(msg.sender, _targetUser);
    }

    /**
     * @dev Allows a user to unfollow another user.
     * @param _targetUser The address of the user to unfollow.
     */
    function unfollowUser(address _targetUser) external onlyRegisteredUser whenNotPaused {
        require(following[msg.sender][_targetUser], "Not following this user.");

        following[msg.sender][_targetUser] = false;

        // Remove follower from followersList of targetUser
        address[] storage followersOfTarget = followersList[_targetUser];
        for (uint256 i = 0; i < followersOfTarget.length; i++) {
            if (followersOfTarget[i] == msg.sender) {
                followersOfTarget[i] = followersOfTarget[followersOfTarget.length - 1];
                followersOfTarget.pop();
                break;
            }
        }

        // Remove targetUser from followingList of msg.sender
        address[] storage followingOfSender = followingList[msg.sender];
        for (uint256 i = 0; i < followingOfSender.length; i++) {
            if (followingOfSender[i] == _targetUser) {
                followingOfSender[i] = followingOfSender[followingOfSender.length - 1];
                followingOfSender.pop();
                break;
            }
        }

        emit UserUnfollowed(msg.sender, _targetUser);
    }

    /**
     * @dev Retrieves a list of followers for a given user.
     * @param _user The address of the user.
     * @return address[] Array of follower addresses.
     */
    function getFollowers(address _user) external view returns (address[] memory) {
        return followersList[_user];
    }

    /**
     * @dev Retrieves a list of users a given user is following.
     * @param _user The address of the user.
     * @return address[] Array of addresses being followed.
     */
    function getFollowing(address _user) external view returns (address[] memory) {
        return followingList[_user];
    }

    /**
     * @dev Checks if a user is following another user.
     * @param _follower The address of the potential follower.
     * @param _target The address of the potential target user.
     * @return bool True if _follower is following _target, false otherwise.
     */
    function isFollowing(address _follower, address _target) external view returns (bool) {
        return following[_follower][_target];
    }


    // ------------------------------------------------------------------------
    // Reputation System (Endorsements) Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to endorse another user with a message.
     * @param _targetUser The address of the user to endorse.
     * @param _endorsementMessage The message accompanying the endorsement.
     */
    function endorseUser(address _targetUser, string memory _endorsementMessage) external onlyRegisteredUser whenNotPaused {
        require(_targetUser != msg.sender, "Cannot endorse yourself.");
        require(profiles[_targetUser].exists, "Target user profile does not exist.");
        require(bytes(_endorsementMessage).length <= 256, "Endorsement message must be at most 256 characters.");

        endorsementsReceived[_targetUser].push(Endorsement({
            endorser: msg.sender,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));

        emit UserEndorsed(_targetUser, msg.sender, _endorsementMessage);
    }

    /**
     * @dev Retrieves a list of endorsements received by a user.
     * @param _user The address of the user.
     * @return Endorsement[] Array of endorsement structs.
     */
    function getEndorsements(address _user) external view returns (Endorsement[] memory) {
        return endorsementsReceived[_user];
    }

    /**
     * @dev Retrieves the number of endorsements received by a user.
     * @param _user The address of the user.
     * @return uint256 The number of endorsements.
     */
    function getEndorsementCount(address _user) external view returns (uint256) {
        return endorsementsReceived[_user].length;
    }

    /**
     * @dev Retrieves a list of endorsement messages received by a user.
     * @param _user The address of the user.
     * @return string[] Array of endorsement messages.
     */
    function getEndorsementMessages(address _user) external view returns (string[] memory) {
        uint256 count = endorsementsReceived[_user].length;
        string[] memory messages = new string[](count);
        for (uint256 i = 0; i < count; i++) {
            messages[i] = endorsementsReceived[_user][i].message;
        }
        return messages;
    }

    /**
     * @dev Retrieves endorsement messages from a specific endorser to a user.
     * @param _user The address of the user who received endorsements.
     * @param _endorser The address of the endorser.
     * @return string[] Array of endorsement messages from the specific endorser.
     */
    function getEndorsementMessagesFromEndorser(address _user, address _endorser) external view returns (string[] memory) {
        Endorsement[] memory allEndorsements = endorsementsReceived[_user];
        uint256 count = 0;
        for (uint256 i = 0; i < allEndorsements.length; i++) {
            if (allEndorsements[i].endorser == _endorser) {
                count++;
            }
        }
        string[] memory messages = new string[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allEndorsements.length; i++) {
            if (allEndorsements[i].endorser == _endorser) {
                messages[index] = allEndorsements[i].message;
                index++;
            }
        }
        return messages;
    }


    // ------------------------------------------------------------------------
    // Moderation & Reporting Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to report another user for inappropriate behavior.
     * @param _reportedUser The address of the user being reported.
     * @param _reportReason The reason for the report.
     */
    function reportUser(address _reportedUser, string memory _reportReason) external onlyRegisteredUser whenNotPaused {
        require(_reportedUser != msg.sender, "Cannot report yourself.");
        require(profiles[_reportedUser].exists, "Reported user profile does not exist.");
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 256, "Report reason must be between 1 and 256 characters.");

        uint256 reportId = reports.length;
        reports.push(Report({
            reporter: msg.sender,
            reportedUser: _reportedUser,
            reason: _reportReason,
            timestamp: block.timestamp,
            isPending: true
        }));

        emit UserReported(reportId, msg.sender, _reportedUser, _reportReason);
    }

    /**
     * @dev Allows moderators to moderate a user report.
     * @param _reportId The ID of the report to moderate.
     * @param _acceptReport Boolean indicating whether to accept or reject the report.
     *                     (Accepting might trigger penalties - placeholder logic).
     */
    function moderateReport(uint256 _reportId, bool _acceptReport) external onlyModerator whenNotPaused {
        require(_reportId < reports.length, "Invalid report ID.");
        Report storage report = reports[_reportId];
        require(report.isPending, "Report is not pending.");

        report.isPending = false; // Mark report as moderated

        if (_acceptReport) {
            // Placeholder for penalty logic - e.g., reduce reputation, temporarily suspend profile, etc.
            // For this example, we'll just emit an event.
            // In a real system, you would implement actual penalty mechanisms.
        }

        emit ReportModerated(_reportId, _acceptReport, msg.sender);
    }

    /**
     * @dev Retrieves a list of pending user reports. (Admin/Moderator function)
     * @return Report[] Array of pending report structs.
     */
    function getPendingReports() external view onlyModerator returns (Report[] memory) {
        uint256 pendingReportCount = 0;
        for (uint256 i = 0; i < reports.length; i++) {
            if (reports[i].isPending) {
                pendingReportCount++;
            }
        }

        Report[] memory pendingReports = new Report[](pendingReportCount);
        uint256 index = 0;
        for (uint256 i = 0; i < reports.length; i++) {
            if (reports[i].isPending) {
                pendingReports[index] = reports[i];
                index++;
            }
        }
        return pendingReports;
    }

    /**
     * @dev Adds an address as a moderator. (Admin function)
     * @param _moderator The address to add as a moderator.
     */
    function addModerator(address _moderator) external onlyOwner whenNotPaused {
        moderators[_moderator] = true;
        emit ModeratorAdded(_moderator, msg.sender);
    }

    /**
     * @dev Removes an address from being a moderator. (Admin function)
     * @param _moderator The address to remove as a moderator.
     */
    function removeModerator(address _moderator) external onlyOwner whenNotPaused {
        moderators[_moderator] = false;
        emit ModeratorRemoved(_moderator, msg.sender);
    }

    /**
     * @dev Checks if an address is a moderator.
     * @param _user The address to check.
     * @return bool True if the address is a moderator, false otherwise.
     */
    function isModerator(address _user) external view returns (bool) {
        return moderators[_user];
    }


    // ------------------------------------------------------------------------
    // Admin & Utility Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Pauses the contract, preventing most functions from being called. (Admin function)
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring normal functionality. (Admin function)
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw the contract's balance. (Admin function)
     * @param _amount The amount to withdraw (in Wei).
     */
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        payable(owner).transfer(_amount);
        emit OwnerWithdrawal(owner, _amount);
    }

    /**
     * @dev Retrieves the current balance of the contract.
     * @return uint256 The contract balance in Wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the contract version.
     * @return string The contract version string.
     */
    function getVersion() external pure returns (string memory) {
        return VERSION;
    }
}
```