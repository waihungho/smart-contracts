This smart contract, **ChronoGlyph**, introduces a novel concept of an **evolving, sentient digital entity** that "learns" and "grows" based on on-chain interactions and verified off-chain data. It's designed as a dynamic, non-transferable (soulbound with conditional exceptions) asset that embodies a history of engagement, accumulates "knowledge" (Glyphs/Traits), and can even perform "actions" or "insights" based on its accumulated state.

---

## ChronoGlyph: Sentient Data Construct

### Outline:

1.  **Core Concept:** An evolving, soulbound-like digital entity ("ChronoGlyph") that accumulates traits and knowledge based on on-chain interactions and verified off-chain data.
2.  **ChronoGlyph Lifecycle:** Awakening -> Interaction -> Evolution (Epochs) -> Insight Generation -> Conditional Transfer/Decommissioning.
3.  **Advanced Concepts:**
    *   **Conditional Soulbound:** ChronoGlyphs are non-transferable by default, but can be delegated or conditionally transferred (e.g., for inheritance, or DAO approval).
    *   **Dynamic Traits & Evolution (Epochs):** Glyphs evolve through "Epochs" (levels) and acquire "Traits" based on interaction, oracle data, and internal state.
    *   **On-chain "Sentiment" & "Entropy":** Internal metrics influencing ChronoGlyph behavior and uniqueness.
    *   **Oracle Integration for "Learning":** ChronoGlyphs can "request" external data and "process" it to gain new traits/insights.
    *   **Inter-Glyph Interaction:** Capabilities for Glyphs to interact with each other (e.g., synthesize lore, challenge insights).
    *   **Self-State Manipulation:** Glyphs can enter states like "meditation" to influence their internal metrics.
    *   **External Contract Integration:** Provides an interface for other contracts to query and interact with Glyphs.

### Function Summary:

1.  **`constructor()`**: Initializes the contract, setting the deployer as the owner and establishing initial parameters.
2.  **`awakenChronoGlyph(string memory _name)`**: Mints a new, unique ChronoGlyph for the caller. This is the "soulbound" creation step, generating an initial entropy seed.
3.  **`interactWithGlyph(uint256 _tokenId, int256 _sentimentDelta)`**: The primary interaction method. Users can engage with their ChronoGlyph, updating its `lastInteractionTimestamp` and `sentimentScore`. This interaction contributes to epoch progression.
4.  **`impartKnowledgeGlyph(uint256 _tokenId, GlyphTrait _trait, bytes32 _proof)`**: Allows a trusted oracle (or condition-based system) to grant a specific `GlyphTrait` to a ChronoGlyph, based on verified off-chain data or on-chain proof.
5.  **`requestExternalInsight(uint256 _tokenId, bytes32 _queryHash)`**: Enables a ChronoGlyph (via its owner) to "ask" for specific external data (e.g., "what's the sentiment on AI in Q1 2024?"). The `_queryHash` identifies the specific request.
6.  **`processExternalInsight(uint256 _tokenId, bytes32 _queryHash, string memory _responseData)`**: Only callable by a trusted oracle. Delivers the requested `_responseData` for a specific `_queryHash` to the ChronoGlyph, potentially triggering new trait acquisitions or sentiment adjustments.
7.  **`proposeEpochAdvancement(uint256 _tokenId)`**: A user can propose that their ChronoGlyph attempts to advance to the next Epoch (level). The contract checks if all milestone requirements are met.
8.  **`advanceEpoch(uint256 _tokenId)`**: An internal or automatically triggered function that, upon successful `proposeEpochAdvancement` validation, updates the ChronoGlyph's `epoch` and possibly grants new base traits.
9.  **`delegateChronoGlyphAccess(uint256 _tokenId, address _delegatee, uint64 _expirationTimestamp)`**: Allows a ChronoGlyph owner to grant temporary, restricted control over their Glyph to another address. Useful for dApp integrations or co-management.
10. **`revokeChronoGlyphAccess(uint256 _tokenId)`**: Revokes any active delegation for the specified ChronoGlyph.
11. **`transferChronoGlyphOwnership(uint256 _tokenId, address _newOwner, bytes32 _proof)`**: Enables conditional transfer of ChronoGlyph ownership. This function requires a specific `_proof` (e.g., a hash representing DAO approval, or a specific inheritance key), allowing it to overcome its typical soulbound nature.
12. **`decommissionGlyph(uint256 _tokenId)`**: Allows the owner to permanently retire their ChronoGlyph. This action might have certain conditions or irreversible consequences, representing the "end of life" for a digital entity.
13. **`synthesizeGlyphLore(uint256 _tokenIdA, uint256 _tokenIdB, string memory _prompt)`**: A creative function where two ChronoGlyphs can "interact" to generate a new, unique piece of "lore" or data based on their combined traits and a user-provided prompt. This can yield a new trait or an on-chain record.
14. **`initiateGlyphMeditation(uint256 _tokenId, uint64 _duration)`**: Puts a ChronoGlyph into a "meditative" state for a specified duration. During this state, certain traits might be enhanced, or internal metrics like sentiment/entropy might be re-calibrated.
15. **`challengeGlyphInsight(uint256 _challengerTokenId, uint256 _targetTokenId, bytes32 _insightHash, string memory _challengeRationale)`**: One ChronoGlyph (via its owner) can "challenge" an "insight" or a derived piece of information generated by another ChronoGlyph, initiating a dispute resolution or a vote among other Glyphs (conceptually, not fully implemented dispute system here).
16. **`recalibrateSentiment(uint256 _tokenId, int256 _newSentiment)`**: Allows the owner to attempt to manually recalibrate their ChronoGlyph's sentiment score, possibly costing a fee or requiring certain conditions to prevent spam.
17. **`queryGlyphStateForExternalContract(uint256 _tokenId)`**: Provides a summarized, public view of a ChronoGlyph's key state variables (epoch, sentiment, active traits) for easy integration with other decentralized applications.
18. **`getChronoGlyphDetails(uint256 _tokenId)`**: A comprehensive read-only function returning all stored details of a specific ChronoGlyph.
19. **`getGlyphTraits(uint256 _tokenId)`**: Returns a list of all currently active `GlyphTrait` enums for a ChronoGlyph.
20. **`updateOracleRegistry(address _oracleAddress, bool _isTrusted)`**: Owner function to add or remove trusted oracle addresses who can provide external data.
21. **`setEpochMilestoneRequirements(uint256 _epoch, EpochMilestone calldata _milestone)`**: Owner function to define or update the requirements (e.g., minimum interactions, specific traits) needed for a ChronoGlyph to advance to a particular Epoch.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For int256 calculations

