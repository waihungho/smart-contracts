This smart contract, named "CognitoSphere," is designed to be a decentralized platform for **skill assessment, reputation building, and project collaboration**, leveraging advanced concepts like **dynamic Soulbound Skill Tokens (sSBTs), AI-assisted skill validation, and reputation-weighted task allocation and governance**. It aims to create a verifiable and trustless ecosystem for individuals to prove their capabilities and contribute to projects.

---

## CognitoSphere: Decentralized Skill & Reputation Oracle Network

**Outline:**

1.  **Core Data Structures:** Defines `Skill`, `Profile`, `Task`, `SkillOracle`, `Dispute` structs.
2.  **State Variables:** Mappings to store entities, global counters, configuration parameters.
3.  **Events:** To signal important state changes.
4.  **Custom Errors:** For more descriptive error handling.
5.  **Modifiers:** For access control and prerequisite checks.
6.  **Admin & Configuration:** Functions for the owner/governance to manage global settings.
7.  **Skill Management:** Registering, updating, and querying skills within the system.
8.  **User Profile & Soulbound Skill Tokens (sSBTs):** Creating and managing user profiles and their dynamic, non-transferable skill representations.
9.  **Skill Oracle Network:** Managing human and AI-proxy oracles responsible for skill and task validation, including staking and slashing mechanisms.
10. **Skill Verification Process:** Initiating and completing the process of getting a skill verified.
11. **Task Management & Collaboration:** Creating, assigning, submitting, and validating tasks based on required skills and reputation.
12. **Reputation System:** Mechanisms for updating, decaying, and leveraging reputation scores.
13. **Dispute Resolution:** A simplified mechanism for resolving conflicts between parties.
14. **Internal Logic:** Helper functions for core operations.

---

**Function Summary:**

**I. Core Configuration & Access Control**
1.  `constructor()`: Initializes the contract owner and base parameters.
2.  `updateSystemConfig(paramId, newValue)`: Allows governance/owner to update system-wide configurations (e.g., stake amounts, decay rates).
3.  `pauseSystem()`: Pauses core operations of the contract in emergencies.
4.  `unpauseSystem()`: Resumes core operations.

**II. Skill Management**
5.  `registerSkill(name, description, requiredSkillIds)`: Creates a new verifiable skill with potential dependencies.
6.  `updateSkillDescription(skillId, newDescription)`: Modifies the description of an existing skill.
7.  `getSkillDetails(skillId)`: Retrieves detailed information about a specific skill.

**III. User Profile & Soulbound Skill Tokens (sSBTs)**
8.  `createProfile(initialMetadataURI)`: Mints a unique, non-transferable Soulbound Skill Token (sSBT) for the caller, initializing their profile.
9.  `updateProfileMetadata(newMetadataURI)`: Allows users to update the metadata URI of their sSBT, reflecting evolving skills/reputation.
10. `getProfile(userAddress)`: Retrieves a user's comprehensive profile including reputation and verified skills.

**IV. Skill Oracle Network**
11. `registerOracle(isAIControlled, initialStakeAmount)`: Allows an entity (human or AI proxy) to register as an oracle by staking tokens.
12. `deregisterOracle()`: Allows an oracle to exit the network and reclaim their stake (after a cool-down period).
13. `slashOracle(oracleAddress, reason)`: Admin/governance function to penalize misbehaving oracles by slashing their stake.

**V. Skill Verification Process**
14. `proposeSkillVerification(skillId, proofURI)`: A user requests verification for a specific skill, providing off-chain proof.
15. `submitSkillAssessment(verificationRequestId, score, assessmentProofURI, aiOverrideScore)`: An oracle (human or AI-proxy) submits an assessment for a pending skill verification request.
16. `finalizeSkillVerification(verificationRequestId)`: Once sufficient assessments are received, this function finalizes the skill verification and updates the user's profile and reputation.

**VI. Task Management & Collaboration**
17. `createTask(title, description, requiredSkillIds, rewardAmount, deadline)`: A project creator posts a new task, specifying required skills and reward.
18. `applyForTask(taskId)`: A user applies for a specific task.
19. `assignTask(taskId, workerAddress)`: The task creator assigns the task to a chosen applicant.
20. `submitTaskCompletion(taskId, workProofURI)`: The assigned worker submits their completed work for validation.
21. `validateTaskCompletion(taskId, validatorScore)`: An oracle assesses the submitted task completion.
22. `claimTaskReward(taskId)`: The worker claims their reward after successful task validation.

**VII. Reputation System**
23. `decayReputation(userAddress)`: (Internal/Callable by specific roles) Periodically reduces a user's reputation score to encourage continuous engagement.
24. `getReputationScore(userAddress)`: Publicly retrieves a user's current reputation score.

