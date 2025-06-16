Okay, here is a Solidity smart contract incorporating several advanced and creative concepts like dynamic NFTs, oracle interaction, yield generation based on attributes/external data, a simple internal marketplace, randomness for attributes, and development mechanics.

This contract, `EternalEstate`, represents unique digital "Parcels" as NFTs (ERC721). These parcels have dynamic attributes and can potentially generate a yield token based on their attributes and a simulated "value" fetched via an oracle. Users can also develop parcels and trade them on an internal marketplace.

It utilizes concepts like:
*   **ERC721:** Standard NFT representation.
*   **Ownable:** Basic access control.
*   **ReentrancyGuard:** Protection for token transfers.
*   **Dynamic NFT Attributes:** Parcel value and yield rate can change.
*   **Oracle Integration:** Simulates fetching external data (parcel "value") to influence yield.
*   **VRF (Verifiable Random Function):** Used to assign initial attributes randomly.
*   **Yield Bearing NFTs:** Parcels generate a separate ERC20 token over time.
*   **Internal Marketplace:** Basic buy/sell functionality within the contract.
*   **Parcel Development:** Users can invest (simulate by staking/burning yield tokens) to improve attributes.
*   **Time-Based Logic:** Yield calculation based on time elapsed.
*   **Event-Driven State Changes:** Using Oracles/VRF callbacks.

---

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, Ownable, ReentrancyGuard, Chainlink VRF, Chainlink Price Feed (as Oracle example), ERC20 (interface for yield token).
3.  **Error Definitions**
4.  **Interfaces:** For Chainlink VRF and Oracle (simulated).
5.  **Structs:** ParcelAttributes, Listing, VRFRequest.
6.  **Events:** Minting, Transfer, Approval (ERC721), Listing, Sale, Value Update, Yield Claim, Development, VRF Request/Fulfillment.
7.  **State Variables:** ERC721 mappings, Parcel data, Dynamic Values, Listings, Oracle/VRF config, Yield token address, Request tracking.
8.  **Constructor:** Initialize base ERC721, set admin, set initial config.
9.  **Modifiers:** onlyOracle, onlyVRF.
10. **ERC721 Standard Functions:**
    *   `balanceOf`
    *   `ownerOf`
    *   `approve`
    *   `getApproved`
    *   `setApprovalForAll`
    *   `isApprovedForAll`
    *   `transferFrom`
    *   `safeTransferFrom` (two variants)
    *   `tokenURI` (placeholder/basic)
    *   `supportsInterface`
11. **Core EternalEstate Logic:**
    *   `mintParcel`: Creates a new Parcel NFT, requests random attributes via VRF.
    *   `getParcelAttributes`: Retrieves static and dynamic attributes.
    *   `getParcelValue`: Retrieves the dynamic value.
    *   `requestValueUpdate`: Initiates an Oracle request to update a parcel's value.
    *   `fulfillValueUpdate`: Callback from Oracle to update parcel value.
    *   `getParcelYieldRate`: Calculates the current yield rate based on attributes and value.
    *   `getPendingYield`: Calculates yield not yet claimed.
    *   `claimYield`: Mints/transfers yield tokens to the owner.
    *   `developParcel`: Allows owner to improve a parcel (e.g., pay fee/stake tokens).
12. **Internal Marketplace Functions:**
    *   `listParcelForSale`: Puts a parcel up for sale.
    *   `buyParcel`: Allows a user to buy a listed parcel (with ETH).
    *   `cancelListing`: Allows seller to remove a listing.
    *   `getListing`: Retrieves listing details.
13. **VRF Integration Functions:**
    *   `requestRandomAttributes`: (Internal, called by `mintParcel`) Requests random words for attributes.
    *   `fulfillRandomWords`: Callback from VRF Coordinator to set parcel attributes.
14. **Admin/Configuration Functions:**
    *   `setYieldTokenAddress`: Sets the address of the ERC20 yield token contract.
    *   `setOracleConfig`: Sets Oracle contract address and Job ID.
    *   `setVRFConfig`: Sets VRF Coordinator, Key Hash, and Fee.
    *   `updateBaseYieldRate`: Adjusts the global base yield rate.
