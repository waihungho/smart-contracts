This smart contract, `ChronicleOfAethel`, is designed to manage a collection of dynamic, evolving digital artifacts called "Aethel Shards" (ERC-721 NFTs) and "Narrative Essences" (ERC-1155 semi-fungible tokens). The core concept revolves around the evolution of Shard properties based on a combination of factors: their owner's on-chain activity, global "cosmic events" powered by Chainlink Oracles, and direct user interactions.

This contract aims to be creative and trendy by offering:
1.  **Dynamic NFTs:** Shard properties are not static; they evolve.
2.  **On-chain Gamification:** Evolution, attunement, harmonization, and resonance provide interactive mechanics.
3.  **Oracle Integration:** Real-world data (simulated via Chainlink for crypto prices) influences the digital realm.
4.  **Metaverse/Lore-driven Design:** The naming and mechanics suggest a rich, evolving narrative.
5.  **Modular Components:** Combining ERC-721 and ERC-1155 for different asset types within a single system.

---

### Outline:

**I. Core Infrastructure & Access Control**
    *   Inherits from OpenZeppelin's `Ownable`, `Pausable`, `ERC721`, `ERC1155`, and Chainlink's `ChainlinkClient`. Provides basic security and token standards.

**II. Aethel Shard Management (Custom ERC-721 for Dynamic NFTs)**
    *   Manages the minting, querying, and underlying dynamic properties of the unique "Aethel Shard" NFTs.
    *   `tokenURI` is designed to point to an off-chain metadata API that can dynamically reflect the Shard's current state.

**III. Narrative Essence Management (Custom ERC-1155 for Semi-Fungible Tokens)**
    *   Manages "Narrative Essences," which are consumable tokens that users can embed into Aethel Shards to modify their properties or unlock new abilities.

**IV. Dynamic Evolution & Interaction (The Core Innovation)**
    *   This section contains the innovative functions that drive the evolution of Shards.
    *   Includes mechanisms for Shards to react to owner's on-chain activity, external events, and direct interactions between Shards or with Essences.

**V. Administrative & Oracle Integration**
    *   Functions for the contract owner to configure Chainlink Oracles, manage whitelisted tokens for activity checks, and perform general administrative tasks.

---

### Function Summary:

**I. Core Infrastructure & Access Control:**
1.  `constructor`: Initializes the contract, setting the owner, Chainlink token, and base URIs for Shards and Essences.
2.  `pause()`: Allows the owner to pause most contract functions in an emergency. *(Inherited from Pausable)*
3.  `unpause()`: Allows the owner to unpause the contract. *(Inherited from Pausable)*
4.  `transferOwnership(address newOwner)`: Transfers ownership of the contract to a new address. *(Inherited from Ownable)*
5.  `renounceOwnership()`: Renounces ownership of the contract, making it unowned. *(Inherited from Ownable)*

**II. Aethel Shard Management (Custom ERC-721):**
6.  `mintGenesisShard(address _to, uint256 _seed)`: Mints a new Aethel Shard to `_to`, generating initial pseudo-random dynamic properties (Power, Resonance, Alignment, Charge, Tier) based on a provided `_seed`. Callable only by owner.
7.  `getShardProperties(uint256 _shardId)`: Retrieves the current dynamic properties (Power, Resonance, Alignment, Tier, Charge, and cooldowns) of a specific Aethel Shard.
8.  `tokenURI(uint256 _shardId)`: Returns the metadata URI for a given Shard. This URI is intended to point to an external service that generates dynamic metadata based on the Shard's current properties. *(Overrides ERC721)*
9.  `safeTransferFrom(address _from, address _to, uint256 _shardId)`: Standard ERC721 function to safely transfer a Shard. *(Inherited from ERC721)*
10. `approve(address _to, uint256 _shardId)`: Standard ERC721 function to grant approval for a single Shard. *(Inherited from ERC721)*
11. `setApprovalForAll(address _operator, bool _approved)`: Standard ERC721 function to grant/revoke operator approval for all Shards. *(Inherited from ERC721)*
12. `ownerOf(uint256 _shardId)`: Standard ERC721 function to query the owner of a Shard. *(Inherited from ERC721)*
13. `balanceOf(address _owner)`: Standard ERC721 function to query the number of Shards owned by an address. *(Inherited from ERC721)*
14. `setShardBaseURI(string memory _newBaseURI)`: Allows the contract owner to update the base URI for all Aethel Shard metadata.

