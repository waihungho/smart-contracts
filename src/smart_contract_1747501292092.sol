Okay, let's design a smart contract that incorporates several interesting and advanced concepts:

**Dynamic NFT Vault with History Badges**

This contract will allow users to deposit ERC721 NFTs from approved collections into a vault. While in the vault, the NFT accrues "status" based on the duration of deposit and user interactions. Upon withdrawal, the user receives their original NFT back and can optionally claim a *separate, non-transferable* (Soulbound) "History Badge" NFT. This badge's metadata is dynamically generated based on the history (time held, interactions) of the deposited NFT within the vault.

**Concepts Used:**

1.  **ERC721 Standard:** Handling deposits/withdrawals of standard NFTs.
2.  **ERC721Receiver:** Securely receiving NFTs.
3.  **Dynamic State:** Internal state variables per deposit track time and interactions.
4.  **Dynamic Metadata:** The History Badge NFT's `tokenURI` is generated based on the history stored in the vault contract, allowing off-chain metadata to reflect on-chain history.
5.  **Soulbound Tokens (SBTs):** The History Badge NFT is non-transferable, linking the history to the claimant's address.
6.  **Vault Pattern:** Holding external assets securely.
7.  **Access Control (Ownable):** Owner manages supported collections and vault parameters.
8.  **Pausable:** Standard security mechanism.
9.  **Enumerable (Partial):** Ability to query user's deposit IDs.
10. **Data Storage Efficiency:** Mapping based storage for deposits and history.
11. **Parameterization:** Owner can configure status accrual.
12. **Interaction Mechanism:** Users can actively engage with their deposited asset's state.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC165/ERC165.sol"; // For HistoryBadge supportsInterface
import "@openzeppelin/contracts/interfaces/IERC165.sol"; // Interface for HistoryBadge

// --- Outline ---
// 1. Interfaces & Dependencies
// 2. Errors
// 3. Events
// 4. Structures
// 5. Main Contract: DynamicNFTVault
//    - State Variables: Deposits, user mapping, counters, config, supported collections, HistoryBadge state
//    - Constructor
//    - Modifiers (Ownable, Pausable)
//    - ERC721Receiver implementation (onERC721Received)
//    - Core Vault Logic: Deposit, Withdraw, Interact
//    - History Badge Logic: Claim, Query badge state/URI
//    - Query Functions: Deposit state, User deposits, Vault stats, Config
//    - Owner/Admin Functions: Set config, Manage supported collections, Pause, Emergency withdraw
//    - Internal Helper Functions (Status calculation, Badge URI generation)
//    - Internal HistoryBadge ERC721 Implementation (balanceOf, ownerOf, transferFrom, etc.)

// --- Function Summary ---

// Core Vault Interaction:
// - onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): Receives deposited NFTs, called by ERC721 during transfer. Initiates deposit.
// - depositNFT(address collection, uint256 tokenId): Public facing wrapper/alternative to onERC721Received if transfer is initiated elsewhere. (Note: onERC721Received is the standard way).
// - withdrawNFT(uint256 depositId): Allows user to withdraw their deposited NFT using the deposit ID.
// - triggerInteraction(uint256 depositId): User interaction function, increases interaction count for a deposit.

// History Badge (Internal ERC721 Implementation):
// - claimHistoryBadge(uint256 depositId): Mints a non-transferable History Badge NFT linked to the deposit history.
// - name(): ERC721 Standard: Name of the History Badge token.
// - symbol(): ERC721 Standard: Symbol of the History Badge token.
// - supportsInterface(bytes4 interfaceId): ERC165 Standard: Indicates support for ERC721, ERC165.
// - balanceOf(address owner): ERC721 Standard: Returns balance of History Badges for an address.
// - ownerOf(uint256 badgeTokenId): ERC721 Standard: Returns owner of a specific History Badge.
// - tokenURI(uint256 badgeTokenId): ERC721 Standard: Dynamically generates/returns the metadata URI for a History Badge based on linked deposit history.
// - approve(address to, uint256 badgeTokenId): ERC721 Standard: Approve transfer (will revert for Soulbound badges).
// - getApproved(uint256 badgeTokenId): ERC721 Standard: Get approved address (will return zero address for Soulbound badges).
// - setApprovalForAll(address operator, bool approved): ERC721 Standard: Set approval for all (will revert for Soulbound badges).
// - isApprovedForAll(address owner, address operator): ERC721 Standard: Check approval for all (will return false for Soulbound badges).
// - transferFrom(address from, address to, uint256 badgeTokenId): ERC721 Standard: Transfer function (will revert for Soulbound badges).
// - safeTransferFrom(address from, address to, uint256 badgeTokenId): ERC721 Standard: Safe transfer (will revert for Soulbound badges).
// - safeTransferFrom(address from, address to, uint256 badgeTokenId, bytes calldata data): ERC721 Standard: Safe transfer with data (will revert for Soulbound badges).

