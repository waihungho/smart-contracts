Okay, here is a Solidity smart contract for a "Quantum-Inspired Encrypted NFT Marketplace".

This contract combines several concepts:
1.  **NFTs:** Standard ERC721 tokens with added data.
2.  **Encrypted Metadata:** The core concept is that sensitive NFT metadata is stored *encrypted* on-chain.
3.  **On-Chain Key Management:** The decryption key (or rather, its encrypted form or a pointer to it) is also managed by the contract.
4.  **Controlled Revelation:** Users must *request* and *receive approval* (based on pre-set conditions like purchase, time, or manual approval) via the contract to get the key and decrypt the off-chain metadata.
5.  **Marketplace:** Functionality to list and buy these specific NFTs.
6.  **Separate Key Listings:** A unique feature allowing the *decryption right* (the key) to be listed and sold separately from the NFT ownership itself.
7.  **Delegated Reveal Rights:** Owners can delegate the ability to request reveals to other addresses.
8.  **Royalty Splits:** Custom royalty management beyond standard ERC2981.
9.  **Pausable & Admin Controls:** Standard safety features.

**Note on "Quantum-Inspired":** Solidity itself cannot perform quantum-resistant cryptography. The "Quantum-Inspired" aspect here is thematic – the marketplace is designed for assets whose *off-chain* metadata *could* be encrypted using quantum-resistant algorithms. The contract manages the *release* of the simulated decryption key based on on-chain logic. The actual encryption/decryption and key storage (beyond the encrypted representation on-chain) are handled off-chain by users/services interacting with the contract. The contract primarily enforces access control to the "key" data stored within it.

---

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// =============================================================================
//                             Contract Outline
// =============================================================================
// 1. State Variables & Data Structures:
//    - Store encrypted metadata and keys per token.
//    - Manage listings (NFTs for sale).
//    - Manage key listings (decryption rights for sale).
//    - Track reveal requests and their status.
//    - Define reveal conditions (purchase, timelock, manual).
//    - Manage delegated reveal rights.
//    - Store marketplace fee config and collected fees.
//    - Custom royalty splits per token.
// 2. Events: Signal key actions (mint, list, buy, reveal, etc.).
// 3. Modifiers: Custom access control (e.g., onlyMinter).
// 4. Constructor: Initialize base ERC721, Ownable, Pausable.
// 5. Core NFT & Encryption Management:
//    - Minting NFTs with initial encrypted data and key.
//    - Updating encrypted data/key (simulating re-encryption).
//    - Setting reveal conditions for metadata.
// 6. Marketplace (NFTs):
//    - Listing NFTs for sale.
//    - Buying listed NFTs (handles ownership transfer, fees, royalties, initiates reveal).
//    - Cancelling NFT listings.
//    - Updating NFT listing price.
// 7. Marketplace (Keys/Decryption Rights):
//    - Listing the decryption right (key) for sale separately.
//    - Buying listed decryption rights (grants reveal access).
//    - Cancelling key listings.
//    - Updating key listing price.
// 8. Metadata Reveal Flow:
//    - Requesting metadata reveal (by owner or delegate).
//    - Approving/Rejecting reveal requests (based on condition).
//    - Retrieving the decryption key (view function after approval).
//    - Delegating reveal rights.
//    - Admin emergency reveal.
// 9. Fees & Royalties:
//    - Setting marketplace fee percentage and recipient.
//    - Withdrawing collected fees.
//    - Implementing ERC2981 royalties.
//    - Managing custom royalty splits.
// 10. Admin & Security:
//     - Pause/Unpause contract.
//     - Owner-only functions.
//     - Reentrancy Guard.
// 11. View Functions: Read contract state (listings, reveals, config, etc.).

// =============================================================================
//                             Function Summary
// =============================================================================
// (Total Public/External Functions: 26+)

// --- Core NFT & Encryption Management ---
// 1.  mintEncryptedNFT(address to, uint256 tokenId, bytes calldata encryptedMetadata, bytes calldata encryptedKey, RevealCondition initialCondition): Mints a new NFT with encrypted data/key and sets the initial reveal condition.
// 2.  reEncryptMetadata(uint256 tokenId, bytes calldata newEncryptedMetadata, bytes calldata newEncryptedKey): Allows token owner to update the encrypted data and key (simulating re-encryption).
// 3.  setRevealCondition(uint256 tokenId, RevealCondition newCondition, uint64 timelockEndTime): Sets/updates the condition required to reveal metadata for a token.

// --- Marketplace (NFTs) ---
// 4.  listEncryptedNFT(uint256 tokenId, uint256 price): Lists an owned encrypted NFT for sale on the marketplace.
// 5.  buyEncryptedNFT(uint256 tokenId): Buys a listed encrypted NFT. Handles payment, fees, royalties, transfers ownership, and initiates the reveal process for the new owner.
// 6.  cancelListing(uint256 tokenId): Cancels an active NFT listing.
// 7.  updateListingPrice(uint256 tokenId, uint256 newPrice): Updates the price of an active NFT listing.

// --- Marketplace (Keys/Decryption Rights) ---
// 8.  listKey(uint256 tokenId, uint256 price): Lists the decryption right (key) for a token for sale separately.
// 9.  buyKey(uint256 tokenId): Buys the listed decryption right (key) for a token. Grants the buyer access to the key without transferring NFT ownership.
// 10. cancelKeyListing(uint256 tokenId): Cancels an active key listing.
// 11. updateKeyListingPrice(uint256 tokenId, uint256 newPrice): Updates the price of an active key listing.

