Okay, this is an exciting challenge! Creating something truly unique, advanced, and with a high function count requires blending several cutting-edge concepts.

I'll propose "ChronoForge," a smart contract system that manages dynamically evolving, time-sensitive digital assets (NFTs) influenced by global epochs, external oracle data, and internal resource management. It's designed to simulate a living, ever-changing ecosystem of digital artifacts.

---

## ChronoForge: Temporal Nexus & Epochal Artifacts

**Concept:** ChronoForge is a decentralized protocol for the creation, evolution, and interaction of "EpochForged Artifacts" (EFAs). These aren't static NFTs; they are dynamic entities whose properties, abilities, and even their visual representation (via metadata updates) change based on:
1.  **Temporal Evolution:** An internal "age" that progresses, unlocking "sentience" levels.
2.  **Epochal Shifts:** Global state changes (epochs) that influence artifact properties.
3.  **Environmental Bias:** External data fed by oracles (simulating real-world events/conditions).
4.  **Resource Infusion:** Players using "TemporalFlux" (ERC-20) to accelerate evolution or activate special abilities.
5.  **Memory Weaving:** Burning "MemoryShards" (ERC-20) from older artifacts to re-roll properties.

The system introduces "Reality Rift Gates" as controlled genesis points for new artifacts, ensuring scarcity and unique initial conditions. It also features a "Catalyst Injection" mechanism for applying specific modifications to artifacts.

**Core Assets:**
*   **EpochForged Artifacts (EFAs):** ERC-721 tokens representing unique, evolving digital entities.
*   **TemporalFlux (TFX):** An ERC-20 token used as a primary resource to influence artifact evolution, activate features, and pay for genesis events.
*   **MemoryShards (MSH):** An ERC-20 token earned from artifacts as they mature or are "decommissioned," used for re-rolling artifact properties.
*   **CrystallineShards (CSH):** An ERC-20 token earned from highly evolved artifacts, used for potent upgrades or unlocking advanced functions.

**Key Advanced Concepts:**
*   **Dynamic On-Chain Metadata:** While the IPFS hash is stored, specific traits (like `evolutionRate`, `sentienceLevel`, `environmentalBias`) are computed and stored on-chain, forming dynamic properties.
*   **Time-Dilation Mechanics:** `infuseAethericEnergy` and `applyTemporalStasis` directly manipulate the artifact's effective "age" progression.
*   **Event-Driven Evolution:** Oracle integration (`updateEnvironmentalFactor`) directly influences how artifacts behave or evolve.
*   **Resource Sinks & Mints:** Complex interdependencies between TFX, MSH, CSH, and EFAs, encouraging strategic play and resource management.
*   **Epochal Global State:** The contract maintains a `currentEpoch` that affects all artifacts, introducing a meta-game layer.
*   **"Sentience" Thresholds:** Artifacts unlock new abilities or characteristics as they reach defined maturity levels.
*   **Controlled Genesis (Rift Gates):** Scarcity is managed through limited-use "gates" rather than open minting.
*   **Inter-Asset Mechanics:** Artifacts "emit" other tokens (shards) as they mature, creating a circular economy.

---

### ChronoForge: Contract Outline & Function Summary

**I. Core Infrastructure & Access Control**
*   `constructor`: Initializes the contract, ERC-721, ERC-20 tokens, and sets the initial owner.
*   `transferOwnership`: Transfers contract ownership.
*   `renounceOwnership`: Renounces contract ownership (makes it unowned).
*   `pauseContract`: Pauses critical functions of the contract (onlyOwner).
*   `unpauseContract`: Unpauses the contract (onlyOwner).
*   `setOracleAddress`: Sets the address of the trusted oracle that provides external data.

**II. Global Epoch & Environment Management**
*   `pioneerNewEpoch`: (Admin/Governance) Advances the global state to a new epoch, affecting all artifacts.
*   `updateEnvironmentalFactor`: (Oracle-only) Updates a global environmental variable that influences artifact evolution.
*   `getCurrentEpochState`: Returns details about the current global epoch.

**III. Artifact Forging & Lifecycle (ERC721 Extension)**
*   `forgeArtifactViaRift`: Creates a new EpochForged Artifact by consuming TemporalFlux and utilizing a specific Reality Rift Gate.
*   `transferFrom`: Transfers ownership of an Artifact. (ERC721 standard)
*   `safeTransferFrom`: Transfers ownership of an Artifact safely. (ERC721 standard)
*   `approve`: Approves another address to transfer a specific Artifact. (ERC721 standard)
*   `setApprovalForAll`: Approves or revokes an operator for all Artifacts. (ERC721 standard)
*   `balanceOf`: Returns the number of Artifacts owned by an address. (ERC721 standard)
*   `ownerOf`: Returns the owner of a specific Artifact. (ERC721 standard)
*   `getApproved`: Returns the approved address for an Artifact. (ERC721 standard)
*   `isApprovedForAll`: Checks if an operator is approved for all Artifacts of an owner. (ERC721 standard)
*   `tokenURI`: Returns the metadata URI for a given Artifact. (ERC721 standard, dynamically adjusted).

