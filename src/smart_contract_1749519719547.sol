Okay, let's design a smart contract that's a bit more complex and involves dynamic state and user interaction beyond simple token transfers. We'll create a system for "Procedural On-Chain Artifacts" that can evolve, decay, and be influenced by user actions and potentially time or external factors (simulated decay in this case).

It will combine elements of NFTs (the artifacts themselves), dynamic properties stored on-chain, crafting, maintenance, and simple state evolution.

Here's the outline and function summary, followed by the Solidity code.

---

## ChronoForge Artifacts Contract

**Description:**
This contract implements a system for crafting, managing, and interacting with unique, dynamic on-chain artifacts. Artifacts are represented as ERC-721 tokens with properties (like durability, power, charm) stored directly in the contract state. These properties can change over time or based on user interactions, introducing concepts of decay, growth, mutation, and maintenance. Users craft artifacts using consumable components (simulated here as balances tracked internally).

**Inheritance:**
*   `ERC721` (from OpenZeppelin): Provides standard NFT functionality (ownership, transfers, approvals).
*   `Ownable` (from OpenZeppelin): Provides a simple owner mechanism for administrative functions.
*   `Pausable` (from OpenZeppelin): Allows pausing core user interactions.

**Events:**
*   `ArtifactCrafted`: Emitted when a new artifact is successfully crafted.
*   `ArtifactRepaired`: Emitted when an artifact's durability is restored.
*   `ArtifactMutated`: Emitted when an artifact's properties are mutated.
*   `ArtifactAttuned`: Emitted when an artifact is attuned to an address.
*   `ArtifactUnattuned`: Emitted when an artifact is unattuned.
*   `ArtifactDismantled`: Emitted when an artifact is burned.
*   `EssenceTypeCreated`: Emitted when a new type of Essence component is defined.
*   `EssenceMinted`: Emitted when Essence components are minted.
*   `EssenceBurned`: Emitted when Essence components are burned.
*   `CatalystTypeCreated`: Emitted when a new type of Catalyst component is defined.
*   `CatalystMinted`: Emitted when Catalyst components are minted.
*   `CatalystBurned`: Emitted when Catalyst components are burned.
*   `ConfigUpdated`: Emitted when key contract parameters are changed.

**Structs:**
*   `Artifact`: Defines the properties of an artifact token (ID, type IDs, timestamps, dynamic stats, etc.).
*   `EssenceType`: Defines a type of Essence component (ID, name, crafting modifiers).
*   `CatalystType`: Defines a type of Catalyst component (ID, name, crafting modifiers, decay/mutation effects).

**State Variables:**
*   `_artifactTokenCounter`: Counter for unique artifact IDs.
*   `_essenceTypeCounter`: Counter for unique Essence type IDs.
*   `_catalystTypeCounter`: Counter for unique Catalyst type IDs.
*   `_artifactData`: Mapping from artifact ID to its `Artifact` struct.
*   `_essenceTypes`: Mapping from Essence type ID to its `EssenceType` struct.
*   `_essenceBalances`: Mapping from user address to Essence type ID to balance.
*   `_catalystTypes`: Mapping from Catalyst type ID to its `CatalystType` struct.
*   `_catalystBalances`: Mapping from user address to Catalyst type ID to balance.
*   `decayRatePerSecond`: Global decay rate for artifact durability.
*   `growthRatePerInteraction`: Global growth rate for artifact stats upon interaction.
*   `mutationChancePercent`: Base chance for mutation upon interaction or repair.
*   `repairCostMultiplier`: Multiplier for repair costs based on durability loss.
*   `dismantleEssenceReturnPercent`: Percentage of crafting Essence returned on dismantle.

**Functions (>= 20 custom functions + ERC721 standard):**

