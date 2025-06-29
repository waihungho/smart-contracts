Okay, here is a smart contract idea that incorporates concepts like dynamic NFTs, on-chain genetic data, evolution mechanics, breeding, and resource consumption, going beyond typical generative art or basic NFT projects.

**Concept: Evolutionary Digital Art**

This contract represents unique digital art pieces (NFTs) that possess on-chain "genetic" data. These pieces can evolve over time or through specific actions, changing their genetic makeup and thus their visual representation (rendered off-chain). They can also be "bred" together to create new, descendant art pieces with combined traits. Actions like evolution and breeding may require a specific resource token.

---

**Outline & Function Summary**

**Contract Name:** `EvolutionaryDigitalArt`

**Core Concepts:**
1.  **Dynamic NFTs:** Art pieces (NFTs) whose on-chain data (genes, generation) can change after minting.
2.  **On-chain Genes:** A significant piece of data stored on-chain for each NFT, determining its traits and potential evolution paths (visual rendering is off-chain).
3.  **Evolution:** A process where an existing NFT changes its genes and generation, potentially requiring resources and cooldowns.
4.  **Breeding:** A process where two existing NFTs combine their genes to create a new descendant NFT, potentially requiring resources and cooldowns.
5.  **Resource Consumption:** Actions like evolution and breeding might require burning or transferring a specific ERC20 token.
6.  **Pausable & Ownable:** Standard administrative controls.

**Function Summary:**

