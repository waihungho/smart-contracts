This smart contract, named **DAIRIN (Decentralized Adaptive Reputation and Impact Network)**, is designed as a sophisticated decentralized autonomous organization (DAO) platform. It introduces several advanced concepts:

1.  **Soulbound Tokens (SBTs) for Dynamic Reputation:** Non-transferable tokens represent verified skills, contributions, or achievements, forming the basis of a user's on-chain identity and reputation.
2.  **Adaptive, Decay-Based Reputation System:** Users' reputation scores are dynamically calculated based on their active SBTs, successful participation in impact initiatives, and governance engagement. This score is subject to decay over time, encouraging continuous positive participation.
3.  **Impact Initiatives with Milestone-Based Funding:** A mechanism for the community to propose and fund projects (initiatives) through token staking. Funds are released progressively upon verification of milestones, integrating a form of "proof of work" for decentralized funding.
4.  **Game-Theoretic Challenge Mechanisms:** Users can dispute the validity of skill attestations or claimed initiative milestones, introducing checks and balances against fraudulent claims. These disputes can be resolved by a trusted oracle or through further governance.
5.  **Dynamic Governance Weighting:** Voting power in governance proposals is not just token-weighted but also heavily influenced by a user's reputation score and active stakes, making the governance more meritocratic and less susceptible to pure plutocracy.
6.  **Community Dispute System:** A general mechanism to initiate and resolve disputes concerning user behavior or actions within the network, with potential reputation consequences.

This contract aims to foster a more accountable, merit-driven, and active decentralized community.

---

## DAIRIN Smart Contract Outline & Function Summary

**Core Components:**
1.  **SkillAttestationSBT:** A custom, non-transferable ERC721 token used to record and verify skills, contributions, or achievements.
2.  **Impact Token (ERC20):** The native ERC20 token for staking in initiatives, earning rewards, and participating in governance.
3.  **Impact Initiatives:** Community-proposed projects with funding goals and milestone-based progress.
4.  **Dynamic Reputation System:** An on-chain score for users, influenced by their SBTs, initiative participation, and governance, with built-in decay.
5.  **Adaptive Governance:** A system where voting power is derived from both token stakes and reputation.
6.  **Oracle Integration:** For external data verification, particularly for initiative milestones and dispute resolution.

---

### Function Summary (29 functions)

**I. Admin & Configuration Functions:**

1.  **`updateOracleAddress(address _newOracleAddress)`:** (Admin) Updates the address of the trusted oracle responsible for external verifications.
2.  **`pause()`:** (Admin) Pauses contract operations in emergencies (inherits from Pausable).
3.  **`unpause()`:** (Admin) Unpauses contract operations (inherits from Pausable).

**II. Reputation & SBT Management Functions:**

4.  **`attestSkill(address _to, string memory _skillURI)`:** Mints a non-transferable Skill Attestation SBT to `_to`, representing a verified skill or contribution by `msg.sender`.
5.  **`revokeAttestation(uint256 _sbtTokenId)`:** (Attestor or Admin) Revokes a previously issued skill attestation, marking it as invalid.
6.  **`challengeAttestation(uint256 _sbtTokenId)`:** Allows a user to formally dispute the validity of an existing skill attestation, moving its status to 'UnderChallenge'.
7.  **`resolveAttestationChallenge(uint256 _sbtTokenId, bool _isValid)`:** (Oracle or Admin) Resolves a challenged attestation, either validating it or marking it as invalid.
8.  **`getReputationScore(address _user)`:** (View) Returns the current dynamic reputation score of a given user, accounting for decay.
9.  **`freezeReputation(address _user)`:** (Admin) Freezes the reputation score of a user (sets to 0), typically for malicious actors, preventing further accumulation or decay.

**III. Impact Initiative Management Functions:**

10. **`createImpactInitiative(string memory _name, string memory _description, uint256 _fundingGoal, uint256 _numMilestones)`:** Proposes a new impact initiative, specifying its goal, description, funding target, and number of milestones.
11. **`fundImpactInitiative(uint256 _initiativeId, uint256 _amount)`:** Stakes `_amount` of Impact Tokens towards an initiative, contributing to its funding goal.
12. **`withdrawInitiativeFunds(uint256 _initiativeId, uint256 _amount)`:** Allows a funder to withdraw their staked tokens from an initiative, if conditions permit (e.g., initiative not active or failed).
13. **`proposeMilestoneAchieved(uint256 _initiativeId, uint256 _milestoneNumber)`:** (Initiative Creator) Declares that a specific milestone for their initiative has been achieved, moving the initiative into a review state.
14. **`verifyMilestoneAchieved(uint256 _initiativeId, uint256 _milestoneNumber)`:** (Oracle or Governance) Confirms the achievement of a milestone, potentially releasing a portion of funds to the creator.
15. **`challengeMilestone(uint256 _initiativeId, uint256 _milestoneNumber)`:** Allows a user to dispute the claim that a milestone has been achieved, moving the initiative into a 'Challenged' state.
16. **`resolveMilestoneChallenge(uint256 _initiativeId, uint256 _milestoneNumber, bool _isValid)`:** (Oracle or Governance) Resolves a challenged milestone, validating or invalidating the claim, and applying consequences (e.g., penalties).
17. **`getInitiativeStatus(uint256 _initiativeId)`:** (View) Returns the current status of an impact initiative (e.g., Proposed, Funding, Active, Completed).
18. **`getUserStakedAmount(uint256 _initiativeId, address _user)`:** (View) Returns the amount of tokens a user has staked in a specific initiative.

