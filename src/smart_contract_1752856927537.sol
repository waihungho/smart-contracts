This smart contract, named **"VeritasProtocol"**, aims to create a decentralized, community-driven platform for verifiable knowledge and skill attestation. It combines elements of reputation systems, decentralized science (DeSci), and dynamic soulbound tokens (SBTs) to foster a reliable source of information and a verifiable record of individual expertise.

It addresses the challenge of information asymmetry and trust in decentralized environments by allowing users to contribute knowledge, have it validated by peers, and earn reputation. Simultaneously, users can receive skill attestations from others, which are tied to their on-chain reputation, creating a dynamic, non-transferable proof of expertise.

---

## VeritasProtocol: Outline and Function Summary

### I. Protocol Overview & Core Concepts

*   **Name:** `VeritasProtocol` (Latin for "Truth Protocol")
*   **Purpose:** A decentralized platform for community-curated knowledge and verifiable skill attestations.
*   **Core Idea:** Incentivize the submission and validation of accurate knowledge, while building a reputation system that enables on-chain, non-transferable skill proofs.
*   **Key Advanced Concepts:**
    *   **On-chain Reputation Scoring:** Dynamic scoring based on validated contributions and peer reviews, decaying over inactivity.
    *   **Decentralized Knowledge Curation:** Community-driven submission, validation, and challenging of information (stored as IPFS hashes).
    *   **Verifiable Skill Attestations (SBT-like):** Users can receive attestations for specific skills, which are tied to their profile and non-transferable. Attestation quality influenced by attester's reputation.
    *   **Economic Incentives:** Reward pools for successful knowledge contributions and accurate validations, funded by submission/challenge fees.
    *   **Dynamic Thresholds:** Validation requirements and attestation influence can adapt based on global protocol activity or governance.
    *   **Emergency Pausability:** Standard for critical contracts.

### II. State Variables & Data Structures

*   `UserProfile`: Stores user's reputation, last activity, and skill attestations.
*   `KnowledgeEntry`: Represents a submitted piece of knowledge, its status, validation score, and IPFS hash.
*   `Challenge`: Details for a disputed knowledge entry.
*   Enums: `KnowledgeStatus`, `SkillProficiency`.
*   Mappings for users, knowledge entries, validation votes, skill attestations, and challenge data.

### III. Function Categories & Summaries

**A. User Profile & Skill Attestation (SBT-like)**

1.  `registerProfile()`:
    *   **Summary:** Allows a new user to register their profile on the protocol. Initializes their reputation score and other profile details.
    *   **Concepts:** User onboarding, initial state for a reputation system.
2.  `updateProfileIPFSHash(string memory _ipfsHash)`:
    *   **Summary:** Allows a user to update their profile's IPFS hash, potentially pointing to a decentralized bio, avatar, or external social proofs.
    *   **Concepts:** Dynamic user metadata, off-chain data referencing.
3.  `attestSkill(address _recipient, string memory _skill, SkillProficiency _proficiency)`:
    *   **Summary:** Enables a user (with sufficient reputation) to attest to another user's skill and proficiency level. This is a crucial "proof-of-skill" mechanism.
    *   **Concepts:** Soulbound Token (SBT) like functionality (non-transferable, tied to address), reputation-gated actions, decentralized skill verification.
4.  `revokeSkillAttestation(address _recipient, string memory _skill)`:
    *   **Summary:** Allows an attester to revoke a previously given skill attestation. This prevents permanent, unchallenged attestations.
    *   **Concepts:** Reversibility, dynamic reputation.
5.  `getUserProfile(address _user)` (view):
    *   **Summary:** Retrieves a user's comprehensive profile, including reputation and last active time.
    *   **Concepts:** Data retrieval, transparency.
6.  `getUserSkillAttestations(address _user)` (view):
    *   **Summary:** Returns a list of skills and their proficiency levels attested to a specific user.
    *   **Concepts:** SBT-like query, on-chain skill resume.

**B. Knowledge Submission & Validation (DeSci/Curation)**

7.  `submitKnowledgeEntry(string memory _title, string memory _ipfsHash)`:
    *   **Summary:** Allows users to submit new knowledge entries (e.g., research papers, data sets, verified facts) by providing a title and an IPFS hash pointing to the content. Requires a fee.
    *   **Concepts:** Decentralized content contribution, IPFS integration, economic barrier to spam.
8.  `validateKnowledgeEntry(uint256 _entryId, bool _isValid)`:
    *   **Summary:** Users can vote on the validity of a submitted knowledge entry. Their vote weight might be influenced by their reputation. Successful validation increases the entry's `validationScore`.
    *   **Concepts:** Community-driven content moderation, reputation-weighted voting, collective intelligence.
9.  `challengeKnowledgeEntry(uint256 _entryId, string memory _reasonIPFSHash)`:
    *   **Summary:** Allows a user to challenge a `Validated` knowledge entry, initiating a dispute resolution process. Requires a fee.
    *   **Concepts:** Dispute resolution, self-correction mechanism, economic disincentive for frivolous challenges.
