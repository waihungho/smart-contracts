This smart contract, `KnowledgeNexus`, presents a novel approach to decentralized knowledge management, blending concepts from DeSci (Decentralized Science), reputation systems, dynamic NFTs (Soulbound Tokens), and conceptual AI integration. It aims to create an on-chain, collaborative platform where knowledge fragments are submitted, peer-reviewed, interlinked, and their contributors rewarded based on quality and impact.

---

## KnowledgeNexus: Decentralized Knowledge Synthesis and Reputation Network

This contract establishes a novel on-chain system for knowledge management, focusing on verifiable claims, collaborative synthesis, and dynamic reputation. Users submit "Knowledge Fragments" (KFs), which are interlinked, peer-reviewed, and subject to a dynamic relevance decay. A multi-faceted reputation system incentivizes high-quality contributions and accurate validations. The system incorporates concepts such as Soulbound Tokens (SBTs) for reputation badges, delegated validation power, and a built-in dispute resolution mechanism. Future integrations with AI oracles for classification and advanced DAO governance are conceptualized within the design.

### Outline and Function Summary:

**I. Core Data Structures & Enums**
*   Enums for KF Status, Dispute Status, Dispute Outcome, Badge Types.
*   Structs for `KnowledgeFragment`, `ValidationLog`, `Dispute`.
*   Mappings to store KFs, their validation data, user reputations, disputes, etc.

**II. Knowledge Fragment Management (Core Logic)**
1.  `submitKnowledgeFragment(string memory _contentCID, string memory _metadataCID, uint256[] memory _parentKFs)`:
    Allows users to submit a new Knowledge Fragment, linking it to existing parent fragments.
2.  `getKnowledgeFragment(uint256 _kfId)`:
    Retrieves detailed information about a specific Knowledge Fragment.
3.  `updateKnowledgeFragmentMetadata(uint256 _kfId, string memory _newMetadataCID)`:
    Enables the owner of a KF to update its associated metadata (e.g., tags, abstract), but not the core content.
4.  `linkKnowledgeFragments(uint256 _kfIdA, uint256 _kfIdB)`:
    Establishes a conceptual directional link between two existing Knowledge Fragments, forming a knowledge graph.
5.  `requestDelistKnowledgeFragment(uint256 _kfId, string memory _reasonCID)`:
    Allows the owner or a sufficiently reputable user to request the delisting/archiving of a KF, potentially triggering a community vote or dispute.
6.  `confirmDelistKnowledgeFragment(uint256 _kfId)`:
    Admin/governance function to finalize the delisting process after a successful request or vote.

**III. Validation & Reputation System**
7.  `validateKnowledgeFragment(uint256 _kfId, uint8 _score, string memory _feedbackCID)`:
    Allows reputable users to review and score Knowledge Fragments, contributing to its overall validation score.
8.  `getKnowledgeFragmentValidationScore(uint256 _kfId)`:
    Returns the aggregated validation score and number of validations for a given KF.
9.  `getUserReputation(address _user)`:
    Retrieves the comprehensive, multi-faceted reputation score of a user, including submission, validation, and dispute resolution metrics.
10. `delegateValidationPower(address _delegatee)`:
    Enables a user to delegate their validation influence/power to another trusted address.
11. `undelegateValidationPower(address _delegatee)`:
    Revokes previously delegated validation power.
12. `decayKnowledgeFragmentRelevance(uint256 _kfId)`:
    A governance-controlled or automated function to reduce a KF's relevance score over time, reflecting outdated information.
13. `rewardValidator(address _validator, uint256 _amount)`:
    Admin/governance function to manually reward a validator, conceptually for high-quality contributions (in a real system, this would be automated and involve token transfers).
14. `mintReputationBadge(address _user, BadgeType _badgeType, string memory _evidenceCID)`:
    Mints a non-transferable (Soulbound Token-like) badge to a user, signifying specific achievements or expertise within the network.

**IV. Dispute Resolution Mechanism**
15. `initiateDispute(uint256 _kfId, string memory _reasonCID)`:
    Starts a formal dispute process against a Knowledge Fragment, challenging its validity or content.
16. `voteOnDispute(uint256 _disputeId, bool _outcome)`:
    Allows designated arbiters to cast their vote on an ongoing dispute.
17. `resolveDispute(uint256 _disputeId)`:
    Admin/governance function to finalize a dispute based on arbiter votes, updating the KF's status and relevant reputations.
18. `getDisputeDetails(uint256 _disputeId)`:
    Retrieves all information pertaining to a specific dispute.
19. `addArbiter(address _arbiterAddress)`:
    Adds an address to the list of official arbiters. Only owner can call.
20. `removeArbiter(address _arbiterAddress)`:
    Removes an address from the list of official arbiters. Only owner can call.

**V. Advanced Query & System Functions**
21. `queryLinkedKnowledge(uint256 _kfId, bool _isParent)`:
    Retrieves all KFs linked as parents or children to a specific Knowledge Fragment, enabling graph traversal.
22. `snapshotUserReputation(address _user)`:
    Records and returns a timestamped snapshot of a user's current reputation, useful for off-chain analysis or reward calculations.
23. `setAIOracleAddress(address _oracleAddress)`:
    Sets the address of a trusted AI oracle contract, which could conceptually provide automated classification or summarization suggestions.
24. `requestAISuggestion(uint256 _kfId)`:
    Triggers a conceptual call to an external AI oracle for processing a KF (e.g., for initial classification or anomaly detection).

**VI. Governance & Emergency**
25. `proposeProtocolUpgrade(string memory _newProtocolCID)`:
    Placeholder for a decentralized governance mechanism, allowing proposals for protocol upgrades to be recorded on-chain.
