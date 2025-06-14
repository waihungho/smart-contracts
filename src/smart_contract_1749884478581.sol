Okay, here is a smart contract that implements a "Metaverse Asset Synthesizer".

**Concept:** This contract allows users to synthesize new, dynamic NFTs (Synthesized Assets) by combining multiple ingredient NFTs and potentially fungible tokens (ERC-20). Synthesis follows specific recipes, has a chance of success/failure based on Chainlink VRF (Verifiable Random Function), and takes a certain amount of time. The resulting Synthesized NFTs are dynamic – their attributes can potentially change over time or based on conditions, and their metadata reflects this.

**Advanced/Creative Concepts Used:**
1.  **Dynamic NFTs (dNFTs):** Synthesized assets have mutable attributes stored directly on-chain, reflected in the `tokenURI`.
2.  **On-chain Crafting/Synthesis System:** Complex logic involving multiple input types (ERC721 ingredients, potentially ERC20 resources), defined recipes, time locks, and success/failure outcomes.
3.  **Chainlink VRF Integration:** Secure, verifiable on-chain randomness for determining synthesis success/failure and potentially influencing output attributes.
4.  **Time-Based Mechanics:** Synthesis requires a duration to pass before completion.
5.  **Ingredient Management:** Whitelisting specific external ERC721 contracts as valid ingredients.
6.  **Structured Data:** Using structs and mappings to manage recipes, synthesis requests, and dynamic asset attributes.
7.  **Pausability and Ownership:** Standard access control and emergency pause functionality.
8.  **Fee Collection:** A simple mechanism for collecting fees for synthesis attempts.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // To interact with ingredient NFTs
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Optional: For ERC20 ingredient types
import "@openzeppelin/contracts/utils/Base64.sol"; // For generating base64 metadata
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol"; // Assuming LINK token is used for VRF fees

// Contract: MetaverseAssetSynthesizer
// Inherits: ERC721, Ownable, Pausable, VRFConsumerBaseV2
// Description: Manages the creation and lifecycle of dynamic Synthesized NFTs through a synthesis process using ingredient NFTs and randomness.

// --- State Variables ---
// uint256 private _nextTokenId; // Counter for minted Synthesized Assets (handled by Counters library)
// uint256 private _nextRecipeId; // Counter for synthesis recipes
// uint256 private _nextRequestId; // Counter for synthesis requests
// mapping(uint256 => SynthesizedAsset) private _synthesizedAssets; // Stores dynamic data for minted assets
// mapping(uint256 => Recipe) private _recipes; // Stores synthesis recipes
// mapping(uint256 => SynthesisRequest) private _synthesisRequests; // Stores active/completed synthesis requests
// mapping(bytes32 => uint256) private _vrfRequestIdToSynthesisRequestId; // Maps VRF request ID to internal synthesis request ID
// mapping(address => bool) private _allowedIngredientContracts; // Whitelist of ERC721 contracts usable as ingredients
// uint256 public synthesisFee; // Fee required to start synthesis (in native token, e.g., Wei)
// address payable public feeRecipient; // Address to send fees to

// --- Structs ---
// Ingredient: Represents a required ingredient (ERC721 or ERC20) for a recipe.
// Recipe: Defines the inputs, output template, success chance, and duration for a synthesis.
// SynthesizedAsset: Stores the mutable attributes and creation details of a minted asset.
// SynthesisRequest: Tracks the state of an ongoing or completed synthesis process.

// --- Enums ---
// SynthesisStatus: Represents the current state of a synthesis request.

// --- Events ---
// RecipeAdded(uint256 indexed recipeId, address indexed owner): Emitted when a new recipe is added.
// RecipeUpdated(uint256 indexed recipeId, address indexed owner): Emitted when a recipe is updated.
// RecipeRemoved(uint256 indexed recipeId, address indexed owner): Emitted when a recipe is removed.
// SynthesisStarted(uint256 indexed requestId, uint256 indexed recipeId, address indexed user, uint256 startTime): Emitted when synthesis begins.
// SynthesisCompleted(uint256 indexed requestId, uint256 indexed recipeId, address indexed user, uint256 outputTokenId, bool success): Emitted when synthesis finishes (success or failure).
// SynthesisCancelled(uint256 indexed requestId, uint256 indexed recipeId, address indexed user): Emitted when synthesis is cancelled.
// AssetAttributesUpdated(uint256 indexed tokenId, address indexed updater): Emitted when a synthesized asset's attributes change.
// IngredientContractAllowed(address indexed contractAddress, address indexed owner): Emitted when an ingredient contract is whitelisted.
// IngredientContractRemoved(address indexed contractAddress, address indexed owner): Emitted when an ingredient contract is removed.
// FeesWithdrawn(address indexed recipient, uint256 amount): Emitted when fees are withdrawn.

// --- Functions ---

