This Solidity smart contract, `VerifiableSkillNexus` (VSN), introduces an advanced, creative, and trending concept: a decentralized platform for **dynamic reputation management and community-validated skill verification**. It's designed to build a robust, verifiable on-chain identity for users based on their demonstrated skills and contributions, incorporating elements of gamification, incentivized validation, and the conceptual integration of zero-knowledge proofs (ZK-proofs) for higher-trust attestations.

---

### Outline and Function Summary

**This smart contract, VerifiableSkillNexus (VSN), is a decentralized platform for skill validation, dynamic reputation management, and incentivized knowledge sharing. It allows users to build a verifiable on-chain profile based on their skills, validated by the community or cryptographic proofs (e.g., ZK-proofs). Reputation points are dynamic, influencing access to various platform features and enabling a truly meritocratic ecosystem.**

**I. Core Data Structures & State Variables:**
*   Defines the foundational data types for users, skills, skill proofs, and challenges.
*   Stores global parameters like reputation decay rate, minimum stakes, and fees.

**II. User Management & Dynamic Reputation:**
*   Functions for users to register, manage their profiles, and query their reputation/skills.
*   Implements a dynamic reputation system where scores accumulate based on activity and decay over time to reflect recent engagement.

**III. Skill Definitions & Lifecycle:**
*   Allows for the creation, modification, and deactivation of distinct skills that can be validated on the platform.
*   Specifies requirements for skill validation, such as reputation thresholds for validators.

**IV. Skill Proof Submission & Community Validation:**
*   Enables users to submit proofs of their skills, optionally indicating if it's a ZK-proof.
*   Establishes a multi-step validation process involving staking by potential validators, community voting, and finalization, with mechanisms for rewards and penalties.

**V. Reputation-Gated Access & Challenges:**
*   Provides a utility function for external contracts or internal logic to verify a user's on-chain credentials (reputation and verified skills).
*   Introduces a challenge system where users can submit solutions for specific skills, fostering a competitive environment and rewarding expertise.

---

### Function Summary

**I. Core Data Structures & State Variables (Internal/State Management - no direct functions here)**

**II. User Management & Dynamic Reputation (6 Functions)**
1.  `registerProfile()`: Initializes a new user profile on the VSN, requiring Proof-of-Humanity verification.
2.  `updateProfileMetadata(string _ipfsHash)`: Allows a user to update their off-chain profile metadata URI (e.g., an IPFS hash to a detailed profile).
3.  `getReputationScore(address _user)`: Retrieves the current reputation score of a user, calculating decay up to the current block timestamp.
4.  `getVerifiedSkills(address _user)`: Returns an array of skill IDs that a user has successfully verified and currently holds.
5.  `checkSkillProficiency(address _user, bytes32 _skillId)`: Checks if a specific user has a particular verified skill.
6.  `decayReputation(address _user)`: Public function to explicitly apply reputation decay for a user. Callable by anyone, it processes decay only if the configured interval has passed.

**III. Skill Definitions & Lifecycle (4 Functions)**
7.  `createSkill(string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`: Creates a new skill definition that users can prove. Only the contract owner can define new skills.
8.  `updateSkill(bytes32 _skillId, string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`: Modifies an existing skill's details (only by the skill creator or contract owner).
9.  `deactivateSkill(bytes32 _skillId)`: Sets a skill as inactive, preventing new proof submissions for it (only by the skill creator or contract owner).
10. `getSkillDetails(bytes32 _skillId)`: Retrieves all details for a given skill ID.

**IV. Skill Proof Submission & Community Validation (8 Functions)**
11. `submitSkillProof(bytes32 _skillId, string memory _proofURI, bool _isZkProof)`: Allows a user to submit a proof for a skill. Requires a small ETH fee for submission and can optionally flag if it's a ZK-proof for different validation rules.
12. `proposeProofValidation(bytes32 _proofId)`: A qualified user (validator with sufficient reputation) proposes to validate a proof, staking VSN tokens.
13. `voteOnProofValidation(bytes32 _proofId, bool _isValid)`: Staking validators cast their vote (approve/reject) on a proposed proof within a grace period.
14. `finalizeProofValidation(bytes32 _proofId)`: Finalizes the proof validation process after the voting period, distributing rewards/penalties and updating user reputation/skills based on vote outcomes and ZK-proof status.
15. `disputeFinalizedProof(bytes32 _proofId)`: Allows a user to dispute a *finalized* proof (whether validated or rejected), initiating an arbitration process and requiring a dispute stake in ETH.
16. `resolveDispute(bytes32 _proofId, bool _isProofValid)`: The contract owner (acting as an arbitrator) resolves a disputed proof, determining its final validity and allocating stakes/reputation accordingly.
17. `getProofDetails(bytes32 _proofId)`: Retrieves the details of a specific skill proof submission.
18. `getPendingProofs(uint256 _offset, uint256 _limit)`: Returns a paginated list of proofs currently awaiting validation (in Pending or Proposed status).

**V. Reputation-Gated Access & Challenges (5 Functions)**
19. `verifyUserCredentials(address _user, uint256 _minReputation, bytes32 _requiredSkillId)`: A utility function for other contracts or dApps to easily check if a user meets specified reputation and/or skill requirements.
20. `createChallenge(string memory _name, bytes32 _skillId, uint256 _rewardAmount, uint256 _duration)`: Creates a new skill-based challenge with a prize pool (in VSN tokens) and a time limit. The creator funds the reward.
21. `submitChallengeSolution(bytes32 _challengeId, bytes32 _proofId)`: Allows a participant to submit a solution to a challenge, referencing one of their already verified skill proofs.
22. `finalizeChallenge(bytes32 _challengeId)`: The challenge creator finalizes the challenge after its expiration, distributing rewards to eligible participants who submitted valid solutions.
23. `getChallengeDetails(bytes32 _challengeId)`: Retrieves all details for a given challenge ID, including participants.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential token rewards/stakes
import "@openzeppelin/contracts/utils/Context.sol"; // Used by Ownable, but explicitly here for consistency
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // To prevent reentrancy attacks on stake withdrawals