26. `voteOnProtocolUpgrade(uint256 _proposalId, bool _vote)`:
    Placeholder for voting on protocol upgrade proposals.
27. `setGovernanceAddress(address _newGovernanceAddress)`:
    Allows the current owner/governance to transfer control to a new address, typically a DAO contract.
28. `rescueERC20(address _tokenAddress, uint256 _amount)`:
    Standard emergency function to recover accidentally sent ERC20 tokens to the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For potentially safer math operations, though overflow checks are default in 0.8.0+

/*
 *   KnowledgeNexus: Decentralized Knowledge Synthesis and Reputation Network
 *   ======================================================================
 *
 *   This contract establishes a novel on-chain system for knowledge management,
 *   focusing on verifiable claims, collaborative synthesis, and dynamic reputation.
 *   Users submit "Knowledge Fragments" (KFs), which are interlinked, peer-reviewed,
 *   and subject to a dynamic relevance decay. A multi-faceted reputation system
 *   incentivizes high-quality contributions and accurate validations. The system
 *   incorporates concepts such as Soulbound Tokens (SBTs) for reputation badges,
 *   delegated validation power, and a built-in dispute resolution mechanism.
 *   Future integrations with AI oracles for classification and advanced DAO governance
 *   are conceptualized within the design.
 *
 *   Outline and Function Summary:
 *   -----------------------------
 *
 *   I. Core Data Structures & Enums
 *      - Enums for KF Status, Dispute Status, Dispute Outcome, Badge Types.
 *      - Structs for KnowledgeFragment, ValidationLog, Dispute.
 *      - Mappings to store KFs, their validation data, user reputations, disputes, etc.
 *
 *   II. Knowledge Fragment Management (Core Logic)
 *      1.  `submitKnowledgeFragment(string memory _contentCID, string memory _metadataCID, uint256[] memory _parentKFs)`:
 *          Allows users to submit a new Knowledge Fragment, linking it to existing parent fragments.
 *      2.  `getKnowledgeFragment(uint256 _kfId)`:
 *          Retrieves detailed information about a specific Knowledge Fragment.
 *      3.  `updateKnowledgeFragmentMetadata(uint256 _kfId, string memory _newMetadataCID)`:
 *          Enables the owner of a KF to update its associated metadata (e.g., tags, abstract), but not the core content.
 *      4.  `linkKnowledgeFragments(uint256 _kfIdA, uint256 _kfIdB)`:
 *          Establishes a conceptual directional link between two existing Knowledge Fragments, forming a knowledge graph.
 *      5.  `requestDelistKnowledgeFragment(uint256 _kfId, string memory _reasonCID)`:
 *          Allows the owner or a sufficiently reputable user to request the delisting/archiving of a KF, potentially triggering a community vote or dispute.
 *      6.  `confirmDelistKnowledgeFragment(uint256 _kfId)`:
 *          Admin/governance function to finalize the delisting process after a successful request or vote.
 *
 *   III. Validation & Reputation System
 *      7.  `validateKnowledgeFragment(uint256 _kfId, uint8 _score, string memory _feedbackCID)`:
 *          Allows reputable users to review and score Knowledge Fragments, contributing to its overall validation score.
 *      8.  `getKnowledgeFragmentValidationScore(uint256 _kfId)`:
 *          Returns the aggregated validation score and number of validations for a given KF.
 *      9.  `getUserReputation(address _user)`:
 *          Retrieves the comprehensive, multi-faceted reputation score of a user, including submission, validation, and dispute resolution metrics.
 *      10. `delegateValidationPower(address _delegatee)`:
 *          Enables a user to delegate their validation influence/power to another trusted address.
 *      11. `undelegateValidationPower(address _delegatee)`:
 *          Revokes previously delegated validation power.
 *      12. `decayKnowledgeFragmentRelevance(uint256 _kfId)`:
 *          A governance-controlled or automated function to reduce a KF's relevance score over time, reflecting outdated information.
 *      13. `rewardValidator(address _validator, uint256 _amount)`:
 *          Admin/governance function to manually reward a validator, conceptually for high-quality contributions (in a real system, this would be automated).
 *      14. `mintReputationBadge(address _user, BadgeType _badgeType, string memory _evidenceCID)`:
 *          Mints a non-transferable (Soulbound Token-like) badge to a user, signifying specific achievements or expertise within the network.
 *
 *   IV. Dispute Resolution Mechanism
 *      15. `initiateDispute(uint256 _kfId, string memory _reasonCID)`:
 *          Starts a formal dispute process against a Knowledge Fragment, challenging its validity or content.
 *      16. `voteOnDispute(uint256 _disputeId, bool _outcome)`:
 *          Allows designated arbiters to cast their vote on an ongoing dispute.
 *      17. `resolveDispute(uint256 _disputeId)`:
 *          Admin/governance function to finalize a dispute based on arbiter votes, updating the KF's status and relevant reputations.
 *      18. `getDisputeDetails(uint256 _disputeId)`:
 *          Retrieves all information pertaining to a specific dispute.
 *      19. `addArbiter(address _arbiterAddress)`:
 *          Adds an address to the list of official arbiters. Only owner can call.
 *      20. `removeArbiter(address _arbiterAddress)`:
 *          Removes an address from the list of official arbiters. Only owner can call.
 *
 *   V. Advanced Query & System Functions
 *      21. `queryLinkedKnowledge(uint256 _kfId, bool _isParent)`:
 *          Retrieves all KFs linked as parents or children to a specific Knowledge Fragment, enabling graph traversal.
 *      22. `snapshotUserReputation(address _user)`:
 *          Records and returns a timestamped snapshot of a user's current reputation, useful for off-chain analysis or reward calculations.
 *      23. `setAIOracleAddress(address _oracleAddress)`:
 *          Sets the address of a trusted AI oracle contract, which could conceptually provide automated classification or summarization suggestions.
 *      24. `requestAISuggestion(uint256 _kfId)`:
 *          Triggers a conceptual call to an external AI oracle for processing a KF (e.g., for initial classification or anomaly detection).
 *
 *   VI. Governance & Emergency
 *      25. `proposeProtocolUpgrade(string memory _newProtocolCID)`:
 *          Placeholder for a decentralized governance mechanism, allowing proposals for protocol upgrades to be recorded on-chain.
 *      26. `voteOnProtocolUpgrade(uint256 _proposalId, bool _vote)`:
 *          Placeholder for voting on protocol upgrade proposals.
 *      27. `setGovernanceAddress(address _newGovernanceAddress)`:
 *          Allows the current owner/governance to transfer control to a new address, typically a DAO contract.
 *      28. `rescueERC20(address _tokenAddress, uint256 _amount)`:
 *          Standard emergency function to recover accidentally sent ERC20 tokens to the contract.
 */