*   **ERC721 Standard Functions (Included for completeness and function count):**
    *   `balanceOf(address owner)`: Returns the number of tokens owned by a specific address.
    *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific token ID.
    *   `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific token.
    *   `getApproved(uint256 tokenId)`: Gets the approved address for a single token.
    *   `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator to manage all of your tokens.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an address is an approved operator for another address.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token from one address to another (requires approval).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token (checks if the recipient can receive NFTs).
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers a token with additional data.
    *   `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token.

*   **Minting & Creation:**
    *   `mintInitialArt(address owner, bytes32 initialGenes)`: Mints a genesis art piece (likely restricted access).
    *   `breedArt(uint256 parent1Id, uint256 parent2Id)`: Creates a new art piece by combining the genes of two parent NFTs owned by the caller.

*   **Evolution Mechanics:**
    *   `triggerEvolution(uint256 tokenId)`: Initiates the evolution process for a specific art piece owned by the caller.
    *   `getEvolutionRequirements(uint256 tokenId)`: Returns the requirements (cost, cooldown) for the next possible evolution of a token.
    *   `previewEvolution(uint256 tokenId)`: A view function to simulate and return the potential resulting genes after the next evolution without performing it.
    *   `setEvolutionConfig(uint8 configId, uint256 requiredGeneration, uint256 requiredResourceAmount, bytes32 geneMutationMask)`: Admin function to define/update evolution types and costs.
    *   `getEvolutionConfig(uint8 configId)`: View function to retrieve details of an evolution config.

*   **Gene & Data Interaction:**
    *   `getGenes(uint256 tokenId)`: Returns the current on-chain genetic data for a token.
    *   `getGeneration(uint256 tokenId)`: Returns the evolution generation of a token.
    *   `getLastEvolutionTime(uint256 tokenId)`: Returns the timestamp of the last evolution.
    *   `getParentTokens(uint256 tokenId)`: Returns the IDs of the parent tokens if bred, or 0,0 if genesis.
    *   `getTokenAttributes(uint256 tokenId)`: Returns a struct containing various attributes of a token (genes, generation, times, parents).

*   **Configuration & Utility:**
    *   `setBreedingConfig(uint256 cost, uint48 cooldownSeconds)`: Admin function to set breeding costs and cooldown.
    *   `setResourceToken(address resourceTokenAddress)`: Admin function to set the address of the ERC20 resource token.
    *   `withdrawResourceTokens(address to)`: Admin function to withdraw collected resource tokens.
    *   `setBaseURI(string memory baseURI)`: Admin function to set the base URI for token metadata.
    *   `pause()`: Admin function to pause key contract actions (minting, evolving, breeding).
    *   `unpause()`: Admin function to unpause the contract.

---

**Smart Contract Code (Solidity)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom errors
error InvalidTokenId();
error NotTokenOwner();
error EvolutionNotAvailable();
error BreedingNotAvailable();
error NotEnoughResourceToken();
error InvalidEvolutionConfig();
error InvalidMutationMask();

contract EvolutionaryDigitalArt is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenCounter;

    struct ArtData {
        bytes32 genes;         // Core on-chain genetic data
        uint256 generation;    // Evolution generation (0 for genesis)
        uint48 createdTime;    // Timestamp of creation
        uint48 lastEvolutionTime; // Timestamp of last evolution
        uint256 parentId1;     // Parent 1 token ID (0 for genesis)
        uint256 parentId2;     // Parent 2 token ID (0 for genesis)
    }

    // Mapping from token ID to its ArtData
    mapping(uint256 tokenId => ArtData) private _tokenData;

    struct EvolutionConfig {
        uint256 requiredGeneration;    // Minimum generation to use this config
        uint256 requiredResourceAmount; // Amount of resource token needed
        bytes32 geneMutationMask;      // Mask defining how genes change (implementation specific)
        string description;            // Description of the evolution type
    }

    // Mapping from evolution config ID to its configuration
    mapping(uint8 configId => EvolutionConfig) private _evolutionConfigs;
    uint8 private _nextEvolutionConfigId = 1; // Start config IDs from 1

    struct BreedingConfig {
        uint256 resourceCost;         // Amount of resource token needed to breed
        uint48 cooldownSeconds;       // Cooldown duration after breeding
    }

    BreedingConfig private _breedingConfig;
    mapping(uint256 tokenId => uint48) private _breedingCooldowns; // Cooldown for each token

    // Address of the resource token required for actions
    IERC20 private _resourceToken;

    // Base URI for metadata
    string private _baseTokenURI;

    // --- Events ---
    event GenesChanged(uint256 indexed tokenId, bytes32 oldGenes, bytes32 newGenes);
    event EvolutionTriggered(uint256 indexed tokenId, uint256 indexed newGeneration, uint8 evolutionConfigId);
    event ArtBred(uint256 indexed newChildTokenId, uint256 indexed parent1Id, uint256 indexed parent2Id, bytes32 childGenes);
    event ResourceTokenSet(address indexed resourceTokenAddress);
    event EvolutionConfigSet(uint8 indexed configId, uint256 requiredGeneration, uint256 requiredResourceAmount);
    event BreedingConfigSet(uint256 resourceCost, uint48 cooldownSeconds);

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- ERC721 Overrides ---

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        return super.balanceOf(owner);
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public override(ERC721) onlyOwnerOf(tokenId) {
        super.approve(to, tokenId);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.getApproved(tokenId);
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public override(ERC721) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override(ERC721) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
         super.transferFrom(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // Off-chain service will resolve the gene data using this URI
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // --- Custom Core Functions ---

    /// @notice Mints a new genesis art piece. Can only be called by the owner/deployer.
    /// @param owner The address to mint the token to.
    /// @param initialGenes The initial genetic data for the art piece.
    function mintInitialArt(address owner, bytes32 initialGenes) public onlyOwner whenNotPaused {
        _tokenCounter.increment();
        uint256 newTokenId = _tokenCounter.current();

        _tokenData[newTokenId] = ArtData({
            genes: initialGenes,
            generation: 0, // Genesis generation
            createdTime: uint48(block.timestamp),
            lastEvolutionTime: uint48(block.timestamp), // Set initial evolution time for cooldowns
            parentId1: 0,
            parentId2: 0
        });

        _safeMint(owner, newTokenId);
        emit GenesChanged(newTokenId, bytes32(0), initialGenes);
    }

    /// @notice Creates a new art piece by breeding two parent tokens.
    /// Requires ownership of both parents and pays a resource token fee.
    /// @param parent1Id The token ID of the first parent.
    /// @param parent2Id The token ID of the second parent.
    /// @dev The gene combination logic is a simple example; complex logic would be off-chain or more sophisticated.
    function breedArt(uint256 parent1Id, uint256 parent2Id) public whenNotPaused {
        address caller = msg.sender;

        if (ownerOf(parent1Id) != caller || ownerOf(parent2Id) != caller) {
            revert NotTokenOwner();
        }
        if (parent1Id == parent2Id) {
             revert BreedingNotAvailable(); // Cannot breed with itself
        }

        uint48 currentTimestamp = uint48(block.timestamp);
        if (_breedingCooldowns[parent1Id] > currentTimestamp || _breedingCooldowns[parent2Id] > currentTimestamp) {
            revert BreedingNotAvailable(); // Tokens are on cooldown
        }

        uint256 requiredCost = _breedingConfig.resourceCost;
        if (address(_resourceToken) == address(0) || _resourceToken.balanceOf(caller) < requiredCost) {
             revert NotEnoughResourceToken(); // Resource token not set or not enough balance
        }

        // --- Gene Combination Logic (Example) ---
        bytes32 genes1 = _tokenData[parent1Id].genes;
        bytes32 genes2 = _tokenData[parent2Id].genes;
        // Simple alternating bytes or XOR, etc. More complex logic is possible.
        // For demonstration, let's just XOR and add a simple 'mutation' based on block data.
        bytes32 childGenes = genes1 ^ genes2;
        bytes32 mutationSeed = bytes32(uint256(block.timestamp) ^ uint256(block.difficulty) ^ uint256(parent1Id) ^ uint256(parent2Id));
        // Apply a simple mutation based on the seed - highly simplified pseudo-randomness
        if (uint256(mutationSeed) % 10 == 0) { // 10% chance of mutation
             childGenes ^= bytes32(uint256(block.gaslimit)); // Example mutation
        }
        // Ensure child genes are valid according to contract rules if needed (e.g., check against a list)

        // Pay resource token fee
        _resourceToken.transferFrom(caller, address(this), requiredCost);

        // Mint the new token
        _tokenCounter.increment();
        uint256 newChildTokenId = _tokenCounter.current();

        _tokenData[newChildTokenId] = ArtData({
            genes: childGenes,
            generation: Math.max(_tokenData[parent1Id].generation, _tokenData[parent2Id].generation).add(1), // Increment generation
            createdTime: currentTimestamp,
            lastEvolutionTime: currentTimestamp, // Set initial evolution time for cooldowns
            parentId1: parent1Id,
            parentId2: parent2Id
        });

        _safeMint(caller, newChildTokenId);

        // Set cooldowns for parents
        _breedingCooldowns[parent1Id] = currentTimestamp + _breedingConfig.cooldownSeconds;
        _breedingCooldowns[parent2Id] = currentTimestamp + _breedingConfig.cooldownSeconds;

        emit ArtBred(newChildTokenId, parent1Id, parent2Id, childGenes);
        emit GenesChanged(newChildTokenId, bytes32(0), childGenes);
    }

    /// @notice Triggers the evolution of a specific art piece owned by the caller.
    /// Requires the token to be off cooldown and meets specific requirements.
    /// @param tokenId The token ID to evolve.
    function triggerEvolution(uint256 tokenId) public whenNotPaused onlyOwnerOf(tokenId) {
        ArtData storage art = _tokenData[tokenId];
        uint48 currentTimestamp = uint48(block.timestamp);

        // Find an applicable evolution config
        // This simple example finds the first config matching the generation.
        // More complex logic could match based on genes, other attributes, etc.
        uint8 applicableConfigId = 0;
        EvolutionConfig memory config;
        bool found = false;

        // Iterate through configs (simple loop for demonstration, large configs could be an issue)
        // A better approach might be a mapping from generation to config ID, or using a specific gene value to select config.
        // Let's assume a mapping from generation to config ID for efficiency.
        // For simplicity in this code, we'll iterate config IDs 1 to _nextEvolutionConfigId-1
        for (uint8 i = 1; i < _nextEvolutionConfigId; i++) {
             EvolutionConfig memory currentConfig = _evolutionConfigs[i];
             if (currentConfig.requiredGeneration == art.generation) {
                  applicableConfigId = i;
                  config = currentConfig;
                  found = true;
                  break; // Found a config for this generation
             }
        }

        if (!found || applicableConfigId == 0) {
            revert EvolutionNotAvailable(); // No evolution config found for this generation
        }

        // Check cooldown (assuming a minimum time since last evolution, defined globally or per config)
        // Let's use a global minimum cooldown or derive from config. For simplicity, let's assume a cooldown is handled by requirements elsewhere, or add a simple `minTimeBetweenEvolutions` state variable.
        // Or, we can use the breeding cooldown mapping for simplicity, applying a cooldown after evolution too.
        if (_breedingCooldowns[tokenId] > currentTimestamp) { // Reusing breeding cooldown mapping for evolution
            revert EvolutionNotAvailable(); // Token is on cooldown
        }


        // Check resource requirement
        if (address(_resourceToken) == address(0) || _resourceToken.balanceOf(msg.sender) < config.requiredResourceAmount) {
             revert NotEnoughResourceToken();
        }

        // --- Apply Evolution Logic ---
        bytes32 oldGenes = art.genes;
        // Simple application of mutation mask (XORing or ANDing is common)
        // This example XORs the genes with the mutation mask
        bytes32 newGenes = oldGenes ^ config.geneMutationMask;

        // Pay resource token fee
        _resourceToken.transferFrom(msg.sender, address(this), config.requiredResourceAmount);

        // Update state
        art.genes = newGenes;
        art.generation = art.generation.add(1);
        art.lastEvolutionTime = currentTimestamp;
        _breedingCooldowns[tokenId] = currentTimestamp + _breedingConfig.cooldownSeconds; // Apply cooldown after evolution

        emit GenesChanged(tokenId, oldGenes, newGenes);
        emit EvolutionTriggered(tokenId, art.generation, applicableConfigId);
    }

    // --- Gene & Data Interaction View Functions ---

    /// @notice Gets the current on-chain genetic data for a token.
    /// @param tokenId The token ID.
    /// @return The genes (bytes32).
    function getGenes(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _tokenData[tokenId].genes;
    }

    /// @notice Gets the evolution generation of a token.
    /// @param tokenId The token ID.
    /// @return The generation number.
    function getGeneration(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _tokenData[tokenId].generation;
    }

    /// @notice Gets the timestamp of the last evolution for a token.
    /// @param tokenId The token ID.
    /// @return The timestamp (uint48).
    function getLastEvolutionTime(uint256 tokenId) public view returns (uint48) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _tokenData[tokenId].lastEvolutionTime;
    }

    /// @notice Gets the parent token IDs for a bred token.
    /// @param tokenId The token ID.
    /// @return parent1Id, parent2Id (uint256). Returns 0,0 for genesis tokens.
    function getParentTokens(uint256 tokenId) public view returns (uint256 parent1Id, uint256 parent2Id) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return (_tokenData[tokenId].parentId1, _tokenData[tokenId].parentId2);
    }

     /// @notice Gets all major attributes for a token.
    /// @param tokenId The token ID.
    /// @return ArtData struct containing genes, generation, times, parents.
    function getTokenAttributes(uint256 tokenId) public view returns (ArtData memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _tokenData[tokenId];
    }

    /// @notice Gets the requirements for the next possible evolution of a token.
    /// Finds the evolution config applicable to the token's current generation.
    /// @param tokenId The token ID.
    /// @return configId The evolution config ID (0 if none found).
    /// @return requiredResourceAmount The resource amount needed.
    /// @return cooldownRemaining The time in seconds until cooldown expires (0 if ready).
    /// @return description The description of the evolution type.
    function getEvolutionRequirements(uint256 tokenId) public view returns (uint8 configId, uint256 requiredResourceAmount, uint48 cooldownRemaining, string memory description) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        ArtData storage art = _tokenData[tokenId];
        uint48 currentTimestamp = uint48(block.timestamp);

        // Find an applicable evolution config (same logic as triggerEvolution)
        uint8 applicableConfigId = 0;
        EvolutionConfig memory config;
        bool found = false;

         for (uint8 i = 1; i < _nextEvolutionConfigId; i++) {
             EvolutionConfig memory currentConfig = _evolutionConfigs[i];
             if (currentConfig.requiredGeneration == art.generation) {
                  applicableConfigId = i;
                  config = currentConfig;
                  found = true;
                  break;
             }
        }

        uint48 cooldownEnd = _breedingCooldowns[tokenId]; // Reusing breeding cooldown mapping
        cooldownRemaining = (cooldownEnd > currentTimestamp) ? cooldownEnd - currentTimestamp : 0;

        if (found) {
            return (applicableConfigId, config.requiredResourceAmount, cooldownRemaining, config.description);
        } else {
            return (0, 0, cooldownRemaining, "");
        }
    }

    /// @notice A view function to simulate and return the potential resulting genes after the next evolution.
    /// Does not perform the actual evolution or state changes.
    /// @param tokenId The token ID.
    /// @return The potential new genes (bytes32), or current genes if no evolution is possible.
    function previewEvolution(uint256 tokenId) public view returns (bytes32) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        ArtData storage art = _tokenData[tokenId];

        // Find an applicable evolution config (same logic as triggerEvolution)
         for (uint8 i = 1; i < _nextEvolutionConfigId; i++) {
             EvolutionConfig memory currentConfig = _evolutionConfigs[i];
             if (currentConfig.requiredGeneration == art.generation) {
                  // Simulate applying the mutation mask
                  return art.genes ^ currentConfig.geneMutationMask;
             }
        }

        // If no evolution config found for this generation, return current genes
        return art.genes;
    }

    /// @notice Calculates a simple pseudo-rarity score based on gene characteristics.
    /// @param tokenId The token ID.
    /// @return A score representing perceived rarity (higher is rarer).
    /// @dev This is a simplified on-chain example. True rarity calculation is often complex and off-chain.
    function calculateRarityScore(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        bytes32 genes = _tokenData[tokenId].genes;
        uint256 score = 0;

        // Example Rarity Logic:
        // - Score based on number of set bits (more set bits = maybe rarer?)
        // - Score based on generation (higher generation = maybe rarer?)
        // - Score based on specific byte patterns (e.g., high value in a specific byte)

        uint256 geneValue = uint256(genes);

        // Count set bits (simple loop, okay for bytes32)
        for (uint256 i = 0; i < 256; i++) {
            if ((geneValue >> i) & 1 == 1) {
                score++;
            }
        }

        // Add generation multiplier (e.g., +100 per generation)
        score += _tokenData[tokenId].generation.mul(100);

        // Add bonus for specific patterns (example: if first byte is FF)
        if (bytes1(genes) == bytes1(uint8(255))) {
            score += 500;
        }
        // Add bonus for specific patterns (example: if last byte is AA)
         if (bytes1(uint8(genes[31])) == bytes1(uint8(170))) { // 0xAA
             score += 500;
         }

        // Add bonus for genesis (generation 0)
        if (_tokenData[tokenId].generation == 0) {
             score += 200;
        }


        return score;
    }


    // --- Configuration & Utility ---

    /// @notice Sets or updates a specific evolution configuration. Only callable by owner.
    /// @param configId The ID of the configuration to set/update (use 0 to add a new one).
    /// @param requiredGeneration The minimum generation for this config to apply.
    /// @param requiredResourceAmount The resource amount needed for evolution.
    /// @param geneMutationMask A mask used to mutate genes during this evolution type.
    /// @param description A description of this evolution type.
    /// @dev The meaning of the geneMutationMask is implementation-specific (e.g., XOR mask, bitwise AND mask).
    function setEvolutionConfig(uint8 configId, uint256 requiredGeneration, uint256 requiredResourceAmount, bytes32 geneMutationMask, string memory description) public onlyOwner {
        uint8 idToSet = configId;
        if (idToSet == 0) {
             idToSet = _nextEvolutionConfigId;
             _nextEvolutionConfigId++;
        } else if (idToSet >= _nextEvolutionConfigId) {
             revert InvalidEvolutionConfig(); // Cannot set config ID beyond the next available
        }

        _evolutionConfigs[idToSet] = EvolutionConfig({
            requiredGeneration: requiredGeneration,
            requiredResourceAmount: requiredResourceAmount,
            geneMutationMask: geneMutationMask,
            description: description
        });

        emit EvolutionConfigSet(idToSet, requiredGeneration, requiredResourceAmount);
    }

     /// @notice Gets details of a specific evolution config.
    /// @param configId The ID of the configuration.
    /// @return config The EvolutionConfig struct.
    function getEvolutionConfig(uint8 configId) public view returns (EvolutionConfig memory config) {
         if (configId == 0 || configId >= _nextEvolutionConfigId) {
             revert InvalidEvolutionConfig();
         }
         return _evolutionConfigs[configId];
    }

    /// @notice Sets the breeding cost in resource tokens and the cooldown duration. Only callable by owner.
    /// @param cost The amount of resource token required.
    /// @param cooldownSeconds The cooldown period in seconds after breeding for participating tokens.
    function setBreedingConfig(uint256 cost, uint48 cooldownSeconds) public onlyOwner {
        _breedingConfig = BreedingConfig({
            resourceCost: cost,
            cooldownSeconds: cooldownSeconds
        });
        emit BreedingConfigSet(cost, cooldownSeconds);
    }

    /// @notice Sets the address of the ERC20 token required for certain actions. Only callable by owner.
    /// @param resourceTokenAddress The address of the ERC20 token contract.
    function setResourceToken(address resourceTokenAddress) public onlyOwner {
        _resourceToken = IERC20(resourceTokenAddress);
        emit ResourceTokenSet(resourceTokenAddress);
    }

     /// @notice Allows the owner to withdraw accumulated resource tokens from the contract.
    /// @param to The address to send the tokens to.
    function withdrawResourceTokens(address to) public onlyOwner {
        uint256 balance = _resourceToken.balanceOf(address(this));
        if (balance > 0) {
            _resourceToken.transfer(to, balance);
        }
    }

    /// @notice Sets the base URI for token metadata. Only callable by owner.
    /// The tokenURI will be this base URI concatenated with the token ID.
    /// @param baseURI The base URI string.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Pauses the contract, preventing core actions like minting, breeding, and evolving. Only callable by owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only callable by owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Internal/Helper Functions ---

    /// @dev Modifier to ensure the caller is the owner of the specified token.
    modifier onlyOwnerOf(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        _;
    }

    // The following functions are internal and already part of ERC721/Ownable/Pausable
    // _safeMint, _transfer, _beforeTokenTransfer, _baseURI (used internally by tokenURI)
    // _isApprovedOrOwner, _authorizePredicates, _checkOwner, _requireNotPaused

    // Exposing total supply for convenience (often included in Enumerable extension, but can be added manually)
     function totalSupply() public view returns (uint256) {
        return _tokenCounter.current();
    }
}
```

