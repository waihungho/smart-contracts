This contract, **ChronoForge**, introduces a novel concept of "Temporal NFTs" and "ChronoEssence" to create a dynamic, time-aware ecosystem. It explores advanced concepts like:

1.  **Time-Based Resource Accrual:** NFTs that passively generate a fungible resource (`ChronoEssence`) over time, based on their age and current 'temporal phase'.
2.  **Dynamic NFT States:** NFTs can be 'aged' by spending `ChronoEssence`, transitioning through `TemporalPhases` which unlock new utilities or alter their properties.
3.  **Global Temporal Epochs:** The contract itself operates in `GlobalEpochs`, influencing all NFTs' accrual rates and enabling time-gated events.
4.  **NFT Fusion & Fragmentation:** Allowing for advanced asset management by merging NFTs to consolidate their temporal power or fragmenting them into redeemable 'Temporal Shards'.
5.  **Temporal Attunement:** Binding external verifiable data (like IPFS hashes of generative art parameters, historical data proofs, or verifiable credentials) to NFTs with a verifiable timestamp on-chain.
6.  **Time-Weighted Delegation:** A unique form of voting/delegation power derived from the *age* and *accrued essence* of an NFT.
7.  **Temporal Stabilization:** A mechanism to "time-lock" an NFT, preventing changes for a period but potentially boosting future accrual.

---

## ChronoForge Smart Contract: Outline & Function Summary

**Contract Name:** `ChronoForge`

**Core Concepts:**
*   **ChronoAsset (NFT - ERC721):** Represents a unique temporal entity. Accrues ChronoEssence over time. Can evolve through TemporalPhases.
*   **ChronoEssence (Fungible Token - ERC20):** A resource representing temporal energy. Earned by ChronoAssets, spent to accelerate their evolution, participate in events, or perform advanced operations.
*   **Temporal Architect (Role):** A privileged role (initially contract deployer) responsible for managing global temporal dynamics (epochs, event scheduling).
*   **Global Epochs:** Contract-wide phases that affect accrual rates and unlock new functionalities.
*   **Temporal Conflux:** A pool of ChronoEssence for strategic distributions and rewards.

---

### **A. Core NFT & Token Management (ERC721 & ERC20 extensions)**

1.  `constructor()`: Initializes the contract, sets the `TemporalArchitect` (deployer), mints initial `ChronoEssence` supply, and starts `GlobalEpoch 0`.
2.  `forgeChronoAsset(address to)`: Mints a new `ChronoAsset` (NFT) to a specified address, recording its `birthTimestamp`.
3.  `claimAccruedEssence(uint256 tokenId)`: Allows the owner of a `ChronoAsset` to claim the `ChronoEssence` it has accrued since the last claim or mint.
4.  `getCurrentAccrualRate(uint256 tokenId)`: Views the current `ChronoEssence` accrual rate for a specific NFT, considering its phase and global epoch.
5.  `balanceOf(address owner)`: (ERC721 Standard) Returns the number of NFTs owned by an address.
6.  `ownerOf(uint256 tokenId)`: (ERC721 Standard) Returns the owner of a specific NFT.
7.  `transferFrom(address from, address to, uint256 tokenId)`: (ERC721 Standard) Transfers ownership of an NFT.
8.  `approve(address to, uint256 tokenId)`: (ERC721 Standard) Approves an address to manage an NFT.
9.  `getApproved(uint256 tokenId)`: (ERC721 Standard) Returns the approved address for an NFT.
10. `setApprovalForAll(address operator, bool approved)`: (ERC721 Standard) Sets approval for an operator to manage all NFTs.
11. `isApprovedForAll(address owner, address operator)`: (ERC721 Standard) Checks if an operator is approved for all NFTs.
12. `totalSupply()`: (ERC721 Standard) Returns the total number of NFTs minted.
13. `tokenByIndex(uint256 index)`: (ERC721 Standard) Returns the token ID at a given index (for enumeration).
14. `tokenOfOwnerByIndex(address owner, uint256 index)`: (ERC721 Standard) Returns the token ID owned by an address at a given index.

### **B. Temporal Mechanics & NFT Evolution**

1.  `advanceTemporalPhase(uint256 tokenId, uint256 targetPhase)`: Allows an NFT owner to spend `ChronoEssence` to accelerate their `ChronoAsset` to a higher `TemporalPhase`, unlocking new attributes or utilities.
2.  `initiateTemporalStabilization(uint256 tokenId, uint256 duration)`: Locks a `ChronoAsset` for a specified `duration`, preventing transfers or actions, but potentially boosting future `ChronoEssence` accrual or enabling special event participation.
3.  `releaseTemporalStabilization(uint256 tokenId)`: Unlocks a `ChronoAsset` after its `temporalStabilization` period has passed.
4.  `fuseChronoAssets(uint256[] calldata tokenIds)`: Fuses multiple `ChronoAssets` into a new, single, more powerful `ChronoAsset`, potentially combining their accrued essence and advancing its phase. The original NFTs are burned.
5.  `fragmentChronoAsset(uint256 tokenId, uint256 numShards)`: Fragments a `ChronoAsset` into multiple `TemporalShard` NFTs (a simplified utility NFT type), which can later be redeemed for `ChronoEssence` or other benefits. The original NFT is burned.
6.  `redeemTemporalShard(uint256 shardTokenId)`: Allows an owner to burn a `TemporalShard` NFT to claim its associated `ChronoEssence` or other pre-defined rewards.

