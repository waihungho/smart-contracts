Okay, let's design a creative and somewhat complex smart contract centered around a decentralized crafting and progression system, integrating unique asset types managed internally. We'll call it the "Aetherium Forge."

It involves:
1.  **Alchemists:** Users who participate.
2.  **Essences:** Fungible, soulbound internal tokens (cannot be transferred between users after initial distribution).
3.  **Shards:** Non-fungible internal assets (can be transferred between users *before* crafting).
4.  **Artifacts:** Non-fungible, potentially dynamic internal assets created by crafting.
5.  **Recipes:** Define input Essences/Shards needed to craft output Artifacts/Essences.
6.  **Progression:** Alchemists gain XP and Ranks by crafting. Recipes can have rank requirements.
7.  **Temporal Rifts:** Time-limited events granting unique opportunities or challenges.

This avoids standard ERC20/ERC721 inheritance directly by managing asset state internally, implements a crafting system (consumes assets, creates new ones), includes soulbinding logic, XP/ranking, and timed events.

---

**Aetherium Forge Smart Contract**

**Outline:**

1.  **Contract Definition:** Pragma, license, custom errors.
2.  **Ownership:** Basic owner management.
3.  **Structs:**
    *   `Alchemist`: User profile (XP, rank, unlocked recipes).
    *   `EssenceDetails`: Metadata for an essence type.
    *   `ShardDetails`: Metadata for a shard type.
    *   `ArtifactDetails`: Metadata for an artifact type (base).
    *   `CraftedArtifactData`: Specific data for a *minted instance* of an artifact (dynamic part).
    *   `Recipe`: Defines inputs (Essences/Shards) and outputs (Artifacts/Essences) for crafting.
    *   `TemporalRift`: Details for a timed event (requirements, rewards, status).
4.  **State Variables:** Mappings for users, assets, recipes, rifts, counters, configuration.
5.  **Events:** For key actions (Crafting, Minting, Essence Transfer, Rank Change, Rift Started/Completed).
6.  **Modifiers:** `onlyOwner`, `onlyRegisteredAlchemist`.
7.  **Constructor:** Initializes owner.
8.  **Admin Functions (Config & Setup):**
    *   Set up item types (Essences, Shards, Artifacts).
    *   Add/Remove recipes.
    *   Grant initial/admin-controlled assets.
    *   Set XP rank thresholds.
    *   Manage Temporal Rifts.
    *   Set metadata base URIs.
9.  **Core Logic Functions (User Actions):**
    *   Register as an Alchemist.
    *   Transfer Shards (between Alchemists).
    *   Check if a recipe can be forged.
    *   Forge an artifact (consumes inputs, grants outputs & XP).
    *   Claim Temporal Rift reward.
    *   Redeem crafted Artifacts for Essences (utility function).
10. **View/Getter Functions (Information Retrieval):**
    *   Get Alchemist details.
    *   Get asset balances/ownership.
    *   Get item details (Essence, Shard, Artifact type info).
    *   Get specific crafted Artifact data.
    *   Get Recipe details.
    *   Get Temporal Rift details.
    *   Check Alchemist rank.
    *   Check asset supply.

**Function Summary (Total: 30 functions)**

