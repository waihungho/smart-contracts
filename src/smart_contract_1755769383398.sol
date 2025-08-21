The `ChronoGlyphProtocol` is a Solidity smart contract designed to manage dynamic, context-aware digital assets called "ChronoGlyphs." These assets are ERC-721 NFTs that possess mutable properties which evolve over time based on external data feeds, user interactions, and their own historical lineage. The protocol introduces advanced concepts such as on-chain adaptive state, conditional utility gating, dynamic royalty distribution, and a unique "transmutation" mechanism for evolving assets.

---

## ChronoGlyph Protocol Outline

**I. Introduction:**
A novel protocol for dynamic, context-aware digital assets (ChronoGlyphs) that evolve based on time, external data, and user interactions. ChronoGlyphs represent a new paradigm for NFTs that are alive, reactive, and hold intrinsic utility tied to their dynamic state.

**II. Core Concepts:**
1.  **ChronoGlyphs (CGs):** ERC-721 NFTs with both an immutable `coreStateHash` (initial properties) and mutable `dynamicState` properties.
2.  **Dynamic State:** Comprises `affinityScore` (reflects interaction quality/data alignment), `temporalCharge` (a time-decaying/accumulating resource), `contextualTraits` (derived from external data), and `lineageScore` (tracks evolution depth). These properties change over time.
3.  **Evolution Triggers:** CG states are updated based on block timestamps, external data (via trusted oracles), and specific user actions. State updates can be explicitly triggered by anyone or implicitly by certain function calls.
4.  **Transmutation:** A unique process where multiple existing ChronoGlyphs are "burned" (consumed) to create a new, evolved ChronoGlyph, inheriting and enhancing properties like `lineageScore`.
5.  **Conditional Utility:** The protocol allows for specific actions, features, or yield generation to be gated or influenced by the ChronoGlyph's current dynamic state, creating adaptive utility.
6.  **Dynamic Royalties:** Royalty percentages on sales of ChronoGlyphs can dynamically adjust based on their `affinityScore` and `lineageScore`.

**III. Roles:**
*   `DEFAULT_ADMIN_ROLE`: Possesses full administrative control, including granting other roles and initial configurations.
*   `ORACLE_ROLE`: Authorized to push external data updates to the protocol.
*   `CONFIG_ROLE`: Allowed to modify core protocol parameters like evolution coefficients, yield rates, and transmutation rules.

**IV. Modules/Function Categories:**
*   **A. Core ChronoGlyph Management:** Standard ERC-721 operations (minting, burning, URI management) with initial state setup.
*   **B. Dynamic State & Evolution:** Logic for recalculating ChronoGlyph dynamic properties and storing historical snapshots.
*   **C. Oracle & Data Integration:** Functions for registering oracles and receiving external data updates.
*   **D. Utility & Interactions:** Mechanics for staking ChronoGlyphs for yield, claiming rewards, performing state-gated actions, and managing dynamic royalties.
*   **E. Transmutation:** Functions for initiating and finalizing the process of evolving ChronoGlyphs into new forms.
*   **F. Protocol Configuration:** Admin/config functions to adjust the rules and parameters governing ChronoGlyph evolution and protocol behavior.

---

## Function Summary

**A. Core ChronoGlyph Management (ERC721 & Base)**
1.  `constructor()`: Initializes the contract, setting the `DEFAULT_ADMIN_ROLE` for the deployer and default protocol parameters.
2.  `mintChronoGlyph(bytes32 _coreStateHash, address _to, uint256 _initialTemporalCharge)`: Mints a new ChronoGlyph NFT, assigning its immutable core properties and initial dynamic state, transferring it to `_to`. Only callable by `DEFAULT_ADMIN_ROLE`.
3.  `burnChronoGlyph(uint256 _tokenId)`: Allows the owner of a ChronoGlyph to burn it, removing it from existence.
4.  `setTokenURI(uint256 _tokenId, string memory _newURI)`: Sets the metadata URI for a specific ChronoGlyph. Can be enhanced with conditional logic based on the glyph's state.

**B. Dynamic State & Evolution**
5.  `triggerGlyphEvolution(uint256 _tokenId)`: Publicly callable function to explicitly recalculate and update a specific ChronoGlyph's dynamic state based on time and current external data.
6.  `batchTriggerGlyphEvolution(uint256[] calldata _tokenIds)`: Allows triggering the evolution of multiple ChronoGlyphs in a single transaction.
7.  `getChronoGlyphState(uint256 _tokenId) returns (ChronoGlyph memory)`: Retrieves the comprehensive current state of a ChronoGlyph. Implicitly triggers a state update if the glyph hasn't evolved recently to ensure freshness.
8.  `getEvolutionHistorySnapshot(uint256 _tokenId, uint256 _snapshotIndex) returns (EvolutionSnapshot memory)`: Provides access to historical snapshots of a ChronoGlyph's dynamic state, capturing its evolution path.

**C. Oracle & Data Integration**
9.  `setOracleAddress(bytes32 _dataKey, address _oracleAddress)`: Assigns a trusted oracle address for a specific data feed (`_dataKey`). Callable by `CONFIG_ROLE`.
10. `updateExternalData(bytes32 _dataKey, uint256 _value, uint64 _timestamp)`: Allows a registered `ORACLE_ROLE` address to push new external data values that influence ChronoGlyph evolution.
11. `getExternalData(bytes32 _dataKey) returns (uint256 value, uint64 timestamp)`: Retrieves the latest value and timestamp for a given external data feed.