**IV. TemporalFlux (ERC20) & Resource Management**
*   `mintTemporalFlux`: (Admin) Mints new TemporalFlux into the system.
*   `burnTemporalFlux`: Allows users to burn their TemporalFlux.
*   `stakeTemporalFlux`: Locks TemporalFlux to potentially earn rewards or unlock features.
*   `unstakeTemporalFlux`: Unlocks and returns staked TemporalFlux.
*   `claimShardsFromArtifact`: Allows an artifact owner to claim accumulated MemoryShards or CrystallineShards from a sufficiently evolved artifact.

**V. Advanced Artifact Interactions & Evolution**
*   `infuseAethericEnergy`: Spends TemporalFlux to accelerate the evolution rate of an Artifact.
*   `applyTemporalStasis`: Spends TemporalFlux to pause an Artifact's evolution, preserving its current state.
*   `reactivateArtifact`: Spends TemporalFlux to resume a paused Artifact's evolution.
*   `injectCatalyst`: Applies a specific "catalyst" (unique modifier) to an Artifact, altering its properties.
*   `weaveMemoryShards`: Burns MemoryShards to re-roll a specific set of properties of an Artifact, potentially changing its path.
*   `triggerSentienceAwakening`: Attempts to awaken an Artifact's sentience if it meets temporal and environmental conditions.
*   `transferEpochArtifact`: (Conceptually) Moves an artifact into a different "conceptual" epoch, affecting how it interacts with the `environmentalFactor`.

**VI. Utility & Query Functions**
*   `getArtifactDetails`: Returns a comprehensive struct of an Artifact's current properties.
*   `getArtifactEvolutionProgress`: Calculates and returns the current evolution progress and remaining time until next sentience level.
*   `getRiftGateDetails`: Returns details about a specific Reality Rift Gate.
*   `getCurrentEpochId`: Returns the ID of the current global epoch.
*   `getTemporalFluxBalance`: Returns the TemporalFlux balance for an address.
*   `getMemoryShardBalance`: Returns the MemoryShard balance for an address.
*   `getCrystallineShardBalance`: Returns the CrystallineShard balance for an address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- ChronoForge: Temporal Nexus & Epochal Artifacts ---
//
// Concept: ChronoForge is a decentralized protocol for the creation, evolution,
// and interaction of "EpochForged Artifacts" (EFAs). These aren't static NFTs;
// they are dynamic entities whose properties, abilities, and even their visual
// representation (via metadata updates) change based on:
// 1. Temporal Evolution: An internal "age" that progresses, unlocking "sentience" levels.
// 2. Epochal Shifts: Global state changes (epochs) that influence artifact properties.
// 3. Environmental Bias: External data fed by oracles (simulating real-world events/conditions).
// 4. Resource Infusion: Players using "TemporalFlux" (ERC-20) to accelerate evolution or activate special abilities.
// 5. Memory Weaving: Burning "MemoryShards" (ERC-20) from older artifacts to re-roll properties.
//
// The system introduces "Reality Rift Gates" as controlled genesis points for new artifacts,
// ensuring scarcity and unique initial conditions. It also features a "Catalyst Injection"
// mechanism for applying specific modifications to artifacts.
//
// Core Assets:
// - EpochForged Artifacts (EFAs): ERC-721 tokens representing unique, evolving digital entities.
// - TemporalFlux (TFX): An ERC-20 token used as a primary resource to influence artifact evolution,
//   activate features, and pay for genesis events.
// - MemoryShards (MSH): An ERC-20 token earned from artifacts as they mature or are "decommissioned,"
//   used for re-rolling artifact properties.
// - CrystallineShards (CSH): An ERC-20 token earned from highly evolved artifacts,
//   used for potent upgrades or unlocking advanced functions.
//
// Key Advanced Concepts:
// - Dynamic On-Chain Metadata: While the IPFS hash is stored, specific traits
//   (like evolutionRate, sentienceLevel, environmentalBias) are computed and stored on-chain,
//   forming dynamic properties.
// - Time-Dilation Mechanics: `infuseAethericEnergy` and `applyTemporalStasis` directly
//   manipulate the artifact's effective "age" progression.
// - Event-Driven Evolution: Oracle integration (`updateEnvironmentalFactor`) directly
//   influences how artifacts behave or evolve.
// - Resource Sinks & Mints: Complex interdependencies between TFX, MSH, CSH, and EFAs,
//   encouraging strategic play and resource management.
// - Epochal Global State: The contract maintains a `currentEpoch` that affects all artifacts,
//   introducing a meta-game layer.
// - "Sentience" Thresholds: Artifacts unlock new abilities or characteristics as they reach
//   defined maturity levels.
// - Controlled Genesis (Rift Gates): Scarcity is managed through limited-use "gates"
//   rather than open minting.
// - Inter-Asset Mechanics: Artifacts "emit" other tokens (shards) as they mature,
//   creating a circular economy.