1.  `constructor()`: Initializes the contract owner.
2.  `registerAlchemist()`: Allows a user to become a registered Alchemist.
3.  `setEssenceDetails(uint256 _essenceTypeId, string memory _name, string memory _symbol)`: Owner sets metadata for an Essence type.
4.  `setShardDetails(uint256 _shardTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI)`: Owner sets metadata for a Shard type and its base URI.
5.  `setArtifactDetails(uint256 _artifactTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI)`: Owner sets metadata for an Artifact type and its base URI.
6.  `addForgingRecipe(...)`: Owner adds a new crafting recipe.
7.  `removeForgingRecipe(uint256 _recipeId)`: Owner removes an existing recipe.
8.  `setMinAlchemistRankToForge(uint256 _recipeId, uint256 _minRank)`: Owner sets minimum rank requirement for a recipe.
9.  `grantEssence(address _to, uint256 _essenceTypeId, uint256 _amount)`: Owner grants a specific amount of Essence to an address (initial distribution/rewards).
10. `grantShard(address _to, uint256 _shardTypeId, uint256 _amount)`: Owner grants multiple instances of a Shard type to an address.
11. `grantArtifact(address _to, uint256 _artifactTypeId, bytes memory _craftedAttributes)`: Owner grants a specific Artifact instance to an address (e.g., for special rewards).
12. `transferShard(address _from, address _to, uint256 _shardTokenId)`: Allows a Shard owner to transfer a specific Shard instance *before* it's used in crafting.
13. `startTemporalRift(...)`: Owner initiates a time-limited Temporal Rift event.
14. `endTemporalRift(uint256 _riftId)`: Owner manually ends a Temporal Rift.
15. `setAlchemistRankThresholds(uint256[] memory _xpThresholds)`: Owner sets the XP required for each Alchemist rank.
16. `checkRecipeAvailability(address _alchemist, uint256 _recipeId)`: Checks if an alchemist meets the requirements (rank, ingredients) to forge a recipe (view function).
17. `forgeArtifact(uint256 _recipeId)`: Executes the crafting process for a given recipe if the caller is a registered Alchemist and meets requirements. Consumes inputs, mints outputs, awards XP.
18. `claimTemporalRiftReward(uint256 _riftId)`: Allows an Alchemist who met rift conditions to claim its reward (requires separate mechanism to track completion, simplified here).
19. `redeemArtifactForEssence(uint256 _artifactTokenId)`: Allows an Artifact owner to burn it in exchange for a predetermined amount of a specific Essence type.
20. `getAlchemistDetails(address _alchemist)`: View Alchemist's XP and rank.
21. `getEssenceBalance(address _alchemist, uint256 _essenceTypeId)`: View an Alchemist's balance of a specific Essence type.
22. `getOwnedShards(address _alchemist, uint256 _shardTypeId)`: List the token IDs of a specific Shard type owned by an Alchemist.
23. `getOwnedArtifacts(address _alchemist, uint256 _artifactTypeId)`: List the token IDs of a specific Artifact type owned by an Alchemist.
24. `getRecipeDetails(uint256 _recipeId)`: View details of a crafting recipe.
25. `getEssenceDetails(uint256 _essenceTypeId)`: View metadata for an Essence type.
26. `getShardDetails(uint256 _shardTypeId)`: View metadata for a Shard type.
27. `getArtifactDetails(uint256 _artifactTypeId)`: View metadata for an Artifact type.
28. `getArtifactAttributes(uint256 _artifactTokenId)`: View the specific dynamic attributes of a minted Artifact instance.
29. `getTemporalRiftDetails(uint256 _riftId)`: View details of a Temporal Rift.
30. `getAlchemistRank(address _alchemist)`: Calculate and return an Alchemist's current rank based on their XP.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Aetherium Forge Smart Contract ---
//
// Outline:
// 1. Contract Definition: Pragma, license, custom errors.
// 2. Ownership: Basic owner management.
// 3. Structs: Alchemist, EssenceDetails, ShardDetails, ArtifactDetails, CraftedArtifactData, Recipe, TemporalRift.
// 4. State Variables: Mappings for users, assets, recipes, rifts, counters, configuration.
// 5. Events: For key actions.
// 6. Modifiers: onlyOwner, onlyRegisteredAlchemist.
// 7. Constructor: Initializes owner.
// 8. Admin Functions (Config & Setup): Item types, recipes, grants, ranks, rifts, metadata. (Functions 3-11, 13-15)
// 9. Core Logic Functions (User Actions): Register, transfer Shards, check recipe, forge, claim rift, redeem. (Functions 2, 12, 16-19)
// 10. View/Getter Functions (Information Retrieval): Alchemist, assets, items, recipes, rifts, rank, supply. (Functions 20-30)
//
// Function Summary (Total: 30 functions):
// 1. constructor(): Initializes the contract owner.
// 2. registerAlchemist(): Allows a user to become a registered Alchemist.
// 3. setEssenceDetails(uint256 _essenceTypeId, string memory _name, string memory _symbol): Owner sets metadata for an Essence type.
// 4. setShardDetails(uint256 _shardTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI): Owner sets metadata for a Shard type and its base URI.
// 5. setArtifactDetails(uint256 _artifactTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI): Owner sets metadata for an Artifact type and its base URI.
// 6. addForgingRecipe(uint256 _recipeId, uint256 _minAlchemistRank, RecipeItemInput[] memory _essenceInputs, RecipeItemInput[] memory _shardInputs, RecipeItemOutput[] memory _artifactOutputs, RecipeItemOutput[] memory _essenceOutputs): Owner adds a new crafting recipe.
// 7. removeForgingRecipe(uint256 _recipeId): Owner removes an existing recipe.
// 8. setMinAlchemistRankToForge(uint256 _recipeId, uint256 _minRank): Owner sets minimum rank requirement for a recipe.
// 9. grantEssence(address _to, uint256 _essenceTypeId, uint256 _amount): Owner grants a specific amount of Essence to an address (initial distribution/rewards).
// 10. grantShard(address _to, uint256 _shardTypeId, uint256 _amount): Owner grants multiple instances of a Shard type to an address.
// 11. grantArtifact(address _to, uint256 _artifactTypeId, bytes memory _craftedAttributes): Owner grants a specific Artifact instance to an address (e.g., for special rewards).
// 12. transferShard(address _from, address _to, uint256 _shardTokenId): Allows a Shard owner to transfer a specific Shard instance *before* it's used in crafting.
// 13. startTemporalRift(uint256 _riftId, string memory _name, uint256 _startTime, uint256 _endTime, bytes memory _conditionsData, RecipeItemOutput[] memory _rewards): Owner initiates a time-limited Temporal Rift event.
// 14. endTemporalRift(uint256 _riftId): Owner manually ends a Temporal Rift.
// 15. setAlchemistRankThresholds(uint256[] memory _xpThresholds): Owner sets the XP required for each Alchemist rank.
// 16. checkRecipeAvailability(address _alchemist, uint256 _recipeId): Checks if an alchemist meets the requirements (rank, ingredients) to forge a recipe (view function).
// 17. forgeArtifact(uint256 _recipeId): Executes the crafting process. Consumes inputs, mints outputs, awards XP.
// 18. claimTemporalRiftReward(uint256 _riftId): Allows an Alchemist who met rift conditions to claim its reward (simplified condition check).
// 19. redeemArtifactForEssence(uint256 _artifactTokenId): Allows an Artifact owner to burn it for Essence.
// 20. getAlchemistDetails(address _alchemist): View Alchemist's XP and rank.
// 21. getEssenceBalance(address _alchemist, uint256 _essenceTypeId): View an Alchemist's balance of a specific Essence type.
// 22. getOwnedShards(address _alchemist, uint256 _shardTypeId): List the token IDs of a specific Shard type owned by an Alchemist. (Note: listing all owned is gas-intensive, this gets by type).
// 23. getOwnedArtifacts(address _alchemist, uint256 _artifactTypeId): List the token IDs of a specific Artifact type owned by an Alchemist. (Note: listing all owned is gas-intensive, this gets by type).
// 24. getRecipeDetails(uint256 _recipeId): View details of a crafting recipe.
// 25. getEssenceDetails(uint256 _essenceTypeId): View metadata for an Essence type.
// 26. getShardDetails(uint256 _shardTypeId): View metadata for a Shard type.
// 27. getArtifactDetails(uint256 _artifactTypeId): View metadata for an Artifact type.
// 28. getArtifactAttributes(uint256 _artifactTokenId): View the specific dynamic attributes of a minted Artifact instance.
// 29. getTemporalRiftDetails(uint256 _riftId): View details of a Temporal Rift.
// 30. getAlchemistRank(address _alchemist): Calculate and return an Alchemist's current rank based on their XP.

