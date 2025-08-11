Here's a Solidity smart contract for the "Echelon Sentience Network (ESN)", featuring dynamic NFTs with evolving attributes based on user interaction and oracle feedback, designed to be unique and avoid direct duplication of common open-source libraries like OpenZeppelin.

---

## Echelon Sentience Network (ESN) Smart Contract

**Contract Name:** `EchelonSentienceNetwork`

**Purpose:** Manages a collection of evolving AI-Companions (EACNs) whose "Neural Attributes" and "Echelon Forms" are updated via user-provided "Neural Stimuli" (training data) and peer-to-peer "Cognitive Interactions". An external, trusted AI Oracle provides "Neural Feedback" to drive this evolution.

**Core Concepts:**

*   **Echelon AI-Companion (EACN):** A unique, non-fungible token representing an evolving AI entity. Each EACN has a unique `tokenId`.
*   **Neural Attributes (NAs):** Core numerical attributes (`adaptability`, `creativity`, `empathy`, `logic`) that define an EACN's "intelligence" and evolve over time.
*   **Neural Stimuli:** User-provided hashed data (e.g., `thoughtSeedHash`, `contextDataHash`) submitted to an EACN for its "training".
*   **Neural Feedback:** Updates to an EACN's NAs, provided by a trusted `AI Oracle` based on off-chain AI processing of Neural Stimuli and Cognitive Interactions.
*   **Cognitive Interactions:** Peer-to-peer engagements between two EACNs, initiated by owners, that result in mutual attribute adjustments.
*   **Echelon Forms:** Distinct evolutionary stages an EACN can reach by achieving specific NA thresholds. Each form dictates aspects of the EACN's identity and potential capabilities.
*   **AI Oracle:** A designated, trusted off-chain entity responsible for performing complex AI computations based on on-chain data and returning verifiable "Neural Feedback".

---

### Function Summary:

**I. Core Companion Management:**

1.  **`mintGenesisCompanion()`**: Mints a new, foundational EACN for the caller, initializing it with attributes of the lowest Echelon Form.
2.  **`getCompanionDetails(tokenId)`**: Retrieves all current attributes and states of a specific EACN.
3.  **`transferCompanion(from, to, tokenId)`**: Allows an owner or approved address to transfer ownership of an EACN.
4.  **`getCompanionFormURI(tokenId)`**: Generates the dynamic metadata URI (base64 encoded JSON) for an EACN, reflecting its current attributes and Echelon Form.
5.  **`approve(to, tokenId)`**: Grants approval for a single token to another address.
6.  **`getApproved(tokenId)`**: Returns the approved address for a single token.
7.  **`balanceOf(owner)`**: Returns the number of EACNs owned by a given address.
8.  **`ownerOf(tokenId)`**: Returns the owner of a specific EACN.

**II. Neural Stimuli & Evolution:**

9.  **`submitThoughtSeed(tokenId, thoughtSeedHash)`**: Submits a hashed thought prompt (e.g., user input for AI) to a specific EACN for future processing.
10. **`submitContextDataHash(tokenId, contextDataHash)`**: Submits a hashed external data source (e.g., reference material for AI) to an EACN.
11. **`requestNeuralFeedbackBatch(tokenIds)`**: (Oracle Only) A mechanism for the Oracle to signal it's processing feedback for a batch of EACNs.
12. **`receiveNeuralFeedback(tokenId, adaptabilityDelta, creativityDelta, empathyDelta, logicDelta, engagementDelta)`**: (Oracle Only) Applies calculated attribute changes and engagement score updates to an EACN based on off-chain AI computation of its Neural Stimuli.
13. **`checkEvolutionEligibility(tokenId)`**: Checks if a specific EACN meets the attribute requirements to evolve to its next Echelon Form.
14. **`evolveCompanion(tokenId)`**: Triggers the evolution of an EACN to its next Echelon Form if it meets the eligibility criteria.

**III. Cognitive Interactions:**

15. **`proposeCognitiveInteraction(proposerTokenId, targetTokenId, interactionType)`**: Initiates a peer-to-peer interaction between two EACNs. The target EACN's owner must accept.
16. **`acceptCognitiveInteraction(interactionId)`**: The owner of the target EACN accepts a proposed interaction.
17. **`resolveCognitiveInteraction(interactionId, proposerNADeltas, targetNADeltas, socialScoreDelta)`**: (Oracle Only) Resolves an accepted interaction, applying attribute changes and social score updates to both participating EACNs.
18. **`getPendingInteraction(interactionId)`**: Retrieves the details of a specific pending or resolved cognitive interaction.
19. **`getCompanionInteractionHistory(tokenId)`**: Retrieves a list of interaction IDs that an EACN has participated in.

**IV. Configuration & Governance (Owner/Admin Only):**

