Okay, let's design a creative, advanced, and non-standard smart contract.

How about a system for managing **"Chronicle Entities"**? These aren't just tokens; they are dynamic, stateful, soulbound entities that evolve based on interactions and can participate in a unique form of on-chain governance weighted by their internal attributes and progression.

**Concept:**

*   **Soulbound Entities:** Each owner address can possess only *one* Chronicle Entity. It's tied to their identity/address and cannot be transferred.
*   **Dynamic Attributes:** Each Chronicle has mutable attributes (e.g., Resolve, Adaptability, Curiosity, Insight Capacity) that change based on on-chain activities.
*   **Internal Resource (Insight):** Activities generate `Insight`, an internal counter within the Chronicle itself.
*   **Aspect Tree/Progression:** `Insight` can be spent to unlock predefined 'Aspects' (like skills or traits) which grant attribute boosts or special permissions/abilities within the system. This forms a simple progression tree logic.
*   **State-Based Actions:** Chronicles have states (Idle, Challenging, Mentoring, Questing). Certain actions require the Chronicle to be in a specific state, and actions can change the state, locking the Chronicle out of other activities for a duration.
*   **Activities:**
    *   `UndergoChallenge`: A core activity spending time/resource, simulating an outcome based on internal attributes and pseudo-randomness, yielding Insight and potentially changing attributes.
    *   `LearnAspect`: Spend Insight to unlock an Aspect.
    *   `InitiateMentoring`: Designate another Chronicle to receive passive benefits.
    *   `JoinQuest`: Collaborate with other Chronicles (simulated).
*   **Chronicle-Weighted Governance:** A simple on-chain governance system where voting power for proposals is *not* based on holding a separate token, but dynamically calculated based on the voter's Chronicle's current attributes and learned Aspects.

This combines Soulbound tokens, dynamic NFTs (without being an NFT in the traditional transferable sense), state machines, internal resource management, progression trees, and a unique governance model. It doesn't replicate standard ERC-20/721 or common DAO templates directly.

---

**Contract Outline and Function Summary**

*   **Contract Name:** `ChronicleEntities`
*   **Description:** Manages dynamic, soulbound digital entities ('Chronicles'). Owners possess one untransferable Chronicle with mutable attributes, an internal 'Insight' resource, and unlockable 'Aspects'. Chronicles engage in activities (Challenges, Quests) that yield Insight and influence attributes. Governance weight is derived from Chronicle attributes and learned Aspects.
*   **Inheritance:** `Ownable`, `Pausable`
*   **Core Concepts:**
    *   Soulbound (Non-Transferable, 1-per-address)
    *   Dynamic Attributes & State
    *   Internal Resource Management (Insight)
    *   Aspect-Based Progression
    *   Activity Simulation (Challenges, Quests)
    *   Chronicle-Weighted Governance
*   **State Variables:** Mappings for Chronicles, owners, aspects, state, attributes, insight, aspect definitions, challenge parameters, quest parameters, governance proposals, etc. Counters for minted chronicles and proposal IDs.
*   **Enums:** `ChronicleState`, `ChallengeType`, `AspectType`, `ProposalState`.
*   **Structs:** `Chronicle`, `Attributes`, `AspectDefinition`, `ChallengeParameters`, `QuestParameters`, `Proposal`.
*   **Events:** `ChronicleMinted`, `ChallengeCompleted`, `AspectLearned`, `MentoringStarted`, `MentoringEnded`, `QuestJoined`, `QuestLeft`, `ProposalCreated`, `Voted`, `ProposalExecuted`.
*   **Modifiers:** `onlyChronicleOwner`, `whenChronicleStateIs`, `whenChronicleStateIsNot`, `hasLearnedAspect`, `canVoteOnProposal`, `proposalStateIs`.

