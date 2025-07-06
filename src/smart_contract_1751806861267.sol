Okay, let's create a smart contract that represents Generative Art NFTs where the traits are determined and stored on-chain using a pseudo-random process based on block data at the time of minting. Users can interact with their NFTs by "burning" specific traits to potentially regenerate them based on a new pseudo-random input. This incorporates generative elements, dynamic state (traits changing), and a unique interaction mechanic.

We will include standard ERC721 and ERC2981 (NFT Royalties) functionality as a base, and then build the custom generative and interactive logic on top.

---

## Smart Contract Outline & Function Summary

**Contract Name:** `GenerativeArtNFT`

**Description:**
An ERC721 and ERC2981 compliant NFT contract where each token's visual characteristics (traits) are generated deterministically on-chain at the time of minting using block data and transaction sender. Holders can "burn" a specific trait of their NFT to attempt a regeneration of that trait, introducing a dynamic element and interaction mechanic.

**Core Concepts:**
*   **On-chain Generative Art:** Traits are generated and stored directly on the blockchain.
*   **Deterministic Generation:** Uses block data, timestamp, sender, and token ID for verifiable (though not cryptographically secure) pseudo-randomness.
*   **Dynamic NFTs:** Traits can change post-mint via the `burnAndReplaceTrait` function.
*   **Trait Management:** Admin can define trait types, possible values, and generation/burn weights.
*   **Burn Mechanic:** Users pay a fee (or meet a condition) to replace a trait, introducing risk/reward.
*   **ERC721 & ERC2981 Compliance:** Standard NFT ownership and royalty features.

**Function Summary:**

**I. Standard ERC721 Functions (Overridden/Implemented):**
1.  `balanceOf(address owner) external view returns (uint256)`: Returns the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId) external view returns (address)`: Returns the owner of a specific token ID.
3.  `approve(address to, uint256 tokenId) external`: Approves an address to transfer a specific token.
4.  `getApproved(uint256 tokenId) external view returns (address)`: Gets the approved address for a token.
5.  `setApprovalForAll(address operator, bool approved) external`: Sets approval for an operator for all tokens of sender.
6.  `isApprovedForAll(address owner, address operator) external view returns (bool)`: Checks if an operator is approved for all tokens of an owner.
7.  `transferFrom(address from, address to, uint256 tokenId) external`: Transfers ownership of a token.
8.  `safeTransferFrom(address from, address to, uint256 tokenId) external`: Safe transfer function.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data) external`: Safe transfer function with data.
10. `supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)`: ERC165 standard for interface detection (includes ERC721 and ERC2981).

**II. Standard ERC2981 (NFT Royalty Standard) Functions:**
11. `setDefaultRoyalty(address recipient, uint96 royaltyFraction) external onlyOwner`: Sets the default royalty recipient and percentage for all tokens.
12. `royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address receiver, uint256 royaltyAmount)`: Returns royalty information for a specific token and sale price.

**III. Admin / Setup Functions (Owner Only):**
13. `setBaseURI(string memory newBaseURI) external onlyOwner`: Sets the base URI for token metadata.
14. `setMintPrice(uint256 price) external onlyOwner`: Sets the price required to mint a token.
15. `toggleMintingActive() external onlyOwner`: Activates or deactivates public minting.
16. `withdraw() external onlyOwner`: Withdraws contract balance to the owner.
17. `addTraitType(string memory traitTypeName) external onlyOwner`: Defines a new category for traits (e.g., "Background", "Shape").
18. `addTraitValue(uint256 traitTypeId, string memory traitValueName) external onlyOwner`: Adds a possible value for a specific trait type (e.g., "Blue" for "Background").
19. `setTraitGenerationWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner`: Sets the weight for a trait value during initial minting generation. Higher weight = more likely.
20. `setTraitBurnWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner`: Sets the weight/difficulty associated with *burning* this specific trait value. Used in the burn mechanic cost/logic.
21. `setBurnReplacementGenerationWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner`: Sets the weight for a trait value during the *burn-and-replace* generation process. Can differ from initial generation weights.
22. `setTraitBurnFee(uint256 traitTypeId, uint256 feeAmount) external onlyOwner`: Sets the ETH fee required to burn and replace a trait of a specific type.

**IV. Minting Functions:**
23. `mint() external payable`: Mints a new token. Requires payment of the mint price. Triggers on-chain trait generation.

**V. Trait Interaction Functions:**
24. `burnAndReplaceTrait(uint256 tokenId, uint256 traitTypeId) external payable`: Allows the token owner to burn a specific trait of their NFT and regenerate a new one for that trait type. Requires payment of the burn fee for that trait type.

