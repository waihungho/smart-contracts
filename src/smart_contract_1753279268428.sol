This smart contract, **SkillForge**, is a decentralized credentialing and opportunity network. It enables users to build verifiable skill profiles, receive attestations from others, participate in a challenge system to ensure data integrity, earn Soulbound Tokens (SBTs) for verified skills, and connect with project opportunities. A key advanced concept is its conceptual integration with an AI oracle, allowing for AI-driven skill matching or attestation scoring, where the AI's results are submitted on-chain for verification or action.

---

## SkillForge Smart Contract

**Outline:**

The contract is structured into several logical modules:

1.  **Core Configuration & Management**: Handles contract ownership, pausing, and setting global parameters like fees and oracle addresses.
2.  **User & Skill Profile Management**: Allows users to register, update their profiles, and for administrators to define canonical skills.
3.  **Attestation & Reputation System**: The core mechanism for users to attest to others' skills, and for a challenge system to dispute false attestations, impacting reputation.
4.  **SkillBound Token (SBT) Management**: Implements a custom non-transferable token standard for issuing verifiable skill credentials (SBTs) based on reputation and successful attestations.
5.  **Opportunity Board & Project Management**: A marketplace where requesters can post projects/bounties, and skilled users can apply, get assigned, and submit work for verification and payment.
6.  **AI Oracle Integration (Conceptual)**: Provides an interface for off-chain AI services to interact with the contract, requesting data or submitting processed results (e.g., for skill matching or fraud detection).
7.  **Internal & Utility Functions**: Helper functions and view functions for retrieving data.

---

**Function Summary:**

1.  **`constructor()`**: Initializes the contract with an owner and default fees.
2.  **`setAttestationFee(uint256 _newFee)`**: Sets the fee required to submit a skill attestation.
3.  **`setChallengeStake(uint256 _newStake)`**: Sets the stake required to challenge an attestation.
4.  **`setOpportunityPostFee(uint256 _newFee)`**: Sets the fee for posting a new opportunity.
5.  **`setAIOperator(address _aiOperator)`**: Sets the trusted address of the AI oracle operator.
6.  **`pauseContract()`**: Pauses all core functionalities of the contract (admin only).
7.  **`unpauseContract()`**: Unpauses the contract, re-enabling functionalities (admin only).
8.  **`registerUser(string calldata _name, string calldata _bio)`**: Allows a new user to register their profile on the network.
9.  **`updateUserProfile(string calldata _newName, string calldata _newBio)`**: Allows a registered user to update their profile details.
10. **`getUserProfile(address _userAddress)`**: Retrieves the profile details of a specified user.
11. **`addSkillDefinition(string calldata _name, string calldata _description)`**: Adds a new canonical skill definition to the system (admin only).
12. **`getSkillDefinition(uint256 _skillId)`**: Retrieves the details of a specific skill definition.
13. **`claimSkill(uint256 _skillId)`**: Allows a user to declare that they possess a particular skill.
14. **`attestSkill(address _subject, uint256 _skillId, uint256 _strength)`**: Allows a user to attest to another user's proficiency in a specific skill, requiring a fee.
15. **`getAttestation(uint256 _attestationId)`**: Retrieves the details of a specific attestation.
16. **`getAttestationsForUser(address _userAddress)`**: Retrieves a list of all attestations received by a user.
17. **`getAttestationsByAttestor(address _attestorAddress)`**: Retrieves a list of all attestations given by a user.
18. **`challengeAttestation(uint256 _attestationId, string calldata _reason)`**: Allows a user to challenge the validity of an attestation, requiring a stake.
19. **`resolveChallenge(uint256 _challengeId, bool _challengerWins)`**: Resolves a challenge, determining the winner, adjusting reputation, and distributing stakes (admin only).
20. **`getChallenge(uint256 _challengeId)`**: Retrieves the details of a specific challenge.
21. **`getReputation(address _userAddress)`**: Calculates and returns the current reputation score for a user.
22. **`mintSkillSBT(address _recipient, uint256 _skillId)`**: Mints a Soulbound Token (SBT) for a user for a specific skill (typically triggered internally by reputation/attestation thresholds, but callable by owner for demonstration).
23. **`getSkillSBTsForUser(address _owner)`**: Retrieves a list of Skill SBT IDs owned by a user.
24. **`postOpportunity(string calldata _title, string calldata _description, uint256[] calldata _requiredSkillIds, uint256 _bountyAmount)`**: Allows a requester to post a new project opportunity with a bounty, requiring a fee.
25. **`applyForOpportunity(uint256 _opportunityId)`**: Allows a user to apply for a posted opportunity.
26. **`assignOpportunity(uint256 _opportunityId, address _worker)`**: Allows the requester to assign an applicant to their opportunity.
27. **`submitOpportunityCompletion(uint256 _opportunityId, string calldata _proofUrl)`**: Allows the assigned worker to submit proof of completion for an opportunity.
28. **`verifyOpportunityCompletion(uint256 _opportunityId)`**: Allows the requester to verify the completion of an opportunity and release the bounty to the worker.
29. **`cancelOpportunity(uint256 _opportunityId)`**: Allows the requester to cancel an unassigned opportunity.
30. **`getOpportunity(uint256 _opportunityId)`**: Retrieves the details of a specific opportunity.
31. **`requestAISkillMatch(address _userAddress, uint256 _contextType)`**: Emits an event to signal an off-chain AI oracle to perform a skill matching operation for a user.
32. **`submitAIResult(uint256 _requestId, address _targetAddress, uint256 _dataType, bytes32 _dataHash)`**: Allows the trusted AI oracle to submit the result of an off-chain AI operation back to the contract.
33. **`withdrawContractBalance()`**: Allows the owner to withdraw accumulated fees from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SkillForge - Decentralized Credentialing and Opportunity Network
 * @dev This contract facilitates a decentralized system for skill attestation, reputation building,
 *      Soulbound Token (SBT) issuance for verified skills, and an opportunity marketplace.
 *      It conceptually integrates with an off-chain AI oracle for advanced functionalities.
 */
