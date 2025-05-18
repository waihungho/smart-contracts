Okay, here is a Solidity smart contract implementing a creative, advanced concept: a "Genesis Forge" for evolving digital entities (NFTs).

This contract allows users to "forge" unique entities with on-chain generative traits using a resource called "Essence". Entities can then be "sacrificed" to regain Essence, "mutated" to alter their traits using Essence, or "fused" with another entity to create a new, potentially more powerful entity, also using Essence. Costs for operations dynamically increase based on the entity's evolution history.

It combines concepts from NFTs, generative art, gaming mechanics (crafting, evolution, resource management), and dynamic token properties.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline:
// 1. Contract Definition: Inherits ERC721Enumerable, Ownable, Pausable.
// 2. Events: To signal key actions (Forged, Sacrificed, Mutated, Fused, Essence related, Config changes, Pause).
// 3. Data Structures:
//    - EntityTraits: Stores on-chain attributes (uint8 to save space).
//    - EntityState: Stores dynamic state (evolution counts, parent history).
//    - EssenceParameters: Stores global configuration for Essence costs/yields.
// 4. State Variables:
//    - Mappings for entity data (_entities, _entityState, _genesisSeeds).
//    - Mapping for user Essence balances (_essenceBalances).
//    - Global parameters for costs/yields (_essenceParams).
//    - Counters for total entities and token IDs (_tokenIds, _entitiesForgedCount).
//    - Pausable state (_pausedOps).
//    - Base URI for token metadata.
// 5. Modifiers: Custom modifiers for operational control (e.g., when certain ops are paused).
// 6. Constructor: Initializes the contract, base URI, and initial essence parameters.
// 7. Core Mechanics (require Essence, state change, events):
//    - forgeEntity: Create a new entity with generated traits.
//    - sacrificeEntity: Burn an entity to gain Essence.
//    - mutateEntity: Modify traits of an existing entity.
//    - fuseEntities: Burn two entities to create a new one.
// 8. Essence Management:
//    - getEssenceBalance: View user's Essence.
//    - adminMintEssence: Owner grants Essence (for initial distribution or recovery).
//    - adminBurnEssence: Owner removes Essence.
// 9. Trait & State Queries (View functions):
//    - getEntityTraits: Get entity's on-chain traits.
//    - getEntityState: Get entity's dynamic state.
//    - getEntityAbilityScore: Derived metric based on traits.
//    - getEntityCreationSeed: Get the unique seed used for creation.
// 10. Configuration (Owner-only functions):
//    - setBaseURI: Set the token metadata base URI.
//    - setEssenceParameters: Update costs/yields globally.
//    - pauseContractsOps: Pause specific core operations.
//    - unpauseContractsOps: Unpause specific core operations.
//    - getEssenceParameters: View current costs/yields.
//    - getRequiredEssenceForNextMutation: Calculate dynamic mutation cost.
//    - getRequiredEssenceForNextFusion: Calculate dynamic fusion cost.
// 11. Standard ERC721 Functions: Inherited and/or overridden (e.g., tokenURI).
// 12. Internal Helper Functions: Logic for trait generation, mutation, fusion.


// Function Summary:
// ERC721 Standard (from OpenZeppelin):
// - balanceOf(address owner) view returns (uint256): Get number of entities owned by an address.
// - ownerOf(uint256 tokenId) view returns (address): Get owner of an entity.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// - transferFrom(address from, address to, uint256 tokenId): Transfer entity.
// - approve(address to, uint256 tokenId): Approve address for one entity.
// - setApprovalForAll(address operator, bool approved): Approve operator for all entities.
// - getApproved(uint256 tokenId) view returns (address): Get approved address for an entity.
// - isApprovedForAll(address owner, address operator) view returns (bool): Check if operator is approved.
// - supportsInterface(bytes4 interfaceId) view returns (bool): Standard interface check.
// - name() view returns (string): Contract name.
// - symbol() view returns (string): Contract symbol.
// - tokenByIndex(uint256 index) view returns (uint256): Get token ID at index (from Enumerable).
// - tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256): Get token ID for owner at index (from Enumerable).
// - totalSupply() view returns (uint256): Get total number of entities (from Enumerable).
// - tokenURI(uint256 tokenId) view returns (string): Get metadata URI for entity.

