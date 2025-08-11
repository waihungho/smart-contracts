The `SyntheticaMinerva` contract is a pioneering Decentralized Knowledge Protocol designed to foster a self-correcting, community-driven on-chain knowledge base. It combines elements of decentralized academia, robust on-chain reputation, and dynamic Soulbound Knowledge Units (SKUs). SKUs are non-transferable NFTs whose attributes (Veracity, Impact, Obsolescence) evolve based on community interaction like citations, reviews, and formal challenges. The protocol rewards quality contributions and facilitates community-funded research grants.

---

## Outline: Synthetica Minerva - Decentralized Knowledge Protocol

A pioneering protocol for curating, contributing, challenging, and evolving on-chain knowledge units. Synthetica Minerva blends decentralized academia, robust on-chain reputation, and dynamic Soulbound Knowledge Units (SKUs). Knowledge Units (SKUs) are non-transferable NFTs, with their attributes (e.g., Veracity, Impact, Obsolescence) evolving based on community interaction like citations, reviews, and formal challenges. The protocol fosters a self-correcting knowledge base, rewarding quality contributions and facilitating community-driven research.

## Function Summary:

### I. Core Knowledge Unit (SKU) Management & Lifecycle
1.  **`contributeKnowledgeUnit(string _ipfsHash, string _metadataURI)`**: Mints a new, non-transferable Soulbound Knowledge Unit (SKU) linked to the contributor, storing its content and metadata hashes.
2.  **`updateKnowledgeUnitContent(uint256 _skuId, string _newIpfsHash, string _newMetadataURI)`**: Allows the SKU's author to update its off-chain content hashes and metadata URI, enabling content revisions.
3.  **`getKnowledgeUnitDetails(uint256 _skuId)`**: Retrieves all on-chain metadata and dynamic scores (veracity, impact, obsolescence) for a specific SKU.
4.  **`archiveKnowledgeUnit(uint256 _skuId)`**: Moves an SKU to an 'Archived' state, typically due to obsolescence or a successful challenge outcome (callable by owner/curator).
5.  **`getArchivedKnowledgeUnits()`**: Provides a list of all currently archived SKUs, useful for auditing or discovering historical knowledge.

### II. Community Interaction & Curation
6.  **`citeKnowledgeUnit(uint256 _skuId)`**: Records a citation for an SKU by any user, incrementally boosting its 'Impact Score' and indicating its relevance.
7.  **`reviewKnowledgeUnit(uint256 _skuId, uint8 _rating, string _reviewHash)`**: Allows users to submit a structured review (rating and off-chain content hash for detailed feedback) for an SKU, influencing its impact.
8.  **`proposeKnowledgeGrant(string _topicHash, uint256 _fundingAmount)`**: Initiates a proposal for community-funded research or development, specifying the topic and requested funds.
9.  **`stakeForGrantProposal(uint256 _proposalId)`**: Allows community members to stake tokens (ETH) in support of a grant proposal, contributing to its funding target.
10. **`claimGrantFunds(uint256 _proposalId)`**: Enables the proposer of a successful (fully funded) grant to withdraw the collected funds.
11. **`reclaimGrantStake(uint256 _proposalId)`**: Allows participants to reclaim their staked funds for grant proposals that did not meet their funding target.

### III. Challenge & Dispute Resolution System
12. **`initiateKnowledgeChallenge(uint256 _skuId, string _challengeReasonHash)`**: Commences a formal challenge against an SKU's validity or accuracy, requiring a stake from the challenger to prevent spam.
13. **`submitChallengeEvidence(uint256 _challengeId, string _evidenceHash)`**: The challenger submits supporting evidence for their ongoing challenge, moving it into the voting phase.
14. **`voteOnKnowledgeChallenge(uint256 _challengeId, bool _supportsChallenge)`**: Community members vote on whether the challenge is valid (`true`) or invalid (`false`), influencing the SKU's veracity score.
15. **`resolveKnowledgeChallenge(uint256 _challengeId)`**: Finalizes the challenge outcome based on votes, redistributes stakes, and updates the SKU's status and scores (veracity, obsolescence).
16. **`reclaimChallengeStake(uint256 _challengeId)`**: Allows the winning party (challenger if successful, or SKU author if challenge fails, or anyone if stakes are just released) to reclaim their staked funds after a challenge is resolved.

### IV. Reputation, Metrics & Dynamic Evolution
17. **`getAuthorWisdomPoints(address _author)`**: Retrieves the total accumulated 'Wisdom Points' (a measure of reputation) for a given address, earned through quality contributions and interactions.
18. **`getKnowledgeUnitScores(uint256 _skuId)`**: Fetches the current 'Veracity Score', 'Impact Score', and 'Obsolescence Timer' for an SKU, reflecting its dynamic standing.
19. **`triggerObsolescenceDecay(uint256 _skuId)`**: A callable function (potentially by anyone for a small reward) to trigger the decay of an SKU's obsolescence score if it lacks recent interaction, eventually marking it as obsolete.

### V. Governance & Protocol Management
20. **`setProtocolParameter(bytes32 _paramName, uint256 _value)`**: An Owner/DAO function to adjust key protocol parameters (e.g., challenge fees, voting durations, score decay rates, incentive amounts).
21. **`appointCurator(address _newCurator)`**: Appoints a new curator with specific moderation privileges (e.g., archiving SKUs).
22. **`removeCurator(address _curator)`**: Revokes curator privileges from an address.
23. **`emergencyPause()`**: Allows the Owner/DAO to pause critical contract functions in an emergency situation (e.g., bug discovery, exploit).
24. **`unpause()`**: Allows the Owner/DAO to unpause the contract after an emergency pause.
25. **`withdrawTreasuryFunds(address _to, uint256 _amount)`**: Enables the Owner/DAO to withdraw accumulated funds from the protocol treasury for maintenance, operational costs, or strategic initiatives.

