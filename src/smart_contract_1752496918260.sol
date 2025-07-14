Okay, this is an exciting challenge! Let's design a contract that manages abstract "Entities" within a "Quantum Realm," focusing on dynamic states, inter-entity relationships, time-based effects, and multiple interaction layers beyond simple token transfers.

We'll avoid standard ERC-20/721 interfaces directly, managing ownership and state internally to provide a unique structure.

**Concept:** The `QuantumRealmRegistry` contract acts as a decentralized ledger for "Entities" existing within a conceptual "Quantum Realm". Each Entity is a unique digital asset represented by a `tokenId`. Entities possess dynamic properties (Alignment, Resonance, Entropy) that change over time or through interactions. The Realm itself has a shared energy pool and global parameters. Interaction between Entities and the Realm is key.

---

### **QuantumRealmRegistry Smart Contract**

**Outline:**

1.  **Contract Definition:** Basic structure, license, pragma.
2.  **Roles & Access Control:** Define roles (`owner`, `guardian`) and custom modifiers.
3.  **Enums:** Define possible states for Entity properties (e.g., Alignment).
4.  **Structs:** Define the `Entity` data structure.
5.  **State Variables:** Mappings for entity data, ownership, realm parameters, energy pool.
6.  **Events:** Announce key actions and state changes.
7.  **Constructor:** Initialize roles and basic parameters.
8.  **Modifiers:** Custom access control logic.
9.  **Internal Helpers:** Functions used internally.
10. **Entity Management Functions (ERC721-like but custom):** Register, transfer, get details.
11. **Dynamic State Functions:** Update Entity properties (Alignment, Resonance, Entropy).
12. **Relationship Functions:** Link and unlink Entities.
13. **Realm Interaction Functions:** Transfer energy, claim energy, affect realm state.
14. **Advanced / Creative Functions:** Synthesis, fragmentation, attunement, batch operations, conditional actions.
15. **View Functions:** Read-only access to state.

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and guardian address.
2.  `registerEntity(address initialOwner, uint256 initialResonance, Alignment initialAlignment)`: Creates a new Entity with specified properties and assigns ownership. Requires ETH payment (energy contribution).
3.  `transferEntityOwnership(uint256 tokenId, address newOwner)`: Transfers ownership of an Entity to a new address (ERC721-like safeTransferFrom).
4.  `approveEntityTransfer(address approved, uint256 tokenId)`: Approves an address to transfer a specific Entity.
5.  `getApproved(uint256 tokenId)`: Returns the approved address for an Entity.
6.  `getEntityDetails(uint256 tokenId)`: Returns all current properties of an Entity. (View)
7.  `updateEntityAlignment(uint256 tokenId, Alignment newAlignment)`: Changes an Entity's alignment. Only callable by the Entity owner or approved.
8.  `updateEntityResonance(uint256 tokenId, uint256 newFrequency)`: Changes an Entity's resonance frequency. Only callable by the Entity owner or approved.
9.  `anchorEntity(uint256 tokenId)`: Sets an Entity's `isAnchored` state to true. Only callable by the Entity owner or approved.
10. `unanchorEntity(uint256 tokenId)`: Sets an Entity's `isAnchored` state to false. Only callable by the Entity owner or approved.
11. `triggerEntropyDecay(uint256 tokenId)`: Calculates and updates an Entity's entropy based on time elapsed since the last update and the realm's decay rate. Can be triggered by anyone.
12. `applyResonanceHarmonization(uint256 tokenId)`: Applies a positive effect (e.g., reduces entropy) if an Entity's resonance is close to the realm's threshold. Consumes Realm energy.
13. `linkEntities(uint256 tokenId1, uint256 tokenId2)`: Creates a bidirectional link between two Entities. Requires ownership of both.
14. `unlinkEntities(uint256 tokenId1, uint256 tokenId2)`: Removes a bidirectional link between two Entities. Requires ownership of both.
15. `getLinkedEntities(uint256 tokenId)`: Returns the list of Entities linked to a specific one. (View)
16. `transferEnergyToRealm()`: Allows anyone to send ETH to the contract, increasing the Realm's energy pool. (Payable)
17. `claimEnergyFromRealm(uint256 tokenId)`: Allows the owner of an Entity to claim a portion of the Realm's energy, potentially based on the Entity's state (e.g., resonance, alignment).
18. `synthesizeEntity(uint256 tokenId1, uint256 tokenId2)`: A creative function that simulates combining two entities. Could consume the parent entities and create a new one with properties derived from them, costing energy. (Conceptual/Advanced) - *Implementation: Consumes energy, generates new ID, properties derived simply.*
19. `fragmentEntity(uint256 tokenId)`: A creative function that simulates breaking down an entity. Burns the entity and potentially refunds some energy based on its entropy level. (Conceptual/Advanced)
20. `attuneToOracle(uint256 tokenId, bytes32 oracleValue)`: Allows an Entity owner to provide a value (simulating an oracle feed) that influences the Entity's alignment or other properties based on the value. Guardian can set a required oracle address, although the verification is simplified here. (Conceptual/Advanced)
21. `batchUpdateEntropy(uint256[] calldata tokenIds)`: Allows updating the entropy for a list of entities in a single transaction.
22. `queryRealmEnergy()`: Returns the current energy level of the Realm. (View)
23. `setResonanceThreshold(uint256 newThreshold)`: Allows the guardian to set the Realm's global resonance threshold.
24. `setEntropyDecayRate(uint256 newRate)`: Allows the guardian to set the Realm's global entropy decay rate.
25. `setGuardian(address newGuardian)`: Allows the owner to change the guardian address.
26. `setOracleAddress(address newOracle)`: Allows the guardian to set the address of the conceptual oracle source.
27. `getEntityCount()`: Returns the total number of registered entities. (View)
28. `isEntityRegistered(uint256 tokenId)`: Checks if an entity ID is currently registered and active. (View)
29. `getEntityOwner(uint256 tokenId)`: Returns the owner of a specific entity. (View)
30. `checkResonanceHarmony(uint256 tokenId)`: Pure function to check if an entity's resonance is currently close to the threshold without state change. (Pure)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// QuantumRealmRegistry Smart Contract

