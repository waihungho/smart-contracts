```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HarmonyNexus Protocol
 * @dev This smart contract implements a decentralized autonomous protocol designed for fostering skill-based collaboration,
 *      managing user reputation, and enabling on-chain project coordination. It blends concepts from Soulbound Tokens (SBTs)
 *      for non-transferable identities, dynamic NFTs for skill badges, epoch-based reputation decay, and an
 *      on-chain governance system.
 *
 * Outline:
 * 1. State Variables & Data Structures
 * 2. Events
 * 3. Modifiers (Owner, Admin, Trusted Oracle)
 * 4. Constructor
 * 5. I. Core Identity & Profile Management (SBT-like)
 * 6. II. Skill & Achievement Management (Dynamic Badges)
 * 7. III. Dynamic Reputation System (Epoch-based Decay)
 * 8. IV. Project & Task Coordination (Conditional Access)
 * 9. V. Treasury & Token Management (ETH based)
 * 10. VI. Governance & Protocol Parameters (Delegated Voting, Executable Proposals)
 * 11. VII. Utility & External Check Functions
 */

/*
 * Function Summary:
 *
 * I. Core Identity & Profile Management:
 *   1. registerProfile(): Allows a user to create a unique, non-transferable on-chain profile. This acts as a Soulbound Token (SBT) of identity.
 *   2. updateProfileMetadata(string _newMetadataURI): User updates their off-chain profile data (e.g., IPFS hash).
 *   3. getProfileDetails(address _user): Public view to retrieve a user's on-chain profile information.
 *
 * II. Skill & Achievement Management:
 *   4. addSkillCategory(string _categoryName): Admin function to define new types of skills (e.g., "Frontend Dev", "Solidity", "Design").
 *   5. grantSkillBadge(address _recipient, uint256 _categoryId, uint8 _level): Trusted Oracle/Admin awards a dynamic skill badge at a specific level to a user.
 *   6. upgradeSkillBadge(address _recipient, uint256 _categoryId, uint8 _newLevel): Trusted Oracle/Admin upgrades an existing skill badge's level.
 *   7. revokeSkillBadge(address _recipient, uint256 _categoryId): Trusted Oracle/Admin revokes a skill badge from a user (e.g., for misconduct).
 *   8. getUserSkills(address _user): Public view to get all skills and their levels for a specific user.
 *
 * III. Dynamic Reputation System:
 *   9. getReputation(address _user): Public view to get a user's current effective reputation, applying an on-demand decay mechanism.
 *   10. startNewEpoch(): Admin/Time-based function to transition to a new epoch, primarily for setting reward windows or triggering other time-sensitive protocol logic.
 *   11. distributeEpochRewards(address[] memory _recipients, uint256[] memory _amounts): Trusted Oracle/Admin function to manually distribute ETH rewards from the treasury based on prior epoch activity or achievements. This is a flexible mechanism for reward distribution.
 *
 * IV. Project & Task Coordination:
 *   12. proposeTask(string _taskURI, uint256 _rewardAmount, uint256 _minReputation, uint256[] memory _requiredSkillCategories): User proposes a new project task with specified requirements and a bounty.
 *   13. approveTaskProposal(uint256 _taskId): Governance/Admin function to approve a proposed task, making it available for applicants.
 *   14. applyForTask(uint256 _taskId): User applies for an approved task, provided they meet the specified reputation and skill criteria.
 *   15. assignTask(uint256 _taskId, address _applicant): Task proposer or Admin assigns an applicant to an approved task.
 *   16. submitTaskCompletion(uint256 _taskId, string _proofURI): Assigned user submits proof of task completion (e.g., IPFS hash to deliverable).
 *   17. verifyTaskCompletion(uint256 _taskId, bool _success): Task proposer or Admin verifies the submission. On success, the task reward is transferred, and reputation is awarded. On failure, reputation might be penalized.
 *
 * V. Treasury & Token Management:
 *   18. depositToTreasury() (payable): Allows anyone to deposit native blockchain currency (ETH) into the protocol's treasury.
 *   19. withdrawFromTreasury(address _to, uint256 _amount): Governance-controlled withdrawal of funds from the treasury.
 *
 * VI. Governance & Protocol Parameters:
 *   20. setTrustedOracle(address _oracle, bool _isTrusted): Owner/Governance can grant or revoke trusted oracle status, allowing them to perform key operational actions.
 *   21. delegateVote(address _delegatee): Allows a user to delegate their voting power (derived from reputation) to another address, fostering liquid democracy.
 *   22. proposeParameterChange(string _description, bytes _callData, address _targetContract): Allows proposing changes to protocol parameters (e.g., decay rates, reward multipliers) or executing arbitrary contract calls, subject to governance approval.
 *   23. voteOnProposal(uint256 _proposalId, bool _support): Users (or their delegates) cast votes on active governance proposals.
 *   24. executeProposal(uint256 _proposalId): Executes a successfully passed governance proposal.
 *
 * VII. Utility & External Check Functions:
 *   25. checkUserEligibility(address _user, uint256 _minReputation, uint256 _minSkillCategory, uint8 _minSkillLevel): A versatile view function for external contracts or DApps to query if a user meets a combined reputation and specific skill requirement.
 */
contract HarmonyNexus {
    address public owner;

    // --- 1. State Variables & Data Structures ---

    // Access Control
    mapping(address => bool) public admins;
    mapping(address => bool) public trustedOracles;

    // Profile (SBT-like)
    struct Profile {
        uint256 id;
        address ownerAddress; // To easily map back from ID to address, and check existence
        string metadataURI;
        uint256 lastReputationUpdateTimestamp; // For decay calculation
        uint256 reputation; // Raw reputation score before decay
        bool exists;
    }
    mapping(address => Profile) public profiles;
    mapping(uint256 => address) public profileIdToAddress; // For retrieving address from SBT-like ID
    uint256 public nextProfileId = 1;

    // Skill Categories
    struct SkillCategory {
        string name;
        bool exists;
    }
    mapping(uint256 => SkillCategory) public skillCategories;
    uint256 public nextSkillCategoryId = 1;

    // User Skills (Dynamic Badges)
    // userAddress => skillCategoryId => {level, exists}
    mapping(address => mapping(uint256 => uint8)) public userSkills;

    // Reputation Parameters
    uint256 public reputationDecayInterval = 7 days; // How often decay is applied (e.g., every week)
    uint256 public reputationDecayRateBps = 500; // 5% decay per interval (500 basis points)
    uint256 public constant MIN_REPUTATION_FLOOR = 100; // Reputation cannot drop below this

    // Epochs
    uint256 public currentEpoch = 1;
    uint256 public epochLength = 30 days; // Duration of an epoch
    uint256 public lastEpochStartTime;

    // Task Coordination
    enum TaskStatus { Proposed, Approved, Applied, Assigned, Submitted, VerifiedSuccess, VerifiedFailure, Cancelled }
    struct Task {
        uint256 id;
        address proposer;
        string metadataURI;
        uint256 rewardAmount; // In Wei (for ETH)
        uint256 minReputation;
        uint256[] requiredSkillCategories; // IDs of skill categories
        address assignedTo;
        string completionProofURI;
        TaskStatus status;
        mapping(address => bool) applicants; // Keep track of who applied
        bool exists;
    }
    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId = 1;

    // Governance
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string description; // IPFS hash or short description
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract address to call
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Address => bool (voted or not)
        ProposalStatus status;
        bool exists;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;
    mapping(address => address) public delegatedVotes; // Voter => Delegatee (for liquid democracy)
    uint256 public proposalQuorumBps = 1000; // 10% of total reputation needed to pass (1000 basis points)
    uint256 public proposalVotingPeriod = 7 days; // Duration proposals are open for voting

    // --- 2. Events ---
    event ProfileRegistered(address indexed user, uint256 profileId, string metadataURI);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);
    event SkillCategoryAdded(uint256 indexed categoryId, string categoryName);
    event SkillBadgeGranted(address indexed recipient, uint256 indexed categoryId, uint8 level);
    event SkillBadgeUpgraded(address indexed recipient, uint256 indexed categoryId, uint8 oldLevel, uint8 newLevel);
    event SkillBadgeRevoked(address indexed recipient, uint256 indexed categoryId);
    event ReputationIncreased(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed user, uint256 amount, uint256 newReputation);
    event EpochStarted(uint256 indexed epochNumber, uint256 startTime);
    event RewardsDistributed(address indexed distributor, address[] recipients, uint256[] amounts);
    event TaskProposed(uint256 indexed taskId, address indexed proposer, uint256 rewardAmount, string metadataURI);
    event TaskApproved(uint256 indexed taskId, address indexed approver);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event TaskAssigned(uint256 indexed taskId, address indexed assignedTo);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed submitter, string proofURI);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool success);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event OracleStatusChanged(address indexed oracle, bool isTrusted);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterChanged(string parameterName, string oldValue, string newValue);


    // --- 3. Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "HarmonyNexus: Only owner can call this function");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner, "HarmonyNexus: Only admin or owner can call this function");
        _;
    }

    modifier onlyTrustedOracle() {
        require(trustedOracles[msg.sender] || msg.sender == owner, "HarmonyNexus: Only trusted oracle or owner can call this function");
        _;
    }

    modifier profileExists(address _user) {
        require(profiles[_user].exists, "HarmonyNexus: Profile does not exist");
        _;
    }

    // --- 4. Constructor ---
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true; // Owner is also an admin by default
        trustedOracles[msg.sender] = true; // Owner is also an oracle by default
        lastEpochStartTime = block.timestamp; // Initialize epoch start time
    }

    // --- Internal Helpers ---

    /**
     * @dev Applies reputation decay to a user's score based on time passed.
     *      Called internally before reading or modifying reputation.
     */
    function _applyDecay(address _user) internal {
        Profile storage userProfile = profiles[_user];
        uint256 currentRep = userProfile.reputation;
        uint256 lastUpdateTimestamp = userProfile.lastReputationUpdateTimestamp;

        if (currentRep == 0 || lastUpdateTimestamp == 0) {
            userProfile.lastReputationUpdateTimestamp = block.timestamp;
            return;
        }

        uint256 timePassed = block.timestamp - lastUpdateTimestamp;
        if (timePassed == 0) return;

        uint256 numIntervals = timePassed / reputationDecayInterval;
        if (numIntervals == 0) return;

        uint256 newRep = currentRep;
        for (uint i = 0; i < numIntervals; i++) {
            newRep = newRep * (10000 - reputationDecayRateBps) / 10000;
            if (newRep < MIN_REPUTATION_FLOOR) {
                newRep = MIN_REPUTATION_FLOOR;
                break;
            }
        }
        userProfile.reputation = newRep;
        userProfile.lastReputationUpdateTimestamp = lastUpdateTimestamp + numIntervals * reputationDecayInterval;
    }

    /**
     * @dev Internal function to increase a user's reputation. Applies decay first.
     */
    function _increaseReputation(address _user, uint256 _amount) internal profileExists(_user) {
        _applyDecay(_user);
        profiles[_user].reputation += _amount;
        emit ReputationIncreased(_user, _amount, profiles[_user].reputation);
    }

    /**
     * @dev Internal function to decrease a user's reputation. Applies decay first.
     */
    function _decreaseReputation(address _user, uint256 _amount) internal profileExists(_user) {
        _applyDecay(_user);
        uint256 currentRep = profiles[_user].reputation;
        if (currentRep > _amount) {
            profiles[_user].reputation -= _amount;
        } else {
            profiles[_user].reputation = MIN_REPUTATION_FLOOR;
        }
        emit ReputationDecreased(_user, _amount, profiles[_user].reputation);
    }


    // --- 5. I. Core Identity & Profile Management ---

    /**
     * @notice Allows a user to create a unique, non-transferable on-chain profile.
     *         This acts as a Soulbound Token (SBT) of identity.
     * @dev Each address can only register one profile.
     * @param _metadataURI IPFS hash or URL pointing to off-chain profile data.
     */
    function registerProfile(string calldata _metadataURI) external {
        require(!profiles[msg.sender].exists, "HarmonyNexus: Profile already registered");

        uint256 profileId = nextProfileId++;
        profiles[msg.sender] = Profile(
            profileId,
            msg.sender,
            _metadataURI,
            block.timestamp, // Initialize last reputation update
            MIN_REPUTATION_FLOOR, // Starting reputation
            true
        );
        profileIdToAddress[profileId] = msg.sender;
        emit ProfileRegistered(msg.sender, profileId, _metadataURI);
        _increaseReputation(msg.sender, 1000); // Give initial reputation boost
    }

    /**
     * @notice User updates their off-chain profile data (e.g., IPFS hash).
     * @param _newMetadataURI New IPFS hash or URL for profile data.
     */
    function updateProfileMetadata(string calldata _newMetadataURI) external profileExists(msg.sender) {
        profiles[msg.sender].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @notice Public view to retrieve a user's on-chain profile information.
     * @param _user The address of the user whose profile is to be retrieved.
     * @return profileId The unique ID of the profile.
     * @return ownerAddress The address that owns the profile.
     * @return metadataURI The IPFS hash or URL for off-chain data.
     * @return reputation The current effective reputation of the user (decay applied).
     */
    function getProfileDetails(address _user) external view profileExists(_user) returns (uint256 profileId, address ownerAddress, string memory metadataURI, uint256 reputation) {
        Profile storage userProfile = profiles[_user];
        return (userProfile.id, userProfile.ownerAddress, userProfile.metadataURI, getReputation(_user));
    }


    // --- 6. II. Skill & Achievement Management ---

    /**
     * @notice Admin function to define new types of skills (e.g., "Frontend Dev", "Solidity", "Design").
     * @param _categoryName The name of the new skill category.
     */
    function addSkillCategory(string calldata _categoryName) external onlyAdmin {
        uint256 categoryId = nextSkillCategoryId++;
        skillCategories[categoryId] = SkillCategory(_categoryName, true);
        emit SkillCategoryAdded(categoryId, _categoryName);
    }

    /**
     * @notice Trusted Oracle/Admin awards a dynamic skill badge at a specific level to a user.
     * @dev Requires the recipient to have a registered profile.
     * @param _recipient The address to grant the skill badge to.
     * @param _categoryId The ID of the skill category.
     * @param _level The level of the skill (e.g., 1-5).
     */
    function grantSkillBadge(address _recipient, uint256 _categoryId, uint8 _level) external onlyTrustedOracle profileExists(_recipient) {
        require(skillCategories[_categoryId].exists, "HarmonyNexus: Skill category does not exist");
        require(_level > 0 && _level <= 100, "HarmonyNexus: Skill level must be between 1 and 100"); // Example bounds

        userSkills[_recipient][_categoryId] = _level;
        emit SkillBadgeGranted(_recipient, _categoryId, _level);
        _increaseReputation(_recipient, 500 * _level); // Reward reputation for new skill
    }

    /**
     * @notice Trusted Oracle/Admin upgrades an existing skill badge's level.
     * @dev New level must be higher than current level.
     * @param _recipient The address whose skill badge is to be upgraded.
     * @param _categoryId The ID of the skill category.
     * @param _newLevel The new, higher level of the skill.
     */
    function upgradeSkillBadge(address _recipient, uint256 _categoryId, uint8 _newLevel) external onlyTrustedOracle profileExists(_recipient) {
        require(skillCategories[_categoryId].exists, "HarmonyNexus: Skill category does not exist");
        require(userSkills[_recipient][_categoryId] > 0, "HarmonyNexus: User does not have this skill badge");
        require(_newLevel > userSkills[_recipient][_categoryId], "HarmonyNexus: New level must be higher than current level");
        require(_newLevel <= 100, "HarmonyNexus: Skill level must be between 1 and 100"); // Example bounds

        uint8 oldLevel = userSkills[_recipient][_categoryId];
        userSkills[_recipient][_categoryId] = _newLevel;
        emit SkillBadgeUpgraded(_recipient, _categoryId, oldLevel, _newLevel);
        _increaseReputation(_recipient, 250 * (_newLevel - oldLevel)); // Reward reputation for upgrade
    }

    /**
     * @notice Trusted Oracle/Admin revokes a skill badge from a user (e.g., for misconduct).
     * @param _recipient The address whose skill badge is to be revoked.
     * @param _categoryId The ID of the skill category to revoke.
     */
    function revokeSkillBadge(address _recipient, uint256 _categoryId) external onlyTrustedOracle profileExists(_recipient) {
        require(skillCategories[_categoryId].exists, "HarmonyNexus: Skill category does not exist");
        require(userSkills[_recipient][_categoryId] > 0, "HarmonyNexus: User does not have this skill badge to revoke");

        uint8 revokedLevel = userSkills[_recipient][_categoryId];
        delete userSkills[_recipient][_categoryId];
        emit SkillBadgeRevoked(_recipient, _categoryId);
        _decreaseReputation(_recipient, 500 * revokedLevel); // Penalize reputation for revocation
    }

    /**
     * @notice Public view to get all skills and their levels for a specific user.
     * @param _user The address of the user.
     * @return skillCategoryIds An array of skill category IDs the user possesses.
     * @return skillLevels An array of corresponding skill levels.
     */
    function getUserSkills(address _user) external view profileExists(_user) returns (uint256[] memory skillCategoryIds, uint8[] memory skillLevels) {
        uint256 count = 0;
        // This is inefficient for a very large number of skill categories.
        // In a real-world scenario, you might use a separate data structure to track user's categories or an external system.
        // For demonstration purposes, iterating up to nextSkillCategoryId is acceptable.
        for (uint256 i = 1; i < nextSkillCategoryId; i++) {
            if (userSkills[_user][i] > 0) {
                count++;
            }
        }

        skillCategoryIds = new uint256[](count);
        skillLevels = new uint8[](count);
        uint256 current = 0;
        for (uint256 i = 1; i < nextSkillCategoryId; i++) {
            if (userSkills[_user][i] > 0) {
                skillCategoryIds[current] = i;
                skillLevels[current] = userSkills[_user][i];
                current++;
            }
        }
        return (skillCategoryIds, skillLevels);
    }


    // --- 7. III. Dynamic Reputation System ---

    /**
     * @notice Public view to get a user's current effective reputation, applying an on-demand decay mechanism.
     * @param _user The address of the user.
     * @return The current effective reputation score.
     */
    function getReputation(address _user) public view profileExists(_user) returns (uint256) {
        Profile storage userProfile = profiles[_user];
        uint256 currentRep = userProfile.reputation;
        uint256 lastUpdateTimestamp = userProfile.lastReputationUpdateTimestamp;

        if (currentRep == 0 || lastUpdateTimestamp == 0) {
            return MIN_REPUTATION_FLOOR;
        }

        uint256 timePassed = block.timestamp - lastUpdateTimestamp;
        if (timePassed == 0) return currentRep;

        uint256 numIntervals = timePassed / reputationDecayInterval;

        uint256 newRep = currentRep;
        for (uint i = 0; i < numIntervals; i++) {
            newRep = newRep * (10000 - reputationDecayRateBps) / 10000;
            if (newRep < MIN_REPUTATION_FLOOR) {
                newRep = MIN_REPUTATION_FLOOR;
                break;
            }
        }
        return newRep;
    }

    /**
     * @notice Admin/Time-based function to transition to a new epoch.
     *         Primarily for setting reward windows or triggering other time-sensitive protocol logic.
     * @dev Can only be called after the `epochLength` has passed since the last epoch start.
     */
    function startNewEpoch() external onlyAdmin {
        require(block.timestamp >= lastEpochStartTime + epochLength, "HarmonyNexus: Epoch has not ended yet");
        
        lastEpochStartTime = block.timestamp;
        currentEpoch++;
        emit EpochStarted(currentEpoch, lastEpochStartTime);
    }

    /**
     * @notice Trusted Oracle/Admin function to manually distribute ETH rewards from the treasury.
     *         This is a flexible mechanism for reward distribution based on prior epoch activity or achievements.
     * @param _recipients An array of addresses to receive rewards.
     * @param _amounts An array of amounts corresponding to each recipient.
     */
    function distributeEpochRewards(address[] memory _recipients, uint256[] memory _amounts) external onlyTrustedOracle {
        require(_recipients.length == _amounts.length, "HarmonyNexus: Mismatched recipients and amounts arrays");
        
        for (uint i = 0; i < _recipients.length; i++) {
            require(address(this).balance >= _amounts[i], "HarmonyNexus: Insufficient treasury balance for rewards");
            (bool success, ) = _recipients[i].call{value: _amounts[i]}("");
            require(success, "HarmonyNexus: Failed to send ETH reward");
        }
        emit RewardsDistributed(msg.sender, _recipients, _amounts);
    }


    // --- 8. IV. Project & Task Coordination ---

    /**
     * @notice User proposes a new project task with specified requirements and a bounty.
     * @param _taskURI IPFS hash or URL for detailed task description.
     * @param _rewardAmount The ETH reward for completing the task (in Wei).
     * @param _minReputation The minimum reputation required for applicants.
     * @param _requiredSkillCategories An array of skill category IDs required for applicants.
     */
    function proposeTask(
        string calldata _taskURI,
        uint256 _rewardAmount,
        uint256 _minReputation,
        uint256[] calldata _requiredSkillCategories
    ) external payable profileExists(msg.sender) {
        require(msg.value == _rewardAmount, "HarmonyNexus: Sent ETH must match reward amount");
        require(_rewardAmount > 0, "HarmonyNexus: Reward amount must be greater than zero");
        
        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task(
            taskId,
            msg.sender,
            _taskURI,
            _rewardAmount,
            _minReputation,
            _requiredSkillCategories,
            address(0), // No one assigned initially
            "",
            TaskStatus.Proposed,
            true
        );
        emit TaskProposed(taskId, msg.sender, _rewardAmount, _taskURI);
    }

    /**
     * @notice Governance/Admin function to approve a proposed task, making it active.
     * @param _taskId The ID of the task to approve.
     */
    function approveTaskProposal(uint256 _taskId) external onlyAdmin {
        Task storage task = tasks[_taskId];
        require(task.exists, "HarmonyNexus: Task does not exist");
        require(task.status == TaskStatus.Proposed, "HarmonyNexus: Task is not in Proposed status");

        task.status = TaskStatus.Approved;
        emit TaskApproved(_taskId, msg.sender);
    }

    /**
     * @notice User applies for an approved task, provided they meet the specified reputation and skill criteria.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 _taskId) external profileExists(msg.sender) {
        Task storage task = tasks[_taskId];
        require(task.exists, "HarmonyNexus: Task does not exist");
        require(task.status == TaskStatus.Approved, "HarmonyNexus: Task is not in Approved status");
        require(!task.applicants[msg.sender], "HarmonyNexus: User already applied for this task");

        // Check reputation
        require(getReputation(msg.sender) >= task.minReputation, "HarmonyNexus: Insufficient reputation to apply");

        // Check skills
        for (uint i = 0; i < task.requiredSkillCategories.length; i++) {
            uint256 requiredCatId = task.requiredSkillCategories[i];
            require(userSkills[msg.sender][requiredCatId] > 0, "HarmonyNexus: Missing required skill");
            // Could also add a minimum level check: userSkills[msg.sender][requiredCatId] >= task.minLevelForSkill[requiredCatId]
        }

        task.applicants[msg.sender] = true;
        emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @notice Task proposer or Admin assigns an applicant to an approved task.
     * @param _taskId The ID of the task.
     * @param _applicant The address of the applicant to assign.
     */
    function assignTask(uint256 _taskId, address _applicant) external {
        Task storage task = tasks[_taskId];
        require(task.exists, "HarmonyNexus: Task does not exist");
        require(task.status == TaskStatus.Approved, "HarmonyNexus: Task is not in Approved status");
        require(msg.sender == task.proposer || admins[msg.sender], "HarmonyNexus: Only task proposer or admin can assign");
        require(task.applicants[_applicant], "HarmonyNexus: Applicant did not apply for this task");

        task.assignedTo = _applicant;
        task.status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _applicant);
    }

    /**
     * @notice Assigned user submits proof of task completion (e.g., IPFS hash to deliverable).
     * @param _taskId The ID of the task.
     * @param _proofURI IPFS hash or URL to the completion proof.
     */
    function submitTaskCompletion(uint256 _taskId, string calldata _proofURI) external profileExists(msg.sender) {
        Task storage task = tasks[_taskId];
        require(task.exists, "HarmonyNexus: Task does not exist");
        require(task.status == TaskStatus.Assigned, "HarmonyNexus: Task is not in Assigned status");
        require(msg.sender == task.assignedTo, "HarmonyNexus: Only assigned user can submit completion");

        task.completionProofURI = _proofURI;
        task.status = TaskStatus.Submitted;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _proofURI);
    }

    /**
     * @notice Task proposer or Admin verifies the submission.
     *         On success, the task reward is transferred, and reputation is awarded.
     *         On failure, reputation might be penalized.
     * @param _taskId The ID of the task.
     * @param _success True if the task was successfully completed, false otherwise.
     */
    function verifyTaskCompletion(uint256 _taskId, bool _success) external {
        Task storage task = tasks[_taskId];
        require(task.exists, "HarmonyNexus: Task does not exist");
        require(task.status == TaskStatus.Submitted, "HarmonyNexus: Task is not in Submitted status");
        require(msg.sender == task.proposer || admins[msg.sender] || trustedOracles[msg.sender], "HarmonyNexus: Only task proposer, admin or oracle can verify");

        if (_success) {
            task.status = TaskStatus.VerifiedSuccess;
            _increaseReputation(task.assignedTo, 1000); // Reward for successful completion
            _increaseReputation(msg.sender, 100); // Reward verifier for activity

            // Transfer reward to assigned user
            (bool success, ) = task.assignedTo.call{value: task.rewardAmount}("");
            require(success, "HarmonyNexus: Failed to transfer task reward");

        } else {
            task.status = TaskStatus.VerifiedFailure;
            _decreaseReputation(task.assignedTo, 500); // Penalize for failed completion
            // The task reward remains in the contract, could be redistributed or proposer can claim back via governance.
        }
        emit TaskVerified(_taskId, msg.sender, _success);
    }


    // --- 9. V. Treasury & Token Management ---

    /**
     * @notice Allows anyone to deposit native blockchain currency (ETH) into the protocol's treasury.
     */
    function depositToTreasury() external payable {
        require(msg.value > 0, "HarmonyNexus: Deposit amount must be greater than zero");
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Governance-controlled withdrawal of funds from the treasury.
     * @dev This function would typically be called via a successful governance proposal.
     * @param _to The recipient address for the withdrawal.
     * @param _amount The amount of ETH to withdraw (in Wei).
     */
    function withdrawFromTreasury(address _to, uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount, "HarmonyNexus: Insufficient treasury balance");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "HarmonyNexus: Failed to withdraw from treasury");
        emit TreasuryWithdrawal(_to, _amount);
    }


    // --- 10. VI. Governance & Protocol Parameters ---

    /**
     * @notice Owner/Governance can grant or revoke trusted oracle status.
     *         Oracles are key to granting skills and verifying tasks.
     * @param _oracle The address to set/unset as an oracle.
     * @param _isTrusted True to grant, false to revoke.
     */
    function setTrustedOracle(address _oracle, bool _isTrusted) external onlyOwner {
        trustedOracles[_oracle] = _isTrusted;
        emit OracleStatusChanged(_oracle, _isTrusted);
    }

    /**
     * @notice Allows a user to delegate their voting power (derived from reputation) to another address.
     *         This fosters liquid democracy.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external profileExists(msg.sender) {
        require(delegatedVotes[msg.sender] != _delegatee, "HarmonyNexus: Already delegated to this address");
        delegatedVotes[msg.sender] = _delegatee;
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @notice Allows proposing changes to protocol parameters (e.g., decay rates, reward multipliers)
     *         or executing arbitrary contract calls, subject to governance approval.
     * @param _description A brief description or IPFS hash for the proposal details.
     * @param _callData The encoded function call (bytes) to execute if the proposal passes.
     * @param _targetContract The address of the contract to call if the proposal passes.
     */
    function proposeParameterChange(
        string calldata _description,
        bytes calldata _callData,
        address _targetContract
    ) external profileExists(msg.sender) {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal(
            proposalId,
            msg.sender,
            _description,
            _callData,
            _targetContract,
            block.timestamp,
            block.timestamp + proposalVotingPeriod,
            0, 0,
            // hasVoted map initialized empty
            ProposalStatus.Active,
            true
        );
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @notice Users (or their delegates) cast votes on active governance proposals.
     *         Voting power is determined by the voter's (or delegator's) effective reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external profileExists(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "HarmonyNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "HarmonyNexus: Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime, "HarmonyNexus: Voting has not started");
        require(block.timestamp <= proposal.voteEndTime, "HarmonyNexus: Voting has ended");

        address voter = msg.sender;
        if (delegatedVotes[voter] != address(0)) {
            voter = delegatedVotes[voter]; // Use delegated address for vote check and power
        }
        
        require(!proposal.hasVoted[voter], "HarmonyNexus: Address already voted on this proposal");

        uint256 votingPower = getReputation(voter);
        require(votingPower > 0, "HarmonyNexus: Voter has no reputation to cast a vote");

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }
        emit Voted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a successfully passed governance proposal.
     * @dev Can only be called after the voting period ends and if the proposal has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyAdmin { // Restricting execution to admin for security
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.exists, "HarmonyNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "HarmonyNexus: Proposal is not active");
        require(block.timestamp > proposal.voteEndTime, "HarmonyNexus: Voting period has not ended");

        // Determine total votes (could be weighted by reputation)
        uint256 totalVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotes > 0, "HarmonyNexus: No votes cast for this proposal");

        // Check quorum (e.g., 10% of total possible reputation, or a fixed threshold)
        // For simplicity, let's assume a fixed number of reputation needed for quorum (e.g., 10000 points)
        // In a real system, `totalReputation` would be tracked, or it'd be based on token stake.
        // For this contract, we'll use a simplified total reputation for quorum check.
        // Let's assume a minimum threshold of votes.
        uint256 minVotesForQuorum = 10000; // Example: needs 10,000 reputation points to be considered valid
        require(totalVotes >= minVotesForQuorum, "HarmonyNexus: Quorum not met for proposal");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst &&
            (proposal.totalVotesFor * 10000 / totalVotes) >= proposalQuorumBps) { // 10% more for than against, and meets quorum
            
            // Execute the proposal call
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "HarmonyNexus: Proposal execution failed");

            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            // No event for failure, but it could be added.
        }
    }


    // --- 11. VII. Utility & External Check Functions ---

    /**
     * @notice A versatile view function for external contracts or DApps to query if a user meets
     *         a combined reputation and specific skill requirement.
     * @param _user The address of the user to check.
     * @param _minReputation The minimum reputation required.
     * @param _minSkillCategory The ID of a specific skill category that is required.
     * @param _minSkillLevel The minimum level required for the specified skill category.
     * @return True if the user meets all specified criteria, false otherwise.
     */
    function checkUserEligibility(
        address _user,
        uint256 _minReputation,
        uint256 _minSkillCategory,
        uint8 _minSkillLevel
    ) external view returns (bool) {
        if (!profiles[_user].exists) return false;

        // Check reputation
        if (getReputation(_user) < _minReputation) return false;

        // Check specific skill, if required
        if (_minSkillCategory != 0) {
            if (!skillCategories[_minSkillCategory].exists) return false;
            if (userSkills[_user][_minSkillCategory] < _minSkillLevel) return false;
        }

        return true;
    }

    /**
     * @notice Allows the owner to add an admin address.
     * @param _newAdmin The address to grant admin privileges.
     */
    function addAdmin(address _newAdmin) external onlyOwner {
        admins[_newAdmin] = true;
    }

    /**
     * @notice Allows the owner to remove an admin address.
     * @param _admin The address to revoke admin privileges from.
     */
    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != owner, "HarmonyNexus: Cannot remove owner as admin");
        admins[_admin] = false;
    }

    /**
     * @notice Returns if an address is an admin.
     * @param _addr The address to check.
     * @return True if the address is an admin, false otherwise.
     */
    function isAdmin(address _addr) external view returns (bool) {
        return admins[_addr];
    }
}
```