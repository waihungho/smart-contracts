The smart contract `KnowledgeVault_Adeptus` is a decentralized platform designed for skill acquisition, validation, and collaborative knowledge creation. It introduces "Adept Certificates" as Soul-Bound Tokens (SBTs) to represent mastered skills, integrating them into a dynamic learning ecosystem with hierarchical skill trees, peer-verified challenges, and a reputation system based on educational contributions.

This contract aims for originality by combining several advanced concepts:
*   **Skill-Bound Tokens (SBTs):** Adept Certificates are non-transferable NFTs tied to specific skills, acting as verifiable proof of mastery. Their issuance is tightly integrated with the platform's challenge and verification mechanisms.
*   **Hierarchical Skill Graph:** Skills can have explicit prerequisites, allowing for structured learning paths and skill progression.
*   **Dynamic Learning Paths:** Users can define, track, and get suggestions for personalized learning sequences based on their acquired skills.
*   **Multi-Party Challenge Verification:** A unique system where challenge creators propose multiple verifiers, and a quorum of these verifiers must approve solutions before certificates and rewards are issued.
*   **Reputation System:** Users earn reputation for mastering skills and actively participating in the challenge verification process.
*   **On-chain Resource Indexing:** Direct linking of decentralized learning content (e.g., IPFS hashes) to specific skill nodes.

---

### Outline and Function Summary

**I. Core Skill Management & Adept Certificates (SBTs)**
1.  **`SkillNode` struct:** Defines a skill with metadata, prerequisites, difficulty, and a designated moderator.
2.  **`AdeptCertificate` struct:** Represents a skill mastery certificate, explicitly non-transferable, including issue details and verification hash.
3.  **`adminRegisterSkillNode(string calldata _name, string calldata _description, uint256[] calldata _prerequisites, uint8 _difficulty)`:** Registers a new foundational skill node in the system. Only callable by the platform owner.
4.  **`getSkillNodeDetails(uint256 _skillId)`:** Retrieves comprehensive details about a specific skill node.
5.  **`hasAdeptCertificate(address _user, uint256 _skillId)`:** Checks if a given user possesses a specific Adept Certificate for a `_skillId`.
6.  **`_issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash, address _issuer)`:** Internal function used to mint a new Adept Certificate for a user upon successful skill mastery verification (e.g., challenge completion). Handles prerequisites and reputation update.
7.  **`issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash)`:** External function allowing the platform owner to manually issue an Adept Certificate (primarily for administrative or fallback purposes).
8.  **`revokeAdeptCertificate(address _user, uint256 _skillId, string calldata _reason)`:** Revokes an Adept Certificate from a user (e.g., due to fraudulent acquisition). Callable by the platform owner.
9.  **`getUserAdeptCertificates(address _user)`:** Returns an array of all skill IDs for which a user currently holds Adept Certificates.
10. **`isPrerequisiteMet(address _user, uint256 _skillId)`:** Verifies if a user holds all the necessary Adept Certificates that are prerequisites for a given `_skillId`.

**II. Dynamic Learning Paths & Recommendations**
11. **`proposeLearningPath(address _forUser, uint256[] calldata _skillPath)`:** Allows any user or an external recommender system to propose a personalized sequence of skills as a learning path for a specific user.
12. **`approveLearningPath(uint256[] calldata _skillPath)`:** A user explicitly accepts a proposed learning path, setting it as their active, tracked path.
13. **`getCurrentLearningPath(address _user)`:** Retrieves the active learning path (sequence of skill IDs) currently set for a user.
14. **`getCurrentLearningPathProgress(address _user)`:** Returns the number of skills completed and the total number of skills in a user's active learning path.
15. **`markSkillAsStarted(uint256 _skillId)`:** Allows a user to mark a specific skill within their active learning path as 'started', indicating engagement.
16. **`suggestNextSkill(address _user)`:** Provides a basic on-chain suggestion for the next skill a user could pursue, based on their active path and currently met prerequisites.

