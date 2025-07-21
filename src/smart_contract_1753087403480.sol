The `ChronoGraph Protocol` is an innovative Solidity smart contract designed to establish a dynamic, verifiable on-chain reputation and skill system for users, which then influences their participation in a gamified ecosystem. Unlike static NFT-based reputation systems, `ChronoGraph` introduces **decaying and leveling traits**, **adaptive incentive mechanisms**, and **decentralized governance** directly tied to user reputation.

The core idea is to create a living, evolving protocol where user actions, contributions, and engagement directly shape their on-chain identity and their share of protocol rewards.

---

## ChronoGraph Protocol: Outline and Function Summary

**Contract Overview:**
The `ChronoGraph Protocol` aims to establish a dynamic, verifiable on-chain reputation and skill system for users, which then influences their participation in a gamified ecosystem. Incentives and challenges adapt over time based on collective activity, governance decisions, and external data.

**Key Concepts:**
*   **Dynamic Traits (ERC721 NFTs):** Reputation tokens that can level up with accumulated experience, decay over time if inactive, and are tied to specific user activities or verifiable achievements. They represent a user's skills and standing.
*   **Gamified Challenges & Quests:** A system where protocol-defined tasks (challenges) can be completed by users to earn Traits, XP, and native protocol tokens. Challenges can have requirements based on existing Traits.
*   **Adaptive Incentives:** Reward distribution (using a native protocol token, `$CHRONO`) is not static but dynamically adjusts based on overall protocol activity, user engagement metrics, and potentially external market conditions fetched via an Oracle.
*   **Epoch-based Progression:** The protocol's state, particularly reward calculations and incentive re-evaluation, progresses in discrete time periods called epochs.
*   **Decentralized Governance:** A DAO-like structure where voting power is directly influenced by a user's accumulated Traits and their levels. This allows the community to propose and vote on evolving protocol parameters, new challenges, or even protocol upgrades.
*   **Oracle Integration:** Utilizes an external oracle for verifiable off-chain attestations (e.g., for complex challenge completions) and for fetching external data (like market prices) to influence adaptive incentives.

**Solidity Version & Imports:**
`Solidity ^0.8.20`. Leverages OpenZeppelin contracts for standard functionalities like `AccessControl` (for roles), `Pausable` (for emergency pausing), `ERC721` (for Traits as NFTs), `IERC20` (for the native reward token), `Counters` (for ID generation), and `ReentrancyGuard`.

---

**Function Summary:**

**I. Admin & Protocol Management (8 functions)**
1.  `constructor(address initialAdmin, address _chronoToken, address _oracleAddress, string memory _traitsBaseURI)`: Initializes the contract, sets up administrative roles, links to the native reward token and trusted oracle, and defines the base URI for Trait NFT metadata. Also pre-registers default `TraitTypes`.
2.  `setProtocolParameters(uint256 _epochDuration, uint256 _baseRewardFactor, uint256 _traitDecayRate, uint256 _proposalQuorumPercentage)`: Allows `ADMIN_ROLE` to adjust global protocol parameters like epoch duration, base reward calculation factor, trait decay rates, and governance quorum percentage.
3.  `setTrustedOracle(address _newOracleAddress)`: Enables `ADMIN_ROLE` to update the address of the trusted oracle contract and update `ORACLE_ROLE`.
4.  `pause()`: Allows `PAUSER_ROLE` to pause critical, user-facing functionalities of the protocol in emergencies.
5.  `unpause()`: Allows `PAUSER_ROLE` to unpause the protocol.
6.  `grantRole(bytes32 role, address account)`: Grants a specific role (e.g., `MINTER_ROLE`, `CHALLENGE_MANAGER_ROLE`) to an address (only by `ADMIN_ROLE`).
7.  `revokeRole(bytes32 role, address account)`: Revokes a specific role from an address (only by `ADMIN_ROLE`).
8.  `renounceRole(bytes32 role)`: Allows an account to voluntarily renounce a role they hold.

**II. User Profile & Trait Management (7 functions)**
9.  `registerUser()`: Allows any address to register as a user in the protocol, creating a basic profile and potentially minting a default "Community Member" trait.
10. `mintTrait(address to, uint256 traitTypeId, string memory _metadataURI)`: Mints a new `TraitInstance` (NFT) of a specific `TraitType` to a user. Callable by `MINTER_ROLE` or internally upon challenge completion.
11. `burnTrait(uint256 tokenId)`: Allows a user to burn their own `TraitInstance` NFT, provided it's not "soulbound."
12. `upgradeTraitLevel(uint256 tokenId)`: Enables a user to increase the level of their `TraitInstance` by consuming accumulated XP.
13. `getUserTraits(address user)`: (View) Returns an array of `TraitInstance` token IDs owned by a specific user.
14. `getTraitDetails(uint256 tokenId)`: (View) Returns comprehensive details about a specific `TraitInstance` NFT, including its `TraitType` information.
15. `updateTraitActivity(uint256 tokenId)`: Allows a user to manually update the `lastActiveTimestamp` of their trait, effectively resetting its decay timer, signaling active engagement.

**III. Challenge & Quest System (7 functions)**
16. `createChallenge(string memory name, string memory description, uint256 requiredTraitTypeId, uint256 requiredTraitLevel, uint256 rewardTraitTypeId, uint256 rewardXP, uint256 rewardAmount, uint256 deadline, bytes32 verificationMethodHash, bool isMutable)`: Allows `CHALLENGE_MANAGER_ROLE` or Governance to define a new challenge, specifying its requirements, rewards, deadline, and verification method (e.g., on-chain event, oracle attestation).
17. `submitChallengeCompletion(uint256 challengeId, bytes32 proofHash)`: Users submit proof of completing a challenge. This function validates requirements and passes the proof to the appropriate verification method (internal logic or oracle).
18. `verifyChallengeCompletion(uint256 challengeId, address user, bytes32 proofHash)`: (Internal or Oracle-called) Verifies the submitted proof for a challenge completion. This function is not directly exposed but used by `submitChallengeCompletion`.
19. `claimChallengeReward(uint256 challengeId)`: Allows a user to claim rewards (XP for traits, CHRONO tokens) after their challenge completion has been verified.
20. `getChallengeDetails(uint256 challengeId)`: (View) Returns all configurable details of a specific challenge.
21. `listActiveChallenges()`: (View) Returns a list of all currently active and available challenge IDs.
22. `setChallengeStatus(uint256 challengeId, bool isActive)`: Allows `CHALLENGE_MANAGER_ROLE` to activate or deactivate mutable challenges.

