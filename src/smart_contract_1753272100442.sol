Here's a Solidity smart contract for an **On-Chain Evolving Attestation NFT** called "ChronicleGlyph". This contract aims to be interesting, advanced, creative, and distinct from common open-source projects by combining several concepts: dynamic on-chain metadata, a decaying reputation system, decentralized attestation via roles, and tiered visual evolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For encoding metadata URI

// Outline and Function Summary:
//
// Contract Name: ChronicleGlyph
//
// Core Concept: ChronicleGlyph is an advanced ERC-721 token designed as a dynamic, evolving attestation for entities (individuals, projects, DAOs). Each Glyph accumulates a verifiable on-chain history ("chronicles") which contribute to a dynamic "reputation score." The Glyph's visual representation (on-chain SVG metadata) and potential utility tiers evolve based on its reputation and accumulated chronicles, making it a living record of an entity's journey and achievements.
//
// Key Features:
// - Dynamic On-Chain Metadata: Token URI generates SVG and JSON metadata directly on-chain, adapting to the Glyph's state based on its chronicles and reputation.
// - Attestation Framework: Allows designated "attester" roles to record specific, predefined "chronicle types" against a Glyph, ensuring verifiable on-chain history.
// - Decaying Reputation System: Each chronicle contributes to a reputation score, which can gradually decay over time if not refreshed by new chronicles, encouraging ongoing engagement.
// - Tiered Evolution: Glyphs evolve through distinct visual tiers, potentially unlocking new attributes or functionalities as their reputation score increases.
// - Modular SVG Layers: SVG generation is modular, combining base designs, chronicle-specific elements, and tier-specific elements to create a unique visual.
//
// Function Summary:
//
// I. Core ERC-721 & Ownership (11 functions):
// 1. constructor(): Initializes the contract with base URI and sets the deployer as the initial admin.
// 2. mintGlyph(address to, string memory initialName): Mints a new ChronicleGlyph NFT to `to` with an initial name. Only callable by the contract admin.
// 3. tokenURI(uint256 tokenId): Returns the dynamic metadata URI for a given token ID, including on-chain generated SVG, reflecting its current state.
// 4. supportsInterface(bytes4 interfaceId): Implements ERC-165 standard for interface discovery.
// 5. balanceOf(address owner): Returns the number of tokens owned by `owner`. (Inherited from ERC721)
// 6. ownerOf(uint256 tokenId): Returns the owner of the `tokenId`. (Inherited from ERC721)
// 7. getApproved(uint256 tokenId): Returns the approved address for the `tokenId`. (Inherited from ERC721)
// 8. setApprovalForAll(address operator, bool approved): Enables/disables an operator to manage all of `msg.sender`'s assets. (Inherited from ERC721)
// 9. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all of `owner`'s assets. (Inherited from ERC721)
// 10. approve(address to, uint256 tokenId): Approves `to` to take ownership of the `tokenId`. (Inherited from ERC721)
// 11. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of `tokenId` from `from` to `to`. (Inherited from ERC721)
//
// II. Chronicle Management & Attestation (6 functions):
// 12. addChronicleType(string memory name, uint256 baseReputation, uint256 decayRateBasisPoints, string memory description): Defines a new type of verifiable event (chronicle), its reputation contribution, decay rate, and a description. Callable only by the admin.
// 13. recordChronicle(uint256 tokenId, uint256 chronicleTypeId, bytes memory eventData): Records an instance of a defined chronicle type for a specific Glyph. Only callable by addresses authorized as attesters for that chronicle type.
// 14. getGlyphChronicles(uint256 tokenId): Retrieves an array of all recorded chronicle indexes for a given Glyph, allowing off-chain querying of its history.
// 15. getChronicleDetails(uint256 chronicleIndex): Retrieves detailed information for a specific chronicle entry by its global index.
// 16. updateChronicleType(uint256 typeId, string memory newName, uint256 newBaseRep, uint256 newDecayRateBasisPoints, string memory newDescription): Admin function to modify parameters of an existing chronicle type.
// 17. toggleChronicleTypeActive(uint256 typeId, bool isActive): Admin function to activate or deactivate a chronicle type, preventing further recording of that type.
//
// III. Reputation System & Tiers (4 functions):
// 18. getCurrentReputation(uint256 tokenId): Calculates and returns the current reputation score for a Glyph, factoring in the decay of its past chronicles. This is a view function that provides the live score.
// 19. getGlyphTier(uint256 tokenId): Determines and returns the current reputation tier details for a Glyph based on its calculated reputation score.
// 20. setReputationTier(uint256 tierId, uint256 minReputation, string memory tierName, string memory svgTemplate): Defines or updates a reputation tier, its minimum reputation threshold, name, and an associated SVG template for visual customization. Callable only by the admin.
// 21. getReputationTierDetails(uint256 tierId): Retrieves details for a specific reputation tier.
//
// IV. Access Control (3 functions):
// 22. grantAttesterRole(address attesterAddress, uint256 chronicleTypeId): Grants `attesterAddress` permission to record a specific chronicle type. Callable only by the admin.
// 23. revokeAttesterRole(address attesterAddress, uint256 chronicleTypeId): Revokes attester permission for a specific chronicle type. Callable only by the admin.
// 24. setAdmin(address newAdmin): Transfers the contract's admin role to a new address. This is a crucial function for decentralized governance transition or admin key management.
//
// V. Configuration & Utilities (3 functions):
// 25. setBaseURI(string memory newBaseURI): Allows updating the base URI for `tokenURI` (e.g., for general off-chain metadata, if applicable). Callable by the admin.
// 26. setTierSVGPrefix(string memory newPrefix): Sets a customizable SVG prefix for tier-specific visual elements, enabling flexible design of Glyph tiers. Callable by the admin.
// 27. setChronicleSVGPrefix(string memory newPrefix): Sets a customizable SVG prefix for chronicle-specific visual elements, allowing design variations based on recorded events. Callable by the admin.