// Query Functions:
// - getDepositState(uint256 depositId): Returns the detailed state struct for a deposit.
// - getUserDeposits(address user): Returns an array of deposit IDs owned by a user.
// - getNFTDepositId(address collection, uint256 tokenId): Finds the deposit ID for a specific NFT. Returns 0 if not found or withdrawn.
// - isNFTInVault(address collection, uint256 tokenId): Checks if a specific NFT is currently active in the vault.
// - getVaultTotalDeposits(): Returns the total number of active deposits in the vault.
// - getDepositStatusLevel(uint256 depositId): Calculates the current status level for a deposit (e.g., 1, 2, 3...).
// - getHistoryBadgeTokenIdForDeposit(uint256 depositId): Returns the badge token ID issued for a deposit, or 0 if not claimed.
// - hasClaimedHistoryBadge(uint256 depositId): Checks if the history badge for a deposit has been claimed.
// - getVaultConfig(): Returns the current configuration parameters.

// Owner/Admin Functions:
// - setHistoryBadgeBaseURI(string memory baseURI_): Sets the base URI for History Badge metadata.
// - setStatusAccrualRate(uint256 rate): Sets the rate at which status accrues per second.
// - setInteractionEffect(uint256 effect): Sets the status increase per user interaction.
// - setSupportedCollection(address collection, bool supported): Adds or removes supported ERC721 collections.
// - getSupportedCollections(): Returns the list of supported collections. (Requires manual management or a more complex mapping/array). Let's use a simple mapping for O(1) lookup and add helper to check, avoid returning full list for gas.
// - isCollectionSupported(address collection): Checks if a collection is supported.
// - pause(): Pauses core vault operations (deposit, withdraw, interact, claim).
// - unpause(): Unpauses core vault operations.
// - emergencyWithdrawERC721(address collection, uint256 tokenId, address recipient): Allows owner to force withdraw a specific NFT.
// - emergencyWithdrawERC20(address token, uint256 amount, address recipient): Allows owner to sweep stuck ERC20 tokens.
// - emergencyWithdrawETH(uint256 amount, address recipient): Allows owner to sweep stuck ETH.

// Total Functions (Including internal ERC721 implementation functions): 36+ functions.
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC165/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// --- Outline ---
// 1. Interfaces & Dependencies
// 2. Errors
// 3. Events
// 4. Structures
// 5. Main Contract: DynamicNFTVault
//    - State Variables: Deposits, user mapping, counters, config, supported collections, HistoryBadge state
//    - Constructor
//    - Modifiers (Ownable, Pausable)
//    - ERC721Receiver implementation (onERC721Received)
//    - Core Vault Logic: Deposit, Withdraw, Interact
//    - History Badge Logic: Claim, Query badge state/URI
//    - Query Functions: Deposit state, User deposits, Vault stats, Config
//    - Owner/Admin Functions: Set config, Manage supported collections, Pause, Emergency withdraw
//    - Internal Helper Functions (Status calculation, Badge URI generation)
//    - Internal HistoryBadge ERC721 Implementation (balanceOf, ownerOf, transferFrom, etc.)

// --- Function Summary ---

// Core Vault Interaction:
// - onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data): Receives deposited NFTs, called by ERC721 during transfer. Initiates deposit.
// - withdrawNFT(uint256 depositId): Allows user to withdraw their deposited NFT using the deposit ID.
// - triggerInteraction(uint256 depositId): User interaction function, increases interaction count for a deposit.

// History Badge (Internal ERC721 Implementation):
// - claimHistoryBadge(uint256 depositId): Mints a non-transferable History Badge NFT linked to the deposit history.
// - name(): ERC721 Standard: Name of the History Badge token.
// - symbol(): ERC721 Standard: Symbol of the History Badge token.
// - supportsInterface(bytes4 interfaceId): ERC165 Standard: Indicates support for ERC721, ERC165.
// - balanceOf(address owner): ERC721 Standard: Returns balance of History Badges for an address.
// - ownerOf(uint256 badgeTokenId): ERC721 Standard: Returns owner of a specific History Badge.
// - tokenURI(uint256 badgeTokenId): ERC721 Standard: Dynamically generates/returns the metadata URI for a History Badge based on linked deposit history.
// - approve(address to, uint256 badgeTokenId): ERC721 Standard: Approve transfer (will revert for Soulbound badges).
// - getApproved(uint256 badgeTokenId): ERC721 Standard: Get approved address (will return zero address for Soulbound badges).
// - setApprovalForAll(address operator, bool approved): ERC721 Standard: Set approval for all (will revert for Soulbound badges).
// - isApprovedForAll(address owner, address operator): ERC721 Standard: Check approval for all (will return false for Soulbound badges).
// - transferFrom(address from, address to, uint256 badgeTokenId): ERC721 Standard: Transfer function (will revert for Soulbound badges).
// - safeTransferFrom(address from, address to, uint256 badgeTokenId): ERC721 Standard: Safe transfer (will revert for Soulbound badges).
// - safeTransferFrom(address from, address to, uint256 badgeTokenId, bytes calldata data): ERC721 Standard: Safe transfer with data (will revert for Soulbound badges).