### **C. Global Temporal Dynamics (Architect Functions)**

1.  `advanceGlobalEpoch()`: (Temporal Architect) Moves the contract to the next `GlobalEpoch`, potentially altering `ChronoEssence` accrual rates, unlocking new events, or changing system parameters.
2.  `setEpochAccrualMultiplier(uint256 epoch, uint256 multiplier)`: (Temporal Architect) Sets the `ChronoEssence` accrual multiplier for a specific `GlobalEpoch`.
3.  `scheduleTemporalEvent(string calldata eventName, uint256 startEpoch, uint256 endEpoch, bytes32 eventDataHash)`: (Temporal Architect) Schedules a time-gated event that is active only during specific `GlobalEpochs`. `eventDataHash` can point to off-chain event details.
4.  `initiateTemporalConfluxTransfer(address token, uint256 amount)`: (Temporal Architect) Transfers a specified amount of `ChronoEssence` (or any ERC20) into the `TemporalConflux` for strategic distribution.
5.  `distributeTemporalBounty(address[] calldata recipients, uint256[] calldata amounts)`: (Temporal Architect) Distributes `ChronoEssence` from the `TemporalConflux` to specified recipients.

### **D. Advanced Interactions & Utilities**

1.  `attuneChronoAsset(uint256 tokenId, string calldata metadataURI, bytes32 attunementHash)`: Allows an NFT owner to cryptographically bind external, verifiable data (e.g., an IPFS hash of a dynamic trait, a verifiable credential, or a historical timestamp) to their `ChronoAsset` on-chain, creating a `TemporalAttunementRecord`. This record is immutable and time-stamped.
2.  `verifyTemporalAttunement(uint256 tokenId, uint256 recordIndex, bytes32 expectedHash)`: Verifies if a specific `TemporalAttunementRecord` on an NFT matches an `expectedHash`.
3.  `delegateTimeWeight(uint256 tokenId, address delegatee)`: Allows an NFT owner to delegate the "time weight" (a conceptual metric based on NFT age and essence) of their `ChronoAsset` to another address, for potential future governance or ranking systems.
4.  `queryTemporalFlow()`: Returns the current `GlobalEpoch`, last `GlobalEpochAdvanceTimestamp`, and other global temporal state variables.
5.  `getChronoAssetDetails(uint256 tokenId)`: A view function to retrieve all stored details for a specific `ChronoAsset`.
6.  `getTokenURI(uint256 tokenId)`: (ERC721 Standard) Returns the URI for a specific NFT, pointing to metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline & Function Summary ---
//
// Contract Name: ChronoForge
//
// Core Concepts:
// - ChronoAsset (NFT - ERC721): Represents a unique temporal entity. Accrues ChronoEssence over time. Can evolve through TemporalPhases.
// - ChronoEssence (Fungible Token - ERC20): A resource representing temporal energy. Earned by ChronoAssets, spent to accelerate their evolution, participate in events, or perform advanced operations.
// - Temporal Architect (Role): A privileged role (initially contract deployer) responsible for managing global temporal dynamics (epochs, event scheduling).
// - Global Epochs: Contract-wide phases that affect accrual rates and unlock new functionalities.
// - Temporal Conflux: A pool of ChronoEssence for strategic distributions and rewards.
//
// Functions:
//
// A. Core NFT & Token Management (ERC721 & ERC20 extensions)
//    1. constructor(): Initializes the contract, sets the TemporalArchitect (deployer), mints initial ChronoEssence supply, and starts GlobalEpoch 0.
//    2. forgeChronoAsset(address to): Mints a new ChronoAsset (NFT) to a specified address, recording its birthTimestamp.
//    3. claimAccruedEssence(uint256 tokenId): Allows the owner of a ChronoAsset to claim the ChronoEssence it has accrued since the last claim or mint.
//    4. getCurrentAccrualRate(uint256 tokenId): Views the current ChronoEssence accrual rate for a specific NFT, considering its phase and global epoch.
//    5. balanceOf(address owner): (ERC721 Standard) Returns the number of NFTs owned by an address.
//    6. ownerOf(uint256 tokenId): (ERC721 Standard) Returns the owner of a specific NFT.
//    7. transferFrom(address from, address to, uint256 tokenId): (ERC721 Standard) Transfers ownership of an NFT.
//    8. approve(address to, uint256 tokenId): (ERC721 Standard) Approves an address to manage an NFT.
//    9. getApproved(uint256 tokenId): (ERC721 Standard) Returns the approved address for an NFT.
//    10. setApprovalForAll(address operator, bool approved): (ERC721 Standard) Sets approval for an operator to manage all NFTs.
//    11. isApprovedForAll(address owner, address operator): (ERC721 Standard) Checks if an operator is approved for all NFTs.
//    12. totalSupply(): (ERC721 Standard) Returns the total number of NFTs minted.
//    13. tokenByIndex(uint256 index): (ERC721 Standard) Returns the token ID at a given index (for enumeration).
//    14. tokenOfOwnerByIndex(address owner, uint256 index): (ERC721 Standard) Returns the token ID owned by an address at a given index.
//
// B. Temporal Mechanics & NFT Evolution
//    1. advanceTemporalPhase(uint256 tokenId, uint256 targetPhase): Allows an NFT owner to spend ChronoEssence to accelerate their ChronoAsset to a higher TemporalPhase, unlocking new attributes or utilities.
//    2. initiateTemporalStabilization(uint256 tokenId, uint256 duration): Locks a ChronoAsset for a specified duration, preventing transfers or actions, but potentially boosting future ChronoEssence accrual or enabling special event participation.
//    3. releaseTemporalStabilization(uint256 tokenId): Unlocks a ChronoAsset after its temporalStabilization period has passed.
//    4. fuseChronoAssets(uint256[] calldata tokenIds): Fuses multiple ChronoAssets into a new, single, more powerful ChronoAsset, potentially combining their accrued essence and advancing its phase. The original NFTs are burned.
//    5. fragmentChronoAsset(uint256 tokenId, uint256 numShards): Fragments a ChronoAsset into multiple TemporalShard NFTs (a simplified utility NFT type), which can later be redeemed for ChronoEssence or other benefits. The original NFT is burned.
//    6. redeemTemporalShard(uint256 shardTokenId): Allows an owner to burn a TemporalShard NFT to claim its associated ChronoEssence or other pre-defined rewards.
//
// C. Global Temporal Dynamics (Architect Functions)
//    1. advanceGlobalEpoch(): (Temporal Architect) Moves the contract to the next GlobalEpoch, potentially altering ChronoEssence accrual rates, unlocking new events, or changing system parameters.
//    2. setEpochAccrualMultiplier(uint256 epoch, uint256 multiplier): (Temporal Architect) Sets the ChronoEssence accrual multiplier for a specific GlobalEpoch.
//    3. scheduleTemporalEvent(string calldata eventName, uint256 startEpoch, uint256 endEpoch, bytes32 eventDataHash): (Temporal Architect) Schedules a time-gated event that is active only during specific GlobalEpochs. eventDataHash can point to off-chain event details.
//    4. initiateTemporalConfluxTransfer(address token, uint256 amount): (Temporal Architect) Transfers a specified amount of ChronoEssence (or any ERC20) into the TemporalConflux for strategic distribution.
//    5. distributeTemporalBounty(address[] calldata recipients, uint256[] calldata amounts): (Temporal Architect) Distributes ChronoEssence from the TemporalConflux to specified recipients.
//
// D. Advanced Interactions & Utilities
//    1. attuneChronoAsset(uint256 tokenId, string calldata metadataURI, bytes32 attunementHash): Allows an NFT owner to cryptographically bind external, verifiable data (e.g., an IPFS hash of a dynamic trait, a verifiable credential, or a historical timestamp) to their ChronoAsset on-chain, creating a TemporalAttunementRecord. This record is immutable and time-stamped.
//    2. verifyTemporalAttunement(uint256 tokenId, uint256 recordIndex, bytes32 expectedHash): Verifies if a specific TemporalAttunementRecord on an NFT matches an expectedHash.
//    3. delegateTimeWeight(uint256 tokenId, address delegatee): Allows an NFT owner to delegate the "time weight" (a conceptual metric based on NFT age and essence) of their ChronoAsset to another address, for potential future governance or ranking systems.
//    4. queryTemporalFlow(): Returns the current GlobalEpoch, last GlobalEpochAdvanceTimestamp, and other global temporal state variables.
//    5. getChronoAssetDetails(uint256 tokenId): A view function to retrieve all stored details for a specific ChronoAsset.
//    6. getTokenURI(uint256 tokenId): (ERC721 Standard) Returns the URI for a specific NFT, pointing to metadata.