// --- Custom Errors ---
error NotOwner();
error AlchemistAlreadyRegistered();
error AlchemistNotRegistered();
error InvalidEssenceType();
error InvalidShardType();
error InvalidArtifactType();
error InvalidRecipe();
error InsufficientEssence(uint256 essenceTypeId, uint256 required, uint256 has);
error InsufficientShard(uint256 shardTypeId, uint256 required, uint256 has);
error ShardNotOwned(uint256 shardTokenId, address owner);
error ArtifactNotOwned(uint256 artifactTokenId, address owner);
error RecipeRankTooLow(uint256 requiredRank, uint256 currentRank);
error InvalidShardTokenId();
error InvalidArtifactTokenId();
error RiftNotActive();
error RiftRewardAlreadyClaimed();
error RiftConditionsNotMet(); // Simplified - actual check needed externally or via complex internal state
error ArtifactCannotBeRedeemed();
error InvalidAmount();
error InvalidRecipient();
error CannotTransferSoulboundEssence();
error RiftEnded();

contract AetheriumForge {

    address private _owner;

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier onlyRegisteredAlchemist() {
        if (!alchemists[msg.sender].isRegistered) revert AlchemistNotRegistered();
        _;
    }

    // --- Structs ---
    struct Alchemist {
        bool isRegistered;
        uint256 xp;
        // Additional stats or flags can be added here
    }

    struct EssenceDetails {
        bool exists;
        string name;
        string symbol;
        // Essences are soulbound to Alchemists after initial grant
    }

    struct ShardDetails {
        bool exists;
        string name;
        string symbol;
        string baseMetadataURI; // Used to generate token URI
    }

    struct ArtifactDetails {
        bool exists;
        string name;
        string symbol;
        string baseMetadataURI; // Used to generate token URI
        bool redeemable; // Can this artifact be burned for essence?
        uint256 redemptionEssenceTypeId;
        uint256 redemptionEssenceAmount;
    }

    struct CraftedArtifactData {
        uint256 artifactTypeId;
        uint256 mintedTimestamp;
        address owner;
        bytes craftedAttributes; // Dynamic attributes based on forging process/alchemist state
        // Add more fields for specific stats/properties
    }

    struct RecipeItemInput {
        uint256 itemTypeId; // EssenceTypeId or ShardTypeId
        uint256 amount; // For Essences (count) or Shards (number of instances/type)
        bool isEssence; // True if input is Essence, false if Shard
    }

    struct RecipeItemOutput {
        uint256 itemTypeId; // ArtifactTypeId or EssenceTypeId
        uint256 amount; // For Essences (count) or Artifacts (number of instances/type)
        bool isEssence; // True if output is Essence, false if Artifact
        bytes outputAttributes; // Base attributes/config for output artifacts
    }

    struct Recipe {
        bool exists;
        uint256 minAlchemistRank;
        RecipeItemInput[] essenceInputs;
        RecipeItemInput[] shardInputs;
        RecipeItemOutput[] artifactOutputs;
        RecipeItemOutput[] essenceOutputs;
        uint256 xpReward;
        // Can add chances for critical success, etc.
    }

    struct TemporalRift {
        bool exists;
        bool active;
        string name;
        uint256 startTime;
        uint256 endTime;
        bytes conditionsData; // Arbitrary data defining rift conditions (requires off-chain interpretation or complex on-chain logic not included here)
        RecipeItemOutput[] rewards;
    }

    // --- State Variables ---

    mapping(address => Alchemist) public alchemists;
    mapping(address => mapping(uint256 => uint256)) private alchemistEssenceBalance; // alchemistAddress -> essenceTypeId -> balance
    mapping(uint256 => address) private shardOwners; // shardTokenId -> ownerAddress
    mapping(address => mapping(uint256 => uint256[])) private alchemistOwnedShardTokenIds; // alchemistAddress -> shardTypeId -> array of tokenIds (Note: Array iteration can be gas-intensive)
    uint256 private nextShardTokenId = 1;

    mapping(uint256 => CraftedArtifactData) private craftedArtifacts; // artifactTokenId -> CraftedArtifactData
    mapping(address => mapping(uint256 => uint256[])) private alchemistOwnedArtifactTokenIds; // alchemistAddress -> artifactTypeId -> array of tokenIds (Note: Array iteration can be gas-intensive)
    uint256 private nextArtifactTokenId = 1;


    mapping(uint256 => EssenceDetails) public essenceDetails; // essenceTypeId -> details
    mapping(uint256 => ShardDetails) public shardDetails;     // shardTypeId -> details
    mapping(uint256 => ArtifactDetails) public artifactDetails; // artifactTypeId -> details

    mapping(uint256 => Recipe) public recipes; // recipeId -> Recipe

    mapping(uint256 => TemporalRift) public temporalRifts; // riftId -> TemporalRift
    mapping(uint256 => mapping(address => bool)) private riftRewardClaimed; // riftId -> alchemistAddress -> claimed

    uint256[] public alchemistRankThresholds; // Sorted array of XP needed for Rank 1, Rank 2, etc. Rank 0 is implied (less than threshold[0])

    mapping(uint256 => uint256) public totalEssenceSupply; // essenceTypeId -> total minted supply
    mapping(uint256 => uint256) public totalShardSupply;   // shardTypeId -> total minted supply
    mapping(uint256 => uint256) public totalArtifactSupply; // artifactTypeId -> total minted supply

    // --- Events ---
    event AlchemistRegistered(address indexed alchemist);
    event EssenceGranted(address indexed to, uint256 indexed essenceTypeId, uint256 amount);
    event EssenceBurned(address indexed from, uint256 indexed essenceTypeId, uint256 amount);
    event ShardGranted(address indexed to, uint256 indexed shardTypeId, uint256 indexed startTokenId, uint256 count);
    event ShardTransfer(address indexed from, address indexed to, uint256 indexed shardTokenId);
    event ShardBurned(address indexed owner, uint256 indexed shardTokenId);
    event ArtifactMinted(address indexed owner, uint256 indexed artifactTypeId, uint256 indexed artifactTokenId);
    event ArtifactBurned(address indexed owner, uint256 indexed artifactTokenId);
    event RecipeAdded(uint256 indexed recipeId, uint256 minRank);
    event RecipeRemoved(uint256 indexed recipeId);
    event ArtifactForged(address indexed alchemist, uint256 indexed recipeId, uint256 xpEarned);
    event AlchemistRankChanged(address indexed alchemist, uint256 oldRank, uint256 newRank);
    event TemporalRiftStarted(uint256 indexed riftId, string name, uint256 startTime, uint256 endTime);
    event TemporalRiftEnded(uint256 indexed riftId);
    event TemporalRiftRewardClaimed(address indexed alchemist, uint256 indexed riftId);

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        // Rank 0 is default. Rank 1 threshold could be 100 XP, Rank 2 is 500 XP, etc.
        // Initial thresholds can be set here or via admin function.
        alchemistRankThresholds = [100, 500, 1500, 3000]; // Example thresholds
    }

    // --- Admin Functions ---

    // Function 3
    function setEssenceDetails(uint256 _essenceTypeId, string memory _name, string memory _symbol) external onlyOwner {
        essenceDetails[_essenceTypeId] = EssenceDetails(true, _name, _symbol);
        // No total supply tracking needed here initially, only via grants
    }

    // Function 4
    function setShardDetails(uint256 _shardTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI) external onlyOwner {
        shardDetails[_shardTypeId] = ShardDetails(true, _name, _symbol, _baseMetadataURI);
        // No total supply tracking needed here initially, only via grants
    }

    // Function 5
    function setArtifactDetails(uint256 _artifactTypeId, string memory _name, string memory _symbol, string memory _baseMetadataURI) external onlyOwner {
        artifactDetails[_artifactTypeId] = ArtifactDetails(true, _name, _symbol, _baseMetadataURI, false, 0, 0); // Not redeemable by default
        // No total supply tracking needed here initially, only via grants
    }

    // Function 6
    function addForgingRecipe(
        uint256 _recipeId,
        uint256 _minAlchemistRank,
        RecipeItemInput[] memory _essenceInputs,
        RecipeItemInput[] memory _shardInputs,
        RecipeItemOutput[] memory _artifactOutputs,
        RecipeItemOutput[] memory _essenceOutputs
    ) external onlyOwner {
        require(!recipes[_recipeId].exists, "Recipe ID already exists");
        recipes[_recipeId] = Recipe(
            true,
            _minAlchemistRank,
            _essenceInputs,
            _shardInputs,
            _artifactOutputs,
            _essenceOutputs,
            100 // Example XP reward - could be per recipe
        );
        emit RecipeAdded(_recipeId, _minAlchemistRank);
    }

    // Function 7
    function removeForgingRecipe(uint256 _recipeId) external onlyOwner {
        require(recipes[_recipeId].exists, InvalidRecipe());
        delete recipes[_recipeId];
        emit RecipeRemoved(_recipeId);
    }

    // Function 8
    function setMinAlchemistRankToForge(uint256 _recipeId, uint256 _minRank) external onlyOwner {
        require(recipes[_recipeId].exists, InvalidRecipe());
        recipes[_recipeId].minAlchemistRank = _minRank;
    }

    // Function 9 - Owner grants Essence
    function grantEssence(address _to, uint256 _essenceTypeId, uint256 _amount) external onlyOwner {
        if (!essenceDetails[_essenceTypeId].exists) revert InvalidEssenceType();
        if (_amount == 0) revert InvalidAmount();
        if (_to == address(0)) revert InvalidRecipient();

        alchemistEssenceBalance[_to][_essenceTypeId] += _amount;
        totalEssenceSupply[_essenceTypeId] += _amount;
        emit EssenceGranted(_to, _essenceTypeId, _amount);
    }

     // Internal function to burn Essence
    function _burnEssence(address _from, uint256 _essenceTypeId, uint256 _amount) internal {
        if (alchemistEssenceBalance[_from][_essenceTypeId] < _amount) revert InsufficientEssence(_essenceTypeId, _amount, alchemistEssenceBalance[_from][_essenceTypeId]);

        alchemistEssenceBalance[_from][_essenceTypeId] -= _amount;
        // Note: Total supply decreases only if implementing burning from total supply, which is not typical for initial grants.
        // totalEssenceSupply[_essenceTypeId] -= _amount; // Uncomment if total supply should reflect only active balance
        emit EssenceBurned(_from, _essenceTypeId, _amount);
    }


    // Function 10 - Owner grants Shards (mints new ones)
    function grantShard(address _to, uint256 _shardTypeId, uint256 _amount) external onlyOwner {
        if (!shardDetails[_shardTypeId].exists) revert InvalidShardType();
        if (_amount == 0) revert InvalidAmount();
        if (_to == address(0)) revert InvalidRecipient();

        uint256 startTokenId = nextShardTokenId;
        for (uint256 i = 0; i < _amount; i++) {
            uint256 newTokenId = nextShardTokenId++;
            shardOwners[newTokenId] = _to;
            alchemistOwnedShardTokenIds[_to][_shardTypeId].push(newTokenId);
            craftedArtifacts[newTokenId].artifactTypeId = _shardTypeId; // Store type for owner lookup efficiency
            totalShardSupply[_shardTypeId]++; // Track total minted per type
        }
        emit ShardGranted(_to, _shardTypeId, startTokenId, _amount);
    }

    // Internal function to burn a Shard instance
    function _burnShard(uint256 _shardTokenId) internal {
        address owner = shardOwners[_shardTokenId];
        if (owner == address(0)) revert InvalidShardTokenId(); // Not a valid shard token ID

        // Remove from owner's list (simple approach, can be optimized)
        uint256 shardTypeId = craftedArtifacts[_shardTokenId].artifactTypeId;
        uint256[] storage ownedList = alchemistOwnedShardTokenIds[owner][shardTypeId];
        for (uint i = 0; i < ownedList.length; i++) {
            if (ownedList[i] == _shardTokenId) {
                ownedList[i] = ownedList[ownedList.length - 1];
                ownedList.pop();
                break;
            }
        }

        delete shardOwners[_shardTokenId]; // Remove ownership
        delete craftedArtifacts[_shardTokenId]; // Clear data for this token ID
        // totalShardSupply[_shardTypeId]--; // Decrement total supply if desired

        emit ShardBurned(owner, _shardTokenId);
    }


    // Function 11 - Owner grants Artifacts (mints new ones)
    function grantArtifact(address _to, uint256 _artifactTypeId, bytes memory _craftedAttributes) external onlyOwner {
        if (!artifactDetails[_artifactTypeId].exists) revert InvalidArtifactType();
        if (_to == address(0)) revert InvalidRecipient();

        _mintArtifact(_to, _artifactTypeId, _craftedAttributes);
    }

    // Function 13 - Owner starts a Temporal Rift
    function startTemporalRift(
        uint256 _riftId,
        string memory _name,
        uint256 _startTime,
        uint256 _endTime,
        bytes memory _conditionsData,
        RecipeItemOutput[] memory _rewards
    ) external onlyOwner {
        require(!temporalRifts[_riftId].exists || !temporalRifts[_riftId].active, "Rift ID exists and is active");
        require(_endTime > _startTime, "End time must be after start time");

        temporalRifts[_riftId] = TemporalRift(
            true,
            true,
            _name,
            _startTime,
            _endTime,
            _conditionsData,
            _rewards
        );

        // Reset claimed status for this rift
        // Note: This mapping needs careful handling if reusing rift IDs
        // A more robust system might use a combination of riftId and Alchemist address.
        // For simplicity here, we just assume a new rift ID resets claims.

        emit TemporalRiftStarted(_riftId, _name, _startTime, _endTime);
    }

    // Function 14 - Owner ends a Temporal Rift
    function endTemporalRift(uint256 _riftId) external onlyOwner {
        require(temporalRifts[_riftId].exists, "Rift ID does not exist");
        require(temporalRifts[_riftId].active, RiftEnded());
        temporalRifts[_riftId].active = false;
        emit TemporalRiftEnded(_riftId);
    }

    // Function 15 - Owner sets XP thresholds for ranks
    function setAlchemistRankThresholds(uint256[] memory _xpThresholds) external onlyOwner {
        // Ensure thresholds are sorted ascendingly
        for (uint256 i = 0; i < _xpThresholds.length; i++) {
            if (i > 0 && _xpThresholds[i] < _xpThresholds[i-1]) {
                 revert("Thresholds must be sorted ascending");
            }
        }
        alchemistRankThresholds = _xpThresholds;
    }

    // --- Core Logic Functions ---

    // Function 2 - Register as Alchemist
    function registerAlchemist() external {
        if (alchemists[msg.sender].isRegistered) revert AlchemistAlreadyRegistered();
        alchemists[msg.sender].isRegistered = true;
        alchemists[msg.sender].xp = 0; // Start with 0 XP
        emit AlchemistRegistered(msg.sender);
    }

     // Function 12 - Transfer Shards
    function transferShard(address _from, address _to, uint256 _shardTokenId) external {
        // Basic ERC721-like transfer logic for Shards *before* crafting consumes them
        require(msg.sender == _from || msg.sender == shardOwners[_shardTokenId], "Not authorized to transfer this shard"); // Simple auth: sender is from or current owner
        require(_to != address(0), "Transfer to zero address");
        if (shardOwners[_shardTokenId] != _from) revert ShardNotOwned(_shardTokenId, _from);

        // Remove from _from's list
        uint256 shardTypeId = craftedArtifacts[_shardTokenId].artifactTypeId;
        uint256[] storage fromOwned = alchemistOwnedShardTokenIds[_from][shardTypeId];
        bool found = false;
        for (uint i = 0; i < fromOwned.length; i++) {
            if (fromOwned[i] == _shardTokenId) {
                fromOwned[i] = fromOwned[fromOwned.length - 1];
                fromOwned.pop();
                found = true;
                break;
            }
        }
        if (!found) revert InvalidShardTokenId(); // Should not happen if owner check passed, but safety

        // Add to _to's list
        shardOwners[_shardTokenId] = _to;
        alchemistOwnedShardTokenIds[_to][_shardTypeId].push(_shardTokenId);
        // No need to update craftedArtifacts[_shardTokenId] as type is set at mint

        emit ShardTransfer(_from, _to, _shardTokenId);
    }


    // Function 16 - Check Recipe Availability (View)
    function checkRecipeAvailability(address _alchemist, uint256 _recipeId) external view returns (bool isAvailable) {
        if (!alchemists[_alchemist].isRegistered) return false;
        Recipe storage recipe = recipes[_recipeId];
        if (!recipe.exists) return false;

        uint256 currentRank = getAlchemistRank(_alchemist);
        if (currentRank < recipe.minAlchemistRank) return false;

        // Check Essence inputs
        for (uint i = 0; i < recipe.essenceInputs.length; i++) {
            if (alchemistEssenceBalance[_alchemist][recipe.essenceInputs[i].itemTypeId] < recipe.essenceInputs[i].amount) {
                return false;
            }
        }

        // Check Shard inputs
        for (uint i = 0; i < recipe.shardInputs.length; i++) {
             // Check if the alchemist has at least 'amount' shards of 'itemTypeId'
             // Note: This simple check doesn't verify *specific* token IDs, just count.
             // A more complex system might require specific token IDs with traits.
            if (alchemistOwnedShardTokenIds[_alchemist][recipe.shardInputs[i].itemTypeId].length < recipe.shardInputs[i].amount) {
                 return false;
            }
        }

        // Assuming availability based on resources and rank
        return true;
    }

    // Function 17 - Forge Artifact
    function forgeArtifact(uint256 _recipeId) external onlyRegisteredAlchemist {
        Recipe storage recipe = recipes[_recipeId];
        if (!recipe.exists) revert InvalidRecipe();

        address alchemistAddress = msg.sender;
        uint256 currentRank = getAlchemistRank(alchemistAddress);
        if (currentRank < recipe.minAlchemistRank) revert RecipeRankTooLow(recipe.minAlchemistRank, currentRank);

        // Consume Inputs
        // Essences
        for (uint i = 0; i < recipe.essenceInputs.length; i++) {
            RecipeItemInput storage input = recipe.essenceInputs[i];
            _burnEssence(alchemistAddress, input.itemTypeId, input.amount);
        }

        // Shards
        for (uint i = 0; i < recipe.shardInputs.length; i++) {
            RecipeItemInput storage input = recipe.shardInputs[i];
            uint256 shardTypeId = input.itemTypeId;
            uint256 amount = input.amount;

            uint256[] storage ownedShards = alchemistOwnedShardTokenIds[alchemistAddress][shardTypeId];
            if (ownedShards.length < amount) revert InsufficientShard(shardTypeId, amount, ownedShards.length);

            // Burn the required number of shards (take from the end of the list for efficiency)
            for (uint j = 0; j < amount; j++) {
                 uint256 shardToBurnTokenId = ownedShards[ownedShards.length - 1];
                 ownedShards.pop();
                 _burnShard(shardToBurnTokenId);
            }
        }

        // Mint Outputs & Award XP
        // Artifacts
        for (uint i = 0; i < recipe.artifactOutputs.length; i++) {
            RecipeItemOutput storage output = recipe.artifactOutputs[i];
            uint256 artifactTypeId = output.itemTypeId;
            uint256 amount = output.amount;

            if (!artifactDetails[artifactTypeId].exists) revert InvalidArtifactType(); // Should be caught by admin setup

            for (uint j = 0; j < amount; j++) {
                // Determine dynamic attributes for the crafted artifact instance
                // Example: Base attributes + modifier based on alchemist rank or timestamp
                bytes memory craftedAttr = abi.encodePacked(
                    output.outputAttributes, // Base attributes from recipe
                    uint64(currentRank),      // Include alchemist's rank at forging
                    uint64(block.timestamp)   // Include timestamp for variation
                    // Add more dynamic factors here
                );

                _mintArtifact(alchemistAddress, artifactTypeId, craftedAttr);
            }
        }

        // Essences (If recipe also outputs essence)
        for (uint i = 0; i < recipe.essenceOutputs.length; i++) {
             RecipeItemOutput storage output = recipe.essenceOutputs[i];
             uint256 essenceTypeId = output.itemTypeId;
             uint256 amount = output.amount;

             if (!essenceDetails[essenceTypeId].exists) revert InvalidEssenceType(); // Should be caught by admin setup

             alchemistEssenceBalance[alchemistAddress][essenceTypeId] += amount; // Grant directly
             totalEssenceSupply[essenceTypeId] += amount; // Update total supply if needed for grants
             emit EssenceGranted(alchemistAddress, essenceTypeId, amount);
        }

        // Award XP
        uint256 oldRank = getAlchemistRank(alchemistAddress);
        alchemists[alchemistAddress].xp += recipe.xpReward;
        uint256 newRank = getAlchemistRank(alchemistAddress);

        if (newRank > oldRank) {
            emit AlchemistRankChanged(alchemistAddress, oldRank, newRank);
        }

        emit ArtifactForged(alchemistAddress, _recipeId, recipe.xpReward);
    }

    // Internal function to mint an Artifact instance
    function _mintArtifact(address _to, uint256 _artifactTypeId, bytes memory _craftedAttributes) internal {
        uint256 newTokenId = nextArtifactTokenId++;
        craftedArtifacts[newTokenId] = CraftedArtifactData({
            artifactTypeId: _artifactTypeId,
            mintedTimestamp: block.timestamp,
            owner: _to,
            craftedAttributes: _craftedAttributes
        });
        alchemistOwnedArtifactTokenIds[_to][_artifactTypeId].push(newTokenId);
        totalArtifactSupply[_artifactTypeId]++;

        emit ArtifactMinted(_to, _artifactTypeId, newTokenId);
    }

    // Function 18 - Claim Temporal Rift Reward
    function claimTemporalRiftReward(uint256 _riftId) external onlyRegisteredAlchemist {
        TemporalRift storage rift = temporalRifts[_riftId];
        if (!rift.exists || !rift.active) revert RiftNotActive();
        if (block.timestamp > rift.endTime) revert RiftEnded();
        if (riftRewardClaimed[_riftId][msg.sender]) revert RiftRewardAlreadyClaimed();

        // --- Simplified Rift Condition Check ---
        // In a real scenario, 'rift.conditionsData' would be interpreted here (or via an external oracle/verifier)
        // to check if msg.sender actually met the rift's requirements (e.g., crafted a specific item, reached certain XP).
        // For this example, we'll assume the conditions are met if the function is called during the active period.
        // REPLACE THIS with actual condition verification:
        bool conditionsMet = true; // Placeholder: Assume met for demonstration

        if (!conditionsMet) revert RiftConditionsNotMet();
        // --- End Simplified Check ---

        // Grant rewards
        for (uint i = 0; i < rift.rewards.length; i++) {
             RecipeItemOutput storage reward = rift.rewards[i];
             if (reward.isEssence) {
                 if (!essenceDetails[reward.itemTypeId].exists) continue; // Skip invalid reward type
                 alchemistEssenceBalance[msg.sender][reward.itemTypeId] += reward.amount;
                 totalEssenceSupply[reward.itemTypeId] += reward.amount; // Update total supply for grants
                 emit EssenceGranted(msg.sender, reward.itemTypeId, reward.amount);
             } else { // Artifact reward
                  if (!artifactDetails[reward.itemTypeId].exists) continue; // Skip invalid reward type
                  for (uint j = 0; j < reward.amount; j++) {
                      // Artifact rewards from rift might have different attribute generation logic
                      bytes memory rewardAttr = abi.encodePacked(
                           reward.outputAttributes,
                           uint64(block.timestamp) // Rift context attribute
                      );
                      _mintArtifact(msg.sender, reward.itemTypeId, rewardAttr);
                  }
             }
        }

        riftRewardClaimed[_riftId][msg.sender] = true;
        emit TemporalRiftRewardClaimed(msg.sender, _riftId);
    }

    // Function 19 - Redeem Artifact for Essence
    function redeemArtifactForEssence(uint256 _artifactTokenId) external onlyRegisteredAlchemist {
        CraftedArtifactData storage artifactData = craftedArtifacts[_artifactTokenId];
        if (artifactData.owner != msg.sender) revert ArtifactNotOwned(_artifactTokenId, msg.sender);

        ArtifactDetails storage details = artifactDetails[artifactData.artifactTypeId];
        if (!details.exists) revert InvalidArtifactType(); // Should not happen if owned
        if (!details.redeemable) revert ArtifactCannotBeRedeemed();
        if (!essenceDetails[details.redemptionEssenceTypeId].exists) revert InvalidEssenceType(); // Should be configured correctly by admin

        uint256 essenceTypeId = details.redemptionEssenceTypeId;
        uint256 amount = details.redemptionEssenceAmount;

        // Burn the artifact
        _burnArtifact(_artifactTokenId);

        // Grant the essence
        alchemistEssenceBalance[msg.sender][essenceTypeId] += amount; // Grant directly
        totalEssenceSupply[essenceTypeId] += amount; // Update total supply for grants
        emit EssenceGranted(msg.sender, essenceTypeId, amount); // Re-using event for clarity
    }

    // Internal function to burn an Artifact instance
     function _burnArtifact(uint256 _artifactTokenId) internal {
        CraftedArtifactData storage artifactData = craftedArtifacts[_artifactTokenId];
        address owner = artifactData.owner;
        if (owner == address(0)) revert InvalidArtifactTokenId();

        uint256 artifactTypeId = artifactData.artifactTypeId;

        // Remove from owner's list (simple approach, can be optimized)
        uint256[] storage ownedList = alchemistOwnedArtifactTokenIds[owner][artifactTypeId];
        for (uint i = 0; i < ownedList.length; i++) {
            if (ownedList[i] == _artifactTokenId) {
                ownedList[i] = ownedList[ownedList.length - 1];
                ownedList.pop();
                break;
            }
        }

        delete craftedArtifacts[_artifactTokenId]; // Clear data for this token ID
        // totalArtifactSupply[artifactTypeId]--; // Decrement total supply if desired

        emit ArtifactBurned(owner, _artifactTokenId);
    }


    // --- View/Getter Functions ---

    // Function 20
    function getAlchemistDetails(address _alchemist) external view returns (Alchemist memory) {
        return alchemists[_alchemist];
    }

    // Function 21
    function getEssenceBalance(address _alchemist, uint256 _essenceTypeId) external view returns (uint256) {
        if (!alchemists[_alchemist].isRegistered) return 0; // Or revert AlchemistNotRegistered();
        return alchemistEssenceBalance[_alchemist][_essenceTypeId];
    }

    // Function 22 - Note: Potentially gas intensive for users with many shards of one type
    function getOwnedShards(address _alchemist, uint256 _shardTypeId) external view returns (uint256[] memory) {
         if (!alchemists[_alchemist].isRegistered) return new uint256[](0);
         return alchemistOwnedShardTokenIds[_alchemist][_shardTypeId];
    }

    // Function 23 - Note: Potentially gas intensive for users with many artifacts of one type
    function getOwnedArtifacts(address _alchemist, uint256 _artifactTypeId) external view returns (uint256[] memory) {
         if (!alchemists[_alchemist].isRegistered) return new uint256[](0);
         return alchemistOwnedArtifactTokenIds[_alchemist][_artifactTypeId];
    }


    // Function 24
    function getRecipeDetails(uint256 _recipeId) external view returns (Recipe memory) {
        return recipes[_recipeId];
    }

    // Function 25
    function getEssenceDetails(uint256 _essenceTypeId) external view returns (EssenceDetails memory) {
        return essenceDetails[_essenceTypeId];
    }

    // Function 26
    function getShardDetails(uint256 _shardTypeId) external view returns (ShardDetails memory) {
        return shardDetails[_shardTypeId];
    }

    // Function 27
    function getArtifactDetails(uint256 _artifactTypeId) external view returns (ArtifactDetails memory) {
        return artifactDetails[_artifactTypeId];
    }

    // Function 28
    function getArtifactAttributes(uint256 _artifactTokenId) external view returns (bytes memory) {
        if (craftedArtifacts[_artifactTokenId].owner == address(0)) revert InvalidArtifactTokenId();
        return craftedArtifacts[_artifactTokenId].craftedAttributes;
    }

    // Function 29
    function getTemporalRiftDetails(uint256 _riftId) external view returns (TemporalRift memory) {
        return temporalRifts[_riftId];
    }

    // Function 30 - Calculate Alchemist Rank
    function getAlchemistRank(address _alchemist) public view returns (uint256) {
        uint256 xp = alchemists[_alchemist].xp;
        uint256 rank = 0;
        for (uint i = 0; i < alchemistRankThresholds.length; i++) {
            if (xp >= alchemistRankThresholds[i]) {
                rank = i + 1; // Rank 1 starts at threshold[0]
            } else {
                break; // XP is less than this threshold, so current rank is the highest achieved so far
            }
        }
        return rank;
    }

    // --- Additional Utility Views ---

    function isAlchemistRegistered(address _alchemist) external view returns (bool) {
        return alchemists[_alchemist].isRegistered;
    }

    function getShardOwner(uint256 _shardTokenId) external view returns (address) {
        return shardOwners[_shardTokenId];
    }

    function getArtifactOwner(uint256 _artifactTokenId) external view returns (address) {
        return craftedArtifacts[_artifactTokenId].owner;
    }

     // Metadata URI generation (ERC721-like helper)
    function shardTokenURI(uint256 _shardTokenId) external view returns (string memory) {
        address owner = shardOwners[_shardTokenId];
        if (owner == address(0)) revert InvalidShardTokenId();

        uint256 shardTypeId = craftedArtifacts[_shardTokenId].artifactTypeId; // Re-using field
        ShardDetails storage details = shardDetails[shardTypeId];
        if (!details.exists) revert InvalidShardType(); // Should not happen if token exists

        // Simple concatenation: baseURI + tokenId.json
        // More complex systems might include attributes in the URI or a dedicated metadata service
        return string(abi.encodePacked(details.baseMetadataURI, Strings.toString(_shardTokenId), ".json"));
    }

    function artifactTokenURI(uint256 _artifactTokenId) external view returns (string memory) {
        address owner = craftedArtifacts[_artifactTokenId].owner;
        if (owner == address(0)) revert InvalidArtifactTokenId();

        uint256 artifactTypeId = craftedArtifacts[_artifactTokenId].artifactTypeId;
        ArtifactDetails storage details = artifactDetails[artifactTypeId];
        if (!details.exists) revert InvalidArtifactType(); // Should not happen if token exists

        // Simple concatenation: baseURI + tokenId.json
        // A real dynamic NFT would need a metadata service that reads craftedAttributes
        return string(abi.encodePacked(details.baseMetadataURI, Strings.toString(_artifactTokenId), ".json"));
    }

    // Helper library for uint to string conversion (simplified version)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```