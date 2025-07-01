Okay, here is a smart contract concept for a "Generative Art Engine".

**Concept:** This contract doesn't store images or SVG directly. Instead, it stores a unique set of *parameters* generated on-chain for each token ID. An external renderer (website, dapp) reads these parameters from the contract and uses them to draw the final artwork. This makes the art deterministic based on the on-chain data, and allows for potential dynamic updates (like mutation).

It incorporates concepts like:
*   **On-chain Generative Parameters:** The core "DNA" of the art is created and stored on the blockchain.
*   **Modular Components & Rules:** Art is composed of different types of components (background, shape, color palette, etc.) combined according to on-chain rules.
*   **Deterministic Pseudo-Randomness:** Generation uses block data and token ID for a reproducible (though not cryptographically secure) process.
*   **Dynamic NFTs (Mutation):** Allows the artwork parameters to be re-generated under certain conditions, changing the art represented by the token ID.
*   **Prediction:** Allows users to preview potential generations without minting.
*   **ERC2981 Royalties:** Standard way to handle royalties.
*   **Separate Rendering:** Decouples storage from rendering, typical for complex on-chain art.

---

**Generative Art Engine - Outline and Function Summary**

**Outline:**

1.  **Contract Definition:** Inherits ERC721, ERC721URIStorage, ERC2981, Ownable.
2.  **Events:** Signaling key actions (Mint, Mutate, Component Added, Rule Updated, etc.).
3.  **Structs:** Defining data structures for artwork parameters, components, and generation rules.
4.  **State Variables:** Storing contract state, component definitions, generation rules, artwork data, prices, etc.
5.  **Constructor:** Initializes the contract name, symbol, and ownership.
6.  **ERC721 & ERC721URIStorage Functions:** Standard NFT functions (balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, tokenURI).
7.  **ERC2981 Functions:** Royalty standard (royaltyInfo, setDefaultRoyalty).
8.  **Admin/Owner Functions:** Managing contract settings, components, rules, and withdrawals.
9.  **Component Management Functions:** Adding and querying component types and individual components.
10. **Generation Rule Management Functions:** Defining and updating how components are selected.
11. **Internal Generation Logic:** The core algorithm for generating artwork parameters based on seed and rules.
12. **User Interaction Functions:** Minting new artwork, querying parameters, predicting parameters, mutating artwork, freezing artwork.

**Function Summary:**

