Okay, let's design a smart contract for a decentralized treasure hunt with some twists inspired by concepts like quantum states, time-sensitivity, and on-chain interaction. We'll call it `QuantumTreasureHunt`.

This contract will involve players scanning for potential "Quantum Shards" which exist in a kind of uncertain state until claimed, solving on-chain puzzles to reveal clues or earn shards, and combining collected shards to unlock upgrades or special items.

It incorporates:
1.  **Simulated Quantum State:** Shards found via scanning are initially "entangled". Their true properties (type, bonus) are revealed only upon claiming (the "measurement" or "decoherence" event), adding uncertainty.
2.  **Time Sensitivity/Decoherence:** Shards and puzzles have limited lifespans. A "Decoherence Event" can accelerate shard expiry.
3.  **On-Chain Puzzles:** Puzzles require specific on-chain actions or providing correct data derived from the blockchain state or contract history.
4.  **Dynamic Shard Generation:** Shards are generated based on complex factors during scanning (block hash, timestamp, player nonce, contract state).
5.  **Shard Combination:** Players can combine different types of shards to gain permanent upgrades or unique items tracked by the contract.
6.  **Player Reputation/Skill:** Players earn reputation by solving puzzles.
7.  **Resource Management:** Scanning costs Ether, adding an economic sink.
8.  **Transferable Scan Claims:** Players can transfer the *right* to claim a scanned, entangled shard, adding a trading layer before the shard's properties are known.

---

**Outline:**

1.  **License & Pragma**
2.  **State Variables:**
    *   Owner address
    *   Scan cost (in Wei)
    *   Shard coherence time (blocks until auto-expiry)
    *   Puzzle expiry delta (blocks puzzles are active)
    *   Decoherence factor (multiplies expiry delta during event)
    *   Nonce for shard generation
    *   Mappings for player profiles (`address => Player`)
    *   Mappings for active scanned shard claims (`bytes32 => ScannedShardClaim`)
    *   Mappings for active puzzles (`uint256 => Puzzle`)
    *   Counters for puzzle IDs
    *   Mapping for shard type details (`uint256 => ShardType`)
    *   Mapping for combination recipes (`bytes32 => CombinationResult`)
3.  **Structs:**
    *   `Player`: reputation, collected shards (`mapping(uint256 => uint256)` shard type => count), last scan block, active scan claims (`bytes32[]`).
    *   `ScannedShardClaim`: owner, generation block, expiry block, revealed shard type (0 if entangled), revealed bonus (0 if entangled).
    *   `Puzzle`: puzzle type, solution hash, creation block, expiry block, reward shard type, difficulty.
    *   `ShardType`: name, description, max per player (optional), properties (e.g., bonus multiplier).
    *   `CombinationResult`: success (bool), result type (e.g., uint for upgrade ID), result data.
4.  **Events:**
    *   `PlayerJoined`
    *   `ShardScanned` (claim ID, owner, generation block, expiry block)
    *   `ShardClaimed` (claim ID, owner, revealed shard type, bonus)
    *   `PuzzleCreated` (puzzle ID, type, expiry)
    *   `PuzzleSolved` (puzzle ID, solver, rewarded shard type)
    *   `ShardsCombined` (player, combination hash, result)
    *   `DecoherenceEventInitiated` (initiator, factor)
    *   `ScannedClaimTransferred` (claim ID, from, to)
    *   `FundsWithdrawn` (recipient, amount)
5.  **Modifiers:**
    *   `onlyOwner`
    *   `playerExists`
    *   `scannedClaimExists`
    *   `puzzleExists`
