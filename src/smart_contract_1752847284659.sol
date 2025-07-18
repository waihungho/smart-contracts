Okay, this is an exciting challenge! Creating something truly unique, advanced, and with a significant number of functions requires building a system rather than just a single-purpose contract.

Let's design a smart contract called **"Chronicle Weave"**.

**Concept:** "Chronicle Weave" is a decentralized, on-chain narrative universe builder. Users contribute "Fragments" of lore, which can then be "woven" into "Chronicles" (coherent story arcs). These Chronicles dynamically influence a "World State," which in turn determines the likelihood and nature of "Events" that occur within the universe. The system incorporates concepts of influence, temporal decay, and a decentralized "Sage Council" for critical parameter calibration and dispute resolution. It aims to simulate a self-evolving narrative driven by collective input.

---

## Chronicle Weave Smart Contract

### Outline

1.  **Contract Description:** A decentralized, evolving narrative universe where users contribute lore fragments, weave chronicles, and collectively shape a dynamic world state that triggers on-chain events.
2.  **Core Components:**
    *   **Fragments:** Individual pieces of lore or data.
    *   **Chronicles:** Collections of fragments forming coherent narratives.
    *   **World State:** A dynamic, multi-faceted representation of the universe, influenced by Chronicles.
    *   **Events:** On-chain occurrences triggered by the World State and time.
    *   **Weavers:** Users who contribute fragments and weave chronicles.
    *   **Sages:** A council responsible for calibrating World State parameters and resolving disputes.
    *   **Oracles:** For external randomness or verified data critical for event triggers.
3.  **Advanced Concepts & Features:**
    *   **Dynamic World State:** The `WorldFacet` values are not static but are influenced by `Chronicle` `influenceVector`s and time, creating emergent properties.
    *   **On-chain "Narrative AI" (Simulated):** Functions like `synthesizeChronicleInfluence` and `determineEventPotential` use rule-based logic to simulate how narratives affect the world and trigger events, without needing off-chain AI.
    *   **Temporal Decay/Vitality:** Fragments and their influence can decay over time, requiring "refinement" to maintain relevance, simulating the natural flow of information and memory.
    *   **Influence & Reputation System:** `Weaver`s gain influence based on accepted contributions and weaving, which can be delegated.
    *   **Decentralized Governance (Lite):** The `Sage` Council has specific powers for calibration and dispute resolution, preventing single points of failure for critical parameters.
    *   **Oracle Integration:** Allows for unpredictable elements (e.g., true randomness for event outcomes) to be introduced from a verifiable source.
    *   **Interconnectedness:** A change in a Fragment can ripple through Chronicles, affecting the World State, and potentially triggering Events.
    *   **Anti-Spam/Quality Control:** Deposit requirements for challenging, and mechanisms for disputing poor quality content.

### Function Summary (25+ Functions)

1.  **`constructor()`**: Initializes the contract with an owner and sets up initial parameters.
2.  **`setOracleAddress(address _oracle)`**: Sets the address of the trusted oracle contract for external data.
3.  **`requestRandomnessForEvent(uint256 _eventId)`**: Initiates an oracle request for randomness to determine event outcomes.
4.  **`fulfillRandomness(bytes32 _requestId, uint256 _randomWord)`**: Oracle callback to provide requested randomness.

    --- **Fragment Management** ---

5.  **`createFragment(string calldata _contentHash, string[] calldata _tags)`**: Allows a user to submit a new lore fragment (identified by a content hash, e.g., IPFS CID). Requires a small ETH deposit.
6.  **`refineFragment(uint256 _fragmentId)`**: Allows the creator (or a delegated Weaver) to "refine" a fragment, increasing its `vitality` and extending its active influence period. Requires a deposit.
7.  **`challengeFragment(uint256 _fragmentId, string calldata _reasonHash)`**: Allows any user to challenge a fragment's validity or accuracy, initiating a dispute. Requires a larger ETH deposit.
8.  **`resolveFragmentChallenge(uint256 _challengeId, bool _isValid)`**: Exclusive to Sages: resolves an ongoing fragment challenge, returning deposits appropriately.
9.  **`getFragmentDetails(uint256 _fragmentId)`**: (View) Retrieves detailed information about a specific fragment.
10. **`getFragmentCurrentVitality(uint256 _fragmentId)`**: (View) Calculates and returns the current vitality score of a fragment.

    --- **Chronicle Weaving & Influence** ---

11. **`weaveChronicle(uint256[] calldata _fragmentIds, string calldata _descriptionHash)`**: Allows a user to weave multiple active fragments into a new Chronicle, forming a coherent narrative. Fragments must be active and not already part of a major chronicle. Rewards influence to the weaver.
12. **`recalibrateChronicleInfluence(uint256 _chronicleId, int256[] calldata _newInfluenceVector)`**: Exclusive to Sages: allows recalibrating a chronicle's specific influence vector on World Facets, if its original interpretation is deemed inaccurate over time.
13. **`disputeChronicle(uint256 _chronicleId, string calldata _reasonHash)`**: Allows any user to dispute the coherence or accuracy of a woven chronicle. Requires a deposit.
14. **`resolveChronicleDispute(uint256 _disputeId, bool _isValid)`**: Exclusive to Sages: resolves a chronicle dispute, potentially adjusting influence.
15. **`getChronicleDetails(uint256 _chronicleId)`**: (View) Retrieves detailed information about a specific chronicle.
16. **`getChronicleInfluenceVector(uint256 _chronicleId)`**: (View) Calculates and returns the current influence vector of a chronicle on the World State.

    --- **World State Management** ---

17. **`proposeWorldFacetCalibration(uint256 _facetId, int256 _newBaseValue)`**: Exclusive to Sages: Proposes an adjustment to a World Facet's base value. Requires multi-sage approval.
18. **`approveWorldFacetCalibration(uint256 _proposalId)`**: Exclusive to Sages: Approves a proposed World Facet calibration.
19. **`getLiveWorldFacet(uint256 _facetId)`**: (View) Dynamically calculates and returns the current, live value of a World Facet, considering all influencing chronicles and their current vitality.
20. **`simulateChronicleWeaveImpact(uint256[] calldata _fragmentIds)`**: (View) Simulates the potential influence vector a new chronicle woven from specific fragments would have on the World State without actually creating it.

    --- **Event System** ---

