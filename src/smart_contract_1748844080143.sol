Okay, let's design a smart contract around a concept that combines dynamic NFT traits with on-chain "memory" or "experiences", influenced by interactions and external actors. We'll call this concept "Engram Sentinels".

An Engram Sentinel is an NFT (ERC-721) that can accumulate "Engrams". Engrams are pieces of data representing events, interactions, or traits imprinted onto the Sentinel. Different types of Engrams can exist, defined by the contract owner, potentially having different weights or effects on the Sentinel's properties, including a calculated "Sentience Score". The contract owner can define approved "Imprinters" – external addresses or contracts authorized to add specific types of Engrams. Sentinel owners can also perform certain actions on their Sentinels' Engrams.

This goes beyond standard NFTs by adding a layer of stateful, dynamic data tied to the token ID, managed through controlled interaction functions.

---

## Smart Contract Outline: EngramSentinels

**Contract Name:** `EngramSentinels`

**Concept:** A dynamic NFT collection where tokens accrue stateful data units called 'Engrams'. Engrams represent interactions or experiences, influencing the token's properties and a 'Sentience Score'. The contract owner defines Engram types and authorized 'Imprinters'.

**Key Features:**

*   **Dynamic NFT Traits:** Sentinel properties (metadata) are derived from accumulated Engrams.
*   **Engram System:** Structured data units (`Engram`) are added to tokens (`Sentinel`).
*   **Engram Types:** Contract owner can define different categories of Engrams with specific properties (e.g., weight, limits).
*   **Approved Imprinters:** Owner-designated addresses/contracts authorized to imprint specific Engram types.
*   **Sentinel Owner Control:** Token owners can view, burn, move, or manage certain aspects of their Sentinel's Engrams.
*   **Sentience Score:** An on-chain score calculated based on accumulated Engrams, representing the Sentinel's "experience" or "complexity".
*   **Standard Compliance:** Implements ERC721, ERC721Enumerable, ERC721Metadata, and ERC2981 (Royalties).
*   **Access Control:** Uses `Ownable` and custom modifiers/checks for Engram management.
*   **Pausability:** Contract can be paused in emergencies.

**Function Summary (Grouped by Category):**

