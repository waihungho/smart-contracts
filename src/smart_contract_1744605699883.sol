```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Credibility Network (DCN) - Smart Contract Outline and Summary
 * @author Bard (Generated Example - Conceptual)
 * @dev A smart contract implementing a Decentralized Credibility Network.
 *      This contract allows users to build and verify credibility through endorsements and reputation tokens,
 *      incorporating features like skill-based endorsements, reputation staking, dynamic reputation scores,
 *      and decentralized dispute resolution.
 *
 * **Contract Summary:**
 *
 * This contract aims to establish a decentralized system for tracking and verifying credibility.
 * Users can create profiles, endorse each other for specific skills, and earn reputation tokens based on
 * endorsements received and staked. The contract includes mechanisms for skill management, reputation scoring,
 * staking, and even a basic decentralized dispute resolution system.  It also incorporates a dynamic reputation
 * decay and boost mechanism to keep reputation scores relevant and active.
 *
 * **Function Summary:**
 *
 * **Profile Management:**
 * 1. `createUserProfile(string _username, string _profileDetails)`: Allows a user to create their profile.
 * 2. `updateUserProfile(string _profileDetails)`: Allows a user to update their profile details.
 * 3. `getUserProfile(address _userAddress)`: Retrieves a user's profile details.
 *
 * **Skill/Tag Management:**
 * 4. `addSkillTag(string _tagName, string _tagDescription)`: Allows the contract owner to add new skill tags.
 * 5. `getSkillTagDetails(uint256 _tagId)`: Retrieves details of a specific skill tag.
 * 6. `listAllSkillTags()`: Lists all available skill tags.
 *
 * **Endorsement and Reputation:**
 * 7. `endorseUser(address _targetUser, uint256 _skillTagId, string _endorsementMessage)`: Allows a user to endorse another user for a specific skill.
 * 8. `getEndorsementsForUser(address _userAddress)`: Retrieves all endorsements received by a user.
 * 9. `getEndorsementsBySkillTag(address _userAddress, uint256 _skillTagId)`: Retrieves endorsements for a user for a specific skill tag.
 * 10. `calculateUserReputation(address _userAddress)`: Calculates a user's reputation score based on endorsements and staking.
 * 11. `getUserReputationScore(address _userAddress)`: Retrieves a user's current reputation score.
 * 12. `issueReputationToken(address _userAddress, uint256 _amount)`: Issues reputation tokens to a user (internal, based on reputation milestones).
 * 13. `getStakedReputation(address _userAddress)`: Retrieves the amount of reputation tokens staked by a user.
 * 14. `stakeReputationToken(uint256 _amount)`: Allows a user to stake their reputation tokens to boost their reputation score.
 * 15. `unstakeReputationToken(uint256 _amount)`: Allows a user to unstake their reputation tokens.
 *
 * **Reputation Dynamics and Decay:**
 * 16. `applyReputationDecay(address _userAddress)`:  Applies a decay factor to a user's reputation score over time (owner-callable for maintenance).
 * 17. `boostReputation(address _userAddress, uint256 _boostAmount)`: Allows the contract owner to manually boost a user's reputation (e.g., for early adopters, special contributions).
 *
 * **Dispute Resolution (Basic):**
 * 18. `reportEndorsement(uint256 _endorsementId, string _reportReason)`: Allows a user to report an endorsement as spam or inaccurate.
 * 19. `voteOnEndorsementReport(uint256 _reportId, bool _isSpam)`: Allows designated moderators (or reputation token holders in a more advanced version) to vote on a report.
 * 20. `resolveEndorsementReport(uint256 _reportId)`: Resolves a reported endorsement based on voting results (removes endorsement if spam).
 *
 * **Admin/Utility:**
 * 21. `pauseContract()`:  Allows the contract owner to pause the contract for maintenance.
 * 22. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 23. `setReputationDecayRate(uint256 _newRate)`:  Allows the contract owner to set the reputation decay rate.
 * 24. `withdrawContractBalance(address payable _recipient)`: Allows the contract owner to withdraw any accumulated contract balance (e.g., fees, if implemented).
 */

contract DecentralizedCredibilityNetwork {
    // Contract Owner
    address public owner;

    // Contract Paused State
    bool public paused;

    // Reputation Decay Rate (percentage per time unit, e.g., per day)
    uint256 public reputationDecayRate = 1; // 1% decay per default time unit

    // Structs to represent data
    struct UserProfile {
        string username;
        string profileDetails;
        uint256 reputationScore;
        uint256 lastReputationUpdate; // Timestamp of last reputation update
        uint256 stakedReputation;
    }

    struct SkillTag {
        uint256 tagId;
        string tagName;
        string tagDescription;
        bool isActive;
    }

    struct Endorsement {
        uint256 endorsementId;
        address endorser;
        address endorsedUser;
        uint256 skillTagId;
        string endorsementMessage;
        uint256 timestamp;
        bool isActive; // To handle removal due to disputes
    }

    struct EndorsementReport {
        uint256 reportId;
        uint256 endorsementId;
        address reporter;
        string reportReason;
        uint256 upVotes;
        uint256 downVotes;
        bool isResolved;
        bool isSpam; // Determined after voting
    }

    // Mappings for data storage
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => SkillTag) public skillTags;
    mapping(uint256 => Endorsement) public endorsements;
    mapping(uint256 => EndorsementReport) public endorsementReports;
    mapping(address => mapping(uint256 => bool)) public userEndorsedForSkill; // To prevent duplicate endorsements for the same skill by the same endorser
    mapping(address => uint256) public reputationTokenBalance; // Simple representation of reputation tokens

    // Counters for IDs
    uint256 public nextSkillTagId = 1;
    uint256 public nextEndorsementId = 1;
    uint256 public nextReportId = 1;

    // Events
    event ProfileCreated(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillTagAdded(uint256 tagId, string tagName);
    event UserEndorsed(uint256 endorsementId, address endorser, address endorsedUser, uint256 skillTagId);
    event ReputationScoreUpdated(address userAddress, uint256 newScore);
    event ReputationTokenIssued(address userAddress, uint256 amount);
    event ReputationStaked(address userAddress, uint256 amount);
    event ReputationUnstaked(address userAddress, uint256 amount);
    event ReputationDecayApplied(address userAddress, uint256 newScore);
    event ReputationBoosted(address userAddress, address boostedUser, uint256 boostAmount);
    event EndorsementReported(uint256 reportId, uint256 endorsementId, address reporter);
    event EndorsementReportVoted(uint256 reportId, bool isSpam, address voter);
    event EndorsementReportResolved(uint256 reportId, bool isSpam, uint256 endorsementId);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);
    event ReputationDecayRateChanged(uint256 newRate);
    event BalanceWithdrawn(address recipient, uint256 amount);

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

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    // -------------------- Profile Management Functions --------------------

    /// @notice Allows a user to create their profile.
    /// @param _username The desired username for the profile.
    /// @param _profileDetails Additional details about the user's profile.
    function createUserProfile(string memory _username, string memory _profileDetails) external whenNotPaused {
        require(bytes(_username).length > 0 && bytes(_username).length <= 50, "Username must be between 1 and 50 characters.");
        require(userProfiles[msg.sender].username.length == 0, "Profile already exists for this address."); // Prevent duplicate profiles

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDetails: _profileDetails,
            reputationScore: 0,
            lastReputationUpdate: block.timestamp,
            stakedReputation: 0
        });
        emit ProfileCreated(msg.sender, _username);
    }

    /// @notice Allows a user to update their profile details.
    /// @param _profileDetails Updated details about the user's profile.
    function updateUserProfile(string memory _profileDetails) external whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "Profile does not exist. Create one first.");
        userProfiles[msg.sender].profileDetails = _profileDetails;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves a user's profile details.
    /// @param _userAddress The address of the user whose profile is being requested.
    /// @return username The username of the user.
    /// @return profileDetails Additional profile details of the user.
    /// @return reputationScore The user's current reputation score.
    function getUserProfile(address _userAddress) external view whenNotPaused returns (string memory username, string memory profileDetails, uint256 reputationScore) {
        require(userProfiles[_userAddress].username.length > 0, "Profile does not exist for this address.");
        UserProfile storage profile = userProfiles[_userAddress];
        return (profile.username, profile.profileDetails, profile.reputationScore);
    }

    // -------------------- Skill/Tag Management Functions --------------------

    /// @notice Allows the contract owner to add new skill tags.
    /// @param _tagName The name of the skill tag (e.g., "Solidity Development").
    /// @param _tagDescription A description of the skill tag.
    function addSkillTag(string memory _tagName, string memory _tagDescription) external onlyOwner whenNotPaused {
        require(bytes(_tagName).length > 0 && bytes(_tagName).length <= 50, "Tag name must be between 1 and 50 characters.");

        skillTags[nextSkillTagId] = SkillTag({
            tagId: nextSkillTagId,
            tagName: _tagName,
            tagDescription: _tagDescription,
            isActive: true
        });
        emit SkillTagAdded(nextSkillTagId, _tagName);
        nextSkillTagId++;
    }

    /// @notice Retrieves details of a specific skill tag.
    /// @param _tagId The ID of the skill tag.
    /// @return tagId The ID of the skill tag.
    /// @return tagName The name of the skill tag.
    /// @return tagDescription The description of the skill tag.
    /// @return isActive Whether the skill tag is active.
    function getSkillTagDetails(uint256 _tagId) external view whenNotPaused returns (uint256 tagId, string memory tagName, string memory tagDescription, bool isActive) {
        require(skillTags[_tagId].tagId != 0, "Skill tag does not exist.");
        SkillTag storage tag = skillTags[_tagId];
        return (tag.tagId, tag.tagName, tag.tagDescription, tag.isActive);
    }

    /// @notice Lists all available skill tags.
    /// @return tagIds An array of all active skill tag IDs.
    function listAllSkillTags() external view whenNotPaused returns (uint256[] memory tagIds) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextSkillTagId; i++) {
            if (skillTags[i].isActive) {
                count++;
            }
        }
        tagIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextSkillTagId; i++) {
            if (skillTags[i].isActive) {
                tagIds[index] = i;
                index++;
            }
        }
        return tagIds;
    }


    // -------------------- Endorsement and Reputation Functions --------------------

    /// @notice Allows a user to endorse another user for a specific skill.
    /// @param _targetUser The address of the user being endorsed.
    /// @param _skillTagId The ID of the skill tag for which the user is being endorsed.
    /// @param _endorsementMessage An optional message accompanying the endorsement.
    function endorseUser(address _targetUser, uint256 _skillTagId, string memory _endorsementMessage) external whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "Endorser profile does not exist. Create one first.");
        require(userProfiles[_targetUser].username.length > 0, "Endorsed user profile does not exist.");
        require(msg.sender != _targetUser, "Cannot endorse yourself.");
        require(skillTags[_skillTagId].isActive, "Skill tag is not active.");
        require(!userEndorsedForSkill[msg.sender][_skillTagId], "You have already endorsed this user for this skill.");

        endorsements[nextEndorsementId] = Endorsement({
            endorsementId: nextEndorsementId,
            endorser: msg.sender,
            endorsedUser: _targetUser,
            skillTagId: _skillTagId,
            endorsementMessage: _endorsementMessage,
            timestamp: block.timestamp,
            isActive: true
        });

        userEndorsedForSkill[msg.sender][_skillTagId] = true; // Mark as endorsed to prevent duplicates

        emit UserEndorsed(nextEndorsementId, msg.sender, _targetUser, _skillTagId);
        calculateUserReputation(_targetUser); // Update reputation of the endorsed user
        nextEndorsementId++;
    }

    /// @notice Retrieves all endorsements received by a user.
    /// @param _userAddress The address of the user.
    /// @return An array of endorsement IDs received by the user.
    function getEndorsementsForUser(address _userAddress) external view whenNotPaused returns (uint256[] memory endorsementIds) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextEndorsementId; i++) {
            if (endorsements[i].endorsedUser == _userAddress && endorsements[i].isActive) {
                count++;
            }
        }
        endorsementIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextEndorsementId; i++) {
            if (endorsements[i].endorsedUser == _userAddress && endorsements[i].isActive) {
                endorsementIds[index] = i;
                index++;
            }
        }
        return endorsementIds;
    }

    /// @notice Retrieves endorsements for a user for a specific skill tag.
    /// @param _userAddress The address of the user.
    /// @param _skillTagId The ID of the skill tag.
    /// @return An array of endorsement IDs for the specific skill tag.
    function getEndorsementsBySkillTag(address _userAddress, uint256 _skillTagId) external view whenNotPaused returns (uint256[] memory endorsementIds) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextEndorsementId; i++) {
            if (endorsements[i].endorsedUser == _userAddress && endorsements[i].skillTagId == _skillTagId && endorsements[i].isActive) {
                count++;
            }
        }
        endorsementIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i < nextEndorsementId; i++) {
            if (endorsements[i].endorsedUser == _userAddress && endorsements[i].skillTagId == _skillTagId && endorsements[i].isActive) {
                endorsementIds[index] = i;
                index++;
            }
        }
        return endorsementIds;
    }

    /// @notice Calculates and updates a user's reputation score based on endorsements and staking.
    /// @param _userAddress The address of the user whose reputation is being calculated.
    function calculateUserReputation(address _userAddress) internal whenNotPaused {
        uint256 reputation = 0;
        uint256 endorsementCount = 0;

        // Apply reputation decay first
        applyReputationDecay(_userAddress);

        for (uint256 i = 1; i < nextEndorsementId; i++) {
            if (endorsements[i].endorsedUser == _userAddress && endorsements[i].isActive) {
                // Simple reputation calculation: +1 per endorsement (can be made more sophisticated)
                reputation += 1;
                endorsementCount++;
            }
        }

        // Apply staking boost (example: 1 staked token = +0.1 reputation, can be adjusted)
        reputation += (userProfiles[_userAddress].stakedReputation / 10); // Example: 10 staked tokens for +1 reputation

        userProfiles[_userAddress].reputationScore = reputation;
        userProfiles[_userAddress].lastReputationUpdate = block.timestamp;
        emit ReputationScoreUpdated(_userAddress, reputation);

        // Reputation token issuance based on milestones (example: 1 token per 10 reputation points)
        if (reputation % 10 == 0 && reputation > 0 && reputation != userProfiles[_userAddress].reputationScore) { // Issue tokens on milestones
            uint256 tokensToIssue = (reputation / 10) - (userProfiles[_userAddress].reputationScore / 10); // Issue only the difference
            if (tokensToIssue > 0) {
                issueReputationToken(_userAddress, tokensToIssue);
            }
        }
    }

    /// @notice Retrieves a user's current reputation score.
    /// @param _userAddress The address of the user.
    /// @return The user's reputation score.
    function getUserReputationScore(address _userAddress) external view whenNotPaused returns (uint256) {
        applyReputationDecay(_userAddress); // Apply decay on view to keep score updated when viewed
        return userProfiles[_userAddress].reputationScore;
    }

    /// @notice Issues reputation tokens to a user (internal, based on reputation milestones).
    /// @param _userAddress The address of the user to receive tokens.
    /// @param _amount The amount of reputation tokens to issue.
    function issueReputationToken(address _userAddress, uint256 _amount) internal {
        reputationTokenBalance[_userAddress] += _amount;
        emit ReputationTokenIssued(_userAddress, _amount);
    }

    /// @notice Retrieves the amount of reputation tokens staked by a user.
    /// @param _userAddress The address of the user.
    /// @return The amount of staked reputation tokens.
    function getStakedReputation(address _userAddress) external view whenNotPaused returns (uint256) {
        return userProfiles[_userAddress].stakedReputation;
    }

    /// @notice Allows a user to stake their reputation tokens to boost their reputation score.
    /// @param _amount The amount of reputation tokens to stake.
    function stakeReputationToken(uint256 _amount) external whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "Profile does not exist. Create one first.");
        require(reputationTokenBalance[msg.sender] >= _amount, "Insufficient reputation token balance.");
        require(_amount > 0, "Amount to stake must be greater than zero.");

        reputationTokenBalance[msg.sender] -= _amount;
        userProfiles[msg.sender].stakedReputation += _amount;
        calculateUserReputation(msg.sender); // Recalculate reputation after staking
        emit ReputationStaked(msg.sender, _amount);
    }

    /// @notice Allows a user to unstake their reputation tokens.
    /// @param _amount The amount of reputation tokens to unstake.
    function unstakeReputationToken(uint256 _amount) external whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "Profile does not exist. Create one first.");
        require(userProfiles[msg.sender].stakedReputation >= _amount, "Insufficient staked reputation tokens.");
        require(_amount > 0, "Amount to unstake must be greater than zero.");

        userProfiles[msg.sender].stakedReputation -= _amount;
        reputationTokenBalance[msg.sender] += _amount;
        calculateUserReputation(msg.sender); // Recalculate reputation after unstaking
        emit ReputationUnstaked(msg.sender, _amount);
    }

    // -------------------- Reputation Dynamics and Decay Functions --------------------

    /// @notice Applies a decay factor to a user's reputation score over time.
    /// @param _userAddress The address of the user whose reputation is being decayed.
    function applyReputationDecay(address _userAddress) internal whenNotPaused {
        UserProfile storage profile = userProfiles[_userAddress];
        if (profile.username.length > 0) {
            uint256 timeElapsed = block.timestamp - profile.lastReputationUpdate;
            uint256 decayPercentage = (reputationDecayRate * timeElapsed) / (365 days); // Example: Decay per year (adjust time unit as needed)
            uint256 reputationLoss = (profile.reputationScore * decayPercentage) / 100;

            if (reputationLoss > profile.reputationScore) { // Prevent score from going negative
                reputationLoss = profile.reputationScore;
            }

            if (reputationLoss > 0) {
                profile.reputationScore -= reputationLoss;
                profile.lastReputationUpdate = block.timestamp;
                emit ReputationDecayApplied(_userAddress, profile.reputationScore);
            }
        }
    }


    /// @notice Allows the contract owner to manually boost a user's reputation (e.g., for early adopters, special contributions).
    /// @param _userAddress The address of the user to boost.
    /// @param _boostAmount The amount to boost the reputation by.
    function boostReputation(address _userAddress, uint256 _boostAmount) external onlyOwner whenNotPaused {
        require(userProfiles[_userAddress].username.length > 0, "Profile does not exist for this address.");
        userProfiles[_userAddress].reputationScore += _boostAmount;
        userProfiles[_userAddress].lastReputationUpdate = block.timestamp; // Update timestamp to avoid immediate decay
        emit ReputationBoosted(msg.sender, _userAddress, _boostAmount);
        emit ReputationScoreUpdated(_userAddress, userProfiles[_userAddress].reputationScore);
    }

    // -------------------- Dispute Resolution Functions --------------------

    /// @notice Allows a user to report an endorsement as spam or inaccurate.
    /// @param _endorsementId The ID of the endorsement being reported.
    /// @param _reportReason The reason for reporting the endorsement.
    function reportEndorsement(uint256 _endorsementId, string memory _reportReason) external whenNotPaused {
        require(userProfiles[msg.sender].username.length > 0, "Profile does not exist. Create one first.");
        require(endorsements[_endorsementId].endorsementId == _endorsementId, "Endorsement does not exist.");
        require(endorsements[_endorsementId].isActive, "Endorsement is not active."); // Can only report active endorsements

        endorsementReports[nextReportId] = EndorsementReport({
            reportId: nextReportId,
            endorsementId: _endorsementId,
            reporter: msg.sender,
            reportReason: _reportReason,
            upVotes: 0,
            downVotes: 0,
            isResolved: false,
            isSpam: false
        });
        emit EndorsementReported(nextReportId, _endorsementId, msg.sender);
        nextReportId++;
    }

    /// @notice Allows designated moderators (or reputation token holders in a more advanced version) to vote on a report.
    /// @param _reportId The ID of the endorsement report.
    /// @param _isSpam Boolean indicating whether the voter believes the endorsement is spam (true) or not (false).
    function voteOnEndorsementReport(uint256 _reportId, bool _isSpam) external whenNotPaused {
        require(endorsementReports[_reportId].reportId == _reportId, "Report does not exist.");
        require(!endorsementReports[_reportId].isResolved, "Report is already resolved.");

        // In a more advanced version, restrict to moderators or reputation token holders
        // For this example, anyone can vote (simplified for demonstration)

        if (_isSpam) {
            endorsementReports[_reportId].upVotes++; // "Spam" votes
        } else {
            endorsementReports[_reportId].downVotes++; // "Not Spam" votes
        }
        emit EndorsementReportVoted(_reportId, _isSpam, msg.sender);
    }

    /// @notice Resolves a reported endorsement based on voting results (removes endorsement if spam).
    /// @param _reportId The ID of the endorsement report to resolve.
    function resolveEndorsementReport(uint256 _reportId) external onlyOwner whenNotPaused {
        require(endorsementReports[_reportId].reportId == _reportId, "Report does not exist.");
        require(!endorsementReports[_reportId].isResolved, "Report is already resolved.");

        EndorsementReport storage report = endorsementReports[_reportId];

        if (report.upVotes > report.downVotes) { // Simple majority vote for spam
            report.isSpam = true;
            endorsements[report.endorsementId].isActive = false; // Deactivate the endorsement
            emit EndorsementReportResolved(_reportId, true, report.endorsementId);
        } else {
            report.isSpam = false;
            emit EndorsementReportResolved(_reportId, false, report.endorsementId);
        }
        report.isResolved = true;
    }

    // -------------------- Admin/Utility Functions --------------------

    /// @notice Allows the contract owner to pause the contract for maintenance.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows the contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to set the reputation decay rate.
    /// @param _newRate The new reputation decay rate (percentage).
    function setReputationDecayRate(uint256 _newRate) external onlyOwner whenNotPaused {
        reputationDecayRate = _newRate;
        emit ReputationDecayRateChanged(_newRate);
    }

    /// @notice Allows the contract owner to withdraw any accumulated contract balance (e.g., fees, if implemented).
    /// @param _recipient The address to receive the withdrawn balance.
    function withdrawContractBalance(address payable _recipient) external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract balance is zero.");
        (bool success, ) = _recipient.call{value: balance}("");
        require(success, "Withdrawal failed.");
        emit BalanceWithdrawn(_recipient, balance);
    }

    // Fallback function to receive Ether (if needed for future extensions like tipping)
    receive() external payable {}
}
```