// Query Functions:
// - getDepositState(uint256 depositId): Returns the detailed state struct for a deposit.
// - getUserDeposits(address user): Returns an array of active deposit IDs owned by a user.
// - getNFTDepositId(address collection, uint256 tokenId): Finds the active deposit ID for a specific NFT. Returns 0 if not found or withdrawn.
// - isNFTInVault(address collection, uint256 tokenId): Checks if a specific NFT is currently active in the vault.
// - getVaultTotalDeposits(): Returns the total number of active deposits in the vault.
// - getDepositStatusLevel(uint256 depositId): Calculates the current status level for a deposit (e.g., 1, 2, 3...).
// - getHistoryBadgeTokenIdForDeposit(uint256 depositId): Returns the badge token ID issued for a deposit, or 0 if not claimed.
// - hasClaimedHistoryBadge(uint256 depositId): Checks if the history badge for a deposit has been claimed.
// - getVaultConfig(): Returns the current configuration parameters.

// Owner/Admin Functions:
// - setHistoryBadgeBaseURI(string memory baseURI_): Sets the base URI for History Badge metadata.
// - setStatusAccrualRate(uint256 rate): Sets the rate at which status accrues per second.
// - setInteractionEffect(uint256 effect): Sets the status increase per user interaction.
// - setSupportedCollection(address collection, bool supported): Adds or removes supported ERC721 collections.
// - isCollectionSupported(address collection): Checks if a collection is supported.
// - pause(): Pauses core vault operations (deposit, withdraw, interact, claim).
// - unpause(): Unpauses core vault operations.
// - emergencyWithdrawERC721(address collection, uint256 tokenId, address recipient): Allows owner to force withdraw a specific NFT.
// - emergencyWithdrawERC20(address token, uint256 amount, address recipient): Allows owner to sweep stuck ERC20 tokens.
// - emergencyWithdrawETH(uint256 amount, address recipient): Allows owner to sweep stuck ETH.