**IV. Adaptive Incentive & Economy (5 functions)**
23. `depositRewards(uint256 amount)`: Allows anyone to deposit `$CHRONO` tokens into the protocol's reward pool, fueling future epoch distributions.
24. `initiateEpochCalculation()`: Triggers the calculation of rewards for the current epoch. This function advances the epoch, aggregates user scores (which involves applying trait decay), and determines the total reward pool for the epoch.
25. `claimPendingRewards()`: Allows users to claim their accumulated `$CHRONO` rewards from previous epoch distributions.
26. `getCurrentEpoch()`: (View) Returns the current epoch number.
27. `getEstimatedUserReward(address user)`: (View) Provides an estimate of a user's potential reward share based on their current score relative to the `totalProtocolScoreLastEpoch`.

**V. Decentralized Governance (5 functions)**
28. `proposeAction(string memory description, bytes memory callData, address targetContract, uint256 value)`: Users with sufficient `votingPower` (derived from their Traits) can propose an action (e.g., updating protocol parameters, creating a new challenge, or any arbitrary call to a contract).
29. `voteOnProposal(uint256 proposalId, bool _support)`: Allows users with voting power to cast their vote (for or against) on an active proposal.
30. `executeProposal(uint256 proposalId)`: Executes a successfully voted-on proposal, provided the voting period has ended and quorum/majority conditions are met.
31. `getProposalDetails(uint256 proposalId)`: (View) Returns comprehensive details about a specific governance proposal.
32. `getUserVotingPower(address user)`: (View) Calculates and returns a user's current voting power based on the levels and weights of their owned `TraitInstances`.

**Internal/Helper Functions (not directly callable externally):**
*   `_calculateUserScore(address user)`: Computes a user's aggregate score based on their traits (levels, XP, weights) and applies trait decay. This score is crucial for reward distribution and governance.
*   `_applyTraitDecay(uint256 tokenId)`: Applies a pre-defined decay rate to a `TraitInstance`'s XP (and potentially level) based on its inactivity duration.
*   `_advanceEpoch()`: Increments the `currentEpoch` and updates `lastEpochCalculationTime`.
*   `_distributeEpochRewardsInternal()`: (Internal) Handles the internal logic of distributing calculated epoch rewards to user's pending balances.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For getUserTraits
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// Interface for a hypothetical Oracle service for external data
// In a real dApp, this would connect to a Chainlink or similar oracle network.
interface IChronoGraphOracle {
    // Example: Fetches a price for dynamic incentive adjustments
    function getLatestPrice(string calldata symbol) external view returns (uint256);
    // Example: Verifies an off-chain attestation for challenge completion
    function verifyExternalAttestation(bytes32 attestationHash, address user) external view returns (bool);
}

// Outline and Function Summary:
//
// ChronoGraph Protocol: A Dynamic On-chain Reputation & Skill Protocol with Adaptive Gamified Incentives.
// This protocol enables users to accrue verifiable, dynamic 'Traits' (NFTs) representing their skills
// and achievements within an evolving ecosystem. These Traits influence participation in challenges,
// governance, and determine their share of dynamically adjusted protocol rewards.
//
// Key Concepts:
// - Dynamic Traits (ERC721 NFTs): Reputation tokens that can level up, decay over time, and are tied to user activity.
// - Gamified Challenges: Quests and tasks users complete to earn Traits, XP, and rewards.
// - Adaptive Incentives: Reward distribution dynamically adjusts based on protocol activity,
//   user engagement, and external market conditions (via Oracle).
// - Epoch-based Progression: Protocol state and incentive calculations advance in discrete time periods.
// - Decentralized Governance: Reputation (Traits) grants voting power to evolve protocol parameters.
// - Oracle Integration: For verifiable off-chain attestations and market data.
//
// Function Summary:
//
// I. Admin & Protocol Management:
//    1. constructor(address initialAdmin, address _chronoToken, address _oracleAddress, string memory _traitsBaseURI):
//       Initializes the contract, sets roles, reward token, oracle, and Trait NFT base URI.
//    2. setProtocolParameters(uint256 _epochDuration, uint256 _baseRewardFactor, uint256 _traitDecayRate, uint256 _proposalQuorumPercentage):
//       Sets core global parameters like epoch duration, base reward calculation factor, and trait decay.
//    3. setTrustedOracle(address _newOracleAddress): Updates the address of the trusted oracle.
//    4. pause(): Pauses core protocol functionalities (only by PAUSER_ROLE).
//    5. unpause(): Unpauses core protocol functionalities (only by PAUSER_ROLE).
//    6. grantRole(bytes32 role, address account): Grants a role to an address.
//    7. revokeRole(bytes32 role, address account): Revokes a role from an address.
//    8. renounceRole(bytes32 role): Renounces a role.
//
// II. User Profile & Trait Management:
//    9. registerUser(): Registers a new user profile in the protocol.
//    10. mintTrait(address to, uint256 traitTypeId, string memory _metadataURI):
//        Mints a new Trait NFT to a user (callable by MINTER_ROLE or internal completion).
//    11. burnTrait(uint256 tokenId): Allows a user to burn their own Trait NFT.
//    12. upgradeTraitLevel(uint256 tokenId): Increases a Trait NFT's level (requires XP).
//    13. getUserTraits(address user): Returns a list of Trait NFT IDs owned by a user.
//    14. getTraitDetails(uint256 tokenId): Returns details of a specific Trait NFT.
//    15. updateTraitActivity(uint256 tokenId): Internal/external function to update last active timestamp, preventing decay.
//
// III. Challenge & Quest System:
//    16. createChallenge(string memory name, string memory description, uint256 requiredTraitTypeId, uint256 requiredTraitLevel,
//                        uint256 rewardTraitTypeId, uint256 rewardXP, uint256 rewardAmount, uint256 deadline,
//                        bytes32 verificationMethodHash, bool isMutable):
//        Creates a new challenge definition (only by CHALLENGE_MANAGER_ROLE or Governance).
//    17. submitChallengeCompletion(uint256 challengeId, bytes32 proofHash):
//        User submits proof for challenge completion.
//    18. verifyChallengeCompletion(uint256 challengeId, address user, bytes32 proofHash):
//        Internal or Oracle-triggered verification of challenge completion.
//    19. claimChallengeReward(uint256 challengeId): User claims rewards after successful verification.
//    20. getChallengeDetails(uint256 challengeId): Returns details of a specific challenge.
//    21. listActiveChallenges(): Returns a list of currently active challenge IDs.
//    22. setChallengeStatus(uint256 challengeId, bool isActive): Activates or deactivates a challenge.
//
// IV. Adaptive Incentive & Economy:
//    23. depositRewards(uint256 amount): Anyone can deposit CHRONO tokens into the reward pool.
//    24. initiateEpochCalculation(): Triggers the calculation of rewards for the current epoch (callable by anyone).
//    25. claimPendingRewards(): Users claim their accumulated CHRONO rewards from previous epochs.
//    26. getCurrentEpoch(): Returns the current epoch number.
//    27. getEstimatedUserReward(address user): Estimates a user's potential reward for the current epoch.
//
// V. Decentralized Governance:
//    28. proposeAction(string memory description, bytes memory callData, address targetContract, uint256 value):
//        Users with sufficient voting power propose an action.
//    29. voteOnProposal(uint256 proposalId, bool _support): Users vote on an active proposal.
//    30. executeProposal(uint256 proposalId): Executes a successful proposal.
//    31. getProposalDetails(uint256 proposalId): Returns details of a specific proposal.
//    32. getUserVotingPower(address user): Calculates and returns a user's current voting power based on their Traits.
//
// Internal/Helper Functions (not directly callable externally):
// - _calculateUserScore(address user): Calculates a user's overall score based on their traits and challenge completions.
// - _applyTraitDecay(uint256 tokenId): Applies decay to a trait's level based on last activity.
// - _advanceEpoch(): Advances the protocol to the next epoch.
// - _distributeEpochRewardsInternal(uint256 epoch): Internal function for distributing rewards after an epoch calculation.
//
// This comprehensive design ensures a dynamic, user-centric, and evolvable on-chain reputation system.

