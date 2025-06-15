Okay, here is a Solidity smart contract implementing an "Infinite Alchemy Guild". This contract manages its own internal fungible "Essence" tokens and non-fungible "Artifact" NFTs, allowing users (Alchemists) to "craft" artifacts by combining essences according to on-chain recipes, influenced by their "Mastery" level.

It incorporates several advanced/creative concepts:
1.  **Internal Token Management:** Instead of just interacting with external tokens, the contract acts as the minter/burner for its own ERC-20 Essence and ERC-721 Artifact tokens, which are deployed *by* this contract's constructor. (While using standard ERC interfaces, the *logic* for minting/burning/using them is integrated uniquely within the crafting system).
2.  **On-Chain Recipe System:** Recipes are defined and stored within the contract state, not external metadata.
3.  **Dynamic Crafting Outcomes:** Success/failure chance and generated NFT attributes are influenced by the user's on-chain "Mastery" level.
4.  **Procedural Attribute Generation:** Artifact NFT attributes are generated during the crafting process based on recipe ranges, mastery, and a pseudo-random factor.
5.  **Mastery Progression:** A dedicated system tracks and updates user mastery based on successful crafts.
6.  **Token Burn/Sink Mechanics:** Essences are burned for crafting and learning recipes. Artifacts can be burned to recover some essence.
7.  **NFT Attribute Rerolling:** Users can spend essence to re-generate the attributes of an existing artifact.