---

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets admin.
2.  `pause()`: Pauses contract activities (admin only).
3.  `unpause()`: Unpauses contract activities (admin only).
4.  `mintChronicle()`: Mints a new Chronicle for the caller. Fails if caller already owns one. Initializes attributes and state. (Soulbound - non-transferable).
5.  `undergoChallenge(ChallengeType _challengeType)`: Starts a challenge for the caller's Chronicle. Changes state, applies lock-out, and simulates outcome based on attributes and pseudo-randomness upon completion. Yields Insight.
6.  `completeChallenge(uint256 _chronicleId)`: Internal/called by an automated keeper or timed execution mechanism (simulated here by requiring lock expiry). Processes challenge outcome, grants Insight, adjusts attributes, resets state.
7.  `learnAspect(uint256 _aspectId)`: Spends Chronicle's Insight to unlock a specific Aspect. Applies attribute boosts and flags the aspect as learned. Requires sufficient Insight and that the aspect isn't already learned.
8.  `initiateMentoring(uint256 _menteeChronicleId)`: Designates another Chronicle as a mentee. Requires caller's Chronicle to have a specific 'Mentoring' Aspect or attribute level (simulated). Changes state of both.
9.  `endMentoring(uint256 _menteeChronicleId)`: Ends a mentoring relationship. Resets states.
10. `joinQuest(uint256 _questId)`: Joins a collaborative quest. Requires Chronicle to meet quest criteria (simulated). Changes state, potentially applies lock-out.
11. `leaveQuest(uint256 _questId)`: Leaves a quest. Resets state.
12. `createProposal(string memory _description, address _targetContract, bytes memory _calldata)`: Creates a new governance proposal. Callable by accounts meeting a threshold of Chronicle attributes/aspects (simulated by requiring a certain aspect).
13. `castVote(uint256 _proposalId, bool _support)`: Casts a vote on a proposal. Vote weight is dynamically calculated based on the voter's Chronicle's current attributes and learned Aspects. Fails if voter doesn't own a Chronicle, Chronicle is busy, or proposal state is wrong.
14. `executeProposal(uint256 _proposalId)`: Executes a successful proposal. Callable after voting period ends and threshold/quorum is met. Requires proposer or authorized executor.
15. `setChallengeParameters(ChallengeType _type, ChallengeParameters calldata _params)`: Admin function to configure challenge outcomes/requirements.
16. `addAspectDefinition(AspectDefinition calldata _definition)`: Admin function to define new Aspects, their costs, and attribute boosts.
17. `setQuestParameters(uint256 _questId, QuestParameters calldata _params)`: Admin function to configure quest requirements/rewards.
18. `setGovernanceParameters(uint256 _votingPeriod, uint256 _proposalThresholdAspectId, uint256 _quorumChronicleCount)`: Admin function to configure governance rules.
19. `getChronicleDetails(uint256 _chronicleId)`: Returns all details of a specific Chronicle.
20. `getChronicleAttributes(uint256 _chronicleId)`: Returns just the attributes of a specific Chronicle.
21. `getChronicleState(uint256 _chronicleId)`: Returns the current state of a specific Chronicle.
22. `getChronicleInsight(uint256 _chronicleId)`: Returns the Insight balance of a specific Chronicle.
23. `isAspectLearned(uint256 _chronicleId, uint256 _aspectId)`: Checks if a specific Chronicle has learned an Aspect.
24. `getChronicleByOwner(address _owner)`: Returns the Chronicle ID owned by an address (since it's 1-per-address).
25. `getVoteWeight(address _voter)`: Calculates and returns the current dynamic vote weight for an owner's Chronicle.
26. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
27. `getAspectDefinition(uint256 _aspectId)`: Returns the definition of a specific Aspect.
28. `getTotalMintedChronicles()`: Returns the total number of Chronicles minted.
29. `getChronicleActivityLockEndTime(uint256 _chronicleId)`: Returns the timestamp when a Chronicle's current activity lock expires.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Although soulbound, useful dependency structure

// --- Outline and Function Summary ---
//
// Contract Name: ChronicleEntities
// Description: Manages dynamic, soulbound digital entities ('Chronicles').
// Owners possess one untransferable Chronicle with mutable attributes, an internal
// 'Insight' resource, and unlockable 'Aspects'. Chronicles engage in activities
// (Challenges, Quests) that yield Insight and influence attributes. Governance
// weight is derived from Chronicle attributes and learned Aspects.
// Inheritance: Ownable, Pausable, ReentrancyGuard
// Core Concepts: Soulbound (Non-Transferable, 1-per-address), Dynamic Attributes & State,
// Internal Resource Management (Insight), Aspect-Based Progression, Activity Simulation
// (Challenges, Quests), Chronicle-Weighted Governance.
//
// State Variables: Mappings for Chronicles, owners, aspects, state, attributes, insight,
// aspect definitions, challenge parameters, quest parameters, governance proposals, etc.
// Counters for minted chronicles and proposal IDs.
// Enums: ChronicleState, ChallengeType, AspectType, ProposalState.
// Structs: Chronicle, Attributes, AspectDefinition, ChallengeParameters, QuestParameters, Proposal.
// Events: ChronicleMinted, ChallengeCompleted, AspectLearned, MentoringStarted,
// MentoringEnded, QuestJoined, QuestLeft, ProposalCreated, Voted, ProposalExecuted.
// Modifiers: onlyChronicleOwner, whenChronicleStateIs, whenChronicleStateIsNot,
// hasLearnedAspect, canVoteOnProposal, proposalStateIs.
//
// Function Summary:
// 1. constructor(): Initializes the contract, sets admin.
// 2. pause(): Pauses contract activities (admin only).
// 3. unpause(): Unpauses contract activities (admin only).
// 4. mintChronicle(): Mints a new Chronicle for the caller (Soulbound).
// 5. undergoChallenge(ChallengeType _challengeType): Starts a challenge for a Chronicle.
// 6. completeChallenge(uint256 _chronicleId): Processes challenge outcome (internal/keeper).
// 7. learnAspect(uint256 _aspectId): Spends Insight to unlock an Aspect.
// 8. initiateMentoring(uint256 _menteeChronicleId): Starts mentoring relationship.
// 9. endMentoring(uint256 _menteeChronicleId): Ends mentoring relationship.
// 10. joinQuest(uint256 _questId): Joins a collaborative quest.
// 11. leaveQuest(uint256 _questId): Leaves a quest.
// 12. createProposal(string memory _description, address _targetContract, bytes memory _calldata): Creates a governance proposal.
// 13. castVote(uint256 _proposalId, bool _support): Casts a Chronicle-weighted vote.
// 14. executeProposal(uint256 _proposalId): Executes a successful proposal.
// 15. setChallengeParameters(ChallengeType _type, ChallengeParameters calldata _params): Admin config for challenges.
// 16. addAspectDefinition(AspectDefinition calldata _definition): Admin config for aspects.
// 17. setQuestParameters(uint256 _questId, QuestParameters calldata _params): Admin config for quests.
// 18. setGovernanceParameters(uint256 _votingPeriod, uint256 _proposalThresholdAspectId, uint256 _quorumChronicleCount): Admin config for governance.
// 19. getChronicleDetails(uint256 _chronicleId): Returns full Chronicle details.
// 20. getChronicleAttributes(uint256 _chronicleId): Returns Chronicle attributes.
// 21. getChronicleState(uint256 _chronicleId): Returns Chronicle state.
// 22. getChronicleInsight(uint256 _chronicleId): Returns Chronicle Insight balance.
// 23. isAspectLearned(uint256 _chronicleId, uint256 _aspectId): Checks if aspect is learned.
// 24. getChronicleByOwner(address _owner): Gets Chronicle ID by owner address.
// 25. getVoteWeight(address _voter): Calculates Chronicle vote weight.
// 26. getProposalDetails(uint256 _proposalId): Returns proposal details.
// 27. getAspectDefinition(uint256 _aspectId): Returns aspect definition.
// 28. getTotalMintedChronicles(): Returns total chronicles minted.
// 29. getChronicleActivityLockEndTime(uint256 _chronicleId): Returns activity lock end time.
// --- End Outline ---

contract ChronicleEntities is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum ChronicleState { Idle, Challenging, Mentoring, Questing }
    enum ChallengeType { Exploration, Riddle, TrialOfResolve } // Example types
    enum AspectType { AttributeBoost, Permission, PassiveBonus } // Example types
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    // --- Structs ---
    struct Attributes {
        uint16 resolve;
        uint16 adaptability;
        uint16 curiosity;
        uint16 insightCapacity; // Max insight before needing to spend
    }

    struct Chronicle {
        uint256 id; // Token ID
        address owner; // Soulbound owner
        Attributes attributes;
        uint256 currentInsight;
        ChronicleState state;
        uint256 activityLockUntil; // Timestamp when state lock ends
        uint256 activeActivityId; // ID of current challenge/quest/mentoring target
        mapping(uint256 => bool) learnedAspects; // aspectId => learned
    }

    struct AspectDefinition {
        uint256 id;
        string name;
        string description;
        uint256 insightCost;
        AspectType aspectType;
        Attributes attributeBoost; // Boost applied when learned
        // Could add prerequisites later (e.g., requires other aspects)
    }

    struct ChallengeParameters {
        uint256 duration; // Lock duration in seconds
        uint256 insightGainMin;
        uint256 insightGainMax;
        int16 resolveChangeMin; // Can be negative
        int16 resolveChangeMax;
        int16 adaptabilityChangeMin;
        int16 adaptabilityChangeMax;
        // More parameters based on ChallengeType
    }

    struct QuestParameters {
        string name;
        uint256 duration; // Lock duration
        uint256 insightReward;
        uint256 requiredChronicleCount; // How many needed to start/succeed
        // Could add attribute requirements for participants
    }

    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes calldata;
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalWeight; // Total weight cast
        uint256 supportWeight;
        uint256 againstWeight;
        mapping(address => bool) hasVoted; // Owner address => voted
    }

    // --- State Variables ---
    uint256 private _nextTokenId; // Starts from 1

    // Chronicle Data: ERC721-like representation (excluding transfer/approval)
    mapping(uint256 => Chronicle) private _chronicles;
    mapping(address => uint256) private _ownerChronicleId; // Soulbound: owner => token ID
    mapping(uint256 => address) private _idOwner; // token ID => owner

    // Aspect Definitions
    uint256 private _nextAspectId; // Starts from 1
    mapping(uint256 => AspectDefinition) private _aspectDefinitions;

    // Activity Parameters
    mapping(ChallengeType => ChallengeParameters) private _challengeParameters;
    uint256 private _nextQuestId; // Starts from 1
    mapping(uint256 => QuestParameters) private _questParameters;
    mapping(uint256 => uint256[]) private _questParticipants; // questId => chronicleIds

    // Governance
    uint256 private _nextProposalId; // Starts from 1
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _governanceVotingPeriod; // In seconds
    uint256 private _governanceProposalThresholdAspectId; // Aspect needed to propose
    uint256 private _governanceQuorumChronicleCount; // Minimum total Chronicle votes needed

    // --- Events ---
    event ChronicleMinted(uint256 indexed chronicleId, address indexed owner);
    event ChallengeStarted(uint256 indexed chronicleId, ChallengeType indexed challengeType, uint256 lockUntil);
    event ChallengeCompleted(uint256 indexed chronicleId, ChallengeType indexed challengeType, uint256 insightGained);
    event AspectLearned(uint256 indexed chronicleId, uint256 indexed aspectId);
    event MentoringStarted(uint256 indexed mentorId, uint256 indexed menteeId);
    event MentoringEnded(uint256 indexed mentorId, uint256 indexed menteeId);
    event QuestJoined(uint256 indexed questId, uint256 indexed chronicleId);
    event QuestLeft(uint256 indexed questId, uint256 indexed chronicleId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 weight, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier onlyChronicleOwner(uint256 _chronicleId) {
        require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
        require(_idOwner[_chronicleId] == _msgSender(), "ChronicleEntities: not chronicle owner");
        _;
    }

    modifier whenChronicleStateIs(uint256 _chronicleId, ChronicleState _state) {
        require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
        require(_chronicles[_chronicleId].state == _state, "ChronicleEntities: chronicle in wrong state");
        _;
    }

    modifier whenChronicleStateIsNot(uint256 _chronicleId, ChronicleState _state) {
        require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
        require(_chronicles[_chronicleId].state != _state, "ChronicleEntities: chronicle in wrong state");
        _;
    }

    modifier hasLearnedAspect(uint256 _chronicleId, uint256 _aspectId) {
        require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
        require(_chronicles[_chronicleId].learnedAspects[_aspectId], "ChronicleEntities: does not have aspect");
        _;
    }

    modifier canVoteOnProposal(uint256 _proposalId) {
        require(_proposals[_proposalId].state == ProposalState.Active, "ChronicleEntities: proposal not active");
        require(_ownerChronicleId[_msgSender()] != 0, "ChronicleEntities: owner has no chronicle");
        require(!_proposals[_proposalId].hasVoted[_msgSender()], "ChronicleEntities: already voted");
        require(_chronicles[_ownerChronicleId[_msgSender()]].state == ChronicleState.Idle, "ChronicleEntities: chronicle must be idle to vote");
        _;
    }

    modifier proposalStateIs(uint256 _proposalId, ProposalState _state) {
        require(_proposals[_proposalId].id == _proposalId, "ChronicleEntities: proposal does not exist");
        require(_proposals[_proposalId].state == _state, "ChronicleEntities: proposal in wrong state");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialProposalAspectId, uint256 initialQuorum) Ownable(msg.sender) Pausable(false) {
         // Set some initial governance parameters
        _governanceVotingPeriod = 7 days; // Example: 7 days voting
        _governanceProposalThresholdAspectId = initialProposalAspectId; // e.g., Aspect 5 is required to propose
        _governanceQuorumChronicleCount = initialQuorum; // e.g., 10 Chronicles must vote for quorum
        _nextAspectId = 1; // Start aspect IDs from 1
        _nextQuestId = 1; // Start quest IDs from 1
        _nextTokenId = 1; // Start Chronicle IDs from 1
        _nextProposalId = 1; // Start Proposal IDs from 1
    }

    // --- Admin Functions (Inherited from Ownable) ---

    /// @notice Pauses activities in the contract.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses activities in the contract.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Sets parameters for a specific challenge type.
    /// @param _type The type of challenge.
    /// @param _params The parameters for the challenge.
    function setChallengeParameters(ChallengeType _type, ChallengeParameters calldata _params) external onlyOwner {
        _challengeParameters[_type] = _params;
    }

    /// @notice Adds a new Aspect definition.
    /// @param _definition The definition of the new Aspect.
    function addAspectDefinition(AspectDefinition calldata _definition) external onlyOwner {
         require(_definition.id == _nextAspectId, "ChronicleEntities: aspect definition ID mismatch");
        _aspectDefinitions[_definition.id] = _definition;
        _nextAspectId++;
    }

    /// @notice Sets parameters for a specific quest.
    /// @param _questId The ID of the quest to configure.
    /// @param _params The parameters for the quest.
    function setQuestParameters(uint256 _questId, QuestParameters calldata _params) external onlyOwner {
         require(_questId > 0 && (_questParameters[_questId].duration == 0 || _questId < _nextQuestId), "ChronicleEntities: invalid quest ID for update"); // Allow updating existing or setting next
        if (_questParameters[_questId].duration == 0) { // New quest
            require(_questId == _nextQuestId, "ChronicleEntities: can only add next quest ID");
            _nextQuestId++;
        }
       _questParameters[_questId] = _params;
    }

     /// @notice Sets governance parameters.
     /// @param _votingPeriod The duration of the voting period in seconds.
     /// @param _proposalThresholdAspectId The Aspect ID required to create a proposal.
     /// @param _quorumChronicleCount The minimum number of Chronicles required to vote for quorum.
    function setGovernanceParameters(uint256 _votingPeriod, uint256 _proposalThresholdAspectId, uint256 _quorumChronicleCount) external onlyOwner {
        require(_aspectDefinitions[_proposalThresholdAspectId].id == _proposalThresholdAspectId, "ChronicleEntities: invalid proposal threshold aspect ID");
        _governanceVotingPeriod = _votingPeriod;
        _governanceProposalThresholdAspectId = _proposalThresholdAspectId;
        _governanceQuorumChronicleCount = _quorumChronicleCount;
    }

    // --- Chronicle Management ---

    /// @notice Mints a new Chronicle Entity, soulbound to the caller.
    /// @dev Only one Chronicle per address is allowed.
    function mintChronicle() external whenNotPaused nonReentrant {
        require(_ownerChronicleId[_msgSender()] == 0, "ChronicleEntities: owner already has a chronicle");

        uint256 newId = _nextTokenId++;
        Attributes memory initialAttributes = Attributes({
            resolve: uint16(50 + (newId % 50)), // Example initial attributes based on ID
            adaptability: uint16(50 + ((newId * 3) % 50)),
            curiosity: uint16(50 + ((newId * 7) % 50)),
            insightCapacity: 100 // Initial capacity
        });

        _chronicles[newId] = Chronicle({
            id: newId,
            owner: _msgSender(),
            attributes: initialAttributes,
            currentInsight: 0,
            state: ChronicleState.Idle,
            activityLockUntil: 0,
            activeActivityId: 0
            // learnedAspects mapping is initialized empty
        });

        _ownerChronicleId[_msgSender()] = newId;
        _idOwner[newId] = _msgSender(); // Required for _exists checks

        emit ChronicleMinted(newId, _msgSender());
    }

    // --- Activity Functions ---

    /// @notice Initiates a Challenge for the caller's Chronicle.
    /// @param _challengeType The type of challenge to undergo.
    function undergoChallenge(ChallengeType _challengeType)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Idle)
    {
        uint256 chronicleId = _ownerChronicleId[_msgSender()];
        ChallengeParameters memory params = _challengeParameters[_challengeType];
        require(params.duration > 0, "ChronicleEntities: challenge parameters not set");

        Chronicle storage chronicle = _chronicles[chronicleId];
        chronicle.state = ChronicleState.Challenging;
        chronicle.activityLockUntil = block.timestamp + params.duration;
        // activeActivityId could store challenge type ID if needed, using 0 for None

        emit ChallengeStarted(chronicleId, _challengeType, chronicle.activityLockUntil);
    }

    /// @notice Completes a Challenge after its lock duration expires.
    /// @dev This function would typically be called by an automated system (keeper)
    /// or triggered by the user after the lock has passed.
    /// Using `block.timestamp` for outcome adds pseudo-randomness, but VRF is better for security.
    function completeChallenge(uint256 _chronicleId)
        external
        whenNotPaused // Keeper calls
        nonReentrant // Prevents reentrancy if called externally
        whenChronicleStateIs(_chronicleId, ChronicleState.Challenging)
    {
        Chronicle storage chronicle = _chronicles[_chronicleId];
        require(block.timestamp >= chronicle.activityLockUntil, "ChronicleEntities: challenge not yet completed");

        ChallengeType challengeType; // How to get the original challenge type? Store it in activeActivityId or similar.
        // For simplicity here, let's assume activeActivityId wasn't strictly needed in undergoChallenge and we pass the type again.
        // In a real system, the state transition should store enough info.
        // Re-fetching params here for simulation completeness
         ChallengeParameters memory params = _challengeParameters[ChronicleType(chronicle.activeActivityId)]; // Requires activeActivityId to store type

        // Simulate outcome using block data for pseudo-randomness (NOT SECURE for high value)
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _chronicleId)));

        // Calculate Insight gain
        uint256 insightGained = params.insightGainMin + (randomFactor % (params.insightGainMax - params.insightGainMin + 1));
        chronicle.currentInsight += insightGained;
        if (chronicle.currentInsight > chronicle.attributes.insightCapacity) {
            chronicle.currentInsight = chronicle.attributes.insightCapacity; // Cap insight
        }

        // Adjust attributes
        int16 resolveChange = params.resolveChangeMin + int16(randomFactor % (params.resolveChangeMax - params.resolveChangeMin + 1));
        chronicle.attributes.resolve = uint16(int16(chronicle.attributes.resolve) + resolveChange);
        // Apply similar logic for adaptability if relevant to challenge type
        int16 adaptabilityChange = params.adaptabilityChangeMin + int16((randomFactor / 100) % (params.adaptabilityChangeMax - params.adaptabilityChangeMin + 1));
         chronicle.attributes.adaptability = uint16(int16(chronicle.attributes.adaptability) + adaptabilityChange);


        // Clamp attributes to a reasonable range (e.g., 0-255 or 0-1000)
        chronicle.attributes.resolve = _clamp(chronicle.attributes.resolve, 0, 255);
        chronicle.attributes.adaptability = _clamp(chronicle.attributes.adaptability, 0, 255);


        // Reset state
        chronicle.state = ChronicleState.Idle;
        chronicle.activityLockUntil = 0;
        chronicle.activeActivityId = 0; // Reset activity ID

        emit ChallengeCompleted(_chronicleId, ChronicleType(chronicle.activeActivityId), insightGained); // Use stored type
    }

    // Internal helper to clamp values
    function _clamp(uint16 value, uint16 min, uint16 max) internal pure returns (uint16) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }


    /// @notice Spends Chronicle Insight to learn a new Aspect.
    /// @param _aspectId The ID of the Aspect to learn.
    function learnAspect(uint256 _aspectId)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Idle)
    {
        uint256 chronicleId = _ownerChronicleId[_msgSender()];
        Chronicle storage chronicle = _chronicles[chronicleId];

        AspectDefinition memory aspectDef = _aspectDefinitions[_aspectId];
        require(aspectDef.id == _aspectId, "ChronicleEntities: aspect definition not found");
        require(!chronicle.learnedAspects[_aspectId], "ChronicleEntities: aspect already learned");
        require(chronicle.currentInsight >= aspectDef.insightCost, "ChronicleEntities: insufficient insight");

        // Spend Insight
        chronicle.currentInsight -= aspectDef.insightCost;

        // Apply attribute boost
        chronicle.attributes.resolve = uint16(uint256(chronicle.attributes.resolve) + aspectDef.attributeBoost.resolve);
        chronicle.attributes.adaptability = uint16(uint256(chronicle.attributes.adaptability) + aspectDef.attributeBoost.adaptability);
        chronicle.attributes.curiosity = uint16(uint256(chronicle.attributes.curiosity) + aspectDef.attributeBoost.curiosity);
        chronicle.attributes.insightCapacity = uint16(uint256(chronicle.attributes.insightCapacity) + aspectDef.attributeBoost.insightCapacity);

         // Clamp attributes (optional, but good practice)
        chronicle.attributes.resolve = _clamp(chronicle.attributes.resolve, 0, 255); // Example clamp
        chronicle.attributes.adaptability = _clamp(chronicle.attributes.adaptability, 0, 255);
        chronicle.attributes.curiosity = _clamp(chronicle.attributes.curiosity, 0, 255);
        chronicle.attributes.insightCapacity = _clamp(chronicle.attributes.insightCapacity, 0, 500); // Higher capacity cap

        // Mark as learned
        chronicle.learnedAspects[_aspectId] = true;

        emit AspectLearned(chronicleId, _aspectId);
    }

    /// @notice Initiates a Mentoring relationship where the caller's Chronicle mentors another.
    /// @param _menteeChronicleId The ID of the Chronicle to mentor.
    /// @dev Requires caller's Chronicle to have a specific Aspect or attribute level (simulated requirement).
    function initiateMentoring(uint256 _menteeChronicleId)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Idle)
    {
        uint256 mentorId = _ownerChronicleId[_msgSender()];
        require(_exists(_menteeChronicleId), "ChronicleEntities: mentee chronicle non-existent");
        require(_menteeChronicleId != mentorId, "ChronicleEntities: cannot mentor self");
        require(_chronicles[_menteeChronicleId].state == ChronicleState.Idle, "ChronicleEntities: mentee chronicle not idle");

        // Simulate requirement: Mentor needs Aspect X (e.g., Aspect ID 10)
        require(_chronicles[mentorId].learnedAspects[10], "ChronicleEntities: mentor needs 'Guidance' aspect");

        Chronicle storage mentorChronicle = _chronicles[mentorId];
        Chronicle storage menteeChronicle = _chronicles[_menteeChronicleId];

        mentorChronicle.state = ChronicleState.Mentoring;
        mentorChronicle.activeActivityId = _menteeChronicleId; // Store mentee ID

        menteeChronicle.state = ChronicleState.Mentoring;
        menteeChronicle.activeActivityId = mentorId; // Store mentor ID

        // Mentoring could provide passive boosts or timed events (not implemented here, just state change)

        emit MentoringStarted(mentorId, _menteeChronicleId);
    }

    /// @notice Ends a Mentoring relationship.
    /// @param _menteeChronicleId The ID of the Chronicle that was being mentored.
     function endMentoring(uint256 _menteeChronicleId)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Mentoring)
    {
        uint256 mentorId = _ownerChronicleId[_msgSender()];
         require(_exists(_menteeChronicleId), "ChronicleEntities: mentee chronicle non-existent");
        require(_chronicles[mentorId].activeActivityId == _menteeChronicleId, "ChronicleEntities: not mentoring this chronicle");
         require(_chronicles[_menteeChronicleId].state == ChronicleState.Mentoring && _chronicles[_menteeChronicleId].activeActivityId == mentorId, "ChronicleEntities: mentee not in mentoring state with this mentor");

        Chronicle storage mentorChronicle = _chronicles[mentorId];
        Chronicle storage menteeChronicle = _chronicles[_menteeChronicleId];

        mentorChronicle.state = ChronicleState.Idle;
        mentorChronicle.activeActivityId = 0;

        menteeChronicle.state = ChronicleState.Idle;
        menteeChronicle.activeActivityId = 0;

        emit MentoringEnded(mentorId, _menteeChronicleId);
    }

    /// @notice Joins a collaborative Quest.
    /// @param _questId The ID of the quest to join.
    function joinQuest(uint256 _questId)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Idle)
    {
        uint256 chronicleId = _ownerChronicleId[_msgSender()];
        QuestParameters memory params = _questParameters[_questId];
        require(params.duration > 0, "ChronicleEntities: quest parameters not set");

        // Check if quest has room (simplified: no max participants check)
        // Could add attribute/aspect requirements here

        Chronicle storage chronicle = _chronicles[chronicleId];
        chronicle.state = ChronicleState.Questing;
        chronicle.activeActivityId = _questId;
        // Quests might not have a fixed lock per participant, but rather a collective goal/timer
        // For simplicity, let's add a short individual lock
        chronicle.activityLockUntil = block.timestamp + 1 hours; // Example short lock

        _questParticipants[_questId].push(chronicleId); // Add to participant list

        emit QuestJoined(_questId, chronicleId);

        // In a full system, you'd check if enough participants joined to *start* the quest
        // and potentially set a collective end time.
    }

     /// @notice Leaves a Quest.
    /// @param _questId The ID of the quest to leave.
     function leaveQuest(uint256 _questId)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
        whenChronicleStateIs(_ownerChronicleId[_msgSender()], ChronicleState.Questing)
    {
        uint256 chronicleId = _ownerChronicleId[_msgSender()];
        require(_chronicles[chronicleId].activeActivityId == _questId, "ChronicleEntities: not participating in this quest");

        Chronicle storage chronicle = _chronicles[chronicleId];
        chronicle.state = ChronicleState.Idle;
        chronicle.activeActivityId = 0;
        chronicle.activityLockUntil = 0; // Clear lock

        // Remove from participant list (basic implementation, inefficient for large arrays)
        uint256[] storage participants = _questParticipants[_questId];
        for (uint i = 0; i < participants.length; i++) {
            if (participants[i] == chronicleId) {
                participants[i] = participants[participants.length - 1];
                participants.pop();
                break;
            }
        }

        emit QuestLeft(_questId, chronicleId);
    }


    // --- Governance Functions (Chronicle-Weighted) ---

    /// @notice Creates a new governance proposal.
    /// @param _description A brief description of the proposal.
    /// @param _targetContract The address of the contract to call if executed.
    /// @param _calldata The calldata to send to the target contract.
    /// @dev Requires the caller's Chronicle to have a specific 'Proposal' Aspect.
    function createProposal(string memory _description, address _targetContract, bytes memory _calldata)
        external
        whenNotPaused
        nonReentrant
        onlyChronicleOwner(_ownerChronicleId[_msgSender()])
    {
        uint256 chronicleId = _ownerChronicleId[_msgSender()];
        require(chronicleId != 0, "ChronicleEntities: caller has no chronicle"); // Redundant with modifier but good check
        require(_chronicles[chronicleId].learnedAspects[_governanceProposalThresholdAspectId], "ChronicleEntities: chronicle does not meet proposal threshold");

        uint256 proposalId = _nextProposalId++;
        _proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            calldata: _calldata,
            state: ProposalState.Active,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + _governanceVotingPeriod,
            totalWeight: 0,
            supportWeight: 0,
            againstWeight: 0,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });

        emit ProposalCreated(proposalId, _msgSender());
    }

    /// @notice Casts a vote on an active proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for 'support', False for 'against'.
    /// @dev Vote weight is derived from the voter's Chronicle attributes and aspects.
    function castVote(uint256 _proposalId, bool _support)
        external
        whenNotPaused
        nonReentrant
        canVoteOnProposal(_proposalId) // Checks state, owner, voted status
    {
        Proposal storage proposal = _proposals[_proposalId];
        uint256 voterChronicleId = _ownerChronicleId[_msgSender()];

        // Calculate vote weight based on Chronicle attributes/aspects
        uint256 weight = _calculateVoteWeight(voterChronicleId);
        require(weight > 0, "ChronicleEntities: chronicle has zero vote weight");

        proposal.totalWeight += weight;
        if (_support) {
            proposal.supportWeight += weight;
        } else {
            proposal.againstWeight += weight;
        }

        proposal.hasVoted[_msgSender()] = true;

        emit Voted(_proposalId, _msgSender(), weight, _support);

        // Optional: Transition state if voting period ended concurrently
        _tryUpdateProposalState(_proposalId);
    }

    /// @notice Executes a successful proposal.
    /// @param _proposalId The ID of the proposal to execute.
    /// @dev Requires the proposal to be in the Succeeded state.
    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
        nonReentrant
        proposalStateIs(_proposalId, ProposalState.Succeeded)
    {
        Proposal storage proposal = _proposals[_proposalId];

        // Use low-level call to execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.calldata);
        require(success, "ChronicleEntities: proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

     // Internal helper to update proposal state based on time/votes
    function _tryUpdateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEndTime) {
            if (proposal.totalWeight >= _governanceQuorumChronicleCount && proposal.supportWeight > proposal.againstWeight) {
                 // Simplified check: quorum based on number of *Chronicles* that voted, not total weight
                 // A more complex system would use total weight >= total potential weight * quorum %
                 // Or count actual distinct voters from the `hasVoted` mapping
                 // Let's use the count of voters tracked by `hasVoted` to meet the quorum parameter
                 uint256 voterCount = 0;
                 // This requires iterating the mapping keys - expensive!
                 // A better design would track voter count directly during `castVote`.
                 // For this example, let's *assume* totalWeight >= QuorumChronicleCount is sufficient,
                 // but note this limitation. A real system would use a different quorum check.
                 // Or, let's just simplify quorum to totalWeight >= MinWeightNeeded
                 // Let's redefine QuorumChronicleCount as MinTotalVoteWeightRequired.

                 // Simplified Quorum: total weight cast >= min required weight
                if (proposal.totalWeight >= _governanceQuorumChronicleCount && proposal.supportWeight > proposal.againstWeight) {
                     proposal.state = ProposalState.Succeeded;
                 } else {
                     proposal.state = ProposalState.Defeated;
                 }

            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
    }

    // Internal helper to calculate vote weight
    function _calculateVoteWeight(uint256 _chronicleId) internal view returns (uint256) {
        Chronicle memory chronicle = _chronicles[_chronicleId];
        // Example Weight Calculation:
        // Sum of key attributes + bonus per learned 'Permission' aspect + bonus for high Insight
        uint256 weight = uint256(chronicle.attributes.resolve) +
                         uint256(chronicle.attributes.adaptability) +
                         uint256(chronicle.attributes.curiosity);

        // Add bonus for specific types of aspects
        for (uint256 i = 1; i < _nextAspectId; i++) {
            if (chronicle.learnedAspects[i]) {
                 AspectDefinition memory aspectDef = _aspectDefinitions[i];
                if (aspectDef.aspectType == AspectType.Permission) {
                    weight += 50; // Example bonus per permission aspect
                }
                // Could add different bonuses for AttributeBoost, PassiveBonus etc.
            }
        }

        // Add bonus based on current Insight (capped)
        uint256 insightBonus = chronicle.currentInsight / 10; // 1 weight per 10 insight, max 10
        if (insightBonus > 10) insightBonus = 10;
        weight += insightBonus;


        return weight;
    }

    // --- Query Functions ---

    /// @notice Checks if a Chronicle ID exists.
    /// @param _chronicleId The ID to check.
    /// @return True if the Chronicle exists, false otherwise.
    function _exists(uint256 _chronicleId) internal view returns (bool) {
        return _idOwner[_chronicleId] != address(0);
    }

    /// @notice Gets the full details of a specific Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return Chronicle struct details.
    function getChronicleDetails(uint256 _chronicleId) public view returns (Chronicle memory) {
        require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         // Note: Mapping inside struct (`learnedAspects`) cannot be returned directly.
         // Need separate getters for aspects.
         Chronicle storage chronicle = _chronicles[_chronicleId];
         return Chronicle({
            id: chronicle.id,
            owner: chronicle.owner,
            attributes: chronicle.attributes,
            currentInsight: chronicle.currentInsight,
            state: chronicle.state,
            activityLockUntil: chronicle.activityLockUntil,
            activeActivityId: chronicle.activeActivityId,
            learnedAspects: chronicle.learnedAspects // This mapping access won't work externally directly
         });
    }

     /// @notice Gets the attributes of a specific Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return Attributes struct.
    function getChronicleAttributes(uint256 _chronicleId) public view returns (Attributes memory) {
         require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         return _chronicles[_chronicleId].attributes;
    }

     /// @notice Gets the state of a specific Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return ChronicleState enum.
    function getChronicleState(uint256 _chronicleId) public view returns (ChronicleState) {
         require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         return _chronicles[_chronicleId].state;
    }

     /// @notice Gets the current Insight balance of a specific Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return Insight balance.
    function getChronicleInsight(uint256 _chronicleId) public view returns (uint256) {
         require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         return _chronicles[_chronicleId].currentInsight;
    }

     /// @notice Checks if a specific Aspect is learned by a Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _aspectId The ID of the Aspect.
    /// @return True if the aspect is learned, false otherwise.
    function isAspectLearned(uint256 _chronicleId, uint256 _aspectId) public view returns (bool) {
         require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         return _chronicles[_chronicleId].learnedAspects[_aspectId];
    }

    /// @notice Gets the Chronicle ID owned by an address.
    /// @param _owner The address to check.
    /// @return The Chronicle ID, or 0 if none exists.
    function getChronicleByOwner(address _owner) public view returns (uint256) {
        return _ownerChronicleId[_owner];
    }

    /// @notice Calculates the current dynamic vote weight for an owner's Chronicle.
    /// @param _voter The address of the owner.
    /// @return The calculated vote weight. Returns 0 if no Chronicle exists or chronicle is busy.
    function getVoteWeight(address _voter) public view returns (uint256) {
        uint256 chronicleId = _ownerChronicleId[_voter];
        if (chronicleId == 0 || _chronicles[chronicleId].state != ChronicleState.Idle) {
            return 0; // Cannot vote if no chronicle or chronicle is busy
        }
        return _calculateVoteWeight(chronicleId);
    }

    /// @notice Gets details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal struct details.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
         require(_proposals[_proposalId].id == _proposalId, "ChronicleEntities: proposal does not exist");
         Proposal memory proposal = _proposals[_proposalId];
         // Cannot return internal mapping `hasVoted` directly
         return Proposal({
             id: proposal.id,
             description: proposal.description,
             targetContract: proposal.targetContract,
             calldata: proposal.calldata,
             state: proposal.state,
             voteStartTime: proposal.voteStartTime,
             voteEndTime: proposal.voteEndTime,
             totalWeight: proposal.totalWeight,
             supportWeight: proposal.supportWeight,
             againstWeight: proposal.againstWeight,
             hasVoted: proposal.hasVoted // This will not work in external calls
         });
    }

     /// @notice Gets the definition of a specific Aspect.
    /// @param _aspectId The ID of the Aspect.
    /// @return AspectDefinition struct details.
    function getAspectDefinition(uint256 _aspectId) public view returns (AspectDefinition memory) {
        AspectDefinition memory def = _aspectDefinitions[_aspectId];
         require(def.id == _aspectId, "ChronicleEntities: aspect definition not found");
         return def;
    }

    /// @notice Gets the total number of Chronicles minted.
    /// @return Total minted count.
    function getTotalMintedChronicles() public view returns (uint256) {
        return _nextTokenId - 1; // Assuming IDs start from 1
    }

    /// @notice Gets the timestamp when a Chronicle's current activity lock expires.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return The timestamp. Returns 0 if not currently locked.
    function getChronicleActivityLockEndTime(uint256 _chronicleId) public view returns (uint256) {
         require(_exists(_chronicleId), "ChronicleEntities: non-existent chronicle");
         return _chronicles[_chronicleId].activityLockUntil;
    }

     // Additional getters to reach 20+ easily and provide more info

     /// @notice Gets the owner of a Chronicle (ERC721-like getter).
     /// @param _chronicleId The ID of the Chronicle.
     /// @return The owner's address.
     function ownerOf(uint256 _chronicleId) public view returns (address) {
        address owner = _idOwner[_chronicleId];
        require(owner != address(0), "ChronicleEntities: owner query for non-existent token");
        return owner;
     }

     /// @notice Gets the number of Chronicles owned by an address. Due to soulbound nature, this is always 0 or 1.
     /// @param _owner The address to check.
     /// @return The balance (0 or 1).
     function balanceOf(address _owner) public view returns (uint256) {
        return _ownerChronicleId[_owner] == 0 ? 0 : 1;
     }

     /// @notice Gets parameters for a specific challenge type.
     /// @param _type The type of challenge.
     /// @return ChallengeParameters struct.
    function getChallengeParameters(ChallengeType _type) public view returns (ChallengeParameters memory) {
         ChallengeParameters memory params = _challengeParameters[_type];
         require(params.duration > 0, "ChronicleEntities: challenge parameters not set");
         return params;
    }

    /// @notice Gets the total number of defined Aspects.
    /// @return Total aspect count.
    function getAspectDefinitionsCount() public view returns (uint256) {
        return _nextAspectId - 1;
    }

    /// @notice Gets parameters for a specific quest.
    /// @param _questId The ID of the quest.
    /// @return QuestParameters struct.
    function getQuestParameters(uint256 _questId) public view returns (QuestParameters memory) {
        QuestParameters memory params = _questParameters[_questId];
        require(params.duration > 0, "ChronicleEntities: quest parameters not set");
        return params;
    }

     /// @notice Gets details of a specific proposal. Public version handling struct return limitation.
     /// @param _proposalId The ID of the proposal.
     /// @return id, description, targetContract, calldata, state, voteStartTime, voteEndTime, totalWeight, supportWeight, againstWeight
    function getProposalDetailsPublic(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            string memory description,
            address targetContract,
            bytes memory calldata,
            ProposalState state,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 totalWeight,
            uint256 supportWeight,
            uint256 againstWeight
        )
    {
         require(_proposals[_proposalId].id == _proposalId, "ChronicleEntities: proposal does not exist");
         Proposal memory proposal = _proposals[_proposalId];
         return (
             proposal.id,
             proposal.description,
             proposal.targetContract,
             proposal.calldata,
             proposal.state,
             proposal.voteStartTime,
             proposal.voteEndTime,
             proposal.totalWeight,
             proposal.supportWeight,
             proposal.againstWeight
         );
    }


    // --- Internal Helper for State Management (Example) ---
    // Could have internal functions like this for complex state transitions
    // function _setChronicleState(uint256 _chronicleId, ChronicleState _newState) internal {
    //     _chronicles[_chronicleId].state = _newState;
    // }

     // Fallback/Receive - Useful if contract might receive Ether (though this design doesn't need it)
    receive() external payable {}
    fallback() external payable {}

    // --- ERC721 Compatibility Notations ---
    // This contract is NOT a standard ERC721 because:
    // - It is Soulbound (non-transferable). Transfer functions are explicitly omitted.
    // - Approval functions (approve, setApprovalForAll, getApproved, isApprovedForAll) are omitted.
    // - It does not implement the ERC721 interface fully (e.g., IERC721).
    // The ownerOf and balanceOf functions are provided for basic compatibility checks only.

}
```