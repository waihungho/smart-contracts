Okay, this is an exciting challenge! Let's design a smart contract that embodies advanced concepts, is creative, and touches upon trendy aspects without directly duplicating existing open-source projects.

We'll create "The Aetherial Nexus Protocol" – a decentralized, self-evolving protocol that leverages collective intelligence, reputation, and dynamic rule-sets to manage resources and respond to "intents" in a highly adaptive manner. It's like a decentralized, data-driven organism that grows and adapts its operational logic based on community consensus and observed performance.

**Core Concept:** A protocol that can dynamically update its own operational parameters and decision-making logic through a "Knowledge Capsule" system, where participants propose and vote on new rules, strategies, or insights. It then uses these activated "Knowledge Capsules" to evaluate and fulfill user "Intents" and manage its treasury. Reputation (Contribution Score) is paramount for influence.

---

## **The Aetherial Nexus Protocol**

**Outline:**

1.  **Introduction & Vision:** A protocol designed for adaptive, decentralized governance and resource management, leveraging community-curated "knowledge" and participant reputation.
2.  **Core Components:**
    *   **Knowledge Capsules:** On-chain, versioned rules, strategies, or insights proposed and activated by the community. They define how the protocol behaves.
    *   **Participant Profiles & Contribution Score:** A reputation system tracking active and valuable participation, influencing voting power and proposal thresholds.
    *   **Intent System:** A mechanism for users to submit desired outcomes (intents), which the protocol then evaluates and potentially fulfills based on its currently active Knowledge Capsules.
    *   **Adaptive Treasury Management:** Treasury allocation governed by Knowledge Capsules and participant votes.
3.  **Advanced Concepts Highlighted:**
    *   **Dynamic On-Chain Logic:** Protocol behavior changes based on activated Knowledge Capsules, not just fixed code.
    *   **Reputation-Weighted Governance:** Influence is tied to demonstrated contribution, not just token holdings.
    *   **Intent-Based Architecture (Simplified):** Users express desired states, and the protocol intelligently tries to achieve them.
    *   **Self-Correction/Adaptation:** Mechanisms for disputing harmful capsules and adapting thresholds.
    *   **Decentralized "Wisdom" Curations:** The community builds the protocol's operational "brain."

---

**Function Summary (25+ Functions):**

**I. Core Infrastructure & Access Control**
1.  `constructor()`: Initializes the protocol, sets the initial owner.
2.  `pause()`: Pauses core operations in an emergency.
3.  `unpause()`: Resumes operations.
4.  `setMinContributionForProposal(uint256 _newMinScore)`: Owner sets minimum score to propose capsules.
5.  `setVoteThresholds(uint256 _activation, uint256 _deactivation)`: Owner sets thresholds for capsule status changes.

**II. Participant & Contribution Score Management**
6.  `registerParticipant()`: Allows anyone to register and start accumulating contribution score.
7.  `getParticipantProfile(address _participant)`: Retrieves a participant's details.
8.  `delegateContributionScore(address _delegatee)`: Delegate voting power and influence.
9.  `revokeDelegation()`: Revoke previous delegation.
10. `_updateContributionScore(address _participant, uint256 _amount)` (internal): Adjusts participant scores based on actions.