This specific combination of mechanics, where a single contract governs token issuance, complex crafting logic with variable outcomes, and on-chain progression/attribute generation, provides a unique system not typically found in standard open-source implementations (like basic ERC-20/721 factories, simple staking contracts, or standard marketplaces).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
//
// Contract: InfiniteAlchemyGuild
// Purpose: Manages an on-chain crafting system using custom Essence (ERC-20) and Artifact (ERC-721) tokens.
// Users (Alchemists) learn recipes and craft Artifacts by burning Essence. Crafting success and Artifact attributes
// are influenced by user Mastery level. Artifacts can be burned for Essence or have attributes rerolled.
//
// State Variables:
// - essenceToken: Address of the ERC-20 Essence token deployed by this contract.
// - artifactNFT: Address of the ERC-721 Artifact token deployed by this contract.
// - recipes: Mapping of recipe IDs to Recipe structs.
// - recipeCount: Counter for generating recipe IDs.
// - learnedRecipes: Mapping tracking which users have learned which recipes.
// - userMastery: Mapping tracking each user's mastery level.
// - artifactAttributes: Mapping tracking custom attributes for each Artifact token ID.
// - artifactAttributeNames: Mapping of attribute IDs to string names.
// - nextArtifactId: Counter for generating Artifact token IDs.
// - craftingFeeEssence: Amount of essence burned as a fee per craft attempt.
// - essenceCostToLearnRecipe: Amount of essence required to learn a recipe.
// - essenceRefundOnFailurePercent: Percentage of input essence refunded on crafting failure.
// - essenceReturnOnBurnPercent: Percentage of *recipe input* essence returned on burning an artifact.
// - masteryGainedPerSuccess: Amount of mastery gained on a successful craft.
// - masterySuccessChanceBonusPer1000Mastery: Bonus success chance added per 1000 mastery points.
//
// Structs:
// - Ingredient: Represents an input requirement for a recipe (token address, amount).
// - ArtifactAttributeRange: Defines the potential range (min, max) for an artifact attribute during crafting.
// - Recipe: Defines a crafting recipe (ID, name, required mastery, inputs, base success chance, attribute ranges, mastery gain, failure refund%).
// - ArtifactAttributes: Stores the generated attribute values for a specific artifact.
//
// Events:
// - RecipeAdded: Emitted when a new recipe is added.
// - RecipeUpdated: Emitted when an existing recipe is updated.
// - RecipeLearned: Emitted when a user learns a recipe.
// - CraftSuccess: Emitted on successful crafting.
// - CraftFailure: Emitted on crafting failure.
// - MasteryGained: Emitted when a user gains mastery.
// - ArtifactBurned: Emitted when an artifact is burned for essence.
// - AttributesRerolled: Emitted when an artifact's attributes are rerolled.
// - FeeWithdrawn: Emitted when fees are withdrawn by the owner.
// - AttributeNameSet: Emitted when an artifact attribute name is set.
//
// Functions (Total: 30+ custom logic functions interacting with internal tokens/state):
//
// Admin/Setup Functions:
// 1.  constructor(): Deploys Essence and Artifact tokens, sets initial owner.
// 2.  addRecipe(Recipe calldata _recipe): Adds a new crafting recipe.
// 3.  updateRecipe(uint256 _recipeId, Recipe calldata _recipe): Updates an existing recipe (careful!).
// 4.  setCraftingFee(uint256 _amount): Sets the essence fee for each craft attempt.
// 5.  setEssenceCostToLearnRecipe(uint256 _amount): Sets the essence cost to learn a recipe.
// 6.  setEssenceRefundOnFailurePercent(uint256 _percent): Sets percentage of input essence refunded on failure.
// 7.  setEssenceReturnOnBurnPercent(uint256 _percent): Sets percentage of input essence returned on burn.
// 8.  setMasteryGainedPerSuccess(uint256 _amount): Sets mastery gained on success.
// 9.  setMasterySuccessChanceBonusPer1000Mastery(uint256 _bonus): Sets mastery bonus to success chance.
// 10. mintInitialEssence(address _to, uint256 _amount): Mints initial essence tokens (e.g., for distribution).
// 11. withdrawFees(address _to): Withdraws accumulated essence fees.
// 12. setArtifactAttributeName(uint8 _attributeId, string calldata _name): Sets the name for an attribute ID.
// 13. pause(): Pauses contract (prevents crafting, learning, burning, rerolling).
// 14. unpause(): Unpauses contract.
//
// User/Gameplay Functions:
// 15. learnRecipe(uint256 _recipeId): Allows a user to learn a recipe by paying essence.
// 16. craftArtifact(uint256 _recipeId): Attempts to craft an artifact using a learned recipe. Requires user approval for input essences + fee.
// 17. burnArtifactIntoEssence(uint256 _artifactId): Burns an artifact to recover essence. Requires user ownership.
// 18. rerollArtifactAttributes(uint256 _artifactId, uint256 _essenceCost): Rerolls artifact attributes for an essence cost. Requires user ownership and approval.
//
// View Functions (Queries):
// 19. getEssenceAddress(): Returns the address of the Essence token.
// 20. getArtifactAddress(): Returns the address of the Artifact token.
// 21. getRecipe(uint256 _recipeId): Returns details of a specific recipe.
// 22. getRecipeCount(): Returns the total number of recipes.
// 23. getAllRecipeIds(): Returns an array of all recipe IDs.
// 24. hasLearnedRecipe(address _user, uint256 _recipeId): Checks if a user has learned a recipe.
// 25. getMasteryLevel(address _user): Returns a user's mastery level.
// 26. getArtifactAttributes(uint256 _artifactId): Returns the stored attributes for an artifact.
// 27. getTotalArtifactsMinted(): Returns the total number of artifacts ever minted.
// 28. getMasteryRequiredForRecipe(uint256 _recipeId): Returns mastery required for a recipe.
// 29. getEssenceCostToLearnRecipe(): Returns the current cost to learn a recipe.
// 30. getCraftingFee(): Returns the current crafting fee.
// 31. getEssenceRefundOnFailurePercent(): Returns the essence refund percentage on failure.
// 32. getEssenceReturnOnBurnPercent(): Returns the essence return percentage on burn.
// 33. getCraftingSuccessRate(uint256 _recipeId, uint256 _userMastery): Calculates the actual success chance for a user/recipe.
// 34. getArtifactAttributeRangeForRecipe(uint256 _recipeId): Returns the attribute ranges defined in a recipe.
// 35. getArtifactAttributeName(uint8 _attributeId): Returns the name of an attribute ID.
// 36. simulateCrafting(uint256 _recipeId, uint256 _userMastery): Simulates attribute generation without spending resources.
//
// Note: Standard ERC-20/ERC-721 interface functions (balanceOf, transfer, approve, ownerOf, etc.) are inherited from OpenZeppelin
// and are not explicitly listed in the "Custom Logic Functions" count, but are necessary for interaction.
// The "don't duplicate any of open source" interpretation used here is that the core *application logic*
// and *system design* should be unique, while standard interfaces and battle-tested utilities (like
// OpenZeppelin's ERC implementations, Ownable, Pausable) are used for safety and compliance, not
// as the creative core of the contract.

// --- CONTRACT CODE ---

// Internal Essence Token
contract EssenceToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {}

    // The Guild contract will be the minter
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // The Guild contract can also burn if needed
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