// Outline:
// 1. Contract Definition: Basic structure, license, pragma.
// 2. Roles & Access Control: Define roles (owner, guardian) and custom modifiers.
// 3. Enums: Define possible states for Entity properties (e.g., Alignment).
// 4. Structs: Define the Entity data structure.
// 5. State Variables: Mappings for entity data, ownership, realm parameters, energy pool.
// 6. Events: Announce key actions and state changes.
// 7. Constructor: Initialize roles and basic parameters.
// 8. Modifiers: Custom access control logic.
// 9. Internal Helpers: Functions used internally.
// 10. Entity Management Functions (ERC721-like but custom): Register, transfer, get details.
// 11. Dynamic State Functions: Update Entity properties (Alignment, Resonance, Entropy).
// 12. Relationship Functions: Link and unlink Entities.
// 13. Realm Interaction Functions: Transfer energy, claim energy, affect realm state.
// 14. Advanced / Creative Functions: Synthesis, fragmentation, attunement, batch operations, conditional actions.
// 15. View Functions: Read-only access to state.

// Function Summary:
// 1. constructor(): Initializes the contract owner and guardian address.
// 2. registerEntity(address initialOwner, uint256 initialResonance, Alignment initialAlignment): Creates a new Entity. (Payable)
// 3. transferEntityOwnership(uint256 tokenId, address newOwner): Transfers ownership of an Entity.
// 4. approveEntityTransfer(address approved, uint256 tokenId): Approves an address to transfer a specific Entity.
// 5. getApproved(uint256 tokenId): Returns the approved address for an Entity. (View)
// 6. getEntityDetails(uint256 tokenId): Returns all current properties of an Entity. (View)
// 7. updateEntityAlignment(uint256 tokenId, Alignment newAlignment): Changes an Entity's alignment.
// 8. updateEntityResonance(uint256 tokenId, uint256 newFrequency): Changes an Entity's resonance frequency.
// 9. anchorEntity(uint256 tokenId): Sets an Entity's isAnchored state to true.
// 10. unanchorEntity(uint256 tokenId): Sets an Entity's isAnchored state to false.
// 11. triggerEntropyDecay(uint256 tokenId): Calculates and updates an Entity's entropy based on time.
// 12. applyResonanceHarmonization(uint256 tokenId): Applies an effect based on resonance harmony.
// 13. linkEntities(uint256 tokenId1, uint256 tokenId2): Creates a bidirectional link.
// 14. unlinkEntities(uint256 tokenId1, uint256 tokenId2): Removes a bidirectional link.
// 15. getLinkedEntities(uint256 tokenId): Returns linked entities. (View)
// 16. transferEnergyToRealm(): Allows anyone to send ETH to the contract (increases Realm energy). (Payable)
// 17. claimEnergyFromRealm(uint256 tokenId): Allows an entity owner to claim realm energy based on entity state.
// 18. synthesizeEntity(uint256 tokenId1, uint256 tokenId2): Combines two entities conceptually (burns parents, creates new).
// 19. fragmentEntity(uint256 tokenId): Breaks down an entity conceptually (burns entity, potentially refunds energy).
// 20. attuneToOracle(uint256 tokenId, bytes32 oracleValue): Influences entity state based on a simulated oracle value.
// 21. batchUpdateEntropy(uint256[] calldata tokenIds): Updates entropy for multiple entities.
// 22. queryRealmEnergy(): Returns current realm energy. (View)
// 23. setResonanceThreshold(uint256 newThreshold): Sets the realm's global resonance threshold (Guardian).
// 24. setEntropyDecayRate(uint256 newRate): Sets the realm's global entropy decay rate (Guardian).
// 25. setGuardian(address newGuardian): Changes the guardian address (Owner).
// 26. setOracleAddress(address newOracle): Sets the conceptual oracle address (Guardian).
// 27. getEntityCount(): Returns total entities. (View)
// 28. isEntityRegistered(uint256 tokenId): Checks if an entity is active. (View)
// 29. getEntityOwner(uint256 tokenId): Returns entity owner. (View)
// 30. checkResonanceHarmony(uint256 tokenId): Checks resonance harmony condition. (Pure)