**IV. Dynamic Governance Functions:**

19. **`proposeNetworkUpgrade(string memory _description, address _targetContract, bytes memory _callData)`:** Allows users with sufficient reputation to propose a network-level change or upgrade, including arbitrary contract calls.
20. **`getVotingWeight(address _user)`:** (View) Calculates and returns the effective voting weight of a user, considering their reputation and any delegation.
21. **`voteOnProposal(uint256 _proposalId, bool _support)`:** Casts a vote (for or against) on a governance proposal, with voting weight determined dynamically.
22. **`executeProposal(uint256 _proposalId)`:** Executes a successful governance proposal that has passed its voting period and met quorum/majority.
23. **`delegateReputation(address _delegatee)`:** Delegates one's voting power (reputation) to another address.
24. **`undelegateReputation()`:** Revokes any existing reputation delegation.

**V. Treasury & Reward Functions:**

25. **`depositIntoTreasury(uint256 _amount)`:** Allows any user to deposit Impact Tokens into the contract's treasury.
26. **`distributeRewards(address _recipient, uint256 _amount)`:** (Admin or Governance) Distributes Impact Tokens from the treasury as rewards to a specified recipient.
27. **`getTreasuryBalance()`:** (View) Returns the current balance of Impact Tokens held by the contract's treasury.

**VI. Community Dispute Mechanism:**

28. **`initiateCommunityDispute(address _targetUser, string memory _details)`:** Initiates a general community dispute against a user, for behaviors not covered by specific challenge mechanisms.
29. **`resolveCommunityDispute(uint256 _disputeId, bool _outcome)`:** (Oracle or Governance) Resolves a community dispute, affecting the target user's reputation based on the outcome.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Non-Transferable ERC721 for Skill Attestations (Soulbound Token)
// This contract handles the minting, revocation, and challenging of non-transferable skill attestations.
// Each attestation is an SBT, linked to an attestor and an attested address, with a status.
contract SkillAttestationSBT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Statuses for an attestation SBT
    enum AttestationStatus {
        Active,                     // 0: Attestation is valid
        UnderChallenge,             // 1: Attestation is currently being disputed
        Revoked,                    // 2: Attestation was voluntarily revoked by the attestor or governance
        ChallengedResolvedInvalid   // 3: Attestation was challenged and found to be invalid
    }

    // Mapping from tokenId to the address of the user who issued the attestation
    mapping(uint256 => address) public attestors;
    // Mapping from tokenId to the address of the user who received the attestation
    mapping(uint256 => address) public attestedAddresses;
    // Mapping from tokenId to its current status
    mapping(uint256 => AttestationStatus) public attestationStatus;

    // Events related to SBT lifecycle
    event SkillAttested(address indexed attestor, address indexed attestedTo, uint256 tokenId, string skillURI);
    event AttestationRevoked(uint256 indexed tokenId);
    event AttestationChallenged(uint256 indexed tokenId, address indexed challenger);
    event AttestationChallengeResolved(uint256 indexed tokenId, bool isValid, address indexed resolver);

    /// @dev Constructor to initialize the SBT with a name and symbol.
    /// @param name The name of the SBT collection.
    /// @param symbol The symbol of the SBT collection.
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    /// @notice Mints a new skill attestation SBT to a specific address.
    /// @dev This function is internal and expected to be called by the DAIRIN main contract.
    /// @param to The address receiving the attestation.
    /// @param skillURI A URI (e.g., IPFS link) pointing to the skill's metadata.
    /// @return The ID of the newly minted SBT.
    function mint(address to, string memory skillURI) internal returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, skillURI); // Can be a link to an IPFS JSON describing the skill
        attestors[newTokenId] = msg.sender;
        attestedAddresses[newTokenId] = to;
        attestationStatus[newTokenId] = AttestationStatus.Active;
        emit SkillAttested(msg.sender, to, newTokenId, skillURI);
        return newTokenId;
    }

    /// @dev Overrides `_approve` to prevent any approval for transfers, enforcing non-transferability.
    function _approve(address to, uint256 tokenId) internal pure override {
        revert("SBTs are non-transferable");
    }

    /// @dev Overrides `setApprovalForAll` to prevent approvals for transfers, enforcing non-transferability.
    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("SBTs are non-transferable");
    }

    /// @dev Overrides `transferFrom` to prevent direct transfers, enforcing non-transferability.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBTs are non-transferable");
    }

    /// @dev Overrides `safeTransferFrom` to prevent direct transfers, enforcing non-transferability.
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBTs are non-transferable");
    }

    /// @notice Marks an attestation as revoked.
    /// @dev Internal function called by the DAIRIN main contract for revocation by attestor or governance.
    /// @param tokenId The ID of the SBT to revoke.
    function _revoke(uint256 tokenId) internal {
        require(_exists(tokenId), "SBT: token does not exist");
        attestationStatus[tokenId] = AttestationStatus.Revoked;
        emit AttestationRevoked(tokenId);
    }

    /// @notice Marks an attestation as being under challenge.
    /// @dev Internal function called by the DAIRIN main contract when a challenge is initiated.
    /// @param tokenId The ID of the SBT under challenge.
    /// @param challenger The address that initiated the challenge.
    function _markUnderChallenge(uint256 tokenId, address challenger) internal {
        require(_exists(tokenId), "SBT: token does not exist");
        require(attestationStatus[tokenId] == AttestationStatus.Active, "SBT: attestation not active");
        attestationStatus[tokenId] = AttestationStatus.UnderChallenge;
        emit AttestationChallenged(tokenId, challenger);
    }

    /// @notice Resolves a challenge on an attestation.
    /// @dev Internal function called by the DAIRIN main contract to finalize a challenge.
    /// @param tokenId The ID of the SBT whose challenge is being resolved.
    /// @param isValid True if the attestation is upheld, false if it is deemed invalid.
    /// @param resolver The address that resolved the challenge.
    function _resolveChallenge(uint256 tokenId, bool isValid, address resolver) internal {
        require(_exists(tokenId), "SBT: token does not exist");
        require(attestationStatus[tokenId] == AttestationStatus.UnderChallenge, "SBT: attestation not under challenge");
        attestationStatus[tokenId] = isValid ? AttestationStatus.Active : AttestationStatus.ChallengedResolvedInvalid;
        emit AttestationChallengeResolved(tokenId, isValid, resolver);
    }
}