// --- Outline and Function Summary ---
// This smart contract, VerifiableSkillNexus (VSN), is a decentralized platform for
// skill validation, dynamic reputation management, and incentivized knowledge sharing.
// It allows users to build a verifiable on-chain profile based on their skills,
// validated by the community or cryptographic proofs (e.g., ZK-proofs).
// Reputation points are dynamic, influencing access to various platform features
// and enabling a truly meritocratic ecosystem.

// I. Core Data Structures & State Variables:
//    - Defines the foundational data types for users, skills, skill proofs, and challenges.
//    - Stores global parameters like reputation decay rate, minimum stakes, and fees.

// II. User Management & Dynamic Reputation:
//    - Functions for users to register, manage their profiles, and query their reputation/skills.
//    - Implements a dynamic reputation system where scores accumulate based on activity
//      and decay over time to reflect recent engagement.

// III. Skill Definitions & Lifecycle:
//    - Allows for the creation, modification, and deactivation of distinct skills
//      that can be validated on the platform.
//    - Specifies requirements for skill validation, such as reputation thresholds for validators.

// IV. Skill Proof Submission & Community Validation:
//    - Enables users to submit proofs of their skills, optionally indicating if it's a ZK-proof.
//    - Establishes a multi-step validation process involving staking by potential validators,
//      community voting, and finalization, with mechanisms for rewards and penalties.

// V. Reputation-Gated Access & Challenges:
//    - Provides a utility function for external contracts or internal logic to verify
//      a user's on-chain credentials (reputation and verified skills).
//    - Introduces a challenge system where users can submit solutions for specific skills,
//      fostering a competitive environment and rewarding expertise.

// --- Function Summary ---

// I. Core Data Structures & State Variables (Internal/State Management - no direct functions here)

// II. User Management & Dynamic Reputation (6 Functions)
// 1.  `registerProfile()`: Initializes a new user profile on the VSN.
// 2.  `updateProfileMetadata(string _ipfsHash)`: Allows a user to update their off-chain profile metadata URI.
// 3.  `getReputationScore(address _user)`: Retrieves the current reputation score of a user.
// 4.  `getVerifiedSkills(address _user)`: Returns an array of skill IDs that a user has successfully verified.
// 5.  `checkSkillProficiency(address _user, bytes32 _skillId)`: Checks if a specific user has a particular verified skill.
// 6.  `decayReputation(address _user)`: Public function to apply reputation decay for a user.

// III. Skill Definitions & Lifecycle (4 Functions)
// 7.  `createSkill(string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`: Creates a new skill definition that users can prove.
// 8.  `updateSkill(bytes32 _skillId, string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`: Modifies an existing skill's details (only by skill creator or owner).
// 9.  `deactivateSkill(bytes32 _skillId)`: Sets a skill as inactive, preventing new proof submissions for it.
// 10. `getSkillDetails(bytes32 _skillId)`: Retrieves all details for a given skill ID.

// IV. Skill Proof Submission & Community Validation (8 Functions)
// 11. `submitSkillProof(bytes32 _skillId, string memory _proofURI, bool _isZkProof)`: Allows a user to submit a proof for a skill. Requires ETH for submission fee.
// 12. `proposeProofValidation(bytes32 _proofId)`: A qualified user (validator) proposes to validate a proof, staking tokens.
// 13. `voteOnProofValidation(bytes32 _proofId, bool _isValid)`: Staking validators cast their vote (approve/reject) on a proposed proof.
// 14. `finalizeProofValidation(bytes32 _proofId)`: Finalizes the proof validation process, distributing rewards/penalties and updating user reputation/skills.
// 15. `disputeFinalizedProof(bytes32 _proofId)`: Allows a user to dispute a *finalized* proof, initiating an arbitration process (requires a dispute stake).
// 16. `resolveDispute(bytes32 _proofId, bool _isProofValid)`: The contract owner/arbitrator resolves a disputed proof.
// 17. `getProofDetails(bytes32 _proofId)`: Retrieves the details of a specific skill proof submission.
// 18. `getPendingProofs(uint256 _offset, uint256 _limit)`: Returns a paginated list of proofs currently awaiting validation.

// V. Reputation-Gated Access & Challenges (5 Functions)
// 19. `verifyUserCredentials(address _user, uint256 _minReputation, bytes32 _requiredSkillId)`: Utility function for checking if a user meets specified reputation and skill requirements.
// 20. `createChallenge(string memory _name, bytes32 _skillId, uint256 _rewardAmount, uint256 _duration)`: Creates a new skill-based challenge with a prize pool and time limit.
// 21. `submitChallengeSolution(bytes32 _challengeId, bytes32 _proofId)`: Allows a participant to submit a solution to a challenge, referencing a verified skill proof.
// 22. `finalizeChallenge(bytes32 _challengeId)`: The challenge creator finalizes the challenge, distributing rewards to eligible participants.
// 23. `getChallengeDetails(bytes32 _challengeId)`: Retrieves all details for a given challenge ID.

