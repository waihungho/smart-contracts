Okay, here is a Solidity smart contract implementing a "Generative Art NFT" with dynamic traits, interaction mechanics, and predictive querying, aiming for complexity and a good number of functions without directly duplicating standard OpenZeppelin implementations beyond the necessary interface inheritance and basic patterns like Ownable.

This contract focuses on:
1.  **On-Chain Trait Generation:** Traits are derived from the token's ID, a contract-wide seed, and its interaction history.
2.  **Dynamic Traits:** Traits can change based on owner interactions with the NFT.
3.  **Interaction Mechanics:** Owners can "interact" with their NFT, potentially influencing its traits and consuming a resource or requiring a cooldown.
4.  **Predictive Functionality:** A novel function to simulate how a token's traits *might* look after a certain number of interactions.
5.  **Generational Evolution:** The contract owner can initiate a "new generation," potentially shifting trait rules or increasing a global dynamic factor.
6.  **Basic Minting & Royalty (ERC2981):** Standard practices included for completeness.

**Outline and Function Summary**

*   **Contract:** `GenerativeArtNFT`
*   **Inherits:** ERC721Enumerable, ERC2981, Ownable (using interfaces/patterns but providing unique implementations)
*   **Purpose:** To issue and manage unique NFTs whose visual traits are determined by contract state and owner interaction.

**Key Concepts:**
*   `TraitSeed`: A base seed derived from the token ID and contract generation parameters, determining static traits.
*   `DynamicFactor`: A contract-wide parameter influencing how much interactions affect dynamic traits.
*   `InteractionCount`: The number of times an owner has "interacted" with a specific token.
*   `LastInteractionTime`: Timestamp of the last interaction for a token, potentially used for cooldowns or time-based effects.
*   `CurrentGeneration`: A contract state counter influencing trait generation rules.

**Function Summary (>= 20 functions):**

1.  `constructor`: Initializes contract with name, symbol, initial price, supply, seed, and owner.
2.  `supportsInterface`: Standard ERC165 override for ERC721, ERC2981.
3.  `tokenURI`: Overrides ERC721. Generates a data URI for metadata, including both base and dynamic traits. **(Core generative function)**
4.  `royaltyInfo`: Overrides ERC2981. Returns royalty details for marketplace support.
5.  `_calculateTraitSeed`: Internal helper. Derives a unique seed for a token based on token ID, generation, and global seed.
6.  `_calculateBaseTraits`: Internal helper. Calculates base traits based on the token's trait seed. (Simulated logic)
7.  `_calculateDynamicTraits`: Internal helper. Calculates dynamic traits based on the token's interaction count, last interaction time, and dynamic factor. (Simulated logic)
8.  `getBaseTraits`: External view function to query a token's calculated base traits.
9.  `getDynamicTraits`: External view function to query a token's calculated dynamic traits.
10. `getFullTraits`: External view function to query a token's combined base and dynamic traits.
11. `getTraitParameter`: External view function to query a specific contract-wide trait generation parameter by index. (Owner configurable)
12. `getDynamicFactor`: External view function to query the current contract-wide dynamic factor.
13. `getCurrentGeneration`: External view function to query the current contract generation number.
14. `getTokenInteractionCount`: External view function to query how many times a specific token has been interacted with.
15. `getTokenLastInteractionTime`: External view function to query the timestamp of the last interaction for a specific token.
16. `predictFutureTraits`: **(Advanced/Creative)** External view function. Simulates `getDynamicTraits` by hypothetically increasing the interaction count and/or advancing time, without changing state. Allows owners/users to preview potential trait changes.
17. `interactWithToken`: **(Dynamic/Trendy)** External function. Allows the token owner to interact. Increments interaction count, updates last interaction time. Can include cost or cooldown logic. This triggers potential dynamic trait changes upon subsequent `tokenURI` calls.
18. `mint`: External payable function for public minting. Handles price, supply, and per-wallet limits.
19. `ownerMint`: Owner-only function to mint tokens (e.g., for team or airdrops) without payment.
20. `setMintPrice`: Owner-only function to update the public mint price.
21. `setMaxSupply`: Owner-only function to update the maximum token supply.
22. `setMaxMintPerWallet`: Owner-only function to update the limit per wallet for public minting.
23. `setTraitParameter`: Owner-only function to configure parameters used in trait generation logic.
24. `setDynamicFactor`: Owner-only function to set the contract-wide parameter influencing dynamic traits.
25. `setBaseURI`: Owner-only function to update the base URI (if using an external metadata server).
26. `setRoyaltyInfo`: Owner-only function to update the royalty recipient and fee percentage.
27. `startNewGeneration`: Owner-only function. Increments the generation counter, potentially resetting or adjusting parameters, influencing future trait generation.
28. `withdraw`: Owner-only function to withdraw collected ETH.
29. `burnToken`: Allows token owner to burn (destroy) their token. (Included for utility/potential scarcity mechanics)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Although we use data URI, URIStorage is useful for baseURI pattern
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For data URI
import "@openzeppelin/contracts/finance/PaymentSplitter.sol"; // Could be used for complex royalties, simpler ERC2981 used here.
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Using minimal interfaces/patterns, not full OpenZeppelin implementations
// where custom logic is needed (like ERC721URIStorage for tokenURI)