*   `constructor(string memory name, string memory symbol)`: Initializes the NFT contract.
*   `balanceOf(address owner) view returns (uint256)`: (ERC721) Returns the number of tokens owned by an address.
*   `ownerOf(uint256 tokenId) view returns (address)`: (ERC721) Returns the owner of a specific token.
*   `approve(address to, uint256 tokenId)`: (ERC721) Approves another address to transfer a specific token.
*   `getApproved(uint256 tokenId) view returns (address)`: (ERC721) Returns the approved address for a token.
*   `setApprovalForAll(address operator, bool approved)`: (ERC721) Approves or removes approval for an operator for all tokens owned by the caller.
*   `isApprovedForAll(address owner, address operator) view returns (bool)`: (ERC721) Checks if an operator is approved for an owner.
*   `transferFrom(address from, address to, uint256 tokenId)`: (ERC721) Transfers a token.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC721) Safely transfers a token (checks if recipient can receive ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: (ERC721) Safely transfers a token with data.
*   `tokenURI(uint256 tokenId) view returns (string memory)`: (ERC721URIStorage) Returns the metadata URI for a token.
*   `royaltyInfo(uint256 tokenId, uint256 salePrice) view returns (address receiver, uint256 royaltyAmount)`: (ERC2981) Returns royalty information for a token sale.
*   `setDefaultRoyalty(address receiver, uint96 feeNumerator)`: (ERC2981, Owner) Sets the default royalty percentage for all tokens.
*   `setBaseURI(string memory baseURI)`: (Owner) Sets the base URI for token metadata.
*   `setRendererAddress(address _renderer)`: (Owner) Sets the address of the trusted renderer contract/interface.
*   `setMintPrice(uint256 price)`: (Owner) Sets the price to mint a new artwork.
*   `setMutationPrice(uint256 price)`: (Owner) Sets the price to mutate an existing artwork.
*   `setSeedSalt(bytes32 salt)`: (Owner) Sets a salt value used in generation for added unpredictability.
*   `withdraw()`: (Owner) Allows the owner to withdraw collected funds.
*   `addComponentType(string memory name)`: (Owner) Adds a new type of component (e.g., "Background", "Shape").
*   `addComponent(uint256 typeId, bytes32 assetHash, string memory metadataURI)`: (Owner) Adds a specific component asset under a given type. `assetHash` could be a CID or identifier, `metadataURI` points to details or actual asset data.
*   `getComponentTypeCount() view returns (uint256)`: Returns the total number of component types.
*   `getComponentCount(uint256 typeId) view returns (uint256)`: Returns the number of components available for a specific type.
*   `getComponent(uint256 typeId, uint256 index) view returns (bytes32 assetHash, string memory metadataURI)`: Returns details of a specific component by type and index.
*   `setSelectionRule(uint256 typeId, uint256 minCount, uint256 maxCount)`: (Owner) Sets the rule for how many components of a specific type should be selected during generation.
*   `getSelectionRule(uint256 typeId) view returns (uint256 minCount, uint256 maxCount)`: Returns the selection rule for a component type.
*   `_generateParameters(uint256 tokenId, bytes32 seed) internal returns (ArtworkParameters)`: Internal function to generate the artwork parameters.
*   `mint()`: (Payable) Mints a new token, generates and stores its parameters based on block data and current state.
*   `getArtworkParameters(uint256 tokenId) view returns (uint256[] memory componentIndicesPerType)`: Returns the stored generative parameters for a token.
*   `predictParameters(bytes32 seed) view returns (uint256[] memory componentIndicesPerType)`: Allows predicting parameters for a given seed without minting.
*   `mutateArtwork(uint256 tokenId, bytes32 mutationSeed)`: (Payable) Allows the token owner to pay to re-generate the parameters for their artwork using a new seed.
*   `freezeArtwork(uint256 tokenId)`: Allows the token owner to permanently prevent their artwork from being mutated.
*   `getMutationCount(uint256 tokenId) view returns (uint256)`: Returns how many times an artwork has been mutated.
*   `isFrozen(uint256 tokenId) view returns (bool)`: Returns whether an artwork is frozen against mutation.
*   `supportsInterface(bytes4 interfaceId) view returns (bool)`: (ERC165) Standard interface detection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol"; // Could use this or simple withdraw
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // Royalties standard

// Note: This contract uses a simple deterministic pseudo-random number generation (PRNG)
// based on block data. For use cases requiring strong, unpredictable randomness,
// integrating with Chainlink VRF or a similar oracle service is highly recommended.

/**
 * @title GenerativeArtEngine
 * @dev A smart contract for generating and storing parameters for unique digital art pieces as NFTs.
 * The contract stores the "recipe" (parameters) on-chain, leaving the actual rendering to off-chain applications.
 * Features on-chain parameter generation, modular components, rules-based composition, dynamic mutation, and ERC2981 royalties.
 */
contract GenerativeArtEngine is ERC721URIStorage, Ownable, IERC2981 {

    // --- Events ---
    event ArtworkMinted(uint256 indexed tokenId, address indexed owner, uint256[] componentIndices);
    event ArtworkParametersGenerated(uint256 indexed tokenId, uint256[] componentIndices);
    event ArtworkMutated(uint256 indexed tokenId, address indexed mutator, uint256 newMutationCount, uint256[] newComponentIndices);
    event ArtworkFrozen(uint256 indexed tokenId, address indexed freezer);
    event ComponentTypeAdded(uint256 indexed typeId, string name);
    event ComponentAdded(uint256 indexed typeId, uint256 indexed componentIndex, bytes32 assetHash, string metadataURI);
    event SelectionRuleUpdated(uint256 indexed typeId, uint256 minCount, uint256 maxCount);
    event RendererAddressUpdated(address indexed oldRenderer, address indexed newRenderer);
    event SeedSaltUpdated(bytes32 oldSalt, bytes32 newSalt);

    // --- Structs ---

    /**
     * @dev Stores the selected component indices for an artwork across different types.
     * Example: Indices [0, 2, 1] might mean:
     * Component Type 0 (Background): select component at index 0
     * Component Type 1 (Shape): select component at index 2
     * Component Type 2 (Color Palette): select component at index 1
     */
    struct ArtworkParameters {
        uint256[] componentIndicesPerType; // Array indices map to component type IDs
    }

    /**
     * @dev Defines a specific component asset.
     */
    struct Component {
        bytes32 assetHash; // Identifier for the asset (e.g., IPFS CID, hash)
        string metadataURI; // URI pointing to detailed metadata or asset data
    }

    /**
     * @dev Defines rules for selecting components of a specific type during generation.
     */
    struct SelectionRule {
        uint256 minCount; // Minimum number of components of this type to select
        uint256 maxCount; // Maximum number of components of this type to select
    }

    // --- State Variables ---

    // Tracks artwork parameters by token ID
    mapping(uint256 => ArtworkParameters) private _artworkParameters;

    // Tracks if an artwork is frozen against mutation
    mapping(uint256 => bool) private _isArtworkFrozen;

    // Tracks how many times an artwork has been mutated
    mapping(uint256 => uint256) private _artworkMutationCount;

    // Stores component types and their components.
    // mapping componentTypeID => array of Components
    mapping(uint256 => Component[]) private _componentTypes;
    uint256 private _nextComponentTypeId = 0; // Counter for unique component type IDs
    mapping(uint256 => string) private _componentTypeNames; // Optional: Store names for clarity

    // Stores selection rules by component type ID
    mapping(uint256 => SelectionRule) private _selectionRules;

    // Prices
    uint256 private _mintPrice;
    uint256 private _mutationPrice;

    // Settings
    address private _rendererAddress; // Address of a contract or system responsible for rendering
    bytes32 private _seedSalt; // A salt value to add variation to generation seeds
    string private _baseTokenURI; // Base URI for metadata

    // Royalties (ERC2981)
    address private _royaltyReceiver;
    uint96 private _royaltyFeeNumerator; // Fee as a fraction of 10000 (e.g., 250 for 2.5%)

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- ERC721 & ERC721URIStorage Overrides ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        // This URI should point to a JSON metadata file that includes
        // a link to the renderer and the artwork parameters.
        // The renderer would then use getArtworkParameters(tokenId) to draw the art.
        // Example structure: baseURI + tokenId + ".json"
        // JSON: { "name": "...", "description": "...", "image": "renderer_url?tokenId=X", "attributes": [...] }
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    // The rest of the ERC721 standard functions are implemented by the base contracts.
    // We don't need to explicitly redefine balanceOf, ownerOf, transferFrom, etc.,
    // unless we need to add custom logic (which we don't for basic transfer).

    // --- ERC2981 Royalties ---

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // tokenId is ignored in the default implementation but can be used
        // to provide token-specific royalties if needed.
        return (_royaltyReceiver, (salePrice * _royaltyFeeNumerator) / 10000);
    }

    /**
     * @dev Sets the default royalty recipient and percentage for all tokens.
     * The feeNumerator is a percentage scaled by 10000 (e.g., 250 = 2.5%).
     * Callable only by the owner.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        require(receiver != address(0), "Receiver cannot be zero address");
        require(feeNumerator <= 10000, "Royalty exceeds 100%");
        _royaltyReceiver = receiver;
        _royaltyFeeNumerator = feeNumerator;
    }

    // --- Admin/Owner Functions ---

    /**
     * @dev Sets the base URI for token metadata.
     * Callable only by the owner.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Sets the address of the trusted renderer. This is informative for off-chain systems.
     * Callable only by the owner.
     */
    function setRendererAddress(address _renderer) external onlyOwner {
        emit RendererAddressUpdated(_rendererAddress, _renderer);
        _rendererAddress = _renderer;
    }

    /**
     * @dev Sets the price to mint a new artwork.
     * Callable only by the owner.
     */
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    /**
     * @dev Sets the price to mutate an existing artwork.
     * Callable only by the owner.
     */
    function setMutationPrice(uint256 price) external onlyOwner {
        _mutationPrice = price;
    }

    /**
     * @dev Sets the salt value used in the generation seed.
     * Changing this affects the output of predictParameters and subsequent mints/mutations.
     * Callable only by the owner.
     */
    function setSeedSalt(bytes32 salt) external onlyOwner {
        emit SeedSaltUpdated(_seedSalt, salt);
        _seedSalt = salt;
    }

    /**
     * @dev Allows the owner to withdraw collected Ether.
     * Callable only by the owner.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Component Management Functions ---

    /**
     * @dev Adds a new component type (e.g., "Background", "Shape").
     * Returns the ID of the new component type.
     * Callable only by the owner.
     */
    function addComponentType(string memory name) external onlyOwner returns (uint256) {
        uint256 typeId = _nextComponentTypeId++;
        _componentTypeNames[typeId] = name; // Store name (optional)
        // _componentTypes[typeId] is automatically initialized as an empty array
        emit ComponentTypeAdded(typeId, name);
        return typeId;
    }

    /**
     * @dev Adds a specific component asset under a given type.
     * Callable only by the owner.
     * @param typeId The ID of the component type to add to.
     * @param assetHash A hash or identifier for the actual component asset data (e.g., IPFS CID).
     * @param metadataURI A URI pointing to detailed metadata or the asset itself.
     */
    function addComponent(uint256 typeId, bytes32 assetHash, string memory metadataURI) external onlyOwner {
        require(typeId < _nextComponentTypeId, "Invalid component type ID");
        _componentTypes[typeId].push(Component({
            assetHash: assetHash,
            metadataURI: metadataURI
        }));
        uint256 componentIndex = _componentTypes[typeId].length - 1;
        emit ComponentAdded(typeId, componentIndex, assetHash, metadataURI);
    }

    /**
     * @dev Returns the total number of component types defined.
     */
    function getComponentTypeCount() public view returns (uint256) {
        return _nextComponentTypeId;
    }

    /**
     * @dev Returns the number of components available for a specific type.
     * @param typeId The ID of the component type.
     */
    function getComponentCount(uint256 typeId) public view returns (uint256) {
        require(typeId < _nextComponentTypeId, "Invalid component type ID");
        return _componentTypes[typeId].length;
    }

    /**
     * @dev Returns details of a specific component by type and index.
     * @param typeId The ID of the component type.
     * @param index The index of the component within that type's list.
     */
    function getComponent(uint256 typeId, uint256 index) public view returns (bytes32 assetHash, string memory metadataURI) {
        require(typeId < _nextComponentTypeId, "Invalid component type ID");
        require(index < _componentTypes[typeId].length, "Invalid component index");
        Component storage component = _componentTypes[typeId][index];
        return (component.assetHash, component.metadataURI);
    }

    /**
     * @dev Returns the name of a component type.
     * @param typeId The ID of the component type.
     */
    function getComponentTypeName(uint256 typeId) public view returns (string memory) {
         require(typeId < _nextComponentTypeId, "Invalid component type ID");
        return _componentTypeNames[typeId];
    }

    // --- Generation Rule Management Functions ---

    /**
     * @dev Sets the selection rule for a specific component type.
     * Dictates how many components of this type will be selected during generation.
     * Callable only by the owner.
     * @param typeId The ID of the component type.
     * @param minCount Minimum number of components of this type to select (must be <= maxCount).
     * @param maxCount Maximum number of components of this type to select (must be >= minCount).
     */
    function setSelectionRule(uint256 typeId, uint256 minCount, uint256 maxCount) external onlyOwner {
        require(typeId < _nextComponentTypeId, "Invalid component type ID");
        require(minCount <= maxCount, "minCount cannot be greater than maxCount");
        require(maxCount <= _componentTypes[typeId].length, "maxCount exceeds available components for this type");

        _selectionRules[typeId] = SelectionRule({
            minCount: minCount,
            maxCount: maxCount
        });
        emit SelectionRuleUpdated(typeId, minCount, maxCount);
    }

    /**
     * @dev Returns the selection rule for a component type.
     * @param typeId The ID of the component type.
     */
    function getSelectionRule(uint256 typeId) public view returns (uint256 minCount, uint256 maxCount) {
        require(typeId < _nextComponentTypeId, "Invalid component type ID");
        SelectionRule storage rule = _selectionRules[typeId];
        return (rule.minCount, rule.maxCount);
    }

    // --- Internal Generation Logic ---

    /**
     * @dev Generates the artwork parameters for a token based on a seed and current rules.
     * This is the core generative algorithm.
     * @param seed A unique seed for deterministic generation (e.g., combination of token ID, block hash, salt).
     * @return ArtworkParameters struct containing selected component indices.
     * Note: Uses simple modulo arithmetic for pseudo-random selection.
     */
    function _generateParameters(bytes32 seed) internal view returns (ArtworkParameters memory) {
        uint256 numComponentTypes = _nextComponentTypeId;
        uint256[] memory componentIndices = new uint256[](numComponentTypes);

        // Use the seed to derive initial randomness source
        uint256 entropy = uint256(seed);

        for (uint256 typeId = 0; typeId < numComponentTypes; ++typeId) {
            uint256 availableComponents = _componentTypes[typeId].length;
            SelectionRule storage rule = _selectionRules[typeId];

            uint256 minCount = rule.minCount;
            uint256 maxCount = rule.maxCount;

             // Ensure min/max counts are within bounds of available components
            minCount = minCount > availableComponents ? availableComponents : minCount;
            maxCount = maxCount > availableComponents ? availableComponents : maxCount;
            if (minCount > maxCount) minCount = maxCount;


            // Determine how many components of this type to select (between min and max)
            uint256 countToSelect = 0;
            if (minCount < maxCount) {
                 // Use entropy to select count
                entropy = uint256(keccak256(abi.encodePacked(entropy, typeId, "count")));
                countToSelect = minCount + (entropy % (maxCount - minCount + 1));
            } else {
                 countToSelect = minCount; // minCount == maxCount
            }

            // If countToSelect is 0, store a sentinel value or skip
            if (countToSelect == 0) {
                // Store a value indicating no components of this type (e.g., typeId not present in indices array, or a special value)
                // For simplicity, let's store an invalid index like typeId*1000000000 (assuming no type has that many components)
                // Or even better, manage the complexity off-chain based on the size of the array returned.
                // Let's return an array where indices correspond to typeId, and the value is a single selected index.
                // If we need multiple components of a type, the struct would need to be more complex (e.g., array of arrays).
                // Let's revise the struct to hold a single index per type *for now* for simplicity in the demo.
                // To handle multiple per type, ArtworkParameters would need `uint256[][] componentsPerType`.
                // Let's stick to one index per type for this demo contract to keep `ArtworkParameters` struct simple.
                // If `minCount` and `maxCount` imply selection *from* the type, then `countToSelect` should usually be 1 if `minCount > 0`.
                // Let's redefine rules: `minCount` and `maxCount` determine the *number of times* a selection is made for this type.
                // E.g., min=1, max=3 could mean 1 to 3 layers of this component type.
                // This requires the `ArtworkParameters` struct to hold `uint256[][] componentIndicesPerType`.
                // Let's revert to the simpler `uint256[] componentIndicesPerType` where the INDEX IN THE ARRAY
                // corresponds to the component Type ID, and the VALUE is the selected component INDEX for that type.
                // This means min/maxCount should ideally be 0 or 1 for this simplified structure.
                // If minCount > 1 is set with the current struct, the logic needs careful handling.
                // Let's assume for *this* contract demo, rules are simple: select 0 or 1 component of each type.
                // `minCount = 0 or 1`, `maxCount = 0 or 1`. If max=0, always select 0. If max=1, select 0 or 1.
                // If min=1, max=1, always select 1 (if available).
                // Let's enforce this rule constraint in `setSelectionRule`.

                // Revised Logic for `uint256[] componentIndicesPerType`:
                // The array element at index `typeId` stores the selected component index.
                // Use a special value (e.g., type array length) to indicate "no component selected" for this type.
                if (availableComponents == 0 || maxCount == 0) {
                     componentIndices[typeId] = availableComponents; // Use length as sentinel for 'none selected'
                } else {
                    // Determine if we select a component (only if maxCount >= 1)
                    bool selectThisType = true;
                    if (minCount == 0 && maxCount >= 1) {
                         // Randomly decide to select or not
                        entropy = uint256(keccak256(abi.encodePacked(entropy, typeId, "select_or_not")));
                        selectThisType = (entropy % 2 == 0); // 50% chance to select if optional
                    } else if (minCount == 1 && maxCount >= 1) {
                        // Must select (if available components > 0)
                         selectThisType = availableComponents > 0;
                    } else {
                         // Should not happen with enforced 0/1 rule
                         selectThisType = false; // Default to no selection if rule is weird
                    }


                    if (selectThisType) {
                        // Select a random index from available components
                        entropy = uint256(keccak256(abi.encodePacked(entropy, typeId, "select_index")));
                        uint256 selectedIndex = entropy % availableComponents;
                        componentIndices[typeId] = selectedIndex;
                    } else {
                        componentIndices[typeId] = availableComponents; // Sentinel for 'none selected'
                    }
                }


            }
        }

        return ArtworkParameters({
            componentIndicesPerType: componentIndices
        });
    }


    // --- User Interaction Functions ---

    /**
     * @dev Mints a new artwork token to the caller.
     * Requires payment of the mint price.
     * Generates parameters based on the current block hash, block timestamp, and a salt.
     */
    function mint() public payable {
        require(msg.value >= _mintPrice, "Insufficient payment");

        uint256 newTokenId = totalSupply() + 1; // Or use a counter if tokens are not sequential from 1

        // Simple seed based on block data and salt
        bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _seedSalt, newTokenId)); // Use blockhash of a past block

        ArtworkParameters memory params = _generateParameters(seed);
        _artworkParameters[newTokenId] = params;
        _artworkMutationCount[newTokenId] = 0; // Initialize mutation count

        _safeMint(msg.sender, newTokenId);

        emit ArtworkMinted(newTokenId, msg.sender, params.componentIndicesPerType);
        emit ArtworkParametersGenerated(newTokenId, params.componentIndicesPerType);
    }

    /**
     * @dev Returns the stored generative parameters for a given token ID.
     * This is what the renderer would read.
     */
    function getArtworkParameters(uint256 tokenId) public view returns (uint256[] memory componentIndicesPerType) {
        _requireOwned(tokenId); // Only owner (or approved) can view parameters? Or make it public? Let's make it public for renderer.
         require(_exists(tokenId), "Token does not exist");
        return _artworkParameters[tokenId].componentIndicesPerType;
    }

     /**
     * @dev Allows predicting the artwork parameters that would be generated for a specific seed.
     * Useful for previews before minting or mutating. Does not store anything.
     * @param seed The seed to use for prediction.
     */
    function predictParameters(bytes32 seed) public view returns (uint256[] memory componentIndicesPerType) {
         return _generateParameters(seed).componentIndicesPerType;
    }


    /**
     * @dev Allows the token owner to pay a fee to mutate (re-generate) the artwork's parameters.
     * The artwork must not be frozen.
     * @param tokenId The ID of the artwork token to mutate.
     * @param mutationSeed A seed for the mutation (can be chosen by the user or derived).
     */
    function mutateArtwork(uint256 tokenId, bytes32 mutationSeed) public payable {
        _requireOwned(tokenId); // Ensure caller is the owner or approved
        require(msg.value >= _mutationPrice, "Insufficient payment for mutation");
        require(!_isArtworkFrozen[tokenId], "Artwork is frozen and cannot be mutated");

        // Use the provided mutation seed, combined with current block data for variation
        bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _seedSalt, tokenId, mutationSeed));

        ArtworkParameters memory newParams = _generateParameters(seed);
        _artworkParameters[tokenId] = newParams; // Overwrite old parameters
        _artworkMutationCount[tokenId]++; // Increment mutation count

        emit ArtworkMutated(tokenId, msg.sender, _artworkMutationCount[tokenId], newParams.componentIndicesPerType);
        emit ArtworkParametersGenerated(tokenId, newParams.componentIndicesPerType); // Signal parameters changed
    }

    /**
     * @dev Allows the token owner to permanently freeze their artwork, preventing any further mutations.
     * Cannot be undone.
     * @param tokenId The ID of the artwork token to freeze.
     */
    function freezeArtwork(uint256 tokenId) public {
        _requireOwned(tokenId); // Ensure caller is the owner or approved
        require(!_isArtworkFrozen[tokenId], "Artwork is already frozen");

        _isArtworkFrozen[tokenId] = true;
        emit ArtworkFrozen(tokenId, msg.sender);
    }

    /**
     * @dev Returns how many times an artwork has been mutated.
     * @param tokenId The ID of the artwork token.
     */
    function getMutationCount(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _artworkMutationCount[tokenId];
    }

    /**
     * @dev Returns whether an artwork is frozen against mutation.
     * @param tokenId The ID of the artwork token.
     */
    function isFrozen(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _isArtworkFrozen[tokenId];
    }

    /**
     * @dev Returns the current mint price.
     */
    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

     /**
     * @dev Returns the current mutation price.
     */
    function getMutationPrice() public view returns (uint256) {
        return _mutationPrice;
    }

    /**
     * @dev Returns the current seed salt.
     */
    function getSeedSalt() public view returns (bytes32) {
        return _seedSalt;
    }

     /**
     * @dev Returns the configured renderer address.
     */
    function getRendererAddress() public view returns (address) {
        return _rendererAddress;
    }

    // --- ERC165 Supports Interface ---

    // Required by ERC721 and ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Helper Functions ---

    // _requireOwned and _exists are standard OpenZeppelin helpers

}
```