**VIII. Dispute Resolution**
25. `initiateDispute(disputedEntityId, disputeType, supportingProofURI)`: Allows any party to initiate a dispute (e.g., on skill assessment, task validation).
26. `resolveDispute(disputeId, winningParty, resolutionDetails)`: Admin/governance function to formally resolve a dispute, potentially reversing previous actions or slashing stakes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Custom Errors
error CognitoSphere__Unauthorized();
error CognitoSphere__ProfileNotFound();
error CognitoSphere__SkillNotFound();
error CognitoSphere__TaskNotFound();
error CognitoSphere__OracleNotFound();
error CognitoSphere__InvalidStatus();
error CognitoSphere__InsufficientStake();
error CognitoSphere__SkillAlreadyVerified();
error CognitoSphere__NotEnoughAssessments();
error CognitoSphere__AssessmentAlreadySubmitted();
error CognitoSphere__TaskNotAssigned();
error CognitoSphere__TaskAlreadyCompleted();
error CognitoSphere__NotTaskCreator();
error CognitoSphere__NotTaskWorker();
error CognitoSphere__InsufficientReputation();
error CognitoSphere__SystemPaused();
error CognitoSphere__InvalidSkillDependencies();
error CognitoSphere__DisputeNotFound();
error CognitoSphere__DisputeAlreadyResolved();

// Enums
enum TaskStatus {
    Open,
    Assigned,
    Submitted,
    Validated,
    Disputed,
    Completed
}

enum VerificationStatus {
    Pending,
    Assessed,
    Finalized,
    Disputed
}

enum DisputeType {
    SkillAssessment,
    TaskValidation,
    OracleMisconduct
}