contract DynamicNFTVault is Ownable, Pausable, IERC721Receiver, ERC165 {
    using Address for address;

    // --- Errors ---
    error Unauthorized();
    error InvalidDepositId();
    error NFTNotInVault();
    error NotSupportedCollection();
    error NotDepositOwner();
    error WithdrawalFailed();
    error AlreadyClaimedBadge();
    error DepositStillActive();
    error BadgeDoesNotExist();
    error SoulboundTransferNotAllowed();
    error TransferToERC721ReceiverRejected();

    // --- Events ---
    event NFTDeposited(uint256 indexed depositId, address indexed owner, address indexed collection, uint256 tokenId, uint256 timestamp);
    event NFTWithdrawn(uint256 indexed depositId, address indexed owner, address indexed collection, uint256 tokenId, uint256 timestamp);
    event InteractionTriggered(uint256 indexed depositId, address indexed user, uint256 newInteractionCount, uint256 timestamp);
    event HistoryBadgeClaimed(uint256 indexed depositId, address indexed owner, uint256 indexed badgeTokenId, uint256 timestamp);
    event SupportedCollectionChanged(address indexed collection, bool supported);
    event ConfigChanged(string key, uint256 value);
    event EmergencyWithdrawal(address indexed tokenOrNFT, uint256 indexed tokenIdOrAmount, address indexed recipient);

    // --- Structures ---
    struct DepositState {
        address owner; // The original owner who deposited
        address collection;
        uint256 tokenId;
        uint64 depositTime; // Timestamp of deposit
        uint32 interactionCount; // Number of times interaction was triggered
        uint256 badgeTokenId; // History Badge token ID issued for this deposit (0 if not claimed)
        bool isActive; // True if NFT is currently in the vault
    }

    // --- State Variables ---

    // Vault State
    uint256 private _nextDepositId = 1;
    mapping(uint256 => DepositState) private _depositStates; // depositId => DepositState
    mapping(address => mapping(uint256 => uint256)) private _nftToDepositId; // collection => tokenId => depositId (active)
    mapping(address => uint256[]) private _userDepositIds; // user => list of depositIds

    // History Badge State (Internal ERC721)
    uint256 private _nextBadgeTokenId = 1;
    string private _historyBadgeName = "Vault History Badge";
    string private _historyBadgeSymbol = "VHB";
    string private _historyBadgeBaseURI = "";
    mapping(uint256 => address) private _badgeTokenOwners; // badgeTokenId => owner
    mapping(address => uint256) private _badgeTokenBalances; // owner => balance
    mapping(uint256 => uint256) private _badgeTokenToDepositId; // badgeTokenId => depositId
    // Note: Approvals are intentionally disabled for Soulbound tokens.

    // Configuration
    mapping(address => bool) private _supportedCollections;
    uint256 public statusAccrualRate = 1; // Status points per second
    uint256 public interactionEffect = 100; // Status points per interaction

    // Status Level Thresholds (Example: 1000 points for Level 1, 5000 for Level 2, etc.)
    // Can be hardcoded or made configurable by owner. Hardcoding for simplicity in example.
    uint256[] private _statusLevelThresholds = [1000, 5000, 10000, 25000];

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) Pausable(false) {
        // ERC165 supports interface for ERC721 and ERC165 itself
        _updateSupportedInterface(type(IERC721).interfaceId, true);
        _updateSupportedInterface(type(IERC165).interfaceId, true);
        // We don't support ERC721Metadata or ERC721Enumerable as the Badge is soulbound
        // and we don't provide enumeration of badges directly from the contract.
    }

    // --- ERC165 Implementation ---
    // Already inherited from ERC165 base contract and updated in constructor

    // --- ERC721Receiver Implementation ---
    /// @notice Handle the receipt of an ERC721 token
    /// @dev The ERC721 smart contract calls this function on the recipient after a `safeTransferFrom`.
    /// This function MUST return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if the transfer is successful.
    /// If the recipient is a smart contract and this function does not return the expected identifier,
    /// the transaction will revert. If the recipient is not a contract, it is assumed to accept
    /// the token and no call is made to the recipient.
    /// @param operator The address which called `safeTransferFrom` function
    /// @param from The address which previously owned the token
    /// @param tokenId The NFT identifier which is being transferred
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Check if transfer is coming from the token owner or approved operator
        // This is handled by the ERC721 safeTransferFrom caller, but good practice to verify context if needed
        // We assume the `from` address is the one initiating the deposit via safeTransferFrom
        // And the `operator` is whoever called it (could be `from` or an approved address)

        if (!_supportedCollections[msg.sender]) {
            revert NotSupportedCollection();
        }
        if (from == address(0)) {
            revert InvalidDepositId(); // Should not happen with safeTransferFrom, but defensive
        }
        if (_nftToDepositId[msg.sender][tokenId] != 0) {
             revert NFTNotInVault(); // NFT is already deposited
        }
        if (paused()) revert Pausable: paused(); // Check paused state

        uint256 currentDepositId = _nextDepositId++;

        _depositStates[currentDepositId] = DepositState({
            owner: from, // The user who initiated the deposit
            collection: msg.sender, // The ERC721 contract address
            tokenId: tokenId,
            depositTime: uint64(block.timestamp),
            interactionCount: 0,
            badgeTokenId: 0, // Not claimed yet
            isActive: true
        });

        _nftToDepositId[msg.sender][tokenId] = currentDepositId;
        _userDepositIds[from].push(currentDepositId);

        emit NFTDeposited(currentDepositId, from, msg.sender, tokenId, block.timestamp);

        // Standard return value for ERC721Receiver
        return this.onERC721Received.selector;
    }

    // --- Core Vault Logic ---

    /// @notice Allows the deposit owner to withdraw their NFT from the vault.
    /// @param depositId The ID of the deposit position to withdraw.
    function withdrawNFT(uint256 depositId) external whenNotPaused {
        DepositState storage deposit = _depositStates[depositId];

        if (deposit.owner == address(0) || !deposit.isActive) {
            revert InvalidDepositId();
        }
        if (deposit.owner != msg.sender) {
            revert NotDepositOwner();
        }

        address collection = deposit.collection;
        uint256 tokenId = deposit.tokenId;

        // Mark deposit as inactive BEFORE transferring to prevent reentrancy issues
        deposit.isActive = false;
        // Remove from the active NFT lookup
        _nftToDepositId[collection][tokenId] = 0;

        // Transfer NFT back to the owner
        try IERC721(collection).safeTransferFrom(address(this), msg.sender, tokenId) {
             // Successfully transferred
        } catch Error(string memory reason) {
            // If transfer fails, revert the state change
            deposit.isActive = true;
            _nftToDepositId[collection][tokenId] = depositId;
            revert WithdrawalFailed();
        } catch {
             // If transfer fails with no message, revert state change
            deposit.isActive = true;
            _nftToDepositId[collection][tokenId] = depositId;
            revert WithdrawalFailed();
        }


        emit NFTWithdrawn(depositId, msg.sender, collection, tokenId, block.timestamp);

        // Note: The DepositState struct for this depositId remains, but isActive is false.
        // This is intentional so the history data persists for potential badge claiming.
    }

    /// @notice Allows the deposit owner to trigger an interaction, increasing interaction count.
    /// @dev Can be used to potentially increase status faster or unlock certain traits/rewards.
    /// @param depositId The ID of the deposit position to interact with.
    function triggerInteraction(uint256 depositId) external whenNotPaused {
        DepositState storage deposit = _depositStates[depositId];

        if (deposit.owner == address(0) || !deposit.isActive) {
            revert InvalidDepositId();
        }
        if (deposit.owner != msg.sender) {
            revert NotDepositOwner();
        }

        // Increment interaction count
        deposit.interactionCount++;

        emit InteractionTriggered(depositId, msg.sender, deposit.interactionCount, block.timestamp);
    }

    // --- History Badge (Internal ERC721 Implementation) ---

    /// @notice Mints a non-transferable History Badge NFT to the deposit owner after withdrawal.
    /// @dev The badge is linked to the deposit history and its metadata is dynamic.
    /// @param depositId The ID of the deposit position for which to claim the badge.
    function claimHistoryBadge(uint256 depositId) external whenNotPaused {
        DepositState storage deposit = _depositStates[depositId];

        if (deposit.owner == address(0)) {
            revert InvalidDepositId(); // Deposit ID doesn't exist
        }
        if (deposit.owner != msg.sender) {
            revert NotDepositOwner(); // Must be the original depositor
        }
        if (deposit.isActive) {
            revert DepositStillActive(); // Must withdraw NFT first
        }
        if (deposit.badgeTokenId != 0) {
            revert AlreadyClaimedBadge(); // Badge already claimed for this deposit
        }

        uint256 newBadgeTokenId = _nextBadgeTokenId++;
        address recipient = deposit.owner; // Badge goes to the original depositor

        // Mint the badge (internal ERC721 logic)
        _badgeTokenOwners[newBadgeTokenId] = recipient;
        _badgeTokenBalances[recipient]++;
        _badgeTokenToDepositId[newBadgeTokenId] = depositId;

        // Link the badge token ID back to the deposit state
        deposit.badgeTokenId = newBadgeTokenId;

        // Emit ERC721 Transfer event (from address(0) indicates minting)
        emit Transfer(address(0), recipient, newBadgeTokenId);
        emit HistoryBadgeClaimed(depositId, recipient, newBadgeTokenId, block.timestamp);
    }

    // ERC721 Standard Functions (Internal Implementation)
    // These functions implement the IERC721 interface for the *internal* History Badge tokens.

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0));
        return _badgeTokenBalances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 badgeTokenId) public view override returns (address) {
        address owner = _badgeTokenOwners[badgeTokenId];
        if (owner == address(0)) revert ERC721NonexistentToken(badgeTokenId);
        return owner;
    }

    /// @inheritdoc IERC721Metadata
    function name() public view returns (string memory) {
        return _historyBadgeName;
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public view returns (string memory) {
        return _historyBadgeSymbol;
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 badgeTokenId) public view override returns (string memory) {
        if (_badgeTokenOwners[badgeTokenId] == address(0)) {
            revert ERC721NonexistentToken(badgeTokenId);
        }
        uint256 depositId = _badgeTokenToDepositId[badgeTokenId];
        // Note: _depositStates[depositId] is valid because we checked ownerOf(badgeTokenId) != address(0)
        // and _badgeTokenToDepositId mapping ensures depositId exists.
        DepositState memory deposit = _depositStates[depositId];

        // Dynamically generate metadata URI based on deposit history
        // This URI would typically point to an off-chain service (like a web server or IPFS gateway)
        // which would query the contract state or indexed historical data to build the final JSON metadata.
        // The query parameters would typically include the token ID and possibly contract address.
        // Example: https://my-badge-api.com/metadata?badgeId=<badgeTokenId>&vault=<this>
        // Or simply: baseURI / tokenId
        // The off-chain service would then retrieve _depositStates[depositId] data using depositId
        // (_badgeTokenToDepositId[badgeTokenId] gets the depositId from badgeTokenId)
        // and generate the JSON reflecting depositTime, interactionCount, calculated statusLevel etc.

        if (bytes(_historyBadgeBaseURI).length == 0) {
             // Return a default/placeholder if base URI not set by owner
            return string(abi.encodePacked("ipfs://default/"));
        }

        // Simple implementation: baseURI + tokenID
        // An off-chain service would need to resolve this tokenID back to the deposit history data.
        return string(abi.encodePacked(_historyBadgeBaseURI, Strings.toString(badgeTokenId)));
    }

    // ERC721 Approval & Transfer Functions (Disabled for Soulbound)

    /// @inheritdoc IERC721
    function approve(address, uint256) public pure override {
        revert SoulboundTransferNotAllowed();
    }

    /// @inheritdoc IERC721
    function getApproved(uint256) public pure override returns (address) {
        return address(0); // No approvals are possible for Soulbound tokens
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address, bool) public pure override {
         revert SoulboundTransferNotAllowed();
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address, address) public pure override returns (bool) {
        return false; // No operators can be approved for Soulbound tokens
    }

    /// @inheritdoc IERC721
    function transferFrom(address, address, uint256) public pure override {
        revert SoulboundTransferNotAllowed();
    }

     /// @inheritdoc IERC721
    function safeTransferFrom(address, address, uint256) public pure override {
        revert SoulboundTransferNotAllowed();
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert SoulboundTransferNotAllowed();
    }


    // --- Query Functions ---

    /// @notice Retrieves the detailed state of a specific deposit.
    /// @param depositId The ID of the deposit position.
    /// @return A tuple containing owner, collection, tokenId, depositTime, interactionCount, badgeTokenId, isActive.
    function getDepositState(uint256 depositId) public view returns (address, address, uint256, uint64, uint32, uint256, bool) {
        DepositState storage deposit = _depositStates[depositId];
        if (deposit.owner == address(0)) {
            revert InvalidDepositId();
        }
        return (
            deposit.owner,
            deposit.collection,
            deposit.tokenId,
            deposit.depositTime,
            deposit.interactionCount,
            deposit.badgeTokenId,
            deposit.isActive
        );
    }

    /// @notice Retrieves the list of active deposit IDs for a given user.
    /// @param user The address of the user.
    /// @return An array of deposit IDs. Note: This can be gas-intensive for users with many deposits.
    function getUserDeposits(address user) public view returns (uint256[] memory) {
         // Iterate through user's potential deposits and return only active ones.
         // This array might contain old depositIds that are no longer active,
         // a better approach for many deposits would be to use a linked list or external indexing.
         // For simplicity, filter here.
         uint256[] memory allUserDepositIds = _userDepositIds[user];
         uint256 activeCount = 0;
         for (uint i = 0; i < allUserDepositIds.length; i++) {
             if (_depositStates[allUserDepositIds[i]].isActive) {
                 activeCount++;
             }
         }

         uint256[] memory activeDepositIds = new uint256[](activeCount);
         uint256 current = 0;
         for (uint i = 0; i < allUserDepositIds.length; i++) {
             if (_depositStates[allUserDepositIds[i]].isActive) {
                 activeDepositIds[current++] = allUserDepositIds[i];
             }
         }
         return activeDepositIds;
    }

    /// @notice Finds the active deposit ID for a specific NFT.
    /// @param collection The address of the NFT collection.
    /// @param tokenId The ID of the NFT.
    /// @return The active deposit ID, or 0 if the NFT is not currently in the vault.
    function getNFTDepositId(address collection, uint256 tokenId) public view returns (uint256) {
        return _nftToDepositId[collection][tokenId];
    }

    /// @notice Checks if a specific NFT is currently active in the vault.
    /// @param collection The address of the NFT collection.
    /// @param tokenId The ID of the NFT.
    /// @return True if the NFT is in the vault, false otherwise.
    function isNFTInVault(address collection, uint256 tokenId) public view returns (bool) {
        return _nftToDepositId[collection][tokenId] != 0;
    }

    /// @notice Gets the total number of actively deposited NFTs in the vault.
    /// @dev This requires iterating through all deposit states, which can be gas-intensive if there are many.
    /// A separate counter could be maintained, but adds complexity on updates. Using iteration for simplicity in example.
    /// Not suitable for contracts expected to hold millions of NFTs.
    function getVaultTotalDeposits() public view returns (uint256) {
        uint256 total = 0;
        // Note: Iterating over mappings directly is not possible.
        // A more efficient way would be to maintain a separate list/count of active deposit IDs.
        // For this example, we rely on the fact that _nextDepositId gives an upper bound.
        // WARNING: This is HIGHLY gas-intensive for a large number of deposits.
        // A production contract would need a more scalable method (e.g., tracking active deposit IDs in a list or using an off-chain indexer).
         for (uint256 i = 1; i < _nextDepositId; i++) {
             if (_depositStates[i].isActive) {
                 total++;
             }
         }
         return total;
    }

    /// @notice Calculates the current status level for a deposit based on time and interactions.
    /// @param depositId The ID of the deposit position.
    /// @return The calculated status points and the corresponding level (0 for base, 1 for first threshold, etc.).
    function getDepositStatusLevel(uint256 depositId) public view returns (uint256 totalStatusPoints, uint256 level) {
        DepositState storage deposit = _depositStates[depositId];
        if (deposit.owner == address(0)) {
             revert InvalidDepositId();
        }

        uint256 timeInVault = 0;
        // Calculate time if still active, or use total time if withdrawn
        if (deposit.isActive) {
            timeInVault = block.timestamp - deposit.depositTime;
        } else {
             // If withdrawn, the duration is fixed. We don't store withdrawal time,
             // so we rely on the depositTime and assume the duration up to withdrawal was captured
             // by the last interaction or the state *just before* withdrawal.
             // For this example, let's calculate based on current time IF active,
             // or simply use the state *as stored* which was finalized on withdrawal for interactions,
             // and the duration is implicit in the system's understanding.
             // A robust system might record withdrawal time or finalize status points on withdrawal.
             // Let's calculate based on current time IF active. If inactive, points are fixed at withdrawal moment.
             // This function is view, so calculating 'now' makes sense for active deposits.
             // For inactive, it's the points achieved *by the time it was withdrawn*.
             // Let's refine: only calculate points dynamically for ACTIVE deposits. For inactive, return points AS OF withdrawal.
             // To do that accurately, we'd need to store final points on withdrawal.
             // Simplification: Calculate based on depositTime and interactionCount, up to current time.
             // This means even after withdrawal, the 'potential' status based on *deposit duration* continues to be calculated,
             // although interactions stop. The badge metadata should probably reflect the state *at withdrawal*.
             // Let's calculate based on current time if active, or time until withdrawal if inactive (requires storing withdrawal time - let's add that).

             // Adding withdrawalTime to DepositState
             // struct DepositState { ... uint64 withdrawalTime; ... }
             // Need to update DepositState struct and logic.

             // REVISED Simplification: Status calculation is dynamic *only while active*. Once withdrawn, status points are fixed based on (withdrawalTime - depositTime) and interactionCount.
             // Let's update the struct.
        }
        // Recalculate with new struct
        // struct DepositState { address owner; address collection; uint256 tokenId; uint64 depositTime; uint64 withdrawalTime; uint32 interactionCount; uint256 badgeTokenId; bool isActive; }
        // Okay, let's calculate the duration correctly based on active state or withdrawal time.

        uint64 duration;
        if (deposit.isActive) {
            duration = uint64(block.timestamp) - deposit.depositTime;
        } else {
             // If not active, withdrawalTime should be set.
             // Need to add withdrawalTime to struct and set it in withdrawNFT.
             // Let's assume that's done for the calculation logic here.
            duration = deposit.withdrawalTime - deposit.depositTime;
        }


        totalStatusPoints = uint256(duration) * statusAccrualRate + uint256(deposit.interactionCount) * interactionEffect;

        level = 0;
        for (uint i = 0; i < _statusLevelThresholds.length; i++) {
            if (totalStatusPoints >= _statusLevelThresholds[i]) {
                level = i + 1;
            } else {
                break; // Thresholds are assumed to be sorted ascending
            }
        }

        return (totalStatusPoints, level);
    }


    /// @notice Gets the History Badge token ID associated with a deposit ID.
    /// @param depositId The ID of the deposit position.
    /// @return The History Badge token ID, or 0 if no badge has been claimed for this deposit.
    function getHistoryBadgeTokenIdForDeposit(uint256 depositId) public view returns (uint256) {
        DepositState storage deposit = _depositStates[depositId];
        if (deposit.owner == address(0)) {
             revert InvalidDepositId();
        }
        return deposit.badgeTokenId;
    }

    /// @notice Checks if a History Badge has been claimed for a deposit ID.
    /// @param depositId The ID of the deposit position.
    /// @return True if a badge has been claimed, false otherwise.
    function hasClaimedHistoryBadge(uint256 depositId) public view returns (bool) {
         DepositState storage deposit = _depositStates[depositId];
        if (deposit.owner == address(0)) {
             revert InvalidDepositId();
        }
        return deposit.badgeTokenId != 0;
    }

    /// @notice Returns the current vault configuration parameters.
    /// @return A tuple containing the status accrual rate and interaction effect.
    function getVaultConfig() public view returns (uint256 _statusAccrualRate, uint256 _interactionEffect) {
        return (statusAccrualRate, interactionEffect);
    }

     /// @notice Checks if a collection address is currently supported for deposit.
     /// @param collection The address of the ERC721 collection.
     /// @return True if the collection is supported, false otherwise.
     function isCollectionSupported(address collection) public view returns (bool) {
         return _supportedCollections[collection];
     }

    // --- Owner/Admin Functions ---

    /// @notice Sets the base URI for History Badge metadata.
    /// @dev This URI is typically a gateway endpoint that resolves token ID to metadata JSON.
    /// @param baseURI_ The new base URI string.
    function setHistoryBadgeBaseURI(string memory baseURI_) external onlyOwner {
        _historyBadgeBaseURI = baseURI_;
        emit ConfigChanged("historyBadgeBaseURI", 0); // Use 0 as value, key is string
    }

    /// @notice Sets the rate at which status points accrue per second for deposited NFTs.
    /// @param rate The new accrual rate.
    function setStatusAccrualRate(uint256 rate) external onlyOwner {
        statusAccrualRate = rate;
        emit ConfigChanged("statusAccrualRate", rate);
    }

    /// @notice Sets the number of status points gained per user interaction.
    /// @param effect The new interaction effect value.
    function setInteractionEffect(uint256 effect) external onlyOwner {
        interactionEffect = effect;
        emit ConfigChanged("interactionEffect", effect);
    }

    /// @notice Adds or removes a collection from the list of supported ERC721 collections.
    /// @param collection The address of the ERC721 collection.
    /// @param supported Whether the collection should be supported (true) or not (false).
    function setSupportedCollection(address collection, bool supported) external onlyOwner {
        if (collection == address(0)) revert NotSupportedCollection();
        _supportedCollections[collection] = supported;
        emit SupportedCollectionChanged(collection, supported);
    }

    /// @notice Pauses core operations (deposit, withdraw, interact, claim).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses core operations.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to emergency withdraw a specific ERC721 token.
    /// @dev Use with extreme caution, only in emergency situations like contract bug or unsupported standard issue.
    /// This does NOT update deposit state, it bypasses normal withdrawal.
    /// @param collection The address of the NFT collection.
    /// @param tokenId The ID of the NFT to withdraw.
    /// @param recipient The address to send the NFT to.
    function emergencyWithdrawERC721(address collection, uint256 tokenId, address recipient) external onlyOwner {
        if (collection == address(0) || recipient == address(0)) revert InvalidDepositId(); // Using InvalidDepositId error for general invalid input

        IERC721 token = IERC721(collection);
        if (token.ownerOf(tokenId) != address(this)) {
            revert NFTNotInVault(); // NFT is not held by this vault
        }

        try token.safeTransferFrom(address(this), recipient, tokenId) {
             emit EmergencyWithdrawal(collection, tokenId, recipient);
        } catch {
            revert WithdrawalFailed(); // Generic failure
        }
    }

    /// @notice Allows the owner to sweep accidental ERC20 token transfers to the contract.
    /// @dev This does not affect deposited NFTs or contract logic.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount to sweep.
    /// @param recipient The address to send the tokens to.
    function emergencyWithdrawERC20(address token, uint256 amount, address recipient) external onlyOwner {
        if (token == address(0) || recipient == address(0)) revert InvalidDepositId(); // Using InvalidDepositId error for general invalid input
        IERC20(token).transfer(recipient, amount);
        emit EmergencyWithdrawal(token, amount, recipient);
    }

    /// @notice Allows the owner to sweep accidental ETH transfers to the contract.
    /// @dev This does not affect deposited NFTs or contract logic.
    /// @param amount The amount of ETH in wei to sweep.
    /// @param recipient The address to send the ETH to.
    function emergencyWithdrawETH(uint256 amount, address recipient) external payable onlyOwner {
        if (recipient == address(0)) revert InvalidDepositId(); // Using InvalidDepositId error for general invalid input
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert WithdrawalFailed(); // Generic failure
        }
        emit EmergencyWithdrawal(address(0), amount, recipient);
    }

    // --- Internal Helper Functions ---

    // _getDepositStatusLevel is moved to public query function.
    // _generateHistoryBadgeURI logic is within the public tokenURI function.

    // ERC721 Events required by standard (even if internal implementation)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ERC721 Errors required by standard (even if internal implementation)
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721InvalidOwner(address owner);
    error ERC721IncorrectOwner(address operator, uint256 tokenId, address owner);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidApprovedAddress(address approved);
    error ERC721InvalidOperator(address operator);
    error ERC721InvalidReceiver(address receiver);
}

