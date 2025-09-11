This smart contract, `Aethelgard`, establishes an "Adaptive On-chain Skill & Competency Network." It's designed as a decentralized platform for users to acquire, attest to, and leverage verifiable skills. The core innovation lies in its dynamic skill graph, reputation-weighted attestation system, and an integrated marketplace for skill-gated tasks, all governed by the community.

## Aethelgard: The Adaptive On-chain Skill & Competency Network

**Concept:** Aethelgard is a decentralized, self-organizing ecosystem for human capital development and verification on the blockchain. It aims to create a verifiable "skill graph" where users can acquire, prove, and monetize their competencies. Unlike static badge systems, Aethelgard's skill graph can evolve through governance, and skill attestations are weighted by the verifier's on-chain reputation, fostering a dynamic and trustworthy system.

**Advanced Concepts & Uniqueness:**
*   **Dynamic Skill Graph:** Skills can have prerequisites, forming a Directed Acyclic Graph (DAG) that is not static but can be updated and expanded via decentralized governance.
*   **Reputation-Weighted Attestations:** Users (verifiers) can attest to others' skills. The "strength" of an attestation is weighted by the verifier's on-chain reputation, which is earned through positive contributions and successful actions within the network.
*   **Proof-of-Skill Challenges:** On-chain challenges allow users to demonstrate proficiency directly, earning skills and rewards without requiring human attestation.
*   **Soulbound Skill Tokens (SBTs):** Once a user earns a skill (via attestation or challenge), it's represented as a non-transferable token (a boolean flag in this implementation), permanently linked to their identity.
*   **Skill-Gated Task Marketplace:** A built-in marketplace where tasks can be posted, requiring specific verified skills. Only users possessing the required skills can apply and be assigned.
*   **Learning Units as NFTs:** Educational content or challenges can be tokenized as transferable ERC-721 NFTs, linking directly to specific skills within the graph.
*   **Decentralized Governance:** Community proposals (e.g., skill graph updates, treasury withdrawals, verifier approvals) are voted on, with votes weighted by the voter's reputation.

---

### Outline and Function Summary

**I. Core Skill Management**
1.  `registerSkill(string calldata _skillName, uint256[] calldata _prerequisites)`: Registers a new skill, setting its name and optional prerequisites. Only callable by governance.
2.  `updateSkillPrerequisites(uint256 _skillId, uint256[] calldata _newPrerequisites)`: Updates the prerequisites for an existing skill. Only callable by governance.
3.  `getSkillDetails(uint256 _skillId)`: Retrieves the name, prerequisites, existence status, and challenge activity of a specified skill.
4.  `getSkillPrerequisites(uint256 _skillId)`: Retrieves only the prerequisite IDs for a given skill.
5.  `hasSkill(address _user, uint256 _skillId)`: Checks if a user possesses a specific skill. This implies they have been attested or passed a challenge for it, and all its prerequisites (if any) were met at that time.

**II. Attestation & Proof-of-Skill**
6.  `attestSkill(address _recipient, uint256 _skillId)`: Allows a registered verifier with sufficient reputation to attest to a recipient's skill. If prerequisites are met and no existing skill token, a skill token is "minted" for the recipient.
7.  `revokeAttestation(address _recipient, uint256 _skillId)`: Allows an original verifier to revoke their attestation for a recipient's skill. This negatively impacts the verifier's reputation.
8.  `submitProofOfChallenge(uint256 _skillId, bytes32 _proofHash)`: Allows a user to submit a proof for an on-chain skill challenge. If valid, the skill is granted, and a reward is distributed.
9.  `setupSkillChallenge(uint256 _skillId, bytes32 _challengeRootHash, uint256 _rewardAmount)`: Sets up an on-chain challenge for a skill, depositing the reward. Only callable by governance.
10. `getAttestationsForSkill(address _user, uint256 _skillId)`: Retrieves an array of verifier addresses who have attested to a user's skill.
11. `getAttestationStrength(address _recipient, uint256 _skillId)`: Calculates the cumulative reputation-weighted strength of valid (not revoked) attestations for a user's skill.

**III. Reputation System**
12. `getReputation(address _user)`: Retrieves the current reputation score of a user.
13. `_updateReputationScore(address _user, int256 _reputationDelta)`: Internal function to adjust a user's reputation score. Called by various actions in the contract.
14. `registerVerifier()`: Allows a user to self-register as a potential verifier, subject to meeting a minimum reputation threshold.

**IV. Learning Units (NFTs - ERC721 Extension)**
15. `mintLearningUnit(uint256 _skillId, string calldata _uri, uint256 _price)`: Mints a new ERC-721 "Learning Unit" token, associating it with a skill and setting its price.
16. `buyLearningUnit(uint256 _unitId)`: Allows a user to purchase a learning unit, transferring the unit's ownership and the price to the creator.
17. `getLearningUnitDetails(uint256 _unitId)`: Retrieves the skill ID, URI, price, and creator of a specified learning unit.
18. `getLearningUnitsForSkill(uint256 _skillId)`: Retrieves a list of Learning Unit token IDs associated with a specific skill.

**V. Skill-Gated Task Marketplace**
19. `createTask(uint256[] calldata _requiredSkills, string calldata _descriptionURI, uint256 _rewardAmount)`: Creates a new task, specifying required skills, a description URI, and a reward amount (deposited upon creation).
20. `applyForTask(uint256 _taskId)`: Allows a user to apply for a task, provided they possess all the required skills.
21. `assignTask(uint256 _taskId, address _assignee)`: The task creator assigns the task to one of the applicants.
22. `completeTask(uint256 _taskId)`: The task creator marks a task as complete, transferring the reward to the assigned individual and updating their reputation.
23. `getTaskDetails(uint256 _taskId)`: Retrieves all details for a specified task.

