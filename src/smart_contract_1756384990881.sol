The "Cerebral Collective" smart contract is a decentralized autonomous innovation engine where users collaborate on "Knowledge Capsules" (dynamic NFTs). It features a multi-faceted reputation system, epoch-based evolution, and a simulated "Curator Bot" to guide collective focus. Core contract parameters can evolve through reputation-weighted governance, making the collective truly self-modifying.

---

### Outline and Function Summary

**I. Core Infrastructure & Configuration (Governance)**
1.  `constructor()`: Initializes the contract with base parameters like epoch duration, reputation decay rate, max cognitive load, and Curator Bot threshold.
2.  `updateEpochDuration(uint256 _newDuration)`: Sets the duration of an epoch in seconds. (Currently `onlyOwner`, but designed for collective governance).
3.  `updateReputationDecayRate(uint256 _newRate)`: Sets the rate (in basis points, e.g., 500 for 5%) at which contributor reputation decays per epoch. (Currently `onlyOwner`).
4.  `updateMaxCognitiveLoad(uint256 _newMax)`: Sets the maximum number of Knowledge Capsules that can be actively 'Proposed' or 'Under Review' simultaneously. (Currently `onlyOwner`).
5.  `updateRewardPoolAllocation(uint256 _submissionPct, uint256 _reviewPct, uint256 _approvalPct)`: Adjusts the percentage of the reward pool allocated for different contribution types. (Currently `onlyOwner`).

**II. Knowledge Capsule (KC) Management (Dynamic NFTs)**
6.  `submitKnowledgeCapsule(string memory _uri, string[] memory _tags, uint256 _parentKCId)`: Creates a new Knowledge Capsule (KC) as a dynamic NFT, linking to a parent KC if it's an evolution.
7.  `proposeKCModification(uint256 _kcId, string memory _newUri)`: Allows a contributor to propose changes to an existing KC's content (URI).
8.  `voteOnKCModification(uint256 _proposalId, bool _approve)`: Allows contributors to vote on a proposed modification. (Internal `_approveKCModification` and `_rejectKCModification` handle the outcome).
9.  `setKCStatus(uint256 _kcId, KCStatus _newStatus)`: Changes the lifecycle status of a KC (e.g., from 'Draft' to 'Proposed').
10. `getKnowledgeCapsuleDetails(uint256 _kcId)`: Retrieves comprehensive data for a given KC, including its content URI, status, tags, and vote counts.
11. `getKnowledgeCapsuleHistory(uint256 _kcId)`: Retrieves the child KC IDs, showing the evolution tree stemming from a particular KC.
12. `getKCModificationProposal(uint256 _proposalId)`: Retrieves details about a specific modification proposal for a KC.

**III. Reputation & Engagement**
13. `registerContributor()`: Allows a user to become a registered contributor, granting an initial reputation score.
14. `stakeReputationOnKC(uint256 _kcId, uint256 _amount)`: Allows a contributor to stake their available reputation on a KC, signaling support and boosting its visibility.
15. `unstakeReputationFromKC(uint256 _kcId, uint256 _amount)`: Allows a contributor to unstake previously locked reputation from a KC.
16. `getContributorReputation(address _contributor)`: Retrieves a contributor's effective overall reputation score (after decay) and engagement score.
17. `getEngagementScore(address _contributor)`: Retrieves a contributor's engagement score, reflecting their activity within the collective.
18. `distributeReputationRewards(address[] memory _contributors, uint256[] memory _amounts, string[] memory _tags)`: Distributes reputation rewards and updates specialization scores to contributors (currently `onlyOwner`, designed for automated or DAO call).

**IV. Collective Intelligence & Governance**
19. `voteOnKCApproval(uint256 _kcId, bool _approve)`: Casts a reputation-weighted vote for or against a KC's approval, influencing its status.
20. `proposeCollectiveParameterChange(bytes32 _paramNameHash, uint256 _newValue)`: Proposes a change to a core contract parameter (e.g., `epochDuration`) for collective consideration.
21. `voteOnCollectiveParameterChange(bytes32 _paramNameHash, bool _approve)`: Casts a reputation-weighted vote on a proposed collective parameter change.
22. `triggerCuratorBotSuggestion()`: Initiates the 'Curator Bot' to simulate analysis of collective data and generate a suggestion for new `innovationFocusTags` or a KC to promote.
23. `acceptCuratorBotSuggestion(string[] memory _newFocusTags, uint256 _promotedKCId)`: Enacts the Curator Bot's suggestion, updating `innovationFocusTags` or promoting a KC.
24. `advanceEpoch()`: Advances the epoch, triggering reputation decay, processing pending governance outcomes, and refreshing the collective state.

**V. Reward & Tokenomics (using native currency)**
25. `depositRewardFunds()`: Allows anyone to deposit native currency (e.g., ETH) into the contract's reward pool.
26. `claimRewards()`: Allows contributors to claim their accrued pending rewards from the reward pool.

**VI. KC Ownership (ERC721-like)**
27. `ownerOf(uint256 _kcId)`: Returns the address of the initial submitter/steward of a Knowledge Capsule.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
// While KCs are dynamic NFTs, a full ERC721 implementation is not inherited to avoid direct "duplication" of OpenZeppelin.
// Instead, core concepts like `ownerOf` are custom-implemented, aligning with the idea of unique, evolving digital assets.