/**
 * @title GenerativeArtNFT
 * @dev A smart contract for dynamic generative art NFTs.
 * Traits are derived on-chain based on token state, generation, and owner interactions.
 */
contract GenerativeArtNFT is ERC721, ERC721Enumerable, IERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- State Variables ---

    // Minting Configuration
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxMintPerWallet;
    mapping(address => uint256) private _mintedCount;

    // Generative & Dynamic Art Parameters
    uint256 public generationSeed; // Global seed influencing trait generation
    uint256 public currentGeneration; // Tracks contract-wide generation
    uint256 public dynamicFactor; // Influences the impact of dynamic changes (e.g., interaction effects)

    // Simulating on-chain trait parameters (replace with more complex logic in a real project)
    // These could map to probabilities, ranges, specific trait values, etc.
    uint256[] public traitParameters;
    uint256 constant private MAX_TRAIT_PARAMS = 10; // Cap the array size for gas predictability

    // Token-specific Dynamic State
    mapping(uint256 => uint256) private _tokenInteractionCount; // How many times this token was interacted with
    mapping(uint256 => uint256) private _tokenLastInteractionTime; // Timestamp of last interaction
    uint256 public interactionCooldown; // Cooldown period for interactions (e.g., 1 day)
    uint256 public interactionCost; // Optional cost per interaction

    // Royalty Configuration (ERC2981)
    address public royaltyRecipient;
    uint96 public royaltyFeeBasisPoints; // Example: 500 = 5%

    // Metadata
    string private _baseTokenURI; // Base URI if metadata is hosted off-chain (can be empty if using data URI fully)

    // --- Events ---

    event Minted(address indexed owner, uint256 indexed tokenId, uint256 price);
    event TraitParametersUpdated(uint256[] newParams);
    event DynamicFactorUpdated(uint256 newFactor);
    event NewGenerationStarted(uint256 newGeneration, uint256 newSeed);
    event TokenInteracted(uint256 indexed tokenId, address indexed owner, uint256 interactionCount, uint256 timestamp);
    event RoyaltyInfoUpdated(address indexed recipient, uint96 feeBasisPoints);
    event TokenBurned(uint256 indexed tokenId);


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMintPrice,
        uint256 initialMaxSupply,
        uint256 initialMaxMintPerWallet,
        uint256 initialGenerationSeed,
        uint256 initialDynamicFactor,
        address initialRoyaltyRecipient,
        uint96 initialRoyaltyFeeBasisPoints,
        uint256 initialInteractionCooldown,
        uint256 initialInteractionCost
    ) ERC721(name, symbol) Ownable(msg.sender) {
        mintPrice = initialMintPrice;
        maxSupply = initialMaxSupply;
        maxMintPerWallet = initialMaxMintPerWallet;
        generationSeed = initialGenerationSeed;
        currentGeneration = 1; // Start with generation 1
        dynamicFactor = initialDynamicFactor;
        interactionCooldown = initialInteractionCooldown;
        interactionCost = initialInteractionCost;

        // Initialize placeholder trait parameters (example)
        traitParameters = new uint256[](MAX_TRAIT_PARAMS);
        for(uint i = 0; i < MAX_TRAIT_PARAMS; i++) {
            traitParameters[i] = 100; // Default value
        }

        royaltyRecipient = initialRoyaltyRecipient;
        royaltyFeeBasisPoints = initialRoyaltyFeeBasisPoints;
    }

    // --- ERC165 / ERC721 / ERC2981 Overrides ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC2981).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Generates a data URI for the token's metadata based on its calculated traits.
     * Metadata includes trait types and values derived from contract state and token history.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721URIStorage__NonexistentToken(tokenId); // Use OpenZeppelin error format
        }

        // Calculate traits dynamically
        uint256 baseTraitsHash = _calculateBaseTraits(tokenId);
        uint256 dynamicTraitsHash = _calculateDynamicTraits(tokenId);

        // Simulate mapping hash to meaningful trait values (replace with actual logic)
        // In a real implementation, this would map hash bits/bytes to different categories (background, body, eyes, etc.)
        // and then to specific values within those categories (blue background, red body, etc.).
        // For this example, we'll just represent them as simple numbers derived from the hash.
        string memory baseTrait1 = string(abi.encodePacked("BaseTraitA: ", uint256(baseTraitsHash % 100).toString()));
        string memory baseTrait2 = string(abi.encodePacked("BaseTraitB: ", uint256((baseTraitsHash / 100) % 100).toString()));
        string memory dynamicTrait1 = string(abi.encodePacked("DynamicTraitX: ", uint256(dynamicTraitsHash % 50).toString()));
        string memory dynamicTrait2 = string(abi.encodePacked("DynamicTraitY: ", string(abi.encodePacked("Level ", uint256(_tokenInteractionCount[tokenId] / 10).toString()))));

        // Construct JSON metadata
        // The actual generative *image* would be linked here (e.g., SVG data URI)
        // For simplicity, this example JSON just describes the traits.
        // A real implementation would generate SVG data URI or link to a service that does.
        string memory json = string(abi.encodePacked(
            '{',
                '"name": "Generative Art NFT #', uint256(tokenId).toString(), '",',
                '"description": "A dynamic generative art piece.",',
                '"image": "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgZmlsbD0icmdiYS(',
                    uint256(baseTraitsHash % 256).toString(), ',',
                    uint256((baseTraitsHash / 256) % 256).toString(), ',',
                    uint256(((baseTraitsHash / 256) / 256) % 256).toString(), ',',
                    uint256(100 + (dynamicTraitsHash % 156)).toString(), ')"></cmVjdD48dGV4dCB4PSI1MCIgeT0iMTEwIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZm9udC1zaXplPSIxNHB4IiBmaWxsPSJ3aGl0ZSIgdGV4dC1hbmNob3I9Im1pZGRsZSI+R2VuOiAj', uint256(currentGeneration).toString(), ' I Count: ', uint256(_tokenInteractionCount[tokenId]).toString(), '</dGV4dD48L3N2Zz4=', // Simple SVG example
                '",',
                '"attributes": [',
                    '{', '"trait_type": "Generation", "value": ', uint256(currentGeneration).toString(), ' }', ',',
                    '{', '"trait_type": "Interaction Count", "value": ', uint256(_tokenInteractionCount[tokenId]).toString(), ' }', ',',
                    '{', '"trait_type": "Last Interaction", "value": ', uint256(_tokenLastInteractionTime[tokenId]).toString(), ' }', ',',
                    '{', '"trait_type": "Dynamic Factor Applied", "value": ', uint256(dynamicFactor).toString(), ' }', ',',
                    '{', '"trait_type": "Base Traits Hash", "value": "', uint256(baseTraitsHash).toHexString(), '" }', ',',
                    '{', '"trait_type": "Dynamic Traits Hash", "value": "', uint256(dynamicTraitsHash).toHexString(), '" }', ',',
                    '{', '"trait_type": "Calculated Base Trait A", "value": ', uint256(baseTraitsHash % 100).toString(), ' }', ',',
                    '{', '"trait_type": "Calculated Base Trait B", "value": ', uint256((baseTraitsHash / 100) % 100).toString(), ' }', ',',
                     '{', '"trait_type": "Calculated Dynamic Trait X", "value": ', uint256(dynamicTraitsHash % 50).toString(), ' }',
                     // Add more traits derived from the hashes or state variables
                ']',
            '}'
        ));

        // Encode JSON to Base64 to create a data URI
        string memory jsonBase64 = Base64.encode(bytes(json));
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        public view override returns (address receiver, uint256 royaltyAmount)
    {
        // Ensure basis points don't exceed 10000 (100%)
        uint96 fee = royaltyFeeBasisPoints > 10000 ? 10000 : royaltyFeeBasisPoints;
        royaltyAmount = (salePrice * fee) / 10000;
        receiver = royaltyRecipient;
    }

    // --- Internal Trait Calculation Helpers ---

    /**
     * @dev Derives a unique seed for a token based on token ID, contract generation, and global seed.
     * This ensures trait calculation is deterministic for a given token state.
     * @param tokenId The ID of the token.
     * @return A unique seed for trait calculations.
     */
    function _calculateTraitSeed(uint256 tokenId) internal view returns (uint256) {
        // Using keccak256 for pseudo-randomness based on fixed inputs.
        // This is deterministic and reproducible. Not cryptographically secure randomness.
        return uint256(keccak256(abi.encodePacked(tokenId, generationSeed, currentGeneration)));
    }

    /**
     * @dev Calculates base traits for a token. These are primarily influenced by the initial seed
     * and generation, less by dynamic interactions.
     * @param tokenId The ID of the token.
     * @return A hash representing the base traits.
     */
    function _calculateBaseTraits(uint256 tokenId) internal view returns (uint256) {
        uint256 seed = _calculateTraitSeed(tokenId);
        // Simulate trait calculation based on seed and contract parameters
        // Replace with complex logic involving traitParameters and seed mapping
        uint256 baseHash = uint256(keccak256(abi.encodePacked(seed, traitParameters[0], traitParameters[1])));
        return baseHash;
    }

    /**
     * @dev Calculates dynamic traits for a token. These are influenced by token state
     * that changes over time or via interactions.
     * @param tokenId The ID of the token.
     * @return A hash representing the dynamic traits.
     */
    function _calculateDynamicTraits(uint256 tokenId) internal view returns (uint256) {
        uint256 interactionCount = _tokenInteractionCount[tokenId];
        uint256 lastInteraction = _tokenLastInteractionTime[tokenId];
        uint256 seed = _calculateTraitSeed(tokenId); // Dynamic traits can still be influenced by the base seed

        // Simulate trait calculation based on dynamic state and dynamic factor
        // Replace with complex logic involving interactionCount, lastInteraction, dynamicFactor, etc.
        uint256 dynamicHash = uint256(keccak256(abi.encodePacked(
            seed,
            interactionCount,
            lastInteraction,
            dynamicFactor,
            block.timestamp // Include current time for potentially time-decaying effects
        )));
        return dynamicHash;
    }

    // --- External Trait Query Functions ---

    /**
     * @dev Queries the base traits of a specific token.
     * @param tokenId The ID of the token.
     * @return A hash representing the calculated base traits.
     */
    function getBaseTraits(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert ERC721URIStorage__NonexistentToken(tokenId);
         return _calculateBaseTraits(tokenId);
    }

    /**
     * @dev Queries the dynamic traits of a specific token based on its current state.
     * @param tokenId The ID of the token.
     * @return A hash representing the calculated dynamic traits.
     */
    function getDynamicTraits(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert ERC721URIStorage__NonexistentToken(tokenId);
        return _calculateDynamicTraits(tokenId);
    }

    /**
     * @dev Queries the combined traits of a specific token.
     * Note: The actual metadata generation in tokenURI uses these calculations.
     * @param tokenId The ID of the token.
     * @return baseTraitsHash The hash representing the base traits.
     * @return dynamicTraitsHash The hash representing the dynamic traits.
     */
    function getFullTraits(uint256 tokenId) public view returns (uint256 baseTraitsHash, uint256 dynamicTraitsHash) {
         if (!_exists(tokenId)) revert ERC721URIStorage__NonexistentToken(tokenId);
         return (_calculateBaseTraits(tokenId), _calculateDynamicTraits(tokenId));
    }

    /**
     * @dev Queries a specific contract-wide trait generation parameter by index.
     * These parameters are used within the _calculateBaseTraits logic.
     * @param index The index of the trait parameter array.
     * @return The value of the trait parameter at the given index.
     */
    function getTraitParameter(uint256 index) public view returns (uint256) {
        require(index < traitParameters.length, "Invalid parameter index");
        return traitParameters[index];
    }

    /**
     * @dev Queries the current contract-wide dynamic factor.
     * This factor influences how dynamic traits change.
     */
    function getDynamicFactor() public view returns (uint256) {
        return dynamicFactor;
    }

    /**
     * @dev Queries the current contract generation number.
     * This influences base trait calculation.
     */
     function getCurrentGeneration() public view returns (uint256) {
         return currentGeneration;
     }

    /**
     * @dev Queries the number of times a specific token has been interacted with.
     * @param tokenId The ID of the token.
     */
    function getTokenInteractionCount(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) return 0; // Return 0 for non-existent tokens
         return _tokenInteractionCount[tokenId];
    }

    /**
     * @dev Queries the timestamp of the last interaction for a specific token.
     * @param tokenId The ID of the token.
     */
     function getTokenLastInteractionTime(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) return 0; // Return 0 for non-existent tokens
         return _tokenLastInteractionTime[tokenId];
     }

    /**
     * @dev **Advanced/Creative Function:** Predicts potential future dynamic traits
     * by simulating additional interactions without changing the token's state.
     * Allows users to see how interacting might change the art.
     * @param tokenId The ID of the token.
     * @param futureInteractions The number of additional interactions to simulate.
     * @param futureTimeDelta Optional time difference in seconds to simulate passing (e.g., after cooldowns reset).
     * @return A hash representing the predicted future dynamic traits.
     */
    function predictFutureTraits(uint256 tokenId, uint256 futureInteractions, uint256 futureTimeDelta) public view returns (uint256 predictedDynamicTraitsHash) {
        if (!_exists(tokenId)) revert ERC721URIStorage__NonexistentToken(tokenId);

        // Simulate future state for calculation
        uint256 simulatedInteractionCount = _tokenInteractionCount[tokenId] + futureInteractions;
        uint256 simulatedLastInteractionTime = _tokenLastInteractionTime[tokenId] + futureTimeDelta; // Simplified time simulation

        // Recalculate dynamic traits with simulated state
        uint256 seed = _calculateTraitSeed(tokenId);

        // Simulate trait calculation based on simulated dynamic state and dynamic factor
        predictedDynamicTraitsHash = uint256(keccak256(abi.encodePacked(
            seed,
            simulatedInteractionCount,
            simulatedLastInteractionTime,
            dynamicFactor,
            block.timestamp + futureTimeDelta // Use simulated future time for time-based effects
        )));

        return predictedDynamicTraitsHash;
    }


    // --- Dynamic Interaction Function ---

    /**
     * @dev Allows the owner of a token to 'interact' with it.
     * This updates the token's interaction count and last interaction time,
     * potentially changing its dynamic traits the next time metadata is viewed.
     * Can require a cooldown or cost.
     * @param tokenId The ID of the token to interact with.
     */
    function interactWithToken(uint256 tokenId) public payable {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        require(block.timestamp >= _tokenLastInteractionTime[tokenId] + interactionCooldown, "Interaction on cooldown");
        require(msg.value >= interactionCost, "Insufficient funds for interaction");

        // Transfer interaction cost if any
        if (interactionCost > 0) {
             (bool success,) = payable(owner()).call{value: msg.value}("");
             require(success, "ETH transfer failed");
        }

        _tokenInteractionCount[tokenId]++;
        _tokenLastInteractionTime[tokenId] = block.timestamp;

        emit TokenInteracted(tokenId, msg.sender, _tokenInteractionCount[tokenId], block.timestamp);

        // Note: The traits *themselves* are not stored, they are recalculated in tokenURI.
        // The interaction just updates the state variables used in that calculation.
    }

     /**
     * @dev Allows the token owner to burn (destroy) their token.
     * This permanently removes the token from existence.
     * @param tokenId The ID of the token to burn.
     */
     function burnToken(uint256 tokenId) public {
         require(_exists(tokenId), "Token does not exist");
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");

         _burn(tokenId); // ERC721 standard burn

         // Clear token-specific state (optional, but good practice)
         delete _tokenInteractionCount[tokenId];
         delete _tokenLastInteractionTime[tokenId];

         emit TokenBurned(tokenId);
     }


    // --- Minting Functions ---

    /**
     * @dev Mints a new token to the caller.
     * Enforces mint price, max supply, and per-wallet limits.
     */
    function mint() public payable {
        uint256 nextTokenId = _tokenIds.current();
        require(nextTokenId < maxSupply, "Max supply reached");
        require(_mintedCount[msg.sender] < maxMintPerWallet, "Max mint per wallet reached");
        require(msg.value >= mintPrice, "Insufficient funds");

        _tokenIds.increment();
        _safeMint(msg.sender, nextTokenId);
        _mintedCount[msg.sender]++;

        emit Minted(msg.sender, nextTokenId, mintPrice);
    }

     /**
     * @dev Owner-only function to mint tokens, e.g., for team or airdrops.
     * Skips payment and per-wallet limits.
     * @param to The address to mint the token to.
     */
    function ownerMint(address to) public onlyOwner {
        uint256 nextTokenId = _tokenIds.current();
        require(nextTokenId < maxSupply, "Max supply reached");

        _tokenIds.increment();
        _safeMint(to, nextTokenId);
        // Note: ownerMint does NOT increment _mintedCount for maxMintPerWallet

        emit Minted(to, nextTokenId, 0); // Price is 0 for owner mint
    }


    // --- Owner Configuration Functions ---

    /**
     * @dev Owner-only function to set the public mint price.
     * @param newPrice The new mint price in wei.
     */
    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }

    /**
     * @dev Owner-only function to set the maximum token supply.
     * Must be greater than or equal to the current supply.
     * @param newMaxSupply The new maximum supply.
     */
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= _tokenIds.current(), "New max supply must be >= current supply");
        maxSupply = newMaxSupply;
    }

    /**
     * @dev Owner-only function to set the maximum number of tokens a single wallet
     * can mint during the public mint phase.
     * @param newMaxMintPerWallet The new maximum per wallet.
     */
    function setMaxMintPerWallet(uint256 newMaxMintPerWallet) public onlyOwner {
        maxMintPerWallet = newMaxMintPerWallet;
    }

     /**
     * @dev Owner-only function to set a specific trait generation parameter by index.
     * This allows the owner to influence how traits are calculated based on the seed.
     * @param index The index of the parameter (must be within bounds).
     * @param value The new value for the parameter.
     */
    function setTraitParameter(uint256 index, uint256 value) public onlyOwner {
        require(index < traitParameters.length, "Invalid parameter index");
        traitParameters[index] = value;
        emit TraitParametersUpdated(traitParameters);
    }

    /**
     * @dev Owner-only function to set the contract-wide dynamic factor.
     * This influences how interactions affect traits.
     * @param newFactor The new dynamic factor.
     */
    function setDynamicFactor(uint256 newFactor) public onlyOwner {
        dynamicFactor = newFactor;
        emit DynamicFactorUpdated(newFactor);
    }

    /**
     * @dev Owner-only function to set the base URI for token metadata.
     * Only needed if metadata isn't entirely on-chain via data URI.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @dev Owner-only function to update the royalty information.
     * @param recipient The new recipient address for royalties.
     * @param feeBasisPoints The new royalty fee percentage in basis points (e.g., 500 for 5%).
     */
    function setRoyaltyInfo(address recipient, uint96 feeBasisPoints) public onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        royaltyRecipient = recipient;
        royaltyFeeBasisPoints = feeBasisPoints;
        emit RoyaltyInfoUpdated(recipient, feeBasisPoints);
    }

    /**
     * @dev **Advanced/Creative Function:** Owner-only function to start a new generation.
     * This increments the contract's generation counter and allows setting a new global seed.
     * This change can significantly influence trait calculations for *all* tokens (base traits for new mints, potentially dynamic traits for existing).
     * @param newSeed The new seed for the next generation.
     */
    function startNewGeneration(uint256 newSeed) public onlyOwner {
        currentGeneration++;
        generationSeed = newSeed;
        // Could add logic here to reset/adjust traitParameters or dynamicFactor for the new generation
        emit NewGenerationStarted(currentGeneration, generationSeed);
    }


    /**
     * @dev Owner-only function to withdraw collected Ether from the contract.
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // --- Query Functions (Standard ERC721 & Custom) ---

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

     /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721Enumerable, IERC721Enumerable) returns (uint256) {
         return super.tokenOfOwnerByIndex(owner, index);
    }


    /**
     * @dev Returns the base URI for the contract.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the current public mint price.
     */
    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    /**
     * @dev Returns the maximum supply.
     */
    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    /**
     * @dev Returns the maximum tokens allowed per wallet during public mint.
     */
    function getMaxMintPerWallet() public view returns (uint256) {
        return maxMintPerWallet;
    }

    /**
     * @dev Returns the number of tokens already minted by a specific address.
     * Useful for checking against maxMintPerWallet.
     * @param wallet The address to check.
     */
    function getMintedCount(address wallet) public view returns (uint256) {
        return _mintedCount[wallet];
    }

    /**
     * @dev Returns the current interaction cooldown period.
     */
     function getInteractionCooldown() public view returns (uint256) {
         return interactionCooldown;
     }

    /**
     * @dev Returns the cost per interaction.
     */
     function getInteractionCost() public view returns (uint256) {
         return interactionCost;
     }

    // --- Internal ERC721 Helper Overrides ---
    // These are necessary because we override ERC721 methods like _safeMint

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _increaseBalance(address account, uint128 amount)
        internal override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

     function _update(address to, uint256 tokenId, address auth)
        internal override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}
```