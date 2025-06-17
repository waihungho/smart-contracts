Okay, this is a fun challenge! Let's design a smart contract that represents a "Digital Soulbound Gallery". This gallery is tied to a specific soul (address), is non-transferable (soulbound), and allows the soul to curate and display NFTs they own from *any* ERC721 contract. It also incorporates features like on-chain gallery features, interactions (visits, reactions), events, and issuing achievements (also soulbound) based on gallery activities.

This design is complex because:
1.  It acts as a modified ERC721 (for the gallery token itself) preventing transfer.
2.  It manages state about external ERC721 tokens being displayed.
3.  It manages state for interactions (visits, reactions).
4.  It incorporates an on-chain event system tied to galleries.
5.  It acts as an achievement issuer for soulbound tokens based on gallery activity.
6.  It allows for dynamic on-chain features for the gallery appearance/state.

**Outline and Function Summary**

**Contract Name:** `DigitalSoulboundGallery`

**Purpose:** A non-transferable digital gallery tied to a single address ("Soul"). Allows Souls to curate and display NFTs they own, host events, track interactions, and earn/issue soulbound achievements within the gallery ecosystem.

**Key Concepts:**
*   **Soulbound Gallery Token:** A unique, non-transferable ERC721 token representing a user's gallery space.
*   **Curated NFTs:** The ability to list external ERC721 tokens the user owns to be displayed in their gallery (metadata/display handled off-chain).
*   **Gallery Features:** On-chain key-value pairs allowing Souls to customize aspects of their gallery (interpreted off-chain).
*   **Interactions:** On-chain tracking of gallery visits and reactions.
*   **Events:** Souls can host on-chain events within their gallery.
*   **Achievements:** Soulbound tokens issued by the contract for participating in gallery activities.

**Function Summary:**

**I. Gallery Management (Soulbound ERC721)**
1.  `claimGallery()`: Allows a user to claim their unique Soulbound Gallery Token (requires fee).
2.  `isGalleryOwner(address _soul)`: Checks if an address owns a gallery token.
3.  `getGalleryTokenId(address _soul)`: Gets the unique token ID for a soul's gallery.
4.  `getGalleryOwner(uint256 _tokenId)`: Gets the soul (owner) of a gallery token (Standard ERC721, but token ID maps directly to the claiming address).
5.  `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a gallery token (Standard ERC721).

**II. Curated NFT Management**
6.  `addDisplayedNFT(uint256 _galleryTokenId, address _nftContract, uint256 _nftTokenId)`: Adds an NFT from another contract to the gallery's display list (requires gallery ownership).
7.  `removeDisplayedNFT(uint256 _galleryTokenId, address _nftContract, uint256 _nftTokenId)`: Removes a specific NFT from the display list (requires gallery ownership).
8.  `getDisplayedNFTs(uint256 _galleryTokenId)`: Retrieves the list of NFTs currently marked for display in a gallery.
9.  `reorderDisplayedNFTs(uint256 _galleryTokenId, (address, uint256)[] memory _newOrder)`: Reorders the list of displayed NFTs (requires gallery ownership).
10. `clearDisplayedNFTs(uint256 _galleryTokenId)`: Removes all NFTs from the display list (requires gallery ownership).

**III. Gallery Features**
11. `updateGalleryFeature(uint256 _galleryTokenId, bytes32 _featureKey, bytes memory _featureValue)`: Sets or updates a specific on-chain feature for the gallery (requires gallery ownership).
12. `getGalleryFeature(uint256 _galleryTokenId, bytes32 _featureKey)`: Retrieves the value of a specific gallery feature.
13. `getGalleryFeatures(uint256 _galleryTokenId)`: Retrieves all key-value features for a gallery.
14. `setFeatureVisibility(uint256 _galleryTokenId, bytes32 _featureKey, bool _isPublic)`: Sets whether a specific feature is publicly visible (requires gallery ownership).

**IV. Interactions (Visits & Reactions)**
15. `visitGallery(uint256 _galleryTokenId)`: Records a visit to a gallery (increments visitor count).
16. `getVisitorCount(uint256 _galleryTokenId)`: Gets the total number of visits for a gallery.
17. `leaveReaction(uint256 _galleryTokenId, uint256 _reactionType)`: Records a specific type of reaction to a gallery.
18. `getReactionCounts(uint256 _galleryTokenId)`: Gets the counts for all reaction types on a gallery.

**V. Events**
19. `hostEvent(uint256 _galleryTokenId, bytes32 _eventId, uint256 _startTime, uint256 _endTime, string memory _eventUri)`: Registers an on-chain event hosted at a gallery (requires gallery ownership).
20. `getGalleryEvents(uint256 _galleryTokenId)`: Lists the IDs of events hosted by a specific gallery.
21. `getEventDetails(bytes32 _eventId)`: Gets the details of a specific event.
22. `registerForEvent(bytes32 _eventId)`: Allows a user to register their attendance for an event.
23. `getEventAttendees(bytes32 _eventId)`: Lists the addresses registered for an event.
24. `checkEventAttendance(bytes32 _eventId, address _soul)`: Checks if a specific soul is registered for an event.

**VI. Achievements (Soulbound Issuer)**
25. `defineAchievement(uint256 _achievementId, string memory _uri)`: Admin function to define the metadata for an achievement ID.
26. `issueGalleryAchievementSBT(address _soul, uint256 _achievementId)`: Admin function to issue a specific achievement SBT to a soul.
27. `getAchievementSBTs(address _soul)`: Retrieves the list of achievement SBT IDs owned by a soul.
28. `hasAchievementSBT(address _soul, uint256 _achievementId)`: Checks if a soul possesses a specific achievement SBT.

**VII. Admin & Platform**
29. `setGalleryClaimFee(uint256 _fee)`: Admin sets the fee required to claim a gallery.
30. `withdrawFees()`: Admin withdraws collected claim fees.
31. `pauseContract()`: Admin pauses the contract (inhibits most interactions).
32. `unpauseContract()`: Admin unpauses the contract.

*(Note: Standard ERC721 functions like `balanceOf`, `ownerOf`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` will be present, but the transfer/approval functions will be overridden to revert for the soulbound gallery tokens).*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Outline and Function Summary provided above the code.