error ChronoGraph__AlreadyRegistered();
error ChronoGraph__NotRegistered();
error ChronoGraph__InvalidTraitId();
error ChronoGraph__InsufficientTraitXP();
error ChronoGraph__TraitNotOwned();
error ChronoGraph__TraitIsSoulbound();
error ChronoGraph__TraitMaxLevelReached();
error ChronoGraph__ChallengeNotFound();
error ChronoGraph__ChallengeNotActive();
error ChronoGraph__ChallengeDeadlinePassed();
error ChronoGraph__ChallengeAlreadyCompleted();
error ChronoGraph__ChallengeProofInvalid();
error ChronoGraph__NoPendingRewards();
error ChronoGraph__InsufficientVotingPower();
error ChronoGraph__ProposalNotFound();
error ChronoGraph__ProposalNotActive();
error ChronoGraph__ProposalNotExecutable();
error ChronoGraph__ProposalAlreadyExecuted();
error ChronoGraph__VotingPeriodNotEnded();
error ChronoGraph__VoteAlreadyCast();
error ChronoGraph__EpochNotReadyForCalculation();
error ChronoGraph__RewardPoolEmpty();
error ChronoGraph__InsufficientBalance();
error ChronoGraph__ChallengeNotMutable();
error ChronoGraph__TraitTypeNotExists();

