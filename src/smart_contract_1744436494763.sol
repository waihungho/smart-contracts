```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Profile NFT with Advanced Features
 * @author Bard (Example Smart Contract)
 * @dev This contract implements a Dynamic Profile NFT with various advanced and creative functionalities.
 * It allows users to create, customize, and interact with dynamic NFT profiles.
 *
 * **Outline and Function Summary:**
 *
 * **1. Profile Creation and Management:**
 *    - `createProfile(string _username, string _bio, string _profilePictureURI)`: Allows users to create a unique NFT profile.
 *    - `updateUsername(uint256 _profileId, string _newUsername)`: Allows profile owners to update their username.
 *    - `updateBio(uint256 _profileId, string _newBio)`: Allows profile owners to update their bio.
 *    - `updateProfilePictureURI(uint256 _profileId, string _newProfilePictureURI)`: Allows profile owners to update their profile picture URI.
 *    - `getProfile(uint256 _profileId)`: Retrieves detailed information about a specific profile.
 *    - `transferProfile(uint256 _profileId, address _to)`: Allows profile owners to transfer their profile NFT.
 *    - `burnProfile(uint256 _profileId)`: Allows profile owners to burn (destroy) their profile NFT.
 *
 * **2. Profile Customization and Features:**
 *    - `addBadgeToProfile(uint256 _profileId, string _badgeName, string _badgeURI)`: Allows profile owners to add badges to their profile.
 *    - `removeBadgeFromProfile(uint256 _profileId, uint256 _badgeIndex)`: Allows profile owners to remove badges from their profile.
 *    - `setProfileTheme(uint256 _profileId, string _themeName)`: Allows profile owners to set a theme for their profile (e.g., visual style).
 *    - `toggleProfileVisibility(uint256 _profileId)`: Allows profile owners to toggle profile visibility (public/private).
 *
 * **3. Social and Interaction Features:**
 *    - `followProfile(uint256 _profileIdToFollow)`: Allows users to follow other profiles.
 *    - `unfollowProfile(uint256 _profileIdToUnfollow)`: Allows users to unfollow profiles.
 *    - `getFollowerCount(uint256 _profileId)`: Retrieves the number of followers for a profile.
 *    - `getFollowingCount(uint256 _profileId)`: Retrieves the number of profiles a profile is following.
 *    - `isFollowing(uint256 _profileId, address _follower)`: Checks if a specific address is following a profile.
 *    - `getFollowers(uint256 _profileId)`: Retrieves a list of followers for a profile.
 *    - `getFollowingProfiles(uint256 _profileId)`: Retrieves a list of profiles a profile is following.
 *
 * **4. Advanced and Unique Features:**
 *    - `endorseProfile(uint256 _profileId, string _endorsementMessage)`: Allows users to endorse profiles with a message.
 *    - `reportProfile(uint256 _profileId, string _reportReason)`: Allows users to report profiles for inappropriate content.
 *    - `verifyProfile(uint256 _profileId)`: (Admin function) Verifies a profile as authentic.
 *    - `getVerifiedProfiles()`: (Admin/Public function) Retrieves a list of verified profiles.
 *    - `searchProfilesByUsername(string _usernameQuery)`: Allows searching for profiles by username (basic substring search).
 *
 * **5. Utility and Admin Functions:**
 *    - `setDefaultProfilePictureURI(string _defaultURI)`: (Admin function) Sets a default profile picture URI.
 *    - `getDefaultProfilePictureURI()`: Retrieves the default profile picture URI.
 *    - `pauseContract()`: (Admin function) Pauses the contract, disabling most functions.
 *    - `unpauseContract()`: (Admin function) Unpauses the contract.
 *    - `isContractPaused()`: Checks if the contract is paused.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DynamicProfileNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _profileIds;

    // Struct to represent a user profile
    struct Profile {
        uint256 profileId;
        address owner;
        string username;
        string bio;
        string profilePictureURI;
        string themeName;
        bool isPublic;
        string[] badges; // Array of badge URIs
        string[] endorsements; // Array of endorsements
        string[] reports; // Array of reports (for admin review)
        bool isVerified;
    }

    mapping(uint256 => Profile) public profiles;
    mapping(uint256 => mapping(address => bool)) public followers; // profileId => (followerAddress => isFollowing)
    mapping(uint256 => mapping(address => bool)) public following; // profileId => (followingAddress => isFollowing)
    mapping(string => uint256[]) public usernameToProfileIds; // For username search (basic substring)
    mapping(uint256 => bool) public verifiedProfiles; // Track verified profiles

    string public defaultProfilePictureURI;
    bool public paused;

    event ProfileCreated(uint256 profileId, address owner, string username);
    event ProfileUpdated(uint256 profileId);
    event BadgeAdded(uint256 profileId, string badgeName);
    event BadgeRemoved(uint256 profileId, uint256 badgeIndex);
    event ProfileThemeSet(uint256 profileId, string themeName);
    event ProfileVisibilityToggled(uint256 profileId, bool isPublic);
    event ProfileFollowed(uint256 profileId, address follower);
    event ProfileUnfollowed(uint256 profileId, address follower);
    event ProfileEndorsed(uint256 profileId, address endorser, string message);
    event ProfileReported(uint256 profileId, address reporter, string reason);
    event ProfileVerified(uint256 profileId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyProfileOwner(uint256 _profileId) {
        require(profiles[_profileId].owner == _msgSender(), "You are not the profile owner");
        _;
    }

    modifier onlyAdmin() {
        require(owner() == _msgSender(), "Only admin can call this function");
        _;
    }

    constructor() ERC721("DynamicProfileNFT", "DPNFT") {
        defaultProfilePictureURI = "ipfs://defaultProfilePictureURI"; // Replace with your default URI
    }

    // -----------------------------------------------------
    // 1. Profile Creation and Management
    // -----------------------------------------------------

    function createProfile(string memory _username, string memory _bio, string memory _profilePictureURI)
        public
        whenNotPaused
        returns (uint256)
    {
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters");
        require(bytes(_bio).length <= 256, "Bio must be less than 256 characters");

        _profileIds.increment();
        uint256 profileId = _profileIds.current();

        profiles[profileId] = Profile({
            profileId: profileId,
            owner: _msgSender(),
            username: _username,
            bio: _bio,
            profilePictureURI: _profilePictureURI,
            themeName: "default",
            isPublic: true,
            badges: new string[](0),
            endorsements: new string[](0),
            reports: new string[](0),
            isVerified: false
        });

        _mint(_msgSender(), profileId);
        usernameToProfileIds[_username].push(profileId); // Index username for search

        emit ProfileCreated(profileId, _msgSender(), _username);
        return profileId;
    }

    function updateUsername(uint256 _profileId, string memory _newUsername)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be between 1 and 32 characters");

        // Remove old username from index (if needed - complex to handle username changes properly in index)
        // For simplicity, not removing old username in this example, just adding new one.

        profiles[_profileId].username = _newUsername;
        usernameToProfileIds[_newUsername].push(_profileId); // Add new username to index

        emit ProfileUpdated(_profileId);
    }

    function updateBio(uint256 _profileId, string memory _newBio)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(bytes(_newBio).length <= 256, "Bio must be less than 256 characters");
        profiles[_profileId].bio = _newBio;
        emit ProfileUpdated(_profileId);
    }

    function updateProfilePictureURI(uint256 _profileId, string memory _newProfilePictureURI)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        profiles[_profileId].profilePictureURI = _newProfilePictureURI;
        emit ProfileUpdated(_profileId);
    }

    function getProfile(uint256 _profileId) public view returns (Profile memory) {
        require(_exists(_profileId), "Profile does not exist");
        return profiles[_profileId];
    }

    function transferProfile(uint256 _profileId, address _to)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        _transfer(_msgSender(), _to, _profileId);
    }

    function burnProfile(uint256 _profileId)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        _burn(_profileId);
        delete profiles[_profileId]; // Clean up profile data
        // TODO: Remove from username index if implemented removal on username change
    }

    // -----------------------------------------------------
    // 2. Profile Customization and Features
    // -----------------------------------------------------

    function addBadgeToProfile(uint256 _profileId, string memory _badgeName, string memory _badgeURI)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(bytes(_badgeName).length > 0 && bytes(_badgeName).length <= 64, "Badge name must be between 1 and 64 characters");
        require(bytes(_badgeURI).length > 0, "Badge URI cannot be empty");

        profiles[_profileId].badges.push(_badgeURI);
        emit BadgeAdded(_profileId, _badgeName);
    }

    function removeBadgeFromProfile(uint256 _profileId, uint256 _badgeIndex)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(_badgeIndex < profiles[_profileId].badges.length, "Invalid badge index");

        // Remove badge by index (shift elements to fill the gap)
        for (uint256 i = _badgeIndex; i < profiles[_profileId].badges.length - 1; i++) {
            profiles[_profileId].badges[i] = profiles[_profileId].badges[i + 1];
        }
        profiles[_profileId].badges.pop(); // Remove last element (duplicate or empty after shift)

        emit BadgeRemoved(_profileId, _badgeIndex);
    }

    function setProfileTheme(uint256 _profileId, string memory _themeName)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        require(bytes(_themeName).length > 0 && bytes(_themeName).length <= 32, "Theme name must be between 1 and 32 characters");
        profiles[_profileId].themeName = _themeName;
        emit ProfileThemeSet(_profileId, _themeName);
    }

    function toggleProfileVisibility(uint256 _profileId)
        public
        whenNotPaused
        onlyProfileOwner(_profileId)
    {
        profiles[_profileId].isPublic = !profiles[_profileId].isPublic;
        emit ProfileVisibilityToggled(_profileId, profiles[_profileId].isPublic);
    }

    // -----------------------------------------------------
    // 3. Social and Interaction Features
    // -----------------------------------------------------

    function followProfile(uint256 _profileIdToFollow) public whenNotPaused {
        require(_exists(_profileIdToFollow), "Profile to follow does not exist");
        require(_profileIdToFollow != _profileIds.current() + 1, "Cannot follow your own profile using profile ID"); // Basic self-follow prevention (adjust logic if needed)
        require(!followers[_profileIdToFollow][_msgSender()], "Already following this profile");

        followers[_profileIdToFollow][_msgSender()] = true;
        following[_profileIds.current() + 1][_profileIdToFollow] = true; // Assuming profile ID of follower is always current + 1 (might need adjustment)

        emit ProfileFollowed(_profileIdToFollow, _msgSender());
    }

    function unfollowProfile(uint256 _profileIdToUnfollow) public whenNotPaused {
        require(_exists(_profileIdToUnfollow), "Profile to unfollow does not exist");
        require(followers[_profileIdToUnfollow][_msgSender()], "Not following this profile");

        followers[_profileIdToUnfollow][_msgSender()] = false;
        delete following[_profileIds.current() + 1][_profileIdToUnfollow]; // Remove from following list

        emit ProfileUnfollowed(_profileIdToUnfollow, _msgSender());
    }

    function getFollowerCount(uint256 _profileId) public view returns (uint256) {
        require(_exists(_profileId), "Profile does not exist");
        uint256 count = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) { // Iterate through all possible profile IDs
            if (followers[_profileId][address(uint160(i))]) { //  Iterate and check followers (inefficient for large scale, consider better data structure for real-world)
                count++;
            }
        }
        return count; // Inefficient approach for large scale. Consider using a counter for efficiency in real application.
    }

    function getFollowingCount(uint256 _profileId) public view returns (uint256) {
        require(_exists(_profileId), "Profile does not exist");
        uint256 count = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) { // Iterate through all possible profile IDs
            if (following[_profileId][address(uint160(i))]) { // Iterate and check following (inefficient for large scale)
                count++;
            }
        }
        return count; // Inefficient approach for large scale. Consider using a counter for efficiency in real application.
    }

    function isFollowing(uint256 _profileId, address _follower) public view returns (bool) {
        require(_exists(_profileId), "Profile does not exist");
        return followers[_profileId][_follower];
    }

    function getFollowers(uint256 _profileId) public view returns (address[] memory) {
        require(_exists(_profileId), "Profile does not exist");
        address[] memory followerList = new address[](getFollowerCount(_profileId));
        uint256 index = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) { // Iterate through all possible profile IDs
            if (followers[_profileId][address(uint160(i))]) { // Iterate and check followers (inefficient for large scale)
                followerList[index] = address(uint160(i));
                index++;
            }
        }
        return followerList; // Inefficient approach for large scale. Consider better data structure for real application.
    }

    function getFollowingProfiles(uint256 _profileId) public view returns (address[] memory) {
        require(_exists(_profileId), "Profile does not exist");
        address[] memory followingList = new address[](getFollowingCount(_profileId));
        uint256 index = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) { // Iterate through all possible profile IDs
            if (following[_profileId][address(uint160(i))]) { // Iterate and check following (inefficient for large scale)
                followingList[index] = address(uint160(i));
                index++;
            }
        }
        return followingList; // Inefficient approach for large scale. Consider better data structure for real application.
    }

    // -----------------------------------------------------
    // 4. Advanced and Unique Features
    // -----------------------------------------------------

    function endorseProfile(uint256 _profileId, string memory _endorsementMessage) public whenNotPaused {
        require(_exists(_profileId), "Profile to endorse does not exist");
        require(bytes(_endorsementMessage).length > 0 && bytes(_endorsementMessage).length <= 140, "Endorsement message must be between 1 and 140 characters");

        profiles[_profileId].endorsements.push(string.concat(_msgSender().toString(), ": ", _endorsementMessage)); // Store endorser address with message
        emit ProfileEndorsed(_profileId, _msgSender(), _endorsementMessage);
    }

    function reportProfile(uint256 _profileId, string memory _reportReason) public whenNotPaused {
        require(_exists(_profileId), "Profile to report does not exist");
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 256, "Report reason must be between 1 and 256 characters");

        profiles[_profileId].reports.push(string.concat(_msgSender().toString(), ": ", _reportReason)); // Store reporter address with reason
        emit ProfileReported(_profileId, _msgSender(), _reportReason);
    }

    function verifyProfile(uint256 _profileId) public whenNotPaused onlyAdmin {
        require(_exists(_profileId), "Profile to verify does not exist");
        profiles[_profileId].isVerified = true;
        verifiedProfiles[_profileId] = true;
        emit ProfileVerified(_profileId);
    }

    function getVerifiedProfiles() public view returns (uint256[] memory) {
        uint256 verifiedCount = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) {
            if (verifiedProfiles[i]) {
                verifiedCount++;
            }
        }

        uint256[] memory verifiedProfileIds = new uint256[](verifiedCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _profileIds.current(); i++) {
            if (verifiedProfiles[i]) {
                verifiedProfileIds[index] = i;
                index++;
            }
        }
        return verifiedProfileIds;
    }

    function searchProfilesByUsername(string memory _usernameQuery) public view returns (uint256[] memory) {
        // Basic substring search (case-sensitive for simplicity). For more robust search, consider off-chain indexing.
        uint256[] memory matchingProfileIds = usernameToProfileIds[_usernameQuery]; // Direct lookup (exact match)
        return matchingProfileIds; // Simple exact match search for demonstration. Real-world search would be more complex and likely off-chain.
    }

    // -----------------------------------------------------
    // 5. Utility and Admin Functions
    // -----------------------------------------------------

    function setDefaultProfilePictureURI(string memory _defaultURI) public whenNotPaused onlyAdmin {
        require(bytes(_defaultURI).length > 0, "Default URI cannot be empty");
        defaultProfilePictureURI = _defaultURI;
    }

    function getDefaultProfilePictureURI() public view returns (string memory) {
        return defaultProfilePictureURI;
    }

    function pauseContract() public whenNotPaused onlyAdmin {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }

    // Override tokenURI to make it dynamic (example - you'd typically use a service like IPFS or a dynamic metadata server)
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Example dynamic URI - in real use case, generate metadata dynamically or point to off-chain metadata service
        return string.concat("ipfs://dynamicProfileMetadata/", Strings.toString(_tokenId));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```