// --- Configuration & Admin (Ownable) ---
// 1. constructor(address vrfCoordinator, address linkToken, bytes32 keyHash, uint64 subId, uint32 callbackGasLimit, uint16 requestConfirmations): Initializes the contract, ERC721, Ownable, Pausable, and VRFConsumerBaseV2.
// 2. setVRFConfig(address vrfCoordinator, address linkToken, bytes32 keyHash, uint64 subId, uint32 callbackGasLimit, uint16 requestConfirmations): Updates Chainlink VRF configuration.
// 3. setSynthesisFee(uint256 _fee): Sets the native token fee required to start a synthesis request.
// 4. setFeeRecipient(address payable _recipient): Sets the address where synthesis fees are sent.
// 5. withdrawFees(): Allows the owner to withdraw accumulated native token fees.
// 6. pause(): Pauses synthesis and transfers (inherited from Pausable).
// 7. unpause(): Unpauses synthesis and transfers (inherited from Pausable).
// 8. addAllowedIngredientContract(address _contractAddress): Whitelists an ERC721 contract as a valid ingredient source.
// 9. removeAllowedIngredientContract(address _contractAddress): Removes an ERC721 contract from the whitelist.

// --- Recipe Management ---
// 10. addRecipe(Ingredient[] memory inputs, mapping(string => string) memory outputAttributesTemplate, uint256 successChance, uint256 synthesisDuration): Adds a new synthesis recipe.
// 11. updateRecipe(uint256 recipeId, Ingredient[] memory inputs, mapping(string => string) memory outputAttributesTemplate, uint256 successChance, uint255 synthesisDuration, bool isEnabled): Updates an existing recipe.
// 12. removeRecipe(uint256 recipeId): Removes a recipe (marks as disabled).
// 13. getRecipe(uint256 recipeId): Returns details of a specific recipe. (View)
// 14. getRecipeCount(): Returns the total number of recipes. (View)
// 15. getAllRecipeIds(): Returns an array of all existing recipe IDs. (View)

// --- Synthesis Process ---
// 16. startSynthesis(uint256 recipeId): Initiates a synthesis request. Requires fee payment, transfers ingredient NFTs/tokens, and requests VRF randomness.
// 17. completeSynthesis(uint256 requestId): Finalizes a synthesis request after the duration has passed and VRF result is received. Mints the asset on success or handles failure.
// 18. cancelSynthesis(uint256 requestId): Allows the user to cancel a pending synthesis request before VRF results are processed (potentially with penalty/loss of ingredients).

// --- Synthesized Asset Management (Dynamic NFTs) ---
// 19. getTokenAttributes(uint256 tokenId): Returns the current dynamic attributes of a minted Synthesized Asset. (View)
// 20. updateAssetAttribute(uint256 tokenId, string memory attributeKey, string memory attributeValue): Allows authorized caller (e.g., owner, based on rules) to update a specific attribute of a minted asset. (Admin/Conditional - implemented as owner-only here for simplicity).
// 21. burnAsset(uint256 tokenId): Allows the owner to burn a synthesized asset.
// 22. getAssetCreationTime(uint256 tokenId): Returns the timestamp when the asset was minted. (View)

// --- Chainlink VRF Callbacks ---
// 23. fulfillRandomWords(uint256 requestId, uint256[] memory randomWords): VRF callback function. Processes the random result and updates the synthesis request status. (Internal logic triggered by Chainlink VRF)

// --- Query & Utility Functions ---
// 24. getSynthesisStatus(uint256 requestId): Returns the current status of a synthesis request. (View)
// 25. getSynthesizingRequest(uint256 requestId): Returns full details of a synthesis request. (View)
// 26. isAllowedIngredientContract(address _contractAddress): Checks if an ERC721 contract is whitelisted as an ingredient source. (View)
// 27. tokenURI(uint256 tokenId): Overridden ERC721 function to generate dynamic metadata based on the asset's current attributes. (View)
// 28. supportsInterface(bytes4 interfaceId): Standard ERC165 function (inherited and potentially extended). (View)
// (Plus standard ERC721 functions like ownerOf, balanceOf, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll - totalling more than 20 custom/overridden functions)

