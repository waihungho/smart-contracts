This smart contract, **AuraNet**, is designed as a Decentralized Algorithmic Reputation and Skill Network. It enables users to build a verifiable, multi-faceted on-chain profile based on registered skills, peer attestations, and project contributions. Unlike static reputation systems, AuraNet incorporates dynamic elements like weighted attestations, reputation decay, and refresh mechanisms, creating a living representation of a user's expertise and trustworthiness in the Web3 space.

---

## AuraNet: Decentralized Algorithmic Reputation & Skill Network

**Function Summary:**

**I. Core Skill & Attestation Management**
1.  `registerSkill`: Allows administrators to define and register new skills, including their prerequisites.
2.  `attestSkill`: Enables users to vouch for another user's skill level, with the attestation weight depending on the attester's own reputation.
3.  `revokeAttestation`: Allows an attester to retract a previously made attestation.
4.  `updateSkillDescription`: Administrator function to modify a skill's description.
5.  `setSkillPrerequisites`: Administrator function to define or update the prerequisite skills for a given skill.

**II. Reputation & Contribution Tracking**
6.  `submitContribution`: Users can log their contributions to various projects, linking them to specific skills.
7.  `verifyContribution`: A designated verifier confirms the legitimacy of a user's submitted contribution.
8.  `claimContributionBadge`: Mints a non-transferable "Soulbound" like badge for a verified contribution, serving as on-chain proof of work.
9.  `getAttestationScore`: Calculates an aggregate, time-decayed, and weighted score for a user's specific skill based on all valid attestations.
10. `getSkillReputationScore`: Returns a user's comprehensive reputation score for a specific skill, combining attestation score and verified contributions.
11. `getOverallReputationScore`: Computes an overall reputation score for a user, aggregating all their skill reputations and contributions.

**III. Dynamic & Algorithmic Features**
12. `setReputationDecayRate`: Administrator function to configure the rate at which a skill's reputation decays over time if not refreshed.
13. `refreshReputation`: Allows a user to actively refresh their reputation for a specific skill, mitigating decay.
14. `delegateAttestationRight`: A user can delegate the ability to attest to specific skills on their behalf for a limited time.
15. `revokeDelegatedAttestation`: Revokes a previously granted delegated attestation right.
16. `initiateSkillChallenge`: Initiates a formal skill challenge (e.g., an off-chain test link via URI) for a user to prove a skill.
17. `resolveSkillChallenge`: An authorized oracle or administrator resolves a pending skill challenge, updating the user's skill status.

**IV. Governance & Admin**
18. `setOracleAddress`: Administrator function to set or update the address of a trusted oracle for resolving off-chain data (e.g., challenges).
19. `pauseContract`: Allows the owner to pause critical contract functions in an emergency.
20. `unpauseContract`: Allows the owner to resume contract functions after a pause.
21. `setModerator`: Administrator function to grant or revoke moderator privileges for dispute resolution.
22. `initiateDispute`: Users can initiate a dispute against an attestation they believe is false or malicious.
23. `resolveDispute`: A moderator resolves a pending dispute, invalidating attestations and potentially penalizing offending parties.
24. `setWeightedAttestationThreshold`: Administrator function to configure how attestations from higher-reputation users are weighted.