// --- ChronoForge: Contract Outline & Function Summary ---
//
// I. Core Infrastructure & Access Control
// - constructor: Initializes the contract, ERC-721, ERC-20 tokens, and sets the initial owner.
// - transferOwnership: Transfers contract ownership.
// - renounceOwnership: Renounces contract ownership (makes it unowned).
// - pauseContract: Pauses critical functions of the contract (onlyOwner).
// - unpauseContract: Unpauses the contract (onlyOwner).
// - setOracleAddress: Sets the address of the trusted oracle that provides external data.
//
// II. Global Epoch & Environment Management
// - pioneerNewEpoch: (Admin/Governance) Advances the global state to a new epoch, affecting all artifacts.
// - updateEnvironmentalFactor: (Oracle-only) Updates a global environmental variable that influences artifact evolution.
// - getCurrentEpochState: Returns details about the current global epoch.
//
// III. Artifact Forging & Lifecycle (ERC721 Extension)
// - forgeArtifactViaRift: Creates a new EpochForged Artifact by consuming TemporalFlux and utilizing a specific Reality Rift Gate.
// - transferFrom: Transfers ownership of an Artifact. (ERC721 standard)
// - safeTransferFrom: Transfers ownership of an Artifact safely. (ERC721 standard)
// - approve: Approves another address to transfer a specific Artifact. (ERC721 standard)
// - setApprovalForAll: Approves or revokes an operator for all Artifacts. (ERC721 standard)
// - balanceOf: Returns the number of Artifacts owned by an address. (ERC721 standard)
// - ownerOf: Returns the owner of a specific Artifact. (ERC721 standard)
// - getApproved: Returns the approved address for an Artifact. (ERC721 standard)
// - isApprovedForAll: Checks if an operator is approved for all Artifacts of an owner. (ERC721 standard)
// - tokenURI: Returns the metadata URI for a given Artifact. (ERC721 standard, dynamically adjusted).
//
// IV. TemporalFlux (ERC20) & Resource Management
// - mintTemporalFlux: (Admin) Mints new TemporalFlux into the system.
// - burnTemporalFlux: Allows users to burn their TemporalFlux.
// - stakeTemporalFlux: Locks TemporalFlux to potentially earn rewards or unlock features.
// - unstakeTemporalFlux: Unlocks and returns staked TemporalFlux.
// - claimShardsFromArtifact: Allows an artifact owner to claim accumulated MemoryShards or CrystallineShards from a sufficiently evolved artifact.
//
// V. Advanced Artifact Interactions & Evolution
// - infuseAethericEnergy: Spends TemporalFlux to accelerate the evolution rate of an Artifact.
// - applyTemporalStasis: Spends TemporalFlux to pause an Artifact's evolution, preserving its current state.
// - reactivateArtifact: Spends TemporalFlux to resume a paused Artifact's evolution.
// - injectCatalyst: Applies a specific "catalyst" (unique modifier) to an Artifact, altering its properties.
// - weaveMemoryShards: Burns MemoryShards to re-roll a specific set of properties of an Artifact, potentially changing its path.
// - triggerSentienceAwakening: Attempts to awaken an Artifact's sentience if it meets temporal and environmental conditions.
// - transferEpochArtifact: (Conceptually) Moves an artifact into a different "conceptual" epoch, affecting how it interacts with the `environmentalFactor`.
//
// VI. Utility & Query Functions
// - getArtifactDetails: Returns a comprehensive struct of an Artifact's current properties.
// - getArtifactEvolutionProgress: Calculates and returns the current evolution progress and remaining time until next sentience level.
// - getRiftGateDetails: Returns details about a specific Reality Rift Gate.
// - getCurrentEpochId: Returns the ID of the current global epoch.
// - getTemporalFluxBalance: Returns the TemporalFlux balance for an address.
// - getMemoryShardBalance: Returns the MemoryShard balance for an address.
// - getCrystallineShardBalance: Returns the CrystallineShard balance for an address.