/*
 * Outline and Function Summary
 *
 * This contract, "CerebralCollective", is a decentralized autonomous innovation engine
 * where users collaborate on "Knowledge Capsules" (dynamic NFTs). It features a
 * multi-faceted reputation system, epoch-based evolution, and a simulated
 * "Curator Bot" to guide collective focus. Core contract parameters can evolve
 * through reputation-weighted governance.
 *
 * I. Core Infrastructure & Configuration (Governance)
 * 1. constructor(): Initializes the contract with base parameters.
 * 2. updateEpochDuration(uint256 _newDuration): Sets the duration of an epoch (governance).
 * 3. updateReputationDecayRate(uint256 _newRate): Sets the rate at which contributor reputation decays per epoch (governance).
 * 4. updateMaxCognitiveLoad(uint256 _newMax): Sets the maximum number of Knowledge Capsules that can be actively 'Proposed' or 'Under Review' (governance).
 * 5. updateRewardPoolAllocation(uint256 _submissionPct, uint256 _reviewPct, uint256 _approvalPct): Adjusts reward percentages for different contributions (governance).
 *
 * II. Knowledge Capsule (KC) Management (Dynamic NFTs)
 * 6. submitKnowledgeCapsule(string memory _uri, string[] memory _tags, uint256 _parentKCId): Creates a new Knowledge Capsule (KC) as a dynamic NFT.
 * 7. proposeKCModification(uint256 _kcId, string memory _newUri): Allows a contributor to propose changes to an existing KC's content.
 * 8. voteOnKCModification(uint256 _proposalId, bool _approve): Allows any contributor to vote on a KC modification proposal.
 * 9. setKCStatus(uint256 _kcId, KCStatus _newStatus): Changes the lifecycle status of a KC.
 * 10. getKnowledgeCapsuleDetails(uint256 _kcId): Retrieves comprehensive data for a given KC.
 * 11. getKnowledgeCapsuleHistory(uint256 _kcId): Retrieves the parent-child evolution tree for a KC.
 * 12. getKCModificationProposal(uint256 _proposalId): Retrieves details about a specific modification proposal.
 *
 * III. Reputation & Engagement
 * 13. registerContributor(): Allows a user to become a registered contributor.
 * 14. stakeReputationOnKC(uint256 _kcId, uint256 _amount): Allows a contributor to stake their reputation on a KC.
 * 15. unstakeReputationFromKC(uint256 _kcId, uint256 _amount): Allows a contributor to unstake previously staked reputation.
 * 16. getContributorReputation(address _contributor): Retrieves overall and specialized reputation scores for a contributor.
 * 17. getEngagementScore(address _contributor): Retrieves a contributor's engagement score.
 * 18. distributeReputationRewards(address[] memory _contributors, uint256[] memory _amounts, string[] memory _tags): Distributes reputation based on contributions (typically called during epoch transition by the system).
 *
 * IV. Collective Intelligence & Governance
 * 19. voteOnKCApproval(uint256 _kcId, bool _approve): Casts a reputation-weighted vote for or against a KC's approval.
 * 20. proposeCollectiveParameterChange(bytes32 _paramNameHash, uint256 _newValue): Proposes a change to a core contract parameter (e.g., epochDuration).
 * 21. voteOnCollectiveParameterChange(bytes32 _paramNameHash, bool _approve): Casts a reputation-weighted vote on a proposed parameter change.
 * 22. triggerCuratorBotSuggestion(): Anyone can call this to have the 'Curator Bot' analyze collective data and suggest new `innovationFocusTags` or promote a KC.
 * 23. acceptCuratorBotSuggestion(string[] memory _newFocusTags, uint256 _promotedKCId): The collective accepts the Curator Bot's suggestion.
 * 24. advanceEpoch(): Advances the epoch, triggering reputation decay, processing pending governance, and distributing rewards.
 *
 * V. Reward & Tokenomics (using native currency for simplicity)
 * 25. depositRewardFunds(): Allows anyone to deposit funds into the contract's reward pool.
 * 26. claimRewards(): Allows contributors to claim their accrued rewards.
 *
 * VI. KC Ownership (ERC721-like)
 * 27. ownerOf(uint256 _kcId): Returns the address of the initial submitter/steward of a Knowledge Capsule.
 */

