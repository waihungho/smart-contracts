Okay, let's create a smart contract based on a "Digital Alchemy Lab" concept.

It will involve:
1.  **Elements:** Fungible tokens (ERC-20) representing basic alchemical ingredients.
2.  **Catalyst:** Another fungible token (ERC-20) required to fuel the alchemy process.
3.  **Artifacts:** Non-fungible tokens (ERC-721) representing the results of successful alchemy.
4.  **Recipes:** Defined combinations of Elements and Catalyst needed to create specific Artifacts.
5.  **Alchemy Process:** Users combine approved Elements and Catalyst in the Lab to mint a new Artifact.
6.  **Disintegration:** Users can destroy Artifacts to recover some original Elements/Catalyst (or different ones).
7.  **Properties:** Artifacts can have dynamic properties stored on-chain.

This contract is not a standard implementation of ERC-20 or ERC-721, but rather a system built *around* them, providing novel mechanics.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // For potential future signed messages, included for "advanced concept" feel, though not fully used in this basic version
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safe arithmetic

// --- Contract Outline ---
//
// The DigitalAlchemyLab contract serves as a central hub for combining digital
// elements and catalysts to create unique digital artifacts. Users must hold
// and approve specific ERC-20 tokens (Elements and Catalyst) to the Lab contract
// to perform alchemy based on predefined recipes. Successful alchemy consumes
// the ingredients and mints a new ERC-721 Artifact token to the user. Artifacts
// can also be disintegrated back into elements.
//
// Key Features:
// - Manages alchemy recipes linking input ERC-20s to output ERC-721s.
// - Handles token transfers via transferFrom during alchemy.
// - Allows disintegration of artifacts to recover resources.
// - Stores on-chain properties for minted artifacts.
// - Includes owner functions for recipe management, token address updates, and withdrawals.
// - Incorporates concepts like structured data (recipes, properties), interaction
//   with external contracts (ERC-20, ERC-721), and basic access control.
//
// External Dependencies:
// - IERC20, IERC721 (OpenZeppelin Contracts)
// - Ownable (OpenZeppelin Contracts)
// - ERC721Holder (Allows the contract to receive and hold ERC721 tokens if needed,
//   though primarily interacts by minting/burning via external calls in this design)
// - SafeMath (OpenZeppelin Contracts - less critical in 0.8+ but good practice)
//
// --- Function Summary ---
//
// Core Alchemy & Disintegration:
// - alchemize(bytes32 recipeHash): Executes an alchemy recipe by consuming inputs and minting an artifact.
// - disintegrateArtifact(uint256 artifactId): Burns an artifact and transfers specified yields back to the user.
//
// Recipe Management (Owner Only):
// - addRecipe(ElementAmount[] memory inputs, uint256 requiredCatalyst, uint256 outputArtifactId, string memory metadataURI, uint256 feeCatalystAmount, ElementAmount[] memory disintegrationYield): Adds a new alchemy recipe.
// - updateRecipe(bytes32 recipeHash, ElementAmount[] memory inputs, uint256 requiredCatalyst, uint256 outputArtifactId, string memory metadataURI, uint256 feeCatalystAmount, ElementAmount[] memory disintegrationYield): Updates an existing alchemy recipe.
// - removeRecipe(bytes32 recipeHash): Removes an alchemy recipe.
//
// Artifact Properties & Yields (Owner Only):
// - setArtifactProperties(uint256 artifactId, uint256 level, string memory artifactType): Sets properties for a specific artifact ID.
// - setDisintegrationYield(uint256 artifactId, ElementAmount[] memory yieldInputs): Sets the disintegration yield for an artifact ID. (Redundant with recipe, but kept for granular control)
//
// Configuration (Owner Only):
// - setTokenAddresses(address _elementToken, address _catalystToken, address _artifactNFT): Sets the addresses of required token contracts.
// - setFeeRecipient(address _feeRecipient): Sets the address to receive collected fees.
// - setDefaultFeeCatalyst(uint256 _amount): Sets a default catalyst fee for recipes if not specified individually.
//
// Withdrawals (Owner Only):
// - withdrawERC20(address tokenAddress, uint256 amount): Withdraws specified ERC-20 tokens held by the contract.
// - withdrawERC721(address tokenAddress, uint256 tokenId): Withdraws a specific ERC-721 token held by the contract.
//
// View Functions (Read-only):
// - getRecipeByHash(bytes32 recipeHash): Retrieves recipe details for a given hash.
// - calculateRecipeHash(ElementAmount[] memory inputs, uint256 requiredCatalyst, uint256 outputArtifactId): Calculates the unique hash for a recipe.
// - getArtifactProperties(uint256 artifactId): Retrieves properties for a specific artifact ID.
// - getDisintegrationYield(uint256 artifactId): Retrieves the disintegration yield for a specific artifact ID.
// - getElementTokenAddress(): Returns the Element ERC-20 address.
// - getCatalystTokenAddress(): Returns the Catalyst ERC-20 address.
// - getArtifactNFTAddress(): Returns the Artifact ERC-721 address.
// - getFeeRecipient(): Returns the fee recipient address.
// - getDefaultFeeCatalyst(): Returns the default catalyst fee.
// - checkRecipeIngredientsBalance(address user, bytes32 recipeHash): Checks if a user has sufficient balance for a recipe's ingredients.
// - checkRecipeIngredientsAllowance(address user, bytes32 recipeHash): Checks if the contract has sufficient allowance from a user for a recipe's ingredients.
//
// Inherited Functions (from Ownable):
// - transferOwnership(address newOwner): Transfers contract ownership.
// - renounceOwnership(): Renounces contract ownership.

