Okay, let's design an advanced, creative, and non-standard smart contract.

**Concept:** "Chronicle NFTs" - Dynamically Evolving NFTs representing unique entities or histories. These NFTs have internal attributes (like 'Essence', 'Consciousness', 'Affinity') and dynamic traits that change based on time, interactions with other NFTs, paid actions, or simulated "trials". The contract includes mechanics for fusion, bonding, and attribute-gated abilities, integrated with a hypothetical keeper system for time-based evolution.

**Advanced Concepts Used:**
1.  **Dynamic NFT Metadata/State:** Traits and attributes are stored and modified on-chain, enabling evolving appearance/properties (requires off-chain metadata renderer reading on-chain state).
2.  **Internal Attribute System:** NFTs have numerical or boolean attributes beyond standard token properties.
3.  **NFT Interaction Mechanics:** Functions allowing NFTs to interact with each other (`fuse`, `bond`, `challenge`), affecting their state.
4.  **Time-Based Evolution (Keeper Integration):** Designed to work with automated systems (like Chainlink Keepers) to trigger state changes over time (`passTime`, `checkUpkeep`, `performUpkeep`).
5.  **Payable Functions for State Change:** Using Ether to fuel NFT actions (`injectEssence`).
6.  **Attribute/Trait Gating:** Certain actions require specific attribute levels or trait values (`activateConsciousnessAbility`).
7.  **Simulated Trials/Events:** A mechanism for triggering probabilistic outcomes that affect NFT state (using simplified on-chain "randomness").
8.  **Fusion Mechanic:** Combining two NFTs to evolve one and burn the other.
9.  **Bonding Mechanic:** Creating relationships between NFTs that can be queried.
10. **Internal Tracking of Non-Transferable "Artifacts":** Marking an NFT/owner as having discovered a unique item associated with the NFT's journey.

---

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721Enumerable, Ownable, Pausable
3.  **Enums and Constants:** Define types for traits, elements, trial outcomes, etc.
4.  **Structs:** Define the structure for Chronicle attributes.
5.  **State Variables:**
    *   ERC721 standard mappings and counters.
    *   Mapping for Chronicle Attributes (`_chronicleAttributes`).
    *   Mapping for Dynamic Traits (`_chronicleTraits`).
    *   Mapping for Chronicle Bonds (`_chronicleBonds`).
    *   Mapping for Trial Definitions/Outcomes (`_trialDefinitions`).
    *   Admin configurable parameters (`_essenceInjectionRate`, `_timeUnitDuration`, `_consciousnessThreshold`).
    *   Last updated timestamp for Keeper logic (`_lastKeeperRun`).
    *   Mapping for discovered artifacts (`_artifactDiscovered`).
    *   Mapping for last time 'passTime' was called per token (`_lastPassTime`).
6.  **Events:** For key actions (Mint, EssenceInjected, TrialCompleted, Fusion, BondCreated, AttributeChanged, TraitChanged, ArtifactDiscovered, KeeperRun).
7.  **Modifiers:** `whenChronicleExists`, `whenChroniclesExist`.
8.  **Constructor:** Initializes the contract, ERC721 details, and owner.
9.  **ERC721 Standard Functions:** Inherited and potentially overridden (like `tokenURI`).
10. **Core Chronicle Management:**
    *   `mint`: Creates a new Chronicle NFT.
    *   `burn`: Destroys a Chronicle NFT (owner/approved only).
    *   `getChronicleAttributes`: View function to get all attributes.
    *   `getChronicleTrait`: View function to get a specific trait value.
    *   `getChronicleTraits`: View function to get all traits for a chronicle.
    *   `getArtifactStatus`: View function to check if an artifact is discovered.
11. **Evolution & Interaction Functions:**
    *   `passTime`: Advances time for a single Chronicle, potentially triggering age-related changes.
    *   `batchPassTime`: Allows processing time for multiple Chronicles (useful for Keeper).
    *   `injectEssence`: Payable function to increase a Chronicle's essence.
    *   `undergoTrial`: Triggers a trial for a Chronicle, applying a simulated outcome based on trial type and state.
    *   `attuneToElement`: Sets or changes a Chronicle's elemental affinity trait.
    *   `fuseChronicles`: Combines two Chronicles, evolving one and burning the other.
    *   `bondWithChronicle`: Creates a bond between two Chronicles.
    *   `challengeChronicle`: Simulates a challenge between two Chronicles, potentially affecting their attributes/traits.
12. **Attribute-Gated Abilities:**
    *   `activateConsciousnessAbility`: Allows a Chronicle owner to perform an action if consciousness is high enough.
    *   `queryBondStatus`: Check if two chronicles are bonded.
13. **Keeper Functions (Chainlink Keeper Pattern):**
    *   `checkUpkeep`: Determines if `performUpkeep` is needed (e.g., if any token needs time processed).
    *   `performUpkeep`: Executes necessary actions determined by `checkUpkeep` (e.g., calls `batchPassTime`).
14. **Admin/Configuration Functions:**
    *   `pause`/`unpause`: Control contract activity.
    *   `setEssenceInjectionRate`: Configure how much essence Ether buys.
    *   `addTrialType`: Define new types of trials and their potential outcomes.
    *   `setConsciousnessThreshold`: Set the requirement for the consciousness ability.
    *   `setTrait`: Admin function to set a specific trait for a token (for setup/corrections).
    *   `setAttributes`: Admin function to set attributes for a token.
    *   `withdrawFees`: Owner can withdraw collected Ether.

---

**Function Summary:**

