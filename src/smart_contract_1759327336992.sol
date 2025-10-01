This smart contract, **DecentralizedKnowledgeNexus**, aims to create a dynamic, self-organizing knowledge network on the blockchain. It combines elements of Decentralized Science (DeSci), dynamic NFTs (as "Knowledge Capsules" or SSKOs), an AI-inspired discovery engine (managed through intents and verifiable proposals), and a reputation system. The goal is to incentivize the creation, curation, and discovery of valuable knowledge, making it more accessible and robustly verified.

---

### **DecentralizedKnowledgeNexus: Outline and Function Summary**

**Contract Name:** `DecentralizedKnowledgeNexus`

**Core Concept:** A decentralized platform for creating, curating, and discovering interconnected knowledge objects (Self-Sovereign Knowledge Objects - SSKOs), driven by community incentives and a reputation system.

---

**Outline:**

1.  **Enums & Structs:** Defines the fundamental data structures for Knowledge Capsules (SSKOs), Discovery Quests, Discovery Links, Curator Reviews, and Research Bounties.
2.  **State Variables:** Global contract variables, counters, and mappings to store the state of the network.
3.  **Events:** Signals important actions and state changes for off-chain monitoring.
4.  **Modifiers:** Access control for various roles and conditions.
5.  **Constructor:** Initializes the contract owner.
6.  **SSKO (Self-Sovereign Knowledge Object) Management:** Functions to create, update, tag, and archive knowledge capsules, acting as dynamic NFTs.
7.  **Decentralized Curation & Reputation System:** Functions for curators to review SSKOs, manage their quality scores, and for users to build their `KnowledgeScore`.
8.  **Knowledge Discovery Engine:** Mechanism for users to initiate "quests" for knowledge connections, agents to propose links, and the community to validate them.
9.  **Research Bounties:** A decentralized funding and reward system for specific research questions or knowledge gaps.
10. **Utility & Administrative Functions:** General functions for querying data, managing roles, and contract administration.

---

**Function Summary:**

**I. SSKO (Self-Sovereign Knowledge Object) Management**
1.  `createSSKO(string memory _ipfsContentHash, string memory _title, string[] memory _tags)`: Mints a new Knowledge Capsule (SSKO) with initial content and tags. Assigns `sskoId`.
2.  `updateSSKOContentHash(uint256 _sskoId, string memory _newIpfsContentHash)`: Allows the creator to update the content of their SSKO, incrementing its version.
3.  `addSSKOTag(uint256 _sskoId, string memory _tag)`: Adds a new descriptive tag to an existing SSKO.
4.  `removeSSKOTag(uint256 _sskoId, string memory _tag)`: Removes an existing tag from an SSKO.
5.  `archiveSSKO(uint256 _sskoId)`: Marks an SSKO as archived, indicating it might be outdated or disproved. Only creator or admin.
6.  `submitSSKOForCuratorReview(uint256 _sskoId)`: Marks an SSKO as ready for quality assessment by curators.

**II. Decentralized Curation & Reputation System**
7.  `assignCuratorToSSKO(uint256 _sskoId, address _curator)`: Admin/DAO assigns a specific curator to review an SSKO.
8.  `submitCuratorReview(uint256 _sskoId, uint8 _qualityScore, string memory _reviewReasonHash)`: Assigned curator submits their assessment of an SSKO's quality.
9.  `disputeCuratorReview(uint256 _reviewId, string memory _disputeReasonHash)`: SSKO creator can dispute a review they disagree with, triggering a re-evaluation process (off-chain/DAO handled).
10. `updateUserKnowledgeScore(address _user, int256 _scoreChange)`: Internal function to adjust a user's `KnowledgeScore` based on their actions (creation, review, discovery).
11. `getKnowledgeScore(address _user)`: Retrieves a specific user's current `KnowledgeScore`.
12. `slashKnowledgeScore(address _user, uint256 _amount, string memory _reasonHash)`: Admin/DAO can reduce a user's `KnowledgeScore` for malicious or poor-quality contributions.

**III. Knowledge Discovery Engine**
13. `initiateDiscoveryQuest(string memory _intentPromptHash, uint256 _stakeAmount)`: User stakes tokens to define an intent (e.g., "find connections between X and Y") for the network to discover.
14. `submitDiscoveryProposal(uint256 _questId, uint256[] memory _sskoIdsInvolved, string memory _reasonHash)`: A "Discovery Agent" proposes a new link (connection) between multiple SSKOs, providing reasoning.
15. `voteOnDiscoveryProposal(uint256 _linkId, bool _isEthical, bool _isAccurate, bool _isRelevant)`: Community members vote on the validity, ethics, and relevance of a proposed knowledge link.
16. `finalizeDiscoveryProposal(uint256 _linkId)`: If a proposal receives enough positive votes, the link is officially added, and the proposer is rewarded.
17. `queryConnectedSSKOs(uint256 _sskoId)`: Returns all SSKO IDs directly linked to a given SSKO.
18. `querySSKOsByDiscoveryIntent(uint256 _questId)`: Returns SSKOs that were part of finalized discovery proposals for a given quest.

**IV. Research Bounties**
19. `proposeResearchBounty(string memory _title, string memory _descriptionHash, uint256 _rewardGoal)`: A community member proposes a bounty for addressing a specific knowledge gap or research question.
20. `fundResearchBounty(uint256 _bountyId) payable`: Users contribute funds to an active research bounty.
21. `submitBountySolution(uint256 _bountyId, uint256 _sskoId, string memory _explanationHash)`: A creator submits an SSKO as a proposed solution to an open bounty.
22. `voteOnBountySolution(uint256 _bountyId, uint256 _solutionId, bool _isSolution)`: Community members vote on which submitted solution best addresses the bounty.
23. `claimBountyReward(uint256 _bountyId)`: The winner(s) of a bounty (as determined by voting) can claim their share of the collected funds.

**V. Utility & Administrative Functions**
24. `withdrawStakedFundsFromDiscovery(uint256 _questId)`: Allows a user to withdraw their stake from an expired or cancelled discovery quest.
25. `grantKnowledgeScore(address _user, uint256 _amount)`: Admin function to manually grant `KnowledgeScore` (e.g., for initial contributors or special achievements).
26. `pauseContract()`: Admin function to pause all mutable operations in case of an emergency.
27. `unpauseContract()`: Admin function to resume operations.
28. `setGovernanceAddress(address _newGovAddress)`: Admin function to update the address of the DAO/governance contract.
29. `getTokenAddress()`: Returns the address of the ERC20 token used for staking and rewards. (Assumes a linked `KnowledgeToken` ERC20).
30. `getSSKOCreator(uint256 _sskoId)`: Returns the original creator of an SSKO.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// ERC-721 is not used directly as SSKOs are not always freely transferable.
// A custom implementation focusing on unique IDs and creator ownership is used.

