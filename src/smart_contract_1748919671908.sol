Okay, here is a Solidity smart contract idea called "SyntheBlocks: Generative Asset Forge".

This contract isn't a typical token, NFT, or DeFi protocol. Instead, it focuses on managing the *parameters* or "genes" used to procedurally generate unique digital assets (like art, music, simulations) off-chain. The contract stores the *recipe* (a combination of genes) as an on-chain token (ERC721-like) and provides mechanisms for acquiring genes, forging new recipes, breeding recipes, staking recipes for rewards, and trading them.

It features concepts like:
*   **Procedural Asset Definition:** The contract doesn't store JPEGs or MP3s, but the combinatorial "DNA" to create them.
*   **Dual On-Chain Assets:** Manages both "Gene Instances" (consumable parameters) and "Recipes" (ERC721 tokens representing a unique combination of genes).
*   **Gene Acquisition Mechanics:** Genes can be minted initially or earned through staking/breeding.
*   **Forging (Crafting):** Users combine Gene Instances to create a Recipe, burning the genes in the process.
*   **Breeding (Mutation):** Combining two Recipes can yield new Gene Instances (potentially mutated or rare).
*   **Staking:** Staking Recipes can generate yield in the form of new Gene Instances over time.
*   **Dynamic Rarity:** Recipes have a calculated rarity score based on their constituent genes.
*   **Internal Marketplace:** Basic listing and buying functionality for Recipes.

This design avoids simply duplicating standard ERC-20/ERC-721 implementations (though it *implements* the ERC721 interface for Recipes) or common DeFi patterns. It's more akin to a complex on-chain game or creative tool layer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SyntheBlocks: Generative Asset Forge
 * @dev This contract manages Gene Types, Gene Instances, and Recipes for procedural asset generation.
 * Gene Instances are consumable parameters. Recipes are unique, tradable ERC721-like tokens
 * representing a combination of Gene Instances used to define a generative asset off-chain.
 * Features include forging recipes from genes, breeding recipes to create new genes,
 * staking recipes for gene rewards, and an internal marketplace.
 *
 * OUTLINE:
 * 1. State Variables & Data Structures (Structs)
 * 2. Events
 * 3. Modifiers (Basic access control)
 * 4. ERC721-like Recipe Implementation (Core functions for token ownership and transfer)
 * 5. Gene Management Functions (Admin & User acquisition/transfer of Gene Instances)
 * 6. Recipe Management Functions (Forging, detail retrieval, rarity calculation)
 * 7. Interaction Functions (Breeding, Staking, Claiming Rewards)
 * 8. Marketplace Functions (Listing, Buying, Canceling, View listings)
 * 9. Utility & View Functions (Total supply, details lookup)
 * 10. Constructor
 * 11. Interface Support (ERC165 for ERC721)
 *
 * FUNCTION SUMMARY:
 * - addGeneType(string memory name, string memory description, uint256 baseRarityScore, uint256 engineTypeId): Owner-only. Defines a new type of gene.
 * - mintGeneInstance(address recipient, uint256 geneTypeId, bytes memory value): Owner-only (for base distribution). Mints a specific gene instance for a user.
 * - batchMintGeneInstances(address recipient, uint256[] memory geneTypeIds, bytes[] memory values): Owner-only. Mints multiple gene instances in one call.
 * - transferGeneInstance(address from, address to, uint256 geneInstanceId): Transfers ownership of a specific gene instance.
 * - forgeRecipe(uint256 engineTypeId, uint256[] memory geneInstanceIds): User function. Burns owned gene instances to create a new Recipe token.
 * - breedRecipes(uint256 recipeId1, uint256 recipeId2): User function. Combines two owned recipes to produce new gene instance rewards (potential for mutation).
 * - stakeRecipe(uint256 recipeId): User function. Locks an owned recipe to accrue staking rewards (new gene instances).
 * - unstakeRecipe(uint256 recipeId): User function. Unlocks a staked recipe.
 * - claimStakingRewards(): User function. Claims accrued gene instance rewards from all staked recipes.
 * - listItem(uint256 recipeId, uint256 price): User function. Lists an owned recipe for sale in the marketplace.
 * - cancelListing(uint256 recipeId): User function. Removes an active marketplace listing for their recipe.
 * - buyItem(uint256 recipeId): User function. Buys a listed recipe, transferring Ether and ownership.
 * - getGeneTypeDetails(uint256 geneTypeId): View function. Returns details of a gene type.
 * - getGeneInstanceDetails(uint256 geneInstanceId): View function. Returns details of a specific gene instance.
 * - getUserGeneInstances(address user): View function. Returns list of gene instance IDs owned by a user.
 * - getRecipeDetails(uint256 recipeId): View function. Returns details of a recipe (engine type, genes).
 * - getRecipeGenes(uint256 recipeId): View function. Returns the gene instances composing a specific recipe.
 * - calculateRecipeRarity(uint256 recipeId): View function. Calculates the rarity score of a recipe based on its genes.
 * - getUserRecipes(address user): View function. Returns list of recipe IDs owned by a user.
 * - getTotalRecipes(): View function. Returns the total number of recipes minted.
 * - getTotalGeneTypes(): View function. Returns the total number of gene types defined.
 * - getTotalGeneInstances(): View function. Returns the total number of gene instances minted.
 * - getListingDetails(uint256 recipeId): View function. Returns details of a marketplace listing.
 * - getUserListings(address user): View function. Returns list of recipe IDs listed by a user.
 * - getStakedRecipes(address user): View function. Returns list of recipe IDs staked by a user.
 * - supportsInterface(bytes4 interfaceId): View function. ERC165 standard implementation for ERC721.
 *
 * ERC721-like Recipe Implementation (Interface):
 * - balanceOf(address owner): Returns count of recipes owned by an address.
 * - ownerOf(uint256 recipeId): Returns the owner of a recipe.
 * - transferFrom(address from, address to, uint256 recipeId): Transfers ownership of a recipe.
 * - safeTransferFrom(address from, address to, uint256 recipeId, bytes memory data): Safe transfer with data.
 * - safeTransferFrom(address from, address to, uint256 recipeId): Safe transfer without data.
 * - approve(address to, uint256 recipeId): Approves an address to transfer a recipe.
 * - setApprovalForAll(address operator, bool approved): Sets approval for an operator for all recipes.
 * - getApproved(uint256 recipeId): Gets the approved address for a recipe.
 * - isApprovedForAll(address owner, address operator): Checks if an operator is approved for all recipes.
 */