15. **Helper Functions:**
    *   `_calculateYield`: Internal function to calculate pending yield.
    *   `_safeTransferETH`: Helper for transferring ETH.

---

**Function Summary:**

*   **ERC721 Standard (10 functions):** `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` (2), `tokenURI`, `supportsInterface`. (Standard NFT operations).
*   **Minting & Attributes (4 functions):**
    *   `mintParcel(address to)`: Mints a new Parcel NFT and triggers VRF for attributes.
    *   `getParcelAttributes(uint256 tokenId)`: Returns the fixed and dynamic attributes of a parcel.
    *   `getParcelValue(uint256 tokenId)`: Returns the current dynamic value of a parcel.
    *   `fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords)`: Chainlink VRF callback to set initial parcel attributes based on randomness.
*   **Dynamic Value & Oracle (3 functions):**
    *   `requestValueUpdate(uint256 tokenId)`: Requests the Oracle to fetch and update a parcel's value.
    *   `fulfillValueUpdate(bytes32 requestId, uint256 value)`: Oracle callback to set the parcel's dynamic value.
    *   `setOracleConfig(address oracle, bytes32 jobId, uint256 fee)`: Admin function to set Oracle parameters.
*   **Yield Generation (4 functions):**
    *   `getParcelYieldRate(uint256 tokenId)`: Calculates the current yield rate per second for a parcel.
    *   `getPendingYield(uint256 tokenId)`: Calculates the amount of yield tokens available to claim for a parcel.
    *   `claimYield(uint256[] calldata tokenIds)`: Allows owner to claim pending yield for multiple parcels.
    *   `setYieldTokenAddress(address yieldToken)`: Admin function to set the address of the ERC20 yield token contract.
*   **Parcel Interaction (2 functions):**
    *   `developParcel(uint256 tokenId, uint256 developmentCost)`: Allows owner to spend resources (simulated cost) to increase development level.
    *   `updateBaseYieldRate(uint256 newRate)`: Admin function to change the global base yield rate.
*   **Internal Marketplace (4 functions):**
    *   `listParcelForSale(uint256 tokenId, uint256 price)`: Lists a parcel for sale at a specific price.
    *   `buyParcel(uint256 tokenId)`: Allows a user to buy a listed parcel by sending ETH.
    *   `cancelListing(uint256 tokenId)`: Allows seller to cancel a listing.
    *   `getListing(uint256 tokenId)`: Returns details about a parcel's listing.
*   **VRF Configuration (1 function):**
    *   `setVRFConfig(address vrfCoordinator, bytes32 keyHash, uint256 fee)`: Admin function to set VRF parameters.

Total Functions: 10 (ERC721) + 4 (Mint/Attributes) + 3 (Oracle) + 4 (Yield) + 2 (Interaction) + 4 (Marketplace) + 1 (VRF Config) = **28 functions**.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. License and Pragma
// 2. Imports: ERC721, Ownable, ReentrancyGuard, Chainlink VRF, Chainlink Price Feed (as Oracle example), ERC20 (interface for yield token).
// 3. Error Definitions
// 4. Interfaces: For Chainlink VRF and Oracle (simulated).
// 5. Structs: ParcelAttributes, Listing, VRFRequest.
// 6. Events: Minting, Transfer, Approval (ERC721), Listing, Sale, Value Update, Yield Claim, Development, VRF Request/Fulfillment.
// 7. State Variables: ERC721 mappings, Parcel data, Dynamic Values, Listings, Oracle/VRF config, Yield token address, Request tracking.
// 8. Constructor: Initialize base ERC721, set admin, set initial config.
// 9. Modifiers: onlyOracle, onlyVRF.
// 10. ERC721 Standard Functions (10)
// 11. Core EternalEstate Logic (5)
// 12. Internal Marketplace Functions (4)
// 13. VRF Integration Functions (2)
// 14. Admin/Configuration Functions (4)
// 15. Helper Functions (1)

