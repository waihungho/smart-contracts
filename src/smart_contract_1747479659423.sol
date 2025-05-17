Okay, let's design a smart contract for Generative Art NFTs with Dynamic Traits.

The core concept is that the NFT's visual representation (which happens *off-chain* via metadata API) is determined by on-chain parameters. These parameters are initially set during minting using a semi-random seed derived from blockchain data, and some of these parameters can change over time or based on user interactions (dynamic traits).

This involves:
1.  **Generative Seed:** Using block data, sender address, etc., to create a unique seed per token.
2.  **On-Chain Trait Data:** Storing specific parameters (color palettes, shapes, patterns, "evolution stage", "complexity") directly in the contract's state for each token ID.
3.  **Dynamic Traits:** Implementing functions where users can interact with their NFTs (e.g., "nurture", "stimulate") to influence certain parameters, causing them to evolve or change over time.
4.  **Metadata API Dependency:** The `tokenURI` will point to an external API that reads the on-chain trait data for a given token ID and generates the corresponding metadata JSON (including trait attributes) and potentially an image/SVG URI.
5.  **Admin Controls:** Functions for the owner to manage parameters like mint price, supply limits, interaction costs, and base URI.

This design combines ERC-721 standards with custom logic for generative seeding, dynamic trait storage, and user interaction, which is more complex than standard static image NFTs and provides ongoing utility/engagement.

---

## Smart Contract Outline & Function Summary

**Contract Name:** `GenerativeArtNFTWithDynamicTraits`

**Core Concept:** An ERC-721 NFT contract where token traits determining generative art are stored on-chain and can evolve through user interaction and time.

**Inherits:** ERC721, Ownable, Pausable, ReentrancyGuard

**State Variables:**
*   `_artworkData`: Mapping from token ID to `ArtworkData` struct.
*   `_currentSupply`: Counter for minted tokens.
*   `_maxSupply`: Maximum number of tokens that can be minted.
*   `_mintPrice`: Cost to mint one token.
*   `_nurtureCost`: Cost for the `nurtureArtwork` function.
*   `_evolutionCost`: Cost for the `evolveArtwork` function.
*   `_stimulateCost`: Cost for the `stimulateComplexity` function.
*   `_minTimeForEvolution`: Minimum time elapsed since last evolution for a new evolution.
*   `_evolutionStageThresholds`: Array defining requirements (e.g., interaction count, time) for each evolution stage.
*   `_complexityDecayRate`: Rate at which complexity score decays over time if not stimulated.
*   `_baseTokenURI`: The base URI for the metadata API.

**Structs:**
*   `ArtworkData`: Stores generative and dynamic traits for an NFT.
    *   `seed`: Initial generation seed.
    *   `creationTime`: Timestamp of minting.
    *   `lastInteractionTime`: Timestamp of the last `nurtureArtwork` call.
    *   `lastEvolutionTime`: Timestamp of the last `evolveArtwork` call.
    *   `lastStimulationTime`: Timestamp of the last `stimulateComplexity` call.
    *   `interactionCount`: Total times `nurtureArtwork` was called.
    *   `evolutionStage`: Current evolution stage (integer).
    *   `baseComplexityScore`: Complexity score influenced by `stimulateComplexity`.

**Events:**
*   `ArtworkMinted(uint256 indexed tokenId, address indexed owner, uint256 seed)`
*   `ArtworkNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newInteractionCount)`
*   `ArtworkEvolved(uint256 indexed tokenId, uint256 newEvolutionStage)`
*   `ComplexityStimulated(uint256 indexed tokenId, uint256 newBaseComplexityScore)`
*   `MintPriceUpdated(uint256 newPrice)`
*   `MaxSupplyUpdated(uint256 newMaxSupply)`
*   `BaseURIUpdated(string newBaseURI)`
*   `MintingPaused(address indexed account)`
*   `MintingUnpaused(address indexed account)`

**Functions (Total > 20):**

