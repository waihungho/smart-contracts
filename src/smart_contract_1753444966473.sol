Here's a Solidity smart contract named `DASCNet` (Decentralized Adaptive Skill & Collaboration Network). It incorporates advanced concepts like dynamic Soulbound Tokens (SBTs) for reputation and skills, on-chain mentorship, project collaboration with adaptive rewards, and oracle integration for verifiable off-chain achievements. It deliberately avoids duplicating existing popular open-source protocols by combining these elements in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; // ERC721Burnable is included for potential future protocol-level burns, though user-initiated burns are prevented for soulbound nature.
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces for potential oracles/external systems
interface IOracle {
    // A simplified oracle interface for skill verification and assessment.
    // In a real scenario, this would likely involve Chainlink VRF, keepers, or other off-chain data feeds.
    // For this contract, it assumes a pre-verified oracle that returns a boolean or a numeric assessment.
    function verifySkill(address _user, uint256 _skillId, string calldata _proofData) external view returns (bool);
    function getSkillAssessment(address _user, uint256 _skillId) external view returns (uint256);
}

// Outline and Function Summary
//
// Contract Name: DASCNet (Decentralized Adaptive Skill & Collaboration Network)
//
// Overview:
// DASCNet is an innovative Solidity smart contract designed to create a decentralized ecosystem for skill development, mentorship, and collaborative project execution. It leverages dynamic Soulbound Tokens (SBTs) to represent evolving user skills and reputation, integrates with external oracles for verifiable achievements, and implements adaptive reward mechanisms to incentivize positive contributions. The core idea is to build a "living credential" system that reflects a user's continuous learning and impact within the network.
//
// Key Concepts:
// 1.  Skill & Reputation Soulbound Tokens (SRS-SBTs): Non-transferable ERC721 tokens representing specific skills and an associated dynamic reputation score. These SBTs evolve based on verified achievements, mentorship success, and project contributions.
// 2.  Adaptive Incentivization: Rewards (in the form of reputation boosts or native token distribution) are dynamically calculated based on various factors like skill demand, project complexity, and successful completion rates, allowing the protocol to respond to ecosystem needs.
// 3.  Decentralized Mentorship: Facilitates on-chain mentorship agreements with escrowed funds, milestone tracking, and dispute resolution mechanisms.
// 4.  Collaborative Projects: Enables the creation, management, and incentivization of collaborative projects, where team members earn reputation and rewards based on their verified contributions.
// 5.  Oracle Integration: Allows for external, verifiable proof of skill or achievement to update SBTs, bridging the gap between on-chain and off-chain impact.
//
// Functions Summary:
//
// I. Core Protocol Management (Ownable/Pausable):
// 1.  constructor(address _oracleAddress): Initializes the contract with an admin (owner) and the trusted oracle address.
// 2.  setOracleAddress(address _newOracleAddress): Updates the trusted oracle address (admin only).
// 3.  pauseContract(): Pauses the contract in case of emergencies (admin only).
// 4.  unpauseContract(): Unpauses the contract (admin only).
// 5.  withdrawProtocolFees(): Allows the admin to withdraw collected protocol fees not locked in escrow.
// 6.  setSkillMintFee(uint256 _newFee): Sets the fee required to mint a new Skill SBT.
// 7.  setProjectCreationFee(uint256 _newFee): Sets the fee required to create a new project.
// 8.  updateAdaptiveRewardConfig(uint256 _baseReputationGain, uint256 _mentorEffRate, uint256 _projectCompFactor): Adjusts parameters for the adaptive reward calculation (admin only).
//
// II. Skill & Reputation SBT Management (ERC721, Soulbound):
// 9.  registerSkillCategory(string calldata _categoryName, string calldata _description): Admin defines top-level skill categories.
// 10. proposeNewSkill(uint256 _categoryId, string calldata _skillName, string calldata _description): Users propose specific skills within categories for approval.
// 11. approveSkillProposal(uint256 _skillProposalId): Admin/DAO approves a skill proposal, making it mintable.
// 12. rejectSkillProposal(uint256 _skillProposalId): Admin/DAO rejects a skill proposal.
// 13. mintSkillSBT(uint256 _skillDefinitionId): Mints a new, unique Skill SBT for the caller, representing their mastery level in a skill.
// 14. updateSkillSBTLevel(uint256 _tokenId, uint256 _newLevel, string calldata _context): Updates the reputation/level of a specific Skill SBT. Callable by SBT owner, oracles, or implicitly by protocol actions (e.g., mentorship, projects).
// 15. attestSkillVerification(address _user, uint256 _skillDefinitionId, string calldata _proofData): Oracle or authorized entity attests to a user's skill, potentially triggering an SBT mint or level update.
// 16. getSkillSBTDetails(uint256 _tokenId): Retrieves details of a specific Skill SBT by its ID.
// 17. getUserSkillSBTs(address _user): Returns a list of all Skill SBT IDs owned by a user.
// 18. getSkillProposalDetails(uint256 _proposalId): Retrieves details of a skill proposal.
//
// III. Mentorship & Collaboration Features:
// 19. offerMentorship(uint256 _skillSBTId, uint256 _ratePerSession, uint256 _minSessions): A Skill SBT owner offers mentorship, specifying terms.
// 20. requestMentorship(address _mentor, uint256 _mentorSkillSBTId, uint256 _numSessions, uint256 _totalDeposit): A user requests mentorship from an offered mentor, providing deposit.
// 21. acceptMentorshipRequest(uint256 _mentorshipId): Mentor accepts a mentorship request, locking funds.
// 22. completeMentorshipMilestone(uint256 _mentorshipId, uint256 _sessionsCompleted, string calldata _proof): Mentor/mentee marks sessions complete, releasing funds/reputation incrementally.
// 23. resolveMentorshipDispute(uint256 _mentorshipId, address _winner, uint256 _amount): Admin/arbiter resolves a dispute, distributing funds and adjusting reputation.
// 24. leaveFeedbackOnMentorship(uint256 _mentorshipId, uint256 _rating, string calldata _comment): Both parties can leave feedback, impacting mentor/mentee reputation.
//
// IV. Project-Based Collaboration Features:
// 25. createProjectProposal(string calldata _projectName, string calldata _description, uint256[] calldata _requiredSkillIds, uint256 _duration, uint256 _rewardBudget): Proposes a new collaborative project, collecting fees and budget.
// 26. joinProjectTeam(uint256 _projectId, uint256 _userSkillSBTId): Users with relevant Skill SBTs can join a project team.
// 27. submitProjectMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofData): Project lead/team member submits proof for a milestone.
// 28. verifyProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, address _contributor, bool _isVerified): Team members or an oracle verify a specific contributor's work for a milestone.
// 29. distributeProjectRewards(uint256 _projectId, uint256 _milestoneIndex): Distributes rewards (reputation/tokens) upon verified milestone completion.
// 30. exitProjectEarly(uint256 _projectId): Allows a team member to leave a project early (with no direct reputation penalty implemented due to 'level-up only' update logic).