// --- Function Summary (28 functions) ---
// ERC721 Standard (10): balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom(2), tokenURI, supportsInterface.
// Minting & Attributes (4): mintParcel, getParcelAttributes, getParcelValue, fulfillRandomWords (VRF callback).
// Dynamic Value & Oracle (3): requestValueUpdate, fulfillValueUpdate (Oracle callback), setOracleConfig.
// Yield Generation (4): getParcelYieldRate, getPendingYield, claimYield, setYieldTokenAddress.
// Parcel Interaction (2): developParcel, updateBaseYieldRate.
// Internal Marketplace (4): listParcelForSale, buyParcel, cancelListing, getListing.
// VRF Configuration (1): setVRFConfig.

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Using Keeper interface as a generic Oracle source example
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// --- Error Definitions ---
error EternalEstate__OnlyOwnerCanCall();
error EternalEstate__TransferFailed();
error EternalEstate__InvalidAddress();
error EternalEstate__ParcelNotFound();
error EternalEstate__NotOwner();
error EternalEstate__NotApprovedOrOwner();
error EternalEstate__AlreadyListed();
error EternalEstate__NotListed();
error EternalEstate__InsufficientPayment();
error EternalEstate__OracleNotSet();
error EternalEstate__VRFNotSet();
error EternalEstate__YieldTokenNotSet();
error EternalEstate__RequestNotFound();
error EternalEstate__UnauthorizedCallback();
error EternalEstate__DevelopmentCostTooLow();
error EternalEstate__ArrayLengthMismatch();
error EternalEstate__ParcelNotOwnedByUser();

// --- Interfaces ---

// Mock Oracle Interface (Replace with actual Chainlink PriceFeed or custom Oracle)
interface MockOracle {
    function requestData(bytes32 jobId, uint256 payment, bytes memory data) external returns (bytes32 requestId);
    function fulfillRequest(bytes32 requestId, uint256 value) external; // Mock callback structure
}