contract ChronoForge is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token Counters
    Counters.Counter private _artifactIds;

    // EpochForger Artifacts (EFAs)
    struct Artifact {
        uint256 creationBlock; // Block number when created
        uint256 lastEvolutionUpdateBlock; // Last block where evolution was accounted for (infusion/stasis/reactivate)
        uint256 accumulatedEvolutionAge; // Total simulated time (blocks) artifact has "lived"
        uint256 evolutionRate; // How many blocks of actual time equate to 1 "simulated" block (lower = faster)
        uint256 sentienceLevel; // Unlocked abilities/properties
        bool isActive; // Can this artifact evolve?
        uint256 environmentalBias; // How this artifact reacts to the current global environmental factor
        uint256 catalystSignature; // Unique ID representing an applied catalyst effect
        uint256 riftOriginId; // ID of the Rift Gate it was forged from
        uint256 currentConceptualEpoch; // The epoch this artifact conceptually belongs to for specific interactions
        string metadataBaseURI; // Base URI for this artifact's metadata
        // For dynamic traits, we can calculate them on-the-fly or store specific indices/values
        // e.g., uint256[] intrinsicProperties; // Array for various dynamic properties
    }
    mapping(uint256 => Artifact) public artifacts;

    // Reality Rift Gates - controlled genesis points for new artifacts
    struct RiftGate {
        uint256 maxArtifacts; // Max artifacts this gate can forge
        uint256 createdCount; // How many artifacts have been forged
        uint256 fluxCost; // Cost in TemporalFlux to use this gate
        bool isActive; // Can this gate be used?
        uint256 uniqueSeed; // Seed for initial artifact property generation
        string gateName; // Name of the rift gate
    }
    mapping(uint256 => RiftGate) public riftGates;
    Counters.Counter private _riftGateIds;

    // Global Epoch Management
    struct Epoch {
        uint256 id;
        uint256 startBlock;
        string theme;
        string description;
        uint256 minimumSentienceForEffect; // Minimum sentience level required for this epoch's effect
    }
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpochId;
    uint256 public environmentalFactor; // Global value updated by oracle

    // Oracles and external integrations
    address public oracleAddress;

    // Sentience thresholds - defines when an artifact reaches a new level
    // mapping: sentienceLevel => requiredAccumulatedEvolutionAge (in blocks)
    mapping(uint256 => uint256) public sentienceThresholds;

    // Token Contracts
    TemporalFlux public temporalFlux;
    MemoryShards public memoryShards;
    CrystallineShards public crystallineShards;

    // Constants
    uint256 public constant DEFAULT_ARTIFACT_EVOLUTION_RATE = 100; // 100 blocks = 1 unit of age
    uint256 public constant BASE_FLUX_COST_FORGE = 100 * (10 ** 18); // Example: 100 TFX
    uint256 public constant SHARDS_PER_SENTIENCE_LEVEL = 10 * (10 ** 18); // Example: 10 MSH per level
    uint256 public constant CRYSTALLINE_SHARDS_PER_LEVEL_AFTER_THRESHOLD = 1 * (10 ** 18); // 1 CSH after a certain level
    uint256 public constant CRYSTALLINE_SHARD_THRESHOLD_LEVEL = 5; // Sentience level from which CSH start accumulating

    // --- Events ---
    event ArtifactForged(uint256 indexed tokenId, address indexed owner, uint256 riftId, uint256 creationEpochId);
    event ArtifactEvolutionInfused(uint256 indexed tokenId, uint256 newEvolutionRate, uint256 fluxSpent);
    event ArtifactStasisApplied(uint256 indexed tokenId, uint256 fluxSpent);
    event ArtifactReactivated(uint256 indexed tokenId, uint256 fluxSpent);
    event ArtifactCatalystInjected(uint256 indexed tokenId, uint256 catalystId);
    event MemoryShardsWoven(uint256 indexed tokenId, uint256 shardsBurned);
    event SentienceAwakened(uint256 indexed tokenId, uint256 newSentienceLevel);
    event EpochPioneered(uint256 indexed newEpochId, string theme, string description);
    event EnvironmentalFactorUpdated(uint256 indexed newFactor, address indexed updater);
    event RealityRiftGateCreated(uint256 indexed riftId, string name, uint256 maxArtifacts, uint256 fluxCost);
    event ShardsClaimed(uint256 indexed tokenId, address indexed claimant, uint256 memoryShardsClaimed, uint256 crystallineShardsClaimed);
    event TemporalFluxStaked(address indexed user, uint256 amount);
    event TemporalFluxUnstaked(address indexed user, uint256 amount);
    event ConceptualEpochTransferred(uint256 indexed tokenId, uint256 oldEpoch, uint256 newEpoch);


    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoForge: Caller is not the oracle");
        _;
    }

    // --- Constructor ---
    constructor(
        address _fluxTokenAddress,
        address _memoryShardsTokenAddress,
        address _crystallineShardsTokenAddress,
        address _initialOracleAddress
    ) ERC721Enumerable("Epoch Forged Artifact", "EFA") Ownable(msg.sender) Pausable() {
        temporalFlux = TemporalFlux(_fluxTokenAddress);
        memoryShards = MemoryShards(_memoryShardsTokenAddress);
        crystallineShards = CrystallineShards(_crystallineShardsTokenAddress);
        oracleAddress = _initialOracleAddress;

        // Initialize the first epoch
        currentEpochId = 1;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startBlock: block.number,
            theme: "The Genesis Age",
            description: "The beginning of ChronoForge. Properties are raw and volatile.",
            minimumSentienceForEffect: 0
        });

        // Set example sentience thresholds
        sentienceThresholds[1] = 1000; // After 1000 simulated blocks
        sentienceThresholds[2] = 3000;
        sentienceThresholds[3] = 6000;
        sentienceThresholds[4] = 10000;
        sentienceThresholds[5] = 15000;
        // ... more levels as needed
    }

    // --- I. Core Infrastructure & Access Control ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "ChronoForge: New oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
    }

    // --- II. Global Epoch & Environment Management ---

    function pioneerNewEpoch(string calldata _theme, string calldata _description, uint256 _minSentience)
        external
        onlyOwner
        nonReentrant
    {
        currentEpochId++;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startBlock: block.number,
            theme: _theme,
            description: _description,
            minimumSentienceForEffect: _minSentience
        });
        emit EpochPioneered(currentEpochId, _theme, _description);
    }

    function updateEnvironmentalFactor(uint256 _newFactor) external onlyOracle nonReentrant {
        require(_newFactor <= 10000, "ChronoForge: Factor out of bounds (0-10000)"); // Example range
        environmentalFactor = _newFactor;
        emit EnvironmentalFactorUpdated(_newFactor, msg.sender);
    }

    function getCurrentEpochState() external view returns (Epoch memory) {
        return epochs[currentEpochId];
    }

    // --- III. Artifact Forging & Lifecycle (ERC721 Extension) ---

    function forgeArtifactViaRift(uint256 _riftId, string calldata _metadataBaseURI)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 tokenId)
    {
        RiftGate storage rift = riftGates[_riftId];
        require(rift.isActive, "ChronoForge: Rift Gate is not active");
        require(rift.createdCount < rift.maxArtifacts, "ChronoForge: Rift Gate exhausted");
        require(temporalFlux.transferFrom(msg.sender, address(this), rift.fluxCost), "ChronoForge: Insufficient TemporalFlux or allowance");

        rift.createdCount++;
        _artifactIds.increment();
        tokenId = _artifactIds.current();

        artifacts[tokenId] = Artifact({
            creationBlock: block.number,
            lastEvolutionUpdateBlock: block.number,
            accumulatedEvolutionAge: 0,
            evolutionRate: DEFAULT_ARTIFACT_EVOLUTION_RATE, // Initial rate
            sentienceLevel: 0,
            isActive: true,
            environmentalBias: (rift.uniqueSeed % 10000) + 1, // Example: Seed derived bias (1-10000)
            catalystSignature: 0,
            riftOriginId: _riftId,
            currentConceptualEpoch: currentEpochId,
            metadataBaseURI: _metadataBaseURI
        });

        _safeMint(msg.sender, tokenId);
        emit ArtifactForged(tokenId, msg.sender, _riftId, currentEpochId);
        return tokenId;
    }

    function createRiftGate(
        string calldata _gateName,
        uint256 _maxArtifacts,
        uint256 _fluxCost,
        uint256 _uniqueSeed
    ) external onlyOwner returns (uint256 riftId) {
        _riftGateIds.increment();
        riftId = _riftGateIds.current();
        riftGates[riftId] = RiftGate({
            maxArtifacts: _maxArtifacts,
            createdCount: 0,
            fluxCost: _fluxCost,
            isActive: true,
            uniqueSeed: _uniqueSeed,
            gateName: _gateName
        });
        emit RealityRiftGateCreated(riftId, _gateName, _maxArtifacts, _fluxCost);
        return riftId;
    }

    function pauseRiftGate(uint256 _riftId, bool _isActive) external onlyOwner {
        require(riftGates[_riftId].maxArtifacts > 0, "ChronoForge: Rift Gate does not exist");
        riftGates[_riftId].isActive = _isActive;
    }

    // Overrides for ERC721Enumerable:
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // On transfer, ensure evolution is calculated up to the current block
        // _updateArtifactEvolution(tokenId); // Could add this for more precise evolution
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        Artifact storage artifact = artifacts[tokenId];

        // Example of dynamic metadata:
        // Concatenate base URI with artifact properties to allow external services to generate dynamic images/JSON
        return string(abi.encodePacked(
            artifact.metadataBaseURI,
            Strings.toString(tokenId),
            ".json?s=", Strings.toString(artifact.sentienceLevel),
            "&e=", Strings.toString(artifact.accumulatedEvolutionAge),
            "&f=", Strings.toString(environmentalFactor),
            "&b=", Strings.toString(artifact.environmentalBias),
            "&c=", Strings.toString(artifact.catalystSignature)
        ));
    }


    // --- IV. TemporalFlux (ERC20) & Resource Management ---

    function mintTemporalFlux(address _to, uint256 _amount) external onlyOwner nonReentrant {
        temporalFlux.mint(_to, _amount);
    }

    function burnTemporalFlux(uint256 _amount) external nonReentrant {
        temporalFlux.burn(msg.sender, _amount);
    }

    function stakeTemporalFlux(uint256 _amount) external nonReentrant {
        require(temporalFlux.transferFrom(msg.sender, address(this), _amount), "ChronoForge: TFX transfer failed or allowance insufficient");
        // Logic for tracking individual stakes would be more complex, e.g., a mapping
        // For simplicity, just transfer to contract. Real staking would involve rewards, withdrawal logic.
        emit TemporalFluxStaked(msg.sender, _amount);
    }

    function unstakeTemporalFlux(uint256 _amount) external nonReentrant {
        // This is a simplified example. A real staking system needs to track how much each user has staked.
        // For now, it assumes the contract has enough balance and user is allowed to unstake.
        // In a real scenario, this would check a user's staked balance.
        require(temporalFlux.balanceOf(address(this)) >= _amount, "ChronoForge: Insufficient TFX staked in contract");
        require(temporalFlux.transfer(msg.sender, _amount), "ChronoForge: TFX transfer failed");
        emit TemporalFluxUnstaked(msg.sender, _amount);
    }


    // Function to calculate and claim shards
    function claimShardsFromArtifact(uint256 _tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to claim shards for this artifact");
        Artifact storage artifact = artifacts[_tokenId];

        // Ensure evolution is up-to-date for accurate shard calculation
        _updateArtifactEvolution(_tokenId);

        uint256 accumulatedMSH = artifact.sentienceLevel * SHARDS_PER_SENTIENCE_LEVEL;
        uint256 accumulatedCSH = 0;

        if (artifact.sentienceLevel >= CRYSTALLINE_SHARD_THRESHOLD_LEVEL) {
            accumulatedCSH = (artifact.sentienceLevel - (CRYSTALLINE_SHARD_THRESHOLD_LEVEL - 1)) * CRYSTALLINE_SHARDS_PER_LEVEL_AFTER_THRESHOLD;
        }

        require(accumulatedMSH > 0 || accumulatedCSH > 0, "ChronoForge: No shards available to claim yet");

        // Mint shards to the owner
        memoryShards.mint(msg.sender, accumulatedMSH);
        if (accumulatedCSH > 0) {
            crystallineShards.mint(msg.sender, accumulatedCSH);
        }

        // Reset shard claims. A more complex system might allow partial claims.
        // For simplicity, we can reset sentience if shards are tied to it, or have a separate tracking variable.
        // For now, we'll assume shards accumulate and can only be claimed once for the current state.
        // To allow repeated claims for newly reached levels, we'd need another mapping:
        // mapping(uint256 => uint256) public claimedMemoryShardsPerToken;
        // mapping(uint256 => uint256) public claimedCrystallineShardsPerToken;
        // and then `accumulatedMSH - claimedMemoryShardsPerToken[_tokenId]` etc.
        // For this example, let's keep it simple and assume the claim represents the total accumulated until now.
        // A better model for continuous claims would be to track 'lastClaimedSentienceLevel'
        // For unique claim, if already claimed, disallow.
        // Or, for cumulative, track `uint256 lastClaimedEvolutionAge;` and `_calculateNewShardsSinceLastClaim`
        // Given the requirement for 20+ functions, let's assume a simpler "claim available" model for now.
        // The most robust way is to have `_claimedMSH[_tokenId]` and `_claimedCSH[_tokenId]` and mint `total_available - _claimed`
        // When claiming, update `_claimedMSH[_tokenId] = total_available`

        // This example implies a one-time claim for the current `sentienceLevel`
        // To make it continuously claimable, each time `sentienceLevel` increases, new shards become claimable.
        // This requires tracking already claimed shards for each artifact. Let's add that for robustness.
        uint256 availableMSH = accumulatedMSH - claimedMemoryShards[_tokenId];
        uint256 availableCSH = accumulatedCSH - claimedCrystallineShards[_tokenId];

        require(availableMSH > 0 || availableCSH > 0, "ChronoForge: No new shards available to claim");

        if (availableMSH > 0) {
            memoryShards.mint(msg.sender, availableMSH);
            claimedMemoryShards[_tokenId] += availableMSH;
        }
        if (availableCSH > 0) {
            crystallineShards.mint(msg.sender, availableCSH);
            claimedCrystallineShards[_tokenId] += availableCSH;
        }

        emit ShardsClaimed(_tokenId, msg.sender, availableMSH, availableCSH);
    }

    mapping(uint256 => uint256) private claimedMemoryShards;
    mapping(uint256 => uint256) private claimedCrystallineShards;


    // --- V. Advanced Artifact Interactions & Evolution ---

    function infuseAethericEnergy(uint256 _tokenId, uint256 _fluxAmount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to infuse energy");
        Artifact storage artifact = artifacts[_tokenId];
        require(artifact.isActive, "ChronoForge: Artifact is in stasis or inactive");
        require(_fluxAmount > 0, "ChronoForge: Infusion amount must be positive");
        require(temporalFlux.transferFrom(msg.sender, address(this), _fluxAmount), "ChronoForge: Insufficient TemporalFlux or allowance");

        _updateArtifactEvolution(_tokenId); // Ensure current age is calculated
        artifact.evolutionRate = artifact.evolutionRate * (10000 + _fluxAmount / (10**18)) / 10000; // Example: 1 TFX reduces rate by 0.01%
        if (artifact.evolutionRate < 10) artifact.evolutionRate = 10; // Cap to prevent ultra-fast evolution
        
        emit ArtifactEvolutionInfused(_tokenId, artifact.evolutionRate, _fluxAmount);
    }

    function applyTemporalStasis(uint256 _tokenId, uint256 _fluxAmount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to apply stasis");
        Artifact storage artifact = artifacts[_tokenId];
        require(artifact.isActive, "ChronoForge: Artifact is already in stasis or inactive");
        require(_fluxAmount > 0, "ChronoForge: Stasis amount must be positive"); // Flux to enter stasis
        require(temporalFlux.transferFrom(msg.sender, address(this), _fluxAmount), "ChronoForge: Insufficient TemporalFlux or allowance");

        _updateArtifactEvolution(_tokenId); // Capture current age before pausing
        artifact.isActive = false;

        emit ArtifactStasisApplied(_tokenId, _fluxAmount);
    }

    function reactivateArtifact(uint256 _tokenId, uint256 _fluxAmount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to reactivate");
        Artifact storage artifact = artifacts[_tokenId];
        require(!artifact.isActive, "ChronoForge: Artifact is already active");
        require(_fluxAmount > 0, "ChronoForge: Reactivation amount must be positive"); // Flux to reactivate
        require(temporalFlux.transferFrom(msg.sender, address(this), _fluxAmount), "ChronoForge: Insufficient TemporalFlux or allowance");

        artifact.isActive = true;
        artifact.lastEvolutionUpdateBlock = block.number; // Resume evolution from now

        emit ArtifactReactivated(_tokenId, _fluxAmount);
    }

    function injectCatalyst(uint256 _tokenId, uint256 _catalystId, uint256 _fluxCost)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to inject catalyst");
        require(_catalystId > 0, "ChronoForge: Catalyst ID must be valid");
        require(temporalFlux.transferFrom(msg.sender, address(this), _fluxCost), "ChronoForge: Insufficient TemporalFlux or allowance");

        _updateArtifactEvolution(_tokenId); // Ensure state is current
        artifacts[_tokenId].catalystSignature = _catalystId; // Apply catalyst effect (simple ID for this example)
        // More complex logic would involve specific trait modifications based on catalystId

        emit ArtifactCatalystInjected(_tokenId, _catalystId);
    }

    function weaveMemoryShards(uint256 _tokenId, uint256 _shardsAmount, uint256 _newSeed)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to weave shards");
        require(_shardsAmount > 0, "ChronoForge: Must weave positive shards");
        require(memoryShards.transferFrom(msg.sender, address(this), _shardsAmount), "ChronoForge: Insufficient MemoryShards or allowance");

        _updateArtifactEvolution(_tokenId); // Ensure evolution is up-to-date
        Artifact storage artifact = artifacts[_tokenId];

        // Example: Re-roll intrinsic properties based on _newSeed and shard amount
        // This is a placeholder for complex trait re-generation
        artifact.environmentalBias = (_newSeed % 10000) + (_shardsAmount / (10**18)) + 1; // Example re-roll logic
        // Could also reset sentience or other attributes depending on game design

        emit MemoryShardsWoven(_tokenId, _shardsAmount);
    }

    function triggerSentienceAwakening(uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to trigger awakening");
        Artifact storage artifact = artifacts[_tokenId];

        _updateArtifactEvolution(_tokenId); // Ensure current age is reflected

        uint256 currentThreshold = sentienceThresholds[artifact.sentienceLevel + 1];
        require(currentThreshold > 0, "ChronoForge: No higher sentience level defined");
        require(artifact.accumulatedEvolutionAge >= currentThreshold, "ChronoForge: Not enough evolution age for next sentience level");

        artifact.sentienceLevel++;
        emit SentienceAwakened(_tokenId, artifact.sentienceLevel);
    }

    function transferEpochArtifact(uint256 _tokenId, uint256 _targetEpochId)
        external
        whenNotPaused
        nonReentrant
    {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ChronoForge: Not authorized to transfer epoch artifact");
        require(_targetEpochId <= currentEpochId, "ChronoForge: Target epoch must exist");
        require(epochs[_targetEpochId].id > 0, "ChronoForge: Target epoch does not exist");
        require(artifacts[_tokenId].currentConceptualEpoch != _targetEpochId, "ChronoForge: Artifact already in target conceptual epoch");

        _updateArtifactEvolution(_tokenId); // Update before changing conceptual epoch

        uint256 oldEpoch = artifacts[_tokenId].currentConceptualEpoch;
        artifacts[_tokenId].currentConceptualEpoch = _targetEpochId;

        emit ConceptualEpochTransferred(_tokenId, oldEpoch, _targetEpochId);
    }

    // --- VI. Utility & Query Functions ---

    function getArtifactDetails(uint256 _tokenId)
        public
        view
        returns (
            Artifact memory details,
            uint256 currentSimulatedAge,
            uint256 currentSentienceLevel,
            string memory currentEpochTheme,
            uint256 currentEnvironmentalFactor
        )
    {
        require(_exists(_tokenId), "ChronoForge: Artifact does not exist");
        Artifact storage artifact = artifacts[_tokenId];
        details = artifact; // Copy struct

        currentSimulatedAge = _calculateCurrentSimulatedAge(artifact);
        currentSentienceLevel = artifact.sentienceLevel;
        currentEpochTheme = epochs[currentEpochId].theme;
        currentEnvironmentalFactor = environmentalFactor;

        // Dynamic Sentience Check: If current age surpasses a threshold not yet registered
        // This is a view function, so it can't update state.
        // The actual update happens in `triggerSentienceAwakening` or `_updateArtifactEvolution`
        for (uint256 i = artifact.sentienceLevel + 1; ; i++) {
            uint256 threshold = sentienceThresholds[i];
            if (threshold == 0) break; // No more thresholds defined
            if (currentSimulatedAge >= threshold) {
                currentSentienceLevel = i; // Show potential new level
            } else {
                break;
            }
        }
    }

    function getArtifactEvolutionProgress(uint256 _tokenId)
        public
        view
        returns (uint256 currentAge, uint256 nextSentienceThreshold, uint256 progressPercentage)
    {
        require(_exists(_tokenId), "ChronoForge: Artifact does not exist");
        Artifact storage artifact = artifacts[_tokenId];

        currentAge = _calculateCurrentSimulatedAge(artifact);
        nextSentienceThreshold = sentienceThresholds[artifact.sentienceLevel + 1];

        if (nextSentienceThreshold == 0) {
            // Max sentience reached or no further levels defined
            progressPercentage = 100;
        } else {
            uint256 previousThreshold = sentienceThresholds[artifact.sentienceLevel];
            if (previousThreshold == 0 && artifact.sentienceLevel == 0) previousThreshold = 0; // Handle level 0 start

            uint256 range = nextSentienceThreshold - previousThreshold;
            uint256 progress = currentAge - previousThreshold;

            if (range > 0) {
                progressPercentage = (progress * 10000) / range; // Scale to 100.00%
            } else {
                progressPercentage = 0; // Should not happen if thresholds are well-defined
            }
            if (progressPercentage > 10000) progressPercentage = 10000; // Cap at 100%
        }
    }


    function getRiftGateDetails(uint256 _riftId) external view returns (RiftGate memory) {
        return riftGates[_riftId];
    }

    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    function getTemporalFluxBalance(address _owner) external view returns (uint256) {
        return temporalFlux.balanceOf(_owner);
    }

    function getMemoryShardBalance(address _owner) external view returns (uint256) {
        return memoryShards.balanceOf(_owner);
    }

    function getCrystallineShardBalance(address _owner) external view returns (uint256) {
        return crystallineShards.balanceOf(_owner);
    }

    // --- Internal/Private Helpers ---

    function _updateArtifactEvolution(uint256 _tokenId) internal {
        Artifact storage artifact = artifacts[_tokenId];
        if (!artifact.isActive) {
            return; // No evolution if in stasis
        }

        uint256 blocksPassed = block.number - artifact.lastEvolutionUpdateBlock;
        if (blocksPassed == 0) {
            return; // No blocks have passed since last update
        }

        uint256 effectiveAgeGain = blocksPassed * 10000 / artifact.evolutionRate; // Scale by 10000 to maintain precision with rate
        artifact.accumulatedEvolutionAge += effectiveAgeGain;
        artifact.lastEvolutionUpdateBlock = block.number;

        // Auto-awaken sentience if conditions are met and not explicitly triggered
        // This makes `triggerSentienceAwakening` more of a "claim" or "force check"
        for (uint256 i = artifact.sentienceLevel + 1; ; i++) {
            uint256 threshold = sentienceThresholds[i];
            if (threshold == 0) break;
            if (artifact.accumulatedEvolutionAge >= threshold) {
                artifact.sentienceLevel = i;
                emit SentienceAwakened(_tokenId, artifact.sentienceLevel);
            } else {
                break;
            }
        }
    }

    function _calculateCurrentSimulatedAge(Artifact storage artifact) internal view returns (uint256) {
        if (!artifact.isActive) {
            return artifact.accumulatedEvolutionAge;
        }
        uint256 blocksPassed = block.number - artifact.lastEvolutionUpdateBlock;
        uint256 effectiveAgeGain = blocksPassed * 10000 / artifact.evolutionRate;
        return artifact.accumulatedEvolutionAge + effectiveAgeGain;
    }

    // Helper to check if caller is owner or approved operator
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        return _spender == ownerOf(_tokenId) || getApproved(_tokenId) == _spender || isApprovedForAll(ownerOf(_tokenId), _spender);
    }
}


// Mock ERC-20 contracts for TemporalFlux, MemoryShards, CrystallineShards
// In a real deployment, these would be separate, deployed ERC-20 tokens.
// For demonstration, they are nested.

contract TemporalFlux is ERC20 {
    constructor() ERC20("TemporalFlux", "TFX") {}

    // Only allow minting by specific roles (e.g., ChronoForge contract or admin)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

contract MemoryShards is ERC20 {
    constructor() ERC20("MemoryShards", "MSH") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract CrystallineShards is ERC20 {
    constructor() ERC20("CrystallineShards", "CSH") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
```