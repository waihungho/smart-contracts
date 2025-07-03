Okay, let's create a smart contract concept that combines digital ownership, generative aspects, collaborative creation under specific rules, and verifiable state representation.

We'll call it "EternalInkwell". It's a platform where users can create "Pages" (like canvases or digital scrolls) with unique rules. On these pages, users can contribute "Glyphs" (entries, strokes, data snippets) which are minted as ERC721 tokens. The contract manages the pages, the rules, the glyph contributions, and provides ways to interpret the resulting "composite view" of a page.

**Key Advanced/Creative Concepts:**

1.  **ERC721 for Contributions:** Each contribution (Glyph) is a distinct NFT owned by the contributor.
2.  **Parameterized Pages:** Pages have configurable rules (fees, allowed data types, property constraints, access control).
3.  **On-Chain Limited Data/Hash Storage:** Glyphs store essential parameters or hashes of off-chain data on-chain to keep costs manageable while anchoring the content.
4.  **Encoded Properties:** Glyph visual/interpretive properties are encoded efficiently in a `uint256`.
5.  **Dynamic/Pseudo-Random Properties:** Properties can be influenced by contribution time, block data, or potentially re-rolled (with limitations, acknowledging on-chain randomness issues).
6.  **Verifiable Composite State:** A function generates a deterministic hash of a page's active glyphs (in order), allowing off-chain renderers to verify they are using the correct on-chain data state.
7.  **Role-Based Access Control:** Granular permissions for creating pages, setting global rules, or managing contributors.
8.  **Internal Accounting/Fee Distribution:** Handling collection of contribution fees and allowing withdrawal by designated parties.
9.  **Burning with History:** Burning a Glyph NFT removes ownership and active status on the page but keeps the historical data record linked to the token ID for potential archival composite views.

This contract is *not* a simple token, a standard NFT drop, or a typical DeFi protocol. It's a platform for structured, owned, and verifiable digital creation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts for ERC721,
// or implement minimal interfaces needed for this example.
// For a real-world scenario, import fully tested OZ implementations.
// For this example, we'll define minimal interfaces and necessary internal logic.
// ERC721: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
// Ownable: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

import "./IERC721.sol"; // Assume IERC721 is available
import "./IERC721Metadata.sol"; // Assume IERC721Metadata is available

/**
 * @title EternalInkwell
 * @dev A platform for creating and contributing to on-chain digital artifacts
 *      composed of owned ERC721 'Glyph' tokens, guided by page-specific rules.
 */

/**
 * @dev CONTRACT OUTLINE:
 *
 * 1.  Interfaces/Abstract Contracts (ERC721 minimums for this example)
 * 2.  Error Definitions
 * 3.  Constants (Roles, Limits)
 * 4.  Struct Definitions (PageRules, Glyph, Page)
 * 5.  State Variables (Ownership, Counters, Mappings for Pages, Glyphs, Roles)
 * 6.  Events
 * 7.  Role Management (Custom Basic Implementation)
 * 8.  Constructor
 * 9.  ERC721 Standard Functions (Implemented minimally or noted as inherited)
 * 10. Admin/Global Configuration Functions
 * 11. Role Management Functions
 * 12. Page Management Functions (Creation, Rule Updates, Queries)
 * 13. Glyph Contribution (Minting) Function
 * 14. Glyph Interaction Functions (Burning, Data Retrieval, Property Rerolling)
 * 15. Advanced/Utility Functions (Composite Hash, Fee Distribution, Metadata)
 * 16. Internal/Helper Functions
 */

