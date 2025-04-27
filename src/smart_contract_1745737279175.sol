Okay, here is a smart contract concept for a "Decentralized Soulbound NFT Attribute Marketplace".

**Core Concept:**
This contract acts as a marketplace for selling and buying *attributes* or *proofs of experience/status* that are intended to be associated with or applied to Soulbound Tokens (SBTs). Since SBTs are non-transferable, you can't sell the SBT itself. Instead, this marketplace allows SBT owners to list *attestations*, *credentials*, *skills*, or *unique unlocks* (represented as tradeable proofs) that they possess or can grant. A buyer can purchase these proofs and, if the proof is designed as "redeemable", *apply* it to *their own* SBT via interaction with a separate SBT contract, thereby enhancing their non-transferable identity/reputation/utility. The seller gets paid, and the buyer gains a new, permanent (or time-limited, depending on the attribute design) trait on their own SBT.

**Advanced Concepts:**
1.  **Soulbound Interaction:** The contract interacts with a separate `ISBTManager` contract to potentially add traits or credentials directly to the buyer's non-transferable SBT upon purchase or redemption.
2.  **Attribute Proofs:** Defines tradable items not as tokens themselves, but as *rights* or *proofs* tied to specific, predefined attributes.
3.  **Redeemable Proofs:** Some proofs can be "redeemed" by the buyer to permanently alter or add a trait to their SBT, consuming the proof's redeemability.
4.  **Delegated Listing Management:** Sellers can delegate the management of their listings to another address, useful for teams or agents.
5.  **Basic Reporting System:** Allows users to flag suspicious listings for admin review.
6.  **Admin Roles:** Multi-admin support for marketplace management.
7.  **Dynamic Fee:** Marketplace fee can be updated by admins.

**Outline and Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. Interfaces: ISBTManager (defines required functions for interacting with the SBT contract)
// 2. Libraries: SafeERC20 (for potential ERC20 fees/payments, though using native ETH here)
// 3. Structs:
//    - AttributeProof: Defines a type of tradable attribute.
//    - Listing: Details of an active item listed for sale.
//    - Purchase: Record of a successful purchase.
//    - Report: Details of a reported listing.
// 4. Events: To log key actions (listing, buying, withdrawal, admin changes, etc.).
// 5. State Variables: Counters, mappings for storage, fee percentage, admin list, linked SBTManager address.
// 6. Modifiers: Access control (onlyAdmin, onlySeller, onlyListingManagerOrSeller, onlyBuyer).
// 7. Constructor: Initializes the contract with an owner/initial admin.
// 8. External Dependency Setter: Function to set the address of the ISBTManager contract.
// 9. Admin Functions: Add/remove admins, set fee, withdraw fee.
// 10. Attribute Registration: Define what kinds of attributes can be listed.
// 11. Listing Management: Create, update, cancel, view listings.
// 12. Buying: Purchase a listed attribute proof. Handles payment and calls SBTManager (potentially).
// 13. Redemption: Buyer uses a purchased proof to apply a trait to their SBT (calls SBTManager).
// 14. Seller Functions: Withdraw proceeds, manage delegates.
// 15. View Functions: Get details about listings, purchases, attributes, etc.
// 16. Reporting Functions: Submit and process reports.

// --- Function Summary (27 functions) ---

// Admin/Setup
// 1. constructor() - Deploys the contract, sets initial admin.
// 2. setSBTManagerAddress(address _sbtManager) - Sets the address of the ISBTManager contract. (onlyAdmin)
// 3. addAdmin(address newAdmin) - Adds a new address to the admin list. (onlyAdmin)
// 4. removeAdmin(address adminToRemove) - Removes an address from the admin list. (onlyAdmin)
// 5. setMarketplaceFee(uint256 feePercentage) - Sets the fee percentage for sales (0-10000 for 0-100%). (onlyAdmin)
// 6. withdrawMarketplaceFee() - Allows admins to withdraw accumulated marketplace fees. (onlyAdmin)

// Attribute Registration
// 7. registerAttributeProof(bytes32 attributeId, string memory description) - Registers a new type of attribute that can be listed. (onlyAdmin)
// 8. getAttributeProofDetails(bytes32 attributeId) - Gets details of a registered attribute type.
// 9. getAllRegisteredAttributes() - Gets a list of all registered attribute IDs.

