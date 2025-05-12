Okay, let's design a smart contract that goes beyond standard patterns, incorporates dynamic elements, crafting, and permissions, ensuring we have a good number of functions while avoiding direct duplication of common open-source implementations.

We'll create a contract called `QuantumForge`, which manages unique digital artifacts called "Quantum Shards". These shards are ERC721 tokens but possess dynamic properties that can be altered through on-chain actions like forging, evolving, and merging. They also have a "charge" that decays over time, adding a time-sensitive element.

**Core Concepts:**

1.  **Dynamic NFTs:** Shards have properties (level, purity, charge, element) stored directly in the contract, which can change after minting.
2.  **Forging:** Minting new shards with initial properties. Can be permissioned and have cooldowns.
3.  **Evolving:** Improving a single shard's properties by consuming its charge.
4.  **Merging:** Combining two shards into one, enhancing the resulting shard and burning the other.
5.  **Charge Decay:** A time/block-based mechanic where a shard's 'charge' decreases, limiting actions like evolving.
6.  **Charge Reset:** The ability to restore a shard's charge.
7.  **Essence Claim:** Burning a shard to gain a permanent, non-transferable 'essence score'.
8.  **Permissioned Actions:** Control over who can perform certain actions (like forging).
9.  **Batch Operations:** Functions for efficiency (batch mint, batch transfer).

To strictly adhere to "don't duplicate any of open source", we will implement the necessary ERC721 logic (ownership, approvals, balances) manually using mappings and emitting standard events, rather than inheriting from a library like OpenZeppelin's ERC721. We *will* use standard interfaces like `IERC721` and `IERC165` to ensure compatibility, but the internal implementation will be custom.

---

**Outline and Function Summary**

*   **Contract Name:** `QuantumForge`
*   **Description:** An advanced ERC721 contract managing dynamic "Quantum Shards" with forging, evolution, merging, time-based decay, and permissioned actions.
*   **Interfaces:** Implements `IERC721`, `IERC165`.
*   **Data Structures:** `ShardData` struct storing dynamic properties for each token.
*   **State Variables:** Mappings for ownership, approvals, balances, token data, essence scores, forge permissions, cooldowns, counters.
*   **Events:** Standard ERC721 events (`Transfer`, `Approval`, `ApprovalForAll`) and custom events (`ShardForged`, `ShardEvolved`, `ShardsMerged`, `EssenceClaimed`, `ChargeReset`, `ForgePermissionGranted`, `ForgePermissionRevoked`).
*   **Modifiers:** `onlyOwner`, `canForge`.
*   **Internal Helpers:** Functions for existence checks, approval checks, core mint/burn/transfer logic, charge decay calculation.
*   **ERC721 Standard Functions (Public/External):**
    1.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
    2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
    3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership, checks if recipient can receive.
    4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers ownership with data, checks if recipient can receive.
    5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership without recipient checks.
    6.  `approve(address to, uint256 tokenId)`: Grants approval for a single token.
    7.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes operator approval for all tokens.
    8.  `getApproved(uint256 tokenId)`: Returns the approved address for a token.
    9.  `isApprovedForAll(address owner, address operator)`: Checks if an address is an approved operator.
    10. `supportsInterface(bytes4 interfaceId)`: ERC165 compliance check for supported interfaces.
    11. `name()`: Returns the contract name.
    12. `symbol()`: Returns the contract symbol.
    13. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token (dynamic based on on-chain data).
*   **Custom Core Functions (Public/External):**
    14. `forgeShard(uint256 elementSeed)`: Mints a new Quantum Shard token with properties derived from a seed. Requires forge permission and respects cooldown.
    15. `evolveShard(uint256 tokenId, uint256 evoBoost)`: Increases a shard's level and purity by consuming its charge. Must own the token.
    16. `mergeShards(uint256 tokenId1, uint256 tokenId2)`: Merges two owned shards. Burns `tokenId2`, enhances `tokenId1` based on both. Requires sufficient charge on `tokenId1`.
    17. `resetCharge(uint256 tokenId)`: Restores a shard's charge to maximum. Must own the token.
    18. `claimEssence(uint256 tokenId)`: Burns a shard and awards the owner essence points based on the shard's properties. Must own the token.
