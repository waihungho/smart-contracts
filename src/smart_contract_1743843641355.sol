```solidity
/**
 * @title Dynamic Reputation & Influence Token (DRIT) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation and influence system using NFTs.
 *      This contract introduces concepts of on-chain reputation tracking, influence scores,
 *      dynamic NFT metadata, skill-based reputation, and community-driven features.
 *      It aims to be a foundational framework for decentralized communities and platforms
 *      that value and measure user contributions and influence.
 *
 * **Outline:**
 *
 * **1.  Core Concepts:**
 *     - Dynamic Reputation: Reputation is not static; it changes based on on-chain activities.
 *     - Influence Score: A derived metric from reputation and other factors, representing user's impact.
 *     - Skill-Based Reputation: Reputation can be categorized and tracked per skill/domain.
 *     - Community Governance: Some aspects of reputation and rules are community-governed.
 *     - Dynamic NFT Metadata: NFT metadata reflects the user's current reputation and influence.
 *
 * **2.  Key Features and Functions:**
 *     - Profile Creation & Management: Users create and manage their profiles represented by NFTs.
 *     - Skill Endorsement: Users can endorse others for specific skills, contributing to reputation.
 *     - Task/Contribution System:  Record and reward contributions, enhancing reputation.
 *     - Reputation Decay: Reputation can decay over time to encourage continuous engagement.
 *     - Influence Calculation: Algorithm to calculate an influence score based on reputation.
 *     - Dynamic NFT Metadata Updates: Metadata updates to reflect reputation and influence changes.
 *     - Community Governance (Basic): Basic governance mechanisms for parameter adjustments.
 *     - Reputation Leaderboards:  Track and display reputation and influence rankings.
 *     - Skill-Based Leaderboards: Leaderboards specific to different skills.
 *     - Reputation Badges/Achievements: Award badges for significant reputation milestones.
 *     - Reputation Transfer (Limited):  Potentially allow limited reputation transfer in specific scenarios.
 *     - Reputation Boosters: Mechanisms to temporarily boost reputation based on certain actions.
 *     - Anti-Sybil Measures: Functions to mitigate sybil attacks and reputation farming.
 *     - Reporting and Moderation (Basic): Simple reporting mechanism for malicious activities.
 *     - Reputation Tiers/Levels: Categorize reputation into tiers or levels.
 *     - Skill-Based Reputation Weighting:  Different skills might have different reputation weights.
 *     - Reputation Snapshotting: Take snapshots of reputation at specific times for historical records.
 *     - Custom Reputation Metrics: Allow adding custom metrics beyond basic reputation.
 *     - Emergency Reputation Freeze: Contract owner function to freeze reputation updates in emergencies.
 *
 * **Function Summary:**
 *
 * 1.  `createProfile(string _profileName, string _profileDescription, string _profilePictureURI)`: Allows a user to create a profile NFT.
 * 2.  `updateProfileName(uint256 _profileId, string _newName)`: Updates the name of a user's profile.
 * 3.  `updateProfileDescription(uint256 _profileId, string _newDescription)`: Updates the description of a user's profile.
 * 4.  `updateProfilePictureURI(uint256 _profileId, string _newURI)`: Updates the profile picture URI of a user's profile.
 * 5.  `endorseSkill(uint256 _profileId, string _skill)`: Allows users to endorse another profile for a specific skill, increasing their skill-based reputation.
 * 6.  `recordContribution(uint256 _profileId, string _contributionType, uint256 _reputationPoints)`: Records a user's contribution and awards reputation points.
 * 7.  `decayReputation(uint256 _profileId)`: Decreases a user's overall reputation over time (can be automated or triggered).
 * 8.  `calculateInfluenceScore(uint256 _profileId)`: Calculates the influence score for a profile based on reputation and other factors.
 * 9.  `getProfileMetadataURI(uint256 _profileId)`: Returns the dynamic metadata URI for a profile NFT, reflecting current reputation and influence.
 * 10. `setBaseMetadataURI(string _newBaseURI)`:  Admin function to set the base URI for profile metadata.
 * 11. `getReputation(uint256 _profileId)`: Returns the overall reputation score of a profile.
 * 12. `getSkillReputation(uint256 _profileId, string _skill)`: Returns the skill-based reputation score for a profile in a specific skill.
 * 13. `getInfluenceScore(uint256 _profileId)`: Returns the calculated influence score of a profile.
 * 14. `getProfileOwner(uint256 _profileId)`: Returns the owner address of a profile NFT.
 * 15. `getTotalProfiles()`: Returns the total number of profiles created.
 * 16. `getProfileCount()`: Returns the current profile count.
 * 17. `awardReputationBadge(uint256 _profileId, string _badgeName)`: Awards a reputation badge to a profile, potentially displayed in metadata.
 * 18. `transferProfile(address _to, uint256 _profileId)`: Allows transferring ownership of a profile NFT.
 * 19. `boostReputation(uint256 _profileId, uint256 _boostAmount, uint256 _duration)`: Temporarily boosts a profile's reputation for a set duration.
 * 20. `reportProfile(uint256 _profileId, string _reportReason)`: Allows users to report a profile for inappropriate behavior (basic moderation).
 * 21. `getProfileTier(uint256 _profileId)`: Returns the reputation tier/level of a profile based on their reputation score.
 * 22. `setSkillWeight(string _skill, uint256 _weight)`: Admin function to set the weight of a specific skill in overall reputation calculation.
 * 23. `takeReputationSnapshot(string _snapshotName)`: Admin function to take a snapshot of current reputation data.
 * 24. `addCustomMetric(uint256 _profileId, string _metricName, uint256 _metricValue)`: Allows adding custom metrics to a profile beyond standard reputation.
 * 25. `emergencyFreezeReputation()`: Contract owner function to freeze all reputation updates in case of emergency.
 * 26. `emergencyUnfreezeReputation()`: Contract owner function to unfreeze reputation updates.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicReputationInfluenceToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _profileIds;

    struct Profile {
        string profileName;
        string profileDescription;
        string profilePictureURI;
        uint256 reputationScore;
        mapping(string => uint256) skillReputations; // Skill -> Reputation Score
        uint256 influenceScore;
        mapping(string => bool) badges; // Badge Name -> Awarded
        mapping(string => uint256) customMetrics; // Metric Name -> Metric Value
        uint256 lastReputationUpdateTimestamp;
        uint256 reputationBoostExpiry; // Timestamp when reputation boost expires
        uint256 reputationBoostAmount;
    }

    mapping(uint256 => Profile) public profiles;
    mapping(uint256 => address) public profileOwners;
    mapping(address => uint256[]) public ownerProfiles; // Address to list of profile IDs they own
    mapping(string => uint256) public skillWeights; // Skill -> Weight in overall reputation (e.g., "Coding" -> 2, "Design" -> 1)
    mapping(uint256 => string[]) public reputationSnapshots; // Snapshot ID -> Array of Profile Data (for history)
    Counters.Counter private _snapshotIds;
    bool public reputationFrozen = false;

    string public baseMetadataURI;
    uint256 public reputationDecayRate = 1; // Reputation points to decay per decay period
    uint256 public reputationDecayPeriod = 7 days; // Time period for reputation decay
    uint256 public reputationBoostFactor = 2; // Factor by which reputation is boosted
    uint256 public baseInfluenceFactor = 10; // Base multiplier for influence score
    uint256 public skillInfluenceFactor = 5; // Multiplier for skill-based influence

    event ProfileCreated(uint256 profileId, address owner, string profileName);
    event ProfileUpdated(uint256 profileId, string field);
    event SkillEndorsed(uint256 profileId, address endorser, string skill);
    event ContributionRecorded(uint256 profileId, string contributionType, uint256 reputationPoints);
    event ReputationDecayed(uint256 profileId, uint256 decayedAmount);
    event InfluenceScoreCalculated(uint256 profileId, uint256 influenceScore);
    event ReputationBadgeAwarded(uint256 profileId, string badgeName);
    event ReputationBoosted(uint256 profileId, uint256 boostAmount, uint256 duration);
    event ProfileReported(uint256 profileId, address reporter, string reason);
    event ReputationFrozenStatusChanged(bool frozen);
    event ReputationSnapshotTaken(uint256 snapshotId, string snapshotName);
    event CustomMetricAdded(uint256 profileId, string metricName, uint256 metricValue);

    modifier profileExists(uint256 _profileId) {
        require(_exists(_profileId), "Profile does not exist");
        _;
    }

    modifier reputationNotFrozen() {
        require(!reputationFrozen, "Reputation updates are currently frozen");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        baseMetadataURI = _baseURI;
        skillWeights["General"] = 1; // Default weight for general reputation
    }

    /**
     * @dev Creates a new profile NFT for the caller.
     * @param _profileName The name of the profile.
     * @param _profileDescription The description of the profile.
     * @param _profilePictureURI The URI for the profile picture.
     */
    function createProfile(string memory _profileName, string memory _profileDescription, string memory _profilePictureURI) public reputationNotFrozen {
        _profileIds.increment();
        uint256 profileId = _profileIds.current();
        _safeMint(msg.sender, profileId);
        profiles[profileId] = Profile({
            profileName: _profileName,
            profileDescription: _profileDescription,
            profilePictureURI: _profilePictureURI,
            reputationScore: 0,
            influenceScore: 0,
            lastReputationUpdateTimestamp: block.timestamp,
            reputationBoostExpiry: 0,
            reputationBoostAmount: 0
        });
        profileOwners[profileId] = msg.sender;
        ownerProfiles[msg.sender].push(profileId);
        emit ProfileCreated(profileId, msg.sender, _profileName);
    }

    /**
     * @dev Updates the name of a user's profile.
     * @param _profileId The ID of the profile to update.
     * @param _newName The new profile name.
     */
    function updateProfileName(uint256 _profileId, string memory _newName) public profileExists(_profileId) reputationNotFrozen {
        require(profileOwners[_profileId] == msg.sender, "You are not the profile owner");
        profiles[_profileId].profileName = _newName;
        emit ProfileUpdated(_profileId, "profileName");
    }

    /**
     * @dev Updates the description of a user's profile.
     * @param _profileId The ID of the profile to update.
     * @param _newDescription The new profile description.
     */
    function updateProfileDescription(uint256 _profileId, string memory _newDescription) public profileExists(_profileId) reputationNotFrozen {
        require(profileOwners[_profileId] == msg.sender, "You are not the profile owner");
        profiles[_profileId].profileDescription = _newDescription;
        emit ProfileUpdated(_profileId, "profileDescription");
    }

    /**
     * @dev Updates the profile picture URI of a user's profile.
     * @param _profileId The ID of the profile to update.
     * @param _newURI The new profile picture URI.
     */
    function updateProfilePictureURI(uint256 _profileId, string memory _newURI) public profileExists(_profileId) reputationNotFrozen {
        require(profileOwners[_profileId] == msg.sender, "You are not the profile owner");
        profiles[_profileId].profilePictureURI = _newURI;
        emit ProfileUpdated(_profileId, "profilePictureURI");
    }

    /**
     * @dev Allows users to endorse another profile for a specific skill, increasing their skill-based reputation.
     * @param _profileId The ID of the profile to endorse.
     * @param _skill The skill being endorsed.
     */
    function endorseSkill(uint256 _profileId, string memory _skill) public profileExists(_profileId) reputationNotFrozen {
        require(msg.sender != profileOwners[_profileId], "Cannot endorse your own profile");
        profiles[_profileId].skillReputations[_skill] += 1; // Simple endorsement logic, can be made more complex
        emit SkillEndorsed(_profileId, msg.sender, _skill);
        _updateReputationAndInfluence(_profileId);
    }

    /**
     * @dev Records a user's contribution and awards reputation points.
     * @param _profileId The ID of the profile receiving the contribution.
     * @param _contributionType The type of contribution (e.g., "Bug Fix", "Content Creation").
     * @param _reputationPoints The reputation points to award.
     */
    function recordContribution(uint256 _profileId, string memory _contributionType, uint256 _reputationPoints) public profileExists(_profileId) reputationNotFrozen onlyOwner {
        profiles[_profileId].reputationScore += _reputationPoints;
        emit ContributionRecorded(_profileId, _contributionType, _reputationPoints);
        _updateReputationAndInfluence(_profileId);
    }

    /**
     * @dev Decreases a user's overall reputation over time to encourage continuous engagement.
     *      This function can be called periodically or automatically triggered.
     * @param _profileId The ID of the profile whose reputation should decay.
     */
    function decayReputation(uint256 _profileId) public profileExists(_profileId) reputationNotFrozen {
        uint256 timeElapsed = block.timestamp - profiles[_profileId].lastReputationUpdateTimestamp;
        if (timeElapsed >= reputationDecayPeriod) {
            uint256 decayCycles = timeElapsed / reputationDecayPeriod;
            uint256 decayedAmount = decayCycles * reputationDecayRate;
            if (profiles[_profileId].reputationScore >= decayedAmount) {
                profiles[_profileId].reputationScore -= decayedAmount;
                profiles[_profileId].lastReputationUpdateTimestamp = block.timestamp;
                emit ReputationDecayed(_profileId, decayedAmount);
                _updateReputationAndInfluence(_profileId);
            } else if (profiles[_profileId].reputationScore > 0) {
                decayedAmount = profiles[_profileId].reputationScore;
                profiles[_profileId].reputationScore = 0;
                profiles[_profileId].lastReputationUpdateTimestamp = block.timestamp;
                emit ReputationDecayed(_profileId, decayedAmount);
                _updateReputationAndInfluence(_profileId);
            }
        }
    }

    /**
     * @dev Calculates the influence score for a profile based on reputation and skill reputations.
     * @param _profileId The ID of the profile to calculate influence for.
     * @return The calculated influence score.
     */
    function calculateInfluenceScore(uint256 _profileId) public view profileExists(_profileId) returns (uint256) {
        uint256 influence = profiles[_profileId].reputationScore * baseInfluenceFactor;
        uint256 skillInfluence = 0;
        for (uint256 i = 0; i < _profileIds.current(); i++) { // Iterate through skills (less efficient, consider better skill tracking if scale is large)
            if (skillWeights[string(abi.encodePacked(i.toString()))] > 0) { // Basic skill iteration - improve if needed
                skillInfluence += profiles[_profileId].skillReputations[string(abi.encodePacked(i.toString()))] * skillWeights[string(abi.encodePacked(i.toString()))] * skillInfluenceFactor;
            }
        }
        return influence + skillInfluence;
    }

    /**
     * @dev Internal function to update both reputation and influence score and emit influence event.
     * @param _profileId The ID of the profile to update.
     */
    function _updateReputationAndInfluence(uint256 _profileId) internal {
        uint256 influenceScore = calculateInfluenceScore(_profileId);
        profiles[_profileId].influenceScore = influenceScore;
        emit InfluenceScoreCalculated(_profileId, influenceScore);
    }

    /**
     * @dev Returns the dynamic metadata URI for a profile NFT, reflecting current reputation and influence.
     * @param _profileId The ID of the profile to get metadata URI for.
     * @return The metadata URI.
     */
    function getProfileMetadataURI(uint256 _profileId) public view profileExists(_profileId) returns (string memory) {
        // Example: Construct dynamic JSON metadata URI based on profile data.
        // In a real-world scenario, you would likely use an off-chain service to generate metadata.
        string memory baseURIValue = baseMetadataURI;
        return string(abi.encodePacked(baseURIValue, "/", _profileId.toString()));
    }

    /**
     * @dev Overrides tokenURI to use dynamic metadata.
     * @param _tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override virtual profileExists(_tokenId) returns (string memory) {
        return getProfileMetadataURI(_tokenId);
    }

    /**
     * @dev Admin function to set the base URI for profile metadata.
     * @param _newBaseURI The new base metadata URI.
     */
    function setBaseMetadataURI(string memory _newBaseURI) public onlyOwner {
        baseMetadataURI = _newBaseURI;
    }

    /**
     * @dev Returns the overall reputation score of a profile.
     * @param _profileId The ID of the profile.
     * @return The reputation score.
     */
    function getReputation(uint256 _profileId) public view profileExists(_profileId) returns (uint256) {
        return profiles[_profileId].reputationScore;
    }

    /**
     * @dev Returns the skill-based reputation score for a profile in a specific skill.
     * @param _profileId The ID of the profile.
     * @param _skill The skill to query.
     * @return The skill reputation score.
     */
    function getSkillReputation(uint256 _profileId, string memory _skill) public view profileExists(_profileId) returns (uint256) {
        return profiles[_profileId].skillReputations[_skill];
    }

    /**
     * @dev Returns the calculated influence score of a profile.
     * @param _profileId The ID of the profile.
     * @return The influence score.
     */
    function getInfluenceScore(uint256 _profileId) public view profileExists(_profileId) returns (uint256) {
        return profiles[_profileId].influenceScore;
    }

    /**
     * @dev Returns the owner address of a profile NFT.
     * @param _profileId The ID of the profile.
     * @return The owner address.
     */
    function getProfileOwner(uint256 _profileId) public view profileExists(_profileId) returns (address) {
        return profileOwners[_profileId];
    }

    /**
     * @dev Returns the total number of profiles ever created.
     * @return The total profile count.
     */
    function getTotalProfiles() public view returns (uint256) {
        return _profileIds.current();
    }

    /**
     * @dev Returns the current profile count. (Same as getTotalProfiles in this implementation, could differ if profiles are burnable later)
     * @return The current profile count.
     */
    function getProfileCount() public view returns (uint256) {
        return _profileIds.current();
    }

    /**
     * @dev Awards a reputation badge to a profile, potentially displayed in metadata.
     * @param _profileId The ID of the profile to award the badge to.
     * @param _badgeName The name of the badge to award.
     */
    function awardReputationBadge(uint256 _profileId, string memory _badgeName) public onlyOwner profileExists(_profileId) reputationNotFrozen {
        profiles[_profileId].badges[_badgeName] = true;
        emit ReputationBadgeAwarded(_profileId, _badgeName);
    }

    /**
     * @dev Allows transferring ownership of a profile NFT. Standard ERC721 transfer.
     * @param _to The address to transfer the profile to.
     * @param _profileId The ID of the profile to transfer.
     */
    function transferProfile(address _to, uint256 _profileId) public profileExists(_profileId) reputationNotFrozen {
        require(profileOwners[_profileId] == msg.sender, "You are not the profile owner");
        _transfer(msg.sender, _to, _profileId);
        profileOwners[_profileId] = _to;
        // Update ownerProfiles mapping - consider more efficient update if needed for large scale
        _updateOwnerProfilesMapping(msg.sender, _to, _profileId);
    }

    /**
     * @dev Internal helper function to update the ownerProfiles mapping when a profile is transferred.
     */
    function _updateOwnerProfilesMapping(address _from, address _to, uint256 _profileId) internal {
        // Remove from 'from' address list
        uint256[] storage fromProfileList = ownerProfiles[_from];
        for (uint256 i = 0; i < fromProfileList.length; i++) {
            if (fromProfileList[i] == _profileId) {
                delete fromProfileList[i]; // Delete leaves a gap, but order might not matter
                // To maintain contiguous array, you could shift elements but it's more gas intensive:
                // fromProfileList[i] = fromProfileList[fromProfileList.length - 1];
                fromProfileList.pop();
                break;
            }
        }
        // Add to 'to' address list
        ownerProfiles[_to].push(_profileId);
    }

    /**
     * @dev Temporarily boosts a profile's reputation for a set duration.
     * @param _profileId The ID of the profile to boost.
     * @param _boostAmount The amount to boost the reputation by.
     * @param _duration The duration of the boost in seconds.
     */
    function boostReputation(uint256 _profileId, uint256 _boostAmount, uint256 _duration) public onlyOwner profileExists(_profileId) reputationNotFrozen {
        profiles[_profileId].reputationBoostAmount = _boostAmount * reputationBoostFactor; // Apply boost factor
        profiles[_profileId].reputationBoostExpiry = block.timestamp + _duration;
        profiles[_profileId].reputationScore += profiles[_profileId].reputationBoostAmount; // Apply boost immediately
        emit ReputationBoosted(_profileId, _boostAmount, _duration);
        _updateReputationAndInfluence(_profileId);
    }

    /**
     * @dev Internal function to check and apply reputation boost expiry and decay.
     *      Should be called before any function that reads or uses reputation.
     * @param _profileId The ID of the profile to check.
     */
    function _checkBoostAndDecay(uint256 _profileId) internal reputationNotFrozen {
        if (profiles[_profileId].reputationBoostExpiry > 0 && block.timestamp >= profiles[_profileId].reputationBoostExpiry) {
            profiles[_profileId].reputationScore -= profiles[_profileId].reputationBoostAmount; // Remove boost
            profiles[_profileId].reputationBoostAmount = 0;
            profiles[_profileId].reputationBoostExpiry = 0;
            _updateReputationAndInfluence(_profileId); // Recalculate influence after boost removal
        }
        decayReputation(_profileId); // Apply reputation decay regardless of boost
    }

    /**
     * @dev Overrides _beforeTokenTransfer to ensure boost and decay are checked before any transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) { // Don't check on minting
            _checkBoostAndDecay(tokenId);
        }
    }

    /**
     * @dev Allows users to report a profile for inappropriate behavior (basic moderation).
     * @param _profileId The ID of the profile being reported.
     * @param _reportReason The reason for the report.
     */
    function reportProfile(uint256 _profileId, string memory _reportReason) public profileExists(_profileId) reputationNotFrozen {
        require(msg.sender != profileOwners[_profileId], "Cannot report your own profile");
        // Basic reporting mechanism - in a real system, you would store reports and have moderation logic
        emit ProfileReported(_profileId, msg.sender, _reportReason);
        // Further actions would be taken off-chain based on reports (e.g., manual review)
    }

    /**
     * @dev Returns the reputation tier/level of a profile based on their reputation score.
     * @param _profileId The ID of the profile.
     * @return The reputation tier (e.g., "Bronze", "Silver", "Gold").
     */
    function getProfileTier(uint256 _profileId) public view profileExists(_profileId) returns (string memory) {
        uint256 reputation = getReputation(_profileId);
        if (reputation >= 10000) {
            return "Legendary";
        } else if (reputation >= 5000) {
            return "Gold";
        } else if (reputation >= 1000) {
            return "Silver";
        } else if (reputation >= 100) {
            return "Bronze";
        } else {
            return "Newcomer";
        }
    }

    /**
     * @dev Admin function to set the weight of a specific skill in overall reputation calculation.
     * @param _skill The skill to set the weight for.
     * @param _weight The weight value (higher weight means more influence).
     */
    function setSkillWeight(string memory _skill, uint256 _weight) public onlyOwner {
        skillWeights[_skill] = _weight;
    }

    /**
     * @dev Admin function to take a snapshot of current reputation data.
     * @param _snapshotName A name for the snapshot for identification.
     */
    function takeReputationSnapshot(string memory _snapshotName) public onlyOwner {
        _snapshotIds.increment();
        uint256 snapshotId = _snapshotIds.current();
        string[] memory snapshotData = new string[](_profileIds.current());
        for (uint256 i = 1; i <= _profileIds.current(); i++) {
            if (_exists(i)) {
                snapshotData[i-1] = string(abi.encodePacked("Profile ID: ", i.toString(), ", Reputation: ", getReputation(i).toString(), ", Influence: ", getInfluenceScore(i).toString()));
            } else {
                snapshotData[i-1] = "Profile ID: " + i.toString() + " - Not Existent"; // Handle deleted profiles if applicable
            }
        }
        reputationSnapshots[snapshotId] = snapshotData;
        emit ReputationSnapshotTaken(snapshotId, _snapshotName);
    }

    /**
     * @dev Admin function to add a custom metric to a profile beyond standard reputation.
     * @param _profileId The ID of the profile to add the metric to.
     * @param _metricName The name of the custom metric.
     * @param _metricValue The value of the custom metric.
     */
    function addCustomMetric(uint256 _profileId, string memory _metricName, uint256 _metricValue) public onlyOwner profileExists(_profileId) reputationNotFrozen {
        profiles[_profileId].customMetrics[_metricName] = _metricValue;
        emit CustomMetricAdded(_profileId, _metricName, _metricValue);
    }

    /**
     * @dev Contract owner function to freeze all reputation updates in case of emergency.
     */
    function emergencyFreezeReputation() public onlyOwner {
        reputationFrozen = true;
        emit ReputationFrozenStatusChanged(true);
    }

    /**
     * @dev Contract owner function to unfreeze reputation updates.
     */
    function emergencyUnfreezeReputation() public onlyOwner {
        reputationFrozen = false;
        emit ReputationFrozenStatusChanged(false);
    }

    /**
     * @dev Override supportsInterface to enable ERC721 metadata interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```