**VI. Query Functions:**
25. `getTokenTraitSet(uint256 tokenId) external view returns (uint256[] memory traitValueIds)`: Returns the current trait value IDs for all trait types for a given token.
26. `getTraitTypeCount() external view returns (uint256)`: Returns the total number of defined trait types.
27. `getTraitTypeDetails(uint256 traitTypeId) external view returns (string memory name, uint256[] memory valueIds)`: Returns details about a specific trait type.
28. `getTraitValueDetails(uint256 traitTypeId, uint256 traitValueId) external view returns (string memory name, uint256 genWeight, uint256 burnWeight, uint256 burnReplaceGenWeight)`: Returns details about a specific trait value.
29. `getTraitBurnFee(uint256 traitTypeId) external view returns (uint256)`: Returns the burn fee for a specific trait type.
30. `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates the metadata URI for a token, including the on-chain traits as attributes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// --- Outline & Function Summary (See above) ---

contract GenerativeArtNFT is ERC721Enumerable, ERC721URIStorage, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct TraitValue {
        string name; // e.g., "Blue Background", "Circle Shape"
        uint256 genWeight; // Weight for initial generation
        uint256 burnWeight; // Weight/factor for burn mechanic cost/chance (conceptual here as fee)
        uint256 burnReplaceGenWeight; // Weight for generation after burning
    }

    struct TraitType {
        string name; // e.g., "Background", "Shape"
        TraitValue[] values; // Array of possible trait values for this type
        mapping(uint256 => uint256) valueIdToIndex; // Map value ID to array index for quick lookup
        uint256 totalGenWeight; // Sum of genWeights for quick random selection
        uint256 totalBurnReplaceGenWeight; // Sum of burnReplaceGenWeights
        uint256 burnFee; // ETH fee to burn a trait of this type
    }

    // Maps trait type ID to TraitType struct
    TraitType[] private _traitTypes;
    mapping(uint256 => uint256) private _traitTypeIdToIndex; // Map trait type ID to array index
    uint256 private _nextTraitTypeId = 0; // Counter for unique trait type IDs

    // Maps token ID to an array of selected TraitValue IDs
    mapping(uint256 => uint256[] _tokenTraits);

    // Contract state
    string private _baseTokenURI;
    uint256 private _mintPrice = 0.0 ether;
    bool private _mintingActive = false;

    // ERC2981 Royalty State
    address private _defaultRoyaltyRecipient;
    uint96 private _defaultRoyaltyFraction = 0; // Royalty fraction * 10000 (e.g., 2.5% is 250) - Note: ERC2981 uses uint96, 10000 basis points is standard. My bad, uint96 is fine, but standard is basis points on salePrice / 10000. Let's use fraction of 10000.

    // --- Events ---
    event MintPriceUpdated(uint256 newPrice);
    event MintingStatusUpdated(bool isActive);
    event TraitTypeAdded(uint256 indexed traitTypeId, string name);
    event TraitValueAdded(uint256 indexed traitTypeId, uint256 indexed traitValueId, string name);
    event TraitGenerationWeightSet(uint256 indexed traitTypeId, uint256 indexed traitValueId, uint256 weight);
    event TraitBurnWeightSet(uint256 indexed traitTypeId, uint256 indexed traitValueId, uint256 weight);
    event BurnReplaceGenWeightSet(uint256 indexed traitTypeId, uint256 indexed traitValueId, uint256 weight);
    event TraitBurnFeeSet(uint256 indexed traitTypeId, uint256 fee);
    event TokenMinted(uint256 indexed tokenId, address indexed minter, uint256[] traitValueIds);
    event TraitBurnedAndReplaced(uint256 indexed tokenId, uint256 indexed traitTypeId, uint256 oldTraitValueId, uint256 newTraitValueId);
    event DefaultRoyaltySet(address indexed recipient, uint96 royaltyFraction);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        _baseTokenURI = baseURI;
        _tokenIdCounter.increment(); // Start counter at 1
    }

    // --- Standard ERC721 Overrides ---
    // 1. balanceOf
    // 2. ownerOf
    // 3. approve
    // 4. getApproved
    // 5. setApprovalForAll
    // 6. isApprovedForAll
    // 7. transferFrom
    // 8. safeTransferFrom (2 overloads)
    // These are provided by ERC721Enumerable, ERC721URIStorage, and ERC721.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint120 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    // 10. supportsInterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721URIStorage, IERC165, IERC2981)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Standard ERC2981 Functions ---
    // 11. setDefaultRoyalty
    function setDefaultRoyalty(address recipient, uint96 royaltyFraction) external onlyOwner {
        require(recipient != address(0), "ERC2981: invalid royalty recipient");
        require(royaltyFraction <= 10000, "ERC2981: royalty fraction exceeds 100%"); // Max 100% of sale price
        _defaultRoyaltyRecipient = recipient;
        _defaultRoyaltyFraction = royaltyFraction;
        emit DefaultRoyaltySet(recipient, royaltyFraction);
    }

    // 12. royaltyInfo
    function royaltyInfo(uint256 /* tokenId */, uint256 salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (_defaultRoyaltyRecipient == address(0) || _defaultRoyaltyFraction == 0) {
            return (address(0), 0);
        }
        return (_defaultRoyaltyRecipient, (salePrice * _defaultRoyaltyFraction) / 10000);
    }

    // --- Admin / Setup Functions ---
    // 13. setBaseURI
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    // 14. setMintPrice
    function setMintPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
        emit MintPriceUpdated(price);
    }

    // 15. toggleMintingActive
    function toggleMintingActive() external onlyOwner {
        _mintingActive = !_mintingActive;
        emit MintingStatusUpdated(_mintingActive);
    }

    // 16. withdraw
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // 17. addTraitType
    function addTraitType(string memory traitTypeName) external onlyOwner {
        uint256 traitTypeId = _nextTraitTypeId++;
        uint256 index = _traitTypes.length;
        _traitTypes.push(); // Add a new TraitType at the end
        _traitTypes[index].name = traitTypeName;
        _traitTypeIdToIndex[traitTypeId] = index;
        emit TraitTypeAdded(traitTypeId, traitTypeName);
    }

    // 18. addTraitValue
    function addTraitValue(uint256 traitTypeId, string memory traitValueName) external onlyOwner {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];

        uint256 traitValueId = traitType.values.length; // Use array length as value ID
        traitType.values.push(); // Add new TraitValue
        traitType.values[traitValueId].name = traitValueName;
        traitType.valueIdToIndex[traitValueId] = traitValueId; // valueId = index here

        emit TraitValueAdded(traitTypeId, traitValueId, traitValueName);
    }

    // Internal helper to update total weights
    function _updateTotalWeights(uint256 traitTypeIndex) internal {
        TraitType storage traitType = _traitTypes[traitTypeIndex];
        traitType.totalGenWeight = 0;
        traitType.totalBurnReplaceGenWeight = 0;
        for (uint256 i = 0; i < traitType.values.length; i++) {
            traitType.totalGenWeight += traitType.values[i].genWeight;
            traitType.totalBurnReplaceGenWeight += traitType.values[i].burnReplaceGenWeight;
        }
    }

    // 19. setTraitGenerationWeight
    function setTraitGenerationWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];
        require(traitType.valueIdToIndex.containsKey(traitValueId), "Invalid trait value ID");
        uint256 valueIndex = traitType.valueIdToIndex[traitValueId];

        traitType.values[valueIndex].genWeight = weight;
        _updateTotalWeights(traitTypeIndex); // Recalculate total weight
        emit TraitGenerationWeightSet(traitTypeId, traitValueId, weight);
    }

    // 20. setTraitBurnWeight
    function setTraitBurnWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];
        require(traitType.valueIdToIndex.containsKey(traitValueId), "Invalid trait value ID");
        uint256 valueIndex = traitType.valueIdToIndex[traitValueId];

        traitType.values[valueIndex].burnWeight = weight;
        // No total weight update needed for burn weight if used for fee/chance calculation per trait
        emit TraitBurnWeightSet(traitTypeId, traitValueId, weight);
    }

    // 21. setBurnReplacementGenerationWeight
    function setBurnReplacementGenerationWeight(uint256 traitTypeId, uint256 traitValueId, uint256 weight) external onlyOwner {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];
        require(traitType.valueIdToIndex.containsKey(traitValueId), "Invalid trait value ID");
        uint256 valueIndex = traitType.valueIdToIndex[traitValueId];

        traitType.values[valueIndex].burnReplaceGenWeight = weight;
        _updateTotalWeights(traitTypeIndex); // Recalculate total weight
        emit BurnReplaceGenWeightSet(traitTypeId, traitValueId, weight);
    }

     // 22. setTraitBurnFee
    function setTraitBurnFee(uint256 traitTypeId, uint256 feeAmount) external onlyOwner {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        _traitTypes[traitTypeIndex].burnFee = feeAmount;
        emit TraitBurnFeeSet(traitTypeId, feeAmount);
    }


    // --- Internal Generative Logic ---

    // Uses block data and other inputs to generate a pseudo-random number
    function _generateRandomSeed(uint256 inputTokenId) internal view returns (uint256) {
        // NOTE: Block hash is deprecated/unreliable after The Merge for randomness.
        // tx.origin can be manipulated.
        // This is for VERIFIABLE DETERMINISTIC generation, not cryptographically secure randomness.
        // For secure randomness, use Chainlink VRF or similar oracle solutions.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Use with caution/awareness post-merge
            block.number,
            msg.sender,
            inputTokenId,
            _tokenIdCounter.current() // Include global counter state
        )));
        return seed;
    }

    // Selects a trait value based on weights and a seed
    function _selectTraitValue(TraitType storage traitType, uint256 seed, bool useBurnReplaceWeights) internal view returns (uint256 selectedValueId) {
        uint256 totalWeight = useBurnReplaceWeights ? traitType.totalBurnReplaceGenWeight : traitType.totalGenWeight;
        require(totalWeight > 0, "Trait type has no weighted values");

        uint256 randomNumber = seed % totalWeight; // Get a number within the total weight range
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < traitType.values.length; i++) {
            uint256 weight = useBurnReplaceWeights ? traitType.values[i].burnReplaceGenWeight : traitType.values[i].genWeight;
            cumulativeWeight += weight;
            if (randomNumber < cumulativeWeight) {
                // Found the selected trait value
                return traitType.valueIdToIndex.getKey(i); // Get the original value ID
            }
        }
        // Fallback - should not happen if totalWeight > 0 and loop is correct
        return traitType.valueIdToIndex.getKey(0); // Return the first value
    }

    // Internal function to generate all traits for a new token
    function _generateTraits(uint256 tokenId) internal view returns (uint256[] memory) {
        uint256 numTraitTypes = _traitTypes.length;
        require(numTraitTypes > 0, "No trait types defined");

        uint256[] memory generatedValueIds = new uint256[](numTraitTypes);
        uint256 seed = _generateRandomSeed(tokenId); // Use a unique seed per token

        for (uint256 i = 0; i < numTraitTypes; i++) {
            TraitType storage traitType = _traitTypes[i];
            // Use a portion of the seed or a derived seed for each trait type
            uint256 typeSeed = uint256(keccak256(abi.encodePacked(seed, i)));
            generatedValueIds[i] = _selectTraitValue(traitType, typeSeed, false); // Use initial generation weights
        }
        return generatedValueIds;
    }

    // Internal function to generate a single trait value
    function _generateSingleTrait(uint256 tokenId, uint256 traitTypeId, uint256 seed) internal view returns (uint256 selectedValueId) {
         require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
         uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
         TraitType storage traitType = _traitTypes[traitTypeIndex];

         return _selectTraitValue(traitType, seed, true); // Use burn replacement weights
    }


    // --- Minting Function ---
    // 23. mint
    function mint() external payable {
        require(_mintingActive, "Minting is not active");
        require(msg.value >= _mintPrice, "Insufficient ETH sent");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Generate traits on-chain
        uint256[] memory generatedTraitValueIds = _generateTraits(newTokenId);
        _tokenTraits[newTokenId] = generatedTraitValueIds;

        // Mint the token
        _safeMint(msg.sender, newTokenId);

        emit TokenMinted(newTokenId, msg.sender, generatedTraitValueIds);
    }

    // --- Trait Interaction Function ---
    // 24. burnAndReplaceTrait
    function burnAndReplaceTrait(uint256 tokenId, uint256 traitTypeId) external payable {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(_tokenTraits[tokenId].length > 0, "Traits not generated for this token"); // Should always be true after mint

        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];

        uint256 requiredFee = traitType.burnFee; // Fee is set per trait type
        require(msg.value >= requiredFee, "Insufficient ETH sent for burn fee");

        // Get the index of this trait type in the token's traits array
        // This assumes trait types are stored in the tokenTraits array in the order they were added
        // A more robust way would be to store {typeId: valueId} mapping per token, but arrays are gas friendlier
        // Let's stick to array indexing mapping to trait type creation order for simplicity in this example
        // This means the Nth element in _tokenTraits[tokenId] corresponds to the Nth trait type added via addTraitType
        require(traitTypeIndex < _tokenTraits[tokenId].length, "Trait type index out of bounds for token traits");

        uint256 oldTraitValueId = _tokenTraits[tokenId][traitTypeIndex];

        // Generate a new trait value for this specific type
        // Use block hash + transaction sender + token ID + trait type ID as seed for new generation
        uint256 replacementSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            tx.origin, // Using tx.origin here to make it slightly different from mint seed
            tokenId,
            traitTypeId,
            block.number // Include block number again
        )));
        uint256 newTraitValueId = _generateSingleTrait(tokenId, traitTypeId, replacementSeed);

        // Update the trait
        _tokenTraits[tokenId][traitTypeIndex] = newTraitValueId;

        emit TraitBurnedAndReplaced(tokenId, traitTypeId, oldTraitValueId, newTraitValueId);

        // Refund excess ETH if any
        if (msg.value > requiredFee) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - requiredFee}("");
             require(success, "Excess ETH refund failed");
        }
    }


    // --- Query Functions ---
    // 25. getTokenTraitSet
    function getTokenTraitSet(uint256 tokenId) external view returns (uint256[] memory traitValueIds) {
        require(_exists(tokenId), "Token does not exist");
        // Return a copy of the internal array
        return _tokenTraits[tokenId];
    }

    // 26. getTraitTypeCount
    function getTraitTypeCount() external view returns (uint256) {
        return _traitTypes.length;
    }

    // 27. getTraitTypeDetails
    function getTraitTypeDetails(uint256 traitTypeId) external view returns (string memory name, uint256[] memory valueIds) {
         require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
         uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
         TraitType storage traitType = _traitTypes[traitTypeIndex];

         name = traitType.name;
         valueIds = new uint256[](traitType.values.length);
         for(uint256 i = 0; i < traitType.values.length; i++) {
             valueIds[i] = traitType.valueIdToIndex.getKey(i); // Get the original value ID
         }
         return (name, valueIds);
    }

    // 28. getTraitValueDetails
    function getTraitValueDetails(uint256 traitTypeId, uint256 traitValueId) external view returns (string memory name, uint256 genWeight, uint256 burnWeight, uint256 burnReplaceGenWeight) {
        require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
        uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
        TraitType storage traitType = _traitTypes[traitTypeIndex];
        require(traitType.valueIdToIndex.containsKey(traitValueId), "Invalid trait value ID");
        uint256 valueIndex = traitType.valueIdToIndex[traitValueId];
        TraitValue storage traitValue = traitType.values[valueIndex];

        return (traitValue.name, traitValue.genWeight, traitValue.burnWeight, traitValue.burnReplaceGenWeight);
    }

    // 29. getTraitBurnFee
    function getTraitBurnFee(uint256 traitTypeId) external view returns (uint256) {
         require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
         uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
         return _traitTypes[traitTypeIndex].burnFee;
    }

    // --- Metadata / URI Functions ---
    // 30. tokenURI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        uint256[] memory tokenTraits = _tokenTraits[tokenId];
        require(tokenTraits.length == _traitTypes.length, "Traits not generated or inconsistent for token");

        // Build JSON metadata string
        string memory json = string(abi.encodePacked(
            '{"name": "', name(), ' #', Strings.toString(tokenId), '",',
            '"description": "A unique piece of on-chain generative art.",',
            '"image": "', _baseTokenURI, Strings.toString(tokenId), '.svg",', // Assuming an off-chain renderer or SVG generator at this URI
            '"attributes": ['
        ));

        for (uint256 i = 0; i < tokenTraits.length; i++) {
            uint256 traitTypeId = _traitTypeIdToIndex.getKey(i); // Get original trait type ID from index
            TraitType storage traitType = _traitTypes[i]; // Using index directly as we iterate through the token's traits array which follows type definition order
            uint256 traitValueId = tokenTraits[i];

            require(traitType.valueIdToIndex.containsKey(traitValueId), "Invalid trait value ID stored");
            uint256 valueIndex = traitType.valueIdToIndex[traitValueId];
            TraitValue storage traitValue = traitType.values[valueIndex];

            json = string(abi.encodePacked(
                json,
                '{"trait_type": "', traitType.name, '", "value": "', traitValue.name, '"}'
            ));
            if (i < tokenTraits.length - 1) {
                json = string(abi.encodePacked(json, ','));
            }
        }

        json = string(abi.encodePacked(json, '] }'));

        // Encode as Base64 data URI
        string memory base64Json = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base66,", base64Json)); // Use base64, not base66
    }

    // --- Internal utility to find key by value in map, needed because we use array indices as primary keys for storage ---
    // This is a workaround for Solidity's map limitations. For production, a more efficient structure might be needed
    // or iterate through trait types to find index by ID. Current setup maps ID to index at creation.

     // Maps index to original ID
    mapping(uint256 => uint256) private _traitTypeIndexToId;
     mapping(uint256 => mapping(uint256 => uint256)) private _traitValueIndexToId; // traitTypeIndex => valueIndex => valueId


     // Override addTraitType and addTraitValue to populate these lookup maps
    function addTraitType(string memory traitTypeName) public override onlyOwner {
         uint256 traitTypeId = _nextTraitTypeId++;
         uint256 index = _traitTypes.length;
         _traitTypes.push(); // Add a new TraitType at the end
         _traitTypes[index].name = traitTypeName;
         _traitTypeIdToIndex[traitTypeId] = index;
         _traitTypeIndexToId[index] = traitTypeId; // Store index -> ID mapping
         emit TraitTypeAdded(traitTypeId, traitTypeName);
     }

     function addTraitValue(uint256 traitTypeId, string memory traitValueName) public override onlyOwner {
         require(_traitTypeIdToIndex.containsKey(traitTypeId), "Invalid trait type ID");
         uint256 traitTypeIndex = _traitTypeIdToIndex[traitTypeId];
         TraitType storage traitType = _traitTypes[traitTypeIndex];

         uint256 traitValueId = traitType.values.length; // Use array length as value ID *initially*
         traitType.values.push(); // Add new TraitValue
         traitType.values[traitValueId].name = traitValueName;
         traitType.valueIdToIndex[traitValueId] = traitValueId; // valueId = index here

         _traitValueIndexToId[traitTypeIndex][traitValueId] = traitValueId; // Store valueIndex -> valueId mapping

         emit TraitValueAdded(traitTypeId, traitValueId, traitValueName);
     }

    // Helper function to get the original ID from an index
    // Used in tokenURI and getTraitTypeDetails to return original IDs to clients
    // This assumes the array index corresponds to the order items were added.
    // A map (index => ID) is more explicit. Let's add those maps.
    function _getTraitTypeIdFromIndex(uint256 index) internal view returns (uint256) {
        require(index < _traitTypes.length, "Invalid trait type index");
        return _traitTypeIndexToId[index];
    }

    function _getTraitValueIdFromIndex(uint256 traitTypeIndex, uint256 valueIndex) internal view returns (uint256) {
         require(traitTypeIndex < _traitTypes.length, "Invalid trait type index");
         require(valueIndex < _traitTypes[traitTypeIndex].values.length, "Invalid trait value index");
         return _traitValueIndexToId[traitTypeIndex][valueIndex];
    }

     // Update _selectTraitValue to return the actual Value ID, not index
     function _selectTraitValue(TraitType storage traitType, uint256 seed, bool useBurnReplaceWeights) internal view returns (uint256 selectedValueId) {
        uint256 totalWeight = useBurnReplaceWeights ? traitType.totalBurnReplaceGenWeight : traitType.totalGenWeight;
        require(totalWeight > 0, "Trait type has no weighted values");

        uint256 randomNumber = seed % totalWeight; // Get a number within the total weight range
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < traitType.values.length; i++) {
            uint256 weight = useBurnReplaceWeights ? traitType.values[i].burnReplaceGenWeight : traitType.values[i].genWeight;
            cumulativeWeight += weight;
            if (randomNumber < cumulativeWeight) {
                // Found the selected trait value by index 'i'
                return _traitValueIndexToId[ _traitTypeIdToIndex[_getTraitTypeIdFromIndex( _traitTypes.indexOf(traitType) )] ][i]; // Get the original value ID
            }
        }
         // Fallback - should not happen
         return _traitValueIndexToId[ _traitTypeIdToIndex[_getTraitTypeIdFromIndex( _traitTypes.indexOf(traitType) )] ][0]; // Return the first value ID
     }

     // Need a way to get index of a TraitType storage reference. This is not possible directly.
     // Re-think index/ID mapping. Using array indices directly as IDs is simpler and avoids these complex lookups.
     // Let's simplify and use array indices as the *de facto* IDs for both TraitTypes and TraitValues *within the contract*.
     // Clients will query by these indices. This reduces complexity and gas.

    // --- Simplified Trait Management (Using Array Indices as IDs) ---

    struct SimplifiedTraitValue {
        string name;
        uint256 genWeight;
        uint256 burnWeight;
        uint256 burnReplaceGenWeight;
    }

    struct SimplifiedTraitType {
        string name;
        SimplifiedTraitValue[] values; // Array of possible trait values for this type
        uint256 totalGenWeight;
        uint256 totalBurnReplaceGenWeight;
        uint256 burnFee;
    }

    SimplifiedTraitType[] private _traitTypesSimple;
    mapping(uint256 => uint256[] _tokenTraitsSimple); // Maps token ID to array of TraitValue indices

    // Override back to simpler add/set functions
    function addTraitType(string memory traitTypeName) public override onlyOwner {
         _traitTypesSimple.push();
         _traitTypesSimple[_traitTypesSimple.length - 1].name = traitTypeName;
         emit TraitTypeAdded(_traitTypesSimple.length - 1, traitTypeName); // Emitting index as ID
    }

     function addTraitValue(uint256 traitTypeIndex, string memory traitValueName) public override onlyOwner {
         require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
         SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
         traitType.values.push();
         traitType.values[traitType.values.length - 1].name = traitValueName;
         emit TraitValueAdded(traitTypeIndex, traitType.values.length - 1, traitValueName); // Emitting indices as IDs
    }

    // Update setters to use simple index
    function setTraitGenerationWeight(uint256 traitTypeIndex, uint256 traitValueIndex, uint256 weight) public override onlyOwner {
        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
        require(traitValueIndex < traitType.values.length, "Invalid trait value index");
        traitType.values[traitValueIndex].genWeight = weight;
        _updateTotalWeightsSimple(traitTypeIndex);
        emit TraitGenerationWeightSet(traitTypeIndex, traitValueIndex, weight);
    }

    function setTraitBurnWeight(uint256 traitTypeIndex, uint256 traitValueIndex, uint256 weight) public override onlyOwner {
        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
        require(traitValueIndex < traitType.values.length, "Invalid trait value index");
        traitType.values[traitValueIndex].burnWeight = weight;
        emit TraitBurnWeightSet(traitTypeIndex, traitValueIndex, weight);
    }

    function setBurnReplacementGenerationWeight(uint256 traitTypeIndex, uint256 traitValueIndex, uint256 weight) public override onlyOwner {
        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
        require(traitValueIndex < traitType.values.length, "Invalid trait value index");
        traitType.values[traitValueIndex].burnReplaceGenWeight = weight;
        _updateTotalWeightsSimple(traitTypeIndex);
        emit BurnReplaceGenWeightSet(traitTypeIndex, traitValueIndex, weight);
    }

    function setTraitBurnFee(uint256 traitTypeIndex, uint256 feeAmount) public override onlyOwner {
        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        _traitTypesSimple[traitTypeIndex].burnFee = feeAmount;
        emit TraitBurnFeeSet(traitTypeIndex, feeAmount);
    }

    // Update simple weight calculation
    function _updateTotalWeightsSimple(uint256 traitTypeIndex) internal {
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
        traitType.totalGenWeight = 0;
        traitType.totalBurnReplaceGenWeight = 0;
        for (uint256 i = 0; i < traitType.values.length; i++) {
            traitType.totalGenWeight += traitType.values[i].genWeight;
            traitType.totalBurnReplaceGenWeight += traitType.values[i].burnReplaceGenWeight;
        }
    }


    // Update trait selection to use simple structs and indices
    function _selectTraitValueSimple(SimplifiedTraitType storage traitType, uint256 seed, bool useBurnReplaceWeights) internal view returns (uint256 selectedValueIndex) {
        uint256 totalWeight = useBurnReplaceWeights ? traitType.totalBurnReplaceGenWeight : traitType.totalGenWeight;
        require(totalWeight > 0, "Trait type has no weighted values");

        uint256 randomNumber = seed % totalWeight;
        uint256 cumulativeWeight = 0;

        for (uint256 i = 0; i < traitType.values.length; i++) {
            uint256 weight = useBurnReplaceWeights ? traitType.values[i].burnReplaceGenWeight : traitType.values[i].genWeight;
            cumulativeWeight += weight;
            if (randomNumber < cumulativeWeight) {
                return i; // Return the index
            }
        }
        return 0; // Fallback
    }

    // Update generation functions to use simple structs
    function _generateTraitsSimple(uint256 tokenId) internal view returns (uint256[] memory) {
        uint256 numTraitTypes = _traitTypesSimple.length;
        require(numTraitTypes > 0, "No trait types defined");

        uint256[] memory generatedValueIndices = new uint256[](numTraitTypes);
        uint256 seed = _generateRandomSeed(tokenId);

        for (uint256 i = 0; i < numTraitTypes; i++) {
            SimplifiedTraitType storage traitType = _traitTypesSimple[i];
             uint256 typeSeed = uint256(keccak256(abi.encodePacked(seed, i)));
            generatedValueIndices[i] = _selectTraitValueSimple(traitType, typeSeed, false);
        }
        return generatedValueIndices;
    }

     function _generateSingleTraitSimple(uint256 tokenId, uint256 traitTypeIndex, uint256 seed) internal view returns (uint256 selectedValueIndex) {
         require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
         SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
         return _selectTraitValueSimple(traitType, seed, true);
     }


    // Update mint function to use simple logic
    function mint() public override payable {
        require(_mintingActive, "Minting is not active");
        require(msg.value >= _mintPrice, "Insufficient ETH sent");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Generate traits on-chain
        uint256[] memory generatedTraitValueIndices = _generateTraitsSimple(newTokenId);
        _tokenTraitsSimple[newTokenId] = generatedTraitValueIndices;

        // Mint the token
        _safeMint(msg.sender, newTokenId);

        emit TokenMinted(newTokenId, msg.sender, generatedTraitValueIndices); // Still emit value IDs/indices
    }

    // Update burn function to use simple logic and indices
    function burnAndReplaceTrait(uint256 tokenId, uint256 traitTypeIndex) public override payable {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner");
        require(_tokenTraitsSimple[tokenId].length > 0, "Traits not generated for this token");

        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];

        uint256 requiredFee = traitType.burnFee;
        require(msg.value >= requiredFee, "Insufficient ETH sent for burn fee");

        require(traitTypeIndex < _tokenTraitsSimple[tokenId].length, "Trait type index out of bounds for token traits");

        uint256 oldTraitValueIndex = _tokenTraitsSimple[tokenId][traitTypeIndex];

        uint256 replacementSeed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            tx.origin,
            tokenId,
            traitTypeIndex,
            block.number,
            oldTraitValueIndex // Include old value in seed for variability
        )));
        uint256 newTraitValueIndex = _generateSingleTraitSimple(tokenId, traitTypeIndex, replacementSeed);

        _tokenTraitsSimple[tokenId][traitTypeIndex] = newTraitValueIndex;

        emit TraitBurnedAndReplaced(tokenId, traitTypeIndex, oldTraitValueIndex, newTraitValueIndex); // Emit indices

         if (msg.value > requiredFee) {
             (bool success, ) = payable(msg.sender).call{value: msg.value - requiredFee}("");
             require(success, "Excess ETH refund failed");
        }
    }

    // Update query functions to use simple structs and indices
    function getTokenTraitSet(uint256 tokenId) public override view returns (uint256[] memory traitValueIndices) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenTraitsSimple[tokenId];
    }

    function getTraitTypeCount() public override view returns (uint256) {
        return _traitTypesSimple.length;
    }

    function getTraitTypeDetails(uint256 traitTypeIndex) public override view returns (string memory name, uint256[] memory valueIndices) {
         require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
         SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];

         name = traitType.name;
         valueIndices = new uint256[](traitType.values.length);
         for(uint256 i = 0; i < traitType.values.length; i++) {
             valueIndices[i] = i; // Index is the ID
         }
         return (name, valueIndices);
    }

    function getTraitValueDetails(uint256 traitTypeIndex, uint256 traitValueIndex) public override view returns (string memory name, uint256 genWeight, uint256 burnWeight, uint256 burnReplaceGenWeight) {
        require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
        SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
        require(traitValueIndex < traitType.values.length, "Invalid trait value index");
        SimplifiedTraitValue storage traitValue = traitType.values[traitValueIndex];

        return (traitValue.name, traitValue.genWeight, traitValue.burnWeight, traitValue.burnReplaceGenWeight);
    }

    function getTraitBurnFee(uint256 traitTypeIndex) public override view returns (uint256) {
         require(traitTypeIndex < _traitTypesSimple.length, "Invalid trait type index");
         return _traitTypesSimple[traitTypeIndex].burnFee;
    }

    // Update tokenURI to use simple structs and indices
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        uint256[] memory tokenTraitIndices = _tokenTraitsSimple[tokenId];
        require(tokenTraitIndices.length == _traitTypesSimple.length, "Traits not generated or inconsistent for token");

        string memory json = string(abi.encodePacked(
            '{"name": "', name(), ' #', Strings.toString(tokenId), '",',
            '"description": "A unique piece of on-chain generative art.",',
            '"image": "', _baseTokenURI, Strings.toString(tokenId), '.svg",', // Still assumes external renderer
            '"attributes": ['
        ));

        for (uint256 i = 0; i < tokenTraitIndices.length; i++) {
            uint256 traitTypeIndex = i; // Index in the tokenTraits array corresponds to the trait type index
            SimplifiedTraitType storage traitType = _traitTypesSimple[traitTypeIndex];
            uint256 traitValueIndex = tokenTraitIndices[i];

            require(traitValueIndex < traitType.values.length, "Invalid trait value index stored");
            SimplifiedTraitValue storage traitValue = traitType.values[traitValueIndex];

            json = string(abi.encodePacked(
                json,
                '{"trait_type": "', traitType.name, '", "value": "', traitValue.name, '"}'
            ));
            if (i < tokenTraitIndices.length - 1) {
                json = string(abi.encodePacked(json, ','));
            }
        }

        json = string(abi.encodePacked(json, '] }'));

        // Encode as Base64 data URI
        bytes memory jsonBytes = bytes(json);
        string memory base64Json = Base64.encode(jsonBytes);
        return string(abi.encodePacked("data:application/json;base64,", base64Json)); // Corrected base64
    }

    // Add fallback/receive to accept Ether for minting/burns
    receive() external payable {
        // Optional: allow direct ETH sends to potentially trigger mint or revert
        // For this contract, explicit function calls (`mint`, `burnAndReplaceTrait`) are required.
        revert("Direct ETH transfer not supported, use mint() or burnAndReplaceTrait()");
    }

    fallback() external payable {
         // Same as receive
         revert("Call a function or use mint()/burnAndReplaceTrait()");
    }

    // Add ERC721Enumerable function to get total supply explicitly
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }
}
```