contract SkillForge is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum AttestationStatus { Pending, Verified, Challenged, Revoked }
    enum OpportunityStatus { Open, Applied, Assigned, Completed, Verified, Cancelled }
    enum ChallengeStatus { Pending, Approved, Rejected }
    enum AIContextType { SkillMatch, AttestationQuality } // Types of AI requests

    // --- Structs ---

    struct User {
        string name;
        string bio;
        bool isRegistered;
        uint256 reputation; // Accumulated reputation score
        uint256[] claimedSkills; // IDs of skills user claims to have
        uint256[] receivedAttestations; // IDs of attestations received
        uint256[] givenAttestations;    // IDs of attestations given
        uint256[] skillSBTs; // IDs of SkillBound Tokens owned
        uint256[] appliedOpportunities; // IDs of opportunities applied for
    }

    struct Skill {
        string name;
        string description;
        bool isDefined;
    }

    struct Attestation {
        address attestor;     // The user providing the attestation
        address subject;      // The user being attested for
        uint256 skillId;      // The ID of the skill being attested
        uint256 strength;     // Attestation strength (e.g., 1-100)
        uint256 timestamp;    // When the attestation was made
        AttestationStatus status; // Current status (Pending, Verified, Challenged, Revoked)
        uint256 challengeId; // ID of the associated challenge if status is Challenged
    }

    // A lightweight Soulbound Token struct. Not a full ERC721, but tracks ownership and non-transferability.
    // Full ERC721 compliance would involve more overhead, this illustrates the SBT concept simply.
    struct SkillBoundToken {
        uint256 sbtId; // Unique ID for this specific SBT instance
        uint256 skillId; // The skill this SBT represents
        address owner;   // The user who owns this SBT (non-transferable)
        uint256 mintTimestamp;
    }

    struct Opportunity {
        address poster;
        string title;
        string description;
        uint256[] requiredSkillIds;
        uint256 bountyAmount; // In Wei
        uint256 timestamp;
        OpportunityStatus status;
        address assignedWorker;
        string completionProofUrl;
    }

    struct Challenge {
        address challenger;
        uint256 attestationId;
        string reason;
        uint256 timestamp;
        ChallengeStatus status;
        uint256 stakeAmount;
        address winner; // Challenger or Attestor
    }

    // --- State Variables ---

    mapping(address => User) public users;
    mapping(uint256 => Skill) public skills; // skillId => Skill Definition
    mapping(uint256 => Attestation) public attestations; // attestationId => Attestation
    mapping(uint256 => SkillBoundToken) public skillSBTs; // sbtId => SkillBoundToken instance
    mapping(uint256 => Opportunity) public opportunities; // opportunityId => Opportunity
    mapping(uint256 => Challenge) public challenges; // challengeId => Challenge

    uint256 public nextSkillId;
    uint256 public nextAttestationId;
    uint256 public nextSBTId;
    uint256 public nextOpportunityId;
    uint256 public nextChallengeId;
    uint256 public nextAIRequestId;

    address public aiOracleAddress; // Address of a trusted AI oracle

    uint256 public attestationFee;    // Fee for creating an attestation
    uint256 public challengeStake;    // Stake required to challenge an attestation
    uint256 public opportunityPostFee; // Fee for posting an opportunity

    // Thresholds for minting SBTs (e.g., minimum strength score, minimum number of attestations)
    uint256 public constant MIN_SBT_STRENGTH_THRESHOLD = 75; // Average strength needed
    uint256 public constant MIN_SBT_ATTESTATION_COUNT = 3;   // Min attestations needed

    // Reputation modifiers
    uint256 public constant REPUTATION_PER_VERIFIED_ATTESTATION = 10;
    uint256 public constant REPUTATION_LOSS_CHALLENGE_LOST = 20;
    uint256 public constant REPUTATION_GAIN_CHALLENGE_WON = 15;
    uint256 public constant REPUTATION_PER_OPPORTUNITY_COMPLETED = 50;

    // --- Events ---

    event UserRegistered(address indexed userAddress, string name);
    event UserProfileUpdated(address indexed userAddress, string newName);
    event SkillDefinitionAdded(uint256 indexed skillId, string name);
    event SkillClaimed(address indexed userAddress, uint256 indexed skillId);

    event SkillAttested(uint256 indexed attestationId, address indexed subject, address indexed attestor, uint256 indexed skillId, uint256 strength);
    event AttestationChallenged(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger);
    event AttestationResolved(uint256 indexed attestationId, AttestationStatus newStatus, address indexed resolver, bool challengerWon);

    event SkillSBTMinted(uint256 indexed sbtId, address indexed recipient, uint256 indexed skillId, string skillName);

    event OpportunityPosted(uint256 indexed opportunityId, address indexed poster, string title, uint256 bounty);
    event OpportunityApplied(uint256 indexed opportunityId, address indexed applicant);
    event OpportunityAssigned(uint256 indexed opportunityId, address indexed worker);
    event OpportunityCompletionSubmitted(uint256 indexed opportunityId, address indexed worker, string proofUrl);
    event OpportunityVerified(uint256 indexed opportunityId, address indexed verifier, address indexed worker, uint256 bountyAmount);
    event OpportunityCancelled(uint256 indexed opportunityId, address indexed poster);

    event AIRequestSent(uint256 indexed requestId, address indexed userAddress, uint256 indexed contextType);
    event AIResultReceived(uint256 indexed requestId, address indexed targetAddress, uint256 indexed dataType, bytes32 indexed dataHash);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        attestationFee = 0.001 ether; // Default fee
        challengeStake = 0.005 ether; // Default stake
        opportunityPostFee = 0.002 ether; // Default fee
    }

    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(users[msg.sender].isRegistered, "SkillForge: Caller is not a registered user");
        _;
    }

    modifier onlyAIOperator() {
        require(msg.sender == aiOracleAddress, "SkillForge: Caller is not the AI Oracle operator");
        _;
    }

    // --- Core Management & Configuration (6 Functions) ---

    /**
     * @dev Sets the fee required to submit a skill attestation.
     * @param _newFee The new attestation fee in Wei.
     */
    function setAttestationFee(uint256 _newFee) external onlyOwner {
        attestationFee = _newFee;
    }

    /**
     * @dev Sets the stake required to challenge an attestation. This stake is returned to the winner of the challenge.
     * @param _newStake The new challenge stake in Wei.
     */
    function setChallengeStake(uint256 _newStake) external onlyOwner {
        challengeStake = _newStake;
    }

    /**
     * @dev Sets the fee for posting a new opportunity on the board.
     * @param _newFee The new opportunity posting fee in Wei.
     */
    function setOpportunityPostFee(uint256 _newFee) external onlyOwner {
        opportunityPostFee = _newFee;
    }

    /**
     * @dev Sets the trusted address of the off-chain AI oracle operator.
     *      This address will be authorized to submit AI-processed results.
     * @param _aiOperator The address of the AI oracle.
     */
    function setAIOperator(address _aiOperator) external onlyOwner {
        require(_aiOperator != address(0), "SkillForge: AI Operator cannot be zero address");
        aiOracleAddress = _aiOperator;
    }

    /**
     * @dev Pauses all core functionalities of the contract.
     *      Only the owner can call this.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling functionalities.
     *      Only the owner can call this.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- User & Skill Profile Management (6 Functions) ---

    /**
     * @dev Allows a new user to register their profile on the network.
     *      A user can only register once.
     * @param _name The name of the user.
     * @param _bio A short biography or description of the user.
     */
    function registerUser(string calldata _name, string calldata _bio) external whenNotPaused {
        require(!users[msg.sender].isRegistered, "SkillForge: User already registered");
        require(bytes(_name).length > 0, "SkillForge: Name cannot be empty");

        users[msg.sender].name = _name;
        users[msg.sender].bio = _bio;
        users[msg.sender].isRegistered = true;
        users[msg.sender].reputation = 0; // Initialize reputation

        emit UserRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a registered user to update their profile details.
     * @param _newName The new name for the user's profile.
     * @param _newBio The new biography for the user's profile.
     */
    function updateUserProfile(string calldata _newName, string calldata _newBio) external onlyRegisteredUser whenNotPaused {
        require(bytes(_newName).length > 0, "SkillForge: New name cannot be empty");

        users[msg.sender].name = _newName;
        users[msg.sender].bio = _newBio;

        emit UserProfileUpdated(msg.sender, _newName);
    }

    /**
     * @dev Retrieves the profile details of a specified user.
     * @param _userAddress The address of the user to retrieve.
     * @return name, bio, isRegistered, reputation, claimedSkills, receivedAttestations, givenAttestations, skillSBTs, appliedOpportunities.
     */
    function getUserProfile(address _userAddress) external view returns (string memory name, string memory bio, bool isRegistered, uint256 reputation, uint256[] memory claimedSkills, uint256[] memory receivedAttestations, uint256[] memory givenAttestations, uint256[] memory skillSBTs, uint256[] memory appliedOpportunities) {
        User storage user = users[_userAddress];
        require(user.isRegistered, "SkillForge: User not registered");
        return (user.name, user.bio, user.isRegistered, user.reputation, user.claimedSkills, user.receivedAttestations, user.givenAttestations, user.skillSBTs, user.appliedOpportunities);
    }

    /**
     * @dev Adds a new canonical skill definition to the system. Only the owner can define new skills.
     * @param _name The name of the skill (e.g., "Solidity Development", "Project Management").
     * @param _description A detailed description of the skill.
     * @return The ID of the newly added skill.
     */
    function addSkillDefinition(string calldata _name, string calldata _description) external onlyOwner returns (uint256) {
        require(bytes(_name).length > 0, "SkillForge: Skill name cannot be empty");
        uint256 skillId = nextSkillId++;
        skills[skillId] = Skill(_name, _description, true);
        emit SkillDefinitionAdded(skillId, _name);
        return skillId;
    }

    /**
     * @dev Retrieves the details of a specific skill definition.
     * @param _skillId The ID of the skill to retrieve.
     * @return name, description, isDefined.
     */
    function getSkillDefinition(uint256 _skillId) external view returns (string memory name, string memory description, bool isDefined) {
        require(skills[_skillId].isDefined, "SkillForge: Skill definition does not exist");
        return (skills[_skillId].name, skills[_skillId].description, skills[_skillId].isDefined);
    }

    /**
     * @dev Allows a user to declare that they possess a particular skill.
     *      This is a self-claim, not an attestation from others.
     * @param _skillId The ID of the skill the user claims.
     */
    function claimSkill(uint256 _skillId) external onlyRegisteredUser whenNotPaused {
        require(skills[_skillId].isDefined, "SkillForge: Skill does not exist");

        // Check if skill is already claimed
        for (uint256 i = 0; i < users[msg.sender].claimedSkills.length; i++) {
            if (users[msg.sender].claimedSkills[i] == _skillId) {
                revert("SkillForge: Skill already claimed by user");
            }
        }

        users[msg.sender].claimedSkills.push(_skillId);
        emit SkillClaimed(msg.sender, _skillId);
    }

    // --- Attestation & Reputation System (8 Functions) ---

    /**
     * @dev Allows a user to attest to another user's proficiency in a specific skill.
     *      Requires payment of `attestationFee`. Attestors and subjects must be registered.
     * @param _subject The address of the user being attested for.
     * @param _skillId The ID of the skill being attested.
     * @param _strength The strength of the attestation (1-100, where 100 is highly proficient).
     */
    function attestSkill(address _subject, uint256 _skillId, uint256 _strength) external payable onlyRegisteredUser whenNotPaused {
        require(msg.sender != _subject, "SkillForge: Cannot attest to your own skill");
        require(users[_subject].isRegistered, "SkillForge: Subject is not a registered user");
        require(skills[_skillId].isDefined, "SkillForge: Skill does not exist");
        require(_strength > 0 && _strength <= 100, "SkillForge: Strength must be between 1 and 100");
        require(msg.value >= attestationFee, "SkillForge: Insufficient attestation fee");

        // Prevent duplicate attestations for the same skill from the same attestor
        for (uint256 i = 0; i < users[msg.sender].givenAttestations.length; i++) {
            Attestation storage existingAtt = attestations[users[msg.sender].givenAttestations[i]];
            if (existingAtt.subject == _subject && existingAtt.skillId == _skillId) {
                revert("SkillForge: Already attested for this user's skill");
            }
        }

        uint256 attestationId = nextAttestationId++;
        attestations[attestationId] = Attestation({
            attestor: msg.sender,
            subject: _subject,
            skillId: _skillId,
            strength: _strength,
            timestamp: block.timestamp,
            status: AttestationStatus.Verified, // Start as verified, can be challenged
            challengeId: 0
        });

        users[msg.sender].givenAttestations.push(attestationId);
        users[_subject].receivedAttestations.push(attestationId);

        // Directly modify reputation for successful attestation
        users[_subject].reputation += REPUTATION_PER_VERIFIED_ATTESTATION;

        emit SkillAttested(attestationId, _subject, msg.sender, _skillId, _strength);
    }

    /**
     * @dev Retrieves the details of a specific attestation.
     * @param _attestationId The ID of the attestation to retrieve.
     * @return attestor, subject, skillId, strength, timestamp, status, challengeId.
     */
    function getAttestation(uint256 _attestationId) external view returns (address attestor, address subject, uint256 skillId, uint256 strength, uint256 timestamp, AttestationStatus status, uint256 challengeId) {
        Attestation storage att = attestations[_attestationId];
        require(att.attestor != address(0), "SkillForge: Attestation does not exist");
        return (att.attestor, att.subject, att.skillId, att.strength, att.timestamp, att.status, att.challengeId);
    }

    /**
     * @dev Retrieves a list of all attestations received by a specific user.
     * @param _userAddress The address of the user.
     * @return An array of attestation IDs.
     */
    function getAttestationsForUser(address _userAddress) external view returns (uint256[] memory) {
        require(users[_userAddress].isRegistered, "SkillForge: User not registered");
        return users[_userAddress].receivedAttestations;
    }

    /**
     * @dev Retrieves a list of all attestations given by a specific user.
     * @param _attestorAddress The address of the attestor.
     * @return An array of attestation IDs.
     */
    function getAttestationsByAttestor(address _attestorAddress) external view returns (uint256[] memory) {
        require(users[_attestorAddress].isRegistered, "SkillForge: User not registered");
        return users[_attestorAddress].givenAttestations;
    }

    /**
     * @dev Allows a user to challenge the validity of an attestation.
     *      Requires payment of `challengeStake`.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reason A brief reason for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, string calldata _reason) external payable onlyRegisteredUser whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        require(att.attestor != address(0), "SkillForge: Attestation does not exist");
        require(att.status == AttestationStatus.Verified, "SkillForge: Attestation is not in a valid state to be challenged");
        require(msg.sender != att.attestor && msg.sender != att.subject, "SkillForge: Cannot challenge your own attestation or one you are part of");
        require(msg.value >= challengeStake, "SkillForge: Insufficient challenge stake");
        require(bytes(_reason).length > 0, "SkillForge: Challenge reason cannot be empty");

        att.status = AttestationStatus.Challenged;

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            challenger: msg.sender,
            attestationId: _attestationId,
            reason: _reason,
            timestamp: block.timestamp,
            status: ChallengeStatus.Pending,
            stakeAmount: msg.value,
            winner: address(0)
        });
        att.challengeId = challengeId;

        emit AttestationChallenged(challengeId, _attestationId, msg.sender);
    }

    /**
     * @dev Resolves a pending challenge. Only the owner (or a future DAO governance) can resolve challenges.
     *      Distributes stakes and adjusts reputation based on the resolution.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger wins, false if the original attestation stands.
     */
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyOwner whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.attestationId != 0, "SkillForge: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Pending, "SkillForge: Challenge already resolved");

        Attestation storage att = attestations[challenge.attestationId];
        require(att.status == AttestationStatus.Challenged, "SkillForge: Attestation not in challenged state");

        challenge.status = _challengerWins ? ChallengeStatus.Approved : ChallengeStatus.Rejected;
        challenge.winner = _challengerWins ? challenge.challenger : att.attestor;

        if (_challengerWins) {
            // Challenger wins: Attestation is revoked, challenger gets stake back + attestor's stake (if any), attestor loses reputation.
            att.status = AttestationStatus.Revoked;
            users[att.attestor].reputation = users[att.attestor].reputation > REPUTATION_LOSS_CHALLENGE_LOST ?
                                            users[att.attestor].reputation - REPUTATION_LOSS_CHALLENGE_LOST : 0;
            users[challenge.challenger].reputation += REPUTATION_GAIN_CHALLENGE_WON;

            // Refund challenger's stake
            (bool success, ) = challenge.challenger.call{value: challenge.stakeAmount}("");
            require(success, "SkillForge: Failed to return challenger stake");

            // Optionally, penalize attestor by sending their attestation fee to challenger or burn.
            // For simplicity, attestation fees go to contract and stake is the penalty.
            // If attestor had staked, it would be transferred. Here we transfer challenger's stake.
            // A more complex system might make attestor also stake for each attestation.
        } else {
            // Challenger loses: Attestation remains verified, challenger loses stake, attestor gains reputation.
            att.status = AttestationStatus.Verified;
            users[challenge.challenger].reputation = users[challenge.challenger].reputation > REPUTATION_LOSS_CHALLENGE_LOST ?
                                                    users[challenge.challenger].reputation - REPUTATION_LOSS_CHALLENGE_LOST : 0;
            users[att.attestor].reputation += REPUTATION_GAIN_CHALLENGE_WON;

            // Challenge stake remains in contract (burned/collected as penalty)
        }

        emit AttestationResolved(challenge.attestationId, att.status, msg.sender, _challengerWins);
    }

    /**
     * @dev Retrieves the details of a specific challenge.
     * @param _challengeId The ID of the challenge to retrieve.
     * @return challenger, attestationId, reason, timestamp, status, stakeAmount, winner.
     */
    function getChallenge(uint256 _challengeId) external view returns (address challenger, uint256 attestationId, string memory reason, uint256 timestamp, ChallengeStatus status, uint256 stakeAmount, address winner) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.attestationId != 0, "SkillForge: Challenge does not exist");
        return (challenge.challenger, challenge.attestationId, challenge.reason, challenge.timestamp, challenge.status, challenge.stakeAmount, challenge.winner);
    }

    /**
     * @dev Calculates and returns the current reputation score for a user.
     * @param _userAddress The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address _userAddress) external view returns (uint256) {
        require(users[_userAddress].isRegistered, "SkillForge: User not registered");
        return users[_userAddress].reputation;
    }

    // --- SkillBound Token (SBT) Management (3 Functions) ---

    /**
     * @dev Mints a Soulbound Token (SBT) for a user for a specific skill.
     *      This function is typically called internally when a user meets certain criteria
     *      (e.g., sufficient attestations for a skill, high reputation).
     *      For demonstration, it's made callable by the owner. In a production system,
     *      it would be triggered by a reputation or attestation threshold.
     * @param _recipient The address to mint the SBT to.
     * @param _skillId The ID of the skill this SBT represents.
     */
    function mintSkillSBT(address _recipient, uint256 _skillId) external onlyOwner whenNotPaused {
        require(users[_recipient].isRegistered, "SkillForge: Recipient is not a registered user");
        require(skills[_skillId].isDefined, "SkillForge: Skill definition does not exist");

        // Basic check for existing SBT for this skill for this user
        // A more robust check would scan all recipient's SBTs.
        for(uint256 i=0; i < users[_recipient].skillSBTs.length; i++) {
            if(skillSBTs[users[_recipient].skillSBTs[i]].skillId == _skillId) {
                revert("SkillForge: User already has an SBT for this skill");
            }
        }

        // In a real system, this would involve a reputation or attestation check:
        // uint256 avgStrength = _calculateAverageAttestationStrength(_recipient, _skillId);
        // uint256 attestationCount = _getVerifiedAttestationCount(_recipient, _skillId);
        // require(avgStrength >= MIN_SBT_STRENGTH_THRESHOLD && attestationCount >= MIN_SBT_ATTESTATION_COUNT, "SkillForge: Not enough verified attestations or strength for SBT");

        uint256 sbtId = nextSBTId++;
        skillSBTs[sbtId] = SkillBoundToken({
            sbtId: sbtId,
            skillId: _skillId,
            owner: _recipient,
            mintTimestamp: block.timestamp
        });

        users[_recipient].skillSBTs.push(sbtId);
        emit SkillSBTMinted(sbtId, _recipient, _skillId, skills[_skillId].name);
    }

    /**
     * @dev Retrieves a list of all Skill SBT IDs owned by a specific user.
     *      These tokens are non-transferable and represent verified skills.
     * @param _owner The address of the SBT owner.
     * @return An array of SBT IDs.
     */
    function getSkillSBTsForUser(address _owner) external view returns (uint256[] memory) {
        require(users[_owner].isRegistered, "SkillForge: User not registered");
        return users[_owner].skillSBTs;
    }

    // --- Opportunity Board & Project Management (7 Functions) ---

    /**
     * @dev Allows a registered user to post a new project opportunity with a bounty.
     *      Requires payment of `opportunityPostFee` and the `_bountyAmount`.
     * @param _title The title of the opportunity.
     * @param _description A detailed description of the project requirements.
     * @param _requiredSkillIds An array of skill IDs required for this opportunity.
     * @param _bountyAmount The bounty amount in Wei for completing the opportunity.
     * @return The ID of the newly posted opportunity.
     */
    function postOpportunity(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _requiredSkillIds,
        uint256 _bountyAmount
    ) external payable onlyRegisteredUser whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "SkillForge: Opportunity title cannot be empty");
        require(_bountyAmount > 0, "SkillForge: Bounty must be greater than zero");
        require(msg.value >= opportunityPostFee + _bountyAmount, "SkillForge: Insufficient funds for fee and bounty");

        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].isDefined, "SkillForge: Required skill does not exist");
        }

        uint256 opportunityId = nextOpportunityId++;
        opportunities[opportunityId] = Opportunity({
            poster: msg.sender,
            title: _title,
            description: _description,
            requiredSkillIds: _requiredSkillIds,
            bountyAmount: _bountyAmount,
            timestamp: block.timestamp,
            status: OpportunityStatus.Open,
            assignedWorker: address(0),
            completionProofUrl: ""
        });

        emit OpportunityPosted(opportunityId, msg.sender, _title, _bountyAmount);
        return opportunityId;
    }

    /**
     * @dev Allows a registered user to apply for a posted opportunity.
     * @param _opportunityId The ID of the opportunity to apply for.
     */
    function applyForOpportunity(uint256 _opportunityId) external onlyRegisteredUser whenNotPaused {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        require(opp.status == OpportunityStatus.Open, "SkillForge: Opportunity is not open for applications");
        require(opp.poster != msg.sender, "SkillForge: Cannot apply for your own opportunity");

        // Simple check if already applied (can be more efficient with a mapping if needed)
        for (uint256 i = 0; i < users[msg.sender].appliedOpportunities.length; i++) {
            if (users[msg.sender].appliedOpportunities[i] == _opportunityId) {
                revert("SkillForge: Already applied for this opportunity");
            }
        }

        users[msg.sender].appliedOpportunities.push(_opportunityId); // Mark user as applied
        emit OpportunityApplied(_opportunityId, msg.sender);
    }

    /**
     * @dev Allows the opportunity poster to assign a registered worker to their opportunity.
     *      Only the poster can assign.
     * @param _opportunityId The ID of the opportunity.
     * @param _worker The address of the worker to assign.
     */
    function assignOpportunity(uint256 _opportunityId, address _worker) external onlyRegisteredUser whenNotPaused {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        require(opp.poster == msg.sender, "SkillForge: Only the poster can assign a worker");
        require(opp.status == OpportunityStatus.Open, "SkillForge: Opportunity is not open for assignment");
        require(users[_worker].isRegistered, "SkillForge: Worker is not a registered user");

        // Basic check: Ensure worker has applied. (More robust would be to track all applicants)
        bool workerHasApplied = false;
        for (uint256 i = 0; i < users[_worker].appliedOpportunities.length; i++) {
            if (users[_worker].appliedOpportunities[i] == _opportunityId) {
                workerHasApplied = true;
                break;
            }
        }
        require(workerHasApplied, "SkillForge: Worker has not applied for this opportunity");

        opp.assignedWorker = _worker;
        opp.status = OpportunityStatus.Assigned;

        emit OpportunityAssigned(_opportunityId, _worker);
    }

    /**
     * @dev Allows the assigned worker to submit proof of completion for an opportunity.
     * @param _opportunityId The ID of the opportunity.
     * @param _proofUrl A URL or identifier pointing to the proof of completion (e.g., IPFS hash).
     */
    function submitOpportunityCompletion(uint256 _opportunityId, string calldata _proofUrl) external onlyRegisteredUser whenNotPaused {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        require(opp.assignedWorker == msg.sender, "SkillForge: Only the assigned worker can submit completion");
        require(opp.status == OpportunityStatus.Assigned, "SkillForge: Opportunity is not assigned or already completed");
        require(bytes(_proofUrl).length > 0, "SkillForge: Completion proof URL cannot be empty");

        opp.completionProofUrl = _proofUrl;
        opp.status = OpportunityStatus.Completed; // Marks for verification

        emit OpportunityCompletionSubmitted(_opportunityId, msg.sender, _proofUrl);
    }

    /**
     * @dev Allows the requester to verify the completion of an opportunity and release the bounty to the worker.
     *      Only the original poster can verify.
     * @param _opportunityId The ID of the opportunity to verify.
     */
    function verifyOpportunityCompletion(uint256 _opportunityId) external onlyRegisteredUser whenNotPaused nonReentrant {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        require(opp.poster == msg.sender, "SkillForge: Only the poster can verify completion");
        require(opp.status == OpportunityStatus.Completed, "SkillForge: Opportunity is not in a completed state for verification");
        require(opp.assignedWorker != address(0), "SkillForge: No worker was assigned");
        require(address(this).balance >= opp.bountyAmount, "SkillForge: Insufficient contract balance to pay bounty");

        opp.status = OpportunityStatus.Verified;
        users[opp.assignedWorker].reputation += REPUTATION_PER_OPPORTUNITY_COMPLETED;

        // Transfer bounty to the worker
        (bool success, ) = opp.assignedWorker.call{value: opp.bountyAmount}("");
        require(success, "SkillForge: Failed to transfer bounty to worker");

        emit OpportunityVerified(_opportunityId, msg.sender, opp.assignedWorker, opp.bountyAmount);
    }

    /**
     * @dev Allows the requester to cancel an unassigned opportunity.
     *      Bounty and fee are returned to the poster.
     * @param _opportunityId The ID of the opportunity to cancel.
     */
    function cancelOpportunity(uint256 _opportunityId) external onlyRegisteredUser whenNotPaused nonReentrant {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        require(opp.poster == msg.sender, "SkillForge: Only the poster can cancel their opportunity");
        require(opp.status == OpportunityStatus.Open, "SkillForge: Opportunity cannot be cancelled in its current state (already assigned/completed)");

        opp.status = OpportunityStatus.Cancelled;

        // Refund bounty and fee to poster
        uint256 refundAmount = opp.bountyAmount + opportunityPostFee; // Assumes initial fee was part of msg.value with bounty
        (bool success, ) = opp.poster.call{value: refundAmount}("");
        require(success, "SkillForge: Failed to refund bounty and fee to poster");

        emit OpportunityCancelled(_opportunityId, msg.sender);
    }

    /**
     * @dev Retrieves the details of a specific opportunity.
     * @param _opportunityId The ID of the opportunity.
     * @return poster, title, description, requiredSkillIds, bountyAmount, timestamp, status, assignedWorker, completionProofUrl.
     */
    function getOpportunity(uint256 _opportunityId) external view returns (address poster, string memory title, string memory description, uint256[] memory requiredSkillIds, uint256 bountyAmount, uint256 timestamp, OpportunityStatus status, address assignedWorker, string memory completionProofUrl) {
        Opportunity storage opp = opportunities[_opportunityId];
        require(opp.poster != address(0), "SkillForge: Opportunity does not exist");
        return (opp.poster, opp.title, opp.description, opp.requiredSkillIds, opp.bountyAmount, opp.timestamp, opp.status, opp.assignedWorker, opp.completionProofUrl);
    }

    // --- AI Oracle Integration (Conceptual) (2 Functions) ---

    /**
     * @dev Sends a request to the off-chain AI oracle for skill matching or attestation quality analysis.
     *      This function emits an event which an off-chain AI service would listen for.
     *      The AI service would then process the request and call `submitAIResult`.
     * @param _userAddress The user address for whom the AI analysis is requested.
     * @param _contextType The type of AI analysis requested (e.g., SkillMatch, AttestationQuality).
     * @return The unique request ID for tracking the AI operation.
     */
    function requestAISkillMatch(address _userAddress, uint256 _contextType) external onlyRegisteredUser whenNotPaused returns (uint256) {
        require(aiOracleAddress != address(0), "SkillForge: AI Oracle address not set");
        require(users[_userAddress].isRegistered, "SkillForge: Target user for AI is not registered");

        uint256 requestId = nextAIRequestId++;
        emit AIRequestSent(requestId, _userAddress, _contextType);
        return requestId;
    }

    /**
     * @dev Allows the trusted AI oracle to submit the result of an off-chain AI operation back to the contract.
     *      The contract does not interpret the `_dataHash` but stores it as a verifiable reference.
     *      Future logic could use this for automated reputation adjustments or skill recommendations.
     * @param _requestId The ID of the original AI request.
     * @param _targetAddress The address of the user or entity the AI result pertains to.
     * @param _dataType A numeric code representing the type of data in `_dataHash` (e.g., 1 for match score, 2 for fraud likelihood).
     * @param _dataHash A cryptographic hash of the AI's detailed result (e.g., IPFS hash of a JSON output).
     */
    function submitAIResult(uint256 _requestId, address _targetAddress, uint256 _dataType, bytes32 _dataHash) external onlyAIOperator {
        // Here, the contract receives AI results.
        // Depending on _dataType, this could trigger internal logic,
        // e.g., if _dataType == AttestationQuality, adjust attestation strength/status.
        // For this example, we just log the event.
        emit AIResultReceived(_requestId, _targetAddress, _dataType, _dataHash);
    }

    // --- Utility Functions ---

    /**
     * @dev Allows the owner to withdraw the accumulated contract balance (fees collected).
     *      Uses a `nonReentrant` guard to prevent reentrancy attacks.
     */
    function withdrawContractBalance() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "SkillForge: No balance to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "SkillForge: Failed to withdraw balance");
    }

    // --- Internal Helpers (Not counted towards 20+ functions directly) ---
    // These would contain logic like `_calculateAverageAttestationStrength` or `_getVerifiedAttestationCount`
    // which would be used by `mintSkillSBT` or other functions if fully implemented.
    // For brevity, not fully implemented here but conceptualized.

    // function _calculateAverageAttestationStrength(address _user, uint256 _skillId) internal view returns (uint256) {
    //     // Logic to iterate through attestations for user and skill, sum strengths, and divide.
    // }

    // function _getVerifiedAttestationCount(address _user, uint256 _skillId) internal view returns (uint256) {
    //     // Logic to count verified attestations for user and skill.
    // }
}
```