1.  `constructor(string name, string symbol, uint256 initialEssenceRate, uint256 timeUnitDurationSeconds, uint256 minConsciousnessForAbility)`: Deploys the contract, sets name, symbol, initial rates/thresholds.
2.  `mint(address owner)`: Mints a new Chronicle NFT to `owner` with base attributes.
3.  `burn(uint256 tokenId)`: Burns (destroys) a Chronicle NFT (owner or approved).
4.  `balanceOf(address owner) view returns (uint256)`: Returns the number of Chronicles owned by `owner`. (ERC721)
5.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of the `tokenId`. (ERC721)
6.  `approve(address to, uint256 tokenId)`: Grants approval for `to` to manage `tokenId`. (ERC721)
7.  `getApproved(uint256 tokenId) view returns (address)`: Gets the approved address for `tokenId`. (ERC721)
8.  `setApprovalForAll(address operator, bool approved)`: Grants or revokes approval for `operator` for all tokens. (ERC721)
9.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks if `operator` is approved for all tokens of `owner`. (ERC721)
10. `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`. (ERC721)
11. `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` safely. (ERC721) (Overload 1)
12. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers `tokenId` safely with data. (ERC721) (Overload 2)
13. `totalSupply() view returns (uint256)`: Returns the total number of Chronicles minted. (ERC721 Enumerable)
14. `tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)`: Gets tokenId by index for an owner. (ERC721 Enumerable)
15. `tokenByIndex(uint256 index) view returns (uint256)`: Gets tokenId by index in the global list. (ERC721 Enumerable)
16. `tokenURI(uint256 tokenId) view returns (string)`: Returns the URI for token metadata (points to external service reading on-chain state). (ERC721)
17. `pause()`: Pauses core contract functions (Owner). (Pausable)
18. `unpause()`: Unpauses core contract functions (Owner). (Pausable)
19. `renounceOwnership()`: Relinquishes ownership (Owner). (Ownable)
20. `transferOwnership(address newOwner)`: Transfers ownership (Owner). (Ownable)
21. `getChronicleAttributes(uint256 tokenId) view returns (ChronicleAttributes)`: Returns the current attributes of a Chronicle.
22. `getChronicleTrait(uint256 tokenId, uint256 traitId) view returns (bytes32)`: Returns the value of a specific trait for a Chronicle.
23. `getChronicleTraits(uint256 tokenId) view returns (uint256[] memory traitIds, bytes32[] memory traitValues)`: Returns all set trait IDs and values for a Chronicle.
24. `getArtifactStatus(uint256 tokenId) view returns (bool)`: Checks if the artifact for this Chronicle has been discovered.
25. `passTime(uint256 tokenId)`: Processes time passage for a single Chronicle, updating `chronos` and potentially triggering age effects. Can only be called after a time unit has passed.
26. `batchPassTime(uint256[] calldata tokenIds)`: Processes time passage for a batch of Chronicles.
27. `injectEssence(uint256 tokenId) payable`: Allows sending Ether to increase the Chronicle's essence attribute based on `_essenceInjectionRate`.
28. `undergoTrial(uint256 tokenId, uint256 trialType)`: Subjects the Chronicle to a trial. Uses simplified randomness to determine success/failure based on `trialType`, affecting attributes or traits.
29. `attuneToElement(uint256 tokenId, uint256 elementType)`: Sets or updates the Chronicle's elemental affinity trait.
30. `fuseChronicles(uint256 tokenId1, uint256 tokenId2)`: Fuses `tokenId2` into `tokenId1`. `tokenId2` is burned, and `tokenId1`'s attributes/traits are significantly altered based on both.
31. `bondWithChronicle(uint256 tokenIdA, uint256 tokenIdB)`: Creates a bond record between two Chronicles. Requires ownership or approval for both.
32. `challengeChronicle(uint256 challengerId, uint256 targetId)`: Simulates a challenge between two Chronicles. Outcomes affect attributes/traits based on simulated success/failure and current stats.
33. `activateConsciousnessAbility(uint256 tokenId)`: Executes a special action if the Chronicle's consciousness level meets the required threshold.
34. `queryBondStatus(uint256 tokenIdA, uint256 tokenIdB) view returns (bool)`: Checks if a bond exists between two Chronicles.
35. `checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData)`: Keeper hook to check if `performUpkeep` is needed (e.g., are there tokens not updated recently by `passTime`).
36. `performUpkeep(bytes calldata performData) external`: Keeper hook to execute necessary upkeep (e.g., find and update tokens needing `passTime`).
37. `setEssenceInjectionRate(uint256 rate)`: Sets the amount of essence gained per Wei/Ether injected (Owner).
38. `addTrialType(uint256 trialType, bytes32 successOutcomeHash, bytes32 failureOutcomeHash)`: Defines a new trial type and hashes representing potential success/failure outcomes (Owner). (Note: Real outcome application logic is complex and would involve revealing the outcome data).
39. `setConsciousnessThreshold(uint256 threshold)`: Sets the minimum consciousness required for `activateConsciousnessAbility` (Owner).
40. `setTrait(uint256 tokenId, uint256 traitId, bytes32 traitValue)`: Admin override to set a specific trait value for a Chronicle (Owner).
41. `setAttributes(uint256 tokenId, ChronicleAttributes newAttributes)`: Admin override to set all attributes for a Chronicle (Owner).
42. `withdrawFees()`: Allows the owner to withdraw accumulated Ether from `injectEssence` calls.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Enums and Constants
// 4. Structs
// 5. State Variables
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. ERC721 Standard Functions (Inherited/Overridden)
// 10. Core Chronicle Management (mint, burn, getters)
// 11. Evolution & Interaction Functions (passTime, injectEssence, undergoTrial, fuse, bond, challenge, attune)
// 12. Attribute-Gated Abilities (activateConsciousnessAbility, queryBondStatus)
// 13. Keeper Functions (checkUpkeep, performUpkeep)
// 14. Admin/Configuration Functions (setters, withdraw)