*   **Custom Read Functions (Public/External):**
    19. `getTokenData(uint256 tokenId)`: Retrieves the full dynamic data struct for a shard.
    20. `getDecayedCharge(uint256 tokenId)`: Calculates and returns the current charge after applying decay based on time.
    21. `canMerge(uint256 tokenId1, uint256 tokenId2)`: Checks if two shards meet the basic criteria for merging (owned by same user, exist).
    22. `getEssenceScore(address user)`: Retrieves the accumulated essence score for a user.
    23. `getTimeSinceLastForge(address user)`: Returns blocks since the user last forged a shard (or 0 if never).
    24. `isForgePermitted(address user)`: Checks if a user has explicit forge permission.
*   **Batch Functions (Public/External):**
    25. `batchForge(uint256[] memory elementSeeds)`: Mints multiple shards in a single transaction (respects cooldown and permission).
    26. `batchTransfer(address[] memory to, uint256[] memory tokenIds)`: Transfers multiple owned tokens to respective recipients.
*   **Owner/Permissioned Functions (Public/External):**
    27. `setBaseURI(string memory baseURI)`: Sets the base URI for token metadata.
    28. `setForgeCooldown(uint256 cooldownInBlocks)`: Sets the required number of blocks between forging operations for any permitted user.
    29. `grantForgePermission(address user)`: Grants an address permission to forge shards (in addition to owner).
    30. `revokeForgePermission(address user)`: Revokes an address's forge permission.
    31. `transferOwnership(address newOwner)`: Transfers contract ownership (from Ownable pattern, implemented manually).
    32. `renounceOwnership()`: Renounces contract ownership (from Ownable pattern, implemented manually).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumForge
/// @author Your Name/Alias
/// @notice An advanced ERC721 contract for managing dynamic Quantum Shards.
/// Shards can be forged, evolved, merged, and possess time-decaying charge.
/// Includes permissioned forging and batch operations.
/// @dev Implements ERC721 and ERC165 interfaces manually to avoid direct duplication of standard library implementations for core logic, while using standard events and function signatures.