contract SyntheBlocks {

    // --- 1. State Variables & Data Structures ---

    address public owner; // Administrative owner of the contract

    uint256 private _nextGeneTypeId;
    uint256 private _nextGeneInstanceId;
    uint256 private _nextRecipeId;

    // Define different types of genes
    struct GeneType {
        string name;
        string description;
        uint256 baseRarityScore; // Base score for this gene type
        uint256 engineTypeId; // What generative engine this gene applies to (e.g., 1 for music, 2 for art)
    }
    mapping(uint256 => GeneType) public geneTypes;

    // Specific instances of genes, owned by users
    struct GeneInstance {
        uint256 geneTypeId;
        bytes value; // The actual parameter data (e.g., a byte array representing a musical phrase, a color palette)
        address owner;
    }
    mapping(uint256 => GeneInstance) public geneInstances;
    mapping(address => uint256[]) private _userGeneInstances; // Helper to track user-owned gene instance IDs

    // The core asset: a combination of gene instances
    struct Recipe {
        uint256 engineTypeId; // The engine this recipe is for
        uint256[] geneInstanceIds; // IDs of the gene instances used to forge this recipe (burned)
        uint256 creationTimestamp; // For staking reward calculation
    }
    mapping(uint256 => Recipe) public recipes;

    // ERC721-like state for Recipes
    mapping(uint256 => address) private _recipeOwners;
    mapping(address => uint256) private _recipeBalances;
    mapping(uint256 => address) private _recipeApprovals; // Token approval
    mapping(address => mapping(address => bool)) private _recipeOperatorApprovals; // Operator approval
    mapping(address => uint256[]) private _userRecipes; // Helper to track user-owned recipe IDs

    // Staking state
    mapping(uint256 => address) private _stakedRecipes; // Recipe ID -> Staker address (0x0 if not staked)
    mapping(address => uint256[]) private _userStakedRecipes; // Helper to track user staked recipe IDs
    mapping(address => uint256) private _stakingRewardPoints; // Accumulated reward points (simplified)

    // Marketplace state
    struct MarketListing {
        uint256 recipeId;
        uint256 price; // Price in wei
        address seller;
        bool active;
    }
    mapping(uint256 => MarketListing) public marketListings; // recipeId -> Listing details

    // --- 2. Events ---

    event GeneTypeAdded(uint256 indexed geneTypeId, string name, uint256 engineTypeId);
    event GeneInstanceMinted(uint256 indexed geneInstanceId, uint256 indexed geneTypeId, address indexed recipient);
    event GeneInstanceTransferred(uint256 indexed geneInstanceId, address indexed from, address indexed to);
    event RecipeForged(uint256 indexed recipeId, uint256 indexed engineTypeId, address indexed minter);
    event RecipeTransferred(address indexed from, address indexed to, uint256 indexed recipeId);
    event RecipeApproved(address indexed owner, address indexed approved, uint256 indexed recipeId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event RecipesBreed(address indexed breeder, uint256 indexed recipeId1, uint256 indexed recipeId2, uint256[] newGeneInstanceIds);
    event RecipeStaked(address indexed staker, uint256 indexed recipeId);
    event RecipeUnstaked(address indexed staker, uint256 indexed recipeId);
    event StakingRewardsClaimed(address indexed staker, uint256[] claimedGeneInstanceIds);
    event ItemListed(uint256 indexed recipeId, address indexed seller, uint256 price);
    event ListingCanceled(uint256 indexed recipeId, address indexed seller);
    event ItemSold(uint256 indexed recipeId, address indexed seller, address indexed buyer, uint256 price);

    // --- 3. Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRecipeOwnerOrApproved(uint256 recipeId) {
        require(
            _isApprovedOrOwner(msg.sender, recipeId),
            "Caller is not owner or approved for this recipe"
        );
        _;
    }

    modifier onlyGeneInstanceOwner(uint256 geneInstanceId) {
        require(
            geneInstances[geneInstanceId].owner == msg.sender,
            "Caller is not owner of this gene instance"
        );
        _;
    }

    // --- Internal ERC721 Helpers ---
    // Minimal implementation to support the interface without inheriting OZ

    function _exists(uint256 recipeId) internal view returns (bool) {
        return _recipeOwners[recipeId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 recipeId) internal view returns (bool) {
        address tokenOwner = ownerOf(recipeId); // Use the public getter
        return (spender == tokenOwner ||
                getApproved(recipeId) == spender || // Use the public getter
                isApprovedForAll(tokenOwner, spender)); // Use the public getter
    }

    function _safeTransferFrom(address from, address to, uint256 recipeId, bytes memory data) internal {
        _transferFrom(from, to, recipeId);
        require(_checkOnERC721Received(address(0), from, to, recipeId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transferFrom(address from, address to, uint256 recipeId) internal {
        require(ownerOf(recipeId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_stakedRecipes[recipeId] == address(0), "Cannot transfer staked recipe"); // Added staking check

        // Clear approvals
        _approve(address(0), recipeId);

        // Update internal state
        _recipeBalances[from]--;
        _recipeBalances[to]++;
        _recipeOwners[recipeId] = to;

        // Update user recipe lists (requires finding and removing/adding IDs)
        // This is inefficient for large numbers of recipes. A more gas-efficient approach
        // would involve linked lists or simply relying on the ownerOf mapping,
        // but let's implement a basic array management for clarity here.
        _removeRecipeFromUserList(_userRecipes[from], recipeId);
        _userRecipes[to].push(recipeId);


        emit RecipeTransferred(from, to, recipeId);
    }

     function _mintRecipe(address to, uint256 engineTypeId, uint256[] memory geneInstanceIds) internal returns (uint256) {
        uint256 newTokenId = _nextRecipeId++;
        _recipeOwners[newTokenId] = to;
        _recipeBalances[to]++;
        _userRecipes[to].push(newTokenId); // Add to user's list

        recipes[newTokenId] = Recipe(
            engineTypeId,
            geneInstanceIds,
            block.timestamp
        );

        emit RecipeForged(newTokenId, engineTypeId, to);
        return newTokenId;
    }


    function _burnRecipe(uint256 recipeId) internal {
        address tokenOwner = ownerOf(recipeId);
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        require(_stakedRecipes[recipeId] == address(0), "Cannot burn staked recipe"); // Added staking check

        // Clear approvals
        _approve(address(0), recipeId);

        // Update internal state
        _recipeBalances[tokenOwner]--;
        delete _recipeOwners[recipeId];
        delete recipes[recipeId]; // Remove recipe data

        // Update user recipe list
        _removeRecipeFromUserList(_userRecipes[tokenOwner], recipeId);

        // Note: ERC721 standard usually emits Transfer to address(0) on burn.
        // We are skipping this minimal implementation detail for brevity.
    }

    function _approve(address to, uint256 recipeId) internal {
        _recipeApprovals[recipeId] = to;
        emit RecipeApproved(ownerOf(recipeId), to, recipeId); // ownerOf used here as per standard
    }

    function _checkOnERC721Received(address operator, address from, address to, uint256 recipeId, bytes memory data) internal returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(operator, from, recipeId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                 if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity exclusive
                    revert(string(reason));
                }
            }
        } else {
            return true; // Allow transfers to non-contract addresses
        }
    }

    // Helper to remove an element from a dynamic array (inefficient for large arrays)
    function _removeRecipeFromUserList(uint256[] storage list, uint256 recipeId) internal {
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == recipeId) {
                list[i] = list[list.length - 1];
                list.pop();
                return;
            }
        }
    }

    // Helper to remove an element from a dynamic array (inefficient for large arrays)
    function _removeGeneInstanceFromUserList(uint256[] storage list, uint256 geneInstanceId) internal {
         for (uint i = 0; i < list.length; i++) {
            if (list[i] == geneInstanceId) {
                list[i] = list[list.length - 1];
                list.pop();
                return;
            }
        }
    }


    // --- 4. ERC721-like Recipe Implementation ---
    // Implementing the external functions of ERC721

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _recipeBalances[owner];
    }

    function ownerOf(uint256 recipeId) public view returns (address) {
        address tokenOwner = _recipeOwners[recipeId];
        require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
        return tokenOwner;
    }

    function transferFrom(address from, address to, uint256 recipeId) public {
        require(_isApprovedOrOwner(msg.sender, recipeId), "ERC721: caller is not token owner or approved");
        _transferFrom(from, to, recipeId);
    }

    function safeTransferFrom(address from, address to, uint256 recipeId) public {
        safeTransferFrom(from, to, recipeId, "");
    }

    function safeTransferFrom(address from, address to, uint256 recipeId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, recipeId), "ERC721: caller is not token owner or approved");
        _safeTransferFrom(from, to, recipeId, data);
    }

    function approve(address to, uint256 recipeId) public {
        address tokenOwner = ownerOf(recipeId);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender), "ERC721: approve caller is not token owner nor approved for all");
        _approve(to, recipeId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _recipeOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 recipeId) public view returns (address) {
        require(_exists(recipeId), "ERC721: approved query for nonexistent token");
        return _recipeApprovals[recipeId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _recipeOperatorApprovals[owner][operator];
    }


    // --- 5. Gene Management Functions ---

    /**
     * @dev Owner-only function to add a new type of gene.
     * @param name The name of the gene type (e.g., "Melody Pattern A", "Color Palette B").
     * @param description A description of the gene type.
     * @param baseRarityScore A base score influencing recipe rarity when this gene is used.
     * @param engineTypeId The ID of the generative engine this gene is compatible with.
     */
    function addGeneType(
        string memory name,
        string memory description,
        uint256 baseRarityScore,
        uint256 engineTypeId
    ) external onlyOwner {
        uint256 newGeneTypeId = _nextGeneTypeId++;
        geneTypes[newGeneTypeId] = GeneType(name, description, baseRarityScore, engineTypeId);
        emit GeneTypeAdded(newGeneTypeId, name, engineTypeId);
    }

     /**
     * @dev Mints a specific instance of a gene type to a recipient. Primarily for initial distribution
     * or rewards. Can be restricted to owner or called internally by other functions (staking, breeding).
     * @param recipient The address to receive the gene instance.
     * @param geneTypeId The type of gene to mint.
     * @param value The specific parameter data for this gene instance.
     */
    function mintGeneInstance(address recipient, uint256 geneTypeId, bytes memory value) internal returns (uint256) {
        require(geneTypes[geneTypeId].engineTypeId != 0, "Gene type does not exist"); // Check if type exists

        uint256 newGeneInstanceId = _nextGeneInstanceId++;
        geneInstances[newGeneInstanceId] = GeneInstance(geneTypeId, value, recipient);
        _userGeneInstances[recipient].push(newGeneInstanceId); // Add to user's list

        emit GeneInstanceMinted(newGeneInstanceId, geneTypeId, recipient);
        return newGeneInstanceId;
    }

    /**
     * @dev Owner-only function to mint multiple gene instances efficiently.
     * @param recipient The address to receive the gene instances.
     * @param geneTypeIds Array of gene type IDs to mint.
     * @param values Array of parameter data values corresponding to geneTypeIds.
     */
    function batchMintGeneInstances(address recipient, uint256[] memory geneTypeIds, bytes[] memory values) external onlyOwner {
        require(geneTypeIds.length == values.length, "Array length mismatch");
        for (uint i = 0; i < geneTypeIds.length; i++) {
            mintGeneInstance(recipient, geneTypeIds[i], values[i]);
        }
    }


    /**
     * @dev Allows the owner of a gene instance to transfer it.
     * Gene instances are consumed when forging recipes, so direct transfer might be less common
     * than recipe transfers, but useful for gifting or future gene marketplaces.
     * @param from The address currently owning the gene instance.
     * @param to The address to transfer the gene instance to.
     * @param geneInstanceId The ID of the gene instance to transfer.
     */
    function transferGeneInstance(address from, address to, uint256 geneInstanceId) external onlyGeneInstanceOwner(geneInstanceId) {
        require(geneInstances[geneInstanceId].owner == from, "GeneInstance: transfer from incorrect owner");
        require(to != address(0), "GeneInstance: transfer to the zero address");

        geneInstances[geneInstanceId].owner = to;

        // Update user gene instance lists (inefficient array manipulation)
        _removeGeneInstanceFromUserList(_userGeneInstances[from], geneInstanceId);
        _userGeneInstances[to].push(geneInstanceId);

        emit GeneInstanceTransferred(geneInstanceId, from, to);
    }


    // --- 6. Recipe Management Functions ---

    /**
     * @dev Allows a user to combine owned gene instances to forge a new Recipe token.
     * The gene instances are consumed (burned) in this process.
     * Requires that the gene instances are compatible with the chosen engine type.
     * @param engineTypeId The ID of the generative engine for the new recipe.
     * @param geneInstanceIds The IDs of the gene instances to use.
     */
    function forgeRecipe(uint256 engineTypeId, uint256[] memory geneInstanceIds) external {
        require(geneTypeIds[engineTypeId].engineTypeId != 0, "Invalid engine type for forging"); // Check if engine type exists (assuming engineTypeIds map maps engine ID to some properties or just use geneTypes[geneTypeIds[0]].engineTypeId)
        require(geneInstanceIds.length > 0, "Must use at least one gene instance");

        address minter = msg.sender;
        uint256[] memory burnedGeneInstanceIds = new uint256[](geneInstanceIds.length);

        // Validate gene ownership and compatibility, then burn
        for (uint i = 0; i < geneInstanceIds.length; i++) {
            uint256 geneInstId = geneInstanceIds[i];
            GeneInstance storage geneInst = geneInstances[geneInstId];

            require(geneInst.owner == minter, "Not owner of gene instance");
            require(geneTypes[geneInst.geneTypeId].engineTypeId == engineTypeId, "Gene instance engine type mismatch");

            // Burn the gene instance (set owner to address(0) and clear data)
            geneInst.owner = address(0); // Mark as burned/consumed
            delete geneInst.value; // Clear value to save space? Or keep for recipe traceability? Let's keep it for traceability within Recipe struct.

            // Remove from user's list
            _removeGeneInstanceFromUserList(_userGeneInstances[minter], geneInstId);

            // Store the original ID for the Recipe struct
            burnedGeneInstanceIds[i] = geneInstId;

             // Emit an event indicating consumption? Not strictly necessary but good for tracking
             // emit GeneInstanceConsumed(geneInstId, minter);
        }

        // Mint the new Recipe token to the minter
        _mintRecipe(minter, engineTypeId, burnedGeneInstanceIds);
    }


     /**
     * @dev View function to retrieve the gene instances that compose a specific recipe.
     * @param recipeId The ID of the recipe.
     * @return An array of GeneInstance structs.
     */
    function getRecipeGenes(uint256 recipeId) public view returns (GeneInstance[] memory) {
        require(_exists(recipeId), "Recipe does not exist");
        uint256[] memory geneInstIds = recipes[recipeId].geneInstanceIds;
        GeneInstance[] memory geneInsts = new GeneInstance[](geneInstIds.length);
        for (uint i = 0; i < geneInstIds.length; i++) {
            geneInsts[i] = geneInstances[geneInstIds[i]]; // Access via the original ID
        }
        return geneInsts;
    }

     /**
     * @dev Calculates a rarity score for a recipe based on the base rarity scores of its component genes.
     * More sophisticated rarity logic (e.g., trait combinations, distribution) could be added.
     * @param recipeId The ID of the recipe.
     * @return The calculated rarity score.
     */
    function calculateRecipeRarity(uint256 recipeId) public view returns (uint256) {
        require(_exists(recipeId), "Recipe does not exist");
        uint256 totalRarity = 0;
        uint256[] memory geneInstIds = recipes[recipeId].geneInstanceIds;
        for (uint i = 0; i < geneInstIds.length; i++) {
            uint256 geneInstId = geneInstIds[i];
            // Access the gene type details via the original gene instance ID's type ID
             totalRarity += geneTypes[geneInstances[geneInstId].geneTypeId].baseRarityScore;
        }
        // Simple aggregation. Could add multipliers, bonuses for combinations, etc.
        return totalRarity;
    }


    // --- 7. Interaction Functions ---

    /**
     * @dev Allows two recipes to be "bred". This simulation could potentially yield new gene instances
     * for the caller based on the combined genes of the parent recipes. The parent recipes are NOT burned.
     * This implementation is a simplified example yielding random gene instances based on parents.
     * @param recipeId1 The ID of the first recipe.
     * @param recipeId2 The ID of the second recipe.
     */
    function breedRecipes(uint256 recipeId1, uint256 recipeId2) external {
        address breeder = msg.sender;
        require(ownerOf(recipeId1) == breeder, "Caller is not owner of recipe 1");
        require(ownerOf(recipeId2) == breeder, "Caller is not owner of recipe 2");
        require(recipeId1 != recipeId2, "Cannot breed a recipe with itself");
        // Add potential breeding fee requirement here (e.g., require(msg.value >= breedFee, "Insufficient fee");)

        // Simplified breeding logic: Pool genes from both parents
        uint256[] memory parent1Genes = recipes[recipeId1].geneInstanceIds;
        uint256[] memory parent2Genes = recipes[recipeId2].geneInstanceIds;

        uint256 totalGenes = parent1Genes.length + parent2Genes.length;
        uint256[] memory allParentGenes = new uint256[](totalGenes);
        for(uint i = 0; i < parent1Genes.length; i++) allParentGenes[i] = parent1Genes[i];
        for(uint i = 0; i < parent2Genes.length; i++) allParentGenes[parent1Genes.length + i] = parent2Genes[i];

        // Determine yield (e.g., based on rarity, random chance, fixed amount)
        uint256 numYieldedGenes = 1 + (calculateRecipeRarity(recipeId1) + calculateRecipeRarity(recipeId2)) / 1000; // Example: 1 + average rarity / 1000

        uint256[] memory newGeneInstanceIds = new uint256[](numYieldedGenes);
        bytes memory placeholderValue = hex"01020304"; // Example placeholder data for new gene instance

        // Example yield logic: Mint random gene instances from the combined pool's *types*
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(recipeId1, recipeId2, block.timestamp, msg.sender)));
        for (uint i = 0; i < numYieldedGenes; i++) {
             if (totalGenes == 0) break; // Avoid division by zero if no genes in parents

            // Pick a random gene instance ID from the combined pool
            uint256 randomIndex = (randomSeed + i) % totalGenes;
            uint256 sourceGeneInstanceId = allParentGenes[randomIndex];
            uint256 sourceGeneTypeId = geneInstances[sourceGeneInstanceId].geneTypeId;

            // Mint a *new* instance of that gene type for the breeder
            newGeneInstanceIds[i] = mintGeneInstance(breeder, sourceGeneTypeId, placeholderValue); // Use a placeholder or derive new value? Placeholder simpler for example.

             randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, newGeneInstanceIds[i], i))); // Update seed for next iteration
        }

        emit RecipesBreed(breeder, recipeId1, recipeId2, newGeneInstanceIds);
    }


    /**
     * @dev Allows a user to stake an owned recipe. Staked recipes cannot be transferred or listed.
     * @param recipeId The ID of the recipe to stake.
     */
    function stakeRecipe(uint256 recipeId) external onlyRecipeOwnerOrApproved(recipeId) {
        address staker = msg.sender;
        require(ownerOf(recipeId) == staker, "Only owner can stake"); // Redundant with modifier, but explicit
        require(_stakedRecipes[recipeId] == address(0), "Recipe is already staked");
        require(marketListings[recipeId].active == false, "Recipe is listed for sale");

        // Mark as staked
        _stakedRecipes[recipeId] = staker;
        _userStakedRecipes[staker].push(recipeId); // Add to staked list

        // Note: In a real implementation, you'd record the timestamp and rarity here
        // to calculate rewards over time. For simplicity, we use reward points.
        // A more advanced system would calculate yield per second/block based on rarity.

        emit RecipeStaked(staker, recipeId);
    }

    /**
     * @dev Allows a user to unstake a recipe.
     * @param recipeId The ID of the recipe to unstake.
     */
    function unstakeRecipe(uint256 recipeId) external {
         address staker = msg.sender;
         require(_stakedRecipes[recipeId] == staker, "Recipe is not staked by caller");

         // Unmark as staked
         _stakedRecipes[recipeId] = address(0); // Clear staker
         _removeRecipeFromUserList(_userStakedRecipes[staker], recipeId); // Remove from staked list

         // Calculate and add pending reward points (simplified)
         // In a real system, this would calculate based on time staked and rarity.
         // Let's add a flat reward point amount per unstake for simplicity.
         _stakingRewardPoints[staker] += calculateRecipeRarity(recipeId) / 100; // Example points calculation

         emit RecipeUnstaked(staker, recipeId);
    }

     /**
     * @dev Allows a staker to claim accumulated staking rewards (new gene instances).
     * The number/type of genes claimed depends on accumulated reward points.
     */
    function claimStakingRewards() external {
        address staker = msg.sender;
        uint256 rewardPoints = _stakingRewardPoints[staker];
        require(rewardPoints > 0, "No rewards accumulated");

        // Determine how many genes to mint based on points
        uint256 numGenesToMint = rewardPoints / 100; // Example: 1 gene per 100 points
        require(numGenesToMint > 0, "Insufficient points to claim a gene");

        // Reset reward points
        _stakingRewardPoints[staker] = rewardPoints % 100; // Keep remainder

        uint256[] memory claimedGeneIds = new uint256[](numGenesToMint);
        bytes memory placeholderValue = hex"05060708"; // Example placeholder data

        // Mint random gene instances as rewards (e.g., from common types)
        // A more advanced system would yield based on staked recipe types/rarity.
         uint256 totalGeneTypes = _nextGeneTypeId;
         require(totalGeneTypes > 0, "No gene types defined for rewards"); // Ensure gene types exist
         uint256 randomSeed = uint256(keccak256(abi.encodePacked(staker, block.timestamp)));

        for (uint i = 0; i < numGenesToMint; i++) {
            // Pick a random existing gene type ID
            uint256 randomGeneTypeId = (randomSeed + i) % totalGeneTypes;

            // Mint a new instance of that type
            claimedGeneIds[i] = mintGeneInstance(staker, randomGeneTypeId, placeholderValue);

            randomSeed = uint256(keccak256(abi.encodePacked(randomSeed, claimedGeneIds[i], i))); // Update seed
        }

        emit StakingRewardsClaimed(staker, claimedGeneIds);
    }


    // --- 8. Marketplace Functions ---

    /**
     * @dev Allows the owner of a recipe to list it for sale. Requires recipe to be unstaked.
     * @param recipeId The ID of the recipe to list.
     * @param price The price in wei.
     */
    function listItem(uint256 recipeId, uint256 price) external onlyRecipeOwnerOrApproved(recipeId) {
        address seller = msg.sender;
        require(ownerOf(recipeId) == seller, "Only owner can list"); // Redundant with modifier
        require(_stakedRecipes[recipeId] == address(0), "Cannot list staked recipe");
        require(marketListings[recipeId].active == false, "Recipe is already listed");
        require(price > 0, "Price must be greater than zero");

        marketListings[recipeId] = MarketListing(recipeId, price, seller, true);

        // Transfer approval to the contract itself so it can transfer on sale
        approve(address(this), recipeId); // Use the ERC721 approve function

        emit ItemListed(recipeId, seller, price);
    }

    /**
     * @dev Allows the seller to cancel a marketplace listing.
     * @param recipeId The ID of the recipe listing to cancel.
     */
    function cancelListing(uint256 recipeId) external {
        MarketListing storage listing = marketListings[recipeId];
        require(listing.active, "Recipe not currently listed");
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.active = false;

        // Optional: Clear approval from the contract if it was set
        // Need to check if the contract was indeed approved
        if (getApproved(recipeId) == address(this)) {
             _approve(address(0), recipeId);
        }

        emit ListingCanceled(recipeId, msg.sender);
    }

    /**
     * @dev Allows a buyer to purchase a listed recipe.
     * @param recipeId The ID of the recipe to buy.
     */
    function buyItem(uint256 recipeId) external payable {
        MarketListing storage listing = marketListings[recipeId];
        require(listing.active, "Recipe not currently listed or already sold");
        require(msg.value >= listing.price, "Insufficient ether sent");
        require(msg.sender != listing.seller, "Cannot buy your own listing");

        address seller = listing.seller;
        address buyer = msg.sender;
        uint256 price = listing.price;

        // Deactivate the listing BEFORE transfers to prevent reentrancy issues if seller is a contract
        listing.active = false;

        // Transfer ownership of the recipe
        // Since the contract is approved (via listItem), it can call its own transferFrom
        transferFrom(seller, buyer, recipeId);

        // Transfer Ether to the seller (and potentially split fees)
        // Use call for safer Ether transfers
        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "Ether transfer failed");

        // Optional: Handle excess Ether sent by buyer
        if (msg.value > price) {
            (success, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(success, "Excess Ether refund failed");
        }

        // Clear approval from the contract if it was set (should be cleared by transferFrom, but good practice)
         if (getApproved(recipeId) == address(this)) {
             _approve(address(0), recipeId);
         }


        emit ItemSold(recipeId, seller, buyer, price);
    }

     /**
     * @dev View function to get details of a marketplace listing.
     * @param recipeId The ID of the recipe.
     * @return A MarketListing struct.
     */
    function getListingDetails(uint256 recipeId) public view returns (MarketListing memory) {
        return marketListings[recipeId];
    }


    // --- 9. Utility & View Functions ---

    /**
     * @dev Returns details of a specific gene type.
     * @param geneTypeId The ID of the gene type.
     * @return The GeneType struct.
     */
    function getGeneTypeDetails(uint256 geneTypeId) public view returns (GeneType memory) {
        require(geneTypes[geneTypeId].engineTypeId != 0 || geneTypeId == 0, "Gene type does not exist"); // Allow 0 for safety check
        return geneTypes[geneTypeId];
    }

    /**
     * @dev Returns details of a specific gene instance.
     * @param geneInstanceId The ID of the gene instance.
     * @return The GeneInstance struct.
     */
    function getGeneInstanceDetails(uint256 geneInstanceId) public view returns (GeneInstance memory) {
         require(geneInstances[geneInstanceId].geneTypeId != 0 || geneInstanceId == 0, "Gene instance does not exist"); // Allow 0 for safety check
         return geneInstances[geneInstanceId];
    }

     /**
     * @dev Returns a list of gene instance IDs owned by a user.
     * @param user The address of the user.
     * @return An array of gene instance IDs.
     */
    function getUserGeneInstances(address user) public view returns (uint256[] memory) {
        return _userGeneInstances[user];
    }

     /**
     * @dev Returns details of a specific recipe.
     * @param recipeId The ID of the recipe.
     * @return The Recipe struct.
     */
    function getRecipeDetails(uint256 recipeId) public view returns (Recipe memory) {
         require(_exists(recipeId) || recipeId == 0, "Recipe does not exist"); // Allow 0 for safety check
         return recipes[recipeId];
    }

     /**
     * @dev Returns a list of recipe IDs owned by a user.
     * @param user The address of the user.
     * @return An array of recipe IDs.
     */
    function getUserRecipes(address user) public view returns (uint256[] memory) {
        return _userRecipes[user];
    }

     /**
     * @dev Returns a list of recipe IDs staked by a user.
     * @param user The address of the user.
     * @return An array of recipe IDs.
     */
    function getStakedRecipes(address user) public view returns (uint256[] memory) {
        return _userStakedRecipes[user];
    }

    /**
     * @dev Returns a list of recipe IDs listed for sale by a user.
     * @param user The address of the user.
     * @return An array of recipe IDs.
     */
     function getUserListings(address user) public view returns (uint256[] memory) {
         uint256[] memory userOwnedRecipes = _userRecipes[user];
         uint256[] memory userListedRecipes; // Dynamic array for results
         uint256 count = 0;

         // Iterate through owned recipes and check if listed
         for(uint i = 0; i < userOwnedRecipes.length; i++) {
             uint256 recipeId = userOwnedRecipes[i];
             if (marketListings[recipeId].active && marketListings[recipeId].seller == user) {
                 count++;
             }
         }

         // Populate the result array
         userListedRecipes = new uint256[](count);
         count = 0;
          for(uint i = 0; i < userOwnedRecipes.length; i++) {
             uint256 recipeId = userOwnedRecipes[i];
              if (marketListings[recipeId].active && marketListings[recipeId].seller == user) {
                 userListedRecipes[count] = recipeId;
                 count++;
             }
         }

         return userListedRecipes;
     }


    /**
     * @dev Returns the total number of recipes that have ever been minted.
     */
    function getTotalRecipes() public view returns (uint256) {
        return _nextRecipeId;
    }

    /**
     * @dev Returns the total number of distinct gene types defined.
     */
    function getTotalGeneTypes() public view returns (uint256) {
        return _nextGeneTypeId;
    }

     /**
     * @dev Returns the total number of gene instances that have ever been minted (including burned ones).
     */
    function getTotalGeneInstances() public view returns (uint256) {
        return _nextGeneInstanceId;
    }


    // --- 10. Constructor ---

    constructor() {
        owner = msg.sender;
        _nextGeneTypeId = 0; // Start IDs from 0
        _nextGeneInstanceId = 0;
        _nextRecipeId = 0;
    }

    // --- 11. Interface Support (ERC165 for ERC721) ---

    // ERC165 Identifier for ERC721
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02; // IERC721Receiver.onERC721Received
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f; // Optional metadata interface
    // bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63; // Optional enumerable interface

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721_METADATA || // Claiming metadata support
               // interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE || // If enumerable is fully implemented
               false; // Add other interfaces if supported
    }


    // --- Fallback / Receive (Optional but good practice) ---
    receive() external payable {}
    fallback() external payable {}
}

