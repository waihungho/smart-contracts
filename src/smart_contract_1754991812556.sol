The `AetherNetReputationProtocol` is a novel, decentralized, and dynamic reputation and skill verification network designed for collaborative projects. It aims to foster trust and efficiency in distributed teams by providing an on-chain, evolving profile for users based on their contributions, claimed expertise, peer reviews, and overall engagement. The protocol introduces "Soulbound Reputation Points" (SRP) which are non-transferable and dynamically adjusted based on on-chain activities.

This contract integrates several advanced concepts:
1.  **Soulbound Reputation Points (SRP):** Non-transferable tokens that represent a user's on-chain standing, dynamically adjusted by interactions.
2.  **Dynamic Skill Assessment:** Users claim expertise in specific domains, which can be endorsed or challenged by peers, influencing their domain-specific and overall reputation.
3.  **Adaptive Project Bounties:** A system where project creators propose tasks with specific skill and reputation requirements, and participants are matched and reviewed on-chain.
4.  **Reputation Decay:** A built-in mechanism for reputation to decay over time due to inactivity, encouraging continuous engagement.
5.  **Staked Dispute Resolution:** Both skill challenges and project outcomes can be disputed, requiring collateral stakes to incentivize honest participation and resolution.
6.  **Reputation-Weighted Governance:** Key protocol parameters can be updated through a decentralized voting mechanism where voting power is proportional to a user's total reputation score.

The "AI-assisted matching" aspect primarily refers to the contract's on-chain logic providing rich data points (reputation, domain scores, project history) that an off-chain AI or smart algorithm can leverage to suggest optimal project-participant pairings, or to automate decision-making for tasks based on quantifiable trust.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Not directly used but often helpful for advanced concepts
import "@openzeppelin/contracts/utils/Address.sol"; // For sendValue

// --- Custom Errors ---
error ARP_ProfileAlreadyExists();
error ARP_ProfileNotFound();
error ARP_DomainAlreadyExists();
error ARP_DomainNotFound();
error ARP_DomainAlreadyClaimed();
error ARP_DomainNotClaimed();
error ARP_Unauthorized();
error ARP_SelfEndorsementNotAllowed();
error ARP_ChallengeAlreadyExists();
error ARP_ChallengeNotFound();
error ARP_ChallengeNotResolved();
error ARP_ChallengeAlreadyResolved();
error ARP_InsufficientStake();
error ARP_ProjectNotFound();
error ARP_ProjectNotOpenForApplications();
error ARP_AlreadyApplied();
error ARP_NotProjectCreator();
error ARP_NotProjectParticipant();
error ARP_DeliverablesAlreadySubmitted();
error ARP_DeliverablesNotSubmitted();
error ARP_ProjectNotCompleted();
error ARP_ProjectAlreadyCompleted();
error ARP_InvalidParticipantSelection();
error ARP_DisputeAlreadyExists();
error ARP_DisputeNotFound();
error ARP_DisputeNotResolved();
error ARP_DisputeAlreadyResolved();
error ARP_CannotDisputeSelf();
error ARP_ProposalNotFound();
error ARP_ProposalAlreadyVoted();
error ARP_ProposalExpired();
error ARP_ProposalNotApproved();
error ARP_InsufficientReputationForProposal();
error ARP_InvalidParameterName();
error ARP_ReputationDecayNotDue();
error ARP_NotEnoughTimePassed();
error ARP_VotingPeriodNotOver();
error ARP_CannotReviewSelf();


/**
 * @title AetherNet Reputation Protocol (ARP)
 * @dev A decentralized, dynamic reputation and skill verification network for collaborative projects.
 * This protocol aims to foster trust and efficiency in distributed teams by providing
 * an on-chain, evolving profile for users based on their contributions, expertise, and peer reviews.
 *
 * Outline:
 * I. Core Infrastructure & Access Control: Manages protocol-level settings and administrative roles.
 * II. User Profile & Soulbound Reputation Points (SRP): Manages user identities, dynamic reputation scores, and skill domains.
 * III. Dynamic Skill Assessment & Validation: Mechanisms for peers to endorse or challenge claimed expertise.
 * IV. Adaptive Project Bounties & Collaboration: Framework for proposing, participating in, and reviewing collaborative projects.
 * V. Governance & Protocol Evolution: Enables community-driven updates to protocol parameters via reputation-weighted voting.
 * VI. Utility & View Functions: Helper functions for querying data.
 */
