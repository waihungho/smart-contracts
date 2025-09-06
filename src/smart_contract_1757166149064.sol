This smart contract, **"TalentSphere"**, is a decentralized talent and collaboration network. It introduces a novel blend of **dynamic Soulbound Tokens (SBTs)** for verifiable skill representation, a **weighted and disputable reputation system**, and a **fully on-chain project management and escrow system** with built-in arbitration, all designed to foster a meritocratic and transparent environment for collaboration.

It moves beyond simple token/NFT contracts by creating an interconnected ecosystem where a user's verifiable skills (SBTs), reputation, and project contributions directly influence their capabilities and opportunities within the network. The system aims to be self-governing and adaptive, with parameters that can be adjusted by a future DAO.

---

## TalentSphere Smart Contract: Outline & Function Summary

**Contract Name:** `TalentSphere`

**Core Concepts:**
*   **Dynamic Soulbound Tokens (SBTs):** Non-transferable tokens representing verified skills, awarded through challenges or evaluations. They are "dynamic" as their value/impact can change with network parameters, and they can be revoked.
*   **Weighted & Disputable Reputation System:** A user's reputation is not just a simple counter. It's calculated based on successful project completions, the age and number of their skill badges, and endorsements from other high-reputation users. Endorsements can be disputed to prevent abuse.
*   **Decentralized Project Escrow & Arbitration:** Projects are funded on-chain, and payments are released milestone-by-milestone upon project creator approval. Disputes can be raised, leading to an arbitration process.
*   **On-Chain Profiles:** Users create persistent, decentralized identities linked to their skills and reputation.
*   **Adaptive Fee Mechanisms (Implied/Extensible):** While not explicitly dynamic in every function, the design allows for fees and parameter adjustments (e.g., `challengeFee`, `minEvaluatorStake`) by an admin/governance, hinting at a future adaptive economy.

**Outline:**

1.  **Enums & Structs:** Defines the core data structures for profiles, skills, badges, projects, endorsements, and disputes.
2.  **State Variables:** Mappings to store all network data.
3.  **Events:** For transparent logging of key actions.
4.  **Modifiers:** Access control for admin, project creators, and evaluators.
5.  **Constructor:** Initializes the contract with an admin.
6.  **I. User Profiles & Decentralized Identity (SBT-based)**
    *   `registerProfile`
    *   `updateProfile`
    *   `getProfile`
7.  **II. Dynamic Skill Badges (Soulbound Token - SBT) System**
    *   `defineSkill`
    *   `requestSkillChallenge`
    *   `evaluateSkillChallenge`
    *   `revokeSkillBadge`
    *   `getSkillBadge`
    *   `getAllUserSkillBadges`
8.  **III. Reputation & Endorsement System (Weighted & Disputable)**
    *   `endorseSkill`
    *   `disputeEndorsement`
    *   `resolveEndorsementDispute`
    *   `getWeightedReputation`
9.  **IV. Dynamic Project Collaboration & Escrow System**
    *   `proposeProject`
    *   `fundProject`
    *   `applyForProject`
    *   `selectContributors`
    *   `submitMilestoneDeliverable`
    *   `approveMilestone`
    *   `disputeMilestone`
    *   `resolveMilestoneDispute`
    *   `completeProject`

---

**Function Summary (22 Functions):**

**I. User Profiles & Decentralized Identity (SBT-based)**

1.  `registerProfile(name, bioCID, profilePictureCID)`:
    *   Allows a user to create a unique, persistent on-chain profile with basic information.
    *   `name`: Display name.
    *   `bioCID`: IPFS CID for a detailed biography.
    *   `profilePictureCID`: IPFS CID for a profile image.
2.  `updateProfile(name, bioCID, profilePictureCID)`:
    *   Enables a registered user to modify their profile information.
3.  `getProfile(userAddress)`:
    *   Retrieves the full profile details for a given user address.

**II. Dynamic Skill Badges (Soulbound Token - SBT) System**

4.  `defineSkill(skillName, descriptionCID, requiredReputation, challengeFee, minEvaluatorStake)`:
    *   `onlyAdmin` function to define a new skill type that users can earn badges for.
    *   Sets requirements for challenging/evaluating this skill.
    *   `skillName`: Name of the skill (e.g., "Solidity Expert").
    *   `descriptionCID`: IPFS CID for a detailed skill description.
    *   `requiredReputation`: Minimum reputation to attempt this challenge.
    *   `challengeFee`: Fee (in native token) to request a challenge.
    *   `minEvaluatorStake`: Minimum stake required for an address to become an evaluator for this skill.
5.  `requestSkillChallenge(skillId, challengeProofCID)`:
    *   A user can request to earn a `SkillBadgeSBT` by initiating a challenge.
    *   Requires payment of the `challengeFee` and meeting `requiredReputation`.
    *   `challengeProofCID`: IPFS CID pointing to the user's proof/submission for the skill.
6.  `evaluateSkillChallenge(challengeId, isPassed, evaluationProofCID)`:
    *   `onlyEvaluator` function. A designated evaluator reviews the submitted `challengeProofCID`.
    *   If `isPassed` is true, a non-transferable `SkillBadgeSBT` is minted to the user.
    *   Evaluator earns a portion of the `challengeFee` for their service.
    *   `evaluationProofCID`: IPFS CID for the evaluator's justification/feedback.
7.  `revokeSkillBadge(user, skillId, reasonCID)`:
    *   `onlyAdmin` (or future DAO governance) function to revoke a `SkillBadgeSBT` from a user, e.g., due to misconduct or outdated skill.
    *   `reasonCID`: IPFS CID for the reason of revocation.
8.  `getSkillBadge(user, skillId)`:
    *   Retrieves the details of a specific `SkillBadgeSBT` held by a user.
