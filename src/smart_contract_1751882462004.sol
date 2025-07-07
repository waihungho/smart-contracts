Okay, let's create an advanced smart contract concept. How about a "Generative Art NFT with On-Chain Traits, Dynamic Evolution, and Token-Specific Energy"?

This contract will mint NFTs whose visual properties (traits) are determined *on-chain* based on deterministic factors (like token ID, minter address, block data). These NFTs can *evolve* or *mutate* over time, changing their on-chain traits, potentially consuming a resource like "Energy" which is also stored on-chain per token and can be added by interacting with the contract.

It combines:
1.  **ERC721 Standard:** For core NFT functionality.
2.  **On-Chain Data:** Traits and energy are stored directly in the contract state.
3.  **Deterministic Generation:** Traits are generated algorithmically.
4.  **Dynamic NFTs:** Traits can change via evolution.
5.  **Resource Management:** Token-specific "Energy" resource.
6.  **Advanced Concepts:** Implementing custom trait generation, evolution mechanics, and resource handling within the contract.

---

**Smart Contract: GenerativeArtNFT**

**Outline:**

1.  ** SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, ReentrancyGuard, Counters (from OpenZeppelin)
3.  **Error Definitions**
4.  **Structs & Enums:**
    *   `TraitType` (Enum): Defines categories of traits (e.g., Background, Body, Head, Accessory).
    *   `Trait` (Struct): Represents a single trait with `traitType` and `value` (uint8 for value index).
    *   `TokenData` (Struct): Holds all dynamic data for a token: `Trait[] traits`, `uint256 energy`.
5.  **State Variables:**
    *   `_tokenIds` (Counters.Counter): Tracks total minted supply.
    *   `_tokenData` (mapping): Maps `tokenId` to `TokenData`.
    *   `_baseTokenURI` (string): Base URI for metadata (points to off-chain renderer).
    *   `MAX_SUPPLY` (uint256): Maximum number of tokens that can be minted.
    *   `_mintPrice` (uint256): Price for public minting.
    *   `_evolutionCost` (uint256): Energy cost per trait evolution.
    *   `_rollCostEther` (uint256): Ether cost for rolling all traits.
    *   `_addEnergyPrice` (uint256): Ether cost to add 1 unit of energy to a token.
    *   `_traitTypeCount` (uint8): Number of different trait categories.
    *   `_traitValues` (mapping): Maps `TraitType` enum to an array of possible value indices (uint8). This is a simplification; real implementation might need more complex mapping or external data.
    *   `_generationSeed` (uint256): A seed used for deterministic generation.
6.  **Events:**
    *   `TokenMinted(uint256 tokenId, address owner, Trait[] traits, uint256 initialEnergy)`
    *   `TraitsEvolved(uint256 tokenId, Trait[] oldTraits, Trait[] newTraits, uint256 energyConsumed)`
    *   `TraitsRolled(uint256 tokenId, Trait[] oldTraits, Trait[] newTraits, uint256 etherConsumed)`
    *   `EnergyAdded(uint256 tokenId, uint256 amount, uint256 etherPaid)`
    *   `BaseURISet(string oldURI, string newURI)`
    *   `MaxSupplySet(uint256 oldMaxSupply, uint256 newMaxSupply)`
    *   `MintPriceSet(uint256 oldPrice, uint256 newPrice)`
    *   `EvolutionCostSet(uint256 oldCost, uint256 newCost)`
    *   `RollCostEtherSet(uint256 oldCost, uint256 newCost)`
    *   `AddEnergyPriceSet(uint256 oldPrice, uint256 newPrice)`
    *   `GenerationSeedSet(uint256 oldSeed, uint256 newSeed)`
    *   `Withdraw(address recipient, uint256 amount)`
7.  **Modifiers:**
    *   `tokenExists(uint256 tokenId)`
    *   `onlyTokenOwner(uint256 tokenId)`
    *   `hasRequiredEnergy(uint256 tokenId, uint256 amount)`
8.  **Constructor:** Initializes base URI, max supply, mint price, costs, trait definitions (simplified), and initial seed.
9.  **Internal Helper Functions:**
    *   `_generateInitialTraits(uint256 tokenId, address minter, uint256 seed)`: Deterministically generates initial traits based on inputs.
    *   `_getRandomValue(uint256 seed, uint8 max)`: Deterministic pseudo-random value from seed (simplified).
    *   `_consumeEnergy(uint256 tokenId, uint256 amount)`: Decreases token energy.
    *   `_addEnergy(uint256 tokenId, uint256 amount)`: Increases token energy.
    *   `_performEvolution(uint256 tokenId, uint8 traitIndex)`: Evolves a single trait based on rules.
    *   `_rollRandomTraits(uint256 tokenId, address roller, uint256 seed)`: Generates a completely new set of traits.
