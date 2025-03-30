```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill Registry & Reputation System
 * @author Bard (AI Assistant)
 * @notice This smart contract implements a decentralized system for registering skills,
 * verifying those skills by peers, and building a reputation score based on verified skills.
 * It aims to create a transparent and verifiable record of skills and reputation on the blockchain,
 * moving beyond simple token transfers and exploring decentralized identity and skill-based economies.
 *
 * Function Outline & Summary:
 *
 * **Skill Management:**
 * 1. `registerSkill(string memory _skillName, string memory _skillDescription)`: Allows users to propose a new skill to be added to the registry.
 * 2. `approveSkill(uint256 _skillId)`: Admin-only function to approve a proposed skill, making it available for verification.
 * 3. `getSkillDetails(uint256 _skillId)`:  Retrieves details of a specific skill, including name, description, and approval status.
 * 4. `listSkills()`: Returns a list of all approved skills in the registry.
 * 5. `isSkillApproved(uint256 _skillId)`: Checks if a skill is approved and available for verification.
 *
 * **Skill Verification:**
 * 6. `requestSkillVerification(uint256 _skillId, address _targetUser)`: Allows a user to request verification for a skill from another user.
 * 7. `verifySkill(uint256 _skillId, address _userToVerify)`: Allows a user to verify another user for a specific skill, if they themselves are verified for that skill.
 * 8. `revokeSkillVerification(uint256 _skillId, address _userToRevoke)`: Admin-only function to revoke a skill verification in case of misuse or error.
 * 9. `getUserSkills(address _user)`: Returns a list of skills that a user has been verified for.
 * 10. `getSkillVerifiers(uint256 _skillId, address _user)`: Returns a list of users who have verified a given user for a specific skill.
 * 11. `getVerificationRequests(address _user)`: Returns a list of pending skill verification requests for a user.
 * 12. `hasUserVerifiedSkill(address _verifier, uint256 _skillId, address _verifiedUser)`: Checks if a specific verifier has verified a user for a skill.
 *
 * **Reputation System:**
 * 13. `calculateReputation(address _user)`: Calculates a user's reputation score based on the number of verified skills. (Simple example, can be made more sophisticated).
 * 14. `getReputation(address _user)`: Returns a user's calculated reputation score.
 * 15. `setSkillWeight(uint256 _skillId, uint256 _weight)`: Admin-only function to set a weight for each skill, influencing the reputation score.
 * 16. `getSkillWeight(uint256 _skillId)`: Returns the weight assigned to a skill.
 *
 * **Admin & Utility Functions:**
 * 17. `setAdmin(address _newAdmin)`: Allows the current admin to change the admin address.
 * 18. `pauseContract()`: Admin-only function to pause the contract, preventing most state-changing operations.
 * 19. `unpauseContract()`: Admin-only function to unpause the contract.
 * 20. `isContractPaused()`: Returns whether the contract is currently paused.
 * 21. `getContractOwner()`: Returns the address of the contract owner.
 * 22. `isAdmin(address _account)`: Checks if an address is the current admin.
 */
contract SkillRegistry {
    address public owner;
    address public admin;
    bool public paused;

    uint256 public skillCount;
    mapping(uint256 => Skill) public skills;
    mapping(address => mapping(uint256 => bool)) public userSkills; // User -> SkillId -> Verified?
    mapping(uint256 => mapping(address => mapping(address => bool))) public skillVerifications; // SkillId -> UserToVerify -> Verifier -> Verified?
    mapping(address => uint256) public reputationScores;
    mapping(uint256 => uint256) public skillWeights; // SkillId -> Weight for reputation calculation
    mapping(address => mapping(uint256 => bool)) public verificationRequests; // UserToVerify -> SkillId -> Request Pending?

    struct Skill {
        string name;
        string description;
        bool approved;
    }

    event SkillRegistered(uint256 skillId, string skillName, string skillDescription, address proposer);
    event SkillApproved(uint256 skillId, string skillName, address admin);
    event SkillVerificationRequested(uint256 skillId, address targetUser, address requester);
    event SkillVerified(uint256 skillId, address verifiedUser, address verifier);
    event SkillVerificationRevoked(uint256 skillId, address user, address admin);
    event ReputationScoreUpdated(address user, uint256 newScore);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admin can call this function.");
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
        admin = msg.sender;
        paused = false;
        skillCount = 0;
    }

    function isAdmin(address _account) public view returns (bool) {
        return _account == admin;
    }

    function getContractOwner() public view returns (address) {
        return owner;
    }

    function isContractPaused() public view returns (bool) {
        return paused;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    // Skill Management Functions

    function registerSkill(string memory _skillName, string memory _skillDescription) public whenNotPaused {
        require(bytes(_skillName).length > 0 && bytes(_skillDescription).length > 0, "Skill name and description cannot be empty.");
        skillCount++;
        skills[skillCount] = Skill({
            name: _skillName,
            description: _skillDescription,
            approved: false
        });
        skillWeights[skillCount] = 1; // Default weight
        emit SkillRegistered(skillCount, _skillName, _skillDescription, msg.sender);
    }

    function approveSkill(uint256 _skillId) public onlyAdmin whenNotPaused {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        require(!skills[_skillId].approved, "Skill is already approved.");
        skills[_skillId].approved = true;
        emit SkillApproved(_skillId, skills[_skillId].name, admin);
    }

    function getSkillDetails(uint256 _skillId) public view returns (string memory name, string memory description, bool approved) {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        return (skills[_skillId].name, skills[_skillId].description, skills[_skillId].approved);
    }

    function listSkills() public view returns (uint256[] memory) {
        uint256[] memory approvedSkillIds = new uint256[](skillCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (skills[i].approved) {
                approvedSkillIds[count] = i;
                count++;
            }
        }
        // Resize the array to remove extra elements
        assembly {
            mstore(approvedSkillIds, count)
        }
        return approvedSkillIds;
    }

    function isSkillApproved(uint256 _skillId) public view returns (bool) {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        return skills[_skillId].approved;
    }

    // Skill Verification Functions

    function requestSkillVerification(uint256 _skillId, address _targetUser) public whenNotPaused {
        require(isSkillApproved(_skillId), "Skill is not approved for verification.");
        require(msg.sender != _targetUser, "Cannot request verification from yourself.");
        require(!verificationRequests[_targetUser][_skillId], "Verification request already pending for this skill and user.");
        verificationRequests[_targetUser][_skillId] = true;
        emit SkillVerificationRequested(_skillId, _targetUser, msg.sender);
    }

    function verifySkill(uint256 _skillId, address _userToVerify) public whenNotPaused {
        require(isSkillApproved(_skillId), "Skill is not approved for verification.");
        require(msg.sender != _userToVerify, "Cannot verify yourself.");
        require(userSkills[msg.sender][_skillId], "You must be verified for this skill to verify others.");
        require(!userSkills[_userToVerify][_skillId], "User is already verified for this skill.");
        require(verificationRequests[_userToVerify][_skillId], "No verification request pending for this skill and user.");

        userSkills[_userToVerify][_skillId] = true;
        skillVerifications[_skillId][_userToVerify][msg.sender] = true;
        verificationRequests[_userToVerify][_skillId] = false; // Clear the request
        reputationScores[_userToVerify] = calculateReputation(_userToVerify); // Update reputation
        emit SkillVerified(_skillId, _userToVerify, msg.sender);
        emit ReputationScoreUpdated(_userToVerify, reputationScores[_userToVerify]);
    }

    function revokeSkillVerification(uint256 _skillId, address _userToRevoke) public onlyAdmin whenNotPaused {
        require(userSkills[_userToRevoke][_skillId], "User is not verified for this skill.");
        userSkills[_userToRevoke][_skillId] = false;
        delete skillVerifications[_skillId][_userToRevoke]; // Clear verifiers for this skill and user (optional, can keep history)
        reputationScores[_userToRevoke] = calculateReputation(_userToRevoke); // Update reputation
        emit SkillVerificationRevoked(_skillId, _userToRevoke, admin);
        emit ReputationScoreUpdated(_userToRevoke, reputationScores[_userToRevoke]);
    }

    function getUserSkills(address _user) public view returns (uint256[] memory) {
        uint256[] memory verifiedSkillIds;
        uint256 count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (userSkills[_user][i]) {
                count++;
            }
        }
        verifiedSkillIds = new uint256[](count);
        count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (userSkills[_user][i]) {
                verifiedSkillIds[count] = i;
                count++;
            }
        }
        return verifiedSkillIds;
    }

    function getSkillVerifiers(uint256 _skillId, address _user) public view returns (address[] memory) {
        require(userSkills[_user][_skillId], "User is not verified for this skill.");
        address[] memory verifiers;
        uint256 count = 0;
        for (address verifier : skillVerifications[_skillId][_user]) {
            if (skillVerifications[_skillId][_user][verifier]) { // Check if verification is true (redundant but explicit)
                count++;
            }
        }
        verifiers = new address[](count);
        count = 0;
        for (address verifier : skillVerifications[_skillId][_user]) {
            if (skillVerifications[_skillId][_user][verifier]) {
                verifiers[count] = verifier;
                count++;
            }
        }
        return verifiers;
    }

    function getVerificationRequests(address _user) public view returns (uint256[] memory) {
        uint256[] memory requestedSkillIds;
        uint256 count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (verificationRequests[_user][i]) {
                count++;
            }
        }
        requestedSkillIds = new uint256[](count);
        count = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (verificationRequests[_user][i]) {
                requestedSkillIds[count] = i;
                count++;
            }
        }
        return requestedSkillIds;
    }

    function hasUserVerifiedSkill(address _verifier, uint256 _skillId, address _verifiedUser) public view returns (bool) {
        return skillVerifications[_skillId][_verifiedUser][_verifier];
    }


    // Reputation System Functions

    function calculateReputation(address _user) internal view returns (uint256) {
        uint256 reputation = 0;
        for (uint256 i = 1; i <= skillCount; i++) {
            if (userSkills[_user][i]) {
                reputation += skillWeights[i];
            }
        }
        return reputation;
    }

    function getReputation(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    function setSkillWeight(uint256 _skillId, uint256 _weight) public onlyAdmin whenNotPaused {
        require(isSkillApproved(_skillId), "Skill must be approved to set weight.");
        skillWeights[_skillId] = _weight;
    }

    function getSkillWeight(uint256 _skillId) public view returns (uint256) {
        require(_skillId > 0 && _skillId <= skillCount, "Invalid skill ID.");
        return skillWeights[_skillId];
    }
}
```