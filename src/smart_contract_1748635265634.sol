Okay, let's design a smart contract that incorporates several advanced and interesting concepts beyond typical token or simple DeFi contracts.

**Concept:** **YieldBender NFT (Dynamic Yield Position NFT)**

This contract will issue Non-Fungible Tokens (NFTs) that represent a user's deposit of an underlying ERC-20 token. These NFTs are "Dynamic" because their attributes (metadata) change based on the state of the underlying position (principal, accrued yield, time held, interactions). It combines elements of DeFi (yield accrual, staking-like mechanics) with NFTs and adds features like delegation and dynamic metadata.

**Outline & Function Summary:**

1.  **Contract Name:** `YieldBenderNFT`
2.  **Inheritance:** ERC721, Ownable, Pausable, ReentrancyGuard
3.  **Core Concepts:**
    *   NFTs representing ERC-20 yield-bearing positions.
    *   Simulated yield accrual based on time and principal.
    *   Dynamic NFT Metadata reflecting position state (principal, yield, duration, claims).
    *   Position management functions (deposit, add, remove, claim, compound).
    *   Delegation of yield claiming rights.
    *   NFT locking mechanism (placeholder for potential future features).
    *   Protocol fees on withdrawals/claims.
    *   Admin controls for yield rate, fees, pausing.