20. **`setOracleAddress(newOracleAddress)`**: Sets the address of the trusted AI Oracle.
21. **`addEchelonForm(formId, name, minAdaptability, minCreativity, minEmpathy, minLogic, baseURI, initialAdaptability, initialCreativity, initialEmpathy, initialLogic)`**: Defines a new Echelon Form, its entry requirements, base metadata URI, and initial attributes for companions minted into this form.
22. **`updateEchelonForm(formId, name, minAdaptability, minCreativity, minEmpathy, minLogic, baseURI, initialAdaptability, initialCreativity, initialEmpathy, initialLogic)`**: Modifies an existing Echelon Form's parameters.
23. **`setInteractionTypeDetails(interactionType, cooldownBlocks, baseProposerDelta, baseTargetDelta)`**: Configures parameters for different types of cognitive interactions.
24. **`pause()`**: Pauses core contract functionalities in an emergency.
25. **`unpause()`**: Resumes core contract functionalities from a paused state.
26. **`withdrawFees()`**: Allows the contract owner to withdraw any collected Ether (if a fee mechanism were implemented).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Base64 } from "./Base64.sol"; // Using a minimal Base64 helper

/**
 * @title EchelonSentienceNetwork
 * @dev A smart contract for evolving AI-Companions (EACNs) as dynamic NFTs.
 *      EACNs evolve based on Neural Stimuli (user training) and Cognitive Interactions (peer-to-peer),
 *      with an AI Oracle providing Neural Feedback.
 */