**V. Query & Utility**
25. `getUserSkills`: Retrieves all skills a specific user has registered an attestation or contribution for.
26. `getSkillDetails`: Returns the name, description, prerequisites, and decay rate for a given skill ID.
27. `getContributionDetails`: Provides details about a specific contribution, including the project, description, and skill impacted.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title AuraNet: Decentralized Algorithmic Reputation & Skill Network
/// @notice A platform for building, verifying, and managing on-chain reputation and skills.
/// @dev This contract combines concepts of verifiable credentials, dynamic reputation,
///      and non-transferable tokens (SBT-like) to create a robust identity layer.
contract AuraNet is Ownable, Pausable {
    using SafeCast for uint256;

    // --- Events ---
    event SkillRegistered(uint256 indexed skillId, string skillName, address indexed registrar);
    event SkillDescriptionUpdated(uint256 indexed skillId, string newDescription);
    event SkillPrerequisitesSet(uint256 indexed skillId, uint256[] prerequisiteSkillIds);
    event AttestationMade(address indexed attester, address indexed attestedUser, uint256 indexed skillId, uint8 level);
    event AttestationRevoked(address indexed attester, address indexed attestedUser, uint256 indexed skillId);
    event ContributionSubmitted(address indexed contributor, uint256 indexed contributionId, string project);
    event ContributionVerified(uint256 indexed contributionId, bool isVerified, address indexed verifier);
    event ContributionBadgeClaimed(address indexed owner, uint256 indexed contributionId);
    event ReputationRefreshed(address indexed user, uint256 indexed skillId, uint256 newTimestamp);
    event ReputationDecayRateSet(uint256 indexed skillId, uint256 ratePerYear);
    event AttestationDelegated(address indexed delegator, address indexed delegatee, uint256 expirationTimestamp);
    event AttestationDelegationRevoked(address indexed delegator, address indexed delegatee);
    event SkillChallengeInitiated(uint256 indexed challengeId, address indexed user, uint256 indexed skillId, string challengeURI);
    event SkillChallengeResolved(uint256 indexed challengeId, bool passed, address indexed resolver);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed attestationId, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, bool isInvalid, address indexed moderator);
    event WeightedAttestationThresholdSet(uint256 minReputation, uint256 weight);
    event ModeratorStatusSet(address indexed moderator, bool status);
    event OracleAddressSet(address indexed newOracle);

    // --- State Variables & Data Structures ---

    uint256 private s_skillCounter;
    uint256 private s_contributionCounter;
    uint256 private s_attestationCounter;
    uint256 private s_challengeCounter;
    uint256 private s_disputeCounter;

    // --- Skill Definitions ---
    struct Skill {
        string name;
        string description;
        uint256[] prerequisites; // IDs of prerequisite skills
        uint256 decayRatePerYear; // Amount of score decayed per year, in basis points (e.g., 1000 = 10% per year)
        bool exists; // To check if a skill ID is valid
    }
    mapping(uint256 => Skill) public skills;
    mapping(string => uint256) public skillNameToId; // For quick lookup

    // --- Attestations ---
    struct Attestation {
        address attester;
        address attestedUser;
        uint256 skillId;
        uint8 level; // 0-100 representing percentage of mastery
        uint256 timestamp;
        bool isValid; // Can be set to false if revoked or disputed
    }
    mapping(uint256 => Attestation) public attestations; // attestationId => Attestation
    mapping(address => mapping(address => mapping(uint256 => uint256))) private s_userAttestations; // attester => attestedUser => skillId => attestationId

    // --- Contributions ---
    struct Contribution {
        address contributor;
        string project;
        string details;
        uint256 skillIdImpacted;
        uint256 timestamp;
        bool isVerified;
    }
    mapping(uint256 => Contribution) public contributions; // contributionId => Contribution
    mapping(address => mapping(uint256 => bool)) public hasClaimedContributionBadge; // user => contributionId => bool (SBT-like)

    // --- Reputation Decay & Refresh ---
    mapping(address => mapping(uint256 => uint256)) public lastReputationRefreshTimestamp; // user => skillId => timestamp

    // --- Delegated Attestation Rights ---
    struct DelegatedAttestation {
        address delegatee;
        uint256 expirationTimestamp;
    }
    mapping(address => mapping(address => DelegatedAttestation)) public delegatedAttestations; // delegator => delegatee => DelegatedAttestation

    // --- Skill Challenges (Off-chain verification) ---
    enum ChallengeStatus { Pending, Resolved }
    struct SkillChallenge {
        address user;
        uint256 skillId;
        string challengeURI; // URI to off-chain challenge details/platform
        ChallengeStatus status;
        bool passed; // Only relevant if status is Resolved
        address resolver;
    }
    mapping(uint256 => SkillChallenge) public skillChallenges;

    // --- Disputes ---
    enum DisputeStatus { Pending, Resolved }
    struct Dispute {
        uint256 attestationId;
        address initiator;
        string reason;
        DisputeStatus status;
        bool isInvalid; // If the attestation was found to be invalid
        address offendingParty; // E.g., the attester or the attested user
    }
    mapping(uint256 => Dispute) public disputes;

    // --- Access Control ---
    address public oracleAddress; // For resolving off-chain challenges or external data
    mapping(address => bool) public moderators; // For dispute resolution

    // --- Weighted Attestations ---
    struct ReputationWeight {
        uint256 minReputationScore; // Minimum overall reputation score an attester needs
        uint256 weightMultiplier; // Multiplier for their attestations (e.g., 2 for 2x weight), in basis points (10000 = 1x)
    }
    ReputationWeight[] public reputationWeights; // Sorted by minReputationScore ascending

    // --- Errors ---
    error SkillDoesNotExist(uint256 skillId);
    error SkillAlreadyExists(string skillName);
    error InvalidSkillLevel();
    error PrerequisitesNotMet(uint256 skillId);
    error AttestationDoesNotExist(uint256 attestationId);
    error NotAttester();
    error AttestationAlreadyExists();
    error ContributionDoesNotExist(uint256 contributionId);
    error ContributionNotVerified();
    error BadgeAlreadyClaimed();
    error NotOracle();
    error ChallengeDoesNotExist(uint256 challengeId);
    error ChallengeAlreadyResolved();
    error NotModerator();
    error AttestationNotValid();
    error DisputeDoesNotExist(uint256 disputeId);
    error DisputeAlreadyResolved();
    error Unauthorized();
    error DelegationExpired();
    error NotDelegator();
    error DelegationDoesNotExist();
    error InvalidDecayRate();
    error CannotSetPrerequisitesToSelf();
    error PrerequisiteCycleDetected();

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert NotOracle();
        }
        _;
    }

    modifier onlyModerator() {
        if (!moderators[msg.sender]) {
            revert NotModerator();
        }
        _;
    }

    constructor() Ownable(msg.sender) {
        // Default moderator is the contract owner
        moderators[msg.sender] = true;
        // Default oracle can also be owner initially
        oracleAddress = msg.sender;
        // Add a default reputation weight: everyone's attestation counts as 1x
        reputationWeights.push(ReputationWeight(0, 10000));
    }

    // --- I. Core Skill & Attestation Management ---

    /// @notice Registers a new skill in the network.
    /// @dev Only the owner can register skills. Prerequisites must be existing skills.
    /// @param _skillName The name of the skill (e.g., "Solidity Development").
    /// @param _description A detailed description of the skill.
    /// @param _prerequisites An array of skill IDs that are prerequisites for this skill.
    function registerSkill(string calldata _skillName, string calldata _description, uint256[] calldata _prerequisites)
        external
        onlyOwner
        whenNotPaused
    {
        if (skillNameToId[_skillName] != 0) {
            revert SkillAlreadyExists(_skillName);
        }

        s_skillCounter++;
        uint256 newSkillId = s_skillCounter;

        for (uint256 i = 0; i < _prerequisites.length; i++) {
            if (!skills[_prerequisites[i]].exists) {
                revert SkillDoesNotExist(_prerequisites[i]);
            }
            if (_prerequisites[i] == newSkillId) {
                revert CannotSetPrerequisitesToSelf();
            }
            // Basic cycle detection (can be more robust for complex graphs)
            for (uint256 j = 0; j < skills[_prerequisites[i]].prerequisites.length; j++) {
                if (skills[_prerequisites[i]].prerequisites[j] == newSkillId) {
                    revert PrerequisiteCycleDetected();
                }
            }
        }

        skills[newSkillId] = Skill({
            name: _skillName,
            description: _description,
            prerequisites: _prerequisites,
            decayRatePerYear: 1000, // Default 10% decay per year
            exists: true
        });
        skillNameToId[_skillName] = newSkillId;
        emit SkillRegistered(newSkillId, _skillName, msg.sender);
    }

    /// @notice Updates the description of an existing skill.
    /// @dev Only the owner can update skill descriptions.
    /// @param _skillId The ID of the skill to update.
    /// @param _newDescription The new description for the skill.
    function updateSkillDescription(uint256 _skillId, string calldata _newDescription) external onlyOwner whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        skills[_skillId].description = _newDescription;
        emit SkillDescriptionUpdated(_skillId, _newDescription);
    }

    /// @notice Sets or updates the prerequisites for an existing skill.
    /// @dev Only the owner can set prerequisites. Prerequisites must be existing skills.
    /// @param _skillId The ID of the skill whose prerequisites are being set.
    /// @param _prerequisiteSkillIds An array of skill IDs that are prerequisites.
    function setSkillPrerequisites(uint256 _skillId, uint256[] calldata _prerequisiteSkillIds) external onlyOwner whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }

        for (uint256 i = 0; i < _prerequisiteSkillIds.length; i++) {
            if (!skills[_prerequisiteSkillIds[i]].exists) {
                revert SkillDoesNotExist(_prerequisiteSkillIds[i]);
            }
            if (_prerequisiteSkillIds[i] == _skillId) {
                revert CannotSetPrerequisitesToSelf();
            }
             // Basic cycle detection (can be more robust for complex graphs)
            for (uint256 j = 0; j < skills[_prerequisiteSkillIds[i]].prerequisites.length; j++) {
                if (skills[_prerequisiteSkillIds[i]].prerequisites[j] == _skillId) {
                    revert PrerequisiteCycleDetected();
                }
            }
        }

        skills[_skillId].prerequisites = _prerequisiteSkillIds;
        emit SkillPrerequisitesSet(_skillId, _prerequisiteSkillIds);
    }

    /// @notice Allows a user to attest to another user's skill level.
    /// @dev The attester's own reputation score influences the weight of their attestation.
    ///      Skill level must be between 0 and 100.
    /// @param _user The address of the user whose skill is being attested.
    /// @param _skillId The ID of the skill being attested.
    /// @param _level The attested level of the skill (0-100).
    function attestSkill(address _user, uint256 _skillId, uint8 _level) external whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        if (_level > 100) {
            revert InvalidSkillLevel();
        }
        if (_user == msg.sender) {
            revert("Cannot attest to your own skill.");
        }

        // Check if prerequisites are met for the attested user (optional but good for a stricter system)
        for (uint256 i = 0; i < skills[_skillId].prerequisites.length; i++) {
            if (getSkillReputationScore(_user, skills[_skillId].prerequisites[i]) < 50) { // Example: need at least 50 score in prerequisite
                revert PrerequisitesNotMet(skills[_skillId].prerequisites[i]);
            }
        }

        // Check if attestation already exists from msg.sender to _user for _skillId
        if (s_userAttestations[msg.sender][_user][_skillId] != 0) {
            revert AttestationAlreadyExists();
        }

        s_attestationCounter++;
        uint256 newAttestationId = s_attestationCounter;

        attestations[newAttestationId] = Attestation({
            attester: msg.sender,
            attestedUser: _user,
            skillId: _skillId,
            level: _level,
            timestamp: block.timestamp,
            isValid: true
        });
        s_userAttestations[msg.sender][_user][_skillId] = newAttestationId;

        lastReputationRefreshTimestamp[_user][_skillId] = block.timestamp; // Refresh target's reputation upon attestation
        emit AttestationMade(msg.sender, _user, _skillId, _level);
    }

    /// @notice Allows an attester to revoke a previous attestation.
    /// @param _user The address of the user who was attested.
    /// @param _skillId The ID of the skill that was attested.
    function revokeAttestation(address _user, uint256 _skillId) external whenNotPaused {
        uint256 attestationId = s_userAttestations[msg.sender][_user][_skillId];
        if (attestationId == 0) {
            revert AttestationDoesNotExist(0); // If attestationId is 0, it doesn't exist.
        }
        if (attestations[attestationId].attester != msg.sender) {
            revert NotAttester();
        }

        attestations[attestationId].isValid = false;
        delete s_userAttestations[msg.sender][_user][_skillId]; // Clean up for new attestations
        emit AttestationRevoked(msg.sender, _user, _skillId);
    }

    // --- II. Reputation & Contribution Tracking ---

    /// @notice Allows a user to submit a contribution to a project, linking it to a specific skill.
    /// @param _project The name or identifier of the project.
    /// @param _contributionDetails A description or URI for the contribution details.
    /// @param _skillIdImpacted The skill ID that this contribution demonstrates.
    function submitContribution(string calldata _project, string calldata _contributionDetails, uint256 _skillIdImpacted) external whenNotPaused {
        if (!skills[_skillIdImpacted].exists) {
            revert SkillDoesNotExist(_skillIdImpacted);
        }

        s_contributionCounter++;
        uint256 newContributionId = s_contributionCounter;

        contributions[newContributionId] = Contribution({
            contributor: msg.sender,
            project: _project,
            details: _contributionDetails,
            skillIdImpacted: _skillIdImpacted,
            timestamp: block.timestamp,
            isVerified: false
        });
        emit ContributionSubmitted(msg.sender, newContributionId, _project);
    }

    /// @notice Verifies a submitted contribution.
    /// @dev Only the contract owner or a designated verifier (e.g., a project manager) can call this.
    ///      For simplicity, using onlyOwner here, but could be extended to allow other roles.
    /// @param _contributor The address of the user who submitted the contribution.
    /// @param _contributionId The ID of the contribution to verify.
    /// @param _isVerified True to verify, false to unverify.
    function verifyContribution(address _contributor, uint256 _contributionId, bool _isVerified) external onlyOwner whenNotPaused {
        if (contributions[_contributionId].contributor == address(0)) {
            revert ContributionDoesNotExist(_contributionId);
        }
        if (contributions[_contributionId].contributor != _contributor) {
            revert Unauthorized();
        }

        contributions[_contributionId].isVerified = _isVerified;
        lastReputationRefreshTimestamp[_contributor][contributions[_contributionId].skillIdImpacted] = block.timestamp;
        emit ContributionVerified(_contributionId, _isVerified, msg.sender);
    }

    /// @notice Allows a user to claim a non-transferable badge for a verified contribution.
    /// @dev This is a simple SBT-like implementation. The badge ID is the contribution ID.
    /// @param _contributionId The ID of the verified contribution.
    function claimContributionBadge(uint256 _contributionId) external whenNotPaused {
        if (contributions[_contributionId].contributor == address(0)) {
            revert ContributionDoesNotExist(_contributionId);
        }
        if (contributions[_contributionId].contributor != msg.sender) {
            revert Unauthorized();
        }
        if (!contributions[_contributionId].isVerified) {
            revert ContributionNotVerified();
        }
        if (hasClaimedContributionBadge[msg.sender][_contributionId]) {
            revert BadgeAlreadyClaimed();
        }

        hasClaimedContributionBadge[msg.sender][_contributionId] = true;
        emit ContributionBadgeClaimed(msg.sender, _contributionId);
    }

    /// @notice Calculates the aggregate, time-decayed, and weighted attestation score for a user's skill.
    /// @dev This is a complex calculation considering multiple factors.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return The calculated attestation score (0-100).
    function getAttestationScore(address _user, uint256 _skillId) public view returns (uint8) {
        if (!skills[_skillId].exists) {
            return 0;
        }

        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;
        uint256 decayRate = skills[_skillId].decayRatePerYear; // Basis points per year

        for (uint256 i = 1; i <= s_attestationCounter; i++) {
            Attestation storage att = attestations[i];
            if (att.attestedUser == _user && att.skillId == _skillId && att.isValid) {
                uint256 attesterReputation = getOverallReputationScore(att.attester);
                uint256 attestationWeight = getAttesterWeightMultiplier(attesterReputation); // Basis points

                // Calculate decay factor
                uint256 timeElapsed = block.timestamp - att.timestamp;
                uint256 decayPeriods = timeElapsed / 1 years; // Assuming annual decay
                
                uint256 currentDecayRate = decayRate; // Use the skill's specific decay rate
                uint256 decayFactor = 10000; // 1x, in basis points
                for (uint256 d = 0; d < decayPeriods; d++) {
                    decayFactor = decayFactor * (10000 - currentDecayRate) / 10000;
                }

                totalWeightedScore += (att.level * attestationWeight / 10000) * decayFactor / 10000;
                totalWeight += (100 * attestationWeight / 10000) * decayFactor / 10000; // Max possible score for this attestation's weight
            }
        }
        return totalWeight > 0 ? (totalWeightedScore * 100 / totalWeight).toUint8() : 0;
    }

    /// @notice Retrieves a user's comprehensive reputation score for a specific skill.
    /// @dev Combines attestation score and contributions.
    /// @param _user The address of the user.
    /// @param _skillId The ID of the skill.
    /// @return The skill-specific reputation score (0-100).
    function getSkillReputationScore(address _user, uint256 _skillId) public view returns (uint8) {
        if (!skills[_skillId].exists) {
            return 0;
        }

        uint256 attestationScore = getAttestationScore(_user, _skillId);
        uint256 contributionScore = 0;
        uint256 verifiedContributions = 0;

        for (uint256 i = 1; i <= s_contributionCounter; i++) {
            Contribution storage contr = contributions[i];
            if (contr.contributor == _user && contr.skillIdImpacted == _skillId && contr.isVerified) {
                verifiedContributions++;
            }
        }

        if (verifiedContributions > 0) {
            // Each verified contribution adds a bonus, capped at a certain amount (e.g., 20 points)
            contributionScore = verifiedContributions * 5; // Example: 5 points per contribution
            if (contributionScore > 20) contributionScore = 20;
        }
        
        // Combine scores. Contributions are a bonus, not a full score.
        // Example: 80% from attestation, 20% from contributions
        uint256 finalScore = (attestationScore * 80 / 100) + (contributionScore * 20 / 100);
        if (finalScore > 100) finalScore = 100;

        return finalScore.toUint8();
    }

    /// @notice Computes an overall reputation score for a user, aggregating all their skill reputations.
    /// @param _user The address of the user.
    /// @return The overall reputation score (0-100).
    function getOverallReputationScore(address _user) public view returns (uint8) {
        uint256 totalWeightedScore = 0;
        uint256 totalSkillCount = 0;

        for (uint256 i = 1; i <= s_skillCounter; i++) {
            if (skills[i].exists) {
                uint256 skillScore = getSkillReputationScore(_user, i);
                if (skillScore > 0) { // Only count skills where the user has some reputation
                    totalWeightedScore += skillScore;
                    totalSkillCount++;
                }
            }
        }

        return totalSkillCount > 0 ? (totalWeightedScore / totalSkillCount).toUint8() : 0;
    }

    // --- III. Dynamic & Algorithmic Features ---

    /// @notice Sets the annual decay rate for a specific skill's reputation.
    /// @dev Only owner can set. Rate is in basis points (e.g., 1000 = 10%). Max 10000 (100%).
    /// @param _skillId The ID of the skill.
    /// @param _ratePerYear The decay rate in basis points per year (0-10000).
    function setReputationDecayRate(uint256 _skillId, uint256 _ratePerYear) external onlyOwner whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        if (_ratePerYear > 10000) {
            revert InvalidDecayRate();
        }
        skills[_skillId].decayRatePerYear = _ratePerYear;
        emit ReputationDecayRateSet(_skillId, _ratePerYear);
    }

    /// @notice Allows a user to refresh their reputation for a specific skill.
    /// @dev This effectively resets the decay timer for the skill's reputation calculation.
    /// @param _user The address of the user whose reputation is being refreshed.
    /// @param _skillId The ID of the skill to refresh.
    function refreshReputation(address _user, uint256 _skillId) public whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        // Only the user themselves can refresh their reputation
        if (msg.sender != _user) {
            revert Unauthorized();
        }
        lastReputationRefreshTimestamp[_user][_skillId] = block.timestamp;
        emit ReputationRefreshed(_user, _skillId, block.timestamp);
    }

    /// @notice Allows a user to delegate attestation rights to another address for a limited time.
    /// @param _delegatee The address to whom attestation rights are delegated.
    /// @param _expirationTimestamp The timestamp when the delegation expires.
    function delegateAttestationRight(address _delegatee, uint256 _expirationTimestamp) external whenNotPaused {
        if (_delegatee == address(0)) {
            revert("Invalid delegatee address.");
        }
        if (_expirationTimestamp <= block.timestamp) {
            revert("Expiration must be in the future.");
        }
        delegatedAttestations[msg.sender][_delegatee] = DelegatedAttestation({
            delegatee: _delegatee,
            expirationTimestamp: _expirationTimestamp
        });
        emit AttestationDelegated(msg.sender, _delegatee, _expirationTimestamp);
    }

    /// @notice Revokes a previously granted delegated attestation right.
    /// @param _delegatee The address whose delegated rights are being revoked.
    function revokeDelegatedAttestation(address _delegatee) external whenNotPaused {
        if (delegatedAttestations[msg.sender][_delegatee].delegatee == address(0)) {
            revert DelegationDoesNotExist();
        }
        delete delegatedAttestations[msg.sender][_delegatee];
        emit AttestationDelegationRevoked(msg.sender, _delegatee);
    }

    /// @notice Initiates an off-chain skill challenge for a user to prove a skill.
    /// @dev The `_challengeURI` should point to external challenge details.
    /// @param _user The user taking the challenge.
    /// @param _skillId The skill ID being challenged.
    /// @param _challengeURI A URI pointing to the challenge details or platform.
    function initiateSkillChallenge(address _user, uint256 _skillId, string calldata _challengeURI) external onlyOwner whenNotPaused {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        s_challengeCounter++;
        uint256 newChallengeId = s_challengeCounter;

        skillChallenges[newChallengeId] = SkillChallenge({
            user: _user,
            skillId: _skillId,
            challengeURI: _challengeURI,
            status: ChallengeStatus.Pending,
            passed: false,
            resolver: address(0)
        });
        emit SkillChallengeInitiated(newChallengeId, _user, _skillId, _challengeURI);
    }

    /// @notice Resolves a pending skill challenge.
    /// @dev Only the designated oracle can resolve challenges.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _passed True if the user passed the challenge, false otherwise.
    function resolveSkillChallenge(uint256 _challengeId, bool _passed) external onlyOracle whenNotPaused {
        if (skillChallenges[_challengeId].user == address(0)) {
            revert ChallengeDoesNotExist(_challengeId);
        }
        if (skillChallenges[_challengeId].status == ChallengeStatus.Resolved) {
            revert ChallengeAlreadyResolved();
        }

        skillChallenges[_challengeId].status = ChallengeStatus.Resolved;
        skillChallenges[_challengeId].passed = _passed;
        skillChallenges[_challengeId].resolver = msg.sender;

        if (_passed) {
            lastReputationRefreshTimestamp[skillChallenges[_challengeId].user][skillChallenges[_challengeId].skillId] = block.timestamp;
            // Optionally, mint a special badge or give a significant reputation boost
        }
        emit SkillChallengeResolved(_challengeId, _passed, msg.sender);
    }

    // --- IV. Governance & Admin ---

    /// @notice Sets the address of the trusted oracle.
    /// @dev Only the owner can set the oracle address.
    /// @param _newOracle The new address for the oracle.
    function setOracleAddress(address _newOracle) external onlyOwner {
        oracleAddress = _newOracle;
        emit OracleAddressSet(_newOracle);
    }

    /// @notice Pauses contract functionality in emergency situations.
    /// @dev Only the owner can pause. Uses OpenZeppelin Pausable.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract functionality.
    /// @dev Only the owner can unpause. Uses OpenZeppelin Pausable.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Assigns or revokes moderator status to an address.
    /// @dev Moderators are responsible for resolving disputes. Only owner can manage.
    /// @param _moderator The address to set/unset as moderator.
    /// @param _status True to make moderator, false to revoke.
    function setModerator(address _moderator, bool _status) external onlyOwner {
        if (_moderator == address(0)) {
            revert("Invalid moderator address.");
        }
        moderators[_moderator] = _status;
        emit ModeratorStatusSet(_moderator, _status);
    }

    /// @notice Allows any user to initiate a dispute against an attestation.
    /// @dev Requires a valid `attestationId`.
    /// @param _attestationId The ID of the attestation being disputed.
    /// @param _reason A string describing the reason for the dispute.
    function initiateDispute(uint256 _attestationId, string calldata _reason) external whenNotPaused {
        if (attestations[_attestationId].attester == address(0)) {
            revert AttestationDoesNotExist(_attestationId);
        }
        if (!attestations[_attestationId].isValid) {
            revert AttestationNotValid();
        }

        s_disputeCounter++;
        uint256 newDisputeId = s_disputeCounter;

        disputes[newDisputeId] = Dispute({
            attestationId: _attestationId,
            initiator: msg.sender,
            reason: _reason,
            status: DisputeStatus.Pending,
            isInvalid: false,
            offendingParty: address(0)
        });
        emit DisputeInitiated(newDisputeId, _attestationId, msg.sender);
    }

    /// @notice Allows a moderator to resolve a pending dispute.
    /// @dev If `_isInvalid` is true, the disputed attestation is marked as invalid.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _isInvalid True if the attestation is found to be invalid.
    /// @param _offendingParty The address of the party found to be at fault (optional).
    function resolveDispute(uint256 _disputeId, bool _isInvalid, address _offendingParty) external onlyModerator whenNotPaused {
        if (disputes[_disputeId].initiator == address(0)) {
            revert DisputeDoesNotExist(_disputeId);
        }
        if (disputes[_disputeId].status == DisputeStatus.Resolved) {
            revert DisputeAlreadyResolved();
        }

        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].isInvalid = _isInvalid;
        disputes[_disputeId].offendingParty = _offendingParty;

        if (_isInvalid) {
            uint256 attestationId = disputes[_disputeId].attestationId;
            attestations[attestationId].isValid = false;
            // Also remove from s_userAttestations to allow new attestations
            delete s_userAttestations[attestations[attestationId].attester][attestations[attestationId].attestedUser][attestations[attestationId].skillId];
            // Potentially penalize _offendingParty here
        }
        emit DisputeResolved(_disputeId, _isInvalid, msg.sender);
    }

    /// @notice Sets a threshold for weighted attestations.
    /// @dev Attestations from users with reputation above `_minReputation` gain `_weightMultiplier` bonus.
    ///      Weights are in basis points (10000 = 1x).
    /// @param _minReputation The minimum overall reputation score for this weight to apply.
    /// @param _weightMultiplier The multiplier (in basis points, e.g., 15000 for 1.5x).
    function setWeightedAttestationThreshold(uint256 _minReputation, uint256 _weightMultiplier) external onlyOwner whenNotPaused {
        if (_weightMultiplier == 0) {
            revert("Weight multiplier cannot be zero.");
        }
        // Insert in sorted order or simply add and rely on getAttesterWeightMultiplier to find highest applicable
        reputationWeights.push(ReputationWeight(_minReputation, _weightMultiplier));
        // Sort the array by minReputationScore (bubble sort for small arrays, or use a more efficient method if many thresholds)
        for (uint256 i = 0; i < reputationWeights.length; i++) {
            for (uint256 j = i + 1; j < reputationWeights.length; j++) {
                if (reputationWeights[i].minReputationScore > reputationWeights[j].minReputationScore) {
                    ReputationWeight memory temp = reputationWeights[i];
                    reputationWeights[i] = reputationWeights[j];
                    reputationWeights[j] = temp;
                }
            }
        }
        emit WeightedAttestationThresholdSet(_minReputation, _weightMultiplier);
    }

    /// @notice Internal helper to get the attester's weight multiplier based on their overall reputation.
    /// @dev Iterates through `reputationWeights` to find the highest applicable multiplier.
    /// @param _attesterReputation The overall reputation score of the attester.
    /// @return The weight multiplier in basis points (e.g., 10000 for 1x).
    function getAttesterWeightMultiplier(uint256 _attesterReputation) internal view returns (uint256) {
        uint256 currentMultiplier = 10000; // Default 1x (10000 basis points)
        for (uint256 i = 0; i < reputationWeights.length; i++) {
            if (_attesterReputation >= reputationWeights[i].minReputationScore) {
                currentMultiplier = reputationWeights[i].weightMultiplier;
            } else {
                // Since array is sorted, we can break early if we exceed the threshold
                break;
            }
        }
        return currentMultiplier;
    }

    // --- V. Query & Utility ---

    /// @notice Retrieves a list of all skills a user has attested to or contributed towards.
    /// @param _user The address of the user.
    /// @return An array of skill IDs associated with the user.
    function getUserSkills(address _user) external view returns (uint256[] memory) {
        uint256[] memory skillIds = new uint256[](s_skillCounter);
        uint256 count = 0;

        for (uint256 i = 1; i <= s_skillCounter; i++) {
            if (skills[i].exists) {
                // Check for attestations
                for (uint256 j = 1; j <= s_attestationCounter; j++) {
                    if (attestations[j].attestedUser == _user && attestations[j].skillId == i && attestations[j].isValid) {
                        skillIds[count++] = i;
                        break; // Move to next skill
                    }
                }
                // Check for contributions
                for (uint256 j = 1; j <= s_contributionCounter; j++) {
                    if (contributions[j].contributor == _user && contributions[j].skillIdImpacted == i && contributions[j].isVerified && hasClaimedContributionBadge[_user][j]) {
                        bool alreadyAdded = false;
                        for (uint256 k = 0; k < count; k++) {
                            if (skillIds[k] == i) {
                                alreadyAdded = true;
                                break;
                            }
                        }
                        if (!alreadyAdded) {
                            skillIds[count++] = i;
                            break; // Move to next skill
                        }
                    }
                }
            }
        }
        uint224 actualCount = count.toUint224();
        uint256[] memory result = new uint256[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = skillIds[i];
        }
        return result;
    }

    /// @notice Returns the details of a specific skill.
    /// @param _skillId The ID of the skill.
    /// @return skillName, description, prerequisites, decayRatePerYear.
    function getSkillDetails(uint256 _skillId) external view returns (string memory skillName, string memory description, uint256[] memory prerequisites, uint256 decayRatePerYear) {
        if (!skills[_skillId].exists) {
            revert SkillDoesNotExist(_skillId);
        }
        Skill storage skill = skills[_skillId];
        return (skill.name, skill.description, skill.prerequisites, skill.decayRatePerYear);
    }

    /// @notice Returns the details of a specific contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return contributor, project, details, skillIdImpacted, timestamp, isVerified.
    function getContributionDetails(uint256 _contributionId) external view returns (address contributor, string memory project, string memory details, uint256 skillIdImpacted, uint256 timestamp, bool isVerified) {
        if (contributions[_contributionId].contributor == address(0)) {
            revert ContributionDoesNotExist(_contributionId);
        }
        Contribution storage contr = contributions[_contributionId];
        return (contr.contributor, contr.project, contr.details, contr.skillIdImpacted, contr.timestamp, contr.isVerified);
    }
}
```