contract VerifiableSkillNexus is Ownable, ReentrancyGuard {

    // --- Events ---
    event ProfileRegistered(address indexed user, uint256 timestamp);
    event ProfileMetadataUpdated(address indexed user, string ipfsHash);
    event ReputationUpdated(address indexed user, uint256 newScore, uint256 oldScore);
    event SkillCreated(bytes32 indexed skillId, address indexed creator);
    event SkillUpdated(bytes32 indexed skillId);
    event SkillDeactivated(bytes32 indexed skillId);
    event SkillProofSubmitted(bytes32 indexed proofId, bytes32 indexed skillId, address indexed prover, string proofURI, bool isZkProof);
    event ProofValidationProposed(bytes32 indexed proofId, address indexed validator, uint256 stakeAmount);
    event ProofVoted(bytes32 indexed proofId, address indexed voter, bool isValid);
    event ProofValidated(bytes32 indexed proofId, bytes32 indexed skillId, address indexed prover, address indexed finalValidator);
    event ProofRejected(bytes32 indexed proofId, bytes32 indexed skillId, address indexed prover);
    event ProofDisputed(bytes32 indexed proofId, address indexed disputer);
    event DisputeResolved(bytes32 indexed proofId, bool isProofValid);
    event ChallengeCreated(bytes32 indexed challengeId, bytes32 indexed skillId, address indexed creator, uint256 rewardAmount, uint256 expiration);
    event ChallengeSolutionSubmitted(bytes32 indexed challengeId, address indexed participant, bytes32 proofId);
    event ChallengeFinalized(bytes32 indexed challengeId, address indexed creator, uint256 totalRewards);

    // --- Constants & Configurable Parameters ---
    uint256 public constant INITIAL_REPUTATION_SCORE = 100;
    uint256 public constant REPUTATION_GAIN_PROOF_VALIDATION = 50;
    uint256 public constant REPUTATION_GAIN_PROOF_SUBMISSION = 25;
    uint256 public constant REPUTATION_PENALTY_FAILED_VALIDATION = 30;
    uint256 public constant REPUTATION_DECAY_INTERVAL = 7 days; // Decay every 7 days
    uint256 public constant REPUTATION_DECAY_PERCENTAGE = 5; // 5% decay
    uint256 public constant PROOF_SUBMISSION_FEE = 0.01 ether; // ETH required to submit a proof
    uint256 public constant VALIDATION_VOTE_GRACE_PERIOD = 3 days; // Time for validators to vote after proposal
    uint256 public constant DISPUTE_STAKE_AMOUNT = 0.5 ether; // ETH required to dispute a proof

    // --- External Dependencies (Interfaces) ---
    // Interface for a hypothetical Proof-of-Humanity or Sybil resistance oracle
    // This allows the contract to interact with an external contract that verifies human identity.
    interface IProofOfHumanityOracle {
        function isHuman(address _addr) external view returns (bool);
    }
    IProofOfHumanityOracle public proofOfHumanityOracle;

    // A token for staking and rewards (e.g., a native VSN token or a stablecoin).
    // The contract holds stakes and distributes rewards in this token.
    IERC20 public vsnToken;

    // --- Data Structures ---

    // Enum to represent the lifecycle status of a skill proof.
    enum ProofStatus {
        Pending,          // Awaiting validation proposal
        Proposed,         // Validation proposed, awaiting votes
        Validated,        // Proof accepted, skill granted
        Rejected,         // Proof rejected, skill not granted
        Disputed,         // Awaiting arbitration after being validated/rejected
        ArbitratedValid,  // Disputed and found valid by arbitrator
        ArbitratedInvalid // Disputed and found invalid by arbitrator
    }

    // Stores information about a user's on-chain profile and reputation.
    struct User {
        uint256 reputationScore;
        uint256 lastActivityTimestamp; // Timestamp for last reputation-affecting activity, used for decay
        string profileMetadataURI;     // IPFS hash or similar for off-chain profile data
        mapping(bytes32 => bool) verifiedSkills; // Skill ID => is_verified status for quick lookup
        bytes32[] skillsList; // To iterate verified skills (for `getVerifiedSkills`)
    }

    // Defines the parameters and requirements for a specific skill.
    struct Skill {
        bytes32 id; // Unique ID for the skill
        address creator; // Address of the entity who created this skill definition
        string name;
        string description;
        uint256 requiredProofsForValidation; // Minimum number of votes (yes/no) needed for a proof to be finalized
        uint256 requiredReputationToValidate; // Minimum reputation for a user to propose/vote on validation
        uint256 validationStakeAmount; // Amount of VSN_TOKEN required to stake as a validator
        bool isActive; // Can new proofs be submitted for this skill?
    }

    // Stores a single vote on a skill proof validation.
    struct ProofValidationVote {
        bool isValid; // True for 'approve', false for 'reject'
        uint256 timestamp;
    }

    // Details of a submitted skill proof and its validation process.
    struct SkillProof {
        bytes32 id; // Unique ID for the proof
        bytes32 skillId; // The skill this proof is for
        address prover; // The user who submitted this proof
        string proofURI; // Link to external proof (e.g., IPFS hash, URL to ZK-proof data)
        bool isZkProof; // Flag indicating if the proof relies on a ZK-proof mechanism
        ProofStatus status;
        uint256 submissionTimestamp;

        address proposer; // The address who staked to propose validation
        uint256 proposalTimestamp;
        mapping(address => ProofValidationVote) votes; // Validator address => vote details
        address[] voters; // Array to iterate through voters for reward/penalty distribution
        uint256 yesVotes;
        uint256 noVotes;
        uint256 validationStakeTotal; // Sum of all stakes for this proof

        address finalValidator; // The validator who successfully finalized (if applicable)
        address disputer; // Address who disputed a finalized proof
        uint256 disputeTimestamp;
        uint256 disputeStake; // Stake amount for dispute
    }

    // Defines a skill-based challenge where users can submit solutions.
    struct Challenge {
        bytes32 id; // Unique ID for the challenge
        address creator; // The user who created the challenge
        string name;
        bytes32 skillId; // The skill required for this challenge
        uint256 rewardAmount; // Total rewards for the challenge (in VSN_TOKEN)
        uint256 expirationTimestamp;
        mapping(address => bytes32) solutions; // Participant address => proofId of their solution
        address[] participants; // Array to iterate through participants
        bool isFinalized; // Is the challenge complete and rewards distributed?
    }

    // --- State Variables ---
    mapping(address => User) public users;
    mapping(bytes32 => Skill) public skills;
    mapping(bytes32 => SkillProof) public skillProofs;
    mapping(bytes32 => Challenge) public challenges;

    bytes32[] public pendingProofIds; // List of proofs that are currently in Pending or Proposed status
    // Note: This array can grow large. In a production system, more gas-efficient
    // methods for tracking pending items or off-chain indexing would be considered.

    // --- Constructor ---
    // Initializes the contract with addresses for the VSN token and a Proof-of-Humanity oracle.
    constructor(address _vsnTokenAddress, address _poHOracleAddress) Ownable(msg.sender) {
        require(_vsnTokenAddress != address(0), "Invalid VSN Token address");
        require(_poHOracleAddress != address(0), "Invalid PoH Oracle address");
        vsnToken = IERC20(_vsnTokenAddress);
        proofOfHumanityOracle = IProofOfHumanityOracle(_poHOracleAddress);
    }

    // --- Modifiers ---
    // Ensures the calling address is verified as a human by the configured oracle.
    modifier onlyHuman(address _user) {
        require(proofOfHumanityOracle.isHuman(_user), "Not a verified human");
        _;
    }

    // Ensures the specified user has a registered profile in the system.
    modifier userExists(address _user) {
        require(users[_user].lastActivityTimestamp != 0, "User profile does not exist");
        _;
    }

    // --- Internal Helpers ---
    // Generates a unique ID using block data, sender, input, and difficulty.
    // While not truly random, it's sufficiently unique for IDs in this context.
    function _generateId(bytes memory _input) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender, _input, block.difficulty));
    }

    // Applies reputation decay for a given user if the decay interval has passed.
    function _applyReputationDecay(address _user) internal {
        User storage user = users[_user];
        if (user.lastActivityTimestamp == 0) return; // User not registered

        uint256 periodsPassed = (block.timestamp - user.lastActivityTimestamp) / REPUTATION_DECAY_INTERVAL;
        if (periodsPassed > 0) {
            uint256 oldScore = user.reputationScore;
            uint256 newScore = oldScore;
            for (uint256 i = 0; i < periodsPassed; i++) {
                newScore = newScore * (100 - REPUTATION_DECAY_PERCENTAGE) / 100;
            }
            user.reputationScore = newScore;
            user.lastActivityTimestamp = block.timestamp; // Update last activity after decay
            emit ReputationUpdated(_user, newScore, oldScore);
        }
    }

    // Grants reputation points to a user. Automatically applies decay before adding.
    function _grantReputation(address _user, uint256 _amount) internal {
        User storage user = users[_user];
        require(user.lastActivityTimestamp != 0, "User must be registered to gain reputation");
        _applyReputationDecay(_user); // Apply decay before adding
        uint256 oldScore = user.reputationScore;
        user.reputationScore += _amount;
        user.lastActivityTimestamp = block.timestamp; // Mark activity
        emit ReputationUpdated(_user, user.reputationScore, oldScore);
    }

    // Penalizes reputation points from a user. Automatically applies decay before penalizing.
    function _penalizeReputation(address _user, uint256 _amount) internal {
        User storage user = users[_user];
        require(user.lastActivityTimestamp != 0, "User must be registered to be penalized");
        _applyReputationDecay(_user); // Apply decay before penalizing
        uint256 oldScore = user.reputationScore;
        user.reputationScore = (user.reputationScore > _amount) ? (user.reputationScore - _amount) : 0;
        user.lastActivityTimestamp = block.timestamp; // Mark activity
        emit ReputationUpdated(_user, user.reputationScore, oldScore);
    }

    // --- II. User Management & Dynamic Reputation (6 Functions) ---

    // 1. `registerProfile()`
    // Initializes a new user profile on the VSN. Requires sender to be verified human by PoH oracle.
    function registerProfile() external nonReentrant onlyHuman(msg.sender) {
        require(users[msg.sender].lastActivityTimestamp == 0, "User already registered");
        users[msg.sender].reputationScore = INITIAL_REPUTATION_SCORE;
        users[msg.sender].lastActivityTimestamp = block.timestamp;
        emit ProfileRegistered(msg.sender, block.timestamp);
    }

    // 2. `updateProfileMetadata(string _ipfsHash)`
    // Allows a user to update their off-chain profile metadata URI (e.g., an IPFS hash).
    function updateProfileMetadata(string memory _ipfsHash) external userExists(msg.sender) {
        _applyReputationDecay(msg.sender); // Apply decay if due before updating timestamp
        users[msg.sender].profileMetadataURI = _ipfsHash;
        users[msg.sender].lastActivityTimestamp = block.timestamp; // Mark activity
        emit ProfileMetadataUpdated(msg.sender, _ipfsHash);
    }

    // 3. `getReputationScore(address _user)`
    // Retrieves the current reputation score of a user. Applies decay before returning the score.
    function getReputationScore(address _user) public view returns (uint256) {
        User storage user = users[_user];
        if (user.lastActivityTimestamp == 0) return 0; // Not registered

        uint256 currentScore = user.reputationScore;
        uint256 periodsPassed = (block.timestamp - user.lastActivityTimestamp) / REPUTATION_DECAY_INTERVAL;
        for (uint256 i = 0; i < periodsPassed; i++) {
            currentScore = currentScore * (100 - REPUTATION_DECAY_PERCENTAGE) / 100;
        }
        return currentScore;
    }

    // 4. `getVerifiedSkills(address _user)`
    // Returns an array of skill IDs that a user has successfully verified.
    function getVerifiedSkills(address _user) external view returns (bytes32[] memory) {
        return users[_user].skillsList;
    }

    // 5. `checkSkillProficiency(address _user, bytes32 _skillId)`
    // Checks if a specific user has a particular verified skill.
    function checkSkillProficiency(address _user, bytes32 _skillId) public view returns (bool) {
        return users[_user].verifiedSkills[_skillId];
    }

    // 6. `decayReputation(address _user)`
    // Public function to apply reputation decay for a user. Callable by anyone, but only applies if time elapsed.
    // This allows external parties (e.g., keepers) to trigger decay for specific users,
    // distributing the gas cost.
    function decayReputation(address _user) public userExists(_user) {
        _applyReputationDecay(_user);
    }

    // --- III. Skill Definitions & Lifecycle (4 Functions) ---

    // 7. `createSkill(string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`
    // Creates a new skill definition that users can prove. Only contract owner can create.
    function createSkill(
        string memory _name,
        string memory _description,
        uint256 _requiredProofsForValidation,
        uint256 _requiredReputationToValidate,
        uint256 _validationStakeAmount
    ) external onlyOwner returns (bytes32) {
        bytes32 skillId = _generateId(abi.encodePacked(_name, _description, block.number));
        require(skills[skillId].creator == address(0), "Skill ID collision, try again");

        skills[skillId] = Skill({
            id: skillId,
            creator: msg.sender,
            name: _name,
            description: _description,
            requiredProofsForValidation: _requiredProofsForValidation,
            requiredReputationToValidate: _requiredReputationToValidate,
            validationStakeAmount: _validationStakeAmount,
            isActive: true
        });
        emit SkillCreated(skillId, msg.sender);
        return skillId;
    }

    // 8. `updateSkill(bytes32 _skillId, string memory _name, string memory _description, uint256 _requiredProofsForValidation, uint256 _requiredReputationToValidate, uint256 _validationStakeAmount)`
    // Modifies an existing skill's details (only by skill creator or contract owner).
    function updateSkill(
        bytes32 _skillId,
        string memory _name,
        string memory _description,
        uint256 _requiredProofsForValidation,
        uint256 _requiredReputationToValidate,
        uint256 _validationStakeAmount
    ) external {
        Skill storage skill = skills[_skillId];
        require(skill.creator != address(0), "Skill not found");
        require(skill.creator == msg.sender || owner() == msg.sender, "Only skill creator or contract owner can update");

        skill.name = _name;
        skill.description = _description;
        skill.requiredProofsForValidation = _requiredProofsForValidation;
        skill.requiredReputationToValidate = _requiredReputationToValidate;
        skill.validationStakeAmount = _validationStakeAmount;
        emit SkillUpdated(_skillId);
    }

    // 9. `deactivateSkill(bytes32 _skillId)`
    // Sets a skill as inactive, preventing new proof submissions for it. Only by skill creator or contract owner.
    function deactivateSkill(bytes32 _skillId) external {
        Skill storage skill = skills[_skillId];
        require(skill.creator != address(0), "Skill not found");
        require(skill.creator == msg.sender || owner() == msg.sender, "Only skill creator or contract owner can deactivate");
        require(skill.isActive, "Skill is already inactive");
        skill.isActive = false;
        emit SkillDeactivated(_skillId);
    }

    // 10. `getSkillDetails(bytes32 _skillId)`
    // Retrieves all details for a given skill ID.
    function getSkillDetails(bytes32 _skillId) external view returns (
        bytes32 id,
        address creator,
        string memory name,
        string memory description,
        uint256 requiredProofsForValidation,
        uint256 requiredReputationToValidate,
        uint256 validationStakeAmount,
        bool isActive
    ) {
        Skill storage skill = skills[_skillId];
        require(skill.creator != address(0), "Skill not found"); // Check if skill exists
        return (
            skill.id,
            skill.creator,
            skill.name,
            skill.description,
            skill.requiredProofsForValidation,
            skill.requiredReputationToValidate,
            skill.validationStakeAmount,
            skill.isActive
        );
    }

    // --- IV. Skill Proof Submission & Community Validation (8 Functions) ---

    // 11. `submitSkillProof(bytes32 _skillId, string memory _proofURI, bool _isZkProof)`
    // Allows a user to submit a proof for a skill. Requires ETH for submission fee.
    // The `_isZkProof` flag influences the validation logic (e.g., higher trust for ZK-proofs).
    function submitSkillProof(bytes32 _skillId, string memory _proofURI, bool _isZkProof) external payable userExists(msg.sender) nonReentrant {
        require(msg.value >= PROOF_SUBMISSION_FEE, "Insufficient ETH for proof submission fee");
        Skill storage skill = skills[_skillId];
        require(skill.isActive, "Skill is not active or does not exist");
        require(!users[msg.sender].verifiedSkills[_skillId], "User already has this skill verified");
        
        _applyReputationDecay(msg.sender); // Apply decay before adding rep
        _grantReputation(msg.sender, REPUTATION_GAIN_PROOF_SUBMISSION); // Reward for proof submission

        bytes32 proofId = _generateId(abi.encodePacked(_skillId, msg.sender, _proofURI));
        require(skillProofs[proofId].prover == address(0), "Proof ID collision, try again"); // Check for ID uniqueness

        skillProofs[proofId] = SkillProof({
            id: proofId,
            skillId: _skillId,
            prover: msg.sender,
            proofURI: _proofURI,
            isZkProof: _isZkProof,
            status: ProofStatus.Pending,
            submissionTimestamp: block.timestamp,
            proposer: address(0),
            proposalTimestamp: 0,
            yesVotes: 0,
            noVotes: 0,
            validationStakeTotal: 0,
            finalValidator: address(0),
            disputer: address(0),
            disputeTimestamp: 0,
            disputeStake: 0,
            voters: new address[](0) // Initialize empty array for voters
        });

        pendingProofIds.push(proofId); // Add to the list of proofs awaiting validation
        emit SkillProofSubmitted(proofId, _skillId, msg.sender, _proofURI, _isZkProof);
    }

    // 12. `proposeProofValidation(bytes32 _proofId)`
    // A qualified user (validator) proposes to validate a proof, staking tokens.
    // This moves the proof from 'Pending' to 'Proposed' status.
    function proposeProofValidation(bytes32 _proofId) external userExists(msg.sender) nonReentrant {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found");
        require(proof.status == ProofStatus.Pending, "Proof not in pending status");
        require(msg.sender != proof.prover, "Prover cannot validate their own proof"); // Prevent self-validation

        Skill storage skill = skills[proof.skillId];
        require(getReputationScore(msg.sender) >= skill.requiredReputationToValidate, "Insufficient reputation to propose validation");
        require(vsnToken.transferFrom(msg.sender, address(this), skill.validationStakeAmount), "Token transfer for stake failed"); // Transfer stake to contract

        proof.proposer = msg.sender;
        proof.proposalTimestamp = block.timestamp;
        proof.status = ProofStatus.Proposed;
        proof.validationStakeTotal += skill.validationStakeAmount;
        proof.votes[msg.sender] = ProofValidationVote(true, block.timestamp); // Proposer implicitly votes "yes"
        proof.voters.push(msg.sender);
        proof.yesVotes++;

        emit ProofValidationProposed(_proofId, msg.sender, skill.validationStakeAmount);
    }

    // 13. `voteOnProofValidation(bytes32 _proofId, bool _isValid)`
    // Staking validators cast their vote (approve/reject) on a proposed proof.
    function voteOnProofValidation(bytes32 _proofId, bool _isValid) external userExists(msg.sender) nonReentrant {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found");
        require(proof.status == ProofStatus.Proposed, "Proof not in proposed status");
        require(msg.sender != proof.prover, "Prover cannot vote on their own proof");
        require(proof.votes[msg.sender].timestamp == 0, "Validator has already voted"); // Only one vote per validator
        require(block.timestamp <= proof.proposalTimestamp + VALIDATION_VOTE_GRACE_PERIOD, "Voting period has ended");

        Skill storage skill = skills[proof.skillId];
        require(getReputationScore(msg.sender) >= skill.requiredReputationToValidate, "Insufficient reputation to vote");
        require(vsnToken.transferFrom(msg.sender, address(this), skill.validationStakeAmount), "Token transfer for stake failed");

        proof.validationStakeTotal += skill.validationStakeAmount;
        proof.votes[msg.sender] = ProofValidationVote(_isValid, block.timestamp);
        proof.voters.push(msg.sender);

        if (_isValid) {
            proof.yesVotes++;
        } else {
            proof.noVotes++;
        }
        emit ProofVoted(_proofId, msg.sender, _isValid);
    }

    // 14. `finalizeProofValidation(bytes32 _proofId)`
    // Finalizes the proof validation process, distributing rewards/penalties and updating user reputation/skills.
    // Can only be called after the voting grace period has ended.
    function finalizeProofValidation(bytes32 _proofId) external userExists(msg.sender) nonReentrant {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found");
        require(proof.status == ProofStatus.Proposed, "Proof not in proposed status");
        require(block.timestamp > proof.proposalTimestamp + VALIDATION_VOTE_GRACE_PERIOD, "Voting period not yet ended");
        // Ensure minimum votes are met for finalization (even if majority logic is complex for ZK)
        require(proof.yesVotes + proof.noVotes >= skills[proof.skillId].requiredProofsForValidation, "Not enough votes to finalize");

        User storage proverUser = users[proof.prover];
        Skill storage skill = skills[proof.skillId];

        bool isProofApproved = false;
        if (proof.isZkProof) {
            // For ZK-proofs, the validation might be more lenient (e.g., if any honest validator confirms).
            // Simplified: If it's a ZK-proof, we assume a higher trust and if there's a majority of YES votes, it's approved.
            // A more complex system would interact with a dedicated ZK verifier contract.
            isProofApproved = (proof.yesVotes > proof.noVotes);
        } else {
            // For non-ZK proofs, simple majority wins.
            isProofApproved = proof.yesVotes > proof.noVotes;
        }

        if (isProofApproved) {
            proof.status = ProofStatus.Validated;
            // Grant skill to the prover
            if (!proverUser.verifiedSkills[proof.skillId]) { // Prevent duplicate additions to the list
                proverUser.verifiedSkills[proof.skillId] = true;
                proverUser.skillsList.push(proof.skillId);
            }
            
            // Reward successful validators & penalize incorrect ones
            uint256 totalCorrectStakes = 0;
            for (uint256 i = 0; i < proof.voters.length; i++) {
                address voter = proof.voters[i];
                if (proof.votes[voter].isValid) { // Correct vote (yes)
                    totalCorrectStakes += skill.validationStakeAmount;
                    _grantReputation(voter, REPUTATION_GAIN_PROOF_VALIDATION);
                } else { // Incorrect vote (no)
                    _penalizeReputation(voter, REPUTATION_PENALTY_FAILED_VALIDATION);
                    // Their stake remains in the contract, potentially distributed to correct voters or to a treasury.
                }
            }
            
            // Distribute rewards from the total staked pool proportionally to correct voters.
            // Incorrect voters' stakes might be distributed among correct voters or sent to a treasury/burn.
            // Here, we add a reward on top of the returned stake for correct voters.
            uint256 rewardPoolForCorrectVoters = proof.validationStakeTotal - (proof.noVotes * skill.validationStakeAmount); // Stakes from 'no' votes are effectively penalty
            uint256 rewardPerCorrectStake = (totalCorrectStakes > 0) ? (rewardPoolForCorrectVoters / totalCorrectStakes) : 0;
            
            for (uint256 i = 0; i < proof.voters.length; i++) {
                address voter = proof.voters[i];
                if (proof.votes[voter].isValid) {
                    // Return their stake + a share of the reward pool
                    require(vsnToken.transfer(voter, skill.validationStakeAmount + rewardPerCorrectStake), "Failed to reward validator");
                }
            }
            emit ProofValidated(_proofId, proof.skillId, proof.prover, msg.sender);
        } else {
            proof.status = ProofStatus.Rejected;
            // Penalize proposer and others who voted yes
            // Refund those who voted correctly (no)
            for (uint256 i = 0; i < proof.voters.length; i++) {
                address voter = proof.voters[i];
                if (!proof.votes[voter].isValid) { // Correct vote (no)
                    _grantReputation(voter, REPUTATION_GAIN_PROOF_VALIDATION);
                    require(vsnToken.transfer(voter, skill.validationStakeAmount), "Failed to refund validator");
                } else { // Incorrect vote (yes)
                    _penalizeReputation(voter, REPUTATION_PENALTY_FAILED_VALIDATION);
                    // Their stake is forfeited.
                }
            }
            emit ProofRejected(_proofId, proof.skillId, proof.prover);
        }
        // Remove the proof from the `pendingProofIds` list (simplified for demonstration).
        // A robust system would involve iterating and removing or using a more complex data structure.
        // For this example, we'll just update its status and rely on `getPendingProofs` to filter.
    }

    // 15. `disputeFinalizedProof(bytes32 _proofId)`
    // Allows a user to dispute a *finalized* proof (Validated or Rejected), initiating an arbitration process.
    // Requires a dispute stake to prevent spam.
    function disputeFinalizedProof(bytes32 _proofId) external payable userExists(msg.sender) nonReentrant {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found");
        require(proof.status == ProofStatus.Validated || proof.status == ProofStatus.Rejected, "Proof not in a finalized status");
        require(proof.disputer == address(0), "Proof already under dispute"); // Check if it's already being disputed
        require(msg.value >= DISPUTE_STAKE_AMOUNT, "Insufficient ETH for dispute stake");
        require(msg.sender != proof.prover, "Prover cannot dispute their own proof"); // Prover cannot dispute their own proof

        proof.status = ProofStatus.Disputed;
        proof.disputer = msg.sender;
        proof.disputeTimestamp = block.timestamp;
        proof.disputeStake = msg.value; // Store the actual stake amount
        emit ProofDisputed(_proofId, msg.sender);
    }

    // 16. `resolveDispute(bytes32 _proofId, bool _isProofValid)`
    // The contract owner (acting as an arbitrator) resolves a disputed proof.
    // This is a powerful function and should only be callable by trusted parties (Owner in this case).
    function resolveDispute(bytes32 _proofId, bool _isProofValid) external onlyOwner nonReentrant {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found");
        require(proof.status == ProofStatus.Disputed, "Proof is not under dispute");

        address prover = proof.prover;
        address disputer = proof.disputer;

        if (_isProofValid) {
            // Arbitrator confirms proof is VALID
            proof.status = ProofStatus.ArbitratedValid;
            _grantReputation(disputer, REPUTATION_GAIN_PROOF_VALIDATION); // Reward disputer for correct dispute
            
            // If it was previously rejected, now grant skill
            if (!users[prover].verifiedSkills[proof.skillId]) {
                users[prover].verifiedSkills[proof.skillId] = true;
                users[prover].skillsList.push(proof.skillId);
            }
            
            // Return disputer's stake
            (bool success, ) = payable(disputer).call{value: proof.disputeStake}("");
            require(success, "Failed to refund disputer stake");

        } else {
            // Arbitrator confirms proof is INVALID
            proof.status = ProofStatus.ArbitratedInvalid;
            _penalizeReputation(disputer, REPUTATION_PENALTY_FAILED_VALIDATION);
            // Disputer's stake is forfeited (remains in contract or goes to treasury/burn)
            
            // If it was previously validated, conceptually revoke skill (simplified to just marking it false)
            // Note: Actual revocation from skillsList requires array manipulation which is gas-intensive.
            if (users[prover].verifiedSkills[proof.skillId]) {
                users[prover].verifiedSkills[proof.skillId] = false;
                // For a complete removal from `skillsList`, an array iteration and shift would be needed.
            }
        }
        emit DisputeResolved(_proofId, _isProofValid);
    }

    // 17. `getProofDetails(bytes32 _proofId)`
    // Retrieves the detailed information of a specific skill proof submission.
    function getProofDetails(bytes32 _proofId) external view returns (
        bytes32 id,
        bytes32 skillId,
        address prover,
        string memory proofURI,
        bool isZkProof,
        ProofStatus status,
        uint256 submissionTimestamp,
        address proposer,
        uint256 proposalTimestamp,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 validationStakeTotal
    ) {
        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover != address(0), "Proof not found"); // Check if proof exists
        return (
            proof.id,
            proof.skillId,
            proof.prover,
            proof.proofURI,
            proof.isZkProof,
            proof.status,
            proof.submissionTimestamp,
            proof.proposer,
            proof.proposalTimestamp,
            proof.yesVotes,
            proof.noVotes,
            proof.validationStakeTotal
        );
    }

    // 18. `getPendingProofs(uint256 _offset, uint256 _limit)`
    // Returns a paginated list of proofs currently awaiting validation (Pending or Proposed).
    // This function iterates through `pendingProofIds` and filters based on status.
    function getPendingProofs(uint256 _offset, uint256 _limit) external view returns (bytes32[] memory) {
        require(_limit > 0, "Limit must be greater than 0");
        uint256 total = pendingProofIds.length;
        if (_offset >= total) {
            return new bytes32[](0); // No results
        }

        bytes32[] memory tempResult = new bytes32[](_limit);
        uint256 count = 0;
        for (uint256 i = _offset; i < total && count < _limit; i++) {
            bytes32 proofId = pendingProofIds[i];
            if (skillProofs[proofId].status == ProofStatus.Pending || skillProofs[proofId].status == ProofStatus.Proposed) {
                tempResult[count] = proofId;
                count++;
            }
        }

        // Copy to a correctly sized array
        bytes32[] memory finalResult = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            finalResult[i] = tempResult[i];
        }
        return finalResult;
    }


    // --- V. Reputation-Gated Access & Challenges (5 Functions) ---

    // 19. `verifyUserCredentials(address _user, uint256 _minReputation, bytes32 _requiredSkillId)`
    // Utility function for checking if a user meets specified reputation and skill requirements.
    // Can be called by other contracts or frontends to gate access to features or resources.
    function verifyUserCredentials(address _user, uint256 _minReputation, bytes32 _requiredSkillId) public view returns (bool) {
        if (!userExists(_user)) return false;
        if (getReputationScore(_user) < _minReputation) return false;
        // If a specific skill is required (i.e., _requiredSkillId is not empty bytes32)
        if (_requiredSkillId != bytes32(0) && !users[_user].verifiedSkills[_requiredSkillId]) return false;
        return true;
    }

    // 20. `createChallenge(string memory _name, bytes32 _skillId, uint256 _rewardAmount, uint256 _duration)`
    // Creates a new skill-based challenge with a prize pool and time limit. Creator funds the reward.
    function createChallenge(
        string memory _name,
        bytes32 _skillId,
        uint256 _rewardAmount,
        uint256 _duration // Duration in seconds
    ) external userExists(msg.sender) nonReentrant returns (bytes32) {
        require(skills[_skillId].creator != address(0), "Skill does not exist");
        require(_rewardAmount > 0, "Challenge must have a reward");
        require(_duration > 0, "Challenge duration must be positive");
        require(vsnToken.transferFrom(msg.sender, address(this), _rewardAmount), "Failed to transfer reward tokens to contract");

        bytes32 challengeId = _generateId(abi.encodePacked(_name, _skillId, block.timestamp));
        require(challenges[challengeId].creator == address(0), "Challenge ID collision, try again");

        challenges[challengeId] = Challenge({
            id: challengeId,
            creator: msg.sender,
            name: _name,
            skillId: _skillId,
            rewardAmount: _rewardAmount,
            expirationTimestamp: block.timestamp + _duration,
            isFinalized: false,
            participants: new address[](0)
        });
        emit ChallengeCreated(challengeId, _skillId, msg.sender, _rewardAmount, block.timestamp + _duration);
        return challengeId;
    }

    // 21. `submitChallengeSolution(bytes32 _challengeId, bytes32 _proofId)`
    // Allows a participant to submit a solution to a challenge, referencing an already verified skill proof.
    function submitChallengeSolution(bytes32 _challengeId, bytes32 _proofId) external userExists(msg.sender) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.creator != address(0), "Challenge not found");
        require(!challenge.isFinalized, "Challenge is already finalized");
        require(block.timestamp <= challenge.expirationTimestamp, "Challenge has expired");
        require(challenge.solutions[msg.sender] == bytes32(0), "User already submitted a solution for this challenge");

        SkillProof storage proof = skillProofs[_proofId];
        require(proof.prover == msg.sender, "Proof must belong to the sender");
        require(proof.status == ProofStatus.Validated || proof.status == ProofStatus.ArbitratedValid, "Proof must be validated");
        require(proof.skillId == challenge.skillId, "Proof does not match challenge skill");

        challenge.solutions[msg.sender] = _proofId;
        challenge.participants.push(msg.sender); // Add participant to the list
        _applyReputationDecay(msg.sender); // Apply decay before marking activity
        users[msg.sender].lastActivityTimestamp = block.timestamp; // Mark activity
        emit ChallengeSolutionSubmitted(_challengeId, msg.sender, _proofId);
    }

    // 22. `finalizeChallenge(bytes32 _challengeId)`
    // The challenge creator finalizes the challenge, distributing rewards to eligible participants.
    // In this simplified version, all participants with a valid, matching skill proof are eligible.
    // A more complex system might involve a jury or voting mechanism to select winners.
    function finalizeChallenge(bytes32 _challengeId) external nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.creator != address(0), "Challenge not found");
        require(challenge.creator == msg.sender, "Only challenge creator can finalize");
        require(block.timestamp > challenge.expirationTimestamp, "Challenge has not expired yet");
        require(!challenge.isFinalized, "Challenge is already finalized");
        require(challenge.participants.length > 0, "No participants to finalize rewards for");

        uint256 eligibleParticipantsCount = 0;
        for (uint256 i = 0; i < challenge.participants.length; i++) {
            address participant = challenge.participants[i];
            bytes32 solutionProofId = challenge.solutions[participant];
            SkillProof storage solutionProof = skillProofs[solutionProofId];
            // Check if proof exists, belongs to participant, is validated, and matches the challenge skill
            if (solutionProof.prover == participant &&
                (solutionProof.status == ProofStatus.Validated || solutionProof.status == ProofStatus.ArbitratedValid) &&
                solutionProof.skillId == challenge.skillId)
            {
                eligibleParticipantsCount++;
            }
        }

        require(eligibleParticipantsCount > 0, "No eligible participants found to distribute rewards");
        uint256 rewardPerParticipant = challenge.rewardAmount / eligibleParticipantsCount;
        uint256 distributedRewards = 0;

        for (uint256 i = 0; i < challenge.participants.length; i++) {
            address participant = challenge.participants[i];
            bytes32 solutionProofId = challenge.solutions[participant];
            SkillProof storage solutionProof = skillProofs[solutionProofId];
            if (solutionProof.prover == participant &&
                (solutionProof.status == ProofStatus.Validated || solutionProof.status == ProofStatus.ArbitratedValid) &&
                solutionProof.skillId == challenge.skillId)
            {
                require(vsnToken.transfer(participant, rewardPerParticipant), "Failed to transfer challenge reward");
                distributedRewards += rewardPerParticipant;
                _grantReputation(participant, REPUTATION_GAIN_PROOF_SUBMISSION); // Reward for successful participation
            }
        }
        
        // If there's any remainder due to division, send it back to the challenge creator.
        if (challenge.rewardAmount > distributedRewards) {
            require(vsnToken.transfer(challenge.creator, challenge.rewardAmount - distributedRewards), "Failed to transfer remainder");
        }

        challenge.isFinalized = true;
        emit ChallengeFinalized(_challengeId, msg.sender, distributedRewards);
    }

    // 23. `getChallengeDetails(bytes32 _challengeId)`
    // Retrieves all details for a given challenge ID, including its participants.
    function getChallengeDetails(bytes32 _challengeId) external view returns (
        bytes32 id,
        address creator,
        string memory name,
        bytes32 skillId,
        uint256 rewardAmount,
        uint256 expirationTimestamp,
        bool isFinalized,
        address[] memory participants // Returns a copy of the participants array
    ) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.creator != address(0), "Challenge not found"); // Check if challenge exists
        return (
            challenge.id,
            challenge.creator,
            challenge.name,
            challenge.skillId,
            challenge.rewardAmount,
            challenge.expirationTimestamp,
            challenge.isFinalized,
            challenge.participants
        );
    }

    // --- Admin/Owner Functions ---
    // (Inherited from OpenZeppelin's Ownable: transferOwnership, renounceOwnership)

    // Set a new VSN Token address. Only callable by the contract owner.
    function setVsnTokenAddress(address _newVsnTokenAddress) external onlyOwner {
        require(_newVsnTokenAddress != address(0), "Invalid VSN Token address");
        vsnToken = IERC20(_newVsnTokenAddress);
    }

    // Set a new Proof of Humanity Oracle address. Only callable by the contract owner.
    function setProofOfHumanityOracle(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "Invalid PoH Oracle address");
        proofOfHumanityOracle = IProofOfHumanityOracle(_newOracleAddress);
    }

    // Withdraw any ETH accidentally sent to the contract (e.g., leftover from proof submission fees).
    // Only callable by the contract owner.
    function withdrawEth() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    // Withdraw any VSN tokens accidentally sent to the contract (e.g., unused rewards, excess stakes).
    // Only callable by the contract owner.
    function withdrawVsnTokens(uint256 _amount) external onlyOwner nonReentrant {
        require(vsnToken.transfer(owner(), _amount), "VSN token withdrawal failed");
    }
}
```