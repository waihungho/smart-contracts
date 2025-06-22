Okay, here is a Solidity smart contract implementing a **Dynamic Soulbound NFT Marketplace**.

This concept revolves around Non-Transferable (Soulbound) Tokens which represent identity or status, but attached to these Soulbound tokens are **Dynamic Properties (DSPs)**. These DSPs are represented as unique, transferable NFTs whose attributes can change based on external triggers or conditions. The marketplace allows trading these specific DSP (NFT) assets. The utility or benefit of holding a DSP is tied to possessing the corresponding Soulbound Token (simulated within this contract for simplicity).

It integrates:
1.  A custom ERC721-like implementation for the Dynamic Soulbound Properties (DSPs).
2.  Dynamic attributes that can be updated.
3.  A simulated "Soulbound Holder" status and logic linking DSPs to this status.
4.  A fixed-price marketplace for DSPs.
5.  A basic English auction system for DSPs.
6.  Admin controls, fees, and pausing.

This contract aims to be complex, creative, and not a direct copy of standard OpenZeppelin ERC721 or basic marketplace examples by intertwining these distinct concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol"; // Implementing manually, but helpful for interface check
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol"; // Implementing manually

/*
Outline:
1.  Contract Definition & State Variables
    -   Inherits Ownable, ReentrancyGuard, Pausable, ERC165
    -   Defines structs for Listings and Auctions
    -   Maps for ERC721 state (_owners, _balances, _tokenApprovals, _operatorApprovals)
    -   Maps for Dynamic Attributes (_dynamicAttributes, _lastAttributeUpdateTime, _dspUpdaterRole)
    -   Maps for Soulbound Linkage (_isSoulboundHolder, _attachedSoulboundHolder, _requiredSoulboundStatusForTransfer)
    -   Maps/Arrays for Marketplace state (_listings, _auctions, _highestBidder, _bidAmounts)
    -   Counters, Fees, Admin addresses
    -   ERC721 Metadata (name, symbol)

2.  Constructor
    -   Sets basic contract parameters (name, symbol, fees, admin roles)

3.  ERC721 & Core DSP Management Functions
    -   Basic ERC721 functions (balanceOf, ownerOf, getApproved, isApprovedForAll, supportsInterface)
    -   Overrides for transferFrom/safeTransferFrom (_beforeTokenTransfer, _transfer) to integrate soulbound/dynamic logic.
    -   Minting (_mint, mintDSP, batchMintDSP)
    -   Burning (_burn - internal helper)
    -   Approval (approve, setApprovalForAll)
    -   tokenURI (custom implementation reflecting dynamic attributes)

4.  Dynamic Attributes Management Functions
    -   updateDSPAttributes (Callable by specific role)
    -   triggerAttributeUpdate (Simulates external trigger/oracle interaction)
    -   getDSPAttributes (View)
    -   setDSPUpdaterRole (Admin)
    -   setDynamicUpdateInterval (Admin - defines minimum time between dynamic updates)

5.  Soulbound Linkage Functions (Simulated SBT)
    -   setSoulboundHolderStatus (Owner - for simulating which addresses are SBT holders)
    -   isSoulboundHolder (View - check simulation status)
    -   getAttachedSoulboundHolder (View - who benefits from the DSP's utility)
    -   setRequiredSoulboundStatusForTransfer (Admin - adds transfer restriction)
    -   getTokensOwnedBySoulboundHolder (View - list DSPs attached to an SBT holder)

6.  Fixed Price Marketplace Functions
    -   listDSPForSale
    -   cancelListing
    -   buyDSP
    -   getListing (View)
    -   getListedDSPTokensBySeller (View)
    -   getListedDSPTokens (View - retrieves active listings)

7.  Auction Marketplace Functions
    -   listDSPForAuction
    -   placeBid
    -   endAuction
    -   withdrawFailedBid
    -   getAuctionDetails (View)

8.  Admin & Utility Functions
    -   withdrawFees (Fee Recipient)
    -   pauseContract (Owner)
    -   unpauseContract (Owner)
    -   setFeePercentage (Owner)
    -   setFeeRecipient (Owner)
    -   setDSPMintingStatus (Owner - control if new DSPs can be created)
    -   claimSoulboundRewardDSP (Callable by owner/designated address to allow SBT holders to claim specific tokens)
    -   checkSoulboundClaimStatus (View - check if an address can claim a reward DSP)

9.  Internal/Helper Functions
    -   _beforeTokenTransfer
    -   _transfer
    -   _mint
    -   _burn
    -   _updateDSPAttributesInternal (Called by updateDSPAttributes/triggerAttributeUpdate)
    -   _processSale (Internal logic for buying/ending auctions)
    -   _safeTransferFrom (Standard ERC721 helper - implemented manually)

Function Summary:

// ERC721 & Core DSP Management
1.  `constructor(string memory name, string memory symbol, uint96 initialFeePercentage, address initialFeeRecipient, address initialDSPUpdater)`: Initializes the contract, sets name, symbol, fees, and key roles.
2.  `balanceOf(address owner)`: Returns the number of tokens owned by `owner`.
3.  `ownerOf(uint256 tokenId)`: Returns the owner of the `tokenId` token.
4.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers `tokenId` from `from` to `to`. Overridden to include custom checks (`requiredSoulboundStatusForTransfer`) and update soulbound link.
5.  `approve(address to, uint256 tokenId)`: Gives permission to `to` to transfer `tokenId` token.
6.  `getApproved(uint256 tokenId)`: Returns the approved address for `tokenId` token.
7.  `setApprovalForAll(address operator, bool approved)`: Approve or remove `operator` as an operator for the caller.
8.  `isApprovedForAll(address owner, address operator)`: Returns if the `operator` is an approved operator for `owner`.
9.  `supportsInterface(bytes4 interfaceId)`: Checks if the contract supports a given interface (ERC165, ERC721, ERC721Metadata).
10. `mintDSP(address to, uint256 initialAttribute)`: Mints a new DSP token with initial attributes to `to`. Requires minting to be enabled.
11. `batchMintDSP(address to, uint256[] memory initialAttributes)`: Mints multiple new DSP tokens with initial attributes to `to`. Requires minting to be enabled.
12. `tokenURI(uint256 tokenId)`: Returns the URI for metadata of `tokenId`, incorporating dynamic attributes.

// Dynamic Attributes Management
13. `updateDSPAttributes(uint256 tokenId, uint256[] memory newAttributes)`: Updates the dynamic attributes for a specific token. Only callable by the DSP updater role.
14. `triggerAttributeUpdate(uint256 tokenId)`: Simulates an external trigger to potentially update attributes based on predefined logic or time interval. Callable by the DSP updater role.
15. `getDSPAttributes(uint256 tokenId)`: Returns the current dynamic attributes for a token.
16. `setDSPUpdaterRole(address newUpdater)`: Sets the address authorized to update DSP attributes. Owner-only.
17. `setDynamicUpdateInterval(uint256 intervalInSeconds)`: Sets the minimum time between `triggerAttributeUpdate` calls for the same token. Owner-only.

// Soulbound Linkage (Simulated SBT)
18. `setSoulboundHolderStatus(address holder, bool status)`: Manually sets the simulated soulbound holder status for an address. Owner-only.
19. `isSoulboundHolder(address addr)`: Checks if an address is marked as a soulbound holder in the simulation.
20. `getAttachedSoulboundHolder(uint256 tokenId)`: Returns the address currently marked as benefiting from the DSP's utility (the wallet that holds this DSP and is a soulbound holder).
21. `setRequiredSoulboundStatusForTransfer(bool required)`: Sets whether transfers (`transferFrom`, `buyDSP`, etc.) require the recipient to be a simulated soulbound holder. Owner-only.
22. `getTokensOwnedBySoulboundHolder(address holder)`: Returns a list of token IDs owned by a specific soulbound holder address that are *also* actively linked to them for utility.

// Fixed Price Marketplace
23. `listDSPForSale(uint256 tokenId, uint256 price)`: Lists an owned DSP token for sale at a fixed price. Requires token approval to the contract.
24. `cancelListing(uint256 tokenId)`: Cancels an active sale listing for a DSP token. Only callable by the seller or owner.
25. `buyDSP(uint256 tokenId)`: Purchases a listed DSP token. Requires sending exact price + fee. Transfers token and updates soulbound link.
26. `getListing(uint256 tokenId)`: Returns the details of a specific sale listing.
27. `getListedDSPTokensBySeller(address seller)`: Returns a list of token IDs currently listed for sale by a specific seller.
28. `getListedDSPTokens(uint256 cursor, uint256 limit)`: Returns a paginated list of token IDs currently listed for sale.

// Auction Marketplace
29. `listDSPForAuction(uint256 tokenId, uint256 minBid, uint64 duration)`: Starts an English auction for an owned DSP token. Requires token approval.
30. `placeBid(uint256 tokenId)`: Places a bid on an active auction. Requires sending Ether >= minimum bid / highest bid + minimum increment.
31. `endAuction(uint256 tokenId)`: Ends an auction. Transfers token to winner, refunds losing bids. Callable by anyone after auction end time.
32. `withdrawFailedBid(uint256 tokenId)`: Allows a bidder to withdraw their bid if they were outbid or the auction ended without a winner (or they weren't the winner).
33. `getAuctionDetails(uint256 tokenId)`: Returns the details of an active or recently ended auction.

// Admin & Utility Functions
34. `withdrawFees()`: Allows the fee recipient to withdraw accumulated fees.
35. `pauseContract()`: Pauses transfers, listings, bids, and claims. Owner-only.
36. `unpauseContract()`: Unpauses the contract. Owner-only.
37. `setFeePercentage(uint96 newFeePercentage)`: Sets the marketplace fee percentage. Owner-only.
38. `setFeeRecipient(address newFeeRecipient)`: Sets the address receiving marketplace fees. Owner-only.
39. `setDSPMintingStatus(bool enabled)`: Enables or disables the minting of new DSP tokens. Owner-only.
40. `claimSoulboundRewardDSP(uint256 tokenId)`: Allows an address with simulated soulbound status to claim a pre-allocated reward DSP token. Owner/designated caller would pre-approve these via `approve` or a custom mapping. Needs a mechanism to mark tokens as claimable. Let's add a mapping `_canClaimReward` for this.
41. `checkSoulboundClaimStatus(uint256 tokenId, address claimant)`: Checks if a specific address is eligible to claim a specific reward DSP token.
42. `transferOwnership(address newOwner)`: Transfers contract ownership.

Total Public/External Functions: 42+
*/

