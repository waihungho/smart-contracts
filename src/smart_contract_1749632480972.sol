Okay, let's design a sophisticated smart contract that acts as a factory for deploying and managing unique, generative, and potentially evolving digital assets (NFTs). This concept combines programmable on-chain generation rules, verifiable randomness, asset linking, and dynamic trait updates.

We'll build a `GenerativeAssetFactory` contract.

**Core Concepts:**

1.  **Generative Templates:** The factory allows defining different "templates". Each template has rules for how an asset's traits are generated upon minting.
2.  **Programmable Generation Rules:** Rules can be simple (fixed values, random range) or complex (dependent on block data, external oracle data, interaction history).
3.  **Verifiable Randomness (Chainlink VRF):** Use Chainlink VRF for secure and verifiable randomness for trait generation.
4.  **Dynamic Traits:** Assets' traits can potentially change *after* minting, triggered by owner actions, on-chain events, or time elapsed.
5.  **Asset Linking:** Allow creating on-chain links between assets, potentially influencing traits or enabling combined actions.
6.  **Factory Pattern:** The contract manages multiple types of generative assets under one roof, allowing efficient deployment and interaction. (Note: Instead of deploying a *new* ERC721 contract for each template, this factory will manage the assets *itself*, acting as a multi-template ERC721, simplifying interaction and management).

**Outline:**

1.  **SPDX License and Pragmas**
2.  **Imports** (OpenZeppelin for ERC721, Ownable, Pausable; Chainlink VRF)
3.  **Enums and Structs**
    *   `RandomnessSource`: Defines where randomness comes from (None, Block, VRF).
    *   `GenerationRuleType`: Defines how a specific trait value is derived (Fixed, RandomRange, BlockData, ExternalData, LinkedAssetDependent).
    *   `TraitRule`: Defines the rule for a single trait type within a template.
    *   `Template`: Defines a blueprint for a type of generative asset.
    *   `Asset`: Represents an minted instance of an asset based on a template.
4.  **State Variables**
    *   Owner, Paused state
    *   Counters (template ID, asset token ID)
    *   Mappings for Templates (`templates`), Assets (`assets`), Trait values (`assetTraits`), Linked Assets (`linkedAssetId`).
    *   Fee configurations (template creation, minting).
    *   Chainlink VRF configuration (coordinator, keyhash, etc.).
    *   Mapping to track pending VRF requests and their associated minting data.
    *   ERC721 standard mappings (ownership, approvals, balances).
    *   Mapping from owner address to list of owned token IDs (Gas warning noted).
5.  **Modifiers** (`onlyOwner`, `whenNotPaused`, `whenPaused`, `onlyTemplateOwnerOrAdmin`)
6.  **Events** (e.g., `TemplateCreated`, `AssetMinted`, `TraitsUpdated`, `AssetsLinked`, `FeesWithdrawn`, `VRFRequested`, `VRFFulfilled`)
7.  **Constructor** (Sets owner, VRF config)
8.  **Admin/Owner Functions (>= 5 functions)**
    *   `setTemplateCreationFee`
    *   `setGlobalMintFee` (Optional default fee)
    *   `setVRFConfiguration`
    *   `withdrawFees`
    *   `pause`
    *   `unpause`
    *   (Inherited `transferOwnership`, `renounceOwnership`)
9.  **Template Management Functions (>= 4 functions)**
    *   `createTemplate`
    *   `setTemplateMintFee`
    *   `setTemplateRandomnessSource`
    *   `toggleTemplateActiveStatus`
    *   `getTemplate` (Query)
    *   `getTemplateTraitRules` (Query)
10. **Asset Generation/Minting Functions (>= 3 functions)**
    *   `mintAsset` (Public function to initiate minting, handles fee and VRF request if needed)
    *   `fulfillRandomWords` (Chainlink VRF callback)
    *   `_generateTraits` (Internal logic based on template rules and randomness)
11. **ERC721 Standard Functions (>= 8 functions - required by standard)**
    *   `balanceOf`
    *   `ownerOf`
    *   `transferFrom`
    *   `safeTransferFrom` (overloaded versions)
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
    *   `supportsInterface`
    *   `tokenURI`
12. **Asset Interaction & Evolution Functions (>= 5 functions)**
    *   `getAssetTraits` (Query)
    *   `updateAssetTrait` (Allows updating a specific trait if template/rules permit)
    *   `linkAssets`
    *   `unlinkAssets`
    *   `getLinkedAsset` (Query)
    *   `triggerAssetEvolution` (Initiates a re-generation or update cycle based on rules)
    *   `burnAsset`
13. **Query Functions (>= 3 functions)**
    *   `getTotalTemplates`
    *   `getTotalAssetsMinted`
    *   `getAssetsByOwner` (Careful with gas, potentially return limited list or rely on events/off-chain indexing)
    *   `assetExists`
14. **Internal Helper Functions** (e.g., `_safeMint`, `_burn`, `_addAssetToOwnerList`, `_removeAssetFromOwnerList`)

**Function Summary:**

