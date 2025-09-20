The following smart contract, `SoulboundSkillGraph`, is designed to create a decentralized reputation and skill network. It introduces novel concepts such as AI-assisted skill validation, economically staked endorsements, and non-transferable (soulbound) badges to build a robust and trustworthy system for verifying and recognizing individual skills on the blockchain.

It avoids direct duplication of common open-source patterns by integrating these features into a cohesive system, rather than just being a generic ERC-721 or a standard DAO. The AI Oracle acts as a crucial, yet trust-minimized, off-chain computation provider for complex skill validation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom errors for clarity and gas efficiency
error InvalidAddress();
error ProfileNotFound();
error ProfileAlreadyExists();
error SkillNotDeclared();
error SkillAlreadyDeclared();
error EndorsementNotFound();
error AlreadyEndorsedSkill();
error NotEnoughStake();
error ChallengeNotFound();
error ChallengeAlreadyResolved();
error InvalidChallengeParameters();
error NotChallengeParticipant();
error AIAlreadyValidatedParticipant();
error InvalidSubmissionURI();
error AIValidationFlagged(); // When AI validation is under dispute
error BadgeNotFound();
error BadgeAlreadyIssued();
error BadgeAlreadyRevoked();
error NotAIOracle();
error CannotReportYourself();
error TargetAlreadyReported();
error InsufficientFunds();
error FailedPaymentTransfer();


/**
 * @title SoulboundSkillGraph
 * @dev A decentralized reputation and skill graph with AI-assisted validation and soulbound badges.
 *      This contract enables users to declare skills, receive endorsements, participate in AI-validated
 *      challenges, and earn non-transferable (soulbound) badges. It incorporates economic incentives
 *      and community moderation to foster a trustworthy and dynamic skill network.
 *
 * @outline
 * 1.  **Core Identity & Profile Management**: Users register a profile and manage its metadata.
 * 2.  **Skill Declaration & Endorsement**: Users declare skills and endorse others, backed by a stake.
 * 3.  **Dynamic Reputation Score**: An on-chain calculation based on endorsed skills, challenge completions, and AI feedback.
 * 4.  **Soulbound Badges (SBTs)**: Non-transferable tokens representing achievements, issued by the contract.
 * 5.  **AI-Assisted Skill Challenges**: Propose and participate in challenges, with results validated by an authorized AI Oracle.
 * 6.  **Community Curation & Governance**: Mechanisms for reporting misconduct and flagging AI validations.
 * 7.  **Economic Incentives**: Staking for endorsements and challenges, reward distribution, and protocol fees.
 * 8.  **Protocol Administration**: Owner and AI Oracle management, contract pausing.
 *
 * @function_summary
 * - **Profile & Skill Management:**
 *   1.  `registerProfile(string _profileURI)`: Creates a new user profile with a metadata URI.
 *   2.  `updateProfileURI(string _newProfileURI)`: Updates the metadata URI for the caller's profile.
 *   3.  `declareSkill(bytes32 _skillHash)`: Adds a skill to the caller's profile using a unique hash.
 *   4.  `retractSkill(bytes32 _skillHash)`: Removes a declared skill; refunds all associated endorsement stakes.
 *   5.  `endorseSkill(address _recipient, bytes32 _skillHash, uint256 _stakeAmount)`: Endorses a recipient for a skill, requiring a payable stake for credibility and a protocol fee.
 *   6.  `revokeEndorsement(address _recipient, bytes32 _skillHash)`: Revokes an endorsement and refunds the stake to the endorser.
 *   7.  `getProfileDetails(address _user)`: Retrieves the profile URI and declared skill hashes for a user.
 *   8.  `getSkillEndorsements(address _user, bytes32 _skillHash)`: Gets all endorser addresses, total stake, and count for a specific skill.
 * - **Reputation & Soulbound Badges:**
 *   9.  `calculateReputationScore(address _user)`: Calculates a user's dynamic reputation based on endorsements, challenge successes, and misconduct reports.
 *   10. `issueSoulboundBadge(address _recipient, bytes32 _badgeId, string _badgeURI)`: Issues a new non-transferable badge to a recipient (owner only).
 *   11. `revokeSoulboundBadge(address _recipient, bytes32 _badgeId)`: Revokes an issued soulbound badge (owner only), marking it as inactive.
 *   12. `updateSoulboundBadgeURI(bytes32 _badgeId, string _newBadgeURI)`: Updates the metadata URI for an existing soulbound badge (owner only).
 *   13. `balanceOfSBT(address _owner)`: Returns the number of unrevoked SBTs held by an address.
 *   14. `tokenURISBT(bytes32 _badgeId)`: Returns the URI for a given SBT, or an empty string if not found or revoked.
 * - **AI-Assisted Skill Challenges:**
 *   15. `proposeSkillChallenge(bytes32 _skillHash, string _challengeURI, uint256 _rewardPool, uint256 _requiredStake)`: Proposes a new skill challenge with rewards and stake (owner only).
 *   16. `participateInChallenge(bytes32 _challengeId, string _submissionURI)`: Allows a user to participate by submitting a solution and staking funds.
 *   17. `submitAIValidationResult(bytes32 _challengeId, address _participant, bool _isSuccessful, string _aiFeedbackURI)`: The authorized AI Oracle submits the validation result for a participant's submission.
 *   18. `finalizeChallengeOutcome(bytes32 _challengeId, address _participant)`: Finalizes a challenge, distributing rewards and issuing a badge to successful participants (can be called by anyone).
 *   19. `flagAIValidation(bytes32 _challengeId, address _participant, string _reasonURI)`: Allows users to flag a potentially incorrect AI validation decision.
 * - **Community Curation & Protocol Management:**
 *   20. `reportMisconduct(address _target, string _reasonURI)`: Allows users to report others for misconduct, affecting their reputation.
 *   21. `setAIPanelOracle(address _newOracle)`: Sets the address of the trusted AI Oracle (owner only).
 *   22. `fundProtocol()`: Allows anyone to send ETH to the contract for general funding.
 *   23. `withdrawProtocolFees(address _to)`: Allows the owner to withdraw accumulated protocol fees.
 *   24. `pauseContract()`: Pauses contract functionality in emergencies (owner only).
 *   25. `unpauseContract()`: Unpauses contract functionality (owner only).
 */