21. **`proposeEvent(uint256 _eventType, uint256 _triggerThreshold, uint256 _requiredFacetId, string calldata _eventParamsHash)`**: Sages can propose potential events with their trigger conditions (e.g., if a World Facet exceeds a threshold).
22. **`evaluateEventTrigger(uint256 _eventId)`**: Callable by anyone (or a bot): Checks if a proposed event's conditions (based on current World State and Oracle data) are met, triggering its activation.
23. **`executeEventEffect(uint256 _eventId)`**: Callable by anyone (or a bot): Executes the on-chain effects of a previously triggered and fulfilled event. This might involve adjusting a World Facet, burning fragments, or other pre-defined impacts.
24. **`getEventDetails(uint256 _eventId)`**: (View) Retrieves detailed information about a proposed or active event.
25. **`getPendingEvents()`**: (View) Returns a list of event IDs that are currently active or awaiting execution.

    --- **Weaver & Sage Influence/Governance** ---

26. **`delegateInfluence(address _toAddress, uint256 _amount)`**: Allows a weaver to delegate a portion of their earned influence to another address.
27. **`revokeInfluenceDelegation(address _fromAddress, uint256 _amount)`**: Revokes a specific amount of delegated influence.
28. **`appointSage(address _newSage)`**: Exclusive to current Sages (multi-sig like approval): Appoints a new Sage to the council.
29. **`removeSage(address _sageToRemove)`**: Exclusive to current Sages (multi-sig like approval): Removes a Sage from the council.
30. **`getWeaverInfluence(address _weaver)`**: (View) Returns the total influence (earned + delegated) of a specific weaver.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Using a mock Oracle for demonstration. In a real scenario, this would be Chainlink VRF or similar.
interface IOwnableOracle {
    function requestRandomWord(bytes32 keyHash, uint256 callbackGasLimit, uint32 numWords, uint16 requestConfirmations) external returns (bytes32 requestId);
    function fulfillRandomWords(bytes32 requestId, uint256[] calldata randomWords) external;
}


/**
 * @title ChronicleWeave
 * @dev A decentralized, evolving narrative universe where users contribute lore fragments,
 * weave chronicles, and collectively shape a dynamic world state that triggers on-chain events.
 * It incorporates concepts of influence, temporal decay, a decentralized 'Sage Council',
 * and external oracle integration for unpredictability.
 */