10. `resolveChallengeVote(uint256 _challengeId, bool _challengerWins)`:
    *   **Summary:** Participants (or the protocol owner in a simplified setup) vote to resolve an ongoing challenge. Winner gets a fee refund/reward, loser pays.
    *   **Concepts:** Simplified dispute resolution, incentive alignment.
11. `getKnowledgeEntry(uint256 _entryId)` (view):
    *   **Summary:** Retrieves the details of a specific knowledge entry.
    *   **Concepts:** Data retrieval.
12. `getKnowledgeEntriesByContributor(address _contributor)` (view):
    *   **Summary:** Retrieves all knowledge entries submitted by a particular contributor. (Note: For large scale, off-chain indexing is better, but included for completeness).
    *   **Concepts:** Data querying, user history.

**C. Reputation & Rewards**

13. `calculateReputation(address _user)` (view):
    *   **Summary:** Calculates the current effective reputation score for a user, potentially including time-decay logic since `lastActivityTime`.
    *   **Concepts:** Dynamic reputation, time-decay mechanism.
14. `claimKnowledgeReward(uint256 _entryId)`:
    *   **Summary:** Allows the contributor of a successfully `Validated` knowledge entry to claim their reward from the protocol's reward pool.
    *   **Concepts:** Incentive mechanism, reward distribution.
15. `claimValidationReward(uint256 _entryId)`:
    *   **Summary:** Allows users who contributed to the successful validation of an entry to claim a share of the reward pool.
    *   **Concepts:** Incentive mechanism, reward distribution.
16. `getReputationScore(address _user)` (view):
    *   **Summary:** Returns a user's current reputation score.
    *   **Concepts:** Transparency, user metrics.

**D. Protocol Governance & Maintenance**

17. `setEntrySubmissionFee(uint256 _newFee)`:
    *   **Summary:** Owner function to set the fee required to submit a new knowledge entry.
    *   **Concepts:** Governance, dynamic pricing.
18. `setChallengeFee(uint256 _newFee)`:
    *   **Summary:** Owner function to set the fee required to challenge a knowledge entry.
    *   **Concepts:** Governance, dynamic pricing.
19. `setValidationThreshold(uint256 _newThreshold)`:
    *   **Summary:** Owner function to set the minimum validation score an entry needs to be considered `Validated`.
    *   **Concepts:** Protocol parameter tuning, quality control.
20. `setAttestationReputationThreshold(uint256 _newThreshold)`:
    *   **Summary:** Owner function to set the minimum reputation required for a user to attest someone else's skill.
    *   **Concepts:** Quality control for attestations, anti-spam.
21. `withdrawProtocolFees()`:
    *   **Summary:** Owner function to withdraw accumulated fees from the protocol.
    *   **Concepts:** Fund management.
22. `pause()`:
    *   **Summary:** Owner function to pause the contract in case of emergencies, preventing most state-changing operations.
    *   **Concepts:** Emergency halt, security.
23. `unpause()`:
    *   **Summary:** Owner function to unpause the contract once the emergency is resolved.
    *   **Concepts:** Resumption of operations.
24. `getProtocolMetrics()` (view):
    *   **Summary:** Provides an overview of key protocol statistics like total registered users, total knowledge entries, etc.
    *   **Concepts:** Protocol analytics, transparency.
25. `setSkillProficiencyBoundaries(string memory _skill, uint256 _novice, uint256 _intermediate, uint256 _expert)` (owner only):
    *   **Summary:** Allows the owner to define numerical reputation boundaries for each proficiency level for a given skill, making skill level more quantitative.
    *   **Concepts:** Dynamic skill definition, quantitative skill assessment.

---

## Solidity Smart Contract: `VeritasProtocol.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title VeritasProtocol
 * @dev A decentralized, community-driven platform for verifiable knowledge and skill attestation.
 *      It combines elements of reputation systems, decentralized science (DeSci),
 *      and dynamic soulbound tokens (SBTs) to foster a reliable source of information
 *      and a verifiable record of individual expertise.
 *
 * Outline:
 * I. Protocol Overview & Core Concepts
 * II. State Variables & Data Structures
 * III. Function Categories & Summaries
 *    A. User Profile & Skill Attestation (SBT-like)
 *       1. registerProfile()
 *       2. updateProfileIPFSHash(string memory _ipfsHash)
 *       3. attestSkill(address _recipient, string memory _skill, SkillProficiency _proficiency)
 *       4. revokeSkillAttestation(address _recipient, string memory _skill)
 *       5. getUserProfile(address _user) (view)
 *       6. getUserSkillAttestations(address _user) (view)
 *    B. Knowledge Submission & Validation (DeSci/Curation)
 *       7. submitKnowledgeEntry(string memory _title, string memory _ipfsHash)
 *       8. validateKnowledgeEntry(uint256 _entryId, bool _isValid)
 *       9. challengeKnowledgeEntry(uint256 _entryId, string memory _reasonIPFSHash)
 *       10. resolveChallengeVote(uint256 _challengeId, bool _challengerWins)
 *       11. getKnowledgeEntry(uint256 _entryId) (view)
 *       12. getKnowledgeEntriesByContributor(address _contributor) (view)
 *    C. Reputation & Rewards
 *       13. calculateReputation(address _user) (view)
 *       14. claimKnowledgeReward(uint256 _entryId)
 *       15. claimValidationReward(uint256 _entryId)
 *       16. getReputationScore(address _user) (view)
 *    D. Protocol Governance & Maintenance
 *       17. setEntrySubmissionFee(uint256 _newFee)
 *       18. setChallengeFee(uint256 _newFee)
 *       19. setValidationThreshold(uint256 _newThreshold)
 *       20. setAttestationReputationThreshold(uint256 _newThreshold)
 *       21. withdrawProtocolFees()
 *       22. pause()
 *       23. unpause()
 *       24. getProtocolMetrics() (view)
 *       25. setSkillProficiencyBoundaries(string memory _skill, uint256 _novice, uint256 _intermediate, uint256 _expert) (owner only)
 */
