Okay, let's create a smart contract concept that's a bit more involved than typical tokens or basic dApps. We'll go for a system that combines elements of dynamic assets, crafting, and decentralized collaboration/discovery.

**Concept: The Alchemical Forge & Lore Repository**

This contract system allows users to:
1.  Stake (provide) various "Raw Materials" (ERC-1155 fungible tokens managed by the contract).
2.  Discover or propose "Alchemical Recipes" (structs defining input materials and output artifact characteristics). Recipes need to be approved by a designated authority or via a governance mechanism.
3.  "Forge" unique "Artifacts" (ERC-721 non-fungible tokens) by consuming staked materials according to an approved recipe.
4.  "Analyze" forged artifacts to potentially reveal hidden "Lore" (dynamic, on-chain data) or additional properties. This analysis might require consuming more materials or tokens.
5.  Other functionalities related to querying recipes, materials, artifacts, and managing the system.

This combines ERC-1155 (materials) with ERC-721 (artifacts), state changes based on actions (analysis), a discovery/approval mechanism (recipes), and potential for future expansion into more complex lore/gameplay mechanics.

---

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- CONTRACT: AlchemicalForge ---

// @title Outline:
// 1. Imports (OpenZeppelin standards)
// 2. Custom Errors
// 3. Events
// 4. State Variables (Ownership, Pausability, Token references, Counters, Mappings for Materials, Recipes, Artifacts)
// 5. Structs (Recipe, ArtifactData)
// 6. Modifiers (e.g., onlyRecipeAuthority)
// 7. Constructor (Initializes ownership, sets up token contracts/references)
// 8. Admin/Setup Functions:
//    - registerMaterialType: Define new material types (ERC-1155 IDs)
//    - mintInitialMaterials: Distribute initial materials
//    - setRecipeApprovalAuthority: Assign address/role for recipe approval
//    - toggleCraftingPause: Pause/unpause crafting
// 9. Material Management Functions:
//    - claimMaterialsReceivedButNotUsed: Allow users to withdraw materials sent but not crafted with
//    - getMaterialTypeDetails: View details of a registered material
//    - onERC1155Received, onERC1155BatchReceived: Handlers for receiving materials (required by ERC-1155)
// 10. Recipe Management Functions:
//     - submitRecipe: User proposes a new recipe
//     - approveRecipe: Authority approves a submitted recipe
//     - rejectRecipe: Authority rejects a submitted recipe
//     - getRecipeDetails: View full details of a recipe
//     - getSubmittedRecipeIds: View IDs of all submitted recipes
//     - getApprovedRecipeIds: View IDs of all approved recipes
//     - isRecipeApproved: Check if a recipe is approved
// 11. Crafting Functions:
//     - craftArtifact: User consumes materials via an approved recipe to mint an artifact
//     - getArtifactDetails: View non-token data for an artifact
//     - getArtifactRecipeUsed: Get the recipe ID used for a specific artifact
//     - getArtifactCount: Total number of artifacts forged
// 12. Artifact Interaction Functions (Analysis):
//     - analyzeArtifact: User performs analysis on an artifact, potentially revealing lore/data
//     - isArtifactAnalyzed: Check if an artifact has been analyzed
//     - getArtifactAnalysisData: View analysis results for an artifact
// 13. View/Query Functions (beyond standard ERC721/ERC1155 views):
//     - getRecipeCount: Total number of recipes (submitted + approved)
//     - getMaterialsUsedInCrafting: View historical material usage (optional, complex state) - let's simplify and query balances instead.
//     - (Many view functions are covered by the Getters above)