**III. Decentralized Challenges & Verification**
17. **`Challenge` struct:** Defines a skill challenge with details like creator, deadline, reward, status, and the multi-party verification mechanism.
18. **`createChallenge(uint256 _skillId, string calldata _description, uint64 _deadline, uint256 _rewardAmount, address[] calldata _proposedVerifiers)`:** Creates a new skill-specific challenge. The challenge creator funds the reward amount in native currency (ETH). Requires initial proposed verifiers.
19. **`submitChallengeSolution(uint256 _challengeId, string calldata _solutionHash)`:** A participant submits a solution hash (e.g., IPFS hash of project files) for a challenge.
20. **`proposeChallengeVerifier(uint256 _challengeId, address _verifier)`:** Allows the challenge creator to add additional verifiers to their challenge after creation.
21. **`approveAsVerifier(uint256 _challengeId)`:** A proposed verifier explicitly accepts their role to verify solutions for a given challenge.
22. **`verifyChallengeSolution(uint256 _challengeId, address _participant, bool _isAccepted)`:** A designated verifier casts their vote (accept/reject) on a specific participant's solution. Triggers reputation gain for the verifier.
23. **`getChallengeStatus(uint256 _challengeId)`:** Provides the current status and key metrics of a challenge, including verification progress.
24. **`finalizeChallenge(uint256 _challengeId)`:** Finalizes a challenge once the deadline has passed and verifications have occurred. It issues Adept Certificates to successful participants, distributes rewards, and collects platform fees.

