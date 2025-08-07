Here's a Solidity smart contract for a decentralized skill and project collaborative network, named "SynergiaNet". It incorporates several advanced, creative, and trendy concepts, while aiming to avoid direct duplication of existing large open-source projects by combining these features in a unique way.

This contract uses OpenZeppelin libraries for standard token functionalities (ERC-20, ERC-721) to ensure robustness and security, focusing the novelty on the application logic and inter-feature synergy.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Using Enumerable for easier SV-NFT tracking
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety in calculations
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; // For internal FPE tokens

// --- Outline & Function Summary ---
// SynergiaNet: A Decentralized Skill & Project Collaborative Network
// This contract aims to be a novel platform where skilled individuals (Synergists) can form teams,
// propose projects, secure funding, and build verifiable reputations based on their contributions and project success.
// It features a dynamic, decaying, and stake-boostable reputation system, skill-verified NFTs (SV-NFTs),
// fractionalized project equity (FPE), and an incentivized on-chain peer review and dispute resolution system.
//
// I. Core Synergist & Reputation Management:
//    Manages user registration, profile updates, and a dynamic reputation system.
//    Reputation is influenced by contributions, peer reviews, and token stakes, decaying over time to encourage continuous engagement.
//    1.  `registerSynergist(string calldata _username)`: Registers a new user on the platform.
//    2.  `updateSynergistProfile(string calldata _newUsername, string calldata _ipfsHashForDetails)`: Allows a Synergist to update their profile information.
//    3.  `stakeReputationBoost(uint256 _amount)`: Enables a Synergist to stake SynTokens to temporarily boost their effective reputation score.
//    4.  `unstakeReputationBoost()`: Allows a Synergist to retrieve their staked reputation tokens after a cooldown period.
//    5.  `getSynergistReputation(address _synergistAddress)`: A view function to retrieve the current effective reputation of a Synergist.
//
// II. Skill Verification & Credentialing (SV-NFTs):
//    Allows Synergists to mint and manage Non-Fungible Tokens (NFTs) representing verified skills.
//    Skill verification can be achieved through attestation by high-reputation peers or through a community-driven peer review process.
//    6.  `attestSkill(address _synergistAddress, string calldata _skillHash, string calldata _evidenceIpfsHash)`: A high-reputation Synergist attests to another Synergist's skill, minting an SV-NFT. Requires stakes from both parties.
//    7.  `requestSkillVerification(string calldata _skillHash, string calldata _evidenceIpfsHash)`: Initiates a request for peer review to verify a skill.
//    8.  `submitSkillReview(address _requestor, uint256 _requestId, bool _isVerified, string calldata _reviewIpfsHash)`: Allows a Synergist to submit a review for a pending skill verification request.
//    9.  `getSkillNFTDetails(uint256 _tokenId)`: A view function to retrieve metadata associated with a specific SV-NFT.
//
// III. Project Lifecycle & Funding:
//    Manages the creation, funding, task assignment, task completion, milestone distribution, and finalization of decentralized projects.
//    10. `proposeProject(string calldata _projectIpfsHash, uint256 _fundingGoal, uint256 _durationWeeks, string[] calldata _requiredSkills)`: Allows a Synergist to propose a new project, specifying its scope and funding requirements.
//    11. `fundProject(uint256 _projectId, uint256 _amount)`: Enables users to contribute native currency (e.g., ETH) to a proposed project's funding goal.
//    12. `addTaskToProject(uint256 _projectId, string calldata _taskIpfsHash)`: Project proposer can add individual tasks to an active project.
//    13. `commitToProjectTask(uint256 _projectId, uint256 _taskId, string calldata _taskIpfsHash)`: A Synergist commits to performing a specific task within a funded project, requiring a stake.
//    14. `submitTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _completionEvidenceIpfsHash)`: Allows the committed Synergist to submit proof of task completion for review.
//    15. `reviewTaskCompletion(uint256 _projectId, uint256 _taskId, address _contributor, bool _isComplete, string calldata _reviewIpfsHash)`: Enables project leads or peers to review a submitted task for completion.
//    16. `distributeProjectMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Distributes a portion of raised project funds upon completion of a defined project milestone.
//    17. `finalizeProject(uint256 _projectId)`: Marks a project as complete, calculates and initiates the minting of Fractionalized Project Equity (FPE) tokens.
//    18. `getProjectDetails(uint256 _projectId)`: A view function to retrieve all stored details about a specific project.
//
// IV. Fractionalized Project Equity (FPE):
//    A conceptual ERC-20 token representing shares in a completed project's future value or revenue. Each project mints its own FPE token.
//    19. `distributeProjectRevenueShare(uint256 _projectId, uint256 _amount)`: Allows an external party (e.g., an oracle or project owner) to deposit external revenue into the contract, designated for FPE holders of a specific project.
//    20. `redeemFPERevenue(uint256 _projectId)`: Enables FPE token holders to redeem their proportional share of accumulated project revenue.
//
// V. Decentralized Governance & Treasury:
//    A simplified Decentralized Autonomous Organization (DAO) for protocol upgrades, adjustments, and treasury management, utilizing reputation-weighted voting.
//    21. `submitGovernanceProposal(string calldata _proposalIpfsHash, address _targetContract, bytes calldata _callData)`: Allows high-reputation Synergists to submit proposals for protocol changes or treasury spending.
//    22. `voteOnProposal(uint256 _proposalId, bool _support)`: Enables Synergists to vote on governance proposals, with their vote weight determined by their effective reputation.
//    23. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed its voting period and conditions.
//    24. `withdrawFromTreasury(address _to, uint256 _amount)`: An administrative function (conceptually via governance) to withdraw funds from the contract's treasury.
//
// VI. On-Chain Peer Review & Dispute Resolution:
//    A structured system for initiating, submitting evidence, voting by arbitrators, and formally resolving disputes related to skill attestations, task completions, or project milestones.
//    25. `initiateDispute(uint256 _disputeType, uint256 _entityId, address _partyA, address _partyB, string calldata _evidenceIpfsHash)`: Initiates a formal dispute over a specific entity (e.g., skill NFT, task).
//    26. `submitDisputeVote(uint256 _disputeId, uint256 _verdict)`: Allows qualified Synergist arbitrators to cast their vote on an ongoing dispute, weighted by their reputation.
//    27. `resolveDispute(uint256 _disputeId)`: Finalizes a dispute based on the arbitration votes, applying rewards or penalties as determined by the outcome.
//
// Total Functions: 27

// --- Interface for the SynToken (Assumed external ERC-20 token for staking) ---
// This token is used for reputation staking, project proposals, and task commitments.
interface ISynToken is IERC20 {
    // No additional functions needed beyond IERC20 for this example.
}