contract ChronoGraph is ERC721Enumerable, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // For minting Traits
    bytes32 public constant CHALLENGE_MANAGER_ROLE = keccak256("CHALLENGE_MANAGER_ROLE"); // For creating/managing challenges
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For trusted oracle attestation

    // --- State Variables ---
    IERC20 public immutable CHRONO_TOKEN;
    IChronoGraphOracle public trustedOracle;

    // Counters for unique IDs
    Counters.Counter private _traitTokenIds; // For Trait NFT instances
    Counters.Counter private _challengeIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _traitTypeIds; // For different types of traits (e.g., Developer, Contributor)

    // --- Data Structures ---

    // Represents a user's profile
    struct UserProfile {
        bool isRegistered;
        uint256 lastActivityTimestamp; // Overall user activity, can prevent decay on all traits
        uint256 totalUserScore; // Aggregated score based on traits & challenge completions (updated on epoch calc)
        // Mapping from challengeId to completion status for a user
        mapping(uint256 => bool) completedChallenges;
    }

    // Defines a type of Trait (e.g., 'Developer', 'Community Contributor')
    struct TraitType {
        uint256 id;
        string name;
        string description;
        uint256 baseXPRequirement; // Base XP needed to reach level 1
        uint256 xpMultiplierPerLevel; // Multiplier for XP requirement for higher levels
        uint256 decayRatePerDay; // XP decay per day if inactive
        uint256 maxLevel;
        bool isSoulbound; // If true, cannot be transferred or burned by user
        uint256 traitWeight; // Weight for user score and voting power calculation
        bool exists; // To check if the TraitType ID is valid
    }

    // Represents an instance of a user's Trait (NFT)
    struct TraitInstance {
        uint256 traitTypeId;
        uint256 level;
        uint256 currentXP;
        uint256 lastActiveTimestamp; // Specific to this trait instance
        bool exists; // To check if the TraitInstance at tokenId is valid
    }

    // Defines a Challenge (Quest)
    struct Challenge {
        uint256 id;
        string name;
        string description;
        uint256 requiredTraitTypeId; // 0 if no specific trait required
        uint256 requiredTraitLevel;
        uint256 rewardTraitTypeId; // 0 if no trait rewarded
        uint256 rewardXP; // XP awarded to trait for completing (if rewardTraitTypeId != 0)
        uint256 rewardAmount; // CHRONO tokens rewarded
        uint256 deadline; // 0 if no deadline
        bytes32 verificationMethodHash; // E.g., keccak256("ON_CHAIN_EVENT"), keccak256("ORACLE_ATTESTATION")
        bool isActive;
        bool isMutable; // Can be updated by challenge manager
    }

    // Represents a Governance Proposal
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;
        address targetContract;
        uint256 value; // ETH to be sent with callData, if any
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if a user has voted on this proposal
    }

    // --- Protocol Parameters (Adjustable via Governance/Admin) ---
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public baseRewardFactor; // Multiplier for calculating epoch rewards (e.g., 1000 means rewards are scaled by 1/1000 of total pool)
    uint256 public traitDecayRate; // Global rate for trait decay (e.g., how much XP decays per day for each traitType's decayRatePerDay)
    uint256 public proposalQuorumPercentage; // Percentage of total *snapshot* voting power required for a quorum (e.g., 20 for 20%)
    uint256 public minVotingPowerToPropose; // Minimum voting power required to create a proposal

    // --- Epoch Management ---
    uint256 public currentEpoch;
    uint256 public lastEpochCalculationTime;
    uint256 public totalProtocolScoreLastEpoch; // Sum of all user scores in the previous epoch (used for current epoch's rewards)
    uint256 public totalEpochRewardPoolLastEpoch; // Total CHRONO available for previous epoch distribution
    uint256 public totalRewardClaimedLastEpoch; // Total CHRONO claimed for last epoch

    // --- Mappings ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => TraitType) public traitTypes; // traitTypeId => TraitType
    mapping(uint256 => TraitInstance) public traitInstances; // tokenId => TraitInstance (for ERC721)
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public userPendingRewards; // Rewards accumulated per user from epoch distributions

    // --- Events ---
    event UserRegistered(address indexed user);
    event TraitMinted(address indexed to, uint256 indexed tokenId, uint256 traitTypeId, uint256 level);
    event TraitBurned(address indexed from, uint256 indexed tokenId);
    event TraitLevelUp(uint256 indexed tokenId, uint256 newLevel, uint256 newXP);
    event TraitDecayed(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel, uint256 oldXP, uint256 newXP);

    event ChallengeCreated(uint256 indexed challengeId, string name, address indexed creator);
    event ChallengeCompleted(uint256 indexed challengeId, address indexed user, uint256 rewardAmount);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed user, uint256 amount);
    event ChallengeStatusChanged(uint256 indexed challengeId, bool newStatus);

    event RewardsDeposited(address indexed depositor, uint256 amount);
    event EpochCalculationInitiated(uint256 indexed epoch, uint256 totalScore, uint256 totalRewardPool);
    event RewardsClaimed(address indexed user, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event ProtocolParametersUpdated(uint256 epochDuration, uint256 baseRewardFactor, uint256 traitDecayRate, uint256 proposalQuorumPercentage);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---
    modifier onlyMinter() {
        _checkRole(MINTER_ROLE);
        _;
    }

    modifier onlyChallengeManager() {
        _checkRole(CHALLENGE_MANAGER_ROLE);
        _;
    }

    modifier onlyOracle() {
        _checkRole(ORACLE_ROLE);
        _;
    }

    modifier onlyAdmin() {
        _checkRole(ADMIN_ROLE);
        _;
    }

    modifier onlyPauser() {
        _checkRole(PAUSER_ROLE);
        _;
    }

    modifier userRegistered() {
        if (!userProfiles[_msgSender()].isRegistered) revert ChronoGraph__NotRegistered();
        _;
    }

    // --- Constructor ---
    constructor(
        address initialAdmin,
        address _chronoToken,
        address _oracleAddress,
        string memory _traitsBaseURI
    ) ERC721("ChronoGraph Trait", "CGT") ERC721Enumerable() {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin); // Custom admin role for specific protocol functions
        _grantRole(PAUSER_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(CHALLENGE_MANAGER_ROLE, initialAdmin);
        _grantRole(ORACLE_ROLE, _oracleAddress); // Set initial oracle role

        CHRONO_TOKEN = IERC20(_chronoToken);
        trustedOracle = IChronoGraphOracle(_oracleAddress);
        _setBaseURI(_traitsBaseURI); // Base URI for Trait NFT metadata

        // Set initial default parameters
        epochDuration = 7 days; // 1 week
        baseRewardFactor = 1000; // E.g., if total pool is 1000 CHRONO, and factor is 1000, 1 CHRONO is paid out per score unit.
        traitDecayRate = 1; // 1 unit of decay per day, applied against traitType.decayRatePerDay
        proposalQuorumPercentage = 20; // 20% quorum
        minVotingPowerToPropose = 100; // Example: Minimum voting power to create a proposal
        currentEpoch = 1;
        lastEpochCalculationTime = block.timestamp;

        // Register default trait types
        // TraitType 1: Community Member
        _traitTypeIds.increment();
        traitTypes[_traitTypeIds.current()] = TraitType({
            id: _traitTypeIds.current(),
            name: "Community Member",
            description: "Basic participation in the protocol. Earned on registration.",
            baseXPRequirement: 100, // XP to reach level 1 (initial level 1 has 0 XP)
            xpMultiplierPerLevel: 2, // XP for level N is baseXPReq * (multiplier^(N-1))
            decayRatePerDay: 1, // 1 XP decay per day for this trait
            maxLevel: 5,
            isSoulbound: true,
            traitWeight: 10,
            exists: true
        });

        // TraitType 2: Chrono Architect
        _traitTypeIds.increment();
        traitTypes[_traitTypeIds.current()] = TraitType({
            id: _traitTypeIds.current(),
            name: "Chrono Architect",
            description: "Developer/contributor to ChronoGraph protocol.",
            baseXPRequirement: 500,
            xpMultiplierPerLevel: 3,
            decayRatePerDay: 2, // 2 XP decay per day for this trait
            maxLevel: 10,
            isSoulbound: true,
            traitWeight: 50,
            exists: true
        });
    }

    // --- I. Admin & Protocol Management Functions ---

    function setProtocolParameters(
        uint256 _epochDuration,
        uint256 _baseRewardFactor,
        uint256 _traitDecayRate,
        uint256 _proposalQuorumPercentage
    ) external onlyAdmin {
        epochDuration = _epochDuration;
        baseRewardFactor = _baseRewardFactor;
        traitDecayRate = _traitDecayRate;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        emit ProtocolParametersUpdated(epochDuration, baseRewardFactor, traitDecayRate, proposalQuorumPercentage);
    }

    function setTrustedOracle(address _newOracleAddress) external onlyAdmin {
        address oldOracle = address(trustedOracle);
        trustedOracle = IChronoGraphOracle(_newOracleAddress);
        // Revoke old oracle role if it had one, grant new one.
        if (hasRole(ORACLE_ROLE, oldOracle)) {
            _revokeRole(ORACLE_ROLE, oldOracle);
        }
        _grantRole(ORACLE_ROLE, _newOracleAddress); // Ensure new oracle has the role
        emit OracleUpdated(oldOracle, _newOracleAddress);
    }

    function pause() external onlyPauser {
        _pause();
    }

    function unpause() external onlyPauser {
        _unpause();
    }

    // --- II. User Profile & Trait Management Functions ---

    function registerUser() external whenNotPaused nonReentrant {
        if (userProfiles[_msgSender()].isRegistered) revert ChronoGraph__AlreadyRegistered();
        userProfiles[_msgSender()].isRegistered = true;
        userProfiles[_msgSender()].lastActivityTimestamp = block.timestamp;
        emit UserRegistered(_msgSender());

        // Mint a default "Community Member" trait upon registration (TraitType ID 1 assumed)
        uint256 communityMemberTraitTypeId = 1; 
        if (!traitTypes[communityMemberTraitTypeId].exists) revert ChronoGraph__TraitTypeNotExists();
        
        _traitTokenIds.increment();
        uint256 newTraitId = _traitTokenIds.current();
        _safeMint(_msgSender(), newTraitId);
        // Default Trait metadata URI for new traits
        _setTokenURI(newTraitId, string(abi.encodePacked(baseURI(), Strings.toString(communityMemberTraitTypeId), ".json"))); 

        traitInstances[newTraitId] = TraitInstance({
            traitTypeId: communityMemberTraitTypeId,
            level: 1,
            currentXP: 0,
            lastActiveTimestamp: block.timestamp,
            exists: true
        });
        emit TraitMinted(_msgSender(), newTraitId, communityMemberTraitTypeId, 1);
    }

    function mintTrait(address to, uint256 traitTypeId, string memory _metadataURI) external onlyMinter {
        if (!traitTypes[traitTypeId].exists) revert ChronoGraph__TraitTypeNotExists();
        if (!userProfiles[to].isRegistered) revert ChronoGraph__NotRegistered();

        _traitTokenIds.increment();
        uint256 newTraitId = _traitTokenIds.current();

        _safeMint(to, newTraitId);
        _setTokenURI(newTraitId, _metadataURI); 

        traitInstances[newTraitId] = TraitInstance({
            traitTypeId: traitTypeId,
            level: 1,
            currentXP: 0,
            lastActiveTimestamp: block.timestamp,
            exists: true
        });
        emit TraitMinted(to, newTraitId, traitTypeId, 1);
    }

    function burnTrait(uint256 tokenId) external nonReentrant {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoGraph__TraitNotOwned();
        if (!traitInstances[tokenId].exists) revert ChronoGraph__InvalidTraitId();
        if (traitTypes[traitInstances[tokenId].traitTypeId].isSoulbound) revert ChronoGraph__TraitIsSoulbound();

        _burn(tokenId);
        delete traitInstances[tokenId];
        emit TraitBurned(_msgSender(), tokenId);
    }

    function upgradeTraitLevel(uint256 tokenId) external whenNotPaused nonReentrant userRegistered {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoGraph__TraitNotOwned();
        if (!traitInstances[tokenId].exists) revert ChronoGraph__InvalidTraitId();

        TraitInstance storage tInstance = traitInstances[tokenId];
        TraitType storage tType = traitTypes[tInstance.traitTypeId];

        if (tInstance.level >= tType.maxLevel) revert ChronoGraph__TraitMaxLevelReached();

        uint256 requiredXP = tType.baseXPRequirement;
        for (uint256 i = 1; i < tInstance.level; i++) { // Calculate XP for next level
            requiredXP *= tType.xpMultiplierPerLevel;
        }

        if (tInstance.currentXP < requiredXP) revert ChronoGraph__InsufficientTraitXP();

        tInstance.currentXP -= requiredXP;
        tInstance.level += 1;
        tInstance.lastActiveTimestamp = block.timestamp; // Leveling up counts as activity
        emit TraitLevelUp(tokenId, tInstance.level, tInstance.currentXP);
    }

    function _applyTraitDecay(uint256 tokenId) internal {
        TraitInstance storage tInstance = traitInstances[tokenId];
        if (!tInstance.exists || tInstance.level == 0) return;

        TraitType storage tType = traitTypes[tInstance.traitTypeId];
        if (tType.decayRatePerDay == 0) return;

        uint256 timeElapsed = block.timestamp - tInstance.lastActiveTimestamp;
        uint256 daysElapsed = timeElapsed / 1 days;

        if (daysElapsed > 0) {
            uint256 xpDecay = daysElapsed * tType.decayRatePerDay * traitDecayRate; // Global decay rate factored in
            uint256 oldXP = tInstance.currentXP;
            uint256 oldLevel = tInstance.level;

            if (tInstance.currentXP <= xpDecay) {
                tInstance.currentXP = 0;
                // Optional: Logic to make level decay if XP reaches zero and activity is very low.
                // For simplicity, traits only decay XP, not level directly, requiring more work to level up again.
            } else {
                tInstance.currentXP -= xpDecay;
            }
            tInstance.lastActiveTimestamp = block.timestamp; // Reset decay timer

            emit TraitDecayed(tokenId, oldLevel, tInstance.level, oldXP, tInstance.currentXP);
        }
    }

    function updateTraitActivity(uint256 tokenId) external whenNotPaused nonReentrant userRegistered {
        if (ownerOf(tokenId) != _msgSender()) revert ChronoGraph__TraitNotOwned();
        if (!traitInstances[tokenId].exists) revert ChronoGraph__InvalidTraitId();

        traitInstances[tokenId].lastActiveTimestamp = block.timestamp;
        userProfiles[_msgSender()].lastActivityTimestamp = block.timestamp; // Update user's overall activity too
    }

    function getUserTraits(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokens[i] = tokenOfOwnerByIndex(user, i);
        }
        return tokens;
    }

    function getTraitDetails(uint256 tokenId) external view returns (
        uint256 traitTypeId,
        uint256 level,
        uint256 currentXP,
        uint256 lastActiveTimestamp,
        string memory name,
        string memory description,
        uint256 maxLevel,
        bool isSoulbound
    ) {
        TraitInstance storage tInstance = traitInstances[tokenId];
        if (!tInstance.exists) revert ChronoGraph__InvalidTraitId();

        TraitType storage tType = traitTypes[tInstance.traitTypeId];
        if (!tType.exists) revert ChronoGraph__TraitTypeNotExists();

        return (
            tInstance.traitTypeId,
            tInstance.level,
            tInstance.currentXP,
            tInstance.lastActiveTimestamp,
            tType.name,
            tType.description,
            tType.maxLevel,
            tType.isSoulbound
        );
    }

    // --- III. Challenge & Quest System ---

    function createChallenge(
        string memory name,
        string memory description,
        uint256 requiredTraitTypeId,
        uint256 requiredTraitLevel,
        uint256 rewardTraitTypeId,
        uint256 rewardXP,
        uint256 rewardAmount,
        uint256 deadline, // 0 for no deadline
        bytes32 verificationMethodHash,
        bool isMutable
    ) external onlyChallengeManager whenNotPaused {
        if (requiredTraitTypeId != 0 && !traitTypes[requiredTraitTypeId].exists) revert ChronoGraph__TraitTypeNotExists();
        if (rewardTraitTypeId != 0 && !traitTypes[rewardTraitTypeId].exists) revert ChronoGraph__TraitTypeNotExists();

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            name: name,
            description: description,
            requiredTraitTypeId: requiredTraitTypeId,
            requiredTraitLevel: requiredTraitLevel,
            rewardTraitTypeId: rewardTraitTypeId,
            rewardXP: rewardXP,
            rewardAmount: rewardAmount,
            deadline: deadline,
            verificationMethodHash: verificationMethodHash,
            isActive: true, // Challenges are active by default upon creation
            isMutable: isMutable
        });

        emit ChallengeCreated(newChallengeId, name, _msgSender());
    }

    function submitChallengeCompletion(uint256 challengeId, bytes32 proofHash) external whenNotPaused userRegistered nonReentrant {
        Challenge storage challenge = challenges[challengeId];
        if (challenge.id == 0) revert ChronoGraph__ChallengeNotFound();
        if (!challenge.isActive) revert ChronoGraph__ChallengeNotActive();
        if (challenge.deadline != 0 && block.timestamp > challenge.deadline) revert ChronoGraph__ChallengeDeadlinePassed();
        if (userProfiles[_msgSender()].completedChallenges[challengeId]) revert ChronoGraph__ChallengeAlreadyCompleted();

        // Check required traits
        if (challenge.requiredTraitTypeId != 0) {
            bool hasRequiredTrait = false;
            uint256[] memory userTokens = getUserTraits(_msgSender());
            for (uint256 i = 0; i < userTokens.length; i++) {
                TraitInstance storage tInst = traitInstances[userTokens[i]];
                if (tInst.traitTypeId == challenge.requiredTraitTypeId && tInst.level >= challenge.requiredTraitLevel) {
                    hasRequiredTrait = true;
                    break;
                }
            }
            if (!hasRequiredTrait) revert ChronoGraph__InsufficientTraitXP(); // Reusing for trait requirement
        }

        // Verify completion based on method
        bool verified = false;
        if (challenge.verificationMethodHash == keccak256(abi.encodePacked("ON_CHAIN_EVENT"))) {
            // For on-chain event verification, this would typically involve:
            // 1. A pre-defined event hash or contract address/function call hash.
            // 2. Verifying a specific event was emitted by a target contract by _msgSender()
            // 3. Or, checking a specific state variable/balance for _msgSender() in another contract.
            // For simplicity in this example, any submission with this method is 'verified'.
            verified = true;
        } else if (challenge.verificationMethodHash == keccak256(abi.encodePacked("ORACLE_ATTESTATION"))) {
            verified = trustedOracle.verifyExternalAttestation(proofHash, _msgSender());
        } else {
            revert ChronoGraph__ChallengeProofInvalid(); // Unknown verification method
        }

        if (!verified) revert ChronoGraph__ChallengeProofInvalid();

        userProfiles[_msgSender()].completedChallenges[challengeId] = true;
        // Reward claims are separate to allow for batching or epoch-based reward distribution
        emit ChallengeCompleted(challengeId, _msgSender(), challenge.rewardAmount);
    }

    function claimChallengeReward(uint256 challengeId) external whenNotPaused userRegistered nonReentrant {
        Challenge storage challenge = challenges[challengeId];
        if (challenge.id == 0) revert ChronoGraph__ChallengeNotFound();
        if (!userProfiles[_msgSender()].completedChallenges[challengeId]) revert ChronoGraph__ChallengeProofInvalid(); 

        // Mark as claimed. Can add another mapping `claimedChallengeRewards[user][challengeId]` for more granular state.
        userProfiles[_msgSender()].completedChallenges[challengeId] = false; 

        // Give XP to appropriate trait, if specified
        if (challenge.rewardTraitTypeId != 0) {
            uint256[] memory userTokens = getUserTraits(_msgSender());
            bool traitFound = false;
            for (uint256 i = 0; i < userTokens.length; i++) {
                TraitInstance storage tInst = traitInstances[userTokens[i]];
                if (tInst.traitTypeId == challenge.rewardTraitTypeId) {
                    tInst.currentXP += challenge.rewardXP;
                    tInst.lastActiveTimestamp = block.timestamp; // Activity from completing challenge
                    traitFound = true;
                    break;
                }
            }
            if (!traitFound) {
                // If user doesn't have the reward trait type, consider auto-minting it for them
                // This would require MINTER_ROLE logic here, or a separate mechanism.
                // For this example, if trait not found, XP is effectively lost.
                // Alternatively, add to a pending XP pool that applies to newly minted trait.
            }
        }

        // Add reward amount to user's pending rewards
        userPendingRewards[_msgSender()] += challenge.rewardAmount;
        emit ChallengeRewardClaimed(challengeId, _msgSender(), challenge.rewardAmount);
    }

    function getChallengeDetails(uint256 challengeId) external view returns (
        string memory name,
        string memory description,
        uint256 requiredTraitTypeId,
        uint256 requiredTraitLevel,
        uint256 rewardTraitTypeId,
        uint256 rewardXP,
        uint256 rewardAmount,
        uint256 deadline,
        bytes32 verificationMethodHash,
        bool isActive
    ) {
        Challenge storage challenge = challenges[challengeId];
        if (challenge.id == 0) revert ChronoGraph__ChallengeNotFound();

        return (
            challenge.name,
            challenge.description,
            challenge.requiredTraitTypeId,
            challenge.requiredTraitLevel,
            challenge.rewardTraitTypeId,
            challenge.rewardXP,
            challenge.rewardAmount,
            challenge.deadline,
            challenge.verificationMethodHash,
            challenge.isActive
        );
    }

    function listActiveChallenges() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            if (challenges[i].isActive && (challenges[i].deadline == 0 || block.timestamp <= challenges[i].deadline)) {
                count++;
            }
        }

        uint256[] memory activeChallengeIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            if (challenges[i].isActive && (challenges[i].deadline == 0 || block.timestamp <= challenges[i].deadline)) {
                activeChallengeIds[index] = i;
                index++;
            }
        }
        return activeChallengeIds;
    }

    function setChallengeStatus(uint256 challengeId, bool isActive) external onlyChallengeManager whenNotPaused {
        Challenge storage challenge = challenges[challengeId];
        if (challenge.id == 0) revert ChronoGraph__ChallengeNotFound();
        if (!challenge.isMutable) revert ChronoGraph__ChallengeNotMutable(); 

        challenge.isActive = isActive;
        emit ChallengeStatusChanged(challengeId, isActive);
    }

    // --- IV. Adaptive Incentive & Economy ---

    function depositRewards(uint256 amount) external whenNotPaused {
        if (amount == 0) revert ChronoGraph__RewardPoolEmpty();
        if (CHRONO_TOKEN.balanceOf(_msgSender()) < amount) revert ChronoGraph__InsufficientBalance();
        CHRONO_TOKEN.transferFrom(_msgSender(), address(this), amount);
        emit RewardsDeposited(_msgSender(), amount);
    }

    function initiateEpochCalculation() external whenNotPaused nonReentrant {
        // Anyone can call this to trigger epoch calculation, providing decentralization.
        if (block.timestamp < lastEpochCalculationTime + epochDuration) revert ChronoGraph__EpochNotReadyForCalculation();

        _advanceEpoch(); 

        uint256 currentProtocolScore = 0;
        uint256 totalRegisteredUsers = _traitTokenIds.current(); // Approximation of active users via trait count

        // Iterate through all minted tokens to update scores of their owners.
        // NOTE: This loop can be very gas-intensive for a large number of minted tokens.
        // For a scalable solution, a Merkle tree approach (where users submit proof of their score)
        // or a Keeper network executing this off-chain is recommended.
        for (uint256 i = 0; i < totalSupply(); i++) {
            uint256 tokenId = tokenByIndex(i); // ERC721Enumerable allows iterating all tokens
            address owner = ownerOf(tokenId);
            if (userProfiles[owner].isRegistered) {
                // Ensure unique users are counted, or sum based on individual trait scores.
                // For simplicity, we are summing each owner's score based on their traits.
                // A better approach for unique user scores might be to iterate through all registered users.
                // Given `getUserVotingPower` already sums trait scores, reuse it for `totalUserScore`.
                // This implicitly includes decay when `_calculateUserScore` is called.
                userProfiles[owner].totalUserScore = _calculateUserScore(owner); 
                currentProtocolScore += userProfiles[owner].totalUserScore;
            }
        }

        totalProtocolScoreLastEpoch = currentProtocolScore;
        totalEpochRewardPoolLastEpoch = CHRONO_TOKEN.balanceOf(address(this)); 

        // Perform internal reward distribution calculation for this epoch.
        // This calculates each user's share and adds to userPendingRewards.
        _distributeEpochRewardsInternal();

        emit EpochCalculationInitiated(currentEpoch, totalProtocolScoreLastEpoch, totalEpochRewardPoolLastEpoch);
    }

    function _distributeEpochRewardsInternal() internal {
        if (totalProtocolScoreLastEpoch == 0 || totalEpochRewardPoolLastEpoch == 0) return;

        // Rewards are distributed based on a user's score relative to the total protocol score,
        // scaled by a baseRewardFactor. This allows for dynamic reward amounts.
        uint256 availablePool = totalEpochRewardPoolLastEpoch;

        // Again, this iteration method is not scalable for many users.
        // In a production system, this would be computed off-chain and distributed
        // via a Merkle tree, allowing users to claim their specific calculated share.
        // For this example, we iterate over all users with a score.
        for (uint256 i = 0; i < totalSupply(); i++) {
            uint256 tokenId = tokenByIndex(i);
            address user = ownerOf(tokenId);
            // Ensure only registered users with a positive score get rewards
            if (userProfiles[user].isRegistered && userProfiles[user].totalUserScore > 0) {
                // Calculate user's share. Using `baseRewardFactor` to prevent over-distributing the pool
                // and allowing for variable rewards per epoch based on the factor.
                uint256 userShare = (userProfiles[user].totalUserScore * baseRewardFactor) / totalProtocolScoreLastEpoch;
                
                // Ensure calculated share does not exceed available pool or make it negative
                if (userShare > availablePool) {
                    userShare = availablePool;
                }
                
                userPendingRewards[user] += userShare;
                availablePool -= userShare; // Deduct from the pool for next user

                if (availablePool == 0) break; // If pool is empty, stop
            }
        }
        // Any remaining `availablePool` might be rolled over to next epoch or sent to a treasury.
        // For simplicity, it remains in the contract, potentially becoming part of the next epoch's pool.
    }

    function claimPendingRewards() external nonReentrant {
        uint256 amount = userPendingRewards[_msgSender()];
        if (amount == 0) revert ChronoGraph__NoPendingRewards();

        userPendingRewards[_msgSender()] = 0;
        totalRewardClaimedLastEpoch += amount; 

        // Transfer tokens from the contract to the user
        if (!CHRONO_TOKEN.transfer(_msgSender(), amount)) {
            revert ChronoGraph__InsufficientBalance(); // Should not happen if amount is from userPendingRewards
        }
        emit RewardsClaimed(_msgSender(), amount);
    }

    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    function getEstimatedUserReward(address user) external view returns (uint256) {
        if (totalProtocolScoreLastEpoch == 0 || totalEpochRewardPoolLastEpoch == 0) return 0;
        uint256 userScore = _calculateUserScore(user); // Use current score for estimate
        if (userScore == 0) return 0;
        
        // Estimate based on the current epoch's potential pool and score.
        // Note: Actual payout depends on `initiateEpochCalculation` being run.
        uint256 estimatedTotalPool = CHRONO_TOKEN.balanceOf(address(this));
        uint256 estimatedUserShare = (userScore * baseRewardFactor) / totalProtocolScoreLastEpoch;
        
        return estimatedUserShare < estimatedTotalPool ? estimatedUserShare : estimatedTotalPool;
    }

    // --- V. Decentralized Governance ---

    function proposeAction(
        string memory description,
        bytes memory callData,
        address targetContract,
        uint256 value
    ) external whenNotPaused userRegistered returns (uint256) {
        uint256 votingPower = getUserVotingPower(_msgSender());
        if (votingPower < minVotingPowerToPropose) revert ChronoGraph__InsufficientVotingPower();

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        uint256 voteDuration = 3 days; // Example: 3 days for voting

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: _msgSender(),
            description: description,
            callData: callData,
            targetContract: targetContract,
            value: value,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + voteDuration,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(newProposalId, _msgSender(), description);
        return newProposalId;
    }

    function voteOnProposal(uint256 proposalId, bool _support) external whenNotPaused userRegistered {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ChronoGraph__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ChronoGraph__ProposalNotActive();
        if (block.timestamp > proposal.voteEndTime) revert ChronoGraph__VotingPeriodNotEnded(); 
        if (proposal.hasVoted[_msgSender()]) revert ChronoGraph__VoteAlreadyCast();

        uint256 votingPower = getUserVotingPower(_msgSender());
        if (votingPower == 0) revert ChronoGraph__InsufficientVotingPower();

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit VoteCast(proposalId, _msgSender(), _support);
    }

    function executeProposal(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ChronoGraph__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ChronoGraph__ProposalNotExecutable();
        if (block.timestamp <= proposal.voteEndTime) revert ChronoGraph__VotingPeriodNotEnded(); 

        // Quorum calculation based on the total score from the *last completed epoch*.
        // A more robust DAO would snapshot voting power at proposal creation or for the entire voting period.
        uint256 totalVotingPowerSnapshot = totalProtocolScoreLastEpoch; 
        uint256 quorumNeeded = (totalVotingPowerSnapshot * proposalQuorumPercentage) / 100;

        if (proposal.votesFor < quorumNeeded) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
            return;
        }
        if (proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
            return;
        }

        // Execute the proposal using delegatecall or direct call
        // Using direct call for simplicity, assuming targetContract implements the function to be called
        // If the proposal involves sending ETH, ensure the contract has enough balance
        if (proposal.value > 0 && address(this).balance < proposal.value) revert ChronoGraph__InsufficientBalance();

        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
        if (!success) {
            proposal.state = ProposalState.Failed; // Mark as failed if execution fails
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
            revert ChronoGraph__ProposalNotExecutable(); // Indicate execution failure
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
    }

    function getProposalDetails(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 voteStartTime,
        uint256 voteEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        address targetContract,
        uint256 value
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ChronoGraph__ProposalNotFound();

        return (
            proposal.proposer,
            proposal.description,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state,
            proposal.targetContract,
            proposal.value
        );
    }

    function getUserVotingPower(address user) public view returns (uint256) {
        // Voting power is based on the sum of weighted trait levels and XP
        // For accurate voting power, decay should be applied.
        // In a view function, we calculate on the fly; for persistent state, _applyTraitDecay must be called.
        return _calculateUserScore(user); // User score is directly used as voting power
    }

    // --- Internal/Helper Functions ---

    function _calculateUserScore(address user) internal returns (uint256) {
        uint256 score = 0;
        uint256[] memory userTokens = getUserTraits(user);
        for (uint256 i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            _applyTraitDecay(tokenId); // Apply decay whenever score is calculated/updated
            TraitInstance storage tInst = traitInstances[tokenId];
            TraitType storage tType = traitTypes[tInst.traitTypeId];
            if (!tType.exists) continue; // Skip if trait type somehow disappeared

            score += (tInst.level * tType.traitWeight) + (tInst.currentXP / 10); // Example: 10 XP equals 1 score point
        }
        return score;
    }

    function _advanceEpoch() internal {
        currentEpoch++;
        lastEpochCalculationTime = block.timestamp;
    }

    // The following functions are overrides from ERC721Enumerable for custom logic or hooks
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of soulbound traits
        if (traitInstances[tokenId].exists && traitTypes[traitInstances[tokenId].traitTypeId].isSoulbound && from != address(0)) {
            revert ChronoGraph__TraitIsSoulbound(); 
        }
    }

    // Override `_approve` and `_setApprovalForAll` to prevent approvals for soulbound tokens
    function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        if (traitInstances[tokenId].exists && traitTypes[traitInstances[tokenId].traitTypeId].isSoulbound) {
            revert ChronoGraph__TraitIsSoulbound();
        }
        super._approve(to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual override(ERC721, ERC721Enumerable) {
        // This is tricky as setApprovalForAll might affect multiple tokens.
        // For soulbound tokens, direct transfer or approval should be blocked by _beforeTokenTransfer / _approve.
        // This function just sets the operator status, actual transfers are checked elsewhere.
        super._setApprovalForAll(owner, operator, approved);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback function for receiving ETH for proposals or future features
    receive() external payable {
        // Event for received ETH can be added here
    }
}
```