### VI. Advanced Concepts & Utility
26. **`crossReferenceKnowledge(uint256 _sourceSkuId, uint256 _referencedSkuId, string _contextHash)`**: Creates a formal on-chain link between two SKUs, where one (source) references another (referenced), enriching the overall knowledge graph and boosting the referenced SKU's impact.
27. **`mintSyntheticaCredits(address _to, uint256 _amount)`**: (Internal/Restricted) Mints internal 'Synthetica Credits', which serve as a fungible reward token within the protocol for various positive actions.
28. **`burnSyntheticaCredits(address _from, uint256 _amount)`**: (Internal/Restricted) Burns 'Synthetica Credits', potentially used for governance or specific utility functions.
29. **`distributeIncentives()`**: A callable function (or triggered by events/automated system) to distribute 'Synthetica Credits' to participants based on their contributions and positive interactions, encouraging engagement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // While Solidity 0.8+ has built-in checks, explicit import can enhance clarity or be used for specific custom math operations

// Outline: Synthetica Minerva - Decentralized Knowledge Protocol

// A pioneering protocol for curating, contributing, challenging, and evolving on-chain knowledge units.
// Synthetica Minerva blends decentralized academia, robust on-chain reputation, and dynamic Soulbound Knowledge Units (SKUs).
// Knowledge Units (SKUs) are non-transferable NFTs, with their attributes (e.g., Veracity, Impact, Obsolescence)
// evolving based on community interaction like citations, reviews, and formal challenges.
// The protocol fosters a self-correcting knowledge base, rewarding quality contributions and facilitating community-driven research.

// Function Summary:

// I. Core Knowledge Unit (SKU) Management & Lifecycle
// 1.  contributeKnowledgeUnit(string _ipfsHash, string _metadataURI): Mints a new, non-transferable Soulbound Knowledge Unit (SKU) linked to the contributor.
// 2.  updateKnowledgeUnitContent(uint256 _skuId, string _newIpfsHash, string _newMetadataURI): Allows the SKU's author to update its off-chain content hashes.
// 3.  getKnowledgeUnitDetails(uint256 _skuId): Retrieves all on-chain metadata and dynamic scores for a specific SKU.
// 4.  archiveKnowledgeUnit(uint256 _skuId): Moves an SKU to an 'Archived' state, typically due to obsolescence or a successful challenge.
// 5.  getArchivedKnowledgeUnits(): Provides a list of all currently archived SKUs.

// II. Community Interaction & Curation
// 6.  citeKnowledgeUnit(uint256 _skuId): Records a citation for an SKU, incrementally boosting its 'Impact Score'.
// 7.  reviewKnowledgeUnit(uint256 _skuId, uint8 _rating, string _reviewHash): Allows users to submit a structured review (rating and off-chain content hash) for an SKU.
// 8.  proposeKnowledgeGrant(string _topicHash, uint256 _fundingAmount): Initiates a proposal for a research grant, specifying topic and requested funds.
// 9.  stakeForGrantProposal(uint256 _proposalId): Allows community members to stake tokens to support a grant proposal.
// 10. claimGrantFunds(uint256 _proposalId): Enables successful grant proposers to withdraw the allocated funds.
// 11. reclaimGrantStake(uint256 _proposalId): Allows participants to reclaim their staked funds for unfunded grant proposals.

// III. Challenge & Dispute Resolution System
// 12. initiateKnowledgeChallenge(uint256 _skuId, string _challengeReasonHash): Commences a formal challenge against an SKU's validity or accuracy, requiring a stake from the challenger.
// 13. submitChallengeEvidence(uint256 _challengeId, string _evidenceHash): Challenger submits supporting evidence for their ongoing challenge.
// 14. voteOnKnowledgeChallenge(uint256 _challengeId, bool _supportsChallenge): Community members vote on whether the challenge is valid (true) or invalid (false).
// 15. resolveKnowledgeChallenge(uint256 _challengeId): Finalizes the challenge outcome, redistributes stakes, and updates the SKU's status and scores based on the vote.
// 16. reclaimChallengeStake(uint256 _challengeId): Allows the winning party (challenger or SKU author) to reclaim their staked funds after a challenge is resolved.

// IV. Reputation, Metrics & Dynamic Evolution
// 17. getAuthorWisdomPoints(address _author): Retrieves the total accumulated 'Wisdom Points' (reputation) for a given address.
// 18. getKnowledgeUnitScores(uint256 _skuId): Fetches the current 'Veracity Score', 'Impact Score', and 'Obsolescence Timer' for an SKU.
// 19. triggerObsolescenceDecay(uint256 _skuId): A callable function (potentially by anyone for a small reward) to trigger the decay of an SKU's obsolescence score if it lacks recent interaction.

// V. Governance & Protocol Management
// 20. setProtocolParameter(bytes32 _paramName, uint256 _value): An Owner/DAO function to adjust key protocol parameters (e.g., challenge fees, voting periods, scores decay rates).
// 21. appointCurator(address _newCurator): Appoints a new curator who can moderate.
// 22. removeCurator(address _curator): Revokes curator privileges from an address.
// 23. emergencyPause(): Allows the Owner/DAO to pause critical contract functions in an emergency.
// 24. unpause(): Allows the Owner/DAO to unpause the contract after an emergency pause.
// 25. withdrawTreasuryFunds(address _to, uint256 _amount): Enables the Owner/DAO to withdraw funds from the protocol treasury for maintenance or operations.

// VI. Advanced Concepts & Utility
// 26. crossReferenceKnowledge(uint256 _sourceSkuId, uint256 _referencedSkuId, string _contextHash): Creates a formal on-chain link between two SKUs, enriching the knowledge graph.
// 27. mintSyntheticaCredits(address _to, uint256 _amount): (Internal/Restricted) Mints internal 'Synthetica Credits' used for rewarding participants.
// 28. burnSyntheticaCredits(address _from, uint256 _amount): (Internal/Restricted) Burns 'Synthetica Credits'.
// 29. distributeIncentives(): Callable function (or triggered by events) to distribute 'Synthetica Credits' to participants based on their contributions and positive interactions.