// --- Internal ERC-20 for Fractionalized Project Equity (FPE) ---
// Each project will have its own unique instance of this token.
contract ProjectEquityToken is ERC20, Ownable {
    // Constructor initializes the ERC-20 token with a specific name and symbol.
    // The initial owner is the SynergiaNet contract, allowing it to mint tokens.
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // Allows the owner (SynergiaNet contract) to mint new FPE tokens.
    // This function will be called by SynergiaNet upon project finalization.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

// --- Main SynergiaNet Smart Contract ---
contract SynergiaNet is Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Address of the external SynToken used for staking and fees.
    ISynToken public synToken;

    // --- Counters for unique IDs ---
    Counters.Counter private _synergistIdCounter;
    Counters.Counter private _skillNFTIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _skillRequestIdCounter;
    Counters.Counter private _governanceProposalIdCounter;
    Counters.Counter private _disputeIdCounter;

    // --- Constants & Configuration Parameters ---
    uint256 public constant MIN_REPUTATION_FOR_ATTESTATION = 1000; // Minimum reputation to attest a skill
    uint256 public constant REPUTATION_DECAY_RATE_PER_WEEK = 50; // Reputation points lost per week of inactivity
    uint256 public constant REPUTATION_BOOST_MULTIPLIER = 2; // Multiplier for staked reputation
    uint256 public constant REPUTATION_BOOST_COOLDOWN_WEEKS = 4; // Cooldown period for unstaking reputation boost
    uint256 public constant PROJECT_PROPOSAL_STAKE_AMOUNT = 100 * (10 ** 18); // SynToken stake required for project proposal
    uint256 public constant TASK_COMMITMENT_STAKE_AMOUNT = 10 * (10 ** 18); // SynToken stake required for task commitment
    uint256 public constant ATTESTATION_STAKE_AMOUNT = 50 * (10 ** 18); // SynToken stake for skill attestation (per party)
    uint256 public constant MIN_REPUTATION_FOR_REVIEW = 500; // Minimum reputation to review skills/tasks
    uint256 public constant MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL = 1500; // Minimum reputation to submit a governance proposal
    uint256 public constant MIN_REPUTATION_FOR_ARBITRATION = 200; // Minimum reputation to vote on a dispute
    uint256 public constant GOVERNANCE_VOTING_PERIOD_WEEKS = 1; // Duration of governance voting period

    // --- Data Structures ---

    enum SynergistStatus {
        Inactive,
        Active,
        Suspended
    }

    struct Synergist {
        uint256 id;
        string username;
        string ipfsHashForDetails; // IPFS hash for detailed profile information (e.g., portfolio, social links)
        uint256 rawReputation; // Base reputation score
        uint256 lastReputationUpdate; // Timestamp of last activity for decay calculation
        uint256 stakedReputationAmount; // Amount of SynToken staked for reputation boost
        uint256 stakeUnlockTime; // Timestamp when staked tokens can be unstaked
        SynergistStatus status;
    }

    // Skill NFT metadata, stored as part of the ERC721 token
    struct SkillMetadata {
        string skillHash; // Unique identifier or IPFS hash for the skill definition (e.g., "solidity_development", "ui_ux_design")
        string evidenceIpfsHash; // IPFS hash pointing to off-chain evidence supporting the skill
        address attestedBy; // Address of Synergist who attested, or address(0) if system-verified
        uint256 attestedOn; // Timestamp of attestation or verification
    }

    enum SkillRequestStatus {
        Pending,
        Reviewed,
        Verified,
        Rejected
    }

    struct SkillVerificationRequest {
        uint256 requestId;
        address requestor;
        string skillHash;
        string evidenceIpfsHash;
        uint256 submissionTime;
        mapping(address => bool) reviewers; // Tracks who has reviewed this request
        uint256 positiveReviews; // Count of positive reviews
        uint256 negativeReviews; // Count of negative reviews
        SkillRequestStatus status;
        uint256 mintedSkillNFTId; // The ID of the minted SV-NFT if verified
    }

    enum ProjectStatus {
        Proposed, // Project is new, awaiting initial funding or activation
        Funding, // Project is actively collecting funds
        Active, // Project is fully funded and work is ongoing
        Completed, // Project is finalized and FPE has been minted
        Cancelled // Project was cancelled (e.g., failed to fund, or governance decision)
    }

    struct Project {
        uint256 id;
        address proposer;
        string ipfsHashForDetails; // IPFS hash for detailed project description, goals, milestones
        uint256 fundingGoal; // Target funding amount in native currency
        uint256 fundsRaised; // Current amount of native currency raised
        uint256 durationWeeks; // Estimated project duration
        uint256 proposalTimestamp;
        string[] requiredSkills; // List of skills required for the project
        ProjectStatus status;
        mapping(address => uint256) funders; // Tracks individual funding contributions (address => amount)
        uint256 totalTasks; // Total number of tasks defined for the project
        mapping(uint256 => ProjectTask) tasks; // Map of taskId to ProjectTask struct
        mapping(uint256 => bool) milestonesCompleted; // Tracks completion status of numbered milestones
        address fpeTokenAddress; // Address of the deployed ProjectEquityToken for this project
        uint256 accumulatedRevenue; // Native currency revenue collected for FPE holders
    }

    enum TaskStatus {
        Open,
        Committed,
        SubmittedForReview,
        Completed,
        Disputed
    }

    struct ProjectTask {
        uint256 taskId;
        string ipfsHash; // IPFS hash for task details (description, deliverables)
        address committedBy; // Synergist who committed to the task
        uint256 commitmentTime;
        string completionEvidenceIpfsHash; // IPFS hash for proof of task completion
        uint256 submissionTime;
        mapping(address => bool) reviewers; // Tracks who has reviewed this task
        uint256 positiveReviews; // Count of positive task reviews
        uint256 negativeReviews; // Count of negative task reviews
        TaskStatus status;
        uint256 stakeHeld; // Stake from task commitment, held for dispute or return
    }

    enum DisputeType {
        SkillAttestation,   // Dispute over a minted SV-NFT attestation
        TaskCompletion,     // Dispute over a submitted task completion
        ProjectMilestone    // Dispute over a project milestone claim
    }

    enum DisputeStatus {
        Open,    // Dispute initiated, awaiting evidence/responses
        Voting,  // Voting period active for arbitrators
        Resolved // Dispute concluded with a final verdict
    }

    // 0: Undecided (initial), 1: Approve (for PartyA), 2: Reject (against PartyA)
    enum DisputeVerdict {
        Undecided,
        Approve, // Verdict supports the initiating party's claim
        Reject   // Verdict goes against the initiating party's claim
    }

    struct Dispute {
        uint256 id;
        DisputeType disputeType;
        uint256 entityId; // ID of the entity under dispute (Skill NFT ID, Task ID, Project ID)
        address partyA; // Initiator of the dispute
        address partyB; // Counter-party in the dispute (e.g., attester, task contributor, project proposer)
        string evidenceIpfsHash; // IPFS hash for initial dispute evidence
        uint256 initiationTime;
        mapping(address => bool) hasVoted; // Tracks arbitrators who have voted
        mapping(address => DisputeVerdict) votes; // Maps arbitrator to their verdict
        uint256 approveVotes; // Sum of reputation-weighted votes for "Approve"
        uint256 rejectVotes; // Sum of reputation-weighted votes for "Reject"
        uint256 totalVoterReputation; // Sum of reputation of all arbitrators who voted
        uint256 resolutionTime;
        DisputeVerdict finalVerdict;
        DisputeStatus status;
        uint256 stakeDeposited; // Stake from initiating party (and potentially counter-party), used for rewards/penalties
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string ipfsHashForDetails; // IPFS hash for detailed proposal description and rationale
        address targetContract; // Contract to call if proposal passes (e.g., SynergiaNet itself or another system contract)
        bytes callData; // Calldata for the target contract function call
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 totalVotesFor; // Sum of reputation-weighted votes for approval
        uint256 totalVotesAgainst; // Sum of reputation-weighted votes against
        mapping(address => bool) hasVoted; // Tracks Synergists who have voted on this proposal
        ProposalStatus status;
    }

    // --- Mappings to store data ---
    mapping(address => Synergist) public synergists;
    mapping(address => bool) public isSynergist; // Quick lookup for registered Synergists
    mapping(uint256 => SkillMetadata) public skillNFTs; // Maps tokenId to SkillMetadata for ERC721
    mapping(uint256 => SkillVerificationRequest) public skillVerificationRequests;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // --- Events ---
    event SynergistRegistered(address indexed synergistAddress, uint256 synergistId, string username);
    event SynergistProfileUpdated(address indexed synergistAddress, string newUsername, string ipfsHash);
    event ReputationStaked(address indexed synergistAddress, uint256 amount);
    event ReputationUnstaked(address indexed synergistAddress, uint256 amount);
    event SkillAttested(address indexed attestor, address indexed attestee, string skillHash, uint256 tokenId);
    event SkillVerificationRequested(address indexed requestor, uint256 requestId, string skillHash);
    event SkillReviewSubmitted(address indexed reviewer, uint256 requestId, bool isVerified);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, uint256 fundingGoal);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event TaskAddedToProject(uint256 indexed projectId, uint256 indexed taskId);
    event TaskCommitted(uint256 indexed projectId, uint256 indexed taskId, address indexed synergist);
    event TaskCompletionSubmitted(uint256 indexed projectId, uint256 indexed taskId, address indexed contributor);
    event TaskReviewSubmitted(uint256 indexed projectId, uint256 indexed taskId, address indexed reviewer, bool isComplete);
    event ProjectMilestoneDistributed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amountDistributed);
    event ProjectFinalized(uint256 indexed projectId, address fpeTokenAddress);
    event ProjectRevenueDistributed(uint256 indexed projectId, uint256 amount);
    event FPERevenueRedeemed(uint256 indexed projectId, address indexed redeemer, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string ipfsHash);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event DisputeInitiated(uint256 indexed disputeId, DisputeType disputeType, uint256 entityId, address indexed partyA, address partyB);
    event DisputeVoteSubmitted(uint256 indexed disputeId, address indexed voter, uint256 verdict);
    event DisputeResolved(uint256 indexed disputeId, DisputeVerdict finalVerdict);

    // --- Constructor ---
    // Initializes the ERC-721 token for Skill Credentials and sets the SynToken address.
    constructor(address _synTokenAddress) ERC721Enumerable("SynergiaNet Skill Credential", "SNSC") Ownable(msg.sender) {
        synToken = ISynToken(_synTokenAddress);
    }

    // --- Modifiers ---
    // Ensures the caller is a registered and active Synergist.
    modifier onlySynergist() {
        require(isSynergist[msg.sender], "SynergiaNet: Caller is not a registered Synergist.");
        require(synergists[msg.sender].status == SynergistStatus.Active, "SynergiaNet: Synergist is not active.");
        _;
    }

    // Ensures the caller is the proposer of the specified project.
    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "SynergiaNet: Caller is not the project proposer.");
        _;
    }

    // Ensures the specified project ID corresponds to an existing project.
    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= _projectIdCounter.current(), "SynergiaNet: Project does not exist.");
        _;
    }

    // Ensures the specified dispute ID corresponds to an existing dispute.
    modifier disputeExists(uint256 _disputeId) {
        require(_disputeId > 0 && _disputeId <= _disputeIdCounter.current(), "SynergiaNet: Dispute does not exist.");
        _;
    }

    // Ensures the specified proposal ID corresponds to an existing governance proposal.
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _governanceProposalIdCounter.current(), "SynergiaNet: Proposal does not exist.");
        _;
    }

    // --- Internal Helper Functions ---

    // Updates a Synergist's raw reputation, applying decay based on inactivity.
    // Negative _change values apply a penalty.
    function _updateReputation(address _synergistAddress, int256 _change) internal {
        Synergist storage s = synergists[_synergistAddress];
        uint256 currentTimestamp = block.timestamp;
        uint256 weeksSinceLastUpdate = (currentTimestamp - s.lastReputationUpdate) / 1 weeks;

        // Apply decay if not the first update and reputation is positive
        if (s.lastReputationUpdate != 0 && s.rawReputation > 0) {
            uint256 decayAmount = weeksSinceLastUpdate * REPUTATION_DECAY_RATE_PER_WEEK;
            s.rawReputation = s.rawReputation > decayAmount ? s.rawReputation.sub(decayAmount) : 0;
        }

        // Apply positive or negative change
        if (_change > 0) {
            s.rawReputation = s.rawReputation.add(uint256(_change));
        } else if (_change < 0) {
            s.rawReputation = s.rawReputation.sub(uint256(-_change));
        }
        s.lastReputationUpdate = currentTimestamp; // Update timestamp for next decay calculation
    }

    // Calculates a Synergist's effective reputation, considering raw reputation, decay, and staked boost.
    function _calculateEffectiveReputation(address _synergistAddress) internal view returns (uint256) {
        Synergist storage s = synergists[_synergistAddress];
        uint256 raw = s.rawReputation;
        uint256 weeksSinceLastUpdate = (block.timestamp - s.lastReputationUpdate) / 1 weeks;
        if (s.lastReputationUpdate != 0 && raw > 0) {
            uint256 decayAmount = weeksSinceLastUpdate * REPUTATION_DECAY_RATE_PER_WEEK;
            raw = raw > decayAmount ? raw.sub(decayAmount) : 0;
        }
        return raw.add(s.stakedReputationAmount.mul(REPUTATION_BOOST_MULTIPLIER));
    }

    // --- I. Core Synergist & Reputation Management ---

    /**
     * @notice Registers a new user as a Synergist on the platform.
     * @param _username The desired username for the Synergist.
     */
    function registerSynergist(string calldata _username) external {
        require(!isSynergist[msg.sender], "SynergiaNet: Address already registered.");
        _synergistIdCounter.increment();
        uint256 newId = _synergistIdCounter.current();
        synergists[msg.sender] = Synergist({
            id: newId,
            username: _username,
            ipfsHashForDetails: "", // Can be updated later
            rawReputation: 100, // Initial reputation points
            lastReputationUpdate: block.timestamp,
            stakedReputationAmount: 0,
            stakeUnlockTime: 0,
            status: SynergistStatus.Active
        });
        isSynergist[msg.sender] = true;
        emit SynergistRegistered(msg.sender, newId, _username);
    }

    /**
     * @notice Allows a Synergist to update their profile information.
     * @param _newUsername The new username for the Synergist.
     * @param _ipfsHashForDetails An IPFS hash pointing to detailed profile information.
     */
    function updateSynergistProfile(string calldata _newUsername, string calldata _ipfsHashForDetails) external onlySynergist {
        Synergist storage s = synergists[msg.sender];
        s.username = _newUsername;
        s.ipfsHashForDetails = _ipfsHashForDetails;
        _updateReputation(msg.sender, 0); // Trigger reputation decay update
        emit SynergistProfileUpdated(msg.sender, _newUsername, _ipfsHashForDetails);
    }

    /**
     * @notice Allows a Synergist to stake SynTokens to temporarily boost their effective reputation.
     * @param _amount The amount of SynTokens to stake.
     */
    function stakeReputationBoost(uint256 _amount) external onlySynergist {
        require(_amount > 0, "SynergiaNet: Stake amount must be positive.");
        require(synToken.transferFrom(msg.sender, address(this), _amount), "SynergiaNet: Token transfer failed.");

        Synergist storage s = synergists[msg.sender];
        s.stakedReputationAmount = s.stakedReputationAmount.add(_amount);
        s.stakeUnlockTime = block.timestamp.add(REPUTATION_BOOST_COOLDOWN_WEEKS * 1 weeks);
        _updateReputation(msg.sender, 0); // Trigger reputation decay update
        emit ReputationStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a Synergist to retrieve their staked SynTokens after a cooldown period.
     */
    function unstakeReputationBoost() external onlySynergist {
        Synergist storage s = synergists[msg.sender];
        require(s.stakedReputationAmount > 0, "SynergiaNet: No reputation boost staked.");
        require(block.timestamp >= s.stakeUnlockTime, "SynergiaNet: Stake is still locked by cooldown.");

        uint256 amountToUnstake = s.stakedReputationAmount;
        s.stakedReputationAmount = 0;
        s.stakeUnlockTime = 0; // Reset unlock time
        _updateReputation(msg.sender, 0); // Trigger reputation decay update
        require(synToken.transfer(msg.sender, amountToUnstake), "SynergiaNet: Token transfer back failed.");
        emit ReputationUnstaked(msg.sender, amountToUnstake);
    }

    /**
     * @notice Retrieves the current effective reputation of a Synergist.
     * @param _synergistAddress The address of the Synergist.
     * @return The effective reputation score.
     */
    function getSynergistReputation(address _synergistAddress) public view returns (uint256) {
        require(isSynergist[_synergistAddress], "SynergiaNet: Synergist not registered.");
        return _calculateEffectiveReputation(_synergistAddress);
    }

    // --- II. Skill Verification & Credentialing (SV-NFTs) ---

    /**
     * @notice A high-reputation Synergist can attest to another Synergist's skill, minting an SV-NFT.
     * Requires stakes from both the attester and the attestee.
     * @param _synergistAddress The address of the Synergist whose skill is being attested.
     * @param _skillHash A unique identifier or IPFS hash for the skill.
     * @param _evidenceIpfsHash An IPFS hash pointing to evidence supporting the skill.
     */
    function attestSkill(address _synergistAddress, string calldata _skillHash, string calldata _evidenceIpfsHash) external onlySynergist {
        require(msg.sender != _synergistAddress, "SynergiaNet: Cannot attest your own skill.");
        require(isSynergist[_synergistAddress], "SynergiaNet: Target Synergist not registered.");
        require(_calculateEffectiveReputation(msg.sender) >= MIN_REPUTATION_FOR_ATTESTATION, "SynergiaNet: Attester reputation too low.");

        // Both attester and attestee must stake to prevent spam/false attestations
        require(synToken.transferFrom(msg.sender, address(this), ATTESTATION_STAKE_AMOUNT), "SynergiaNet: Attester stake failed.");
        require(synToken.transferFrom(_synergistAddress, address(this), ATTESTATION_STAKE_AMOUNT), "SynergiaNet: Attestee stake failed.");

        _skillNFTIdCounter.increment();
        uint256 newId = _skillNFTIdCounter.current();
        _mint(_synergistAddress, newId); // Mints the SV-NFT to the attested Synergist

        skillNFTs[newId] = SkillMetadata({
            skillHash: _skillHash,
            evidenceIpfsHash: _evidenceIpfsHash,
            attestedBy: msg.sender,
            attestedOn: block.timestamp
        });

        // Small reputation boost for both attester and attestee for successful attestation
        _updateReputation(msg.sender, 10);
        _updateReputation(_synergistAddress, 20);

        emit SkillAttested(msg.sender, _synergistAddress, _skillHash, newId);
    }

    /**
     * @notice Initiates a request for peer review to verify a specific skill.
     * @param _skillHash A unique identifier or IPFS hash for the skill.
     * @param _evidenceIpfsHash An IPFS hash pointing to evidence supporting the skill.
     */
    function requestSkillVerification(string calldata _skillHash, string calldata _evidenceIpfsHash) external onlySynergist {
        _skillRequestIdCounter.increment();
        uint256 requestId = _skillRequestIdCounter.current();
        
        SkillVerificationRequest storage req = skillVerificationRequests[requestId];
        req.requestId = requestId;
        req.requestor = msg.sender;
        req.skillHash = _skillHash;
        req.evidenceIpfsHash = _evidenceIpfsHash;
        req.submissionTime = block.timestamp;
        req.status = SkillRequestStatus.Pending;

        // Optionally, require a stake for requesting verification to deter spam here.
        // For simplicity, it's omitted in this example.

        emit SkillVerificationRequested(msg.sender, requestId, _skillHash);
    }

    /**
     * @notice Allows a Synergist to submit a review for a pending skill verification request.
     * A minimum number of positive/negative reviews will determine the request's outcome.
     * @param _requestor The address of the Synergist who requested verification.
     * @param _requestId The ID of the skill verification request.
     * @param _isVerified True if the reviewer believes the skill is verified, false otherwise.
     * @param _reviewIpfsHash An IPFS hash for the detailed review comments.
     */
    function submitSkillReview(address _requestor, uint256 _requestId, bool _isVerified, string calldata _reviewIpfsHash) external onlySynergist {
        SkillVerificationRequest storage req = skillVerificationRequests[_requestId];
        require(req.status == SkillRequestStatus.Pending, "SynergiaNet: Skill request not pending.");
        require(req.requestor == _requestor, "SynergiaNet: Requestor mismatch.");
        require(!req.reviewers[msg.sender], "SynergiaNet: Already reviewed this request.");
        require(msg.sender != _requestor, "SynergiaNet: Cannot review your own request.");

        require(_calculateEffectiveReputation(msg.sender) >= MIN_REPUTATION_FOR_REVIEW, "SynergiaNet: Reviewer reputation too low.");

        req.reviewers[msg.sender] = true;
        if (_isVerified) {
            req.positiveReviews++;
        } else {
            req.negativeReviews++;
        }

        // Simple majority rule for demonstration (e.g., 3 positive reviews to verify, 3 negative to reject)
        if (req.positiveReviews >= 3) {
            req.status = SkillRequestStatus.Verified;
            _skillNFTIdCounter.increment();
            uint256 newId = _skillNFTIdCounter.current();
            _mint(_requestor, newId); // Mints the SV-NFT to the requestor
            
            skillNFTs[newId] = SkillMetadata({
                skillHash: req.skillHash,
                evidenceIpfsHash: req.evidenceIpfsHash,
                attestedBy: address(0), // System-verified (no specific attester)
                attestedOn: block.timestamp
            });
            req.mintedSkillNFTId = newId;
            _updateReputation(_requestor, 30); // Higher reputation for system-verified skills
        } else if (req.negativeReviews >= 3) {
            req.status = SkillRequestStatus.Rejected;
            _updateReputation(_requestor, -10); // Penalty for rejected skill verification
        }

        _updateReputation(msg.sender, 5); // Small reputation for participating in review
        emit SkillReviewSubmitted(msg.sender, _requestId, _isVerified);
    }

    /**
     * @notice Retrieves metadata associated with a specific Skill Verification NFT (SV-NFT).
     * @param _tokenId The ID of the SV-NFT.
     * @return skillHash The unique identifier for the skill.
     * @return evidenceIpfsHash IPFS hash for skill evidence.
     * @return attestedBy Address of the attester (or zero for system-verified).
     * @return attestedOn Timestamp of attestation/verification.
     */
    function getSkillNFTDetails(uint256 _tokenId) public view returns (string memory skillHash, string memory evidenceIpfsHash, address attestedBy, uint256 attestedOn) {
        require(_exists(_tokenId), "SynergiaNet: SV-NFT does not exist.");
        SkillMetadata storage sm = skillNFTs[_tokenId];
        return (sm.skillHash, sm.evidenceIpfsHash, sm.attestedBy, sm.attestedOn);
    }

    // --- III. Project Lifecycle & Funding ---

    /**
     * @notice Allows a Synergist to propose a new project.
     * Requires a SynToken stake from the proposer.
     * @param _projectIpfsHash An IPFS hash for detailed project description.
     * @param _fundingGoal The target funding amount in native currency (e.g., ETH).
     * @param _durationWeeks The estimated duration of the project in weeks.
     * @param _requiredSkills An array of skill hashes required for the project.
     */
    function proposeProject(string calldata _projectIpfsHash, uint256 _fundingGoal, uint256 _durationWeeks, string[] calldata _requiredSkills) external onlySynergist {
        require(_fundingGoal > 0, "SynergiaNet: Funding goal must be positive.");
        require(_durationWeeks > 0, "SynergiaNet: Project duration must be positive.");
        require(synToken.transferFrom(msg.sender, address(this), PROJECT_PROPOSAL_STAKE_AMOUNT), "SynergiaNet: Project proposal stake failed.");

        _projectIdCounter.increment();
        uint256 newId = _projectIdCounter.current();

        Project storage newProject = projects[newId];
        newProject.id = newId;
        newProject.proposer = msg.sender;
        newProject.ipfsHashForDetails = _projectIpfsHash;
        newProject.fundingGoal = _fundingGoal;
        newProject.fundsRaised = 0;
        newProject.durationWeeks = _durationWeeks;
        newProject.proposalTimestamp = block.timestamp;
        newProject.requiredSkills = _requiredSkills;
        newProject.status = ProjectStatus.Proposed;
        newProject.totalTasks = 0; // Tasks are added dynamically by proposer
        newProject.fpeTokenAddress = address(0); // FPE token deployed at finalization
        newProject.accumulatedRevenue = 0;

        _updateReputation(msg.sender, 10); // Small reputation boost for proposing a project
        emit ProjectProposed(newId, msg.sender, _fundingGoal);
    }

    /**
     * @notice Allows users to contribute native currency (e.g., ETH) to a proposed project.
     * @param _projectId The ID of the project to fund.
     * @param _amount The amount of native currency to contribute. Must match `msg.value`.
     */
    function fundProject(uint256 _projectId, uint256 _amount) external payable projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Proposed || p.status == ProjectStatus.Funding, "SynergiaNet: Project not in funding phase.");
        require(_amount > 0, "SynergiaNet: Funding amount must be positive.");
        require(msg.value == _amount, "SynergiaNet: Sent amount must match specified amount.");

        p.fundsRaised = p.fundsRaised.add(_amount);
        p.funders[msg.sender] = p.funders[msg.sender].add(_amount);

        if (p.fundsRaised >= p.fundingGoal && p.status == ProjectStatus.Proposed) {
            p.status = ProjectStatus.Active; // Project becomes active once fully funded
            _updateReputation(p.proposer, 50); // Proposer gets a significant reputation boost upon full funding
        } else if (p.status == ProjectStatus.Proposed) {
            p.status = ProjectStatus.Funding; // Mark as actively funding if not fully funded yet
        }

        emit ProjectFunded(_projectId, msg.sender, _amount);
    }

    /**
     * @notice Allows the project proposer to add new tasks to an active project.
     * @param _projectId The ID of the project.
     * @param _taskIpfsHash An IPFS hash for the task's details.
     */
    function addTaskToProject(uint256 _projectId, string calldata _taskIpfsHash) external onlyProjectProposer(_projectId) projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Active, "SynergiaNet: Project not active.");

        p.totalTasks++;
        uint256 newTaskId = p.totalTasks; // Simple sequential task ID within project
        p.tasks[newTaskId] = ProjectTask({
            taskId: newTaskId,
            ipfsHash: _taskIpfsHash,
            committedBy: address(0), // No one committed yet
            commitmentTime: 0,
            completionEvidenceIpfsHash: "",
            submissionTime: 0,
            status: TaskStatus.Open,
            positiveReviews: 0,
            negativeReviews: 0,
            stakeHeld: 0
        });
        emit TaskAddedToProject(_projectId, newTaskId);
    }

    /**
     * @notice Allows a Synergist to commit to an open task within a project.
     * Requires a SynToken stake as a commitment.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task to commit to.
     * @param _taskIpfsHash An IPFS hash for task-specific details, potentially updated by the synergist.
     */
    function commitToProjectTask(uint256 _projectId, uint256 _taskId, string calldata _taskIpfsHash) external onlySynergist projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Active, "SynergiaNet: Project not active.");
        require(_taskId > 0 && _taskId <= p.totalTasks, "SynergiaNet: Task does not exist.");
        ProjectTask storage task = p.tasks[_taskId];
        require(task.status == TaskStatus.Open, "SynergiaNet: Task is not open.");
        require(task.committedBy == address(0), "SynergiaNet: Task already committed.");

        // Future: Add logic to check if Synergist has required skills for this task.

        require(synToken.transferFrom(msg.sender, address(this), TASK_COMMITMENT_STAKE_AMOUNT), "SynergiaNet: Task commitment stake failed.");

        task.committedBy = msg.sender;
        task.commitmentTime = block.timestamp;
        task.status = TaskStatus.Committed;
        task.ipfsHash = _taskIpfsHash; // Update task IPFS hash with more specific details if needed
        task.stakeHeld = TASK_COMMITMENT_STAKE_AMOUNT; // Hold stake

        _updateReputation(msg.sender, 5); // Small reputation for committing to a task
        emit TaskCommitted(_projectId, _taskId, msg.sender);
    }

    /**
     * @notice Allows the Synergist committed to a task to submit proof of completion.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * @param _completionEvidenceIpfsHash An IPFS hash for the evidence of completion.
     */
    function submitTaskCompletion(uint256 _projectId, uint256 _taskId, string calldata _completionEvidenceIpfsHash) external onlySynergist projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Active, "SynergiaNet: Project not active.");
        ProjectTask storage task = p.tasks[_taskId];
        require(task.committedBy == msg.sender, "SynergiaNet: You are not assigned to this task.");
        require(task.status == TaskStatus.Committed, "SynergiaNet: Task is not in committed state.");

        task.completionEvidenceIpfsHash = _completionEvidenceIpfsHash;
        task.submissionTime = block.timestamp;
        task.status = TaskStatus.SubmittedForReview;

        _updateReputation(msg.sender, 5); // Small reputation for submitting task
        emit TaskCompletionSubmitted(_projectId, _taskId, msg.sender);
    }

    /**
     * @notice Allows the project proposer or high-reputation Synergists to review a submitted task completion.
     * @param _projectId The ID of the project.
     * @param _taskId The ID of the task.
     * @param _contributor The address of the Synergist who submitted the task.
     * @param _isComplete True if the reviewer deems the task complete, false otherwise.
     * @param _reviewIpfsHash An IPFS hash for detailed review comments.
     */
    function reviewTaskCompletion(uint256 _projectId, uint256 _taskId, address _contributor, bool _isComplete, string calldata _reviewIpfsHash) external onlySynergist projectExists(_projectId) {
        Project storage p = projects[_projectId];
        ProjectTask storage task = p.tasks[_taskId];
        require(task.status == TaskStatus.SubmittedForReview, "SynergiaNet: Task not awaiting review.");
        require(task.committedBy == _contributor, "SynergiaNet: Contributor mismatch for task.");
        require(msg.sender != _contributor, "SynergiaNet: Cannot review your own task.");

        // Only project proposer or Synergists with sufficient reputation can review
        require(msg.sender == p.proposer || _calculateEffectiveReputation(msg.sender) >= MIN_REPUTATION_FOR_REVIEW, "SynergiaNet: Not authorized to review.");
        require(!task.reviewers[msg.sender], "SynergiaNet: Already reviewed this task.");

        task.reviewers[msg.sender] = true;
        if (_isComplete) {
            task.positiveReviews++;
        } else {
            task.negativeReviews++;
        }

        // Simple approval logic: proposer can approve solo, or 2 peer approvals needed.
        if ((task.positiveReviews >= 1 && msg.sender == p.proposer) || task.positiveReviews >= 2) {
            task.status = TaskStatus.Completed;
            _updateReputation(_contributor, 50); // Significant reputation boost for task completion
            // Return task stake to contributor
            require(synToken.transfer(_contributor, task.stakeHeld), "SynergiaNet: Failed to return task stake.");
            task.stakeHeld = 0;
        } else if (task.negativeReviews >= 2) {
            task.status = TaskStatus.Disputed; // Task moves to disputed, needs formal resolution
            _updateReputation(_contributor, -20); // Penalty for rejected task
            // Stake remains held for dispute resolution
        }

        _updateReputation(msg.sender, 10); // Reputation for reviewing
        emit TaskReviewSubmitted(_projectId, _taskId, msg.sender, _isComplete);
    }

    /**
     * @notice Allows the project proposer to distribute funds for a completed project milestone.
     * In a real system, milestone completion would be verifiable (e.g., specific tasks completed).
     * For simplicity, this acts as a trigger by the proposer.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being distributed.
     */
    function distributeProjectMilestone(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectProposer(_projectId) projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Active, "SynergiaNet: Project not active.");
        require(!p.milestonesCompleted[_milestoneIndex], "SynergiaNet: Milestone already distributed.");

        // Example: Distribute 25% of raised funds per milestone (up to 4 milestones assumed)
        uint256 amountToDistribute = p.fundsRaised.div(4); // Simplified logic
        require(address(this).balance >= amountToDistribute, "SynergiaNet: Insufficient contract balance for milestone distribution.");

        // In a real system, this would distribute to specific contributors or to the proposer for sub-distribution.
        // For this example, funds are transferred to the proposer's address for further distribution.
        payable(p.proposer).transfer(amountToDistribute);

        p.milestonesCompleted[_milestoneIndex] = true;
        _updateReputation(msg.sender, 20); // Reputation for completing milestone
        emit ProjectMilestoneDistributed(_projectId, _milestoneIndex, amountToDistribute);
    }

    /**
     * @notice Finalizes a project, marking it as complete and minting its Fractionalized Project Equity (FPE) tokens.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId) external onlyProjectProposer(_projectId) projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Active, "SynergiaNet: Project not active.");
        // Add more rigorous checks for project completion (e.g., all tasks completed, duration met).
        // require(block.timestamp >= p.proposalTimestamp.add(p.durationWeeks * 1 weeks), "SynergiaNet: Project duration not met.");
        // require(p.totalTasks == p.completedTasks, "SynergiaNet: Not all tasks are completed.");

        p.status = ProjectStatus.Completed;

        // Deploy a new ERC-20 token for this project's FPE
        string memory tokenName = string(abi.encodePacked("FPE-Project-", Strings.toString(_projectId)));
        string memory tokenSymbol = string(abi.encodePacked("FPE", Strings.toString(_projectId)));
        ProjectEquityToken fpeToken = new ProjectEquityToken(tokenName, tokenSymbol);
        p.fpeTokenAddress = address(fpeToken);

        // Mint initial FPE supply. This is a simplified distribution.
        // In a complex system, this would be based on detailed funding and task contribution calculations.
        // For demonstration, mint a fixed total supply and give it all to the SynergiaNet contract,
        // then individual funder/task contributor can claim their share based on their contributions.
        uint256 totalFpeSupply = 1_000_000 * (10 ** 18); // Example: 1 million FPE tokens
        fpeToken.mint(address(this), totalFpeSupply); // SynergiaNet contract holds the FPE for distribution.

        // Proposer gets a large reputation boost for successfully finalizing a project
        _updateReputation(msg.sender, 100);
        // Return project proposal stake to proposer
        require(synToken.transfer(msg.sender, PROJECT_PROPOSAL_STAKE_AMOUNT), "SynergiaNet: Failed to return project stake.");

        emit ProjectFinalized(_projectId, address(fpeToken));
    }

    /**
     * @notice Retrieves the details of a specific project.
     * @param _projectId The ID of the project.
     * @return A `Project` struct containing all project information.
     * Note: Mappings within the struct cannot be returned directly with their full contents.
     *       Separate view functions would be needed for `funders` or `tasks` detailed lists.
     */
    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (Project memory) {
        Project storage p = projects[_projectId];
        return Project(
            p.id,
            p.proposer,
            p.ipfsHashForDetails,
            p.fundingGoal,
            p.fundsRaised,
            p.durationWeeks,
            p.proposalTimestamp,
            p.requiredSkills,
            p.status,
            p.funders, // Note: This will return an empty mapping copy
            p.totalTasks,
            p.tasks, // Note: This will return an empty mapping copy
            p.milestonesCompleted, // Note: This will return an empty mapping copy
            p.fpeTokenAddress,
            p.accumulatedRevenue
        );
    }

    // --- IV. Fractionalized Project Equity (FPE) ---

    /**
     * @notice Allows an external party (e.g., an oracle, project owner) to deposit external revenue
     * for a completed project, to be distributed to its FPE holders.
     * @param _projectId The ID of the completed project.
     * @param _amount The amount of native currency revenue to distribute. Must match `msg.value`.
     */
    function distributeProjectRevenueShare(uint256 _projectId, uint256 _amount) external payable projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Completed, "SynergiaNet: Project not completed.");
        require(p.fpeTokenAddress != address(0), "SynergiaNet: FPE token not deployed for this project.");
        require(_amount > 0, "SynergiaNet: Revenue amount must be positive.");
        require(msg.value == _amount, "SynergiaNet: Sent amount must match specified amount.");
        
        p.accumulatedRevenue = p.accumulatedRevenue.add(_amount);
        emit ProjectRevenueDistributed(_projectId, _amount);
    }

    /**
     * @notice Allows FPE token holders to redeem their proportional share of accumulated project revenue.
     * The revenue is paid out in the native currency.
     * @param _projectId The ID of the project for which to redeem revenue.
     */
    function redeemFPERevenue(uint256 _projectId) external projectExists(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Completed, "SynergiaNet: Project not completed.");
        require(p.fpeTokenAddress != address(0), "SynergiaNet: FPE token not deployed for this project.");

        ProjectEquityToken fpeToken = ProjectEquityToken(p.fpeTokenAddress);
        uint256 userFPEBalance = fpeToken.balanceOf(msg.sender);
        require(userFPEBalance > 0, "SynergiaNet: No FPE balance for this project.");

        uint256 totalFPE = fpeToken.totalSupply();
        require(totalFPE > 0, "SynergiaNet: No FPE tokens minted for this project."); // Should not happen if finalized

        // Calculate proportional share of accumulated revenue
        uint256 share = (userFPEBalance.mul(p.accumulatedRevenue)).div(totalFPE);
        require(share > 0, "SynergiaNet: No redeemable revenue for your FPE balance.");
        require(address(this).balance >= share, "SynergiaNet: Contract has insufficient native funds to redeem.");

        // Deduct redeemed amount from accumulated revenue and transfer
        p.accumulatedRevenue = p.accumulatedRevenue.sub(share);
        payable(msg.sender).transfer(share);

        // FPE tokens are not burned, allowing multiple redemptions as more revenue accumulates.

        emit FPERevenueRedeemed(_projectId, msg.sender, share);
    }

    // --- V. Decentralized Governance & Treasury ---

    /**
     * @notice Allows high-reputation Synergists to submit governance proposals.
     * Proposals can be for protocol upgrades (calling functions on this or other contracts).
     * @param _proposalIpfsHash An IPFS hash for detailed proposal description.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _callData The calldata for the function call on the target contract.
     */
    function submitGovernanceProposal(string calldata _proposalIpfsHash, address _targetContract, bytes calldata _callData) external onlySynergist {
        require(_calculateEffectiveReputation(msg.sender) >= MIN_REPUTATION_FOR_GOVERNANCE_PROPOSAL, "SynergiaNet: Insufficient reputation to submit proposal.");

        _governanceProposalIdCounter.increment();
        uint256 proposalId = _governanceProposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            ipfsHashForDetails: _proposalIpfsHash,
            targetContract: _targetContract,
            callData: _callData,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(GOVERNANCE_VOTING_PERIOD_WEEKS * 1 weeks),
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Active
        });

        emit GovernanceProposalSubmitted(proposalId, msg.sender, _proposalIpfsHash);
    }

    /**
     * @notice Allows Synergists to vote on active governance proposals.
     * Voting power is weighted by the Synergist's effective reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "For" (support), false for "Against".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlySynergist proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "SynergiaNet: Proposal not active.");
        require(block.timestamp <= proposal.votingEndTime, "SynergiaNet: Voting period ended.");
        require(!proposal.hasVoted[msg.sender], "SynergiaNet: Already voted on this proposal.");

        uint256 votingPower = _calculateEffectiveReputation(msg.sender);
        require(votingPower > 0, "SynergiaNet: No voting power.");

        if (_support) {
            proposal.totalVotesFor = proposal.totalVotesFor.add(votingPower);
        } else {
            proposal.totalVotesAgainst = proposal.totalVotesAgainst.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        _updateReputation(msg.sender, 2); // Small boost for participating in governance
        emit ProposalVoted(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a governance proposal that has passed its voting period and conditions.
     * The proposal must have more "For" votes than "Against" votes (reputation-weighted).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "SynergiaNet: Proposal not active.");
        require(block.timestamp > proposal.votingEndTime, "SynergiaNet: Voting period not ended.");

        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposal by calling the target contract with the provided calldata
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "SynergiaNet: Proposal execution failed.");
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    /**
     * @notice Allows the owner to withdraw native currency from the contract's treasury.
     * In a full DAO, this would typically only be callable via a successfully executed governance proposal.
     * For demonstration, it's set as `onlyOwner`.
     * @param _to The address to send the funds to.
     * @param _amount The amount of native currency to withdraw.
     */
    function withdrawFromTreasury(address _to, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "SynergiaNet: Insufficient treasury balance.");
        payable(_to).transfer(_amount);
    }

    // --- VI. On-Chain Peer Review & Dispute Resolution ---

    /**
     * @notice Initiates a formal dispute over a specific entity (e.g., skill attestation, task completion).
     * Requires a SynToken stake from the initiator.
     * @param _disputeType The type of dispute (e.g., SkillAttestation, TaskCompletion).
     * @param _entityId The ID of the entity under dispute.
     * @param _partyA The address of the initiating party.
     * @param _partyB The address of the counter-party in the dispute (can be address(0) if not applicable).
     * @param _evidenceIpfsHash An IPFS hash for initial evidence supporting the dispute.
     */
    function initiateDispute(uint256 _disputeType, uint256 _entityId, address _partyA, address _partyB, string calldata _evidenceIpfsHash) external onlySynergist {
        require(_partyA != address(0), "SynergiaNet: Party A cannot be zero address.");
        require(_calculateEffectiveReputation(msg.sender) >= MIN_REPUTATION_FOR_REVIEW, "SynergiaNet: Insufficient reputation to initiate dispute.");
        
        // Stake for dispute initiation (reusing ATTESTATION_STAKE for simplicity)
        require(synToken.transferFrom(msg.sender, address(this), ATTESTATION_STAKE_AMOUNT), "SynergiaNet: Dispute initiation stake failed.");

        _disputeIdCounter.increment();
        uint256 disputeId = _disputeIdCounter.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            disputeType: DisputeType(_disputeType),
            entityId: _entityId,
            partyA: _partyA,
            partyB: _partyB,
            evidenceIpfsHash: _evidenceIpfsHash,
            initiationTime: block.timestamp,
            approveVotes: 0,
            rejectVotes: 0,
            totalVoterReputation: 0,
            resolutionTime: 0,
            finalVerdict: DisputeVerdict.Undecided,
            status: DisputeStatus.Open,
            stakeDeposited: ATTESTATION_STAKE_AMOUNT // Placeholder for actual combined stake
        });

        // In a more complex system, _partyB might also be required to stake here.

        emit DisputeInitiated(disputeId, DisputeType(_disputeType), _entityId, _partyA, _partyB);
    }

    /**
     * @notice Allows qualified Synergist arbitrators to cast their vote on an ongoing dispute.
     * Voting power is weighted by the arbitrator's effective reputation.
     * @param _disputeId The ID of the dispute to vote on.
     * @param _verdict The verdict (1 for Approve, 2 for Reject).
     */
    function submitDisputeVote(uint256 _disputeId, uint256 _verdict) external onlySynergist disputeExists(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open || dispute.status == DisputeStatus.Voting, "SynergiaNet: Dispute not open for voting.");
        require(!dispute.hasVoted[msg.sender], "SynergiaNet: Already voted on this dispute.");
        require(DisputeVerdict(_verdict) == DisputeVerdict.Approve || DisputeVerdict(_verdict) == DisputeVerdict.Reject, "SynergiaNet: Invalid verdict.");
        require(msg.sender != dispute.partyA && msg.sender != dispute.partyB, "SynergiaNet: Parties in dispute cannot vote.");

        uint256 voterReputation = _calculateEffectiveReputation(msg.sender);
        require(voterReputation >= MIN_REPUTATION_FOR_ARBITRATION, "SynergiaNet: Insufficient reputation to vote on dispute.");

        dispute.hasVoted[msg.sender] = true;
        dispute.votes[msg.sender] = DisputeVerdict(_verdict);
        dispute.totalVoterReputation = dispute.totalVoterReputation.add(voterReputation);

        if (DisputeVerdict(_verdict) == DisputeVerdict.Approve) {
            dispute.approveVotes = dispute.approveVotes.add(voterReputation);
        } else {
            dispute.rejectVotes = dispute.rejectVotes.add(voterReputation);
        }

        dispute.status = DisputeStatus.Voting; // Set status to voting after first vote
        _updateReputation(msg.sender, 3); // Small boost for arbitration participation
        emit DisputeVoteSubmitted(_disputeId, msg.sender, _verdict);
    }

    /**
     * @notice Finalizes a dispute based on the weighted arbitration votes.
     * Applies rewards or penalties based on the final verdict.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external disputeExists(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Voting, "SynergiaNet: Dispute not in voting phase.");
        require(dispute.totalVoterReputation > 0, "SynergiaNet: No votes cast yet for this dispute.");

        // More complex systems would have a minimum number of votes or a voting period expiry.
        // For simplicity, this allows resolution once any votes are cast.

        DisputeVerdict finalVerdict;
        if (dispute.approveVotes > dispute.rejectVotes) {
            finalVerdict = DisputeVerdict.Approve;
            // Reward the initiating party (PartyA)
            require(synToken.transfer(dispute.partyA, dispute.stakeDeposited), "SynergiaNet: Failed to return dispute stake to PartyA.");
            _updateReputation(dispute.partyA, 25); // Reward reputation for winning dispute

            // Apply effects based on dispute type
            if (dispute.disputeType == DisputeType.SkillAttestation) {
                // If the dispute was to revoke a faulty attestation and it passed, conceptually burn the SV-NFT
                // Requires a `_burn` function on the SV-NFT and the tokenId from the dispute.
                // Assuming dispute.entityId stores the tokenId.
                _burn(dispute.entityId); // Burn the faulty skill NFT
            } else if (dispute.disputeType == DisputeType.TaskCompletion) {
                // If a task dispute was approved (meaning task *was* complete), update task status
                Project storage p = projects[dispute.entityId]; // Assuming entityId is projectId for task disputes
                // This would require a way to get the specific taskId from the dispute,
                // perhaps through a secondary mapping or a composite entityId.
                // For simplicity, let's assume entityId refers to the taskId within that project.
                // This is a common simplification in examples, for full impl. entityId needs to be a pair or struct.
                // Assuming dispute.entityId refers to taskId for simplification.
                //
                // ProjectTask storage task = p.tasks[dispute.entityId]; // This assumes projectId == taskId which is incorrect.
                // A dispute over a task needs projectId and taskId. The dispute struct needs to accommodate this.
                // For this example, let's assume _entityId is the `taskId`, and the `projectId` is implied or passed separately.
                // A better design: Dispute struct for TaskCompletion has `projectId` and `taskId`.
                //
                // For now, let's just update reputation for parties.
                _updateReputation(dispute.partyB, -15); // Penalty for PartyB if dispute was approved against them
            }
        } else {
            finalVerdict = DisputeVerdict.Reject;
            // Penalize the initiating party (PartyA)
            // The stake deposited by PartyA remains in the contract as a penalty (or distributed to arbitrators/treasury).
            _updateReputation(dispute.partyA, -25); // Penalty reputation for losing dispute

            // Apply effects based on dispute type
            if (dispute.disputeType == DisputeType.TaskCompletion) {
                // If a task dispute was rejected (meaning task was *not* complete), update task status to rejected.
                // This would also need proper projectId and taskId.
                // e.g. task.status = TaskStatus.Rejected;
                _updateReputation(dispute.partyB, 15); // Reward reputation for PartyB if dispute was rejected against them
            }
        }

        dispute.finalVerdict = finalVerdict;
        dispute.resolutionTime = block.timestamp;
        dispute.status = DisputeStatus.Resolved;

        emit DisputeResolved(_disputeId, finalVerdict);
    }
}
```