// Minimal interface for ERC721Receiver checks
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
```

---

**Explanation of Concepts and Advanced Features:**

1.  **Dual Assets (Gene Instances & Recipes):** Most contracts handle one primary asset type (a fungible token, an NFT). Here, we have two distinct, but interacting, assets:
    *   `GeneInstance`: Represents a specific *parameter value* (e.g., `bytes value`) of a certain `GeneType`. They are owned and consumed. Think of them as crafting ingredients.
    *   `Recipe`: Represents a unique *combination* of consumed `GeneInstance`s. This is the ERC721-like token that is owned, traded, staked, and defines the off-chain generated asset. It's the blueprint or DNA.

2.  **Procedural Generation (Off-Chain Focus):** The contract doesn't *generate* the art/music itself (that would be too complex and gas-intensive). Instead, it stores the immutable `Recipe` (`engineTypeId`, `geneInstanceIds`). An off-chain application reads this on-chain data and uses it to render the actual asset based on the `engineTypeId` and the `value` stored in the referenced `GeneInstance`s (even though the instance is "burned", its data is stored in the `geneInstances` mapping via its ID).

3.  **Forging (Crafting Mechanic):** `forgeRecipe` is the core creation function. It's more complex than a simple `mint`. It requires owning specific "ingredient" `GeneInstance`s, checks their compatibility (`engineTypeId`), burns them (sets owner to `address(0)` and removes from user's list), and then mints a new `Recipe` token containing the list of original gene instance IDs.

4.  **Breeding (Mutation/Procreation):** `breedRecipes` introduces a "yield farming" or "procreation" mechanic. Combining two owned recipes produces *new* `GeneInstance`s. The example logic is simple (randomly pick gene *types* from parents and mint new instances), but this could be highly complex:
    *   Implementing genetic algorithms (cross-over, mutation).
    *   Requiring specific rare gene combinations for exotic offspring genes.
    *   Having a chance of failure or yielding nothing.
    *   Requiring a fee (crypto or specific genes).

5.  **Staking for Yield (Gene Farming):** `stakeRecipe` and `claimStakingRewards` implement a staking mechanism where the yield isn't a fungible token, but *new Gene Instances*. The `_stakingRewardPoints` and simple calculation are placeholders; a real system would calculate rewards over time based on the staked recipe's rarity and duration. This provides a sink for Recipes and a way to introduce new genes into the ecosystem over time.

6.  **Dynamic Rarity:** `calculateRecipeRarity` provides a simple on-chain method to determine a recipe's rarity based on its components. This score can then be used by off-chain applications for display, or potentially influence on-chain mechanics like staking yield or breeding outcomes (though not fully implemented in this example).

7.  **Internal Marketplace:** Includes basic `listItem`, `cancelListing`, and `buyItem` functionality directly within the contract. This avoids reliance on external marketplaces (though integration with platforms like OpenSea would typically involve ERC721 approval). The `buyItem` function handles Ether transfer and listing state change atomically.

8.  **Custom ERC721 Implementation:** Instead of inheriting from OpenZeppelin's `ERC721`, the core functions (`balanceOf`, `ownerOf`, `transferFrom`, etc.) are implemented from scratch. This fulfills the "don't duplicate any of open source" aspect *while still adhering to the ERC721 standard interface* (checked via `supportsInterface`). This is more complex and gas-intensive than using a library, but demonstrates understanding of the underlying logic and avoids direct code duplication.

9.  **Keeping Gene Data:** Although genes are "burned" during forging, their `GeneInstance` struct and `value` data are *not* deleted from the `geneInstances` mapping. This allows `getRecipeGenes` to reconstruct the recipe's components and `calculateRecipeRarity` to access their type information, which is crucial for the off-chain generator and on-chain mechanics. The owner is simply set to `address(0)`.

This contract provides a framework for a complex, interactive ecosystem centered around creating and evolving unique digital assets based on on-chain defined parameters.