/**
 * @dev FUNCTION SUMMARY:
 *
 * ERC721 Standard (Assumed/Minimal Implementation):
 * - balanceOf(address owner) view returns (uint256)
 * - ownerOf(uint256 tokenId) view returns (address)
 * - safeTransferFrom(address from, address to, uint256 tokenId) payable
 * - transferFrom(address from, address to, uint256 tokenId) payable
 * - approve(address to, uint256 tokenId) payable
 * - setApprovalForAll(address operator, bool approved)
 * - getApproved(uint256 tokenId) view returns (address)
 * - isApprovedForAll(address owner, address operator) view returns (bool)
 * - name() view returns (string) (IERC721Metadata)
 * - symbol() view returns (string) (IERC721Metadata)
 * - tokenURI(uint256 tokenId) view returns (string) (IERC721Metadata)
 *
 * Role Management (Custom Basic):
 * 1. grantRole(bytes32 role, address account): Assign a role to an address.
 * 2. revokeRole(bytes32 role, address account): Remove a role from an address.
 * 3. renounceRole(bytes32 role): User removes a role from themselves.
 * 4. hasRole(bytes32 role, address account) view returns (bool): Check if address has role.
 *
 * Admin/Global Configuration:
 * 5. setPageCreationFee(uint256 fee): Set the cost to create a new page.
 * 6. setBaseURI(string baseURI): Set the base URI for Glyph metadata.
 * 7. withdrawContractBalance(address payable recipient): Withdraw accumulated ETH not tied to page fees.
 *
 * Page Management:
 * 8. createPage(string name, PageRules rules, string metadataURI) payable returns (uint256 pageId): Create a new page with specified rules and metadata.
 * 9. updatePageRules(uint256 pageId, PageRules newRules): Update the rules for an existing page.
 * 10. togglePageContributionLock(uint256 pageId, bool locked): Lock or unlock contributions for a page.
 * 11. addWhitelistedContributor(uint256 pageId, address contributor): Add an address to a page's whitelist.
 * 12. removeWhitelistedContributor(uint256 pageId, address contributor): Remove an address from a page's whitelist.
 * 13. distributePageFees(uint256 pageId, address payable recipient): Withdraw accumulated fees for a specific page.
 * 14. getPageDetails(uint256 pageId) view returns (string name, address creator, uint256 creationTime, bool contributionLocked, uint256 currentGlyphCounter, PageRules rules, string metadataURI): Get details of a page.
 * 15. getPageGlyphTokenIds(uint256 pageId, bool includeBurned) view returns (uint256[] tokenIds): Get list of Glyph token IDs associated with a page.
 * 16. getGlyphCountOnPage(uint256 pageId, bool includeBurned) view returns (uint256 count): Get number of glyphs on a page.
 * 17. listAllPageIds() view returns (uint256[] pageIds): Get a list of all created page IDs.
 * 18. getTotalPages() view returns (uint256): Get the total number of pages created.
 * 19. setPageMetadataURI(uint256 pageId, string metadataURI): Set metadata URI for a page.
 *
 * Glyph Contribution:
 * 20. contributeToPage(uint256 pageId, uint8 dataType, bytes data, uint256 encodedProperties) payable returns (uint256 tokenId): Mint a new Glyph token by contributing data to a page, following its rules.
 * 21. setGlyphDataHash(uint256 tokenId, bytes32 dataHash): Owner can set a hash linking off-chain data to their Glyph.
 * 22. getGlyphDataHash(uint256 tokenId) view returns (bytes32): Get the linked data hash for a Glyph.
 *
 * Glyph Interaction/Query:
 * 23. burnGlyph(uint256 tokenId): Burn a Glyph token. Removes ownership and active status on page, but data may persist.
 * 24. getGlyphData(uint256 tokenId) view returns (uint256 pageId, address contributor, uint64 timestamp, uint8 dataType, bytes data, uint256 encodedProperties, bool isBurned): Retrieve full data for a specific Glyph.
 * 25. rerollGlyphPropertiesAdmin(uint256 tokenId): Admin can re-roll properties of a Glyph (example of dynamic state update).
 *
 * Advanced/Utility:
 * 26. getCompositeViewHash(uint256 pageId) view returns (bytes32): Calculate a deterministic hash of the page's active glyphs.
 * 27. getTotalGlyphsMinted() view returns (uint256): Get the total number of glyphs minted across all pages (ERC721 totalSupply).
 *
 * Total Functions Listed: 27 (+ 8 standard ERC721 functions implicitly used/needed) = 35
 */

// --- Minimal ERC721 Interface (for demonstration) ---
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function approve(address to, uint256 tokenId) external payable;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// --- Error Definitions ---
error EternalInkwell__NotOwner();
error EternalInkwell__FeeMismatch(uint256 expectedFee, uint256 providedFee);
error EternalInkwell__InvalidPageId();
error EternalInkwell__PageLocked();
error EternalInkwell__NotWhitelisted();
error EternalInkwell__MaxGlyphSizeExceeded();
error EternalInkwell__InvalidDataType();
error EternalInkwell__InvalidRole();
error EternalInkwell__RecipientZeroAddress();
error EternalInkwell__TransferFailed();
error EternalInkwell__BurnFailed();
error EternalInkwell__MetadataURINotSet();


