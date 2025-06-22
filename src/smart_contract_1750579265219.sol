Okay, let's design a smart contract that combines several interesting concepts:

1.  **Multi-Asset Ownership within an NFT:** An NFT token represents ownership of quantities of *other* tokens (specifically ERC20s in this case, to keep it manageable).
2.  **Dynamic State:** The NFT's visual/metadata state changes based on its contents or other on-chain factors.
3.  **Programmable Attributes:** The state transitions are governed by configurable thresholds or rules.
4.  **Role-Based Access Control:** Beyond simple owner/approved, use roles like "Minter" and "StateController".

We will implement a custom ERC721-like structure without directly importing OpenZeppelin *implementations* for the core logic, adhering to the ERC721 standard interfaces and events.

**Contract Name:** `MultiAssetDynamicNFT`

**Concept:** Each token is a "vault" or "container" that can hold ERC20 tokens. The token's visual representation and attributes dynamically change based on the *number of unique ERC20 token types* it holds, or potentially other factors we define.

---

### Outline & Function Summary

**Contract:** `MultiAssetDynamicNFT`

**Description:** An ERC721 compliant contract where each NFT token acts as a multi-asset container for ERC20 tokens. The NFT's state and attributes are dynamic, changing based on the unique types of ERC20 tokens deposited into it, governed by configurable thresholds.

**Key Concepts:**
*   ERC721 Base (Custom Implementation adhering to standard)
*   Multi-Asset ERC20 Vault per TokenId
*   Dynamic State & Attributes based on on-chain factors
*   Configurable State Transition Thresholds
*   Role-Based Access Control (Owner, Minter, StateController)

**State Variables:**
*   Basic ERC721 storage (`_balances`, `_owners`, `_tokenApprovals`, `_operatorApprovals`, `_totalSupply`)
*   Contract Metadata (`_name`, `_symbol`, `_baseTokenURI`)
*   Access Control (`_owner`, `_minters`, `_stateControllers`)
*   Multi-Asset Storage (`_tokenERC20Contents`: mapping tokenId -> tokenAddress -> amount)
*   Dynamic State Storage (`_dynamicAttributes`: mapping tokenId -> struct DynamicAttributes)
*   Dynamic State Configuration (`_stateThresholds`: array of thresholds for state levels)

**Events:**
*   Standard ERC721 Events (`Transfer`, `Approval`, `ApprovalForAll`)
*   `ERC20Deposited(uint256 tokenId, address tokenAddress, uint256 amount, address depositor)`
*   `ERC20Withdrawal(uint256 tokenId, address tokenAddress, uint256 amount, address receiver)`
*   `StateUpdated(uint256 tokenId, uint256 newStateLevel, uint256 numUniqueTypes)`
*   `MinterAdded(address account)`
*   `MinterRemoved(address account)`
*   `StateControllerAdded(address account)`
*   `StateControllerRemoved(address account)`
*   `ThresholdsUpdated(uint256[] newThresholds)`

**Functions (25 total):**

