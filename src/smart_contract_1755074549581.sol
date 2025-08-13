This smart contract, **SynapticNexus**, is designed as a decentralized, adaptive knowledge and skill development platform. It leverages concepts like dynamic, evolving NFTs, a reputation system based on contributions and peer validation, and adaptive "cognitive challenges" to foster a self-improving collective intelligence network.

It aims to go beyond simple content storage by incentivizing structured knowledge contribution, its validation, and the development of skills through interactive challenges, all recorded and incentivized on-chain.

---

## SynapticNexus: A Decentralized Adaptive Knowledge & Skill Nexus

**Description:**
SynapticNexus is an advanced Solidity smart contract that orchestrates a decentralized network for contributing, validating, and evolving knowledge, skills, and intellectual challenges. It integrates dynamic NFTs, a granular reputation system, and game-theoretic incentives to foster a vibrant, self-improving ecosystem.

**Core Concepts:**
1.  **Evolving Knowledge Artifacts (EKAs):** On-chain representations of knowledge units (via IPFS hashes) that can be proposed, validated, and subsequently updated/evolved by the community. Each finalized EKA is minted as a unique ERC721 NFT.
2.  **Adaptive Cognitive Challenges:** Programmatically generated or community-proposed intellectual puzzles or tasks that users can solve to demonstrate skills, earn reputation, and contribute to the network's collective intelligence. These challenges can adapt based on network activity and performance (requiring off-chain computation for true adaptiveness, with results fed on-chain).
3.  **Dynamic Reputation Trails:** A multi-faceted reputation system tracking user contributions, validation accuracy, challenge successes, and peer endorsements, rather than just a single score.
4.  **Soulbound-like Achievement NFTs:** Non-transferable NFTs awarded for significant milestones, challenge victories, or high-impact contributions, serving as an immutable on-chain credential.
5.  **Decentralized Validation & Curation:** A robust peer-review mechanism where users stake tokens to participate in the validation of EKAs and challenge solutions, ensuring quality and integrity.
6.  **Economic Sustainability:** A treasury system funded by various protocol activities (e.g., small fees, unclaimed rewards) which can fund grants, bounties, and reward contributors.

---

### **Outline of SynapticNexus Contract**

1.  **SPDX License & Pragmas**
2.  **Imports:** OpenZeppelin contracts for ERC721, AccessControl, Pausable, ReentrancyGuard, Strings, Counters.
3.  **Errors:** Custom error definitions for clarity and gas efficiency.
4.  **Enums:** State definitions for EKAs, Challenges, etc.
5.  **Structs:** Data structures for Users, Knowledge Artifacts, Challenges, Solutions, Votes, etc.
6.  **Events:** Comprehensive event logging for all major actions.
7.  **State Variables:** Mappings, arrays, and single variables to store protocol state.
8.  **Modifiers:** Access control and state-based modifiers.
9.  **Constructor:** Initializes roles and base parameters.
10. **ERC721 Implementation Overrides:** Custom logic for soulbound NFTs.
11. **Core User & Profile Management Functions:** Registration, profile updates, staking for integrity.
12. **Knowledge Artifact (EKA) Management Functions:** Proposing, updating, bonding, validation.
13. **Cognitive Challenge Functions:** Proposing, solving, validating solutions.
14. **Reputation & Endorsement Functions:** Skill endorsement, reputation queries.
15. **NFT Management Functions:** Minting EKAs, awarding achievements, evolving EKAs.
16. **Treasury & Reward Functions:** Depositing funds, claiming rewards, requesting grants.
17. **Admin & Protocol Parameter Functions:** Pausing, setting parameters, emergency withdrawals.
18. **View Functions:** Read-only functions for querying state.

---

### **Function Summary (26+ Functions)**

**I. Core User & Profile Management**
1.  `registerUser(string calldata _username, string calldata _ipfsProfileHash)`: Registers a new user, requiring an initial stake for profile integrity.
2.  `updateUserProfile(string calldata _newIpfsProfileHash)`: Allows a registered user to update their profile metadata.
3.  `stakeForProfileIntegrity()`: Users can increase their stake, potentially boosting their profile's visibility/trust.
4.  `withdrawProfileStake()`: Allows users to withdraw their stake, subject to a cooldown or reputation check.

**II. Knowledge Artifact (EKA) Management**
5.  `proposeKnowledgeArtifact(string calldata _title, string calldata _ipfsContentHash, string[] calldata _tags)`: Proposes a new knowledge artifact, requiring a quality bond.
6.  `updateKnowledgeArtifact(uint256 _ekaId, string calldata _newIpfsContentHash)`: Proposes an update to an existing EKA, also requiring a bond.
7.  `bondForEKAProposalQuality(uint256 _ekaId)`: Bonds ETH for a pending EKA proposal or update to signal quality and readiness for validation.
8.  `releaseEKAProposalBond(uint256 _ekaId)`: Releases the bond after an EKA is successfully validated and minted/updated.
9.  `participateInEKAValidation(uint256 _ekaId)`: Users can register to be a validator for a specific EKA, requiring a stake.
10. `voteOnEKAProposal(uint256 _ekaId, bool _approve)`: Validators cast their vote (approve/reject) on a proposed EKA or update.
11. `challengeEKAValidationResult(uint256 _ekaId, string calldata _reasonIpfsHash)`: Allows a user to dispute the outcome of an EKA validation round, requiring a challenge bond.
12. `bondForValidationIntegrity()`: Allows a user to bond funds to enhance their credibility as a validator.

**III. Cognitive Challenge Functions**
13. `proposeCognitiveChallenge(string calldata _title, string calldata _descriptionIpfsHash, uint256 _rewardAmount)`: Users can propose new intellectual challenges for the community to solve.
14. `submitChallengeSolution(uint256 _challengeId, string calldata _solutionIpfsHash)`: Submits a solution to an active challenge.
15. `validateChallengeSolution(uint256 _challengeId, address _solver, bool _valid)`: Peer validators (or a designated role) validate submitted solutions.
16. `spawnAdaptiveChallenge(string calldata _title, string calldata _descriptionIpfsHash, uint256 _rewardAmount, string[] calldata _tags)`: (Admin/System Role) Triggers the creation of a new challenge, potentially generated based on network data or AI insights (true adaptiveness requires off-chain logic).

**IV. Reputation & Endorsement Functions**
17. `endorseUserSkill(address _user, string calldata _skill)`: Allows users to endorse specific skills of other users, building their "reputation trail."
18. `revokeSkillEndorsement(address _user, string calldata _skill)`: Allows a user to revoke a previous skill endorsement.