*   **`constructor(...)`**: Initializes the contract, setting owner and Chainlink VRF parameters.
*   **`setTemplateCreationFee(uint256 _fee)`**: Owner function to set the fee required to create a new template.
*   **`setGlobalMintFee(uint256 _fee)`**: Owner function to set an optional default minting fee for templates without a specific fee.
*   **`setVRFConfiguration(...)`**: Owner function to update Chainlink VRF coordinator, keyhash, gas limit, and request confirmations.
*   **`withdrawFees(address payable _to, uint256 _amount)`**: Owner function to withdraw collected fees.
*   **`pause()`**: Owner function to pause contract functionality (minting, transfers, etc.).
*   **`unpause()`**: Owner function to unpause the contract.
*   **`createTemplate(uint256 _mintFee, RandomnessSource _randomnessSource, TraitRule[] memory _traitRules)`**: Allows anyone to create a new generative template by paying the creation fee and defining its properties and generation rules.
*   **`setTemplateMintFee(uint256 _templateId, uint256 _fee)`**: Template owner or contract owner can update the minting fee for a specific template.
*   **`setTemplateRandomnessSource(uint256 _templateId, RandomnessSource _source)`**: Template owner or contract owner can update the randomness source for a template.
*   **`toggleTemplateActiveStatus(uint256 _templateId, bool _active)`**: Template owner or contract owner can activate or deactivate a template, preventing/allowing new mints.
*   **`getTemplate(uint256 _templateId)`**: Queries details of a specific template.
*   **`getTemplateTraitRules(uint256 _templateId)`**: Queries the generation rules defined for a template.
*   **`mintAsset(uint256 _templateId)`**: Public function for users to mint a new asset from an active template, paying the required fee. Initiates trait generation (including VRF request if applicable).
*   **`fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)`**: Chainlink VRF callback function. Receives random words, retrieves pending mint data, and calls `_generateTraits` to finalize the asset creation.
*   **`getAssetTraits(uint256 _tokenId)`**: Queries the current traits of a specific asset.
*   **`updateAssetTrait(uint256 _tokenId, string memory _traitType, string memory _newValue)`**: Allows updating a specific trait value. Subject to template rules or requires asset owner/template owner permission. (Simplified for example, could be complex).
*   **`linkAssets(uint256 _tokenId1, uint256 _tokenId2)`**: Allows the owner of `_tokenId1` to link it to `_tokenId2`. Creates a one-way relationship.
*   **`unlinkAssets(uint256 _tokenId)`**: Allows the owner of `_tokenId` to remove its link to another asset.
*   **`getLinkedAsset(uint256 _tokenId)`**: Queries the token ID that a specific asset is linked to.
*   **`triggerAssetEvolution(uint256 _tokenId)`**: Allows the asset owner to trigger an 'evolution' or trait update process, potentially re-running generation logic with new inputs or applying evolution rules defined in the template.
*   **`burnAsset(uint256 _tokenId)`**: Allows the asset owner to burn (destroy) their asset.
*   **`balanceOf(address owner)`**: Standard ERC721: Returns the number of assets owned by an address.
*   **`ownerOf(uint256 tokenId)`**: Standard ERC721: Returns the owner of an asset.
*   **`transferFrom(address from, address to, uint256 tokenId)`**: Standard ERC721: Transfers asset ownership (requires approval or sender is owner).
*   **`safeTransferFrom(...)`**: Standard ERC721: Safe transfers, checking if recipient can receive NFTs.
*   **`approve(address to, uint256 tokenId)`**: Standard ERC721: Grants approval for another address to transfer a specific asset.
*   **`setApprovalForAll(address operator, bool approved)`**: Standard ERC721: Grants/revokes approval for an operator to manage all assets owned by the sender.
*   **`getApproved(uint256 tokenId)`**: Standard ERC721: Returns the address approved for a specific asset.
*   **`isApprovedForAll(address owner, address operator)`**: Standard ERC721: Checks if an operator has approval for all assets of an owner.
*   **`supportsInterface(bytes4 interfaceId)`**: Standard ERC165/ERC721: Indicates supported interfaces.
*   **`tokenURI(uint256 tokenId)`**: Standard ERC721 Metadata: Returns a URI pointing to metadata for an asset. (This implementation will likely generate a base URI + token ID).
*   **`getTotalTemplates()`**: Queries the total number of templates created.
*   **`getTotalAssetsMinted()`**: Queries the total number of assets minted across all templates.
*   **`getAssetsByOwner(address _owner)`**: Queries the list of token IDs owned by an address. (Gas warning applies).
*   **`assetExists(uint256 _tokenId)`**: Checks if a specific asset token ID exists.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Import Chainlink VRF contracts
// Note: These imports assume you have Chainlink VRF v2 contracts available.
// You will need to install them using npm or yarn:
// yarn add @chainlink/contracts
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// Using placeholder interfaces if Chainlink isn't installed for compilation
interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint32 requestConfirmations,
        uint32 callbackGasLimit,
        uint16 numWords
    ) external returns (uint256 requestId);

    // Add other functions you might need from the interface
}

abstract contract VRFConsumerBaseV2 {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;
}


/**
 * @title GenerativeAssetFactory
 * @dev A smart contract factory for creating, managing, and minting generative and evolving digital assets (NFTs).
 * Assets' traits are generated based on programmable rules, verifiable randomness (Chainlink VRF),
 * and can potentially evolve or be linked to other assets.
 * This contract acts as a multi-template ERC721 collection manager.
 */
