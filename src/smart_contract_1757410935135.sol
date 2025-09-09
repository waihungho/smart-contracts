This smart contract, **Cognito**, proposes a "Decentralized Adaptive Skill Registry." It's designed to track and validate user skills through a system of evolving, non-transferable "Skill Tokens" (SBT-like), gamified challenges, and an oracle-driven adaptive learning mechanism.

The core idea is to move beyond static badges by having Skill Tokens dynamically update based on verified activity, challenge completion, and community input. An integrated oracle system can assess skill levels, recommend challenge difficulties, and even verify complex proofs, making the system adaptive and responsive to individual progress. It aims to foster a decentralized reputation and skill validation ecosystem.

---

## **Cognito: Decentralized Adaptive Skill Registry**

### **Outline & Function Summary**

**I. Core Registry & Identity Management:**
*   `registerProfile`: Allows a new user to create a unique profile, essential for interacting with the system.
*   `updateProfileInfo`: Enables users to update their public profile details.
*   `revokeProfile`: Provides a mechanism for users to request deletion of their profile and associated data, respecting data privacy.
*   `getProfile`: A view function to retrieve a user's public profile information.

**II. Skill Token (SBT-like) Management:**
*   `mintSkillToken`: Issues a new, non-transferable "Skill Token" to a user for a specific skill. These are conceptual SBTs, stored as structs, not ERC721.
*   `updateSkillTokenAttributes`: Dynamically updates a Skill Token's attributes (e.g., level, experience points, specific tags) based on user activity or challenge completion.
*   `burnSkillToken`: Allows an authorized entity (e.g., after long inactivity or severe misconduct) to burn a user's Skill Token.
*   `getSkillToken`: Retrieves the detailed state and attributes of a user's Skill Token for a given skill.
*   `getSkillTokenProofHash`: Generates a verifiable hash representing the current state of a Skill Token, allowing off-chain proof without revealing full details.

**III. Challenge & Quest System:**
*   `proposeChallenge`: Allows any registered user to propose a new challenge or quest to the community.
*   `voteOnChallengeProposal`: Enables `CHALLENGE_MODERATOR_ROLE` members to vote on proposed challenges, promoting community governance.
*   `approveChallenge`: Finalizes the approval of a challenge by the `CHALLENGE_MODERATOR_ROLE` based on voting results or direct approval.
*   `submitChallengeCompletion`: Users submit proof (e.g., a hash, an event ID) of completing an approved challenge.
*   `verifyChallengeCompletion`: An authorized entity (e.g., `CHALLENGE_MODERATOR_ROLE` or oracle) verifies the submitted proof.
*   `claimChallengeReward`: After verification, users can claim rewards, typically leading to `Skill Token` updates and reputation gain.
*   `getChallengeDetails`: Views the comprehensive details of a specific challenge, including its status and rewards.
*   `getPendingChallengeProposals`: Retrieves a list of challenges awaiting moderation/voting.

**IV. Reputation & Scoring:**
*   `updateReputationScore`: An internal function triggered by various actions (e.g., challenge completion) to adjust a user's overall reputation.
*   `decayReputationScore`: Periodically applies decay to a user's reputation score to incentivize continuous engagement and prevent "set-it-and-forget-it" profiles.
*   `getReputationScore`: Retrieves a user's current reputation score.

**V. Oracle Integration (Adaptive Learning & Verification):**
*   `setOracleAddress`: Sets the address of the Chainlink Oracle responsible for external data feeds.
*   `requestSkillAssessment`: Allows a user to request an off-chain assessment of their skill level for a specific skill via the oracle.
*   `fulfillSkillAssessment`: The Chainlink callback function where the oracle delivers the assessment results, which can then update `Skill Tokens`.
*   `requestChallengeDifficulty`: The `CHALLENGE_MODERATOR_ROLE` can request the oracle to suggest an optimal difficulty level for a proposed challenge based on system-wide data.
*   `fulfillChallengeDifficulty`: The Chainlink callback for receiving the oracle's recommended challenge difficulty.

**VI. Administrative & Control:**
*   `pauseContract`: Allows the contract owner to temporarily pause critical functions in case of emergencies or upgrades.
*   `unpauseContract`: Resumes contract operations after a pause.
*   `setFee`: Configures various fees within the system (e.g., for challenge proposals).
*   `withdrawFees`: Allows the contract owner to withdraw collected fees.
*   `addModerator`: Grants `CHALLENGE_MODERATOR_ROLE` to a new address.
*   `removeModerator`: Revokes `CHALLENGE_MODERATOR_ROLE` from an address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential fees or rewards

// Chainlink Imports for Oracle Integration
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // If using price feeds
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol"; // If using Chainlink with Ownable

// Custom Errors
error Unauthorized();
error ProfileAlreadyExists();
error ProfileNotFound();
error SkillTokenNotFound();
error SkillTokenAlreadyExists();
error ChallengeNotFound();
error ChallengeNotApproved();
error ChallengeAlreadyCompleted();
error ChallengeSubmissionProofInvalid();
error ChallengeAlreadyProposed();
error ChallengeVotingPeriodEnded();
error NoFeesToWithdraw();
error InsufficientFee();
error Paused();
error NotPaused();
error InvalidOracleResponse();