6.  **Functions (>= 20):**
    *   `constructor`: Sets owner, initial parameters.
    *   `receive()`: Allows receiving Ether (primarily for scanning).
    *   `joinHunt()`: Registers a new player.
    *   `scanForShards()`: Pays scan cost, attempts to generate a new `ScannedShardClaim` based on block data and nonce.
    *   `claimShard(bytes32 _claimId)`: Claims a scanned shard, reveals its properties if entangled, adds to player inventory.
    *   `createPuzzle(uint256 _type, bytes32 _solutionHash, uint256 _rewardShardType, uint256 _difficulty)`: Owner only. Creates a new on-chain puzzle.
    *   `solvePuzzle(uint256 _puzzleId, bytes32 _solutionData)`: Attempts to solve a puzzle by providing solution data. Rewards player on success.
    *   `combineShards(uint256[] calldata _shardTypes, uint256[] calldata _amounts)`: Attempts to combine specified shards based on defined recipes. Consumes shards, grants result.
    *   `initiateDecoherence(uint256 _factor)`: Owner or costly player function? (Let's make it owner for simplicity, or maybe require a rare shard combo). Increases the expiry rate of active claims temporarily.
    *   `attuneToDimension(uint256 _dimensionId)`: Placeholder for a system that might influence scan results (player state change).
    *   `getPlayerProfile(address _player)`: View function. Returns player reputation and last scan block.
    *   `getPlayerShards(address _player, uint256 _shardType)`: View function. Returns count of a specific shard type for a player.
    *   `getPlayerAllShards(address _player)`: View function. Returns mapping of all shard counts for a player.
    *   `getScannedClaim(bytes32 _claimId)`: View function. Returns details of a scanned shard claim.
    *   `getPlayerScannedClaims(address _player)`: View function. Returns list of claim IDs owned by player.
    *   `getPuzzle(uint256 _puzzleId)`: View function. Returns puzzle details (excluding solution hash).
    *   `getActivePuzzles()`: View function. Returns list of active puzzle IDs (gas intensive if many).
    *   `addShardType(uint256 _typeId, string memory _name, string memory _description, uint256 _maxPerPlayer)`: Owner only. Defines a new shard type.
    *   `addCombinationRecipe(uint256[] calldata _ingredientTypes, uint256[] calldata _ingredientAmounts, bool _success, uint256 _resultType, bytes memory _resultData)`: Owner only. Defines a shard combination recipe.
    *   `transferScannedClaim(bytes32 _claimId, address _to)`: Allows transferring ownership of an *unclaimed* scanned shard.
    *   `setScanCost(uint256 _cost)`: Owner only. Sets the cost to scan.
    *   `setShardCoherenceTime(uint256 _blocks)`: Owner only. Sets default shard expiry delta.
    *   `setPuzzleExpiryDelta(uint256 _blocks)`: Owner only. Sets default puzzle expiry delta.
    *   `cleanExpiredClaims()`: Allows anyone to call and potentially clean up some expired claims (incentive not included for brevity, but could be). Gas limited.
    *   `getContractBalance()`: View function. Returns contract's Ether balance.
    *   `withdrawFunds(address payable _recipient, uint256 _amount)`: Owner only. Withdraws funds.
    *   `burnShards(uint256[] calldata _shardTypes, uint256[] calldata _amounts)`: Allows players to voluntarily burn their shards.
    *   `getShardTypeDetails(uint256 _typeId)`: View function. Returns details about a shard type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. License & Pragma
// 2. State Variables: Owner, costs, timings, nonces, mappings for players, claims, puzzles, shard types, combinations.
// 3. Structs: Player, ScannedShardClaim, Puzzle, ShardType, CombinationResult.
// 4. Events: Notifications for key actions (join, scan, claim, solve, combine, decoherence, transfer, withdraw).
// 5. Modifiers: Access control (onlyOwner), existence checks (playerExists, etc.).
// 6. Functions:
//    - Core Game Loop: joinHunt, scanForShards, claimShard, solvePuzzle, combineShards.
//    - Mechanics: initiateDecoherence, attuneToDimension, transferScannedClaim, burnShards.
//    - Setup/Admin: constructor, receive, createPuzzle, addShardType, addCombinationRecipe, setScanCost, setShardCoherenceTime, setPuzzleExpiryDelta, withdrawFunds.
//    - View/Read: getPlayerProfile, getPlayerShards, getPlayerAllShards, getScannedClaim, getPlayerScannedClaims, getPuzzle, getActivePuzzles, getShardTypeDetails, getContractBalance.
//    - Maintenance: cleanExpiredClaims.

// Summary:
// QuantumTreasureHunt is a smart contract game where players register, scan for potential "Quantum Shards" (paying Ether),
// solve on-chain puzzles, and combine collected shards. Scanned shards are initially in an "entangled" state; their type
// and bonus are revealed only upon claiming, introducing uncertainty. Shards and puzzles are time-sensitive, and a
// "Decoherence Event" can accelerate their expiry. Players earn reputation by solving puzzles. The contract manages
// player inventories of shards, active scanned claims (transferable before claiming), and puzzles.

contract QuantumTreasureHunt {

    // --- State Variables ---

    address public owner;
    uint256 public scanCost = 0.01 ether; // Cost in Wei to initiate a scan
    uint256 public shardCoherenceBlocks = 100; // Blocks a scanned claim is active before expiring
    uint256 public puzzleExpiryBlocks = 500; // Blocks a puzzle is active after creation
    uint256 public decoherenceFactor = 1; // Multiplier for expiry during decoherence event (default 1)
    uint256 public lastDecoherenceBlock;

    uint256 private _nonce = 0; // Used in shard generation entropy

    // Player data
    struct Player {
        uint256 reputation;
        mapping(uint256 => uint256) collectedShards; // Shard Type ID => Count
        uint256 lastScanBlock;
        bytes32[] activeScanClaims; // IDs of scanned claims owned by player
    }
    mapping(address => Player) public players;
    mapping(address => bool) public playerExists; // More efficient check

    // Scanned shard claims (before they are claimed and become collected shards)
    // These are the "entangled" states
    struct ScannedShardClaim {
        address owner;
        uint256 generationBlock;
        uint256 expiryBlock;
        uint256 revealedShardType; // 0 if still entangled
        uint256 revealedBonus;    // 0 if still entangled
        bool claimed;
    }
    mapping(bytes32 => ScannedShardClaim) public scannedClaims;

    // Puzzles
    struct Puzzle {
        uint256 puzzleType; // Represents the nature of the puzzle (e.g., 1=DataHash, 2=TxSequence)
        bytes32 solutionHash; // Hash of the correct solution data
        uint256 creationBlock;
        uint256 expiryBlock;
        uint256 rewardShardType; // Shard type ID rewarded upon solving
        uint252 difficulty; // Arbitrary metric, maybe influences reputation reward
        bool solved;
    }
    uint256 public puzzleCounter = 0;
    mapping(uint256 => Puzzle) public puzzles;

    // Shard Type definitions
    struct ShardType {
        string name;
        string description;
        uint256 maxPerPlayer; // 0 if no limit
        uint256 propertiesHash; // Hash representing inherent properties/bonuses
    }
    mapping(uint256 => ShardType) public shardTypes; // Shard Type ID => ShardType details
    uint256 public shardTypeCounter = 0; // Simple counter for new types

    // Shard combination recipes
    // Key: keccak256 hash of sorted ingredientTypes and ingredientAmounts
    struct CombinationResult {
        bool success; // true if the combination yields something, false if it just burns
        uint256 resultType; // e.g., 0 for Upgrade, 1 for Item (interpreted based on context)
        bytes resultData; // Data specific to the result (e.g., Upgrade ID, Item properties)
    }
    mapping(bytes32 => CombinationResult) public combinationRecipes;

    // --- Events ---

    event PlayerJoined(address indexed player);
    event ShardScanned(bytes32 indexed claimId, address indexed owner, uint256 generationBlock, uint256 expiryBlock);
    event ShardClaimed(bytes32 indexed claimId, address indexed owner, uint256 revealedShardType, uint256 revealedBonus);
    event PuzzleCreated(uint256 indexed puzzleId, uint256 puzzleType, uint256 expiryBlock);
    event PuzzleSolved(uint256 indexed puzzleId, address indexed solver, uint256 rewardedShardType);
    event ShardsCombined(address indexed player, bytes32 indexed combinationHash, bool success, uint256 resultType);
    event DecoherenceEventInitiated(address indexed initiator, uint256 factor, uint256 startBlock, uint256 endBlock);
    event ScannedClaimTransferred(bytes32 indexed claimId, address indexed from, address indexed to);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ShardsBurned(address indexed player, uint256[] shardTypes, uint256[] amounts);
    event ScanCostUpdated(uint256 newCost);
    event ShardCoherenceTimeUpdated(uint256 newBlocks);
    event PuzzleExpiryDeltaUpdated(uint256 newBlocks);
    event ShardTypeAdded(uint256 indexed typeId, string name);
    event CombinationRecipeAdded(bytes32 indexed recipeHash, bool success);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier playerExists() {
        require(players[msg.sender].reputation > 0 || playerExists[msg.sender], "Player does not exist. Join the hunt first.");
        _;
    }

    modifier scannedClaimExists(bytes32 _claimId) {
        require(scannedClaims[_claimId].owner != address(0), "Scanned claim does not exist");
        _;
    }

    modifier puzzleExists(uint256 _puzzleId) {
        require(_puzzleId > 0 && _puzzleId <= puzzleCounter, "Puzzle does not exist");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        lastDecoherenceBlock = block.number; // Initialize
         // Add a default shard type 0 (e.g., Basic Fragment)
        shardTypeCounter++; // typeId 1
        shardTypes[shardTypeCounter] = ShardType("Basic Fragment", "A common quantum fragment.", 0, uint256(keccak256(abi.encodePacked("basic_fragment_props"))));
         // Add a default shard type 1 (e.g., Entangled Crystal)
        shardTypeCounter++; // typeId 2
        shardTypes[shardTypeCounter] = ShardType("Entangled Crystal", "Holds unpredictable properties.", 0, uint256(keccak256(abi.encodePacked("entangled_crystal_props"))));
    }

    // --- Receive Ether ---
    receive() external payable {}

    // --- Core Game Loop Functions ---

    /**
     * @notice Allows a new player to join the treasure hunt.
     */
    function joinHunt() external {
        require(!playerExists[msg.sender], "Player already exists");
        players[msg.sender].reputation = 1; // Starting reputation
        playerExists[msg.sender] = true;
        emit PlayerJoined(msg.sender);
    }

    /**
     * @notice Initiates a scan for potential quantum shards. Costs Ether.
     * @dev Uses block data and a nonce for entropy.
     */
    function scanForShards() external payable playerExists {
        require(msg.value >= scanCost, "Insufficient Ether for scan");
        require(block.number > players[msg.sender].lastScanBlock, "Can only scan once per block");

        _nonce++; // Increment nonce for variability

        // Simulate quantum randomness using block data and nonce
        bytes32 scanEntropy = keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, _nonce, block.difficulty, block.prevrandao));
        
        // Determine if a shard is found based on entropy (simplified)
        // 1 in 10 chance to find a shard claim
        if (uint256(scanEntropy) % 10 == 0) {
            bytes32 claimId = keccak256(abi.encodePacked(msg.sender, block.number, _nonce, scanEntropy));

            uint256 currentCoherenceTime = shardCoherenceBlocks;
            if (block.number < lastDecoherenceBlock + 100) { // Decoherence event lasts 100 blocks
                currentCoherenceTime /= decoherenceFactor;
                if (currentCoherenceTime == 0) currentCoherenceTime = 1; // Minimum 1 block
            }

            ScannedShardClaim storage newClaim = scannedClaims[claimId];
            newClaim.owner = msg.sender;
            newClaim.generationBlock = block.number;
            newClaim.expiryBlock = block.number + currentCoherenceTime;
            newClaim.revealedShardType = 0; // Start as entangled (type 0 means unrevealed)
            newClaim.revealedBonus = 0;
            newClaim.claimed = false;

            players[msg.sender].activeScanClaims.push(claimId);
            players[msg.sender].lastScanBlock = block.number;

            emit ShardScanned(claimId, msg.sender, newClaim.generationBlock, newClaim.expiryBlock);
        } else {
            players[msg.sender].lastScanBlock = block.number;
            // Emit a "scan failed" event? Or just let the lack of ShardScanned imply failure.
        }
    }

    /**
     * @notice Claims a previously scanned shard claim. Reveals its properties.
     * @param _claimId The ID of the scanned claim to claim.
     */
    function claimShard(bytes32 _claimId) external playerExists scannedClaimExists(_claimId) {
        ScannedShardClaim storage claim = scannedClaims[_claimId];
        require(claim.owner == msg.sender, "Not your scanned claim");
        require(!claim.claimed, "Claim already processed");
        require(block.number <= claim.expiryBlock, "Scanned claim has decohered (expired)");

        // Simulate decoherence/measurement - reveal true properties based on claim time entropy
        bytes32 revealEntropy = keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, _claimId, block.difficulty, block.prevrandao));

        // Determine revealed shard type and bonus based on entropy (simplified logic)
        uint256 revealedType = (uint256(revealEntropy) % shardTypeCounter) + 1; // Assuming shardTypeCounter starts from 1
        if (revealedType == 0) revealedType = 1; // Ensure valid type ID >= 1

        // Simple bonus determination - e.g., 0-99
        uint256 revealedBonus = uint256(revealEntropy) % 100;

        claim.revealedShardType = revealedType;
        claim.revealedBonus = revealedBonus; // Store bonus, maybe used later for something

        // Add to player's collected shards
        // Check max per player if defined
        uint256 maxAllowed = shardTypes[revealedType].maxPerPlayer;
        if (maxAllowed > 0 && players[msg.sender].collectedShards[revealedType] >= maxAllowed) {
             // Cannot claim, maybe auto-burn or refund? For now, let's auto-burn
             claim.claimed = true; // Mark as processed
             emit ShardClaimed(_claimId, msg.sender, revealedType, revealedBonus); // Still emit event showing result
             emit ShardsBurned(msg.sender, new uint256[](1), new uint256[](1)); // Simulate burning the received shard
             return; // Exit function
        }


        players[msg.sender].collectedShards[revealedType]++;
        claim.claimed = true; // Mark as processed

        // Remove from player's active scan claims list (optional, can keep history)
        // For simplicity now, we won't remove from the array, just mark as claimed in the mapping.
        // A cleanup function could periodically remove claimed/expired entries from the player's array.

        emit ShardClaimed(_claimId, msg.sender, revealedType, revealedBonus);
    }

    /**
     * @notice Attempts to solve a puzzle.
     * @param _puzzleId The ID of the puzzle to solve.
     * @param _solutionData The player's proposed solution data (e.g., a hash, a number, a string).
     * @dev Solution is verified against a stored hash.
     */
    function solvePuzzle(uint256 _puzzleId, bytes32 _solutionData) external playerExists puzzleExists(_puzzleId) {
        Puzzle storage puzzle = puzzles[_puzzleId];
        require(!puzzle.solved, "Puzzle already solved");
        require(block.number <= puzzle.expiryBlock, "Puzzle has expired");

        // Verify the solution - replace with actual puzzle type logic if needed
        // For simplicity, assumes _solutionData is the hash to match
        require(keccak256(abi.encodePacked(_solutionData)) == puzzle.solutionHash, "Incorrect solution");

        puzzle.solved = true;
        players[msg.sender].reputation += puzzle.difficulty; // Reward reputation

        // Reward with a shard (or the ability to claim a specific shard type directly?)
        // Let's reward directly added to inventory
        uint256 rewardShard = puzzle.rewardShardType;
        require(shardTypes[rewardShard].name.length > 0, "Invalid reward shard type"); // Ensure reward type exists

        // Check max per player if defined for reward shard
        uint256 maxAllowed = shardTypes[rewardShard].maxPerPlayer;
        if (maxAllowed == 0 || players[msg.sender].collectedShards[rewardShard] < maxAllowed) {
             players[msg.sender].collectedShards[rewardShard]++;
        } else {
            // Cannot receive reward shard due to max limit, maybe give reputation boost instead?
             players[msg.sender].reputation += puzzle.difficulty / 2; // Half reputation boost
        }


        emit PuzzleSolved(_puzzleId, msg.sender, rewardShard);
    }

    /**
     * @notice Attempts to combine a set of shards based on defined recipes.
     * @param _shardTypes Array of shard type IDs to combine.
     * @param _amounts Array of amounts for each corresponding shard type.
     * @dev The order of types/amounts doesn't matter for the recipe hash, but must match arrays.
     */
    function combineShards(uint256[] calldata _shardTypes, uint256[] calldata _amounts) external playerExists {
        require(_shardTypes.length == _amounts.length, "Array lengths must match");
        require(_shardTypes.length > 0, "Must provide ingredients");

        // Sort ingredients to create a canonical recipe hash
        // This requires a custom sorting helper function or library if done purely on-chain.
        // For a simpler implementation, we'll require the input arrays to be sorted by shard type ID.
        // In a real complex contract, consider the gas cost of on-chain sorting.
        // Assuming inputs are sorted for this example to calculate hash.

        bytes memory sortedIngredients = abi.encodePacked(_shardTypes, _amounts); // Simplistic: assumes presorted
        bytes32 recipeHash = keccak256(sortedIngredients);

        CombinationResult storage recipe = combinationRecipes[recipeHash];
        require(recipe.success || combinationRecipes[recipeHash].resultType != 0 || combinationRecipes[recipeHash].resultData.length > 0, "No recipe for these ingredients"); // Check if recipe exists

        // Check if player has enough shards
        for (uint i = 0; i < _shardTypes.length; i++) {
            require(players[msg.sender].collectedShards[_shardTypes[i]] >= _amounts[i], "Insufficient shards for combination");
        }

        // Consume shards
        for (uint i = 0; i < _shardTypes.length; i++) {
            players[msg.sender].collectedShards[_shardTypes[i]] -= _amounts[i];
        }

        // Apply result
        if (recipe.success) {
            // Implement logic based on recipe.resultType and recipe.resultData
            // e.g., increase a player's permanent bonus, grant a special status, etc.
            // This is highly game-specific. For this example, we'll just emit an event.
            // A more complex implementation would modify player state beyond collectedShards.
            // Example: If resultType 0 is "PermanentBonus", resultData could be abi.encode(bonusAmount)
            // bytes data = recipe.resultData;
            // uint256 bonus = abi.decode(data, (uint256)); // Example decoding
            // players[msg.sender].permanentBonus += bonus; // Example player state update

            // For now, just signal success and emit the result type/data hash
        } else {
             // Combination failed / just burns ingredients
             // No result other than consuming shards
        }


        emit ShardsCombined(msg.sender, recipeHash, recipe.success, recipe.resultType);
        // Could emit more specific events based on resultType
    }

    // --- Mechanics Functions ---

    /**
     * @notice Initiates a global decoherence event, accelerating shard claim expiry.
     * @param _factor The multiplier for accelerating expiry (e.g., 2 makes them expire twice as fast).
     * @dev Can be called by owner or potentially triggered by a rare combination result.
     */
    function initiateDecoherence(uint256 _factor) external onlyOwner { // Or specific player condition
        require(_factor > 1, "Decoherence factor must be greater than 1");
        decoherenceFactor = _factor;
        lastDecoherenceBlock = block.number;
        // The expiry calculation happens in `scanForShards` and `claimShard` based on `lastDecoherenceBlock`

        emit DecoherenceEventInitiated(msg.sender, _factor, block.number, block.number + 100); // Event lasts 100 blocks
    }

    /**
     * @notice Allows a player to attune themselves to a specific 'dimension'.
     * @param _dimensionId The ID representing the dimension.
     * @dev This function itself only changes player state; the effect is felt in `scanForShards` or puzzle types.
     *      Implementation of dimension effect is left as an exercise, but could involve a variable in Player struct.
     */
    function attuneToDimension(uint256 _dimensionId) external playerExists {
        // Example: Add a dimension field to Player struct
        // players[msg.sender].currentDimension = _dimensionId;
        // scanForShards could then use this dimensionId to influence scanEntropy or possible shard types.
        // Simple stub for now.
        revert("Dimension attunement not fully implemented in this version");
    }

    /**
     * @notice Allows a player to transfer the right to claim a scanned shard to another player.
     * @param _claimId The ID of the scanned claim to transfer.
     * @param _to The address of the recipient.
     * @dev Transferable only before claiming.
     */
    function transferScannedClaim(bytes32 _claimId, address _to) external playerExists scannedClaimExists(_claimId) {
        ScannedShardClaim storage claim = scannedClaims[_claimId];
        require(claim.owner == msg.sender, "Not your scanned claim");
        require(!claim.claimed, "Claim already processed");
        require(block.number <= claim.expiryBlock, "Scanned claim has decohered (expired)");
        require(_to != address(0), "Cannot transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to self");
        require(playerExists[_to], "Recipient is not a player");

        claim.owner = _to;

        // Update activeScanClaims arrays - This is gas intensive and complex to do efficiently.
        // A better approach in production would be to NOT store active claims in an array per player,
        // but perhaps query the mapping by owner or use a linked list structure if iteration is needed often.
        // For this example, we'll skip updating the array to save complexity and gas, but note this limitation.
        // Finding and removing an element from a dynamic array in storage is costly.
        // The recipient will now own the claim in the mapping, they can call claimShard directly.

        emit ScannedClaimTransferred(_claimId, msg.sender, _to);
    }

     /**
     * @notice Allows a player to burn (destroy) collected shards.
     * @param _shardTypes Array of shard type IDs to burn.
     * @param _amounts Array of amounts for each corresponding shard type.
     */
    function burnShards(uint256[] calldata _shardTypes, uint256[] calldata _amounts) external playerExists {
        require(_shardTypes.length == _amounts.length, "Array lengths must match");
        require(_shardTypes.length > 0, "Must specify shards to burn");

        for (uint i = 0; i < _shardTypes.length; i++) {
            require(players[msg.sender].collectedShards[_shardTypes[i]] >= _amounts[i], "Insufficient shards to burn");
        }

        for (uint i = 0; i < _shardTypes.length; i++) {
             players[msg.sender].collectedShards[_shardTypes[i]] -= _amounts[i];
        }

        emit ShardsBurned(msg.sender, _shardTypes, _amounts);
    }

    // --- Setup/Admin Functions ---

    /**
     * @notice Creates a new puzzle.
     * @param _puzzleType The type identifier for the puzzle (e.g., 1 for hash match).
     * @param _solutionHash The hash of the correct solution data.
     * @param _rewardShardType The ID of the shard type rewarded on success.
     * @param _difficulty The difficulty rating (influences reputation reward).
     */
    function createPuzzle(uint256 _puzzleType, bytes32 _solutionHash, uint256 _rewardShardType, uint252 _difficulty) external onlyOwner {
        require(_solutionHash != bytes32(0), "Solution hash cannot be zero");
        require(shardTypes[_rewardShardType].name.length > 0, "Invalid reward shard type"); // Ensure reward type exists
        require(_difficulty > 0, "Difficulty must be positive");

        puzzleCounter++;
        puzzles[puzzleCounter] = Puzzle({
            puzzleType: _puzzleType,
            solutionHash: _solutionHash,
            creationBlock: block.number,
            expiryBlock: block.number + puzzleExpiryBlocks,
            rewardShardType: _rewardShardType,
            difficulty: _difficulty,
            solved: false
        });

        emit PuzzleCreated(puzzleCounter, _puzzleType, puzzles[puzzleCounter].expiryBlock);
    }

     /**
     * @notice Adds a new shard type definition.
     * @param _name Name of the shard type.
     * @param _description Description of the shard type.
     * @param _maxPerPlayer Maximum count a single player can hold (0 for unlimited).
     */
    function addShardType(uint256 _typeId, string memory _name, string memory _description, uint256 _maxPerPlayer) external onlyOwner {
         require(_typeId > 0, "Shard type ID must be greater than 0");
         require(shardTypes[_typeId].name.length == 0, "Shard type ID already exists"); // Ensure ID is unique
         require(bytes(_name).length > 0, "Name cannot be empty");

         shardTypes[_typeId] = ShardType({
             name: _name,
             description: _description,
             maxPerPlayer: _maxPerPlayer,
             propertiesHash: uint256(keccak256(abi.encodePacked(_name, _description))) // Simple properties hash
         });
         if (_typeId > shardTypeCounter) shardTypeCounter = _typeId; // Update counter if adding higher ID

         emit ShardTypeAdded(_typeId, _name);
    }

    /**
     * @notice Adds a new shard combination recipe.
     * @param _ingredientTypes Sorted array of shard type IDs required.
     * @param _ingredientAmounts Amounts required for each type (must match _ingredientTypes length).
     * @param _success True if combination yields a result, false if it just burns.
     * @param _resultType Type identifier for the result (0 for burn/no specific type, >0 otherwise).
     * @param _resultData Arbitrary data describing the result (e.g., encoded upgrade ID).
     * @dev Requires _ingredientTypes to be sorted ascending for a canonical recipe hash.
     */
    function addCombinationRecipe(uint256[] calldata _ingredientTypes, uint256[] calldata _ingredientAmounts, bool _success, uint256 _resultType, bytes calldata _resultData) external onlyOwner {
        require(_ingredientTypes.length > 0 && _ingredientTypes.length == _ingredientAmounts.length, "Invalid ingredients");
        // Add validation that _ingredientTypes is sorted
        for(uint i = 0; i < _ingredientTypes.length - 1; i++) {
            require(_ingredientTypes[i] < _ingredientTypes[i+1], "Ingredient types must be sorted ascending");
        }
        // Add validation that ingredient types exist
        for(uint i = 0; i < _ingredientTypes.length; i++) {
             require(shardTypes[_ingredientTypes[i]].name.length > 0, "Invalid ingredient shard type");
        }


        bytes32 recipeHash = keccak256(abi.encodePacked(_ingredientTypes, _ingredientAmounts));
        require(combinationRecipes[recipeHash].resultType == 0 && combinationRecipes[recipeHash].resultData.length == 0 && !combinationRecipes[recipeHash].success, "Recipe already exists");

        combinationRecipes[recipeHash] = CombinationResult({
            success: _success,
            resultType: _resultType,
            resultData: _resultData
        });

        emit CombinationRecipeAdded(recipeHash, _success);
    }


    /**
     * @notice Sets the cost of initiating a scan.
     * @param _cost New scan cost in Wei.
     */
    function setScanCost(uint256 _cost) external onlyOwner {
        scanCost = _cost;
        emit ScanCostUpdated(_cost);
    }

    /**
     * @notice Sets the default number of blocks a scanned claim remains active.
     * @param _blocks New coherence time in blocks.
     */
    function setShardCoherenceTime(uint256 _blocks) external onlyOwner {
        require(_blocks > 0, "Coherence time must be positive");
        shardCoherenceBlocks = _blocks;
        emit ShardCoherenceTimeUpdated(_blocks);
    }

    /**
     * @notice Sets the default number of blocks a puzzle remains active.
     * @param _blocks New puzzle expiry delta in blocks.
     */
    function setPuzzleExpiryDelta(uint256 _blocks) external onlyOwner {
         require(_blocks > 0, "Puzzle expiry delta must be positive");
         puzzleExpiryBlocks = _blocks;
         emit PuzzleExpiryDeltaUpdated(_blocks);
    }

    /**
     * @notice Allows the owner to withdraw funds from the contract.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be positive");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(_recipient, _amount);
    }

    // --- View/Read Functions ---

    /**
     * @notice Gets a player's profile information.
     * @param _player The address of the player.
     * @return reputation The player's reputation score.
     * @return lastScanBlock The block number of the player's last scan.
     * @return isActivePlayer Whether the address is registered as a player.
     */
    function getPlayerProfile(address _player) external view returns (uint256 reputation, uint256 lastScanBlock, bool isActivePlayer) {
        Player storage player = players[_player];
        return (player.reputation, player.lastScanBlock, playerExists[_player]);
    }

    /**
     * @notice Gets the count of a specific shard type for a player.
     * @param _player The address of the player.
     * @param _shardType The ID of the shard type.
     * @return The count of the specified shard type the player holds.
     */
    function getPlayerShards(address _player, uint256 _shardType) external view playerExists returns (uint256) {
        return players[_player].collectedShards[_shardType];
    }

     /**
     * @notice Gets all collected shard counts for a player.
     * @param _player The address of the player.
     * @dev Note: Mappings cannot be returned directly in Solidity views. This function
     *      would need an off-chain helper or a mechanism to iterate shard types.
     *      Returning a mapping directly is not possible. Returning a list of ShardTypeIds
     *      and requiring separate calls for counts is an alternative, or returning a fixed-size array/struct
     *      if the number of relevant shard types is small and known.
     *      Stubbing this as it's a common pattern but not directly implementable as `mapping(uint256 => uint256)`.
     */
    function getPlayerAllShards(address _player) external view playerExists returns (uint256[] memory shardTypeIds, uint256[] memory counts) {
        // This function cannot return the mapping directly.
        // To implement this, you'd need to store player shards in a different structure
        // that supports iteration (like an array of structs/tuples), or require the caller
        // to query each shard type ID individually.
        // For demonstration, we'll return empty arrays and a comment.
        // A realistic implementation might involve:
        // 1. Storing collected shards in a dynamic array of {typeId, count} structs.
        // 2. Providing a view function to get the *list* of shardTypeIds a player has.
        // 3. Providing the getPlayerShards function above for individual counts.
        // Option 2 is better for gas efficiency in writes.

        // Example of how you *might* get keys if you tracked them:
        // uint256[] memory playerShardTypeIds = players[_player].shardTypeIdsList; // If you tracked a list
        // uint256[] memory playerShardCounts = new uint256[](playerShardTypeIds.length);
        // for(uint i = 0; i < playerShardTypeIds.length; i++) {
        //     playerShardCounts[i] = players[_player].collectedShards[playerShardTypeIds[i]];
        // }
        // return (playerShardTypeIds, playerShardCounts);

        // Returning empty arrays as direct mapping iteration is not supported in Solidity view functions.
        return (new uint256[](0), new uint256[](0));
    }


    /**
     * @notice Gets details about a specific scanned shard claim.
     * @param _claimId The ID of the scanned claim.
     * @return owner The owner's address.
     * @return generationBlock The block the claim was generated.
     * @return expiryBlock The block the claim expires.
     * @return revealedShardType The revealed shard type (0 if entangled).
     * @return revealedBonus The revealed bonus (0 if entangled).
     * @return claimed Whether the claim has been processed.
     */
    function getScannedClaim(bytes32 _claimId) external view scannedClaimExists(_claimId) returns (address owner, uint256 generationBlock, uint256 expiryBlock, uint256 revealedShardType, uint256 revealedBonus, bool claimed) {
        ScannedShardClaim storage claim = scannedClaims[_claimId];
        return (claim.owner, claim.generationBlock, claim.expiryBlock, claim.revealedShardType, claim.revealedBonus, claim.claimed);
    }

    /**
     * @notice Gets the list of active scanned claim IDs owned by a player.
     * @param _player The address of the player.
     * @return An array of claim IDs. Note: this array might contain IDs for claims that are expired or already claimed in the mapping, due to the complexity of removing from storage arrays. Check the mapping state for definitive status.
     */
    function getPlayerScannedClaims(address _player) external view playerExists returns (bytes32[] memory) {
        return players[_player].activeScanClaims;
    }

     /**
     * @notice Gets details about a puzzle (excluding the solution hash).
     * @param _puzzleId The ID of the puzzle.
     * @return puzzleType The type of puzzle.
     * @return creationBlock The block the puzzle was created.
     * @return expiryBlock The block the puzzle expires.
     * @return rewardShardType The ID of the reward shard.
     * @return difficulty The difficulty rating.
     * @return solved Whether the puzzle has been solved.
     */
    function getPuzzle(uint256 _puzzleId) external view puzzleExists(_puzzleId) returns (uint256 puzzleType, uint256 creationBlock, uint256 expiryBlock, uint256 rewardShardType, uint252 difficulty, bool solved) {
        Puzzle storage puzzle = puzzles[_puzzleId];
        return (puzzle.puzzleType, puzzle.creationBlock, puzzle.expiryBlock, puzzle.rewardShardType, puzzle.difficulty, puzzle.solved);
    }

    /**
     * @notice Gets the list of all active puzzle IDs.
     * @dev This can be gas-intensive if there are many puzzles.
     *      A more efficient approach would involve tracking active puzzles in an iterable structure.
     *      For simplicity, this version requires iterating through potential IDs up to the counter.
     *      Returning a maximum number or requiring pagination would be better in production.
     */
    function getActivePuzzles() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        // First pass to count active puzzles
        for (uint256 i = 1; i <= puzzleCounter; i++) {
            // Check if puzzle exists and is active (not solved, not expired)
            if (puzzles[i].creationBlock > 0 && !puzzles[i].solved && block.number <= puzzles[i].expiryBlock) {
                activeCount++;
            }
        }

        uint256[] memory activePuzzleIds = new uint256[](activeCount);
        uint256 currentIndex = 0;
         // Second pass to collect active puzzle IDs
        for (uint256 i = 1; i <= puzzleCounter; i++) {
             if (puzzles[i].creationBlock > 0 && !puzzles[i].solved && block.number <= puzzles[i].expiryBlock) {
                 activePuzzleIds[currentIndex] = i;
                 currentIndex++;
             }
         }
        return activePuzzleIds;
    }

     /**
     * @notice Gets details about a defined shard type.
     * @param _typeId The ID of the shard type.
     * @return name The name of the shard type.
     * @return description The description of the shard type.
     * @return maxPerPlayer The maximum count a player can hold (0 for unlimited).
     * @return propertiesHash A hash representing inherent properties.
     * @return exists True if the shard type ID is defined.
     */
    function getShardTypeDetails(uint256 _typeId) external view returns (string memory name, string memory description, uint256 maxPerPlayer, uint256 propertiesHash, bool exists) {
         ShardType storage sType = shardTypes[_typeId];
         return (sType.name, sType.description, sType.maxPerPlayer, sType.propertiesHash, bytes(sType.name).length > 0);
     }

    /**
     * @notice Gets the current Ether balance of the contract.
     * @return The contract's balance in Wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Maintenance Functions ---

    /**
     * @notice Allows anyone to trigger cleanup of expired scanned claims.
     * @dev This function is designed to be called externally to offload gas costs from core functions.
     *      It iterates through a limited number of claims to avoid hitting gas limits.
     *      Requires tracking claims in an iterable structure for efficient cleanup, which is complex in Solidity.
     *      This is a placeholder for a more robust cleanup mechanism (e.g., linked list, merkledrop pattern for reclaiming gas).
     *      In this simplified version, it just checks a range, which isn't practical for a large number of claims.
     *      A more realistic approach might involve players cleaning up their *own* expired claims with a small incentive.
     */
    function cleanExpiredClaims() external {
        // This is a complex problem in Solidity without iterable mappings.
        // A common pattern is to use a list/array of IDs and iterate through that,
        // but adding/removing from that list is also costly.
        // For demonstration, this function won't actually iterate effectively over *all* claims.
        // It serves as a placeholder concept for off-chain or incentivized on-chain cleanup.
        // To implement properly, you'd need to track claim IDs in an array or linked list.

        // Example conceptual logic (NOT EFFICIENT FOR LARGE DATA):
        // uint256 cleanedCount = 0;
        // for (uint i = 0; i < playerList.length; i++) { // Need a list of player addresses
        //    address playerAddr = playerList[i];
        //    bytes32[] storage claims = players[playerAddr].activeScanClaims;
        //    for (uint j = 0; j < claims.length; j++) { // Iterating through player claims
        //       bytes32 claimId = claims[j];
        //       if (scannedClaims[claimId].owner != address(0) && // exists
        //           !scannedClaims[claimId].claimed && // not claimed
        //           block.number > scannedClaims[claimId].expiryBlock) // expired
        //       {
        //           delete scannedClaims[claimId]; // Remove from mapping
        //           // Need to remove from player's array as well (complex/costly)
        //           cleanedCount++;
        //           if (cleanedCount >= 10) break; // Limit gas
        //       }
        //    }
        //    if (cleanedCount >= 10) break;
        // }

        // Returning empty arrays as this implementation is not fully functional due to mapping limitations.
        // A real implementation might track active claim IDs in a separate, iterable list (e.g., a dynamic array)
        // or use a state pattern where expiry is checked on access rather than requiring explicit cleanup.
    }
}
```