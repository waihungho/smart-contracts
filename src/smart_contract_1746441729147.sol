Okay, let's create a concept for a dynamic, evolving digital entity registry on the blockchain. We'll call it `MetaMorphRegistry`. These MetaMorphs are NFTs (ERC721) whose properties and 'evolution stage' can change over time, based on external triggers, and potentially through owner actions or interactions with other MetaMorphs.

This combines concepts of:
1.  **Dynamic NFTs:** Metadata and properties aren't static.
2.  **State Machines:** Entities transition through defined stages.
3.  **Oracle/External System Interaction:** Evolution can be triggered or influenced by external data or events via authorized addresses.
4.  **Game-like Mechanics:** Concepts like 'boosting', 'sacrificing', and 'evolution rules'.
5.  **Verifiable State:** A state hash allows verification of the entity's properties at a given moment.

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, Counters, ECDSA (optional, for signed external triggers - let's keep it simpler for now and use authorized addresses).
3.  **Enums:** `EvolutionStage` (e.g., Egg, Juvenile, Adult, Elder, Mythic).
4.  **Structs:**
    *   `MetaMorphState`: Stores the dynamic data for a single MetaMorph (stage, timestamp, properties mapping, trigger flags, state hash).
    *   `EvolutionRule`: Defines the requirements for a specific stage transition.
5.  **State Variables:**
    *   `_nextTokenId`: Counter for minting new tokens.
    *   `metaMorphs`: Mapping from token ID to `MetaMorphState`.
    *   `evolutionRules`: Mapping from current `EvolutionStage` to `EvolutionRule` for the *next* stage.
    *   `stageNames`: Mapping from `EvolutionStage` enum to string name.
    *   `authorizedTriggers`: Mapping of addresses allowed to trigger specific state changes.
    *   `baseTokenURI`: Base URI for metadata (will append token ID and perhaps a state identifier).
    *   `ADMIN_ROLE`, `TRIGGER_ROLE`: Bytes32 identifiers for roles (using simple boolean mapping for authorized triggers is sufficient for this example).
    *   `paused`: Inherited from Pausable.
6.  **Events:**
    *   `MetaMorphMinted`
    *   `MetaMorphEvolved`
    *   `PropertyChanged`
    *   `TriggerAuthorized`
    *   `TriggerRevoked`
    *   `StateSnapshotRecorded` (or just `StateHashUpdated`)
    *   `MetaMorphSacrificed`
7.  **Modifiers:**
    *   `onlyAuthorizedTrigger`
    *   `whenMetaMorphExists`
8.  **Constructor:** Initializes base URI and owner.
9.  **Core ERC721 Functions:** (Inherited and potentially overridden)
10. **State & Property Management Functions:** Getters and setters for dynamic state and properties.
11. **Evolution Mechanics Functions:** Checking readiness, triggering evolution, defining rules.
12. **Authorization Functions:** Managing addresses allowed to trigger external updates.
13. **Admin & Pausability Functions:** Setting rules, managing roles, pausing.
14. **Advanced/Creative Functions:** Sacrifice, state snapshot/verification.
15. **Metadata Function:** `tokenURI` override.
16. **Internal Helper Functions:** For state hashing, rule checking etc.

**Function Summary (at least 20 unique, non-ERC721 base functions):**

1.  `constructor(string memory initialBaseURI)`: Initializes the contract, ERC721 name/symbol, and base URI.
2.  `mint()`: Creates a new MetaMorph token, assigning it an initial stage and state.
3.  `getMetaMorphState(uint256 tokenId)`: Returns the full `MetaMorphState` struct for a given token ID.
4.  `getEvolutionStage(uint256 tokenId)`: Returns the current `EvolutionStage` of a MetaMorph.
5.  `getProperty(uint256 tokenId, string memory propertyName)`: Returns the value of a specific dynamic property for a MetaMorph.
6.  `setProperty(uint256 tokenId, string memory propertyName, uint256 value)`: Allows the owner to set a numeric property (can be restricted by property name or role internally).
7.  `incrementProperty(uint256 tokenId, string memory propertyName, uint256 amount)`: Increments a numeric property.
8.  `decrementProperty(uint256 tokenId, string memory propertyName, uint256 amount)`: Decrements a numeric property.
9.  `checkEvolutionReadiness(uint256 tokenId)`: Checks if a MetaMorph meets the requirements to evolve to the next stage based on its current state and rules.
10. `evolveMetaMorph(uint256 tokenId)`: Triggers the evolution process if the MetaMorph is ready, advancing its stage and updating state. Can be called by owner or perhaps automatically checked via a trigger.
11. `triggerExternalBoost(uint256 tokenId, string memory boostType)`: Called by an authorized trigger address to fulfill an external requirement for evolution or property boost.
12. `setEvolutionRule(EvolutionStage currentStage, EvolutionRule memory rule)`: (Admin Only) Defines the requirements for evolving *from* a specific stage.
13. `getEvolutionRule(EvolutionStage currentStage)`: Returns the `EvolutionRule` set for a specific stage.
14. `authorizeTrigger(address triggerAddress)`: (Owner Only) Grants permission to an address to call functions like `triggerExternalBoost`.
15. `revokeTrigger(address triggerAddress)`: (Owner Only) Removes permission from a trigger address.
16. `isAuthorizedTrigger(address triggerAddress)`: Checks if an address is authorized to trigger external actions.
17. `setStageName(EvolutionStage stage, string memory name)`: (Admin Only) Sets the human-readable name for an evolution stage.
18. `getStageName(EvolutionStage stage)`: Returns the human-readable name for an evolution stage.
19. `sacrificeMetaMorph(uint256 sacrificeTokenId, uint256 targetTokenId)`: Allows an owner to burn one MetaMorph (`sacrificeTokenId`) to provide a boost or fulfill an evolution requirement for another (`targetTokenId`).
20. `getMetaMorphStateHash(uint256 tokenId)`: Calculates and returns the current state hash of a MetaMorph.
21. `verifyStateSnapshot(uint256 tokenId, bytes32 providedHash)`: Verifies if a provided state hash matches the current calculated state hash for a MetaMorph.
22. `setBaseTokenURI(string memory newBaseURI)`: (Owner Only) Updates the base URI for metadata.
23. `getBaseTokenURI()`: Returns the current base token URI.
24. `pause()`: (Owner Only) Pauses certain contract functionalities (e.g., minting, transfers, potentially evolution).
25. `unpause()`: (Owner Only) Unpauses the contract.

(Note: ERC721 methods like `balanceOf`, `ownerOf`, `transferFrom`, `approve`, `getApproved`, `isApprovedForAll`, `setApprovalForAll` add another 8-9 functions, bringing the total well over 20).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline ---
// 1. License and Pragma
// 2. Imports: ERC721, Ownable, Pausable, Counters, Strings
// 3. Enums: EvolutionStage
// 4. Structs: MetaMorphState, EvolutionRule
// 5. State Variables: nextTokenId, metaMorphs, evolutionRules, stageNames, authorizedTriggers, baseTokenURI, paused
// 6. Events: MetaMorphMinted, MetaMorphEvolved, PropertyChanged, TriggerAuthorized, TriggerRevoked, StateHashUpdated, MetaMorphSacrificed
// 7. Modifiers: onlyAuthorizedTrigger, whenMetaMorphExists
// 8. Constructor
// 9. Core ERC721 Functions (Inherited + Override tokenURI, _beforeTokenTransfer for pause)
// 10. State & Property Management Functions: Getters and setters for dynamic state and properties.
// 11. Evolution Mechanics Functions: Checking readiness, triggering evolution, defining rules.
// 12. Authorization Functions: Managing addresses allowed to trigger external updates.
// 13. Admin & Pausability Functions: Setting rules, managing roles, pausing.
// 14. Advanced/Creative Functions: Sacrifice, state snapshot/verification.
// 15. Metadata Function: tokenURI override.
// 16. Internal Helper Functions: State hashing, rule checking.

// --- Function Summary ---
// 1.  constructor(string memory initialBaseURI): Initializes the contract, ERC721 name/symbol, and base URI.
// 2.  mint(): Creates a new MetaMorph token (NFT), assigning it an initial stage and state.
// 3.  getMetaMorphState(uint256 tokenId): Returns the full MetaMorphState struct for a given token ID.
// 4.  getEvolutionStage(uint256 tokenId): Returns the current EvolutionStage of a MetaMorph.
// 5.  getProperty(uint256 tokenId, string memory propertyName): Returns the uint256 value of a specific dynamic property for a MetaMorph.
// 6.  setProperty(uint256 tokenId, string memory propertyName, uint256 value): Allows the owner to set a numeric property (basic implementation, can be restricted).
// 7.  incrementProperty(uint256 tokenId, string memory propertyName, uint256 amount): Increments a numeric property.
// 8.  decrementProperty(uint256 tokenId, string memory propertyName, uint256 amount): Decrements a numeric property.
// 9.  checkEvolutionReadiness(uint256 tokenId): Checks if a MetaMorph meets the requirements to evolve to the next stage based on its current state and rules.
// 10. evolveMetaMorph(uint256 tokenId): Triggers the evolution process if the MetaMorph is ready, advancing its stage and updating state.
// 11. triggerExternalBoost(uint256 tokenId, string memory boostType): Called by an authorized trigger address to fulfill an external requirement (e.g., for evolution).
// 12. setEvolutionRule(EvolutionStage currentStage, EvolutionRule memory rule): (Admin Only) Defines the requirements for evolving *from* a specific stage.
// 13. getEvolutionRule(EvolutionStage currentStage): Returns the EvolutionRule set for a specific stage.
// 14. authorizeTrigger(address triggerAddress): (Owner Only) Grants permission to an address to call functions like triggerExternalBoost.
// 15. revokeTrigger(address triggerAddress): (Owner Only) Removes permission from a trigger address.
// 16. isAuthorizedTrigger(address triggerAddress): Checks if an address is authorized to trigger external actions.
// 17. setStageName(EvolutionStage stage, string memory name): (Admin Only) Sets the human-readable name for an evolution stage.
// 18. getStageName(EvolutionStage stage): Returns the human-readable name for an evolution stage.
// 19. sacrificeMetaMorph(uint256 sacrificeTokenId, uint256 targetTokenId): Allows an owner to burn one MetaMorph to provide a boost or fulfill an evolution requirement for another.
// 20. getMetaMorphStateHash(uint256 tokenId): Calculates and returns the current state hash of a MetaMorph.
// 21. verifyStateSnapshot(uint256 tokenId, bytes32 providedHash): Verifies if a provided state hash matches the current calculated state hash for a MetaMorph.
// 22. setBaseTokenURI(string memory newBaseURI): (Owner Only) Updates the base URI for metadata.
// 23. getBaseTokenURI(): Returns the current base token URI.
// 24. pause(): (Owner Only) Pauses certain contract functionalities.
// 25. unpause(): (Owner Only) Unpauses the contract.
// (Plus standard ERC721 functions inherited and exposed by ERC721URIStorage: name, symbol, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom)

contract MetaMorphRegistry is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _nextTokenId;

    enum EvolutionStage {
        Egg,
        Juvenile,
        Adult,
        Elder,
        Mythic,
        Corrupted,
        Awakened,
        STAGE_COUNT // Sentinel value for array sizing if needed, not a real stage
    }

    struct MetaMorphState {
        EvolutionStage stage;
        uint256 lastStateChangeTime; // Timestamp of last evolution or significant state change
        mapping(string => uint256) propertiesUint; // Dynamic integer properties
        mapping(string => string) propertiesString; // Dynamic string properties
        mapping(string => bool) externalTriggersUsed; // Flags for external boosts/triggers used
        bytes32 stateHash; // Hash of the current key state fields for verification
    }

    struct EvolutionRule {
        EvolutionStage requiredCurrentStage; // Must be at this stage to use this rule
        EvolutionStage nextStage;            // Stage after evolution
        uint256 minTimeInStage;              // Minimum seconds required in requiredCurrentStage
        mapping(string => bool) requiredExternalTriggers; // Map of trigger types needed
        // Future complexity: property minimums, token burns, fee requirements etc.
    }

    // State Variables
    mapping(uint256 => MetaMorphState) private _metaMorphs;
    mapping(EvolutionStage => EvolutionRule) private _evolutionRules;
    mapping(EvolutionStage => string) private _stageNames;
    mapping(address => bool) private _authorizedTriggers; // Addresses allowed to call triggerExternalBoost

    string private _baseTokenURI;

    // Events
    event MetaMorphMinted(uint256 indexed tokenId, address indexed owner, EvolutionStage initialStage);
    event MetaMorphEvolved(uint256 indexed tokenId, EvolutionStage fromStage, EvolutionStage toStage, uint256 evolutionTime);
    event PropertyUintChanged(uint256 indexed tokenId, string propertyName, uint256 oldValue, uint256 newValue);
    event PropertyStringChanged(uint256 indexed tokenId, string propertyName, string oldValue, string newValue);
    event ExternalTriggerUsed(uint256 indexed tokenId, string triggerType, address indexed triggerAddress);
    event TriggerAuthorized(address indexed triggerAddress);
    event TriggerRevoked(address indexed triggerAddress);
    event StateHashUpdated(uint256 indexed tokenId, bytes32 newStateHash);
    event MetaMorphSacrificed(uint256 indexed sacrificeTokenId, uint256 indexed targetTokenId, uint256 timestamp);
    event EvolutionRuleSet(EvolutionStage indexed currentStage, EvolutionStage indexed nextStage);

    // Modifiers
    modifier onlyAuthorizedTrigger() {
        require(_authorizedTriggers[msg.sender], "MetaMorph: Not authorized trigger");
        _;
    }

    modifier whenMetaMorphExists(uint256 tokenId) {
        require(_exists(tokenId), "MetaMorph: Token does not exist");
        _;
    }

    // Constructor
    constructor(string memory initialBaseURI) ERC721("MetaMorph", "MORPH") Ownable(msg.sender) {
        _baseTokenURI = initialBaseURI;

        // Set default stage names (can be overridden by admin)
        _stageNames[EvolutionStage.Egg] = "Egg";
        _stageNames[EvolutionStage.Juvenile] = "Juvenile";
        _stageNames[EvolutionStage.Adult] = "Adult";
        _stageNames[EvolutionStage.Elder] = "Elder";
        _stageNames[EvolutionStage.Mythic] = "Mythic";
        _stageNames[EvolutionStage.Corrupted] = "Corrupted";
        _stageNames[EvolutionStage.Awakened] = "Awakened";
    }

    // --- Core ERC721 Overrides ---

    function tokenURI(uint256 tokenId) public view override whenMetaMorphExists(tokenId) returns (string memory) {
        // This implementation assumes the baseTokenURI points to a service
        // that can interpret the token ID and query the contract state
        // (using getMetaMorphState or individual getters) to generate dynamic metadata.
        // The standard ERC721URIStorage would append the token ID directly.
        // We return the base URI, signaling that the metadata is dynamic.
        // A more specific implementation could append token ID or state hash:
        // string memory base = _baseTokenURI;
        // return string(abi.encodePacked(base, tokenId.toString())); // Or .../tokenId/stateHash
        return _baseTokenURI; // Signal dynamic metadata
    }

    // Pausability hook for transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // --- State & Property Management Functions ---

    // 3. getMetaMorphState
    function getMetaMorphState(uint256 tokenId) public view whenMetaMorphExists(tokenId) returns (MetaMorphState memory) {
        // Note: Mappings within structs (like propertiesUint) cannot be returned directly.
        // We return the base struct data. Properties need dedicated getters.
        MetaMorphState storage morph = _metaMorphs[tokenId];
        return MetaMorphState({
            stage: morph.stage,
            lastStateChangeTime: morph.lastStateChangeTime,
            propertiesUint: morph.propertiesUint, // This mapping is not fully returned
            propertiesString: morph.propertiesString, // This mapping is not fully returned
            externalTriggersUsed: morph.externalTriggersUsed, // This mapping is not fully returned
            stateHash: morph.stateHash
        });
        // To get properties, use getProperty.
    }

    // 4. getEvolutionStage
    function getEvolutionStage(uint256 tokenId) public view whenMetaMorphExists(tokenId) returns (EvolutionStage) {
        return _metaMorphs[tokenId].stage;
    }

    // 5. getProperty (uint256)
    function getProperty(uint256 tokenId, string memory propertyName) public view whenMetaMorphExists(tokenId) returns (uint256) {
        return _metaMorphs[tokenId].propertiesUint[propertyName];
    }

    // 6. setProperty (uint256)
    function setProperty(uint256 tokenId, string memory propertyName, uint256 value) public whenMetaMorphExists(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can set properties");
        // Add further restrictions here if only certain properties can be set by owner

        uint256 oldValue = _metaMorphs[tokenId].propertiesUint[propertyName];
        _metaMorphs[tokenId].propertiesUint[propertyName] = value;

        _updateStateHash(tokenId); // State change -> update hash
        emit PropertyUintChanged(tokenId, propertyName, oldValue, value);
    }

    // 7. incrementProperty (uint256)
    function incrementProperty(uint256 tokenId, string memory propertyName, uint256 amount) public whenMetaMorphExists(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can increment properties");

        uint256 oldValue = _metaMorphs[tokenId].propertiesUint[propertyName];
        _metaMorphs[tokenId].propertiesUint[propertyName] = oldValue + amount;

        _updateStateHash(tokenId); // State change -> update hash
        emit PropertyUintChanged(tokenId, propertyName, oldValue, _metaMorphs[tokenId].propertiesUint[propertyName]);
    }

    // 8. decrementProperty (uint256)
    function decrementProperty(uint256 tokenId, string memory propertyName, uint256 amount) public whenMetaMorphExists(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can decrement properties");
        require(_metaMorphs[tokenId].propertiesUint[propertyName] >= amount, "MetaMorph: Insufficient property value");

        uint256 oldValue = _metaMorphs[tokenId].propertiesUint[propertyName];
        _metaMorphs[tokenId].propertiesUint[propertyName] = oldValue - amount;

        _updateStateHash(tokenId); // State change -> update hash
        emit PropertyUintChanged(tokenId, propertyName, oldValue, _metaMorphs[tokenId].propertiesUint[propertyName]);
    }

    // --- Evolution Mechanics Functions ---

    // 9. checkEvolutionReadiness
    function checkEvolutionReadiness(uint256 tokenId) public view whenMetaMorphExists(tokenId) returns (bool) {
        MetaMorphState storage morph = _metaMorphs[tokenId];
        EvolutionRule storage rule = _evolutionRules[morph.stage];

        // Check if there is a rule defined for the current stage
        if (rule.requiredCurrentStage != morph.stage) {
            // No rule defined for this stage, cannot evolve via standard rules
            return false;
        }

        // Check time requirement
        if (block.timestamp < morph.lastStateChangeTime + rule.minTimeInStage) {
            return false;
        }

        // Check external trigger requirements
        // Iterate through required triggers in the rule and check if they have been used
        // (This requires iterating a mapping, which is not directly possible in Solidity.
        // A production system would need to store required triggers in an array or handle differently).
        // For this example, let's assume rules only require ONE specific trigger type, or none.
        // A more robust system might store `string[] requiredTriggerTypes` in the rule struct
        // and loop through it here.
        // Simple check: Does the rule *require* a specific trigger type to be used?
        // If rule.requiredExternalTriggers["someTriggerType"] is true, check morph.externalTriggersUsed["someTriggerType"].
        // Let's refine the rule struct to make this iterable or handle a fixed set of trigger checks.
        // For simplicity, let's just check if *any* required trigger (as defined in the rule's mapping) has *not* been used.
        // **NOTE:** Iterating mappings in rules/state directly is impossible or gas-prohibitive.
        // A practical implementation needs a fixed list of potential trigger types or a different data structure.
        // Let's simulate with a single hardcoded required trigger check for demo purposes.
         if (rule.requiredExternalTriggers["basic_boost"] && !morph.externalTriggersUsed["basic_boost"]) {
             return false; // Requires "basic_boost" trigger but not used
         }
         // Add checks for other potential required triggers defined in the rule...
         // if (rule.requiredExternalTriggers["sacrifice_boost"] && !morph.externalTriggersUsed["sacrifice_boost"]) return false;


        // If all checks pass
        return true;
    }


    // 10. evolveMetaMorph
    function evolveMetaMorph(uint256 tokenId) public whenMetaMorphExists(tokenId) whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "MetaMorph: Only owner can trigger evolution");
        require(checkEvolutionReadiness(tokenId), "MetaMorph: Not ready to evolve");

        MetaMorphState storage morph = _metaMorphs[tokenId];
        EvolutionRule storage rule = _evolutionRules[morph.stage];

        EvolutionStage oldStage = morph.stage;
        morph.stage = rule.nextStage;
        morph.lastStateChangeTime = block.timestamp; // Reset timer on evolution

        // Reset used external triggers for the next stage requirements
        // Again, iterating mappings is tricky. A practical approach: clear flags for a known set of trigger types.
        delete morph.externalTriggersUsed["basic_boost"]; // Clear specific flags
        delete morph.externalTriggersUsed["sacrifice_boost"]; // Clear specific flags
        // ... clear other potential trigger flags

        _updateStateHash(tokenId); // State change -> update hash
        emit MetaMorphEvolved(tokenId, oldStage, morph.stage, block.timestamp);
    }

    // 11. triggerExternalBoost
    function triggerExternalBoost(uint256 tokenId, string memory boostType) public onlyAuthorizedTrigger whenMetaMorphExists(tokenId) whenNotPaused {
        // This function is called by an authorized external system (like an oracle)
        // to indicate a specific event happened or requirement is met for this MetaMorph.
        // The boostType string allows different types of external triggers.

        MetaMorphState storage morph = _metaMorphs[tokenId];

        // Mark the trigger type as used for this morph's current state
        morph.externalTriggersUsed[boostType] = true;

        // Optional: Apply immediate property boosts based on boostType
        // Example: if (keccak256(abi.encodePacked(boostType)) == keccak256(abi.encodePacked("basic_boost"))) {
        //     morph.propertiesUint["strength"] += 10;
        // }

        _updateStateHash(tokenId); // State change -> update hash
        emit ExternalTriggerUsed(tokenId, boostType, msg.sender);
        // Note: The evolution logic in checkEvolutionReadiness will now see this trigger has been used.
    }

    // 12. setEvolutionRule
    function setEvolutionRule(EvolutionStage currentStage, EvolutionRule memory rule) public onlyOwner {
        // Basic rule validation: The requiredCurrentStage in the rule should match the mapping key
        require(rule.requiredCurrentStage == currentStage, "MetaMorph: Rule must match currentStage key");
        require(uint8(currentStage) < uint8(EvolutionStage.STAGE_COUNT), "MetaMorph: Invalid current stage");
        require(uint8(rule.nextStage) < uint8(EvolutionStage.STAGE_COUNT), "MetaMorph: Invalid next stage");
        require(uint8(rule.nextStage) != uint8(currentStage), "MetaMorph: Next stage cannot be the same as current");

        _evolutionRules[currentStage] = rule;
        emit EvolutionRuleSet(currentStage, rule.nextStage);
    }

    // 13. getEvolutionRule
    function getEvolutionRule(EvolutionStage currentStage) public view returns (EvolutionRule memory) {
         // Mappings inside structs cannot be returned directly.
         // We can return the base struct values, but requiredExternalTriggers map won't be accessible.
         // A practical solution would be to store required triggers in a fixed-size array or list.
         EvolutionRule storage rule = _evolutionRules[currentStage];
         return EvolutionRule({
             requiredCurrentStage: rule.requiredCurrentStage,
             nextStage: rule.nextStage,
             minTimeInStage: rule.minTimeInStage,
             requiredExternalTriggers: rule.requiredExternalTriggers // This mapping data is not accessible outside
         });
         // To check specific required triggers in a rule, a dedicated getter would be needed:
         // function isTriggerRequiredForEvolution(EvolutionStage stage, string memory triggerType) public view returns (bool) { ... }
    }

    // --- Authorization Functions ---

    // 14. authorizeTrigger
    function authorizeTrigger(address triggerAddress) public onlyOwner {
        require(triggerAddress != address(0), "MetaMorph: Zero address");
        _authorizedTriggers[triggerAddress] = true;
        emit TriggerAuthorized(triggerAddress);
    }

    // 15. revokeTrigger
    function revokeTrigger(address triggerAddress) public onlyOwner {
        require(triggerAddress != address(0), "MetaMorph: Zero address");
        _authorizedTriggers[triggerAddress] = false;
        emit TriggerRevoked(triggerAddress);
    }

    // 16. isAuthorizedTrigger
    function isAuthorizedTrigger(address triggerAddress) public view returns (bool) {
        return _authorizedTriggers[triggerAddress];
    }

    // --- Admin & Pausability Functions ---

    // 17. setStageName
    function setStageName(EvolutionStage stage, string memory name) public onlyOwner {
        require(uint8(stage) < uint8(EvolutionStage.STAGE_COUNT), "MetaMorph: Invalid stage");
        _stageNames[stage] = name;
    }

    // 18. getStageName
    function getStageName(EvolutionStage stage) public view returns (string memory) {
         require(uint8(stage) < uint8(EvolutionStage.STAGE_COUNT), "MetaMorph: Invalid stage");
        return _stageNames[stage];
    }

    // 22. setBaseTokenURI
    function setBaseTokenURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // 23. getBaseTokenURI
    function getBaseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // 24. pause
    function pause() public onlyOwner {
        _pause();
    }

    // 25. unpause
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Advanced/Creative Functions ---

    // 19. sacrificeMetaMorph
    // Burns sacrificeTokenId and grants a boost or fulfills a requirement on targetTokenId
    function sacrificeMetaMorph(uint256 sacrificeTokenId, uint256 targetTokenId) public whenMetaMorphExists(sacrificeTokenId) whenMetaMorphExists(targetTokenId) whenNotPaused {
        // Require owner to own both tokens
        require(ownerOf(sacrificeTokenId) == msg.sender, "MetaMorph: Must own sacrifice token");
        require(ownerOf(targetTokenId) == msg.sender, "MetaMorph: Must own target token");
        require(sacrificeTokenId != targetTokenId, "MetaMorph: Cannot sacrifice to self");

        MetaMorphState storage targetMorph = _metaMorphs[targetTokenId];
        // Example boost: Fulfill a specific external trigger requirement on the target
        string memory boostType = "sacrifice_boost";
        targetMorph.externalTriggersUsed[boostType] = true;
        // Optional: transfer some property value, add a flat property boost, etc.
        // uint256 sacrificeStrength = _metaMorphs[sacrificeTokenId].propertiesUint["strength"];
        // targetMorph.propertiesUint["strength"] += sacrificeStrength / 2; // Example property transfer

        // Burn the sacrifice token
        _burn(sacrificeTokenId);
        // ERC721URIStorage requires clearing URI storage on burn
        _deleteTokenURI(sacrificeTokenId);

        _updateStateHash(targetTokenId); // State change on target -> update hash
        emit MetaMorphSacrificed(sacrificeTokenId, targetTokenId, block.timestamp);
        emit ExternalTriggerUsed(targetTokenId, boostType, msg.sender); // Also log the trigger effect
    }

    // 20. getMetaMorphStateHash (Calculates current hash)
    function getMetaMorphStateHash(uint256 tokenId) public view whenMetaMorphExists(tokenId) returns (bytes32) {
         // Calculate hash of relevant dynamic state fields
        MetaMorphState storage morph = _metaMorphs[tokenId];
         // Hashing mappings is not feasible/standard.
         // Hash key state variables: stage, lastStateChangeTime, maybe a flag.
         // For simplicity, hash the stage and last state change time.
         // A more robust hash would include hashes of property states or a root of a Merkle tree of properties.
         return keccak256(abi.encode(morph.stage, morph.lastStateChangeTime, morph.externalTriggersUsed["basic_boost"], morph.externalTriggersUsed["sacrifice_boost"])); // Include key trigger flags
    }

    // 21. verifyStateSnapshot
     function verifyStateSnapshot(uint256 tokenId, bytes32 providedHash) public view whenMetaMorphExists(tokenId) returns (bool) {
         bytes32 currentHash = getMetaMorphStateHash(tokenId);
         return currentHash == providedHash;
     }

    // --- Internal Helper Functions ---

    // Internal function to mint a new MetaMorph
    function _mint(address to) internal returns (uint256) {
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(to, newTokenId); // Use safeMint from ERC721

        // Initialize MetaMorph State
        _metaMorphs[newTokenId].stage = EvolutionStage.Egg;
        _metaMorphs[newTokenId].lastStateChangeTime = block.timestamp;
        // Initialize default properties if needed
        _metaMorphs[newTokenId].propertiesUint["level"] = 1;

        _updateStateHash(newTokenId); // Calculate initial hash

        emit MetaMorphMinted(newTokenId, to, EvolutionStage.Egg);

        return newTokenId;
    }

    // Internal function to update the state hash
    function _updateStateHash(uint256 tokenId) internal {
        bytes32 newHash = getMetaMorphStateHash(tokenId);
        _metaMorphs[tokenId].stateHash = newHash;
        emit StateHashUpdated(tokenId, newHash);
    }

    // --- Public Minting Function (Wrapper for internal _mint) ---
    function mint() public whenNotPaused returns (uint256) {
        return _mint(msg.sender);
    }

    // --- Standard ERC721 functions exposed by inheritance ---
    // name(), symbol(), balanceOf(address owner), ownerOf(uint256 tokenId),
    // approve(address to, uint256 tokenId), getApproved(uint256 tokenId),
    // setApprovalForAll(address operator, bool approved), isApprovedForAll(address owner, address operator),
    // transferFrom(address from, address to, uint256 tokenId),
    // safeTransferFrom(address from, address to, uint256 tokenId),
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
}
```

**Explanation and Advanced Concepts:**

1.  **Dynamic State (`MetaMorphState` struct):** Unlike standard NFTs where metadata often lives entirely off-chain and is static or points to static data, this contract stores key dynamic properties (`stage`, `lastStateChangeTime`, mappings for properties and triggers) directly on-chain for each token.
2.  **On-Chain Evolution Engine:** The `EvolutionStage` enum and `EvolutionRule` struct define a state machine. The `evolveMetaMorph` function manages transitions based on predefined rules stored on-chain.
3.  **Time-Based Mechanics:** `minTimeInStage` in `EvolutionRule` introduces a time lock, requiring MetaMorphs to spend a certain duration in a stage before evolving.
4.  **External Triggers/Oracle Interaction:** `authorizedTriggers` and `triggerExternalBoost` provide a secure way for off-chain systems (like oracles monitoring real-world events, game servers, or other smart contracts) to influence a MetaMorph's state or fulfill evolution requirements. This decouples the *trigger* from the *evolution* itself.
5.  **Programmable Properties:** Using `mapping(string => uint256)` for properties allows for flexible, dynamic attributes that can be modified by the owner or authorized triggers, enabling complex mechanics (stats, progression, etc.). String properties are also included.
6.  **Sacrifice Mechanic:** `sacrificeMetaMorph` introduces a creative, game-like interaction where one NFT can be destroyed to benefit another owned by the same user, adding strategic depth.
7.  **Verifiable State Hash:** `stateHash` and associated functions (`getMetaMorphStateHash`, `verifyStateSnapshot`, `_updateStateHash`) allow anyone to verify the integrity of a MetaMorph's on-chain state at any given moment. While a simple hash is used here, this pattern can be extended with Merkle trees for complex property structures.
8.  **Dynamic Metadata (`tokenURI` override):** The `tokenURI` override signals that the metadata should be fetched dynamically by an off-chain service. This service would query the contract's state for the specific `tokenId` to generate metadata (like JSON, SVG, etc.) reflecting the current stage, properties, etc.
9.  **Role-Based Access Control (Simplified):** Using `onlyOwner` and `onlyAuthorizedTrigger` modifiers manages who can perform sensitive actions like setting rules or triggering external boosts.

This contract provides a framework for NFTs that are not merely static collectibles but living, evolving entities whose characteristics and journey are recorded and governed by the blockchain logic.

**Important Considerations for Production:**

*   **Gas Costs:** Mappings, especially large ones or complex iterations, can be gas-intensive. The current design simplifies map handling for the example, but a production version would need optimization (e.g., using arrays for known lists of properties/triggers, state-channel solutions for rapid property updates).
*   **Metadata Service:** The dynamic `tokenURI` requires a reliable, potentially decentralized off-chain service to generate metadata based on the on-chain state.
*   **Oracle/Trigger Reliability:** If evolution heavily depends on `triggerExternalBoost`, the reliability and security of the authorized trigger source are paramount.
*   **Complexity vs. Security:** More complex state logic increases the potential for bugs. Thorough testing and audits are essential.
*   **Property Management:** The simple `setProperty`, `incrementProperty`, `decrementProperty` functions are basic. A real application would likely need more nuanced control over *which* properties can be changed by *whom* and *when*.
*   **Evolution Rules:** The `EvolutionRule` struct and check are basic. Real rules could involve property minimums, consumption of other tokens, etc. Storing complex rules efficiently on-chain is a design challenge.