// Custom Genesis Forge Functions:
// - constructor(string memory name, string memory symbol, string memory baseUri): Initializes contract.
// - forgeEntity(uint256 userSeed): Mints a new entity with traits generated from seed and block data. (Requires Essence)
// - sacrificeEntity(uint256 tokenId): Burns an owned entity and grants Essence. (Requires Ownership/Approval)
// - mutateEntity(uint256 tokenId): Modifies traits of an owned entity. (Requires Essence, Ownership/Approval)
// - fuseEntities(uint256 tokenId1, uint256 tokenId2): Burns two owned entities and mints a new one. (Requires Essence, Ownership/Approval for both)
// - getEssenceBalance(address user) view returns (uint96): Get user's current Essence balance.
// - getEntityTraits(uint256 tokenId) view returns (EntityTraits): Get the stored on-chain traits of an entity.
// - getEntityState(uint256 tokenId) view returns (EntityState): Get the stored dynamic state of an entity.
// - getEntityAbilityScore(uint256 tokenId) view returns (uint256): Calculates a simple score based on entity traits.
// - getEntityCreationSeed(uint256 tokenId) view returns (bytes32): Get the hash used as the genesis seed.
// - setBaseURI(string memory baseUri_): Owner sets the base URI for token metadata.
// - setEssenceParameters(EssenceParameters memory params_): Owner sets the global Essence costs and yields.
// - pauseContractsOps(): Owner pauses forging, mutating, and fusing.
// - unpauseContractsOps(): Owner unpauses forging, mutating, and fusing.
// - isContractOpsPaused() view returns (bool): Check if core operations are paused.
// - getEssenceParameters() view returns (EssenceParameters): Get the current Essence configuration.
// - getRequiredEssenceForNextMutation(uint256 tokenId) view returns (uint96): Calculate the cost for the next mutation based on its state.
// - getRequiredEssenceForNextFusion(uint256 tokenId1, uint256 tokenId2) view returns (uint96): Calculate the cost for fusion based on parent states.
// - adminMintEssence(address user, uint96 amount): Owner grants Essence to a user.
// - adminBurnEssence(address user, uint96 amount): Owner removes Essence from a user.

