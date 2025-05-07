Okay, let's design a smart contract that acts as a factory for generating *dynamic* NFTs based on pre-defined "models" or "recipes". The generation logic is parameterized and partially controlled on-chain, allowing for variations and potentially future evolution. Users can mint based on these models, sometimes influencing parameters, and the metadata is generated dynamically.

This concept involves:
1.  **Factory Pattern:** Managing multiple types of generative rules.
2.  **Generative Art/Data:** Storing and using parameters on-chain to define unique outputs.
3.  **Dynamic NFTs:** The `tokenURI` or underlying parameters could theoretically change (though we'll keep parameters fixed post-mint for simplicity in this example, but the *rendering* via metadata could be dynamic based on external factors or time, often handled off-chain but driven by on-chain data). We *will* store the *generated* parameters on-chain.
4.  **Parameterized Minting:** Allowing users to influence the generation within model constraints.
5.  **On-chain Configuration:** Storing model definitions and parameters on-chain.

Let's call it `GenerativeNFTFactory`.

---

## Contract Outline: `GenerativeNFTFactory.sol`

This contract is an ERC721 token itself, where each token represents a unique generative NFT minted from one of the registered models. It manages the creation parameters for different generative art styles ("models") and allows users to mint NFTs based on these models, storing the specific parameters used for each token on-chain.

1.  **Imports:** ERC721, Ownable, ReentrancyGuard, Strings.
2.  **Error Definitions:** Custom errors for clarity.
3.  **Structs:**
    *   `GenerationModel`: Defines a template for a generative style (name, description, mint cost, max supply, base/default parameters, active status).
    *   `TokenParameters`: Stores the *specific* generated parameters for an individual NFT token.
4.  **State Variables:**
    *   Owner address.
    *   Pause status.
    *   Counter for model IDs.
    *   Mapping from model ID to `GenerationModel`.
    *   Mapping from token ID to the model ID used.
    *   Mapping from token ID to `TokenParameters`.
    *   Mapping from model ID to current minted supply for that model.
    *   Total minted supply across all models.
    *   Withdrawal address for funds.
    *   Base URI for metadata (can be an API endpoint).
5.  **Events:**
    *   `ModelAdded`: When a new generation model is registered.
    *   `ModelUpdated`: When a model's config changes.
    *   `ModelToggled`: When a model's active status changes.
    *   `NFTMinted`: When a token is minted, including its parameters.
    *   `Withdrawal`: When funds are withdrawn.
    *   `FactoryPaused`, `FactoryUnpaused`.
    *   `BaseURIUpdated`.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`.
7.  **ERC721 Overrides:** `tokenURI`.
8.  **Internal Functions:**
    *   `_generateTokenData`: Core logic to deterministically (or pseudo-randomly) generate parameters based on model, seed, and optional user input.
9.  **Public/External Functions (>= 20 custom):**
    *   **Factory Management:**
        *   `constructor`: Initializes factory.
        *   `pause`: Pause minting.
        *   `unpause`: Unpause minting.
        *   `setWithdrawalAddress`: Set address to receive funds.
        *   `withdraw`: Withdraw accumulated funds.
        *   `setBaseURI`: Set the base URL for token metadata.
    *   **Model Management (onlyOwner):**
        *   `addGenerationModel`: Register a new generative model.
        *   `updateGenerationModelConfig`: Change cost, supply, active status of a model.
        *   `updateGenerationModelBaseParams`: Update the default/base parameters for a model.
        *   `toggleGenerationModelActive`: Activate or deactivate a model.
    *   **Minting (payable, whenNotPaused):**
        *   `mintRandomModel`: Mint from a randomly selected active model.
        *   `mintSpecificModel`: Mint from a specified model ID using default parameters.
        *   `mintWithParameters`: Mint from a specified model ID allowing the user to influence parameters within bounds.
    *   **Query Functions (view):**
        *   `getGenerationModel`: Get configuration details of a model.
        *   `getAllGenerationModelIds`: Get a list of all registered model IDs.
        *   `getModelSupply`: Get minted count for a specific model.
        *   `getTotalSupply`: Get total minted count across all models.
        *   `tokenModelId`: Get the model ID for a given token ID.
        *   `getTokenParameters`: Get the *specific* generated parameters for a given token ID.
        *   `getBaseURI`: Get the current base URI.
        *   `getFactoryState`: Get factory pause status and withdrawal address.
        *   `previewGenerateParameters`: Simulate parameter generation for a model without minting (helpful for UIs).
        *   `getModelParametersDefinition`: Get information about the expected parameter structure for a model (e.g., types, ranges).
    *   **Other:**
        *   `burn`: Allow owner to burn a token (optional, could be for cleanup).

---

## Function Summary:

1.  `constructor(string name, string symbol, address initialOwner, address initialWithdrawalAddress)`: Initializes the ERC721 contract with name, symbol, sets owner, and sets the initial withdrawal address.
2.  `pause()`: Owner can pause minting functions.
3.  `unpause()`: Owner can unpause minting functions.
4.  `setWithdrawalAddress(address payable newWithdrawalAddress)`: Owner can change the address where withdrawn funds are sent.
5.  `withdraw()`: Owner can withdraw accumulated Ether from minting.
6.  `setBaseURI(string memory newBaseURI)`: Owner can set the base URI for `tokenURI` (e.g., pointing to an API endpoint that serves metadata based on token ID and parameters).
7.  `addGenerationModel(string memory name, string memory description, uint256 mintCost, uint256 maxSupply, bytes memory baseParamsDefinition, bytes memory defaultGeneratedParams)`: Owner adds a new generative model with its configuration, a definition of its parameters, and default values. Returns the new model ID.
8.  `updateGenerationModelConfig(uint256 modelId, uint256 mintCost, uint256 maxSupply)`: Owner updates the mutable configuration (cost, supply) of an existing model.
9.  `updateGenerationModelBaseParams(uint256 modelId, bytes memory newBaseParamsDefinition)`: Owner updates the definition of parameters for an existing model. *Note: This affects interpretation of existing tokens for this model.*
10. `updateGenerationModelDefaultGeneratedParams(uint256 modelId, bytes memory newDefaultParams)`: Owner updates the default parameters used for generation if no user input is provided.
11. `toggleGenerationModelActive(uint256 modelId, bool active)`: Owner activates or deactivates a generation model, affecting whether it can be minted from.
12. `mintRandomModel()`: User pays the required Ether to mint a token from a randomly selected *active* generation model that still has supply.
13. `mintSpecificModel(uint256 modelId)`: User pays the cost for a specific model ID to mint a token using its default generation parameters.
14. `mintWithParameters(uint256 modelId, bytes memory userInfluenceParams)`: User pays the cost for a specific model ID and provides `userInfluenceParams` (encoded bytes) to guide the generation logic. Validation happens within `_generateTokenData`.
15. `getGenerationModel(uint256 modelId)`: Public view function to get details of a specific generation model.
16. `getAllGenerationModelIds()`: Public view function to get an array of all registered generation model IDs.
17. `getModelSupply(uint256 modelId)`: Public view function to get the current number of tokens minted for a specific model.
18. `getTotalSupply()`: Public view function to get the total number of NFTs minted across all models. (Uses ERC721's `_tokenIdCounter.current() - 1`).
19. `tokenModelId(uint256 tokenId)`: Public view function to get the model ID used to generate a specific token.
20. `getTokenParameters(uint256 tokenId)`: Public view function to get the *specific* parameters generated and stored on-chain for a given token ID.
21. `getBaseURI()`: Public view function to get the current base URI for metadata.
22. `getFactoryState()`: Public view function to get the current pause status and withdrawal address of the factory.
23. `previewGenerateParameters(uint256 modelId, uint256 seed, bytes memory userInfluenceParams)`: Public view function to simulate the parameter generation process for a given model, seed, and user input without actually minting. Useful for previewing.
24. `getModelParametersDefinition(uint256 modelId)`: Public view function to retrieve the definition bytes that describe the expected parameter structure for a model.
25. `burn(uint256 tokenId)`: Owner can burn a specific token.
26. `tokenURI(uint256 tokenId)`: ERC721 override. Returns the metadata URI for a token, constructing it from the `_baseURI` and token ID. The off-chain service at `_baseURI` would ideally use `getTokenParameters(tokenId)` to generate the actual JSON metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title GenerativeNFTFactory
/// @dev A factory contract that mints ERC721 tokens based on configurable generative models.
///      Each token stores its specific generation parameters on-chain.
///      Supports multiple generative models with different costs, supplies, and parameter types.
contract GenerativeNFTFactory is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Error Definitions ---
    error GenerativeNFTFactory__AlreadyPaused();
    error GenerativeNFTFactory__NotPaused();
    error GenerativeNFTFactory__InsufficientPayment(uint256 required, uint256 sent);
    error GenerativeNFTFactory__WithdrawalFailed();
    error GenerativeNFTFactory__ModelNotFound(uint256 modelId);
    error GenerativeNFTFactory__ModelNotActive(uint256 modelId);
    error GenerativeNFTFactory__ModelSupplyExceeded(uint256 modelId, uint256 maxSupply);
    error GenerativeNFTFactory__InvalidModelId();
    error GenerativeNFTFactory__MaxTotalSupplyExceeded(uint256 maxSupply);
    error GenerativeNFTFactory__TokenNotFound(uint256 tokenId);
    error GenerativeNFTFactory__InvalidUserParameters(uint256 modelId);
    error GenerativeNFTFactory__UnauthorizedBurn();

    // --- Structs ---

    /// @dev Defines a template for generating NFTs.
    struct GenerationModel {
        string name;
        string description;
        uint256 mintCost;      // Cost in Wei to mint from this model
        uint256 maxSupply;     // Max number of tokens for this model (0 for unlimited)
        bool active;           // Is this model available for minting?
        bytes baseParamsDefinition; // Defines the structure/types/ranges expected for parameters (e.g., abi.encodePacked(uint8, uint16, bytes32))
        bytes defaultGeneratedParams; // Default generated parameters if no user input is provided
    }

    /// @dev Stores the unique, generated parameters for a specific NFT token.
    struct TokenParameters {
        bytes params; // The specific generated parameters for this token (structure defined by model.baseParamsDefinition)
        uint256 generationSeed; // The seed used for generation (e.g., block.timestamp, block.difficulty)
        // Add more fields here if generation depends on other factors (e.g., minter address, other tokens)
    }

    // --- State Variables ---

    Counters.Counter private _modelIdCounter; // Counter for assigning unique model IDs
    mapping(uint256 => GenerationModel) private _generationModels; // Stores generative model configurations
    uint256[] private _modelIds; // Array to keep track of all registered model IDs (for iteration/query)

    Counters.Counter private _tokenIdCounter; // ERC721 token counter (starts at 1, 0 is unassigned)
    mapping(uint256 => uint256) private _tokenModelId; // Maps token ID to the model ID used for generation
    mapping(uint256 => TokenParameters) private _tokenParameters; // Maps token ID to its specific generated parameters

    mapping(uint256 => uint256) private _modelSupply; // Tracks current minted supply per model

    bool private _paused; // Factory pause status

    address payable private _withdrawalAddress; // Address to send collected funds

    string private _baseURI; // Base URI for token metadata (e.g., an API endpoint)

    // --- Events ---

    event ModelAdded(uint256 indexed modelId, string name, uint256 mintCost, uint256 maxSupply);
    event ModelConfigUpdated(uint256 indexed modelId, uint256 newMintCost, uint256 newMaxSupply);
    event ModelBaseParamsUpdated(uint256 indexed modelId, bytes newBaseParamsDefinition);
    event ModelDefaultParamsUpdated(uint256 indexed modelId, bytes newDefaultParams);
    event ModelToggled(uint256 indexed modelId, bool active);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed modelId, address indexed minter, bytes generatedParams);
    event Withdrawal(address indexed to, uint256 amount);
    event FactoryPaused();
    event FactoryUnpaused();
    event BaseURIUpdated(string newBaseURI);

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (_paused) revert GenerativeNFTFactory__AlreadyPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert GenerativeNFTFactory__NotPaused();
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialOwner, address payable initialWithdrawalAddress)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {
        _withdrawalAddress = initialWithdrawalAddress;
        _tokenIdCounter.increment(); // Start token IDs from 1, 0 is reserved/unassigned
    }

    // --- Factory Management ---

    /// @dev Pauses minting functions. Only owner can call.
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit FactoryPaused();
    }

    /// @dev Unpauses minting functions. Only owner can call.
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit FactoryUnpaused();
    }

    /// @dev Sets the address where withdrawn funds are sent. Only owner can call.
    /// @param newWithdrawalAddress The new withdrawal address.
    function setWithdrawalAddress(address payable newWithdrawalAddress) external onlyOwner {
        _withdrawalAddress = newWithdrawalAddress;
    }

    /// @dev Allows the owner to withdraw accumulated Ether.
    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = _withdrawalAddress.call{value: balance}("");
            if (!success) revert GenerativeNFTFactory__WithdrawalFailed();
            emit Withdrawal(_withdrawalAddress, balance);
        }
    }

    /// @dev Sets the base URI for token metadata. This URI will be appended with the token ID.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // --- Model Management (Owner Only) ---

    /// @dev Adds a new generative model to the factory.
    /// @param name The name of the model.
    /// @param description A description of the model's style/parameters.
    /// @param mintCost The cost in Wei to mint from this model.
    /// @param maxSupply The maximum number of tokens for this model (0 for unlimited).
    /// @param baseParamsDefinition Bytes defining the structure/types of parameters for this model (e.g., abi.encodePacked(uint8, uint16)).
    /// @param defaultGeneratedParams Bytes containing the default parameters to use if mintWithParameters is not used or user input is ignored.
    /// @return modelId The ID of the newly added model.
    function addGenerationModel(
        string memory name,
        string memory description,
        uint256 mintCost,
        uint256 maxSupply,
        bytes memory baseParamsDefinition,
        bytes memory defaultGeneratedParams
    ) external onlyOwner returns (uint256 modelId) {
        _modelIdCounter.increment();
        modelId = _modelIdCounter.current();

        _generationModels[modelId] = GenerationModel({
            name: name,
            description: description,
            mintCost: mintCost,
            maxSupply: maxSupply,
            active: true, // New models are active by default
            baseParamsDefinition: baseParamsDefinition,
            defaultGeneratedParams: defaultGeneratedParams
        });
        _modelIds.push(modelId); // Add to the array for easier iteration

        emit ModelAdded(modelId, name, mintCost, maxSupply);
    }

    /// @dev Updates the configuration details of an existing generation model.
    /// @param modelId The ID of the model to update.
    /// @param newMintCost The new minting cost.
    /// @param newMaxSupply The new maximum supply (0 for unlimited).
    function updateGenerationModelConfig(
        uint256 modelId,
        uint256 newMintCost,
        uint256 newMaxSupply
    ) external onlyOwner {
        GenerationModel storage model = _generationModels[modelId];
        if (bytes(model.name).length == 0) revert GenerativeNFTFactory__ModelNotFound(modelId); // Check if model exists

        model.mintCost = newMintCost;
        model.maxSupply = newMaxSupply;

        emit ModelConfigUpdated(modelId, newMintCost, newMaxSupply);
    }

    /// @dev Updates the base parameter definition for an existing generation model.
    ///      NOTE: Changing this affects how parameters for *all* tokens of this model are interpreted.
    /// @param modelId The ID of the model to update.
    /// @param newBaseParamsDefinition The new base parameter definition bytes.
    function updateGenerationModelBaseParams(
        uint256 modelId,
        bytes memory newBaseParamsDefinition
    ) external onlyOwner {
        GenerationModel storage model = _generationModels[modelId];
         if (bytes(model.name).length == 0) revert GenerativeNFTFactory__ModelNotFound(modelId);

        model.baseParamsDefinition = newBaseParamsDefinition;

        emit ModelBaseParamsUpdated(modelId, newBaseParamsDefinition);
    }

    /// @dev Updates the default generated parameters for an existing generation model.
    /// @param modelId The ID of the model to update.
    /// @param newDefaultParams Bytes containing the new default parameters.
     function updateGenerationModelDefaultGeneratedParams(
        uint256 modelId,
        bytes memory newDefaultParams
    ) external onlyOwner {
        GenerationModel storage model = _generationModels[modelId];
         if (bytes(model.name).length == 0) revert GenerativeNFTFactory__ModelNotFound(modelId);

        model.defaultGeneratedParams = newDefaultParams;

        emit ModelDefaultParamsUpdated(modelId, newDefaultParams);
    }

    /// @dev Toggles the active status of a generation model. Inactive models cannot be minted from.
    /// @param modelId The ID of the model to toggle.
    /// @param active The new active status (true to activate, false to deactivate).
    function toggleGenerationModelActive(uint256 modelId, bool active) external onlyOwner {
        GenerationModel storage model = _generationModels[modelId];
         if (bytes(model.name).length == 0) revert GenerativeNFTFactory__ModelNotFound(modelId);

        model.active = active;

        emit ModelToggled(modelId, active);
    }

    // --- Minting (Payable, Not Paused) ---

    /// @dev Mints an NFT from a randomly selected active model that still has supply.
    ///      Requires payment equal to the chosen model's mint cost.
    function mintRandomModel() external payable whenNotPaused nonReentrant {
        uint256[] memory activeModelIds = new uint256[](_modelIds.length);
        uint256 activeCount = 0;

        // Find active models with supply available
        for (uint256 i = 0; i < _modelIds.length; i++) {
            uint256 currentModelId = _modelIds[i];
            GenerationModel storage model = _generationModels[currentModelId];
            if (model.active && (model.maxSupply == 0 || _modelSupply[currentModelId] < model.maxSupply)) {
                 activeModelIds[activeCount] = currentModelId;
                 activeCount++;
            }
        }

        if (activeCount == 0) revert GenerativeNFTFactory__InvalidModelId(); // No active models available

        // Select a random model ID
        // WARNING: Using block.timestamp and block.difficulty/blockhash is NOT cryptographically secure randomness.
        // For production, use Chainlink VRF or similar.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, activeCount)));
        uint256 selectedModelId = activeModelIds[randomSeed % activeCount];

        // Proceed to mint using the selected model ID
        _mint(selectedModelId, bytes("")); // Pass empty bytes for user influence, use default logic
    }


    /// @dev Mints an NFT from a specific model using its default parameters.
    ///      Requires payment equal to the specified model's mint cost.
    /// @param modelId The ID of the model to mint from.
    function mintSpecificModel(uint256 modelId) external payable whenNotPaused nonReentrant {
        _mint(modelId, bytes("")); // Pass empty bytes for user influence, use default logic
    }

    /// @dev Mints an NFT from a specific model, allowing the minter to influence parameters.
    ///      Requires payment equal to the specified model's mint cost.
    /// @param modelId The ID of the model to mint from.
    /// @param userInfluenceParams Bytes containing parameters provided by the user.
    ///      The structure and validation of these bytes depend on the specific model's definition.
    function mintWithParameters(uint256 modelId, bytes memory userInfluenceParams) external payable whenNotPaused nonReentrant {
        _mint(modelId, userInfluenceParams);
    }

    /// @dev Internal helper function to perform the actual minting logic.
    /// @param modelId The ID of the model to use.
    /// @param userInfluenceParams Bytes containing user-provided parameters (can be empty).
    function _mint(uint256 modelId, bytes memory userInfluenceParams) internal {
        GenerationModel storage model = _generationModels[modelId];

        // --- Validation ---
        if (bytes(model.name).length == 0) revert GenerativeNFTFactory__ModelNotFound(modelId);
        if (!model.active) revert GenerativeNFTFactory__ModelNotActive(modelId);
        if (msg.value < model.mintCost) revert GenerativeNFTFactory__InsufficientPayment(model.mintCost, msg.value);
        if (model.maxSupply > 0 && _modelSupply[modelId] >= model.maxSupply) revert GenerativeNFTFactory__ModelSupplyExceeded(modelId, model.maxSupply);
        // ERC721 _safeMint handles check for total supply limit implicitly by requiring current < type(uint256).max

        // --- Minting ---
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // --- Parameter Generation ---
        // WARNING: Basic seed generation. For production, use Chainlink VRF or similar.
        // For deterministic generation based purely on user input, remove block hash/timestamp.
        uint256 generationSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, userInfluenceParams)));
        bytes memory generatedParams = _generateTokenData(modelId, generationSeed, userInfluenceParams);

        // --- Store Data ---
        _tokenModelId[newTokenId] = modelId;
        _tokenParameters[newTokenId] = TokenParameters({
            params: generatedParams,
            generationSeed: generationSeed
            // Add other fields here if needed
        });
        _modelSupply[modelId]++;

        // --- Mint ERC721 Token ---
        _safeMint(msg.sender, newTokenId);

        // --- Emit Event ---
        emit NFTMinted(newTokenId, modelId, msg.sender, generatedParams);

        // --- Handle Excess Payment ---
        if (msg.value > model.mintCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - model.mintCost}("");
            require(success, "Refund failed"); // Refund excess ETH
        }
    }

    /// @dev Internal function containing the core generative logic.
    ///      This is where the parameters for a specific token are determined
    ///      based on the model, a seed, and potentially user input.
    ///      Implement complex, deterministic or pseudo-random logic here.
    /// @param modelId The ID of the model being used.
    /// @param seed A seed value for randomness.
    /// @param userInfluenceParams User provided parameters (can be empty bytes).
    /// @return bytes The generated parameters for the token. Structure should match model's baseParamsDefinition.
    function _generateTokenData(uint256 modelId, uint256 seed, bytes memory userInfluenceParams) internal view returns (bytes memory) {
        // IMPORTANT: This is a simplified placeholder.
        // A real generative process would live here or be computed off-chain deterministically
        // based on these inputs. The complexity depends on the art/data being generated.
        // The return bytes should conform to the structure defined by the model's baseParamsDefinition.

        GenerationModel storage model = _generationModels[modelId];

        bytes memory finalParams;

        // Example Logic: If user provides params, attempt to use them; otherwise use defaults or seed.
        // A real implementation would need complex logic to parse/validate userInfluenceParams
        // against model.baseParamsDefinition and potentially combine with seed/defaults.

        if (userInfluenceParams.length > 0) {
             // Placeholder: In a real contract, you'd validate userInfluenceParams against model.baseParamsDefinition
             // For demonstration, we'll just check if it matches the expected size (basic validation)
             if (userInfluenceParams.length != model.defaultGeneratedParams.length && model.defaultGeneratedParams.length > 0) {
                  // Basic check: If default params exist, user params should match length
                  // More complex validation (e.g., value ranges) required in a real scenario
                 revert GenerativeNFTFactory__InvalidUserParameters(modelId);
             }
             // Use user provided parameters if valid
            finalParams = userInfluenceParams;
        } else {
             // Use default generated parameters if no user input
             finalParams = model.defaultGeneratedParams;
        }

        // Example: If the params bytes are meant to represent a uint256 color,
        // you might combine the seed with the default/user input.
        // uint256 colorParam = abi.decode(finalParams, (uint256)); // Example decoding
        // colorParam = (colorParam + seed) % (2**24); // Example modification using seed
        // finalParams = abi.encode(colorParam); // Example encoding back

        // For this placeholder, we'll just return the selected params (user or default).
        // A production contract would use the seed to add randomness or derive features
        // from the default/user params according to the model's logic.
        // The `seed` is stored on-chain for reproducibility off-chain.

        return finalParams;
    }


    // --- Query Functions (View) ---

    /// @dev Gets the configuration details of a specific generation model.
    /// @param modelId The ID of the model.
    /// @return name, description, mintCost, maxSupply, active, baseParamsDefinition, defaultGeneratedParams
    function getGenerationModel(uint256 modelId) external view returns (
        string memory name,
        string memory description,
        uint256 mintCost,
        uint256 maxSupply,
        bool active,
        bytes memory baseParamsDefinition,
        bytes memory defaultGeneratedParams
    ) {
        GenerationModel storage model = _generationModels[modelId];
        if (bytes(model.name).length == 0 && modelId != 0) revert GenerativeNFTFactory__ModelNotFound(modelId); // ModelId 0 is invalid/non-existent but mapping read won't revert

        return (
            model.name,
            model.description,
            model.mintCost,
            model.maxSupply,
            model.active,
            model.baseParamsDefinition,
            model.defaultGeneratedParams
        );
    }

     /// @dev Gets information about the state of the factory.
     /// @return paused The pause status.
     /// @return withdrawalAddress The address for withdrawals.
     /// @return modelCount The total number of registered models.
    function getFactoryState() external view returns (bool paused, address withdrawalAddress, uint256 modelCount) {
        return (_paused, _withdrawalAddress, _modelIds.length);
    }

    /// @dev Gets an array of all registered generation model IDs.
    /// @return modelIds An array of model IDs.
    function getAllGenerationModelIds() external view returns (uint256[] memory) {
        return _modelIds;
    }

    /// @dev Gets the current minted supply for a specific model.
    /// @param modelId The ID of the model.
    /// @return supply The current supply for the model.
    function getModelSupply(uint256 modelId) external view returns (uint256 supply) {
         if (bytes(_generationModels[modelId].name).length == 0 && modelId != 0) revert GenerativeNFTFactory__ModelNotFound(modelId);
        return _modelSupply[modelId];
    }

    /// @dev Gets the total minted supply across all models.
    /// @return total The total supply.
    function getTotalSupply() external view returns (uint256 total) {
        // _tokenIdCounter starts at 1, so current()-1 is the number of tokens minted
        return _tokenIdCounter.current() > 0 ? _tokenIdCounter.current() - 1 : 0;
    }

    /// @dev Gets the model ID used to generate a specific token.
    /// @param tokenId The ID of the token.
    /// @return modelId The model ID.
    function tokenModelId(uint256 tokenId) external view returns (uint256 modelId) {
        _requireMinted(tokenId); // Validate token exists
        return _tokenModelId[tokenId];
    }

    /// @dev Gets the specific generated parameters stored on-chain for a token.
    ///      This is the core data point for rendering the unique generative output off-chain.
    /// @param tokenId The ID of the token.
    /// @return params The generated parameters bytes.
    /// @return generationSeed The seed used for generation.
    function getTokenParameters(uint256 tokenId) external view returns (bytes memory params, uint256 generationSeed) {
         _requireMinted(tokenId); // Validate token exists
        TokenParameters storage tokenData = _tokenParameters[tokenId];
        return (tokenData.params, tokenData.generationSeed);
    }

    /// @dev Gets the current base URI for token metadata.
    /// @return baseURI The base URI string.
    function getBaseURI() external view returns (string memory) {
        return _baseURI;
    }

     /// @dev Gets the base parameter definition bytes for a specific model.
     /// @param modelId The ID of the model.
     /// @return baseParamsDefinition The bytes defining the expected structure/types of parameters.
     function getModelParametersDefinition(uint256 modelId) external view returns (bytes memory baseParamsDefinition) {
         GenerationModel storage model = _generationModels[modelId];
         if (bytes(model.name).length == 0 && modelId != 0) revert GenerativeNFTFactory__ModelNotFound(modelId);
         return model.baseParamsDefinition;
     }

     /// @dev Simulates the parameter generation process for a model and inputs without minting.
     ///      Useful for frontends to preview potential outcomes.
     ///      NOTE: The seed used here is arbitrary for simulation purposes; a real mint uses block data.
     /// @param modelId The ID of the model.
     /// @param seed An arbitrary seed for simulation.
     /// @param userInfluenceParams Optional user-provided parameters for simulation.
     /// @return generatedParams The simulated generated parameters bytes.
     function previewGenerateParameters(uint256 modelId, uint256 seed, bytes memory userInfluenceParams) external view returns (bytes memory generatedParams) {
         GenerationModel storage model = _generationModels[modelId];
         if (bytes(model.name).length == 0 && modelId != 0) revert GenerativeNFTFactory__ModelNotFound(modelId);
         // Pass inputs to the internal generation logic.
         // Note: The internal logic might still use block data if implemented that way,
         // which would make previews non-deterministic relative to future block data.
         // For a true deterministic preview, the internal logic should *only* use seed and userInfluenceParams.
         return _generateTokenData(modelId, seed, userInfluenceParams);
     }


    // --- Other ---

    /// @dev Allows the owner to burn a token. Use with caution.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) external onlyOwner {
        // _burn checks if token exists and if sender is owner/approved (owner modifier handles owner check)
        _burn(tokenId);

        // Clean up storage (optional but good practice for state variables we added)
        uint256 modelId = _tokenModelId[tokenId];
        delete _tokenParameters[tokenId];
        delete _tokenModelId[tokenId];
        // Decrement model supply
        if (_modelSupply[modelId] > 0) {
            _modelSupply[modelId]--;
        }
        // Total supply is managed by _tokenIdCounter in OpenZeppelin's ERC721,
        // _burn internally handles its own supply tracking/counter,
        // but our _tokenIdCounter is just an ever-increasing ID.
        // So we don't decrement _tokenIdCounter here.
    }

    // --- ERC721 Overrides ---

    /// @dev See {ERC721-tokenURI}.
    ///      Returns the base URI + token ID. An off-chain service should use
    ///      `getTokenParameters(tokenId)` to fetch the unique data and generate metadata JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId); // Ensure token exists before returning URI
        if (bytes(_baseURI).length == 0) {
             // Optional: return a default URI or error if base URI is not set
             return ""; // Or revert("Base URI not set");
        }
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

     /// @dev Helper function to check if a token ID has been minted.
     ///      Used internally and by external view functions that require a valid token.
     function _requireMinted(uint256 tokenId) internal view {
         // Check if token exists (ownerOf will revert if not)
         // Also check if token ID is 0, which is used as an unassigned/invalid state
         if (tokenId == 0 || super.ownerOf(tokenId) == address(0)) {
             revert GenerativeNFTFactory__TokenNotFound(tokenId);
         }
     }

    // --- Standard ERC721 Functions (Inherited) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(address,address,uint256), safeTransferFrom(address,address,uint256,bytes)
    // These are provided by OpenZeppelin and are part of the contract's capabilities.
    // We explicitly override tokenURI and add custom logic on top.
}
```