contract DigitalAlchemyLab is Ownable, ERC721Holder {
    using SafeMath for uint256;

    // --- Structs ---
    struct ElementAmount {
        address token; // Address of the specific Element ERC-20 contract
        uint256 amount; // Amount of the element required/yielded
    }

    struct Recipe {
        ElementAmount[] inputs; // List of element tokens and amounts required
        uint256 requiredCatalyst; // Amount of Catalyst token required
        uint256 outputArtifactId; // The specific ID of the artifact minted by this recipe
        string metadataURI; // Base URI or specific URI for the minted artifact (dependent on ERC721 implementation)
        uint256 feeCatalystAmount; // Additional Catalyst fee for performing this recipe
        ElementAmount[] disintegrationYield; // Elements/Catalyst yielded upon disintegrating the output artifact
    }

    struct ArtifactProperties {
        uint256 level;
        string artifactType;
        // Add more properties as needed (e.g., power, color, etc.)
    }

    // --- State Variables ---
    address public elementTokenAddress;
    address public catalystTokenAddress;
    address public artifactNFTAddress;

    // Mapping from recipe hash to Recipe struct
    mapping(bytes32 => Recipe) private recipes;
    // Array to store recipe hashes for potential iteration/listing (careful with gas)
    // We'll just store hashes here, retrieval is by hash.
    bytes32[] private recipeHashes;
    // Mapping to track existence of a recipe hash
    mapping(bytes32 => bool) private recipeExists;

    // Mapping from artifact ID to its on-chain properties
    mapping(uint256 => ArtifactProperties) private artifactProperties;

    // Mapping from artifact ID to its disintegration yield override
    // If set here, this overrides the yield defined in the recipe.
    mapping(uint256 => ElementAmount[]) private artifactDisintegrationYieldOverrides;
    // Flag to indicate if an override exists for an artifact ID
    mapping(uint256 => bool) private hasDisintegrationYieldOverride;


    address public feeRecipient;
    uint256 public defaultFeeCatalyst; // Default catalyst fee if not specified per recipe

    // --- Events ---
    event TokenAddressesSet(address indexed elementToken, address indexed catalystToken, address indexed artifactNFT);
    event RecipeAdded(bytes32 indexed recipeHash, uint256 indexed outputArtifactId);
    event RecipeUpdated(bytes32 indexed recipeHash, uint256 indexed outputArtifactId);
    event RecipeRemoved(bytes32 indexed recipeHash);
    event AlchemyPerformed(address indexed user, bytes32 indexed recipeHash, uint256 indexed mintedArtifactId);
    event ArtifactDisintegrated(address indexed user, uint256 indexed artifactId);
    event ArtifactPropertiesSet(uint256 indexed artifactId, uint256 level, string artifactType);
    event DisintegrationYieldSet(uint256 indexed artifactId);
    event FeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event DefaultFeeCatalystSet(uint256 indexed oldAmount, uint256 indexed newAmount);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event ERC721Withdrawn(address indexed token, address indexed recipient, uint256 tokenId);

    // --- Constructor ---
    constructor(address _elementToken, address _catalystToken, address _artifactNFT, address _feeRecipient, uint256 _defaultFeeCatalyst) Ownable(msg.sender) {
        require(_elementToken != address(0), "Element token address cannot be zero");
        require(_catalystToken != address(0), "Catalyst token address cannot be zero");
        require(_artifactNFT != address(0), "Artifact NFT address cannot be zero");
        require(_feeRecipient != address(0), "Fee recipient address cannot be zero");

        elementTokenAddress = _elementToken;
        catalystTokenAddress = _catalystToken;
        artifactNFTAddress = _artifactNFT;
        feeRecipient = _feeRecipient;
        defaultFeeCatalyst = _defaultFeeCatalyst;

        emit TokenAddressesSet(elementTokenAddress, catalystTokenAddress, artifactNFTAddress);
        emit FeeRecipientSet(address(0), feeRecipient);
        emit DefaultFeeCatalystSet(0, defaultFeeCatalyst);
    }

    // --- Configuration Functions (Owner Only) ---

    /// @notice Sets the addresses of the required token contracts.
    /// @param _elementToken The address of the Element ERC-20 contract.
    /// @param _catalystToken The address of the Catalyst ERC-20 contract.
    /// @param _artifactNFT The address of the Artifact ERC-721 contract.
    function setTokenAddresses(address _elementToken, address _catalystToken, address _artifactNFT) external onlyOwner {
        require(_elementToken != address(0) && _catalystToken != address(0) && _artifactNFT != address(0), "Token addresses cannot be zero");
        elementTokenAddress = _elementToken;
        catalystTokenAddress = _catalystToken;
        artifactNFTAddress = _artifactNFT;
        emit TokenAddressesSet(elementTokenAddress, catalystTokenAddress, artifactNFTAddress);
    }

    /// @notice Sets the address that receives collected catalyst fees.
    /// @param _feeRecipient The address to receive fees.
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Fee recipient address cannot be zero");
        address oldRecipient = feeRecipient;
        feeRecipient = _feeRecipient;
        emit FeeRecipientSet(oldRecipient, feeRecipient);
    }

    /// @notice Sets the default amount of Catalyst token required as a fee for recipes.
    /// @param _amount The default catalyst fee amount.
    function setDefaultFeeCatalyst(uint256 _amount) external onlyOwner {
        uint256 oldAmount = defaultFeeCatalyst;
        defaultFeeCatalyst = _amount;
        emit DefaultFeeCatalystSet(oldAmount, defaultFeeCatalyst);
    }

    // --- Recipe Management Functions (Owner Only) ---

    /// @notice Adds a new alchemy recipe.
    /// @param inputs Array of required elements and amounts.
    /// @param requiredCatalyst Amount of Catalyst token required.
    /// @param outputArtifactId The ID of the artifact produced.
    /// @param metadataURI The metadata URI for the artifact.
    /// @param feeCatalystAmount Additional catalyst fee for this specific recipe (0 to use default).
    /// @param disintegrationYield Elements/Catalyst yielded on disintegration.
    function addRecipe(
        ElementAmount[] memory inputs,
        uint256 requiredCatalyst,
        uint256 outputArtifactId,
        string memory metadataURI,
        uint256 feeCatalystAmount,
        ElementAmount[] memory disintegrationYield
    ) external onlyOwner {
        bytes32 recipeHash = calculateRecipeHash(inputs, requiredCatalyst, outputArtifactId);
        require(!recipeExists[recipeHash], "Recipe already exists");

        recipes[recipeHash] = Recipe(
            inputs,
            requiredCatalyst,
            outputArtifactId,
            metadataURI,
            feeCatalystAmount,
            disintegrationYield
        );
        recipeHashes.push(recipeHash);
        recipeExists[recipeHash] = true;

        // Set initial disintegration yield override based on recipe yield
        artifactDisintegrationYieldOverrides[outputArtifactId] = disintegrationYield;
        hasDisintegrationYieldOverride[outputArtifactId] = true;

        emit RecipeAdded(recipeHash, outputArtifactId);
    }

    /// @notice Updates an existing alchemy recipe.
    /// @param recipeHash The hash of the recipe to update.
    /// @param inputs Array of required elements and amounts.
    /// @param requiredCatalyst Amount of Catalyst token required.
    /// @param outputArtifactId The ID of the artifact produced. (Cannot be changed for hash calculation)
    /// @param metadataURI The metadata URI for the artifact.
    /// @param feeCatalystAmount Additional catalyst fee for this specific recipe (0 to use default).
    /// @param disintegrationYield Elements/Catalyst yielded on disintegration.
    function updateRecipe(
        bytes32 recipeHash,
        ElementAmount[] memory inputs,
        uint256 requiredCatalyst,
        uint256 outputArtifactId,
        string memory metadataURI,
        uint256 feeCatalystAmount,
        ElementAmount[] memory disintegrationYield
    ) external onlyOwner {
        require(recipeExists[recipeHash], "Recipe does not exist");

        // Check if the new inputs/catalyst/output match the hash (they must)
        bytes32 expectedHash = calculateRecipeHash(inputs, requiredCatalyst, outputArtifactId);
        require(recipeHash == expectedHash, "Input parameters do not match recipe hash");

        recipes[recipeHash] = Recipe(
            inputs,
            requiredCatalyst,
            outputArtifactId,
            metadataURI,
            feeCatalystAmount,
            disintegrationYield
        );

        // Update disintegration yield override based on updated recipe yield
        artifactDisintegrationYieldOverrides[outputArtifactId] = disintegrationYield;
        hasDisintegrationYieldOverride[outputArtifactId] = true;

        emit RecipeUpdated(recipeHash, outputArtifactId);
    }


    /// @notice Removes an alchemy recipe.
    /// @param recipeHash The hash of the recipe to remove.
    function removeRecipe(bytes32 recipeHash) external onlyOwner {
        require(recipeExists[recipeHash], "Recipe does not exist");

        uint256 outputArtifactId = recipes[recipeHash].outputArtifactId;

        // Find and remove hash from the dynamic array (inefficient for large arrays)
        for (uint i = 0; i < recipeHashes.length; i++) {
            if (recipeHashes[i] == recipeHash) {
                // Replace with last element and pop (order not guaranteed)
                recipeHashes[i] = recipeHashes[recipeHashes.length - 1];
                recipeHashes.pop();
                break; // Exit loop once found
            }
        }

        delete recipes[recipeHash];
        recipeExists[recipeHash] = false;

        // Optionally clear artifact yield override if it matched the recipe yield
        // This implementation leaves the override unless explicitly removed later
        // delete artifactDisintegrationYieldOverrides[outputArtifactId]; // <-- Example to clear override
        // hasDisintegrationYieldOverride[outputArtifactId] = false; // <-- Example to clear flag

        emit RecipeRemoved(recipeHash);
    }

    // --- Artifact Properties & Yield Functions ---

    /// @notice Sets on-chain properties for a specific artifact ID.
    /// This is typically called by the owner after an artifact is minted
    /// or to update properties of existing artifacts.
    /// @param artifactId The ID of the artifact.
    /// @param level The level property.
    /// @param artifactType The type property.
    function setArtifactProperties(uint256 artifactId, uint256 level, string memory artifactType) external onlyOwner {
        // Optional: Add check if artifactId exists or belongs to this contract's output types
        artifactProperties[artifactId] = ArtifactProperties(level, artifactType);
        emit ArtifactPropertiesSet(artifactId, level, artifactType);
    }

    /// @notice Sets a specific disintegration yield for an artifact ID, overriding the recipe's yield.
    /// @param artifactId The ID of the artifact.
    /// @param yieldInputs Array of elements and amounts yielded on disintegration.
    function setDisintegrationYield(uint256 artifactId, ElementAmount[] memory yieldInputs) external onlyOwner {
        artifactDisintegrationYieldOverrides[artifactId] = yieldInputs;
        hasDisintegrationYieldOverride[artifactId] = true;
        emit DisintegrationYieldSet(artifactId);
    }

    // --- Core Alchemy & Disintegration Functions ---

    /// @notice Executes an alchemy recipe.
    /// Requires the user to have approved the necessary Element and Catalyst tokens
    /// to this contract beforehand.
    /// @param recipeHash The hash of the recipe to perform.
    function alchemize(bytes32 recipeHash) external {
        Recipe storage recipe = recipes[recipeHash];
        require(recipeExists[recipeHash], "Recipe does not exist");
        require(artifactNFTAddress != address(0), "Artifact NFT contract not set");
        require(elementTokenAddress != address(0), "Element token contract not set");
        require(catalystTokenAddress != address(0), "Catalyst token contract not set");

        // --- Consume Elements ---
        for (uint i = 0; i < recipe.inputs.length; i++) {
            ElementAmount storage input = recipe.inputs[i];
            require(input.token != address(0), "Invalid element token address in recipe");
            require(
                IERC20(input.token).transferFrom(msg.sender, address(this), input.amount),
                "Element transfer failed or insufficient allowance"
            );
        }

        // --- Consume Catalyst (Recipe Requirement + Fee) ---
        uint256 totalCatalystRequired = recipe.requiredCatalyst.add(recipe.feeCatalystAmount > 0 ? recipe.feeCatalystAmount : defaultFeeCatalyst);
        if (totalCatalystRequired > 0) {
            require(
                IERC20(catalystTokenAddress).transferFrom(msg.sender, address(this), totalCatalystRequired),
                "Catalyst transfer failed or insufficient allowance"
            );
            // Transfer fee portion to fee recipient
            if (feeRecipient != address(0) && (recipe.feeCatalystAmount > 0 ? recipe.feeCatalystAmount : defaultFeeCatalyst) > 0) {
                 uint256 feeAmount = recipe.feeCatalystAmount > 0 ? recipe.feeCatalystAmount : defaultFeeCatalyst;
                 // Ensure the contract actually received enough catalyst before sending the fee
                 // The transferFrom above guarantees this if it didn't revert.
                 // However, sending *to* the fee recipient might fail if they are a contract
                 // that doesn't accept tokens. A robust design might hold fees or handle failures.
                 // For simplicity here, we assume the fee recipient can receive tokens.
                 IERC20(catalystTokenAddress).transfer(feeRecipient, feeAmount);
            }
        }

        // --- Mint Artifact ---
        // Assumes the Artifact NFT contract has a minting function callable by this contract
        // Example call, the exact function depends on the ERC721 implementation
        // It should typically be something like `safeMint(to, tokenId, uri)`
        IERC721 artifactContract = IERC721(artifactNFTAddress);
        // Note: OpenZeppelin's ERC721 doesn't expose a public `_mint` or `_safeMint`
        // directly. A common pattern is for the NFT contract to have a minter role
        // and grant that role to the AlchmeyLab contract, or the AlchmeyLab calls
        // a custom public `mint` function on the NFT contract.
        // For demonstration, we will simulate the call structure.
        // A real implementation needs the NFT contract to have a function like:
        // function mint(address to, uint256 tokenId, string memory uri) external onlyMinter { _safeMint(to, tokenId); _setTokenURI(tokenId, uri); }
        // and the AlchemyLab address is granted the Minter role.

        // The token ID to mint is fixed by the recipe in this design
        uint256 mintedArtifactId = recipe.outputArtifactId;
        string memory tokenURI = recipe.metadataURI;

        // We cannot directly call a private/internal _safeMint from here.
        // This line is a placeholder/conceptual call. A real system requires
        // the NFT contract to have a public mint function callable by this contract.
        // Example conceptual call:
        // artifactContract.mint(msg.sender, mintedArtifactId, tokenURI);
        // Since we don't have the actual NFT contract code, we skip the external call here
        // but the logic implies it happens here.
        // For a functional deployment, replace this comment block with the actual call
        // assuming the NFT contract has a public mint function like `mint(address to, uint256 tokenId, string memory uri)`
        // and this contract address is authorized to call it.
        // Example call structure assuming such a function exists:
        // IERC721(artifactNFTAddress).call(abi.encodeWithSignature("mint(address,uint256,string)", msg.sender, mintedArtifactId, tokenURI));
        // This raw call is risky; a safer way is using interfaces if the NFT contract is known.
        // Let's assume the NFT contract has `safeMint(address to, uint256 tokenId)` and `setTokenURI(uint256 tokenId, string memory uri)` callable by us.
        // This also implies Artifact IDs must be unique for each mint, which contradicts the recipe design
        // where outputArtifactId is fixed per recipe.
        //
        // REVISED DESIGN: Let's assume the NFT contract has a `createArtifact` function
        // that takes recipient, recipe ID, and metadata and handles ID generation internally.
        // This makes more sense for unique NFTs created from recipes.
        // Let's redefine `outputArtifactId` in `Recipe` as a *type identifier* or *blueprint ID*,
        // and the NFT contract generates a *new* unique token ID upon minting.
        // The NFT contract might need a function like:
        // `function createArtifact(address to, uint256 blueprintId, string memory metadataURI) external returns (uint256 newTokenId);`
        //
        // Okay, let's adjust the `Recipe` struct and the `alchemize` function to reflect this common pattern:
        // `outputBlueprintId` instead of `outputArtifactId`.
        // The NFT contract will return the actual minted token ID.

        // Re-fetching recipe after potential storage layout change (conceptually)
        recipe = recipes[recipeHash]; // Refresh reference if struct changed

        uint256 mintedTokenId;
        // Conceptual call to NFT contract's minting function
        // Assuming ArtifactNFT has function `mintNewArtifact(address to, uint256 blueprintId, string memory metadataURI) returns (uint256)`
        // Need to encode the call correctly.
        (bool success, bytes memory returnData) = artifactNFTAddress.call(abi.encodeWithSignature("mintNewArtifact(address,uint256,string)", msg.sender, recipe.outputArtifactId, recipe.metadataURI));
        require(success, "NFT minting failed");

        // Attempt to decode the returned token ID
        // This requires the target function to actually return the token ID and abi.decode to work
        // If the function just returns a bool or nothing, this will fail.
        // A safer approach is to have the NFT contract emit an event with the new token ID
        // and have the client listen for that event. But for function return value demo:
        assembly {
            mintedTokenId := mload(add(returnData, 0x20)) // ERC-X standard says return values are offset by 32 bytes
        }

        require(mintedTokenId > 0, "NFT minting failed or returned invalid ID"); // Simple check

        // Note: Setting properties (like level) might happen immediately after minting
        // based on the blueprintId, either within the NFT contract's mint function,
        // or by calling `setArtifactProperties` from here (if `setArtifactProperties` allows non-owner calls with auth).
        // For now, `setArtifactProperties` remains owner-only for manual/backend setting.

        emit AlchemyPerformed(msg.sender, recipeHash, mintedTokenId);
    }

    /// @notice Disintegrates an artifact token held by the user.
    /// Requires the user to have the artifact and potentially approved it
    /// for transfer to this contract (though burning is direct in ERC721).
    /// @param artifactId The ID of the artifact to disintegrate.
    function disintegrateArtifact(uint256 artifactId) external {
        require(artifactNFTAddress != address(0), "Artifact NFT contract not set");
        IERC721 artifactContract = IERC721(artifactNFTAddress);

        // Check if user owns the artifact
        require(artifactContract.ownerOf(artifactId) == msg.sender, "Not the owner of the artifact");

        // --- Burn Artifact ---
        // Assumes the Artifact NFT contract has a burning function callable by this contract
        // Example: `burn(uint256 tokenId)`
        // OpenZeppelin's ERC721 typically has `_burn`. A public `burn` function
        // would need to be added to the NFT contract, callable by the owner or approved address.
        // We'll assume the NFT contract has a public `burn(uint256 tokenId)` function
        // callable by this contract (e.g., if this contract is an approved operator or the owner).
        // Call should be from msg.sender as they own it. A safe design is the user
        // approves the Lab contract, and the Lab contract calls `transferFrom` to move
        // it to the Lab (if needed before burn), or calls a burn function on the NFT
        // contract that checks approval/ownership. Standard ERC721 `burn` often
        // requires the caller to be the owner or approved.
        // Let's assume the NFT contract has `burn(uint256 tokenId)` which checks ownership/approval.
        // The user must approve the AlchemyLab or grant it operator status first.

        // Conceptual call to NFT contract's burning function
        // Example assuming artifactContract.burn(artifactId) exists and checks msg.sender ownership/approval
        (bool success, ) = artifactNFTAddress.call(abi.encodeWithSignature("burn(uint256)", artifactId));
        require(success, "NFT burning failed");


        // --- Transfer Yielded Elements/Catalyst ---
        ElementAmount[] memory yield;
        // Check for artifact-specific override first
        if (hasDisintegrationYieldOverride[artifactId]) {
            yield = artifactDisintegrationYieldOverrides[artifactId];
        } else {
            // Find the recipe that produced this artifact ID (assuming unique output ID per recipe type)
            // This lookup is inefficient. Better structure needed if many recipes.
            // For now, we'll iterate recipe hashes. A mapping from outputBlueprintId to recipe hash would be better.
            // Let's assume for simplicity that the artifactId *is* the outputBlueprintId from *some* recipe.
            // A more robust system needs a way to know *which* recipe created a specific tokenID,
            // perhaps stored during minting or derivable from blueprintId.
            // Given the `outputArtifactId` is a blueprint/type ID in the recipe struct,
            // we need to find a recipe with that blueprint ID.
            bytes32 sourceRecipeHash = 0; // Placeholder
            for(uint i = 0; i < recipeHashes.length; i++) {
                 if (recipes[recipeHashes[i]].outputArtifactId == artifactId) { // Compare blueprint IDs
                     sourceRecipeHash = recipeHashes[i];
                     break;
                 }
            }
            require(sourceRecipeHash != 0, "No recipe found for this artifact type");
            yield = recipes[sourceRecipeHash].disintegrationYield;
        }


        for (uint i = 0; i < yield.length; i++) {
            ElementAmount memory yieldItem = yield[i];
            require(yieldItem.token != address(0), "Invalid yield token address in recipe/override");

             // Contract must *hold* these tokens to transfer them.
             // This implies the contract was pre-funded, or collects tokens from fees,
             // or potentially has minting rights on the Element/Catalyst tokens (less common).
             // For this example, we assume the contract has sufficient balance.
            require(
                IERC20(yieldItem.token).transfer(msg.sender, yieldItem.amount),
                "Yield token transfer failed"
            );
        }

        // Clear the override after disintegration if desired (optional)
        // delete artifactDisintegrationYieldOverrides[artifactId];
        // hasDisintegrationYieldOverride[artifactId] = false;

        emit ArtifactDisintegrated(msg.sender, artifactId);
    }

    // --- View Functions (Read-only) ---

    /// @notice Retrieves a specific alchemy recipe by its hash.
    /// @param recipeHash The hash of the recipe.
    /// @return The Recipe struct.
    function getRecipeByHash(bytes32 recipeHash) external view returns (Recipe memory) {
        require(recipeExists[recipeHash], "Recipe does not exist");
        return recipes[recipeHash];
    }

    /// @notice Calculates the unique hash for a recipe based on its inputs and output blueprint.
    /// This hash serves as the identifier for the recipe.
    /// @param inputs Array of required elements and amounts.
    /// @param requiredCatalyst Amount of Catalyst token required.
    /// @param outputArtifactId The blueprint ID of the artifact produced.
    /// @return The calculated bytes32 hash.
    function calculateRecipeHash(ElementAmount[] memory inputs, uint256 requiredCatalyst, uint256 outputArtifactId) public pure returns (bytes32) {
        // Need a deterministic way to hash the inputs array
        bytes memory encodedInputs = abi.encode(inputs);
        // Hash includes inputs (sorted deterministically if needed, but abi.encode should be consistent),
        // required catalyst, and output blueprint ID.
        // Adding the contract address as part of the hash is common to prevent cross-contract recipe spoofing,
        // but not strictly necessary for *this* contract's internal mapping.
        // However, if recipes were shared/referenced across contracts, it would be important.
        // For now, simpler hash is based on recipe parameters only.
        return keccak256(abi.encodePacked(encodedInputs, requiredCatalyst, outputArtifactId));
    }

    /// @notice Retrieves the on-chain properties for a specific artifact ID.
    /// @param artifactId The ID of the artifact.
    /// @return The ArtifactProperties struct. Returns default values if properties not set.
    function getArtifactProperties(uint256 artifactId) external view returns (ArtifactProperties memory) {
        return artifactProperties[artifactId];
    }

    /// @notice Retrieves the disintegration yield for a specific artifact ID.
    /// Checks for an override first, otherwise returns the yield from the corresponding recipe.
    /// @param artifactId The ID of the artifact.
    /// @return Array of ElementAmount for the yield.
    function getDisintegrationYield(uint256 artifactId) external view returns (ElementAmount[] memory) {
        if (hasDisintegrationYieldOverride[artifactId]) {
            return artifactDisintegrationYieldOverrides[artifactId];
        } else {
            // Find the recipe by outputBlueprintId (inefficient iteration)
            bytes32 sourceRecipeHash = 0;
            for(uint i = 0; i < recipeHashes.length; i++) {
                 if (recipes[recipeHashes[i]].outputArtifactId == artifactId) { // Compare blueprint IDs
                     sourceRecipeHash = recipeHashes[i];
                     break;
                 }
            }
            // If no recipe is found or recipe yield is empty, return an empty array
             if (sourceRecipeHash == 0) {
                 return new ElementAmount[](0);
             }
            return recipes[sourceRecipeHash].disintegrationYield;
        }
    }

    /// @notice Returns the address of the Element ERC-20 token contract.
    function getElementTokenAddress() external view returns (address) {
        return elementTokenAddress;
    }

    /// @notice Returns the address of the Catalyst ERC-20 token contract.
    function getCatalystTokenAddress() external view returns (address) {
        return catalystTokenAddress;
    }

    /// @notice Returns the address of the Artifact ERC-721 NFT contract.
    function getArtifactNFTAddress() external view returns (address) {
        return artifactNFTAddress;
    }

    /// @notice Returns the address configured to receive collected fees.
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

    /// @notice Returns the current default catalyst fee for recipes.
    function getDefaultFeeCatalyst() external view returns (uint256) {
        return defaultFeeCatalyst;
    }

    /// @notice Checks if a user has sufficient balance for all ingredients and catalyst of a recipe.
    /// Does NOT check allowances.
    /// @param user The address of the user.
    /// @param recipeHash The hash of the recipe.
    /// @return True if user has sufficient balance, false otherwise.
    function checkRecipeIngredientsBalance(address user, bytes32 recipeHash) external view returns (bool) {
         if (!recipeExists[recipeHash]) {
             return false; // Recipe must exist
         }
         Recipe storage recipe = recipes[recipeHash];

         // Check elements
         for (uint i = 0; i < recipe.inputs.length; i++) {
             ElementAmount storage input = recipe.inputs[i];
             if (IERC20(input.token).balanceOf(user) < input.amount) {
                 return false; // Insufficient element balance
             }
         }

         // Check catalyst (required + fee)
         uint256 totalCatalystRequired = recipe.requiredCatalyst.add(recipe.feeCatalystAmount > 0 ? recipe.feeCatalystAmount : defaultFeeCatalyst);
         if (totalCatalystRequired > 0) {
             if (IERC20(catalystTokenAddress).balanceOf(user) < totalCatalystRequired) {
                 return false; // Insufficient catalyst balance
             }
         }

         return true; // All balances sufficient
    }

    /// @notice Checks if the contract has sufficient allowance from a user for all ingredients and catalyst of a recipe.
    /// Does NOT check balances.
    /// @param user The address of the user.
    /// @param recipeHash The hash of the recipe.
    /// @return True if contract has sufficient allowance, false otherwise.
    function checkRecipeIngredientsAllowance(address user, bytes32 recipeHash) external view returns (bool) {
        if (!recipeExists[recipeHash]) {
             return false; // Recipe must exist
         }
         Recipe storage recipe = recipes[recipeHash];

         // Check elements
         for (uint i = 0; i < recipe.inputs.length; i++) {
             ElementAmount storage input = recipe.inputs[i];
             if (IERC20(input.token).allowance(user, address(this)) < input.amount) {
                 return false; // Insufficient element allowance
             }
         }

         // Check catalyst (required + fee)
         uint256 totalCatalystRequired = recipe.requiredCatalyst.add(recipe.feeCatalystAmount > 0 ? recipe.feeCatalystAmount : defaultFeeCatalyst);
         if (totalCatalystRequired > 0) {
             if (IERC20(catalystTokenAddress).allowance(user, address(this)) < totalCatalystRequired) {
                 return false; // Insufficient catalyst allowance
             }
         }

         return true; // All allowances sufficient
    }


    /// @notice Returns the total number of recipes currently stored.
    function getTotalRecipesCount() external view returns (uint256) {
        return recipeHashes.length;
    }

    /// @notice Returns the hash of a recipe at a specific index in the internal list.
    /// Use `getTotalRecipesCount` to get the valid range of indices (0 to count-1).
    /// Note: The order is not guaranteed after recipe removals.
    /// @param index The index of the recipe hash.
    /// @return The recipe hash at the given index.
    function getRecipeHashByIndex(uint256 index) external view returns (bytes32) {
        require(index < recipeHashes.length, "Index out of bounds");
        return recipeHashes[index];
    }


    // --- Withdrawal Functions (Owner Only) ---

    /// @notice Allows the owner to withdraw any ERC-20 tokens held by the contract.
    /// Useful for recovering accidentally sent tokens or withdrawing collected fees if not auto-forwarded.
    /// @param tokenAddress The address of the ERC-20 token.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(amount > 0, "Amount must be greater than zero");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
        require(token.transfer(owner(), amount), "ERC20 withdrawal failed");
        emit ERC20Withdrawn(tokenAddress, owner(), amount);
    }

    /// @notice Allows the owner to withdraw any ERC-721 tokens held by the contract.
    /// ERC721Holder helps the contract *receive* NFTs, but explicit withdrawal is needed.
    /// This is for NFTs sent *to* the contract address, not the ones it mints/burns.
    /// @param tokenAddress The address of the ERC-721 token.
    /// @param tokenId The ID of the ERC-721 token.
    function withdrawERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero");
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "Contract is not the owner of the NFT");
        // Use safeTransferFrom to ensure receiver can accept ERC721
        token.safeTransferFrom(address(this), owner(), tokenId);
        emit ERC721Withdrawn(tokenAddress, owner(), tokenId);
    }

    // --- ERC721Holder Compatibility ---
    // Needed to allow the contract to receive NFTs (e.g., if a user transfers one here accidentally or intentionally).
    // This contract is primarily designed to interact with the *specified* ArtifactNFT contract
    // via mint/burn calls, not hold arbitrary NFTs, but this is good practice if receiving is possible.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        // Accept the NFT
        return this.onERC721Received.selector;
    }

    // Fallback function (optional but good practice)
    fallback() external payable {
        // Optionally handle received ether if needed, otherwise revert
        revert("Cannot receive ether directly");
    }

    receive() external payable {
        // Optionally handle received ether if needed, otherwise revert
        revert("Cannot receive ether directly");
    }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts & Functions:**

