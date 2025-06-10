Okay, here is a Solidity smart contract based on the concept of "Generative Asset Alchemy". This contract allows users to mint initial assets with unique on-chain attributes (elemental composition) and then combine (alchemize) existing assets to create new ones, whose attributes are derived from the inputs using configurable formulas. The assets are ERC721 tokens, and their metadata dynamically reflects their current on-chain state. It includes features like configurable costs, cooldowns, rarity calculation based on attributes, and even a function to predict alchemy outcomes without executing the transaction.

It aims for complexity and creativity through:
1.  **On-chain Generative Attributes:** Assets have structured elemental compositions stored directly on-chain.
2.  **Deterministic Alchemy:** Combining assets follows specific, owner-configurable formulas based on input compositions.
3.  **Dynamic Metadata:** `tokenURI` reflects the current on-chain elemental composition and rarity.
4.  **Prediction Function:** Users can preview alchemy results.
5.  **Configurable System:** Many parameters (formulas, costs, cooldowns, rarity weights) are owner-controlled, allowing for evolving game mechanics.
6.  **Asset Evolution/Degradation:** Assets have a "generation" counter and a cooldown, implicitly affecting their lifecycle.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
//
// Contract Name: GenerativeAssetAlchemy
// Purpose: An ERC721 contract for managing generative digital assets with elemental compositions.
// Users can mint initial assets and combine (alchemize) existing assets based on on-chain formulas
// to create new, evolved assets. Asset attributes (composition, rarity) are stored on-chain
// and influence dynamic metadata.
//
// State Variables:
// - _elementTypes: Array of strings representing element names (e.g., "Fire", "Water").
// - _assets: Mapping from tokenId to Asset struct, storing on-chain attributes.
// - _initialMintConfig: Configuration for minting initial assets.
// - _alchemyConfig: Configuration for the alchemy process.
// - _rarityWeights: Weights for calculating rarity based on elements and generation.
// - _elementalFormula: Mapping defining how input elements combine during alchemy.
// - _baseTokenURI: Base URI for metadata.
// - _paused: Contract pause state.
// - _tokenIdCounter: Counter for assigning unique token IDs.
//
// Structs:
// - Asset: Stores on-chain attributes for each token (composition, rarity, generation, lastAlchemizedBlock, creationSeed).
// - InitialMintConfig: Price and enabled status for initial minting.
// - AlchemyConfig: Cost (ETH), minimum inputs, cooldown (in blocks), enabled status for alchemy.
//
// Enums:
// - ErrorCode: Enum for specific error types during alchemy prediction.
//
// Events:
// - InitialAssetMinted: Emitted when a new initial asset is minted.
// - AssetsAlchemized: Emitted when assets are successfully alchemized into a new one.
// - InitialMintConfigUpdated: Emitted when initial minting config changes.
// - AlchemyConfigUpdated: Emitted when alchemy config changes.
// - ElementalFormulaUpdated: Emitted when the alchemy formula changes.
// - RarityWeightsUpdated: Emitted when rarity calculation weights change.
// - BaseTokenURIUpdated: Emitted when the base token URI is updated.
// - Paused / Unpaused: Standard Ownable events.
//
// Functions:
//
// --- Core ERC721 (Inherited/Overridden) ---
// 1. constructor(string name, string symbol, string[] elementNames): Initializes the contract, ERC721, and sets elements.
// 2. supportsInterface(bytes4 interfaceId): Standard interface support check.
// 3. balanceOf(address owner): Returns the number of tokens owned by an address.
// 4. ownerOf(uint256 tokenId): Returns the owner of a specific token.
// 5. approve(address to, uint256 tokenId): Grants approval for a specific token.
// 6. getApproved(uint256 tokenId): Gets the approved address for a token.
// 7. setApprovalForAll(address operator, bool approved): Sets approval for all tokens for an operator.
// 8. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
// 9. transferFrom(address from, address to, uint256 tokenId): Transfers a token (standard).
// 10. safeTransferFrom(address from, address to, uint256 tokenId): Transfers a token (safe).
// 11. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Transfers a token (safe with data).
// 12. tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a token, including on-chain attributes. (Overrides ERC721)
// 13. _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Hook executed before token transfers. (Overrides ERC721)
//
// --- Minting Functions ---
// 14. mintInitialAsset(bytes32 creationSeed) payable: Mints a new, generation-0 asset with attributes derived from the seed. Pays a fee.
// 15. setInitialMintConfig(uint256 price, bool enabled): Owner-only function to set minting price and status.
// 16. getInitialMintConfig(): View function to get the current initial mint configuration.
//
// --- Alchemy Functions ---
// 17. alchemizeAssets(uint256[] calldata inputTokenIds) payable: Combines multiple input tokens into a new one. Requires ownership/approval and payment. Burns input tokens.
// 18. predictAlchemyOutcome(uint256[] calldata inputTokenIds): View function to predict the resulting composition and rarity score of alchemy without executing it. Returns potential composition, rarity, and an error code if prediction fails (e.g., not enough inputs).
// 19. setAlchemyConfig(uint256 cost, uint256 minInputs, uint256 cooldownBlocks, bool enabled): Owner-only function to set alchemy parameters.
// 20. setElementalFormula(uint[] calldata inputElementIndices, uint[] calldata outputComposition): Owner-only function to define a specific alchemy formula mapping input element combinations to output compositions.
// 21. removeElementalFormula(uint[] calldata inputElementIndices): Owner-only function to remove a specific formula.
// 22. getAlchemyConfig(): View function to get the current alchemy configuration.
// 23. getElementalFormula(uint[] calldata inputElementIndices): View function to retrieve a specific alchemy formula.
// 24. getAlchemyCooldown(uint256 tokenId): View function to check blocks remaining until a token can be used in alchemy.
//
// --- Asset Data & Configuration Functions ---
// 25. getAssetComposition(uint256 tokenId): View function to get the elemental composition of an asset.
// 26. getAssetRarity(uint256 tokenId): View function to get the calculated rarity score of an asset.
// 27. getAssetGeneration(uint256 tokenId): View function to get the generation number of an asset.
// 28. getCreationParameters(uint256 tokenId): View function to get the creation seed/parameters of an asset.
// 29. setRarityWeights(uint[] calldata elementWeights, uint256 generationWeight): Owner-only function to set weights for rarity calculation. Must match element type count.
// 30. getRarityWeights(): View function to get the current rarity calculation weights.
// 31. setBaseTokenURI(string memory uri): Owner-only function to set the base URI for token metadata.
// 32. getBaseTokenURI(): View function to get the current base token URI.
// 33. getTokenIdsForOwner(address owner): View function to get all token IDs owned by a specific address (helper).
// 34. burnAsset(uint256 tokenId): Owner-only function to burn an asset (useful for removing problematic tokens or in dev/admin scenarios).
// 35. pause(): Owner-only function to pause the contract.
// 36. unpause(): Owner-only function to unpause the contract.
// 37. paused(): View function to check if the contract is paused.
// 38. withdraw(): Owner-only function to withdraw contract balance.
// 39. getElementTypes(): View function to get the list of defined element types.
// 40. getTotalSupply(): View function to get the total number of minted tokens.