// Custom error definitions for clarity and gas efficiency
error NotKFOwner();
error InvalidKFId();
error InvalidScore();
error AlreadyValidated();
error InvalidDelegatee();
error NotDelegated();
error KFNotPending();
error KFAlreadyDisputed();
error DisputeNotFound();
error NotArbiter();
error DisputeAlreadyResolved();
error NoOngoingProposal();
error ProposalAlreadyVoted();
error InvalidBadgeType();
error BadgeAlreadyMinted();
error SelfLinkNotAllowed();
error LinkAlreadyExists();
error AlreadyDelisted();
error NotDelistedRequested(); // Not currently used, but good to keep if future logic needs it.

contract KnowledgeNexus is Ownable, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // While 0.8.0+ has default overflow checks, SafeMath is used for clarity.

    // --- Enums ---
    enum KFStatus {
        Pending,        // Newly submitted, awaiting validation
        Validated,      // Reviewed and deemed valid
        Disputed,       // Currently under dispute
        Archived        // Delisted, no longer actively shown/indexed
    }

    enum DisputeStatus {
        Open,           // Dispute initiated, awaiting arbiter selection
        Voting,         // Arbiters are voting
        Resolved,       // Dispute concluded
        Rejected        // Dispute rejected (e.g., frivolous)
    }

    enum DisputeOutcome {
        NotApplicable,  // Default, or before resolution
        Upheld,         // Challenger's claim upheld (KF deemed invalid/needs change)
        Overturned      // Challenger's claim overturned (KF deemed valid)
    }

    enum BadgeType {
        ValidatorMaster,        // For consistently high-quality validations
        KnowledgeSynthesizer,   // For submitting highly linked/cited KFs
        DisputeResolver,        // For consistent fair dispute resolutions
        EarlyContributor        // For contributing in early stages
    }

    // --- Structs ---
    struct KnowledgeFragment {
        uint256 kfId;
        address owner;
        string contentCID;      // IPFS hash of the core knowledge content
        string metadataCID;     // IPFS hash of structured metadata (title, abstract, tags, etc.)
        uint256[] parentKFs;    // IDs of KFs this fragment builds upon
        uint256[] childKFs;     // IDs of KFs that build upon this fragment
        uint256 submittedAt;
        uint256 relevanceScore; // Dynamic score, could decay over time
        KFStatus status;
        // Aggregated validation data stored separately to allow dynamic updates
    }

    // ValidationLog struct is illustrative, individual logs are not stored on-chain
    // struct ValidationLog {
    //     address validator;
    //     uint256 kfId;
    //     uint8 score;            // e.g., 1-5, 5 being highest quality
    //     string feedbackCID;     // IPFS hash of validator's feedback
    //     uint256 validatedAt;
    // }

    struct Dispute {
        uint256 disputeId;
        uint256 kfId;
        address challenger;
        string reasonCID;       // IPFS hash of the reason for dispute
        address[] arbiters;     // Addresses of arbiters for this specific dispute
        mapping(address => bool) hasVoted; // Tracks if an arbiter has voted
        // mapping(address => bool) arbiterVote; // True for uphold, false for overturn (not strictly needed, can derive from votes)
        uint256 votesForUphold;
        uint256 votesForOverturn;
        DisputeStatus status;
        DisputeOutcome outcome;
        uint256 initiatedAt;
        uint256 resolvedAt;
    }

    // User profile data (implicitly managed via mappings for reputation)
    struct UserReputation {
        uint256 submissionRep;  // Based on validated KFs submitted
        uint256 validationRep;  // Based on accuracy/volume of validations
        uint256 disputeRep;     // Based on fair and correct dispute resolutions
        uint256 lastActivity;
    }

    // --- State Variables ---
    Counters.Counter private _kfIds;
    Counters.Counter private _disputeIds;
    Counters.Counter private _proposalIds; // For protocol upgrades

    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;

    // Validation data: kfId -> (total score, validation count)
    mapping(uint256 => uint256) public kfTotalValidationScore;
    mapping(uint256 => uint256) public kfValidationCount;
    // To prevent double validation by same user on a given KF
    mapping(uint256 => mapping(address => bool)) public hasValidated;

    // User reputation scores
    mapping(address => UserReputation) public userReputations;
    // Delegation of validation power: delegator => delegatee => isDelegated
    mapping(address => mapping(address => bool)) public delegatedValidationPower;

    // Dispute management
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => uint256) public kfToDisputeId; // KF ID to active dispute ID
    address[] public arbiters; // Global list of addresses qualified to be arbiters (managed by governance)

    // Reputation Badges (SBT-like)
    mapping(address => mapping(BadgeType => bool)) public hasBadge;
    uint256 public nextBadgeTokenId; // For ERC721 token IDs

    // AI Oracle integration (conceptual)
    address public aiOracleAddress;

    // Protocol Upgrade Proposal
    struct ProtocolUpgradeProposal {
        uint256 proposalId;
        string newProtocolCID;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool active;
        uint256 createdAt;
    }
    mapping(uint256 => ProtocolUpgradeProposal) public protocolUpgradeProposals;
    uint256 public currentActiveProposalId; // Tracks the currently active proposal (simplified: only one at a time)

    // --- Events ---
    event KnowledgeFragmentSubmitted(uint256 indexed kfId, address indexed owner, string contentCID, string metadataCID, uint256 submittedAt);
    event KnowledgeFragmentMetadataUpdated(uint256 indexed kfId, string newMetadataCID);
    event KnowledgeFragmentsLinked(uint256 indexed kfIdA, uint256 indexed kfIdB);
    event KnowledgeFragmentValidated(uint256 indexed kfId, address indexed validator, uint8 score, uint256 newAvgScore);
    event KnowledgeFragmentDelistedRequested(uint256 indexed kfId, address indexed requester, string reasonCID);
    event KnowledgeFragmentDelistedConfirmed(uint256 indexed kfId);

    event ValidationPowerDelegated(address indexed delegator, address indexed delegatee);
    event ValidationPowerUndelegated(address indexed delegator, address indexed delegatee);
    event ReputationBadgeMinted(address indexed user, BadgeType indexed badgeType, uint256 indexed tokenId);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed kfId, address indexed challenger, string reasonCID);
    event DisputeVoted(uint256 indexed disputeId, address indexed arbiter, bool vote);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed kfId, DisputeOutcome outcome);
    event ArbiterAdded(address indexed arbiterAddress);
    event ArbiterRemoved(address indexed arbiterAddress);


    event AIOracleAddressSet(address indexed newAddress);
    event AIRequestTriggered(uint256 indexed kfId, address indexed requester);

    event ProtocolUpgradeProposed(uint256 indexed proposalId, string newProtocolCID);
    event ProtocolUpgradeVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);
    event ValidatorRewarded(address indexed validator, uint256 amount);


    // --- Constructor ---
    /// @param _name Name of the ERC721 token (for badges).
    /// @param _symbol Symbol of the ERC721 token (for badges).
    constructor(string memory _name, string memory _symbol) Ownable(msg.sender) ERC721(_name, _symbol) {
        nextBadgeTokenId = 1;
        // The deployer is initially added as an arbiter to allow dispute setup.
        arbiters.push(msg.sender);
        emit ArbiterAdded(msg.sender);
    }

    // --- Modifiers ---
    /// @dev Throws if caller is not the owner of the specific Knowledge Fragment.
    modifier onlyKFOwner(uint256 _kfId) {
        if (knowledgeFragments[_kfId].owner != msg.sender) revert NotKFOwner();
        _;
    }

    /// @dev Throws if caller is not an approved arbiter.
    modifier onlyArbiter() {
        bool isAnArbiter = false;
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (arbiters[i] == msg.sender) {
                isAnArbiter = true;
                break;
            }
        }
        if (!isAnArbiter) revert NotArbiter();
        _;
    }

    // --- Knowledge Fragment Management ---

    /// @notice Allows users to submit a new Knowledge Fragment, linking it to existing parent fragments.
    /// @param _contentCID IPFS hash of the core knowledge content.
    /// @param _metadataCID IPFS hash of structured metadata (title, abstract, tags, etc.).
    /// @param _parentKFs Array of KF IDs this new fragment builds upon.
    function submitKnowledgeFragment(
        string memory _contentCID,
        string memory _metadataCID,
        uint256[] memory _parentKFs
    ) public {
        _kfIds.increment();
        uint256 newId = _kfIds.current();

        KnowledgeFragment storage newKF = knowledgeFragments[newId];
        newKF.kfId = newId;
        newKF.owner = msg.sender;
        newKF.contentCID = _contentCID;
        newKF.metadataCID = _metadataCID;
        newKF.submittedAt = block.timestamp;
        newKF.relevanceScore = 100; // Initial relevance
        newKF.status = KFStatus.Pending;

        // Link to parent KFs
        for (uint256 i = 0; i < _parentKFs.length; i++) {
            uint256 parentId = _parentKFs[i];
            if (knowledgeFragments[parentId].owner == address(0)) revert InvalidKFId(); // Parent must exist
            if (parentId == newId) revert SelfLinkNotAllowed(); // Prevent linking to self
            newKF.parentKFs.push(parentId);
            knowledgeFragments[parentId].childKFs.push(newId); // Add new KF as child to parents
        }

        userReputations[msg.sender].submissionRep = userReputations[msg.sender].submissionRep.add(1);
        userReputations[msg.sender].lastActivity = block.timestamp;

        emit KnowledgeFragmentSubmitted(newId, msg.sender, _contentCID, _metadataCID, block.timestamp);
    }

    /// @notice Retrieves detailed information about a specific Knowledge Fragment.
    /// @param _kfId The ID of the Knowledge Fragment.
    /// @return kfId, owner, contentCID, metadataCID, parentKFs, childKFs, submittedAt, relevanceScore, status.
    function getKnowledgeFragment(uint256 _kfId)
        public
        view
        returns (
            uint256 kfId,
            address owner,
            string memory contentCID,
            string memory metadataCID,
            uint256[] memory parentKFs,
            uint256[] memory childKFs,
            uint256 submittedAt,
            uint256 relevanceScore,
            KFStatus status
        )
    {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId(); // Check if KF exists

        return (
            kf.kfId,
            kf.owner,
            kf.contentCID,
            kf.metadataCID,
            kf.parentKFs,
            kf.childKFs,
            kf.submittedAt,
            kf.relevanceScore,
            kf.status
        );
    }

    /// @notice Enables the owner of a KF to update its associated metadata (e.g., tags, abstract).
    /// @param _kfId The ID of the Knowledge Fragment.
    /// @param _newMetadataCID The new IPFS hash for the metadata.
    function updateKnowledgeFragmentMetadata(uint256 _kfId, string memory _newMetadataCID)
        public
        onlyKFOwner(_kfId)
    {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        kf.metadataCID = _newMetadataCID;
        userReputations[msg.sender].lastActivity = block.timestamp;
        emit KnowledgeFragmentMetadataUpdated(_kfId, _newMetadataCID);
    }

    /// @notice Establishes a conceptual directional link between two existing Knowledge Fragments.
    /// @param _kfIdA The ID of the source KF.
    /// @param _kfIdB The ID of the target KF (meaning _kfIdA builds upon _kfIdB, or cites _kfIdB).
    function linkKnowledgeFragments(uint256 _kfIdA, uint256 _kfIdB) public {
        KnowledgeFragment storage kfA = knowledgeFragments[_kfIdA];
        KnowledgeFragment storage kfB = knowledgeFragments[_kfIdB];

        if (kfA.owner == address(0) || kfB.owner == address(0)) revert InvalidKFId(); // Both KFs must exist
        if (_kfIdA == _kfIdB) revert SelfLinkNotAllowed();

        // Check if the link already exists (from A to B)
        for (uint256 i = 0; i < kfA.childKFs.length; i++) {
            if (kfA.childKFs[i] == _kfIdB) revert LinkAlreadyExists();
        }

        kfA.childKFs.push(_kfIdB); // KF A now has KF B as a child (meaning KF A refers to/builds on KF B)
        kfB.parentKFs.push(_kfIdA); // KF B now has KF A as a parent (meaning KF A refers to/builds on KF B)

        userReputations[msg.sender].lastActivity = block.timestamp;
        emit KnowledgeFragmentsLinked(_kfIdA, _kfIdB);
    }

    /// @notice Allows the owner or a sufficiently reputable user to request the delisting/archiving of a KF.
    /// @dev This function only *requests* delisting. Actual delisting might require governance approval or a dispute process.
    ///      For simplicity, `confirmDelistKnowledgeFragment` can be called by `owner()` directly.
    /// @param _kfId The ID of the Knowledge Fragment to request delisting.
    /// @param _reasonCID IPFS hash of the reason for requesting delisting.
    function requestDelistKnowledgeFragment(uint256 _kfId, string memory _reasonCID) public {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();
        if (kf.status == KFStatus.Archived) revert AlreadyDelisted();

        // Optional: require reputation for non-owners to prevent spamming delist requests
        // require(msg.sender == kf.owner || userReputations[msg.sender].disputeRep >= MIN_DELIST_REP, "Insufficient reputation to request delist");
        
        userReputations[msg.sender].lastActivity = block.timestamp;
        emit KnowledgeFragmentDelistedRequested(_kfId, msg.sender, _reasonCID);
    }

    /// @notice Admin/governance function to finalize the delisting process after a successful request or vote.
    /// @dev This function can be called by the contract owner directly. In a full DAO, it would be part of a proposal execution.
    /// @param _kfId The ID of the Knowledge Fragment to delist.
    function confirmDelistKnowledgeFragment(uint256 _kfId) public onlyOwner {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();
        if (kf.status == KFStatus.Archived) revert AlreadyDelisted();
        
        kf.status = KFStatus.Archived;
        emit KnowledgeFragmentDelistedConfirmed(_kfId);
    }

    // --- Validation & Reputation System ---

    /// @notice Allows reputable users to review and score Knowledge Fragments.
    /// @param _kfId The ID of the Knowledge Fragment to validate.
    /// @param _score The score given (e.g., 1-5, 5 being highest quality).
    /// @param _feedbackCID IPFS hash of validator's detailed feedback.
    function validateKnowledgeFragment(uint256 _kfId, uint8 _score, string memory _feedbackCID) public {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();
        if (kf.status != KFStatus.Pending) revert KFNotPending(); // Only pending KFs can be validated
        if (msg.sender == kf.owner) revert("Cannot validate your own KF"); // Prevent self-validation
        if (_score == 0 || _score > 5) revert InvalidScore();
        if (hasValidated[_kfId][msg.sender]) revert AlreadyValidated();

        // Check if validator's power is delegated from someone else
        address actualValidator = msg.sender;
        // Simplified check: if someone delegated power to msg.sender, we don't apply it here
        // A more complex system would check `delegatedValidationPower[delegator][msg.sender]`
        // and adjust scoring weight based on combined power. For now, it's direct validation.

        kfTotalValidationScore[_kfId] = kfTotalValidationScore[_kfId].add(_score);
        kfValidationCount[_kfId] = kfValidationCount[_kfId].add(1);
        hasValidated[_kfId][actualValidator] = true;

        // Update validator's reputation based on their direct validation
        userReputations[actualValidator].validationRep = userReputations[actualValidator].validationRep.add(_score);
        userReputations[actualValidator].lastActivity = block.timestamp;

        uint256 currentAvgScore = kfTotalValidationScore[_kfId].div(kfValidationCount[_kfId]);

        // A simple rule to move from Pending to Validated:
        // Requires at least 3 validations and an average score of 3 or higher.
        if (kfValidationCount[_kfId] >= 3 && currentAvgScore >= 3) {
            kf.status = KFStatus.Validated;
            // Optionally, increase KF owner's submissionRep when their KF is successfully validated
            userReputations[kf.owner].submissionRep = userReputations[kf.owner].submissionRep.add(5); // Arbitrary value
        }

        emit KnowledgeFragmentValidated(_kfId, actualValidator, _score, currentAvgScore);
    }

    /// @notice Returns the aggregated validation score and number of validations for a given KF.
    /// @param _kfId The ID of the Knowledge Fragment.
    /// @return totalScore The sum of all validation scores.
    /// @return validationCount The number of validations received.
    function getKnowledgeFragmentValidationScore(uint256 _kfId)
        public
        view
        returns (uint256 totalScore, uint256 validationCount)
    {
        if (knowledgeFragments[_kfId].owner == address(0)) revert InvalidKFId();
        return (kfTotalValidationScore[_kfId], kfValidationCount[_kfId]);
    }

    /// @notice Retrieves the comprehensive, multi-faceted reputation score of a user.
    /// @param _user The address of the user.
    /// @return submissionRep, validationRep, disputeRep, lastActivity.
    function getUserReputation(address _user)
        public
        view
        returns (uint256 submissionRep, uint256 validationRep, uint256 disputeRep, uint256 lastActivity)
    {
        UserReputation storage rep = userReputations[_user];
        return (rep.submissionRep, rep.validationRep, rep.disputeRep, rep.lastActivity);
    }

    /// @notice Enables a user to delegate their validation influence/power to another trusted address.
    /// @dev This doesn't transfer tokens, but conceptually allows the delegatee to act with some of the delegator's "power".
    /// @param _delegatee The address to whom validation power is delegated.
    function delegateValidationPower(address _delegatee) public {
        if (_delegatee == address(0) || _delegatee == msg.sender) revert InvalidDelegatee();
        delegatedValidationPower[msg.sender][_delegatee] = true;
        userReputations[msg.sender].lastActivity = block.timestamp;
        emit ValidationPowerDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes previously delegated validation power.
    /// @param _delegatee The address from whom validation power is undelegated.
    function undelegateValidationPower(address _delegatee) public {
        if (!delegatedValidationPower[msg.sender][_delegatee]) revert NotDelegated();
        delete delegatedValidationPower[msg.sender][_delegatee];
        userReputations[msg.sender].lastActivity = block.timestamp;
        emit ValidationPowerUndelegated(msg.sender, _delegatee);
    }

    /// @notice A governance-controlled or automated function to reduce a KF's relevance score over time.
    /// @dev This simulates a time-decaying relevance, which in a real system could be triggered by an oracle or a timed function.
    /// @param _kfId The ID of the Knowledge Fragment.
    function decayKnowledgeFragmentRelevance(uint256 _kfId) public onlyOwner {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();

        // Simple decay: reduce by 10% of current relevance score, ensuring it doesn't go below zero.
        uint256 decayAmount = kf.relevanceScore.div(10); // 10% decay
        if (decayAmount == 0 && kf.relevanceScore > 0) decayAmount = 1; // Ensure at least 1 point decay if score > 0

        kf.relevanceScore = kf.relevanceScore.sub(decayAmount);
        // Optional: if relevance drops too low, automatically archive or flag for re-evaluation
        // if (kf.relevanceScore < MIN_RELEVANCE_THRESHOLD && kf.status != KFStatus.Archived) {
        //     kf.status = KFStatus.Archived; // Or set to a new "Outdated" status
        // }
    }

    /// @notice Admin/governance function to manually reward a validator.
    /// @dev This function is conceptual. In a real system, _amount would be in a specific ERC20 token,
    ///      and transfers would occur here. For now, it's a signaling event.
    /// @param _validator The address of the validator to reward.
    /// @param _amount The amount of reward (conceptual, as no native token defined in this contract for rewards).
    function rewardValidator(address _validator, uint256 _amount) public onlyOwner {
        // Example of what would happen if a reward token existed:
        // IERC20(REWARD_TOKEN_ADDRESS).transfer(_validator, _amount);
        userReputations[_validator].lastActivity = block.timestamp;
        emit ValidatorRewarded(_validator, _amount);
    }

    /// @notice Mints a non-transferable (Soulbound Token-like) badge to a user.
    /// @dev These badges are ERC721 but are explicitly non-transferable by overriding `transferFrom`.
    /// @param _user The address to whom the badge is minted.
    /// @param _badgeType The type of badge to mint.
    /// @param _evidenceCID IPFS hash linking to evidence/criteria for the badge (used as token URI).
    function mintReputationBadge(address _user, BadgeType _badgeType, string memory _evidenceCID) public onlyOwner {
        if (_user == address(0)) revert InvalidDelegatee(); // Reusing error for null address
        if (hasBadge[_user][_badgeType]) revert BadgeAlreadyMinted();

        uint256 newTokenId = nextBadgeTokenId;
        _safeMint(_user, newTokenId);
        _setTokenURI(newTokenId, _evidenceCID); // Use evidence CID as token URI for badge details

        hasBadge[_user][_badgeType] = true;
        nextBadgeTokenId++;

        emit ReputationBadgeMinted(_user, _badgeType, newTokenId);
    }

    // Overrides from ERC721 to make tokens non-transferable (Soulbound)
    function transferFrom(address, address, uint256) public pure override {
        revert("Badges are non-transferable (Soulbound)");
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert("Badges are non-transferable (Soulbound)");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert("Badges are non-transferable (Soulbound)");
    }


    // --- Dispute Resolution Mechanism ---

    /// @notice Initiates a formal dispute process against a Knowledge Fragment.
    /// @param _kfId The ID of the Knowledge Fragment to dispute.
    /// @param _reasonCID IPFS hash of the reason for dispute.
    function initiateDispute(uint256 _kfId, string memory _reasonCID) public {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();
        if (kf.status == KFStatus.Disputed) revert KFAlreadyDisputed();
        if (arbiters.length == 0) revert("No arbiters available for dispute resolution."); // Must have arbiters set up

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.disputeId = newDisputeId;
        newDispute.kfId = _kfId;
        newDispute.challenger = msg.sender;
        newDispute.reasonCID = _reasonCID;
        newDispute.status = DisputeStatus.Open;
        newDispute.initiatedAt = block.timestamp;
        newDispute.outcome = DisputeOutcome.NotApplicable;

        kf.status = KFStatus.Disputed;
        kfToDisputeId[_kfId] = newDisputeId;

        // Assign all current global arbiters to this new dispute.
        // In a more complex system, a subset might be randomly selected or based on staked value.
        newDispute.arbiters = arbiters;

        userReputations[msg.sender].lastActivity = block.timestamp;
        emit DisputeInitiated(newDisputeId, _kfId, msg.sender, _reasonCID);
    }

    /// @notice Allows designated arbiters to cast their vote on an ongoing dispute.
    /// @param _disputeId The ID of the dispute.
    /// @param _outcome True if arbiter votes to uphold the challenger's claim (meaning KF is invalid/needs change), false to overturn (KF is valid).
    function voteOnDispute(uint256 _disputeId, bool _outcome) public onlyArbiter {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeId == 0) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.Open && dispute.status != DisputeStatus.Voting) revert DisputeAlreadyResolved();
        if (dispute.hasVoted[msg.sender]) revert ProposalAlreadyVoted(); // Reusing error for already voted

        bool isAssignedArbiter = false;
        for (uint256 i = 0; i < dispute.arbiters.length; i++) {
            if (dispute.arbiters[i] == msg.sender) {
                isAssignedArbiter = true;
                break;
            }
        }
        if (!isAssignedArbiter) revert NotArbiter(); // Ensure voter is assigned to this dispute

        dispute.hasVoted[msg.sender] = true;
        // dispute.arbiterVote[msg.sender] = _outcome; // Removed, not strictly necessary to store individual vote

        if (_outcome) {
            dispute.votesForUphold++;
        } else {
            dispute.votesForOverturn++;
        }

        dispute.status = DisputeStatus.Voting; // Set to voting after first vote is cast

        userReputations[msg.sender].lastActivity = block.timestamp;
        emit DisputeVoted(_disputeId, msg.sender, _outcome);
    }

    /// @notice Admin/governance function to finalize a dispute based on arbiter votes.
    /// @dev Requires a majority vote from assigned arbiters.
    /// @param _disputeId The ID of the dispute to resolve.
    function resolveDispute(uint256 _disputeId) public onlyOwner {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeId == 0) revert DisputeNotFound();
        if (dispute.status != DisputeStatus.Voting) revert DisputeAlreadyResolved(); // Must be in voting state

        // Ensure a minimum number of votes (e.g., quorum) or all assigned arbiters have voted
        uint256 totalVotesCast = dispute.votesForUphold.add(dispute.votesForOverturn);
        if (dispute.arbiters.length == 0 || totalVotesCast < dispute.arbiters.length) {
            // For simplicity, requiring all arbiters to vote. Can be changed to a quorum (e.g., majority of assigned arbiters).
            revert("Not all assigned arbiters have voted or quorum not met.");
        }
        
        KnowledgeFragment storage kf = knowledgeFragments[dispute.kfId];
        DisputeOutcome finalOutcome;
        if (dispute.votesForUphold > dispute.votesForOverturn) {
            finalOutcome = DisputeOutcome.Upheld; // Challenger's claim upheld: KF is deemed invalid/needs correction
            kf.status = KFStatus.Archived; // Mark KF as archived due to invalidity
            // Penalize KF owner for invalid submission
            userReputations[kf.owner].submissionRep = userReputations[kf.owner].submissionRep.sub(2); // Arbitrary penalty
        } else {
            finalOutcome = DisputeOutcome.Overturned; // Challenger's claim overturned: KF is deemed valid
            kf.status = KFStatus.Validated; // Revert KF to Validated status
            // Penalize challenger for frivolous dispute
            userReputations[dispute.challenger].disputeRep = userReputations[dispute.challenger].disputeRep.sub(1); // Arbitrary penalty
        }

        dispute.status = DisputeStatus.Resolved;
        dispute.outcome = finalOutcome;
        dispute.resolvedAt = block.timestamp;

        // Reward arbiters for participation (conceptual)
        for (uint256 i = 0; i < dispute.arbiters.length; i++) {
            // Can add more complex logic: reward based on correctness of their vote vs. final outcome
            userReputations[dispute.arbiters[i]].disputeRep = userReputations[dispute.arbiters[i]].disputeRep.add(1); // Flat reward for participation
        }

        emit DisputeResolved(_disputeId, dispute.kfId, finalOutcome);
    }

    /// @notice Retrieves all information pertaining to a specific dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return disputeId, kfId, challenger, reasonCID, arbiters, votesForUphold, votesForOverturn, status, outcome, initiatedAt, resolvedAt.
    function getDisputeDetails(uint256 _disputeId)
        public
        view
        returns (
            uint256 disputeId,
            uint256 kfId,
            address challenger,
            string memory reasonCID,
            address[] memory arbitersList,
            uint256 votesForUphold,
            uint256 votesForOverturn,
            DisputeStatus status,
            DisputeOutcome outcome,
            uint256 initiatedAt,
            uint256 resolvedAt
        )
    {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.disputeId == 0) revert DisputeNotFound();

        return (
            dispute.disputeId,
            dispute.kfId,
            dispute.challenger,
            dispute.reasonCID,
            dispute.arbiters,
            dispute.votesForUphold,
            dispute.votesForOverturn,
            dispute.status,
            dispute.outcome,
            dispute.initiatedAt,
            dispute.resolvedAt
        );
    }
    
    /// @notice Adds an address to the list of official arbiters. Only owner can call.
    /// @param _arbiterAddress The address to add as an arbiter.
    function addArbiter(address _arbiterAddress) public onlyOwner {
        // Prevent duplicates
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (arbiters[i] == _arbiterAddress) {
                return; // Already an arbiter, do nothing
            }
        }
        arbiters.push(_arbiterAddress);
        emit ArbiterAdded(_arbiterAddress);
    }

    /// @notice Removes an address from the list of official arbiters. Only owner can call.
    /// @param _arbiterAddress The address to remove from arbiters.
    function removeArbiter(address _arbiterAddress) public onlyOwner {
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (arbiters[i] == _arbiterAddress) {
                // Swap with last element and pop to maintain array contiguity
                arbiters[i] = arbiters[arbiters.length - 1];
                arbiters.pop();
                emit ArbiterRemoved(_arbiterAddress);
                return;
            }
        }
    }


    // --- Advanced Query & System Functions ---

    /// @notice Retrieves all KFs linked as parents or children to a specific Knowledge Fragment.
    /// @param _kfId The ID of the Knowledge Fragment.
    /// @param _isParent If true, return parent KFs; if false, return child KFs.
    /// @return An array of KF IDs.
    function queryLinkedKnowledge(uint256 _kfId, bool _isParent) public view returns (uint256[] memory) {
        KnowledgeFragment storage kf = knowledgeFragments[_kfId];
        if (kf.owner == address(0)) revert InvalidKFId();

        if (_isParent) {
            return kf.parentKFs;
        } else {
            return kf.childKFs;
        }
    }

    /// @notice Records and returns a timestamped snapshot of a user's current reputation.
    /// @dev Useful for off-chain analysis, leaderboards, or reward calculations at specific points in time.
    /// @param _user The address of the user.
    /// @return submissionRep, validationRep, disputeRep, timestamp of snapshot.
    function snapshotUserReputation(address _user)
        public
        view
        returns (uint256 submissionRep, uint256 validationRep, uint256 disputeRep, uint256 snapshotTimestamp)
    {
        UserReputation storage rep = userReputations[_user];
        return (rep.submissionRep, rep.validationRep, rep.disputeRep, block.timestamp);
    }

    /// @notice Sets the address of a trusted AI oracle contract. Only owner can call.
    /// @param _oracleAddress The address of the AI oracle contract.
    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        aiOracleAddress = _oracleAddress;
        emit AIOracleAddressSet(_oracleAddress);
    }

    /// @notice Triggers a conceptual call to an external AI oracle for processing a KF.
    /// @dev This function only emits an event; actual AI processing would happen off-chain via the oracle
    ///      listening to this event.
    /// @param _kfId The ID of the Knowledge Fragment to send to the AI oracle.
    function requestAISuggestion(uint256 _kfId) public {
        if (knowledgeFragments[_kfId].owner == address(0)) revert InvalidKFId();
        if (aiOracleAddress == address(0)) revert("AI Oracle not set");

        // In a real system, this could be:
        // IAIOracle(aiOracleAddress).requestProcessing(_kfId, msg.sender);
        // Where IAIOracle is an interface defining the oracle's function.
        userReputations[msg.sender].lastActivity = block.timestamp;
        emit AIRequestTriggered(_kfId, msg.sender);
    }

    // --- Governance & Emergency ---

    /// @notice Placeholder for a decentralized governance mechanism, allowing proposals for protocol upgrades.
    /// @dev This is a simplified proposal system. A full DAO would have more complex voting, timelocks, etc.
    ///      Only one proposal can be active at a time for simplicity.
    /// @param _newProtocolCID IPFS hash of the new protocol/contract code or specifications.
    function proposeProtocolUpgrade(string memory _newProtocolCID) public {
        if (currentActiveProposalId != 0 && protocolUpgradeProposals[currentActiveProposalId].active) {
            revert("Another proposal is already active.");
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        ProtocolUpgradeProposal storage proposal = protocolUpgradeProposals[newProposalId];
        proposal.proposalId = newProposalId;
        proposal.newProtocolCID = _newProtocolCID;
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.active = true;
        proposal.createdAt = block.timestamp;

        currentActiveProposalId = newProposalId;

        userReputations[msg.sender].lastActivity = block.timestamp;
        emit ProtocolUpgradeProposed(newProposalId, _newProtocolCID);
    }

    /// @notice Placeholder for voting on protocol upgrade proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for 'yes', false for 'no'.
    function voteOnProtocolUpgrade(uint256 _proposalId, bool _vote) public {
        ProtocolUpgradeProposal storage proposal = protocolUpgradeProposals[_proposalId];
        if (proposal.proposalId == 0 || !proposal.active) revert NoOngoingProposal();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        userReputations[msg.sender].lastActivity = block.timestamp;
        emit ProtocolUpgradeVoted(_proposalId, msg.sender, _vote);

        // TODO: Implement a voting period and outcome execution logic in a separate function
        // A real DAO would check a quorum and timelock after voting before execution.
    }

    /// @notice Allows the current owner/governance to transfer control to a new address.
    /// @dev Typically used to transfer ownership to a new contract, like a DAO.
    /// @param _newGovernanceAddress The address of the new owner/governance entity.
    function setGovernanceAddress(address _newGovernanceAddress) public onlyOwner {
        address previousOwner = owner();
        transferOwnership(_newGovernanceAddress); // Uses Ownable's transferOwnership
        emit GovernanceTransferred(previousOwner, _newGovernanceAddress);
    }

    /// @notice Standard emergency function to recover accidentally sent ERC20 tokens to the contract.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _amount The amount of tokens to rescue.
    function rescueERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), _amount);
    }

    // Required by ERC721URIStorage
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://"; // Base URI for badges, actual token URI is set per token.
    }
}

// Minimal IERC20 interface for rescueERC20
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

```