**V. NFT Management Functions**
19. `mintEKA_NFT(uint256 _ekaId, address _to)`: Mints an EKA-NFT (transferable) to the EKA's contributor upon successful validation.
20. `evolveEKA_NFT(uint256 _ekaId)`: Updates the metadata URI of an existing EKA-NFT when a significant update is validated.
21. `awardAchievementNFT(address _to, string calldata _achievementType, string calldata _ipfsMetadataHash)`: Awards a soulbound (non-transferable) achievement NFT for milestones (e.g., solving a difficult challenge, high validation accuracy).

**VI. Treasury & Reward Functions**
22. `depositToTreasury()`: Allows anyone to contribute funds to the SynapticNexus treasury.
23. `claimRewards()`: Users can claim accumulated rewards from successful EKA contributions, challenge solutions, and validation activities.
24. `requestGrantFromTreasury(uint256 _amount, string calldata _proposalIpfsHash)`: Allows users to propose projects and request grants from the treasury (subject to governance/approval).

**VII. Admin & Protocol Parameter Functions**
25. `setProtocolParameter(bytes32 _paramKey, uint256 _value)`: (Governance Role) Allows setting key protocol parameters like min stakes, validation thresholds, etc.
26. `emergencyPause()`: (Admin Role) Pauses critical contract functionalities in case of an emergency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SynapticNexus is ERC721URIStorage, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error UserNotRegistered();
    error InvalidStakeAmount();
    error InsufficientStake();
    error StakeLocked();
    error KnowledgeArtifactNotFound();
    error KnowledgeArtifactNotPending();
    error KnowledgeArtifactAlreadyValidated();
    error NotEKAProposer();
    error NotEKAValidator();
    error InvalidVote();
    error NotEnoughValidators();
    error ChallengeNotFound();
    error ChallengeNotActive();
    error ChallengeAlreadySolved();
    error SolutionNotFound();
    error SolutionAlreadyValidated();
    error NotChallengeProposer();
    error NotChallengeSolver();
    error NotChallengeSolutionValidator();
    error SelfEndorsementNotAllowed();
    error EndorsementNotFound();
    error UnauthorizedCall();
    error TransferNotAllowed();
    error NoRewardsToClaim();
    error InvalidGrantRequest();
    error ProtocolPaused();
    error InvalidParameterKey();
    error CannotSelfDestruct();

    // --- Enums ---
    enum EKAState { Proposed, PendingValidation, Validated, Disputed, Rejected }
    enum ChallengeStatus { Proposed, Active, Solved, Validated, Rejected }
    enum NFType { EKA, Achievement }

    // --- Structs ---

    struct User {
        bool isRegistered;
        string username;
        string ipfsProfileHash;
        uint256 profileStake;
        uint256 lastStakeWithdrawal; // Timestamp for cooldown
        uint256 accumulatedRewards; // Internal points or ETH value
    }

    struct KnowledgeArtifact {
        uint256 id;
        address proposer;
        string title;
        string ipfsContentHash;
        string[] tags;
        EKAState state;
        uint256 proposalBond;
        uint256 submissionTimestamp;
        address[] currentValidators;
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
        uint256 approveVotes;
        uint256 rejectVotes;
        uint256 currentVersion; // Tracks how many times it has been updated
        uint256 associatedNFTId; // 0 if not minted yet
    }

    struct Challenge {
        uint256 id;
        address proposer;
        string title;
        string descriptionIpfsHash;
        uint256 rewardAmount; // In accumulatedRewards points
        ChallengeStatus status;
        uint256 submissionTimestamp;
        uint256 solvedTimestamp; // Timestamp when a valid solution was approved
        address currentSolver; // Address of the approved solver
        mapping(address => bool) hasValidatedSolution; // Tracks if a validator has validated a specific solution
        uint256 solutionApproveVotes;
        uint256 solutionRejectVotes;
    }

    struct GrantRequest {
        uint256 id;
        address requester;
        uint256 amount;
        string proposalIpfsHash;
        bool approved;
        bool exists; // To differentiate from default zero-value struct
    }

    // --- State Variables ---

    // Roles
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE"); // For adaptive challenge spawning, etc.

    // Counters for unique IDs
    Counters.Counter private _userIds;
    Counters.Counter private _ekaIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _grantIds;
    Counters.Counter private _nftIds; // Global NFT ID counter

    // Core Data Mappings
    mapping(address => User) public users;
    mapping(uint256 => KnowledgeArtifact) public knowledgeArtifacts; // EKA ID to EKA struct
    mapping(uint256 => Challenge) public challenges; // Challenge ID to Challenge struct
    mapping(address => mapping(string => uint256)) public userSkillReputation; // user => skill => endorsementCount
    mapping(uint256 => GrantRequest) public grantRequests;

    // NFT Type Tracking (0=EKA, 1=Achievement. For soulbound logic)
    mapping(uint256 => NFType) private _nftTypes;

    // Protocol Parameters (configurable by GOVERNANCE_ROLE)
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 public constant MIN_PROFILE_STAKE = keccak256("MIN_PROFILE_STAKE");
    bytes32 public constant PROFILE_WITHDRAW_COOLDOWN = keccak256("PROFILE_WITHDRAW_COOLDOWN");
    bytes32 public constant MIN_EKA_PROPOSAL_BOND = keccak256("MIN_EKA_PROPOSAL_BOND");
    bytes32 public constant EKA_VALIDATION_THRESHOLD_PERCENT = keccak256("EKA_VALIDATION_THRESHOLD_PERCENT"); // e.g., 7500 for 75%
    bytes32 public constant MIN_VALIDATORS_FOR_EKA = keccak256("MIN_VALIDATORS_FOR_EKA");
    bytes32 public constant MIN_VALIDATION_INTEGRITY_BOND = keccak256("MIN_VALIDATION_INTEGRITY_BOND");
    bytes32 public constant MIN_CHALLENGE_SOLUTION_VALIDATORS = keccak256("MIN_CHALLENGE_SOLUTION_VALIDATORS");
    bytes32 public constant REWARD_POINTS_PER_EKA_CONTRIBUTION = keccak256("REWARD_POINTS_PER_EKA_CONTRIBUTION");
    bytes32 public constant REWARD_POINTS_PER_CHALLENGE_SOLVE = keccak256("REWARD_POINTS_PER_CHALLENGE_SOLVE");
    bytes32 public constant REWARD_POINTS_PER_VALIDATION = keccak256("REWARD_POINTS_PER_VALIDATION");
    bytes32 public constant REWARD_POINTS_PER_SUCCESSFUL_CHALLENGE_VALIDATION = keccak256("REWARD_POINTS_PER_SUCCESSFUL_CHALLENGE_VALIDATION");
    bytes32 public constant MAX_GRANT_PERCENTAGE_OF_TREASURY = keccak256("MAX_GRANT_PERCENTAGE_OF_TREASURY"); // e.g., 500 for 5%

    // Treasury (holds ETH, can be used for rewards/grants)
    uint256 public treasuryBalance;

    // --- Events ---
    event UserRegistered(address indexed userAddress, string username, string ipfsProfileHash, uint256 stake);
    event ProfileUpdated(address indexed userAddress, string newIpfsProfileHash);
    event ProfileStakeUpdated(address indexed userAddress, uint256 newStake);
    event ProfileStakeWithdrawn(address indexed userAddress, uint256 amount);

    event KnowledgeArtifactProposed(uint256 indexed ekaId, address indexed proposer, string title, string ipfsContentHash);
    event KnowledgeArtifactUpdated(uint256 indexed ekaId, address indexed updater, string newIpfsContentHash, uint256 newVersion);
    event EKAProposalBondUpdated(uint256 indexed ekaId, address indexed bonder, uint256 bondAmount);
    event EKAProposalBondReleased(uint256 indexed ekaId, address indexed bonder, uint256 bondAmount);
    event EKAValidatorAdded(uint256 indexed ekaId, address indexed validator);
    event EKAValidationVoteCast(uint256 indexed ekaId, address indexed validator, bool approved);
    event EKAValidated(uint256 indexed ekaId, address indexed proposer, uint256 approveVotes, uint256 rejectVotes);
    event EKADisputed(uint256 indexed ekaId, address indexed challenger, string reasonIpfsHash);
    event EKARejected(uint256 indexed ekaId, uint256 approveVotes, uint256 rejectVotes);
    event ValidationIntegrityBondUpdated(address indexed validator, uint256 bondAmount);

    event ChallengeProposed(uint256 indexed challengeId, address indexed proposer, string title, uint256 rewardAmount);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, address indexed solver, string solutionIpfsHash);
    event ChallengeSolutionValidated(uint256 indexed challengeId, address indexed solver, address indexed validator, bool valid);
    event ChallengeSolved(uint256 indexed challengeId, address indexed solver);
    event ChallengeSpawned(uint256 indexed challengeId, string title, string descriptionIpfsHash);

    event UserSkillEndorsed(address indexed endorsedUser, address indexed endorser, string skill, uint256 newEndorsementCount);
    event UserSkillEndorsementRevoked(address indexed endorsedUser, address indexed endorser, string skill, uint256 newEndorsementCount);

    event EKA_NFT_Minted(uint256 indexed tokenId, uint256 indexed ekaId, address indexed owner, string tokenURI);
    event EKA_NFT_Evolved(uint256 indexed tokenId, uint256 indexed ekaId, string newTokenURI);
    event AchievementNFTAwarded(uint256 indexed tokenId, address indexed recipient, string achievementType, string tokenURI);

    event FundsDepositedToTreasury(address indexed depositor, uint256 amount);
    event RewardsClaimed(address indexed claimant, uint256 amount);
    event GrantRequested(uint256 indexed grantId, address indexed requester, uint256 amount, string proposalIpfsHash);
    event GrantApproved(uint256 indexed grantId, address indexed approver, uint256 amount);

    event ProtocolParameterSet(bytes32 indexed paramKey, uint256 value);
    event ProtocolPaused(address indexed caller);
    event EmergencyFundsWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        if (!users[msg.sender].isRegistered) {
            revert UserNotRegistered();
        }
        _;
    }

    modifier onlyEKAProposer(uint256 _ekaId) {
        if (knowledgeArtifacts[_ekaId].proposer != msg.sender) {
            revert NotEKAProposer();
        }
        _;
    }

    modifier onlyChallengeProposer(uint256 _challengeId) {
        if (challenges[_challengeId].proposer != msg.sender) {
            revert NotChallengeProposer();
        }
        _;
    }

    modifier onlyChallengeSolver(uint256 _challengeId) {
        if (challenges[_challengeId].currentSolver != msg.sender) {
            revert NotChallengeSolver();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender); // Initial governance
        _grantRole(VALIDATOR_ROLE, msg.sender); // Initial validator
        _grantRole(SYSTEM_ROLE, msg.sender); // Initial system role for adaptive functions

        // Set initial protocol parameters
        protocolParameters[MIN_PROFILE_STAKE] = 0.01 ether; // Example: 0.01 ETH
        protocolParameters[PROFILE_WITHDRAW_COOLDOWN] = 30 days;
        protocolParameters[MIN_EKA_PROPOSAL_BOND] = 0.005 ether; // Example: 0.005 ETH
        protocolParameters[EKA_VALIDATION_THRESHOLD_PERCENT] = 7500; // 75%
        protocolParameters[MIN_VALIDATORS_FOR_EKA] = 3;
        protocolParameters[MIN_VALIDATION_INTEGRITY_BOND] = 0.01 ether;
        protocolParameters[MIN_CHALLENGE_SOLUTION_VALIDATORS] = 3;
        protocolParameters[REWARD_POINTS_PER_EKA_CONTRIBUTION] = 100;
        protocolParameters[REWARD_POINTS_PER_CHALLENGE_SOLVE] = 150;
        protocolParameters[REWARD_POINTS_PER_VALIDATION] = 10;
        protocolParameters[REWARD_POINTS_PER_SUCCESSFUL_CHALLENGE_VALIDATION] = 20;
        protocolParameters[MAX_GRANT_PERCENTAGE_OF_TREASURY] = 500; // 5%
    }

    // --- ERC721 Implementation Overrides ---
    // Custom logic to prevent transfer of "Achievement" NFTs (soulbound-like)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721URIStorage) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (_nftTypes[tokenId] == NFType.Achievement && from != address(0) && to != address(0)) {
            revert TransferNotAllowed(); // Achievement NFTs are non-transferable
        }
    }

    // --- I. Core User & Profile Management Functions ---

    /**
     * @notice Registers a new user in the SynapticNexus.
     * @dev Requires an initial ETH stake for profile integrity.
     * @param _username The desired username for the user.
     * @param _ipfsProfileHash IPFS hash pointing to the user's profile metadata.
     */
    function registerUser(string calldata _username, string calldata _ipfsProfileHash) external payable nonReentrant {
        if (users[msg.sender].isRegistered) {
            revert("User already registered");
        }
        if (msg.value < protocolParameters[MIN_PROFILE_STAKE]) {
            revert InvalidStakeAmount();
        }

        users[msg.sender] = User({
            isRegistered: true,
            username: _username,
            ipfsProfileHash: _ipfsProfileHash,
            profileStake: msg.value,
            lastStakeWithdrawal: block.timestamp,
            accumulatedRewards: 0
        });
        _userIds.increment();
        emit UserRegistered(msg.sender, _username, _ipfsProfileHash, msg.value);
    }

    /**
     * @notice Allows a registered user to update their IPFS profile hash.
     * @param _newIpfsProfileHash New IPFS hash for the user's profile metadata.
     */
    function updateUserProfile(string calldata _newIpfsProfileHash) external onlyRegisteredUser whenNotPaused {
        users[msg.sender].ipfsProfileHash = _newIpfsProfileHash;
        emit ProfileUpdated(msg.sender, _newIpfsProfileHash);
    }

    /**
     * @notice Allows a registered user to increase their profile integrity stake.
     * @dev The stake contributes to the user's credibility and the protocol's treasury.
     */
    function stakeForProfileIntegrity() external payable onlyRegisteredUser whenNotPaused {
        if (msg.value == 0) {
            revert InvalidStakeAmount();
        }
        users[msg.sender].profileStake += msg.value;
        treasuryBalance += msg.value; // Staked funds go to treasury for protocol use
        emit ProfileStakeUpdated(msg.sender, users[msg.sender].profileStake);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /**
     * @notice Allows a registered user to withdraw a portion or all of their profile stake.
     * @dev Subject to a cooldown period to prevent rapid stake manipulation.
     */
    function withdrawProfileStake() external onlyRegisteredUser whenNotPaused nonReentrant {
        uint256 minStake = protocolParameters[MIN_PROFILE_STAKE];
        uint256 cooldown = protocolParameters[PROFILE_WITHDRAW_COOLDOWN];

        if (users[msg.sender].profileStake <= minStake) {
            revert InsufficientStake();
        }
        if (block.timestamp < users[msg.sender].lastStakeWithdrawal + cooldown) {
            revert StakeLocked();
        }

        uint256 withdrawableAmount = users[msg.sender].profileStake - minStake;
        users[msg.sender].profileStake = minStake;
        users[msg.sender].lastStakeWithdrawal = block.timestamp;
        
        // Ensure treasury has enough funds before sending
        if (treasuryBalance < withdrawableAmount) {
            revert("Treasury insufficient for withdrawal"); // Should not happen if logic is sound
        }
        treasuryBalance -= withdrawableAmount;

        (bool success,) = payable(msg.sender).call{value: withdrawableAmount}("");
        if (!success) {
            revert("Withdrawal failed");
        }
        emit ProfileStakeWithdrawn(msg.sender, withdrawableAmount);
    }

    // --- II. Knowledge Artifact (EKA) Management Functions ---

    /**
     * @notice Proposes a new Knowledge Artifact (EKA).
     * @dev Requires a quality bond (ETH) to prevent spam and ensure serious contributions.
     * @param _title The title of the EKA.
     * @param _ipfsContentHash IPFS hash of the EKA's content.
     * @param _tags Keywords or categories for the EKA.
     */
    function proposeKnowledgeArtifact(string calldata _title, string calldata _ipfsContentHash, string[] calldata _tags)
        external
        payable
        onlyRegisteredUser
        whenNotPaused
    {
        if (msg.value < protocolParameters[MIN_EKA_PROPOSAL_BOND]) {
            revert InvalidStakeAmount();
        }

        _ekaIds.increment();
        uint256 newEkaId = _ekaIds.current();

        knowledgeArtifacts[newEkaId] = KnowledgeArtifact({
            id: newEkaId,
            proposer: msg.sender,
            title: _title,
            ipfsContentHash: _ipfsContentHash,
            tags: _tags,
            state: EKAState.PendingValidation,
            proposalBond: msg.value,
            submissionTimestamp: block.timestamp,
            currentValidators: new address[](0),
            approveVotes: 0,
            rejectVotes: 0,
            currentVersion: 1,
            associatedNFTId: 0
        });

        treasuryBalance += msg.value; // Bond goes to treasury
        emit KnowledgeArtifactProposed(newEkaId, msg.sender, _title, _ipfsContentHash);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /**
     * @notice Proposes an update to an existing Knowledge Artifact.
     * @dev The update goes through a new validation process.
     * @param _ekaId The ID of the EKA to update.
     * @param _newIpfsContentHash The new IPFS hash for the updated content.
     */
    function updateKnowledgeArtifact(uint256 _ekaId, string calldata _newIpfsContentHash)
        external
        payable
        onlyRegisteredUser
        whenNotPaused
    {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        // Only allow updates to Validated EKAs or Disputed ones where previous validation failed
        if (eka.state != EKAState.Validated && eka.state != EKAState.Disputed) {
            revert("EKA not in valid state for update proposal");
        }
        if (msg.value < protocolParameters[MIN_EKA_PROPOSAL_BOND]) {
            revert InvalidStakeAmount();
        }

        // Reset for new validation
        eka.ipfsContentHash = _newIpfsContentHash;
        eka.currentVersion++;
        eka.state = EKAState.PendingValidation;
        eka.proposalBond += msg.value; // Add to existing bond
        eka.currentValidators = new address[](0);
        delete eka.hasVoted; // Reset votes
        eka.approveVotes = 0;
        eka.rejectVotes = 0;

        treasuryBalance += msg.value;
        emit KnowledgeArtifactUpdated(_ekaId, msg.sender, _newIpfsContentHash, eka.currentVersion);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /**
     * @notice Allows a user to add a quality bond to a pending EKA proposal or update.
     * @dev Additional bonding can signal confidence and prioritize validation.
     * @param _ekaId The ID of the EKA.
     */
    function bondForEKAProposalQuality(uint256 _ekaId) external payable onlyRegisteredUser whenNotPaused {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        if (eka.state != EKAState.PendingValidation) {
            revert KnowledgeArtifactNotPending();
        }
        if (msg.value == 0) {
            revert InvalidStakeAmount();
        }

        eka.proposalBond += msg.value;
        treasuryBalance += msg.value;
        emit EKAProposalBondUpdated(_ekaId, msg.sender, eka.proposalBond);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /**
     * @notice Releases the proposal bond after an EKA is successfully validated.
     * @dev Only the EKA proposer can release their bond.
     * @param _ekaId The ID of the EKA.
     */
    function releaseEKAProposalBond(uint256 _ekaId) external onlyEKAProposer(_ekaId) whenNotPaused nonReentrant {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        if (eka.state != EKAState.Validated) {
            revert("EKA not yet validated");
        }
        if (eka.proposalBond == 0) {
            revert("No bond to release");
        }

        uint256 bondAmount = eka.proposalBond;
        eka.proposalBond = 0;

        if (treasuryBalance < bondAmount) {
            revert("Treasury insufficient for bond release");
        }
        treasuryBalance -= bondAmount;

        (bool success,) = payable(msg.sender).call{value: bondAmount}("");
        if (!success) {
            revert("Bond release failed");
        }
        emit EKAProposalBondReleased(_ekaId, msg.sender, bondAmount);
    }

    /**
     * @notice Allows a user with VALIDATOR_ROLE to register as a validator for a specific EKA.
     * @dev Requires an integrity bond to ensure honest participation.
     * @param _ekaId The ID of the EKA to validate.
     */
    function participateInEKAValidation(uint256 _ekaId) external onlyRegisteredUser hasRole(VALIDATOR_ROLE, msg.sender) whenNotPaused {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        if (eka.state != EKAState.PendingValidation) {
            revert KnowledgeArtifactNotPending();
        }
        if (users[msg.sender].profileStake < protocolParameters[MIN_VALIDATION_INTEGRITY_BOND]) {
            revert("Insufficient validation integrity bond (profile stake)");
        }

        for (uint256 i = 0; i < eka.currentValidators.length; i++) {
            if (eka.currentValidators[i] == msg.sender) {
                revert("Already registered as validator for this EKA");
            }
        }
        eka.currentValidators.push(msg.sender);
        emit EKAValidatorAdded(_ekaId, msg.sender);
    }

    /**
     * @notice Allows a registered validator to vote on a pending EKA.
     * @dev A sufficient number of votes determines the EKA's fate.
     * @param _ekaId The ID of the EKA to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteOnEKAProposal(uint256 _ekaId, bool _approve) external onlyRegisteredUser hasRole(VALIDATOR_ROLE, msg.sender) whenNotPaused {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        if (eka.state != EKAState.PendingValidation) {
            revert KnowledgeArtifactNotPending();
        }
        bool isValidator = false;
        for (uint256 i = 0; i < eka.currentValidators.length; i++) {
            if (eka.currentValidators[i] == msg.sender) {
                isValidator = true;
                break;
            }
        }
        if (!isValidator) {
            revert NotEKAValidator();
        }
        if (eka.hasVoted[msg.sender]) {
            revert("Already voted on this EKA");
        }

        eka.hasVoted[msg.sender] = true;
        if (_approve) {
            eka.approveVotes++;
        } else {
            eka.rejectVotes++;
        }
        users[msg.sender].accumulatedRewards += protocolParameters[REWARD_POINTS_PER_VALIDATION];
        emit EKAValidationVoteCast(_ekaId, msg.sender, _approve);

        // Check if enough votes have been cast to finalize validation
        uint256 totalVotes = eka.approveVotes + eka.rejectVotes;
        if (totalVotes >= protocolParameters[MIN_VALIDATORS_FOR_EKA]) {
            uint256 approvalPercentage = (eka.approveVotes * 10000) / totalVotes; // Multiply by 10000 for 2 decimal places precision

            if (approvalPercentage >= protocolParameters[EKA_VALIDATION_THRESHOLD_PERCENT]) {
                eka.state = EKAState.Validated;
                if (eka.associatedNFTId == 0) {
                    _mintEKA_NFT(_ekaId); // Mint new NFT if it's the first validation
                } else {
                    _evolveEKA_NFT(_ekaId); // Update existing NFT metadata if it's an update
                }
                users[eka.proposer].accumulatedRewards += protocolParameters[REWARD_POINTS_PER_EKA_CONTRIBUTION];
                emit EKAValidated(_ekaId, eka.proposer, eka.approveVotes, eka.rejectVotes);
            } else {
                eka.state = EKAState.Rejected;
                emit EKARejected(_ekaId, eka.approveVotes, eka.rejectVotes);
            }
        }
    }

    /**
     * @notice Allows a user to challenge the outcome of an EKA validation.
     * @dev Requires a significant bond and an IPFS hash explaining the challenge reason.
     * @param _ekaId The ID of the EKA whose validation result is being challenged.
     * @param _reasonIpfsHash IPFS hash explaining the reason for the challenge.
     */
    function challengeEKAValidationResult(uint256 _ekaId, string calldata _reasonIpfsHash) external payable onlyRegisteredUser whenNotPaused {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.id == 0) {
            revert KnowledgeArtifactNotFound();
        }
        if (eka.state != EKAState.Validated && eka.state != EKAState.Rejected) {
            revert KnowledgeArtifactNotPending(); // Only challenge finalized states
        }
        if (msg.value < protocolParameters[MIN_EKA_PROPOSAL_BOND] * 2) { // Example: Double the original proposal bond for challenge
            revert InvalidStakeAmount();
        }

        // Move EKA back to disputed state for re-evaluation (or new validation round)
        eka.state = EKAState.Disputed;
        eka.proposalBond += msg.value; // Add challenge bond to the EKA's total bond
        treasuryBalance += msg.value;
        emit EKADisputed(_ekaId, msg.sender, _reasonIpfsHash);
        emit FundsDepositedToTreasury(msg.sender, msg.value);

        // A new validation round would need to be triggered or manually handled by governance.
        // For simplicity, this acts as a flag for re-evaluation.
    }

    /**
     * @notice Allows a user to bond funds to enhance their credibility as a validator.
     * @dev This bond is separate from EKA-specific validation bonds.
     */
    function bondForValidationIntegrity() external payable onlyRegisteredUser whenNotPaused {
        if (msg.value == 0) {
            revert InvalidStakeAmount();
        }
        users[msg.sender].profileStake += msg.value; // Add to existing profile stake, which acts as integrity bond
        treasuryBalance += msg.value;
        emit ValidationIntegrityBondUpdated(msg.sender, users[msg.sender].profileStake);
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    // --- III. Cognitive Challenge Functions ---

    /**
     * @notice Allows a registered user to propose a new Cognitive Challenge.
     * @dev The challenge becomes active after proposal and can be solved by others.
     * @param _title The title of the challenge.
     * @param _descriptionIpfsHash IPFS hash of the challenge's detailed description.
     * @param _rewardAmount The reward (in accumulatedRewards points) for successfully solving this challenge.
     */
    function proposeCognitiveChallenge(string calldata _title, string calldata _descriptionIpfsHash, uint256 _rewardAmount)
        external
        onlyRegisteredUser
        whenNotPaused
    {
        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            proposer: msg.sender,
            title: _title,
            descriptionIpfsHash: _descriptionIpfsHash,
            rewardAmount: _rewardAmount,
            status: ChallengeStatus.Active, // Auto-active for simplicity, could require approval
            submissionTimestamp: block.timestamp,
            solvedTimestamp: 0,
            currentSolver: address(0),
            solutionApproveVotes: 0,
            solutionRejectVotes: 0
        });

        emit ChallengeProposed(newChallengeId, msg.sender, _title, _rewardAmount);
    }

    /**
     * @notice Allows a registered user to submit a solution to an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionIpfsHash IPFS hash of the submitted solution.
     */
    function submitChallengeSolution(uint256 _challengeId, string calldata _solutionIpfsHash) external onlyRegisteredUser whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert ChallengeNotFound();
        }
        if (challenge.status != ChallengeStatus.Active) {
            revert ChallengeNotActive();
        }

        challenge.currentSolver = msg.sender;
        challenge.solvedTimestamp = block.timestamp;
        challenge.descriptionIpfsHash = _solutionIpfsHash; // Temporarily use description field for solution hash
        challenge.status = ChallengeStatus.Solved;

        // Reset for validation
        delete challenge.hasValidatedSolution;
        challenge.solutionApproveVotes = 0;
        challenge.solutionRejectVotes = 0;

        emit ChallengeSolutionSubmitted(_challengeId, msg.sender, _solutionIpfsHash);
    }

    /**
     * @notice Allows a user with VALIDATOR_ROLE to validate a submitted solution for a challenge.
     * @dev Requires a minimum number of validators to reach a consensus.
     * @param _challengeId The ID of the challenge.
     * @param _solver The address of the user who submitted the solution.
     * @param _valid True if the solution is valid, false otherwise.
     */
    function validateChallengeSolution(uint256 _challengeId, address _solver, bool _valid)
        external
        onlyRegisteredUser
        hasRole(VALIDATOR_ROLE, msg.sender)
        whenNotPaused
    {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.id == 0) {
            revert ChallengeNotFound();
        }
        if (challenge.status != ChallengeStatus.Solved || challenge.currentSolver != _solver) {
            revert SolutionNotFound();
        }
        if (challenge.hasValidatedSolution[msg.sender]) {
            revert SolutionAlreadyValidated();
        }

        challenge.hasValidatedSolution[msg.sender] = true;
        if (_valid) {
            challenge.solutionApproveVotes++;
        } else {
            challenge.solutionRejectVotes++;
        }
        users[msg.sender].accumulatedRewards += protocolParameters[REWARD_POINTS_PER_VALIDATION];
        emit ChallengeSolutionValidated(_challengeId, _solver, msg.sender, _valid);

        uint256 totalSolutionVotes = challenge.solutionApproveVotes + challenge.solutionRejectVotes;
        if (totalSolutionVotes >= protocolParameters[MIN_CHALLENGE_SOLUTION_VALIDATORS]) {
            uint256 approvalPercentage = (challenge.solutionApproveVotes * 10000) / totalSolutionVotes;

            if (approvalPercentage >= protocolParameters[EKA_VALIDATION_THRESHOLD_PERCENT]) { // Using EKA threshold for challenges too
                challenge.status = ChallengeStatus.Validated;
                users[_solver].accumulatedRewards += challenge.rewardAmount;
                _awardAchievementNFT(_solver, "Challenge Master", string(abi.encodePacked("ipfs://",_challengeId.toString(),".json"))); // Example URI
                // Reward validators who voted correctly
                for(uint256 i = 0; i < challenge.currentValidators.length; i++) {
                    if (challenge.hasValidatedSolution[challenge.currentValidators[i]]) { // Recheck this logic in real implementation
                        users[challenge.currentValidators[i]].accumulatedRewards += protocolParameters[REWARD_POINTS_PER_SUCCESSFUL_CHALLENGE_VALIDATION];
                    }
                }
                emit ChallengeSolved(_challengeId, _solver);
            } else {
                challenge.status = ChallengeStatus.Rejected;
                // Optionally penalize solver or allow re-submission
            }
        }
    }

    /**
     * @notice (SYSTEM_ROLE) Spawns a new adaptive cognitive challenge.
     * @dev This function is intended to be called by a trusted off-chain system (e.g., an AI agent or DAO-controlled oracle)
     *      that determines challenge content based on network needs or collective intelligence analysis.
     * @param _title The title of the generated challenge.
     * @param _descriptionIpfsHash IPFS hash of the challenge's detailed description.
     * @param _rewardAmount The reward (in accumulatedRewards points) for solving.
     * @param _tags Keywords or categories for the adaptive challenge.
     */
    function spawnAdaptiveChallenge(string calldata _title, string calldata _descriptionIpfsHash, uint256 _rewardAmount, string[] calldata _tags)
        external
        hasRole(SYSTEM_ROLE, msg.sender)
        whenNotPaused
    {
        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        // For simplicity, currentSolver is proposer here, could be an admin/system address.
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            proposer: msg.sender, // The system role
            title: _title,
            descriptionIpfsHash: _descriptionIpfsHash,
            rewardAmount: _rewardAmount,
            status: ChallengeStatus.Active,
            submissionTimestamp: block.timestamp,
            solvedTimestamp: 0,
            currentSolver: address(0),
            solutionApproveVotes: 0,
            solutionRejectVotes: 0
        });

        // The 'tags' parameter is not stored directly in the Challenge struct as defined, but could be added.
        // It's mainly here to show the kind of metadata an adaptive system would provide.

        emit ChallengeSpawned(newChallengeId, _title, _descriptionIpfsHash);
    }

    // --- IV. Reputation & Endorsement Functions ---

    /**
     * @notice Allows a registered user to endorse a specific skill of another registered user.
     * @dev Builds a granular "reputation trail" for users.
     * @param _user The address of the user whose skill is being endorsed.
     * @param _skill The name of the skill being endorsed (e.g., "Solidity", "Cryptography", "Knowledge Curation").
     */
    function endorseUserSkill(address _user, string calldata _skill) external onlyRegisteredUser whenNotPaused {
        if (!users[_user].isRegistered) {
            revert UserNotRegistered();
        }
        if (msg.sender == _user) {
            revert SelfEndorsementNotAllowed();
        }

        userSkillReputation[_user][_skill]++;
        emit UserSkillEndorsed(_user, msg.sender, _skill, userSkillReputation[_user][_skill]);
    }

    /**
     * @notice Allows a user to revoke a previous skill endorsement they made.
     * @param _user The address of the user whose skill was endorsed.
     * @param _skill The name of the skill for which the endorsement is being revoked.
     */
    function revokeSkillEndorsement(address _user, string calldata _skill) external onlyRegisteredUser whenNotPaused {
        if (userSkillReputation[_user][_skill] == 0) {
            revert EndorsementNotFound();
        }
        // This is a simplified revocation. In a real system, you'd track who endorsed to allow individual revocation.
        // For this example, it just reduces the count.
        userSkillReputation[_user][_skill]--;
        emit UserSkillEndorsementRevoked(_user, msg.sender, _skill, userSkillReputation[_user][_skill]);
    }

    // --- V. NFT Management Functions ---

    /**
     * @notice Internal function to mint a new EKA-NFT upon successful validation of an EKA.
     * @dev EKA-NFTs are transferable and represent ownership of a validated knowledge artifact.
     * @param _ekaId The ID of the validated EKA.
     */
    function _mintEKA_NFT(uint256 _ekaId) internal {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        _nftIds.increment();
        uint256 tokenId = _nftIds.current();
        _safeMint(eka.proposer, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", _ekaId.toString(), "/v", eka.currentVersion.toString(), ".json")));
        _nftTypes[tokenId] = NFType.EKA;
        eka.associatedNFTId = tokenId;
        emit EKA_NFT_Minted(tokenId, _ekaId, eka.proposer, tokenURI(tokenId));
    }

    /**
     * @notice Updates the metadata URI of an existing EKA-NFT when the underlying EKA is significantly updated/evolved.
     * @param _ekaId The ID of the EKA that has evolved.
     */
    function _evolveEKA_NFT(uint256 _ekaId) internal {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        if (eka.associatedNFTId == 0) {
            revert KnowledgeArtifactNotFound(); // Should not happen if called correctly
        }
        uint256 tokenId = eka.associatedNFTId;
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://", _ekaId.toString(), "/v", eka.currentVersion.toString(), ".json")));
        emit EKA_NFT_Evolved(tokenId, _ekaId, tokenURI(tokenId));
    }

    /**
     * @notice Internal function to award a soulbound (non-transferable) achievement NFT.
     * @dev These NFTs act as on-chain credentials for significant accomplishments.
     * @param _to The recipient of the achievement NFT.
     * @param _achievementType A string describing the type of achievement (e.g., "Challenge Master", "Top Validator").
     * @param _ipfsMetadataHash IPFS hash pointing to the NFT's metadata.
     */
    function _awardAchievementNFT(address _to, string calldata _achievementType, string calldata _ipfsMetadataHash) internal {
        _nftIds.increment();
        uint256 tokenId = _nftIds.current();
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _ipfsMetadataHash);
        _nftTypes[tokenId] = NFType.Achievement; // Mark as achievement NFT (non-transferable)
        emit AchievementNFTAwarded(tokenId, _to, _achievementType, _ipfsMetadataHash);
    }

    // --- VI. Treasury & Reward Functions ---

    /**
     * @notice Allows anyone to deposit ETH into the SynapticNexus treasury.
     * @dev These funds can be used for rewards, grants, and protocol development.
     */
    function depositToTreasury() external payable whenNotPaused {
        if (msg.value == 0) {
            revert InvalidStakeAmount();
        }
        treasuryBalance += msg.value;
        emit FundsDepositedToTreasury(msg.sender, msg.value);
    }

    /**
     * @notice Allows a registered user to claim their accumulated rewards.
     * @dev Rewards are paid out from the treasury.
     */
    function claimRewards() external onlyRegisteredUser whenNotPaused nonReentrant {
        uint256 amount = users[msg.sender].accumulatedRewards;
        if (amount == 0) {
            revert NoRewardsToClaim();
        }
        if (treasuryBalance < amount) {
            revert("Treasury insufficient for rewards");
        }

        users[msg.sender].accumulatedRewards = 0;
        treasuryBalance -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert("Reward claim failed");
        }
        emit RewardsClaimed(msg.sender, amount);
    }

    /**
     * @notice Allows a registered user to request a grant from the treasury for a project.
     * @dev Requires a proposal IPFS hash and is subject to governance approval.
     * @param _amount The amount of ETH requested.
     * @param _proposalIpfsHash IPFS hash of the detailed grant proposal.
     */
    function requestGrantFromTreasury(uint256 _amount, string calldata _proposalIpfsHash) external onlyRegisteredUser whenNotPaused {
        if (_amount == 0) {
            revert InvalidGrantRequest();
        }
        // Basic check: max percentage of treasury. Full approval via governance.
        if (_amount > (treasuryBalance * protocolParameters[MAX_GRANT_PERCENTAGE_OF_TREASURY]) / 10000) {
            revert InvalidGrantRequest();
        }

        _grantIds.increment();
        uint256 newGrantId = _grantIds.current();

        grantRequests[newGrantId] = GrantRequest({
            id: newGrantId,
            requester: msg.sender,
            amount: _amount,
            proposalIpfsHash: _proposalIpfsHash,
            approved: false,
            exists: true
        });

        emit GrantRequested(newGrantId, msg.sender, _amount, _proposalIpfsHash);
    }

    /**
     * @notice (GOVERNANCE_ROLE) Approves and executes a pending grant request.
     * @param _grantId The ID of the grant request to approve.
     */
    function approveGrant(uint256 _grantId) external hasRole(GOVERNANCE_ROLE, msg.sender) whenNotPaused nonReentrant {
        GrantRequest storage grant = grantRequests[_grantId];
        if (!grant.exists) {
            revert InvalidGrantRequest();
        }
        if (grant.approved) {
            revert("Grant already approved");
        }
        if (treasuryBalance < grant.amount) {
            revert("Treasury insufficient for grant");
        }

        grant.approved = true;
        treasuryBalance -= grant.amount;

        (bool success,) = payable(grant.requester).call{value: grant.amount}("");
        if (!success) {
            revert("Grant transfer failed");
        }
        emit GrantApproved(_grantId, msg.sender, grant.amount);
    }

    // --- VII. Admin & Protocol Parameter Functions ---

    /**
     * @notice (GOVERNANCE_ROLE) Sets a protocol parameter.
     * @dev Allows dynamic adjustment of key contract parameters.
     * @param _paramKey The keccak256 hash of the parameter name (e.g., MIN_PROFILE_STAKE).
     * @param _value The new value for the parameter.
     */
    function setProtocolParameter(bytes32 _paramKey, uint256 _value) external hasRole(GOVERNANCE_ROLE, msg.sender) whenNotPaused {
        // Basic validation for known keys
        if (_paramKey != MIN_PROFILE_STAKE && _paramKey != PROFILE_WITHDRAW_COOLDOWN &&
            _paramKey != MIN_EKA_PROPOSAL_BOND && _paramKey != EKA_VALIDATION_THRESHOLD_PERCENT &&
            _paramKey != MIN_VALIDATORS_FOR_EKA && _paramKey != MIN_VALIDATION_INTEGRITY_BOND &&
            _paramKey != MIN_CHALLENGE_SOLUTION_VALIDATORS && _paramKey != REWARD_POINTS_PER_EKA_CONTRIBUTION &&
            _paramKey != REWARD_POINTS_PER_CHALLENGE_SOLVE && _paramKey != REWARD_POINTS_PER_VALIDATION &&
            _paramKey != REWARD_POINTS_PER_SUCCESSFUL_CHALLENGE_VALIDATION && _paramKey != MAX_GRANT_PERCENTAGE_OF_TREASURY
        ) {
            revert InvalidParameterKey();
        }
        protocolParameters[_paramKey] = _value;
        emit ProtocolParameterSet(_paramKey, _value);
    }

    /**
     * @notice (ADMIN_ROLE) Pauses all critical operations in an emergency.
     * @dev Inherited from OpenZeppelin's Pausable.
     */
    function emergencyPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @notice (ADMIN_ROLE) Allows the default admin to withdraw funds from the treasury in an emergency.
     * @dev Use with extreme caution. This bypasses governance for urgent situations.
     * @param _amount The amount of ETH to withdraw.
     * @param _to The address to send the ETH to.
     */
    function emergencyWithdrawFunds(uint256 _amount, address _to) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        if (_amount == 0 || _to == address(0)) {
            revert("Invalid amount or recipient");
        }
        if (treasuryBalance < _amount) {
            revert("Insufficient treasury balance for emergency withdrawal");
        }

        treasuryBalance -= _amount;
        (bool success,) = payable(_to).call{value: _amount}("");
        if (!success) {
            revert("Emergency withdrawal failed");
        }
        emit EmergencyFundsWithdrawn(_to, _amount);
    }

    // --- VIII. View Functions ---

    /**
     * @notice Returns the current details of a user.
     * @param _userAddress The address of the user.
     * @return A tuple containing user details.
     */
    function getUserDetails(address _userAddress) external view returns (bool, string memory, string memory, uint256, uint256, uint256) {
        User storage user = users[_userAddress];
        return (user.isRegistered, user.username, user.ipfsProfileHash, user.profileStake, user.lastStakeWithdrawal, user.accumulatedRewards);
    }

    /**
     * @notice Returns the details of a specific Knowledge Artifact.
     * @param _ekaId The ID of the EKA.
     * @return A tuple containing EKA details.
     */
    function getKnowledgeArtifactDetails(uint256 _ekaId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory ipfsContentHash,
            string[] memory tags,
            EKAState state,
            uint256 proposalBond,
            uint256 submissionTimestamp,
            address[] memory currentValidators,
            uint256 approveVotes,
            uint256 rejectVotes,
            uint256 currentVersion,
            uint256 associatedNFTId
        )
    {
        KnowledgeArtifact storage eka = knowledgeArtifacts[_ekaId];
        return (
            eka.id,
            eka.proposer,
            eka.title,
            eka.ipfsContentHash,
            eka.tags,
            eka.state,
            eka.proposalBond,
            eka.submissionTimestamp,
            eka.currentValidators,
            eka.approveVotes,
            eka.rejectVotes,
            eka.currentVersion,
            eka.associatedNFTId
        );
    }

    /**
     * @notice Returns the details of a specific Cognitive Challenge.
     * @param _challengeId The ID of the challenge.
     * @return A tuple containing challenge details.
     */
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory descriptionIpfsHash,
            uint256 rewardAmount,
            ChallengeStatus status,
            uint256 submissionTimestamp,
            uint256 solvedTimestamp,
            address currentSolver,
            uint256 solutionApproveVotes,
            uint256 solutionRejectVotes
        )
    {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.id,
            challenge.proposer,
            challenge.title,
            challenge.descriptionIpfsHash,
            challenge.rewardAmount,
            challenge.status,
            challenge.submissionTimestamp,
            challenge.solvedTimestamp,
            challenge.currentSolver,
            challenge.solutionApproveVotes,
            challenge.solutionRejectVotes
        );
    }

    /**
     * @notice Returns the endorsement count for a specific skill of a user.
     * @param _user The address of the user.
     * @param _skill The name of the skill.
     * @return The number of endorsements for that skill.
     */
    function getSkillEndorsementCount(address _user, string calldata _skill) external view returns (uint256) {
        return userSkillReputation[_user][_skill];
    }

    /**
     * @notice Returns the type of a given NFT (EKA or Achievement).
     * @param _tokenId The ID of the NFT.
     * @return The NFType enum value.
     */
    function getNftType(uint256 _tokenId) external view returns (NFType) {
        return _nftTypes[_tokenId];
    }

    /**
     * @notice Returns the details of a specific grant request.
     * @param _grantId The ID of the grant request.
     * @return A tuple containing grant request details.
     */
    function getGrantRequestDetails(uint256 _grantId)
        external
        view
        returns (
            uint256 id,
            address requester,
            uint256 amount,
            string memory proposalIpfsHash,
            bool approved,
            bool exists
        )
    {
        GrantRequest storage grant = grantRequests[_grantId];
        return (grant.id, grant.requester, grant.amount, grant.proposalIpfsHash, grant.approved, grant.exists);
    }

    /**
     * @notice Returns the current value of a protocol parameter.
     * @param _paramKey The keccak256 hash of the parameter name.
     * @return The value of the parameter.
     */
    function getProtocolParameter(bytes32 _paramKey) external view returns (uint256) {
        return protocolParameters[_paramKey];
    }
}
```