/**
 * @title DecentralizedKnowledgeNexus
 * @dev A smart contract for a decentralized knowledge network.
 *      It enables creation, curation, and discovery of Self-Sovereign Knowledge Objects (SSKOs),
 *      managed by community reputation and incentive mechanisms.
 *
 * Outline:
 * 1. Enums & Structs: Defines core data structures for SSKOs, Discovery Quests, Discovery Links, Curator Reviews, and Research Bounties.
 * 2. State Variables: Global contract variables, counters, and mappings to store the network's state.
 * 3. Events: Signals important actions and state changes for off-chain monitoring.
 * 4. Modifiers: Access control for various roles and conditions.
 * 5. Constructor: Initializes the contract owner and the associated KnowledgeToken.
 * 6. SSKO (Self-Sovereign Knowledge Object) Management: Functions to create, update, tag, and archive knowledge capsules, acting as dynamic NFTs.
 * 7. Decentralized Curation & Reputation System: Functions for curators to review SSKOs, manage their quality scores, and for users to build their `KnowledgeScore`.
 * 8. Knowledge Discovery Engine: Mechanism for users to initiate "quests" for knowledge connections, agents to propose links, and the community to validate them.
 * 9. Research Bounties: A decentralized funding and reward system for specific research questions or knowledge gaps.
 * 10. Utility & Administrative Functions: General functions for querying data, managing roles, and contract administration.
 *
 * Function Summary:
 * I. SSKO (Self-Sovereign Knowledge Object) Management
 *  1. createSSKO(string memory _ipfsContentHash, string memory _title, string[] memory _tags): Mints a new Knowledge Capsule (SSKO).
 *  2. updateSSKOContentHash(uint256 _sskoId, string memory _newIpfsContentHash): Allows creator to update SSKO content.
 *  3. addSSKOTag(uint256 _sskoId, string memory _tag): Adds a descriptive tag to an SSKO.
 *  4. removeSSKOTag(uint256 _sskoId, string memory _tag): Removes a tag from an SSKO.
 *  5. archiveSSKO(uint256 _sskoId): Marks an SSKO as archived (outdated/disproved).
 *  6. submitSSKOForCuratorReview(uint256 _sskoId): Marks an SSKO for quality assessment.
 *
 * II. Decentralized Curation & Reputation System
 *  7. assignCuratorToSSKO(uint256 _sskoId, address _curator): Admin/DAO assigns a curator.
 *  8. submitCuratorReview(uint256 _sskoId, uint8 _qualityScore, string memory _reviewReasonHash): Curator submits review.
 *  9. disputeCuratorReview(uint256 _reviewId, string memory _disputeReasonHash): Creator disputes a review.
 * 10. updateUserKnowledgeScore(address _user, int256 _scoreChange): Internal score adjustment.
 * 11. getKnowledgeScore(address _user): Retrieves user's KnowledgeScore.
 * 12. slashKnowledgeScore(address _user, uint256 _amount, string memory _reasonHash): Admin/DAO reduces score for malicious activity.
 *
 * III. Knowledge Discovery Engine
 * 13. initiateDiscoveryQuest(string memory _intentPromptHash, uint256 _stakeAmount): User stakes tokens to define a discovery intent.
 * 14. submitDiscoveryProposal(uint256 _questId, uint256[] memory _sskoIdsInvolved, string memory _reasonHash): Agent proposes a link between SSKOs.
 * 15. voteOnDiscoveryProposal(uint256 _linkId, bool _isEthical, bool _isAccurate, bool _isRelevant): Community votes on proposed link.
 * 16. finalizeDiscoveryProposal(uint256 _linkId): Adds link if approved, rewards proposer.
 * 17. queryConnectedSSKOs(uint256 _sskoId): Returns SSKOs linked to a given SSKO.
 * 18. querySSKOsByDiscoveryIntent(uint256 _questId): Returns SSKOs relevant to a specific quest.
 *
 * IV. Research Bounties
 * 19. proposeResearchBounty(string memory _title, string memory _descriptionHash, uint256 _rewardGoal): Proposes a bounty for a knowledge gap.
 * 20. fundResearchBounty(uint256 _bountyId) payable: Users contribute funds to a bounty.
 * 21. submitBountySolution(uint256 _bountyId, uint256 _sskoId, string memory _explanationHash): Creator submits an SSKO as a bounty solution.
 * 22. voteOnBountySolution(uint256 _bountyId, uint256 _solutionId, bool _isSolution): Community votes on bounty solutions.
 * 23. claimBountyReward(uint256 _bountyId): Winner(s) claim bounty reward.
 *
 * V. Utility & Administrative Functions
 * 24. withdrawStakedFundsFromDiscovery(uint256 _questId): Allows stake withdrawal from expired/cancelled quests.
 * 25. grantKnowledgeScore(address _user, uint256 _amount): Admin manually grants KnowledgeScore.
 * 26. pauseContract(): Admin pauses contract operations.
 * 27. unpauseContract(): Admin resumes contract operations.
 * 28. setGovernanceAddress(address _newGovAddress): Admin sets governance contract address.
 * 29. getTokenAddress(): Returns the address of the KnowledgeToken.
 * 30. getSSKOCreator(uint256 _sskoId): Returns the creator of an SSKO.
 */
