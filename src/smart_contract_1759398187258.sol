This smart contract, **ADSCN (Adaptive Decentralized Skill & Contribution Network)**, aims to create a self-organizing ecosystem for talent and project execution. It integrates several advanced and trendy concepts:

1.  **Soulbound Tokens (SBTs):** Used for non-transferable proof of skills and project achievements, forming a decentralized identity and verifiable credential system.
2.  **Dynamic On-Chain Reputation:** Contributors earn or lose reputation based on successful project completions, community validation, and dispute outcomes.
3.  **Reputation Delegation:** Allows contributors to delegate a portion of their reputation score for specific tasks or votes, enabling nuanced influence without transferring the core identity.
4.  **Decentralized Project Lifecycle:** A structured process for proposing, funding, assigning, reviewing, and completing projects, tying into skill verification.
5.  **Dispute Resolution:** Mechanisms for challenging skill verifications, reputation scores, and project outcomes, ensuring protocol integrity.
6.  **AI-Oracle Integration (Conceptual):** Functions for requesting external AI assistance, such as matching contributors to projects based on their verified skills and reputation.
7.  **SBT Staking:** A novel concept where contributors can lock their Skill SBTs for a duration to gain enhanced protocol benefits (e.g., higher priority for tasks, boosted voting power).
8.  **On-Chain Governance:** A framework for proposing and executing protocol upgrades or parameter changes.

---

### Contract Outline:

**I. Core Infrastructure & Roles:**
    - `AccessControl` for managing `ADMIN_ROLE`, `GUARDIAN_ROLE`, `VERIFIER_ROLE`, `ORACLE_ROLE`.
    - Global parameters like `protocolFeeBps`, `oracleAddress`.
    - Internal counters for managing IDs.

**II. Soulbound Token (SBT) Management:**
    - `SkillSBT`: An ERC721 contract for non-transferable skill verifications.
    - `AchievementSBT`: An ERC721 contract for non-transferable project completion proofs.
    - Functions for proposing skill claims, having them verified, and minting/revoking skill SBTs.
    - Functions for minting achievement SBTs upon project completion.

**III. Dynamic Reputation System:**
    - `reputations`: A mapping storing `int256` reputation scores for contributors.
    - `updateContributorReputation`: Internal function to adjust reputation.
    - `delegateReputationScore`: Allows a contributor to delegate a percentage of their reputation.
    - `challengeReputationScore`: Initiates a dispute over another contributor's reputation.

**IV. Project & Task Management:**
    - `projects`: Structs holding project details (status, funding, rewards, contributors, deliverables).
    - `skillCategories`: Structs defining categories for skills.
    - Functions for creating projects, funding them, assigning contributors based on skills, submitting deliverables, and reviewing work.
    - `completeProjectAndDistributeRewards`: Finalizes projects, distributes funds, and triggers achievement SBT minting and reputation updates.

**V. Governance & Protocol Evolution:**
    - `SkillVerificationProposal`: Struct for tracking skill verification requests.
    - `GovernanceProposal`: Struct for protocol-level changes.
    - `Dispute`: Struct for tracking challenges related to skills, reputation, or projects.
    - Functions for proposing skill verifications, governance changes, and managing votes/approvals.
    - `resolveDispute`: A generalized function to handle outcomes of various disputes.

**VI. Oracle Integration (Conceptual):**
    - `requestDynamicTaskMatch`: Simulates an interaction with an external AI oracle for contributor matching.
    - `updateOracleAddress`: To manage the trusted oracle address.

**VII. Advanced SBT Utility:**
    - `lockedSBTs`: Mapping to track staked Skill SBTs.
    - `lockSBTForStaking`: Allows contributors to stake their Skill SBTs.
    - `claimSBTStakingRewards`: (Conceptual) Allows claiming benefits from staked SBTs.

---

### Function Summary:

1.  `constructor()`: Initializes the contract, sets the deployer as `ADMIN_ROLE`, and grants initial roles.
2.  `updateProtocolFee(uint256 _newFeeBps)`: Sets the protocol fee percentage collected on project rewards.
3.  `updateGuardian(address _newGuardian)`: Designates or changes the `GUARDIAN_ROLE` for emergency actions.
4.  `updateOracleAddress(address _newOracleAddress)`: Sets the trusted `ORACLE_ROLE` address for external data queries.
5.  `registerSkillCategory(string memory _name, string memory _description)`: Defines a new category for skills, e.g., "Frontend Development", "Solidity".
6.  `proposeSkillVerification(uint256 _skillCategoryId, string memory _proofCid)`: A user proposes that they possess a skill, providing an IPFS CID to off-chain proof.
7.  `approveSkillVerificationByVerifier(uint256 _proposalId, bool _approve)`: A member of the `VERIFIER_ROLE` approves or rejects a skill verification proposal.
8.  `claimSkillSBT(uint256 _proposalId)`: Allows a contributor whose skill verification proposal was approved to mint their Skill SBT.
9.  `revokeSkillSBT(address _contributor, uint256 _skillCategoryId, string memory _reasonCid)`: An `ADMIN_ROLE` or `GUARDIAN_ROLE` can revoke a Skill SBT, potentially due to fraud.
10. `proposeProject(string memory _name, string memory _descriptionCid, uint256 _rewardAmount, uint256[] memory _requiredSkillCategoryIds, uint256 _bountyDuration)`: Creates a new project proposal, specifying required skills, reward, and duration.
11. `fundProject(uint256 _projectId)`: Allows users to contribute funding (in native currency, i.e., ETH/MATIC) to a proposed project.
12. `assignProjectContributor(uint256 _projectId, address _contributor)`: The project owner assigns a contributor, checking if they hold the necessary Skill SBTs.
13. `submitProjectDeliverable(uint256 _projectId, string memory _deliverableCid)`: An assigned contributor submits their work, providing an IPFS CID to the deliverable.
14. `reviewProjectDeliverable(uint256 _projectId, address _contributor, bool _approved)`: The project owner or designated reviewer assesses the submitted deliverable.
15. `setProjectReviewer(uint256 _projectId, address _reviewer, bool _canReview)`: The project owner can designate other addresses to assist with reviewing project deliverables.
16. `completeProjectAndDistributeRewards(uint256 _projectId)`: Finalizes a project, distributes rewards to approved contributors, collects fees, and triggers reputation updates.
17. `claimAchievementSBT(uint256 _projectId, address _contributor)`: A contributor who successfully completed a project can mint their Achievement SBT.
18. `delegateReputationScore(address _delegatee, uint256 _percentage)`: Allows a contributor to temporarily delegate a percentage of their reputation score to another address.
19. `challengeReputationScore(address _contributorToChallenge, string memory _reasonCid)`: Initiates a formal dispute over another contributor's reputation, requiring a bond.
20. `initiateProjectDispute(uint256 _projectId, string memory _reasonCid)`: Opens a dispute regarding a project's completion, rewards, or review outcome.
21. `resolveDispute(uint256 _disputeId, bool _isSkillDispute, bool _resolutionOutcome, int256 _reputationAdjust)`: An `ADMIN_ROLE` or `GUARDIAN_ROLE` resolves a dispute, adjusting reputation and potentially reverting actions.
22. `proposeGovernanceChange(bytes memory _callData, address _targetContract, string memory _descriptionCid)`: Initiates a proposal for a protocol upgrade or parameter change, targetting a specific contract with encoded call data.
23. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows contributors to vote on open governance proposals.
24. `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal once it has passed the voting threshold.
25. `requestDynamicTaskMatch(uint256 _projectId, uint256 _skillCategoryId)`: A conceptual function to request an external AI oracle to suggest contributors for a project based on skills and reputation.
26. `lockSBTForStaking(uint256 _sbtTokenId, uint256 _duration)`: Allows a contributor to lock one of their Skill SBTs for a specified duration to gain protocol benefits (e.g., boosted voting power, priority access).
27. `claimSBTStakingRewards(uint256 _sbtTokenId)`: Allows a contributor to claim any accrued rewards or benefits from their staked SBT after the lock duration.
28. `withdrawProtocolFees()`: Allows the `ADMIN_ROLE` to withdraw accumulated protocol fees from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For potential future token integration

// Outline:
// I. Core Infrastructure & Roles
//    - AccessControl for roles (Admin, Guardian, Oracle, Verifier)
//    - Contract-level parameters (fees, oracle addresses)
// II. Soulbound Token (SBT) Management
//    - SkillSBT (ERC721 Non-Transferable) for verified skills
//    - AchievementSBT (ERC721 Non-Transferable) for project completions
//    - Functions for proposing, approving, minting, and revoking SBTs
// III. Dynamic Reputation System
//    - On-chain reputation scores for contributors
//    - Functions for updating, delegating, and challenging reputation
// IV. Project & Task Management
//    - Lifecycle for proposing, funding, assigning, submitting, reviewing, and completing projects
//    - Integration with Skill SBTs for contributor assignment
// V. Governance & Protocol Evolution
//    - Proposal and voting mechanism for protocol changes
//    - Dispute resolution for skills, projects, and reputation
// VI. Oracle Integration (Conceptual)
//    - Functions for interacting with external data sources (e.g., AI for matching)
// VII. Advanced SBT Utility
//    - Staking mechanism for Skill SBTs to gain additional protocol benefits

// Function Summary:
// 1.  constructor(): Initializes roles, sets base parameters.
// 2.  updateProtocolFee(uint256 _newFeeBps): Sets the protocol fee percentage.
// 3.  updateGuardian(address _newGuardian): Designates a guardian with emergency powers.
// 4.  updateOracleAddress(address _newOracleAddress): Sets the trusted oracle contract address.
// 5.  registerSkillCategory(string memory _name, string memory _description): Defines a new category for skills.
// 6.  proposeSkillVerification(uint256 _skillCategoryId, string memory _proofCid): Initiates a request for skill verification (SBT mint).
// 7.  approveSkillVerificationByVerifier(uint256 _proposalId, bool _approve): Verifiers approve/reject skill verification proposals.
// 8.  claimSkillSBT(uint256 _proposalId): Mints a Soulbound Token for a successfully verified skill.
// 9.  revokeSkillSBT(address _contributor, uint256 _skillCategoryId, string memory _reasonCid): Revokes an SBT due to fraud or invalidation.
// 10. proposeProject(string memory _name, string memory _descriptionCid, uint256 _rewardAmount, uint256[] memory _requiredSkillCategoryIds, uint256 _bountyDuration): Creates a new project proposal.
// 11. fundProject(uint256 _projectId): Allows users to contribute funding to a proposed project.
// 12. assignProjectContributor(uint256 _projectId, address _contributor): Project owner assigns a contributor based on their skills.
// 13. submitProjectDeliverable(uint256 _projectId, string memory _deliverableCid): Contributor submits their work for review.
// 14. reviewProjectDeliverable(uint256 _projectId, address _contributor, bool _approved): Project owner or reviewer assesses the submitted deliverable.
// 15. setProjectReviewer(uint256 _projectId, address _reviewer, bool _canReview): Assigns specific reviewers for a project.
// 16. completeProjectAndDistributeRewards(uint256 _projectId): Finalizes the project, distributes rewards, and updates reputation.
// 17. claimAchievementSBT(uint256 _projectId, address _contributor): Mints an Achievement SBT for successful project completion.
// 18. delegateReputationScore(address _delegatee, uint256 _percentage): Delegates a percentage of one's reputation to another address for a specific purpose.
// 19. challengeReputationScore(address _contributorToChallenge, string memory _reasonCid): Initiates a formal dispute over a contributor's reputation.
// 20. initiateProjectDispute(uint256 _projectId, string memory _reasonCid): Opens a dispute regarding a project's completion or review.
// 21. resolveDispute(uint256 _disputeId, bool _isSkillDispute, bool _resolutionOutcome, int256 _reputationAdjust): Resolves a general dispute (skill or project).
// 22. proposeGovernanceChange(bytes memory _callData, address _targetContract, string memory _descriptionCid): Proposes a protocol upgrade or parameter change.
// 23. voteOnGovernanceProposal(uint256 _proposalId, bool _support): Casts a vote on a governance proposal.
// 24. executeGovernanceProposal(uint256 _proposalId): Executes an approved governance proposal.
// 25. requestDynamicTaskMatch(uint256 _projectId, uint256 _skillCategoryId): Requests a dynamic contributor match from an external oracle (e.g., AI).
// 26. lockSBTForStaking(uint256 _sbtTokenId, uint256 _duration): Locks a Skill SBT to gain staking benefits (e.g., enhanced voting, priority).
// 27. claimSBTStakingRewards(uint256 _sbtTokenId): Allows claiming rewards from staked SBTs.
// 28. withdrawProtocolFees(): Allows the admin to withdraw accumulated protocol fees.

contract AdaptiveDecentralizedSkillNetwork is AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for int256;

    // --- I. Core Infrastructure & Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE"); // Emergency role
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE"); // For skill verification
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");     // For AI/external data integration

    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 500 = 5%)
    address public oracleAddress;   // Address of the trusted oracle contract

    // --- II. Soulbound Token (SBT) Management ---
    // SkillSBT for verified skills
    // Non-transferable ERC721
    bytes32 private constant SKILL_SBT_NON_TRANSFERABLE_ROLE = keccak256("SKILL_SBT_NON_TRANSFERABLE_ROLE");
    bytes32 private constant SKILL_SBT_MINTER_ROLE = keccak256("SKILL_SBT_MINTER_ROLE");

    contract SkillSBT is ERC721, AccessControl {
        constructor(address _adscn) ERC721("ADSCN Skill Proof", "ASPS") {
            _grantRole(DEFAULT_ADMIN_ROLE, _adscn); // ADSCN contract is the admin
            _grantRole(SKILL_SBT_MINTER_ROLE, _adscn); // ADSCN contract can mint
            _setupRole(SKILL_SBT_NON_TRANSFERABLE_ROLE, _adscn); // ADSCN controls transferability
        }

        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal view override {
            super._beforeTokenTransfer(from, to, tokenId);
            require(
                hasRole(SKILL_SBT_NON_TRANSFERABLE_ROLE, _msgSender()),
                "SkillSBT: tokens are non-transferable"
            );
        }

        function mint(address to, uint256 tokenId)
            external
            onlyRole(SKILL_SBT_MINTER_ROLE)
            returns (uint256)
        {
            _safeMint(to, tokenId);
            return tokenId;
        }

        // Allow admin to burn, e.g., for revocation
        function burn(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
            _burn(tokenId);
        }
    }

    // AchievementSBT for project completions
    // Non-transferable ERC721
    bytes32 private constant ACHIEVEMENT_SBT_NON_TRANSFERABLE_ROLE =
        keccak256("ACHIEVEMENT_SBT_NON_TRANSFERABLE_ROLE");
    bytes32 private constant ACHIEVEMENT_SBT_MINTER_ROLE =
        keccak256("ACHIEVEMENT_SBT_MINTER_ROLE");

    contract AchievementSBT is ERC721, AccessControl {
        constructor(address _adscn) ERC721("ADSCN Project Achievement", "APA") {
            _grantRole(DEFAULT_ADMIN_ROLE, _adscn); // ADSCN contract is the admin
            _grantRole(ACHIEVEMENT_SBT_MINTER_ROLE, _adscn); // ADSCN contract can mint
            _setupRole(ACHIEVEMENT_SBT_NON_TRANSFERABLE_ROLE, _adscn); // ADSCN controls transferability
        }

        function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
        ) internal view override {
            super._beforeTokenTransfer(from, to, tokenId);
            require(
                hasRole(ACHIEVEMENT_SBT_NON_TRANSFERABLE_ROLE, _msgSender()),
                "AchievementSBT: tokens are non-transferable"
            );
        }

        function mint(address to, uint256 tokenId)
            external
            onlyRole(ACHIEVEMENT_SBT_MINTER_ROLE)
            returns (uint256)
        {
            _safeMint(to, tokenId);
            return tokenId;
        }

        function burn(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
            _burn(tokenId);
        }
    }

    SkillSBT public skillSBT;
    AchievementSBT public achievementSBT;

    struct SkillCategory {
        string name;
        string description;
        bool exists;
    }
    mapping(uint256 => SkillCategory) public skillCategories;
    Counters.Counter private _skillCategoryIds;

    struct SkillVerificationProposal {
        address contributor;
        uint256 skillCategoryId;
        string proofCid;
        bool approved;
        bool exists;
        bool claimed; // If SBT has been minted
    }
    mapping(uint256 => SkillVerificationProposal) public skillVerificationProposals;
    Counters.Counter private _skillVerificationProposalIds;

    // --- III. Dynamic Reputation System ---
    mapping(address => int256) public reputations; // Default starting reputation can be 0 or a base value
    mapping(address => mapping(address => uint256)) public delegatedReputations; // delegatee => delegator => percentage
    uint256 public constant MAX_REPUTATION_DELEGATION_PERCENT = 50; // Max 50% of reputation can be delegated

    // --- IV. Project & Task Management ---
    enum ProjectStatus {
        Proposed,
        Funded,
        InProgress,
        ReviewPending,
        Completed,
        Disputed,
        Cancelled
    }

    struct Project {
        address owner;
        string name;
        string descriptionCid;
        uint256 rewardAmount; // Total reward for project
        uint256 fundedAmount;
        ProjectStatus status;
        uint256[] requiredSkillCategoryIds;
        address[] assignedContributors;
        mapping(address => bool) contributorAssigned; // Quick check
        mapping(address => bool) contributorSubmitted;
        mapping(address => bool) contributorReviewed;
        mapping(address => bool) contributorApproved;
        mapping(address => string) deliverables; // contributor => deliverableCid
        mapping(address => bool) projectReviewers; // addresses that can review this project
        uint256 bountyDuration; // In seconds
        uint256 fundingDeadline; // Timestamp
        uint256 completionDeadline; // Timestamp after funding
        uint256 rewardsDistributed;
        bool exists;
    }
    mapping(uint256 => Project) public projects;
    Counters.Counter private _projectIds;

    // --- V. Governance & Protocol Evolution ---
    enum ProposalType {
        GovernanceChange,
        SkillVerification, // Handled separately now
        ReputationChallenge,
        ProjectDispute
    }

    enum DisputeStatus {
        Pending,
        ResolvedApproved,
        ResolvedRejected
    }

    struct Dispute {
        uint256 id;
        ProposalType _type;
        address initiator;
        address targetAddress; // relevant for reputation challenges, skill revokes
        uint256 targetId; // Project ID, Skill Category ID, etc.
        string reasonCid;
        DisputeStatus status;
        address resolutionBy;
        bool exists;
    }
    mapping(uint256 => Dispute) public disputes;
    Counters.Counter private _disputeIds;

    struct GovernanceProposal {
        uint256 id;
        string descriptionCid;
        address targetContract;
        bytes callData;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool exists;
        uint256 deadline;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _governanceProposalIds;

    // --- VI. Oracle Integration (Conceptual) ---
    // No direct oracle interface implementation, but conceptual functions exist

    // --- VII. Advanced SBT Utility ---
    struct StakedSBT {
        uint256 tokenId;
        uint256 lockUntil; // Timestamp
        uint256 stakedAt;  // Timestamp
        bool active;
    }
    // Mapping from Skill SBT tokenId to StakedSBT info
    mapping(uint256 => StakedSBT) public lockedSBTs;

    // --- Events ---
    event ProtocolFeeUpdated(uint256 newFeeBps);
    event GuardianUpdated(address newGuardian);
    event OracleAddressUpdated(address newOracleAddress);
    event SkillCategoryRegistered(uint256 indexed categoryId, string name);
    event SkillVerificationProposed(uint256 indexed proposalId, address indexed contributor, uint256 skillCategoryId);
    event SkillVerificationApproved(uint256 indexed proposalId, address indexed verifier, bool approved);
    event SkillSBTClaimed(address indexed contributor, uint256 indexed skillCategoryId, uint256 tokenId);
    event SkillSBTRevoked(address indexed contributor, uint256 indexed skillCategoryId, string reasonCid);
    event ProjectProposed(uint256 indexed projectId, address indexed owner, uint256 rewardAmount);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ContributorAssigned(uint256 indexed projectId, address indexed contributor);
    event DeliverableSubmitted(uint256 indexed projectId, address indexed contributor, string deliverableCid);
    event DeliverableReviewed(uint256 indexed projectId, address indexed contributor, bool approved);
    event ProjectReviewerSet(uint256 indexed projectId, address indexed reviewer, bool canReview);
    event ProjectCompleted(uint256 indexed projectId, address indexed completer, uint256 totalRewards, uint256 protocolFee);
    event AchievementSBTClaimed(uint256 indexed projectId, address indexed contributor, uint256 tokenId);
    event ReputationUpdated(address indexed contributor, int256 oldReputation, int256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 percentage);
    event ReputationChallengeInitiated(uint256 indexed disputeId, address indexed challenger, address indexed challenged, string reasonCid);
    event ProjectDisputeInitiated(uint256 indexed disputeId, address indexed initiator, uint256 indexed projectId, string reasonCid);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status, address indexed resolver, bool outcome);
    event GovernanceProposalProposed(uint256 indexed proposalId, address indexed proposer, string descriptionCid);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event DynamicTaskMatchRequested(uint256 indexed projectId, uint256 skillCategoryId);
    event SBTLockedForStaking(uint256 indexed sbtTokenId, address indexed owner, uint256 duration, uint256 lockUntil);
    event SBTStakingRewardsClaimed(uint256 indexed sbtTokenId, address indexed owner);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(GUARDIAN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender); // Deployer is also initial verifier
        _grantRole(ORACLE_ROLE, msg.sender); // Deployer is also initial oracle address

        protocolFeeBps = 500; // 5% initial fee
        oracleAddress = msg.sender; // Set initial oracle address to deployer

        // Deploy SBT contracts
        skillSBT = new SkillSBT(address(this));
        achievementSBT = new AchievementSBT(address(this));
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ADSCN: Must have ADMIN_ROLE");
        _;
    }

    modifier onlyGuardian() {
        require(hasRole(GUARDIAN_ROLE, _msgSender()), "ADSCN: Must have GUARDIAN_ROLE");
        _;
    }

    modifier onlyVerifier() {
        require(hasRole(VERIFIER_ROLE, _msgSender()), "ADSCN: Must have VERIFIER_ROLE");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, _msgSender()), "ADSCN: Must have ORACLE_ROLE");
        _;
    }

    // --- I. Core Infrastructure & Roles ---
    function updateProtocolFee(uint256 _newFeeBps) external onlyAdmin {
        require(_newFeeBps <= 10000, "ADSCN: Fee cannot exceed 100%");
        protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    function updateGuardian(address _newGuardian) external onlyAdmin {
        require(_newGuardian != address(0), "ADSCN: Invalid guardian address");
        _revokeRole(GUARDIAN_ROLE, getRoleMember(GUARDIAN_ROLE, 0)); // Only works if there's one guardian
        _grantRole(GUARDIAN_ROLE, _newGuardian);
        emit GuardianUpdated(_newGuardian);
    }

    function updateOracleAddress(address _newOracleAddress) external onlyAdmin {
        require(_newOracleAddress != address(0), "ADSCN: Invalid oracle address");
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    // --- II. Soulbound Token (SBT) Management ---
    function registerSkillCategory(
        string memory _name,
        string memory _description
    ) external onlyAdmin {
        _skillCategoryIds.increment();
        uint256 newId = _skillCategoryIds.current();
        skillCategories[newId] = SkillCategory(_name, _description, true);
        emit SkillCategoryRegistered(newId, _name);
    }

    function proposeSkillVerification(
        uint256 _skillCategoryId,
        string memory _proofCid
    ) external {
        require(skillCategories[_skillCategoryId].exists, "ADSCN: Skill category does not exist");
        _skillVerificationProposalIds.increment();
        uint256 proposalId = _skillVerificationProposalIds.current();
        skillVerificationProposals[proposalId] = SkillVerificationProposal(
            _msgSender(),
            _skillCategoryId,
            _proofCid,
            false,
            true,
            false
        );
        emit SkillVerificationProposed(proposalId, _msgSender(), _skillCategoryId);
    }

    function approveSkillVerificationByVerifier(
        uint256 _proposalId,
        bool _approve
    ) external onlyVerifier {
        SkillVerificationProposal storage proposal = skillVerificationProposals[_proposalId];
        require(proposal.exists, "ADSCN: Proposal does not exist");
        require(!proposal.approved && !proposal.claimed, "ADSCN: Proposal already processed"); // Can't re-approve or approve after claim

        proposal.approved = _approve;
        emit SkillVerificationApproved(_proposalId, _msgSender(), _approve);

        if (_approve) {
            // Optional: immediately mint or wait for user to claim
        } else {
            // Optional: reputation penalty for proposer if fraud detected
        }
    }

    function claimSkillSBT(uint256 _proposalId) external {
        SkillVerificationProposal storage proposal = skillVerificationProposals[_proposalId];
        require(proposal.exists, "ADSCN: Proposal does not exist");
        require(proposal.contributor == _msgSender(), "ADSCN: Not your proposal");
        require(proposal.approved, "ADSCN: Proposal not yet approved");
        require(!proposal.claimed, "ADSCN: SBT already claimed");

        // Use proposalId as tokenId for simplicity
        skillSBT.mint(_msgSender(), _proposalId);
        proposal.claimed = true;
        updateContributorReputation(
            _msgSender(),
            reputations[_msgSender()].add(100)
        ); // Example reputation boost
        emit SkillSBTClaimed(_msgSender(), proposal.skillCategoryId, _proposalId);
    }

    function revokeSkillSBT(
        address _contributor,
        uint256 _skillCategoryId, // Can be used to find the specific SBT if needed, assuming (contributor, category) -> unique SBT ID
        string memory _reasonCid
    ) external onlyAdmin {
        // Find the proposalId related to this contributor and skillCategoryId
        uint256 proposalId = 0;
        for (uint256 i = 1; i <= _skillVerificationProposalIds.current(); i++) {
            SkillVerificationProposal storage p = skillVerificationProposals[i];
            if (p.exists && p.contributor == _contributor && p.skillCategoryId == _skillCategoryId && p.claimed) {
                proposalId = i;
                break;
            }
        }
        require(proposalId != 0, "ADSCN: No claimed SBT found for this skill/contributor");

        skillSBT.burn(proposalId); // Burn the SBT
        skillVerificationProposals[proposalId].claimed = false; // Mark as no longer claimed
        skillVerificationProposals[proposalId].approved = false; // Reset approval status

        updateContributorReputation(
            _contributor,
            reputations[_contributor].sub(200)
        ); // Example reputation penalty

        // Optionally, create a dispute record for transparency
        _disputeIds.increment();
        disputes[_disputeIds.current()] = Dispute(
            _disputeIds.current(),
            ProposalType.SkillVerification,
            _msgSender(), // Admin/Guardian initiating revoke
            _contributor,
            _skillCategoryId,
            _reasonCid,
            DisputeStatus.ResolvedApproved, // Revocation is the resolution
            _msgSender(),
            true
        );

        emit SkillSBTRevoked(_contributor, _skillCategoryId, _reasonCid);
    }

    // --- III. Dynamic Reputation System ---
    function updateContributorReputation(address _contributor, int256 _newReputation) internal {
        int256 oldReputation = reputations[_contributor];
        reputations[_contributor] = _newReputation;
        emit ReputationUpdated(_contributor, oldReputation, _newReputation);
    }

    function delegateReputationScore(address _delegatee, uint256 _percentage) external {
        require(_percentage <= MAX_REPUTATION_DELEGATION_PERCENT, "ADSCN: Exceeds max delegation percentage");
        require(_delegatee != address(0), "ADSCN: Invalid delegatee address");
        require(_delegatee != _msgSender(), "ADSCN: Cannot delegate to self");

        delegatedReputations[_delegatee][_msgSender()] = _percentage;
        emit ReputationDelegated(_msgSender(), _delegatee, _percentage);
    }

    function challengeReputationScore(
        address _contributorToChallenge,
        string memory _reasonCid
    ) external payable {
        // Require a bond to challenge
        require(msg.value > 0, "ADSCN: Must provide a bond to challenge reputation");
        require(_contributorToChallenge != address(0), "ADSCN: Invalid target address");
        require(_contributorToChallenge != _msgSender(), "ADSCN: Cannot challenge self");

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();
        disputes[disputeId] = Dispute(
            disputeId,
            ProposalType.ReputationChallenge,
            _msgSender(),
            _contributorToChallenge,
            0, // No specific ID for skill or project here
            _reasonCid,
            DisputeStatus.Pending,
            address(0),
            true
        );
        // Store bond, e.g., in a separate mapping or track with dispute struct
        // For simplicity, bond is just sent to contract. Resolution logic will handle refund/slash.
        emit ReputationChallengeInitiated(disputeId, _msgSender(), _contributorToChallenge, _reasonCid);
    }

    // --- IV. Project & Task Management ---
    function proposeProject(
        string memory _name,
        string memory _descriptionCid,
        uint256 _rewardAmount,
        uint256[] memory _requiredSkillCategoryIds,
        uint256 _bountyDuration
    ) external {
        require(_rewardAmount > 0, "ADSCN: Project reward must be greater than zero");
        for (uint256 i = 0; i < _requiredSkillCategoryIds.length; i++) {
            require(
                skillCategories[_requiredSkillCategoryIds[i]].exists,
                "ADSCN: Required skill category does not exist"
            );
        }

        _projectIds.increment();
        uint256 projectId = _projectIds.current();
        projects[projectId] = Project(
            _msgSender(),
            _name,
            _descriptionCid,
            _rewardAmount,
            0, // fundedAmount
            ProjectStatus.Proposed,
            _requiredSkillCategoryIds,
            new address[](0), // assignedContributors
            // contributorAssigned, contributorSubmitted, contributorReviewed, contributorApproved are mappings initialized implicitly
            // deliverables is mapping initialized implicitly
            // projectReviewers is mapping initialized implicitly
            _bountyDuration,
            block.timestamp + 7 days, // Example 7 days funding deadline
            0, // completionDeadline
            0, // rewardsDistributed
            true
        );

        emit ProjectProposed(projectId, _msgSender(), _rewardAmount);
    }

    function fundProject(uint256 _projectId) external payable {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.status == ProjectStatus.Proposed, "ADSCN: Project not in proposed state");
        require(block.timestamp <= project.fundingDeadline, "ADSCN: Funding deadline passed");
        require(msg.value > 0, "ADSCN: Must send value to fund");

        project.fundedAmount += msg.value;
        if (project.fundedAmount >= project.rewardAmount) {
            project.status = ProjectStatus.Funded;
            project.completionDeadline = block.timestamp + project.bountyDuration;
        }
        emit ProjectFunded(_projectId, _msgSender(), msg.value);
    }

    function assignProjectContributor(uint256 _projectId, address _contributor) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.owner == _msgSender(), "ADSCN: Only project owner can assign contributors");
        require(
            project.status == ProjectStatus.Funded || project.status == ProjectStatus.InProgress,
            "ADSCN: Project not ready for contributor assignment"
        );
        require(!project.contributorAssigned[_contributor], "ADSCN: Contributor already assigned");

        // Check if contributor holds all required Skill SBTs
        for (uint256 i = 0; i < project.requiredSkillCategoryIds.length; i++) {
            uint256 skillCatId = project.requiredSkillCategoryIds[i];
            uint256 skillSbtId = 0;
            for (uint256 j = 1; j <= _skillVerificationProposalIds.current(); j++) {
                SkillVerificationProposal storage p = skillVerificationProposals[j];
                if (p.exists && p.contributor == _contributor && p.skillCategoryId == skillCatId && p.claimed) {
                    skillSbtId = j; // Found the SBT ID for this skill category
                    break;
                }
            }
            require(skillSBT.ownerOf(skillSbtId) == _contributor, "ADSCN: Contributor lacks required Skill SBT");
        }

        project.assignedContributors.push(_contributor);
        project.contributorAssigned[_contributor] = true;
        if (project.status == ProjectStatus.Funded) {
            project.status = ProjectStatus.InProgress;
        }
        emit ContributorAssigned(_projectId, _contributor);
    }

    function submitProjectDeliverable(uint256 _projectId, string memory _deliverableCid) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.contributorAssigned[_msgSender()], "ADSCN: Not an assigned contributor");
        require(project.status == ProjectStatus.InProgress, "ADSCN: Project not in progress");
        require(block.timestamp <= project.completionDeadline, "ADSCN: Project completion deadline passed");
        require(!project.contributorSubmitted[_msgSender()], "ADSCN: Deliverable already submitted");

        project.deliverables[_msgSender()] = _deliverableCid;
        project.contributorSubmitted[_msgSender()] = true;
        project.status = ProjectStatus.ReviewPending; // Transition if all deliverables are in, or if it's a single contributor
        emit DeliverableSubmitted(_projectId, _msgSender(), _deliverableCid);
    }

    function reviewProjectDeliverable(
        uint256 _projectId,
        address _contributor,
        bool _approved
    ) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(
            project.owner == _msgSender() || project.projectReviewers[_msgSender()],
            "ADSCN: Only project owner or designated reviewer can review"
        );
        require(project.contributorAssigned[_contributor], "ADSCN: Not an assigned contributor");
        require(project.contributorSubmitted[_contributor], "ADSCN: Deliverable not submitted yet");
        require(!project.contributorReviewed[_contributor], "ADSCN: Deliverable already reviewed");

        project.contributorReviewed[_contributor] = true;
        project.contributorApproved[_contributor] = _approved;
        emit DeliverableReviewed(_projectId, _contributor, _approved);
    }

    function setProjectReviewer(uint256 _projectId, address _reviewer, bool _canReview) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.owner == _msgSender(), "ADSCN: Only project owner can set reviewers");
        require(_reviewer != address(0), "ADSCN: Invalid reviewer address");

        project.projectReviewers[_reviewer] = _canReview;
        emit ProjectReviewerSet(_projectId, _reviewer, _canReview);
    }

    function completeProjectAndDistributeRewards(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.owner == _msgSender(), "ADSCN: Only project owner can complete");
        require(project.status == ProjectStatus.ReviewPending, "ADSCN: Project not in review pending state");

        uint256 totalApprovedContributors = 0;
        for (uint256 i = 0; i < project.assignedContributors.length; i++) {
            if (project.contributorApproved[project.assignedContributors[i]]) {
                totalApprovedContributors++;
            }
        }
        require(totalApprovedContributors > 0, "ADSCN: No approved contributors to reward");

        uint256 rewardPerContributor = project.rewardAmount / totalApprovedContributors;
        uint256 totalProtocolFee = (project.rewardAmount * protocolFeeBps) / 10000;
        uint256 totalDistributed = 0;

        for (uint256 i = 0; i < project.assignedContributors.length; i++) {
            address contributor = project.assignedContributors[i];
            if (project.contributorApproved[contributor]) {
                payable(contributor).transfer(rewardPerContributor);
                totalDistributed += rewardPerContributor;
                // Update reputation for successful completion
                updateContributorReputation(contributor, reputations[contributor].add(150)); // Example boost
            } else {
                // Optional: penalize reputation for failed contribution
                updateContributorReputation(contributor, reputations[contributor].sub(50));
            }
        }

        // Send protocol fees
        if (totalProtocolFee > 0) {
            payable(address(this)).transfer(totalProtocolFee); // Funds are already in contract from funding
        }

        project.rewardsDistributed = totalDistributed;
        project.status = ProjectStatus.Completed;
        emit ProjectCompleted(_projectId, _msgSender(), totalDistributed, totalProtocolFee);
    }

    function claimAchievementSBT(uint256 _projectId, address _contributor) external {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.status == ProjectStatus.Completed, "ADSCN: Project not completed");
        require(project.contributorApproved[_contributor], "ADSCN: Contributor was not approved for this project");
        require(_contributor == _msgSender(), "ADSCN: Only approved contributor can claim");

        // Use a combination of projectId and contributor address for unique Achievement SBT ID
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_projectId, _contributor)));
        require(achievementSBT.ownerOf(tokenId) == address(0), "ADSCN: Achievement SBT already claimed");

        achievementSBT.mint(_contributor, tokenId);
        emit AchievementSBTClaimed(_projectId, _contributor, tokenId);
    }

    // --- V. Governance & Protocol Evolution ---

    function initiateProjectDispute(uint256 _projectId, string memory _reasonCid) external payable {
        Project storage project = projects[_projectId];
        require(project.exists, "ADSCN: Project does not exist");
        require(project.status != ProjectStatus.Cancelled, "ADSCN: Project is cancelled");
        require(msg.value > 0, "ADSCN: Must provide a bond to dispute");

        _disputeIds.increment();
        uint256 disputeId = _disputeIds.current();
        disputes[disputeId] = Dispute(
            disputeId,
            ProposalType.ProjectDispute,
            _msgSender(),
            project.owner, // Or specific contributor if dispute is against them
            _projectId,
            _reasonCid,
            DisputeStatus.Pending,
            address(0),
            true
        );
        project.status = ProjectStatus.Disputed; // Set project status to disputed
        emit ProjectDisputeInitiated(disputeId, _msgSender(), _projectId, _reasonCid);
    }

    function resolveDispute(
        uint256 _disputeId,
        bool _isSkillDispute, // if true, it's skill verification proposal dispute, else project/reputation
        bool _resolutionOutcome, // true for challenger wins / approval, false for challenger loses / rejection
        int256 _reputationAdjust // Reputation adjustment delta
    ) external onlyAdmin {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.exists, "ADSCN: Dispute does not exist");
        require(dispute.status == DisputeStatus.Pending, "ADSCN: Dispute already resolved");

        dispute.status = _resolutionOutcome ? DisputeStatus.ResolvedApproved : DisputeStatus.ResolvedRejected;
        dispute.resolutionBy = _msgSender();

        // Handle bond refund/slash logic here (not explicitly implemented in this basic example)
        // If challenger wins, refund their bond. If they lose, slash.

        if (_isSkillDispute) {
            // This is actually for revoking existing SBTs or challenging a verifier's decision.
            // If it's a challenge against a skill SBT or its verification,
            // we'd interact with skillSBT.burn() or adjust skillVerificationProposals.
            // Simplified: The outcome dictates if the skill SBT remains or is burned.
            // For revocation, this would reverse it if _resolutionOutcome is false (i.e. revoke was wrong).
        } else {
            // For project disputes or reputation challenges
            if (dispute._type == ProposalType.ProjectDispute) {
                Project storage project = projects[dispute.targetId];
                if (project.exists) {
                    if (_resolutionOutcome) {
                        // Example: If dispute resolution favors the disputer in a project dispute
                        // Could lead to re-review, reallocation of rewards, or penalties
                        project.status = ProjectStatus.ReviewPending; // Revert to re-review
                    } else {
                        // Dispute rejected, revert project to its previous state
                        project.status = ProjectStatus.Completed; // Or whatever it was before dispute
                    }
                }
            } else if (dispute._type == ProposalType.ReputationChallenge) {
                // Adjust reputation of the challenged party
                updateContributorReputation(
                    dispute.targetAddress,
                    reputations[dispute.targetAddress].add(_reputationAdjust)
                );
                // Adjust reputation of the initiator based on _resolutionOutcome
                updateContributorReputation(
                    dispute.initiator,
                    reputations[dispute.initiator].add(_resolutionOutcome ? 50 : -50)
                ); // Challenger gets points if successful, loses if not.
            }
        }
        emit DisputeResolved(_disputeId, dispute.status, _msgSender(), _resolutionOutcome);
    }

    function proposeGovernanceChange(
        bytes memory _callData,
        address _targetContract,
        string memory _descriptionCid
    ) external onlyAdmin {
        // In a full DAO, this might be open to anyone with a stake
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal(
            proposalId,
            _descriptionCid,
            _targetContract,
            _callData,
            0, // totalVotesFor
            0, // totalVotesAgainst
            // hasVoted mapping initialized implicitly
            false, // executed
            true, // exists
            block.timestamp + 3 days // Example 3 days voting period
        );
        emit GovernanceProposalProposed(proposalId, _msgSender(), _descriptionCid);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.exists, "ADSCN: Proposal does not exist");
        require(!proposal.executed, "ADSCN: Proposal already executed");
        require(block.timestamp <= proposal.deadline, "ADSCN: Voting period ended");
        require(!proposal.hasVoted[_msgSender()], "ADSCN: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.totalVotesFor++; // Simple vote count, could be weighted by reputation/SBT stake
        } else {
            proposal.totalVotesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, _msgSender(), _support);
    }

    function executeGovernanceProposal(uint256 _proposalId) external onlyAdmin {
        // In a full DAO, this would be callable by anyone if conditions are met
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.exists, "ADSCN: Proposal does not exist");
        require(!proposal.executed, "ADSCN: Proposal already executed");
        require(block.timestamp > proposal.deadline, "ADSCN: Voting period not ended");
        require(
            proposal.totalVotesFor > proposal.totalVotesAgainst,
            "ADSCN: Proposal did not pass"
        );

        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "ADSCN: Proposal execution failed");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- VI. Oracle Integration (Conceptual) ---
    function requestDynamicTaskMatch(uint256 _projectId, uint256 _skillCategoryId) external {
        // This function would typically interact with an external oracle contract.
        // For demonstration, it just emits an event. The oracle would then
        // (off-chain or via another contract) process this request and potentially
        // suggest contributors to the project owner.
        require(projects[_projectId].exists, "ADSCN: Project does not exist");
        require(skillCategories[_skillCategoryId].exists, "ADSCN: Skill category does not exist");

        // Example: Call to an oracle contract.
        // IOracle(oracleAddress).requestMatch(_projectId, _skillCategoryId, _msgSender());
        emit DynamicTaskMatchRequested(_projectId, _skillCategoryId);
    }

    // --- VII. Advanced SBT Utility ---
    function lockSBTForStaking(uint256 _sbtTokenId, uint256 _duration) external {
        require(skillSBT.ownerOf(_sbtTokenId) == _msgSender(), "ADSCN: Not the owner of this Skill SBT");
        require(_duration > 0, "ADSCN: Lock duration must be greater than zero");
        require(!lockedSBTs[_sbtTokenId].active, "ADSCN: SBT is already staked");

        lockedSBTs[_sbtTokenId] = StakedSBT({
            tokenId: _sbtTokenId,
            lockUntil: block.timestamp + _duration,
            stakedAt: block.timestamp,
            active: true
        });

        // Potentially disable transfers of the SBT if the SBT contract supports it
        // Or simply penalize early withdrawal. For a Soulbound Token, transfer is already restricted.

        // Benefits could include boosted voting power in governance, priority for project assignments, etc.
        emit SBTLockedForStaking(_sbtTokenId, _msgSender(), _duration, block.timestamp + _duration);
    }

    function claimSBTStakingRewards(uint256 _sbtTokenId) external {
        StakedSBT storage staked = lockedSBTs[_sbtTokenId];
        require(staked.active, "ADSCN: SBT not actively staked");
        require(skillSBT.ownerOf(_sbtTokenId) == _msgSender(), "ADSCN: Not the owner of this Skill SBT");
        require(block.timestamp >= staked.lockUntil, "ADSCN: Staking period not yet over");

        // Logic to calculate and distribute rewards.
        // For simplicity, let's say it gives a reputation boost and then unstakes.
        updateContributorReputation(_msgSender(), reputations[_msgSender()].add(50)); // Example reputation reward
        staked.active = false; // Mark as unstaked

        emit SBTStakingRewardsClaimed(_sbtTokenId, _msgSender());
    }

    function withdrawProtocolFees() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "ADSCN: No fees to withdraw");

        payable(msg.sender).transfer(balance);
        emit ProtocolFeesWithdrawn(msg.sender, balance);
    }

    // Fallback function to accept Ether
    receive() external payable {}
}

```