**III. Knowledge Capsule Management (The Protocol's Brain)**
11. `proposeKnowledgeCapsule(string calldata _ipfsContentHash, string calldata _description)`: Proposes a new operational rule or strategy.
12. `voteOnKnowledgeCapsule(uint256 _capsuleId, bool _for)`: Participants vote for or against a proposed capsule.
13. `activateKnowledgeCapsule(uint256 _capsuleId)`: Transitions a capsule to active status if thresholds are met.
14. `deactivateKnowledgeCapsule(uint256 _capsuleId)`: Transitions an active capsule back to proposed or rejected if thresholds met/disputed.
15. `getKnowledgeCapsuleDetails(uint256 _capsuleId)`: Retrieves details of a specific capsule.
16. `getKnowledgeCapsulesByStatus(KnowledgeCapsuleStatus _status)`: Lists capsules by their current status.
17. `submitKnowledgeCapsuleDispute(uint256 _capsuleId, string calldata _reason)`: Initiate a dispute process for a capsule deemed harmful.
18. `resolveKnowledgeCapsuleDispute(uint256 _capsuleId, bool _validDispute)`: Owner/Governance resolves disputes (could evolve into vote-based).

**IV. Intent & Execution Engine**
19. `submitIntent(IntentType _type, address _target, uint256 _value, bytes calldata _data)`: A participant expresses a desired action or outcome.
20. `evaluateIntent(uint256 _intentId)`: Internal function: The protocol evaluates an intent against its active Knowledge Capsules.
21. `fulfillIntent(uint256 _intentId)`: Executes an intent if `evaluateIntent` determines it's valid and beneficial.
22. `rejectIntent(uint256 _intentId, string calldata _reason)`: Marks an intent as rejected.
23. `getIntentDetails(uint256 _intentId)`: Retrieves an intent's status and parameters.

**V. Adaptive Treasury Management**
24. `depositToTreasury()`: Allows users to contribute funds to the protocol's treasury.
25. `proposeTreasuryAllocation(string calldata _purpose, uint256 _amount, address _recipient)`: Propose how treasury funds should be spent.
26. `voteOnTreasuryAllocation(uint256 _allocationId, bool _for)`: Participants vote on a treasury allocation proposal.
27. `executeTreasuryAllocation(uint256 _allocationId)`: Executes the transfer of funds if the allocation proposal passes.
28. `getTreasuryBalance()`: Returns the current balance of the protocol's treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title The Aetherial Nexus Protocol
 * @dev A decentralized, self-evolving protocol for adaptive governance and resource management.
 *      It leverages collective intelligence via "Knowledge Capsules" (dynamic rules/strategies),
 *      a reputation-based "Contribution Score," and an "Intent System" for automated actions.
 */
contract AetherialNexus is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Custom Errors ---
    error AlreadyRegistered();
    error NotRegistered();
    error InvalidKnowledgeCapsuleStatus();
    error InsufficientContributionScore(uint256 required, uint256 current);
    error KnowledgeCapsuleNotFound();
    error NotEnoughVotes(uint256 required, uint256 current);
    error AlreadyVoted();
    error IntentNotFound();
    error IntentNotFulfillable();
    error AllocationNotFound();
    error AllocationNotApproved();
    error InsufficientTreasuryBalance(uint256 required, uint256 current);
    error SelfDelegationNotAllowed();
    error InvalidDelegationTarget();
    error NoActiveDelegation();
    error InvalidVoteType();
    error DisputedCapsule();
    error OnlyOwnerOrGovernance(); // For future governance system integration

    // --- Enums ---
    enum KnowledgeCapsuleStatus {
        Proposed,
        Active,
        Rejected,
        Disputed
    }

    enum IntentStatus {
        Pending,
        Fulfilled,
        Rejected
    }

    enum IntentType {
        TreasuryTransfer,
        ProtocolParameterUpdate,
        CustomAction
    }

    // --- Structs ---
    struct ParticipantProfile {
        uint256 contributionScore;
        uint256 lastActivityTimestamp;
        address delegatedTo; // Address this participant has delegated their score to
        bool isRegistered;
    }

    struct KnowledgeCapsule {
        uint256 id;
        address creator;
        string ipfsContentHash; // IPFS hash pointing to the detailed content/logic of the capsule
        string description;     // Brief description for on-chain visibility
        KnowledgeCapsuleStatus status;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted; // Tracks unique votes per participant
        uint256 creationTimestamp;
        bool isInDispute; // True if a dispute has been submitted
    }

    struct Intent {
        uint256 id;
        address caller;
        IntentType intentType;
        address targetAddress;  // Target for treasury transfer or parameter update
        uint256 value;          // Amount for treasury transfer or new parameter value
        bytes data;             // Additional data for custom actions (e.g., function signature + args)
        IntentStatus status;
        uint256 resolutionCapsuleId; // ID of the Knowledge Capsule that dictated the resolution
        string rejectionReason; // Reason if rejected
    }

    struct TreasuryAllocation {
        uint256 id;
        string purpose;
        uint256 amount;
        address recipient;
        address proposer;
        uint256 creationTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // --- State Variables ---
    mapping(address => ParticipantProfile) public participantProfiles;
    address[] public registeredParticipants; // To iterate or get total count

    KnowledgeCapsule[] public knowledgeCapsules;
    uint256 public nextKnowledgeCapsuleId = 0;
    uint256 public minContributionForProposal = 100; // Min score required to propose a capsule
    uint256 public knowledgeCapsuleActivationThreshold = 70; // % of (upvotes / (upvotes + downvotes))
    uint256 public knowledgeCapsuleDeactivationThreshold = 30; // % for active capsule to be deactivated

    Intent[] public intents;
    uint256 public nextIntentId = 0;

    TreasuryAllocation[] public treasuryAllocations;
    uint256 public nextTreasuryAllocationId = 0;
    uint256 public treasuryAllocationApprovalThreshold = 60; // % for treasury allocation approval

    // --- Events ---
    event ParticipantRegistered(address indexed participant);
    event ContributionScoreUpdated(address indexed participant, uint256 newScore, string reason);
    event ContributionDelegated(address indexed delegator, address indexed delegatee);
    event DelegationRevoked(address indexed delegator);

    event KnowledgeCapsuleProposed(uint256 indexed capsuleId, address indexed creator, string ipfsHash);
    event KnowledgeCapsuleVoted(uint256 indexed capsuleId, address indexed voter, bool _for, uint256 upvotes, uint256 downvotes);
    event KnowledgeCapsuleStatusChanged(uint256 indexed capsuleId, KnowledgeCapsuleStatus oldStatus, KnowledgeCapsuleStatus newStatus);
    event KnowledgeCapsuleDisputed(uint256 indexed capsuleId, address indexed disputer, string reason);
    event KnowledgeCapsuleDisputeResolved(uint256 indexed capsuleId, bool validDispute, KnowledgeCapsuleStatus newStatus);

    event IntentSubmitted(uint256 indexed intentId, address indexed caller, IntentType _type);
    event IntentFulfilled(uint256 indexed intentId, address indexed executor, uint256 resolutionCapsuleId);
    event IntentRejected(uint256 indexed intentId, string reason);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event TreasuryAllocationProposed(uint256 indexed allocationId, address indexed proposer, uint256 amount, address recipient, string purpose);
    event TreasuryAllocationVoted(uint256 indexed allocationId, address indexed voter, bool _for);
    event TreasuryAllocationExecuted(uint256 indexed allocationId, uint256 amount, address recipient);

    // --- Modifiers ---
    modifier onlyParticipant() {
        if (!participantProfiles[msg.sender].isRegistered) {
            revert NotRegistered();
        }
        _;
    }

    modifier onlyRegisteredForProposal() {
        if (getEffectiveContributionScore(msg.sender) < minContributionForProposal) {
            revert InsufficientContributionScore(minContributionForProposal, getEffectiveContributionScore(msg.sender));
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        // Initial owner is set by Ownable contract
        // Add initial Nexus Participant (the owner)
        participantProfiles[msg.sender].isRegistered = true;
        participantProfiles[msg.sender].contributionScore = 1000; // Give owner a high initial score
        registeredParticipants.push(msg.sender);
        emit ParticipantRegistered(msg.sender);
        emit ContributionScoreUpdated(msg.sender, 1000, "Initial registration as owner");
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses core operations in an emergency. Only owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resumes core operations. Only owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the minimum contribution score required to propose a knowledge capsule.
     * @param _newMinScore The new minimum score.
     */
    function setMinContributionForProposal(uint256 _newMinScore) external onlyOwner {
        minContributionForProposal = _newMinScore;
    }

    /**
     * @dev Sets the percentage thresholds for activating and deactivating Knowledge Capsules.
     * @param _activation The percentage of upvotes required for activation (e.g., 70 for 70%).
     * @param _deactivation The percentage of upvotes below which an active capsule is deactivated (e.g., 30 for 30%).
     */
    function setVoteThresholds(uint256 _activation, uint256 _deactivation) external onlyOwner {
        require(_activation <= 100 && _deactivation <= 100, "Thresholds must be percentages (0-100)");
        knowledgeCapsuleActivationThreshold = _activation;
        knowledgeCapsuleDeactivationThreshold = _deactivation;
    }

    // --- II. Participant & Contribution Score Management ---

    /**
     * @dev Allows any address to register as a participant in the Aetherial Nexus.
     *      Initial contribution score is 0.
     */
    function registerParticipant() external whenNotPaused {
        if (participantProfiles[msg.sender].isRegistered) {
            revert AlreadyRegistered();
        }
        participantProfiles[msg.sender].isRegistered = true;
        registeredParticipants.push(msg.sender);
        emit ParticipantRegistered(msg.sender);
        emit ContributionScoreUpdated(msg.sender, 0, "Initial registration");
    }

    /**
     * @dev Retrieves a participant's profile details.
     * @param _participant The address of the participant.
     * @return ParticipantProfile struct containing score, last activity, and delegation.
     */
    function getParticipantProfile(address _participant) public view returns (ParticipantProfile memory) {
        return participantProfiles[_participant];
    }

    /**
     * @dev Delegates a participant's effective contribution score to another participant.
     * @param _delegatee The address to delegate the score to.
     */
    function delegateContributionScore(address _delegatee) external onlyParticipant whenNotPaused {
        if (_delegatee == address(0) || _delegatee == msg.sender) {
            revert SelfDelegationNotAllowed();
        }
        if (!participantProfiles[_delegatee].isRegistered) {
            revert InvalidDelegationTarget();
        }

        ParticipantProfile storage delegatorProfile = participantProfiles[msg.sender];
        if (delegatorProfile.delegatedTo != address(0)) {
            // Revoke old delegation first if any, to avoid double counting
            _revokeDelegationInternal(msg.sender, delegatorProfile.delegatedTo);
        }

        delegatorProfile.delegatedTo = _delegatee;
        emit ContributionDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active delegation of a participant's contribution score.
     */
    function revokeDelegation() external onlyParticipant whenNotPaused {
        ParticipantProfile storage delegatorProfile = participantProfiles[msg.sender];
        if (delegatorProfile.delegatedTo == address(0)) {
            revert NoActiveDelegation();
        }
        _revokeDelegationInternal(msg.sender, delegatorProfile.delegatedTo);
    }

    /**
     * @dev Internal function to handle the actual revocation logic.
     * @param _delegator The address of the delegator.
     * @param _delegatee The address of the delegatee.
     */
    function _revokeDelegationInternal(address _delegator, address _delegatee) internal {
        // This is where actual effective score deduction would happen if using active sums
        // For simplicity, this simply clears the delegation link.
        participantProfiles[_delegator].delegatedTo = address(0);
        emit DelegationRevoked(_delegator);
    }

    /**
     * @dev Internal function to update a participant's contribution score.
     *      Called by other functions as rewards for positive actions.
     * @param _participant The address whose score is to be updated.
     * @param _amount The amount to add to the score.
     */
    function _updateContributionScore(address _participant, uint256 _amount) internal {
        // Only registered participants can have scores
        if (!participantProfiles[_participant].isRegistered) {
            return;
        }
        participantProfiles[_participant].contributionScore = participantProfiles[_participant].contributionScore.add(_amount);
        participantProfiles[_participant].lastActivityTimestamp = block.timestamp;
        emit ContributionScoreUpdated(_participant, participantProfiles[_participant].contributionScore, "Action rewarded");
    }

    /**
     * @dev Gets the effective contribution score for a participant, considering delegation.
     *      If a participant has delegated their score, their own score is effectively 0 for voting/proposing,
     *      and their score contributes to the delegatee's effective score.
     * @param _participant The address to get the effective score for.
     * @return The effective contribution score.
     */
    function getEffectiveContributionScore(address _participant) public view returns (uint256) {
        // If a participant has delegated, their direct voting power is 0 for this check.
        // The delegatee's score calculation would sum up all delegated scores.
        // For this simplified example, we'll assume a direct lookup unless delegated.
        // A more complex system would recursively sum delegated scores.
        ParticipantProfile storage profile = participantProfiles[_participant];
        if (!profile.isRegistered) {
            return 0;
        }

        // Check if this participant is a delegatee for anyone.
        uint256 delegatedScore = 0;
        for (uint i = 0; i < registeredParticipants.length; i++) {
            if (participantProfiles[registeredParticipants[i]].delegatedTo == _participant) {
                delegatedScore = delegatedScore.add(participantProfiles[registeredParticipants[i]].contributionScore);
            }
        }
        return profile.contributionScore.add(delegatedScore);
    }

    // --- III. Knowledge Capsule Management (The Protocol's Brain) ---

    /**
     * @dev Allows participants with sufficient contribution score to propose a new Knowledge Capsule.
     * @param _ipfsContentHash An IPFS hash pointing to the detailed content/logic of the capsule (e.g., Markdown, code snippet).
     * @param _description A brief, on-chain description of the capsule's purpose.
     */
    function proposeKnowledgeCapsule(string calldata _ipfsContentHash, string calldata _description)
        external
        onlyRegisteredForProposal
        whenNotPaused
    {
        knowledgeCapsules.push(KnowledgeCapsule({
            id: nextKnowledgeCapsuleId,
            creator: msg.sender,
            ipfsContentHash: _ipfsContentHash,
            description: _description,
            status: KnowledgeCapsuleStatus.Proposed,
            upvotes: 0,
            downvotes: 0,
            creationTimestamp: block.timestamp,
            isInDispute: false
        }));
        nextKnowledgeCapsuleId++;
        _updateContributionScore(msg.sender, 5); // Reward for proposing
        emit KnowledgeCapsuleProposed(nextKnowledgeCapsuleId - 1, msg.sender, _ipfsContentHash);
    }

    /**
     * @dev Allows participants to vote on a proposed Knowledge Capsule.
     *      Votes are weighted by the participant's effective contribution score.
     * @param _capsuleId The ID of the capsule to vote on.
     * @param _for True for an upvote, false for a downvote.
     */
    function voteOnKnowledgeCapsule(uint256 _capsuleId, bool _for) external onlyParticipant whenNotPaused {
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];

        if (capsule.status != KnowledgeCapsuleStatus.Proposed && capsule.status != KnowledgeCapsuleStatus.Active) {
            revert InvalidKnowledgeCapsuleStatus(); // Can only vote on proposed or active (for deactivation)
        }
        if (capsule.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }
        if (capsule.isInDispute) {
            revert DisputedCapsule();
        }

        uint256 voterScore = getEffectiveContributionScore(msg.sender);
        require(voterScore > 0, "Voter must have positive effective contribution score");

        if (_for) {
            capsule.upvotes = capsule.upvotes.add(voterScore);
        } else {
            capsule.downvotes = capsule.downvotes.add(voterScore);
        }
        capsule.hasVoted[msg.sender] = true;

        _updateContributionScore(msg.sender, 1); // Reward for voting
        emit KnowledgeCapsuleVoted(_capsuleId, msg.sender, _for, capsule.upvotes, capsule.downvotes);
    }

    /**
     * @dev Activates a Knowledge Capsule if it meets the activation threshold.
     *      Can be called by any participant after voting period.
     * @param _capsuleId The ID of the capsule to activate.
     */
    function activateKnowledgeCapsule(uint256 _capsuleId) external onlyParticipant whenNotPaused {
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.status != KnowledgeCapsuleStatus.Proposed) {
            revert InvalidKnowledgeCapsuleStatus();
        }
        if (capsule.isInDispute) {
            revert DisputedCapsule();
        }

        uint256 totalVotes = capsule.upvotes.add(capsule.downvotes);
        if (totalVotes == 0) {
            revert NotEnoughVotes(1, 0); // Need at least one vote to activate
        }

        uint256 upvotePercentage = capsule.upvotes.mul(100).div(totalVotes);

        if (upvotePercentage >= knowledgeCapsuleActivationThreshold) {
            capsule.status = KnowledgeCapsuleStatus.Active;
            emit KnowledgeCapsuleStatusChanged(_capsuleId, KnowledgeCapsuleStatus.Proposed, KnowledgeCapsuleStatus.Active);
            _updateContributionScore(msg.sender, 2); // Reward for activating
        } else {
            revert NotEnoughVotes(knowledgeCapsuleActivationThreshold, upvotePercentage);
        }
    }

    /**
     * @dev Deactivates an active Knowledge Capsule if it falls below the deactivation threshold.
     *      Can be called by any participant.
     * @param _capsuleId The ID of the capsule to deactivate.
     */
    function deactivateKnowledgeCapsule(uint256 _capsuleId) external onlyParticipant whenNotPaused {
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        if (capsule.status != KnowledgeCapsuleStatus.Active) {
            revert InvalidKnowledgeCapsuleStatus();
        }
        if (capsule.isInDispute) {
            revert DisputedCapsule();
        }

        uint256 totalVotes = capsule.upvotes.add(capsule.downvotes);
        if (totalVotes == 0) { // If it was active with no downvotes, but then downvotes started
            return; // No change based on votes yet
        }

        uint256 upvotePercentage = capsule.upvotes.mul(100).div(totalVotes);

        if (upvotePercentage < knowledgeCapsuleDeactivationThreshold) {
            capsule.status = KnowledgeCapsuleStatus.Rejected; // Deactivate to 'Rejected'
            emit KnowledgeCapsuleStatusChanged(_capsuleId, KnowledgeCapsuleStatus.Active, KnowledgeCapsuleStatus.Rejected);
            _updateContributionScore(msg.sender, 2); // Reward for deactivating harmful capsule
        } else {
            revert NotEnoughVotes(knowledgeCapsuleDeactivationThreshold, upvotePercentage);
        }
    }

    /**
     * @dev Retrieves details of a specific Knowledge Capsule.
     * @param _capsuleId The ID of the capsule.
     * @return Tuple containing capsule details.
     */
    function getKnowledgeCapsuleDetails(uint256 _capsuleId)
        public
        view
        returns (
            uint256 id,
            address creator,
            string memory ipfsContentHash,
            string memory description,
            KnowledgeCapsuleStatus status,
            uint256 upvotes,
            uint256 downvotes,
            uint256 creationTimestamp,
            bool isInDispute
        )
    {
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        return (
            capsule.id,
            capsule.creator,
            capsule.ipfsContentHash,
            capsule.description,
            capsule.status,
            capsule.upvotes,
            capsule.downvotes,
            capsule.creationTimestamp,
            capsule.isInDispute
        );
    }

    /**
     * @dev Retrieves a list of Knowledge Capsule IDs filtered by their status.
     * @param _status The desired status (Proposed, Active, Rejected, Disputed).
     * @return An array of capsule IDs.
     */
    function getKnowledgeCapsulesByStatus(KnowledgeCapsuleStatus _status)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory filteredCapsules = new uint256[](nextKnowledgeCapsuleId);
        uint256 counter = 0;
        for (uint256 i = 0; i < nextKnowledgeCapsuleId; i++) {
            if (knowledgeCapsules[i].status == _status) {
                filteredCapsules[counter] = i;
                counter++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = filteredCapsules[i];
        }
        return result;
    }

    /**
     * @dev Allows a participant to submit a dispute against a Knowledge Capsule.
     *      Marks the capsule as 'Disputed' and halts further voting/activation until resolved.
     * @param _capsuleId The ID of the capsule to dispute.
     * @param _reason A string explaining the reason for the dispute.
     */
    function submitKnowledgeCapsuleDispute(uint256 _capsuleId, string calldata _reason) external onlyParticipant whenNotPaused {
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(!capsule.isInDispute, "Capsule is already in dispute.");
        require(capsule.status != KnowledgeCapsuleStatus.Rejected, "Cannot dispute a rejected capsule.");

        capsule.isInDispute = true;
        KnowledgeCapsuleStatus oldStatus = capsule.status;
        capsule.status = KnowledgeCapsuleStatus.Disputed;
        _updateContributionScore(msg.sender, 3); // Reward for vigilance
        emit KnowledgeCapsuleDisputed(_capsuleId, msg.sender, _reason);
        emit KnowledgeCapsuleStatusChanged(_capsuleId, oldStatus, KnowledgeCapsuleStatus.Disputed);
    }

    /**
     * @dev Resolves a dispute for a Knowledge Capsule. Only owner can resolve (could be DAO vote in future).
     * @param _capsuleId The ID of the disputed capsule.
     * @param _validDispute True if the dispute is valid (capsule should be rejected/re-evaluated), false otherwise.
     */
    function resolveKnowledgeCapsuleDispute(uint256 _capsuleId, bool _validDispute) external onlyOwner { // TODO: Make this a governance/vote-based function
        if (_capsuleId >= nextKnowledgeCapsuleId) {
            revert KnowledgeCapsuleNotFound();
        }
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.status == KnowledgeCapsuleStatus.Disputed, "Capsule is not in dispute.");
        require(capsule.isInDispute, "Capsule not marked as in dispute.");

        capsule.isInDispute = false;
        KnowledgeCapsuleStatus oldStatus = capsule.status;
        if (_validDispute) {
            capsule.status = KnowledgeCapsuleStatus.Rejected; // If dispute valid, reject the capsule
        } else {
            // If dispute invalid, revert to its previous status (Proposed or Active).
            // This requires storing previous status, or a more nuanced logic.
            // For simplicity, we'll revert to Proposed if it was proposed, or Active otherwise.
            // A production system might save the status before dispute.
            capsule.status = (capsule.upvotes.mul(100).div(capsule.upvotes.add(capsule.downvotes))) >= knowledgeCapsuleActivationThreshold ? KnowledgeCapsuleStatus.Active : KnowledgeCapsuleStatus.Proposed;
        }
        emit KnowledgeCapsuleDisputeResolved(_capsuleId, _validDispute, capsule.status);
        emit KnowledgeCapsuleStatusChanged(_capsuleId, oldStatus, capsule.status);
    }

    // --- IV. Intent & Execution Engine ---

    /**
     * @dev Allows a participant to submit an Intent (a desired action/outcome) to the protocol.
     *      The protocol will attempt to fulfill this intent based on its active Knowledge Capsules.
     * @param _type The type of intent (e.g., TreasuryTransfer, ProtocolParameterUpdate).
     * @param _target The target address for the intent (e.g., recipient for transfer).
     * @param _value The value associated with the intent (e.g., amount for transfer, new parameter value).
     * @param _data Additional arbitrary data for complex intents (e.g., function call data).
     */
    function submitIntent(IntentType _type, address _target, uint256 _value, bytes calldata _data)
        external
        onlyParticipant
        whenNotPaused
    {
        intents.push(Intent({
            id: nextIntentId,
            caller: msg.sender,
            intentType: _type,
            targetAddress: _target,
            value: _value,
            data: _data,
            status: IntentStatus.Pending,
            resolutionCapsuleId: 0, // Will be set upon fulfillment
            rejectionReason: ""
        }));
        nextIntentId++;
        _updateContributionScore(msg.sender, 2); // Reward for submitting intent
        emit IntentSubmitted(nextIntentId - 1, msg.sender, _type);
    }

    /**
     * @dev Internal function to evaluate an intent based on active Knowledge Capsules.
     *      This is the "AI-assisted" part: the protocol processes logic from dynamic rules.
     *      NOTE: In a real system, this would involve complex logic derived from `ipfsContentHash`.
     *      For this example, it's a placeholder for future on-chain reasoning engine.
     * @param _intentId The ID of the intent to evaluate.
     * @return True if the intent is deemed fulfillable by the active capsules, false otherwise.
     */
    function _evaluateIntent(uint256 _intentId) internal view returns (bool, uint256) {
        // This is where the core "intelligence" would reside.
        // In a real system, this would:
        // 1. Iterate through active Knowledge Capsules.
        // 2. Parse their `ipfsContentHash` (e.g., pointing to on-chain verifiable logic, a state machine, or an oracle's verifiable output).
        // 3. Apply the logic of the capsules to the current intent and protocol state.
        // 4. Return true if the intent aligns with *all* currently active and relevant capsules' rules.

        // Placeholder logic: For demonstration, let's say an intent is fulfillable
        // if *any* active capsule explicitly mentions `IntentType.CustomAction` and its ID is even.
        // This simulates a "rule" being active.
        Intent storage currentIntent = intents[_intentId];
        uint256 resolvingCapsuleId = 0;
        bool isFulfillable = false;

        for (uint256 i = 0; i < nextKnowledgeCapsuleId; i++) {
            KnowledgeCapsule storage capsule = knowledgeCapsules[i];
            if (capsule.status == KnowledgeCapsuleStatus.Active) {
                // This is where the "knowledge" is applied.
                // Imagine the `ipfsContentHash` contains executable logic.
                // For this demo, let's have a simple conceptual check:
                if (currentIntent.intentType == IntentType.CustomAction && capsule.id % 2 == 0) {
                    // A simple rule: If intent is CustomAction and an even-ID capsule is active
                    isFulfillable = true;
                    resolvingCapsuleId = capsule.id;
                    break; // Found a rule that validates it
                }
                // Add more complex conditional logic based on capsule.ipfsContentHash or capsule.description here.
                // e.g., if capsule.description contains "Approve specific action X" and intent is X, then true.
            }
        }
        return (isFulfillable, resolvingCapsuleId);
    }

    /**
     * @dev Attempts to fulfill a submitted intent if it passes evaluation by active Knowledge Capsules.
     *      Only callable by participants, triggering the internal evaluation.
     * @param _intentId The ID of the intent to fulfill.
     */
    function fulfillIntent(uint256 _intentId) external onlyParticipant whenNotPaused {
        if (_intentId >= nextIntentId) {
            revert IntentNotFound();
        }
        Intent storage currentIntent = intents[_intentId];
        require(currentIntent.status == IntentStatus.Pending, "Intent is not pending.");

        (bool canFulfill, uint256 resolvingCapsuleId) = _evaluateIntent(_intentId);

        if (canFulfill) {
            currentIntent.status = IntentStatus.Fulfilled;
            currentIntent.resolutionCapsuleId = resolvingCapsuleId;
            // Execute the intent based on its type
            if (currentIntent.intentType == IntentType.TreasuryTransfer) {
                // Note: Actual transfer logic for treasury is separate (TreasuryAllocation)
                // This would trigger internal logic for transfer from this contract if it were directly holding funds.
                // For this example, this simply marks the intent as fulfilled.
                // A real system might call an external treasury contract or manage its own.
                // bytes memory callData = abi.encodeWithSignature("transfer(address,uint256)", currentIntent.targetAddress, currentIntent.value);
                // (bool success, ) = address(this).call(callData);
                // require(success, "Treasury transfer failed");
            } else if (currentIntent.intentType == IntentType.ProtocolParameterUpdate) {
                // Example: Update a protocol parameter based on intent.
                // This would be highly sensitive and require strong Knowledge Capsule validation.
                // if (currentIntent.targetAddress == address(this) && currentIntent.data.length > 0) {
                //     (bool success, ) = address(this).call(currentIntent.data);
                //     require(success, "Parameter update failed");
                // }
            } else if (currentIntent.intentType == IntentType.CustomAction) {
                // This is where generic external calls or internal logic could be triggered.
                // (bool success, ) = currentIntent.targetAddress.call{value: currentIntent.value}(currentIntent.data);
                // require(success, "Custom action failed");
            }
            _updateContributionScore(msg.sender, 5); // Reward for fulfilling
            emit IntentFulfilled(_intentId, msg.sender, resolvingCapsuleId);
        } else {
            currentIntent.status = IntentStatus.Rejected;
            currentIntent.rejectionReason = "Not validated by active Knowledge Capsules.";
            emit IntentRejected(_intentId, "Not validated by active Knowledge Capsules.");
            revert IntentNotFulfillable();
        }
    }

    /**
     * @dev Explicitly rejects a pending intent. Could be called by a governance function.
     * @param _intentId The ID of the intent to reject.
     * @param _reason The reason for rejection.
     */
    function rejectIntent(uint256 _intentId, string calldata _reason) external onlyOwner { // Or by a vote-based governance decision
        if (_intentId >= nextIntentId) {
            revert IntentNotFound();
        }
        Intent storage currentIntent = intents[_intentId];
        require(currentIntent.status == IntentStatus.Pending, "Intent is not pending.");

        currentIntent.status = IntentStatus.Rejected;
        currentIntent.rejectionReason = _reason;
        emit IntentRejected(_intentId, _reason);
    }

    /**
     * @dev Retrieves the details of a specific intent.
     * @param _intentId The ID of the intent.
     * @return Tuple containing intent details.
     */
    function getIntentDetails(uint256 _intentId)
        public
        view
        returns (
            uint256 id,
            address caller,
            IntentType intentType,
            address targetAddress,
            uint256 value,
            bytes memory data,
            IntentStatus status,
            uint256 resolutionCapsuleId,
            string memory rejectionReason
        )
    {
        if (_intentId >= nextIntentId) {
            revert IntentNotFound();
        }
        Intent storage currentIntent = intents[_intentId];
        return (
            currentIntent.id,
            currentIntent.caller,
            currentIntent.intentType,
            currentIntent.targetAddress,
            currentIntent.value,
            currentIntent.data,
            currentIntent.status,
            currentIntent.resolutionCapsuleId,
            currentIntent.rejectionReason
        );
    }

    // --- V. Adaptive Treasury Management ---

    /**
     * @dev Allows users to deposit funds (ETH/native token) into the protocol's treasury.
     */
    function depositToTreasury() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows participants to propose an allocation of treasury funds.
     * @param _purpose A description of the allocation's purpose.
     * @param _amount The amount of funds to allocate.
     * @param _recipient The recipient address for the funds.
     */
    function proposeTreasuryAllocation(string calldata _purpose, uint256 _amount, address _recipient)
        external
        onlyRegisteredForProposal
        whenNotPaused
    {
        require(_amount > 0, "Amount must be greater than zero.");
        if (address(this).balance < _amount) {
            revert InsufficientTreasuryBalance(_amount, address(this).balance);
        }

        treasuryAllocations.push(TreasuryAllocation({
            id: nextTreasuryAllocationId,
            purpose: _purpose,
            amount: _amount,
            recipient: _recipient,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            executed: false
        }));
        nextTreasuryAllocationId++;
        _updateContributionScore(msg.sender, 4); // Reward for proposing allocation
        emit TreasuryAllocationProposed(nextTreasuryAllocationId - 1, msg.sender, _amount, _recipient, _purpose);
    }

    /**
     * @dev Allows participants to vote on a proposed treasury allocation.
     *      Votes are weighted by effective contribution score.
     * @param _allocationId The ID of the allocation proposal.
     * @param _for True for an upvote, false for a downvote.
     */
    function voteOnTreasuryAllocation(uint256 _allocationId, bool _for) external onlyParticipant whenNotPaused {
        if (_allocationId >= nextTreasuryAllocationId) {
            revert AllocationNotFound();
        }
        TreasuryAllocation storage allocation = treasuryAllocations[_allocationId];
        require(!allocation.executed, "Allocation already executed.");
        if (allocation.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }

        uint256 voterScore = getEffectiveContributionScore(msg.sender);
        require(voterScore > 0, "Voter must have positive effective contribution score.");

        if (_for) {
            allocation.upvotes = allocation.upvotes.add(voterScore);
        } else {
            allocation.downvotes = allocation.downvotes.add(voterScore);
        }
        allocation.hasVoted[msg.sender] = true;

        _updateContributionScore(msg.sender, 1); // Reward for voting
        emit TreasuryAllocationVoted(_allocationId, msg.sender, _for);
    }

    /**
     * @dev Executes a treasury allocation if it has passed the approval threshold.
     * @param _allocationId The ID of the allocation to execute.
     */
    function executeTreasuryAllocation(uint256 _allocationId) external onlyParticipant whenNotPaused {
        if (_allocationId >= nextTreasuryAllocationId) {
            revert AllocationNotFound();
        }
        TreasuryAllocation storage allocation = treasuryAllocations[_allocationId];
        require(!allocation.executed, "Allocation already executed.");

        uint256 totalVotes = allocation.upvotes.add(allocation.downvotes);
        require(totalVotes > 0, "No votes cast yet for this allocation.");

        uint256 approvalPercentage = allocation.upvotes.mul(100).div(totalVotes);

        if (approvalPercentage >= treasuryAllocationApprovalThreshold) {
            require(address(this).balance >= allocation.amount, "Insufficient treasury balance for execution.");

            allocation.executed = true;
            (bool success, ) = allocation.recipient.call{value: allocation.amount}("");
            require(success, "Treasury transfer failed during execution.");

            _updateContributionScore(msg.sender, 6); // Reward for executing
            emit TreasuryAllocationExecuted(_allocationId, allocation.amount, allocation.recipient);
        } else {
            revert AllocationNotApproved();
        }
    }

    /**
     * @dev Returns the current balance of the protocol's treasury.
     * @return The current balance in wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```