// --- Metadata Reveal Flow ---
// 12. requestMetadataReveal(uint256 tokenId): Initiates a request to reveal the metadata decryption key for a token. Callable by owner or delegate.
// 13. approveMetadataReveal(uint256 tokenId, address requester): Approves a pending metadata reveal request. Callable by token owner if ManualApproval is required.
// 14. grantDelegateReveal(uint256 tokenId, address delegate): Grants an address the right to request metadata reveal on behalf of the owner.
// 15. revokeDelegateReveal(uint256 tokenId, address delegate): Revokes a delegated reveal right.
// 16. emergencyRevealKey(uint256 tokenId, address recipient): Allows the contract owner (admin) to reveal the key to a specific recipient in emergency situations.

// --- Fees & Royalties ---
// 17. setMarketplaceFee(uint96 feeNumerator): Sets the marketplace fee percentage (e.g., 250 for 2.5%).
// 18. setFeeRecipient(address recipient): Sets the address where marketplace fees are sent.
// 19. withdrawFees(): Allows the fee recipient to withdraw collected fees.
// 20. setDefaultRoyalty(uint96 royaltyNumerator): Sets a default royalty percentage for new mints if not specified.
// 21. setPrimarySaleRoyalty(uint256 tokenId, address recipient, uint96 royaltyNumerator): Overrides the default royalty for a specific token's primary sale (part of ERC2981).
// 22. addRoyaltyRecipient(uint256 tokenId, address recipient, uint96 percentageBasisPoints): Adds a recipient and their percentage share for custom secondary sale royalty splits for a token (beyond ERC2981).
// 23. removeRoyaltyRecipient(uint256 tokenId, address recipient): Removes a custom royalty recipient for a token.

// --- Admin & Security ---
// 24. pause(): Pauses contract functionality (listings, buys, reveals). Owner only.
// 25. unpause(): Unpauses the contract. Owner only.
// 26. transferOwnership(address newOwner): Transfers contract ownership.

// --- View Functions (Internal or Public/External - Read Only) ---
//    tokenURI(uint256 tokenId): Returns the URI for the token's *public* metadata.
//    royaltyInfo(uint256 tokenId, uint256 salePrice): Returns royalty information (part of ERC2981).
//    getListing(uint256 tokenId): Returns details of an active NFT listing.
//    getKeyListing(uint256 tokenId): Returns details of an active key listing.
//    getRevealRequest(uint256 tokenId, address requester): Returns details of a pending reveal request.
//    getRevealCondition(uint256 tokenId): Returns the reveal condition for a token.
//    getDelegates(uint256 tokenId): Returns list of addresses with delegated reveal rights for a token.
//    getEncryptedMetadata(uint256 tokenId): Returns the stored encrypted metadata (requires specific access or just public view of encrypted bytes).
//    getDecryptionKey(uint256 tokenId): Returns the decryption key *if* the requester is approved (access controlled). This is the crucial *controlled* view.
//    getCustomRoyaltyRecipients(uint256 tokenId): Returns custom royalty split recipients for a token.

// Note: Standard ERC721/ERC165/ERC721Enumerable/ERC2981/Pausable/Ownable functions like
// name(), symbol(), balanceOf(), ownerOf(), approve(), setApprovalForAll(), getApproved(),
// isApprovedForAll(), totalSupply(), tokenOfOwnerByIndex(), tokenByIndex(), supportsInterface()
// transferOwnership(), renounceOwnership(), paused() are also available via inheritance.
// We count our *custom* logic functions towards the 20+ requirement.