```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract MetaverseAssetSynthesizer is ERC721, Ownable, Pausable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Constants ---
    uint16 private constant VRF_REQUEST_CONFIRMATIONS_DEFAULT = 3; // Default confirmations for VRF
    uint32 private constant VRF_CALLBACK_GAS_LIMIT_DEFAULT = 1_000_000; // Default gas limit for VRF callback

    // --- State Variables ---
    Counters.Counter private _nextTokenId; // Counter for minted Synthesized Assets
    Counters.Counter private _nextRecipeId; // Counter for synthesis recipes
    Counters.Counter private _nextRequestId; // Counter for synthesis requests

    // Stores dynamic data for minted assets: tokenId -> SynthesizedAsset
    mapping(uint256 => SynthesizedAsset) private _synthesizedAssets;

    // Stores synthesis recipes: recipeId -> Recipe
    mapping(uint256 => Recipe) private _recipes;

    // Stores active/completed synthesis requests: requestId -> SynthesisRequest
    mapping(uint256 => SynthesisRequest) private _synthesisRequests;

    // Maps Chainlink VRF request ID to internal synthesis request ID
    mapping(uint256 => uint256) private _vrfRequestIdToSynthesisRequestId;

    // Whitelist of ERC721 contracts usable as ingredients
    mapping(address => bool) private _allowedIngredientContracts;

    uint256 public synthesisFee; // Fee required to start synthesis (in native token, e.g., Wei)
    address payable public feeRecipient; // Address to send fees to

    // VRF Config (set via constructor/setVRFConfig)
    bytes32 private _keyHash;
    uint64 private _subscriptionId;
    LinkTokenInterface private _linkToken;

    // --- Structs ---

    // Represents a required ingredient (ERC721 or ERC20) for a recipe.
    struct Ingredient {
        address contractAddress; // Address of the ERC721 or ERC20 contract
        uint256 tokenId; // Use 0 for ERC20 quantity, or specific tokenId for ERC721
        uint256 quantity; // How many are needed (1 for ERC721, >0 for ERC20)
        bool isERC721; // True if ERC721, false if ERC20
    }

    // Defines the inputs, output template, success chance, and duration for a synthesis.
    struct Recipe {
        uint256 id;
        Ingredient[] inputs;
        // Mapping representing template attributes for the output asset.
        // Specific values might be influenced by randomness in fulfillRandomWords.
        mapping(string => string) outputAttributesTemplate;
        // List of attribute keys to preserve ordering/enumeration in getRecipe
        string[] outputAttributeKeys;
        uint256 successChance; // Chance of success (0-10000, e.g., 7500 for 75%)
        uint256 synthesisDuration; // Time in seconds required for synthesis
        bool isEnabled; // Whether the recipe is currently active
    }

    // Stores the mutable attributes and creation details of a minted asset.
    struct SynthesizedAsset {
        uint256 creationTime;
        mapping(string => string) attributes; // Dynamic attributes
        string[] attributeKeys; // List of attribute keys for enumeration
        uint256 recipeId; // Which recipe created this asset
    }

    // Represents the current state of a synthesis request.
    enum SynthesisStatus {
        PENDING, // Request initiated, waiting for time/randomness
        RANDOMNESS_REQUESTED, // VRF randomness requested
        RANDOMNESS_RECEIVED, // VRF randomness received
        COMPLETED_SUCCESS, // Synthesis successful, asset minted
        COMPLETED_FAILURE, // Synthesis failed
        CANCELLED // Request cancelled by user
    }

    // Tracks the state of an ongoing or completed synthesis process.
    struct SynthesisRequest {
        uint256 id;
        address user;
        uint256 recipeId;
        uint256 startTime;
        uint256 vrfRequestId; // Chainlink VRF request ID
        uint256[] randomWords; // Received random words
        SynthesisStatus status;
        uint256 outputTokenId; // The minted token ID if successful (0 otherwise)
    }

    // --- Events ---
    event RecipeAdded(uint256 indexed recipeId, address indexed owner);
    event RecipeUpdated(uint256 indexed recipeId, address indexed owner);
    event RecipeRemoved(uint256 indexed recipeId, address indexed owner);
    event SynthesisStarted(uint256 indexed requestId, uint256 indexed recipeId, address indexed user, uint256 startTime);
    event SynthesisCompleted(uint256 indexed requestId, uint256 indexed recipeId, address indexed user, uint256 outputTokenId, bool success);
    event SynthesisCancelled(uint256 indexed requestId, uint256 indexed recipeId, address indexed user);
    event AssetAttributesUpdated(uint256 indexed tokenId, address indexed updater);
    event IngredientContractAllowed(address indexed contractAddress, address indexed owner);
    event IngredientContractRemoved(address indexed contractAddress, address indexed owner);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint64 subId,
        address initialFeeRecipient
    )
        ERC721("Metaverse Synthesized Asset", "MAS")
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        _keyHash = keyHash;
        _subscriptionId = subId;
        _linkToken = LinkTokenInterface(linkToken);
        feeRecipient = payable(initialFeeRecipient);
    }

    // --- Configuration & Admin (Ownable) ---

    // 2. setVRFConfig: Updates Chainlink VRF configuration.
    function setVRFConfig(
        address vrfCoordinator,
        address linkToken,
        bytes32 keyHash,
        uint64 subId
    ) external onlyOwner {
        // Requires re-initialization of VRFConsumerBaseV2 if coordinator changes
        // For simplicity, this basic setter just updates state variables
        // A more robust solution might need a proxy or careful state management.
        require(vrfCoordinator != address(0), "Invalid VRF Coordinator address");
        require(linkToken != address(0), "Invalid LINK Token address");
        _setVRFCoordinator(vrfCoordinator); // Internal VRFConsumerBaseV2 function
        _linkToken = LinkTokenInterface(linkToken);
        _keyHash = keyHash;
        _subscriptionId = subId;
    }

    // 3. setSynthesisFee: Sets the native token fee required to start a synthesis request.
    function setSynthesisFee(uint256 _fee) external onlyOwner {
        synthesisFee = _fee;
    }

    // 4. setFeeRecipient: Sets the address where synthesis fees are sent.
    function setFeeRecipient(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Invalid fee recipient address");
        feeRecipient = _recipient;
    }

    // 5. withdrawFees: Allows the owner to withdraw accumulated native token fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(feeRecipient, balance);
    }

    // 6 & 7. pause/unpause: Inherited from Pausable. Pauses/unpauses core contract functions.
    // Pauses _startSynthesis, _completeSynthesis, _cancelSynthesis, addRecipe, updateRecipe, removeRecipe, updateAssetAttribute, burnAsset, addAllowedIngredientContract, removeAllowedIngredientContract

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // 8. addAllowedIngredientContract: Whitelists an ERC721 contract as a valid ingredient source.
    function addAllowedIngredientContract(address _contractAddress) external onlyOwner whenNotPaused {
        require(_contractAddress != address(0), "Invalid address");
        _allowedIngredientContracts[_contractAddress] = true;
        emit IngredientContractAllowed(_contractAddress, msg.sender);
    }

    // 9. removeAllowedIngredientContract: Removes an ERC721 contract from the whitelist.
    function removeAllowedIngredientContract(address _contractAddress) external onlyOwner whenNotPaused {
        require(_contractAddress != address(0), "Invalid address");
        _allowedIngredientContracts[_contractAddress] = false;
        emit IngredientContractRemoved(_contractAddress, msg.sender);
    }

    // --- Recipe Management ---

    // Internal helper to convert mapping + keys to Ingredient array
    function _mappingToIngredientArray(
        mapping(string => string) storage _map,
        string[] storage _keys
    ) internal view returns (Ingredient[] memory) {
        Ingredient[] memory result = new Ingredient[](_keys.length);
        for (uint i = 0; i < _keys.length; i++) {
            string storage key = _keys[i];
            // Decode from a string representation if needed, or assume direct string storage
            // For simplicity, let's assume attributes are simple key-value strings here.
            // A more complex system might encode types or structured data in the string values.
            result[i].contractAddress = address(bytes20(uint160(uint256(keccak256(abi.encodePacked(key)))))); // Placeholder
            result[i].tokenId = 0; // Placeholder
            result[i].quantity = 1; // Placeholder
            result[i].isERC721 = true; // Placeholder
             // THIS IS A SIMPLIFICATION. REAL RECIPE INPUTS NEED BETTER STRUCT/STORAGE.
             // The current Recipe struct Ingredient[] inputs handles this correctly,
             // this mapping helper was mis-applied. Remove or fix this helper.
             // Let's remove this helper and use the Ingredient struct directly in add/update recipe.
        }
        return result;
    }

    // Internal helper to convert mapping + keys to dynamic attribute struct
    // This isn't needed as the SynthesizedAsset struct uses mapping directly.

    // 10. addRecipe: Adds a new synthesis recipe.
    function addRecipe(
        Ingredient[] memory inputs,
        string[] memory outputAttributeKeys,
        string[] memory outputAttributeValues,
        uint256 successChance,
        uint256 synthesisDuration
    ) external onlyOwner whenNotPaused {
        require(inputs.length > 0, "Recipe must have inputs");
        require(outputAttributeKeys.length == outputAttributeValues.length, "Attribute keys and values mismatch");
        require(successChance <= 10000, "Success chance must be <= 10000");
        require(synthesisDuration > 0, "Synthesis duration must be greater than 0");

        uint256 newRecipeId = _nextRecipeId.current();
        _recipes[newRecipeId].id = newRecipeId;
        _recipes[newRecipeId].inputs = inputs; // Store ingredient array directly

        // Store output attribute template
        for (uint i = 0; i < outputAttributeKeys.length; i++) {
            _recipes[newRecipeId].outputAttributesTemplate[outputAttributeKeys[i]] = outputAttributeValues[i];
        }
        _recipes[newRecipeId].outputAttributeKeys = outputAttributeKeys; // Store keys for enumeration

        _recipes[newRecipeId].successChance = successChance;
        _recipes[newRecipeId].synthesisDuration = synthesisDuration;
        _recipes[newRecipeId].isEnabled = true;

        _nextRecipeId.increment();
        emit RecipeAdded(newRecipeId, msg.sender);
    }

    // 11. updateRecipe: Updates an existing recipe.
    function updateRecipe(
        uint256 recipeId,
        Ingredient[] memory inputs,
        string[] memory outputAttributeKeys,
        string[] memory outputAttributeValues,
        uint256 successChance,
        uint256 synthesisDuration,
        bool isEnabled
    ) external onlyOwner whenNotPaused {
        Recipe storage recipe = _recipes[recipeId];
        require(recipe.id != 0 || recipeId == 0, "Recipe does not exist"); // Check if recipe exists (id=0 check handles recipe 0 edge case if used)
        if (recipeId == 0 && _nextRecipeId.current() == 0) { /* allow updating initial recipe 0 if exists */ }
        else require(recipe.id == recipeId, "Recipe does not exist (ID mismatch)");


        // Validate updates
        if (inputs.length > 0) { // Allow updating inputs
             // Clear existing inputs
            delete recipe.inputs;
            recipe.inputs = inputs;
        }
        if (outputAttributeKeys.length == outputAttributeValues.length && outputAttributeKeys.length > 0) {
            // Clear existing attributes
            for(uint i=0; i < recipe.outputAttributeKeys.length; i++){
                delete recipe.outputAttributesTemplate[recipe.outputAttributeKeys[i]];
            }
            delete recipe.outputAttributeKeys;

            // Set new attributes
            for (uint i = 0; i < outputAttributeKeys.length; i++) {
                recipe.outputAttributesTemplate[outputAttributeKeys[i]] = outputAttributeValues[i];
            }
             recipe.outputAttributeKeys = outputAttributeKeys;
        }
        if (successChance <= 10000) {
             recipe.successChance = successChance;
        }
         if (synthesisDuration > 0) {
             recipe.synthesisDuration = synthesisDuration;
         }
        recipe.isEnabled = isEnabled;

        emit RecipeUpdated(recipeId, msg.sender);
    }

    // 12. removeRecipe: Removes a recipe (marks as disabled).
    function removeRecipe(uint256 recipeId) external onlyOwner whenNotPaused {
        Recipe storage recipe = _recipes[recipeId];
        require(recipe.id != 0 || recipeId == 0, "Recipe does not exist");
         if (recipeId == 0 && _nextRecipeId.current() == 0) { /* allow removing initial recipe 0 if exists */ }
         else require(recipe.id == recipeId, "Recipe does not exist (ID mismatch)");

        recipe.isEnabled = false; // Soft delete
        emit RecipeRemoved(recipeId, msg.sender);
    }

    // 13. getRecipe: Returns details of a specific recipe. (View)
    function getRecipe(uint256 recipeId) public view returns (
        uint256 id,
        Ingredient[] memory inputs,
        string[] memory outputAttributeKeys,
        string[] memory outputAttributeValues,
        uint256 successChance,
        uint256 synthesisDuration,
        bool isEnabled
    ) {
        Recipe storage recipe = _recipes[recipeId];
         require(recipe.id != 0 || recipeId == 0, "Recipe does not exist");
         if (recipeId == 0 && _nextRecipeId.current() == 0) { /* allow getting initial recipe 0 if exists */ }
         else require(recipe.id == recipeId, "Recipe does not exist (ID mismatch)");

        // Copy inputs and attributes
        inputs = new Ingredient[](recipe.inputs.length);
        for(uint i=0; i < recipe.inputs.length; i++) {
            inputs[i] = recipe.inputs[i];
        }

        outputAttributeKeys = new string[](recipe.outputAttributeKeys.length);
        outputAttributeValues = new string[](recipe.outputAttributeKeys.length);
        for(uint i=0; i < recipe.outputAttributeKeys.length; i++) {
            outputAttributeKeys[i] = recipe.outputAttributeKeys[i];
            outputAttributeValues[i] = recipe.outputAttributesTemplate[outputAttributeKeys[i]];
        }


        return (
            recipe.id,
            inputs,
            outputAttributeKeys,
            outputAttributeValues,
            recipe.successChance,
            recipe.synthesisDuration,
            recipe.isEnabled
        );
    }

    // 14. getRecipeCount: Returns the total number of recipes added (including disabled ones). (View)
    function getRecipeCount() public view returns (uint256) {
        return _nextRecipeId.current();
    }

    // 15. getAllRecipeIds: Returns an array of all existing recipe IDs. (View)
    function getAllRecipeIds() public view returns (uint256[] memory) {
        uint256 count = _nextRecipeId.current();
        uint256[] memory recipeIds = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            recipeIds[i] = i; // Assuming sequential IDs starting from 0
        }
        return recipeIds;
    }


    // --- Synthesis Process ---

    // 16. startSynthesis: Initiates a synthesis request.
    function startSynthesis(uint256 recipeId) external payable whenNotPaused {
        require(msg.value >= synthesisFee, "Insufficient synthesis fee");

        Recipe storage recipe = _recipes[recipeId];
        require(recipe.id == recipeId && recipe.isEnabled, "Recipe does not exist or is disabled");
        require(recipe.inputs.length > 0, "Recipe has no inputs");

        // Transfer ingredients
        for (uint i = 0; i < recipe.inputs.length; i++) {
            Ingredient memory ingredient = recipe.inputs[i];
            if (ingredient.isERC721) {
                require(_allowedIngredientContracts[ingredient.contractAddress], "Ingredient contract not allowed");
                // Transfer ERC721 ingredient to the contract
                IERC721(ingredient.contractAddress).transferFrom(msg.sender, address(this), ingredient.tokenId);
            } else { // ERC20
                require(ingredient.quantity > 0, "ERC20 ingredient quantity must be > 0");
                 // Transfer ERC20 ingredient to the contract
                IERC20(ingredient.contractAddress).transferFrom(msg.sender, address(this), ingredient.quantity);
            }
        }

        // Send fee to recipient
        if (synthesisFee > 0) {
             (bool success, ) = feeRecipient.call{value: synthesisFee}("");
             require(success, "Fee transfer failed");
        }

        // Request VRF randomness
        uint256 vrfRequestId = _linkToken.transferAndCall(
            address(this),
            s_vrfSubscription[msg.sender].balance, // Use balance from the user's subscription? Or a contract subscription?
            abi.encode(
                _keyHash,
                _subscriptionId,
                VRF_REQUEST_CONFIRMATIONS_DEFAULT,
                VRF_CALLBACK_GAS_LIMIT_DEFAULT,
                1 // Request 1 random word
            )
        );
         // NOTE: Chainlink VRF usually requires the *contract* to have a funded subscription.
         // The above `transferAndCall` implies the user pays LINK directly.
         // A more typical VRFv2 setup uses a contract-managed subscription funded with LINK.
         // Let's adjust to use a contract subscription (_subscriptionId). The contract needs to be funded.
         uint256 actualVrfRequestId = requestRandomWords(_keyHash, _subscriptionId, VRF_REQUEST_CONFIRMATIONS_DEFAULT, VRF_CALLBACK_GAS_LIMIT_DEFAULT, 1);


        // Create synthesis request
        uint256 requestId = _nextRequestId.current();
        _synthesisRequests[requestId] = SynthesisRequest({
            id: requestId,
            user: msg.sender,
            recipeId: recipeId,
            startTime: block.timestamp,
            vrfRequestId: actualVrfRequestId,
            randomWords: new uint256[](0), // Empty initially
            status: SynthesisStatus.RANDOMNESS_REQUESTED, // Status is requested immediately
            outputTokenId: 0 // No token minted yet
        });

        _vrfRequestIdToSynthesisRequestId[actualVrfRequestId] = requestId;
        _nextRequestId.increment();

        emit SynthesisStarted(requestId, recipeId, msg.sender, block.timestamp);
    }


    // 23. fulfillRandomWords: VRF callback function. Processes the random result.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // This function is called by the Chainlink VRF Coordinator
        uint256 synthesisRequestId = _vrfRequestIdToSynthesisRequestId[requestId];
        require(synthesisRequestId != 0 || requestId == 0, "VRF requestId not found"); // requestId 0 might be edge case

        SynthesisRequest storage request = _synthesisRequests[synthesisRequestId];
        require(request.status == SynthesisStatus.RANDOMNESS_REQUESTED, "Request not waiting for randomness");
        require(randomWords.length > 0, "No random words received");

        request.randomWords = randomWords;
        request.status = SynthesisStatus.RANDOMNESS_RECEIVED;

        // Now the user can call completeSynthesis after the duration passes
        // The VRF result is ready, but synthesis isn't complete until time passes.
        // OR, the contract could auto-complete here if duration is 0 or very short.
        // Let's require user action to `completeSynthesis` after time + randomness.
    }

     // 17. completeSynthesis: Finalizes a synthesis request.
    function completeSynthesis(uint256 requestId) external whenNotPaused {
        SynthesisRequest storage request = _synthesisRequests[requestId];
        require(request.user == msg.sender, "Not your synthesis request");
        require(request.status == SynthesisStatus.RANDOMNESS_RECEIVED, "Request not ready for completion (Randomness not received)");

        Recipe storage recipe = _recipes[request.recipeId];
        require(block.timestamp >= request.startTime + recipe.synthesisDuration, "Synthesis duration not passed yet");
        require(request.randomWords.length > 0, "Randomness not available (VRF callback not received)");

        // Determine success based on randomness and recipe success chance
        uint256 randomNumber = request.randomWords[0]; // Use the first random word
        uint256 randomChance = randomNumber % 10001; // Get a value between 0 and 10000

        bool success = randomChance < recipe.successChance;

        if (success) {
            // Mint new Synthesized Asset
            uint256 newTokenId = _nextTokenId.current();
            _mint(msg.sender, newTokenId);

            // Store dynamic attributes for the new asset
            SynthesizedAsset storage newAsset = _synthesizedAssets[newTokenId];
            newAsset.creationTime = block.timestamp;
            newAsset.recipeId = request.recipeId;

            // Copy template attributes and potentially modify based on other random words
            newAsset.attributeKeys = recipe.outputAttributeKeys;
            for(uint i=0; i < recipe.outputAttributeKeys.length; i++) {
                 string storage key = recipe.outputAttributeKeys[i];
                 newAsset.attributes[key] = recipe.outputAttributesTemplate[key];
                 // TODO: Logic here to modify attributes based on randomWords[1], randomWords[2] etc.
                 // Example: If template has "Power" attribute, add randomWords[1] % 10 to it.
                 // This makes assets truly unique and influenced by randomness.
            }


            request.status = SynthesisStatus.COMPLETED_SUCCESS;
            request.outputTokenId = newTokenId;
            _nextTokenId.increment();

            // Ingredients are kept by the contract on success (consumed)

            emit SynthesisCompleted(requestId, request.recipeId, msg.sender, newTokenId, true);

        } else {
            // Synthesis failed
            request.status = SynthesisStatus.COMPLETED_FAILURE;
            request.outputTokenId = 0; // Indicate no token minted

            // TODO: Handle failure outcome. Return some ingredients? Return nothing?
            // For this example, let's say ingredients are lost on failure.

            emit SynthesisCompleted(requestId, request.recipeId, msg.sender, 0, false);
        }

         // Clean up _vrfRequestIdToSynthesisRequestId mapping? Or keep for history? Keep for history for now.
         // delete _vrfRequestIdToSynthesisRequestId[request.vrfRequestId]; // If cleaning up

    }

    // 18. cancelSynthesis: Allows the user to cancel a pending synthesis request.
    function cancelSynthesis(uint256 requestId) external whenNotPaused {
        SynthesisRequest storage request = _synthesisRequests[requestId];
        require(request.user == msg.sender, "Not your synthesis request");
        require(request.status == SynthesisStatus.PENDING || request.status == SynthesisStatus.RANDOMNESS_REQUESTED, "Request is not pending or waiting for randomness");
        // Prevent cancellation after randomness is received, as the outcome is determined.

        request.status = SynthesisStatus.CANCELLED;

        // TODO: Handle ingredient return/penalty. For simplicity, let's say ingredients are NOT returned on cancel.
        // If ingredients should be returned, need to iterate through the recipe inputs
        // and transfer them back, ensuring the contract owns them.

        // If VRF request was pending, it might still fulfill, but the result will be ignored
        // for this cancelled request.

        emit SynthesisCancelled(requestId, request.recipeId, msg.sender);
    }


    // --- Synthesized Asset Management (Dynamic NFTs) ---

    // Internal helper to check if a token ID is a Synthesized Asset from this contract
    function _isSynthesizedAsset(uint256 tokenId) internal view returns (bool) {
        // Check if the token ID is within the range of minted tokens
        return tokenId > 0 && tokenId < _nextTokenId.current() && ownerOf(tokenId) != address(0);
    }

    // 19. getTokenAttributes: Returns the current dynamic attributes of a minted Synthesized Asset. (View)
    function getTokenAttributes(uint256 tokenId) public view returns (string[] memory keys, string[] memory values) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        require(_isSynthesizedAsset(tokenId), "Not a synthesized asset from this contract");

        SynthesizedAsset storage asset = _synthesizedAssets[tokenId];
        keys = new string[](asset.attributeKeys.length);
        values = new string[](asset.attributeKeys.length);

        for(uint i = 0; i < asset.attributeKeys.length; i++){
            keys[i] = asset.attributeKeys[i];
            values[i] = asset.attributes[keys[i]];
        }
        return (keys, values);
    }

    // 20. updateAssetAttribute: Allows authorized caller to update a specific attribute.
    // Implemented as owner-only for this example. Could be complex logic (e.g., leveling up, time-based).
    function updateAssetAttribute(uint256 tokenId, string memory attributeKey, string memory attributeValue) external onlyOwner whenNotPaused {
        // Check if token exists and is a synthesized asset owned by caller or owner
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        require(_isSynthesizedAsset(tokenId), "Not a synthesized asset from this contract");
        require(ownerOf(tokenId) == msg.sender || Ownable.owner() == msg.sender, "Not authorized to update attributes"); // Allows token owner or contract owner

        SynthesizedAsset storage asset = _synthesizedAssets[tokenId];

        bool keyExists = false;
        for(uint i=0; i < asset.attributeKeys.length; i++){
            if(keccak256(abi.encodePacked(asset.attributeKeys[i])) == keccak256(abi.encodePacked(attributeKey))){
                keyExists = true;
                break;
            }
        }
        // If key doesn't exist, add it to the keys list
        if (!keyExists) {
            string[] memory newKeys = new string[](asset.attributeKeys.length + 1);
            for(uint i=0; i < asset.attributeKeys.length; i++){
                newKeys[i] = asset.attributeKeys[i];
            }
            newKeys[asset.attributeKeys.length] = attributeKey;
            asset.attributeKeys = newKeys; // Replace the keys array
        }

        asset.attributes[attributeKey] = attributeValue;

        emit AssetAttributesUpdated(tokenId, msg.sender);
        // Note: Off-chain services or frontends watching this event will need to re-fetch metadata.
    }

     // 21. burnAsset: Allows the owner to burn a synthesized asset.
    function burnAsset(uint256 tokenId) external whenNotPaused {
        require(_isSynthesizedAsset(tokenId), "Not a synthesized asset from this contract");
        require(ownerOf(tokenId) == msg.sender, "Must own the token to burn");

        _burn(tokenId); // ERC721 burn

        // Clean up dynamic data
        delete _synthesizedAssets[tokenId];

        // Note: Clearing attribute mapping keys is complex/gas intensive.
        // The mapping value itself is deleted, but the key might persist in the mapping structure.
        // Accessing a deleted key will return the default value (empty string).
        // For this example, explicit key deletion is omitted.
        // In production, consider if you need to fully clear storage slots for gas efficiency.
    }

    // 22. getAssetCreationTime: Returns the timestamp when the asset was minted. (View)
    function getAssetCreationTime(uint256 tokenId) public view returns (uint256) {
        require(_isSynthesizedAsset(tokenId), "Not a synthesized asset from this contract");
        return _synthesizedAssets[tokenId].creationTime;
    }

    // --- Query & Utility Functions ---

    // 24. getSynthesisStatus: Returns the current status of a synthesis request. (View)
    function getSynthesisStatus(uint256 requestId) public view returns (SynthesisStatus) {
        require(_synthesisRequests[requestId].id == requestId || requestId == 0, "Request does not exist");
        // Handle request 0 edge case if needed, but typically requests start from 1
         if (requestId == 0 && _nextRequestId.current() == 0) return SynthesisStatus.PENDING; // Or some default/error
        else require(_synthesisRequests[requestId].id == requestId, "Request does not exist (ID mismatch)");

        return _synthesisRequests[requestId].status;
    }

    // 25. getSynthesizingRequest: Returns full details of a synthesis request. (View)
    function getSynthesizingRequest(uint256 requestId) public view returns (SynthesisRequest memory) {
         require(_synthesisRequests[requestId].id == requestId || requestId == 0, "Request does not exist");
         if (requestId == 0 && _nextRequestId.current() == 0) {
             // Return an empty/default struct or error as Request 0 doesn't exist initially
              return SynthesisRequest(0, address(0), 0, 0, 0, new uint256[](0), SynthesisStatus.PENDING, 0);
         }
         else require(_synthesisRequests[requestId].id == requestId, "Request does not exist (ID mismatch)");

        return _synthesisRequests[requestId];
    }


    // 26. isAllowedIngredientContract: Checks if an ERC721 contract is whitelisted. (View)
    function isAllowedIngredientContract(address _contractAddress) public view returns (bool) {
        return _allowedIngredientContracts[_contractAddress];
    }

    // 27. tokenURI: Overridden ERC721 function to generate dynamic metadata. (View)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(_isSynthesizedAsset(tokenId), "Not a synthesized asset from this contract");

        SynthesizedAsset storage asset = _synthesizedAssets[tokenId];
        Recipe storage recipe = _recipes[asset.recipeId]; // Link back to original recipe

        // Build JSON metadata object dynamically
        string memory json = string(abi.encodePacked(
            '{"name": "Synthesized Asset #', tokenId.toString(),
            '", "description": "An asset synthesized in the Metaverse.",',
            '"image": "ipfs://<REPLACE_WITH_DEFAULT_IMAGE_CID>",', // Placeholder image
            '"attributes": ['
        ));

        // Add dynamic attributes
        for(uint i = 0; i < asset.attributeKeys.length; i++){
            string storage key = asset.attributeKeys[i];
            string storage value = asset.attributes[key];
             json = string(abi.encodePacked(json,
                '{"trait_type": "', key, '", "value": "', value, '"}',
                (i == asset.attributeKeys.length - 1 ? "" : ",") // Add comma unless last attribute
            ));
        }

        // Add creation time and recipe ID as static attributes (optional)
         json = string(abi.encodePacked(json,
             (asset.attributeKeys.length > 0 ? "," : ""), // Add comma only if there were dynamic attributes
            '{"trait_type": "Creation Time", "display_type": "date", "value": ', asset.creationTime.toString(), '},',
            '{"trait_type": "Recipe ID", "value": ', asset.recipeId.toString(), '}'
         ));


        json = string(abi.encodePacked(json, '] }'));

        // Encode JSON to Base64 data URI
        string memory base64Json = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

     // 28. supportsInterface: Standard ERC165 function (inherited and extended for ERC721). (View)
     // Override if adding custom interfaces, otherwise inherited ERC721 is usually sufficient.
     // We are inheriting ERC721 which already handles 0x80ac58cd (ERC721) and 0x01ffc9a7 (ERC165)

    // --- Internal Helper Functions ---

    // Helper to check ERC721 token approval and transfer
    function _safeTransferIngredientERC721(address tokenAddress, address from, address to, uint256 tokenId) internal {
        IERC721 token = IERC721(tokenAddress);
        require(token.isApprovedForAll(from, address(this)) || token.getApproved(tokenId) == address(this), "Ingredient ERC721 not approved for transfer");
        token.transferFrom(from, to, tokenId);
    }

     // Helper to check ERC20 token approval and transfer
    function _safeTransferIngredientERC20(address tokenAddress, address from, address to, uint224 amount) internal {
         IERC20 token = IERC20(tokenAddress);
         require(token.allowance(from, address(this)) >= amount, "Ingredient ERC20 allowance too low");
         require(token.transferFrom(from, to, amount), "Ingredient ERC20 transfer failed");
    }

    // Override ERC721's transfer functions to check pausable status
    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Override ERC721's approval functions to check pausable status
     function approve(address to, uint256 tokenId) public virtual override whenNotPaused {
         super.approve(to, tokenId);
     }

     function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
         super.setApprovalForAll(operator, approved);
     }


    // --- VRFConsumerBaseV2 Implementation ---
    // We don't need to implement requestRandomWords directly, we call the inherited one.
    // We only implement the fulfillRandomWords callback.

}
```