contract SyntheticaMinerva is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // SKU (Knowledge Unit)
    struct KnowledgeUnit {
        uint256 id;
        address author;
        string ipfsHash; // Hash of the main content (e.g., research paper, article)
        string metadataURI; // URI to metadata (e.g., title, description, abstract)
        uint64 createdAt;
        uint64 lastUpdatedAt;
        uint64 lastInteractedAt; // For obsolescence tracking
        uint8 veracityScore; // 0-100, starts at 50, increases/decreases with challenges
        uint8 impactScore; // 0-100, starts at 0, increases with citations/reviews
        uint8 obsolescenceTimer; // 0-100, starts at 100, decays over time, resets with interaction
        SkuStatus status;
        uint256[] referencedBy; // List of SKUs that reference this one
    }

    enum SkuStatus {
        Pending, // Initial state, not used in this contract (contributions start as Verified)
        Verified, // Active and generally accepted
        Challenged, // Currently under a formal challenge
        Archived, // Permanently moved to archive (e.g., due to successful challenge or curator decision)
        Obsolete // Marked as obsolete due to lack of interaction / decay
    }

    Counters.Counter private _skuIds;
    mapping(uint256 => KnowledgeUnit) public knowledgeUnits;

    // Challenge System
    struct Challenge {
        uint256 id;
        uint256 skuId;
        address challenger;
        uint256 stakeAmount;
        string challengeReasonHash;
        string evidenceHash;
        uint64 initiatedAt;
        uint64 votingEndsAt;
        uint256 votesForChallenge;
        uint256 votesAgainstChallenge;
        ChallengeStatus status;
        uint256 totalVotes; // Total votes cast on this challenge
    }

    enum ChallengeStatus {
        Initiated, // Challenge proposed, waiting for evidence
        EvidenceSubmitted, // Evidence provided, voting period starts (renamed to avoid redundancy with next status)
        Voting, // Voting is active
        ResolvedSuccess, // Challenge passed (SKU's veracity reduced, challenger wins stake)
        ResolvedFailure, // Challenge failed (SKU's veracity increased, challenger loses stake)
        Cancelled // Challenge cancelled by challenger or curator
    }

    Counters.Counter private _challengeIds;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => mapping(address => bool)) private _hasVotedOnChallenge;

    // Grant System
    struct GrantProposal {
        uint256 id;
        address proposer;
        string topicHash;
        uint256 fundingTargetAmount; // In native currency (ETH) - the goal to reach
        uint64 createdAt;
        uint64 fundingEndsAt; // Timestamp when funding period ends
        uint256 totalFunded; // Total ETH collected towards the target
        GrantStatus status;
        mapping(address => uint256) stakers; // To track individual stakes/contributions
        bool claimed; // Whether the proposer has claimed funds
    }

    enum GrantStatus {
        Proposed,
        Funding, // Renamed from Voting to better reflect crowdfunding aspect
        Approved, // Funding target met
        Rejected, // Funding target not met
        Claimed // Funds have been claimed by proposer
    }

    Counters.Counter private _grantIds;
    mapping(uint256 => GrantProposal) public grantProposals;

    // Reputation & Credits
    mapping(address => uint256) public authorWisdomPoints; // Reputation for authors and contributors
    mapping(address => uint256) public syntheticaCredits; // Internal ERC20-like token for incentives

    // Protocol Parameters (adjustable by owner/DAO)
    mapping(bytes32 => uint256) public protocolParameters;

    // Curators (can perform certain moderation actions)
    mapping(address => bool) public isCurator;

    // --- Events ---
    event KnowledgeUnitContributed(uint256 indexed skuId, address indexed author, string ipfsHash, string metadataURI, uint64 createdAt);
    event KnowledgeUnitUpdated(uint256 indexed skuId, address indexed author, string newIpfsHash, string newMetadataURI, uint64 updatedAt);
    event KnowledgeUnitArchived(uint256 indexed skuId, SkuStatus oldStatus, SkuStatus newStatus);
    event KnowledgeUnitCited(uint256 indexed skuId, address indexed citer, uint8 newImpactScore);
    event KnowledgeUnitReviewed(uint256 indexed skuId, address indexed reviewer, uint8 rating, string reviewHash);
    event KnowledgeUnitCrossReferenced(uint256 indexed sourceSkuId, uint256 indexed referencedSkuId, string contextHash);

    event GrantProposalProposed(uint256 indexed proposalId, address indexed proposer, string topicHash, uint256 fundingTargetAmount, uint64 createdAt);
    event GrantProposalStaked(uint256 indexed proposalId, address indexed staker, uint256 amount, uint256 totalFunded);
    event GrantProposalStatusUpdated(uint256 indexed proposalId, GrantStatus newStatus);
    event GrantFundsClaimed(uint256 indexed proposalId, address indexed claimant, uint256 amount);
    event GrantStakeReclaimed(uint256 indexed proposalId, address indexed staker, uint256 amount);

    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed skuId, address indexed challenger, uint256 stakeAmount, string reasonHash);
    event ChallengeEvidenceSubmitted(uint256 indexed challengeId, address indexed submitter, string evidenceHash);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool supportsChallenge);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed skuId, ChallengeStatus newStatus, uint256 votesFor, uint256 votesAgainst);
    event ChallengeStakeReclaimed(uint256 indexed challengeId, address indexed winner, uint256 amount);

    event WisdomPointsUpdated(address indexed user, uint256 newPoints);
    event SyntheticaCreditsMinted(address indexed to, uint256 amount);
    event SyntheticaCreditsBurned(address indexed from, uint256 amount);
    event IncentivesDistributed(uint256 totalAmount);
    event ObsolescenceDecayTriggered(uint256 indexed skuId, uint8 newObsolescenceTimer);

    event ProtocolParameterSet(bytes32 indexed paramName, uint256 value);
    event CuratorAppointed(address indexed curator);
    event CuratorRemoved(address indexed curator);
    event Paused(address account);
    event Unpaused(address account);

    // --- Custom Errors ---
    error InvalidSKUId();
    error NotSKUAuthor();
    error SKUNotInValidStatus();
    error InvalidRating();
    error ActiveChallengeExists(); // More descriptive name
    error ChallengeNotInCorrectPhase();
    error NotChallenger();
    error AlreadyVoted();
    error VotingPeriodEnded();
    error NotEnoughStake();
    error GrantFundingEnded();
    error GrantNotApprovedOrClaimed(); // Covers both
    error SelfReferenceNotAllowed();
    error ParameterDoesNotExist();
    error InsufficientCredits();
    error NotEnoughFunds();
    error AlreadyArchived();
    error FundingPeriodNotEnded();
    error NotEnoughFundsToFulfillGrant();
    error NotAllowedToReclaimStake(); // For challenge or grant stake
    error ChallengeAlreadyResolved();


    // --- Constructor ---
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) Ownable(msg.sender) {
        // Initialize default protocol parameters
        protocolParameters["minChallengeStake"] = 0.05 ether; // Example: 0.05 ETH
        protocolParameters["challengeVotingDuration"] = 7 days;
        protocolParameters["grantFundingDuration"] = 14 days; // Renamed from grantVotingDuration
        protocolParameters["grantApprovalThresholdPercent"] = 100; // 100% of target must be funded for approval
        protocolParameters["wisdomPointsForContribution"] = 10;
        protocolParameters["wisdomPointsForSuccessfulChallenge"] = 20;
        protocolParameters["wisdomPointsForSuccessfulReview"] = 5;
        protocolParameters["obsolescenceDecayRate"] = 10; // % per decay trigger (e.g., 10%)
        protocolParameters["obsolescenceDecayInterval"] = 30 days; // How often decay can be triggered
        protocolParameters["creditMintRate"] = 100; // Example: 100 credits per action
        protocolParameters["veracityChangeOnChallenge"] = 10; // How much veracity changes on challenge success/failure
        protocolParameters["impactChangeOnCite"] = 1;
        protocolParameters["impactChangeOnReview"] = 2;
        protocolParameters["crossReferenceImpactBoost"] = 3; // Impact boost for cross-referencing
        protocolParameters["incentiveDistributionAmount"] = 500; // For `distributeIncentives`
        protocolParameters["decayTriggerCreditReward"] = 10; // Reward for calling triggerObsolescenceDecay
    }

    // --- Modifiers ---
    modifier onlyCurator() {
        if (!isCurator[msg.sender] && owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender); // Revert with OpenZeppelin's Ownable error for consistency
        }
        _;
    }

    // Pausability modifiers (from OpenZeppelin's Pausable)
    bool private _paused;

    modifier whenNotPaused() {
        _assertNotPaused();
        _;
    }

    modifier whenPaused() {
        _assertPaused();
        _;
    }

    function _assertNotPaused() internal view {
        require(!_paused, "Pausable: paused");
    }

    function _assertPaused() internal view {
        require(_paused, "Pausable: not paused");
    }

    // ERC721 overrides to make SKUs soulbound (non-transferable)
    function _transfer(address, address, uint256) internal pure override {
        revert("SyntheticaMinerva: SKUs are soulbound and non-transferable.");
    }

    function _approve(address, uint256) internal pure override {
        revert("SyntheticaMinerva: SKUs are soulbound and non-transferable.");
    }

    function _setApprovalForAll(address, bool) internal pure override {
        revert("SyntheticaMinerva: SKUs are soulbound and non-transferable.");
    }

    function _safeTransferFrom(address, address, uint256, bytes memory) internal pure override {
        revert("SyntheticaMinerva: SKUs are soulbound and non-transferable.");
    }

    function _safeTransferFrom(address, address, uint256) internal pure override {
        revert("SyntheticaMinerva: SKUs are soulbound and non-transferable.");
    }

    // Function 23: emergencyPause()
    function emergencyPause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    // Function 24: unpause()
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // Function 27: mintSyntheticaCredits(address _to, uint256 _amount)
    function mintSyntheticaCredits(address _to, uint256 _amount) internal {
        syntheticaCredits[_to] = syntheticaCredits[_to].add(_amount);
        emit SyntheticaCreditsMinted(_to, _amount);
    }

    // Function 28: burnSyntheticaCredits(address _from, uint256 _amount)
    function burnSyntheticaCredits(address _from, uint256 _amount) internal {
        require(syntheticaCredits[_from] >= _amount, "SyntheticaMinerva: Not enough credits to burn.");
        syntheticaCredits[_from] = syntheticaCredits[_from].sub(_amount);
        emit SyntheticaCreditsBurned(_from, _amount);
    }

    // --- I. Core Knowledge Unit (SKU) Management & Lifecycle ---

    // Function 1: contributeKnowledgeUnit(string _ipfsHash, string _metadataURI)
    function contributeKnowledgeUnit(string calldata _ipfsHash, string calldata _metadataURI)
        public
        whenNotPaused
        returns (uint256)
    {
        _skuIds.increment();
        uint256 newId = _skuIds.current();
        uint64 currentTime = uint64(block.timestamp);

        KnowledgeUnit storage newSKU = knowledgeUnits[newId];
        newSKU.id = newId;
        newSKU.author = msg.sender;
        newSKU.ipfsHash = _ipfsHash;
        newSKU.metadataURI = _metadataURI;
        newSKU.createdAt = currentTime;
        newSKU.lastUpdatedAt = currentTime;
        newSKU.lastInteractedAt = currentTime;
        newSKU.veracityScore = 50; // Initial neutral score (0-100)
        newSKU.impactScore = 0; // Initial score
        newSKU.obsolescenceTimer = 100; // Starts at max (100)
        newSKU.status = SkuStatus.Verified; // New contributions start as verified, can be challenged

        _safeMint(msg.sender, newId); // Mints the SKU as a non-transferable NFT
        _setTokenURI(newId, _metadataURI); // Set URI for the NFT

        authorWisdomPoints[msg.sender] = authorWisdomPoints[msg.sender].add(protocolParameters["wisdomPointsForContribution"]);
        emit WisdomPointsUpdated(msg.sender, authorWisdomPoints[msg.sender]);
        emit KnowledgeUnitContributed(newId, msg.sender, _ipfsHash, _metadataURI, currentTime);

        return newId;
    }

    // Function 2: updateKnowledgeUnitContent(uint256 _skuId, string _newIpfsHash, string _newMetadataURI)
    function updateKnowledgeUnitContent(uint256 _skuId, string calldata _newIpfsHash, string calldata _newMetadataURI)
        public
        whenNotPaused
    {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.author != msg.sender) revert NotSKUAuthor();
        if (sku.status == SkuStatus.Challenged || sku.status == SkuStatus.Archived) revert SKUNotInValidStatus();

        sku.ipfsHash = _newIpfsHash;
        sku.metadataURI = _newMetadataURI;
        sku.lastUpdatedAt = uint64(block.timestamp);
        _setTokenURI(_skuId, _newMetadataURI);

        emit KnowledgeUnitUpdated(_skuId, msg.sender, _newIpfsHash, _newMetadataURI, sku.lastUpdatedAt);
    }

    // Function 3: getKnowledgeUnitDetails(uint256 _skuId)
    function getKnowledgeUnitDetails(uint256 _skuId)
        public
        view
        returns (
            uint256 id,
            address author,
            string memory ipfsHash,
            string memory metadataURI,
            uint64 createdAt,
            uint64 lastUpdatedAt,
            uint64 lastInteractedAt,
            uint8 veracityScore,
            uint8 impactScore,
            uint8 obsolescenceTimer,
            SkuStatus status,
            uint256[] memory referencedBy
        )
    {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();

        return (
            sku.id,
            sku.author,
            sku.ipfsHash,
            sku.metadataURI,
            sku.createdAt,
            sku.lastUpdatedAt,
            sku.lastInteractedAt,
            sku.veracityScore,
            sku.impactScore,
            sku.obsolescenceTimer,
            sku.status,
            sku.referencedBy
        );
    }

    // Function 4: archiveKnowledgeUnit(uint256 _skuId)
    function archiveKnowledgeUnit(uint256 _skuId) public onlyCurator whenNotPaused {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.status == SkuStatus.Archived) revert AlreadyArchived();

        SkuStatus oldStatus = sku.status;
        sku.status = SkuStatus.Archived;

        emit KnowledgeUnitArchived(_skuId, oldStatus, sku.status);
    }

    // Function 5: getArchivedKnowledgeUnits()
    function getArchivedKnowledgeUnits() public view returns (uint256[] memory) {
        uint256[] memory archivedIds = new uint256[](_skuIds.current());
        uint256 count = 0;
        for (uint256 i = 1; i <= _skuIds.current(); i++) {
            if (knowledgeUnits[i].status == SkuStatus.Archived) {
                archivedIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = archivedIds[i];
        }
        return result;
    }

    // --- II. Community Interaction & Curation ---

    // Function 6: citeKnowledgeUnit(uint256 _skuId)
    function citeKnowledgeUnit(uint256 _skuId) public whenNotPaused {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.status == SkuStatus.Archived || sku.status == SkuStatus.Obsolete) revert SKUNotInValidStatus();

        sku.impactScore = (sku.impactScore.add(protocolParameters["impactChangeOnCite"]) > 100) ? 100 : sku.impactScore.add(protocolParameters["impactChangeOnCite"]);
        sku.lastInteractedAt = uint64(block.timestamp);

        emit KnowledgeUnitCited(_skuId, msg.sender, sku.impactScore);
        mintSyntheticaCredits(msg.sender, protocolParameters["creditMintRate"]);
    }

    // Function 7: reviewKnowledgeUnit(uint256 _skuId, uint8 _rating, string _reviewHash)
    function reviewKnowledgeUnit(uint256 _skuId, uint8 _rating, string calldata _reviewHash) public whenNotPaused {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.status == SkuStatus.Archived || sku.status == SkuStatus.Obsolete) revert SKUNotInValidStatus();
        if (_rating > 5 || _rating < 1) revert InvalidRating(); // Assuming rating 1-5

        sku.impactScore = (sku.impactScore.add(protocolParameters["impactChangeOnReview"]) > 100) ? 100 : sku.impactScore.add(protocolParameters["impactChangeOnReview"]);
        sku.lastInteractedAt = uint64(block.timestamp);

        emit KnowledgeUnitReviewed(_skuId, msg.sender, _rating, _reviewHash);
        mintSyntheticaCredits(msg.sender, protocolParameters["creditMintRate"]);
        authorWisdomPoints[msg.sender] = authorWisdomPoints[msg.sender].add(protocolParameters["wisdomPointsForSuccessfulReview"]);
        emit WisdomPointsUpdated(msg.sender, authorWisdomPoints[msg.sender]);
    }

    // Function 8: proposeKnowledgeGrant(string _topicHash, uint256 _fundingAmount)
    function proposeKnowledgeGrant(string calldata _topicHash, uint256 _fundingAmount) public whenNotPaused returns (uint256) {
        require(_fundingAmount > 0, "SyntheticaMinerva: Funding amount must be greater than zero.");

        _grantIds.increment();
        uint256 newId = _grantIds.current();

        GrantProposal storage newProposal = grantProposals[newId];
        newProposal.id = newId;
        newProposal.proposer = msg.sender;
        newProposal.topicHash = _topicHash;
        newProposal.fundingTargetAmount = _fundingAmount;
        newProposal.createdAt = uint64(block.timestamp);
        newProposal.fundingEndsAt = uint64(block.timestamp + protocolParameters["grantFundingDuration"]);
        newProposal.status = GrantStatus.Proposed;
        newProposal.claimed = false;

        emit GrantProposalProposed(newId, msg.sender, _topicHash, _fundingAmount, newProposal.createdAt);
        return newId;
    }

    // Function 9: stakeForGrantProposal(uint256 _proposalId)
    function stakeForGrantProposal(uint256 _proposalId) public payable whenNotPaused {
        GrantProposal storage proposal = grantProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ("SyntheticaMinerva: Grant proposal does not exist.");
        if (proposal.status == GrantStatus.Approved || proposal.status == GrantStatus.Rejected || proposal.status == GrantStatus.Claimed) revert GrantFundingEnded();
        if (block.timestamp > proposal.fundingEndsAt) revert GrantFundingEnded();
        if (msg.value == 0) revert ("SyntheticaMinerva: Must send ETH to stake.");
        if (proposal.totalFunded.add(msg.value) > proposal.fundingTargetAmount) revert ("SyntheticaMinerva: Contribution exceeds remaining funding target.");


        proposal.totalFunded = proposal.totalFunded.add(msg.value);
        proposal.stakers[msg.sender] = proposal.stakers[msg.sender].add(msg.value);
        proposal.status = GrantStatus.Funding;

        // Auto-approve if target met
        if (proposal.totalFunded >= proposal.fundingTargetAmount) {
            proposal.status = GrantStatus.Approved;
            emit GrantProposalStatusUpdated(_proposalId, GrantStatus.Approved);
        }

        emit GrantProposalStaked(_proposalId, msg.sender, msg.value, proposal.totalFunded);
    }

    // Function 10: claimGrantFunds(uint256 _proposalId)
    function claimGrantFunds(uint256 _proposalId) public whenNotPaused {
        GrantProposal storage proposal = grantProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ("SyntheticaMinerva: Grant proposal does not exist.");
        if (msg.sender != proposal.proposer) revert ("SyntheticaMinerva: Only proposer can claim funds.");
        if (proposal.claimed) revert GrantNotApprovedOrClaimed();

        // Check if funding period has ended, then determine final status
        if (block.timestamp <= proposal.fundingEndsAt && proposal.status != GrantStatus.Approved) revert FundingPeriodNotEnded();

        if (proposal.status != GrantStatus.Approved) {
            // If not approved after funding period ends
            if (proposal.totalFunded < proposal.fundingTargetAmount) {
                 proposal.status = GrantStatus.Rejected;
                 emit GrantProposalStatusUpdated(_proposalId, GrantStatus.Rejected);
            }
            revert GrantNotApprovedOrClaimed();
        }

        uint256 amountToTransfer = proposal.totalFunded; // Claim the actual funded amount
        require(address(this).balance >= amountToTransfer, NotEnoughFundsToFulfillGrant.selector);

        proposal.claimed = true;
        proposal.status = GrantStatus.Claimed; // Mark as claimed

        (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
        require(success, "SyntheticaMinerva: Failed to transfer grant funds.");

        emit GrantFundsClaimed(_proposalId, msg.sender, amountToTransfer);
    }

    // Function 11: reclaimGrantStake(uint256 _proposalId)
    function reclaimGrantStake(uint256 _proposalId) public whenNotPaused {
        GrantProposal storage proposal = grantProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ("SyntheticaMinerva: Grant proposal does not exist.");
        if (proposal.stakers[msg.sender] == 0) revert ("SyntheticaMinerva: No stake to reclaim.");

        // If funding period has not ended, cannot reclaim.
        if (block.timestamp <= proposal.fundingEndsAt && proposal.status != GrantStatus.Approved) revert FundingPeriodNotEnded();

        // Check if proposal was not fully funded OR if it was approved but not claimed yet (unlikely scenario)
        if (proposal.status == GrantStatus.Approved && proposal.claimed) {
            revert NotAllowedToReclaimStake(); // Funds were claimed by proposer
        }
        
        // If funding period ended and it's not approved, or it's simply rejected.
        if (proposal.status == GrantStatus.Rejected || (proposal.status == GrantStatus.Funding && block.timestamp > proposal.fundingEndsAt && proposal.totalFunded < proposal.fundingTargetAmount)) {
            uint256 stake = proposal.stakers[msg.sender];
            proposal.stakers[msg.sender] = 0; // Clear stake

            (bool success, ) = payable(msg.sender).call{value: stake}("");
            require(success, "SyntheticaMinerva: Failed to reclaim stake.");
            emit GrantStakeReclaimed(_proposalId, msg.sender, stake);
        } else {
            revert NotAllowedToReclaimStake();
        }
    }


    // --- III. Challenge & Dispute Resolution System ---

    // Function 12: initiateKnowledgeChallenge(uint256 _skuId, string _challengeReasonHash)
    function initiateKnowledgeChallenge(uint256 _skuId, string calldata _challengeReasonHash) public payable whenNotPaused {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.status != SkuStatus.Verified && sku.status != SkuStatus.Obsolete) revert SKUNotInValidStatus(); // Can challenge Verified or Obsolete
        if (msg.value < protocolParameters["minChallengeStake"]) revert NotEnoughStake();

        // Ensure no active challenge for this SKU
        for (uint256 i = 1; i <= _challengeIds.current(); i++) {
            Challenge storage existingChallenge = challenges[i];
            if (existingChallenge.skuId == _skuId && (
                existingChallenge.status == ChallengeStatus.Initiated ||
                existingChallenge.status == ChallengeStatus.EvidenceSubmitted ||
                existingChallenge.status == ChallengeStatus.Voting))
            {
                revert ActiveChallengeExists();
            }
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();

        Challenge storage newChallenge = challenges[newChallengeId];
        newChallenge.id = newChallengeId;
        newChallenge.skuId = _skuId;
        newChallenge.challenger = msg.sender;
        newChallenge.stakeAmount = msg.value;
        newChallenge.challengeReasonHash = _challengeReasonHash;
        newChallenge.initiatedAt = uint64(block.timestamp);
        newChallenge.status = ChallengeStatus.Initiated;

        sku.status = SkuStatus.Challenged;

        emit ChallengeInitiated(newChallengeId, _skuId, msg.sender, msg.value, _challengeReasonHash);
    }

    // Function 13: submitChallengeEvidence(uint256 _challengeId, string _evidenceHash)
    function submitChallengeEvidence(uint256 _challengeId, string calldata _evidenceHash) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challenger == address(0)) revert ("SyntheticaMinerva: Challenge does not exist.");
        if (challenge.challenger != msg.sender) revert NotChallenger();
        if (challenge.status != ChallengeStatus.Initiated) revert ChallengeNotInCorrectPhase();

        challenge.evidenceHash = _evidenceHash;
        challenge.votingEndsAt = uint64(block.timestamp + protocolParameters["challengeVotingDuration"]);
        challenge.status = ChallengeStatus.Voting;

        emit ChallengeEvidenceSubmitted(_challengeId, msg.sender, _evidenceHash);
    }

    // Function 14: voteOnKnowledgeChallenge(uint256 _challengeId, bool _supportsChallenge)
    function voteOnKnowledgeChallenge(uint256 _challengeId, bool _supportsChallenge) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challenger == address(0)) revert ("SyntheticaMinerva: Challenge does not exist.");
        if (challenge.status != ChallengeStatus.Voting) revert ChallengeNotInCorrectPhase();
        if (block.timestamp > challenge.votingEndsAt) revert VotingPeriodEnded();
        if (_hasVotedOnChallenge[_challengeId][msg.sender]) revert AlreadyVoted();

        _hasVotedOnChallenge[_challengeId][msg.sender] = true;
        challenge.totalVotes++;

        if (_supportsChallenge) {
            challenge.votesForChallenge++;
        } else {
            challenge.votesAgainstChallenge++;
        }
        mintSyntheticaCredits(msg.sender, protocolParameters["creditMintRate"]);
        emit ChallengeVoted(_challengeId, msg.sender, _supportsChallenge);
    }

    // Function 15: resolveKnowledgeChallenge(uint256 _challengeId)
    function resolveKnowledgeChallenge(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challenger == address(0)) revert ("SyntheticaMinerva: Challenge does not exist.");
        if (challenge.status != ChallengeStatus.Voting) revert ChallengeNotInCorrectPhase();
        if (block.timestamp <= challenge.votingEndsAt) revert VotingPeriodEnded();
        if (challenge.status == ChallengeStatus.ResolvedSuccess || challenge.status == ChallengeStatus.ResolvedFailure) revert ChallengeAlreadyResolved();

        KnowledgeUnit storage sku = knowledgeUnits[challenge.skuId];
        if (sku.author == address(0)) revert InvalidSKUId();

        ChallengeStatus outcome;
        // Simple majority: if votes for challenge are strictly greater than votes against
        if (challenge.votesForChallenge > challenge.votesAgainstChallenge) {
            outcome = ChallengeStatus.ResolvedSuccess;
            sku.status = SkuStatus.Archived; // Challenge successful, SKU is archived
            sku.veracityScore = (sku.veracityScore < protocolParameters["veracityChangeOnChallenge"]) ? 0 : sku.veracityScore.sub(protocolParameters["veracityChangeOnChallenge"]);
            authorWisdomPoints[challenge.challenger] = authorWisdomPoints[challenge.challenger].add(protocolParameters["wisdomPointsForSuccessfulChallenge"]);
            emit WisdomPointsUpdated(challenge.challenger, authorWisdomPoints[challenge.challenger]);
        } else {
            outcome = ChallengeStatus.ResolvedFailure;
            sku.status = SkuStatus.Verified; // Challenge failed, revert SKU to verified
            sku.veracityScore = (sku.veracityScore.add(protocolParameters["veracityChangeOnChallenge"]) > 100) ? 100 : sku.veracityScore.add(protocolParameters["veracityChangeOnChallenge"]);
            // Challenger's stake is forfeited to the contract treasury
        }

        challenge.status = outcome;
        emit ChallengeResolved(_challengeId, challenge.skuId, outcome, challenge.votesForChallenge, challenge.votesAgainstChallenge);
    }

    // Function 16: reclaimChallengeStake(uint256 _challengeId)
    function reclaimChallengeStake(uint256 _challengeId) public whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challenger == address(0)) revert ("SyntheticaMinerva: Challenge does not exist.");
        if (challenge.status != ChallengeStatus.ResolvedSuccess && challenge.status != ChallengeStatus.ResolvedFailure) revert ("SyntheticaMinerva: Challenge not yet resolved.");

        if (challenge.status == ChallengeStatus.ResolvedSuccess && msg.sender == challenge.challenger) {
            // Challenger wins, reclaim stake
            uint256 amountToRefund = challenge.stakeAmount;
            require(amountToRefund > 0, "SyntheticaMinerva: Stake already reclaimed or zero.");
            challenge.stakeAmount = 0; // Prevent double claim
            (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
            require(success, "SyntheticaMinerva: Failed to refund stake.");
            emit ChallengeStakeReclaimed(_challengeId, msg.sender, amountToRefund);
        } else {
            revert NotAllowedToReclaimStake(); // Challenger lost, or not the challenger
        }
    }

    // --- IV. Reputation, Metrics & Dynamic Evolution ---

    // Function 17: getAuthorWisdomPoints(address _author)
    function getAuthorWisdomPoints(address _author) public view returns (uint256) {
        return authorWisdomPoints[_author];
    }

    // Function 18: getKnowledgeUnitScores(uint256 _skuId)
    function getKnowledgeUnitScores(uint256 _skuId)
        public
        view
        returns (uint8 veracityScore, uint8 impactScore, uint8 obsolescenceTimer)
    {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();

        return (sku.veracityScore, sku.impactScore, sku.obsolescenceTimer);
    }

    // Function 19: triggerObsolescenceDecay(uint256 _skuId)
    function triggerObsolescenceDecay(uint256 _skuId) public whenNotPaused {
        KnowledgeUnit storage sku = knowledgeUnits[_skuId];
        if (sku.author == address(0)) revert InvalidSKUId();
        if (sku.status == SkuStatus.Archived || sku.status == SkuStatus.Obsolete) revert SKUNotInValidStatus();

        uint64 timeSinceLastInteraction = uint64(block.timestamp) - sku.lastInteractedAt;
        if (timeSinceLastInteraction < protocolParameters["obsolescenceDecayInterval"]) {
            revert ("SyntheticaMinerva: Not enough time has passed for decay.");
        }

        uint8 decayAmount = uint8(protocolParameters["obsolescenceDecayRate"]);
        if (sku.obsolescenceTimer > decayAmount) {
            sku.obsolescenceTimer = sku.obsolescenceTimer.sub(decayAmount);
        } else {
            sku.obsolescenceTimer = 0;
            sku.status = SkuStatus.Obsolete; // Mark as obsolete if timer hits zero
        }
        sku.lastInteractedAt = uint64(block.timestamp); // Reset last interacted to allow future decay

        emit ObsolescenceDecayTriggered(_skuId, sku.obsolescenceTimer);
        mintSyntheticaCredits(msg.sender, protocolParameters["decayTriggerCreditReward"]);
    }

    // --- V. Governance & Protocol Management ---

    // Function 20: setProtocolParameter(bytes32 _paramName, uint256 _value)
    function setProtocolParameter(bytes32 _paramName, uint256 _value) public onlyOwner whenNotPaused {
        // Basic check for allowed parameters
        if (
            _paramName != "minChallengeStake" &&
            _paramName != "challengeVotingDuration" &&
            _paramName != "grantFundingDuration" &&
            _paramName != "grantApprovalThresholdPercent" &&
            _paramName != "wisdomPointsForContribution" &&
            _paramName != "wisdomPointsForSuccessfulChallenge" &&
            _paramName != "wisdomPointsForSuccessfulReview" &&
            _paramName != "obsolescenceDecayRate" &&
            _paramName != "obsolescenceDecayInterval" &&
            _paramName != "creditMintRate" &&
            _paramName != "veracityChangeOnChallenge" &&
            _paramName != "impactChangeOnCite" &&
            _paramName != "impactChangeOnReview" &&
            _paramName != "crossReferenceImpactBoost" &&
            _paramName != "incentiveDistributionAmount" &&
            _paramName != "decayTriggerCreditReward"
        ) {
            revert ParameterDoesNotExist();
        }
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterSet(_paramName, _value);
    }

    // Function 21: appointCurator(address _newCurator)
    function appointCurator(address _newCurator) public onlyOwner whenNotPaused {
        require(_newCurator != address(0), "SyntheticaMinerva: Invalid address.");
        isCurator[_newCurator] = true;
        emit CuratorAppointed(_newCurator);
    }

    // Function 22: removeCurator(address _curator)
    function removeCurator(address _curator) public onlyOwner whenNotPaused {
        require(_curator != address(0), "SyntheticaMinerva: Invalid address.");
        isCurator[_curator] = false;
        emit CuratorRemoved(_curator);
    }

    // Function 25: withdrawTreasuryFunds(address _to, uint256 _amount)
    function withdrawTreasuryFunds(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_to != address(0), "SyntheticaMinerva: Invalid address.");
        require(address(this).balance >= _amount, "SyntheticaMinerva: Insufficient treasury balance.");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "SyntheticaMinerva: Failed to withdraw treasury funds.");
    }

    // --- VI. Advanced Concepts & Utility ---

    // Function 26: crossReferenceKnowledge(uint256 _sourceSkuId, uint256 _referencedSkuId, string _contextHash)
    function crossReferenceKnowledge(uint256 _sourceSkuId, uint256 _referencedSkuId, string calldata _contextHash)
        public
        whenNotPaused
    {
        KnowledgeUnit storage sourceSku = knowledgeUnits[_sourceSkuId];
        KnowledgeUnit storage referencedSku = knowledgeUnits[_referencedSkuId];

        if (sourceSku.author == address(0) || referencedSku.author == address(0)) revert InvalidSKUId();
        if (sourceSku.status == SkuStatus.Archived || sourceSku.status == SkuStatus.Obsolete) revert SKUNotInValidStatus();
        if (_sourceSkuId == _referencedSkuId) revert SelfReferenceNotAllowed();
        if (sourceSku.author != msg.sender) revert NotSKUAuthor(); // Only author can cross-reference their own SKU

        // Add _sourceSkuId to referencedBy array of _referencedSkuId if not already present
        bool alreadyReferenced = false;
        for (uint256 i = 0; i < referencedSku.referencedBy.length; i++) {
            if (referencedSku.referencedBy[i] == _sourceSkuId) {
                alreadyReferenced = true;
                break;
            }
        }
        if (!alreadyReferenced) {
            referencedSku.referencedBy.push(_sourceSkuId);
        }

        // Increase impact score of the referenced SKU
        referencedSku.impactScore = (referencedSku.impactScore.add(protocolParameters["crossReferenceImpactBoost"]) > 100) ? 100 : referencedSku.impactScore.add(protocolParameters["crossReferenceImpactBoost"]);
        referencedSku.lastInteractedAt = uint64(block.timestamp);

        emit KnowledgeUnitCrossReferenced(_sourceSkuId, _referencedSkuId, _contextHash);
        mintSyntheticaCredits(msg.sender, protocolParameters["creditMintRate"]);
    }

    // Function 29: distributeIncentives()
    // This function can be called by anyone, primarily to trigger a reward distribution.
    // In a full system, this would involve more complex logic, potentially based on a
    // snapshot of contributions over a period, or a portion of collected fees.
    // For this demonstration, it's a simple fixed credit distribution to the caller.
    function distributeIncentives() public whenNotPaused {
        mintSyntheticaCredits(msg.sender, protocolParameters["incentiveDistributionAmount"]);
        emit IncentivesDistributed(protocolParameters["incentiveDistributionAmount"]);
    }

    // Fallback and Receive functions to allow receiving ETH
    receive() external payable {}
    fallback() external payable {}
}
```