**VI. Governance & Treasury**
24. `proposeSkillGraphUpdate(uint256 _skillId, uint256[] calldata _newPrerequisites)`: Creates a governance proposal to update the prerequisites of a skill.
25. `proposeTreasuryWithdrawal(address _recipient, uint256 _amount)`: Creates a governance proposal to withdraw funds from the contract's treasury.
26. `proposeVerifierApproval(address _verifierCandidate)`: Creates a governance proposal to approve a user as a verifier.
27. `voteOnProposal(uint256 _proposalId, bool _approve)`: Allows users with sufficient reputation to vote on an active governance proposal. Votes are reputation-weighted.
28. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed and whose voting period has ended.
29. `_withdrawFunds(address _recipient, uint256 _amount)`: Internal function to withdraw funds from the contract treasury, callable only via a successful governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Aethelgard: The Adaptive On-chain Skill & Competency Network
 * @dev A decentralized platform for individuals to acquire, attest to, and leverage verifiable skills and competencies.
 *      It integrates dynamic skill dependencies, reputation-weighted attestations, a self-organizing knowledge graph,
 *      a marketplace for skill-gated tasks, and on-chain learning units.
 *      It aims to foster a self-evolving ecosystem for verifiable human capital.
 */
contract Aethelgard is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                            OUTLINE
    //////////////////////////////////////////////////////////////*/
    // I. Core Skill Management
    // II. Attestation & Proof-of-Skill
    // III. Reputation System
    // IV. Learning Units (NFTs - ERC721 Extension)
    // V. Skill-Gated Task Marketplace
    // VI. Governance & Treasury

    /*//////////////////////////////////////////////////////////////
                            FUNCTION SUMMARY
    //////////////////////////////////////////////////////////////*/

    // I. Core Skill Management
    // 1. registerSkill(string calldata _skillName, uint256[] calldata _prerequisites): Registers a new skill, setting its name and optional prerequisites. Only callable by governance.
    // 2. updateSkillPrerequisites(uint256 _skillId, uint256[] calldata _newPrerequisites): Updates the prerequisites for an existing skill. Only callable by governance.
    // 3. getSkillDetails(uint256 _skillId): Retrieves the name, prerequisites, existence status, and challenge activity of a specified skill.
    // 4. getSkillPrerequisites(uint256 _skillId): Retrieves only the prerequisite IDs for a given skill.
    // 5. hasSkill(address _user, uint256 _skillId): Checks if a user possesses a specific skill. This implies they have been attested or passed a challenge for it, and all its prerequisites (if any) were met at that time.

    // II. Attestation & Proof-of-Skill
    // 6. attestSkill(address _recipient, uint256 _skillId): Allows a registered verifier with sufficient reputation to attest to a recipient's skill. If prerequisites are met and no existing skill token, a skill token is "minted" for the recipient.
    // 7. revokeAttestation(address _recipient, uint256 _skillId): Allows an original verifier to revoke their attestation for a recipient's skill. This negatively impacts the verifier's reputation.
    // 8. submitProofOfChallenge(uint256 _skillId, bytes32 _proofHash): Allows a user to submit a proof for an on-chain skill challenge. If valid, the skill is granted, and a reward is distributed.
    // 9. setupSkillChallenge(uint256 _skillId, bytes32 _challengeRootHash, uint256 _rewardAmount): Sets up an on-chain challenge for a skill, depositing the reward. Only callable by governance.
    // 10. getAttestationsForSkill(address _user, uint256 _skillId): Retrieves an array of verifier addresses who have attested to a user's skill.
    // 11. getAttestationStrength(address _recipient, uint256 _skillId): Calculates the cumulative reputation-weighted strength of valid (not revoked) attestations for a user's skill.

    // III. Reputation System
    // 12. getReputation(address _user): Retrieves the current reputation score of a user.
    // 13. _updateReputationScore(address _user, int256 _reputationDelta): Internal function to adjust a user's reputation score. Called by various actions in the contract.
    // 14. registerVerifier(): Allows a user to self-register as a potential verifier, subject to meeting a minimum reputation threshold.

    // IV. Learning Units (NFTs - ERC721 Extension)
    // 15. mintLearningUnit(uint256 _skillId, string calldata _uri, uint256 _price): Mints a new ERC-721 "Learning Unit" token, associating it with a skill and setting its price.
    // 16. buyLearningUnit(uint256 _unitId): Allows a user to purchase a learning unit, transferring the unit's ownership and the price to the creator.
    // 17. getLearningUnitDetails(uint256 _unitId): Retrieves the skill ID, URI, price, and creator of a specified learning unit.
    // 18. getLearningUnitsForSkill(uint256 _skillId): Retrieves a list of Learning Unit token IDs associated with a specific skill.

    // V. Skill-Gated Task Marketplace
    // 19. createTask(uint256[] calldata _requiredSkills, string calldata _descriptionURI, uint256 _rewardAmount): Creates a new task, specifying required skills, a description URI, and a reward amount (deposited upon creation).
    // 20. applyForTask(uint256 _taskId): Allows a user to apply for a task, provided they possess all the required skills.
    // 21. assignTask(uint256 _taskId, address _assignee): The task creator assigns the task to one of the applicants.
    // 22. completeTask(uint256 _taskId): The task creator marks a task as complete, transferring the reward to the assigned individual and updating their reputation.
    // 23. getTaskDetails(uint256 _taskId): Retrieves all details for a specified task.

    // VI. Governance & Treasury
    // 24. proposeSkillGraphUpdate(uint256 _skillId, uint256[] calldata _newPrerequisites): Creates a governance proposal to update the prerequisites of a skill.
    // 25. proposeTreasuryWithdrawal(address _recipient, uint256 _amount): Creates a governance proposal to withdraw funds from the contract's treasury.
    // 26. proposeVerifierApproval(address _verifierCandidate): Creates a governance proposal to approve a user as a verifier.
    // 27. voteOnProposal(uint256 _proposalId, bool _approve): Allows users with sufficient reputation to vote on an active governance proposal. Votes are reputation-weighted.
    // 28. executeProposal(uint256 _proposalId): Executes a governance proposal that has passed and whose voting period has ended.
    // 29. _withdrawFunds(address _recipient, uint256 _amount): Internal function to withdraw funds from the contract treasury, callable only via a successful governance proposal.


    /*//////////////////////////////////////////////////////////////
                            DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct Skill {
        string name;
        uint256[] prerequisites; // IDs of skills required before this one
        bool exists;             // To check if skillId is valid
        bytes32 challengeRootHash; // For on-chain challenges: keccak256(abi.encodePacked(solution))
        uint256 challengeReward; // Reward for passing the challenge
        bool challengeActive;    // Is there an active challenge for this skill?
        uint256 attestationCount; // Total active (not revoked) attestations for this skill
    }

    struct Attestation {
        address verifier;
        uint256 timestamp;
        uint256 verifierReputationAtAttestation; // Snapshot reputation of verifier when attesting
        bool revoked;
    }

    struct UserProfile {
        uint256 reputationScore;
        bool isVerifier;
        // Add more user-specific data here if needed, e.g., display name, profile URI
    }

    struct LearningUnitData { // Data for a Learning Unit NFT
        uint256 skillId;
        string uri;
        uint256 price;
        address creator;
        uint256 mintTimestamp;
    }

    struct Task {
        address creator;
        uint256[] requiredSkills;
        string descriptionURI; // URI to IPFS or other decentralized storage for task details
        uint256 rewardAmount;    // In native currency (ETH)
        address assignedTo;
        bool completed;
        uint256 createTimestamp;
        address[] applicants;    // List of addresses who applied
        uint256 rewardDeposit;   // Actual ETH deposited for the reward
    }

    enum ProposalType {
        SkillGraphUpdate,
        TreasuryWithdrawal,
        RegisterVerifierApproval
    }

    struct Proposal {
        address proposer;
        ProposalType proposalType;
        uint256 targetSkillId;          // For SkillGraphUpdate
        uint256[] newPrerequisites;     // For SkillGraphUpdate
        address treasuryWithdrawRecipient; // For TreasuryWithdrawal
        uint256 treasuryWithdrawAmount; // For TreasuryWithdrawal
        address verifierCandidate;      // For RegisterVerifierApproval

        uint256 totalPositiveReputationVotes;
        uint256 totalNegativeReputationVotes;
        mapping(address => bool) hasVoted; // True if address has voted on this proposal
        bool executed;
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _skillIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _learningUnitIds; // ERC721 token IDs

    mapping(uint256 => Skill) public skills;
    mapping(address => mapping(uint256 => bool)) private _userHasSkill; // recipient => skillId => true if user possesses skill token (SBT)
    mapping(address => UserProfile) public userProfiles;
    // recipient => skillId => verifier => Attestation
    mapping(address => mapping(uint256 => mapping(address => Attestation))) private _skillAttestations;
    // recipient => skillId => list of verifiers who attested
    mapping(address => mapping(uint256 => address[])) private _attestedVerifiersList;

    uint256 public minReputationForAttestation = 100; // Minimum reputation for a user to attest to skills
    uint256 public constant INITIAL_REPUTATION = 1000;
    uint256 public constant REPUTATION_FOR_VALID_ATTESTATION = 50;
    uint256 public constant REPUTATION_PENALTY_FOR_REVOCATION = 100;
    uint256 public constant REPUTATION_FOR_TASK_COMPLETION = 200;
    uint256 public constant REPUTATION_FOR_CHALLENGE_PASS = 150;
    uint256 public constant MIN_REPUTATION_TO_PROPOSE = 500;
    uint256 public constant GOVERNANCE_VOTING_PERIOD = 7 days; // 7 days for proposals to be voted on
    uint256 public constant GOVERNANCE_MAJORITY_THRESHOLD_PERCENT = 50; // 50% majority needed for proposals

    mapping(uint256 => LearningUnitData) public learningUnits;
    mapping(uint256 => uint256[]) public learningUnitsBySkill; // skillId => array of learningUnitIds

    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Proposal) public proposals;

    event SkillRegistered(uint256 indexed skillId, string name, uint256[] prerequisites, address indexed creator);
    event SkillPrerequisitesUpdated(uint256 indexed skillId, uint256[] newPrerequisites, address indexed updater);
    event SkillAttested(address indexed recipient, uint256 indexed skillId, address indexed verifier, uint256 attestationStrength);
    event AttestationRevoked(address indexed recipient, uint256 indexed skillId, address indexed verifier);
    event ProofOfChallengeSubmitted(address indexed challenger, uint256 indexed skillId);
    event SkillChallengeSetup(uint256 indexed skillId, bytes32 challengeRootHash, uint256 rewardAmount, address indexed creator);
    event VerifierRegistered(address indexed verifier);
    event LearningUnitMinted(uint256 indexed unitId, uint256 indexed skillId, address indexed creator, uint256 price);
    event LearningUnitPurchased(uint256 indexed unitId, address indexed buyer, address indexed creator, uint256 price);
    event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount);
    event TaskApplied(uint256 indexed taskId, address indexed applicant);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee, uint256 rewardAmount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool approved, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    constructor() ERC721("Learning Unit NFT", "LUNIT") Ownable(msg.sender) {
        // Initialize the deployer with a substantial initial reputation and as a verifier
        userProfiles[msg.sender].reputationScore = INITIAL_REPUTATION;
        userProfiles[msg.sender].isVerifier = true;
    }

    // Allows the contract to receive native currency (ETH)
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            I. CORE SKILL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Registers a new skill with optional prerequisites.
     * @param _skillName The name of the skill.
     * @param _prerequisites An array of skill IDs that are prerequisites for this skill.
     * Requirements:
     * - Only callable by governance (initially owner, later via DAO).
     * - All prerequisite skill IDs must exist.
     */
    function registerSkill(string calldata _skillName, uint256[] calldata _prerequisites)
        external
        onlyOwner // For simplicity, assumes owner for now, can be transitioned to DAO via proposal.
    {
        for (uint256 i = 0; i < _prerequisites.length; i++) {
            require(skills[_prerequisites[i]].exists, "Aethelgard: Prerequisite skill does not exist");
        }

        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();

        skills[newSkillId] = Skill({
            name: _skillName,
            prerequisites: _prerequisites,
            exists: true,
            challengeRootHash: bytes32(0),
            challengeReward: 0,
            challengeActive: false,
            attestationCount: 0
        });

        emit SkillRegistered(newSkillId, _skillName, _prerequisites, msg.sender);
    }

    /**
     * @dev Updates the prerequisites for an existing skill.
     * @param _skillId The ID of the skill to update.
     * @param _newPrerequisites The new array of prerequisite skill IDs.
     * Requirements:
     * - Only callable by governance (initially owner, later via DAO proposal).
     * - Skill must exist.
     * - All new prerequisite skill IDs must exist.
     */
    function updateSkillPrerequisites(uint256 _skillId, uint256[] calldata _newPrerequisites)
        external
        onlyOwner // For simplicity, assumes owner for now, can be transitioned to DAO via proposal.
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");

        for (uint256 i = 0; i < _newPrerequisites.length; i++) {
            require(skills[_newPrerequisites[i]].exists, "Aethelgard: New prerequisite skill does not exist");
        }

        skills[_skillId].prerequisites = _newPrerequisites;
        emit SkillPrerequisitesUpdated(_skillId, _newPrerequisites, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific skill.
     * @param _skillId The ID of the skill.
     * @return name The name of the skill.
     * @return prerequisites The array of prerequisite skill IDs.
     * @return exists Whether the skill exists.
     * @return challengeActive Whether there's an active challenge for the skill.
     */
    function getSkillDetails(uint256 _skillId)
        public
        view
        returns (string memory name, uint256[] memory prerequisites, bool exists, bool challengeActive)
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        Skill storage skill = skills[_skillId];
        return (skill.name, skill.prerequisites, skill.exists, skill.challengeActive);
    }

    /**
     * @dev Retrieves only the prerequisite IDs for a given skill.
     * @param _skillId The ID of the skill.
     * @return The array of prerequisite skill IDs.
     */
    function getSkillPrerequisites(uint256 _skillId)
        public
        view
        returns (uint256[] memory)
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        return skills[_skillId].prerequisites;
    }

    /**
     * @dev Checks if a user possesses a specific skill.
     * This check implicitly considers prerequisites because skill tokens are only issued
     * if all prerequisites were met at the time of attestation or challenge completion.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return True if the user has the skill, false otherwise.
     */
    function hasSkill(address _user, uint256 _skillId)
        public
        view
        returns (bool)
    {
        return _userHasSkill[_user][_skillId];
    }

    /*//////////////////////////////////////////////////////////////
                            II. ATTESTATION & PROOF-OF-SKILL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows a registered verifier to attest to a recipient's skill.
     * If all prerequisites for the skill are met and the recipient doesn't yet hold the skill token,
     * the skill token is issued to them.
     * @param _recipient The address of the user receiving the attestation.
     * @param _skillId The ID of the skill being attested.
     * Requirements:
     * - msg.sender must be a registered verifier with sufficient reputation.
     * - Skill must exist.
     * - Recipient must meet all prerequisites for the skill.
     * - Verifier cannot attest to their own skill.
     * - Verifier can only attest once per skill for a given recipient.
     */
    function attestSkill(address _recipient, uint256 _skillId)
        external
        nonReentrant
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        require(userProfiles[msg.sender].isVerifier, "Aethelgard: Caller is not a registered verifier");
        require(userProfiles[msg.sender].reputationScore >= minReputationForAttestation, "Aethelgard: Verifier reputation too low");
        require(msg.sender != _recipient, "Aethelgard: Cannot attest to your own skill");
        require(_skillAttestations[_recipient][_skillId][msg.sender].verifier == address(0), "Aethelgard: Already attested to this skill for recipient");

        // Check prerequisites recursively. This function ensures the DAG structure before granting a skill.
        _checkPrerequisites(_recipient, _skillId);

        _skillAttestations[_recipient][_skillId][msg.sender] = Attestation({
            verifier: msg.sender,
            timestamp: block.timestamp,
            verifierReputationAtAttestation: userProfiles[msg.sender].reputationScore,
            revoked: false
        });

        _attestedVerifiersList[_recipient][_skillId].push(msg.sender); // Add verifier to the list
        skills[_skillId].attestationCount++;
        _updateReputationScore(msg.sender, int256(REPUTATION_FOR_VALID_ATTESTATION));

        // Issue skill token (SBT) if the recipient doesn't have it yet and prerequisites are met
        if (!_userHasSkill[_recipient][_skillId]) {
            _userHasSkill[_recipient][_skillId] = true;
        }

        emit SkillAttested(_recipient, _skillId, msg.sender, userProfiles[msg.sender].reputationScore);
    }

    /**
     * @dev Allows an original verifier to revoke their attestation for a recipient's skill.
     * This action will negatively impact the verifier's reputation.
     * @param _recipient The address of the user whose skill attestation is being revoked.
     * @param _skillId The ID of the skill.
     * Requirements:
     * - msg.sender must be the original verifier for the specific attestation.
     * - Attestation must exist and not already be revoked.
     */
    function revokeAttestation(address _recipient, uint256 _skillId)
        external
        nonReentrant
    {
        Attestation storage att = _skillAttestations[_recipient][_skillId][msg.sender];
        require(att.verifier == msg.sender, "Aethelgard: Not the original verifier");
        require(!att.revoked, "Aethelgard: Attestation already revoked");

        att.revoked = true;
        skills[_skillId].attestationCount--;
        _updateReputationScore(msg.sender, -int256(REPUTATION_PENALTY_FOR_REVOCATION));

        // Note: For simplicity, the verifier is not removed from `_attestedVerifiersList`.
        // `getAttestationStrength` correctly filters out revoked attestations.
        // If a true removal from the array is needed, it would involve more complex (and gas-intensive) array manipulation.

        emit AttestationRevoked(_recipient, _skillId, msg.sender);
    }

    /**
     * @dev Allows a user to submit a proof for an on-chain skill challenge.
     * If the proof is valid, the user is granted the skill and receives a reward.
     * @param _skillId The ID of the skill for which the challenge is being completed.
     * @param _proofHash The hash of the correct solution/proof (e.g., keccak256 of the answer).
     * Requirements:
     * - Skill must exist and have an active challenge.
     * - Submitted proof hash must match the challenge's root hash.
     * - User cannot have already completed this challenge or possess the skill.
     */
    function submitProofOfChallenge(uint256 _skillId, bytes32 _proofHash)
        external
        nonReentrant
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        require(skills[_skillId].challengeActive, "Aethelgard: No active challenge for this skill");
        require(skills[_skillId].challengeRootHash != bytes32(0), "Aethelgard: Challenge root hash not set");
        require(!_userHasSkill[msg.sender][_skillId], "Aethelgard: User already has this skill");

        // Simple comparison for on-chain proof. For complex proofs, this would involve ZK-proof verification.
        require(skills[_skillId].challengeRootHash == _proofHash, "Aethelgard: Invalid proof hash");

        _checkPrerequisites(msg.sender, _skillId); // Ensure prerequisites are met even for challenge

        _userHasSkill[msg.sender][_skillId] = true;
        _updateReputationScore(msg.sender, int256(REPUTATION_FOR_CHALLENGE_PASS));

        if (skills[_skillId].challengeReward > 0) {
            uint256 reward = skills[_skillId].challengeReward;
            skills[_skillId].challengeReward = 0; // Prevent multiple claims from the same challenge
            skills[_skillId].challengeActive = false; // Deactivate challenge after one successful claim, or keep active for multiple users
            
            // Send reward
            (bool success, ) = payable(msg.sender).call{value: reward}("");
            require(success, "Aethelgard: Failed to send challenge reward");
        }

        emit ProofOfChallengeSubmitted(msg.sender, _skillId);
    }

    /**
     * @dev Sets up an on-chain challenge for a specific skill.
     * This allows users to prove a skill by submitting a correct hash (e.g., solution to a puzzle).
     * @param _skillId The ID of the skill to attach the challenge to.
     * @param _challengeRootHash The keccak256 hash of the challenge's correct solution.
     * @param _rewardAmount The ETH reward for successfully completing the challenge.
     * Requirements:
     * - Only callable by governance (initially owner, later via DAO proposal).
     * - Skill must exist.
     * - No active challenge for this skill already.
     * - `_rewardAmount` must be sent with the transaction.
     */
    function setupSkillChallenge(uint256 _skillId, bytes32 _challengeRootHash, uint256 _rewardAmount)
        external
        payable
        onlyOwner // For simplicity, assumes owner for now, can be transitioned to DAO via proposal.
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        require(!skills[_skillId].challengeActive, "Aethelgard: Challenge already active for this skill");
        require(msg.value == _rewardAmount, "Aethelgard: Reward amount must match sent ETH");
        require(_challengeRootHash != bytes32(0), "Aethelgard: Challenge root hash cannot be zero");

        skills[_skillId].challengeRootHash = _challengeRootHash;
        skills[_skillId].challengeReward = _rewardAmount;
        skills[_skillId].challengeActive = true;

        emit SkillChallengeSetup(_skillId, _challengeRootHash, _rewardAmount, msg.sender);
    }

    /**
     * @dev Internal helper function to check if a user possesses all prerequisites for a skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill whose prerequisites are being checked.
     */
    function _checkPrerequisites(address _user, uint256 _skillId) private view {
        uint256[] memory prereqs = skills[_skillId].prerequisites;
        for (uint256 i = 0; i < prereqs.length; i++) {
            require(_userHasSkill[_user][prereqs[i]], string(abi.encodePacked("Aethelgard: Missing prerequisite skill ", Strings.toString(prereqs[i]))));
        }
    }

    /**
     * @dev Retrieves a list of verifier addresses who have attested to a user's specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return An array of verifier addresses.
     */
    function getAttestationsForSkill(address _user, uint256 _skillId)
        public
        view
        returns (address[] memory)
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        return _attestedVerifiersList[_user][_skillId];
    }

    /**
     * @dev Calculates the cumulative reputation-weighted strength of valid attestations for a user's skill.
     * @param _recipient The address of the user.
     * @param _skillId The ID of the skill.
     * @return The total reputation-weighted strength.
     */
    function getAttestationStrength(address _recipient, uint256 _skillId)
        public
        view
        returns (uint256)
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        uint256 totalStrength = 0;
        address[] memory verifiers = _attestedVerifiersList[_recipient][_skillId];

        for (uint256 i = 0; i < verifiers.length; i++) {
            Attestation storage att = _skillAttestations[_recipient][_skillId][verifiers[i]];
            if (!att.revoked) {
                totalStrength += att.verifierReputationAtAttestation;
            }
        }
        return totalStrength;
    }

    /*//////////////////////////////////////////////////////////////
                            III. REPUTATION SYSTEM
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Retrieves the current reputation score of a user.
     * @param _user The address of the user.
     * @return The current reputation score.
     */
    function getReputation(address _user)
        public
        view
        returns (uint256)
    {
        return userProfiles[_user].reputationScore;
    }

    /**
     * @dev Internal function to adjust a user's reputation score.
     * Only callable by the contract's internal logic.
     * @param _user The address of the user whose reputation is being adjusted.
     * @param _reputationDelta The change in reputation (can be positive or negative).
     */
    function _updateReputationScore(address _user, int256 _reputationDelta)
        internal
    {
        int256 currentScore = int256(userProfiles[_user].reputationScore);
        currentScore += _reputationDelta;
        if (currentScore < 0) {
            currentScore = 0; // Reputation cannot go below zero
        }
        userProfiles[_user].reputationScore = uint256(currentScore);
    }

    /**
     * @dev Allows a user to express interest in becoming a registered verifier.
     * This requires a minimum reputation score. Alternatively, a governance proposal can approve a verifier.
     */
    function registerVerifier()
        external
        nonReentrant
    {
        require(userProfiles[msg.sender].reputationScore >= minReputationForAttestation, "Aethelgard: Insufficient reputation to self-register as verifier");        
        require(!userProfiles[msg.sender].isVerifier, "Aethelgard: User is already a registered verifier");
        userProfiles[msg.sender].isVerifier = true;
        emit VerifierRegistered(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            IV. LEARNING UNITS (NFTs - ERC721 Extension)
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints a new ERC-721 "Learning Unit" token.
     * This unit is associated with a specific skill and has a price.
     * @param _skillId The ID of the skill this learning unit teaches or is related to.
     * @param _uri The URI to the learning content (e.g., IPFS hash).
     * @param _price The price of the learning unit in native currency (ETH).
     * Requirements:
     * - Skill must exist.
     */
    function mintLearningUnit(uint256 _skillId, string calldata _uri, uint256 _price)
        external
        nonReentrant
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");

        _learningUnitIds.increment();
        uint256 newItemId = _learningUnitIds.current();

        _safeMint(msg.sender, newItemId); // Mints the ERC721 to the creator

        learningUnits[newItemId] = LearningUnitData({
            skillId: _skillId,
            uri: _uri,
            price: _price,
            creator: msg.sender,
            mintTimestamp: block.timestamp
        });

        learningUnitsBySkill[_skillId].push(newItemId);

        emit LearningUnitMinted(newItemId, _skillId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to purchase a learning unit.
     * Transfers the learning unit (NFT) ownership to the buyer and the price to the creator.
     * @param _unitId The ID of the learning unit to purchase.
     * Requirements:
     * - Learning unit must exist.
     * - `msg.value` must match the unit's price.
     */
    function buyLearningUnit(uint256 _unitId)
        external
        payable
        nonReentrant
    {
        LearningUnitData storage unit = learningUnits[_unitId];
        require(unit.creator != address(0), "Aethelgard: Learning unit does not exist");
        require(msg.value == unit.price, "Aethelgard: Incorrect ETH amount sent");
        require(msg.sender != unit.creator, "Aethelgard: Cannot buy your own learning unit");

        address creator = unit.creator;
        _transfer(creator, msg.sender, _unitId); // Transfer NFT ownership
        
        // Transfer funds to creator
        (bool success, ) = payable(creator).call{value: msg.value}("");
        require(success, "Aethelgard: Failed to send payment to creator");

        emit LearningUnitPurchased(_unitId, msg.sender, creator, unit.price);
    }

    /**
     * @dev Retrieves the details of a specific learning unit.
     * @param _unitId The ID of the learning unit.
     * @return skillId The ID of the associated skill.
     * @return uri The URI to the content.
     * @return price The price of the unit.
     * @return creator The address of the unit's creator.
     */
    function getLearningUnitDetails(uint256 _unitId)
        public
        view
        returns (uint256 skillId, string memory uri, uint256 price, address creator)
    {
        LearningUnitData storage unit = learningUnits[_unitId];
        require(unit.creator != address(0), "Aethelgard: Learning unit does not exist");
        return (unit.skillId, unit.uri, unit.price, unit.creator);
    }

    /**
     * @dev Retrieves a list of Learning Unit token IDs associated with a specific skill.
     * @param _skillId The ID of the skill.
     * @return An array of learning unit IDs.
     */
    function getLearningUnitsForSkill(uint256 _skillId)
        public
        view
        returns (uint256[] memory)
    {
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        return learningUnitsBySkill[_skillId];
    }

    /*//////////////////////////////////////////////////////////////
                            V. SKILL-GATED TASK MARKETPLACE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new task, specifying required skills, a description URI, and a reward.
     * The reward amount must be sent with the transaction and is held by the contract.
     * @param _requiredSkills An array of skill IDs required to apply for this task.
     * @param _descriptionURI The URI to the task's detailed description.
     * @param _rewardAmount The reward for completing the task (in native currency).
     * Requirements:
     * - All required skill IDs must exist.
     * - `msg.value` must match `_rewardAmount`.
     */
    function createTask(uint256[] calldata _requiredSkills, string calldata _descriptionURI, uint256 _rewardAmount)
        external
        payable
        nonReentrant
    {
        require(msg.value == _rewardAmount, "Aethelgard: Reward amount must match sent ETH");
        require(_rewardAmount > 0, "Aethelgard: Reward must be greater than zero");

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            require(skills[_requiredSkills[i]].exists, "Aethelgard: Required skill does not exist");
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            creator: msg.sender,
            requiredSkills: _requiredSkills,
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            assignedTo: address(0),
            completed: false,
            createTimestamp: block.timestamp,
            applicants: new address[](0), // Initialize empty array
            rewardDeposit: msg.value
        });

        emit TaskCreated(newTaskId, msg.sender, _rewardAmount);
    }

    /**
     * @dev Allows a user to apply for a task if they possess all the required skills.
     * @param _taskId The ID of the task to apply for.
     * Requirements:
     * - Task must exist and not be assigned or completed.
     * - `msg.sender` must possess all required skills for the task.
     * - `msg.sender` must not have already applied.
     */
    function applyForTask(uint256 _taskId)
        external
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Aethelgard: Task does not exist");
        require(task.assignedTo == address(0), "Aethelgard: Task is already assigned");
        require(!task.completed, "Aethelgard: Task is already completed");

        // Check if user already applied
        bool alreadyApplied = false;
        for (uint256 i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == msg.sender) {
                alreadyApplied = true;
                break;
            }
        }
        require(!alreadyApplied, "Aethelgard: Already applied for this task");

        for (uint256 i = 0; i < task.requiredSkills.length; i++) {
            require(hasSkill(msg.sender, task.requiredSkills[i]), "Aethelgard: Missing required skill for this task");
        }

        task.applicants.push(msg.sender);
        emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @dev The task creator assigns the task to one of the applicants.
     * @param _taskId The ID of the task.
     * @param _assignee The address of the applicant to assign the task to.
     * Requirements:
     * - `msg.sender` must be the task creator.
     * - Task must exist and not be assigned or completed.
     * - `_assignee` must be an applicant for the task.
     */
    function assignTask(uint256 _taskId, address _assignee)
        external
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Aethelgard: Task does not exist");
        require(msg.sender == task.creator, "Aethelgard: Only task creator can assign");
        require(task.assignedTo == address(0), "Aethelgard: Task is already assigned");
        require(!task.completed, "Aethelgard: Task is already completed");

        bool isApplicant = false;
        for (uint256 i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == _assignee) {
                isApplicant = true;
                break;
            }
        }
        require(isApplicant, "Aethelgard: Assignee is not an applicant for this task");

        task.assignedTo = _assignee;
        emit TaskAssigned(_taskId, _assignee);
    }

    /**
     * @dev The task creator marks a task as complete, transferring the reward to the assigned individual.
     * @param _taskId The ID of the task.
     * Requirements:
     * - `msg.sender` must be the task creator.
     * - Task must exist, be assigned, and not be completed.
     */
    function completeTask(uint256 _taskId)
        external
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Aethelgard: Task does not exist");
        require(msg.sender == task.creator, "Aethelgard: Only task creator can complete");
        require(task.assignedTo != address(0), "Aethelgard: Task is not assigned");
        require(!task.completed, "Aethelgard: Task is already completed");

        task.completed = true;
        _updateReputationScore(task.assignedTo, int256(REPUTATION_FOR_TASK_COMPLETION));

        // Transfer reward to assignee
        (bool success, ) = payable(task.assignedTo).call{value: task.rewardAmount}("");
        require(success, "Aethelgard: Failed to send task reward");
        
        // Reset reward deposit as it's now disbursed
        task.rewardDeposit = 0;

        emit TaskCompleted(_taskId, task.assignedTo, task.rewardAmount);
    }

    /**
     * @dev Retrieves all details for a specified task.
     * @param _taskId The ID of the task.
     * @return creator The address of the task creator.
     * @return requiredSkills An array of required skill IDs.
     * @return descriptionURI The URI to the task description.
     * @return rewardAmount The reward for the task.
     * @return assignedTo The address of the assignee.
     * @return completed Whether the task is completed.
     * @return createTimestamp The timestamp of creation.
     * @return applicants An array of addresses that applied for the task.
     */
    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (address creator, uint256[] memory requiredSkills, string memory descriptionURI, uint256 rewardAmount, address assignedTo, bool completed, uint256 createTimestamp, address[] memory applicants)
    {
        Task storage task = tasks[_taskId];
        require(task.creator != address(0), "Aethelgard: Task does not exist");
        return (task.creator, task.requiredSkills, task.descriptionURI, task.rewardAmount, task.assignedTo, task.completed, task.createTimestamp, task.applicants);
    }

    /*//////////////////////////////////////////////////////////////
                            VI. GOVERNANCE & TREASURY
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows users with sufficient reputation to propose an update to a skill's prerequisites.
     * @param _skillId The ID of the skill whose prerequisites are proposed to be updated.
     * @param _newPrerequisites The new array of prerequisite skill IDs.
     * Requirements:
     * - `msg.sender` must meet minimum reputation to propose.
     * - Skill must exist.
     * - All `_newPrerequisites` must exist.
     */
    function proposeSkillGraphUpdate(uint256 _skillId, uint256[] calldata _newPrerequisites)
        external
        nonReentrant
    {
        require(userProfiles[msg.sender].reputationScore >= MIN_REPUTATION_TO_PROPOSE, "Aethelgard: Insufficient reputation to propose");
        require(skills[_skillId].exists, "Aethelgard: Skill does not exist");
        for (uint256 i = 0; i < _newPrerequisites.length; i++) {
            require(skills[_newPrerequisites[i]].exists, "Aethelgard: Proposed prerequisite skill does not exist");
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.SkillGraphUpdate,
            targetSkillId: _skillId,
            newPrerequisites: _newPrerequisites,
            treasuryWithdrawRecipient: address(0),
            treasuryWithdrawAmount: 0,
            verifierCandidate: address(0),
            totalPositiveReputationVotes: 0,
            totalNegativeReputationVotes: 0,
            executed: false,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            hasVoted: new mapping(address => bool)() // Initialize mapping within struct
        });

        emit ProposalCreated(newProposalId, msg.sender, ProposalType.SkillGraphUpdate);
    }

    /**
     * @dev Proposes a treasury withdrawal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of funds to withdraw.
     * Requirements:
     * - `msg.sender` must meet minimum reputation to propose.
     * - Amount must be greater than zero.
     * - Contract must hold sufficient funds.
     */
    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount)
        external
        nonReentrant
    {
        require(userProfiles[msg.sender].reputationScore >= MIN_REPUTATION_TO_PROPOSE, "Aethelgard: Insufficient reputation to propose");
        require(_amount > 0, "Aethelgard: Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "Aethelgard: Insufficient contract balance");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.TreasuryWithdrawal,
            targetSkillId: 0, // Not applicable
            newPrerequisites: new uint256[](0), // Not applicable
            treasuryWithdrawRecipient: _recipient,
            treasuryWithdrawAmount: _amount,
            verifierCandidate: address(0),
            totalPositiveReputationVotes: 0,
            totalNegativeReputationVotes: 0,
            executed: false,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            hasVoted: new mapping(address => bool)()
        });

        emit ProposalCreated(newProposalId, msg.sender, ProposalType.TreasuryWithdrawal);
    }

    /**
     * @dev Proposes to approve a user as a verifier.
     * @param _verifierCandidate The address of the user to propose as a verifier.
     * Requirements:
     * - `msg.sender` must meet minimum reputation to propose.
     * - `_verifierCandidate` must not already be a verifier.
     */
    function proposeVerifierApproval(address _verifierCandidate)
        external
        nonReentrant
    {
        require(userProfiles[msg.sender].reputationScore >= MIN_REPUTATION_TO_PROPOSE, "Aethelgard: Insufficient reputation to propose");
        require(!userProfiles[_verifierCandidate].isVerifier, "Aethelgard: Candidate is already a verifier");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            proposalType: ProposalType.RegisterVerifierApproval,
            targetSkillId: 0, // Not applicable
            newPrerequisites: new uint256[](0), // Not applicable
            treasuryWithdrawRecipient: address(0),
            treasuryWithdrawAmount: 0,
            verifierCandidate: _verifierCandidate,
            totalPositiveReputationVotes: 0,
            totalNegativeReputationVotes: 0,
            executed: false,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            hasVoted: new mapping(address => bool)()
        });

        emit ProposalCreated(newProposalId, msg.sender, ProposalType.RegisterVerifierApproval);
    }

    /**
     * @dev Allows users with sufficient reputation to vote on an active governance proposal.
     * Votes are weighted by the voter's current reputation score.
     * @param _proposalId The ID of the proposal.
     * @param _approve True for an 'approve' vote, false for 'disapprove'.
     * Requirements:
     * - Proposal must exist and be active.
     * - `msg.sender` must not have already voted on this proposal.
     * - `msg.sender` must have a reputation score greater than 0.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve)
        external
        nonReentrant
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Aethelgard: Proposal does not exist");
        require(block.timestamp <= proposal.expirationTimestamp, "Aethelgard: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Aethelgard: Already voted on this proposal");
        require(userProfiles[msg.sender].reputationScore > 0, "Aethelgard: Voter must have reputation");

        uint256 voterReputation = userProfiles[msg.sender].reputationScore;
        if (_approve) {
            proposal.totalPositiveReputationVotes += voterReputation;
        } else {
            proposal.totalNegativeReputationVotes += voterReputation;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _approve, voterReputation);
    }

    /**
     * @dev Executes a governance proposal that has passed and whose voting period has ended.
     * Requirements:
     * - Proposal must exist and its voting period must have ended.
     * - Proposal must not have been executed already.
     * - Proposal must have passed the majority threshold based on reputation-weighted votes.
     */
    function executeProposal(uint256 _proposalId)
        external
        nonReentrant
        onlyOwner // For initial setup, only owner can execute. Can be transitioned to automated or role-based execution later.
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Aethelgard: Proposal does not exist");
        require(block.timestamp > proposal.expirationTimestamp, "Aethelgard: Voting period has not ended");
        require(!proposal.executed, "Aethelgard: Proposal already executed");

        uint256 totalVotes = proposal.totalPositiveReputationVotes + proposal.totalNegativeReputationVotes;
        require(totalVotes > 0, "Aethelgard: No votes cast for this proposal");

        // Simple majority based on reputation-weighted votes
        bool passed = (proposal.totalPositiveReputationVotes * 100) / totalVotes >= GOVERNANCE_MAJORITY_THRESHOLD_PERCENT;

        if (passed) {
            proposal.executed = true;
            if (proposal.proposalType == ProposalType.SkillGraphUpdate) {
                // Call the internal/governance-only skill update function
                skills[proposal.targetSkillId].prerequisites = proposal.newPrerequisites;
                emit SkillPrerequisitesUpdated(proposal.targetSkillId, proposal.newPrerequisites, address(this));
            } else if (proposal.proposalType == ProposalType.TreasuryWithdrawal) {
                _withdrawFunds(proposal.treasuryWithdrawRecipient, proposal.treasuryWithdrawAmount);
            } else if (proposal.proposalType == ProposalType.RegisterVerifierApproval) {
                userProfiles[proposal.verifierCandidate].isVerifier = true;
                emit VerifierRegistered(proposal.verifierCandidate);
            }
            emit ProposalExecuted(_proposalId, true);
        } else {
            emit ProposalExecuted(_proposalId, false);
        }
    }
    
    /**
     * @dev Internal function to withdraw funds from the contract treasury.
     * Only callable by a successful governance proposal.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of funds to withdraw.
     * Requirements:
     * - Contract must hold sufficient funds.
     */
    function _withdrawFunds(address _recipient, uint256 _amount)
        internal
    {
        require(address(this).balance >= _amount, "Aethelgard: Insufficient contract balance for withdrawal");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Aethelgard: Failed to withdraw funds");
        emit FundsWithdrawn(_recipient, _amount);
    }
}
```