contract GenerativeAssetFactory is ERC721, Ownable, Pausable, VRFConsumerBaseV2 {

    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum RandomnessSource {
        NONE,          // No randomness, traits might be fixed or based purely on non-random data
        BLOCK_DATA,    // Uses blockhash, timestamp, or block number (less secure randomness)
        CHAINLINK_VRF  // Uses Chainlink Verifiable Random Function (secure randomness)
    }

    enum GenerationRuleType {
        FIXED_VALUE,         // Trait has a fixed value defined in the rule
        RANDOM_RANGE_INT,    // Random integer within a defined min/max range
        RANDOM_RANGE_DECIMAL,// Random decimal within a defined min/max range (scaled integer)
        BLOCK_NUMBER,        // Value based on block.number at mint time
        BLOCK_TIMESTAMP,     // Value based on block.timestamp at mint time
        LINKED_ASSET_TRAIT,  // Value copied from a specific trait of a linked asset
        EXTERNAL_ORACLE_DATA // (Placeholder) Value derived from external data via oracle (requires oracle integration)
    }

    struct TraitRule {
        string traitType;           // The name of the trait (e.g., "Color", "Strength", "Rarity")
        GenerationRuleType ruleType; // How the trait value is generated
        string fixedValue;          // Used if ruleType is FIXED_VALUE
        int256 minInt;              // Used if ruleType is RANDOM_RANGE_INT
        int256 maxInt;              // Used if ruleType is RANDOM_RANGE_INT
        uint256 minDecimal;         // Used if ruleType is RANDOM_RANGE_DECIMAL (scaled)
        uint256 maxDecimal;         // Used if ruleType is RANDOM_RANGE_DECIMAL (scaled)
        uint256 decimalScale;       // Used if ruleType is RANDOM_RANGE_DECIMAL (e.g., 100 for 2 decimal places)
        string sourceTraitType;     // Used if ruleType is LINKED_ASSET_TRAIT
        // Add fields for EXTERNAL_ORACLE_DATA if implementing oracle integration
    }

    struct Template {
        address owner;               // Creator/owner of the template
        uint256 mintFee;             // Fee to mint an asset from this template (in contract's native currency, e.g., Ether)
        RandomnessSource randomnessSource; // Source of randomness for this template
        bool active;                 // Is the template currently available for minting?
        Counters.Counter assetCounter; // Counter for assets minted under this template
        mapping(string => TraitRule) traitRules; // Mapping of trait type name to its rule
        string[] traitTypes;         // Ordered list of trait types for iteration
    }

    struct Asset {
        uint256 templateId;         // The ID of the template this asset was minted from
        uint256 mintTimestamp;      // Timestamp when the asset was minted
        bytes32 generationSeed;     // The random seed used for initial generation (if applicable)
        uint256 linkedAssetId;      // The token ID of an asset this one is linked to (0 if not linked)
        // Owner and tokenId are handled by ERC721 mappings
    }

    // --- State Variables ---

    Counters.Counter private _templateIds;
    Counters.Counter private _tokenIds;

    uint256 public templateCreationFee; // Fee to create a new template
    uint256 public totalFeesCollected; // Total fees collected in native currency

    mapping(uint256 => Template) public templates;
    mapping(uint256 => Asset) public assets;

    // Stores trait values for each asset: tokenId => traitType => traitValue
    mapping(uint256 => mapping(string => string)) public assetTraits;

    // ERC721 Standard Mappings (inherited or managed explicitly)
    // We'll rely on OpenZeppelin's internal mappings where possible, but need some explicit tracking
    // ERC721 handles _owners, _balances, _tokenApprovals, _operatorApprovals
    // We *might* need a mapping from address to token IDs for getAssetsByOwner, but it's gas-intensive.
    // Let's add it with a warning, or better, manage a simple list and rely on off-chain for full list.
    // A simple mapping to track tokens per owner (careful with gas for large numbers!)
    mapping(address => uint256[]) private _ownerTokens;
    // Mapping to quickly look up index in _ownerTokens list
    mapping(uint256 => uint256) private _tokenOwnerIndex;


    // Chainlink VRF v2 specific state
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public i_keyHash;
    uint32 public i_callbackGasLimit;
    uint16 public i_requestConfirmations;
    uint64 public i_subscriptionId; // Your pre-funded subscription ID with the VRF Coordinator

    // Mapping to store context for VRF requests: requestId => minterAddress, templateId, newTokenId
    mapping(uint256 => struct MintRequest {
        address minter;
        uint256 templateId;
        uint256 newTokenId;
    }) public s_requests;


    // --- Modifiers ---

    modifier onlyTemplateOwnerOrAdmin(uint256 _templateId) {
        require(templates[_templateId].owner == msg.sender || owner() == msg.sender, "Not template owner or admin");
        _;
    }

    // --- Events ---

    event TemplateCreated(uint256 indexed templateId, address indexed owner, uint256 mintFee, RandomnessSource randomnessSource);
    event AssetMinted(uint256 indexed tokenId, uint256 indexed templateId, address indexed owner, bytes32 generationSeed);
    event TraitsUpdated(uint256 indexed tokenId, string traitType, string newValue);
    event AssetsLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event AssetsUnlinked(uint256 indexed tokenId);
    event EvolutionTriggered(uint256 indexed tokenId, bytes32 newSeed);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event VRFRequested(uint256 indexed requestId, uint256 indexed templateId, uint256 newTokenId);
    event VRFFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256[] randomWords);


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        address vrfCoordinator,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint16 requestConfirmations,
        uint64 subscriptionId,
        uint256 _templateCreationFee
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() VRFConsumerBaseV2() {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_requestConfirmations = requestConfirmations;
        i_subscriptionId = subscriptionId;
        templateCreationFee = _templateCreationFee;
    }

    // --- Admin/Owner Functions (7 functions) ---

    /**
     * @dev Sets the fee required to create a new template.
     * @param _fee The new template creation fee in native currency (Wei).
     */
    function setTemplateCreationFee(uint256 _fee) public onlyOwner {
        templateCreationFee = _fee;
    }

    /**
     * @dev Allows the owner to withdraw collected fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw in native currency (Wei).
     */
    function withdrawFees(address payable _to, uint256 _amount) public onlyOwner {
        require(_amount <= totalFeesCollected, "Insufficient collected fees");
        totalFeesCollected -= _amount;
        // It's generally safer to use `call` than `transfer` or `send` for withdrawing Ether
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Sets the configuration parameters for Chainlink VRF v2.
     * @param _keyHash The VRF key hash.
     * @param _callbackGasLimit The gas limit for the fulfillment callback.
     * @param _requestConfirmations The number of block confirmations to wait for.
     * @param _subscriptionId The VRF subscription ID.
     */
    function setVRFConfiguration(
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint64 _subscriptionId
    ) public onlyOwner {
        i_keyHash = _keyHash;
        i_callbackGasLimit = _callbackGasLimit;
        i_requestConfirmations = _requestConfirmations;
        i_subscriptionId = _subscriptionId;
    }

    // pause() and unpause() inherited from Pausable

    // transferOwnership() and renounceOwnership() inherited from Ownable

    // --- Template Management Functions (5 functions) ---

    /**
     * @dev Creates a new generative template. Requires payment of the template creation fee.
     * @param _mintFee The fee to mint an asset from this template.
     * @param _randomnessSource The source of randomness for trait generation.
     * @param _traitRules Array of TraitRule structs defining the generation rules.
     */
    function createTemplate(
        uint256 _mintFee,
        RandomnessSource _randomnessSource,
        TraitRule[] memory _traitRules
    ) public payable whenNotPaused {
        require(msg.value >= templateCreationFee, "Insufficient fee to create template");

        uint256 newTemplateId = _templateIds.current();
        _templateIds.increment();

        Template storage newTemplate = templates[newTemplateId];
        newTemplate.owner = msg.sender;
        newTemplate.mintFee = _mintFee;
        newTemplate.randomnessSource = _randomnessSource;
        newTemplate.active = true; // New templates are active by default

        for (uint i = 0; i < _traitRules.length; i++) {
            newTemplate.traitRules[_traitRules[i].traitType] = _traitRules[i];
            newTemplate.traitTypes.push(_traitRules[i].traitType);
        }

        totalFeesCollected += msg.value; // Collect the template creation fee

        emit TemplateCreated(newTemplateId, msg.sender, _mintFee, _randomnessSource);
    }

    /**
     * @dev Sets the minting fee for a specific template.
     * @param _templateId The ID of the template to update.
     * @param _fee The new minting fee for the template.
     */
    function setTemplateMintFee(uint256 _templateId, uint256 _fee) public onlyTemplateOwnerOrAdmin(_templateId) {
        templates[_templateId].mintFee = _fee;
    }

    /**
     * @dev Sets the randomness source for a specific template.
     * @param _templateId The ID of the template to update.
     * @param _source The new randomness source.
     */
    function setTemplateRandomnessSource(uint256 _templateId, RandomnessSource _source) public onlyTemplateOwnerOrAdmin(_templateId) {
        templates[_templateId].randomnessSource = _source;
    }

    /**
     * @dev Activates or deactivates a template, controlling whether new assets can be minted from it.
     * @param _templateId The ID of the template to update.
     * @param _active The new active status (true to activate, false to deactivate).
     */
    function toggleTemplateActiveStatus(uint256 _templateId, bool _active) public onlyTemplateOwnerOrAdmin(_templateId) {
        templates[_templateId].active = _active;
    }

    /**
     * @dev Gets the details of a specific template.
     * @param _templateId The ID of the template to query.
     * @return owner_ The template owner.
     * @return mintFee_ The template's minting fee.
     * @return randomnessSource_ The template's randomness source.
     * @return active_ The template's active status.
     * @return assetCount_ The number of assets minted from this template.
     */
    function getTemplate(uint256 _templateId)
        public
        view
        returns (address owner_, uint256 mintFee_, RandomnessSource randomnessSource_, bool active_, uint256 assetCount_)
    {
        Template storage t = templates[_templateId];
        owner_ = t.owner;
        mintFee_ = t.mintFee;
        randomnessSource_ = t.randomnessSource;
        active_ = t.active;
        assetCount_ = t.assetCounter.current();
    }

    /**
     * @dev Gets the trait rules defined for a specific template.
     * Note: This is a helper function to query the rules structure, actual trait values are stored per asset.
     * @param _templateId The ID of the template to query.
     * @return rules_ An array of TraitRule structs for the template.
     */
    function getTemplateTraitRules(uint256 _templateId)
        public
        view
        returns (TraitRule[] memory rules_)
    {
        Template storage t = templates[_templateId];
        uint256 numTraits = t.traitTypes.length;
        rules_ = new TraitRule[](numTraits);
        for (uint i = 0; i < numTraits; i++) {
            rules_[i] = t.traitRules[t.traitTypes[i]];
        }
    }


    // --- Asset Generation/Minting Functions (3 functions) ---

    /**
     * @dev Mints a new asset from a template. Requires payment of the template's mint fee.
     * Triggers trait generation based on the template's randomness source.
     * @param _templateId The ID of the template to mint from.
     */
    function mintAsset(uint256 _templateId) public payable whenNotPaused {
        Template storage template = templates[_templateId];
        require(template.active, "Template not active");
        require(msg.value >= template.mintFee, "Insufficient mint fee");

        totalFeesCollected += msg.value; // Collect mint fee

        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();
        template.assetCounter.increment();

        assets[newTokenId].templateId = _templateId;
        assets[newTokenId].mintTimestamp = block.timestamp;
        assets[newTokenId].linkedAssetId = 0; // Initially no linked asset

        // Standard ERC721 minting logic (handled by OpenZeppelin's _mint)
        _safeMint(msg.sender, newTokenId);
        _addAssetToOwnerList(msg.sender, newTokenId); // Manually track for getAssetsByOwner

        bytes32 generationSeed; // Seed used for generation

        if (template.randomnessSource == RandomnessSource.CHAINLINK_VRF) {
            // Request randomness from Chainlink VRF
            // Store context so fulfillRandomWords knows which asset/template it's for
            uint256 requestId = i_vrfCoordinator.requestRandomWords(
                i_keyHash,
                i_subscriptionId,
                i_requestConfirmations,
                i_callbackGasLimit,
                1 // Request 1 random word as a seed
            );
            s_requests[requestId] = MintRequest({minter: msg.sender, templateId: _templateId, newTokenId: newTokenId});
            emit VRFRequested(requestId, _templateId, newTokenId);
            // Trait generation happens in fulfillRandomWords
        } else {
            // Generate traits immediately using less secure randomness
            // Use block data as seed for non-VRF randomness
            if (template.randomnessSource == RandomnessSource.BLOCK_DATA) {
                 // Simple hashing of block data and token ID for a non-VRF seed
                generationSeed = keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, newTokenId));
            } else { // RandomnessSource.NONE
                // Use a non-random seed, generation might rely only on fixed values or other non-random inputs
                generationSeed = bytes32(newTokenId); // Use token ID as a non-random identifier
            }
            assets[newTokenId].generationSeed = generationSeed;
            _generateTraits(newTokenId, _templateId, generationSeed);
        }

        emit AssetMinted(newTokenId, _templateId, msg.sender, generationSeed); // Note: seed might be 0 for VRF until fulfilled
    }

     /**
     * @dev Callback function for Chainlink VRF v2.
     * Receives random words and triggers trait generation for the waiting asset.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords The array of random words returned by the VRF coordinator.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].newTokenId != 0, "VRF request not found or already fulfilled");
        require(_randomWords.length > 0, "No random words received");

        // Retrieve minting context
        address minter = s_requests[_requestId].minter;
        uint256 templateId = s_requests[_requestId].templateId;
        uint256 tokenId = s_requests[_requestId].newTokenId;

        // Clean up the request mapping
        delete s_requests[_requestId];

        // Use the first random word as the seed
        bytes32 generationSeed = bytes32(_randomWords[0]);
        assets[tokenId].generationSeed = generationSeed; // Store the actual seed

        // Generate traits using the VRF seed
        _generateTraits(tokenId, templateId, generationSeed);

        emit VRFFulfilled(_requestId, tokenId, _randomWords);
    }


    /**
     * @dev Internal function to generate asset traits based on template rules and a seed.
     * This function contains the core generative logic.
     * @param _tokenId The ID of the asset being generated.
     * @param _templateId The ID of the template used.
     * @param _seed The random seed or identifier for generation.
     */
    function _generateTraits(uint256 _tokenId, uint256 _templateId, bytes32 _seed) internal {
        Template storage template = templates[_templateId];
        // Use the seed to derive deterministic values for trait generation
        // A simple approach: hash the seed + traitType to get trait-specific random bytes
        uint256 seedInt = uint256(_seed);

        for (uint i = 0; i < template.traitTypes.length; i++) {
            string memory traitType = template.traitTypes[i];
            TraitRule storage rule = template.traitRules[traitType];
            string memory traitValue;

            bytes32 traitSpecificSeed = keccak256(abi.encodePacked(seedInt, traitType));
            uint256 traitRandomness = uint256(traitSpecificSeed); // Use this for deriving values

            if (rule.ruleType == GenerationRuleType.FIXED_VALUE) {
                traitValue = rule.fixedValue;
            } else if (rule.ruleType == GenerationRuleType.RANDOM_RANGE_INT) {
                 // Generate integer within [minInt, maxInt]
                require(rule.maxInt >= rule.minInt, "Invalid int range");
                int256 range = rule.maxInt - rule.minInt + 1;
                int256 randomOffset = int256(traitRandomness % uint256(range));
                int256 generatedValue = rule.minInt + randomOffset;
                // Convert int256 to string
                if (generatedValue == 0) traitValue = "0";
                else traitValue = Strings.toString(generatedValue); // Simplified, proper int256 toString needed
            } else if (rule.ruleType == GenerationRuleType.RANDOM_RANGE_DECIMAL) {
                // Generate decimal within [minDecimal, maxDecimal] scaled by decimalScale
                require(rule.maxDecimal >= rule.minDecimal, "Invalid decimal range");
                require(rule.decimalScale > 0, "Decimal scale must be > 0");
                uint256 range = rule.maxDecimal - rule.minDecimal + 1;
                uint256 randomOffset = traitRandomness % range;
                uint256 generatedScaledValue = rule.minDecimal + randomOffset;

                // Convert scaled value to decimal string (e.g., 12345, scale 100 -> "123.45")
                uint256 integerPart = generatedScaledValue / rule.decimalScale;
                uint256 decimalPart = generatedScaledValue % rule.decimalScale;

                string memory decimalString = Strings.toString(decimalPart);
                // Pad decimal part with leading zeros if necessary
                while (bytes(decimalString).length < _countDigits(rule.decimalScale) - 1) {
                    decimalString = string(abi.encodePacked("0", decimalString));
                }
                traitValue = string(abi.encodePacked(Strings.toString(integerPart), ".", decimalString));

            } else if (rule.ruleType == GenerationRuleType.BLOCK_NUMBER) {
                traitValue = Strings.toString(block.number);
            } else if (rule.ruleType == GenerationRuleType.BLOCK_TIMESTAMP) {
                 traitValue = Strings.toString(block.timestamp);
            } else if (rule.ruleType == GenerationRuleType.LINKED_ASSET_TRAIT) {
                 // This rule relies on a linked asset's trait value at the time of generation
                 uint256 linkedId = assets[_tokenId].linkedAssetId;
                 if (linkedId != 0) {
                     traitValue = assetTraits[linkedId][rule.sourceTraitType];
                 } else {
                     // Handle case where no asset is linked or source trait doesn't exist on linked asset
                     traitValue = "N/A"; // Or some default/error value
                 }
                 // Note: This linking affects generation *at mint*. Subsequent links/unlinks don't change it
                 // unless explicitly triggered by triggerAssetEvolution which might re-run this logic.
            }
            // TODO: Add logic for EXTERNAL_ORACLE_DATA if implemented

            assetTraits[_tokenId][traitType] = traitValue;
            emit TraitsUpdated(_tokenId, traitType, traitValue);
        }
    }

    // Helper for _generateTraits to count digits for decimal padding
     function _countDigits(uint256 number) private pure returns (uint256) {
        if (number == 0) return 1;
        uint256 count = 0;
        uint256 temp = number;
        while (temp > 0) {
            temp /= 10;
            count++;
        }
        return count;
    }


    // --- ERC721 Standard Functions (10 functions + 2 helpers for tracking) ---

    // Override required ERC721 functions
    // OpenZeppelin's ERC721 handles _owners, _balances, etc.
    // We only override to add/remove from our _ownerTokens list for getAssetsByOwner query.

    /**
     * @dev See {IERC721Enumerable-balanceOf}.
     * Note: ERC721Enumerable is not fully implemented, just the standard ERC721 functions.
     * Using OpenZeppelin's internal _balances.
     */
    function balanceOf(address owner) public view override(ERC721) returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return super.balanceOf(owner); // Uses OZ internal _balances
    }

     /**
     * @dev See {IERC721-ownerOf}.
     * Using OpenZeppelin's internal _owners.
     */
    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        // Checks if token exists internally
        return super.ownerOf(tokenId); // Uses OZ internal _owners
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
        // Standard checks (ownership, approval) handled by super
        super.transferFrom(from, to, tokenId);
        _removeAssetFromOwnerList(from, tokenId);
        _addAssetToOwnerList(to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
         super.safeTransferFrom(from, to, tokenId);
         _removeAssetFromOwnerList(from, tokenId);
         _addAssetToOwnerList(to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721) {
         super.safeTransferFrom(from, to, tokenId, data);
         _removeAssetFromOwnerList(from, tokenId);
         _addAssetToOwnerList(to, tokenId);
    }

    // approve, setApprovalForAll, getApproved, isApprovedForAll are handled by OpenZeppelin ERC721

    /**
     * @dev See {IERC721-tokenURI}.
     * Returns the URI for the metadata of an asset.
     * Assumes metadata is hosted off-chain and can be retrieved via a base URI + token ID.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        _requireOwned(tokenId); // Ensures token exists and sender is owner (or approved/operator) implicitly via _requireOwned
        // In a real implementation, you'd construct the actual metadata URI here.
        // For this example, let's return a placeholder or a base URI + token ID.
        // A more advanced version could use template ID and traits to generate metadata dynamically or point to an on-chain resolver.
        return string(abi.encodePacked("ipfs://YOUR_METADATA_BASE_URI/", tokenId.toString()));
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     * Supports ERC721 and ERC165 interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        // Add ERC721Enumerable interfaceId if _ownerTokens mapping is intended for full enumeration
        // return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
         return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Internal Helpers for _ownerTokens (manual tracking for query) ---

    function _addAssetToOwnerList(address _owner, uint256 _tokenId) internal {
        _ownerTokens[_owner].push(_tokenId);
        _tokenOwnerIndex[_tokenId] = _ownerTokens[_owner].length - 1;
    }

    function _removeAssetFromOwnerList(address _owner, uint256 _tokenId) internal {
        uint256 lastTokenIndex = _ownerTokens[_owner].length - 1;
        uint256 tokenIndex = _tokenOwnerIndex[_tokenId];

        // Move the last token to the index of the token to delete
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownerTokens[_owner][lastTokenIndex];
            _ownerTokens[_owner][tokenIndex] = lastTokenId;
            _tokenOwnerIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last token (which is now the token to delete or was the token to delete)
        _ownerTokens[_owner].pop();
        delete _tokenOwnerIndex[_tokenId];
    }


    // --- Asset Interaction & Evolution Functions (7 functions) ---

     /**
     * @dev Gets the current traits of a specific asset.
     * @param _tokenId The ID of the asset to query.
     * @return traitNames_ An array of trait names.
     * @return traitValues_ An array of trait values corresponding to the names.
     */
    function getAssetTraits(uint256 _tokenId)
        public
        view
        returns (string[] memory traitNames_, string[] memory traitValues_)
    {
        require(assets[_tokenId].templateId != 0, "Asset does not exist"); // Check asset existence

        uint256 templateId = assets[_tokenId].templateId;
        Template storage template = templates[templateId];
        uint256 numTraits = template.traitTypes.length;

        traitNames_ = new string[](numTraits);
        traitValues_ = new string[](numTraits);

        for (uint i = 0; i < numTraits; i++) {
            string memory traitType = template.traitTypes[i];
            traitNames_[i] = traitType;
            traitValues_[i] = assetTraits[_tokenId][traitType];
        }
    }

    /**
     * @dev Allows updating a specific trait value for an asset.
     * This function could be restricted based on template rules, ownership, or other conditions.
     * Simplified here to allow owner update.
     * @param _tokenId The ID of the asset.
     * @param _traitType The name of the trait to update.
     * @param _newValue The new value for the trait.
     */
    function updateAssetTrait(uint256 _tokenId, string memory _traitType, string memory _newValue) public whenNotPaused {
        // Simplified access control: only owner can update traits directly.
        // More complex logic could involve template rules, time locks, etc.
        require(ownerOf(_tokenId) == msg.sender, "Only asset owner can update traits");
        // Optional: Add check if traitType is defined in the asset's template?

        assetTraits[_tokenId][_traitType] = _newValue;
        emit TraitsUpdated(_tokenId, _traitType, _newValue);
    }

    /**
     * @dev Links one asset to another. Creates a one-way relationship.
     * Only the owner of the asset being linked (`_tokenId1`) can perform this action.
     * @param _tokenId1 The ID of the asset to link FROM.
     * @param _tokenId2 The ID of the asset to link TO.
     */
    function linkAssets(uint256 _tokenId1, uint256 _tokenId2) public whenNotPaused {
        require(ownerOf(_tokenId1) == msg.sender, "Sender must own the first asset");
        require(assets[_tokenId2].templateId != 0, "Second asset does not exist"); // Check _tokenId2 exists
        require(_tokenId1 != _tokenId2, "Cannot link an asset to itself");

        assets[_tokenId1].linkedAssetId = _tokenId2;
        emit AssetsLinked(_tokenId1, _tokenId2);
    }

    /**
     * @dev Removes the link from an asset.
     * Only the owner of the asset can perform this action.
     * @param _tokenId The ID of the asset to unlink.
     */
    function unlinkAssets(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Sender must own the asset");
        require(assets[_tokenId].linkedAssetId != 0, "Asset is not linked");

        assets[_tokenId].linkedAssetId = 0;
        emit AssetsUnlinked(_tokenId);
    }

    /**
     * @dev Gets the token ID of the asset that a specific asset is linked to.
     * @param _tokenId The ID of the asset to query.
     * @return The token ID of the linked asset, or 0 if not linked.
     */
    function getLinkedAsset(uint256 _tokenId) public view returns (uint256) {
         require(assets[_tokenId].templateId != 0, "Asset does not exist"); // Check asset existence
        return assets[_tokenId].linkedAssetId;
    }

    /**
     * @dev Triggers an 'evolution' or trait update process for an asset.
     * This could re-run the trait generation logic with new parameters,
     * apply specific evolution rules defined in the template, or consume resources.
     * Simplified here to re-generate traits using current block data as a new seed,
     * but a real implementation would be template-specific.
     * Requires asset owner to call.
     * @param _tokenId The ID of the asset to evolve.
     */
    function triggerAssetEvolution(uint256 _tokenId) public whenNotPaused {
        require(ownerOf(_tokenId) == msg.sender, "Only asset owner can trigger evolution");
        require(assets[_tokenId].templateId != 0, "Asset does not exist"); // Check asset existence

        uint256 templateId = assets[_tokenId].templateId;
        Template storage template = templates[templateId];

        // --- Evolution Logic Placeholder ---
        // This is a simplified example. Real evolution logic could:
        // 1. Use time elapsed since mint/last evolution
        // 2. Use external data (oracles)
        // 3. Consume tokens or other assets
        // 4. Have a chance of success/failure
        // 5. Apply specific 'evolution rules' defined in the template rather than re-running generation.
        // -----------------------------------

        // Example Simplified Evolution: Re-generate traits using current block data
        bytes32 newSeed = keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, _tokenId, "evolution"));
        assets[_tokenId].generationSeed = newSeed; // Update the stored seed
        _generateTraits(_tokenId, templateId, newSeed); // Re-run generation with the new seed

        emit EvolutionTriggered(_tokenId, newSeed);
    }

    /**
     * @dev Burns (destroys) an asset.
     * Requires asset owner or approved operator to call.
     * @param _tokenId The ID of the asset to burn.
     */
    function burnAsset(uint256 _tokenId) public whenNotPaused {
        address assetOwner = ownerOf(_tokenId); // Checks existence via ownerOf
        require(assetOwner == msg.sender || isApprovedForAll(assetOwner, msg.sender) || getApproved(_tokenId) == msg.sender, "Caller is not owner nor approved");

        _burn(_tokenId); // OpenZeppelin's ERC721 handles burning
        _removeAssetFromOwnerList(assetOwner, _tokenId); // Manually track for getAssetsByOwner

        // Clean up asset-specific data (optional, but good practice)
        delete assets[_tokenId];
        // Deleting mapping keys is gas-intensive, especially for nested mappings.
        // Iterating through traitTypes to delete might exceed gas limit.
        // A common pattern is to just leave the old data or manage trait storage differently.
        // For this example, we'll leave the trait data but note the potential gas issue
        // if trait cleanup was attempted here.

        // Optional: emit a Burn event if OZ doesn't (ERC721 standard includes Transfer event with to=address(0))
    }

    // --- Query Functions (4 functions + ERC721 queries) ---

    /**
     * @dev Gets the total number of generative templates created.
     * @return The total number of templates.
     */
    function getTotalTemplates() public view returns (uint256) {
        return _templateIds.current();
    }

    /**
     * @dev Gets the total number of assets minted across all templates.
     * @return The total number of assets.
     */
    function getTotalAssetsMinted() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Gets the list of token IDs owned by a specific address.
     * WARNING: This function can be gas-intensive for addresses owning a large number of assets.
     * Consider using off-chain indexing or pagination in real applications.
     * @param _owner The address to query.
     * @return An array of token IDs owned by the address.
     */
    function getAssetsByOwner(address _owner) public view returns (uint256[] memory) {
        return _ownerTokens[_owner];
    }

    /**
     * @dev Checks if a specific asset token ID exists.
     * @param _tokenId The token ID to check.
     * @return True if the asset exists, false otherwise.
     */
    function assetExists(uint256 _tokenId) public view returns (bool) {
        // The ERC721 ownerOf function will revert or return address(0) if the token doesn't exist.
        // We can use our internal asset struct check for existence.
         return assets[_tokenId].templateId != 0; // Template ID 0 indicates uninitialized struct
    }

    // --- Internal ERC721 Helpers (Delegated to OpenZeppelin) ---
    // _safeMint, _burn, _beforeTokenTransfer, _afterTokenTransfer
    // OpenZeppelin handles these, we override _before/after if needed for hooks.
    // Our _addAssetToOwnerList and _removeAssetFromOwnerList act as hooks for tracking.
    // _requireOwned(tokenId) is an OZ internal used in functions like tokenURI


    // Function Count Check:
    // Admin/Owner: 7 (setTemplateCreationFee, withdrawFees, setVRFConfiguration, pause, unpause, transferOwnership, renounceOwnership)
    // Template Management: 5 (createTemplate, setTemplateMintFee, setTemplateRandomnessSource, toggleTemplateActiveStatus, getTemplate, getTemplateTraitRules) -> Actually 6 query included
    // Asset Generation: 3 (mintAsset, fulfillRandomWords, _generateTraits - internal) -> 2 public/external
    // ERC721 Standard: 10 (balanceOf, ownerOf, transferFrom, safeTransferFrom x2, approve, setApprovalForAll, getApproved, isApprovedForAll, supportsInterface, tokenURI)
    // Asset Interaction: 7 (getAssetTraits, updateAssetTrait, linkAssets, unlinkAssets, getLinkedAsset, triggerAssetEvolution, burnAsset) -> 6 public/external
    // Query: 4 (getTotalTemplates, getTotalAssetsMinted, getAssetsByOwner, assetExists)
    // Internal Helpers: 2 (_addAssetToOwnerList, _removeAssetFromOwnerList) + others like _countDigits, _generateTraits

    // Total Public/External functions: 7 (Admin) + 5 (Template) + 2 (Mint) + 10 (ERC721) + 6 (Interaction) + 4 (Query) = 34 functions.
    // This easily exceeds the 20 function requirement.

}
```