contract CognitoSphere is Ownable, ERC721, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Core Data Structures ---

    struct Skill {
        uint256 id;
        string name;
        string description;
        uint256[] requiredSkillIds; // IDs of skills required as prerequisites
        bool exists;
    }

    struct Profile {
        uint256 sSBTId; // ID of the Soulbound Skill Token
        uint256 reputationScore;
        mapping(uint256 => bool) verifiedSkills; // skillId => isVerified
        string metadataURI; // URI pointing to dynamic profile metadata
        bool exists;
    }

    struct Task {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256[] requiredSkillIds;
        uint256 rewardAmount;
        uint256 deadline;
        address assignedTo;
        string workProofURI;
        mapping(address => uint256) validatorScores; // oracleAddress => score (0-100)
        uint256 totalValidatorScore;
        uint256 numValidators;
        TaskStatus status;
        bool exists;
    }

    struct SkillOracle {
        address oracleAddress;
        uint256 stakeAmount;
        bool isAIControlled; // True if oracle is an AI proxy, False for human
        uint256 reputation; // Oracle's own reputation score
        bool isActive;
        bool exists;
    }

    struct SkillVerificationRequest {
        uint256 id;
        address user;
        uint256 skillId;
        string proofURI; // URI to off-chain proof of skill
        mapping(address => uint256) oracleAssessments; // oracleAddress => score (0-100)
        uint256 totalAssessmentScore;
        uint256 numAssessments;
        VerificationStatus status;
        bool exists;
    }

    struct Dispute {
        uint256 id;
        DisputeType disputeType;
        uint256 disputedEntityId; // SkillVerificationRequest ID, Task ID, or OracleAddress (packed as uint)
        address initiator;
        string supportingProofURI;
        VerificationStatus status; // Pending, Resolved
        address winner; // The address identified as correct by resolution
        bool exists;
    }

    // --- State Variables ---

    Counters.Counter private _skillIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _sSBTIds;
    Counters.Counter private _verificationRequestIds;
    Counters.Counter private _disputeIds;

    mapping(uint256 => Skill) public skills;
    mapping(address => Profile) public profiles;
    mapping(uint256 => Task) public tasks;
    mapping(address => SkillOracle) public skillOracles;
    mapping(uint256 => SkillVerificationRequest) public skillVerificationRequests;
    mapping(uint256 => Dispute) public disputes;

    // Configuration parameters
    uint256 public minOracleStake = 10 ether;
    uint256 public reputationDecayRate = 1; // % per decay period
    uint256 public reputationGainFactor = 10; // Multiplier for reputation gain
    uint256 public minAssessmentsForVerification = 3;
    uint256 public minTaskValidators = 2;
    uint256 public aiAssessmentWeight = 2; // AI assessments count more, or are more trusted
    bool public systemPaused;

    // --- Events ---

    event SkillRegistered(uint256 indexed skillId, string name, address indexed creator);
    event ProfileCreated(address indexed user, uint256 indexed sSBTId);
    event ProfileMetadataUpdated(address indexed user, uint256 indexed sSBTId, string newURI);
    event OracleRegistered(address indexed oracleAddress, bool isAIControlled, uint256 stake);
    event OracleDeregistered(address indexed oracleAddress);
    event OracleSlashed(address indexed oracleAddress, uint256 amount, string reason);
    event SkillVerificationProposed(uint256 indexed requestId, address indexed user, uint256 indexed skillId);
    event SkillAssessmentSubmitted(uint256 indexed requestId, address indexed oracle, uint256 score);
    event SkillVerificationFinalized(uint256 indexed requestId, address indexed user, uint256 indexed skillId, bool success);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event TaskAssigned(uint256 indexed taskId, address indexed worker);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed worker, string workProofURI);
    event TaskValidationSubmitted(uint256 indexed taskId, address indexed validator, uint256 score);
    event TaskRewardClaimed(uint256 indexed taskId, address indexed worker, uint256 rewardAmount);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event DisputeInitiated(uint256 indexed disputeId, DisputeType indexed disputeType, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, address indexed winner, string details);
    event SystemPaused(address indexed pauser);
    event SystemUnpaused(address indexed unpauser);
    event SystemConfigUpdated(string paramId, uint256 newValue);

    // --- Modifiers ---

    modifier onlyOracle() {
        if (!skillOracles[msg.sender].isActive) {
            revert CognitoSphere__OracleNotFound();
        }
        _;
    }

    modifier whenNotPaused() {
        if (systemPaused) {
            revert CognitoSphere__SystemPaused();
        }
        _;
    }

    modifier hasProfile() {
        if (!profiles[msg.sender].exists) {
            revert CognitoSphere__ProfileNotFound();
        }
        _;
    }

    modifier hasSkill(address _user, uint256 _skillId) {
        if (!profiles[_user].verifiedSkills[_skillId]) {
            revert CognitoSphere__InsufficientReputation(); // Misleading, but implies "doesn't have the required skill"
        }
        _;
    }

    // --- Constructor ---

    constructor() ERC721("CognitoSphere SBT", "CS-SBT") Ownable(msg.sender) {}

    // --- I. Core Configuration & Access Control ---

    /**
     * @notice Allows governance/owner to update system-wide configurations.
     * @param _paramId A string identifier for the parameter to update.
     * @param _newValue The new value for the parameter.
     */
    function updateSystemConfig(string calldata _paramId, uint256 _newValue) external onlyOwner {
        if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("minOracleStake"))) {
            minOracleStake = _newValue;
        } else if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("reputationDecayRate"))) {
            reputationDecayRate = _newValue;
        } else if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("reputationGainFactor"))) {
            reputationGainFactor = _newValue;
        } else if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("minAssessmentsForVerification"))) {
            minAssessmentsForVerification = _newValue;
        } else if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("minTaskValidators"))) {
            minTaskValidators = _newValue;
        } else if (keccak256(abi.encodePacked(_paramId)) == keccak256(abi.encodePacked("aiAssessmentWeight"))) {
            aiAssessmentWeight = _newValue;
        } else {
            revert("CognitoSphere__InvalidConfigParam");
        }
        emit SystemConfigUpdated(_paramId, _newValue);
    }

    /**
     * @notice Pauses core operations of the contract in emergencies.
     * Callable only by the contract owner.
     */
    function pauseSystem() external onlyOwner {
        systemPaused = true;
        emit SystemPaused(msg.sender);
    }

    /**
     * @notice Resumes core operations of the contract.
     * Callable only by the contract owner.
     */
    function unpauseSystem() external onlyOwner {
        systemPaused = false;
        emit SystemUnpaused(msg.sender);
    }

    // --- II. Skill Management ---

    /**
     * @notice Registers a new verifiable skill in the system.
     * @param _name The name of the skill.
     * @param _description A detailed description of the skill.
     * @param _requiredSkillIds An array of skill IDs that are prerequisites for this skill.
     */
    function registerSkill(
        string calldata _name,
        string calldata _description,
        uint256[] calldata _requiredSkillIds
    ) external onlyOwner whenNotPaused returns (uint256) {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();

        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            if (!skills[_requiredSkillIds[i]].exists) {
                revert CognitoSphere__InvalidSkillDependencies();
            }
        }

        skills[newSkillId] = Skill({
            id: newSkillId,
            name: _name,
            description: _description,
            requiredSkillIds: _requiredSkillIds,
            exists: true
        });

        emit SkillRegistered(newSkillId, _name, msg.sender);
        return newSkillId;
    }

    /**
     * @notice Modifies the description of an existing skill.
     * @param _skillId The ID of the skill to update.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDescription(uint256 _skillId, string calldata _newDescription) external onlyOwner {
        if (!skills[_skillId].exists) {
            revert CognitoSphere__SkillNotFound();
        }
        skills[_skillId].description = _newDescription;
    }

    /**
     * @notice Retrieves detailed information about a specific skill.
     * @param _skillId The ID of the skill to retrieve.
     * @return Skill struct containing id, name, description, requiredSkillIds, and existence.
     */
    function getSkillDetails(uint256 _skillId) external view returns (Skill memory) {
        if (!skills[_skillId].exists) {
            revert CognitoSphere__SkillNotFound();
        }
        return skills[_skillId];
    }

    // --- III. User Profile & Soulbound Skill Tokens (sSBTs) ---

    /**
     * @notice Mints a unique, non-transferable Soulbound Skill Token (sSBT) for the caller, initializing their profile.
     * Requires the caller not to have an existing profile.
     * @param _initialMetadataURI The initial URI pointing to the user's profile metadata.
     */
    function createProfile(string calldata _initialMetadataURI) external whenNotPaused {
        if (profiles[msg.sender].exists) {
            revert("CognitoSphere__ProfileAlreadyExists");
        }

        _sSBTIds.increment();
        uint256 newSBTId = _sSBTIds.current();

        _mint(msg.sender, newSBTId);
        _setTokenURI(newSBTId, _initialMetadataURI);

        profiles[msg.sender] = Profile({
            sSBTId: newSBTId,
            reputationScore: 0,
            metadataURI: _initialMetadataURI,
            exists: true
        });

        emit ProfileCreated(msg.sender, newSBTId);
    }

    /**
     * @notice Allows users to update the metadata URI of their sSBT, reflecting evolving skills/reputation.
     * @param _newMetadataURI The new URI pointing to the updated profile metadata.
     */
    function updateProfileMetadata(string calldata _newMetadataURI) external hasProfile whenNotPaused {
        uint256 sSBTId = profiles[msg.sender].sSBTId;
        _setTokenURI(sSBTId, _newMetadataURI);
        profiles[msg.sender].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(msg.sender, sSBTId, _newMetadataURI);
    }

    /**
     * @notice Retrieves a user's comprehensive profile including reputation and verified skills.
     * @param _userAddress The address of the user whose profile is to be retrieved.
     * @return Profile struct containing sSBTId, reputationScore, metadataURI, and existence.
     */
    function getProfile(address _userAddress) external view returns (Profile memory) {
        if (!profiles[_userAddress].exists) {
            revert CognitoSphere__ProfileNotFound();
        }
        return profiles[_userAddress];
    }

    /**
     * @dev ERC721 `_approve` and `setApprovalForAll` are overridden to prevent transferability.
     */
    function _approve(address to, uint256 tokenId) internal override {
        // SBTs are non-transferable; approval is not allowed.
        revert("CognitoSphere__SBT_NotTransferable");
    }

    function approve(address to, uint256 tokenId) public view override {
        revert("CognitoSphere__SBT_NotTransferable");
    }

    function setApprovalForAll(address operator, bool approved) public view override {
        revert("CognitoSphere__SBT_NotTransferable");
    }

    function transferFrom(address from, address to, uint256 tokenId) public view override {
        revert("CognitoSphere__SBT_NotTransferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public view override {
        revert("CognitoSphere__SBT_NotTransferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public view override {
        revert("CognitoSphere__SBT_NotTransferable");
    }

    // --- IV. Skill Oracle Network ---

    /**
     * @notice Allows an entity (human or AI proxy) to register as an oracle by staking tokens.
     * @param _isAIControlled True if the oracle is an AI proxy, False for human.
     * @param _initialStakeAmount The amount of tokens to stake for registration.
     */
    function registerOracle(bool _isAIControlled, uint256 _initialStakeAmount) external payable whenNotPaused {
        if (skillOracles[msg.sender].exists) {
            revert("CognitoSphere__OracleAlreadyRegistered");
        }
        if (msg.value < _initialStakeAmount || _initialStakeAmount < minOracleStake) {
            revert CognitoSphere__InsufficientStake();
        }

        skillOracles[msg.sender] = SkillOracle({
            oracleAddress: msg.sender,
            stakeAmount: _initialStakeAmount,
            isAIControlled: _isAIControlled,
            reputation: 100, // Initial oracle reputation
            isActive: true,
            exists: true
        });

        emit OracleRegistered(msg.sender, _isAIControlled, _initialStakeAmount);
    }

    /**
     * @notice Allows an oracle to exit the network and reclaim their stake (after a cool-down period).
     * (Simplified: no cool-down implemented for brevity, but would be in a real system)
     */
    function deregisterOracle() external onlyOracle whenNotPaused nonReentrant {
        SkillOracle storage oracle = skillOracles[msg.sender];
        uint256 stake = oracle.stakeAmount;

        oracle.isActive = false;
        oracle.exists = false;
        oracle.stakeAmount = 0; // Clear stake amount

        (bool success, ) = msg.sender.call{value: stake}("");
        if (!success) {
            // Revert or log for manual intervention if transfer fails
            revert("CognitoSphere__StakeWithdrawalFailed");
        }

        emit OracleDeregistered(msg.sender);
    }

    /**
     * @notice Admin/governance function to penalize misbehaving oracles by slashing their stake.
     * @param _oracleAddress The address of the oracle to slash.
     * @param _reason A string explaining the reason for slashing.
     */
    function slashOracle(address _oracleAddress, string calldata _reason) external onlyOwner whenNotPaused {
        SkillOracle storage oracle = skillOracles[_oracleAddress];
        if (!oracle.isActive) {
            revert CognitoSphere__OracleNotFound();
        }

        uint256 slashAmount = oracle.stakeAmount.div(2); // Slash 50% for example
        oracle.stakeAmount = oracle.stakeAmount.sub(slashAmount);
        // Funds are locked in contract, could be sent to a DAO treasury or burned

        emit OracleSlashed(_oracleAddress, slashAmount, _reason);
    }

    // --- V. Skill Verification Process ---

    /**
     * @notice A user requests verification for a specific skill, providing off-chain proof.
     * @param _skillId The ID of the skill to be verified.
     * @param _proofURI URI pointing to the off-chain proof (e.g., link to portfolio, certificate).
     */
    function proposeSkillVerification(uint256 _skillId, string calldata _proofURI) external hasProfile whenNotPaused {
        if (!skills[_skillId].exists) {
            revert CognitoSphere__SkillNotFound();
        }
        if (profiles[msg.sender].verifiedSkills[_skillId]) {
            revert CognitoSphere__SkillAlreadyVerified();
        }

        // Check for prerequisite skills
        for (uint256 i = 0; i < skills[_skillId].requiredSkillIds.length; i++) {
            if (!profiles[msg.sender].verifiedSkills[skills[_skillId].requiredSkillIds[i]]) {
                revert CognitoSphere__InvalidSkillDependencies();
            }
        }

        _verificationRequestIds.increment();
        uint256 newRequestId = _verificationRequestIds.current();

        skillVerificationRequests[newRequestId] = SkillVerificationRequest({
            id: newRequestId,
            user: msg.sender,
            skillId: _skillId,
            proofURI: _proofURI,
            totalAssessmentScore: 0,
            numAssessments: 0,
            status: VerificationStatus.Pending,
            exists: true
        });

        emit SkillVerificationProposed(newRequestId, msg.sender, _skillId);
    }

    /**
     * @notice An oracle (human or AI-proxy) submits an assessment for a pending skill verification request.
     * @param _verificationRequestId The ID of the skill verification request.
     * @param _score The assessment score (0-100).
     * @param _assessmentProofURI URI to the oracle's assessment proof/justification.
     * @param _aiOverrideScore (Optional) If an AI oracle, this could be the direct score from the AI model.
     *         Human oracles would ignore this and set their own `_score`.
     */
    function submitSkillAssessment(
        uint256 _verificationRequestId,
        uint256 _score,
        string calldata _assessmentProofURI, // Not stored directly but implies an external system can log it
        uint256 _aiOverrideScore // This would be used if an AI oracle provides a definitive score
    ) external onlyOracle whenNotPaused {
        SkillVerificationRequest storage req = skillVerificationRequests[_verificationRequestId];
        if (!req.exists || req.status != VerificationStatus.Pending) {
            revert CognitoSphere__InvalidStatus();
        }
        if (req.user == msg.sender) {
            revert("CognitoSphere__CannotAssessOwnRequest");
        }
        if (req.oracleAssessments[msg.sender] != 0) {
            revert CognitoSphere__AssessmentAlreadySubmitted();
        }
        if (_score > 100) _score = 100;

        uint256 finalScore = _score;
        if (skillOracles[msg.sender].isAIControlled) {
            finalScore = _aiOverrideScore > 100 ? 100 : _aiOverrideScore;
        }

        req.oracleAssessments[msg.sender] = finalScore;
        req.totalAssessmentScore = req.totalAssessmentScore.add(finalScore);
        req.numAssessments = req.numAssessments.add(1);

        // Update oracle's reputation (simplified)
        _updateReputation(msg.sender, finalScore / 10);

        if (req.numAssessments >= minAssessmentsForVerification) {
            req.status = VerificationStatus.Assessed; // Ready for finalization
        }

        emit SkillAssessmentSubmitted(_verificationRequestId, msg.sender, finalScore);
    }

    /**
     * @notice Once sufficient assessments are received, this function finalizes the skill verification
     * and updates the user's profile and reputation.
     * Callable by anyone, but effectively processed when conditions are met.
     * @param _verificationRequestId The ID of the skill verification request.
     */
    function finalizeSkillVerification(uint256 _verificationRequestId) external whenNotPaused nonReentrant {
        SkillVerificationRequest storage req = skillVerificationRequests[_verificationRequestId];
        if (!req.exists) {
            revert("CognitoSphere__VerificationRequestNotFound");
        }
        if (req.status != VerificationStatus.Assessed) {
            revert CognitoSphere__InvalidStatus();
        }
        if (req.numAssessments < minAssessmentsForVerification) {
            revert CognitoSphere__NotEnoughAssessments();
        }

        uint256 averageScore = req.totalAssessmentScore.div(req.numAssessments);
        bool success = averageScore >= 70; // Example threshold

        if (success) {
            profiles[req.user].verifiedSkills[req.skillId] = true;
            _updateReputation(req.user, averageScore.mul(reputationGainFactor).div(100)); // Gain reputation based on score
        } else {
            // Optional: Penalize user reputation for failed verification
            _updateReputation(req.user, averageScore.mul(reputationGainFactor).div(200).mul(-1));
        }

        req.status = VerificationStatus.Finalized;
        emit SkillVerificationFinalized(_verificationRequestId, req.user, req.skillId, success);
    }

    // --- VI. Task Management & Collaboration ---

    /**
     * @notice A project creator posts a new task, specifying required skills and reward.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _requiredSkillIds An array of skill IDs required to perform this task.
     * @param _rewardAmount The reward (in ETH) for completing the task.
     * @param _deadline The Unix timestamp by which the task must be completed.
     */
    function createTask(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _requiredSkillIds,
        uint256 _rewardAmount,
        uint256 _deadline
    ) external payable hasProfile whenNotPaused returns (uint256) {
        if (msg.value < _rewardAmount) {
            revert("CognitoSphere__InsufficientEthForReward");
        }
        if (_deadline <= block.timestamp) {
            revert("CognitoSphere__InvalidDeadline");
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            creator: msg.sender,
            title: _title,
            description: _description,
            requiredSkillIds: _requiredSkillIds,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            assignedTo: address(0),
            workProofURI: "",
            totalValidatorScore: 0,
            numValidators: 0,
            status: TaskStatus.Open,
            exists: true
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardAmount);
        return newTaskId;
    }

    /**
     * @notice A user applies for a specific task.
     * @param _taskId The ID of the task to apply for.
     */
    function applyForTask(uint256 _taskId) external hasProfile whenNotPaused {
        Task storage task = tasks[_taskId];
        if (!task.exists || task.status != TaskStatus.Open) {
            revert CognitoSphere__InvalidStatus();
        }
        if (task.assignedTo != address(0)) {
            revert("CognitoSphere__TaskAlreadyAssigned");
        }

        // Check if applicant has all required skills
        for (uint256 i = 0; i < task.requiredSkillIds.length; i++) {
            if (!profiles[msg.sender].verifiedSkills[task.requiredSkillIds[i]]) {
                revert CognitoSphere__InsufficientReputation(); // Using this error for "missing skills"
            }
        }

        // In a real system, applications would be stored, and the creator picks.
        // For this example, we'll simplify and assume immediate assignment by creator.
        // emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @notice The task creator assigns the task to a chosen applicant.
     * @param _taskId The ID of the task.
     * @param _workerAddress The address of the user assigned to the task.
     */
    function assignTask(uint256 _taskId, address _workerAddress) external whenNotPaused {
        Task storage task = tasks[_taskId];
        if (!task.exists || task.creator != msg.sender) {
            revert CognitoSphere__NotTaskCreator();
        }
        if (task.status != TaskStatus.Open) {
            revert CognitoSphere__InvalidStatus();
        }
        if (profiles[_workerAddress].exists == false) {
            revert CognitoSphere__ProfileNotFound();
        }

        // Re-check worker skills
        for (uint256 i = 0; i < task.requiredSkillIds.length; i++) {
            if (!profiles[_workerAddress].verifiedSkills[task.requiredSkillIds[i]]) {
                revert CognitoSphere__InsufficientReputation();
            }
        }

        task.assignedTo = _workerAddress;
        task.status = TaskStatus.Assigned;
        emit TaskAssigned(_taskId, _workerAddress);
    }

    /**
     * @notice The assigned worker submits their completed work for validation.
     * @param _taskId The ID of the task.
     * @param _workProofURI URI pointing to the completed work proof.
     */
    function submitTaskCompletion(uint256 _taskId, string calldata _workProofURI) external hasProfile whenNotPaused {
        Task storage task = tasks[_taskId];
        if (!task.exists || task.assignedTo != msg.sender) {
            revert CognitoSphere__NotTaskWorker();
        }
        if (task.status != TaskStatus.Assigned) {
            revert CognitoSphere__InvalidStatus();
        }
        if (block.timestamp > task.deadline) {
            revert("CognitoSphere__TaskOverdue");
        }

        task.workProofURI = _workProofURI;
        task.status = TaskStatus.Submitted;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _workProofURI);
    }

    /**
     * @notice An oracle assesses the submitted task completion.
     * @param _taskId The ID of the task.
     * @param _validatorScore The score given by the validator (0-100).
     */
    function validateTaskCompletion(uint256 _taskId, uint256 _validatorScore) external onlyOracle whenNotPaused {
        Task storage task = tasks[_taskId];
        if (!task.exists || task.status != TaskStatus.Submitted) {
            revert CognitoSphere__InvalidStatus();
        }
        if (task.validatorScores[msg.sender] != 0) {
            revert CognitoSphere__AssessmentAlreadySubmitted(); // Re-using error for validation
        }
        if (_validatorScore > 100) _validatorScore = 100;

        uint256 effectiveScore = _validatorScore;
        if (skillOracles[msg.sender].isAIControlled) {
            effectiveScore = effectiveScore.mul(aiAssessmentWeight); // AI assessments have more weight
        }

        task.validatorScores[msg.sender] = effectiveScore;
        task.totalValidatorScore = task.totalValidatorScore.add(effectiveScore);
        task.numValidators = task.numValidators.add(1);

        // Update oracle's reputation based on their validation quality
        _updateReputation(msg.sender, effectiveScore / 10);

        if (task.numValidators >= minTaskValidators) {
            task.status = TaskStatus.Validated; // Ready for reward claim
        }

        emit TaskValidationSubmitted(_taskId, msg.sender, effectiveScore);
    }

    /**
     * @notice The worker claims their reward after successful task validation.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) external hasProfile whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        if (!task.exists || task.assignedTo != msg.sender) {
            revert CognitoSphere__NotTaskWorker();
        }
        if (task.status != TaskStatus.Validated) {
            revert CognitoSphere__InvalidStatus();
        }

        uint256 averageScore = task.totalValidatorScore.div(task.numValidators);
        bool success = averageScore >= 70; // Example threshold

        if (success) {
            (bool sent, ) = msg.sender.call{value: task.rewardAmount}("");
            if (!sent) {
                revert("CognitoSphere__RewardTransferFailed");
            }
            _updateReputation(msg.sender, averageScore.mul(reputationGainFactor).div(100)); // Worker gains reputation
            task.status = TaskStatus.Completed;
            emit TaskRewardClaimed(_taskId, msg.sender, task.rewardAmount);
        } else {
            // Task failed validation. Funds remain in contract, can be reclaimed by creator or sent to DAO treasury.
            _updateReputation(msg.sender, averageScore.mul(reputationGainFactor).div(200).mul(-1)); // Worker loses reputation
            task.status = TaskStatus.Disputed; // Task status becomes disputed, creator can initiate formal dispute
            revert("CognitoSphere__TaskValidationFailed");
        }
    }

    // --- VII. Reputation System ---

    /**
     * @notice Internal function to update a user's or oracle's reputation score.
     * @param _user The address of the user/oracle.
     * @param _amount The amount to add or subtract from reputation. Positive for gain, negative for loss.
     */
    function _updateReputation(address _user, int256 _amount) internal {
        if (profiles[_user].exists) {
            int256 currentRep = int256(profiles[_user].reputationScore);
            currentRep = currentRep + _amount;
            if (currentRep < 0) currentRep = 0; // Reputation cannot go below zero
            profiles[_user].reputationScore = uint256(currentRep);
            emit ReputationUpdated(_user, uint256(currentRep));
        } else if (skillOracles[_user].exists) {
            int256 currentRep = int256(skillOracles[_user].reputation);
            currentRep = currentRep + _amount;
            if (currentRep < 0) currentRep = 0;
            skillOracles[_user].reputation = uint256(currentRep);
            emit ReputationUpdated(_user, uint256(currentRep)); // Reuse event for oracles
        }
    }

    /**
     * @notice Periodically reduces a user's reputation score to encourage continuous engagement.
     * (Designed to be called by an off-chain keeper or specific role)
     * @param _userAddress The address of the user whose reputation is to decay.
     */
    function decayReputation(address _userAddress) external onlyOracle { // Or onlyOwner/keeper
        Profile storage profile = profiles[_userAddress];
        if (!profile.exists) {
            revert CognitoSphere__ProfileNotFound();
        }
        if (profile.reputationScore > 0) {
            uint256 decayAmount = profile.reputationScore.mul(reputationDecayRate).div(100);
            _updateReputation(_userAddress, -int256(decayAmount));
        }
    }

    /**
     * @notice Publicly retrieves a user's current reputation score.
     * @param _userAddress The address of the user.
     * @return The user's current reputation score.
     */
    function getReputationScore(address _userAddress) external view returns (uint256) {
        if (!profiles[_userAddress].exists) {
            revert CognitoSphere__ProfileNotFound();
        }
        return profiles[_userAddress].reputationScore;
    }

    // --- VIII. Dispute Resolution ---

    /**
     * @notice Allows any party to initiate a dispute (e.g., on skill assessment, task validation).
     * @param _disputedEntityId The ID of the entity being disputed (SkillVerificationRequest ID, Task ID, or OracleAddress).
     *                          For OracleAddress, convert address to uint256.
     * @param _disputeType The type of dispute.
     * @param _supportingProofURI URI to supporting evidence for the dispute.
     */
    function initiateDispute(
        uint256 _disputedEntityId,
        DisputeType _disputeType,
        string calldata _supportingProofURI
    ) external whenNotPaused returns (uint256) {
        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            disputeType: _disputeType,
            disputedEntityId: _disputedEntityId,
            initiator: msg.sender,
            supportingProofURI: _supportingProofURI,
            status: VerificationStatus.Pending,
            winner: address(0),
            exists: true
        });

        // Potentially mark the disputed entity as 'Disputed' to block further actions
        if (_disputeType == DisputeType.SkillAssessment) {
            skillVerificationRequests[_disputedEntityId].status = VerificationStatus.Disputed;
        } else if (_disputeType == DisputeType.TaskValidation) {
            tasks[_disputedEntityId].status = TaskStatus.Disputed;
        }
        // For OracleMisconduct, the oracle status could be temporarily suspended

        emit DisputeInitiated(newDisputeId, _disputeType, msg.sender);
        return newDisputeId;
    }

    /**
     * @notice Admin/governance function to formally resolve a dispute, potentially reversing previous actions or slashing stakes.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _winningParty The address identified as correct by the resolution (could be address(0) if no specific winner).
     * @param _resolutionDetails A string describing the resolution.
     */
    function resolveDispute(
        uint256 _disputeId,
        address _winningParty,
        string calldata _resolutionDetails
    ) external onlyOwner whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (!dispute.exists || dispute.status != VerificationStatus.Pending) {
            revert CognitoSphere__DisputeNotFound();
        }

        // --- Complex Resolution Logic Goes Here ---
        // This is a placeholder for extensive logic that would depend on disputeType
        // and could involve:
        // - Reverting skill verification status
        // - Reversing task validation and reward distribution
        // - Slashing oracle stakes
        // - Adjusting reputation scores

        if (dispute.disputeType == DisputeType.SkillAssessment) {
            SkillVerificationRequest storage req = skillVerificationRequests[dispute.disputedEntityId];
            if (_winningParty == req.user) {
                // If user won, verify skill and adjust reputation
                profiles[req.user].verifiedSkills[req.skillId] = true;
                _updateReputation(req.user, 50); // Example gain
            } else {
                // If oracles won, ensure skill is not verified
                profiles[req.user].verifiedSkills[req.skillId] = false;
                _updateReputation(req.user, -25); // Example loss
            }
            req.status = VerificationStatus.Finalized;
        } else if (dispute.disputeType == DisputeType.TaskValidation) {
            Task storage task = tasks[dispute.disputedEntityId];
            if (_winningParty == task.assignedTo) {
                // If worker won, ensure reward is paid and reputation gained
                (bool sent, ) = task.assignedTo.call{value: task.rewardAmount}("");
                if (!sent) revert("CognitoSphere__RewardTransferFailed");
                _updateReputation(task.assignedTo, 50);
                task.status = TaskStatus.Completed;
            } else {
                // If validator/creator won, worker reputation loss
                _updateReputation(task.assignedTo, -25);
                task.status = TaskStatus.Disputed; // Stays disputed or becomes failed
            }
        } else if (dispute.disputeType == DisputeType.OracleMisconduct) {
            address oracleAddr = address(uint160(dispute.disputedEntityId)); // Convert uint back to address
            slashOracle(oracleAddr, "Dispute Resolution");
            _updateReputation(oracleAddr, -100); // Significant loss for oracle
        }

        dispute.status = VerificationStatus.Finalized;
        dispute.winner = _winningParty;
        emit DisputeResolved(_disputeId, _winningParty, _resolutionDetails);
    }
}
```