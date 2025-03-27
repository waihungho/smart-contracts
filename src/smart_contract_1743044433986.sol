```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Social Reputation Badge Platform - Smart Contract
 * @author Bard (Example Smart Contract - Creative & Advanced Concepts)
 * @dev This contract implements a decentralized reputation system using NFTs as badges,
 *      enhanced with social features, dynamic reputation calculation, profile customization,
 *      and governance elements. It aims to be a unique blend of social interaction,
 *      reputation management, and NFT technology, avoiding direct duplication of existing
 *      open-source contracts.
 *
 * Function Outline and Summary:
 *
 * **Reputation Management:**
 *   1. `endorseUser(address _user)`: Allows users to endorse other users, increasing their reputation.
 *   2. `revokeEndorsement(address _user)`: Allows users to revoke a previous endorsement.
 *   3. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 *   4. `getReputationBadgeOfUser(address _user)`: Retrieves the token ID of the Reputation Badge NFT for a user, if they have one.
 *   5. `setReputationThresholds(uint256[] memory _thresholds)`: Admin function to set reputation levels and their thresholds.
 *   6. `getReputationLevel(address _user)`: Returns the current reputation level of a user based on their score.
 *
 * **NFT Badge Management:**
 *   7. `mintReputationBadge(address _user)`: Internal function to mint a Reputation Badge NFT to a user when they reach a new reputation level.
 *   8. `transferReputationBadge(address _recipient, uint256 _tokenId)`: Allows a user to transfer their Reputation Badge NFT.
 *   9. `getBadgeMetadataURI(uint256 _tokenId)`: Returns the metadata URI for a specific Reputation Badge NFT.
 *   10. `setBaseBadgeMetadataURI(string memory _baseURI)`: Admin function to set the base URI for badge metadata.
 *
 * **Social & Profile Features:**
 *   11. `createProfile(string memory _displayName, string memory _bio)`: Allows users to create a social profile associated with their address.
 *   12. `updateProfile(string memory _displayName, string memory _bio)`: Allows users to update their existing profile.
 *   13. `getProfile(address _user)`: Retrieves the profile information of a user.
 *   14. `followUser(address _userToFollow)`: Allows users to follow other users.
 *   15. `unfollowUser(address _userToUnfollow)`: Allows users to unfollow other users.
 *   16. `getFollowerCount(address _user)`: Returns the number of followers a user has.
 *   17. `getFollowingCount(address _user)`: Returns the number of users a user is following.
 *
 * **Governance & Platform Settings:**
 *   18. `setEndorsementWeight(uint256 _weight)`: Admin function to adjust the reputation points gained per endorsement.
 *   19. `pauseContract()`: Admin function to pause core functionalities of the contract.
 *   20. `unpauseContract()`: Admin function to unpause the contract.
 *   21. `withdrawContractBalance(address _recipient)`: Admin function to withdraw ETH from the contract balance.
 *   22. `setPlatformFee(uint256 _feePercentage)`: Admin function to set a platform fee percentage (example for future features - not actively used in this version).
 */
contract SocialReputationBadgePlatform {
    // State Variables

    // Reputation System
    mapping(address => uint256) public userReputations; // User address => Reputation score
    mapping(address => mapping(address => bool)) public hasEndorsed; // Endorser => Endorsed User => bool
    uint256 public endorsementWeight = 10; // Reputation points gained per endorsement
    uint256[] public reputationThresholds = [100, 500, 1000, 5000, 10000]; // Reputation scores for different levels (e.g., Level 1 at 100, Level 2 at 500, etc.)
    string[] public reputationLevelNames = ["Beginner", "Initiate", "Contributor", "Advocate", "Luminary"]; // Names for each reputation level

    // NFT Badges - Simplified ERC721-like implementation (no full ERC721 for brevity, focus on core concept)
    mapping(uint256 => address) private _ownerOf; // Token ID => Owner address
    mapping(address => uint256) private _badgeOfUser; // User address => Token ID of their badge (if any)
    uint256 public nextBadgeTokenId = 1;
    string public baseBadgeMetadataURI = "ipfs://default/"; // Base URI for badge metadata

    // Social Profiles
    struct Profile {
        string displayName;
        string bio;
        bool exists;
    }
    mapping(address => Profile) public userProfiles;
    mapping(address => mapping(address => bool)) public following; // Follower => User Being Followed => bool
    mapping(address => uint256) public followerCount;
    mapping(address => uint256) public followingCount;

    // Governance & Platform Settings
    address public owner;
    bool public paused = false;
    uint256 public platformFeePercentage = 0; // Example fee - not used in current functions

    // Events
    event UserEndorsed(address endorser, address endorsedUser);
    event UserRevokedEndorsement(address endorser, address endorsedUser);
    event ReputationUpdated(address user, uint256 newReputation);
    event ReputationBadgeMinted(address user, uint256 tokenId, uint256 level);
    event ReputationBadgeTransferred(address from, address to, uint256 tokenId);
    event ProfileCreated(address user, string displayName, string bio);
    event ProfileUpdated(address user, string displayName, string bio);
    event UserFollowed(address follower, address userToFollow);
    event UserUnfollowed(address follower, address userToUnfollow);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event PlatformFeeSet(uint256 feePercentage);
    event EndorsementWeightSet(uint256 weight);
    event BaseBadgeMetadataURISet(string baseURI);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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


    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // ------------------------ Reputation Management Functions ------------------------

    /**
     * @dev Allows a user to endorse another user, increasing their reputation.
     * @param _user The address of the user to endorse.
     */
    function endorseUser(address _user) external whenNotPaused {
        require(_user != msg.sender, "You cannot endorse yourself.");
        require(!hasEndorsed[msg.sender][_user], "You have already endorsed this user.");

        userReputations[_user] += endorsementWeight;
        hasEndorsed[msg.sender][_user] = true;

        emit UserEndorsed(msg.sender, _user);
        emit ReputationUpdated(_user, userReputations[_user]);

        // Mint badge if new level reached
        _checkAndMintBadge(_user);
    }

    /**
     * @dev Allows a user to revoke a previous endorsement.
     * @param _user The address of the user whose endorsement to revoke.
     */
    function revokeEndorsement(address _user) external whenNotPaused {
        require(_user != msg.sender, "You cannot revoke endorsement from yourself.");
        require(hasEndorsed[msg.sender][_user], "You have not endorsed this user.");

        userReputations[_user] -= endorsementWeight; // Simple subtraction, consider min reputation floor in real app
        hasEndorsed[msg.sender][_user] = false;

        emit UserRevokedEndorsement(msg.sender, _user);
        emit ReputationUpdated(_user, userReputations[_user]);

        // Re-evaluate badge level if reputation decreased significantly (optional - for more dynamic badges)
        _checkAndMintBadge(_user); // Re-check in case level needs to be downgraded/re-minted logic can be added here.
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputations[_user];
    }

    /**
     * @dev Retrieves the token ID of the Reputation Badge NFT for a user, if they have one.
     * @param _user The address of the user.
     * @return The token ID of the badge, or 0 if no badge.
     */
    function getReputationBadgeOfUser(address _user) external view returns (uint256) {
        return _badgeOfUser[_user];
    }

    /**
     * @dev Admin function to set reputation levels and their thresholds.
     * @param _thresholds An array of reputation scores representing the thresholds for each level.
     */
    function setReputationThresholds(uint256[] memory _thresholds) external onlyOwner {
        reputationThresholds = _thresholds;
        // Optionally update level names as well if needed.
    }

    /**
     * @dev Returns the current reputation level of a user based on their score.
     * @param _user The address of the user.
     * @return The reputation level index (0-based). Returns 0 if below level 1.
     */
    function getReputationLevel(address _user) public view returns (uint256) {
        uint256 reputation = userReputations[_user];
        for (uint256 i = 0; i < reputationThresholds.length; i++) {
            if (reputation < reputationThresholds[i]) {
                return i; // Level index (0-based)
            }
        }
        return reputationThresholds.length; // Highest level if score exceeds all thresholds
    }

    // ------------------------ NFT Badge Management Functions ------------------------

    /**
     * @dev Internal function to mint a Reputation Badge NFT to a user when they reach a new reputation level.
     * @param _user The address of the user to mint the badge for.
     */
    function mintReputationBadge(address _user) internal {
        uint256 level = getReputationLevel(_user);
        uint256 tokenId = nextBadgeTokenId++;

        _ownerOf[tokenId] = _user;
        _badgeOfUser[_user] = tokenId; // Store token ID for user lookup

        emit ReputationBadgeMinted(_user, tokenId, level);
    }

    /**
     * @dev Allows a user to transfer their Reputation Badge NFT.
     * @param _recipient The address to transfer the badge to.
     * @param _tokenId The ID of the Reputation Badge NFT to transfer.
     */
    function transferReputationBadge(address _recipient, uint256 _tokenId) external whenNotPaused {
        require(_ownerOf[_tokenId] == msg.sender, "You do not own this badge.");
        require(_recipient != address(0), "Invalid recipient address.");
        require(_recipient != address(this), "Cannot transfer to contract address.");

        address from = _ownerOf[_tokenId];
        _ownerOf[_tokenId] = _recipient;
        _badgeOfUser[from] = 0; // Remove old user badge mapping (user might not have badge after transfer - design decision)
        _badgeOfUser[_recipient] = _tokenId; // Assign badge to new user

        emit ReputationBadgeTransferred(from, _recipient, _tokenId);
    }


    /**
     * @dev Returns the metadata URI for a specific Reputation Badge NFT.
     * @param _tokenId The ID of the Reputation Badge NFT.
     * @return The metadata URI string.
     */
    function getBadgeMetadataURI(uint256 _tokenId) external view returns (string memory) {
        // Example: Construct URI based on token ID or level - customize as needed
        uint256 level = getReputationLevel(_ownerOf[_tokenId]); // Assumes level correlates with badge
        return string(abi.encodePacked(baseBadgeMetadataURI, "level_", uint2str(level), ".json"));
    }

    /**
     * @dev Admin function to set the base URI for badge metadata.
     * @param _baseURI The new base URI string.
     */
    function setBaseBadgeMetadataURI(string memory _baseURI) external onlyOwner {
        baseBadgeMetadataURI = _baseURI;
        emit BaseBadgeMetadataURISet(_baseURI);
    }

    // ------------------------ Social & Profile Features Functions ------------------------

    /**
     * @dev Allows users to create a social profile associated with their address.
     * @param _displayName The display name for the profile.
     * @param _bio A short bio for the profile.
     */
    function createProfile(string memory _displayName, string memory _bio) external whenNotPaused {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        require(bytes(_displayName).length > 0 && bytes(_displayName).length <= 32, "Display name must be 1-32 characters."); // Example limits

        userProfiles[msg.sender] = Profile({
            displayName: _displayName,
            bio: _bio,
            exists: true
        });
        emit ProfileCreated(msg.sender, _displayName, _bio);
    }

    /**
     * @dev Allows users to update their existing profile.
     * @param _displayName The new display name for the profile.
     * @param _bio The new bio for the profile.
     */
    function updateProfile(string memory _displayName, string memory _bio) external whenNotPaused {
        require(userProfiles[msg.sender].exists, "Profile does not exist. Create one first.");
        require(bytes(_displayName).length > 0 && bytes(_displayName).length <= 32, "Display name must be 1-32 characters."); // Example limits

        userProfiles[msg.sender].displayName = _displayName;
        userProfiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender, _displayName, _bio);
    }

    /**
     * @dev Retrieves the profile information of a user.
     * @param _user The address of the user.
     * @return Profile struct containing profile information.
     */
    function getProfile(address _user) external view returns (Profile memory) {
        return userProfiles[_user];
    }

    /**
     * @dev Allows users to follow other users.
     * @param _userToFollow The address of the user to follow.
     */
    function followUser(address _userToFollow) external whenNotPaused {
        require(_userToFollow != msg.sender, "You cannot follow yourself.");
        require(!following[msg.sender][_userToFollow], "You are already following this user.");

        following[msg.sender][_userToFollow] = true;
        followerCount[_userToFollow]++;
        followingCount[msg.sender]++;

        emit UserFollowed(msg.sender, _userToFollow);
    }

    /**
     * @dev Allows users to unfollow other users.
     * @param _userToUnfollow The address of the user to unfollow.
     */
    function unfollowUser(address _userToUnfollow) external whenNotPaused {
        require(following[msg.sender][_userToUnfollow], "You are not following this user.");

        following[msg.sender][_userToUnfollow] = false;
        followerCount[_userToUnfollow]--;
        followingCount[msg.sender]--;

        emit UserUnfollowed(msg.sender, _userToUnfollow);
    }

    /**
     * @dev Returns the number of followers a user has.
     * @param _user The address of the user.
     * @return The follower count.
     */
    function getFollowerCount(address _user) external view returns (uint256) {
        return followerCount[_user];
    }

    /**
     * @dev Returns the number of users a user is following.
     * @param _user The address of the user.
     * @return The following count.
     */
    function getFollowingCount(address _user) external view returns (uint256) {
        return followingCount[_user];
    }


    // ------------------------ Governance & Platform Settings Functions ------------------------

    /**
     * @dev Admin function to adjust the reputation points gained per endorsement.
     * @param _weight The new endorsement weight.
     */
    function setEndorsementWeight(uint256 _weight) external onlyOwner {
        endorsementWeight = _weight;
        emit EndorsementWeightSet(_weight);
    }

    /**
     * @dev Admin function to pause core functionalities of the contract.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Admin function to unpause the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Admin function to withdraw ETH from the contract balance.
     * @param _recipient The address to send the ETH to.
     */
    function withdrawContractBalance(address _recipient) external onlyOwner {
        payable(_recipient).transfer(address(this).balance);
    }

    /**
     * @dev Admin function to set a platform fee percentage (example for future features).
     * @param _feePercentage The platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner {
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }


    // ------------------------ Internal Helper Functions ------------------------

    /**
     * @dev Internal function to check if a user has reached a new reputation level and mint a badge if needed.
     * @param _user The address of the user to check.
     */
    function _checkAndMintBadge(address _user) internal {
        uint256 currentLevel = getReputationLevel(_user);
        uint256 currentBadgeId = _badgeOfUser[_user];

        if (currentLevel > 0 && currentBadgeId == 0) { // Reached level 1 or higher and no badge yet
            mintReputationBadge(_user);
        } else if (currentLevel > 0 && currentBadgeId != 0) {
            uint256 badgeLevel = getReputationLevel(_ownerOf[currentBadgeId]); // Assumes badge level same as user level at mint time
            if (currentLevel > badgeLevel) {
                // Optional: logic to upgrade badge (burn old, mint new) or just update metadata based on level
                // For simplicity, let's just re-mint a new badge (optional, can be refined)
                // _burnReputationBadge(currentBadgeId); // Add burn function if needed
                _badgeOfUser[_user] = 0; // Clear old badge association
                mintReputationBadge(_user); // Mint new badge at new level
            }
        }
        // Consider logic for downgrading badges if reputation falls below a level threshold (optional complexity)
    }


    // --- Utility function to convert uint to string (for metadata URI example) ---
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
```