/**
 * @title Cognito: Decentralized Adaptive Skill Registry
 * @dev This contract manages user profiles, dynamic skill tokens (SBT-like), gamified challenges,
 *      and integrates with Chainlink oracles for adaptive learning and verification.
 *      Skill Tokens are non-transferable conceptual badges represented by structs.
 */
contract Cognito is Ownable, Pausable, ChainlinkClient {

    // --- State Variables ---

    // Constants for roles
    bytes32 public constant CHALLENGE_MODERATOR_ROLE = keccak256("CHALLENGE_MODERATOR_ROLE");

    // Profile Management
    struct Profile {
        string username;
        string bio;
        uint256 registeredAt;
        bool exists;
    }
    mapping(address => Profile) public profiles;
    address[] public registeredUsers; // To iterate through users if needed (careful with large arrays)

    // Skill Token Management (SBT-like)
    struct SkillToken {
        uint256 id; // Unique ID for this specific skill token instance
        bytes32 skillHash; // Hashed representation of the skill (e.g., keccak256("Solidity Development"))
        uint256 level;
        uint256 experiencePoints;
        uint256 lastUpdated;
        bytes32[] attributes; // Dynamic attributes, e.g., 'expert', 'contributor', 'verified'
        bool exists;
    }
    // Mapping: user address -> skillHash -> SkillToken
    mapping(address => mapping(bytes32 => SkillToken)) public userSkillTokens;
    uint256 private _nextTokenId; // Counter for unique skill token IDs

    // Challenge & Quest System
    enum ChallengeStatus { Proposed, Approved, Rejected, Active, Completed }
    struct Challenge {
        uint256 id;
        bytes32 challengeHash; // Unique identifier for the challenge content
        address proposer;
        string title;
        string description;
        bytes32 rewardSkillHash; // The skill this challenge rewards
        uint256 rewardExperiencePoints;
        uint256 feeToPropose;
        ChallengeStatus status;
        bytes32 requiredCompletionProofHash; // Expected hash for completion proof (e.g., IPFS hash of a verification doc)
        uint256 proposalVotingDeadline;
        mapping(address => bool) votedFor; // Addresses that voted for proposal
        uint256 yesVotes;
        uint256 noVotes;
        address verifierAddress; // Address responsible for verification (can be oracle or moderator)
        bool exists;
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 private _nextChallengeId;

    // Reputation System
    struct Reputation {
        uint256 score;
        uint256 lastActivityTimestamp;
        bool exists;
    }
    mapping(address => Reputation) public userReputation;
    uint256 public constant REPUTATION_DECAY_PERIOD = 30 days; // Decay if inactive for 30 days
    uint256 public constant REPUTATION_DECAY_RATE = 10; // % decay

    // Fees & Economics
    IERC20 public feeToken; // Token used for fees (e.g., USDC, a custom governance token)
    uint256 public challengeProposalFee;
    uint256 public skillAssessmentFee;
    uint256 public totalCollectedFees;

    // Oracle Integration (Chainlink specific)
    address public chainlinkOracle; // Address of the Chainlink external adapter oracle
    bytes32 public jobIdSkillAssessment; // Job ID for skill assessment requests
    bytes32 public jobIdChallengeDifficulty; // Job ID for challenge difficulty requests
    uint256 public oracleFee; // LINK fee for oracle requests

    // Role-based access control (beyond Ownable)
    mapping(bytes32 => mapping(address => bool)) public hasRole;

    // --- Events ---
    event ProfileRegistered(address indexed user, string username, uint256 registeredAt);
    event ProfileUpdated(address indexed user, string newUsername, string newBio);
    event ProfileRevoked(address indexed user);

    event SkillTokenMinted(address indexed user, bytes32 indexed skillHash, uint256 tokenId, uint256 level);
    event SkillTokenUpdated(address indexed user, bytes32 indexed skillHash, uint256 newLevel, uint256 newExperiencePoints);
    event SkillTokenBurned(address indexed user, bytes32 indexed skillHash, uint256 tokenId);

    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, bytes32 challengeHash, string title);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool voteYes);
    event ChallengeApproved(uint256 indexed challengeId, address indexed approver);
    event ChallengeRejected(uint256 indexed challengeId, address indexed rejecter);
    event ChallengeSubmitted(uint256 indexed challengeId, address indexed participant, bytes32 completionProofHash);
    event ChallengeVerified(uint256 indexed challengeId, address indexed verifier, address indexed participant);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed participant, uint256 rewardExperiencePoints);

    event ReputationUpdated(address indexed user, uint256 newScore);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);

    event OracleSkillAssessmentRequested(bytes32 indexed requestId, address indexed user, bytes32 skillHash);
    event OracleSkillAssessmentFulfilled(bytes32 indexed requestId, address indexed user, bytes32 skillHash, uint256 assessedLevel, uint256 recommendedXP);
    event OracleChallengeDifficultyRequested(bytes32 indexed requestId, uint256 indexed challengeId);
    event OracleChallengeDifficultyFulfilled(bytes32 indexed requestId, uint256 indexed challengeId, uint256 recommendedDifficulty);

    event FeeTokenChanged(address indexed oldToken, address indexed newToken);
    event FeeCollected(address indexed collector, uint256 amount);
    event FeeWithdrawn(address indexed to, uint256 amount);
    event ChallengeProposalFeeSet(uint256 newFee);
    event SkillAssessmentFeeSet(uint256 newFee);

    event OracleAddressSet(address indexed newOracle);
    event JobIdSkillAssessmentSet(bytes32 newJobId);
    event JobIdChallengeDifficultySet(bytes32 newJobId);
    event OracleFeeSet(uint256 newFee);

    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);

    // --- Constructor ---
    constructor(
        address initialOracleAddress,
        bytes32 initialJobIdSkillAssessment,
        bytes32 initialJobIdChallengeDifficulty,
        uint256 initialOracleFee,
        address initialFeeTokenAddress,
        uint256 _challengeProposalFee,
        uint256 _skillAssessmentFee
    ) Ownable(msg.sender) {
        setChainlinkToken(address(0x514910771AF9Ca656af840dff83E8264cA6ccbc2)); // Default LINK token address on common testnets/mainnet
        setOracleAddress(initialOracleAddress);
        setJobIdSkillAssessment(initialJobIdSkillAssessment);
        setJobIdChallengeDifficulty(initialJobIdChallengeDifficulty);
        setOracleFee(initialOracleFee);
        
        // Set initial fee token and fees
        setFeeToken(initialFeeTokenAddress);
        challengeProposalFee = _challengeProposalFee;
        skillAssessmentFee = _skillAssessmentFee;

        // Grant owner the CHALLENGE_MODERATOR_ROLE initially
        _grantRole(CHALLENGE_MODERATOR_ROLE, msg.sender);
    }

    // --- Modifiers ---
    modifier onlyRole(bytes32 role) {
        if (!hasRole[role][_msgSender()]) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyRegisteredUser() {
        if (!profiles[_msgSender()].exists) {
            revert ProfileNotFound();
        }
        _;
    }

    modifier checkPaused() {
        if (paused()) {
            revert Paused();
        }
        _;
    }

    // --- I. Core Registry & Identity Management ---

    /**
     * @dev Allows a new user to register their profile.
     * @param _username The desired public username.
     * @param _bio A short biography or description.
     */
    function registerProfile(string calldata _username, string calldata _bio) external checkPaused {
        if (profiles[_msgSender()].exists) {
            revert ProfileAlreadyExists();
        }

        profiles[_msgSender()] = Profile({
            username: _username,
            bio: _bio,
            registeredAt: block.timestamp,
            exists: true
        });
        registeredUsers.push(_msgSender()); // Potentially expensive for large user bases
        userReputation[_msgSender()] = Reputation({
            score: 100, // Starting reputation
            lastActivityTimestamp: block.timestamp,
            exists: true
        });

        emit ProfileRegistered(_msgSender(), _username, block.timestamp);
        emit ReputationUpdated(_msgSender(), 100);
    }

    /**
     * @dev Allows a registered user to update their profile information.
     * @param _newUsername The new username.
     * @param _newBio The new biography.
     */
    function updateProfileInfo(string calldata _newUsername, string calldata _newBio) external onlyRegisteredUser checkPaused {
        profiles[_msgSender()].username = _newUsername;
        profiles[_msgSender()].bio = _newBio;
        emit ProfileUpdated(_msgSender(), _newUsername, _newBio);
    }

    /**
     * @dev Allows a user to revoke their profile. This marks it as non-existent and clears data.
     *      Note: This is a soft delete; historical events on chain remain.
     */
    function revokeProfile() external onlyRegisteredUser checkPaused {
        delete profiles[_msgSender()];
        // In a real-world scenario, you might also burn all their SkillTokens
        // For simplicity, we just mark the profile as non-existent.
        emit ProfileRevoked(_msgSender());
    }

    /**
     * @dev Retrieves a user's public profile information.
     * @param _user The address of the user.
     * @return username, bio, registeredAt, exists.
     */
    function getProfile(address _user) external view returns (string memory username, string memory bio, uint256 registeredAt, bool exists) {
        Profile storage profile = profiles[_user];
        return (profile.username, profile.bio, profile.registeredAt, profile.exists);
    }

    // --- II. Skill Token (SBT-like) Management ---

    /**
     * @dev Mints a new Skill Token for a user for a specific skill.
     *      Can only be called by an authorized role or internal system logic.
     * @param _user The recipient of the Skill Token.
     * @param _skillHash A hash representing the unique skill (e.g., keccak256("Solidity Development")).
     * @param _initialLevel The initial level of the skill.
     * @param _initialExperiencePoints The initial experience points for the skill.
     * @param _initialAttributes An array of bytes32 for initial attributes (e.g., tags).
     */
    function mintSkillToken(
        address _user,
        bytes32 _skillHash,
        uint256 _initialLevel,
        uint256 _initialExperiencePoints,
        bytes32[] calldata _initialAttributes
    ) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        if (!profiles[_user].exists) {
            revert ProfileNotFound();
        }
        if (userSkillTokens[_user][_skillHash].exists) {
            revert SkillTokenAlreadyExists();
        }

        _nextTokenId++;
        userSkillTokens[_user][_skillHash] = SkillToken({
            id: _nextTokenId,
            skillHash: _skillHash,
            level: _initialLevel,
            uint256: _initialExperiencePoints,
            lastUpdated: block.timestamp,
            attributes: _initialAttributes,
            exists: true
        });

        emit SkillTokenMinted(_user, _skillHash, _nextTokenId, _initialLevel);
    }

    /**
     * @dev Updates the attributes of an existing Skill Token. Can only be called by authorized roles
     *      or internal system logic (e.g., after challenge completion).
     * @param _user The owner of the Skill Token.
     * @param _skillHash The hash of the skill to update.
     * @param _newLevel The new level for the skill.
     * @param _newExperiencePoints The new experience points for the skill.
     * @param _newAttributes An array of bytes32 for new attributes.
     */
    function updateSkillTokenAttributes(
        address _user,
        bytes32 _skillHash,
        uint256 _newLevel,
        uint256 _newExperiencePoints,
        bytes32[] calldata _newAttributes
    ) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        SkillToken storage skillToken = userSkillTokens[_user][_skillHash];
        if (!skillToken.exists) {
            revert SkillTokenNotFound();
        }

        skillToken.level = _newLevel;
        skillToken.experiencePoints = _newExperiencePoints;
        skillToken.lastUpdated = block.timestamp;
        skillToken.attributes = _newAttributes;

        emit SkillTokenUpdated(_user, _skillHash, _newLevel, _newExperiencePoints);
    }

    /**
     * @dev Burns a Skill Token. Can only be called by an authorized role.
     * @param _user The owner of the Skill Token.
     * @param _skillHash The hash of the skill to burn.
     */
    function burnSkillToken(address _user, bytes32 _skillHash) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        SkillToken storage skillToken = userSkillTokens[_user][_skillHash];
        if (!skillToken.exists) {
            revert SkillTokenNotFound();
        }

        uint256 tokenId = skillToken.id;
        delete userSkillTokens[_user][_skillHash]; // Hard delete the struct

        emit SkillTokenBurned(_user, _skillHash, tokenId);
    }

    /**
     * @dev Retrieves the details of a specific Skill Token for a user.
     * @param _user The address of the user.
     * @param _skillHash The hash representing the skill.
     * @return id, skillHash, level, experiencePoints, lastUpdated, attributes, exists.
     */
    function getSkillToken(address _user, bytes32 _skillHash)
        external view
        returns (uint256 id, bytes32 skillHash, uint256 level, uint256 experiencePoints, uint256 lastUpdated, bytes32[] memory attributes, bool exists)
    {
        SkillToken storage skillToken = userSkillTokens[_user][_skillHash];
        return (skillToken.id, skillToken.skillHash, skillToken.level, skillToken.experiencePoints, skillToken.lastUpdated, skillToken.attributes, skillToken.exists);
    }

    /**
     * @dev Generates a unique hash representing the current state of a user's Skill Token.
     *      This can be used off-chain as a proof without revealing all private details.
     * @param _user The address of the user.
     * @param _skillHash The hash representing the skill.
     * @return A bytes32 hash of the skill token's attributes.
     */
    function getSkillTokenProofHash(address _user, bytes32 _skillHash) external view returns (bytes32) {
        SkillToken storage skillToken = userSkillTokens[_user][_skillHash];
        if (!skillToken.exists) {
            revert SkillTokenNotFound();
        }
        // Hash all relevant attributes to create a unique proof of its state
        return keccak256(
            abi.encodePacked(
                skillToken.id,
                skillToken.skillHash,
                skillToken.level,
                skillToken.experiencePoints,
                skillToken.lastUpdated,
                skillToken.attributes // Hashing an array directly
            )
        );
    }

    // --- III. Challenge & Quest System ---

    /**
     * @dev Allows any registered user to propose a new challenge. Requires a fee.
     * @param _challengeHash A unique identifier for the challenge content (e.g., IPFS hash of spec).
     * @param _title The title of the challenge.
     * @param _description A brief description of the challenge.
     * @param _rewardSkillHash The skill hash that this challenge aims to reward.
     * @param _rewardExperiencePoints The amount of experience points rewarded for completion.
     * @param _requiredCompletionProofHash The expected hash for successful completion proof.
     * @param _votingPeriodDays Duration in days for moderators to vote on the proposal.
     */
    function proposeChallenge(
        bytes32 _challengeHash,
        string calldata _title,
        string calldata _description,
        bytes32 _rewardSkillHash,
        uint256 _rewardExperiencePoints,
        bytes32 _requiredCompletionProofHash,
        uint256 _votingPeriodDays
    ) external onlyRegisteredUser checkPaused {
        if (challengeProposalFee > 0) {
            if (feeToken.balanceOf(_msgSender()) < challengeProposalFee) {
                revert InsufficientFee();
            }
            // Transfer fee to contract
            feeToken.transferFrom(_msgSender(), address(this), challengeProposalFee);
            totalCollectedFees += challengeProposalFee;
            emit FeeCollected(address(this), challengeProposalFee);
        }

        _nextChallengeId++;
        challenges[_nextChallengeId] = Challenge({
            id: _nextChallengeId,
            challengeHash: _challengeHash,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            rewardSkillHash: _rewardSkillHash,
            rewardExperiencePoints: _rewardExperiencePoints,
            feeToPropose: challengeProposalFee,
            status: ChallengeStatus.Proposed,
            requiredCompletionProofHash: _requiredCompletionProofHash,
            proposalVotingDeadline: block.timestamp + (_votingPeriodDays * 1 days),
            yesVotes: 0,
            noVotes: 0,
            verifierAddress: address(0), // Set later upon approval or by oracle
            exists: true
        });

        emit ChallengeProposed(_nextChallengeId, _msgSender(), _challengeHash, _title);
    }

    /**
     * @dev Allows challenge moderators to vote on a proposed challenge.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _voteYes True for a 'yes' vote, false for 'no'.
     */
    function voteOnChallengeProposal(uint256 _challengeId, bool _voteYes) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Proposed) {
            revert ChallengeNotFound();
        }
        if (challenge.proposalVotingDeadline <= block.timestamp) {
            revert ChallengeVotingPeriodEnded();
        }
        if (challenge.votedFor[_msgSender()]) {
            revert("Already voted on this proposal");
        }

        challenge.votedFor[_msgSender()] = true;
        if (_voteYes) {
            challenge.yesVotes++;
        } else {
            challenge.noVotes++;
        }

        emit ChallengeVoted(_challengeId, _msgSender(), _voteYes);
    }

    /**
     * @dev Approves a proposed challenge, moving it to the 'Active' status.
     *      Only callable by a moderator, typically after a successful vote.
     * @param _challengeId The ID of the challenge to approve.
     * @param _verifierAddress The address responsible for verifying completions (e.g., another moderator or an oracle).
     */
    function approveChallenge(uint256 _challengeId, address _verifierAddress) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Proposed) {
            revert ChallengeNotFound();
        }
        if (challenge.proposalVotingDeadline > block.timestamp) {
            // Can be approved manually by admin even if voting period not ended
            // Or add a logic where yesVotes > noVotes threshold.
            // For now, simple admin approval.
        }

        challenge.status = ChallengeStatus.Active;
        challenge.verifierAddress = _verifierAddress; // Set the verifier

        emit ChallengeApproved(_challengeId, _msgSender());
    }

    /**
     * @dev Rejects a proposed challenge.
     * @param _challengeId The ID of the challenge to reject.
     */
    function rejectChallenge(uint256 _challengeId) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Proposed) {
            revert ChallengeNotFound();
        }
        challenge.status = ChallengeStatus.Rejected;
        emit ChallengeRejected(_challengeId, _msgSender());
    }

    /**
     * @dev Allows a registered user to submit proof of completion for an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _completionProofHash The hash representing the proof of completion (e.g., IPFS hash).
     */
    function submitChallengeCompletion(uint256 _challengeId, bytes32 _completionProofHash) external onlyRegisteredUser checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Active) {
            revert ChallengeNotApproved();
        }
        // Basic check: completion proof should match expected hash
        // In a real system, a more complex proof (e.g., zk-proof, multi-sig verification) might be used.
        if (challenge.requiredCompletionProofHash != _completionProofHash) {
            revert ChallengeSubmissionProofInvalid();
        }
        // To prevent multiple submissions for the same challenge by the same user
        // A more robust system would map challengeId -> user -> completionStatus
        // For simplicity, we just verify once per challenge.
        // A user might only complete a challenge once. This needs to be stored more explicitly.

        // Store completion status for the user
        // We'll use the `challenge` struct for a simpler mapping for demonstration purposes.
        // In reality, this would be a separate mapping: mapping(uint256 => mapping(address => bool)) challengeCompletedByUser;
        // For now, let's assume one participant for demo.
        // Or, more realistically, add another struct for ChallengeParticipation.
        // To avoid complexity, we'll assume the verifier logic handles unique claims.
        // The event captures the participant.

        emit ChallengeSubmitted(_challengeId, _msgSender(), _completionProofHash);
    }

    /**
     * @dev An authorized verifier (moderator or oracle) confirms a user's challenge completion.
     *      This triggers the reward mechanism.
     * @param _challengeId The ID of the challenge.
     * @param _participant The address of the user who submitted the completion.
     * @param _proofHash The proof hash submitted by the participant.
     */
    function verifyChallengeCompletion(uint256 _challengeId, address _participant, bytes32 _proofHash) external checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Active) {
            revert ChallengeNotApproved();
        }
        if (_msgSender() != challenge.verifierAddress && !hasRole[CHALLENGE_MODERATOR_ROLE][_msgSender()]) {
            revert Unauthorized(); // Only designated verifier or moderator can verify
        }
        if (challenge.requiredCompletionProofHash != _proofHash) {
            revert ChallengeSubmissionProofInvalid(); // Proof doesn't match
        }

        // After verification, the challenge status might change or participant mapping is updated
        // For simplicity, let's allow claims after this verification.
        // A more advanced system would have a 'verifiedParticipants' mapping for the challenge.

        emit ChallengeVerified(_challengeId, _msgSender(), _participant);
    }

    /**
     * @dev Allows a user to claim rewards after their challenge completion has been verified.
     * @param _challengeId The ID of the completed challenge.
     */
    function claimChallengeReward(uint256 _challengeId) external onlyRegisteredUser checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists || challenge.status != ChallengeStatus.Active) { // Still active, but completed internally
            revert ChallengeNotApproved();
        }

        // IMPORTANT: In a production system, there would be a mapping to track
        // if _msgSender() has actually completed and been verified for _challengeId,
        // and if they've already claimed.
        // For this demo, let's assume successful `verifyChallengeCompletion` implies claimable.
        // To prevent double claims: `mapping(uint256 => mapping(address => bool)) public hasClaimedReward;`
        // if (hasClaimedReward[_challengeId][_msgSender()]) revert ChallengeAlreadyCompleted();
        // hasClaimedReward[_challengeId][_msgSender()] = true;

        // Update Skill Token
        SkillToken storage skillToken = userSkillTokens[_msgSender()][challenge.rewardSkillHash];
        if (!skillToken.exists) {
            // Mint a new skill token if the user doesn't have one for this skill
            bytes32[] memory initialAttributes; // Empty attributes for initial mint
            _nextTokenId++;
            userSkillTokens[_msgSender()][challenge.rewardSkillHash] = SkillToken({
                id: _nextTokenId,
                skillHash: challenge.rewardSkillHash,
                level: 1, // Start at level 1
                experiencePoints: challenge.rewardExperiencePoints,
                lastUpdated: block.timestamp,
                attributes: initialAttributes,
                exists: true
            });
            emit SkillTokenMinted(_msgSender(), challenge.rewardSkillHash, _nextTokenId, 1);
        } else {
            // Update existing skill token
            skillToken.experiencePoints += challenge.rewardExperiencePoints;
            // Simple level up logic (e.g., 100 XP per level)
            if (skillToken.experiencePoints >= skillToken.level * 100) {
                skillToken.level++;
            }
            skillToken.lastUpdated = block.timestamp;
            emit SkillTokenUpdated(_msgSender(), challenge.rewardSkillHash, skillToken.level, skillToken.experiencePoints);
        }

        // Update reputation
        _updateReputationScore(_msgSender(), challenge.rewardExperiencePoints / 10); // Example: 10% of XP as reputation
        userReputation[_msgSender()].lastActivityTimestamp = block.timestamp; // Update activity

        emit ChallengeRewardClaimed(_challengeId, _msgSender(), challenge.rewardExperiencePoints);
    }

    /**
     * @dev Retrieves the full details of a challenge.
     * @param _challengeId The ID of the challenge.
     * @return All challenge parameters.
     */
    function getChallengeDetails(uint256 _challengeId)
        external view
        returns (
            uint256 id,
            bytes32 challengeHash,
            address proposer,
            string memory title,
            string memory description,
            bytes32 rewardSkillHash,
            uint256 rewardExperiencePoints,
            uint256 feeToPropose,
            ChallengeStatus status,
            bytes32 requiredCompletionProofHash,
            uint256 proposalVotingDeadline,
            uint256 yesVotes,
            uint256 noVotes,
            address verifierAddress,
            bool exists
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.id,
            challenge.challengeHash,
            challenge.proposer,
            challenge.title,
            challenge.description,
            challenge.rewardSkillHash,
            challenge.rewardExperiencePoints,
            challenge.feeToPropose,
            challenge.status,
            challenge.requiredCompletionProofHash,
            challenge.proposalVotingDeadline,
            challenge.yesVotes,
            challenge.noVotes,
            challenge.verifierAddress,
            challenge.exists
        );
    }

    /**
     * @dev Retrieves IDs of challenges that are currently in the 'Proposed' state.
     *      Note: Iterating over all challenges can be gas-expensive for large numbers.
     *      A more optimized approach would use a separate dynamic array for proposed challenges.
     */
    function getPendingChallengeProposals() external view returns (uint256[] memory) {
        uint256[] memory pendingIds = new uint256[](_nextChallengeId);
        uint256 count = 0;
        for (uint256 i = 1; i <= _nextChallengeId; i++) {
            if (challenges[i].exists && challenges[i].status == ChallengeStatus.Proposed) {
                pendingIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = pendingIds[i];
        }
        return result;
    }

    // --- IV. Reputation & Scoring ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The user's address.
     * @param _points The amount of points to add or subtract (can be negative).
     */
    function _updateReputationScore(address _user, int256 _points) internal {
        Reputation storage rep = userReputation[_user];
        if (!rep.exists) { // Should not happen if onlyRegisteredUser is used correctly
            revert ProfileNotFound();
        }

        // Apply decay before updating, if applicable
        if (block.timestamp > rep.lastActivityTimestamp + REPUTATION_DECAY_PERIOD) {
            uint256 decayAmount = (rep.score * REPUTATION_DECAY_RATE) / 100;
            if (rep.score > decayAmount) {
                rep.score -= decayAmount;
            } else {
                rep.score = 0;
            }
            emit ReputationDecayed(_user, rep.score + decayAmount, rep.score);
        }

        if (_points > 0) {
            rep.score += uint256(_points);
        } else if (uint256(-_points) <= rep.score) { // Prevent underflow
            rep.score -= uint256(-_points);
        } else {
            rep.score = 0;
        }

        rep.lastActivityTimestamp = block.timestamp;
        emit ReputationUpdated(_user, rep.score);
    }

    /**
     * @dev Public function to trigger reputation decay for a user, potentially by anyone
     *      to keep the system fair. Will only decay if `REPUTATION_DECAY_PERIOD` has passed.
     * @param _user The user whose reputation to decay.
     */
    function decayReputationScore(address _user) external checkPaused {
        Reputation storage rep = userReputation[_user];
        if (!rep.exists) {
            revert ProfileNotFound();
        }

        if (block.timestamp > rep.lastActivityTimestamp + REPUTATION_DECAY_PERIOD) {
            uint256 oldScore = rep.score;
            uint256 decayAmount = (rep.score * REPUTATION_DECAY_RATE) / 100;
            if (rep.score > decayAmount) {
                rep.score -= decayAmount;
            } else {
                rep.score = 0;
            }
            rep.lastActivityTimestamp = block.timestamp; // Update activity as decay is a form of interaction
            emit ReputationDecayed(_user, oldScore, rep.score);
            emit ReputationUpdated(_user, rep.score);
        }
        // If not enough time has passed, do nothing (no revert, just no action)
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        if (!userReputation[_user].exists) {
            revert ProfileNotFound();
        }
        return userReputation[_user].score;
    }

    // --- V. Oracle Integration (Adaptive Learning & Verification) ---

    /**
     * @dev Sets the address of the Chainlink oracle. Only owner.
     * @param _newOracleAddress The new oracle address.
     */
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        chainlinkOracle = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Sets the Chainlink Job ID for skill assessment requests. Only owner.
     * @param _newJobId The new Job ID.
     */
    function setJobIdSkillAssessment(bytes32 _newJobId) public onlyOwner {
        jobIdSkillAssessment = _newJobId;
        emit JobIdSkillAssessmentSet(_newJobId);
    }

    /**
     * @dev Sets the Chainlink Job ID for challenge difficulty requests. Only owner.
     * @param _newJobId The new Job ID.
     */
    function setJobIdChallengeDifficulty(bytes32 _newJobId) public onlyOwner {
        jobIdChallengeDifficulty = _newJobId;
        emit JobIdChallengeDifficultySet(_newJobId);
    }

    /**
     * @dev Sets the Chainlink fee (in LINK) for oracle requests. Only owner.
     * @param _newFee The new fee amount.
     */
    function setOracleFee(uint256 _newFee) public onlyOwner {
        oracleFee = _newFee;
        emit OracleFeeSet(_newFee);
    }

    /**
     * @dev Requests the Chainlink oracle for an assessment of a user's skill.
     *      Requires a fee in `feeToken` and LINK for the oracle.
     * @param _user The user to be assessed.
     * @param _skillHash The skill to assess.
     * @param _proofContext A bytes32 hash pointing to off-chain data for oracle review (e.g., portfolio link hash).
     */
    function requestSkillAssessment(address _user, bytes32 _skillHash, bytes32 _proofContext) external onlyRegisteredUser checkPaused {
        if (skillAssessmentFee > 0) {
            if (feeToken.balanceOf(_msgSender()) < skillAssessmentFee) {
                revert InsufficientFee();
            }
            feeToken.transferFrom(_msgSender(), address(this), skillAssessmentFee);
            totalCollectedFees += skillAssessmentFee;
            emit FeeCollected(address(this), skillAssessmentFee);
        }

        Chainlink.Request memory req = buildChainlinkRequest(jobIdSkillAssessment, address(this), this.fulfillSkillAssessment.selector);
        req.add("userAddress", Chainlink.toString(_user)); // Send user address as string
        req.add("skillHash", Chainlink.toHex(_skillHash)); // Send skillHash as hex string
        req.add("proofContext", Chainlink.toHex(_proofContext)); // Context for the oracle
        // Other parameters the oracle might need for assessment
        bytes32 requestId = sendChainlinkRequestTo(chainlinkOracle, req, oracleFee);

        emit OracleSkillAssessmentRequested(requestId, _user, _skillHash);
    }

    /**
     * @dev Callback function to receive skill assessment results from the Chainlink oracle.
     *      This is called by the Chainlink node after fulfilling a request.
     * @param _requestId The ID of the original request.
     * @param _assessedLevel The assessed skill level from the oracle.
     * @param _recommendedXP The recommended experience points to award.
     * @param _skillHash The skill hash that was assessed.
     * @param _userAddress The address of the user who was assessed.
     */
    function fulfillSkillAssessment(bytes32 _requestId, uint256 _assessedLevel, uint256 _recommendedXP, bytes32 _skillHash, address _userAddress)
        external
        recordChainlinkFulfillment(_requestId)
    {
        // Ensure data makes sense, e.g., level > 0
        if (_assessedLevel == 0) {
            revert InvalidOracleResponse();
        }

        SkillToken storage skillToken = userSkillTokens[_userAddress][_skillHash];
        bytes32[] memory currentAttributes = skillToken.exists ? skillToken.attributes : new bytes32[](0);

        if (!skillToken.exists) {
            // Mint new skill token
            _nextTokenId++;
            userSkillTokens[_userAddress][_skillHash] = SkillToken({
                id: _nextTokenId,
                skillHash: _skillHash,
                level: _assessedLevel,
                experiencePoints: _recommendedXP,
                lastUpdated: block.timestamp,
                attributes: currentAttributes, // Initial attributes can be empty or set by oracle
                exists: true
            });
            emit SkillTokenMinted(_userAddress, _skillHash, _nextTokenId, _assessedLevel);
        } else {
            // Update existing skill token
            skillToken.level = _assessedLevel;
            skillToken.experiencePoints += _recommendedXP; // Add recommended XP
            skillToken.lastUpdated = block.timestamp;
            // Potentially add new attributes based on assessment (e.g., 'oracle_verified')
            emit SkillTokenUpdated(_userAddress, _skillHash, _assessedLevel, skillToken.experiencePoints);
        }

        _updateReputationScore(_userAddress, int256(_recommendedXP / 5)); // Reward reputation
        userReputation[_userAddress].lastActivityTimestamp = block.timestamp;

        emit OracleSkillAssessmentFulfilled(_requestId, _userAddress, _skillHash, _assessedLevel, _recommendedXP);
    }

    /**
     * @dev Requests the Chainlink oracle to suggest an optimal difficulty for a challenge.
     *      Only callable by CHALLENGE_MODERATOR_ROLE.
     * @param _challengeId The ID of the challenge for which difficulty is needed.
     * @param _contextData A bytes32 hash of context data (e.g., IPFS hash of challenge spec, desired outcome).
     */
    function requestChallengeDifficulty(uint256 _challengeId, bytes32 _contextData) external onlyRole(CHALLENGE_MODERATOR_ROLE) checkPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (!challenge.exists) {
            revert ChallengeNotFound();
        }

        Chainlink.Request memory req = buildChainlinkRequest(jobIdChallengeDifficulty, address(this), this.fulfillChallengeDifficulty.selector);
        req.add("challengeId", Chainlink.toString(_challengeId));
        req.add("contextData", Chainlink.toHex(_contextData));
        // Add existing challenge details if needed for oracle assessment
        req.add("rewardSkillHash", Chainlink.toHex(challenge.rewardSkillHash));
        bytes32 requestId = sendChainlinkRequestTo(chainlinkOracle, req, oracleFee);

        emit OracleChallengeDifficultyRequested(requestId, _challengeId);
    }

    /**
     * @dev Callback function to receive challenge difficulty from the Chainlink oracle.
     * @param _requestId The ID of the original request.
     * @param _challengeId The ID of the challenge.
     * @param _recommendedDifficulty The recommended difficulty level (e.g., 1-5).
     */
    function fulfillChallengeDifficulty(bytes32 _requestId, uint256 _challengeId, uint256 _recommendedDifficulty)
        external
        recordChainlinkFulfillment(_requestId)
    {
        // No direct state change to `Challenge` struct here, as difficulty is a suggestion.
        // A moderator would review this and manually update if a 'difficulty' field existed in Challenge.
        // For now, it's just an emitted event for information.
        emit OracleChallengeDifficultyFulfilled(_requestId, _challengeId, _recommendedDifficulty);
    }

    // --- VI. Administrative & Control ---

    /**
     * @dev Pauses the contract, preventing certain functions from being called. Only owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing all functions to be called again. Only owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the ERC20 token to be used for fees. Only owner.
     * @param _newTokenAddress The address of the new fee token.
     */
    function setFeeToken(address _newTokenAddress) public onlyOwner {
        address oldToken = address(feeToken);
        feeToken = IERC20(_newTokenAddress);
        emit FeeTokenChanged(oldToken, _newTokenAddress);
    }

    /**
     * @dev Sets the fee for proposing a challenge. Only owner.
     * @param _newFee The new fee amount.
     */
    function setChallengeProposalFee(uint256 _newFee) external onlyOwner {
        challengeProposalFee = _newFee;
        emit ChallengeProposalFeeSet(_newFee);
    }

    /**
     * @dev Sets the fee for requesting a skill assessment. Only owner.
     * @param _newFee The new fee amount.
     */
    function setSkillAssessmentFee(uint256 _newFee) external onlyOwner {
        skillAssessmentFee = _newFee;
        emit SkillAssessmentFeeSet(_newFee);
    }

    /**
     * @dev Allows the owner to withdraw collected fees from the contract.
     * @param _to The address to send the fees to.
     */
    function withdrawFees(address _to) external onlyOwner {
        if (totalCollectedFees == 0) {
            revert NoFeesToWithdraw();
        }
        uint256 amount = totalCollectedFees;
        totalCollectedFees = 0; // Reset
        feeToken.transfer(_to, amount);
        emit FeeWithdrawn(_to, amount);
    }

    /**
     * @dev Grants a role to an address. Only owner.
     * @param _role The role to grant (e.g., CHALLENGE_MODERATOR_ROLE).
     * @param _account The address to grant the role to.
     */
    function addModerator(bytes32 _role, address _account) external onlyOwner {
        _grantRole(_role, _account);
    }

    /**
     * @dev Revokes a role from an address. Only owner.
     * @param _role The role to revoke.
     * @param _account The address to revoke the role from.
     */
    function removeModerator(bytes32 _role, address _account) external onlyOwner {
        _revokeRole(_role, _account);
    }

    /**
     * @dev Internal function to grant a role and emit an event.
     * @param role The role to grant.
     * @param account The address to grant the role to.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole[role][account]) {
            hasRole[role][account] = true;
            emit RoleGranted(role, account);
        }
    }

    /**
     * @dev Internal function to revoke a role and emit an event.
     * @param role The role to revoke.
     * @param account The address to revoke the role from.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole[role][account]) {
            hasRole[role][account] = false;
            emit RoleRevoked(role, account);
        }
    }
}
```