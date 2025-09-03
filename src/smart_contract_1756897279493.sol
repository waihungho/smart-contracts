Here's a Solidity smart contract for **CognitoNexus**, a Decentralized Skill & Contribution Graph with AI-Enhanced Attestations.

This contract introduces several advanced, creative, and trendy concepts:

1.  **Dynamic Soulbound NFTs (Skill Badges):** NFTs representing skills that are permanently tied to a user's address (non-transferable) and can evolve over time (upgrade/degrade) based on reputation, new attestations, or challenges. This goes beyond static SBTs.
2.  **AI-Augmented Attestation:** Integrates a conceptual "AI Oracle" that can provide an objective (or semi-objective) score for skill proposals. This score influences the weight of attestations and the initial tier of minted Skill Badges, adding a layer of sophisticated validation beyond purely human judgment.
3.  **Weighted Reputation System:** Attestors' reputations and stakes influence the weight of their attestations, making validations from more established members more impactful. Participants also gain/lose reputation based on successful proposals, attestations, and challenge outcomes.
4.  **Multi-Stakeholder Dispute Resolution:** A structured challenge system allows any participant to dispute an attestation. Other active attestors then vote on the validity, with clear rewards for accurate challenges and penalties for false ones or poor attestations.
5.  **Modular & Extensible Identity:** Users register with off-chain profile URIs, allowing for rich, evolving identity representation.
6.  **Pausable & Ownable:** Standard security features.

---

## CognitoNexus: Decentralized Skill & Contribution Graph

### Outline:

This contract establishes a decentralized system for validating and recognizing individual skills and contributions through a multi-stakeholder attestation process, augmented by a conceptual AI oracle and dynamic Soulbound NFTs.

1.  **Core Infrastructure & Identity:** Handles participant registration, profile management, and the lifecycle of becoming/resigning as an attestor, including staking.
2.  **Skill & Contribution Proposals:** Allows participants to propose specific skills or contributions they have made, providing off-chain details.
3.  **Attestation & Validation:** Enables active attestors to review and validate proposed skills. Attestations are weighted by the attestor's reputation and stake.
4.  **Dynamic Soulbound Skill Badges:** Manages the creation, upgrading, and degradation of non-transferable NFTs that serve as verifiable skill certificates. These badges reflect the evolving status of the associated skill.
5.  **Reputation & AI-Enhanced Scoring:** Tracks reputation scores for participants and attestors. Integrates a conceptual AI Oracle for objective assessments of proposals, influencing attestation weight and badge tiers.
6.  **Dispute Resolution:** Provides a mechanism for challenging questionable attestations, with a voting process by other attestors to resolve disputes and apply appropriate rewards/penalties.
7.  **Governance & Administrative:** Includes functions for contract ownership, pausing, and setting key parameters.

### Function Summary:

**I. Core Infrastructure & Identity (Participants & Attestors)**

*   `registerParticipant(string _profileURI)`: Registers a new participant and links an off-chain profile.
*   `updateProfileURI(string _newProfileURI)`: Updates a participant's profile URI.
*   `getParticipantProfile(address _participant)`: Retrieves a participant's profile details.
*   `applyForAttestor(uint256 _stakeAmount)`: Allows a participant to apply as an attestor by staking tokens.
*   `withdrawAttestorStake()`: Allows an attestor to withdraw their stake and resign (after a cooldown).
*   `isAttestor(address _account)`: Checks if an address is an active attestor.
*   `getAttestorDetails(address _attestor)`: Retrieves an attestor's specific details.

**II. Skill & Contribution Proposals**

*   `proposeSkillContribution(string _title, string _descriptionURI, string[] _tags)`: Allows a participant to propose a new skill or contribution for validation.
*   `getProposalDetails(uint256 _proposalId)`: Retrieves details for a specific skill proposal.
*   `getParticipantProposals(address _participant)`: Lists all proposals submitted by a participant.

**III. Attestation & Validation**

*   `submitAttestation(uint256 _proposalId, string _attestationURI)`: Allows an active attestor to attest to a skill proposal.
*   `revokeAttestation(uint256 _attestationId)`: Allows an attestor to revoke their own attestation.
*   `getAttestationsForProposal(uint256 _proposalId)`: Lists all attestations made for a specific proposal.
*   `getAttestorAttestations(address _attestor)`: Lists all attestations made by a specific attestor.

**IV. Dynamic Soulbound Skill Badges (ERC-721-like)**

*   `mintSkillBadge(uint256 _proposalId)`: Mints a new soulbound NFT (Skill Badge) for a sufficiently validated proposal.
*   `upgradeSkillBadge(uint256 _badgeId)`: Upgrades the tier of an existing Skill Badge.
*   `degradeSkillBadge(uint256 _badgeId)`: Degrades the tier of an existing Skill Badge (e.g., after a successful challenge).
*   `getSkillBadgeDetails(uint256 _badgeId)`: Retrieves details for a specific Skill Badge.
*   `getParticipantSkillBadges(address _participant)`: Lists all Skill Badges owned by a participant.

**V. Reputation & AI-Enhanced Scoring (Conceptual Oracle)**

*   `getReputation(address _account)`: Retrieves the current reputation score of an account.
*   `submitAIOracleReport(uint256 _proposalId, uint256 _aiScore, string _reportURI)`: (Admin/Trusted Oracle only) Submits an AI-generated assessment for a proposal.
*   `getAIOracleScore(uint256 _proposalId)`: Retrieves the AI score for a proposal.

