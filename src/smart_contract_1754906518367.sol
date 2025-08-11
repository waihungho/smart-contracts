Here's a smart contract in Solidity called `ChronicleForge`, designed around the concept of "Aetherial Entities" (AEs) – dynamic, evolving NFTs with a rich set of interactions, reputation, and time-based mechanics, all influenced by internal resources, external data (abstracted via oracles), and decentralized governance. It aims to be creative, advanced, and distinct from typical open-source projects.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath is built-in for 0.8.0+ but kept for clarity/backward compatibility
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/*
*   Contract: ChronicleForge
*   Description: A decentralized protocol for managing "Aetherial Entities" (AEs), which are dynamic,
*                reputation-driven NFTs that evolve based on on-chain activity, time, and community governance.
*                AEs consume and generate "Essence" (an internal resource) and possess a "Resilience Score"
*                (reputation). The system features dynamic attribute evolution, time-based decay, and a governance
*                mechanism for "Universal Directives" that influence all AEs. It incorporates an abstract
*                "Oracle Nexus" for potential future integration of external data or AI insights, and an internal
*                "Temporal Flux" mechanism for time-based processes.
*
*   Outline & Function Summary:
*
*   I. Core Entity Management (Dynamic NFTs):
*      - forgeNewEntity(): Mints a new Aetherial Entity (AE) with initial random/base attributes.
*      - getEntityAttributes(): Views the current mutable attributes of a specified AE.
*      - getEssenceBalance(): Retrieves the current accumulated Essence for a given AE.
*      - getResilienceScore(): Retrieves the current Resilience Score of a specified AE.
*      - getTotalEntities(): Returns the total number of Aetherial Entities currently forged.
*
*   II. Dynamic Attribute & Evolution System:
*      - calibrateAttribute(): Allows an AE's owner to spend 'Essence' to enhance a specific attribute.
*      - distributeEssence(uint256 _tokenId, uint256 _amount): Internal/privileged function to award Essence to an AE,
*                                                               often triggered by on-chain activity, oracle data, or system events.
*      - decayAttributes(): Triggers the time-based decay of certain attributes for a specified AE,
*                           representing natural entropy or resource consumption.
*      - rejuvenateEntity(): Spends Essence (or a fee) to counteract attribute decay or reset an AE's "age".
*
*   III. Reputation & Interaction System:
*      - updateResilienceScore(uint256 _tokenId, int256 _scoreChange): Internal/privileged function to modify an AE's Resilience Score,
*                                                                      reflecting its positive or negative engagement within the ecosystem.
*      - initiateInterdimensionalLink(): Enables two AEs to form a "link," fostering collaboration and potentially boosting their
*                                        Resilience or Essence upon successful resolution.
*      - resolveInterdimensionalLink(): Finalizes an interdimensional link, distributing rewards or penalties
*                                       based on predefined conditions (e.g., successful link completion or expiry).
*      - getLinkDetails(): Views the details of an active interdimensional link.
*
*   IV. Oracle & Temporal Flux Integration:
*      - submitOracleData(): Allows a whitelisted oracle to submit external data that can influence AE evolution
*                            or system parameters (abstracted for this contract).
*      - triggerTemporalFluxUpdate(): A system-level function (e.g., called by a Keeper network) to process
*                                     time-sensitive events like global attribute decay or activate Universal Directives.
*      - setOracleAddress(): Admin function to set or update the address of the trusted Oracle Nexus.
*      - getTemporalFluxLastUpdate(): Returns the timestamp of the last global temporal flux update.
*
*   V. Governance & Universal Directives (DAO-like):
*      - proposeUniversalDirective(): Allows entities with sufficient Resilience to propose changes to system
*                                     parameters or evolution rules, or global events affecting all AEs.
*      - voteOnDirective(): Enables eligible participants (e.g., AE holders, high-Resilience AEs) to vote on proposals.
*      - executeDirective(): Executes a passed Universal Directive, applying its effects to the ChronicleForge.
*      - getCurrentDirectiveParameters(): Views the currently active global parameters or directives influencing AEs.
*      - getProposalDetails(): Views the details of a specific Universal Directive proposal.
*
*   VI. Advanced Concepts & Utility:
*      - synthesizeAether(): Allows an AE that has reached peak attributes/resilience to "synthesize Aether"
*                            (a unique reward/state) or initiate a transcendent phase.
*      - disintegrateEntity(): Allows an AE's owner to burn the entity, potentially recovering some Essence
*                              or receiving a final symbolic reward.
*      - withdrawFunds(): Allows the contract owner to withdraw any collected fees or excess funds.
*      - togglePausableState(): Allows the contract owner to pause/unpause critical functions in an emergency.
*      - setEssenceConversionRate(): Admin function to adjust the rate at which Essence can be used for actions
*                                    (placeholder for a governance-controlled parameter).
*/

