Okay, here is a Solidity smart contract called `CryptoSculptor`. It implements a dynamic NFT concept where tokens (Sculptures) can be modified and evolve over time through different "sculpting" techniques applied by the token owner. It incorporates stages of sculpting, various techniques affecting on-chain attributes, a finalization process, and some conditional logic based on time or state.

It aims for creativity by making the NFT not static but a work-in-progress that the owner actively participates in creating, and advanced concepts like complex on-chain state per token and multiple state-changing functions influencing that state.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Outline and Function Summary ---
/*
Contract Name: CryptoSculptor

Description:
A dynamic NFT contract where each token represents a digital sculpture.
Owners can apply various "sculpting techniques" to their tokens,
modifying on-chain attributes such as shape, color, texture, and complexity score.
The sculptures evolve through different stages, culminating in a final,
immutable state. The metadata associated with the token URI should ideally
reflect the current on-chain state of the sculpture.

Core Concepts:
1.  ERC721 Standard: Core non-fungible token functionality.
2.  Dynamic State: Each token has unique, mutable on-chain data (`TokenData`).
3.  Sculpting Techniques: Multiple functions that modify the token's state.
4.  Sculpting Stages: Progression through defined stages unlocking abilities.
5.  Complexity Score: A key attribute influenced by sculpting, required for stage advancement.
6.  Finalization: Locking the token's state after reaching the final stage.
7.  On-Chain Influence: Techniques potentially influenced by block data (timestamp/number).
8.  Owner Interaction: Only the token owner can apply most techniques.
9.  Admin Control: Basic contract management (pause, withdraw, settings).

Outline:
1.  Imports
2.  Error Definitions
3.  Enums
4.  Structs
5.  State Variables
6.  Events
7.  Modifiers
8.  Constructor
9.  Pausable Implementation
10. ERC721 Overrides (_baseURI, tokenURI)
11. Core Minting Logic
12. Internal State Management Helpers
13. Sculpting Functions (Modify TokenData)
14. Stage Management Functions
15. Finalization Function
16. Post-Transfer Mechanics
17. Query/View Functions
18. Admin/Owner Functions

Function Summary (> 20 functions):
1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, sets name, symbol, and owner.
2.  `pause()`: Owner function to pause minting and sculpting.
3.  `unpause()`: Owner function to unpause the contract.
4.  `_baseURI()`: Internal helper for token URI generation.
5.  `tokenURI(uint256 tokenId)`: Returns the URI for a token's metadata.
6.  `mintRawMaterial()`: Payable function to mint a new raw sculpture NFT.
7.  `_beforeTokenTransfer(...)`: Internal ERC721 hook (not callable directly) for transfer logic.
8.  `_afterTokenTransfer(...)`: Internal ERC721 hook (not callable directly) for post-transfer logic.
9.  `_getTokenData(uint256 tokenId)`: Internal helper to get token data (saves gas over public getter when used internally).
10. `_updateComplexity(uint256 tokenId, int256 scoreChange)`: Internal helper to adjust complexity score.
11. `applyChiselTechnique(uint256 tokenId)`: Basic sculpting, increases complexity and subtly changes shape/texture.
12. `applySandingTechnique(uint256 tokenId)`: Smooths surface, changes texture, slight complexity change.
13. `applyPolishingTechnique(uint256 tokenId)`: Adds shine, changes color/texture, increases complexity.
14. `applyEtchingTechnique(uint256 tokenId)`: Adds detail based on block number parity, moderate complexity gain.
15. `applyHeatTreatment(uint256 tokenId)`: Drastically changes color and texture, variable complexity change (can be negative).
16. `applyPatina(uint256 tokenId)`: Adds an aged layer, influenced by timestamp, changes color/texture.
17. `applyRandomMutation(uint256 tokenId)`: Applies an unpredictable change to attributes and complexity based on limited on-chain "randomness".
18. `reinforceStructure(uint256 tokenId)`: Focuses on structural integrity, significant complexity gain, minimal attribute change.
19. `addInlay(uint256 tokenId, uint8 inlayType)`: Adds a conceptual inlay, increases complexity, adds unique attribute data.
20. `cleanSurface(uint256 tokenId)`: Reduces complexity slightly, can reset some texture/color aspects.
21. `applyAestheticFilter(uint256 tokenId, uint8 filterCode)`: Applies a specific visual style (conceptual), changes color/texture based on input.
22. `burnFlaws(uint256 tokenId)`: Reduces complexity but potentially improves base stats (removes negative traits).
23. `applyRarePigment(uint256 tokenId, uint8 pigmentCode)`: Applies a specific color pigment, increases complexity, maybe limited use per pigment type (not fully implemented for simplicity).
24. `performStructuralAnalysis(uint256 tokenId)`: Increases complexity score, represents research/planning.
25. `addSignature(uint256 tokenId, bytes32 signatureHash)`: Adds a conceptual signature (can only be done once), increases complexity, finalizes a aspect.
26. `advanceSculptingStage(uint256 tokenId)`: Progresses the token to the next stage if complexity threshold is met.
27. `finalizeSculpture(uint256 tokenId)`: Marks the sculpture as complete and immutable after reaching the final stage threshold.
28. `refreshAfterTransfer(uint256 tokenId)`: Allows the new owner to perform a single post-transfer adjustment (conceptual).
29. `getTokenData(uint256 tokenId)`: Public view function to get all detailed token data.
30. `getSculptingStage(uint256 tokenId)`: Public view function for the current stage.
31. `getAttributes(uint256 tokenId)`: Public view function for current attributes.
32. `getComplexityScore(uint256 tokenId)`: Public view function for the complexity score.
33. `getTechniqueUsageCount(uint256 tokenId, uint8 techniqueId)`: Public view for technique usage.
34. `isFinalized(uint256 tokenId)`: Public view function for finalization status.
35. `getBaseMaterial(uint256 tokenId)`: Public view function for base material.
36. `getRefreshApplied(uint256 tokenId)`: Public view function for refresh status.
37. `setMaxSupply(uint256 _maxSupply)`: Owner function to set max tokens.
38. `setMintPrice(uint256 _mintPrice)`: Owner function to set mint cost.
39. `setBaseURI(string memory baseURI)`: Owner function to set the metadata base URI.
40. `withdraw()`: Owner function to withdraw contract balance.

(Includes standard ERC721/Enumerable/URIStorage functions like `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`, `setApprovalForAll`, `transferFrom`, `safeTransferFrom`, `totalSupply`, `tokenOfOwnerByIndex`, `tokenByIndex` bringing the total callable/view function count well over 20).
*/