10. **ERC721 Standard Overrides:**
    *   `tokenURI(uint256 tokenId)`: Overrides to return the base URI + tokenId.
    *   `supportsInterface(bytes4 interfaceId)`: Standard override.
11. **Minting Functions:**
    *   `publicMint()`: Mints a token to the caller, pays `_mintPrice`.
    *   `adminMint(address recipient)`: Mints a token to a recipient (Owner only).
    *   `totalSupply()`: Returns current token count.
    *   `maxSupply()`: Returns maximum allowed token count.
12. **Trait & Evolution Functions:**
    *   `getTraits(uint256 tokenId)`: Returns the current traits for a token.
    *   `getTraitValueName(uint8 traitType, uint8 traitValue)`: Helper to get a readable name (simplified; real impl needs mapping).
    *   `evolveTrait(uint256 tokenId, uint8 traitIndex)`: Evolves a specific trait, consuming energy.
    *   `rollTraits(uint256 tokenId)`: Rerolls all traits for a token, costs Ether.
13. **Energy Functions:**
    *   `getEnergy(uint256 tokenId)`: Returns current energy for a token.
    *   `addEnergyToToken(uint256 tokenId)`: Adds energy to a token, receives Ether based on `_addEnergyPrice`.
    *   `getAddEnergyPrice()`: Returns the current price to add energy.
14. **Querying & Data Functions:**
    *   `getTokenDetails(uint256 tokenId)`: Returns a struct/tuple with owner, traits, and energy.
    *   `exists(uint256 tokenId)`: Checks if a token exists.
15. **Admin Functions (Owner Only):**
    *   `pause()`: Pauses minting and certain interactions.
    *   `unpause()`: Unpauses.
    *   `setBaseURI(string memory newBaseURI)`: Sets the base URI.
    *   `setMaxSupply(uint256 newMaxSupply)`: Sets the max supply.
    *   `setMintPrice(uint256 newMintPrice)`: Sets the public mint price.
    *   `setEvolutionCost(uint256 newCost)`: Sets the energy cost for trait evolution.
    *   `setRollCostEther(uint256 newCost)`: Sets the Ether cost for rolling traits.
    *   `setAddEnergyPrice(uint256 newPrice)`: Sets the Ether price to add energy.
    *   `setGenerationSeed(uint256 newSeed)`: Updates the generation seed (caution needed).
    *   `withdrawFunds()`: Withdraws contract balance to owner.

---

**Function Summary (Minimum 20):**

1.  `constructor()`: Initializes contract.
2.  `supportsInterface(bytes4 interfaceId)`: ERC721 standard.
3.  `tokenURI(uint256 tokenId)`: Returns metadata URI.
4.  `balanceOf(address owner)`: ERC721 standard.
5.  `ownerOf(uint256 tokenId)`: ERC721 standard.
6.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
7.  `approve(address to, uint256 tokenId)`: ERC721 standard.
8.  `getApproved(uint256 tokenId)`: ERC721 standard.
9.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
10. `isApprovedForAll(address owner, address operator)`: ERC721 standard.
11. `publicMint()`: Mints token for caller (paid).
12. `adminMint(address recipient)`: Mints token for recipient (admin).
13. `totalSupply()`: Returns total tokens minted.
14. `maxSupply()`: Returns max token supply.
15. `getTraits(uint256 tokenId)`: Gets current on-chain traits.
16. `getTraitValueName(uint8 traitType, uint8 traitValue)`: Gets readable trait value name (simplified).
17. `evolveTrait(uint256 tokenId, uint8 traitIndex)`: Evolves a specific trait (consumes energy).
18. `rollTraits(uint256 tokenId)`: Rerolls all traits (consumes Ether).
19. `getEnergy(uint256 tokenId)`: Gets current energy for a token.
20. `addEnergyToToken(uint256 tokenId)`: Adds energy to a token (pays Ether).
21. `getAddEnergyPrice()`: Gets price to add energy.
22. `getTokenDetails(uint256 tokenId)`: Gets comprehensive token data.
23. `exists(uint256 tokenId)`: Checks if token exists.
24. `pause()`: Pauses contract actions.
25. `unpause()`: Unpauses contract actions.
26. `setBaseURI(string memory newBaseURI)`: Sets metadata base URI (Admin).
27. `setMaxSupply(uint256 newMaxSupply)`: Sets max supply (Admin).
28. `setMintPrice(uint256 newMintPrice)`: Sets public mint price (Admin).
29. `setEvolutionCost(uint256 newCost)`: Sets evolution energy cost (Admin).
30. `setRollCostEther(uint256 newCost)`: Sets roll Ether cost (Admin).
31. `setAddEnergyPrice(uint256 newPrice)`: Sets add energy Ether price (Admin).
32. `setGenerationSeed(uint256 newSeed)`: Sets generation seed (Admin - Use with caution).
33. `withdrawFunds()`: Withdraws contract balance (Admin).
34. `transferOwnership(address newOwner)`: Transfers contract ownership (Admin).
35. `renounceOwnership()`: Renounces contract ownership (Admin).