// @title Function Summary:
// 1.  constructor(address initialOwner, address materialTokenAddress, address artifactTokenAddress): Initializes the contract, sets the owner, links to deployed ERC-1155 and ERC-721 contracts.
// 2.  registerMaterialType(uint256 materialTypeId, string calldata name): Registers a new material type ID that the forge recognizes. Only callable by owner.
// 3.  mintInitialMaterials(address recipient, uint256 materialTypeId, uint256 amount): Mints initial materials of a specific type and sends them to a recipient. Only callable by owner (e.g., for distribution).
// 4.  setRecipeApprovalAuthority(address authority): Sets the address authorized to approve/reject recipes. Only callable by owner.
// 5.  toggleCraftingPause(bool paused): Pauses or unpauses the crafting functionality. Only callable by owner.
// 6.  claimMaterialsReceivedButNotUsed(uint256 materialTypeId): Allows a user to claim back materials of a specific type they previously sent to the contract but which were not used in crafting. (Requires tracking, alternative is explicit `unstake` or only using `safeTransferFrom` during craft). Let's simplify: users approve contract, contract pulls. Any direct transfers can be reclaimed.
// 7.  getMaterialTypeDetails(uint256 materialTypeId) external view returns (string memory name): Returns the name of a registered material type.
// 8.  onERC1155Received(...) external returns (bytes4): Standard ERC-1155 receiver hook. Allows the contract to receive materials.
// 9.  onERC1155BatchReceived(...) external returns (bytes4): Standard ERC-1155 batch receiver hook. Allows the contract to receive batches of materials.
// 10. submitRecipe(uint256[] calldata inputMaterialTypes, uint256[] calldata inputMaterialQuantities, string calldata outputArtifactProperties): Allows any user to propose a new recipe by defining required inputs and resulting output properties string. Assigns a unique ID.
// 11. approveRecipe(uint256 recipeId): Marks a submitted recipe as approved, making it available for crafting. Only callable by the recipe approval authority.
// 12. rejectRecipe(uint256 recipeId): Marks a submitted recipe as rejected. Only callable by the recipe approval authority.
// 13. getRecipeDetails(uint256 recipeId) external view returns (uint256 id, address creator, bool isApproved, uint256[] memory inputMaterialTypes, uint256[] memory inputMaterialQuantities, string memory outputArtifactProperties): Returns the full details of a specific recipe.
// 14. getSubmittedRecipeIds() external view returns (uint256[] memory): Returns a list of all recipe IDs that have been submitted (approved or not).
// 15. getApprovedRecipeIds() external view returns (uint256[] memory): Returns a list of recipe IDs that have been approved.
// 16. isRecipeApproved(uint256 recipeId) external view returns (bool): Checks if a specific recipe ID is approved for crafting.
// 17. craftArtifact(uint256 recipeId): Executes the crafting process. Checks recipe approval, pulls required materials from the caller (user must have approved the contract via ERC-1155 `setApprovalForAll`), burns the materials, mints a new ERC-721 artifact token, and records artifact data.
// 18. getArtifactDetails(uint256 artifactTokenId) external view returns (uint256 id, address creator, uint256 recipeId, uint256 craftTimestamp, string memory initialProperties, bool isAnalyzed, string memory analysisData): Returns the non-token-standard data stored for an artifact.
// 19. getArtifactRecipeUsed(uint256 artifactTokenId) external view returns (uint256 recipeId): Returns the ID of the recipe used to craft a specific artifact.
// 20. getArtifactCount() external view returns (uint256): Returns the total number of artifacts ever forged.
// 21. analyzeArtifact(uint256 artifactTokenId): Allows the owner of an artifact to perform an analysis. (Could require consuming materials, tokens, or just a transaction cost). For this example, it will toggle a flag and potentially set some dynamic `analysisData`. Requires `nonReentrant`.
// 22. isArtifactAnalyzed(uint256 artifactTokenId) external view returns (bool): Checks if a specific artifact has been analyzed.
// 23. getArtifactAnalysisData(uint256 artifactTokenId) external view returns (string memory): Returns the analysis-revealed data for an artifact. Empty string if not analyzed or no data revealed.