contract GenesisForge is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- Events ---
    event Forged(uint256 indexed tokenId, address indexed minter, bytes32 genesisSeed);
    event Sacrificed(uint256 indexed tokenId, address indexed owner, uint96 essenceYielded);
    event Mutated(uint256 indexed tokenId, address indexed owner, uint96 essenceConsumed, EntityTraits newTraits);
    event Fused(uint256 indexed newTokenId, uint256 indexed parentTokenId1, uint256 indexed parentTokenId2, address indexed owner, uint96 essenceConsumed);
    event EssenceMinted(address indexed user, uint96 amount);
    event EssenceBurned(address indexed user, uint96 amount);
    event EssenceParametersUpdated(EssenceParameters newParams);
    event ContractOpsPaused(bool paused);

    // --- Data Structures ---

    // Basic traits (can be expanded)
    struct EntityTraits {
        uint8 strength;    // 0-255
        uint8 dexterity;   // 0-255
        uint8 constitution; // 0-255
        uint8 intelligence; // 0-255
        uint8 charisma;    // 0-255
    }

    // Dynamic state of an entity
    struct EntityState {
        uint64 mutationCount; // How many times this entity has been mutated
        uint64 fusionCount;   // How many times this entity has been used as a parent in fusion
        uint256 parentTokenId1; // ID of first parent (0 for forged entities)
        uint256 parentTokenId2; // ID of second parent (0 for forged entities)
    }

    // Configuration for Essence costs and yields
    struct EssenceParameters {
        uint96 forgingCost;
        uint96 sacrificeYield;
        uint96 baseMutationCost;
        uint96 baseFusionCost;
        uint64 mutationCostMultiplier; // Cost increases by base * multiplier * mutationCount
        uint64 fusionCostMultiplier;   // Cost increases by base * multiplier * max(parentMutation/Fusion Counts)
    }

    // --- State Variables ---

    Counters.Counter private _tokenIds;
    uint256 private _entitiesForgedCount; // Total ever forged (including parents of fusions before burning)

    // Mapping from token ID to entity traits
    mapping(uint256 => EntityTraits) private _entities;
    // Mapping from token ID to entity state
    mapping(uint256 => EntityState) private _entityState;
    // Mapping from token ID to the original genesis seed hash
    mapping(uint256 => bytes32) private _genesisSeeds;

    // Mapping from user address to their Essence balance
    mapping(address => uint96) private _essenceBalances;

    // Global parameters for Essence costs and yields
    EssenceParameters private _essenceParams;

    // Base URI for token metadata (delegates heavy lifting off-chain)
    string private _baseTokenURI;

    // Pausability state for core operations (forge, mutate, fuse)
    bool private _pausedOps;

    // --- Modifiers ---

    // Ensure a token ID exists and belongs to the owner or an approved operator
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

    // Check if the core contract operations (forge, mutate, fuse) are paused
    modifier whenContractOpsNotPaused() {
        require(!_pausedOps, "Contract operations are paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseUri)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseUri;
        // Set initial default parameters
        _essenceParams = EssenceParameters({
            forgingCost: 100,
            sacrificeYield: 80,
            baseMutationCost: 50,
            baseFusionCost: 200,
            mutationCostMultiplier: 10,
            fusionCostMultiplier: 20
        });
        _pausedOps = false;
    }

    // --- Standard ERC721 Overrides ---

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId); // Ensure token exists
        // Append token ID and potentially query parameters for dynamic data
        return string(abi.encodePacked(_baseTokenURI, toString(tokenId)));
    }

    // Required override for ERC721Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Required override for ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // --- Core Mechanics ---

    /**
     * @notice Forges a new entity (NFT) with unique, on-chain generated traits.
     * Requires Essence from the caller.
     * @param userSeed A seed provided by the user to influence generation (e.g., a lucky number).
     */
    function forgeEntity(uint256 userSeed) external whenContractOpsNotPaused {
        uint96 requiredEssence = _essenceParams.forgingCost;
        require(_essenceBalances[msg.sender] >= requiredEssence, "Insufficient Essence");

        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        _entitiesForgedCount++;

        bytes32 genesisSeed = _generateTraits(newTokenId, userSeed, msg.sender);
        EntityTraits memory newTraits = _entities[newTokenId]; // Traits were written by _generateTraits

        _entityState[newTokenId] = EntityState({
            mutationCount: 0,
            fusionCount: 0,
            parentTokenId1: 0,
            parentTokenId2: 0
        });

        _genesisSeeds[newTokenId] = genesisSeed;
        _essenceBalances[msg.sender] -= requiredEssence;

        _safeMint(msg.sender, newTokenId);

        emit Forged(newTokenId, msg.sender, genesisSeed);
    }

    /**
     * @notice Sacrifices an owned entity, burning it permanently and yielding Essence to the owner.
     * @param tokenId The ID of the entity to sacrifice.
     */
    function sacrificeEntity(uint256 tokenId) external onlyOwnerOrApproved(tokenId) {
        address owner = ownerOf(tokenId); // Get owner before burn

        _burn(tokenId); // Burns the token and removes its data from ERC721Enumerable

        // Clean up custom storage
        delete _entities[tokenId];
        delete _entityState[tokenId];
        delete _genesisSeeds[tokenId];

        uint96 yieldedEssence = _essenceParams.sacrificeYield;
        _essenceBalances[owner] += yieldedEssence;

        emit Sacrificed(tokenId, owner, yieldedEssence);
    }

    /**
     * @notice Mutates an owned entity, changing its traits based on its history and Essence consumed.
     * @param tokenId The ID of the entity to mutate.
     */
    function mutateEntity(uint256 tokenId) external onlyOwnerOrApproved(tokenId) whenContractOpsNotPaused {
        EntityState storage state = _entityState[tokenId];
        uint96 requiredEssence = getRequiredEssenceForNextMutation(tokenId);

        require(_essenceBalances[msg.sender] >= requiredEssence, "Insufficient Essence for mutation");

        _essenceBalances[msg.sender] -= requiredEssence;

        _mutateTraits(tokenId, state.mutationCount, requiredEssence);
        state.mutationCount++;

        emit Mutated(tokenId, msg.sender, requiredEssence, _entities[tokenId]);
    }

    /**
     * @notice Fuses two owned entities into a single new entity.
     * The two parent entities are burned, and a new entity is minted with traits derived from the parents and the fusion process.
     * @param tokenId1 The ID of the first entity to fuse.
     * @param tokenId2 The ID of the second entity to fuse.
     */
    function fuseEntities(uint256 tokenId1, uint256 tokenId2) external whenContractOpsNotPaused {
        require(tokenId1 != tokenId2, "Cannot fuse an entity with itself");
        require(_exists(tokenId1), "Entity 1 does not exist");
        require(_exists(tokenId2), "Entity 2 does not exist");

        // Check ownership/approval for both
        require(_isApprovedOrOwner(msg.sender, tokenId1), "Not owner or approved for entity 1");
        require(_isApprovedOrOwner(msg.sender, tokenId2), "Not owner or approved for entity 2");

        uint96 requiredEssence = getRequiredEssenceForNextFusion(tokenId1, tokenId2);
        require(_essenceBalances[msg.sender] >= requiredEssence, "Insufficient Essence for fusion");

        _essenceBalances[msg.sender] -= requiredEssence;

        // Store parent state before burning
        EntityState memory parentState1 = _entityState[tokenId1];
        EntityState memory parentState2 = _entityState[tokenId2];

        // Burn the parent entities
        _burn(tokenId1);
        _burn(tokenId2);

        // Clean up custom storage for parents
        delete _entities[tokenId1];
        delete _entityState[tokenId1];
        delete _genesisSeeds[tokenId1];
        delete _entities[tokenId2];
        delete _entityState[tokenId2];
        delete _genesisSeeds[tokenId2];

        // Forge the new fused entity
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        _entitiesForgedCount++; // Count the new entity

        bytes32 genesisSeed = _fuseTraits(newTokenId, tokenId1, tokenId2, requiredEssence, parentState1, parentState2);
        EntityTraits memory newTraits = _entities[newTokenId]; // Traits written by _fuseTraits

        _entityState[newTokenId] = EntityState({
            mutationCount: 0, // Fused entity starts with fresh evolution count
            fusionCount: 0,
            parentTokenId1: tokenId1,
            parentTokenId2: tokenId2
        });

        _genesisSeeds[newTokenId] = genesisSeed;

        _safeMint(msg.sender, newTokenId);

        emit Fused(newTokenId, tokenId1, tokenId2, msg.sender, requiredEssence);
        // Optionally emit Forged for the new entity as well? Let's stick to Fused to distinguish origin.
    }

    // --- Essence Management ---

    /**
     * @notice Gets the Essence balance for a given user.
     * @param user The address of the user.
     * @return uint96 The user's current Essence balance.
     */
    function getEssenceBalance(address user) external view returns (uint96) {
        return _essenceBalances[user];
    }

    /**
     * @notice Owner can mint Essence for a specific user.
     * Useful for initial distribution or compensation.
     * @param user The address to mint Essence to.
     * @param amount The amount of Essence to mint.
     */
    function adminMintEssence(address user, uint96 amount) external onlyOwner {
        require(user != address(0), "Cannot mint to the zero address");
        _essenceBalances[user] += amount;
        emit EssenceMinted(user, amount);
    }

    /**
     * @notice Owner can burn (remove) Essence from a user.
     * Useful for correcting errors or administrative reasons.
     * @param user The address to burn Essence from.
     * @param amount The amount of Essence to burn.
     */
    function adminBurnEssence(address user, uint96 amount) external onlyOwner {
        require(user != address(0), "Cannot burn from the zero address");
        require(_essenceBalances[user] >= amount, "User has insufficient Essence to burn");
        _essenceBalances[user] -= amount;
        emit EssenceBurned(user, amount);
    }


    // --- Trait & State Queries ---

    /**
     * @notice Gets the stored on-chain traits for a specific entity.
     * @param tokenId The ID of the entity.
     * @return EntityTraits The traits struct.
     */
    function getEntityTraits(uint256 tokenId) public view returns (EntityTraits memory) {
        _requireOwned(tokenId); // Ensure token exists
        return _entities[tokenId];
    }

    /**
     * @notice Gets the stored dynamic state for a specific entity.
     * @param tokenId The ID of the entity.
     * @return EntityState The state struct.
     */
    function getEntityState(uint256 tokenId) public view returns (EntityState memory) {
         _requireOwned(tokenId); // Ensure token exists
        return _entityState[tokenId];
    }

    /**
     * @notice Calculates a simple derived ability score based on the entity's current traits.
     * This is an example, can be complex game logic.
     * @param tokenId The ID of the entity.
     * @return uint256 A calculated score.
     */
    function getEntityAbilityScore(uint256 tokenId) public view returns (uint256) {
        EntityTraits memory traits = getEntityTraits(tokenId);
        // Simple scoring: sum of traits + bonus for having high primary stats
        uint256 score = traits.strength + traits.dexterity + traits.constitution + traits.intelligence + traits.charisma;
        if (traits.strength >= 200 && traits.constitution >= 200) score += 50;
        if (traits.intelligence >= 200 && traits.charisma >= 200) score += 50;
        return score;
    }

    /**
     * @notice Gets the unique genesis seed used during the creation of an entity.
     * This provides provenance for forged entities.
     * @param tokenId The ID of the entity.
     * @return bytes32 The genesis seed hash.
     */
    function getEntityCreationSeed(uint256 tokenId) public view returns (bytes32) {
        _requireOwned(tokenId); // Ensure token exists
        return _genesisSeeds[tokenId];
    }

    /**
     * @notice Gets the total number of entities ever forged by the contract.
     * Includes entities burned during fusion.
     * @return uint256 Total forged count.
     */
    function getTotalEntitiesForged() public view returns (uint256) {
        return _entitiesForgedCount;
    }


    // --- Configuration ---

    /**
     * @notice Owner sets the base URI for the token metadata.
     * This URI should typically point to an API that serves JSON metadata for each token ID.
     * @param baseUri_ The new base URI string.
     */
    function setBaseURI(string memory baseUri_) external onlyOwner {
        _baseTokenURI = baseUri_;
    }

    /**
     * @notice Owner sets the global parameters for Essence costs and yields.
     * This allows tuning the economy of the Forge.
     * @param params_ The new EssenceParameters struct.
     */
    function setEssenceParameters(EssenceParameters memory params_) external onlyOwner {
        _essenceParams = params_;
        emit EssenceParametersUpdated(params_);
    }

     /**
     * @notice Owner can pause the core contract operations (forge, mutate, fuse).
     * Standard Pausable is used for transfers, this adds specific control over creation/evolution.
     */
    function pauseContractsOps() external onlyOwner {
        _pausedOps = true;
        emit ContractOpsPaused(true);
    }

    /**
     * @notice Owner can unpause the core contract operations.
     */
    function unpauseContractsOps() external onlyOwner {
        _pausedOps = false;
        emit ContractOpsPaused(false);
    }

    /**
     * @notice Checks if core contract operations (forge, mutate, fuse) are currently paused.
     * @return bool True if operations are paused, false otherwise.
     */
    function isContractOpsPaused() external view returns (bool) {
        return _pausedOps;
    }

    /**
     * @notice Gets the current global Essence parameters.
     * @return EssenceParameters The current parameters struct.
     */
    function getEssenceParameters() external view returns (EssenceParameters memory) {
        return _essenceParams;
    }

    /**
     * @notice Calculates the required Essence to perform the next mutation on a specific entity.
     * Cost increases based on the entity's current mutation count.
     * @param tokenId The ID of the entity.
     * @return uint96 The Essence cost for the next mutation.
     */
    function getRequiredEssenceForNextMutation(uint256 tokenId) public view returns (uint96) {
        _requireOwned(tokenId); // Ensure token exists
        EntityState memory state = _entityState[tokenId];
        // Cost = base cost + (mutation count * multiplier)
        uint256 cost = uint256(_essenceParams.baseMutationCost) + (uint256(state.mutationCount) * _essenceParams.mutationCostMultiplier);
        // Cap cost to uint96 max if necessary, though unlikely with reasonable multipliers
        return uint96(cost > type(uint96).max ? type(uint96).max : cost);
    }

    /**
     * @notice Calculates the required Essence to fuse two entities.
     * Cost increases based on the higher mutation/fusion count of the two parents.
     * @param tokenId1 The ID of the first entity.
     * @param tokenId2 The ID of the second entity.
     * @return uint96 The Essence cost for fusion.
     */
    function getRequiredEssenceForNextFusion(uint256 tokenId1, uint256 tokenId2) public view returns (uint96) {
         _requireOwned(tokenId1); // Ensure token exists
         _requireOwned(tokenId2); // Ensure token exists
        EntityState memory state1 = _entityState[tokenId1];
        EntityState memory state2 = _entityState[tokenId2];
        uint64 maxParentEvolution = state1.mutationCount > state2.mutationCount ? state1.mutationCount : state2.mutationCount;
        maxParentEvolution = maxParentEvolution > state1.fusionCount ? maxParentEvolution : state1.fusionCount;
        maxParentEvolution = maxParentEvolution > state2.fusionCount ? maxParentEvolution : state2.fusionCount;

        // Cost = base cost + (max parent evolution count * multiplier)
        uint256 cost = uint256(_essenceParams.baseFusionCost) + (uint256(maxParentEvolution) * _essenceParams.fusionCostMultiplier);
        // Cap cost to uint96 max
        return uint96(cost > type(uint96).max ? type(uint96).max : cost);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Generates initial traits for a new entity based on unique inputs.
     * Uses block data and a user seed for deterministic but hard-to-predict results.
     * Traits are written directly to the _entities mapping.
     * @param tokenId The ID of the entity being created.
     * @param userSeed A seed provided by the user.
     * @param minter The address of the minter.
     * @return bytes32 The combined hash used as the genesis seed.
     */
    function _generateTraits(uint256 tokenId, uint256 userSeed, address minter) internal returns (bytes32) {
        // Combine block data, user seed, minter, and token ID for a unique seed
        bytes32 genesisSeed = keccak256(
            abi.encodePacked(
                tokenId,
                userSeed,
                minter,
                block.timestamp,
                block.number,
                block.difficulty, // block.difficulty is deprecated in PoS, use block.prevrandao
                block.coinbase // block.coinbase is deprecated in PoS, address(0) or random
            )
        );

        uint256 random = uint256(genesisSeed);
        EntityTraits storage traits = _entities[tokenId];

        // Derive traits from the random seed
        traits.strength = uint8(random % 256); random /= 256;
        traits.dexterity = uint8(random % 256); random /= 256;
        traits.constitution = uint8(random % 256); random /= 256;
        traits.intelligence = uint8(random % 256); random /= 256;
        traits.charisma = uint8(random % 256);

        return genesisSeed;
    }

    /**
     * @dev Mutates the traits of an existing entity.
     * The amount and type of mutation are influenced by the Essence consumed and the entity's history.
     * Traits are modified in place in the _entities mapping.
     * @param tokenId The ID of the entity to mutate.
     * @param currentMutationCount The entity's current mutation count.
     * @param essenceConsumed The amount of Essence used for this mutation.
     */
    function _mutateTraits(uint256 tokenId, uint64 currentMutationCount, uint96 essenceConsumed) internal {
        // Generate a new random source based on the original seed, history, and current context
        bytes32 mutationSeed = keccak256(
            abi.encodePacked(
                _genesisSeeds[tokenId],
                currentMutationCount,
                essenceConsumed,
                block.timestamp,
                block.number
            )
        );

        uint256 random = uint256(mutationSeed);
        EntityTraits storage traits = _entities[tokenId];

        // Determine how many traits to potentially affect (e.g., 1 + essence / threshold)
        // Determine magnitude of change (e.g., based on essence)
        uint256 maxChange = uint256(essenceConsumed / 20); // Example: more essence = potentially bigger changes
        if (maxChange == 0) maxChange = 1; // Ensure at least some change potential

        uint256 traitsToMutate = 1 + (random % 3); // Mutate 1 to 3 traits
        random /= 256;

        for(uint256 i = 0; i < traitsToMutate; i++) {
            uint8 traitIndex = uint8(random % 5); // Pick a trait index (0-4)
            random /= 256;

            int256 changeAmount = int256(random % (maxChange * 2 + 1)) - int256(maxChange); // Change between -maxChange and +maxChange
            random /= 256;

            // Apply change, clamping between 0 and 255
            if (traitIndex == 0) traits.strength = uint8(Math.max(0, Math.min(255, int256(traits.strength) + changeAmount)));
            else if (traitIndex == 1) traits.dexterity = uint8(Math.max(0, Math.min(255, int256(traits.dexterity) + changeAmount)));
            else if (traitIndex == 2) traits.constitution = uint8(Math.max(0, Math.min(255, int256(traits.constitution) + changeAmount)));
            else if (traitIndex == 3) traits.intelligence = uint8(Math.max(0, Math.min(255, int256(traits.intelligence) + changeAmount)));
            else if (traitIndex == 4) traits.charisma = uint8(Math.max(0, Math.min(255, int256(traits.charisma) + changeAmount)));
        }
    }

    /**
     * @dev Fuses the traits of two parent entities to generate traits for a new entity.
     * @param newTokenId The ID of the new entity being created.
     * @param parentTokenId1 The ID of the first parent entity.
     * @param parentTokenId2 The ID of the second parent entity.
     * @param essenceConsumed The amount of Essence used for this fusion.
     * @param parentState1 The state of the first parent.
     * @param parentState2 The state of the second parent.
     * @return bytes32 The combined hash used as the genesis seed for the new entity.
     */
    function _fuseTraits(uint256 newTokenId, uint256 parentTokenId1, uint256 parentTokenId2, uint96 essenceConsumed, EntityState memory parentState1, EntityState memory parentState2) internal returns (bytes32) {
         EntityTraits memory traits1 = _entities[parentTokenId1];
         EntityTraits memory traits2 = _entities[parentTokenId2];

        // Generate a new random source based on parent seeds, history, and current context
        bytes32 fusionSeed = keccak256(
            abi.encodePacked(
                _genesisSeeds[parentTokenId1],
                _genesisSeeds[parentTokenId2],
                parentState1.mutationCount,
                parentState2.mutationCount,
                parentState1.fusionCount,
                parentState2.fusionCount,
                essenceConsumed,
                block.timestamp,
                block.number,
                newTokenId // Include new token ID for uniqueness
            )
        );

        uint256 random = uint256(fusionSeed);
        EntityTraits storage newTraits = _entities[newTokenId];

        // Basic fusion logic: average traits, with a chance for random deviation
        uint256 maxDeviation = uint256(essenceConsumed / 50); // Example: more essence allows higher deviation
        if (maxDeviation == 0) maxDeviation = 5; // Ensure some potential deviation

        // Apply logic for each trait
        newTraits.strength = uint8(Math.max(0, Math.min(255, (uint256(traits1.strength) + uint256(traits2.strength)) / 2 + int256(random % (maxDeviation * 2 + 1)) - int256(maxDeviation)))); random /= 256;
        newTraits.dexterity = uint8(Math.max(0, Math.min(255, (uint256(traits1.dexterity) + uint256(traits2.dexterity)) / 2 + int256(random % (maxDeviation * 2 + 1)) - int256(maxDeviation)))); random /= 256;
        newTraits.constitution = uint8(Math.max(0, Math.min(255, (uint256(traits1.constitution) + uint256(traits2.constitution)) / 2 + int256(random % (maxDeviation * 2 + 1)) - int256(maxDeviation)))); random /= 256;
        newTraits.intelligence = uint8(Math.max(0, Math.min(255, (uint256(traits1.intelligence) + uint256(traits2.intelligence)) / 2 + int256(random % (maxDeviation * 2 + 1)) - int256(maxDeviation)))); random /= 256;
        newTraits.charisma = uint8(Math.max(0, Math.min(255, (uint256(traits1.charisma) + uint256(traits2.charisma)) / 2 + int256(random % (maxDeviation * 2 + 1)) - int256(maxDeviation))));

        // Example: Maybe add a rare chance for an extreme value or specific combo based on seeds/random

        return fusionSeed;
    }

    // --- Utility Functions ---

    // Helper to convert uint256 to string
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Simple Math helpers to avoid external library dependency for min/max on int256
    library Math {
        function max(int256 a, int256 b) internal pure returns (int256) {
            return a >= b ? a : b;
        }

        function min(int256 a, int256 b) internal pure returns (int256) {
            return a < b ? a : b;
        }
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **On-Chain Generative Traits:** Entity traits (`strength`, `dexterity`, etc.) are not predefined but generated deterministically when `forgeEntity` is called. The generation uses a combination of user-provided input (`userSeed`), contract state (`tokenId`, `minter`), and block data (`block.timestamp`, `block.number`, `block.difficulty`/`prevrandao`, `block.coinbase`/`coinbase`). While block data is pseudorandom on EVM, combining it with a user seed and internal state makes the output non-predictable by the user before the block is mined, while still being verifiable on-chain after the fact via the stored `genesisSeed`.
2.  **Custom Fungible Resource ("Essence"):** The contract introduces a separate internal resource (`Essence`) tracked per user. This resource is central to the mechanics, required for forging, mutating, and fusing. It's not a separate ERC20 token but managed within the contract's state for gas efficiency and tight integration.
3.  **Sacrifice Mechanism:** Entities are not just burned arbitrarily; they can be `sacrificeEntity`d to yield `Essence`. This creates a circular economy within the contract: you need Essence to create/evolve entities, and you can burn entities you no longer want to recoup some Essence.
4.  **Mutation Mechanism:** The `mutateEntity` function allows altering the traits of an existing entity. This process consumes Essence and modifies the entity's traits based on a new pseudo-random seed derived from its *original genesis seed*, its *mutation history*, and the *current block context*. This adds an evolutionary aspect where entities can change over time.
5.  **Fusion Mechanism:** The `fuseEntities` function allows combining two existing entities into a single new one. This is more complex than just transferring traits; it burns the two parent entities and mints a brand-new entity. The traits of the new entity are derived from a combination (e.g., average, weighted, random mix) of the parents' traits, influenced by Essence consumed and a new random seed. The new entity's state explicitly tracks its parent IDs, creating a lineage.
6.  **Dynamic Costs:** The Essence costs for mutation and fusion (`getRequiredEssenceForNextMutation`, `getRequiredEssenceForNextFusion`) are not fixed but increase based on the entity's history (mutation count) or the parents' history (max mutation/fusion counts). This adds a layer of complexity and makes repeated evolution or fusion more expensive, balancing the game/system.
7.  **On-Chain Traits & Dynamic Metadata:** Entity traits are stored directly within the contract state (`_entities` mapping). The `tokenURI` function would typically point to an API that reads these on-chain traits and state via contract calls to generate the JSON metadata and image/visual representation *dynamically*. This is a common pattern for dynamic NFTs and allows the visual representation to change as the entity mutates or evolves, based purely on verifiable on-chain data.
8.  **Derived Attributes:** The `getEntityAbilityScore` is an example of how game-like attributes or scores can be derived *on-chain* from the fundamental traits. This score can then be used in further on-chain or off-chain logic (e.g., battling games, leaderboards).

This contract goes beyond a simple ERC721 with static metadata by integrating generative processes, resource management, and evolutionary mechanics directly into the token lifecycle.