**IV. Reputation & Moderation**
25. **`getUserReputation(address _user)`:** Retrieves the reputation score of a specific user.
26. **`_increaseReputation(address _user, int256 _amount)`:** Internal function to update a user's reputation score. Reputation increases with skill mastery and successful verification, and decreases with certificate revocation.
27. **`setSkillNodeModerator(uint256 _skillId, address _moderator)`:** Assigns a moderator to a specific skill node. This moderator can have privileges like curating resources or approving verifiers for challenges related to that skill (though not fully implemented in this example, it's a structural placeholder).

**V. Content & Resource Linking**
28. **`linkResourceToSkill(uint256 _skillId, string calldata _resourceURI, string calldata _description)`:** Associates an external resource URI (e.g., IPFS link to learning material) with a skill node. Allows for decentralized content curation.
29. **`getSkillResources(uint256 _skillId)`:** Retrieves all linked external resources for a specific skill node.

**VI. Platform Management**
30. **`setPlatformFee(uint256 _feePercentage)`:** Sets the percentage of challenge rewards that are collected as platform fees. Callable only by the platform owner.
31. **`withdrawPlatformFunds()`:** Allows the platform owner to withdraw accumulated fees from the contract.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title KnowledgeVault_Adeptus
 * @dev A decentralized platform for skill acquisition, validation, and collaborative knowledge creation.
 *      It issues "Adept Certificates" as Soul-Bound Tokens (SBTs) representing mastered skills,
 *      and allows for dynamic learning paths, peer-verified challenges, and reputation-based interactions.
 *      This contract aims for originality by integrating hierarchical skill trees,
 *      multi-party challenge verification, dynamic learning path tracking, and
 *      reputation tied to educational contributions, all in a non-transferable token ecosystem.
 */
contract KnowledgeVault_Adeptus is Ownable {
    using Counters for Counters.Counter;

    // --- Outline and Function Summary ---
    // I. Core Skill Management & Adept Certificates (SBTs)
    //    1.  `SkillNode` struct: Defines a skill with metadata and prerequisites.
    //    2.  `AdeptCertificate` struct: Represents a skill mastery certificate, non-transferable.
    //    3.  `adminRegisterSkillNode(string calldata _name, string calldata _description, uint256[] calldata _prerequisites, uint8 _difficulty)`:
    //        Registers a new skill node in the system. Only callable by platform admin.
    //    4.  `getSkillNodeDetails(uint256 _skillId)`: Retrieves comprehensive details about a specific skill node.
    //    5.  `hasAdeptCertificate(address _user, uint256 _skillId)`: Checks if a user possesses a specific Adept Certificate.
    //    6.  `_issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash, address _issuer)`:
    //        Internal function to mint a new Adept Certificate upon successful skill mastery verification.
    //    7.  `issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash)`:
    //        Mints a new Adept Certificate for a user (manual admin issuance).
    //    8.  `revokeAdeptCertificate(address _user, uint256 _skillId, string calldata _reason)`:
    //        Revokes an Adept Certificate from a user (e.g., due to fraud). Callable by admin/governance.
    //    9.  `getUserAdeptCertificates(address _user)`: Returns a list of all skill IDs for which a user holds Adept Certificates.
    //    10. `isPrerequisiteMet(address _user, uint256 _skillId)`:
    //        Checks if a user has all the required Adept Certificates for a given skill's prerequisites.

    // II. Dynamic Learning Paths & Recommendations
    //    11. `proposeLearningPath(address _forUser, uint256[] calldata _skillPath)`:
    //        Allows a user (or potentially a recommended system off-chain) to propose a learning sequence.
    //    12. `approveLearningPath(uint256[] calldata _skillPath)`:
    //        A user explicitly approves a proposed learning path, setting it as their active path.
    //    13. `getCurrentLearningPath(address _user)`: Retrieves the currently active learning path for a user.
    //    14. `getCurrentLearningPathProgress(address _user)`:
    //        Returns the number of skills completed and total skills in a user's active learning path.
    //    15. `markSkillAsStarted(uint256 _skillId)`:
    //        Allows a user to mark a skill in their active learning path as 'started'.
    //    16. `suggestNextSkill(address _user)`:
    //        Suggests the next skill a user could pursue based on their current certificates and potential skill graph traversal.

    // III. Decentralized Challenges & Verification
    //    17. `Challenge` struct: Defines a skill challenge structure.
    //    18. `createChallenge(uint256 _skillId, string calldata _description, uint64 _deadline, uint256 _rewardAmount, address[] calldata _proposedVerifiers)`:
    //        Creates a new skill-specific challenge, funded by the creator.
    //    19. `submitChallengeSolution(uint256 _challengeId, string calldata _solutionHash)`:
    //        A participant submits a solution hash for a challenge.
    //    20. `proposeChallengeVerifier(uint256 _challengeId, address _verifier)`:
    //        Challenge creator can propose additional verifiers for their challenge.
    //    21. `approveAsVerifier(uint256 _challengeId)`:
    //        A proposed verifier accepts their role for a challenge.
    //    22. `verifyChallengeSolution(uint256 _challengeId, address _participant, bool _isAccepted)`:
    //        A designated verifier casts their vote on a participant's solution.
    //    23. `getChallengeStatus(uint256 _challengeId)`:
    //        Retrieves the current status of a challenge, including verification progress.
    //    24. `finalizeChallenge(uint256 _challengeId)`:
    //        Finalizes a challenge once sufficient verifications are in. Issues AdeptCertificates and distributes rewards.

    // IV. Reputation & Moderation
    //    25. `getUserReputation(address _user)`: Retrieves a user's reputation score.
    //    26. `_increaseReputation(address _user, int256 _amount)`: Internal function to update reputation based on actions.
    //    27. `setSkillNodeModerator(uint256 _skillId, address _moderator)`:
    //        Assigns a moderator to a specific skill node.

    // V. Content & Resource Linking
    //    28. `linkResourceToSkill(uint256 _skillId, string calldata _resourceURI, string calldata _description)`:
    //        Associates an external resource (e.g., IPFS hash) with a skill node.
    //    29. `getSkillResources(uint256 _skillId)`: Retrieves all linked resources for a skill.

    // VI. Platform Management
    //    30. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage on challenge rewards.
    //    31. `withdrawPlatformFunds()`: Allows the platform owner to withdraw accumulated fees.

    // --- State Variables ---

    Counters.Counter private _skillIds;
    Counters.Counter private _challengeIds;

    // I. Skill Management & Adept Certificates (SBTs)
    struct SkillNode {
        uint256 id;
        string name;
        string description;
        uint256[] prerequisites; // IDs of skills required before this one
        uint8 difficulty; // 1-10
        address moderator; // Can curate resources, propose verifiers for challenges related to this skill
        bool exists; // To check if skillId is valid
    }

    struct AdeptCertificate {
        uint256 skillId;
        uint64 issueDate;
        address issuer; // The address that initiated the issuance (e.g., finalizer of challenge, admin)
        string verificationHash; // Hash of evidence or assessment for verification
    }

    // Maps skillId to SkillNode details
    mapping(uint256 => SkillNode) public skillNodes;
    // Maps user address to skillId to AdeptCertificate details (SBTs)
    mapping(address => mapping(uint256 => AdeptCertificate)) private userAdeptCertificates;
    // Tracks all skill IDs for a user to allow easy enumeration
    mapping(address => uint256[]) private userCertificateList;

    // II. Dynamic Learning Paths & Recommendations
    // Maps user address to their active learning path (array of skill IDs)
    mapping(address => uint256[]) public activeLearningPaths;
    // Maps user address to skill ID to boolean indicating if skill is started on current path
    mapping(address => mapping(uint256 => bool)) public skillStartedInPath;

    // III. Decentralized Challenges & Verification
    enum ChallengeStatus {
        Open,
        SubmissionsClosed,
        Verifying,
        Completed,
        Cancelled
    }

    struct Challenge {
        uint256 id;
        uint256 skillId;
        address creator;
        string description;
        uint64 deadline;
        uint256 rewardAmount; // In native token (wei)
        ChallengeStatus status;
        address[] verifiers; // Approved verifiers for this challenge
        uint256 minVerificationsRequired; // Number of verifier approvals needed
        mapping(address => string) solutions; // Participant address => solution hash
        mapping(address => mapping(address => bool)) verifierVotes; // Verifier => Participant => Accepted/Rejected
        mapping(address => uint256) solutionAcceptCount; // Participant => Number of accepted votes
        address[] participants; // List of all participants in this challenge
    }

    mapping(uint256 => Challenge) public challenges;
    // Maps challengeId => Verifier => bool (if they accepted their role)
    mapping(uint256 => mapping(address => bool)) public verifierAcceptedRoles;


    // IV. Reputation & Moderation
    mapping(address => uint256) public userReputation;

    // V. Content & Resource Linking
    struct SkillResource {
        string uri; // e.g., IPFS hash, URL
        string description;
        address contributor;
        uint64 timestamp;
    }
    mapping(uint256 => SkillResource[]) public skillResources;

    // VI. Platform Management
    uint256 public platformFeePercentage; // e.g., 500 for 5% (500/10000)
    uint256 public totalPlatformFeesCollected;

    // --- Events ---
    event SkillNodeRegistered(uint256 indexed skillId, string name, address indexed creator);
    event AdeptCertificateIssued(address indexed user, uint256 indexed skillId, uint64 issueDate, string verificationHash);
    event AdeptCertificateRevoked(address indexed user, uint256 indexed skillId, string reason);
    event LearningPathProposed(address indexed forUser, uint256[] skillPath);
    event LearningPathApproved(address indexed user, uint256[] skillPath);
    event SkillStartedInPath(address indexed user, uint256 indexed skillId);
    event ChallengeCreated(uint256 indexed challengeId, uint256 indexed skillId, address indexed creator, uint256 rewardAmount, uint64 deadline);
    event SolutionSubmitted(uint256 indexed challengeId, address indexed participant, string solutionHash);
    event VerifierRoleAccepted(uint256 indexed challengeId, address indexed verifier);
    event SolutionVerified(uint256 indexed challengeId, address indexed verifier, address indexed participant, bool accepted);
    event ChallengeFinalized(uint256 indexed challengeId, ChallengeStatus status);
    event UserReputationIncreased(address indexed user, uint256 newReputation);
    event SkillNodeModeratorSet(uint256 indexed skillId, address indexed moderator);
    event SkillResourceLinked(uint256 indexed skillId, string uri, address indexed contributor);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyPlatformAdmin() {
        require(owner() == msg.sender, "KnowledgeVault: Only platform owner can call this function");
        _;
    }

    modifier onlySkillNodeModerator(uint256 _skillId) {
        require(skillNodes[_skillId].moderator == msg.sender, "KnowledgeVault: Only skill node moderator can call this function");
        _;
    }

    modifier onlyChallengeCreator(uint256 _challengeId) {
        require(challenges[_challengeId].creator == msg.sender, "KnowledgeVault: Only challenge creator can call this function");
        _;
    }

    modifier onlyVerifier(uint256 _challengeId) {
        bool isVerifier = false;
        for (uint256 i = 0; i < challenges[_challengeId].verifiers.length; i++) {
            if (challenges[_challengeId].verifiers[i] == msg.sender) {
                isVerifier = true;
                break;
            }
        }
        require(isVerifier, "KnowledgeVault: Caller is not a verifier for this challenge");
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialFeePercentage) Ownable(msg.sender) {
        require(_initialFeePercentage <= 10000, "KnowledgeVault: Fee percentage cannot exceed 10000 (100%)");
        platformFeePercentage = _initialFeePercentage; // e.g., 500 for 5%
    }

    // --- I. Core Skill Management & Adept Certificates (SBTs) ---

    function adminRegisterSkillNode(
        string calldata _name,
        string calldata _description,
        uint256[] calldata _prerequisites,
        uint8 _difficulty
    ) external onlyPlatformAdmin returns (uint256) {
        require(_difficulty > 0 && _difficulty <= 10, "KnowledgeVault: Difficulty must be between 1 and 10");
        for (uint256 i = 0; i < _prerequisites.length; i++) {
            require(skillNodes[_prerequisites[i]].exists, "KnowledgeVault: Prerequisite skill does not exist");
        }

        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();

        skillNodes[newSkillId] = SkillNode({
            id: newSkillId,
            name: _name,
            description: _description,
            prerequisites: _prerequisites,
            difficulty: _difficulty,
            moderator: address(0), // No moderator by default
            exists: true
        });

        emit SkillNodeRegistered(newSkillId, _name, msg.sender);
        return newSkillId;
    }

    function getSkillNodeDetails(uint256 _skillId) external view returns (
        uint256 id,
        string memory name,
        string memory description,
        uint256[] memory prerequisites,
        uint8 difficulty,
        address moderator
    ) {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        SkillNode storage skill = skillNodes[_skillId];
        return (skill.id, skill.name, skill.description, skill.prerequisites, skill.difficulty, skill.moderator);
    }

    function hasAdeptCertificate(address _user, uint256 _skillId) public view returns (bool) {
        return userAdeptCertificates[_user][_skillId].skillId != 0; // skillId 0 implies not set/issued
    }

    // Internal function for issuing certificates
    function _issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash, address _issuer) internal {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        require(!hasAdeptCertificate(_to, _skillId), "KnowledgeVault: User already has this certificate");
        require(isPrerequisiteMet(_to, _skillId), "KnowledgeVault: Prerequisites for this skill are not met");

        userAdeptCertificates[_to][_skillId] = AdeptCertificate({
            skillId: _skillId,
            issueDate: uint64(block.timestamp),
            issuer: _issuer,
            verificationHash: _verificationHash
        });
        userCertificateList[_to].push(_skillId); // Add to list for enumeration

        _increaseReputation(_to, 10 * skillNodes[_skillId].difficulty); // Increase reputation for mastering a skill
        emit AdeptCertificateIssued(_to, _skillId, uint64(block.timestamp), _verificationHash);
    }

    function issueAdeptCertificate(address _to, uint256 _skillId, string calldata _verificationHash) external onlyPlatformAdmin {
        // This function is primarily for admin to manually issue or for a fallback.
        // Normal issuance should happen via challenge finalization.
        _issueAdeptCertificate(_to, _skillId, _verificationHash, msg.sender);
    }

    function revokeAdeptCertificate(address _user, uint256 _skillId, string calldata _reason) external onlyPlatformAdmin {
        require(hasAdeptCertificate(_user, _skillId), "KnowledgeVault: User does not have this certificate");

        // Set skillId to 0 to invalidate the certificate
        userAdeptCertificates[_user][_skillId].skillId = 0;

        // Remove from userCertificateList - potentially gas intensive for long lists
        uint256[] storage certificates = userCertificateList[_user];
        for (uint256 i = 0; i < certificates.length; i++) {
            if (certificates[i] == _skillId) {
                certificates[i] = certificates[certificates.length - 1]; // Move last element to current position
                certificates.pop(); // Remove last element
                break;
            }
        }

        _increaseReputation(_user, -5 * skillNodes[_skillId].difficulty); // Decrease reputation for revocation
        emit AdeptCertificateRevoked(_user, _skillId, _reason);
    }

    function getUserAdeptCertificates(address _user) external view returns (uint256[] memory) {
        return userCertificateList[_user];
    }

    function isPrerequisiteMet(address _user, uint256 _skillId) public view returns (bool) {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        uint256[] storage prerequisites = skillNodes[_skillId].prerequisites;
        for (uint256 i = 0; i < prerequisites.length; i++) {
            if (!hasAdeptCertificate(_user, prerequisites[i])) {
                return false;
            }
        }
        return true;
    }

    // --- II. Dynamic Learning Paths & Recommendations ---

    function proposeLearningPath(address _forUser, uint256[] calldata _skillPath) external {
        // Anyone can propose a path, _forUser can be msg.sender for self-proposal
        // In a real system, an AI might propose it off-chain and then call this function
        require(_skillPath.length > 0, "KnowledgeVault: Learning path cannot be empty");
        for (uint256 i = 0; i < _skillPath.length; i++) {
            require(skillNodes[_skillPath[i]].exists, "KnowledgeVault: Skill in path does not exist");
        }
        // This function only emits an event. The user must call `approveLearningPath` to activate it.
        emit LearningPathProposed(_forUser, _skillPath);
    }

    function approveLearningPath(uint256[] calldata _skillPath) external {
        // A user explicitly approves a path, making it active.
        require(_skillPath.length > 0, "KnowledgeVault: Learning path cannot be empty");
        for (uint256 i = 0; i < _skillPath.length; i++) {
            require(skillNodes[_skillPath[i]].exists, "KnowledgeVault: Skill in path does not exist");
            // Reset skill started status for the new path
            skillStartedInPath[msg.sender][_skillPath[i]] = false; // Reset status for new path
        }
        activeLearningPaths[msg.sender] = _skillPath;
        emit LearningPathApproved(msg.sender, _skillPath);
    }

    function getCurrentLearningPath(address _user) external view returns (uint256[] memory) {
        return activeLearningPaths[_user];
    }

    function getCurrentLearningPathProgress(address _user) external view returns (uint256 completedSkills, uint256 totalSkills) {
        uint256[] memory path = activeLearningPaths[_user];
        totalSkills = path.length;
        if (totalSkills == 0) return (0, 0);

        completedSkills = 0;
        for (uint256 i = 0; i < totalSkills; i++) {
            if (hasAdeptCertificate(_user, path[i])) {
                completedSkills++;
            }
        }
        return (completedSkills, totalSkills);
    }

    function markSkillAsStarted(uint256 _skillId) external {
        uint256[] memory path = activeLearningPaths[msg.sender];
        bool isInPath = false;
        for (uint256 i = 0; i < path.length; i++) {
            if (path[i] == _skillId) {
                isInPath = true;
                break;
            }
        }
        require(isInPath, "KnowledgeVault: Skill not in active learning path");
        require(!skillStartedInPath[msg.sender][_skillId], "KnowledgeVault: Skill already marked as started");
        skillStartedInPath[msg.sender][_skillId] = true;
        emit SkillStartedInPath(msg.sender, _skillId);
    }

    function suggestNextSkill(address _user) external view returns (uint256 suggestedSkillId) {
        uint256[] memory path = activeLearningPaths[_user];
        if (path.length == 0) return 0; // No active path

        for (uint256 i = 0; i < path.length; i++) {
            uint256 currentSkillId = path[i];
            if (!hasAdeptCertificate(_user, currentSkillId)) {
                // Check if prerequisites are met for this skill in the path
                if (isPrerequisiteMet(_user, currentSkillId)) {
                    return currentSkillId; // Suggest the first uncompleted skill whose prerequisites are met
                }
            }
        }
        return 0; // No further skills in the path meet prerequisites or all completed
    }


    // --- III. Decentralized Challenges & Verification ---

    function createChallenge(
        uint256 _skillId,
        string calldata _description,
        uint64 _deadline,
        uint256 _rewardAmount,
        address[] calldata _proposedVerifiers
    ) external payable returns (uint256) {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill does not exist");
        require(_deadline > block.timestamp, "KnowledgeVault: Deadline must be in the future");
        require(_rewardAmount > 0, "KnowledgeVault: Reward must be greater than zero");
        require(msg.value == _rewardAmount, "KnowledgeVault: Insufficient ether sent for reward");
        require(_proposedVerifiers.length > 0, "KnowledgeVault: At least one verifier must be proposed");

        for (uint256 i = 0; i < _proposedVerifiers.length; i++) {
            require(_proposedVerifiers[i] != address(0), "KnowledgeVault: Verifier cannot be zero address");
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        Challenge storage newChallenge = challenges[newChallengeId];
        newChallenge.id = newChallengeId;
        newChallenge.skillId = _skillId;
        newChallenge.creator = msg.sender;
        newChallenge.description = _description;
        newChallenge.deadline = _deadline;
        newChallenge.rewardAmount = _rewardAmount;
        newChallenge.status = ChallengeStatus.Open;
        newChallenge.verifiers = _proposedVerifiers;
        newChallenge.minVerificationsRequired = (_proposedVerifiers.length / 2) + 1; // Simple majority

        emit ChallengeCreated(newChallengeId, _skillId, msg.sender, _rewardAmount, _deadline);
        return newChallengeId;
    }

    function submitChallengeSolution(uint256 _challengeId, string calldata _solutionHash) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open, "KnowledgeVault: Challenge is not open for submissions");
        require(block.timestamp <= challenge.deadline, "KnowledgeVault: Submission deadline has passed");
        require(bytes(challenge.solutions[msg.sender]).length == 0, "KnowledgeVault: You have already submitted a solution");

        challenge.solutions[msg.sender] = _solutionHash;
        // Add participant if not already in list
        bool alreadyParticipant = false;
        for(uint256 i=0; i < challenge.participants.length; i++){
            if(challenge.participants[i] == msg.sender){
                alreadyParticipant = true;
                break;
            }
        }
        if(!alreadyParticipant){
            challenge.participants.push(msg.sender);
        }

        emit SolutionSubmitted(_challengeId, msg.sender, _solutionHash);
    }

    function proposeChallengeVerifier(uint256 _challengeId, address _verifier) external onlyChallengeCreator(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open, "KnowledgeVault: Challenge is not open");
        require(_verifier != address(0), "KnowledgeVault: Verifier cannot be zero address");

        // Check if already a verifier
        bool alreadyVerifier = false;
        for (uint256 i = 0; i < challenge.verifiers.length; i++) {
            if (challenge.verifiers[i] == _verifier) {
                alreadyVerifier = true;
                break;
            }
        }
        require(!alreadyVerifier, "KnowledgeVault: Address is already a verifier for this challenge");

        challenge.verifiers.push(_verifier);
        // Recalculate minimum verifications, in case more verifiers are added.
        // This makes it dynamic, but could also make it harder to reach quorum if many decline.
        // Alternative: minVerificationsRequired fixed at creation or only modifiable by admin.
        challenge.minVerificationsRequired = (challenge.verifiers.length / 2) + 1;
    }

    function approveAsVerifier(uint256 _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open || challenge.status == ChallengeStatus.SubmissionsClosed, "KnowledgeVault: Challenge not in a state for verifier approval");

        bool isProposedVerifier = false;
        for (uint256 i = 0; i < challenge.verifiers.length; i++) {
            if (challenge.verifiers[i] == msg.sender) {
                isProposedVerifier = true;
                break;
            }
        }
        require(isProposedVerifier, "KnowledgeVault: You are not a proposed verifier for this challenge");
        require(!verifierAcceptedRoles[_challengeId][msg.sender], "KnowledgeVault: You have already accepted this role");

        verifierAcceptedRoles[_challengeId][msg.sender] = true;
        emit VerifierRoleAccepted(_challengeId, msg.sender);
    }

    function verifyChallengeSolution(uint256 _challengeId, address _participant, bool _isAccepted) external onlyVerifier(_challengeId) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Open || challenge.status == ChallengeStatus.SubmissionsClosed || challenge.status == ChallengeStatus.Verifying, "KnowledgeVault: Challenge is not in a verifiable state");
        require(block.timestamp > challenge.deadline, "KnowledgeVault: Submissions are still open, cannot verify yet"); // Only verify after deadline
        require(bytes(challenge.solutions[_participant]).length > 0, "KnowledgeVault: Participant has not submitted a solution");
        require(verifierAcceptedRoles[_challengeId][msg.sender], "KnowledgeVault: You must approve your verifier role first");
        require(!challenge.verifierVotes[msg.sender][_participant], "KnowledgeVault: You have already voted for this participant's solution");

        if (challenge.status == ChallengeStatus.Open) {
            challenge.status = ChallengeStatus.SubmissionsClosed; // Automatically close submissions if not already
        }
        if (challenge.status == ChallengeStatus.SubmissionsClosed) {
            challenge.status = ChallengeStatus.Verifying; // Transition to verifying
        }

        // Mark that this verifier has voted for this participant's solution
        // Using bool `true` to indicate a vote was cast. The _isAccepted determines the count.
        challenge.verifierVotes[msg.sender][_participant] = true; 

        if (_isAccepted) {
            challenge.solutionAcceptCount[_participant]++;
            _increaseReputation(msg.sender, 1); // Verifier gains reputation for active verification
        } else {
            // No reputation loss for rejection, only for fraud or explicit bad actions
        }

        emit SolutionVerified(_challengeId, msg.sender, _participant, _isAccepted);
    }

    function getChallengeStatus(uint256 _challengeId) public view returns (
        ChallengeStatus status,
        uint256 skillId,
        address creator,
        uint64 deadline,
        uint256 rewardAmount,
        uint256 numParticipants,
        uint256 numVerifiers,
        uint256 minVerificationsNeeded
    ) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");

        return (
            challenge.status,
            challenge.skillId,
            challenge.creator,
            challenge.deadline,
            challenge.rewardAmount,
            challenge.participants.length,
            challenge.verifiers.length,
            challenge.minVerificationsRequired
        );
    }

    function finalizeChallenge(uint256 _challengeId) external {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "KnowledgeVault: Challenge does not exist");
        require(challenge.status != ChallengeStatus.Completed && challenge.status != ChallengeStatus.Cancelled, "KnowledgeVault: Challenge already finalized or cancelled");
        require(block.timestamp > challenge.deadline, "KnowledgeVault: Cannot finalize before deadline");
        
        // Ensure at least one verifier has accepted their role to proceed with finalization.
        bool atLeastOneVerifierAccepted = false;
        for (uint256 i = 0; i < challenge.verifiers.length; i++) {
            if (verifierAcceptedRoles[_challengeId][challenge.verifiers[i]]) {
                atLeastOneVerifierAccepted = true;
                break;
            }
        }
        require(atLeastOneVerifierAccepted, "KnowledgeVault: No verifiers have accepted their role for this challenge yet.");

        // If submissions are still open after deadline, close them
        if (challenge.status == ChallengeStatus.Open) {
            challenge.status = ChallengeStatus.SubmissionsClosed;
        }

        uint256 platformShare = (challenge.rewardAmount * platformFeePercentage) / 10000;
        uint256 rewardForParticipantsPool = challenge.rewardAmount - platformShare;
        
        uint256 successfulParticipantsCount = 0;
        for (uint256 i = 0; i < challenge.participants.length; i++) {
            address participant = challenge.participants[i];
            if (challenge.solutionAcceptCount[participant] >= challenge.minVerificationsRequired) {
                successfulParticipantsCount++;
            }
        }

        if (successfulParticipantsCount > 0) {
            uint256 rewardPerParticipant = rewardForParticipantsPool / successfulParticipantsCount; // Divide equally among successful ones
            for (uint256 i = 0; i < challenge.participants.length; i++) {
                address participant = challenge.participants[i];
                if (challenge.solutionAcceptCount[participant] >= challenge.minVerificationsRequired) {
                    _issueAdeptCertificate(participant, challenge.skillId, challenge.solutions[participant], address(this));
                    payable(participant).transfer(rewardPerParticipant);
                }
            }
            totalPlatformFeesCollected += platformShare;
        } else {
             // If no one successfully completed, the entire reward goes to the platform fees
             totalPlatformFeesCollected += challenge.rewardAmount;
        }

        challenge.status = ChallengeStatus.Completed;
        emit ChallengeFinalized(_challengeId, ChallengeStatus.Completed);
    }

    // --- IV. Reputation & Moderation ---

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function _increaseReputation(address _user, int256 _amount) internal {
        if (_amount > 0) {
            userReputation[_user] += uint256(_amount);
        } else if (userReputation[_user] >= uint256(-_amount)) { // Check for potential underflow
            userReputation[_user] -= uint256(-_amount);
        } else {
            userReputation[_user] = 0; // Set to 0 if subtraction would lead to negative
        }
        emit UserReputationIncreased(_user, userReputation[_user]);
    }

    function setSkillNodeModerator(uint256 _skillId, address _moderator) external onlyPlatformAdmin {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        skillNodes[_skillId].moderator = _moderator;
        emit SkillNodeModeratorSet(_skillId, _moderator);
    }

    // --- V. Content & Resource Linking ---

    function linkResourceToSkill(uint256 _skillId, string calldata _resourceURI, string calldata _description) external {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        require(bytes(_resourceURI).length > 0, "KnowledgeVault: Resource URI cannot be empty");
        // Anyone can contribute resources. A moderator or admin can later prune irrelevant ones if needed.

        skillResources[_skillId].push(SkillResource({
            uri: _resourceURI,
            description: _description,
            contributor: msg.sender,
            timestamp: uint64(block.timestamp)
        }));

        emit SkillResourceLinked(_skillId, _resourceURI, msg.sender);
    }

    function getSkillResources(uint256 _skillId) external view returns (
        string[] memory uris,
        string[] memory descriptions,
        address[] memory contributors,
        uint64[] memory timestamps
    ) {
        require(skillNodes[_skillId].exists, "KnowledgeVault: Skill node does not exist");
        SkillResource[] storage resources = skillResources[_skillId];
        uris = new string[](resources.length);
        descriptions = new string[](resources.length);
        contributors = new address[](resources.length);
        timestamps = new uint64[](resources.length);

        for (uint256 i = 0; i < resources.length; i++) {
            uris[i] = resources[i].uri;
            descriptions[i] = resources[i].description;
            contributors[i] = resources[i].contributor;
            timestamps[i] = resources[i].timestamp;
        }
        return (uris, descriptions, contributors, timestamps);
    }

    // --- VI. Platform Management ---

    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin {
        require(_feePercentage <= 10000, "KnowledgeVault: Fee percentage cannot exceed 10000 (100%)");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    function withdrawPlatformFunds() external onlyPlatformAdmin {
        uint256 amount = totalPlatformFeesCollected;
        require(amount > 0, "KnowledgeVault: No fees to withdraw");
        totalPlatformFeesCollected = 0; // Reset balance before transfer to prevent reentrancy (Checks-Effects-Interactions)
        payable(owner()).transfer(amount);
        emit PlatformFundsWithdrawn(owner(), amount);
    }
}
```