contract DecentralizedKnowledgeNexus is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 public immutable knowledgeToken; // ERC20 token for staking, rewards, and potentially governance

    // --- Enums and Structs ---

    enum ReviewStatus { Pending, Approved, Rejected, Disputed }
    enum BountyStatus { Open, Funding, Voting, Closed, Claimed }

    struct KnowledgeCapsule {
        uint256 sskoId;
        address creator;
        uint256 currentVersion;
        string ipfsContentHash; // IPFS hash of the actual knowledge content
        string title;
        uint256 creationTimestamp;
        uint256 lastUpdatedTimestamp;
        uint8 aggregatedQualityScore; // Average score from curator reviews (0-100)
        mapping(bytes32 => bool) tags; // Using bytes32 for efficiency
        bool submittedForReview;
        bool isArchived;
        address currentOwner; // Could be transferred later if not permanently soulbound
        uint256 curatorReviewId; // ID of the latest curator review
    }

    struct CuratorReview {
        uint256 reviewId;
        uint256 sskoId;
        address curator;
        uint8 qualityScore; // 0-100
        string reviewReasonHash; // IPFS hash of the detailed review
        uint256 reviewTimestamp;
        ReviewStatus status;
        address reviewerDisputing; // If review is disputed, who initiated it
    }

    struct DiscoveryQuest {
        uint256 questId;
        address initiator;
        string intentPromptHash; // IPFS hash of the natural language prompt for discovery
        uint256 stakedAmount; // Tokens staked by the initiator
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        bool isActive;
        bool hasFinalizedProposal; // If a proposal has been accepted for this quest
    }

    struct DiscoveryLink {
        uint256 linkId;
        uint256[] sskoIdsInvolved; // Can link multiple SSKOs
        address proposer;
        string proposalReasonHash; // IPFS hash of the reasoning for the link
        uint256 proposalTimestamp;
        uint256 questId; // Associated quest ID
        bool isValidated; // After community vote
        uint256 validationTimestamp;
        mapping(address => bool) hasVoted; // Tracks who has voted on this proposal
        uint256 positiveVotes;
        uint256 negativeVotes;
        uint256 ethicalVotes; // Votes on whether the link is ethical/responsible
        uint256 accurateVotes; // Votes on whether the link is factually accurate
        uint256 relevantVotes; // Votes on whether the link is relevant to the quest/network
    }

    struct ResearchBounty {
        uint256 bountyId;
        address proposer;
        string title;
        string descriptionHash; // IPFS hash of the bounty description
        uint256 rewardGoal;
        uint256 currentFunds;
        uint256 creationTimestamp;
        uint256 expirationTimestamp;
        BountyStatus status;
        uint256 winningSolutionId; // ID of the SSKO that won the bounty
        mapping(uint256 => address) submittedSolutions; // Solution SSKO ID => submitter address
        mapping(uint256 => uint256) solutionVotes; // Solution SSKO ID => votes for it
        uint256 totalSolutionVotes;
    }

    // --- State Variables ---

    Counters.Counter private _sskoIdCounter;
    Counters.Counter private _reviewIdCounter;
    Counters.Counter private _questIdCounter;
    Counters.Counter private _linkIdCounter;
    Counters.Counter private _bountyIdCounter;

    mapping(uint256 => KnowledgeCapsule) public sskos;
    mapping(uint256 => mapping(bytes32 => bool)) public sskoTags; // sskoId => tagHash => exists
    mapping(address => uint256) public userKnowledgeScore; // Reputation score for users
    mapping(uint256 => CuratorReview) public curatorReviews;

    mapping(uint256 => DiscoveryQuest) public discoveryQuests;
    mapping(uint256 => DiscoveryLink) public discoveryLinks;
    mapping(uint256 => uint256[]) public sskoToDiscoveryLinks; // sskoId => array of linkIds it's involved in

    mapping(uint256 => ResearchBounty) public researchBounties;

    address public governanceAddress; // Address of a DAO or multisig that handles specific admin tasks

    uint256 public constant DISCOVERY_QUEST_DURATION = 30 days; // Example duration
    uint252 public constant MIN_VALIDATION_VOTES = 5; // Minimum votes required to finalize a discovery link
    uint256 public constant BOUNTY_FUNDING_DURATION = 60 days;
    uint256 public constant BOUNTY_VOTING_DURATION = 14 days;
    uint256 public constant KNOWLEDGE_SCORE_REWARD_SSKO_CREATION = 10;
    uint256 public constant KNOWLEDGE_SCORE_REWARD_CURATOR_REVIEW = 5;
    uint256 public constant KNOWLEDGE_SCORE_REWARD_DISCOVERY_PROPOSAL = 20;

    // --- Events ---

    event SSKOCreated(uint256 indexed sskoId, address indexed creator, string ipfsContentHash, string title, uint256 timestamp);
    event SSKOUpdated(uint256 indexed sskoId, uint256 newVersion, string newIpfsContentHash, uint256 timestamp);
    event SSKOArchived(uint256 indexed sskoId, address indexed archiver, uint256 timestamp);
    event SSKOReviewed(uint256 indexed sskoId, uint256 indexed reviewId, address indexed curator, uint8 qualityScore, ReviewStatus status);
    event KnowledgeScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore);

    event DiscoveryQuestInitiated(uint256 indexed questId, address indexed initiator, string intentPromptHash, uint256 stakedAmount, uint256 expiration);
    event DiscoveryProposalSubmitted(uint256 indexed linkId, uint256 indexed questId, address indexed proposer, uint256[] sskoIdsInvolved);
    event DiscoveryProposalVoted(uint256 indexed linkId, address indexed voter, bool isEthical, bool isAccurate, bool isRelevant);
    event DiscoveryProposalFinalized(uint256 indexed linkId, uint256 indexed questId, address indexed proposer, uint256 rewardAmount);
    event StakedFundsWithdrawn(uint256 indexed questId, address indexed beneficiary, uint256 amount);

    event ResearchBountyProposed(uint256 indexed bountyId, address indexed proposer, string title, uint256 rewardGoal);
    event ResearchBountyFunded(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed sskoId, address indexed submitter);
    event BountySolutionVoted(uint256 indexed bountyId, uint256 indexed solutionId, address indexed voter);
    event BountyRewardClaimed(uint256 indexed bountyId, address indexed winner, uint256 amount);

    // --- Modifiers ---

    modifier onlySSKOCreator(uint256 _sskoId) {
        require(msg.sender == sskos[_sskoId].creator, "DKN: Not SSKO creator");
        _;
    }

    modifier onlySSKOCurrentOwner(uint256 _sskoId) {
        require(msg.sender == sskos[_sskoId].currentOwner, "DKN: Not SSKO current owner");
        _;
    }

    modifier onlyCurator(uint256 _reviewId) {
        require(msg.sender == curatorReviews[_reviewId].curator, "DKN: Not assigned curator");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "DKN: Caller is not governance address");
        _;
    }

    // --- Constructor ---

    constructor(address _knowledgeTokenAddress) Ownable(msg.sender) {
        require(_knowledgeTokenAddress != address(0), "DKN: Invalid token address");
        knowledgeToken = IERC20(_knowledgeTokenAddress);
        governanceAddress = msg.sender; // Initially, owner is governance
    }

    // --- I. SSKO (Self-Sovereign Knowledge Object) Management ---

    /**
     * @dev Mints a new Knowledge Capsule (SSKO).
     * @param _ipfsContentHash IPFS hash pointing to the knowledge content.
     * @param _title Title of the SSKO.
     * @param _tags Initial descriptive tags for the SSKO.
     * @return sskoId The ID of the newly created SSKO.
     */
    function createSSKO(string memory _ipfsContentHash, string memory _title, string[] memory _tags)
        external
        whenNotPaused
        returns (uint256 sskoId)
    {
        _sskoIdCounter.increment();
        sskoId = _sskoIdCounter.current();

        sskos[sskoId] = KnowledgeCapsule({
            sskoId: sskoId,
            creator: msg.sender,
            currentVersion: 1,
            ipfsContentHash: _ipfsContentHash,
            title: _title,
            creationTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            aggregatedQualityScore: 0,
            submittedForReview: false,
            isArchived: false,
            currentOwner: msg.sender,
            curatorReviewId: 0
        });

        for (uint256 i = 0; i < _tags.length; i++) {
            sskoTags[sskoId][keccak256(abi.encodePacked(_tags[i]))] = true;
        }

        _updateUserKnowledgeScore(msg.sender, int256(KNOWLEDGE_SCORE_REWARD_SSKO_CREATION));
        emit SSKOCreated(sskoId, msg.sender, _ipfsContentHash, _title, block.timestamp);
    }

    /**
     * @dev Allows the creator to update the content of their SSKO, incrementing its version.
     *      This marks the SSKO for potential re-review.
     * @param _sskoId The ID of the SSKO to update.
     * @param _newIpfsContentHash The new IPFS hash for the updated content.
     */
    function updateSSKOContentHash(uint256 _sskoId, string memory _newIpfsContentHash)
        external
        whenNotPaused
        onlySSKOCreator(_sskoId)
    {
        KnowledgeCapsule storage ssko = sskos[_sskoId];
        require(!ssko.isArchived, "DKN: Cannot update archived SSKO");

        ssko.currentVersion++;
        ssko.ipfsContentHash = _newIpfsContentHash;
        ssko.lastUpdatedTimestamp = block.timestamp;
        ssko.submittedForReview = false; // New content requires new review

        emit SSKOUpdated(_sskoId, ssko.currentVersion, _newIpfsContentHash, block.timestamp);
    }

    /**
     * @dev Adds a new descriptive tag to an existing SSKO.
     * @param _sskoId The ID of the SSKO.
     * @param _tag The tag to add.
     */
    function addSSKOTag(uint256 _sskoId, string memory _tag)
        external
        whenNotPaused
        onlySSKOCurrentOwner(_sskoId)
    {
        require(bytes(_tag).length > 0, "DKN: Tag cannot be empty");
        bytes32 tagHash = keccak256(abi.encodePacked(_tag));
        require(!sskoTags[_sskoId][tagHash], "DKN: Tag already exists");

        sskoTags[_sskoId][tagHash] = true;
        // Event for tag changes could be added if needed
    }

    /**
     * @dev Removes an existing tag from an SSKO.
     * @param _sskoId The ID of the SSKO.
     * @param _tag The tag to remove.
     */
    function removeSSKOTag(uint256 _sskoId, string memory _tag)
        external
        whenNotPaused
        onlySSKOCurrentOwner(_sskoId)
    {
        require(bytes(_tag).length > 0, "DKN: Tag cannot be empty");
        bytes32 tagHash = keccak256(abi.encodePacked(_tag));
        require(sskoTags[_sskoId][tagHash], "DKN: Tag does not exist");

        delete sskoTags[_sskoId][tagHash];
        // Event for tag changes could be added if needed
    }

    /**
     * @dev Marks an SSKO as archived, indicating it might be outdated or disproved.
     * @param _sskoId The ID of the SSKO to archive.
     */
    function archiveSSKO(uint256 _sskoId)
        external
        whenNotPaused
        onlySSKOCurrentOwner(_sskoId) // Or can be `onlyGovernance`
    {
        KnowledgeCapsule storage ssko = sskos[_sskoId];
        require(!ssko.isArchived, "DKN: SSKO is already archived");

        ssko.isArchived = true;
        emit SSKOArchived(_sskoId, msg.sender, block.timestamp);
    }

    /**
     * @dev Marks an SSKO as ready for quality assessment by curators.
     *      Only the current owner or creator can submit for review.
     * @param _sskoId The ID of the SSKO to submit for review.
     */
    function submitSSKOForCuratorReview(uint256 _sskoId)
        external
        whenNotPaused
        onlySSKOCurrentOwner(_sskoId)
    {
        KnowledgeCapsule storage ssko = sskos[_sskoId];
        require(!ssko.isArchived, "DKN: Archived SSKO cannot be reviewed");
        require(!ssko.submittedForReview, "DKN: SSKO already submitted for review");

        ssko.submittedForReview = true;
        // An event could be emitted here to notify potential curators or a DAO governance module
        // that a review is pending.
    }

    // --- II. Decentralized Curation & Reputation System ---

    /**
     * @dev Admin/Governance assigns a specific curator to review an SSKO.
     *      This implies an off-chain or DAO process for selecting qualified curators.
     * @param _sskoId The ID of the SSKO to be reviewed.
     * @param _curator The address of the assigned curator.
     * @return reviewId The ID of the newly created review task.
     */
    function assignCuratorToSSKO(uint256 _sskoId, address _curator)
        external
        whenNotPaused
        onlyGovernance
        returns (uint256 reviewId)
    {
        KnowledgeCapsule storage ssko = sskos[_sskoId];
        require(ssko.sskoId != 0, "DKN: SSKO does not exist");
        require(ssko.submittedForReview, "DKN: SSKO not submitted for review");
        require(_curator != address(0), "DKN: Invalid curator address");

        _reviewIdCounter.increment();
        reviewId = _reviewIdCounter.current();

        curatorReviews[reviewId] = CuratorReview({
            reviewId: reviewId,
            sskoId: _sskoId,
            curator: _curator,
            qualityScore: 0,
            reviewReasonHash: "",
            reviewTimestamp: 0,
            status: ReviewStatus.Pending,
            reviewerDisputing: address(0)
        });

        ssko.curatorReviewId = reviewId;
        // An event could be added to notify the curator
    }

    /**
     * @dev Assigned curator submits their assessment of an SSKO's quality.
     *      This updates the SSKO's aggregated quality score and impacts curator's reputation.
     * @param _sskoId The ID of the SSKO being reviewed.
     * @param _qualityScore The quality score (0-100) assigned by the curator.
     * @param _reviewReasonHash IPFS hash of the detailed reasoning for the score.
     */
    function submitCuratorReview(uint256 _sskoId, uint8 _qualityScore, string memory _reviewReasonHash)
        external
        whenNotPaused
    {
        KnowledgeCapsule storage ssko = sskos[_sskoId];
        require(ssko.sskoId != 0, "DKN: SSKO does not exist");
        require(ssko.curatorReviewId != 0, "DKN: No review assigned for this SSKO");

        CuratorReview storage review = curatorReviews[ssko.curatorReviewId];
        require(msg.sender == review.curator, "DKN: Not the assigned curator for this review");
        require(review.status == ReviewStatus.Pending, "DKN: Review already completed or disputed");
        require(_qualityScore <= 100, "DKN: Quality score must be 0-100");

        review.qualityScore = _qualityScore;
        review.reviewReasonHash = _reviewReasonHash;
        review.reviewTimestamp = block.timestamp;
        review.status = ReviewStatus.Approved; // Assuming it's approved by default, can be 'Completed'

        ssko.aggregatedQualityScore = _qualityScore; // For simplicity, direct assignment. Could be average.
        ssko.submittedForReview = false; // Review completed

        _updateUserKnowledgeScore(msg.sender, int256(KNOWLEDGE_SCORE_REWARD_CURATOR_REVIEW));
        _updateUserKnowledgeScore(ssko.creator, int256(_qualityScore / 10)); // Reward creator based on quality
        emit SSKOReviewed(_sskoId, review.reviewId, msg.sender, _qualityScore, ReviewStatus.Approved);
    }

    /**
     * @dev SSKO creator can dispute a negative review they disagree with.
     *      This triggers an off-chain or DAO re-evaluation process.
     * @param _reviewId The ID of the review being disputed.
     * @param _disputeReasonHash IPFS hash of the creator's reasons for dispute.
     */
    function disputeCuratorReview(uint256 _reviewId, string memory _disputeReasonHash)
        external
        whenNotPaused
    {
        CuratorReview storage review = curatorReviews[_reviewId];
        require(review.reviewId != 0, "DKN: Review does not exist");
        require(msg.sender == sskos[review.sskoId].creator, "DKN: Only SSKO creator can dispute");
        require(review.status == ReviewStatus.Approved, "DKN: Only approved reviews can be disputed");

        review.status = ReviewStatus.Disputed;
        review.reviewerDisputing = msg.sender;
        // _disputeReasonHash is stored off-chain or linked via an event
        // A governance module would then handle the dispute resolution.
        // On-chain: Could involve a vote or arbitration.
        // For simplicity here, it just marks it disputed.
    }

    /**
     * @dev Internal function to adjust a user's KnowledgeScore.
     * @param _user The address of the user whose score is being updated.
     * @param _scoreChange The amount to change the score by (can be positive or negative).
     */
    function _updateUserKnowledgeScore(address _user, int256 _scoreChange) internal {
        uint256 oldScore = userKnowledgeScore[_user];
        uint256 newScore;

        if (_scoreChange > 0) {
            newScore = oldScore.add(uint256(_scoreChange));
        } else {
            uint256 absScoreChange = uint256(-_scoreChange);
            newScore = oldScore > absScoreChange ? oldScore.sub(absScoreChange) : 0;
        }

        userKnowledgeScore[_user] = newScore;
        emit KnowledgeScoreUpdated(_user, oldScore, newScore);
    }

    /**
     * @dev Retrieves a specific user's current KnowledgeScore.
     * @param _user The address of the user.
     * @return The KnowledgeScore of the user.
     */
    function getKnowledgeScore(address _user) external view returns (uint256) {
        return userKnowledgeScore[_user];
    }

    /**
     * @dev Admin/Governance can reduce a user's KnowledgeScore for malicious or poor-quality contributions.
     * @param _user The address of the user to penalize.
     * @param _amount The amount to reduce the score by.
     * @param _reasonHash IPFS hash of the reason for slashing.
     */
    function slashKnowledgeScore(address _user, uint256 _amount, string memory _reasonHash)
        external
        whenNotPaused
        onlyGovernance
    {
        require(userKnowledgeScore[_user] >= _amount, "DKN: Cannot slash more than current score");
        _updateUserKnowledgeScore(_user, -int256(_amount));
        // An event specific to slashing could be added.
    }

    // --- III. Knowledge Discovery Engine ---

    /**
     * @dev User stakes tokens to define an intent (e.g., "find connections between X and Y") for the network to discover.
     * @param _intentPromptHash IPFS hash of the natural language prompt or query.
     * @param _stakeAmount The amount of knowledge tokens to stake for this quest.
     * @return questId The ID of the newly initiated discovery quest.
     */
    function initiateDiscoveryQuest(string memory _intentPromptHash, uint256 _stakeAmount)
        external
        whenNotPaused
        returns (uint256 questId)
    {
        require(_stakeAmount > 0, "DKN: Stake amount must be greater than zero");
        require(knowledgeToken.transferFrom(msg.sender, address(this), _stakeAmount), "DKN: Token transfer failed");

        _questIdCounter.increment();
        questId = _questIdCounter.current();

        discoveryQuests[questId] = DiscoveryQuest({
            questId: questId,
            initiator: msg.sender,
            intentPromptHash: _intentPromptHash,
            stakedAmount: _stakeAmount,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(DISCOVERY_QUEST_DURATION),
            isActive: true,
            hasFinalizedProposal: false
        });

        emit DiscoveryQuestInitiated(questId, msg.sender, _intentPromptHash, _stakeAmount, discoveryQuests[questId].expirationTimestamp);
    }

    /**
     * @dev A "Discovery Agent" proposes a new link (connection) between multiple SSKOs, providing reasoning.
     *      Agents could be humans, bots, or AI systems. Their work is validated by the community.
     * @param _questId The ID of the discovery quest this proposal addresses.
     * @param _sskoIdsInvolved An array of SSKO IDs that are proposed to be linked.
     * @param _reasonHash IPFS hash of the detailed reasoning for this proposed link.
     * @return linkId The ID of the newly created discovery proposal.
     */
    function submitDiscoveryProposal(uint256 _questId, uint256[] memory _sskoIdsInvolved, string memory _reasonHash)
        external
        whenNotPaused
        returns (uint256 linkId)
    {
        DiscoveryQuest storage quest = discoveryQuests[_questId];
        require(quest.isActive, "DKN: Quest is not active");
        require(block.timestamp <= quest.expirationTimestamp, "DKN: Quest has expired");
        require(_sskoIdsInvolved.length >= 2, "DKN: A link must involve at least two SSKOs");
        require(!quest.hasFinalizedProposal, "DKN: Quest already has a finalized proposal");

        for (uint256 i = 0; i < _sskoIdsInvolved.length; i++) {
            require(sskos[_sskoIdsInvolved[i]].sskoId != 0, "DKN: Invalid SSKO ID in proposal");
            require(!sskos[_sskoIdsInvolved[i]].isArchived, "DKN: Cannot link archived SSKOs");
        }

        _linkIdCounter.increment();
        linkId = _linkIdCounter.current();

        discoveryLinks[linkId] = DiscoveryLink({
            linkId: linkId,
            sskoIdsInvolved: _sskoIdsInvolved,
            proposer: msg.sender,
            proposalReasonHash: _reasonHash,
            proposalTimestamp: block.timestamp,
            questId: _questId,
            isValidated: false,
            validationTimestamp: 0,
            hasVoted: new mapping(address => bool),
            positiveVotes: 0,
            negativeVotes: 0,
            ethicalVotes: 0,
            accurateVotes: 0,
            relevantVotes: 0
        });

        emit DiscoveryProposalSubmitted(linkId, _questId, msg.sender, _sskoIdsInvolved);
    }

    /**
     * @dev Community members vote on the validity, ethics, and relevance of a proposed knowledge link.
     * @param _linkId The ID of the discovery proposal to vote on.
     * @param _isEthical True if the link is deemed ethically sound.
     * @param _isAccurate True if the link is factually accurate.
     * @param _isRelevant True if the link is relevant to the associated quest or network.
     */
    function voteOnDiscoveryProposal(uint256 _linkId, bool _isEthical, bool _isAccurate, bool _isRelevant)
        external
        whenNotPaused
    {
        DiscoveryLink storage link = discoveryLinks[_linkId];
        require(link.linkId != 0, "DKN: Link proposal does not exist");
        require(!link.isValidated, "DKN: Link already validated");
        require(discoveryQuests[link.questId].isActive, "DKN: Associated quest is not active");
        require(block.timestamp <= discoveryQuests[link.questId].expirationTimestamp.add(DISCOVERY_QUEST_DURATION / 2), "DKN: Voting period expired"); // Allow voting for a period after quest expiry
        require(!link.hasVoted[msg.sender], "DKN: Already voted on this proposal");

        link.hasVoted[msg.sender] = true;
        if (_isEthical) link.ethicalVotes++;
        if (_isAccurate) link.accurateVotes++;
        if (_isRelevant) link.relevantVotes++;

        // A simple majority across all three criteria might be enough. Or weighted by KnowledgeScore.
        // For simplicity, we just count them. Finalization logic will decide.

        emit DiscoveryProposalVoted(_linkId, msg.sender, _isEthical, _isAccurate, _isRelevant);
    }

    /**
     * @dev If a proposal receives enough positive votes, the link is officially added to the network graph,
     *      and the proposer is rewarded from the quest's staked funds.
     * @param _linkId The ID of the discovery proposal to finalize.
     */
    function finalizeDiscoveryProposal(uint256 _linkId)
        external
        whenNotPaused
    {
        DiscoveryLink storage link = discoveryLinks[_linkId];
        require(link.linkId != 0, "DKN: Link proposal does not exist");
        require(!link.isValidated, "DKN: Link already validated");
        require(discoveryQuests[link.questId].isActive, "DKN: Associated quest is not active");
        require(!discoveryQuests[link.questId].hasFinalizedProposal, "DKN: Quest already has a finalized proposal");

        // Simple validation logic: require MIN_VALIDATION_VOTES for each criteria
        require(link.ethicalVotes >= MIN_VALIDATION_VOTES &&
                link.accurateVotes >= MIN_VALIDATION_VOTES &&
                link.relevantVotes >= MIN_VALIDATION_VOTES, "DKN: Not enough validation votes");

        link.isValidated = true;
        link.validationTimestamp = block.timestamp;
        
        // Add direct links for querying
        for (uint256 i = 0; i < link.sskoIdsInvolved.length; i++) {
            sskoToDiscoveryLinks[link.sskoIdsInvolved[i]].push(_linkId);
        }

        DiscoveryQuest storage quest = discoveryQuests[link.questId];
        quest.isActive = false; // Quest completed
        quest.hasFinalizedProposal = true;

        uint256 rewardAmount = quest.stakedAmount; // Proposer gets the full stake for simplicity
        require(knowledgeToken.transfer(link.proposer, rewardAmount), "DKN: Reward transfer failed");
        
        _updateUserKnowledgeScore(link.proposer, int256(KNOWLEDGE_SCORE_REWARD_DISCOVERY_PROPOSAL));

        emit DiscoveryProposalFinalized(_linkId, link.questId, link.proposer, rewardAmount);
    }
    
    /**
     * @dev Returns all SSKO IDs directly linked to a given SSKO through finalized discovery links.
     * @param _sskoId The ID of the SSKO to query.
     * @return An array of SSKO IDs connected to the input SSKO.
     */
    function queryConnectedSSKOs(uint256 _sskoId) external view returns (uint256[] memory) {
        require(sskos[_sskoId].sskoId != 0, "DKN: SSKO does not exist");
        
        uint256[] memory linkedDiscoveryIds = sskoToDiscoveryLinks[_sskoId];
        uint256[] memory connectedSSKOs;
        uint256 count = 0;

        // First pass to count unique SSKOs and allocate memory efficiently
        mapping(uint256 => bool) seen;
        for (uint256 i = 0; i < linkedDiscoveryIds.length; i++) {
            DiscoveryLink storage link = discoveryLinks[linkedDiscoveryIds[i]];
            if (link.isValidated) {
                for (uint256 j = 0; j < link.sskoIdsInvolved.length; j++) {
                    uint256 connectedId = link.sskoIdsInvolved[j];
                    if (connectedId != _sskoId && !seen[connectedId]) {
                        seen[connectedId] = true;
                        count++;
                    }
                }
            }
        }

        connectedSSKOs = new uint256[](count);
        uint256 currentIdx = 0;
        // Second pass to populate the array
        for (uint256 i = 0; i < linkedDiscoveryIds.length; i++) {
            DiscoveryLink storage link = discoveryLinks[linkedDiscoveryIds[i]];
            if (link.isValidated) {
                for (uint256 j = 0; j < link.sskoIdsInvolved.length; j++) {
                    uint256 connectedId = link.sskoIdsInvolved[j];
                    if (connectedId != _sskoId && seen[connectedId]) {
                        connectedSSKOs[currentIdx] = connectedId;
                        seen[connectedId] = false; // Mark as added to avoid duplicates if iterating again
                        currentIdx++;
                    }
                }
            }
        }
        return connectedSSKOs;
    }

    /**
     * @dev Returns SSKOs that were part of finalized discovery proposals for a given quest.
     * @param _questId The ID of the discovery quest.
     * @return An array of SSKO IDs relevant to the quest.
     */
    function querySSKOsByDiscoveryIntent(uint256 _questId) external view returns (uint256[] memory) {
        require(discoveryQuests[_questId].questId != 0, "DKN: Quest does not exist");

        // Iterate through all links to find those associated with this quest and are validated
        uint256[] memory relevantSSKOs;
        uint256 count = 0;
        mapping(uint256 => bool) seenSSKO;

        for (uint256 i = 1; i <= _linkIdCounter.current(); i++) {
            DiscoveryLink storage link = discoveryLinks[i];
            if (link.questId == _questId && link.isValidated) {
                for (uint256 j = 0; j < link.sskoIdsInvolved.length; j++) {
                    uint256 sskoId = link.sskoIdsInvolved[j];
                    if (!seenSSKO[sskoId]) {
                        seenSSKO[sskoId] = true;
                        count++;
                    }
                }
            }
        }

        relevantSSKOs = new uint256[](count);
        uint256 currentIdx = 0;
        for (uint256 i = 1; i <= _linkIdCounter.current(); i++) {
            DiscoveryLink storage link = discoveryLinks[i];
            if (link.questId == _questId && link.isValidated) {
                for (uint256 j = 0; j < link.sskoIdsInvolved.length; j++) {
                    uint256 sskoId = link.sskoIdsInvolved[j];
                    if (seenSSKO[sskoId]) { // Check again in case it was added in the first pass
                        relevantSSKOs[currentIdx] = sskoId;
                        seenSSKO[sskoId] = false; // Mark as added
                        currentIdx++;
                    }
                }
            }
        }
        return relevantSSKOs;
    }


    // --- IV. Research Bounties ---

    /**
     * @dev A community member proposes a bounty for addressing a specific knowledge gap or research question.
     * @param _title Title of the bounty.
     * @param _descriptionHash IPFS hash of the detailed bounty description.
     * @param _rewardGoal The target amount of tokens to collect for the bounty.
     * @return bountyId The ID of the newly proposed bounty.
     */
    function proposeResearchBounty(string memory _title, string memory _descriptionHash, uint256 _rewardGoal)
        external
        whenNotPaused
        returns (uint256 bountyId)
    {
        require(_rewardGoal > 0, "DKN: Reward goal must be positive");

        _bountyIdCounter.increment();
        bountyId = _bountyIdCounter.current();

        researchBounties[bountyId] = ResearchBounty({
            bountyId: bountyId,
            proposer: msg.sender,
            title: _title,
            descriptionHash: _descriptionHash,
            rewardGoal: _rewardGoal,
            currentFunds: 0,
            creationTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp.add(BOUNTY_FUNDING_DURATION),
            status: BountyStatus.Funding,
            winningSolutionId: 0,
            submittedSolutions: new mapping(uint256 => address),
            solutionVotes: new mapping(uint256 => uint256),
            totalSolutionVotes: 0
        });

        emit ResearchBountyProposed(bountyId, msg.sender, _title, _rewardGoal);
    }

    /**
     * @dev Users contribute funds (Knowledge Tokens) to an active research bounty.
     * @param _bountyId The ID of the bounty to fund.
     */
    function fundResearchBounty(uint256 _bountyId)
        external
        payable
        whenNotPaused
    {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.bountyId != 0, "DKN: Bounty does not exist");
        require(bounty.status == BountyStatus.Funding, "DKN: Bounty is not in funding stage");
        require(block.timestamp <= bounty.expirationTimestamp, "DKN: Funding period for bounty has ended");
        require(msg.value > 0, "DKN: Must send ETH to fund bounty"); // Using ETH for funding for simplicity, could be KnowledgeToken.

        bounty.currentFunds = bounty.currentFunds.add(msg.value);
        emit ResearchBountyFunded(_bountyId, msg.sender, msg.value);

        if (bounty.currentFunds >= bounty.rewardGoal) {
            bounty.status = BountyStatus.Open; // Funding goal met, open for solutions
            // Could add an event for BountyStatusChange
        }
    }

    /**
     * @dev A creator submits an SSKO as a proposed solution to an open bounty.
     * @param _bountyId The ID of the bounty.
     * @param _sskoId The ID of the SSKO being submitted as a solution.
     * @param _explanationHash IPFS hash of an explanation connecting the SSKO to the bounty.
     */
    function submitBountySolution(uint256 _bountyId, uint256 _sskoId, string memory _explanationHash)
        external
        whenNotPaused
    {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.bountyId != 0, "DKN: Bounty does not exist");
        require(bounty.status == BountyStatus.Open, "DKN: Bounty not open for solutions");
        require(block.timestamp <= bounty.expirationTimestamp, "DKN: Solution submission period ended"); // Use funding expiration as solution submission expiry for now
        require(sskos[_sskoId].sskoId != 0, "DKN: SSKO does not exist");
        require(!sskos[_sskoId].isArchived, "DKN: Cannot submit archived SSKO as solution");
        require(sskos[_sskoId].creator == msg.sender, "DKN: Only SSKO creator can submit as solution");

        // Prevent multiple submissions of the same SSKO to the same bounty
        require(bounty.submittedSolutions[_sskoId] == address(0), "DKN: SSKO already submitted as solution");

        bounty.submittedSolutions[_sskoId] = msg.sender;
        
        // Transition to voting phase if first solution, or after a fixed period
        if (bounty.totalSolutionVotes == 0) { // Using totalSolutionVotes as a proxy for first solution
            bounty.status = BountyStatus.Voting;
            // Set a voting expiration
            bounty.expirationTimestamp = block.timestamp.add(BOUNTY_VOTING_DURATION);
        }

        emit BountySolutionSubmitted(_bountyId, _sskoId, msg.sender);
    }

    /**
     * @dev Community members vote on which submitted solution best addresses the bounty.
     * @param _bountyId The ID of the bounty.
     * @param _solutionId The SSKO ID of the proposed solution being voted for.
     * @param _isSolution True if the voter believes this SSKO is a valid solution.
     */
    function voteOnBountySolution(uint256 _bountyId, uint256 _solutionId, bool _isSolution)
        external
        whenNotPaused
    {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.bountyId != 0, "DKN: Bounty does not exist");
        require(bounty.status == BountyStatus.Voting, "DKN: Bounty not in voting stage");
        require(block.timestamp <= bounty.expirationTimestamp, "DKN: Voting period for bounty has ended");
        require(bounty.submittedSolutions[_solutionId] != address(0), "DKN: Not a valid submitted solution");

        // Prevent double voting (per bounty, not per solution)
        // This requires an additional mapping per bounty, e.g., mapping(uint256 => mapping(address => bool)) hasVotedBounty;
        // For simplicity, let's assume external systems prevent double voting per bounty from a single user
        // Or implement an on-chain voting system that tracks voters per bounty.
        // For this example, we'll keep it simple:
        bounty.solutionVotes[_solutionId] = bounty.solutionVotes[_solutionId].add(1); // Assuming positive vote
        bounty.totalSolutionVotes = bounty.totalSolutionVotes.add(1);

        emit BountySolutionVoted(_bountyId, _solutionId, msg.sender);
    }

    /**
     * @dev The winner(s) of a bounty (as determined by voting) can claim their share of the collected funds.
     *      This function can only be called after the voting period has ended.
     * @param _bountyId The ID of the bounty to claim rewards from.
     */
    function claimBountyReward(uint256 _bountyId)
        external
        whenNotPaused
    {
        ResearchBounty storage bounty = researchBounties[_bountyId];
        require(bounty.bountyId != 0, "DKN: Bounty does not exist");
        require(bounty.status == BountyStatus.Voting || bounty.status == BountyStatus.Closed, "DKN: Bounty not in claiming stage");
        require(block.timestamp > bounty.expirationTimestamp, "DKN: Voting period not yet ended");
        require(bounty.winningSolutionId == 0, "DKN: Reward already claimed or winning solution already determined"); // Only allow once

        // Determine winner
        uint256 maxVotes = 0;
        uint256 winningSSKOId = 0;
        address winnerAddress = address(0);

        // Iterate through all submitted solutions to find the one with the most votes
        for (uint256 i = 1; i <= _sskoIdCounter.current(); i++) { // Potentially inefficient for many SSKOs
            if (bounty.submittedSolutions[i] != address(0) && bounty.solutionVotes[i] > maxVotes) {
                maxVotes = bounty.solutionVotes[i];
                winningSSKOId = i;
                winnerAddress = bounty.submittedSolutions[i];
            }
        }
        
        require(winningSSKOId != 0, "DKN: No valid winning solution found");
        
        bounty.winningSolutionId = winningSSKOId;
        bounty.status = BountyStatus.Closed; // Or BountyStatus.Claimed if immediate claim

        uint256 rewardAmount = bounty.currentFunds;
        // Transfer collected ETH to the winner
        (bool success, ) = winnerAddress.call{value: rewardAmount}("");
        require(success, "DKN: Failed to send ETH reward to winner");

        emit BountyRewardClaimed(_bountyId, winnerAddress, rewardAmount);
    }

    // --- V. Utility & Administrative Functions ---

    /**
     * @dev Allows a user to withdraw their stake from an expired or cancelled discovery quest.
     * @param _questId The ID of the discovery quest.
     */
    function withdrawStakedFundsFromDiscovery(uint256 _questId)
        external
        whenNotPaused
    {
        DiscoveryQuest storage quest = discoveryQuests[_questId];
        require(quest.questId != 0, "DKN: Quest does not exist");
        require(quest.initiator == msg.sender, "DKN: Only quest initiator can withdraw stake");
        require(!quest.hasFinalizedProposal, "DKN: Cannot withdraw from quest with finalized proposal");
        require(block.timestamp > quest.expirationTimestamp, "DKN: Quest is still active");
        require(quest.stakedAmount > 0, "DKN: No funds staked or already withdrawn");

        uint256 amountToWithdraw = quest.stakedAmount;
        quest.stakedAmount = 0; // Prevent double withdrawal
        quest.isActive = false; // Mark quest as inactive

        require(knowledgeToken.transfer(msg.sender, amountToWithdraw), "DKN: Token transfer failed");
        emit StakedFundsWithdrawn(_questId, msg.sender, amountToWithdraw);
    }

    /**
     * @dev Admin function to manually grant KnowledgeScore (e.g., for initial contributors or special achievements).
     * @param _user The address of the user to grant score to.
     * @param _amount The amount of score to grant.
     */
    function grantKnowledgeScore(address _user, uint256 _amount)
        external
        whenNotPaused
        onlyGovernance // Or onlyOwner if governance isn't fully set up
    {
        require(_amount > 0, "DKN: Amount must be positive");
        _updateUserKnowledgeScore(_user, int256(_amount));
    }

    /**
     * @dev Admin function to pause all mutable operations in case of an emergency.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Admin function to resume operations after pausing.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Admin function to update the address of the DAO/governance contract.
     * @param _newGovAddress The new address for governance.
     */
    function setGovernanceAddress(address _newGovAddress) external onlyOwner {
        require(_newGovAddress != address(0), "DKN: Invalid governance address");
        governanceAddress = _newGovAddress;
    }

    /**
     * @dev Returns the address of the ERC20 token used for staking and rewards.
     * @return The address of the KnowledgeToken.
     */
    function getTokenAddress() external view returns (address) {
        return address(knowledgeToken);
    }

    /**
     * @dev Returns the original creator of an SSKO.
     * @param _sskoId The ID of the SSKO.
     * @return The address of the creator.
     */
    function getSSKOCreator(uint256 _sskoId) external view returns (address) {
        require(sskos[_sskoId].sskoId != 0, "DKN: SSKO does not exist");
        return sskos[_sskoId].creator;
    }
}
```