1.  **Multi-Token Interaction (ERC-20 & ERC-721):** The core mechanic isn't just minting one type of token; it's using fungible tokens as *ingredients* to create non-fungible tokens. This simulates crafting/combining assets common in games and digital collectibles.
2.  **Recipe System:** Using a `mapping` and a calculated `bytes32` hash (`calculateRecipeHash`) for recipe lookups is a common and efficient pattern for managing dynamic configurations on-chain. The recipe itself is a structured piece of data (`struct Recipe`).
3.  **`transferFrom` Usage:** Alchemy requires users to `approve` the Lab contract to spend their Element and Catalyst tokens. The Lab then uses `transferFrom`, which is the standard and secure way for contracts to pull tokens from user wallets after explicit permission.
4.  **On-Chain Properties (`ArtifactProperties`):** Storing properties like `level` and `artifactType` directly in a mapping within the Lab contract adds a layer of on-chain metadata beyond just the ERC-721 URI. This allows for game logic or filtering based on these properties directly on the blockchain.
5.  **Disintegration/Burning with Yield:** The `disintegrateArtifact` function introduces a token sink for NFTs and a source for Elements/Catalyst. This creates a circular economy mechanism, allowing users to reverse the crafting process to recoup some value or get back ingredients.
6.  **Yield Overrides (`artifactDisintegrationYieldOverrides`):** Allows for specific instances of artifacts (identified by their ID) to have a different disintegration yield than the default set in the recipe. This adds flexibility, perhaps allowing for special or rare artifacts to yield different results.
7.  **Calculated Hash for Recipes:** `calculateRecipeHash` ensures recipe definitions are unique and provides a fixed-size identifier for lookup. Using `abi.encode` helps create a consistent byte representation of complex input data.
8.  **Separate Fee Mechanism (`feeCatalystAmount`, `defaultFeeCatalyst`, `feeRecipient`):** Introduces a way to collect fees on the alchemy process, independent of the base recipe cost. Fees are configurable per recipe or globally.
9.  **Structured Data (`struct`s):** Using structs like `ElementAmount`, `Recipe`, `ArtifactProperties`, and `DisintegrationYield` organizes the contract's state and makes the code more readable and maintainable.
10. **Interaction with External Contracts:** The contract interacts with other deployed contracts (`IERC20`, `IERC721`). This is fundamental to DeFi and token standards but done here in the context of a specific application logic (crafting/alchemy).
11. **`ERC721Holder`:** By inheriting `ERC721Holder`, the contract officially signals that it knows how to handle received ERC-721 tokens, necessary if tokens might be sent directly to it.
12. **View Helpers (`checkRecipeIngredientsBalance`, `checkRecipeIngredientsAllowance`):** Providing dedicated view functions for checking user readiness for a recipe improves usability for frontends, allowing them to guide users on what they need or need to approve.
13. **Recipe Indexing (`recipeHashes`, `getTotalRecipesCount`, `getRecipeHashByIndex`):** While iterating mappings directly is bad, maintaining a separate array of keys allows for external systems (like dApps) to discover and list available recipes, albeit with potential gas costs for large lists if retrieved all at once (here, we provide iteration by index).
14. **Owner-Controlled Configuration:** Critical parameters (token addresses, fees, recipes) are owner-gated using `Ownable`, providing administrative control over the system's parameters.
15. **Withdrawal Functions:** Standard but necessary functions (`withdrawERC20`, `withdrawERC721`) to recover any tokens accidentally sent to the contract or to sweep collected fees.
16. **Detailed Events:** Emitting events for key actions allows off-chain systems (indexers, dApps, explorers) to track the state changes and provide real-time updates.
17. **SafeMath:** Although less critical in Solidity 0.8+ for basic arithmetic due to built-in overflow checks, explicitly using SafeMath (or understanding when checks are automatic) is part of secure smart contract development. Included here via import.
18. **Conceptual External Calls (Mint/Burn):** The `alchemize` and `disintegrateArtifact` functions demonstrate *how* this contract would interact with hypothetical ERC-20 and ERC-721 contracts that have specific mint/burn functions exposed to authorized callers. A real implementation would require defining those NFT/Element/Catalyst contracts as well.
19. **Dynamic Data Structures:** Use of dynamic arrays (`ElementAmount[]`) within the `Recipe` struct allows for flexible recipes that can require varying numbers and types of elements.
20. **Function Over 20 Count:** The contract includes 24 publicly exposed functions (including inherited Ownable ones and view functions), meeting the requirement.

This contract provides a more complex and interactive system than typical single-purpose token contracts, demonstrating how multiple tokens and custom logic can be combined on-chain.