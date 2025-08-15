The smart contract below, named `CerebralNexus`, is designed to be a decentralized protocol that orchestrates collective intelligence and resource allocation based on dynamic, verifiable on-chain reputation and skill-centric interactions. It aims to create a self-regulating ecosystem for project funding and collaboration, moving beyond simple token-weighted voting to incorporate a more nuanced understanding of "trust" and "contribution."

It focuses on concepts like:
*   **Dynamic Reputation:** Reputation isn't static; it evolves based on active contributions, successful attestations, and performance in dispute resolution.
*   **Skill Attestation:** A mechanism for users to vouch for each other's skills, with attestations having an expiration and a challenge mechanism.
*   **Adaptive Resource Pools (ARPs):** Funding pools that release capital iteratively based on milestone verification and community consensus, rather than lump sums.
*   **Nexus Challenges:** A built-in dispute resolution system for contesting skill attestations or project milestones, where reputation is at stake.
*   **Performance-Based Funding:** Funds are released only upon verified milestone completion, potentially using external oracles.

---

**Outline & Function Summary**

**I. Core Protocol Management**
    *   `constructor()`: Initializes the protocol owner and core parameters.
    *   `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows the owner (or eventually DAO) to adjust global protocol settings (e.g., reputation decay rate, minimum reputation thresholds).
    *   `pauseProtocol()`: Puts the protocol into a paused state, preventing core operations during maintenance or emergencies.
    *   `unpauseProtocol()`: Resumes protocol operations from a paused state.
    *   `withdrawProtocolFees(address _token, uint256 _amount)`: Allows the owner (or DAO treasury) to withdraw accrued protocol fees in various tokens.

**II. Identity & Reputation Layer**
    *   `registerNexusProfile(string memory _metadataURI)`: Registers a unique, soulbound-like profile for a new user, establishing their on-chain identity within the Nexus.
    *   `attestSkill(address _attestee, bytes32 _skillHash, uint256 _durationDays, string memory _proofURI)`: Allows a user with sufficient reputation to formally attest to another user's specific skill. Requires a conceptual temporary reputation "stake."
    *   `revokeSkillAttestation(uint256 _attestationId)`: Allows the original attester to retract their skill attestation, with potential implications for their reputation.
    *   `challengeSkillAttestation(uint256 _attestationId, string memory _challengeReasonURI)`: Initiates a formal dispute (Nexus Challenge) against an existing skill attestation, questioning its validity.
    *   `getSkillAttestation(uint256 _attestationId)`: Retrieves detailed information about a specific skill attestation.
    *   `getReputationScore(address _user)`: Calculates and returns a user's dynamic reputation score, derived from their active skill attestations, participation in Nexus Challenges, and contributions (conceptual decay is applied over time).
    *   `_decayReputation(address _user)`: An internal, conceptual function representing the periodic decay of a user's reputation if not actively maintained or increased.

**III. Resource Allocation & Project Management**
    *   `createAdaptiveResourcePool(string memory _name, string memory _descriptionURI, uint256 _targetAmount, address _tokenAddress, Milestone[] memory _milestones)`: Creates a new, dedicated funding pool for a specific project or initiative, defining its funding goals and an ordered set of milestones.
    *   `submitProjectProposal(uint256 _resourcePoolId, string memory _proposalURI)`: Allows users to submit detailed project proposals that aim to receive funding from a designated Adaptive Resource Pool.
    *   `voteOnProjectProposal(uint256 _resourcePoolId, uint256 _proposalId, bool _approve)`: Enables community members to vote on submitted project proposals, with their vote weight scaled by their current reputation score.
    *   `fundResourcePool(uint256 _resourcePoolId, uint256 _amount)`: Allows any user to contribute funds (ETH or specified ERC20) to an Adaptive Resource Pool once a proposal has been approved.
    *   `reportMilestoneCompletion(uint256 _resourcePoolId, uint256 _milestoneIndex)`: The designated project lead reports the completion of a specific milestone, triggering a verification or challenge period.
    *   `challengeMilestoneCompletion(uint256 _resourcePoolId, uint256 _milestoneIndex, string memory _challengeReasonURI)`: Initiates a Nexus Challenge if a community member disputes a reported milestone completion.
    *   `releaseMilestoneFunds(uint256 _resourcePoolId, uint256 _milestoneIndex)`: Releases the allocated funds for a milestone *after* its successful verification (either via oracle or after a challenge has been resolved in favor of completion).
    *   `reallocateUnusedFunds(uint256 _resourcePoolId)`: Allows the owner (or DAO) to reallocate remaining funds from projects that have stalled, failed, or been canceled.

**IV. Dispute Resolution & Validation (Nexus Challenges)**
    *   `initiateNexusChallenge(bytes32 _challengeType, uint256 _subjectId, string memory _reasonURI)`: A generalized function to start a dispute, linking to specific types (e.g., skill attestation or milestone completion). This is an internal helper called by specific challenge functions.
    *   `submitChallengeEvidence(uint256 _challengeId, string memory _evidenceURI)`: Allows participants (challenger, challenged party, or interested community members) to submit supporting evidence for an ongoing Nexus Challenge.
    *   `voteOnChallengeOutcome(uint256 _challengeId, bool _outcome)`: Community members vote on the resolution of an ongoing challenge, with their vote weight scaled by reputation.
    *   `resolveNexusChallenge(uint256 _challengeId)`: Finalizes a challenge once the voting period ends, applying the consequences (e.g., reputation adjustments, attestation deactivation, milestone verification status) based on the community's vote.

**V. Dynamic Incentives & Protocol Economics**
    *   `claimReputationRewards()`: Allows users to claim periodic rewards based on their accumulated reputation score and active contributions to the protocol.
    *   `setExternalOracleAddress(address _oracleAddress)`: Allows the owner (or DAO) to set the address of an external oracle contract used for specific off-chain data verification (e.g., complex project milestone verification).
    *   `getProfileStats(address _user)`: A view function that returns a comprehensive overview of a user's profile, including their current calculated reputation score and metadata.
    *   `getPoolStats(uint256 _resourcePoolId)`: A view function that provides detailed statistics about a specific Adaptive Resource Pool, including its funding status and milestone progress.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CerebralNexus
 * @author YourName (Conceptual)
 * @notice A decentralized protocol for skill-centric resource coordination and collective intelligence.
 * @dev This contract implements dynamic reputation, skill attestations, adaptive resource pools,
 *      and a robust dispute resolution system (Nexus Challenges) to foster a trust-minimized
 *      and performance-driven ecosystem.
 *      Many complex aspects (e.g., detailed reputation graph, specific oracle integrations,
 *      advanced DAO governance) are conceptual placeholders for brevity and gas efficiency.
 */
contract CerebralNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Events ---
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event NexusProfileRegistered(address indexed user, string metadataURI);
    event SkillAttested(uint256 indexed attestationId, address indexed attester, address indexed attestee, bytes32 skillHash, uint256 expiration);
    event SkillAttestationRevoked(uint256 indexed attestationId);
    event AdaptiveResourcePoolCreated(uint256 indexed poolId, address indexed creator, uint256 targetAmount, address tokenAddress);
    event ProjectProposalSubmitted(uint256 indexed poolId, uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event ProjectProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 voteWeight);
    event ResourcePoolFunded(uint256 indexed poolId, address indexed contributor, uint256 amount);
    event MilestoneReported(uint256 indexed poolId, uint256 indexed milestoneIndex, address indexed reporter);
    event MilestoneFundsReleased(uint256 indexed poolId, uint256 indexed milestoneIndex, uint256 amount);
    event FundsReallocated(uint256 indexed poolId, uint256 amount);
    event NexusChallengeInitiated(uint256 indexed challengeId, bytes32 indexed challengeType, uint256 indexed subjectId, address initiator);
    event NexusChallengeEvidenceSubmitted(uint256 indexed challengeId, address indexed submitter, string evidenceURI);
    event NexusChallengeVoted(uint256 indexed challengeId, address indexed voter, bool outcome);
    event NexusChallengeResolved(uint256 indexed challengeId, bool finalOutcome);
    event ReputationRewardsClaimed(address indexed user, uint256 amount);

    // --- Constants & Configuration ---
    // These would typically be configurable via `updateProtocolParameter` or a DAO vote.
    // For this example, they are hardcoded.
    uint256 public MIN_REPUTATION_FOR_ATTESTATION = 1000; // Minimum reputation required to attest to a skill
    uint256 public REPUTATION_DECAY_RATE_PER_DAY_BPS = 10; // 0.10% per day (10 Basis Points)
    uint256 public MIN_PROPOSAL_VOTE_REPUTATION = 50; // Minimum reputation to vote on proposals
    uint256 public NEXUS_CHALLENGE_VOTING_PERIOD_DAYS = 3; // Duration for Nexus Challenge voting

    // --- Structs ---

    struct NexusProfile {
        bool exists;
        string metadataURI; // Link to IPFS or similar for detailed profile info (e.g., name, bio)
        uint256 lastReputationUpdate; // Timestamp of last reputation calculation/decay application
        uint256 baseReputation; // A foundational reputation score, modified by actions
    }

    struct SkillAttestation {
        address attester;
        address attestee;
        bytes32 skillHash; // Keccak256 hash of a standardized skill identifier (e.g., "keccak256('solidity_developer')")
        uint256 issuedAt;
        uint256 expiresAt;
        string proofURI; // Link to off-chain proof (e.g., certification, portfolio, project list)
        bool isActive; // Can be deactivated if challenged, revoked, or expired
        uint256 challengeId; // If challenged, links to NexusChallenge ID (0 if not challenged)
    }

    enum ResourcePoolStatus { Active, Closed, Failed, Completed }

    struct Milestone {
        string descriptionURI; // Link to IPFS for detailed description of the milestone task
        uint256 targetAmount; // Amount of funds to be released upon this milestone's verified completion
        bool isCompleted; // True if reported completed by project lead
        bool isVerified; // True if verified by oracle or community challenge outcome
        uint256 challengeId; // If challenged, links to NexusChallenge ID (0 if not challenged)
    }

    struct ProjectProposal {
        address proposer;
        string proposalURI; // Link to IPFS for the detailed project proposal document
        uint256 submittedAt;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this specific proposal
        uint256 yesVotesWeighted; // Sum of reputation-weighted "yes" votes
        uint256 noVotesWeighted;  // Sum of reputation-weighted "no" votes
        bool approved; // True if the proposal has passed the voting threshold
    }

    enum ChallengeStatus { PendingEvidence, Voting, Resolved, Canceled }
    enum ChallengeType { SkillAttestation, MilestoneCompletion } // Defines what kind of subject is being challenged

    struct NexusChallenge {
        ChallengeType challengeType;
        uint256 subjectId; // ID of the SkillAttestation or a composite ID for Milestone being challenged
        address initiator; // Address of the user who initiated the challenge
        string reasonURI; // Link to detailed reason/evidence provided by the initiator
        uint256 initiatedAt;
        uint256 votingEndsAt;
        mapping(address => bool) hasVoted; // Tracks voters for this challenge
        uint256 yesVotesWeighted; // Votes supporting the challenge (i.e., attestation is false, milestone not completed)
        uint256 noVotesWeighted;  // Votes opposing the challenge (i.e., attestation is true, milestone is completed)
        ChallengeStatus status;
        bool finalOutcome; // true if challenge succeeded (e.g., attestation revoked, milestone marked false)
    }

    // --- State Variables ---
    mapping(address => NexusProfile) public nexusProfiles;
    uint256 public nextAttestationId;
    mapping(uint256 => SkillAttestation) public skillAttestations;

    uint256 public nextResourcePoolId;
    mapping(uint256 => AdaptiveResourcePool) public adaptiveResourcePools;

    uint256 public nextChallengeId;
    mapping(uint256 => NexusChallenge) public nexusChallenges;

    address public externalOracleAddress; // Address of a trusted oracle contract for external data/verification

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {
        // Owner is initially set to the deployer by Ownable
        // No tokens are held directly by the contract initially, funds are managed per pool.
    }

    // --- I. Core Protocol Management ---

    /**
     * @notice Allows the owner to update key protocol parameters.
     * @dev In a full DAO implementation, this would be governed by DAO proposals.
     * @param _paramName The name of the parameter to update (e.g., "reputationDecayRate", "minReputationForAttestation").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        if (_paramName == "minReputationForAttestation") {
            MIN_REPUTATION_FOR_ATTESTATION = _newValue;
        } else if (_paramName == "reputationDecayRate") {
            REPUTATION_DECAY_RATE_PER_DAY_BPS = _newValue;
        } else if (_paramName == "minProposalVoteReputation") {
            MIN_PROPOSAL_VOTE_REPUTATION = _newValue;
        } else if (_paramName == "nexusChallengeVotingPeriodDays") {
            NEXUS_CHALLENGE_VOTING_PERIOD_DAYS = _newValue;
        } else {
            revert("Unknown protocol parameter");
        }
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /**
     * @notice Pauses the entire protocol, preventing most state-changing operations.
     * @dev Only callable by the owner. Useful for upgrades or emergency situations.
     */
    function pauseProtocol() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Unpauses the protocol, allowing operations to resume.
     * @dev Only callable by the owner.
     */
    function unpauseProtocol() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw accrued protocol fees.
     * @dev For conceptual use; in a real system, fees might be distributed automatically or
     *      managed by a more complex treasury system/DAO.
     * @param _token The address of the token to withdraw (address(0) for native ETH).
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawProtocolFees(address _token, uint256 _amount) external onlyOwner nonReentrant {
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "CerebralNexus: Insufficient ETH balance");
            (bool success, ) = payable(owner()).call{value: _amount}("");
            require(success, "CerebralNexus: ETH transfer failed");
        } else {
            IERC20 token = IERC20(_token);
            require(token.balanceOf(address(this)) >= _amount, "CerebralNexus: Insufficient token balance");
            require(token.transfer(owner(), _amount), "CerebralNexus: Token transfer failed");
        }
    }

    // --- II. Identity & Reputation Layer ---

    /**
     * @notice Registers a new, unique profile for a user within the CerebralNexus.
     * @dev This functions as a Soulbound Token (SBT) like identity.
     * @param _metadataURI A URI pointing to off-chain metadata (e.g., IPFS) for the user's profile.
     */
    function registerNexusProfile(string memory _metadataURI) external whenNotPaused {
        require(!nexusProfiles[msg.sender].exists, "CerebralNexus: Profile already exists");
        nexusProfiles[msg.sender] = NexusProfile({
            exists: true,
            metadataURI: _metadataURI,
            lastReputationUpdate: block.timestamp,
            baseReputation: 100 // Starting reputation for new profiles
        });
        emit NexusProfileRegistered(msg.sender, _metadataURI);
    }

    /**
     * @notice Allows a user to formally attest to another user's skill.
     * @dev Requires the attester to have a minimum reputation. A temporary stake or reputation lock
     *      could be added for more advanced scenarios (not implemented for simplicity).
     * @param _attestee The address of the user whose skill is being attested.
     * @param _skillHash A Keccak256 hash representing a standardized skill (e.g., hash("solidity_developer")).
     * @param _durationDays The number of days for which this attestation is valid.
     * @param _proofURI A URI pointing to off-chain proof supporting the attestation (e.g., project portfolio).
     */
    function attestSkill(address _attestee, bytes32 _skillHash, uint256 _durationDays, string memory _proofURI) external whenNotPaused nonReentrant {
        require(nexusProfiles[msg.sender].exists, "CerebralNexus: Attester must have a profile");
        require(nexusProfiles[_attestee].exists, "CerebralNexus: Attestee must have a profile");
        require(msg.sender != _attestee, "CerebralNexus: Cannot attest your own skill");
        require(_durationDays > 0, "CerebralNexus: Duration must be positive");
        require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_ATTESTATION, "CerebralNexus: Not enough reputation to attest");

        nextAttestationId++;
        uint256 expirationTime = block.timestamp + (_durationDays * 1 days);
        skillAttestations[nextAttestationId] = SkillAttestation({
            attester: msg.sender,
            attestee: _attestee,
            skillHash: _skillHash,
            issuedAt: block.timestamp,
            expiresAt: expirationTime,
            proofURI: _proofURI,
            isActive: true,
            challengeId: 0
        });

        emit SkillAttested(nextAttestationId, msg.sender, _attestee, _skillHash, expirationTime);
    }

    /**
     * @notice Allows the original attester to revoke their skill attestation.
     * @dev Revocation might incur a minor reputation penalty for the attester in a more complex system.
     * @param _attestationId The ID of the skill attestation to revoke.
     */
    function revokeSkillAttestation(uint256 _attestationId) external whenNotPaused {
        SkillAttestation storage attestation = skillAttestations[_attestationId];
        require(attestation.attester == msg.sender, "CerebralNexus: Only the attester can revoke");
        require(attestation.isActive, "CerebralNexus: Attestation is not active or already revoked");
        require(attestation.challengeId == 0, "CerebralNexus: Cannot revoke challenged attestation");

        attestation.isActive = false;
        emit SkillAttestationRevoked(_attestationId);
    }

    /**
     * @notice Retrieves details of a specific skill attestation.
     * @param _attestationId The ID of the attestation.
     * @return attester The address of the attester.
     * @return attestee The address of the attestee.
     * @return skillHash The hash of the skill.
     * @return issuedAt The timestamp when the attestation was issued.
     * @return expiresAt The timestamp when the attestation expires.
     * @return proofURI The URI for off-chain proof.
     * @return isActive The current active status of the attestation.
     */
    function getSkillAttestation(uint256 _attestationId) external view returns (
        address attester,
        address attestee,
        bytes32 skillHash,
        uint256 issuedAt,
        uint256 expiresAt,
        string memory proofURI,
        bool isActive
    ) {
        SkillAttestation storage attestation = skillAttestations[_attestationId];
        require(attestation.attester != address(0), "CerebralNexus: Attestation does not exist");
        return (
            attestation.attester,
            attestation.attestee,
            attestation.skillHash,
            attestation.issuedAt,
            attestation.expiresAt,
            attestation.proofURI,
            attestation.isActive
        );
    }

    /**
     * @notice Calculates a user's dynamic reputation score.
     * @dev This is a simplified calculation. A real, scalable system might use off-chain computation
     *      or more complex graph-based approaches with reputation shards/aggregators.
     *      Reputation decays over time if not actively maintained.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        NexusProfile storage profile = nexusProfiles[_user];
        if (!profile.exists) return 0;

        uint256 currentReputation = profile.baseReputation;

        // Apply decay since last update of `baseReputation`
        uint256 timeElapsedSeconds = block.timestamp - profile.lastReputationUpdate;
        uint256 decayPeriods = timeElapsedSeconds / 1 days; // Number of full days passed

        if (decayPeriods > 0) {
            // Apply decay rate: `currentReputation * (1 - (decayPeriods * REPUTATION_DECAY_RATE_PER_DAY_BPS / 10000))`
            uint256 decayFactor = (decayPeriods * REPUTATION_DECAY_RATE_PER_DAY_BPS);
            if (decayFactor >= 10000) { // Ensure we don't decay below zero with this simple formula
                currentReputation = 0;
            } else {
                currentReputation = (currentReputation * (10000 - decayFactor)) / 10000;
            }
        }

        // Conceptual: In a real system, active attestations received, successful project contributions,
        // and challenge outcomes would dynamically boost or penalize this score.
        // Iterating through all attestations for a user is gas-prohibitive on-chain for a large system,
        // so such factors would be managed through incremental updates or graph-based computations.
        return currentReputation;
    }

    /**
     * @notice Internal function to update a user's base reputation after a period of decay.
     * @dev This should be called strategically, perhaps during other reputation-modifying actions
     *      or by a keeper, to avoid excessive gas costs for simple reads.
     * @param _user The address of the user to update.
     */
    function _decayReputation(address _user) internal {
        NexusProfile storage profile = nexusProfiles[_user];
        if (!profile.exists) return;

        // Update baseReputation to its current (decayed) value
        profile.baseReputation = getReputationScore(_user);
        profile.lastReputationUpdate = block.timestamp;
    }


    // --- III. Resource Allocation & Project Management ---

    /**
     * @notice Creates a new Adaptive Resource Pool (ARP) for a project or initiative.
     * @dev Defines the target funding amount, the token to be used, and a list of milestones.
     * @param _name The name of the resource pool.
     * @param _descriptionURI A URI pointing to off-chain detailed description of the pool's purpose.
     * @param _targetAmount The total amount of funds targeted for this pool across all milestones.
     * @param _tokenAddress The ERC20 token address for funding (use address(0) for native ETH).
     * @param _milestones An array of Milestone structs defining project phases and their funding targets.
     */
    function createAdaptiveResourcePool(
        string memory _name,
        string memory _descriptionURI,
        uint256 _targetAmount,
        address _tokenAddress,
        Milestone[] memory _milestones
    ) external whenNotPaused {
        require(nexusProfiles[msg.sender].exists, "CerebralNexus: Creator must have a profile");
        require(_targetAmount > 0, "CerebralNexus: Target amount must be positive");
        require(_milestones.length > 0, "CerebralNexus: Must define at least one milestone");

        uint256 totalMilestoneAmount = 0;
        for (uint i = 0; i < _milestones.length; i++) {
            totalMilestoneAmount += _milestones[i].targetAmount;
        }
        require(totalMilestoneAmount <= _targetAmount, "CerebralNexus: Total milestone amounts exceed target pool amount");

        nextResourcePoolId++;
        AdaptiveResourcePool storage newPool = adaptiveResourcePools[nextResourcePoolId];
        newPool.creator = msg.sender;
        newPool.name = _name;
        newPool.descriptionURI = _descriptionURI;
        newPool.targetAmount = _targetAmount;
        newPool.tokenAddress = _tokenAddress;
        newPool.currentFundedAmount = 0;
        newPool.status = ResourcePoolStatus.Active;
        newPool.milestones = _milestones; // Deep copy for memory array to storage
        newPool.totalProposals = 0;
        newPool.approvedProposalId = 0;

        emit AdaptiveResourcePoolCreated(nextResourcePoolId, msg.sender, _targetAmount, _tokenAddress);
    }

    /**
     * @notice Allows users to submit detailed project proposals for funding from a specific ARP.
     * @dev Requires a minimum reputation to submit. Only one proposal can be approved per pool.
     * @param _resourcePoolId The ID of the Adaptive Resource Pool to which the proposal is submitted.
     * @param _proposalURI A URI pointing to off-chain detailed proposal document (e.g., IPFS).
     */
    function submitProjectProposal(uint256 _resourcePoolId, string memory _proposalURI) external whenNotPaused {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(pool.status == ResourcePoolStatus.Active, "CerebralNexus: Resource Pool is not active");
        require(pool.approvedProposalId == 0, "CerebralNexus: A proposal is already approved for this pool");
        require(getReputationScore(msg.sender) >= MIN_PROPOSAL_VOTE_REPUTATION, "CerebralNexus: Not enough reputation to submit proposal");

        pool.totalProposals++;
        pool.proposals[pool.totalProposals] = ProjectProposal({
            proposer: msg.sender,
            proposalURI: _proposalURI,
            submittedAt: block.timestamp,
            hasVoted: new mapping(address => bool),
            yesVotesWeighted: 0,
            noVotesWeighted: 0,
            approved: false
        });

        emit ProjectProposalSubmitted(_resourcePoolId, pool.totalProposals, msg.sender, _proposalURI);
    }

    /**
     * @notice Allows community members to vote on submitted project proposals.
     * @dev Vote weight is scaled by the voter's reputation score.
     *      A more robust system would include a voting period and quorum.
     * @param _resourcePoolId The ID of the resource pool.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for a "yes" vote, false for a "no" vote.
     */
    function voteOnProjectProposal(uint256 _resourcePoolId, uint256 _proposalId, bool _approve) external whenNotPaused {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        ProjectProposal storage proposal = pool.proposals[_proposalId];
        require(proposal.proposer != address(0), "CerebralNexus: Proposal does not exist");
        require(!proposal.hasVoted[msg.sender], "CerebralNexus: Already voted on this proposal");
        require(pool.approvedProposalId == 0, "CerebralNexus: A proposal is already approved for this pool");
        require(getReputationScore(msg.sender) >= MIN_PROPOSAL_VOTE_REPUTATION, "CerebralNexus: Not enough reputation to vote");

        proposal.hasVoted[msg.sender] = true;
        uint256 voteWeight = getReputationScore(msg.sender);

        if (_approve) {
            proposal.yesVotesWeighted += voteWeight;
        } else {
            proposal.noVotesWeighted += voteWeight;
        }

        // Conceptual: Simple majority + a threshold for approval
        // A real DAO would likely have a separate function to finalize proposals after a voting period
        // and consider quorum.
        if (proposal.yesVotesWeighted > proposal.noVotesWeighted && proposal.yesVotesWeighted > (pool.targetAmount / 100)) { // Example threshold, can be refined.
            proposal.approved = true;
            pool.approvedProposalId = _proposalId;
        }

        emit ProjectProposalVoted(_proposalId, msg.sender, _approve, voteWeight);
    }

    /**
     * @notice Allows anyone to contribute funds to an Adaptive Resource Pool.
     * @dev Funds are collected and held by the contract for the pool's milestones.
     * @param _resourcePoolId The ID of the resource pool to fund.
     * @param _amount The amount of funds to contribute.
     */
    function fundResourcePool(uint256 _resourcePoolId, uint256 _amount) external payable whenNotPaused nonReentrant {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(pool.status == ResourcePoolStatus.Active, "CerebralNexus: Resource Pool is not active");
        require(pool.approvedProposalId != 0, "CerebralNexus: No approved proposal for this pool yet");
        require(pool.currentFundedAmount + _amount <= pool.targetAmount, "CerebralNexus: Funding exceeds target amount");


        if (pool.tokenAddress == address(0)) { // Native ETH
            require(msg.value == _amount, "CerebralNexus: ETH amount mismatch");
            pool.currentFundedAmount += _amount;
        } else { // ERC20 token
            require(msg.value == 0, "CerebralNexus: Do not send ETH with ERC20 funding");
            IERC20 token = IERC20(pool.tokenAddress);
            require(token.transferFrom(msg.sender, address(this), _amount), "CerebralNexus: ERC20 transfer failed. Check allowance.");
            pool.currentFundedAmount += _amount;
        }
        emit ResourcePoolFunded(_resourcePoolId, msg.sender, _amount);
    }

    /**
     * @notice Allows the project lead (creator or approved proposer) to report a milestone as completed.
     * @dev This triggers a verification period where it can be challenged or verified by an oracle.
     * @param _resourcePoolId The ID of the resource pool.
     * @param _milestoneIndex The index of the milestone within the pool's milestone array.
     */
    function reportMilestoneCompletion(uint256 _resourcePoolId, uint256 _milestoneIndex) external whenNotPaused {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(msg.sender == pool.creator || msg.sender == pool.proposals[pool.approvedProposalId].proposer, "CerebralNexus: Only project creator or proposer can report");
        require(_milestoneIndex < pool.milestones.length, "CerebralNexus: Invalid milestone index");
        require(!pool.milestones[_milestoneIndex].isCompleted, "CerebralNexus: Milestone already reported completed");

        pool.milestones[_milestoneIndex].isCompleted = true;
        emit MilestoneReported(_resourcePoolId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Releases funds for a milestone after it has been verified as completed.
     * @dev Verification can occur through an external oracle or by the resolution of a Nexus Challenge.
     * @param _resourcePoolId The ID of the resource pool.
     * @param _milestoneIndex The index of the milestone.
     */
    function releaseMilestoneFunds(uint256 _resourcePoolId, uint256 _milestoneIndex) external whenNotPaused nonReentrant {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(_milestoneIndex < pool.milestones.length, "CerebralNexus: Invalid milestone index");
        Milestone storage milestone = pool.milestones[_milestoneIndex];
        require(milestone.isCompleted, "CerebralNexus: Milestone not reported as completed");
        require(!milestone.isVerified, "CerebralNexus: Milestone already verified or funds released");

        // Ensure milestone is not under active challenge
        if (milestone.challengeId != 0) {
            require(nexusChallenges[milestone.challengeId].status == ChallengeStatus.Resolved, "CerebralNexus: Milestone is currently under challenge or challenge not resolved");
            // If challenged and resolution was "milestone IS NOT complete" (finalOutcome = true), then fail.
            require(!nexusChallenges[milestone.challengeId].finalOutcome, "CerebralNexus: Milestone challenge failed verification");
        } else {
            // Conceptual: If no challenge was initiated within a grace period (not implemented),
            // or if an oracle has verified it.
            // For this example, we'll allow the creator to call it if no challenge,
            // but a real system would gate this by time or oracle.
        }

        require(pool.currentFundedAmount >= milestone.targetAmount, "CerebralNexus: Insufficient funds in pool for milestone");

        milestone.isVerified = true; // Mark as verified

        pool.currentFundedAmount -= milestone.targetAmount;
        address recipient = pool.proposals[pool.approvedProposalId].proposer;
        if (pool.tokenAddress == address(0)) { // Native ETH
            (bool success, ) = payable(recipient).call{value: milestone.targetAmount}("");
            require(success, "CerebralNexus: ETH transfer failed");
        } else { // ERC20 token
            IERC20 token = IERC20(pool.tokenAddress);
            require(token.transfer(recipient, milestone.targetAmount), "CerebralNexus: Token transfer failed");
        }

        emit MilestoneFundsReleased(_resourcePoolId, _milestoneIndex, milestone.targetAmount);

        // Check if all milestones are complete and update pool status
        bool allMilestonesVerified = true;
        for (uint i = 0; i < pool.milestones.length; i++) {
            if (!pool.milestones[i].isVerified) {
                allMilestonesVerified = false;
                break;
            }
        }
        if (allMilestonesVerified) {
            pool.status = ResourcePoolStatus.Completed;
        }
    }

    /**
     * @notice Reallocates unused funds from a stalled or failed resource pool.
     * @dev Only callable by the owner (or DAO). Funds can be returned to contributors (complex)
     *      or sent to a common treasury (simplified here to owner).
     * @param _resourcePoolId The ID of the resource pool.
     */
    function reallocateUnusedFunds(uint256 _resourcePoolId) external onlyOwner nonReentrant {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(pool.status != ResourcePoolStatus.Completed, "CerebralNexus: Pool already completed");
        require(pool.status != ResourcePoolStatus.Failed, "CerebralNexus: Pool already failed");

        // Conceptual: This function assumes the pool is deemed "stalled" or "failed" by governance.
        // In a real system, this could be triggered by lack of activity, failed challenges, or specific DAO votes.

        uint256 remainingFunds = pool.currentFundedAmount;
        pool.currentFundedAmount = 0;
        pool.status = ResourcePoolStatus.Failed; // Mark as failed

        if (remainingFunds > 0) {
            if (pool.tokenAddress == address(0)) {
                (bool success, ) = payable(owner()).call{value: remainingFunds}(""); // Send to owner/treasury
                require(success, "CerebralNexus: ETH reallocation failed");
            } else {
                IERC20 token = IERC20(pool.tokenAddress);
                require(token.transfer(owner(), remainingFunds), "CerebralNexus: Token reallocation failed");
            }
            emit FundsReallocated(_resourcePoolId, remainingFunds);
        }
    }

    // --- IV. Dispute Resolution & Validation (Nexus Challenges) ---

    /**
     * @notice Initiates a Nexus Challenge against an existing skill attestation.
     * @param _attestationId The ID of the skill attestation to challenge.
     * @param _challengeReasonURI A URI pointing to off-chain documentation for the reason of the challenge.
     */
    function challengeSkillAttestation(uint256 _attestationId, string memory _challengeReasonURI) external whenNotPaused {
        SkillAttestation storage attestation = skillAttestations[_attestationId];
        require(attestation.attester != address(0), "CerebralNexus: Attestation does not exist");
        require(attestation.isActive, "CerebralNexus: Attestation is not active or already challenged");
        require(attestation.challengeId == 0, "CerebralNexus: Attestation already under challenge");
        require(msg.sender != attestation.attester && msg.sender != attestation.attestee, "CerebralNexus: Cannot challenge your own attestation or one you attested to");
        require(getReputationScore(msg.sender) > 0, "CerebralNexus: Initiator must have reputation"); // Prevent spam

        nextChallengeId++;
        NexusChallenge storage newChallenge = nexusChallenges[nextChallengeId];
        newChallenge.initiator = msg.sender;
        newChallenge.reasonURI = _challengeReasonURI;
        newChallenge.initiatedAt = block.timestamp;
        newChallenge.votingEndsAt = block.timestamp + (NEXUS_CHALLENGE_VOTING_PERIOD_DAYS * 1 days);
        newChallenge.status = ChallengeStatus.PendingEvidence;
        newChallenge.challengeType = ChallengeType.SkillAttestation;
        newChallenge.subjectId = _attestationId; // The ID of the attestation being challenged

        attestation.challengeId = nextChallengeId; // Link attestation to this new challenge

        emit NexusChallengeInitiated(nextChallengeId, "SkillAttestation", _attestationId, msg.sender);
    }

    /**
     * @notice Initiates a Nexus Challenge against a reported milestone completion.
     * @dev A composite ID `(poolId << 16) | milestoneIndex` is used for the subjectId.
     * @param _resourcePoolId The ID of the resource pool containing the milestone.
     * @param _milestoneIndex The index of the milestone within the pool's milestone array.
     * @param _challengeReasonURI A URI pointing to off-chain documentation for the reason of the challenge.
     */
    function challengeMilestoneCompletion(uint256 _resourcePoolId, uint256 _milestoneIndex, string memory _challengeReasonURI) external whenNotPaused {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");
        require(_milestoneIndex < pool.milestones.length, "CerebralNexus: Invalid milestone index");
        Milestone storage milestone = pool.milestones[_milestoneIndex];
        require(milestone.isCompleted, "CerebralNexus: Milestone not reported as completed");
        require(!milestone.isVerified, "CerebralNexus: Milestone already verified");
        require(milestone.challengeId == 0, "CerebralNexus: Milestone already under challenge");
        require(msg.sender != pool.creator && msg.sender != pool.proposals[pool.approvedProposalId].proposer, "CerebralNexus: Creator/Proposer cannot challenge their own milestone");
        require(getReputationScore(msg.sender) > 0, "CerebralNexus: Initiator must have reputation"); // Prevent spam

        // Create a unique composite ID for the milestone being challenged
        uint256 compositeMilestoneId = (_resourcePoolId << 16) | _milestoneIndex; // Assumes milestoneIndex < 2^16 (65536)

        nextChallengeId++;
        NexusChallenge storage newChallenge = nexusChallenges[nextChallengeId];
        newChallenge.initiator = msg.sender;
        newChallenge.reasonURI = _challengeReasonURI;
        newChallenge.initiatedAt = block.timestamp;
        newChallenge.votingEndsAt = block.timestamp + (NEXUS_CHALLENGE_VOTING_PERIOD_DAYS * 1 days);
        newChallenge.status = ChallengeStatus.PendingEvidence;
        newChallenge.challengeType = ChallengeType.MilestoneCompletion;
        newChallenge.subjectId = compositeMilestoneId;

        milestone.challengeId = nextChallengeId; // Link milestone to this new challenge

        emit NexusChallengeInitiated(nextChallengeId, "MilestoneCompletion", compositeMilestoneId, msg.sender);
    }

    /**
     * @notice Allows participants to submit supporting evidence for an ongoing Nexus Challenge.
     * @dev Evidence is stored as a URI; a more complex system might use on-chain hashes of evidence.
     * @param _challengeId The ID of the challenge.
     * @param _evidenceURI A URI pointing to off-chain evidence.
     */
    function submitChallengeEvidence(uint256 _challengeId, string memory _evidenceURI) external whenNotPaused {
        NexusChallenge storage challenge = nexusChallenges[_challengeId];
        require(challenge.initiator != address(0), "CerebralNexus: Challenge does not exist");
        require(challenge.status == ChallengeStatus.PendingEvidence || challenge.status == ChallengeStatus.Voting, "CerebralNexus: Challenge not in evidence submission phase");
        // For simplicity, just emit the event. In a real system, the evidence URI would be stored
        // perhaps in an array within the NexusChallenge struct, or a separate mapping.
        emit NexusChallengeEvidenceSubmitted(_challengeId, msg.sender, _evidenceURI);
    }

    /**
     * @notice Allows community members to vote on the outcome of an ongoing Nexus Challenge.
     * @dev Vote weight is scaled by the voter's reputation.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _outcome True if supporting the challenge (i.e., attestation/milestone is false/not completed),
     *                 False if opposing the challenge (i.e., attestation/milestone is true/completed).
     */
    function voteOnChallengeOutcome(uint256 _challengeId, bool _outcome) external whenNotPaused {
        NexusChallenge storage challenge = nexusChallenges[_challengeId];
        require(challenge.initiator != address(0), "CerebralNexus: Challenge does not exist");
        require(block.timestamp <= challenge.votingEndsAt, "CerebralNexus: Voting period has ended");
        require(challenge.status == ChallengeStatus.PendingEvidence || challenge.status == ChallengeStatus.Voting, "CerebralNexus: Challenge not in voting phase");
        require(getReputationScore(msg.sender) > 0, "CerebralNexus: Voter must have reputation");
        require(!challenge.hasVoted[msg.sender], "CerebralNexus: Already voted on this challenge");

        challenge.hasVoted[msg.sender] = true;
        uint256 voteWeight = getReputationScore(msg.sender);

        if (_outcome) { // _outcome = true means supporting the challenge (e.g., attestation is false, milestone is not completed)
            challenge.yesVotesWeighted += voteWeight;
        } else { // _outcome = false means opposing the challenge (e.g., attestation is true, milestone is completed)
            challenge.noVotesWeighted += voteWeight;
        }
        challenge.status = ChallengeStatus.Voting; // Ensure status moves to voting once votes start coming in.

        emit NexusChallengeVoted(_challengeId, msg.sender, _outcome);
    }

    /**
     * @notice Resolves a Nexus Challenge after its voting period has ended, applying consequences.
     * @dev Adjusts reputation scores of involved parties and updates the status of the challenged subject.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveNexusChallenge(uint256 _challengeId) external whenNotPaused {
        NexusChallenge storage challenge = nexusChallenges[_challengeId];
        require(challenge.initiator != address(0), "CerebralNexus: Challenge does not exist");
        require(block.timestamp > challenge.votingEndsAt, "CerebralNexus: Voting period not ended yet");
        require(challenge.status != ChallengeStatus.Resolved, "CerebralNexus: Challenge already resolved");

        bool finalOutcome = false; // Default: challenge failed (original state persists)
        if (challenge.yesVotesWeighted > challenge.noVotesWeighted) {
            finalOutcome = true; // Challenge succeeded (e.g., attestation was indeed false)
        }

        challenge.finalOutcome = finalOutcome;
        challenge.status = ChallengeStatus.Resolved;

        // Apply consequences based on challenge type and outcome
        if (challenge.challengeType == ChallengeType.SkillAttestation) {
            SkillAttestation storage attestation = skillAttestations[challenge.subjectId];
            if (finalOutcome) { // If challenge succeeded (attestation found false)
                attestation.isActive = false; // Deactivate the attestation
                // Conceptual: Reduce reputation of attester and attestee
                // _penalizeReputation(attestation.attester, penaltyAmount);
                // _penalizeReputation(attestation.attestee, penaltyAmount);
                // Conceptual: Reward challenger
                // _boostReputation(challenge.initiator, rewardAmount);
            } else { // If challenge failed (attestation found true)
                // Conceptual: Boost reputation of attester and attestee
                // _boostReputation(attestation.attester, rewardAmount);
                // _boostReputation(attestation.attestee, rewardAmount);
                // Conceptual: Penalize challenger
                // _penalizeReputation(challenge.initiator, penaltyAmount);
            }
            attestation.challengeId = 0; // Unlink challenge after resolution
        } else if (challenge.challengeType == ChallengeType.MilestoneCompletion) {
            // Reconstruct poolId and milestoneIndex from composite subjectId
            uint256 poolId = challenge.subjectId >> 16;
            uint256 milestoneIndex = challenge.subjectId & 0xFFFF;

            AdaptiveResourcePool storage pool = adaptiveResourcePools[poolId];
            Milestone storage milestone = pool.milestones[milestoneIndex];

            if (finalOutcome) { // If challenge succeeded (milestone was NOT completed correctly)
                milestone.isVerified = false; // Mark as not verified
                milestone.isCompleted = false; // Reset completion status, requiring re-report
                // Conceptual: Reduce reputation of reporter/proposer
            } else { // If challenge failed (milestone was indeed completed correctly)
                milestone.isVerified = true; // Mark as verified (can now release funds)
                // Conceptual: Boost reputation of reporter/proposer, reduce reputation of challenger
            }
            milestone.challengeId = 0; // Unlink challenge after resolution
        }

        emit NexusChallengeResolved(_challengeId, finalOutcome);
    }

    // --- V. Dynamic Incentives & Protocol Economics ---

    /**
     * @notice Allows users to claim periodic rewards based on their aggregated reputation score and active contributions.
     * @dev This is a simplified conceptual function. A real system would have a dedicated rewards pool
     *      and a more complex mechanism to track and distribute rewards (e.g., tokenomics, vesting).
     */
    function claimReputationRewards() external whenNotPaused nonReentrant {
        require(nexusProfiles[msg.sender].exists, "CerebralNexus: User has no profile");
        uint256 rewards = _calculateReputationRewards(msg.sender);
        require(rewards > 0, "CerebralNexus: No rewards to claim");

        // Conceptual: Assume rewards are in native ETH for this example.
        // In a real system, this would be a specific reward token transfer.
        (bool success, ) = payable(msg.sender).call{value: rewards}("");
        require(success, "CerebralNexus: Reward transfer failed");

        // Conceptual: Reset reward calculation state for the user (e.g., last claim timestamp)
        // This is omitted for brevity but crucial for preventing double claims.
        emit ReputationRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Internal conceptual function to calculate rewards.
     * @param _user The address of the user.
     * @return The conceptual reward amount in wei.
     */
    function _calculateReputationRewards(address _user) internal view returns (uint256) {
        uint256 currentReputation = getReputationScore(_user);
        // Example simple formula: 1 wei per 10 reputation points.
        // This is highly simplified and would need a proper economic model.
        return currentReputation / 10;
    }

    /**
     * @notice Sets the address of an external oracle contract.
     * @dev This oracle could be used for verifying milestone completions, fetching external data, etc.
     * @param _oracleAddress The address of the trusted oracle contract.
     */
    function setExternalOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "CerebralNexus: Oracle address cannot be zero");
        externalOracleAddress = _oracleAddress;
    }

    // --- Utility View Functions ---

    /**
     * @notice Returns a comprehensive view of a user's Nexus profile and statistics.
     * @param _user The address of the user.
     * @return exists True if the profile exists.
     * @return metadataURI The URI to the user's off-chain profile metadata.
     * @return reputationScore The user's current dynamic reputation score.
     * @return lastReputationUpdate The timestamp of the last reputation update/decay application.
     */
    function getProfileStats(address _user) external view returns (
        bool exists,
        string memory metadataURI,
        uint256 reputationScore,
        uint256 lastReputationUpdate
    ) {
        NexusProfile storage profile = nexusProfiles[_user];
        if (!profile.exists) return (false, "", 0, 0);

        return (
            profile.exists,
            profile.metadataURI,
            getReputationScore(_user), // Recompute live score
            profile.lastReputationUpdate
        );
    }

    /**
     * @notice Returns statistics about a specific Adaptive Resource Pool.
     * @param _resourcePoolId The ID of the resource pool.
     * @return name The name of the pool.
     * @return descriptionURI The URI to the pool's off-chain description.
     * @return creator The address of the pool's creator.
     * @return targetAmount The total target funding amount for the pool.
     * @return currentFundedAmount The current amount of funds collected in the pool.
     * @return tokenAddress The address of the token used for funding.
     * @return status The current status of the pool (Active, Closed, Failed, Completed).
     * @return totalMilestones The total number of milestones defined for the pool.
     * @return completedMilestones The number of milestones reported as completed.
     * @return verifiedMilestones The number of milestones verified as completed.
     * @return approvedProposalId The ID of the currently approved project proposal for this pool.
     */
    function getPoolStats(uint256 _resourcePoolId) external view returns (
        string memory name,
        string memory descriptionURI,
        address creator,
        uint256 targetAmount,
        uint256 currentFundedAmount,
        address tokenAddress,
        ResourcePoolStatus status,
        uint256 totalMilestones,
        uint256 completedMilestones,
        uint256 verifiedMilestones,
        uint256 approvedProposalId
    ) {
        AdaptiveResourcePool storage pool = adaptiveResourcePools[_resourcePoolId];
        require(pool.creator != address(0), "CerebralNexus: Resource Pool does not exist");

        uint256 _completedMilestones = 0;
        uint256 _verifiedMilestones = 0;
        for (uint i = 0; i < pool.milestones.length; i++) {
            if (pool.milestones[i].isCompleted) _completedMilestones++;
            if (pool.milestones[i].isVerified) _verifiedMilestones++;
        }

        return (
            pool.name,
            pool.descriptionURI,
            pool.creator,
            pool.targetAmount,
            pool.currentFundedAmount,
            pool.tokenAddress,
            pool.status,
            pool.milestones.length,
            _completedMilestones,
            _verifiedMilestones,
            pool.approvedProposalId
        );
    }

    /**
     * @dev Fallback function to allow the contract to receive native ETH.
     *      Any direct ETH transfers not intended for a specific fundResourcePool call will be received here.
     */
    receive() external payable {
        // This can be used for general treasury contributions if designed,
        // or to simply prevent ETH from being lost if sent directly.
    }
}
```