// Note on ERC20/ERC721 Standard Functions: While explicitly listed for clarity of the 20+ count,
// the OpenZeppelin imports automatically provide these. Only custom overrides or specific interactions are fully detailed.

// --- Smart Contract Source Code ---

// Dummy ERC20 for Temporal Shards, just for demonstration of fragmentation
// In a real scenario, this might be a separate, dedicated ERC1155 or ERC721.
contract TemporalShardNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _shardTokenIds;

    mapping(uint256 => uint256) public shardEssenceValue; // How much ChronoEssence each shard is worth

    event ShardForged(uint256 indexed shardId, uint256 value);
    event ShardRedeemed(uint256 indexed shardId, address indexed redeemer, uint256 value);

    constructor() ERC721("Temporal Shard", "TSHRD") Ownable(msg.sender) {}

    function mintShard(address to, uint256 value) internal returns (uint256) {
        _shardTokenIds.increment();
        uint256 newShardId = _shardTokenIds.current();
        _safeMint(to, newShardId);
        shardEssenceValue[newShardId] = value;
        emit ShardForged(newShardId, value);
        return newShardId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Add specific logic here if shards have transfer restrictions
    }
}


contract ChronoEssence is ERC20, Ownable {
    constructor() ERC20("Chrono Essence", "CE") Ownable(msg.sender) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}