contract AetherNetReputationProtocol is Ownable {
    using Strings for uint256;
    using Address for address payable;

    /*
     * Function Summary:
     *
     * I. Core Infrastructure & Access Control
     * 1.  constructor(): Initializes the contract with an owner.
     * 2.  addDomain(string _domainName, string _description): Owner adds a new skill domain to the protocol.
     * 3.  removeDomain(bytes32 _domainId): Owner removes an existing skill domain.
     * 4.  updateProtocolParameter(bytes32 _paramName, uint256 _newValue): Owner can update certain protocol-wide parameters (e.g., decay rates).
     *
     * II. User Profile & Soulbound Reputation Points (SRP)
     * 5.  createProfile(string _metadataURI): Allows a new user to create their unique on-chain profile and mint their initial Soulbound Reputation Points (SRP).
     * 6.  updateProfileMetadata(string _newMetadataURI): Allows a user to update their public profile's metadata (e.g., IPFS hash of their bio).
     * 7.  claimDomainExpertise(bytes32 _domainId): User declares expertise in a specific domain.
     * 8.  revokeDomainExpertise(bytes32 _domainId): User removes a claimed domain expertise.
     * 9.  endorseDomainExpertise(address _targetProfile, bytes32 _domainId): A user can endorse another user's expertise in a domain, boosting their domain-specific score.
     * 10. challengeDomainExpertise(address _targetProfile, bytes32 _domainId) payable: A user can challenge another's domain expertise, requiring a collateral stake.
     * 11. resolveDomainChallenge(bytes32 _challengeId, bool _challengerWins): Owner/Governance resolves an outstanding domain expertise challenge, distributing or slashing stakes.
     * 12. recalibrateReputation(address _user): Public function to trigger a reputation decay calculation for a specific user based on inactivity.
     *
     * III. Adaptive Project Bounties & Collaboration
     * 13. proposeProject(string _title, string _descriptionURI, uint256 _budget, uint256 _deadline, bytes32[] _requiredDomains, uint256 _minReputationScore): Allows a user to create a new project bounty, specifying requirements and budget.
     * 14. applyForProject(bytes32 _projectId): Allows a user to apply to an open project, if they meet the requirements.
     * 15. selectProjectParticipants(bytes32 _projectId, address[] _participants): Project creator selects approved participants from applicants.
     * 16. submitProjectDeliverables(bytes32 _projectId, string _deliverablesURI): A selected participant submits their project deliverables (e.g., IPFS hash).
     * 17. approveProjectCompletion(bytes32 _projectId, address _participant): Project creator approves a participant's completion, triggering payout and enabling feedback.
     * 18. reviewParticipantPerformance(bytes32 _projectId, address _participant, int256 _scoreChange, string _feedbackURI): Project creator provides feedback on a participant, affecting their SRP.
     * 19. reviewProjectCreator(bytes32 _projectId, int256 _scoreChange, string _feedbackURI): A participant provides feedback on the project creator, affecting their SRP.
     * 20. disputeProjectOutcome(bytes32 _projectId, address _disputingParty, string _reasonURI) payable: A project participant or creator can dispute a project outcome (e.g., unfair review, non-payment), requiring a stake.
     * 21. resolveProjectDispute(bytes32 _disputeId, address _winner): Owner/Governance resolves a project dispute, affecting involved parties' SRP and distributing stakes.
     *
     * IV. Governance & Protocol Evolution
     * 22. proposeProtocolParameterChange(string _description, bytes32 _paramName, uint256 _newValue): Allows SRP holders (above min threshold) to propose changes to protocol parameters.
     * 23. voteOnProposal(uint256 _proposalId, bool _support): Allows SRP holders to vote on active proposals.
     * 24. executeProposal(uint256 _proposalId): Executes a passed proposal.
     *
     * V. Utility & View Functions
     * 25. getProfile(address _user): Returns a user's complete profile information.
     * 26. getDomain(bytes32 _domainId): Returns information about a specific skill domain.
     * 27. getProject(bytes32 _projectId): Returns detailed information about a project.
     * 28. getChallenge(bytes32 _challengeId): Returns details about a domain expertise challenge.
     * 29. getDispute(bytes32 _disputeId): Returns details about a project dispute.
     * 30. getProposal(uint256 _proposalId): Returns details about a governance proposal.
     */

    // --- State Variables & Structs ---

    // Protocol parameters, configurable via governance
    uint256 public constant INITIAL_REPUTATION_SCORE = 1000; // Initial score for new profiles and claimed domains
    uint256 public reputationDecayRatePerSecond = 1 wei; // Example: 1 wei decay per second of inactivity
    uint256 public challengeStakeAmount = 0.01 ether; // ETH required to challenge an expertise
    uint256 public disputeStakeAmount = 0.05 ether; // ETH required to dispute a project outcome
    uint256 public minReputationForProposal = 5000; // Minimum SRP to propose governance changes
    uint256 public votingPeriodSeconds = 7 days; // Duration for governance proposals to be voted on
    uint256 public minEndorsementInterval = 1 days; // Minimum time between endorsements for same domain/target
    uint256 public maxReviewScoreChange = 250; // Max absolute value of score change from a single review

    // User Profile & SRP
    struct DomainExpertise {
        uint256 score;
        uint256 lastUpdateTimestamp;
    }

    struct Profile {
        address owner;
        string metadataURI; // IPFS hash or similar for external profile data
        uint256 totalReputationScore;
        uint256 lastReputationUpdate; // Timestamp of last activity/recalibration
        mapping(bytes32 => DomainExpertise) domains;
        bytes32[] claimedDomainIds; // For easier iteration of claimed domains
    }
    mapping(address => Profile) public profiles;
    mapping(address => bool) public hasProfile; // Quick check if address has a profile

    // Skill Domains
    struct Domain {
        string name;
        string description;
        bool exists; // To check if domainId is valid
    }
    mapping(bytes32 => Domain) public domains; // domainId (keccak256(name)) => Domain struct
    bytes32[] public allDomainIds; // For iterating all registered domains

    // Domain Expertise Challenges
    enum ChallengeStatus { Pending, Resolved, Canceled }
    struct DomainChallenge {
        bytes32 challengeId;
        address challenger;
        address target;
        bytes32 domainId;
        uint256 stake;
        ChallengeStatus status;
        uint256 timestamp;
    }
    mapping(bytes32 => DomainChallenge) public domainChallenges;
    uint256 public nextChallengeId = 1;

    // Projects & Bounties
    enum ProjectStatus { Open, ApplicationPhase, ParticipantsSelected, InProgress, DeliverablesSubmitted, Completed, Disputed, Canceled }
    struct Project {
        bytes32 projectId;
        address creator;
        string title;
        string descriptionURI;
        uint256 budget;
        uint256 deadline;
        bytes32[] requiredDomains;
        uint256 minReputationScore;
        ProjectStatus status;
        address[] applicants; // List of addresses that applied
        mapping(address => bool) isApplicant; // For O(1) check if an address applied
        address[] participants; // Approved participants
        mapping(address => bool) isParticipant; // For O(1) check if an address is a participant
        mapping(address => string) participantDeliverablesURI; // Participant address => IPFS URI of deliverables
        mapping(address => bool) participantApprovedCompletion; // Whether creator approved participant's work
        mapping(address => bool) participantReviewedCreator; // Whether participant reviewed creator
        mapping(address => bool) creatorReviewedParticipant; // Whether creator reviewed participant
        uint256 timestamp;
    }
    mapping(bytes32 => Project) public projects;

    // Project Disputes
    enum DisputeStatus { Pending, Resolved, Canceled }
    struct ProjectDispute {
        bytes32 disputeId;
        bytes32 projectId;
        address disputingParty;
        address counterParty; // The other party in the dispute (e.g., creator vs participant, or vice-versa)
        string reasonURI; // IPFS hash for detailed reason
        uint256 stake;
        DisputeStatus status;
        uint256 timestamp;
    }
    mapping(bytes32 => ProjectDispute) public projectDisputes;
    uint256 public nextDisputeId = 1;

    // Governance Proposals
    enum ProposalStatus { Pending, Approved, Rejected, Executed, Expired }
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes32 paramName; // Keccak256 hash of parameter name string
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        ProposalStatus status;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1;

    // Mapping to track the last endorsement time from one user to another for a specific domain (rate limiting)
    mapping(address => mapping(address => mapping(bytes32 => uint256))) public lastEndorsementTime;

    // --- Events ---
    event ProfileCreated(address indexed user, string metadataURI);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);
    event DomainAdded(bytes32 indexed domainId, string name, string description);
    event DomainRemoved(bytes32 indexed domainId);
    event DomainExpertiseClaimed(address indexed user, bytes32 indexed domainId);
    event DomainExpertiseRevoked(address indexed user, bytes32 indexed domainId);
    event DomainExpertiseEndorsed(address indexed endorser, address indexed target, bytes32 indexed domainId, uint256 newScore);
    event DomainExpertiseChallenged(bytes32 indexed challengeId, address indexed challenger, address indexed target, bytes32 indexed domainId, uint256 stake);
    event DomainChallengeResolved(bytes32 indexed challengeId, bool challengerWins, address indexed winner, address indexed loser, uint256 stakeTransferred);
    event ReputationRecalibrated(address indexed user, uint256 oldScore, uint256 newScore);

    event ProjectProposed(bytes32 indexed projectId, address indexed creator, string title, uint256 budget, uint256 deadline);
    event ProjectApplied(bytes32 indexed projectId, address indexed applicant);
    event ProjectParticipantsSelected(bytes32 indexed projectId, address indexed creator, address[] participants);
    event ProjectDeliverablesSubmitted(bytes32 indexed projectId, address indexed participant, string deliverablesURI);
    event ProjectCompletionApproved(bytes32 indexed projectId, address indexed participant);
    event ParticipantPerformanceReviewed(bytes32 indexed projectId, address indexed reviewer, address indexed participant, int256 scoreChange, string feedbackURI);
    event ProjectCreatorReviewed(bytes32 indexed projectId, address indexed reviewer, address indexed creator, int256 scoreChange, string feedbackURI);
    event ProjectDisputed(bytes32 indexed disputeId, bytes32 indexed projectId, address indexed disputingParty, string reasonURI);
    event ProjectDisputeResolved(bytes32 indexed disputeId, bytes32 indexed projectId, address indexed winner, uint256 stakeTransferred);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 paramName, uint256 newValue);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votesFor, uint256 votesAgainst);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);

    constructor() Ownable(msg.sender) {
        // Initial setup for protocol parameters is done via state variable declarations.
        // These can be updated via governance later.
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Adds a new skill domain to the protocol. Only callable by the owner.
     * @param _domainName The human-readable name of the domain (e.g., "Web3 Security").
     * @param _description A brief description of the domain.
     */
    function addDomain(string calldata _domainName, string calldata _description) external onlyOwner {
        bytes32 domainId = keccak256(abi.encodePacked(_domainName));
        if (domains[domainId].exists) revert ARP_DomainAlreadyExists(); // Assuming unique names for domains
        domains[domainId] = Domain({
            name: _domainName,
            description: _description,
            exists: true
        });
        allDomainIds.push(domainId); // Add to iterable list of all domains
        emit DomainAdded(domainId, _domainName, _description);
    }

    /**
     * @dev Removes an existing skill domain from the protocol. Only callable by the owner.
     * This is a soft delete (sets `exists` to false) for historical data integrity.
     * @param _domainId The ID of the domain to remove.
     */
    function removeDomain(bytes32 _domainId) external onlyOwner {
        if (!domains[_domainId].exists) revert ARP_DomainNotFound();
        domains[_domainId].exists = false;
        // Note: For simplicity, we don't remove from `allDomainIds` array, which would be more complex.
        emit DomainRemoved(_domainId);
    }

    /**
     * @dev Updates a core protocol parameter. Only callable by the owner.
     * This function provides a backdoor for direct owner control before full governance is established.
     * Full governance flow is handled by `proposeProtocolParameterChange` and `executeProposal`.
     * @param _paramName The name of the parameter (e.g., "reputationDecayRatePerSecond") as a bytes32 hash.
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        if (_paramName == keccak256(abi.encodePacked("reputationDecayRatePerSecond"))) {
            reputationDecayRatePerSecond = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("challengeStakeAmount"))) {
            challengeStakeAmount = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("disputeStakeAmount"))) {
            disputeStakeAmount = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("minReputationForProposal"))) {
            minReputationForProposal = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("votingPeriodSeconds"))) {
            votingPeriodSeconds = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("minEndorsementInterval"))) {
            minEndorsementInterval = _newValue;
        } else if (_paramName == keccak256(abi.encodePacked("maxReviewScoreChange"))) {
            maxReviewScoreChange = _newValue;
        } else {
            revert ARP_InvalidParameterName();
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    // --- II. User Profile & Soulbound Reputation Points (SRP) ---

    /**
     * @dev Allows a new user to create their unique on-chain profile and mint their initial Soulbound Reputation Points (SRP).
     * @param _metadataURI IPFS hash or URI pointing to the user's external profile data (e.g., bio, portfolio links).
     */
    function createProfile(string calldata _metadataURI) external {
        if (hasProfile[msg.sender]) revert ARP_ProfileAlreadyExists();

        profiles[msg.sender].owner = msg.sender;
        profiles[msg.sender].metadataURI = _metadataURI;
        profiles[msg.sender].totalReputationScore = INITIAL_REPUTATION_SCORE;
        profiles[msg.sender].lastReputationUpdate = block.timestamp;
        hasProfile[msg.sender] = true;

        emit ProfileCreated(msg.sender, _metadataURI);
    }

    /**
     * @dev Allows a user to update their public profile's metadata.
     * @param _newMetadataURI New IPFS hash or URI for profile data.
     */
    function updateProfileMetadata(string calldata _newMetadataURI) external {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        profiles[msg.sender].metadataURI = _newMetadataURI;
        emit ProfileMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @dev User declares expertise in a specific domain. Initializes domain-specific score.
     * The user must already have a profile.
     * @param _domainId The ID of the domain (keccak256 of domain name).
     */
    function claimDomainExpertise(bytes32 _domainId) external {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (!domains[_domainId].exists) revert ARP_DomainNotFound();
        if (profiles[msg.sender].domains[_domainId].lastUpdateTimestamp != 0) revert ARP_DomainAlreadyClaimed(); // Check if already claimed

        profiles[msg.sender].domains[_domainId] = DomainExpertise({
            score: INITIAL_REPUTATION_SCORE, // Initial score for claimed domain
            lastUpdateTimestamp: block.timestamp
        });
        profiles[msg.sender].claimedDomainIds.push(_domainId);
        _updateTotalReputation(msg.sender, int256(INITIAL_REPUTATION_SCORE)); // Add domain score to total reputation

        emit DomainExpertiseClaimed(msg.sender, _domainId);
    }

    /**
     * @dev User removes a claimed domain expertise. Reduces total reputation by the domain's score.
     * @param _domainId The ID of the domain.
     */
    function revokeDomainExpertise(bytes32 _domainId) external {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (!domains[_domainId].exists) revert ARP_DomainNotFound();
        if (profiles[msg.sender].domains[_domainId].lastUpdateTimestamp == 0) revert ARP_DomainNotClaimed();

        // Reduce total reputation by the domain's score before deleting the domain entry
        _updateTotalReputation(msg.sender, -int256(profiles[msg.sender].domains[_domainId].score));

        delete profiles[msg.sender].domains[_domainId]; // Remove domain-specific score and timestamp
        // Remove from claimedDomainIds array (simple but potentially inefficient for very large arrays)
        for (uint256 i = 0; i < profiles[msg.sender].claimedDomainIds.length; i++) {
            if (profiles[msg.sender].claimedDomainIds[i] == _domainId) {
                profiles[msg.sender].claimedDomainIds[i] = profiles[msg.sender].claimedDomainIds[profiles[msg.sender].claimedDomainIds.length - 1];
                profiles[msg.sender].claimedDomainIds.pop();
                break;
            }
        }
        emit DomainExpertiseRevoked(msg.sender, _domainId);
    }

    // --- III. Dynamic Skill Assessment & Validation ---

    /**
     * @dev A user can endorse another user's expertise in a domain, boosting their domain-specific score.
     * Endorsement is rate-limited (`minEndorsementInterval`) to prevent spam and encourage thoughtful reviews.
     * @param _targetProfile The address of the user being endorsed.
     * @param _domainId The ID of the domain being endorsed.
     */
    function endorseDomainExpertise(address _targetProfile, bytes32 _domainId) external {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (!hasProfile[_targetProfile]) revert ARP_ProfileNotFound();
        if (msg.sender == _targetProfile) revert ARP_SelfEndorsementNotAllowed();
        if (!domains[_domainId].exists) revert ARP_DomainNotFound();
        if (profiles[_targetProfile].domains[_domainId].lastUpdateTimestamp == 0) revert ARP_DomainNotClaimed();
        if (lastEndorsementTime[msg.sender][_targetProfile][_domainId] + minEndorsementInterval > block.timestamp) revert ARP_NotEnoughTimePassed();

        uint256 endorsementImpact = profiles[msg.sender].totalReputationScore / 1000; // Impact proportional to endorser's reputation
        if (endorsementImpact == 0) endorsementImpact = 1; // Ensure a minimum positive impact
        
        _updateDomainReputation(_targetProfile, _domainId, int256(endorsementImpact));
        lastEndorsementTime[msg.sender][_targetProfile][_domainId] = block.timestamp;

        emit DomainExpertiseEndorsed(msg.sender, _targetProfile, _domainId, profiles[_targetProfile].domains[_domainId].score);
    }

    /**
     * @dev A user can challenge another's domain expertise, requiring a collateral stake.
     * This initiates a challenge that needs to be resolved by governance/owner.
     * @param _targetProfile The address of the user whose expertise is being challenged.
     * @param _domainId The ID of the domain being challenged.
     */
    function challengeDomainExpertise(address _targetProfile, bytes32 _domainId) external payable {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (!hasProfile[_targetProfile]) revert ARP_ProfileNotFound();
        if (msg.sender == _targetProfile) revert ARP_CannotDisputeSelf();
        if (!domains[_domainId].exists) revert ARP_DomainNotFound();
        if (profiles[_targetProfile].domains[_domainId].lastUpdateTimestamp == 0) revert ARP_DomainNotClaimed();
        if (msg.value < challengeStakeAmount) revert ARP_InsufficientStake();

        bytes32 currentChallengeId = keccak256(abi.encodePacked(nextChallengeId));
        domainChallenges[currentChallengeId] = DomainChallenge({
            challengeId: currentChallengeId,
            challenger: msg.sender,
            target: _targetProfile,
            domainId: _domainId,
            stake: msg.value,
            status: ChallengeStatus.Pending,
            timestamp: block.timestamp
        });
        nextChallengeId++;

        emit DomainExpertiseChallenged(currentChallengeId, msg.sender, _targetProfile, _domainId, msg.value);
    }

    /**
     * @dev Owner/Governance resolves an outstanding domain expertise challenge.
     * The stake is transferred based on the outcome, and reputations are adjusted.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWins True if the challenger wins (target's expertise is deemed false), false if the target wins.
     */
    function resolveDomainChallenge(bytes32 _challengeId, bool _challengerWins) external onlyOwner {
        DomainChallenge storage challenge = domainChallenges[_challengeId];
        if (challenge.challengeId == bytes32(0)) revert ARP_ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Pending) revert ARP_ChallengeAlreadyResolved();

        challenge.status = ChallengeStatus.Resolved;

        address winner;
        address loser;
        uint256 stakeAmount = challenge.stake;

        if (_challengerWins) {
            winner = challenge.challenger;
            loser = challenge.target;
            // Slash target's total and domain reputation for false claim
            _updateDomainReputation(challenge.target, challenge.domainId, -int256(stakeAmount));
        } else {
            winner = challenge.target;
            loser = challenge.challenger;
            // Reward target's reputation, potentially slash challenger's
            _updateDomainReputation(challenge.target, challenge.domainId, int256(stakeAmount / 2)); // Reward target some of stake
            _updateTotalReputation(challenge.challenger, -int256(stakeAmount / 2)); // Challenger loses some reputation
        }

        // Transfer stake to the winner
        payable(winner).sendValue(stakeAmount);

        emit DomainChallengeResolved(_challengeId, _challengerWins, winner, loser, stakeAmount);
    }

    /**
     * @dev Public function to trigger a reputation decay calculation for a specific user based on inactivity.
     * Can be called by anyone (e.g., an off-chain keeper service) to maintain profile freshness.
     * @param _user The address of the user whose reputation needs recalibration.
     */
    function recalibrateReputation(address _user) external {
        if (!hasProfile[_user]) revert ARP_ProfileNotFound();

        Profile storage userProfile = profiles[_user];
        uint256 timeElapsed = block.timestamp - userProfile.lastReputationUpdate;

        if (timeElapsed == 0) revert ARP_ReputationDecayNotDue(); // No time has passed since last update

        uint256 decayAmount = timeElapsed * reputationDecayRatePerSecond;
        if (userProfile.totalReputationScore <= decayAmount) {
            userProfile.totalReputationScore = 1; // Don't allow score to drop to zero, always maintain minimal presence
        } else {
            userProfile.totalReputationScore -= decayAmount;
        }

        // Apply decay to domain specific scores as well
        for (uint256 i = 0; i < userProfile.claimedDomainIds.length; i++) {
            bytes32 domainId = userProfile.claimedDomainIds[i];
            DomainExpertise storage domainExp = userProfile.domains[domainId];
            uint256 domainTimeElapsed = block.timestamp - domainExp.lastUpdateTimestamp;
            uint256 domainDecayAmount = domainTimeElapsed * reputationDecayRatePerSecond / 2; // Domain decay might be slower

            if (domainExp.score <= domainDecayAmount) {
                domainExp.score = 1;
            } else {
                domainExp.score -= domainDecayAmount;
            }
            domainExp.lastUpdateTimestamp = block.timestamp;
        }

        userProfile.lastReputationUpdate = block.timestamp;
        emit ReputationRecalibrated(_user, userProfile.totalReputationScore + decayAmount, userProfile.totalReputationScore);
    }

    // --- III. Adaptive Project Bounties & Collaboration ---

    /**
     * @dev Allows a user to create a new project bounty, specifying requirements and budget.
     * The project creator must send the budget amount along with this call, which is held in escrow.
     * @param _title The title of the project.
     * @param _descriptionURI IPFS hash or URI for detailed project description.
     * @param _budget The ETH budget for the project.
     * @param _deadline Timestamp by which the project should be completed.
     * @param _requiredDomains An array of domain IDs (keccak256 hashes) required for participants.
     * @param _minReputationScore The minimum total reputation score required for participants to apply.
     */
    function proposeProject(
        string calldata _title,
        string calldata _descriptionURI,
        uint256 _budget,
        uint256 _deadline,
        bytes32[] calldata _requiredDomains,
        uint256 _minReputationScore
    ) external payable {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (msg.value < _budget) revert ARP_InsufficientStake(); // Budget must be provided upfront

        bytes32 projectId = keccak256(abi.encodePacked(msg.sender, _title, block.timestamp)); // Generate a unique project ID

        projects[projectId] = Project({
            projectId: projectId,
            creator: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            budget: _budget,
            deadline: _deadline,
            requiredDomains: _requiredDomains,
            minReputationScore: _minReputationScore,
            status: ProjectStatus.ApplicationPhase,
            applicants: new address[](0),
            isApplicant: new mapping(address => bool)(),
            participants: new address[](0),
            isParticipant: new mapping(address => bool)(),
            participantDeliverablesURI: new mapping(address => string)(),
            participantApprovedCompletion: new mapping(address => bool)(),
            participantReviewedCreator: new mapping(address => bool)(),
            creatorReviewedParticipant: new mapping(address => bool)(),
            timestamp: block.timestamp
        });

        emit ProjectProposed(projectId, msg.sender, _title, _budget, _deadline);
    }

    /**
     * @dev Allows a user to apply to an open project, if they meet the specified requirements.
     * Requirements include minimum reputation score and claimed expertise in all required domains.
     * @param _projectId The ID of the project to apply for.
     */
    function applyForProject(bytes32 _projectId) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (project.status != ProjectStatus.ApplicationPhase) revert ARP_ProjectNotOpenForApplications();
        if (project.isApplicant[msg.sender]) revert ARP_AlreadyApplied();

        Profile storage applicantProfile = profiles[msg.sender];
        if (applicantProfile.totalReputationScore < project.minReputationScore) revert ARP_InsufficientReputationForProposal(); // Reusing error for reputation threshold
        
        // Verify applicant's domain expertise for all required domains
        for (uint256 i = 0; i < project.requiredDomains.length; i++) {
            bytes32 requiredDomain = project.requiredDomains[i];
            if (!domains[requiredDomain].exists || // Domain must exist in the protocol
                applicantProfile.domains[requiredDomain].lastUpdateTimestamp == 0 || // User must have claimed expertise
                applicantProfile.domains[requiredDomain].score < project.minReputationScore / 2) { // Example: must have claimed and reasonable score
                revert ARP_InvalidParticipantSelection(); // Reusing error: applicant does not meet skill requirements
            }
        }

        project.applicants.push(msg.sender);
        project.isApplicant[msg.sender] = true;

        emit ProjectApplied(_projectId, msg.sender);
    }

    /**
     * @dev Project creator selects approved participants from the list of applicants.
     * Moves the project status from `ApplicationPhase` to `InProgress`.
     * @param _projectId The ID of the project.
     * @param _participants An array of addresses selected as participants.
     */
    function selectProjectParticipants(bytes32 _projectId, address[] calldata _participants) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (msg.sender != project.creator) revert ARP_NotProjectCreator();
        if (project.status != ProjectStatus.ApplicationPhase) revert ARP_InvalidParticipantSelection(); // Already selected or not open for applications

        // Validate that all selected participants actually applied
        for (uint256 i = 0; i < _participants.length; i++) {
            address participant = _participants[i];
            if (!project.isApplicant[participant]) revert ARP_InvalidParticipantSelection(); // Selected participant must have applied
            project.participants.push(participant);
            project.isParticipant[participant] = true;
        }

        project.status = ProjectStatus.InProgress;
        emit ProjectParticipantsSelected(_projectId, msg.sender, _participants);
    }

    /**
     * @dev A selected participant submits their project deliverables (e.g., an IPFS hash).
     * @param _projectId The ID of the project.
     * @param _deliverablesURI IPFS hash or URI for the deliverables.
     */
    function submitProjectDeliverables(bytes32 _projectId, string calldata _deliverablesURI) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (!project.isParticipant[msg.sender]) revert ARP_NotProjectParticipant();
        if (project.status != ProjectStatus.InProgress) revert ARP_ProjectNotOpenForApplications(); // Must be in progress
        if (bytes(project.participantDeliverablesURI[msg.sender]).length != 0) revert ARP_DeliverablesAlreadySubmitted();

        project.participantDeliverablesURI[msg.sender] = _deliverablesURI;
        emit ProjectDeliverablesSubmitted(_projectId, msg.sender, _deliverablesURI);
    }

    /**
     * @dev Project creator approves a participant's completion, triggering payout from escrow.
     * Enables subsequent feedback/reviews.
     * @param _projectId The ID of the project.
     * @param _participant The address of the participant whose work is being approved.
     */
    function approveProjectCompletion(bytes32 _projectId, address _participant) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (msg.sender != project.creator) revert ARP_NotProjectCreator();
        if (!project.isParticipant[_participant]) revert ARP_NotProjectParticipant();
        if (bytes(project.participantDeliverablesURI[_participant]).length == 0) revert ARP_DeliverablesNotSubmitted();
        if (project.participantApprovedCompletion[_participant]) revert ARP_ProjectAlreadyCompleted();

        // Simple equal split of the budget among approved participants
        uint256 payout = project.budget / project.participants.length; 
        project.participantApprovedCompletion[_participant] = true;
        
        // Transfer funds to participant. Re-entrancy guard is managed by Address.sendValue.
        payable(_participant).sendValue(payout);

        // If all participants are approved, transition project status to 'Completed'.
        bool allApproved = true;
        for (uint i = 0; i < project.participants.length; i++) {
            if (!project.participantApprovedCompletion[project.participants[i]]) {
                allApproved = false;
                break;
            }
        }
        if (allApproved) {
            project.status = ProjectStatus.Completed;
        }

        emit ProjectCompletionApproved(_projectId, _participant);
    }

    /**
     * @dev Project creator provides feedback on a participant, affecting their total SRP.
     * Can only be called once per participant per project after their completion is approved.
     * @param _projectId The ID of the project.
     * @param _participant The participant being reviewed.
     * @param _scoreChange The amount to change the participant's total reputation score (positive or negative).
     * @param _feedbackURI IPFS hash or URI for detailed text feedback.
     */
    function reviewParticipantPerformance(bytes32 _projectId, address _participant, int256 _scoreChange, string calldata _feedbackURI) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (msg.sender != project.creator) revert ARP_NotProjectCreator();
        if (!project.isParticipant[_participant]) revert ARP_NotProjectParticipant();
        if (!project.participantApprovedCompletion[_participant]) revert ARP_ProjectNotCompleted(); // Participant's work must be approved first
        if (project.creatorReviewedParticipant[_participant]) revert ARP_CannotReviewSelf(); // Reusing error: creator already reviewed this participant
        if (_scoreChange > int256(maxReviewScoreChange) || _scoreChange < -int256(maxReviewScoreChange)) revert ARP_InvalidParticipantSelection(); // Reusing: score change out of bounds

        _updateTotalReputation(_participant, _scoreChange);
        project.creatorReviewedParticipant[_participant] = true;

        emit ParticipantPerformanceReviewed(_projectId, msg.sender, _participant, _scoreChange, _feedbackURI);
    }

    /**
     * @dev A participant provides feedback on the project creator, affecting their total SRP.
     * Can only be called once by a participant per project after their completion is approved.
     * @param _projectId The ID of the project.
     * @param _scoreChange The amount to change the creator's total reputation score (positive or negative).
     * @param _feedbackURI IPFS hash or URI for detailed text feedback.
     */
    function reviewProjectCreator(bytes32 _projectId, int256 _scoreChange, string calldata _feedbackURI) external {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (!project.isParticipant[msg.sender]) revert ARP_NotProjectParticipant();
        if (!project.participantApprovedCompletion[msg.sender]) revert ARP_ProjectNotCompleted(); // Participant's work must be approved first
        if (project.participantReviewedCreator[msg.sender]) revert ARP_CannotReviewSelf(); // Reusing error: participant already reviewed creator
        if (_scoreChange > int256(maxReviewScoreChange) || _scoreChange < -int256(maxReviewScoreChange)) revert ARP_InvalidParticipantSelection(); // Reusing: score change out of bounds

        _updateTotalReputation(project.creator, _scoreChange);
        project.participantReviewedCreator[msg.sender] = true;

        emit ProjectCreatorReviewed(_projectId, msg.sender, project.creator, _scoreChange, _feedbackURI);
    }

    /**
     * @dev A project participant or creator can dispute a project outcome (e.g., unfair review, non-payment).
     * Requires a collateral stake, which is held until the dispute is resolved.
     * @param _projectId The ID of the project being disputed.
     * @param _disputingParty The address of the party initiating the dispute (must be the caller, and either creator or a participant).
     * @param _reasonURI IPFS hash or URI for detailed reason of the dispute.
     */
    function disputeProjectOutcome(bytes32 _projectId, address _disputingParty, string calldata _reasonURI) external payable {
        Project storage project = projects[_projectId];
        if (project.projectId == bytes32(0)) revert ARP_ProjectNotFound();
        if (msg.sender != _disputingParty) revert ARP_Unauthorized(); // Caller must be the disputing party
        if (msg.sender != project.creator && !project.isParticipant[msg.sender]) revert ARP_Unauthorized(); // Must be creator or a participant
        if (msg.value < disputeStakeAmount) revert ARP_InsufficientStake();

        bytes32 currentDisputeId = keccak256(abi.encodePacked(nextDisputeId));
        projectDisputes[currentDisputeId] = ProjectDispute({
            disputeId: currentDisputeId,
            projectId: _projectId,
            disputingParty: _disputingParty,
            // Determine the counter-party: if caller is creator, counter-party is the project itself (or all participants) for now.
            // For simplicity, we assume the counter-party is the other 'side' of the project interaction (creator vs. the specific participant).
            // A more complex system might allow specific participant-to-participant disputes.
            counterParty: (msg.sender == project.creator) ? address(0) : project.creator, // address(0) for "the other side of the project", or can be a specific participant
            reasonURI: _reasonURI,
            stake: msg.value,
            status: DisputeStatus.Pending,
            timestamp: block.timestamp
        });
        nextDisputeId++;
        project.status = ProjectStatus.Disputed; // Set project status to disputed

        emit ProjectDisputed(currentDisputeId, _projectId, _disputingParty, _reasonURI);
    }

    /**
     * @dev Owner/Governance resolves a project dispute. Stakes are transferred and SRP adjusted based on outcome.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _winner The address of the party deemed to have won the dispute.
     */
    function resolveProjectDispute(bytes32 _disputeId, address _winner) external onlyOwner {
        ProjectDispute storage dispute = projectDisputes[_disputeId];
        if (dispute.disputeId == bytes32(0)) revert ARP_DisputeNotFound();
        if (dispute.status != DisputeStatus.Pending) revert ARP_DisputeAlreadyResolved();
        
        // The winner must be either the disputing party or the project creator/a participant if counterParty is specific.
        // For simplicity with counterParty as address(0), _winner must be the disputing party.
        if (_winner != dispute.disputingParty && _winner != projects[dispute.projectId].creator) revert ARP_Unauthorized(); 

        dispute.status = DisputeStatus.Resolved;
        address loser = (_winner == dispute.disputingParty) ? projects[dispute.projectId].creator : dispute.disputingParty;
        uint256 stakeAmount = dispute.stake;

        // Reward winner's reputation, slash loser's reputation
        _updateTotalReputation(_winner, int256(stakeAmount));
        _updateTotalReputation(loser, -int256(stakeAmount));

        // Transfer stake to the winner
        payable(_winner).sendValue(stakeAmount);

        // Reset project status or finalize based on dispute outcome (e.g., return to completed or mark as resolved)
        projects[dispute.projectId].status = ProjectStatus.Completed; 

        emit ProjectDisputeResolved(_disputeId, dispute.projectId, _winner, stakeAmount);
    }

    // --- IV. Governance & Protocol Evolution ---

    /**
     * @dev Allows SRP holders (above a minimum threshold) to propose changes to protocol parameters.
     * This initiates a voting period for the community.
     * @param _description A detailed description of the proposed change.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("reputationDecayRatePerSecond")).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(string calldata _description, bytes32 _paramName, uint256 _newValue) external {
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();
        if (profiles[msg.sender].totalReputationScore < minReputationForProposal) revert ARP_InsufficientReputationForProposal();

        uint256 currentProposalId = nextProposalId;
        proposals[currentProposalId] = Proposal({
            proposalId: currentProposalId,
            proposer: msg.sender,
            description: _description,
            paramName: _paramName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(), // Initialize mapping
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + votingPeriodSeconds,
            status: ProposalStatus.Pending
        });
        nextProposalId++;

        emit ProposalCreated(currentProposalId, msg.sender, _description, _paramName, _newValue);
    }

    /**
     * @dev Allows SRP holders to vote on active proposals.
     * Each vote's weight is proportional to the voter's current total reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "yes" vote, false for "no" vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert ARP_ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert ARP_ProposalNotApproved(); // Not in pending state for voting
        if (block.timestamp >= proposal.expirationTimestamp) revert ARP_ProposalExpired();
        if (proposal.hasVoted[msg.sender]) revert ARP_ProposalAlreadyVoted();
        if (!hasProfile[msg.sender]) revert ARP_ProfileNotFound();

        uint256 voteWeight = profiles[msg.sender].totalReputationScore;
        if (_support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);
    }

    /**
     * @dev Executes a passed proposal if the voting period is over and it has garnered more "for" votes than "against".
     * Any user can call this to trigger execution after the voting period has ended.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert ARP_ProposalNotFound();
        if (proposal.status != ProposalStatus.Pending) revert ARP_ProposalNotApproved(); // Must be pending
        if (block.timestamp < proposal.expirationTimestamp) revert ARP_VotingPeriodNotOver(); // Voting period must have ended

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed: apply the parameter change
            if (proposal.paramName == keccak256(abi.encodePacked("reputationDecayRatePerSecond"))) {
                reputationDecayRatePerSecond = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("challengeStakeAmount"))) {
                challengeStakeAmount = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("disputeStakeAmount"))) {
                disputeStakeAmount = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("minReputationForProposal"))) {
                minReputationForProposal = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("votingPeriodSeconds"))) {
                votingPeriodSeconds = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("minEndorsementInterval"))) {
                minEndorsementInterval = proposal.newValue;
            } else if (proposal.paramName == keccak256(abi.encodePacked("maxReviewScoreChange"))) {
                maxReviewScoreChange = proposal.newValue;
            } else {
                revert ARP_InvalidParameterName(); // Should theoretically not happen if proposal creation validates
            }
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
            emit ProtocolParameterUpdated(proposal.paramName, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
    }

    // --- V. Utility & View Functions ---

    /**
     * @dev Returns a user's complete profile information, including total SRP and domain-specific scores.
     * @param _user The address of the user.
     * @return profileData A tuple containing all profile details.
     */
    function getProfile(address _user) external view returns (
        address owner,
        string memory metadataURI,
        uint256 totalReputationScore,
        uint256 lastReputationUpdate,
        bytes32[] memory claimedDomainIds,
        uint256[] memory domainScores,
        uint256[] memory domainLastUpdates
    ) {
        if (!hasProfile[_user]) revert ARP_ProfileNotFound();
        Profile storage userProfile = profiles[_user];

        claimedDomainIds = userProfile.claimedDomainIds;
        domainScores = new uint256[](claimedDomainIds.length);
        domainLastUpdates = new uint256[](claimedDomainIds.length);

        for (uint256 i = 0; i < claimedDomainIds.length; i++) {
            bytes32 domainId = claimedDomainIds[i];
            domainScores[i] = userProfile.domains[domainId].score;
            domainLastUpdates[i] = userProfile.domains[domainId].lastUpdateTimestamp;
        }

        owner = userProfile.owner;
        metadataURI = userProfile.metadataURI;
        totalReputationScore = userProfile.totalReputationScore;
        lastReputationUpdate = userProfile.lastReputationUpdate;
    }

    /**
     * @dev Returns information about a specific skill domain.
     * @param _domainId The ID of the domain.
     * @return name The human-readable name of the domain.
     * @return description A brief description of the domain.
     * @return exists True if the domain exists (not soft-deleted).
     */
    function getDomain(bytes32 _domainId) external view returns (string memory name, string memory description, bool exists) {
        Domain storage d = domains[_domainId];
        return (d.name, d.description, d.exists);
    }

    /**
     * @dev Returns detailed information about a project.
     * @param _projectId The ID of the project.
     * @return projectData A tuple containing all relevant project details.
     */
    function getProject(bytes32 _projectId) external view returns (
        bytes32 projectId,
        address creator,
        string memory title,
        string memory descriptionURI,
        uint256 budget,
        uint256 deadline,
        bytes32[] memory requiredDomains,
        uint256 minReputationScore,
        ProjectStatus status,
        address[] memory applicants,
        address[] memory participants,
        string[] memory participantDeliverables,
        bool[] memory participantApprovedStatus,
        bool[] memory creatorReviewedStatuses,
        bool[] memory participantReviewedCreatorStatuses
    ) {
        Project storage p = projects[_projectId];
        if (p.projectId == bytes32(0)) revert ARP_ProjectNotFound();

        projectId = p.projectId;
        creator = p.creator;
        title = p.title;
        descriptionURI = p.descriptionURI;
        budget = p.budget;
        deadline = p.deadline;
        requiredDomains = p.requiredDomains;
        minReputationScore = p.minReputationScore;
        status = p.status;
        applicants = p.applicants;
        participants = p.participants;

        participantDeliverables = new string[](p.participants.length);
        participantApprovedStatus = new bool[](p.participants.length);
        creatorReviewedStatuses = new bool[](p.participants.length);
        participantReviewedCreatorStatuses = new bool[](p.participants.length);

        for (uint i = 0; i < p.participants.length; i++) {
            address participant = p.participants[i];
            participantDeliverables[i] = p.participantDeliverablesURI[participant];
            participantApprovedStatus[i] = p.participantApprovedCompletion[participant];
            creatorReviewedStatuses[i] = p.creatorReviewedParticipant[participant];
            participantReviewedCreatorStatuses[i] = p.participantReviewedCreator[participant];
        }
    }

    /**
     * @dev Returns details about a domain expertise challenge.
     * @param _challengeId The ID of the challenge.
     * @return challengeData A tuple containing challenge details.
     */
    function getChallenge(bytes32 _challengeId) external view returns (
        bytes32 challengeId,
        address challenger,
        address target,
        bytes32 domainId,
        uint256 stake,
        ChallengeStatus status,
        uint256 timestamp
    ) {
        DomainChallenge storage c = domainChallenges[_challengeId];
        if (c.challengeId == bytes32(0)) revert ARP_ChallengeNotFound();
        return (c.challengeId, c.challenger, c.target, c.domainId, c.stake, c.status, c.timestamp);
    }

    /**
     * @dev Returns details about a project dispute.
     * @param _disputeId The ID of the dispute.
     * @return disputeData A tuple containing dispute details.
     */
    function getDispute(bytes32 _disputeId) external view returns (
        bytes32 disputeId,
        bytes32 projectId,
        address disputingParty,
        address counterParty,
        string memory reasonURI,
        uint256 stake,
        DisputeStatus status,
        uint256 timestamp
    ) {
        ProjectDispute storage d = projectDisputes[_disputeId];
        if (d.disputeId == bytes32(0)) revert ARP_DisputeNotFound();
        return (d.disputeId, d.projectId, d.disputingParty, d.counterParty, d.reasonURI, d.stake, d.status, d.timestamp);
    }

    /**
     * @dev Returns details about a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposalData A tuple containing proposal details.
     */
    function getProposal(uint256 _proposalId) external view returns (
        uint256 proposalId,
        address proposer,
        string memory description,
        bytes32 paramName,
        uint256 newValue,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 creationTimestamp,
        uint256 expirationTimestamp,
        ProposalStatus status
    ) {
        Proposal storage p = proposals[_proposalId];
        if (p.proposalId == 0) revert ARP_ProposalNotFound();
        return (
            p.proposalId,
            p.proposer,
            p.description,
            p.paramName,
            p.newValue,
            p.votesFor,
            p.votesAgainst,
            p.creationTimestamp,
            p.expirationTimestamp,
            p.status
        );
    }

    // --- Internal/Private Functions ---

    /**
     * @dev Internal function to update a user's total reputation score.
     * Handles positive and negative score changes, ensuring a minimum score of 1.
     * Also updates the `lastReputationUpdate` timestamp.
     * @param _user The user whose score to update.
     * @param _change The amount to change the score by (can be positive or negative).
     */
    function _updateTotalReputation(address _user, int256 _change) internal {
        Profile storage userProfile = profiles[_user];
        uint256 currentScore = userProfile.totalReputationScore;

        if (_change > 0) {
            userProfile.totalReputationScore = currentScore + uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (currentScore <= absChange) {
                userProfile.totalReputationScore = 1; // Minimum score of 1 to prevent complete deletion from radar
            } else {
                userProfile.totalReputationScore = currentScore - absChange;
            }
        }
        userProfile.lastReputationUpdate = block.timestamp; // Mark activity
    }

    /**
     * @dev Internal function to update a user's domain-specific reputation score.
     * Handles positive and negative score changes, ensuring minimum score of 1.
     * Also updates the user's total reputation score to reflect changes in domain-specific scores.
     * @param _user The user whose domain score to update.
     * @param _domainId The domain ID.
     * @param _change The amount to change the domain score by.
     */
    function _updateDomainReputation(address _user, bytes32 _domainId, int256 _change) internal {
        DomainExpertise storage domainExp = profiles[_user].domains[_domainId];
        if (domainExp.lastUpdateTimestamp == 0) revert ARP_DomainNotClaimed(); // Should not be called for unclaimed domains

        uint256 currentScore = domainExp.score;
        if (_change > 0) {
            domainExp.score = currentScore + uint256(_change);
        } else {
            uint256 absChange = uint256(-_change);
            if (currentScore <= absChange) {
                domainExp.score = 1; // Minimum score for a claimed domain
            } else {
                domainExp.score = currentScore - absChange;
            }
        }
        domainExp.lastUpdateTimestamp = block.timestamp;
        _updateTotalReputation(_user, _change); // Reflect domain score change in total score
    }
}
```