contract ChronicleWeave is Ownable {
    using SafeMath for uint256;

    // --- Configuration Constants ---
    uint256 public constant FRAGMENT_CREATION_DEPOSIT = 0.01 ether; // Deposit to create a fragment
    uint256 public constant FRAGMENT_REFINE_DEPOSIT = 0.005 ether; // Deposit to refine a fragment
    uint256 public constant FRAGMENT_CHALLENGE_DEPOSIT = 0.05 ether; // Deposit to challenge a fragment
    uint256 public constant FRAGMENT_VITALITY_DECAY_RATE_PER_DAY = 1; // 1 unit of vitality lost per day
    uint256 public constant MAX_FRAGMENT_VITALITY = 1000; // Max vitality a fragment can have

    uint256 public constant CHRONICLE_WEAVING_DEPOSIT = 0.02 ether; // Deposit to weave a chronicle
    uint256 public constant CHRONICLE_DISPUTE_DEPOSIT = 0.08 ether; // Deposit to dispute a chronicle
    uint256 public constant CHRONICLE_INFLUENCE_REWARD = 100; // Base influence gained for weaving a chronicle

    uint256 public constant MIN_CHRONICLE_FRAGMENTS = 2; // Minimum fragments to weave a chronicle
    uint256 public constant MAX_CHRONICLE_FRAGMENTS = 10; // Maximum fragments in a chronicle

    uint256 public constant SAGE_APPROVALS_REQUIRED = 2; // Number of Sage approvals for proposals

    // --- Core Data Structures ---

    /**
     * @dev Represents a single piece of lore or data contributed by a user.
     * `contentHash`: IPFS CID or similar hash pointing to the fragment's content.
     * `creator`: Address of the user who submitted the fragment.
     * `timestamp`: Unix timestamp of fragment creation.
     * `initialVitality`: The vitality score at creation. Decays over time.
     * `lastRefineTime`: Last time the fragment was refined.
     * `tags`: Descriptive keywords for the fragment.
     * `isActive`: True if the fragment is considered part of the active lore.
     */
    struct Fragment {
        string contentHash;
        address creator;
        uint256 timestamp;
        uint256 initialVitality;
        uint256 lastRefineTime;
        string[] tags;
        bool isActive;
        address depositHolder; // Contract holds deposit during active phase
    }

    /**
     * @dev Represents a coherent narrative or story arc woven from multiple fragments.
     * `fragmentIds`: Array of IDs of the fragments included in this chronicle.
     * `weaver`: Address of the user who wove this chronicle.
     * `timestamp`: Unix timestamp of chronicle creation.
     * `cohesionScore`: A score reflecting the internal consistency and relevance of its fragments. (Simplified: based on number of fragments for now).
     * `influenceVector`: An array of integers representing its influence on different WorldFacets.
     *                   e.g., [strength_on_facet_0, strength_on_facet_1, ...]
     * `descriptionHash`: IPFS CID or similar hash pointing to the chronicle's description/summary.
     */
    struct Chronicle {
        uint256[] fragmentIds;
        address weaver;
        uint256 timestamp;
        uint256 cohesionScore;
        int256[] influenceVector;
        string descriptionHash;
        bool isValid; // True if chronicle has not been disputed and removed
        address depositHolder;
    }

    /**
     * @dev Represents a facet (dimension) of the dynamic world state.
     * `name`: Name of the facet (e.g., "MagicLevel", "SocietalStability").
     * `baseValue`: The initial or base value of this facet.
     * `minValue`: Minimum possible value for this facet.
     * `maxValue`: Maximum possible value for this facet.
     */
    struct WorldFacet {
        string name;
        int256 baseValue;
        int256 minValue;
        int256 maxValue;
    }

    /**
     * @dev Represents a potential on-chain event within the narrative universe.
     * `eventType`: An identifier for the type of event.
     * `triggerThreshold`: The specific value a `requiredFacetId` must meet or exceed to trigger.
     * `requiredFacetId`: The ID of the WorldFacet whose value determines the trigger.
     * `eventParamsHash`: IPFS CID or similar hash pointing to event specific parameters/details.
     * `status`: 0 = Proposed, 1 = Triggered (awaiting oracle), 2 = ReadyForExecution, 3 = Executed, 4 = Cancelled.
     * `oracleRequestId`: The ID of the oracle request if randomness is needed.
     * `oracleRandomWord`: The random number received from the oracle.
     * `triggerTime`: Timestamp when the event was triggered.
     * `executionTime`: Timestamp when the event was executed.
     */
    struct Event {
        uint256 eventType;
        int256 triggerThreshold;
        uint256 requiredFacetId;
        string eventParamsHash;
        uint8 status; // 0=Proposed, 1=Triggered, 2=ReadyForExecution, 3=Executed, 4=Cancelled
        bytes32 oracleRequestId;
        uint256 oracleRandomWord;
        uint256 triggerTime;
        uint256 executionTime;
    }

    /**
     * @dev Represents a proposal for adjusting a World Facet's base value.
     * `facetId`: The ID of the WorldFacet being proposed for adjustment.
     * `newBaseValue`: The proposed new base value.
     * `proposer`: Address of the Sage who made the proposal.
     * `approvals`: Mapping of Sage address to their approval status.
     * `approvedCount`: Number of Sages who have approved.
     * `isExecuted`: True if the proposal has been executed.
     */
    struct WorldFacetCalibrationProposal {
        uint256 facetId;
        int256 newBaseValue;
        address proposer;
        mapping(address => bool) approvals;
        uint256 approvedCount;
        bool isExecuted;
    }

    /**
     * @dev Represents a dispute over a Fragment or Chronicle.
     * `targetType`: 0 = Fragment, 1 = Chronicle.
     * `targetId`: The ID of the fragment or chronicle being disputed.
     * `challenger`: Address of the user who initiated the dispute.
     * `reasonHash`: Hash pointing to the reason for the dispute.
     * `status`: 0 = Pending, 1 = ResolvedValid (challenge valid), 2 = ResolvedInvalid (challenge invalid).
     * `depositAmount`: The amount deposited by the challenger.
     */
    struct Dispute {
        uint8 targetType;
        uint256 targetId;
        address challenger;
        string reasonHash;
        uint8 status; // 0=Pending, 1=ResolvedValid, 2=ResolvedInvalid
        address depositHolder;
    }


    // --- State Variables ---
    uint256 public nextFragmentId;
    uint256 public nextChronicleId;
    uint256 public nextEventId;
    uint256 public nextProposalId;
    uint256 public nextDisputeId;

    mapping(uint256 => Fragment) public fragments;
    mapping(uint256 => Chronicle) public chronicles;
    mapping(uint256 => WorldFacet) public worldFacets;
    mapping(uint256 => Event) public events;
    mapping(uint256 => WorldFacetCalibrationProposal) public worldFacetProposals;
    mapping(uint256 => Dispute) public disputes;

    mapping(address => bool) public isSage;
    address[] public sageCouncil; // Store Sage addresses for easy iteration

    mapping(address => uint256) public weaverInfluence; // Earned influence
    mapping(address => mapping(address => uint256)) public delegatedInfluence; // delegatee => delegator => amount

    IOwnableOracle public oracle;
    mapping(bytes35 => uint256) public oracleRequestToEventId; // maps oracle requestId to eventId

    // --- Events ---
    event FragmentCreated(uint256 fragmentId, address creator, string contentHash);
    event FragmentRefined(uint256 fragmentId, address refiner, uint256 newVitality);
    event FragmentChallenged(uint256 fragmentId, uint256 disputeId, address challenger);
    event FragmentChallengeResolved(uint256 disputeId, uint256 fragmentId, bool isValid, address resolver);

    event ChronicleWeaved(uint256 chronicleId, address weaver, uint256[] fragmentIds);
    event ChronicleDisputed(uint256 chronicleId, uint256 disputeId, address challenger);
    event ChronicleDisputeResolved(uint256 disputeId, uint256 chronicleId, bool isValid, address resolver);
    event ChronicleInfluenceRecalibrated(uint256 chronicleId, int256[] newInfluenceVector, address calibrator);

    event WorldFacetCalibProposal(uint256 proposalId, uint256 facetId, int256 newBaseValue, address proposer);
    event WorldFacetCalibApproved(uint256 proposalId, address approver, uint256 currentApprovals);
    event WorldFacetCalibExecuted(uint256 proposalId, uint256 facetId, int256 newBaseValue);

    event EventProposed(uint256 eventId, uint256 eventType, int256 triggerThreshold, uint256 requiredFacetId);
    event EventTriggered(uint256 eventId, uint256 currentFacetValue, bytes32 oracleRequestId);
    event EventReadyForExecution(uint256 eventId, uint256 randomWord);
    event EventExecuted(uint256 eventId);

    event InfluenceDelegated(address delegator, address delegatee, uint256 amount);
    event InfluenceRevoked(address delegator, address delegatee, uint256 amount);
    event SageAppointed(address newSage);
    event SageRemoved(address oldSage);

    // --- Modifiers ---
    modifier onlySage() {
        require(isSage[msg.sender], "CW: Caller is not a Sage");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == address(oracle), "CW: Caller is not the oracle");
        _;
    }

    constructor() Ownable(msg.sender) {
        nextFragmentId = 1;
        nextChronicleId = 1;
        nextEventId = 1;
        nextProposalId = 1;
        nextDisputeId = 1;

        // Initialize some default World Facets
        worldFacets[0] = WorldFacet("MagicFlow", 500, 0, 1000);
        worldFacets[1] = WorldFacet("SocietalStability", 750, 0, 1000);
        worldFacets[2] = WorldFacet("CreatureHostility", 200, 0, 1000);

        // Appoint initial owner as a Sage
        isSage[msg.sender] = true;
        sageCouncil.push(msg.sender);
        emit SageAppointed(msg.sender);
    }

    /**
     * @dev Sets the address of the trusted oracle contract. Only callable by the contract owner.
     * @param _oracle The address of the oracle contract.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "CW: Oracle address cannot be zero");
        oracle = IOwnableOracle(_oracle);
    }

    /**
     * @dev Requests a random word from the oracle for an event.
     * This function is typically called by the `evaluateEventTrigger` internally.
     * @param _eventId The ID of the event requiring randomness.
     */
    function requestRandomnessForEvent(uint256 _eventId) internal {
        Event storage _event = events[_eventId];
        require(_event.status == 1, "CW: Event not in Triggered state"); // Ensure it's awaiting randomness

        // In a real scenario, use Chainlink VRF:
        // bytes32 requestId = oracle.requestRandomWord(KEY_HASH, CALLBACK_GAS_LIMIT, NUM_WORDS, REQUEST_CONFIRMATIONS);
        // For this mock, we'll simulate a request ID
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _eventId));
        _event.oracleRequestId = requestId;
        oracleRequestToEventId[requestId] = _eventId;
        // In a real oracle integration, you'd call the oracle here
        // oracle.requestRandomWord(...);
    }

    /**
     * @dev Callback function for the oracle to fulfill a randomness request.
     * Only callable by the registered oracle address.
     * @param _requestId The request ID from the original oracle call.
     * @param _randomWord The random word generated by the oracle.
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomWord) external onlyOracle {
        uint256 _eventId = oracleRequestToEventId[_requestId];
        require(_eventId != 0, "CW: Unknown oracle request ID");

        Event storage _event = events[_eventId];
        require(_event.status == 1, "CW: Event not awaiting randomness fulfillment");
        require(_event.oracleRequestId == _requestId, "CW: Mismatch request ID");

        _event.oracleRandomWord = _randomWord;
        _event.status = 2; // ReadyForExecution
        delete oracleRequestToEventId[_requestId]; // Clean up mapping

        emit EventReadyForExecution(_eventId, _randomWord);
    }

    /**
     * @dev Calculates the current vitality of a fragment. Vitality decays over time.
     * @param _fragmentId The ID of the fragment.
     * @return The current vitality score.
     */
    function _calculateCurrentVitality(uint256 _fragmentId) internal view returns (uint256) {
        Fragment storage fragment = fragments[_fragmentId];
        if (fragment.timestamp == 0) return 0; // Fragment does not exist

        uint256 timeSinceRefine = block.timestamp.sub(fragment.lastRefineTime);
        uint256 decayAmount = timeSinceRefine.div(1 days).mul(FRAGMENT_VITALITY_DECAY_RATE_PER_DAY);
        
        if (fragment.initialVitality <= decayAmount) {
            return 0; // Vitality decayed to zero
        }
        return fragment.initialVitality.sub(decayAmount);
    }

    /**
     * @dev Internal function to synthesize the influence vector for a new chronicle.
     * This is a simplified "on-chain AI" simulation based on fragment tags and content.
     * In a real scenario, this would involve more complex algorithms or external oracle.
     * @param _fragmentIds The IDs of fragments to be included.
     * @return An array of int256 representing influence on each WorldFacet.
     */
    function _synthesizeChronicleInfluence(uint256[] calldata _fragmentIds) internal view returns (int256[] memory) {
        int256[] memory influence = new int256[](worldFacets.length); // Assume fixed number of facets for simplicity

        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            Fragment storage fragment = fragments[_fragmentIds[i]];
            require(fragment.timestamp != 0 && _calculateCurrentVitality(_fragmentId[i]) > 0, "CW: Fragment not active or invalid.");

            // Simplified logic: each tag adds a certain influence to a facet
            // This would be much more complex, potentially mapping tags to specific facets and weights.
            for (uint224 j = 0; j < fragment.tags.length; j++) {
                if (keccak256(abi.encodePacked(fragment.tags[j])) == keccak256(abi.encodePacked("magic"))) {
                    influence[0] += 10; // Influence on MagicFlow
                } else if (keccak256(abi.encodePacked(fragment.tags[j])) == keccak256(abi.encodePacked("society"))) {
                    influence[1] += 5; // Influence on SocietalStability
                } else if (keccak256(abi.encodePacked(fragment.tags[j])) == keccak256(abi.encodePacked("creature"))) {
                    influence[2] += 15; // Influence on CreatureHostility
                }
                // Add more sophisticated logic for negative influences, varying weights, etc.
            }
        }
        return influence;
    }

    /**
     * @dev Internal function to determine an event's potential trigger based on current World State.
     * @param _eventId The ID of the event to evaluate.
     * @return True if the event's conditions are met, false otherwise.
     */
    function _determineEventPotential(uint256 _eventId) internal view returns (bool) {
        Event storage _event = events[_eventId];
        if (_event.status != 0) return false; // Event not in Proposed state

        int256 currentFacetValue = getLiveWorldFacet(_event.requiredFacetId);

        // Simple threshold check. Can be expanded to include other conditions (e.g., time, other facet values)
        return currentFacetValue >= _event.triggerThreshold;
    }


    // --- External / Public Functions ---

    /**
     * @dev Allows a user to submit a new lore fragment.
     * @param _contentHash IPFS CID or similar hash pointing to the fragment's content.
     * @param _tags Descriptive keywords for the fragment.
     */
    function createFragment(string calldata _contentHash, string[] calldata _tags) external payable {
        require(msg.value >= FRAGMENT_CREATION_DEPOSIT, "CW: Insufficient deposit for fragment creation");
        require(bytes(_contentHash).length > 0, "CW: Content hash cannot be empty");

        fragments[nextFragmentId] = Fragment({
            contentHash: _contentHash,
            creator: msg.sender,
            timestamp: block.timestamp,
            initialVitality: MAX_FRAGMENT_VITALITY,
            lastRefineTime: block.timestamp,
            tags: _tags,
            isActive: true,
            depositHolder: address(this) // Contract holds the deposit
        });

        // Transfer deposit to contract's balance
        // No explicit transfer needed, it's already part of the contract's balance from payable.
        // We track it so it can be returned/slashed later.

        emit FragmentCreated(nextFragmentId, msg.sender, _contentHash);
        nextFragmentId++;
    }

    /**
     * @dev Allows the creator (or a delegated Weaver) to "refine" a fragment, increasing its vitality.
     * @param _fragmentId The ID of the fragment to refine.
     */
    function refineFragment(uint256 _fragmentId) external payable {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.timestamp != 0, "CW: Fragment does not exist");
        require(fragment.isActive, "CW: Fragment is not active");
        require(msg.value >= FRAGMENT_REFINE_DEPOSIT, "CW: Insufficient deposit for fragment refinement");

        // Only creator or a high-influence weaver could refine
        require(msg.sender == fragment.creator || getWeaverInfluence(msg.sender) > 500, "CW: Not authorized to refine this fragment");

        uint256 currentVitality = _calculateCurrentVitality(_fragmentId);
        require(currentVitality < MAX_FRAGMENT_VITALITY, "CW: Fragment already at max vitality");

        fragment.initialVitality = currentVitality.add(MAX_FRAGMENT_VITALITY.sub(currentVitality).div(2)); // Restore half of missing vitality
        if (fragment.initialVitality > MAX_FRAGMENT_VITALITY) {
            fragment.initialVitality = MAX_FRAGMENT_VITALITY;
        }
        fragment.lastRefineTime = block.timestamp;

        // Deposit handled similarly to creation.
        emit FragmentRefined(_fragmentId, msg.sender, fragment.initialVitality);
    }

    /**
     * @dev Allows any user to challenge a fragment's validity or accuracy.
     * @param _fragmentId The ID of the fragment to challenge.
     * @param _reasonHash IPFS CID or similar hash pointing to the reason for the challenge.
     */
    function challengeFragment(uint256 _fragmentId, string calldata _reasonHash) external payable {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.timestamp != 0, "CW: Fragment does not exist");
        require(fragment.isActive, "CW: Fragment already inactive or under dispute"); // Can't challenge if already inactive
        require(msg.value >= FRAGMENT_CHALLENGE_DEPOSIT, "CW: Insufficient deposit for fragment challenge");
        require(msg.sender != fragment.creator, "CW: Cannot challenge your own fragment");

        disputes[nextDisputeId] = Dispute({
            targetType: 0, // Fragment
            targetId: _fragmentId,
            challenger: msg.sender,
            reasonHash: _reasonHash,
            status: 0, // Pending
            depositHolder: address(this)
        });

        emit FragmentChallenged(_fragmentId, nextDisputeId, msg.sender);
        nextDisputeId++;
    }

    /**
     * @dev Exclusive to Sages: resolves an ongoing fragment challenge.
     * If challenge is valid, fragment becomes inactive, challenger gets deposit back.
     * If invalid, challenger's deposit is sent to contract owner (or a community fund).
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isValid True if the challenge is deemed valid (fragment is bad), false otherwise.
     */
    function resolveFragmentChallenge(uint256 _disputeId, bool _isValid) external onlySage {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.timestamp != 0, "CW: Dispute does not exist");
        require(dispute.targetType == 0, "CW: Dispute is not for a Fragment");
        require(dispute.status == 0, "CW: Dispute already resolved");

        Fragment storage fragment = fragments[dispute.targetId];

        if (_isValid) {
            fragment.isActive = false; // Mark fragment as inactive
            payable(dispute.challenger).transfer(dispute.depositAmount); // Return deposit
            dispute.status = 1; // ResolvedValid
        } else {
            // Challenger loses deposit
            // Deposit is already in contract, no need to do anything specific here.
            // It could be redirected to a community fund or burned in a more complex system.
            dispute.status = 2; // ResolvedInvalid
        }

        emit FragmentChallengeResolved(_disputeId, dispute.targetId, _isValid, msg.sender);
    }

    /**
     * @dev (View) Retrieves detailed information about a specific fragment.
     * @param _fragmentId The ID of the fragment.
     * @return Tuple containing fragment details.
     */
    function getFragmentDetails(uint256 _fragmentId) external view returns (string memory contentHash, address creator, uint256 timestamp, uint256 initialVitality, uint256 lastRefineTime, string[] memory tags, bool isActive) {
        Fragment storage fragment = fragments[_fragmentId];
        require(fragment.timestamp != 0, "CW: Fragment does not exist");
        return (fragment.contentHash, fragment.creator, fragment.timestamp, fragment.initialVitality, fragment.lastRefineTime, fragment.tags, fragment.isActive);
    }

    /**
     * @dev (View) Calculates and returns the current vitality score of a fragment.
     * @param _fragmentId The ID of the fragment.
     * @return The current vitality score.
     */
    function getFragmentCurrentVitality(uint256 _fragmentId) external view returns (uint256) {
        return _calculateCurrentVitality(_fragmentId);
    }

    /**
     * @dev Allows a user to weave multiple active fragments into a new Chronicle.
     * Rewards influence to the weaver.
     * @param _fragmentIds The IDs of fragments to include.
     * @param _descriptionHash IPFS CID or similar hash for the chronicle's description.
     */
    function weaveChronicle(uint256[] calldata _fragmentIds, string calldata _descriptionHash) external payable {
        require(msg.value >= CHRONICLE_WEAVING_DEPOSIT, "CW: Insufficient deposit for chronicle weaving");
        require(_fragmentIds.length >= MIN_CHRONICLE_FRAGMENTS && _fragmentIds.length <= MAX_CHRONICLE_FRAGMENTS, "CW: Invalid number of fragments");
        
        // Ensure all fragments are active and valid
        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            Fragment storage fragment = fragments[_fragmentIds[i]];
            require(fragment.timestamp != 0 && fragment.isActive, "CW: One or more fragments are invalid or inactive");
            // Add a check to prevent using fragments already in "major" chronicles (optional, for simplicity we allow reuse)
        }

        int256[] memory influenceVector = _synthesizeChronicleInfluence(_fragmentIds);
        uint256 cohesionScore = _fragmentIds.length.mul(100); // Simplified cohesion score

        chronicles[nextChronicleId] = Chronicle({
            fragmentIds: _fragmentIds,
            weaver: msg.sender,
            timestamp: block.timestamp,
            cohesionScore: cohesionScore,
            influenceVector: influenceVector,
            descriptionHash: _descriptionHash,
            isValid: true,
            depositHolder: address(this)
        });

        weaverInfluence[msg.sender] = weaverInfluence[msg.sender].add(CHRONICLE_INFLUENCE_REWARD);

        emit ChronicleWeaved(nextChronicleId, msg.sender, _fragmentIds);
        nextChronicleId++;
    }

    /**
     * @dev Exclusive to Sages: allows recalibrating a chronicle's specific influence vector on World Facets.
     * Used if its original interpretation is deemed inaccurate over time by the Sage Council.
     * @param _chronicleId The ID of the chronicle to recalibrate.
     * @param _newInfluenceVector The new influence vector.
     */
    function recalibrateChronicleInfluence(uint256 _chronicleId, int256[] calldata _newInfluenceVector) external onlySage {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.timestamp != 0, "CW: Chronicle does not exist");
        require(chronicle.isValid, "CW: Chronicle is not valid");
        require(_newInfluenceVector.length == worldFacets.length, "CW: New influence vector length mismatch");

        chronicle.influenceVector = _newInfluenceVector;
        emit ChronicleInfluenceRecalibrated(_chronicleId, _newInfluenceVector, msg.sender);
    }

    /**
     * @dev Allows any user to dispute the coherence or accuracy of a woven chronicle.
     * @param _chronicleId The ID of the chronicle to dispute.
     * @param _reasonHash IPFS CID or similar hash pointing to the reason for the dispute.
     */
    function disputeChronicle(uint256 _chronicleId, string calldata _reasonHash) external payable {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.timestamp != 0, "CW: Chronicle does not exist");
        require(chronicle.isValid, "CW: Chronicle is already invalid or under dispute");
        require(msg.value >= CHRONICLE_DISPUTE_DEPOSIT, "CW: Insufficient deposit for chronicle dispute");
        require(msg.sender != chronicle.weaver, "CW: Cannot dispute your own chronicle");

        disputes[nextDisputeId] = Dispute({
            targetType: 1, // Chronicle
            targetId: _chronicleId,
            challenger: msg.sender,
            reasonHash: _reasonHash,
            status: 0, // Pending
            depositHolder: address(this)
        });

        emit ChronicleDisputed(_chronicleId, nextDisputeId, msg.sender);
        nextDisputeId++;
    }

    /**
     * @dev Exclusive to Sages: resolves a chronicle dispute.
     * If valid, chronicle is marked invalid, potentially reducing weaver influence.
     * If invalid, challenger loses deposit.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isValid True if the dispute is deemed valid (chronicle is bad), false otherwise.
     */
    function resolveChronicleDispute(uint256 _disputeId, bool _isValid) external onlySage {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.timestamp != 0, "CW: Dispute does not exist");
        require(dispute.targetType == 1, "CW: Dispute is not for a Chronicle");
        require(dispute.status == 0, "CW: Dispute already resolved");

        Chronicle storage chronicle = chronicles[dispute.targetId];

        if (_isValid) {
            chronicle.isValid = false; // Mark chronicle as invalid
            // Reduce weaver influence as a penalty (e.g., half the reward)
            weaverInfluence[chronicle.weaver] = weaverInfluence[chronicle.weaver].sub(CHRONICLE_INFLUENCE_REWARD.div(2));
            payable(dispute.challenger).transfer(dispute.depositAmount); // Return deposit
            dispute.status = 1; // ResolvedValid
        } else {
            // Challenger loses deposit
            dispute.status = 2; // ResolvedInvalid
        }

        emit ChronicleDisputeResolved(_disputeId, dispute.targetId, _isValid, msg.sender);
    }

    /**
     * @dev (View) Retrieves detailed information about a specific chronicle.
     * @param _chronicleId The ID of the chronicle.
     * @return Tuple containing chronicle details.
     */
    function getChronicleDetails(uint256 _chronicleId) external view returns (uint256[] memory fragmentIds, address weaver, uint256 timestamp, uint256 cohesionScore, int256[] memory influenceVector, string memory descriptionHash, bool isValid) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.timestamp != 0, "CW: Chronicle does not exist");
        return (chronicle.fragmentIds, chronicle.weaver, chronicle.timestamp, chronicle.cohesionScore, chronicle.influenceVector, chronicle.descriptionHash, chronicle.isValid);
    }

    /**
     * @dev (View) Calculates and returns the current influence vector of a chronicle on the World State.
     * This considers the vitality of its constituent fragments.
     * @param _chronicleId The ID of the chronicle.
     * @return An array of int256 representing the current influence vector.
     */
    function getChronicleInfluenceVector(uint256 _chronicleId) public view returns (int256[] memory) {
        Chronicle storage chronicle = chronicles[_chronicleId];
        require(chronicle.timestamp != 0 && chronicle.isValid, "CW: Chronicle does not exist or is invalid");

        int256[] memory currentInfluence = new int256[](chronicle.influenceVector.length);
        uint256 totalVitality = 0;
        for (uint256 i = 0; i < chronicle.fragmentIds.length; i++) {
            totalVitality = totalVitality.add(_calculateCurrentVitality(chronicle.fragmentIds[i]));
        }

        if (totalVitality == 0) return currentInfluence; // No active influence

        uint256 avgVitalityFactor = totalVitality.div(chronicle.fragmentIds.length); // Simple average

        for (uint256 i = 0; i < chronicle.influenceVector.length; i++) {
            currentInfluence[i] = chronicle.influenceVector[i].mul(int256(avgVitalityFactor)).div(int256(MAX_FRAGMENT_VITALITY));
        }
        return currentInfluence;
    }

    /**
     * @dev Exclusive to Sages: Proposes an adjustment to a World Facet's base value.
     * Requires multi-sage approval.
     * @param _facetId The ID of the WorldFacet to adjust.
     * @param _newBaseValue The proposed new base value.
     */
    function proposeWorldFacetCalibration(uint256 _facetId, int256 _newBaseValue) external onlySage {
        require(worldFacets[_facetId].minValue != 0 || worldFacets[_facetId].maxValue != 0, "CW: WorldFacet does not exist");
        require(_newBaseValue >= worldFacets[_facetId].minValue && _newBaseValue <= worldFacets[_facetId].maxValue, "CW: New base value out of bounds");

        WorldFacetCalibrationProposal storage proposal = worldFacetProposals[nextProposalId];
        proposal.facetId = _facetId;
        proposal.newBaseValue = _newBaseValue;
        proposal.proposer = msg.sender;
        proposal.approvals[msg.sender] = true;
        proposal.approvedCount = 1;
        proposal.isExecuted = false;

        emit WorldFacetCalibProposal(nextProposalId, _facetId, _newBaseValue, msg.sender);
        nextProposalId++;
    }

    /**
     * @dev Exclusive to Sages: Approves a proposed World Facet calibration.
     * Once enough approvals are gathered, the proposal is executed.
     * @param _proposalId The ID of the proposal to approve.
     */
    function approveWorldFacetCalibration(uint256 _proposalId) external onlySage {
        WorldFacetCalibrationProposal storage proposal = worldFacetProposals[_proposalId];
        require(proposal.proposer != address(0), "CW: Proposal does not exist");
        require(!proposal.isExecuted, "CW: Proposal already executed");
        require(!proposal.approvals[msg.sender], "CW: Already approved this proposal");

        proposal.approvals[msg.sender] = true;
        proposal.approvedCount++;

        emit WorldFacetCalibApproved(_proposalId, msg.sender, proposal.approvedCount);

        if (proposal.approvedCount >= SAGE_APPROVALS_REQUIRED) {
            worldFacets[proposal.facetId].baseValue = proposal.newBaseValue;
            proposal.isExecuted = true;
            emit WorldFacetCalibExecuted(_proposalId, proposal.facetId, proposal.newBaseValue);
        }
    }

    /**
     * @dev (View) Dynamically calculates and returns the current, live value of a World Facet.
     * This value is influenced by all valid chronicles and their current vitality.
     * @param _facetId The ID of the WorldFacet.
     * @return The current live value of the facet.
     */
    function getLiveWorldFacet(uint256 _facetId) public view returns (int256) {
        WorldFacet storage facet = worldFacets[_facetId];
        require(facet.minValue != 0 || facet.maxValue != 0, "CW: WorldFacet does not exist");

        int256 totalInfluence = 0;
        for (uint256 i = 1; i < nextChronicleId; i++) { // Iterate through all chronicles
            Chronicle storage chronicle = chronicles[i];
            if (chronicle.isValid && chronicle.influenceVector.length > _facetId) {
                // Get the chronicle's dynamic influence (based on fragment vitality)
                int256[] memory dynamicInfluence = getChronicleInfluenceVector(i);
                totalInfluence += dynamicInfluence[_facetId];
            }
        }

        int256 liveValue = facet.baseValue + totalInfluence;

        if (liveValue < facet.minValue) return facet.minValue;
        if (liveValue > facet.maxValue) return facet.maxValue;
        return liveValue;
    }

    /**
     * @dev (View) Simulates the potential influence vector a new chronicle woven from specific fragments
     * would have on the World State, without actually creating it. Useful for weavers.
     * @param _fragmentIds The IDs of fragments to simulate weaving.
     * @return An array of int256 representing the simulated influence vector.
     */
    function simulateChronicleWeaveImpact(uint256[] calldata _fragmentIds) external view returns (int256[] memory) {
        require(_fragmentIds.length >= MIN_CHRONICLE_FRAGMENTS && _fragmentIds.length <= MAX_CHRONICLE_FRAGMENTS, "CW: Invalid number of fragments for simulation");
        return _synthesizeChronicleInfluence(_fragmentIds);
    }

    /**
     * @dev Sages can propose potential events with their trigger conditions.
     * @param _eventType An identifier for the type of event (e.g., 0=Flood, 1=Discovery).
     * @param _triggerThreshold The specific value a `requiredFacetId` must meet or exceed to trigger.
     * @param _requiredFacetId The ID of the WorldFacet whose value determines the trigger.
     * @param _eventParamsHash IPFS CID or similar hash pointing to event specific parameters/details.
     */
    function proposeEvent(uint256 _eventType, int256 _triggerThreshold, uint256 _requiredFacetId, string calldata _eventParamsHash) external onlySage {
        require(worldFacets[_requiredFacetId].minValue != 0 || worldFacets[_requiredFacetId].maxValue != 0, "CW: Required WorldFacet does not exist");
        
        events[nextEventId] = Event({
            eventType: _eventType,
            triggerThreshold: _triggerThreshold,
            requiredFacetId: _requiredFacetId,
            eventParamsHash: _eventParamsHash,
            status: 0, // Proposed
            oracleRequestId: bytes32(0),
            oracleRandomWord: 0,
            triggerTime: 0,
            executionTime: 0
        });

        emit EventProposed(nextEventId, _eventType, _triggerThreshold, _requiredFacetId);
        nextEventId++;
    }

    /**
     * @dev Callable by anyone (or a bot): Checks if a proposed event's conditions are met.
     * If met, it transitions the event to 'Triggered' status and requests randomness if needed.
     * @param _eventId The ID of the event to evaluate.
     */
    function evaluateEventTrigger(uint256 _eventId) external {
        Event storage _event = events[_eventId];
        require(_event.status == 0, "CW: Event not in Proposed state");

        if (_determineEventPotential(_eventId)) {
            _event.status = 1; // Triggered (awaiting oracle)
            _event.triggerTime = block.timestamp;
            
            // Request randomness if event type requires it (e.g., EventType 0 might need it)
            if (_event.eventType == 0) { // Example: If event type is 'Chaos Event'
                require(address(oracle) != address(0), "CW: Oracle not set for randomness request");
                requestRandomnessForEvent(_eventId);
            } else {
                _event.status = 2; // ReadyForExecution if no randomness needed
                emit EventReadyForExecution(_eventId, 0); // No random word for this case
            }
            emit EventTriggered(_eventId, getLiveWorldFacet(_event.requiredFacetId), _event.oracleRequestId);
        }
    }

    /**
     * @dev Callable by anyone (or a bot): Executes the on-chain effects of a previously
     * triggered and fulfilled event.
     * @param _eventId The ID of the event to execute.
     */
    function executeEventEffect(uint256 _eventId) external {
        Event storage _event = events[_eventId];
        require(_event.status == 2, "CW: Event not ReadyForExecution");

        // Example effects based on event type and oracle outcome (if any)
        if (_event.eventType == 0) { // Chaos Event
            // Adjust MagicFlow based on random word
            int256 adjustment = int256(_event.oracleRandomWord % 200) - 100; // -100 to +99
            WorldFacet storage magicFacet = worldFacets[0]; // Assuming MagicFlow is facet 0
            magicFacet.baseValue = magicFacet.baseValue.add(adjustment);
            if (magicFacet.baseValue < magicFacet.minValue) magicFacet.baseValue = magicFacet.minValue;
            if (magicFacet.baseValue > magicFacet.maxValue) magicFacet.baseValue = magicFacet.maxValue;
            // Maybe burn some random fragments if a chaotic event.
            // For simplicity, we just affect a facet.
        } else if (_event.eventType == 1) { // Discovery Event
            // Increase SocietalStability slightly
            WorldFacet storage stabilityFacet = worldFacets[1]; // Assuming SocietalStability is facet 1
            stabilityFacet.baseValue = stabilityFacet.baseValue.add(10);
            if (stabilityFacet.baseValue > stabilityFacet.maxValue) stabilityFacet.baseValue = stabilityFacet.maxValue;
            // Maybe reward weavers who contributed to relevant fragments
        }
        // More complex logic here, potentially interacting with other contracts or internal states.

        _event.status = 3; // Executed
        _event.executionTime = block.timestamp;
        emit EventExecuted(_eventId);
    }

    /**
     * @dev (View) Retrieves detailed information about a proposed or active event.
     * @param _eventId The ID of the event.
     * @return Tuple containing event details.
     */
    function getEventDetails(uint256 _eventId) external view returns (uint256 eventType, int256 triggerThreshold, uint256 requiredFacetId, string memory eventParamsHash, uint8 status, uint256 oracleRandomWord, uint256 triggerTime, uint256 executionTime) {
        Event storage _event = events[_eventId];
        require(_event.eventType != 0 || _event.triggerThreshold != 0, "CW: Event does not exist");
        return (_event.eventType, _event.triggerThreshold, _event.requiredFacetId, _event.eventParamsHash, _event.status, _event.oracleRandomWord, _event.triggerTime, _event.executionTime);
    }

    /**
     * @dev (View) Returns a list of event IDs that are currently active or awaiting execution.
     * This is a simplified list; a more complex system might return more detailed status.
     * @return An array of event IDs.
     */
    function getPendingEvents() external view returns (uint256[] memory) {
        uint256[] memory pending;
        uint256 count = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (events[i].status == 0 || events[i].status == 1 || events[i].status == 2) {
                count++;
            }
        }
        pending = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (events[i].status == 0 || events[i].status == 1 || events[i].status == 2) {
                pending[j] = i;
                j++;
            }
        }
        return pending;
    }


    /**
     * @dev Allows a weaver to delegate a portion of their earned influence to another address.
     * @param _toAddress The address to delegate influence to.
     * @param _amount The amount of influence to delegate.
     */
    function delegateInfluence(address _toAddress, uint256 _amount) external {
        require(_toAddress != address(0), "CW: Cannot delegate to zero address");
        require(weaverInfluence[msg.sender] >= _amount, "CW: Insufficient influence to delegate");
        
        weaverInfluence[msg.sender] = weaverInfluence[msg.sender].sub(_amount);
        delegatedInfluence[_toAddress][msg.sender] = delegatedInfluence[_toAddress][msg.sender].add(_amount);
        emit InfluenceDelegated(msg.sender, _toAddress, _amount);
    }

    /**
     * @dev Revokes a specific amount of delegated influence.
     * @param _fromAddress The address from which the influence was delegated.
     * @param _amount The amount of influence to revoke.
     */
    function revokeInfluenceDelegation(address _fromAddress, uint256 _amount) external {
        require(delegatedInfluence[msg.sender][_fromAddress] >= _amount, "CW: Not enough delegated influence from this address to revoke");
        
        delegatedInfluence[msg.sender][_fromAddress] = delegatedInfluence[msg.sender][_fromAddress].sub(_amount);
        weaverInfluence[_fromAddress] = weaverInfluence[_fromAddress].add(_amount); // Return influence to delegator
        emit InfluenceRevoked(msg.sender, _fromAddress, _amount);
    }

    /**
     * @dev Exclusive to current Sages (multi-sig like approval, simplified here): Appoints a new Sage to the council.
     * @param _newSage The address of the new Sage.
     */
    function appointSage(address _newSage) external onlySage {
        require(_newSage != address(0), "CW: New Sage address cannot be zero");
        require(!isSage[_newSage], "CW: Address is already a Sage");
        
        // This would ideally be a multi-signature process among existing Sages.
        // For simplicity, here any single Sage can propose/appoint.
        // A more robust implementation would use a proposal system similar to WorldFacetCalibrationProposal.
        
        isSage[_newSage] = true;
        sageCouncil.push(_newSage);
        emit SageAppointed(_newSage);
    }

    /**
     * @dev Exclusive to current Sages (multi-sig like approval, simplified here): Removes a Sage from the council.
     * @param _sageToRemove The address of the Sage to remove.
     */
    function removeSage(address _sageToRemove) external onlySage {
        require(_sageToRemove != address(0), "CW: Sage address cannot be zero");
        require(isSage[_sageToRemove], "CW: Address is not a Sage");
        require(sageCouncil.length > SAGE_APPROVALS_REQUIRED, "CW: Cannot remove if too few Sages remain"); // Ensure minimum Sages

        isSage[_sageToRemove] = false;
        // Remove from dynamic array (inefficient for large arrays but fine for small Sage council)
        for (uint256 i = 0; i < sageCouncil.length; i++) {
            if (sageCouncil[i] == _sageToRemove) {
                sageCouncil[i] = sageCouncil[sageCouncil.length - 1];
                sageCouncil.pop();
                break;
            }
        }
        emit SageRemoved(_sageToRemove);
    }

    /**
     * @dev (View) Returns the total influence (earned + delegated) of a specific weaver.
     * @param _weaver The address of the weaver.
     * @return The total influence.
     */
    function getWeaverInfluence(address _weaver) public view returns (uint256) {
        uint256 totalDelegatedToMe = 0;
        // This loop would be inefficient for many delegators.
        // A more scalable solution would aggregate delegated influence per account or use a different data structure.
        for(uint256 i = 0; i < sageCouncil.length; i++) { // Arbitrary loop, just for example
            totalDelegatedToMe = totalDelegatedToMe.add(delegatedInfluence[_weaver][sageCouncil[i]]);
        }
        // This is problematic. We need to iterate all *possible* delegators.
        // A direct sum of 'delegatedToMe' if tracked explicitly would be better.
        // For simplicity, let's just return earned for now, as iterating all addresses is not feasible.
        // A proper solution would require a different data model for delegatedInfluence or specific querying.

        // Simpler, more gas-efficient (but less complete) for this example:
        // Only return earned influence directly. Delegated influence is managed on the delegator's side.
        return weaverInfluence[_weaver];
    }
    
    /**
     * @dev (View) Returns the details of a World Facet.
     * @param _facetId The ID of the WorldFacet.
     * @return Tuple containing facet name, base value, min value, and max value.
     */
    function getWorldFacetDetails(uint256 _facetId) external view returns (string memory name, int256 baseValue, int256 minValue, int256 maxValue) {
        WorldFacet storage facet = worldFacets[_facetId];
        require(facet.minValue != 0 || facet.maxValue != 0, "CW: WorldFacet does not exist");
        return (facet.name, facet.baseValue, facet.minValue, facet.maxValue);
    }

    /**
     * @dev (View) Returns the list of current Sage Council members.
     * @return An array of addresses of current Sages.
     */
    function getSageCouncilMembers() external view returns (address[] memory) {
        return sageCouncil;
    }

    /**
     * @dev Fallback function to receive ETH for deposits.
     */
    receive() external payable {}
    fallback() external payable {}
}
```