**VI. Dispute Resolution**

*   `challengeAttestation(uint256 _attestationId, string _reasonURI)`: Allows any participant to challenge an existing attestation.
*   `voteOnChallenge(uint256 _challengeId, bool _supportsAttestation)`: Allows active attestors to vote on a challenged attestation.
*   `resolveChallenge(uint256 _challengeId)`: Finalizes a challenge, applying rewards/penalties based on the outcome.

**VII. Governance & Administrative**

*   `setAttestorStakeRequirement(uint256 _newAmount)`: Sets the minimum stake required to become an attestor.
*   `setAIOracleAddress(address _newOracle)`: Sets the address of the trusted AI Oracle contract/entity.
*   `setChallengePeriod(uint256 _newPeriod)`: Sets the duration for challenge voting.
*   `setCooldownPeriod(uint256 _newPeriod)`: Sets the cooldown period for attestor stake withdrawal.
*   `pauseSystem()`: Pauses core functionality of the contract.
*   `unpauseSystem()`: Unpauses core functionality.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom error definitions for better debugging
error CognitoNexus__NotParticipant();
error CognitoNexus__AlreadyParticipant();
error CognitoNexus__NotAttestor();
error CognitoNexus__AlreadyAttestor();
error CognitoNexus__InsufficientStake();
error CognitoNexus__StakeWithdrawalCooldownActive();
error CognitoNexus__ProposalNotFound();
error CognitoNexus__NotProposer();
error CognitoNexus__AIReportNotSubmitted();
error CognitoNexus__AttestationNotFound();
error CognitoNexus__AlreadyAttested();
error CognitoNexus__CannotAttestOwnProposal();
error CognitoNexus__InsufficientAttestations();
error CognitoNexus__BadgeAlreadyMinted();
error CognitoNexus__BadgeNotFound();
error CognitoNexus__NotBadgeOwner();
error CognitoNexus__CannotTransferSoulboundBadge();
error CognitoNexus__ChallengeNotFound();
error CognitoNexus__ChallengeNotActive();
error CognitoNexus__AlreadyVotedOnChallenge();
error CognitoNexus__ChallengeAlreadyResolved();
error CognitoNexus__InvalidChallengeState();
error CognitoNexus__VotingPeriodNotEnded();
error CognitoNexus__CannotCallAsAIOracle();
error CognitoNexus__ChallengeRewardTooLow();
error CognitoNexus__InvalidAIOracleAddress();


/**
 * @title CognitoNexus: Decentralized Skill & Contribution Graph
 * @dev This contract facilitates a decentralized system for validating and recognizing individual
 *      skills and contributions through a multi-stakeholder attestation process, augmented by a
 *      conceptual AI oracle and dynamic Soulbound NFTs.
 */