**III. Narrative Essence Management (Custom ERC-1155):**
15. `mintNarrativeEssence(address _to, uint256 _essenceTypeId, uint256 _amount)`: Mints a specified `_amount` of a specific `_essenceTypeId` Narrative Essence to `_to`. Callable only by owner (e.g., for special events).
16. `registerNewEssenceType(string memory _name, string memory _description, uint256 _effectPower, bool _removable)`: Allows the owner to define new types of Narrative Essences and their base properties.
17. `getEssenceDetails(uint256 _essenceTypeId)`: Returns the static details (name, description, effect power, removability) of a specific Essence type.
18. `setEssenceURI(string memory _newURI)`: Allows the contract owner to update the base URI for all Narrative Essence metadata.
19. `uri(uint256 _essenceTypeId)`: Returns the metadata URI for a given Essence type. *(Overrides ERC1155)*
20. `balanceOfBatch(address[] memory _accounts, uint256[] memory _ids)`: Standard ERC1155 function to query balances for multiple accounts and Essence types. *(Inherited from ERC1155)*

**IV. Dynamic Evolution & Interaction:**
21. `attuneShardToEvent(uint256 _shardId, uint256 _eventId)`: Allows the owner of `_shardId` to attune it to a `_eventId` (a previously processed Cosmic Shift). This influences the Shard's properties (e.g., `Alignment`, `Power`) based on the event's nature. Has a cooldown.
22. `updateShardViaOwnerActivity(uint256 _shardId)`: Triggers a property update for `_shardId` based on its owner's recent engagement. This checks if the owner holds a minimum amount of any whitelisted ERC20 tokens. Shards gain a small boost if active, or decay slightly if inactive. Has a cooldown.
23. `embedNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount)`: Allows a Shard owner to burn `_amount` of `_essenceTypeId` Essences to apply their effects to `_shardId`, permanently modifying its properties (e.g., increasing `Power` and `Resonance`).
24. `extractNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount)`: Allows a Shard owner to remove `_amount` of embedded Essences (if the Essence type is `removable`), reverting their effects and minting the Essences back to the owner.
25. `harmonizeShards(uint256 _shardId1, uint256 _shardId2)`: Enables two Shard owners (or one owner with both Shards) to mutually interact their Shards. This function requires operator approval for both NFTs and results in property adjustments (e.g., resonance boost for similar alignments, power average for differing alignments). Has a cooldown.
26. `activateShardResonance(uint256 _shardId)`: Consumes a portion of a Shard's `Charge` to trigger a unique, beneficial effect (e.g., a temporary power boost for the Shard itself).
27. `evolveShardTier(uint256 _shardId)`: Allows a Shard to permanently advance to a higher `Tier` if it meets specific thresholds for `Power` and `Resonance`. Tier evolution grants significant permanent property boosts and can change its metadata.

**V. Administrative & Oracle Integration:**
28. `setAllowedActivityToken(address _tokenAddress, bool _isAllowed)`: Allows the owner to whitelist or blacklist ERC20 tokens used in the `updateShardViaOwnerActivity` function to determine owner engagement.
29. `setChainlinkOracleConfig(address _oracle, bytes32 _jobId, uint256 _fee)`: Sets the Chainlink Oracle address, job ID, and LINK fee required for initiating cosmic shifts.
30. `initiateCosmicShift(uint256 _shiftType)`: Callable by the owner, this function requests data from a configured Chainlink Oracle to trigger a global "cosmic shift" event. `_shiftType` indicates the nature of the event to the oracle adapter.
31. `fulfillCosmicShift(bytes32 _requestId, uint256 _priceInUSD)`: This is the Chainlink callback function that receives the oracle's response (e.g., a crypto price) and processes the cosmic shift, making its data available for Shard attunement.
32. `withdrawFunds()`: Allows the contract owner to withdraw any accumulated ETH from the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // To check ERC20 balances
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol"; // For Oracle integration

// Outline:
// I. Core Infrastructure & Access Control
//    - Inherited: Ownable, Pausable, ERC721, ERC1155, ChainlinkClient
// II. Aethel Shard Management (Custom ERC-721 for Dynamic NFTs)
//    - Represents unique, evolving digital artifacts.
// III. Narrative Essence Management (Custom ERC-1155 for Semi-Fungible Tokens)
//    - Represents consumable data/energy fragments that modify Shards.
// IV. Dynamic Evolution & Interaction (The Core Innovation)
//    - Functions for Shard property evolution based on owner activity, cosmic events, and direct user actions.
// V. Administrative & Oracle Integration
//    - Functions for managing contract parameters and integrating Chainlink Oracles for external data.

// Function Summary:
// I. Core Infrastructure & Access Control:
// 1. constructor: Initializes contract, sets owner, and base URIs.
// 2. pause(): Pauses core contract functions. (Inherited from Pausable)
// 3. unpause(): Unpauses core contract functions. (Inherited from Pausable)
// 4. transferOwnership(address newOwner): Transfers contract ownership. (Inherited from Ownable)
// 5. renounceOwnership(): Renounces contract ownership. (Inherited from Ownable)