*Total functions: 35 (well over 20).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ----------------------------------------------------------------------------
// Smart Contract: GenerativeArtNFT
// Concept: ERC721 NFT with on-chain deterministic traits, dynamic evolution,
// and token-specific energy.
//
// Features:
// - Standard ERC721 functionality.
// - Traits stored on-chain, generated deterministically at mint.
// - Token-specific energy resource stored on-chain.
// - Traits can be evolved (consume energy) or rerolled (pay ether).
// - Energy can be added to tokens (pay ether).
// - Pausable minting and actions.
// - Owner controls key parameters (prices, max supply, base URI).
// - Metadata URI points to an off-chain service that reads on-chain traits.
//
// This contract demonstrates dynamic NFT properties and on-chain data management
// beyond typical static NFT implementations.
//
// Outline:
// 1. SPDX-License-Identifier & Pragma
// 2. Imports (OpenZeppelin Libraries)
// 3. Error Definitions (Custom Errors)
// 4. Structs & Enums (TraitType, Trait, TokenData)
// 5. State Variables (_tokenIds, _tokenData, _baseTokenURI, MAX_SUPPLY, prices/costs, etc.)
// 6. Events (Minting, Evolution, Energy, Admin actions)
// 7. Modifiers (tokenExists, onlyTokenOwner, hasRequiredEnergy)
// 8. Constructor
// 9. Internal Helper Functions (_generateInitialTraits, _getRandomValue, _consumeEnergy, etc.)
// 10. ERC721 Standard Overrides (tokenURI, supportsInterface)
// 11. Minting Functions (publicMint, adminMint, totalSupply, maxSupply)
// 12. Trait & Evolution Functions (getTraits, evolveTrait, rollTraits)
// 13. Energy Functions (getEnergy, addEnergyToToken, getAddEnergyPrice)
// 14. Querying & Data Functions (getTokenDetails, exists)
// 15. Admin Functions (pause, unpause, set parameters, withdrawFunds)
//
// Function Summary (35 Functions):
// - constructor()
// - supportsInterface()
// - tokenURI()
// - balanceOf()
// - ownerOf()
// - transferFrom()
// - approve()
// - getApproved()
// - setApprovalForAll()
// - isApprovedForAll()
// - publicMint()
// - adminMint()
// - totalSupply()
// - maxSupply()
// - getTraits()
// - getTraitValueName() - Simplified getter for trait names
// - evolveTrait()
// - rollTraits()
// - getEnergy()
// - addEnergyToToken()
// - getAddEnergyPrice()
// - getTokenDetails() - Retrieves multiple token properties
// - exists()
// - pause()
// - unpause()
// - setBaseURI()
// - setMaxSupply()
// - setMintPrice()
// - setEvolutionCost()
// - setRollCostEther()
// - setAddEnergyPrice()
// - setGenerationSeed()
// - withdrawFunds()
// - transferOwnership()
// - renounceOwnership()
// ----------------------------------------------------------------------------

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GenerativeArtNFT is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Error Definitions ---
    error MaxSupplyReached();
    error NotEnoughEnergy(uint256 tokenId, uint256 required, uint256 current);
    error InvalidTraitIndex(uint256 tokenId, uint8 index);
    error InvalidTraitValue(uint8 traitType, uint8 value);
    error InsufficientPayment(uint256 required, uint256 sent);
    error TokenDoesNotExist(uint256 tokenId);

    // --- Structs & Enums ---

    enum TraitType {
        Background,
        Body,
        Head,
        Accessory,
        Expression,
        // Add more trait types as needed
        COUNT // Special value to know the number of trait types
    }

    struct Trait {
        TraitType traitType;
        uint8 value; // Use uint8 to represent an index into possible values
    }

    struct TokenData {
        Trait[] traits;
        uint256 energy;
    }

    // --- State Variables ---

    Counters.Counter private _tokenIds;
    mapping(uint256 => TokenData) private _tokenData;

    string private _baseTokenURI;
    uint256 public immutable MAX_SUPPLY; // Set once in constructor

    uint256 private _mintPrice; // Price for public minting
    uint256 private _evolutionCost; // Energy cost per trait evolution
    uint256 private _rollCostEther; // Ether cost for rolling all traits
    uint256 private _addEnergyPrice; // Ether cost to add 1 unit of energy to a token

    // Mapping TraitType to maximum possible value index (simple example)
    // A real implementation would need a more robust way to define trait values and names.
    mapping(TraitType => uint8) private _maxTraitValues;

    // A seed value used for deterministic trait generation
    uint256 private _generationSeed;

    // --- Events ---

    event TokenMinted(uint256 indexed tokenId, address indexed owner, Trait[] traits, uint256 initialEnergy);
    event TraitsEvolved(uint256 indexed tokenId, Trait[] oldTraits, Trait[] newTraits, uint256 energyConsumed);
    event TraitsRolled(uint256 indexed tokenId, Trait[] oldTraits, Trait[] newTraits, uint256 etherConsumed);
    event EnergyAdded(uint256 indexed tokenId, uint256 amount, uint256 etherPaid);
    event BaseURISet(string oldURI, string newURI);
    event MaxSupplySet(uint256 oldMaxSupply, uint256 newMaxSupply);
    event MintPriceSet(uint256 oldPrice, uint256 newPrice);
    event EvolutionCostSet(uint256 oldCost, uint256 newCost);
    event RollCostEtherSet(uint256 oldCost, uint256 newCost);
    event AddEnergyPriceSet(uint256 oldPrice, uint256 newPrice);
    event GenerationSeedSet(uint256 oldSeed, uint256 newSeed);
    event Withdraw(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) {
            revert ERC721Ownership(msg.sender, _ownerOf(tokenId)); // Revert with OZ standard error
        }
        _;
    }

    modifier hasRequiredEnergy(uint256 tokenId, uint256 amount) {
        if (_tokenData[tokenId].energy < amount) {
            revert NotEnoughEnergy(tokenId, amount, _tokenData[tokenId].energy);
        }
        _;
    }

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI,
        uint256 maxSupply_,
        uint256 mintPrice_,
        uint256 evolutionCost_,
        uint256 rollCostEther_,
        uint256 addEnergyPrice_,
        uint256 initialGenerationSeed
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (maxSupply_ == 0) revert("Max supply cannot be zero");
        MAX_SUPPLY = maxSupply_;
        _baseTokenURI = initialBaseURI;
        _mintPrice = mintPrice_;
        _evolutionCost = evolutionCost_;
        _rollCostEther = rollCostEther_;
        _addEnergyPrice = addEnergyPrice_;
        _generationSeed = initialGenerationSeed;

        // Initialize max values for each trait type (Simplified)
        // In a real scenario, this might be more complex or data-driven.
        _maxTraitValues[TraitType.Background] = 5; // e.g., 6 different backgrounds (0-5)
        _maxTraitValues[TraitType.Body] = 10;      // e.g., 11 different bodies (0-10)
        _maxTraitValues[TraitType.Head] = 8;       // e.g., 9 different heads (0-8)
        _maxTraitValues[TraitType.Accessory] = 12; // e.g., 13 different accessories (0-12)
        _maxTraitValues[TraitType.Expression] = 7; // e.g., 8 different expressions (0-7)
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Deterministically generates initial traits for a new token.
     * Pseudo-randomness based on block data, minter, tokenId, and a seed.
     * Note: block.timestamp and blockhash are susceptible to miner manipulation
     * for short time windows. For higher security randomness, Chainlink VRF or
     * similar solutions should be used. This implementation prioritizes on-chain
     * data derivation for the "generative" aspect.
     */
    function _generateInitialTraits(uint256 tokenId, address minter, uint256 seed) internal view returns (Trait[] memory) {
        uint256 currentSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, tokenId, seed)));
        Trait[] memory initialTraits = new Trait[](uint8(TraitType.COUNT));

        for (uint8 i = 0; i < uint8(TraitType.COUNT); i++) {
            TraitType traitType = TraitType(i);
            uint8 maxValue = _maxTraitValues[traitType];
            uint8 generatedValue = _getRandomValue(currentSeed, maxValue);

            initialTraits[i] = Trait({
                traitType: traitType,
                value: generatedValue
            });

            // Update seed for the next trait generation
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, generatedValue)));
        }
        return initialTraits;
    }

    /**
     * @dev Simple deterministic pseudo-random value generator.
     * Should NOT be used for security-critical applications requiring true randomness.
     */
    function _getRandomValue(uint256 seed, uint8 max) internal pure returns (uint8) {
        if (max == 0) return 0; // Avoid division by zero
        // Use seed to derive a value within the range [0, max]
        return uint8((seed % (max + 1)));
    }


    /**
     * @dev Consumes energy from a token. Internal helper.
     */
    function _consumeEnergy(uint256 tokenId, uint256 amount) internal {
        _tokenData[tokenId].energy -= amount;
        // No need for Underflow check due to `hasRequiredEnergy` modifier
    }

    /**
     * @dev Adds energy to a token. Internal helper.
     */
    function _addEnergy(uint256 tokenId, uint256 amount) internal {
        _tokenData[tokenId].energy += amount;
    }

    /**
     * @dev Performs the evolution logic for a single trait.
     * Simplified: just increments the trait value, looping back if needed.
     * More complex logic (e.g., specific upgrades based on current value)
     * could be implemented here.
     */
    function _performEvolution(uint256 tokenId, uint8 traitIndex) internal tokenExists(tokenId) {
        if (traitIndex >= uint8(TraitType.COUNT)) {
            revert InvalidTraitIndex(tokenId, traitIndex);
        }

        Trait storage traitToEvolve = _tokenData[tokenId].traits[traitIndex];
        uint8 maxValue = _maxTraitValues[traitToEvolve.traitType];

        // Simple evolution: increment value, loop back if exceeds max
        traitToEvolve.value = (traitToEvolve.value + 1) % (maxValue + 1);

        // Emit event with updated traits for transparency
        emit TraitsEvolved(tokenId, _tokenData[tokenId].traits, _tokenData[tokenId].traits, _evolutionCost);
    }

    /**
     * @dev Rerolls all traits for a token using a new seed source.
     */
    function _rollRandomTraits(uint256 tokenId, address roller, uint256 seed) internal tokenExists(tokenId) returns (Trait[] memory) {
        uint256 currentSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, block.difficulty, roller, tokenId, seed)));
        Trait[] memory newTraits = new Trait[](uint8(TraitType.COUNT));

        for (uint8 i = 0; i < uint8(TraitType.COUNT); i++) {
            TraitType traitType = TraitType(i);
            uint8 maxValue = _maxTraitValues[traitType];
            uint8 generatedValue = _getRandomValue(currentSeed, maxValue);

            newTraits[i] = Trait({
                traitType: traitType,
                value: generatedValue
            });

             // Update seed for the next trait generation
            currentSeed = uint256(keccak256(abi.encodePacked(currentSeed, generatedValue)));
        }

        // Store the old traits before updating
        Trait[] memory oldTraits = new Trait[](uint8(TraitType.COUNT));
        for(uint8 i = 0; i < uint8(TraitType.COUNT); i++) {
            oldTraits[i] = _tokenData[tokenId].traits[i];
        }

        // Update token data
        _tokenData[tokenId].traits = newTraits; // Assign the new traits array

        emit TraitsRolled(tokenId, oldTraits, newTraits, _rollCostEther);

        return newTraits;
    }


    // --- ERC721 Standard Overrides ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Returns the concatenated base URI and token ID.
     * An off-chain service at the base URI should fetch the token's on-chain
     * traits and energy using `getTraits()` and `getEnergy()` to generate
     * the actual metadata (JSON and image).
     */
    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * Includes ERC721, ERC721Enumerable (if used), ERC721Metadata, Ownable, Pausable.
     * OpenZeppelin handles standard interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // ERC721 core functions are inherited directly from OpenZeppelin

    // --- Minting Functions ---

    /**
     * @dev Mints a new token to the caller. Requires payment of _mintPrice.
     * Traits are generated deterministically based on block data, msg.sender, and token ID.
     * Initial energy is set to 0.
     */
    function publicMint() external payable whenNotPaused nonReentrant {
        uint256 currentTokenId = _tokenIds.current();
        if (currentTokenId >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        if (msg.value < _mintPrice) {
            revert InsufficientPayment(_mintPrice, msg.value);
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Generate initial traits and set initial energy
        Trait[] memory initialTraits = _generateInitialTraits(newTokenId, msg.sender, _generationSeed);
        _tokenData[newTokenId] = TokenData({
            traits: initialTraits,
            energy: 0 // Start with 0 energy
        });

        _safeMint(msg.sender, newTokenId); // Mints and transfers ownership

        emit TokenMinted(newTokenId, msg.sender, initialTraits, 0);

        // Refund excess Ether if any
        if (msg.value > _mintPrice) {
            payable(msg.sender).transfer(msg.value - _mintPrice);
        }
    }

    /**
     * @dev Mints a new token to a specified recipient (Owner only). No cost.
     */
    function adminMint(address recipient) external onlyOwner whenNotPaused {
        uint256 currentTokenId = _tokenIds.current();
        if (currentTokenId >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Generate initial traits and set initial energy
         Trait[] memory initialTraits = _generateInitialTraits(newTokenId, recipient, _generationSeed);
        _tokenData[newTokenId] = TokenData({
            traits: initialTraits,
            energy: 0 // Start with 0 energy
        });

        _safeMint(recipient, newTokenId); // Mints and transfers ownership

        emit TokenMinted(newTokenId, recipient, initialTraits, 0);
    }

    /**
     * @dev Returns the total number of tokens minted.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Returns the maximum number of tokens that can be minted.
     */
    function maxSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }


    // --- Trait & Evolution Functions ---

    /**
     * @dev Returns the current traits for a specific token.
     */
    function getTraits(uint256 tokenId) public view tokenExists(tokenId) returns (Trait[] memory) {
        return _tokenData[tokenId].traits;
    }

    /**
     * @dev Helper function to get a *placeholder* readable name for a trait value.
     * A real implementation would likely need a more complex mapping or off-chain lookup.
     * This is just to show how you might reference trait values.
     */
    function getTraitValueName(uint8 traitType, uint8 traitValue) public pure returns (string memory) {
        // In a real application, you would map traitType and value to a specific string name
        // e.g., return "Red Background" if traitType is Background (0) and value is 1.
        // This example uses placeholder strings.
        if (traitType >= uint8(TraitType.COUNT)) revert InvalidTraitValue(traitType, traitValue);

        string memory typeName = "";
        if (traitType == uint8(TraitType.Background)) typeName = "Background";
        else if (traitType == uint8(TraitType.Body)) typeName = "Body";
        else if (traitType == uint8(TraitType.Head)) typeName = "Head";
        else if (traitType == uint8(TraitType.Accessory)) typeName = "Accessory";
        else if (traitType == uint8(TraitType.Expression)) typeName = "Expression";
        else typeName = "Unknown"; // Should not happen with enum check

        return string(abi.encodePacked(typeName, " Value ", traitValue.toString()));
    }


    /**
     * @dev Evolves a specific trait for the token owner's token.
     * Consumes energy from the token.
     */
    function evolveTrait(uint256 tokenId, uint8 traitIndex) external payable whenNotPaused onlyTokenOwner(tokenId) hasRequiredEnergy(tokenId, _evolutionCost) {
        _consumeEnergy(tokenId, _evolutionCost);
        _performEvolution(tokenId, traitIndex); // This function emits the event
    }

    /**
     * @dev Rerolls ALL traits for the token owner's token.
     * Costs Ether. Uses a new deterministic seed derived from tx data, etc.
     */
    function rollTraits(uint256 tokenId) external payable whenNotPaused onlyTokenOwner(tokenId) nonReentrant {
         if (msg.value < _rollCostEther) {
            revert InsufficientPayment(_rollCostEther, msg.value);
        }

        // Generate new traits
        Trait[] memory newTraits = _rollRandomTraits(tokenId, msg.sender, uint256(keccak256(abi.encodePacked(tx.origin, block.timestamp, block.number)))); // Use different seed sources

        // Refund excess Ether
        if (msg.value > _rollCostEther) {
            payable(msg.sender).transfer(msg.value - _rollCostEther);
        }
        // _rollRandomTraits emits the event
    }

    // --- Energy Functions ---

    /**
     * @dev Returns the current energy level for a specific token.
     */
    function getEnergy(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _tokenData[tokenId].energy;
    }

    /**
     * @dev Adds energy to a specific token. Requires payment of _addEnergyPrice per unit of energy.
     * Anyone can add energy to any token by paying the price.
     */
    function addEnergyToToken(uint256 tokenId) external payable whenNotPaused nonReentrant tokenExists(tokenId) {
         if (_addEnergyPrice == 0) revert("Energy cannot be added if price is zero"); // Prevent griefing if price is 0

         uint256 amountPaid = msg.value;
         uint256 energyToAdd = amountPaid / _addEnergyPrice;

         if (energyToAdd == 0) {
             revert InsufficientPayment(_addEnergyPrice, amountPaid);
         }

         uint256 cost = energyToAdd * _addEnergyPrice;
         if (amountPaid < cost) {
              // Should not happen due to integer division, but belt and suspenders
             revert InsufficientPayment(cost, amountPaid);
         }

        _addEnergy(tokenId, energyToAdd);

        emit EnergyAdded(tokenId, energyToAdd, cost);

        // Refund excess Ether
        if (amountPaid > cost) {
            payable(msg.sender).transfer(amountPaid - cost);
        }
    }

     /**
     * @dev Returns the current price to add 1 unit of energy to a token.
     */
    function getAddEnergyPrice() public view returns (uint256) {
        return _addEnergyPrice;
    }

    // --- Querying & Data Functions ---

    /**
     * @dev Returns a comprehensive set of data for a token.
     * Useful for off-chain applications (like renderers) to fetch all necessary info in one call.
     */
    function getTokenDetails(uint256 tokenId) public view tokenExists(tokenId) returns (address owner, Trait[] memory traits, uint256 energy) {
        owner = _ownerOf(tokenId);
        traits = _tokenData[tokenId].traits; // Returns a memory copy
        energy = _tokenData[tokenId].energy;
    }

    /**
     * @dev Checks if a token with the given ID exists.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Pauses the contract, preventing most state-changing functions.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the base URI for token metadata.
     * Should point to a service that can interpret on-chain traits.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        string memory oldURI = _baseTokenURI;
        _baseTokenURI = newBaseURI;
        emit BaseURISet(oldURI, newBaseURI);
    }

    /**
     * @dev Sets the maximum number of tokens that can be minted.
     * Can only increase the supply, not decrease below current supply.
     * Note: MAX_SUPPLY is immutable in this implementation. This function
     * is just an example if MAX_SUPPLY were a state variable.
     * For this contract, MAX_SUPPLY is set in the constructor and cannot change.
     * Keeping the function signature as per summary but it will revert or needs adjustment.
     *
     * Let's adjust: remove setMaxSupply as MAX_SUPPLY is immutable.
     * We'll need to adjust the function count or add another simple admin function.
     * Okay, let's keep it but add a require that the new supply must be > current.
     * No, the summary explicitly lists 35 functions including setMaxSupply.
     * Let's assume MAX_SUPPLY *was* intended to be mutable initially and keep the function,
     * but add a comment that it's immutable in this version.
     * Or, better, change the concept slightly: MAX_SUPPLY is immutable, but maybe there's a *per-phase* supply limit?
     * No, keep it simple as requested. MAX_SUPPLY is immutable. Let's remove `setMaxSupply` and the corresponding event and test/update the function count.

     * Count Check after removing `setMaxSupply`: 35 - 1 = 34. Still >= 20. Good.

     * Let's re-add a simple getter or setter to compensate if needed.
     * Maybe add a setter for the initial energy amount at mint? No, let's keep initial energy 0 for simplicity.
     * How about a setter for the *initial* energy amount for *admin* mints vs public?
     * No, let's stick to the original plan and make sure the functions match the summary exactly.
     * The summary listed `setMaxSupply`. The *implementation* made it immutable. This is a conflict.
     * Okay, let's revert MAX_SUPPLY to be a state variable `uint256 private _maxSupply;` and make it mutable via `setMaxSupply`.
     */

    // Redefine MAX_SUPPLY to be a state variable to match the summary function
    uint256 private _maxSupply; // Now mutable

    // Update constructor to set _maxSupply
    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI,
        uint256 maxSupply_, // This is now the initial value for the mutable state variable
        uint256 mintPrice_,
        uint256 evolutionCost_,
        uint256 rollCostEther_,
        uint256 addEnergyPrice_,
        uint256 initialGenerationSeed
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (maxSupply_ == 0) revert("Initial max supply cannot be zero");
        _maxSupply = maxSupply_; // Set the state variable
        _baseTokenURI = initialBaseURI;
        _mintPrice = mintPrice_;
        _evolutionCost = evolutionCost_;
        _rollCostEther = rollCostEther_;
        _addEnergyPrice = addEnergyPrice_;
        _generationSeed = initialGenerationSeed;

        // Initialize max values for each trait type (Simplified)
        _maxTraitValues[TraitType.Background] = 5;
        _maxTraitValues[TraitType.Body] = 10;
        _maxTraitValues[TraitType.Head] = 8;
        _maxTraitValues[TraitType.Accessory] = 12;
        _maxTraitValues[TraitType.Expression] = 7;
    }

    // Getter for maxSupply (was accidentally removed during mutable change)
    function maxSupply() public view returns (uint256) {
        return _maxSupply; // Now refers to the state variable
    }

     /**
     * @dev Sets the maximum number of tokens that can be minted (Owner only).
     * New max supply must be greater than or equal to current total supply.
     */
    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        if (newMaxSupply < _tokenIds.current()) {
            revert("New max supply below current total supply");
        }
        uint256 oldMaxSupply = _maxSupply;
        _maxSupply = newMaxSupply;
        emit MaxSupplySet(oldMaxSupply, newMaxSupply);
    }

    /**
     * @dev Sets the price for public minting (Owner only).
     */
    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        uint256 oldPrice = _mintPrice;
        _mintPrice = newMintPrice;
        emit MintPriceSet(oldPrice, newMintPrice);
    }

    /**
     * @dev Sets the energy cost for evolving a single trait (Owner only).
     */
    function setEvolutionCost(uint256 newCost) external onlyOwner {
        uint256 oldCost = _evolutionCost;
        _evolutionCost = newCost;
        emit EvolutionCostSet(oldCost, newCost);
    }

     /**
     * @dev Sets the Ether cost for rolling all traits (Owner only).
     */
    function setRollCostEther(uint256 newCost) external onlyOwner {
        uint256 oldCost = _rollCostEther;
        _rollCostEther = newCost;
        emit RollCostEtherSet(oldCost, newCost);
    }

     /**
     * @dev Sets the Ether price to add 1 unit of energy to a token (Owner only).
     */
    function setAddEnergyPrice(uint256 newPrice) external onlyOwner {
        uint256 oldPrice = _addEnergyPrice;
        _addEnergyPrice = newPrice;
        emit AddEnergyPriceSet(oldPrice, newPrice);
    }

    /**
     * @dev Sets the generation seed used for deterministic trait generation (Owner only).
     * Changing this will affect the generation of *future* tokens.
     * WARNING: Use with caution, changing the seed mid-mint can affect randomness distribution.
     */
    function setGenerationSeed(uint256 newSeed) external onlyOwner {
        uint256 oldSeed = _generationSeed;
        _generationSeed = newSeed;
        emit GenerationSeedSet(oldSeed, newSeed);
    }

    /**
     * @dev Withdraws the entire contract balance to the owner (Owner only).
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit Withdraw(owner(), balance);
    }

    // Ownership transfer functions inherited from Ownable

    // --- Internal Overrides for ERC721 State Management ---

    // OpenZeppelin's ERC721 handles the owner mapping internally.
    // We manage `_tokenData` separately.
    // We could override _beforeTokenTransfer and _afterTokenTransfer
    // if we needed to specifically handle cleanup or initialization
    // related to _tokenData during transfers or burns,
    // but for simple mapping/struct storage, it's often not strictly required unless
    // the struct contained references that needed manual cleanup.
    // For this case, the mapping keys are tokenIds, which are implicitly managed by OZ ERC721.
    // If we needed to *delete* data on burn, we'd override _beforeTokenTransfer and check for burning.
    // Let's add an override to demonstrate and handle potential data cleanup on burn.

    /**
     * @dev Internal function called before any token transfer, including minting and burning.
     * Handles cleanup of token-specific data upon burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Check if it's a burn (transfer to address(0))
        if (to == address(0)) {
            // Clean up token-specific data
            delete _tokenData[tokenId];
            // Note: Events for burning (e.g., Transfer event from owner to address(0))
            // are handled by the base ERC721 contract.
        }
        // No specific handling needed for mint (from address(0)) or transfer (from != 0 && to != 0)
        // as _tokenData is initialized on mint and stays associated with tokenId.
    }
}
```