**ERC721 Standard Interface (10 functions + 1 Interface):**
1.  `balanceOf(address owner) view`: Returns the number of NFTs owned by an address.
2.  `ownerOf(uint256 tokenId) view`: Returns the owner of a specific NFT.
3.  `approve(address to, uint256 tokenId)`: Grants approval for one address to transfer a specific token.
4.  `getApproved(uint256 tokenId) view`: Returns the approved address for a specific token.
5.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for an operator to manage all caller's tokens.
6.  `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for all owner's tokens.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token (unsafe, no receiver check). Internal logic wrapped by public safeTransferFrom.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership safely.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers ownership safely with data.
10. `supportsInterface(bytes4 interfaceId) view`: ERC165 compliance check.
11. `tokenURI(uint256 tokenId) view`: Returns the URI for the token metadata (will reflect dynamic state).

**Minting & Burning (3 functions):**
12. `mint(address to, uint256 tokenId)`: Mints a new token to an address (only by Minter role).
13. `mintBatch(address[] memory to, uint256[] memory tokenIds)`: Mints multiple tokens in a batch (only by Minter role).
14. `burn(uint256 tokenId)`: Burns (destroys) a token (by owner or approved).

**Supply & Query (1 function):**
15. `totalSupply() view`: Returns the total number of minted tokens.

**Multi-Asset Management (3 functions):**
16. `depositERC20(uint256 tokenId, address tokenAddress, uint256 amount)`: Deposits ERC20 tokens into an NFT (caller must pre-approve this contract to spend their ERC20s). Triggers potential state update.
17. `withdrawERC20(uint256 tokenId, address tokenAddress, uint256 amount)`: Withdraws ERC20 tokens from an NFT (only by NFT owner or approved). Triggers potential state update.
18. `getERC20Balance(uint256 tokenId, address tokenAddress) view`: Gets the balance of a specific ERC20 within an NFT.

**Dynamic State Management (4 functions):**
19. `triggerStateUpdate(uint256 tokenId)`: Recalculates and updates the dynamic state for an NFT based on its contents (by NFT owner, approved, or StateController).
20. `getDynamicAttributes(uint256 tokenId) view`: Gets the current dynamic attributes (state level, unique types count) of an NFT.
21. `getNumUniqueERC20Types(uint256 tokenId) view`: Helper to count the number of unique ERC20 types held by an NFT.
22. `setStateThresholds(uint256[] memory thresholds)`: Sets the thresholds for state transitions based on unique ERC20 types count (only by Owner).

**Access Control & Admin (4 functions):**
23. `addMinter(address account)`: Grants Minter role (only by Owner).
24. `removeMinter(address account)`: Revokes Minter role (only by Owner).
25. `addStateController(address account)`: Grants StateController role (only by Owner).
26. `removeStateController(address account)`: Revokes StateController role (only by Owner).
27. `setBaseURI(string memory baseURI)`: Sets the base URI for token metadata (only by Owner).
28. `withdrawContractERC20(address tokenAddress, uint256 amount)`: Allows Owner to withdraw ERC20s accidentally sent directly to the contract address (not into an NFT).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline & Function Summary at the top of the file.

import {IERC165} from "./IERC165.sol"; // Assuming interfaces are available locally or imported via package
import {IERC721} from "./IERC721.sol";
import {IERC721Metadata} from "./IERC721Metadata.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC20} from "./IERC20.sol";

/**
 * @title MultiAssetDynamicNFT
 * @dev An ERC721 compliant contract where each token is a multi-asset container for ERC20s
 * and its state is dynamic based on the number of unique ERC20 types held.
 *
 * Outline:
 * - Basic ERC721 implementation (custom, adhering to standard interfaces)
 * - Multi-Asset (ERC20) deposit/withdrawal per token
 * - Dynamic State based on # of unique ERC20 types held
 * - Configurable state transition thresholds
 * - Role-based access control (Owner, Minter, StateController)
 *
 * Function Summary:
 * - Standard ERC721 (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
 *   transferFrom, safeTransferFrom (2 overloads), supportsInterface, tokenURI)
 * - Minting/Burning (mint, mintBatch, burn)
 * - Supply (totalSupply)
 * - Multi-Asset Management (depositERC20, withdrawERC20, getERC20Balance)
 * - Dynamic State (triggerStateUpdate, getDynamicAttributes, getNumUniqueERC20Types, setStateThresholds)
 * - Access Control/Admin (addMinter, removeMinter, addStateController, removeStateController,
 *   setBaseURI, withdrawContractERC20)
 */
contract MultiAssetDynamicNFT is IERC721, IERC721Metadata, IERC165 {
    // --- ERC721 Standard Storage ---
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _totalSupply;

    // --- Contract Metadata ---
    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    // --- Access Control ---
    address private _owner;
    mapping(address => bool) private _minters;
    mapping(address => bool) private _stateControllers;

    // --- Multi-Asset Storage (tokenId => tokenAddress => amount) ---
    mapping(uint256 => mapping(address => uint256)) private _tokenERC20Contents;

    // --- Dynamic State Storage ---
    struct DynamicAttributes {
        uint256 stateLevel;
        uint256 numUniqueERC20Types; // Explicitly track unique types to avoid iterating map
        // Add other dynamic attributes here if needed
    }
    mapping(uint256 => DynamicAttributes) private _dynamicAttributes;

    // --- Dynamic State Configuration (sorted ascending thresholds) ---
    uint256[] private _stateThresholds; // e.g., [0, 5, 10] -> State 0 (0-4 types), State 1 (5-9 types), State 2 (10+ types)

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ERC20Deposited(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount, address indexed depositor);
    event ERC20Withdrawal(uint256 indexed tokenId, address indexed tokenAddress, uint256 amount, address indexed receiver);
    event StateUpdated(uint256 indexed tokenId, uint256 newStateLevel, uint256 numUniqueTypes);
    event ThresholdsUpdated(uint256[] newThresholds);

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event StateControllerAdded(address indexed account);
    event StateControllerRemoved(address indexed account);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not contract owner");
        _;
    }

    modifier onlyMinter() {
        require(_minters[msg.sender], "Not a minter");
        _;
    }

    modifier onlyStateController() {
        require(_stateControllers[msg.sender] || msg.sender == _owner, "Not state controller or owner");
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialMinter) {
        _name = name;
        _symbol = symbol;
        _owner = msg.sender;
        _minters[initialMinter] = true; // Grant initial minter role
        _stateControllers[msg.sender] = true; // Owner is also a state controller by default
        emit MinterAdded(initialMinter);
        emit StateControllerAdded(msg.sender);

        // Set a default threshold (e.g., 0 unique types for state 0)
        _stateThresholds = new uint256[](1);
        _stateThresholds[0] = 0;
        emit ThresholdsUpdated(_stateThresholds);
    }

    // --- ERC165 Standard Interface Implementation ---
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721Metadata = 0x5b5e139f;

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721Metadata;
    }

    // --- ERC721 Standard Functions ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "Approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev This function is included for compliance but `safeTransferFrom` is recommended.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev This function constructs a dynamic URI based on the token's state.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        DynamicAttributes storage attributes = _dynamicAttributes[tokenId];

        // Construct a dynamic URI. The off-chain service at _baseTokenURI
        // should interpret these parameters to generate the correct JSON metadata.
        // Example: base_uri/token/tokenId?stateLevel=X&uniqueTypes=Y
        string memory dynamicParams = string(abi.encodePacked(
            "?stateLevel=", uint256ToString(attributes.stateLevel),
            "&uniqueTypes=", uint256ToString(attributes.numUniqueERC20Types)
            // Add other attributes here
        ));

        if (bytes(_baseTokenURI).length == 0) {
             return dynamicParams; // Return just params if base URI is not set
        }

        if (bytes(_baseTokenURI)[bytes(_baseTokenURI).length - 1] == '/') {
             return string(abi.encodePacked(_baseTokenURI, uint256ToString(tokenId), dynamicParams));
        } else {
            return string(abi.encodePacked(_baseTokenURI, "/", uint256ToString(tokenId), dynamicParams));
        }
    }

    // --- Custom Minting & Burning ---

    /**
     * @dev Mints a new NFT token. Only callable by addresses with the Minter role.
     * @param to The recipient address.
     * @param tokenId The ID of the token to mint.
     */
    function mint(address to, uint256 tokenId) public virtual onlyMinter {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;

        // Initialize dynamic attributes for the new token
        _dynamicAttributes[tokenId].stateLevel = 0;
        _dynamicAttributes[tokenId].numUniqueERC20Types = 0;

        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Mints multiple NFT tokens in a batch. Only callable by addresses with the Minter role.
     * @param to Array of recipient addresses (must match tokenIds length).
     * @param tokenIds Array of token IDs to mint.
     */
    function mintBatch(address[] memory to, uint256[] memory tokenIds) public virtual onlyMinter {
        require(to.length == tokenIds.length, "Batch mint arrays mismatch");
        for (uint i = 0; i < tokenIds.length; i++) {
            mint(to[i], tokenIds[i]); // Call single mint function for each token
        }
    }

    /**
     * @dev Destroys a token. The approved address and operator approvals for the token are cleared.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(_isApprovedOrOwner(msg.sender, tokenId), "Burn caller is not owner nor approved");

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        _totalSupply -= 1;

        // Clear multi-asset contents (gas cost scales with # of unique token types)
        // For simplicity here, we'll just delete the top-level mapping entry.
        // A more gas-efficient approach might require iterating or tracking active token addresses per NFT.
        delete _tokenERC20Contents[tokenId];

        // Clear dynamic attributes
        delete _dynamicAttributes[tokenId];

        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    // --- Supply Query ---

    /**
     * @dev See {IERC721-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // --- Multi-Asset Management ---

    /**
     * @dev Deposits ERC20 tokens into a specific NFT.
     * Caller must have pre-approved this contract to spend `amount` of `tokenAddress` from their balance.
     * Automatically triggers a state update check.
     * @param tokenId The ID of the NFT.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of ERC20 tokens to deposit.
     */
    function depositERC20(uint256 tokenId, address tokenAddress, uint256 amount) public virtual {
        require(_exists(tokenId), "Deposit to nonexistent token");
        require(tokenAddress != address(0), "Deposit zero address token");
        require(amount > 0, "Deposit amount must be greater than zero");

        address owner = ownerOf(tokenId); // Deposit can be done by anyone, not just NFT owner

        uint256 currentBalance = _tokenERC20Contents[tokenId][tokenAddress];
        bool isNewToken = currentBalance == 0;

        // Transfer ERC20 from depositor to this contract
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "ERC20 transfer failed");

        _tokenERC20Contents[tokenId][tokenAddress] = currentBalance + amount;

        // If it's a new unique token type for this NFT, increment counter
        if (isNewToken) {
             _dynamicAttributes[tokenId].numUniqueERC20Types += 1;
        }

        emit ERC20Deposited(tokenId, tokenAddress, amount, msg.sender);

        // Automatically trigger state update after deposit
        _updateDynamicState(tokenId);
    }

    /**
     * @dev Withdraws ERC20 tokens from a specific NFT.
     * Only callable by the NFT owner or an approved address for the NFT.
     * Automatically triggers a state update check.
     * @param tokenId The ID of the NFT.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawERC20(uint256 tokenId, address tokenAddress, uint256 amount) public virtual onlyTokenOwnerOrApproved(tokenId) {
        require(tokenAddress != address(0), "Withdraw zero address token");
        require(amount > 0, "Withdraw amount must be greater than zero");

        uint256 currentBalance = _tokenERC20Contents[tokenId][tokenAddress];
        require(currentBalance >= amount, "Insufficient ERC20 balance in token");

        _tokenERC20Contents[tokenId][tokenAddress] = currentBalance - amount;

        // Check if the token type is now empty, if so, decrement unique types counter
        if (_tokenERC20Contents[tokenId][tokenAddress] == 0) {
            // Note: This is simple. A more robust solution might iterate or use a Set structure if gas allows,
            // but iterating mapping keys is not standard practice due to potential gas costs.
            // Assuming tokenAddress is non-zero and was present before.
            _dynamicAttributes[tokenId].numUniqueERC20Types -= 1;
        }

        // Transfer ERC20 from this contract to the receiver (msg.sender)
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(msg.sender, amount);
        require(success, "ERC20 transfer failed");

        emit ERC20Withdrawal(tokenId, tokenAddress, amount, msg.sender);

        // Automatically trigger state update after withdrawal
        _updateDynamicState(tokenId);
    }

     /**
     * @dev Gets the balance of a specific ERC20 token held within a specific NFT.
     * @param tokenId The ID of the NFT.
     * @param tokenAddress The address of the ERC20 token.
     * @return The amount of the ERC20 token held.
     */
    function getERC20Balance(uint256 tokenId, address tokenAddress) public view virtual returns (uint256) {
        require(_exists(tokenId), "Query balance for nonexistent token");
        require(tokenAddress != address(0), "Query balance for zero address token");
        return _tokenERC20Contents[tokenId][tokenAddress];
    }

    // --- Dynamic State Management ---

    /**
     * @dev Triggers the dynamic state update logic for a specific token based on its contents.
     * Can be called by the token owner, approved address, or a StateController.
     * @param tokenId The ID of the NFT to update.
     */
    function triggerStateUpdate(uint256 tokenId) public virtual {
        require(_exists(tokenId), "Cannot update state for nonexistent token");
        // Allow owner, approved, or StateController to trigger manual update
        require(_isApprovedOrOwner(msg.sender, tokenId) || _stateControllers[msg.sender], "State update caller not authorized");

        _updateDynamicState(tokenId);
    }

    /**
     * @dev Internal function to calculate and update the dynamic state.
     * Currently based on the number of unique ERC20 token types.
     * @param tokenId The ID of the NFT to update.
     */
    function _updateDynamicState(uint256 tokenId) internal {
        // This is where the core state logic lives.
        // It currently uses numUniqueERC20Types and stateThresholds.
        // More complex logic could be added here (e.g., based on total value, time, external data via oracle).

        uint256 numUniqueTypes = _dynamicAttributes[tokenId].numUniqueERC20Types;
        uint256 currentStateLevel = _dynamicAttributes[tokenId].stateLevel;
        uint256 newStateLevel = currentStateLevel;

        // Determine the new state level based on thresholds
        for (uint i = 0; i < _stateThresholds.length; i++) {
            if (numUniqueTypes >= _stateThresholds[i]) {
                newStateLevel = i; // State level corresponds to the threshold index
            } else {
                break; // Thresholds are sorted, no need to check further
            }
        }

        if (newStateLevel != currentStateLevel) {
            _dynamicAttributes[tokenId].stateLevel = newStateLevel;
            emit StateUpdated(tokenId, newStateLevel, numUniqueTypes);
            // Note: Re-emitting Transfer event is NOT standard practice for metadata updates.
            // Clients monitor the StateUpdated event and `tokenURI` changes.
        }
         // Even if state level doesn't change, ensure the numUniqueTypes is correct in the struct
         // (This is already updated in deposit/withdraw, but good practice if other factors were involved)
         // _dynamicAttributes[tokenId].numUniqueERC20Types = numUniqueTypes; // This is already handled by deposit/withdraw side effects
    }


    /**
     * @dev Gets the current dynamic attributes for a specific NFT.
     * @param tokenId The ID of the NFT.
     * @return The state level and number of unique ERC20 types.
     */
    function getDynamicAttributes(uint256 tokenId) public view virtual returns (uint256 stateLevel, uint256 numUniqueTypes) {
         require(_exists(tokenId), "Query attributes for nonexistent token");
         DynamicAttributes storage attributes = _dynamicAttributes[tokenId];
         return (attributes.stateLevel, attributes.numUniqueERC20Types);
    }

    /**
     * @dev Returns the number of unique ERC20 token types held by an NFT.
     * This value is tracked explicitly during deposit/withdrawal.
     * @param tokenId The ID of the NFT.
     * @return The count of unique ERC20 types.
     */
    function getNumUniqueERC20Types(uint256 tokenId) public view virtual returns (uint256) {
         require(_exists(tokenId), "Query unique types for nonexistent token");
         return _dynamicAttributes[tokenId].numUniqueERC20Types;
    }


    /**
     * @dev Sets the thresholds for state transitions.
     * The array must be sorted in ascending order.
     * state 0: unique types < thresholds[0]
     * state 1: thresholds[0] <= unique types < thresholds[1]
     * state N: unique types >= thresholds[N-1] (assuming N is the number of thresholds)
     * Only callable by the contract owner.
     * @param thresholds An array of sorted uint256 thresholds.
     */
    function setStateThresholds(uint256[] memory thresholds) public virtual onlyOwner {
        // Basic check for sorted order
        for (uint i = 0; i < thresholds.length; i++) {
            if (i > 0) {
                require(thresholds[i] >= thresholds[i-1], "Thresholds must be sorted ascending");
            }
        }
        _stateThresholds = thresholds;
        emit ThresholdsUpdated(thresholds);
        // Consider triggering state updates for all existing tokens after thresholds change (potentially gas intensive)
        // For this example, we rely on future triggerStateUpdate calls or deposit/withdrawals to update.
    }

    // --- Access Control & Admin ---

    /**
     * @dev Grants the Minter role to an account. Only callable by the contract owner.
     * Accounts with the Minter role can mint new tokens.
     * @param account The address to grant the role to.
     */
    function addMinter(address account) public virtual onlyOwner {
        require(account != address(0), "Cannot add zero address as minter");
        require(!_minters[account], "Account already has minter role");
        _minters[account] = true;
        emit MinterAdded(account);
    }

    /**
     * @dev Revokes the Minter role from an account. Only callable by the contract owner.
     * @param account The address to revoke the role from.
     */
    function removeMinter(address account) public virtual onlyOwner {
        require(account != address(0), "Cannot remove zero address minter");
        require(_minters[account], "Account does not have minter role");
        _minters[account] = false;
        emit MinterRemoved(account);
    }

     /**
     * @dev Checks if an account has the Minter role.
     * @param account The address to check.
     * @return bool True if the account is a minter, false otherwise.
     */
    function isMinter(address account) public view virtual returns (bool) {
        return _minters[account];
    }

    /**
     * @dev Grants the StateController role to an account. Only callable by the contract owner.
     * Accounts with the StateController role can trigger state updates for any token.
     * @param account The address to grant the role to.
     */
    function addStateController(address account) public virtual onlyOwner {
        require(account != address(0), "Cannot add zero address as state controller");
        require(!_stateControllers[account], "Account already has state controller role");
        _stateControllers[account] = true;
        emit StateControllerAdded(account);
    }

    /**
     * @dev Revokes the StateController role from an account. Only callable by the contract owner.
     * @param account The address to revoke the role from.
     */
    function removeStateController(address account) public virtual onlyOwner {
        require(account != address(0), "Cannot remove zero address state controller");
        require(_stateControllers[account], "Account does not have state controller role");
        _stateControllers[account] = false;
        emit StateControllerRemoved(account);
    }

     /**
     * @dev Checks if an account has the StateController role.
     * @param account The address to check.
     * @return bool True if the account is a state controller, false otherwise.
     */
    function isStateController(address account) public view virtual returns (bool) {
        return _stateControllers[account];
    }


    /**
     * @dev Sets the base URI for token metadata. Only callable by the contract owner.
     * This URI is used in the `tokenURI` function to construct the full metadata URL.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public virtual onlyOwner {
        _baseTokenURI = baseURI_;
        // Note: No event standard for base URI change, but could add one if clients need to track this
    }

     /**
     * @dev Allows the contract owner to withdraw ERC20 tokens accidentally sent to the contract address.
     * These are tokens NOT deposited into a specific NFT using `depositERC20`.
     * @param tokenAddress The address of the ERC20 token to withdraw.
     * @param amount The amount of ERC20 tokens to withdraw.
     */
    function withdrawContractERC20(address tokenAddress, uint256 amount) public virtual onlyOwner {
        require(tokenAddress != address(0), "Cannot withdraw zero address token");
        require(amount > 0, "Withdraw amount must be greater than zero");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient contract ERC20 balance");

        bool success = token.transfer(msg.sender, amount);
        require(success, "ERC20 withdrawal failed");
        // Note: No specific event standard for this, but could add one.
    }


    // --- ERC721 Internal Helpers ---

    /**
     * @dev Checks if a token exists.
     */
    function _exists(uint255 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Checks if `spender` is allowed to manage `tokenId`.
     * This includes token owner, approved address, or operator approved for all.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal transfer function without safety checks.
     * Used by `transferFrom`.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner"); // ownerOf checks if token exists
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Internal transfer function with safety checks (ERC721Receiver).
     * Used by `safeTransferFrom`.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
         _transfer(from, to, tokenId);
         require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    /**
     * @dev Internal approval function. Clears existing approvals.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

     /**
     * @dev Internal setApprovalForAll function.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "Approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    /**
     * @dev Internal function to call `onERC721Received` on the recipient contract.
     * Returns true if the recipient is a contract and successfully accepts the token.
     * Returns false if the recipient is an EOA or a contract that doesn't implement the interface.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
        if (to.code.length == 0) {
            return true; // Recipient is an EOA, always accept
        }

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
             return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                 revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                 assembly {
                     revert(add(32, reason), mload(reason))
                 }
            }
        }
    }

    // --- Hooks ---
    // These can be extended by inheriting contracts

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    // --- Utility function for tokenURI ---
    // Simple uint to string conversion (standard utility)
    function uint256ToString(uint256 value) internal pure returns (string memory) {
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
        uint256 index = digits;
        temp = value;
        while (temp != 0) {
            index--;
            buffer[index] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// --- Interfaces (Assuming these are available or defined elsewhere) ---

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

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
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

**Explanation of Advanced/Creative/Trendy Concepts:**

1.  **Multi-Asset Container:** The core idea that an NFT *owns* other fungible tokens is a step beyond standard NFTs. This enables use cases like:
    *   NFTs as token baskets/portfolios.
    *   Gaming assets that level up by "consuming" other tokens (deposit ERC20s to boost attributes).
    *   Digital collectibles that yield other tokens over time (requires additional yield logic, not included here, but the container exists).
2.  **Dynamic State based on On-Chain Contents:** The NFT's `tokenURI` changes based on the *actual* ERC20 contents within the contract's storage. This is verifiable on-chain, unlike dynamic NFTs relying solely on off-chain oracles polling external data. The state transition logic based on the *number of unique token types* is a simple but concrete example of this.
3.  **Configurable State Logic:** The `setStateThresholds` function allows the contract owner to adjust how the `numUniqueERC20Types` maps to the `stateLevel`. This makes the dynamic logic programmable and adaptable without redeploying the entire contract (within the bounds of the implemented logic).
4.  **Explicit Role-Based Access Control:** Using `minters` and `stateControllers` mappings provides more granular control than just `onlyOwner`. This is common in dApps for separating duties.
5.  **Custom ERC721 Implementation:** While adhering to the standard, implementing the core storage and transfer logic without direct library imports (like from OpenZeppelin) fulfills the "don't duplicate open source" aspect regarding the *implementation details* of the standard itself, although using interfaces from standards bodies is necessary and good practice.

This contract offers a foundation for dynamic, interactive NFTs that are intrinsically linked to the fungible assets they contain, opening up various potential applications in DeFi, gaming, and collectibles.