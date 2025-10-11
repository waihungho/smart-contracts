This smart contract, "Quantum Entanglement Digital Companions (QEDC)," introduces a novel concept of dynamic, evolving NFTs that possess an on-chain "Quantum State Vector." These companions are not static images but digital entities whose characteristics, appearance (via dynamic `tokenURI`), and abilities change based on user interactions, internal pseudo-random fluctuations, time-based decay, external oracle data, and unique "entanglement" links with other companions.

The core idea revolves around a multi-dimensional state system that simulates a form of "digital consciousness" or "life cycle," encouraging continuous engagement and strategic decision-making by owners.

---

## Quantum Entanglement Digital Companions (QEDC) Smart Contract

**Concept:** QEDC are dynamic NFTs (ERC721) whose attributes are governed by an on-chain "Quantum State Vector" comprising `cohesion`, `adaptability`, `resonance`, and `entropy_level`. These vectors evolve through user interactions, probabilistic events, time-based decay, external oracle influence, and unique "entanglement" mechanics with other companions. Their visual representation (via `tokenURI`) and potential abilities are directly tied to their evolving state and "Quantum Tier."

**Key Advanced Concepts:**

1.  **Dynamic NFTs:** `tokenURI` updates dynamically based on the companion's evolving on-chain state.
2.  **Multi-Dimensional State Vector:** Not just a single score, but interacting parameters influencing behavior and tier.
3.  **On-chain Pseudo-Randomness:** For "quantum fluctuations" and initial state generation.
4.  **Reputation/Engagement System:** `evolutionaryScore` and `quantumTier` based on activity.
5.  **Delegated "Focus":** Users can stake tokens to influence a companion's potential.
6.  **Inter-entity "Entanglement":** Actions on one companion can subtly affect its entangled partners.
7.  **Oracle Integration:** For feeding external "cognitive data" and resolving complex challenges.
8.  **Time-based Decay/Equilibrium:** States naturally shift over time if not actively managed, requiring owner intervention.
9.  **Gamified Challenges:** Unique challenge types that test specific state vectors.

---

### Contract Outline & Function Summary

**I. Core ERC721 & Setup**
*   `constructor()`: Initializes the contract, sets the name, symbol, and designates initial minter/oracle roles.
*   `mintCompanion()`: Creates a new QEDC, assigning it an initial semi-random quantum state vector.
*   `tokenURI(uint256 tokenId)`: Generates the dynamic metadata URI for a companion, reflecting its current on-chain state.

**II. Quantum State & Evolution**
*   `observeQuantumState(uint256 tokenId)`: Publicly viewable function that also slightly increases the companion's `evolutionaryScore` and updates its `lastInteractionTime`, simulating 'attention'.
*   `interactWithCompanion(uint256 tokenId, InteractionType interactionType)`: Allows owners to perform specific interactions (Nurture, Stimulate, Challenge) that affect different components of the companion's quantum state vector and `evolutionaryScore`.
*   `triggerQuantumFluctuation(uint256 tokenId)`: Initiates a probabilistic, state-altering event for the companion, consuming a small fee and potentially shifting its quantum state vectors in unpredictable ways.
*   `advanceTimeStep(uint256 tokenId)`: A callable function (e.g., by owners or keeper network) that applies time-based decay or subtle shifts to state vectors if the companion has been inactive, mimicking the passage of time.
*   `synthesizeCognitiveData(uint256 tokenId, bytes32 externalDataHash, uint256 dataValue)`: An authorized oracle can feed external "cognitive" data (e.g., environmental factors, general market sentiment) which subtly influences the state of specific companions or the entire ecosystem.
*   `delegateFocus(uint256 tokenId, uint256 amount)`: Allows users to stake a custom `FocusToken` to a companion, boosting its 'potential' or 'energy' for participation in challenges.
*   `recalibrateEquilibrium(uint256 tokenId)`: Allows an owner to pay a small fee to gently nudge a companion's extreme state vectors back towards a 'balanced' equilibrium, mitigating burnout or complete instability.