// II. Aethel Shard Management (Custom ERC-721):
// 6. mintGenesisShard(address _to, uint256 _seed): Mints a new Aethel Shard with initial pseudo-random properties.
// 7. getShardProperties(uint256 _shardId): Retrieves the current dynamic properties of a specific Shard.
// 8. tokenURI(uint256 _shardId): Returns the metadata URI for a Shard, which can reflect its dynamic state. (Custom logic, overrides ERC721)
// 9. safeTransferFrom(address _from, address _to, uint256 _shardId): Standard ERC721 transfer. (Inherited from ERC721)
// 10. approve(address _to, uint256 _shardId): Standard ERC721 approval. (Inherited from ERC721)
// 11. setApprovalForAll(address _operator, bool _approved): Standard ERC721 operator approval. (Inherited from ERC721)
// 12. ownerOf(uint256 _shardId): Standard ERC721 owner lookup. (Inherited from ERC721)
// 13. balanceOf(address _owner): Standard ERC721 balance lookup. (Inherited from ERC721)
// 14. setShardBaseURI(string memory _newBaseURI): Sets the base URI for all Shard metadata, affecting tokenURI.

// III. Narrative Essence Management (Custom ERC-1155):
// 15. mintNarrativeEssence(address _to, uint256 _essenceTypeId, uint256 _amount): Mints a specific type of Narrative Essence token (admin/event only).
// 16. registerNewEssenceType(string memory _name, string memory _description, uint256 _effectPower, bool _removable): Defines a new type of Narrative Essence.
// 17. getEssenceDetails(uint256 _essenceTypeId): Returns static details (name, description, effect type) of an Essence type.
// 18. setEssenceURI(string memory _newURI): Sets the base URI for all Essence metadata, affecting uri.
// 19. uri(uint256 _essenceTypeId): Returns the metadata URI for an Essence type. (Overrides ERC1155)
// 20. balanceOfBatch(address[] memory _accounts, uint256[] memory _ids): Standard ERC1155 batch balance lookup. (Inherited from ERC1155)

// IV. Dynamic Evolution & Interaction:
// 21. attuneShardToEvent(uint256 _shardId, uint256 _eventId): Owner attunes a Shard to a specific event, influencing its properties based on the event.
// 22. updateShardViaOwnerActivity(uint256 _shardId): Triggers a property update for _shardId based on its owner's recent engagement (holding whitelisted tokens).
// 23. embedNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount): Burns Narrative Essences to apply their effects to a Shard, modifying its properties.
// 24. extractNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount): Removes embedded essences (if removable) and reverts their effects.
// 25. harmonizeShards(uint256 _shardId1, uint256 _shardId2): Allows two Shard owners to mutually influence their Shards, leading to property boosts or alignment changes. Requires operator approval for both.
// 26. activateShardResonance(uint256 _shardId): Consumes a Shard's "Charge" to trigger a unique, beneficial effect (e.g., temporary boost).
// 27. evolveShardTier(uint256 _shardId): Allows a Shard to permanently advance to a higher Tier if it meets specific property/essence thresholds.

// V. Administrative & Oracle Integration:
// 28. setAllowedActivityToken(address _tokenAddress, bool _isAllowed): Whitelists/blacklists ERC20 tokens whose balances contribute to Shard evolution.
// 29. setChainlinkOracleConfig(address _oracle, bytes32 _jobId, uint256 _fee): Sets Chainlink oracle configuration for cosmic shifts.
// 30. initiateCosmicShift(uint256 _shiftType): Admin function to request a Chainlink Oracle for data to trigger a global "cosmic shift" event.
// 31. fulfillCosmicShift(bytes32 _requestId, uint256 _priceInUSD): Chainlink callback function to process oracle data for cosmic shifts.
// 32. withdrawFunds(): Allows the contract owner to withdraw any accumulated ETH.