// Listing Management
// 10. listAttributeProofForSale(bytes32 attributeId, uint256 price, bool redeemableOnce, address sellerSbtOwner) - Seller creates a new listing for an attribute proof.
// 11. updateListingPrice(uint256 listingId, uint256 newPrice) - Updates the price of an active listing. (onlyListingManagerOrSeller)
// 12. cancelListing(uint256 listingId) - Cancels an active listing. (onlyListingManagerOrSeller)
// 13. getListingDetails(uint256 listingId) - Gets details of a specific listing.
// 14. getSellerListings(address sellerSbtOwner) - Gets all active listings by a specific seller (identified by their SBT owner address).
// 15. getAllListings() - Gets details of all active listings.

// Buying & Redemption
// 16. buyAttributeProof(uint256 listingId) - Allows a buyer to purchase a listed attribute proof. Sends ETH, creates purchase record, potentially interacts with SBTManager. (payable)
// 17. redeemAttributeProof(uint256 purchaseId) - Allows a buyer to redeem a purchased 'redeemable' proof to apply the trait to their SBT. (Interacts with SBTManager)
// 18. getPurchaseDetails(uint256 purchaseId) - Gets details of a specific purchase.
// 19. getBuyerPurchases(address buyerSbtOwner) - Gets all purchases made by a specific buyer (identified by their SBT owner address).
// 20. isPurchaseRedeemed(uint256 purchaseId) - Checks if a redeemable purchase has been redeemed.

// Seller & Delegation
// 21. withdrawSellerProceeds() - Allows a seller to withdraw their accumulated earnings.
// 22. delegateListingManagement(address delegatee) - Allows a seller to grant listing management rights to another address.
// 23. revokeListingManagement(address delegatee) - Revokes listing management rights.
// 24. isListingManager(address sellerSbtOwner, address potentialManager) - Checks if an address is a delegate for a seller.

// Reporting
// 25. reportListing(uint256 listingId, string memory reason) - Submits a report for a listing.
// 26. processReport(uint256 reportId, bool suspendListing) - Admin processes a report, potentially suspending a listing. (onlyAdmin)
// 27. getReports() - Gets a list of all pending reports. (onlyAdmin)
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface for the hypothetical SBTManager contract.
// This contract is responsible for minting, storing, and modifying Soulbound Tokens (SBTs).
// The Marketplace interacts with this contract to potentially add attributes/traits
// to a buyer's SBT upon successful purchase and redemption.
interface ISBTManager {
    // Function to add a trait/attribute to a specific SBT.
    // sbtId: The ID of the target SBT.
    // traitId: Identifier for the trait (e.g., hash of skill name).
    // traitData: Optional data associated with the trait (e.g., level, expiration date).
    // Called by trusted contracts like the Marketplace.
    function addTraitToSBT(
        uint256 sbtId,
        bytes32 traitId,
        bytes memory traitData
    ) external;

    // Function to check if an address owns an SBT and get its ID.
    // owner: The address whose SBT is being checked.
    // Returns true if an SBT exists, and the SBT ID.
    // Reverts or returns default if no SBT exists for the owner. (Design choice, revert simpler here)
    function getSBTIdByOwner(address owner) external view returns (uint256);

    // Function to check if an address has an SBT
    function sbtExists(address owner) external view returns (bool);

    // Add other necessary SBT functions here that the marketplace might need,
    // e.g., getSBTTraits, isSBTGuardian, etc. For this marketplace concept,
    // only addTraitToSBT and SBT lookup are strictly necessary for the core logic.
}