contract QuantumRealmRegistry {

    address private immutable i_owner;
    address private s_guardian; // Guardian role for realm parameters
    address private s_oracleAddress; // Conceptual oracle address

    uint256 private s_nextTokenId;
    uint256 private s_entityCount;

    uint256 public s_realmEnergy; // Represents a shared resource (ETH balance)

    // Realm Parameters
    uint256 public s_resonanceThreshold = 500; // Default threshold
    uint256 public s_entropyDecayRate = 1 days; // Time period for entropy decay calculation

    // Entity Properties
    enum Alignment { Neutral, Ordered, Chaotic, Harmonious }

    struct Entity {
        address owner;
        uint66 registrationTime; // uint66 to potentially store more time than uint32
        Alignment alignment;
        uint256 resonanceFrequency;
        uint256 entropyLevel; // 0-100, represents instability
        bool isAnchored;
        bytes32 metadataHash; // Link to off-chain data
        bool isActive; // To handle 'burned' entities
    }

    // State Mappings
    mapping(uint256 => Entity) private s_entities;
    mapping(uint256 => address) private s_entityApprovals; // ERC721-like approval
    mapping(uint256 => uint256[]) private s_linkedEntities; // Bidirectional linking
    mapping(uint256 => uint64) private s_lastEntropyUpdateTime; // Timestamp for entropy decay

    // Events
    event EntityRegistered(uint256 indexed tokenId, address indexed owner, uint256 initialResonance, Alignment initialAlignment);
    event EntityTransfer(uint256 indexed tokenId, address indexed from, address indexed to);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event AlignmentChanged(uint256 indexed tokenId, Alignment oldAlignment, Alignment newAlignment);
    event ResonanceChanged(uint256 indexed tokenId, uint256 oldFrequency, uint256 newFrequency);
    event EntropyUpdated(uint256 indexed tokenId, uint224 oldEntropy, uint224 newEntropy); // using uint224 to avoid overflow with 100 max
    event AnchoredStatusChanged(uint256 indexed tokenId, bool isAnchored);
    event EntitiesLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntitiesUnlinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EnergyTransferredToRealm(address indexed from, uint256 amount);
    event EnergyClaimedFromRealm(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ResonanceHarmonizationApplied(uint256 indexed tokenId, uint256 energyConsumed);
    event EntitySynthesized(uint256 indexed parent1, uint256 indexed parent2, uint256 indexed newEntityId);
    event EntityFragmented(uint256 indexed tokenId, uint256 energyRefunded);
    event OracleAttuned(uint256 indexed tokenId, bytes32 oracleValue, Alignment resultingAlignment);
    event GuardianSet(address indexed oldGuardian, address indexed newGuardian);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event ResonanceThresholdSet(uint256 oldThreshold, uint256 newThreshold);
    event EntropyDecayRateSet(uint256 oldRate, uint256 newRate);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not contract owner");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == s_guardian, "Not guardian");
        _;
    }

    modifier onlyEntityOwner(uint256 _tokenId) {
        require(s_entities[_tokenId].isActive, "Entity does not exist");
        require(s_entities[_tokenId].owner == msg.sender, "Not entity owner");
        _;
    }

    modifier onlyEntityOwnerOrApproved(uint256 _tokenId) {
        require(s_entities[_tokenId].isActive, "Entity does not exist");
        require(s_entities[_tokenId].owner == msg.sender || s_entityApprovals[_tokenId] == msg.sender, "Not entity owner or approved");
        _;
    }

    modifier entityExists(uint256 _tokenId) {
        require(s_entities[_tokenId].isActive, "Entity does not exist");
        _;
    }

    // Constructor
    constructor(address initialGuardian) payable {
        i_owner = msg.sender;
        s_guardian = initialGuardian;
        s_realmEnergy = msg.value; // Initialize realm energy with any initial ETH sent
    }

    // Internal Helpers

    function _updateEntropy(uint256 _tokenId) internal {
        Entity storage entity = s_entities[_tokenId];
        require(entity.isActive, "Entity does not exist"); // Should be guaranteed by callers but defensive

        uint64 lastUpdate = s_lastEntropyUpdateTime[_tokenId];
        uint64 currentTime = uint64(block.timestamp);

        // Prevent update if rate is 0 or no time has passed since last manual update (for precision)
        if (s_entropyDecayRate == 0 || currentTime <= lastUpdate) {
             s_lastEntropyUpdateTime[_tokenId] = currentTime; // Record last update even if no decay occurred
             return;
        }

        // Calculate time elapsed since last update, capped by decay rate interval for simplicity
        uint256 timeElapsed = currentTime - lastUpdate;
        uint256 decayTicks = timeElapsed / s_entropyDecayRate; // How many decay periods have passed

        if (decayTicks > 0) {
            uint224 oldEntropy = uint224(entity.entropyLevel);
            // Simple decay model: Entropy increases by 1 per decay tick, capped at 100
            entity.entropyLevel = min(entity.entropyLevel + decayTicks, 100); // Cap entropy at 100
            s_lastEntropyUpdateTime[_tokenId] = currentTime; // Update last update time

            if (uint224(entity.entropyLevel) != oldEntropy) {
                 emit EntropyUpdated(_tokenId, oldEntropy, uint224(entity.entropyLevel));
            }
        }
    }

    function _addLink(uint256 _tokenId1, uint256 _tokenId2) internal {
        // Check if link already exists (simple check on one side)
        for (uint i = 0; i < s_linkedEntities[_tokenId1].length; i++) {
            if (s_linkedEntities[_tokenId1][i] == _tokenId2) {
                return; // Link already exists
            }
        }
        s_linkedEntities[_tokenId1].push(_tokenId2);
        s_linkedEntities[_tokenId2].push(_tokenId1); // Bidirectional
        emit EntitiesLinked(_tokenId1, _tokenId2);
    }

    function _removeLink(uint256 _tokenId1, uint256 _tokenId2) internal {
        // Remove link from token1's list
        for (uint i = 0; i < s_linkedEntities[_tokenId1].length; i++) {
            if (s_linkedEntities[_tokenId1][i] == _tokenId2) {
                s_linkedEntities[_tokenId1][i] = s_linkedEntities[_tokenId1][s_linkedEntities[_tokenId1].length - 1];
                s_linkedEntities[_tokenId1].pop();
                break; // Assuming no duplicate links
            }
        }
        // Remove link from token2's list
        for (uint i = 0; i < s_linkedEntities[_tokenId2].length; i++) {
            if (s_linkedEntities[_tokenId2][i] == _tokenId1) {
                s_linkedEntities[_tokenId2][i] = s_linkedEntities[_tokenId2][s_linkedEntities[_tokenId2].length - 1];
                s_linkedEntities[_tokenId2].pop();
                break; // Assuming no duplicate links
            }
        }
        emit EntitiesUnlinked(_tokenId1, _tokenId2);
    }

    function _burnEntity(uint256 _tokenId) internal {
        Entity storage entity = s_entities[_tokenId];
        require(entity.isActive, "Entity does not exist");

        entity.isActive = false; // Mark as inactive/burned
        s_entityCount--;
        // Clear mappings associated with the entity ID for gas efficiency on future calls
        delete s_entities[_tokenId].owner; // Clear sensitive data
        delete s_entityApprovals[_tokenId]; // Clear approval
        // Note: Linked entities will still show the burned ID in their lists until manually unlinked.
        // A more robust system would iterate and remove links here, but that's gas-intensive.
        // For this example, checking isActive in getLinkedEntities is simpler.
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // 10. Entity Management Functions

    /// @notice Registers a new Entity in the Quantum Realm.
    /// @param initialOwner The address that will own the new Entity.
    /// @param initialResonance The initial resonance frequency of the Entity.
    /// @param initialAlignment The initial alignment of the Entity.
    /// @return The unique identifier (tokenId) of the newly registered Entity.
    /// @dev Requires sending ETH to contribute energy to the Realm.
    function registerEntity(
        address initialOwner,
        uint256 initialResonance,
        Alignment initialAlignment
    ) external payable returns (uint256) {
        require(msg.value > 0, "Must send energy to register entity"); // Require minimum energy contribution

        uint256 newTokenId = s_nextTokenId++;
        s_entityCount++;

        s_entities[newTokenId] = Entity({
            owner: initialOwner,
            registrationTime: uint66(block.timestamp),
            alignment: initialAlignment,
            resonanceFrequency: initialResonance,
            entropyLevel: 0, // Start with low entropy
            isAnchored: false,
            metadataHash: bytes32(0), // Placeholder
            isActive: true
        });

        s_lastEntropyUpdateTime[newTokenId] = uint64(block.timestamp);
        s_realmEnergy += msg.value; // Add received ETH to realm energy

        emit EntityRegistered(newTokenId, initialOwner, initialResonance, initialAlignment);
        return newTokenId;
    }

    /// @notice Transfers ownership of an Entity.
    /// @param tokenId The ID of the Entity to transfer.
    /// @param newOwner The address to transfer ownership to.
    /// @dev Follows ERC721-like transfer logic (requires owner or approved).
    function transferEntityOwnership(uint256 tokenId, address newOwner)
        external
        onlyEntityOwnerOrApproved(tokenId)
    {
        address oldOwner = s_entities[tokenId].owner;
        require(oldOwner != address(0), "Entity not valid"); // Should be caught by modifier, but double check
        require(newOwner != address(0), "Transfer to the zero address is forbidden");

        s_entityApprovals[tokenId] = address(0); // Clear approval on transfer
        s_entities[tokenId].owner = newOwner;

        emit EntityTransfer(tokenId, oldOwner, newOwner);
    }

    /// @notice Approves an address to manage a specific Entity.
    /// @param approved The address to grant approval to.
    /// @param tokenId The ID of the Entity to approve.
    /// @dev ERC721-like approval mechanism.
    function approveEntityTransfer(address approved, uint256 tokenId)
        external
        onlyEntityOwner(tokenId)
    {
        s_entityApprovals[tokenId] = approved;
        emit Approval(msg.sender, approved, tokenId);
    }

    /// @notice Gets the approved address for a specific Entity.
    /// @param tokenId The ID of the Entity.
    /// @return The address approved for the Entity, or address(0) if none.
    function getApproved(uint256 tokenId) public view entityExists(tokenId) returns (address) {
        return s_entityApprovals[tokenId];
    }

    /// @notice Retrieves all details for a specific Entity.
    /// @param tokenId The ID of the Entity.
    /// @return The Entity struct containing all its properties.
    function getEntityDetails(uint256 tokenId)
        public
        view
        entityExists(tokenId)
        returns (Entity memory)
    {
        return s_entities[tokenId];
    }

    // 11. Dynamic State Functions

    /// @notice Updates the alignment of an Entity.
    /// @param tokenId The ID of the Entity.
    /// @param newAlignment The new alignment value.
    function updateEntityAlignment(uint256 tokenId, Alignment newAlignment)
        external
        onlyEntityOwnerOrApproved(tokenId)
        entityExists(tokenId)
    {
        Alignment oldAlignment = s_entities[tokenId].alignment;
        if (oldAlignment != newAlignment) {
            s_entities[tokenId].alignment = newAlignment;
            emit AlignmentChanged(tokenId, oldAlignment, newAlignment);
        }
    }

    /// @notice Updates the resonance frequency of an Entity.
    /// @param tokenId The ID of the Entity.
    /// @param newFrequency The new resonance frequency.
    function updateEntityResonance(uint256 tokenId, uint256 newFrequency)
        external
        onlyEntityOwnerOrApproved(tokenId)
        entityExists(tokenId)
    {
        uint256 oldFrequency = s_entities[tokenId].resonanceFrequency;
        if (oldFrequency != newFrequency) {
            s_entities[tokenId].resonanceFrequency = newFrequency;
            emit ResonanceChanged(tokenId, oldFrequency, newFrequency);
        }
    }

    /// @notice Anchors an Entity, making it less susceptible to certain external forces.
    /// @param tokenId The ID of the Entity.
    function anchorEntity(uint256 tokenId)
        external
        onlyEntityOwnerOrApproved(tokenId)
        entityExists(tokenId)
    {
        if (!s_entities[tokenId].isAnchored) {
            s_entities[tokenId].isAnchored = true;
            emit AnchoredStatusChanged(tokenId, true);
        }
    }

    /// @notice Unanchors an Entity, making it mobile or more susceptible.
    /// @param tokenId The ID of the Entity.
    function unanchorEntity(uint256 tokenId)
        external
        onlyEntityOwnerOrApproved(tokenId)
        entityExists(tokenId)
    {
        if (s_entities[tokenId].isAnchored) {
            s_entities[tokenId].isAnchored = false;
            emit AnchoredStatusChanged(tokenId, false);
        }
    }

    /// @notice Triggers the calculation and update of an Entity's entropy level based on time.
    /// @param tokenId The ID of the Entity.
    /// @dev Can be called by anyone to help maintain entity state.
    function triggerEntropyDecay(uint256 tokenId) external entityExists(tokenId) {
        _updateEntropy(tokenId);
        // Event is emitted inside _updateEntropy if state changes
    }

    /// @notice Applies a beneficial effect if an Entity's resonance is close to the Realm's threshold.
    /// @param tokenId The ID of the Entity.
    /// @dev This action consumes Realm energy. Reduces entropy if criteria met.
    function applyResonanceHarmonization(uint256 tokenId)
        external
        entityExists(tokenId)
    {
        require(s_realmEnergy > 0, "Realm energy is depleted");
        // Simulate cost
        uint256 cost = 1 ether; // Example cost
        require(s_realmEnergy >= cost, "Insufficient Realm energy for harmonization");

        _updateEntropy(tokenId); // Update entropy first

        // Check for resonance harmony (example: within +/- 10% of threshold)
        bool isHarmonious = checkResonanceHarmony(tokenId); // Uses the pure check function

        if (isHarmonious) {
            // Apply beneficial effect: Reduce entropy significantly
            s_entities[tokenId].entropyLevel = s_entities[tokenId].entropyLevel > 20 ? s_entities[tokenId].entropyLevel - 20 : 0;
            emit EntropyUpdated(tokenId, uint224(s_entities[tokenId].entropyLevel + 20), uint224(s_entities[tokenId].entropyLevel)); // Emit old/new
            s_realmEnergy -= cost; // Consume energy
            emit ResonanceHarmonizationApplied(tokenId, cost);
        } else {
            // Small penalty or nothing? For now, just fail the effect if not harmonious.
            // require(false, "Entity resonance is not harmonious"); // Could add a revert or just no effect. Let's just have no effect/event if not harmonious.
        }
    }


    // 12. Relationship Functions

    /// @notice Creates a bidirectional link between two Entities.
    /// @param tokenId1 The ID of the first Entity.
    /// @param tokenId2 The ID of the second Entity.
    /// @dev Requires the caller to own both entities. Cannot link an entity to itself.
    function linkEntities(uint256 tokenId1, uint256 tokenId2) external {
        require(tokenId1 != tokenId2, "Cannot link entity to itself");
        entityExists(tokenId1); // Check existence with modifier
        entityExists(tokenId2); // Check existence with modifier
        require(s_entities[tokenId1].owner == msg.sender && s_entities[tokenId2].owner == msg.sender, "Must own both entities to link");

        _addLink(tokenId1, tokenId2); // Handles bidirectional add and checks for existing
    }

    /// @notice Removes a bidirectional link between two Entities.
    /// @param tokenId1 The ID of the first Entity.
    /// @param tokenId2 The ID of the second Entity.
    /// @dev Requires the caller to own both entities.
    function unlinkEntities(uint256 tokenId1, uint256 tokenId2) external {
        require(tokenId1 != tokenId2, "Invalid unlink request");
        entityExists(tokenId1); // Check existence with modifier
        entityExists(tokenId2); // Check existence with modifier
        require(s_entities[tokenId1].owner == msg.sender && s_entities[tokenId2].owner == msg.sender, "Must own both entities to unlink");

        _removeLink(tokenId1, tokenId2); // Handles bidirectional removal
    }

    /// @notice Gets the list of Entities linked to a specific one.
    /// @param tokenId The ID of the Entity.
    /// @return An array of Entity IDs linked to the specified Entity.
    /// @dev Note: May include IDs of fragmented/burned entities if not manually unlinked.
    function getLinkedEntities(uint256 tokenId)
        public
        view
        entityExists(tokenId)
        returns (uint256[] memory)
    {
        uint256[] memory rawLinks = s_linkedEntities[tokenId];
        uint256 activeCount = 0;
        // Count only active links
        for (uint i = 0; i < rawLinks.length; i++) {
            if (s_entities[rawLinks[i]].isActive) {
                activeCount++;
            }
        }

        uint256[] memory activeLinks = new uint256[](activeCount);
        uint256 currentIndex = 0;
         for (uint i = 0; i < rawLinks.length; i++) {
            if (s_entities[rawLinks[i]].isActive) {
                activeLinks[currentIndex] = rawLinks[i];
                currentIndex++;
            }
        }

        return activeLinks;
    }

    // 13. Realm Interaction Functions

    /// @notice Allows anyone to transfer ETH to the contract, increasing the Realm's energy pool.
    function transferEnergyToRealm() external payable {
        require(msg.value > 0, "Must send ETH to contribute energy");
        s_realmEnergy += msg.value;
        emit EnergyTransferredToRealm(msg.sender, msg.value);
    }

    /// @notice Allows an entity owner to claim energy from the Realm.
    /// @param tokenId The ID of the Entity whose state influences the claim.
    /// @dev The amount claimable could be based on entity state (e.g., low entropy, high resonance).
    /// In this example, a fixed amount is claimable, with a cooldown or condition.
    function claimEnergyFromRealm(uint256 tokenId)
        external
        onlyEntityOwner(tokenId)
        entityExists(tokenId)
    {
        // Example logic: Can only claim if entropy is below 10 and resonance is high
        _updateEntropy(tokenId); // Update entropy before checking
        Entity storage entity = s_entities[tokenId];

        require(entity.entropyLevel < 10, "Entity entropy too high to claim");
        require(entity.resonanceFrequency > 800, "Entity resonance too low to claim");
        // Add a cooldown mechanism to prevent spamming claims - Example using timestamp
        // uint64 lastClaimTime = s_lastClaimTime[tokenId]; // Need a mapping for this
        // require(block.timestamp > lastClaimTime + 1 hours, "Claim cooldown active");

        uint256 claimAmount = 0.01 ether; // Example fixed claim amount
        require(s_realmEnergy >= claimAmount, "Insufficient Realm energy to claim");

        s_realmEnergy -= claimAmount;

        // Using transfer is simplest, consider call/send for robustness in real dapps
        (bool success, ) = payable(msg.sender).transfer(claimAmount);
        require(success, "Energy claim failed");

        // s_lastClaimTime[tokenId] = uint64(block.timestamp); // Update cooldown
        emit EnergyClaimedFromRealm(tokenId, msg.sender, claimAmount);
    }

    // 14. Advanced / Creative Functions

    /// @notice Simulates the synthesis of two entities into a new one.
    /// @param tokenId1 The ID of the first parent Entity.
    /// @param tokenId2 The ID of the second parent Entity.
    /// @dev Consumes both parent entities and creates a new one. Properties are derived simply. Requires Realm energy.
    function synthesizeEntity(uint256 tokenId1, uint256 tokenId2) external {
        require(tokenId1 != tokenId2, "Cannot synthesize an entity with itself");
        entityExists(tokenId1);
        entityExists(tokenId2);
        require(s_entities[tokenId1].owner == msg.sender && s_entities[tokenId2].owner == msg.sender, "Must own both entities to synthesize");

        uint256 synthesisCost = 0.05 ether; // Example cost
        require(s_realmEnergy >= synthesisCost, "Insufficient Realm energy for synthesis");

        // Burn parent entities
        _burnEntity(tokenId1);
        _burnEntity(tokenId2);

        s_realmEnergy -= synthesisCost; // Consume energy

        // Create new entity - simplified property derivation
        uint256 newTokenId = s_nextTokenId++;
         s_entityCount++;

        // Derive properties (example: average resonance, specific alignment rule)
        uint256 newResonance = (s_entities[tokenId1].resonanceFrequency + s_entities[tokenId2].resonanceFrequency) / 2;
        Alignment newAlignment;
        if (s_entities[tokenId1].alignment == Alignment.Harmonious || s_entities[tokenId2].alignment == Alignment.Harmonious) {
            newAlignment = Alignment.Harmonious;
        } else if (s_entities[tokenId1].alignment != s_entities[tokenId2].alignment) {
            newAlignment = Alignment.Chaotic; // Different alignments yield chaotic
        } else {
            newAlignment = s_entities[tokenId1].alignment; // Same alignments maintain alignment
        }

        s_entities[newTokenId] = Entity({
            owner: msg.sender, // New entity owned by synthesizer
            registrationTime: uint66(block.timestamp),
            alignment: newAlignment,
            resonanceFrequency: newResonance,
            entropyLevel: 20, // Start with some entropy
            isAnchored: false,
            metadataHash: bytes32(0), // Placeholder
            isActive: true
        });

        s_lastEntropyUpdateTime[newTokenId] = uint64(block.timestamp);

        emit EntitySynthesized(tokenId1, tokenId2, newTokenId);
        emit EntityRegistered(newTokenId, msg.sender, newResonance, newAlignment); // Also emit registration event for the new one
    }

    /// @notice Simulates the fragmentation of an entity.
    /// @param tokenId The ID of the Entity to fragment.
    /// @dev Burns the entity and potentially refunds some Realm energy based on its state (e.g., low entropy = higher refund).
    function fragmentEntity(uint256 tokenId) external onlyEntityOwner(tokenId) entityExists(tokenId) {
        _updateEntropy(tokenId); // Final entropy update before fragmentation
        Entity storage entity = s_entities[tokenId];

        uint256 refundAmount = 0;
        if (entity.entropyLevel < 50) {
            // Refund more for less unstable entities
            refundAmount = (100 - entity.entropyLevel) * 1 ether / 200; // Max 0.5 ether refund for entropy 0
        }

        _burnEntity(tokenId); // Mark as inactive/burned

        if (refundAmount > 0) {
            require(s_realmEnergy >= refundAmount, "Insufficient Realm energy for fragmentation refund");
             s_realmEnergy -= refundAmount;
            (bool success, ) = payable(msg.sender).transfer(refundAmount);
            require(success, "Fragmentation refund failed");
        }

        emit EntityFragmented(tokenId, refundAmount);
    }

    /// @notice Allows attuning an Entity to a simulated oracle value.
    /// @param tokenId The ID of the Entity.
    /// @param oracleValue A simulated value from an oracle.
    /// @dev Changes entity state (e.g., alignment) based on the oracle value and entity properties. Requires oracle address to be set.
    function attuneToOracle(uint256 tokenId, bytes32 oracleValue) external onlyEntityOwnerOrApproved(tokenId) entityExists(tokenId) {
        require(s_oracleAddress != address(0), "Oracle address not set");
        // In a real scenario, you'd verify the oracle signature/proof here
        // For this example, we trust the caller provides a valid value
        // require(msg.sender == s_oracleAddress, "Call must come from the oracle address"); // More realistic check

        Entity storage entity = s_entities[tokenId];

        // Example logic: Oracle value influences alignment based on resonance
        uint256 valueUint = uint256(oracleValue); // Treat hash as a large uint

        Alignment oldAlignment = entity.alignment;
        Alignment newAlignment = oldAlignment;

        if (valueUint % 100 < 50 && entity.resonanceFrequency < s_resonanceThreshold) {
            newAlignment = Alignment.Ordered;
        } else if (valueUint % 100 >= 50 && entity.resonanceFrequency > s_resonanceThreshold) {
             newAlignment = Alignment.Chaotic;
        } else if (valueUint % 10 == 0 && entity.alignment != Alignment.Harmonious) {
             newAlignment = Alignment.Neutral;
        } // else maintain current alignment

        if (newAlignment != oldAlignment) {
            entity.alignment = newAlignment;
             emit OracleAttuned(tokenId, oracleValue, newAlignment);
             emit AlignmentChanged(tokenId, oldAlignment, newAlignment); // Also emit generic alignment change
        } else {
             // Optionally emit an event if attunement happened but state didn't change
             emit OracleAttuned(tokenId, oracleValue, newAlignment);
        }
    }

    /// @notice Updates the entropy level for a list of Entities in a single transaction.
    /// @param tokenIds An array of Entity IDs to update.
    /// @dev Useful for maintaining state for multiple entities efficiently. Gas costs will scale with array size.
    function batchUpdateEntropy(uint256[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            // Check if entity exists within the loop, but continue if one fails
            if (s_entities[tokenIds[i]].isActive) {
                 _updateEntropy(tokenIds[i]);
                 // Event emitted inside _updateEntropy
            }
        }
    }

    // 15. View Functions

    /// @notice Returns the current energy level of the Quantum Realm.
    /// @return The amount of ETH currently held by the contract.
    function queryRealmEnergy() external view returns (uint256) {
        return address(this).balance; // Reflects actual ETH balance
    }

    /// @notice Sets the global resonance threshold for the Realm.
    /// @param newThreshold The new threshold value.
    function setResonanceThreshold(uint256 newThreshold) external onlyGuardian {
        uint256 oldThreshold = s_resonanceThreshold;
        s_resonanceThreshold = newThreshold;
        emit ResonanceThresholdSet(oldThreshold, newThreshold);
    }

    /// @notice Sets the rate at which Entity entropy decays (time period between ticks).
    /// @param newRate The new decay rate in seconds.
    function setEntropyDecayRate(uint256 newRate) external onlyGuardian {
        uint256 oldRate = s_entropyDecayRate;
        s_entropyDecayRate = newRate;
         emit EntropyDecayRateSet(oldRate, newRate);
    }

    /// @notice Sets the guardian address.
    /// @param newGuardian The address to set as the new guardian.
    function setGuardian(address newGuardian) external onlyOwner {
        require(newGuardian != address(0), "New guardian cannot be the zero address");
        address oldGuardian = s_guardian;
        s_guardian = newGuardian;
        emit GuardianSet(oldGuardian, newGuardian);
    }

    /// @notice Sets the conceptual oracle address.
    /// @param newOracle The address of the conceptual oracle.
    function setOracleAddress(address newOracle) external onlyGuardian {
        require(newOracle != address(0), "Oracle address cannot be the zero address");
        address oldOracle = s_oracleAddress;
        s_oracleAddress = newOracle;
        emit OracleAddressSet(oldOracle, newOracle);
    }

    /// @notice Returns the total number of active Entities registered.
    /// @return The count of active entities.
    function getEntityCount() external view returns (uint256) {
        return s_entityCount;
    }

    /// @notice Checks if an Entity with a specific ID is currently registered and active.
    /// @param tokenId The ID to check.
    /// @return True if the entity exists and is active, false otherwise.
    function isEntityRegistered(uint256 tokenId) external view returns (bool) {
        return s_entities[tokenId].isActive;
    }

    /// @notice Returns the owner of a specific Entity.
    /// @param tokenId The ID of the Entity.
    /// @return The address of the Entity's owner. Returns address(0) if not active.
    function getEntityOwner(uint256 tokenId) external view returns (address) {
        if (!s_entities[tokenId].isActive) {
            return address(0);
        }
        return s_entities[tokenId].owner;
    }

    /// @notice Checks if an Entity's resonance frequency is close to the Realm's threshold.
    /// @param tokenId The ID of the Entity.
    /// @return True if the entity's resonance is considered harmonious with the realm threshold.
    /// @dev This is a pure check based on current state, no side effects. Example logic: within 10% range.
    function checkResonanceHarmony(uint256 tokenId) public view entityExists(tokenId) returns (bool) {
        uint256 resonance = s_entities[tokenId].resonanceFrequency;
        // Check if resonance is within +/- 10% of threshold (avoid division by zero)
        if (s_resonanceThreshold == 0) return resonance == 0; // If threshold is 0, only resonance 0 is harmonious
        uint256 lowerBound = s_resonanceThreshold * 90 / 100; // 90% of threshold
        uint256 upperBound = s_resonanceThreshold * 110 / 100; // 110% of threshold
        return resonance >= lowerBound && resonance <= upperBound;
    }

    // Fallback function to receive ETH for realm energy
    receive() external payable {
        transferEnergyToRealm();
    }

    // Pay attention to potential reentrancy if adding external calls in claimEnergyFromRealm or similar.
    // For this example, direct transfers are used, which mitigate *some* reentrancy risks compared to .call{value: amount}("").
    // A more robust system might use a withdraw pattern.

    // The 'oracleValue' in `attuneToOracle` is a simplified representation.
    // A real system would integrate with Chainlink or a custom oracle with proper verification (signatures, request/response patterns).

    // Entity linking does not automatically clean up links when an entity is burned.
    // The `getLinkedEntities` function filters for active entities, but the mapping still holds old IDs.
    // A cleanup function could be added, but would be gas-intensive.
}
```