// Internal Artifact NFT
contract ArtifactNFT is ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) ERC721URIStorage(name, symbol) Ownable(msg.sender) {}

    // The Guild contract will be the minter
    function mint(address to, uint256 tokenId, string memory uri) external onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The Guild contract will be the burner
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    // Override for access control - only owner or approved can transfer
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        super.safeTransferFrom(from, to, tokenId, data);
    }
}


contract InfiniteAlchemyGuild is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    EssenceToken public essenceToken;
    ArtifactNFT public artifactNFT;

    struct Ingredient {
        address tokenAddress;
        uint256 amount;
    }

    struct ArtifactAttributeRange {
        uint8 attributeId; // e.g., 0=Power, 1=Speed, 2=Durability etc.
        uint256 min;
        uint256 max;
    }

    struct Recipe {
        uint256 id;
        string name;
        uint256 requiredMastery;
        Ingredient[] inputs;
        uint256 baseSuccessChance; // Out of 10000 (for 0.01% precision)
        ArtifactAttributeRange[] attributeRanges;
        uint256 masteryGainedOnSuccess;
    }

    struct ArtifactAttributes {
        uint8[] attributeIds;
        uint256[] values;
    }

    mapping(uint256 => Recipe) public recipes;
    Counters.Counter private _recipeCount;

    mapping(address => mapping(uint256 => bool)) public learnedRecipes; // user => recipeId => learned

    mapping(address => uint256) public userMastery; // user => mastery level

    mapping(uint256 => ArtifactAttributes) private artifactAttributes; // artifactId => attributes
    mapping(uint8 => string) public artifactAttributeNames; // attributeId => name

    Counters.Counter private _nextArtifactId;

    // Configurable parameters (in EssenceToken amount)
    uint256 public craftingFeeEssence = 100; // Fee paid per craft attempt regardless of success/failure
    uint256 public essenceCostToLearnRecipe = 500; // Cost to learn a recipe
    uint256 public essenceRefundOnFailurePercent = 50; // % of input cost (excluding fee) refunded on failure
    uint256 public essenceReturnOnBurnPercent = 80; // % of *original input cost* returned on artifact burn

    // Configurable Mastery parameters
    uint256 public masteryGainedPerSuccess = 10;
    uint256 public masterySuccessChanceBonusPer1000Mastery = 50; // 0.5% bonus chance per 1000 mastery

    // --- Events ---

    event RecipeAdded(uint256 recipeId, string name, address indexed by);
    event RecipeUpdated(uint256 recipeId, string name, address indexed by);
    event RecipeLearned(address indexed user, uint256 recipeId);
    event CraftSuccess(address indexed user, uint256 recipeId, uint256 artifactId, uint256 masteryGained);
    event CraftFailure(address indexed user, uint256 recipeId, uint256 essenceRefunded);
    event MasteryGained(address indexed user, uint256 newMasteryLevel);
    event ArtifactBurned(address indexed user, uint256 artifactId, uint256 essenceReturned);
    event AttributesRerolled(address indexed user, uint256 artifactId, uint256 essenceCost);
    event FeeWithdrawn(address indexed to, uint256 amount);
    event AttributeNameSet(uint8 attributeId, string name, address indexed by);
    event Paused(address account);
    event Unpaused(address account);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Deploy the custom ERC-20 and ERC-721 tokens managed by this contract
        essenceToken = new EssenceToken("Alchemy Essence", "ESS");
        artifactNFT = new ArtifactNFT("Mystic Artifact", "ARTF");

        // Transfer ownership of the tokens to this Guild contract
        // This allows the Guild contract to call mint/burn on them
        essenceToken.transferOwnership(address(this));
        artifactNFT.transferOwnership(address(this));

        // Set some initial default parameters
        craftingFeeEssence = 100e18; // Example: 100 tokens (assuming 18 decimals)
        essenceCostToLearnRecipe = 500e18; // Example: 500 tokens
        essenceRefundOnFailurePercent = 50; // 50%
        essenceReturnOnBurnPercent = 80; // 80%
        masteryGainedPerSuccess = 10;
        masterySuccessChanceBonusPer1000Mastery = 50; // 0.5% per 1000 mastery (50/100000 total chance points)
    }

    // --- Admin/Setup Functions ---

    /**
     * @notice Adds a new crafting recipe. Only callable by the owner.
     * @param _recipe The Recipe struct containing details.
     */
    function addRecipe(Recipe calldata _recipe) external onlyOwner {
        _recipeCount.increment();
        uint256 newRecipeId = _recipeCount.current();
        _recipe.id = newRecipeId; // Ensure internal ID matches mapping key
        recipes[newRecipeId] = _recipe;
        emit RecipeAdded(newRecipeId, _recipe.name, msg.sender);
    }

    /**
     * @notice Updates an existing crafting recipe. Use with extreme caution as it changes game mechanics. Only callable by the owner.
     * @param _recipeId The ID of the recipe to update.
     * @param _recipe The updated Recipe struct.
     */
    function updateRecipe(uint256 _recipeId, Recipe calldata _recipe) external onlyOwner {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        _recipe.id = _recipeId; // Ensure ID consistency
        recipes[_recipeId] = _recipe;
        emit RecipeUpdated(_recipeId, _recipe.name, msg.sender);
    }

    /**
     * @notice Sets the essence fee for each craft attempt. Only callable by the owner.
     * @param _amount The new fee amount.
     */
    function setCraftingFee(uint256 _amount) external onlyOwner {
        craftingFeeEssence = _amount;
    }

    /**
     * @notice Sets the essence cost required for a user to learn a recipe. Only callable by the owner.
     * @param _amount The new cost amount.
     */
    function setEssenceCostToLearnRecipe(uint256 _amount) external onlyOwner {
        essenceCostToLearnRecipe = _amount;
    }

    /**
     * @notice Sets the percentage of input essence (excluding fee) refunded on crafting failure. Only callable by the owner.
     * @param _percent The percentage (0-100).
     */
    function setEssenceRefundOnFailurePercent(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Percent cannot exceed 100");
        essenceRefundOnFailurePercent = _percent;
    }

    /**
     * @notice Sets the percentage of original recipe input cost returned when an artifact is burned. Only callable by the owner.
     * @param _percent The percentage (0-100).
     */
    function setEssenceReturnOnBurnPercent(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Percent cannot exceed 100");
        essenceReturnOnBurnPercent = _percent;
    }

    /**
     * @notice Sets the amount of mastery gained upon a successful craft. Only callable by the owner.
     * @param _amount The amount of mastery points.
     */
    function setMasteryGainedPerSuccess(uint256 _amount) external onlyOwner {
        masteryGainedPerSuccess = _amount;
    }

    /**
     * @notice Sets the bonus success chance added per 1000 mastery points. Only callable by the owner.
     * @param _bonus The bonus points (out of 10000 total chance).
     */
    function setMasterySuccessChanceBonusPer1000Mastery(uint256 _bonus) external onlyOwner {
        masterySuccessChanceBonusPer1000Mastery = _bonus;
    }

    /**
     * @notice Mints initial essence tokens for a user. Only callable by the owner (for initial distribution).
     * @param _to The recipient address.
     * @param _amount The amount to mint.
     */
    function mintInitialEssence(address _to, uint256 _amount) external onlyOwner {
        essenceToken.mint(_to, _amount);
    }

    /**
     * @notice Allows the owner to withdraw accumulated essence fees.
     * @param _to The address to send the fees to.
     */
    function withdrawFees(address _to) external onlyOwner {
        uint256 feeBalance = essenceToken.balanceOf(address(this));
        if (feeBalance > 0) {
            // Note: This assumes the Guild contract holds fees directly.
            // A separate fee pool might be more robust depending on architecture.
            // If fees are burned, this function wouldn't exist.
             essenceToken.transfer(_to, feeBalance); // Assumes EssenceToken has a transfer function callable by its owner (this contract)
            emit FeeWithdrawn(_to, feeBalance);
        }
    }

    /**
     * @notice Sets the human-readable name for a specific artifact attribute ID. Only callable by the owner.
     * @param _attributeId The ID of the attribute.
     * @param _name The name for the attribute (e.g., "Power", "Speed").
     */
    function setArtifactAttributeName(uint8 _attributeId, string calldata _name) external onlyOwner {
        artifactAttributeNames[_attributeId] = _name;
        emit AttributeNameSet(_attributeId, _name, msg.sender);
    }

    /**
     * @notice Pauses crafting, learning, burning, and rerolling operations. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, re-enabling operations. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- User/Gameplay Functions ---

    /**
     * @notice Allows a user to learn a recipe by paying a fixed essence cost.
     * @param _recipeId The ID of the recipe to learn.
     */
    function learnRecipe(uint256 _recipeId) external whenNotPaused {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        require(!learnedRecipes[msg.sender][_recipeId], "Recipe already learned");
        require(essenceCostToLearnRecipe > 0, "Learning recipe is currently disabled");

        // Transfer essence cost from user to contract (requires prior approval)
        essenceToken.transferFrom(msg.sender, address(this), essenceCostToLearnRecipe);

        learnedRecipes[msg.sender][_recipeId] = true;
        emit RecipeLearned(msg.sender, _recipeId);
    }

    /**
     * @notice Attempts to craft an artifact using a specified recipe.
     * Burns input essences and crafting fee. Outcome depends on mastery and chance.
     * Requires user to approve the Guild contract for the total essence cost (inputs + fee) *before* calling.
     * @param _recipeId The ID of the recipe to use.
     */
    function craftArtifact(uint256 _recipeId) external whenNotPaused {
        Recipe storage recipe = recipes[_recipeId];
        require(recipe.id != 0, "Recipe does not exist");
        require(learnedRecipes[msg.sender][_recipeId], "Recipe not learned");
        require(userMastery[msg.sender] >= recipe.requiredMastery, "Not enough mastery");

        uint256 totalInputCost = craftingFeeEssence;
        for (uint i = 0; i < recipe.inputs.length; i++) {
            // Assumes all inputs are the EssenceToken for simplicity in this design
            require(recipe.inputs[i].tokenAddress == address(essenceToken), "Only EssenceToken can be used as ingredient");
            totalInputCost += recipe.inputs[i].amount;
        }

        // Transfer all required essence (inputs + fee) from user to the contract
        // This requires the user to have called approve() on the EssenceToken beforehand
        essenceToken.transferFrom(msg.sender, address(this), totalInputCost);

        // Calculate success chance based on mastery
        uint256 currentMastery = userMastery[msg.sender];
        uint256 successChance = _calculateSuccessChance(recipe.baseSuccessChance, currentMastery);

        // Determine success using pseudo-randomness (NOTE: Block-based randomness is exploitable!)
        // A truly secure random source (like Chainlink VRF) would be needed for production games.
        // Using a simple, exploitable method for demonstration purposes only.
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextArtifactId.current(), block.number));
        uint256 randomNumber = uint256(randomSeed) % 10001; // 0 to 10000

        if (randomNumber <= successChance) {
            // Success!
            _nextArtifactId.increment();
            uint256 newArtifactId = _nextArtifactId.current();

            // Generate attributes
            ArtifactAttributes memory generatedAttributes = _generateArtifactAttributes(recipe, currentMastery, randomSeed);
            artifactAttributes[newArtifactId] = generatedAttributes;

            // Mint the artifact to the user
            // ERC721URIStorage requires a URI. We can generate a simple one or leave it to a metadata service.
            // Let's generate a placeholder URI pointing to a hypothetical API endpoint.
            string memory tokenURI = string(abi.encodePacked("https://alchemyguild.io/api/artifact/", newArtifactId.toString()));
            artifactNFT.mint(msg.sender, newArtifactId, tokenURI);

            // Gain mastery
            uint256 masteryGained = recipe.masteryGainedOnSuccess;
            if (masteryGained > 0) {
                userMastery[msg.sender] += masteryGained;
                emit MasteryGained(msg.sender, userMastery[msg.sender]);
            }

            emit CraftSuccess(msg.sender, _recipeId, newArtifactId, masteryGained);

        } else {
            // Failure!
            // Calculate and refund a percentage of the input cost (excluding fee)
            uint256 inputCostExcludingFee = totalInputCost - craftingFeeEssence;
            uint256 refundAmount = (inputCostExcludingFee * essenceRefundOnFailurePercent) / 100;

            if (refundAmount > 0) {
                // Send refund back to the user
                 essenceToken.transfer(msg.sender, refundAmount); // Assumes EssenceToken allows transfer by its owner (this contract)
            }

            // Fees are kept by the contract regardless of success/failure
            emit CraftFailure(msg.sender, _recipeId, refundAmount);
        }
    }

    /**
     * @notice Allows a user to burn one of their artifacts to recover a percentage of its original crafting cost in essence.
     * Requires user ownership of the artifact.
     * @param _artifactId The ID of the artifact to burn.
     */
    function burnArtifactIntoEssence(uint256 _artifactId) external whenNotPaused {
        require(artifactNFT.ownerOf(_artifactId) == msg.sender, "Not artifact owner");

        // Determine original recipe cost. This requires knowing which recipe was used to mint it.
        // A more robust system would store the originating recipeId with the artifact's attributes.
        // For simplicity here, let's assume the essence return is a percentage of the *average* recipe cost or a fixed value per artifact type.
        // A better approach: store recipeId in ArtifactAttributes struct. Let's modify the struct and mint logic.

        ArtifactAttributes storage arts = artifactAttributes[_artifactId];
        require(arts.recipeId != 0, "Artifact origin unknown"); // Check if attribute data exists/is valid

        Recipe storage originalRecipe = recipes[arts.recipeId];
        require(originalRecipe.id != 0, "Original recipe no longer exists");

        uint256 originalInputCostExcludingFee = 0;
        for (uint i = 0; i < originalRecipe.inputs.length; i++) {
            originalInputCostExcludingFee += originalRecipe.inputs[i].amount;
        }

        uint256 returnAmount = (originalInputCostExcludingFee * essenceReturnOnBurnPercent) / 100;

        // Burn the artifact NFT
        artifactNFT.burn(_artifactId);

        // Delete attributes to save gas (optional, but good practice)
        delete artifactAttributes[_artifactId];

        // Mint essence back to the user
        if (returnAmount > 0) {
            essenceToken.mint(msg.sender, returnAmount); // Minting requires the Guild to be the EssenceToken owner
        }

        emit ArtifactBurned(msg.sender, _artifactId, returnAmount);
    }

     /**
     * @notice Allows a user to pay essence to re-generate the attributes of an existing artifact.
     * Requires user ownership and approval for the essence cost.
     * Attributes are regenerated based on the artifact's *original recipe* and the user's *current mastery*.
     * @param _artifactId The ID of the artifact to reroll.
     * @param _essenceCost The amount of essence required for the reroll.
     */
    function rerollArtifactAttributes(uint256 _artifactId, uint256 _essenceCost) external whenNotPaused {
        require(artifactNFT.ownerOf(_artifactId) == msg.sender, "Not artifact owner");
        require(_essenceCost > 0, "Reroll cost must be positive");

        ArtifactAttributes storage arts = artifactAttributes[_artifactId];
        require(arts.recipeId != 0, "Artifact origin unknown"); // Check if attribute data exists/is valid

        Recipe storage originalRecipe = recipes[arts.recipeId];
        require(originalRecipe.id != 0, "Original recipe no longer exists");

        // Transfer essence cost from user (requires prior approval)
        essenceToken.transferFrom(msg.sender, address(this), _essenceCost);

        // Generate new attributes based on the original recipe and current mastery
        // Use a different random seed for rerolling
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _artifactId, block.number, "reroll"));
        ArtifactAttributes memory newAttributes = _generateArtifactAttributes(originalRecipe, userMastery[msg.sender], randomSeed);

        // Update stored attributes
        artifactAttributes[_artifactId] = newAttributes;

        emit AttributesRerolled(msg.sender, _artifactId, _essenceCost);
    }


    // --- View Functions ---

    /**
     * @notice Returns the address of the deployed Essence token contract.
     */
    function getEssenceAddress() external view returns (address) {
        return address(essenceToken);
    }

    /**
     * @notice Returns the address of the deployed Artifact NFT contract.
     */
    function getArtifactAddress() external view returns (address) {
        return address(artifactNFT);
    }

    /**
     * @notice Returns the details of a specific recipe.
     * @param _recipeId The ID of the recipe.
     */
    function getRecipe(uint256 _recipeId) external view returns (Recipe memory) {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        return recipes[_recipeId];
    }

    /**
     * @notice Returns the total number of recipes added to the guild.
     */
    function getRecipeCount() external view returns (uint256) {
        return _recipeCount.current();
    }

    /**
     * @notice Returns an array of all existing recipe IDs.
     * Note: Can be gas intensive if many recipes exist.
     */
    function getAllRecipeIds() external view returns (uint256[] memory) {
        uint256 count = _recipeCount.current();
        uint256[] memory ids = new uint256[](count);
        for (uint i = 1; i <= count; i++) {
            ids[i - 1] = i;
        }
        return ids;
    }

    /**
     * @notice Checks if a user has learned a specific recipe.
     * @param _user The address of the user.
     * @param _recipeId The ID of the recipe.
     */
    function hasLearnedRecipe(address _user, uint256 _recipeId) external view returns (bool) {
        return learnedRecipes[_user][_recipeId];
    }

    /**
     * @notice Returns the mastery level of a user.
     * @param _user The address of the user.
     */
    function getMasteryLevel(address _user) external view returns (uint256) {
        return userMastery[_user];
    }

    /**
     * @notice Returns the custom attributes stored for a specific artifact.
     * @param _artifactId The ID of the artifact.
     */
    function getArtifactAttributes(uint256 _artifactId) external view returns (ArtifactAttributes memory) {
        require(artifactNFT.ownerOf(_artifactId) != address(0), "Artifact does not exist"); // Check if NFT exists
        // Note: This doesn't check if attributes exist, as they might be deleted after burn.
        // Call ownerOf first to ensure the token exists.
        return artifactAttributes[_artifactId];
    }

    /**
     * @notice Returns the total number of artifacts ever minted by the guild.
     */
    function getTotalArtifactsMinted() external view returns (uint256) {
        return _nextArtifactId.current();
    }

    /**
     * @notice Returns the minimum mastery level required to attempt a specific recipe.
     * @param _recipeId The ID of the recipe.
     */
    function getMasteryRequiredForRecipe(uint256 _recipeId) external view returns (uint256) {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        return recipes[_recipeId].requiredMastery;
    }

    /**
     * @notice Returns the current cost in essence to learn any recipe.
     */
    function getEssenceCostToLearnRecipe() external view returns (uint256) {
        return essenceCostToLearnRecipe;
    }

     /**
     * @notice Returns the current essence fee charged per crafting attempt.
     */
    function getCraftingFee() external view returns (uint256) {
        return craftingFeeEssence;
    }

    /**
     * @notice Returns the percentage of input essence refunded on crafting failure.
     */
    function getEssenceRefundOnFailurePercent() external view returns (uint256) {
        return essenceRefundOnFailurePercent;
    }

    /**
     * @notice Returns the percentage of original recipe input cost returned when an artifact is burned.
     */
    function getEssenceReturnOnBurnPercent() external view returns (uint256) {
        return essenceReturnOnBurnPercent;
    }

    /**
     * @notice Calculates the effective success chance for a user attempting a recipe based on their mastery.
     * @param _recipeId The ID of the recipe.
     * @param _userMastery The mastery level of the user.
     * @return The success chance out of 10000.
     */
    function getCraftingSuccessRate(uint256 _recipeId, uint256 _userMastery) external view returns (uint256) {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        return _calculateSuccessChance(recipes[_recipeId].baseSuccessChance, _userMastery);
    }

    /**
     * @notice Returns the attribute ranges defined for the potential output artifact of a recipe.
     * @param _recipeId The ID of the recipe.
     */
    function getArtifactAttributeRangeForRecipe(uint256 _recipeId) external view returns (ArtifactAttributeRange[] memory) {
        require(recipes[_recipeId].id != 0, "Recipe does not exist");
        return recipes[_recipeId].attributeRanges;
    }

    /**
     * @notice Returns the name associated with an artifact attribute ID.
     * @param _attributeId The ID of the attribute.
     */
    function getArtifactAttributeName(uint8 _attributeId) external view returns (string memory) {
        return artifactAttributeNames[_attributeId];
    }

     /**
     * @notice Simulates the attribute generation for a recipe and mastery level without performing a craft.
     * Useful for frontends to show potential outcomes.
     * Uses a non-deterministic seed for simulation purposes. Do NOT rely on this for any state-changing logic.
     * @param _recipeId The ID of the recipe to simulate.
     * @param _userMastery The mastery level to simulate with.
     * @return An array of attribute IDs and an array of potential values.
     */
    function simulateCrafting(uint256 _recipeId, uint256 _userMastery) external view returns (uint8[] memory, uint256[] memory) {
        Recipe storage recipe = recipes[_recipeId];
        require(recipe.id != 0, "Recipe does not exist");

        // Use block-based seed for simulation, but emphasize it's not for real crafting
        bytes32 simulationSeed = keccak256(abi.encodePacked(block.timestamp, msg.sender, "simulate"));

        ArtifactAttributes memory simulatedAttributes = _generateArtifactAttributes(recipe, _userMastery, simulationSeed);

        return (simulatedAttributes.attributeIds, simulatedAttributes.values);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the actual success chance based on base chance and mastery.
     * @param _baseChance The base success chance (out of 10000).
     * @param _userMastery The user's mastery level.
     * @return The effective success chance out of 10000.
     */
    function _calculateSuccessChance(uint256 _baseChance, uint256 _userMastery) internal view returns (uint256) {
        // Bonus is per 1000 mastery, out of 10000 total chance points
        uint256 masteryBonus = (_userMastery / 1000) * masterySuccessChanceBonusPer1000Mastery;
        uint256 effectiveChance = _baseChance + masteryBonus;
        // Cap chance at 100% (10000 points)
        return effectiveChance > 10000 ? 10000 : effectiveChance;
    }

    /**
     * @dev Generates artifact attribute values based on recipe ranges, mastery, and a random seed.
     * @param _recipe The recipe used.
     * @param _userMastery The user's mastery level.
     * @param _seed A random seed for attribute generation.
     * @return The generated ArtifactAttributes struct.
     */
    function _generateArtifactAttributes(Recipe storage _recipe, uint256 _userMastery, bytes32 _seed) internal view returns (ArtifactAttributes memory) {
        uint256 numAttributes = _recipe.attributeRanges.length;
        uint8[] memory attributeIds = new uint8[](numAttributes);
        uint256[] memory values = new uint256[](numAttributes);

        // Use a changing seed for each attribute generation within the same transaction
        bytes32 currentSeed = _seed;

        for (uint i = 0; i < numAttributes; i++) {
            ArtifactAttributeRange storage range = _recipe.attributeRanges[i];
            attributeIds[i] = range.attributeId;

            if (range.min == range.max) {
                // Fixed value if min equals max
                values[i] = range.min;
            } else {
                // Generate a value within the range, influenced by mastery
                uint256 rangeSize = range.max - range.min;

                // Generate a random value within the range size
                currentSeed = keccak256(abi.encodePacked(currentSeed, i, msg.sender, block.number));
                uint256 randomOffset = uint256(currentSeed) % (rangeSize + 1);

                // Apply mastery influence (e.g., shift distribution towards max)
                // Simple model: Mastery adds a bias towards the max value.
                // (randomOffset + masteryBonus) capped by rangeSize
                uint265 masteryBias = _userMastery / 100; // Example: 1 bonus point per 100 mastery
                uint256 finalOffset = randomOffset;
                if (masteryBias > 0) {
                     // Add mastery bias, ensuring we don't exceed rangeSize
                     finalOffset = (randomOffset + masteryBias) > rangeSize ? rangeSize : (randomOffset + masteryBias);
                }

                values[i] = range.min + finalOffset;
            }
        }

        // Store the originating recipe ID with the attributes for burn/reroll logic
        ArtifactAttributes memory arts = ArtifactAttributes({
             attributeIds: attributeIds,
             values: values,
             recipeId: _recipe.id // Store the recipe ID
        });

        return arts;
    }

    // --- Add recipeId to ArtifactAttributes struct ---
    // Need to redefine ArtifactAttributes and update functions that use it.
    // This requires a storage layout change, which is breaking.
    // For demonstration, let's redefine the struct and adjust the functions.

    // Redefine ArtifactAttributes struct with recipeId
    struct ArtifactAttributes {
        uint256 recipeId; // Add this field
        uint8[] attributeIds;
        uint256[] values;
    }
    // Re-mapping storage variable requires careful migration in production,
    // but in this example, we just update the struct definition.
    // mapping(uint256 => ArtifactAttributes) private artifactAttributes; // Already declared above

    // Update _generateArtifactAttributes to include recipeId
    function _generateArtifactAttributes(Recipe storage _recipe, uint256 _userMastery, bytes32 _seed) internal view returns (ArtifactAttributes memory) {
        uint256 numAttributes = _recipe.attributeRanges.length;
        uint8[] memory attributeIds = new uint8[](numAttributes);
        uint256[] memory values = new uint256[](numAttributes);

        bytes32 currentSeed = _seed;

        for (uint i = 0; i < numAttributes; i++) {
            ArtifactAttributeRange storage range = _recipe.attributeRanges[i];
            attributeIds[i] = range.attributeId;

            if (range.min == range.max) {
                values[i] = range.min;
            } else {
                uint256 rangeSize = range.max - range.min;
                currentSeed = keccak256(abi.encodePacked(currentSeed, i, msg.sender, block.number));
                uint256 randomOffset = uint256(currentSeed) % (rangeSize + 1);

                uint256 masteryBias = _userMastery / 100;
                uint256 finalOffset = randomOffset;
                if (masteryBias > 0) {
                     finalOffset = (randomOffset + masteryBias) > rangeSize ? rangeSize : (randomOffset + masteryBias);
                }
                values[i] = range.min + finalOffset;
            }
        }

        ArtifactAttributes memory arts = ArtifactAttributes({
             recipeId: _recipe.id, // Now included
             attributeIds: attributeIds,
             values: values
        });

        return arts;
    }
     // Ensure burnArtifactIntoEssence and rerollArtifactAttributes use arts.recipeId

    // --- End of ArtifactAttributes struct update ---


}
```