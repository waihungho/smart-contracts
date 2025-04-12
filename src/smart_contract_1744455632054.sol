```solidity
/**
 * @title Dynamic Reputation and Achievement NFT Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT platform where NFTs represent user profiles,
 *      reputation, achievements, and evolve based on on-chain interactions and activities.
 *
 * Function Summary:
 * -----------------
 * **Core NFT Functions (ERC721 based):**
 * 1.  `mintProfileNFT(address _to, string memory _profileName) external`: Mints a new Profile NFT to a user.
 * 2.  `transferNFT(address _to, uint256 _tokenId) external`: Transfers an NFT to another address.
 * 3.  `getProfileName(uint256 _tokenId) public view returns (string memory)`: Retrieves the profile name associated with an NFT.
 * 4.  `getProfileLevel(uint256 _tokenId) public view returns (uint256)`: Retrieves the current level of a profile NFT.
 * 5.  `getReputationScore(uint256 _tokenId) public view returns (uint256)`: Retrieves the reputation score of a profile NFT.
 * 6.  `getAchievementCount(uint256 _tokenId) public view returns (uint256)`: Gets the number of achievements unlocked by a profile NFT.
 * 7.  `getAchievementDetails(uint256 _tokenId, uint256 _achievementIndex) public view returns (string memory, uint256)`: Gets details of a specific achievement.
 *
 * **Reputation and Leveling Functions:**
 * 8.  `interactWithProfile(uint256 _tokenIdToInteractWith) external`: Allows a profile NFT to interact with another, increasing reputation based on interaction type.
 * 9.  `rewardReputation(uint256 _tokenId, uint256 _amount) external onlyOwner`: Owner function to manually reward reputation.
 * 10. `penalizeReputation(uint256 _tokenId, uint256 _amount) external onlyOwner`: Owner function to manually penalize reputation.
 * 11. `levelUpProfile(uint256 _tokenId) external`: Allows a profile owner to level up their NFT when enough reputation is accumulated.
 * 12. `setReputationThresholdForLevel(uint256 _level, uint256 _threshold) external onlyOwner`: Sets the reputation required for each level.
 *
 * **Achievement System Functions:**
 * 13. `unlockAchievement(uint256 _tokenId, string memory _achievementName, uint256 _points) internal`: Internal function to unlock achievements based on actions (used by other functions).
 * 14. `checkAndUnlockInteractionAchievement(uint256 _tokenId) internal`: Checks and unlocks achievements related to interactions.
 * 15. `checkAndUnlockLevelAchievement(uint256 _tokenId) internal`: Checks and unlocks achievements related to reaching certain levels.
 * 16. `viewAllAchievementsForProfile(uint256 _tokenId) public view returns (string[] memory, uint256[] memory)`: Returns a list of all achievements and their points for a profile.
 *
 * **Utility and Community Functions:**
 * 17. `setProfileName(uint256 _tokenId, string memory _newName) external`: Allows a profile owner to update their profile name.
 * 18. `burnProfileNFT(uint256 _tokenId) external`: Allows a profile owner to burn their NFT, destroying it permanently.
 * 19. `pauseContract() external onlyOwner`: Pauses the contract, preventing most state-changing functions.
 * 20. `unpauseContract() external onlyOwner`: Unpauses the contract, restoring functionality.
 * 21. `withdrawFunds() external onlyOwner`: Allows the contract owner to withdraw any accumulated Ether.
 * 22. `supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)`:  Standard ERC165 interface support.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicReputationNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to profile name
    mapping(uint256 => string) public profileNames;

    // Mapping from token ID to reputation score
    mapping(uint256 => uint256) public reputationScores;

    // Mapping from token ID to profile level
    mapping(uint256 => uint256) public profileLevels;

    // Mapping from level to reputation threshold
    mapping(uint256 => uint256) public reputationThresholds;

    // Struct to hold achievement details
    struct Achievement {
        string name;
        uint256 points;
    }

    // Mapping from token ID to list of achievements
    mapping(uint256 => Achievement[]) public profileAchievements;

    // Base URI for NFT metadata (can be updated)
    string public baseURI = "ipfs://your-ipfs-cid/"; // Replace with your IPFS base URI

    event ProfileNFTMinted(uint256 tokenId, address owner, string profileName);
    event ReputationUpdated(uint256 tokenId, uint256 newReputation);
    event ProfileLevelUp(uint256 tokenId, uint256 newLevel);
    event AchievementUnlocked(uint256 tokenId, string achievementName, uint256 points);
    event ProfileNameUpdated(uint256 tokenId, string newName);
    event ContractPaused();
    event ContractUnpaused();

    constructor() ERC721("DynamicProfileNFT", "DPNFT") {
        // Initialize level thresholds (example)
        reputationThresholds[1] = 100;
        reputationThresholds[2] = 300;
        reputationThresholds[3] = 600;
        // ... you can set more levels and thresholds
    }

    // --- Core NFT Functions ---

    /**
     * @dev Mints a new Profile NFT to a user.
     * @param _to The address to mint the NFT to.
     * @param _profileName The name to associate with the profile.
     */
    function mintProfileNFT(address _to, string memory _profileName) external whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(_to, tokenId);
        profileNames[tokenId] = _profileName;
        reputationScores[tokenId] = 0; // Initial reputation
        profileLevels[tokenId] = 1;     // Start at level 1
        emit ProfileNFTMinted(tokenId, _to, _profileName);
    }

    /**
     * @dev Transfers an NFT to another address.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        transferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Retrieves the profile name associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The profile name.
     */
    function getProfileName(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return profileNames[_tokenId];
    }

    /**
     * @dev Retrieves the current level of a profile NFT.
     * @param _tokenId The ID of the NFT.
     * @return The profile level.
     */
    function getProfileLevel(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return profileLevels[_tokenId];
    }

    /**
     * @dev Retrieves the reputation score of a profile NFT.
     * @param _tokenId The ID of the NFT.
     * @return The reputation score.
     */
    function getReputationScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return reputationScores[_tokenId];
    }

    /**
     * @dev Gets the number of achievements unlocked by a profile NFT.
     * @param _tokenId The ID of the NFT.
     * @return The achievement count.
     */
    function getAchievementCount(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return profileAchievements[_tokenId].length;
    }

    /**
     * @dev Gets details of a specific achievement.
     * @param _tokenId The ID of the NFT.
     * @param _achievementIndex The index of the achievement in the list (0-based).
     * @return The achievement name and points.
     */
    function getAchievementDetails(uint256 _tokenId, uint256 _achievementIndex) public view returns (string memory, uint256) {
        require(_exists(_tokenId), "Token does not exist");
        require(_achievementIndex < profileAchievements[_tokenId].length, "Invalid achievement index");
        Achievement storage achievement = profileAchievements[_tokenId][_achievementIndex];
        return (achievement.name, achievement.points);
    }


    // --- Reputation and Leveling Functions ---

    /**
     * @dev Allows a profile NFT to interact with another, increasing reputation.
     * @param _tokenIdToInteractWith The ID of the profile NFT being interacted with.
     */
    function interactWithProfile(uint256 _tokenIdToInteractWith) external whenNotPaused {
        require(_exists(msg.sender), "Caller is not a profile owner"); // Implicitly checks if msg.sender owns a token
        uint256 interactingTokenId = tokenOfOwner(msg.sender); // Get the token ID owned by the sender
        require(_exists(_tokenIdToInteractWith), "Target profile token does not exist");
        require(interactingTokenId != _tokenIdToInteractWith, "Cannot interact with own profile");

        // Example: Simple interaction, award reputation
        uint256 reputationGain = 10;
        reputationScores[_tokenIdToInteractWith] += reputationGain;
        emit ReputationUpdated(_tokenIdToInteractWith, reputationScores[_tokenIdToInteractWith]);

        checkAndUnlockInteractionAchievement(_tokenIdToInteractWith); // Check for interaction-based achievements
    }

    /**
     * @dev Owner function to manually reward reputation.
     * @param _tokenId The ID of the NFT to reward.
     * @param _amount The amount of reputation to reward.
     */
    function rewardReputation(uint256 _tokenId, uint256 _amount) external onlyOwner whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        reputationScores[_tokenId] += _amount;
        emit ReputationUpdated(_tokenId, reputationScores[_tokenId]);
    }

    /**
     * @dev Owner function to manually penalize reputation.
     * @param _tokenId The ID of the NFT to penalize.
     * @param _amount The amount of reputation to penalize.
     */
    function penalizeReputation(uint256 _tokenId, uint256 _amount) external onlyOwner whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        // Prevent reputation from going negative (optional, adjust as needed)
        if (reputationScores[_tokenId] >= _amount) {
            reputationScores[_tokenId] -= _amount;
        } else {
            reputationScores[_tokenId] = 0;
        }
        emit ReputationUpdated(_tokenId, reputationScores[_tokenId]);
    }

    /**
     * @dev Allows a profile owner to level up their NFT when enough reputation is accumulated.
     * @param _tokenId The ID of the NFT to level up.
     */
    function levelUpProfile(uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        require(_exists(_tokenId), "Token does not exist");

        uint256 currentLevel = profileLevels[_tokenId];
        uint256 nextLevel = currentLevel + 1;
        uint256 requiredReputation = reputationThresholds[nextLevel];

        require(requiredReputation > 0, "Max level reached or level thresholds not set"); // Check if threshold is set for next level
        require(reputationScores[_tokenId] >= requiredReputation, "Not enough reputation to level up");

        profileLevels[_tokenId] = nextLevel;
        emit ProfileLevelUp(_tokenId, nextLevel);

        checkAndUnlockLevelAchievement(_tokenId); // Check for level-based achievements
    }

    /**
     * @dev Sets the reputation required for each level (Owner only).
     * @param _level The level number.
     * @param _threshold The reputation threshold required for that level.
     */
    function setReputationThresholdForLevel(uint256 _level, uint256 _threshold) external onlyOwner {
        require(_level > 0, "Level must be greater than 0");
        reputationThresholds[_level] = _threshold;
    }


    // --- Achievement System Functions ---

    /**
     * @dev Internal function to unlock achievements based on actions.
     * @param _tokenId The ID of the NFT receiving the achievement.
     * @param _achievementName The name of the achievement.
     * @param _points Points awarded for the achievement.
     */
    function unlockAchievement(uint256 _tokenId, string memory _achievementName, uint256 _points) internal {
        Achievement memory newAchievement = Achievement({name: _achievementName, points: _points});
        profileAchievements[_tokenId].push(newAchievement);
        emit AchievementUnlocked(_tokenId, _achievementName, _points);
    }

    /**
     * @dev Checks and unlocks achievements related to interactions.
     * @param _tokenId The ID of the NFT to check for achievements.
     */
    function checkAndUnlockInteractionAchievement(uint256 _tokenId) internal {
        // Example: Unlock "Social Butterfly" achievement after 10 interactions
        if (getInteractionCount(_tokenId) >= 10 && !hasAchievement(_tokenId, "Social Butterfly")) {
            unlockAchievement(_tokenId, "Social Butterfly", 50);
        }
        // Add more interaction-based achievement checks here
    }

    /**
     * @dev Checks and unlocks achievements related to reaching certain levels.
     * @param _tokenId The ID of the NFT to check for achievements.
     */
    function checkAndUnlockLevelAchievement(uint256 _tokenId) internal {
        uint256 currentLevel = profileLevels[_tokenId];
        // Example: Unlock "Level 5 Achiever" achievement upon reaching level 5
        if (currentLevel == 5 && !hasAchievement(_tokenId, "Level 5 Achiever")) {
            unlockAchievement(_tokenId, "Level 5 Achiever", 100);
        }
        // Example: Unlock "Level 10 Master" achievement upon reaching level 10
        if (currentLevel == 10 && !hasAchievement(_tokenId, "Level 10 Master")) {
            unlockAchievement(_tokenId, "Level 10 Master", 200);
        }
        // Add more level-based achievement checks here for different levels
    }

    /**
     * @dev Returns a list of all achievements and their points for a profile.
     * @param _tokenId The ID of the NFT.
     * @return Arrays of achievement names and points.
     */
    function viewAllAchievementsForProfile(uint256 _tokenId) public view returns (string[] memory, uint256[] memory) {
        require(_exists(_tokenId), "Token does not exist");
        Achievement[] storage achievements = profileAchievements[_tokenId];
        uint256 count = achievements.length;
        string[] memory names = new string[](count);
        uint256[] memory points = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            names[i] = achievements[i].name;
            points[i] = achievements[i].points;
        }
        return (names, points);
    }

    // --- Utility and Community Functions ---

    /**
     * @dev Allows a profile owner to update their profile name.
     * @param _tokenId The ID of the NFT.
     * @param _newName The new profile name.
     */
    function setProfileName(uint256 _tokenId, string memory _newName) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        require(_exists(_tokenId), "Token does not exist");
        profileNames[_tokenId] = _newName;
        emit ProfileNameUpdated(_tokenId, _newName);
    }

    /**
     * @dev Allows a profile owner to burn their NFT, destroying it permanently.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnProfileNFT(uint256 _tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not owner or approved");
        require(_exists(_tokenId), "Token does not exist");
        _burn(_tokenId);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing functions.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring functionality.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Allows the contract owner to withdraw any accumulated Ether.
     */
    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    // --- Internal Helper Functions (Not directly exposed but used within contract) ---

    /**
     * @dev Internal function to check if a profile has a specific achievement.
     * @param _tokenId The ID of the NFT.
     * @param _achievementName The name of the achievement to check.
     * @return True if the achievement exists, false otherwise.
     */
    function hasAchievement(uint256 _tokenId, string memory _achievementName) internal view returns (bool) {
        Achievement[] storage achievements = profileAchievements[_tokenId];
        for (uint256 i = 0; i < achievements.length; i++) {
            if (keccak256(bytes(achievements[i].name)) == keccak256(bytes(_achievementName))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Internal function to get the interaction count for a profile (example - could be expanded).
     * @param _tokenId The ID of the NFT.
     * @return The interaction count.
     */
    function getInteractionCount(uint256 _tokenId) internal view returns (uint256) {
        // In a real-world scenario, you might track interaction counts in a mapping
        // For this example, we are just returning a placeholder value.
        // You could increment a counter in the interactWithProfile function and store it here.
        // For simplicity in this example, we are simulating a count based on reputation for demo purposes.
        return reputationScores[_tokenId] / 20; // Example: Assume ~1 interaction per 20 reputation points
    }


    // --- ERC721 Metadata URI ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = baseURI;
        // Construct dynamic metadata based on token attributes (level, reputation, achievements)
        string memory metadataJSON = generateMetadataJSON(tokenId);
        string memory tokenUri = string(abi.encodePacked(base, tokenId, ".json")); // Basic structure, could be improved
        // In a real application, you would likely upload the JSON to IPFS and return the IPFS URI.
        // For this example, we are returning a placeholder.
        return tokenUri; // In a real scenario, point this to IPFS or your metadata server.
    }

    /**
     * @dev Generates a basic JSON metadata string for the NFT (example - customize as needed).
     * @param _tokenId The ID of the NFT.
     * @return JSON metadata string.
     */
    function generateMetadataJSON(uint256 _tokenId) internal view returns (string memory) {
        string memory name = getProfileName(_tokenId);
        uint256 level = getProfileLevel(_tokenId);
        uint256 reputation = getReputationScore(_tokenId);
        (string[] memory achievementNames, uint256[] memory achievementPoints) = viewAllAchievementsForProfile(_tokenId);

        string memory json = string(abi.encodePacked(
            '{"name": "', name, '", ',
            '"description": "A Dynamic Reputation and Achievement Profile NFT.", ',
            '"image": "ipfs://your-default-image-cid.png", ', // Replace with a default image CID
            '"attributes": [',
                '{"trait_type": "Level", "value": ', Strings.toString(level), '}, ',
                '{"trait_type": "Reputation", "value": ', Strings.toString(reputation), '}, ',
                '{"trait_type": "Achievements", "value": ', Strings.toString(achievementNames.length), '}'
            ,']}'
        ));
        return json;
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // --- ERC165 Interface Support ---
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```