*   **ERC721 Standard Functions (Provided by Inheritance):**
    1.  `balanceOf(address owner) view`: Returns the number of tokens owned by an address.
    2.  `ownerOf(uint256 tokenId) view`: Returns the owner of a specific token.
    3.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a token.
    4.  `getApproved(uint256 tokenId) view`: Returns the approved address for a token.
    5.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator for all tokens.
    6.  `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for all tokens of an owner.
    7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (less safe than safeTransferFrom).
    8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a token, checking if the recipient can receive NFTs.
    9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Overloaded safe transfer.

*   **Component Management (Admin/Internal):**
    10. `createEssenceType(string memory name, uint256 baseCraftingCost, uint32 basePowerBoost, uint32 baseCharmBoost) onlyOwner`: Creates a new type of Essence component.
    11. `mintEssence(address to, uint256 essenceTypeId, uint256 amount) onlyOwner`: Mints a specific amount of Essence components of a given type to an address.
    12. `burnEssence(address from, uint256 essenceTypeId, uint256 amount) internal`: Burns a specific amount of Essence components.
    13. `getEssenceBalance(address account, uint256 essenceTypeId) view`: Gets the balance of a specific Essence type for an address.
    14. `getEssenceTypeDetails(uint256 essenceTypeId) view`: Gets the details of an Essence type.
    15. `createCatalystType(string memory name, uint256 craftingModifier, uint8 mutationChanceModifier, uint32 durabilityBoost) onlyOwner`: Creates a new type of Catalyst component.
    16. `mintCatalyst(address to, uint256 catalystTypeId, uint256 amount) onlyOwner`: Mints a specific amount of Catalyst components of a given type to an address.
    17. `burnCatalyst(address from, uint256 catalystTypeId, uint256 amount) internal`: Burns a specific amount of Catalyst components.
    18. `getCatalystBalance(address account, uint256 catalystTypeId) view`: Gets the balance of a specific Catalyst type for an address.
    19. `getCatalystTypeDetails(uint256 catalystTypeId) view`: Gets the details of a Catalyst type.

*   **Artifact Creation & Management (User):**
    20. `craftArtifact(uint256 essenceTypeId, uint256 catalystTypeId)`: Crafts a new artifact using specified Essence and Catalyst components.
    21. `interactWithArtifact(uint256 artifactId) whenNotPaused`: Simulates interaction, updating time and potentially triggering growth/decay checks (decay applied implicitly on query).
    22. `repairArtifact(uint256 artifactId, uint256 essenceTypeId) whenNotPaused`: Repairs an artifact using Essence components, restoring durability based on cost.
    23. `attemptMutation(uint256 artifactId, uint256 catalystTypeId) whenNotPaused`: Attempts to mutate an artifact's properties using a Catalyst.
    24. `attuneArtifact(uint256 artifactId, address targetAddress) whenNotPaused`: Attunes an artifact to a specific address (must be owner of artifact).
    25. `unattuneArtifact(uint256 artifactId) whenNotPaused`: Removes attunement from an artifact.
    26. `dismantleArtifact(uint256 artifactId) whenNotPaused`: Burns an artifact, potentially returning some components.

*   **Artifact State & Query (User/Public):**
    27. `getArtifactDetails(uint256 artifactId) view`: Gets the raw stored details of an artifact.
    28. `calculateCurrentDurability(uint256 artifactId) view`: Calculates the current effective durability considering decay.
    29. `calculateCurrentPower(uint256 artifactId) view`: Calculates the current effective power considering decay/growth.
    30. `calculateCurrentCharm(uint256 artifactId) view`: Calculates the current effective charm considering decay/growth.
    31. `isArtifactCorrupted(uint256 artifactId) view`: Checks if an artifact's durability has dropped to zero.
    32. `getTokenURI(uint256 tokenId) pure override`: Placeholder for returning artifact metadata URI. (Standard ERC721, but often customized). *Self-correction: Need to implement this or mark as abstract/placeholder.* Let's make it a placeholder as dynamic URI generation is complex and often off-chain.

*   **Configuration (Admin):**
    33. `setDecayRate(uint256 ratePerSecond) onlyOwner`: Sets the global durability decay rate.
    34. `setGrowthRate(uint256 ratePerInteraction) onlyOwner`: Sets the global stat growth rate per interaction.
    35. `setMutationChance(uint8 percent) onlyOwner`: Sets the base mutation chance.
    36. `setRepairCostMultiplier(uint256 multiplier) onlyOwner`: Sets the multiplier for repair costs.
    37. `setDismantleEssenceReturnPercent(uint8 percent) onlyOwner`: Sets the percentage of Essence returned on dismantle.

*   **Pausable Functions (Admin):**
    38. `pause() onlyOwner whenNotPaused`: Pauses crafting and interaction functions.
    39. `unpause() onlyOwner whenPaused`: Unpauses crafting and interaction functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max

contract ChronoForgeArtifacts is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- Events ---
    event ArtifactCrafted(uint256 indexed artifactId, address indexed owner, uint256 essenceTypeId, uint256 catalystTypeId);
    event ArtifactRepaired(uint256 indexed artifactId, uint256 indexed essenceTypeId, uint32 durabilityRestored);
    event ArtifactMutated(uint256 indexed artifactId, uint256 indexed catalystTypeId, int32 powerChange, int32 charmChange, bool becameCorrupted);
    event ArtifactAttuned(uint256 indexed artifactId, address indexed toAddress);
    event ArtifactUnattuned(uint256 indexed artifactId);
    event ArtifactDismantled(uint256 indexed artifactId, address indexed owner);
    event EssenceTypeCreated(uint256 indexed essenceTypeId, string name);
    event EssenceMinted(address indexed to, uint256 indexed essenceTypeId, uint256 amount);
    event EssenceBurned(address indexed from, uint256 indexed essenceTypeId, uint256 amount);
    event CatalystTypeCreated(uint256 indexed catalystTypeId, string name);
    event CatalystMinted(address indexed to, uint256 indexed catalystTypeId, uint256 amount);
    event CatalystBurned(address indexed from, uint256 indexed catalystTypeId, uint256 amount);
    event ConfigUpdated(string key, uint256 value);


    // --- Structs ---
    struct Artifact {
        uint256 id;
        uint256 essenceTypeId;
        uint256 catalystTypeId;
        uint64 creationTime; // Timestamp of creation
        uint64 lastInteractionTime; // Timestamp of last user interaction (crafting, repair, mutation, explicit interact)
        uint32 durability; // Current durability (out of MAX_DURABILITY)
        uint32 power;      // Dynamic power stat
        uint32 charm;      // Dynamic charm stat
        uint8 generation;  // How many times it has been "mutated" significantly or evolved
        uint8 mutations;   // Count of attempted mutations
        address attunedTo; // Address this artifact is attuned to (could be user, contract, etc.)
        bool isCorrupted;  // Flag indicating if durability reached zero
    }

    struct EssenceType {
        uint256 id;
        string name;
        uint256 baseCraftingCost; // Amount of this essence needed to craft
        uint32 basePowerBoost;    // Initial power boost provided by this essence
        uint32 baseCharmBoost;    // Initial charm boost provided by this essence
    }

    struct CatalystType {
        uint256 id;
        string name;
        uint256 craftingModifier;       // Multiplier or bonus for crafting cost (e.g., 9000 for 90% cost)
        uint8 mutationChanceModifier;   // Bonus chance percentage for mutation
        uint32 durabilityBoost;        // Flat boost to initial durability
    }

    // --- State Variables ---
    Counters.Counter private _artifactTokenCounter;
    Counters.Counter private _essenceTypeCounter;
    Counters.Counter private _catalystTypeCounter;

    mapping(uint256 => Artifact) private _artifactData;
    mapping(uint256 => EssenceType) private _essenceTypes;
    mapping(address => mapping(uint256 => uint256)) private _essenceBalances; // owner => essenceTypeId => balance
    mapping(uint256 => CatalystType) private _catalystTypes;
    mapping(address => mapping(uint256 => uint256)) private _catalystBalances; // owner => catalystTypeId => balance

    // Configuration Parameters
    uint256 public decayRatePerSecond = 1;       // Durability points lost per second of inactivity
    uint256 public growthRatePerInteraction = 10; // Stat points gained per interaction (distributed between power/charm)
    uint8 public mutationChancePercent = 5;     // Base percentage chance (0-100)
    uint256 public repairCostMultiplier = 100;   // Essence cost = durability_loss * essence_base_cost / repairCostMultiplier
    uint8 public dismantleEssenceReturnPercent = 50; // Percentage of base crafting essence cost returned on dismantle

    // Constants
    uint32 public constant MAX_DURABILITY = 10000;
    uint32 public constant MAX_STAT = 100000; // Cap for power and charm

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- ERC721 Required Overrides ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Placeholder for metadata URI generation.
        // A real implementation would typically construct a URL pointing to
        // metadata (on IPFS, Arweave, or a dedicated service) which describes
        // the artifact based on its on-chain properties.
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Example: return string(abi.encodePacked("ipfs://some_base_uri/", Strings.toString(tokenId)));
        return string(abi.encodePacked("placeholder_uri/", Strings.toString(tokenId)));
    }

    // --- Internal Helpers ---
    function _calculateDecay(uint256 artifactId) internal view returns (uint32 currentDurability) {
        Artifact storage artifact = _artifactData[artifactId];
        if (artifact.isCorrupted) {
            return 0; // Already corrupted
        }

        uint256 timeSinceInteraction = block.timestamp - artifact.lastInteractionTime;
        uint256 decayAmount = timeSinceInteraction * decayRatePerSecond;

        // Ensure durability doesn't underflow or go below 0
        currentDurability = artifact.durability >= decayAmount ? uint32(artifact.durability - decayAmount) : 0;
        return currentDurability;
    }

    function _applyDecay(uint256 artifactId, uint32 calculatedDurability) internal {
         Artifact storage artifact = _artifactData[artifactId];
         artifact.durability = calculatedDurability;
         if (artifact.durability == 0 && !artifact.isCorrupted) {
             artifact.isCorrupted = true;
             // Optional: Trigger an event or effect for corruption
         }
    }

    function _applyGrowth(uint256 artifactId, uint256 growthAmount) internal {
        Artifact storage artifact = _artifactData[artifactId];
        uint256 powerGrowth = growthAmount / 2; // Split growth
        uint256 charmGrowth = growthAmount - powerGrowth;

        artifact.power = uint32((artifact.power + powerGrowth).min(MAX_STAT));
        artifact.charm = uint32((artifact.charm + charmGrowth).min(MAX_STAT));
    }

    function _attemptMutationRoll(uint256 artifactId, uint256 catalystTypeId) internal view returns (bool success, int32 powerChange, int32 charmChange) {
        CatalystType storage catalyst = _catalystTypes[catalystTypeId];
        uint256 totalChance = mutationChancePercent + catalyst.mutationChanceModifier; // Add catalyst bonus

        // Basic randomness simulation (not cryptographically secure, use Chainlink VRF for real randomness)
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(artifactId, catalystTypeId, block.timestamp, tx.origin, block.number)));
        uint256 roll = randomSeed % 100; // Roll a number between 0 and 99

        if (roll < totalChance) {
            // Mutation succeeds - determine changes
            uint256 changeSeed = uint256(keccak256(abi.encodePacked(artifactId, catalystTypeId, block.timestamp, tx.origin, block.number, roll)));
            int32 maxStatChange = int32(artifactData(artifactId).power.min(artifactData(artifactId).charm).min(MAX_STAT / 10)); // Change is relative to current stats, max 10% or 10000
            if (maxStatChange < 100) maxStatChange = 100; // Minimum change

            // Randomly determine if stats go up or down, and by how much
            powerChange = int32((changeSeed % (maxStatChange * 2)) - maxStatChange); // Range from -maxStatChange to +maxStatChange
            changeSeed = uint256(keccak256(abi.encodePacked(changeSeed))); // New seed
            charmChange = int32((changeSeed % (maxStatChange * 2)) - maxStatChange); // Range from -maxStatChange to +maxStatChange

            return (true, powerChange, charmChange);
        }
        return (false, 0, 0);
    }

    // --- Component Management (Admin/Internal) ---

    // 10. Creates a new type of Essence component.
    function createEssenceType(string memory name, uint256 baseCraftingCost, uint32 basePowerBoost, uint32 baseCharmBoost) external onlyOwner {
        _essenceTypeCounter.increment();
        uint256 newId = _essenceTypeCounter.current();
        _essenceTypes[newId] = EssenceType(newId, name, baseCraftingCost, basePowerBoost, baseCharmBoost);
        emit EssenceTypeCreated(newId, name);
    }

    // 11. Mints a specific amount of Essence components of a given type to an address.
    function mintEssence(address to, uint256 essenceTypeId, uint256 amount) external onlyOwner {
        require(_essenceTypes[essenceTypeId].id != 0, "Essence type does not exist");
        _essenceBalances[to][essenceTypeId] += amount;
        emit EssenceMinted(to, essenceTypeId, amount);
    }

    // 12. Burns a specific amount of Essence components.
    function burnEssence(address from, uint256 essenceTypeId, uint256 amount) internal {
        require(_essenceTypes[essenceTypeId].id != 0, "Essence type does not exist");
        require(_essenceBalances[from][essenceTypeId] >= amount, "Insufficient essence balance");
        _essenceBalances[from][essenceTypeId] -= amount;
        emit EssenceBurned(from, essenceTypeId, amount);
    }

    // 13. Gets the balance of a specific Essence type for an address.
    function getEssenceBalance(address account, uint256 essenceTypeId) external view returns (uint256) {
        return _essenceBalances[account][essenceTypeId];
    }

    // 14. Gets the details of an Essence type.
    function getEssenceTypeDetails(uint256 essenceTypeId) external view returns (EssenceType memory) {
        require(_essenceTypes[essenceTypeId].id != 0, "Essence type does not exist");
        return _essenceTypes[essenceTypeId];
    }

    // 15. Creates a new type of Catalyst component.
    function createCatalystType(string memory name, uint256 craftingModifier, uint8 mutationChanceModifier, uint32 durabilityBoost) external onlyOwner {
        _catalystTypeCounter.increment();
        uint256 newId = _catalystTypeCounter.current();
        _catalystTypes[newId] = CatalystType(newId, name, craftingModifier, mutationChanceModifier, durabilityBoost);
        emit CatalystTypeCreated(newId, name);
    }

    // 16. Mints a specific amount of Catalyst components of a given type to an address.
    function mintCatalyst(address to, uint256 catalystTypeId, uint256 amount) external onlyOwner {
        require(_catalystTypes[catalystTypeId].id != 0, "Catalyst type does not exist");
        _catalystBalances[to][catalystTypeId] += amount;
        emit CatalystMinted(to, catalystTypeId, amount);
    }

    // 17. Burns a specific amount of Catalyst components.
    function burnCatalyst(address from, uint256 catalystTypeId, uint256 amount) internal {
         require(_catalystTypes[catalystTypeId].id != 0, "Catalyst type does not exist");
         require(_catalystBalances[from][catalystTypeId] >= amount, "Insufficient catalyst balance");
        _catalystBalances[from][catalystTypeId] -= amount;
        emit CatalystBurned(from, catalystTypeId, amount);
    }

    // 18. Gets the balance of a specific Catalyst type for an address.
    function getCatalystBalance(address account, uint256 catalystTypeId) external view returns (uint256) {
        return _catalystBalances[account][catalystTypeId];
    }

    // 19. Gets the details of a Catalyst type.
    function getCatalystTypeDetails(uint256 catalystTypeId) external view returns (CatalystType memory) {
        require(_catalystTypes[catalystTypeId].id != 0, "Catalyst type does not exist");
        return _catalystTypes[catalystTypeId];
    }


    // --- Artifact Creation & Management (User) ---

    // 20. Crafts a new artifact using specified Essence and Catalyst components.
    function craftArtifact(uint256 essenceTypeId, uint256 catalystTypeId) external whenNotPaused {
        EssenceType storage essence = _essenceTypes[essenceTypeId];
        CatalystType storage catalyst = _catalystTypes[catalystTypeId];

        require(essence.id != 0, "Invalid Essence type");
        require(catalyst.id != 0, "Invalid Catalyst type");

        uint256 requiredEssence = essence.baseCraftingCost;
        // Apply catalyst modifier (assuming craftingModifier is like a percentage, e.g., 9000 means 90%)
        if (catalyst.craftingModifier > 0) {
             requiredEssence = (requiredEssence * catalyst.craftingModifier) / 10000; // Example: 9000/10000 = 0.9 multiplier
        }
         // Ensure minimum cost to avoid division by zero or free crafting unintentionally
        if (requiredEssence == 0 && essence.baseCraftingCost > 0) requiredEssence = 1;


        require(_essenceBalances[msg.sender][essenceTypeId] >= requiredEssence, "Insufficient Essence");
        require(_catalystBalances[msg.sender][catalystTypeId] >= 1, "Insufficient Catalyst");

        // Burn components
        burnEssence(msg.sender, essenceTypeId, requiredEssence);
        burnCatalyst(msg.sender, catalystTypeId, 1); // Catalysts are typically single-use

        // Mint new artifact
        _artifactTokenCounter.increment();
        uint256 newArtifactId = _artifactTokenCounter.current();

        // Calculate initial stats
        uint32 initialDurability = MAX_DURABILITY / 2 + catalyst.durabilityBoost; // Start with half + catalyst boost
        if (initialDurability > MAX_DURABILITY) initialDurability = MAX_DURABILITY; // Cap durability
        uint32 initialPower = essence.basePowerBoost;
        uint32 initialCharm = essence.baseCharmBoost;

        _artifactData[newArtifactId] = Artifact({
            id: newArtifactId,
            essenceTypeId: essenceTypeId,
            catalystTypeId: catalystTypeId,
            creationTime: uint64(block.timestamp),
            lastInteractionTime: uint64(block.timestamp), // Interaction on creation
            durability: initialDurability,
            power: initialPower,
            charm: initialCharm,
            generation: 1, // First generation upon crafting
            mutations: 0,
            attunedTo: address(0), // Not attuned initially
            isCorrupted: false
        });

        _safeMint(msg.sender, newArtifactId);

        emit ArtifactCrafted(newArtifactId, msg.sender, essenceTypeId, catalystTypeId);
    }

    // 21. Simulates interaction, updating time and potentially triggering growth/decay checks (decay applied implicitly on query).
    function interactWithArtifact(uint256 artifactId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
        Artifact storage artifact = _artifactData[artifactId];
        require(!artifact.isCorrupted, "Artifact is corrupted and cannot be interacted with");

        // Apply decay up to this point
        uint32 currentDurability = _calculateDecay(artifactId);
        _applyDecay(artifactId, currentDurability); // Update stored durability

        // Apply growth from interaction
        _applyGrowth(artifactId, growthRatePerInteraction);

        artifact.lastInteractionTime = uint64(block.timestamp); // Update interaction time

        // Optional: Add a small chance for mutation or other effects on interaction
        // bool mutated = _attemptMutationRoll(artifactId, artifact.catalystTypeId); // Could use the artifact's creation catalyst or require a new one?
        // if (mutated) { ... }

        // No specific event for generic interaction unless it causes a state change beyond time update
    }

    // 22. Repairs an artifact using Essence components, restoring durability based on cost.
    function repairArtifact(uint256 artifactId, uint256 essenceTypeId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
        Artifact storage artifact = _artifactData[artifactId];
        require(!artifact.isCorrupted, "Artifact is corrupted and cannot be repaired this way"); // Maybe a special repair for corrupted?

        EssenceType storage essence = _essenceTypes[essenceTypeId];
        require(essence.id != 0, "Invalid Essence type");

        // Calculate current durability factoring in decay
        uint32 currentDurability = _calculateDecay(artifactId);
        uint32 durabilityLost = MAX_DURABILITY - currentDurability;
        require(durabilityLost > 0, "Artifact does not need repair");

        // Calculate repair cost based on durability lost and essence base cost
        uint256 repairCost = (uint256(durabilityLost) * essence.baseCraftingCost * repairCostMultiplier) / MAX_DURABILITY; // Normalize by max durability
        if (repairCost == 0 && durabilityLost > 0) repairCost = 1; // Minimum cost

        require(_essenceBalances[msg.sender][essenceTypeId] >= repairCost, "Insufficent Essence for repair");

        // Burn components
        burnEssence(msg.sender, essenceTypeId, repairCost);

        // Restore durability (restore full durability, maybe scale restoration by essence type?)
        _applyDecay(artifactId, currentDurability); // Apply decay before repair
        artifact.durability = MAX_DURABILITY; // Restore to full
        artifact.lastInteractionTime = uint64(block.timestamp); // Interaction on repair
        artifact.isCorrupted = false; // Repair removes corrupted status

        emit ArtifactRepaired(artifactId, essenceTypeId, durabilityLost); // Emit how much was restored
    }

    // 23. Attempts to mutate an artifact's properties using a Catalyst.
    function attemptMutation(uint256 artifactId, uint256 catalystTypeId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
        Artifact storage artifact = _artifactData[artifactId];
         require(!artifact.isCorrupted, "Artifact is corrupted and cannot be mutated");

        CatalystType storage catalyst = _catalystTypes[catalystTypeId];
        require(catalyst.id != 0, "Invalid Catalyst type");
        require(_catalystBalances[msg.sender][catalystTypeId] >= 1, "Insufficient Catalyst");

        // Burn the catalyst
        burnCatalyst(msg.sender, catalystTypeId, 1);

        // Apply decay before potential mutation
        uint32 currentDurability = _calculateDecay(artifactId);
        _applyDecay(artifactId, currentDurability);

        // Attempt the mutation roll
        (bool success, int32 powerChange, int32 charmChange) = _attemptMutationRoll(artifactId, catalystTypeId);

        if (success) {
            // Apply changes, ensuring stats stay within limits (0 to MAX_STAT)
            artifact.power = uint32(int32(artifact.power) + powerChange).min(MAX_STAT).max(0);
            artifact.charm = uint32(int32(artifact.charm) + charmChange).min(MAX_STAT).max(0);
            artifact.mutations++;
            artifact.generation++; // Mutation increases generation
            artifact.lastInteractionTime = uint64(block.timestamp); // Interaction on mutation

            // Check if mutation caused corruption (e.g., if a stat drops to 0 and has a corruption effect)
            bool becameCorrupted = false; // Define custom corruption logic here if needed, e.g., power < minThreshold
            if (becameCorrupted) {
                 artifact.isCorrupted = true;
            }

            emit ArtifactMutated(artifactId, catalystTypeId, powerChange, charmChange, becameCorrupted);
        } else {
            // Mutation failed, maybe minor durability loss or just catalyst consumed
             // Example: lose 10% of MAX_DURABILITY on failed mutation
             uint32 failedMutationPenalty = MAX_DURABILITY / 10;
             artifact.durability = artifact.durability >= failedMutationPenalty ? artifact.durability - failedMutationPenalty : 0;
             if (artifact.durability == 0 && !artifact.isCorrupted) {
                 artifact.isCorrupted = true;
                 emit ArtifactMutated(artifactId, catalystTypeId, 0, 0, true); // Report becoming corrupted
             } else {
                 emit ArtifactMutated(artifactId, catalystTypeId, 0, 0, false); // Report failed mutation
             }
        }
    }

    // 24. Attunes an artifact to a specific address (must be owner of artifact).
    function attuneArtifact(uint256 artifactId, address targetAddress) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
        Artifact storage artifact = _artifactData[artifactId];
        require(artifact.attunedTo == address(0), "Artifact is already attuned");
        require(targetAddress != address(0), "Cannot attune to zero address");

        artifact.attunedTo = targetAddress;
        artifact.lastInteractionTime = uint64(block.timestamp); // Interaction on attunement

        emit ArtifactAttuned(artifactId, targetAddress);
    }

    // 25. Removes attunement from an artifact.
    function unattuneArtifact(uint256 artifactId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
        Artifact storage artifact = _artifactData[artifactId];
        require(artifact.attunedTo != address(0), "Artifact is not attuned");

        artifact.attunedTo = address(0);
        artifact.lastInteractionTime = uint64(block.timestamp); // Interaction on unattunement

        emit ArtifactUnattuned(artifactId);
    }

    // 26. Burns an artifact, potentially returning some components.
    function dismantleArtifact(uint256 artifactId) external whenNotPaused {
         require(_isApprovedOrOwner(msg.sender, artifactId), "Caller is not owner nor approved");
         Artifact storage artifact = _artifactData[artifactId];
         address owner = ownerOf(artifactId); // Use ownerOf for safety

         // Apply decay before dismantling
         uint32 currentDurability = _calculateDecay(artifactId);
         _applyDecay(artifactId, currentDurability);

         uint256 essenceTypeId = artifact.essenceTypeId;
         EssenceType storage essence = _essenceTypes[essenceTypeId];

         // Calculate essence return (based on original cost and return percent)
         uint256 returnedEssenceAmount = (essence.baseCraftingCost * dismantleEssenceReturnPercent) / 100;

         // Mint returned essence to owner
         if (returnedEssenceAmount > 0) {
             _essenceBalances[owner][essenceTypeId] += returnedEssenceAmount;
             emit EssenceMinted(owner, essenceTypeId, returnedEssenceAmount); // Re-use mint event for consistency
         }

         // Burn the artifact NFT
         _burn(artifactId);

         // Remove artifact data
         delete _artifactData[artifactId];

         emit ArtifactDismantled(artifactId, owner);
    }

    // --- Artifact State & Query (User/Public) ---

    // 27. Gets the raw stored details of an artifact.
    function getArtifactDetails(uint256 artifactId) public view returns (Artifact memory) {
         require(_exists(artifactId), "Artifact does not exist");
         return _artifactData[artifactId];
    }

    // 28. Calculates the current effective durability considering decay.
    function calculateCurrentDurability(uint256 artifactId) public view returns (uint32) {
        require(_exists(artifactId), "Artifact does not exist");
        return _calculateDecay(artifactId);
    }

    // 29. Calculates the current effective power considering decay/growth.
    function calculateCurrentPower(uint256 artifactId) public view returns (uint32) {
        require(_exists(artifactId), "Artifact does not exist");
        Artifact storage artifact = _artifactData[artifactId];
        // Decay could reduce power, but for simplicity, let's assume stats decay if durability is low.
        // Or more complex: stats decay proportional to durability loss.
        // Simple example: Power is 0 if corrupted.
        if (artifact.isCorrupted || _calculateDecay(artifactId) == 0) return 0;
        // More complex: Apply a decay penalty to stats based on durability %
        uint32 effectiveDurability = _calculateDecay(artifactId);
        uint256 durabilityRatio = (uint256(effectiveDurability) * 10000) / MAX_DURABILITY; // Ratio out of 10000
        uint32 effectivePower = uint32((uint256(artifact.power) * durabilityRatio) / 10000);

        return effectivePower; // This version applies a penalty based on *calculated* durability
    }

    // 30. Calculates the current effective charm considering decay/growth.
     function calculateCurrentCharm(uint256 artifactId) public view returns (uint32) {
        require(_exists(artifactId), "Artifact does not exist");
        Artifact storage artifact = _artifactData[artifactId];
         // Similar logic to power calculation
        if (artifact.isCorrupted || _calculateDecay(artifactId) == 0) return 0;

        uint32 effectiveDurability = _calculateDecay(artifactId);
        uint256 durabilityRatio = (uint256(effectiveDurability) * 10000) / MAX_DURABILITY;
        uint32 effectiveCharm = uint32((uint256(artifact.charm) * durabilityRatio) / 10000);

        return effectiveCharm; // This version applies a penalty based on *calculated* durability
    }

    // 31. Checks if an artifact's durability has dropped to zero (or calculated as zero).
    function isArtifactCorrupted(uint256 artifactId) public view returns (bool) {
        require(_exists(artifactId), "Artifact does not exist");
        return _artifactData[artifactId].isCorrupted || _calculateDecay(artifactId) == 0;
    }

    // 32. getTokenURI - See override implementation above.

    // --- Configuration (Admin) ---

    // 33. Sets the global durability decay rate.
    function setDecayRate(uint256 ratePerSecond) external onlyOwner {
        decayRatePerSecond = ratePerSecond;
        emit ConfigUpdated("decayRatePerSecond", ratePerSecond);
    }

    // 34. Sets the global stat growth rate per interaction.
    function setGrowthRate(uint256 ratePerInteraction) external onlyOwner {
        growthRatePerInteraction = ratePerInteraction;
        emit ConfigUpdated("growthRatePerInteraction", ratePerInteraction);
    }

    // 35. Sets the base mutation chance.
    function setMutationChance(uint8 percent) external onlyOwner {
        require(percent <= 100, "Percent must be 0-100");
        mutationChancePercent = percent;
         emit ConfigUpdated("mutationChancePercent", percent); // Note: Event takes uint256, casting uint8
    }

    // 36. Sets the multiplier for repair costs.
     function setRepairCostMultiplier(uint256 multiplier) external onlyOwner {
        require(multiplier > 0, "Multiplier must be positive");
        repairCostMultiplier = multiplier;
        emit ConfigUpdated("repairCostMultiplier", multiplier);
    }

    // 37. Sets the percentage of Essence returned on dismantle.
     function setDismantleEssenceReturnPercent(uint8 percent) external onlyOwner {
        require(percent <= 100, "Percent must be 0-100");
        dismantleEssenceReturnPercent = percent;
         emit ConfigUpdated("dismantleEssenceReturnPercent", percent); // Note: Event takes uint256, casting uint8
    }

    // --- Pausable Functions (Admin) ---

    // 38. Pauses crafting and interaction functions.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    // 39. Unpauses crafting and interaction functions.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- Overridden Pausable Hooks ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721) // Note: ERC721Hooks inherit from ERC721
    {
        // Apply decay when an artifact is transferred
        // This ensures the receiver gets an artifact with up-to-date durability
         if (from != address(0) && to != address(0)) { // Only apply on actual transfers, not mint/burn
            require(_exists(tokenId), "Transfer of nonexistent token"); // Should be true by ERC721 logic, but double check
            uint32 currentDurability = _calculateDecay(tokenId);
            _applyDecay(tokenId, currentDurability);
            _artifactData[tokenId].lastInteractionTime = uint64(block.timestamp); // Update interaction time on transfer
            // Note: This doesn't strictly apply growth, only decay on transfer.
            // Could add growth based on time transferred, but adds complexity.
         }

        // Apply Pausable check to transfers
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Call parent hook
    }

    // Needed to make Pausable work with ERC721's _beforeTokenTransfer hook
     function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
     {
         return super._update(to, tokenId, auth);
     }

     function _increaseBalance(address account, uint256 amount)
         internal
         override(ERC721)
     {
        super._increaseBalance(account, amount);
     }

    // Helper function to check if caller is owner or approved (from ERC721)
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender;
     }
}
```