contract EternalInkwell is IERC721Metadata {

    // --- Constants ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAGE_CREATOR_ROLE = keccak256("PAGE_CREATOR_ROLE");

    // --- Struct Definitions ---

    struct PageRules {
        uint256 contributionFee;       // Fee required to contribute a glyph to this page
        uint16 maxGlyphDataSize;       // Max size of the 'data' bytes field
        bytes32 requiredContributorRole; // Role required, 0x0 for anyone
        bool requiresWhitelist;        // True if contributor must be whitelisted
        // Future: colorPalette, allowedTypes, etc. encoded/referenced here
        uint256 ruleSetVersion;        // Increment on rule changes
    }

    struct Glyph {
        uint256 pageId;
        address contributor;
        uint64 timestamp;              // Unix timestamp of creation
        uint8 dataType;                // e.g., 1=Text, 2=URL, 3=Encoded Drawing Command, 4=Hash
        bytes data;                    // Limited data or hash/pointer
        uint256 encodedProperties;     // Packed properties (color, size, style, etc.)
        bytes32 dataHash;              // Optional hash for off-chain data verification
        bool isBurned;                 // True if the NFT token has been burned
    }

    struct Page {
        string name;
        address creator;
        uint256 creationTime;
        bool contributionLocked;
        PageRules rules;
        uint256[] associatedGlyphTokenIds; // Ordered list of active (non-burned) glyphs on this page
        mapping(address => bool) whitelistedContributors; // Whitelist specific to this page
        uint256 accumulatedFees;       // ETH accumulated from contributions to this page
        string metadataURI;            // Metadata URI for the page itself
    }

    // --- State Variables ---

    address private _owner; // Contract deployer/main owner

    mapping(bytes32 => mapping(address => bool)) private _roles;

    uint256 private _pageCounter; // Starts at 1
    mapping(uint256 => Page) private _pages;
    uint256[] private _allPageIds; // Keep track of all page IDs

    uint256 private _tokenCounter; // Starts at 1, ERC721 tokenId counter
    mapping(uint256 => address) private _tokenOwners; // ERC721 owner storage
    mapping(uint256 => address) private _tokenApprovals; // ERC721 single approval
    mapping(address => mapping(address => bool)) private _operatorApprovals; // ERC721 operator approval

    mapping(uint256 => Glyph) private _glyphs; // Stores data for each minted Glyph

    string private _baseTokenURI;
    uint256 private _pageCreationFee = 0.01 ether; // Default fee to create a page

    // --- Events ---

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event PageCreated(uint256 indexed pageId, string name, address indexed creator, PageRules rules);
    event PageRulesUpdated(uint256 indexed pageId, PageRules newRules);
    event PageContributionLockedToggled(uint256 indexed pageId, bool locked);
    event WhitelistedContributorAdded(uint256 indexed pageId, address indexed contributor, address indexed sender);
    event WhitelistedContributorRemoved(uint256 indexed pageId, address indexed contributor, address indexed sender);
    event PageFeesDistributed(uint256 indexed pageId, address indexed recipient, uint256 amount);
    event GlyphContributed(uint256 indexed pageId, uint256 indexed tokenId, address indexed contributor, uint8 dataType, bytes data, uint256 encodedProperties);
    event GlyphDataHashSet(uint256 indexed tokenId, bytes32 dataHash);
    event GlyphPropertiesRerolled(uint256 indexed tokenId, uint256 oldProperties, uint256 newProperties);
    event PageMetadataURIUpdated(uint256 indexed pageId, string metadataURI);

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _roles[ADMIN_ROLE][msg.sender] = true; // Grant ADMIN_ROLE to deployer
        _pageCounter = 0; // Page IDs will start from 1
        _tokenCounter = 0; // Token IDs will start from 1
    }

    // --- Internal/Helper Functions ---

    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) {
            revert EternalInkwell__InvalidRole();
        }
        _;
    }

    modifier onlyPageCreatorOrAdmin(uint256 pageId) {
        Page storage page = _pages[pageId];
        if (page.creator != msg.sender && !_roles[ADMIN_ROLE][msg.sender]) {
            revert EternalInkwell__InvalidRole(); // Or specific error like NotPageCreatorOrAdmin
        }
        _;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Using public ownerOf
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // ERC721 Basic Implementation (for this example)
    // In a real contract, inherit from OpenZeppelin's ERC721

    function name() public view virtual override returns (string memory) {
        return "Eternal Inkwell Glyph";
    }

    function symbol() public view virtual override returns (string memory) {
        return "EIG";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId); // Using OZ-style error
        // Placeholder for actual metadata URI logic
        // Could combine _baseTokenURI with tokenId or data hash
        if (bytes(_baseTokenURI).length == 0) revert EternalInkwell__MetadataURINotSet();
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))); // Using OZ Strings or similar
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0)); // Using OZ-style error
        uint256 count = 0;
        // This is inefficient for large collections. A real ERC721 tracks balances differently (e.g., array per owner or counter)
        // For simplicity here, we iterate.
        for (uint256 i = 1; i <= _tokenCounter; i++) {
            if (_tokenOwners[i] == owner) {
                count++;
            }
        }
        return count;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert ERC721NonexistentToken(tokenId); // Using OZ-style error
        return owner;
    }

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert ERC721InvalidReceiver(address(0)); // Using OZ-style error
        // Add ERC721 minting logic (update balances, owner mapping)
        _tokenOwners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
         // Add ERC721 burning logic (clear owner, approvals)
        address owner = ownerOf(tokenId); // Will revert if not exists
        _tokenOwners[tokenId] = address(0);
        delete _tokenApprovals[tokenId];
        emit Transfer(owner, address(0), tokenId);

        // Mark the Glyph data as burned
        _glyphs[tokenId].isBurned = true;

        // IMPORTANT: For _pages[pageId].associatedGlyphTokenIds, we need to REMOVE this token ID.
        // Removing from an array in storage is expensive. A more gas-efficient approach
        // would be to iterate and filter *in the view function* getPageGlyphTokenIds,
        // or use a linked list, or mark as burned but don't remove from array,
        // or use a separate mapping mapping(uint256 => bool) isActiveOnPage.
        // For simplicity in this example, we'll note that associatedGlyphTokenIds
        // should conceptually only contain *active* glyphs, but the simple array
        // won't be updated here for gas reasons. The `getCompositeViewHash` will filter.
    }

    // Standard ERC721 transfer/approval functions would also need minimal implementation or inheritance.
    // Omitting for brevity as they are boilerplate.
    // Assume safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll are present.
    // They would interact with _tokenOwners, _tokenApprovals, _operatorApprovals and emit relevant events.
    // For `safeTransferFrom`, the `onERC721Received` check is needed.

    // --- Role Management (Custom Basic) ---

    function grantRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        if (account == address(0)) revert EternalInkwell__RecipientZeroAddress();
        _roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(ADMIN_ROLE) {
        if (account == address(0)) revert EternalInkwell__RecipientZeroAddress();
        _roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function renounceRole(bytes32 role) public {
        _roles[role][msg.sender] = false;
        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    // --- Admin/Global Configuration Functions ---

    function setPageCreationFee(uint256 fee) public onlyRole(ADMIN_ROLE) {
        _pageCreationFee = fee;
    }

    function setBaseURI(string memory baseURI) public onlyRole(ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function withdrawContractBalance(address payable recipient) public onlyRole(ADMIN_ROLE) {
        if (recipient == address(0)) revert EternalInkwell__RecipientZeroAddress();
        // Only withdraw balance *not* accumulated as page fees.
        // This requires tracking ETH separately or ensuring page fees are withdrawn via distributePageFees.
        // For simplicity, this function withdraws the *entire* contract balance not specifically marked as accumulated fees.
        // A more robust system might track balances per source or use a withdrawal pattern.
        uint256 balance = address(this).balance;
        // Ideally, subtract total accumulated fees across all pages.
        // For this example, let's assume any balance not in `accumulatedFees` can be withdrawn.
        // This is simplified; a real system needs careful accounting.
        uint256 totalAccumulated = 0;
        for(uint i = 0; i < _allPageIds.length; i++) {
            totalAccumulated += _pages[_allPageIds[i]].accumulatedFees;
        }
        uint256 amountToWithdraw = balance > totalAccumulated ? balance - totalAccumulated : 0;

        if (amountToWithdraw > 0) {
             (bool success, ) = recipient.call{value: amountToWithdraw}("");
             if (!success) revert EternalInkwell__TransferFailed();
        }
    }

    // --- Page Management Functions ---

    function createPage(string memory name, PageRules memory rules, string memory metadataURI) public payable returns (uint256 pageId) {
        if (msg.value < _pageCreationFee) {
            revert EternalInkwell__FeeMismatch(_pageCreationFee, msg.value);
        }
        if (rules.requiredContributorRole != 0x0 && !_roles[ADMIN_ROLE][msg.sender] && !_roles[PAGE_CREATOR_ROLE][msg.sender]) {
             revert EternalInkwell__InvalidRole(); // Cannot set a required role if you don't have creator/admin role
        }

        _pageCounter++;
        pageId = _pageCounter;
        _pages[pageId] = Page({
            name: name,
            creator: msg.sender,
            creationTime: block.timestamp,
            contributionLocked: false,
            rules: rules,
            associatedGlyphTokenIds: new uint256[](0), // Start with empty list
            accumulatedFees: msg.value - _pageCreationFee, // Store any excess sent beyond creation fee
            metadataURI: metadataURI
        });
        _allPageIds.push(pageId); // Add to list of all pages

        // Transfer the creation fee to the owner/treasury or burn it
        // For simplicity, excess is added to page fees, creation fee is "used" conceptually.
        // A real system might send the creation fee to a separate address.
        // We'll leave the fee in the contract balance to be withdrawn by admin.

        emit PageCreated(pageId, name, msg.sender, rules);
        return pageId;
    }

    function updatePageRules(uint256 pageId, PageRules memory newRules) public onlyPageCreatorOrAdmin(pageId) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId(); // Check if page exists

        // Prevent changing required role if the caller doesn't have the creator/admin role
         if (newRules.requiredContributorRole != page.rules.requiredContributorRole && !_roles[ADMIN_ROLE][msg.sender] && !_roles[PAGE_CREATOR_ROLE][msg.sender]) {
             revert EternalInkwell__InvalidRole(); // Cannot change required role if you don't have creator/admin role
        }

        newRules.ruleSetVersion = page.rules.ruleSetVersion + 1; // Increment version on update
        page.rules = newRules;

        emit PageRulesUpdated(pageId, newRules);
    }

    function togglePageContributionLock(uint256 pageId, bool locked) public onlyPageCreatorOrAdmin(pageId) {
         Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();

        page.contributionLocked = locked;
        emit PageContributionLockedToggled(pageId, locked);
    }

    function addWhitelistedContributor(uint256 pageId, address contributor) public onlyPageCreatorOrAdmin(pageId) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
        if (contributor == address(0)) revert EternalInkwell__RecipientZeroAddress();

        page.whitelistedContributors[contributor] = true;
        emit WhitelistedContributorAdded(pageId, contributor, msg.sender);
    }

    function removeWhitelistedContributor(uint256 pageId, address contributor) public onlyPageCreatorOrAdmin(pageId) {
         Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
        if (contributor == address(0)) revert EternalInkwell__RecipientZeroAddress();

        page.whitelistedContributors[contributor] = false;
         emit WhitelistedContributorRemoved(pageId, contributor, msg.sender);
    }

    function distributePageFees(uint256 pageId, address payable recipient) public onlyPageCreatorOrAdmin(pageId) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
         if (recipient == address(0)) revert EternalInkwell__RecipientZeroAddress();

        uint256 amount = page.accumulatedFees;
        if (amount > 0) {
            page.accumulatedFees = 0;
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) {
                 // Revert state if transfer failed to prevent funds from being lost
                 page.accumulatedFees = amount; // Restore balance
                 revert EternalInkwell__TransferFailed();
             }
            emit PageFeesDistributed(pageId, recipient, amount);
        }
    }

    function getPageDetails(uint256 pageId) public view returns (string memory name, address creator, uint256 creationTime, bool contributionLocked, uint256 currentGlyphCounter, PageRules memory rules, string memory metadataURI) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
        return (page.name, page.creator, page.creationTime, page.contributionLocked, page.associatedGlyphTokenIds.length, page.rules, page.metadataURI);
    }

    function getPageGlyphTokenIds(uint256 pageId, bool includeBurned) public view returns (uint256[] memory tokenIds) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();

        if (includeBurned) {
             // If including burned, return the potentially non-compacted array.
             // This is less efficient if many items are burned.
             // A better approach might store burned status in a separate mapping
             // and iterate through all token IDs >= page's starting ID,
             // or filter the array here (costly). Let's filter here for correctness demonstration.
            uint256 totalCount = 0;
            for(uint i = 0; i < page.associatedGlyphTokenIds.length; i++) {
                 totalCount++;
            }
            tokenIds = new uint256[](totalCount);
            uint256 currentIndex = 0;
            for(uint i = 0; i < page.associatedGlyphTokenIds.length; i++) {
                tokenIds[currentIndex] = page.associatedGlyphTokenIds[i];
                currentIndex++;
            }

        } else {
            // Filter out burned glyphs. This requires iterating.
             uint256 activeCount = 0;
             for(uint i = 0; i < page.associatedGlyphTokenIds.length; i++) {
                 uint256 tokenId = page.associatedGlyphTokenIds[i];
                 if (_exists(tokenId) && !_glyphs[tokenId].isBurned) { // Check existence and burned status
                     activeCount++;
                 }
             }
             tokenIds = new uint256[](activeCount);
             uint256 currentIndex = 0;
             for(uint i = 0; i < page.associatedGlyphTokenIds.length; i++) {
                 uint256 tokenId = page.associatedGlyphTokenIds[i];
                  if (_exists(tokenId) && !_glyphs[tokenId].isBurned) {
                     tokenIds[currentIndex] = tokenId;
                     currentIndex++;
                 }
             }
        }
         return tokenIds;
    }

     function getGlyphCountOnPage(uint256 pageId, bool includeBurned) public view returns (uint256 count) {
         Page storage page = _pages[pageId];
         if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();

         if (includeBurned) {
              return page.associatedGlyphTokenIds.length;
         } else {
             uint256 activeCount = 0;
             for(uint i = 0; i < page.associatedGlyphTokenIds.length; i++) {
                 uint256 tokenId = page.associatedGlyphTokenIds[i];
                 if (_exists(tokenId) && !_glyphs[tokenId].isBurned) {
                     activeCount++;
                 }
             }
             return activeCount;
         }
     }

    function listAllPageIds() public view returns (uint256[] memory) {
        return _allPageIds;
    }

    function getTotalPages() public view returns (uint256) {
        return _pageCounter;
    }

    function setPageMetadataURI(uint256 pageId, string memory metadataURI) public onlyPageCreatorOrAdmin(pageId) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
        page.metadataURI = metadataURI;
        emit PageMetadataURIUpdated(pageId, metadataURI);
    }


    // --- Glyph Contribution (Minting) Function ---

    function contributeToPage(uint256 pageId, uint8 dataType, bytes memory data, uint256 encodedProperties) public payable returns (uint256 tokenId) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();
        if (page.contributionLocked) revert EternalInkwell__PageLocked();

        // Check rules
        if (msg.value < page.rules.contributionFee) {
            revert EternalInkwell__FeeMismatch(page.rules.contributionFee, msg.value);
        }
        if (bytes(data).length > page.rules.maxGlyphDataSize) {
            revert EternalInkwell__MaxGlyphSizeExceeded();
        }
        if (page.rules.requiredContributorRole != 0x0 && !_roles[page.rules.requiredContributorRole][msg.sender]) {
             revert EternalInkwell__InvalidRole(); // Doesn't have required role for this page
        }
        if (page.rules.requiresWhitelist && !page.whitelistedContributors[msg.sender]) {
            revert EternalInkwell__NotWhitelisted();
        }

        // --- Mint Glyph NFT ---
        _tokenCounter++;
        tokenId = _tokenCounter;

        _mint(msg.sender, tokenId); // Use internal _mint function

        // --- Store Glyph Data ---
        // Example of influencing properties based on block/time - NOT truly random!
        // For secure randomness (e.g., for generative art traits), use Chainlink VRF or similar.
        uint256 finalProperties = encodedProperties;
        if (finalProperties == 0) { // Example: if properties are 0, assign simple pseudo-random ones
             finalProperties = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId))) % 1000; // Simple modulo
        }

        _glyphs[tokenId] = Glyph({
            pageId: pageId,
            contributor: msg.sender,
            timestamp: uint64(block.timestamp),
            dataType: dataType,
            data: data,
            encodedProperties: finalProperties,
            dataHash: 0, // Initially no data hash set
            isBurned: false
        });

        // Add token ID to the page's list
        page.associatedGlyphTokenIds.push(tokenId);

        // Handle fee
        uint256 fee = page.rules.contributionFee;
        if (fee > 0) {
            page.accumulatedFees += fee;
        }
        // Any excess msg.value beyond the fee stays in the contract balance (can be withdrawn by admin)

        emit GlyphContributed(pageId, tokenId, msg.sender, dataType, data, finalProperties);
        return tokenId;
    }

     function setGlyphDataHash(uint256 tokenId, bytes32 dataHash) public {
         if (ownerOf(tokenId) != msg.sender) revert EternalInkwell__NotOwner(); // Uses ERC721 ownerOf check
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

         _glyphs[tokenId].dataHash = dataHash;
         emit GlyphDataHashSet(tokenId, dataHash);
     }

     function getGlyphDataHash(uint256 tokenId) public view returns (bytes32) {
          if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
          return _glyphs[tokenId].dataHash;
     }


    // --- Glyph Interaction/Query Functions ---

    function burnGlyph(uint256 tokenId) public {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721InsufficientApproval(msg.sender, tokenId); // Uses internal helper
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

        _burn(tokenId); // Use internal _burn function
        // Note: `isBurned` is set to true within _burn. The glyph data remains in _glyphs mapping.
    }

    function getGlyphData(uint256 tokenId) public view returns (uint256 pageId, address contributor, uint64 timestamp, uint8 dataType, bytes memory data, uint256 encodedProperties, bool isBurned) {
         // Data is available even if NFT is burned, keyed by tokenId
         if (!_exists(tokenId) && _glyphs[tokenId].contributor == address(0)) revert ERC721NonexistentToken(tokenId); // Check if data exists for token ID

         Glyph storage glyph = _glyphs[tokenId];
         return (glyph.pageId, glyph.contributor, glyph.timestamp, glyph.dataType, glyph.data, glyph.encodedProperties, glyph.isBurned);
    }

    function rerollGlyphPropertiesAdmin(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
         if (_glyphs[tokenId].isBurned) revert EternalInkwell__BurnFailed(); // Cannot reroll burned glyphs

         Glyph storage glyph = _glyphs[tokenId];
         uint256 oldProperties = glyph.encodedProperties;

         // Example of admin-forced re-roll using block data (still pseudo-random)
         // In a real system, rules might dictate if properties are rerollable and by whom.
         // A more complex reroll might use Chainlink VRF requested by the admin.
         glyph.encodedProperties = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, msg.sender))) % 1000;

         emit GlyphPropertiesRerolled(tokenId, oldProperties, glyph.encodedProperties);
     }


    // --- Advanced/Utility Functions ---

    /**
     * @dev Calculates a deterministic hash representing the active state of a page's glyphs.
     *      Useful for off-chain renderers to verify they are interpreting the correct on-chain data.
     *      Order matters, and only non-burned glyphs are included.
     *      NOTE: This function can be computationally expensive for pages with many glyphs, potentially exceeding gas limits.
     *      For performance-critical applications, this hash might be computed off-chain and stored/verified differently.
     */
    function getCompositeViewHash(uint256 pageId) public view returns (bytes32) {
        Page storage page = _pages[pageId];
        if (page.creator == address(0)) revert EternalInkwell__InvalidPageId();

        // Hash includes page rules version to ensure hash changes when rules change
        bytes32 currentHash = keccak256(abi.encodePacked(page.rules.ruleSetVersion));

        uint256[] memory tokenIds = getPageGlyphTokenIds(pageId, false); // Get active glyph IDs

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Glyph storage glyph = _glyphs[tokenId];
            // Hash core, immutable glyph data points (excluding mutable dataHash and isBurned)
            // and include the token ID itself (for order dependency).
            currentHash = keccak256(abi.encodePacked(
                currentHash,
                tokenId,
                glyph.pageId,
                glyph.contributor,
                glyph.timestamp,
                glyph.dataType,
                keccak256(glyph.data), // Hash the data bytes
                glyph.encodedProperties
            ));
        }

        return currentHash;
    }

    function getTotalGlyphsMinted() public view returns (uint256) {
        return _tokenCounter; // Matches ERC721 totalSupply concept
    }

     // --- Minimal ERC721 Implementations (cont.) ---
     // These are standard ERC721 functions needed for basic compatibility.
     // In a real contract, these would be inherited from OpenZeppelin.

     function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override {
          // Basic check, full implementation includes ERC721Receiver check
         transferFrom(from, to, tokenId);
          // requires ERC721Receiver logic for smart contracts
     }

      function transferFrom(address from, address to, uint256 tokenId) public payable virtual override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721InsufficientApproval(msg.sender, tokenId); // Needs OZ-style error
         if (ownerOf(tokenId) != from) revert ERC721IncorrectOwner(from, tokenId); // Needs OZ-style error
         if (to == address(0)) revert ERC721InvalidReceiver(address(0)); // Needs OZ-style error

         // Clear approvals from the previous owner
         delete _tokenApprovals[tokenId];

         _tokenOwners[tokenId] = to;
         // Does NOT remove from page's associatedGlyphTokenIds array - ownership changes, but contribution stays linked conceptually
         emit Transfer(from, to, tokenId);
      }

     function approve(address to, uint256 tokenId) public payable virtual override {
         address owner = ownerOf(tokenId); // Will revert if not exists
         if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert ERC721InsufficientApproval(msg.sender, tokenId); // Needs OZ-style error
         }
         _tokenApprovals[tokenId] = to;
         emit Approval(owner, to, tokenId);
     }

     function getApproved(uint256 tokenId) public view virtual override returns (address) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId); // Needs OZ-style error
         return _tokenApprovals[tokenId];
     }

     function setApprovalForAll(address operator, bool approved) public virtual override {
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg.sender, operator, approved);
     }

     function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
         return _operatorApprovals[owner][operator];
     }

     // --- Using OZ-style Error Definitions for compatibility with common tooling ---
     // Add these error definitions here or import them if using OZ
     error ERC721NonexistentToken(uint256 tokenId);
     error ERC721IncorrectOwner(address operator, uint256 tokenId);
     error ERC721InvalidOwner(address owner);
     error ERC721InvalidReceiver(address receiver);
     error ERC721InsufficientApproval(address operator, uint256 tokenId);


    // --- Minimal String Conversion (for tokenURI) ---
    // Add this or import OpenZeppelin's Strings.sol
    library Strings {
        bytes16 private constant _HEX_TABLE = "0123456789abcdef";
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```

---

**Explanation of Advanced/Interesting Parts:**

1.  **ERC721 as a Contribution Token:** Instead of a standard generative art NFT where properties are fixed at mint, here the NFT *represents* a contribution *to* a larger evolving artifact (the Page). The ownership of the contribution is distinct from the ownership of the overall page concept.
2.  **Parameterized Pages (`PageRules`):** The `PageRules` struct allows creators (or admins) to define dynamic conditions for contribution. This goes beyond a simple whitelist or fixed mint price. It enables diverse page types with different interaction models (e.g., a "premium" page with high fees, a "community" page requiring a specific role, a "limited" page with small data size limits). The `ruleSetVersion` allows external interpreters to know if the rules governing a page's appearance/interpretation have changed.
3.  **On-Chain Limited Data/Hash (`Glyph.data`, `Glyph.dataHash`):** Storing large images or complex instructions directly on-chain is prohibitive. `Glyph.data` is limited (`maxGlyphDataSize`) for small pieces of text or simple parameters. `Glyph.dataHash` provides a verifiable link to off-chain data (like an IPFS hash of a generated image or a text file), anchoring the content on-chain without storing the full content.
4.  **Encoded Properties (`Glyph.encodedProperties`):** A single `uint256` is used to pack multiple properties (like color, stroke thickness, font style, etc.) that an off-chain renderer would interpret. This is significantly more gas-efficient than storing multiple separate fields or a mapping. Off-chain tools would need to know how to decode this integer.
5.  **Dynamic/Pseudo-Random Properties (`contributeToPage`, `rerollGlyphPropertiesAdmin`):** The initial `encodedProperties` can be influenced by the block hash or timestamp during minting (simple example, *not* truly random or secure). The `rerollGlyphPropertiesAdmin` function demonstrates how properties *could* be updated after minting, adding a dynamic element to the NFTs themselves, controlled by specific roles. (Requires careful design in a real system, potentially tied to payment or specific game mechanics).
6.  **Verifiable Composite State (`getCompositeViewHash`):** This function generates a deterministic hash of the *current active state* of a page (excluding burned glyphs, ordered by contribution). An off-chain application rendering the page (e.g., a website displaying the collaborative art piece) can calculate the same hash based on the on-chain Glyph data and compare it to the hash from this function. This cryptographically proves that the off-chain rendering is based on the correct, immutable on-chain data, ensuring transparency and authenticity of the generated artifact. This is a powerful concept for on-chain generative systems.
7.  **Role-Based Access Control (Custom Basic):** A simple mapping-based role system (`ADMIN_ROLE`, `PAGE_CREATOR_ROLE`) is implemented. This allows for tiered permissions beyond simple ownership, controlling who can create pages, set global fees, or manage page-specific settings and whitelists.
8.  **Internal Accounting (`accumulatedFees`, `distributePageFees`):** The contract collects contribution fees per page. The `distributePageFees` function allows the page creator (or admin) to withdraw these specific fees, keeping them separate from the general contract balance.
9.  **Burning with History (`burnGlyph`, `Glyph.isBurned`, `getGlyphData`):** When a Glyph NFT is burned, ownership is destroyed as per the ERC721 standard. However, the associated `Glyph` struct data is *not* deleted from storage; it's simply marked `isBurned = true`. This allows historical views or analyses of pages to potentially include burned contributions, while active composite views (`getCompositeViewHash`, `getPageGlyphTokenIds(false)`) exclude them.

This contract provides a framework for building complex, dynamic, and verifiable on-chain creative projects where users own their individual contributions within a larger, rule-governed ecosystem. It moves beyond simple static NFTs by introducing collaboration, rule-based interaction, and verifiable derived states.