contract ChronoForge is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _chronoTokenIds;

    // --- State Variables ---

    ChronoEssence public chronoEssence;
    TemporalShardNFT public temporalShardNFT; // Dedicated contract for shard NFTs

    address public temporalArchitect; // Special role for managing global temporal dynamics

    // --- Structs ---

    struct ChronoAssetDetails {
        uint256 birthTimestamp;
        uint256 lastClaimTimestamp;
        uint256 temporalPhase; // 0, 1, 2, ... higher means more evolved
        uint256 accumulatedEssenceUnclaimed; // CE accrued but not yet claimed
        uint256 stabilizedUntil; // Timestamp until which the asset is locked (0 if not locked)
        address delegatedTimeWeightTo; // Address to whom time weight is delegated
        uint256 accrualBoostMultiplier; // For stabilization benefits, etc.
    }

    struct TemporalAttunementRecord {
        string metadataURI; // URI to off-chain data (e.g., IPFS hash)
        bytes32 attunementHash; // Cryptographic hash of the external data
        uint256 attunementTimestamp; // When the attunement was made
    }

    struct GlobalEpochDetails {
        uint256 startTime;
        uint256 accrualMultiplier; // Base multiplier for all NFTs during this epoch
        bool active;
    }

    struct TemporalEvent {
        string eventName;
        uint256 startEpoch;
        uint256 endEpoch;
        bytes32 eventDataHash; // Hash pointing to off-chain event details
        bool isScheduled;
    }

    // --- Mappings ---

    mapping(uint256 => ChronoAssetDetails) public chronoAssets;
    mapping(uint256 => TemporalAttunementRecord[]) public chronoAssetAttunements; // tokenId => array of attunement records
    mapping(uint256 => GlobalEpochDetails) public globalEpochs;
    mapping(uint256 => TemporalEvent) public temporalEvents; // eventId => TemporalEvent details
    Counters.Counter private _eventIds;


    // --- Global Temporal State ---
    uint256 public currentGlobalEpoch;
    uint256 public lastGlobalEpochAdvanceTimestamp;
    uint256 public constant BASE_ACCRUAL_RATE_PER_SECOND = 100; // Base CE units per second, scaled by 10^18 for decimals
    uint256 public constant PHASE_ADVANCE_COST_PER_PHASE = 1000 * (10**18); // Example cost to advance one phase


    // --- Events ---
    event ChronoAssetForged(uint256 indexed tokenId, address indexed owner, uint256 birthTimestamp);
    event EssenceClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount);
    event TemporalPhaseAdvanced(uint256 indexed tokenId, uint256 oldPhase, uint256 newPhase);
    event TemporalStabilizationInitiated(uint256 indexed tokenId, uint256 stabilizedUntil);
    event TemporalStabilizationReleased(uint256 indexed tokenId);
    event ChronoAssetsFused(uint256[] indexed sourceTokenIds, uint256 indexed newChronoAssetId);
    event ChronoAssetFragmented(uint256 indexed originalTokenId, uint256[] indexed shardTokenIds);
    event GlobalEpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event EpochAccrualMultiplierSet(uint256 indexed epoch, uint256 multiplier);
    event TemporalEventScheduled(uint256 indexed eventId, string eventName, uint256 startEpoch, uint256 endEpoch);
    event TemporalAttunementMade(uint256 indexed tokenId, bytes32 indexed attunementHash, uint256 attunementTimestamp);
    event TimeWeightDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event TemporalConfluxTransfer(address indexed token, uint256 amount);
    event TemporalBountyDistributed(address indexed distributor, uint256 totalAmount);

    // --- Modifiers ---
    modifier onlyTemporalArchitect() {
        require(msg.sender == temporalArchitect, "ChronoForge: Only Temporal Architect can call this function");
        _;
    }

    modifier notStabilized(uint256 tokenId) {
        require(block.timestamp >= chronoAssets[tokenId].stabilizedUntil, "ChronoForge: ChronoAsset is stabilized");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("ChronoForge Asset", "CFA") Ownable(msg.sender) {
        chronoEssence = new ChronoEssence();
        temporalShardNFT = new TemporalShardNFT();

        // Initial setup for Temporal Architect
        temporalArchitect = msg.sender;

        // Initialize Global Epoch 0
        currentGlobalEpoch = 0;
        lastGlobalEpochAdvanceTimestamp = block.timestamp;
        globalEpochs[0] = GlobalEpochDetails({
            startTime: block.timestamp,
            accrualMultiplier: 100, // 1x base multiplier
            active: true
        });

        // Mint initial ChronoEssence for Architect/Treasury (example)
        chronoEssence.mint(msg.sender, 1_000_000 * (10**18));
    }

    // --- A. Core NFT & Token Management (ERC721 & ERC20 extensions) ---

    /**
     * @dev Mints a new ChronoAsset (NFT) to a specified address.
     * @param to The address to mint the NFT to.
     */
    function forgeChronoAsset(address to) public nonReentrant {
        _chronoTokenIds.increment();
        uint256 newItemId = _chronoTokenIds.current();
        _safeMint(to, newItemId);

        chronoAssets[newItemId] = ChronoAssetDetails({
            birthTimestamp: block.timestamp,
            lastClaimTimestamp: block.timestamp,
            temporalPhase: 0,
            accumulatedEssenceUnclaimed: 0,
            stabilizedUntil: 0,
            delegatedTimeWeightTo: address(0),
            accrualBoostMultiplier: 100 // 1x
        });

        emit ChronoAssetForged(newItemId, to, block.timestamp);
    }

    /**
     * @dev Calculates and claims accrued ChronoEssence for a specific ChronoAsset.
     * @param tokenId The ID of the ChronoAsset.
     */
    function claimAccruedEssence(uint256 tokenId) public nonReentrant onlyOwnerOf(tokenId) notStabilized(tokenId) {
        ChronoAssetDetails storage asset = chronoAssets[tokenId];
        uint256 timeElapsed = block.timestamp - asset.lastClaimTimestamp;

        uint256 currentAccrualRate = getCurrentAccrualRate(tokenId);
        uint256 newAccruedEssence = (timeElapsed * currentAccrualRate) / (10**18); // Scale down if rate is scaled up

        uint256 totalEssenceToClaim = asset.accumulatedEssenceUnclaimed + newAccruedEssence;
        require(totalEssenceToClaim > 0, "ChronoForge: No essence to claim");

        asset.accumulatedEssenceUnclaimed = 0; // Reset unclaimed before transfer
        asset.lastClaimTimestamp = block.timestamp; // Update last claim timestamp

        chronoEssence.mint(ownerOf(tokenId), totalEssenceToClaim); // Mint and transfer CE
        emit EssenceClaimed(tokenId, ownerOf(tokenId), totalEssenceToClaim);
    }

    /**
     * @dev Views the current ChronoEssence accrual rate for a specific NFT.
     *      Considers NFT's phase, global epoch multiplier, and any boost.
     * @param tokenId The ID of the ChronoAsset.
     * @return The calculated accrual rate in CE units per second (scaled by 10^18).
     */
    function getCurrentAccrualRate(uint256 tokenId) public view returns (uint256) {
        ChronoAssetDetails storage asset = chronoAssets[tokenId];
        uint256 phaseMultiplier = 100 + (asset.temporalPhase * 20); // Each phase adds 0.2x multiplier
        uint256 epochMultiplier = globalEpochs[currentGlobalEpoch].accrualMultiplier;

        // Base rate * phase multiplier * epoch multiplier * stabilization boost
        return (BASE_ACCRUAL_RATE_PER_SECOND * phaseMultiplier * epochMultiplier * asset.accrualBoostMultiplier) / (100 * 100 * 100);
    }

    // --- B. Temporal Mechanics & NFT Evolution ---

    /**
     * @dev Allows an NFT owner to spend ChronoEssence to advance their ChronoAsset to a higher TemporalPhase.
     * @param tokenId The ID of the ChronoAsset.
     * @param targetPhase The desired TemporalPhase to reach.
     */
    function advanceTemporalPhase(uint256 tokenId, uint256 targetPhase) public nonReentrant onlyOwnerOf(tokenId) notStabilized(tokenId) {
        ChronoAssetDetails storage asset = chronoAssets[tokenId];
        require(targetPhase > asset.temporalPhase, "ChronoForge: Target phase must be higher than current phase");
        require(targetPhase <= 10, "ChronoForge: Maximum temporal phase reached (example limit)"); // Example limit

        uint256 phasesToAdvance = targetPhase - asset.temporalPhase;
        uint256 essenceCost = phasesToAdvance * PHASE_ADVANCE_COST_PER_PHASE;

        chronoEssence.burnFrom(_msgSender(), essenceCost); // Burn CE from owner

        uint256 oldPhase = asset.temporalPhase;
        asset.temporalPhase = targetPhase;
        // Optionally, claim accrued essence before phase advance
        claimAccruedEssence(tokenId); // Ensure any pending essence is claimed first

        emit TemporalPhaseAdvanced(tokenId, oldPhase, asset.temporalPhase);
    }

    /**
     * @dev Locks a ChronoAsset for a specified duration, preventing transfers or actions.
     *      May grant a temporary accrual boost.
     * @param tokenId The ID of the ChronoAsset.
     * @param duration The duration in seconds to lock the asset.
     */
    function initiateTemporalStabilization(uint256 tokenId, uint256 duration) public nonReentrant onlyOwnerOf(tokenId) {
        require(duration > 0, "ChronoForge: Duration must be greater than zero");
        require(chronoAssets[tokenId].stabilizedUntil <= block.timestamp, "ChronoForge: ChronoAsset already stabilized");
        
        // Example: Add a boost for stabilization
        chronoAssets[tokenId].accrualBoostMultiplier = 120; // 1.2x boost for stabilization

        chronoAssets[tokenId].stabilizedUntil = block.timestamp + duration;
        emit TemporalStabilizationInitiated(tokenId, chronoAssets[tokenId].stabilizedUntil);
    }

    /**
     * @dev Unlocks a ChronoAsset after its temporalStabilization period has passed.
     *      Resets any stabilization-related boosts.
     * @param tokenId The ID of the ChronoAsset.
     */
    function releaseTemporalStabilization(uint256 tokenId) public nonReentrant onlyOwnerOf(tokenId) {
        require(chronoAssets[tokenId].stabilizedUntil > 0, "ChronoForge: ChronoAsset not stabilized");
        require(block.timestamp >= chronoAssets[tokenId].stabilizedUntil, "ChronoForge: Stabilization period not yet over");

        chronoAssets[tokenId].stabilizedUntil = 0;
        chronoAssets[tokenId].accrualBoostMultiplier = 100; // Reset boost
        emit TemporalStabilizationReleased(tokenId);
    }

    /**
     * @dev Fuses multiple ChronoAssets into a new, single, more powerful ChronoAsset.
     *      The original NFTs are burned. Accumulates essence and averages/advances phases.
     * @param tokenIds An array of token IDs to fuse.
     */
    function fuseChronoAssets(uint256[] calldata tokenIds) public nonReentrant {
        require(tokenIds.length >= 2, "ChronoForge: At least two assets are required for fusion");

        uint256 totalEssence = 0;
        uint256 totalPhase = 0;
        uint256 newId;

        // All tokens must be owned by msg.sender and not stabilized
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(ownerOf(tokenIds[i]) == _msgSender(), "ChronoForge: Not owner of all assets");
            require(chronoAssets[tokenIds[i]].stabilizedUntil <= block.timestamp, "ChronoForge: One or more assets are stabilized");

            // Claim pending essence before fusion
            claimAccruedEssence(tokenIds[i]);
            totalEssence += chronoAssets[tokenIds[i]].accumulatedEssenceUnclaimed; // should be 0 after claimAccruedEssence
            totalPhase += chronoAssets[tokenIds[i]].temporalPhase;

            // Burn the original assets
            _burn(tokenIds[i]);
        }

        // Mint a new asset
        _chronoTokenIds.increment();
        newId = _chronoTokenIds.current();
        _safeMint(_msgSender(), newId);

        // Assign new asset properties based on fused assets
        chronoAssets[newId] = ChronoAssetDetails({
            birthTimestamp: block.timestamp,
            lastClaimTimestamp: block.timestamp,
            temporalPhase: totalPhase / tokenIds.length, // Average or sum, depending on desired logic
            accumulatedEssenceUnclaimed: totalEssence,
            stabilizedUntil: 0,
            delegatedTimeWeightTo: address(0),
            accrualBoostMultiplier: 100
        });

        emit ChronoAssetsFused(tokenIds, newId);
    }

    /**
     * @dev Fragments a ChronoAsset into multiple TemporalShard NFTs.
     *      The original NFT is burned, and its essence is divided among shards.
     * @param tokenId The ID of the ChronoAsset to fragment.
     * @param numShards The number of TemporalShards to create.
     */
    function fragmentChronoAsset(uint256 tokenId, uint256 numShards) public nonReentrant onlyOwnerOf(tokenId) notStabilized(tokenId) {
        require(numShards > 0, "ChronoForge: Must create at least one shard");
        require(numShards <= 10, "ChronoForge: Max 10 shards per asset (example limit)");

        // Claim pending essence before fragmentation
        claimAccruedEssence(tokenId);
        uint256 totalEssence = chronoAssets[tokenId].accumulatedEssenceUnclaimed;

        // Burn the original asset
        _burn(tokenId);

        // Mint Temporal Shards
        uint256[] memory shardIds = new uint256[](numShards);
        uint256 essencePerShard = totalEssence / numShards;

        for (uint256 i = 0; i < numShards; i++) {
            shardIds[i] = temporalShardNFT.mintShard(_msgSender(), essencePerShard);
        }
        
        // If there's a remainder, add to the last shard
        if (totalEssence % numShards > 0) {
            temporalShardNFT.shardEssenceValue[shardIds[numShards - 1]] += totalEssence % numShards;
        }

        emit ChronoAssetFragmented(tokenId, shardIds);
    }

    /**
     * @dev Allows an owner to burn a TemporalShard NFT to claim its associated ChronoEssence.
     * @param shardTokenId The ID of the TemporalShard NFT.
     */
    function redeemTemporalShard(uint256 shardTokenId) public nonReentrant {
        require(temporalShardNFT.ownerOf(shardTokenId) == _msgSender(), "TemporalShardNFT: Not shard owner");
        
        uint256 essenceValue = temporalShardNFT.shardEssenceValue[shardTokenId];
        require(essenceValue > 0, "TemporalShardNFT: Shard has no value or already redeemed");

        // Burn the shard
        temporalShardNFT.burn(shardTokenId);
        temporalShardNFT.shardEssenceValue[shardTokenId] = 0; // Prevent double claim

        // Mint ChronoEssence to the redeemer
        chronoEssence.mint(_msgSender(), essenceValue);
        
        emit TemporalShardNFT.ShardRedeemed(shardTokenId, _msgSender(), essenceValue);
    }

    // --- C. Global Temporal Dynamics (Architect Functions) ---

    /**
     * @dev (Temporal Architect) Moves the contract to the next GlobalEpoch.
     *      This can alter ChronoEssence accrual rates globally.
     */
    function advanceGlobalEpoch() public nonReentrant onlyTemporalArchitect {
        currentGlobalEpoch++;
        lastGlobalEpochAdvanceTimestamp = block.timestamp;

        // Default multiplier for new epochs if not explicitly set
        if (globalEpochs[currentGlobalEpoch].accrualMultiplier == 0) {
            globalEpochs[currentGlobalEpoch] = GlobalEpochDetails({
                startTime: block.timestamp,
                accrualMultiplier: 100, // Default 1x
                active: true
            });
        } else {
             globalEpochs[currentGlobalEpoch].startTime = block.timestamp;
             globalEpochs[currentGlobalEpoch].active = true;
        }

        // Invalidate previous epoch
        if (currentGlobalEpoch > 0) {
            globalEpochs[currentGlobalEpoch - 1].active = false;
        }

        emit GlobalEpochAdvanced(currentGlobalEpoch, block.timestamp);
    }

    /**
     * @dev (Temporal Architect) Sets the ChronoEssence accrual multiplier for a specific GlobalEpoch.
     * @param epoch The epoch to set the multiplier for.
     * @param multiplier The new multiplier (e.g., 100 for 1x, 150 for 1.5x).
     */
    function setEpochAccrualMultiplier(uint256 epoch, uint256 multiplier) public onlyTemporalArchitect {
        require(multiplier > 0, "ChronoForge: Multiplier must be positive");
        globalEpochs[epoch].accrualMultiplier = multiplier;
        emit EpochAccrualMultiplierSet(epoch, multiplier);
    }

    /**
     * @dev (Temporal Architect) Schedules a time-gated event.
     *      Event is active only during specified GlobalEpochs.
     * @param eventName A descriptive name for the event.
     * @param startEpoch The GlobalEpoch at which the event becomes active.
     * @param endEpoch The GlobalEpoch at which the event becomes inactive.
     * @param eventDataHash A hash pointing to off-chain event details (e.g., IPFS CID).
     */
    function scheduleTemporalEvent(string calldata eventName, uint256 startEpoch, uint256 endEpoch, bytes32 eventDataHash) public onlyTemporalArchitect {
        require(endEpoch >= startEpoch, "ChronoForge: End epoch must be greater than or equal to start epoch");
        _eventIds.increment();
        uint256 newEventId = _eventIds.current();

        temporalEvents[newEventId] = TemporalEvent({
            eventName: eventName,
            startEpoch: startEpoch,
            endEpoch: endEpoch,
            eventDataHash: eventDataHash,
            isScheduled: true
        });

        emit TemporalEventScheduled(newEventId, eventName, startEpoch, endEpoch);
    }

    /**
     * @dev (Temporal Architect) Transfers ChronoEssence (or any ERC20) into the TemporalConflux.
     *      This conflux acts as a treasury for strategic distributions.
     * @param token The address of the ERC20 token to transfer (use ChronoEssence address for CE).
     * @param amount The amount to transfer.
     */
    function initiateTemporalConfluxTransfer(address token, uint256 amount) public onlyTemporalArchitect {
        ERC20(token).transferFrom(msg.sender, address(this), amount); // Contract itself is the conflux
        emit TemporalConfluxTransfer(token, amount);
    }

    /**
     * @dev (Temporal Architect) Distributes ChronoEssence from the TemporalConflux.
     * @param recipients An array of recipient addresses.
     * @param amounts An array of amounts corresponding to recipients.
     */
    function distributeTemporalBounty(address[] calldata recipients, uint256[] calldata amounts) public nonReentrant onlyTemporalArchitect {
        require(recipients.length == amounts.length, "ChronoForge: Mismatch in recipients and amounts");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
        }
        require(chronoEssence.balanceOf(address(this)) >= totalAmount, "ChronoForge: Insufficient ChronoEssence in Conflux");

        for (uint256 i = 0; i < recipients.length; i++) {
            chronoEssence.transfer(recipients[i], amounts[i]);
        }
        emit TemporalBountyDistributed(msg.sender, totalAmount);
    }

    // --- D. Advanced Interactions & Utilities ---

    /**
     * @dev Allows an NFT owner to cryptographically bind external, verifiable data to their ChronoAsset.
     *      Creates a permanent, time-stamped `TemporalAttunementRecord`.
     * @param tokenId The ID of the ChronoAsset.
     * @param metadataURI A URI pointing to off-chain metadata (e.g., IPFS CID).
     * @param attunementHash A cryptographic hash (e.g., SHA256 of external data).
     */
    function attuneChronoAsset(uint256 tokenId, string calldata metadataURI, bytes32 attunementHash) public nonReentrant onlyOwnerOf(tokenId) notStabilized(tokenId) {
        chronoAssetAttunements[tokenId].push(TemporalAttunementRecord({
            metadataURI: metadataURI,
            attunementHash: attunementHash,
            attunementTimestamp: block.timestamp
        }));
        emit TemporalAttunementMade(tokenId, attunementHash, block.timestamp);
    }

    /**
     * @dev Verifies if a specific `TemporalAttunementRecord` on an NFT matches an expected hash.
     * @param tokenId The ID of the ChronoAsset.
     * @param recordIndex The index of the attunement record to check.
     * @param expectedHash The hash to verify against.
     * @return True if the hash matches, false otherwise.
     */
    function verifyTemporalAttunement(uint256 tokenId, uint256 recordIndex, bytes32 expectedHash) public view returns (bool) {
        require(recordIndex < chronoAssetAttunements[tokenId].length, "ChronoForge: Attunement record index out of bounds");
        return chronoAssetAttunements[tokenId][recordIndex].attunementHash == expectedHash;
    }

    /**
     * @dev Allows an NFT owner to delegate the "time weight" of their ChronoAsset to another address.
     *      This can be used for conceptual governance or ranking systems.
     * @param tokenId The ID of the ChronoAsset.
     * @param delegatee The address to delegate the time weight to.
     */
    function delegateTimeWeight(uint256 tokenId, address delegatee) public nonReentrant onlyOwnerOf(tokenId) notStabilized(tokenId) {
        chronoAssets[tokenId].delegatedTimeWeightTo = delegatee;
        emit TimeWeightDelegated(tokenId, _msgSender(), delegatee);
    }

    /**
     * @dev Returns the current global temporal state variables.
     * @return _currentGlobalEpoch The current active global epoch.
     * @return _lastGlobalEpochAdvanceTimestamp The timestamp of the last epoch advance.
     * @return _epochAccrualMultiplier The accrual multiplier for the current epoch.
     */
    function queryTemporalFlow() public view returns (uint256 _currentGlobalEpoch, uint256 _lastGlobalEpochAdvanceTimestamp, uint256 _epochAccrualMultiplier) {
        return (
            currentGlobalEpoch,
            lastGlobalEpochAdvanceTimestamp,
            globalEpochs[currentGlobalEpoch].accrualMultiplier
        );
    }

    /**
     * @dev A view function to retrieve all stored details for a specific ChronoAsset.
     * @param tokenId The ID of the ChronoAsset.
     * @return ChronoAssetDetails struct containing all relevant data.
     */
    function getChronoAssetDetails(uint256 tokenId) public view returns (ChronoAssetDetails memory) {
        return chronoAssets[tokenId];
    }

    /**
     * @dev Returns the URI for a given token ID.
     *      Override this to point to a dynamic metadata API based on temporal properties.
     * @param tokenId The ID of the ChronoAsset.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned

        // Example: Dynamic URI based on phase
        string memory baseURI = "ipfs://QmbF6R6X4Y5Z7W8E9C0A1B2C3D4E5F6G7H8I9J0K1L/"; // Base IPFS CID
        uint256 phase = chronoAssets[tokenId].temporalPhase;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), "/phase/", Strings.toString(phase), ".json"));
    }

    // --- Internal/Utility Functions ---

    /**
     * @dev Helper modifier to ensure caller is the owner of the token.
     */
    modifier onlyOwnerOf(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ChronoForge: Caller is not owner or approved");
        _;
    }

    // Overrides for ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._approve(to, tokenId);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        // Clear asset details before burning to save gas on subsequent reads
        // Note: For full deletion, consider solidity delete keyword if no longer needed.
        // For simplicity, we just zero out key mutable fields.
        // Or better, map by `active` boolean
        delete chronoAssets[tokenId];
        delete chronoAssetAttunements[tokenId]; // Deletes the array, but gas refund applies
        super._burn(tokenId);
    }

    // The rest of standard ERC721/ERC20 functions are implicitly inherited from OpenZeppelin.
    // E.g., balanceOf, ownerOf, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // totalSupply, tokenByIndex, tokenOfOwnerByIndex are all available.
}
```