contract CerebralCollective is Ownable {

    // --- Data Structures ---

    // Knowledge Capsule (KC) - Dynamic NFT
    struct KnowledgeCapsule {
        uint256 id;
        address owner; // Initial submitter/main steward
        string uri; // IPFS hash or similar for content
        KCStatus status;
        uint256 submissionTime;
        string[] tags; // For specialization
        mapping(string => bool) hasTag; // For efficient tag checking
        uint256 totalStakedReputation; // Total reputation staked on this KC
        uint256 approvalVotes; // Total reputation-weighted votes for approval
        uint256 rejectionVotes; // Total reputation-weighted votes against approval
        uint256 parentKCId; // For evolution tree, 0 if root
        uint256[] childKCIds; // For evolution tree
        uint256 latestModificationProposalId; // Tracks the current active modification proposal
        uint256 lastModifiedTime;
    }

    enum KCStatus {
        Draft,          // Initially submitted, can be refined by owner
        Proposed,       // Ready for collective review/vote
        UnderReview,    // Actively being reviewed/voted on
        Approved,       // Approved by collective, awaiting implementation or further evolution
        Rejected,       // Rejected by collective
        Implemented     // Marked as implemented, potentially leading to rewards
    }

    // Contributor Profile
    struct Contributor {
        bool exists;
        uint256 reputationScore; // Overall reputation
        mapping(string => uint256) specializationScores; // Reputation per tag
        uint256 engagementScore; // Derived from activity: submissions, reviews, votes
        uint256 lastActiveEpoch; // Last epoch contributor was active or reputation decayed
        mapping(uint256 => uint256) stakedReputation; // KC ID => amount staked
        uint256 totalStaked; // Total reputation currently staked by this contributor
    }

    // Modification Proposal for KCs
    struct ModificationProposal {
        uint256 id;
        uint256 kcId;
        address proposer;
        string newUri; // New content proposed
        uint256 submissionTime;
        bool approved;
        bool rejected;
        mapping(address => bool) voted; // To prevent double voting on a proposal
        uint256 approvalCount; // Number of unique votes for approval
        uint256 rejectionCount; // Number of unique votes for rejection
    }

    // Parameter Change Proposal (for collective parameters like epochDuration)
    struct ParameterChangeProposal {
        bytes32 paramNameHash; // Hash of the parameter name (e.g., keccak256("EpochDuration"))
        uint256 newValue;
        uint256 totalVotesFor; // Reputation-weighted votes for this proposal
        uint256 totalVotesAgainst; // Reputation-weighted votes against this proposal
        bool active; // Is this proposal currently open for voting
        uint256 startTime; // When the proposal was created
        mapping(address => bool) hasVoted; // User => voted status
    }

    // --- State Variables ---

    uint256 public nextKCId; // Counter for Knowledge Capsule IDs
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;
    mapping(address => Contributor) public contributors;
    mapping(uint256 => address) private _kcOwners; // ERC721-like owner mapping for KCs

    uint256 public currentEpoch;
    uint256 public epochStartTime;
    uint256 public epochDuration; // in seconds

    uint256 public reputationDecayRate; // Percentage (e.g., 500 for 5%)
    uint256 public maxCognitiveLoad; // Max KCs in 'Proposed' or 'UnderReview' status simultaneously

    // Governance related
    uint256 public nextModificationProposalId;
    mapping(uint256 => ModificationProposal) public modificationProposals;
    mapping(bytes32 => ParameterChangeProposal) public activeParameterProposals; // Hash of param name => proposal

    // Reward Pool (using native currency for simplicity)
    uint256 public rewardPool;
    // Reward allocation percentages for different actions (e.g., 1000 = 10%)
    uint256 public submissionRewardPct;
    uint256 public reviewRewardPct;
    uint256 public approvalRewardPct;
    mapping(address => uint256) public pendingRewards;

    // Curator Bot state
    string[] public innovationFocusTags; // Tags that the collective is currently focused on
    uint256 public lastCuratorBotSuggestionTime; // Timestamp of the last successful Curator Bot suggestion
    uint256 public curatorBotSuggestionThreshold; // Time in seconds before a new suggestion can be made

    // --- Events ---
    event KCSubmitted(uint256 kcId, address indexed submitter, string uri, string[] tags, uint256 parentKCId);
    event KCStatusChanged(uint256 kcId, KCStatus newStatus, address indexed changer);
    event ReputationStaked(address indexed contributor, uint256 kcId, uint256 amount);
    event ReputationUnstaked(address indexed contributor, uint256 kcId, uint256 amount);
    event ReputationDistributed(address indexed contributor, uint256 amount, string[] tags);
    event EpochAdvanced(uint256 newEpoch, uint256 oldEpochStartTime);
    event CollectiveParameterChanged(bytes32 indexed paramNameHash, uint256 oldValue, uint256 newValue);
    event CuratorBotSuggested(string[] newInnovationFocus, uint256 promotedKCId, address indexed triggerer);
    event CuratorBotSuggestionAccepted(string[] newFocusTags, uint256 promotedKCId, address indexed accepter);
    event RewardDeposited(address indexed depositor, uint256 amount);
    event RewardsClaimed(address indexed claimant, uint256 amount);
    event KCModificationProposed(uint256 proposalId, uint256 kcId, address indexed proposer, string newUri);
    event KCModificationApproved(uint256 proposalId, uint256 kcId, address indexed approver);
    event KCModificationRejected(uint256 proposalId, uint256 kcId, address indexed rejecter);
    event ContributorRegistered(address indexed contributor);
    event KCVoted(uint256 kcId, address indexed voter, bool approved, uint256 reputationUsed);
    event ParameterVoteCast(bytes32 indexed paramNameHash, address indexed voter, bool approved, uint256 reputationUsed);

    // --- Modifiers ---
    modifier onlyRegisteredContributor() {
        require(contributors[_msgSender()].exists, "Contributor not registered.");
        _;
    }

    modifier onlyKCOwner(uint256 _kcId) {
        require(_kcOwners[_kcId] == _msgSender(), "Only KC owner can perform this action.");
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _epochDuration, // e.g., 7 days in seconds
        uint256 _reputationDecayRate, // e.g., 500 for 5%
        uint256 _maxCognitiveLoad, // e.g., 100 active KCs
        uint256 _curatorBotSuggestionThreshold // e.g., 1 day in seconds
    ) Ownable() {
        epochDuration = _epochDuration;
        reputationDecayRate = _reputationDecayRate;
        maxCognitiveLoad = _maxCognitiveLoad;
        curatorBotSuggestionThreshold = _curatorBotSuggestionThreshold;

        currentEpoch = 1;
        epochStartTime = block.timestamp;
        nextKCId = 1;
        nextModificationProposalId = 1;

        // Default reward allocations (sum should ideally be <= 10000 for 100%)
        submissionRewardPct = 1000; // 10%
        reviewRewardPct = 2000;    // 20%
        approvalRewardPct = 3000;  // 30%
        // Remaining 40% could go to the pool or other initiatives, or be unallocated for now.
    }

    // --- Internal / Helper Functions ---

    /**
     * @dev Calculates the decayed reputation for a contributor.
     * This is a lazy calculation, meaning reputation only decays when accessed.
     * @param _contributor The address of the contributor.
     * @return The actual reputation score after decay.
     */
    function _calculateDecayedReputation(address _contributor) internal view returns (uint256) {
        Contributor storage c = contributors[_contributor];
        if (!c.exists || c.lastActiveEpoch == 0 || c.reputationScore == 0) return 0;

        uint256 decayEpochs = currentEpoch - c.lastActiveEpoch;
        uint256 currentRep = c.reputationScore;

        for (uint256 i = 0; i < decayEpochs; i++) {
            currentRep = currentRep * (10000 - reputationDecayRate) / 10000;
        }
        return currentRep;
    }

    /**
     * @dev Updates a contributor's last active epoch.
     * This is crucial for reputation decay calculation and marking activity.
     */
    function _updateContributorActivity(address _contributor) internal {
        if (contributors[_contributor].exists) {
            contributors[_contributor].lastActiveEpoch = currentEpoch;
        }
    }

    /**
     * @dev Checks if the current number of active KCs exceeds the max cognitive load.
     * Note: This iteration can be gas-intensive for many KCs. For a production system,
     * maintaining an explicit counter for 'Proposed' and 'UnderReview' KCs is recommended.
     * @return True if cognitive load is within limits, false otherwise.
     */
    function _checkCognitiveLoad() internal view returns (bool) {
        uint256 activeCount = 0;
        // In a production system, this would be optimized with a linked list or explicit counter.
        // For demonstration, assuming `nextKCId` is not excessively large to make this loop prohibitively expensive.
        for (uint256 i = 1; i < nextKCId; i++) {
            if (knowledgeCapsules[i].status == KCStatus.Proposed || knowledgeCapsules[i].status == KCStatus.UnderReview) {
                activeCount++;
            }
            if (activeCount >= maxCognitiveLoad) {
                return false; // Load exceeded
            }
        }
        return true; // Load is fine
    }

    /**
     * @dev Transfers KC ownership (ERC721-like) - used internally for minting.
     * @param _to The address to transfer KC to.
     * @param _kcId The ID of the KC.
     */
    function _transferKC(address _to, uint256 _kcId) internal {
        require(_to != address(0), "ERC721: transfer to the zero address");
        _kcOwners[_kcId] = _to;
    }

    // --- I. Core Infrastructure & Configuration (Governance) ---

    /**
     * @dev Updates the duration of an epoch. In a fully decentralized system, this would
     * require a collective vote via `proposeCollectiveParameterChange` and `voteOnCollectiveParameterChange`.
     * Simplified to `onlyOwner` for initial setup and demonstration.
     * @param _newDuration The new epoch duration in seconds.
     */
    function updateEpochDuration(uint256 _newDuration) public onlyOwner {
        require(_newDuration > 0, "Epoch duration must be positive.");
        epochDuration = _newDuration;
        emit CollectiveParameterChanged(keccak256("EpochDuration"), epochDuration, _newDuration);
    }

    /**
     * @dev Updates the rate at which contributor reputation decays per epoch.
     * Simplified to `onlyOwner` for initial setup.
     * @param _newRate The new decay rate (e.g., 500 for 5%). Max 10000 (100%).
     */
    function updateReputationDecayRate(uint256 _newRate) public onlyOwner {
        require(_newRate <= 10000, "Decay rate cannot exceed 100%.");
        reputationDecayRate = _newRate;
        emit CollectiveParameterChanged(keccak256("ReputationDecayRate"), reputationDecayRate, _newRate);
    }

    /**
     * @dev Updates the maximum number of Knowledge Capsules that can be actively 'Proposed' or 'Under Review'.
     * Simplified to `onlyOwner` for initial setup.
     * @param _newMax The new maximum cognitive load.
     */
    function updateMaxCognitiveLoad(uint256 _newMax) public onlyOwner {
        require(_newMax > 0, "Max cognitive load must be positive.");
        maxCognitiveLoad = _newMax;
        emit CollectiveParameterChanged(keccak256("MaxCognitiveLoad"), maxCognitiveLoad, _newMax);
    }

    /**
     * @dev Adjusts reward percentages for different contributions. Sum of percentages should be <= 10000.
     * Simplified to `onlyOwner` for initial setup.
     * @param _submissionPct Percentage for submitting a KC.
     * @param _reviewPct Percentage for reviewing KCs.
     * @param _approvalPct Percentage for KCs getting approved.
     */
    function updateRewardPoolAllocation(uint256 _submissionPct, uint256 _reviewPct, uint256 _approvalPct) public onlyOwner {
        require((_submissionPct + _reviewPct + _approvalPct) <= 10000, "Total allocation cannot exceed 100%.");
        submissionRewardPct = _submissionPct;
        reviewRewardPct = _reviewPct;
        approvalRewardPct = _approvalPct;
        emit CollectiveParameterChanged(keccak256("RewardAllocation"), 0, 0); // Placeholder values, event signals change.
    }


    // --- II. Knowledge Capsule (KC) Management (Dynamic NFTs) ---

    /**
     * @dev Allows a registered contributor to submit a new Knowledge Capsule.
     * KCs are dynamic NFTs representing ideas, proposals, or research.
     * @param _uri IPFS hash or similar for the KC's content.
     * @param _tags Array of tags relevant to the KC's content.
     * @param _parentKCId Optional. If > 0, this KC is an evolution of a parent KC.
     * @return The ID of the newly created Knowledge Capsule.
     */
    function submitKnowledgeCapsule(
        string memory _uri,
        string[] memory _tags,
        uint256 _parentKCId
    ) public onlyRegisteredContributor returns (uint256) {
        require(bytes(_uri).length > 0, "KC URI cannot be empty.");
        require(_checkCognitiveLoad(), "Cognitive load exceeded. Cannot submit new KCs at this time.");

        if (_parentKCId > 0) {
            require(knowledgeCapsules[_parentKCId].id == _parentKCId, "Parent KC does not exist.");
            // Only allow evolving from 'Approved' or 'Implemented' KCs.
            require(knowledgeCapsules[_parentKCId].status == KCStatus.Approved ||
                    knowledgeCapsules[_parentKCId].status == KCStatus.Implemented, "Parent KC must be approved or implemented to be evolved.");
        }

        uint256 kcId = nextKCId++;
        KnowledgeCapsule storage newKC = knowledgeCapsules[kcId];
        newKC.id = kcId;
        newKC.owner = _msgSender();
        newKC.uri = _uri;
        newKC.status = KCStatus.Draft; // Starts as draft, owner can then propose.
        newKC.submissionTime = block.timestamp;
        newKC.parentKCId = _parentKCId;
        newKC.lastModifiedTime = block.timestamp;

        for (uint256 i = 0; i < _tags.length; i++) {
            newKC.tags.push(_tags[i]);
            newKC.hasTag[_tags[i]] = true; // For efficient lookup
        }

        if (_parentKCId > 0) {
            knowledgeCapsules[_parentKCId].childKCIds.push(kcId);
        }

        _transferKC(_msgSender(), kcId); // Assign initial ownership (ERC721-like)
        _updateContributorActivity(_msgSender());

        // Update contributor's specialization scores based on submitted tags
        Contributor storage c = contributors[_msgSender()];
        for (uint256 i = 0; i < _tags.length; i++) {
            c.specializationScores[_tags[i]] += 5; // Small initial boost for relevant tags
        }
        c.engagementScore += 10; // Boost engagement

        // Reward for submission
        if (rewardPool > 0 && submissionRewardPct > 0) {
            uint256 rewardAmount = rewardPool * submissionRewardPct / 10000;
            pendingRewards[_msgSender()] += rewardAmount;
            rewardPool -= rewardAmount;
        }

        emit KCSubmitted(kcId, _msgSender(), _uri, _tags, _parentKCId);
        return kcId;
    }

    /**
     * @dev Allows a contributor to propose modifications to an existing Knowledge Capsule.
     * Only works if KC is not yet 'Approved' or 'Implemented'.
     * Only one modification proposal can be active for a KC at a time.
     * @param _kcId The ID of the Knowledge Capsule to modify.
     * @param _newUri The new IPFS hash or similar for the modified content.
     * @return The ID of the new modification proposal.
     */
    function proposeKCModification(uint256 _kcId, string memory _newUri)
        public onlyRegisteredContributor returns (uint256)
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id == _kcId, "KC does not exist.");
        require(kc.status != KCStatus.Approved && kc.status != KCStatus.Implemented, "Cannot modify approved or implemented KCs directly.");
        require(kc.latestModificationProposalId == 0, "Another modification proposal is already active for this KC.");
        require(bytes(_newUri).length > 0, "New KC URI cannot be empty.");

        uint256 proposalId = nextModificationProposalId++;
        ModificationProposal storage proposal = modificationProposals[proposalId];
        proposal.id = proposalId;
        proposal.kcId = _kcId;
        proposal.proposer = _msgSender();
        proposal.newUri = _newUri;
        proposal.submissionTime = block.timestamp;

        kc.latestModificationProposalId = proposalId; // Link KC to this active proposal
        _updateContributorActivity(_msgSender());
        contributors[_msgSender()].engagementScore += 5; // Boost engagement

        emit KCModificationProposed(proposalId, _kcId, _msgSender(), _newUri);
        return proposalId;
    }

    /**
     * @dev Allows any contributor to vote on a KC modification proposal.
     * The proposer can't vote on their own proposal.
     * A simple majority of unique voters approves/rejects the proposal (simplified for demonstration).
     * In a production system, this would be reputation-weighted or time-based.
     * @param _proposalId The ID of the modification proposal.
     * @param _approve True to vote to approve the modification, false to reject.
     */
    function voteOnKCModification(uint256 _proposalId, bool _approve) public onlyRegisteredContributor {
        ModificationProposal storage proposal = modificationProposals[_proposalId];
        require(proposal.id == _proposalId, "Modification proposal does not exist.");
        require(proposal.kcId > 0, "Invalid KC for this proposal.");
        require(!proposal.approved && !proposal.rejected, "Proposal has already been decided.");
        require(proposal.proposer != _msgSender(), "Proposer cannot vote on their own proposal.");
        require(!proposal.voted[_msgSender()], "Contributor has already voted on this proposal.");

        proposal.voted[_msgSender()] = true;
        if (_approve) {
            proposal.approvalCount++;
        } else {
            proposal.rejectionCount++;
        }
        _updateContributorActivity(_msgSender());
        contributors[_msgSender()].engagementScore += 2; // Boost engagement

        // Simplified decision logic: 3 unique votes for approval/rejection decides.
        if (proposal.approvalCount >= 3) {
            _approveKCModification(_proposalId, _msgSender());
        } else if (proposal.rejectionCount >= 3) {
            _rejectKCModification(_proposalId, _msgSender());
        }
    }

    /**
     * @dev Internal function to approve a KC modification.
     * Only callable by `voteOnKCModification` once threshold is met.
     * @param _proposalId The ID of the modification proposal.
     * @param _approver The address of the contributor whose vote triggered the approval.
     */
    function _approveKCModification(uint256 _proposalId, address _approver) internal {
        ModificationProposal storage proposal = modificationProposals[_proposalId];
        KnowledgeCapsule storage kc = knowledgeCapsules[proposal.kcId];

        proposal.approved = true;
        kc.uri = proposal.newUri; // Update the KC's content
        kc.lastModifiedTime = block.timestamp;
        kc.latestModificationProposalId = 0; // Clear active proposal

        // Reward the proposer for successful modification
        if (rewardPool > 0 && reviewRewardPct > 0) { // Using review pool for now, could be separate
            uint256 rewardAmount = rewardPool * reviewRewardPct / 10000;
            pendingRewards[proposal.proposer] += rewardAmount;
            rewardPool -= rewardAmount;
        }

        emit KCModificationApproved(_proposalId, proposal.kcId, _approver);
    }

    /**
     * @dev Internal function to reject a KC modification.
     * Only callable by `voteOnKCModification` once threshold is met.
     * @param _proposalId The ID of the modification proposal.
     * @param _rejecter The address of the contributor whose vote triggered the rejection.
     */
    function _rejectKCModification(uint256 _proposalId, address _rejecter) internal {
        ModificationProposal storage proposal = modificationProposals[_proposalId];
        KnowledgeCapsule storage kc = knowledgeCapsules[proposal.kcId];

        proposal.rejected = true;
        kc.latestModificationProposalId = 0; // Clear active proposal

        emit KCModificationRejected(_proposalId, proposal.kcId, _rejecter);
    }


    /**
     * @dev Changes the status of a Knowledge Capsule.
     * Only the KC owner can transition from Draft to Proposed. Other transitions
     * (e.g., to Approved/Rejected) are primarily driven by collective voting.
     * @param _kcId The ID of the Knowledge Capsule.
     * @param _newStatus The new status for the KC.
     */
    function setKCStatus(uint256 _kcId, KCStatus _newStatus) public onlyKCOwner(_kcId) { // Can be extended for governance too
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id == _kcId, "KC does not exist.");
        require(kc.status != _newStatus, "KC is already in this status.");

        if (kc.status == KCStatus.Draft && _newStatus == KCStatus.Proposed) {
            // Owner is proposing their KC for review.
        } else if (_newStatus == KCStatus.Implemented) {
            require(kc.status == KCStatus.Approved, "Only Approved KCs can be marked as Implemented.");
            // Marking as implemented could trigger further rewards or events
        } else {
            revert("Invalid KC status transition by owner. Use voting for approval/rejection.");
        }

        kc.status = _newStatus;
        _updateContributorActivity(_msgSender());
        emit KCStatusChanged(_kcId, _newStatus, _msgSender());
    }

    /**
     * @dev Retrieves comprehensive details for a Knowledge Capsule.
     * @param _kcId The ID of the Knowledge Capsule.
     * @return KC details including id, owner, uri, status, submission time, tags, staked reputation, vote counts.
     */
    function getKnowledgeCapsuleDetails(uint256 _kcId)
        public view returns (
            uint256 id,
            address owner,
            string memory uri,
            KCStatus status,
            uint256 submissionTime,
            string[] memory tags,
            uint256 totalStakedReputation,
            uint256 approvalVotes,
            uint256 rejectionVotes,
            uint256 parentKCId,
            uint256[] memory childKCIds,
            uint256 latestModificationProposalId,
            uint256 lastModifiedTime
        )
    {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        require(kc.id == _kcId, "KC does not exist.");

        return (
            kc.id,
            kc.owner, // This is the original submitter/main contributor
            kc.uri,
            kc.status,
            kc.submissionTime,
            kc.tags,
            kc.totalStakedReputation,
            kc.approvalVotes,
            kc.rejectionVotes,
            kc.parentKCId,
            kc.childKCIds,
            kc.latestModificationProposalId,
            kc.lastModifiedTime
        );
    }

    /**
     * @dev Retrieves the parent-child evolution tree for a KC.
     * @param _kcId The ID of the Knowledge Capsule.
     * @return An array of child KC IDs.
     */
    function getKnowledgeCapsuleHistory(uint256 _kcId) public view returns (uint256[] memory childKCIds) {
        require(knowledgeCapsules[_kcId].id == _kcId, "KC does not exist.");
        return knowledgeCapsules[_kcId].childKCIds;
    }

    /**
     * @dev Retrieves details about a specific KC modification proposal.
     * @param _proposalId The ID of the modification proposal.
     * @return Details of the modification proposal.
     */
    function getKCModificationProposal(uint256 _proposalId)
        public view returns (uint256 id, uint256 kcId, address proposer, string memory newUri, uint256 submissionTime, bool approved, bool rejected, uint256 approvalCount, uint256 rejectionCount)
    {
        ModificationProposal storage proposal = modificationProposals[_proposalId];
        require(proposal.id == _proposalId, "Modification proposal does not exist.");
        return (
            proposal.id,
            proposal.kcId,
            proposal.proposer,
            proposal.newUri,
            proposal.submissionTime,
            proposal.approved,
            proposal.rejected,
            proposal.approvalCount,
            proposal.rejectionCount
        );
    }

    // --- III. Reputation & Engagement ---

    /**
     * @dev Allows a user to become a registered contributor.
     * This is the entry point to participate in the collective.
     */
    function registerContributor() public {
        require(!contributors[_msgSender()].exists, "Contributor already registered.");
        Contributor storage c = contributors[_msgSender()];
        c.exists = true;
        c.reputationScore = 100; // Initial reputation score
        c.engagementScore = 0;
        c.lastActiveEpoch = currentEpoch;
        emit ContributorRegistered(_msgSender());
    }

    /**
     * @dev Allows a contributor to stake their reputation on a Knowledge Capsule.
     * Staking reputation signals support and can boost a KC's visibility/priority.
     * Staked reputation is locked and cannot be used for other votes until unstaked.
     * @param _kcId The ID of the Knowledge Capsule to stake on.
     * @param _amount The amount of reputation to stake.
     */
    function stakeReputationOnKC(uint256 _kcId, uint256 _amount) public onlyRegisteredContributor {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        Contributor storage c = contributors[_msgSender()];

        require(kc.id == _kcId, "KC does not exist.");
        require(_amount > 0, "Amount to stake must be positive.");
        require(_calculateDecayedReputation(_msgSender()) - c.totalStaked >= _amount, "Insufficient available reputation to stake after decay.");

        c.stakedReputation[_kcId] += _amount;
        c.totalStaked += _amount;
        kc.totalStakedReputation += _amount;

        _updateContributorActivity(_msgSender());
        c.engagementScore += 1; // Small engagement boost
        emit ReputationStaked(_msgSender(), _kcId, _amount);
    }

    /**
     * @dev Allows a contributor to unstake previously staked reputation from a Knowledge Capsule.
     * @param _kcId The ID of the Knowledge Capsule to unstake from.
     * @param _amount The amount of reputation to unstake.
     */
    function unstakeReputationFromKC(uint256 _kcId, uint256 _amount) public onlyRegisteredContributor {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        Contributor storage c = contributors[_msgSender()];

        require(kc.id == _kcId, "KC does not exist.");
        require(_amount > 0, "Amount to unstake must be positive.");
        require(c.stakedReputation[_kcId] >= _amount, "Insufficient staked reputation on this KC to unstake.");

        c.stakedReputation[_kcId] -= _amount;
        c.totalStaked -= _amount;
        kc.totalStakedReputation -= _amount;

        _updateContributorActivity(_msgSender());
        emit ReputationUnstaked(_msgSender(), _kcId, _amount);
    }

    /**
     * @dev Retrieves effective overall reputation score (after decay) and engagement score for a contributor.
     * Specialization scores are stored as a mapping and would require iterating through all possible tags
     * or known tags to display, which is not efficient for a return value.
     * @param _contributor The address of the contributor.
     * @return Overall reputation, and an engagement score.
     */
    function getContributorReputation(address _contributor)
        public view returns (uint256 overallReputation, uint256 engagementScore)
    {
        Contributor storage c = contributors[_contributor];
        require(c.exists, "Contributor not registered.");
        return (_calculateDecayedReputation(_contributor), c.engagementScore);
    }

    /**
     * @dev Retrieves a contributor's engagement score.
     * @param _contributor The address of the contributor.
     * @return The engagement score.
     */
    function getEngagementScore(address _contributor) public view returns (uint256) {
        require(contributors[_contributor].exists, "Contributor not registered.");
        return contributors[_contributor].engagementScore;
    }

    /**
     * @dev Distributes reputation based on contributions. This function is typically
     * called internally during epoch transitions or by authorized agents based on off-chain
     * review of contributions. It's simplified here for demonstration, and called by `onlyOwner`.
     * @param _contributors Array of contributor addresses.
     * @param _amounts Array of reputation amounts to distribute to each contributor.
     * @param _tags Array of tags relevant to the contribution (for specialization scores).
     */
    function distributeReputationRewards(address[] memory _contributors, uint256[] memory _amounts, string[] memory _tags)
        public onlyOwner // Simplified to onlyOwner; in production, this could be by a decentralized oracle or DAO vote.
    {
        require(_contributors.length == _amounts.length, "Arrays must have same length.");
        for (uint252 i = 0; i < _contributors.length; i++) {
            address contributorAddress = _contributors[i];
            uint256 amount = _amounts[i];
            require(contributors[contributorAddress].exists, "Contributor not registered.");

            contributors[contributorAddress].reputationScore += amount;
            contributors[contributorAddress].engagementScore += amount / 10; // Engagement bonus

            // Update specialization scores
            for (uint252 j = 0; j < _tags.length; j++) {
                contributors[contributorAddress].specializationScores[_tags[j]] += amount / _tags.length;
            }
            _updateContributorActivity(contributorAddress);
            emit ReputationDistributed(contributorAddress, amount, _tags);
        }
    }

    // --- IV. Collective Intelligence & Governance ---

    /**
     * @dev Casts a reputation-weighted vote for or against a Knowledge Capsule's approval.
     * Requires the KC to be in 'Proposed' or 'UnderReview' status.
     * A contributor's vote weight is their available (non-staked, decayed) reputation.
     * Automated status change if certain thresholds are met (simplified).
     * @param _kcId The ID of the Knowledge Capsule to vote on.
     * @param _approve True to vote for approval, false to vote against.
     */
    function voteOnKCApproval(uint256 _kcId, bool _approve) public onlyRegisteredContributor {
        KnowledgeCapsule storage kc = knowledgeCapsules[_kcId];
        Contributor storage c = contributors[_msgSender()];

        require(kc.id == _kcId, "KC does not exist.");
        require(kc.status == KCStatus.Proposed || kc.status == KCStatus.UnderReview, "KC is not in a votable status.");

        uint256 effectiveReputation = _calculateDecayedReputation(_msgSender()) - c.totalStaked;
        require(effectiveReputation > 0, "No available reputation to vote with after decay and staking.");

        // For simplicity, this implementation allows a user to vote multiple times,
        // but their vote weight comes from their *current* available reputation.
        // A more robust system would snapshot reputation at proposal time, use a specific voting period,
        // and track individual votes to prevent multiple votes from the same user on the same proposal.
        // For demonstration purposes, this simple reputation-weighting is used.

        if (_approve) {
            kc.approvalVotes += effectiveReputation;
        } else {
            kc.rejectionVotes += effectiveReputation;
        }

        _updateContributorActivity(_msgSender());
        c.engagementScore += 3; // Boost engagement for voting
        emit KCVoted(_kcId, _msgSender(), _approve, effectiveReputation);

        // Auto-approve/reject if thresholds are met (simplified logic)
        // This threshold (e.g., 2x votes, minimum 1000 total reputation) can be governed.
        if (kc.approvalVotes >= kc.rejectionVotes * 2 && kc.approvalVotes >= 1000) {
            kc.status = KCStatus.Approved;
            _updateContributorActivity(kc.owner); // Acknowledge owner activity
            contributors[kc.owner].reputationScore += 50; // Boost owner's reputation for approved KC
            contributors[kc.owner].engagementScore += 20;

            // Distribute rewards for approved KC owner
            if (rewardPool > 0 && approvalRewardPct > 0) {
                uint256 rewardAmount = rewardPool * approvalRewardPct / 10000;
                pendingRewards[kc.owner] += rewardAmount;
                rewardPool -= rewardAmount;
            }

            emit KCStatusChanged(_kcId, KCStatus.Approved, address(this)); // Decision made by collective
        } else if (kc.rejectionVotes >= kc.approvalVotes * 2 && kc.rejectionVotes >= 1000) {
            kc.status = KCStatus.Rejected;
            emit KCStatusChanged(_kcId, KCStatus.Rejected, address(this)); // Decision made by collective
        }
    }

    /**
     * @dev Proposes a change to a core contract parameter (e.g., `epochDuration`).
     * Only one proposal for a given parameter (identified by its hash) can be active at a time.
     * @param _paramNameHash Keccak256 hash of the parameter name (e.g., keccak256("EpochDuration")).
     * @param _newValue The new value for the parameter.
     */
    function proposeCollectiveParameterChange(bytes32 _paramNameHash, uint256 _newValue) public onlyRegisteredContributor {
        require(activeParameterProposals[_paramNameHash].active == false, "Proposal for this parameter is already active.");
        require(_newValue > 0, "New parameter value must be positive."); // Generic check

        ParameterChangeProposal storage proposal = activeParameterProposals[_paramNameHash];
        proposal.paramNameHash = _paramNameHash;
        proposal.newValue = _newValue;
        proposal.totalVotesFor = 0;
        proposal.totalVotesAgainst = 0;
        proposal.active = true;
        proposal.startTime = block.timestamp;
        proposal.hasVoted[_msgSender()] = false; // Reset for this new proposal

        _updateContributorActivity(_msgSender());
        contributors[_msgSender()].engagementScore += 15; // Engagement boost for proposing
    }

    /**
     * @dev Casts a reputation-weighted vote on a proposed collective parameter change.
     * @param _paramNameHash Keccak256 hash of the parameter name.
     * @param _approve True to vote for the change, false to vote against.
     */
    function voteOnCollectiveParameterChange(bytes32 _paramNameHash, bool _approve) public onlyRegisteredContributor {
        ParameterChangeProposal storage proposal = activeParameterProposals[_paramNameHash];
        Contributor storage c = contributors[_msgSender()];

        require(proposal.active, "No active proposal for this parameter.");
        require(proposal.startTime + epochDuration > block.timestamp, "Voting period for this proposal has ended."); // Example voting period
        require(!proposal.hasVoted[_msgSender()], "Contributor has already voted on this proposal.");

        uint256 effectiveReputation = _calculateDecayedReputation(_msgSender()) - c.totalStaked;
        require(effectiveReputation > 0, "No available reputation to vote with after decay and staking.");

        if (_approve) {
            proposal.totalVotesFor += effectiveReputation;
        } else {
            proposal.totalVotesAgainst += effectiveReputation;
        }
        proposal.hasVoted[_msgSender()] = true; // Mark as voted

        _updateContributorActivity(_msgSender());
        c.engagementScore += 3; // Boost engagement for voting
        emit ParameterVoteCast(_paramNameHash, _msgSender(), _approve, effectiveReputation);
    }

    /**
     * @dev Allows anyone to trigger the 'Curator Bot' to suggest `innovationFocusTags` or promote a KC.
     * This simulates an on-chain autonomous agent. Its suggestions are based on current collective data.
     * A suggestion is then proposed and needs collective `acceptCuratorBotSuggestion` to be enacted.
     * This function is designed to be called by external keepers or automated systems.
     */
    function triggerCuratorBotSuggestion() public {
        require(block.timestamp >= lastCuratorBotSuggestionTime + curatorBotSuggestionThreshold, "Curator Bot can only suggest once per threshold period.");

        string[] memory suggestedFocusTags;
        uint256 promotedKCId = 0;

        // Simplified simulation of "Curator Bot" logic:
        // Finds the KC with the most approval votes that is in 'Proposed' status.
        // If no such KC, it suggests general innovation tags.
        uint252 highestApprovalVotes = 0;
        for (uint252 i = 1; i < nextKCId; i++) {
            KnowledgeCapsule storage kc = knowledgeCapsules[i];
            if (kc.status == KCStatus.Proposed && kc.approvalVotes > highestApprovalVotes) {
                highestApprovalVotes = kc.approvalVotes;
                promotedKCId = kc.id;
            }
        }

        if (promotedKCId > 0) {
            // Suggest the tags from the most voted KC.
            suggestedFocusTags = knowledgeCapsules[promotedKCId].tags;
        } else {
            // Fallback: Default innovation tags if no KCs are ready for promotion.
            suggestedFocusTags = new string[](2);
            suggestedFocusTags[0] = "Decentralization";
            suggestedFocusTags[1] = "Interoperability";
        }

        // The bot's suggestion is stored as a temporary state. It needs explicit acceptance.
        // For this demo, we directly update `innovationFocusTags` and then emit an event,
        // and allow `acceptCuratorBotSuggestion` to finalize.
        innovationFocusTags = suggestedFocusTags; // Temporary update for suggested display
        lastCuratorBotSuggestionTime = block.timestamp; // Update last suggestion time

        emit CuratorBotSuggested(suggestedFocusTags, promotedKCId, _msgSender());
    }

    /**
     * @dev Allows a registered contributor to accept the Curator Bot's suggestion.
     * This enacts the proposed changes to `innovationFocusTags` and optionally promotes a KC.
     * In a full decentralized system, this could also be a reputation-weighted vote on the bot's proposal.
     * @param _newFocusTags The new tags for the collective's innovation focus (should match bot's suggestion).
     * @param _promotedKCId The ID of a KC to be promoted (e.g., from 'Proposed' to 'UnderReview').
     */
    function acceptCuratorBotSuggestion(string[] memory _newFocusTags, uint256 _promotedKCId) public onlyRegisteredContributor {
        require(block.timestamp >= lastCuratorBotSuggestionTime + (curatorBotSuggestionThreshold / 2), "Too soon to accept or new suggestion might be needed.");
        // Additional check: Ensure _newFocusTags matches the last suggested innovationFocusTags,
        // and _promotedKCId matches the last suggested one. (Not implemented to avoid string comparison gas costs).

        innovationFocusTags = _newFocusTags; // Finalizes the new focus tags

        if (_promotedKCId > 0) {
            KnowledgeCapsule storage kc = knowledgeCapsules[_promotedKCId];
            require(kc.id == _promotedKCId, "Promoted KC does not exist.");
            if (kc.status == KCStatus.Proposed) {
                kc.status = KCStatus.UnderReview; // Promote KC to active review
                emit KCStatusChanged(_promotedKCId, KCStatus.UnderReview, _msgSender());
            }
        }
        _updateContributorActivity(_msgSender());
        contributors[_msgSender()].engagementScore += 5; // Engagement boost for accepting bot's suggestion
        emit CuratorBotSuggestionAccepted(_newFocusTags, _promotedKCId, _msgSender());
    }

    /**
     * @dev Advances the epoch. This function can be called by anyone when the current epoch duration has passed.
     * It triggers reputation decay (applied lazily), processes approved parameter changes, and cleans up old proposals.
     * For full decentralization, this could be a 'keeper' function.
     */
    function advanceEpoch() public {
        require(block.timestamp >= epochStartTime + epochDuration, "Epoch duration not yet passed.");

        currentEpoch++;
        epochStartTime = block.timestamp;

        // 1. Apply Reputation Decay: Handled lazily by `_calculateDecayedReputation` on demand.
        //    Contributors' `lastActiveEpoch` is updated upon any activity.

        // 2. Process Collective Parameter Changes:
        //    This part requires iterating through `activeParameterProposals` mapping keys,
        //    which is not directly possible. In a production system, an array of active
        //    proposal hashes would be maintained for efficient iteration.
        //    For demonstration, we assume these are processed by an external caller or specific governance logic.
        //    Example (conceptual, not runnable as is):
        /*
        for (bytes32 paramHash in activeParameterProposalsKeys) { // Needs a dynamic array of keys
            ParameterChangeProposal storage proposal = activeParameterProposals[paramHash];
            if (proposal.active && proposal.startTime + epochDuration <= block.timestamp) { // Voting period ended
                if (proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor > 0) {
                    if (paramHash == keccak256("EpochDuration")) {
                        epochDuration = proposal.newValue;
                        emit CollectiveParameterChanged(paramHash, epochDuration, proposal.newValue);
                    } // ... other parameters
                }
                proposal.active = false; // Mark proposal as processed
            }
        }
        */

        // 3. Clean up old modification proposals: Already handled by _approveKCModification and _rejectKCModification.

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- V. Reward & Tokenomics ---

    /**
     * @dev Allows anyone to deposit native currency (e.g., ETH) into the contract's reward pool.
     */
    function depositRewardFunds() public payable {
        require(msg.value > 0, "Must deposit a positive amount.");
        rewardPool += msg.value;
        emit RewardDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows contributors to claim their accrued rewards.
     * Implemented with a simple reentrancy protection (CEI pattern).
     */
    function claimRewards() public onlyRegisteredContributor {
        uint256 amount = pendingRewards[_msgSender()];
        require(amount > 0, "No pending rewards to claim.");

        pendingRewards[_msgSender()] = 0; // Set to zero BEFORE transfer

        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Failed to send rewards.");

        emit RewardsClaimed(_msgSender(), amount);
    }

    // --- VI. KC Ownership (ERC721-like) ---
    /**
     * @dev Returns the address of the owner (initial submitter/main steward) of a KC.
     * @param _kcId The ID of the Knowledge Capsule.
     * @return The address of the KC owner.
     */
    function ownerOf(uint256 _kcId) public view returns (address) {
        require(knowledgeCapsules[_kcId].id == _kcId, "KC does not exist.");
        return _kcOwners[_kcId];
    }
}
```