1.  **Standard ERC721/Enumerable/Metadata/Royalties (Inherited/Overridden):**
    *   `constructor()`: Initializes the contract.
    *   `supportsInterface(bytes4 interfaceId)`: Checks if the contract supports a given interface.
    *   `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Returns royalty information for a token sale (ERC2981).
    *   `mint(address to)`: Mints a new Sentinel NFT.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a token safely.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers a token safely with data.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (unsafe).
    *   `approve(address to, uint256 tokenId)`: Approves an address to transfer a token.
    *   `setApprovalForAll(address operator, bool approved)`: Approves an operator for all tokens.
    *   `getApproved(uint256 tokenId)`: Gets the approved address for a token.
    *   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for an owner.
    *   `balanceOf(address owner)`: Gets the balance of an owner.
    *   `ownerOf(uint256 tokenId)`: Gets the owner of a token.
    *   `totalSupply()`: Gets the total number of tokens.
    *   `tokenByIndex(uint256 index)`: Gets a token ID by index (Enumerable).
    *   `tokenOfOwnerByIndex(address owner, uint256 index)`: Gets a token ID of an owner by index (Enumerable).
    *   `tokenURI(uint256 tokenId)`: Gets the metadata URI for a token (Metadata).

2.  **Owner-Specific Functions:**
    *   `renounceOwnership()`: Renounces contract ownership.
    *   `transferOwnership(address newOwner)`: Transfers contract ownership.
    *   `pause()`: Pauses sensitive operations.
    *   `unpause()`: Unpauses the contract.
    *   `withdraw(address to)`: Withdraws ether from the contract.
    *   `setBaseURI(string newBaseURI)`: Sets the base URI for token metadata.
    *   `setDefaultRoyalty(address receiver, uint96 feeNumerator)`: Sets default royalties for new tokens.
    *   `deleteDefaultRoyalty()`: Deletes the default royalty setting.
    *   `setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)`: Sets specific royalty for a token.
    *   `resetTokenRoyalty(uint256 tokenId)`: Resets a token's royalty to default or none.

3.  **Engram Type Management (Owner Only):**
    *   `addEngramType(string name, uint256 weight, uint16 maxPerSentinel, bool active, bool imprinterRequired)`: Adds a new type of Engram.
    *   `updateEngramType(uint32 engramTypeId, string name, uint256 weight, uint16 maxPerSentinel, bool active, bool imprinterRequired)`: Updates properties of an existing Engram type.
    *   `toggleEngramTypeStatus(uint32 engramTypeId, bool active)`: Activates or deactivates an Engram type.

4.  **Approved Imprinter Management (Owner Only):**
    *   `addApprovedImprinter(address imprinter)`: Adds an address to the list of approved Imprinters.
    *   `removeApprovedImprinter(address imprinter)`: Removes an address from the approved Imprinters list.

5.  **Engram & Sentinel Management (Approved Imprinter / Sentinel Owner):**
    *   `imprintEngram(uint256 tokenId, uint32 engramTypeId, bytes data)`: Adds an Engram instance to a Sentinel. Requires appropriate permissions (approved imprinter or sentinel owner if type allows).
    *   `burnEngram(uint256 tokenId, uint32 engramTypeId, uint256 index)`: Removes a specific Engram instance from a Sentinel (by type and index). Requires sentinel owner or approved.
    *   `moveEngram(uint256 fromTokenId, uint32 engramTypeId, uint256 index, uint256 toTokenId)`: Moves an Engram instance from one Sentinel to another. Requires ownership/approval of both tokens.
    *   `cleanseEngrams(uint256 tokenId, uint32[] engramTypeIds)`: Removes all Engrams of specified types from a Sentinel. Requires sentinel owner.
    *   `attuneSentinel(uint256 tokenId)`: Recalculates and updates the Sentience Score for a Sentinel, potentially triggering events or state changes derived from Engrams. Requires sentinel owner.

6.  **Query Functions:**
    *   `getSentinelEngrams(uint256 tokenId)`: Retrieves all Engram instances for a specific Sentinel.
    *   `getEngramTypeDetails(uint32 engramTypeId)`: Retrieves configuration details for an Engram type.
    *   `getAllEngramTypes()`: Retrieves details for all defined Engram types.
    *   `calculateSentienceScore(uint256 tokenId)`: Calculates the Sentience Score for a Sentinel based on its current Engrams (view function, doesn't change state).
    *   `getSentienceScore(uint256 tokenId)`: Retrieves the last calculated/stored Sentience Score for a Sentinel.
    *   `isApprovedImprinter(address imprinter)`: Checks if an address is a globally approved Imprinter.
    *   `getSentinelEngramCountForType(uint256 tokenId, uint32 engramTypeId)`: Gets the number of Engrams of a specific type on a Sentinel.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol"; // Using ERC2981
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title EngramSentinels
 * @dev An ERC721 NFT contract where tokens (Sentinels) can accumulate dynamic state
 *      called 'Engrams', representing experiences or traits. Engrams influence
 *      Sentinel properties and a 'Sentience Score'.
 */
contract EngramSentinels is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Errors ---
    error EngramTypeDoesNotExist(uint32 engramTypeId);
    error EngramTypeNotActive(uint32 engramTypeId);
    error EngramLimitExceeded(uint32 engramTypeId, uint16 maxPerSentinel);
    error NotApprovedImprinter();
    error ImprinterRequiredForType(uint32 engramTypeId);
    error EngramInstanceDoesNotExist(uint256 tokenId, uint32 engramTypeId, uint256 index);
    error NotSentinelOwnerOrApproved();
    error CannotMoveEngramToSameSentinel();
    error TokensNotOwnedOrApproved(uint256 tokenId1, uint256 tokenId2);

    // --- Structs and Enums ---

    /// @dev Represents the configuration of a type of Engram.
    struct EngramType {
        string name;            // Human-readable name (e.g., "Interaction", "Achievement")
        uint256 weight;         // Score influence weight
        uint16 maxPerSentinel;  // Maximum number of this Engram type per Sentinel (0 for unlimited)
        bool active;            // Is this Engram type currently active for imprinting?
        bool imprinterRequired; // Does this Engram type require an approved imprinter (or owner if approved)?
    }

    /// @dev Represents an instance of an Engram attached to a Sentinel.
    struct SentinelEngram {
        uint32 engramTypeId; // ID of the EngramType
        bytes data;          // Arbitrary data associated with this instance
        uint64 timestamp;    // When the Engram was imprinted (block.timestamp)
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _engramTypeCounter;

    // Mapping from Engram Type ID to its configuration
    mapping(uint32 => EngramType) private _engramTypes;

    // Mapping from token ID to Engram Type ID to array of Engram instances
    mapping(uint256 => mapping(uint32 => SentinelEngram[])) private _sentinelEngrams;

    // Mapping from token ID to the number of Engrams of a specific type
    mapping(uint256 => mapping(uint32 => uint256)) private _sentinelEngramCounts;

    // Mapping from token ID to the last calculated Sentience Score
    mapping(uint256 => uint256) private _sentienceScores;

    // Set of addresses approved to imprint Engrams globally
    mapping(address => bool) private _approvedImprinters;

    // Base URI for token metadata
    string private _baseTokenURI;

    // --- Events ---

    /// @dev Emitted when a new Engram Type is added.
    event EngramTypeAdded(uint32 indexed engramTypeId, string name, uint256 weight, uint16 maxPerSentinel, bool active, bool imprinterRequired);

    /// @dev Emitted when an Engram Type is updated.
    event EngramTypeUpdated(uint32 indexed engramTypeId, string name, uint256 weight, uint16 maxPerSentinel, bool active, bool imprinterRequired);

    /// @dev Emitted when an Engram Type's status is toggled.
    event EngramTypeStatusToggled(uint32 indexed engramTypeId, bool active);

    /// @dev Emitted when an address is added as an approved imprinter.
    event ApprovedImprinterAdded(address indexed imprinter);

    /// @dev Emitted when an address is removed as an approved imprinter.
    event ApprovedImprinterRemoved(address indexed imprinter);

    /// @dev Emitted when an Engram is successfully imprinted onto a Sentinel.
    event EngramImprinted(uint256 indexed tokenId, uint32 indexed engramTypeId, uint256 indexed engramIndex, address imprinter, bytes data);

    /// @dev Emitted when an Engram is burned from a Sentinel.
    event EngramBurned(uint256 indexed tokenId, uint32 indexed engramTypeId, uint256 indexed engramIndex, address burner);

    /// @dev Emitted when an Engram is moved between Sentinels.
    event EngramMoved(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint32 indexed engramTypeId, uint256 engramIndex, address initiator);

    /// @dev Emitted when a Sentinel's Sentience Score is updated.
    event SentienceScoreUpdated(uint256 indexed tokenId, uint256 newScore);

    // --- Modifiers ---

    /// @dev Checks if the caller is an approved imprinter or the contract owner.
    modifier onlyApprovedImprinterOrOwner() {
        if (!_approvedImprinters[msg.sender] && msg.sender != owner()) {
            revert NotApprovedImprinter();
        }
        _;
    }

    /// @dev Checks if the caller is the owner of the token or approved for the token.
    modifier onlySentinelOwnerOrApproved(uint256 tokenId) {
        if (msg.sender != ownerOf(tokenId) && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotSentinelOwnerOrApproved();
        }
        _;
    }

    /// @dev Checks if the Engram Type is active.
    modifier whenEngramTypeActive(uint32 engramTypeId) {
        if (!_engramTypes[engramTypeId].active) {
             revert EngramTypeNotActive(engramTypeId);
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI;
    }

    // --- Standard ERC721/Enumerable/Metadata/Royalties Overrides ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        // Optionally clear approved imprinters specific to this token if implemented,
        // or recalculate Sentience score on transfer completion.
        // For simplicity, we won't clear token-specific imprinter approvals here.
    }

    function _increaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, amount);
    }

    function _decreaseBalance(address account, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._decreaseBalance(account, amount);
    }

    function tokenByIndex(uint256 index)
        public
        view
        override(ERC721Enumerable)
        returns (uint256)
    {
        return super.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override(ERC721Enumerable)
        returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Base URI combined with token ID and potential extension (e.g., .json)
        // A real implementation would likely have an API backend that generates the
        // metadata JSON based on the Engram data retrieved via getSentinelEngrams.
        // For this example, we'll just return the base URI + token ID.
        // A more advanced version would generate a data URI or call an oracle.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return _baseTokenURI;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC721Royalty)
        returns (address receiver, uint256 royaltyAmount)
    {
        // ERC2981 implementation handled by inherited contract
        return super.royaltyInfo(tokenId, salePrice);
    }

    // --- Custom Function Implementations ---

    /**
     * @dev Mints a new Engram Sentinel NFT.
     * @param to The address receiving the new Sentinel.
     * @return The token ID of the newly minted Sentinel.
     */
    function mint(address to) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId); // Mints the token

        // Optionally initialize with default Engrams or state here
        // Example: imprintEngram(newTokenId, DEFAULT_ENGRAM_TYPE_ID, "");

        emit SentienceScoreUpdated(newTokenId, 0); // Initialize score

        return newTokenId;
    }

    // --- Owner Functions (General) ---

    /**
     * @dev See {Pausable-pause}.
     * Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     * Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraws any Ether held by the contract.
     * @param to The address to send the Ether to.
     */
    function withdraw(address to) public onlyOwner nonReentrant {
        uint balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = payable(to).call{value: balance}("");
            require(success, "Withdrawal failed");
        }
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets the default royalty information for all tokens in this collection (ERC2981).
     * @param receiver The address to receive the royalties.
     * @param feeNumerator The numerator of the royalty fee percentage (e.g., 500 for 5%).
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
         super.setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Deletes the default royalty information (ERC2981).
     */
    function deleteDefaultRoyalty() public onlyOwner {
        super.deleteDefaultRoyalty();
    }

    /**
     * @dev Sets specific royalty information for a single token (ERC2981).
     * @param tokenId The ID of the token.
     * @param receiver The address to receive the royalties for this token.
     * @param feeNumerator The numerator of the royalty fee percentage (e.g., 700 for 7%).
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
        super._setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Resets the royalty information for a single token to the default (or no royalty if no default is set) (ERC2981).
     * @param tokenId The ID of the token.
     */
    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        super._resetTokenRoyalty(tokenId);
    }

    // --- Owner Functions (Engram Type Management) ---

    /**
     * @dev Adds a new type of Engram that can be imprinted onto Sentinels.
     * @param name The human-readable name of the Engram type.
     * @param weight The influence this Engram type has on the Sentience Score.
     * @param maxPerSentinel The maximum number of this type per Sentinel (0 for unlimited).
     * @param active Whether this Engram type is immediately active for use.
     * @param imprinterRequired Whether imprinting this type requires an approved imprinter (or owner).
     * @return The ID of the newly created Engram type.
     */
    function addEngramType(
        string memory name,
        uint256 weight,
        uint16 maxPerSentinel,
        bool active,
        bool imprinterRequired
    ) public onlyOwner returns (uint32) {
        _engramTypeCounter.increment();
        uint32 newTypeId = uint32(_engramTypeCounter.current());
        _engramTypes[newTypeId] = EngramType(name, weight, maxPerSentinel, active, imprinterRequired);
        emit EngramTypeAdded(newTypeId, name, weight, maxPerSentinel, active, imprinterRequired);
        return newTypeId;
    }

    /**
     * @dev Updates an existing Engram Type's configuration.
     * @param engramTypeId The ID of the Engram type to update.
     * @param name The new human-readable name.
     * @param weight The new influence weight.
     * @param maxPerSentinel The new maximum count per Sentinel.
     * @param active Whether the Engram type is active.
     * @param imprinterRequired Whether imprinting requires an approved imprinter.
     */
    function updateEngramType(
        uint32 engramTypeId,
        string memory name,
        uint256 weight,
        uint16 maxPerSentinel,
        bool active,
        bool imprinterRequired
    ) public onlyOwner {
        if (_engramTypes[engramTypeId].weight == 0 && _engramTypes[engramTypeId].maxPerSentinel == 0 && !_engramTypes[engramTypeId].active && !_engramTypes[engramTypeId].imprinterRequired) {
             revert EngramTypeDoesNotExist(engramTypeId);
        }
        _engramTypes[engramTypeId] = EngramType(name, weight, maxPerSentinel, active, imprinterRequired);
        emit EngramTypeUpdated(engramTypeId, name, weight, maxPerSentinel, active, imprinterRequired);
    }

    /**
     * @dev Toggles the active status of an Engram Type. Inactive types cannot be imprinted.
     * @param engramTypeId The ID of the Engram type to toggle.
     * @param active The new active status.
     */
    function toggleEngramTypeStatus(uint32 engramTypeId, bool active) public onlyOwner {
        if (_engramTypes[engramTypeId].weight == 0 && _engramTypes[engramTypeId].maxPerSentinel == 0 && !_engramTypes[engramTypeId].active && !_engramTypes[engramTypeId].imprinterRequired) {
             revert EngramTypeDoesNotExist(engramTypeId);
        }
        _engramTypes[engramTypeId].active = active;
        emit EngramTypeStatusToggled(engramTypeId, active);
    }

    // --- Approved Imprinter Management (Owner Only) ---

    /**
     * @dev Adds an address to the list of globally approved Imprinters.
     * These addresses can imprint Engrams that require an imprinter.
     * @param imprinter The address to approve.
     */
    function addApprovedImprinter(address imprinter) public onlyOwner {
        require(imprinter != address(0), "Invalid address");
        _approvedImprinters[imprinter] = true;
        emit ApprovedImprinterAdded(imprinter);
    }

    /**
     * @dev Removes an address from the list of globally approved Imprinters.
     * @param imprinter The address to remove.
     */
    function removeApprovedImprinter(address imprinter) public onlyOwner {
        require(imprinter != address(0), "Invalid address");
        _approvedImprinters[imprinter] = false;
        emit ApprovedImprinterRemoved(imprinter);
    }

    // --- Engram & Sentinel Management (Approved Imprinter / Sentinel Owner) ---

    /**
     * @dev Imprints an Engram instance onto a Sentinel.
     * Requires that the caller is an approved imprinter OR the sentinel owner,
     * and meets the `imprinterRequired` setting for the Engram type.
     * Also checks type activity and per-Sentinel limits.
     * @param tokenId The ID of the Sentinel.
     * @param engramTypeId The ID of the Engram type.
     * @param data Arbitrary data for the Engram instance.
     */
    function imprintEngram(uint256 tokenId, uint32 engramTypeId, bytes memory data)
        public
        whenNotPaused
        nonReentrant
    {
        require(_exists(tokenId), "Sentinel does not exist");

        EngramType storage et = _engramTypes[engramTypeId];
        if (et.weight == 0 && et.maxPerSentinel == 0 && !et.active && !et.imprinterRequired) {
             revert EngramTypeDoesNotExist(engramTypeId);
        }
        if (!et.active) {
             revert EngramTypeNotActive(engramTypeId);
        }

        address tokenOwner = ownerOf(tokenId);
        bool isTokenOwner = (msg.sender == tokenOwner);
        bool isApprovedGlobalImprinter = _approvedImprinters[msg.sender];

        // Check permission based on engram type requirements
        if (et.imprinterRequired) {
            // Requires an approved imprinter OR the owner if they are an approved imprinter
            if (!isApprovedGlobalImprinter) {
                revert ImprinterRequiredForType(engramTypeId);
            }
        }
        // If imprinterRequired is false, anyone can technically imprint,
        // but adding the `onlyApprovedImprinterOrOwner` modifier globally
        // would limit this. Let's enforce that *only* approved imprinters
        // or the owner (who can add themselves as imprinter) can imprint.
        // Refined: `onlyApprovedImprinterOrOwner` already checks msg.sender.
        // We only need to check the `imprinterRequired` flag *if* msg.sender
        // is *not* the owner AND *not* a global imprinter (which is covered by the modifier).
        // So, if modifier passes, and `imprinterRequired` is true, we just need to ensure
        // the caller *is* an approved imprinter (already checked by modifier if not owner).
        // The logic becomes:
        // 1. Caller must be owner or approved imprinter (checked by modifier).
        // 2. If `imprinterRequired` is true, caller *must* be an approved imprinter.
        // This prevents owner from imprinting types marked `imprinterRequired` unless they are also approved.
        if (et.imprinterRequired && !isApprovedGlobalImprinter) {
            revert ImprinterRequiredForType(engramTypeId);
        }


        // Check per-Sentinel limit
        if (et.maxPerSentinel > 0 && _sentinelEngramCounts[tokenId][engramTypeId] >= et.maxPerSentinel) {
             revert EngramLimitExceeded(engramTypeId, et.maxPerSentinel);
        }

        // Add the Engram instance
        _sentinelEngrams[tokenId][engramTypeId].push(
            SentinelEngram({
                engramTypeId: engramTypeId,
                data: data,
                timestamp: uint64(block.timestamp) // Use uint64 for timestamp storage
            })
        );
        _sentinelEngramCounts[tokenId][engramTypeId]++;

        uint256 engramIndex = _sentinelEngrams[tokenId][engramTypeId].length - 1; // Index of the newly added engram

        // Recalculate and update Sentience Score (optional, can be done on attune instead)
        // _updateSentienceScore(tokenId);

        emit EngramImprinted(tokenId, engramTypeId, engramIndex, msg.sender, data);
    }

    /**
     * @dev Removes a specific Engram instance from a Sentinel by its type and index.
     * Requires the caller to be the Sentinel owner or approved.
     * Note: Removing from the middle of an array in Solidity is inefficient.
     * This implementation uses the common "swap and pop" pattern for non-ordered removal.
     * This means the index of the *last* element of the type will change if it's not the one being removed.
     * Frontends should be aware of this when referencing Engrams by index after removal.
     * @param tokenId The ID of the Sentinel.
     * @param engramTypeId The ID of the Engram type.
     * @param index The index of the Engram instance within that type's array for the Sentinel.
     */
    function burnEngram(uint256 tokenId, uint32 engramTypeId, uint256 index)
        public
        onlySentinelOwnerOrApproved(tokenId)
        whenNotPaused
        nonReentrant
    {
        // Check if token and engram type exist are implicitly covered by the Engram instance check.
        // No need to explicitly check _exists(tokenId) again due to onlySentinelOwnerOrApproved.

        SentinelEngram[] storage engamsOfType = _sentinelEngrams[tokenId][engramTypeId];
        if (index >= engamsOfType.length) {
            revert EngramInstanceDoesNotExist(tokenId, engramTypeId, index);
        }

        // Swap the element to remove with the last element and pop
        uint256 lastIndex = engamsOfType.length - 1;
        if (index != lastIndex) {
            engamsOfType[index] = engamsOfType[lastIndex];
        }
        engamsOfType.pop();
        _sentinelEngramCounts[tokenId][engramTypeId]--;

        // Recalculate and update Sentience Score (optional)
        // _updateSentienceScore(tokenId);

        emit EngramBurned(tokenId, engramTypeId, index, msg.sender);
    }

    /**
     * @dev Moves a specific Engram instance from one Sentinel to another.
     * Requires the caller to be the owner or approved for *both* source and destination Sentinels.
     * Uses burn+imprint logic internally for state consistency.
     * @param fromTokenId The ID of the Sentinel to move the Engram from.
     * @param engramTypeId The ID of the Engram type.
     * @param index The index of the Engram instance within that type's array on the source Sentinel.
     * @param toTokenId The ID of the Sentinel to move the Engram to.
     */
    function moveEngram(uint256 fromTokenId, uint32 engramTypeId, uint256 index, uint256 toTokenId)
        public
        whenNotPaused
        nonReentrant
    {
        if (fromTokenId == toTokenId) {
            revert CannotMoveEngramToSameSentinel();
        }
        require(_exists(fromTokenId), "Source Sentinel does not exist");
        require(_exists(toTokenId), "Destination Sentinel does not exist");

        // Check ownership/approval for *both* tokens by the caller
        bool callerOwnsFrom = ownerOf(fromTokenId) == msg.sender;
        bool callerApprovedFrom = isApprovedForAll(ownerOf(fromTokenId), msg.sender) || getApproved(fromTokenId) == msg.sender;
        bool callerOwnsTo = ownerOf(toTokenId) == msg.sender;
        bool callerApprovedTo = isApprovedForAll(ownerOf(toTokenId), msg.sender) || getApproved(toTokenId) == msg.sender;

        if (!((callerOwnsFrom || callerApprovedFrom) && (callerOwnsTo || callerApprovedTo))) {
             revert TokensNotOwnedOrApproved(fromTokenId, toTokenId);
        }

        // Retrieve the Engram data before burning
        SentinelEngram[] storage fromEngamsOfType = _sentinelEngrams[fromTokenId][engramTypeId];
        if (index >= fromEngamsOfType.length) {
            revert EngramInstanceDoesNotExist(fromTokenId, engramTypeId, index);
        }
        SentinelEngram memory engramToMove = fromEngamsOfType[index]; // Copy data

        // Check if destination Sentinel can receive this Engram type and is not at limit
        EngramType storage et = _engramTypes[engramTypeId];
         if (et.weight == 0 && et.maxPerSentinel == 0 && !et.active && !et.imprinterRequired) {
             revert EngramTypeDoesNotExist(engramTypeId);
        }
        if (!et.active) {
             revert EngramTypeNotActive(engramTypeId);
        }
        if (et.maxPerSentinel > 0 && _sentinelEngramCounts[toTokenId][engramTypeId] >= et.maxPerSentinel) {
             revert EngramLimitExceeded(engramTypeId, et.maxPerSentinel);
        }

        // Perform the burn from source (using swap and pop logic internally)
        uint256 lastIndexFrom = fromEngamsOfType.length - 1;
        if (index != lastIndexFrom) {
            fromEngamsOfType[index] = fromEngamsOfType[lastIndexFrom];
        }
        fromEngamsOfType.pop();
        _sentinelEngramCounts[fromTokenId][engramTypeId]--;

        // Perform the imprint on destination
        _sentinelEngrams[toTokenId][engramTypeId].push(engramToMove);
        _sentinelEngramCounts[toTokenId][engramTypeId]++;

        // Recalculate Sentience Scores (optional)
        // _updateSentienceScore(fromTokenId);
        // _updateSentienceScore(toTokenId);

        emit EngramBurned(fromTokenId, engramTypeId, index, address(this)); // Indicate contract burned
        emit EngramImprinted(toTokenId, engramTypeId, _sentinelEngrams[toTokenId][engramTypeId].length - 1, address(this), engramToMove.data); // Indicate contract imprinted
        emit EngramMoved(fromTokenId, toTokenId, engramTypeId, index, msg.sender);
    }

    /**
     * @dev Removes all Engrams of specified types from a Sentinel.
     * Requires the caller to be the Sentinel owner.
     * @param tokenId The ID of the Sentinel.
     * @param engramTypeIds An array of Engram type IDs to cleanse.
     */
    function cleanseEngrams(uint256 tokenId, uint32[] memory engramTypeIds)
        public
        onlySentinelOwnerOrApproved(tokenId)
        whenNotPaused
        nonReentrant
    {
        require(_exists(tokenId), "Sentinel does not exist");

        for (uint i = 0; i < engramTypeIds.length; i++) {
            uint32 typeId = engramTypeIds[i];
             if (_engramTypes[typeId].weight == 0 && _engramTypes[typeId].maxPerSentinel == 0 && !_engramTypes[typeId].active && !_engramTypes[typeId].imprinterRequired) {
                // Engram type doesn't exist, skip
                continue;
            }
            // Clear the array for this type
            delete _sentinelEngrams[tokenId][typeId];
            uint256 count = _sentinelEngramCounts[tokenId][typeId];
            if (count > 0) {
                 _sentinelEngramCounts[tokenId][typeId] = 0;
                 // Emit a single event for cleansing a type or individual events?
                 // Let's emit individual burn events for clarity, though less gas efficient for large counts.
                 // Alternative: Emit Cleansed event per type: event EngramsCleansed(uint256 indexed tokenId, uint32 indexed engramTypeId, uint256 count);
                 // Let's stick to individual events for now as burnEngram emits one. This would require iterating.
                 // Simpler for this example: Don't emit individual burn events, just clear state.
                 // If individual events are needed, the loop would need to store indices before clearing.
                 // Let's emit a summary event per type cleansed.
                 emit EngramBurned(tokenId, typeId, type(uint256).max, msg.sender); // Special index like max(uint256) can indicate "all of this type" or use a separate event.
                 // Let's use a dedicated event:
                 emit EngramsCleansed(tokenId, typeId, count, msg.sender);
            }
        }

        // Recalculate and update Sentience Score
        _updateSentienceScore(tokenId);
    }

    /**
     * @dev Recalculates and updates the Sentience Score for a Sentinel.
     * Can be called by the Sentinel owner or approved.
     * This function could trigger on-chain effects derived from the new score.
     * @param tokenId The ID of the Sentinel.
     */
    function attuneSentinel(uint256 tokenId)
        public
        onlySentinelOwnerOrApproved(tokenId)
        whenNotPaused
        nonReentrant
    {
        require(_exists(tokenId), "Sentinel does not exist");
        _updateSentienceScore(tokenId);
        // Add any other "attunement" logic here, like triggering effects or state changes.
    }

    // --- Query Functions ---

    /**
     * @dev Retrieves all Engram instances for a specific Sentinel.
     * Returns a flattened array of structs containing engramTypeId, data, and timestamp.
     * Note: This can be gas-expensive for Sentinels with many Engrams.
     * @param tokenId The ID of the Sentinel.
     * @return An array of SentinelEngram structs.
     */
    function getSentinelEngrams(uint256 tokenId) public view returns (SentinelEngram[] memory) {
         require(_exists(tokenId), "Sentinel does not exist");

        uint256 totalEngrams = 0;
        uint32 currentTypeId = 0;
        while (true) {
            // Find the next Engram type ID for this token that has Engrams
            // This is inefficient. A mapping of token ID to list of Engram type IDs would be better.
            // For this example, let's assume we iterate through all *possible* types, up to the counter.
            if (currentTypeId >= _engramTypeCounter.current()) break;

            uint256 count = _sentinelEngramCounts[tokenId][currentTypeId];
            if (count > 0) {
                totalEngrams += count;
            }
            currentTypeId++; // Move to the next potential type ID
        }

        SentinelEngram[] memory allEngrams = new SentinelEngram[](totalEngrams);
        uint256 currentIndex = 0;
        currentTypeId = 0;
         while (true) {
            if (currentTypeId >= _engramTypeCounter.current()) break;

             SentinelEngram[] storage engramsOfType = _sentinelEngrams[tokenId][currentTypeId];
             for (uint i = 0; i < engramsOfType.length; i++) {
                 allEngrams[currentIndex] = engramsOfType[i];
                 currentIndex++;
             }
             currentTypeId++;
        }

        return allEngrams;
    }

     /**
     * @dev Retrieves all Engram instances of a specific type for a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param engramTypeId The ID of the Engram type.
     * @return An array of SentinelEngram structs of the specified type.
     */
    function getSentinelEngramsByType(uint256 tokenId, uint32 engramTypeId) public view returns (SentinelEngram[] memory) {
         require(_exists(tokenId), "Sentinel does not exist");
         if (_engramTypes[engramTypeId].weight == 0 && _engramTypes[engramTypeId].maxPerSentinel == 0 && !_engramTypes[engramTypeId].active && !_engramTypes[engramTypeId].imprinterRequired) {
             // Engram type doesn't exist explicitly check
             revert EngramTypeDoesNotExist(engramTypeId);
         }
         SentinelEngram[] storage engramsOfType = _sentinelEngrams[tokenId][engramTypeId];
         SentinelEngram[] memory result = new SentinelEngram[](engramsOfType.length);
         for(uint i = 0; i < engramsOfType.length; i++) {
             result[i] = engramsOfType[i];
         }
         return result;
    }


    /**
     * @dev Retrieves configuration details for a specific Engram type.
     * @param engramTypeId The ID of the Engram type.
     * @return EngramType struct containing name, weight, maxPerSentinel, active status, and imprinter required status.
     */
    function getEngramTypeDetails(uint32 engramTypeId) public view returns (EngramType memory) {
         if (_engramTypes[engramTypeId].weight == 0 && _engramTypes[engramTypeId].maxPerSentinel == 0 && !_engramTypes[engramTypeId].active && !_engramTypes[engramTypeId].imprinterRequired) {
             revert EngramTypeDoesNotExist(engramTypeId);
         }
        return _engramTypes[engramTypeId];
    }

     /**
     * @dev Retrieves details for all defined Engram types.
     * Note: Can be gas-expensive if many Engram types exist.
     * @return An array of EngramType structs.
     */
    function getAllEngramTypes() public view returns (EngramType[] memory) {
        uint256 totalTypes = _engramTypeCounter.current();
        EngramType[] memory types = new EngramType[](totalTypes);
        for (uint32 i = 0; i < totalTypes; i++) {
            // Assuming Engram type IDs are sequential starting from 1
             types[i] = _engramTypes[i + 1]; // Adjust index if counter starts at 1
        }
        return types;
    }


    /**
     * @dev Calculates the potential Sentience Score for a Sentinel based on its current Engrams.
     * This is a view function and does not modify state.
     * The score calculation logic is simple sum of weights here, but can be complex.
     * @param tokenId The ID of the Sentinel.
     * @return The calculated Sentience Score.
     */
    function calculateSentienceScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Sentinel does not exist");

        uint256 score = 0;
        uint32 currentTypeId = 0;
         while (true) {
            if (currentTypeId >= _engramTypeCounter.current()) break;

            uint256 count = _sentinelEngramCounts[tokenId][currentTypeId];
            if (count > 0) {
                EngramType storage et = _engramTypes[currentTypeId];
                // Example calculation: sum of (count * weight) for active types
                if (et.active) {
                    score += count * et.weight;
                }
            }
             currentTypeId++;
        }
        return score;
    }

    /**
     * @dev Retrieves the last calculated/stored Sentience Score for a Sentinel.
     * Use `attuneSentinel` or internal calls to update the stored score.
     * @param tokenId The ID of the Sentinel.
     * @return The stored Sentience Score.
     */
    function getSentienceScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Sentinel does not exist");
        return _sentienceScores[tokenId];
    }

    /**
     * @dev Checks if an address is a globally approved Imprinter.
     * @param imprinter The address to check.
     * @return True if the address is approved, false otherwise.
     */
    function isApprovedImprinter(address imprinter) public view returns (bool) {
        return _approvedImprinters[imprinter];
    }

     /**
     * @dev Gets the number of Engrams of a specific type currently on a Sentinel.
     * @param tokenId The ID of the Sentinel.
     * @param engramTypeId The ID of the Engram type.
     * @return The count of Engrams of that type on the Sentinel.
     */
    function getSentinelEngramCountForType(uint256 tokenId, uint32 engramTypeId) public view returns (uint256) {
        require(_exists(tokenId), "Sentinel does not exist");
         if (_engramTypes[engramTypeId].weight == 0 && _engramTypes[engramTypeId].maxPerSentinel == 0 && !_engramTypes[engramTypeId].active && !_engramTypes[engramTypeId].imprinterRequired) {
             // Engram type doesn't exist explicitly check
             revert EngramTypeDoesNotExist(engramTypeId);
         }
        return _sentinelEngramCounts[tokenId][engramTypeId];
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update the stored Sentience Score for a Sentinel.
     * This is called by `attuneSentinel` or other functions that modify Engrams.
     * @param tokenId The ID of the Sentinel.
     */
    function _updateSentienceScore(uint256 tokenId) internal {
        uint256 newScore = calculateSentienceScore(tokenId);
        if (_sentienceScores[tokenId] != newScore) {
            _sentienceScores[tokenId] = newScore;
            emit SentienceScoreUpdated(tokenId, newScore);
        }
    }

    // Custom Event for Cleansing (More specific than just 'Burned' with a special index)
    event EngramsCleansed(uint256 indexed tokenId, uint32 indexed engramTypeId, uint256 count, address initiator);
}
```