// Main Contract: Decentralized Adaptive Reputation and Impact Network (DAIRIN)
// This contract orchestrates impact initiatives, dynamic reputation, and adaptive governance.
contract DAIRIN is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Configuration & Constants ---
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Minimum reputation to create a governance proposal
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;    // Duration for governance proposal voting
    uint256 public constant CHALLENGE_PERIOD = 3 days;          // Time window to challenge a milestone
    uint256 public constant REPUTATION_DECAY_RATE = 1;          // Reputation points decayed per day

    address public oracleAddress; // Address of a trusted oracle for external data verification

    // --- Tokens ---
    ERC20 public impactToken;     // The native ERC20 token for staking, rewards, and governance
    SkillAttestationSBT public skillSBT; // Non-transferable tokens for skill attestations

    // --- Data Structures ---

    /// @dev Struct to represent a governance proposal.
    struct Proposal {
        uint256 proposalId;         // Unique ID for the proposal
        address proposer;           // Address of the user who created the proposal
        string description;         // Link to IPFS or detailed description of the proposal
        bytes callData;             // Encoded function call for execution upon proposal success
        address targetContract;     // Target contract for the callData
        uint256 creationTime;       // Timestamp when the proposal was created
        uint256 endTime;            // Timestamp when the voting period ends
        uint256 votesFor;           // Total voting weight for the proposal
        uint256 votesAgainst;       // Total voting weight against the proposal
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;              // True if the proposal has been successfully executed
        bool active;                // True if the proposal is currently active for voting
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    /// @dev Enum for the various statuses of an Impact Initiative.
    enum InitiativeStatus {
        Proposed,               // Initial state after creation
        Funding,                // Actively receiving funds
        Active,                 // Fully funded and undergoing work
        MilestoneUnderReview,   // A milestone has been proposed and is awaiting verification/challenge
        Completed,              // All milestones achieved and funds disbursed
        Failed,                 // Initiative failed (e.g., funding goal not met, challenge failed)
        Challenged              // A milestone claim is under dispute
    }

    /// @dev Struct to represent an Impact Initiative.
    struct ImpactInitiative {
        uint256 initiativeId;        // Unique ID for the initiative
        address creator;             // Address of the user who created the initiative
        string name;                 // Name of the initiative
        string description;          // Link to IPFS for detailed description
        uint256 fundingGoal;         // Total impact tokens required
        uint256 currentFunding;      // Current amount of impact tokens staked
        uint256 proposalTime;        // Timestamp when the initiative was proposed
        InitiativeStatus status;     // Current status of the initiative
        uint256 lastMilestoneTime;   // Timestamp of the last proposed/verified milestone
        uint256 numMilestones;       // Total number of milestones planned
        uint256 completedMilestones; // Number of milestones successfully completed
        mapping(address => uint256) stakedAmounts; // User to their staked amount for this initiative
    }
    Counters.Counter private _initiativeIds;
    mapping(uint256 => ImpactInitiative) public impactInitiatives;

    // Reputation scores (non-transferable, dynamic, and subject to decay)
    mapping(address => uint256) private _reputationScores;
    // Last activity time for each user to calculate reputation decay
    mapping(address => uint256) private _lastReputationUpdateTime;

    // Delegations for voting power: delegator => delegatee
    mapping(address => address) public delegates;

    /// @dev Struct to represent a general community dispute.
    struct CommunityDispute {
        uint256 disputeId;          // Unique ID for the dispute
        address initiator;          // Address of the user who raised the dispute
        address targetUser;         // Address of the user against whom the dispute is raised
        string details;             // Link to IPFS for detailed dispute description
        uint256 creationTime;       // Timestamp when the dispute was initiated
        bool resolved;              // True if the dispute has been resolved
        bool outcome;               // True if target user is found 'guilty'/'invalid', false if 'innocent'/'valid'
    }
    Counters.Counter private _disputeIds;
    mapping(uint256 => CommunityDispute) public communityDisputes;

    // --- Events ---
    event OracleAddressUpdated(address indexed newOracleAddress);
    event SkillAttestedInternal(address indexed attestor, address indexed attestedTo, uint256 sbtTokenId);
    event AttestationRevokedInternal(uint256 indexed sbtTokenId);
    event AttestationChallengedInternal(uint256 indexed sbtTokenId, address indexed challenger);
    event AttestationChallengeResolvedInternal(uint256 indexed sbtTokenId, bool isValid, address indexed resolver);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event InitiativeCreated(uint256 indexed initiativeId, address indexed creator, uint256 fundingGoal);
    event InitiativeFunded(uint256 indexed initiativeId, address indexed funder, uint256 amount);
    event InitiativeWithdrawn(uint256 indexed initiativeId, address indexed funder, uint256 amount);
    event MilestoneProposed(uint256 indexed initiativeId, uint256 milestoneNumber, address indexed proposer);
    event MilestoneVerified(uint256 indexed initiativeId, uint256 milestoneNumber, address indexed verifier);
    event MilestoneChallenged(uint256 indexed initiativeId, uint256 milestoneNumber, address indexed challenger);
    event MilestoneChallengeResolved(uint256 indexed initiativeId, uint256 milestoneNumber, bool isValid, address indexed resolver);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event RewardsDistributed(address indexed recipient, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event CommunityDisputeInitiated(uint256 indexed disputeId, address indexed initiator, string details);
    event CommunityDisputeResolved(uint256 indexed disputeId, bool outcome, address indexed resolver);


    // --- Constructor ---
    /// @notice Deploys the DAIRIN contract, linking it to an existing ERC20 Impact Token and an Oracle.
    /// @param _impactTokenAddress The address of the ERC20 token used for staking and rewards.
    /// @param _oracleAddress The initial address of the trusted oracle.
    constructor(address _impactTokenAddress, address _oracleAddress)
        Ownable(msg.sender)
        Pausable()
    {
        require(_impactTokenAddress != address(0), "DAIRIN: Invalid impact token address");
        require(_oracleAddress != address(0), "DAIRIN: Invalid oracle address");

        impactToken = ERC20(_impactTokenAddress);
        skillSBT = new SkillAttestationSBT("DAIRIN Skill Attestations", "DAIRIN-SBT");
        oracleAddress = _oracleAddress;
    }

    // --- Modifiers ---
    /// @dev Restricts access to the designated oracle address.
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "DAIRIN: Only oracle can call this function");
        _;
    }

    /// @dev Restricts access to the creator of a specific initiative.
    /// @param _initiativeId The ID of the initiative.
    modifier onlyInitiativeCreator(uint256 _initiativeId) {
        require(impactInitiatives[_initiativeId].creator == msg.sender, "DAIRIN: Only initiative creator can call this");
        _;
    }

    /// @dev Restricts access to the original attestor of an SBT or the contract owner.
    /// @param _sbtTokenId The ID of the SBT.
    modifier onlyAttestor(uint256 _sbtTokenId) {
        require(skillSBT.attestors(_sbtTokenId) == msg.sender || owner() == msg.sender, "DAIRIN: Not authorized to revoke");
        _;
    }

    // --- Internal Reputation Calculation Helper ---
    /// @notice Calculates the raw reputation score for a user based on active SBTs.
    /// @dev This function can be extended to include other factors like successful initiative participation.
    /// @param _user The address for which to calculate reputation.
    /// @return The raw reputation score.
    function _calculateRawReputation(address _user) internal view returns (uint256) {
        // Each active SBT contributes 10 base points to reputation (example weight)
        uint256 activeSBTs = 0;
        // Iterating all tokens for a user for a view function can be gas-intensive if many tokens exist.
        // A more scalable solution might involve a separate counter for active SBTs per user
        // updated during mint/revoke/challenge resolution in the SkillAttestationSBT contract.
        // For simplicity, we assume an efficient way to get active SBT count.
        // For this example, we'll just use the overall balance, assuming only active ones count.
        // In a real system, the SBT contract would need a public function to count active ones for a user.
        // For this example, let's assume `balanceOf` only counts active, or that we'd have a helper.
        // The current `balanceOf` counts all _existing_ tokens.
        // A more robust implementation would require iterating through a list of a user's tokens
        // and checking their individual `attestationStatus`. For now, we simplify:
        // We'll give a fixed reputation per 'minted' SBT (regardless of current status for simplicity here,
        // but a real system should filter by `AttestationStatus.Active`).
        activeSBTs = skillSBT.balanceOf(_user); // Simplified: assumes balanceOf reflects active or that system tolerates it.
        // A more correct approach would be to have an internal counter in SkillAttestationSBT that increments on active mint
        // and decrements on revocation/invalidation, which DAIRIN could query.
        uint256 sbtReputation = activeSBTs * 10;

        // Future enhancements: Add reputation from active stakes, successful initiatives, etc.
        return sbtReputation;
    }

    /// @notice Updates a user's reputation score, applying decay and recalculating base reputation.
    /// @dev Should be called whenever a user's reputation-affecting action occurs or before a score is retrieved.
    /// @param _user The address of the user whose reputation needs updating.
    function _updateReputation(address _user) internal {
        uint256 currentTimestamp = block.timestamp;
        uint256 lastUpdate = _lastReputationUpdateTime[_user];
        uint256 currentScore = _reputationScores[_user];

        if (lastUpdate > 0 && currentTimestamp > lastUpdate) {
            uint256 elapsedDays = (currentTimestamp - lastUpdate) / 1 days;
            uint256 decayAmount = elapsedDays * REPUTATION_DECAY_RATE;
            if (currentScore > decayAmount) {
                currentScore -= decayAmount;
            } else {
                currentScore = 0;
            }
        }

        uint256 rawRep = _calculateRawReputation(_user);
        // The new score is a combination of decayed existing score and newly calculated raw reputation.
        // For simplicity, this example will just overwrite with rawRep and let the decay apply next.
        // A more complex system might add rawRep to decayed score, or average it.
        _reputationScores[_user] = rawRep; // For now, just reset to raw for simplicity, or add to existing.
        _lastReputationUpdateTime[_user] = currentTimestamp;
        emit ReputationScoreUpdated(_user, _reputationScores[_user]);
    }

    // --- Admin & Configuration Functions ---

    /// @notice Updates the address of the trusted oracle.
    /// @dev Only the contract owner can call this.
    /// @param _newOracleAddress The new address for the oracle.
    function updateOracleAddress(address _newOracleAddress) public onlyOwner whenNotPaused {
        require(_newOracleAddress != address(0), "DAIRIN: Invalid oracle address");
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    /// @notice Pauses contract operations.
    /// @dev Only the contract owner can call this. Inherits from OpenZeppelin Pausable.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Only the contract owner can call this. Inherits from OpenZeppelin Pausable.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Reputation & SBT Management Functions ---

    /// @notice Mints a non-transferable Skill Attestation SBT to `_to`.
    /// @dev Requires active engagement or owner status to attest.
    /// @param _to The address to attest the skill for.
    /// @param _skillURI A URI (e.g., IPFS link) pointing to the skill's metadata.
    function attestSkill(address _to, string memory _skillURI) public whenNotPaused {
        // Example: require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_ATTESTATION, "DAIRIN: Insufficient reputation to attest");
        uint256 sbtTokenId = skillSBT.mint(_to, _skillURI);
        _updateReputation(_to); // Update reputation of the attested user
        emit SkillAttestedInternal(msg.sender, _to, sbtTokenId);
    }

    /// @notice Revokes a previously issued skill attestation.
    /// @dev Can only be called by the original attestor or the contract owner.
    /// @param _sbtTokenId The ID of the SBT to revoke.
    function revokeAttestation(uint256 _sbtTokenId) public onlyAttestor(_sbtTokenId) whenNotPaused {
        require(skillSBT.attestationStatus(_sbtTokenId) == SkillAttestationSBT.AttestationStatus.Active, "DAIRIN: Attestation not active");
        
        skillSBT._revoke(_sbtTokenId);
        _updateReputation(skillSBT.attestedAddresses(_sbtTokenId)); // Update reputation of the attested user
        emit AttestationRevokedInternal(_sbtTokenId);
    }

    /// @notice Allows a user to formally dispute the validity of an existing skill attestation.
    /// @dev Requires a certain reputation to challenge, and potentially a stake (not implemented for brevity).
    /// @param _sbtTokenId The ID of the SBT to challenge.
    function challengeAttestation(uint256 _sbtTokenId) public payable whenNotPaused {
        require(skillSBT.attestationStatus(_sbtTokenId) == SkillAttestationSBT.AttestationStatus.Active, "DAIRIN: Attestation not active");
        // Example: require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_CHALLENGE, "DAIRIN: Insufficient reputation to challenge");
        // Could require a stake here: require(msg.value >= CHALLENGE_STAKE, "DAIRIN: Insufficient challenge stake");
        skillSBT._markUnderChallenge(_sbtTokenId, msg.sender);
        emit AttestationChallengedInternal(_sbtTokenId, msg.sender);
    }

    /// @notice Resolves a challenged attestation, either validating it or marking it as invalid.
    /// @dev Only callable by the oracle.
    /// @param _sbtTokenId The ID of the SBT being challenged.
    /// @param _isValid True if the attestation is deemed valid, false otherwise.
    function resolveAttestationChallenge(uint256 _sbtTokenId, bool _isValid) public onlyOracle whenNotPaused {
        require(skillSBT.attestationStatus(_sbtTokenId) == SkillAttestationSBT.AttestationStatus.UnderChallenge, "DAIRIN: Attestation not under challenge");
        skillSBT._resolveChallenge(_sbtTokenId, _isValid, msg.sender);
        address attestedUser = skillSBT.attestedAddresses(_sbtTokenId);
        if (!_isValid) {
            // Penalize the attested user's reputation if the attestation was found invalid
            _reputationScores[attestedUser] = _reputationScores[attestedUser] > 10 ? _reputationScores[attestedUser] - 10 : 0;
            _lastReputationUpdateTime[attestedUser] = block.timestamp;
            emit ReputationScoreUpdated(attestedUser, _reputationScores[attestedUser]);
        }
        _updateReputation(attestedUser); // Recalculate reputation after resolution
        emit AttestationChallengeResolvedInternal(_sbtTokenId, _isValid, msg.sender);
        // Implement logic for refunding stakes, penalizing, etc.
    }

    /// @notice Returns the current dynamic reputation score of a given user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        // For a view function, we calculate the potential decay up to the current moment
        uint256 currentScore = _reputationScores[_user];
        uint256 lastUpdate = _lastReputationUpdateTime[_user];
        
        if (lastUpdate > 0 && block.timestamp > lastUpdate) {
            uint256 elapsedDays = (block.timestamp - lastUpdate) / 1 days;
            uint256 decayAmount = elapsedDays * REPUTATION_DECAY_RATE;
            if (currentScore > decayAmount) {
                currentScore -= decayAmount;
            } else {
                currentScore = 0;
            }
        }
        return currentScore;
    }

    /// @notice Freezes the reputation score of a user, typically for malicious actors.
    /// @dev Sets the user's reputation to 0 and prevents further updates. Only owner can call.
    /// @param _user The address of the user whose reputation is to be frozen.
    function freezeReputation(address _user) public onlyOwner whenNotPaused {
        _reputationScores[_user] = 0;
        _lastReputationUpdateTime[_user] = block.timestamp; // Prevent further decay/updates
        emit ReputationScoreUpdated(_user, 0);
    }

    // --- Impact Initiative Management Functions ---

    /// @notice Proposes a new impact initiative.
    /// @param _name The name of the initiative.
    /// @param _description A URI or text description of the initiative.
    /// @param _fundingGoal The total amount of Impact Tokens needed.
    /// @param _numMilestones The total number of milestones for the initiative.
    function createImpactInitiative(string memory _name, string memory _description, uint256 _fundingGoal, uint256 _numMilestones) public whenNotPaused {
        _initiativeIds.increment();
        uint256 newId = _initiativeIds.current();
        ImpactInitiative storage initiative = impactInitiatives[newId];
        initiative.initiativeId = newId;
        initiative.creator = msg.sender;
        initiative.name = _name;
        initiative.description = _description;
        initiative.fundingGoal = _fundingGoal;
        initiative.proposalTime = block.timestamp;
        initiative.status = InitiativeStatus.Proposed;
        initiative.numMilestones = _numMilestones;
        emit InitiativeCreated(newId, msg.sender, _fundingGoal);
    }

    /// @notice Stakes `_amount` of Impact Tokens towards an initiative.
    /// @param _initiativeId The ID of the initiative to fund.
    /// @param _amount The amount of tokens to stake.
    function fundImpactInitiative(uint256 _initiativeId, uint256 _amount) public whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.status == InitiativeStatus.Proposed || initiative.status == InitiativeStatus.Funding, "DAIRIN: Initiative not open for funding");
        require(_amount > 0, "DAIRIN: Amount must be greater than 0");
        require(initiative.currentFunding + _amount <= initiative.fundingGoal, "DAIRIN: Funding exceeds goal");
        require(impactToken.transferFrom(msg.sender, address(this), _amount), "DAIRIN: Token transfer failed");

        initiative.currentFunding += _amount;
        initiative.stakedAmounts[msg.sender] += _amount;

        if (initiative.currentFunding >= initiative.fundingGoal && initiative.status == InitiativeStatus.Proposed) {
            initiative.status = InitiativeStatus.Active; // Move directly to Active if fully funded
        }
        emit InitiativeFunded(_initiativeId, msg.sender, _amount);
    }

    /// @notice Allows a funder to withdraw their staked tokens from an initiative.
    /// @dev Can only withdraw if the initiative is still in Proposed/Funding phase or has Failed.
    /// @param _initiativeId The ID of the initiative.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawInitiativeFunds(uint256 _initiativeId, uint256 _amount) public whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.stakedAmounts[msg.sender] >= _amount, "DAIRIN: Insufficient staked amount");
        require(_amount > 0, "DAIRIN: Amount must be greater than 0");
        require(initiative.status == InitiativeStatus.Proposed || initiative.status == InitiativeStatus.Funding || initiative.status == InitiativeStatus.Failed, "DAIRIN: Cannot withdraw from active/completed initiative");

        initiative.stakedAmounts[msg.sender] -= _amount;
        initiative.currentFunding -= _amount;
        require(impactToken.transfer(msg.sender, _amount), "DAIRIN: Token transfer failed");
        emit InitiativeWithdrawn(_initiativeId, msg.sender, _amount);
    }

    /// @notice Declares that a specific milestone for an initiative has been achieved.
    /// @param _initiativeId The ID of the initiative.
    /// @param _milestoneNumber The number of the milestone achieved (1-indexed).
    function proposeMilestoneAchieved(uint256 _initiativeId, uint256 _milestoneNumber) public onlyInitiativeCreator(_initiativeId) whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.status == InitiativeStatus.Active, "DAIRIN: Initiative not active");
        require(_milestoneNumber > initiative.completedMilestones && _milestoneNumber <= initiative.numMilestones, "DAIRIN: Invalid milestone number");

        initiative.status = InitiativeStatus.MilestoneUnderReview;
        initiative.lastMilestoneTime = block.timestamp; // Start review/challenge period
        emit MilestoneProposed(_initiativeId, _milestoneNumber, msg.sender);
    }

    /// @notice Confirms the achievement of a milestone, potentially releasing a portion of funds.
    /// @dev Only callable by the oracle. After verification, funds can be released to the creator.
    /// @param _initiativeId The ID of the initiative.
    /// @param _milestoneNumber The number of the verified milestone.
    function verifyMilestoneAchieved(uint256 _initiativeId, uint256 _milestoneNumber) public onlyOracle whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.status == InitiativeStatus.MilestoneUnderReview, "DAIRIN: Milestone not under review");
        require(initiative.completedMilestones + 1 == _milestoneNumber, "DAIRIN: Incorrect milestone sequence");

        initiative.completedMilestones = _milestoneNumber;
        initiative.status = InitiativeStatus.Active; // Revert to active or set to completed

        // Release funds (e.g., fundingGoal / numMilestones) to initiative.creator
        uint256 fundsToRelease = initiative.fundingGoal / initiative.numMilestones;
        require(impactToken.transfer(initiative.creator, fundsToRelease), "DAIRIN: Failed to release milestone funds");

        if (initiative.completedMilestones == initiative.numMilestones) {
            initiative.status = InitiativeStatus.Completed;
            // Optionally, distribute remaining funds to funders if overfunded, or mark for governance decision
        }
        _updateReputation(initiative.creator); // Creator gets reputation boost
        emit MilestoneVerified(_initiativeId, _milestoneNumber, msg.sender);
    }

    /// @notice Allows a user to dispute the claim that a milestone has been achieved.
    /// @dev Requires a stake (not implemented for brevity). Moves initiative to 'Challenged' state.
    /// @param _initiativeId The ID of the initiative.
    /// @param _milestoneNumber The number of the disputed milestone.
    function challengeMilestone(uint256 _initiativeId, uint256 _milestoneNumber) public payable whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.status == InitiativeStatus.MilestoneUnderReview, "DAIRIN: Milestone not under review");
        require(block.timestamp <= initiative.lastMilestoneTime + CHALLENGE_PERIOD, "DAIRIN: Challenge period expired");
        // Could require a stake here: require(msg.value >= CHALLENGE_STAKE, "DAIRIN: Insufficient challenge stake");
        initiative.status = InitiativeStatus.Challenged;
        emit MilestoneChallenged(_initiativeId, _milestoneNumber, msg.sender);
    }

    /// @notice Resolves a challenged milestone.
    /// @dev Only callable by the oracle. If invalid, creator may be penalized, if valid, challenger stake refunded.
    /// @param _initiativeId The ID of the initiative.
    /// @param _milestoneNumber The number of the disputed milestone.
    /// @param _isValid True if the milestone claim is upheld, false if invalid.
    function resolveMilestoneChallenge(uint256 _initiativeId, uint256 _milestoneNumber, bool _isValid) public onlyOracle whenNotPaused {
        ImpactInitiative storage initiative = impactInitiatives[_initiativeId];
        require(initiative.status == InitiativeStatus.Challenged, "DAIRIN: Initiative not under challenge");

        if (_isValid) {
            // Milestone upheld, proceed with verification
            initiative.status = InitiativeStatus.MilestoneUnderReview; // Revert to review state to allow verification
            verifyMilestoneAchieved(_initiativeId, _milestoneNumber); // Automatically verify if challenge failed
            // Reward challenger (e.g., refund stake)
        } else {
            // Milestone deemed invalid
            initiative.status = InitiativeStatus.Failed;
            // Penalize creator (e.g., reputation loss)
            _reputationScores[initiative.creator] = _reputationScores[initiative.creator] > 20 ? _reputationScores[initiative.creator] - 20 : 0; // Example penalty
            _lastReputationUpdateTime[initiative.creator] = block.timestamp;
            emit ReputationScoreUpdated(initiative.creator, _reputationScores[initiative.creator]);
            // Logic to refund funders, etc., not implemented for brevity.
        }
        emit MilestoneChallengeResolved(_initiativeId, _milestoneNumber, _isValid, msg.sender);
    }

    /// @notice Returns the current status of an impact initiative.
    /// @param _initiativeId The ID of the initiative.
    /// @return The current InitiativeStatus.
    function getInitiativeStatus(uint256 _initiativeId) public view returns (InitiativeStatus) {
        return impactInitiatives[_initiativeId].status;
    }

    /// @notice Returns the amount of tokens an _user has staked in a specific initiative.
    /// @param _initiativeId The ID of the initiative.
    /// @param _user The address of the user.
    /// @return The staked amount.
    function getUserStakedAmount(uint256 _initiativeId, address _user) public view returns (uint256) {
        return impactInitiatives[_initiativeId].stakedAmounts[_user];
    }

    // --- Dynamic Governance Functions ---

    /// @notice Allows users with sufficient reputation to propose a network-level change or upgrade.
    /// @param _description A detailed description or link to the proposal (e.g., IPFS).
    /// @param _targetContract The contract address the proposal will interact with (for execution).
    /// @param _callData The encoded function call data for the proposal (for execution).
    function proposeNetworkUpgrade(string memory _description, address _targetContract, bytes memory _callData) public whenNotPaused {
        require(getReputationScore(msg.sender) >= MIN_REPUTATION_FOR_PROPOSAL, "DAIRIN: Insufficient reputation to propose");

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();
        Proposal storage proposal = proposals[newId];
        proposal.proposalId = newId;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.targetContract = _targetContract;
        proposal.callData = _callData;
        proposal.creationTime = block.timestamp;
        proposal.endTime = block.timestamp + PROPOSAL_VOTING_PERIOD;
        proposal.active = true;
        emit ProposalCreated(newId, msg.sender, _description);
    }

    /// @notice Calculates and returns the effective voting weight of a user.
    /// @dev Considers user's reputation and potential delegation. This is the dynamic aspect.
    /// @param _user The address of the user.
    /// @return The effective voting weight.
    function getVotingWeight(address _user) public view returns (uint256) {
        address actualVoter = delegates[_user] != address(0) ? delegates[_user] : _user;
        uint256 weight = getReputationScore(actualVoter); // Base on dynamic reputation
        // Future enhancement: Add active stakes to voting weight calculation, e.g.,
        // for each initiative where actualVoter has staked: weight += initiative.stakedAmounts[actualVoter] / 100;
        return weight;
    }

    /// @notice Casts a vote (for or against) on a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'for' vote, false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "DAIRIN: Proposal not active");
        require(block.timestamp <= proposal.endTime, "DAIRIN: Voting period has ended");

        address voter = delegates[msg.sender] != address(0) ? delegates[msg.sender] : msg.sender;
        require(!proposal.hasVoted[voter], "DAIRIN: Already voted on this proposal");

        uint256 weight = getVotingWeight(voter);
        require(weight > 0, "DAIRIN: Voter has no voting weight");

        if (_support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        proposal.hasVoted[voter] = true;
        _updateReputation(voter); // Active participation boosts reputation (updates last activity)
        emit VoteCast(_proposalId, voter, _support, weight);
    }

    /// @notice Executes a successful governance proposal.
    /// @dev Can only be called after the voting period ends and if the proposal passes quorum/majority.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.active, "DAIRIN: Proposal not active");
        require(!proposal.executed, "DAIRIN: Proposal already executed");
        require(block.timestamp > proposal.endTime, "DAIRIN: Voting period not ended");

        // Simple majority threshold. Can be expanded with quorum requirements.
        require(proposal.votesFor > proposal.votesAgainst, "DAIRIN: Proposal did not pass");

        proposal.executed = true;
        proposal.active = false;

        // Execute the proposal's callData on the target contract
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "DAIRIN: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Delegates one's voting power (reputation) to another address.
    /// @param _delegatee The address to delegate reputation to.
    function delegateReputation(address _delegatee) public whenNotPaused {
        require(_delegatee != msg.sender, "DAIRIN: Cannot delegate to self");
        delegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes any existing reputation delegation.
    function undelegateReputation() public whenNotPaused {
        require(delegates[msg.sender] != address(0), "DAIRIN: No active delegation to undelegate");
        delete delegates[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    // --- Treasury & Reward Functions ---

    /// @notice Allows any user to deposit Impact Tokens into the contract's treasury.
    /// @param _amount The amount of Impact Tokens to deposit.
    function depositIntoTreasury(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "DAIRIN: Deposit amount must be greater than 0");
        require(impactToken.transferFrom(msg.sender, address(this), _amount), "DAIRIN: Token transfer failed");
        emit FundsDeposited(msg.sender, _amount);
    }

    /// @notice Distributes Impact Tokens from the treasury as rewards.
    /// @dev Can only be called by the owner or via a successful governance proposal.
    /// @param _recipient The address to send the rewards to.
    /// @param _amount The amount of rewards to distribute.
    function distributeRewards(address _recipient, uint256 _amount) public onlyOwner whenNotPaused {
        require(_amount > 0, "DAIRIN: Reward amount must be greater than 0");
        require(impactToken.balanceOf(address(this)) >= _amount, "DAIRIN: Insufficient treasury balance");
        require(impactToken.transfer(_recipient, _amount), "DAIRIN: Reward distribution failed");
        emit RewardsDistributed(_recipient, _amount);
    }

    /// @notice Returns the current balance of Impact Tokens held by the contract.
    /// @return The treasury balance.
    function getTreasuryBalance() public view returns (uint256) {
        return impactToken.balanceOf(address(this));
    }

    // --- Community Dispute Mechanism ---

    /// @notice Initiates a general community dispute against a user.
    /// @dev Requires a stake (not implemented for brevity) to prevent spam.
    /// @param _targetUser The user against whom the dispute is raised.
    /// @param _details A URI or text description for the dispute.
    function initiateCommunityDispute(address _targetUser, string memory _details) public payable whenNotPaused {
        require(_targetUser != address(0), "DAIRIN: Invalid target user");
        require(_targetUser != msg.sender, "DAIRIN: Cannot dispute self");
        // Could require a stake here: require(msg.value >= DISPUTE_STAKE, "DAIRIN: Insufficient dispute stake");

        _disputeIds.increment();
        uint256 newId = _disputeIds.current();
        CommunityDispute storage dispute = communityDisputes[newId];
        dispute.disputeId = newId;
        dispute.initiator = msg.sender;
        dispute.targetUser = _targetUser;
        dispute.details = _details;
        dispute.creationTime = block.timestamp;
        dispute.resolved = false;
        emit CommunityDisputeInitiated(newId, msg.sender, _details);
    }

    /// @notice Resolves a community dispute.
    /// @dev Only callable by the oracle. Affects target user's reputation based on outcome.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _outcome True if the target user is found 'guilty' (e.g., their action was malicious/invalid), false otherwise.
    function resolveCommunityDispute(uint256 _disputeId, bool _outcome) public onlyOracle whenNotPaused {
        CommunityDispute storage dispute = communityDisputes[_disputeId];
        require(!dispute.resolved, "DAIRIN: Dispute already resolved");

        dispute.resolved = true;
        dispute.outcome = _outcome;

        if (_outcome) {
            // Target user found 'guilty', penalize reputation
            _reputationScores[dispute.targetUser] = _reputationScores[dispute.targetUser] > 50 ? _reputationScores[dispute.targetUser] - 50 : 0; // Example penalty
            _lastReputationUpdateTime[dispute.targetUser] = block.timestamp;
            emit ReputationScoreUpdated(dispute.targetUser, _reputationScores[dispute.targetUser]);
            // Could also reward initiator if _outcome is true (from dispute stake)
        } else {
            // Target user found 'innocent', potentially penalize initiator if dispute was frivolous
            // Or refund initiator's stake
        }
        emit CommunityDisputeResolved(_disputeId, _outcome, msg.sender);
    }
}
```