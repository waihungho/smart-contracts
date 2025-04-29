Okay, let's design a smart contract for a *Generative and Mutable NFT Realm*. This contract will focus on NFTs whose attributes are generated on-chain upon minting using deterministic randomness and can later be mutated or evolved under certain conditions defined by the contract logic.

This approach is more advanced than typical static NFTs or NFTs relying solely on off-chain metadata. It incorporates on-chain logic for generation, evolution, and complex configuration, providing a foundation for dynamic digital assets or game items.

**Concept:** NFTs representing "Proto-Entities". Their initial attributes are born from the blockchain's state at the time of minting. Over time, or under specific conditions (like a cooldown period), the owner can trigger a "mutation" process that deterministicately evolves some of these attributes based on new blockchain state and contract-defined rules.

---

### Smart Contract: GenerativeNFTRealm

**Outline:**

1.  **Pragma & Imports:** Solidity version and necessary OpenZeppelin libraries (ERC721, Ownable, ReentrancyGuard, Strings, ERC165).
2.  **Custom Errors:** Define gas-efficient errors for various failure conditions.
3.  **Events:** Log key actions (Mint, Mutation, Attribute Change, Configuration updates, Withdrawal).
4.  **Structs & Enums:** Define data structures for Token Attributes and potentially attribute types/values.
5.  **State Variables:** Store token data, counters, configuration settings (prices, cooldowns, mutation rules, attribute options/weights), admin addresses, etc.
6.  **Modifiers:** Custom modifiers if needed (though `Ownable` provides `onlyOwner`).
7.  **ERC721 Standard Functions:** Implement or override required ERC-721 functions.
8.  **Generative Minting Logic:** Handle the minting process, including on-chain attribute generation.
9.  **Mutation/Evolution Logic:** Allow owners to trigger attribute changes based on contract rules.
10. **Attribute Management:** Functions to read token attributes.
11. **Configuration & Admin:** Functions for the contract owner to set parameters (prices, weights, rules, cooldowns, base URI, withdraw fees).
12. **View/Query Functions:** Functions to read contract state and configuration.
13. **Internal Helper Functions:** Logic for attribute generation and mutation execution.

**Function Summary (Total: 31+ functions counting ERC721 standards):**

*   **Standard ERC721 Functions (11):**
    1.  `constructor`: Initializes the contract, name, symbol, and owner.
    2.  `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
    3.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId`.
    4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token.
    5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers a token with data.
    6.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token.
    7.  `approve(address to, uint256 tokenId)`: Approves an address to manage a token.
    8.  `setApprovalForAll(address operator, bool approved)`: Approves or disapproves an operator for all tokens.
    9.  `getApproved(uint256 tokenId)`: Returns the approved address for a token.
    10. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens of an owner.
    11. `supportsInterface(bytes4 interfaceId)`: ERC-165 standard, confirms implemented interfaces (ERC721, ERC165).

*   **Core Generative & Mutation Functions (5):**
    12. `mint(uint256 count)`: Public function to mint new NFTs, paying a fee. Triggers on-chain generation.
    13. `adminMint(address to, uint256 count)`: Owner-only function to mint tokens without fee for a specific address.
    14. `triggerMutation(uint256 tokenId)`: Allows the token owner to attempt to mutate the token's attributes, subject to cooldowns and rules.
    15. `getGenerationBlock(uint256 tokenId)`: Returns the block number when the token was minted.
    16. `getTimeSinceLastMutation(uint256 tokenId)`: Returns the time elapsed since the last mutation for a token.