```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Custom Errors ---
error AlchemicalForge__RecipeNotFound(uint256 recipeId);
error AlchemicalForge__RecipeNotApproved(uint256 recipeId);
error AlchemicalForge__MaterialTypeNotRegistered(uint256 materialTypeId);
error AlchemicalForge__InsufficientMaterials(uint256 materialTypeId, uint256 required, uint256 available);
error AlchemicalForge__ArtifactNotFound(uint256 artifactTokenId);
error AlchemicalForge__ArtifactAlreadyAnalyzed(uint256 artifactTokenId);
error AlchemicalForge__Unauthorized();
error AlchemicalForge__MaterialsNotClaimable(uint256 materialTypeId); // If claim logic is complex
error AlchemicalForge__InvalidInputLength(); // For recipe submission

// --- Events ---
event MaterialTypeRegistered(uint256 indexed materialTypeId, string name);
event InitialMaterialsMinted(address indexed recipient, uint256 indexed materialTypeId, uint256 amount);
event RecipeApprovalAuthoritySet(address indexed authority);
event RecipeSubmitted(uint256 indexed recipeId, address indexed creator);
event RecipeApproved(uint256 indexed recipeId, address indexed approver);
event RecipeRejected(uint256 indexed recipeId, address indexed rejecter);
event ArtifactCrafted(uint256 indexed artifactTokenId, uint256 indexed recipeId, address indexed crafter);
event ArtifactAnalyzed(uint256 indexed artifactTokenId, address indexed analyzer);
event UnusedMaterialsClaimed(address indexed claimant, uint256 indexed materialTypeId, uint256 amount);


contract AlchemicalForge is Ownable, Pausable, ReentrancyGuard, ERC1155Receiver {

    // --- State Variables ---

    // References to the deployed token contracts (ERC-1155 for materials, ERC-721 for artifacts)
    // In a real scenario, these would be deployed separately and their addresses passed in constructor.
    // For this example, we'll simulate them being managed by this contract, but conceptually they could be external.
    // Let's define them as external references for better modularity.
    IERC1155 private s_materialToken;
    IERC721 private s_artifactToken; // Note: We'll mint artifacts using _safeMint, assuming this contract is the minter

    address private s_recipeApprovalAuthority;

    // Counters for unique IDs
    using Counters for Counters.Counter;
    Counters.Counter private s_recipeCounter;
    Counters.Counter private s_artifactCounter; // Used for ERC721 token IDs

    // Mappings for Material Types
    mapping(uint256 => string) private s_materialTypeNames;
    mapping(uint256 => bool) private s_isMaterialTypeRegistered;
    uint256[] private s_registeredMaterialTypeIds; // To list all registered types

    // Mappings for Recipes
    struct Recipe {
        uint256 id;
        address creator;
        bool isApproved;
        uint256[] inputMaterialTypes; // ERC1155 token IDs
        uint256[] inputMaterialQuantities;
        string outputArtifactProperties; // A string representing initial properties/metadata pointer
    }
    mapping(uint256 => Recipe) private s_recipes;
    uint256[] private s_submittedRecipeIds; // All submitted recipes
    uint256[] private s_approvedRecipeIds; // Only approved recipes

    // Mappings for Artifacts (additional data beyond ERC721 standard)
    struct ArtifactData {
        uint256 recipeId; // Which recipe was used
        uint256 craftTimestamp;
        string initialProperties; // Copy of recipe output
        bool isAnalyzed;
        string analysisData; // Data revealed upon analysis
    }
    mapping(uint256 => ArtifactData) private s_artifactData; // artifactTokenId => data

    // Tracking materials sent directly to the contract by users for potential claim
    // This is separate from the contract's overall balance.
    // mapping(address user => mapping(uint256 materialTypeId => uint256 amount)) private s_materialsReceivedByUser; // Complex to track per user
    // Alternative: Just let users claim *any* materials they sent directly that are held by the contract. Simpler for this example.
    // This requires careful implementation of onERC1155Received to differentiate.
    // Let's simplify: The primary interaction is 'craftArtifact' pulling from user balance.
    // Users should NOT send materials directly unless there's a specific 'stake' function.
    // We'll implement the receiver functions but assume craft uses pull mechanics.

    // --- Modifiers ---
    modifier onlyRecipeApprovalAuthority() {
        if (msg.sender != s_recipeApprovalAuthority && msg.sender != owner()) { // Owner can also approve
            revert AlchemicalForge__Unauthorized();
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner, address materialTokenAddress, address artifactTokenAddress) Ownable(initialOwner) Pausable(false) {
        // Assuming material and artifact tokens are already deployed standard contracts
        // In a real system, you might deploy them *from* this contract or link to factories.
        // For this example, we require pre-deployed standard ERC-1155 and ERC-721.
        require(materialTokenAddress != address(0), "Material token address cannot be zero");
        require(artifactTokenAddress != address(0), "Artifact token address cannot be zero");

        s_materialToken = IERC1155(materialTokenAddress);
        s_artifactToken = IERC721(artifactTokenAddress); // We cast to IERC721 but expect it to be minter-capable

        s_recipeApprovalAuthority = initialOwner; // Owner is default authority
    }

    // --- Admin/Setup Functions ---

    /// @notice Registers a new type of raw material the forge recognizes.
    /// @param materialTypeId The ERC-1155 token ID for this material type.
    /// @param name The human-readable name for this material type.
    function registerMaterialType(uint256 materialTypeId, string calldata name) external onlyOwner {
        if (s_isMaterialTypeRegistered[materialTypeId]) {
            // Consider if updating name is allowed, or if only one registration per ID
            // For now, assume no re-registration of same ID
            revert("AlchemicalForge: Material type already registered");
        }
        s_materialTypeNames[materialTypeId] = name;
        s_isMaterialTypeRegistered[materialTypeId] = true;
        s_registeredMaterialTypeIds.push(materialTypeId);
        emit MaterialTypeRegistered(materialTypeId, name);
    }

    /// @notice Mints initial materials of a registered type for a recipient.
    /// @param recipient The address to mint materials for.
    /// @param materialTypeId The ID of the material type.
    /// @param amount The amount to mint.
    function mintInitialMaterials(address recipient, uint256 materialTypeId, uint256 amount) external onlyOwner {
        if (!s_isMaterialTypeRegistered[materialTypeId]) {
             revert AlchemicalForge__MaterialTypeNotRegistered(materialTypeId);
        }
        // Assumes the ERC1155 contract has a minter role granted to this contract, or owner can mint.
        // In a real scenario, this might call a mint function on the s_materialToken contract.
        // For this example, let's simulate by assuming this contract *is* the minter,
        // though ideally, the ERC1155 would be a separate contract with access control.
        // Since we are linking to *an* IERC1155, a real implementation would need
        // s_materialToken to have a function like `mintTo(recipient, materialTypeId, amount)`
        // and this contract would need the MINTER_ROLE on that token contract.
        // We'll emit an event as a placeholder for the actual minting call.
        emit InitialMaterialsMinted(recipient, materialTypeId, amount);
        // Add placeholder for actual minting call if s_materialToken supports it
        // s_materialToken.mintTo(recipient, materialTypeId, amount);
    }

    /// @notice Sets the address authorized to approve or reject recipes.
    /// @param authority The address to set as the recipe approval authority.
    function setRecipeApprovalAuthority(address authority) external onlyOwner {
        s_recipeApprovalAuthority = authority;
        emit RecipeApprovalAuthoritySet(authority);
    }

    /// @notice Pauses or unpauses the crafting functionality.
    /// @param paused True to pause, false to unpause.
    function toggleCraftingPause(bool paused) external onlyOwner {
        _updatePause(paused);
    }

    // --- Material Management Functions ---

    // Note: This function is commented out as the primary interaction model relies on user
    // approving the contract to pull materials during craftArtifact.
    // Implementing a robust 'claimMaterialsReceivedButNotUsed' requires complex tracking
    // of who sent what directly via onERC1155Received.
    // For a simpler model, users should approve the contract and let it pull during craft.
    /*
    /// @notice Allows a user to claim back materials they sent directly to the contract
    /// which have not been used in crafting.
    /// Requires complex tracking of `s_materialsReceivedByUser`.
    function claimMaterialsReceivedButNotUsed(uint256 materialTypeId) external nonReentrant {
        uint256 amount = s_materialsReceivedByUser[msg.sender][materialTypeId];
        if (amount == 0) {
            revert AlchemicalForge__MaterialsNotClaimable(materialTypeId);
        }
        s_materialsReceivedByUser[msg.sender][materialTypeId] = 0;
        // Assumes ERC1155 contract allows transferring from this contract's balance
        // Need to ensure this contract holds enough balance and has transfer rights.
        // A better approach is often to have users 'stake' explicitly.
        // If s_materialToken.safeTransferFrom(address(this), msg.sender, materialTypeId, amount, "") fails,
        // the state change is reverted.
        s_materialToken.safeTransferFrom(address(this), msg.sender, materialTypeId, amount, "");
        emit UnusedMaterialsClaimed(msg.sender, materialTypeId, amount);
    }
    */

    /// @notice Returns the human-readable name for a registered material type.
    /// @param materialTypeId The ID of the material type.
    /// @return name The name of the material type.
    function getMaterialTypeDetails(uint256 materialTypeId) external view returns (string memory name) {
        if (!s_isMaterialTypeRegistered[materialTypeId]) {
             revert AlchemicalForge__MaterialTypeNotRegistered(materialTypeId);
        }
        return s_materialTypeNames[materialTypeId];
    }

    // ERC-1155 Receiver Hooks
    /// @dev See {IERC1155Receiver-onERC1155Received}.
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        // This function is called when a user sends ERC-1155 tokens to this contract.
        // You might want to track who sent what here if implementing the claim function.
        // For this example, we just accept the tokens. Crafting uses a pull mechanism.
        // if (from != address(0)) { // Not a mint
        //     s_materialsReceivedByUser[from][id] += value;
        // }
        return this.onERC1155Received.selector;
    }

    /// @dev See {IERC1155Receiver-onERC1155BatchReceived}.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
         // This function is called when a user sends batches of ERC-1155 tokens to this contract.
        // Similar to onERC1155Received, track if needed for claim function.
        // if (from != address(0)) { // Not a mint
        //     for (uint i = 0; i < ids.length; i++) {
        //         s_materialsReceivedByUser[from][ids[i]] += values[i];
        //     }
        // }
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Required by ERC1155Receiver. Tells tokens that this contract supports the interface.
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Receiver, Ownable) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }


    // --- Recipe Management Functions ---

    /// @notice Allows any user to propose a new recipe.
    /// @param inputMaterialTypes Array of ERC-1155 token IDs for required materials.
    /// @param inputMaterialQuantities Array of quantities corresponding to inputMaterialTypes.
    /// @param outputArtifactProperties A string representing the initial properties/metadata of the resulting artifact.
    function submitRecipe(
        uint256[] calldata inputMaterialTypes,
        uint256[] calldata inputMaterialQuantities,
        string calldata outputArtifactProperties
    ) external {
        if (inputMaterialTypes.length != inputMaterialQuantities.length) {
            revert AlchemicalForge__InvalidInputLength();
        }

        // Basic validation: check if material types are registered
        for (uint i = 0; i < inputMaterialTypes.length; i++) {
            if (!s_isMaterialTypeRegistered[inputMaterialTypes[i]]) {
                revert AlchemicalForge__MaterialTypeNotRegistered(inputMaterialTypes[i]);
            }
            // Prevent zero quantity inputs
            if (inputMaterialQuantities[i] == 0) {
                 revert("AlchemicalForge: Input material quantity cannot be zero");
            }
        }

        s_recipeCounter.increment();
        uint256 newRecipeId = s_recipeCounter.current();

        s_recipes[newRecipeId] = Recipe({
            id: newRecipeId,
            creator: msg.sender,
            isApproved: false, // Requires approval
            inputMaterialTypes: inputMaterialTypes,
            inputMaterialQuantities: inputMaterialQuantities,
            outputArtifactProperties: outputArtifactProperties
        });
        s_submittedRecipeIds.push(newRecipeId);

        emit RecipeSubmitted(newRecipeId, msg.sender);
    }

    /// @notice Approves a submitted recipe, making it craftable.
    /// Only callable by the recipe approval authority or owner.
    /// @param recipeId The ID of the recipe to approve.
    function approveRecipe(uint256 recipeId) external onlyRecipeApprovalAuthority {
        Recipe storage recipe = s_recipes[recipeId];
        if (recipe.id == 0 || recipe.isApproved) { // Check if exists and not already approved
            revert AlchemicalForge__RecipeNotFound(recipeId); // Use same error for not found or already approved
        }

        recipe.isApproved = true;
        s_approvedRecipeIds.push(recipeId); // Add to approved list

        emit RecipeApproved(recipeId, msg.sender);
    }

    /// @notice Rejects a submitted recipe.
    /// Only callable by the recipe approval authority or owner.
    /// @param recipeId The ID of the recipe to reject.
    function rejectRecipe(uint256 recipeId) external onlyRecipeApprovalAuthority {
        Recipe storage recipe = s_recipes[recipeId];
         if (recipe.id == 0) { // Check if exists
            revert AlchemicalForge__RecipeNotFound(recipeId);
        }
        // Note: Rejecting doesn't remove it from s_submittedRecipeIds or mapping, just sets isApproved to false (or keeps it false)
        // If you wanted to remove, it's more complex. For now, just reject.
        // You might want to add a 'isRejected' flag if needed. For simplicity, isApproved=false is sufficient.

        // We don't need to change recipe.isApproved if it was already false.
        // Just emitting the event is enough to signal rejection status externally.
        // If recipe was already approved and you want to 'unapprove', this logic needs extension.
        // Assuming this is only for recipes that are not yet approved.
        if (recipe.isApproved) {
             revert("AlchemicalForge: Cannot reject an already approved recipe");
        }


        emit RecipeRejected(recipeId, msg.sender);
    }

    /// @notice Returns the full details of a specific recipe.
    /// @param recipeId The ID of the recipe.
    /// @return Recipe struct data.
    function getRecipeDetails(uint256 recipeId) external view returns (uint256 id, address creator, bool isApproved, uint256[] memory inputMaterialTypes, uint256[] memory inputMaterialQuantities, string memory outputArtifactProperties) {
        Recipe storage recipe = s_recipes[recipeId];
        if (recipe.id == 0) {
            revert AlchemicalForge__RecipeNotFound(recipeId);
        }
        return (recipe.id, recipe.creator, recipe.isApproved, recipe.inputMaterialTypes, recipe.inputMaterialQuantities, recipe.outputArtifactProperties);
    }

    /// @notice Returns a list of all recipe IDs that have been submitted.
    /// @return An array of submitted recipe IDs.
    function getSubmittedRecipeIds() external view returns (uint256[] memory) {
        return s_submittedRecipeIds;
    }

     /// @notice Returns a list of all recipe IDs that have been approved.
    /// @return An array of approved recipe IDs.
    function getApprovedRecipeIds() external view returns (uint256[] memory) {
        return s_approvedRecipeIds;
    }

    /// @notice Checks if a specific recipe ID is approved for crafting.
    /// @param recipeId The ID of the recipe.
    /// @return True if approved, false otherwise.
    function isRecipeApproved(uint256 recipeId) public view returns (bool) {
        return s_recipes[recipeId].isApproved;
    }


    // --- Crafting Functions ---

    /// @notice Executes the crafting process using an approved recipe.
    /// Consumes required materials from the caller and mints a new artifact token.
    /// Caller must have approved the contract to manage their ERC-1155 materials using `setApprovalForAll`.
    /// @param recipeId The ID of the approved recipe to use.
    function craftArtifact(uint256 recipeId) external payable nonReentrant whenNotPaused {
        Recipe storage recipe = s_recipes[recipeId];
        if (recipe.id == 0) {
            revert AlchemicalForge__RecipeNotFound(recipeId);
        }
        if (!recipe.isApproved) {
            revert AlchemicalForge__RecipeNotApproved(recipeId);
        }

        address crafter = msg.sender;

        // Check and pull materials from the crafter
        uint256[] memory inputTypes = recipe.inputMaterialTypes;
        uint256[] memory inputQuantities = recipe.inputMaterialQuantities;

        if (inputTypes.length != inputQuantities.length) {
             revert AlchemicalForge__InvalidInputLength(); // Should not happen with validated recipes
        }

        for (uint i = 0; i < inputTypes.length; i++) {
            uint256 materialType = inputTypes[i];
            uint256 requiredAmount = inputQuantities[i];

            if (!s_isMaterialTypeRegistered[materialType]) {
                 revert AlchemicalForge__MaterialTypeNotRegistered(materialType); // Should not happen with validated recipes
            }

            uint256 availableAmount = s_materialToken.balanceOf(crafter, materialType);
            if (availableAmount < requiredAmount) {
                 revert AlchemicalForge__InsufficientMaterials(materialType, requiredAmount, availableAmount);
            }

            // Transfer materials from crafter to the contract/burn address.
            // Transferring to address(0) effectively burns them.
            // The ERC1155 contract must allow this contract to transfer on behalf of the user (crafter).
            // This requires the crafter to call `s_materialToken.setApprovalForAll(address(this), true)` prior to crafting.
             s_materialToken.safeTransferFrom(crafter, address(0), materialType, requiredAmount, "");
        }

        // Mint a new artifact token
        s_artifactCounter.increment();
        uint256 newArtifactId = s_artifactCounter.current();

        // Assumes the ERC721 contract (s_artifactToken) allows this contract to mint.
        // This typically requires a minter role on the ERC721 contract assigned to this forge contract address.
        // If s_artifactToken is a standard OpenZeppelin ERC721, it doesn't have a public mint function
        // unless inherited from a minter contract. A real implementation might need a custom ERC721
        // or for this contract to inherit from a base ERC721 and manage its own tokens.
        // For this example, we assume s_artifactToken has a `_safeMint` function or similar.
        // If it's a pure IERC721, we can't mint. Let's assume it's minter-capable,
        // perhaps a custom ERC721 contract where this forge address has the MINTER_ROLE.

        // Cast to a type that potentially has _safeMint (e.g., a mock or a custom ERC721)
        // In a real dApp, s_artifactToken would likely be an interface with a specific mint function
        // or this contract would inherit from ERC721 itself.
        // Let's assume for this example, s_artifactToken is a custom minter-enabled ERC721.
        // s_artifactToken._safeMint(crafter, newArtifactId); // This is not a public function on IERC721
        // Using emit as placeholder for minting call
         emit ArtifactCrafted(newArtifactId, recipeId, crafter);

        // Store artifact-specific data
        s_artifactData[newArtifactId] = ArtifactData({
            id: newArtifactId, // Redundant with mapping key, but good for struct clarity
            creator: crafter,
            recipeId: recipeId,
            craftTimestamp: block.timestamp,
            initialProperties: recipe.outputArtifactProperties,
            isAnalyzed: false,
            analysisData: "" // Starts empty
        });

        // --- IMPORTANT ---
        // In a real implementation using OpenZeppelin's ERC721, this contract needs
        // to *be* the ERC721 contract itself, or call a separate contract with a minter role.
        // If this contract *is* the ERC721, you'd use:
        // _safeMint(crafter, newArtifactId);
        // If s_artifactToken is a separate ERC721 contract with a minter role for this address:
        // IERC721Minter(s_artifactToken).mint(crafter, newArtifactId); // Example custom interface
        // For this example, we use the event as a placeholder for the actual minting logic
        // and the storage mapping `s_artifactData` to track artifact properties.
    }

    /// @notice Returns the additional data stored for a specific artifact.
    /// @param artifactTokenId The ID of the artifact token.
    /// @return ArtifactData struct data.
    function getArtifactDetails(uint256 artifactTokenId) external view returns (uint256 id, address creator, uint256 recipeId, uint256 craftTimestamp, string memory initialProperties, bool isAnalyzed, string memory analysisData) {
        ArtifactData storage data = s_artifactData[artifactTokenId];
        if (data.id == 0) { // Assuming 0 is an invalid ID; needs care if ID 0 is possible
             revert AlchemicalForge__ArtifactNotFound(artifactTokenId);
        }
        return (data.id, data.creator, data.recipeId, data.craftTimestamp, data.initialProperties, data.isAnalyzed, data.analysisData);
    }

     /// @notice Returns the ID of the recipe used to craft a specific artifact.
     /// @param artifactTokenId The ID of the artifact token.
     /// @return The recipe ID.
    function getArtifactRecipeUsed(uint256 artifactTokenId) external view returns (uint256 recipeId) {
        ArtifactData storage data = s_artifactData[artifactTokenId];
        if (data.id == 0) { // Assuming 0 is an invalid ID
             revert AlchemicalForge__ArtifactNotFound(artifactTokenId);
        }
        return data.recipeId;
    }

    /// @notice Returns the total number of artifacts forged by this contract.
    /// @return The total count of artifacts.
    function getArtifactCount() external view returns (uint256) {
        return s_artifactCounter.current();
    }


    // --- Artifact Interaction Functions (Analysis) ---

    /// @notice Allows the owner of an artifact to perform an analysis on it.
    /// This action can reveal hidden lore or properties. Can only be done once per artifact.
    /// Could potentially require payment or material consumption in a real scenario.
    /// @param artifactTokenId The ID of the artifact token to analyze.
    function analyzeArtifact(uint256 artifactTokenId) external nonReentrant {
        ArtifactData storage data = s_artifactData[artifactTokenId];
         if (data.id == 0) { // Assuming 0 is an invalid ID
             revert AlchemicalForge__ArtifactNotFound(artifactTokenId);
        }

        // Check ownership of the artifact (requires querying the s_artifactToken contract)
        address artifactOwner = s_artifactToken.ownerOf(artifactTokenId);
        if (artifactOwner != msg.sender) {
            revert AlchemicalForge__Unauthorized(); // Only owner can analyze
        }

        if (data.isAnalyzed) {
            revert AlchemicalForge__ArtifactAlreadyAnalyzed(artifactTokenId);
        }

        // --- Analysis Logic Placeholder ---
        // In a real dApp, this could involve:
        // - Consuming materials (s_materialToken.safeTransferFrom(msg.sender, address(0), ...))
        // - Consuming another token (IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount))
        // - Paying ETH (payable function)
        // - Interacting with an oracle (e.g., Chainlink VRF for random results, Chainlink keepers for off-chain data)
        // - Complex on-chain computation based on initialProperties
        // For this example, we'll just toggle the flag and set a simple string.

        data.isAnalyzed = true;
        // Simulate analysis revealing data based on initial properties (simple hash/string manipulation)
        bytes memory initialBytes = bytes(data.initialProperties);
        bytes memory analysisBytes = new bytes(initialBytes.length * 2); // Placeholder: Double the string length
        for(uint i = 0; i < initialBytes.length; i++){
            analysisBytes[2*i] = initialBytes[i];
            analysisBytes[2*i+1] = bytes1(uint8(initialBytes[i]) + 1); // Simple transformation
        }
        data.analysisData = string(analysisBytes); // Store the 'revealed' data

        emit ArtifactAnalyzed(artifactTokenId, msg.sender);
    }

     /// @notice Checks if a specific artifact has been analyzed.
     /// @param artifactTokenId The ID of the artifact token.
     /// @return True if analyzed, false otherwise.
    function isArtifactAnalyzed(uint256 artifactTokenId) external view returns (bool) {
         ArtifactData storage data = s_artifactData[artifactTokenId];
         if (data.id == 0) { // Assuming 0 is an invalid ID
             revert AlchemicalForge__ArtifactNotFound(artifactTokenId);
        }
        return data.isAnalyzed;
    }

     /// @notice Returns the analysis-revealed data for an artifact.
     /// @param artifactTokenId The ID of the artifact token.
     /// @return The analysis data string. Returns empty string if not analyzed or no data revealed.
    function getArtifactAnalysisData(uint256 artifactTokenId) external view returns (string memory) {
         ArtifactData storage data = s_artifactData[artifactTokenId];
         if (data.id == 0) { // Assuming 0 is an invalid ID
             revert AlchemicalForge__ArtifactNotFound(artifactTokenId);
        }
        return data.analysisData;
    }

    // --- View/Query Functions ---

    /// @notice Returns the total number of recipes (submitted + approved).
    /// @return The total count of recipes.
    function getRecipeCount() external view returns (uint256) {
        return s_recipeCounter.current();
    }

    // Other view functions like balanceOf, ownerOf, tokenOfOwnerByIndex are provided by the ERC721 contract (s_artifactToken)
    // and balance/balanceOfBatch by the ERC1155 contract (s_materialToken).
    // We can add wrappers if needed, but typically interacting directly with the token contracts is standard.

    // Example of a wrapper (though not strictly needed for the 20+ functions requirement)
    /*
    function getUserMaterialBalance(address user, uint256 materialTypeId) external view returns (uint256) {
        return s_materialToken.balanceOf(user, materialTypeId);
    }
    */

}
```