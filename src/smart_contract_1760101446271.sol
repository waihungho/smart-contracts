```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Included for potential ERC20 rewards/funding, though ETH is primary in this example.

/**
 * @title AuraForge Protocol: A Dynamic Reputation and Adaptive Governance System
 * @dev AuraForge is a decentralized, skill-centric network and project incubator designed to foster
 *      genuine contributions and enable fair resource allocation. It moves beyond simple token-weighted
 *      voting by validating and leveraging individual skills, tracking verifiable impact, and
 *      dynamically evolving user reputation through Soulbound AuraTokens.
 *
 * @author AuraForge Team (Conceptual)
 * @notice This contract is built for demonstration and educational purposes. It integrates advanced
 *         conceptual features such as dynamic Soulbound Tokens, skill validation delegation, and
 *         hooks for off-chain AI/ZK integrations. A production environment would require
 *         sophisticated off-chain components (e.g., ZK-proof generation, verifiable credential systems,
 *         AI-driven oracles) and robust governance mechanisms (e.g., a Governor contract with a Timelock).
 */
contract AuraForge is Ownable {
    using Counters for Counters.Counter;

    /*
     *
     * --- Contract Outline & Function Summary ---
     *
     * I. Core Concepts & Vision
     *    AuraForge envisions a self-organizing talent network where individuals build verifiable
     *    reputation based on their skills and contributions to decentralized projects. It aims to:
     *    1.  **Skill Graph & Validation:** Establish a formal, validated system for user skills.
     *    2.  **Soulbound AuraTokens (SBTs):** Issue non-transferable, dynamic reputation tokens that evolve
     *        with a user's verified skills, project contributions, and overall impact.
     *    3.  **Project Incubation & Impact Tracking:** Facilitate decentralized project proposals, funding,
     *        and diligent tracking of individual contributions with measurable impact assessments.
     *    4.  **Adaptive Resource Allocation:** Distribute project funds and treasury resources based on a
     *        multi-factorial system that prioritizes proven skills, AuraToken reputation, and verified
     *        project impact, rather than solely token holdings.
     *    5.  **Dynamic Governance & Parameter Adaptation:** Implement a governance model where system
     *        parameters can be adjusted based on collective decisions and network health, leveraging
     *        reputation-weighted influence.
     *    6.  **Delegated Skill Authority:** Introduce a novel form of liquid democracy by allowing
     *        high-reputation validators to delegate their skill validation authority for specific skills.
     *    7.  **Conceptual AI & ZK Integration:** Provide explicit hooks for future integration with
     *        off-chain AI oracles (for impact analysis, recommendations) and ZK-proofs (for
     *        privacy-preserving skill verification).
     *
     * II. State Variables & Data Structures
     *    - `Skill`: Defines a skill type (name, parent, description, core status).
     *    - `UserSkill`: Records a user's validated skill, level, validator, and proof hash.
     *    - `SkillValidationRequest`: Manages the lifecycle of skill validation requests.
     *    - `AuraToken`: Represents the user's Soulbound Reputation Token with score, badges, and dynamic attributes.
     *    - `Project`: Defines a decentralized project (funding, status, required skills, impact).
     *    - `Contribution`: Tracks individual contributions to a project (contributor, skill used, impact score).
     *    - `Proposal`: Manages governance proposals (type, data, votes, status).
     *    - `treasuryAddress`: Address for managing protocol funds.
     *    - `aiPredictionOracle`: Address of an external AI-driven oracle (conceptual).
     *    - `delegatedSkillAuthorities`: Mapping for delegated validation powers.
     *
     * III. Function Categories & Summary
     *
     * A. Skill & Reputation Management (Soulbound AuraTokens)
     * --------------------------------------------------------
     * 1.  `registerSkill(string _name, uint256 _parentSkillId, string _description, bool _isCoreSkill)`:
     *     Registers a new skill type in the AuraForge system. Only the contract owner can call this.
     * 2.  `declareSkill(uint256 _skillId, bytes32 _proofHash)`:
     *     Allows a user to declare possession of a skill, optionally linking a hash of an off-chain
     *     proof (e.g., ZK proof, verifiable credential). Mints an AuraToken if user doesn't have one.
     * 3.  `requestSkillValidation(uint256 _skillId, address _validator, bytes32 _proofHash)`:
     *     User requests a specific, reputable validator to formally verify their declared skill.
     * 4.  `validateSkill(uint256 _validationRequestId, bool _isVerified, uint256 _level)`:
     *     A designated validator (or delegatee) confirms or rejects a user's skill, assigning an expertise level.
     * 5.  `revokeSkill(address _user, uint256 _skillId)`:
     *     Revokes a user's skill due to expiry, fraud, or a successful challenge. Callable by owner.
     * 6.  `updateAuraTokenMetadata(address _user)` (internal):
     *     Dynamically recalculates and updates a user's AuraToken (reputation score, skill badges)
     *     based on their validated skills and contributions. Triggered by relevant actions.
     * 7.  `getSkillDetails(uint256 _skillId)`:
     *     Retrieves detailed information about a registered skill.
     * 8.  `getUserSkills(address _user)`:
     *     Returns an array of all verified skills associated with a specific user.
     *
     * B. Project & Contribution Lifecycle
     * ------------------------------------
     * 9.  `proposeProject(string _name, string _description, uint256 _fundingGoal, uint256[] _requiredSkillIds)`:
     *     Submits a new project proposal, requiring a minimum AuraToken reputation score.
     * 10. `fundProject(uint256 _projectId)`:
     *     Allows users to contribute Ether to a proposed project. Automatically activates project if goal is met.
     * 11. `commitToProjectTask(uint256 _projectId, uint256 _skillId, string _taskDescription)`:
     *     A user formally commits to performing a task within an active project, specifying the skill they will use.
     * 12. `submitContribution(uint256 _projectId, string _contributionDescription, bytes32 _impactMetricHash)`:
     *     User submits proof of their completed contribution to a project, including a hash to off-chain impact data.
     * 13. `verifyContribution(uint256 _contributionId, bool _isSuccessful, uint256 _impactScore)`:
     *     A project manager or reputable validator assesses and verifies a contribution, assigning an impact score.
     * 14. `distributeProjectRewards(uint256 _projectId)`:
     *     Distributes collected project rewards to contributors based on their verified impact scores. Callable by proposer.
     * 15. `markProjectAsComplete(uint256 _projectId, bytes32 _finalReportHash)`:
     *     Marks a project as complete, potentially triggering final assessments and reward distribution.
     *
     * C. Adaptive Governance & Treasury
     * ----------------------------------
     * 16. `submitParameterProposal(ProposalType _proposalType, bytes _data, string _description, uint256 _votingDuration)`:
     *     Allows high-reputation users to propose changes to system parameters or treasury actions.
     * 17. `voteOnProposal(uint256 _proposalId, bool _vote)`:
     *     Users cast 'Yes' or 'No' votes on pending proposals, requiring a minimum AuraToken score.
     * 18. `executeProposal(uint256 _proposalId)`:
     *     Executes a proposal if its voting period has ended and it has achieved a majority 'Yes' vote.
     * 19. `_withdrawFundsFromTreasury(address _recipient, uint256 _amount)` (internal):
     *     Internal utility to transfer funds from the contract's treasury to a recipient, typically via governance.
     * 20. `setTreasuryAddress(address _newTreasuryAddress)`:
     *     Allows the owner to update the treasury address. In a full DAO, this would be a governance proposal.
     *
     * D. Advanced / Interoperability Features
     * -----------------------------------------
     * 21. `delegateSkillValidationAuthority(address _delegatee, uint256 _skillId, uint256 _duration)`:
     *     Allows a highly skilled and reputable validator to delegate their authority to validate a
     *     specific skill to another user for a limited time.
     * 22. `registerExternalSkillAttestation(address _user, uint256 _skillId, bytes32 _attestationHash)`:
     *     Records a hash of an external verifiable credential or ZK-proof for a user's skill,
     *     integrating with off-chain identity systems. Callable by owner.
     * 23. `challengeSkillValidation(uint256 _validationRequestId, string _reason)`:
     *     Enables any user with sufficient reputation to challenge a previously approved skill validation,
     *     triggering a dispute resolution process.
     * 24. `updateDynamicAuraAttribute(address _user, string _attributeKey, string _attributeValue)`:
     *     Allows a designated AI oracle or governance to update specific custom attributes on a user's
     *     AuraToken, enabling highly adaptive and data-driven reputation evolution.
     * 25. `setAIPredictionOracle(address _newOracleAddress)`:
     *     Sets the address of an external AI prediction oracle contract, enabling conceptual
     *     AI integration for insights like project success probability or contribution quality assessment.
     */

    // --- State Variables & Data Structures ---

    // Identity & Skills
    Counters.Counter private _skillIds;
    Counters.Counter private _validationRequestIds;

    struct Skill {
        uint256 id;
        string name;
        uint256 parentSkillId; // 0 for top-level skills
        string description;
        bool isCoreSkill; // Core skills might have higher validation requirements or impact.
        bool isActive;
    }
    mapping(uint256 => Skill) public skills;

    struct UserSkill {
        uint256 skillId;
        uint256 level; // e.g., 1 (Beginner) to 5 (Expert)
        uint256 lastValidatedAt;
        address validator; // Address of the validator or address(0) if external proof
        bytes32 proofHash; // Hash of a ZK proof or verifiable credential
        bool isVerified;
    }
    mapping(address => mapping(uint256 => UserSkill)) public userSkills; // user => skillId => UserSkill

    struct SkillValidationRequest {
        uint256 requestId;
        uint256 skillId;
        address applicant;
        address validator;
        bytes32 proofHash;
        uint256 requestedAt;
        uint8 status; // 0: Pending, 1: Approved, 2: Rejected, 3: Challenged
    }
    mapping(uint256 => SkillValidationRequest) public skillValidationRequests;

    // AuraToken (Conceptual SBT)
    struct AuraToken {
        address owner;
        uint256 reputationScore; // Aggregate score based on skills, contributions, validated impact
        uint256[] skillBadges; // Array of skill IDs for which user has level >= 3 (example threshold)
        string[] achievements; // Custom achievement strings (e.g., "First Project Contributor")
        uint256 lastUpdated;
        mapping(string => string) dynamicAttributes; // For AI-driven or custom metadata
    }
    mapping(address => AuraToken) public auraTokens;
    mapping(address => bool) private _hasAuraToken; // To check if an AuraToken has been minted for an address

    // Project & Contributions
    Counters.Counter private _projectIds;
    Counters.Counter private _contributionIds;

    enum ProjectStatus { Proposed, Active, Completed, Failed, Cancelled }

    struct Project {
        uint256 id;
        string name;
        string description;
        address proposer;
        ProjectStatus status;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 startTime; // Timestamp when project became Active
        uint256 endTime; // Timestamp when project was marked Completed/Failed
        uint256[] requiredSkills; // Skill IDs crucial for project success
        uint256 impactScore; // Cumulative impact score from verified contributions
        uint256 rewardPool; // Funds specifically for contributor rewards
        mapping(address => bool) hasCommitted; // user => committed to a task (simplified: one task per project)
    }
    mapping(uint256 => Project) public projects;

    struct Contribution {
        uint256 id;
        uint256 projectId;
        address contributor;
        uint256 skillUsed;
        string description;
        bytes32 impactMetricHash; // Hash of off-chain impact data (e.g., link to metrics, code diffs)
        uint256 submittedAt;
        uint256 verifiedAt;
        address verifier; // Project manager or designated validator
        uint256 impactScore; // Score given by verifier
        bool rewardClaimed;
    }
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => uint256[]) public projectContributions; // projectId => array of contributionIds

    // Adaptive Governance & Treasury
    Counters.Counter private _proposalIds;

    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum ProposalType { ParameterChange, TreasuryWithdrawal, ProjectApproval, Custom }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes data; // Encoded function call for parameter changes or specific data for other types
        string description;
        uint256 creationTime;
        uint256 endTime; // For voting period
        uint256 requiredAuraScore; // Min AuraScore to vote
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }
    mapping(uint256 => Proposal) public proposals;

    address public treasuryAddress;
    address public aiPredictionOracle; // Address of an external AI-driven oracle contract (conceptual)

    // Delegated Skill Authority: validator => skillId => delegatee => expiryTimestamp
    mapping(address => mapping(uint256 => mapping(address => uint256))) public delegatedSkillAuthorities;

    // --- Event Declarations ---
    event SkillRegistered(uint256 indexed skillId, string name, uint256 parentSkillId);
    event SkillDeclared(address indexed user, uint256 indexed skillId, bytes32 proofHash);
    event SkillValidationRequested(uint256 indexed requestId, address indexed applicant, uint256 indexed skillId, address validator);
    event SkillValidated(uint256 indexed requestId, address indexed applicant, uint256 indexed skillId, uint256 level, address validator, bool isVerified);
    event SkillRevoked(address indexed user, uint256 indexed skillId);
    event AuraTokenUpdated(address indexed user, uint256 newReputationScore);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string name, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectTaskCommitted(uint256 indexed projectId, address indexed contributor, uint256 skillId);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed projectId, address indexed contributor);
    event ContributionVerified(uint256 indexed contributionId, uint256 indexed projectId, address indexed verifier, uint256 impactScore);
    event RewardsDistributed(uint256 indexed projectId, uint256 totalDistributed);
    event ProjectStatusChanged(uint256 indexed projectId, ProjectStatus newStatus);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event SkillValidationAuthorityDelegated(address indexed validator, address indexed delegatee, uint256 indexed skillId, uint256 expiry);
    event ExternalSkillAttestationRegistered(address indexed user, uint256 indexed skillId, bytes32 attestationHash);
    event SkillValidationChallenge(uint256 indexed requestId, address indexed challenger, string reason);
    event DynamicAuraAttributeUpdated(address indexed user, string attributeKey, string attributeValue);
    event AIPredictionOracleSet(address indexed newOracleAddress);

    // --- Constructor ---
    constructor(address _initialTreasuryAddress, address _initialAIPredictionOracle) Ownable(msg.sender) {
        require(_initialTreasuryAddress != address(0), "Treasury address cannot be zero");
        treasuryAddress = _initialTreasuryAddress;
        aiPredictionOracle = _initialAIPredictionOracle; // Can be address(0) initially if not set
    }

    // --- Modifier for AuraToken existence ---
    modifier hasAuraToken(address _user) {
        require(_hasAuraToken[_user], "AuraToken not minted for user");
        _;
    }

    // --- A. Skill & Reputation Management ---

    /**
     * @dev Registers a new skill in the system. Only owner can add core skills.
     * @param _name The name of the skill (e.g., "Solidity Development").
     * @param _parentSkillId The ID of the parent skill (0 for top-level skills).
     * @param _description A brief description of the skill.
     * @param _isCoreSkill True if this is a fundamental, high-impact skill.
     * @return The ID of the newly registered skill.
     */
    function registerSkill(
        string calldata _name,
        uint256 _parentSkillId,
        string calldata _description,
        bool _isCoreSkill
    ) external onlyOwner returns (uint256) {
        if (_parentSkillId != 0) {
            require(skills[_parentSkillId].id != 0, "Parent skill does not exist");
            require(skills[_parentSkillId].isActive, "Parent skill is not active");
        }
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId] = Skill({
            id: newSkillId,
            name: _name,
            parentSkillId: _parentSkillId,
            description: _description,
            isCoreSkill: _isCoreSkill,
            isActive: true
        });
        emit SkillRegistered(newSkillId, _name, _parentSkillId);
        return newSkillId;
    }

    /**
     * @dev User declares they possess a skill, optionally providing a hash for a ZK proof or verifiable credential.
     *      This is the first step before formal validation. Mints an AuraToken if it doesn't exist.
     * @param _skillId The ID of the skill being declared.
     * @param _proofHash A hash representing an off-chain proof of skill (e.g., ZK proof, VC hash). Can be empty (bytes32(0)).
     */
    function declareSkill(uint256 _skillId, bytes32 _proofHash) external {
        require(skills[_skillId].id != 0, "Skill does not exist");
        require(skills[_skillId].isActive, "Skill is not active");
        require(userSkills[_msgSender()][_skillId].skillId == 0 || !userSkills[_msgSender()][_skillId].isVerified, "Skill already declared or verified");

        // Mint AuraToken if not already minted
        if (!_hasAuraToken[_msgSender()]) {
            _mintAuraToken(_msgSender());
        }

        userSkills[_msgSender()][_skillId] = UserSkill({
            skillId: _skillId,
            level: 0, // Level will be set upon validation
            lastValidatedAt: 0,
            validator: address(0), // No validator yet
            proofHash: _proofHash,
            isVerified: false
        });
        emit SkillDeclared(_msgSender(), _skillId, _proofHash);
    }

    /**
     * @dev User requests a specific validator to formally verify their declared skill.
     *      The validator must have a certain AuraToken score and potentially the parent skill.
     * @param _skillId The ID of the skill to be validated.
     * @param _validator The address of the user requested to validate.
     * @param _proofHash Optional, a hash of an off-chain proof (can override initial declaration proof).
     */
    function requestSkillValidation(uint256 _skillId, address _validator, bytes32 _proofHash) external hasAuraToken(_msgSender()) {
        require(userSkills[_msgSender()][_skillId].skillId != 0, "Skill not declared by user");
        require(!userSkills[_msgSender()][_skillId].isVerified, "Skill already verified");
        require(_validator != address(0) && _validator != _msgSender(), "Invalid validator address");
        // Ensure validator has sufficient reputation and relevant skills (e.g., parent skill or same skill at higher level)
        require(_hasAuraToken[_validator] && auraTokens[_validator].reputationScore >= 100, "Validator insufficient reputation"); // Example threshold
        require(userSkills[_validator][_skillId].isVerified || userSkills[_validator][skills[_skillId].parentSkillId].isVerified, "Validator lacks relevant skill"); // Example logic

        _validationRequestIds.increment();
        uint256 requestId = _validationRequestIds.current();
        skillValidationRequests[requestId] = SkillValidationRequest({
            requestId: requestId,
            skillId: _skillId,
            applicant: _msgSender(),
            validator: _validator,
            proofHash: _proofHash == bytes32(0) ? userSkills[_msgSender()][_skillId].proofHash : _proofHash,
            requestedAt: block.timestamp,
            status: 0 // Pending
        });
        emit SkillValidationRequested(requestId, _msgSender(), _skillId, _validator);
    }

    /**
     * @dev A validator confirms or rejects a user's skill based on provided proof or off-chain assessment.
     *      Can be called by the designated validator or a delegated authority.
     * @param _validationRequestId The ID of the validation request.
     * @param _isVerified True if the skill is confirmed, false otherwise.
     * @param _level The level of expertise (1-5) if verified.
     */
    function validateSkill(uint256 _validationRequestId, bool _isVerified, uint256 _level) external {
        SkillValidationRequest storage req = skillValidationRequests[_validationRequestId];
        require(req.status == 0, "Validation request not pending");
        require(req.applicant != address(0), "Invalid validation request");
        // Check if caller is the designated validator OR a delegatee for this skill
        bool isValidator = (_msgSender() == req.validator);
        bool isDelegatee = (delegatedSkillAuthorities[req.validator][req.skillId][_msgSender()] > block.timestamp);
        require(isValidator || isDelegatee, "Not authorized to validate this skill");

        req.status = _isVerified ? 1 : 2; // Approved or Rejected

        UserSkill storage userSkill = userSkills[req.applicant][req.skillId];
        userSkill.isVerified = _isVerified;
        userSkill.lastValidatedAt = block.timestamp;
        userSkill.validator = _msgSender();

        if (_isVerified) {
            require(_level > 0 && _level <= 5, "Skill level must be between 1 and 5");
            userSkill.level = _level;
            _updateAuraToken(req.applicant); // Update applicant's AuraToken
            // Potentially reward validator for good validation
        } else {
            userSkill.level = 0;
        }

        emit SkillValidated(_validationRequestId, req.applicant, req.skillId, userSkill.level, _msgSender(), _isVerified);
    }

    /**
     * @dev Revokes a skill from a user, typically due to expiry, fraud, or a challenge.
     *      Can be called by owner or by successful challenge resolution (after governance).
     * @param _user The address of the user.
     * @param _skillId The ID of the skill to revoke.
     */
    function revokeSkill(address _user, uint256 _skillId) external onlyOwner hasAuraToken(_user) {
        require(userSkills[_user][_skillId].isVerified, "Skill is not verified or already revoked");
        userSkills[_user][_skillId].isVerified = false;
        userSkills[_user][_skillId].level = 0;
        userSkills[_user][_skillId].lastValidatedAt = 0; // Reset validation timestamp
        _updateAuraToken(_user); // Update user's AuraToken
        emit SkillRevoked(_user, _skillId);
    }

    /**
     * @dev Internal function to mint an AuraToken for a user if they don't have one.
     *      AuraTokens are conceptual Soulbound Tokens (SBTs), meaning they are non-transferable
     *      and represent a user's on-chain identity and reputation.
     * @param _user The address to mint the AuraToken for.
     */
    function _mintAuraToken(address _user) internal {
        require(!_hasAuraToken[_user], "AuraToken already minted for user");
        auraTokens[_user] = AuraToken({
            owner: _user,
            reputationScore: 0,
            skillBadges: new uint256[](0),
            achievements: new string[](0),
            lastUpdated: block.timestamp
        });
        _hasAuraToken[_user] = true;
        _updateAuraToken(_user); // Initial update to calculate score/badges
    }

    /**
     * @dev Dynamically updates a user's AuraToken (reputation score, skill badges, achievements)
     *      based on their validated skills, contributions, and other activities.
     *      This is a core mechanism for the evolving nature of the SBT.
     * @param _user The address whose AuraToken metadata needs updating.
     */
    function _updateAuraToken(address _user) internal {
        require(_hasAuraToken[_user], "AuraToken not minted for user");
        AuraToken storage token = auraTokens[_user];
        uint256 newScore = 0;
        uint256[] memory newSkillBadges = new uint256[](0);

        // Calculate score from skills
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (userSkills[_user][i].isVerified) {
                newScore += userSkills[_user][i].level * 10; // Each level adds 10 points (example)
                if (userSkills[_user][i].level >= 3) { // Example: skills with level >= 3 become badges
                    newSkillBadges = _appendSkill(newSkillBadges, i);
                }
            }
        }

        // TODO: Integrate impactScore from contributions here for a more comprehensive reputation score.
        // This would require iterating `projectContributions` and summing `impactScore` for the user.
        // For simplicity, it's omitted in this example's reputation calculation.

        token.reputationScore = newScore;
        token.skillBadges = newSkillBadges;
        token.lastUpdated = block.timestamp;

        // Potentially add achievements based on score or specific actions
        if (newScore > 500 && !_hasAchievement(token, "Aura Master")) {
            token.achievements.push("Aura Master");
        } else if (newScore > 100 && !_hasAchievement(token, "Aura Initiate")) {
            token.achievements.push("Aura Initiate");
        }

        emit AuraTokenUpdated(_user, newScore);
    }

    // Helper to avoid duplicate skill badges
    function _appendSkill(uint256[] memory arr, uint256 value) internal pure returns (uint256[] memory) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return arr;
            }
        }
        uint256[] memory newArr = new uint256[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = value;
        return newArr;
    }

    // Helper to check for achievement existence
    function _hasAchievement(AuraToken storage token, string memory _achievement) internal view returns (bool) {
        for (uint256 i = 0; i < token.achievements.length; i++) {
            if (keccak256(abi.encodePacked(token.achievements[i])) == keccak256(abi.encodePacked(_achievement))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Retrieves details about a registered skill.
     * @param _skillId The ID of the skill.
     * @return Skill struct containing details.
     */
    function getSkillDetails(uint256 _skillId) external view returns (Skill memory) {
        require(skills[_skillId].id != 0, "Skill does not exist");
        return skills[_skillId];
    }

    /**
     * @dev Retrieves all verified skills for a given user.
     * @param _user The address of the user.
     * @return An array of UserSkill structs.
     */
    function getUserSkills(address _user) external view returns (UserSkill[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (userSkills[_user][i].isVerified) {
                count++;
            }
        }

        UserSkill[] memory userVerifiedSkills = new UserSkill[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (userSkills[_user][i].isVerified) {
                userVerifiedSkills[index] = userSkills[_user][i];
                index++;
            }
        }
        return userVerifiedSkills;
    }

    // --- B. Project & Contribution Lifecycle ---

    /**
     * @dev Proposes a new project for the community. Requires a minimum reputation score.
     * @param _name The name of the project.
     * @param _description A detailed description of the project.
     * @param _fundingGoal The target funding amount in wei.
     * @param _requiredSkillIds An array of skill IDs deemed essential for this project.
     * @return The ID of the newly proposed project.
     */
    function proposeProject(
        string calldata _name,
        string calldata _description,
        uint256 _fundingGoal,
        uint256[] calldata _requiredSkillIds
    ) external hasAuraToken(_msgSender()) returns (uint256) {
        require(auraTokens[_msgSender()].reputationScore >= 50, "Proposer insufficient reputation"); // Example threshold
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].id != 0, "Required skill does not exist");
            require(skills[_requiredSkillIds[i]].isActive, "Required skill is not active");
        }

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        projects[newProjectId] = Project({
            id: newProjectId,
            name: _name,
            description: _description,
            proposer: _msgSender(),
            status: ProjectStatus.Proposed,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            startTime: 0,
            endTime: 0,
            requiredSkills: _requiredSkillIds,
            impactScore: 0,
            rewardPool: 0
        });
        emit ProjectProposed(newProjectId, _msgSender(), _name, _fundingGoal);
        return newProjectId;
    }

    /**
     * @dev Allows users to contribute funds (ETH) to a proposed project.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "Project not in funding phase");
        require(msg.value > 0, "Must send a positive amount");

        project.currentFunding += msg.value;
        // If funding goal is met, mark project as active
        if (project.status == ProjectStatus.Proposed && project.currentFunding >= project.fundingGoal) {
            project.status = ProjectStatus.Active;
            project.startTime = block.timestamp;
            emit ProjectStatusChanged(_projectId, ProjectStatus.Active);
        }
        // Allocate a percentage to the reward pool (e.g., 80% to reward pool, 20% to treasury/operations)
        uint256 rewardAmount = (msg.value * 80) / 100;
        uint256 treasuryAmount = msg.value - rewardAmount;
        
        project.rewardPool += rewardAmount;
        // Send remaining to treasury
        if (treasuryAmount > 0) {
            payable(treasuryAddress).transfer(treasuryAmount);
        }

        emit ProjectFunded(_projectId, _msgSender(), msg.value);
    }

    /**
     * @dev User commits to performing a specific task within an active project,
     *      declaring the skill they will utilize.
     * @param _projectId The ID of the project.
     * @param _skillId The ID of the skill the user will apply.
     * @param _taskDescription A brief description of the task being committed to.
     */
    function commitToProjectTask(uint256 _projectId, uint256 _skillId, string calldata _taskDescription) external hasAuraToken(_msgSender()) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Active, "Project not active");
        require(userSkills[_msgSender()][_skillId].isVerified && userSkills[_msgSender()][_skillId].level > 0, "User does not have verified skill");
        require(!project.hasCommitted[_msgSender()], "User already committed to a task in this project"); // Simple for one task per user
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty");

        // Advanced: Check if skill matches requiredSkills, perhaps with minimum level
        bool skillMatchesRequired = false;
        for (uint256 i = 0; i < project.requiredSkills.length; i++) {
            if (project.requiredSkills[i] == _skillId) {
                skillMatchesRequired = true;
                break;
            }
        }
        require(skillMatchesRequired, "Committed skill not among project's required skills");

        project.hasCommitted[_msgSender()] = true; // Mark commitment
        // In a more complex system, this would register a specific task ID

        emit ProjectTaskCommitted(_projectId, _msgSender(), _skillId);
    }

    /**
     * @dev User submits proof of their contribution to a project.
     *      This could be a hash of a GitHub commit, IPFS link to documentation, etc.
     * @param _projectId The ID of the project.
     * @param _contributionDescription A description of the contribution made.
     * @param _impactMetricHash A hash pointing to off-chain data that quantifies impact.
     * @return The ID of the newly submitted contribution.
     */
    function submitContribution(uint256 _projectId, string calldata _contributionDescription, bytes32 _impactMetricHash) external hasAuraToken(_msgSender()) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Active, "Project not active for contributions");
        require(project.hasCommitted[_msgSender()], "User has not committed to this project");
        require(bytes(_contributionDescription).length > 0, "Contribution description cannot be empty");

        _contributionIds.increment();
        uint256 newContributionId = _contributionIds.current();

        // Find the skill the user committed with (simplified, in a real system this would be per-task)
        uint256 committedSkill = 0;
        for (uint256 i = 0; i < project.requiredSkills.length; i++) {
            if (userSkills[_msgSender()][project.requiredSkills[i]].isVerified && project.hasCommitted[_msgSender()]) { // Basic check
                committedSkill = project.requiredSkills[i];
                break;
            }
        }
        require(committedSkill != 0, "Could not determine committed skill for this user/project");

        contributions[newContributionId] = Contribution({
            id: newContributionId,
            projectId: _projectId,
            contributor: _msgSender(),
            skillUsed: committedSkill,
            description: _contributionDescription,
            impactMetricHash: _impactMetricHash,
            submittedAt: block.timestamp,
            verifiedAt: 0,
            verifier: address(0),
            impactScore: 0,
            rewardClaimed: false
        });
        projectContributions[_projectId].push(newContributionId);
        emit ContributionSubmitted(newContributionId, _projectId, _msgSender());
        return newContributionId;
    }

    /**
     * @dev A designated project manager or high-reputation validator verifies a contribution,
     *      assigning an impact score. This score directly influences reputation and rewards.
     *      Could potentially interact with an AI oracle for impact suggestion.
     * @param _contributionId The ID of the contribution to verify.
     * @param _isSuccessful True if the contribution is deemed successful.
     * @param _impactScore The score reflecting the impact (e.g., 0-100).
     */
    function verifyContribution(uint256 _contributionId, bool _isSuccessful, uint256 _impactScore) external hasAuraToken(_msgSender()) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.id != 0, "Contribution does not exist");
        require(contribution.verifier == address(0), "Contribution already verified");
        Project storage project = projects[contribution.projectId];
        require(project.status == ProjectStatus.Active, "Project not active");
        // Only project proposer or a high-reputation manager can verify
        require(_msgSender() == project.proposer || auraTokens[_msgSender()].reputationScore >= 200, "Not authorized to verify contributions"); // Example threshold

        contribution.verifier = _msgSender();
        contribution.verifiedAt = block.timestamp;
        contribution.impactScore = _isSuccessful ? _impactScore : 0;

        if (_isSuccessful) {
            require(_impactScore > 0, "Impact score must be positive for successful contribution");
            project.impactScore += _impactScore; // Aggregate project impact
            _updateAuraToken(contribution.contributor); // Update contributor's AuraToken
        }

        emit ContributionVerified(_contributionId, contribution.projectId, _msgSender(), contribution.impactScore);
    }

    /**
     * @dev Distributes rewards from the project's reward pool to contributors
     *      based on their verified impact scores. This adaptive distribution
     *      rewards higher impact more. Only callable by project proposer after project completion.
     * @param _projectId The ID of the project.
     */
    function distributeProjectRewards(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Completed, "Project not completed");
        require(_msgSender() == project.proposer, "Only project proposer can distribute rewards");
        require(project.rewardPool > 0, "No funds in reward pool to distribute");
        require(project.impactScore > 0, "No total impact score recorded for distribution");

        uint256 totalDistributed = 0;
        uint256[] memory projectContribIds = projectContributions[_projectId];

        for (uint256 i = 0; i < projectContribIds.length; i++) {
            Contribution storage contrib = contributions[projectContribIds[i]];
            if (contrib.impactScore > 0 && !contrib.rewardClaimed) {
                // Proportional distribution based on individual impact vs. total project impact
                uint256 rewardAmount = (project.rewardPool * contrib.impactScore) / project.impactScore; 
                if (rewardAmount > 0) {
                    payable(contrib.contributor).transfer(rewardAmount);
                    contrib.rewardClaimed = true;
                    totalDistributed += rewardAmount;
                }
            }
        }
        project.rewardPool = 0; // Clear reward pool after distribution
        emit RewardsDistributed(_projectId, totalDistributed);
    }

    /**
     * @dev Marks a project as complete. This triggers final impact assessments and reward distribution.
     * @param _projectId The ID of the project.
     * @param _finalReportHash Hash of an off-chain final report or artifact.
     */
    function markProjectAsComplete(uint256 _projectId, bytes32 _finalReportHash) external {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.status == ProjectStatus.Active, "Project is not active");
        require(_msgSender() == project.proposer, "Only project proposer can mark as complete");

        project.status = ProjectStatus.Completed;
        project.endTime = block.timestamp;
        // Further actions could be triggered here, e.g., AI oracle for overall impact assessment
        // if (aiPredictionOracle != address(0)) {
        //     // Conceptual call to AI oracle for post-completion analysis
        //     // IAIOracle(aiPredictionOracle).assessProjectImpact(_projectId, _finalReportHash);
        // }

        emit ProjectStatusChanged(_projectId, ProjectStatus.Completed);
    }

    // --- C. Adaptive Governance & Treasury ---

    /**
     * @dev Submits a proposal for governance, potentially for parameter changes or treasury actions.
     *      Requires a minimum AuraToken score.
     * @param _proposalType The type of proposal (e.g., ParameterChange, TreasuryWithdrawal).
     * @param _data Encoded function call for ParameterChange, or specific data for other types.
     * @param _description A human-readable description of the proposal.
     * @param _votingDuration The duration for which voting will be open (in seconds).
     * @return The ID of the newly submitted proposal.
     */
    function submitParameterProposal(
        ProposalType _proposalType,
        bytes calldata _data,
        string calldata _description,
        uint256 _votingDuration
    ) external hasAuraToken(_msgSender()) returns (uint256) {
        require(auraTokens[_msgSender()].reputationScore >= 150, "Proposer insufficient reputation for governance"); // Example threshold
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_votingDuration > 0, "Voting duration must be positive");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: _msgSender(),
            proposalType: _proposalType,
            data: _data,
            description: _description,
            creationTime: block.timestamp,
            endTime: block.timestamp + _votingDuration,
            requiredAuraScore: 50, // Example: minimum AuraScore to vote
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Pending
        });

        emit ProposalSubmitted(newProposalId, _msgSender(), _proposalType, _description);
        return newProposalId;
    }

    /**
     * @dev Allows users to vote on a proposal. Voting power is simply 1 vote per eligible user,
     *      but could be weighted by AuraToken score in a more complex system.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'Yes', False for 'No'.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external hasAuraToken(_msgSender()) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Voting is not open for this proposal");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "User already voted on this proposal");
        require(auraTokens[_msgSender()].reputationScore >= proposal.requiredAuraScore, "Insufficient AuraScore to vote");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit Voted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes a proposal if the voting period has ended and it has passed.
     *      Passage logic: more yes votes than no votes (simple majority).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending status");
        require(block.timestamp > proposal.endTime, "Voting period not yet ended");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.status = ProposalStatus.Approved;
            // Execute the proposal's action (simplified direct call)
            if (proposal.proposalType == ProposalType.ParameterChange) {
                // In a robust system, this would use a timelock and a more secure way
                // to call arbitrary functions via a `Governor` contract or a proxy.
                (bool success,) = address(this).call(proposal.data);
                require(success, "Parameter change execution failed");
            } else if (proposal.proposalType == ProposalType.TreasuryWithdrawal) {
                // Assuming `_data` for TreasuryWithdrawal contains `abi.encode(recipient, amount)`
                (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));
                _withdrawFundsFromTreasury(recipient, amount);
            }
            // Add other proposal types here

            proposal.status = ProposalStatus.Executed; // Mark as executed after successful operation
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Could emit an event for rejected proposals.
        }
    }

    /**
     * @dev Internal function to withdraw funds from the contract's treasury.
     *      This function is typically called by a successful governance proposal.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function _withdrawFundsFromTreasury(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Amount must be positive");
        require(address(this).balance >= _amount, "Insufficient balance in contract treasury");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Allows the owner to directly set the treasury address. In a full DAO, this would be a governance proposal.
     * @param _newTreasuryAddress The new address for the treasury.
     */
    function setTreasuryAddress(address _newTreasuryAddress) external onlyOwner {
        require(_newTreasuryAddress != address(0), "New treasury address cannot be zero");
        treasuryAddress = _newTreasuryAddress;
    }

    // --- D. Advanced / Interoperability Features ---

    /**
     * @dev Allows a high-reputation validator to delegate their skill validation authority
     *      for a specific skill to another user for a limited duration.
     *      This promotes liquid democracy and distributed validation.
     * @param _delegatee The address to delegate validation authority to.
     * @param _skillId The ID of the skill for which authority is delegated.
     * @param _duration The duration in seconds for which the delegation is valid.
     */
    function delegateSkillValidationAuthority(address _delegatee, uint256 _skillId, uint256 _duration) external hasAuraToken(_msgSender()) {
        require(_delegatee != address(0) && _delegatee != _msgSender(), "Invalid delegatee address");
        require(skills[_skillId].id != 0, "Skill does not exist");
        require(_duration > 0, "Delegation duration must be positive");
        // Delegator must have high reputation and be a verified validator for this skill
        require(auraTokens[_msgSender()].reputationScore >= 300, "Delegator insufficient reputation"); // Example threshold
        require(userSkills[_msgSender()][_skillId].isVerified && userSkills[_msgSender()][_skillId].level >= 4, "Delegator lacks expertise in this skill"); // Example level

        delegatedSkillAuthorities[_msgSender()][_skillId][_delegatee] = block.timestamp + _duration;
        emit SkillValidationAuthorityDelegated(_msgSender(), _delegatee, _skillId, block.timestamp + _duration);
    }

    /**
     * @dev Registers an attestation of skill from an external verifiable credential system
     *      or another blockchain. The actual verification happens off-chain,
     *      but its proof/hash is recorded on-chain.
     * @param _user The address of the user who has the external attestation.
     * @param _skillId The ID of the skill being attested.
     * @param _attestationHash A hash linking to the external verifiable credential or proof.
     */
    function registerExternalSkillAttestation(address _user, uint256 _skillId, bytes32 _attestationHash) external onlyOwner { // Could be permissioned by governance too
        require(skills[_skillId].id != 0, "Skill does not exist");
        require(_attestationHash != bytes32(0), "Attestation hash cannot be zero");

        // Mint AuraToken if not already minted
        if (!_hasAuraToken[_user]) {
            _mintAuraToken(_user);
        }

        UserSkill storage userSkill = userSkills[_user][_skillId];
        userSkill.skillId = _skillId; // Ensure skill entry exists
        userSkill.isVerified = true; // Assumes external attestation means verified
        userSkill.level = 5; // Example: External attestations are high-level
        userSkill.lastValidatedAt = block.timestamp;
        userSkill.validator = address(0); // Marked as externally validated
        userSkill.proofHash = _attestationHash;

        _updateAuraToken(_user);
        emit ExternalSkillAttestationRegistered(_user, _skillId, _attestationHash);
    }

    /**
     * @dev Allows any user to challenge an existing skill validation.
     *      A successful challenge could lead to skill revocation or validator penalty.
     *      This would trigger a dispute resolution process (e.g., governance vote, arbitration).
     * @param _validationRequestId The ID of the skill validation request to challenge.
     * @param _reason A string explaining the reason for the challenge.
     */
    function challengeSkillValidation(uint256 _validationRequestId, string calldata _reason) external hasAuraToken(_msgSender()) {
        SkillValidationRequest storage req = skillValidationRequests[_validationRequestId];
        require(req.status == 1, "Only approved validations can be challenged"); // Only challenge approved ones
        require(_msgSender() != req.applicant && _msgSender() != req.validator, "Challenger cannot be applicant or validator");
        require(auraTokens[_msgSender()].reputationScore >= 100, "Challenger insufficient reputation"); // Example threshold
        require(bytes(_reason).length > 0, "Challenge reason cannot be empty");

        req.status = 3; // Mark as Challenged
        // In a real system, this would trigger an on-chain dispute resolution process,
        // potentially requiring staking of tokens, or creating a governance proposal.
        // For this example, we simply change the status.

        emit SkillValidationChallenge(_validationRequestId, _msgSender(), _reason);
    }

    /**
     * @dev Allows a designated AI oracle or governance to update specific
     *      dynamic attributes on a user's AuraToken. This enables highly flexible
     *      and data-driven reputation evolution.
     * @param _user The address of the user whose AuraToken is being updated.
     * @param _attributeKey The key of the attribute (e.g., "AI_SentimentScore", "ActivityMetric").
     * @param _attributeValue The new value for the attribute.
     */
    function updateDynamicAuraAttribute(address _user, string calldata _attributeKey, string calldata _attributeValue) external {
        // Only the AI oracle or owner/governance can call this
        require(_msgSender() == aiPredictionOracle || _msgSender() == owner(), "Not authorized to update dynamic attributes");
        require(_hasAuraToken[_user], "AuraToken not minted for user");
        require(bytes(_attributeKey).length > 0, "Attribute key cannot be empty");

        auraTokens[_user].dynamicAttributes[_attributeKey] = _attributeValue;
        auraTokens[_user].lastUpdated = block.timestamp; // Mark as updated

        emit DynamicAuraAttributeUpdated(_user, _attributeKey, _attributeValue);
    }

    /**
     * @dev Sets the address of an external AI prediction oracle contract.
     *      This oracle can provide data or insights for project success,
     *      contribution impact, or reputation adjustments.
     * @param _newOracleAddress The address of the new AI prediction oracle.
     */
    function setAIPredictionOracle(address _newOracleAddress) external onlyOwner {
        aiPredictionOracle = _newOracleAddress;
        emit AIPredictionOracleSet(_newOracleAddress);
    }

    // --- Utility Functions ---

    /**
     * @dev Allows the owner to deactivate a skill, preventing new declarations/validations.
     * @param _skillId The ID of the skill to deactivate.
     */
    function deactivateSkill(uint256 _skillId) external onlyOwner {
        require(skills[_skillId].id != 0, "Skill does not exist");
        skills[_skillId].isActive = false;
    }

    // Fallback function to receive Ether for project funding or treasury
    receive() external payable {}
}
```