**D. Utility & Interactions**
12. `stakeChronoGlyph(uint256 _tokenId)`: Locks a ChronoGlyph, making it eligible to accumulate yield based on its dynamic properties. Claims any pending yield before staking.
13. `unstakeChronoGlyph(uint256 _tokenId)`: Unstakes a ChronoGlyph, stopping yield accumulation and returning it to a transferrable state. Automatically claims all accrued yield.
14. `claimYield(uint256 _tokenId)`: Allows the owner to claim accumulated yield for a staked ChronoGlyph without unstaking it.
15. `getAccruedYield(uint256 _tokenId) returns (uint256)`: Calculates and returns the amount of yield currently accrued for a staked ChronoGlyph without performing a claim.
16. `performConditionalAction(uint256 _tokenId, bytes4 _actionSelector, bytes calldata _actionData)`: A generic gateway function that executes specific protocol actions (e.g., modifying certain glyph properties, unlocking external features) only if the ChronoGlyph's dynamic state meets predefined criteria.
17. `getDynamicRoyaltyAmount(uint256 _tokenId, uint256 _salePrice) returns (uint256 royaltyAmount)`: Calculates the royalty amount for a ChronoGlyph sale, where the royalty percentage dynamically adjusts based on the glyph's `affinityScore` and `lineageScore`.
18. `setDynamicRoyaltyRecipient(uint256 _tokenId, address _newRecipient)`: Allows the owner of a ChronoGlyph to designate a specific address to receive royalties from its sales.

**E. Transmutation**
19. `initiateTransmutation(uint256[] calldata _sourceTokenIds, bytes32 _targetCoreStateHash)`: Initiates a transmutation process. Requires burning multiple source ChronoGlyphs that meet certain dynamic state criteria (e.g., minimum average `affinityScore`) to propose the creation of a new, evolved glyph with a specified `_targetCoreStateHash`.
20. `finalizeTransmutation(uint256 _transmutationId)`: Completes a proposed transmutation after a required cooldown period. It burns the source glyphs and mints the new evolved ChronoGlyph to the initiator, increasing its `lineageScore`.
21. `getTransmutationDetails(uint256 _transmutationId) returns (Transmutation memory)`: Retrieves the full details of a pending or finalized transmutation proposal.

**F. Protocol Configuration**
22. `setEvolutionCoefficient(bytes32 _dataKey, uint256 _coefficient)`: Configures how a specific external data feed (`_dataKey`) influences the calculation of ChronoGlyph dynamic states (e.g., `affinityScore`). Callable by `CONFIG_ROLE`.
23. `setTransmutationParameters(uint256 _minSourceGlyphs, uint256 _cooldownDuration)`: Sets the global rules for transmutation, such as the minimum number of source glyphs required and the cooldown period before finalization. Callable by `CONFIG_ROLE`.
24. `setYieldRate(uint256 _newRate)`: Adjusts the base rate at which staked ChronoGlyphs accumulate yield. Callable by `CONFIG_ROLE`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ChronoGlyphProtocol
 * @dev A novel protocol for dynamic, context-aware digital assets (ChronoGlyphs)
 *      that evolve based on time, external data, and user interactions.
 *      It integrates dynamic NFTs, oracle-driven state changes, conditional utility gating,
 *      dynamic royalties, and a unique 'transmutation' (evolution) mechanic.
 */