---

**Explanation and Creative Aspects:**

1.  **On-Chain Genes (`bytes32 genes`):** This is the core dynamic element. `bytes32` offers 256 bits, ample space to encode numerous traits, characteristics, colors, patterns, or even potential actions. The interpretation of these bits is left to off-chain rendering engines, allowing for complex and unique visuals driven by verifiable on-chain data.
2.  **Evolution Mechanics:** The `triggerEvolution` function allows NFTs to change. This isn't a simple visual update; it *mutates* the core `genes` data on-chain based on predefined `EvolutionConfig`s and `geneMutationMask`s. This creates a lineage of genetic change. The `requiredGeneration` allows for multi-stage evolution paths.
3.  **Breeding Mechanics:** The `breedArt` function adds another layer of complexity. New NFTs are generated from two parents, inheriting and combining their genes. The example uses a simple XOR, but this could be sophisticated logic simulating genetic crossover, dominance, or recombination. The `parentId1`/`parentId2` fields track lineage, creating a verifiable family tree on-chain.
4.  **Resource Token Integration:** Requiring a specific `IERC20` token for breeding and evolution (`setResourceToken`, `_resourceToken.transferFrom`) adds an economic layer and utility to another token, creating interconnected ecosystems. The collected tokens can be managed by the contract owner (`withdrawResourceTokens`).
5.  **Dynamic Metadata (`tokenURI`):** The `tokenURI` points to an off-chain service. This service would read the NFT's *current* on-chain state (`genes`, `generation`, etc. via `getTokenAttributes`) and dynamically generate the metadata (JSON) and potentially the art image URI. This is crucial for dynamic NFTs.
6.  **Evolution Configurations (`_evolutionConfigs`):** Allows the contract owner (or potentially a DAO in a more advanced version) to define *how* evolution happens for different generations or types of art pieces, making the system extensible without redeploying the core logic.
7.  **Breeding Cooldowns:** Prevents spamming breeding/evolution, adding a strategic element for owners.
8.  **Rarity Calculation (On-chain Example):** While true rarity is often off-chain, including an on-chain `calculateRarityScore` provides a basic, transparent metric directly accessible from the blockchain, which can be used by marketplaces or other protocols. The example logic is simple but demonstrates the concept of deriving a score from gene data.
9.  **Preview Function:** `previewEvolution` allows users to see the *potential* outcome of an action before committing gas and resources, improving user experience.

This contract structure provides a robust framework for dynamic, evolving, and lineage-based digital art NFTs, distinct from static collections or simple generative mints. The on-chain data manipulation for genes and the evolution/breeding mechanics are the key creative and advanced concepts here, especially the idea of predefined, configurable genetic transformations (`geneMutationMask`).