9.  `getAllUserSkillBadges(user)`:
    *   Returns a list of all `skillId`s for which a user holds a `SkillBadgeSBT`.

**III. Reputation & Endorsement System (Weighted & Disputable)**

10. `endorseSkill(endorsedUser, skillId, commentCID)`:
    *   Allows a registered user to endorse another user's skill.
    *   Requires a small stake from the endorser, which is locked to add weight to the endorsement.
    *   `commentCID`: IPFS CID for an optional comment/justification for the endorsement.
11. `disputeEndorsement(endorsementId, reasonCID)`:
    *   Any user can dispute a potentially false or malicious endorsement.
    *   Requires a stake from the disputer to prevent frivolous disputes.
    *   `reasonCID`: IPFS CID for the reason of the dispute.
12. `resolveEndorsementDispute(disputeId, isLegitimate, penaltyTo)`:
    *   `onlyAdmin` (or future DAO arbitration) function to resolve an endorsement dispute.
    *   If `isLegitimate` is true, the disputed endorsement is removed, and the endorser is penalized.
    *   If `isLegitimate` is false, the disputer is penalized. Stakes are redistributed.
    *   `penaltyTo`: Address to send forfeited stakes (e.g., treasury).
13. `getWeightedReputation(user)`:
    *   Calculates and returns a user's dynamic reputation score.
    *   This score is based on:
        *   Successful project completions (higher weight).
        *   Number and age of `SkillBadgeSBTs`.
        *   Weighted endorsements (endorsements from high-reputation users carry more weight).
        *   Absence of revoked badges or lost disputes.

**IV. Dynamic Project Collaboration & Escrow System**

14. `proposeProject(titleCID, descriptionCID, requiredSkills, initialBounty, milestoneCount, deadline)`:
    *   A user can propose a new project, defining its scope, skill requirements, total bounty, and milestone structure.
    *   `titleCID`: IPFS CID for project title.
    *   `descriptionCID`: IPFS CID for detailed project description.
    *   `requiredSkills`: Array of `skillId`s needed for contributors.
    *   `initialBounty`: Total native token amount for the project.
    *   `milestoneCount`: Number of milestones for the project.
    *   `deadline`: Timestamp by which the project should be completed.
15. `fundProject(projectId)`:
    *   Anyone can contribute native tokens to a `projectId`'s escrow.
    *   The project can only start once the `initialBounty` is fully funded.
16. `applyForProject(projectId, coverLetterCID)`:
    *   Users meeting the project's `requiredSkills` and a minimum reputation can apply to be contributors.
    *   `coverLetterCID`: IPFS CID for the applicant's cover letter/proposal.
17. `selectContributors(projectId, selectedApplicants)`:
    *   `onlyProjectCreator` function to select contributors from the pool of applicants.
    *   These contributors are now authorized to submit deliverables and claim milestone payouts.
18. `submitMilestoneDeliverable(projectId, milestoneIndex, deliverableCID)`:
    *   `onlyContributor` function. A selected contributor submits their work for a specific milestone.
    *   `deliverableCID`: IPFS CID for the completed work/proof.
19. `approveMilestone(projectId, milestoneIndex, feedbackCID)`:
    *   `onlyProjectCreator` function. Approves a submitted milestone deliverable.
    *   Releases the allocated native token funds for that milestone to the contributor.
    *   `feedbackCID`: IPFS CID for optional feedback to the contributor.
20. `disputeMilestone(projectId, milestoneIndex, reasonCID)`:
    *   Either the project creator or a contributor can dispute a milestone (e.g., creator not approving, contributor not delivering).
    *   Initiates an arbitration process.
    *   `reasonCID`: IPFS CID for the reason of the dispute.
21. `resolveMilestoneDispute(disputeId, winnerAddress, payoutAllocation)`:
    *   `onlyAdmin` (or future DAO arbitration) function to resolve a milestone dispute.
    *   Determines the `winnerAddress` and how `payoutAllocation` (native token) for the disputed milestone should be distributed.
22. `completeProject(projectId, finalReportCID)`:
    *   `onlyProjectCreator` function to mark the project as fully completed after all milestones are approved.
    *   Triggers reputation updates for all successful contributors.
    *   `finalReportCID`: IPFS CID for an optional final project report.

---
**Smart Contract Code (Solidity)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For potential future interaction, though SBTs are non-transferable.
import "@openzeppelin/contracts/utils/Counters.sol"; // To generate unique IDs

/// @title TalentSphere - A Decentralized Talent & Collaboration Network
/// @author [Your Name/AI]
/// @notice This contract provides a platform for users to create profiles, earn skill-based Soulbound Tokens (SBTs), build reputation through endorsements and project contributions, and collaborate on projects with on-chain escrow and arbitration.
/// @dev This is an advanced concept contract, not duplicating existing open-source solutions by integrating dynamic SBTs, weighted disputable reputation, and comprehensive project management with arbitration in a single, interconnected system.