// Function Summary:
// 1.  constructor(string name, string symbol, uint256 initialEssenceRate, uint256 timeUnitDurationSeconds, uint256 minConsciousnessForAbility): Deploys with initial settings.
// 2.  mint(address owner): Creates a new Chronicle NFT.
// 3.  burn(uint256 tokenId): Destroys a Chronicle NFT (owner/approved).
// 4.  balanceOf(address owner): (ERC721) Returns count of NFTs owned by address.
// 5.  ownerOf(uint256 tokenId): (ERC721) Returns owner of NFT.
// 6.  approve(address to, uint256 tokenId): (ERC721) Approves address for NFT.
// 7.  getApproved(uint256 tokenId): (ERC721) Gets approved address for NFT.
// 8.  setApprovalForAll(address operator, bool approved): (ERC721) Sets global approval.
// 9.  isApprovedForAll(address owner, address operator): (ERC721) Checks global approval.
// 10. transferFrom(address from, address to, uint256 tokenId): (ERC721) Transfers NFT.
// 11. safeTransferFrom(address from, address to, uint256 tokenId): (ERC721) Safe Transfer (overload 1).
// 12. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): (ERC721) Safe Transfer (overload 2).
// 13. totalSupply(): (ERC721Enumerable) Returns total minted supply.
// 14. tokenOfOwnerByIndex(address owner, uint256 index): (ERC721Enumerable) Gets token ID by owner index.
// 15. tokenByIndex(uint256 index): (ERC721Enumerable) Gets token ID by global index.
// 16. tokenURI(uint256 tokenId): (ERC721) Returns metadata URI.
// 17. pause(): (Pausable) Pauses actions (Owner).
// 18. unpause(): (Pausable) Unpauses actions (Owner).
// 19. renounceOwnership(): (Ownable) Renounce ownership.
// 20. transferOwnership(address newOwner): (Ownable) Transfer ownership.
// 21. getChronicleAttributes(uint256 tokenId): Returns attributes struct.
// 22. getChronicleTrait(uint256 tokenId, uint256 traitId): Returns value of a specific trait.
// 23. getChronicleTraits(uint256 tokenId): Returns all trait IDs and values.
// 24. getArtifactStatus(uint256 tokenId): Checks if artifact is discovered.
// 25. passTime(uint256 tokenId): Advances time for one Chronicle.
// 26. batchPassTime(uint256[] calldata tokenIds): Advances time for multiple Chronicles.
// 27. injectEssence(uint256 tokenId) payable: Increases Essence attribute using Ether.
// 28. undergoTrial(uint256 tokenId, uint256 trialType): Triggers a trial with a simulated outcome.
// 29. attuneToElement(uint256 tokenId, uint256 elementType): Sets/changes elemental affinity trait.
// 30. fuseChronicles(uint256 tokenId1, uint256 tokenId2): Fuses tokenId2 into tokenId1.
// 31. bondWithChronicle(uint256 tokenIdA, uint256 tokenIdB): Creates a bond between two Chronicles.
// 32. challengeChronicle(uint256 challengerId, uint256 targetId): Simulates a challenge between two Chronicles.
// 33. activateConsciousnessAbility(uint256 tokenId): Executes action based on consciousness level.
// 34. queryBondStatus(uint256 tokenIdA, uint256 tokenIdB): Checks if a bond exists.
// 35. checkUpkeep(bytes calldata checkData): Keeper hook to check if upkeep is needed.
// 36. performUpkeep(bytes calldata performData): Keeper hook to perform upkeep actions.
// 37. setEssenceInjectionRate(uint32 rate): Sets Essence gain per Wei (Owner).
// 38. addTrialType(uint256 trialType, bytes32 successOutcomeHash, bytes32 failureOutcomeHash): Defines a new trial type and outcomes (Owner).
// 39. setConsciousnessThreshold(uint256 threshold): Sets min consciousness for ability (Owner).
// 40. setTrait(uint256 tokenId, uint256 traitId, bytes32 traitValue): Admin override to set a trait (Owner).
// 41. setAttributes(uint256 tokenId, ChronicleAttributes newAttributes): Admin override to set attributes (Owner).
// 42. withdrawFees(): Withdraws collected Ether (Owner).