**ERC-721 Standard Functions (from inheritance):**
1.  `balanceOf(address owner) view returns (uint256)`
2.  `ownerOf(uint256 tokenId) view returns (address)`
3.  `transferFrom(address from, address to, uint256 tokenId)`
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`
6.  `approve(address to, uint256 tokenId)`
7.  `getApproved(uint256 tokenId) view returns (address)`
8.  `setApprovalForAll(address operator, bool approved)`
9.  `isApprovedForAll(address owner, address operator) view returns (bool)`
10. `supportsInterface(bytes4 interfaceId) view returns (bool)`
11. `totalSupply() view returns (uint256)` (from Enumerable)
12. `tokenByIndex(uint256 index) view returns (uint256)` (from Enumerable)
13. `tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)` (from Enumerable)
14. `tokenURI(uint256 tokenId) view returns (string memory)` (Overrides ERC721)

**Minting Functions:**
15. `mintArtwork() payable`: Public function to mint a new NFT. Requires payment of `_mintPrice`. Generates a unique seed and initializes artwork data. Increments supply.
16. `_generateInitialSeed(uint256 tokenId) internal pure returns (uint256)`: Internal helper to generate a pseudo-random seed based on block data, sender, and token ID. *Note: This is not cryptographically secure randomness.*
17. `_initializeArtworkData(uint256 tokenId, uint256 seed)`: Internal helper to set initial values in the `_artworkData` struct for a new token.

**Dynamic Trait Interaction Functions:**
18. `nurtureArtwork(uint256 tokenId) payable nonReentrant whenNotPaused`: Allows the owner (or approved address) to "nurture" their NFT. Requires payment of `_nurtureCost`. Updates `lastInteractionTime` and increments `interactionCount`.
19. `evolveArtwork(uint256 tokenId) payable nonReentrant whenNotPaused`: Allows the owner (or approved address) to attempt to "evolve" their NFT. Requires payment of `_evolutionCost`. Checks time elapsed since last evolution and interaction count against `_evolutionStageThresholds`. If conditions are met, increments `evolutionStage` and updates `lastEvolutionTime`.
20. `stimulateComplexity(uint256 tokenId) payable nonReentrant whenNotPaused`: Allows the owner (or approved address) to "stimulate" their NFT's complexity. Requires payment of `_stimulateCost`. Increases the `baseComplexityScore` for the artwork.

**Data Query Functions:**
21. `getArtworkData(uint256 tokenId) view returns (ArtworkData memory)`: Returns all stored data for a specific token ID.
22. `getEvolutionStage(uint256 tokenId) view returns (uint256)`: Returns the current evolution stage of an NFT.
23. `getEffectiveComplexity(uint256 tokenId, uint256 currentTime) view returns (uint256)`: Calculates and returns the *effective* complexity score, considering the `baseComplexityScore` and time decay since last stimulation using the provided `currentTime`.
24. `getLastInteractionTime(uint256 tokenId) view returns (uint256)`: Returns the timestamp of the last nurture interaction.
25. `getInteractionCount(uint256 tokenId) view returns (uint256)`: Returns the total nurture interaction count.
26. `getCurrentSupply() view returns (uint256)`: Returns the number of tokens minted so far. Alias for `totalSupply()`.
27. `getMaxSupply() view returns (uint256)`: Returns the maximum allowed supply.
28. `getMintPrice() view returns (uint256)`: Returns the current mint price.
29. `getNurtureCost() view returns (uint256)`: Returns the cost for nurturing.
30. `getEvolutionCost() view returns (uint256)`: Returns the cost for evolving.
31. `getStimulateCost() view returns (uint256)`: Returns the cost for stimulating complexity.
32. `getMinTimeForEvolution() view returns (uint256)`: Returns the minimum time required between evolutions.
33. `getEvolutionStageThresholds() view returns (uint256[] memory)`: Returns the array of evolution thresholds.
34. `getComplexityDecayRate() view returns (uint256)`: Returns the complexity decay rate.
35. `isMintingPaused() view returns (bool)`: Checks if minting is paused.

**Admin/Owner Functions (Require `onlyOwner`):**
36. `pauseMinting()`: Pauses the `mintArtwork` function.
37. `unpauseMinting()`: Unpauses the `mintArtwork` function.
38. `withdrawFunds()`: Allows the owner to withdraw collected ETH from the contract.
39. `setMaxSupply(uint256 newMaxSupply)`: Sets the maximum number of tokens that can be minted.
40. `setMintPrice(uint256 newPrice)`: Sets the price for minting.
41. `setNurtureCost(uint256 newCost)`: Sets the cost for nurturing.
42. `setEvolutionCost(uint256 newCost)`: Sets the cost for evolving.
43. `setStimulateCost(uint256 newCost)`: Sets the cost for stimulating complexity.
44. `setMinTimeForEvolution(uint256 newMinTime)`: Sets the minimum time required between evolutions.
45. `setEvolutionStageThresholds(uint256[] memory newThresholds)`: Sets the requirements for each evolution stage.
46. `setComplexityDecayRate(uint256 newRate)`: Sets the complexity decay rate.
47. `setBaseURI(string memory newBaseURI)`: Sets the base URI for the metadata API.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title GenerativeArtNFTWithDynamicTraits
/// @dev An ERC-721 contract for generative art NFTs where token traits are stored on-chain
/// and can evolve through user interaction and time. Metadata is served via an off-chain API.
contract GenerativeArtNFTWithDynamicTraits is ERC721, ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /// @notice Stores the generative and dynamic trait data for each artwork token.
    struct ArtworkData {
        uint256 seed;              // Initial seed for off-chain generative rendering
        uint256 creationTime;      // Timestamp of minting
        uint256 lastInteractionTime; // Timestamp of the last nurture/interaction
        uint256 lastEvolutionTime;   // Timestamp of the last evolution
        uint256 lastStimulationTime; // Timestamp of the last complexity stimulation
        uint256 interactionCount;  // Total times artwork has been nurtured
        uint256 evolutionStage;    // Current evolution stage (e.g., 0, 1, 2...)
        uint256 baseComplexityScore; // Base score for complexity, influenced by stimulation
    }

    // --- State Variables ---
    mapping(uint256 => ArtworkData) private _artworkData;
    Counters.Counter private _currentSupply;
    uint256 private _maxSupply;
    uint256 private _mintPrice;
    uint256 private _nurtureCost;
    uint256 private _evolutionCost;
    uint256 private _stimulateCost;
    uint256 private _minTimeForEvolution; // Minimum time (in seconds) required between evolutions
    uint256[] private _evolutionStageThresholds; // Array of interaction counts required for each stage [stage1_req, stage2_req, ...]
    uint256 private _complexityDecayRate; // Rate per second for complexity decay (larger number = slower decay)
    string private _baseTokenURI; // Base URI for the metadata API

    // --- Events ---
    event ArtworkMinted(uint256 indexed tokenId, address indexed owner, uint256 seed);
    event ArtworkNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 newInteractionCount);
    event ArtworkEvolved(uint256 indexed tokenId, uint256 newEvolutionStage);
    event ComplexityStimulated(uint256 indexed tokenId, uint256 newBaseComplexityScore);
    event MintPriceUpdated(uint256 newPrice);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event BaseURIUpdated(string newBaseURI);
    event MintingPaused(address indexed account);
    event MintingUnpaused(address indexed account);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialMaxSupply,
        uint256 initialMintPrice,
        uint256 initialNurtureCost,
        uint256 initialEvolutionCost,
        uint256 initialStimulateCost,
        uint256 initialMinTimeForEvolution,
        uint256[] memory initialEvolutionThresholds,
        uint256 initialComplexityDecayRate,
        string memory initialBaseURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _maxSupply = initialMaxSupply;
        _mintPrice = initialMintPrice;
        _nurtureCost = initialNurtureCost;
        _evolutionCost = initialEvolutionCost;
        _stimulateCost = initialStimulateCost;
        _minTimeForEvolution = initialMinTimeForEvolution;
        _evolutionStageThresholds = initialEvolutionThresholds;
        _complexityDecayRate = initialComplexityDecayRate;
        _baseTokenURI = initialBaseURI;
    }

    // --- ERC-721 Overrides & Standard Functions (Included in Count) ---

    /// @inheritdoc ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /// @inheritdoc ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

     /// @dev Base URI for computing {tokenURI}. Appends token ID to the base URI.
     /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Returns the metadata URI for a given token ID.
    /// @dev This implementation assumes an off-chain service serves metadata based on the token ID
    /// and the on-chain ArtworkData.
    /// @param tokenId The identifier for the token.
    /// @return A string representing the URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists before querying data

        string memory base = _baseURI();
        // Assumes the metadata API endpoint is like baseURI/tokenId
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /// @notice Returns the total number of tokens in existence.
    /// @return The total supply count.
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return _currentSupply.current();
    }

    // Functions inherited from ERC721, Ownable, Pausable, ReentrancyGuard
    // These are automatically available and count towards the function count:
    // 1. balanceOf(address owner)
    // 2. ownerOf(uint256 tokenId)
    // 3. transferFrom(address from, address to, uint256 tokenId)
    // 4. safeTransferFrom(address from, address to, uint256 tokenId)
    // 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    // 6. approve(address to, uint256 tokenId)
    // 7. getApproved(uint256 tokenId)
    // 8. setApprovalForAll(address operator, bool approved)
    // 9. isApprovedForAll(address owner, address operator)
    // 10. supportsInterface(bytes4 interfaceId)
    // 11. totalSupply() // Alias for getCurrentSupply
    // 12. tokenByIndex(uint256 index)
    // 13. tokenOfOwnerByIndex(address owner, uint256 index)
    // 14. tokenURI(uint256 tokenId) // Overridden above
    // 15. pause() (from Pausable - inherited, makes pausable functions pause)
    // 16. unpause() (from Pausable - inherited, makes pausable functions unpause)
    // 17. paused() view returns (bool) (from Pausable - inherited, checks pause state)
    // 18. renounceOwnership() (from Ownable - inherited)
    // 19. transferOwnership(address newOwner) (from Ownable - inherited)

    // --- Minting Functions ---

    /// @notice Allows anyone to mint a new generative artwork NFT.
    /// @dev Requires payment of the current mint price. Generates a seed and initializes data.
    /// @return The ID of the newly minted token.
    function mintArtwork() public payable nonReentrant whenNotPaused returns (uint256) {
        uint256 supply = _currentSupply.current();
        require(supply < _maxSupply, "Max supply reached");
        require(msg.value >= _mintPrice, "Insufficient funds");

        uint256 newTokenId = supply; // Simple sequential ID

        _currentSupply.increment();

        uint256 seed = _generateInitialSeed(newTokenId);
        _artworkData[newTokenId] = _initializeArtworkData(newTokenId, seed);

        _safeMint(msg.sender, newTokenId);

        if (msg.value > _mintPrice) {
            // Refund excess ETH
            (bool success, ) = payable(msg.sender).call{value: msg.value - _mintPrice}("");
            require(success, "Refund failed");
        }

        emit ArtworkMinted(newTokenId, msg.sender, seed);
        return newTokenId;
    }

    /// @dev Generates an initial seed for generative art based on block data, sender, and token ID.
    /// @notice This is NOT cryptographically secure and should not be used where guaranteed
    /// unpredictable randomness is required (e.g., gambling, fair draws). It's suitable here
    /// for creating diverse initial visual parameters.
    /// @param tokenId The ID of the token being minted.
    /// @return A pseudo-random seed value.
    function _generateInitialSeed(uint256 tokenId) internal view returns (uint256) {
        // Use a combination of block data and transaction details for a unique seed per mint.
        // Avoid relying solely on block.timestamp or block.number for security/predictability.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // block.difficulty might be 0 on L2s/newer Eth versions. Use block.prevrandao if available and relevant. Using difficulty here for simplicity.
            msg.sender,
            tx.origin,
            tokenId,
            _currentSupply.current(), // Use pre-incremented supply value
            address(this)
        )));
        return seed;
    }

    /// @dev Initializes the ArtworkData struct for a newly minted token.
    /// @param tokenId The ID of the token being minted.
    /// @param seed The initial seed generated for the artwork.
    /// @return The initialized ArtworkData struct.
    function _initializeArtworkData(uint256 tokenId, uint256 seed) internal view returns (ArtworkData memory) {
        // The struct is implicitly initialized with default values (0 for uint, false for bool)
        // when assigned to a mapping key that doesn't exist.
        // We explicitly set non-zero or relevant initial values here.
        ArtworkData memory newArtwork;
        newArtwork.seed = seed;
        newArtwork.creationTime = block.timestamp;
        newArtwork.lastInteractionTime = block.timestamp; // Start fresh
        newArtwork.lastEvolutionTime = block.timestamp;   // Start fresh
        newArtwork.lastStimulationTime = block.timestamp; // Start fresh
        newArtwork.interactionCount = 0; // Starts at stage 0 implicitly
        newArtwork.evolutionStage = 0;
        newArtwork.baseComplexityScore = 0;

        // If you want a non-zero starting complexity, set it here:
        // newArtwork.baseComplexityScore = 100; // Example

        return newArtwork;
    }


    // --- Dynamic Trait Interaction Functions ---

    /// @notice Allows the token owner or approved address to "nurture" their artwork.
    /// @dev Costs `_nurtureCost`. Updates interaction time and count.
    /// @param tokenId The ID of the artwork token.
    function nurtureArtwork(uint256 tokenId) public payable nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to nurture");
        require(msg.value >= _nurtureCost, "Insufficient funds for nurture");

        ArtworkData storage artwork = _artworkData[tokenId];
        artwork.lastInteractionTime = block.timestamp;
        artwork.interactionCount++;

         if (msg.value > _nurtureCost) {
            // Refund excess ETH
            (bool success, ) = payable(msg.sender).call{value: msg.value - _nurtureCost}("");
            require(success, "Refund failed");
        }

        emit ArtworkNurtured(tokenId, msg.sender, artwork.interactionCount);
    }

    /// @notice Allows the token owner or approved address to attempt to "evolve" their artwork.
    /// @dev Costs `_evolutionCost`. Requires meeting evolution stage thresholds and time cooldown.
    /// @param tokenId The ID of the artwork token.
    function evolveArtwork(uint256 tokenId) public payable nonReentrant whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to evolve");
        require(msg.value >= _evolutionCost, "Insufficient funds for evolution");

        ArtworkData storage artwork = _artworkData[tokenId];

        // Check if there are higher stages available
        require(artwork.evolutionStage < _evolutionStageThresholds.length, "Artwork is at max evolution stage");

        // Check if enough time has passed since the last evolution attempt
        require(block.timestamp >= artwork.lastEvolutionTime + _minTimeForEvolution, "Evolution cooldown active");

        // Check if interaction count meets the requirement for the next stage
        uint256 nextStageIndex = artwork.evolutionStage; // Next threshold to check
        uint256 requiredInteractions = _evolutionStageThresholds[nextStageIndex];
        require(artwork.interactionCount >= requiredInteractions, "Not enough interactions for next stage");

        // Perform the evolution
        artwork.evolutionStage++;
        artwork.lastEvolutionTime = block.timestamp;
        // Optionally reset interaction count for the next stage, or let it accumulate
        // artwork.interactionCount = 0; // Uncomment to reset interaction count each stage

        if (msg.value > _evolutionCost) {
            // Refund excess ETH
            (bool success, ) = payable(msg.sender).call{value: msg.value - _evolutionCost}("");
            require(success, "Refund failed");
        }

        emit ArtworkEvolved(tokenId, artwork.evolutionStage);
    }

    /// @notice Allows the token owner or approved address to "stimulate" their artwork's complexity.
    /// @dev Costs `_stimulateCost`. Increases the base complexity score.
    /// @param tokenId The ID of the artwork token.
    function stimulateComplexity(uint256 tokenId) public payable nonReentrant whenNotPaused {
         require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to stimulate");
        require(msg.value >= _stimulateCost, "Insufficient funds for stimulation");

        ArtworkData storage artwork = _artworkData[tokenId];

        // Increase complexity - simple increment, could be more complex formula
        artwork.baseComplexityScore++;
        artwork.lastStimulationTime = block.timestamp;

        if (msg.value > _stimulateCost) {
            // Refund excess ETH
            (bool success, ) = payable(msg.sender).call{value: msg.value - _stimulateCost}("");
            require(success, "Refund failed");
        }

        emit ComplexityStimulated(tokenId, artwork.baseComplexityScore);
    }

    // --- Data Query Functions ---

    /// @notice Retrieves all stored ArtworkData for a specific token ID.
    /// @param tokenId The ID of the artwork token.
    /// @return The ArtworkData struct for the token.
    function getArtworkData(uint256 tokenId) public view returns (ArtworkData memory) {
         _requireOwned(tokenId); // Ensure token exists
        return _artworkData[tokenId];
    }

    /// @notice Retrieves the current evolution stage for a specific token ID.
    /// @param tokenId The ID of the artwork token.
    /// @return The evolution stage (integer).
    function getEvolutionStage(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _artworkData[tokenId].evolutionStage;
    }

    /// @notice Calculates and returns the effective complexity score, considering time decay.
    /// @dev The effective complexity decays from the base score based on time since last stimulation.
    /// @param tokenId The ID of the artwork token.
    /// @param currentTime The current timestamp to use for calculation (e.g., block.timestamp).
    /// @return The effective complexity score.
    function getEffectiveComplexity(uint256 tokenId, uint256 currentTime) public view returns (uint256) {
        _requireOwned(tokenId);
        ArtworkData memory artwork = _artworkData[tokenId];
        uint256 base = artwork.baseComplexityScore;
        uint256 lastStim = artwork.lastStimulationTime;
        uint256 decayRate = _complexityDecayRate;

        if (decayRate == 0 || currentTime <= lastStim) {
            return base; // No decay if rate is 0 or time hasn't passed
        }

        uint256 timeElapsed = currentTime - lastStim;
        uint256 decayAmount = timeElapsed / decayRate; // Simple linear decay

        // Ensure complexity doesn't go below zero
        return base > decayAmount ? base - decayAmount : 0;
    }

    /// @notice Retrieves the timestamp of the last nurture interaction for a token.
    /// @param tokenId The ID of the artwork token.
    /// @return The timestamp.
    function getLastInteractionTime(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _artworkData[tokenId].lastInteractionTime;
    }

     /// @notice Retrieves the total nurture interaction count for a token.
    /// @param tokenId The ID of the artwork token.
    /// @return The interaction count.
    function getInteractionCount(uint256 tokenId) public view returns (uint256) {
        _requireOwned(tokenId);
        return _artworkData[tokenId].interactionCount;
    }

    /// @notice Returns the current number of tokens minted.
    /// @return The current supply.
    function getCurrentSupply() public view returns (uint256) {
        return _currentSupply.current();
    }

    /// @notice Returns the maximum number of tokens that can be minted.
    /// @return The maximum supply.
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// @notice Returns the current price to mint a token.
    /// @return The mint price in wei.
    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    /// @notice Returns the current cost for nurturing an artwork.
    /// @return The nurture cost in wei.
    function getNurtureCost() public view returns (uint256) {
        return _nurtureCost;
    }

     /// @notice Returns the current cost for evolving an artwork.
    /// @return The evolution cost in wei.
    function getEvolutionCost() public view returns (uint256) {
        return _evolutionCost;
    }

     /// @notice Returns the current cost for stimulating complexity.
    /// @return The stimulation cost in wei.
    function getStimulateCost() public view returns (uint256) {
        return _stimulateCost;
    }

    /// @notice Returns the minimum time required between evolution attempts.
    /// @return The minimum time in seconds.
    function getMinTimeForEvolution() public view returns (uint256) {
        return _minTimeForEvolution;
    }

    /// @notice Returns the interaction count thresholds required for each evolution stage.
    /// @return An array of required interaction counts.
    function getEvolutionStageThresholds() public view returns (uint256[] memory) {
        return _evolutionStageThresholds;
    }

    /// @notice Returns the complexity decay rate.
    /// @return The decay rate (larger is slower decay).
    function getComplexityDecayRate() public view returns (uint256) {
        return _complexityDecayRate;
    }

    /// @notice Returns the base URI used for token metadata.
    /// @return The base URI string.
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Checks if minting is currently paused.
    /// @return True if paused, false otherwise.
    function isMintingPaused() public view returns (bool) {
        return paused(); // Uses the paused() function from Pausable
    }


    // --- Admin/Owner Functions ---

    /// @notice Pauses the minting process. Only callable by the owner.
    function pauseMinting() public onlyOwner {
        _pause();
        emit MintingPaused(msg.sender);
    }

    /// @notice Unpauses the minting process. Only callable by the owner.
    function unpauseMinting() public onlyOwner {
        _unpause();
        emit MintingUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to withdraw collected ETH.
    function withdrawFunds() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Sets the maximum total supply for the collection.
    /// @dev Can only be set to a value greater than or equal to the current supply.
    /// @param newMaxSupply The new maximum supply.
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        require(newMaxSupply >= _currentSupply.current(), "New max supply must be >= current supply");
        _maxSupply = newMaxSupply;
        emit MaxSupplyUpdated(newMaxSupply);
    }

    /// @notice Sets the price required to mint a new token.
    /// @param newPrice The new mint price in wei.
    function setMintPrice(uint256 newPrice) public onlyOwner {
        _mintPrice = newPrice;
        emit MintPriceUpdated(newPrice);
    }

    /// @notice Sets the cost for nurturing an artwork.
    /// @param newCost The new nurture cost in wei.
    function setNurtureCost(uint256 newCost) public onlyOwner {
        _nurtureCost = newCost;
    }

    /// @notice Sets the cost for evolving an artwork.
    /// @param newCost The new evolution cost in wei.
    function setEvolutionCost(uint256 newCost) public onlyOwner {
        _evolutionCost = newCost;
    }

    /// @notice Sets the cost for stimulating complexity.
    /// @param newCost The new stimulation cost in wei.
    function setStimulateCost(uint256 newCost) public onlyOwner {
        _stimulateCost = newCost;
    }

    /// @notice Sets the minimum time required between evolution attempts.
    /// @param newMinTime The new minimum time in seconds.
    function setMinTimeForEvolution(uint256 newMinTime) public onlyOwner {
        _minTimeForEvolution = newMinTime;
    }

    /// @notice Sets the interaction count thresholds required for each evolution stage.
    /// @dev Index 0 is requirement for stage 1, Index 1 for stage 2, etc.
    /// Empty array means no evolution beyond stage 0 is possible.
    /// @param newThresholds An array of required interaction counts.
    function setEvolutionStageThresholds(uint256[] memory newThresholds) public onlyOwner {
        // Basic validation: Ensure current evolution stages are still reachable or handled
        // For simplicity, we allow setting any array, but changes might affect existing NFTs
        // that haven't evolved yet. A robust contract might require more complex checks
        // or migration logic.
        _evolutionStageThresholds = newThresholds;
    }

    /// @notice Sets the complexity decay rate. Larger number means slower decay.
    /// @dev A rate of 0 means no decay. Rate represents seconds per point of decay.
    /// @param newRate The new decay rate.
    function setComplexityDecayRate(uint256 newRate) public onlyOwner {
        _complexityDecayRate = newRate;
    }

    /// @notice Sets the base URI for the token metadata API.
    /// @param newBaseURI The new base URI string.
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // --- Internal Helpers ---

    /// @dev Throws if `tokenId` is not owned by `owner` or approved by `owner`.
    function _requireOwned(uint256 tokenId) internal view {
        require(_exists(tokenId), "ERC721: invalid token ID");
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "ERC721: access denied");
    }
}
```