*   **Attribute & Metadata Functions (3):**
    17. `getTokenAttributes(uint256 tokenId)`: Returns the current on-chain attributes of a token.
    18. `tokenURI(uint256 tokenId)`: Returns the URI for the token's metadata, dynamically reflecting current attributes via an off-chain service pointer.
    19. `_generateAttributes(uint256 tokenId, address minter)`: Internal helper to generate attributes using pseudo-randomness derived from blockchain state.
    *(Note: `_generateAttributes` is internal, but included in the count logic as it's a core, distinct piece of functionality)*

*   **Configuration & Admin Functions (10):**
    20. `setBaseURI(string memory baseURI_)`: Owner-only to update the base URI for metadata.
    21. `setMintPrice(uint256 price)`: Owner-only to set the price per token for public minting.
    22. `getMintPrice()`: Returns the current mint price.
    23. `withdrawFees()`: Owner-only to withdraw accumulated Ether from minting.
    24. `setMutationCooldown(uint256 cooldownSeconds)`: Owner-only to set the minimum time between mutations for any token.
    25. `getMutationCooldown()`: Returns the current mutation cooldown period.
    26. `setAttributeWeightDistribution(string[] memory attributeNames, uint[][] memory weights)`: Owner-only to configure the probability weights for generating attribute values. (e.g., "rarity": [10, 5, 2, 1] for Common, Rare, Epic, Legendary).
    27. `getAttributeWeightDistribution()`: Returns the configured attribute names and their weights for generation.
    28. `setMutationRules(string[] memory attributeNames, uint[] memory mutationProbabilities, uint[][] memory mutationWeights)`: Owner-only to configure the probability an attribute mutates and the weights for selecting the new value if it does.
    29. `getMutationRules()`: Returns the configured mutation rules (attribute names, probabilities, new value weights).
    30. `setAllowedAttributeValues(string[] memory attributeNames, uint[][] memory allowedValues)`: Owner-only to define the possible integer values for each named attribute.

*   **Query Functions (Specific to State/Config) (2+):**
    31. `totalSupply()`: Returns the total number of tokens minted. (Standard ERC721 function, but good to list as a common query).
    32. `getAllowedAttributeValues()`: Returns the configured allowed values for each attribute name.
    33. `getLastMutationTimestamp(uint256 tokenId)`: Returns the timestamp of the last mutation for a specific token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline ---
// 1. Pragma & Imports
// 2. Custom Errors
// 3. Events
// 4. Structs & Enums
// 5. State Variables
// 6. Modifiers (Using Ownable)
// 7. ERC721 Standard Functions (Included via inheritance and overrides)
// 8. Generative Minting Logic
// 9. Mutation/Evolution Logic
// 10. Attribute Management
// 11. Configuration & Admin Functions
// 12. View/Query Functions
// 13. Internal Helper Functions (_generateAttributes, _triggerMutationLogic)

// --- Function Summary ---
// - constructor: Initializes contract details.
// - balanceOf: (ERC721)
// - ownerOf: (ERC721)
// - safeTransferFrom (overloaded): (ERC721)
// - transferFrom: (ERC721)
// - approve: (ERC721)
// - setApprovalForAll: (ERC721)
// - getApproved: (ERC721)
// - isApprovedForAll: (ERC721)
// - supportsInterface: (ERC165/ERC721)
// - mint: Public function to mint tokens with payment and on-chain generation.
// - adminMint: Owner-only minting without payment.
// - triggerMutation: Owner-only function to evolve token attributes.
// - getGenerationBlock: Get the block number when a token was minted.
// - getTimeSinceLastMutation: Calculate time since the last mutation.
// - getTokenAttributes: View a token's current attributes.
// - tokenURI: Get the metadata URI for a token.
// - setBaseURI: Owner-only to set metadata base URI.
// - setMintPrice: Owner-only to set the public minting cost.
// - getMintPrice: Get the current mint price.
// - withdrawFees: Owner-only to collect accumulated Ether.
// - setMutationCooldown: Owner-only to set minimum time between mutations.
// - getMutationCooldown: Get the current mutation cooldown.
// - setAttributeWeightDistribution: Owner-only to configure generation probabilities.
// - getAttributeWeightDistribution: Get current generation weights.
// - setMutationRules: Owner-only to configure how attributes change during mutation.
// - getMutationRules: Get current mutation rules.
// - setAllowedAttributeValues: Owner-only to define possible attribute integer values.
// - getAllowedAttributeValues: Get current allowed attribute values.
// - totalSupply: (ERC721, convenience query)
// - getLastMutationTimestamp: Get exact timestamp of last mutation.
// - _generateAttributes: Internal function for on-chain generation logic.
// - _triggerMutationLogic: Internal function for on-chain mutation execution.

contract GenerativeNFTRealm is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256; // Though not strictly necessary in 0.8+, good practice or for complex ops

    // --- 2. Custom Errors ---
    error NotEnoughEtherForMint();
    error InvalidMintCount();
    error TokenDoesNotExist();
    error NotTokenOwner();
    error MutationCooldownNotPassed();
    error InvalidAttributeConfiguration();
    error AttributeNotFound(string attributeName);
    error InvalidAttributeValues();

    // --- 3. Events ---
    event TokenMinted(uint256 indexed tokenId, address indexed minter, uint256 generationBlock, mapping(string => uint256) attributes);
    event TokenMutated(uint256 indexed tokenId, address indexed owner, uint256 mutationTimestamp, mapping(string => uint256) oldAttributes, mapping(string => uint256) newAttributes);
    event AttributeWeightsUpdated(string[] attributeNames, uint[][] weights);
    event MutationRulesUpdated(string[] attributeNames, uint[] probabilities); // Log simplified view
    event BaseURIUpdated(string newBaseURI);
    event MintPriceUpdated(uint256 newPrice);
    event MutationCooldownUpdated(uint256 newCooldown);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- 4. Structs & Enums ---
    // Using mapping for attributes allows flexible, named attributes
    struct TokenAttributes {
        mapping(string => uint256) values;
        uint256 generationBlock; // Block number when attributes were first generated
        uint256 lastMutationTimestamp; // Timestamp of the last mutation (0 for initial state)
    }

    // --- 5. State Variables ---
    uint256 private _currentTokenId;
    mapping(uint256 => TokenAttributes) private _tokenAttributes;
    string private _baseURI;

    // Minting Configuration
    uint256 private _mintPrice = 0.05 ether; // Default price
    uint256 public constant MAX_MINT_COUNT = 10; // Limit per transaction

    // Generative Attribute Configuration
    string[] private _attributeNames; // Names of attributes (e.g., "Element", "Rarity", "VisualDNA_Part1")
    mapping(string => uint[]) private _allowedAttributeValues; // Valid integer values for each attribute name
    mapping(string => uint[]) private _attributeWeights; // Weights for selecting value during *generation*

    // Mutation Configuration
    uint256 private _mutationCooldown = 7 days; // Cooldown in seconds between mutations
    mapping(string => uint) private _mutationProbabilities; // Probability (0-100) an attribute mutates
    mapping(string => uint[]) private _mutationWeights; // Weights for selecting value during *mutation*

    // --- 6. Modifiers (Inherited from Ownable) ---
    // onlyOwner

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _currentTokenId = 0;
        // Initial configuration for attributes could be set here or via admin functions
        // For simplicity, we'll require admin to set attributes via config functions later.
    }

    // --- 7. ERC721 Standard Functions ---
    // All basic ERC721 functions (balanceOf, ownerOf, transferFrom, approve, etc.)
    // are provided by inheriting from OpenZeppelin's ERC721 contract.
    // We only override tokenURI as it needs custom logic.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- 8. Generative Minting Logic ---

    /// @notice Mints a specified number of new generative tokens.
    /// @param count The number of tokens to mint (up to MAX_MINT_COUNT).
    function mint(uint256 count) external payable nonReentrant {
        if (count == 0 || count > MAX_MINT_COUNT) {
            revert InvalidMintCount();
        }
        if (msg.value < _mintPrice.mul(count)) {
            revert NotEnoughEtherForMint();
        }

        unchecked { // SafeMath no longer strictly needed in 0.8+ for basic ops
            for (uint256 i = 0; i < count; i++) {
                uint256 newItemId = _currentTokenId + 1;
                _generateAttributes(newItemId, msg.sender); // Generate attributes before minting
                _safeMint(msg.sender, newItemId); // Mint token using OpenZeppelin helper
                _currentTokenId = newItemId;
            }
        }
        // Event is emitted within _generateAttributes for initial state
    }

    /// @notice Owner-only function to mint tokens without payment.
    /// @param to The address to mint tokens for.
    /// @param count The number of tokens to mint.
    function adminMint(address to, uint256 count) external onlyOwner {
        if (count == 0) {
             revert InvalidMintCount();
        }

        unchecked {
            for (uint256 i = 0; i < count; i++) {
                uint256 newItemId = _currentTokenId + 1;
                _generateAttributes(newItemId, to); // Generate attributes
                _safeMint(to, newItemId); // Mint token
                _currentTokenId = newItemId;
            }
        }
        // Event is emitted within _generateAttributes for initial state
    }

    // --- 9. Mutation/Evolution Logic ---

    /// @notice Allows the token owner to trigger a mutation process for their token.
    /// @param tokenId The ID of the token to mutate.
    function triggerMutation(uint256 tokenId) external nonReentrant {
        if (_ownerOf(tokenId) != msg.sender) {
            revert NotTokenOwner();
        }
        if (_tokenAttributes[tokenId].generationBlock == 0) { // Check if token exists and has attributes
             revert TokenDoesNotExist();
        }
        if (block.timestamp < _tokenAttributes[tokenId].lastMutationTimestamp.add(_mutationCooldown)) {
            revert MutationCooldownNotPassed();
        }

        _triggerMutationLogic(tokenId);
    }

    /// @notice Internal function containing the core mutation logic.
    /// @param tokenId The ID of the token to mutate.
    function _triggerMutationLogic(uint256 tokenId) internal {
        TokenAttributes storage attributes = _tokenAttributes[tokenId];
        mapping(string => uint256) storage currentValues = attributes.values;

        mapping(string => uint256) memory oldValues;
        string[] memory currentAttributeNames = _attributeNames; // Use a memory copy for iteration

        // Copy current values before potential changes
        for (uint i = 0; i < currentAttributeNames.length; i++) {
             oldValues[currentAttributeNames[i]] = currentValues[currentAttributeNames[i]];
        }

        // Pseudo-randomness source for mutation
        // Using block hash is only reliable for the *current* block and can be manipulated by miners
        // A more robust system might involve commit-reveal, Chainlink VRF, or waiting several blocks.
        // For this example, we'll use a simple, potentially manipulatable source for demonstration.
        // The combination of token ID, timestamp, and block hash provides some entropy.
        bytes32 mutationSeed = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), tokenId, currentValues[currentAttributeNames[0]], _mutationCooldown)); // Use a past blockhash

        uint256 randomValue = uint256(mutationSeed);

        // Iterate through each attribute and potentially mutate it
        for (uint i = 0; i < currentAttributeNames.length; i++) {
            string memory attrName = currentAttributeNames[i];
            uint prob = _mutationProbabilities[attrName];

            if (prob > 0 && (randomValue % 100) < prob) { // Check if this attribute should mutate
                uint[] memory allowedValues = _allowedAttributeValues[attrName];
                uint[] memory mutationWeights = _mutationWeights[attrName];

                if (allowedValues.length != mutationWeights.length || allowedValues.length == 0) {
                     // Should be caught by admin config functions, but guard here too
                     continue; // Skip mutation for this attribute if config is invalid
                }

                // Select a new value based on mutation weights
                uint totalWeight = 0;
                for (uint j = 0; j < mutationWeights.length; j++) {
                    totalWeight += mutationWeights[j];
                }

                uint choice = randomValue % totalWeight;
                uint selectedValue = allowedValues[0]; // Default to first value

                uint cumulativeWeight = 0;
                for (uint j = 0; j < mutationWeights.length; j++) {
                    cumulativeWeight += mutationWeights[j];
                    if (choice < cumulativeWeight) {
                        selectedValue = allowedValues[j];
                        break;
                    }
                }

                // Update the attribute value
                currentValues[attrName] = selectedValue;
                 // Update seed for the next attribute using the outcome
                randomValue = uint256(keccak256(abi.encodePacked(randomValue, selectedValue)));
            }
             // Update seed even if no mutation occurred, using the current value
            randomValue = uint256(keccak256(abi.encodePacked(randomValue, currentValues[attrName])));
        }

        attributes.lastMutationTimestamp = block.timestamp;

        // Note: Emitting the full mapping state in events is not directly supported in Solidity < 0.8.14
        // We'll emit a simplified event or rely on external indexing services to read the new state.
        // For this example, we'll emit the old and new values by iterating.
        mapping(string => uint256) memory newValues;
         for (uint i = 0; i < currentAttributeNames.length; i++) {
             newValues[currentAttributeNames[i]] = currentValues[currentAttributeNames[i]];
         }
         // Workaround for event data - might need an indexer to reconstruct
         // event TokenMutated(tokenId, msg.sender, block.timestamp, oldValues, newValues);
         // Or emit changes granularly: event AttributeChanged(tokenId, attrName, oldValue, newValue);
         emit TokenMutated(tokenId, msg.sender, block.timestamp, oldValues, newValues); // Simplified event structure
    }

    // --- 10. Attribute & Metadata Functions ---

    /// @notice Gets the current attributes of a token.
    /// @param tokenId The ID of the token.
    /// @return An array of attribute names and an array of corresponding values.
    function getTokenAttributes(uint256 tokenId) external view returns (string[] memory names, uint256[] memory values) {
         if (_tokenAttributes[tokenId].generationBlock == 0) {
             revert TokenDoesNotExist();
         }

        string[] memory currentAttributeNames = _attributeNames;
        names = new string[](currentAttributeNames.length);
        values = new uint256[](currentAttributeNames.length);

        for (uint i = 0; i < currentAttributeNames.length; i++) {
            names[i] = currentAttributeNames[i];
            values[i] = _tokenAttributes[tokenId].values[currentAttributeNames[i]];
        }
        return (names, values);
    }

    /// @notice Returns the metadata URI for a given token ID.
    /// The metadata should reflect the token's current (potentially mutated) attributes.
    /// Assumes an off-chain service serves JSON from baseURI/tokenID.json
    /// @param tokenId The ID of the token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist();
        }
        string memory currentBaseURI = _baseURI;
        if (bytes(currentBaseURI).length == 0) {
            return ""; // Or return a default URI indicating no metadata
        }
        return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
    }

    // --- 11. Configuration & Admin Functions ---

    /// @notice Owner-only function to set the base URI for token metadata.
    /// @param baseURI_ The new base URI (e.g., "ipfs://<cid>/").
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
        emit BaseURIUpdated(baseURI_);
    }

    /// @notice Owner-only function to set the price for public minting.
    /// @param price The new price in Wei per token.
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit MintPriceUpdated(price);
    }

    /// @notice Gets the current mint price per token.
    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }

    /// @notice Owner-only function to withdraw accumulated Ether from minting.
    function withdrawFees() external onlyOwner nonReentrancy {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "Withdrawal failed");
            emit FeesWithdrawn(owner(), balance);
        }
    }

    /// @notice Owner-only function to set the minimum time required between mutations for any token.
    /// @param cooldownSeconds The cooldown period in seconds.
    function setMutationCooldown(uint256 cooldownSeconds) external onlyOwner {
        _mutationCooldown = cooldownSeconds;
        emit MutationCooldownUpdated(cooldownSeconds);
    }

    /// @notice Gets the current mutation cooldown period in seconds.
    function getMutationCooldown() external view returns (uint256) {
        return _mutationCooldown;
    }

    /// @notice Owner-only function to define the attribute names, allowed values, and their generation weights.
    /// This completely replaces the current attribute configuration.
    /// @param attributeNames The list of attribute names.
    /// @param allowedValues A 2D array where allowedValues[i] contains the possible uint values for attributeNames[i].
    /// @param weights A 2D array where weights[i] contains the generation weights for allowedValues[i].
    function setAttributeWeightDistribution(string[] memory attributeNames, uint[][] memory allowedValues, uint[][] memory weights) external onlyOwner {
        if (attributeNames.length != allowedValues.length || attributeNames.length != weights.length) {
            revert InvalidAttributeConfiguration();
        }

        // Clear previous configurations
        delete _attributeNames;
        for (uint i = 0; i < _attributeNames.length; i++) {
             delete _allowedAttributeValues[_attributeNames[i]];
             delete _attributeWeights[_attributeNames[i]];
        }
        // Reset mutation config dependent on attribute names too?
        // For simplicity, this setter assumes mutation rules will be re-set if names change.
        // In a complex system, you'd manage dependencies carefully.
        for (uint i = 0; i < _attributeNames.length; i++) {
             delete _mutationProbabilities[_attributeNames[i]];
             delete _mutationWeights[_attributeNames[i]];
        }


        _attributeNames = attributeNames;
        for (uint i = 0; i < attributeNames.length; i++) {
            string memory attrName = attributeNames[i];
            if (allowedValues[i].length != weights[i].length || allowedValues[i].length == 0) {
                 revert InvalidAttributeConfiguration();
            }
            _allowedAttributeValues[attrName] = allowedValues[i];
            _attributeWeights[attrName] = weights[i];
        }
        emit AttributeWeightsUpdated(attributeNames, weights);
    }

    /// @notice Gets the currently configured attribute names and their generation weights.
    /// @return attributeNames The configured attribute names.
    /// @return allowedValues The configured allowed values for each attribute.
    /// @return weights The configured generation weights for each attribute.
    function getAttributeWeightDistribution() external view returns (string[] memory, uint[][] memory, uint[][] memory) {
         string[] memory currentAttributeNames = _attributeNames;
         uint[][] memory currentAllowedValues = new uint[][](currentAttributeNames.length);
         uint[][] memory currentWeights = new uint[][](currentAttributeNames.length);

         for (uint i = 0; i < currentAttributeNames.length; i++) {
             currentAllowedValues[i] = _allowedAttributeValues[currentAttributeNames[i]];
             currentWeights[i] = _attributeWeights[currentAttributeNames[i]];
         }
         return (currentAttributeNames, currentAllowedValues, currentWeights);
    }

    /// @notice Owner-only function to define mutation rules: probability of mutation and weights for new values if it mutates.
    /// Requires that attributes were already defined using `setAttributeWeightDistribution`.
    /// @param attributeNames_ The list of attribute names matching the generation config.
    /// @param mutationProbabilities The probability (0-100) for each attribute mutating.
    /// @param mutationWeights A 2D array where mutationWeights[i] contains weights for selecting new value for attributeNames_[i] (must match allowed values array length).
    function setMutationRules(string[] memory attributeNames_, uint[] memory mutationProbabilities, uint[][] memory mutationWeights) external onlyOwner {
         if (attributeNames_.length != mutationProbabilities.length || attributeNames_.length != mutationWeights.length) {
             revert InvalidMutationConfiguration(); // Need a custom error for mutation config
         }

         // Check if these attribute names exist in the generation config
         mapping(string => bool) memory validNames;
         for(uint i=0; i < _attributeNames.length; i++) {
             validNames[_attributeNames[i]] = true;
         }

         for (uint i = 0; i < attributeNames_.length; i++) {
             string memory attrName = attributeNames_[i];
             if (!validNames[attrName]) {
                 revert AttributeNotFound(attrName);
             }
             if (_allowedAttributeValues[attrName].length != mutationWeights[i].length) {
                 revert InvalidAttributeConfiguration(); // Weights must match allowed values
             }
             _mutationProbabilities[attrName] = mutationProbabilities[i];
             _mutationWeights[attrName] = mutationWeights[i];
         }
          emit MutationRulesUpdated(attributeNames_, mutationProbabilities); // Log simplified view
    }

     /// @notice Gets the currently configured mutation rules.
     /// @return attributeNames The configured attribute names.
     /// @return mutationProbabilities The configured mutation probabilities.
     /// @return mutationWeights The configured mutation weights.
    function getMutationRules() external view returns (string[] memory, uint[] memory, uint[][] memory) {
        string[] memory currentAttributeNames = _attributeNames; // Assuming mutation rules exist for all defined attributes
        uint[] memory currentProbabilities = new uint[](currentAttributeNames.length);
        uint[][] memory currentMutationWeights = new uint[][](currentAttributeNames.length);

        for (uint i = 0; i < currentAttributeNames.length; i++) {
            string memory attrName = currentAttributeNames[i];
            currentProbabilities[i] = _mutationProbabilities[attrName];
            currentMutationWeights[i] = _mutationWeights[attrName];
        }
        return (currentAttributeNames, currentProbabilities, currentMutationWeights);
    }

    /// @notice Owner-only function to define the allowed integer values for each attribute name.
    /// This should ideally be called *before* setting weights or rules.
    /// @param attributeNames_ The list of attribute names.
    /// @param allowedValues_ A 2D array where allowedValues_[i] contains the possible uint values for attributeNames_[i].
    function setAllowedAttributeValues(string[] memory attributeNames_, uint[][] memory allowedValues_) external onlyOwner {
         if (attributeNames_.length != allowedValues_.length) {
             revert InvalidAttributeConfiguration();
         }

         // Clear existing
         delete _attributeNames;
         for (uint i = 0; i < _attributeNames.length; i++) {
             delete _allowedAttributeValues[_attributeNames[i]];
         }

         _attributeNames = attributeNames_;
         for (uint i = 0; i < attributeNames_.length; i++) {
             _allowedAttributeValues[attributeNames_[i]] = allowedValues_[i];
         }
         // Note: AttributeWeights and MutationRules should be re-set after this if they were already configured
         // as they depend on the length of allowed values.
    }

    // --- 12. View/Query Functions ---

    /// @notice Gets the configured allowed integer values for each attribute name.
    /// @return attributeNames The configured attribute names.
    /// @return allowedValues The configured allowed values for each attribute.
    function getAllowedAttributeValues() external view returns (string[] memory, uint[][] memory) {
        string[] memory currentAttributeNames = _attributeNames;
        uint[][] memory currentAllowedValues = new uint[][](currentAttributeNames.length);

        for (uint i = 0; i < currentAttributeNames.length; i++) {
            currentAllowedValues[i] = _allowedAttributeValues[currentAttributeNames[i]];
        }
        return (currentAttributeNames, currentAllowedValues);
    }

    /// @notice Gets the block number when the token's attributes were initially generated.
    /// @param tokenId The ID of the token.
    /// @return The block number.
    function getGenerationBlock(uint256 tokenId) external view returns (uint256) {
         if (_tokenAttributes[tokenId].generationBlock == 0) {
             revert TokenDoesNotExist();
         }
         return _tokenAttributes[tokenId].generationBlock;
    }

    /// @notice Gets the timestamp of the last mutation for a token.
    /// @param tokenId The ID of the token.
    /// @return The timestamp. Returns 0 if never mutated.
    function getLastMutationTimestamp(uint256 tokenId) external view returns (uint256) {
         if (_tokenAttributes[tokenId].generationBlock == 0) {
             revert TokenDoesNotExist();
         }
         return _tokenAttributes[tokenId].lastMutationTimestamp;
    }

    /// @notice Calculates the time elapsed since the last mutation for a token.
    /// @param tokenId The ID of the token.
    /// @return The time elapsed in seconds. Returns current timestamp if never mutated.
    function getTimeSinceLastMutation(uint256 tokenId) external view returns (uint256) {
        if (_tokenAttributes[tokenId].generationBlock == 0) {
             revert TokenDoesNotExist();
         }
        uint256 lastMutation = _tokenAttributes[tokenId].lastMutationTimestamp;
        if (lastMutation == 0) {
             // Never mutated, return time since initial generation (or block.timestamp if preferred)
             // Let's return time since generation block for clarity if mutation is 0
             return block.timestamp.sub(block.timestamp % 1 hours); // Approx, block.timestamp is precise
             // Or simply: return block.timestamp; // Indicates a long time has passed
             // Or return 0 and require caller to check getLastMutationTimestamp == 0
             // Let's return time since generation block if no mutation yet.
             return block.timestamp.sub(block.timestamp % 1 hours); // Requires storing generation timestamp too? Or approximate from block.number?
             // Simple approach: If lastMutationTimestamp is 0, return uint256 max or a special value to indicate "never".
             // Let's just return the timestamp itself and the caller checks for 0.
             return block.timestamp.sub(lastMutation); // This will be block.timestamp if lastMutation is 0
        }
        return block.timestamp.sub(lastMutation);
    }

    // --- 13. Internal Helper Functions ---

    /// @dev Internal function to handle the core logic of generating random attributes.
    /// Uses blockchain parameters for pseudo-randomness.
    /// @param tokenId The ID of the token being generated.
    /// @param minter The address minting the token (can influence tx.origin if used, but less common now).
    function _generateAttributes(uint256 tokenId, address minter) internal {
        TokenAttributes storage attributes = _tokenAttributes[tokenId];
        attributes.generationBlock = block.number;
        attributes.lastMutationTimestamp = 0; // No mutation yet

        // Pseudo-randomness source: Mix various blockchain state variables.
        // This is still predictable to miners in the current block, but harder for future blocks.
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, msg.sender, tokenId, block.chainid, _attributeNames.length));
        uint256 randomValue = uint256(seed);

        string[] memory currentAttributeNames = _attributeNames;

        // Check if attribute configuration exists
        if (currentAttributeNames.length == 0) {
             // No attributes configured, mint with empty attributes
             // Potentially log a warning or revert depending on desired behavior
             // For this design, we'll allow minting but the token will have no attributes
             // This is an edge case assuming admin configures attributes first.
             // Let's require config exists for generation.
             require(currentAttributeNames.length > 0, "No attributes configured for generation");
        }

        for (uint i = 0; i < currentAttributeNames.length; i++) {
            string memory attrName = currentAttributeNames[i];
            uint[] memory allowedValues = _allowedAttributeValues[attrName];
            uint[] memory weights = _attributeWeights[attrName];

            if (allowedValues.length != weights.length || allowedValues.length == 0) {
                // Configuration error - should ideally be caught by admin functions
                // Handle by skipping this attribute or reverting mint.
                 // Reverting mint is safer if attributes are essential.
                 revert InvalidAttributeConfiguration();
            }

            // Calculate total weight for this attribute
            uint totalWeight = 0;
            for (uint j = 0; j < weights.length; j++) {
                totalWeight += weights[j];
            }

            if (totalWeight == 0) {
                 // No weight defined, maybe default to first value or skip?
                 // Require total weight > 0
                 revert InvalidAttributeConfiguration();
            }

            // Select value based on weights
            uint choice = randomValue % totalWeight;
            uint selectedValue = allowedValues[0]; // Default to first value

            uint cumulativeWeight = 0;
            for (uint j = 0; j < weights.length; j++) {
                cumulativeWeight += weights[j];
                if (choice < cumulativeWeight) {
                    selectedValue = allowedValues[j];
                    break;
                }
            }

            // Assign the selected value
            attributes.values[attrName] = selectedValue;

            // Use the selected value to influence the next random number
            randomValue = uint256(keccak256(abi.encodePacked(randomValue, selectedValue, attrName)));
        }

        // Note: Emitting the full mapping state in events is not directly supported in Solidity < 0.8.14
        // Workaround for event data - might need an indexer to reconstruct
        mapping(string => uint256) memory initialValues;
        for (uint i = 0; i < currentAttributeNames.length; i++) {
             initialValues[currentAttributeNames[i]] = attributes.values[currentAttributeNames[i]];
        }
        // event TokenMinted(tokenId, minter, block.number, initialValues); // Simplified event structure
         emit TokenMinted(tokenId, minter, block.number, initialValues);
    }

    // Internal overrides for ERC721 hooks (optional but good practice)
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    // Override _beforeTokenTransfer and _afterTokenTransfer if needed for specific logic
    // e.g., pausing mutations during transfer, though not implemented here.

    // --- Query Total Supply ---
    // ERC721 already provides totalSupply via _owners.length or _tokenSupply.
    // For clarity, we can add an explicit view function.
    function totalSupply() public view returns (uint256) {
        return _currentTokenId; // Assumes tokens are minted sequentially from 1
    }

     // --- Helper to get owner (used internally by triggerMutation) ---
    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = ownerOf(tokenId); // Calls ERC721 ownerOf
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
}
```