contract ChronicleGlyph is ERC721, Ownable {
    using Strings for uint256;

    // --- Data Structures ---

    /// @dev Stores dynamic data for each individual ChronicleGlyph NFT.
    struct GlyphData {
        string name;                       // The user-assigned name of the Glyph.
        uint256[] chronicleIndexes;        // Array of global indexes pointing to _allChronicles.
    }

    /// @dev Defines a type of chronicle that can be recorded, including its reputation mechanics.
    struct ChronicleType {
        string name;                       // Name of the chronicle type (e.g., "DAO Contributor", "Bug Bounty Winner").
        uint256 baseReputation;            // Base reputation points awarded for this chronicle type.
        uint256 decayRateBasisPoints;      // Decay rate per 365 days, in basis points (e.g., 100 = 1% decay per year). Max 10000 (100%).
        string description;                // A brief description for clarity.
        bool active;                       // Whether this chronicle type can currently be recorded.
    }

    /// @dev Represents a single recorded instance of a chronicle for a Glyph.
    struct Chronicle {
        uint256 chronicleTypeId;           // The ID of the ChronicleType this instance belongs to.
        uint256 tokenId;                   // The ID of the Glyph NFT this chronicle is recorded for.
        uint256 timestamp;                 // The timestamp when the chronicle was recorded.
        bytes eventData;                   // Arbitrary data related to the specific event (e.g., hash of off-chain proof, transaction ID).
    }

    /// @dev Defines a reputation tier, including its visual representation.
    struct ReputationTier {
        string name;                       // Name of the tier (e.g., "Novice", "Expert", "Legend").
        uint256 minReputation;             // Minimum reputation score required to be in this tier.
        string svgTemplate;                // An SVG snippet for this tier's unique visual element. This should be a hex color string or a fragment.
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for minting new Glyphs, starts from 0.
    mapping(uint256 => GlyphData) private _glyphData; // Stores dynamic data for each Glyph NFT.

    mapping(uint256 => ChronicleType) private _chronicleTypes; // Stores definitions of chronicle types.
    uint256 private _nextChronicleTypeId; // Counter for new chronicle type IDs, starts from 1.

    Chronicle[] private _allChronicles; // Stores all recorded chronicle instances globally.

    // Mapping: chronicleTypeId => attesterAddress => hasPermission
    mapping(uint256 => mapping(address => bool)) private _chronicleTypeAttesters; 

    mapping(uint256 => ReputationTier) private _reputationTiers; // Stores definitions of reputation tiers.
    uint256 private _nextTierId; // Counter for new reputation tier IDs, starts from 1.

    string private _baseTokenURI; // Base URI for metadata (e.g., IPFS gateway).
    string private _tierSVGPrefix; // Customizable SVG prefix for tier-specific elements.
    string private _chronicleSVGPrefix; // Customizable SVG prefix for chronicle-specific elements.

    // --- Events ---
    event GlyphMinted(uint256 indexed tokenId, address indexed owner, string name);
    event ChronicleTypeAdded(uint256 indexed typeId, string name, uint256 baseReputation, uint256 decayRate);
    event ChronicleRecorded(uint256 indexed tokenId, uint256 indexed chronicleTypeId, uint256 indexed chronicleIndex, uint256 timestamp);
    event ReputationTierSet(uint256 indexed tierId, string name, uint256 minReputation);
    event AttesterRoleGranted(address indexed attester, uint256 indexed chronicleTypeId);
    event AttesterRoleRevoked(address indexed attester, uint256 indexed chronicleTypeId);

    // --- Constructor ---
    /// @dev Initializes the contract, setting default URI and role.
    constructor() ERC721("ChronicleGlyph", "CGLYPH") Ownable(msg.sender) {
        _baseTokenURI = "ipfs://"; // Default, can be updated by admin.
        // Default SVG prefixes for basic shapes and colors.
        _tierSVGPrefix = "<rect x='0' y='0' width='100%' height='100%' fill='#";
        _chronicleSVGPrefix = "<circle cx='";
        _nextChronicleTypeId = 1; // Start IDs from 1 to avoid conflicts with default 0.
        _nextTierId = 1; // Start IDs from 1.
    }

    // --- I. Core ERC-721 & Ownership ---

    /**
     * @dev Mints a new ChronicleGlyph NFT to the specified address with an initial name.
     *      Only the contract admin can mint new Glyphs.
     * @param to The address to mint the NFT to.
     * @param initialName The initial human-readable name for the Glyph.
     * @return The ID of the newly minted Glyph.
     */
    function mintGlyph(address to, string memory initialName) public onlyOwner returns (uint256) {
        uint256 tokenId = _nextTokenId++; // Assign a new token ID.
        _mint(to, tokenId); // Standard ERC721 minting.
        _glyphData[tokenId].name = initialName; // Store initial Glyph data.
        // Initial reputation is effectively 0 until chronicles are added.

        emit GlyphMinted(tokenId, to, initialName);
        return tokenId;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}. This function dynamically generates the metadata
     *      URI for a given Glyph, including its on-chain SVG representation,
     *      which updates based on its reputation and chronicles.
     * @param tokenId The ID of the Glyph token.
     * @return A data URI containing JSON metadata with an embedded SVG image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId); // ERC721 error for non-existent token.

        uint256 currentRep = getCurrentReputation(tokenId); // Get the live reputation score.
        ReputationTier memory currentTier = getGlyphTier(tokenId); // Determine the current reputation tier.

        string memory svg = _generateFullSVG(tokenId, currentRep, currentTier); // Generate the dynamic SVG.

        // Construct the JSON metadata string.
        string memory json = string.concat(
            '{"name": "', _glyphData[tokenId].name,
            '", "description": "An evolving ChronicleGlyph representing on-chain history and achievements.",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), // Embed SVG as base64 data URI.
            '", "attributes": [',
            '{"trait_type": "Reputation Score", "value": "', currentRep.toString(), '"},',
            '{"trait_type": "Current Tier", "value": "', currentTier.name, '"},',
            '{"trait_type": "Total Chronicles", "value": "', _glyphData[tokenId].chronicleIndexes.length.toString(), '"}'
            // Further attributes could be added here from eventData, or specific chronicle types
            ']}'
        );

        // Return the full metadata URI.
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    /**
     * @dev Internal helper function to construct the full SVG string for a Glyph.
     *      Combines base, tier-specific, and chronicle-specific SVG elements.
     * @param tokenId The ID of the Glyph.
     * @param reputation The current reputation score of the Glyph.
     * @param currentTier The determined current ReputationTier for the Glyph.
     * @return A complete SVG string ready for embedding.
     */
    function _generateFullSVG(uint256 tokenId, uint256 reputation, ReputationTier memory currentTier) internal view returns (string memory) {
        // Base SVG structure: a dark background for contrast.
        string memory svg = string.concat(
            "<svg width='400' height='400' viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg' style='background-color:#0d0d0d;'>",
            "<rect width='100%' height='100%' fill='#1a1a1a'/>" // A slightly lighter base layer.
        );

        // Add tier-specific visual elements based on the current tier's SVG template.
        if (bytes(currentTier.svgTemplate).length > 0) {
            // Assumes svgTemplate is a hex color (e.g., "FFD700") for simple backgrounds.
            svg = string.concat(svg, _tierSVGPrefix, currentTier.svgTemplate, "'/>");
        } else {
            // Fallback for default tier color if no template is provided.
            string memory tierColor = _getTierColor(currentTier.minReputation);
            svg = string.concat(svg, "<rect x='0' y='0' width='100%' height='100%' fill='#", tierColor, "'/>");
        }

        // Add visual elements for each recorded chronicle.
        // This creates a dynamic pattern reflecting the Glyph's history.
        uint256 numChronicles = _glyphData[tokenId].chronicleIndexes.length;
        for (uint252 i = 0; i < numChronicles; i++) {
            Chronicle storage chronicle = _allChronicles[_glyphData[tokenId].chronicleIndexes[i]];
            ChronicleType storage chronicleType = _chronicleTypes[chronicle.chronicleTypeId];

            if (!chronicleType.active) continue; // Skip visual for inactive chronicle types.

            // Simple visual representation: A circle whose size depends on reputation contribution.
            // Position varies based on chronicle index for a scattered effect.
            uint256 effectiveRadius = chronicleType.baseReputation / 20; // Scale radius, max 50 for 1000 rep.
            if (effectiveRadius > 0 && effectiveRadius < 50) { // Limit max radius for visibility.
                string memory xPos = (25 + (i % 5) * 10).toString(); // X position variation.
                string memory yPos = (25 + ((i / 5) % 5) * 10).toString(); // Y position variation.
                svg = string.concat(
                    svg,
                    _chronicleSVGPrefix, xPos, "%' cy='", yPos, "%' r='", effectiveRadius.toString(),
                    "' fill='", _getChronicleColor(chronicle.chronicleTypeId),
                    "' opacity='0.6' stroke='#ffffff' stroke-width='1'/>"
                );
            }
        }

        // Add dynamic text overlays for Glyph name, reputation, and tier.
        svg = string.concat(
            svg,
            "<text x='50%' y='40%' font-family='monospace' font-size='24' fill='white' text-anchor='middle'>",
            _glyphData[tokenId].name,
            "</text>",
            "<text x='50%' y='50%' font-family='monospace' font-size='20' fill='white' text-anchor='middle'>",
            "Reputation: ", reputation.toString(),
            "</text>",
            "<text x='50%' y='60%' font-family='monospace' font-size='18' fill='white' text-anchor='middle'>",
            "Tier: ", currentTier.name,
            "</text>"
        );

        svg = string.concat(svg, "</svg>"); // Close the SVG tag.
        return svg;
    }

    /**
     * @dev Internal helper to determine a simple hex color based on the minimum reputation of a tier.
     *      Provides a default visual progression if custom SVG templates are not used.
     * @param minReputation The minimum reputation score required for the tier.
     * @return A 6-character hex color string (e.g., "FFD700" for gold).
     */
    function _getTierColor(uint256 minReputation) internal pure returns (string memory) {
        if (minReputation >= 1000) return "FFD700"; // Gold
        if (minReputation >= 500) return "C0C0C0"; // Silver
        if (minReputation >= 100) return "CD7F32"; // Bronze
        return "808080"; // Gray (Default for base tier)
    }

    /**
     * @dev Internal helper to determine a simple hex color based on the chronicle type ID.
     *      Allows for visual differentiation of different chronicle types.
     * @param chronicleTypeId The ID of the chronicle type.
     * @return A 6-character hex color string (e.g., "FF0000" for red).
     */
    function _getChronicleColor(uint256 chronicleTypeId) internal pure returns (string memory) {
        // Simple mapping to a few distinct colors.
        if (chronicleTypeId % 5 == 1) return "FF0000"; // Red
        if (chronicleTypeId % 5 == 2) return "00FF00"; // Green
        if (chronicleTypeId % 5 == 3) return "0000FF"; // Blue
        if (chronicleTypeId % 5 == 4) return "FFFF00"; // Yellow
        return "FFFFFF"; // White (Default)
    }

    // ERC-721 standard functions (balanceOf, ownerOf, getApproved, setApprovalForAll, isApprovedForAll, approve, transferFrom)
    // are fully implemented by the inherited OpenZeppelin ERC721 contract.

    // --- II. Chronicle Management & Attestation ---

    /**
     * @dev Adds a new type of chronicle that can be recorded for Glyphs.
     *      Only callable by the contract admin.
     * @param name The unique name of the chronicle type (e.g., "DAO Proposal Passed", "Code Contribution").
     * @param baseReputation The base reputation points awarded when this chronicle type is recorded.
     * @param decayRateBasisPoints The percentage rate at which reputation from this specific chronicle type
     *      decays over a year (365 days), in basis points (e.g., 100 for 1% per year). Max 10000 (100%).
     * @param description A brief explanation of what this chronicle type signifies.
     * @return The ID of the newly created chronicle type.
     */
    function addChronicleType(
        string memory name,
        uint256 baseReputation,
        uint256 decayRateBasisPoints,
        string memory description
    ) public onlyOwner returns (uint256) {
        require(decayRateBasisPoints <= 10000, "Decay rate cannot exceed 10000 basis points (100%)");
        uint256 newTypeId = _nextChronicleTypeId++;
        _chronicleTypes[newTypeId] = ChronicleType({
            name: name,
            baseReputation: baseReputation,
            decayRateBasisPoints: decayRateBasisPoints,
            description: description,
            active: true // New chronicle types are active by default.
        });
        emit ChronicleTypeAdded(newTypeId, name, baseReputation, decayRateBasisPoints);
        return newTypeId;
    }

    /**
     * @dev Records a new chronicle for a specific Glyph. This is the core attestation function.
     *      Only callable by an address that has been granted the attester role for the specified chronicle type.
     * @param tokenId The ID of the Glyph to record the chronicle for.
     * @param chronicleTypeId The ID of the predefined chronicle type.
     * @param eventData Arbitrary bytes data related to the specific event. This can be a hash, a URL, or encoded parameters.
     */
    function recordChronicle(uint256 tokenId, uint256 chronicleTypeId, bytes memory eventData) public {
        require(_exists(tokenId), "Glyph does not exist");
        require(chronicleTypeId > 0 && chronicleTypeId < _nextChronicleTypeId, "Invalid chronicle type ID");
        require(_chronicleTypes[chronicleTypeId].active, "Chronicle type is not active for recording");
        // Ensure msg.sender has permission for THIS specific chronicle type.
        require(
            _chronicleTypeAttesters[chronicleTypeId][msg.sender],
            "Caller not authorized to attest this specific chronicle type"
        );

        // Store the new chronicle globally.
        _allChronicles.push(
            Chronicle({
                chronicleTypeId: chronicleTypeId,
                tokenId: tokenId,
                timestamp: block.timestamp,
                eventData: eventData
            })
        );
        uint256 newChronicleIndex = _allChronicles.length - 1; // Get the global index of the new chronicle.
        _glyphData[tokenId].chronicleIndexes.push(newChronicleIndex); // Associate with the Glyph.

        emit ChronicleRecorded(tokenId, chronicleTypeId, newChronicleIndex, block.timestamp);
    }

    /**
     * @dev Retrieves a list of all global chronicle indexes associated with a specific Glyph.
     *      Allows external systems to query the full history of a Glyph.
     * @param tokenId The ID of the Glyph.
     * @return An array of uint256, where each element is a global index into the `_allChronicles` array.
     */
    function getGlyphChronicles(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Glyph does not exist");
        return _glyphData[tokenId].chronicleIndexes;
    }

    /**
     * @dev Retrieves detailed information for a specific chronicle entry from the global list.
     * @param chronicleIndex The global index of the chronicle to retrieve.
     * @return A tuple containing the chronicleTypeId, tokenId, timestamp, and eventData.
     */
    function getChronicleDetails(uint256 chronicleIndex)
        public
        view
        returns (
            uint256 chronicleTypeId,
            uint256 tokenId,
            uint256 timestamp,
            bytes memory eventData
        )
    {
        require(chronicleIndex < _allChronicles.length, "Invalid chronicle index");
        Chronicle storage c = _allChronicles[chronicleIndex];
        return (c.chronicleTypeId, c.tokenId, c.timestamp, c.eventData);
    }

    /**
     * @dev Updates parameters of an existing chronicle type.
     *      Only callable by the contract admin.
     * @param typeId The ID of the chronicle type to update.
     * @param newName The new name for the chronicle type.
     * @param newBaseRep The new base reputation value.
     * @param newDecayRateBasisPoints The new decay rate (in basis points per year).
     * @param newDescription The new description for the chronicle type.
     */
    function updateChronicleType(
        uint256 typeId,
        string memory newName,
        uint256 newBaseRep,
        uint256 newDecayRateBasisPoints,
        string memory newDescription
    ) public onlyOwner {
        require(typeId > 0 && typeId < _nextChronicleTypeId, "Invalid chronicle type ID");
        require(newDecayRateBasisPoints <= 10000, "Decay rate cannot exceed 10000 basis points (100%)");
        // No explicit check for 'active' state, as inactive types can still be updated.

        ChronicleType storage ct = _chronicleTypes[typeId];
        ct.name = newName;
        ct.baseReputation = newBaseRep;
        ct.decayRateBasisPoints = newDecayRateBasisPoints;
        ct.description = newDescription;
    }

    /**
     * @dev Activates or deactivates a chronicle type. Deactivated types cannot be recorded.
     *      Only callable by the contract admin.
     * @param typeId The ID of the chronicle type to toggle.
     * @param isActive True to activate, false to deactivate.
     */
    function toggleChronicleTypeActive(uint256 typeId, bool isActive) public onlyOwner {
        require(typeId > 0 && typeId < _nextChronicleTypeId, "Invalid chronicle type ID");
        _chronicleTypes[typeId].active = isActive;
    }

    // --- III. Reputation System & Tiers ---

    /**
     * @dev Calculates and returns the current reputation score for a Glyph.
     *      This function accounts for the decay of each individual chronicle based on its
     *      type's decay rate and the time elapsed since it was recorded.
     * @param tokenId The ID of the Glyph.
     * @return The current calculated reputation score for the Glyph.
     */
    function getCurrentReputation(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Glyph does not exist");

        uint256 totalReputation = 0;
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i < _glyphData[tokenId].chronicleIndexes.length; i++) {
            Chronicle storage chronicle = _allChronicles[_glyphData[tokenId].chronicleIndexes[i]];
            // Retrieve chronicle type details. Note: If chronicle type was deleted, this would revert or use default values.
            // For robustness, ensure chronicle types cannot be deleted, only deactivated.
            ChronicleType storage chronicleType = _chronicleTypes[chronicle.chronicleTypeId];

            // If the chronicle type itself is inactive, its reputation might not count towards live score
            // This is a design choice; currently, active status only prevents *new* recordings.
            // If (!chronicleType.active) continue; // Uncomment this line if you want inactive chronicle types to contribute 0 reputation

            uint256 timeElapsed = currentTime - chronicle.timestamp;
            // Calculate decay: (baseRep * decayRate * timeElapsed) / (10000 * 365 days in seconds)
            // This models linear decay, where `decayRateBasisPoints` is the percentage lost over 365 days.
            uint252 decayAmount = (chronicleType.baseReputation * chronicleType.decayRateBasisPoints * timeElapsed) / (10000 * 365 days);
            
            // Ensure reputation from a single chronicle doesn't go below zero.
            uint252 effectiveRep = chronicleType.baseReputation > decayAmount ? chronicleType.baseReputation - decayAmount : 0;
            totalReputation += effectiveRep;
        }

        return totalReputation;
    }

    /**
     * @dev Determines and returns the current reputation tier details for a given Glyph.
     *      It iterates through all defined tiers and finds the highest tier whose minimum
     *      reputation threshold is met by the Glyph's current reputation.
     * @param tokenId The ID of the Glyph.
     * @return A `ReputationTier` struct containing the tier's name, minimum reputation, and SVG template.
     */
    function getGlyphTier(uint256 tokenId) public view returns (ReputationTier memory) {
        uint256 currentRep = getCurrentReputation(tokenId);
        // Initialize with a default "Novice" tier.
        ReputationTier memory bestTier = ReputationTier({name: "Novice", minReputation: 0, svgTemplate: "808080"}); 

        // Iterate through all defined tiers to find the highest applicable tier.
        for (uint256 i = 1; i < _nextTierId; i++) {
            ReputationTier storage tier = _reputationTiers[i];
            if (currentRep >= tier.minReputation && tier.minReputation >= bestTier.minReputation) {
                // If current reputation meets or exceeds this tier's minimum, and this tier's minimum
                // is higher than the current best tier's minimum, then this is the new best tier.
                bestTier = tier; 
            }
        }
        return bestTier;
    }

    /**
     * @dev Defines or updates a reputation tier. Only callable by the contract admin.
     *      Allows setting custom thresholds and associated SVG elements for different tiers.
     * @param tierId The ID for this tier. If 0, a new unique ID will be assigned.
     * @param minReputation The minimum reputation score required to qualify for this tier.
     * @param tierName The human-readable name of the tier (e.g., "Silver", "Gold").
     * @param svgTemplate An SVG snippet or hex color string specifically for this tier's visual representation.
     */
    function setReputationTier(
        uint256 tierId,
        uint256 minReputation,
        string memory tierName,
        string memory svgTemplate
    ) public onlyOwner {
        uint256 actualTierId = tierId;
        if (tierId == 0) { // If 0 is passed, assign a new tier ID.
            actualTierId = _nextTierId++;
        } else {
            // If a non-zero tierId is passed, it must be an existing tier to update.
            require(tierId > 0 && tierId < _nextTierId, "Tier ID out of bounds for existing tiers");
        }

        _reputationTiers[actualTierId] = ReputationTier({
            name: tierName,
            minReputation: minReputation,
            svgTemplate: svgTemplate
        });
        emit ReputationTierSet(actualTierId, tierName, minReputation);
    }

    /**
     * @dev Retrieves details for a specific reputation tier by its ID.
     * @param tierId The ID of the tier.
     * @return A tuple containing the tier's name, minimum reputation, and SVG template.
     */
    function getReputationTierDetails(uint256 tierId)
        public
        view
        returns (
            string memory tierName,
            uint256 minReputation,
            string memory svgTemplate
        )
    {
        require(tierId > 0 && tierId < _nextTierId, "Invalid tier ID");
        ReputationTier storage tier = _reputationTiers[tierId];
        return (tier.name, tier.minReputation, tier.svgTemplate);
    }

    // --- IV. Access Control ---

    /**
     * @dev Grants a specific address the role to record chronicles of a given type.
     *      This provides granular control over who can attest to what types of events.
     *      Only callable by the contract admin.
     * @param attesterAddress The address to grant the role to.
     * @param chronicleTypeId The ID of the chronicle type this address will be authorized to attest.
     */
    function grantAttesterRole(address attesterAddress, uint256 chronicleTypeId) public onlyOwner {
        require(chronicleTypeId > 0 && chronicleTypeId < _nextChronicleTypeId, "Invalid chronicle type ID");
        _chronicleTypeAttesters[chronicleTypeId][attesterAddress] = true;
        emit AttesterRoleGranted(attesterAddress, chronicleTypeId);
    }

    /**
     * @dev Revokes an address's permission to record a specific chronicle type.
     *      Only callable by the contract admin.
     * @param attesterAddress The address to revoke the role from.
     * @param chronicleTypeId The ID of the chronicle type this address can no longer attest.
     */
    function revokeAttesterRole(address attesterAddress, uint256 chronicleTypeId) public onlyOwner {
        require(chronicleTypeId > 0 && chronicleTypeId < _nextChronicleTypeId, "Invalid chronicle type ID");
        _chronicleTypeAttesters[chronicleTypeId][attesterAddress] = false;
        emit AttesterRoleRevoked(attesterAddress, chronicleTypeId);
    }

    /**
     * @dev Transfers the contract's admin (owner) role to a new address.
     *      This is a critical function, usually guarded by multi-sig or DAO governance in production.
     *      Only callable by the current admin.
     * @param newAdmin The address of the new admin.
     */
    function setAdmin(address newAdmin) public onlyOwner {
        transferOwnership(newAdmin); // Utilizes Ownable's transferOwnership.
    }

    // --- V. Configuration & Utilities ---

    /**
     * @dev Sets the base URI for the token metadata. This could be used for general
     *      off-chain images or other metadata components if not everything is on-chain.
     *      Only callable by the contract admin.
     * @param newBaseURI The new base URI string (e.g., "https://myproject.xyz/api/").
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets the SVG prefix string used when generating tier-specific visual elements.
     *      This allows for flexibility in how tiers are visually rendered within the SVG.
     *      Only callable by the contract admin.
     * @param newPrefix The new SVG prefix (e.g., "<rect x='0' y='0' width='100%' height='100%' fill='#").
     */
    function setTierSVGPrefix(string memory newPrefix) public onlyOwner {
        _tierSVGPrefix = newPrefix;
    }

    /**
     * @dev Sets the SVG prefix string used when generating chronicle-specific visual elements.
     *      This enables different visual styles for recorded chronicles.
     *      Only callable by the contract admin.
     * @param newPrefix The new SVG prefix (e.g., "<circle cx='").
     */
    function setChronicleSVGPrefix(string memory newPrefix) public onlyOwner {
        _chronicleSVGPrefix = newPrefix;
    }
}
```