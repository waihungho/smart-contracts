```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Skill Oracle (DDRSO)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation and skill oracle system.
 *      This contract allows users to build on-chain reputation based on verifiable actions and skills.
 *      It incorporates advanced concepts like skill-based reputation, dynamic reputation decay,
 *      community endorsements, and on-chain verification mechanisms. It aims to provide
 *      a decentralized and transparent system for assessing and showcasing user abilities
 *      within a specific domain or community.
 *
 * Function Summary:
 *
 * 1.  registerProfile(): Allows users to register a profile with basic information and skills.
 * 2.  updateProfileMetadata(): Users can update their profile details (name, bio, etc.).
 * 3.  addSkill(): Users can add skills they possess, subject to verification.
 * 4.  requestSkillVerification(): Users request verification of a specific skill by the community.
 * 5.  endorseSkillVerification(): Community members can endorse a skill verification request.
 * 6.  reportSkillVerification(): Community members can report a fraudulent skill verification request.
 * 7.  verifySkill(): Admin function to finalize skill verification based on endorsements and reports.
 * 8.  revokeSkill(): Admin function to revoke a verified skill if found to be fraudulent later.
 * 9.  getProfile(): Retrieve a user's profile information and verified skills.
 * 10. getSkillVerificationStatus(): Check the verification status of a skill for a user.
 * 11. getReputationScore(): Calculate a reputation score based on verified skills and endorsements.
 * 12. endorseProfileReputation(): Registered users can endorse another user's overall reputation.
 * 13. reportProfileReputation(): Registered users can report another user's overall reputation (with reason).
 * 14. getProfileEndorsements(): View the number of endorsements a profile has received.
 * 15. getProfileReports(): View the number of reports a profile has received (for admin purposes).
 * 16. setSkillWeight(): Admin function to set the weight of a skill in reputation calculation.
 * 17. setReputationDecayRate(): Admin function to set the rate at which reputation decays over time.
 * 18. setVerificationThreshold(): Admin function to set the threshold for skill verification endorsements.
 * 19. withdrawContractBalance(): Admin function to withdraw any contract balance (e.g., for fees).
 * 20. pauseContract(): Admin function to pause critical functionalities of the contract.
 * 21. unpauseContract(): Admin function to resume contract functionalities.
 * 22. getContractStatus(): Public function to check if the contract is paused or active.
 * 23. migrateSkillVerificationData(): Admin function for potential data migration or upgrades.
 * 24. setCommunityThreshold(): Admin function to set the minimum number of community members needed for certain actions.
 */

contract DecentralizedDynamicReputationOracle {

    // --- Structs & Enums ---

    struct UserProfile {
        string name;
        string bio;
        uint256 registrationTimestamp;
        mapping(bytes32 => SkillVerification) skillVerifications; // skillHash => SkillVerification
        uint256 reputationScore;
        uint256 endorsementCount;
        uint256 reportCount;
    }

    struct SkillVerification {
        string skillName;
        bool isVerified;
        uint256 requestTimestamp;
        mapping(address => bool) endorsements; // endorser => endorsed
        uint256 endorsementCount;
        mapping(address => string) reports; // reporter => reportReason
        uint256 reportCount;
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(bytes32 => uint256) public skillWeights; // skillHash => weight in reputation score
    address public admin;
    uint256 public reputationDecayRate; // Percentage decay per time unit (e.g., per day)
    uint256 public lastReputationUpdate;
    uint256 public verificationThreshold; // Number of endorsements needed for auto-verification
    uint256 public communityThreshold; // Minimum community members for actions
    bool public paused;

    // --- Events ---

    event ProfileRegistered(address indexed user, string name, uint256 timestamp);
    event ProfileMetadataUpdated(address indexed user, string newName, string newBio);
    event SkillAdded(address indexed user, string skillName, bytes32 skillHash);
    event SkillVerificationRequested(address indexed user, string skillName, bytes32 skillHash, uint256 timestamp);
    event SkillVerificationEndorsed(address indexed user, bytes32 skillHash, address endorser);
    event SkillVerificationReported(address indexed user, bytes32 skillHash, address reporter, string reason);
    event SkillVerified(address indexed user, string skillName, bytes32 skillHash);
    event SkillRevoked(address indexed user, string skillName, bytes32 skillHash);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event ProfileReputationEndorsed(address indexed profileOwner, address endorser);
    event ProfileReputationReported(address indexed profileOwner, address reporter, string reason);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminUpdated(address newAdmin);

    // --- Modifiers ---

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

    modifier communityMemberOnly() {
        require(address(userProfiles[msg.sender]) != address(0) , "Must be a registered community member.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        reputationDecayRate = 1; // 1% decay per day (example)
        lastReputationUpdate = block.timestamp;
        verificationThreshold = 5; // 5 endorsements for auto-verification
        communityThreshold = 10; // Minimum 10 registered users to be considered a community
        paused = false;

        // Initialize some default skill weights (example - can be configured by admin)
        skillWeights[keccak256("Solidity Development")] = 100;
        skillWeights[keccak256("Smart Contract Auditing")] = 150;
        skillWeights[keccak256("Frontend Web3 Integration")] = 80;
    }

    // --- Identity & Profile Management Functions ---

    /// @notice Allows a user to register a profile in the system.
    /// @param _name User's display name.
    /// @param _bio Short biography or description of the user.
    function registerProfile(string memory _name, string memory _bio) external whenNotPaused {
        require(bytes(_name).length > 0 && bytes(_name).length <= 50, "Name must be between 1 and 50 characters.");
        require(bytes(_bio).length <= 200, "Bio must be at most 200 characters.");
        require(address(userProfiles[msg.sender]) == address(0), "Profile already registered.");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            registrationTimestamp: block.timestamp,
            reputationScore: 0,
            endorsementCount: 0,
            reportCount: 0
        });

        emit ProfileRegistered(msg.sender, _name, block.timestamp);
    }

    /// @notice Allows a user to update their profile metadata (name and bio).
    /// @param _newName New display name for the user.
    /// @param _newBio New biography for the user.
    function updateProfileMetadata(string memory _newName, string memory _newBio) external whenNotPaused communityMemberOnly {
        require(bytes(_newName).length > 0 && bytes(_newName).length <= 50, "Name must be between 1 and 50 characters.");
        require(bytes(_newBio).length <= 200, "Bio must be at most 200 characters.");

        userProfiles[msg.sender].name = _newName;
        userProfiles[msg.sender].bio = _newBio;

        emit ProfileMetadataUpdated(msg.sender, _newName, _newBio);
    }

    /// @notice Allows a user to add a skill to their profile, initiating the verification process.
    /// @param _skillName Name of the skill to be added.
    function addSkill(string memory _skillName) external whenNotPaused communityMemberOnly {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 50, "Skill name must be between 1 and 50 characters.");
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[msg.sender].skillVerifications[skillHash]) == address(0), "Skill already added.");

        userProfiles[msg.sender].skillVerifications[skillHash] = SkillVerification({
            skillName: _skillName,
            isVerified: false,
            requestTimestamp: 0, // Set to 0 initially, requestVerification will update
            endorsementCount: 0,
            reportCount: 0
        });

        emit SkillAdded(msg.sender, _skillName, skillHash);
    }

    /// @notice Allows a user to request verification for a specific skill they've added.
    /// @param _skillName Name of the skill to request verification for.
    function requestSkillVerification(string memory _skillName) external whenNotPaused communityMemberOnly {
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[msg.sender].skillVerifications[skillHash]) != address(0), "Skill not added to profile.");
        require(!userProfiles[msg.sender].skillVerifications[skillHash].isVerified, "Skill already verified.");
        require(userProfiles[msg.sender].skillVerifications[skillHash].requestTimestamp == 0, "Verification already requested.");

        userProfiles[msg.sender].skillVerifications[skillHash].requestTimestamp = block.timestamp;
        emit SkillVerificationRequested(msg.sender, _skillName, skillHash, block.timestamp);
    }

    /// @notice Allows registered community members to endorse a skill verification request.
    /// @param _profileOwner Address of the user whose skill is being verified.
    /// @param _skillName Name of the skill being verified.
    function endorseSkillVerification(address _profileOwner, string memory _skillName) external whenNotPaused communityMemberOnly {
        require(_profileOwner != msg.sender, "Cannot endorse your own skill verification.");
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[_profileOwner].skillVerifications[skillHash]) != address(0), "Skill not found for profile owner.");
        require(!userProfiles[_profileOwner].skillVerifications[skillHash].isVerified, "Skill already verified.");
        require(userProfiles[_profileOwner].skillVerifications[skillHash].requestTimestamp > 0, "Verification not requested yet.");
        require(!userProfiles[_profileOwner].skillVerifications[skillHash].endorsements[msg.sender], "Already endorsed this skill verification.");

        userProfiles[_profileOwner].skillVerifications[skillHash].endorsements[msg.sender] = true;
        userProfiles[_profileOwner].skillVerifications[skillHash].endorsementCount++;

        emit SkillVerificationEndorsed(_profileOwner, skillHash, msg.sender);

        // Auto-verify if threshold is reached
        if (userProfiles[_profileOwner].skillVerifications[skillHash].endorsementCount >= verificationThreshold) {
            verifySkill(_profileOwner, _skillName);
        }
    }

    /// @notice Allows registered community members to report a skill verification request as fraudulent.
    /// @param _profileOwner Address of the user whose skill verification is being reported.
    /// @param _skillName Name of the skill being reported.
    /// @param _reason Reason for reporting the skill verification.
    function reportSkillVerification(address _profileOwner, string memory _skillName, string memory _reason) external whenNotPaused communityMemberOnly {
        require(_profileOwner != msg.sender, "Cannot report your own skill verification.");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 200, "Report reason must be between 1 and 200 characters.");
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[_profileOwner].skillVerifications[skillHash]) != address(0), "Skill not found for profile owner.");
        require(!userProfiles[_profileOwner].skillVerifications[skillHash].isVerified, "Skill already verified.");
        require(userProfiles[_profileOwner].skillVerifications[skillHash].requestTimestamp > 0, "Verification not requested yet.");
        require(bytes(userProfiles[_profileOwner].skillVerifications[skillHash].reports[msg.sender]).length == 0, "Already reported this skill verification.");

        userProfiles[_profileOwner].skillVerifications[skillHash].reports[msg.sender] = _reason;
        userProfiles[_profileOwner].skillVerifications[skillHash].reportCount++;

        emit SkillVerificationReported(_profileOwner, skillHash, msg.sender, _reason);

        // Admin can review reports and manually verify or reject
    }

    /// @notice Admin function to manually verify a skill for a user, considering endorsements and reports.
    /// @param _profileOwner Address of the user whose skill is being verified.
    /// @param _skillName Name of the skill to verify.
    function verifySkill(address _profileOwner, string memory _skillName) public onlyAdmin whenNotPaused {
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[_profileOwner].skillVerifications[skillHash]) != address(0), "Skill not found for profile owner.");
        require(!userProfiles[_profileOwner].skillVerifications[skillHash].isVerified, "Skill already verified.");

        userProfiles[_profileOwner].skillVerifications[skillHash].isVerified = true;
        emit SkillVerified(_profileOwner, _skillName, skillHash);
        _updateReputationScore(_profileOwner); // Update reputation upon skill verification
    }

    /// @notice Admin function to revoke a verified skill from a user's profile.
    /// @param _profileOwner Address of the user whose skill is being revoked.
    /// @param _skillName Name of the skill to revoke.
    function revokeSkill(address _profileOwner, string memory _skillName) public onlyAdmin whenNotPaused {
        bytes32 skillHash = keccak256(_skillName);
        require(address(userProfiles[_profileOwner].skillVerifications[skillHash]) != address(0), "Skill not found for profile owner.");
        require(userProfiles[_profileOwner].skillVerifications[skillHash].isVerified, "Skill is not verified.");

        userProfiles[_profileOwner].skillVerifications[skillHash].isVerified = false;
        emit SkillRevoked(_profileOwner, _skillName, skillHash);
        _updateReputationScore(_profileOwner); // Update reputation upon skill revocation
    }

    /// @notice Retrieves a user's profile information and their verified skills.
    /// @param _user Address of the user whose profile to retrieve.
    /// @return UserProfile struct containing profile details and verified skills.
    function getProfile(address _user) external view returns (UserProfile memory) {
        return userProfiles[_user];
    }

    /// @notice Checks the verification status of a specific skill for a user.
    /// @param _user Address of the user.
    /// @param _skillName Name of the skill to check.
    /// @return bool indicating if the skill is verified.
    function getSkillVerificationStatus(address _user, string memory _skillName) external view returns (bool) {
        bytes32 skillHash = keccak256(_skillName);
        return userProfiles[_user].skillVerifications[skillHash].isVerified;
    }

    // --- Reputation Management Functions ---

    /// @notice Calculates and returns a user's reputation score based on verified skills and endorsements.
    /// @param _user Address of the user to calculate the reputation score for.
    /// @return uint256 Reputation score of the user.
    function getReputationScore(address _user) external view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        uint256 currentScore = profile.reputationScore;

        // Apply reputation decay since last update
        uint256 timeElapsed = block.timestamp - lastReputationUpdate;
        uint256 decayAmount = (currentScore * reputationDecayRate * timeElapsed) / (100 * 86400); // Example: daily decay
        if (decayAmount < currentScore) {
             currentScore -= decayAmount;
        } else {
            currentScore = 0; // Prevent negative scores
        }

        uint256 skillScore = 0;
        for (uint256 i = 0; i < 10; i++) { // Iterate through a limited number of skills (for gas efficiency, can be optimized)
            bytes32 skillHash = keccak256(string(abi.encodePacked("Skill", i))); // Example: Skill0, Skill1, ...  (need a better way to iterate skills)
            if (userProfiles[_user].skillVerifications[skillHash].isVerified) {
                 skillScore += skillWeights[skillHash]; // Add weight for verified skills
            }
        }

        return currentScore + skillScore + profile.endorsementCount - profile.reportCount; // Basic score calculation, can be more sophisticated
    }

    /// @dev Internal function to update a user's reputation score based on verified skills.
    /// @param _user Address of the user to update the reputation score for.
    function _updateReputationScore(address _user) internal {
        uint256 newScore = getReputationScore(_user); // Recalculate score
        userProfiles[_user].reputationScore = newScore;
        lastReputationUpdate = block.timestamp; // Update last update timestamp
        emit ReputationScoreUpdated(_user, newScore);
    }

    /// @notice Allows registered users to endorse another user's overall reputation.
    /// @param _profileOwner Address of the user whose reputation is being endorsed.
    function endorseProfileReputation(address _profileOwner) external whenNotPaused communityMemberOnly {
        require(_profileOwner != msg.sender, "Cannot endorse your own reputation.");
        require(address(userProfiles[_profileOwner]) != address(0), "Profile owner not registered.");

        userProfiles[_profileOwner].endorsementCount++;
        emit ProfileReputationEndorsed(_profileOwner, msg.sender);
        _updateReputationScore(_profileOwner); // Update reputation upon endorsement
    }

    /// @notice Allows registered users to report another user's overall reputation with a reason.
    /// @param _profileOwner Address of the user whose reputation is being reported.
    /// @param _reason Reason for reporting the reputation.
    function reportProfileReputation(address _profileOwner, string memory _reason) external whenNotPaused communityMemberOnly {
        require(_profileOwner != msg.sender, "Cannot report your own reputation.");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 200, "Report reason must be between 1 and 200 characters.");
        require(address(userProfiles[_profileOwner]) != address(0), "Profile owner not registered.");

        userProfiles[_profileOwner].reportCount++;
        emit ProfileReputationReported(_profileOwner, msg.sender, _reason);
        _updateReputationScore(_profileOwner); // Update reputation upon report
    }

    /// @notice Gets the number of endorsements a profile has received.
    /// @param _user Address of the user.
    /// @return uint256 Number of endorsements.
    function getProfileEndorsements(address _user) external view returns (uint256) {
        return userProfiles[_user].endorsementCount;
    }

    /// @notice Gets the number of reports a profile has received (for admin overview).
    /// @param _user Address of the user.
    /// @return uint256 Number of reports.
    function getProfileReports(address _user) external view returns (uint256) {
        return userProfiles[_user].reportCount;
    }

    // --- Admin & Utility Functions ---

    /// @notice Admin function to set the weight of a skill in reputation score calculation.
    /// @param _skillName Name of the skill.
    /// @param _weight Weight to assign to the skill.
    function setSkillWeight(string memory _skillName, uint256 _weight) public onlyAdmin whenNotPaused {
        bytes32 skillHash = keccak256(_skillName);
        skillWeights[skillHash] = _weight;
    }

    /// @notice Admin function to set the reputation decay rate.
    /// @param _rate Percentage decay rate per time unit (e.g., per day).
    function setReputationDecayRate(uint256 _rate) public onlyAdmin whenNotPaused {
        reputationDecayRate = _rate;
    }

    /// @notice Admin function to set the endorsement threshold for automatic skill verification.
    /// @param _threshold Number of endorsements required for auto-verification.
    function setVerificationThreshold(uint256 _threshold) public onlyAdmin whenNotPaused {
        verificationThreshold = _threshold;
    }

    /// @notice Admin function to set the minimum number of community members for certain actions.
    /// @param _threshold Minimum community member count.
    function setCommunityThreshold(uint256 _threshold) public onlyAdmin whenNotPaused {
        communityThreshold = _threshold;
    }


    /// @notice Admin function to withdraw any ETH balance from the contract.
    /// @dev Use with caution. Consider adding proper fee management instead of direct withdrawal.
    function withdrawContractBalance() public payable onlyAdmin whenNotPaused {
        uint256 balance = address(this).balance;
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdrawal failed.");
    }

    /// @notice Admin function to pause critical functionalities of the contract.
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Admin function to unpause contract functionalities.
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Public function to check if the contract is currently paused.
    /// @return bool True if paused, false otherwise.
    function getContractStatus() external view returns (bool) {
        return paused;
    }

    /// @notice Admin function to migrate skill verification data (example for upgrades).
    /// @dev Placeholder function for potential data migration logic during contract upgrades.
    function migrateSkillVerificationData() public onlyAdmin whenNotPaused {
        // Add logic to migrate skill verification data if needed during contract upgrades.
        // For example, if the SkillVerification struct is changed.
        // This is a placeholder and needs to be implemented based on specific upgrade needs.
        // Example: Iterate through user profiles and migrate skill verification data to a new format.
        // Note: Data migration can be complex and gas-intensive. Consider off-chain solutions if possible.
    }

    /// @notice Admin function to change the contract administrator.
    /// @param _newAdmin Address of the new administrator.
    function setAdmin(address _newAdmin) public onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be zero address.");
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }
}
```