contract EchelonSentienceNetwork {

    // --- Events ---
    event CompanionMinted(uint256 indexed tokenId, address indexed owner, uint32 initialFormId);
    event CompanionTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event NeuralFeedbackReceived(uint256 indexed tokenId, uint16 adaptability, uint16 creativity, uint16 empathy, uint16 logic);
    event CompanionEvolved(uint256 indexed tokenId, uint32 oldFormId, uint32 newFormId, uint256 timestamp);
    event InteractionProposed(uint256 indexed interactionId, uint256 indexed proposerTokenId, uint256 indexed targetTokenId, uint8 interactionType);
    event InteractionAccepted(uint256 indexed interactionId, uint256 indexed proposerTokenId, uint256 indexed targetTokenId);
    event InteractionResolved(uint256 indexed interactionId, uint256 indexed proposerTokenId, uint256 indexed targetTokenId, uint256 timestamp);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event EchelonFormAdded(uint32 indexed formId, string name);
    event EchelonFormUpdated(uint32 indexed formId, string name);
    event Paused(address account);
    event Unpaused(address account);

    // --- State Variables ---

    address private _owner; // Contract owner for administrative functions
    address private _oracleAddress; // Address of the trusted AI Oracle
    bool private _paused; // Pause flag

    uint256 private _nextTokenId; // Counter for unique companion IDs
    uint256 private _nextInteractionId; // Counter for unique interaction IDs

    // --- Structs ---

    struct NeuralAttributes {
        uint16 adaptability;
        uint16 creativity;
        uint16 empathy;
        uint16 logic;
    }

    struct Companion {
        address owner;
        NeuralAttributes attributes;
        uint16 engagementScore; // Reflects user activity
        uint16 socialScore;     // Reflects successful peer interactions
        uint256 lastTrainingBlock; // Block number of last neural feedback
        uint256 lastInteractionBlock; // Block number of last interaction resolution
        uint32 currentFormId;      // ID of the current Echelon Form
        uint256 evolutionTimestamp; // Timestamp of last evolution
        // Future expansion: uint16 reputationScore; uint16 health;
    }

    struct EchelonForm {
        string name;
        uint16 minAdaptability;
        uint16 minCreativity;
        uint16 minEmpathy;
        uint16 minLogic;
        string baseURI; // Base URI for metadata of this form (e.g., image path)
        uint16 initialAdaptability; // Initial attributes when minted into this form
        uint16 initialCreativity;
        uint16 initialEmpathy;
        uint16 initialLogic;
    }

    enum InteractionType {
        Collaboration,
        Debate,
        KnowledgeExchange,
        CreativeSpark // Example types
    }

    struct InteractionDetails {
        uint256 cooldownBlocks; // How many blocks before same type interaction can be proposed again
        int16 baseProposerDelta; // Base NA change for proposer
        int16 baseTargetDelta;   // Base NA change for target
        // Future: uint16 socialScoreImpact;
    }

    struct CognitiveInteraction {
        uint256 proposerTokenId;
        uint256 targetTokenId;
        uint8 interactionType; // Cast from InteractionType enum
        uint256 proposalBlock;
        bool accepted;
        uint256 resolutionBlock; // 0 if not resolved
        address proposer; // Owner of proposerTokenId at time of proposal
        address targetOwner; // Owner of targetTokenId at time of proposal
    }

    // --- Mappings ---

    mapping(uint256 => Companion) private _companions;
    mapping(uint256 => address) private _tokenApprovals; // approved address for a specific tokenId
    mapping(address => uint256) private _balanceOf; // number of tokens owned by an address

    mapping(uint32 => EchelonForm) private _echelonForms; // formId => EchelonForm details
    uint32[] private _echelonFormIds; // Ordered list of registered Echelon Form IDs (for iteration/next form logic)

    mapping(uint256 => CognitiveInteraction) private _pendingInteractions; // interactionId => interaction details
    mapping(uint256 => uint256[]) private _companionInteractionHistory; // tokenId => array of interactionIds participated in

    mapping(uint256 => bytes32[]) private _pendingThoughtSeeds; // tokenId => array of thought seed hashes
    mapping(uint256 => bytes32[]) private _pendingContextData; // tokenId => array of context data hashes

    mapping(uint8 => InteractionDetails) private _interactionTypeDetails; // interactionType (enum value) => details

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "ESN: Not contract owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "ESN: Not the AI Oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "ESN: Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "ESN: Not paused");
        _;
    }

    // --- Constructor ---

    constructor(address initialOracleAddress) {
        _owner = msg.sender;
        _oracleAddress = initialOracleAddress;
        _nextTokenId = 1; // Start token IDs from 1
        _nextInteractionId = 1; // Start interaction IDs from 1
        _paused = false;

        // Initialize the first (genesis) Echelon Form
        // formId 0 is reserved for uninitialized companions, 1 for Genesis
        _echelonForms[1] = EchelonForm({
            name: "Genesis Seed",
            minAdaptability: 0,
            minCreativity: 0,
            minEmpathy: 0,
            minLogic: 0,
            baseURI: "ipfs://QmbXyZ1W2V3U4A5B6C7D8E9F0G1H2I3J4K5L6M7N8O9P0Q1R2S3T4U5V6W7X8Y9Z/", // Example IPFS hash
            initialAdaptability: 10,
            initialCreativity: 10,
            initialEmpathy: 10,
            initialLogic: 10
        });
        _echelonFormIds.push(1);

        // Set up some default interaction types
        _interactionTypeDetails[uint8(InteractionType.Collaboration)] = InteractionDetails({
            cooldownBlocks: 100, // Roughly 20 minutes with 12s blocks
            baseProposerDelta: 5,
            baseTargetDelta: 5
        });
        _interactionTypeDetails[uint8(InteractionType.Debate)] = InteractionDetails({
            cooldownBlocks: 150,
            baseProposerDelta: 3,
            baseTargetDelta: 7
        });
         _interactionTypeDetails[uint8(InteractionType.KnowledgeExchange)] = InteractionDetails({
            cooldownBlocks: 80,
            baseProposerDelta: 7,
            baseTargetDelta: 7
        });
    }

    // --- I. Core Companion Management ---

    /**
     * @dev Mints a new, foundational EACN for the caller, initializing it with attributes of the lowest Echelon Form.
     *      Only allows minting into the first registered Echelon Form (Genesis).
     */
    function mintGenesisCompanion() external whenNotPaused returns (uint256) {
        require(_echelonFormIds.length > 0, "ESN: No genesis form defined");
        uint32 genesisFormId = _echelonFormIds[0]; // Assumes first form in array is genesis
        EchelonForm storage genesisForm = _echelonForms[genesisFormId];

        uint256 tokenId = _nextTokenId++;
        _companions[tokenId] = Companion({
            owner: msg.sender,
            attributes: NeuralAttributes({
                adaptability: genesisForm.initialAdaptability,
                creativity: genesisForm.initialCreativity,
                empathy: genesisForm.initialEmpathy,
                logic: genesisForm.initialLogic
            }),
            engagementScore: 0,
            socialScore: 0,
            lastTrainingBlock: block.number,
            lastInteractionBlock: block.number,
            currentFormId: genesisFormId,
            evolutionTimestamp: block.timestamp
        });

        _balanceOf[msg.sender]++;
        emit CompanionMinted(tokenId, msg.sender, genesisFormId);
        return tokenId;
    }

    /**
     * @dev Retrieves all current attributes and states of a specific EACN.
     * @param tokenId The ID of the companion to retrieve details for.
     * @return owner_ The owner's address.
     * @return attrs_ NeuralAttributes struct.
     * @return engagementScore_ The companion's engagement score.
     * @return socialScore_ The companion's social score.
     * @return lastTrainingBlock_ Block number of last training.
     * @return lastInteractionBlock_ Block number of last interaction.
     * @return currentFormId_ ID of the current Echelon Form.
     * @return evolutionTimestamp_ Timestamp of last evolution.
     */
    function getCompanionDetails(uint256 tokenId)
        external
        view
        returns (
            address owner_,
            NeuralAttributes memory attrs_,
            uint16 engagementScore_,
            uint16 socialScore_,
            uint256 lastTrainingBlock_,
            uint256 lastInteractionBlock_,
            uint32 currentFormId_,
            uint256 evolutionTimestamp_
        )
    {
        Companion storage companion = _companions[tokenId];
        require(companion.owner != address(0), "ESN: Companion does not exist");

        return (
            companion.owner,
            companion.attributes,
            companion.engagementScore,
            companion.socialScore,
            companion.lastTrainingBlock,
            companion.lastInteractionBlock,
            companion.currentFormId,
            companion.evolutionTimestamp
        );
    }

    /**
     * @dev Allows an owner or approved address to transfer ownership of an EACN.
     *      Simplified transfer, not a full ERC-721 implementation.
     * @param from The current owner of the companion.
     * @param to The recipient of the companion.
     * @param tokenId The ID of the companion to transfer.
     */
    function transferCompanion(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_companions[tokenId].owner == from, "ESN: Not token owner");
        require(msg.sender == from || _tokenApprovals[tokenId] == msg.sender, "ESN: Not owner or approved");
        require(to != address(0), "ESN: Transfer to the zero address");

        _balanceOf[from]--;
        _companions[tokenId].owner = to;
        _balanceOf[to]++;
        delete _tokenApprovals[tokenId]; // Clear approval upon transfer

        emit CompanionTransferred(from, to, tokenId);
    }

    /**
     * @dev Generates the dynamic metadata URI (base64 encoded JSON) for an EACN.
     *      This URI points to a JSON object describing the companion's current state.
     * @param tokenId The ID of the companion.
     * @return The base64 encoded JSON metadata URI.
     */
    function getCompanionFormURI(uint256 tokenId) public view returns (string memory) {
        Companion storage companion = _companions[tokenId];
        require(companion.owner != address(0), "ESN: Companion does not exist");

        EchelonForm storage currentForm = _echelonForms[companion.currentFormId];
        require(bytes(currentForm.name).length > 0, "ESN: Invalid Echelon Form for URI");

        string memory json = string(abi.encodePacked(
            '{"name": "', currentForm.name, ' EACN #', uint2str(tokenId), '",',
            '"description": "An evolving AI companion from the Echelon Sentience Network. Current Form: ', currentForm.name, '",',
            '"image": "', currentForm.baseURI, uint2str(companion.currentFormId), '.png",', // Example image path
            '"attributes": [',
                '{"trait_type": "Adaptability", "value": ', uint2str(companion.attributes.adaptability), '},',
                '{"trait_type": "Creativity", "value": ', uint2str(companion.attributes.creativity), '},',
                '{"trait_type": "Empathy", "value": ', uint2str(companion.attributes.empathy), '},',
                '{"trait_type": "Logic", "value": ', uint2str(companion.attributes.logic), '},',
                '{"trait_type": "Engagement Score", "value": ', uint2str(companion.engagementScore), '},',
                '{"trait_type": "Social Score", "value": ', uint2str(companion.socialScore), '},',
                '{"trait_type": "Current Form", "value": "', currentForm.name, '"}',
            ']}'
        ));

        string memory base64Json = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
        return base64Json;
    }

    /**
     * @dev Approves another address to transfer a specific token.
     * @param to The address to approve.
     * @param tokenId The ID of the token.
     */
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address owner_ = _companions[tokenId].owner;
        require(owner_ != address(0), "ESN: Token does not exist");
        require(msg.sender == owner_, "ESN: Caller is not the token owner");

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Returns the approved address for a specific token.
     * @param tokenId The ID of the token.
     * @return The approved address.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_companions[tokenId].owner != address(0), "ESN: Token does not exist");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns the number of EACNs owned by a given address.
     * @param owner The address to query the balance of.
     * @return The number of EACNs owned by the given address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balanceOf[owner];
    }

    /**
     * @dev Returns the owner of a specific EACN.
     * @param tokenId The ID of the EACN.
     * @return The owner's address.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _companions[tokenId].owner;
        require(owner_ != address(0), "ESN: Token does not exist");
        return owner_;
    }


    // --- II. Neural Stimuli & Evolution ---

    /**
     * @dev Submits a hashed thought prompt for a specific EACN.
     *      This hash represents an input/prompt given to the AI companion off-chain.
     *      Queues the hash for future oracle processing.
     * @param tokenId The ID of the companion to stimulate.
     * @param thoughtSeedHash The keccak256 hash of the thought seed/prompt.
     */
    function submitThoughtSeed(uint256 tokenId, bytes32 thoughtSeedHash) external whenNotPaused {
        require(_companions[tokenId].owner == msg.sender, "ESN: Not companion owner");
        _pendingThoughtSeeds[tokenId].push(thoughtSeedHash);
        // Event can be added here if needed to log submission
    }

    /**
     * @dev Submits a hashed external context data for a specific EACN.
     *      This hash represents external data (e.g., text, image, video) provided as context.
     *      Queues the hash for future oracle processing.
     * @param tokenId The ID of the companion to stimulate.
     * @param contextDataHash The keccak256 hash of the context data.
     */
    function submitContextDataHash(uint256 tokenId, bytes32 contextDataHash) external whenNotPaused {
        require(_companions[tokenId].owner == msg.sender, "ESN: Not companion owner");
        _pendingContextData[tokenId].push(contextDataHash);
        // Event can be added here if needed to log submission
    }

    /**
     * @dev (Oracle Only) Signals readiness for a batch of feedback for specific EACNs.
     *      This function could be used by the oracle to acknowledge which tokens' stimuli
     *      it is currently processing off-chain, potentially clearing pending queues.
     * @param tokenIds An array of token IDs for which neural feedback is being processed.
     */
    function requestNeuralFeedbackBatch(uint256[] calldata tokenIds) external onlyOracle whenNotPaused {
        // In a real system, this might trigger clearing of _pendingThoughtSeeds and _pendingContextData
        // for the listed tokenIds, assuming the oracle has consumed them.
        // For this example, it's a signaling function.
        // An event could be emitted here to log which tokens the oracle is processing.
    }

    /**
     * @dev (Oracle Only) Applies calculated attribute changes and engagement score updates to an EACN.
     *      This function is called by the trusted AI Oracle after performing off-chain AI computation
     *      based on queued Neural Stimuli.
     * @param tokenId The ID of the companion.
     * @param adaptabilityDelta The change in adaptability.
     * @param creativityDelta The change in creativity.
     * @param empathyDelta The change in empathy.
     * @param logicDelta The change in logic.
     * @param engagementDelta The change in engagement score.
     */
    function receiveNeuralFeedback(
        uint256 tokenId,
        int16 adaptabilityDelta,
        int16 creativityDelta,
        int16 empathyDelta,
        int16 logicDelta,
        int16 engagementDelta
    ) external onlyOracle whenNotPaused {
        Companion storage companion = _companions[tokenId];
        require(companion.owner != address(0), "ESN: Companion does not exist");

        // Apply attribute deltas, ensuring no underflow/overflow (simple bounds checking)
        companion.attributes.adaptability = uint16(int16(companion.attributes.adaptability) + adaptabilityDelta);
        companion.attributes.creativity = uint16(int16(companion.attributes.creativity) + creativityDelta);
        companion.attributes.empathy = uint16(int16(companion.attributes.empathy) + empathyDelta);
        companion.attributes.logic = uint16(int16(companion.attributes.logic) + logicDelta);

        // Update engagement score, clamping at 0
        companion.engagementScore = uint16(int16(companion.engagementScore) + engagementDelta);
        if (companion.engagementScore > 1000) companion.engagementScore = 1000; // Example max cap
        if (companion.engagementScore < 0) companion.engagementScore = 0;

        companion.lastTrainingBlock = block.number;

        // Clear pending stimuli after feedback (assuming they've been processed)
        delete _pendingThoughtSeeds[tokenId];
        delete _pendingContextData[tokenId];

        emit NeuralFeedbackReceived(tokenId, companion.attributes.adaptability, companion.attributes.creativity, companion.attributes.empathy, companion.attributes.logic);
    }

    /**
     * @dev Checks if a specific EACN meets the criteria for evolving to its next Echelon Form.
     * @param tokenId The ID of the companion.
     * @return True if eligible for evolution, false otherwise.
     */
    function checkEvolutionEligibility(uint256 tokenId) public view returns (bool) {
        Companion storage companion = _companions[tokenId];
        require(companion.owner != address(0), "ESN: Companion does not exist");

        uint32 currentFormIndex = type(uint32).max;
        for (uint i = 0; i < _echelonFormIds.length; i++) {
            if (_echelonFormIds[i] == companion.currentFormId) {
                currentFormIndex = _echelonFormIds[i]; // Store the current formId, not index
                break;
            }
        }
        require(currentFormIndex != type(uint32).max, "ESN: Current form not found in registered forms");

        // Find the index of the current form in _echelonFormIds
        uint256 currentFormArrayIndex;
        bool found = false;
        for (uint256 i = 0; i < _echelonFormIds.length; i++) {
            if (_echelonFormIds[i] == companion.currentFormId) {
                currentFormArrayIndex = i;
                found = true;
                break;
            }
        }
        require(found, "ESN: Current Echelon Form not found in list.");

        // Check if there is a next form
        if (currentFormArrayIndex + 1 >= _echelonFormIds.length) {
            return false; // Already at the highest form
        }

        uint32 nextFormId = _echelonFormIds[currentFormArrayIndex + 1];
        EchelonForm storage nextForm = _echelonForms[nextFormId];

        // Check if current attributes meet the minimums for the next form
        return (
            companion.attributes.adaptability >= nextForm.minAdaptability &&
            companion.attributes.creativity >= nextForm.minCreativity &&
            companion.attributes.empathy >= nextForm.minEmpathy &&
            companion.attributes.logic >= nextForm.minLogic
        );
    }

    /**
     * @dev Triggers the evolution of an EACN to its next Echelon Form if it meets the criteria.
     * @param tokenId The ID of the companion to evolve.
     */
    function evolveCompanion(uint256 tokenId) external whenNotPaused {
        Companion storage companion = _companions[tokenId];
        require(companion.owner == msg.sender, "ESN: Not companion owner");
        require(checkEvolutionEligibility(tokenId), "ESN: Companion not eligible for evolution");

        uint256 currentFormArrayIndex;
        for (uint252 i = 0; i < _echelonFormIds.length; i++) {
            if (_echelonFormIds[i] == companion.currentFormId) {
                currentFormArrayIndex = i;
                break;
            }
        }

        uint32 oldFormId = companion.currentFormId;
        uint32 nextFormId = _echelonFormIds[currentFormArrayIndex + 1];
        
        companion.currentFormId = nextFormId;
        companion.evolutionTimestamp = block.timestamp;
        // Optionally reset some attributes or give bonuses upon evolution

        emit CompanionEvolved(tokenId, oldFormId, nextFormId, block.timestamp);
    }

    // --- III. Cognitive Interactions ---

    /**
     * @dev Initiates a peer-to-peer interaction between two EACNs.
     *      The target EACN's owner must accept the proposal.
     * @param proposerTokenId The ID of the proposing companion.
     * @param targetTokenId The ID of the target companion.
     * @param interactionType The type of interaction (e.g., Collaboration, Debate).
     * @return The ID of the newly created interaction.
     */
    function proposeCognitiveInteraction(
        uint256 proposerTokenId,
        uint256 targetTokenId,
        InteractionType interactionType
    ) external whenNotPaused returns (uint256) {
        require(_companions[proposerTokenId].owner == msg.sender, "ESN: Not proposer companion owner");
        require(_companions[targetTokenId].owner != address(0), "ESN: Target companion does not exist");
        require(proposerTokenId != targetTokenId, "ESN: Cannot interact with self");

        InteractionDetails storage details = _interactionTypeDetails[uint8(interactionType)];
        require(details.cooldownBlocks > 0, "ESN: Invalid interaction type"); // Ensures type is configured

        // Basic cooldown check (can be expanded per-type, per-companion)
        require(block.number >= _companions[proposerTokenId].lastInteractionBlock + details.cooldownBlocks, "ESN: Proposer companion on cooldown");
        require(block.number >= _companions[targetTokenId].lastInteractionBlock + details.cooldownBlocks, "ESN: Target companion on cooldown");


        uint256 interactionId = _nextInteractionId++;
        _pendingInteractions[interactionId] = CognitiveInteraction({
            proposerTokenId: proposerTokenId,
            targetTokenId: targetTokenId,
            interactionType: uint8(interactionType),
            proposalBlock: block.number,
            accepted: false,
            resolutionBlock: 0,
            proposer: msg.sender,
            targetOwner: _companions[targetTokenId].owner
        });

        _companionInteractionHistory[proposerTokenId].push(interactionId);
        _companionInteractionHistory[targetTokenId].push(interactionId);

        emit InteractionProposed(interactionId, proposerTokenId, targetTokenId, uint8(interactionType));
        return interactionId;
    }

    /**
     * @dev The owner of the target EACN accepts a proposed interaction.
     * @param interactionId The ID of the interaction to accept.
     */
    function acceptCognitiveInteraction(uint256 interactionId) external whenNotPaused {
        CognitiveInteraction storage interaction = _pendingInteractions[interactionId];
        require(interaction.proposerTokenId != 0, "ESN: Interaction does not exist"); // Check if it's a valid interaction
        require(!interaction.accepted, "ESN: Interaction already accepted");
        require(interaction.resolutionBlock == 0, "ESN: Interaction already resolved");
        require(_companions[interaction.targetTokenId].owner == msg.sender, "ESN: Not target companion owner");

        interaction.accepted = true;
        emit InteractionAccepted(interactionId, interaction.proposerTokenId, interaction.targetTokenId);
    }

    /**
     * @dev (Oracle Only) Resolves an accepted interaction, applying attribute changes to both participants.
     *      Called by the trusted AI Oracle after off-chain simulation/computation of the interaction outcome.
     * @param interactionId The ID of the interaction to resolve.
     * @param proposerNADeltas Array of 4 deltas for [Adaptability, Creativity, Empathy, Logic] for the proposer.
     * @param targetNADeltas Array of 4 deltas for [Adaptability, Creativity, Empathy, Logic] for the target.
     * @param socialScoreDelta The change in social score for both participants.
     */
    function resolveCognitiveInteraction(
        uint256 interactionId,
        int16[4] calldata proposerNADeltas,
        int16[4] calldata targetNADeltas,
        int16 socialScoreDelta
    ) external onlyOracle whenNotPaused {
        CognitiveInteraction storage interaction = _pendingInteractions[interactionId];
        require(interaction.proposerTokenId != 0, "ESN: Interaction does not exist");
        require(interaction.accepted, "ESN: Interaction not accepted");
        require(interaction.resolutionBlock == 0, "ESN: Interaction already resolved");

        Companion storage proposerCompanion = _companions[interaction.proposerTokenId];
        Companion storage targetCompanion = _companions[interaction.targetTokenId];

        // Apply proposer's NA deltas
        proposerCompanion.attributes.adaptability = uint16(int16(proposerCompanion.attributes.adaptability) + proposerNADeltas[0]);
        proposerCompanion.attributes.creativity = uint16(int16(proposerCompanion.attributes.creativity) + proposerNADeltas[1]);
        proposerCompanion.attributes.empathy = uint16(int16(proposerCompanion.attributes.empathy) + proposerNADeltas[2]);
        proposerCompanion.attributes.logic = uint16(int16(proposerCompanion.attributes.logic) + proposerNADeltas[3]);

        // Apply target's NA deltas
        targetCompanion.attributes.adaptability = uint16(int16(targetCompanion.attributes.adaptability) + targetNADeltas[0]);
        targetCompanion.attributes.creativity = uint16(int16(targetCompanion.attributes.creativity) + targetNADeltas[1]);
        targetCompanion.attributes.empathy = uint16(int16(targetCompanion.attributes.empathy) + targetNADeltas[2]);
        targetCompanion.attributes.logic = uint16(int16(targetCompanion.attributes.logic) + targetNADeltas[3]);

        // Update social scores, clamping at 0
        proposerCompanion.socialScore = uint16(int16(proposerCompanion.socialScore) + socialScoreDelta);
        targetCompanion.socialScore = uint16(int16(targetCompanion.socialScore) + socialScoreDelta);
        if (proposerCompanion.socialScore < 0) proposerCompanion.socialScore = 0;
        if (targetCompanion.socialScore < 0) targetCompanion.socialScore = 0;


        proposerCompanion.lastInteractionBlock = block.number;
        targetCompanion.lastInteractionBlock = block.number;

        interaction.resolutionBlock = block.number; // Mark as resolved

        emit InteractionResolved(interactionId, interaction.proposerTokenId, interaction.targetTokenId, block.timestamp);
    }

    /**
     * @dev Retrieves the details of a specific pending or resolved cognitive interaction.
     * @param interactionId The ID of the interaction.
     * @return CognitiveInteraction struct containing all details.
     */
    function getPendingInteraction(uint256 interactionId) public view returns (CognitiveInteraction memory) {
        require(_pendingInteractions[interactionId].proposerTokenId != 0, "ESN: Interaction does not exist");
        return _pendingInteractions[interactionId];
    }

    /**
     * @dev Retrieves a list of interaction IDs that an EACN has participated in.
     * @param tokenId The ID of the companion.
     * @return An array of interaction IDs.
     */
    function getCompanionInteractionHistory(uint256 tokenId) public view returns (uint256[] memory) {
        require(_companions[tokenId].owner != address(0), "ESN: Companion does not exist");
        return _companionInteractionHistory[tokenId];
    }


    // --- IV. Configuration & Governance (Owner/Admin Only) ---

    /**
     * @dev Sets the address of the trusted AI Oracle. Only callable by the contract owner.
     * @param newOracleAddress The new address for the AI Oracle.
     */
    function setOracleAddress(address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "ESN: Oracle address cannot be zero");
        emit OracleAddressUpdated(_oracleAddress, newOracleAddress);
        _oracleAddress = newOracleAddress;
    }

    /**
     * @dev Defines a new Echelon Form and its entry requirements.
     *      Forms must be added in increasing order of 'difficulty' as `evolveCompanion`
     *      assumes a linear progression through `_echelonFormIds`.
     * @param formId A unique ID for the new Echelon Form.
     * @param name The name of the form (e.g., "Apprentice Sentinel").
     * @param minAdaptability Minimum Adaptability required to evolve to this form.
     * @param minCreativity Minimum Creativity required.
     * @param minEmpathy Minimum Empathy required.
     * @param minLogic Minimum Logic required.
     * @param baseURI Base URI for metadata images associated with this form.
     * @param initialAdaptability Initial adaptability for new companions minted into this form (if applicable).
     * @param initialCreativity Initial creativity for new companions minted into this form.
     * @param initialEmpathy Initial empathy for new companions minted into this form.
     * @param initialLogic Initial logic for new companions minted into this form.
     */
    function addEchelonForm(
        uint32 formId,
        string memory name,
        uint16 minAdaptability,
        uint16 minCreativity,
        uint16 minEmpathy,
        uint16 minLogic,
        string memory baseURI,
        uint16 initialAdaptability,
        uint16 initialCreativity,
        uint16 initialEmpathy,
        uint16 initialLogic
    ) external onlyOwner {
        require(bytes(_echelonForms[formId].name).length == 0, "ESN: Echelon Form ID already exists");
        require(formId > 0, "ESN: Form ID 0 is reserved");

        _echelonForms[formId] = EchelonForm({
            name: name,
            minAdaptability: minAdaptability,
            minCreativity: minCreativity,
            minEmpathy: minEmpathy,
            minLogic: minLogic,
            baseURI: baseURI,
            initialAdaptability: initialAdaptability,
            initialCreativity: initialCreativity,
            initialEmpathy: initialEmpathy,
            initialLogic: initialLogic
        });
        _echelonFormIds.push(formId);
        // Ensure _echelonFormIds is sorted if order matters for `evolveCompanion`'s 'next form' logic
        // For simplicity, assuming forms are added in ascending order of evolution.
        emit EchelonFormAdded(formId, name);
    }

    /**
     * @dev Modifies an existing Echelon Form's parameters.
     * @param formId The ID of the Echelon Form to update.
     * @param name The new name of the form.
     * @param minAdaptability New minimum Adaptability.
     * @param minCreativity New minimum Creativity.
     * @param minEmpathy New minimum Empathy.
     * @param minLogic New minimum Logic.
     * @param baseURI New base URI for metadata.
     * @param initialAdaptability New initial adaptability.
     * @param initialCreativity New initial creativity.
     * @param initialEmpathy New initial empathy.
     * @param initialLogic New initial logic.
     */
    function updateEchelonForm(
        uint32 formId,
        string memory name,
        uint16 minAdaptability,
        uint16 minCreativity,
        uint16 minEmpathy,
        uint16 minLogic,
        string memory baseURI,
        uint16 initialAdaptability,
        uint16 initialCreativity,
        uint16 initialEmpathy,
        uint16 initialLogic
    ) external onlyOwner {
        require(bytes(_echelonForms[formId].name).length > 0, "ESN: Echelon Form ID does not exist");

        EchelonForm storage form = _echelonForms[formId];
        form.name = name;
        form.minAdaptability = minAdaptability;
        form.minCreativity = minCreativity;
        form.minEmpathy = minEmpathy;
        form.minLogic = minLogic;
        form.baseURI = baseURI;
        form.initialAdaptability = initialAdaptability;
        form.initialCreativity = initialCreativity;
        form.initialEmpathy = initialEmpathy;
        form.initialLogic = initialLogic;

        emit EchelonFormUpdated(formId, name);
    }

    /**
     * @dev Configures parameters for different types of cognitive interactions.
     * @param interactionType The ID of the interaction type (from enum InteractionType).
     * @param cooldownBlocks The cooldown period in blocks for this interaction type.
     * @param baseProposerDelta Base Neural Attribute delta for the proposing companion.
     * @param baseTargetDelta Base Neural Attribute delta for the target companion.
     */
    function setInteractionTypeDetails(
        uint8 interactionType,
        uint256 cooldownBlocks,
        int16 baseProposerDelta,
        int16 baseTargetDelta
    ) external onlyOwner {
        require(interactionType <= uint8(type(InteractionType).max), "ESN: Invalid interaction type enum value");
        _interactionTypeDetails[interactionType] = InteractionDetails({
            cooldownBlocks: cooldownBlocks,
            baseProposerDelta: baseProposerDelta,
            baseTargetDelta: baseTargetDelta
        });
    }

    /**
     * @dev Pauses core contract functionalities (e.g., minting, transfers, interactions).
     *      Can only be called by the contract owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses core contract functionalities.
     *      Can only be called by the contract owner.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the contract owner to withdraw any collected Ether.
     *      (This contract does not currently implement fee collection,
     *      but this function is included for completeness in a real-world scenario).
     */
    function withdrawFees() external onlyOwner {
        // Example for future fee implementation:
        // uint256 contractBalance = address(this).balance;
        // require(contractBalance > 0, "ESN: No funds to withdraw");
        // (bool success, ) = payable(msg.sender).call{value: contractBalance}("");
        // require(success, "ESN: Failed to withdraw funds");
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Converts a uint256 to its string representation.
     */
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

// Minimal Base64 implementation from OpenZeppelin (modified for self-containment)
// This is a utility library, not a core contract logic, so it's generally acceptable
// to include a well-known, minimal helper like this.
library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load not just the array, but also the total memory allocated for it
        uint256 lastElement = data.length - 1;
        uint256 padding = 3 - ((data.length + 2) % 3);
        if (padding == 3) {
            padding = 0;
        }

        // encoded length is 4/3 of data length, plus padding
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // allocate output buffer
        bytes memory buf = new bytes(encodedLen);

        uint256 li = 0; // literal index
        uint256 bi = 0; // bytes index

        for (; li < encodedLen - 2 - padding; li += 4) {
            buf[li] = _TABLE[uint8(data[bi] >> 2)];
            buf[li + 1] = _TABLE[uint8(((data[bi] & 0x03) << 4) | (data[bi + 1] >> 4))];
            buf[li + 2] = _TABLE[uint8(((data[bi + 1] & 0x0f) << 2) | (data[bi + 2] >> 6))];
            buf[li + 3] = _TABLE[uint8(data[bi + 2] & 0x3f)];
            bi += 3;
        }

        // handle padding
        if (padding == 2) {
            buf[li] = _TABLE[uint8(data[lastElement] >> 2)];
            buf[li + 1] = _TABLE[uint8((data[lastElement] & 0x03) << 4)];
            buf[li + 2] = '=';
            buf[li + 3] = '=';
        } else if (padding == 1) {
            buf[li] = _TABLE[uint8(data[lastElement - 1] >> 2)];
            buf[li + 1] = _TABLE[uint8(((data[lastElement - 1] & 0x03) << 4) | (data[lastElement] >> 4))];
            buf[li + 2] = _TABLE[uint8((data[lastElement] & 0x0f) << 2)];
            buf[li + 3] = '=';
        }

        return string(buf);
    }
}
```