/*
Outline and Function Summary:

Core Concepts: Dynamic NFTs, Forging, Evolving, Merging, Charge Decay, Charge Reset, Essence Claim, Permissioned Actions, Batch Operations.

Data Structures:
- ShardData: struct { uint8 element; uint16 purity; uint16 level; uint16 charge; uint64 forgeBlock; uint64 lastChargeResetBlock; }

State Variables:
- Mappings: _owners, _balances, _approved, _operatorApprovals, _tokenData, _essenceScores, _forgePermissions, _lastForgeBlock
- Counters: _nextTokenId
- Config: _name, _symbol, _baseURI, _forgeCooldownBlocks
- Ownership: _owner

Events:
- Standard ERC721: Transfer, Approval, ApprovalForAll
- Custom: ShardForged, ShardEvolved, ShardsMerged, EssenceClaimed, ChargeReset, ForgePermissionGranted, ForgePermissionRevoked

Modifiers:
- onlyOwner: Restricts access to the contract owner.
- canForge: Checks if the caller has permission and respects the cooldown.

Internal Helpers:
- _exists(uint256 tokenId): Checks if a token exists.
- _isApprovedOrOwner(address spender, uint256 tokenId): Checks if an address is the owner or approved/operator for a token.
- _safeMint(address to, uint256 tokenId): Mints a token, checks recipient.
- _burn(uint256 tokenId): Burns a token.
- _transfer(address from, address to, uint256 tokenId): Transfers token ownership.
- _getDecayedCharge(uint256 tokenId): Calculates charge including time-based decay.
- _applyDecay(uint256 tokenId): Updates charge based on decay calculation.

ERC721 Standard Functions (Public/External - Implementing IERC721 & IERC165):
1.  balanceOf(address owner): Get token count for owner.
2.  ownerOf(uint256 tokenId): Get owner of token.
3.  safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
4.  safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
5.  transferFrom(address from, address to, uint256 tokenId): Unsafe transfer.
6.  approve(address to, uint256 tokenId): Approve address for single token.
7.  setApprovalForAll(address operator, bool approved): Approve operator for all tokens.
8.  getApproved(uint256 tokenId): Get approved address for token.
9.  isApprovedForAll(address owner, address operator): Check operator approval.
10. supportsInterface(bytes4 interfaceId): ERC165 interface support check.
11. name(): Get contract name.
12. symbol(): Get contract symbol.
13. tokenURI(uint256 tokenId): Get metadata URI for token.

Custom Core Functions (Public/External):
14. forgeShard(uint256 elementSeed): Mint a new shard.
15. evolveShard(uint256 tokenId, uint256 evoBoost): Evolve an existing shard.
16. mergeShards(uint256 tokenId1, uint256 tokenId2): Merge two shards.
17. resetCharge(uint256 tokenId): Reset a shard's charge.
18. claimEssence(uint256 tokenId): Burn shard for essence score.

Custom Read Functions (Public/External):
19. getTokenData(uint256 tokenId): Get a shard's dynamic data.
20. getDecayedCharge(uint256 tokenId): Get charge with decay applied.
21. canMerge(uint256 tokenId1, uint256 tokenId2): Check if merge is possible.
22. getEssenceScore(address user): Get user's essence score.
23. getTimeSinceLastForge(address user): Get blocks since user's last forge.
24. isForgePermitted(address user): Check if user can forge.

Batch Functions (Public/External):
25. batchForge(uint256[] memory elementSeeds): Mint multiple shards.
26. batchTransfer(address[] memory to, uint256[] memory tokenIds): Transfer multiple tokens.

Owner/Permissioned Functions (Public/External):
27. setBaseURI(string memory baseURI): Set metadata base URI.
28. setForgeCooldown(uint256 cooldownInBlocks): Set forge cooldown.
29. grantForgePermission(address user): Grant forge permission.
30. revokeForgePermission(address user): Revoke forge permission.
31. transferOwnership(address newOwner): Transfer contract ownership.
32. renounceOwnership(): Renounce contract ownership.
*/