contract ChronicleForge is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Explicitly using SafeMath for 0.8.0+ for clarity, though it's default.

    // --- State Variables ---

    // ERC721 Token Counter
    Counters.Counter private _tokenIdCounter;

    // Aetherial Entity Data
    enum AttributeType { STRENGTH, AGILITY, INTELLECT, AWARENESS }
    struct AetherialEntity {
        uint256 tokenId; // Redundant but helpful for direct mapping
        uint256 forgedAt; // Timestamp of creation
        uint256 lastEssenceDistribution; // Timestamp of last passive Essence distribution
        uint256 lastAttributeDecayCheck; // Timestamp of last attribute decay check
        uint256 essenceBalance;
        int256 resilienceScore; // Can be positive or negative
        uint256 strength;
        uint256 agility;
        uint256 intellect;
        uint256 awareness;
        bool isTranscendent; // True if entity has synthesized Aether
    }
    mapping(uint256 => AetherialEntity) private _entities;
    // _entityOwner mapping is redundant with ERC721's _owners, but provides a direct internal reference.
    // However, for ERC721 compliance, ownerOf() should always be used.
    // Keeping for illustrative purposes if specific lookups were needed without external calls.
    mapping(uint256 => address) private _entityOwnerMap; // Used internally for custom logic where ERC721.ownerOf isn't direct

    // Global parameters (can be made mutable via governance)
    uint256 public constant BASE_ATTRIBUTE_VALUE = 100;
    uint256 public constant REJUVENATION_ESSENCE_COST = 500;
    uint256 public constant ATTRIBUTE_DECAY_RATE_PER_DAY = 1; // Points
    uint256 public constant ESSENCE_DECAY_RATE_PER_DAY = 5; // Points
    uint256 public constant ESSENCE_DISTRIBUTION_INTERVAL = 1 days; // How often passive essence is given (e.g., by temporal flux)
    uint256 public constant RESILIENCE_SCORE_FOR_PROPOSAL = 1000; // Minimum resilience to propose a directive
    uint256 public constant DIRECTIVE_VOTING_PERIOD = 3 days;
    uint256 public constant INTERDIMENSIONAL_LINK_DURATION = 1 days;
    
    // This should ideally be a mutable state variable updated by governance, not a constant.
    // For this example, we'll demonstrate its use as if it were.
    uint256 public essenceCostPerAttributePoint; 

    // Oracle Nexus
    address public oracleAddress;
    uint256 public lastTemporalFluxUpdate; // Last time triggerTemporalFluxUpdate was called

    // Universal Directives (Governance)
    struct UniversalDirective {
        uint256 proposalId;
        address proposer;
        uint256 creationTime;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed; // True if votesFor > votesAgainst after deadline
        bytes proposalData; // Encoded data for the directive (e.g., new parameter values)
        mapping(address => bool) hasVoted; // Tracks unique voters by address
    }
    Counters.Counter private _directiveIdCounter;
    mapping(uint256 => UniversalDirective) public universalDirectives;

    // Interdimensional Links
    struct InterdimensionalLink {
        uint256 linkId;
        uint256 entity1;
        uint256 entity2;
        uint256 initiatedAt;
        uint256 expiryAt;
        bool resolved;
        address initiator;
        uint256 essenceReward; // Potential reward for successful link
    }
    Counters.Counter private _linkIdCounter;
    mapping(uint256 => InterdimensionalLink) public interdimensionalLinks;

    // --- Events ---
    event EntityForged(uint256 indexed tokenId, address indexed owner, uint256 forgedAt);
    event AttributeCalibrated(uint256 indexed tokenId, AttributeType indexed attrType, uint252 newAmount, uint256 essenceSpent);
    event EssenceDistributed(uint256 indexed tokenId, uint256 amount);
    event AttributesDecayed(uint256 indexed tokenId, uint256 strengthDecay, uint256 agilityDecay, uint256 intellectDecay, uint256 awarenessDecay);
    event EntityRejuvenated(uint256 indexed tokenId);
    event ResilienceScoreUpdated(uint256 indexed tokenId, int256 newScore);
    event InterdimensionalLinkInitiated(uint256 indexed linkId, uint256 indexed entity1, uint256 indexed entity2, address indexed initiator);
    event InterdimensionalLinkResolved(uint256 indexed linkId, uint256 indexed entity1, uint256 indexed entity2, uint256 essenceAwarded);
    event OracleDataSubmitted(bytes32 indexed key, uint256 value);
    event TemporalFluxUpdated(uint256 timestamp);
    event UniversalDirectiveProposed(uint256 indexed proposalId, address indexed proposer, uint256 creationTime, uint256 votingDeadline);
    event UniversalDirectiveVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event UniversalDirectiveExecuted(uint256 indexed proposalId, bool passed);
    event AetherSynthesized(uint256 indexed tokenId);
    event EntityDisintegrated(uint256 indexed tokenId, address indexed owner, uint256 essenceRefunded);
    event EssenceConversionRateSet(uint256 newRate);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "ChronicleForge: Only Oracle can call this function");
        _;
    }

    // Custom modifier to check if the caller is the owner or approved for a given token
    modifier onlyEntityOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ChronicleForge: Not entity owner or approved");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("Aetherial Entity", "AE") Ownable(_msgSender()) {
        oracleAddress = address(0); // Placeholder, set via `setOracleAddress`
        lastTemporalFluxUpdate = block.timestamp;
        essenceCostPerAttributePoint = 10; // Initial value for the mutable parameter
    }

    // --- I. Core Entity Management (Dynamic NFTs) ---

    /**
     * @notice Mints a new Aetherial Entity (AE) with initial random/base attributes.
     * @dev Initial attributes are set to BASE_ATTRIBUTE_VALUE. Essence and Resilience start at 0.
     *      Requires a small fee to forge a new entity.
     * @return newTokenId The ID of the newly forged entity.
     */
    function forgeNewEntity() public payable whenNotPaused returns (uint256) {
        // Example: Require a small fee (e.g., 0.01 ETH) to forge a new entity
        require(msg.value >= 0.01 ether, "ChronicleForge: Insufficient fee to forge entity (0.01 ETH required)");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        AetherialEntity storage newEntity = _entities[newTokenId];
        newEntity.tokenId = newTokenId; // Storing tokenId inside struct for completeness
        newEntity.forgedAt = block.timestamp;
        newEntity.lastEssenceDistribution = block.timestamp;
        newEntity.lastAttributeDecayCheck = block.timestamp;
        newEntity.essenceBalance = 0;
        newEntity.resilienceScore = 0;
        newEntity.strength = BASE_ATTRIBUTE_VALUE;
        newEntity.agility = BASE_ATTRIBUTE_VALUE;
        newEntity.intellect = BASE_ATTRIBUTE_VALUE;
        newEntity.awareness = BASE_ATTRIBUTE_VALUE;
        newEntity.isTranscendent = false;

        _safeMint(_msgSender(), newTokenId);
        _entityOwnerMap[newTokenId] = _msgSender(); // Update custom owner map

        emit EntityForged(newTokenId, _msgSender(), block.timestamp);
        return newTokenId;
    }

    /**
     * @notice Views the current mutable attributes of a specified AE.
     * @param _tokenId The ID of the Aetherial Entity.
     * @return A tuple containing strength, agility, intellect, and awareness.
     */
    function getEntityAttributes(uint256 _tokenId) public view returns (uint256 strength, uint256 agility, uint256 intellect, uint256 awareness) {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        AetherialEntity storage entity = _entities[_tokenId];
        return (entity.strength, entity.agility, entity.intellect, entity.awareness);
    }

    /**
     * @notice Retrieves the current accumulated Essence for a given AE.
     * @param _tokenId The ID of the Aetherial Entity.
     * @return The current essence balance.
     */
    function getEssenceBalance(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        return _entities[_tokenId].essenceBalance;
    }

    /**
     * @notice Retrieves the current Resilience Score of a specified AE.
     * @param _tokenId The ID of the Aetherial Entity.
     * @return The current resilience score.
     */
    function getResilienceScore(uint256 _tokenId) public view returns (int256) {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        return _entities[_tokenId].resilienceScore;
    }

    /**
     * @notice Returns the total number of Aetherial Entities currently forged.
     * @return The total supply of entities.
     */
    function getTotalEntities() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Override _transfer and _burn to update internal _entityOwnerMap and delete entity data
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        _entityOwnerMap[tokenId] = to; // Keep custom map in sync
    }

    function _burn(uint256 tokenId) internal override(ERC721) { // Explicitly override ERC721's _burn
        super._burn(tokenId);
        delete _entityOwnerMap[tokenId]; // Clear custom owner map
        delete _entities[tokenId]; // Delete entity data
    }

    // --- II. Dynamic Attribute & Evolution System ---

    /**
     * @notice Allows an AE's owner to spend 'Essence' to enhance a specific attribute.
     * @param _tokenId The ID of the Aetherial Entity.
     * @param _attr The type of attribute to calibrate (STRENGTH, AGILITY, INTELLECT, AWARENESS).
     * @param _amount The amount of attribute points to add.
     */
    function calibrateAttribute(uint256 _tokenId, AttributeType _attr, uint256 _amount) public onlyEntityOwner(_tokenId) whenNotPaused {
        require(_amount > 0, "ChronicleForge: Calibration amount must be positive");
        AetherialEntity storage entity = _entities[_tokenId];
        uint256 essenceCost = _amount.mul(essenceCostPerAttributePoint); // Uses mutable parameter
        require(entity.essenceBalance >= essenceCost, "ChronicleForge: Insufficient Essence for calibration");

        entity.essenceBalance = entity.essenceBalance.sub(essenceCost);

        if (_attr == AttributeType.STRENGTH) {
            entity.strength = entity.strength.add(_amount);
        } else if (_attr == AttributeType.AGILITY) {
            entity.agility = entity.agility.add(_amount);
        } else if (_attr == AttributeType.INTELLECT) {
            entity.intellect = entity.intellect.add(_amount);
        } else if (_attr == AttributeType.AWARENESS) {
            entity.awareness = entity.awareness.add(_amount);
        }

        emit AttributeCalibrated(_tokenId, _attr, _amount, essenceCost);
    }

    /**
     * @notice An internal/privileged function to award Essence to an AE.
     * @dev Can be called by the system (e.g., via `triggerTemporalFluxUpdate` for passive generation)
     *      or by the Oracle Nexus based on external events/achievements.
     * @param _tokenId The ID of the Aetherial Entity.
     * @param _amount The amount of Essence to distribute.
     */
    function distributeEssence(uint256 _tokenId, uint256 _amount) internal {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        require(_amount > 0, "ChronicleForge: Distribution amount must be positive");

        _entities[_tokenId].essenceBalance = _entities[_tokenId].essenceBalance.add(_amount);
        _entities[_tokenId].lastEssenceDistribution = block.timestamp; // Update last distribution time
        emit EssenceDistributed(_tokenId, _amount);
    }

    /**
     * @notice Triggers the time-based decay of certain attributes and Essence for a specified AE.
     * @dev Can be called by anyone, but includes logic to only apply decay once per set period,
     *      making it a "pull" function incentivized by external keepers or users.
     * @param _tokenId The ID of the Aetherial Entity.
     */
    function decayAttributes(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        AetherialEntity storage entity = _entities[_tokenId];

        uint256 timeSinceLastDecay = block.timestamp.sub(entity.lastAttributeDecayCheck);
        uint256 daysPassed = timeSinceLastDecay.div(1 days);

        if (daysPassed == 0) return; // No decay needed yet for this entity

        uint256 strengthDecay = daysPassed.mul(ATTRIBUTE_DECAY_RATE_PER_DAY);
        uint256 agilityDecay = daysPassed.mul(ATTRIBUTE_DECAY_RATE_PER_DAY);
        uint256 intellectDecay = daysPassed.mul(ATTRIBUTE_DECAY_RATE_PER_DAY);
        uint256 awarenessDecay = daysPassed.mul(ATTRIBUTE_DECAY_RATE_PER_DAY);

        // Ensure attributes don't drop below BASE_ATTRIBUTE_VALUE
        entity.strength = entity.strength > strengthDecay ? entity.strength.sub(strengthDecay) : BASE_ATTRIBUTE_VALUE;
        entity.agility = entity.agility > agilityDecay ? entity.agility.sub(agilityDecay) : BASE_ATTRIBUTE_VALUE;
        entity.intellect = entity.intellect > intellectDecay ? entity.intellect.sub(intellectDecay) : BASE_ATTRIBUTE_VALUE;
        entity.awareness = entity.awareness > awarenessDecay ? entity.awareness.sub(awarenessDecay) : BASE_ATTRIBUTE_VALUE;

        // Essence can also decay over time
        uint256 essenceDecay = daysPassed.mul(ESSENCE_DECAY_RATE_PER_DAY);
        entity.essenceBalance = entity.essenceBalance > essenceDecay ? entity.essenceBalance.sub(essenceDecay) : 0;

        entity.lastAttributeDecayCheck = block.timestamp; // Update decay check timestamp
        emit AttributesDecayed(_tokenId, strengthDecay, agilityDecay, intellectDecay, awarenessDecay);
    }

    /**
     * @notice Spends Essence (or a fee) to counteract attribute decay or reset an AE's "age" for certain benefits.
     *         Resets attributes to base value and provides a small resilience boost.
     * @param _tokenId The ID of the Aetherial Entity.
     */
    function rejuvenateEntity(uint256 _tokenId) public onlyEntityOwner(_tokenId) whenNotPaused {
        AetherialEntity storage entity = _entities[_tokenId];
        require(entity.essenceBalance >= REJUVENATION_ESSENCE_COST, "ChronicleForge: Insufficient Essence for rejuvenation");

        entity.essenceBalance = entity.essenceBalance.sub(REJUVENATION_ESSENCE_COST);
        
        // Reset decay timers and attributes to base or a slightly higher value
        entity.lastAttributeDecayCheck = block.timestamp;
        entity.forgedAt = block.timestamp; // "Resets" the age for any age-based mechanics
        entity.strength = BASE_ATTRIBUTE_VALUE;
        entity.agility = BASE_ATTRIBUTE_VALUE;
        entity.intellect = BASE_ATTRIBUTE_VALUE;
        entity.awareness = BASE_ATTRIBUTE_VALUE;

        // Optionally, give a small resilience boost for active maintenance
        updateResilienceScore(_tokenId, 50); 

        emit EntityRejuvenated(_tokenId);
    }

    // --- III. Reputation & Interaction System ---

    /**
     * @notice An internal/privileged function to modify an AE's Resilience Score.
     * @dev This could be called by specific game mechanics, oracle results, or governance decisions.
     * @param _tokenId The ID of the Aetherial Entity.
     * @param _scoreChange The amount to change the score by (positive for increase, negative for decrease).
     */
    function updateResilienceScore(uint256 _tokenId, int256 _scoreChange) internal {
        require(_exists(_tokenId), "ChronicleForge: Entity does not exist");
        
        _entities[_tokenId].resilienceScore = _entities[_tokenId].resilienceScore.add(_scoreChange);
        emit ResilienceScoreUpdated(_tokenId, _entities[_tokenId].resilienceScore);
    }

    /**
     * @notice Enables two AEs to form an "interdimensional link," fostering collaboration.
     * @dev Requires caller to own one of the entities. Initiator pays no direct fee in this example,
     *      but future versions could involve a cost.
     * @param _entity1 The ID of the first Aetherial Entity.
     * @param _entity2 The ID of the second Aetherial Entity.
     */
    function initiateInterdimensionalLink(uint256 _entity1, uint256 _entity2) public whenNotPaused {
        require(_exists(_entity1) && _exists(_entity2), "ChronicleForge: Both entities must exist");
        require(_entity1 != _entity2, "ChronicleForge: Cannot link an entity to itself");
        require(ownerOf(_entity1) == _msgSender() || ownerOf(_entity2) == _msgSender(), "ChronicleForge: Must own one of the entities to initiate a link");

        _linkIdCounter.increment();
        uint256 newLinkId = _linkIdCounter.current();

        interdimensionalLinks[newLinkId] = InterdimensionalLink({
            linkId: newLinkId,
            entity1: _entity1,
            entity2: _entity2,
            initiatedAt: block.timestamp,
            expiryAt: block.timestamp.add(INTERDIMENSIONAL_LINK_DURATION),
            resolved: false,
            initiator: _msgSender(),
            essenceReward: 0 // Will be set on resolution
        });

        emit InterdimensionalLinkInitiated(newLinkId, _entity1, _entity2, _msgSender());
    }

    /**
     * @notice Finalizes an interdimensional link, distributing rewards or penalties based on its resolution.
     * @dev Can be called by either owner of the linked entities. Checks if link is expired for outcome.
     * @param _linkId The ID of the interdimensional link.
     */
    function resolveInterdimensionalLink(uint256 _linkId) public whenNotPaused {
        InterdimensionalLink storage link = interdimensionalLinks[_linkId];
        require(link.entity1 != 0, "ChronicleForge: Link does not exist");
        require(!link.resolved, "ChronicleForge: Link already resolved");
        require(ownerOf(link.entity1) == _msgSender() || ownerOf(link.entity2) == _msgSender(), "ChronicleForge: Not an owner of linked entities");
        
        uint256 reward = 0;
        int256 scoreChange = 0;

        if (block.timestamp < link.expiryAt) {
            // Successful resolution before expiry
            reward = 200; // Base reward for a successful link
            scoreChange = 25; // Resilience boost
            distributeEssence(link.entity1, reward);
            distributeEssence(link.entity2, reward);
            updateResilienceScore(link.entity1, scoreChange);
            updateResilienceScore(link.entity2, scoreChange);
        } else {
            // Link expired without successful resolution
            scoreChange = -10; // Small penalty
            updateResilienceScore(link.entity1, scoreChange);
            updateResilienceScore(link.entity2, scoreChange);
        }

        link.essenceReward = reward; // Store the actual awarded essence
        link.resolved = true; // Mark as resolved (either successful or expired)
        emit InterdimensionalLinkResolved(_linkId, link.entity1, link.entity2, reward);
    }

    /**
     * @notice Views the details of an active or resolved interdimensional link.
     * @param _linkId The ID of the interdimensional link.
     * @return A tuple containing link details: linkId, entity1, entity2, initiatedAt, expiryAt, resolved, initiator, essenceReward.
     */
    function getLinkDetails(uint256 _linkId) public view returns (
        uint256 linkId,
        uint256 entity1,
        uint256 entity2,
        uint256 initiatedAt,
        uint256 expiryAt,
        bool resolved,
        address initiator,
        uint256 essenceReward
    ) {
        InterdimensionalLink storage link = interdimensionalLinks[_linkId];
        require(link.entity1 != 0, "ChronicleForge: Link does not exist"); // Check if the link exists
        return (
            link.linkId,
            link.entity1,
            link.entity2,
            link.initiatedAt,
            link.expiryAt,
            link.resolved,
            link.initiator,
            link.essenceReward
        );
    }

    // --- IV. Oracle & Temporal Flux Integration ---

    /**
     * @notice Allows a whitelisted oracle to submit external data that can influence AE evolution or system parameters.
     * @dev This function acts as an abstraction for AI model results, real-world events, or other off-chain data.
     *      The `_key` and `_value` can represent anything from "weather_impact" to "market_sentiment".
     *      This example doesn't directly use the data for state changes, but demonstrates the interface.
     * @param _key A bytes32 key representing the type of data (e.g., keccak256("EXTERNAL_EVENT_SCORE")).
     * @param _value The uint256 value of the submitted data.
     */
    function submitOracleData(bytes32 _key, uint256 _value) public onlyOracle whenNotPaused {
        // In a real scenario, this data would trigger specific logic:
        // E.g., if (_key == keccak256("AI_IMPACT_SCORE")) { applyGlobalEffect(_value); }
        // Or trigger specific essence distribution/resilience updates for entities.
        emit OracleDataSubmitted(_key, _value);
    }

    /**
     * @notice A system-level function to process time-sensitive events like global attribute decay or activate Universal Directives.
     * @dev Intended to be called periodically by a decentralized keeper network (e.g., Chainlink Keepers) or a cron job.
     *      It triggers passive Essence distribution and individual decay checks for all existing entities.
     *      NOTE: For very large numbers of entities, this loop could hit gas limits.
     *            A more robust solution for mass updates would involve pagination, Merkle trees, or a system
     *            where updates are "pulled" by users interacting with their entities.
     */
    function triggerTemporalFluxUpdate() public whenNotPaused {
        // Prevent frequent calls to avoid gas abuse and ensure consistent intervals
        require(block.timestamp >= lastTemporalFluxUpdate.add(ESSENCE_DISTRIBUTION_INTERVAL), "ChronicleForge: Temporal Flux update too soon");

        // Iterate through all existing entities to distribute passive essence and check decay
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) { // Ensure the token still exists
                AetherialEntity storage entity = _entities[i];
                uint256 timeSinceLastPassiveEssence = block.timestamp.sub(entity.lastEssenceDistribution);
                uint256 intervalsPassed = timeSinceLastPassiveEssence.div(ESSENCE_DISTRIBUTION_INTERVAL);

                if (intervalsPassed > 0) {
                    uint256 passiveEssence = intervalsPassed.mul(100); // Example: 100 Essence per interval
                    distributeEssence(i, passiveEssence);
                }
                // Also trigger individual decay checks for entities that haven't been touched recently
                decayAttributes(i);
            }
        }

        lastTemporalFluxUpdate = block.timestamp;
        emit TemporalFluxUpdated(block.timestamp);
    }

    /**
     * @notice Admin function to set or update the address of the trusted Oracle Nexus.
     * @param _oracle The new address for the oracle contract or account.
     */
    function setOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "ChronicleForge: Oracle address cannot be zero");
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        // Using a more specific event than OwnershipTransferred for clarity
        emit OracleAddressSet(oldOracle, _oracle);
    }
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);


    /**
     * @notice Returns the timestamp of the last global temporal flux update.
     */
    function getTemporalFluxLastUpdate() public view returns (uint256) {
        return lastTemporalFluxUpdate;
    }

    // --- V. Governance & Universal Directives (DAO-like) ---

    /**
     * @notice Allows entities with sufficient Resilience (or their owners) to propose changes to system parameters,
     *         evolution rules, or global events affecting all AEs.
     * @dev `_proposalData` should be an ABI-encoded call to a function that the DAO can execute (e.g., setting a new parameter).
     * @param _proposalData Arbitrary data representing the directive (e.g., ABI-encoded function call).
     * @return The ID of the newly created proposal.
     */
    function proposeUniversalDirective(bytes memory _proposalData) public whenNotPaused returns (uint256) {
        // Require that the caller owns at least one entity with sufficient resilience to propose
        bool hasHighResilience = false;
        // Iterating up to _tokenIdCounter.current() assumes token IDs are sequential.
        // For sparse IDs, an alternative (e.g., iterating through owner's tokens) would be needed.
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i) && ownerOf(i) == _msgSender() && _entities[i].resilienceScore >= RESILIENCE_SCORE_FOR_PROPOSAL) {
                hasHighResilience = true;
                break;
            }
        }
        require(hasHighResilience, "ChronicleForge: Insufficient Resilience to propose a directive");

        _directiveIdCounter.increment();
        uint256 newProposalId = _directiveIdCounter.current();

        universalDirectives[newProposalId] = UniversalDirective({
            proposalId: newProposalId,
            proposer: _msgSender(),
            creationTime: block.timestamp,
            votingDeadline: block.timestamp.add(DIRECTIVE_VOTING_PERIOD),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            proposalData: _proposalData
        });

        emit UniversalDirectiveProposed(newProposalId, _msgSender(), block.timestamp, universalDirectives[newProposalId].votingDeadline);
        return newProposalId;
    }

    /**
     * @notice Enables eligible participants (e.g., AE holders, high-Resilience AEs) to vote on proposals.
     * @param _proposalId The ID of the Universal Directive proposal.
     * @param _support True for "for" vote, false for "against" vote.
     */
    function voteOnDirective(uint256 _proposalId, bool _support) public whenNotPaused {
        UniversalDirective storage proposal = universalDirectives[_proposalId];
        require(proposal.proposer != address(0), "ChronicleForge: Proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Proposal already executed");
        require(block.timestamp < proposal.votingDeadline, "ChronicleForge: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "ChronicleForge: Already voted on this proposal");

        // Simple voting: 1 address = 1 vote. Could be weighted by AE count or Resilience in a more complex DAO.
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[_msgSender()] = true;

        emit UniversalDirectiveVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @notice Executes a passed Universal Directive, applying its effects to the ChronicleForge.
     * @dev Can be called by anyone after the voting deadline, if the proposal has passed.
     *      This function demonstrates the execution, but a real DAO would involve a more robust
     *      execution mechanism (e.g., a dedicated executor contract with permissioned calls).
     * @param _proposalId The ID of the Universal Directive proposal.
     */
    function executeDirective(uint256 _proposalId) public whenNotPaused {
        UniversalDirective storage proposal = universalDirectives[_proposalId];
        require(proposal.proposer != address(0), "ChronicleForge: Proposal does not exist");
        require(!proposal.executed, "ChronicleForge: Proposal already executed");
        require(block.timestamp >= proposal.votingDeadline, "ChronicleForge: Voting period not ended yet");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Example of how to execute encoded proposalData:
            // This would allow the DAO to call specific functions within this contract, e.g.,
            // to update `essenceCostPerAttributePoint` or other global parameters.
            // (bool success, ) = address(this).call(proposal.proposalData);
            // require(success, "ChronicleForge: Directive execution failed");
            // For this demonstration, we'll just log success.
        } else {
            proposal.passed = false;
        }

        proposal.executed = true;
        emit UniversalDirectiveExecuted(_proposalId, proposal.passed);
    }

    /**
     * @notice Views the currently active global parameters or directives influencing AEs.
     * @dev For simplicity, this returns current state variables. In a more complex system,
     *      some of these might be derived from active directives.
     * @return A tuple of current system parameters.
     */
    function getCurrentDirectiveParameters() public view returns (
        uint256 currentEssenceCostPerAttributePoint,
        uint256 rejuvenationEssenceCost,
        uint256 attributeDecayRatePerDay,
        uint256 essenceDecayRatePerDay,
        uint256 essenceDistributionInterval,
        uint256 resilienceScoreForProposal,
        uint256 directiveVotingPeriod
    ) {
        return (
            essenceCostPerAttributePoint, // This is a mutable state variable
            REJUVENATION_ESSENCE_COST,
            ATTRIBUTE_DECAY_RATE_PER_DAY,
            ESSENCE_DECAY_RATE_PER_DAY,
            ESSENCE_DISTRIBUTION_INTERVAL,
            RESILIENCE_SCORE_FOR_PROPOSAL,
            DIRECTIVE_VOTING_PERIOD
        );
    }

    /**
     * @notice Views the details of a specific Universal Directive proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details: proposalId, proposer, creationTime, votingDeadline, votesFor, votesAgainst, executed, passed.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 proposalId,
        address proposer,
        uint256 creationTime,
        uint256 votingDeadline,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool passed
    ) {
        UniversalDirective storage proposal = universalDirectives[_proposalId];
        require(proposal.proposer != address(0), "ChronicleForge: Proposal does not exist"); // Check if proposal exists
        return (
            proposal.proposalId,
            proposal.proposer,
            proposal.creationTime,
            proposal.votingDeadline,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.passed
        );
    }

    // --- VI. Advanced Concepts & Utility ---

    /**
     * @notice Allows an AE that has reached peak attributes/resilience to "synthesize Aether" (a unique reward/state)
     *         or initiate a transcendent phase, making it potentially non-transferable or unlocking new abilities.
     * @dev For demonstration, requires max attributes (arbitrary high value) and a high resilience score.
     * @param _tokenId The ID of the Aetherial Entity.
     */
    function synthesizeAether(uint256 _tokenId) public onlyEntityOwner(_tokenId) whenNotPaused {
        AetherialEntity storage entity = _entities[_tokenId];
        require(!entity.isTranscendent, "ChronicleForge: Entity is already transcendent");
        
        // Example criteria for transcendence:
        require(entity.strength >= 500 && entity.agility >= 500 && entity.intellect >= 500 && entity.awareness >= 500, "ChronicleForge: Attributes not sufficiently advanced for transcendence");
        require(entity.resilienceScore >= 2000, "ChronicleForge: Insufficient Resilience Score for transcendence");
        
        entity.isTranscendent = true;
        // Here, a real system might:
        // 1. Mint a new "AetherShard" ERC20 token to the owner.
        // 2. Make the AE soulbound (non-transferable) by overriding `_beforeTokenTransfer`.
        // 3. Unlock new, specific functions only callable by transcendent entities.
        
        emit AetherSynthesized(_tokenId);
    }

    /**
     * @notice Allows an AE's owner to burn the entity, potentially recovering some Essence or receiving a final symbolic reward.
     * @param _tokenId The ID of the Aetherial Entity.
     */
    function disintegrateEntity(uint256 _tokenId) public onlyEntityOwner(_tokenId) whenNotPaused {
        AetherialEntity storage entity = _entities[_tokenId];
        uint256 essenceRefund = entity.essenceBalance.div(2); // Example: refund 50% of remaining essence

        // In a real scenario, Essence would likely be an ERC20 token or a redeemable credit.
        // For this contract, we'll emit an event showing the refund amount as it's an internal resource.
        // If ETH was collected as part of Essence, it would be transferred.
        // E.g., if essence was represented by ETH, you'd transfer `payable(_msgSender()).transfer(essenceRefund);`

        _burn(_tokenId); // Burns the ERC721 token and deletes associated data from mappings

        emit EntityDisintegrated(_tokenId, _msgSender(), essenceRefund);
    }

    /**
     * @notice Allows the contract owner to withdraw any collected fees or excess funds.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "ChronicleForge: No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @notice Allows the contract owner to pause/unpause critical functions in an emergency.
     * @dev Uses OpenZeppelin's Pausable functionality.
     */
    function togglePausableState() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice Admin function to adjust the rate at which Essence can be used for actions (e.g., attribute calibration).
     * @dev This parameter can also be controlled by governance (Universal Directives) by encoding a call to this function.
     * @param _newRate The new cost of Essence per attribute point. Must be greater than zero.
     */
    function setEssenceConversionRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0, "ChronicleForge: Conversion rate must be positive");
        essenceCostPerAttributePoint = _newRate; // Update the mutable state variable
        emit EssenceConversionRateSet(_newRate);
    }

    // --- Internal Helpers (Overrides for OpenZeppelin ERC721) ---

    // The `_entityOwnerMap` is maintained manually in `_transfer` and `_burn` overrides
    // to align with the custom data structures. `ERC721.ownerOf()` should be preferred
    // for external owner checks.

    // `_isApprovedOrOwner` is an internal OpenZeppelin function used by `onlyEntityOwner`.
}
```