/// @title ChronoGlyph: Sentient Data Construct
/// @author YourName (inspired by various advanced blockchain concepts)
/// @notice A smart contract defining an evolving, dynamic, and conditionally soulbound digital entity.
///         ChronoGlyphs learn from on-chain interactions and verified off-chain data,
///         progress through epochs, and can participate in unique inter-entity actions.

contract ChronoGlyph is Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    using SafeMath for int256; // For sentiment calculations

    // --- Custom Errors ---
    error ChronoGlyph__NotGlyphOwner();
    error ChronoGlyph__GlyphDoesNotExist();
    error ChronoGlyph__GlyphAlreadyAwakened();
    error ChronoGlyph__InvalidEpoch();
    error ChronoGlyph__EpochRequirementsNotMet();
    error ChronoGlyph__NotTrustedOracle();
    error ChronoGlyph__InvalidOracleQuery();
    error ChronoGlyph__DelegationExpired();
    error ChronoGlyph__NoActiveDelegation();
    error ChronoGlyph__InvalidProofForTransfer();
    error ChronoGlyph__AlreadyDecommissioned();
    error ChronoGlyph__InvalidSentimentDelta();
    error ChronoGlyph__MeditationInProgress();
    error ChronoGlyph__NotEnoughTraitsForLore();
    error ChronoGlyph__InsufficientInteractionTime();
    error ChronoGlyph__MaxEpochReached();


    // --- Enums ---
    enum ChronoGlyphStatus {
        Awakened,     // Actively interacting and evolving
        Dormant,      // Inactive for a long period, may require re-activation
        Evolving,     // Currently meeting conditions for next epoch
        Meditating,   // Temporarily in a special state, potentially boosting traits
        Decommissioned // Permanently retired
    }

    enum GlyphTrait {
        None,           // Default/No trait
        Insightful,     // Enhanced data processing
        Resilient,      // Resists negative sentiment
        Adaptive,       // Faster epoch progression
        Empathic,       // Boosts sentiment of other Glyphs
        Analytical,     // Better at external data queries
        Creative,       // Enhances lore synthesis
        Protective,     // Guards against challenges
        Intuitive,      // Generates more accurate insights
        Verbose,        // Produces more detailed lore
        Mystical        // Special rare trait
    }

    // --- Structs ---
    struct ChronoGlyphData {
        address owner;
        string name;
        uint256 epoch;                          // Current epoch (level)
        uint64 creationTimestamp;               // When the Glyph was awakened
        uint64 lastInteractionTimestamp;        // Timestamp of last `interactWithGlyph`
        int256 sentimentScore;                  // Represents its 'mood' or 'positivity' (-100 to 100)
        uint256 entropySeed;                    // A unique, deterministic seed for characteristics
        ChronoGlyphStatus status;
        mapping(GlyphTrait => bool) activeTraits; // What traits this Glyph currently possesses
        uint66 meditationEndTime;               // Timestamp when meditation ends
        uint256 lastLoreSynthesisBlock;         // Block number of last lore synthesis
        uint256 interactionsCount;              // Total number of interactions
    }

    struct EpochMilestone {
        uint256 minInteractions;                // Minimum interactions to reach this epoch
        int256 minSentiment;                    // Minimum sentiment score
        uint64 minAgeInDays;                    // Minimum days since creation
        GlyphTrait requiredTrait;               // A specific trait required for this epoch (or None)
    }

    struct OracleDataFeedEntry {
        bytes32 queryHash;                      // Hash of the specific data query
        string responseData;                    // The actual data response
        uint64 timestamp;                       // When the data was processed
        bool fulfilled;                         // If the query has been fulfilled
    }

    struct Delegation {
        address delegatee;
        uint64 expirationTimestamp;
        bool isActive;
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => ChronoGlyphData) private _chronoGlyphs;
    mapping(address => uint256) private _ownerToTokenId; // Each address can only own one ChronoGlyph
    mapping(address => bool) private _isTrustedOracle;
    mapping(uint256 => EpochMilestone) private _epochMilestones; // Maps epoch number to its requirements
    mapping(uint256 => OracleDataFeedEntry) private _oracleDataQueries; // Maps queryHash to its entry
    mapping(uint256 => Delegation) private _delegations; // Maps tokenId to its active delegation

    uint256 public constant MAX_SENTIMENT = 100;
    uint256 public constant MIN_SENTIMENT = -100;
    uint256 public constant BASE_INTERACTION_SENTIMENT_CHANGE = 5; // Default sentiment change per interaction
    uint256 public constant MIN_TRAITS_FOR_LORE_SYNTHESIS = 2; // Min traits for synthesizeGlyphLore

    // --- Events ---
    event ChronoGlyphAwakened(uint256 indexed tokenId, address indexed owner, string name, uint64 timestamp);
    event ChronoGlyphInteracted(uint256 indexed tokenId, address indexed by, int256 newSentiment, uint64 timestamp);
    event GlyphTraitAcquired(uint256 indexed tokenId, GlyphTrait trait);
    event EpochAdvanced(uint256 indexed tokenId, uint256 newEpoch);
    event ExternalInsightRequested(uint256 indexed tokenId, bytes32 indexed queryHash, address indexed requester);
    event ExternalInsightProcessed(uint256 indexed tokenId, bytes32 indexed queryHash, string responseData);
    event ChronoGlyphDelegated(uint256 indexed tokenId, address indexed delegatee, uint64 expirationTimestamp);
    event ChronoGlyphDelegationRevoked(uint256 indexed tokenId, address indexed delegatee);
    event ChronoGlyphOwnershipTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
    event ChronoGlyphDecommissioned(uint256 indexed tokenId, address indexed owner);
    event GlyphLoreSynthesized(uint256 indexed tokenIdA, uint256 indexed tokenIdB, bytes32 loreHash);
    event GlyphMeditationStarted(uint256 indexed tokenId, uint64 duration);
    event GlyphMeditationEnded(uint256 indexed tokenId);
    event GlyphInsightChallenged(uint256 indexed challengerTokenId, uint256 indexed targetTokenId, bytes32 insightHash);
    event SentimentRecalibrated(uint256 indexed tokenId, int256 oldSentiment, int256 newSentiment);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Initialize default epoch milestones
        _epochMilestones[1] = EpochMilestone(0, 0, 0, GlyphTrait.None); // Epoch 0 -> 1 has no requirements (initial state)
        _epochMilestones[2] = EpochMilestone(5, 10, 1, GlyphTrait.None);
        _epochMilestones[3] = EpochMilestone(15, 20, 7, GlyphTrait.Insightful);
        _epochMilestones[4] = EpochMilestone(30, 40, 30, GlyphTrait.Adaptive);
        _epochMilestones[5] = EpochMilestone(50, 60, 90, GlyphTrait.Analytical);
        // ... more epochs can be added by owner
    }

    // --- External Functions ---

    /**
     * @notice Awakens a new ChronoGlyph for the caller. Each address can only awaken one Glyph.
     * @param _name The desired name for the ChronoGlyph.
     */
    function awakenChronoGlyph(string memory _name) external {
        if (_ownerToTokenId[msg.sender] != 0) {
            revert ChronoGlyph__GlyphAlreadyAwakened();
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Generate a pseudo-random entropy seed for uniqueness
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));

        _chronoGlyphs[newTokenId] = ChronoGlyphData({
            owner: msg.sender,
            name: _name,
            epoch: 1, // Start at Epoch 1
            creationTimestamp: uint64(block.timestamp),
            lastInteractionTimestamp: uint64(block.timestamp),
            sentimentScore: 0, // Neutral sentiment
            entropySeed: entropy,
            status: ChronoGlyphStatus.Awakened,
            meditationEndTime: 0,
            lastLoreSynthesisBlock: 0,
            interactionsCount: 0
        });
        _chronoGlyphs[newTokenId].activeTraits[GlyphTrait.None] = true; // Placeholder for initial state
        _ownerToTokenId[msg.sender] = newTokenId;

        emit ChronoGlyphAwakened(newTokenId, msg.sender, _name, uint64(block.timestamp));
    }

    /**
     * @notice Allows an owner or delegated address to interact with a ChronoGlyph,
     *         updating its last interaction time and sentiment.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _sentimentDelta The change in sentiment score (can be positive or negative).
     * @dev Sentiment is clamped between MIN_SENTIMENT and MAX_SENTIMENT.
     */
    function interactWithGlyph(uint256 _tokenId, int256 _sentimentDelta) external {
        _ensureGlyphExistsAndCanBeControlled(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);
        _ensureGlyphIsNotMeditating(_tokenId);

        if (_sentimentDelta == 0) {
            revert ChronoGlyph__InvalidSentimentDelta();
        }

        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        glyph.sentimentScore = SafeMath.max(MIN_SENTIMENT, SafeMath.min(MAX_SENTIMENT, glyph.sentimentScore.add(_sentimentDelta)));
        glyph.lastInteractionTimestamp = uint64(block.timestamp);
        glyph.interactionsCount++;

        // Glyphs with 'Adaptive' trait might get a bonus sentiment boost or faster progress
        if (glyph.activeTraits[GlyphTrait.Adaptive]) {
            glyph.sentimentScore = SafeMath.max(MIN_SENTIMENT, SafeMath.min(MAX_SENTIMENT, glyph.sentimentScore.add(_sentimentDelta / 2)));
        }

        emit ChronoGlyphInteracted(_tokenId, msg.sender, glyph.sentimentScore, uint64(block.timestamp));
    }

    /**
     * @notice Imparts a specific knowledge trait to a ChronoGlyph.
     *         Callable only by a trusted oracle or if a specific on-chain proof is provided.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _trait The `GlyphTrait` to be granted.
     * @param _proof A cryptographic proof or identifier for the condition being met.
     * @dev For a real system, `_proof` would be verified against specific conditions or external sources.
     */
    function impartKnowledgeGlyph(uint256 _tokenId, GlyphTrait _trait, bytes32 _proof) external {
        _ensureGlyphExists(_tokenId);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        // This function could be restricted to `onlyOwner` for manual grants,
        // or more realistically, an oracle system.
        // For demonstration, let's assume `_proof` verifies some off-chain event for the owner.
        // In a real system, _proof would be more complex and validated.
        // Or, it's called by a trusted oracle address
        if (!_isTrustedOracle[msg.sender] && msg.sender != owner()) {
            revert ChronoGlyph__NotTrustedOracle();
        }

        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        if (!glyph.activeTraits[_trait]) {
            glyph.activeTraits[_trait] = true;
            emit GlyphTraitAcquired(_tokenId, _trait);
        }
    }

    /**
     * @notice Allows a ChronoGlyph owner to request external, verified data from an oracle.
     * @param _tokenId The ID of the ChronoGlyph making the request.
     * @param _queryHash A unique hash representing the specific data query.
     * @dev The actual data will be provided later via `processExternalInsight`.
     */
    function requestExternalInsight(uint256 _tokenId, bytes32 _queryHash) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);
        _ensureGlyphIsNotMeditating(_tokenId);

        // Ensure this query hasn't been requested recently or is not already fulfilled
        if (_oracleDataQueries[_queryHash].fulfilled) {
            revert ChronoGlyph__InvalidOracleQuery();
        }

        // Store query details for the oracle to pick up
        _oracleDataQueries[_queryHash] = OracleDataFeedEntry({
            queryHash: _queryHash,
            responseData: "", // Empty until fulfilled
            timestamp: uint64(block.timestamp),
            fulfilled: false
        });

        emit ExternalInsightRequested(_tokenId, _queryHash, msg.sender);
    }

    /**
     * @notice Callable only by a trusted oracle. Delivers requested external data to a ChronoGlyph.
     *         This can trigger new traits or sentiment adjustments based on the data.
     * @param _tokenId The ID of the ChronoGlyph to update.
     * @param _queryHash The hash of the query being fulfilled.
     * @param _responseData The actual data string from the oracle.
     */
    function processExternalInsight(uint256 _tokenId, bytes32 _queryHash, string memory _responseData) external {
        _ensureGlyphExists(_tokenId);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        if (!_isTrustedOracle[msg.sender]) {
            revert ChronoGlyph__NotTrustedOracle();
        }
        if (!_oracleDataQueries[_queryHash].fulfilled && _oracleDataQueries[_queryHash].queryHash == _queryHash) {
            _oracleDataQueries[_queryHash].responseData = _responseData;
            _oracleDataQueries[_queryHash].fulfilled = true;
            _oracleDataQueries[_queryHash].timestamp = uint64(block.timestamp);

            ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
            // Example: If data contains "positive", sentiment increases. If "negative", decreases.
            if (bytes(_responseData).length > 0) {
                if (keccak256(abi.encodePacked(_responseData)) == keccak256(abi.encodePacked("positive"))) {
                    glyph.sentimentScore = SafeMath.min(MAX_SENTIMENT, glyph.sentimentScore.add(10));
                    if (!glyph.activeTraits[GlyphTrait.Intuitive]) {
                         glyph.activeTraits[GlyphTrait.Intuitive] = true;
                         emit GlyphTraitAcquired(_tokenId, GlyphTrait.Intuitive);
                    }
                } else if (keccak256(abi.encodePacked(_responseData)) == keccak256(abi.encodePacked("negative"))) {
                    glyph.sentimentScore = SafeMath.max(MIN_SENTIMENT, glyph.sentimentScore.sub(10));
                }
            }

            emit ExternalInsightProcessed(_tokenId, _queryHash, _responseData);
        } else {
            revert ChronoGlyph__InvalidOracleQuery(); // Query either doesn't exist or already fulfilled
        }
    }

    /**
     * @notice Allows a ChronoGlyph owner to propose advancing their Glyph to the next Epoch.
     * @param _tokenId The ID of the ChronoGlyph.
     * @dev This checks if all requirements for the next epoch are met.
     */
    function proposeEpochAdvancement(uint256 _tokenId) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);
        _ensureGlyphIsNotMeditating(_tokenId);

        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        uint256 nextEpoch = glyph.epoch + 1;
        EpochMilestone storage milestone = _epochMilestones[nextEpoch];

        if (milestone.minInteractions == 0 && milestone.minSentiment == 0 && milestone.minAgeInDays == 0 && milestone.requiredTrait == GlyphTrait.None) {
            revert ChronoGlyph__MaxEpochReached(); // No more milestones defined
        }

        if (glyph.interactionsCount < milestone.minInteractions) {
            revert ChronoGlyph__EpochRequirementsNotMet();
        }
        if (glyph.sentimentScore < milestone.minSentiment) {
            revert ChronoGlyph__EpochRequirementsNotMet();
        }
        if (uint64(block.timestamp) < glyph.creationTimestamp + milestone.minAgeInDays * 1 days) {
            revert ChronoGlyph__EpochRequirementsNotMet();
        }
        if (milestone.requiredTrait != GlyphTrait.None && !glyph.activeTraits[milestone.requiredTrait]) {
            revert ChronoGlyph__EpochRequirementsNotMet();
        }

        // All requirements met, advance the epoch
        glyph.epoch = nextEpoch;
        emit EpochAdvanced(_tokenId, nextEpoch);
    }

    /**
     * @notice Delegates temporary control of a ChronoGlyph to another address.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _delegatee The address to delegate control to.
     * @param _expirationTimestamp The timestamp when the delegation expires.
     */
    function delegateChronoGlyphAccess(uint256 _tokenId, address _delegatee, uint64 _expirationTimestamp) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        if (_expirationTimestamp <= block.timestamp) {
            revert ChronoGlyph__InvalidEpoch(); // Using this error for invalid timestamp, could be more specific
        }

        _delegations[_tokenId] = Delegation({
            delegatee: _delegatee,
            expirationTimestamp: _expirationTimestamp,
            isActive: true
        });

        emit ChronoGlyphDelegated(_tokenId, _delegatee, _expirationTimestamp);
    }

    /**
     * @notice Revokes an active delegation for a ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph.
     */
    function revokeChronoGlyphAccess(uint256 _tokenId) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        Delegation storage delegation = _delegations[_tokenId];
        if (!delegation.isActive) {
            revert ChronoGlyph__NoActiveDelegation();
        }

        delegation.isActive = false;
        delegation.delegatee = address(0); // Clear delegatee
        delegation.expirationTimestamp = 0;

        emit ChronoGlyphDelegationRevoked(_tokenId, delegation.delegatee);
    }

    /**
     * @notice Conditionally transfers ChronoGlyph ownership.
     *         This is the ONLY way a "soulbound" Glyph can change owner, requiring a specific proof.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _newOwner The address of the new owner.
     * @param _proof A specific, pre-agreed proof (e.g., hash of a will, DAO vote result).
     * @dev For demonstration, a hardcoded proof is used. In a real system, this would be complex.
     */
    function transferChronoGlyphOwnership(uint256 _tokenId, address _newOwner, bytes32 _proof) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        bytes32 expectedProof = keccak256(abi.encodePacked("CHRONOGLYPH_TRANSFER_APPROVED_BY_DAO_OR_INHERITANCE_PROTOCOL", _tokenId, msg.sender, _newOwner));

        if (_proof != expectedProof) {
            revert ChronoGlyph__InvalidProofForTransfer();
        }

        address oldOwner = _chronoGlyphs[_tokenId].owner;
        _chronoGlyphs[_tokenId].owner = _newOwner;
        _ownerToTokenId[oldOwner] = 0; // Clear old owner mapping
        _ownerToTokenId[_newOwner] = _tokenId; // Set new owner mapping

        // Revoke any active delegations upon ownership transfer
        if (_delegations[_tokenId].isActive) {
            _delegations[_tokenId].isActive = false;
        }

        emit ChronoGlyphOwnershipTransferred(_tokenId, oldOwner, _newOwner);
    }

    /**
     * @notice Allows the owner to permanently decommission their ChronoGlyph.
     *         This cannot be undone and changes the Glyph's status to Decommissioned.
     * @param _tokenId The ID of the ChronoGlyph to decommission.
     */
    function decommissionGlyph(uint256 _tokenId) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        _chronoGlyphs[_tokenId].status = ChronoGlyphStatus.Decommissioned;
        // Optionally, clear other data or transfer remaining value.
        // For this contract, it simply becomes inert.

        emit ChronoGlyphDecommissioned(_tokenId, msg.sender);
    }

    /**
     * @notice Allows two ChronoGlyphs to combine their 'experiences' to synthesize new 'lore'.
     *         This might generate new traits, or an on-chain record of their interaction.
     * @param _tokenIdA The ID of the first ChronoGlyph (must be owned by msg.sender).
     * @param _tokenIdB The ID of the second ChronoGlyph (can be any Glyph).
     * @param _prompt A user-provided prompt or context for the lore generation.
     * @dev This is a simplified on-chain "lore" generation. Realistically, it would be more complex.
     */
    function synthesizeGlyphLore(uint256 _tokenIdA, uint256 _tokenIdB, string memory _prompt) external {
        _ensureGlyphExistsAndIsOwner(_tokenIdA, msg.sender);
        _ensureGlyphExists(_tokenIdB);
        _ensureGlyphIsNotDecommissioned(_tokenIdA);
        _ensureGlyphIsNotDecommissioned(_tokenIdB);
        _ensureGlyphIsNotMeditating(_tokenIdA);
        _ensureGlyphIsNotMeditating(_tokenIdB);

        ChronoGlyphData storage glyphA = _chronoGlyphs[_tokenIdA];
        ChronoGlyphData storage glyphB = _chronoGlyphs[_tokenIdB];

        uint256 traitsCountA = _getTraitCount(glyphA);
        uint256 traitsCountB = _getTraitCount(glyphB);

        if (traitsCountA < MIN_TRAITS_FOR_LORE_SYNTHESIS || traitsCountB < MIN_TRAITS_FOR_LORE_SYNTHESIS) {
            revert ChronoGlyph__NotEnoughTraitsForLore();
        }

        // Prevent spamming lore synthesis in the same block
        if (glyphA.lastLoreSynthesisBlock == block.number || glyphB.lastLoreSynthesisBlock == block.number) {
            revert ChronoGlyph__InsufficientInteractionTime();
        }

        bytes32 loreHash = keccak256(abi.encodePacked(
            _tokenIdA,
            _tokenIdB,
            glyphA.epoch,
            glyphB.epoch,
            glyphA.sentimentScore,
            glyphB.sentimentScore,
            glyphA.entropySeed,
            glyphB.entropySeed,
            _prompt,
            block.timestamp
        ));

        // Example: Synthesized lore could grant a new trait if specific conditions met
        if (glyphA.activeTraits[GlyphTrait.Creative] && glyphB.activeTraits[GlyphTrait.Verbose]) {
            if (!glyphA.activeTraits[GlyphTrait.Mystical]) {
                glyphA.activeTraits[GlyphTrait.Mystical] = true;
                emit GlyphTraitAcquired(_tokenIdA, GlyphTrait.Mystical);
            }
        }

        glyphA.lastLoreSynthesisBlock = block.number;
        glyphB.lastLoreSynthesisBlock = block.number;

        emit GlyphLoreSynthesized(_tokenIdA, _tokenIdB, loreHash);
    }

    /**
     * @notice Puts a ChronoGlyph into a "meditative" state for a specified duration.
     *         During meditation, certain internal metrics might be boosted or locked.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _duration The duration in seconds for which the Glyph will meditate.
     */
    function initiateGlyphMeditation(uint256 _tokenId, uint64 _duration) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);

        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.status == ChronoGlyphStatus.Meditating && glyph.meditationEndTime > block.timestamp) {
            revert ChronoGlyph__MeditationInProgress();
        }

        glyph.status = ChronoGlyphStatus.Meditating;
        glyph.meditationEndTime = uint64(block.timestamp + _duration);

        // Example: Sentiment slowly increases during meditation
        // This effect would typically be calculated on `interact` or a specific `endMeditation` call
        // For simplicity, we just set the end time and state here.

        emit GlyphMeditationStarted(_tokenId, _duration);
    }

    /**
     * @notice Allows one ChronoGlyph to "challenge" an insight or derived information from another.
     *         This could initiate a dispute mechanism or a social interaction within the ChronoGlyph ecosystem.
     * @param _challengerTokenId The ID of the ChronoGlyph initiating the challenge.
     * @param _targetTokenId The ID of the ChronoGlyph whose insight is being challenged.
     * @param _insightHash The hash of the specific insight or lore being challenged.
     * @param _challengeRationale A string explaining the reason for the challenge.
     */
    function challengeGlyphInsight(uint256 _challengerTokenId, uint256 _targetTokenId, bytes32 _insightHash, string memory _challengeRationale) external {
        _ensureGlyphExistsAndIsOwner(_challengerTokenId, msg.sender);
        _ensureGlyphExists(_targetTokenId);
        _ensureGlyphIsNotDecommissioned(_challengerTokenId);
        _ensureGlyphIsNotDecommissioned(_targetTokenId);
        _ensureGlyphIsNotMeditating(_challengerTokenId);

        if (_challengerTokenId == _targetTokenId) {
            revert ChronoGlyph__InvalidEpoch(); // Using this error for self-challenge, could be more specific
        }

        // Logic here for what a challenge means. Could cost a fee, record a dispute, etc.
        // For now, it simply emits an event.
        // If the challenger has the 'Protective' trait, maybe their challenge is stronger.
        if (_chronoGlyphs[_challengerTokenId].activeTraits[GlyphTrait.Protective]) {
            // Placeholder for challenge bonus logic
        }

        emit GlyphInsightChallenged(_challengerTokenId, _targetTokenId, _insightHash);
    }

    /**
     * @notice Allows the owner to manually recalibrate their ChronoGlyph's sentiment score.
     *         This might have cooldowns or costs associated with it in a real application.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _newSentiment The target sentiment score.
     */
    function recalibrateSentiment(uint256 _tokenId, int256 _newSentiment) external {
        _ensureGlyphExistsAndIsOwner(_tokenId, msg.sender);
        _ensureGlyphIsNotDecommissioned(_tokenId);
        _ensureGlyphIsNotMeditating(_tokenId);

        if (_newSentiment < MIN_SENTIMENT || _newSentiment > MAX_SENTIMENT) {
            revert ChronoGlyph__InvalidSentimentDelta(); // Re-using error, could be specific
        }

        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        int256 oldSentiment = glyph.sentimentScore;
        glyph.sentimentScore = _newSentiment;

        emit SentimentRecalibrated(_tokenId, oldSentiment, _newSentiment);
    }

    /**
     * @notice Provides a summarized view of a ChronoGlyph's state for external contracts.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return owner The owner's address.
     * @return name The Glyph's name.
     * @return epoch The current epoch.
     * @return sentimentScore The current sentiment score.
     * @return status The current status.
     */
    function queryGlyphStateForExternalContract(uint256 _tokenId)
        external
        view
        returns (address owner, string memory name, uint256 epoch, int256 sentimentScore, ChronoGlyphStatus status)
    {
        _ensureGlyphExists(_tokenId);
        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        return (glyph.owner, glyph.name, glyph.epoch, glyph.sentimentScore, glyph.status);
    }


    // --- Owner-only / Admin Functions ---

    /**
     * @notice Allows the contract owner to update the registry of trusted oracles.
     * @param _oracleAddress The address of the oracle.
     * @param _isTrusted Whether the address should be trusted or not.
     */
    function updateOracleRegistry(address _oracleAddress, bool _isTrusted) external onlyOwner {
        _isTrustedOracle[_oracleAddress] = _isTrusted;
    }

    /**
     * @notice Sets or updates the requirements for a ChronoGlyph to advance to a specific epoch.
     * @param _epoch The epoch number for which to set milestones.
     * @param _milestone The `EpochMilestone` struct containing the requirements.
     */
    function setEpochMilestoneRequirements(uint256 _epoch, EpochMilestone calldata _milestone) external onlyOwner {
        if (_epoch == 0) {
            revert ChronoGlyph__InvalidEpoch();
        }
        _epochMilestones[_epoch] = _milestone;
    }

    // --- View Functions ---

    /**
     * @notice Returns all detailed information about a specific ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return A tuple containing all ChronoGlyphData fields.
     */
    function getChronoGlyphDetails(uint256 _tokenId)
        external
        view
        returns (
            address owner,
            string memory name,
            uint256 epoch,
            uint64 creationTimestamp,
            uint64 lastInteractionTimestamp,
            int256 sentimentScore,
            uint256 entropySeed,
            ChronoGlyphStatus status,
            uint66 meditationEndTime,
            uint256 interactionsCount
        )
    {
        _ensureGlyphExists(_tokenId);
        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        return (
            glyph.owner,
            glyph.name,
            glyph.epoch,
            glyph.creationTimestamp,
            glyph.lastInteractionTimestamp,
            glyph.sentimentScore,
            glyph.entropySeed,
            glyph.status,
            glyph.meditationEndTime,
            glyph.interactionsCount
        );
    }

    /**
     * @notice Returns all active traits for a given ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return An array of `GlyphTrait` enums.
     */
    function getGlyphTraits(uint256 _tokenId) external view returns (GlyphTrait[] memory) {
        _ensureGlyphExists(_tokenId);
        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];

        uint256 traitCount = _getTraitCount(glyph);
        GlyphTrait[] memory traits = new GlyphTrait[](traitCount);
        uint256 index = 0;
        for (uint256 i = 0; i < uint256(GlyphTrait.Mystical) + 1; i++) {
            GlyphTrait currentTrait = GlyphTrait(i);
            if (glyph.activeTraits[currentTrait]) {
                traits[index] = currentTrait;
                index++;
            }
        }
        return traits;
    }

    /**
     * @notice Returns the total number of ChronoGlyphs awakened.
     * @return The current total supply of ChronoGlyphs.
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @notice Returns the ChronoGlyph ID owned by a specific address.
     * @param _owner The address to query.
     * @return The tokenId owned by the address, or 0 if none.
     */
    function getGlyphIdByOwner(address _owner) external view returns (uint256) {
        return _ownerToTokenId[_owner];
    }

    /**
     * @notice Check if an address is a trusted oracle.
     * @param _oracleAddress The address to check.
     * @return True if the address is a trusted oracle, false otherwise.
     */
    function isTrustedOracle(address _oracleAddress) external view returns (bool) {
        return _isTrustedOracle[_oracleAddress];
    }

    // --- Internal & Private Helper Functions ---

    /**
     * @dev Throws if ChronoGlyph does not exist.
     */
    function _ensureGlyphExists(uint256 _tokenId) internal view {
        if (_tokenId == 0 || _tokenId > _tokenIdCounter.current()) {
            revert ChronoGlyph__GlyphDoesNotExist();
        }
    }

    /**
     * @dev Throws if ChronoGlyph does not exist or caller is not owner/delegatee.
     */
    function _ensureGlyphExistsAndCanBeControlled(uint256 _tokenId, address _caller) internal view {
        _ensureGlyphExists(_tokenId);
        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.owner != _caller) {
            Delegation storage delegation = _delegations[_tokenId];
            if (!(delegation.isActive && delegation.delegatee == _caller && delegation.expirationTimestamp > block.timestamp)) {
                revert ChronoGlyph__NotGlyphOwner();
            }
        }
    }

    /**
     * @dev Throws if ChronoGlyph does not exist or caller is not the owner.
     */
    function _ensureGlyphExistsAndIsOwner(uint256 _tokenId, address _caller) internal view {
        _ensureGlyphExists(_tokenId);
        if (_chronoGlyphs[_tokenId].owner != _caller) {
            revert ChronoGlyph__NotGlyphOwner();
        }
    }

    /**
     * @dev Throws if ChronoGlyph is decommissioned.
     */
    function _ensureGlyphIsNotDecommissioned(uint256 _tokenId) internal view {
        if (_chronoGlyphs[_tokenId].status == ChronoGlyphStatus.Decommissioned) {
            revert ChronoGlyph__AlreadyDecommissioned();
        }
    }

    /**
     * @dev Throws if ChronoGlyph is currently meditating.
     */
    function _ensureGlyphIsNotMeditating(uint256 _tokenId) internal view {
        ChronoGlyphData storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.status == ChronoGlyphStatus.Meditating && glyph.meditationEndTime > block.timestamp) {
            revert ChronoGlyph__MeditationInProgress();
        } else if (glyph.status == ChronoGlyphStatus.Meditating && glyph.meditationEndTime <= block.timestamp) {
            // Automatically end meditation if past due
            _chronoGlyphs[_tokenId].status = ChronoGlyphStatus.Awakened;
            emit GlyphMeditationEnded(_tokenId);
        }
    }

    /**
     * @dev Helper to count active traits for a glyph.
     */
    function _getTraitCount(ChronoGlyphData storage glyph) internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < uint256(GlyphTrait.Mystical) + 1; i++) {
            if (glyph.activeTraits[GlyphTrait(i)]) {
                count++;
            }
        }
        return count;
    }

    // --- ERC721Receiver fallback (if this contract were to receive ERC721 tokens for some reason) ---
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // This contract is not designed to hold ERC721 tokens.
        // If it were to receive them, it would reject them by returning an invalid selector.
        // For a contract that needs to hold NFTs, this should return `IERC721Receiver.onERC721Received.selector`.
        return bytes4(0);
    }
}
```