```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Skill-Based Reputation System with Dynamic Challenges and Rewards
 * @author Gemini
 * @dev This contract implements a decentralized reputation system based on skills and endorsements.
 * It allows users to register skills, endorse each other for skills, participate in dynamic challenges,
 * earn reputation and rewards, and engage in a decentralized talent ecosystem.
 *
 * **Outline & Function Summary:**
 *
 * **Skill Management:**
 * 1. `registerSkill(string _skillName)`: Allows admins to register new skills in the system.
 * 2. `getSkillName(uint256 _skillId)`: Returns the name of a skill given its ID.
 * 3. `getSkillCount()`: Returns the total number of registered skills.
 * 4. `isSkillRegistered(uint256 _skillId)`: Checks if a skill ID is registered.
 *
 * **User Reputation & Endorsement:**
 * 5. `endorseSkill(address _user, uint256 _skillId, string _endorsementMessage)`: Allows users to endorse another user for a specific skill.
 * 6. `getUserReputation(address _user)`: Returns the overall reputation score of a user.
 * 7. `getUserSkillReputation(address _user, uint256 _skillId)`: Returns the reputation score of a user for a specific skill.
 * 8. `getEndorsementCount(address _user, uint256 _skillId)`: Returns the number of endorsements a user has received for a specific skill.
 * 9. `getUserEndorsementsForSkill(address _user, uint256 _skillId)`: Returns a list of endorsers and messages for a specific skill of a user.
 * 10. `decayReputation(address _user)`: Periodically decays a user's overall reputation over time if inactive.
 *
 * **Dynamic Challenges & Rewards:**
 * 11. `createChallenge(string _challengeName, uint256 _skillId, uint256 _rewardAmount, uint256 _deadline)`: Allows admins to create challenges for specific skills with rewards and deadlines.
 * 12. `getChallengeDetails(uint256 _challengeId)`: Returns details of a specific challenge.
 * 13. `submitChallengeSolution(uint256 _challengeId, string _solutionUri)`: Allows users to submit solutions for active challenges.
 * 14. `evaluateChallengeSolution(uint256 _challengeId, address _user, bool _isAccepted)`: Allows admins to evaluate submitted solutions and reward users if accepted.
 * 15. `getChallengeSubmissions(uint256 _challengeId)`: Returns a list of users who submitted solutions for a challenge.
 * 16. `getActiveChallengeCountForSkill(uint256 _skillId)`: Returns the number of active challenges for a given skill.
 *
 * **Admin & System Management:**
 * 17. `addAdmin(address _newAdmin)`: Allows existing admins to add new admins.
 * 18. `removeAdmin(address _adminToRemove)`: Allows admins to remove other admins.
 * 19. `isAdmin(address _account)`: Checks if an account is an admin.
 * 20. `pauseContract()`: Allows admins to pause the contract functionality.
 * 21. `unpauseContract()`: Allows admins to unpause the contract functionality.
 * 22. `isPaused()`: Checks if the contract is currently paused.
 * 23. `setReputationDecayRate(uint256 _decayRate)`: Allows admins to set the reputation decay rate.
 * 24. `setBaseReputationGain(uint256 _baseGain)`: Allows admins to set the base reputation gain for endorsements.
 * 25. `setChallengeEvaluationReputationGain(uint256 _challengeGain)`: Allows admins to set reputation gain for successful challenge evaluations.
 * 26. `withdrawContractBalance()`: Allows admins to withdraw any ETH balance in the contract.
 * 27. `getVersion()`: Returns the contract version.
 */
contract SkillBasedReputation {

    // --- State Variables ---

    address public owner;
    bool public paused;
    uint256 public contractVersion = 1;

    uint256 public skillCount;
    mapping(uint256 => string) public skills;
    mapping(string => uint256) public skillNameToId;

    mapping(address => uint256) public userReputation;
    mapping(address => mapping(uint256 => uint256)) public userSkillReputation;
    mapping(address => mapping(uint256 => Endorsement[])) public skillEndorsements;

    uint256 public reputationDecayRate = 1; // Decay amount per decay cycle
    uint256 public lastDecayTimestamp;
    uint256 public decayInterval = 1 days; // Time interval for reputation decay

    uint256 public baseReputationGain = 10; // Reputation gained per endorsement
    uint256 public challengeEvaluationReputationGain = 50; // Reputation gained for successful challenge

    uint256 public challengeCount;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Submission[]) public challengeSubmissions;

    mapping(address => bool) public admins;

    // --- Structs ---

    struct Endorsement {
        address endorser;
        string message;
        uint256 timestamp;
    }

    struct Challenge {
        string name;
        uint256 skillId;
        uint256 rewardAmount;
        uint256 deadline;
        address creator;
        bool isActive;
    }

    struct Submission {
        address submitter;
        string solutionUri;
        uint256 timestamp;
        bool isEvaluated;
        bool isAccepted;
    }

    // --- Events ---

    event SkillRegistered(uint256 skillId, string skillName);
    event SkillEndorsed(address indexed user, uint256 skillId, address indexed endorser, string message);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event ChallengeCreated(uint256 challengeId, string challengeName, uint256 skillId, uint256 rewardAmount, uint256 deadline);
    event ChallengeSolutionSubmitted(uint256 challengeId, address indexed submitter, string solutionUri);
    event ChallengeSolutionEvaluated(uint256 challengeId, address indexed submitter, bool isAccepted, uint256 reputationGain);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminAdded(address newAdmin, address addedBy);
    event AdminRemoved(address removedAdmin, address removedBy);
    event ReputationDecayed(address indexed user, uint256 decayedAmount, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this function.");
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

    modifier skillExists(uint256 _skillId) {
        require(_skillId > 0 && _skillId <= skillCount && bytes(skills[_skillId]).length > 0, "Skill does not exist.");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= challengeCount && challenges[_challengeId].isActive, "Challenge does not exist or is inactive.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admins[owner] = true;
        paused = false;
        lastDecayTimestamp = block.timestamp;
    }

    // --- Skill Management Functions ---

    /**
     * @dev Registers a new skill in the system. Only admins can call this.
     * @param _skillName The name of the skill to register.
     */
    function registerSkill(string memory _skillName) public onlyAdmin whenNotPaused {
        require(bytes(_skillName).length > 0, "Skill name cannot be empty.");
        require(skillNameToId[_skillName] == 0, "Skill name already registered.");
        skillCount++;
        skills[skillCount] = _skillName;
        skillNameToId[_skillName] = skillCount;
        emit SkillRegistered(skillCount, _skillName);
    }

    /**
     * @dev Returns the name of a skill given its ID.
     * @param _skillId The ID of the skill.
     * @return The name of the skill.
     */
    function getSkillName(uint256 _skillId) public view skillExists(_skillId) returns (string memory) {
        return skills[_skillId];
    }

    /**
     * @dev Returns the total number of registered skills.
     * @return The total skill count.
     */
    function getSkillCount() public view returns (uint256) {
        return skillCount;
    }

    /**
     * @dev Checks if a skill ID is registered.
     * @param _skillId The ID to check.
     * @return True if the skill is registered, false otherwise.
     */
    function isSkillRegistered(uint256 _skillId) public view returns (bool) {
        return (_skillId > 0 && _skillId <= skillCount && bytes(skills[_skillId]).length > 0);
    }

    // --- User Reputation & Endorsement Functions ---

    /**
     * @dev Allows a user to endorse another user for a specific skill.
     * @param _user The address of the user being endorsed.
     * @param _skillId The ID of the skill for which the user is being endorsed.
     * @param _endorsementMessage A message accompanying the endorsement.
     */
    function endorseSkill(address _user, uint256 _skillId, string memory _endorsementMessage) public whenNotPaused skillExists(_skillId) {
        require(msg.sender != _user, "Cannot endorse yourself.");
        require(bytes(_endorsementMessage).length <= 256, "Endorsement message too long."); // Limit message length

        // Check for reputation decay before endorsement
        decayReputation(_user);
        decayReputation(msg.sender);

        userSkillReputation[_user][_skillId] += baseReputationGain;
        userReputation[_user] += baseReputationGain;
        skillEndorsements[_user][_skillId].push(Endorsement({
            endorser: msg.sender,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));

        emit SkillEndorsed(_user, _skillId, msg.sender, _endorsementMessage);
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    /**
     * @dev Returns the overall reputation score of a user.
     * @param _user The address of the user.
     * @return The user's overall reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the reputation score of a user for a specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The user's reputation score for the skill.
     */
    function getUserSkillReputation(address _user, uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return userSkillReputation[_user][_skillId];
    }

    /**
     * @dev Returns the number of endorsements a user has received for a specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The number of endorsements.
     */
    function getEndorsementCount(address _user, uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return skillEndorsements[_user][_skillId].length;
    }

    /**
     * @dev Returns a list of endorsers and messages for a specific skill of a user.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return An array of Endorsement structs.
     */
    function getUserEndorsementsForSkill(address _user, uint256 _skillId) public view skillExists(_skillId) returns (Endorsement[] memory) {
        return skillEndorsements[_user][_skillId];
    }

    /**
     * @dev Periodically decays a user's overall reputation over time if inactive.
     * @param _user The address of the user whose reputation needs to be decayed.
     */
    function decayReputation(address _user) public whenNotPaused {
        if (block.timestamp >= lastDecayTimestamp + decayInterval) {
            lastDecayTimestamp = block.timestamp;
            if (userReputation[_user] > reputationDecayRate) {
                userReputation[_user] -= reputationDecayRate;
                emit ReputationDecayed(_user, reputationDecayRate, userReputation[_user]);
            } else if (userReputation[_user] > 0) {
                uint256 decayedAmount = userReputation[_user];
                userReputation[_user] = 0;
                emit ReputationDecayed(_user, decayedAmount, userReputation[_user]);
            }
             // Decay skill-specific reputation proportionally - optional, can be added if needed.
             // for (uint256 i = 1; i <= skillCount; i++) {
             //     if (userSkillReputation[_user][i] > 0) {
             //         userSkillReputation[_user][i] -= (userSkillReputation[_user][i] * reputationDecayRate) / userReputation[_user]; // Proportional decay
             //     }
             // }
        }
    }


    // --- Dynamic Challenges & Rewards Functions ---

    /**
     * @dev Allows admins to create a new challenge for a specific skill.
     * @param _challengeName The name of the challenge.
     * @param _skillId The skill ID related to the challenge.
     * @param _rewardAmount The reward amount (in ETH) for completing the challenge.
     * @param _deadline The deadline timestamp for the challenge.
     */
    function createChallenge(string memory _challengeName, uint256 _skillId, uint256 _rewardAmount, uint256 _deadline) public onlyAdmin whenNotPaused skillExists(_skillId) {
        require(bytes(_challengeName).length > 0, "Challenge name cannot be empty.");
        require(_deadline > block.timestamp, "Deadline must be in the future.");
        require(_rewardAmount > 0, "Reward amount must be greater than zero.");

        challengeCount++;
        challenges[challengeCount] = Challenge({
            name: _challengeName,
            skillId: _skillId,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            creator: msg.sender,
            isActive: true
        });

        emit ChallengeCreated(challengeCount, _challengeName, _skillId, _rewardAmount, _deadline);
    }

    /**
     * @dev Returns details of a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return The Challenge struct.
     */
    function getChallengeDetails(uint256 _challengeId) public view challengeExists(_challengeId) returns (Challenge memory) {
        return challenges[_challengeId];
    }

    /**
     * @dev Allows users to submit a solution for an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionUri URI pointing to the solution (e.g., IPFS hash).
     */
    function submitChallengeSolution(uint256 _challengeId, string memory _solutionUri) public whenNotPaused challengeExists(_challengeId) {
        require(challenges[_challengeId].deadline > block.timestamp, "Challenge deadline passed.");
        require(bytes(_solutionUri).length > 0, "Solution URI cannot be empty.");

        // Check if user has already submitted for this challenge (optional - prevent resubmissions)
        for (uint256 i = 0; i < challengeSubmissions[_challengeId].length; i++) {
            require(challengeSubmissions[_challengeId][i].submitter != msg.sender, "You have already submitted a solution for this challenge.");
        }

        challengeSubmissions[_challengeId].push(Submission({
            submitter: msg.sender,
            solutionUri: _solutionUri,
            timestamp: block.timestamp,
            isEvaluated: false,
            isAccepted: false
        }));

        emit ChallengeSolutionSubmitted(_challengeId, msg.sender, _solutionUri);
    }

    /**
     * @dev Allows admins to evaluate a submitted solution and reward the user if accepted.
     * @param _challengeId The ID of the challenge.
     * @param _user The address of the user who submitted the solution.
     * @param _isAccepted Boolean indicating whether the solution is accepted or not.
     */
    function evaluateChallengeSolution(uint256 _challengeId, address _user, bool _isAccepted) public onlyAdmin whenNotPaused challengeExists(_challengeId) {
        require(challenges[_challengeId].deadline <= block.timestamp, "Challenge is still active, cannot evaluate yet."); // Ensure deadline has passed
        require(!challengeSubmissions[_challengeId][0].isEvaluated, "Challenge already evaluated."); // Simple check, can be improved for multiple submissions

        Submission storage submission = challengeSubmissions[_challengeId][0]; // Assuming single submission for simplicity - can be adjusted for multiple
        require(submission.submitter == _user, "User did not submit solution for this challenge.");
        require(!submission.isEvaluated, "Solution already evaluated.");

        submission.isEvaluated = true;
        submission.isAccepted = _isAccepted;

        if (_isAccepted) {
            payable(_user).transfer(challenges[_challengeId].rewardAmount);
            userReputation[_user] += challengeEvaluationReputationGain;
            emit ReputationUpdated(_user, userReputation[_user]);
            emit ChallengeSolutionEvaluated(_challengeId, _user, true, challengeEvaluationReputationGain);
        } else {
             emit ChallengeSolutionEvaluated(_challengeId, _user, false, 0);
        }

        // Deactivate challenge after evaluation (optional - depends on use case)
        challenges[_challengeId].isActive = false;
    }

    /**
     * @dev Returns a list of users who submitted solutions for a challenge.
     * @param _challengeId The ID of the challenge.
     * @return An array of addresses of submitters.
     */
    function getChallengeSubmissions(uint256 _challengeId) public view challengeExists(_challengeId) returns (address[] memory) {
        uint256 submissionCount = challengeSubmissions[_challengeId].length;
        address[] memory submitters = new address[](submissionCount);
        for (uint256 i = 0; i < submissionCount; i++) {
            submitters[i] = challengeSubmissions[_challengeId][i].submitter;
        }
        return submitters;
    }

    /**
     * @dev Returns the number of active challenges for a given skill.
     * @param _skillId The ID of the skill.
     * @return The count of active challenges.
     */
    function getActiveChallengeCountForSkill(uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        uint256 activeChallengeCount = 0;
        for (uint256 i = 1; i <= challengeCount; i++) {
            if (challenges[i].isActive && challenges[i].skillId == _skillId) {
                activeChallengeCount++;
            }
        }
        return activeChallengeCount;
    }


    // --- Admin & System Management Functions ---

    /**
     * @dev Adds a new admin. Only existing admins can call this.
     * @param _newAdmin The address of the new admin to add.
     */
    function addAdmin(address _newAdmin) public onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        require(!admins[_newAdmin], "Address is already an admin.");
        admins[_newAdmin] = true;
        emit AdminAdded(_newAdmin, msg.sender);
    }

    /**
     * @dev Removes an admin. Only existing admins can call this. Cannot remove the contract owner.
     * @param _adminToRemove The address of the admin to remove.
     */
    function removeAdmin(address _adminToRemove) public onlyAdmin whenNotPaused {
        require(_adminToRemove != owner, "Cannot remove the contract owner as admin.");
        require(admins[_adminToRemove], "Address is not an admin.");
        delete admins[_adminToRemove];
        emit AdminRemoved(_adminToRemove, msg.sender);
    }

    /**
     * @dev Checks if an address is an admin.
     * @param _account The address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isAdmin(address _account) public view returns (bool) {
        return admins[_account];
    }

    /**
     * @dev Pauses the contract functionality. Only admins can call this.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract functionality. Only admins can call this.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Sets the reputation decay rate. Only admins can call this.
     * @param _decayRate The new decay rate.
     */
    function setReputationDecayRate(uint256 _decayRate) public onlyAdmin whenNotPaused {
        require(_decayRate >= 0, "Decay rate cannot be negative.");
        reputationDecayRate = _decayRate;
    }

    /**
     * @dev Sets the base reputation gain for endorsements. Only admins can call this.
     * @param _baseGain The new base reputation gain.
     */
    function setBaseReputationGain(uint256 _baseGain) public onlyAdmin whenNotPaused {
        require(_baseGain >= 0, "Base reputation gain cannot be negative.");
        baseReputationGain = _baseGain;
    }

    /**
     * @dev Sets the reputation gain for successful challenge evaluations. Only admins can call this.
     * @param _challengeGain The new challenge evaluation reputation gain.
     */
    function setChallengeEvaluationReputationGain(uint256 _challengeGain) public onlyAdmin whenNotPaused {
        require(_challengeGain >= 0, "Challenge reputation gain cannot be negative.");
        challengeEvaluationReputationGain = _challengeGain;
    }


    /**
     * @dev Allows the contract owner to withdraw any ETH balance in the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Returns the contract version.
     * @return The contract version number.
     */
    function getVersion() public view returns (uint256) {
        return contractVersion;
    }

    // --- Fallback and Receive Functions (Optional - for receiving ETH if needed for challenges) ---
    receive() external payable {}
    fallback() external payable {}
}
```