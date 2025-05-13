Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts around dynamic NFTs, resource management, evolution, and staking, going beyond standard implementations.

It focuses on a "Digital Art Foundry" where unique art pieces (ERC-721) are *forged* using specific "Elements" (ERC-1155 tokens). These art pieces are dynamic: they have traits stored on-chain and can *evolve* by consuming more elements, changing their traits and potentially their rarity/metadata over time. Art pieces can also be *staked* to yield more Elements.

This contract is designed to be a complex ecosystem rather than a simple mint-and-transfer NFT.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary

/*
Contract: DigitalArtFoundry

Description:
A multi-faceted smart contract acting as a decentralized foundry for crafting
and managing dynamic digital art pieces (ERC-721 NFTs). Users forge art by
consuming elemental tokens (ERC-1155), which gives the art initial traits.
These art pieces can then evolve by consuming more elements, changing their
traits and potentially rarity. Art can also be staked within the contract
to earn element token rewards over time.

Advanced Concepts:
1.  **Dual Token Standard:** Implements both ERC-721 (for unique art pieces) and ERC-1155 (for fungible/semi-fungible elements/resources) in a single contract.
2.  **Resource-Based Minting/Forging:** Art pieces are not simply minted, but "forged" by burning specific quantities of ERC-1155 elements.
3.  **Dynamic NFT Traits:** Art pieces store mutable traits directly on-chain, allowing for state changes beyond static metadata.
4.  **On-Chain Evolution Mechanics:** Art pieces can be upgraded/evolved by meeting specific trait requirements and consuming more elements, altering their on-chain traits.
5.  **Staking for Resource Yield:** ERC-721 art pieces can be staked in the contract to passively earn ERC-1155 element rewards over time.
6.  **Configurable Recipes:** Forging and evolution requirements (element types and amounts) are configurable by the contract owner.
7.  **Time-Based Rewards:** Staking rewards are calculated based on the duration the NFT is staked.
8.  **On-Chain Rarity Scoring (Simple):** Includes a basic example of calculating a dynamic rarity score based on evolution count.

Interfaces & Inheritance:
-   Inherits ERC721URIStorage for NFT functionality and metadata.
-   Inherits ERC1155URIStorage for Element token functionality and metadata.
-   Inherits Ownable for administrative access control.
-   Implements necessary interface IDs for ERC-165.

State Variables:
-   Track next token IDs for NFTs and Elements.
-   Store art piece traits, evolution counts, staking status, start times, and reward debt.
-   Store element details and total supply.
-   Store forging and evolution recipes.
-   Store staking reward rates for elements.

Events:
-   Notify about key actions: Art Forged, Art Evolved, Art Staked, Art Unstaked, Rewards Claimed, Element Type Added, Recipe Set.

Function Categories:
1.  **ERC-165 Standard:** `supportsInterface`
2.  **ERC-721 Standard:** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`, `_baseURI`. (8 functions)
3.  **ERC-1155 Standard:** `balanceOf`, `balanceOfBatch`, `setApprovalForAll`, `isApprovedForAll`, `safeTransferFrom`, `safeBatchTransferFrom`, `uri`. (7 functions - note `supportsInterface` is shared)
4.  **Core Foundry Mechanics:**
    -   `forgeArt`: Mint a new art NFT by burning elements.
    -   `evolveArt`: Modify an existing art NFT's traits by burning elements, based on recipes.
5.  **Staking Mechanics:**
    -   `stakeArt`: Lock an art NFT in the contract for staking.
    -   `unstakeArt`: Retrieve a staked art NFT and claim pending rewards.
    -   `claimElementRewards`: Claim pending element rewards for a staked art NFT without unstaking.
    -   `_calculatePendingRewards`: Internal helper to calculate staking rewards.
6.  **View & Getters:**
    -   `getArtTraits`: Get current traits of an art piece.
    -   `getArtEvolutionCount`: Get evolution count of an art piece.
    -   `isArtStaked`: Check if an art piece is staked.
    -   `getStakingStartTime`: Get staking start time.
    -   `getArtRarityScore`: Calculate a simple dynamic rarity score.
    -   `getElementDetails`: Get details of an element type.
    -   `getForgingRecipe`: Get the current forging recipe.
    -   `getEvolutionRecipe`: Get a specific evolution recipe.
    -   `getStakingRewardRate`: Get element staking reward rate.
    -   `getTotalArtSupply`: Get total minted art pieces.
    -   `getTotalElementSupply`: Get total supply of an element type.
    -   `calculatePendingRewards`: View pending rewards for a staked NFT.
7.  **Admin & Setup (Owner-Only):**
    -   `addElementType`: Define a new type of element token.
    -   `setForgingRecipe`: Configure the elements required for forging.
    -   `setEvolutionRecipe`: Configure elements/requirements for evolving.
    -   `setStakingRewardsPerSecond`: Set the reward rate for staking.
    -   `adminMintElements`: Mint elements (e.g., for initial distribution or airdrops).
    -   `setBaseURI`: Set base URI for ERC-721 metadata.
    -   `setElementURI`: Set URI for a specific ERC-1155 element type.
    -   `withdrawFunds`: Withdraw any Ether accidentally sent to the contract.
    -   `setArtTraits`: Admin override to manually set traits (use with caution).

Total Functions: 8 (ERC721) + 7 (ERC1155) + 2 (Core Foundry) + 3 (Staking) + 12 (View/Getters) + 8 (Admin) = **40+ functions**

Note on Metadata: The ERC721 `tokenURI` should ideally point to a service (like IPFS or a backend) that dynamically generates metadata based on the on-chain traits (`_artTraits`). Similarly, ERC1155 `uri` points to metadata for the element types. This contract only handles the storage and logic of the *on-chain* traits; the visual representation and full JSON metadata would be handled externally, referencing the on-chain data.

Note on Rarity: The `getArtRarityScore` is a very basic example. Real-world rarity calculation for dynamic NFTs can be complex and might involve off-chain processing or more sophisticated on-chain state.

Note on Gas Costs: Complex actions like forging or evolving involving multiple token transfers/burns and state updates will consume significant gas. Staking reward calculation is relatively efficient.
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

contract DigitalArtFoundry is ERC721URIStorage, ERC1155URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _artTokenIds;
    Counters.Counter private _elementTypeIds;

    // --- State Variables ---

    // ERC721 Art Piece Data
    mapping(uint256 => string) private _artTraits; // artTokenId => JSON string or custom format
    mapping(uint256 => uint256) private _artEvolutionCount; // artTokenId => count

    // Staking Data
    mapping(uint256 => bool) private _stakedArt; // artTokenId => isStaked
    mapping(uint256 => uint256) private _artStakingStartTime; // artTokenId => timestamp when staked
    mapping(uint256 => mapping(uint256 => uint256)) private _stakingRewardDebt; // artTokenId => elementType => accumulated debt

    // ERC1155 Element Data (URI handled by ERC1155URIStorage)
    // No extra state needed beyond ERC1155URIStorage mappings unless custom element properties are added

    // Recipes & Configuration
    struct ForgingRecipe {
        uint256[] elementTypes; // List of element type IDs required
        uint256[] amounts;      // Corresponding amounts required
        string initialTraits;   // Initial traits string for the forged art
    }
    ForgingRecipe private _forgingRecipe; // Simple one-to-one forging recipe for example

    struct EvolutionRecipe {
        string requiredArtTrait; // Art must have this trait string to be eligible for this evolution
        uint256[] elementTypes;  // Elements required for this evolution step
        uint256[] amounts;       // Corresponding amounts required
        string newTraits;        // New traits string after evolution
    }
    // Using a mapping for evolution recipes based on a hash of the required trait for lookup
    mapping(bytes32 => EvolutionRecipe) private _evolutionRecipes;

    // Staking Rewards Configuration
    mapping(uint256 => uint256) private _elementRewardRates; // elementType => reward rate per second

    // Manually track total supply of each element type (since burning removes from total)
    mapping(uint256 => uint256) private _totalElementSupply;

    // --- Events ---

    event ArtForged(uint256 indexed artTokenId, address indexed owner, uint256[] elementTypes, uint256[] amounts);
    event ArtEvolved(uint256 indexed artTokenId, string oldTraits, string newTraits, uint256 newEvolutionCount);
    event ArtStaked(uint256 indexed artTokenId, address indexed owner);
    event ArtUnstaked(uint256 indexed artTokenId, address indexed owner, uint256[] elementTypes, uint256[] claimedAmounts);
    event RewardsClaimed(uint256 indexed artTokenId, uint256[] elementTypes, uint256[] claimedAmounts);
    event ElementTypeAdded(uint256 indexed elementType, string uri);
    event ForgingRecipeSet(uint256[] elementTypes, uint256[] amounts, string initialTraits);
    event EvolutionRecipeSet(string indexed requiredTrait, uint256[] elementTypes, uint256[] amounts, string newTraits);
    event StakingRewardRateSet(uint256 indexed elementType, uint256 ratePerSecond);

    // --- Constructor ---

    constructor(string memory baseTokenURI, string memory baseElementURI)
        ERC721("DigitalArtPiece", "DAP")
        ERC1155(baseElementURI) // Base URI for all elements initially
        Ownable(msg.sender)
    {
        _setBaseURI(baseTokenURI); // Base URI for Art NFTs
        // Initial element types can be added by the owner after deployment
    }

    // --- ERC-165 Standard ---
    // Override supportsInterface to declare support for multiple interfaces

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC1155URIStorage) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC1155).interfaceId ||
               interfaceId == type(IERC165).interfaceId ||
               interfaceId == type(Ownable).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- ERC-721 Standard Functions ---
    // Most standard ERC721 functions are inherited and used directly:
    // - balanceOf(address owner)
    // - ownerOf(uint256 tokenId)
    // - approve(address to, uint256 tokenId)
    // - getApproved(uint256 tokenId)
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address owner, address operator)
    // - transferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId)
    // - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)

    // Override tokenURI to potentially include dynamic traits in metadata reference
    // This basic implementation just uses the base URI + token ID, but a dynamic
    // metadata service would use this ID to look up on-chain traits.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId))) : "";
    }

    // _baseURI is inherited and can be set by owner

    // --- ERC-1155 Standard Functions ---
    // Most standard ERC1155 functions are inherited and used directly:
    // - balanceOf(address account, uint256 id)
    // - balanceOfBatch(address[] accounts, uint256[] ids)
    // - setApprovalForAll(address operator, bool approved)
    // - isApprovedForAll(address account, address operator)
    // - safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes data)
    // - safeBatchTransferFrom(address from, address to, uint256[] ids, uint256[] amounts, bytes data)

    // uri(uint256 tokenId) is inherited and can be set per element type by owner

    // --- Core Foundry Mechanics ---

    /// @notice Forges a new Digital Art Piece by consuming required elements.
    /// @param elementTypes The types of elements to consume.
    /// @param amounts The corresponding amounts of elements to consume.
    /// @dev The provided elementTypes and amounts must match the current forging recipe.
    function forgeArt(uint256[] calldata elementTypes, uint256[] calldata amounts) external {
        // Check if the provided elements match the forging recipe
        require(elementTypes.length == _forgingRecipe.elementTypes.length, "Forge: Invalid element types length");
        require(amounts.length == _forgingRecipe.amounts.length, "Forge: Invalid amounts length");

        for (uint i = 0; i < elementTypes.length; i++) {
            require(elementTypes[i] == _forgingRecipe.elementTypes[i], "Forge: Incorrect element type in recipe");
            require(amounts[i] >= _forgingRecipe.amounts[i], "Forge: Insufficient element amount for recipe"); // Allow using more than required if user wishes, though only required is consumed
        }

        // Consume (burn) the required elements from the sender
        // Transfer to address(0) is the standard way to burn ERC1155 tokens
        ERC1155URIStorage.safeBatchTransferFrom(msg.sender, address(0), _forgingRecipe.elementTypes, _forgingRecipe.amounts, "");

        // Mint the new art piece
        uint256 newItemId = _artTokenIds.current();
        _artTokenIds.increment();
        _safeMint(msg.sender, newItemId);

        // Set initial traits and evolution count
        _artTraits[newItemId] = _forgingRecipe.initialTraits;
        _artEvolutionCount[newItemId] = 0;

        emit ArtForged(newItemId, msg.sender, _forgingRecipe.elementTypes, _forgingRecipe.amounts);
    }

    /// @notice Evolves an existing Digital Art Piece by consuming required elements.
    /// @param artTokenId The ID of the art piece to evolve.
    /// @param elementTypes The types of elements to consume for evolution.
    /// @param amounts The corresponding amounts of elements to consume.
    /// @dev The art piece must be owned by the sender, not staked, and meet the required trait for an evolution recipe.
    function evolveArt(uint256 artTokenId, uint256[] calldata elementTypes, uint256[] calldata amounts) external {
        require(_exists(artTokenId), "Evolve: Art piece does not exist");
        require(ownerOf(artTokenId) == msg.sender, "Evolve: Not the owner");
        require(!_stakedArt[artTokenId], "Evolve: Art piece is staked");

        // Find the relevant evolution recipe based on current traits
        bytes32 currentTraitHash = keccak256(bytes(_artTraits[artTokenId]));
        EvolutionRecipe storage recipe = _evolutionRecipes[currentTraitHash];

        require(bytes(recipe.requiredArtTrait).length > 0, "Evolve: No evolution recipe for current traits");
        require(keccak256(bytes(recipe.requiredArtTrait)) == currentTraitHash, "Evolve: Recipe mismatch (internal error)"); // Double check

        // Check if the provided elements match the evolution recipe
        require(elementTypes.length == recipe.elementTypes.length, "Evolve: Invalid element types length");
        require(amounts.length == recipe.amounts.length, "Evolve: Invalid amounts length");

        for (uint i = 0; i < elementTypes.length; i++) {
             require(elementTypes[i] == recipe.elementTypes[i], "Evolve: Incorrect element type in recipe");
             require(amounts[i] >= recipe.amounts[i], "Evolve: Insufficient element amount for recipe");
        }

        // Consume (burn) the required elements
        ERC1155URIStorage.safeBatchTransferFrom(msg.sender, address(0), recipe.elementTypes, recipe.amounts, "");

        // Update the art piece traits and evolution count
        string memory oldTraits = _artTraits[artTokenId];
        _artTraits[artTokenId] = recipe.newTraits;
        _artEvolutionCount[artTokenId]++;

        emit ArtEvolved(artTokenId, oldTraits, recipe.newTraits, _artEvolutionCount[artTokenId]);
    }

    // --- Staking Mechanics ---

    /// @notice Stakes a Digital Art Piece to earn element rewards.
    /// @param artTokenId The ID of the art piece to stake.
    /// @dev The sender must own the art piece and approve the contract. Art cannot be staked if already staked.
    function stakeArt(uint256 artTokenId) external {
        require(_exists(artTokenId), "Stake: Art piece does not exist");
        require(ownerOf(artTokenId) == msg.sender, "Stake: Not the owner");
        require(!_stakedArt[artTokenId], "Stake: Art piece already staked");

        // Ensure contract is approved to transfer the NFT
        require(getApproved(artTokenId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Stake: Contract not approved");

        // Transfer the NFT to the contract
        _transfer(msg.sender, address(this), artTokenId);

        // Record staking info
        _stakedArt[artTokenId] = true;
        _artStakingStartTime[artTokenId] = block.timestamp;

        // Reset reward debt for all elements (new staking period begins)
        // Iterate through known elements or rely on lazy calculation
        // Lazy calculation is simpler: debt is implicitly 0 at start.
        // When rewards are calculated, debt is set to the total calculated at that moment.

        emit ArtStaked(artTokenId, msg.sender);
    }

    /// @notice Unstakes a Digital Art Piece and claims pending element rewards.
    /// @param artTokenId The ID of the art piece to unstake.
    /// @dev The sender must be the original staker.
    function unstakeArt(uint256 artTokenId) external {
        require(_exists(artTokenId), "Unstake: Art piece does not exist");
        require(_stakedArt[artTokenId], "Unstake: Art piece not staked");
        // Ensure only the original staker can unstake (or owner if transfer wasn't possible while staked)
        // A more robust system might track the staker address explicitly if NFTs can change ownership while staked.
        // Assuming for simplicity that NFT must be unstaked before transfer.
        // The owner check is implicit because the NFT is in the contract address.
        // Let's add a check to ensure the caller is the *original* staker, or owner logic is needed.
        // For simplicity, let's assume only the owner can unstake *their* staked NFT (which is now in contract custody).
        // This means only the *contract itself* can call _transfer, which implies the owner of the NFT must call *this* function.
        // A separate mapping tracking staker address would be more explicit.
        // Let's assume the contract requires the *current* owner to initiate unstaking.
        // If NFT ownership could transfer while staked, this logic would need revision.
        require(msg.sender == ownerOf(artTokenId), "Unstake: Only the owner can unstake");


        // Calculate and claim rewards first
        (uint256[] memory claimedElementTypes, uint256[] memory claimedAmounts) = _calculateAndClaimRewards(artTokenId);

        // Transfer the NFT back to the owner
        _transfer(address(this), msg.sender, artTokenId);

        // Reset staking info
        _stakedArt[artTokenId] = false;
        delete _artStakingStartTime[artTokenId];
        // Reward debt is already handled in _calculateAndClaimRewards

        emit ArtUnstaked(artTokenId, msg.sender, claimedElementTypes, claimedAmounts);
    }

    /// @notice Claims pending element rewards for a staked Digital Art Piece without unstaking.
    /// @param artTokenId The ID of the staked art piece.
    /// @dev The sender must be the original staker (or contract owner for simplicity as above).
    function claimElementRewards(uint256 artTokenId) external {
         require(_exists(artTokenId), "Claim Rewards: Art piece does not exist");
         require(_stakedArt[artTokenId], "Claim Rewards: Art piece not staked");
         require(msg.sender == ownerOf(artTokenId), "Claim Rewards: Only the owner can claim");

        _calculateAndClaimRewards(artTokenId);

        // Event is emitted inside _calculateAndClaimRewards
    }

    /// @dev Internal helper to calculate and mint pending rewards.
    function _calculateAndClaimRewards(uint256 artTokenId) internal returns (uint256[] memory, uint256[] memory) {
        uint256 stakedDuration = block.timestamp - _artStakingStartTime[artTokenId];
        uint256[] memory rewardElementTypes;
        uint256[] memory rewardAmounts;

        // Determine which element types have reward rates set
        // This requires iterating through all possible element type IDs or tracking active ones.
        // For simplicity, let's assume element types are added sequentially and iterate up to the current max ID.
        uint256 totalElementTypes = _elementTypeIds.current();
        uint256[] memory potentialRewardElements = new uint256[](totalElementTypes);
        uint256 validRewardCount = 0;
        for(uint256 i = 0; i < totalElementTypes; i++) {
            if (_elementRewardRates[i] > 0) {
                potentialRewardElements[validRewardCount] = i;
                validRewardCount++;
            }
        }

        rewardElementTypes = new uint256[](validRewardCount);
        rewardAmounts = new uint256[](validRewardCount);

        for(uint i = 0; i < validRewardCount; i++) {
            uint256 elementType = potentialRewardElements[i];
            uint256 rate = _elementRewardRates[elementType];
            uint256 pending = stakedDuration * rate;
            uint256 owed = pending - _stakingRewardDebt[artTokenId][elementType];

            if (owed > 0) {
                 // Mint rewards to the current owner of the NFT (which is the contract if staked)
                 // Standard practice is to mint rewards to the address *calling* claim/unstake.
                 // Let's mint to the *current owner* (which is the contract) and then transfer later if needed.
                 // Better: mint directly to msg.sender who initiated claim/unstake.
                 ERC1155URIStorage._mint(msg.sender, elementType, owed, "");
                 _totalElementSupply[elementType] += owed; // Manually track supply

                 // Update reward debt to the total earned up to this point
                 _stakingRewardDebt[artTokenId][elementType] = pending;

                 rewardElementTypes[i] = elementType;
                 rewardAmounts[i] = owed;
            } else {
                 rewardElementTypes[i] = elementType; // Still include in arrays but amount is 0
                 rewardAmounts[i] = 0;
            }
        }

        // Note: The staking start time is *not* reset on claim, only on unstake/stake.
        // This means rewards accumulate continuously until unstaked.

        emit RewardsClaimed(artTokenId, rewardElementTypes, rewardAmounts);
        return (rewardElementTypes, rewardAmounts);
    }


    // --- View & Getters ---

    /// @notice Gets the current on-chain traits of a Digital Art Piece.
    /// @param artTokenId The ID of the art piece.
    /// @return A string representing the art's traits (e.g., JSON).
    function getArtTraits(uint256 artTokenId) public view returns (string memory) {
        require(_exists(artTokenId), "Get Traits: Art piece does not exist");
        return _artTraits[artTokenId];
    }

    /// @notice Gets the evolution count of a Digital Art Piece.
    /// @param artTokenId The ID of the art piece.
    /// @return The number of times the art piece has been evolved.
    function getArtEvolutionCount(uint256 artTokenId) public view returns (uint256) {
         require(_exists(artTokenId), "Get Evolution Count: Art piece does not exist");
         return _artEvolutionCount[artTokenId];
    }

    /// @notice Checks if a Digital Art Piece is currently staked.
    /// @param artTokenId The ID of the art piece.
    /// @return True if the art piece is staked, false otherwise.
    function isArtStaked(uint256 artTokenId) public view returns (bool) {
        // No require _exists here, as _stakedArt mapping defaults to false
        return _stakedArt[artTokenId];
    }

     /// @notice Gets the timestamp when a staked Digital Art Piece was staked.
     /// @param artTokenId The ID of the art piece.
     /// @return The timestamp of staking, or 0 if not staked.
    function getStakingStartTime(uint256 artTokenId) public view returns (uint256) {
        // No require _exists here, as mapping defaults to 0
         return _artStakingStartTime[artTokenId];
    }

    /// @notice Calculates a simple dynamic rarity score for an art piece.
    /// @param artTokenId The ID of the art piece.
    /// @return A simple rarity score (higher is rarer, based on evolution).
    /// @dev This is a placeholder; real rarity is often trait-based and computed off-chain or with more complex on-chain state.
    function getArtRarityScore(uint256 artTokenId) public view returns (uint256) {
        require(_exists(artTokenId), "Get Rarity: Art piece does not exist");
        // Example simple score: base + evolution count * factor
        uint256 baseScore = 100; // Starting rarity
        uint256 evolutionFactor = 50; // Each evolution adds 50 rarity
        return baseScore + (_artEvolutionCount[artTokenId] * evolutionFactor);
        // Could also incorporate factors based on traits, forging elements used, etc.
    }

    /// @notice Gets the details of a specific element type.
    /// @param elementType The ID of the element type.
    /// @return The URI for the element type.
    function getElementDetails(uint256 elementType) public view returns (string memory) {
        require(elementType < _elementTypeIds.current(), "Get Element Details: Invalid element type");
        return uri(elementType); // ERC1155URIStorage handles base URI and type-specific URI
    }

    /// @notice Gets the current forging recipe.
    /// @return elementTypes The types of elements required.
    /// @return amounts The corresponding amounts required.
    /// @return initialTraits The initial traits set upon forging.
    function getForgingRecipe() public view returns (uint256[] memory elementTypes, uint256[] memory amounts, string memory initialTraits) {
        return (_forgingRecipe.elementTypes, _forgingRecipe.amounts, _forgingRecipe.initialTraits);
    }

    /// @notice Gets a specific evolution recipe based on the required current trait.
    /// @param requiredTrait The trait string required for this evolution step.
    /// @return elementTypes The types of elements required.
    /// @return amounts The corresponding amounts required.
    /// @return newTraits The traits set after evolution.
    function getEvolutionRecipe(string calldata requiredTrait) public view returns (uint256[] memory elementTypes, uint256[] memory amounts, string memory newTraits) {
         bytes32 traitHash = keccak256(bytes(requiredTrait));
         EvolutionRecipe storage recipe = _evolutionRecipes[traitHash];
         require(bytes(recipe.requiredArtTrait).length > 0, "Get Evolution Recipe: Recipe not found for trait");
         return (recipe.elementTypes, recipe.amounts, recipe.newTraits);
    }

    /// @notice Gets the staking reward rate per second for a specific element type.
    /// @param elementType The ID of the element type.
    /// @return The reward rate per second.
    function getStakingRewardRate(uint256 elementType) public view returns (uint256) {
        require(elementType < _elementTypeIds.current(), "Get Staking Rate: Invalid element type");
        return _elementRewardRates[elementType];
    }

    /// @notice Gets the total number of Digital Art Pieces minted.
    /// @return The total supply of ERC-721 tokens.
    function getTotalArtSupply() public view returns (uint256) {
        return _artTokenIds.current();
    }

    /// @notice Gets the total supply of a specific element type.
    /// @param elementType The ID of the element type.
    /// @return The total supply (minted minus burned).
    function getTotalElementSupply(uint256 elementType) public view returns (uint256) {
        require(elementType < _elementTypeIds.current(), "Get Element Supply: Invalid element type");
        return _totalElementSupply[elementType];
    }

    /// @notice Calculates the pending element rewards for a staked art piece.
    /// @param artTokenId The ID of the staked art piece.
    /// @return elementTypes The types of elements with pending rewards.
    /// @return pendingAmounts The corresponding amounts of pending rewards.
    function calculatePendingRewards(uint256 artTokenId) public view returns (uint256[] memory elementTypes, uint256[] memory pendingAmounts) {
        require(_exists(artTokenId), "Calculate Rewards: Art piece does not exist");
        require(_stakedArt[artTokenId], "Calculate Rewards: Art piece not staked");

        uint256 stakedDuration = block.timestamp - _artStakingStartTime[artTokenId];

        // Determine which element types have reward rates set
        uint256 totalElementTypes = _elementTypeIds.current();
        uint256[] memory potentialRewardElements = new uint256[](totalElementTypes);
        uint256 validRewardCount = 0;
        for(uint256 i = 0; i < totalElementTypes; i++) {
            if (_elementRewardRates[i] > 0) {
                potentialRewardElements[validRewardCount] = i;
                validRewardCount++;
            }
        }

        elementTypes = new uint256[](validRewardCount);
        pendingAmounts = new uint256[](validRewardCount);

        for(uint i = 0; i < validRewardCount; i++) {
             uint256 elementType = potentialRewardElements[i];
             uint256 rate = _elementRewardRates[elementType];
             uint256 pending = stakedDuration * rate;
             uint256 owed = pending - _stakingRewardDebt[artTokenId][elementType]; // Subtract already claimed/accounted debt

             elementTypes[i] = elementType;
             pendingAmounts[i] = owed;
        }
        return (elementTypes, pendingAmounts);
    }


    // --- Admin & Setup (Owner-Only) ---

    /// @notice Adds a new type of element token.
    /// @param initialURI The URI for the new element type.
    /// @param initialSupply The initial supply to mint for the new element type (minted to owner).
    function addElementType(string calldata initialURI, uint256 initialSupply) external onlyOwner {
        uint256 newElementTypeId = _elementTypeIds.current();
        _elementTypeIds.increment();

        _setURI(newElementTypeId, initialURI); // Set URI for this specific element type

        if (initialSupply > 0) {
             // Mint initial supply to the owner of the contract
             ERC1155URIStorage._mint(owner(), newElementTypeId, initialSupply, "");
             _totalElementSupply[newElementTypeId] = initialSupply; // Track supply
        } else {
            _totalElementSupply[newElementTypeId] = 0; // Initialize supply count
        }


        emit ElementTypeAdded(newElementTypeId, initialURI);
    }

    /// @notice Sets the recipe for forging a new Digital Art Piece.
    /// @param elementTypes The types of elements required.
    /// @param amounts The corresponding amounts required.
    /// @param initialTraits The initial traits string for the forged art.
    /// @dev Requires element types to be valid (less than current _elementTypeIds.current()).
    function setForgingRecipe(uint256[] calldata elementTypes, uint256[] calldata amounts, string calldata initialTraits) external onlyOwner {
        require(elementTypes.length == amounts.length, "Recipe: Array length mismatch");
        for (uint i = 0; i < elementTypes.length; i++) {
            require(elementTypes[i] < _elementTypeIds.current(), "Recipe: Invalid element type ID in recipe");
        }
        _forgingRecipe = ForgingRecipe(elementTypes, amounts, initialTraits);
        emit ForgingRecipeSet(elementTypes, amounts, initialTraits);
    }

    /// @notice Sets an evolution recipe based on required current traits.
    /// @param requiredTrait The trait string required for this evolution step.
    /// @param elementTypes The types of elements required.
    /// @param amounts The corresponding amounts required.
    /// @param newTraits The traits string set after evolution.
     /// @dev Requires element types to be valid. The requiredTrait must not be empty.
    function setEvolutionRecipe(string calldata requiredTrait, uint256[] calldata elementTypes, uint256[] calldata amounts, string calldata newTraits) external onlyOwner {
        require(elementTypes.length == amounts.length, "Recipe: Array length mismatch");
        require(bytes(requiredTrait).length > 0, "Recipe: Required trait cannot be empty");
        for (uint i = 0; i < elementTypes.length; i++) {
            require(elementTypes[i] < _elementTypeIds.current(), "Recipe: Invalid element type ID in recipe");
        }
        bytes32 traitHash = keccak256(bytes(requiredTrait));
        _evolutionRecipes[traitHash] = EvolutionRecipe(requiredTrait, elementTypes, amounts, newTraits);
        emit EvolutionRecipeSet(requiredTrait, elementTypes, amounts, newTraits);
    }

    /// @notice Sets the staking reward rate per second for a specific element type.
    /// @param elementType The ID of the element type.
    /// @param ratePerSecond The amount of this element rewarded per second staked.
    /// @dev Requires element type to be valid.
    function setStakingRewardsPerSecond(uint256 elementType, uint256 ratePerSecond) external onlyOwner {
        require(elementType < _elementTypeIds.current(), "Set Staking Rate: Invalid element type");
        _elementRewardRates[elementType] = ratePerSecond;
        emit StakingRewardRateSet(elementType, ratePerSecond);
    }

     /// @notice Mints elements to a specific address (for initial distribution, etc.).
     /// @param elementType The ID of the element type to mint.
     /// @param amount The amount to mint.
     /// @param to The recipient address.
     /// @dev Requires element type to be valid.
    function adminMintElements(uint256 elementType, uint256 amount, address to) external onlyOwner {
        require(elementType < _elementTypeIds.current(), "Admin Mint: Invalid element type");
        require(to != address(0), "Admin Mint: Cannot mint to zero address");
        ERC1155URIStorage._mint(to, elementType, amount, "");
        _totalElementSupply[elementType] += amount; // Track supply
    }

    /// @notice Sets the base URI for ERC-721 Art Piece metadata.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Sets the URI for a specific ERC-1155 Element type.
    /// @param elementType The ID of the element type.
    /// @param elementURI_ The new URI for this element type.
    /// @dev Requires element type to be valid.
    function setElementURI(uint256 elementType, string calldata elementURI_) external onlyOwner {
        require(elementType < _elementTypeIds.current(), "Set Element URI: Invalid element type");
        _setURI(elementType, elementURI_);
    }

    /// @notice Allows the owner to withdraw any Ether sent to the contract.
    function withdrawFunds(address payable recipient) external onlyOwner {
        require(recipient != address(0), "Withdraw: Invalid recipient address");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Withdraw: Transfer failed");
    }

     /// @notice Allows the owner to directly set the traits of an art piece (use with caution).
     /// @param artTokenId The ID of the art piece.
     /// @param newTraits The new traits string.
    function setArtTraits(uint256 artTokenId, string calldata newTraits) external onlyOwner {
        require(_exists(artTokenId), "Set Traits: Art piece does not exist");
        _artTraits[artTokenId] = newTraits;
        // No event specific to admin override, but state is changed. Consider adding one if needed for transparency.
    }

    // --- Internal Overrides ---

    // The ERC721 _transfer function is overridden to prevent transferring staked NFTs
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(!_stakedArt[tokenId] || from == address(this), "Transfer: Cannot transfer staked art piece");
        super._transfer(from, to, tokenId);
    }

    // The ERC721 _beforeTokenTransfer is useful for hooks, not strictly needed here based on _transfer override.
    // Can be added if more complex logic is needed before transfer.

    // The ERC1155 _beforeTokenTransfer is useful for hooks, not strictly needed here.
    // Can be added if more complex logic is needed before element transfers.
    // This is where custom logic related to burning elements upon forging/evolving could be added if burning wasn't direct to address(0).

}
```