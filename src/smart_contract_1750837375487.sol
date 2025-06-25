Okay, let's design a smart contract that represents an "NFT Fusion Forge". Users can combine (burn) specific ingredient NFTs from approved external collections to create brand new, unique output NFTs managed by this contract. The output NFTs will have dynamically changing properties based on interactions or conditions. This incorporates ideas around composability (using external NFTs), crafting/gaming mechanics, and dynamic NFTs.

It won't duplicate standard ERC-721 or common staking/marketplace patterns directly.

---

**Smart Contract: NFTFusionForge**

**Outline:**

1.  **License & Pragma:** Standard Solidity setup.
2.  **Imports:** OpenZeppelin libraries for ERC721, Ownable, Pausable, ERC165.
3.  **Errors:** Custom error definitions for clarity.
4.  **Events:** Signalling key actions (Fusion Success/Failure, Recipe Changes, Collection Allowed, State Updates, etc.).
5.  **Structs:**
    *   `Ingredient`: Defines requirements for one type of input NFT (contract address, required token ID or range, quantity).
    *   `Recipe`: Defines a fusion recipe (list of input ingredients, probability of success, output NFT properties/traits).
    *   `NftProperties`: Static properties of a minted NFT from this forge.
    *   `DynamicState`: Properties of a minted NFT that can change over time or via interaction.
6.  **State Variables:**
    *   Owner address.
    *   Pause status.
    *   Counter for minted token IDs.
    *   Mapping for allowed ingredient collection addresses.
    *   Mapping from recipe hash (`bytes32`) to `Recipe` struct.
    *   Mapping from token ID (`uint256`) to `NftProperties`.
    *   Mapping from token ID (`uint256`) to `DynamicState`.
    *   Base URI for metadata.
    *   Contract address of the ERC-721 implementation (e.g., self).
    *   Fee receiver address.
    *   Fusion fee amount (in wei).