contract ChronicleOfAethel is ERC721Burnable, ERC1155, Ownable, Pausable, ChainlinkClient {
    using Counters for Counters.Counter;

    // --- Data Structures ---

    // Aethel Shard Properties
    struct ShardProperties {
        uint256 power;       // Base strength, influenced by all factors
        uint224 resonance;   // Ability to interact, attract essences (using uint224 to pack)
        uint8 alignment;     // Elemental/factional affinity (0: Neutral, 1: Solar, 2: Lunar, 3: Void, etc.)
        uint8 tier;          // Evolution level (0-255)
        uint64 charge;       // Temporary energy pool, used for resonance, refills over time (using uint64 for packing)
        uint64 lastChargeUpdateBlock; // Block number when charge was last updated/consumed
        uint64 lastAttunedEventBlock; // Block number when the shard was last attuned to an event
        uint64 lastActivityUpdateBlock; // Block number when owner activity was last checked
        uint64 lastHarmonyBlock; // Block number when the shard last participated in harmony
    }

    // Narrative Essence Details
    struct EssenceDetails {
        string name;
        string description;
        uint256 effectPower; // Generic power of the essence
        bool removable;      // Can this essence be extracted?
    }

    // Cosmic Event Details
    struct CosmicEvent {
        uint256 eventId;
        uint256 shiftType;  // Type of cosmic shift (e.g., 1 for Solar Flare, 2 for Lunar Alignment)
        bytes effectData;   // Raw data from oracle to apply effects
        uint256 timestamp;  // Timestamp when the event was processed
        bool processed;     // True if the event has been successfully fulfilled by Chainlink
    }

    // --- State Variables ---

    Counters.Counter private _shardIds;
    mapping(uint256 => ShardProperties) public aethelShards;
    string private _shardBaseURI;

    // Mapping for embedded essences: shardId => essenceTypeId => amount
    mapping(uint256 => mapping(uint256 => uint256)) public embeddedEssences;
    string private _essenceBaseURI;
    mapping(uint256 => EssenceDetails) public essenceTypes;
    uint256 private _nextEssenceTypeId;

    // Cosmic Shift related
    uint256 private _oracleFee;
    bytes32 private _chainlinkJobId;
    mapping(bytes32 => CosmicEvent) public cosmicEvents; // requestId => CosmicEvent (for pending requests)
    mapping(uint256 => CosmicEvent) public processedCosmicShifts; // eventId => CosmicEvent (for successfully processed events)
    uint256 private _nextEventId;

    // Activity Whitelist
    mapping(address => bool) public isAllowedActivityToken; // ERC20 tokens whose balances contribute to owner activity check
    address[] private whitelistedActivityTokens; // To iterate over whitelisted tokens

    // --- Events ---
    event ShardMinted(uint256 indexed shardId, address indexed owner, uint256 seed);
    event ShardPropertiesUpdated(uint256 indexed shardId, uint256 power, uint256 resonance, uint8 alignment, uint8 tier, uint64 charge);
    event EssenceMinted(uint256 indexed essenceTypeId, address indexed to, uint256 amount);
    event EssenceEmbedded(uint256 indexed shardId, uint256 indexed essenceTypeId, uint256 amount);
    event EssenceExtracted(uint256 indexed shardId, uint256 indexed essenceTypeId, uint256 amount);
    event ShardAttuned(uint256 indexed shardId, uint256 indexed eventId);
    event ShardsHarmonized(uint256 indexed shardId1, uint256 indexed shardId2);
    event ShardResonanceActivated(uint256 indexed shardId, uint64 consumedCharge);
    event ShardEvolved(uint256 indexed shardId, uint8 newTier);
    event CosmicShiftInitiated(bytes32 indexed requestId, uint256 shiftType, address requester);
    event CosmicShiftProcessed(uint256 indexed eventId, uint256 shiftType, bytes effectData);

    // --- Constants & Configuration ---
    uint256 public constant MAX_SHARDS = 10_000;
    uint256 public constant CHARGE_REFILL_RATE_PER_BLOCK = 1; // 1 unit of charge per block
    uint256 public constant MAX_CHARGE = 1_000;
    uint256 public constant MIN_CHARGE_FOR_RESONANCE = 100;
    uint256 public constant ACTIVITY_CHECK_TOKEN_THRESHOLD = 1e18; // Example: 1 token (assuming 18 decimals) for activity
    uint256 public constant ACTIVITY_COOLDOWN_BLOCKS = 100; // Blocks between activity updates
    uint256 public constant ATTUNEMENT_COOLDOWN_BLOCKS = 50; // Blocks between attunements
    uint256 public constant HARMONY_COOLDOWN_BLOCKS = 200; // Blocks between harmony actions

    constructor(address _link, string memory _initialShardBaseURI, string memory _initialEssenceBaseURI)
        ERC721("ChronicleOfAethel Shard", "AETHEL")
        ERC1155(_initialEssenceBaseURI)
        Ownable(msg.sender)
        Pausable()
        ChainlinkClient()
    {
        setChainlinkToken(_link);
        _shardBaseURI = _initialShardBaseURI;
        _essenceBaseURI = _initialEssenceBaseURI;
        _nextEssenceTypeId = 1; // Start Essence IDs from 1
        _nextEventId = 1; // Start Event IDs from 1
    }

    // --- I. Core Infrastructure & Access Control (Inherited/Standard) ---
    // (pause, unpause, transferOwnership, renounceOwnership are inherited from Pausable and Ownable)

    // --- II. Aethel Shard Management (Custom ERC-721) ---

    function mintGenesisShard(address _to, uint256 _seed) external onlyOwner returns (uint256) {
        require(_shardIds.current() < MAX_SHARDS, "Max shards reached");
        _shardIds.increment();
        uint256 newTokenId = _shardIds.current();

        _safeMint(_to, newTokenId);

        // Pseudo-random initial properties based on seed, block data, and sender
        // Note: For truly secure randomness, Chainlink VRF or similar is required.
        // This is sufficient for initial property generation not tied to high-stakes gambling.
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _seed, newTokenId)));

        aethelShards[newTokenId] = ShardProperties({
            power: (rand % 100) + 100,      // Base power 100-199
            resonance: uint224((rand >> 8) % 50 + 50), // Base resonance 50-99
            alignment: uint8((rand >> 16) % 3 + 1), // 1: Solar, 2: Lunar, 3: Void
            tier: 1,
            charge: MAX_CHARGE / 2, // Start with half charge
            lastChargeUpdateBlock: uint64(block.number),
            lastAttunedEventBlock: uint64(block.number),
            lastActivityUpdateBlock: uint64(block.number),
            lastHarmonyBlock: uint64(block.number)
        });

        emit ShardMinted(newTokenId, _to, _seed);
        _emitShardPropertiesUpdate(newTokenId); // Emit current properties
        return newTokenId;
    }

    function getShardProperties(uint256 _shardId) public view returns (ShardProperties memory) {
        return aethelShards[_shardId];
    }

    function _baseURI() internal view override(ERC721, ERC1155) returns (string memory) {
        // ERC1155 uri requires this if not passed in constructor.
        // For dynamic tokenURI, this is overridden below by tokenURI and uri for each.
        // This _baseURI should ideally be for common metadata, or left empty if
        // tokenURI/uri methods handle all specific metadata paths.
        return ""; 
    }

    function tokenURI(uint256 _shardId) public view override(ERC721) returns (string memory) {
        require(_exists(_shardId), "ERC721: URI query for nonexistent token");
        // The actual metadata API would use _shardBaseURI + _shardId.
        // It should fetch the dynamic properties from this contract and compose the JSON.
        // For demonstration, we just return the base URI + ID + ".json"
        return string(abi.encodePacked(_shardBaseURI, Strings.toString(_shardId), ".json"));
    }

    function setShardBaseURI(string memory _newBaseURI) external onlyOwner {
        _shardBaseURI = _newBaseURI;
    }

    // --- III. Narrative Essence Management (Custom ERC-1155) ---

    function mintNarrativeEssence(address _to, uint256 _essenceTypeId, uint256 _amount) external onlyOwner whenNotPaused {
        require(essenceTypes[_essenceTypeId].effectPower > 0, "Essence type not defined or invalid"); // Check if essence type exists
        _mint(_to, _essenceTypeId, _amount, "");
        emit EssenceMinted(_essenceTypeId, _to, _amount);
    }

    function registerNewEssenceType(string memory _name, string memory _description, uint256 _effectPower, bool _removable) external onlyOwner returns (uint256) {
        _nextEssenceTypeId++;
        essenceTypes[_nextEssenceTypeId] = EssenceDetails({
            name: _name,
            description: _description,
            effectPower: _effectPower,
            removable: _removable
        });
        return _nextEssenceTypeId;
    }

    function getEssenceDetails(uint256 _essenceTypeId) public view returns (EssenceDetails memory) {
        return essenceTypes[_essenceTypeId];
    }

    function setEssenceURI(string memory _newURI) external onlyOwner {
        _essenceBaseURI = _newURI;
        // ERC1155's uri(uint256) function uses the _uri variable set in the constructor.
        // To update it dynamically, we might need a custom setter or just ensure
        // our external metadata service understands this. For this example, we assume
        // the off-chain system updates its paths based on this.
    }

    function uri(uint256 _essenceTypeId) public view override(ERC1155) returns (string memory) {
        // The actual metadata API would use _essenceBaseURI + _essenceTypeId.
        // For demonstration, we just return the base URI + ID + ".json"
        return string(abi.encodePacked(_essenceBaseURI, Strings.toString(_essenceTypeId), ".json"));
    }

    // --- IV. Dynamic Evolution & Interaction ---

    // Internal helper to update Shard's charge based on blocks passed
    function _updateShardCharge(uint256 _shardId) internal {
        ShardProperties storage shard = aethelShards[_shardId];
        uint64 blocksPassed = uint64(block.number) > shard.lastChargeUpdateBlock ? uint64(block.number) - shard.lastChargeUpdateBlock : 0;
        uint64 newCharge = shard.charge + (blocksPassed * CHARGE_REFILL_RATE_PER_BLOCK);
        shard.charge = newCharge > MAX_CHARGE ? MAX_CHARGE : newCharge;
        shard.lastChargeUpdateBlock = uint64(block.number);
    }

    // Internal helper to emit ShardPropertiesUpdated event
    function _emitShardPropertiesUpdate(uint256 _shardId) internal {
        ShardProperties storage shard = aethelShards[_shardId];
        emit ShardPropertiesUpdated(_shardId, shard.power, shard.resonance, shard.alignment, shard.tier, shard.charge);
    }

    function attuneShardToEvent(uint256 _shardId, uint256 _eventId) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        _updateShardCharge(_shardId); // Update charge before any action
        require(block.number - aethelShards[_shardId].lastAttunedEventBlock >= ATTUNEMENT_COOLDOWN_BLOCKS, "ChronicleOfAethel: Shard on attunement cooldown");
        require(processedCosmicShifts[_eventId].processed, "ChronicleOfAethel: Event not yet processed or invalid");

        ShardProperties storage shard = aethelShards[_shardId];
        CosmicEvent storage eventData = processedCosmicShifts[_eventId];
        uint256 priceEffect = abi.decode(eventData.effectData, (uint256)); // Assuming effectData contains a uint256

        // Example: Attuning to a specific event type might shift alignment and boost properties
        if (eventData.shiftType == 1) { // Example: "Solar Flare" type event
            shard.alignment = 1; // Shift to Solar
            shard.power = shard.power + 10 + (priceEffect / 100_000); // Boost based on event and oracle data
        } else if (eventData.shiftType == 2) { // Example: "Lunar Alignment" type event
            shard.alignment = 2; // Shift to Lunar
            shard.resonance = shard.resonance + 5 + uint224(priceEffect / 200_000);
        } else { // Neutral/Other event
            shard.power = shard.power + (priceEffect / 500_000); // Minor general boost
        }

        shard.lastAttunedEventBlock = uint64(block.number);
        emit ShardAttuned(_shardId, _eventId);
        _emitShardPropertiesUpdate(_shardId);
    }

    function updateShardViaOwnerActivity(uint256 _shardId) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        _updateShardCharge(_shardId); // Update charge before any action
        require(block.number - aethelShards[_shardId].lastActivityUpdateBlock >= ACTIVITY_COOLDOWN_BLOCKS, "ChronicleOfAethel: Shard activity update on cooldown");

        ShardProperties storage shard = aethelShards[_shardId];
        address currentOwner = msg.sender;
        bool engaged = false;

        // Check for engagement based on whitelisted ERC20 tokens
        for (uint i = 0; i < whitelistedActivityTokens.length; i++) {
            address tokenAddress = whitelistedActivityTokens[i];
            if (isAllowedActivityToken[tokenAddress]) {
                if (IERC20(tokenAddress).balanceOf(currentOwner) >= ACTIVITY_CHECK_TOKEN_THRESHOLD) {
                    engaged = true;
                    break;
                }
            }
        }
        
        if (engaged) {
            shard.power += 2; // Small boost for being active
            shard.resonance += 1;
        } else {
            if (shard.power > 1) shard.power -= 1; // Small decay if not active
        }

        shard.lastActivityUpdateBlock = uint64(block.number);
        _emitShardPropertiesUpdate(_shardId);
    }
    
    function setAllowedActivityToken(address _tokenAddress, bool _isAllowed) external onlyOwner {
        if (_isAllowed) {
            require(!isAllowedActivityToken[_tokenAddress], "ChronicleOfAethel: Token already whitelisted");
            isAllowedActivityToken[_tokenAddress] = true;
            whitelistedActivityTokens.push(_tokenAddress);
        } else {
            require(isAllowedActivityToken[_tokenAddress], "ChronicleOfAethel: Token not whitelisted");
            isAllowedActivityToken[_tokenAddress] = false;
            // Remove from array (inefficient for large arrays but simple for few)
            for (uint i = 0; i < whitelistedActivityTokens.length; i++) {
                if (whitelistedActivityTokens[i] == _tokenAddress) {
                    whitelistedActivityTokens[i] = whitelistedActivityTokens[whitelistedActivityTokens.length - 1];
                    whitelistedActivityTokens.pop();
                    break;
                }
            }
        }
    }

    function embedNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        require(balanceOf(msg.sender, _essenceTypeId) >= _amount, "ChronicleOfAethel: Insufficient essence balance");
        require(essenceTypes[_essenceTypeId].effectPower > 0, "ChronicleOfAethel: Essence type not defined or invalid");
        _updateShardCharge(_shardId); // Update charge before any action

        _burn(msg.sender, _essenceTypeId, _amount);
        embeddedEssences[_shardId][_essenceTypeId] += _amount;

        ShardProperties storage shard = aethelShards[_shardId];
        uint256 totalEffectPower = essenceTypes[_essenceTypeId].effectPower * _amount;

        // Apply essence effect (example logic)
        shard.power += (totalEffectPower / 10);
        shard.resonance += uint224(totalEffectPower / 20);

        emit EssenceEmbedded(_shardId, _essenceTypeId, _amount);
        _emitShardPropertiesUpdate(_shardId);
    }

    function extractNarrativeEssence(uint256 _shardId, uint256 _essenceTypeId, uint256 _amount) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        require(essenceTypes[_essenceTypeId].removable, "ChronicleOfAethel: Essence type is not removable");
        require(embeddedEssences[_shardId][_essenceTypeId] >= _amount, "ChronicleOfAethel: Not enough embedded essences");
        _updateShardCharge(_shardId); // Update charge before any action

        embeddedEssences[_shardId][_essenceTypeId] -= _amount;
        _mint(msg.sender, _essenceTypeId, _amount, "");

        ShardProperties storage shard = aethelShards[_shardId];
        uint256 totalEffectPower = essenceTypes[_essenceTypeId].effectPower * _amount;

        // Revert essence effect (example logic)
        if (shard.power > (totalEffectPower / 10)) shard.power -= (totalEffectPower / 10);
        if (shard.resonance > uint224(totalEffectPower / 20)) shard.resonance -= uint224(totalEffectPower / 20);

        emit EssenceExtracted(_shardId, _essenceTypeId, _amount);
        _emitShardPropertiesUpdate(_shardId);
    }

    function harmonizeShards(uint256 _shardId1, uint256 _shardId2) external whenNotPaused {
        require(_shardId1 != _shardId2, "ChronicleOfAethel: Cannot harmonize a shard with itself");
        address owner1 = ownerOf(_shardId1);
        address owner2 = ownerOf(_shardId2);
        require(owner1 == msg.sender || owner2 == msg.sender, "ChronicleOfAethel: Must be owner of at least one shard");

        // Requires operator approval or direct ownership for both shards
        require(
            (owner1 == msg.sender && isApprovedForAll(owner2, msg.sender)) ||
            (owner2 == msg.sender && isApprovedForAll(owner1, msg.sender)) ||
            (owner1 == msg.sender && owner2 == msg.sender)
            , "ChronicleOfAethel: Requires both owners' approval or one owner of both shards"
        );
        
        _updateShardCharge(_shardId1);
        _updateShardCharge(_shardId2);

        ShardProperties storage shard1 = aethelShards[_shardId1];
        ShardProperties storage shard2 = aethelShards[_shardId2];

        require(block.number - shard1.lastHarmonyBlock >= HARMONY_COOLDOWN_BLOCKS, "ChronicleOfAethel: Shard1 on harmony cooldown");
        require(block.number - shard2.lastHarmonyBlock >= HARMONY_COOLDOWN_BLOCKS, "ChronicleOfAethel: Shard2 on harmony cooldown");

        // Example Harmony Logic:
        // If alignments are similar, boost resonance. If different, average power and shift alignments.
        if (shard1.alignment == shard2.alignment) {
            uint256 resonanceBoost = 5;
            shard1.resonance += uint224(resonanceBoost);
            shard2.resonance += uint224(resonanceBoost);
        } else {
            uint256 avgPower = (shard1.power + shard2.power) / 2;
            shard1.power = avgPower;
            shard2.power = avgPower;
            // Shift alignments slightly towards each other or neutral (e.g., average, or specific rules)
            uint8 newAlignment = uint8((shard1.alignment + shard2.alignment) / 2);
            if (newAlignment == 0) newAlignment = 1; // Prevent neutral 0 if we want specific alignments
            shard1.alignment = newAlignment;
            shard2.alignment = newAlignment; 
        }
        
        shard1.lastHarmonyBlock = uint64(block.number); // Reset cooldown
        shard2.lastHarmonyBlock = uint64(block.number); // Reset cooldown

        emit ShardsHarmonized(_shardId1, _shardId2);
        _emitShardPropertiesUpdate(_shardId1);
        _emitShardPropertiesUpdate(_shardId2);
    }

    function activateShardResonance(uint256 _shardId) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        _updateShardCharge(_shardId);

        ShardProperties storage shard = aethelShards[_shardId];
        require(shard.charge >= MIN_CHARGE_FOR_RESONANCE, "ChronicleOfAethel: Insufficient charge to activate resonance");
        
        uint64 consumedCharge = MIN_CHARGE_FOR_RESONANCE;
        shard.charge -= consumedCharge;

        // Example effect: temporary power boost
        shard.power += 5; 
        // In a more complex system, this might mint a small ERC20 "Lore Dust" token
        // or trigger a temporary global effect visible to all shards.
        
        emit ShardResonanceActivated(_shardId, consumedCharge);
        _emitShardPropertiesUpdate(_shardId);
    }

    function evolveShardTier(uint256 _shardId) external whenNotPaused {
        require(ownerOf(_shardId) == msg.sender, "ChronicleOfAethel: Not shard owner");
        _updateShardCharge(_shardId);

        ShardProperties storage shard = aethelShards[_shardId];
        require(shard.tier < 5, "ChronicleOfAethel: Shard already at max tier (5)"); // Example max tier
        require(shard.power >= uint256(shard.tier) * 200, "ChronicleOfAethel: Insufficient power for evolution"); // Example condition
        require(shard.resonance >= uint256(shard.tier) * 100, "ChronicleOfAethel: Insufficient resonance for evolution"); // Example condition
        // Could also require specific embedded essences: require(embeddedEssences[_shardId][SOME_ESSENCE_ID] >= 1, "Missing evolution essence");

        shard.tier += 1;
        shard.power += 50; // Permanent base boost
        shard.resonance += 25;

        emit ShardEvolved(_shardId, shard.tier);
        _emitShardPropertiesUpdate(_shardId);
    }

    // --- V. Administrative & Oracle Integration ---

    function setChainlinkOracleConfig(address _oracle, bytes32 _jobId, uint256 _fee) external onlyOwner {
        setChainlinkOracle(_oracle);
        _chainlinkJobId = _jobId;
        _oracleFee = _fee;
    }

    function initiateCosmicShift(uint256 _shiftType) external onlyOwner returns (bytes32 requestId) {
        require(address(getChainlinkOracle()) != address(0) && _chainlinkJobId != bytes32(0), "ChronicleOfAethel: Chainlink oracle not configured");
        require(IERC20(chainlinkToken()).balanceOf(address(this)) >= _oracleFee, "ChronicleOfAethel: Insufficient LINK balance for oracle request");
        
        Chainlink.Request memory req = buildChainlinkRequest(_chainlinkJobId, address(this), this.fulfillCosmicShift.selector);
        
        // Example Oracle Request: Get ETH price in USD
        req.add("get", "https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD");
        req.add("path", "USD"); // Path to the desired data point in the JSON response
        req.addInt("multiply", 100); // Scale it for integer processing (e.g., $2000 becomes 200000)
        req.addUint("shiftType", _shiftType); // Pass shiftType to the external adapter (if needed)

        requestId = sendChainlinkRequest(req, _oracleFee);
        cosmicEvents[requestId] = CosmicEvent({
            eventId: 0, // Will be set in fulfill
            shiftType: _shiftType,
            effectData: "", // Will be set in fulfill
            timestamp: block.timestamp,
            processed: false
        });
        emit CosmicShiftInitiated(requestId, _shiftType, msg.sender);
    }

    function fulfillCosmicShift(bytes32 _requestId, uint256 _priceInUSD) public recordChainlinkFulfillment(_requestId) {
        // Assume _priceInUSD is the result from our Chainlink adapter.
        // In a real scenario, the Chainlink job returns `bytes`, which you'd decode.
        // For this example, we directly passed `_priceInUSD` from the adapter as a uint256.
        
        bytes memory _effectData = abi.encode(_priceInUSD); // Store the raw data for future attunement

        require(!cosmicEvents[_requestId].processed, "ChronicleOfAethel: Cosmic event already processed");
        _nextEventId++;
        uint256 currentEventId = _nextEventId;

        cosmicEvents[_requestId].eventId = currentEventId;
        cosmicEvents[_requestId].effectData = _effectData;
        cosmicEvents[_requestId].processed = true;
        processedCosmicShifts[currentEventId] = cosmicEvents[_requestId];

        // This is where global effects could be applied directly.
        // However, updating all shards directly is gas-prohibitive.
        // Instead, the `attuneShardToEvent` function allows shards to react to this processed event.
        // A truly "global" effect would likely involve setting a global parameter that all shards
        // implicitly benefit from when their properties are queried or updated.
        // For now, we rely on individual shards attuning to the event.

        emit CosmicShiftProcessed(currentEventId, cosmicEvents[_requestId].shiftType, _effectData);
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
```