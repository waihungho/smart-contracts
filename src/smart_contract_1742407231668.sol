```solidity
/**
 * @title Decentralized Skill & Reputation Oracle
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing decentralized skill verification and reputation scoring.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `registerUser(string _name)`: Allows users to register in the system with a name.
 * 2. `addSkill(string _skill)`: Registered users can add skills to their profile.
 * 3. `requestSkillVerification(address _verifier, string _skill)`: Users can request verification of a skill from another user (verifier).
 * 4. `verifySkill(uint _requestId, bool _isVerified)`: Verifiers can verify or reject a skill verification request.
 * 5. `getReputationScore(address _user)`: Returns the reputation score of a user based on successful skill verifications.
 * 6. `becomeVerifier(string[] _skills)`: Allows registered users to become verifiers for specific skills.
 * 7. `addVerifiedSkillToVerifier(string _skill)`: Verifiers can add more skills they are willing to verify.
 * 8. `removeVerifiedSkillFromVerifier(string _skill)`: Verifiers can remove skills they no longer want to verify.
 * 9. `getVerifierSkills(address _verifier)`: Returns the list of skills a verifier is currently verifying.
 * 10. `isVerifier(address _user)`: Checks if a user is registered as a verifier.
 *
 * **Advanced Features:**
 * 11. `endorseUser(address _endorsedUser, string _skill, string _endorsementMessage)`: Registered users can endorse other users for specific skills with a message.
 * 12. `getSkillEndorsements(address _user, string _skill)`: Retrieves endorsements received by a user for a specific skill.
 * 13. `reportUser(address _reportedUser, string _reason)`: Allows users to report other users for malicious activities or false claims.
 * 14. `moderateReport(uint _reportId, bool _isMalicious)`: Admin/Moderator function to review and moderate user reports.
 * 15. `getUserReportCount(address _user)`: Retrieves the number of active reports against a user.
 * 16. `setSkillReputationWeight(string _skill, uint _weight)`: Admin function to adjust the reputation weight of different skills.
 * 17. `getSkillReputationWeight(string _skill)`: Retrieves the reputation weight of a specific skill.
 * 18. `pauseContract()`: Admin function to pause the contract, halting critical functionalities.
 * 19. `unpauseContract()`: Admin function to unpause the contract, restoring functionalities.
 * 20. `withdrawContractBalance(address _recipient)`: Admin function to withdraw the contract's Ether balance (for potential fees or future features).
 * 21. `getUserProfile(address _user)`: Retrieves the entire profile data of a user, including name, skills, reputation, etc.
 * 22. `getVerificationRequestDetails(uint _requestId)`: Allows anyone to view details of a specific verification request.
 */
pragma solidity ^0.8.0;

contract SkillReputationOracle {
    // --- Data Structures ---
    struct UserProfile {
        string name;
        string[] skills;
        uint reputationScore;
        bool isVerifier;
    }

    struct VerifierProfile {
        string[] verifiedSkills;
    }

    struct VerificationRequest {
        address requester;
        address verifier;
        string skill;
        bool isVerified;
        bool isPending;
    }

    struct Endorsement {
        address endorser;
        string message;
        uint timestamp;
    }

    struct Report {
        address reporter;
        address reportedUser;
        string reason;
        bool isMalicious;
        bool isActive;
        uint timestamp;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(address => VerifierProfile) public verifierProfiles;
    mapping(uint => VerificationRequest) public verificationRequests;
    mapping(address => mapping(string => Endorsement[])) public skillEndorsements;
    mapping(uint => Report) public reports;
    mapping(string => uint) public skillReputationWeights; // Weight for each skill in reputation calculation. Default 1.
    uint public verificationRequestCount = 0;
    uint public reportCount = 0;
    address public admin;
    bool public paused = false;

    // --- Events ---
    event UserRegistered(address user, string name);
    event SkillAdded(address user, string skill);
    event VerificationRequested(uint requestId, address requester, address verifier, string skill);
    event SkillVerified(uint requestId, address verifier, bool isVerified);
    event ReputationScoreUpdated(address user, uint newScore);
    event VerifierRegistered(address verifier, string[] skills);
    event VerifierSkillAdded(address verifier, string skill);
    event VerifierSkillRemoved(address verifier, string skill);
    event UserEndorsed(address endorser, address endorsedUser, string skill, string message);
    event UserReported(uint reportId, address reporter, address reportedUser, string reason);
    event ReportModerated(uint reportId, bool isMalicious);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BalanceWithdrawn(address admin, address recipient, uint amount);
    event SkillReputationWeightSet(string skill, uint weight);

    // --- Modifiers ---
    modifier onlyUser() {
        require(userProfiles[msg.sender].name.length > 0, "User not registered.");
        _;
    }

    modifier onlyVerifier() {
        require(verifierProfiles[msg.sender].verifiedSkills.length > 0, "Not a registered verifier.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Core Functions ---
    /// @notice Registers a new user in the system.
    /// @param _name The name of the user.
    function registerUser(string memory _name) external whenNotPaused {
        require(userProfiles[msg.sender].name.length == 0, "User already registered.");
        userProfiles[msg.sender] = UserProfile({
            name: _name,
            skills: new string[](0),
            reputationScore: 0,
            isVerifier: false
        });
        emit UserRegistered(msg.sender, _name);
    }

    /// @notice Adds a skill to the user's profile.
    /// @param _skill The skill to add.
    function addSkill(string memory _skill) external onlyUser whenNotPaused {
        bool skillExists = false;
        for (uint i = 0; i < userProfiles[msg.sender].skills.length; i++) {
            if (keccak256(abi.encodePacked(userProfiles[msg.sender].skills[i])) == keccak256(abi.encodePacked(_skill))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Skill already added.");
        userProfiles[msg.sender].skills.push(_skill);
        emit SkillAdded(msg.sender, _skill);
    }

    /// @notice Requests skill verification from another user (verifier).
    /// @param _verifier The address of the user to verify the skill.
    /// @param _skill The skill to be verified.
    function requestSkillVerification(address _verifier, string memory _skill) external onlyUser whenNotPaused {
        require(isVerifier(_verifier), "Recipient is not a verifier.");
        bool canVerifySkill = false;
        for (uint i = 0; i < verifierProfiles[_verifier].verifiedSkills.length; i++) {
            if (keccak256(abi.encodePacked(verifierProfiles[_verifier].verifiedSkills[i])) == keccak256(abi.encodePacked(_skill))) {
                canVerifySkill = true;
                break;
            }
        }
        require(canVerifySkill, "Verifier does not verify this skill.");
        verificationRequests[verificationRequestCount] = VerificationRequest({
            requester: msg.sender,
            verifier: _verifier,
            skill: _skill,
            isVerified: false,
            isPending: true
        });
        emit VerificationRequested(verificationRequestCount, msg.sender, _verifier, _skill);
        verificationRequestCount++;
    }

    /// @notice Verifies or rejects a skill verification request.
    /// @param _requestId The ID of the verification request.
    /// @param _isVerified True if verified, false if rejected.
    function verifySkill(uint _requestId, bool _isVerified) external onlyVerifier whenNotPaused {
        require(verificationRequests[_requestId].verifier == msg.sender, "Not authorized to verify this request.");
        require(verificationRequests[_requestId].isPending, "Verification request is not pending.");
        verificationRequests[_requestId].isVerified = _isVerified;
        verificationRequests[_requestId].isPending = false;
        emit SkillVerified(_requestId, msg.sender, _isVerified);

        if (_isVerified) {
            _updateReputationScore(verificationRequests[_requestId].requester, verificationRequests[_requestId].skill);
        }
    }

    /// @notice Calculates and updates the reputation score of a user.
    /// @param _user The address of the user to update the reputation score for.
    /// @param _skill The skill that was just verified (for weight consideration).
    function _updateReputationScore(address _user, string memory _skill) private {
        uint skillWeight = skillReputationWeights[_skill];
        if (skillWeight == 0) {
            skillWeight = 1; // Default weight if not set
        }
        userProfiles[_user].reputationScore += skillWeight; // Simple increment, can be made more complex
        emit ReputationScoreUpdated(_user, userProfiles[_user].reputationScore);
    }

    /// @notice Gets the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getReputationScore(address _user) external view returns (uint) {
        return userProfiles[_user].reputationScore;
    }

    /// @notice Allows a user to become a verifier for a list of skills.
    /// @param _skills An array of skills the user can verify.
    function becomeVerifier(string[] memory _skills) external onlyUser whenNotPaused {
        require(!userProfiles[msg.sender].isVerifier, "Already a verifier.");
        userProfiles[msg.sender].isVerifier = true;
        verifierProfiles[msg.sender] = VerifierProfile({
            verifiedSkills: _skills
        });
        emit VerifierRegistered(msg.sender, _skills);
    }

    /// @notice Adds a skill to the list of skills a verifier can verify.
    /// @param _skill The skill to add.
    function addVerifiedSkillToVerifier(string memory _skill) external onlyVerifier whenNotPaused {
        bool skillExists = false;
        for (uint i = 0; i < verifierProfiles[msg.sender].verifiedSkills.length; i++) {
            if (keccak256(abi.encodePacked(verifierProfiles[msg.sender].verifiedSkills[i])) == keccak256(abi.encodePacked(_skill))) {
                skillExists = true;
                break;
            }
        }
        require(!skillExists, "Verifier already verifies this skill.");
        verifierProfiles[msg.sender].verifiedSkills.push(_skill);
        emit VerifierSkillAdded(msg.sender, _skill);
    }

    /// @notice Removes a skill from the list of skills a verifier can verify.
    /// @param _skill The skill to remove.
    function removeVerifiedSkillFromVerifier(string memory _skill) external onlyVerifier whenNotPaused {
        bool skillExists = false;
        uint skillIndex = 0;
        for (uint i = 0; i < verifierProfiles[msg.sender].verifiedSkills.length; i++) {
            if (keccak256(abi.encodePacked(verifierProfiles[msg.sender].verifiedSkills[i])) == keccak256(abi.encodePacked(_skill))) {
                skillExists = true;
                skillIndex = i;
                break;
            }
        }
        require(skillExists, "Verifier does not verify this skill.");
        // Remove skill from array (shift elements)
        for (uint j = skillIndex; j < verifierProfiles[msg.sender].verifiedSkills.length - 1; j++) {
            verifierProfiles[msg.sender].verifiedSkills[j] = verifierProfiles[msg.sender].verifiedSkills[j + 1];
        }
        verifierProfiles[msg.sender].verifiedSkills.pop();
        emit VerifierSkillRemoved(msg.sender, _skill);
    }

    /// @notice Gets the list of skills a verifier is currently verifying.
    /// @param _verifier The address of the verifier.
    /// @return An array of skills the verifier verifies.
    function getVerifierSkills(address _verifier) external view returns (string[] memory) {
        return verifierProfiles[_verifier].verifiedSkills;
    }

    /// @notice Checks if a user is registered as a verifier.
    /// @param _user The address of the user.
    /// @return True if the user is a verifier, false otherwise.
    function isVerifier(address _user) external view returns (bool) {
        return userProfiles[_user].isVerifier;
    }

    // --- Advanced Features ---
    /// @notice Allows a user to endorse another user for a specific skill.
    /// @param _endorsedUser The user being endorsed.
    /// @param _skill The skill for which the user is being endorsed.
    /// @param _endorsementMessage A message accompanying the endorsement.
    function endorseUser(address _endorsedUser, string memory _skill, string memory _endorsementMessage) external onlyUser whenNotPaused {
        require(userProfiles[_endorsedUser].name.length > 0, "Endorsed user is not registered.");
        skillEndorsements[_endorsedUser][_skill].push(Endorsement({
            endorser: msg.sender,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));
        emit UserEndorsed(msg.sender, _endorsedUser, _skill, _endorsementMessage);
    }

    /// @notice Retrieves endorsements received by a user for a specific skill.
    /// @param _user The address of the user.
    /// @param _skill The skill to retrieve endorsements for.
    /// @return An array of endorsements for the skill.
    function getSkillEndorsements(address _user, string memory _skill) external view returns (Endorsement[] memory) {
        return skillEndorsements[_user][_skill];
    }

    /// @notice Allows a user to report another user for malicious activities or false claims.
    /// @param _reportedUser The user being reported.
    /// @param _reason The reason for the report.
    function reportUser(address _reportedUser, string memory _reason) external onlyUser whenNotPaused {
        require(userProfiles[_reportedUser].name.length > 0, "Reported user is not registered.");
        reports[reportCount] = Report({
            reporter: msg.sender,
            reportedUser: _reportedUser,
            reason: _reason,
            isMalicious: false, // Initially set to false, admin needs to moderate
            isActive: true,
            timestamp: block.timestamp
        });
        emit UserReported(reportCount, msg.sender, _reportedUser, _reason);
        reportCount++;
    }

    /// @notice Admin/Moderator function to review and moderate user reports.
    /// @param _reportId The ID of the report to moderate.
    /// @param _isMalicious True if the report is considered malicious, false otherwise.
    function moderateReport(uint _reportId, bool _isMalicious) external onlyAdmin whenNotPaused {
        require(reports[_reportId].isActive, "Report is not active.");
        reports[_reportId].isMalicious = _isMalicious;
        reports[_reportId].isActive = false; // Mark report as resolved
        emit ReportModerated(_reportId, _isMalicious);
        // Future: Implement actions based on _isMalicious, e.g., reputation penalty for reported user.
    }

    /// @notice Retrieves the number of active reports against a user.
    /// @param _user The address of the user.
    /// @return The number of active reports.
    function getUserReportCount(address _user) external view returns (uint) {
        uint activeReportCount = 0;
        for (uint i = 0; i < reportCount; i++) {
            if (reports[i].isActive && reports[i].reportedUser == _user) {
                activeReportCount++;
            }
        }
        return activeReportCount;
    }

    /// @notice Admin function to set the reputation weight for a specific skill.
    /// @param _skill The skill to set the weight for.
    /// @param _weight The reputation weight (e.g., higher weight for more valuable skills).
    function setSkillReputationWeight(string memory _skill, uint _weight) external onlyAdmin whenNotPaused {
        skillReputationWeights[_skill] = _weight;
        emit SkillReputationWeightSet(_skill, _weight);
    }

    /// @notice Gets the reputation weight for a specific skill.
    /// @param _skill The skill to query.
    /// @return The reputation weight of the skill.
    function getSkillReputationWeight(string memory _skill) external view returns (uint) {
        return skillReputationWeights[_skill];
    }

    // --- Admin Functions ---
    /// @notice Pauses the contract, preventing critical functionalities.
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Unpauses the contract, restoring functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Allows the admin to withdraw the contract's Ether balance.
    /// @param _recipient The address to receive the withdrawn Ether.
    function withdrawContractBalance(address _recipient) external onlyAdmin {
        uint balance = address(this).balance;
        payable(_recipient).transfer(balance);
        emit BalanceWithdrawn(admin, _recipient, balance);
    }

    // --- Getter Functions for Structs ---
    /// @notice Retrieves the entire user profile data.
    /// @param _user The address of the user.
    /// @return UserProfile struct containing user's data.
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    /// @notice Retrieves details of a specific verification request.
    /// @param _requestId The ID of the verification request.
    /// @return VerificationRequest struct containing request details.
    function getVerificationRequestDetails(uint _requestId) external view returns (VerificationRequest memory) {
        return verificationRequests[_requestId];
    }
}
```