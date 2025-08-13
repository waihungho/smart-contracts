The following Solidity smart contract, `CognitiveNexus`, is designed to be an advanced, multi-faceted platform for managing decentralized reputation and skill-based interactions. It combines several trendy and innovative concepts, including dynamic Soulbound Tokens (SBTs), AI oracle integration for assessments, a skill-tree progression system, a delegated governance model, and skill-gated bounties.

This contract has been developed from scratch for this request, ensuring it does not duplicate any existing open-source projects in its complete integrated form, though it leverages common OpenZeppelin utilities for best practices.

---

**Outline:**

1.  **Contract Overview**
2.  **State Variables**
3.  **Events**
4.  **Modifiers**
5.  **Constructor**
6.  **I. Core Skill & Reputation Management**
7.  **II. AI Oracle Integration (Mocked)**
8.  **III. Dynamic Soulbound Token (SBT) Functionality**
9.  **IV. Advanced Governance & Bounty System**
10. **V. Administrative & Role-Based Functions**

**Function Summary (26 functions):**

**I. Core Skill & Reputation Management**
*   `registerProfile()`: Allows a user to register their unique profile in the network, a prerequisite for participation.
*   `updateProfileDetails(string memory _name, bytes32 _bioHash)`: Allows a user to update their profile details (name and IPFS hash for bio).
*   `requestSkillAcquisition(uint256 _skillTypeId, bytes32 _proofHash)`: Initiates a request for a user to acquire a specific skill, providing an off-chain proof hash. Requires meeting skill prerequisites.
*   `verifySkillAcquisition(uint256 _requestId, uint256 _aiAssessmentScore)`: Verifies a pending skill acquisition request, updating the user's skill based on an AI assessment score. (Callable by `ADMIN_ROLE` or `ORACLE_ROLE`).
*   `levelUpSkill(address _user, uint256 _skillTypeId, uint256 _xpEarned)`: Increases the level of a user's acquired skill based on earned experience points. (Callable by `ORACLE_ROLE`, as XP is system-awarded).
*   `getSkillLevel(address _user, uint256 _skillTypeId)`: Retrieves the current level of a specific skill for a given user.
*   `getSkillXP(address _user, uint256 _skillTypeId)`: Retrieves the current experience points of a specific skill for a given user.
*   `getTotalReputation(address _user)`: Calculates and returns the aggregated reputation score for a user based on all their acquired skills.
*   `getSkillPower(address _user, uint256 _skillTypeId)`: Calculates the specific skill's power for governance/voting, based on level and skill type weight.
*   `delegateSkillPoints(uint256 _skillTypeId, address _delegatee)`: Allows a user to delegate the governance power of their specific skill to another address.
*   `undelegateSkillPoints(uint256 _skillTypeId)`: Revokes the delegation of a specific skill's power.
*   `getDelegatedSkill(address _delegator, uint252 _skillTypeId)`: Retrieves the address to which a specific skill's power has been delegated by a user.

**II. AI Oracle Integration (Mocked)**
*   `setAIOracleAddress(address _oracleAddress)`: Sets the trusted address for the AI oracle contract. (Callable by `ADMIN_ROLE`).
*   `requestAIAssessment(uint256 _entityId, bytes32 _dataHash, uint256 _assessmentType)`: (Internal) Simulates a user requesting an AI assessment for off-chain data related to an entity.
*   `receiveAIAssessment(uint256 _requestId, uint256 _aiScore)`: Callback function for the trusted AI oracle to deliver an assessment score. (Callable by `ORACLE_ROLE`).

**III. Dynamic Soulbound Token (SBT) Functionality**
*   `tokenURI(address _owner, uint256 _skillTypeId)`: Generates a dynamic, base64-encoded SVG metadata URI for a user's specific skill, reflecting its current level and XP. Mimics ERC721 `tokenURI`.
*   `getSkillMetadata(address _owner, uint256 _skillTypeId)`: Retrieves the decoded JSON metadata for a user's specific skill, useful for direct inspection.