```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC2981/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // To handle potential transfers from other contracts

contract QuantumEncryptedNFTMarketplace is ERC721Enumerable, ERC2981, Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables & Data Structures ---

    // Struct to store encrypted metadata and key per token
    struct EncryptedData {
        bytes encryptedMetadata;
        bytes encryptedKey; // This is the key required to decrypt encryptedMetadata off-chain
    }

    mapping(uint256 => EncryptedData) private _encryptedTokenData;

    // Enum to define conditions for revealing the decryption key
    enum RevealCondition {
        Purchase,       // Key revealed automatically upon purchase via this contract
        Timelock,       // Key revealed after a specific time passes since purchase/mint
        ManualApproval, // Key reveal requires manual approval by the token owner
        Always          // Key is always visible (e.g., for publicly known data)
    }

    struct RevealStatus {
        RevealCondition condition;
        uint64 timelockEndTime; // Used if condition is Timelock
        bool manualApproved;    // Used if condition is ManualApproval
        address requester;      // Address that requested the reveal
        bool requested;         // Whether a reveal has been requested
        bool canBeRevealed;     // Calculated status: whether conditions are met for retrieval
    }

    // Maps tokenId -> Address -> RevealStatus (Allows multiple requesters if needed, though primary use is current owner)
    mapping(uint256 => mapping(address => RevealStatus)) private _revealRequests;

    // Maps tokenId -> Address -> bool (Allows specific addresses to request reveal on owner's behalf)
    mapping(uint256 => mapping(address => bool)) private _delegateRevealRights;

    // Struct for NFT Listings
    struct NFTListing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => NFTListing) private _nftListings; // tokenId -> Listing

    // Struct for Decryption Key Listings (selling the right to decrypt, not the NFT itself)
    struct KeyListing {
        uint256 tokenId;
        address seller; // Seller of the *key*, usually the NFT owner
        uint256 price;
        bool active;
    }

    mapping(uint256 => KeyListing) private _keyListings; // tokenId -> KeyListing

    // Marketplace Fees
    uint96 private _marketplaceFeeNumerator; // e.g., 250 for 2.5% (250/10000)
    uint96 private constant FEE_DENOMINATOR = 10000;
    address private _feeRecipient;
    uint256 private _collectedFees;

    // Custom Royalty Splits (beyond ERC2981 primary sale)
    // Maps tokenId -> Recipient Address -> Percentage (out of 10000)
    mapping(uint256 => mapping(address => uint96)) private _customRoyaltySplits;
    mapping(uint256 => address[]) private _customRoyaltyRecipients; // To iterate over recipients

    // Default royalty for primary sales if not set per token
    uint96 private _defaultRoyaltyNumerator;
    address private _defaultRoyaltyRecipient;

    // --- Events ---

    event EncryptedNFTMinted(uint256 indexed tokenId, address indexed owner, bytes encryptedMetadataHash, bytes encryptedKeyHash, RevealCondition initialCondition);
    event MetadataReEncrypted(uint256 indexed tokenId, bytes newEncryptedMetadataHash, bytes newEncryptedKeyHash);
    event RevealConditionUpdated(uint256 indexed tokenId, RevealCondition newCondition, uint64 timelockEndTime);

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ListingCancelled(uint256 indexed tokenId);
    event ListingPriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    event KeyListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event KeyBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event KeyListingCancelled(uint256 indexed tokenId);
    event KeyListingPriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    event MetadataRevealRequested(uint256 indexed tokenId, address indexed requester, RevealCondition condition);
    event MetadataRevealApproved(uint256 indexed tokenId, address indexed requester, RevealCondition condition);
    // Note: Key retrieval happens via a view function after approval, no event needed for the view call itself.
    event DelegateRevealGranted(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event DelegateRevealRevoked(uint256 indexed tokenId, address indexed owner, address indexed delegate);
    event EmergencyKeyRevealed(uint256 indexed tokenId, address indexed admin, address indexed recipient);

    event MarketplaceFeeUpdated(uint96 feeNumerator);
    event FeeRecipientUpdated(address indexed recipient);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event CustomRoyaltyRecipientAdded(uint256 indexed tokenId, address indexed recipient, uint96 percentageBasisPoints);
    event CustomRoyaltyRecipientRemoved(uint256 indexed tokenId, address indexed recipient);

    // --- Constructor ---

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
        Pausable()
    {
        _feeRecipient = msg.sender; // Default fee recipient is owner
        _marketplaceFeeNumerator = 0; // Start with no fees
        _defaultRoyaltyRecipient = address(0); // No default royalty initially
        _defaultRoyaltyNumerator = 0;
    }

    // --- Overrides ---

    // ERC721 standard overrides to integrate with Pausable and custom minting
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) whenNotPaused returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        // Clean up associated data upon burn
        delete _encryptedTokenData[tokenId];
        delete _nftListings[tokenId];
        delete _keyListings[tokenId];
        delete _revealRequests[tokenId]; // Clears all requests for this token
        delete _delegateRevealRights[tokenId]; // Clears all delegates
        delete _customRoyaltySplits[tokenId];
        delete _customRoyaltyRecipients[tokenId];

        super._burn(tokenId);
    }

    // Implement ERC165 and ERC2981 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId ||
               interfaceId == type(IERC2981).interfaceId ||
               interfaceId == type(IERC721Receiver).interfaceId || // Support onERC721Received
               super.supportsInterface(interfaceId);
    }

    // ERC2981 Royalty Implementation
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override(ERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Check for specific token royalty first
        (receiver, royaltyAmount) = super.royaltyInfo(tokenId, salePrice);

        if (receiver == address(0) && _defaultRoyaltyRecipient != address(0)) {
            // If no token-specific royalty, use default primary sale royalty
            receiver = _defaultRoyaltyRecipient;
            royaltyAmount = salePrice.mul(_defaultRoyaltyNumerator).div(FEE_DENOMINATOR);
        }

        // Note: Custom splits handled separately during buyKey/buyEncryptedNFT if it's a secondary sale
        // ERC2981 standard is for primary sales primarily, this contract extends secondary sale royalty logic separately.
        return (receiver, royaltyAmount);
    }

    // --- Core NFT & Encryption Management ---

    /// @notice Mints a new encrypted NFT. Only callable by owner initially or designated minters (if implemented).
    /// @param to The recipient address.
    /// @param tokenId The unique identifier for the token.
    /// @param encryptedMetadata The encrypted metadata bytes.
    /// @param encryptedKey The encrypted decryption key bytes.
    /// @param initialCondition The initial condition for revealing the key.
    function mintEncryptedNFT(
        address to,
        uint256 tokenId,
        bytes calldata encryptedMetadata,
        bytes calldata encryptedKey,
        RevealCondition initialCondition
    ) external onlyOwner whenNotPaused {
        // Check if token already exists
        require(!_exists(tokenId), "Token already minted");

        _safeMint(to, tokenId);

        _encryptedTokenData[tokenId] = EncryptedData({
            encryptedMetadata: encryptedMetadata,
            encryptedKey: encryptedKey
        });

        // Set initial reveal condition
        _revealRequests[tokenId][to] = RevealStatus({
            condition: initialCondition,
            timelockEndTime: 0, // Default, set later if Timelock
            manualApproved: false,
            requester: address(0), // No request initiated yet
            requested: false,
            canBeRevealed: false
        });

        // Apply default royalty if set and not overridden later by setPrimarySaleRoyalty
        if (_defaultRoyaltyRecipient != address(0)) {
            _setPrimarySaleRecipient(tokenId, _defaultRoyaltyRecipient);
            _setDefaultRoyalty(tokenId, _defaultRoyaltyNumerator); // Use ERC2981 internal helper
        }


        emit EncryptedNFTMinted(
            tokenId,
            to,
            keccak256(encryptedMetadata), // Emit hash, not raw data for privacy
            keccak256(encryptedKey),       // Emit hash
            initialCondition
        );
    }

    /// @notice Allows the token owner to update the encrypted metadata and key.
    /// This simulates key rotation or dynamic metadata updates.
    /// @param tokenId The token identifier.
    /// @param newEncryptedMetadata The new encrypted metadata bytes.
    /// @param newEncryptedKey The new encrypted decryption key bytes.
    function reEncryptMetadata(uint256 tokenId, bytes calldata newEncryptedMetadata, bytes calldata newEncryptedKey) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only token owner can re-encrypt");

        _encryptedTokenData[tokenId].encryptedMetadata = newEncryptedMetadata;
        _encryptedTokenData[tokenId].encryptedKey = newEncryptedKey;

        // Reset reveal requests for this token as the key has changed
        delete _revealRequests[tokenId];

        emit MetadataReEncrypted(
            tokenId,
            keccak256(newEncryptedMetadata),
            keccak256(newEncryptedKey)
        );
    }

    /// @notice Sets or updates the condition required for revealing the metadata decryption key.
    /// @param tokenId The token identifier.
    /// @param newCondition The new reveal condition.
    /// @param timelockEndTime The end time for Timelock condition (ignored otherwise).
    function setRevealCondition(uint256 tokenId, RevealCondition newCondition, uint64 timelockEndTime) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only token owner can set reveal condition");

        // Update the condition for the current owner's reveal status (and potentially future owners)
        // Note: This simplifies; a more complex version might track conditions per ownership epoch.
        RevealStatus storage currentOwnerStatus = _revealRequests[tokenId][owner];
        currentOwnerStatus.condition = newCondition;
        currentOwnerStatus.timelockEndTime = (newCondition == RevealCondition.Timelock) ? timelockEndTime : 0;
        currentOwnerStatus.manualApproved = false; // Reset manual approval
        currentOwnerStatus.requested = false; // Reset request status
        currentOwnerStatus.canBeRevealed = false; // Reset calculated status

        emit RevealConditionUpdated(tokenId, newCondition, timelockEndTime);
    }


    // --- Marketplace (NFTs) ---

    /// @notice Lists an owned encrypted NFT for sale.
    /// @param tokenId The token identifier.
    /// @param price The sale price in native currency (e.g., ETH).
    function listEncryptedNFT(uint256 tokenId, uint256 price) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        require(price > 0, "Price must be greater than 0");
        require(!_nftListings[tokenId].active, "Token already listed");
        require(!_keyListings[tokenId].active, "Token key is listed separately"); // Prevent listing NFT if key is listed

        // Ensure contract is approved to transfer the token
        require(getApproved(tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to transfer token");

        _nftListings[tokenId] = NFTListing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /// @notice Buys a listed encrypted NFT.
    /// @param tokenId The token identifier.
    function buyEncryptedNFT(uint256 tokenId) external payable nonReentrant whenNotPaused {
        NFTListing storage listing = _nftListings[tokenId];
        require(listing.active, "Token not listed or listing inactive");
        require(msg.sender != listing.seller, "Cannot buy your own token");
        require(msg.value >= listing.price, "Insufficient payment");

        uint256 totalPrice = listing.price;
        address seller = listing.seller;

        // Calculate fees
        uint256 marketplaceFee = totalPrice.mul(_marketplaceFeeNumerator).div(FEE_DENOMINATOR);
        _collectedFees = _collectedFees.add(marketplaceFee);

        // Calculate royalties (ERC2981 for primary sale, custom for secondary)
        uint256 royaltyAmount = 0;
        address royaltyRecipient = address(0);
        uint256 sellerProceeds = totalPrice.sub(marketplaceFee);

        // Check if this is a secondary sale (seller is not the original minter)
        // Note: This assumes the _setupRoyalties in ERC2981 is used during minting for primary sale
        // and we handle secondary sale royalties here.
        (royaltyRecipient, royaltyAmount) = royaltyInfo(tokenId, totalPrice);

        if (royaltyAmount > 0) {
             // If ERC2981 specified a single recipient, deduct it
            sellerProceeds = sellerProceeds.sub(royaltyAmount);
            // Transfer royalty to the single recipient (handled below)
        } else {
            // Check for custom secondary royalty splits
            address[] memory recipients = _customRoyaltyRecipients[tokenId];
            uint256 totalSplitAmount = 0;
            for (uint i = 0; i < recipients.length; i++) {
                address recipient = recipients[i];
                uint96 percentage = _customRoyaltySplits[tokenId][recipient];
                if (percentage > 0) {
                    uint256 splitAmount = totalPrice.mul(percentage).div(FEE_DENOMINATOR);
                    payable(recipient).transfer(splitAmount); // Transfer each split immediately
                    totalSplitAmount = totalSplitAmount.add(splitAmount);
                }
            }
            sellerProceeds = sellerProceeds.sub(totalSplitAmount);
        }


        // Transfer funds: seller receives proceeds, single ERC2981 royalty recipient receives royalty (if any)
        payable(seller).transfer(sellerProceeds);
        if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
             payable(royaltyRecipient).transfer(royaltyAmount);
        }


        // Transfer NFT ownership
        _safeTransfer(seller, msg.sender, tokenId, ""); // Assuming ERC721 implemented _safeTransfer

        // Deactivate listing
        listing.active = false;

        // If the reveal condition is 'Purchase', automatically initiate the reveal request for the new owner
        RevealStatus storage currentOwnerStatus = _revealRequests[tokenId][msg.sender]; // Get status for the new owner
        RevealCondition condition = _revealRequests[tokenId][seller].condition; // Get condition set by previous owner
        currentOwnerStatus.condition = condition; // Apply the inherited condition
        currentOwnerStatus.timelockEndTime = _revealRequests[tokenId][seller].timelockEndTime; // Inherit timelock if any

        if (condition == RevealCondition.Purchase || condition == RevealCondition.Always) {
             _initiateRevealRequest(tokenId, msg.sender);
        } else {
             // For Timelock/ManualApproval, the new owner needs to call requestMetadataReveal()
             currentOwnerStatus.requested = false; // Reset request status for new owner
             currentOwnerStatus.manualApproved = false;
             currentOwnerStatus.canBeRevealed = false;
             currentOwnerStatus.requester = address(0);
        }


        // Handle potential excess payment refund
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit NFTBought(tokenId, msg.sender, seller, totalPrice);
    }

    /// @notice Cancels an active NFT listing.
    /// @param tokenId The token identifier.
    function cancelListing(uint256 tokenId) external nonReentrant whenNotPaused {
        NFTListing storage listing = _nftListings[tokenId];
        require(listing.active, "Token not listed");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;

        emit ListingCancelled(tokenId);
    }

     /// @notice Updates the price of an active NFT listing.
     /// @param tokenId The token identifier.
     /// @param newPrice The new price for the listing.
     function updateListingPrice(uint256 tokenId, uint256 newPrice) external nonReentrant whenNotPaused {
        NFTListing storage listing = _nftListings[tokenId];
        require(listing.active, "Token not listed");
        require(listing.seller == msg.sender, "Not the seller");
        require(newPrice > 0, "Price must be greater than 0");

        listing.price = newPrice;

        emit ListingPriceUpdated(tokenId, newPrice);
     }


    // --- Marketplace (Keys/Decryption Rights) ---

    /// @notice Lists the decryption right (key) for a token for sale separately.
    /// Requires the seller to be the current owner of the NFT.
    /// @param tokenId The token identifier.
    /// @param price The price of the decryption right in native currency.
    function listKey(uint256 tokenId, uint256 price) external nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only token owner can list key");
        require(price > 0, "Price must be greater than 0");
        require(!_keyListings[tokenId].active, "Key already listed");
        require(!_nftListings[tokenId].active, "Token NFT is listed for sale"); // Prevent listing key if NFT is listed

        _keyListings[tokenId] = KeyListing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit KeyListed(tokenId, msg.sender, price);
    }

    /// @notice Buys the listed decryption right (key) for a token.
    /// Does *not* transfer NFT ownership. Grants the buyer access to the key.
    /// @param tokenId The token identifier.
    function buyKey(uint256 tokenId) external payable nonReentrant whenNotPaused {
        KeyListing storage listing = _keyListings[tokenId];
        require(listing.active, "Key not listed or listing inactive");
        require(msg.sender != listing.seller, "Cannot buy key from yourself"); // Prevents buying from owner if owner lists key
        require(msg.value >= listing.price, "Insufficient payment");
        // Ensure the buyer is NOT the current owner (unless you want owners to "re-buy" rights)
        // require(ownerOf(tokenId) != msg.sender, "Owner already has implicit access"); // Optional: uncomment if owner shouldn't buy key listing

        uint256 totalPrice = listing.price;
        address seller = listing.seller; // Seller of the key, usually the NFT owner

        // Calculate fees
        uint256 marketplaceFee = totalPrice.mul(_marketplaceFeeNumerator).div(FEE_DENOMINATOR);
        _collectedFees = _collectedFees.add(marketplaceFee);

        // Calculate custom secondary royalties for the key sale
        address[] memory recipients = _customRoyaltyRecipients[tokenId];
        uint256 totalSplitAmount = 0;
        for (uint i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint96 percentage = _customRoyaltySplits[tokenId][recipient];
            if (percentage > 0) {
                uint256 splitAmount = totalPrice.mul(percentage).div(FEE_DENOMINATOR);
                payable(recipient).transfer(splitAmount); // Transfer each split immediately
                totalSplitAmount = totalSplitAmount.add(splitAmount);
            }
        }

        uint256 sellerProceeds = totalPrice.sub(marketplaceFee).sub(totalSplitAmount);

        // Transfer funds to the seller of the key
        payable(seller).transfer(sellerProceeds);

        // Deactivate key listing
        listing.active = false;

        // Initiate reveal request for the buyer
        _initiateRevealRequest(tokenId, msg.sender);

        // Handle potential excess payment refund
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value.sub(totalPrice));
        }

        emit KeyBought(tokenId, msg.sender, seller, totalPrice);
    }

    /// @notice Cancels an active key listing.
    /// @param tokenId The token identifier.
    function cancelKeyListing(uint256 tokenId) external nonReentrant whenNotPaused {
        KeyListing storage listing = _keyListings[tokenId];
        require(listing.active, "Key not listed");
        require(listing.seller == msg.sender, "Not the seller of the key");

        listing.active = false;

        emit KeyListingCancelled(tokenId);
    }

    /// @notice Updates the price of an active key listing.
     /// @param tokenId The token identifier.
     /// @param newPrice The new price for the key listing.
     function updateKeyListingPrice(uint256 tokenId, uint256 newPrice) external nonReentrant whenNotPaused {
        KeyListing storage listing = _keyListings[tokenId];
        require(listing.active, "Key not listed");
        require(listing.seller == msg.sender, "Not the seller of the key");
        require(newPrice > 0, "Price must be greater than 0");

        listing.price = newPrice;

        emit KeyListingPriceUpdated(tokenId, newPrice);
     }

    // --- Metadata Reveal Flow ---

    /// @notice Initiates a request to reveal the metadata decryption key for a token.
    /// Callable by the token owner or an approved delegate.
    /// @param tokenId The token identifier.
    function requestMetadataReveal(uint256 tokenId) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || _delegateRevealRights[tokenId][msg.sender], "Not owner or delegate");

        _initiateRevealRequest(tokenId, msg.sender);

        emit MetadataRevealRequested(tokenId, msg.sender, _revealRequests[tokenId][owner].condition); // Emit condition set by owner
    }

    /// @notice Internal function to handle the reveal request initiation logic.
    /// @param tokenId The token identifier.
    /// @param requester The address initiating the request.
    function _initiateRevealRequest(uint256 tokenId, address requester) internal {
        // Get the condition set by the current owner
        RevealCondition condition = _revealRequests[tokenId][ownerOf(tokenId)].condition;
        uint64 timelockEndTime = _revealRequests[tokenId][ownerOf(tokenId)].timelockEndTime;

        // Set the request status for the specific requester
        RevealStatus storage requestStatus = _revealRequests[tokenId][requester];
        requestStatus.requester = requester;
        requestStatus.requested = true;
        requestStatus.condition = condition; // Record the condition under which it was requested/granted
        requestStatus.timelockEndTime = timelockEndTime;
        requestStatus.manualApproved = (condition != RevealCondition.ManualApproval); // Auto-approve if not manual
        requestStatus.canBeRevealed = _checkCanBeRevealed(requestStatus);

        // If condition is Purchase or Always, it's automatically approved and ready
         if (condition == RevealCondition.Purchase || condition == RevealCondition.Always) {
             emit MetadataRevealApproved(tokenId, requester, condition);
         }
    }


    /// @notice Approves a pending metadata reveal request. Only callable by the token owner
    /// and only if the reveal condition is ManualApproval.
    /// @param tokenId The token identifier.
    /// @param requester The address whose request is being approved.
    function approveMetadataReveal(uint256 tokenId, address requester) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only token owner can approve");

        RevealStatus storage requestStatus = _revealRequests[tokenId][requester];
        require(requestStatus.requested, "No reveal request from this address");
        require(requestStatus.condition == RevealCondition.ManualApproval, "Reveal condition is not ManualApproval");
        require(!requestStatus.manualApproved, "Request already manually approved");

        requestStatus.manualApproved = true;
        requestStatus.canBeRevealed = _checkCanBeRevealed(requestStatus);

        emit MetadataRevealApproved(tokenId, requester, requestStatus.condition);
    }

    /// @notice Grants an address the right to request metadata reveal on behalf of the owner.
    /// @param tokenId The token identifier.
    /// @param delegate The address to grant delegation rights to.
    function grantDelegateReveal(uint256 tokenId, address delegate) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only token owner can grant delegation");
        require(delegate != address(0), "Delegate cannot be zero address");
        require(delegate != owner, "Cannot delegate to self");

        _delegateRevealRights[tokenId][delegate] = true;

        emit DelegateRevealGranted(tokenId, owner, delegate);
    }

    /// @notice Revokes a delegated reveal right.
    /// @param tokenId The token identifier.
    /// @param delegate The address to revoke delegation rights from.
    function revokeDelegateReveal(uint256 tokenId, address delegate) external nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "Only token owner can revoke delegation");
        require(delegate != address(0), "Delegate cannot be zero address");
        require(delegate != owner, "Cannot revoke self");
        require(_delegateRevealRights[tokenId][delegate], "Delegate right not granted");

        delete _delegateRevealRights[tokenId][delegate];

        emit DelegateRevealRevoked(tokenId, owner, delegate);
    }

    /// @notice Allows the contract owner (admin) to reveal the key to a specific recipient in emergency situations.
    /// This bypasses standard reveal conditions. Use with caution.
    /// @param tokenId The token identifier.
    /// @param recipient The address to reveal the key to.
    function emergencyRevealKey(uint256 tokenId, address recipient) external onlyOwner nonReentrant whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(recipient != address(0), "Recipient cannot be zero address");

        // Simulate setting a condition that allows immediate reveal for this recipient
        RevealStatus storage adminOverrideStatus = _revealRequests[tokenId][recipient];
        adminOverrideStatus.requester = recipient;
        adminOverrideStatus.requested = true;
        adminOverrideStatus.condition = RevealCondition.Always; // Force Always condition
        adminOverrideStatus.timelockEndTime = 0;
        adminOverrideStatus.manualApproved = true;
        adminOverrideStatus.canBeRevealed = true; // Force true

        emit EmergencyKeyRevealed(tokenId, msg.sender, recipient);
    }


    // --- Fees & Royalties ---

    /// @notice Sets the marketplace fee percentage.
    /// @param feeNumerator The numerator for the fee percentage (out of FEE_DENOMINATOR).
    function setMarketplaceFee(uint96 feeNumerator) external onlyOwner {
        require(feeNumerator <= FEE_DENOMINATOR, "Fee cannot exceed 100%");
        _marketplaceFeeNumerator = feeNumerator;
        emit MarketplaceFeeUpdated(feeNumerator);
    }

    /// @notice Sets the address where marketplace fees are sent.
    /// @param recipient The address to send fees to.
    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Fee recipient cannot be zero address");
        _feeRecipient = recipient;
        emit FeeRecipientUpdated(recipient);
    }

    /// @notice Allows the fee recipient to withdraw collected fees.
    function withdrawFees() external nonReentrant {
        require(msg.sender == _feeRecipient, "Only fee recipient can withdraw");
        uint256 amount = _collectedFees;
        require(amount > 0, "No fees collected");

        _collectedFees = 0;
        payable(_feeRecipient).transfer(amount);

        emit FeesWithdrawn(_feeRecipient, amount);
    }

    /// @notice Sets a default royalty percentage for new mints if not specified per token.
    /// @param royaltyNumerator The numerator for the default royalty percentage (out of FEE_DENOMINATOR).
    function setDefaultRoyalty(uint96 royaltyNumerator) external onlyOwner {
        require(royaltyNumerator <= FEE_DENOMINATOR, "Royalty cannot exceed 100%");
         _defaultRoyaltyNumerator = royaltyNumerator;
         // The recipient is set by _defaultRoyaltyRecipient, can add a separate function for that if needed
    }

    /// @notice Sets the default royalty recipient for new mints.
    /// @param recipient The address to receive default royalties.
    function setDefaultRoyaltyRecipient(address recipient) external onlyOwner {
        _defaultRoyaltyRecipient = recipient;
    }

    // ERC2981's _setPrimarySaleRecipient and _setDefaultRoyalty are internal helpers used in mintEncryptedNFT
    // setPrimarySaleRoyalty from ERC2981 is public and can be used directly:
    // function setPrimarySaleRoyalty(uint256 tokenId, address recipient, uint96 royaltyNumerator) public override { ... }

    /// @notice Adds a recipient and their percentage share for custom secondary sale royalty splits for a token.
    /// Can only be set by the original minter or owner.
    /// @param tokenId The token identifier.
    /// @param recipient The address to receive a share.
    /// @param percentageBasisPoints The percentage share out of 10000.
    function addRoyaltyRecipient(uint256 tokenId, address recipient, uint96 percentageBasisPoints) external nonReentrant whenNotPaused {
        address originalMinter = ownerOf(tokenId); // Assuming owner at time of setting controls this
        require(msg.sender == originalMinter, "Only original minter/owner can set custom splits"); // Or owner at time of call? Let's use owner.
        require(recipient != address(0), "Recipient cannot be zero address");
        require(percentageBasisPoints > 0 && percentageBasisPoints <= FEE_DENOMINATOR, "Invalid percentage");

        // Check if recipient already exists to prevent duplicates in the list
        bool recipientExists = false;
        for(uint i = 0; i < _customRoyaltyRecipients[tokenId].length; i++) {
            if (_customRoyaltyRecipients[tokenId][i] == recipient) {
                recipientExists = true;
                break;
            }
        }

        if (!recipientExists) {
             _customRoyaltyRecipients[tokenId].push(recipient);
        }
        _customRoyaltySplits[tokenId][recipient] = percentageBasisPoints;

        // Optional: Add logic to ensure total percentages don't exceed 10000

        emit CustomRoyaltyRecipientAdded(tokenId, recipient, percentageBasisPoints);
    }

    /// @notice Removes a custom royalty recipient for a token.
    /// Can only be called by the original minter or owner.
    /// @param tokenId The token identifier.
    /// @param recipient The address to remove.
    function removeRoyaltyRecipient(uint256 tokenId, address recipient) external nonReentrant whenNotPaused {
        address originalMinter = ownerOf(tokenId); // Assuming owner at time of setting controls this
        require(msg.sender == originalMinter, "Only original minter/owner can manage custom splits"); // Or owner at time of call? Let's use owner.
        require(recipient != address(0), "Recipient cannot be zero address");
        require(_customRoyaltySplits[tokenId][recipient] > 0, "Recipient not found for token");

        delete _customRoyaltySplits[tokenId][recipient];

        // Remove recipient from the dynamic array (less efficient but necessary for iteration)
        address[] storage recipients = _customRoyaltyRecipients[tokenId];
        for (uint i = 0; i < recipients.length; i++) {
            if (recipients[i] == recipient) {
                // Shift elements left
                for (uint j = i; j < recipients.length - 1; j++) {
                    recipients[j] = recipients[j+1];
                }
                recipients.pop(); // Remove last element
                break;
            }
        }

        emit CustomRoyaltyRecipientRemoved(tokenId, recipient);
    }


    // --- Admin & Security ---

    /// @notice Pauses the contract. Only owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract. Only owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    // Override transferOwnership to ensure Pausable state is considered (already handled by Ownable/Pausable interaction)
    // function transferOwnership(address newOwner) public override onlyOwner {
    //     super.transferOwnership(newOwner);
    // }


    // --- View Functions ---

    /// @notice Internal helper to check if reveal conditions are met.
    function _checkCanBeRevealed(RevealStatus storage requestStatus) internal view returns (bool) {
        if (!requestStatus.requested) return false;

        if (requestStatus.condition == RevealCondition.Purchase || requestStatus.condition == RevealCondition.Always) {
            return true; // Always or automatically granted on purchase/request
        } else if (requestStatus.condition == RevealCondition.Timelock) {
            return requestStatus.timelockEndTime > 0 && block.timestamp >= requestStatus.timelockEndTime;
        } else if (requestStatus.condition == RevealCondition.ManualApproval) {
            return requestStatus.manualApproved;
        }
        return false; // Should not happen
    }

    /// @notice Returns the encrypted metadata for a token. Publicly viewable (it's encrypted).
    /// @param tokenId The token identifier.
    /// @return The encrypted metadata bytes.
    function getEncryptedMetadata(uint256 tokenId) external view returns (bytes memory) {
        require(_exists(tokenId), "Token does not exist");
        return _encryptedTokenData[tokenId].encryptedMetadata;
    }

    /// @notice Returns the encrypted decryption key for a token, but ONLY if the requester
    /// has been approved via the reveal flow based on the token's reveal condition.
    /// @param tokenId The token identifier.
    /// @return The encrypted key bytes.
    function getDecryptionKey(uint256 tokenId) external view returns (bytes memory) {
        require(_exists(tokenId), "Token does not exist");

        RevealStatus storage requestStatus = _revealRequests[tokenId][msg.sender];

        // Re-calculate canBeRevealed based on current state (especially for Timelock/ManualApproval)
        bool canReveal = _checkCanBeRevealed(requestStatus);

        require(canReveal, "Reveal condition not met for msg.sender");

        return _encryptedTokenData[tokenId].encryptedKey;
    }

    /// @notice Returns the active NFT listing details for a token.
    /// @param tokenId The token identifier.
    /// @return active Whether the listing is active.
    /// @return seller The seller's address.
    /// @return price The listing price.
    function getListing(uint256 tokenId) external view returns (bool active, address seller, uint256 price) {
        NFTListing storage listing = _nftListings[tokenId];
        return (listing.active, listing.seller, listing.price);
    }

    /// @notice Returns the active key listing details for a token.
    /// @param tokenId The token identifier.
    /// @return active Whether the listing is active.
    /// @return seller The key seller's address.
    /// @return price The key listing price.
    function getKeyListing(uint256 tokenId) external view returns (bool active, address seller, uint256 price) {
        KeyListing storage listing = _keyListings[tokenId];
        return (listing.active, listing.seller, listing.price);
    }

    /// @notice Returns the reveal request status for a specific token and requester.
    /// @param tokenId The token identifier.
    /// @param requester The address that requested the reveal.
    /// @return condition The reveal condition applicable to this request.
    /// @return timelockEndTime The timelock end time (if applicable).
    /// @return manualApproved Whether manual approval was granted.
    /// @return requested Whether a request was initiated.
    /// @return canBeRevealed Calculated status: whether the key can be retrieved by this requester.
    function getRevealRequest(uint256 tokenId, address requester) external view returns (RevealCondition condition, uint64 timelockEndTime, bool manualApproved, bool requested, bool canBeRevealed) {
         require(_exists(tokenId), "Token does not exist");
         RevealStatus storage requestStatus = _revealRequests[tokenId][requester];
         bool _canBeRevealed = _checkCanBeRevealed(requestStatus); // Recalculate
         return (requestStatus.condition, requestStatus.timelockEndTime, requestStatus.manualApproved, requestStatus.requested, _canBeRevealed);
    }

    /// @notice Returns the reveal condition set for a token by its current owner.
    /// @param tokenId The token identifier.
    /// @return condition The current reveal condition.
    /// @return timelockEndTime The timelock end time (if applicable).
    function getRevealCondition(uint256 tokenId) external view returns (RevealCondition condition, uint64 timelockEndTime) {
         require(_exists(tokenId), "Token does not exist");
         address owner = ownerOf(tokenId);
         RevealStatus storage ownerStatus = _revealRequests[tokenId][owner];
         return (ownerStatus.condition, ownerStatus.timelockEndTime);
    }

    /// @notice Returns the list of addresses delegated reveal rights for a token.
    /// Note: This requires iterating through a sparse mapping; returning the full list might be gas intensive for large numbers of delegates.
    /// A more gas-efficient approach might be to check delegation status for a *single* address via `isDelegateReveal`.
    /// For simplicity here, we don't return a list, but provide `isDelegateReveal`.
     /// @param tokenId The token identifier.
     /// @param delegate The address to check.
     /// @return bool True if the address has delegated reveal rights.
    function isDelegateReveal(uint256 tokenId, address delegate) external view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _delegateRevealRights[tokenId][delegate];
    }

    /// @notice Returns the custom royalty split recipients for a token.
    /// @param tokenId The token identifier.
    /// @return An array of recipient addresses.
    function getCustomRoyaltyRecipients(uint256 tokenId) external view returns (address[] memory) {
        return _customRoyaltyRecipients[tokenId];
    }

    /// @notice Returns the custom royalty percentage for a specific recipient and token.
    /// @param tokenId The token identifier.
    /// @param recipient The address to check.
    /// @return uint96 The percentage share out of 10000.
    function getCustomRoyaltyPercentage(uint256 tokenId, address recipient) external view returns (uint96) {
        return _customRoyaltySplits[tokenId][recipient];
    }

    /// @notice Returns the amount of collected fees available for withdrawal.
    /// @return uint256 The collected fee amount.
    function getCollectedFees() external view returns (uint256) {
        return _collectedFees;
    }

    /// @notice Returns the current marketplace fee numerator.
    /// @return uint96 The fee numerator.
    function getMarketplaceFeeNumerator() external view returns (uint96) {
        return _marketplaceFeeNumerator;
    }

    /// @notice Returns the fee recipient address.
    /// @return address The fee recipient.
    function getFeeRecipient() external view returns (address) {
        return _feeRecipient;
    }

    /// @notice Handles ERC721 token transfers to the contract. Important if contract needs to receive NFTs.
    /// @dev This function is called when a contract receives an ERC721 token.
    /// @param operator The address which called safeTransferFrom function.
    /// @param from The address which previously owned the token.
    /// @param tokenId The NFT identifier which is being transferred.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if transfer is successful.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
         // This marketplace is designed for tokens minted *by* itself.
         // Receiving random NFTs is not part of the core logic.
         // Decide whether to accept or reject arbitrary ERC721 transfers.
         // Rejecting is safer if the contract only manages its own NFTs.
         // return this.onERC721Received.selector; // Accept
         revert("ERC721 tokens not minted by this contract cannot be received"); // Reject
    }

    // Override ERC721 standard transfer functions if needed to add specific logic,
    // but usually relying on the inherited _safeTransfer and _update/burn hooks is sufficient.
    // e.g. function transferFrom(address from, address to, uint256 tokenId) public override { ... }
    // The buy flow uses _safeTransfer internally, which is okay.
    // Direct external transferFrom/safeTransferFrom calls could transfer the NFT without affecting listings/reveals.
    // This is standard ERC721 behavior and expected - the key/reveal status stays with the contract's records for that tokenId.

}
```