7.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `onlyAllowedCollection`, `onlyFusionResultOrApproved`.
8.  **Constructor:** Initializes ERC721, Ownable, and sets initial parameters.
9.  **Core ERC-721 Functions:** Overrides of standard ERC-721 functions (`tokenURI`, `supportsInterface`, `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `approve`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`). `tokenURI` will be dynamic.
10. **Admin/Owner Functions:** Manage recipes, allowed ingredient collections, fees, pausing.
11. **User/Fusion Functions:** The main `fuseNFTs` function and potentially helper/interaction functions.
12. **Dynamic NFT Functions:** Functions allowing interaction or evolution of the minted NFTs.
13. **Query/View Functions:** Reading state variables, checking recipes, getting NFT properties/state.
14. **Internal Helper Functions:** Logic for hashing recipes, checking ingredients, generating randomness, minting/burning.

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets owner, base URI, and fee config.
2.  `supportsInterface(bytes4 interfaceId)`: ERC-165 standard implementation.
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (ERC721)
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (ERC721)
5.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific token. (ERC721)
6.  `getApproved(uint256 tokenId)`: Gets the approved address for a token. (ERC721)
7.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator for all tokens. (ERC721)
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens of an owner. (ERC721)
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token. (ERC721)
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of a token. (ERC721, overloaded)
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Safe transfer with data. (ERC721, overloaded)
12. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token (dynamic based on state). (ERC721)
13. `totalSupply()`: Returns the total number of tokens minted by this forge.
14. `addAllowedIngredientCollection(address collectionAddress)`: Owner function to allow an external ERC721 collection as an ingredient source.
15. `removeAllowedIngredientCollection(address collectionAddress)`: Owner function to disallow an external ERC721 collection.
16. `addRecipe(Ingredient[] memory inputs, uint16 successProbability, NftProperties memory outputProperties)`: Owner function to define a new fusion recipe. Takes sorted ingredients, probability (0-10000), and output properties.
17. `removeRecipe(bytes32 recipeHash)`: Owner function to remove an existing recipe.
18. `updateRecipeProbability(bytes32 recipeHash, uint16 newProbability)`: Owner function to change the success probability of a recipe.
19. `updateRecipeOutputProperties(bytes32 recipeHash, NftProperties memory newOutputProperties)`: Owner function to change the static output properties of a recipe.
20. `pauseFusion()`: Owner function to pause the `fuseNFTs` function.
21. `unpauseFusion()`: Owner function to unpause the `fuseNFTs` function.
22. `setBaseURI(string memory baseURI_)`: Owner function to set the base part of the token URI.
23. `setFeeConfiguration(address receiver, uint256 feeAmount)`: Owner function to set the fee receiver and amount.
24. `withdrawFunds()`: Owner function to withdraw collected fees.
25. `fuseNFTs(Ingredient[] memory inputs)`: User function to attempt a fusion. Requires user to have approved this contract for all specified input NFTs. Burns inputs, attempts fusion based on recipe and probability, mints output on success.
26. `evolveNFT(uint256 tokenId)`: Allows owner *or* approved user to trigger evolution logic for a minted NFT (e.g., requires certain conditions like time elapsed, other items, or maybe a fee). Updates `DynamicState`.
27. `interactWithNFT(uint256 tokenId, bytes calldata interactionData)`: Allows owner *or* approved user to interact with a minted NFT, potentially changing its `DynamicState` based on the interaction data (requires internal logic).
28. `getRecipe(bytes32 recipeHash)`: View function to get details of a specific recipe.
29. `getRecipeHash(Ingredient[] memory inputs)`: Pure function to calculate the hash for a given set of inputs (must be sorted externally or internally for consistency).
30. `getAllowedIngredientCollections()`: View function returning the list of allowed ingredient collection addresses.
31. `getNftProperties(uint256 tokenId)`: View function to get the static properties of a minted NFT.
32. `getNftDynamicState(uint256 tokenId)`: View function to get the dynamic state of a minted NFT.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity >=0.8.0 has overflow checks, SafeMath is still useful for division/multiplication clarity.
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title NFTFusionForge
 * @dev A smart contract allowing users to fuse (burn) specific ingredient NFTs
 * from approved external collections to mint new, dynamically stateful NFTs.
 * Includes a recipe system, probability of success, and on-chain dynamic properties.
 *
 * Outline:
 * 1. License & Pragma
 * 2. Imports (OpenZeppelin)
 * 3. Errors
 * 4. Events
 * 5. Structs (Ingredient, Recipe, NftProperties, DynamicState)
 * 6. State Variables
 * 7. Modifiers
 * 8. Constructor
 * 9. Core ERC-721 Overrides (tokenURI, supportsInterface, etc.)
 * 10. Admin/Owner Functions (Manage Collections, Recipes, Fees, Pause)
 * 11. User/Fusion Functions (fuseNFTs)
 * 12. Dynamic NFT Functions (evolveNFT, interactWithNFT)
 * 13. Query/View Functions (Get Recipe, Collections, Properties, State)
 * 14. Internal Helper Functions (Hashing, Randomness, Checks)
 *
 * Function Summary:
 * 1. constructor()
 * 2. supportsInterface(bytes4 interfaceId)
 * 3. balanceOf(address owner)
 * 4. ownerOf(uint256 tokenId)
 * 5. approve(address to, uint256 tokenId)
 * 6. getApproved(uint256 tokenId)
 * 7. setApprovalForAll(address operator, bool approved)
 * 8. isApprovedForAll(address owner, address operator)
 * 9. transferFrom(address from, address to, uint256 tokenId)
 * 10. safeTransferFrom(address from, address to, uint256 tokenId) (Overloaded)
 * 11. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) (Overloaded)
 * 12. tokenURI(uint256 tokenId) (Dynamic)
 * 13. totalSupply()
 * 14. addAllowedIngredientCollection(address collectionAddress) (Owner)
 * 15. removeAllowedIngredientCollection(address collectionAddress) (Owner)
 * 16. addRecipe(Ingredient[] memory inputs, uint16 successProbability, NftProperties memory outputProperties) (Owner)
 * 17. removeRecipe(bytes32 recipeHash) (Owner)
 * 18. updateRecipeProbability(bytes32 recipeHash, uint16 newProbability) (Owner)
 * 19. updateRecipeOutputProperties(bytes32 recipeHash, NftProperties memory newOutputProperties) (Owner)
 * 20. pauseFusion() (Owner)
 * 21. unpauseFusion() (Owner)
 * 22. setBaseURI(string memory baseURI_) (Owner)
 * 23. setFeeConfiguration(address receiver, uint256 feeAmount) (Owner)
 * 24. withdrawFunds() (Owner)
 * 25. fuseNFTs(Ingredient[] memory inputs) (User)
 * 26. evolveNFT(uint256 tokenId) (Dynamic NFT interaction)
 * 27. interactWithNFT(uint256 tokenId, bytes calldata interactionData) (Dynamic NFT interaction)
 * 28. getRecipe(bytes32 recipeHash) (View)
 * 29. getRecipeHash(Ingredient[] memory inputs) (Pure - Helper)
 * 30. getAllowedIngredientCollections() (View)
 * 31. getNftProperties(uint256 tokenId) (View)
 * 32. getNftDynamicState(uint256 tokenId) (View)
 */