// --- Contract Definition ---

contract CryptoSculptor is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- Error Definitions ---
    error NotOwnerOfToken(uint256 tokenId, address caller);
    error TokenNotRaw(uint256 tokenId);
    error TokenFinalized(uint256 tokenId);
    error InvalidSculptingStage(uint256 tokenId, SculptingStage currentStage, SculptingStage requiredStage);
    error BelowMintPrice(uint256 expectedPrice, uint256 sentValue);
    error MaxSupplyReached(uint256 currentSupply, uint256 maxSupply);
    error InsufficientComplexity(uint256 tokenId, uint256 currentComplexity, uint256 requiredComplexity);
    error AlreadyFinalized(uint256 tokenId);
    error StageNotMax(uint256 tokenId, SculptingStage currentStage, SculptingStage maxStage);
    error RefreshAlreadyApplied(uint256 tokenId);
    error SignatureAlreadyAdded(uint256 tokenId);

    // --- Enums ---
    enum BaseMaterial { Unknown, Marble, Wood, Metal, Stone, Crystal }
    enum SculptingStage { Raw, Beginner, Apprentice, Journeyman, Master, Grandmaster, Final } // 7 stages

    // --- Structs ---
    struct TokenData {
        uint64 mintTimestamp; // When the token was minted
        uint64 lastSculptTimestamp; // When a sculpting action was last applied
        SculptingStage sculptingStage; // Current stage of evolution
        BaseMaterial baseMaterial; // The initial material
        int256 complexityScore; // A score representing complexity/quality/progress

        // On-chain attributes (simplified) - off-chain renderer interprets these
        uint8 shape;    // e.g., 0-100
        uint8 color;    // e.g., 0-255 (grayscale or index)
        uint8 texture;  // e.g., 0-100 (roughness, smoothness)

        mapping(uint8 => uint256) techniqueUsageCounts; // Count how many times each technique ID was used

        bool isFinalized; // True when sculpting is complete
        bool refreshApplied; // Can apply post-transfer refresh once
        bool signatureAdded; // Can add signature once
    }

    // --- State Variables ---
    uint256 public MAX_SUPPLY;
    uint256 public MINT_PRICE;
    string private _baseTokenURI; // Base URI for metadata

    // Mapping from token ID to its data
    mapping(uint256 => TokenData) private _tokenData;

    // Mapping from SculptingStage to the required complexity score to reach the *next* stage
    mapping(SculptingStage => int256) public stageComplexityThresholds;

    // --- Events ---
    event RawMaterialMinted(uint256 indexed tokenId, address indexed owner, BaseMaterial baseMaterial, uint256 mintTimestamp);
    event SculptingApplied(uint256 indexed tokenId, uint8 indexed techniqueId, uint64 timestamp, int256 complexityChange);
    event StageAdvanced(uint256 indexed tokenId, SculptingStage indexed fromStage, SculptingStage indexed toStage, uint64 timestamp);
    event SculptureFinalized(uint256 indexed tokenId, uint64 timestamp, int256 finalComplexityScore);
    event RefreshAppliedEvent(uint256 indexed tokenId, address indexed newOwner, uint64 timestamp);
    event SignatureAddedEvent(uint256 indexed tokenId, bytes32 signatureHash);
    event AttributeChanged(uint256 indexed tokenId, string attributeName, int256 oldValue, int256 newValue); // Generic event for attribute changes

    // --- Modifiers ---
    modifier onlyOwnerOfToken(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) {
            revert NotOwnerOfToken(tokenId, msg.sender);
        }
        _;
    }

    modifier notFinalized(uint256 tokenId) {
        if (_tokenData[tokenId].isFinalized) {
            revert TokenFinalized(tokenId);
        }
        _;
    }

    modifier onlyStage(uint256 tokenId, SculptingStage requiredStage) {
        if (_tokenData[tokenId].sculptingStage != requiredStage) {
            revert InvalidSculptingStage(tokenId, _tokenData[tokenId].sculptingStage, requiredStage);
        }
        _;
    }

    modifier minimumStage(uint256 tokenId, SculptingStage minimumStage) {
        if (_tokenData[tokenId].sculptingStage < minimumStage) {
            revert InvalidSculptingStage(tokenId, _tokenData[tokenId].sculptingStage, minimumStage);
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets the deployer as owner
    {
        MAX_SUPPLY = 5000; // Default max supply
        MINT_PRICE = 0.01 ether; // Default mint price

        // Set complexity thresholds for stage advancement
        stageComplexityThresholds[SculptingStage.Raw] = 100; // Need 100 complexity to reach Beginner
        stageComplexityThresholds[SculptingStage.Beginner] = 300; // Need 300 to reach Apprentice
        stageComplexityThresholds[SculptingStage.Apprentice] = 600; // Need 600 to reach Journeyman
        stageComplexityThresholds[SculptingStage.Journeyman] = 1000; // Need 1000 to reach Master
        stageComplexityThresholds[SculptingStage.Master] = 1500; // Need 1500 to reach Grandmaster
        stageComplexityThresholds[SculptingStage.Grandmaster] = 2500; // Need 2500 to reach Final
        stageComplexityThresholds[SculptingStage.Final] = type(int256).max; // Final stage has no threshold to advance further
    }

    // --- Pausable Implementation ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides ---

    // We override _baseURI and tokenURI to handle metadata pointing to a service
    // that can read our on-chain state and generate dynamic JSON.
    function _baseURI() internal view override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
         // ERC721URIStorage's tokenURI checks existence and returns stored URI or delegates to _baseURI() + tokenId
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory currentURI = super.tokenURI(tokenId);
        if (bytes(currentURI).length > 0) {
            return currentURI;
        }
        // Fallback to baseURI + tokenId
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    // Override needed for ERC721URIStorage
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Override needed for ERC721Enumerable
     function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    // Override needed for ERC721Enumerable
    function _increaseBalance(address account, uint256 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }


    // --- Core Minting Logic ---

    /// @notice Mints a new raw sculpture NFT.
    /// @dev Requires payment of MINT_PRICE and checks against MAX_SUPPLY.
    function mintRawMaterial() public payable whenNotPaused {
        uint256 newTokenId = _tokenIds.current();
        if (newTokenId >= MAX_SUPPLY) {
            revert MaxSupplyReached(newTokenId, MAX_SUPPLY);
        }
        if (msg.value < MINT_PRICE) {
             revert BelowMintPrice(MINT_PRICE, msg.value);
        }

        // Determine base material based on timestamp/block number (pseudo-random)
        uint8 materialSeed = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, newTokenId))) % 5) + 1; // 1 to 5
        BaseMaterial initialMaterial = BaseMaterial(materialSeed);

        // Initialize token data
        TokenData memory newSculpture;
        newSculpture.mintTimestamp = uint64(block.timestamp);
        newSculpture.lastSculptTimestamp = uint64(block.timestamp);
        newSculpture.sculptingStage = SculptingStage.Raw;
        newSculpture.baseMaterial = initialMaterial;
        newSculpture.complexityScore = 0; // Starts at 0
        newSculpture.shape = 50; // Initial neutral state
        newSculpture.color = 128; // Initial neutral state
        newSculpture.texture = 50; // Initial neutral state
        newSculpture.isFinalized = false;
        newSculpture.refreshApplied = false;
        newSculpture.signatureAdded = false;
        // techniqueUsageCounts mapping is default initialized to zeros

        _tokenData[newTokenId] = newSculpture;

        _tokenIds.increment();
        _safeMint(msg.sender, newTokenId);

        emit RawMaterialMinted(newTokenId, msg.sender, initialMaterial, block.timestamp);
    }

    // --- Internal State Management Helpers ---

    /// @dev Internal helper to get mutable token data. Use `getTokenData` for public views.
    function _getTokenData(uint256 tokenId) internal view returns (TokenData storage) {
        require(_exists(tokenId), "CryptoSculptor: Token does not exist");
        return _tokenData[tokenId];
    }

     /// @dev Internal helper to adjust complexity score safely within bounds.
    function _updateComplexity(uint256 tokenId, int256 scoreChange) internal {
        TokenData storage token = _getTokenData(tokenId);
        int256 newScore = token.complexityScore + scoreChange;
        // Prevent score from going too low or high? Or let it? Let's bound it for now.
        token.complexityScore = Math.max(0, newScore); // Complexity shouldn't go below 0 conceptually
        // Max complexity could be enforced too, but let's allow potential large scores.
    }

    /// @dev Internal helper to update attributes safely within bounds.
    function _updateAttribute(uint8 currentValue, int256 change, uint8 min, uint8 max) internal pure returns (uint8) {
        int256 newValue = int256(currentValue) + change;
        newValue = Math.max(int256(min), newValue);
        newValue = Math.min(int256(max), newValue);
        return uint8(newValue);
    }

    /// @dev Records technique usage and updates timestamp.
    function _recordTechniqueUsage(uint256 tokenId, uint8 techniqueId) internal {
        TokenData storage token = _getTokenData(tokenId);
        token.techniqueUsageCounts[techniqueId]++;
        token.lastSculptTimestamp = uint64(block.timestamp);
        emit SculptingApplied(tokenId, techniqueId, block.timestamp, 0); // Emit 0 complexity change initially, actual change happens below
    }

    // --- Sculpting Functions (Modify TokenData) ---
    // Each function represents a different technique an owner can apply.

    /// @notice Applies the basic Chisel technique. Increases complexity.
    /// @dev Usable from Raw stage onwards.
    function applyChiselTechnique(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Raw) {
        _recordTechniqueUsage(tokenId, 1); // Technique ID 1 for Chisel
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 15); // Gain 15 complexity

        // Subtle attribute changes
        int8 shapeChange = int8(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, token.techniqueUsageCounts[1]))) % 5) - 2; // -2 to +2
        int8 textureChange = int8(uint256(keccak256(abi.encodePacked(tokenId, block.number, token.complexityScore))) % 5) - 2; // -2 to +2

        uint8 oldShape = token.shape; uint8 oldTexture = token.texture;
        token.shape = _updateAttribute(token.shape, shapeChange, 0, 100);
        token.texture = _updateAttribute(token.texture, textureChange, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Applies the Sanding technique. Smooths texture.
    /// @dev Usable from Beginner stage onwards.
    function applySandingTechnique(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Beginner) {
        _recordTechniqueUsage(tokenId, 2); // Technique ID 2 for Sanding
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 10); // Gain 10 complexity

        // Significant texture change towards smooth (lower value)
        uint8 oldTexture = token.texture;
        token.texture = _updateAttribute(token.texture, -10, 0, 100);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Applies the Polishing technique. Enhances color/shine.
    /// @dev Usable from Apprentice stage onwards.
    function applyPolishingTechnique(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Apprentice) {
        _recordTechniqueUsage(tokenId, 3); // Technique ID 3 for Polishing
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 20); // Gain 20 complexity

        // Changes color and texture
        uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        token.color = _updateAttribute(token.color, 15, 0, 255);
        token.texture = _updateAttribute(token.texture, -5, 0, 100); // Makes it slightly smoother
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

     /// @notice Applies the Etching technique. Adds fine details based on block number parity.
    /// @dev Usable from Journeyman stage onwards.
    function applyEtchingTechnique(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
        _recordTechniqueUsage(tokenId, 4); // Technique ID 4 for Etching
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 30); // Gain 30 complexity

        // Change shape slightly based on block number parity
        int8 shapeChange = (block.number % 2 == 0) ? 5 : -5;

        uint8 oldShape = token.shape;
        token.shape = _updateAttribute(token.shape, shapeChange, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
    }

    /// @notice Applies Heat Treatment. Can dramatically change color and texture, risky.
    /// @dev Usable from Master stage onwards.
    function applyHeatTreatment(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Master) {
        _recordTechniqueUsage(tokenId, 5); // Technique ID 5 for Heat Treatment
        TokenData storage token = _getTokenData(tokenId);

        // Variable complexity change - risk/reward
        int256 complexityChange = int256(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, token.complexityScore))) % 100) - 40; // Range -40 to +60
        _updateComplexity(tokenId, complexityChange);

        // Drastic color and texture changes
        uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        token.color = _updateAttribute(token.color, int256(uint256(keccak256(abi.encodePacked(tokenId, block.number))) % 100) - 50, 0, 255); // Range -50 to +50
        token.texture = _updateAttribute(token.texture, int256(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 50) - 25, 0, 100); // Range -25 to +25
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Applies Patina. Adds an aged layer based on timestamp parity.
    /// @dev Usable from Journeyman stage onwards.
    function applyPatina(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
        _recordTechniqueUsage(tokenId, 6); // Technique ID 6 for Patina
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 18); // Gain 18 complexity

        // Color and texture change based on timestamp parity
        int8 colorChange = (block.timestamp % 2 == 0) ? 10 : -10;
        int8 textureChange = (block.timestamp % 3 == 0) ? 8 : -8;

        uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        token.color = _updateAttribute(token.color, colorChange, 0, 255);
        token.texture = _updateAttribute(token.texture, textureChange, 0, 100);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Applies a Random Mutation. Unpredictable changes based on combined on-chain data.
    /// @dev Usable from Apprentice stage onwards. Results are highly variable.
    function applyRandomMutation(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Apprentice) {
        _recordTechniqueUsage(tokenId, 7); // Technique ID 7 for Random Mutation
        TokenData storage token = _getTokenData(tokenId);

        // Pseudo-random seed from block data and state
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, block.number, msg.sender, token.complexityScore, token.shape, token.color, token.texture, token.techniqueUsageCounts[7])));

        int256 complexityChange = int256(seed % 101) - 50; // Range -50 to +50
        int8 shapeChange = int8(seed % 21) - 10; // Range -10 to +10
        int8 colorChange = int8(seed % 41) - 20; // Range -20 to +20
        int8 textureChange = int8(seed % 21) - 10; // Range -10 to +10

        _updateComplexity(tokenId, complexityChange);

        uint8 oldShape = token.shape; uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        token.shape = _updateAttribute(token.shape, shapeChange, 0, 100);
        token.color = _updateAttribute(token.color, colorChange, 0, 255);
        token.texture = _updateAttribute(token.texture, textureChange, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Focuses on structural integrity. Provides a solid complexity boost.
    /// @dev Usable from Journeyman stage onwards. Minimal attribute changes.
    function reinforceStructure(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
        _recordTechniqueUsage(tokenId, 8); // Technique ID 8 for Reinforce Structure
        _updateComplexity(tokenId, 40); // Gain 40 complexity
        // Attributes largely unchanged, focus is on structure (complexity score)
    }

    /// @notice Adds a conceptual inlay of a specific type. Increases complexity and potentially adds a trait.
    /// @dev Usable from Apprentice stage onwards.
    /// @param inlayType A code representing the type of inlay (e.g., 1=Gold, 2=Silver, 3=Gem).
    function addInlay(uint256 tokenId, uint8 inlayType) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Apprentice) {
        _recordTechniqueUsage(tokenId, 9 + inlayType); // Technique IDs 10+ for specific inlays
        _updateComplexity(tokenId, 25 + inlayType * 5); // Higher inlay types add more complexity

        // Could store inlay type specifically if needed, or imply from techniqueUsageCounts
        // For this example, just impacts complexity and general attributes slightly
         TokenData storage token = _getTokenData(tokenId);
         uint8 oldColor = token.color; uint8 oldShape = token.shape;
        token.color = _updateAttribute(token.color, inlayType * 2, 0, 255);
        token.shape = _updateAttribute(token.shape, inlayType, 0, 100);
         emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
    }

    /// @notice Cleans the surface, reducing some surface complexity but potentially preparing for new work.
    /// @dev Usable from Beginner stage onwards.
    function cleanSurface(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Beginner) {
        _recordTechniqueUsage(tokenId, 10); // Technique ID 10 for Clean Surface
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, -10); // Lose 10 complexity

        // Reset texture closer to base material, slightly change color
        uint8 oldTexture = token.texture; uint8 oldColor = token.color;
        token.texture = _updateAttribute(token.texture, (50 - int256(token.texture)) / 2, 0, 100); // Move halfway towards 50
        token.color = _updateAttribute(token.color, int256(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 11) - 5, 0, 255); // Small random color shift
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
    }

     /// @notice Applies a specific aesthetic filter (conceptual style).
    /// @dev Usable from Apprentice stage onwards.
    /// @param filterCode A code representing the filter style (e.g., 1=Sepia, 2=Vivid, etc.).
    function applyAestheticFilter(uint256 tokenId, uint8 filterCode) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Apprentice) {
        _recordTechniqueUsage(tokenId, 11 + filterCode); // Technique IDs 12+ for specific filters
        _updateComplexity(tokenId, 20 + filterCode * 3); // Complexity boost based on filter type

        // Apply filter-specific changes to color and texture
        TokenData storage token = _getTokenData(tokenId);
        uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        int8 colorShift = 0; int8 textureShift = 0;
        if (filterCode == 1) { colorShift = -15; textureShift = 5; } // Sepia-like
        else if (filterCode == 2) { colorShift = 20; textureShift = -5; } // Vivid-like
        else { colorShift = int8(uint256(keccak256(abi.encodePacked(tokenId, block.number, filterCode))) % 31) - 15; } // Other/random

        token.color = _updateAttribute(token.color, colorShift, 0, 255);
        token.texture = _updateAttribute(token.texture, textureShift, 0, 100);
         emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

     /// @notice Attempts to 'burn' or remove flaws, reducing complexity but potentially improving base quality.
    /// @dev Usable from Journeyman stage onwards. Can slightly reduce complexity.
    function burnFlaws(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
        _recordTechniqueUsage(tokenId, 13); // Technique ID 13 for Burn Flaws
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, -5); // Small complexity loss

        // Slightly improve texture and shape towards ideal (e.g., 50 for shape, 20 for texture=smooth)
        uint8 oldShape = token.shape; uint8 oldTexture = token.texture;
        token.shape = _updateAttribute(token.shape, (50 - int256(token.shape)) / 3, 0, 100);
        token.texture = _updateAttribute(token.texture, (20 - int256(token.texture)) / 3, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Applies a rare pigment. Gives a specific color and complexity boost.
    /// @dev Usable from Master stage onwards. Limited conceptual pigment types.
     /// @param pigmentCode A code representing the rare pigment (e.g., 1=Crimson, 2=Azure, etc.).
    function applyRarePigment(uint256 tokenId, uint8 pigmentCode) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Master) {
         // Could add logic here to check if pigmentCode is valid or track limited uses
        _recordTechniqueUsage(tokenId, 14 + pigmentCode); // Technique IDs 15+ for specific pigments
        _updateComplexity(tokenId, 50 + pigmentCode * 10); // Significant complexity gain

        // Apply pigment-specific color change
        TokenData storage token = _getTokenData(tokenId);
        uint8 oldColor = token.color;
        int8 colorChange = 0;
        if (pigmentCode == 1) { colorChange = 80; } // Crimson-like
        else if (pigmentCode == 2) { colorChange = -80; } // Azure-like (lower color index)
        else { colorChange = int8(uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, pigmentCode))) % 61) - 30; } // Other/random

        token.color = _updateAttribute(token.color, colorChange, 0, 255);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
    }

    /// @notice Performs a structural analysis. Represents study and planning, increasing complexity.
    /// @dev Usable from Apprentice stage onwards.
    function performStructuralAnalysis(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Apprentice) {
        _recordTechniqueUsage(tokenId, 17); // Technique ID 17 for Structural Analysis
        _updateComplexity(tokenId, 25); // Gain 25 complexity
        // No attribute changes, focuses on the conceptual 'understanding' (complexity)
    }

    /// @notice Adds a unique, immutable signature to the sculpture. Can only be done once.
    /// @dev Usable only at the Grandmaster stage. Significantly increases complexity.
    /// @param signatureHash A hash representing the signature data (could be IPFS hash of a signature image, or just a unique identifier).
    function addSignature(uint256 tokenId, bytes32 signatureHash) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) onlyStage(tokenId, SculptingStage.Grandmaster) {
        TokenData storage token = _getTokenData(tokenId);
        if (token.signatureAdded) {
            revert SignatureAlreadyAdded(tokenId);
        }

        _recordTechniqueUsage(tokenId, 18); // Technique ID 18 for Add Signature
        _updateComplexity(tokenId, 100); // Significant complexity boost for signing

        token.signatureAdded = true;
        // Could store the signatureHash in the struct if needed, adds state cost.
        // For simplicity, just mark as added. Off-chain metadata can read this status.

        emit SignatureAddedEvent(tokenId, signatureHash);
    }

    /// @notice Etches fine details influenced by the timestamp parity.
    /// @dev Usable from Journeyman stage onwards.
    function etchDetailsByTimestampParity(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
         _recordTechniqueUsage(tokenId, 19); // Technique ID 19 for Etching by Timestamp
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 22); // Gain 22 complexity

        // Change shape and texture based on timestamp parity
        int8 shapeChange = (block.timestamp % 5 == 0) ? 4 : -4; // +-4 based on timestamp % 5
        int8 textureChange = (block.timestamp % 7 == 0) ? 6 : -6; // +-6 based on timestamp % 7

        uint8 oldShape = token.shape; uint8 oldTexture = token.texture;
        token.shape = _updateAttribute(token.shape, shapeChange, 0, 100);
        token.texture = _updateAttribute(token.texture, textureChange, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

     /// @notice Applies a gradient finish. Influences color and texture.
    /// @dev Usable from Master stage onwards.
    function applyGradientFinish(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Master) {
        _recordTechniqueUsage(tokenId, 20); // Technique ID 20 for Gradient Finish
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 35); // Gain 35 complexity

        // Apply gradient-like changes - could depend on complexity or other factors
        uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        int8 colorShift = int8(token.complexityScore / 50 % 41) - 20; // Shift based on complexity
        int8 textureShift = int8(token.complexityScore / 70 % 21) - 10; // Shift based on complexity

        token.color = _updateAttribute(token.color, colorShift, 0, 255);
        token.texture = _updateAttribute(token.texture, textureShift, 0, 100);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Performs a precision cut. Fine-tunes shape and slightly boosts complexity.
    /// @dev Usable from Master stage onwards.
    function performPrecisionCut(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Master) {
        _recordTechniqueUsage(tokenId, 21); // Technique ID 21 for Precision Cut
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, 38); // Gain 38 complexity

        // Fine-tune shape towards center or target
        uint8 oldShape = token.shape;
        token.shape = _updateAttribute(token.shape, (50 - int256(token.shape)) / 4, 0, 100); // Move 1/4 towards 50
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
    }

     /// @notice Adds a conceptual symbolic element to the sculpture.
    /// @dev Usable from Journeyman stage onwards.
    /// @param symbolCode A code representing the symbol type.
    function addSymbol(uint256 tokenId, uint8 symbolCode) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
        _recordTechniqueUsage(tokenId, 22 + symbolCode); // Technique IDs 23+ for symbols
        _updateComplexity(tokenId, 28 + symbolCode * 4); // Complexity based on symbol type

        // Subtle attribute shifts based on symbol
        TokenData storage token = _getTokenData(tokenId);
        uint8 oldShape = token.shape; uint8 oldColor = token.color;
        token.shape = _updateAttribute(token.shape, int8(symbolCode % 7) - 3, 0, 100);
        token.color = _updateAttribute(token.color, int8(symbolCode % 9) - 4, 0, 255);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
    }

    /// @notice Cleanses conceptual 'energies', slightly reducing complexity but potentially improving balance.
    /// @dev Usable from Journeyman stage onwards.
    function cleanseEnergies(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Journeyman) {
         _recordTechniqueUsage(tokenId, 25); // Technique ID 25 for Cleanse Energies
        TokenData storage token = _getTokenData(tokenId);
        _updateComplexity(tokenId, -8); // Lose 8 complexity

        // Move attributes closer to initial state? Or just neutral? Let's move towards 50/128/50
        uint8 oldShape = token.shape; uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        token.shape = _updateAttribute(token.shape, (50 - int256(token.shape)) / 5, 0, 100);
        token.color = _updateAttribute(token.color, (128 - int256(token.color)) / 5, 0, 255);
        token.texture = _updateAttribute(token.texture, (50 - int256(token.texture)) / 5, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);
    }

    /// @notice Re-calculates or reinforces the conceptual complexity score based on current attributes and techniques used.
    /// @dev Usable from Master stage onwards. Provides a variable complexity boost.
    function inspectAndScore(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) minimumStage(tokenId, SculptingStage.Master) {
        _recordTechniqueUsage(tokenId, 26); // Technique ID 26 for Inspect and Score
        TokenData storage token = _getTokenData(tokenId);

        // Calculate boost based on current attributes and stage
        int256 boost = int256(token.shape / 10 + token.color / 20 + token.texture / 10) + int256(uint8(token.sculptingStage)) * 15;
        _updateComplexity(tokenId, boost); // Boost based on state
    }


    // --- Stage Management Functions ---

    /// @notice Advances the sculpture to the next sculpting stage if the complexity threshold is met.
    /// @dev Can only be called by the owner and before finalization.
    function advanceSculptingStage(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) {
        TokenData storage token = _getTokenData(tokenId);
        SculptingStage currentStage = token.sculptingStage;

        // Cannot advance past Grandmaster (Final stage is reached via finalizeSculpture)
        if (currentStage >= SculptingStage.Grandmaster) {
            revert StageNotMax(tokenId, currentStage, SculptingStage.Grandmaster);
        }

        SculptingStage nextStage = SculptingStage(uint8(currentStage) + 1);
        int256 requiredComplexity = stageComplexityThresholds[currentStage];

        if (token.complexityScore < requiredComplexity) {
            revert InsufficientComplexity(tokenId, token.complexityScore, requiredComplexity);
        }

        token.sculptingStage = nextStage;
        emit StageAdvanced(tokenId, currentStage, nextStage, uint64(block.timestamp));

        // Optional: reset some temporary stats or give a small boost upon advancement
        _updateComplexity(tokenId, 50); // Small bonus complexity for advancing
    }

    // --- Finalization Function ---

    /// @notice Finalizes the sculpture, locking its state permanently.
    /// @dev Can only be called by the owner once the Grandmaster stage is reached.
    function finalizeSculpture(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) {
        TokenData storage token = _getTokenData(tokenId);

        if (token.sculptingStage != SculptingStage.Grandmaster) {
            revert InvalidSculptingStage(tokenId, token.sculptingStage, SculptingStage.Grandmaster);
        }

        // Optional: Check for minimum complexity at Grandmaster stage before finalization
        // int256 requiredComplexity = stageComplexityThresholds[SculptingStage.Grandmaster]; // This threshold is for advancing *to* Final, not necessarily for *calling* finalize *from* Grandmaster. Let's use a final threshold check.
        if (token.complexityScore < 2500) { // Example final threshold
             revert InsufficientComplexity(tokenId, token.complexityScore, 2500);
        }


        token.sculptingStage = SculptingStage.Final;
        token.isFinalized = true;
        // _setTokenURI(tokenId, string(abi.encodePacked(_baseTokenURI, "finalized/", Strings.toString(tokenId)))); // Optionally set a specific URI for finalized state

        emit SculptureFinalized(tokenId, uint64(block.timestamp), token.complexityScore);
    }

    // --- Post-Transfer Mechanics ---

     /// @notice Allows the new owner of a sculpture to perform a single conceptual 'refresh' or adjustment after acquiring it.
    /// @dev Can only be called once per token, by the current owner, if not finalized.
    function refreshAfterTransfer(uint256 tokenId) public payable onlyOwnerOfToken(tokenId) notFinalized(tokenId) {
        TokenData storage token = _getTokenData(tokenId);
        if (token.refreshApplied) {
            revert RefreshAlreadyApplied(tokenId);
        }

        _recordTechniqueUsage(tokenId, 99); // Technique ID 99 for Refresh
        _updateComplexity(tokenId, 10); // Small complexity boost for refresh

        // Apply a small adjustment to attributes based on transfer time and token ID
        uint8 oldShape = token.shape; uint8 oldColor = token.color; uint8 oldTexture = token.texture;
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp, msg.sender)));
        token.shape = _updateAttribute(token.shape, int8(seed % 7) - 3, 0, 100);
        token.color = _updateAttribute(token.color, int8(seed % 9) - 4, 0, 255);
        token.texture = _updateAttribute(token.texture, int8(seed % 5) - 2, 0, 100);
        emit AttributeChanged(tokenId, "shape", oldShape, token.shape);
        emit AttributeChanged(tokenId, "color", oldColor, token.color);
        emit AttributeChanged(tokenId, "texture", oldTexture, token.texture);


        token.refreshApplied = true;
        emit RefreshAppliedEvent(tokenId, msg.sender, uint64(block.timestamp));
    }


    // --- Query/View Functions ---

    /// @notice Gets all detailed on-chain data for a sculpture.
    /// @param tokenId The ID of the token to query.
    /// @return A struct containing all token data.
    function getTokenData(uint256 tokenId) public view returns (TokenData memory) {
         require(_exists(tokenId), "CryptoSculptor: Token does not exist");
         // Must read from storage to memory for returning structs
         TokenData storage token = _tokenData[tokenId];
         TokenData memory data;
         data.mintTimestamp = token.mintTimestamp;
         data.lastSculptTimestamp = token.lastSculptTimestamp;
         data.sculptingStage = token.sculptingStage;
         data.baseMaterial = token.baseMaterial;
         data.complexityScore = token.complexityScore;
         data.shape = token.shape;
         data.color = token.color;
         data.texture = token.texture;
         // Note: Mappings cannot be returned directly from memory structs.
         // Use getTechniqueUsageCount for specific technique counts.
         data.isFinalized = token.isFinalized;
         data.refreshApplied = token.refreshApplied;
         data.signatureAdded = token.signatureAdded;
         // Return value doesn't include the mapping techniqueUsageCounts
         return data;
    }

     /// @notice Gets the current sculpting stage of a sculpture.
    function getSculptingStage(uint256 tokenId) public view returns (SculptingStage) {
        return _getTokenData(tokenId).sculptingStage;
    }

    /// @notice Gets the current attributes (shape, color, texture) of a sculpture.
    /// @return shape, color, texture values.
    function getAttributes(uint256 tokenId) public view returns (uint8 shape, uint8 color, uint8 texture) {
        TokenData storage token = _getTokenData(tokenId);
        return (token.shape, token.color, token.texture);
    }

     /// @notice Gets the current complexity score of a sculpture.
    function getComplexityScore(uint256 tokenId) public view returns (int256) {
        return _getTokenData(tokenId).complexityScore;
    }

     /// @notice Gets the usage count for a specific sculpting technique on a sculpture.
     /// @param techniqueId The ID of the technique to query (1=Chisel, etc.).
    function getTechniqueUsageCount(uint256 tokenId, uint8 techniqueId) public view returns (uint256) {
        return _getTokenData(tokenId).techniqueUsageCounts[techniqueId];
    }

    /// @notice Checks if a sculpture has been finalized.
    function isFinalized(uint256 tokenId) public view returns (bool) {
        return _getTokenData(tokenId).isFinalized;
    }

     /// @notice Gets the base material of a sculpture.
    function getBaseMaterial(uint256 tokenId) public view returns (BaseMaterial) {
        return _getTokenData(tokenId).baseMaterial;
    }

     /// @notice Checks if the post-transfer refresh has been applied to a sculpture.
    function getRefreshApplied(uint256 tokenId) public view returns (bool) {
        return _getTokenData(tokenId).refreshApplied;
    }


    // --- Admin/Owner Functions ---

    /// @notice Allows the owner to set the maximum supply of tokens.
    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    /// @notice Allows the owner to set the mint price.
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        MINT_PRICE = _mintPrice;
    }

    /// @notice Allows the owner to set the base URI for token metadata.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

     /// @notice Allows the owner to set the complexity threshold for a specific stage.
     /// @dev Use with caution, affects game balance.
     function setStageComplexityThreshold(SculptingStage stage, int256 threshold) public onlyOwner {
         // Cannot set threshold for the final stage or stages beyond Grandmaster
         require(stage < SculptingStage.Final, "Cannot set threshold for Final stage");
         stageComplexityThresholds[stage] = threshold;
     }

    /// @notice Allows the owner to withdraw the contract balance.
    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // --- End of Contract ---
}
```

---

**Explanation of Concepts & Features:**

1.  **Dynamic State (`TokenData` Struct):** Each NFT doesn't just point to an image; it *is* a data structure on-chain that evolves. Attributes like `shape`, `color`, `texture`, `complexityScore`, and `sculptingStage` are stored and modified directly in the contract storage associated with each `tokenId`.
2.  **Sculpting Stages (`SculptingStage` Enum):** The lifecycle of a sculpture is broken into distinct stages. Advancing requires meeting a `complexityScore` threshold. This gating mechanism introduces progression and unlocks new abilities (techniques available only at higher stages).
3.  **Complexity Score (`complexityScore`):** This is a central mechanic. It acts as a proxy for the 'quality', 'detail', or 'progress' of the sculpture. Different techniques add or subtract from this score. Achieving certain scores is necessary to advance stages.
4.  **Multiple Sculpting Techniques (Numerous `apply...` Functions):** Instead of a single way to interact, many functions are provided, each with a unique name, conceptual action, required stage, and effect on the token's state (`complexityScore`, `shape`, `color`, `texture`). This adds depth and strategy for the owner. Technique IDs are tracked for potential future use (e.g., showing a history or specializing in certain techniques).
5.  **On-Chain Influence:** Some techniques (`applyEtchingTechnique`, `applyPatina`, `applyRandomMutation`, `etchDetailsByTimestampParity`) incorporate `block.timestamp` or `block.number` in their attribute calculations. While this is pseudo-random and front-runnable, it demonstrates using on-chain environmental data to influence outcomes in a deterministic-yet-unpredictable-to-the-user-without-simulation way.
6.  **Finalization (`finalizeSculpture`):** Once a sculpture reaches the `Grandmaster` stage and meets a final threshold, it can be permanently locked in the `Final` stage. This prevents further sculpting and signifies completion.
7.  **Post-Transfer Refresh (`refreshAfterTransfer`):** An interesting concept where the new owner of a non-finalized sculpture gets one chance to apply a small, defining adjustment. This adds a unique interaction upon secondary sale.
8.  **Signature (`addSignature`):** A one-time action at a high stage to conceptually 'sign' the work, adding significant complexity and marking it as signed on-chain.
9.  **Attribute Representation (uint8, int256):** Simplified numerical attributes are used (`shape`, `color`, `texture`) to represent visual properties efficiently on-chain. An off-chain service reading the contract state is expected to interpret these numbers into actual visual traits or metadata.
10. **Standard Compliance & Helpers:** Uses OpenZeppelin libraries (`ERC721Enumerable`, `ERC721URIStorage`, `Ownable`, `Pausable`) for standard, audited functionality and includes custom errors for better gas efficiency and clarity.
11. **Extensibility:** The structure allows for adding more techniques, stages, attributes, or complex interactions in future versions (though this specific contract is not upgradeable).

This contract provides a rich, interactive NFT experience where the NFT is not just a static image or collectible, but a digital asset that the owner actively cultivates and shapes over its lifetime on the blockchain.