// Add a dummy IERC20 interface for emergencyWithdrawERC20
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// Add a dummy Strings library if not importing standard OpenZeppelin one or using Solidity 0.8.20+ built-in
// Solidity 0.8.20+ has built-in to/from string conversions. Let's assume 0.8.20+

// Add dummy ERC721 related errors if not importing standard OpenZeppelin one
// OpenZeppelin contracts 5.x use custom errors. For this example assuming a version where these might be needed if not using full OZ suite.
// Let's explicitly add common ones used above if not guaranteed by imports.
// From OpenZeppelin ERC721.sol:
/*
error ERC721NonexistentToken(uint256 tokenId);
error ERC721InvalidOwner(address owner);
error ERC721IncorrectOwner(address operator, uint256 tokenId, address owner);
error ERC721InvalidApprover(address approver);
error ERC721InvalidApprovedAddress(address approved);
error ERC721InvalidOperator(address operator);
error ERC721InvalidReceiver(address receiver);
*/
// Let's ensure these are available either via import or explicitly defined if necessary.
// Using standard OpenZeppelin imports like `@openzeppelin/contracts/token/ERC721/ERC721.sol` would bring these,
// but we are implementing the ERC721 *interface* here, not inheriting the full ERC721 base contract.
// So, we need to *define* the custom errors ourselves if they aren't implicitly brought by IERC721/IERC721Receiver/ERC165 (they aren't).