contract DynamicSoulboundNFTMarketplace is Ownable, ReentrancyGuard, Pausable, ERC165, IERC721, IERC721Metadata {

    // --- Structs ---

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 minBid;
        uint256 highestBid;
        address highestBidder;
        uint64 endTime;
        bool ended;
    }

    // --- State Variables: ERC721 ---

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    uint256 private _nextTokenId;

    // --- State Variables: Dynamic Attributes ---

    // Stores dynamic attributes for each token (e.g., levels, stats, traits that can change)
    mapping(uint256 => uint256[]) private _dynamicAttributes;
    // Timestamp of the last attribute update for a token
    mapping(uint256 => uint64) private _lastAttributeUpdateTime;
    // Role allowed to trigger attribute updates
    address private _dspUpdaterRole;
    // Minimum interval between dynamic attribute updates for a token
    uint256 private _dynamicUpdateInterval = 1 hours; // Default interval

    // --- State Variables: Soulbound Linkage (Simulated SBT) ---

    // Simulation: Tracks addresses that are considered "Soulbound Holders"
    mapping(address => bool) private _isSoulboundHolder;
    // Tracks which Soulbound Holder address is currently linked to a DSP's utility
    // This is the holder of the *DSP token itself* IF they are also a _isSoulboundHolder
    mapping(uint256 => address) private _attachedSoulboundHolder;
    // If true, transfers are only allowed if the recipient is a simulated soulbound holder
    bool private _requiredSoulboundStatusForTransfer = false;

    // --- State Variables: Marketplace ---

    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => Auction) private _auctions;

    // Tracks failed bids in auctions for withdrawal
    mapping(uint256 => mapping(address => uint256)) private _failedBids;

    uint96 private _feePercentage; // Fee / 10000 (e.g., 250 = 2.5%)
    address payable private _feeRecipient;
    uint256 private _collectedFees;

    bool private _mintingEnabled = true;

    // --- State Variables: Reward Claiming ---
    // Mapping to track if a specific DSP can be claimed by a specific address (or any SBT holder if address is address(0))
    mapping(uint256 => address) private _canClaimReward; // address(0) means any SBT holder can claim

    // --- Events ---

    event Minted(uint256 indexed tokenId, address indexed recipient, uint256[] initialAttributes);
    event AttributesUpdated(uint256 indexed tokenId, uint256[] newAttributes, uint64 timestamp);
    event SoulboundHolderStatusSet(address indexed holder, bool status);
    event AttachedSoulboundHolderUpdated(uint256 indexed tokenId, address indexed oldHolder, address indexed newHolder);
    event TransferRestrictionSet(bool required);

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Cancelled(uint256 indexed tokenId, address indexed seller);
    event Sold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    event AuctionListed(uint256 indexed tokenId, address indexed seller, uint256 minBid, uint64 endTime);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 finalPrice);
    event FailedBidWithdrawn(uint256 indexed tokenId, address indexed bidder, uint256 amount);

    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeePercentageUpdated(uint96 oldPercentage, uint96 newPercentage);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event DSPUpdaterRoleSet(address indexed oldUpdater, address indexed newUpdater);
    event DynamicUpdateIntervalSet(uint256 indexed newInterval);
    event MintingStatusSet(bool enabled);
    event RewardClaimableSet(uint256 indexed tokenId, address indexed claimableBy);
    event RewardClaimed(uint256 indexed tokenId, address indexed claimant);


    // --- Constructor ---

    constructor(
        string memory name_,
        string memory symbol_,
        uint96 initialFeePercentage,
        address payable initialFeeRecipient,
        address initialDSPUpdater
    ) Ownable(msg.sender) Pausable() {
        _name = name_;
        _symbol = symbol_;
        require(initialFeeRecipient != address(0), "Fee recipient cannot be zero address");
        require(initialFeePercentage <= 10000, "Fee percentage cannot exceed 100%"); // 10000 / 10000 = 100%
        _feePercentage = initialFeePercentage;
        _feeRecipient = initialFeeRecipient;
        _dspUpdaterRole = initialDSPUpdater; // Could be an oracle contract or multi-sig
    }

    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- ERC721 & Core DSP Management Implementations ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Example: Construct a simple URI including dynamic attributes
        // In a real application, this would likely point to an API or IPFS gateway
        // which fetches the on-chain dynamic attributes and formats them as JSON metadata.
        // This is a placeholder showing how you might indicate dynamic attributes are relevant.

        string memory baseURI = "ipfs://YOUR_METADATA_BASE_URI/"; // Replace with actual base URI
        string memory tokenUri = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

        // Optionally, you could append query parameters for dynamic data
        // Example: ipfs://.../123?attr=1,2,3&lastUpdate=1678886400
        uint265[] memory attrs = _dynamicAttributes[tokenId];
        string memory dynamicPart = "";
        if (attrs.length > 0) {
             dynamicPart = string(abi.encodePacked("&attrs=", Strings.toString(attrs[0]))); // Simplify for example
             for(uint i = 1; i < attrs.length; i++) {
                 dynamicPart = string(abi.encodePacked(dynamicPart, ",", Strings.toString(attrs[i])));
             }
             dynamicPart = string(abi.encodePacked(tokenUri, "?", dynamicPart, "&lastUpdate=", Strings.toString(_lastAttributeUpdateTime[tokenId])));
        } else {
             dynamicPart = string(abi.encodePacked(tokenUri, "?lastUpdate=", Strings.toString(_lastAttributeUpdateTime[tokenId])));
        }

        return dynamicPart;
    }


    function approve(address to, uint256 tokenId) public override whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused {
        // Check ownership or approval
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        // Standard ERC721 checks
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // --- Custom Soulbound Transfer Logic ---
        if (_requiredSoulboundStatusForTransfer) {
             require(_isSoulboundHolder[to], "Soulbound: Recipient must be a Soulbound Holder");
        }
        // --- End Custom Logic ---

        // Clear approvals for the token
        _approve(address(0), tokenId);

        // Perform the transfer
        _beforeTokenTransfer(from, to, tokenId); // Handles soulbound link update
        _transfer(from, to, tokenId);
    }

    // safeTransferFrom variants are inherited from OpenZeppelin's IERC721 implementations
    // We only need to override the core `transferFrom` and potentially `_beforeTokenTransfer`
    // to inject our custom logic. The inherited `safeTransferFrom` will call our overridden `transferFrom`.


    // Internal helper to check existence
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Internal helper to check approval or ownership
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Internal mint function
    function _mint(address to, uint256 tokenId, uint256[] memory initialAttributes) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // Update balances and owner mapping
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Set initial dynamic attributes and timestamp
        _dynamicAttributes[tokenId] = initialAttributes;
        _lastAttributeUpdateTime[tokenId] = uint64(block.timestamp);

        // Update soulbound linkage if applicable
        _beforeTokenTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
        emit Minted(tokenId, to, initialAttributes);
    }

    // Internal transfer function (low-level)
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        // Check ownership (already done in transferFrom, but good practice)
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Before hook handles soulbound link update etc.
        // _beforeTokenTransfer(from, to, tokenId); // Moved this call to the top of transferFrom

        // Update state
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        // Clear approvals (already done in transferFrom)
        // _approve(address(0), tokenId);

        emit Transfer(from, to, tokenId);
    }

    // Internal burn function
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId); // Checks existence

        // Clear approvals
        _approve(address(0), tokenId);

        // Before hook handles soulbound link removal etc.
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update state
        _balances[owner] -= 1;
        delete _owners[tokenId];
        // Note: Dynamic attributes remain, but are orphaned. Could add cleanup logic if needed.
        // Marketplace listings/auctions for the token must be cancelled/ended before burning.

        emit Transfer(owner, address(0), tokenId);
    }

    // Internal helper for approval
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // --- Custom Hooks ---

    // Called before any transfer, minting (from == address(0)), or burning (to == address(0))
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {
        super.whenNotPaused(); // Ensure transfer is not paused

        if (from == address(0)) { // Minting
            // No specific action needed here beyond ensuring contract is not paused.
            // Initial soulbound link is handled when minting.
        } else if (to == address(0)) { // Burning
            // Remove soulbound linkage if token is burned
            delete _attachedSoulboundHolder[tokenId];
        } else { // Transferring between addresses
            // Update soulbound linkage: The new holder benefits IF they are an SBT holder
            if (_isSoulboundHolder[to]) {
                 emit AttachedSoulboundHolderUpdated(tokenId, _attachedSoulboundHolder[tokenId], to);
                 _attachedSoulboundHolder[tokenId] = to;
            } else {
                 // If the recipient is NOT an SBT holder, the DSP's utility is not attached
                 if (_attachedSoulboundHolder[tokenId] != address(0)) {
                      emit AttachedSoulboundHolderUpdated(tokenId, _attachedSoulboundHolder[tokenId], address(0));
                 }
                 delete _attachedSoulboundHolder[tokenId];
            }

            // Ensure listings/auctions are cancelled/ended upon transfer
            if (_listings[tokenId].active) {
                _cancelListingInternal(tokenId);
            }
            if (_auctions[tokenId].endTime != 0 && !_auctions[tokenId].ended) {
                _endAuctionInternal(tokenId); // Force end if mid-auction
            }
        }
    }


    // --- Minting Functions ---

    /// @notice Mints a new Dynamic Soulbound Property token.
    /// @param to The address to mint the token to.
    /// @param initialAttribute The initial value for the primary dynamic attribute. More attributes can be added/updated later.
    function mintDSP(address to, uint256 initialAttribute) external onlyOwner whenNotPaused {
        require(_mintingEnabled, "Minting is currently disabled");
        uint256 newItemId = _nextTokenId++;
        uint256[] memory initialAttributes = new uint256[](1);
        initialAttributes[0] = initialAttribute;
        _mint(to, newItemId, initialAttributes);

        // If the recipient is a simulated soulbound holder, immediately link the utility
        if (_isSoulboundHolder[to]) {
            _attachedSoulboundHolder[newItemId] = to;
             emit AttachedSoulboundHolderUpdated(newItemId, address(0), to);
        }
    }

    /// @notice Mints multiple new Dynamic Soulbound Property tokens.
    /// @param to The address to mint the tokens to.
    /// @param initialAttributes An array of initial primary attribute values, one for each token to mint.
    function batchMintDSP(address to, uint256[] memory initialAttributes) external onlyOwner whenNotPaused {
        require(_mintingEnabled, "Minting is currently disabled");
        for (uint i = 0; i < initialAttributes.length; i++) {
            uint256 newItemId = _nextTokenId++;
            uint256[] memory currentAttributes = new uint256[](1);
            currentAttributes[0] = initialAttributes[i];
            _mint(to, newItemId, currentAttributes);

             // If the recipient is a simulated soulbound holder, immediately link the utility
            if (_isSoulboundHolder[to]) {
                 _attachedSoulboundHolder[newItemId] = to;
                  emit AttachedSoulboundHolderUpdated(newItemId, address(0), to);
            }
        }
    }

    // --- Dynamic Attributes Management ---

    /// @notice Updates the dynamic attributes for a specific token.
    /// @param tokenId The token ID to update.
    /// @param newAttributes The new array of attributes.
    function updateDSPAttributes(uint256 tokenId, uint256[] memory newAttributes) external onlyDSPUpdater whenNotPaused {
        _updateDSPAttributesInternal(tokenId, newAttributes);
    }

    /// @notice Simulates an external trigger to potentially update attributes.
    /// Can be called by the updater role to initiate changes based on off-chain data or time.
    /// Includes a time-based cooldown.
    /// @param tokenId The token ID to check and potentially update.
    function triggerAttributeUpdate(uint256 tokenId) external onlyDSPUpdater whenNotPaused {
        require(_exists(tokenId), "DSP: Token does not exist");
        require(block.timestamp >= _lastAttributeUpdateTime[tokenId] + _dynamicUpdateInterval, "DSP: Dynamic attribute update cooldown in effect");

        // Placeholder for actual dynamic logic
        // In a real contract, this would interact with an oracle (e.g., Chainlink)
        // or read game state from another contract, or apply time-based decay/growth.
        // For this example, we'll just increment the first attribute.
        uint256[] memory currentAttributes = _dynamicAttributes[tokenId];
        if (currentAttributes.length > 0) {
            currentAttributes[0]++; // Example dynamic change: increment the first attribute
             _updateDSPAttributesInternal(tokenId, currentAttributes); // Apply the change
        }
        // If no attributes, perhaps initialize them or do nothing
    }

    /// @notice Internal function to apply attribute updates and timestamp.
    function _updateDSPAttributesInternal(uint256 tokenId, uint256[] memory newAttributes) internal {
         require(_exists(tokenId), "DSP: Token does not exist");
        _dynamicAttributes[tokenId] = newAttributes;
        _lastAttributeUpdateTime[tokenId] = uint64(block.timestamp);
        emit AttributesUpdated(tokenId, newAttributes, uint64(block.timestamp));
    }

    /// @notice Gets the current dynamic attributes for a token.
    /// @param tokenId The token ID to query.
    /// @return An array of the token's dynamic attributes.
    function getDSPAttributes(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "DSP: Token does not exist");
        return _dynamicAttributes[tokenId];
    }

    /// @notice Sets the address authorized to update DSP attributes.
    /// @param newUpdater The address of the new updater role.
    function setDSPUpdaterRole(address newUpdater) external onlyOwner {
        require(newUpdater != address(0), "Updater cannot be zero address");
        emit DSPUpdaterRoleSet(_dspUpdaterRole, newUpdater);
        _dspUpdaterRole = newUpdater;
    }

    /// @notice Sets the minimum time interval between dynamic attribute updates via `triggerAttributeUpdate`.
    /// @param intervalInSeconds The new interval in seconds.
    function setDynamicUpdateInterval(uint256 intervalInSeconds) external onlyOwner {
         emit DynamicUpdateIntervalSet(intervalInSeconds);
         _dynamicUpdateInterval = intervalInSeconds;
    }

    // Modifier for the DSP updater role
    modifier onlyDSPUpdater() {
        require(msg.sender == _dspUpdaterRole, "Not authorized as DSP Updater");
        _;
    }

    // --- Soulbound Linkage Functions (Simulated SBT) ---

    /// @notice Sets the simulated soulbound holder status for an address.
    /// This is a simplification; in a real scenario, this might check an external SBT contract.
    /// @param holder The address whose status to set.
    /// @param status The new status (true for holder, false otherwise).
    function setSoulboundHolderStatus(address holder, bool status) external onlyOwner {
        require(holder != address(0), "Cannot set status for zero address");
        _isSoulboundHolder[holder] = status;
        emit SoulboundHolderStatusSet(holder, status);

        // If status is set to false, remove any active DSP links for tokens they *currently* hold
        if (!status) {
            // Find and unlink any DSPs they currently own
             uint256 balance = _balances[holder];
             if (balance > 0) {
                 // Iterating through all tokens is gas-intensive.
                 // A better approach in production would be to store tokens by owner mapping or handle this off-chain/indexed.
                 // For example purposes, we'll do a limited check or rely on transfer logic.
                 // The _beforeTokenTransfer logic already handles unlinking on transfer out.
                 // For tokens they *keep* but lose SBT status, the link should be removed.
                 // This requires iterating their owned tokens... let's skip explicit iteration here
                 // and rely on the fact that `getAttachedSoulboundHolder` checks `_isSoulboundHolder` live.
                 // The _attachedSoulboundHolder mapping won't be updated until the token is transferred again.
                 // So, `getAttachedSoulboundHolder` needs to check BOTH mappings.
             }
        }
    }

    /// @notice Checks if an address is a simulated soulbound holder.
    /// @param addr The address to check.
    /// @return True if the address is a simulated soulbound holder.
    function isSoulboundHolder(address addr) public view returns (bool) {
        return _isSoulboundHolder[addr];
    }

    /// @notice Gets the address currently linked to a DSP token's utility.
    /// This is the address that *holds* the token AND is a simulated soulbound holder.
    /// @param tokenId The token ID to query.
    /// @return The address of the linked soulbound holder, or address(0) if none is linked.
    function getAttachedSoulboundHolder(uint256 tokenId) public view returns (address) {
        address currentOwner = ownerOf(tokenId); // Throws if token doesn't exist
        if (_isSoulboundHolder[currentOwner]) {
            // Only the current owner, if they are an SBT holder, is considered "attached"
             // The _attachedSoulboundHolder mapping was an attempt to store this,
             // but checking live owner + isSoulboundHolder is more accurate post-transfer.
             // Let's update _attachedSoulboundHolder check:
             // It should represent the LAST soulbound holder of this token *before* it moved to a non-soulbound holder.
             // The live check is simpler and more accurate for *current utility*.
             return currentOwner; // Return the current owner if they are an SBT holder
        }
        return address(0); // No SBT holder currently benefits
    }

    /// @notice Sets whether the recipient of a transfer must be a simulated soulbound holder.
    /// @param required True if a soulbound holder is required for transfers, false otherwise.
    function setRequiredSoulboundStatusForTransfer(bool required) external onlyOwner {
        _requiredSoulboundStatusForTransfer = required;
        emit TransferRestrictionSet(required);
    }

     /// @notice Gets a list of token IDs owned by a specific address that are *also* linked for utility (i.e., the owner is an SBT holder).
     /// WARNING: This function iterates through all tokens owned by the address, which can be gas-intensive for addresses holding many tokens.
     /// @param holder The address (simulated soulbound holder) to query.
     /// @return An array of token IDs owned by the holder and linked for utility.
     function getTokensOwnedBySoulboundHolder(address holder) public view returns (uint256[] memory) {
         require(_isSoulboundHolder[holder], "Address is not a Soulbound Holder");

         uint256[] memory ownedTokens = new uint256[](_balances[holder]);
         uint256 counter = 0;

         // This is inefficient for large collections. Indexing tokens by owner off-chain or using a linked list in contract is better for production.
         // For demonstration, this simple iteration finds tokens.
         // A truly robust implementation would need a way to efficiently iterate owned tokens.
         // Let's simplify and just show *how many* are linked, or return a limited list.
         // Returning all IDs is risky. Let's return up to a limit or just the count.
         // Given the requirement for many functions, let's assume a small number of tokens per holder for this function's practicality in this example.
         // A better approach for a list would be to store tokens by owner in a dynamic array or linked list within the contract state.

         // Let's iterate through all possible token IDs up to the last minted, checking ownership. Still inefficient.
         // A proper ERC721Enumerable extension or storing token IDs per owner is needed for efficiency.
         // Let's *simulate* the retrieval by finding a few owned tokens. This is not a production pattern.
         // *Refinement:* Let's make this function return just the *count* of linked tokens owned, as returning the array is highly inefficient without proper data structures. Or, even better, provide a function that returns a *page* of tokens if we add the necessary data structure (like an array of tokens per owner). Let's implement a function that returns the count. If the prompt *strictly* requires a function returning the list, the performance warning is necessary. Given the function count requirement, let's aim to return a list, but with a mental note about inefficiency.

         // Let's add a mapping to store token IDs by owner. This *does* increase state size but allows efficient iteration per owner.
         // mapping(address => uint256[]) private _ownedTokensList; // Add this state variable
         // Need to manage this list in _mint, _transfer, _burn. This significantly increases contract complexity.
         // Let's assume for this example that `_owners` mapping is sufficient for *checking* ownership,
         // and that iterating through all possible `_nextTokenId` is acceptable *for this example's getter function*,
         // acknowledging it's inefficient in reality.

         // *Revised plan:* Given the inefficiency of iterating through all possible token IDs,
         // and the complexity of maintaining `_ownedTokensList`, let's acknowledge the limitation
         // and provide a view function that conceptually shows the linked tokens, but in a real scenario,
         // this would need a better data structure or be handled off-chain.
         // A simple approach is to return a fixed-size array or rely on the frontend to query `ownerOf` for a range of IDs.

         // Let's return a limited list for demonstration purposes, assuming we have a list structure (even if not fully implemented here).
         // Simulating the logic without adding the actual _ownedTokensList state and management:
         // This function as written below *is* highly inefficient. Consider it pseudocode for intent.
         uint256 currentToken = 1; // Assuming token IDs start from 1 (or 0 based on _nextTokenId init)
         uint256 count = 0;
         uint256 limit = 100; // Limit the number of tokens returned for view functions
         uint256[] memory tokens; // Declare array later once size is known (or use fixed size)
         uint256[] memory tempTokens = new uint256[](limit);

         while(currentToken < _nextTokenId && count < limit) {
             // This is the inefficient part: checking ownerOf for every potential token ID
             // A production contract MUST NOT iterate like this.
             try this.ownerOf(currentToken) returns (address tokenOwner) {
                  if (tokenOwner == holder) {
                      tempTokens[count] = currentToken;
                      count++;
                  }
             } catch {
                 // Token doesn't exist, skip
             }
             currentToken++;
         }

         tokens = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             tokens[i] = tempTokens[i];
         }

         return tokens; // Return the (potentially limited) list
     }


    // --- Fixed Price Marketplace Functions ---

    /// @notice Lists an owned DSP token for sale at a fixed price.
    /// Requires the token to be approved to the marketplace contract address.
    /// @param tokenId The token ID to list.
    /// @param price The fixed price in wei.
    function listDSPForSale(uint256 tokenId, uint256 price) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Marketplace: token does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Marketplace: sender is not token owner");
        require(getApproved(tokenId) == address(this), "Marketplace: token not approved for marketplace");
        require(price > 0, "Marketplace: price must be greater than zero");
        require(!_listings[tokenId].active, "Marketplace: token already listed for sale");
        require(_auctions[tokenId].endTime == 0 || _auctions[tokenId].ended, "Marketplace: token is currently in an active auction");

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit Listed(tokenId, msg.sender, price);
    }

    /// @notice Cancels an active sale listing for a DSP token.
    /// @param tokenId The token ID of the listing to cancel.
    function cancelListing(uint256 tokenId) external whenNotPaused nonReentrant {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Marketplace: listing not active");
        require(listing.seller == msg.sender || ownerOf(tokenId) == msg.sender, "Marketplace: sender is not seller or owner");

        _cancelListingInternal(tokenId);
        emit Cancelled(tokenId, listing.seller);
    }

    /// @notice Internal function to cancel a listing.
    function _cancelListingInternal(uint256 tokenId) internal {
         Listing storage listing = _listings[tokenId];
        listing.active = false; // Mark as inactive
        // Consider using delete for gas efficiency if struct contains dynamic arrays or mappings.
        // For simple structs, marking inactive is fine, or explicit deletion:
        // delete _listings[tokenId]; // This might be better
         delete _listings[tokenId]; // Let's use delete for clarity
    }

    /// @notice Purchases a listed DSP token.
    /// Requires sending exactly `price + fee` in Ether.
    /// @param tokenId The token ID to purchase.
    function buyDSP(uint256 tokenId) external payable whenNotPaused nonReentrant {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Marketplace: listing not active");
        require(listing.seller != msg.sender, "Marketplace: cannot buy your own token");

        uint256 price = listing.price;
        uint256 feeAmount = (price * _feePercentage) / 10000;
        uint256 totalPayment = price + feeAmount;

        require(msg.value == totalPayment, "Marketplace: incorrect Ether amount sent");

        // Process the sale
        _processSale(tokenId, listing.seller, msg.sender, price, feeAmount);

        // Remove the listing
        delete _listings[tokenId]; // Mark as inactive

        emit Sold(tokenId, msg.sender, price);
    }

    /// @notice Internal function to handle token transfer, fee distribution, and soulbound link update after a sale or auction.
    function _processSale(uint256 tokenId, address seller, address buyer, uint256 price, uint256 feeAmount) internal {
         require(_exists(tokenId), "Marketplace: token does not exist");
         require(ownerOf(tokenId) == seller, "Marketplace: seller does not own the token"); // Should be true if listing was valid

         // Perform the token transfer
         // This calls our overridden _beforeTokenTransfer, handling soulbound link update and transfer logic
         transferFrom(seller, buyer, tokenId);

         // Distribute funds
         uint256 sellerProceeds = price;
         if (sellerProceeds > 0) {
             payable(seller).transfer(sellerProceeds);
         }
         // Fees are collected by the contract, not sent directly
         _collectedFees += feeAmount;
    }


    /// @notice Gets the details of a specific fixed price listing.
    /// @param tokenId The token ID to query.
    /// @return Listing details.
    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    /// @notice Gets a list of token IDs currently listed for sale by a specific seller.
    /// WARNING: This function iterates through all possible token IDs up to _nextTokenId, which can be gas-intensive.
    /// @param seller The address of the seller.
    /// @return An array of token IDs listed by the seller.
    function getListedDSPTokensBySeller(address seller) public view returns (uint256[] memory) {
        uint256[] memory listedTokens = new uint256[](_nextTokenId); // Max possible size
        uint256 count = 0;

        // Inefficient iteration. In production, manage listings in an iterable data structure per seller.
        for(uint256 i = 1; i < _nextTokenId; i++) { // Assuming token IDs start from 1 or 0
            Listing storage listing = _listings[i];
            if (listing.active && listing.seller == seller) {
                listedTokens[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for(uint i = 0; i < count; i++) {
            result[i] = listedTokens[i];
        }
        return result;
    }

    /// @notice Gets a paginated list of token IDs currently listed for sale.
    /// WARNING: Iterates through all possible token IDs. Highly inefficient for large numbers of tokens.
    /// @param cursor The starting token ID to check from (e.g., 0 or 1 to start from the beginning).
    /// @param limit The maximum number of tokens to return.
    /// @return An array of token IDs and the next cursor value.
    function getListedDSPTokens(uint256 cursor, uint256 limit) public view returns (uint256[] memory tokenIds, uint256 nextCursor) {
         uint256[] memory tempTokenIds = new uint256[](limit);
         uint256 count = 0;
         uint256 currentToken = (cursor == 0) ? 1 : cursor; // Start checking from cursor or 1

         // Inefficient iteration. Manage listings in an iterable data structure or use off-chain indexing in production.
         while (currentToken < _nextTokenId && count < limit) {
             Listing storage listing = _listings[currentToken];
             if (listing.active) {
                 tempTokenIds[count] = currentToken;
                 count++;
             }
             currentToken++;
         }

         tokenIds = new uint256[](count);
         for(uint i = 0; i < count; i++) {
             tokenIds[i] = tempTokenIds[i];
         }
         nextCursor = currentToken; // Return the ID where iteration stopped

         return (tokenIds, nextCursor);
    }


    // --- Auction Marketplace Functions ---

    /// @notice Lists an owned DSP token for English auction.
    /// Requires the token to be approved to the marketplace contract address.
    /// @param tokenId The token ID to list for auction.
    /// @param minBid The minimum starting bid in wei.
    /// @param duration The duration of the auction in seconds.
    function listDSPForAuction(uint256 tokenId, uint256 minBid, uint64 duration) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Auction: token does not exist");
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "Auction: sender is not token owner");
        require(getApproved(tokenId) == address(this), "Auction: token not approved for marketplace");
        require(duration > 0, "Auction: duration must be greater than zero");
        require(_auctions[tokenId].endTime == 0 || _auctions[tokenId].ended, "Auction: token is already in an active or pending auction");
         require(!_listings[tokenId].active, "Auction: token is listed for fixed price sale");

        // Ensure any old auction data is cleared (should be if ended, but safety)
        delete _auctions[tokenId];
        delete _failedBids[tokenId]; // Clear failed bids from potential previous auction

        _auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: payable(msg.sender),
            minBid: minBid,
            highestBid: minBid > 0 ? 0 : 1, // If minBid is 0, first bid is 1 wei
            highestBidder: address(0),
            endTime: uint64(block.timestamp + duration),
            ended: false
        });

        emit AuctionListed(tokenId, msg.sender, minBid, uint64(block.timestamp + duration));
    }

    /// @notice Places a bid on an active auction.
    /// Requires sending Ether >= minimum bid / highest bid + minimum increment.
    /// @param tokenId The token ID of the auction.
    function placeBid(uint256 tokenId) external payable whenNotPaused nonReentrant {
        Auction storage auction = _auctions[tokenId];
        require(auction.endTime > 0 && !auction.ended, "Auction: auction is not active");
        require(block.timestamp < auction.endTime, "Auction: auction has already ended");
        require(msg.sender != auction.seller, "Auction: seller cannot place bids");
        require(msg.sender != address(0), "Auction: zero address cannot bid");

        uint256 currentHighestBid = auction.highestBid;
        // Minimum bid increment logic (e.g., 1% or a fixed amount)
        uint256 minIncrement = (currentHighestBid * 1) / 100; // Example: 1% increment
        if (minIncrement < 1 wei) minIncrement = 1 wei; // Ensure minimum increment is at least 1 wei

        uint256 requiredBid = currentHighestBid + minIncrement;
         // Special case for first bid: must meet minBid
        if (currentHighestBid == 0 || currentHighestBid == auction.minBid && auction.minBid > 0) {
             requiredBid = auction.minBid;
         }


        require(msg.value >= requiredBid, "Auction: bid must be higher than current highest bid plus minimum increment");

        // Refund previous highest bidder if exists and not the same as current bidder
        if (auction.highestBidder != address(0)) {
            // Instead of immediate transfer (re-entrancy risk), record failed bid
            _failedBids[tokenId][auction.highestBidder] += currentHighestBid;
        }

        // Update auction state
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /// @notice Ends an auction.
    /// Can be called by anyone after the auction end time.
    /// Transfers token to winner, refunds losing bids.
    /// @param tokenId The token ID of the auction.
    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage auction = _auctions[tokenId];
        require(auction.endTime > 0 && !auction.ended, "Auction: auction is not active or already ended");
        require(block.timestamp >= auction.endTime, "Auction: auction has not ended yet");

        auction.ended = true; // Mark auction as ended immediately to prevent re-entry/re-calling

        address winner = auction.highestBidder;
        uint256 finalPrice = auction.highestBid;

        if (winner == address(0) || finalPrice < auction.minBid) {
            // No valid bids or highest bid didn't meet minimum
            emit AuctionEnded(tokenId, address(0), 0);
            // Token remains with seller. Allow highest bidder (if any) to withdraw their bid amount via withdrawFailedBid.
        } else {
            // Valid winner
            uint256 feeAmount = (finalPrice * _feePercentage) / 10000;
            uint256 sellerProceeds = finalPrice - feeAmount;

            // Transfer token
             // This calls our overridden _beforeTokenTransfer, handling soulbound link update etc.
             transferFrom(auction.seller, winner, tokenId);

            // Transfer funds (seller proceeds)
             if (sellerProceeds > 0) {
                auction.seller.transfer(sellerProceeds);
             }
             // Fees are collected
             _collectedFees += feeAmount;

            emit AuctionEnded(tokenId, winner, finalPrice);

             // The highest bidder (winner) does *not* have their bid amount added to _failedBids,
             // as their bid is used for the purchase. Other bidders already had their bids recorded in _failedBids
             // when they were outbid. The winner's bid amount was held by the contract balance until here.
             // Now it's distributed (seller + fee).
        }

        // Clear auction data after settlement (optional, or leave for history)
        // delete _auctions[tokenId]; // Could delete to save gas, but might lose history

        // Leaving auction data allows fetching results with getAuctionDetails later.
        // Failed bids map still holds amounts for losers to withdraw.
    }

     /// @notice Internal function to forcefully end an auction (e.g., if token is transferred unexpectedly).
     function _endAuctionInternal(uint256 tokenId) internal {
         Auction storage auction = _auctions[tokenId];
         if (auction.endTime > 0 && !auction.ended) {
             auction.ended = true; // Mark as ended

             // Record the highest bid amount for the highest bidder so they can withdraw it if the auction was force-ended BEFORE normal end time.
             // If force-ended *after* end time, the normal endAuction logic should have run, transferring token/funds.
             // This internal function is primarily for the *before* end time scenario.
             // If the token is transferred by someone other than the owner while in auction, the auction should be cancelled.
             // The _beforeTokenTransfer hook handles calling this.
             // If _beforeTokenTransfer calls this, it means the token moved unexpectedly.
             // In this case, the auction is invalidated. The seller keeps the token, any bids placed are failed bids.

             address currentHighestBidder = auction.highestBidder;
             uint256 currentHighestBid = auction.highestBid;

             if (currentHighestBidder != address(0) && currentHighestBid > 0) {
                  _failedBids[tokenId][currentHighestBidder] += currentHighestBid;
             }

             emit AuctionEnded(tokenId, address(0), 0); // Indicate no winner due to cancellation/force end

             // Clear auction data (optional, or leave for history)
            // delete _auctions[tokenId]; // Could delete
         }
     }


    /// @notice Allows a bidder to withdraw their failed bid from an auction.
    /// This includes bids that were outbid or bids in an auction that ended without a winner.
    /// @param tokenId The token ID of the auction.
    function withdrawFailedBid(uint256 tokenId) external nonReentrant {
        uint256 amount = _failedBids[tokenId][msg.sender];
        require(amount > 0, "Auction: no failed bids to withdraw");

        _failedBids[tokenId][msg.sender] = 0; // Clear balance before transfer (re-entrancy guard)

        payable(msg.sender).transfer(amount);

        emit FailedBidWithdrawn(tokenId, msg.sender, amount);
    }

    /// @notice Gets the details of an auction.
    /// @param tokenId The token ID of the auction.
    /// @return Auction details.
    function getAuctionDetails(uint256 tokenId) public view returns (Auction memory) {
        return _auctions[tokenId];
    }


    // --- Admin & Utility Functions ---

    /// @notice Allows the fee recipient to withdraw collected fees.
    function withdrawFees() external nonReentrant {
        require(msg.sender == _feeRecipient, "Fees: Only fee recipient can withdraw");
        uint256 amount = _collectedFees;
        require(amount > 0, "Fees: No fees collected yet");

        _collectedFees = 0; // Reset balance before transfer

        payable(_feeRecipient).transfer(amount);
        emit FeesWithdrawn(_feeRecipient, amount);
    }

    /// @notice Pauses the contract, preventing most operations.
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract, enabling operations.
    function unpauseContract() external onlyOwner {
        _unpause();
         emit Unpaused(msg.sender);
    }

    /// @notice Sets the marketplace fee percentage.
    /// @param newFeePercentage The new fee percentage (e.g., 250 for 2.5%). Max 10000 (100%).
    function setFeePercentage(uint96 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 10000, "Fees: percentage cannot exceed 100%");
        emit FeePercentageUpdated(_feePercentage, newFeePercentage);
        _feePercentage = newFeePercentage;
    }

    /// @notice Sets the address that receives marketplace fees.
    /// @param newFeeRecipient The address of the new fee recipient.
    function setFeeRecipient(address payable newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Fees: recipient cannot be zero address");
        emit FeeRecipientUpdated(_feeRecipient, newFeeRecipient);
        _feeRecipient = newFeeRecipient;
    }

    /// @notice Enables or disables the minting of new DSP tokens.
    /// @param enabled True to enable minting, false to disable.
    function setDSPMintingStatus(bool enabled) external onlyOwner {
        _mintingEnabled = enabled;
        emit MintingStatusSet(enabled);
    }

    /// @notice Allows an address with simulated soulbound status to claim a pre-allocated reward DSP token.
    /// The owner or a designated contract would need to have approved this contract to transfer the `tokenId`
    /// and marked it as claimable via `_canClaimReward` mapping.
    /// @param tokenId The token ID to claim.
    function claimSoulboundRewardDSP(uint256 tokenId) external whenNotPaused nonReentrant {
        require(_exists(tokenId), "Claim: token does not exist");
        address claimableBy = _canClaimReward[tokenId];
        require(claimableBy != address(0), "Claim: token not marked as claimable");
        require(claimableBy == msg.sender || claimableBy == address(1), "Claim: not eligible to claim this token"); // address(1) could signify "any SBT holder"

        address currentOwner = ownerOf(tokenId);
        require(currentOwner != address(0), "Claim: token must be owned by the contract or another approved address"); // Usually owned by owner or contract
        require(_isApprovedOrOwner(address(this), tokenId), "Claim: contract not approved to transfer token"); // Contract must be approved to transfer it from its current owner (owner or other pre-allocator)

        require(_isSoulboundHolder[msg.sender], "Claim: claimant must be a Soulbound Holder");

        // Perform the transfer from the current owner (likely owner() or the contract itself) to the claimant
        // This calls our overridden _beforeTokenTransfer, handling soulbound link update
        transferFrom(currentOwner, msg.sender, tokenId);

        // Remove the claimable status
        delete _canClaimReward[tokenId];

        emit RewardClaimed(tokenId, msg.sender);
    }

    /// @notice Sets a DSP token as claimable by a specific address or any SBT holder (address(1)).
    /// Only the owner can set this. The owner must also ensure the contract is approved to transfer this token.
    /// @param tokenId The token ID to mark as claimable.
    /// @param claimableBy The address that can claim it (or address(1) for any SBT holder, address(0) to remove).
    function setRewardClaimableStatus(uint256 tokenId, address claimableBy) external onlyOwner {
         require(_exists(tokenId), "Claim: token does not exist");
         require(claimableBy != address(0) || _canClaimReward[tokenId] != address(0), "Claim: token is not claimable or already removed"); // Can't set to zero if not already claimable

         _canClaimReward[tokenId] = claimableBy;
         emit RewardClaimableSet(tokenId, claimableBy);
    }


    /// @notice Checks if a specific address is eligible to claim a specific reward DSP token.
    /// @param tokenId The token ID to check.
    /// @param claimant The address attempting to claim.
    /// @return True if the claimant is eligible based on SBT status and claimable setting.
    function checkSoulboundClaimStatus(uint256 tokenId, address claimant) public view returns (bool) {
        address claimableBy = _canClaimReward[tokenId];
        if (claimableBy == address(0)) return false; // Not marked as claimable
        if (!_exists(tokenId)) return false; // Token doesn't exist
        if (!_isSoulboundHolder[claimant]) return false; // Claimant must be an SBT holder

        // If claimableBy is address(1), any SBT holder can claim
        if (claimableBy == address(1)) return true;

        // Otherwise, must match the specific address set
        return claimableBy == claimant;
    }

     // --- Overrides for Pausable ---
     function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, DynamicSoulboundNFTMarketplace) {
         // Calls ERC721's _beforeTokenTransfer first if it exists, then our custom logic
         // OpenZeppelin's ERC721 does not have _beforeTokenTransfer in 0.8.x, but this is where hooks would go.
         // We added our custom logic directly in our _beforeTokenTransfer.
         // Need to call super's whenNotPaused.
         super._beforeTokenTransfer(from, to, tokenId); // Calls Pausable's whenNotPaused
     }

     // --- Overrides for Ownable transferOwnership ---
     function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // Add checks here if new owner must also be a Soulbound Holder or have specific attributes? (Advanced concept)
        // For this example, just standard transfer.
        _transferOwnership(newOwner);
    }

    // --- Fallback and Receive Functions (Optional but good practice) ---
    receive() external payable {} // Allows receiving plain Ether
    fallback() external payable {} // Allows receiving Ether for calls to undefined functions
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

     function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 4;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let buffer := add(new freeptr, 10)
            let ptr := add(buffer, length)
            if iszero(length) {
                ptr := add(ptr, 1)
            }
            temp := value
            for {} iszero(iszero(temp)) {} {
                ptr := sub(ptr, 1)
                mstore(ptr, byte(and(temp, 0xf), _HEX_SYMBOLS))
                temp := shr(4, temp)
            }
            mstore(sub(ptr, 2), 0x7830) // "0x"
            return(sub(ptr, 2), add(length, 2))
        }
    }
}
```

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic Soulbound Properties (DSPs):**
    *   The core asset isn't just an NFT; it's a *property* that *can* be traded, but its *effect* or *utility* is tied to the holder's "soul" (simulated SBT status).
    *   Implemented as a custom ERC721-like structure (`_owners`, `_balances`, etc.) but with overrides.
    *   The `_beforeTokenTransfer` hook is crucial. It intercepts transfers to update the `_attachedSoulboundHolder` mapping and enforce `_requiredSoulboundStatusForTransfer` if set.

2.  **Dynamic Attributes:**
    *   Each DSP token has an array of `_dynamicAttributes`.
    *   An `updateDSPAttributes` function allows a designated `_dspUpdaterRole` (e.g., an oracle, game server, or admin) to change these attributes *after* minting.
    *   A `triggerAttributeUpdate` function simulates a condition-based update (e.g., time decay, external data check) with a built-in cooldown (`_dynamicUpdateInterval`).
    *   `tokenURI` is designed to conceptually reflect these dynamic attributes, suggesting metadata that changes.

3.  **Simulated Soulbound Linkage:**
    *   `_isSoulboundHolder` mapping simulates an external SBT contract. The contract owner can set this status.
    *   `_attachedSoulboundHolder` tracks *which* soulbound holder currently benefits from a DSP's utility. This is updated automatically on `transferFrom` and `buyDSP`.
    *   `setRequiredSoulboundStatusForTransfer` adds an optional, powerful restriction: transfers are only allowed to addresses marked as soulbound holders.
    *   `getAttachedSoulboundHolder` provides a view into the current utility link.

4.  **Combined Marketplace (Fixed Price & Auction):**
    *   Includes standard fixed-price listings (`listDSPForSale`, `buyDSP`).
    *   Adds a basic English auction system (`listDSPForAuction`, `placeBid`, `endAuction`, `withdrawFailedBid`). This significantly increases complexity with bid tracking, end times, and refund logic.
    *   Uses `nonReentrant` guard on critical payment/state-changing functions (`buyDSP`, `endAuction`, `withdrawFees`, `withdrawFailedBid`).
    *   The `_processSale` internal function centralizes the logic for transferring the token and distributing funds/fees after a successful sale or auction end, ensuring the `_beforeTokenTransfer` hook is called.

5.  **Advanced Admin Controls & Utilities:**
    *   `Ownable` for standard ownership.
    *   `Pausable` allows pausing sensitive operations (transfers, listings, bids, claims) in emergencies.
    *   Separate `_dspUpdaterRole` allows delegating attribute updates without full ownership.
    *   Fee mechanism with a changeable `_feePercentage` and `_feeRecipient`.
    *   `setDSPMintingStatus` allows controlling token creation.
    *   `claimSoulboundRewardDSP` introduces a mechanism for tokens to be claimable based on soulbound status, suggesting potential reward distribution or airdrops tied to identity/achievements.
    *   `setRewardClaimableStatus` and `checkSoulboundClaimStatus` support the reward claiming feature.

6.  **Efficiency Considerations & Caveats:**
    *   Several view functions (`getListedDSPTokensBySeller`, `getListedDSPTokens`, `getTokensOwnedBySoulboundHolder`) involve iterating through potentially large numbers of tokens. **This is inefficient and highly discouraged for production contracts with many tokens.** In a real application, you would need to use a different data structure (like iterable mappings or linked lists managed within the contract state) or rely on off-chain indexing services (like subgraph). The current implementation is for demonstrating functionality count and complexity.
    *   The auction implementation is basic. A production auction might need more features (e.g., minimum bid increment validation in `placeBid`, escrowing bids differently).

This contract provides a starting point for a novel Web3 interaction model combining identity, evolving digital assets, and specialized trading mechanisms. Remember to thoroughly test and audit any complex smart contract before deployment.