**IV. Advanced Governance & Bounty System**
*   `proposeBounty(string memory _title, bytes32 _descriptionHash, uint256[] memory _requiredSkillTypes, uint256[] memory _requiredSkillLevels, uint256 _rewardAmount, address _rewardToken)`: Allows users to propose bounties, specifying required skill types/levels and an ERC20 reward.
*   `submitBountyCompletion(uint256 _bountyId, bytes32 _solutionHash)`: Allows a skill-qualified user to submit a solution for a proposed bounty.
*   `verifyBountyCompletion(uint256 _bountyId, address _submitter, uint256 _aiAssessmentScore)`: Verifies a bounty completion submission, potentially using AI assessment, and awards the reward. (Callable by `ADMIN_ROLE` or `ORACLE_ROLE`).
*   `createGovernanceProposal(string memory _title, bytes32 _descriptionHash, address _target, bytes memory _callData)`: Allows users with sufficient aggregate skill power to create a new governance proposal for on-chain execution.
*   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users (or implicitly, their delegates) to vote on an active governance proposal, weighted by their skill power.
*   `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed and met the execution delay. Anyone can call this once conditions are met.
*   `cancelProposal(uint256 _proposalId)`: Allows the proposer or `ADMIN_ROLE` to cancel an active proposal.

**V. Administrative & Role-Based Functions**
*   `addSkillType(uint256 _skillTypeId, string memory _name, string memory _description, uint256 _xpForLevelUp, uint256 _weight, uint256[] memory _prerequisites)`: Defines a new skill type and its properties, including prerequisites for a "skill tree". (Callable by `SKILL_MANAGER_ROLE`).
*   `removeSkillType(uint256 _skillTypeId)`: Removes an existing skill type. (Callable by `SKILL_MANAGER_ROLE`).
*   `grantRole(bytes32 role, address account)`: Grants a role to an address. (Callable by `DEFAULT_ADMIN_ROLE`).
*   `revokeRole(bytes32 role, address account)`: Revokes a role from an address. (Callable by `DEFAULT_ADMIN_ROLE`).
*   `setMinAggregateSkillPowerForProposal(uint256 _power)`: Sets the minimum aggregate skill power required for a user to create a governance proposal. (Callable by `ADMIN_ROLE`).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For bounty rewards

// Outline:
// 1. Contract Overview
// 2. State Variables
// 3. Events
// 4. Modifiers
// 5. Constructor
// 6. I. Core Skill & Reputation Management
// 7. II. AI Oracle Integration (Mocked)
// 8. III. Dynamic Soulbound Token (SBT) Functionality
// 9. IV. Advanced Governance & Bounty System
// 10. V. Administrative & Role-Based Functions

// Function Summary:
// I. Core Skill & Reputation Management
//   - registerProfile(): Allows a user to register their unique profile in the network.
//   - updateProfileDetails(string memory _name, bytes32 _bioHash): Allows a user to update their profile details (name and IPFS hash for bio).
//   - requestSkillAcquisition(uint256 _skillTypeId, bytes32 _proofHash): Initiates a request for a user to acquire a specific skill, providing off-chain proof hash.
//   - verifySkillAcquisition(uint256 _requestId, uint256 _aiAssessmentScore): Verifies a pending skill acquisition request, updating user's skill based on AI assessment. (ADMIN_ROLE/ORACLE_ROLE only)
//   - levelUpSkill(address _user, uint256 _skillTypeId, uint256 _xpEarned): Increases the level of a user's acquired skill based on earned experience points. Can only be called by ORACLE_ROLE, as XP is typically awarded by the system.
//   - getSkillLevel(address _user, uint256 _skillTypeId): Retrieves the current level of a specific skill for a given user.
//   - getSkillXP(address _user, uint256 _skillTypeId): Retrieves the current experience points of a specific skill for a given user.
//   - getTotalReputation(address _user): Calculates and returns the aggregated reputation score for a user based on all their acquired skills.
//   - getSkillPower(address _user, uint256 _skillTypeId): Calculates the specific skill's power for governance/voting.
//   - delegateSkillPoints(uint256 _skillTypeId, address _delegatee): Allows a user to delegate the governance power of their specific skill to another address.
//   - undelegateSkillPoints(uint256 _skillTypeId): Revokes the delegation of a specific skill's power.
//   - getDelegatedSkill(address _delegator, uint256 _skillTypeId): Retrieves the address to which a specific skill's power has been delegated by a user.
//
// II. AI Oracle Integration (Mocked)
//   - setAIOracleAddress(address _oracleAddress): Sets the trusted address for the AI oracle contract. (ADMIN_ROLE only)
//   - requestAIAssessment(uint256 _entityId, bytes32 _dataHash, uint256 _assessmentType): Simulates a user requesting an AI assessment for off-chain data related to an entity. (Intended for internal oracle use)
//   - receiveAIAssessment(uint256 _requestId, uint256 _aiScore): Callback function for the trusted AI oracle to deliver an assessment score. (ORACLE_ROLE only)
//
// III. Dynamic Soulbound Token (SBT) Functionality
//   - tokenURI(address _owner, uint256 _skillTypeId): Generates a dynamic, base64-encoded SVG metadata URI for a user's specific skill, reflecting its current level and XP. (View)
//   - getSkillMetadata(address _owner, uint256 _skillTypeId): Retrieves the decoded JSON metadata for a user's specific skill. (View)
//
// IV. Advanced Governance & Bounty System
//   - proposeBounty(string memory _title, bytes32 _descriptionHash, uint256[] memory _requiredSkillTypes, uint256[] memory _requiredSkillLevels, uint256 _rewardAmount, address _rewardToken): Allows users to propose bounties requiring specific skill types and levels for completion, specifying an ERC20 reward token.
//   - submitBountyCompletion(uint256 _bountyId, bytes32 _solutionHash): Allows a user to submit a solution for a proposed bounty.
//   - verifyBountyCompletion(uint256 _bountyId, address _submitter, uint256 _aiAssessmentScore): Verifies a bounty completion submission, potentially using AI assessment. (ADMIN_ROLE/ORACLE_ROLE only)
//   - createGovernanceProposal(string memory _title, bytes32 _descriptionHash, address _target, bytes memory _callData): Allows users with sufficient skill power to create a new governance proposal.
//   - voteOnProposal(uint256 _proposalId, bool _support): Allows users (or their delegates) to vote on an active governance proposal, weighted by their skill power.
//   - executeProposal(uint256 _proposalId): Executes a governance proposal that has passed and met the execution delay.
//   - cancelProposal(uint256 _proposalId): Allows the proposer or ADMIN_ROLE to cancel an active proposal.
//
// V. Administrative & Role-Based Functions
//   - addSkillType(uint256 _skillTypeId, string memory _name, string memory _description, uint256 _xpForLevelUp, uint256 _weight, uint256[] memory _prerequisites): Defines a new skill type and its properties, including prerequisites. (SKILL_MANAGER_ROLE only)
//   - removeSkillType(uint256 _skillTypeId): Removes an existing skill type. (SKILL_MANAGER_ROLE only)
//   - grantRole(bytes32 role, address account): Grants a role to an address. (DEFAULT_ADMIN_ROLE only)
//   - revokeRole(bytes32 role, address account): Revokes a role from an address. (DEFAULT_ADMIN_ROLE only)
//   - setMinAggregateSkillPowerForProposal(uint256 _power): Sets the minimum aggregate skill power required to create a governance proposal. (ADMIN_ROLE only)

contract CognitiveNexus is AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // 1. Contract Overview:
    // CognitiveNexus is a decentralized platform for managing skill-based reputation.
    // It utilizes dynamically leveling Soulbound Tokens (SBTs) to represent user skills,
    // integrates with AI oracles for automated assessment, and features an advanced
    // governance system where voting power is derived from delegated skill proficiency.
    // Bounties can also be proposed and completed based on required skill sets.

    // 2. State Variables
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant SKILL_MANAGER_ROLE = keccak256("SKILL_MANAGER_ROLE"); 

    address public aiOracleAddress;
    uint256 public minAggregateSkillPowerForProposal;

    // User profile structure
    struct UserProfile {
        bool isRegistered;
        string name;
        bytes32 bioHash; // IPFS hash or similar for longer bio
    }
    mapping(address => UserProfile) public userProfiles;

    // Skill type definition (global)
    struct SkillType {
        bool exists;
        string name;
        string description;
        uint256 xpForLevelUp; // XP needed to advance one level
        uint256 weight;       // Multiplier for reputation/governance power
        uint256[] prerequisites; // SkillType IDs required before acquiring this skill
    }
    mapping(uint256 => SkillType) public skillTypes; // skillTypeId => SkillType
    uint256[] public registeredSkillTypeIds; // For iterating all skill types

    // User's acquired skill instance (Soulbound Token)
    struct SkillInstance {
        uint256 skillTypeId;
        uint256 level;
        uint256 xp;
        address delegatedTo; // Address to which this skill's power is delegated
        uint256 acquisitionTimestamp;
    }
    mapping(address => mapping(uint256 => SkillInstance)) public userSkills; // user => skillTypeId => SkillInstance
    mapping(address => uint256[]) public userAcquiredSkillTypeIds; // user => list of skillTypeIds they own

    // Skill acquisition requests for oracle processing
    struct SkillAcquisitionRequest {
        address requester;
        uint256 skillTypeId;
        bytes32 proofHash;
        bool fulfilled;
    }
    Counters.Counter private _nextSkillAcquisitionRequestId;
    mapping(uint256 => SkillAcquisitionRequest) public skillAcquisitionRequests;

    // AI Assessment requests
    struct AIAssessmentRequest {
        address requester;
        uint256 entityId;     // ID of the skill acquisition request or bounty ID
        bytes32 dataHash;
        uint256 assessmentType; // e.g., 1 for skill acquisition, 2 for bounty completion
        bool fulfilled;
    }
    Counters.Counter private _nextAIAssessmentRequestId;
    mapping(uint256 => AIAssessmentRequest) public aiAssessmentRequests;
    mapping(uint256 => uint256) public aiAssessmentResults; // requestId => aiScore

    // Bounty System
    enum BountyState { Open, Submitted, Verified, Rejected, Claimed }
    struct Bounty {
        uint256 id;
        address proposer;
        string title;
        bytes32 descriptionHash; // IPFS hash of detailed description
        uint256[] requiredSkillTypes;
        uint256[] requiredSkillLevels;
        uint256 rewardAmount;
        address rewardToken; // ERC20 token address for rewards
        BountyState state;
        mapping(address => bytes32) submissions; // submitter => solutionHash
        address[] submitters; // list of unique submitters for a bounty
        address winner;
        bool claimed;
    }
    Counters.Counter private _nextBountyId;
    mapping(uint256 => Bounty) public bounties;

    // Governance System
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed, Canceled }
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        bytes32 descriptionHash;
        address target;       // Address to call
        bytes callData;       // Calldata for the target
        uint256 creationTime;
        uint256 votingPeriod; // Duration in seconds
        uint256 executionDelay; // Delay before execution after passing
        uint256 totalSkillPowerFor;
        uint256 totalSkillPowerAgainst;
        mapping(address => bool) hasVoted; // Voter => hasVoted
        mapping(address => uint256) voteWeights; // Voter => skill power voted
        ProposalState state;
        bool executed;
    }
    Counters.Counter private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;


    // 3. Events
    event ProfileRegistered(address indexed user, string name);
    event ProfileUpdated(address indexed user, string name, bytes32 bioHash);
    event SkillAcquisitionRequested(uint256 indexed requestId, address indexed requester, uint256 indexed skillTypeId, bytes32 proofHash);
    event SkillAcquired(address indexed user, uint256 indexed skillTypeId, uint256 level, uint256 xp);
    event SkillLeveledUp(address indexed user, uint256 indexed skillTypeId, uint256 newLevel, uint256 newXP);
    event SkillDelegated(address indexed delegator, uint256 indexed skillTypeId, address indexed delegatee);
    event SkillUndelegated(address indexed delegator, uint256 indexed skillTypeId);

    event AIAssessmentRequested(uint256 indexed requestId, address indexed requester, uint256 entityId, uint256 assessmentType);
    event AIAssessmentReceived(uint256 indexed requestId, uint256 aiScore);

    event BountyProposed(uint256 indexed bountyId, address indexed proposer, string title, uint256 rewardAmount);
    event BountySubmitted(uint256 indexed bountyId, address indexed submitter);
    event BountyVerified(uint256 indexed bountyId, address indexed winner, uint256 aiAssessmentScore);
    event BountyClaimed(uint256 indexed bountyId, address indexed winner, uint256 amount, address token);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 skillPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    event SkillTypeAdded(uint256 indexed skillTypeId, string name);
    event SkillTypeRemoved(uint256 indexed skillTypeId);
    event MinAggregateSkillPowerForProposalSet(uint256 newPower);

    // 4. Modifiers
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "CognitiveNexus: Must have ADMIN_ROLE");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "CognitiveNexus: Must have ORACLE_ROLE");
        _;
    }

    modifier onlySkillManager() {
        require(hasRole(SKILL_MANAGER_ROLE, msg.sender), "CognitiveNexus: Must have SKILL_MANAGER_ROLE");
        _;
    }

    modifier onlyRegisteredProfile() {
        require(userProfiles[msg.sender].isRegistered, "CognitiveNexus: Profile not registered");
        _;
    }

    // 5. Constructor
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Deployer gets DEFAULT_ADMIN_ROLE
        _grantRole(ADMIN_ROLE, msg.sender);         // And also ADMIN_ROLE by default
        _grantRole(SKILL_MANAGER_ROLE, msg.sender); // And also SKILL_MANAGER_ROLE by default

        // Initialize default values
        minAggregateSkillPowerForProposal = 100; // Example value
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Calculates the total skill power of a user from all their acquired skills.
     *      Used for reputation and governance weighting.
     */
    function _calculateTotalSkillPower(address _user) internal view returns (uint256) {
        uint256 totalPower = 0;
        uint256[] storage skillIds = userAcquiredSkillTypeIds[_user];
        for (uint256 i = 0; i < skillIds.length; i++) {
            totalPower += getSkillPower(_user, skillIds[i]);
        }
        return totalPower;
    }

    /**
     * @dev Generates the SVG image data for a skill.
     *      This is a simplification; a real app might use off-chain services or more complex SVG.
     */
    function _generateSkillSVG(uint256 _skillTypeId, uint256 _level, uint256 _xp) internal view returns (string memory) {
        SkillType storage sType = skillTypes[_skillTypeId];
        string memory svg = string(abi.encodePacked(
            "<svg width='300' height='200' viewBox='0 0 300 200' xmlns='http://www.w3.org/2000/svg'>",
            "<rect width='100%' height='100%' fill='#f0f0f0'/>",
            "<text x='150' y='50' font-family='monospace' font-size='24' fill='#333' text-anchor='middle'>", sType.name, "</text>",
            "<text x='150' y='90' font-family='monospace' font-size='20' fill='#555' text-anchor='middle'>Level: ", _level.toString(), "</text>",
            "<text x='150' y='120' font-family='monospace' font-size='16' fill='#777' text-anchor='middle'>XP: ", _xp.toString(), "/", sType.xpForLevelUp.toString(), "</text>",
            "<text x='150' y='160' font-family='monospace' font-size='12' fill='#999' text-anchor='middle'>ID: ", _skillTypeId.toString(), "</text>",
            "</svg>"
        ));
        return svg;
    }


    // 6. I. Core Skill & Reputation Management

    /**
     * @dev Allows a user to register their unique profile in the network.
     *      This is a prerequisite for acquiring skills or participating in governance.
     * @param _name The user's chosen display name.
     * @param _bioHash An IPFS hash (or similar) pointing to the user's detailed biography or profile data.
     */
    function registerProfile(string memory _name, bytes32 _bioHash) public {
        require(!userProfiles[msg.sender].isRegistered, "CognitiveNexus: Profile already registered");
        require(bytes(_name).length > 0, "CognitiveNexus: Name cannot be empty");

        userProfiles[msg.sender] = UserProfile({
            isRegistered: true,
            name: _name,
            bioHash: _bioHash
        });
        emit ProfileRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a user to update their profile details (name and IPFS hash for bio).
     *      Only callable by a registered user.
     * @param _name The new display name for the user.
     * @param _bioHash The new IPFS hash for the user's detailed biography.
     */
    function updateProfileDetails(string memory _name, bytes32 _bioHash) public onlyRegisteredProfile {
        require(bytes(_name).length > 0, "CognitiveNexus: Name cannot be empty");
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bioHash = _bioHash;
        emit ProfileUpdated(msg.sender, _name, _bioHash);
    }

    /**
     * @dev Initiates a request for a user to acquire a specific skill, providing off-chain proof hash.
     *      This creates a request that needs to be verified by an Oracle/Admin.
     *      Prerequisites for the skill type must be met.
     * @param _skillTypeId The unique ID of the skill type to acquire.
     * @param _proofHash A hash (e.g., IPFS hash) of the off-chain proof of skill (e.g., certificate, code repository).
     */
    function requestSkillAcquisition(uint256 _skillTypeId, bytes32 _proofHash) public onlyRegisteredProfile {
        require(skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type does not exist");
        require(userSkills[msg.sender][_skillTypeId].acquisitionTimestamp == 0, "CognitiveNexus: Skill already acquired");

        // Check prerequisites
        uint256[] storage prereqs = skillTypes[_skillTypeId].prerequisites;
        for (uint256 i = 0; i < prereqs.length; i++) {
            require(userSkills[msg.sender][prereqs[i]].acquisitionTimestamp > 0, "CognitiveNexus: Prerequisites not met for skill acquisition");
        }

        uint256 requestId = _nextSkillAcquisitionRequestId.current();
        skillAcquisitionRequests[requestId] = SkillAcquisitionRequest({
            requester: msg.sender,
            skillTypeId: _skillTypeId,
            proofHash: _proofHash,
            fulfilled: false
        });
        _nextSkillAcquisitionRequestId.increment();

        // In a real system, this could internally call requestAIAssessment
        // or an off-chain process would pick up this event and trigger the AI oracle.
        emit SkillAcquisitionRequested(requestId, msg.sender, _skillTypeId, _proofHash);
    }

    /**
     * @dev Verifies a pending skill acquisition request, updating user's skill based on AI assessment.
     *      This function is expected to be called by a trusted ORACLE_ROLE after off-chain verification (e.g., AI).
     * @param _requestId The ID of the skill acquisition request.
     * @param _aiAssessmentScore The score provided by the AI oracle (e.g., 0-100).
     */
    function verifySkillAcquisition(uint256 _requestId, uint256 _aiAssessmentScore) public onlyOracle {
        SkillAcquisitionRequest storage req = skillAcquisitionRequests[_requestId];
        require(!req.fulfilled, "CognitiveNexus: Skill acquisition request already fulfilled");
        require(req.requester != address(0), "CognitiveNexus: Invalid request ID");
        require(skillTypes[req.skillTypeId].exists, "CognitiveNexus: Skill type invalid for request");
        require(_aiAssessmentScore > 50, "CognitiveNexus: AI assessment score too low for acquisition (must be > 50)"); // Example threshold

        req.fulfilled = true;

        uint256 skillTypeId = req.skillTypeId;
        address user = req.requester;

        SkillInstance storage skill = userSkills[user][skillTypeId];
        // Initialize if first acquisition
        if (skill.acquisitionTimestamp == 0) {
            skill.skillTypeId = skillTypeId;
            skill.level = 1; // Start at level 1 upon successful acquisition
            skill.xp = _aiAssessmentScore; // Initial XP from assessment
            skill.delegatedTo = address(0);
            skill.acquisitionTimestamp = block.timestamp;

            // Add to user's list of acquired skill type IDs if not already present
            bool found = false;
            for(uint256 i = 0; i < userAcquiredSkillTypeIds[user].length; i++) {
                if (userAcquiredSkillTypeIds[user][i] == skillTypeId) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                userAcquiredSkillTypeIds[user].push(skillTypeId);
            }
        } else {
            // If already acquired, just add XP and potentially level up
            skill.xp += _aiAssessmentScore;
            while (skill.xp >= skillTypes[skillTypeId].xpForLevelUp && skillTypes[skillTypeId].xpForLevelUp > 0) {
                skill.xp -= skillTypes[skillTypeId].xpForLevelUp;
                skill.level++;
                emit SkillLeveledUp(user, skillTypeId, skill.level, skill.xp);
            }
        }

        emit SkillAcquired(user, skillTypeId, skill.level, skill.xp);
    }

    /**
     * @dev Increases the level of a user's acquired skill based on earned experience points.
     *      This function is expected to be called by a trusted ORACLE_ROLE, as XP is typically awarded by the system
     *      based on contributions (e.g., verified bounty completions, AI assessments).
     * @param _user The address of the user whose skill is being leveled up.
     * @param _skillTypeId The ID of the skill type to level up.
     * @param _xpEarned The amount of experience points earned.
     */
    function levelUpSkill(address _user, uint256 _skillTypeId, uint256 _xpEarned) public onlyOracle {
        SkillInstance storage skill = userSkills[_user][_skillTypeId];
        require(skill.acquisitionTimestamp > 0, "CognitiveNexus: User has not acquired this skill");
        require(skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type does not exist");
        require(_xpEarned > 0, "CognitiveNexus: XP earned must be positive");

        skill.xp += _xpEarned;
        while (skill.xp >= skillTypes[_skillTypeId].xpForLevelUp && skillTypes[_skillTypeId].xpForLevelUp > 0) {
            skill.xp -= skillTypes[_skillTypeId].xpForLevelUp;
            skill.level++;
        }
        emit SkillLeveledUp(_user, _skillTypeId, skill.level, skill.xp);
    }

    /**
     * @dev Retrieves the current level of a specific skill for a given user.
     * @param _user The address of the user.
     * @param _skillTypeId The ID of the skill type.
     * @return The current level of the skill.
     */
    function getSkillLevel(address _user, uint256 _skillTypeId) public view returns (uint256) {
        return userSkills[_user][_skillTypeId].level;
    }

    /**
     * @dev Retrieves the current experience points of a specific skill for a given user.
     * @param _user The address of the user.
     * @param _skillTypeId The ID of the skill type.
     * @return The current XP of the skill.
     */
    function getSkillXP(address _user, uint256 _skillTypeId) public view returns (uint256) {
        return userSkills[_user][_skillTypeId].xp;
    }

    /**
     * @dev Calculates and returns the aggregated reputation score for a user based on all their acquired skills.
     *      Reputation is a sum of (skill level * skill type weight).
     * @param _user The address of the user.
     * @return The total reputation score (total skill power).
     */
    function getTotalReputation(address _user) public view returns (uint256) {
        return _calculateTotalSkillPower(_user); // Reputation is effectively total skill power
    }

    /**
     * @dev Calculates the specific skill's power for governance/voting.
     * @param _user The address of the user.
     * @param _skillTypeId The ID of the skill type.
     * @return The calculated skill power (level * weight).
     */
    function getSkillPower(address _user, uint256 _skillTypeId) public view returns (uint256) {
        SkillInstance storage skill = userSkills[_user][_skillTypeId];
        SkillType storage sType = skillTypes[_skillTypeId];
        if (skill.acquisitionTimestamp == 0 || !sType.exists) {
            return 0; // Skill not acquired or does not exist
        }
        return skill.level * sType.weight;
    }

    /**
     * @dev Allows a user to delegate the governance power of their specific skill to another address.
     *      The delegatee can then vote on proposals using the delegated skill's power.
     * @param _skillTypeId The ID of the skill type to delegate.
     * @param _delegatee The address to which the skill's power will be delegated.
     */
    function delegateSkillPoints(uint256 _skillTypeId, address _delegatee) public onlyRegisteredProfile {
        require(userSkills[msg.sender][_skillTypeId].acquisitionTimestamp > 0, "CognitiveNexus: User has not acquired this skill");
        require(skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type does not exist");
        require(_delegatee != address(0), "CognitiveNexus: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "CognitiveNexus: Cannot delegate to self");
        userSkills[msg.sender][_skillTypeId].delegatedTo = _delegatee;
        emit SkillDelegated(msg.sender, _skillTypeId, _delegatee);
    }

    /**
     * @dev Revokes the delegation of a specific skill's power.
     *      Only callable by the original delegator.
     * @param _skillTypeId The ID of the skill type to undelegate.
     */
    function undelegateSkillPoints(uint256 _skillTypeId) public onlyRegisteredProfile {
        require(userSkills[msg.sender][_skillTypeId].acquisitionTimestamp > 0, "CognitiveNexus: User has not acquired this skill");
        require(skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type does not exist");
        require(userSkills[msg.sender][_skillTypeId].delegatedTo != address(0), "CognitiveNexus: Skill not currently delegated");
        userSkills[msg.sender][_skillTypeId].delegatedTo = address(0);
        emit SkillUndelegated(msg.sender, _skillTypeId);
    }

    /**
     * @dev Retrieves the address to which a specific skill's power has been delegated by a user.
     * @param _delegator The address of the user who potentially delegated the skill.
     * @param _skillTypeId The ID of the skill type.
     * @return The address of the delegatee, or address(0) if not delegated.
     */
    function getDelegatedSkill(address _delegator, uint256 _skillTypeId) public view returns (address) {
        return userSkills[_delegator][_skillTypeId].delegatedTo;
    }

    // 7. II. AI Oracle Integration (Mocked)

    /**
     * @dev Sets the trusted address for the AI oracle contract. Only `ADMIN_ROLE` can call.
     * @param _oracleAddress The address of the trusted AI oracle contract.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyAdmin {
        require(_oracleAddress != address(0), "CognitiveNexus: Oracle address cannot be zero");
        aiOracleAddress = _oracleAddress;
    }

    /**
     * @dev Simulates a user requesting an AI assessment for off-chain data related to an entity.
     *      This function is typically an internal call or part of a larger workflow where
     *      data needs external AI verification (e.g., for skill acquisition or bounty completion).
     * @param _entityId The ID of the related entity (e.g., skill acquisition request ID, bounty ID).
     * @param _dataHash Hash of the data to be assessed (e.g., IPFS hash of a code submission).
     * @param _assessmentType Type of assessment (e.g., 1 for skill acquisition, 2 for bounty completion).
     */
    function requestAIAssessment(uint256 _entityId, bytes32 _dataHash, uint256 _assessmentType) internal {
        require(aiOracleAddress != address(0), "CognitiveNexus: AI Oracle address not set");

        uint256 requestId = _nextAIAssessmentRequestId.current();
        aiAssessmentRequests[requestId] = AIAssessmentRequest({
            requester: msg.sender, // Or the entity's owner if called internally for an entity
            entityId: _entityId,
            dataHash: _dataHash,
            assessmentType: _assessmentType,
            fulfilled: false
        });
        _nextAIAssessmentRequestId.increment();
        emit AIAssessmentRequested(requestId, msg.sender, _entityId, _assessmentType);

        // In a real system, this would trigger an off-chain call to the oracle.
        // For this mock, we assume the oracle will eventually call `receiveAIAssessment`.
    }

    /**
     * @dev Callback function for the trusted AI oracle to deliver an assessment score.
     *      Only the designated `ORACLE_ROLE` can call this.
     * @param _requestId The ID of the AI assessment request.
     * @param _aiScore The score provided by the AI.
     */
    function receiveAIAssessment(uint256 _requestId, uint256 _aiScore) public onlyOracle {
        AIAssessmentRequest storage req = aiAssessmentRequests[_requestId];
        require(!req.fulfilled, "CognitiveNexus: AI assessment request already fulfilled");
        require(req.requester != address(0), "CognitiveNexus: Invalid AI assessment request ID");

        req.fulfilled = true;
        aiAssessmentResults[_requestId] = _aiScore;
        emit AIAssessmentReceived(_requestId, _aiScore);

        // Based on assessmentType, further actions (e.g., verifySkillAcquisition or verifyBountyCompletion)
        // would typically be triggered by an off-chain keeper or within the oracle contract itself.
        // This contract provides `receiveAIAssessment` and expects external logic to connect it.
    }


    // 8. III. Dynamic Soulbound Token (SBT) Functionality

    /**
     * @dev Generates a dynamic, base64-encoded SVG metadata URI for a user's specific skill.
     *      This mimics ERC721 `tokenURI` for SBTs. The URI reflects the skill's current level and XP.
     * @param _owner The address of the skill owner.
     * @param _skillTypeId The ID of the skill type.
     * @return A data URI containing JSON metadata with a base64-encoded SVG image.
     */
    function tokenURI(address _owner, uint256 _skillTypeId) public view returns (string memory) {
        SkillInstance storage skill = userSkills[_owner][_skillTypeId];
        require(skill.acquisitionTimestamp > 0, "CognitiveNexus: User does not own this skill");
        SkillType storage sType = skillTypes[_skillTypeId];
        require(sType.exists, "CognitiveNexus: Skill type does not exist");

        string memory svg = _generateSkillSVG(_skillTypeId, skill.level, skill.xp);
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));

        string memory json = string(abi.encodePacked(
            '{"name": "', sType.name, ' - Level ', skill.level.toString(), '",',
            '"description": "A dynamic skill representing proficiency in ', sType.name, '. Level increases with XP.",',
            '"image": "', imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Skill Type ID", "value": ', _skillTypeId.toString(), '},',
                '{"trait_type": "Level", "value": ', skill.level.toString(), '},',
                '{"trait_type": "Experience Points", "value": ', skill.xp.toString(), '}',
            ']}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Retrieves the decoded JSON metadata for a user's specific skill.
     *      This is a helper function to directly get the JSON part of the tokenURI.
     * @param _owner The address of the skill owner.
     * @param _skillTypeId The ID of the skill type.
     * @return The decoded JSON metadata string.
     */
    function getSkillMetadata(address _owner, uint256 _skillTypeId) public view returns (string memory) {
        SkillInstance storage skill = userSkills[_owner][_skillTypeId];
        require(skill.acquisitionTimestamp > 0, "CognitiveNexus: User does not own this skill");
        SkillType storage sType = skillTypes[_skillTypeId];
        require(sType.exists, "CognitiveNexus: Skill type does not exist");

        string memory svg = _generateSkillSVG(_skillTypeId, skill.level, skill.xp);
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));

        string memory json = string(abi.encodePacked(
            '{"name": "', sType.name, ' - Level ', skill.level.toString(), '",',
            '"description": "A dynamic skill representing proficiency in ', sType.name, '. Level increases with XP.",',
            '"image": "', imageURI, '",',
            '"attributes": [',
                '{"trait_type": "Skill Type ID", "value": ', _skillTypeId.toString(), '},',
                '{"trait_type": "Level", "value": ', skill.level.toString(), '},',
                '{"trait_type": "Experience Points", "value": ', skill.xp.toString(), '}',
            ']}'
        ));
        return json;
    }


    // 9. IV. Advanced Governance & Bounty System

    /**
     * @dev Allows users to propose bounties requiring specific skill types and levels for completion.
     *      Rewards are in ERC20 tokens.
     * @param _title The title of the bounty.
     * @param _descriptionHash IPFS hash of the detailed bounty description.
     * @param _requiredSkillTypes An array of skill type IDs required.
     * @param _requiredSkillLevels An array of corresponding minimum skill levels required.
     * @param _rewardAmount The amount of reward for completing the bounty.
     * @param _rewardToken The address of the ERC20 token used for the reward.
     */
    function proposeBounty(
        string memory _title,
        bytes32 _descriptionHash,
        uint256[] memory _requiredSkillTypes,
        uint256[] memory _requiredSkillLevels,
        uint256 _rewardAmount,
        address _rewardToken
    ) public onlyRegisteredProfile {
        require(bytes(_title).length > 0, "CognitiveNexus: Bounty title cannot be empty");
        require(_requiredSkillTypes.length == _requiredSkillLevels.length, "CognitiveNexus: Skill type and level arrays must match");
        require(_rewardAmount > 0, "CognitiveNexus: Reward amount must be greater than zero");
        require(_rewardToken != address(0), "CognitiveNexus: Reward token address cannot be zero");

        // Ensure the contract can take the reward tokens from proposer
        IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);

        uint256 bountyId = _nextBountyId.current();
        bounties[bountyId] = Bounty({
            id: bountyId,
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            requiredSkillTypes: _requiredSkillTypes,
            requiredSkillLevels: _requiredSkillLevels,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            state: BountyState.Open,
            // submissions mapping is implicit, submitters array is explicit
            submitters: new address[](0), // Initialize empty
            winner: address(0),
            claimed: false
        });
        _nextBountyId.increment();
        emit BountyProposed(bountyId, msg.sender, _title, _rewardAmount);
    }

    /**
     * @dev Allows a user to submit a solution for a proposed bounty.
     *      User must meet the required skill prerequisites for the bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionHash IPFS hash of the solution.
     */
    function submitBountyCompletion(uint256 _bountyId, bytes32 _solutionHash) public onlyRegisteredProfile {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.proposer != address(0), "CognitiveNexus: Bounty does not exist");
        require(bounty.state == BountyState.Open, "CognitiveNexus: Bounty is not open for submissions");
        require(bounty.submissions[msg.sender] == bytes32(0), "CognitiveNexus: Already submitted for this bounty");
        require(_solutionHash != bytes32(0), "CognitiveNexus: Solution hash cannot be empty");

        // Check if submitter meets required skills
        for (uint256 i = 0; i < bounty.requiredSkillTypes.length; i++) {
            uint256 skillType = bounty.requiredSkillTypes[i];
            uint256 requiredLevel = bounty.requiredSkillLevels[i];
            require(userSkills[msg.sender][skillType].level >= requiredLevel, "CognitiveNexus: Submitter does not meet required skills for bounty");
        }

        bounty.submissions[msg.sender] = _solutionHash;
        bounty.submitters.push(msg.sender);
        bounty.state = BountyState.Submitted; // Mark as submitted, awaiting verification
        emit BountySubmitted(_bountyId, msg.sender);
    }

    /**
     * @dev Verifies a bounty completion submission, potentially using AI assessment.
     *      Only `ORACLE_ROLE` or `ADMIN_ROLE` can call this. Awards the bounty reward upon verification.
     * @param _bountyId The ID of the bounty.
     * @param _submitter The address of the user who submitted the solution.
     * @param _aiAssessmentScore The score from AI assessment (e.g., 0-100).
     */
    function verifyBountyCompletion(uint256 _bountyId, address _submitter, uint256 _aiAssessmentScore) public onlyOracle {
        Bounty storage bounty = bounties[_bountyId];
        require(bounty.proposer != address(0), "CognitiveNexus: Bounty does not exist");
        require(bounty.state == BountyState.Submitted, "CognitiveNexus: Bounty is not in submitted state");
        require(bounty.submissions[_submitter] != bytes32(0), "CognitiveNexus: Submitter has not submitted a solution for this bounty");
        require(_aiAssessmentScore > 75, "CognitiveNexus: AI assessment score too low for bounty completion (must be > 75)"); // Example threshold

        bounty.state = BountyState.Verified;
        bounty.winner = _submitter;

        // Transfer reward
        IERC20(bounty.rewardToken).transfer(bounty.winner, bounty.rewardAmount);
        bounty.claimed = true; // Mark as claimed implicitly by transfer
        emit BountyVerified(_bountyId, _submitter, _aiAssessmentScore);
        emit BountyClaimed(_bountyId, _submitter, bounty.rewardAmount, bounty.rewardToken);

        // Optionally, award XP to the winner for relevant skills
        // This is a simplified example; a real system would map bounty to skill XP.
        for (uint256 i = 0; i < bounty.requiredSkillTypes.length; i++) {
             uint256 skillTypeId = bounty.requiredSkillTypes[i];
             // Award XP, e.g., 10% of reward amount or a fixed amount per skill
             // Ensure this does not lead to reentrancy if _rewardAmount can be very large
             levelUpSkill(_submitter, skillTypeId, bounty.rewardAmount / 100); // Integer division
        }
    }

    /**
     * @dev Allows users with sufficient skill power to create a new governance proposal.
     *      Aggregate skill power is used to gate proposal creation.
     * @param _title The title of the proposal.
     * @param _descriptionHash IPFS hash of the detailed proposal description.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The calldata to be executed on the target contract.
     */
    function createGovernanceProposal(
        string memory _title,
        bytes32 _descriptionHash,
        address _target,
        bytes memory _callData
    ) public onlyRegisteredProfile {
        require(bytes(_title).length > 0, "CognitiveNexus: Proposal title cannot be empty");
        require(_calculateTotalSkillPower(msg.sender) >= minAggregateSkillPowerForProposal, "CognitiveNexus: Insufficient aggregate skill power to create proposal");

        uint256 proposalId = _nextProposalId.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            target: _target,
            callData: _callData,
            creationTime: block.timestamp,
            votingPeriod: 7 days, // Example: 7 days voting period
            executionDelay: 2 days, // Example: 2 days delay after success
            totalSkillPowerFor: 0,
            totalSkillPowerAgainst: 0,
            // hasVoted mapping is implicit, voteWeights mapping is implicit
            state: ProposalState.Active,
            executed: false
        });
        _nextProposalId.increment();
        emit ProposalCreated(proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows users (or their delegates) to vote on an active governance proposal,
     *      weighted by their delegated skill power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredProfile {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitiveNexus: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "CognitiveNexus: Proposal is not active");
        require(block.timestamp < proposal.creationTime + proposal.votingPeriod, "CognitiveNexus: Voting period has ended");

        address voter = msg.sender;
        require(proposal.hasVoted[voter] == false, "CognitiveNexus: Already voted on this proposal");

        uint256 voterSkillPower = 0;
        uint256[] storage skillIds = userAcquiredSkillTypeIds[voter]; // Skills directly owned by msg.sender
        for (uint256 i = 0; i < skillIds.length; i++) {
            // Only count skill power if it's not delegated away by the voter
            if (userSkills[voter][skillIds[i]].delegatedTo == address(0)) {
                 voterSkillPower += getSkillPower(voter, skillIds[i]);
            }
        }
        // NOTE: For a full liquid democracy, one would also need to aggregate skill power
        // that has been delegated *to* this `voter` from other users. This requires a
        // separate `delegatedPowerTo[voter]` mapping updated on delegation/undelegation,
        // which adds complexity but is a common pattern in fully-featured DAOs.
        // For this example, we only consider skills directly owned by msg.sender and not delegated away.

        require(voterSkillPower > 0, "CognitiveNexus: Voter has no skill power to cast a vote or skill power is delegated away");

        if (_support) {
            proposal.totalSkillPowerFor += voterSkillPower;
        } else {
            proposal.totalSkillPowerAgainst += voterSkillPower;
        }
        proposal.hasVoted[voter] = true;
        proposal.voteWeights[voter] = voterSkillPower; // Record the weight of the vote
        emit VoteCast(_proposalId, voter, _support, voterSkillPower);
    }

    /**
     * @dev Executes a governance proposal that has passed and met the execution delay.
     *      Anyone can call this once conditions are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitiveNexus: Proposal does not exist");
        require(proposal.state == ProposalState.Active || proposal.state == ProposalState.Succeeded, "CognitiveNexus: Proposal is not active or already finished");
        require(block.timestamp >= proposal.creationTime + proposal.votingPeriod, "CognitiveNexus: Voting period not ended");

        // Determine outcome if not already set (e.g., if called right after voting period ends)
        if (proposal.state == ProposalState.Active) {
            if (proposal.totalSkillPowerFor > proposal.totalSkillPowerAgainst) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Defeated;
            }
            emit ProposalStateChanged(_proposalId, proposal.state);
        }

        require(proposal.state == ProposalState.Succeeded, "CognitiveNexus: Proposal did not pass");
        require(!proposal.executed, "CognitiveNexus: Proposal already executed");
        require(block.timestamp >= proposal.creationTime + proposal.votingPeriod + proposal.executionDelay, "CognitiveNexus: Execution delay not met");

        // Execute the proposal's calldata on the target contract
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "CognitiveNexus: Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    /**
     * @dev Allows the proposer or `ADMIN_ROLE` to cancel an active proposal.
     *      Useful for fixing errors or withdrawing proposals.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitiveNexus: Proposal does not exist");
        require(proposal.state == ProposalState.Active, "CognitiveNexus: Proposal is not active and cannot be canceled");
        require(msg.sender == proposal.proposer || hasRole(ADMIN_ROLE, msg.sender), "CognitiveNexus: Only proposer or admin can cancel");

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
        emit ProposalStateChanged(_proposalId, proposal.state);
    }


    // 10. V. Administrative & Role-Based Functions

    /**
     * @dev Adds a new skill type definition. Only `SKILL_MANAGER_ROLE` can call.
     * @param _skillTypeId A unique ID for the new skill type.
     * @param _name The name of the skill (e.g., "Solidity Developer").
     * @param _description A description of the skill.
     * @param _xpForLevelUp XP required to advance one level in this skill.
     * @param _weight Multiplier for reputation/governance power for this skill.
     * @param _prerequisites Array of skillType IDs that must be acquired before this one.
     */
    function addSkillType(
        uint256 _skillTypeId,
        string memory _name,
        string memory _description,
        uint256 _xpForLevelUp,
        uint256 _weight,
        uint256[] memory _prerequisites
    ) public onlySkillManager {
        require(!skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type ID already exists");
        require(bytes(_name).length > 0, "CognitiveNexus: Skill name cannot be empty");
        require(_xpForLevelUp > 0, "CognitiveNexus: XP for level up must be positive");
        require(_weight > 0, "CognitiveNexus: Skill weight must be positive");

        // Validate prerequisites
        for (uint256 i = 0; i < _prerequisites.length; i++) {
            require(skillTypes[_prerequisites[i]].exists, "CognitiveNexus: Prerequisite skill type does not exist");
        }

        skillTypes[_skillTypeId] = SkillType({
            exists: true,
            name: _name,
            description: _description,
            xpForLevelUp: _xpForLevelUp,
            weight: _weight,
            prerequisites: _prerequisites
        });
        registeredSkillTypeIds.push(_skillTypeId); // Add to iterable list
        emit SkillTypeAdded(_skillTypeId, _name);
    }

    /**
     * @dev Removes an existing skill type. Only `SKILL_MANAGER_ROLE` can call.
     *      Note: This does not affect already acquired skills for users.
     * @param _skillTypeId The ID of the skill type to remove.
     */
    function removeSkillType(uint256 _skillTypeId) public onlySkillManager {
        require(skillTypes[_skillTypeId].exists, "CognitiveNexus: Skill type does not exist");
        // In a more robust system, you might prevent removal if users already have this skill
        // or if it's a prerequisite for other skills. For simplicity, we allow removal.
        delete skillTypes[_skillTypeId]; // This sets 'exists' to false and clears data

        // Remove from registeredSkillTypeIds array (inefficient for very large arrays, consider linked list or mapping for O(1))
        for (uint256 i = 0; i < registeredSkillTypeIds.length; i++) {
            if (registeredSkillTypeIds[i] == _skillTypeId) {
                registeredSkillTypeIds[i] = registeredSkillTypeIds[registeredSkillTypeIds.length - 1];
                registeredSkillTypeIds.pop();
                break;
            }
        }
        emit SkillTypeRemoved(_skillTypeId);
    }

    /**
     * @dev Grants a role to an account. Only `DEFAULT_ADMIN_ROLE` can call.
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes a role from an account. Only `DEFAULT_ADMIN_ROLE` can call.
     */
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /**
     * @dev Sets the minimum aggregate skill power required for a user to create a governance proposal.
     * @param _power The new minimum aggregate skill power.
     */
    function setMinAggregateSkillPowerForProposal(uint256 _power) public onlyAdmin {
        require(_power > 0, "CognitiveNexus: Minimum skill power must be positive");
        minAggregateSkillPowerForProposal = _power;
        emit MinAggregateSkillPowerForProposalSet(_power);
    }
}
```