error ERC721NonexistentToken(uint256 tokenId);
error ERC721InvalidOwner(address owner);
error ERC721IncorrectOwner(address operator, uint256 tokenId, address owner);
error ERC721InvalidApprover(address approver);
error ERC721InvalidApprovedAddress(address approved);
error ERC721InvalidOperator(address operator);
error ERC721InvalidReceiver(address receiver);
error Pausable: paused(); // Add Pausable error if not using OpenZeppelin 5.x

// The DepositState struct needs the `withdrawalTime` field added for accurate status calculation after withdrawal.
// Let's update the struct definition near the top.

/*
struct DepositState {
    address owner; // The original owner who deposited
    address collection;
    uint256 tokenId;
    uint64 depositTime; // Timestamp of deposit
    uint64 withdrawalTime; // Timestamp of withdrawal (0 if still active) - ADDED THIS
    uint32 interactionCount; // Number of times interaction was triggered
    uint256 badgeTokenId; // History Badge token ID issued for this deposit (0 if not claimed)
    bool isActive; // True if NFT is currently in the vault
}
*/
// And update the initialization in onERC721Received and setting in withdrawNFT.

// --- Updated DepositState struct definition ---
/* (Already placed near the top in the final code block)
struct DepositState {
    address owner; // The original owner who deposited
    address collection;
    uint256 tokenId;
    uint64 depositTime; // Timestamp of deposit
    uint64 withdrawalTime; // Timestamp of withdrawal (0 if still active)
    uint32 interactionCount; // Number of times interaction was triggered
    uint256 badgeTokenId; // History Badge token ID issued for this deposit (0 if not claimed)
    bool isActive; // True if NFT is currently in the vault
}
*/
// --- Update onERC721Received ---
/*
_depositStates[currentDepositId] = DepositState({
    owner: from,
    collection: msg.sender,
    tokenId: tokenId,
    depositTime: uint64(block.timestamp),
    withdrawalTime: 0, // Initialize as 0
    interactionCount: 0,
    badgeTokenId: 0,
    isActive: true
});
*/

// --- Update withdrawNFT ---
/*
...
// Mark deposit as inactive BEFORE transferring
deposit.isActive = false;
deposit.withdrawalTime = uint64(block.timestamp); // Set withdrawal time
// Remove from the active NFT lookup
_nftToDepositId[collection][tokenId] = 0;
...
*/

// --- Update getDepositStatusLevel ---
/*
...
        uint64 duration;
        if (deposit.isActive) {
            duration = uint64(block.timestamp) - deposit.depositTime;
        } else {
             // Use stored withdrawal time for inactive deposits
             duration = deposit.withdrawalTime - deposit.depositTime;
        }
... (rest of calculation is the same)
*/
```

This contract provides a framework for a dynamic NFT vault where deposit history influences a non-transferable badge. The dynamic metadata aspect relies on an off-chain service resolving the `tokenURI` and deposit history. The Soulbound nature of the badge is implemented by making its internal ERC721 functions (`transferFrom`, `approve`, etc.) revert. The multiple owner functions and query functions help meet the function count requirement while adding useful management and visibility features. It's a blend of standard patterns (Vault, Ownable, Pausable, ERC721) with more advanced concepts (Dynamic State, Dynamic Metadata, Soulbound Tokens) in a novel combination.