4.  **State Variables:** Mappings to store position details, delegations, locks, fees, admin settings.
5.  **Structs:** `Position` to hold principal, deposit time, last claim time, accrued yield, total claimed yield.
6.  **Events:** Signify key actions (Deposit, Withdraw, Claim, Delegate, Lock, FeeWithdraw, SettingsUpdate).
7.  **Functions (20+):**

    *   **ERC721 Standard (10+):**
        *   `constructor`: Initializes the contract with name and symbol.
        *   `balanceOf(address owner)`: Returns the number of NFTs owned by an address.
        *   `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT.
        *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers an NFT, checks if receiver can accept.
        *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Same as above with data payload.
        *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers an NFT without safety check.
        *   `approve(address to, uint256 tokenId)`: Approves an address to spend an NFT.
        *   `getApproved(uint256 tokenId)`: Gets the approved address for a specific NFT.
        *   `setApprovalForAll(address operator, bool approved)`: Approves or revokes operator status for all owner's NFTs.
        *   `isApprovedForAll(address owner, address operator)`: Checks if operator is approved for all of owner's NFTs.
        *   `supportsInterface(bytes4 interfaceId)`: ERC165 standard check.
        *   `name()`: Returns the NFT collection name.
        *   `symbol()`: Returns the NFT collection symbol.
        *   `tokenURI(uint256 tokenId)`: Returns the URI for the NFT's metadata (dynamic part handled by a view function/off-chain).

    *   **Position Management (Specific) (~8):**
        *   `deposit(uint256 amount)`: Creates a new NFT position by depositing ERC-20 tokens.
        *   `addPrincipal(uint256 tokenId, uint256 amount)`: Adds principal to an existing position represented by an NFT.
        *   `removePrincipal(uint256 tokenId, uint256 amount)`: Partially withdraws principal from a position (subject to fees).
        *   `claimYield(uint256 tokenId)`: Claims accrued yield for a position (subject to fees if applicable).
        *   `compoundYield(uint256 tokenId)`: Adds accrued yield to the principal of a position.
        *   `getPositionDetails(uint256 tokenId)`: View function to get all stored details of a position.
        *   `getAccruedYield(uint256 tokenId)`: View function to calculate and return currently accrued yield.
        *   `getTotalPrincipal(uint256 tokenId)`: View function to get current principal amount.

    *   **Dynamic Metadata / Traits (~2):**
        *   `getNFTAttributes(uint256 tokenId)`: View function that calculates and returns the dynamic traits/attributes for a given NFT as a string (e.g., "Principal: 1000, Yield: 50, Duration: 30 days"). Note: Generating full JSON on-chain is gas-prohibitive; this function provides the *data* that an off-chain service would use to build the JSON metadata pointed to by `tokenURI`.
        *   `getBaseURI()`: View function to get the base URI for token metadata. (Admin function below to set it).

    *   **Delegation (~3):**
        *   `delegateYieldClaim(uint256 tokenId, address delegatee)`: Allows the NFT owner to delegate the right to claim yield to another address.
        *   `undelegateYieldClaim(uint256 tokenId)`: Revokes delegation for a specific NFT.
        *   `isYieldClaimDelegated(uint256 tokenId, address account)`: Checks if an account has been delegated yield claiming rights for an NFT.

    *   **Locking Mechanism (~2):**
        *   `lockNFTForBonus(uint256 tokenId)`: Locks the NFT, potentially enabling future bonus features (no actual bonus logic included, just the state change).
        *   `unlockNFT(uint256 tokenId)`: Unlocks the NFT.

    *   **Admin / Protocol Settings (~7):**
        *   `pause()`: Pauses critical contract functions (Owner only).
        *   `unpause()`: Unpauses the contract (Owner only).
        *   `setYieldRatePerSecond(uint256 rate)`: Sets the simulated yield rate (Owner only).
        *   `setWithdrawalFeeRateBps(uint256 rateBps)`: Sets the withdrawal/claim fee rate in basis points (Owner only).
        *   `setFeeRecipient(address recipient)`: Sets the address where protocol fees are sent (Owner only).
        *   `withdrawProtocolFees()`: Allows the fee recipient (or owner) to withdraw accumulated fees (or a designated address).
        *   `setMinDepositAmount(uint256 amount)`: Sets the minimum required amount for a new deposit (Owner only).
        *   `setBaseURI(string memory uri)`: Sets the base URI for token metadata (Owner only).

    *   **Helpers (Internal/View, not counted in 20+):**
        *   `_calculateYield(uint256 tokenId)`: Internal calculation of yield based on time, principal, and rate.
        *   `_updatePositionState(uint256 tokenId)`: Internal function to update last claim/interaction time and accrued yield.
        *   `_generateAttributesJson(uint256 tokenId)`: Internal helper to format attributes for `getNFTAttributes`.

**Solidity Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline & Function Summary ---
// Contract: YieldBenderNFT
// Description: An NFT representing a yield-bearing ERC-20 deposit position.
// The NFT's attributes are dynamic based on the position's state.

// Core Concepts:
// - Dynamic Yield Position NFTs
// - Time-based Simulated Yield Accrual
// - Dynamic NFT Metadata (via view function)
// - Position Management (Deposit, Add/Remove Principal, Claim/Compound Yield)
// - Yield Claim Delegation
// - NFT Locking Mechanism
// - Protocol Fees on Interactions
// - Admin Controls (Rates, Fees, Pausing)

// State Variables:
// - positions: Maps tokenId to Position struct
// - yieldClaimDelegates: Maps tokenId to delegatee address
// - nftLocked: Maps tokenId to boolean indicating lock status
// - accumulatedProtocolFees: Total fees collected
// - underlyingToken: The ERC-20 token address for deposits
// - yieldRatePerSecond: Simulated yield rate
// - withdrawalFeeRateBps: Fee rate in basis points (e.g., 100 = 1%)
// - feeRecipient: Address receiving protocol fees
// - minDepositAmount: Minimum tokens required for a new deposit
// - baseTokenURI: Base URI for metadata endpoints

// Structs:
// - Position: Stores principal, deposit time, last claim time, accrued yield, total claimed yield

// Events:
// - Deposit: Logs new position creation
// - PrincipalAdded: Logs addition to principal
// - PrincipalRemoved: Logs principal withdrawal
// - YieldClaimed: Logs yield claiming
// - YieldCompounded: Logs yield compounding
// - YieldClaimDelegated: Logs yield claim delegation
// - YieldClaimUndelegated: Logs yield claim revocation
// - NFTLocked: Logs NFT locking
// - NFTUnlocked: Logs NFT unlocking
// - ProtocolFeesWithdrawn: Logs withdrawal of fees
// - SettingsUpdated: Logs changes to admin settings

// Functions (20+):

// ERC721 Standard (12):
// constructor(string name, string symbol, address tokenAddress, address ownerAddress, address initialFeeRecipient)
// balanceOf(address owner) view
// ownerOf(uint256 tokenId) view
// safeTransferFrom(address from, address to, uint256 tokenId)
// safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// transferFrom(address from, address to, uint256 tokenId)
// approve(address to, uint256 tokenId)
// getApproved(uint256 tokenId) view
// setApprovalForAll(address operator, bool approved)
// isApprovedForAll(address owner, address operator) view
// supportsInterface(bytes4 interfaceId) view
// tokenURI(uint256 tokenId) view

// Position Management (8):
// deposit(uint256 amount) nonReentrant whenNotPaused
// addPrincipal(uint256 tokenId, uint256 amount) nonReentrant whenNotPaused
// removePrincipal(uint256 tokenId, uint256 amount) nonReentrant whenNotPaused
// claimYield(uint256 tokenId) nonReentrant whenNotPaused
// compoundYield(uint256 tokenId) nonReentrant whenNotPaused
// getPositionDetails(uint256 tokenId) view
// getAccruedYield(uint256 tokenId) view
// getTotalPrincipal(uint256 tokenId) view

// Dynamic Metadata / Traits (2):
// getNFTAttributes(uint256 tokenId) view - Provides data for dynamic metadata
// getBaseURI() view - Returns the base URI for metadata endpoint

// Delegation (3):
// delegateYieldClaim(uint256 tokenId, address delegatee) whenNotPaused
// undelegateYieldClaim(uint256 tokenId) whenNotPaused
// isYieldClaimDelegated(uint256 tokenId, address account) view

// Locking Mechanism (2):
// lockNFTForBonus(uint256 tokenId) whenNotPaused
// unlockNFT(uint256 tokenId) whenNotPaused

// Admin / Protocol Settings (7):
// pause() onlyOwner
// unpause() onlyOwner
// setYieldRatePerSecond(uint256 rate) onlyOwner
// setWithdrawalFeeRateBps(uint256 rateBps) onlyOwner
// setFeeRecipient(address recipient) onlyOwner
// withdrawProtocolFees() nonReentrant - Callable by feeRecipient or Owner
// setMinDepositAmount(uint256 amount) onlyOwner
// setBaseURI(string memory uri) onlyOwner

// --- End of Outline & Function Summary ---


contract YieldBenderNFT is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct Position {
        uint256 principal;
        uint256 depositTime;
        uint256 lastInteractionTime; // Last time yield was claimed/compounded/principal added/removed
        uint256 accruedYield;
        uint256 totalClaimedYield;
    }

    mapping(uint256 => Position) public positions;
    mapping(uint256 => address) private _yieldClaimDelegates;
    mapping(uint256 => bool) public nftLocked; // Simple lock state

    Counters.Counter private _tokenIdCounter;

    IERC20 public immutable underlyingToken;

    uint256 public yieldRatePerSecond; // Yield rate per second per token unit
    uint256 public withdrawalFeeRateBps; // Fee in basis points (e.g., 100 = 1%)
    address public feeRecipient;
    uint256 public minDepositAmount;

    uint256 public accumulatedProtocolFees;

    string private _baseTokenURI;

    // Errors
    error InsufficientAmount();
    error InvalidTokenId();
    error NotNFTAOwnerOrApproved();
    error OnlyNFTOwnerCanDelegate();
    error NotYieldClaimDelegatee();
    error NFTIsLocked();
    error NFTIsNotLocked();
    error FeeRecipientZeroAddress();
    error InvalidFeeRate();

    // Events
    event Deposit(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 depositTime);
    event PrincipalAdded(uint256 indexed tokenId, uint256 amount);
    event PrincipalRemoved(uint256 indexed tokenId, uint256 amount, uint256 fee);
    event YieldClaimed(uint256 indexed tokenId, address indexed claimant, uint256 amount, uint256 fee);
    event YieldCompounded(uint256 indexed tokenId, uint256 amount);
    event YieldClaimDelegated(uint256 indexed tokenId, address indexed delegatee);
    event YieldClaimUndelegated(uint256 indexed tokenId);
    event NFTLocked(uint256 indexed tokenId);
    event NFTUnlocked(uint256 indexed tokenId);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event SettingsUpdated(); // Generic event for owner-only setting changes

    constructor(
        string memory name,
        string memory symbol,
        address tokenAddress,
        address ownerAddress, // Explicitly set owner
        address initialFeeRecipient // Explicitly set fee recipient
    ) ERC721(name, symbol) Ownable(ownerAddress) Pausable(false) {
        require(tokenAddress != address(0), "Invalid token address");
        require(initialFeeRecipient != address(0), "Invalid fee recipient address");

        underlyingToken = IERC20(tokenAddress);
        feeRecipient = initialFeeRecipient;

        // Default settings - Owner should configure after deployment
        yieldRatePerSecond = 0; // Default 0, needs setting
        withdrawalFeeRateBps = 0; // Default 0, needs setting
        minDepositAmount = 0; // Default 0, needs setting
        _baseTokenURI = ""; // Default empty, needs setting

        emit SettingsUpdated();
    }

    // --- ERC721 Overrides & Standard Functions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId(); // Using a custom error for clarity
        }
        // Return base URI + tokenId. The actual metadata endpoint should
        // call getNFTAttributes(tokenId) to get the dynamic data.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // Standard ERC721 functions like balanceOf, ownerOf, transferFrom, etc.,
    // are inherited from OpenZeppelin and require no override unless custom logic is needed.
    // We'll rely on their standard implementation which handles ownership, approvals, etc.
    // The transfer functions will need `whenNotPaused`.

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
         _safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused {
         _safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        _transfer(from, to, tokenId); // Use internal _transfer from OZ
    }

    function approve(address to, uint256 tokenId) public override whenNotPaused {
        _approve(to, tokenId); // Use internal _approve from OZ
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        _setApprovalForAll(msg.sender, operator, approved); // Use internal from OZ
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC165) returns (bool) {
        // Include ERC165 itself and any other interfaces supported
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }


    // --- Position Management Functions ---

    /**
     * @dev Creates a new yield-bearing NFT position.
     * @param amount The amount of underlying tokens to deposit.
     */
    function deposit(uint256 amount) public nonReentrant whenNotPaused {
        if (amount < minDepositAmount) {
            revert InsufficientAmount();
        }

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        // Transfer tokens from user to contract
        underlyingToken.transferFrom(msg.sender, address(this), amount);

        // Mint NFT to the user
        _safeMint(msg.sender, newTokenId);

        // Store position details
        positions[newTokenId] = Position({
            principal: amount,
            depositTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            accruedYield: 0,
            totalClaimedYield: 0
        });

        emit Deposit(msg.sender, newTokenId, amount, block.timestamp);
    }

    /**
     * @dev Adds principal to an existing position.
     * @param tokenId The ID of the NFT representing the position.
     * @param amount The amount of underlying tokens to add.
     */
    function addPrincipal(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
        // Only NFT owner or approved can add principal
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotNFTAOwnerOrApproved();
        }
        if (amount == 0) revert InsufficientAmount();
        if (nftLocked[tokenId]) revert NFTIsLocked();

        // Update accrued yield before modifying principal
        _updatePositionState(tokenId);

        // Transfer tokens from user to contract
        underlyingToken.transferFrom(msg.sender, address(this), amount);

        positions[tokenId].principal += amount;
        positions[tokenId].lastInteractionTime = block.timestamp; // Reset interaction time to include this
        // AccruedYield remains as calculated before adding principal,
        // it will start accumulating on the new principal amount from block.timestamp

        emit PrincipalAdded(tokenId, amount);
    }

    /**
     * @dev Partially withdraws principal from an existing position.
     * Applies a withdrawal fee.
     * @param tokenId The ID of the NFT representing the position.
     * @param amount The amount of principal to withdraw.
     */
    function removePrincipal(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
        // Only NFT owner or approved can withdraw principal
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotNFTAOwnerOrApproved();
        }
        if (amount == 0 || amount > positions[tokenId].principal) revert InsufficientAmount();
        if (nftLocked[tokenId]) revert NFTIsLocked();

        // Update accrued yield before withdrawing
        _updatePositionState(tokenId);

        uint256 feeAmount = (amount * withdrawalFeeRateBps) / 10000;
        uint256 amountAfterFee = amount - feeAmount;

        positions[tokenId].principal -= amount;
        positions[tokenId].lastInteractionTime = block.timestamp; // Reset interaction time
        // AccruedYield remains as calculated before withdrawal

        // Transfer tokens to user
        underlyingToken.transfer(msg.sender, amountAfterFee);

        // Accumulate fees
        accumulatedProtocolFees += feeAmount;

        // If principal becomes 0, consider burning the NFT? Or allow 0 principal position?
        // Let's allow 0 principal, the NFT still exists representing the historical position.
        // A separate burn function could be added if needed.

        emit PrincipalRemoved(tokenId, amount, feeAmount);
    }

    /**
     * @dev Claims accrued yield for a position.
     * Applies a fee on the claimed amount.
     * @param tokenId The ID of the NFT representing the position.
     */
    function claimYield(uint256 tokenId) public nonReentrant whenNotPaused {
        // Only NFT owner, approved, OR DELEGATEE can claim yield
        address owner = ownerOf(tokenId);
        bool isOwnerOrApproved = (msg.sender == owner || isApprovedForAll(owner, msg.sender));
        bool isDelegatee = (_yieldClaimDelegates[tokenId] == msg.sender);

        if (!isOwnerOrApproved && !isDelegatee) {
             revert NotNFTAOwnerOrApproved(); // Reusing error, could make a more specific one
        }
         if (nftLocked[tokenId]) revert NFTIsLocked();

        _updatePositionState(tokenId); // Calculate latest yield

        uint256 yieldToClaim = positions[tokenId].accruedYield;
        if (yieldToClaim == 0) {
            return; // Nothing to claim
        }

        uint256 feeAmount = (yieldToClaim * withdrawalFeeRateBps) / 10000;
        uint256 yieldAfterFee = yieldToClaim - feeAmount;

        positions[tokenId].accruedYield = 0; // Reset accrued yield
        positions[tokenId].lastInteractionTime = block.timestamp; // Reset interaction time
        positions[tokenId].totalClaimedYield += yieldAfterFee; // Track total claimed

        // Transfer tokens to user (or delegatee)
        underlyingToken.transfer(msg.sender, yieldAfterFee);

        // Accumulate fees
        accumulatedProtocolFees += feeAmount;

        emit YieldClaimed(tokenId, msg.sender, yieldToClaim, feeAmount);
    }

    /**
     * @dev Compounds accrued yield into the principal for a position.
     * No fee on compounding.
     * @param tokenId The ID of the NFT representing the position.
     */
    function compoundYield(uint256 tokenId) public nonReentrant whenNotPaused {
        // Only NFT owner or approved can compound
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotNFTAOwnerOrApproved();
        }
         if (nftLocked[tokenId]) revert NFTIsLocked();

        _updatePositionState(tokenId); // Calculate latest yield

        uint256 yieldToCompound = positions[tokenId].accruedYield;
        if (yieldToCompound == 0) {
            return; // Nothing to compound
        }

        positions[tokenId].principal += yieldToCompound;
        positions[tokenId].accruedYield = 0; // Reset accrued yield
        positions[tokenId].lastInteractionTime = block.timestamp; // Reset interaction time
        // totalClaimedYield does not increase on compound

        emit YieldCompounded(tokenId, yieldToCompound);
    }

     /**
     * @dev Gets the details of a specific position.
     * @param tokenId The ID of the NFT.
     * @return Position struct containing principal, timestamps, and yield amounts.
     */
    function getPositionDetails(uint256 tokenId) public view returns (Position memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Calculate current accrued yield before returning details
        Position memory pos = positions[tokenId];
        pos.accruedYield = _calculateYield(tokenId); // Calculate 'on the fly'
        return pos;
    }

     /**
     * @dev Calculates the currently accrued yield for a position.
     * @param tokenId The ID of the NFT.
     * @return The calculated accrued yield.
     */
    function getAccruedYield(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _calculateYield(tokenId);
    }

    /**
     * @dev Gets the current principal amount for a position.
     * @param tokenId The ID of the NFT.
     * @return The principal amount.
     */
    function getTotalPrincipal(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId();
        return positions[tokenId].principal;
    }


    // --- Dynamic Metadata / Traits Functions ---

    /**
     * @dev Calculates and returns the dynamic attributes for an NFT.
     * This function provides the data that an off-chain service would use
     * to build the JSON metadata for tokenURI.
     * @param tokenId The ID of the NFT.
     * @return A string representing the attributes (e.g., "Principal: X, Yield: Y, Duration: Z days").
     *         This is a simplified representation; in a real app, this might return structured data.
     */
    function getNFTAttributes(uint256 tokenId) public view returns (string memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();

        Position memory pos = positions[tokenId];
        uint256 currentAccrued = _calculateYield(tokenId);

        // Basic attribute string formation - complex JSON generation is gas prohibitive on-chain
        // Off-chain metadata service calls this function and formats the data as JSON.
        string memory principalStr = pos.principal.toString();
        string memory accruedStr = currentAccrued.toString();
        string memory claimedStr = pos.totalClaimedYield.toString();
        uint256 durationSeconds = block.timestamp - pos.depositTime;
        string memory durationDaysStr = (durationSeconds / 86400).toString(); // Seconds to days
        string memory lockStatus = nftLocked[tokenId] ? "Locked" : "Unlocked";

        return string(abi.encodePacked(
            '{"principal": ', principalStr,
            ', "accrued_yield": ', accruedStr,
            ', "total_claimed": ', claimedStr,
            ', "duration_days": ', durationDaysStr,
            ', "lock_status": "', lockStatus, '"}'
            // Add more attributes as needed, e.g., yield rate, last interaction time
        ));
    }

    /**
     * @dev Returns the base URI for token metadata.
     */
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // --- Delegation Functions ---

    /**
     * @dev Allows the NFT owner to delegate the right to claim yield for a position.
     * @param tokenId The ID of the NFT.
     * @param delegatee The address to delegate claiming rights to. Address(0) to remove.
     */
    function delegateYieldClaim(uint256 tokenId, address delegatee) public whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert OnlyNFTOwnerCanDelegate();
         if (nftLocked[tokenId]) revert NFTIsLocked();

        _yieldClaimDelegates[tokenId] = delegatee;
        if (delegatee != address(0)) {
             emit YieldClaimDelegated(tokenId, delegatee);
        } else {
             emit YieldClaimUndelegated(tokenId);
        }
    }

     /**
     * @dev Revokes delegation for a specific NFT.
     * @param tokenId The ID of the NFT.
     */
    function undelegateYieldClaim(uint256 tokenId) public whenNotPaused {
         address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert OnlyNFTOwnerCanDelegate();
         if (nftLocked[tokenId]) revert NFTIsLocked();

        _yieldClaimDelegates[tokenId] = address(0);
         emit YieldClaimUndelegated(tokenId);
    }

    /**
     * @dev Checks if an account has been delegated yield claiming rights for an NFT.
     * @param tokenId The ID of the NFT.
     * @param account The address to check.
     * @return bool True if delegated, false otherwise.
     */
    function isYieldClaimDelegated(uint256 tokenId, address account) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        return _yieldClaimDelegates[tokenId] == account;
    }


    // --- Locking Mechanism Functions ---

    /**
     * @dev Locks an NFT. Could be used for staking bonuses or other features.
     * (No actual bonus logic implemented here).
     * @param tokenId The ID of the NFT.
     */
    function lockNFTForBonus(uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotNFTAOwnerOrApproved();
        }
        if (nftLocked[tokenId]) revert NFTIsLocked();

        nftLocked[tokenId] = true;
        // Potentially update state or start timers for bonus eligibility here
        emit NFTLocked(tokenId);
    }

    /**
     * @dev Unlocks a previously locked NFT.
     * @param tokenId The ID of the NFT.
     */
    function unlockNFT(uint256 tokenId) public whenNotPaused {
         address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert NotNFTAOwnerOrApproved();
        }
        if (!nftLocked[tokenId]) revert NFTIsNotLocked();

        nftLocked[tokenId] = false;
         // Potentially finalize bonus calculations or state changes here
        emit NFTUnlocked(tokenId);
    }


    // --- Admin / Protocol Settings Functions ---

    /**
     * @dev Pauses critical contract interactions. Only callable by owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the simulated yield rate per second per token unit.
     * The rate is denominated such that yield = principal * rate * time.
     * Rate 1e18 means 1 token per second per token. Use a smaller unit.
     * E.g., 1 token/year rate = 1e18 / (365 * 86400).
     * @param rate The new yield rate per second.
     */
    function setYieldRatePerSecond(uint256 rate) public onlyOwner {
        yieldRatePerSecond = rate;
        emit SettingsUpdated();
    }

    /**
     * @dev Sets the fee rate applied to withdrawals and claims in basis points.
     * 100 basis points = 1%. Max 10000 (100%).
     * @param rateBps The new fee rate in basis points.
     */
    function setWithdrawalFeeRateBps(uint256 rateBps) public onlyOwner {
        if (rateBps > 10000) revert InvalidFeeRate(); // Max 100%
        withdrawalFeeRateBps = rateBps;
        emit SettingsUpdated();
    }

     /**
     * @dev Sets the address where protocol fees are accumulated.
     * @param recipient The new fee recipient address.
     */
    function setFeeRecipient(address recipient) public onlyOwner {
        if (recipient == address(0)) revert FeeRecipientZeroAddress();
        feeRecipient = recipient;
        emit SettingsUpdated();
    }

     /**
     * @dev Allows the fee recipient or owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() public nonReentrant {
        if (msg.sender != owner() && msg.sender != feeRecipient) {
            revert OwnableUnauthorizedAccount(msg.sender); // Using inherited error
        }

        uint256 feesToWithdraw = accumulatedProtocolFees;
        if (feesToWithdraw == 0) return;

        accumulatedProtocolFees = 0;
        underlyingToken.transfer(feeRecipient, feesToWithdraw);

        emit ProtocolFeesWithdrawn(feeRecipient, feesToWithdraw);
    }

    /**
     * @dev Sets the minimum amount required for a new deposit.
     * @param amount The new minimum deposit amount.
     */
    function setMinDepositAmount(uint256 amount) public onlyOwner {
        minDepositAmount = amount;
        emit SettingsUpdated();
    }

     /**
     * @dev Sets the base URI for token metadata.
     * @param uri The new base URI.
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit SettingsUpdated();
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to calculate yield accrued since last interaction.
     * @param tokenId The ID of the NFT.
     * @return The newly accrued yield.
     */
    function _calculateYield(uint256 tokenId) internal view returns (uint256) {
        Position storage pos = positions[tokenId];
        uint256 timeElapsed = block.timestamp - pos.lastInteractionTime;

        // Avoid overflow: calculate (principal * time) first if necessary
        // For simplicity here, assume multiplication doesn't overflow typical uint256 capacity
        // with reasonable yield rates and timeframes.
        uint256 yieldToAdd = (pos.principal * timeElapsed * yieldRatePerSecond) / (1e18); // Assuming yieldRatePerSecond is in 1e18 units

        return pos.accruedYield + yieldToAdd;
    }

     /**
     * @dev Internal function to update the position state including accrued yield.
     * Call this before modifying principal or interacting with accrued yield.
     * @param tokenId The ID of the NFT.
     */
    function _updatePositionState(uint256 tokenId) internal {
         Position storage pos = positions[tokenId];
         uint256 newlyAccrued = _calculateYield(tokenId) - pos.accruedYield;

         pos.accruedYield += newlyAccrued;
         pos.lastInteractionTime = block.timestamp;
    }

    // --- Bonus/Conceptual Functions (for meeting 20+ requirement with interesting ideas) ---

    /**
     * @dev Example: Checks if an external signature is valid for a specific NFT owner and message.
     * This is a conceptual function demonstrating how signature validation could be integrated,
     * potentially for off-chain actions authenticated by NFT ownership.
     * Note: This does NOT verify ownership at the time of signature, only verifies the signature itself.
     * You'd need to combine this with ownerOf checks.
     * @param tokenId The ID of the NFT.
     * @param hash The message hash that was signed.
     * @param signature The signature bytes.
     * @return bool True if the signature is valid for the current owner and hash.
     */
    function isNFTSignatureValid(uint256 tokenId, bytes32 hash, bytes memory signature) public view returns (bool) {
        if (!_exists(tokenId)) return false;
        address expectedSigner = ownerOf(tokenId);
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)); // Standard message prefix
        address signer = ECDSA.recover(messageHash, signature);
        return signer == expectedSigner;
    }

    // Need 20+ functions, let's check count:
    // ERC721 (12) + Position (8) + Metadata (2) + Delegation (3) + Locking (2) + Admin (7) + Bonus (1) = 35 functions.

    // Ensure the ERC721 hooks that interact with state (like _beforeTokenTransfer)
    // are compatible or overridden if needed, but OZ standard ones should be fine.
    // For this concept, transferring the NFT transfers the *entire position*.

    // ReentrancyGuard is used on functions that make external calls (token transfers)
    // after state changes, or where state changes depend on complex external calls.
    // `deposit`, `addPrincipal`, `removePrincipal`, `claimYield`, `compoundYield`, `withdrawProtocolFees`
    // all involve token transfers, so they use `nonReentrant`.

    // Pausable is used on core interaction functions:
    // `safeTransferFrom`, `transferFrom`, `approve`, `setApprovalForAll`,
    // `deposit`, `addPrincipal`, `removePrincipal`, `claimYield`, `compoundYield`,
    // `delegateYieldClaim`, `undelegateYieldClaim`, `lockNFTForBonus`, `unlockNFT`.

}
```

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic NFT Metadata:** While the contract doesn't generate the *image* or the full JSON *on-chain* (which is gas-prohibitive), the `getNFTAttributes` view function *computes* the key characteristics of the NFT's underlying position in real-time (principal, accrued yield, duration, etc.). An off-chain metadata server would call this function using the `tokenURI` pointer (`baseURI + tokenId`) and serve the actual JSON, making the NFT's appearance or description dynamic based on its on-chain state.
2.  **Yield Accrual (Simulated):** The contract simulates yield accrual based on the `yieldRatePerSecond`, principal, and the time elapsed since the last interaction (`lastInteractionTime`). This avoids relying on complex external DeFi protocol integrations while demonstrating the concept.
3.  **Position as NFT:** The ERC-721 token is not just a collectible; it's a financial instrument representing a claim on underlying tokens and accrued yield. Transferring the NFT means transferring the entire position.
4.  **Yield Claim Delegation:** The `delegateYieldClaim` allows the NFT owner to grant a specific address the right *only* to claim the yield, not manage the principal or transfer the NFT. This is useful for custodial services, yield farming pools, or allowing someone else to manage distributions without full control.
5.  **NFT Locking:** The `lockNFTForBonus` function introduces a state variable that can be used in future logic (not implemented here beyond the state change) for features like staking bonuses, participation requirements, or gating access based on the NFT being locked.
6.  **Protocol Fees:** Fees are applied to `removePrincipal` and `claimYield` and accumulate in the contract, payable to a configurable `feeRecipient`. This is a common mechanism in DeFi protocols.
7.  **Access Control & Pausing:** Standard `Ownable` and `Pausable` are used, but applied strategically to sensitive or interaction-heavy functions.
8.  **Reentrancy Guard:** Used on functions that transfer tokens to prevent reentrancy attacks.
9.  **On-Chain Signature Validation (`isNFTSignatureValid`):** A conceptual function demonstrating how to verify a signed message on-chain. This could be used for off-chain applications that need proof of NFT ownership or authorization without requiring a transaction for every interaction (e.g., signing up for a service with your NFT, proving ownership for airdrops, etc.).

This contract provides a framework for a dynamic, yield-bearing NFT, offering a combination of standard NFT practices with DeFi mechanics, delegation, and hooks for future dynamic features. Remember that for production use, the yield calculation, fee mechanisms, and security aspects would require thorough testing and auditing. The metadata part relies on an off-chain component to fully function.