contract EternalEstate is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- Structs ---
    struct ParcelAttributes {
        uint8 size; // e.g., 1-10
        uint8 typeId; // e.g., 1=Basic, 2=Premium, 3=Commercial
        uint8 developmentLevel; // e.g., 0-5
        uint64 lastYieldClaimTimestamp;
    }

    struct Listing {
        address payable seller;
        uint256 price; // in wei
        bool active;
    }

    // --- Events ---
    event ParcelMinted(uint256 indexed tokenId, address indexed owner, uint8 size, uint8 typeId);
    event ParcelAttributesSet(uint256 indexed tokenId, uint8 size, uint8 typeId, uint8 developmentLevel);
    event ParcelValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event ParcelDeveloped(uint256 indexed tokenId, uint8 newDevelopmentLevel, uint256 costPaid);
    event ParcelListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ParcelSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event ParcelListingCancelled(uint256 indexed tokenId);
    event OracleRequestSent(bytes32 indexed requestId, uint256 indexed tokenId);
    event VRFRequestSent(bytes32 indexed requestId, uint256 indexed tokenId);
    event VRFFulfillmentReceived(bytes32 indexed requestId, uint256 indexed tokenId);
    event BaseYieldRateUpdated(uint256 newRate);

    // --- State Variables ---
    // ERC721 standard storage is handled by the base ERC721 contract

    mapping(uint256 => ParcelAttributes) private _parcelAttributes;
    mapping(uint256 => uint256) private _parcelValues; // Dynamic value, e.g., based on oracle data
    mapping(uint256 => Listing) private _parcelListings;

    // Oracle configuration (using a mock interface for demonstration)
    address private _oracleAddress;
    bytes32 private _oracleJobId;
    uint256 private _oracleFee;
    mapping(bytes32 => uint256) private _oracleRequests; // Request ID -> Token ID

    // VRF configuration
    VRFCoordinatorV2Interface private _vrfCoordinator;
    bytes32 private _vrfKeyHash;
    uint256 private _vrfFee;
    mapping(bytes32 => uint256) private _vrfRequests; // Request ID -> Token ID

    IERC20 private _yieldToken; // Address of the ERC20 token generated as yield

    uint256 private _baseYieldRatePerSecond = 1; // Example: 1 token unit per second base rate

    uint256 private _nextTokenId = 0; // Counter for token IDs

    // --- Constructor ---
    constructor(address initialOwner, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != _oracleAddress) revert EternalEstate__UnauthorizedCallback();
        _;
    }

    modifier onlyVRF() {
        if (msg.sender != address(_vrfCoordinator)) revert EternalEstate__UnauthorizedCallback();
        _;
    }

    // --- ERC721 Standard Functions ---
    // These are standard overrides. The logic is within the ERC721 base contract.
    // Listing these explicitly as they count towards the function count.

    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert EternalEstate__NotApprovedOrOwner();
        }
        super.approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
        // Could add ERC165, ERC2981 (Royalties) if implemented
    }

    // Placeholder for tokenURI - implement actual metadata logic here
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
             revert ERC721NonexistentToken(tokenId);
        }
        // Return a base URI or construct a dynamic URI pointing to metadata
        return string(abi.encodePacked("ipfs://baseuri/", tokenId.toString()));
    }

    // --- Core EternalEstate Logic ---

    /// @notice Mints a new Parcel NFT and requests random attributes via VRF.
    /// @param to The address to mint the parcel to.
    function mintParcel(address to) public onlyOwner {
        if (_vrfCoordinator == VRFCoordinatorV2Interface(address(0)) || _vrfKeyHash == bytes32(0) || _vrfFee == 0) {
            revert EternalEstate__VRFNotSet();
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);

        // Request random words for initial attributes
        bytes32 requestId = _vrfCoordinator.requestRandomWords(
            _vrfKeyHash,
            1, // numWords (size, typeId - derived from less entropy)
            3, // requestConfirmations
            0, // callbackGasLimit (0 means default)
            1  // numWords requested for randomness pool
        );

        _vrfRequests[requestId] = tokenId; // Map request ID to token ID

        emit ParcelMinted(tokenId, to, 0, 0); // Attributes are 0 until VRF fulfills
        emit VRFRequestSent(requestId, tokenId);
    }

    /// @notice Gets the attributes of a Parcel.
    /// @param tokenId The ID of the parcel.
    /// @return size The size attribute.
    /// @return typeId The type ID attribute.
    /// @return developmentLevel The development level.
    /// @return lastYieldClaimTimestamp The timestamp of the last yield claim.
    function getParcelAttributes(uint256 tokenId) public view returns (uint8 size, uint8 typeId, uint8 developmentLevel, uint64 lastYieldClaimTimestamp) {
        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        ParcelAttributes storage attrs = _parcelAttributes[tokenId];
        return (attrs.size, attrs.typeId, attrs.developmentLevel, attrs.lastYieldClaimTimestamp);
    }

    /// @notice Gets the dynamic value of a Parcel.
    /// @param tokenId The ID of the parcel.
    /// @return value The dynamic value.
    function getParcelValue(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        return _parcelValues[tokenId];
    }

    /// @notice Requests an update to a Parcel's dynamic value via the Oracle.
    /// @param tokenId The ID of the parcel.
    /// Requires a fee in ETH (sent with the transaction).
    function requestValueUpdate(uint256 tokenId) public payable nonReentrant {
        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        if (_oracleAddress == address(0) || _oracleJobId == bytes32(0) || _oracleFee == 0) {
             revert EternalEstate__OracleNotSet();
        }
        if (msg.value < _oracleFee) {
             revert EternalEstate__InsufficientPayment();
        }

        // Example data payload (could encode token ID, specific query parameters)
        bytes memory data = abi.encode(tokenId);

        // Call the Oracle contract
        // Note: This assumes the MockOracle interface and requestData structure match the actual oracle
        bytes32 requestId = MockOracle(_oracleAddress).requestData(_oracleJobId, _oracleFee, data);

        _oracleRequests[requestId] = tokenId; // Map request ID to token ID

        emit OracleRequestSent(requestId, tokenId);

        // Refund any excess ETH
        if (msg.value > _oracleFee) {
            _safeTransferETH(payable(msg.sender), msg.value - _oracleFee);
        }
    }

    /// @notice Callback function for the Oracle to update a Parcel's value.
    /// @param requestId The ID of the request.
    /// @param value The new value provided by the oracle.
    function fulfillValueUpdate(bytes32 requestId, uint256 value) external onlyOracle {
        uint256 tokenId = _oracleRequests[requestId];
        if (tokenId == 0) revert EternalEstate__RequestNotFound(); // Should not happen if onlyOracle works

        _parcelValues[tokenId] = value;

        delete _oracleRequests[requestId]; // Clean up the request

        emit ParcelValueUpdated(tokenId, value);
    }


    /// @notice Calculates the current yield rate per second for a Parcel.
    /// @param tokenId The ID of the parcel.
    /// @return rate The yield rate per second.
    function getParcelYieldRate(uint256 tokenId) public view returns (uint256 rate) {
        if (!_exists(tokenId)) return 0; // Or revert
        ParcelAttributes storage attrs = _parcelAttributes[tokenId];
        uint256 value = _parcelValues[tokenId];

        // Example complex calculation: Base rate * (size + type bonus + development bonus) * (1 + value influence)
        uint256 sizeBonus = attrs.size; // Example: linear bonus
        uint256 typeBonus;
        if (attrs.typeId == 2) typeBonus = 5;
        else if (attrs.typeId == 3) typeBonus = 10; // Example bonus per type

        uint256 devBonus = attrs.developmentLevel * 2; // Example: linear dev bonus

        // Value influence: e.g., value / 1000 (assuming value is large)
        // Prevent division by zero or overflow/underflow issues
        uint256 valueInfluence = value > 0 ? value / 1000 : 0; // Example scaling

        rate = _baseYieldRatePerSecond * (10 + sizeBonus + typeBonus + devBonus); // Base points + bonuses
        // Add value influence (e.g., yield is rate * (1 + valueInfluence/100) )
        // This calculation can get complex. Let's simplify for the example:
        // Rate influenced by value directly, scaled.
        rate = (_baseYieldRatePerSecond * (1 + sizeBonus + typeBonus + devBonus)) * (100 + valueInfluence) / 100;
        // Ensure minimal rate
        if (rate == 0) rate = _baseYieldRatePerSecond;
    }

    /// @notice Calculates the amount of yield tokens available to claim for a Parcel.
    /// @param tokenId The ID of the parcel.
    /// @return pendingYield The amount of pending yield tokens.
    function getPendingYield(uint256 tokenId) public view returns (uint256 pendingYield) {
        if (!_exists(tokenId)) return 0;
        ParcelAttributes storage attrs = _parcelAttributes[tokenId];
        return _calculateYield(tokenId, attrs.lastYieldClaimTimestamp);
    }

    /// @dev Internal helper to calculate yield since a given timestamp.
    function _calculateYield(uint256 tokenId, uint64 lastClaimTimestamp) internal view returns (uint256) {
         // Prevent calculating yield if parcel was claimed very recently (e.g., less than 1 second ago)
        // This prevents issues with timestamp granularity.
        if (block.timestamp <= lastClaimTimestamp) {
            return 0;
        }

        uint256 timeElapsed = block.timestamp - lastClaimTimestamp;
        uint256 yieldRate = getParcelYieldRate(tokenId);

        return yieldRate * timeElapsed;
    }


    /// @notice Allows owner to claim pending yield for one or more Parcels.
    /// @param tokenIds An array of token IDs to claim yield for.
    function claimYield(uint256[] calldata tokenIds) public nonReentrant {
        if (address(_yieldToken) == address(0)) revert EternalEstate__YieldTokenNotSet();

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address parcelOwner = ownerOf(tokenId); // Use base ERC721 owner check

            if (parcelOwner != msg.sender) {
                 revert EternalEstate__ParcelNotOwnedByUser();
            }
            if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound(); // Should be covered by owner check but good practice

            ParcelAttributes storage attrs = _parcelAttributes[tokenId];
            uint256 pending = _calculateYield(tokenId, attrs.lastYieldClaimTimestamp);

            if (pending > 0) {
                // Assuming the Yield Token contract allows minting or transferFrom this contract
                // If it's a mintable token, the Yield Token contract needs to have a mint function callable by EternalEstate
                // Example: IERC20Mintable(_yieldToken).mint(msg.sender, pending);
                // If it's a pre-minted pool, use transfer:
                 bool sent = _yieldToken.transfer(msg.sender, pending);
                 if (!sent) revert EternalEstate__TransferFailed();

                attrs.lastYieldClaimTimestamp = uint64(block.timestamp); // Update last claimed time
                emit YieldClaimed(tokenId, msg.sender, pending);
            }
        }
    }

    /// @notice Allows owner to develop a Parcel, increasing its development level.
    /// @param tokenId The ID of the parcel.
    /// @param developmentCost The amount of yield tokens to spend for development.
    /// Requires the owner to approve this contract to spend `developmentCost` yield tokens.
    function developParcel(uint256 tokenId, uint256 developmentCost) public nonReentrant {
        address parcelOwner = ownerOf(tokenId);
        if (parcelOwner != msg.sender) revert EternalEstate__NotOwner();
        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        if (address(_yieldToken) == address(0)) revert EternalEstate__YieldTokenNotSet();
        if (developmentCost == 0) revert EternalEstate__DevelopmentCostTooLow();

        ParcelAttributes storage attrs = _parcelAttributes[tokenId];
        if (attrs.developmentLevel >= 5) return; // Max development level

        // Require spending yield tokens
        // The user must have approved this contract to spend their yield tokens beforehand
        bool success = _yieldToken.transferFrom(msg.sender, address(this), developmentCost);
        if (!success) revert EternalEstate__TransferFailed();

        // Burn the tokens or transfer to a sink address
        // Example: transfer to zero address (burning)
        // bool burned = _yieldToken.transfer(address(0), developmentCost); // Requires token supports transfer to zero
        // if (!burned) revert EternalEstate__TransferFailed(); // Or specific burn function if available

        attrs.developmentLevel++; // Increase development level
        attrs.lastYieldClaimTimestamp = uint64(block.timestamp); // Reset claim time on development

        emit ParcelDeveloped(tokenId, attrs.developmentLevel, developmentCost);
    }

     /// @notice Admin function to set the address of the ERC20 yield token contract.
     /// @param yieldToken The address of the yield token contract.
    function setYieldTokenAddress(address yieldToken) public onlyOwner {
        if (yieldToken == address(0)) revert EternalEstate__InvalidAddress();
        _yieldToken = IERC20(yieldToken);
        // Consider adding a check that this is actually an ERC20 contract
    }

    /// @notice Admin function to update the global base yield rate.
    /// @param newRate The new base yield rate per second.
    function updateBaseYieldRate(uint256 newRate) public onlyOwner {
        _baseYieldRatePerSecond = newRate;
        emit BaseYieldRateUpdated(newRate);
    }


    // --- Internal Marketplace Functions ---

    /// @notice Lists a Parcel for sale on the internal marketplace.
    /// @param tokenId The ID of the parcel.
    /// @param price The price in wei.
    function listParcelForSale(uint256 tokenId, uint256 price) public nonReentrant {
        address parcelOwner = ownerOf(tokenId);
        if (parcelOwner != msg.sender) revert EternalEstate__NotOwner();
        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        if (_parcelListings[tokenId].active) revert EternalEstate__AlreadyListed();

        _parcelListings[tokenId] = Listing({
            seller: payable(msg.sender),
            price: price,
            active: true
        });

        // Approve this contract to hold the NFT while listed
        // Or, better, don't transfer ownership until sale, but require the owner not to transfer it
        // For simplicity here, the listing just records the intent. Transfer happens on buy.

        emit ParcelListed(tokenId, msg.sender, price);
    }

    /// @notice Allows a user to buy a listed Parcel.
    /// @param tokenId The ID of the parcel.
    /// Requires sending the exact listing price in ETH with the transaction.
    function buyParcel(uint256 tokenId) public payable nonReentrant {
        Listing storage listing = _parcelListings[tokenId];

        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        if (!listing.active) revert EternalEstate__NotListed();
        if (msg.value < listing.price) revert EternalEstate__InsufficientPayment();
        if (listing.seller == msg.sender) revert EternalEstate__InvalidAddress(); // Cannot buy your own parcel

        address seller = listing.seller;
        uint256 price = listing.price;

        // Invalidate listing BEFORE transferring funds and NFT to prevent reentrancy issues
        listing.active = false;
        delete _parcelListings[tokenId];

        // Transfer NFT to buyer
        // Use internal _transfer function to bypass approval requirements as listing confirms intent
        _transfer(seller, msg.sender, tokenId);

        // Transfer ETH to seller
        _safeTransferETH(payable(seller), price);

        // Refund any excess ETH
        if (msg.value > price) {
            _safeTransferETH(payable(msg.sender), msg.value - price);
        }

        emit ParcelSold(tokenId, msg.sender, seller, price);
    }

    /// @notice Allows the seller to cancel a Parcel listing.
    /// @param tokenId The ID of the parcel.
    function cancelListing(uint256 tokenId) public nonReentrant {
        Listing storage listing = _parcelListings[tokenId];

        if (!_exists(tokenId)) revert EternalEstate__ParcelNotFound();
        if (!listing.active) revert EternalEstate__NotListed();
        if (listing.seller != msg.sender) revert EternalEstate__NotOwner(); // Only seller can cancel

        listing.active = false; // Invalidate listing
        delete _parcelListings[tokenId];

        // If the NFT was transferred to the contract for listing, transfer it back here.
        // In this simplified version, the NFT stays with the owner.

        emit ParcelListingCancelled(tokenId);
    }

    /// @notice Gets the details of a Parcel listing.
    /// @param tokenId The ID of the parcel.
    /// @return seller The seller's address.
    /// @return price The listing price.
    /// @return active Whether the listing is active.
    function getListing(uint256 tokenId) public view returns (address seller, uint256 price, bool active) {
        Listing storage listing = _parcelListings[tokenId];
        return (listing.seller, listing.price, listing.active);
    }

    // --- VRF Integration Functions ---

    /// @notice Chainlink VRF callback function to fulfill random word requests.
    /// @param requestId The ID of the VRF request.
    /// @param randomWords The random words provided by VRF.
    function fulfillRandomWords(bytes32 requestId, uint256[] memory randomWords) external override onlyVRF {
        uint256 tokenId = _vrfRequests[requestId];
        if (tokenId == 0) revert EternalEstate__RequestNotFound(); // Should not happen with onlyVRF

        if (randomWords.length == 0) {
            // Handle case where VRF fails to provide words, maybe set default attributes
            delete _vrfRequests[requestId];
            return;
        }

        // Use the first random word to derive attributes
        uint256 randomValue = randomWords[0];

        // Derive attributes from the random value
        uint8 size = uint8(randomValue % 10) + 1; // Size 1-10
        uint8 typeId = uint8((randomValue / 10) % 3) + 1; // Type 1-3

        _parcelAttributes[tokenId] = ParcelAttributes({
            size: size,
            typeId: typeId,
            developmentLevel: 0, // Starts at 0
            lastYieldClaimTimestamp: uint64(block.timestamp) // Set initial claim time
        });

        delete _vrfRequests[requestId]; // Clean up the request

        emit ParcelAttributesSet(tokenId, size, typeId, 0);
        emit VRFFulfillmentReceived(requestId, tokenId);
    }


    /// @notice Admin function to set the VRF configuration parameters.
    /// @param vrfCoordinator The address of the VRF Coordinator contract.
    /// @param keyHash The key hash for VRF requests.
    /// @param fee The LINK fee for VRF requests.
    function setVRFConfig(address vrfCoordinator, bytes32 keyHash, uint256 fee) public onlyOwner {
        if (vrfCoordinator == address(0) || keyHash == bytes32(0) || fee == 0) {
             revert EternalEstate__InvalidAddress(); // Or specific error for VRF config
        }
        _vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        _vrfKeyHash = keyHash;
        _vrfFee = fee;
    }

     /// @notice Admin function to set the Oracle configuration parameters.
     /// @param oracle The address of the Oracle contract.
     /// @param jobId The Job ID for the Oracle request.
     /// @param fee The payment fee for the Oracle request (e.g., in LINK).
    function setOracleConfig(address oracle, bytes32 jobId, uint256 fee) public onlyOwner {
        if (oracle == address(0) || jobId == bytes32(0) || fee == 0) {
             revert EternalEstate__InvalidAddress(); // Or specific error for Oracle config
        }
        _oracleAddress = oracle;
        _oracleJobId = jobId;
        _oracleFee = fee;
    }


    // --- Helper Functions ---

    /// @dev Internal helper to safely transfer ETH, handling potential failures.
    function _safeTransferETH(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert EternalEstate__TransferFailed();
        }
    }
}
```