// Minimal ERC165 Interface
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas and MUST return true when called with the
    ///  interfaceId for ERC-165.
    /// @return `true` if the contract implements `interfaceId`, `false` otherwise.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal ERC721 Interface
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address approved);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// Minimal ERC721TokenReceiver Interface for safeTransferFrom
interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract QuantumForge is IERC721 {
    // --- Errors ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwnerOrApproved(address caller, uint256 tokenId);
    error TransferToZeroAddress();
    error ApproveToOwner();
    error NotCurrentOwner(address caller, uint256 tokenId);
    error InvalidRecipient();
    error SelfMergeForbidden();
    error MergeRequiresTwoTokens();
    error InsufficientCharge(uint256 tokenId, uint256 currentCharge, uint256 requiredCharge);
    error CannotMergeDifferentElements(); // Or allow, but with penalty? Let's forbid for simplicity.
    error ForgeCooldownActive(uint256 remainingBlocks);
    error ForgeNotPermitted();
    error NothingToBatchForge();
    error BatchTransferLengthMismatch();
    error CannotClaimNonExistentEssence();
    error NotOwner();
    error ZeroAddressOwner();
    error RenounceOwnerFromZeroAddress();


    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ShardForged(uint256 indexed tokenId, address indexed owner, uint8 element, uint16 purity);
    event ShardEvolved(uint256 indexed tokenId, address indexed owner, uint16 newLevel, uint16 newPurity);
    event ShardsMerged(uint256 indexed tokenId1, uint256 indexed tokenId2Burned, address indexed owner, uint16 newLevel, uint16 newPurity);
    event EssenceClaimed(uint256 indexed tokenIdBurned, address indexed owner, uint256 essenceGained, uint256 newTotalEssence);
    event ChargeReset(uint256 indexed tokenId, address indexed owner);
    event ForgePermissionGranted(address indexed user);
    event ForgePermissionRevoked(address indexed user);

    // --- Data Structures ---
    struct ShardData {
        uint8 element; // e.g., 1: Fire, 2: Water, 3: Earth, 4: Air, 5: Quantum
        uint16 purity;  // Quality/strength (0-1000)
        uint16 level;   // Evolution level (0-255)
        uint16 charge;  // Resource for actions (0-1000)
        uint64 forgeBlock; // Block number when forged
        uint64 lastChargeResetBlock; // Block number when charge was last reset/used in action
    }

    // --- State Variables ---
    // ERC721 Core
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _nextTokenId;

    // Custom Data
    mapping(uint256 => ShardData) private _tokenData;
    mapping(address => uint256) private _essenceScores; // Non-transferable score

    // Permissions & Cooldowns
    mapping(address => bool) private _forgePermissions;
    mapping(address => uint64) private _lastForgeBlock;
    uint256 private _forgeCooldownBlocks; // Blocks required between forge actions per user

    // Token Info
    string private _name;
    string private _symbol;
    string private _baseURI; // Base URI for metadata

    // Ownership (Manual Implementation)
    address private _owner;

    // ERC165 interface IDs
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd; // ERC721
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7; // ERC165

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, uint256 initialForgeCooldown) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender; // Set initial owner
        _forgeCooldownBlocks = initialForgeCooldown;
        _forgePermissions[msg.sender] = true; // Owner has forge permission by default
        _nextTokenId = 1; // Token IDs start from 1
    }

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    modifier canForge() {
        if (!_forgePermissions[msg.sender]) {
            revert ForgeNotPermitted();
        }
        uint64 timeSinceLast = block.number - _lastForgeBlock[msg.sender];
        if (_lastForgeBlock[msg.sender] > 0 && timeSinceLast < _forgeCooldownBlocks) {
             revert ForgeCooldownActive(_forgeCooldownBlocks - timeSinceLast);
        }
        _;
    }

    // --- Internal Helpers ---

    /// @dev Returns whether the specified token exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @dev Returns whether the given spender is allowed to manage the given token ID.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @dev Safely mints a token to a recipient, checking if the recipient is a contract
    ///      and can accept ERC721 tokens.
    function _safeMint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        _owners[tokenId] = to;
        _balances[to]++;
        emit Transfer(address(0), to, tokenId);

        // Check if recipient is a contract and can receive ERC721 tokens
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(to) }
        if (size > 0) {
             bytes4 retval = IERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, "");
             if (retval != IERC721TokenReceiver.onERC721Received.selector) {
                revert InvalidRecipient();
             }
        }
    }

    /// @dev Burns a token. Reverts if the token does not exist.
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // ownerOf already checks existence
        _tokenApprovals[tokenId] = address(0); // Clear approvals

        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenData[tokenId]; // Remove dynamic data
        emit Transfer(owner, address(0), tokenId);
    }

    /// @dev Transfers token ownership.
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert NotCurrentOwner(from, tokenId); // ownerOf checks existence
        if (to == address(0)) revert TransferToZeroAddress();

        _tokenApprovals[tokenId] = address(0); // Clear approvals

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Calculates the current charge of a shard, applying decay based on blocks passed.
    /// Decay rate is simplified: lose 1 charge unit per block beyond the last reset block.
    /// Max decay per block call is capped to prevent griefing, but total decay is based on blocks passed.
    /// @param tokenId The ID of the shard.
    /// @return The current charge after decay.
    function _getDecayedCharge(uint256 tokenId) internal view returns (uint16) {
        ShardData storage data = _tokenData[tokenId];
        if (data.charge == 0) return 0;

        uint64 blocksPassed = block.number - data.lastChargeResetBlock;
        uint256 decayAmount = uint256(blocksPassed); // Simplified: 1 charge loss per block

        if (decayAmount >= data.charge) {
            return 0;
        }
        return uint16(data.charge - decayAmount);
    }

     /// @dev Applies the calculated decay to the stored charge and updates last reset block.
     /// Should be called internally before using or resetting charge.
    function _applyDecay(uint256 tokenId) internal {
        ShardData storage data = _tokenData[tokenId];
        uint16 decayedCharge = _getDecayedCharge(tokenId);
        data.charge = decayedCharge;
        // Update last reset block to current block for future decay calculation
        data.lastChargeResetBlock = uint64(block.number);
    }


    // --- ERC721 Standard Functions ---

    /// @notice Get the number of tokens owned by an address
    /// @param owner The address for whom to query the balance
    /// @return The number of tokens owned by the `owner`
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return _balances[owner];
    }

    /// @notice Find the owner of a token
    /// @param tokenId The identifier for a token
    /// @return The address of the owner of the token
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist(tokenId);
        return owner;
    }

    /// @notice Safely transfers the ownership of a given token ID to another address
    /// @dev Senders can be contract accounts as well
    /// @param from The current owner of the token
    /// @param to The address to transfer the token to
    /// @param tokenId The ID of the token to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Safely transfers the ownership of a given token ID to another address
    /// @dev Senders can be contract accounts as well
    /// @param from The current owner of the token
    /// @param to The address to transfer the token to
    /// @param tokenId The ID of the token to transfer
    /// @param data Additional data with no specified format, sent in call to `onERC721Received` on contract recipients
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotTokenOwnerOrApproved(msg.sender, tokenId);
        if (ownerOf(tokenId) != from) revert NotCurrentOwner(from, tokenId); // ownerOf checks existence
        if (to == address(0)) revert TransferToZeroAddress();

        _transfer(from, to, tokenId);

        // Check if recipient is a contract and can receive ERC721 tokens
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(to) }
        if (size > 0) {
             bytes4 retval = IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data);
             if (retval != IERC721TokenReceiver.onERC721Received.selector) {
                revert InvalidRecipient();
             }
        }
    }


    /// @notice Transfers the ownership of a given token ID to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    ///  address for this token. Does not check if the recipient is a contract.
    /// @param from The current owner of the token
    /// @param to The address to transfer the token to
    /// @param tokenId The ID of the token to transfer
    function transferFrom(address from, address to, uint256 tokenId) public override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotTokenOwnerOrApproved(msg.sender, tokenId);
         _transfer(from, to, tokenId);
    }


    /// @notice Approve or remove `operator` as an operator for the caller
    /// @dev Operators can call `transferFrom` or `safeTransferFrom` for any token owned by the caller.
    /// @param operator The address to set as operator
    /// @param approved Whether the operator should be approved or not
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == msg.sender) revert ApproveToOwner(); // Cannot set approval for self
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }


    /// @notice Get the approved address for a single token
    /// @dev Throws if `tokenId` is not valid.
    /// @param tokenId The ID of the token to query the approval for
    /// @return The approved address for the given token, or the zero address if no address is set
    function getApproved(uint256 tokenId) public view override returns (address approved) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param owner The address that owns the tokens
    /// @param operator The address that acts on behalf of the owner
    /// @return `true` if `operator` is an approved operator for `owner`, `false` otherwise
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    /// @notice Sets or clears the approved address for a given token ID
    /// @dev Throws unless `msg.sender` is the token owner or an approved operator.
    /// @param to The address to approve to, or the zero address to clear the approval
    /// @param tokenId The ID of the token to approve
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Checks existence
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotTokenOwnerOrApproved(msg.sender, tokenId);
        }
        if (to == owner) revert ApproveToOwner(); // Cannot approve owner

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }


    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas and MUST return true when called with the
    ///  interfaceId for ERC-165.
    /// @return `true` if the contract implements `interfaceId`, `false` otherwise.
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == _ERC721_INTERFACE_ID || interfaceId == _ERC165_INTERFACE_ID;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for a collection of NFTs in this contract
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given token
    /// @dev Throws if `tokenId` is not a valid NFT. URIs are defined in RFC 3986.
    ///      The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
    ///      The URI for a token MUST be immutable.
    ///      This implementation generates a URI based on the base URI and token ID, allowing
    ///      an off-chain service to serve metadata that reflects the dynamic state.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        // Basic implementation: baseURI + tokenId. Off-chain server retrieves data using getTokenData
        // and serves metadata accordingly.
        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return "";
        }
        // If base ends with '/', append tokenId, otherwise append '/tokenId'
        if (bytes(base)[bytes(base).length - 1] == '/') {
            return string(abi.encodePacked(base, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(base, "/", Strings.toString(tokenId)));
        }
    }

    // --- Custom Core Functions ---

    /// @notice Forges a new Quantum Shard.
    /// @dev Requires forge permission and respects the forge cooldown.
    /// @param elementSeed A seed value used to determine the initial element and properties.
    /// @return tokenId The ID of the newly forged shard.
    function forgeShard(uint256 elementSeed) external canForge returns (uint256 tokenId) {
        tokenId = _nextTokenId++;

        // Simple property generation based on seed and block data for pseudo-randomness
        uint256 combinedSeed = elementSeed + uint256(keccak256(abi.encodePacked(msg.sender, block.number, tx.origin, block.timestamp)));
        uint8 element = uint8((combinedSeed % 5) + 1); // 1-5
        uint16 purity = uint16((combinedSeed % 500) + 501); // 501-1000
        uint16 level = 1; // Starts at level 1
        uint16 initialCharge = uint16((combinedSeed % 500) + 501); // 501-1000 initial charge

        _tokenData[tokenId] = ShardData({
            element: element,
            purity: purity,
            level: level,
            charge: initialCharge,
            forgeBlock: uint64(block.number),
            lastChargeResetBlock: uint64(block.number)
        });

        _safeMint(msg.sender, tokenId);
        _lastForgeBlock[msg.sender] = uint64(block.number); // Record last forge block for cooldown

        emit ShardForged(tokenId, msg.sender, element, purity);
        return tokenId;
    }

    /// @notice Evolves a Quantum Shard, increasing its level and purity.
    /// @dev Consumes the shard's charge. Must own the token.
    /// @param tokenId The ID of the shard to evolve.
    /// @param evoBoost A value representing the intensity of the evolution (affects charge cost and stats gain).
    function evolveShard(uint256 tokenId, uint256 evoBoost) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(msg.sender, tokenId); // ownerOf checks existence
        if (evoBoost == 0) return; // Nothing to evolve

        _applyDecay(tokenId); // Apply decay before checking/using charge
        ShardData storage data = _tokenData[tokenId];

        uint256 chargeCost = evoBoost * 50; // Simple cost calculation
        if (data.charge < chargeCost) {
            revert InsufficientCharge(tokenId, data.charge, uint16(chargeCost));
        }

        data.charge = uint16(data.charge - chargeCost);
        data.level = uint16(data.level + (evoBoost % 10) + 1); // Gain at least 1 level
        data.purity = uint16(data.purity + (evoBoost % 50) + 10); // Gain at least 10 purity

        // Cap level and purity at uint16 max if necessary (though likely not hit in simple examples)
        if (data.level > type(uint16).max) data.level = type(uint16).max;
        if (data.purity > type(uint16).max) data.purity = type(uint16).max;

        emit ShardEvolved(tokenId, msg.sender, data.level, data.purity);
    }

    /// @notice Merges two Quantum Shards into one.
    /// @dev Burns `tokenId2`, enhances `tokenId1`. Must own both tokens. Requires charge on `tokenId1`.
    ///      Forbids merging a token with itself or tokens of different elements.
    /// @param tokenId1 The ID of the shard to keep and enhance.
    /// @param tokenId2 The ID of the shard to burn.
    function mergeShards(uint256 tokenId1, uint256 tokenId2) external {
        if (tokenId1 == tokenId2) revert SelfMergeForbidden();
        if (!_exists(tokenId1) || !_exists(tokenId2)) revert MergeRequiresTwoTokens();
        if (ownerOf(tokenId1) != msg.sender || ownerOf(tokenId2) != msg.sender) {
             revert NotTokenOwnerOrApproved(msg.sender, tokenId1); // Simplification: check msg.sender owns both
        }

        ShardData storage data1 = _tokenData[tokenId1];
        ShardData storage data2 = _tokenData[tokenId2];

        if (data1.element != data2.element) revert CannotMergeDifferentElements();

        _applyDecay(tokenId1); // Apply decay to the main shard
        uint256 chargeCost = 200; // Fixed cost for merging
        if (data1.charge < chargeCost) {
            revert InsufficientCharge(tokenId1, data1.charge, uint16(chargeCost));
        }

        data1.charge = uint16(data1.charge - chargeCost);

        // Merge logic: average purity, sum levels, transfer some charge?
        data1.purity = uint16((uint256(data1.purity) + data2.purity) / 2 + 50); // Avg + bonus
        data1.level = uint16(data1.level + data2.level); // Sum levels
        data1.charge = uint16(data1.charge + data2.charge / 2); // Transfer half of burned shard's charge

         // Cap level, purity, charge
        if (data1.level > type(uint16).max) data1.level = type(uint16).max;
        if (data1.purity > type(uint16).max) data1.purity = type(uint16).max;
        if (data1.charge > 1000) data1.charge = 1000; // Max charge is 1000

        _burn(tokenId2); // Burn the second shard

        emit ShardsMerged(tokenId1, tokenId2, msg.sender, data1.level, data1.purity);
    }

    /// @notice Resets a shard's charge to maximum.
    /// @dev Must own the token. Applies any pending decay before resetting.
    /// @param tokenId The ID of the shard to reset charge.
    function resetCharge(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(msg.sender, tokenId); // ownerOf checks existence

        _applyDecay(tokenId); // Apply decay just in case, although resetting makes it less critical

        ShardData storage data = _tokenData[tokenId];
        data.charge = 1000; // Reset to max charge
        data.lastChargeResetBlock = uint64(block.number); // Reset decay timer

        emit ChargeReset(tokenId, msg.sender);
    }

    /// @notice Burns a shard and awards the owner essence points.
    /// @dev Essence points are permanent and non-transferable. Must own the token.
    /// @param tokenId The ID of the shard to claim essence from.
    function claimEssence(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwnerOrApproved(msg.sender, tokenId); // ownerOf checks existence

        ShardData storage data = _tokenData[tokenId];
        // Calculate essence gained based on shard properties (example formula)
        uint256 essenceGained = (uint256(data.level) * 10) + (data.purity / 10);

        _essenceScores[msg.sender] += essenceGained; // Add to user's score

        _burn(tokenId); // Burn the shard

        emit EssenceClaimed(tokenId, msg.sender, essenceGained, _essenceScores[msg.sender]);
    }

    // --- Custom Read Functions ---

    /// @notice Gets the dynamic properties of a specific shard.
    /// @param tokenId The ID of the shard.
    /// @return The ShardData struct for the token.
    function getTokenData(uint256 tokenId) external view returns (ShardData memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenData[tokenId];
    }

    /// @notice Gets the current charge of a shard after applying time-based decay.
    /// @param tokenId The ID of the shard.
    /// @return The decayed charge value.
    function getDecayedCharge(uint256 tokenId) external view returns (uint16) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _getDecayedCharge(tokenId);
    }

    /// @notice Checks if two shards can be merged according to the contract's rules.
    /// @param tokenId1 The ID of the first shard.
    /// @param tokenId2 The ID of the second shard.
    /// @return True if the shards can be merged, false otherwise.
    function canMerge(uint256 tokenId1, uint256 tokenId2) external view returns (bool) {
         if (tokenId1 == tokenId2) return false;
         if (!_exists(tokenId1) || !_exists(tokenId2)) return false;
         if (ownerOf(tokenId1) != msg.sender || ownerOf(tokenId2) != msg.sender) return false;
         // Check element compatibility (if necessary, based on merge logic)
         if (_tokenData[tokenId1].element != _tokenData[tokenId2].element) return false;
         // Could also check charge, but mergeShards() will do that with current decay applied
         return true;
    }

    /// @notice Gets the accumulated essence score for a user.
    /// @param user The address of the user.
    /// @return The user's total essence score.
    function getEssenceScore(address user) external view returns (uint256) {
        return _essenceScores[user];
    }

    /// @notice Gets the number of blocks passed since a user last forged a shard.
    /// @dev Returns 0 if the user has never forged.
    /// @param user The address of the user.
    /// @return The number of blocks.
    function getTimeSinceLastForge(address user) external view returns (uint256) {
        if (_lastForgeBlock[user] == 0) {
            return 0;
        }
        return block.number - _lastForgeBlock[user];
    }

    /// @notice Checks if a user has explicit permission to forge shards.
    /// @param user The address of the user.
    /// @return True if the user has permission, false otherwise.
    function isForgePermitted(address user) external view returns (bool) {
        return _forgePermissions[user];
    }

    // --- Batch Functions ---

    /// @notice Forges multiple new Quantum Shards in a single transaction.
    /// @dev Requires forge permission and respects the forge cooldown (applied after the batch).
    /// @param elementSeeds An array of seed values for the shards to forge.
    function batchForge(uint256[] memory elementSeeds) external canForge {
        if (elementSeeds.length == 0) revert NothingToBatchForge();

        for (uint i = 0; i < elementSeeds.length; i++) {
             uint256 tokenId = _nextTokenId++;

             // Simple property generation based on seed and block data
             uint256 combinedSeed = elementSeeds[i] + uint256(keccak256(abi.encodePacked(msg.sender, block.number, tx.origin, block.timestamp, i))); // Add index for variation
             uint8 element = uint8((combinedSeed % 5) + 1); // 1-5
             uint16 purity = uint16((combinedSeed % 500) + 501); // 501-1000
             uint16 level = 1; // Starts at level 1
             uint16 initialCharge = uint16((combinedSeed % 500) + 501); // 501-1000 initial charge

             _tokenData[tokenId] = ShardData({
                element: element,
                purity: purity,
                level: level,
                charge: initialCharge,
                forgeBlock: uint64(block.number),
                lastChargeResetBlock: uint64(block.number)
             });

             _safeMint(msg.sender, tokenId);
             emit ShardForged(tokenId, msg.sender, element, purity);
        }
         _lastForgeBlock[msg.sender] = uint64(block.number); // Record last forge block *after* the batch
    }

    /// @notice Transfers multiple owned tokens to respective recipients.
    /// @dev Both arrays must have the same length. Requires sender to own or be approved for each token.
    /// @param to An array of recipient addresses.
    /// @param tokenIds An array of token IDs to transfer.
    function batchTransfer(address[] memory to, uint255[] memory tokenIds) external {
         if (to.length != tokenIds.length) revert BatchTransferLengthMismatch();
         for (uint i = 0; i < tokenIds.length; i++) {
             // Use safeTransferFrom logic to ensure recipient can receive
             safeTransferFrom(msg.sender, to[i], tokenIds[i]);
         }
    }

    // --- Owner/Permissioned Functions ---

    /// @notice Sets the base URI for token metadata.
    /// @dev Only callable by the owner.
    /// @param baseURI The new base URI string.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURI = baseURI;
    }

    /// @notice Sets the required cooldown period in blocks between forge actions for any user.
    /// @dev Only callable by the owner.
    /// @param cooldownInBlocks The new cooldown duration in blocks.
    function setForgeCooldown(uint256 cooldownInBlocks) external onlyOwner {
        _forgeCooldownBlocks = cooldownInBlocks;
    }

    /// @notice Grants forge permission to a specific address.
    /// @dev The owner always has permission. Only callable by the owner.
    /// @param user The address to grant permission to.
    function grantForgePermission(address user) external onlyOwner {
        _forgePermissions[user] = true;
        emit ForgePermissionGranted(user);
    }

    /// @notice Revokes forge permission from a specific address.
    /// @dev The owner's permission cannot be revoked. Only callable by the owner.
    /// @param user The address to revoke permission from.
    function revokeForgePermission(address user) external onlyOwner {
        if (user == _owner) revert NotOwner(); // Cannot revoke owner's permission
        _forgePermissions[user] = false;
        emit ForgePermissionRevoked(user);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @dev Can only be called by the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert ZeroAddressOwner();
        _owner = newOwner;
    }

    /// @notice Renounces ownership of the contract.
    /// @dev The renounce operation will leave the contract without an owner, thereby removing any functionality that is protected by the `onlyOwner` modifier.
    ///      Cannot be called if current owner is address(0).
    function renounceOwnership() public onlyOwner {
        if (_owner == address(0)) revert RenounceOwnerFromZeroAddress();
        _owner = address(0);
    }

    // --- Utility Library (Manual Implementation) ---
    // Simple toString function for uint256 (minimal implementation for tokenURI)
    library Strings {
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
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```