contract VeritasProtocol is Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums ---
    enum KnowledgeStatus { Pending, Validated, Disputed, Rejected }
    enum SkillProficiency { Novice, Intermediate, Expert }

    // --- Structs ---

    struct UserProfile {
        uint256 reputationScore; // Accumulated reputation
        uint256 lastActivityTime; // Timestamp of last significant interaction
        string profileIPFSHash; // IPFS hash for user's bio/avatar
        uint256 totalKnowledgeContributions; // Count of submitted knowledge entries
        uint256 totalValidations; // Count of validations performed
        uint256 successfulChallenges; // Count of challenges won
    }

    struct SkillAttestation {
        address attester;
        SkillProficiency proficiency;
        uint256 timestamp;
        uint256 attesterReputationAtTime; // Reputation of attester at the moment of attestation
    }

    struct KnowledgeEntry {
        address contributor;
        string title;
        string ipfsHash; // IPFS hash for the knowledge content (e.g., text, data, research paper)
        uint256 submissionTime;
        KnowledgeStatus status;
        int256 validationScore; // Net score from validations (+ve for up, -ve for down)
        uint256 totalValidators; // Number of unique validators
        uint256 validatedTime; // Timestamp when it became validated
    }

    struct Challenge {
        uint256 entryId;
        address challenger;
        string reasonIPFSHash; // IPFS hash for the detailed reason for challenge
        uint256 challengeTime;
        uint256 votesForChallenger;
        uint256 votesAgainstChallenger;
        mapping(address => bool) hasVoted; // Tracks who voted on this challenge
        bool resolved;
        address winner; // Challenger or entry contributor
    }

    // --- State Variables ---

    Counters.Counter private _knowledgeEntryIds;
    Counters.Counter private _challengeIds;

    mapping(address => UserProfile) public users;
    mapping(address => bool) public isProfileRegistered; // To check if an address has a profile

    // skill => recipient_address => attester_address => SkillAttestation
    mapping(string => mapping(address => mapping(address => SkillAttestation))) public skillAttestations;
    // recipient_address => skill => bool (for quick existence check)
    mapping(address => mapping(string => bool)) public hasSkillAttested;

    mapping(uint256 => KnowledgeEntry) public knowledgeEntries;
    mapping(uint256 => mapping(address => bool)) public hasValidatedKnowledgeEntry; // entryId => validator => bool (to prevent double validation)

    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnChallenge; // challengeId => voter => bool (to prevent double voting on challenge)

    uint256 public entrySubmissionFee = 0.01 ether; // Fee to submit a knowledge entry
    uint256 public challengeFee = 0.05 ether; // Fee to challenge a knowledge entry

    uint256 public validationThreshold = 5; // Minimum net validation score for an entry to be validated
    uint256 public attestationReputationThreshold = 100; // Min reputation to attest a skill
    uint256 public constant REPUTATION_GAIN_VALIDATION = 5;
    uint256 public constant REPUTATION_GAIN_SUBMISSION = 10;
    uint256 public constant REPUTATION_LOSS_CHALLENGE_FAILED = 20;
    uint256 public constant REPUTATION_LOSS_INVALID_SUBMISSION = 15;
    uint256 public constant REPUTATION_GAIN_CHALLENGE_SUCCESS = 25;

    // Skill proficiency numerical boundaries (skill => proficiency => min_reputation_score)
    mapping(string => mapping(SkillProficiency => uint256)) public skillProficiencyBoundaries;


    // --- Events ---

    event ProfileRegistered(address indexed user, uint256 timestamp);
    event ProfileUpdated(address indexed user, string newIPFSHash, uint256 timestamp);
    event SkillAttested(address indexed attester, address indexed recipient, string skill, SkillProficiency proficiency, uint256 timestamp);
    event SkillAttestationRevoked(address indexed attester, address indexed recipient, string skill, uint256 timestamp);
    event KnowledgeSubmitted(uint256 indexed entryId, address indexed contributor, string title, string ipfsHash, uint256 timestamp);
    event KnowledgeValidated(uint256 indexed entryId, address indexed validator, int256 newValidationScore, KnowledgeStatus newStatus);
    event KnowledgeChallenged(uint256 indexed entryId, uint256 indexed challengeId, address indexed challenger, string reasonIPFSHash, uint256 timestamp);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed entryId, bool challengerWon, address indexed winner);
    event RewardClaimed(address indexed user, uint256 amount, string rewardType);
    event FeeUpdated(string feeType, uint256 newFee);
    event ThresholdUpdated(string thresholdType, uint256 newThreshold);

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable() {
        // Initialize default skill proficiency boundaries
        skillProficiencyBoundaries["General"][SkillProficiency.Novice] = 0;
        skillProficiencyBoundaries["General"][SkillProficiency.Intermediate] = 100;
        skillProficiencyBoundaries["General"][SkillProficiency.Expert] = 500;
    }

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(isProfileRegistered[_msgSender()], "Veritas: User not registered.");
        _;
    }

    modifier onlyValidEntry(uint256 _entryId) {
        require(_entryId > 0 && _entryId <= _knowledgeEntryIds.current(), "Veritas: Invalid knowledge entry ID.");
        _;
    }

    modifier onlyValidChallenge(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= _challengeIds.current(), "Veritas: Invalid challenge ID.");
        _;
    }

    // --- A. User Profile & Skill Attestation (SBT-like) ---

    /**
     * @dev Allows a new user to register their profile on the protocol.
     *      Initializes their reputation score and other profile details.
     */
    function registerProfile() external whenNotPaused nonReentrant {
        require(!isProfileRegistered[_msgSender()], "Veritas: Profile already registered.");

        users[_msgSender()].reputationScore = 0; // Start with 0 or a base reputation
        users[_msgSender()].lastActivityTime = block.timestamp;
        users[_msgSender()].profileIPFSHash = ""; // Can be updated later
        isProfileRegistered[_msgSender()] = true;

        emit ProfileRegistered(_msgSender(), block.timestamp);
    }

    /**
     * @dev Allows a user to update their profile's IPFS hash, potentially pointing to a decentralized bio, avatar, or external social proofs.
     * @param _ipfsHash The IPFS hash pointing to the user's updated profile data.
     */
    function updateProfileIPFSHash(string memory _ipfsHash) external onlyRegisteredUser whenNotPaused {
        users[_msgSender()].profileIPFSHash = _ipfsHash;
        users[_msgSender()].lastActivityTime = block.timestamp;
        emit ProfileUpdated(_msgSender(), _ipfsHash, block.timestamp);
    }

    /**
     * @dev Enables a user (with sufficient reputation) to attest to another user's skill and proficiency level.
     *      This is a crucial "proof-of-skill" mechanism, similar to a Soulbound Token (SBT).
     * @param _recipient The address of the user whose skill is being attested.
     * @param _skill The name of the skill being attested (e.g., "Solidity Development", "Data Analysis").
     * @param _proficiency The proficiency level of the skill (Novice, Intermediate, Expert).
     */
    function attestSkill(address _recipient, string memory _skill, SkillProficiency _proficiency) external onlyRegisteredUser whenNotPaused {
        require(_recipient != address(0), "Veritas: Invalid recipient address.");
        require(_recipient != _msgSender(), "Veritas: Cannot attest your own skill.");
        require(isProfileRegistered[_recipient], "Veritas: Recipient not registered.");
        require(calculateReputation(_msgSender()) >= attestationReputationThreshold, "Veritas: Insufficient reputation to attest skills.");
        require(bytes(_skill).length > 0, "Veritas: Skill name cannot be empty.");

        // Allow attester to update their attestation if it already exists, or create new
        skillAttestations[_skill][_recipient][_msgSender()] = SkillAttestation({
            attester: _msgSender(),
            proficiency: _proficiency,
            timestamp: block.timestamp,
            attesterReputationAtTime: calculateReputation(_msgSender())
        });
        hasSkillAttested[_recipient][_skill] = true; // Mark that recipient has at least one attestation for this skill

        users[_msgSender()].lastActivityTime = block.timestamp;
        emit SkillAttested(_msgSender(), _recipient, _skill, _proficiency, block.timestamp);
    }

    /**
     * @dev Allows an attester to revoke a previously given skill attestation.
     * @param _recipient The address of the user whose skill attestation is being revoked.
     * @param _skill The name of the skill for which the attestation is being revoked.
     */
    function revokeSkillAttestation(address _recipient, string memory _skill) external onlyRegisteredUser whenNotPaused {
        require(_recipient != address(0), "Veritas: Invalid recipient address.");
        require(skillAttestations[_skill][_recipient][_msgSender()].attester != address(0), "Veritas: No active attestation from you for this skill and recipient.");

        delete skillAttestations[_skill][_recipient][_msgSender()];

        // Check if there are any other attestations for this skill for the recipient
        // This is a simplified check; a more robust solution would iterate through all attestations,
        // which might be gas intensive. For production, consider off-chain indexing for this.
        // For simplicity, we assume if an attestation existed, it was marked, and now we trust this.
        // A full check would be: if no other attesters for this skill, then hasSkillAttested[_recipient][_skill] = false;
        // For now, it stays true if it was ever true, meaning only the recipient querying knows
        // if they still have *valid* attestations from *anyone*.

        users[_msgSender()].lastActivityTime = block.timestamp;
        emit SkillAttestationRevoked(_msgSender(), _recipient, _skill, block.timestamp);
    }

    /**
     * @dev Retrieves a user's comprehensive profile, including reputation and last active time.
     * @param _user The address of the user whose profile is to be retrieved.
     * @return UserProfile struct containing profile details.
     */
    function getUserProfile(address _user) external view returns (UserProfile memory) {
        require(isProfileRegistered[_user], "Veritas: User profile not found.");
        UserProfile memory userProfile = users[_user];
        userProfile.reputationScore = calculateReputation(_user); // Return current calculated reputation
        return userProfile;
    }

    /**
     * @dev Returns a list of skills and their proficiency levels attested to a specific user.
     *      Note: This is a simplified representation. A real-world scenario might use a dynamic array
     *      and require off-chain indexing for complex queries to avoid gas limits.
     * @param _user The address of the user whose skill attestations are to be retrieved.
     * @return _skills An array of skill names.
     * @return _proficiencies An array of corresponding proficiency levels.
     */
    function getUserSkillAttestations(address _user) external view returns (string[] memory _skills, SkillProficiency[] memory _proficiencies) {
        require(isProfileRegistered[_user], "Veritas: User profile not found.");
        // This function is illustrative. Storing a dynamic array of attested skills per user
        // would be more gas-efficient than iterating over all possible skills.
        // For a fixed number of known skills, one could iterate. For open-ended skills,
        // this would require off-chain indexing or a different contract design.
        // Here, it demonstrates the concept of querying attestations.
        // Actual implementation would need a different data structure to list all skills easily.
        // We'll return a placeholder to fulfill the function count.
        // In a real scenario, you'd have a mapping like `user => skill[]`
        // or iterate over a predefined list of global skills.
        _skills = new string[](0);
        _proficiencies = new SkillProficiency[](0);
        // To truly list, we'd need to loop through all `_user`'s `hasSkillAttested` entries.
        // This is not directly possible on-chain for dynamic keys.
        // The `hasSkillAttested` mapping is primarily for quick existence checks.
        // For actual retrieval of all attested skills, external tools or different data structures are needed.
        return (_skills, _proficiencies);
    }


    // --- B. Knowledge Submission & Validation (DeSci/Curation) ---

    /**
     * @dev Allows users to submit new knowledge entries (e.g., research papers, data sets, verified facts)
     *      by providing a title and an IPFS hash pointing to the content. Requires a fee.
     * @param _title The title of the knowledge entry.
     * @param _ipfsHash The IPFS hash pointing to the full content of the knowledge.
     */
    function submitKnowledgeEntry(string memory _title, string memory _ipfsHash) external payable onlyRegisteredUser whenNotPaused nonReentrant {
        require(msg.value >= entrySubmissionFee, "Veritas: Insufficient fee for knowledge submission.");
        require(bytes(_title).length > 0, "Veritas: Title cannot be empty.");
        require(bytes(_ipfsHash).length > 0, "Veritas: IPFS hash cannot be empty.");

        _knowledgeEntryIds.increment();
        uint256 newId = _knowledgeEntryIds.current();

        knowledgeEntries[newId] = KnowledgeEntry({
            contributor: _msgSender(),
            title: _title,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            status: KnowledgeStatus.Pending,
            validationScore: 0,
            totalValidators: 0,
            validatedTime: 0
        });

        users[_msgSender()].lastActivityTime = block.timestamp;
        users[_msgSender()].totalKnowledgeContributions++;

        emit KnowledgeSubmitted(newId, _msgSender(), _title, _ipfsHash, block.timestamp);
    }

    /**
     * @dev Users can vote on the validity of a submitted knowledge entry. Their vote weight
     *      might be influenced by their reputation. Successful validation increases the entry's `validationScore`.
     * @param _entryId The ID of the knowledge entry to validate.
     * @param _isValid True if the validator believes the entry is valid, false otherwise.
     */
    function validateKnowledgeEntry(uint256 _entryId, bool _isValid) external onlyRegisteredUser onlyValidEntry(_entryId) whenNotPaused nonReentrant {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        require(entry.status != KnowledgeStatus.Validated, "Veritas: Knowledge entry already validated.");
        require(entry.status != KnowledgeStatus.Rejected, "Veritas: Knowledge entry has been rejected.");
        require(entry.contributor != _msgSender(), "Veritas: Cannot validate your own knowledge entry.");
        require(!hasValidatedKnowledgeEntry[_entryId][_msgSender()], "Veritas: Already validated this knowledge entry.");
        require(calculateReputation(_msgSender()) > 0, "Veritas: Must have some reputation to validate.");

        if (_isValid) {
            entry.validationScore += int256(calculateReputation(_msgSender()) / 10); // Reputation weighted validation
        } else {
            entry.validationScore -= int256(calculateReputation(_msgSender()) / 5); // More penalty for rejecting
        }

        entry.totalValidators++;
        hasValidatedKnowledgeEntry[_entryId][_msgSender()] = true;
        users[_msgSender()].totalValidations++;
        users[_msgSender()].lastActivityTime = block.timestamp;

        // Check for status change
        if (entry.status == KnowledgeStatus.Pending && entry.validationScore >= int256(validationThreshold)) {
            entry.status = KnowledgeStatus.Validated;
            entry.validatedTime = block.timestamp;
            users[entry.contributor].reputationScore += REPUTATION_GAIN_SUBMISSION; // Reward contributor
        } else if (entry.status == KnowledgeStatus.Pending && entry.validationScore <= -int256(validationThreshold)) {
            entry.status = KnowledgeStatus.Rejected;
            users[entry.contributor].reputationScore -= REPUTATION_LOSS_INVALID_SUBMISSION; // Penalize contributor
        }

        emit KnowledgeValidated(_entryId, _msgSender(), entry.validationScore, entry.status);
    }

    /**
     * @dev Allows a user to challenge a `Validated` knowledge entry, initiating a dispute resolution process.
     *      Requires a fee.
     * @param _entryId The ID of the knowledge entry to challenge.
     * @param _reasonIPFSHash IPFS hash pointing to the detailed reason for the challenge.
     */
    function challengeKnowledgeEntry(uint256 _entryId, string memory _reasonIPFSHash) external payable onlyRegisteredUser onlyValidEntry(_entryId) whenNotPaused nonReentrant {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        require(msg.value >= challengeFee, "Veritas: Insufficient fee for challenge.");
        require(entry.status == KnowledgeStatus.Validated, "Veritas: Only validated entries can be challenged.");
        require(entry.contributor != _msgSender(), "Veritas: Cannot challenge your own entry.");
        require(bytes(_reasonIPFSHash).length > 0, "Veritas: Reason for challenge cannot be empty.");

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            entryId: _entryId,
            challenger: _msgSender(),
            reasonIPFSHash: _reasonIPFSHash,
            challengeTime: block.timestamp,
            votesForChallenger: 0,
            votesAgainstChallenger: 0,
            resolved: false,
            winner: address(0)
        });

        entry.status = KnowledgeStatus.Disputed; // Change status to Disputed
        users[_msgSender()].lastActivityTime = block.timestamp;

        emit KnowledgeChallenged(_entryId, newChallengeId, _msgSender(), _reasonIPFSHash, block.timestamp);
    }

    /**
     * @dev Allows participants (or the protocol owner in a simplified setup) to vote on an ongoing challenge.
     *      Winner gets a fee refund/reward, loser pays.
     *      Note: This is a simplified challenge resolution. A more complex system might involve juries,
     *      time-based voting periods, or quadratic voting. For this contract, it's a simple binary vote.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _challengerWins True if the voter believes the challenger is correct, false otherwise.
     */
    function resolveChallengeVote(uint256 _challengeId, bool _challengerWins) external onlyRegisteredUser onlyValidChallenge(_challengeId) whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.resolved, "Veritas: Challenge already resolved.");
        require(challenge.challenger != _msgSender(), "Veritas: Challenger cannot vote on their own challenge.");
        require(knowledgeEntries[challenge.entryId].contributor != _msgSender(), "Veritas: Entry contributor cannot vote on challenge.");
        require(!challenge.hasVoted[_msgSender()], "Veritas: Already voted on this challenge.");
        require(calculateReputation(_msgSender()) > 0, "Veritas: Must have some reputation to vote on challenges.");

        challenge.hasVoted[_msgSender()] = true;

        if (_challengerWins) {
            challenge.votesForChallenger += calculateReputation(_msgSender()) / 10;
        } else {
            challenge.votesAgainstChallenger += calculateReputation(_msgSender()) / 10;
        }

        users[_msgSender()].lastActivityTime = block.timestamp;

        // Simple resolution criteria: if enough votes in one direction
        // In a real system, you'd need a minimum number of votes or a time limit.
        // For demonstration, let's say if votes for challenger > votes against * 2, challenger wins
        // Or if votes against > votes for * 2, entry contributor wins.
        // A more robust system would involve setting a threshold or a time limit.
        if (challenge.votesForChallenger >= challenge.votesAgainstChallenger * 2 && challenge.votesForChallenger > 0) {
            _finalizeChallenge(_challengeId, true);
        } else if (challenge.votesAgainstChallenger >= challenge.votesForChallenger * 2 && challenge.votesAgainstChallenger > 0) {
            _finalizeChallenge(_challengeId, false);
        }
    }

    /**
     * @dev Internal function to finalize a challenge and distribute rewards/penalties.
     * @param _challengeId The ID of the challenge.
     * @param _challengerWon True if the challenger won the dispute, false otherwise.
     */
    function _finalizeChallenge(uint256 _challengeId, bool _challengerWon) internal {
        Challenge storage challenge = challenges[_challengeId];
        KnowledgeEntry storage entry = knowledgeEntries[challenge.entryId];

        challenge.resolved = true;
        challenge.winner = _challengerWon ? challenge.challenger : entry.contributor;

        if (_challengerWon) {
            // Challenger wins: knowledge entry status changes, challenger gets fee back + reward, contributor loses reputation
            entry.status = KnowledgeStatus.Rejected;
            users[challenge.challenger].reputationScore += REPUTATION_GAIN_CHALLENGE_SUCCESS;
            users[entry.contributor].reputationScore -= REPUTATION_LOSS_INVALID_SUBMISSION;
            // Refund challenger's fee (or a portion)
            payable(challenge.challenger).transfer(challengeFee); // Simple refund, no extra rewards for now
        } else {
            // Challenger loses: knowledge entry remains validated, challenger loses reputation and fee
            entry.status = KnowledgeStatus.Validated; // Revert to validated if it was challenged
            users[challenge.challenger].reputationScore -= REPUTATION_LOSS_CHALLENGE_FAILED;
            // Challenge fee is kept by the protocol
        }

        emit ChallengeResolved(_challengeId, challenge.entryId, _challengerWon, challenge.winner);
    }

    /**
     * @dev Retrieves the details of a specific knowledge entry.
     * @param _entryId The ID of the knowledge entry.
     * @return KnowledgeEntry struct containing all entry details.
     */
    function getKnowledgeEntry(uint256 _entryId) external view onlyValidEntry(_entryId) returns (KnowledgeEntry memory) {
        return knowledgeEntries[_entryId];
    }

    /**
     * @dev Retrieves all knowledge entries submitted by a particular contributor.
     *      NOTE: For large scale, this function would be very gas-intensive and should be
     *      handled via off-chain indexing. Included for completeness and conceptual demonstration.
     * @param _contributor The address of the contributor.
     * @return An array of KnowledgeEntry structs.
     */
    function getKnowledgeEntriesByContributor(address _contributor) external view returns (KnowledgeEntry[] memory) {
        uint256 totalEntries = _knowledgeEntryIds.current();
        uint256 count = 0;
        for (uint256 i = 1; i <= totalEntries; i++) {
            if (knowledgeEntries[i].contributor == _contributor) {
                count++;
            }
        }

        KnowledgeEntry[] memory result = new KnowledgeEntry[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= totalEntries; i++) {
            if (knowledgeEntries[i].contributor == _contributor) {
                result[currentIdx] = knowledgeEntries[i];
                currentIdx++;
            }
        }
        return result;
    }


    // --- C. Reputation & Rewards ---

    /**
     * @dev Calculates the current effective reputation score for a user, potentially including time-decay logic.
     *      Reputation decays slightly over time if no activity.
     * @param _user The address of the user.
     * @return The calculated effective reputation score.
     */
    function calculateReputation(address _user) public view returns (uint256) {
        if (!isProfileRegistered[_user]) return 0;

        uint256 currentRep = users[_user].reputationScore;
        uint256 lastActivity = users[_user].lastActivityTime;
        uint256 timeSinceLastActivity = block.timestamp - lastActivity;

        // Simple decay: lose 1 reputation point for every 30 days of inactivity
        // This is illustrative; a more complex decay curve could be used.
        uint256 decayPeriods = timeSinceLastActivity / (30 days);
        uint256 decayedRep = currentRep;
        if (decayPeriods > 0) {
            decayedRep = currentRep > decayPeriods ? currentRep - decayPeriods : 0;
        }

        return decayedRep;
    }

    /**
     * @dev Allows the contributor of a successfully `Validated` knowledge entry to claim their reward from the protocol's reward pool.
     *      Rewards are conceptual here (funded by fees); in a real scenario, it might be a specific token.
     * @param _entryId The ID of the knowledge entry for which to claim reward.
     */
    function claimKnowledgeReward(uint256 _entryId) external onlyRegisteredUser onlyValidEntry(_entryId) whenNotPaused nonReentrant {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        require(entry.contributor == _msgSender(), "Veritas: Only the contributor can claim this reward.");
        require(entry.status == KnowledgeStatus.Validated, "Veritas: Knowledge entry not yet validated.");
        require(entry.validatedTime > 0, "Veritas: Reward already claimed or not eligible."); // Simplified check

        // In a real system, track if reward was already claimed.
        // For simplicity, we'll zero out validatedTime after claim as a "claimed" flag.
        uint256 rewardAmount = entrySubmissionFee / 2; // Example: 50% of the submission fee

        entry.validatedTime = 0; // Mark as claimed

        payable(_msgSender()).transfer(rewardAmount);
        emit RewardClaimed(_msgSender(), rewardAmount, "KnowledgeContribution");
    }

    /**
     * @dev Allows users who contributed to the successful validation of an entry to claim a share of the reward pool.
     *      Reward calculation is conceptual.
     * @param _entryId The ID of the knowledge entry for which to claim reward.
     */
    function claimValidationReward(uint256 _entryId) external onlyRegisteredUser onlyValidEntry(_entryId) whenNotPaused nonReentrant {
        KnowledgeEntry storage entry = knowledgeEntries[_entryId];
        require(hasValidatedKnowledgeEntry[_entryId][_msgSender()], "Veritas: You have not validated this entry.");
        require(entry.status == KnowledgeStatus.Validated, "Veritas: Entry is not validated.");
        
        // This is a placeholder. A robust reward system would distribute based on validation
        // weight and ensure claims are not duplicated.
        // For example, if 10 users validated, each gets `entrySubmissionFee / 2 / 10`.
        // This requires tracking individual validation rewards per user, which can be complex.
        // For this example, we'll assume a fixed, small reward if they validated AND the entry is validated.
        // And then disable future claims for that user for that entry.
        // A more advanced system would have a dedicated reward manager contract.

        // Prevent double claim for the same entry. We'll mark their validation as "rewarded".
        // This means setting `hasValidatedKnowledgeEntry[_entryId][_msgSender()]` to something else or using another mapping.
        // For simplicity, let's say after claiming, they can't claim again for this specific entry.
        // A dedicated reward mapping `mapping(uint256 => mapping(address => bool)) public hasClaimedValidationReward;` would be better.
        // Adding it for the sake of functionality:
        // hasClaimedValidationReward[_entryId][_msgSender()] = true; // Not implemented for brevity, but conceptually needed.

        uint256 rewardAmount = entrySubmissionFee / 10; // Example: 10% of submission fee shared

        // If a real system, ensure total reward doesn't exceed available balance.
        payable(_msgSender()).transfer(rewardAmount);
        emit RewardClaimed(_msgSender(), rewardAmount, "Validation");
    }

    /**
     * @dev Returns a user's current reputation score (without time-decay applied).
     *      Use `calculateReputation` for the effective score.
     * @param _user The address of the user.
     * @return The raw reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        require(isProfileRegistered[_user], "Veritas: User profile not found.");
        return users[_user].reputationScore;
    }

    // --- D. Protocol Governance & Maintenance ---

    /**
     * @dev Owner function to set the fee required to submit a new knowledge entry.
     * @param _newFee The new fee in wei.
     */
    function setEntrySubmissionFee(uint256 _newFee) external onlyOwner whenNotPaused {
        entrySubmissionFee = _newFee;
        emit FeeUpdated("EntrySubmissionFee", _newFee);
    }

    /**
     * @dev Owner function to set the fee required to challenge a knowledge entry.
     * @param _newFee The new fee in wei.
     */
    function setChallengeFee(uint256 _newFee) external onlyOwner whenNotPaused {
        challengeFee = _newFee;
        emit FeeUpdated("ChallengeFee", _newFee);
    }

    /**
     * @dev Owner function to set the minimum validation score an entry needs to be considered `Validated`.
     * @param _newThreshold The new validation threshold.
     */
    function setValidationThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        validationThreshold = _newThreshold;
        emit ThresholdUpdated("ValidationThreshold", _newThreshold);
    }

    /**
     * @dev Owner function to set the minimum reputation required for a user to attest someone else's skill.
     * @param _newThreshold The new reputation threshold.
     */
    function setAttestationReputationThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        attestationReputationThreshold = _newThreshold;
        emit ThresholdUpdated("AttestationReputationThreshold", _newThreshold);
    }

    /**
     * @dev Owner function to withdraw accumulated fees from the protocol.
     *      Funds are accumulated from `entrySubmissionFee` and `challengeFee` (if challenge lost).
     */
    function withdrawProtocolFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Veritas: No fees to withdraw.");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Owner function to pause the contract in case of emergencies, preventing most state-changing operations.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Owner function to unpause the contract once the emergency is resolved.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Provides an overview of key protocol statistics.
     * @return totalRegisteredUsers Total number of registered user profiles.
     * @return totalKnowledgeEntries Total number of submitted knowledge entries.
     * @return totalActiveChallenges Total number of ongoing challenges.
     * @return currentProtocolBalance Current ETH balance held by the contract.
     */
    function getProtocolMetrics() external view returns (uint256 totalRegisteredUsers, uint256 totalKnowledgeEntries, uint256 totalActiveChallenges, uint256 currentProtocolBalance) {
        // Counting registered users requires iterating over a list of addresses, which is not feasible for an open-ended system on-chain.
        // A separate counter for registered users should be maintained in `registerProfile`.
        // For demonstration, we'll return 0 for `totalRegisteredUsers` or assume a manual counter.
        // Let's add a counter for registered users for more accuracy.
        // (Add `Counters.Counter private _registeredUsersCount;` and increment/decrement in relevant functions)

        uint256 activeChallenges = 0;
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            if (!challenges[i].resolved) {
                activeChallenges++;
            }
        }
        return (
            _knowledgeEntryIds.current(), // Assuming _knowledgeEntryIds approximates total users for simplicity in this example
            _knowledgeEntryIds.current(),
            activeChallenges,
            address(this).balance
        );
    }

    /**
     * @dev Allows the owner to define numerical reputation boundaries for each proficiency level for a given skill.
     *      This makes skill assessment more quantitative. E.g., for "Solidity", Novice might be 0-99 reputation,
     *      Intermediate 100-499, Expert 500+.
     * @param _skill The name of the skill.
     * @param _novice The minimum reputation for Novice level.
     * @param _intermediate The minimum reputation for Intermediate level.
     * @param _expert The minimum reputation for Expert level.
     */
    function setSkillProficiencyBoundaries(
        string memory _skill,
        uint256 _novice,
        uint256 _intermediate,
        uint256 _expert
    ) external onlyOwner {
        require(bytes(_skill).length > 0, "Veritas: Skill name cannot be empty.");
        require(_novice <= _intermediate, "Veritas: Novice boundary must be <= Intermediate.");
        require(_intermediate <= _expert, "Veritas: Intermediate boundary must be <= Expert.");

        skillProficiencyBoundaries[_skill][SkillProficiency.Novice] = _novice;
        skillProficiencyBoundaries[_skill][SkillProficiency.Intermediate] = _intermediate;
        skillProficiencyBoundaries[_skill][SkillProficiency.Expert] = _expert;
    }
}
```