contract SoulboundSkillGraph is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    address public aiPanelOracle;
    uint256 public nextChallengeId;
    uint256 public constant PROTOCOL_FEE_PERCENT = 2; // 2% protocol fee on certain actions
    uint256 public protocolFeeAccrued;

    // --- Struct Definitions ---

    struct Profile {
        string profileURI;
        bool exists;
        mapping(bytes32 => SkillDeclaration) skills; // skillHash => SkillDeclaration
        bytes32[] declaredSkillHashes; // For easier iteration of declared skills
    }

    struct SkillDeclaration {
        bool declared;
        mapping(address => Endorsement) endorsers; // endorserAddress => Endorsement
        address[] currentEndorsers; // For easier iteration of endorsers
        uint256 totalEndorsementStake;
        uint256 endorsementCount;
    }

    struct Endorsement {
        bool exists;
        address endorser;
        uint256 stake;
        uint256 endorsementTimestamp;
    }

    struct SoulboundBadge {
        string badgeURI;
        address holder;
        uint256 issueTimestamp;
        bool revoked;
        bool exists; // To distinguish between non-existent and revoked
    }

    struct SkillChallenge {
        bytes32 skillHash;
        string challengeURI;
        uint256 rewardPool;
        uint256 requiredStake;
        uint256 challengeCreationTimestamp;
        mapping(address => ChallengeParticipant) participants;
        address[] currentParticipants; // For easier iteration of participants
        bool resolved;
        bool exists;
        address creator;
    }

    struct ChallengeParticipant {
        string submissionURI;
        uint256 stakedAmount;
        bool submitted;
        bool aiValidated; // AI's final decision
        string aiFeedbackURI;
        bool validationFlagged; // If user flagged AI's decision
        bool rewarded;
        uint256 submissionTimestamp;
    }

    struct MisconductReport {
        address reporter;
        string reasonURI;
        uint256 reportTimestamp;
        bool resolved;
    }

    // --- Mappings ---
    mapping(address => Profile) public profiles;
    mapping(uint256 => SkillChallenge) public challenges; // challengeId => SkillChallenge
    mapping(bytes32 => SoulboundBadge) public soulboundBadges; // badgeId => SoulboundBadge
    mapping(address => bytes32[]) public userSoulboundBadges; // userAddress => array of badgeIds
    mapping(address => MisconductReport[]) public misconductReports; // targetAddress => array of reports

    // --- Events ---
    event ProfileRegistered(address indexed user, string profileURI);
    event ProfileURIUpdated(address indexed user, string newProfileURI);
    event SkillDeclared(address indexed user, bytes32 indexed skillHash);
    event SkillRetracted(address indexed user, bytes32 indexed skillHash);
    event SkillEndorsed(address indexed endorser, address indexed recipient, bytes32 indexed skillHash, uint256 stakeAmount);
    event EndorsementRevoked(address indexed endorser, address indexed recipient, bytes32 indexed skillHash, uint256 refundedStake);
    event ReputationScoreCalculated(address indexed user, uint256 score);
    event SoulboundBadgeIssued(address indexed recipient, bytes32 indexed badgeId, string badgeURI);
    event SoulboundBadgeRevoked(address indexed recipient, bytes32 indexed badgeId);
    event SoulboundBadgeURIUpdated(bytes32 indexed badgeId, string newBadgeURI);
    event SkillChallengeProposed(uint256 indexed challengeId, bytes32 indexed skillHash, uint256 rewardPool, uint256 requiredStake, string challengeURI);
    event ChallengeParticipated(uint256 indexed challengeId, address indexed participant, string submissionURI, uint256 stakedAmount);
    event AIValidationSubmitted(uint256 indexed challengeId, address indexed participant, bool isSuccessful, string aiFeedbackURI);
    event ChallengeOutcomeFinalized(uint256 indexed challengeId, address indexed participant, bool success, uint256 totalAmount); // totalAmount includes stake refund + reward
    event AIValidationFlagged(uint256 indexed challengeId, address indexed participant, address indexed flipper, string reasonURI);
    event MisconductReported(address indexed reporter, address indexed target, string reasonURI);
    event AIPanelOracleSet(address indexed oldOracle, address indexed newOracle);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiPanelOracle) revert NotAIOracle();
        _;
    }

    // --- Constructor ---
    constructor(address _aiPanelOracle) Ownable(msg.sender) {
        if (_aiPanelOracle == address(0)) revert InvalidAddress();
        aiPanelOracle = _aiPanelOracle;
        nextChallengeId = 1;
    }

    // --- 1. registerProfile(string _profileURI) ---
    /**
     * @dev Creates a new user profile.
     * @param _profileURI IPFS or other URI pointing to the user's profile metadata.
     */
    function registerProfile(string memory _profileURI) public whenNotPaused {
        if (profiles[msg.sender].exists) revert ProfileAlreadyExists();
        profiles[msg.sender].profileURI = _profileURI;
        profiles[msg.sender].exists = true;
        emit ProfileRegistered(msg.sender, _profileURI);
    }

    // --- 2. updateProfileURI(string _newProfileURI) ---
    /**
     * @dev Updates the metadata URI for the caller's profile.
     * @param _newProfileURI The new IPFS or other URI for the profile metadata.
     */
    function updateProfileURI(string memory _newProfileURI) public whenNotPaused {
        if (!profiles[msg.sender].exists) revert ProfileNotFound();
        profiles[msg.sender].profileURI = _newProfileURI;
        emit ProfileURIUpdated(msg.sender, _newProfileURI);
    }

    // --- 3. declareSkill(bytes32 _skillHash) ---
    /**
     * @dev Declares a new skill for the caller's profile.
     * @param _skillHash A unique hash identifying the skill (e.g., keccak256("Solidity Programming")).
     */
    function declareSkill(bytes32 _skillHash) public whenNotPaused {
        if (!profiles[msg.sender].exists) revert ProfileNotFound();
        if (profiles[msg.sender].skills[_skillHash].declared) revert SkillAlreadyDeclared();

        profiles[msg.sender].skills[_skillHash].declared = true;
        profiles[msg.sender].declaredSkillHashes.push(_skillHash);
        emit SkillDeclared(msg.sender, _skillHash);
    }

    // --- 4. retractSkill(bytes32 _skillHash) ---
    /**
     * @dev Retracts a previously declared skill from the caller's profile.
     *      All associated endorsements will also be removed and stakes refunded to endorsers.
     * @param _skillHash The hash of the skill to retract.
     */
    function retractSkill(bytes32 _skillHash) public whenNotPaused {
        Profile storage senderProfile = profiles[msg.sender];
        if (!senderProfile.exists) revert ProfileNotFound();
        if (!senderProfile.skills[_skillHash].declared) revert SkillNotDeclared();

        SkillDeclaration storage skillDecl = senderProfile.skills[_skillHash];

        // Refund all stakes for this skill's endorsers
        for (uint256 i = 0; i < skillDecl.currentEndorsers.length; i++) {
            address endorser = skillDecl.currentEndorsers[i];
            Endorsement storage endorsement = skillDecl.endorsers[endorser];
            if (endorsement.exists) {
                (bool success, ) = endorser.call{value: endorsement.stake}("");
                if (!success) revert FailedPaymentTransfer();
                emit EndorsementRevoked(endorser, msg.sender, _skillHash, endorsement.stake);
            }
        }

        // Remove the skill from the array for iteration
        for (uint256 i = 0; i < senderProfile.declaredSkillHashes.length; i++) {
            if (senderProfile.declaredSkillHashes[i] == _skillHash) {
                senderProfile.declaredSkillHashes[i] = senderProfile.declaredSkillHashes[senderProfile.declaredSkillHashes.length - 1];
                senderProfile.declaredSkillHashes.pop();
                break;
            }
        }

        delete senderProfile.skills[_skillHash]; // Clear the skill data
        emit SkillRetracted(msg.sender, _skillHash);
    }

    // --- 5. endorseSkill(address _recipient, bytes32 _skillHash, uint256 _stakeAmount) ---
    /**
     * @dev Endorses another user for a specific skill, requiring a stake to add weight and deter spam.
     *      A protocol fee is applied to the stake amount.
     * @param _recipient The address of the user being endorsed.
     * @param _skillHash The hash of the skill being endorsed.
     * @param _stakeAmount The amount of ETH to stake for this endorsement.
     */
    function endorseSkill(address _recipient, bytes32 _skillHash, uint256 _stakeAmount) public payable whenNotPaused {
        if (!profiles[msg.sender].exists) revert ProfileNotFound();
        if (!profiles[_recipient].exists) revert ProfileNotFound();
        if (msg.sender == _recipient) revert("Cannot endorse yourself"); // Custom error preferred
        if (_stakeAmount == 0) revert NotEnoughStake();
        if (msg.value < _stakeAmount) revert NotEnoughStake(); // msg.value must be at least _stakeAmount

        SkillDeclaration storage recipientSkill = profiles[_recipient].skills[_skillHash];
        if (!recipientSkill.declared) revert SkillNotDeclared();
        if (recipientSkill.endorsers[msg.sender].exists) revert AlreadyEndorsedSkill();

        // Calculate protocol fee
        uint256 fee = _stakeAmount.mul(PROTOCOL_FEE_PERCENT).div(100);
        protocolFeeAccrued = protocolFeeAccrued.add(fee);

        // Calculate actual amount to be held as stake
        uint256 actualStake = _stakeAmount.sub(fee);

        // Ensure enough value was sent for the stake and fee
        if (msg.value < _stakeAmount) revert NotEnoughStake(); // Should not happen with previous check, but for safety

        // Refund any excess ETH sent
        if (msg.value > _stakeAmount) {
            (bool success, ) = msg.sender.call{value: msg.value.sub(_stakeAmount)}("");
            if (!success) revert FailedPaymentTransfer();
        }

        recipientSkill.endorsers[msg.sender] = Endorsement({
            exists: true,
            endorser: msg.sender,
            stake: actualStake,
            endorsementTimestamp: block.timestamp
        });
        recipientSkill.currentEndorsers.push(msg.sender);
        recipientSkill.totalEndorsementStake = recipientSkill.totalEndorsementStake.add(actualStake);
        recipientSkill.endorsementCount = recipientSkill.endorsementCount.add(1);

        emit SkillEndorsed(msg.sender, _recipient, _skillHash, actualStake);
    }

    // --- 6. revokeEndorsement(address _recipient, bytes32 _skillHash) ---
    /**
     * @dev Revokes a previously made endorsement and refunds the staked amount to the endorser.
     * @param _recipient The address of the user who was endorsed.
     * @param _skillHash The hash of the skill for which the endorsement was given.
     */
    function revokeEndorsement(address _recipient, bytes32 _skillHash) public whenNotPaused {
        if (!profiles[_recipient].exists) revert ProfileNotFound();
        SkillDeclaration storage recipientSkill = profiles[_recipient].skills[_skillHash];
        if (!recipientSkill.declared) revert SkillNotDeclared();

        Endorsement storage endorsement = recipientSkill.endorsers[msg.sender];
        if (!endorsement.exists) revert EndorsementNotFound();

        uint256 refundedStake = endorsement.stake;

        // Find and remove endorser from currentEndorsers array
        for (uint256 i = 0; i < recipientSkill.currentEndorsers.length; i++) {
            if (recipientSkill.currentEndorsers[i] == msg.sender) {
                recipientSkill.currentEndorsers[i] = recipientSkill.currentEndorsers[recipientSkill.currentEndorsers.length - 1];
                recipientSkill.currentEndorsers.pop();
                break;
            }
        }

        // Refund stake
        (bool success, ) = msg.sender.call{value: refundedStake}("");
        if (!success) revert FailedPaymentTransfer();

        recipientSkill.totalEndorsementStake = recipientSkill.totalEndorsementStake.sub(refundedStake);
        recipientSkill.endorsementCount = recipientSkill.endorsementCount.sub(1);
        delete recipientSkill.endorsers[msg.sender]; // Clear endorsement data

        emit EndorsementRevoked(msg.sender, _recipient, _skillHash, refundedStake);
    }

    // --- 7. getProfileDetails(address _user) ---
    /**
     * @dev Retrieves details of a user's profile.
     * @param _user The address of the user.
     * @return profileURI The metadata URI of the profile.
     * @return declaredSkillHashes An array of skill hashes declared by the user.
     */
    function getProfileDetails(address _user) public view returns (string memory profileURI, bytes32[] memory declaredSkillHashes) {
        if (!profiles[_user].exists) revert ProfileNotFound();
        return (profiles[_user].profileURI, profiles[_user].declaredSkillHashes);
    }

    // --- 8. getSkillEndorsements(address _user, bytes32 _skillHash) ---
    /**
     * @dev Retrieves details about endorsements for a specific skill on a user's profile.
     * @param _user The address of the user.
     * @param _skillHash The hash of the skill.
     * @return endorserAddresses An array of addresses that endorsed the skill.
     * @return totalStake The total staked amount for this skill (excluding fees).
     * @return count The total number of endorsements for this skill.
     */
    function getSkillEndorsements(address _user, bytes32 _skillHash) public view returns (address[] memory endorserAddresses, uint256 totalStake, uint256 count) {
        if (!profiles[_user].exists) revert ProfileNotFound();
        SkillDeclaration storage skillDecl = profiles[_user].skills[_skillHash];
        if (!skillDecl.declared) revert SkillNotDeclared();

        return (skillDecl.currentEndorsers, skillDecl.totalEndorsementStake, skillDecl.endorsementCount);
    }

    // --- 9. calculateReputationScore(address _user) ---
    /**
     * @dev Calculates a user's dynamic reputation score.
     *      This score aggregates endorsement stakes, challenge successes, and applies penalties for misconduct.
     *      A more complex system would involve time decay, endorser reputation weighting, etc.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateReputationScore(address _user) public view returns (uint256) {
        if (!profiles[_user].exists) revert ProfileNotFound();

        uint256 score = 0;
        Profile storage userProfile = profiles[_user];

        // Aggregate score from endorsed skills
        for (uint256 i = 0; i < userProfile.declaredSkillHashes.length; i++) {
            bytes32 skillHash = userProfile.declaredSkillHashes[i];
            score = score.add(userProfile.skills[skillHash].totalEndorsementStake.mul(5)); // Each unit of stake adds weight
            score = score.add(userProfile.skills[skillHash].endorsementCount.mul(10)); // Each endorsement adds a base amount
        }

        // Aggregate score from completed challenges
        for (uint256 i = 1; i < nextChallengeId; i++) { // Iterate through all challenges (up to nextChallengeId-1)
            SkillChallenge storage challenge = challenges[i];
            if (challenge.exists && challenge.participants[_user].submitted && challenge.participants[_user].aiValidated && challenge.participants[_user].rewarded) {
                // Simplified: Add a portion of reward pool + returned stake value for successful challenges
                score = score.add(challenge.rewardPool.div(2)).add(challenge.participants[_user].stakedAmount.div(2));
            }
        }

        // Penalty for misconduct reports (simplified: fixed penalty per unresolved report)
        for(uint256 i = 0; i < misconductReports[_user].length; i++) {
            if (!misconductReports[_user][i].resolved) {
                score = score.sub(100); // Apply a penalty for each unresolved report
            }
        }
        
        if (score < 0) return 0; // Ensure score doesn't go negative

        return score;
    }

    // --- 10. issueSoulboundBadge(address _recipient, bytes32 _badgeId, string _badgeURI) ---
    /**
     * @dev Issues a new non-transferable (soulbound) badge to a recipient. Only callable by the owner.
     * @param _recipient The address to issue the badge to.
     * @param _badgeId A unique ID for this specific badge instance.
     * @param _badgeURI IPFS or other URI pointing to the badge's metadata.
     */
    function issueSoulboundBadge(address _recipient, bytes32 _badgeId, string memory _badgeURI) public onlyOwner whenNotPaused {
        if (soulboundBadges[_badgeId].exists) revert BadgeAlreadyIssued();
        if (!profiles[_recipient].exists) revert ProfileNotFound();

        soulboundBadges[_badgeId] = SoulboundBadge({
            badgeURI: _badgeURI,
            holder: _recipient,
            issueTimestamp: block.timestamp,
            revoked: false,
            exists: true
        });
        userSoulboundBadges[_recipient].push(_badgeId);

        emit SoulboundBadgeIssued(_recipient, _badgeId, _badgeURI);
    }

    // --- 11. revokeSoulboundBadge(address _recipient, bytes32 _badgeId) ---
    /**
     * @dev Revokes an issued soulbound badge from a recipient. Only callable by the owner.
     * @param _recipient The address from whom to revoke the badge.
     * @param _badgeId The unique ID of the badge to revoke.
     */
    function revokeSoulboundBadge(address _recipient, bytes32 _badgeId) public onlyOwner whenNotPaused {
        SoulboundBadge storage badge = soulboundBadges[_badgeId];
        if (!badge.exists || badge.holder != _recipient) revert BadgeNotFound();
        if (badge.revoked) revert BadgeAlreadyRevoked();

        badge.revoked = true;
        // The badge remains in userSoulboundBadges array to preserve history, but is marked as revoked.
        emit SoulboundBadgeRevoked(_recipient, _badgeId);
    }

    // --- 12. updateSoulboundBadgeURI(bytes32 _badgeId, string _newBadgeURI) ---
    /**
     * @dev Updates the metadata URI for an existing soulbound badge. Useful for dynamic badges.
     * @param _badgeId The unique ID of the badge to update.
     * @param _newBadgeURI The new IPFS or other URI for the badge's metadata.
     */
    function updateSoulboundBadgeURI(bytes32 _badgeId, string memory _newBadgeURI) public onlyOwner whenNotPaused {
        SoulboundBadge storage badge = soulboundBadges[_badgeId];
        if (!badge.exists) revert BadgeNotFound();
        if (badge.revoked) revert BadgeAlreadyRevoked(); // Cannot update a revoked badge
        badge.badgeURI = _newBadgeURI;
        emit SoulboundBadgeURIUpdated(_badgeId, _newBadgeURI);
    }

    // --- 13. balanceOfSBT(address _owner) ---
    /**
     * @dev Returns the number of unrevoked SBTs held by an owner.
     * @param _owner The address to query the balance of.
     * @return The number of unrevoked SBTs.
     */
    function balanceOfSBT(address _owner) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < userSoulboundBadges[_owner].length; i++) {
            bytes32 badgeId = userSoulboundBadges[_owner][i];
            if (soulboundBadges[badgeId].exists && !soulboundBadges[badgeId].revoked) {
                count++;
            }
        }
        return count;
    }

    // --- 14. tokenURISBT(bytes32 _badgeId) ---
    /**
     * @dev Returns the URI for a given SBT.
     * @param _badgeId The ID of the SBT.
     * @return The URI for the SBT, or empty string if not found/revoked.
     */
    function tokenURISBT(bytes32 _badgeId) public view returns (string memory) {
        SoulboundBadge storage badge = soulboundBadges[_badgeId];
        if (!badge.exists || badge.revoked) return "";
        return badge.badgeURI;
    }

    // --- 15. proposeSkillChallenge(bytes32 _skillHash, string _challengeURI, uint256 _rewardPool, uint256 _requiredStake) ---
    /**
     * @dev Proposes a new skill challenge. Only callable by the owner.
     *      The `_rewardPool` funds are added to the contract's balance and allocated for this challenge.
     * @param _skillHash The skill associated with this challenge.
     * @param _challengeURI IPFS or other URI describing the challenge task.
     * @param _rewardPool The total ETH reward pool for successful participants.
     * @param _requiredStake The ETH amount participants must stake to join.
     */
    function proposeSkillChallenge(bytes32 _skillHash, string memory _challengeURI, uint256 _rewardPool, uint256 _requiredStake) public payable onlyOwner whenNotPaused {
        if (_rewardPool == 0 || _requiredStake == 0 || bytes(_challengeURI).length == 0) revert InvalidChallengeParameters();
        if (msg.value < _rewardPool) revert InsufficientFunds(); // Must fund the reward pool upon creation

        challenges[nextChallengeId] = SkillChallenge({
            skillHash: _skillHash,
            challengeURI: _challengeURI,
            rewardPool: _rewardPool,
            requiredStake: _requiredStake,
            challengeCreationTimestamp: block.timestamp,
            resolved: false,
            exists: true,
            creator: msg.sender
        });

        // Any excess ETH sent beyond the rewardPool is refunded
        if (msg.value > _rewardPool) {
            (bool success, ) = msg.sender.call{value: msg.value.sub(_rewardPool)}("");
            if (!success) revert FailedPaymentTransfer();
        }

        emit SkillChallengeProposed(nextChallengeId, _skillHash, _rewardPool, _requiredStake, _challengeURI);
        nextChallengeId++;
    }

    // --- 16. participateInChallenge(bytes32 _challengeId, string _submissionURI) ---
    /**
     * @dev Allows a user to participate in a skill challenge by submitting their solution and staking funds.
     *      A protocol fee is applied to the staked amount.
     * @param _challengeId The ID of the challenge.
     * @param _submissionURI IPFS or other URI pointing to the participant's solution.
     */
    function participateInChallenge(uint256 _challengeId, string memory _submissionURI) public payable whenNotPaused {
        SkillChallenge storage challenge = challenges[_challengeId];
        if (!challenge.exists) revert ChallengeNotFound();
        if (challenge.resolved) revert ChallengeAlreadyResolved();
        if (!profiles[msg.sender].exists) revert ProfileNotFound(); // Must have a profile to participate
        if (challenge.participants[msg.sender].submitted) revert("Already participated in this challenge"); // Custom error preferred
        if (msg.value < challenge.requiredStake) revert NotEnoughStake();
        if (bytes(_submissionURI).length == 0) revert InvalidSubmissionURI();

        // Calculate protocol fee on stake
        uint256 fee = challenge.requiredStake.mul(PROTOCOL_FEE_PERCENT).div(100);
        protocolFeeAccrued = protocolFeeAccrued.add(fee);

        // Actual stake amount to be held by the contract for refund/reward
        uint256 actualStakeAmount = challenge.requiredStake.sub(fee);

        // Refund any excess ETH sent beyond required stake + fee
        if (msg.value > challenge.requiredStake) {
            (bool success, ) = msg.sender.call{value: msg.value.sub(challenge.requiredStake)}("");
            if (!success) revert FailedPaymentTransfer();
        }

        challenge.participants[msg.sender] = ChallengeParticipant({
            submissionURI: _submissionURI,
            stakedAmount: actualStakeAmount,
            submitted: true,
            aiValidated: false,
            aiFeedbackURI: "",
            validationFlagged: false,
            rewarded: false,
            submissionTimestamp: block.timestamp
        });
        challenge.currentParticipants.push(msg.sender);

        emit ChallengeParticipated(_challengeId, msg.sender, _submissionURI, actualStakeAmount);
    }

    // --- 17. submitAIValidationResult(bytes32 _challengeId, address _participant, bool _isSuccessful, string _aiFeedbackURI) ---
    /**
     * @dev AI Oracle submits the validation result for a participant's challenge submission.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the participant.
     * @param _isSuccessful Whether the participant's submission was successful according to AI.
     * @param _aiFeedbackURI IPFS or other URI for AI's detailed feedback.
     */
    function submitAIValidationResult(uint256 _challengeId, address _participant, bool _isSuccessful, string memory _aiFeedbackURI) public onlyAIOracle whenNotPaused {
        SkillChallenge storage challenge = challenges[_challengeId];
        if (!challenge.exists) revert ChallengeNotFound();
        if (challenge.resolved) revert ChallengeAlreadyResolved();
        ChallengeParticipant storage participant = challenge.participants[_participant];
        if (!participant.submitted) revert NotChallengeParticipant();
        if (participant.aiValidated) revert AIAlreadyValidatedParticipant();

        participant.aiValidated = _isSuccessful;
        participant.aiFeedbackURI = _aiFeedbackURI;

        emit AIValidationSubmitted(_challengeId, _participant, _isSuccessful, _aiFeedbackURI);
    }

    // --- 18. finalizeChallengeOutcome(bytes32 _challengeId, address _participant) ---
    /**
     * @dev Finalizes a challenge outcome for a specific participant, distributing rewards and issuing badges.
     *      Can be called by anyone after AI validation is submitted.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the participant.
     */
    function finalizeChallengeOutcome(uint256 _challengeId, address _participant) public whenNotPaused {
        SkillChallenge storage challenge = challenges[_challengeId];
        if (!challenge.exists) revert ChallengeNotFound();
        if (challenge.resolved) revert ChallengeAlreadyResolved();
        ChallengeParticipant storage participant = challenge.participants[_participant];
        if (!participant.submitted) revert NotChallengeParticipant();
        if (participant.aiFeedbackURI == "") revert("AI validation not yet submitted"); // Custom error preferred
        if (participant.validationFlagged) revert AIValidationFlagged(); // Cannot finalize if flagged
        if (participant.rewarded) revert("Participant already rewarded/processed"); // Custom error preferred

        uint256 totalPayout = 0;

        if (participant.aiValidated) {
            // Participant succeeded: refund stake + distribute reward
            uint256 rewardAmount = challenge.rewardPool; // Simplified: entire pool for one winner. Can be divided among multiple.
            uint256 participantStake = participant.stakedAmount;

            // Issue SBT badge for success
            bytes32 newBadgeId = keccak256(abi.encodePacked("Challenge-", _challengeId, "-", _participant, "-", block.timestamp));
            issueSoulboundBadge(_participant, newBadgeId, challenge.challengeURI); // Using challengeURI as badgeURI

            // Transfer funds
            totalPayout = participantStake.add(rewardAmount);
            (bool success, ) = _participant.call{value: totalPayout}("");
            if (!success) revert FailedPaymentTransfer();

            challenge.rewardPool = 0; // The reward pool is depleted/assigned
            challenge.resolved = true; // Mark challenge as resolved after a successful participant (simplification)
        } else {
            // Participant failed: refund stake (or keep, based on challenge rules, here we refund)
            uint256 participantStake = participant.stakedAmount;
            (bool success, ) = _participant.call{value: participantStake}("");
            if (!success) revert FailedPaymentTransfer();
            totalPayout = participantStake; // Only stake refunded
        }

        participant.rewarded = true; // Mark participant as processed
        emit ChallengeOutcomeFinalized(_challengeId, _participant, participant.aiValidated, totalPayout);
    }

    // --- 19. flagAIValidation(bytes32 _challengeId, address _participant, string _reasonURI) ---
    /**
     * @dev Allows a user to flag the AI's validation decision for a challenge, initiating a dispute.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the participant whose validation is being flagged.
     * @param _reasonURI IPFS or other URI explaining why the AI's decision is considered incorrect.
     */
    function flagAIValidation(uint256 _challengeId, address _participant, string memory _reasonURI) public whenNotPaused {
        SkillChallenge storage challenge = challenges[_challengeId];
        if (!challenge.exists) revert ChallengeNotFound();
        ChallengeParticipant storage participant = challenge.participants[_participant];
        if (!participant.submitted) revert NotChallengeParticipant();
        if (participant.aiFeedbackURI == "") revert("AI has not validated this yet");
        if (participant.validationFlagged) revert("AI validation already flagged");

        participant.validationFlagged = true;
        // In a real system, this would trigger a more complex dispute resolution process (e.g., DAO vote, arbitration).
        // For simplicity, we just record the flag and prevent immediate finalization.

        emit AIValidationFlagged(_challengeId, _participant, msg.sender, _reasonURI);
    }

    // --- 20. reportMisconduct(address _target, string _reasonURI) ---
    /**
     * @dev Allows users to report other profiles for misconduct. This adds a record to the target's profile
     *      and affects their reputation score.
     * @param _target The address of the user being reported.
     * @param _reasonURI IPFS or other URI explaining the reason for the report.
     */
    function reportMisconduct(address _target, string memory _reasonURI) public whenNotPaused {
        if (!profiles[_target].exists) revert ProfileNotFound();
        if (msg.sender == _target) revert CannotReportYourself();

        // Prevent duplicate unresolved reports from the same reporter for the same target
        for(uint256 i = 0; i < misconductReports[_target].length; i++) {
            if(misconductReports[_target][i].reporter == msg.sender && !misconductReports[_target][i].resolved) {
                revert TargetAlreadyReported();
            }
        }

        misconductReports[_target].push(MisconductReport({
            reporter: msg.sender,
            reasonURI: _reasonURI,
            reportTimestamp: block.timestamp,
            resolved: false
        }));

        emit MisconductReported(msg.sender, _target, _reasonURI);
    }
    
    // --- (Additional function for dispute resolution committee to mark report as resolved) ---
    // This is not part of the initial 20+ count but would be a natural extension for reports.
    // function resolveMisconductReport(address _target, uint256 _reportIndex, bool _isGuilty) public onlyModerationCommittee {
    //     if (_reportIndex >= misconductReports[_target].length) revert("Invalid report index");
    //     MisconductReport storage report = misconductReports[_target][_reportIndex];
    //     if (report.resolved) revert("Report already resolved");
    //     report.resolved = true;
    //     // Further logic: apply permanent penalty, suspend profile, etc. based on _isGuilty
    //     emit MisconductReportResolved(_target, _reportIndex, _isGuilty);
    // }

    // --- 21. setAIPanelOracle(address _newOracle) ---
    /**
     * @dev Sets the address of the trusted AI Oracle. Only callable by the owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIPanelOracle(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) revert InvalidAddress();
        emit AIPanelOracleSet(aiPanelOracle, _newOracle);
        aiPanelOracle = _newOracle;
    }

    // --- 22. fundProtocol() ---
    /**
     * @dev Allows anyone to send ETH to the contract, e.g., to top up reward pools or general operations.
     */
    function fundProtocol() public payable whenNotPaused {
        if (msg.value == 0) revert InsufficientFunds();
        emit FundsDeposited(msg.sender, msg.value);
    }

    // --- 23. withdrawProtocolFees(address _to) ---
    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     * @param _to The address to send the fees to.
     */
    function withdrawProtocolFees(address _to) public onlyOwner {
        if (_to == address(0)) revert InvalidAddress();
        uint256 amount = protocolFeeAccrued;
        if (amount == 0) revert InsufficientFunds(); // No fees to withdraw
        protocolFeeAccrued = 0; // Reset accumulated fees
        (bool success, ) = _to.call{value: amount}("");
        if (!success) revert FailedPaymentTransfer();
        emit ProtocolFeesWithdrawn(_to, amount);
    }

    // --- 24. pauseContract() ---
    /**
     * @dev Pauses contract functionality in emergencies. Only callable by the owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    // --- 25. unpauseContract() ---
    /**
     * @dev Unpauses contract functionality. Only callable by the owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }
}
```