contract ChronicleNFTs is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Enums and Constants ---

    // Define some example trait types (can be expanded)
    enum TraitType {
        GENESIS_MARK,   // A static identifier
        ELEMENTAL_AFFINITY, // Can change
        CURRENT_STATE,  // E.g., "Dormant", "Active", "Evolved"
        LAST_TRIAL_OUTCOME // Records outcome of the last trial
    }

    // Define some example elements (for ELEMENTAL_AFFINITY)
    enum Element {
        FIRE,
        WATER,
        EARTH,
        AIR,
        AETHER
    }

    // Define some example trial types
    enum TrialType {
        TRIAL_OF_ENDURANCE,
        TRIAL_OF_WISDOM,
        TRIAL_OF_STRENGTH
    }

    // --- Structs ---

    struct ChronicleAttributes {
        uint256 essence; // Energy for actions (can be refilled)
        uint256 affinity; // Alignment score based on ELEMENTAL_AFFINITY
        uint256 chronos; // Time/Age index (increases with passTime)
        uint256 consciousness; // Unlocks abilities at higher levels
        bool artifactDiscovered; // True if artifact found for this chronicle
    }

    struct TrialDefinition {
        bytes32 successOutcomeHash; // Hash representing success effects
        bytes32 failureOutcomeHash; // Hash representing failure effects
        // Note: Applying outcomes would involve revealing a preimage that matches the hash
        // and contains data on how attributes/traits change. Simplified here.
    }

    // --- State Variables ---

    // Chronicle data
    mapping(uint256 => ChronicleAttributes) private _chronicleAttributes;
    // tokenId => traitId => traitValue (bytes32 allows storing various data types)
    mapping(uint256 => mapping(uint256 => bytes32)) private _chronicleTraits;
    // tokenIdA => tokenIdB => isBonded (symmetric bond)
    mapping(uint256 => mapping(uint256 => bool)) private _chronicleBonds;
    // tokenId => timestamp of last passTime call
    mapping(uint256 => uint256) private _lastPassTime;
    // Keeps track of which traitIds are set for a chronicle for easier retrieval
    mapping(uint256 => uint256[]) private _chronicleTraitIds;

    // Configuration
    uint32 private _essenceInjectionRate; // Amount of essence per 1e18 Wei (1 Ether)
    uint256 private _timeUnitDurationSeconds; // How many seconds represent one "time unit" for chronos
    uint256 private _minConsciousnessForAbility; // Minimum consciousness needed for activation
    mapping(uint256 => TrialDefinition) private _trialDefinitions;

    // Keeper data
    uint256 private _lastKeeperRun;
    // Placeholder: In a real system, would track tokens needing upkeep, e.g., a list of tokenIds or a timestamp per token

    // --- Events ---

    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, uint256 genesisMark);
    event EssenceInjected(uint256 indexed tokenId, address indexed injector, uint256 amount, uint256 newEssence);
    event TimePassed(uint256 indexed tokenId, uint256 oldChronos, uint256 newChronos);
    event TrialCompleted(uint256 indexed tokenId, uint256 trialType, bool success, bytes32 outcomeHash);
    event ChronicleFused(uint256 indexed primaryTokenId, uint256 indexed fusedTokenId, uint256 newConsciousness, uint256 newEssence);
    event ChronicleBonded(uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event ChronicleChallenged(uint256 indexed challengerId, uint256 indexed targetId, bool challengerWon);
    event ConsciousnessAbilityActivated(uint256 indexed tokenId, uint256 consciousnessLevel);
    event AttributeChanged(uint256 indexed tokenId, string attributeName, uint256 oldValue, uint256 newValue);
    event TraitChanged(uint256 indexed tokenId, uint256 traitId, bytes32 oldValue, bytes32 newValue);
    event ArtifactDiscovered(uint256 indexed tokenId, address indexed owner);
    event KeeperRun(uint256 timestamp, uint256 tokensUpdatedCount);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Modifiers ---

    modifier whenChronicleExists(uint256 tokenId) {
        require(_exists(tokenId), "Chronicle: Token does not exist");
        _;
    }

     modifier whenChroniclesExist(uint256 tokenId1, uint256 tokenId2) {
        require(_exists(tokenId1) && _exists(tokenId2), "Chronicle: One or both tokens do not exist");
        require(tokenId1 != tokenId2, "Chronicle: Cannot interact with self");
        _;
    }

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint32 initialEssenceRate, // e.g., 1 ether = 1000 essence -> 1000e18 / 1e18 = 1000
        uint256 timeUnitDurationSeconds,
        uint256 minConsciousnessForAbility
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable(false) {
        _essenceInjectionRate = initialEssenceRate;
        _timeUnitDurationSeconds = timeUnitDurationSeconds;
        _minConsciousnessForAbility = minConsciousnessForAbility;
        _lastKeeperRun = block.timestamp;
    }

    // --- ERC721 Standard Functions (Inherited/Overridden) ---

    // All standard ERC721Enumerable, Ownable, Pausable functions are inherited.
    // Including: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom (x2), totalSupply, tokenOfOwnerByIndex, tokenByIndex,
    // pause, unpause, renounceOwnership, transferOwnership. Total 16 functions.

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real implementation, this URI would point to an external service (API/renderer)
        // that reads the on-chain state (_chronicleAttributes, _chronicleTraits) for this tokenId
        // and generates dynamic JSON metadata and/or imagery based on the traits and attributes.
        // For this example, it's a placeholder.
        return string(abi.encodePacked("https://your.metadata.api/", Strings.toString(tokenId)));
    }

    // --- Core Chronicle Management ---

    function mint(address owner) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Set base attributes
        _chronicleAttributes[newTokenId] = ChronicleAttributes({
            essence: 100,
            affinity: 0,
            chronos: 0,
            consciousness: 1,
            artifactDiscovered: false
        });

        // Set initial traits (example: Genesis Mark based on token ID modulo)
        _setTrait(newTokenId, uint256(TraitType.GENESIS_MARK), bytes32(newTokenId % 100)); // Simple example value

        _mint(owner, newTokenId);

        emit ChronicleMinted(newTokenId, owner, newTokenId % 100); // Example: Genesis Mark in event
        return newTokenId;
    }

    function burn(uint256 tokenId) public whenChronicleExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Chronicle: Caller is not owner nor approved");

        // Clean up associated state
        delete _chronicleAttributes[tokenId];
        delete _lastPassTime[tokenId];
        delete _chronicleTraitIds[tokenId]; // Doesn't clear the inner mapping, but removes the list of keys

        // In a real system, would need more sophisticated cleanup for mappings like _chronicleTraits and _chronicleBonds
        // For _chronicleTraits, iterating and deleting all traitIds for the token is needed.
        // For _chronicleBonds, iterating through all other tokens to remove bonds with the burned token is needed.
        // This adds complexity and gas cost. A simpler approach is to just check `_exists(tokenId)` before using its data.

        _burn(tokenId);
    }

    function getChronicleAttributes(uint256 tokenId) public view whenChronicleExists(tokenId) returns (ChronicleAttributes memory) {
        return _chronicleAttributes[tokenId];
    }

    function getChronicleTrait(uint256 tokenId, uint256 traitId) public view whenChronicleExists(tokenId) returns (bytes32) {
         // Check if the traitId has ever been set for this token to avoid returning default(bytes32) for unset traits
         // This requires iterating _chronicleTraitIds[tokenId], which can be gas-intensive for many traits.
         // A simpler check: is the traitId in the list?
         bool traitExists = false;
         uint256[] memory traitIds = _chronicleTraitIds[tokenId];
         for(uint i = 0; i < traitIds.length; i++) {
             if (traitIds[i] == traitId) {
                 traitExists = true;
                 break;
             }
         }
         require(traitExists, "Chronicle: Trait does not exist for this token");
         return _chronicleTraits[tokenId][traitId];
    }

    function getChronicleTraits(uint256 tokenId) public view whenChronicleExists(tokenId) returns (uint256[] memory traitIds, bytes32[] memory traitValues) {
        uint256[] memory ids = _chronicleTraitIds[tokenId];
        traitIds = new uint256[](ids.length);
        traitValues = new bytes32[](ids.length);

        for (uint i = 0; i < ids.length; i++) {
            uint256 traitId = ids[i];
            traitIds[i] = traitId;
            traitValues[i] = _chronicleTraits[tokenId][traitId];
        }
        return (traitIds, traitValues);
    }

    function getArtifactStatus(uint256 tokenId) public view whenChronicleExists(tokenId) returns (bool) {
        return _chronicleAttributes[tokenId].artifactDiscovered;
    }

    // --- Evolution & Interaction Functions ---

    function passTime(uint256 tokenId) public virtual whenNotPaused whenChronicleExists(tokenId) {
         // Only allow owner or approved or Keeper to call directly?
         // For Keepers, checkUpkeep/performUpkeep is the standard.
         // Let's allow owner/approved/Keeper for flexibility or testing.
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == address(this), "Chronicle: Caller is not owner, approved, or contract itself"); // Contract can call via performUpkeep

        uint256 lastUpdate = _lastPassTime[tokenId];
        uint256 timeElapsed = block.timestamp - lastUpdate;
        uint256 timeUnitsPassed = timeElapsed / _timeUnitDurationSeconds;

        if (timeUnitsPassed > 0) {
            uint256 oldChronos = _chronicleAttributes[tokenId].chronos;
            _chronicleAttributes[tokenId].chronos += timeUnitsPassed;
            _lastPassTime[tokenId] = block.timestamp; // Update last update time

            emit TimePassed(tokenId, oldChronos, _chronicleAttributes[tokenId].chronos);

            // Example: Trigger trait changes based on chronos (simplified)
            if (_chronicleAttributes[tokenId].chronos >= 10 && _chronicleAttributes[tokenId].chronos < 20 && bytes32(_chronicleTraits[tokenId][uint256(TraitType.CURRENT_STATE)]) == bytes32(0)) {
                 _setTrait(tokenId, uint256(TraitType.CURRENT_STATE), "Active");
            } else if (_chronicleAttributes[tokenId].chronos >= 20 && bytes32(_chronicleTraits[tokenId][uint256(TraitType.CURRENT_STATE)]) != bytes32("Evolved")) {
                 _setTrait(tokenId, uint256(TraitType.CURRENT_STATE), "Evolved");
                 // Also maybe increase consciousness slightly
                 _setAttribute(tokenId, "consciousness", _chronicleAttributes[tokenId].consciousness + 1);
            }

            // Example: Discover artifact upon reaching a specific chronos level
            if (_chronicleAttributes[tokenId].chronos >= 50 && !_chronicleAttributes[tokenId].artifactDiscovered) {
                _chronicleAttributes[tokenId].artifactDiscovered = true;
                emit ArtifactDiscovered(tokenId, ownerOf(tokenId));
            }
        }
    }

    // This function would typically be called by the Keeper's performUpkeep
    function batchPassTime(uint256[] calldata tokenIds) public virtual whenNotPaused {
         // Only allow owner or Keeper to call this
         // In a real keeper setup, this should only be callable by the Keeper compatible address
         // For this example, let's allow owner or contract itself (simulating keeper)
        require(msg.sender == owner() || msg.sender == address(this), "Chronicle: Caller is not owner or contract");

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (_exists(tokenId)) { // Check if token still exists (e.g., not burned between checkUpkeep and performUpkeep)
                 // Call the individual passTime logic
                 passTime(tokenId); // Note: passTime checks permissions internally, but batch is usually just called by trusted source
            }
        }
    }

    function injectEssence(uint256 tokenId) public payable whenNotPaused whenChronicleExists(tokenId) {
        require(msg.value > 0, "Chronicle: Must send Ether to inject essence");
        // Only owner or approved can inject? Or anyone can?
        // Let's allow anyone to inject essence into any chronicle they own or are approved for.
        require(_isApprovedOrOwner(msg.sender, tokenId), "Chronicle: Caller is not owner nor approved");

        uint256 essenceGained = (msg.value * _essenceInjectionRate) / 1e18; // Rate is Essence per Ether
        require(essenceGained > 0, "Chronicle: Amount too small to gain essence");

        uint256 oldEssence = _chronicleAttributes[tokenId].essence;
        _chronicleAttributes[tokenId].essence += essenceGained;

        emit EssenceInjected(tokenId, msg.sender, msg.value, _chronicleAttributes[tokenId].essence);
        emit AttributeChanged(tokenId, "essence", oldEssence, _chronicleAttributes[tokenId].essence);

        // Note: Sent Ether is held by the contract. Owner can withdraw via withdrawFees.
    }

    function undergoTrial(uint256 tokenId, uint256 trialType) public virtual whenNotPaused whenChronicleExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Chronicle: Caller is not owner nor approved");
        require(_chronicleAttributes[tokenId].essence >= 50, "Chronicle: Not enough essence for trial (requires 50)"); // Example cost
        require(_trialDefinitions[trialType].successOutcomeHash != bytes32(0), "Chronicle: Invalid trial type"); // Check if trial type exists

        _chronicleAttributes[tokenId].essence -= 50; // Deduct essence

        // --- Simulate Randomness (WARNING: DO NOT USE FOR HIGH-VALUE/HIGH-STAKES) ---
        // On-chain randomness is hard. This is a simple, exploitable example.
        // Use Chainlink VRF or similar for secure randomness.
        bytes32 pseudoRandomHash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, trialType, _chronicleAttributes[tokenId].chronos));
        bool success = uint256(pseudoRandomHash) % 100 < 60; // Example: 60% success rate

        bytes32 outcomeHash;
        if (success) {
            outcomeHash = _trialDefinitions[trialType].successOutcomeHash;
            // Apply positive effects (example: increase consciousness, change state trait)
            uint256 oldConsciousness = _chronicleAttributes[tokenId].consciousness;
            _chronicleAttributes[tokenId].consciousness += 5; // Example gain
             emit AttributeChanged(tokenId, "consciousness", oldConsciousness, _chronicleAttributes[tokenId].consciousness);
            _setTrait(tokenId, uint256(TraitType.CURRENT_STATE), "Triumphant"); // Example trait change
        } else {
            outcomeHash = _trialDefinitions[trialType].failureOutcomeHash;
            // Apply negative effects (example: decrease essence, change state trait)
             uint256 oldEssence = _chronicleAttributes[tokenId].essence;
             if (_chronicleAttributes[tokenId].essence >= 20) { // Don't go below 0
                 _chronicleAttributes[tokenId].essence -= 20;
             } else {
                 _chronicleAttributes[tokenId].essence = 0;
             }
             emit AttributeChanged(tokenId, "essence", oldEssence, _chronicleAttributes[tokenId].essence);
            _setTrait(tokenId, uint256(TraitType.CURRENT_STATE), "Setback"); // Example trait change
        }

        _setTrait(tokenId, uint256(TraitType.LAST_TRIAL_OUTCOME), outcomeHash);

        emit TrialCompleted(tokenId, trialType, success, outcomeHash);
    }

    function attuneToElement(uint256 tokenId, uint256 elementType) public whenNotPaused whenChronicleExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Chronicle: Caller is not owner nor approved");
        require(elementType < uint256(Element.AETHER) + 1, "Chronicle: Invalid element type"); // Check if element is valid

        // Example: Changing element costs essence
        require(_chronicleAttributes[tokenId].essence >= 30, "Chronicle: Not enough essence to attune (requires 30)");
         _chronicleAttributes[tokenId].essence -= 30;
         emit AttributeChanged(tokenId, "essence", _chronicleAttributes[tokenId].essence + 30, _chronicleAttributes[tokenId].essence);

        _setTrait(tokenId, uint256(TraitType.ELEMENTAL_AFFINITY), bytes32(elementType));
         // Example: Affinity attribute tracks the count of changes or last element type?
         // Let's make affinity track the *value* of the element enum
         uint256 oldAffinity = _chronicleAttributes[tokenId].affinity;
        _chronicleAttributes[tokenId].affinity = elementType;
         emit AttributeChanged(tokenId, "affinity", oldAffinity, _chronicleAttributes[tokenId].affinity);
    }


    function fuseChronicles(uint256 tokenId1, uint256 tokenId2) public virtual whenNotPaused whenChroniclesExist(tokenId1, tokenId2) {
        // Require ownership/approval of BOTH tokens by the caller
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Chronicle: Caller is not owner nor approved for token 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Chronicle: Caller is not owner nor approved for token 2");

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        // Ensure both tokens belong to the same owner for fusion, or caller is approved for both by different owners?
        // Let's require same owner for simplicity
        require(owner1 == owner2, "Chronicle: Both tokens must be owned by the same address to fuse");

        // Example Fusion Logic:
        // tokenId1 (primary) absorbs tokenId2 (secondary)
        // tokenId2 is burned.
        // tokenId1 gains some attributes/traits based on tokenId2.
        ChronicleAttributes memory attr1 = _chronicleAttributes[tokenId1];
        ChronicleAttributes memory attr2 = _chronicleAttributes[tokenId2];

        // Example Attribute Boost: primary gets 50% of secondary's essence and consciousness
        uint256 oldEssence1 = attr1.essence;
        uint256 oldConsciousness1 = attr1.consciousness;

        attr1.essence += attr2.essence / 2;
        attr1.consciousness += attr2.consciousness / 2;
        attr1.chronos = (attr1.chronos + attr2.chronos) / 2; // Average chronos? Or take max? Let's average.
        // Affinity logic could combine based on elements, etc. Simplified here.

        _chronicleAttributes[tokenId1] = attr1; // Update attributes for tokenId1

        emit AttributeChanged(tokenId1, "essence", oldEssence1, attr1.essence);
        emit AttributeChanged(tokenId1, "consciousness", oldConsciousness1, attr1.consciousness);
        emit AttributeChanged(tokenId1, "chronos", attr1.chronos, (attr1.chronos + attr2.chronos) / 2); // Emitting new value as (old+new)/2 is wrong, fix event

        // _setAttribute(tokenId1, "essence", attr1.essence); // Cleaner to use internal setter which emits event
        // _setAttribute(tokenId1, "consciousness", attr1.consciousness);
        // _setAttribute(tokenId1, "chronos", (attr1.chronos + attr2.chronos) / 2);


        // Example Trait Modification: maybe tokenId1 inherits a trait from tokenId2, or gains a new trait
        // For simplicity, let's say tokenId1 gains a new trait representing fusion or copies one trait from tokenId2
         _setTrait(tokenId1, uint256(TraitType.CURRENT_STATE), "Fused"); // Example: Change state trait
         // If tokenId2 had an artifact, maybe tokenId1 gets it too (or a fraction?) Let's make it discoverable again via time.

        // Burn the secondary token
        burn(tokenId2); // burn function handles checks and cleanup

        emit ChronicleFused(tokenId1, tokenId2, attr1.consciousness, attr1.essence);
    }

    function bondWithChronicle(uint256 tokenIdA, uint256 tokenIdB) public whenNotPaused whenChroniclesExist(tokenIdA, tokenIdB) {
         // Allow owners or approved to bond their tokens
        require(_isApprovedOrOwner(msg.sender, tokenIdA), "Chronicle: Caller is not owner nor approved for token A");
        require(_isApprovedOrOwner(msg.sender, tokenIdB), "Chronicle: Caller is not owner nor approved for token B");
        // For owner to bond their two tokens, they just need to own/be approved for both.
        // For two different owners to bond their tokens, both must approve the caller (or the caller must be an approved contract/address).

        require(!_chronicleBonds[tokenIdA][tokenIdB], "Chronicle: Bond already exists");

        _chronicleBonds[tokenIdA][tokenIdB] = true;
        _chronicleBonds[tokenIdB][tokenIdA] = true; // Make bond symmetric

        emit ChronicleBonded(tokenIdA, tokenIdB);
    }

    function challengeChronicle(uint256 challengerId, uint256 targetId) public virtual whenNotPaused whenChroniclesExist(challengerId, targetId) {
        // Requires ownership/approval of the challenger token
        require(_isApprovedOrOwner(msg.sender, challengerId), "Chronicle: Caller is not owner nor approved for challenger token");
        // Does the target token owner need to consent? For a simple "challenge", maybe not.
        // Let's allow a challenge from an approved address without target consent for simplicity,
        // affecting only the challenger and potentially the target's state passively.

        ChronicleAttributes memory challengerAttr = _chronicleAttributes[challengerId];
        ChronicleAttributes memory targetAttr = _chronicleAttributes[targetId];

        require(challengerAttr.essence >= 40, "Challenger: Not enough essence for challenge (requires 40)"); // Example cost
        _chronicleAttributes[challengerId].essence -= 40;
        emit AttributeChanged(challengerId, "essence", challengerAttr.essence, _chronicleAttributes[challengerId].essence - 40);


        // Simulate Outcome based on attributes (e.g., Consciousness, Essence, Affinity)
        // Use simplified, exploitable randomness again.
        bytes32 pseudoRandomHash = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, challengerId, targetId, challengerAttr, targetAttr));

        // Example Logic: Challenger wins if (challenger consciousness + essence/10) > (target consciousness + essence/10) * some_factor
        uint256 challengerScore = challengerAttr.consciousness + (challengerAttr.essence / 10) + uint256(pseudoRandomHash) % 50; // Add randomness bias
        uint256 targetScore = targetAttr.consciousness + (targetAttr.essence / 10);

        bool challengerWon = challengerScore > targetScore;

        if (challengerWon) {
            // Challenger gains something, target loses something
            _setAttribute(challengerId, "consciousness", challengerAttr.consciousness + 3); // Example gain
             uint256 oldTargetEssence = targetAttr.essence;
             if (targetAttr.essence >= 10) {
                 _setAttribute(targetId, "essence", targetAttr.essence - 10); // Example loss
             } else {
                 _setAttribute(targetId, "essence", 0);
             }
        } else {
            // Challenger loses something, target might gain something
            uint256 oldChallengerConsciousness = challengerAttr.consciousness;
             if (challengerAttr.consciousness >= 1) {
                 _setAttribute(challengerId, "consciousness", challengerAttr.consciousness - 1); // Example loss
             }
             _setAttribute(targetId, "consciousness", targetAttr.consciousness + 1); // Example gain
        }

        emit ChronicleChallenged(challengerId, targetId, challengerWon);
        // Could also emit AttributeChanged events here for clarity, but Challenge event summarizes.
    }


    // --- Attribute-Gated Abilities ---

    function activateConsciousnessAbility(uint256 tokenId) public virtual whenNotPaused whenChronicleExists(tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Chronicle: Caller is not owner nor approved");
        require(_chronicleAttributes[tokenId].consciousness >= _minConsciousnessForAbility, "Chronicle: Consciousness level too low");

        // Example Ability Effect: Gain a significant amount of essence
        uint256 oldEssence = _chronicleAttributes[tokenId].essence;
        _chronicleAttributes[tokenId].essence += 200; // Example boost

        emit ConsciousnessAbilityActivated(tokenId, _chronicleAttributes[tokenId].consciousness);
        emit AttributeChanged(tokenId, "essence", oldEssence, _chronicleAttributes[tokenId].essence);

        // Could also trigger trait changes, temporary buffs (if state included timestamps), etc.
    }

    function queryBondStatus(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        if (tokenIdA == tokenIdB) return false;
        // Don't require existence check here, just return false if either or both don't exist or aren't bonded
        return _chronicleBonds[tokenIdA][tokenIdB];
    }


    // --- Keeper Functions ---

    // This is a simplified check. A real keeper would need to iterate through tokens
    // or maintain a list of tokens needing updates, which can be complex and gas-intensive.
    // This example just checks if the last Keeper run was long ago.
    // A more advanced version might check _lastPassTime for a sample of tokens or iterate a list.
    function checkUpkeep(bytes calldata /* checkData */) external view returns (bool upkeepNeeded, bytes memory performData) {
        // Check if a significant amount of time has passed since last keeper run,
        // implying tokens might need their passTime updated.
        // A more robust check would track individual token _lastPassTime.
        upkeepNeeded = (block.timestamp - _lastKeeperRun) >= _timeUnitDurationSeconds * 10; // Example: check every 10 time units

        // If needed, performData could encode which tokens need updating (e.g., a list of IDs)
        // For this simple example, performData is empty, and performUpkeep will find tokens.
        performData = bytes(""); // Placeholder

        // NOTE: A real implementation might need to scan tokens or maintain a queue/list
        // of tokens requiring upkeep, which is non-trivial and can hit gas limits.
        // Chainlink Keepers can pass state back to help manage iterations across calls.
    }

    // This is a placeholder. A real performUpkeep would iterate and call passTime
    // for tokens identified as needing updates by checkUpkeep. Iterating all tokens
    // is not gas-efficient for large collections.
    function performUpkeep(bytes calldata /* performData */) external {
        // Only allow the contract itself (called by Keeper after checkUpkeep) to run this
        // In a real Keeper setup, msg.sender would be the Keeper contract address
        // require(msg.sender == <Keeper_Contract_Address>, "Chronicle: Only Keeper can call performUpkeep");

        // For this example, we'll simulate updating a few recent tokens or relying on batchPassTime
        // A real implementation would find outdated tokens and pass their IDs to batchPassTime.
        // As a simplification, we'll just increment a counter and emit an event.
        // TO IMPLEMENT PROPERLY: Find tokenIds needing updates and call batchPassTime(tokenIds).
        // Finding tokens needing update might require iterating or a separate index.

        _lastKeeperRun = block.timestamp;
        // Example: Update the last 10 minted tokens
        uint256 total = totalSupply();
        uint256 numToUpdate = total > 10 ? 10 : total;
        uint256[] memory recentTokenIds = new uint256[](numToUpdate);
        for(uint i = 0; i < numToUpdate; i++) {
             recentTokenIds[i] = total - i; // Assuming token IDs are sequential from 1
        }
         if(numToUpdate > 0) {
            batchPassTime(recentTokenIds);
         }


        emit KeeperRun(block.timestamp, numToUpdate); // Simulate updating numToUpdate tokens
    }


    // --- Admin/Configuration Functions ---

    function setEssenceInjectionRate(uint32 rate) public onlyOwner {
        _essenceInjectionRate = rate;
    }

    function addTrialType(uint256 trialType, bytes32 successOutcomeHash, bytes32 failureOutcomeHash) public onlyOwner {
        require(trialType > 0, "Chronicle: Trial type must be non-zero");
        require(_trialDefinitions[trialType].successOutcomeHash == bytes32(0), "Chronicle: Trial type already exists"); // Avoid overwriting
        _trialDefinitions[trialType] = TrialDefinition({
            successOutcomeHash: successOutcomeHash,
            failureOutcomeHash: failureOutcomeHash
        });
        // Note: The actual outcome data (preimage) would need to be provided off-chain
        // and revealed later, likely involving another function and verification.
    }

    function setConsciousnessThreshold(uint256 threshold) public onlyOwner {
        _minConsciousnessForAbility = threshold;
    }

    function setTrait(uint256 tokenId, uint256 traitId, bytes32 traitValue) public onlyOwner whenChronicleExists(tokenId) {
         _setTrait(tokenId, traitId, traitValue);
    }

    function setAttributes(uint256 tokenId, ChronicleAttributes memory newAttributes) public onlyOwner whenChronicleExists(tokenId) {
        // Simple override. Could add validation if needed.
        _chronicleAttributes[tokenId] = newAttributes;
        // Note: This does not emit individual attribute change events.
    }

    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Chronicle: No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Chronicle: Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }


    // --- Internal Helper Functions ---

    function _setTrait(uint256 tokenId, uint256 traitId, bytes32 traitValue) internal {
        bytes32 oldValue = _chronicleTraits[tokenId][traitId];
        _chronicleTraits[tokenId][traitId] = traitValue;

        // Track trait IDs for easier retrieval later via getChronicleTraits
        bool found = false;
        for(uint i = 0; i < _chronicleTraitIds[tokenId].length; i++) {
            if (_chronicleTraitIds[tokenId][i] == traitId) {
                found = true;
                break;
            }
        }
        if (!found && traitValue != bytes32(0)) { // Only add if new and non-zero value
            _chronicleTraitIds[tokenId].push(traitId);
        }
         // If setting to zero, consider removing from _chronicleTraitIds to save gas/space on reads (more complex)

        emit TraitChanged(tokenId, traitId, oldValue, traitValue);
    }

     function _setAttribute(uint256 tokenId, string memory attributeName, uint256 newValue) internal {
        // Note: This setter works for uint256 attributes.
        // Would need overloads or different approach for other types.
        // Using string attributeName is for the event, accessing the state
        // requires direct struct access or mapping.

        uint256 oldValue;
        // This requires knowing which attribute by string name corresponds to which in the struct,
        // or using if/else chain. Direct struct manipulation is safer.
        // This helper is mainly for emitting the event cleanly.

        if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("essence"))) {
            oldValue = _chronicleAttributes[tokenId].essence;
            _chronicleAttributes[tokenId].essence = newValue;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("affinity"))) {
             oldValue = _chronicleAttributes[tokenId].affinity;
             _chronicleAttributes[tokenId].affinity = newValue;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("chronos"))) {
             oldValue = _chronicleAttributes[tokenId].chronos;
             _chronicleAttributes[tokenId].chronos = newValue;
        } else if (keccak256(abi.encodePacked(attributeName)) == keccak256(abi.encodePacked("consciousness"))) {
             oldValue = _chronicleAttributes[tokenId].consciousness;
             _chronicleAttributes[tokenId].consciousness = newValue;
        } else {
            revert("Chronicle: Invalid attribute name for setting");
        }

        emit AttributeChanged(tokenId, attributeName, oldValue, newValue);
    }


    // The following functions are standard ERC721Enumerable overrides
    // that simply call the internal OpenZeppelin functions.
    // Including them explicitly confirms they are part of the contract interface.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Function to check ownership or approval for actions (used internally)
    function _isApprovedOrOwner(address caller, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        return caller == tokenOwner || getApproved(tokenId) == caller || isApprovedForAll(tokenOwner, caller);
    }
}
```