contract ChronoGlyphProtocol is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* ========== ROLES & PERMISSIONS ========== */
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    /* ========== CUSTOM ERRORS ========== */
    error InvalidTokenId();
    error NotAuthorized();
    error GlyphNotStaked();
    error GlyphAlreadyStaked();
    error InsufficientTemporalCharge();
    error InvalidTransmutation();
    error TransmutationNotReady();
    error NotGlyphOwner();
    error ExternalDataNotAvailable();
    error InvalidRoyaltyRecipient();
    error TransmutationAlreadyFinalized();
    error TransmutationSourceInvalid();
    error TransmutationTargetExists();
    error ConditionalActionConditionsNotMet(string reason);


    /* ========== DATA STRUCTURES ========== */

    /**
     * @dev ChronoGlyph represents a dynamic, evolving NFT.
     *      Its properties are designed to change over time and based on external factors.
     */
    struct ChronoGlyph {
        bytes32 coreStateHash;      // Immutable: Initial properties (e.g., hashed metadata, base attributes)
        uint64 creationTimestamp;   // Immutable: When the glyph was minted
        uint64 lastEvolutionTimestamp; // Mutable: Last time dynamic state was updated (triggered or implicit)
        uint64 lastActionTimestamp; // Mutable: Last time an owner-specific action was performed (e.g., stake/unstake)

        // Dynamic State Properties (mutable, evolve over time and interactions)
        uint256 affinityScore;      // 0-1000: Reflects interaction quality, data alignment (1000 is max)
        uint256 temporalCharge;     // 0-1,000,000: A time-decaying/accumulating resource (10^6 is max)
        bytes32 contextualTraits;   // Derived hash from external data influencing the glyph's environment
        uint256 lineageScore;       // Tracks the 'ancestry' or evolution depth (increases with successful transmutation)

        // Staking Information
        uint64 stakeTimestamp;      // Timestamp when the glyph was staked (0 if not staked)
        uint256 accumulatedYield;   // Yield pending claim for staked glyphs
    }

    /**
     * @dev EvolutionSnapshot captures a point-in-time state of a ChronoGlyph.
     */
    struct EvolutionSnapshot {
        uint64 timestamp;
        uint256 affinityScore;
        uint256 temporalCharge;
        bytes32 contextualTraits;
        uint256 lineageScore;
    }

    /**
     * @dev Transmutation details for the multi-step evolution process.
     */
    struct Transmutation {
        uint256[] sourceTokenIds;   // IDs of glyphs to be burned
        bytes32 targetCoreStateHash; // Core state hash for the new evolved glyph
        uint64 initiationTimestamp; // When the transmutation was initiated
        uint64 finalizeTimestamp;   // When the transmutation can be finalized (after cooldown)
        address initiator;          // Address who initiated the transmutation
        bool finalized;             // True if transmutation is complete
        uint256 newGlyphId;         // The ID of the new glyph generated upon finalization
    }

    /* ========== STATE VARIABLES ========== */

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _transmutationIdCounter;

    mapping(uint256 => ChronoGlyph) private _chronoGlyphs;
    mapping(uint256 => EvolutionSnapshot[]) private _evolutionHistory;
    
    // External Data Storage: dataKey => latest value & timestamp
    mapping(bytes32 => address) private _oracleAddresses; 
    mapping(bytes32 => uint256) private _externalDataValues; 
    mapping(bytes32 => uint64) private _externalDataTimestamps; 

    // Configuration for how external data influences evolution: dataKey => coefficient
    mapping(bytes32 => uint256) private _evolutionCoefficients; 

    // Protocol-wide parameters
    uint256 public yieldRatePerUnitTemporalCharge; // Base rate for yield calculation (scaled)
    uint256 public transmutationCooldownDuration; // Minimum time before a transmutation can be finalized (seconds)
    uint256 public minSourceGlyphsForTransmutation; // Minimum number of glyphs required for transmutation
    uint256 public affinityScoreThresholdForTransmutation; // Minimum average affinity score of sources for transmutation (0-1000)

    // Transmutation tracking: Transmutation ID => Transmutation details
    mapping(uint256 => Transmutation) private _transmutations; 

    // Dynamic Royalty Recipient: tokenId => designated recipient address
    mapping(uint256 => address) private _dynamicRoyaltyRecipients; 


    /* ========== EVENTS ========== */
    event ChronoGlyphMinted(uint256 indexed tokenId, address indexed owner, bytes32 coreStateHash);
    event ChronoGlyphBurned(uint256 indexed tokenId);
    event ChronoGlyphStateEvolved(uint256 indexed tokenId, uint256 affinityScore, uint256 temporalCharge, bytes32 contextualTraits, uint256 lineageScore);
    event ExternalDataUpdated(bytes32 indexed dataKey, uint256 value, uint64 timestamp);
    event ChronoGlyphStaked(uint256 indexed tokenId, address indexed owner);
    event ChronoGlyphUnstaked(uint256 indexed tokenId, address indexed owner);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event TransmutationInitiated(uint256 indexed transmutationId, address indexed initiator, uint256[] sourceTokenIds, bytes32 targetCoreStateHash);
    event TransmutationFinalized(uint256 indexed transmutationId, uint256 indexed newGlyphId, bytes32 targetCoreStateHash);
    event EvolutionCoefficientSet(bytes32 indexed dataKey, uint256 coefficient);
    event YieldRateSet(uint256 newRate);
    event TransmutationParametersSet(uint256 minSourceGlyphs, uint256 cooldownDuration, uint256 affinityScoreThreshold);
    event DynamicRoyaltyRecipientSet(uint256 indexed tokenId, address indexed newRecipient);
    event ConditionalActionPerformed(uint256 indexed tokenId, bytes4 actionSelector, address indexed caller);


    /* ========== CONSTRUCTOR ========== */

    constructor() ERC721("ChronoGlyph", "CG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender); // Deployer also gets ORACLE_ROLE initially for testing
        _grantRole(CONFIG_ROLE, msg.sender); // Deployer also gets CONFIG_ROLE initially

        // Default initial configurations (can be changed by CONFIG_ROLE)
        yieldRatePerUnitTemporalCharge = 10; // Example: 10 units of yield per (1 unit temporal charge * 1 unit affinity * 1 sec), scaled
        transmutationCooldownDuration = 7 days; // 7 days cooldown for transmutation
        minSourceGlyphsForTransmutation = 2; // Min 2 glyphs to transmute
        affinityScoreThresholdForTransmutation = 500; // Min average 500 affinity score for sources (out of 1000)

        // Set example evolution coefficients for specific data keys
        _evolutionCoefficients[keccak256(abi.encodePacked("market_sentiment"))] = 100; // Positive influence
        _evolutionCoefficients[keccak256(abi.encodePacked("weather_condition"))] = 50; // Moderate influence
        _evolutionCoefficients[keccak256(abi.encodePacked("economic_index"))] = 150; // Strong influence
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Throws if the caller is not the owner of the specified ChronoGlyph.
     * @param _tokenId The ID of the ChronoGlyph to check ownership for.
     */
    modifier onlyGlyphOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != _msgSender()) {
            revert NotGlyphOwner();
        }
        _;
    }

    /* ========== INTERNAL & HELPER FUNCTIONS ========== */

    /**
     * @dev Internal function to recalculate and update a ChronoGlyph's dynamic state.
     *      This function captures the essence of the "adaptive" and "evolving" nature.
     *      It can be called publicly to encourage state updates, or internally before
     *      any action relying on the latest state.
     *      The specific logic for how each dynamic property evolves is defined here.
     * @param _tokenId The ID of the ChronoGlyph to update.
     */
    function _updateDynamicState(uint256 _tokenId) internal {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) revert InvalidTokenId(); 

        uint64 currentTime = uint64(block.timestamp);
        uint64 timeElapsed = currentTime - glyph.lastEvolutionTimestamp;

        // Save current state as snapshot if sufficient time has passed or significant change occurred
        // Snapshotting every hour or on first evolution helps track long-term trends.
        if (timeElapsed >= 1 hours || glyph.lastEvolutionTimestamp == glyph.creationTimestamp) { 
            _evolutionHistory[_tokenId].push(EvolutionSnapshot({
                timestamp: glyph.lastEvolutionTimestamp,
                affinityScore: glyph.affinityScore,
                temporalCharge: glyph.temporalCharge,
                contextualTraits: glyph.contextualTraits,
                lineageScore: glyph.lineageScore
            }));
        }

        // --- TemporalCharge Calculation ---
        // Accumulates passively over time. Staked glyphs might gain more.
        // Also introduces a small passive decay to encourage interaction or staking.
        uint256 temporalGainPerSecond = 5; // Base gain per second
        if (glyph.stakeTimestamp != 0) { 
            temporalGainPerSecond = temporalGainPerSecond.add(5); // Staked glyphs gain more
        }
        uint256 newTemporalCharge = glyph.temporalCharge.add(timeElapsed.mul(temporalGainPerSecond));
        
        // Decay based on inactivity (example: if not staked or no action for a day)
        if (glyph.stakeTimestamp == 0 && currentTime - glyph.lastActionTimestamp > 1 days) {
            newTemporalCharge = newTemporalCharge.mul(99).div(100); // 1% decay per day of inactivity (simplified)
        }
        
        // Cap TemporalCharge
        glyph.temporalCharge = newTemporalCharge > 1000000 ? 1000000 : newTemporalCharge;


        // --- AffinityScore Calculation ---
        // Influenced by external data feeds. Coefficients determine impact.
        bytes32 marketSentimentKey = keccak256(abi.encodePacked("market_sentiment"));
        uint256 marketSentimentValue = _externalDataValues[marketSentimentKey];
        uint256 sentimentCoefficient = _evolutionCoefficients[marketSentimentKey];
        
        // Apply influence from market sentiment (example: scales from 0 to 1000)
        if (marketSentimentValue > 0 && sentimentCoefficient > 0) {
            uint256 sentimentImpact = marketSentimentValue.mul(sentimentCoefficient).div(10000); // Scale down
            glyph.affinityScore = glyph.affinityScore.add(sentimentImpact);
        } else if (marketSentimentValue == 0) { // If no recent sentiment data, slight decay
            glyph.affinityScore = glyph.affinityScore.mul(999).div(1000); // Very small passive decay
        }

        // Ensure affinityScore stays within bounds [0, 1000]
        if (glyph.affinityScore > 1000) glyph.affinityScore = 1000;
        if (glyph.affinityScore < 1) glyph.affinityScore = 0; // Don't go below 0 easily

        // --- ContextualTraits Calculation ---
        // Combined hash of relevant external data points for uniqueness and contextual awareness.
        bytes32 weatherKey = keccak256(abi.encodePacked("weather_condition"));
        bytes32 economicKey = keccak256(abi.encodePacked("economic_index"));
        glyph.contextualTraits = keccak256(abi.encodePacked(
            _externalDataValues[marketSentimentKey],
            _externalDataValues[weatherKey],
            _externalDataValues[economicKey],
            glyph.creationTimestamp // Ensures uniqueness across glyphs
        ));

        // LineageScore increases only upon successful transmutation.

        glyph.lastEvolutionTimestamp = currentTime;

        emit ChronoGlyphStateEvolved(
            _tokenId,
            glyph.affinityScore,
            glyph.temporalCharge,
            glyph.contextualTraits,
            glyph.lineageScore
        );
    }

    /**
     * @dev Calculates the yield accrued for a staked ChronoGlyph based on its current state and time staked.
     *      Yield scales with 'temporalCharge' and 'affinityScore', making dynamic glyphs more rewarding.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return The calculated yield amount.
     */
    function _calculateYield(uint256 _tokenId) internal view returns (uint256) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.stakeTimestamp == 0) return 0; // Not staked

        uint64 timeStaked = uint64(block.timestamp) - glyph.stakeTimestamp;
        
        // Yield = (TemporalCharge * AffinityScore * TimeStaked * YieldRate) / (ScalingFactor)
        // Scaling factor adjusted to make the yield meaningful (e.g., 10^9 for smaller rates)
        uint256 effectiveTemporalCharge = glyph.temporalCharge.mul(glyph.affinityScore).div(1000); // Scale Affinity (max 1M * 1K / 1K = 1M)
        uint256 yieldPerSecond = effectiveTemporalCharge.mul(yieldRatePerUnitTemporalCharge).div(1e9); // Scale down by 10^9 to get a small per-second rate
        
        return yieldPerSecond.mul(timeStaked);
    }

    /* ========== A. Core ChronoGlyph Management (ERC721 & Base) ========== */

    /**
     * @dev Mints a new ChronoGlyph NFT with its initial core and dynamic state.
     *      The initial dynamic state can be set to reasonable defaults.
     * @param _coreStateHash An immutable hash representing the core attributes/metadata of the glyph.
     * @param _to The address to mint the glyph to.
     * @param _initialTemporalCharge Initial temporal charge for the new glyph.
     */
    function mintChronoGlyph(bytes32 _coreStateHash, address _to, uint256 _initialTemporalCharge)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Only admin can mint new base glyphs or via transmutation process.
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _chronoGlyphs[newItemId] = ChronoGlyph({
            coreStateHash: _coreStateHash,
            creationTimestamp: uint64(block.timestamp),
            lastEvolutionTimestamp: uint64(block.timestamp),
            lastActionTimestamp: uint64(block.timestamp),
            affinityScore: 500, // Default starting affinity (mid-range)
            temporalCharge: _initialTemporalCharge,
            contextualTraits: bytes32(0), // Will be updated on first evolution trigger
            lineageScore: 0,
            stakeTimestamp: 0,
            accumulatedYield: 0
        });

        _safeMint(_to, newItemId);
        emit ChronoGlyphMinted(newItemId, _to, _coreStateHash);

        // Trigger initial evolution to set contextual traits and initial calculated state.
        _updateDynamicState(newItemId);
    }

    /**
     * @dev Burns a ChronoGlyph NFT. Only allowed by owner.
     *      Used for general burning or internally by transmutation process.
     * @param _tokenId The ID of the ChronoGlyph to burn.
     */
    function burnChronoGlyph(uint256 _tokenId) public onlyGlyphOwner(_tokenId) {
        if (_chronoGlyphs[_tokenId].stakeTimestamp != 0) revert("Cannot burn staked glyph.");
        _burn(_tokenId); // ERC721 burn
        delete _chronoGlyphs[_tokenId]; // Remove from our custom mapping for state
        emit ChronoGlyphBurned(_tokenId);
    }

    /**
     * @dev Sets the metadata URI for a ChronoGlyph.
     *      Can be conditionally restricted based on glyph state for advanced dynamic metadata updates.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _newURI The new URI for the glyph's metadata.
     */
    function setTokenURI(uint256 _tokenId, string memory _newURI) public onlyGlyphOwner(_tokenId) {
        // Example conditional restriction: Only high affinity glyphs can change their URI easily.
        _updateDynamicState(_tokenId); // Ensure state is fresh for condition check
        if (_chronoGlyphs[_tokenId].affinityScore < 700) {
            revert ConditionalActionConditionsNotMet("Affinity score too low to change URI.");
        }
        _setTokenURI(_tokenId, _newURI);
    }

    /* ========== B. Dynamic State & Evolution ========== */

    /**
     * @dev Triggers the dynamic state evolution for a specific ChronoGlyph.
     *      Anyone can call this to keep a glyph's state fresh.
     * @param _tokenId The ID of the ChronoGlyph to evolve.
     */
    function triggerGlyphEvolution(uint256 _tokenId) public {
        _updateDynamicState(_tokenId);
    }

    /**
     * @dev Batch version of `triggerGlyphEvolution` for multiple glyphs.
     * @param _tokenIds An array of ChronoGlyph IDs to evolve.
     */
    function batchTriggerGlyphEvolution(uint256[] calldata _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _updateDynamicState(_tokenIds[i]);
        }
    }

    /**
     * @dev Retrieves the current comprehensive state of a ChronoGlyph.
     *      It implicitly triggers an update if the last evolution was a while ago,
     *      ensuring the returned state is reasonably fresh without explicit `triggerGlyphEvolution` call.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return The ChronoGlyph struct containing its comprehensive state.
     */
    function getChronoGlyphState(uint256 _tokenId) public returns (ChronoGlyph memory) {
        if (_chronoGlyphs[_tokenId].creationTimestamp == 0) revert InvalidTokenId();
        // Automatically update state if it hasn't been updated recently (e.g., in the last 5 minutes)
        if (block.timestamp - _chronoGlyphs[_tokenId].lastEvolutionTimestamp > 5 minutes) {
            _updateDynamicState(_tokenId);
        }
        return _chronoGlyphs[_tokenId];
    }

    /**
     * @dev Retrieves a historical snapshot of a ChronoGlyph's state.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _snapshotIndex The index of the snapshot in the history array.
     * @return The EvolutionSnapshot struct.
     */
    function getEvolutionHistorySnapshot(uint256 _tokenId, uint256 _snapshotIndex)
        public view
        returns (EvolutionSnapshot memory)
    {
        if (_chronoGlyphs[_tokenId].creationTimestamp == 0) revert InvalidTokenId();
        if (_snapshotIndex >= _evolutionHistory[_tokenId].length) revert("Snapshot index out of bounds");
        return _evolutionHistory[_tokenId][_snapshotIndex];
    }

    /* ========== C. Oracle & Data Integration ========== */

    /**
     * @dev Sets or updates the trusted oracle address for a specific data key.
     *      Only callable by an address with `DEFAULT_ADMIN_ROLE` or `CONFIG_ROLE`.
     * @param _dataKey A unique identifier for the data feed (e.g., `keccak256("market_sentiment")`).
     * @param _oracleAddress The address of the oracle contract or EOA.
     */
    function setOracleAddress(bytes32 _dataKey, address _oracleAddress) public onlyRole(CONFIG_ROLE) {
        _oracleAddresses[_dataKey] = _oracleAddress;
    }

    /**
     * @dev Allows an authorized oracle to push new external data influencing ChronoGlyph states.
     *      Only callable by addresses with `ORACLE_ROLE` that are registered for the specific dataKey.
     * @param _dataKey The identifier for the data feed.
     * @param _value The new value for the data feed.
     * @param _timestamp The timestamp of the data point.
     */
    function updateExternalData(bytes32 _dataKey, uint256 _value, uint64 _timestamp) public onlyRole(ORACLE_ROLE) {
        if (_oracleAddresses[_dataKey] != _msgSender()) revert NotAuthorized(); // Ensure the caller is the registered oracle
        _externalDataValues[_dataKey] = _value;
        _externalDataTimestamps[_dataKey] = _timestamp;
        emit ExternalDataUpdated(_dataKey, _value, _timestamp);
    }

    /**
     * @dev Retrieves the latest external data value and timestamp for a given data key.
     * @param _dataKey The identifier for the data feed.
     * @return value The latest data value.
     * @return timestamp The timestamp of the latest data value.
     */
    function getExternalData(bytes32 _dataKey) public view returns (uint256 value, uint64 timestamp) {
        if (_externalDataTimestamps[_dataKey] == 0) revert ExternalDataNotAvailable();
        return (_externalDataValues[_dataKey], _externalDataTimestamps[_dataKey]);
    }

    /* ========== D. Utility & Interactions ========== */

    /**
     * @dev Stakes a ChronoGlyph, making it eligible for passive yield generation.
     *      Automatically claims any pending yield before re-staking.
     * @param _tokenId The ID of the ChronoGlyph to stake.
     */
    function stakeChronoGlyph(uint256 _tokenId) public onlyGlyphOwner(_tokenId) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) revert InvalidTokenId();
        if (glyph.stakeTimestamp != 0) revert GlyphAlreadyStaked();

        // Claim any previously accumulated yield before starting a new staking period
        uint256 claimable = _calculateYield(_tokenId).add(glyph.accumulatedYield);
        if (claimable > 0) {
            // In a real dApp, transfer ERC20 reward tokens here.
            // Example: IERC20(rewardTokenAddress).transfer(msg.sender, claimable);
            // For this demo, we acknowledge the claim without actual token transfer.
            glyph.accumulatedYield = 0; // Reset after accounting for claim
            emit YieldClaimed(_tokenId, msg.sender, claimable);
        }

        glyph.stakeTimestamp = uint64(block.timestamp);
        glyph.lastActionTimestamp = uint64(block.timestamp);
        _updateDynamicState(_tokenId); // Update state upon staking, potentially boosting temporal charge
        emit ChronoGlyphStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes a ChronoGlyph, stopping yield accumulation and allowing transfers.
     *      Automatically claims all pending yield.
     * @param _tokenId The ID of the ChronoGlyph to unstake.
     */
    function unstakeChronoGlyph(uint256 _tokenId) public onlyGlyphOwner(_tokenId) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) revert InvalidTokenId();
        if (glyph.stakeTimestamp == 0) revert GlyphNotStaked();

        uint256 claimable = _calculateYield(_tokenId).add(glyph.accumulatedYield); // Total yield to claim
        
        // In a real dApp, transfer ERC20 reward tokens here.
        // Example: IERC20(rewardTokenAddress).transfer(msg.sender, claimable);
        // For this demo, we acknowledge the claim.
        
        glyph.accumulatedYield = 0; // Reset accumulated yield after claiming
        glyph.stakeTimestamp = 0; // Unstake the glyph
        glyph.lastActionTimestamp = uint64(block.timestamp);
        _updateDynamicState(_tokenId); // Update state upon unstaking
        emit YieldClaimed(_tokenId, msg.sender, claimable); 
        emit ChronoGlyphUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Claims accumulated yield for a staked ChronoGlyph without unstaking.
     * @param _tokenId The ID of the ChronoGlyph to claim yield for.
     */
    function claimYield(uint256 _tokenId) public onlyGlyphOwner(_tokenId) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) revert InvalidTokenId();
        if (glyph.stakeTimestamp == 0) revert GlyphNotStaked();

        uint256 claimable = _calculateYield(_tokenId).add(glyph.accumulatedYield); // Total yield to claim

        if (claimable == 0) return; // Nothing to claim

        // In a real dApp, transfer ERC20 reward tokens here.
        // Example: IERC20(rewardTokenAddress).transfer(msg.sender, claimable);
        
        glyph.accumulatedYield = 0; // Reset accumulated yield
        glyph.stakeTimestamp = uint64(block.timestamp); // Reset stake timestamp to start new accumulation period
        
        emit YieldClaimed(_tokenId, msg.sender, claimable);
    }
    
    /**
     * @dev Returns the amount of yield currently accrued for a staked ChronoGlyph, without claiming.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return The amount of accrued yield.
     */
    function getAccruedYield(uint256 _tokenId) public view returns (uint256) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) revert InvalidTokenId();
        if (glyph.stakeTimestamp == 0) return 0;
        // Includes previously accumulated yield and newly calculated yield since last claim/stake
        return _calculateYield(_tokenId).add(glyph.accumulatedYield);
    }

    /**
     * @dev A generic gateway function to perform protocol-defined actions
     *      only if the ChronoGlyph's dynamic state meets specific criteria.
     *      This function demonstrates advanced conditional utility.
     *      Note: For a production system, `_actionSelector` would map to a restricted set of internal
     *      functions or a controlled external call mechanism for security.
     * @param _tokenId The ID of the ChronoGlyph to use for the action.
     * @param _actionSelector A bytes4 representing the function signature of the desired action.
     * @param _actionData The ABI-encoded parameters for the desired action (if any).
     */
    function performConditionalAction(uint256 _tokenId, bytes4 _actionSelector, bytes calldata _actionData) public onlyGlyphOwner(_tokenId) {
        // Ensure the glyph state is fresh before checking conditions
        _updateDynamicState(_tokenId);
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];

        // --- Example Conditional Logic for various actions ---
        // This can be expanded into a sophisticated registry of actions and their requirements.
        if (_actionSelector == bytes4(keccak256("upgradeTier()"))) {
            // Example: Upgrade a glyph's "tier" if it has high affinity and temporal charge
            if (glyph.affinityScore < 900) revert ConditionalActionConditionsNotMet("Affinity score too low for tier upgrade.");
            if (glyph.temporalCharge < 100000) revert InsufficientTemporalCharge();
            
            // Consume temporal charge for the action
            glyph.temporalCharge = glyph.temporalCharge.sub(100000);
            glyph.lastActionTimestamp = uint64(block.timestamp);

            // Placeholder for tier upgrade logic (e.g., set an internal tier variable, update metadata)
            // _setTier(_tokenId, glyph.tier + 1); 
            // This is a conceptual function; actual implementation would involve concrete state changes.
            emit ConditionalActionPerformed(_tokenId, _actionSelector, _msgSender());

        } else if (_actionSelector == bytes4(keccak256("accessExclusiveContent()"))) {
            // Example: Access exclusive content if lineage score is high
            if (glyph.lineageScore < 5) revert ConditionalActionConditionsNotMet("Lineage score too low for exclusive content.");
            
            // This action might not consume resources but simply verify eligibility.
            emit ConditionalActionPerformed(_tokenId, _actionSelector, _msgSender());

        } else {
            revert ConditionalActionConditionsNotMet("Unsupported conditional action or conditions not met.");
        }
        emit ChronoGlyphStateEvolved(_tokenId, glyph.affinityScore, glyph.temporalCharge, glyph.contextualTraits, glyph.lineageScore); // Re-emit evolution as state might change
    }
    
    /**
     * @dev Calculates the dynamic royalty amount for a ChronoGlyph based on its evolving state.
     *      This provides a unique dynamic royalty mechanism, instead of a fixed percentage.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _salePrice The price at which the glyph is being sold.
     * @return royaltyAmount The calculated royalty amount.
     */
    function getDynamicRoyaltyAmount(uint256 _tokenId, uint256 _salePrice) public view returns (uint256 royaltyAmount) {
        ChronoGlyph storage glyph = _chronoGlyphs[_tokenId];
        if (glyph.creationTimestamp == 0) return 0; // Not a valid glyph

        // Royalty percentage can be based on AffinityScore and LineageScore
        // Example: Base Royalty 2.5% + (AffinityScore / 1000 * 2.5%) + (LineageScore * 0.2%)
        // Max (250 + 250 + 20*N) basis points (out of 10000 BPS = 100%)
        uint256 baseRoyaltyBPS = 250; // 2.5% in basis points
        uint256 affinityBonusBPS = glyph.affinityScore.mul(250).div(1000); // Max 2.5% bonus based on affinity
        uint256 lineageBonusBPS = glyph.lineageScore.mul(20); // Max 0.2% per lineage point

        uint256 totalRoyaltyBPS = baseRoyaltyBPS.add(affinityBonusBPS).add(lineageBonusBPS);
        
        // Cap total royalty to prevent excessive percentages (e.g., max 15%)
        if (totalRoyaltyBPS > 1500) totalRoyaltyBPS = 1500; 

        return _salePrice.mul(totalRoyaltyBPS).div(10000); // Divide by 10000 for basis points conversion
    }
    
    /**
     * @dev Allows the ChronoGlyph owner to set a custom recipient for their dynamic royalties.
     *      This could be conditionally restricted based on glyph state or lineage.
     * @param _tokenId The ID of the ChronoGlyph.
     * @param _newRecipient The address to receive royalties. Use address(0) to reset to default (owner).
     */
    function setDynamicRoyaltyRecipient(uint256 _tokenId, address _newRecipient) public onlyGlyphOwner(_tokenId) {
        // Optional: Condition this on glyph state, e.g., glyph.lineageScore > X for advanced customization
        // For example, high lineage glyphs might have more control over their destiny.
        _dynamicRoyaltyRecipients[_tokenId] = _newRecipient;
        emit DynamicRoyaltyRecipientSet(_tokenId, _newRecipient);
    }
    
    /**
     * @dev Returns the designated royalty recipient for a ChronoGlyph.
     *      Defaults to the current owner if no custom recipient is set.
     * @param _tokenId The ID of the ChronoGlyph.
     * @return The address of the royalty recipient.
     */
    function getDynamicRoyaltyRecipient(uint256 _tokenId) public view returns (address) {
        address recipient = _dynamicRoyaltyRecipients[_tokenId];
        if (recipient == address(0)) {
            return ownerOf(_tokenId); // Default to current owner if no custom recipient is set
        }
        return recipient;
    }


    /* ========== E. Transmutation ========== */

    /**
     * @dev Initiates a transmutation process, proposing to burn a set of source glyphs
     *      to create a new, potentially more powerful/unique ChronoGlyph.
     *      Requires source glyphs to meet certain conditions (e.g., minimum count, average affinity).
     * @param _sourceTokenIds An array of ChronoGlyph IDs to be used as sources.
     * @param _targetCoreStateHash The immutable core state hash for the new evolved glyph.
     */
    function initiateTransmutation(uint256[] calldata _sourceTokenIds, bytes32 _targetCoreStateHash) public {
        if (_sourceTokenIds.length < minSourceGlyphsForTransmutation) revert TransmutationSourceInvalid();
        if (_targetCoreStateHash == bytes32(0)) revert TransmutationTargetExists(); // Target must be defined

        uint256 totalAffinityScore = 0;
        // Ensure all source glyphs belong to the caller and are not currently staked
        for (uint256 i = 0; i < _sourceTokenIds.length; i++) {
            uint256 tokenId = _sourceTokenIds[i];
            if (ownerOf(tokenId) != _msgSender()) revert NotGlyphOwner();
            if (_chronoGlyphs[tokenId].stakeTimestamp != 0) revert("Source glyph must be unstaked.");

            // Update state before checking, and sum affinity for qualification
            _updateDynamicState(tokenId);
            totalAffinityScore = totalAffinityScore.add(_chronoGlyphs[tokenId].affinityScore);
        }

        // Check average affinity score requirement for transmutation
        if (totalAffinityScore.div(_sourceTokenIds.length) < affinityScoreThresholdForTransmutation) {
            revert ConditionalActionConditionsNotMet("Average affinity score too low for transmutation.");
        }

        _transmutationIdCounter.increment();
        uint256 newTransmutationId = _transmutationIdCounter.current();

        _transmutations[newTransmutationId] = Transmutation({
            sourceTokenIds: _sourceTokenIds,
            targetCoreStateHash: _targetCoreStateHash,
            initiator: _msgSender(),
            initiationTimestamp: uint64(block.timestamp),
            finalizeTimestamp: uint64(block.timestamp).add(transmutationCooldownDuration),
            finalized: false,
            newGlyphId: 0 // Will be set upon finalization
        });

        emit TransmutationInitiated(newTransmutationId, _msgSender(), _sourceTokenIds, _targetCoreStateHash);
    }

    /**
     * @dev Finalizes a proposed transmutation, burning the source glyphs and minting a new one.
     *      Can only be called after the `transmutationCooldownDuration` has passed.
     * @param _transmutationId The ID of the transmutation to finalize.
     */
    function finalizeTransmutation(uint256 _transmutationId) public {
        Transmutation storage trans = _transmutations[_transmutationId];
        if (trans.initiator == address(0)) revert InvalidTransmutation();
        if (trans.initiator != _msgSender()) revert NotAuthorized(); // Only initiator can finalize
        if (trans.finalized) revert TransmutationAlreadyFinalized();
        if (block.timestamp < trans.finalizeTimestamp) revert TransmutationNotReady();

        // Burn source glyphs and calculate new glyph's lineage score
        uint256 newGlyphLineageScore = 0;
        for (uint256 i = 0; i < trans.sourceTokenIds.length; i++) {
            uint256 sourceTokenId = trans.sourceTokenIds[i];
            // Get lineage score BEFORE burning, as _chronoGlyphs[sourceTokenId] will be deleted
            newGlyphLineageScore = newGlyphLineageScore.add(_chronoGlyphs[sourceTokenId].lineageScore); 
            _burn(sourceTokenId); // Burn the NFT from existence
            delete _chronoGlyphs[sourceTokenId]; // Remove from our custom mapping for state
        }

        // Mint the new evolved ChronoGlyph
        _tokenIdCounter.increment();
        uint256 newGlyphId = _tokenIdCounter.current();

        // New glyph's properties are derived from transmutation:
        // Lineage score is sum of sources + 1 (representing a new generation)
        _chronoGlyphs[newGlyphId] = ChronoGlyph({
            coreStateHash: trans.targetCoreStateHash,
            creationTimestamp: uint64(block.timestamp),
            lastEvolutionTimestamp: uint64(block.timestamp),
            lastActionTimestamp: uint64(block.timestamp),
            affinityScore: 750, // New glyph starts with high affinity post-evolution
            temporalCharge: 750000, // New glyph starts with significant charge
            contextualTraits: bytes32(0), // Will be updated on first evolution trigger
            lineageScore: newGlyphLineageScore.add(1), // Lineage increases from combined sources
            stakeTimestamp: 0,
            accumulatedYield: 0
        });

        _safeMint(trans.initiator, newGlyphId); // Mint the new glyph to the initiator
        _updateDynamicState(newGlyphId); // Trigger initial evolution for the newly minted glyph

        trans.finalized = true;
        trans.newGlyphId = newGlyphId;

        emit TransmutationFinalized(_transmutationId, newGlyphId, trans.targetCoreStateHash);
    }

    /**
     * @dev Retrieves the details of a pending or finalized transmutation.
     * @param _transmutationId The ID of the transmutation.
     * @return The Transmutation struct.
     */
    function getTransmutationDetails(uint256 _transmutationId) public view returns (Transmutation memory) {
        Transmutation storage trans = _transmutations[_transmutationId];
        if (trans.initiator == address(0)) revert InvalidTransmutation();
        return trans;
    }

    /* ========== F. Protocol Configuration ========== */

    /**
     * @dev Sets the coefficient for how a specific external data feed influences ChronoGlyph evolution.
     *      Requires `CONFIG_ROLE`.
     * @param _dataKey The identifier for the data feed.
     * @param _coefficient The new coefficient value (e.g., 100 for 1x impact if scaled).
     */
    function setEvolutionCoefficient(bytes32 _dataKey, uint256 _coefficient) public onlyRole(CONFIG_ROLE) {
        _evolutionCoefficients[_dataKey] = _coefficient;
        emit EvolutionCoefficientSet(_dataKey, _coefficient);
    }

    /**
     * @dev Sets parameters for the transmutation process.
     *      Requires `CONFIG_ROLE`.
     * @param _minSourceGlyphs The minimum number of source glyphs required for transmutation.
     * @param _cooldownDuration The duration (in seconds) that must pass before a transmutation can be finalized.
     * @param _affinityScoreThreshold The minimum average affinity score required for source glyphs.
     */
    function setTransmutationParameters(uint256 _minSourceGlyphs, uint256 _cooldownDuration, uint256 _affinityScoreThreshold) public onlyRole(CONFIG_ROLE) {
        minSourceGlyphsForTransmutation = _minSourceGlyphs;
        transmutationCooldownDuration = _cooldownDuration;
        affinityScoreThresholdForTransmutation = _affinityScoreThreshold;
        emit TransmutationParametersSet(_minSourceGlyphs, _cooldownDuration, _affinityScoreThreshold);
    }

    /**
     * @dev Sets the base yield rate for staked ChronoGlyphs.
     *      Requires `CONFIG_ROLE`.
     * @param _newRate The new yield rate (e.g., 10 for 10 units of yield scaled by other factors).
     */
    function setYieldRate(uint256 _newRate) public onlyRole(CONFIG_ROLE) {
        yieldRatePerUnitTemporalCharge = _newRate;
        emit YieldRateSet(_newRate);
    }

    /* ========== AccessControl Overrides ========== */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```