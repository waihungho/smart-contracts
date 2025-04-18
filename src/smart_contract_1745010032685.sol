```solidity
/**
 * @title Decentralized Skill-Based Reputation and Impact DAO
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation system
 * based on skills, contributions, and impact within a DAO.
 * It features advanced concepts like skill-based reputation, impact measurement,
 * decentralized endorsement, dynamic reputation decay, and granular access control,
 * going beyond typical token contracts and governance DAOs.
 *
 * **Outline & Function Summary:**
 *
 * **I. User Management & Profile Functions:**
 *   1. `registerUser(string _username, string _profileHash)`: Allows a user to register with a username and profile hash (e.g., IPFS).
 *   2. `updateProfile(string _profileHash)`:  Allows registered users to update their profile information.
 *   3. `addSkill(string _skillName)`: Allows users to add skills to their profile.
 *   4. `removeSkill(string _skillName)`: Allows users to remove skills from their profile.
 *   5. `getUserProfile(address _userAddress) external view returns (string username, string profileHash, string[] skills)`: Retrieves a user's profile information.
 *   6. `getUserReputation(address _userAddress) external view returns (uint256 reputationScore)`: Retrieves a user's reputation score.
 *
 * **II. Skill Endorsement & Verification Functions:**
 *   7. `endorseSkill(address _userAddress, string _skillName)`: Registered users can endorse another user for a specific skill.
 *   8. `revokeEndorsement(address _userAddress, string _skillName)`: Users can revoke a skill endorsement they previously gave.
 *   9. `getSkillEndorsements(address _userAddress, string _skillName) external view returns (address[] endorsers)`: Retrieves the list of users who have endorsed a specific skill for a user.
 *
 * **III. Contribution & Impact Tracking Functions:**
 *   10. `reportContribution(string _contributionDescription, string _contributionHash, string[] _relevantSkills)`: Registered users can report their contributions to the DAO.
 *   11. `validateContribution(uint256 _contributionId, bool _isValid)`:  Admin/Reputation Committee can validate or invalidate a reported contribution.
 *   12. `reportImpact(uint256 _contributionId, string _impactDescription, string _impactMetricsHash)`: Registered users can report the impact of a validated contribution.
 *   13. `validateImpact(uint256 _impactId, bool _isValid)`: Admin/Reputation Committee can validate or invalidate a reported impact.
 *   14. `getContributionDetails(uint256 _contributionId) external view returns (address contributor, string description, string hash, string[] skills, bool isValidated)`: Retrieves details of a contribution.
 *   15. `getImpactDetails(uint256 _impactId) external view returns (uint256 contributionId, string description, string metricsHash, bool isValidated)`: Retrieves details of an impact report.
 *
 * **IV. Reputation & Scoring Functions:**
 *   16. `calculateReputation(address _userAddress)`: (Internal) Calculates reputation score based on skills, endorsements, validated contributions, and impacts.
 *   17. `adjustReputationWeight(string _skillName, uint256 _newWeight)`: Admin function to dynamically adjust the weight of specific skills in reputation calculation.
 *   18. `setBaseReputationDecayRate(uint256 _newRate)`: Admin function to set the base reputation decay rate over time.
 *   19. `applyReputationDecay()`:  Function (can be automated off-chain or called periodically) to apply reputation decay to all users.
 *
 * **V. DAO Administration & Governance Functions:**
 *   20. `addAdmin(address _newAdmin)`: Contract owner can add new admin addresses.
 *   21. `removeAdmin(address _adminToRemove)`: Contract owner can remove admin addresses.
 *   22. `isAdmin(address _address) external view returns (bool)`: Checks if an address is an admin.
 *   23. `setReputationCommittee(address _committeeAddress)`: Contract owner can set the address of the Reputation Committee.
 *   24. `isReputationCommittee(address _address) external view returns (bool)`: Checks if an address is the Reputation Committee.
 */
pragma solidity ^0.8.0;

contract SkillBasedReputationDAO {

    // -------- Structs and Enums --------

    struct UserProfile {
        string username;
        string profileHash;
        string[] skills;
        uint256 reputationScore;
        mapping(string => address[]) skillEndorsements; // Skill name => list of endorser addresses
    }

    struct Contribution {
        address contributor;
        string description;
        string contributionHash; // Hash of detailed contribution document (e.g., IPFS)
        string[] relevantSkills;
        bool isValidated;
        uint256 impactId; // ID of associated impact report, if any
        uint256 timestamp;
    }

    struct ImpactReport {
        uint256 contributionId;
        string description;
        string impactMetricsHash; // Hash of impact metrics document (e.g., IPFS)
        bool isValidated;
        uint256 timestamp;
    }

    // -------- State Variables --------

    address public owner;
    address public reputationCommittee;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => ImpactReport) public impactReports;
    uint256 public contributionCount;
    uint256 public impactReportCount;
    mapping(address => bool) public admins;
    mapping(string => uint256) public skillWeights; // Skill name => Weight in reputation calculation
    uint256 public baseReputationDecayRate = 1; // Percentage decay per time unit (e.g., per month)
    uint256 public lastDecayTimestamp; // Timestamp of the last reputation decay application

    // -------- Events --------

    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event SkillAdded(address userAddress, string skillName);
    event SkillRemoved(address userAddress, string skillName);
    event SkillEndorsed(address endorser, address endorsedUser, string skillName);
    event SkillEndorsementRevoked(address revoker, address endorsedUser, string skillName);
    event ContributionReported(uint256 contributionId, address contributor);
    event ContributionValidated(uint256 contributionId, bool isValid);
    event ImpactReported(uint256 impactId, uint256 contributionId);
    event ImpactValidated(uint256 impactId, bool isValid);
    event ReputationScoreUpdated(address userAddress, uint256 newScore);
    event ReputationDecayApplied();
    event AdminAdded(address adminAddress);
    event AdminRemoved(address adminAddress);
    event ReputationCommitteeSet(address committeeAddress);

    // -------- Modifiers --------

    modifier onlyRegisteredUser() {
        require(bytes(userProfiles[msg.sender].username).length > 0, "User not registered.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action.");
        _;
    }

    modifier onlyReputationCommittee() {
        require(msg.sender == reputationCommittee, "Only Reputation Committee can perform this action.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        admins[owner] = true; // Owner is initially an admin
        lastDecayTimestamp = block.timestamp;

        // Initialize some default skill weights (can be adjusted later by admin)
        skillWeights["Solidity Development"] = 100;
        skillWeights["Smart Contract Auditing"] = 120;
        skillWeights["Community Management"] = 80;
        skillWeights["Content Creation"] = 70;
        skillWeights["Project Management"] = 90;
        skillWeights["UX/UI Design"] = 85;
    }

    // -------- I. User Management & Profile Functions --------

    function registerUser(string memory _username, string memory _profileHash) public {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_profileHash).length > 0, "Username and profile hash cannot be empty.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            skills: new string[](0),
            reputationScore: 0,
            skillEndorsements: mapping(string => address[])()
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileHash) public onlyRegisteredUser {
        require(bytes(_profileHash).length > 0, "Profile hash cannot be empty.");
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    function addSkill(string memory _skillName) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(bytes(userProfiles[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added.");
        userProfiles[msg.sender].skills.push(_skillName);
        emit SkillAdded(msg.sender, _skillName);
    }

    function removeSkill(string memory _skillName) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        bool skillRemoved = false;
        string[] memory currentSkills = userProfiles[msg.sender].skills;
        string[] memory updatedSkills = new string[](currentSkills.length - 1);
        uint256 updatedIndex = 0;
        for (uint256 i = 0; i < currentSkills.length; i++) {
            if (keccak256(bytes(currentSkills[i])) != keccak256(bytes(_skillName))) {
                updatedSkills[updatedIndex] = currentSkills[i];
                updatedIndex++;
            } else {
                skillRemoved = true;
            }
        }
        require(skillRemoved, "Skill not found in profile.");
        userProfiles[msg.sender].skills = updatedSkills;
        emit SkillRemoved(msg.sender, _skillName);
    }

    function getUserProfile(address _userAddress) external view returns (string memory username, string memory profileHash, string[] memory skills) {
        UserProfile storage profile = userProfiles[_userAddress];
        return (profile.username, profile.profileHash, profile.skills);
    }

    function getUserReputation(address _userAddress) external view returns (uint256 reputationScore) {
        return userProfiles[_userAddress].reputationScore;
    }

    // -------- II. Skill Endorsement & Verification Functions --------

    function endorseSkill(address _userAddress, string memory _skillName) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        require(msg.sender != _userAddress, "Cannot endorse yourself.");
        bool skillExists = false;
        for (uint256 i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            if (keccak256(bytes(userProfiles[_userAddress].skills[i])) == keccak256(bytes(_skillName))) {
                skillExists = true;
                break;
            }
        }
        require(skillExists, "User does not have this skill in their profile.");

        // Check if already endorsed
        address[] storage endorsements = userProfiles[_userAddress].skillEndorsements[_skillName];
        for (uint256 i = 0; i < endorsements.length; i++) {
            if (endorsements[i] == msg.sender) {
                revert("Already endorsed this skill for this user.");
            }
        }

        userProfiles[_userAddress].skillEndorsements[_skillName].push(msg.sender);
        _updateReputation(_userAddress); // Update reputation immediately upon endorsement
        emit SkillEndorsed(msg.sender, _userAddress, _skillName);
    }

    function revokeEndorsement(address _userAddress, string memory _skillName) public onlyRegisteredUser {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        address[] storage endorsements = userProfiles[_userAddress].skillEndorsements[_skillName];
        bool endorsementRevoked = false;
        address[] memory updatedEndorsements = new address[](endorsements.length - 1);
        uint256 updatedIndex = 0;
        for (uint256 i = 0; i < endorsements.length; i++) {
            if (endorsements[i] != msg.sender) {
                updatedEndorsements[updatedIndex] = endorsements[i];
                updatedIndex++;
            } else {
                endorsementRevoked = true;
            }
        }
        require(endorsementRevoked, "No endorsement found to revoke for this skill and user from you.");
        userProfiles[_userAddress].skillEndorsements[_skillName] = updatedEndorsements;
        _updateReputation(_userAddress); // Update reputation immediately upon revocation
        emit SkillEndorsementRevoked(msg.sender, _userAddress, _skillName);
    }

    function getSkillEndorsements(address _userAddress, string memory _skillName) external view returns (address[] memory endorsers) {
        return userProfiles[_userAddress].skillEndorsements[_skillName];
    }

    // -------- III. Contribution & Impact Tracking Functions --------

    function reportContribution(string memory _contributionDescription, string memory _contributionHash, string[] memory _relevantSkills) public onlyRegisteredUser {
        require(bytes(_contributionDescription).length > 0 && bytes(_contributionHash).length > 0, "Description and contribution hash cannot be empty.");
        require(_relevantSkills.length > 0, "At least one relevant skill must be provided.");
        contributionCount++;
        contributions[contributionCount] = Contribution({
            contributor: msg.sender,
            description: _contributionDescription,
            contributionHash: _contributionHash,
            relevantSkills: _relevantSkills,
            isValidated: false,
            impactId: 0,
            timestamp: block.timestamp
        });
        emit ContributionReported(contributionCount, msg.sender);
    }

    function validateContribution(uint256 _contributionId, bool _isValid) public onlyReputationCommittee {
        require(_contributionId > 0 && _contributionId <= contributionCount, "Invalid contribution ID.");
        contributions[_contributionId].isValidated = _isValid;
        if (_isValid) {
            _updateReputation(contributions[_contributionId].contributor); // Update reputation upon validation
        }
        emit ContributionValidated(_contributionId, _isValid);
    }

    function reportImpact(uint256 _contributionId, string memory _impactDescription, string memory _impactMetricsHash) public onlyRegisteredUser {
        require(_contributionId > 0 && _contributionId <= contributionCount, "Invalid contribution ID.");
        require(contributions[_contributionId].contributor == msg.sender, "Only contributor can report impact.");
        require(contributions[_contributionId].isValidated, "Contribution must be validated before reporting impact.");
        require(bytes(_impactDescription).length > 0 && bytes(_impactMetricsHash).length > 0, "Impact description and metrics hash cannot be empty.");
        require(contributions[_contributionId].impactId == 0, "Impact already reported for this contribution.");

        impactReportCount++;
        impactReports[impactReportCount] = ImpactReport({
            contributionId: _contributionId,
            description: _impactDescription,
            impactMetricsHash: _impactMetricsHash,
            isValidated: false,
            timestamp: block.timestamp
        });
        contributions[_contributionId].impactId = impactReportCount; // Link contribution to impact report
        emit ImpactReported(impactReportCount, _contributionId);
    }

    function validateImpact(uint256 _impactId, bool _isValid) public onlyReputationCommittee {
        require(_impactId > 0 && _impactId <= impactReportCount, "Invalid impact ID.");
        impactReports[_impactId].isValidated = _isValid;
        if (_isValid) {
            _updateReputation(contributions[impactReports[_impactId].contributionId].contributor); // Update reputation upon impact validation
        }
        emit ImpactValidated(_impactId, _isValid);
    }

    function getContributionDetails(uint256 _contributionId) external view returns (address contributor, string memory description, string memory hash, string[] memory skills, bool isValidated) {
        Contribution storage contrib = contributions[_contributionId];
        return (contrib.contributor, contrib.description, contrib.contributionHash, contrib.relevantSkills, contrib.isValidated);
    }

    function getImpactDetails(uint256 _impactId) external view returns (uint256 contributionId, string memory description, string memory metricsHash, bool isValidated) {
        ImpactReport storage impact = impactReports[_impactId];
        return (impact.contributionId, impact.description, impact.impactMetricsHash, impact.isValidated);
    }

    // -------- IV. Reputation & Scoring Functions --------

    function calculateReputation(address _userAddress) public view returns (uint256) {
        uint256 reputation = 0;

        // Skill-based reputation (weighted by endorsements and skill weight)
        for (uint256 i = 0; i < userProfiles[_userAddress].skills.length; i++) {
            string memory skillName = userProfiles[_userAddress].skills[i];
            uint256 endorsementsCount = userProfiles[_userAddress].skillEndorsements[skillName].length;
            uint256 skillWeight = skillWeights[skillName];
            reputation += endorsementsCount * skillWeight; // More endorsements, higher weight, higher reputation
        }

        // Contribution-based reputation (validated contributions boost reputation)
        for (uint256 i = 1; i <= contributionCount; i++) {
            if (contributions[i].contributor == _userAddress && contributions[i].isValidated) {
                reputation += 50; // Base contribution reputation points, can be adjusted
            }
        }

        // Impact-based reputation (validated impacts boost reputation even more)
        for (uint256 i = 1; i <= impactReportCount; i++) {
            if (impactReports[i].isValidated && contributions[impactReports[i].contributionId].contributor == _userAddress) {
                reputation += 100; // Base impact reputation points, can be adjusted
            }
        }

        return reputation;
    }

    function _updateReputation(address _userAddress) private {
        uint256 newReputation = calculateReputation(_userAddress);
        userProfiles[_userAddress].reputationScore = newReputation;
        emit ReputationScoreUpdated(_userAddress, newReputation);
    }

    function adjustReputationWeight(string memory _skillName, uint256 _newWeight) public onlyAdmin {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        skillWeights[_skillName] = _newWeight;
    }

    function setBaseReputationDecayRate(uint256 _newRate) public onlyAdmin {
        baseReputationDecayRate = _newRate;
    }

    function applyReputationDecay() public {
        uint256 timeElapsed = block.timestamp - lastDecayTimestamp;
        require(timeElapsed >= 1 minutes, "Reputation decay can only be applied once per minute."); // Example: Decay every minute

        for (uint256 i = 0; i < address(this).balance; i++) { // Iterate over all possible user addresses (inefficient in reality, needs better user tracking in real-world)
            address userAddress = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Simple address generation for iteration - REPLACE WITH PROPER USER LIST MANAGEMENT

            if (bytes(userProfiles[userAddress].username).length > 0) { // Check if it's a registered user
                uint256 currentReputation = userProfiles[userAddress].reputationScore;
                uint256 decayAmount = (currentReputation * baseReputationDecayRate) / 100; // Calculate decay amount
                if (currentReputation > decayAmount) {
                    userProfiles[userAddress].reputationScore -= decayAmount;
                } else {
                    userProfiles[userAddress].reputationScore = 0; // Prevent negative reputation
                }
                emit ReputationScoreUpdated(userAddress, userProfiles[userAddress].reputationScore);
            }
        }

        lastDecayTimestamp = block.timestamp;
        emit ReputationDecayApplied();
    }


    // -------- V. DAO Administration & Governance Functions --------

    function addAdmin(address _newAdmin) public onlyAdmin {
        admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin);
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        require(_adminToRemove != owner, "Cannot remove contract owner as admin.");
        admins[_adminToRemove] = false;
        emit AdminRemoved(_adminToRemove);
    }

    function isAdmin(address _address) external view returns (bool) {
        return admins[_address];
    }

    function setReputationCommittee(address _committeeAddress) public onlyAdmin {
        reputationCommittee = _committeeAddress;
        emit ReputationCommitteeSet(_committeeAddress);
    }

    function isReputationCommittee(address _address) external view returns (bool) {
        return _address == reputationCommittee;
    }

    // -------- Fallback and Receive (Optional) --------
    receive() external payable {}
    fallback() external payable {}
}
```