Okay, let's create a smart contract based on an interesting concept: A decentralized "Chronicle" represented by a series of linked NFTs, where each NFT is a "Moment" in time or a sequence, possessing dynamic properties and delegation capabilities. This avoids directly copying standard implementations while using well-known patterns in a novel combination.

**Concept: ChronicleNFT - Linked & Dynamic Moments**

This contract mints NFTs where each token represents a "Moment". These moments can be linked together to form a "Chronicle Chain". Individual moments and entire chains can have dynamic properties (like description/URI), be frozen, and allow for delegation of certain rights.

**Outline:**

1.  **SPDX-License-Identifier & Pragma**
2.  **Imports:** ERC721, ERC721URIStorage, ERC721Burnable, ERC2981, Pausable, Ownable, Roles. (Using building blocks, but the *composition* and *logic* is custom).
3.  **Error Definitions**
4.  **Structs:** `Moment` to hold core data for each token.
5.  **State Variables:** Mappings for Moment data, linking pointers, frozen status, delegation, allowed minters, total supply, etc.
6.  **Events:** For Minting, Linking, Unlinking, Updates, Freezing, Delegation, Role changes, Pausing.
7.  **Roles:** `ALLOWED_MINTER_ROLE`.
8.  **Contract Definition:** Inheriting necessary modules.
9.  **Constructor:** Initializes base URI and admin role.
10. **Core ERC721 Overrides:** Transfer checks (`_beforeTokenTransfer`).
11. **ERC2981 Implementation:** Setting and retrieving royalty info.
12. **Pausable Implementation:** Pause/Unpause functionality.
13. **Access Control (Ownable & Roles):** Admin functions, Minter role management.
14. **Moment Management Functions:**
    *   Minting (Initial, Linked, Standalone).
    *   Updating (Description, URI - with delegation check).
    *   Freezing (Individual Moment, Entire Chain).
    *   Burning (Individual Moment, handles unlinking).
15. **Chronicle Linking Functions:**
    *   Linking two existing moments.
    *   Inserting a moment into a chain.
    *   Unlinking a moment from its neighbors.
16. **Delegation Functions:**
    *   Delegate rights (e.g., update description).
    *   Remove delegation.
17. **Snapshot Function:**
    *   Generate a hash representing the state of a chain.
18. **Read Functions:**
    *   Get Moment details.
    *   Traverse chain (get previous/next).
    *   Check frozen status.
    *   Get delegation status.
    *   Get chain start/length.
    *   Get minters list.

**Function Summary (Public/External Functions):**