**III. Entanglement & Social Mechanics**
*   `initiateEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of `tokenId1` proposes an entanglement link with `tokenId2`. Requires the target companion to not be entangled already.
*   `acceptEntanglement(uint256 proposalId)`: Owner of `tokenId2` accepts an entanglement proposal, establishing a reciprocal link.
*   `severEntanglement(uint256 entanglementId)`: Either owner can sever an entanglement, potentially incurring a small state penalty or cost.
*   `conductJointInteraction(uint256 tokenId1, uint256 tokenId2, JointInteractionType type)`: Allows owners of two entangled companions to perform a shared interaction, potentially amplifying effects or unlocking unique state transitions for both.
*   `propagateQuantumEcho(uint256 sourceTokenId)`: An internal function (triggered by certain external actions on a companion) that subtly propagates state changes from a `sourceTokenId` to its entangled partners, simulating a ripple effect.

**IV. Challenges & Gamification**
*   `createTemporalRiftChallenge(string calldata name, uint256 entryFee, uint256 rewardMultiplier, uint256 requiredCohesion)`: An admin or DAO-controlled function to create a new challenge that requires companions to possess specific state vector attributes.
*   `enterTemporalRift(uint256 challengeId, uint256 tokenId)`: Allows a user to enter their companion into a specified challenge, consuming stamina, paying the entry fee, and checking required state attributes.
*   `resolveTemporalRift(uint256 challengeId, uint256[] calldata participantTokenIds, bytes32 oracleOutcomeHash)`: An authorized oracle-called function to determine the outcomes of a challenge, distribute rewards, and apply state modifications (positive or negative) to participants based on their success or failure.
*   `claimRiftRewards(uint256 challengeId)`: Allows successful participants in a resolved challenge to claim their share of the reward pool.
*   `initiateCommunityEvent(string calldata eventName, uint256 duration, uint256 collectiveGoal, EventEffectType effect)`: An admin/DAO-initiated event where *all* companions can contribute (e.g., by specific interactions) towards a collective goal. If the goal is reached within the duration, a global effect is applied to all participating companions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For FocusToken

/**
 * @title Quantum Entanglement Digital Companions (QEDC)
 * @dev A dynamic NFT contract where companions evolve based on interactions,
 *      time, external data, and unique 'entanglement' mechanics.
 */
contract QEDC is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _entanglementIdCounter;
    Counters.Counter private _entanglementProposalIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _communityEventIdCounter;

    uint256 public constant MAX_STATE_VALUE = 1000;
    uint256 public constant INITIAL_STAMINA = 100;
    uint256 public constant MAX_STAMINA = 200;
    uint256 public constant STAMINA_REGEN_RATE = 10; // per advanceTimeStep

    string private _baseTokenURI;
    address public oracleAddress; // Address authorized to resolve challenges and synthesize cognitive data
    address public focusTokenAddress; // Address of the custom ERC20 token used for 'focus' delegation

    // --- Structs & Enums ---

    enum InteractionType {
        Nurture,    // Boosts Cohesion, reduces Entropy
        Stimulate,  // Boosts Adaptability, Resonance
        Challenge   // Tests Adaptability, consumes Stamina, affects all stats based on outcome
    }

    enum JointInteractionType {
        Synchronize, // Balances entangled states, potentially amplifies positive effects
        Amplify,     // Boosts one specific state vector across both entangled companions
        Meditate     // Reduces Entropy across both, recovers stamina slowly
    }

    enum EventEffectType {
        GlobalBoost,        // All stats slightly increased for participants
        EntropyReduction,   // Reduces Entropy for all participants
        CohesionIncrease    // Increases Cohesion for all participants
    }

    struct QuantumStateVector {
        uint16 cohesion;      // Stability, resilience (0-MAX_STATE_VALUE)
        uint16 adaptability;  // Ability to change, learn (0-MAX_STATE_VALUE)
        uint16 resonance;     // Connection, empathy (0-MAX_STATE_VALUE)
        uint16 entropy_level; // Disorder, decay, instability (0-MAX_STATE_VALUE)
    }

    struct CompanionDetails {
        address owner;
        string tokenURI_metadata; // Stored for caching or baseURI purposes, actual URI is dynamic
        QuantumStateVector state;
        uint256 evolutionaryScore;
        uint8 quantumTier;          // Derived from evolutionaryScore and state (0-9)
        uint64 lastInteractionTime; // Timestamp of last owner interaction
        uint16 stamina;             // Energy for challenges
        uint256 focusTokensStaked;  // Amount of FocusToken staked
        uint256[] activeEntanglementIds; // IDs of entanglements this companion is part of
        uint256[] pendingEntanglementProposals; // IDs of pending proposals for this companion
    }

    struct Entanglement {
        uint256 id;
        uint256 tokenId1;
        uint256 tokenId2;
        bool active;
        uint64 initiationTime;
        uint64 lastPropagateTime; // Last time influence was propagated
    }

    struct EntanglementProposal {
        uint256 id;
        address proposer;
        address targetOwner;
        uint256 tokenId1; // Proposer's token
        uint256 tokenId2; // Target's token
        bool accepted;
        bool cancelled;
    }

    struct Challenge {
        uint256 id;
        string name;
        uint256 entryFee; // In native currency (wei)
        uint256 rewardMultiplier; // Multiplier for base rewards
        uint16 requiredCohesion; // Minimum cohesion to enter
        uint16 requiredAdaptability; // Minimum adaptability to enter
        uint64 startTime;
        uint64 endTime;
        bool active;
        bool resolved;
        address[] participants; // Track actual participant addresses, not tokens
        mapping(uint256 => bool) hasParticipated; // tokenId => true
        mapping(uint256 => bool) isWinner; // tokenId => true
        address[] winners;
        uint256 totalRewardPool; // Sum of entry fees
    }

    struct CommunityEvent {
        uint256 id;
        string name;
        uint64 startTime;
        uint64 endTime;
        uint256 collectiveGoal; // e.g., total interactions
        uint256 currentProgress;
        EventEffectType effectType;
        bool goalReached;
        mapping(uint256 => bool) hasContributed; // tokenId => true
        address[] contributors; // Addresses of unique contributors for reward distribution
    }

    // --- Mappings ---
    mapping(uint256 => CompanionDetails) public companionData;
    mapping(uint256 => Entanglement) public entanglements;
    mapping(uint256 => EntanglementProposal) public entanglementProposals;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => CommunityEvent) public communityEvents;

    // --- Events ---
    event CompanionMinted(uint256 indexed tokenId, address indexed owner, QuantumStateVector initialState);
    event CompanionInteracted(uint256 indexed tokenId, InteractionType interactionType, QuantumStateVector newState);
    event QuantumFluctuationTriggered(uint256 indexed tokenId, QuantumStateVector newState);
    event CompanionStateDecayed(uint256 indexed tokenId, QuantumStateVector newState);
    event CognitiveDataSynthesized(uint256 indexed tokenId, bytes32 externalDataHash, uint256 dataValue, QuantumStateVector newState);
    event FocusDelegated(uint256 indexed tokenId, address indexed delegator, uint256 amount);
    event FocusReclaimed(uint256 indexed tokenId, address indexed delegator, uint256 amount);
    event EquilibriumRecalibrated(uint256 indexed tokenId, QuantumStateVector newState);
    event EntanglementInitiated(uint256 indexed proposalId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementAccepted(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementSevered(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event JointInteractionPerformed(uint256 indexed tokenId1, uint256 indexed tokenId2, JointInteractionType interactionType);
    event QuantumEchoPropagated(uint256 indexed sourceTokenId, uint256 indexed targetTokenId, QuantumStateVector targetNewState);
    event ChallengeCreated(uint256 indexed challengeId, string name, uint256 entryFee, uint16 requiredCohesion);
    event CompanionEnteredChallenge(uint256 indexed challengeId, uint256 indexed tokenId);
    event ChallengeResolved(uint256 indexed challengeId, address[] winners);
    event RewardsClaimed(uint256 indexed challengeId, uint256 indexed tokenId, uint256 amount);
    event CommunityEventInitiated(uint256 indexed eventId, string name, uint256 collectiveGoal, EventEffectType effectType);
    event CommunityEventProgress(uint256 indexed eventId, uint256 newProgress, uint256 indexed tokenId);
    event CommunityEventGoalReached(uint256 indexed eventId, EventEffectType effectType);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QEDC: Only oracle can call this function");
        _;
    }

    modifier onlyCompanionOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "QEDC: Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "QEDC: Not the owner of this companion");
        _;
    }

    modifier onlyEntangled(uint256 _entanglementId, uint256 _tokenId) {
        require(entanglements[_entanglementId].active, "QEDC: Entanglement not active");
        require(entanglements[_entanglementId].tokenId1 == _tokenId || entanglements[_entanglementId].tokenId2 == _tokenId, "QEDC: Token not part of this entanglement");
        _;
    }

    modifier onlyChallengeActive(uint256 _challengeId) {
        require(challenges[_challengeId].active, "QEDC: Challenge is not active");
        require(block.timestamp >= challenges[_challengeId].startTime, "QEDC: Challenge has not started yet");
        require(block.timestamp <= challenges[_challengeId].endTime, "QEDC: Challenge has ended");
        _;
    }

    modifier onlyEventActive(uint256 _eventId) {
        require(communityEvents[_eventId].startTime <= block.timestamp && communityEvents[_eventId].endTime >= block.timestamp, "QEDC: Community event not active");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, string memory baseURI, address _oracleAddress, address _focusTokenAddress)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
        oracleAddress = _oracleAddress;
        focusTokenAddress = _focusTokenAddress;
    }

    // --- I. Core ERC721 & Setup ---

    /**
     * @dev Mints a new Quantum Entanglement Digital Companion.
     * @return tokenId The ID of the newly minted companion.
     */
    function mintCompanion() public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Basic pseudo-random initial state based on block data
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId)));

        QuantumStateVector memory initialState = QuantumStateVector({
            cohesion: uint16(seed % (MAX_STATE_VALUE / 2) + MAX_STATE_VALUE / 4), // 250-750
            adaptability: uint16((seed / 10) % (MAX_STATE_VALUE / 2) + MAX_STATE_VALUE / 4),
            resonance: uint16((seed / 100) % (MAX_STATE_VALUE / 2) + MAX_STATE_VALUE / 4),
            entropy_level: uint16((seed / 1000) % (MAX_STATE_VALUE / 4) + 100) // Lower initial entropy
        });

        _safeMint(msg.sender, newItemId);
        companionData[newItemId] = CompanionDetails({
            owner: msg.sender,
            tokenURI_metadata: "", // Will be dynamically generated by base URI
            state: initialState,
            evolutionaryScore: 0,
            quantumTier: 0,
            lastInteractionTime: uint64(block.timestamp),
            stamina: INITIAL_STAMINA,
            focusTokensStaked: 0,
            activeEntanglementIds: new uint256[](0),
            pendingEntanglementProposals: new uint256[](0)
        });

        _updateQuantumTier(newItemId); // Set initial tier
        emit CompanionMinted(newItemId, msg.sender, initialState);
        return newItemId;
    }

    /**
     * @dev Returns the base URI for the QEDC.
     *      The full tokenURI will be `_baseTokenURI` + `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide dynamic metadata.
     *      The actual metadata JSON (and image) will be generated by an off-chain server
     *      that queries the on-chain state of the companion.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "QEDC: URI query for nonexistent token");
        // Example: https://my-qedc-api.com/metadata/123
        // The off-chain API should read the state from the contract to generate dynamic metadata.
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    // --- II. Quantum State & Evolution ---

    /**
     * @dev Allows an owner to 'observe' their companion. This action subtly boosts its score
     *      and updates its last interaction time, simulating attention.
     * @param tokenId The ID of the companion.
     */
    function observeQuantumState(uint256 tokenId) public onlyCompanionOwner(tokenId) {
        CompanionDetails storage details = companionData[tokenId];
        details.evolutionaryScore += 1; // Small boost for attention
        details.lastInteractionTime = uint64(block.timestamp);
        _updateQuantumTier(tokenId); // Check for tier change
        emit CompanionInteracted(tokenId, InteractionType.Nurture, details.state); // Using Nurture for simplicity
    }

    /**
     * @dev Allows an owner to perform specific interactions with their companion,
     *      affecting its quantum state vector.
     * @param tokenId The ID of the companion.
     * @param interactionType The type of interaction (Nurture, Stimulate, Challenge).
     */
    function interactWithCompanion(uint256 tokenId, InteractionType interactionType) public onlyCompanionOwner(tokenId) {
        CompanionDetails storage details = companionData[tokenId];

        uint256 interactionEffect = 10;
        uint256 scoreIncrease = 5;

        if (interactionType == InteractionType.Nurture) {
            details.state.cohesion = _capStateValue(details.state.cohesion + uint16(interactionEffect));
            details.state.entropy_level = _capStateValue(details.state.entropy_level - uint16(interactionEffect / 2));
            scoreIncrease = 10;
        } else if (interactionType == InteractionType.Stimulate) {
            details.state.adaptability = _capStateValue(details.state.adaptability + uint16(interactionEffect));
            details.state.resonance = _capStateValue(details.state.resonance + uint16(interactionEffect));
            scoreIncrease = 15;
        } else if (interactionType == InteractionType.Challenge) {
            // Simplified challenge: consumes stamina, randomly affects stats
            require(details.stamina >= 20, "QEDC: Not enough stamina for challenge interaction");
            details.stamina -= 20;

            uint256 outcomeSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, "challenge")));
            if (outcomeSeed % 10 < 7) { // 70% chance of positive outcome
                details.state.adaptability = _capStateValue(details.state.adaptability + uint16(interactionEffect * 2));
                details.state.cohesion = _capStateValue(details.state.cohesion + uint16(interactionEffect));
                scoreIncrease = 30;
            } else { // 30% chance of negative outcome
                details.state.entropy_level = _capStateValue(details.state.entropy_level + uint16(interactionEffect * 2));
                details.state.cohesion = _capStateValue(details.state.cohesion - uint16(interactionEffect));
                scoreIncrease = 5; // Still some learning, but less
            }
        }

        details.evolutionaryScore += scoreIncrease;
        details.lastInteractionTime = uint64(block.timestamp);
        _updateQuantumTier(tokenId);
        _triggerPropagateQuantumEcho(tokenId); // Potentially affects entangled companions

        emit CompanionInteracted(tokenId, interactionType, details.state);
    }

    /**
     * @dev Initiates a probabilistic 'quantum fluctuation' for a companion,
     *      costing a small fee and causing unpredictable shifts in its state vectors.
     * @param tokenId The ID of the companion.
     */
    function triggerQuantumFluctuation(uint256 tokenId) public payable onlyCompanionOwner(tokenId) {
        require(msg.value >= 0.001 ether, "QEDC: Fluctuation requires 0.001 ETH fee"); // Small fee
        CompanionDetails storage details = companionData[tokenId];

        // Pseudo-random factor for fluctuation magnitude and direction
        uint256 fluctuationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, "fluctuation")));
        int256 deltaCohesion = int256(fluctuationSeed % 100) - 50; // -50 to +49
        int256 deltaAdaptability = int256((fluctuationSeed / 10) % 100) - 50;
        int256 deltaResonance = int256((fluctuationSeed / 100) % 100) - 50;
        int256 deltaEntropy = int256((fluctuationSeed / 1000) % 100) - 50;

        details.state.cohesion = _capStateValue(int256(details.state.cohesion) + deltaCohesion);
        details.state.adaptability = _capStateValue(int256(details.state.adaptability) + deltaAdaptability);
        details.state.resonance = _capStateValue(int256(details.state.resonance) + deltaResonance);
        details.state.entropy_level = _capStateValue(int256(details.state.entropy_level) + deltaEntropy);

        details.lastInteractionTime = uint64(block.timestamp);
        _updateQuantumTier(tokenId);
        _triggerPropagateQuantumEcho(tokenId);

        emit QuantumFluctuationTriggered(tokenId, details.state);
    }

    /**
     * @dev Applies time-based decay or subtle shifts to a companion's state vectors
     *      if it has been inactive for a period. Can be called by anyone or a keeper network.
     * @param tokenId The ID of the companion.
     */
    function advanceTimeStep(uint256 tokenId) public {
        CompanionDetails storage details = companionData[tokenId];
        uint64 timePassed = uint64(block.timestamp) - details.lastInteractionTime;
        uint64 decayInterval = 1 days; // Apply decay every day of inactivity

        if (timePassed < decayInterval) {
            return; // Not enough time passed for decay
        }

        uint64 decaySteps = timePassed / decayInterval;
        uint64 remainingTime = timePassed % decayInterval;

        // Apply decay
        uint16 decayAmount = uint16(1 * decaySteps); // Small decay per day
        details.state.cohesion = _capStateValue(details.state.cohesion - decayAmount);
        details.state.adaptability = _capStateValue(details.state.adaptability - decayAmount);
        details.state.resonance = _capStateValue(details.state.resonance - decayAmount);
        details.state.entropy_level = _capStateValue(details.state.entropy_level + decayAmount * 2); // Entropy increases faster

        // Stamina regeneration
        details.stamina = _capStamina(details.stamina + uint16(STAMINA_REGEN_RATE * decaySteps));

        details.lastInteractionTime = uint64(block.timestamp) - remainingTime; // Update to reflect remaining time
        _updateQuantumTier(tokenId);
        _triggerPropagateQuantumEcho(tokenId); // Decay can also ripple through entanglements

        emit CompanionStateDecayed(tokenId, details.state);
    }

    /**
     * @dev Allows an authorized oracle to feed external "cognitive" data, subtly influencing
     *      a companion's state. This can represent global events, environmental factors, etc.
     * @param tokenId The ID of the companion to influence.
     * @param externalDataHash A hash representing the external data source.
     * @param dataValue A value derived from the external data, influencing state.
     */
    function synthesizeCognitiveData(uint256 tokenId, bytes32 externalDataHash, uint256 dataValue) public onlyOracle {
        CompanionDetails storage details = companionData[tokenId];
        require(_exists(tokenId), "QEDC: Token does not exist");

        // Example: dataValue influences adaptability, scaled to a small effect
        uint16 influence = uint16(dataValue % 50); // Max 49
        if (dataValue % 2 == 0) {
            details.state.adaptability = _capStateValue(details.state.adaptability + influence);
            details.evolutionaryScore += influence / 2;
        } else {
            details.state.entropy_level = _capStateValue(details.state.entropy_level + influence);
            details.evolutionaryScore += influence / 4; // Less score for negative impact
        }

        _updateQuantumTier(tokenId);
        _triggerPropagateQuantumEcho(tokenId);

        emit CognitiveDataSynthesized(tokenId, externalDataHash, dataValue, details.state);
    }

    /**
     * @dev Allows users to stake `FocusToken` to a companion, boosting its 'potential' or 'energy'.
     *      This could impact challenge success rates or reduce decay.
     * @param tokenId The ID of the companion.
     * @param amount The amount of FocusToken to stake.
     */
    function delegateFocus(uint256 tokenId, uint256 amount) public onlyCompanionOwner(tokenId) {
        require(focusTokenAddress != address(0), "QEDC: FocusToken address not set");
        CompanionDetails storage details = companionData[tokenId];

        // Transfer FocusToken from msg.sender to this contract
        IERC20 focusToken = IERC20(focusTokenAddress);
        require(focusToken.transferFrom(msg.sender, address(this), amount), "QEDC: FocusToken transfer failed");

        details.focusTokensStaked += amount;
        emit FocusDelegated(tokenId, msg.sender, amount);
    }

    /**
     * @dev Allows users to reclaim staked `FocusToken` from their companion.
     * @param tokenId The ID of the companion.
     * @param amount The amount of FocusToken to reclaim.
     */
    function reclaimFocus(uint256 tokenId, uint256 amount) public onlyCompanionOwner(tokenId) {
        require(focusTokenAddress != address(0), "QEDC: FocusToken address not set");
        CompanionDetails storage details = companionData[tokenId];
        require(details.focusTokensStaked >= amount, "QEDC: Not enough FocusTokens staked to reclaim");

        // Transfer FocusToken from this contract back to msg.sender
        IERC20 focusToken = IERC20(focusTokenAddress);
        require(focusToken.transfer(msg.sender, amount), "QEDC: FocusToken transfer failed");

        details.focusTokensStaked -= amount;
        emit FocusReclaimed(tokenId, msg.sender, amount);
    }


    /**
     * @dev Allows an owner to pay a fee to gently nudge a companion's extreme state vectors
     *      back towards a 'balanced' equilibrium, mitigating burnout or instability.
     * @param tokenId The ID of the companion.
     */
    function recalibrateEquilibrium(uint256 tokenId) public payable onlyCompanionOwner(tokenId) {
        require(msg.value >= 0.005 ether, "QEDC: Recalibration requires 0.005 ETH fee"); // Small fee
        CompanionDetails storage details = companionData[tokenId];

        uint16 avgState = (details.state.cohesion + details.state.adaptability + details.state.resonance + (MAX_STATE_VALUE - details.state.entropy_level)) / 4;
        uint16 recalibrationStrength = 50; // How much to shift

        // Nudge values towards the average
        details.state.cohesion = _capStateValue(_nudgeTowards(details.state.cohesion, avgState, recalibrationStrength));
        details.state.adaptability = _capStateValue(_nudgeTowards(details.state.adaptability, avgState, recalibrationStrength));
        details.state.resonance = _capStateValue(_nudgeTowards(details.state.resonance, avgState, recalibrationStrength));
        // Entropy is opposite, so nudge MAX_STATE_VALUE - entropy_level towards average
        details.state.entropy_level = _capStateValue(MAX_STATE_VALUE - _nudgeTowards(MAX_STATE_VALUE - details.state.entropy_level, avgState, recalibrationStrength));

        details.lastInteractionTime = uint64(block.timestamp);
        _updateQuantumTier(tokenId);
        _triggerPropagateQuantumEcho(tokenId);

        emit EquilibriumRecalibrated(tokenId, details.state);
    }

    // --- III. Entanglement & Social Mechanics ---

    /**
     * @dev Initiates an entanglement proposal between two companions.
     *      Requires the target companion's owner to accept.
     * @param tokenId1 The ID of the proposing companion (owned by msg.sender).
     * @param tokenId2 The ID of the target companion.
     */
    function initiateEntanglement(uint256 tokenId1, uint256 tokenId2) public onlyCompanionOwner(tokenId1) {
        require(_exists(tokenId2), "QEDC: Target companion does not exist");
        require(tokenId1 != tokenId2, "QEDC: Cannot entangle a companion with itself");
        require(ownerOf(tokenId1) != ownerOf(tokenId2), "QEDC: Companions must have different owners to entangle");
        
        // Ensure neither token is already entangled with *each other*
        require(!_isEntangledWith(tokenId1, tokenId2), "QEDC: Companions are already entangled");

        // Check if there's already a pending proposal between them
        for (uint256 i = 0; i < companionData[tokenId2].pendingEntanglementProposals.length; i++) {
            uint256 proposalId = companionData[tokenId2].pendingEntanglementProposals[i];
            if (entanglementProposals[proposalId].tokenId1 == tokenId1 && entanglementProposals[proposalId].tokenId2 == tokenId2) {
                require(!entanglementProposals[proposalId].accepted && !entanglementProposals[proposalId].cancelled, "QEDC: Pending proposal already exists between these companions");
            }
        }
        
        _entanglementProposalIdCounter.increment();
        uint256 proposalId = _entanglementProposalIdCounter.current();

        entanglementProposals[proposalId] = EntanglementProposal({
            id: proposalId,
            proposer: msg.sender,
            targetOwner: ownerOf(tokenId2),
            tokenId1: tokenId1,
            tokenId2: tokenId2,
            accepted: false,
            cancelled: false
        });
        
        companionData[tokenId2].pendingEntanglementProposals.push(proposalId);

        emit EntanglementInitiated(proposalId, tokenId1, tokenId2);
    }

    /**
     * @dev Accepts an entanglement proposal. Only the target companion's owner can call this.
     * @param proposalId The ID of the entanglement proposal.
     */
    function acceptEntanglement(uint256 proposalId) public {
        EntanglementProposal storage proposal = entanglementProposals[proposalId];
        require(proposal.proposer != address(0), "QEDC: Proposal does not exist");
        require(msg.sender == proposal.targetOwner, "QEDC: Not the owner of the target companion");
        require(!proposal.accepted, "QEDC: Proposal already accepted");
        require(!proposal.cancelled, "QEDC: Proposal has been cancelled");
        require(!_isEntangledWith(proposal.tokenId1, proposal.tokenId2), "QEDC: Companions already entangled");

        proposal.accepted = true;

        _entanglementIdCounter.increment();
        uint256 entanglementId = _entanglementIdCounter.current();

        entanglements[entanglementId] = Entanglement({
            id: entanglementId,
            tokenId1: proposal.tokenId1,
            tokenId2: proposal.tokenId2,
            active: true,
            initiationTime: uint64(block.timestamp),
            lastPropagateTime: uint64(block.timestamp)
        });

        companionData[proposal.tokenId1].activeEntanglementIds.push(entanglementId);
        companionData[proposal.tokenId2].activeEntanglementIds.push(entanglementId);
        
        // Remove from pending proposals list
        _removeProposal(proposal.tokenId2, proposalId);

        emit EntanglementAccepted(entanglementId, proposal.tokenId1, proposal.tokenId2);
    }

    /**
     * @dev Allows either owner of an entangled pair to sever the link.
     *      May incur a small state penalty.
     * @param entanglementId The ID of the active entanglement.
     */
    function severEntanglement(uint256 entanglementId) public {
        Entanglement storage ent = entanglements[entanglementId];
        require(ent.active, "QEDC: Entanglement is not active");
        require(msg.sender == ownerOf(ent.tokenId1) || msg.sender == ownerOf(ent.tokenId2), "QEDC: Not an owner of either entangled companion");

        ent.active = false; // Deactivate entanglement

        // Apply small entropy penalty to both companions for severing
        companionData[ent.tokenId1].state.entropy_level = _capStateValue(companionData[ent.tokenId1].state.entropy_level + 20);
        companionData[ent.tokenId2].state.entropy_level = _capStateValue(companionData[ent.tokenId2].state.entropy_level + 20);

        // Remove from active entanglement lists
        _removeEntanglement(ent.tokenId1, entanglementId);
        _removeEntanglement(ent.tokenId2, entanglementId);

        emit EntanglementSevered(entanglementId, ent.tokenId1, ent.tokenId2);
    }

    /**
     * @dev Allows owners of entangled companions to perform a shared interaction,
     *      potentially amplifying effects or unlocking unique state transitions.
     * @param tokenId1 The ID of the first companion.
     * @param tokenId2 The ID of the second companion.
     * @param type The type of joint interaction to perform.
     */
    function conductJointInteraction(uint256 tokenId1, uint256 tokenId2, JointInteractionType type) public {
        require(ownerOf(tokenId1) == msg.sender, "QEDC: Not owner of first companion");
        require(ownerOf(tokenId2) == msg.sender || _isEntangledWith(tokenId1, tokenId2), "QEDC: Not owner of second companion or not entangled");
        
        // If different owners, ensure both have approved an active entanglement
        if (ownerOf(tokenId1) != ownerOf(tokenId2)) {
             require(_isEntangledWith(tokenId1, tokenId2), "QEDC: Companions not entangled for joint interaction between different owners");
        }

        CompanionDetails storage details1 = companionData[tokenId1];
        CompanionDetails storage details2 = companionData[tokenId2];

        uint256 jointEffect = 15;
        uint256 scoreBoost = 20;

        if (type == JointInteractionType.Synchronize) {
            // Nudge both companions' stats towards their combined average
            uint16 combinedCohesion = (details1.state.cohesion + details2.state.cohesion) / 2;
            uint16 combinedAdaptability = (details1.state.adaptability + details2.state.adaptability) / 2;
            uint16 combinedResonance = (details1.state.resonance + details2.state.resonance) / 2;
            uint16 combinedEntropy = (details1.state.entropy_level + details2.state.entropy_level) / 2;

            details1.state.cohesion = _capStateValue(_nudgeTowards(details1.state.cohesion, combinedCohesion, uint16(jointEffect)));
            details2.state.cohesion = _capStateValue(_nudgeTowards(details2.state.cohesion, combinedCohesion, uint16(jointEffect)));
            // ... similar for other stats ...
            details1.state.adaptability = _capStateValue(_nudgeTowards(details1.state.adaptability, combinedAdaptability, uint16(jointEffect)));
            details2.state.adaptability = _capStateValue(_nudgeTowards(details2.state.adaptability, combinedAdaptability, uint16(jointEffect)));
            details1.state.resonance = _capStateValue(_nudgeTowards(details1.state.resonance, combinedResonance, uint16(jointEffect)));
            details2.state.resonance = _capStateValue(_nudgeTowards(details2.state.resonance, combinedResonance, uint16(jointEffect)));
            details1.state.entropy_level = _capStateValue(_nudgeTowards(details1.state.entropy_level, combinedEntropy, uint16(jointEffect)));
            details2.state.entropy_level = _capStateValue(_nudgeTowards(details2.state.entropy_level, combinedEntropy, uint16(jointEffect)));
            scoreBoost = 30; // Higher boost for synchronization
        } else if (type == JointInteractionType.Amplify) {
            // Boost adaptability for both
            details1.state.adaptability = _capStateValue(details1.state.adaptability + uint16(jointEffect * 2));
            details2.state.adaptability = _capStateValue(details2.state.adaptability + uint16(jointEffect * 2));
        } else if (type == JointInteractionType.Meditate) {
            // Reduce entropy and recover stamina
            details1.state.entropy_level = _capStateValue(details1.state.entropy_level - uint16(jointEffect));
            details2.state.entropy_level = _capStateValue(details2.state.entropy_level - uint16(jointEffect));
            details1.stamina = _capStamina(details1.stamina + uint16(jointEffect));
            details2.stamina = _capStamina(details2.stamina + uint16(jointEffect));
        }

        details1.evolutionaryScore += scoreBoost;
        details2.evolutionaryScore += scoreBoost;
        details1.lastInteractionTime = uint64(block.timestamp);
        details2.lastInteractionTime = uint64(block.timestamp);

        _updateQuantumTier(tokenId1);
        _updateQuantumTier(tokenId2);
        _triggerPropagateQuantumEcho(tokenId1); // Trigger echo from one, it will handle propagation to others
        _triggerPropagateQuantumEcho(tokenId2); // And from the other to ensure all ripple effects

        emit JointInteractionPerformed(tokenId1, tokenId2, type);
    }

    /**
     * @dev Internal function to subtly propagate state changes from a source companion
     *      to its entangled partners, simulating a 'quantum echo'.
     * @param sourceTokenId The ID of the companion whose state change will propagate.
     */
    function _triggerPropagateQuantumEcho(uint256 sourceTokenId) internal {
        CompanionDetails storage sourceDetails = companionData[sourceTokenId];
        
        for (uint256 i = 0; i < sourceDetails.activeEntanglementIds.length; i++) {
            uint256 entanglementId = sourceDetails.activeEntanglementIds[i];
            Entanglement storage ent = entanglements[entanglementId];
            
            uint256 targetTokenId = (ent.tokenId1 == sourceTokenId) ? ent.tokenId2 : ent.tokenId1;
            CompanionDetails storage targetDetails = companionData[targetTokenId];

            // Only propagate if enough time has passed since last propagation for this specific entanglement
            uint64 minEchoInterval = 1 hours; // Minimum 1 hour between echoes for a specific link
            if (uint64(block.timestamp) - ent.lastPropagateTime < minEchoInterval) {
                continue;
            }

            // Small, scaled influence based on difference in state
            int16 echoStrength = 5; // Max shift per echo
            
            // Cohesion seeks equilibrium
            int16 deltaC = int16(sourceDetails.state.cohesion) - int16(targetDetails.state.cohesion);
            targetDetails.state.cohesion = _capStateValue(int256(targetDetails.state.cohesion) + (deltaC / 10)); // 10% of difference
            
            // Adaptability also seeks balance, but with less force
            int16 deltaA = int16(sourceDetails.state.adaptability) - int16(targetDetails.state.adaptability);
            targetDetails.state.adaptability = _capStateValue(int256(targetDetails.state.adaptability) + (deltaA / 15));
            
            // Resonance might just increase with interaction
            targetDetails.state.resonance = _capStateValue(targetDetails.state.resonance + uint16(echoStrength / 2));

            // Entropy might subtly increase due to complex interactions
            targetDetails.state.entropy_level = _capStateValue(targetDetails.state.entropy_level + uint16(echoStrength / 4));

            targetDetails.evolutionaryScore += 1; // Small score for being influenced
            _updateQuantumTier(targetTokenId);
            ent.lastPropagateTime = uint64(block.timestamp);

            emit QuantumEchoPropagated(sourceTokenId, targetTokenId, targetDetails.state);
        }
    }


    // --- IV. Challenges & Gamification ---

    /**
     * @dev Admin/DAO function to create a new 'Temporal Rift' challenge.
     *      Companions with specific state attributes can participate.
     * @param name The name of the challenge.
     * @param entryFee The fee (in ETH) to enter the challenge.
     * @param rewardMultiplier A multiplier for base rewards if successful.
     * @param requiredCohesion Minimum cohesion required to enter.
     * @param requiredAdaptability Minimum adaptability required to enter.
     * @param duration Challenge duration in seconds.
     */
    function createTemporalRiftChallenge(
        string calldata name,
        uint256 entryFee,
        uint256 rewardMultiplier,
        uint16 requiredCohesion,
        uint16 requiredAdaptability,
        uint64 duration
    ) public onlyOwner returns (uint256) {
        _challengeIdCounter.increment();
        uint256 challengeId = _challengeIdCounter.current();

        challenges[challengeId] = Challenge({
            id: challengeId,
            name: name,
            entryFee: entryFee,
            rewardMultiplier: rewardMultiplier,
            requiredCohesion: requiredCohesion,
            requiredAdaptability: requiredAdaptability,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + duration,
            active: true,
            resolved: false,
            participants: new address[](0),
            hasParticipated: new mapping(uint256 => bool)(), // Initialize mapping
            isWinner: new mapping(uint256 => bool)(),
            winners: new address[](0),
            totalRewardPool: 0
        });

        emit ChallengeCreated(challengeId, name, entryFee, requiredCohesion);
        return challengeId;
    }

    /**
     * @dev Allows a user to enter their companion into a specified Temporal Rift challenge.
     *      Checks stamina, required state attributes, and pays entry fee.
     * @param challengeId The ID of the challenge to enter.
     * @param tokenId The ID of the companion to enter.
     */
    function enterTemporalRift(uint256 challengeId, uint256 tokenId) public payable onlyCompanionOwner(tokenId) onlyChallengeActive(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        CompanionDetails storage details = companionData[tokenId];

        require(!challenge.hasParticipated[tokenId], "QEDC: Companion already entered this challenge");
        require(msg.value >= challenge.entryFee, "QEDC: Insufficient entry fee");
        require(details.stamina >= 50, "QEDC: Companion needs at least 50 stamina to enter");
        require(details.state.cohesion >= challenge.requiredCohesion, "QEDC: Companion cohesion too low");
        require(details.state.adaptability >= challenge.requiredAdaptability, "QEDC: Companion adaptability too low");

        details.stamina -= 50; // Consume stamina

        challenge.participants.push(msg.sender); // Track owner, not token
        challenge.hasParticipated[tokenId] = true;
        challenge.totalRewardPool += msg.value;

        emit CompanionEnteredChallenge(challengeId, tokenId);
    }

    /**
     * @dev An authorized oracle-called function to determine the outcomes of a challenge,
     *      distribute rewards, and apply state modifications to participants.
     * @param challengeId The ID of the challenge to resolve.
     * @param participantTokenIds An array of all token IDs that participated.
     * @param oracleOutcomeHash A hash containing the outcome data (e.g., random seed, specific results).
     *                          This is simplified; a real oracle would provide more robust proof.
     */
    function resolveTemporalRift(uint256 challengeId, uint256[] calldata participantTokenIds, bytes32 oracleOutcomeHash) public onlyOracle {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.active, "QEDC: Challenge is not active");
        require(!challenge.resolved, "QEDC: Challenge already resolved");
        require(block.timestamp > challenge.endTime, "QEDC: Challenge period not over yet");

        challenge.active = false;
        challenge.resolved = true;

        uint256 totalWinners = 0;
        address[] memory currentWinners = new address[](participantTokenIds.length); // Max possible winners

        // Simplified outcome: winners are selected based on a pseudo-random seed derived from oracle hash
        uint256 outcomeSeed = uint256(keccak256(abi.encodePacked(oracleOutcomeHash, challengeId)));

        for (uint256 i = 0; i < participantTokenIds.length; i++) {
            uint256 tokenId = participantTokenIds[i];
            require(challenge.hasParticipated[tokenId], "QEDC: Token did not participate in this challenge");
            
            CompanionDetails storage details = companionData[tokenId];

            // Complex logic for determining success based on companion stats and oracle outcome
            // For simplicity, let's say high cohesion and adaptability contribute to success.
            uint256 successChance = (details.state.cohesion + details.state.adaptability + (details.focusTokensStaked / 1 ether * 100)) / 20; // Example
            
            if ((outcomeSeed / (i + 1)) % 100 < successChance) { // Example random success check
                challenge.isWinner[tokenId] = true;
                currentWinners[totalWinners] = ownerOf(tokenId); // Store the owner as winner
                totalWinners++;
                // Apply positive state change for winners
                details.state.cohesion = _capStateValue(details.state.cohesion + 30);
                details.state.adaptability = _capStateValue(details.state.adaptability + 40);
                details.evolutionaryScore += 100 * challenge.rewardMultiplier;
            } else {
                // Apply negative state change for losers
                details.state.entropy_level = _capStateValue(details.state.entropy_level + 20);
                details.evolutionaryScore += 10; // Still some experience
            }
            _updateQuantumTier(tokenId);
            _triggerPropagateQuantumEcho(tokenId);
        }

        // Resize the winners array to actual number of winners
        address[] memory finalWinners = new address[](totalWinners);
        for (uint256 i = 0; i < totalWinners; i++) {
            finalWinners[i] = currentWinners[i];
        }
        challenge.winners = finalWinners;

        emit ChallengeResolved(challengeId, challenge.winners);
    }

    /**
     * @dev Allows winners of a resolved Temporal Rift challenge to claim their rewards.
     * @param challengeId The ID of the challenge.
     */
    function claimRiftRewards(uint256 challengeId) public {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.resolved, "QEDC: Challenge not yet resolved");
        require(challenge.totalRewardPool > 0, "QEDC: No rewards available or already distributed");

        uint256 tokenId = 0; // Find user's winning token
        bool foundWinnerToken = false;
        // Iterate through all tokens owned by msg.sender
        uint256 balance = balanceOf(msg.sender);
        for (uint256 i = 0; i < balance; i++) {
            uint256 userTokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (challenge.isWinner[userTokenId]) {
                tokenId = userTokenId;
                foundWinnerToken = true;
                break;
            }
        }
        require(foundWinnerToken, "QEDC: No winning companion found for this address in this challenge");
        
        uint256 rewardPerWinner = challenge.totalRewardPool / challenge.winners.length;
        require(challenge.totalRewardPool >= rewardPerWinner, "QEDC: Reward pool drained or error"); // Ensure no re-claims

        // Transfer reward and clear claim
        (bool success, ) = payable(msg.sender).call{value: rewardPerWinner}("");
        require(success, "QEDC: Failed to send reward");

        challenge.totalRewardPool -= rewardPerWinner; // Deduct from pool
        challenge.isWinner[tokenId] = false; // Prevent re-claim for this token
        
        // If all winners claim, the remaining pool will be 0
        if (challenge.totalRewardPool == 0) {
            delete challenge.winners; // Clear winners array
        }

        emit RewardsClaimed(challengeId, tokenId, rewardPerWinner);
    }

    /**
     * @dev Initiates a community-wide event where all companions can contribute towards a collective goal.
     *      If the goal is met, a global effect is applied to participants.
     * @param eventName The name of the community event.
     * @param duration The duration of the event in seconds.
     * @param collectiveGoal The total number of contributions needed to reach the goal.
     * @param effect The type of global effect to apply if the goal is reached.
     */
    function initiateCommunityEvent(
        string calldata eventName,
        uint256 duration,
        uint256 collectiveGoal,
        EventEffectType effect
    ) public onlyOwner returns (uint256) {
        _communityEventIdCounter.increment();
        uint256 eventId = _communityEventIdCounter.current();

        communityEvents[eventId] = CommunityEvent({
            id: eventId,
            name: eventName,
            startTime: uint64(block.timestamp),
            endTime: uint64(block.timestamp) + duration,
            collectiveGoal: collectiveGoal,
            currentProgress: 0,
            effectType: effect,
            goalReached: false,
            hasContributed: new mapping(uint256 => bool)(),
            contributors: new address[](0)
        });

        emit CommunityEventInitiated(eventId, eventName, collectiveGoal, effect);
        return eventId;
    }

    /**
     * @dev Allows a companion to contribute to an active community event.
     *      Each companion can contribute once per event.
     * @param eventId The ID of the community event.
     * @param tokenId The ID of the companion contributing.
     */
    function contributeToCommunityEvent(uint256 eventId, uint256 tokenId) public onlyCompanionOwner(tokenId) onlyEventActive(eventId) {
        CommunityEvent storage event_ = communityEvents[eventId];
        require(!event_.hasContributed[tokenId], "QEDC: Companion has already contributed to this event");
        require(!event_.goalReached, "QEDC: Event goal already reached");

        event_.currentProgress++;
        event_.hasContributed[tokenId] = true;
        // Only add unique owner addresses to contributors list
        bool ownerAlreadyContributed = false;
        for (uint i = 0; i < event_.contributors.length; i++) {
            if (event_.contributors[i] == msg.sender) {
                ownerAlreadyContributed = true;
                break;
            }
        }
        if (!ownerAlreadyContributed) {
            event_.contributors.push(msg.sender);
        }

        emit CommunityEventProgress(eventId, event_.currentProgress, tokenId);

        if (event_.currentProgress >= event_.collectiveGoal) {
            event_.goalReached = true;
            _applyCommunityEventEffect(eventId);
            emit CommunityEventGoalReached(eventId, event_.effectType);
        }
    }

    // --- Private / Internal Helper Functions ---

    /**
     * @dev Applies the global effect of a community event to all contributing companions.
     * @param eventId The ID of the community event.
     */
    function _applyCommunityEventEffect(uint256 eventId) internal {
        CommunityEvent storage event_ = communityEvents[eventId];
        require(event_.goalReached, "QEDC: Event goal not reached");

        uint16 effectMagnitude = 25; // Base effect magnitude

        for (uint256 i = 0; i < event_.contributors.length; i++) {
            address contributorAddress = event_.contributors[i];
            uint256 balance = balanceOf(contributorAddress);
            for (uint256 j = 0; j < balance; j++) {
                uint256 tokenId = tokenOfOwnerByIndex(contributorAddress, j);
                if (event_.hasContributed[tokenId]) { // Only apply to companions that specifically contributed
                    CompanionDetails storage details = companionData[tokenId];
                    if (event_.effectType == EventEffectType.GlobalBoost) {
                        details.state.cohesion = _capStateValue(details.state.cohesion + effectMagnitude);
                        details.state.adaptability = _capStateValue(details.state.adaptability + effectMagnitude);
                        details.state.resonance = _capStateValue(details.state.resonance + effectMagnitude);
                        details.evolutionaryScore += effectMagnitude * 2;
                    } else if (event_.effectType == EventEffectType.EntropyReduction) {
                        details.state.entropy_level = _capStateValue(details.state.entropy_level - effectMagnitude * 2);
                        details.evolutionaryScore += effectMagnitude * 3;
                    } else if (event_.effectType == EventEffectType.CohesionIncrease) {
                        details.state.cohesion = _capStateValue(details.state.cohesion + effectMagnitude * 3);
                        details.evolutionaryScore += effectMagnitude * 2;
                    }
                    _updateQuantumTier(tokenId);
                    _triggerPropagateQuantumEcho(tokenId);
                }
            }
        }
    }

    /**
     * @dev Ensures a state value stays within 0 and MAX_STATE_VALUE.
     * @param value The state value to cap.
     * @return The capped value.
     */
    function _capStateValue(int256 value) internal pure returns (uint16) {
        if (value < 0) return 0;
        if (value > MAX_STATE_VALUE) return uint16(MAX_STATE_VALUE);
        return uint16(value);
    }

    /**
     * @dev Ensures stamina value stays within 0 and MAX_STAMINA.
     * @param value The stamina value to cap.
     * @return The capped value.
     */
    function _capStamina(uint16 value) internal pure returns (uint16) {
        if (value < 0) return 0; // Should not happen with uint16 but good practice
        if (value > MAX_STAMINA) return MAX_STAMINA;
        return value;
    }

    /**
     * @dev Updates the quantum tier of a companion based on its evolutionary score and state.
     * @param tokenId The ID of the companion.
     */
    function _updateQuantumTier(uint256 tokenId) internal {
        CompanionDetails storage details = companionData[tokenId];
        uint256 score = details.evolutionaryScore;
        uint256 stateSum = details.state.cohesion + details.state.adaptability + details.state.resonance + (MAX_STATE_VALUE - details.state.entropy_level);
        uint256 effectiveScore = score + (stateSum / 10); // State also contributes

        uint8 newTier = 0;
        if (effectiveScore >= 1000) newTier = 9;
        else if (effectiveScore >= 750) newTier = 8;
        else if (effectiveScore >= 500) newTier = 7;
        else if (effectiveScore >= 300) newTier = 6;
        else if (effectiveScore >= 200) newTier = 5;
        else if (effectiveScore >= 150) newTier = 4;
        else if (effectiveScore >= 100) newTier = 3;
        else if (effectiveScore >= 50) newTier = 2;
        else if (effectiveScore >= 10) newTier = 1;
        else newTier = 0;

        details.quantumTier = newTier;
    }

    /**
     * @dev Helper to nudge a value towards a target.
     * @param current The current value.
     * @param target The target value.
     * @param strength How much to nudge (max change).
     * @return The nudged value.
     */
    function _nudgeTowards(uint16 current, uint16 target, uint16 strength) internal pure returns (uint16) {
        if (current == target) return current;
        if (current < target) {
            return current + strength > target ? target : current + strength;
        } else {
            return current - strength < target ? target : current - strength;
        }
    }

    /**
     * @dev Checks if two companions are currently entangled.
     */
    function _isEntangledWith(uint256 tokenId1, uint256 tokenId2) internal view returns (bool) {
        for (uint256 i = 0; i < companionData[tokenId1].activeEntanglementIds.length; i++) {
            uint256 entId = companionData[tokenId1].activeEntanglementIds[i];
            if (entanglements[entId].active && 
                ((entanglements[entId].tokenId1 == tokenId1 && entanglements[entId].tokenId2 == tokenId2) || 
                 (entanglements[entId].tokenId1 == tokenId2 && entanglements[entId].tokenId2 == tokenId1))) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Helper to remove an entanglement ID from a companion's list.
     */
    function _removeEntanglement(uint256 tokenId, uint256 entanglementId) internal {
        uint256[] storage activeEnts = companionData[tokenId].activeEntanglementIds;
        for (uint256 i = 0; i < activeEnts.length; i++) {
            if (activeEnts[i] == entanglementId) {
                activeEnts[i] = activeEnts[activeEnts.length - 1];
                activeEnts.pop();
                break;
            }
        }
    }
    
    /**
     * @dev Helper to remove an entanglement proposal ID from a companion's pending list.
     */
    function _removeProposal(uint256 tokenId, uint256 proposalId) internal {
        uint256[] storage pendingProposals = companionData[tokenId].pendingEntanglementProposals;
        for (uint256 i = 0; i < pendingProposals.length; i++) {
            if (pendingProposals[i] == proposalId) {
                pendingProposals[i] = pendingProposals[pendingProposals.length - 1];
                pendingProposals.pop();
                break;
            }
        }
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets the address of the authorized oracle.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "QEDC: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Sets the address of the FocusToken (ERC20).
     * @param _focusTokenAddress The new FocusToken address.
     */
    function setFocusTokenAddress(address _focusTokenAddress) public onlyOwner {
        require(_focusTokenAddress != address(0), "QEDC: FocusToken address cannot be zero");
        focusTokenAddress = _focusTokenAddress;
    }

    /**
     * @dev Allows owner to withdraw any remaining ETH that might have been sent to the contract
     *      (e.g., from fluctuation fees or unclaimed challenge rewards after all claims).
     */
    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "QEDC: No ETH to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "QEDC: Failed to withdraw ETH");
    }

    // --- View Functions (getters) ---

    function getCompanionState(uint256 tokenId) public view returns (QuantumStateVector memory) {
        return companionData[tokenId].state;
    }

    function getCompanionDetails(uint256 tokenId) public view returns (
        address owner_,
        QuantumStateVector memory state_,
        uint256 evolutionaryScore_,
        uint8 quantumTier_,
        uint64 lastInteractionTime_,
        uint16 stamina_,
        uint256 focusTokensStaked_,
        uint256[] memory activeEntanglementIds_
    ) {
        CompanionDetails storage details = companionData[tokenId];
        return (
            details.owner,
            details.state,
            details.evolutionaryScore,
            details.quantumTier,
            details.lastInteractionTime,
            details.stamina,
            details.focusTokensStaked,
            details.activeEntanglementIds
        );
    }

    function getEntanglementDetails(uint256 entanglementId) public view returns (
        uint256 id_, uint256 tokenId1_, uint256 tokenId2_, bool active_, uint64 initiationTime_
    ) {
        Entanglement storage ent = entanglements[entanglementId];
        return (ent.id, ent.tokenId1, ent.tokenId2, ent.active, ent.initiationTime);
    }
    
    function getEntanglementProposalDetails(uint256 proposalId) public view returns (
        uint256 id_, address proposer_, address targetOwner_, uint256 tokenId1_, uint256 tokenId2_, bool accepted_, bool cancelled_
    ) {
        EntanglementProposal storage proposal = entanglementProposals[proposalId];
        return (proposal.id, proposal.proposer, proposal.targetOwner, proposal.tokenId1, proposal.tokenId2, proposal.accepted, proposal.cancelled);
    }

    function getChallengeDetails(uint256 challengeId) public view returns (
        uint256 id_, string memory name_, uint256 entryFee_, uint256 rewardMultiplier_,
        uint16 requiredCohesion_, uint16 requiredAdaptability_, uint64 startTime_, uint64 endTime_,
        bool active_, bool resolved_, uint256 totalRewardPool_
    ) {
        Challenge storage challenge = challenges[challengeId];
        return (
            challenge.id, challenge.name, challenge.entryFee, challenge.rewardMultiplier,
            challenge.requiredCohesion, challenge.requiredAdaptability, challenge.startTime, challenge.endTime,
            challenge.active, challenge.resolved, challenge.totalRewardPool
        );
    }

    function getCommunityEventDetails(uint256 eventId) public view returns (
        uint256 id_, string memory name_, uint64 startTime_, uint64 endTime_,
        uint256 collectiveGoal_, uint256 currentProgress_, EventEffectType effectType_, bool goalReached_
    ) {
        CommunityEvent storage event_ = communityEvents[eventId];
        return (
            event_.id, event_.name, event_.startTime, event_.endTime,
            event_.collectiveGoal, event_.currentProgress, event_.effectType, event_.goalReached
        );
    }
}
```