// --- End Outline & Summary ---

contract GenerativeAssetAlchemy is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Defines the types of elements (e.g., ["Fire", "Water", "Earth", "Air"])
    string[] private _elementTypes;

    // Stores the on-chain attributes for each asset
    struct Asset {
        uint[] composition; // Percentage breakdown of elements, sums to 100
        uint rarityScore;   // Calculated score based on composition and generation
        uint generation;    // 0 for initial mints, increments after alchemy
        uint lastAlchemizedBlock; // Block number when last used in alchemy (for cooldown)
        bytes32 creationSeed; // Seed used for initial generation or alchemy derivation
    }

    mapping(uint256 => Asset) private _assets;

    // Configuration for minting new, generation-0 assets
    struct InitialMintConfig {
        uint256 price;
        bool enabled;
    }
    InitialMintConfig private _initialMintConfig;

    // Configuration for the alchemy process
    struct AlchemyConfig {
        uint256 cost;              // Cost in wei to perform alchemy
        uint256 minInputTokens;    // Minimum number of tokens required for alchemy
        uint256 cooldownBlocks;    // Number of blocks a token is on cooldown after alchemy
        bool enabled;
    }
    AlchemyConfig private _alchemyConfig;

    // Weights used for calculating rarity score (element index => weight, plus generation weight)
    // elementWeights array length must match _elementTypes.length
    struct RarityWeights {
        uint[] elementWeights;
        uint generationWeight;
    }
    RarityWeights private _rarityWeights;

    // Defines how elemental compositions combine during alchemy.
    // Mapping from a hash of input element indices (sorted) to the resulting output composition.
    // A simpler approach is to use a fixed deterministic formula based on input compositions,
    // but allowing mapping adds complexity and configurability. Let's go with a fixed formula based on weighted average + a modifier,
    // but store a *modifier* per input combination hash for advanced control.
    // The key is a keccak256 hash of sorted input token compositions. The value is a uint[] modifier.
    mapping(bytes32 => uint[]) private _elementalFormulaModifiers;

    string private _baseTokenURI;
    bool private _paused;

    // Helper mapping to get token IDs for owner (not strictly necessary but helpful for UIs)
    mapping(address => uint256[]) private _ownerTokens;

    // --- Enums ---
    enum ErrorCode {
        NoError,
        AlchemyNotEnabled,
        InsufficientInputs,
        NotOwnerOrApproved,
        OnCooldown,
        AlchemyCostTooLow,
        AssetNotFound,
        NotEnoughElements,
        WeightsMismatch
    }

    // --- Events ---

    event InitialAssetMinted(address indexed owner, uint256 indexed tokenId, uint[] composition, uint rarity, bytes32 creationSeed);
    event AssetsAlchemized(address indexed alchemist, uint256[] indexed inputTokenIds, uint256 indexed outputTokenId, uint[] outputComposition, uint outputRarity);
    event InitialMintConfigUpdated(uint256 newPrice, bool newEnabled);
    event AlchemyConfigUpdated(uint256 newCost, uint256 newMinInputs, uint256 newCooldownBlocks, bool newEnabled);
    event ElementalFormulaUpdated(bytes32 indexed formulaHash, uint[] modifier);
    event RarityWeightsUpdated(uint[] elementWeights, uint256 generationWeight);
    event BaseTokenURIUpdated(string newURI);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string[] memory elementNames)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(elementNames.length > 0, "Must define at least one element type");
        _elementTypes = elementNames;

        // Set initial default configs (can be changed by owner)
        _initialMintConfig = InitialMintConfig({ price: 0.01 ether, enabled: true });
        _alchemyConfig = AlchemyConfig({ cost: 0.005 ether, minInputTokens: 2, cooldownBlocks: 10, enabled: true });
        _rarityWeights = RarityWeights({ elementWeights: new uint[](_elementTypes.length), generationWeight: 10 }); // Default weights: 0 for elements, 10 for generation
        // Initialize element weights to 1 (can be changed by owner)
        for(uint i=0; i < _elementTypes.length; i++) {
             _rarityWeights.elementWeights[i] = 1;
        }

        _paused = false;
    }

    // --- ERC721 Overrides ---

    // ERC721 standard override for dynamic metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721MetadataURI("ERC721: URI query for nonexistent token");
        }

        string memory base = _baseTokenURI;
        if (bytes(base).length == 0) {
            return "";
        }

        // Construct dynamic URI with on-chain attributes
        // Example: baseURI/tokenId?composition=10,20,70&rarity=150&generation=1
        string memory uri = string(abi.encodePacked(base, Strings.toString(tokenId)));

        // Add query parameters for on-chain data
        uri = string(abi.encodePacked(uri, "?composition="));
        for (uint i = 0; i < _assets[tokenId].composition.length; i++) {
            uri = string(abi.encodePacked(uri, Strings.toString(_assets[tokenId].composition[i])));
            if (i < _assets[tokenId].composition.length - 1) {
                uri = string(abi.encodePacked(uri, ","));
            }
        }

        uri = string(abi.encodePacked(uri, "&rarity=", Strings.toString(_assets[tokenId].rarityScore)));
        uri = string(abi.encodePacked(uri, "&generation=", Strings.toString(_assets[tokenId].generation)));

        // Optionally add other attributes like creationSeed, lastAlchemizedBlock
        // uri = string(abi.encodePacked(uri, "&seed=", Strings.toHexString(uint256(_assets[tokenId].creationSeed))));
        // uri = string(abi.encodePacked(uri, "&lastAlchemized=", Strings.toString(_assets[tokenId].lastAlchemizedBlock)));


        return uri;
    }

    // Internal hook before transfers (used here to update _ownerTokens helper)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721) // Specify ERC721 as the base contract implementing this hook
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // --- Manual Update for _ownerTokens helper (Optional but useful) ---
        // NOTE: This is a gas-intensive operation for listing all tokens per owner.
        // For large collections, relying solely on transfer events client-side is more gas efficient.
        // Included here as requested for potentially >= 20 functions and useful queryability,
        // but acknowledge its cost implications.

        if (from != address(0)) {
             _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to != address(0)) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        // --- End Manual Update ---
    }

    // Internal helper to add token to owner's list
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        _ownerTokens[to].push(tokenId);
    }

    // Internal helper to remove token from owner's list (simple linear scan - optimize for large lists if needed)
    function _removeTokenFromOwnerEnumeration(address from, uint255 tokenId) internal {
        uint256[] storage tokenList = _ownerTokens[from];
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == tokenId) {
                // Swap the last element with the element to remove
                tokenList[i] = tokenList[tokenList.length - 1];
                // Remove the last element
                tokenList.pop();
                return;
            }
        }
        // Should not happen if _beforeTokenTransfer is called correctly
    }


    // --- Pausable ---

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() public view returns (bool) {
        return _paused;
    }


    // --- Initial Minting Functions ---

    /**
     * @notice Mints a new generation-0 asset.
     * @param creationSeed A bytes32 value used as a seed for generating initial attributes.
     */
    function mintInitialAsset(bytes32 creationSeed) public payable whenNotPaused {
        require(_initialMintConfig.enabled, "Minting is not enabled");
        require(msg.value >= _initialMintConfig.price, "Insufficient ETH sent for minting");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        uint[] memory initialComposition = _generateInitialComposition(creationSeed);
        uint rarity = _calculateRarity(initialComposition, 0); // Generation 0

        _assets[newItemId] = Asset({
            composition: initialComposition,
            rarityScore: rarity,
            generation: 0,
            lastAlchemizedBlock: 0, // Can be used immediately in alchemy
            creationSeed: creationSeed
        });

        _safeMint(msg.sender, newItemId);

        emit InitialAssetMinted(msg.sender, newItemId, initialComposition, rarity, creationSeed);
    }

    /**
     * @notice Owner-only function to set the initial minting configuration.
     * @param price The price in wei to mint an asset.
     * @param enabled Whether initial minting is enabled.
     */
    function setInitialMintConfig(uint256 price, bool enabled) public onlyOwner {
        _initialMintConfig = InitialMintConfig({ price: price, enabled: enabled });
        emit InitialMintConfigUpdated(price, enabled);
    }

    /**
     * @notice Gets the current configuration for initial minting.
     * @return price The price in wei.
     * @return enabled Whether minting is enabled.
     */
    function getInitialMintConfig() public view returns (uint256 price, bool enabled) {
        return (_initialMintConfig.price, _initialMintConfig.enabled);
    }

    // --- Alchemy Functions ---

    /**
     * @notice Combines multiple input assets into a single new asset.
     * Input tokens are burned. A fee is required.
     * @param inputTokenIds An array of token IDs to be combined.
     */
    function alchemizeAssets(uint256[] calldata inputTokenIds) public payable whenNotPaused {
        require(_alchemyConfig.enabled, "Alchemy is not enabled");
        require(inputTokenIds.length >= _alchemyConfig.minInputTokens, "Not enough input tokens");
        require(msg.value >= _alchemyConfig.cost, "Insufficient ETH sent for alchemy cost");

        // Check ownership/approval and cooldown for all input tokens
        for (uint i = 0; i < inputTokenIds.length; i++) {
            uint256 tokenId = inputTokenIds[i];
            address owner = ownerOf(tokenId); // Will revert if token does not exist

            require(owner == msg.sender || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender,
                "Not owner or approved for token");
            require(block.number >= _assets[tokenId].lastAlchemizedBlock + _alchemyConfig.cooldownBlocks,
                "Token is on cooldown");
        }

        // --- Alchemy Logic ---
        // 1. Calculate the new elemental composition based on inputs and formulas.
        // A simple deterministic method: average compositions and apply a potential modifier.
        uint[] memory newComposition = _deriveCompositionFromInputs(inputTokenIds);
        uint newGeneration = 0;
        bytes32 newCreationSeed = keccak256(abi.encodePacked(inputTokenIds)); // Seed based on input token IDs

        // Find max generation + 1 among inputs
        for (uint i = 0; i < inputTokenIds.length; i++) {
            if (_assets[inputTokenIds[i]].generation + 1 > newGeneration) {
                 newGeneration = _assets[inputTokenIds[i]].generation + 1;
            }
        }

        uint newRarity = _calculateRarity(newComposition, newGeneration);

        // 2. Mint the new asset
        _tokenIdCounter.increment();
        uint256 outputTokenId = _tokenIdCounter.current();

         _assets[outputTokenId] = Asset({
            composition: newComposition,
            rarityScore: newRarity,
            generation: newGeneration,
            lastAlchemizedBlock: block.number, // New asset starts cooldown immediately
            creationSeed: newCreationSeed
        });

        _safeMint(msg.sender, outputTokenId);

        // 3. Burn the input assets
        for (uint i = 0; i < inputTokenIds.length; i++) {
             uint256 tokenIdToBurn = inputTokenIds[i];
             // Clear approval before burning (good practice)
             approve(address(0), tokenIdToBurn);
             // Burn the token - OpenZeppelin's _burn handles ERC721 state updates
            _burn(tokenIdToBurn);
        }

        emit AssetsAlchemized(msg.sender, inputTokenIds, outputTokenId, newComposition, newRarity);
    }

    /**
     * @notice Predicts the outcome (composition and rarity) of alchemizing specific assets without executing the transaction.
     * Does NOT check ownership, approval, cooldown, or cost. Use this for UI previews.
     * Returns an error code if prediction inputs are invalid (e.g., not enough tokens, invalid token IDs).
     * @param inputTokenIds An array of token IDs to predict the outcome for.
     * @return predictedComposition The potential resulting elemental composition.
     * @return predictedRarityScore The potential resulting rarity score.
     * @return errorCode An error code indicating why prediction might fail based on inputs.
     */
    function predictAlchemyOutcome(uint256[] calldata inputTokenIds) public view returns (uint[] memory predictedComposition, uint predictedRarityScore, ErrorCode errorCode) {
        if (inputTokenIds.length < _alchemyConfig.minInputTokens) {
            return (new uint[](0), 0, ErrorCode.InsufficientInputs);
        }

        // Check if all input tokens exist
        for (uint i = 0; i < inputTokenIds.length; i++) {
            if (!_exists(inputTokenIds[i])) {
                return (new uint[](0), 0, ErrorCode.AssetNotFound);
            }
        }

        // --- Prediction Logic (Mirrors alchemy logic without state changes) ---
        uint[] memory predictedComp = _deriveCompositionFromInputs(inputTokenIds);

        uint predictedGen = 0;
        for (uint i = 0; i < inputTokenIds.length; i++) {
             if (_assets[inputTokenIds[i]].generation + 1 > predictedGen) {
                 predictedGen = _assets[inputTokenIds[i]].generation + 1;
             }
        }

        uint predictedRarity = _calculateRarity(predictedComp, predictedGen);

        return (predictedComp, predictedRarity, ErrorCode.NoError);
    }

    /**
     * @notice Owner-only function to set the alchemy configuration.
     * @param cost The cost in wei to perform alchemy.
     * @param minInputs The minimum number of tokens required.
     * @param cooldownBlocks The number of blocks a token is on cooldown after use.
     * @param enabled Whether alchemy is enabled.
     */
    function setAlchemyConfig(uint256 cost, uint256 minInputs, uint256 cooldownBlocks, bool enabled) public onlyOwner {
        _alchemyConfig = AlchemyConfig({
            cost: cost,
            minInputTokens: minInputs,
            cooldownBlocks: cooldownBlocks,
            enabled: enabled
        });
        emit AlchemyConfigUpdated(cost, minInputs, cooldownBlocks, enabled);
    }

     /**
     * @notice Owner-only function to set a specific elemental formula modifier.
     * The inputElementIndices represent a unique combination of element index presence/absence
     * across the input tokens. This allows defining special reactions for specific mixes.
     * Example: If elements are [Fire, Water, Earth], a hash of [0, 1] (Fire and Water present)
     * could map to a modifier [0, 0, 20] adding 20% Earth.
     * A more robust system might hash the *sorted* indices of elements present above a certain threshold.
     * For this example, let's use a simpler approach: hash the *sorted unique element indices* present in the *total aggregated composition* of inputs above 0%.
     * The `outputComposition` here acts as a *modifier* added to the base averaged composition.
     * @param inputElementIndices The sorted unique indices of elements (0 to _elementTypes.length - 1) that *must* be present in the combined inputs (above 0%) for this formula to apply.
     * @param modifierComposition The composition modifier to add if this formula matches. Length must match _elementTypes.length.
     */
    function setElementalFormula(uint[] calldata inputElementIndices, uint[] calldata modifierComposition) public onlyOwner {
        require(modifierComposition.length == _elementTypes.length, "Modifier composition length mismatch");
        // Simple check that input indices are valid and sorted
        uint lastIndex = 0;
        for(uint i = 0; i < inputElementIndices.length; i++) {
            require(inputElementIndices[i] < _elementTypes.length, "Invalid element index in input");
            if (i > 0) {
                require(inputElementIndices[i] > lastIndex, "Input indices must be sorted and unique");
            }
            lastIndex = inputElementIndices[i];
        }

        bytes32 formulaHash = keccak256(abi.encodePacked(inputElementIndices));
        _elementalFormulaModifiers[formulaHash] = modifierComposition;

        emit ElementalFormulaUpdated(formulaHash, modifierComposition);
    }

    /**
     * @notice Owner-only function to remove a specific elemental formula modifier.
     * @param inputElementIndices The sorted unique indices of elements (0 to _elementTypes.length - 1) matching the formula hash to remove.
     */
    function removeElementalFormula(uint[] calldata inputElementIndices) public onlyOwner {
         // Simple check that input indices are valid and sorted
        uint lastIndex = 0;
        for(uint i = 0; i < inputElementIndices.length; i++) {
            require(inputElementIndices[i] < _elementTypes.length, "Invalid element index in input");
            if (i > 0) {
                require(inputElementIndices[i] > lastIndex, "Input indices must be sorted and unique");
            }
            lastIndex = inputElementIndices[i];
        }
        bytes32 formulaHash = keccak256(abi.encodePacked(inputElementIndices));
        delete _elementalFormulaModifiers[formulaHash];

        emit ElementalFormulaUpdated(formulaHash, new uint[](0)); // Emit with empty modifier to signify removal
    }


    /**
     * @notice Gets the current alchemy configuration.
     * @return cost The cost in wei.
     * @return minInputs The minimum number of inputs.
     * @return cooldownBlocks The number of blocks cooldown.
     * @return enabled Whether alchemy is enabled.
     */
    function getAlchemyConfig() public view returns (uint256 cost, uint256 minInputs, uint256 cooldownBlocks, bool enabled) {
        return (_alchemyConfig.cost, _alchemyConfig.minInputTokens, _alchemyConfig.cooldownBlocks, _alchemyConfig.enabled);
    }

     /**
     * @notice Gets a specific elemental formula modifier.
     * @param inputElementIndices The sorted unique indices of elements matching the formula hash.
     * @return modifierComposition The modifier composition if found, or an empty array.
     */
    function getElementalFormula(uint[] calldata inputElementIndices) public view returns (uint[] memory modifierComposition) {
         // Simple check that input indices are valid and sorted
        uint lastIndex = 0;
        for(uint i = 0; i < inputElementIndices.length; i++) {
            require(inputElementIndices[i] < _elementTypes.length, "Invalid element index in input");
            if (i > 0) {
                require(inputElementIndices[i] > lastIndex, "Input indices must be sorted and unique");
            }
            lastIndex = inputElementIndices[i];
        }
        bytes32 formulaHash = keccak256(abi.encodePacked(inputElementIndices));
        return _elementalFormulaModifiers[formulaHash];
    }

    /**
     * @notice Gets the number of blocks remaining until a token can be used in alchemy.
     * Returns 0 if not on cooldown or token doesn't exist.
     * @param tokenId The ID of the token.
     * @return blocksRemaining The number of blocks remaining on cooldown.
     */
    function getAlchemyCooldown(uint256 tokenId) public view returns (uint256 blocksRemaining) {
        if (!_exists(tokenId)) {
            return 0;
        }
        uint lastUsed = _assets[tokenId].lastAlchemizedBlock;
        uint cooldown = _alchemyConfig.cooldownBlocks;

        if (lastUsed == 0 || block.number >= lastUsed + cooldown) {
            return 0;
        } else {
            return (lastUsed + cooldown) - block.number;
        }
    }


    // --- Asset Data & Configuration Functions ---

    /**
     * @notice Gets the elemental composition of an asset.
     * @param tokenId The ID of the token.
     * @return composition An array of uints representing percentage points for each element.
     */
    function getAssetComposition(uint256 tokenId) public view returns (uint[] memory composition) {
        require(_exists(tokenId), "Token does not exist");
        return _assets[tokenId].composition;
    }

    /**
     * @notice Gets the calculated rarity score of an asset.
     * @param tokenId The ID of the token.
     * @return rarityScore The calculated rarity score.
     */
    function getAssetRarity(uint256 tokenId) public view returns (uint256 rarityScore) {
        require(_exists(tokenId), "Token does not exist");
        return _assets[tokenId].rarityScore;
    }

    /**
     * @notice Gets the generation number of an asset.
     * @param tokenId The ID of the token.
     * @return generation The generation number.
     */
    function getAssetGeneration(uint256 tokenId) public view returns (uint256 generation) {
        require(_exists(tokenId), "Token does not exist");
        return _assets[tokenId].generation;
    }

     /**
     * @notice Gets the creation seed or parameters used for an asset.
     * @param tokenId The ID of the token.
     * @return creationSeed The bytes32 creation seed.
     */
    function getCreationParameters(uint256 tokenId) public view returns (bytes32 creationSeed) {
        require(_exists(tokenId), "Token does not exist");
        return _assets[tokenId].creationSeed;
    }

    /**
     * @notice Gets the effective age of an asset based on its last alchemized block.
     * Returns blocks since last alchemized, or blocks since creation for generation 0.
     * @param tokenId The ID of the token.
     * @return ageInBlocks The age in blocks.
     */
    function getAssetAge(uint256 tokenId) public view returns (uint256 ageInBlocks) {
        require(_exists(tokenId), "Token does not exist");
        // If lastAlchemizedBlock is 0 (initial mint), age is blocks since it was minted (assuming mint block is close to current block in this simple model)
        // A more accurate age tracking would store creation block explicitly.
        // For simplicity here, age is block.number - lastAlchemizedBlock (if > 0), else just consider it "new" or age 0 for simple cooldown logic.
        // Let's return blocks since last used in alchemy / creation.
        uint lastUsed = _assets[tokenId].lastAlchemizedBlock;
         if (lastUsed == 0) {
             // For generation 0 assets not yet used in alchemy, age is 0 in this model's context
             return 0; // Or could return blocks since mint block if stored
         } else {
             return block.number - lastUsed;
         }
    }


    /**
     * @notice Owner-only function to set weights for rarity calculation.
     * @param elementWeights An array of weights corresponding to each element type. Must match element type count.
     * @param generationWeight The weight given to the generation number.
     */
    function setRarityWeights(uint[] calldata elementWeights, uint256 generationWeight) public onlyOwner {
        require(elementWeights.length == _elementTypes.length, "Element weights length mismatch");
        _rarityWeights = RarityWeights({ elementWeights: elementWeights, generationWeight: generationWeight });
        emit RarityWeightsUpdated(elementWeights, generationWeight);
    }

    /**
     * @notice Gets the current rarity calculation weights.
     * @return elementWeights Array of weights per element.
     * @return generationWeight Weight for generation.
     */
    function getRarityWeights() public view returns (uint[] memory elementWeights, uint256 generationWeight) {
        return (_rarityWeights.elementWeights, _rarityWeights.generationWeight);
    }

    /**
     * @notice Owner-only function to set the base URI for token metadata.
     * @param uri The new base URI.
     */
    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    /**
     * @notice Gets the current base token URI.
     * @return baseURI The current base URI.
     */
    function getBaseTokenURI() public view returns (string memory baseURI) {
        return _baseTokenURI;
    }

     /**
     * @notice Gets all token IDs owned by a specific address.
     * WARNING: This can be gas-intensive for owners with many tokens. Use client-side indexing of Transfer events for better performance.
     * Included to meet the function count and provide an on-chain helper option.
     * @param owner The address to query.
     * @return tokenIds An array of token IDs owned by the address.
     */
    function getTokenIdsForOwner(address owner) public view returns (uint256[] memory tokenIds) {
        return _ownerTokens[owner];
    }

    /**
     * @notice Owner-only function to burn a specific asset.
     * @param tokenId The ID of the token to burn.
     */
    function burnAsset(uint256 tokenId) public onlyOwner {
         require(_exists(tokenId), "Token does not exist");
         // Clear approval before burning
         approve(address(0), tokenId);
         _burn(tokenId);
    }

     /**
     * @notice Owner-only function to withdraw contract balance.
     */
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    /**
     * @notice Gets the list of defined element types.
     * @return elementTypes An array of strings.
     */
    function getElementTypes() public view returns (string[] memory) {
        return _elementTypes;
    }

     /**
     * @notice Gets the total number of minted tokens.
     * @return count The total supply.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Generates an initial elemental composition for a new asset based on a seed.
     * For simplicity, this example uses the seed to deterministically generate pseudo-random percentages.
     * Ensure the total percentage is 100.
     * @param seed A bytes32 seed.
     * @return composition An array of uints summing to 100.
     */
    function _generateInitialComposition(bytes32 seed) internal view returns (uint[] memory) {
        uint numElements = _elementTypes.length;
        uint[] memory composition = new uint[](numElements);
        uint total = 0;

        // Generate pseudo-random values based on seed and block hash
        // Note: block.difficulty / blockhash are deprecated / unreliable on PoS.
        // A robust system would use VRF (Chainlink VRF) for true randomness.
        // Using simple combination here for demonstration.
        bytes32 combinedSeed = keccak256(abi.encodePacked(seed, blockhash(block.number - 1)));

        for (uint i = 0; i < numElements; i++) {
            // Use parts of the hash for values
            uint value = uint(keccak256(abi.encodePacked(combinedSeed, i)));
            // Modulo a large number, e.g., 1000, to get values for distribution
            composition[i] = value % 1000;
            total += composition[i];
        }

        // Normalize to 100%
        if (total == 0) {
             // Avoid division by zero if seed somehow results in all zeros
             // Assign equal parts if total is zero
             for(uint i = 0; i < numElements; i++) {
                 composition[i] = 100 / numElements;
             }
             // Adjust last element to ensure sum is exactly 100 if division wasn't perfect
             composition[numElements - 1] += 100 % numElements;

        } else {
             uint sumCheck = 0;
             for (uint i = 0; i < numElements; i++) {
                 composition[i] = (composition[i] * 100) / total;
                 sumCheck += composition[i];
             }
             // Adjust last element to ensure sum is exactly 100 due to integer division
             if (sumCheck != 100) {
                 composition[numElements - 1] += (100 - sumCheck);
             }
        }

        return composition;
    }

    /**
     * @dev Derives the elemental composition of a new asset from the input assets during alchemy.
     * Simple logic: Calculate average composition and apply a modifier based on a matching formula.
     * @param inputTokenIds Array of token IDs being alchemized.
     * @return newComposition The resulting elemental composition.
     */
    function _deriveCompositionFromInputs(uint256[] memory inputTokenIds) internal view returns (uint[] memory newComposition) {
        uint numElements = _elementTypes.length;
        uint[] memory averagedComposition = new uint[](numElements); // Store sums before averaging
        uint[] memory totalComposition = new uint[](numElements); // Store total percentage points of each element across inputs
        uint numInputs = inputTokenIds.length;

        // Calculate the total percentage points for each element across all inputs
        for (uint i = 0; i < numInputs; i++) {
            uint[] memory comp = _assets[inputTokenIds[i]].composition;
            for (uint j = 0; j < numElements; j++) {
                totalComposition[j] += comp[j]; // Summing percentages
            }
        }

        // Calculate the simple average composition
        for (uint i = 0; i < numElements; i++) {
            averagedComposition[i] = totalComposition[i] / numInputs; // Integer division
        }

        // --- Apply Formula Modifier ---
        // Determine which elements are present (above 0%) in the TOTAL aggregated composition
        uint[] memory presentElementIndices;
        uint presentCount = 0;
        for(uint i = 0; i < numElements; i++) {
            if (totalComposition[i] > 0) { // Check total, not average, for presence
                presentCount++;
            }
        }

        presentElementIndices = new uint[](presentCount);
        uint currentIndex = 0;
         for(uint i = 0; i < numElements; i++) {
            if (totalComposition[i] > 0) {
                presentElementIndices[currentIndex] = i;
                currentIndex++;
            }
        }
        // Note: presentElementIndices is naturally sorted because we iterate from 0 to numElements-1

        bytes32 formulaHash = keccak256(abi.encodePacked(presentElementIndices));
        uint[] memory modifierComposition = _elementalFormulaModifiers[formulaHash];

        uint[] memory finalComposition = new uint[](numElements);
        uint finalSum = 0;

        if (modifierComposition.length == numElements) {
            // Apply modifier and sum
            for(uint i = 0; i < numElements; i++) {
                 // Apply modifier (can add or subtract based on modifier value)
                 // Ensure no negative values, clamp at 0
                 if (averagedComposition[i] + modifierComposition[i] >= 0) { // Assuming modifier[i] can be very large positive or negative
                      finalComposition[i] = averagedComposition[i] + modifierComposition[i];
                 } else {
                     finalComposition[i] = 0;
                 }
                 finalSum += finalComposition[i];
            }
        } else {
            // No specific formula matched, use the simple average
            finalComposition = averagedComposition;
            // Recalculate sum for normalization because averaged might not sum to 100 due to integer division
             for(uint i = 0; i < numElements; i++) {
                 finalSum += finalComposition[i];
            }
        }

        // Normalize the final composition back to 100%
        if (finalSum == 0) {
             // Should not happen with multiple inputs unless all had 0% of everything
             // Fallback to equal distribution if somehow the sum is 0
             uint equalShare = 100 / numElements;
             for(uint i = 0; i < numElements; i++) {
                finalComposition[i] = equalShare;
             }
             finalComposition[numElements - 1] += 100 % numElements; // Adjust last element
        } else {
             uint sumCheck = 0;
             for(uint i = 0; i < numElements; i++) {
                 finalComposition[i] = (finalComposition[i] * 100) / finalSum; // Scale to 100
                 sumCheck += finalComposition[i];
             }
             // Adjust last element to ensure sum is exactly 100 due to integer division
             if (sumCheck != 100) {
                 finalComposition[numElements - 1] += (100 - sumCheck);
             }
        }


        return finalComposition;
    }


    /**
     * @dev Calculates the rarity score based on elemental composition and generation.
     * Simple linear scoring: Sum of (element_percentage * element_weight) + (generation * generation_weight).
     * @param composition The elemental composition array.
     * @param generation The generation number.
     * @return rarityScore The calculated score.
     */
    function _calculateRarity(uint[] memory composition, uint generation) internal view returns (uint) {
        uint rarity = 0;
        uint numElements = _elementTypes.length;

        require(composition.length == numElements, "Composition length mismatch during rarity calculation");
        require(_rarityWeights.elementWeights.length == numElements, "Rarity weights length mismatch");


        for (uint i = 0; i < numElements; i++) {
            rarity += composition[i] * _rarityWeights.elementWeights[i];
        }

        rarity += generation * _rarityWeights.generationWeight;

        return rarity;
    }
}
```