contract DASCNet is ERC721, ERC721Burnable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Global counters for unique IDs across different structs
    Counters.Counter private _skillCategoryIds;
    Counters.Counter private _skillProposalIds; // Used for actual skill definition IDs once approved
    Counters.Counter private _skillSBTTokenIds; // Used for unique ID of each SBT instance
    Counters.Counter private _mentorshipIds;
    Counters.Counter private _projectIds;

    // Fees & Protocol Settings
    uint256 public skillMintFee;
    uint256 public projectCreationFee;
    address public immutable protocolFeeRecipient; // Where fees go, initially owner, can be updated to a DAO treasury

    // Adaptive Reward Parameters (configurable by owner)
    // These are multipliers or base values for dynamic reputation/token rewards
    uint256 public baseReputationGain;      // Base reputation points for successful actions (e.g., 10 points)
    uint256 public mentorEfficiencyRate;    // Multiplier for mentor reputation based on mentee success (0-100, e.g., 50 means 50%)
    uint256 public projectComplexityFactor; // Multiplier for project rewards based on complexity/duration (0-100, e.g., 100 means 100%)

    // Oracle Address - trusted external verifier
    address public oracleAddress;

    // --- Structs ---

    // Skill Categories (e.g., "Programming", "Design")
    struct SkillCategory {
        string name;
        string description;
        bool exists; // To check if category ID is valid
    }
    mapping(uint256 => SkillCategory) public skillCategories;

    // Skill Proposals (for community/admin approval)
    enum SkillProposalStatus { Pending, Approved, Rejected }
    struct SkillProposal {
        uint256 categoryId;
        string name;
        string description;
        address proposer;
        SkillProposalStatus status;
        uint256 approvedSkillDefinitionId; // If approved, this proposal's ID itself serves as the skill definition ID
    }
    mapping(uint256 => SkillProposal) public skillProposals; // Maps proposal ID to its details

    // Skill & Reputation SBT (Soulbound Token)
    // Each minted ERC721 token represents an instance of a skill for a user.
    struct SkillSBT {
        uint256 skillDefinitionId; // Points to the approved skill definition (from `skillProposals` mapping)
        uint256 level;             // Current mastery/reputation level (e.g., 1-100). Only increases.
        uint256 lastUpdated;       // Timestamp of last level update
    }
    mapping(uint256 => SkillSBT) public skillSBTs; // tokenId => SkillSBT details
    mapping(address => uint256[]) private _userSkillSBTs; // userAddress => array of their SBT token IDs

    // Mentorship Offer (made by a mentor using one of their SkillSBTs)
    struct MentorshipOffer {
        uint256 skillSBTId;     // The mentor's SkillSBT ID for which they offer mentorship
        address mentorAddress;  // Address of the mentor
        uint256 ratePerSession; // Price per session in native currency (wei)
        uint256 minSessions;    // Minimum number of sessions required for a request
        bool isActive;
    }
    // Mapping from mentor's SkillSBT ID to their active offer. A mentor can offer mentorship for multiple SBTs.
    mapping(uint256 => MentorshipOffer) public mentorshipOffers;

    // Mentorship Request/Agreement
    enum MentorshipStatus { Requested, Accepted, InProgress, Completed, Disputed, Resolved, Cancelled }
    struct Mentorship {
        uint256 offerSkillSBTId; // ID of the mentor's SkillSBT that originated the offer
        address mentee;
        address mentor;
        uint256 numSessionsAgreed;
        uint256 sessionsCompleted;
        uint256 totalDeposit;   // Total deposit locked for the mentorship (native currency)
        MentorshipStatus status;
        uint256 lastUpdateTimestamp;
        // For disputes:
        address disputeWinner;
        uint256 disputeResolutionAmount;
    }
    mapping(uint256 => Mentorship) public mentorships; // Maps unique mentorship ID to its details

    // Project Collaboration
    enum ProjectStatus { Proposed, Active, Completed, Cancelled }
    struct Project {
        string name;
        string description;
        address creator;
        uint256[] requiredSkillDefinitionIds; // IDs of general skills (from `skillProposals`) needed
        mapping(address => uint256) teamMembers; // Member address => their SkillSBT ID used to join
        address[] teamMemberAddresses; // To easily iterate project team members
        uint256 durationDays; // Expected duration of the project in days
        uint256 rewardBudget; // Total reward budget for the project, in native currency (wei)
        uint256 collectedFunds; // Funds actually collected from rewardBudget + fee (for transparency)
        Counters.Counter milestoneCounter; // Counter for milestones within this project
        mapping(uint256 => ProjectMilestone) milestones; // Milestone index => ProjectMilestone details
        ProjectStatus status;
    }
    mapping(uint256 => Project) public projects; // Maps unique project ID to its details

    struct ProjectMilestone {
        string description;
        uint256 expectedCompletionTime; // Timestamp, for informational purposes
        bool isCompleted; // True if the entire milestone is verified as complete
        mapping(address => bool) contributorSubmittedProof; // contributor address => has submitted proof
        mapping(address => bool) contributorVerifiedByProtocol; // contributor address => has their part verified by protocol
        address[] verifiedContributorsList; // List of contributors whose work for this milestone has been verified
        uint256 milestoneRewardShare; // Share of total project reward for this specific milestone
    }


    // --- Events ---

    event OracleAddressUpdated(address indexed _oldAddress, address indexed _newAddress);
    event ProtocolFeesWithdrawn(address indexed _to, uint256 _amount);
    event SkillMintFeeUpdated(uint256 _oldFee, uint256 _newFee);
    event ProjectCreationFeeUpdated(uint256 _oldFee, uint256 _newFee);
    event AdaptiveRewardConfigUpdated(uint256 _baseReputationGain, uint256 _mentorEffRate, uint256 _projectCompFactor);

    event SkillCategoryRegistered(uint256 indexed _categoryId, string _name);
    event SkillProposed(uint256 indexed _proposalId, uint256 indexed _categoryId, string _name, address indexed _proposer);
    event SkillProposalApproved(uint256 indexed _proposalId, uint256 indexed _skillDefinitionId, string _name);
    event SkillProposalRejected(uint256 indexed _proposalId);
    event SkillSBTMinted(address indexed _owner, uint256 indexed _tokenId, uint256 _skillDefinitionId, uint256 _initialLevel);
    event SkillSBTLevelUpdated(uint256 indexed _tokenId, uint256 _oldLevel, uint256 _newLevel, string _context);
    event SkillAttested(address indexed _user, uint256 indexed _skillDefinitionId, uint256 _assessmentValue);

    event MentorshipOffered(uint256 indexed _skillSBTId, address indexed _mentor, uint256 _ratePerSession, uint256 _minSessions);
    event MentorshipRequested(uint256 indexed _mentorshipId, address indexed _mentee, address indexed _mentor, uint256 _numSessions, uint256 _totalDeposit);
    event MentorshipAccepted(uint256 indexed _mentorshipId);
    event MentorshipMilestoneCompleted(uint256 indexed _mentorshipId, uint256 _sessionsCompleted, uint256 _fundsReleased);
    event MentorshipDisputeResolved(uint256 indexed _mentorshipId, address indexed _winner, uint256 _amount);
    event MentorshipFeedbackLeft(uint256 indexed _mentorshipId, address indexed _by, uint256 _rating);

    event ProjectProposed(uint256 indexed _projectId, string _name, address indexed _creator, uint256 _rewardBudget);
    event ProjectJoined(uint256 indexed _projectId, address indexed _member, uint256 _skillSBTId);
    event ProjectMilestoneProofSubmitted(uint256 indexed _projectId, uint256 _milestoneIndex, address indexed _contributor);
    event ProjectMilestoneVerified(uint256 indexed _projectId, uint256 _milestoneIndex, address indexed _contributor);
    event ProjectRewardsDistributed(uint256 indexed _projectId, uint256 _milestoneIndex, uint256 _totalDistributed);
    event ProjectExited(uint256 indexed _projectId, address indexed _member);


    // --- Constructor ---

    /// @notice Initializes the DASCNet contract.
    /// @param _oracleAddress The address of the trusted oracle for skill verification.
    constructor(address _oracleAddress) ERC721("DASCNet Skill SBT", "SRS-SBT") Ownable(msg.sender) Pausable() {
        require(_oracleAddress != address(0), "DASCNet: Invalid oracle address");
        oracleAddress = _oracleAddress;
        protocolFeeRecipient = msg.sender; // Owner is initially the fee recipient; can be conceptually updated to a DAO.
        skillMintFee = 0.005 ether; // Example: 0.005 ETH (adjust as needed)
        projectCreationFee = 0.01 ether; // Example: 0.01 ETH (adjust as needed)

        // Initial adaptive reward parameters (values 0-100 for percentage factors)
        baseReputationGain = 10;     // Base points for a positive action
        mentorEfficiencyRate = 50;   // Mentor gets 0.5 * mentee's reputation gain
        projectComplexityFactor = 100; // Project rewards scaled by this factor (100 means full effect)
    }

    // --- Core Protocol Management ---

    /// @notice Updates the trusted oracle address. Only callable by the contract owner.
    /// @param _newOracleAddress The new address of the oracle.
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "DASCNet: Invalid new oracle address");
        emit OracleAddressUpdated(oracleAddress, _newOracleAddress);
        oracleAddress = _newOracleAddress;
    }

    /// @notice Pauses contract operations in case of an emergency. Only callable by the contract owner.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations. Only callable by the contract owner.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the protocol fee recipient to withdraw collected fees not currently locked in escrow.
    ///         Only callable by the contract owner.
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance - getLockedFunds(); // Only withdraw unlocked funds
        require(balance > 0, "DASCNet: No withdrawable fees available");
        (bool success, ) = payable(protocolFeeRecipient).call{value: balance}("");
        require(success, "DASCNet: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, balance);
    }

    /// @notice Internal helper to calculate total funds currently locked in mentorships and projects.
    /// @return The total amount of native currency locked in escrow.
    function getLockedFunds() internal view returns (uint256) {
        uint256 locked = 0;
        for (uint256 i = 1; i <= _mentorshipIds.current(); i++) {
            Mentorship storage m = mentorships[i];
            if (m.status == MentorshipStatus.Accepted || m.status == MentorshipStatus.InProgress || m.status == MentorshipStatus.Disputed) {
                locked += m.totalDeposit - (m.sessionsCompleted * (m.totalDeposit / m.numSessionsAgreed)); // Sum of remaining deposits
            }
        }
        for (uint256 i = 1; i <= _projectIds.current(); i++) {
            Project storage p = projects[i];
            if (p.status == ProjectStatus.Active || p.status == ProjectStatus.Proposed) {
                locked += p.collectedFunds;
            }
        }
        return locked;
    }

    /// @notice Sets the fee required to mint a new Skill SBT. Only callable by the contract owner.
    /// @param _newFee The new fee in wei.
    function setSkillMintFee(uint256 _newFee) external onlyOwner {
        emit SkillMintFeeUpdated(skillMintFee, _newFee);
        skillMintFee = _newFee;
    }

    /// @notice Sets the fee required to create a new project. Only callable by the contract owner.
    /// @param _newFee The new fee in wei.
    function setProjectCreationFee(uint256 _newFee) external onlyOwner {
        emit ProjectCreationFeeUpdated(projectCreationFee, _newFee);
        projectCreationFee = _newFee;
    }

    /// @notice Adjusts parameters for the adaptive reward calculation. Only callable by the contract owner.
    /// @param _baseReputationGain Base points for positive actions.
    /// @param _mentorEffRate Multiplier (0-100) for mentor reputation based on mentee success.
    /// @param _projectCompFactor Multiplier (0-100) for project rewards based on complexity.
    function updateAdaptiveRewardConfig(uint256 _baseReputationGain, uint256 _mentorEffRate, uint256 _projectCompFactor) external onlyOwner {
        require(_mentorEffRate <= 100 && _projectCompFactor <= 100, "DASCNet: Rates must be between 0 and 100");
        baseReputationGain = _baseReputationGain;
        mentorEfficiencyRate = _mentorEffRate;
        projectComplexityFactor = _projectCompFactor;
        emit AdaptiveRewardConfigUpdated(_baseReputationGain, _mentorEffRate, _projectCompFactor);
    }

    // --- Skill & Reputation SBT Management ---

    /// @notice Registers a new top-level skill category (e.g., "Programming", "Design"). Only callable by the contract owner.
    /// @param _categoryName The name of the new category.
    /// @param _description A description of the category.
    function registerSkillCategory(string calldata _categoryName, string calldata _description) external onlyOwner {
        _skillCategoryIds.increment();
        uint256 newId = _skillCategoryIds.current();
        skillCategories[newId] = SkillCategory({
            name: _categoryName,
            description: _description,
            exists: true
        });
        emit SkillCategoryRegistered(newId, _categoryName);
    }

    /// @notice Allows any user to propose a new specific skill within an existing category.
    /// @param _categoryId The ID of the parent skill category.
    /// @param _skillName The name of the proposed skill (e.g., "Solidity", "UX Research").
    /// @param _description A description of the proposed skill.
    function proposeNewSkill(uint256 _categoryId, string calldata _skillName, string calldata _description) external whenNotPaused {
        require(skillCategories[_categoryId].exists, "DASCNet: Category does not exist");
        _skillProposalIds.increment();
        uint256 proposalId = _skillProposalIds.current();
        skillProposals[proposalId] = SkillProposal({
            categoryId: _categoryId,
            name: _skillName,
            description: _description,
            proposer: msg.sender,
            status: SkillProposalStatus.Pending,
            approvedSkillDefinitionId: 0 // Will be set to proposalId upon approval
        });
        emit SkillProposed(proposalId, _categoryId, _skillName, msg.sender);
    }

    /// @notice Admin/DAO approves a pending skill proposal, making it a mintable skill. Only callable by the contract owner.
    /// @param _skillProposalId The ID of the skill proposal to approve.
    function approveSkillProposal(uint256 _skillProposalId) external onlyOwner { // In a full DAO, this would be a voting outcome.
        SkillProposal storage proposal = skillProposals[_skillProposalId];
        require(proposal.proposer != address(0), "DASCNet: Skill proposal does not exist");
        require(proposal.status == SkillProposalStatus.Pending, "DASCNet: Skill proposal not pending");

        proposal.status = SkillProposalStatus.Approved;
        proposal.approvedSkillDefinitionId = _skillProposalId; // The proposal ID itself becomes the "skill definition ID"
        emit SkillProposalApproved(_skillProposalId, _skillProposalId, proposal.name);
    }

    /// @notice Admin/DAO rejects a pending skill proposal. Only callable by the contract owner.
    /// @param _skillProposalId The ID of the skill proposal to reject.
    function rejectSkillProposal(uint256 _skillProposalId) external onlyOwner {
        SkillProposal storage proposal = skillProposals[_skillProposalId];
        require(proposal.proposer != address(0), "DASCNet: Skill proposal does not exist");
        require(proposal.status == SkillProposalStatus.Pending, "DASCNet: Skill proposal not pending");
        proposal.status = SkillProposalStatus.Rejected;
        emit SkillProposalRejected(_skillProposalId);
    }

    /// @notice Mints a new Skill SBT for the caller. Requires an approved skill definition and payment of fee.
    /// @param _skillDefinitionId The ID of the approved skill definition (i.e., the approved skill proposal ID).
    function mintSkillSBT(uint256 _skillDefinitionId) external payable whenNotPaused nonReentrant {
        SkillProposal storage skillDef = skillProposals[_skillDefinitionId];
        require(skillDef.status == SkillProposalStatus.Approved, "DASCNet: Skill not approved for minting");
        require(msg.value >= skillMintFee, "DASCNet: Insufficient fee");

        // Ensure user doesn't already own an SBT for this specific skill definition
        uint256[] memory userSBTs = _userSkillSBTs[msg.sender];
        for (uint256 i = 0; i < userSBTs.length; i++) {
            require(skillSBTs[userSBTs[i]].skillDefinitionId != _skillDefinitionId, "DASCNet: Already owns an SBT for this skill");
        }

        uint256 newTokenId = _skillSBTTokenIds.current();
        _skillSBTTokenIds.increment();

        _safeMint(msg.sender, newTokenId);
        skillSBTs[newTokenId] = SkillSBT({
            skillDefinitionId: _skillDefinitionId,
            level: 1, // Start at level 1
            lastUpdated: block.timestamp
        });

        _userSkillSBTs[msg.sender].push(newTokenId);

        emit SkillSBTMinted(msg.sender, newTokenId, _skillDefinitionId, 1);
    }

    /// @notice Updates the reputation/level of a specific Skill SBT. Only allows level ups.
    ///         Callable by the SBT owner (e.g., for self-improvement declaration), oracles, or implicitly by protocol actions (mentorship, project completion).
    /// @param _tokenId The ID of the Skill SBT to update.
    /// @param _newLevel The new level to set for the SBT.
    /// @param _context A string describing the reason/source of the update (e.g., "Mentorship Completion", "Oracle Attestation").
    function updateSkillSBTLevel(uint256 _tokenId, uint256 _newLevel, string calldata _context) public whenNotPaused {
        require(_exists(_tokenId), "DASCNet: SBT does not exist");
        require(_newLevel > 0, "DASCNet: Level must be positive");
        // Only owner of the SBT or the designated oracle can directly call this function.
        // Internal calls by protocol functions (e.g., mentorship, projects) are handled separately by their logic.
        require(ownerOf(_tokenId) == msg.sender || oracleAddress == msg.sender, "DASCNet: Not authorized to directly update this SBT level");

        SkillSBT storage sbt = skillSBTs[_tokenId];
        uint256 oldLevel = sbt.level;
        require(_newLevel > oldLevel, "DASCNet: New level must be strictly higher than current (only level ups are allowed)");

        sbt.level = _newLevel;
        sbt.lastUpdated = block.timestamp;
        emit SkillSBTLevelUpdated(_tokenId, oldLevel, _newLevel, _context);
    }

    /// @notice Oracle or authorized entity attests to a user's skill, potentially triggering an SBT mint or level update.
    ///         This function allows the designated oracle to directly influence a user's skill level and even grant SBTs.
    /// @param _user The address of the user whose skill is being attested.
    /// @param _skillDefinitionId The ID of the skill definition being attested.
    /// @param _proofData Off-chain proof data for oracle verification.
    function attestSkillVerification(address _user, uint256 _skillDefinitionId, string calldata _proofData) external whenNotPaused {
        require(msg.sender == oracleAddress, "DASCNet: Only the designated oracle can attest skills");
        SkillProposal storage skillDef = skillProposals[_skillDefinitionId];
        require(skillDef.status == SkillProposalStatus.Approved, "DASCNet: Skill definition is not approved.");

        // Oracle performs its internal check (e.g., calls external API based on _proofData)
        // For demonstration, we simulate oracle interaction using the IOracle interface.
        bool verified = IOracle(oracleAddress).verifySkill(_user, _skillDefinitionId, _proofData);
        require(verified, "DASCNet: Oracle could not verify skill based on provided proof");

        uint256 assessment = IOracle(oracleAddress).getSkillAssessment(_user, _skillDefinitionId); // Get a new level from oracle
        require(assessment > 0, "DASCNet: Oracle assessment resulted in an invalid level");

        uint256 targetSBTId = 0;
        uint256[] memory userSBTs = _userSkillSBTs[_user];
        for (uint256 i = 0; i < userSBTs.length; i++) {
            if (skillSBTs[userSBTs[i]].skillDefinitionId == _skillDefinitionId) {
                targetSBTId = userSBTs[i];
                break;
            }
        }

        if (targetSBTId == 0) {
            // If user doesn't have an SBT for this skill, mint one for them (as a certification/grant)
            uint256 newTokenId = _skillSBTTokenIds.current();
            _skillSBTTokenIds.increment();
            _safeMint(_user, newTokenId);
            skillSBTs[newTokenId] = SkillSBT({
                skillDefinitionId: _skillDefinitionId,
                level: assessment,
                lastUpdated: block.timestamp
            });
            _userSkillSBTs[_user].push(newTokenId);
            emit SkillSBTMinted(_user, newTokenId, _skillDefinitionId, assessment);
        } else {
            // Update existing SBT if new level from oracle is higher
            SkillSBT storage sbt = skillSBTs[targetSBTId];
            if (assessment > sbt.level) {
                uint256 oldLevel = sbt.level;
                sbt.level = assessment;
                sbt.lastUpdated = block.timestamp;
                emit SkillSBTLevelUpdated(targetSBTId, oldLevel, assessment, "Oracle Attestation");
            }
        }
        emit SkillAttested(_user, _skillDefinitionId, assessment);
    }

    /// @notice Retrieves details of a specific Skill SBT by its ID.
    /// @param _tokenId The ID of the Skill SBT.
    /// @return skillDefinitionId_ The ID of the skill definition.
    /// @return level_ The current mastery/reputation level.
    /// @return lastUpdated_ The timestamp of the last level update.
    /// @return owner_ The owner of the SBT.
    function getSkillSBTDetails(uint256 _tokenId) public view returns (uint256 skillDefinitionId_, uint256 level_, uint256 lastUpdated_, address owner_) {
        require(_exists(_tokenId), "DASCNet: SBT does not exist");
        SkillSBT storage sbt = skillSBTs[_tokenId];
        skillDefinitionId_ = sbt.skillDefinitionId;
        level_ = sbt.level;
        lastUpdated_ = sbt.lastUpdated;
        owner_ = ownerOf(_tokenId);
    }

    /// @notice Returns a list of all Skill SBT IDs owned by a user.
    /// @param _user The address of the user.
    /// @return A dynamic array of SBT token IDs.
    function getUserSkillSBTs(address _user) public view returns (uint256[] memory) {
        return _userSkillSBTs[_user];
    }

    /// @notice Retrieves details of a skill proposal.
    /// @param _proposalId The ID of the skill proposal.
    /// @return categoryId_ The category ID.
    /// @return name_ The skill name.
    /// @return description_ The skill description.
    /// @return proposer_ The proposer's address.
    /// @return status_ The status of the proposal.
    /// @return approvedSkillDefinitionId_ The ID if approved.
    function getSkillProposalDetails(uint256 _proposalId) public view returns (uint256 categoryId_, string memory name_, string memory description_, address proposer_, SkillProposalStatus status_, uint256 approvedSkillDefinitionId_) {
        SkillProposal storage proposal = skillProposals[_proposalId];
        require(proposal.proposer != address(0), "DASCNet: Skill proposal does not exist"); // Check if proposal ID is valid
        categoryId_ = proposal.categoryId;
        name_ = proposal.name;
        description_ = proposal.description;
        proposer_ = proposal.proposer;
        status_ = proposal.status;
        approvedSkillDefinitionId_ = proposal.approvedSkillDefinitionId;
    }

    // --- Mentorship & Collaboration Features ---

    /// @notice An owner of a Skill SBT offers to mentor others in that skill.
    /// @param _skillSBTId The ID of the mentor's Skill SBT (must be owned by msg.sender).
    /// @param _ratePerSession The price per session in native currency (wei).
    /// @param _minSessions The minimum number of sessions for this mentorship offer.
    function offerMentorship(uint256 _skillSBTId, uint256 _ratePerSession, uint256 _minSessions) external whenNotPaused {
        require(ownerOf(_skillSBTId) == msg.sender, "DASCNet: You must own this Skill SBT to offer mentorship");
        require(_ratePerSession > 0, "DASCNet: Rate per session must be positive");
        require(_minSessions > 0, "DASCNet: Minimum sessions must be positive");
        // Ensure no active offer with this specific SBT already exists
        require(mentorshipOffers[_skillSBTId].mentorAddress == address(0) || !mentorshipOffers[_skillSBTId].isActive, "DASCNet: Mentorship already offered with this SBT");

        mentorshipOffers[_skillSBTId] = MentorshipOffer({
            skillSBTId: _skillSBTId,
            mentorAddress: msg.sender,
            ratePerSession: _ratePerSession,
            minSessions: _minSessions,
            isActive: true
        });
        emit MentorshipOffered(_skillSBTId, msg.sender, _ratePerSession, _minSessions);
    }

    /// @notice A user requests mentorship from an offered mentor. Funds are deposited in escrow.
    /// @param _mentor The address of the mentor.
    /// @param _mentorSkillSBTId The ID of the mentor's Skill SBT that was offered.
    /// @param _numSessions The number of sessions requested by the mentee.
    function requestMentorship(address _mentor, uint256 _mentorSkillSBTId, uint256 _numSessions) external payable whenNotPaused nonReentrant {
        require(msg.sender != _mentor, "DASCNet: Cannot request mentorship from self");
        MentorshipOffer storage offer = mentorshipOffers[_mentorSkillSBTId];
        require(offer.isActive && offer.mentorAddress == _mentor, "DASCNet: Mentorship offer not active or invalid mentor");
        require(_numSessions >= offer.minSessions, "DASCNet: Not enough sessions requested");

        uint256 requiredDeposit = offer.ratePerSession * _numSessions;
        require(msg.value == requiredDeposit, "DASCNet: Deposit mismatch with required amount");

        _mentorshipIds.increment();
        uint256 newMentorshipId = _mentorshipIds.current();

        mentorships[newMentorshipId] = Mentorship({
            offerSkillSBTId: _mentorSkillSBTId,
            mentee: msg.sender,
            mentor: _mentor,
            numSessionsAgreed: _numSessions,
            sessionsCompleted: 0,
            totalDeposit: msg.value,
            status: MentorshipStatus.Requested,
            lastUpdateTimestamp: block.timestamp,
            disputeWinner: address(0),
            disputeResolutionAmount: 0
        });
        emit MentorshipRequested(newMentorshipId, msg.sender, _mentor, _numSessions, msg.value);
    }

    /// @notice The mentor accepts a mentorship request.
    /// @param _mentorshipId The ID of the mentorship request to accept.
    function acceptMentorshipRequest(uint256 _mentorshipId) external whenNotPaused {
        Mentorship storage m = mentorships[_mentorshipId];
        require(m.mentor == msg.sender, "DASCNet: Only the mentor can accept this request");
        require(m.status == MentorshipStatus.Requested, "DASCNet: Mentorship not in requested state");

        m.status = MentorshipStatus.Accepted;
        m.lastUpdateTimestamp = block.timestamp;
        emit MentorshipAccepted(_mentorshipId);
    }

    /// @notice Both mentor or mentee can mark sessions complete, releasing funds incrementally and updating reputation.
    /// @param _mentorshipId The ID of the mentorship.
    /// @param _sessionsCompleted The number of sessions being marked as completed in this batch.
    /// @param _proof A string describing proof of completion (e.g., "session log hash", "meeting ID").
    function completeMentorshipMilestone(uint256 _mentorshipId, uint256 _sessionsCompleted, string calldata _proof) external whenNotPaused nonReentrant {
        Mentorship storage m = mentorships[_mentorshipId];
        require(m.mentor == msg.sender || m.mentee == msg.sender, "DASCNet: Not a participant in this mentorship");
        require(m.status == MentorshipStatus.Accepted || m.status == MentorshipStatus.InProgress, "DASCNet: Mentorship not active");
        require(_sessionsCompleted > 0, "DASCNet: Must complete at least one session");
        require(m.sessionsCompleted + _sessionsCompleted <= m.numSessionsAgreed, "DASCNet: Exceeds agreed sessions");

        m.sessionsCompleted += _sessionsCompleted;
        uint256 fundsPerSession = m.totalDeposit / m.numSessionsAgreed; // Integer division
        uint256 amountToRelease = _sessionsCompleted * fundsPerSession;

        (bool success, ) = payable(m.mentor).call{value: amountToRelease}("");
        require(success, "DASCNet: Failed to send funds to mentor");

        if (m.sessionsCompleted == m.numSessionsAgreed) {
            m.status = MentorshipStatus.Completed;
            // Refund any remainder due to integer division (if any)
            uint256 remainingDeposit = m.totalDeposit - (m.sessionsCompleted * fundsPerSession);
            if (remainingDeposit > 0) {
                (bool successRefund, ) = payable(m.mentee).call{value: remainingDeposit}("");
                require(successRefund, "DASCNet: Failed to refund mentee remainder");
            }
        } else {
            m.status = MentorshipStatus.InProgress;
        }
        m.lastUpdateTimestamp = block.timestamp;

        // Reputation boost for mentee's relevant skill SBT
        uint256 menteeSBTId = 0;
        uint256 mentorSkillDefId = skillSBTs[m.offerSkillSBTId].skillDefinitionId;
        for (uint256 i = 0; i < _userSkillSBTs[m.mentee].length; i++) {
            if (skillSBTs[_userSkillSBTs[m.mentee][i]].skillDefinitionId == mentorSkillDefId) {
                menteeSBTId = _userSkillSBTs[m.mentee][i];
                break;
            }
        }
        if (menteeSBTId != 0) {
             uint256 menteeReputationIncrease = (baseReputationGain * _sessionsCompleted) / m.numSessionsAgreed;
             updateSkillSBTLevel(menteeSBTId, skillSBTs[menteeSBTId].level + menteeReputationIncrease, "Mentorship Completion (Mentee)");
        }

        // Mentor's reputation increase
        uint256 mentorReputationIncrease = (baseReputationGain * _sessionsCompleted * mentorEfficiencyRate) / (m.numSessionsAgreed * 100);
        updateSkillSBTLevel(m.offerSkillSBTId, skillSBTs[m.offerSkillSBTId].level + mentorReputationIncrease, "Mentorship Completion (Mentor)");

        emit MentorshipMilestoneCompleted(_mentorshipId, _sessionsCompleted, amountToRelease);
    }

    /// @notice Admin/arbiter resolves a mentorship dispute. Only callable by the contract owner.
    /// @param _mentorshipId The ID of the mentorship in dispute.
    /// @param _winner The address designated as the winner (mentor or mentee).
    /// @param _amount The amount to release to the winner from the remaining deposit.
    function resolveMentorshipDispute(uint256 _mentorshipId, address _winner, uint256 _amount) external onlyOwner nonReentrant {
        Mentorship storage m = mentorships[_mentorshipId];
        require(m.status == MentorshipStatus.Disputed, "DASCNet: Mentorship not in dispute");
        require(_winner == m.mentor || _winner == m.mentee, "DASCNet: Winner must be mentor or mentee");

        uint256 remainingEscrow = m.totalDeposit - (m.sessionsCompleted * (m.totalDeposit / m.numSessionsAgreed));
        require(_amount <= remainingEscrow, "DASCNet: Amount exceeds remaining deposit in escrow");

        m.status = MentorshipStatus.Resolved;
        m.disputeWinner = _winner;
        m.disputeResolutionAmount = _amount;

        (bool success, ) = payable(_winner).call{value: _amount}("");
        require(success, "DASCNet: Failed to resolve dispute payment");

        // Refund remaining funds to the loser, or if unsuccessful, they remain in the contract as fees.
        uint256 refundAmount = remainingEscrow - _amount;
        if (refundAmount > 0) {
            address loser = (_winner == m.mentor) ? m.mentee : m.mentor;
            (bool refundSuccess, ) = payable(loser).call{value: refundAmount}("");
            // If refund fails, funds stay in contract.
            if (!refundSuccess) { /* Funds become part of protocol fee balance */ }
        }

        // Adjust reputation based on dispute outcome (simplified: winner gains)
        uint256 reputationImpact = baseReputationGain * 2; // Significant impact for dispute resolution
        if (_winner == m.mentor) {
            updateSkillSBTLevel(m.offerSkillSBTId, skillSBTs[m.offerSkillSBTId].level + reputationImpact, "Dispute Resolution (Mentor Win)");
        } else { // Mentee wins
            uint256 menteeSBTId = 0;
            uint256 mentorSkillDefId = skillSBTs[m.offerSkillSBTId].skillDefinitionId;
            for (uint256 i = 0; i < _userSkillSBTs[m.mentee].length; i++) {
                if (skillSBTs[_userSkillSBTs[m.mentee][i]].skillDefinitionId == mentorSkillDefId) {
                    menteeSBTId = _userSkillSBTs[m.mentee][i];
                    break;
                }
            }
            if (menteeSBTId != 0) {
                updateSkillSBTLevel(menteeSBTId, skillSBTs[menteeSBTId].level + (reputationImpact / 2), "Dispute Resolution (Mentee Win)");
            }
        }
        emit MentorshipDisputeResolved(_mentorshipId, _winner, _amount);
    }

    /// @notice Allows both participating parties to leave feedback, impacting mentor/mentee reputation.
    /// @param _mentorshipId The ID of the mentorship.
    /// @param _rating A rating (e.g., 1-5, where 5 is excellent).
    /// @param _comment A brief comment string.
    function leaveFeedbackOnMentorship(uint256 _mentorshipId, uint256 _rating, string calldata _comment) external whenNotPaused {
        Mentorship storage m = mentorships[_mentorshipId];
        require(m.status == MentorshipStatus.Completed || m.status == MentorshipStatus.Resolved, "DASCNet: Mentorship not completed or resolved");
        require(m.mentor == msg.sender || m.mentee == msg.sender, "DASCNet: Not a participant in this mentorship");
        require(_rating >= 1 && _rating <= 5, "DASCNet: Rating must be between 1 and 5");

        uint256 reputationChange = 0;
        if (_rating == 5) {
            reputationChange = baseReputationGain * 150 / 100; // 1.5x base gain
        } else if (_rating == 4) {
            reputationChange = baseReputationGain; // Base gain
        } else if (_rating == 3) {
            reputationChange = baseReputationGain / 2; // Half gain
        }
        // Ratings 1 or 2 give 0 gain (as updateSkillSBTLevel only allows increases).

        if (msg.sender == m.mentee) { // Mentee leaving feedback for mentor
            updateSkillSBTLevel(m.offerSkillSBTId, skillSBTs[m.offerSkillSBTId].level + reputationChange, "Mentee Feedback");
        } else { // Mentor leaving feedback for mentee
            uint256 menteeSBTId = 0;
            uint256 mentorSkillDefId = skillSBTs[m.offerSkillSBTId].skillDefinitionId;
            for (uint256 i = 0; i < _userSkillSBTs[m.mentee].length; i++) {
                if (skillSBTs[_userSkillSBTs[m.mentee][i]].skillDefinitionId == mentorSkillDefId) {
                    menteeSBTId = _userSkillSBTs[m.mentee][i];
                    break;
                }
            }
            if (menteeSBTId != 0) {
                updateSkillSBTLevel(menteeSBTId, skillSBTs[menteeSBTId].level + reputationChange, "Mentor Feedback");
            }
        }
        emit MentorshipFeedbackLeft(_mentorshipId, msg.sender, _rating);
    }

    // --- Project-Based Collaboration Features ---

    /// @notice Proposes a new collaborative project, collecting a fee and the reward budget.
    /// @param _projectName The name of the project.
    /// @param _description A detailed description of the project.
    /// @param _requiredSkillDefinitionIds An array of skill definition IDs required for the project.
    /// @param _durationDays Expected duration of the project in days.
    /// @param _rewardBudget Total native currency reward budget for the project.
    function createProjectProposal(string calldata _projectName, string calldata _description, uint256[] calldata _requiredSkillDefinitionIds, uint256 _durationDays, uint256 _rewardBudget) external payable whenNotPaused nonReentrant {
        require(msg.value >= projectCreationFee + _rewardBudget, "DASCNet: Insufficient funds for fee and reward budget");
        require(_durationDays > 0, "DASCNet: Project duration must be positive");
        require(_rewardBudget > 0, "DASCNet: Reward budget must be positive");
        for (uint256 i = 0; i < _requiredSkillDefinitionIds.length; i++) {
            require(skillProposals[_requiredSkillDefinitionIds[i]].status == SkillProposalStatus.Approved, "DASCNet: Required skill definition not approved");
        }

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        Project storage newProject = projects[newProjectId];
        newProject.name = _projectName;
        newProject.description = _description;
        newProject.creator = msg.sender;
        newProject.requiredSkillDefinitionIds = _requiredSkillDefinitionIds;
        newProject.durationDays = _durationDays;
        newProject.rewardBudget = _rewardBudget;
        newProject.collectedFunds = msg.value; // Collect fee + budget
        newProject.status = ProjectStatus.Proposed;
        // `milestoneCounter` is initially 0 for the first milestone (index 1)

        emit ProjectProposed(newProjectId, _projectName, msg.sender, _rewardBudget);
    }

    /// @notice Allows a user to join a project team if they possess one of the required Skill SBTs.
    /// @param _projectId The ID of the project to join.
    /// @param _userSkillSBTId The ID of the user's Skill SBT relevant to this project.
    function joinProjectTeam(uint256 _projectId, uint256 _userSkillSBTId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "DASCNet: Project not open for joining");
        require(ownerOf(_userSkillSBTId) == msg.sender, "DASCNet: You must own this Skill SBT");
        require(project.teamMembers[msg.sender] == 0, "DASCNet: You are already a member of this project");

        // Check if the user's SBT matches one of the required skill definitions
        bool hasRequiredSkill = false;
        uint256 userSkillDefId = skillSBTs[_userSkillSBTId].skillDefinitionId;
        for (uint256 i = 0; i < project.requiredSkillDefinitionIds.length; i++) {
            if (project.requiredSkillDefinitionIds[i] == userSkillDefId) {
                hasRequiredSkill = true;
                break;
            }
        }
        require(hasRequiredSkill, "DASCNet: Your SBT does not match any required skill for this project");

        project.teamMembers[msg.sender] = _userSkillSBTId;
        project.teamMemberAddresses.push(msg.sender);

        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Active; // Project becomes active once a member joins
        }

        emit ProjectJoined(_projectId, msg.sender, _userSkillSBTId);
    }

    /// @notice Project lead or any team member submits proof for a milestone. This creates the milestone if it's the next in sequence.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone (1-based).
    /// @param _proofData String containing URI or hash of off-chain proof of work.
    function submitProjectMilestoneProof(uint256 _projectId, uint256 _milestoneIndex, string calldata _proofData) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DASCNet: Project not active");
        require(project.teamMembers[msg.sender] != 0 || project.creator == msg.sender, "DASCNet: Not a team member or creator");
        require(_milestoneIndex > 0, "DASCNet: Milestone index must be positive");

        ProjectMilestone storage milestone = project.milestones[_milestoneIndex];

        if (_milestoneIndex == project.milestoneCounter.current() + 1) {
            // If it's the next sequential milestone, initialize it
            project.milestoneCounter.increment();
            milestone.description = _proofData; // Using proofData as description for simplicity here
            milestone.expectedCompletionTime = block.timestamp + (project.durationDays * 1 days / project.milestoneCounter.current()); // A placeholder calculation
            milestone.isCompleted = false;
            milestone.milestoneRewardShare = project.rewardBudget / (project.milestoneCounter.current()); // Simple even split of total budget for each milestone
        } else {
            require(_milestoneIndex <= project.milestoneCounter.current(), "DASCNet: Milestone index out of sequence");
        }
        require(!milestone.isCompleted, "DASCNet: Milestone already completed");

        // Mark that this specific contributor has submitted their proof for this milestone.
        milestone.contributorSubmittedProof[msg.sender] = true;

        emit ProjectMilestoneProofSubmitted(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice Team members or the oracle verify a contributor's work for a milestone.
    ///         A milestone is marked as complete when all `teamMemberAddresses` (or a majority/creator) have their work implicitly or explicitly verified.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @param _contributor The address of the contributor whose work is being verified.
    /// @param _isVerified True if the contributor's work is verified.
    function verifyProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, address _contributor, bool _isVerified) external whenNotPaused {
        Project storage project = projects[_projectId];
        ProjectMilestone storage milestone = project.milestones[_milestoneIndex];

        require(project.status == ProjectStatus.Active, "DASCNet: Project not active");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCounter.current(), "DASCNet: Milestone does not exist");
        require(!milestone.isCompleted, "DASCNet: Milestone already completed");
        require(milestone.contributorSubmittedProof[_contributor], "DASCNet: Contributor has not submitted proof for this milestone");

        // Only project creator, another team member (can verify others), or the oracle can verify.
        require(msg.sender == project.creator || project.teamMembers[msg.sender] != 0 || msg.sender == oracleAddress, "DASCNet: Not authorized to verify");
        // Ensure _contributor is a legitimate member
        require(project.teamMembers[_contributor] != 0 || project.creator == _contributor, "DASCNet: Target contributor is not a project member/creator");

        if (_isVerified) {
            milestone.contributorVerifiedByProtocol[_contributor] = true;
            // Add to verified list if not already there (prevents duplicates).
            bool alreadyInList = false;
            for(uint224 i=0; i < milestone.verifiedContributorsList.length; i++) {
                if (milestone.verifiedContributorsList[i] == _contributor) {
                    alreadyInList = true;
                    break;
                }
            }
            if (!alreadyInList) {
                milestone.verifiedContributorsList.push(_contributor);
            }
        } else {
            milestone.contributorVerifiedByProtocol[_contributor] = false; // Allow un-verification
            // Remove from verified list if present (more complex, might skip for simplicity in demo)
        }

        // Check if all active team members for this milestone have been verified by the protocol
        bool allRequiredContributorsVerified = true;
        uint256 activeTeamCount = 0;
        for (uint256 i = 0; i < project.teamMemberAddresses.length; i++) {
            address member = project.teamMemberAddresses[i];
            if (project.teamMembers[member] != 0) { // Check if still an active member
                activeTeamCount++;
                if (!milestone.contributorVerifiedByProtocol[member]) {
                    allRequiredContributorsVerified = false;
                    break;
                }
            }
        }

        // If all active team members (who are supposed to contribute) are verified, mark milestone as complete.
        // Or, if creator/oracle explicitly calls this on all contributors, or a simpler rule applies (e.g., creator's single vote).
        // For simplicity, milestone completes if all contributors are marked as verified and there's at least one active team member.
        if (allRequiredContributorsVerified && activeTeamCount > 0) {
            milestone.isCompleted = true;
        }

        emit ProjectMilestoneVerified(_projectId, _milestoneIndex, _contributor);
    }

    /// @notice Distributes rewards (reputation/tokens) upon verified milestone completion.
    ///         Only callable by project creator or contract owner.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    function distributeProjectRewards(uint256 _projectId, uint256 _milestoneIndex) external nonReentrant whenNotPaused {
        Project storage project = projects[_projectId];
        ProjectMilestone storage milestone = project.milestones[_milestoneIndex];

        require(project.status == ProjectStatus.Active, "DASCNet: Project not active");
        require(milestone.isCompleted, "DASCNet: Milestone not yet completed");
        require(msg.sender == project.creator || msg.sender == owner(), "DASCNet: Only project creator or owner can distribute rewards");
        require(milestone.milestoneRewardShare > 0, "DASCNet: Rewards already distributed for this milestone");

        uint256 totalRewardForMilestone = milestone.milestoneRewardShare;
        uint256 numContributors = milestone.verifiedContributorsList.length;
        require(numContributors > 0, "DASCNet: No verified contributors to distribute rewards to");

        uint256 rewardPerContributor = totalRewardForMilestone / numContributors;

        for (uint256 i = 0; i < numContributors; i++) {
            address contributor = milestone.verifiedContributorsList[i];
            uint256 contributorSBTId = project.teamMembers[contributor];

            // Distribute native currency reward
            if (rewardPerContributor > 0) {
                (bool success, ) = payable(contributor).call{value: rewardPerContributor}("");
                require(success, "DASCNet: Failed to send project reward to contributor");
            }

            // Boost reputation for the relevant SBT
            uint256 reputationGain = (baseReputationGain * projectComplexityFactor) / 100;
            if (contributorSBTId != 0) { // Ensure they have an SBT associated with joining the project
                 // `updateSkillSBTLevel` is called directly, bypassing the `msg.sender` checks as it's an internal protocol action.
                 // This would require changing `updateSkillSBTLevel` to be `internal` or using an `onlyProtocol` modifier.
                 // For now, I'll directly modify the struct and emit an event as it's an authorized internal action.
                 SkillSBT storage sbt = skillSBTs[contributorSBTId];
                 uint256 oldLevel = sbt.level;
                 sbt.level += reputationGain; // Assuming we can always increase here
                 sbt.lastUpdated = block.timestamp;
                 emit SkillSBTLevelUpdated(contributorSBTId, oldLevel, sbt.level, "Project Milestone Completion");
            }
        }

        milestone.milestoneRewardShare = 0; // Mark rewards as distributed for this milestone
        emit ProjectRewardsDistributed(_projectId, _milestoneIndex, totalRewardForMilestone);

        // Optional: Check if all milestones are completed to mark project as finished.
        // This requires knowing the total number of milestones for a project in advance.
        // For this demo, projects don't auto-complete on last milestone distribution.
        // A `completeProject` function would be needed, callable by creator/owner.
    }


    /// @notice Allows a team member to exit a project early.
    ///         Note: Due to `updateSkillSBTLevel` only allowing level-ups, no direct reputation penalty is applied here.
    ///         A more complex system could track negative reputation or allow level-downs.
    /// @param _projectId The ID of the project.
    function exitProjectEarly(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "DASCNet: Project not active");
        require(project.teamMembers[msg.sender] != 0, "DASCNet: You are not a member of this project");
        require(project.creator != msg.sender, "DASCNet: Project creator cannot simply exit, they manage the project lifecycle.");

        delete project.teamMembers[msg.sender]; // Remove from mapping

        // Remove from dynamic array (less efficient for large arrays, but simple for demo)
        for (uint256 i = 0; i < project.teamMemberAddresses.length; i++) {
            if (project.teamMemberAddresses[i] == msg.sender) {
                project.teamMemberAddresses[i] = project.teamMemberAddresses[project.teamMemberAddresses.length - 1];
                project.teamMemberAddresses.pop();
                break;
            }
        }
        emit ProjectExited(_projectId, msg.sender);
    }


    // --- ERC721 Overrides for Soulbound Behavior ---

    /// @dev Prevents transfers of SBTs, making them soulbound.
    ///      Allows minting (from address(0)) and burning (to address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert("DASCNet: Skill SBTs are soulbound and cannot be transferred.");
        }
    }

    /// @dev Marks token as non-transferable according to EIP-4671 (Soulbound).
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        // Return true for ERC721 and ERC721Metadata interfaces.
        // Optionally, one might return false for ERC721Enumerable or other interfaces
        // that imply transferability if they were explicitly used for soulbound tokens.
        // EIP-4671 suggests that for soulbound tokens, `transferFrom` and `safeTransferFrom`
        // should always revert. The `_beforeTokenTransfer` handles this.
        // No specific EIP for Soulbound has a dedicated `interfaceId` yet that would return `true` here.
        return super.supportsInterface(interfaceId);
    }

    // Fallback function to accept Ether
    receive() external payable {}
    fallback() external payable {}
}
```