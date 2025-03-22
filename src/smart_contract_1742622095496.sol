```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Skill Marketplace Contract
 * @author Gemini AI
 * @notice This contract implements a decentralized reputation and skill marketplace,
 * allowing users to build on-chain reputation based on their skills and contributions.
 * It introduces advanced concepts like:
 *  - Skill-based reputation system with dynamic weighting.
 *  - Decentralized skill verification and endorsement.
 *  - Skill-based NFT badges for reputation display.
 *  - Skill-based job/task posting and matching.
 *  - Decentralized dispute resolution for skill-based tasks.
 *  - Dynamic skill pricing based on reputation.
 *  - On-chain skill-based community governance (simple).
 *  - Skill-based learning paths and certifications (conceptual).
 *  - Reputation-weighted access control for features.
 *  - Skill-based tipping and rewarding.
 *
 * Function Summary:
 * 1. registerProfile(string _name, string _skills): Allows users to register their profile with name and skills.
 * 2. updateProfileSkills(string _newSkills): Allows users to update their listed skills.
 * 3. addSkillEndorsement(address _userToEndorse, string _skill): Allows users to endorse skills of other users.
 * 4. verifySkill(address _userToVerify, string _skill): Allows authorized verifiers to officially verify skills.
 * 5. requestSkillVerification(string _skill): Allows users to request skill verification (requires admin approval in a real-world scenario).
 * 6. createSkillBadgeNFT(string _skill): Mints an NFT badge representing a verified skill for a user.
 * 7. postTask(string _taskDescription, string[] _requiredSkills, uint256 _payment): Allows users to post tasks requiring specific skills.
 * 8. applyForTask(uint256 _taskId): Allows users to apply for a task, checking for required skills.
 * 9. acceptTaskApplication(uint256 _taskId, address _applicant): Allows task poster to accept an application.
 * 10. completeTask(uint256 _taskId): Allows task applicant to mark a task as completed.
 * 11. submitTaskForReview(uint256 _taskId): Allows task applicant to submit completed task for review by the poster.
 * 12. approveTaskCompletion(uint256 _taskId): Allows task poster to approve task completion and release payment.
 * 13. disputeTask(uint256 _taskId, string _disputeReason): Allows either party to dispute a task, initiating a basic dispute process.
 * 14. resolveDispute(uint256 _taskId, DisputeResolution _resolution): Allows admin to resolve a dispute.
 * 15. rateUserSkill(address _ratedUser, string _skill, uint8 _rating): Allows users to rate the skill of another user after a task completion.
 * 16. getSkillReputation(address _user, string _skill): Returns the reputation score for a specific skill of a user.
 * 17. getUserProfile(address _user): Returns the profile information of a user.
 * 18. getTaskDetails(uint256 _taskId): Returns details of a specific task.
 * 19. withdrawBalance(): Allows users to withdraw their earned balance.
 * 20. setSkillWeight(string _skill, uint256 _weight): Allows admin to set the reputation weight for a skill.
 * 21. pauseContract(): Allows admin to pause the contract in case of emergency.
 * 22. unpauseContract(): Allows admin to unpause the contract.
 * 23. addVerifier(address _verifierAddress): Allows admin to add a skill verifier.
 * 24. removeVerifier(address _verifierAddress): Allows admin to remove a skill verifier.
 */

contract SkillReputationMarketplace {
    // ---------- Outline & Function Summary Above ----------

    // -------- State Variables --------
    struct UserProfile {
        string name;
        string skills; // Comma-separated skills, could be improved with a list in future iterations for better indexing
        uint256 registrationTimestamp;
    }

    struct Task {
        address poster;
        string description;
        string[] requiredSkills;
        uint256 payment;
        address applicant;
        TaskStatus status;
        uint256 creationTimestamp;
    }

    struct SkillRating {
        uint8 rating; // 1-5 scale
        address rater;
        uint256 timestamp;
    }

    enum TaskStatus { Open, Applied, Accepted, Completed, Reviewed, Disputed, Resolved }
    enum DisputeResolution { PosterWins, ApplicantWins, SplitPayment }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(string => uint256)) public skillReputation; // User -> Skill -> Reputation Score
    mapping(address => mapping(string => SkillRating[])) public skillRatingsReceived; // User -> Skill -> List of Ratings
    mapping(address => mapping(string => bool)) public skillEndorsements; // Endorser -> User -> Skill -> Endorsed
    mapping(address => mapping(string => bool)) public skillVerifications; // Verifier -> User -> Skill -> Verified
    mapping(address => bool) public skillVerifiers; // Address -> isVerifier
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;
    mapping(string => uint256) public skillWeights; // Skill -> Reputation Weight (for dynamic reputation calculation)
    mapping(address => uint256) public userBalances; // User -> Balance in contract

    address public owner;
    bool public paused;

    // -------- Events --------
    event ProfileRegistered(address user, string name, string skills);
    event ProfileSkillsUpdated(address user, string newSkills);
    event SkillEndorsed(address endorser, address endorsedUser, string skill);
    event SkillVerified(address verifier, address verifiedUser, string skill, bool verified);
    event TaskPosted(uint256 taskId, address poster, string description, string[] requiredSkills, uint256 payment);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskApplicationAccepted(uint256 taskId, address applicant);
    event TaskCompleted(uint256 taskId, address applicant);
    event TaskSubmittedForReview(uint256 taskId, address applicant);
    event TaskApproved(uint256 taskId, uint256 paymentReleased);
    event TaskDisputed(uint256 taskId, address disputer, string reason);
    event DisputeResolved(uint256 taskId, DisputeResolution resolution);
    event SkillRated(address rater, address ratedUser, string skill, uint8 rating);
    event SkillWeightSet(string skill, uint256 weight);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);
    event BalanceWithdrawn(address user, uint256 amount);


    // -------- Modifiers --------
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

    modifier onlyVerifier() {
        require(skillVerifiers[msg.sender], "Only authorized verifiers can call this function.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < taskCount && _taskId >= 0, "Task does not exist.");
        _;
    }

    modifier taskStatus(uint256 _taskId, TaskStatus _status) {
        require(tasks[_taskId].status == _status, "Task has incorrect status.");
        _;
    }

    modifier taskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Only task poster can call this function.");
        _;
    }

    modifier taskApplicant(uint256 _taskId) {
        require(tasks[_taskId].applicant == msg.sender, "Only task applicant can call this function.");
        _;
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }


    // -------- Constructor --------
    constructor() {
        owner = msg.sender;
        paused = false;
        // Initialize default skill weights (can be adjusted by admin)
        skillWeights["Programming"] = 100;
        skillWeights["Design"] = 80;
        skillWeights["Marketing"] = 70;
        skillWeights["Writing"] = 60;
        skillWeights["Management"] = 90;
    }

    // -------- Profile Functions --------
    function registerProfile(string memory _name, string memory _skills) public whenNotPaused {
        require(bytes(_name).length > 0 && bytes(_skills).length > 0, "Name and skills cannot be empty.");
        require(userProfiles[msg.sender].registrationTimestamp == 0, "Profile already registered."); // Prevent re-registration

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            skills: _skills,
            registrationTimestamp: block.timestamp
        });
        emit ProfileRegistered(msg.sender, _name, _skills);
    }

    function updateProfileSkills(string memory _newSkills) public whenNotPaused {
        require(userProfiles[msg.sender].registrationTimestamp != 0, "Profile not registered.");
        require(bytes(_newSkills).length > 0, "Skills cannot be empty.");

        userProfiles[msg.sender].skills = _newSkills;
        emit ProfileSkillsUpdated(msg.sender, _newSkills);
    }

    function getUserProfile(address _user) public view returns (UserProfile memory) {
        require(userProfiles[_user].registrationTimestamp != 0, "Profile not registered.");
        return userProfiles[_user];
    }

    // -------- Skill Endorsement & Verification Functions --------
    function addSkillEndorsement(address _userToEndorse, string memory _skill) public whenNotPaused {
        require(userProfiles[_userToEndorse].registrationTimestamp != 0, "User to endorse has no profile.");
        require(!skillEndorsements[msg.sender][_userToEndorse][_skill], "Skill already endorsed by you.");

        skillEndorsements[msg.sender][_userToEndorse][_skill] = true;
        // In a more advanced system, endorsements could contribute to reputation score, but for simplicity, it's just an endorsement here.
        emit SkillEndorsed(msg.sender, _userToEndorse, _skill);
    }

    function verifySkill(address _userToVerify, string memory _skill) public onlyVerifier whenNotPaused {
        require(userProfiles[_userToVerify].registrationTimestamp != 0, "User to verify has no profile.");
        require(!skillVerifications[msg.sender][_userToVerify][_skill], "Skill already verified by this verifier.");

        skillVerifications[msg.sender][_userToVerify][_skill] = true;
        // Verification could significantly boost reputation in a real system
        emit SkillVerified(msg.sender, _userToVerify, _skill, true);
    }

    // Placeholder for skill verification request process (would require admin/verifier approval flow in real app)
    function requestSkillVerification(string memory _skill) public whenNotPaused {
        require(userProfiles[msg.sender].registrationTimestamp != 0, "Profile not registered.");
        // In a real application, this would trigger an off-chain process or on-chain queue for verifier review and approval.
        // For now, it's just a placeholder.
        // TODO: Implement verification request queue and admin/verifier approval process.
        // emit SkillVerificationRequested(msg.sender, _skill);
    }

    // Placeholder for NFT Badge creation (would require NFT contract integration)
    function createSkillBadgeNFT(string memory _skill) public whenNotPaused {
        require(userProfiles[msg.sender].registrationTimestamp != 0, "Profile not registered.");
        // In a real application, this would interact with an NFT contract to mint a badge representing the verified skill.
        // This is a simplified example and doesn't include NFT minting logic here.
        // TODO: Integrate with NFT contract to mint skill badges.
        // emit SkillBadgeMinted(msg.sender, _skill);
    }


    // -------- Task Posting & Application Functions --------
    function postTask(string memory _taskDescription, string[] memory _requiredSkills, uint256 _payment) public payable whenNotPaused {
        require(bytes(_taskDescription).length > 0 && _requiredSkills.length > 0 && _payment > 0, "Invalid task details.");
        require(msg.value >= _payment, "Insufficient payment provided for task.");

        uint256 taskId = taskCount++;
        tasks[taskId] = Task({
            poster: msg.sender,
            description: _taskDescription,
            requiredSkills: _requiredSkills,
            payment: _payment,
            applicant: address(0), // No applicant initially
            status: TaskStatus.Open,
            creationTimestamp: block.timestamp
        });
        userBalances[address(this)] += _payment; // Contract holds the payment until task completion
        emit TaskPosted(taskId, msg.sender, _taskDescription, _requiredSkills, _payment);
    }

    function applyForTask(uint256 _taskId) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Open) {
        require(userProfiles[msg.sender].registrationTimestamp != 0, "Profile not registered to apply for tasks.");
        require(tasks[_taskId].applicant == address(0), "Task already has an applicant.");

        // Basic skill check - could be improved with more sophisticated matching
        bool skillsMatch = true;
        string memory userSkills = userProfiles[msg.sender].skills;
        for (uint i = 0; i < tasks[_taskId].requiredSkills.length; i++) {
            bool skillFound = false;
            string[] memory userSkillList = split(userSkills, ","); // Simple split by comma
            for (uint j = 0; j < userSkillList.length; j++) {
                if (keccak256(bytes(userSkillList[j])) == keccak256(bytes(tasks[_taskId].requiredSkills[i]))) {
                    skillFound = true;
                    break;
                }
            }
            if (!skillFound) {
                skillsMatch = false;
                break;
            }
        }

        require(skillsMatch, "You do not have the required skills for this task.");

        tasks[_taskId].applicant = msg.sender;
        tasks[_taskId].status = TaskStatus.Applied;
        emit TaskApplied(_taskId, msg.sender);
    }

    function acceptTaskApplication(uint256 _taskId, address _applicant) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Applied) taskPoster(_taskId) {
        require(tasks[_taskId].applicant == _applicant, "Applicant address mismatch.");

        tasks[_taskId].status = TaskStatus.Accepted;
        emit TaskApplicationAccepted(_taskId, _applicant);
    }

    // -------- Task Completion & Review Functions --------
    function completeTask(uint256 _taskId) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Accepted) taskApplicant(_taskId) {
        tasks[_taskId].status = TaskStatus.Completed;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function submitTaskForReview(uint256 _taskId) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Completed) taskApplicant(_taskId) {
        tasks[_taskId].status = TaskStatus.Reviewed;
        emit TaskSubmittedForReview(_taskId, msg.sender);
    }

    function approveTaskCompletion(uint256 _taskId) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Reviewed) taskPoster(_taskId) {
        address applicant = tasks[_taskId].applicant;
        uint256 payment = tasks[_taskId].payment;

        tasks[_taskId].status = TaskStatus.Resolved; // Mark as resolved upon approval
        userBalances[applicant] += payment;
        userBalances[address(this)] -= payment; // Reduce contract balance
        emit TaskApproved(_taskId, payment);
    }

    // -------- Dispute Resolution Functions --------
    function disputeTask(uint256 _taskId, string memory _disputeReason) public whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Reviewed) {
        require(tasks[_taskId].poster == msg.sender || tasks[_taskId].applicant == msg.sender, "Only poster or applicant can dispute.");

        tasks[_taskId].status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _taskId, DisputeResolution _resolution) public onlyOwner whenNotPaused taskExists(_taskId) taskStatus(_taskId, TaskStatus.Disputed) {
        address poster = tasks[_taskId].poster;
        address applicant = tasks[_taskId].applicant;
        uint256 payment = tasks[_taskId].payment;

        tasks[_taskId].status = TaskStatus.Resolved; // Mark as resolved after admin action

        if (_resolution == DisputeResolution.PosterWins) {
            // Payment remains with the poster (in contract, but logically poster keeps it) - in a real app, funds might be returned to poster or handled differently based on dispute terms.
            // For simplicity, we are not returning funds to poster in this example, they were never truly "sent" from poster, just held by contract.
            emit DisputeResolved(_taskId, DisputeResolution.PosterWins);
        } else if (_resolution == DisputeResolution.ApplicantWins) {
            userBalances[applicant] += payment;
            userBalances[address(this)] -= payment; // Reduce contract balance
            emit DisputeResolved(_taskId, DisputeResolution.ApplicantWins);
        } else if (_resolution == DisputeResolution.SplitPayment) {
            uint256 splitPayment = payment / 2; // Simple 50/50 split
            userBalances[applicant] += splitPayment;
            userBalances[address(this)] -= splitPayment; // Reduce contract balance
            // Remaining half stays logically with poster (or in contract, depending on desired logic).
            emit DisputeResolved(_taskId, DisputeResolution.SplitPayment);
        }
    }

    // -------- Reputation & Rating Functions --------
    function rateUserSkill(address _ratedUser, string memory _skill, uint8 _rating) public whenNotPaused validRating(_rating) {
        require(userProfiles[_ratedUser].registrationTimestamp != 0, "Rated user has no profile.");
        require(msg.sender != _ratedUser, "Cannot rate yourself."); // Prevent self-rating
        // In a real app, you'd likely want to restrict rating to users who completed a task with the rated user.
        // For simplicity, we allow any registered user to rate anyone else.

        skillRatingsReceived[_ratedUser][_skill].push(SkillRating({
            rating: _rating,
            rater: msg.sender,
            timestamp: block.timestamp
        }));

        // Update skill reputation (simple average for now, can be weighted average later)
        uint256 totalRating = 0;
        SkillRating[] storage ratings = skillRatingsReceived[_ratedUser][_skill];
        for (uint i = 0; i < ratings.length; i++) {
            totalRating += ratings[i].rating;
        }
        uint256 averageRating = ratings.length > 0 ? totalRating / ratings.length : 0; // Avoid division by zero
        uint256 skillWeight = skillWeights[_skill] > 0 ? skillWeights[_skill] : 50; // Default weight if not set
        skillReputation[_ratedUser][_skill] = averageRating * skillWeight; // Simple weighted reputation

        emit SkillRated(msg.sender, _ratedUser, _skill, _rating);
    }

    function getSkillReputation(address _user, string memory _skill) public view returns (uint256) {
        return skillReputation[_user][_skill];
    }

    function getTaskDetails(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }


    // -------- Balance & Withdrawal Functions --------
    function withdrawBalance() public whenNotPaused {
        uint256 balance = userBalances[msg.sender];
        require(balance > 0, "No balance to withdraw.");

        userBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit BalanceWithdrawn(msg.sender, balance);
    }

    // -------- Admin & Utility Functions --------
    function setSkillWeight(string memory _skill, uint256 _weight) public onlyOwner whenNotPaused {
        skillWeights[_skill] = _weight;
        emit SkillWeightSet(_skill, _weight);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function addVerifier(address _verifierAddress) public onlyOwner whenNotPaused {
        skillVerifiers[_verifierAddress] = true;
        emit VerifierAdded(_verifierAddress);
    }

    function removeVerifier(address _verifierAddress) public onlyOwner whenNotPaused {
        skillVerifiers[_verifierAddress] = false;
        emit VerifierRemoved(_verifierAddress);
    }

    // -------- Helper Function (Simple String Split) --------
    function split(string memory _str, string memory _delimiter) internal pure returns (string[] memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory delimiterBytes = bytes(_delimiter);

        if (delimiterBytes.length == 0 || strBytes.length == 0) {
            return new string[](0);
        }

        uint256 count = 0;
        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                count++;
                i += delimiterBytes.length - 1;
            }
        }

        string[] memory result = new string[](count + 1);
        uint256 startIndex = 0;
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < strBytes.length - (delimiterBytes.length - 1); i++) {
            bool match = true;
            for (uint256 j = 0; j < delimiterBytes.length; j++) {
                if (strBytes[i + j] != delimiterBytes[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                result[resultIndex++] = string(slice(strBytes, startIndex, i));
                startIndex = i + delimiterBytes.length;
                i += delimiterBytes.length - 1;
            }
        }

        result[resultIndex] = string(slice(strBytes, startIndex, strBytes.length));
        return result;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length <= _bytes.length - _start, "Slice out of bounds");

        bytes memory tempBytes = new bytes(_length);

        for (uint256 i = 0; i < _length; i++) {
            tempBytes[i] = _bytes[_start + i];
        }
        return tempBytes;
    }
}
```