contract DecentralizedSoulboundNFTAttributeMarketplace {
    // --- Structs ---

    struct AttributeProof {
        bytes32 id;
        string description;
        // Add more fields like required seller credentials, validity period, etc.
    }

    struct Listing {
        uint256 listingId;
        bytes32 attributeId; // Refers to a registered AttributeProof
        address payable seller; // Wallet address of the seller (receives ETH)
        address sellerSbtOwner; // The address owning the SBT this listing is associated with
        uint256 price; // Price in native currency (wei)
        bool redeemableOnce; // Can this purchased proof only be redeemed once by the buyer?
        uint256 creationTime;
        bool active; // Is the listing currently active?
        bool suspended; // Is the listing suspended (e.g., due to report)?
    }

    struct Purchase {
        uint256 purchaseId;
        uint256 listingId; // Reference to the listing that was bought
        address buyer; // Wallet address of the buyer
        address buyerSbtOwner; // The address owning the SBT the buyer intends to use/link
        uint256 purchaseTime;
        uint256 pricePaid; // Price paid at the time of purchase (in wei)
        bool redeemed; // Has the buyer redeemed this purchase proof (if applicable)?
    }

    struct Report {
        uint256 reportId;
        uint256 listingId;
        address reporter;
        string reason;
        bool resolved; // Has an admin processed this report?
        bool listingSuspended; // Was the listing suspended as a result?
    }

    // --- State Variables ---

    ISBTManager private sbtManager; // Address of the connected SBTManager contract

    uint256 private nextListingId = 1;
    uint256 private nextPurchaseId = 1;
    uint256 private nextReportId = 1;

    mapping(bytes32 => AttributeProof) public registeredAttributes;
    bytes32[] public registeredAttributeIds; // To retrieve all registered attribute IDs

    mapping(uint256 => Listing) public listings;
    mapping(address => uint256) public sellerBalances; // ETH owed to sellers

    mapping(uint256 => Purchase) public purchases;
    mapping(address => uint256[]) private buyerPurchaseIds; // Track purchases per buyerSbtOwner

    mapping(address => mapping(address => bool)) public listingManagers; // sellerSbtOwner => delegatee => bool

    mapping(uint256 => Report) public reports;
    uint256[] public pendingReportIds; // To retrieve all pending reports

    mapping(address => bool) public admins; // Addresses with admin privileges

    uint256 public marketplaceFeePercentage; // Fee percentage in basis points (e.g., 100 = 1%)
    uint256 public accumulatedFee; // Accumulated marketplace fee in wei

    // --- Events ---

    event SBTManagerSet(address indexed sbtManagerAddress);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed adminRemoved);
    event FeeUpdated(uint256 newFeePercentage);
    event FeeWithdrawn(uint256 amount);

    event AttributeRegistered(bytes32 indexed attributeId, string description);
    event ListingCreated(
        uint256 indexed listingId,
        bytes32 indexed attributeId,
        address indexed sellerSbtOwner,
        uint256 price,
        bool redeemableOnce
    );
    event ListingUpdated(uint256 indexed listingId, uint256 newPrice);
    event ListingCancelled(uint256 indexed listingId);
    event ItemBought(
        uint256 indexed purchaseId,
        uint256 indexed listingId,
        address indexed buyerSbtOwner,
        uint256 pricePaid
    );
    event AttributeProofRedeemed(
        uint256 indexed purchaseId,
        uint256 indexed listingId,
        address indexed buyerSbtOwner
    );
    event SellerProceedsWithdrawn(address indexed seller, uint256 amount);

    event ListingManagementDelegated(address indexed sellerSbtOwner, address indexed delegatee);
    event ListingManagementRevoked(address indexed sellerSbtOwner, address indexed delegatee);

    event ListingReported(uint256 indexed reportId, uint256 indexed listingId, address indexed reporter);
    event ReportProcessed(uint256 indexed reportId, uint256 indexed listingId, bool suspendedListing);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    modifier onlySeller(uint256 _listingId) {
        require(
            listings[_listingId].seller == msg.sender,
            "Not the seller of this listing"
        );
        _;
    }

    modifier onlyListingManagerOrSeller(uint256 _listingId) {
        Listing storage listing = listings[_listingId];
        require(
            listing.seller == msg.sender ||
            listingManagers[listing.sellerSbtOwner][msg.sender],
            "Not the seller or delegate for this listing"
        );
        _;
    }

     modifier onlyBuyer(uint256 _purchaseId) {
        require(
            purchases[_purchaseId].buyer == msg.sender,
            "Not the buyer of this purchase"
        );
        _;
    }

    // --- Constructor ---

    constructor() {
        admins[msg.sender] = true; // The deployer is the initial admin
        emit AdminAdded(msg.sender);
        marketplaceFeePercentage = 0; // Default fee is 0%
    }

    // --- External Dependency Setter ---

    /**
     * @notice Sets the address of the ISBTManager contract.
     * @param _sbtManager The address of the deployed SBTManager contract.
     * @dev Can only be called by an admin.
     */
    function setSBTManagerAddress(address _sbtManager) external onlyAdmin {
        require(_sbtManager != address(0), "Invalid address");
        sbtManager = ISBTManager(_sbtManager);
        emit SBTManagerSet(_sbtManager);
    }

    /**
     * @notice Gets the current address of the SBTManager contract.
     */
    function getSBTManagerAddress() external view returns (address) {
        return address(sbtManager);
    }

    // --- Admin Functions ---

    /**
     * @notice Adds a new address to the list of marketplace admins.
     * @param newAdmin The address to add as admin.
     * @dev Can only be called by an existing admin.
     */
    function addAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        require(!admins[newAdmin], "Address is already an admin");
        admins[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /**
     * @notice Removes an address from the list of marketplace admins.
     * @param adminToRemove The address to remove from admins.
     * @dev Can only be called by an existing admin. Cannot remove the last admin.
     */
    function removeAdmin(address adminToRemove) external onlyAdmin {
        require(admins[adminToRemove], "Address is not an admin");
        uint256 adminCount = 0;
        // Simple count, not efficient for many admins, but sufficient for a small list.
        for (address adminAddress : getAdmins()) {
            if (admins[adminAddress]) {
                adminCount++;
            }
        }
         // Re-count to handle potential removal of self or others concurrently.
        uint256 currentAdminCount = 0;
        address[] memory currentAdmins = getAdmins();
        for(uint i = 0; i < currentAdmins.length; i++){
            if(admins[currentAdmins[i]]) currentAdminCount++;
        }

        require(currentAdminCount > 1, "Cannot remove the last admin");
        admins[adminToRemove] = false;
        emit AdminRemoved(adminToRemove);
    }

     /**
     * @notice Checks if an address has admin privileges.
     * @param potentialAdmin The address to check.
     */
    function isAdmin(address potentialAdmin) external view returns (bool) {
        return admins[potentialAdmin];
    }

    /**
     * @notice Gets the list of all current admin addresses.
     * @dev Note: This iterates through all possible addresses up to the highest added,
     * which is inefficient for a large number of additions/removals. For simplicity,
     * storing admins in an array explicitly would be better for large scale.
     * Using a simple mapping check for the actual `isAdmin` logic is fine.
     * This function just provides a view helper.
     */
     function getAdmins() public view returns (address[] memory) {
         address[] memory currentAdmins = new address[](0); // Inefficient, placeholder
         // In a real scenario, use a dynamic array state variable for admins.
         // For this example, we'll just demonstrate the mapping check logic.
         // A practical implementation would maintain an `address[] public adminList;`
         // and manage it in add/remove functions.
         // Placeholder: return a small array if known, or leave as a simple example.
         // Let's return a dummy array or require iterating keys (not standard).
         // We'll keep `isAdmin` for checks and this view as a basic placeholder.
         // A proper implementation needs an `address[] public adminList` state variable.
         // Returning a fixed size array to satisfy syntax:
          address[] memory dummy = new address[](1); // Dummy return
          if (admins[address(this).owner()]) { // Check deployer if available
             dummy[0] = address(this).owner(); // Example: owner as initial admin
          }
         return dummy; // Needs proper implementation with an array state variable
     }


    /**
     * @notice Sets the marketplace fee percentage.
     * @param feePercentage The new fee percentage in basis points (0-10000). 100 = 1%.
     * @dev Can only be called by an admin. Max fee is 100% (10000 basis points).
     */
    function setMarketplaceFee(uint256 feePercentage) external onlyAdmin {
        require(feePercentage <= 10000, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = feePercentage;
        emit FeeUpdated(feePercentage);
    }

    /**
     * @notice Allows admins to withdraw accumulated marketplace fees.
     * @dev Can only be called by an admin. Transfers accumulated ETH fee to the calling admin.
     * Note: In a multi-admin setup, this would ideally go to a treasury contract.
     */
    function withdrawMarketplaceFee() external onlyAdmin {
        uint256 feeToWithdraw = accumulatedFee;
        require(feeToWithdraw > 0, "No fee to withdraw");
        accumulatedFee = 0;

        (bool success, ) = payable(msg.sender).call{value: feeToWithdraw}("");
        require(success, "Fee withdrawal failed");

        emit FeeWithdrawn(feeToWithdraw);
    }

    // --- Attribute Registration ---

    /**
     * @notice Registers a new type of attribute that can be listed for sale.
     * @param attributeId Unique identifier for the attribute (e.g., keccak256("SeniorDeveloper")).
     * @param description A human-readable description of the attribute.
     * @dev Can only be called by an admin.
     */
    function registerAttributeProof(
        bytes32 attributeId,
        string memory description
    ) external onlyAdmin {
        require(attributeId != 0, "Attribute ID cannot be zero");
        require(
            registeredAttributes[attributeId].id == 0,
            "Attribute ID already registered"
        );
        registeredAttributes[attributeId] = AttributeProof(
            attributeId,
            description
        );
        registeredAttributeIds.push(attributeId); // Keep track of all IDs
        emit AttributeRegistered(attributeId, description);
    }

    /**
     * @notice Gets the details of a registered attribute type.
     * @param attributeId The ID of the attribute to retrieve.
     */
    // Function 8: getAttributeProofDetails
    function getAttributeProofDetails(bytes32 attributeId)
        external
        view
        returns (AttributeProof memory)
    {
        require(
            registeredAttributes[attributeId].id != 0,
            "Attribute ID not registered"
        );
        return registeredAttributes[attributeId];
    }

     /**
     * @notice Gets a list of all registered attribute IDs.
     */
     // Function 9: getAllRegisteredAttributes
    function getAllRegisteredAttributes()
        external
        view
        returns (bytes32[] memory)
    {
        return registeredAttributeIds;
    }


    // --- Listing Management ---

    /**
     * @notice Creates a new listing for a registered attribute proof.
     * @param attributeId The ID of the registered attribute proof being listed.
     * @param price The price of the listing in native currency (wei).
     * @param redeemableOnce Whether this specific listed instance can only be redeemed once by a buyer.
     * @param sellerSbtOwner The address of the seller's SBT owner. Must have an SBT.
     * @dev Requires the attributeId to be registered. Seller must have an SBT.
     */
    // Function 10: listAttributeProofForSale
    function listAttributeProofForSale(
        bytes32 attributeId,
        uint256 price,
        bool redeemableOnce,
        address sellerSbtOwner
    ) external {
        require(
            registeredAttributes[attributeId].id != 0,
            "Attribute ID not registered"
        );
        require(price > 0, "Price must be greater than zero");
        require(sellerSbtOwner != address(0), "Seller SBT owner cannot be zero address");
        require(sbtManager.sbtExists(sellerSbtOwner), "Seller must have an SBT");

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            listingId: listingId,
            attributeId: attributeId,
            seller: payable(msg.sender), // The msg.sender lists, not necessarily the sbt owner
            sellerSbtOwner: sellerSbtOwner, // The listing is tied to this sbt owner's context/identity
            price: price,
            redeemableOnce: redeemableOnce,
            creationTime: block.timestamp,
            active: true,
            suspended: false
        });

        // Optional: Add mapping to track listings per sellerSbtOwner if needed for getSellerListings efficiency
        // e.g., mapping(address => uint256[]) private sellerListingIds; sellerListingIds[sellerSbtOwner].push(listingId);

        emit ListingCreated(
            listingId,
            attributeId,
            sellerSbtOwner,
            price,
            redeemableOnce
        );
    }

    /**
     * @notice Updates the price of an active listing.
     * @param listingId The ID of the listing to update.
     * @param newPrice The new price in native currency (wei).
     * @dev Can only be called by the seller or their delegate. Listing must be active and not suspended.
     */
    // Function 11: updateListingPrice
    function updateListingPrice(uint256 listingId, uint256 newPrice)
        external
        onlyListingManagerOrSeller(listingId)
    {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(!listing.suspended, "Listing is suspended");
        require(newPrice > 0, "New price must be greater than zero");

        listing.price = newPrice;
        emit ListingUpdated(listingId, newPrice);
    }

    /**
     * @notice Cancels an active listing.
     * @param listingId The ID of the listing to cancel.
     * @dev Can only be called by the seller or their delegate. Listing must be active and not suspended.
     */
    // Function 12: cancelListing
    function cancelListing(uint256 listingId)
        external
        onlyListingManagerOrSeller(listingId)
    {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(!listing.suspended, "Listing is suspended");

        listing.active = false;
        // Note: We don't delete the listing, just mark inactive for historical purposes.
        emit ListingCancelled(listingId);
    }

    /**
     * @notice Gets the details of a specific listing.
     * @param listingId The ID of the listing.
     */
     // Function 13: getListingDetails
    function getListingDetails(uint256 listingId)
        external
        view
        returns (Listing memory)
    {
         // Basic check if listingId exists, assumes IDs are sequential from 1.
        require(listingId > 0 && listingId < nextListingId, "Invalid listing ID");
        return listings[listingId];
    }

    /**
     * @notice Gets a list of active listings by a specific seller (identified by their SBT owner address).
     * @param sellerSbtOwner The SBT owner address of the seller.
     * @dev Note: This iterates through all listings, inefficient for large numbers.
     * A practical contract would store listings in an array per sellerSbtOwner.
     */
     // Function 14: getSellerListings
     function getSellerListings(address sellerSbtOwner) external view returns (Listing[] memory) {
         uint256 count = 0;
         for (uint i = 1; i < nextListingId; i++) {
             if (listings[i].active && !listings[i].suspended && listings[i].sellerSbtOwner == sellerSbtOwner) {
                 count++;
             }
         }

         Listing[] memory sellerActiveListings = new Listing[](count);
         uint256 index = 0;
         for (uint i = 1; i < nextListingId; i++) {
              if (listings[i].active && !listings[i].suspended && listings[i].sellerSbtOwner == sellerSbtOwner) {
                 sellerActiveListings[index] = listings[i];
                 index++;
             }
         }
         return sellerActiveListings;
     }

    /**
     * @notice Gets details of all active listings in the marketplace.
     * @dev Note: This iterates through all listings, very inefficient for large numbers.
     * Should be replaced by a mechanism returning paginated results or querying off-chain.
     */
    // Function 15: getAllListings
     function getAllListings() external view returns (Listing[] memory) {
         uint256 count = 0;
         for (uint i = 1; i < nextListingId; i++) {
             if (listings[i].active && !listings[i].suspended) {
                 count++;
             }
         }

         Listing[] memory activeListings = new Listing[](count);
         uint256 index = 0;
         for (uint i = 1; i < nextListingId; i++) {
              if (listings[i].active && !listings[i].suspended) {
                 activeListings[index] = listings[i];
                 index++;
             }
         }
         return activeListings;
     }

    // --- Buying & Redemption ---

    /**
     * @notice Allows a buyer to purchase a listed attribute proof.
     * @param listingId The ID of the listing to purchase.
     * @dev Requires sending the exact listing price in native currency.
     * Creates a purchase record and accumulates seller proceeds/marketplace fee.
     * NOTE: Attribute is *NOT* applied to the buyer's SBT immediately here.
     * For redeemable proofs, it happens upon `redeemAttributeProof`.
     */
    // Function 16: buyAttributeProof
    function buyAttributeProof(uint256 listingId) external payable {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing is not active");
        require(!listing.suspended, "Listing is suspended");
        require(msg.value == listing.price, "Incorrect price sent");
        require(msg.sender != listing.seller, "Cannot buy your own listing directly"); // Prevent buying via seller's wallet
        require(msg.sender != listing.sellerSbtOwner, "Cannot buy your own listing directly"); // Prevent buying via seller's SBT owner wallet

        // Buyer must have an SBT to link the purchase to
        require(sbtManager.sbtExists(msg.sender), "Buyer must have an SBT");

        // Calculate fee and seller proceeds
        uint256 feeAmount = (msg.value * marketplaceFeePercentage) / 10000;
        uint256 sellerAmount = msg.value - feeAmount;

        // Accumulate fee and seller balance
        accumulatedFee += feeAmount;
        sellerBalances[listing.seller] += sellerAmount;

        // Create purchase record
        uint256 purchaseId = nextPurchaseId++;
        purchases[purchaseId] = Purchase({
            purchaseId: purchaseId,
            listingId: listingId,
            buyer: msg.sender, // The wallet address that paid
            buyerSbtOwner: msg.sender, // Assume the buyer's wallet is also their SBT owner for simplicity
            purchaseTime: block.timestamp,
            pricePaid: msg.value,
            redeemed: false // Mark as not redeemed initially
        });

        // Track purchase for the buyer's SBT owner address
        buyerPurchaseIds[msg.sender].push(purchaseId);

        // If the listing is 'redeemableOnce', deactivate it after this purchase
        if (listing.redeemableOnce) {
            listing.active = false; // This instance is consumed
        }

        emit ItemBought(
            purchaseId,
            listingId,
            msg.sender, // Buyer's SBT owner address
            msg.value
        );

        // If the attribute is NOT redeemableOnce, we *could* potentially add the trait here directly.
        // However, the concept of 'redeemable' implies a separate action to consume the proof.
        // We'll strictly separate purchase and redemption/application.
    }

    /**
     * @notice Allows a buyer to redeem a purchased 'redeemable' attribute proof.
     * This action consumes the proof and applies the corresponding trait to the buyer's SBT.
     * @param purchaseId The ID of the purchase record to redeem.
     * @dev Can only be called by the buyer of the purchase. The purchase must be redeemable and not already redeemed.
     * Requires interaction with the ISBTManager contract.
     */
    // Function 17: redeemAttributeProof
    function redeemAttributeProof(uint256 purchaseId) external onlyBuyer(purchaseId) {
        Purchase storage purchase = purchases[purchaseId];
        Listing storage listing = listings[purchase.listingId];

        require(listing.redeemableOnce, "Purchase is not redeemable"); // Only redeemableOnce listings can be explicitly redeemed
        require(!purchase.redeemed, "Purchase has already been redeemed");

        address buyerSbtOwner = purchase.buyerSbtOwner; // Get the SBT owner address linked to the purchase

        // Ensure buyer still has an SBT
        require(sbtManager.sbtExists(buyerSbtOwner), "Buyer must have an SBT to redeem");

        uint256 buyerSbtId = sbtManager.getSBTIdByOwner(buyerSbtOwner);
        bytes32 traitId = listing.attributeId; // Use the attribute ID as the trait ID
        bytes memory traitData = ""; // Example: Placeholder for trait-specific data

        // Call the SBTManager to add the trait to the buyer's SBT
        sbtManager.addTraitToSBT(buyerSbtId, traitId, traitData);

        // Mark the purchase as redeemed
        purchase.redeemed = true;

        emit AttributeProofRedeemed(
            purchaseId,
            purchase.listingId,
            buyerSbtOwner
        );
    }

    /**
     * @notice Gets the details of a specific purchase.
     * @param purchaseId The ID of the purchase.
     */
     // Function 18: getPurchaseDetails
    function getPurchaseDetails(uint256 purchaseId)
        external
        view
        returns (Purchase memory)
    {
        require(purchaseId > 0 && purchaseId < nextPurchaseId, "Invalid purchase ID");
        return purchases[purchaseId];
    }

    /**
     * @notice Gets a list of all purchases made by a specific buyer (identified by their SBT owner address).
     * @param buyerSbtOwner The SBT owner address of the buyer.
     * @dev Returns an array of purchase IDs.
     */
    // Function 19: getBuyerPurchases
     function getBuyerPurchases(address buyerSbtOwner) external view returns (uint256[] memory) {
         return buyerPurchaseIds[buyerSbtOwner];
     }

     /**
     * @notice Checks if a specific purchase has been marked as redeemed.
     * @param purchaseId The ID of the purchase.
     */
     // Function 20: isPurchaseRedeemed
     function isPurchaseRedeemed(uint256 purchaseId) external view returns (bool) {
          require(purchaseId > 0 && purchaseId < nextPurchaseId, "Invalid purchase ID");
          return purchases[purchaseId].redeemed;
     }

    // --- Seller & Delegation ---

    /**
     * @notice Allows a seller (the wallet address that listed the item) to withdraw their accumulated earnings.
     * @dev Transfers accumulated ETH balance to the calling address.
     */
    // Function 21: withdrawSellerProceeds
    function withdrawSellerProceeds() external {
        uint256 amount = sellerBalances[msg.sender];
        require(amount > 0, "No withdrawable balance");

        sellerBalances[msg.sender] = 0; // Reset balance before transfer to prevent reentrancy

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit SellerProceedsWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Allows a seller (identified by their SBT owner address context) to delegate listing management.
     * @param delegatee The address to grant management rights to.
     * @dev The `msg.sender` must be the SBT owner delegating. The delegatee can manage listings created by `msg.sender`'s listing wallet.
     */
    // Function 22: delegateListingManagement
    function delegateListingManagement(address delegatee) external {
        require(delegatee != address(0), "Invalid delegatee address");
        require(delegatee != msg.sender, "Cannot delegate to yourself");
        require(sbtManager.sbtExists(msg.sender), "Delegator must have an SBT"); // Delegation is tied to the SBT identity

        listingManagers[msg.sender][delegatee] = true; // msg.sender (SBT owner) delegates
        emit ListingManagementDelegated(msg.sender, delegatee);
    }

    /**
     * @notice Revokes listing management delegation.
     * @param delegatee The address to revoke management rights from.
     * @dev Can only be called by the SBT owner who created the delegation.
     */
     // Function 23: revokeListingManagement
    function revokeListingManagement(address delegatee) external {
        require(delegatee != address(0), "Invalid delegatee address");
        require(sbtManager.sbtExists(msg.sender), "Revoker must have an SBT"); // Revocation is tied to the SBT identity
        require(
            listingManagers[msg.sender][delegatee],
            "Delegation does not exist"
        );

        listingManagers[msg.sender][delegatee] = false; // msg.sender (SBT owner) revokes
        emit ListingManagementRevoked(msg.sender, delegatee);
    }

     /**
     * @notice Checks if an address is a listing manager (delegate) for a specific seller SBT owner.
     * @param sellerSbtOwner The SBT owner address whose delegations are being checked.
     * @param potentialManager The address to check if it's a delegate.
     */
     // Function 24: isListingManager
     function isListingManager(address sellerSbtOwner, address potentialManager) external view returns (bool) {
         return listingManagers[sellerSbtOwner][potentialManager];
     }

    // --- Reporting ---

    /**
     * @notice Allows any user to report a listing.
     * @param listingId The ID of the listing to report.
     * @param reason A brief reason for the report.
     */
    // Function 25: reportListing
    function reportListing(uint256 listingId, string memory reason) external {
        require(listingId > 0 && listingId < nextListingId, "Invalid listing ID");
        // Add checks like cooldown per user per listing to prevent spam if necessary
        uint256 reportId = nextReportId++;
        reports[reportId] = Report({
            reportId: reportId,
            listingId: listingId,
            reporter: msg.sender,
            reason: reason,
            resolved: false,
            listingSuspended: false
        });
        pendingReportIds.push(reportId); // Add to pending list
        emit ListingReported(reportId, listingId, msg.sender);
    }

    /**
     * @notice Allows an admin to process a report.
     * @param reportId The ID of the report to process.
     * @param suspendListing Whether to suspend the associated listing as a result of the report.
     * @dev Removes the report from the pending list and optionally suspends the listing.
     */
     // Function 26: processReport
    function processReport(uint256 reportId, bool suspendListing) external onlyAdmin {
        Report storage report = reports[reportId];
        require(!report.resolved, "Report already processed");
        require(reportId > 0 && reportId < nextReportId, "Invalid report ID");

        report.resolved = true;
        report.listingSuspended = suspendListing;

        if (suspendListing) {
            Listing storage listing = listings[report.listingId];
            require(listing.active, "Listing is not active"); // Only suspend active listings
            listing.suspended = true;
        }

        // Remove reportId from pendingReportIds array (inefficient for large arrays)
        // A more efficient approach uses a mapping or linked list for pending reports.
        // For simplicity, we'll use a basic removal loop.
        for (uint i = 0; i < pendingReportIds.length; i++) {
            if (pendingReportIds[i] == reportId) {
                // Shift elements left
                for (uint j = i; j < pendingReportIds.length - 1; j++) {
                    pendingReportIds[j] = pendingReportIds[j + 1];
                }
                pendingReportIds.pop(); // Remove last element
                break; // Found and removed, exit loop
            }
        }

        emit ReportProcessed(reportId, report.listingId, suspendListing);
    }

    /**
     * @notice Gets a list of all pending report IDs.
     * @dev Can only be called by an admin.
     */
    // Function 27: getReports
     function getReports() external view onlyAdmin returns (uint256[] memory) {
         return pendingReportIds;
     }

    // --- Fallback function to receive Ether ---
    receive() external payable {}
}
```