contract CognitoNexus is Ownable, Pausable, ERC721 {
    using Strings for uint256;

    // --- State Variables ---

    IERC20 public immutable stakingToken; // ERC-20 token used for attestor staking
    address public aiOracleAddress;      // Trusted address for AI oracle reports

    uint256 public attestorStakeRequirement; // Minimum tokens required to be an attestor
    uint256 public challengePeriod;          // Duration for challenge voting in seconds
    uint256 public attestorWithdrawalCooldown; // Cooldown period for attestor stake withdrawal in seconds

    // Reputation impact parameters
    uint256 public constant BASE_REPUTATION_GAIN_PROPOSAL = 10;
    uint256 public constant BASE_REPUTATION_GAIN_ATTEST = 5;
    uint256 public constant BASE_REPUTATION_GAIN_CHALLENGE_WIN = 20;
    uint256 public constant BASE_REPUTATION_LOSS_CHALLENGE_LOSE = 15;
    uint256 public constant BASE_REPUTATION_LOSS_FALSE_ATTEST = 10;
    uint256 public constant INITIAL_REPUTATION = 100;

    // Badge Tiers
    enum BadgeTier { NONE, BRONZE, SILVER, GOLD }
    uint256 public constant BRONZE_TIER_MIN_ATTESTATIONS = 2; // With sufficient weight
    uint256 public constant SILVER_TIER_MIN_ATTESTATIONS = 5;
    uint256 public constant GOLD_TIER_MIN_ATTESTATIONS = 10;
    uint256 public constant UPGRADE_REPUTATION_THRESHOLD = 50; // Reputation gain needed for upgrade

    // Counters for unique IDs
    uint256 private _nextTokenId;
    uint256 private _nextProposalId;
    uint256 private _nextAttestationId;
    uint256 private _nextChallengeId;

    // --- Data Structures ---

    struct Participant {
        address participantAddress;
        string profileURI;
        uint256 reputation;
        bool registered;
    }

    struct Attestor {
        uint256 stakeAmount;
        uint256 stakeTimestamp; // Timestamp of latest stake or last activity (for cooldown)
        bool isActive;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string title;
        string descriptionURI;
        string[] tags;
        uint256 submissionTime;
        uint256 aiScore; // AI's assessment score (0-100)
        string aiReportURI;
        bool aiScoreSubmitted;
        uint256 totalAttestationWeight; // Sum of reputation * stake from valid attestors
        bool hasMintedBadge;
        mapping(address => uint256) attestationsByAttestor; // attestor => attestationId
        address[] attestorsWhoAttested; // List of attestors for easier iteration
        uint256 badgeId; // Link to minted badge if any
    }

    struct Attestation {
        uint256 attestationId;
        uint256 proposalId;
        address attestor;
        string attestationURI;
        uint256 attestationTime;
        bool isValid; // True unless successfully challenged
        uint256 reputationAtAttestation; // Attestor's reputation at time of attestation
        uint256 attestorStakeAtAttestation; // Attestor's stake at time of attestation
        uint256 challengeId; // 0 if not challenged, otherwise challengeId
    }

    struct SkillBadge {
        uint256 badgeId;
        uint256 proposalId;
        address owner; // The participant who earned it (soulbound)
        string metadataURI; // IPFS hash or URL for NFT metadata (dynamic)
        uint256 mintTime;
        BadgeTier tier;
        uint256 lastUpgradeTime;
        uint256 totalAttestationWeightAtMint; // Snapshot of weight when minted
    }

    struct Challenge {
        uint256 challengeId;
        uint256 attestationId;
        address challenger;
        string reasonURI;
        uint256 startTime;
        uint256 endTime;
        uint256 votesForAttestation; // Attestors voting the attestation is valid
        uint256 votesAgainstAttestation; // Attestors voting the attestation is invalid
        mapping(address => bool) hasVoted; // attestor => voted
        bool resolved;
        bool attestationUpheld; // True if attestation was deemed valid after challenge
    }

    // --- Mappings ---

    mapping(address => Participant) public participants;
    mapping(address => Attestor) public attestors;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => SkillBadge) public skillBadges;
    mapping(uint256 => Challenge) public challenges;

    // Mappings for easier retrieval
    mapping(address => uint256[]) public participantProposals; // participant => list of proposalIds
    mapping(address => uint256[]) public attestorAttestations; // attestor => list of attestationIds
    mapping(address => uint256[]) public participantSkillBadges; // participant => list of badgeIds

    // --- Events ---

    event ParticipantRegistered(address indexed participant, string profileURI);
    event ProfileURIUpdated(address indexed participant, string newProfileURI);
    event AttestorApplied(address indexed attestor, uint256 stakeAmount);
    event AttestorWithdrawn(address indexed attestor, uint256 stakeAmount);
    event SkillContributionProposed(address indexed proposer, uint256 proposalId, string title, string descriptionURI);
    event AttestationSubmitted(address indexed attestor, uint256 attestationId, uint256 proposalId, uint256 attestationWeight);
    event AttestationRevoked(address indexed attestor, uint256 attestationId);
    event SkillBadgeMinted(address indexed owner, uint256 badgeId, uint256 proposalId, BadgeTier tier);
    event SkillBadgeUpgraded(uint256 badgeId, BadgeTier newTier);
    event SkillBadgeDegraded(uint256 badgeId, BadgeTier newTier);
    event AIOracleReportSubmitted(uint256 indexed proposalId, uint256 aiScore, string reportURI);
    event AttestationChallenged(address indexed challenger, uint256 challengeId, uint256 attestationId, string reasonURI);
    event ChallengeVoted(address indexed voter, uint256 challengeId, bool supportsAttestation);
    event ChallengeResolved(uint256 indexed challengeId, bool attestationUpheld, uint256 reputationGain, uint256 reputationLoss);
    event ReputationUpdated(address indexed account, uint256 newReputation);
    event AttestorStakeRequirementUpdated(uint256 newAmount);
    event AIOracleAddressUpdated(address newAddress);
    event ChallengePeriodUpdated(uint256 newPeriod);
    event AttestorWithdrawalCooldownUpdated(uint256 newPeriod);


    // --- Constructor ---

    constructor(address _stakingToken, address _aiOracleAddress, uint256 _attestorStakeRequirement)
        ERC721("CognitoNexusSkillBadge", "CNSB")
        Ownable(msg.sender)
    {
        if (_stakingToken == address(0)) revert CognitoNexus__InvalidAIOracleAddress();
        if (_aiOracleAddress == address(0)) revert CognitoNexus__InvalidAIOracleAddress();

        stakingToken = IERC20(_stakingToken);
        aiOracleAddress = _aiOracleAddress;
        attestorStakeRequirement = _attestorStakeRequirement;
        challengePeriod = 3 days; // Default challenge voting period
        attestorWithdrawalCooldown = 7 days; // Default cooldown for stake withdrawal
    }

    // --- Modifier for Soulbound Token ---
    modifier onlyBadgeOwner(uint256 _badgeId) {
        if (skillBadges[_badgeId].owner != msg.sender) revert CognitoNexus__NotBadgeOwner();
        _;
    }

    // --- ERC721 Overrides for Soulbound Tokens ---
    function _approve(address to, uint256 tokenId) internal pure override {
        revert CognitoNexus__CannotTransferSoulboundBadge();
    }
    function _setApprovalForAll(address owner, address operator, bool approved) internal pure override {
        revert CognitoNexus__CannotTransferSoulboundBadge();
    }
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert CognitoNexus__CannotTransferSoulboundBadge();
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert CognitoNexus__CannotTransferSoulboundBadge();
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert CognitoNexus__CannotTransferSoulboundBadge();
    }

    // --- Internal Utility Functions ---

    function _isParticipant(address _addr) internal view returns (bool) {
        return participants[_addr].registered;
    }

    function _isActiveAttestor(address _addr) internal view returns (bool) {
        return attestors[_addr].isActive;
    }

    function _updateReputation(address _account, int256 _amount) internal {
        if (_amount > 0) {
            participants[_account].reputation += uint256(_amount);
        } else {
            uint256 loss = uint256(-_amount);
            if (participants[_account].reputation < loss) {
                participants[_account].reputation = 0;
            } else {
                participants[_account].reputation -= loss;
            }
        }
        emit ReputationUpdated(_account, participants[_account].reputation);
    }

    function _mint(address to, uint256 tokenId, string memory tokenURI) internal {
        ERC721._safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function _calculateAttestationWeight(uint256 _reputation, uint256 _stake) internal pure returns (uint256) {
        // Simple weight calculation: (reputation / 100) * (stake / 1 ether)
        // Adjust denominators as needed for practical values
        if (_reputation == 0 || _stake == 0) return 0;
        return (_reputation * _stake) / (10**36); // Assuming 1e18 stake, 1e18 reputation base. Adjust if different scale.
    }

    function _getBadgeTier(uint256 _weight, uint256 _aiScore) internal pure returns (BadgeTier) {
        if (_weight == 0) return BadgeTier.NONE;
        uint256 combinedScore = _weight + (_aiScore * 1e18 / 100); // AI score (0-100) adds to weight

        if (combinedScore >= (GOLD_TIER_MIN_ATTESTATIONS * 1e18)) return BadgeTier.GOLD;
        if (combinedScore >= (SILVER_TIER_MIN_ATTESTATIONS * 1e18)) return BadgeTier.SILVER;
        if (combinedScore >= (BRONZE_TIER_MIN_ATTESTATIONS * 1e18)) return BadgeTier.BRONZE;
        return BadgeTier.NONE;
    }

    // --- I. Core Infrastructure & Identity ---

    /**
     * @dev Registers the caller as a participant in the CognitoNexus system.
     * @param _profileURI URI pointing to the participant's off-chain profile (e.g., IPFS hash).
     */
    function registerParticipant(string memory _profileURI) external whenNotPaused {
        if (_isParticipant(msg.sender)) revert CognitoNexus__AlreadyParticipant();

        participants[msg.sender] = Participant({
            participantAddress: msg.sender,
            profileURI: _profileURI,
            reputation: INITIAL_REPUTATION,
            registered: true
        });

        emit ParticipantRegistered(msg.sender, _profileURI);
    }

    /**
     * @dev Updates the off-chain profile URI for the caller.
     * @param _newProfileURI The new URI for the participant's profile.
     */
    function updateProfileURI(string memory _newProfileURI) external whenNotPaused {
        if (!_isParticipant(msg.sender)) revert CognitoNexus__NotParticipant();
        participants[msg.sender].profileURI = _newProfileURI;
        emit ProfileURIUpdated(msg.sender, _newProfileURI);
    }

    /**
     * @dev Retrieves the profile details for a given participant.
     * @param _participant The address of the participant.
     * @return profileURI The off-chain profile URI.
     * @return reputation The participant's current reputation score.
     * @return registered True if the address is a registered participant.
     */
    function getParticipantProfile(address _participant)
        external
        view
        returns (string memory profileURI, uint256 reputation, bool registered)
    {
        Participant storage p = participants[_participant];
        return (p.profileURI, p.reputation, p.registered);
    }

    /**
     * @dev Allows a registered participant to apply to become an attestor by staking tokens.
     * @param _stakeAmount The amount of staking tokens to deposit.
     */
    function applyForAttestor(uint256 _stakeAmount) external whenNotPaused {
        if (!_isParticipant(msg.sender)) revert CognitoNexus__NotParticipant();
        if (_isActiveAttestor(msg.sender)) revert CognitoNexus__AlreadyAttestor();
        if (_stakeAmount < attestorStakeRequirement) revert CognitoNexus__InsufficientStake();

        // Transfer stake tokens from sender to contract
        require(stakingToken.transferFrom(msg.sender, address(this), _stakeAmount), "Token transfer failed");

        attestors[msg.sender] = Attestor({
            stakeAmount: _stakeAmount,
            stakeTimestamp: block.timestamp,
            isActive: true
        });

        emit AttestorApplied(msg.sender, _stakeAmount);
    }

    /**
     * @dev Allows an active attestor to withdraw their stake and resign after a cooldown period.
     */
    function withdrawAttestorStake() external whenNotPaused {
        if (!_isActiveAttestor(msg.sender)) revert CognitoNexus__NotAttestor();
        
        Attestor storage attestorData = attestors[msg.sender];
        if (block.timestamp < attestorData.stakeTimestamp + attestorWithdrawalCooldown) {
            revert CognitoNexus__StakeWithdrawalCooldownActive();
        }

        attestorData.isActive = false;
        uint256 amount = attestorData.stakeAmount;
        attestorData.stakeAmount = 0; // Clear stake amount

        require(stakingToken.transfer(msg.sender, amount), "Stake withdrawal failed");
        emit AttestorWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Checks if an address is currently an active attestor.
     * @param _account The address to check.
     * @return True if the address is an active attestor, false otherwise.
     */
    function isAttestor(address _account) external view returns (bool) {
        return _isActiveAttestor(_account);
    }

    /**
     * @dev Retrieves details about an attestor.
     * @param _attestor The address of the attestor.
     * @return stakeAmount The amount of tokens staked by the attestor.
     * @return stakeTimestamp The timestamp of the attestor's last staking activity.
     * @return isActive True if the attestor is currently active.
     */
    function getAttestorDetails(address _attestor)
        external
        view
        returns (uint256 stakeAmount, uint256 stakeTimestamp, bool isActive)
    {
        Attestor storage a = attestors[_attestor];
        return (a.stakeAmount, a.stakeTimestamp, a.isActive);
    }

    // --- II. Skill & Contribution Proposals ---

    /**
     * @dev Allows a participant to propose a new skill or contribution for validation.
     * @param _title The title of the skill/contribution.
     * @param _descriptionURI URI pointing to off-chain detailed description.
     * @param _tags An array of tags describing the skill/contribution.
     * @return The ID of the newly created proposal.
     */
    function proposeSkillContribution(string memory _title, string memory _descriptionURI, string[] memory _tags)
        external
        whenNotPaused
        returns (uint256)
    {
        if (!_isParticipant(msg.sender)) revert CognitoNexus__NotParticipant();

        _nextProposalId++;
        uint256 proposalId = _nextProposalId;

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            tags: _tags,
            submissionTime: block.timestamp,
            aiScore: 0,
            aiReportURI: "",
            aiScoreSubmitted: false,
            totalAttestationWeight: 0,
            hasMintedBadge: false,
            badgeId: 0,
            attestorsWhoAttested: new address[](0) // Initialize
        });

        participantProposals[msg.sender].push(proposalId);
        _updateReputation(msg.sender, int256(BASE_REPUTATION_GAIN_PROPOSAL)); // Reward for proposing
        emit SkillContributionProposed(msg.sender, proposalId, _title, _descriptionURI);
        return proposalId;
    }

    /**
     * @dev Retrieves details for a specific skill proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer The address of the proposer.
     * @return title The title of the proposal.
     * @return descriptionURI The URI for the description.
     * @return tags The tags associated with the proposal.
     * @return submissionTime The timestamp of submission.
     * @return aiScore The AI's assessment score.
     * @return aiReportURI The URI for the AI report.
     * @return aiScoreSubmitted True if an AI report has been submitted.
     * @return totalAttestationWeight The combined weight of valid attestations.
     * @return hasMintedBadge True if a badge has been minted for this proposal.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            string memory title,
            string memory descriptionURI,
            string[] memory tags,
            uint256 submissionTime,
            uint256 aiScore,
            string memory aiReportURI,
            bool aiScoreSubmitted,
            uint256 totalAttestationWeight,
            bool hasMintedBadge
        )
    {
        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();

        return (
            p.proposer,
            p.title,
            p.descriptionURI,
            p.tags,
            p.submissionTime,
            p.aiScore,
            p.aiReportURI,
            p.aiScoreSubmitted,
            p.totalAttestationWeight,
            p.hasMintedBadge
        );
    }

    /**
     * @dev Lists all proposals submitted by a given participant.
     * @param _participant The address of the participant.
     * @return An array of proposal IDs.
     */
    function getParticipantProposals(address _participant) external view returns (uint256[] memory) {
        return participantProposals[_participant];
    }

    // --- III. Attestation & Validation ---

    /**
     * @dev Allows an active attestor to attest to a skill proposal.
     * @param _proposalId The ID of the proposal to attest to.
     * @param _attestationURI URI pointing to off-chain details of the attestation.
     * @return The ID of the newly created attestation.
     */
    function submitAttestation(uint256 _proposalId, string memory _attestationURI)
        external
        whenNotPaused
        returns (uint256)
    {
        if (!_isActiveAttestor(msg.sender)) revert CognitoNexus__NotAttestor();

        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();
        if (p.proposer == msg.sender) revert CognitoNexus__CannotAttestOwnProposal();
        if (p.attestationsByAttestor[msg.sender] != 0) revert CognitoNexus__AlreadyAttested();
        
        // Ensure AI report is submitted for weighted calculation
        if (!p.aiScoreSubmitted) revert CognitoNexus__AIReportNotSubmitted();

        _nextAttestationId++;
        uint256 attestationId = _nextAttestationId;

        uint256 reputation = participants[msg.sender].reputation;
        uint256 stake = attestors[msg.sender].stakeAmount;
        uint256 attestationWeight = _calculateAttestationWeight(reputation, stake);

        attestations[attestationId] = Attestation({
            attestationId: attestationId,
            proposalId: _proposalId,
            attestor: msg.sender,
            attestationURI: _attestationURI,
            attestationTime: block.timestamp,
            isValid: true,
            reputationAtAttestation: reputation,
            attestorStakeAtAttestation: stake,
            challengeId: 0
        });

        p.attestationsByAttestor[msg.sender] = attestationId;
        p.attestorsWhoAttested.push(msg.sender);
        p.totalAttestationWeight += (attestationWeight * (p.aiScore > 0 ? p.aiScore : 1) / 100); // AI score acts as a multiplier

        attestorAttestations[msg.sender].push(attestationId);
        _updateReputation(msg.sender, int256(BASE_REPUTATION_GAIN_ATTEST)); // Reward for attesting
        emit AttestationSubmitted(msg.sender, attestationId, _proposalId, attestationWeight);
        return attestationId;
    }

    /**
     * @dev Allows an attestor to revoke their own attestation.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId) external whenNotPaused {
        Attestation storage a = attestations[_attestationId];
        if (a.attestor == address(0)) revert CognitoNexus__AttestationNotFound();
        if (a.attestor != msg.sender) revert CognitoNexus__NotAttestor(); // Only attestor can revoke their own
        if (!a.isValid) revert CognitoNexus__InvalidChallengeState(); // Cannot revoke if already invalid

        Proposal storage p = proposals[a.proposalId];
        // Remove weight from proposal
        uint256 attestationWeight = _calculateAttestationWeight(a.reputationAtAttestation, a.attestorStakeAtAttestation);
        p.totalAttestationWeight -= (attestationWeight * (p.aiScore > 0 ? p.aiScore : 1) / 100);

        delete p.attestationsByAttestor[msg.sender];
        // Note: Removing from p.attestorsWhoAttested and attestorAttestations[msg.sender] is costly.
        // For simplicity, we mark isValid=false and ignore in calculations.
        a.isValid = false; // Mark as invalid
        
        // Apply reputation loss for revoking (implies uncertainty or error)
        _updateReputation(msg.sender, -int256(BASE_REPUTATION_LOSS_FALSE_ATTEST / 2)); 
        emit AttestationRevoked(msg.sender, _attestationId);
    }

    /**
     * @dev Lists all attestations made for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return An array of attestation IDs.
     */
    function getAttestationsForProposal(uint256 _proposalId) external view returns (uint256[] memory) {
        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();

        uint256[] memory activeAttestations = new uint256[](p.attestorsWhoAttested.length);
        uint256 count = 0;
        for (uint i = 0; i < p.attestorsWhoAttested.length; i++) {
            address attestorAddr = p.attestorsWhoAttested[i];
            uint256 attestationId = p.attestationsByAttestor[attestorAddr];
            if (attestationId != 0 && attestations[attestationId].isValid) {
                activeAttestations[count] = attestationId;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeAttestations[i];
        }
        return result;
    }

    /**
     * @dev Lists all attestations made by a specific attestor.
     * @param _attestor The address of the attestor.
     * @return An array of attestation IDs.
     */
    function getAttestorAttestations(address _attestor) external view returns (uint256[] memory) {
        return attestorAttestations[_attestor];
    }

    // --- IV. Dynamic Soulbound Skill Badges ---

    /**
     * @dev Mints a new soulbound NFT (Skill Badge) for a validated proposal.
     * Requires sufficient total attestation weight for the proposal.
     * @param _proposalId The ID of the proposal to mint a badge for.
     * @return The ID of the newly minted Skill Badge.
     */
    function mintSkillBadge(uint256 _proposalId) external whenNotPaused returns (uint256) {
        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();
        if (p.proposer != msg.sender) revert CognitoNexus__NotProposer();
        if (p.hasMintedBadge) revert CognitoNexus__BadgeAlreadyMinted();
        if (p.totalAttestationWeight < (BRONZE_TIER_MIN_ATTESTATIONS * 1e18)) revert CognitoNexus__InsufficientAttestations();
        if (!p.aiScoreSubmitted) revert CognitoNexus__AIReportNotSubmitted();

        _nextTokenId++;
        uint256 badgeId = _nextTokenId;

        BadgeTier initialTier = _getBadgeTier(p.totalAttestationWeight, p.aiScore);
        if (initialTier == BadgeTier.NONE) revert CognitoNexus__InsufficientAttestations();

        // Base metadata URI for dynamic tokens
        string memory tokenURI = string(abi.encodePacked("ipfs://", badgeId.toString(), "/metadata.json"));

        skillBadges[badgeId] = SkillBadge({
            badgeId: badgeId,
            proposalId: _proposalId,
            owner: msg.sender,
            metadataURI: tokenURI,
            mintTime: block.timestamp,
            tier: initialTier,
            lastUpgradeTime: block.timestamp,
            totalAttestationWeightAtMint: p.totalAttestationWeight
        });

        p.hasMintedBadge = true;
        p.badgeId = badgeId;
        participantSkillBadges[msg.sender].push(badgeId);

        _mint(msg.sender, badgeId, tokenURI);
        emit SkillBadgeMinted(msg.sender, badgeId, _proposalId, initialTier);
        return badgeId;
    }

    /**
     * @dev Upgrades the tier of an existing Skill Badge.
     * This can be triggered by the owner if conditions (e.g., higher reputation, more attestations) are met.
     * @param _badgeId The ID of the Skill Badge to upgrade.
     */
    function upgradeSkillBadge(uint256 _badgeId) external whenNotPaused onlyBadgeOwner(_badgeId) {
        SkillBadge storage badge = skillBadges[_badgeId];
        Proposal storage p = proposals[badge.proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();

        BadgeTier currentTier = badge.tier;
        BadgeTier potentialNewTier = _getBadgeTier(p.totalAttestationWeight, p.aiScore);

        if (potentialNewTier > currentTier) {
            badge.tier = potentialNewTier;
            badge.lastUpgradeTime = block.timestamp;
            // Optionally update metadataURI here if tiers have different URIs
            emit SkillBadgeUpgraded(_badgeId, potentialNewTier);
        } else {
            // No upgrade possible or conditions not met
            revert CognitoNexus__InvalidChallengeState(); // Revert for no upgrade
        }
    }

    /**
     * @dev Degrades the tier of an existing Skill Badge.
     * This might happen after a successful challenge to an underlying attestation or other negative events.
     * Only callable by owner or via internal logic (e.g., from resolveChallenge).
     * @param _badgeId The ID of the Skill Badge to degrade.
     */
    function degradeSkillBadge(uint256 _badgeId) public whenNotPaused { // Changed to public for internal calls
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0)) revert CognitoNexus__BadgeNotFound();
        // Allow owner or contract itself (via other functions) to degrade
        if (msg.sender != badge.owner && msg.sender != address(this)) revert CognitoNexus__NotBadgeOwner();

        Proposal storage p = proposals[badge.proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();

        BadgeTier currentTier = badge.tier;
        BadgeTier potentialNewTier = _getBadgeTier(p.totalAttestationWeight, p.aiScore);

        if (potentialNewTier < currentTier) {
            badge.tier = potentialNewTier;
            // Optionally update metadataURI here
            emit SkillBadgeDegraded(_badgeId, potentialNewTier);
        } else {
            revert CognitoNexus__InvalidChallengeState(); // No degradation possible
        }
    }

    /**
     * @dev Retrieves details for a specific Skill Badge.
     * @param _badgeId The ID of the Skill Badge.
     * @return owner The address of the badge owner.
     * @return proposalId The ID of the associated proposal.
     * @return metadataURI The URI for the badge's metadata.
     * @return mintTime The timestamp when the badge was minted.
     * @return tier The current tier of the badge.
     * @return lastUpgradeTime The last time the badge was upgraded.
     */
    function getSkillBadgeDetails(uint256 _badgeId)
        external
        view
        returns (
            address owner,
            uint256 proposalId,
            string memory metadataURI,
            uint256 mintTime,
            BadgeTier tier,
            uint256 lastUpgradeTime
        )
    {
        SkillBadge storage badge = skillBadges[_badgeId];
        if (badge.owner == address(0)) revert CognitoNexus__BadgeNotFound();

        return (
            badge.owner,
            badge.proposalId,
            badge.metadataURI,
            badge.mintTime,
            badge.tier,
            badge.lastUpgradeTime
        );
    }

    /**
     * @dev Lists all Skill Badges owned by a given participant.
     * @param _participant The address of the participant.
     * @return An array of Skill Badge IDs.
     */
    function getParticipantSkillBadges(address _participant) external view returns (uint256[] memory) {
        return participantSkillBadges[_participant];
    }

    // --- V. Reputation & AI-Enhanced Scoring (Conceptual Oracle) ---

    /**
     * @dev Retrieves the current reputation score for an account.
     * @param _account The address of the account.
     * @return The current reputation score.
     */
    function getReputation(address _account) external view returns (uint256) {
        return participants[_account].reputation;
    }

    /**
     * @dev Allows the designated AI Oracle to submit an evaluation for a proposal.
     * This score influences attestation weighting and badge tiers.
     * @param _proposalId The ID of the proposal.
     * @param _aiScore The AI-generated score (e.g., 0-100).
     * @param _reportURI URI pointing to the detailed AI report.
     */
    function submitAIOracleReport(uint256 _proposalId, uint256 _aiScore, string memory _reportURI)
        external
        whenNotPaused
    {
        if (msg.sender != aiOracleAddress) revert CognitoNexus__CannotCallAsAIOracle();

        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();
        if (p.aiScoreSubmitted) revert CognitoNexus__InvalidChallengeState(); // Can't resubmit AI score

        p.aiScore = _aiScore;
        p.aiReportURI = _reportURI;
        p.aiScoreSubmitted = true;
        emit AIOracleReportSubmitted(_proposalId, _aiScore, _reportURI);
    }

    /**
     * @dev Retrieves the AI-generated score for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return The AI score (0-100) and the report URI.
     */
    function getAIOracleScore(uint256 _proposalId) external view returns (uint256, string memory) {
        Proposal storage p = proposals[_proposalId];
        if (p.proposer == address(0)) revert CognitoNexus__ProposalNotFound();
        if (!p.aiScoreSubmitted) revert CognitoNexus__AIReportNotSubmitted();
        return (p.aiScore, p.aiReportURI);
    }

    // --- VI. Dispute Resolution ---

    /**
     * @dev Allows any registered participant to challenge an existing attestation.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonURI URI pointing to the challenger's detailed reason.
     * @return The ID of the newly created challenge.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reasonURI)
        external
        whenNotPaused
        returns (uint256)
    {
        if (!_isParticipant(msg.sender)) revert CognitoNexus__NotParticipant();
        Attestation storage a = attestations[_attestationId];
        if (a.attestor == address(0)) revert CognitoNexus__AttestationNotFound();
        if (a.challengeId != 0) revert CognitoNexus__InvalidChallengeState(); // Already challenged

        _nextChallengeId++;
        uint256 challengeId = _nextChallengeId;

        challenges[challengeId] = Challenge({
            challengeId: challengeId,
            attestationId: _attestationId,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            startTime: block.timestamp,
            endTime: block.timestamp + challengePeriod,
            votesForAttestation: 0,
            votesAgainstAttestation: 0,
            resolved: false,
            attestationUpheld: false,
            hasVoted: new mapping(address => bool)() // Initialize mapping
        });

        a.challengeId = challengeId;
        emit AttestationChallenged(msg.sender, challengeId, _attestationId, _reasonURI);
        return challengeId;
    }

    /**
     * @dev Allows active attestors to vote on a challenged attestation.
     * @param _challengeId The ID of the challenge.
     * @param _supportsAttestation True if the voter believes the attestation is valid, false otherwise.
     */
    function voteOnChallenge(uint256 _challengeId, bool _supportsAttestation) external whenNotPaused {
        if (!_isActiveAttestor(msg.sender)) revert CognitoNexus__NotAttestor();
        Challenge storage c = challenges[_challengeId];
        if (c.challenger == address(0)) revert CognitoNexus__ChallengeNotFound();
        if (c.resolved) revert CognitoNexus__ChallengeAlreadyResolved();
        if (block.timestamp > c.endTime) revert CognitoNexus__ChallengeNotActive();
        if (c.hasVoted[msg.sender]) revert CognitoNexus__AlreadyVotedOnChallenge();

        // An attestor cannot vote on a challenge involving their own attestation.
        // Or if they are the proposer of the challenged proposal.
        Attestation storage a = attestations[c.attestationId];
        if (a.attestor == msg.sender) revert CognitoNexus__CannotAttestOwnProposal();
        if (proposals[a.proposalId].proposer == msg.sender) revert CognitoNexus__CannotAttestOwnProposal();


        c.hasVoted[msg.sender] = true;
        if (_supportsAttestation) {
            c.votesForAttestation++;
        } else {
            c.votesAgainstAttestation++;
        }
        emit ChallengeVoted(msg.sender, _challengeId, _supportsAttestation);
    }

    /**
     * @dev Finalizes a challenge, applying rewards/penalties based on the outcome.
     * Can only be called after the challenge voting period has ended.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function resolveChallenge(uint256 _challengeId) external whenNotPaused {
        Challenge storage c = challenges[_challengeId];
        if (c.challenger == address(0)) revert CognitoNexus__ChallengeNotFound();
        if (c.resolved) revert CognitoNexus__ChallengeAlreadyResolved();
        if (block.timestamp < c.endTime) revert CognitoNexus__VotingPeriodNotEnded();

        Attestation storage a = attestations[c.attestationId];
        Proposal storage p = proposals[a.proposalId];

        bool attestationUpheld = c.votesForAttestation >= c.votesAgainstAttestation;
        c.attestationUpheld = attestationUpheld;
        c.resolved = true;

        uint256 reputationGainForChallenger = 0;
        uint256 reputationLossForAttestor = 0;
        uint256 reputationLossForChallenger = 0;

        if (attestationUpheld) {
            // Attestation was valid
            // Challenger loses reputation
            _updateReputation(c.challenger, -int256(BASE_REPUTATION_LOSS_CHALLENGE_LOSE));
            reputationLossForChallenger = BASE_REPUTATION_LOSS_CHALLENGE_LOSE;
        } else {
            // Attestation was invalid
            a.isValid = false; // Mark attestation as invalid
            // Attestor loses reputation, challenger gains
            _updateReputation(a.attestor, -int256(BASE_REPUTATION_LOSS_FALSE_ATTEST));
            _updateReputation(c.challenger, int256(BASE_REPUTATION_GAIN_CHALLENGE_WIN));
            reputationGainForChallenger = BASE_REPUTATION_GAIN_CHALLENGE_WIN;
            reputationLossForAttestor = BASE_REPUTATION_LOSS_FALSE_ATTEST;

            // Adjust proposal's total weight
            uint256 attestationWeight = _calculateAttestationWeight(a.reputationAtAttestation, a.attestorStakeAtAttestation);
            p.totalAttestationWeight -= (attestationWeight * (p.aiScore > 0 ? p.aiScore : 1) / 100);

            // If a badge was minted, potentially degrade it
            if (p.hasMintedBadge) {
                SkillBadge storage badge = skillBadges[p.badgeId];
                if (badge.owner != address(0) && _getBadgeTier(p.totalAttestationWeight, p.aiScore) < badge.tier) {
                    degradeSkillBadge(p.badgeId); // Internal call
                }
            }
        }
        emit ChallengeResolved(_challengeId, attestationUpheld, reputationGainForChallenger, reputationLossForChallenger);
    }

    // --- VII. Governance & Administrative ---

    /**
     * @dev Sets the minimum stake requirement for becoming an attestor.
     * Only callable by the contract owner.
     * @param _newAmount The new minimum stake amount.
     */
    function setAttestorStakeRequirement(uint256 _newAmount) external onlyOwner whenNotPaused {
        attestorStakeRequirement = _newAmount;
        emit AttestorStakeRequirementUpdated(_newAmount);
    }

    /**
     * @dev Sets the address of the trusted AI Oracle contract/entity.
     * Only callable by the contract owner.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner whenNotPaused {
        if (_newOracle == address(0)) revert CognitoNexus__InvalidAIOracleAddress();
        aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Sets the duration for the challenge voting period.
     * Only callable by the contract owner.
     * @param _newPeriod The new challenge period duration in seconds.
     */
    function setChallengePeriod(uint256 _newPeriod) external onlyOwner whenNotPaused {
        challengePeriod = _newPeriod;
        emit ChallengePeriodUpdated(_newPeriod);
    }

    /**
     * @dev Sets the cooldown period for attestor stake withdrawal.
     * Only callable by the contract owner.
     * @param _newPeriod The new cooldown period duration in seconds.
     */
    function setCooldownPeriod(uint256 _newPeriod) external onlyOwner whenNotPaused {
        attestorWithdrawalCooldown = _newPeriod;
        emit AttestorWithdrawalCooldownUpdated(_newPeriod);
    }

    /**
     * @dev Pauses the core functionality of the contract.
     * Only callable by the contract owner.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the core functionality of the contract.
     * Only callable by the contract owner.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }
}
```