contract NFTFusionForge is ERC721, Ownable, Pausable, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Errors ---
    error InvalidIngredientCollection();
    error RecipeNotFound();
    error IngredientMismatch();
    error NotEnoughIngredients();
    error IngredientApprovalMissing(address ingredientAddress, uint256 tokenId);
    error FusionPaused();
    error TokenDoesNotExist(uint256 tokenId);
    error NotFusionResultNFT();
    error UnauthorizedDynamicStateUpdate();
    error InvalidProbability();
    error FeeTransferFailed();
    error NoFundsToWithdraw();

    // --- Events ---
    event CollectionAllowed(address indexed collectionAddress);
    event CollectionRemoved(address indexed collectionAddress);
    event RecipeAdded(bytes32 indexed recipeHash, Ingredient[] inputs);
    event RecipeRemoved(bytes32 indexed recipeHash);
    event RecipeProbabilityUpdated(bytes32 indexed recipeHash, uint16 newProbability);
    event RecipeOutputPropertiesUpdated(bytes32 indexed recipeHash, NftProperties outputProperties);
    event FusionAttempted(address indexed fusionist, bytes32 indexed recipeHash);
    event FusionSuccess(address indexed fusionist, bytes32 indexed recipeHash, uint256 indexed newTokenId);
    event FusionFailed(address indexed fusionist, bytes32 indexed recipeHash);
    event NftDynamicStateUpdated(uint256 indexed tokenId, bytes32 indexed stateHash);
    event FeeConfigurationUpdated(address indexed receiver, uint256 feeAmount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Structs ---
    struct Ingredient {
        address collectionAddress; // Address of the ERC721 contract
        uint256 tokenId;           // Specific token ID required (0 for any token in collection)
        uint256 quantity;          // Number of tokens required
    }

    struct NftProperties {
        string name;
        string description;
        // Add more static properties like trait types, values, etc.
        // Example: string[] traits; string[] traitValues;
    }

    struct DynamicState {
        uint256 level;
        uint64 lastInteractionTimestamp;
        uint256 health;
        // Add more dynamic properties that can change post-mint
        // Example: string status; uint256 experience;
    }

    struct Recipe {
        Ingredient[] inputs;
        uint16 successProbability; // 0-10000 representing 0% to 100%
        NftProperties outputProperties;
    }

    // --- State Variables ---
    uint256 private _nextTokenId;

    // Keep track of allowed external NFT collections
    mapping(address => bool) private _allowedIngredientCollections;
    address[] private _allowedIngredientCollectionsArray; // To easily list allowed collections

    // Recipe storage: Hash of ingredients => Recipe
    mapping(bytes32 => Recipe) private _recipes;
    bytes32[] private _recipeHashesArray; // To easily list recipes

    // Storage for properties and dynamic state of NFTs minted by this contract
    mapping(uint256 => NftProperties) private _nftProperties;
    mapping(uint256 => DynamicState) private _nftDynamicState;

    string private _baseURI;
    address private _feeReceiver;
    uint256 private _fusionFee;

    // --- Modifiers ---
    modifier onlyAllowedCollection(address collectionAddress) {
        if (!_allowedIngredientCollections[collectionAddress]) {
            revert InvalidIngredientCollection();
        }
        _;
    }

    // Allows only the owner of the NFT or an approved address (operator or individual token)
    modifier onlyFusionResultOrApproved(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && getApproved(tokenId) != msg.sender && !isApprovedForAll(tokenOwner, msg.sender)) {
            revert UnauthorizedDynamicStateUpdate();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        address initialFeeReceiver,
        uint256 initialFusionFee
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        _baseURI = baseURI_;
        _nextTokenId = 1; // Start token IDs from 1
        _feeReceiver = initialFeeReceiver;
        _fusionFee = initialFusionFee;
    }

    // --- Core ERC-721 Overrides ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        // Also support ERC721Receiver for potential incoming transfers (though we primarily burn from sender)
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        // The actual metadata JSON should be hosted off-chain, but generated
        // dynamically based on the on-chain NftProperties and DynamicState.
        // The URI would typically point to an API endpoint like:
        // https://your.metadata.api/token/{tokenId}
        // This endpoint would then query the contract for properties and state.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    // The standard ERC721 functions like balanceOf, ownerOf, approve, getApproved,
    // setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom are
    // inherited and used from OpenZeppelin and don't need explicit re-implementation
    // unless custom logic is required beyond pause checks. Pausable is applied via modifiers.

    // We need totalSupply, which is tracked internally by ERC721 but we expose it
    function totalSupply() public view returns (uint256) {
        // OpenZeppelin ERC721 doesn't expose totalSupply directly, but _nextTokenId
        // is a reasonable approximation if we only mint sequentially and never burn.
        // If burning is introduced, this would need a dedicated counter.
        // For this design, we only mint *new* tokens, never burn the forged ones (for now).
        // If fused NFTs could also be ingredients, a burn counter would be needed.
        // Assuming no burning of forged NFTs for simplicity here:
         return _nextTokenId - 1;
    }


    // --- Admin/Owner Functions ---

    function addAllowedIngredientCollection(address collectionAddress) public onlyOwner {
        if (collectionAddress == address(0)) revert InvalidIngredientCollection();
        if (!_allowedIngredientCollections[collectionAddress]) {
            _allowedIngredientCollections[collectionAddress] = true;
            _allowedIngredientCollectionsArray.push(collectionAddress);
            emit CollectionAllowed(collectionAddress);
        }
    }

    function removeAllowedIngredientCollection(address collectionAddress) public onlyOwner {
        if (_allowedIngredientCollections[collectionAddress]) {
             _allowedIngredientCollections[collectionAddress] = false;
             // Simple removal from array (inefficient for large arrays, consider linked list or mapping index)
             for (uint256 i = 0; i < _allowedIngredientCollectionsArray.length; i++) {
                 if (_allowedIngredientCollectionsArray[i] == collectionAddress) {
                     _allowedIngredientCollectionsArray[i] = _allowedIngredientCollectionsArray[_allowedIngredientCollectionsArray.length - 1];
                     _allowedIngredientCollectionsArray.pop();
                     break;
                 }
             }
            emit CollectionRemoved(collectionAddress);
        }
    }

    function addRecipe(Ingredient[] memory inputs, uint16 successProbability, NftProperties memory outputProperties) public onlyOwner {
        if (successProbability > 10000) revert InvalidProbability();
        // Ensure inputs are sorted canonically before hashing
        Ingredient[] memory sortedInputs = _sortIngredients(inputs);
        bytes32 recipeHash = _getIngredientHash(sortedInputs);

        if (_recipes[recipeHash].inputs.length != 0) {
             // Recipe already exists, consider update function instead
             revert("Recipe already exists"); // Custom error preferred
        }

        _recipes[recipeHash] = Recipe(sortedInputs, successProbability, outputProperties);
        _recipeHashesArray.push(recipeHash);

        emit RecipeAdded(recipeHash, sortedInputs);
    }

    function removeRecipe(bytes32 recipeHash) public onlyOwner {
         if (_recipes[recipeHash].inputs.length == 0) {
             revert RecipeNotFound();
         }
         delete _recipes[recipeHash];
         // Simple removal from array (inefficient for large arrays)
         for (uint256 i = 0; i < _recipeHashesArray.length; i++) {
             if (_recipeHashesArray[i] == recipeHash) {
                 _recipeHashesArray[i] = _recipeHashesArray[_recipeHashesArray.length - 1];
                 _recipeHashesArray.pop();
                 break;
             }
         }
         emit RecipeRemoved(recipeHash);
    }

    function updateRecipeProbability(bytes32 recipeHash, uint16 newProbability) public onlyOwner {
        if (_recipes[recipeHash].inputs.length == 0) {
            revert RecipeNotFound();
        }
        if (newProbability > 10000) revert InvalidProbability();
        _recipes[recipeHash].successProbability = newProbability;
        emit RecipeProbabilityUpdated(recipeHash, newProbability);
    }

     function updateRecipeOutputProperties(bytes32 recipeHash, NftProperties memory newOutputProperties) public onlyOwner {
        if (_recipes[recipeHash].inputs.length == 0) {
            revert RecipeNotFound();
        }
        _recipes[recipeHash].outputProperties = newOutputProperties;
        emit RecipeOutputPropertiesUpdated(recipeHash, newOutputProperties);
    }


    function pauseFusion() public onlyOwner {
        _pause();
    }

    function unpauseFusion() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setFeeConfiguration(address receiver, uint256 feeAmount) public onlyOwner {
        if (receiver == address(0)) revert("Invalid fee receiver address");
        _feeReceiver = receiver;
        _fusionFee = feeAmount;
        emit FeeConfigurationUpdated(_feeReceiver, _fusionFee);
    }

    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoFundsToWithdraw();

        (bool success, ) = payable(_feeReceiver).call{value: balance}("");
        if (!success) {
            revert FeeTransferFailed();
        }
        emit FundsWithdrawn(_feeReceiver, balance);
    }


    // --- User/Fusion Functions ---

    /**
     * @dev Attempts to fuse a list of input NFTs based on defined recipes.
     * Requires the user to have approved this contract to transfer the input NFTs.
     * Ingredients must be provided *sorted* to match recipe hash.
     * Burns inputs regardless of fusion success.
     * Collects fusion fee.
     * @param inputs List of ingredients (contract address, tokenId, quantity). Must be sorted.
     */
    function fuseNFTs(Ingredient[] memory inputs) public payable whenNotPaused {
        if (msg.value < _fusionFee) revert("Insufficient fusion fee");

        // Send fee to receiver
        if (_fusionFee > 0) {
             (bool success, ) = payable(_feeReceiver).call{value: _fusionFee}("");
             // If fee transfer fails, revert the entire fusion attempt
             if (!success) {
                 revert FeeTransferFailed();
             }
        }

        // The user *must* provide inputs sorted to match the recipe hash key
        Ingredient[] memory sortedInputs = _sortIngredients(inputs); // Sort defensively

        bytes32 recipeHash = _getIngredientHash(sortedInputs);
        Recipe storage recipe = _recipes[recipeHash];

        if (recipe.inputs.length == 0) {
            // Refund excess ETH if recipe not found
            if (msg.value > _fusionFee) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - _fusionFee}("");
                 // Revert if refund fails to prevent state inconsistency (should be rare)
                 if (!success) revert("Fee refund failed after recipe not found"); // Custom error
             }
            revert RecipeNotFound();
        }

        // Check ingredients and permissions
        _checkIngredientsAndPermissions(msg.sender, sortedInputs, recipe.inputs);

        // Burn the input NFTs
        _burnIngredients(msg.sender, sortedInputs);

        emit FusionAttempted(msg.sender, recipeHash);

        // Determine success based on probability
        // WARNING: On-chain randomness is NOT secure for high-value outcomes.
        // Use Chainlink VRF or similar in production.
        uint256 randomNumber = _generateRandomness(msg.sender, block.timestamp, block.difficulty, block.number, tx.gasprice);
        uint256 probabilityBasis = 10000; // Basis for probability (e.g., 10000 for 0.01% precision)

        if (randomNumber % probabilityBasis < recipe.successProbability) {
            // Fusion Success!
            uint256 newTokenId = _nextTokenId++;
            _safeMint(msg.sender, newTokenId);

            // Store static properties and initial dynamic state
            _nftProperties[newTokenId] = recipe.outputProperties;
            _nftDynamicState[newTokenId] = DynamicState({
                level: 1,
                lastInteractionTimestamp: uint64(block.timestamp),
                health: 100 // Example initial state
                // Initialize other dynamic properties
            });
            emit NftDynamicStateUpdated(newTokenId, keccak256(abi.encode(_nftDynamicState[newTokenId]))); // Emit hash of initial state

            emit FusionSuccess(msg.sender, recipeHash, newTokenId);

            // Refund excess ETH
            if (msg.value > _fusionFee) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - _fusionFee}("");
                 if (!success) revert("Fee refund failed after success"); // Custom error
             }

        } else {
            // Fusion Failed :( Inputs are already burned.
            emit FusionFailed(msg.sender, recipeHash);

             // Refund excess ETH
             if (msg.value > _fusionFee) {
                 (bool success, ) = payable(msg.sender).call{value: msg.value - _fusionFee}("");
                 if (!success) revert("Fee refund failed after failure"); // Custom error
             }
        }
    }


    // --- Dynamic NFT Functions ---

    /**
     * @dev Allows evolving a forged NFT. Can be called by owner or approved.
     * Contains internal logic to determine if evolution is possible (e.g., based on time, level, other state).
     * This is a placeholder for complex evolution rules.
     * @param tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 tokenId) public onlyFusionResultOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (ownerOf(tokenId) != address(this) && ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            // This check is actually redundant due to the modifier, but good to be explicit.
             revert UnauthorizedDynamicStateUpdate();
        }

        DynamicState storage currentState = _nftDynamicState[tokenId];

        // --- Complex Evolution Logic Placeholder ---
        // Example: Can only evolve if level < 10 and 24 hours have passed since last interaction
        bool canEvolve = false;
        if (currentState.level < 10 && (block.timestamp - currentState.lastInteractionTimestamp) >= 1 days) {
            canEvolve = true;
            // Maybe require burning another item? Or paying a fee?
            // Example: require(ERC20(EVOLUTION_ITEM_ADDRESS).transferFrom(msg.sender, address(this), EVOLUTION_COST), "Need evolution item");
        }
        // --- End Placeholder ---

        if (!canEvolve) {
            revert("Evolution conditions not met"); // Custom error
        }

        // Apply evolution effects
        currentState.level += 1;
        currentState.health += 10; // Gain health on evolution
        currentState.lastInteractionTimestamp = uint64(block.timestamp);
        // Update other state based on evolution

        emit NftDynamicStateUpdated(tokenId, keccak256(abi.encode(currentState)));
        // Note: `tokenURI` relies on this state change to reflect updates in metadata.
    }

     /**
     * @dev Allows interacting with a forged NFT. Can be called by owner or approved.
     * The outcome depends on the interaction data and current state.
     * This is a placeholder for various interaction types (e.g., feeding, training, battling simulation).
     * @param tokenId The ID of the NFT to interact with.
     * @param interactionData Arbitrary data defining the interaction type and parameters.
     */
    function interactWithNFT(uint256 tokenId, bytes calldata interactionData) public onlyFusionResultOrApproved(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
         if (ownerOf(tokenId) != address(this) && ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            // Redundant due to modifier
             revert UnauthorizedDynamicStateUpdate();
        }

        DynamicState storage currentState = _nftDynamicState[tokenId];

        // --- Complex Interaction Logic Placeholder ---
        // Example: Simple interaction logic based on interactionData
        bytes4 interactionType = bytes4(interactionData[0..4]);

        if (interactionType == bytes4(keccak256("feed()"))) {
            // Example 'feed' interaction
            if (currentState.health < 100) {
                currentState.health += 5;
                if (currentState.health > 100) currentState.health = 100;
                currentState.lastInteractionTimestamp = uint64(block.timestamp);
                 // Maybe require burning a food item? ERC721(FOOD_ITEM_COLLECTION).burn(FEED_ITEM_ID);
            } else {
                revert("Health is already full"); // Custom error
            }
        } else if (interactionType == bytes4(keccak256("train()"))) {
             // Example 'train' interaction
             if (currentState.level < 10) {
                 currentState.level += 1;
                 currentState.lastInteractionTimestamp = uint64(block.timestamp);
             } else {
                 revert("Already max level"); // Custom error
             }
        } else {
            revert("Unknown interaction type"); // Custom error
        }
        // --- End Placeholder ---

        emit NftDynamicStateUpdated(tokenId, keccak256(abi.encode(currentState)));
         // Note: `tokenURI` relies on this state change to reflect updates in metadata.
    }


    // --- Query/View Functions ---

    function getRecipe(bytes32 recipeHash) public view returns (Recipe memory) {
        if (_recipes[recipeHash].inputs.length == 0) {
            revert RecipeNotFound();
        }
        return _recipes[recipeHash];
    }

    /**
     * @dev Calculates the canonical hash for a list of ingredients.
     * Ingredients MUST be sorted consistently (e.g., by collection address, then tokenId)
     * before hashing to ensure a unique hash for a given recipe.
     * @param inputs The list of ingredients.
     * @return The keccak256 hash representing the recipe inputs.
     */
    function getRecipeHash(Ingredient[] memory inputs) public pure returns (bytes32) {
         // Call internal helper to get the hash of the sorted inputs
         return _getIngredientHash(_sortIngredients(inputs));
    }

     function getAllowedIngredientCollections() public view returns (address[] memory) {
        return _allowedIngredientCollectionsArray;
    }

    function getNftProperties(uint256 tokenId) public view returns (NftProperties memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _nftProperties[tokenId];
    }

    function getNftDynamicState(uint256 tokenId) public view returns (DynamicState memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _nftDynamicState[tokenId];
    }

     // --- Internal Helper Functions ---

     /**
      * @dev Sorts an array of Ingredients canonically. Used for hashing.
      * Sorting order: by collectionAddress ascending, then by tokenId ascending.
      * @param inputs The unsorted array of ingredients.
      * @return A new array with ingredients sorted.
      */
    function _sortIngredients(Ingredient[] memory inputs) internal pure returns (Ingredient[] memory) {
        Ingredient[] memory sorted = new Ingredient[](inputs.length);
        for (uint i = 0; i < inputs.length; i++) {
            sorted[i] = inputs[i];
        }

        // Bubble sort implementation for demonstration. In production,
        // consider gas costs for large arrays or require pre-sorting off-chain.
        for (uint i = 0; i < sorted.length; i++) {
            for (uint j = 0; j < sorted.length - i - 1; j++) {
                bool swap = false;
                if (sorted[j].collectionAddress > sorted[j+1].collectionAddress) {
                    swap = true;
                } else if (sorted[j].collectionAddress == sorted[j+1].collectionAddress && sorted[j].tokenId > sorted[j+1].tokenId) {
                     swap = true;
                }

                if (swap) {
                    Ingredient memory temp = sorted[j];
                    sorted[j] = sorted[j+1];
                    sorted[j+1] = temp;
                }
            }
        }
        return sorted;
    }


     /**
      * @dev Calculates the canonical hash for a list of ingredients.
      * Assumes inputs are already sorted canonically.
      * @param sortedInputs The sorted array of ingredients.
      * @return The keccak256 hash.
      */
    function _getIngredientHash(Ingredient[] memory sortedInputs) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sortedInputs));
    }


    /**
     * @dev Checks if the user has the required ingredients and if the contract
     * has approval to transfer them from the user.
     * @param user The address attempting the fusion.
     * @param providedInputs The ingredients provided by the user (already sorted).
     * @param requiredInputs The ingredients required by the recipe (already sorted).
     */
    function _checkIngredientsAndPermissions(
        address user,
        Ingredient[] memory providedInputs,
        Ingredient[] memory requiredInputs
    ) internal view {
        if (providedInputs.length != requiredInputs.length) {
            revert IngredientMismatch();
        }

        for (uint i = 0; i < requiredInputs.length; i++) {
            Ingredient memory required = requiredInputs[i];
            Ingredient memory provided = providedInputs[i];

            // Strict match required: collection address, tokenId (if specific), and quantity
            if (provided.collectionAddress != required.collectionAddress ||
                (required.tokenId != 0 && provided.tokenId != required.tokenId) ||
                provided.quantity != required.quantity) {
                revert IngredientMismatch();
            }

             if (!_allowedIngredientCollections[required.collectionAddress]) {
                 // Should not happen if recipe was added correctly, but double check
                 revert InvalidIngredientCollection();
             }

            IERC721 ingredientContract = IERC721(required.collectionAddress);

            // Check user's balance for the required specific token ID or any ID if required.tokenId is 0
            // This logic assumes providedInputs lists the *exact* token IDs the user wants to use
            // for the quantity specified. A more complex system might allow using *any* N tokens from a collection.
            // This implementation requires specifying the exact tokenId *if* the recipe requires a specific one.
            // If recipe.tokenId is 0, provided.tokenId MUST also be 0. The quantity check is separate.
             if (required.tokenId != 0) {
                // Check if user owns the specific token ID and has approved this contract
                if (ingredientContract.ownerOf(provided.tokenId) != user) {
                     revert NotEnoughIngredients(); // User doesn't own the specific token
                }
                 // Check if approval for the specific token or all tokens is granted
                 address approvedAddress = ingredientContract.getApproved(provided.tokenId);
                 bool approvedForAll = ingredientContract.isApprovedForAll(user, address(this));

                 if (approvedAddress != address(this) && !approvedForAll) {
                     revert IngredientApprovalMissing(provided.collectionAddress, provided.tokenId);
                 }

                 // Quantity for specific token ID must be 1
                 if (provided.quantity != 1) revert IngredientMismatch();

            } else {
                 // Recipe requires quantity of *any* token from the collection (tokenId 0)
                 // This implementation requires the user to list `quantity` number of entries
                 // in the providedInputs array with collectionAddress and tokenId 0.
                 // A more user-friendly interface would allow providing just the collection+quantity
                 // and let the contract pick which tokens to burn, but that's more complex.
                 // Let's refine: User provides N specific token IDs to burn if recipe needs N from a collection (tokenId 0).
                 // So, `providedInputs` for a required {collectionA, 0, 3} ingredient
                 // would be three entries: {collectionA, id1, 1}, {collectionA, id2, 1}, {collectionA, id3, 1}.
                 // The sorting logic needs to handle this.
                 // Let's simplify for this example: If recipe needs {collectionA, 0, 3}, the user must provide *exactly*
                 // 3 Ingredient structs like {collectionA, tokenId_X, 1}, {collectionA, tokenId_Y, 1}, {collectionA, tokenId_Z, 1}
                 // where X, Y, Z are token IDs the user owns and have approved this contract.
                 // The `providedInputs` array length must match the sum of quantities in `requiredInputs`.
                 // Let's adjust the check: Check total quantity per collection/tokenId 0 requirement.

                 // The providedInputs array itself must represent the *exact* tokens to burn.
                 // So if recipe needs {A, 0, 2} and {B, 5, 1}, provided must be like [{A, id1, 1}, {A, id2, 1}, {B, 5, 1}].
                 // The sorting ensures they line up.
                 // The check below needs to verify ownership and approval for *each* provided token listed.

                 // If required.tokenId is 0, provided.tokenId MUST be > 0 (the actual token ID to burn).
                 if (provided.tokenId == 0) revert IngredientMismatch(); // Provided must be specific if required is any

                 // Check user owns the specific token ID in the provided list and has approved
                  if (ingredientContract.ownerOf(provided.tokenId) != user) {
                     revert NotEnoughIngredients(); // User doesn't own the specific token provided
                 }
                 address approvedAddress = ingredientContract.getApproved(provided.tokenId);
                 bool approvedForAll = ingredientContract.isApprovedForAll(user, address(this));

                 if (approvedAddress != address(this) && !approvedForAll) {
                      revert IngredientApprovalMissing(provided.collectionAddress, provided.tokenId);
                 }
                 // Quantity for this specific token ID must be 1
                 if (provided.quantity != 1) revert IngredientMismatch();
            }
        }
    }


    /**
     * @dev Burns the specified input NFTs from the user's wallet.
     * Assumes permissions have already been checked.
     * @param user The address owning the ingredients.
     * @param inputs The list of ingredients (specific token IDs) to burn.
     */
    function _burnIngredients(address user, Ingredient[] memory inputs) internal {
        for (uint i = 0; i < inputs.length; i++) {
            Ingredient memory ingredient = inputs[i];
            // Assuming quantity is 1 for each entry in inputs after checkIngredientsAndPermissions logic
            // If quantity > 1 was allowed per entry, loop quantity times.
             if (ingredient.quantity != 1) revert "Internal error: quantity > 1 in burn list"; // Should not happen with current checks

            IERC721 ingredientContract = IERC721(ingredient.collectionAddress);
            // ERC721 standard burn function (SafeMath not applicable here)
            ingredientContract.transferFrom(user, address(0), ingredient.tokenId); // Burn by transferring to address(0)
        }
    }


    /**
     * @dev Generates a pseudo-random number. NOT cryptographically secure.
     * Should be replaced with Chainlink VRF or similar in production for sensitive outcomes.
     * @param sender The address initiating the process.
     * @param timestamp The current block timestamp.
     * @param difficulty The current block difficulty.
     * @param blocknumber The current block number.
     * @param gasprice The gas price of the transaction.
     * @return A pseudo-random uint256.
     */
    function _generateRandomness(
        address sender,
        uint256 timestamp,
        uint256 difficulty,
        uint256 blocknumber,
        uint256 gasprice
    ) internal view returns (uint256) {
        // Using blockhash(block.number - 1) ensures the value is not predictable
        // within the same block, but is predictable by miners.
        // For better randomness, combine with other variables or use VRF.
        uint256 randomSeed = uint256(keccak256(
            abi.encodePacked(
                blockhash(block.number - 1), // Use previous blockhash
                sender,
                timestamp,
                difficulty, // Use block.timestamp, block.difficulty for unpredictability within block (less reliable now with Proof-of-Stake)
                blocknumber,
                gasprice,
                _nextTokenId // Add a contract specific counter
                // Consider adding block.chainid, msg.value if applicable
            )
        ));
        return randomSeed;
    }

     // Needed for IERC721Receiver compatibility, although we burn from sender
     // rather than transferring into the contract. Implement as required by standard.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This contract does not accept receiving NFTs for storage or other purposes
        // It only receives them briefly during a transferFrom call before burning them.
        // If you *did* want the contract to hold ingredients, you would handle that logic here.
        // Returning the magic value signifies acceptance.
        return this.onERC721Received.selector;
    }


    // The ERC721 standard functions _safeMint, _burn are used internally
    // by the overridden transferFrom functions and our _burnIngredients.
    // _beforeTokenTransfer, _afterTokenTransfer hooks can be used for custom logic
    // like checking if the token is the result of this forge or an ingredient.

    // Example _beforeTokenTransfer hook:
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer of forged NFTs if paused (optional, depends on desired behavior)
        if (_exists(tokenId) && ownerOf(tokenId) == from && from != address(0) && to != address(0) && paused()) {
            revert("Transfers paused for forged NFTs"); // Custom error
        }

        // Add checks related to ingredients if needed
    }
}
```

**Explanation of Advanced Concepts and Features:**

1.  **Composable NFTs:** The contract interacts with *external* ERC-721 contracts (`IERC721`). Users must possess and approve the transfer of these external NFTs to the Forge contract for burning. This makes the Forge dependent on and interacting with other NFT ecosystems.
2.  **Recipe System:** Uses a mapping based on a `bytes32` hash of the ingredients to define distinct fusion formulas.
    *   **Canonical Hashing:** Ingredients must be sorted canonically before hashing (`_sortIngredients`, `_getIngredientHash`) to ensure that the order doesn't matter for recipe lookup, only the combination and quantities.
    *   **Ingredient Struct:** Allows specifying required collection address, specific token ID (or 0 for any token), and quantity.
3.  **Probabilistic Outcomes:** Fusion has a defined `successProbability` stored in the recipe (0-10000 basis). This introduces risk and rarity.
4.  **On-Chain Pseudo-Randomness:** Uses a combination of block properties, sender address, and contract state (`_nextTokenId`) to generate a seed for determining fusion success/failure. *Crucially, this is highlighted as NOT secure for high-value outcomes in production and should ideally use Chainlink VRF or similar decentralized oracle.*
5.  **Dynamic NFTs:**
    *   Fused NFTs have both `NftProperties` (static, set at mint based on recipe) and `DynamicState` (mutable).
    *   Functions like `evolveNFT` and `interactWithNFT` allow the NFT's state (`DynamicState`) to change *after* minting.
    *   These functions are restricted to the NFT owner or approved operators (`onlyFusionResultOrApproved` modifier).
    *   The `tokenURI` function is overridden to indicate that metadata should be fetched from a service that queries the *current* `DynamicState` of the token, making the metadata dynamic.
6.  **Atomic Fusion Transaction:** The `fuseNFTs` function handles all steps (fee collection, ingredient check, ingredient burning, randomness, outcome processing, output minting/failure) within a single transaction. If any step fails (e.g., insufficient approvals, fee transfer fails), the entire transaction reverts (except for the fee transfer itself on failure, which is handled carefully).
7.  **Ingredient Burning:** Instead of transferring ingredients *to* the contract, the contract calls `transferFrom` to send the ingredients directly to the zero address (`address(0)`), effectively burning them directly from the user's wallet after verifying approval.
8.  **Fee Mechanism:** Fusion attempts require a fee, collected in ETH, which can be withdrawn by the owner.
9.  **Pausable:** The `fuseNFTs` function (and optionally transfers of forged NFTs) can be paused by the owner.
10. **Granular Admin Control:** Owner functions allow adding/removing allowed collections and recipes, updating recipe parameters (probability, output properties), and managing fees.
11. **Error Handling:** Uses custom errors for clearer revert reasons.
12. **Array Management:** Includes basic (though potentially inefficient for large scale) array management for listing allowed collections and recipe hashes. More advanced data structures could be used for large numbers.

This contract goes beyond a standard ERC-721 by adding a complex interaction layer requiring external NFTs, a dynamic minting process with probability and recipes, and mutable on-chain state for the resulting NFTs.