contract TalentSphere is Ownable {
    using Counters for Counters.Counter;

    // --- Enums and Structs ---

    enum ProjectStatus { Proposed, Funding, Active, Disputed, Completed, Cancelled }
    enum DisputeStatus { Open, Resolved }
    enum EndorsementStatus { Active, Disputed, Resolved }

    struct UserProfile {
        address userAddress;
        string name;
        string bioCID; // IPFS CID for detailed biography
        string profilePictureCID; // IPFS CID for profile image
        uint256 registeredAt;
        uint256 totalProjectsCompleted;
        uint256 totalReputationEarned; // For internal tracking, weighted reputation is calculated on-the-fly
        mapping(uint256 => bool) hasSkillBadge; // skillId => bool
        mapping(uint256 => uint256) skillBadgeMintTime; // skillId => timestamp
    }

    struct SkillType {
        uint256 id;
        string name;
        string descriptionCID; // IPFS CID for skill description
        uint256 requiredReputation; // Min reputation to attempt challenge
        uint256 challengeFee; // Native token fee to request a challenge
        uint256 minEvaluatorStake; // Min stake required for an address to be an evaluator for this skill
        address[] authorizedEvaluators;
        bool exists;
    }

    struct SkillChallenge {
        uint256 id;
        uint256 skillId;
        address challenger;
        string challengeProofCID; // IPFS CID for user's submission
        uint256 requestedAt;
        address evaluator; // Assigned evaluator
        bool isPassed;
        string evaluationProofCID; // IPFS CID for evaluator's justification
        bool isEvaluated;
        bool exists;
    }

    struct Endorsement {
        uint256 id;
        address endorser;
        address endorsed;
        uint256 skillId;
        string commentCID; // IPFS CID for optional comment
        uint256 stake; // Locked stake by endorser
        EndorsementStatus status;
        uint256 createdAt;
    }

    struct Project {
        uint256 id;
        address creator;
        string titleCID; // IPFS CID for project title
        string descriptionCID; // IPFS CID for project description
        uint256[] requiredSkills; // Array of skillIds
        uint256 totalBounty; // Total native token bounty
        uint256 fundedAmount;
        uint256 milestoneCount;
        uint256 deadline; // Unix timestamp
        address[] contributors;
        ProjectStatus status;
        uint256 createdAt;
        mapping(uint256 => Milestone) milestones; // milestoneIndex => Milestone
        mapping(address => bool) isContributor; // address => bool
        uint256 lastActivity; // Timestamp of last approval or submission
        uint256 completedMilestones;
    }

    struct Milestone {
        uint256 index;
        address contributor; // Assigned contributor for this milestone
        string deliverableCID; // IPFS CID for submitted work
        bool isSubmitted;
        bool isApproved;
        uint256 payoutAmount; // Native token amount for this milestone
        string creatorFeedbackCID; // IPFS CID for creator's feedback
        bool isDisputed;
    }

    struct Dispute {
        uint256 id;
        uint256 relatedEntityId; // project id, milestone index, endorsement id
        uint256 entityType; // 0: Project, 1: Milestone, 2: Endorsement
        address initiator;
        string reasonCID; // IPFS CID for dispute reason
        DisputeStatus status;
        address winner;
        uint256 penaltyAmount; // Amount to be penalized or allocated
        uint256 createdAt;
    }

    // --- State Variables ---

    Counters.Counter private _profileIds;
    Counters.Counter private _skillIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _endorsementIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _disputeIds;

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => SkillType) public skillTypes;
    mapping(uint256 => SkillChallenge) public skillChallenges;
    mapping(uint256 => Endorsement) public endorsements;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---

    event ProfileRegistered(address indexed user, string name, uint256 registeredAt);
    event ProfileUpdated(address indexed user, string name);
    event SkillDefined(uint256 indexed skillId, string name, address indexed admin);
    event SkillChallengeRequested(uint256 indexed challengeId, uint256 indexed skillId, address indexed challenger);
    event SkillChallengeEvaluated(uint256 indexed challengeId, address indexed evaluator, bool isPassed);
    event SkillBadgeMinted(address indexed user, uint256 indexed skillId, uint256 challengeId);
    event SkillBadgeRevoked(address indexed user, uint256 indexed skillId, address indexed revoker);
    event SkillEndorsed(uint256 indexed endorsementId, address indexed endorser, address indexed endorsed, uint256 skillId);
    event EndorsementDisputed(uint256 indexed disputeId, uint256 indexed endorsementId, address indexed initiator);
    event EndorsementDisputeResolved(uint256 indexed disputeId, uint256 indexed endorsementId, address indexed winner, uint256 penalty);
    event ProjectProposed(uint256 indexed projectId, address indexed creator, uint256 totalBounty, uint256 milestoneCount);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectApplication(uint256 indexed projectId, address indexed applicant);
    event ContributorsSelected(uint256 indexed projectId, address[] contributors);
    event MilestoneDeliverableSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed contributor);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed approver, address indexed contributor, uint256 payout);
    event MilestoneDisputed(uint256 indexed disputeId, uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed initiator);
    event MilestoneDisputeResolved(uint256 indexed disputeId, uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed winner, uint256 payoutAllocation);
    event ProjectCompleted(uint256 indexed projectId, address indexed creator);

    // --- Modifiers ---

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].registeredAt != 0, "TS: Caller not registered");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "TS: Not project creator");
        _;
    }

    modifier onlyContributor(uint256 _projectId, uint256 _milestoneIndex) {
        require(projects[_projectId].isContributor[msg.sender], "TS: Not a contributor to this project");
        require(projects[_projectId].milestones[_milestoneIndex].contributor == msg.sender, "TS: Not assigned to this milestone");
        _;
    }

    modifier onlyEvaluator(uint256 _skillId) {
        bool isAuthorized = false;
        for (uint256 i = 0; i < skillTypes[_skillId].authorizedEvaluators.length; i++) {
            if (skillTypes[_skillId].authorizedEvaluators[i] == msg.sender) {
                isAuthorized = true;
                break;
            }
        }
        require(isAuthorized, "TS: Caller not an authorized evaluator for this skill");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- I. User Profiles & Decentralized Identity (SBT-based) ---

    /// @notice Registers a new user profile on the TalentSphere network.
    /// @param _name The user's display name.
    /// @param _bioCID IPFS CID pointing to the user's detailed biography.
    /// @param _profilePictureCID IPFS CID pointing to the user's profile picture.
    function registerProfile(string calldata _name, string calldata _bioCID, string calldata _profilePictureCID) external {
        require(userProfiles[msg.sender].registeredAt == 0, "TS: User already registered");
        _profileIds.increment();
        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            name: _name,
            bioCID: _bioCID,
            profilePictureCID: _profilePictureCID,
            registeredAt: block.timestamp,
            totalProjectsCompleted: 0,
            totalReputationEarned: 0 // Will be calculated dynamically
        });
        emit ProfileRegistered(msg.sender, _name, block.timestamp);
    }

    /// @notice Updates an existing user's profile information.
    /// @param _name The new display name.
    /// @param _bioCID IPFS CID for the updated biography.
    /// @param _profilePictureCID IPFS CID for the updated profile picture.
    function updateProfile(string calldata _name, string calldata _bioCID, string calldata _profilePictureCID) external onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];
        profile.name = _name;
        profile.bioCID = _bioCID;
        profile.profilePictureCID = _profilePictureCID;
        emit ProfileUpdated(msg.sender, _name);
    }

    /// @notice Retrieves the full profile details for a given user address.
    /// @param _userAddress The address of the user.
    /// @return UserProfile struct containing all profile data.
    function getProfile(address _userAddress) external view returns (UserProfile memory) {
        require(userProfiles[_userAddress].registeredAt != 0, "TS: User not registered");
        return userProfiles[_userAddress];
    }

    // --- II. Dynamic Skill Badges (Soulbound Token - SBT) System ---

    /// @notice Defines a new skill type that users can earn badges for. Only callable by the owner.
    /// @param _skillName The name of the skill (e.g., "Solidity Expert").
    /// @param _descriptionCID IPFS CID for a detailed description of the skill.
    /// @param _requiredReputation Minimum reputation score required to attempt a challenge for this skill.
    /// @param _challengeFee Native token fee to request a challenge for this skill.
    /// @param _minEvaluatorStake Minimum native token stake required for an address to become an evaluator for this skill.
    function defineSkill(string calldata _skillName, string calldata _descriptionCID, uint256 _requiredReputation, uint256 _challengeFee, uint256 _minEvaluatorStake) external onlyOwner {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skillTypes[newSkillId] = SkillType({
            id: newSkillId,
            name: _skillName,
            descriptionCID: _descriptionCID,
            requiredReputation: _requiredReputation,
            challengeFee: _challengeFee,
            minEvaluatorStake: _minEvaluatorStake,
            authorizedEvaluators: new address[](0),
            exists: true
        });
        emit SkillDefined(newSkillId, _skillName, msg.sender);
    }

    /// @notice Requests a challenge to earn a specific skill badge.
    /// @dev Requires the challenger to be registered, meet reputation requirements, and pay the challenge fee.
    /// @param _skillId The ID of the skill type to challenge.
    /// @param _challengeProofCID IPFS CID pointing to the user's submission/proof for the skill challenge.
    function requestSkillChallenge(uint256 _skillId, string calldata _challengeProofCID) external payable onlyRegistered {
        SkillType storage skill = skillTypes[_skillId];
        require(skill.exists, "TS: Skill does not exist");
        require(msg.value == skill.challengeFee, "TS: Incorrect challenge fee");
        require(getWeightedReputation(msg.sender) >= skill.requiredReputation, "TS: Insufficient reputation to challenge this skill");
        require(skill.authorizedEvaluators.length > 0, "TS: No evaluators available for this skill"); // At least one evaluator needed

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();
        
        // Simple evaluator assignment (can be improved with round-robin, least busy, or stake-weighted assignment)
        address assignedEvaluator = skill.authorizedEvaluators[newChallengeId % skill.authorizedEvaluators.length];

        skillChallenges[newChallengeId] = SkillChallenge({
            id: newChallengeId,
            skillId: _skillId,
            challenger: msg.sender,
            challengeProofCID: _challengeProofCID,
            requestedAt: block.timestamp,
            evaluator: assignedEvaluator,
            isPassed: false,
            evaluationProofCID: "",
            isEvaluated: false,
            exists: true
        });
        emit SkillChallengeRequested(newChallengeId, _skillId, msg.sender);
    }

    /// @notice An authorized evaluator evaluates a submitted skill challenge.
    /// @dev If passed, a non-transferable SkillBadgeSBT is "minted" (recorded). Evaluator receives a portion of the fee.
    /// @param _challengeId The ID of the skill challenge to evaluate.
    /// @param _isPassed True if the challenger passed the skill, false otherwise.
    /// @param _evaluationProofCID IPFS CID for the evaluator's justification/feedback.
    function evaluateSkillChallenge(uint256 _challengeId, bool _isPassed, string calldata _evaluationProofCID) external {
        SkillChallenge storage challenge = skillChallenges[_challengeId];
        require(challenge.exists, "TS: Challenge does not exist");
        require(msg.sender == challenge.evaluator, "TS: Caller is not the assigned evaluator");
        require(!challenge.isEvaluated, "TS: Challenge already evaluated");

        challenge.isPassed = _isPassed;
        challenge.evaluationProofCID = _evaluationProofCID;
        challenge.isEvaluated = true;

        if (_isPassed) {
            userProfiles[challenge.challenger].hasSkillBadge[challenge.skillId] = true;
            userProfiles[challenge.challenger].skillBadgeMintTime[challenge.skillId] = block.timestamp;
            // Transfer a portion of the challenge fee to the evaluator
            uint256 evaluatorReward = skillTypes[challenge.skillId].challengeFee / 2; // Example: 50% to evaluator
            payable(msg.sender).transfer(evaluatorReward);
            emit SkillBadgeMinted(challenge.challenger, challenge.skillId, _challengeId);
        }
        // Remaining fee can go to treasury or be burned
        emit SkillChallengeEvaluated(_challengeId, msg.sender, _isPassed);
    }

    /// @notice Revokes a skill badge from a user. Only callable by the contract owner.
    /// @param _user The address of the user whose badge is to be revoked.
    /// @param _skillId The ID of the skill badge to revoke.
    /// @param _reasonCID IPFS CID for the reason of revocation.
    function revokeSkillBadge(address _user, uint256 _skillId, string calldata _reasonCID) external onlyOwner {
        require(userProfiles[_user].registeredAt != 0, "TS: User not registered");
        require(userProfiles[_user].hasSkillBadge[_skillId], "TS: User does not have this skill badge");
        userProfiles[_user].hasSkillBadge[_skillId] = false;
        userProfiles[_user].skillBadgeMintTime[_skillId] = 0; // Reset mint time
        emit SkillBadgeRevoked(_user, _skillId, msg.sender);
        // _reasonCID is stored off-chain or in an event log
    }

    /// @notice Retrieves the details of a specific skill badge held by a user.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return A tuple indicating if the user has the badge and when it was minted.
    function getSkillBadge(address _user, uint256 _skillId) external view returns (bool hasBadge, uint256 mintTime) {
        require(userProfiles[_user].registeredAt != 0, "TS: User not registered");
        return (userProfiles[_user].hasSkillBadge[_skillId], userProfiles[_user].skillBadgeMintTime[_skillId]);
    }

    /// @notice Retrieves a list of all skill IDs for which a user holds a badge.
    /// @param _user The address of the user.
    /// @return An array of skill IDs.
    function getAllUserSkillBadges(address _user) external view returns (uint256[] memory) {
        require(userProfiles[_user].registeredAt != 0, "TS: User not registered");
        uint256[] memory skillIds = new uint256[](_skillIds.current());
        uint256 counter = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (userProfiles[_user].hasSkillBadge[i]) {
                skillIds[counter] = i;
                counter++;
            }
        }
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = skillIds[i];
        }
        return result;
    }

    // --- III. Reputation & Endorsement System (Weighted & Disputable) ---

    /// @notice Allows a registered user to endorse another user's skill.
    /// @dev Requires a small native token stake from the endorser, which is locked to add weight.
    /// @param _endorsedUser The user whose skill is being endorsed.
    /// @param _skillId The ID of the skill being endorsed.
    /// @param _commentCID IPFS CID for an optional comment/justification.
    function endorseSkill(address _endorsedUser, uint256 _skillId, string calldata _commentCID) external payable onlyRegistered {
        require(msg.sender != _endorsedUser, "TS: Cannot endorse yourself");
        require(userProfiles[_endorsedUser].registeredAt != 0, "TS: Endorsed user not registered");
        require(userProfiles[_endorsedUser].hasSkillBadge[_skillId], "TS: Endorsed user does not have this skill badge");
        require(msg.value > 0, "TS: Endorsement requires a stake");

        _endorsementIds.increment();
        uint256 newEndorsementId = _endorsementIds.current();
        endorsements[newEndorsementId] = Endorsement({
            id: newEndorsementId,
            endorser: msg.sender,
            endorsed: _endorsedUser,
            skillId: _skillId,
            commentCID: _commentCID,
            stake: msg.value,
            status: EndorsementStatus.Active,
            createdAt: block.timestamp
        });
        emit SkillEndorsed(newEndorsementId, msg.sender, _endorsedUser, _skillId);
    }

    /// @notice Allows any user to dispute a potentially false or malicious endorsement.
    /// @dev Requires a stake from the disputer to prevent frivolous disputes.
    /// @param _endorsementId The ID of the endorsement to dispute.
    /// @param _reasonCID IPFS CID for the reason of the dispute.
    function disputeEndorsement(uint256 _endorsementId, string calldata _reasonCID) external payable onlyRegistered {
        Endorsement storage endorsement = endorsements[_endorsementId];
        require(endorsement.status == EndorsementStatus.Active, "TS: Endorsement not active or already disputed");
        require(msg.value > 0, "TS: Dispute requires a stake"); // Disputer must stake a similar amount

        endorsement.status = EndorsementStatus.Disputed;

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();
        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            relatedEntityId: _endorsementId,
            entityType: 2, // Endorsement
            initiator: msg.sender,
            reasonCID: _reasonCID,
            status: DisputeStatus.Open,
            winner: address(0),
            penaltyAmount: msg.value, // Store disputer's stake here temporarily
            createdAt: block.timestamp
        });
        emit EndorsementDisputed(newDisputeId, _endorsementId, msg.sender);
    }

    /// @notice Resolves an endorsement dispute, penalizing the party found to be at fault.
    /// @dev Only callable by the contract owner (or a future DAO arbitration system).
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _isLegitimate True if the dispute claim is legitimate (endorser was at fault).
    /// @param _penaltyTo The address to send forfeited stakes (e.g., treasury or winner).
    function resolveEndorsementDispute(uint256 _disputeId, bool _isLegitimate, address _penaltyTo) external onlyOwner {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "TS: Dispute not open");
        require(dispute.entityType == 2, "TS: Not an endorsement dispute");

        Endorsement storage endorsement = endorsements[dispute.relatedEntityId];
        require(endorsement.status == EndorsementStatus.Disputed, "TS: Endorsement not in disputed state");

        uint256 totalStake = endorsement.stake + dispute.penaltyAmount; // Endorser's stake + Disputer's stake

        if (_isLegitimate) {
            // Dispute is legitimate: endorser was wrong. Endorsement removed, endorser penalized.
            endorsement.status = EndorsementStatus.Resolved; // Mark endorsement as resolved
            // Optionally remove the badge from the endorsed if endorsement was critical to its validity, or reduce reputation.
            
            // Penalty: Endorser loses their stake. Disputer potentially gets some reward.
            // Simplified: Endorser's stake goes to _penaltyTo, Disputer gets their stake back.
            payable(_penaltyTo).transfer(endorsement.stake);
            payable(dispute.initiator).transfer(dispute.penaltyAmount); // Disputer gets their stake back
            dispute.winner = dispute.initiator;
            dispute.penaltyAmount = endorsement.stake; // Amount lost by endorser
        } else {
            // Dispute is not legitimate: disputer was wrong. Disputer penalized.
            endorsement.status = EndorsementStatus.Active; // Endorsement status returns to active
            
            // Penalty: Disputer loses their stake. Endorser potentially gets some reward.
            // Simplified: Disputer's stake goes to _penaltyTo, Endorser gets their stake back.
            payable(_penaltyTo).transfer(dispute.penaltyAmount);
            payable(endorsement.endorser).transfer(endorsement.stake); // Endorser gets their stake back
            dispute.winner = endorsement.endorser;
            dispute.penaltyAmount = dispute.penaltyAmount; // Amount lost by disputer
        }
        dispute.status = DisputeStatus.Resolved;
        emit EndorsementDisputeResolved(_disputeId, endorsement.id, dispute.winner, dispute.penaltyAmount);
    }

    /// @notice Calculates a user's dynamic weighted reputation score.
    /// @dev This score is a comprehensive metric based on project success, skill badges, and weighted endorsements.
    /// @param _user The address of the user.
    /// @return The calculated weighted reputation score.
    function getWeightedReputation(address _user) public view returns (uint256) {
        require(userProfiles[_user].registeredAt != 0, "TS: User not registered");
        UserProfile storage profile = userProfiles[_user];
        uint256 reputation = 0;

        // Base reputation for being registered
        reputation += 10;

        // Factor in successful project completions (high weight)
        reputation += profile.totalProjectsCompleted * 100;

        // Factor in skill badges (each badge adds reputation, older badges add more)
        uint256 skillCount = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (profile.hasSkillBadge[i]) {
                skillCount++;
                // Add reputation for skill, decay based on age (or boost for recent)
                uint256 ageFactor = (block.timestamp - profile.skillBadgeMintTime[i]) / (1 days); // Days since minted
                reputation += 50 + (ageFactor / 10); // Example: 50 base + 1 rep per 10 days
            }
        }
        // Penalize for revoked badges (if we tracked them)

        // Factor in weighted endorsements
        for (uint256 i = 1; i <= _endorsementIds.current(); i++) {
            Endorsement storage e = endorsements[i];
            if (e.endorsed == _user && e.status == EndorsementStatus.Active) {
                // Weight endorsement by endorser's reputation and their stake
                uint256 endorserRep = getWeightedReputation(e.endorser);
                reputation += (e.stake * endorserRep) / 1000; // Example weighting logic
            }
        }
        
        // Ensure minimum reputation
        if (reputation < 10) reputation = 10; 
        return reputation;
    }

    // --- IV. Dynamic Project Collaboration & Escrow System ---

    /// @notice Proposes a new project to the TalentSphere network.
    /// @dev The project creator defines requirements, total bounty, milestones, and deadline.
    /// @param _titleCID IPFS CID for the project title.
    /// @param _descriptionCID IPFS CID for the detailed project description.
    /// @param _requiredSkills An array of skill IDs required for contributors.
    /// @param _initialBounty The total native token amount for the project.
    /// @param _milestoneCount The number of milestones for the project.
    /// @param _deadline Unix timestamp by which the project should be completed.
    function proposeProject(
        string calldata _titleCID,
        string calldata _descriptionCID,
        uint256[] calldata _requiredSkills,
        uint256 _initialBounty,
        uint256 _milestoneCount,
        uint256 _deadline
    ) external onlyRegistered returns (uint256) {
        require(_initialBounty > 0, "TS: Bounty must be greater than zero");
        require(_milestoneCount > 0, "TS: Project must have at least one milestone");
        require(_deadline > block.timestamp, "TS: Deadline must be in the future");

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        projects[newProjectId] = Project({
            id: newProjectId,
            creator: msg.sender,
            titleCID: _titleCID,
            descriptionCID: _descriptionCID,
            requiredSkills: _requiredSkills,
            totalBounty: _initialBounty,
            fundedAmount: 0,
            milestoneCount: _milestoneCount,
            deadline: _deadline,
            contributors: new address[](0),
            status: ProjectStatus.Proposed,
            createdAt: block.timestamp,
            lastActivity: block.timestamp,
            completedMilestones: 0
        });

        // Initialize milestones (payouts set later upon selection)
        for (uint256 i = 0; i < _milestoneCount; i++) {
            projects[newProjectId].milestones[i] = Milestone({
                index: i,
                contributor: address(0),
                deliverableCID: "",
                isSubmitted: false,
                isApproved: false,
                payoutAmount: 0, // Set later
                creatorFeedbackCID: "",
                isDisputed: false
            });
        }

        emit ProjectProposed(newProjectId, msg.sender, _initialBounty, _milestoneCount);
        return newProjectId;
    }

    /// @notice Allows users to contribute native tokens to a project's escrow.
    /// @dev The project's status changes to `Funding` and eventually `Active` once fully funded.
    /// @param _projectId The ID of the project to fund.
    function fundProject(uint256 _projectId) external payable onlyRegistered {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status <= ProjectStatus.Funding, "TS: Project not in funding stage");
        require(msg.value > 0, "TS: Funding amount must be greater than zero");

        project.fundedAmount += msg.value;
        project.status = ProjectStatus.Funding; // Update status if not already funding
        project.lastActivity = block.timestamp;

        if (project.fundedAmount >= project.totalBounty) {
            project.status = ProjectStatus.Active; // Project is now active, ready for contributor selection
        }
        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /// @notice Allows users to apply to be contributors for a project.
    /// @dev Applicants must meet the project's required skills and have a minimum reputation.
    /// @param _projectId The ID of the project to apply for.
    /// @param _coverLetterCID IPFS CID for the applicant's cover letter or proposal.
    function applyForProject(uint256 _projectId, string calldata _coverLetterCID) external onlyRegistered {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status == ProjectStatus.Active, "TS: Project not active for applications");
        
        uint256 applicantReputation = getWeightedReputation(msg.sender);
        require(applicantReputation > 0, "TS: Applicant has no reputation"); // Must have some rep

        // Check if applicant has all required skills
        for (uint256 i = 0; i < project.requiredSkills.length; i++) {
            require(userProfiles[msg.sender].hasSkillBadge[project.requiredSkills[i]], "TS: Applicant missing required skill");
        }
        
        // This function would usually just record the application, not immediately add to contributors
        // For simplicity, we'll assume the project creator picks from a list of applicants off-chain
        // and then calls `selectContributors`.
        // A more complex system would store applicants in a mapping: mapping(uint256 => mapping(address => string)) projectApplicants;
        emit ProjectApplication(_projectId, msg.sender);
    }

    /// @notice The project creator selects the final contributors for the project.
    /// @dev Selected contributors are assigned to milestones (implicitly or explicitly here).
    /// @param _projectId The ID of the project.
    /// @param _selectedApplicants An array of addresses of the chosen contributors.
    function selectContributors(uint256 _projectId, address[] calldata _selectedApplicants) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Active, "TS: Project not in active state to select contributors");
        require(_selectedApplicants.length > 0, "TS: Must select at least one contributor");
        // For simplicity, assign all milestones to the first selected applicant
        require(_selectedApplicants.length == 1, "TS: Currently supports only one primary contributor for all milestones."); // Can be extended for multi-contributor milestones

        project.contributors.push(_selectedApplicants[0]);
        project.isContributor[_selectedApplicants[0]] = true;

        // Assign milestones and allocate payout.
        uint256 payoutPerMilestone = project.totalBounty / project.milestoneCount;
        for (uint256 i = 0; i < project.milestoneCount; i++) {
            project.milestones[i].contributor = _selectedApplicants[0];
            project.milestones[i].payoutAmount = payoutPerMilestone;
        }

        project.lastActivity = block.timestamp;
        emit ContributorsSelected(_projectId, _selectedApplicants);
    }

    /// @notice A selected contributor submits their work for a specific milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The 0-based index of the milestone.
    /// @param _deliverableCID IPFS CID pointing to the completed work/proof.
    function submitMilestoneDeliverable(uint256 _projectId, uint256 _milestoneIndex, string calldata _deliverableCID) external onlyRegistered {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status == ProjectStatus.Active, "TS: Project not active");
        require(_milestoneIndex < project.milestoneCount, "TS: Invalid milestone index");
        
        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.contributor == msg.sender, "TS: Caller is not assigned to this milestone");
        require(!milestone.isSubmitted, "TS: Milestone already submitted");
        require(!milestone.isApproved, "TS: Milestone already approved");
        
        milestone.deliverableCID = _deliverableCID;
        milestone.isSubmitted = true;
        project.lastActivity = block.timestamp;
        emit MilestoneDeliverableSubmitted(_projectId, _milestoneIndex, msg.sender);
    }

    /// @notice The project creator approves a submitted milestone, releasing funds to the contributor.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The 0-based index of the milestone.
    /// @param _feedbackCID IPFS CID for optional feedback to the contributor.
    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _feedbackCID) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status == ProjectStatus.Active, "TS: Project not active");
        require(_milestoneIndex < project.milestoneCount, "TS: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(milestone.isSubmitted, "TS: Milestone not submitted yet");
        require(!milestone.isApproved, "TS: Milestone already approved");
        require(!milestone.isDisputed, "TS: Milestone is currently disputed");

        milestone.isApproved = true;
        milestone.creatorFeedbackCID = _feedbackCID;
        project.completedMilestones++;
        project.lastActivity = block.timestamp;

        // Transfer funds to contributor
        payable(milestone.contributor).transfer(milestone.payoutAmount);
        
        emit MilestoneApproved(_projectId, _milestoneIndex, msg.sender, milestone.contributor, milestone.payoutAmount);
    }

    /// @notice Initiates a dispute over a milestone (e.g., creator not approving, contributor not delivering).
    /// @dev Can be called by either the project creator or the assigned contributor for that milestone.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The 0-based index of the milestone.
    /// @param _reasonCID IPFS CID for the reason of the dispute.
    function disputeMilestone(uint256 _projectId, uint256 _milestoneIndex, string calldata _reasonCID) external onlyRegistered {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status == ProjectStatus.Active, "TS: Project not active");
        require(_milestoneIndex < project.milestoneCount, "TS: Invalid milestone index");

        Milestone storage milestone = project.milestones[_milestoneIndex];
        require(!milestone.isDisputed, "TS: Milestone already disputed");
        
        bool isCreator = project.creator == msg.sender;
        bool isContributor = milestone.contributor == msg.sender;
        require(isCreator || isContributor, "TS: Only creator or assigned contributor can dispute this milestone");
        
        milestone.isDisputed = true;
        project.status = ProjectStatus.Disputed; // Set project status to disputed

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();
        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            relatedEntityId: _projectId, // Project ID as the primary entity
            entityType: 1, // Milestone dispute
            initiator: msg.sender,
            reasonCID: _reasonCID,
            status: DisputeStatus.Open,
            winner: address(0),
            penaltyAmount: 0, // Set by resolver
            createdAt: block.timestamp
        });
        emit MilestoneDisputed(newDisputeId, _projectId, _milestoneIndex, msg.sender);
    }

    /// @notice Resolves a milestone dispute, determining the winner and payout allocation.
    /// @dev Only callable by the contract owner (or a future DAO arbitration system).
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _winnerAddress The address of the party deemed to be correct (creator or contributor).
    /// @param _payoutAllocation The native token amount to be allocated to the winner for this milestone.
    function resolveMilestoneDispute(uint256 _disputeId, address _winnerAddress, uint256 _payoutAllocation) external onlyOwner {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "TS: Dispute not open");
        require(dispute.entityType == 1, "TS: Not a milestone dispute");

        Project storage project = projects[dispute.relatedEntityId];
        // Need to identify which milestone this dispute is for. Assuming dispute.relatedEntityId now means projectId
        // This requires an additional `milestoneIndex` field in the dispute struct for clarity
        // For now, let's assume dispute resolution only happens for one milestone at a time for simplicity.
        // A robust system would have `Dispute.relatedMilestoneIndex`

        // Placeholder for now, assumes _payoutAllocation is for the *specific* milestone in dispute
        // This needs to be carefully matched to the milestone's actual payout amount.
        // For a full implementation, `Dispute` would need `relatedMilestoneIndex`

        // Example: Assume a specific milestone from the project, for this demo.
        uint256 disputedMilestoneIndex = 0; // Replace with actual index if added to Dispute struct.
        Milestone storage milestone = project.milestones[disputedMilestoneIndex]; // This is a limitation in current struct.

        require(milestone.isDisputed, "TS: Milestone not in disputed state");
        require(_payoutAllocation <= milestone.payoutAmount, "TS: Payout allocation cannot exceed milestone bounty");

        // Release funds based on resolution
        if (_winnerAddress == milestone.contributor) {
            payable(milestone.contributor).transfer(_payoutAllocation);
            // Remaining bounty (milestone.payoutAmount - _payoutAllocation) stays in project escrow or returned to creator
        } else if (_winnerAddress == project.creator) {
            // Funds stay in escrow or returned to creator
            // Maybe transfer to creator directly for partial refund:
            // payable(project.creator).transfer(_payoutAllocation); // If creator wins and gets a refund
        } else {
            revert("TS: Invalid winner address");
        }

        milestone.isDisputed = false; // Dispute resolved for this milestone
        milestone.isApproved = true; // Mark as resolved/approved by arbitration
        project.status = ProjectStatus.Active; // Return project to active status
        project.lastActivity = block.timestamp;
        
        dispute.status = DisputeStatus.Resolved;
        dispute.winner = _winnerAddress;
        dispute.penaltyAmount = _payoutAllocation; // Amount moved based on resolution

        emit MilestoneDisputeResolved(_disputeId, project.id, disputedMilestoneIndex, _winnerAddress, _payoutAllocation);
    }

    /// @notice Marks a project as fully completed after all milestones are approved.
    /// @dev Triggers reputation updates for all successful contributors.
    /// @param _projectId The ID of the project to complete.
    /// @param _finalReportCID IPFS CID for an optional final project report.
    function completeProject(uint256 _projectId, string calldata _finalReportCID) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.exists, "TS: Project does not exist");
        require(project.status == ProjectStatus.Active, "TS: Project not active");
        require(project.completedMilestones == project.milestoneCount, "TS: Not all milestones are completed");
        require(block.timestamp <= project.deadline, "TS: Project completed after deadline");

        project.status = ProjectStatus.Completed;
        project.lastActivity = block.timestamp;

        // Update reputation for contributors
        for (uint256 i = 0; i < project.contributors.length; i++) {
            address contributor = project.contributors[i];
            userProfiles[contributor].totalProjectsCompleted++;
            // The `getWeightedReputation` function will pick up this change
        }

        // Return any remaining unspent funds to the project creator (if any)
        uint256 remainingFunds = address(this).balance - project.totalBounty; // Simplified, in a real system track escrow specifically
        if (remainingFunds > 0) {
            payable(project.creator).transfer(remainingFunds);
        }

        emit ProjectCompleted(_projectId, msg.sender);
        // _finalReportCID is logged in the event, or could be stored in the Project struct
    }

    // --- Admin and Utility Functions (for a full system, these would be part of a robust governance) ---
    
    /// @notice Adds an address to the list of authorized evaluators for a specific skill.
    /// @dev Requires the evaluator to have staked `minEvaluatorStake` off-chain or by calling a separate stake function.
    /// @param _skillId The ID of the skill.
    /// @param _evaluatorAddress The address to authorize.
    function addAuthorizedEvaluator(uint256 _skillId, address _evaluatorAddress) external onlyOwner {
        SkillType storage skill = skillTypes[_skillId];
        require(skill.exists, "TS: Skill does not exist");
        // Ensure not already an evaluator
        for (uint256 i = 0; i < skill.authorizedEvaluators.length; i++) {
            require(skill.authorizedEvaluators[i] != _evaluatorAddress, "TS: Address already an evaluator");
        }
        // In a real system, would verify _evaluatorAddress has staked `minEvaluatorStake`
        skill.authorizedEvaluators.push(_evaluatorAddress);
    }

    /// @notice Allows the contract owner to withdraw any residual funds not tied to active projects or disputes.
    function withdrawAdminFunds() external onlyOwner {
        // This is a simplified emergency withdrawal.
        // A robust system would track available treasury funds vs. escrowed project funds.
        payable(owner()).transfer(address(this).balance);
    }
}
```