/// @title DigitalSoulboundGallery
/// @dev Represents a non-transferable digital gallery tied to a single address ("Soul").
/// Allows Souls to curate and display NFTs they own, host events, track interactions,
/// and earn/issue soulbound achievements within the gallery ecosystem.
contract DigitalSoulboundGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- State Variables ---

    // Maps Soul address to their unique Gallery Token ID
    mapping(address => uint256) private _soulToGalleryTokenId;
    // Reverse mapping for standard ERC721 ownerOf
    mapping(uint256 => address) private _galleryTokenIdToSoul; // Redundant with ERC721 _owners, but explicit

    Counters.Counter private _galleryTokenIds;

    // Maps Gallery Token ID to list of NFTs to display (Contract Address, Token ID)
    mapping(uint256 => (address, uint256)[]) private _displayedNFTs;

    // Maps Gallery Token ID to dynamic on-chain features (key => value)
    mapping(uint256 => mapping(bytes32 => bytes)) private _galleryFeatures;
    // Maps Gallery Token ID to feature visibility (key => isPublic)
    mapping(uint256 => mapping(bytes32 => bool)) private _galleryFeatureVisibility;

    // Maps Gallery Token ID to visitor count
    mapping(uint256 => uint256) private _visitorCount;
    // Maps Gallery Token ID to reaction type counts
    mapping(uint256 => mapping(uint256 => uint256)) private _reactionCounts; // reactionType 0, 1, 2...

    // Event structure
    struct GalleryEvent {
        bytes32 eventId;
        uint256 galleryTokenId;
        uint256 startTime;
        uint256 endTime;
        string eventUri; // Metadata URI for the event
        address host; // Host address (redundant but useful)
    }
    // Maps Event ID to Event details
    mapping(bytes32 => GalleryEvent) private _events;
    // Maps Gallery Token ID to list of hosted Event IDs
    mapping(uint256 => bytes32[]) private _hostedEventIds;
    // Maps Event ID to list of attendee addresses
    mapping(bytes32 => address[]) private _eventAttendees;
    // Maps Event ID to attendee registration status
    mapping(bytes32 => mapping(address => bool)) private _isAttendee;

    // Maps Achievement ID to its metadata URI
    mapping(uint256 => string) private _achievementURIs;
    // Maps Soul address to list of Achievement IDs they possess
    mapping(address => uint256[]) private _soulAchievements;
    // Maps Soul address and Achievement ID to check possession
    mapping(address => mapping(uint256 => bool)) private _hasAchievement;

    // Fee to claim a gallery
    uint256 public galleryClaimFee;

    // --- Events ---

    event GalleryClaimed(address indexed soul, uint256 indexed tokenId);
    event NFTDisplayed(uint256 indexed galleryTokenId, address indexed nftContract, uint256 indexed nftTokenId);
    event NFTRemoved(uint256 indexed galleryTokenId, address indexed nftContract, uint256 indexed nftTokenId);
    event AchievementDefined(uint256 indexed achievementId, string uri);
    event AchievementIssued(address indexed soul, uint256 indexed achievementId);
    event GalleryVisited(uint256 indexed galleryTokenId, address visitor);
    event ReactionLeft(uint256 indexed galleryTokenId, address reactor, uint256 reactionType);
    event EventHosted(bytes32 indexed eventId, uint256 indexed galleryTokenId, address indexed host, uint256 startTime, uint256 endTime);
    event EventRegistered(bytes32 indexed eventId, address indexed attendee);
    event GalleryFeatureUpdated(uint256 indexed galleryTokenId, bytes32 indexed featureKey, bytes featureValue);
    event GalleryFeatureVisibilityUpdated(uint256 indexed galleryTokenId, bytes32 indexed featureKey, bool isPublic);
    event FeeWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyGalleryOwner(uint256 _tokenId) {
        require(_galleryTokenIdToSoul[_tokenId] == _msgSender(), "Not gallery owner");
        _;
    }

    modifier onlySoul(address _soul) {
        require(_soul == _msgSender(), "Not the designated soul");
        _;
    }

    modifier galleryExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Gallery does not exist");
        _;
    }

     modifier eventExists(bytes32 _eventId) {
        require(_events[_eventId].galleryTokenId != 0 || _events[_eventId].host != address(0), "Event does not exist");
        // Assuming galleryTokenId 0 is never minted, or host != address(0) check handles it
        _;
    }


    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(_msgSender()) {}

    // --- Overrides to enforce Soulbound ---
    // Note: Standard ERC721 functions like ownerOf, balanceOf, tokenURI work as expected,
    // but transfer/approval related functions are disabled.

    /// @dev Prevents all transfers of the Soulbound Gallery Token.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfers if both from and to are valid addresses (i.e., not minting or burning to zero address)
        if (from != address(0) && to != address(0)) {
            revert("Soulbound: Gallery token is non-transferable");
        }
    }

    // Explicitly override transfer functions to ensure they revert.
    // _beforeTokenTransfer handles the core logic, but explicit overrides are clearer.

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        revert("Soulbound: Gallery token is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        revert("Soulbound: Gallery token is non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        revert("Soulbound: Gallery token is non-transferable");
    }

    function approve(address to, uint256 tokenId) public payable override {
        revert("Soulbound: Gallery token cannot be approved for transfer");
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert("Soulbound: Gallery token cannot be approved for transfer");
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        // Return zero address to indicate no approval is possible
        return address(0);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Always false as approval is not possible
        return false;
    }

    // --- I. Gallery Management ---

    /// @dev Allows a user to claim their unique Soulbound Gallery Token.
    /// Requires payment of galleryClaimFee.
    function claimGallery() external payable whenNotPaused {
        require(_soulToGalleryTokenId[_msgSender()] == 0, "Soul already has a gallery");
        require(msg.value >= galleryClaimFee, "Insufficient fee");

        _galleryTokenIds.increment();
        uint256 newTokenId = _galleryTokenIds.current();

        _safeMint(_msgSender(), newTokenId);
        _soulToGalleryTokenId[_msgSender()] = newTokenId;
        _galleryTokenIdToSoul[newTokenId] = _msgSender(); // Store soul for lookup

        emit GalleryClaimed(_msgSender(), newTokenId);
    }

    /// @dev Checks if an address owns a gallery token.
    /// @param _soul The address to check.
    /// @return bool True if the address owns a gallery, false otherwise.
    function isGalleryOwner(address _soul) public view returns (bool) {
        return _soulToGalleryTokenId[_soul] != 0;
    }

    /// @dev Gets the unique token ID for a soul's gallery.
    /// @param _soul The address of the soul.
    /// @return uint256 The gallery token ID, or 0 if no gallery is owned.
    function getGalleryTokenId(address _soul) public view returns (uint256) {
        return _soulToGalleryTokenId[_soul];
    }

    /// @dev Gets the soul (owner) of a gallery token.
    /// Standard ERC721 ownerOf, but explicitly maps tokenId to soul.
    /// @param _tokenId The gallery token ID.
    /// @return address The soul who owns the gallery.
    function getGalleryOwner(uint256 _tokenId) public view galleryExists(_tokenId) returns (address) {
        // ERC721 ownerOf also works, this is for clarity/consistency with soul mapping
        return _galleryTokenIdToSoul[_tokenId];
    }

    // --- II. Curated NFT Management ---

    /// @dev Adds an NFT from another contract to the gallery's display list.
    /// Off-chain services should verify ownership before proposing this transaction.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _nftContract The address of the external ERC721 contract.
    /// @param _nftTokenId The token ID of the NFT to display.
    function addDisplayedNFT(uint256 _galleryTokenId, address _nftContract, uint256 _nftTokenId)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        // Basic check: require the contract is not zero address
        require(_nftContract != address(0), "Invalid NFT contract address");

        // Note: On-chain verification of ownership of the external NFT is expensive
        // and often handled off-chain. The contract just records the intent to display.
        // ERC721(_nftContract).ownerOf(_nftTokenId) == msg.sender is possible but costly.

        _displayedNFTs[_galleryTokenId].push( 능력: (_nftContract, _nftTokenId)); // Using a tuple

        emit NFTDisplayed(_galleryTokenId, _nftContract, _nftTokenId);
    }

    /// @dev Removes a specific NFT from the display list.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _nftContract The address of the external ERC721 contract.
    /// @param _nftTokenId The token ID of the NFT to remove.
    function removeDisplayedNFT(uint256 _galleryTokenId, address _nftContract, uint256 _nftTokenId)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        (address[] memory contracts, uint256[] memory tokenIds) = getDisplayedNFTs(_galleryTokenId);
        uint256 indexToRemove = type(uint256).max; // Sentinel value

        for (uint256 i = 0; i < contracts.length; i++) {
            if (contracts[i] == _nftContract && tokenIds[i] == _nftTokenId) {
                indexToRemove = i;
                break;
            }
        }

        require(indexToRemove != type(uint256).max, "NFT not found in displayed list");

        // Swap with last element and pop
        uint256 lastIndex = _displayedNFTs[_galleryTokenId].length - 1;
        if (indexToRemove != lastIndex) {
            _displayedNFTs[_galleryTokenId][indexToRemove] = _displayedNFTs[_galleryTokenId][lastIndex];
        }
        _displayedNFTs[_galleryTokenId].pop();

        emit NFTRemoved(_galleryTokenId, _nftContract, _nftTokenId);
    }

    /// @dev Retrieves the list of NFTs currently marked for display in a gallery.
    /// @param _galleryTokenId The ID of the gallery.
    /// @return address[] An array of NFT contract addresses.
    /// @return uint256[] An array of NFT token IDs.
    function getDisplayedNFTs(uint256 _galleryTokenId)
        public
        view
        galleryExists(_galleryTokenId)
        returns (address[] memory, uint256[] memory)
    {
        uint256 count = _displayedNFTs[_galleryTokenId].length;
        address[] memory contracts = new address[](count);
        uint256[] memory tokenIds = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            (address contractAddr, uint256 tokenId) = _displayedNFTs[_galleryTokenId][i];
            contracts[i] = contractAddr;
            tokenIds[i] = tokenId;
        }

        return (contracts, tokenIds);
    }

    /// @dev Reorders the list of displayed NFTs.
    /// The input array must contain all currently displayed NFTs for that gallery.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _newOrder An array of (contract address, token ID) tuples in the desired order.
    function reorderDisplayedNFTs(uint256 _galleryTokenId, (address, uint256)[] memory _newOrder)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        // Basic validation: Check if the length matches
        require(_newOrder.length == _displayedNFTs[_galleryTokenId].length, "New order length mismatch");

        // More robust validation (optional due to gas cost):
        // Check if _newOrder contains exactly the same set of NFTs as _displayedNFTs[_galleryTokenId]
        // This would require iterating and matching, which is expensive.
        // Trusting the front-end/caller to provide valid reordering is often necessary.

        // Replace the current displayed NFTs list with the new order
        _displayedNFTs[_galleryTokenId] = _newOrder;

        // No specific event for reorder, addDisplayedNFT/NFTRemoved cover items added/removed
    }

    /// @dev Removes all NFTs from the display list.
    /// @param _galleryTokenId The ID of the gallery.
    function clearDisplayedNFTs(uint256 _galleryTokenId)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        delete _displayedNFTs[_galleryTokenId];
        // Consider emitting events for each removed NFT if detailed logging is needed,
        // but that can be expensive.
    }

    // --- III. Gallery Features ---

    /// @dev Sets or updates a specific on-chain feature for the gallery.
    /// Features are stored as key-value pairs (bytes32 => bytes).
    /// Interpretation of features (e.g., "themeColor" => bytes for a color code) is off-chain.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _featureKey The key for the feature (e.g., keccak256("themeColor")).
    /// @param _featureValue The value for the feature.
    function updateGalleryFeature(uint256 _galleryTokenId, bytes32 _featureKey, bytes memory _featureValue)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        _galleryFeatures[_galleryTokenId][_featureKey] = _featureValue;
        emit GalleryFeatureUpdated(_galleryTokenId, _featureKey, _featureValue);
    }

    /// @dev Retrieves the value of a specific gallery feature.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _featureKey The key for the feature.
    /// @return bytes The value of the feature. Returns empty bytes if the feature is not set.
    function getGalleryFeature(uint256 _galleryTokenId, bytes32 _featureKey)
        public
        view
        galleryExists(_galleryTokenId)
        returns (bytes memory)
    {
        // Check visibility if caller is not the owner
        if (_msgSender() != _galleryTokenIdToSoul[_galleryTokenId] && !_galleryFeatureVisibility[_galleryTokenId][_featureKey]) {
            // Or maybe revert, depending on desired privacy level
            return bytes(""); // Return empty bytes if not public and not owner
        }
        return _galleryFeatures[_galleryTokenId][_featureKey];
    }

    /// @dev Retrieves all key-value features for a gallery.
    /// This can be gas-intensive depending on the number of features set.
    /// @param _galleryTokenId The ID of the gallery.
    /// @return bytes32[] An array of feature keys.
    /// @return bytes[] An array of corresponding feature values.
    function getGalleryFeatures(uint256 _galleryTokenId)
        public
        view
        galleryExists(_galleryTokenId)
        returns (bytes32[] memory, bytes[] memory)
    {
        // Warning: Iterating over mappings directly in Solidity is not possible.
        // This function cannot easily return *all* features set.
        // A common pattern is to track keys in a separate array, or rely on off-chain indexing.
        // For demonstration, we'll return an empty array. A real implementation needs an index.
        // As a workaround for the example, let's just return empty arrays.
        // In a real system, you'd need a mapping(uint256 => bytes32[]) private _galleryFeatureKeys;
        // updated alongside updateGalleryFeature.
         revert("Retrieving all features is not directly supported on-chain due to gas limitations. Use an indexer.");
        // return (new bytes32[](0), new bytes[](0));
    }


    /// @dev Sets whether a specific feature is publicly visible.
    /// Default is likely true unless set otherwise.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _featureKey The key for the feature.
    /// @param _isPublic True to make public, false otherwise.
    function setFeatureVisibility(uint256 _galleryTokenId, bytes32 _featureKey, bool _isPublic)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        _galleryFeatureVisibility[_galleryTokenId][_featureKey] = _isPublic;
        emit GalleryFeatureVisibilityUpdated(_galleryTokenId, _featureKey, _isPublic);
    }


    // --- IV. Interactions (Visits & Reactions) ---

    /// @dev Records a visit to a gallery. Increments visitor count.
    /// A soul visiting their own gallery is also recorded.
    /// @param _galleryTokenId The ID of the gallery being visited.
    function visitGallery(uint256 _galleryTokenId) external whenNotPaused galleryExists(_galleryTokenId) {
        _visitorCount[_galleryTokenId]++;
        emit GalleryVisited(_galleryTokenId, _msgSender());
        // Could add logic here to award visit-related achievements (e.g., "First Visitor", "Frequent Visitor")
        // but triggering achievement issuance directly in a payable/view/external function is complex
        // (requires checks, potential loops). Better done by admin or a separate system.
    }

    /// @dev Gets the total number of visits for a gallery.
    /// @param _galleryTokenId The ID of the gallery.
    /// @return uint256 The total visit count.
    function getVisitorCount(uint256 _galleryTokenId) public view galleryExists(_galleryTokenId) returns (uint256) {
        return _visitorCount[_galleryTokenId];
    }

    /// @dev Records a specific type of reaction to a gallery.
    /// Reaction types are arbitrary (e.g., 0=like, 1=love, 2=fire). Interpretation is off-chain.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _reactionType The type of reaction.
    function leaveReaction(uint256 _galleryTokenId, uint256 _reactionType) external whenNotPaused galleryExists(_galleryTokenId) {
        _reactionCounts[_galleryTokenId][_reactionType]++;
        emit ReactionLeft(_galleryTokenId, _msgSender(), _reactionType);
    }

    /// @dev Gets the counts for all reaction types on a gallery.
    /// @param _galleryTokenId The ID of the gallery.
    /// @param _reactionTypes An array of reaction types to query counts for.
    /// @return uint256[] An array of corresponding counts.
    function getReactionCounts(uint256 _galleryTokenId, uint256[] memory _reactionTypes)
        public
        view
        galleryExists(_galleryTokenId)
        returns (uint256[] memory)
    {
        uint256[] memory counts = new uint256[](_reactionTypes.length);
        for (uint256 i = 0; i < _reactionTypes.length; i++) {
            counts[i] = _reactionCounts[_galleryTokenId][_reactionTypes[i]];
        }
        return counts;
    }

    // --- V. Events ---

    /// @dev Registers an on-chain event hosted at a gallery.
    /// @param _galleryTokenId The ID of the hosting gallery.
    /// @param _eventId A unique ID for the event (e.g., keccak256(title+time)).
    /// @param _startTime The start time of the event (Unix timestamp).
    /// @param _endTime The end time of the event (Unix timestamp).
    /// @param _eventUri Metadata URI for the event details (description, images, etc.).
    function hostEvent(uint256 _galleryTokenId, bytes32 _eventId, uint256 _startTime, uint256 _endTime, string memory _eventUri)
        external
        whenNotPaused
        onlyGalleryOwner(_galleryTokenId)
        galleryExists(_galleryTokenId)
    {
        require(_events[_eventId].galleryTokenId == 0 && _events[_eventId].host == address(0), "Event ID already exists");
        require(_startTime < _endTime, "Start time must be before end time");
        // Could add checks for time validity (e.g., not in the past too far)

        _events[_eventId] = GalleryEvent({
            eventId: _eventId,
            galleryTokenId: _galleryTokenId,
            startTime: _startTime,
            endTime: _endTime,
            eventUri: _eventUri,
            host: _msgSender()
        });
        _hostedEventIds[_galleryTokenId].push(_eventId);

        emit EventHosted(_eventId, _galleryTokenId, _msgSender(), _startTime, _endTime);
    }

    /// @dev Lists the IDs of events hosted by a specific gallery.
    /// @param _galleryTokenId The ID of the gallery.
    /// @return bytes32[] An array of event IDs.
    function getGalleryEvents(uint256 _galleryTokenId)
        public
        view
        galleryExists(_galleryTokenId)
        returns (bytes32[] memory)
    {
        return _hostedEventIds[_galleryTokenId];
    }

     /// @dev Gets the details of a specific event.
    /// @param _eventId The unique ID of the event.
    /// @return GalleryEvent The details of the event.
    function getEventDetails(bytes32 _eventId) public view eventExists(_eventId) returns (GalleryEvent memory) {
        return _events[_eventId];
    }


    /// @dev Allows a user to register their attendance for an event.
    /// @param _eventId The unique ID of the event.
    function registerForEvent(bytes32 _eventId) external whenNotPaused eventExists(_eventId) {
        require(!_isAttendee[_eventId][_msgSender()], "Already registered for this event");
        // Could add time constraints (e.g., only register before event ends)
        // require(block.timestamp < _events[_eventId].endTime, "Cannot register after event ends");

        _eventAttendees[_eventId].push(_msgSender());
        _isAttendee[_eventId][_msgSender()] = true;

        emit EventRegistered(_eventId, _msgSender());
    }

    /// @dev Lists the addresses registered for an event.
    /// @param _eventId The unique ID of the event.
    /// @return address[] An array of attendee addresses.
    function getEventAttendees(bytes32 _eventId) public view eventExists(_eventId) returns (address[] memory) {
        return _eventAttendees[_eventId];
    }

    /// @dev Checks if a specific soul is registered for an event.
    /// @param _eventId The unique ID of the event.
    /// @param _soul The address of the soul to check.
    /// @return bool True if the soul is registered, false otherwise.
    function checkEventAttendance(bytes32 _eventId, address _soul) public view eventExists(_eventId) returns (bool) {
        return _isAttendee[_eventId][_soul];
    }


    // --- VI. Achievements (Soulbound Issuer) ---

    /// @dev Admin function to define the metadata URI for an achievement ID.
    /// This allows linking an achievement ID to off-chain metadata describing it.
    /// @param _achievementId The ID of the achievement.
    /// @param _uri The metadata URI (e.g., IPFS hash).
    function defineAchievement(uint256 _achievementId, string memory _uri) external onlyOwner {
        _achievementURIs[_achievementId] = _uri;
        emit AchievementDefined(_achievementId, _uri);
    }

    /// @dev Admin function to issue a specific achievement SBT to a soul.
    /// These achievements are soulbound and cannot be transferred.
    /// @param _soul The address of the soul to issue the achievement to.
    /// @param _achievementId The ID of the achievement to issue.
    function issueGalleryAchievementSBT(address _soul, uint256 _achievementId) external onlyOwner {
        require(_achievementURIs[_achievementId].length > 0, "Achievement ID not defined");
        require(!_hasAchievement[_soul][_achievementId], "Soul already has this achievement");

        _soulAchievements[_soul].push(_achievementId);
        _hasAchievement[_soul][_achievementId] = true;

        emit AchievementIssued(_soul, _achievementId);
    }

    /// @dev Retrieves the list of achievement SBT IDs owned by a soul.
    /// @param _soul The address of the soul.
    /// @return uint256[] An array of achievement IDs.
    function getAchievementSBTs(address _soul) public view returns (uint256[] memory) {
        return _soulAchievements[_soul];
    }

    /// @dev Checks if a soul possesses a specific achievement SBT.
    /// @param _soul The address of the soul.
    /// @param _achievementId The ID of the achievement.
    /// @return bool True if the soul has the achievement, false otherwise.
    function hasAchievementSBT(address _soul, uint256 _achievementId) public view returns (bool) {
        return _hasAchievement[_soul][_achievementId];
    }

    /// @dev Gets the metadata URI for a specific achievement ID.
    /// @param _achievementId The ID of the achievement.
    /// @return string The metadata URI.
    function getAchievementURI(uint256 _achievementId) public view returns (string memory) {
        return _achievementURIs[_achievementId];
    }

    // --- VII. Admin & Platform ---

    /// @dev Admin sets the fee required to claim a gallery.
    /// @param _fee The new fee amount.
    function setGalleryClaimFee(uint256 _fee) external onlyOwner {
        galleryClaimFee = _fee;
    }

    /// @dev Admin withdraws collected claim fees.
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeeWithdrawn(owner(), balance);
    }

    // Pausable functions (inherit from Pausable)
    // pause() and unpause() are available to the owner.

    /// @dev Pauses the contract, preventing most state-changing operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @dev Unpauses the contract, allowing state-changing operations again.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Internal/Helper Functions ---

    /// @dev Mints a new gallery token and associates it with a soul.
    /// Overrides _safeMint to also set the soul mapping.
    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        _galleryTokenIdToSoul[tokenId] = to; // Explicitly store soul
    }

    // --- Additional ERC721 compliance ---

    // The standard ERC165 supportsInterface is inherited from OpenZeppelin ERC721.
    // It correctly reports support for ERC721 and ERC165 interfaces.
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Soulbound Tokens (SBTs):** The core concept is a non-transferable ERC721 token (`claimGallery`, overridden `_beforeTokenTransfer`). This prevents the gallery itself from being sold or moved, anchoring it to the user's identity (their address).
2.  **External NFT Display:** The contract stores references (`(address, uint256)[]`) to NFTs owned by the soul on *other* ERC721 contracts (`addDisplayedNFT`, `getDisplayedNFTs`). The contract doesn't custody the NFTs, just records which ones the soul *intends* to display. Off-chain services retrieve this list and verify ownership (or trust the soul) for rendering. This is a gas-efficient way to allow curation across the entire NFT ecosystem.
3.  **Dynamic On-Chain Features:** Using `bytes32 => bytes` mappings (`updateGalleryFeature`, `getGalleryFeature`), the contract allows arbitrary key-value data to be stored representing aspects of the gallery's state or appearance. This data can be dynamic and changed by the owner. `setFeatureVisibility` adds a layer of privacy control. Interpretation of these bytes happens off-chain, keeping the contract focused on verifiable state.
4.  **On-Chain Interactions:** `visitGallery` and `leaveReaction` provide simple, gas-efficient ways to record public interaction with a gallery. This data is verifiable on-chain and can potentially be used for future mechanics (like awarding achievements for visiting many galleries).
5.  **On-Chain Event System:** A simple system to register events tied to a specific gallery (`hostEvent`, `registerForEvent`, `getEventAttendees`). This allows for verifiable on-chain records of virtual or real-world events hosted by gallery owners, potentially linking directly to attendance-based achievements.
6.  **Achievement Issuer:** The contract itself acts as an issuer of soulbound achievements (`defineAchievement`, `issueGalleryAchievementSBT`, `getAchievementSBTs`). These achievements are also non-transferable and tied to the soul, building a verifiable on-chain reputation/history based on gallery participation or curation. This creates a feedback loop within the ecosystem.
7.  **Gas Considerations:** While providing rich functionality, choices were made to manage gas. Displaying *external* NFTs avoids costly deposit/withdrawal patterns. Interaction tracking uses simple counters/mappings. Retrieving *all* features or *all* hosted events/attendees for *every* gallery is offloaded or noted as a potential limitation requiring off-chain indexing.
8.  **Extensibility:** The feature system (`updateGalleryFeature`) and achievement system (`defineAchievement`) are designed to be extensible. New features or achievements can be defined and implemented off-chain without changing the core contract logic, using the on-chain state as a source of truth.

This contract provides a foundation for a decentralized, identity-anchored digital space where users can curate their digital assets, interact with others, host events, and earn verifiable recognition for their participation, all linked to their non-transferable "Soulbound Gallery" identity.