1.  `constructor(string memory name, string memory symbol, string memory baseTokenURI)`: Initializes the contract, name, symbol, and base URI. Sets contract deployer as admin.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165 function to indicate support for interfaces (ERC721, Metadata, Burnable, ERC2981, AccessControl, Pausable).
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address. (ERC721)
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token. (ERC721)
5.  `approve(address to, uint256 tokenId)`: Approves an address to spend a specific token. (ERC721)
6.  `getApproved(uint256 tokenId)`: Gets the approved address for a specific token. (ERC721)
7.  `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all tokens owned by the caller. (ERC721)
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens owned by an address. (ERC721)
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership. (ERC721)
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers token ownership. (ERC721)
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safely transfers token ownership with data. (ERC721)
12. `tokenURI(uint256 tokenId)`: Returns the URI for the token metadata, checks if frozen. (ERC721 Metadata override)
13. `royaltyInfo(uint256 tokenId, uint256 salePrice)`: Returns the royalty information for a token based on sale price. (ERC2981)
14. `mintInitialMoment(string memory description, string memory tokenURI)`: Mints the very first token (start of a new chain). Restricted to minters.
15. `mintLinkedMoment(uint256 previousTokenId, string memory description, string memory tokenURI)`: Mints a new token and links it as the next moment after `previousTokenId`. Restricted to minters.
16. `mintStandaloneMoment(string memory description, string memory tokenURI)`: Mints a token that is not linked to any other initially. Restricted to minters.
17. `updateMomentDescription(uint256 tokenId, string memory newDescription)`: Updates the description of a moment. Callable by owner or delegated address, if not frozen.
18. `updateMomentURI(uint256 tokenId, string memory newTokenURI)`: Updates the URI of a moment. Callable by owner, if not frozen.
19. `freezeMoment(uint256 tokenId)`: Makes a specific moment immutable. Callable only by the owner.
20. `freezeChronicleChain(uint256 startTokenId)`: Freezes all moments in the chain starting from `startTokenId`. Callable only by the owner of `startTokenId`.
21. `linkMoments(uint256 firstTokenId, uint256 secondTokenId)`: Links `secondTokenId` as the moment after `firstTokenId`. Requires ownership of both.
22. `insertMomentBetween(uint256 firstTokenId, uint256 newListTokenId, uint256 thirdTokenId)`: Inserts `newListTokenId` between `firstTokenId` and `thirdTokenId`. Requires ownership of all three.
23. `unlinkMoment(uint256 tokenId)`: Removes a moment from its position in a chain, linking its previous and next neighbors. Requires ownership.
24. `burn(uint256 tokenId)`: Destroys a moment token, removing it from its chain if linked. Requires ownership or approval. (ERC721Burnable override)
25. `delegateDescriptionUpdateRights(uint256 tokenId, address delegatee)`: Allows the owner to grant an address the right to update the moment's description.
26. `removeDescriptionUpdateDelegation(uint256 tokenId)`: Removes any existing description update delegation for a moment. Callable by owner or current delegatee.
27. `createChainSnapshotHash(uint256 startTokenId)`: Generates a hash representing the current state (token IDs, frozen status, URIs) of the chain starting at `startTokenId`. Useful for off-chain proofs or checks.
28. `setTokenRoyaltyInfo(uint256 tokenId, address receiver, uint96 feeNumerator)`: Sets the royalty receiver and fee for a *specific* token. Callable by owner.
29. `pause()`: Pauses minting and transfers. Restricted to admin. (Pausable)
30. `unpause()`: Unpauses the contract. Restricted to admin. (Pausable)
31. `grantRole(bytes32 role, address account)`: Grants a role (like ALLOWED_MINTER_ROLE). Restricted to role admin (OWNER_ROLE). (AccessControl)
32. `revokeRole(bytes32 role, address account)`: Revokes a role. Restricted to role admin. (AccessControl)
33. `renounceRole(bytes32 role, address account)`: An account can renounce their own role. (AccessControl)
34. `hasRole(bytes32 role, address account)`: Checks if an account has a role. (AccessControl)
35. `getMomentDetails(uint256 tokenId)`: Returns the core details of a moment (read-only).
36. `getChainStart(uint256 tokenId)`: Finds and returns the token ID of the start of the chain the moment belongs to (read-only).
37. `getChainLength(uint256 tokenId)`: Calculates and returns the length of the chain the moment belongs to (read-only).
38. `isMomentFrozen(uint256 tokenId)`: Checks if a specific moment is frozen (read-only).
39. `isChainFrozen(uint256 startTokenId)`: Checks if an entire chain is frozen (read-only).
40. `getDescriptionUpdateDelegatee(uint256 tokenId)`: Returns the address delegated to update description for a moment (read-only).
41. `getAllowedMinters()`: Returns an array of addresses with the ALLOWED_MINTER_ROLE (read-only). *Requires AccessControlEnumerable for this exact function signature, let's simplify and provide an internal helper or skip returning all if we don't inherit Enumerable AC.* Let's skip returning all minters directly in the interest of code size/complexity for the example, but the role management functions (31-34) provide the necessary control.
    *Revised Function Count (External/Public):* 1-13 (ERC) + 14-16 (Mint) + 17-20 (Dynamics/Freeze) + 21-23 (Linking) + 24 (Burn) + 25-26 (Delegation) + 27-28 (Snapshot/RoyaltySet) + 29-30 (Pause) + 31-34 (Roles) + 35-40 (Read) = **40 Functions**. This easily meets the requirement.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; // Example for potential advanced use, maybe not strictly needed for this function set, but good to show

// Custom Errors
error ChronicleNFT__TokenDoesNotExist();
error ChronicleNFT__OnlyAllowedMinter();
error ChronicleNFT__MomentFrozen();
error ChronicleNFT__ChainFrozen();
error ChronicleNFT__UnauthorizedUpdate();
error ChronicleNFT__LinkAlreadyExists();
error ChronicleNFT__CannotLinkToSelf();
error ChronicleNFT__CannotUnlinkStandalone();
error ChronicleNFT__NotTokenOwner();
error ChronicleNFT__NotChainOwner();
error ChronicleNFT__AlreadyDelegatee();
error ChronicleNFT__NotDelegatee();
error ChronicleNFT__InvalidChainStart();
error ChronicleNFT__CannotLinkFrozenMoment();


/**
 * @title ChronicleNFT
 * @dev An ERC721 contract representing chronological or linked "Moments"
 *      with dynamic metadata, linking capabilities, freezing, and delegation.
 *
 * Outline:
 * 1. SPDX-License-Identifier & Pragma
 * 2. Imports
 * 3. Custom Errors
 * 4. Structs: Moment data
 * 5. State Variables: Token counter, Moment data mapping, linking maps, frozen status, delegation, roles.
 * 6. Events: Minting, Linking, Unlinking, Updates, Freezing, Delegation, Roles, Pausing.
 * 7. Roles: ALLOWED_MINTER_ROLE.
 * 8. Contract Definition: Inheritance (ERC721URIStorage, ERC721Burnable, ERC2981, Pausable, Ownable, AccessControl).
 * 9. Constructor: Initialize contract.
 * 10. Core ERC721 Overrides (_beforeTokenTransfer).
 * 11. ERC2981 Implementation (Setting/getting royalties).
 * 12. Pausable Implementation.
 * 13. Access Control (Ownable & AccessControl).
 * 14. Moment Management (Minting, Updating, Freezing, Burning).
 * 15. Chronicle Linking (Link, Insert, Unlink).
 * 16. Delegation (Description update rights).
 * 17. Snapshot (Generate chain hash).
 * 18. Read Functions (Details, Traversal, Status, Delegation, Chain info).
 *
 * Function Summary (Public/External Functions - roughly grouped):
 * - ERC721/Standard: supportsInterface, balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2), tokenURI, burn.
 * - ERC2981 Royalty: royaltyInfo, setTokenRoyaltyInfo.
 * - Pausable: pause, unpause.
 * - Access Control: grantRole, revokeRole, renounceRole, hasRole.
 * - Minting: mintInitialMoment, mintLinkedMoment, mintStandaloneMoment.
 * - Dynamic Updates: updateMomentDescription, updateMomentURI.
 * - Immutability: freezeMoment, freezeChronicleChain.
 * - Linking: linkMoments, insertMomentBetween, unlinkMoment.
 * - Delegation: delegateDescriptionUpdateRights, removeDescriptionUpdateDelegation.
 * - Snapshot: createChainSnapshotHash.
 * - Read Functions: getMomentDetails, getPreviousMoment, getNextMoment, isMomentFrozen, isChainFrozen, getDescriptionUpdateDelegatee, getChainStart, getChainLength.
 *
 * Total Public/External Functions: ~40+
 */
contract ChronicleNFT is
    Context,
    AccessControl,
    ERC721URIStorage,
    ERC721Burnable,
    ERC2981,
    Pausable,
    Ownable
{
    bytes32 public constant ALLOWED_MINTER_ROLE = keccak256("ALLOWED_MINTER_ROLE");

    struct Moment {
        uint256 timestamp;
        address minter;
        string description; // On-chain description
        uint256 previousTokenId; // 0 for start of chain or standalone
        uint256 nextTokenId; // 0 for end of chain or standalone
        bool isFrozen; // Individual moment freeze status
    }

    uint256 private _nextTokenId;

    // Core data storage
    mapping(uint256 => Moment) private _moments;
    // Explicit mapping for chain frozen status, keyed by the chain's START token ID
    mapping(uint256 => bool) private _isChainFrozen;

    // Delegation for specific rights (e.g., update description)
    mapping(uint256 => address) private _descriptionUpdateDelegatee;

    // --- Events ---
    event MomentMinted(
        uint256 indexed tokenId,
        address indexed minter,
        string description,
        string tokenURI,
        uint256 previousTokenId
    );
    event MomentUpdated(
        uint256 indexed tokenId,
        address indexed updater,
        string newDescription,
        string newTokenURI
    );
    event MomentLinked(
        uint256 indexed firstTokenId,
        uint256 indexed secondTokenId,
        address indexed linker
    );
    event MomentUnlinked(uint256 indexed tokenId, address indexed unlinker);
    event MomentFrozen(uint256 indexed tokenId, address indexed freezer);
    event ChainFrozen(uint256 indexed startTokenId, address indexed freezer);
    event DescriptionUpdateDelegated(
        uint256 indexed tokenId,
        address indexed delegator,
        address indexed delegatee
    );
    event DescriptionUpdateDelegationRemoved(
        uint256 indexed tokenId,
        address indexed remover
    );
    event ChainSnapshotTaken(
        uint256 indexed startTokenId,
        bytes32 indexed snapshotHash
    );

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) ERC721URIStorage() Ownable(msg.sender) {
        _nextTokenId = 1; // Start token IDs from 1
        _setDefaultRoyalty(msg.sender, 0); // Default royalty, can be changed
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ALLOWED_MINTER_ROLE, msg.sender); // Grant deployer minter role by default
        _setBaseURI(baseTokenURI);
    }

    // --- ERC721 Overrides ---
    // ERC721URIStorage requires overriding _baseURI and _update.
    // ERC721Burnable uses _burn.
    // ERC2981 requires royaltyInfo and _setDefaultRoyalty/_setTokenRoyaltyInfo.
    // Pausable requires `whenNotPaused` modifier.
    // Ownable manages owner.
    // AccessControl manages roles.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (_moments[tokenId].isFrozen) {
            // If moment is frozen, return the URI stored in the moment struct (if we stored it, or baseURI + id if that's how it works)
            // For simplicity, let's assume the URI points to metadata reflecting the state at freeze.
            // If you want to return the URI *stored in the contract at the time of freezing*, you'd need to store it in the Moment struct.
            // Current ERC721URIStorage just appends ID to baseURI. Let's stick to that standard but acknowledge freezing intent.
             // A frozen moment should return its state at freeze. ERC721URIStorage appends _tokenIds.
             // To truly freeze URI, you'd need to override _baseURI or store the *full* URI in the Moment struct on freeze.
             // For this example, we'll just prevent *updating* the URI when frozen, but `tokenURI` will still reflect the *current* (potentially post-freeze base) URI.
            return super.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721URIStorage) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Add checks here if needed, e.g., cannot transfer frozen tokens (optional based on design)
        // require(!_moments[tokenId].isFrozen, "Cannot transfer frozen moment"); // Example restriction
        // require(!isChainFrozen(getChainStart(tokenId)), "Cannot transfer token in frozen chain"); // Example restriction
    }

    // ERC721URIStorage overrides _update. ERC721Burnable overrides _burn.
    // We don't need to explicitly override _burn here as we handle unlinking inside the burn function logic.

    // --- ERC2981 Royalty ---
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        return super.royaltyInfo(tokenId, salePrice);
    }

    // Admin function to set royalty for a specific token
    function setTokenRoyaltyInfo(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyTokenOwner(tokenId) {
        // Check if token exists, only owner can set royalty
        if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        _setTokenRoyaltyInfo(tokenId, receiver, feeNumerator);
    }

    // --- Pausable ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- Access Control ---
    // Grant/Revoke/Renounce roles handled by AccessControl and Ownable default admin.
    // Added specific checks for minter role.

    function grantRole(bytes32 role, address account)
        public
        override(AccessControl)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override(AccessControl)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super.revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account)
        public
        override(AccessControl, Ownable)
    {
        super.renounceRole(role, account);
    }

    // --- Moment Management (Minting, Updating, Freezing, Burning) ---

    modifier onlyAllowedMinter() {
        if (!hasRole(ALLOWED_MINTER_ROLE, _msgSender())) {
            revert ChronicleNFT__OnlyAllowedMinter();
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender()) {
            revert ChronicleNFT__NotTokenOwner();
        }
        _;
    }

    modifier onlyTokenOwnerOrDelegatee(uint256 tokenId) {
        address tokenOwner = ownerOf(tokenId);
        address delegatee = _descriptionUpdateDelegatee[tokenId];
        if (_msgSender() != tokenOwner && _msgSender() != delegatee) {
            revert ChronicleNFT__UnauthorizedUpdate();
        }
        _;
    }

    modifier notFrozen(uint256 tokenId) {
        if (_moments[tokenId].isFrozen) {
            revert ChronicleNFT__MomentFrozen();
        }
        if (isChainFrozen(getChainStart(tokenId))) {
             revert ChronicleNFT__ChainFrozen();
        }
        _;
    }

    modifier onlyChainOwner(uint256 startTokenId) {
        if (!_exists(startTokenId) || _moments[startTokenId].previousTokenId != 0) {
             revert ChronicleNFT__InvalidChainStart();
        }
        if (ownerOf(startTokenId) != _msgSender()) {
            revert ChronicleNFT__NotChainOwner();
        }
        _;
    }

    /**
     * @dev Mints the first moment of a new chronicle chain.
     * @param description The on-chain description for the moment.
     * @param tokenURI The URI pointing to off-chain metadata.
     */
    function mintInitialMoment(
        string memory description,
        string memory tokenURI
    ) public whenNotPaused onlyAllowedMinter returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(_msgSender(), newTokenId);
        _moments[newTokenId] = Moment({
            timestamp: block.timestamp,
            minter: _msgSender(),
            description: description,
            previousTokenId: 0,
            nextTokenId: 0,
            isFrozen: false
        });
        _setTokenURI(newTokenId, tokenURI);

        emit MomentMinted(newTokenId, _msgSender(), description, tokenURI, 0);
        return newTokenId;
    }

    /**
     * @dev Mints a new moment and links it after an existing moment.
     * @param previousTokenId The token ID of the moment to link after.
     * @param description The on-chain description for the new moment.
     * @param tokenURI The URI pointing to off-chain metadata for the new moment.
     */
    function mintLinkedMoment(
        uint256 previousTokenId,
        string memory description,
        string memory tokenURI
    ) public whenNotPaused onlyAllowedMinter returns (uint256) {
        if (!_exists(previousTokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        if (_moments[previousTokenId].isFrozen || isChainFrozen(getChainStart(previousTokenId))) {
             revert ChronicleNFT__CannotLinkFrozenMoment(); // Cannot link to/from a frozen moment/chain
        }

        uint256 newTokenId = _nextTokenId++;
        _safeMint(_msgSender(), newTokenId);

        uint256 oldNextTokenId = _moments[previousTokenId].nextTokenId;

        _moments[newTokenId] = Moment({
            timestamp: block.timestamp,
            minter: _msgSender(),
            description: description,
            previousTokenId: previousTokenId,
            nextTokenId: oldNextTokenId,
            isFrozen: false
        });
        _setTokenURI(newTokenId, tokenURI);

        _moments[previousTokenId].nextTokenId = newTokenId;
        if (oldNextTokenId != 0) {
            _moments[oldNextTokenId].previousTokenId = newTokenId;
            emit MomentUnlinked(oldNextTokenId, address(0)); // Indicate unlink from previous logic
            emit MomentLinked(newTokenId, oldNextTokenId, _msgSender()); // Indicate new link
        }
        emit MomentLinked(previousTokenId, newTokenId, _msgSender());
        emit MomentMinted(
            newTokenId,
            _msgSender(),
            description,
            tokenURI,
            previousTokenId
        );

        return newTokenId;
    }

     /**
     * @dev Mints a standalone moment that is not linked to any chain initially.
     * @param description The on-chain description for the moment.
     * @param tokenURI The URI pointing to off-chain metadata.
     */
    function mintStandaloneMoment(
        string memory description,
        string memory tokenURI
    ) public whenNotPaused onlyAllowedMinter returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(_msgSender(), newTokenId);
        _moments[newTokenId] = Moment({
            timestamp: block.timestamp,
            minter: _msgSender(),
            description: description,
            previousTokenId: 0,
            nextTokenId: 0,
            isFrozen: false
        });
        _setTokenURI(newTokenId, tokenURI);

        emit MomentMinted(newTokenId, _msgSender(), description, tokenURI, 0);
        return newTokenId;
    }


    /**
     * @dev Updates the on-chain description of a moment.
     * @param tokenId The token ID to update.
     * @param newDescription The new description.
     */
    function updateMomentDescription(uint256 tokenId, string memory newDescription)
        public
        whenNotPaused
        onlyTokenOwnerOrDelegatee(tokenId)
        notFrozen(tokenId)
    {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        _moments[tokenId].description = newDescription;
        // Note: This update doesn't change the tokenURI, only the on-chain description field.
        // A dApp would read both for full context.
        emit MomentUpdated(tokenId, _msgSender(), newDescription, tokenURI(tokenId));
    }

    /**
     * @dev Updates the off-chain metadata URI of a moment.
     * @param tokenId The token ID to update.
     * @param newTokenURI The new URI.
     */
    function updateMomentURI(uint256 tokenId, string memory newTokenURI)
        public
        whenNotPaused
        onlyTokenOwner(tokenId)
        notFrozen(tokenId)
    {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        _setTokenURI(tokenId, newTokenURI);
        emit MomentUpdated(tokenId, _msgSender(), _moments[tokenId].description, newTokenURI);
    }

    /**
     * @dev Freezes a single moment, preventing further updates to its description or URI.
     * @param tokenId The token ID to freeze.
     */
    function freezeMoment(uint256 tokenId) public onlyTokenOwner(tokenId) {
        if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        if (_moments[tokenId].isFrozen) {
            // Already frozen, do nothing or revert
             revert ChronicleNFT__MomentFrozen();
        }
        _moments[tokenId].isFrozen = true;
        emit MomentFrozen(tokenId, _msgSender());
    }

    /**
     * @dev Freezes an entire chronicle chain, preventing updates to any moment within it.
     * @param startTokenId The token ID of the start of the chain.
     */
    function freezeChronicleChain(uint256 startTokenId) public onlyChainOwner(startTokenId) {
         if (_isChainFrozen[startTokenId]) {
             revert ChronicleNFT__ChainFrozen();
         }
        _isChainFrozen[startTokenId] = true;
        emit ChainFrozen(startTokenId, _msgSender());
    }

    /**
     * @dev Burns a moment. Handles unlinking it from any chain.
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) public override(ERC721Burnable) {
        if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        // Standard ERC721Burnable checks ownership/approval
        super.burn(tokenId);

        // Unlink from neighbors before deleting moment data
        uint256 prev = _moments[tokenId].previousTokenId;
        uint256 next = _moments[tokenId].nextTokenId;

        if (prev != 0) {
            _moments[prev].nextTokenId = next;
        }
        if (next != 0) {
            _moments[next].previousTokenId = prev;
        }

        // Clean up delegation data
        delete _descriptionUpdateDelegatee[tokenId];

        // Delete the moment data
        delete _moments[tokenId];

        emit MomentUnlinked(tokenId, _msgSender()); // Indicate it was removed from chain context
    }

    // --- Chronicle Linking Functions ---

    /**
     * @dev Links two existing standalone moments, or links the second moment after the first.
     * Requires ownership of both tokens and they must not be frozen or part of frozen chains.
     * @param firstTokenId The token ID of the moment that will be first.
     * @param secondTokenId The token ID of the moment that will be second.
     */
    function linkMoments(uint256 firstTokenId, uint256 secondTokenId)
        public
        whenNotPaused
        onlyTokenOwner(firstTokenId)
        onlyTokenOwner(secondTokenId)
    {
        if (firstTokenId == secondTokenId) {
            revert ChronicleNFT__CannotLinkToSelf();
        }
        if (!_exists(firstTokenId) || !_exists(secondTokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
         if (_moments[firstTokenId].isFrozen || _moments[secondTokenId].isFrozen) {
             revert ChronicleNFT__CannotLinkFrozenMoment();
         }
         if (isChainFrozen(getChainStart(firstTokenId)) || isChainFrozen(getChainStart(secondTokenId))) {
              revert ChronicleNFT__CannotLinkFrozenMoment();
         }


        // Ensure they are not already linked in a way that conflicts
        if (_moments[firstTokenId].nextTokenId != 0 || _moments[secondTokenId].previousTokenId != 0) {
             revert ChronicleNFT__LinkAlreadyExists();
        }

        // Link first -> second
        _moments[firstTokenId].nextTokenId = secondTokenId;
        _moments[secondTokenId].previousTokenId = firstTokenId;

        emit MomentLinked(firstTokenId, secondTokenId, _msgSender());
    }

    /**
     * @dev Inserts a standalone moment into an existing chain between two moments.
     * Requires ownership of all three tokens and they must not be frozen or part of frozen chains.
     * @param firstTokenId The token ID of the moment before the insertion point.
     * @param newMiddleTokenId The token ID of the moment to insert.
     * @param thirdTokenId The token ID of the moment after the insertion point.
     */
    function insertMomentBetween(
        uint256 firstTokenId,
        uint256 newMiddleTokenId,
        uint256 thirdTokenId
    )
        public
        whenNotPaused
        onlyTokenOwner(firstTokenId)
        onlyTokenOwner(newMiddleTokenId)
        onlyTokenOwner(thirdTokenId)
    {
         if (firstTokenId == newMiddleTokenId || firstTokenId == thirdTokenId || newMiddleTokenId == thirdTokenId) {
            revert ChronicleNFT__CannotLinkToSelf();
        }
         if (!_exists(firstTokenId) || !_exists(newMiddleTokenId) || !_exists(thirdTokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        if (_moments[firstTokenId].isFrozen || _moments[newMiddleTokenId].isFrozen || _moments[thirdTokenId].isFrozen) {
             revert ChronicleNFT__CannotLinkFrozenMoment();
        }
         if (isChainFrozen(getChainStart(firstTokenId)) || isChainFrozen(getChainStart(newMiddleTokenId)) || isChainFrozen(getChainStart(thirdTokenId))) {
              revert ChronicleNFT__CannotLinkFrozenMoment();
         }

        // Ensure first and third are linked, and newMiddle is standalone
        if (_moments[firstTokenId].nextTokenId != thirdTokenId || _moments[thirdTokenId].previousTokenId != firstTokenId) {
             // Not a direct link, or mismatch
             revert ChronicleNFT__LinkAlreadyExists(); // Use existing error, indicates incorrect linking structure
        }
         if (_moments[newMiddleTokenId].previousTokenId != 0 || _moments[newMiddleTokenId].nextTokenId != 0) {
             revert ChronicleNFT__LinkAlreadyExists(); // New moment is not standalone
         }

        // Break link first -> third
        _moments[firstTokenId].nextTokenId = 0;
        _moments[thirdTokenId].previousTokenId = 0;
        emit MomentUnlinked(firstTokenId, address(0)); // Indicate break for first -> third
        emit MomentUnlinked(thirdTokenId, address(0)); // Indicate break for third <- first

        // Link first -> newMiddle -> third
        _moments[firstTokenId].nextTokenId = newMiddleTokenId;
        _moments[newMiddleTokenId].previousTokenId = firstTokenId;
        _moments[newMiddleTokenId].nextTokenId = thirdTokenId;
        _moments[thirdTokenId].previousTokenId = newMiddleTokenId;

        emit MomentLinked(firstTokenId, newMiddleTokenId, _msgSender());
        emit MomentLinked(newMiddleTokenId, thirdTokenId, _msgSender());
    }

    /**
     * @dev Unlinks a moment from its neighbors in a chain. Its neighbors will be linked directly.
     * The moment becomes standalone unless it was the start or end of the chain.
     * Requires ownership of the moment and it must not be frozen or part of a frozen chain.
     * @param tokenId The token ID to unlink.
     */
    function unlinkMoment(uint256 tokenId)
        public
        whenNotPaused
        onlyTokenOwner(tokenId)
        notFrozen(tokenId)
    {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        uint256 prev = _moments[tokenId].previousTokenId;
        uint256 next = _moments[tokenId].nextTokenId;

        if (prev == 0 && next == 0) {
            revert ChronicleNFT__CannotUnlinkStandalone();
        }

        // Update neighbors
        if (prev != 0) {
            _moments[prev].nextTokenId = next;
        }
        if (next != 0) {
            _moments[next].previousTokenId = prev;
        }

        // Clear links for the token being unlinked
        _moments[tokenId].previousTokenId = 0;
        _moments[tokenId].nextTokenId = 0;

        emit MomentUnlinked(tokenId, _msgSender());
        if (prev != 0 && next != 0) {
             emit MomentLinked(prev, next, _msgSender()); // Indicate neighbors are now linked
        }
    }


    // --- Delegation Functions ---

    /**
     * @dev Allows the token owner to delegate the right to update the moment's description.
     * @param tokenId The token ID.
     * @param delegatee The address to delegate the right to. Set to address(0) to remove.
     */
    function delegateDescriptionUpdateRights(uint256 tokenId, address delegatee)
        public
        onlyTokenOwner(tokenId)
    {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        if (_descriptionUpdateDelegatee[tokenId] == delegatee) {
            revert ChronicleNFT__AlreadyDelegatee();
        }
        _descriptionUpdateDelegatee[tokenId] = delegatee;
        emit DescriptionUpdateDelegated(tokenId, _msgSender(), delegatee);
    }

    /**
     * @dev Removes the description update delegation for a moment.
     * Callable by the token owner or the current delegatee.
     * @param tokenId The token ID.
     */
    function removeDescriptionUpdateDelegation(uint256 tokenId) public {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        address currentDelegatee = _descriptionUpdateDelegatee[tokenId];
        address tokenOwner = ownerOf(tokenId);

        if (_msgSender() != tokenOwner && _msgSender() != currentDelegatee) {
            revert ChronicleNFT__UnauthorizedUpdate(); // Not owner or delegatee
        }
         if (currentDelegatee == address(0)) {
             revert ChronicleNFT__NotDelegatee(); // No delegation exists
         }

        delete _descriptionUpdateDelegatee[tokenId];
        emit DescriptionUpdateDelegationRemoved(tokenId, _msgSender());
    }

    // --- Snapshot Function ---

    /**
     * @dev Generates a unique hash representing the current state of a chronicle chain.
     * State includes the sequence of token IDs, their frozen status, and their current URIs.
     * Note: This function's gas cost scales linearly with the chain length.
     * @param startTokenId The token ID of the start of the chain.
     * @return A keccak256 hash representing the chain's state.
     */
    function createChainSnapshotHash(uint256 startTokenId)
        public
        view
        returns (bytes32)
    {
        if (!_exists(startTokenId) || _moments[startTokenId].previousTokenId != 0) {
             revert ChronicleNFT__InvalidChainStart();
        }

        bytes memory data;
        uint256 currentTokenId = startTokenId;
        uint256 length = 0;

        // Collect data for hashing: token ID, frozen status, and tokenURI
        while (currentTokenId != 0) {
            // Using abi.encodePacked is gas-efficient for hashing
            data = abi.encodePacked(data, currentTokenId, _moments[currentTokenId].isFrozen, tokenURI(currentTokenId));
            currentTokenId = _moments[currentTokenId].nextTokenId;
            length++;
            // Basic safety check against infinite loops if linking logic failed somehow
            require(length <= _nextTokenId, "ChronicleNFT: Chain traversal error");
        }

        bytes32 snapshotHash = keccak256(data);

        // Note: Emit event might be too gas heavy if called frequently for long chains
        // emit ChainSnapshotTaken(startTokenId, snapshotHash); // Optional: emit event

        return snapshotHash;
    }


    // --- Read Functions ---

    /**
     * @dev Returns the core details of a moment.
     * @param tokenId The token ID.
     * @return Moment struct data.
     */
    function getMomentDetails(uint256 tokenId)
        public
        view
        returns (Moment memory)
    {
        if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        return _moments[tokenId];
    }

    /**
     * @dev Returns the token ID of the previous moment in the chain.
     * @param tokenId The token ID.
     * @return The previous token ID (0 if none).
     */
    function getPreviousMoment(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        return _moments[tokenId].previousTokenId;
    }

    /**
     * @dev Returns the token ID of the next moment in the chain.
     * @param tokenId The token ID.
     * @return The next token ID (0 if none).
     */
    function getNextMoment(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        return _moments[tokenId].nextTokenId;
    }

    /**
     * @dev Checks if a specific moment is individually frozen.
     * @param tokenId The token ID.
     * @return True if frozen, false otherwise.
     */
    function isMomentFrozen(uint256 tokenId) public view returns (bool) {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        return _moments[tokenId].isFrozen;
    }

     /**
     * @dev Checks if the entire chain starting from startTokenId is frozen.
     * @param startTokenId The token ID of the start of the chain.
     * @return True if chain is frozen, false otherwise.
     */
    function isChainFrozen(uint256 startTokenId) public view returns (bool) {
         if (!_exists(startTokenId) || _moments[startTokenId].previousTokenId != 0) {
             revert ChronicleNFT__InvalidChainStart();
         }
        return _isChainFrozen[startTokenId];
    }

    /**
     * @dev Returns the address delegated description update rights for a moment.
     * @param tokenId The token ID.
     * @return The delegatee address (address(0) if none).
     */
    function getDescriptionUpdateDelegatee(uint256 tokenId)
        public
        view
        returns (address)
    {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        return _descriptionUpdateDelegatee[tokenId];
    }

    /**
     * @dev Finds the starting token ID of the chain a moment belongs to.
     * Note: This function's gas cost scales linearly with the chain length backward.
     * @param tokenId The token ID.
     * @return The start token ID (tokenId itself if standalone or already the start).
     */
    function getChainStart(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        uint256 currentToken = tokenId;
        uint256 previousToken = _moments[currentToken].previousTokenId;
        uint256 safetyCounter = 0;
        // Traverse backwards until previousTokenId is 0
        while (previousToken != 0) {
            currentToken = previousToken;
            previousToken = _moments[currentToken].previousTokenId;
            safetyCounter++;
             require(safetyCounter <= _nextTokenId, "ChronicleNFT: Chain traversal error");
        }
        return currentToken;
    }

     /**
     * @dev Calculates the length of the chain a moment belongs to.
     * Note: This function's gas cost scales linearly with the chain length.
     * @param tokenId The token ID.
     * @return The length of the chain.
     */
    function getChainLength(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert ChronicleNFT__TokenDoesNotExist();
        }
        uint256 startToken = getChainStart(tokenId); // Find the start
        uint256 currentToken = startToken;
        uint256 length = 0;
        uint256 safetyCounter = 0;

        // Traverse forward from the start
        while (currentToken != 0) {
            length++;
            currentToken = _moments[currentToken].nextTokenId;
             safetyCounter++;
             require(safetyCounter <= _nextTokenId, "ChronicleNFT: Chain traversal error");
        }
        return length;
    }

    // --- Internal Helper Functions ---
    // _beforeTokenTransfer is overridden above.
    // _safeMint and _burn are used internally by public functions.
    // _setTokenURI is inherited from ERC721URIStorage.
    // _setDefaultRoyalty, _setTokenRoyaltyInfo used internally by ERC2981 functions.
}
```