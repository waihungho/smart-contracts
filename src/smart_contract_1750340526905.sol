Okay, here is a smart contract concept called `DecentralizedCreativeCommons`. It aims to represent creative works as NFTs and manage on-chain licenses for their usage, including different license types, custom creator terms, and royalty mechanisms. It combines concepts from NFTs, access control, licensing, and payment splitting.

This contract includes implementations of basic ERC721 functionality, Pausable, and Ownable patterns for self-containment, written from scratch to adhere to the "no open source duplication" request, while following the standard interface concepts.

---

**Outline and Function Summary**

This contract, `DecentralizedCreativeCommons`, allows creators to mint unique digital assets representing their creative works. It then provides a framework for defining and granting licenses for the usage of these works, managing different types of permissions and associated royalties.

**I. Core Data Structures & State Variables:**
    *   `Work`: Represents a creative asset (NFT). Stores creator, metadata URI, and royalty info.
    *   `LicenseType`: Defines a standard or custom set of usage permissions. Stores name, description, and boolean flags for capabilities (modify, distribute, commercial use, attribution).
    *   `GrantedLicense`: Records an instance of a license granted to a specific user for a specific work under a given license type. Stores work ID, licensee, license type ID, grant date, and optional expiry.
    *   Counters (`workIdCounter`, `licenseTypeIdCounter`, `grantedLicenseIdCounter`) to track unique IDs.
    *   Mappings to store `Work`, `LicenseType` (system-wide), `LicenseType` (creator-specific), `GrantedLicense`, ownership data (ERC721), and royalty balances.

**II. Basic Contract Management (Custom Implementation of Standard Patterns):**
    *   `owner`: Address of the contract owner (admin).
    *   `_paused`: Boolean state for pausing contract operations.
    *   Modifiers: `onlyOwner`, `onlyWhenNotPaused`.
    *   Functions: `constructor`, `transferOwnership`, `pause`, `unpause`.

**III. ERC721 NFT Functionality (Custom Implementation):**
    *   Represents creative works as NFTs.
    *   State: `_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`.
    *   Events: `Transfer`, `Approval`, `ApprovalForAll`.
    *   Functions: `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom` (two variants).

**IV. Creative Work (NFT) Management:**
    *   `mintWork`: Mints a new NFT for a creative work. Requires metadata URI.
    *   `setWorkMetadataURI`: Allows the creator/owner of a work to update its metadata URI.
    *   `getWorkDetails`: Retrieves details of a specific work by ID.
    *   `getTotalWorks`: Returns the total number of works minted.

**V. System-Wide License Type Management:**
    *   `addSystemLicenseType`: Allows the contract owner to define a new standard license type with specific permissions and optional default royalty terms.
    *   `getSystemLicenseType`: Retrieves details of a system license type by ID.
    *   `getAllSystemLicenseTypeIds`: Returns an array of all defined system license type IDs.
    *   `getTotalSystemLicenseTypes`: Returns the total number of system license types.

**VI. Creator-Specific License Type Management:**
    *   `addCreatorCustomLicenseType`: Allows a work's creator/owner to define a license type unique to *that specific work*.
    *   `getCreatorCustomLicenseType`: Retrieves details of a creator's custom license type for a work.
    *   `getCreatorCustomLicenseTypeIdsForWork`: Returns an array of custom license type IDs defined for a specific work.

**VII. License Granting & Management:**
    *   `grantLicense`: Grants a license (either system or creator custom) for a specific work to a user. Can be payable if the license type requires it. Handles payment distribution.
    *   `getGrantedLicense`: Retrieves details of a specific granted license instance by its unique ID.
    *   `getGrantedLicenseIdsForWork`: Returns an array of all granted license instance IDs for a specific work.
    *   `getGrantedLicenseIdsForUser`: Returns an array of all granted license instance IDs held by a specific user.
    *   `getTotalGrantedLicenses`: Returns the total number of granted license instances.

**VIII. License Usage & Permission Checking:**
    *   `checkLicenseValidity`: Checks if a specific granted license instance is still valid (exists and not expired).
    *   `checkUsagePermission`: Checks if a user has *any* valid license for a work that permits a specific type of usage (modification, distribution, commercial use).

**IX. Royalty and Payment Management:**
    *   `setWorkRoyaltyRecipient`: Allows the work creator/owner to designate an address to receive royalties for that work.
    *   `getWorkRoyaltyRecipient`: Retrieves the current royalty recipient for a work.
    *   `getWorkRoyaltyBalance`: Checks the accumulated royalty balance for a specific work/recipient.
    *   `withdrawWorkRoyalties`: Allows the designated royalty recipient to withdraw accumulated ETH royalties for a work.

**X. Emergency & Maintenance:**
    *   `rescueETH`: Allows the owner to withdraw accidental ETH sent to the contract (excluding royalty balances).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline and Function Summary Above ---

contract DecentralizedCreativeCommons {

    // --- Errors ---
    error NotOwner();
    error Paused();
    error NotPaused();
    error ERC721InvalidOwner(address sender, uint256 tokenId);
    error ERC721NotApprovedOrOwner();
    error ERC721InvalidRecipient();
    error ERC721TokenAlreadyMinted();
    error InvalidWorkId();
    error InvalidLicenseTypeId();
    error InvalidGrantedLicenseId();
    error LicenseGrantExpired();
    error LicenseRequiresPayment();
    error PaymentExceedsRequired();
    error PaymentInsufficient();
    error RoyaltyRecipientNotSet();
    error ZeroRoyaltyBalance();
    error InvalidRoyaltyPercentage();
    error InvalidCreatorCustomLicenseId();
    error NotWorkCreator();


    // --- State Variables ---

    // --- ERC721 Basic Implementation (Standard Interfaces) ---
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // --- Contract Ownership (Standard Pattern) ---
    address private _owner;

    // --- Pausability (Standard Pattern) ---
    bool private _paused;

    // --- Counters ---
    uint256 private workIdCounter;
    uint256 private systemLicenseTypeIdCounter;
    uint256 private grantedLicenseIdCounter;
    // Creator custom licenses use nested counters per work
    mapping(uint256 => uint256) private creatorCustomLicenseTypeIdCounters;


    // --- Data Structures for Creative Commons Logic ---

    struct Work {
        address creator;
        string metadataURI;
        // Royalty information
        address royaltyRecipient;
        uint96 royaltyPercentage; // 0-10000 for 0-100%
        uint256 accumulatedRoyalties; // In Wei
    }

    struct LicenseType {
        uint256 id; // Redundant but useful for struct return/copy
        string name;
        string description;
        bool canModify;
        bool canDistribute;
        bool canUseCommercially;
        bool attributionRequired;
        uint256 requiredPayment; // In Wei, for payable licenses
        uint96 defaultRoyaltyPercentage; // Applied if no work-specific royaltyRecipient is set
    }

    struct GrantedLicense {
        uint256 id; // Redundant but useful for struct return/copy
        uint256 workId;
        address licensee;
        uint256 licenseTypeId; // References either a system or creator license type
        bool isSystemLicense; // True if references systemLicenseTypes, false if creatorCustomLicenseTypes
        uint256 grantDate;
        uint256 expiryDate; // 0 for perpetual
    }

    // --- Mappings for Creative Commons Logic ---

    // Work data (ERC721 token data)
    mapping(uint256 => Work) private _works;

    // System-wide license types
    mapping(uint256 => LicenseType) private systemLicenseTypes;

    // Creator-specific license types (WorkId => LicenseTypeId => LicenseType)
    mapping(uint256 => mapping(uint256 => LicenseType)) private creatorCustomLicenseTypes;

    // Granted license instances (GrantedLicenseId => GrantedLicense)
    mapping(uint256 => GrantedLicense) private grantedLicenses;

    // Mapping from workId/licensee/licenseTypeId to grantedLicenseId for quick lookup (Optional, but useful for preventing duplicate grants or finding a specific grant)
    // For simplicity and to reduce mapping complexity, we'll primarily query grantedLicenses via indices or iterate.
    // More advanced lookup structures could be added if needed.

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);

    event WorkMinted(uint256 indexed workId, address indexed creator, string metadataURI);
    event WorkMetadataUpdated(uint256 indexed workId, string newMetadataURI);
    event WorkRoyaltyRecipientUpdated(uint256 indexed workId, address indexed recipient);
    event WorkRoyaltiesWithdrawn(uint256 indexed workId, address indexed recipient, uint256 amount);

    event SystemLicenseTypeAdded(uint256 indexed licenseTypeId, string name);
    event CreatorCustomLicenseTypeAdded(uint256 indexed workId, uint256 indexed licenseTypeId, string name);
    event LicenseGranted(uint256 indexed grantedLicenseId, uint256 indexed workId, address indexed licensee, uint256 licenseTypeId, bool isSystemLicense);


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyWhenNotPaused() {
        if (_paused) {
            revert Paused();
        }
        _;
    }

    modifier onlyWhenPaused() {
        if (!_paused) {
            revert NotPaused();
        }
        _;
    }

    modifier onlyWorkCreator(uint256 workId) {
        if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
        if (msg.sender != _works[workId].creator) revert NotWorkCreator();
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        workIdCounter = 0;
        systemLicenseTypeIdCounter = 0;
        grantedLicenseIdCounter = 0;
    }

    // --- Basic Contract Management Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @notice Returns the current owner of the contract.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice Pauses the contract. Restricted to the owner.
    function pause() external onlyOwner onlyWhenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract. Restricted to the owner.
    function unpause() external onlyOwner onlyWhenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Returns the current paused state of the contract.
    function paused() public view returns (bool) {
        return _paused;
    }

    // --- ERC721 Standard Functions (Subset for Work NFTs) ---

    /// @notice Returns the number of NFTs owned by `owner`.
    /// @param owner The address whose balance is sought.
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0), 0);
        return _balances[owner];
    }

    /// @notice Returns the owner of the NFT specified by `tokenId`.
    /// @param tokenId The identifier for an NFT.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidWorkId(); // Using InvalidWorkId for clarity re: our context
        return owner;
    }

    /// @notice Approves another address to transfer the specified NFT.
    /// @param to The address to approve.
    /// @param tokenId The NFT to approve.
    function approve(address to, uint256 tokenId) external onlyWhenNotPaused {
        address owner = ownerOf(tokenId); // Checks if token exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
             revert ERC721NotApprovedOrOwner();
        }
        _approve(to, tokenId);
    }

    /// @notice Get the approved address for a single NFT.
    /// @param tokenId The NFT to query the approval for.
    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert InvalidWorkId();
        return _tokenApprovals[tokenId];
    }

    /// @notice Sets or unsets the approval for an operator to manage all NFTs of the caller.
    /// @param operator The address to approve.
    /// @param approved True to approve, false to unapprove.
    function setApprovalForAll(address operator, bool approved) external onlyWhenNotPaused {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Tells whether an operator is approved by a given owner.
    /// @param owner The address that owns the NFTs.
    /// @param operator The address that acts as an operator.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @notice Transfers ownership of an NFT from one address to another.
    /// @param from The current owner of the NFT.
    /// @param to The new owner.
    /// @param tokenId The NFT to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public onlyWhenNotPaused {
        _transfer(from, to, tokenId);
    }

    /// @notice Safely transfers ownership of an NFT from one address to another.
    /// @param from The current owner of the NFT.
    /// @param to The new owner.
    /// @param tokenId The NFT to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) public onlyWhenNotPaused {
         _transfer(from, to, tokenId);
         // In a full implementation, this would include the ERC721Receiver check
         // For simplicity and focus on the core CC logic, we omit the check here.
    }

    /// @notice Safely transfers ownership of an NFT from one address to another with additional data.
    /// @param from The current owner of the NFT.
    /// @param to The new owner.
    /// @param tokenId The NFT to transfer.
    /// @param data Additional data with no specified format.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public onlyWhenNotPaused {
         _transfer(from, to, tokenId);
         // In a full implementation, this would include the ERC721Receiver check
         // For simplicity and focus on the core CC logic, we omit the check here.
         // The `data` parameter is included for interface compatibility but ignored.
         data; // Avoid unused variable warning
    }

    // Internal ERC721 helper functions
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert ERC721InvalidOwner(from, tokenId);
        if (to == address(0)) revert ERC721InvalidRecipient();

        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert ERC721NotApprovedOrOwner();
        }

        // Clear approval
        _approve(address(0), tokenId);

        // Update balances
        _balances[from]--;
        _balances[to]++;

        // Update owner
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // --- Creative Work (NFT) Management Functions ---

    /// @notice Mints a new creative work represented as an NFT.
    /// @param metadataURI URI pointing to off-chain metadata (e.g., IPFS).
    /// @return The ID of the newly minted work (NFT).
    function mintWork(string memory metadataURI) external onlyWhenNotPaused returns (uint256) {
        uint256 newWorkId = workIdCounter++;
        _works[newWorkId] = Work({
            creator: msg.sender,
            metadataURI: metadataURI,
            royaltyRecipient: msg.sender, // Default royalty recipient is creator
            royaltyPercentage: 0, // Default 0% royalty (can be set later)
            accumulatedRoyalties: 0
        });

        // Mint the ERC721 token
        _owners[newWorkId] = msg.sender;
        _balances[msg.sender]++;

        emit Transfer(address(0), msg.sender, newWorkId);
        emit WorkMinted(newWorkId, msg.sender, metadataURI);
        return newWorkId;
    }

    /// @notice Allows the creator/owner of a work NFT to update its metadata URI.
    /// @param workId The ID of the work.
    /// @param newMetadataURI The new URI.
    function setWorkMetadataURI(uint256 workId, string memory newMetadataURI) external onlyWhenNotPaused {
        if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
        if (_owners[workId] != msg.sender) revert ERC721NotApprovedOrOwner(); // Only owner can update

        _works[workId].metadataURI = newMetadataURI;
        emit WorkMetadataUpdated(workId, newMetadataURI);
    }

    /// @notice Gets the details of a creative work.
    /// @param workId The ID of the work.
    /// @return The Work struct.
    function getWorkDetails(uint256 workId) public view returns (Work memory) {
        if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
        return _works[workId];
    }

     /// @notice Gets the metadata URI for a creative work.
    /// @param workId The ID of the work.
    /// @return The metadata URI string.
    function getWorkMetadataURI(uint256 workId) public view returns (string memory) {
         if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
        return _works[workId].metadataURI;
    }

    /// @notice Returns the total number of works minted.
    function getTotalWorks() public view returns (uint256) {
        return workIdCounter;
    }

    // --- System-Wide License Type Management Functions ---

    /// @notice Allows the contract owner to add a new system-wide license type.
    /// @param name Name of the license type (e.g., "Attribution-Only").
    /// @param description Description of the license terms.
    /// @param canModify Permission flag.
    /// @param canDistribute Permission flag.
    /// @param canUseCommercially Permission flag.
    /// @param attributionRequired Permission flag.
    /// @param requiredPayment Required payment in Wei for this license type.
    /// @param defaultRoyaltyPercentage Default percentage (0-10000) if work has no specific recipient.
    /// @return The ID of the newly added system license type.
    function addSystemLicenseType(
        string memory name,
        string memory description,
        bool canModify,
        bool canDistribute,
        bool canUseCommercially,
        bool attributionRequired,
        uint256 requiredPayment,
        uint96 defaultRoyaltyPercentage // 0-10000
    ) external onlyOwner onlyWhenNotPaused returns (uint256) {
        if (defaultRoyaltyPercentage > 10000) revert InvalidRoyaltyPercentage();

        uint256 newLicenseTypeId = systemLicenseTypeIdCounter++;
        systemLicenseTypes[newLicenseTypeId] = LicenseType({
            id: newLicenseTypeId,
            name: name,
            description: description,
            canModify: canModify,
            canDistribute: canDistribute,
            canUseCommercially: canUseCommercially,
            attributionRequired: attributionRequired,
            requiredPayment: requiredPayment,
            defaultRoyaltyPercentage: defaultRoyaltyPercentage
        });

        emit SystemLicenseTypeAdded(newLicenseTypeId, name);
        return newLicenseTypeId;
    }

    /// @notice Gets the details of a system-wide license type.
    /// @param licenseTypeId The ID of the system license type.
    /// @return The LicenseType struct.
    function getSystemLicenseType(uint256 licenseTypeId) public view returns (LicenseType memory) {
        if (licenseTypeId >= systemLicenseTypeIdCounter) revert InvalidLicenseTypeId();
        return systemLicenseTypes[licenseTypeId];
    }

     /// @notice Gets the total number of system license types defined.
    function getTotalSystemLicenseTypes() public view returns (uint256) {
        return systemLicenseTypeIdCounter;
    }

    /// @notice (Helper) Returns an array of all system license type IDs.
    function getAllSystemLicenseTypeIds() public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](systemLicenseTypeIdCounter);
        for (uint256 i = 0; i < systemLicenseTypeIdCounter; i++) {
            ids[i] = i;
        }
        return ids;
    }

    // --- Creator-Specific License Type Management Functions ---

     /// @notice Allows the creator/owner of a work to add a custom license type specific to that work.
    /// @param workId The ID of the work.
    /// @param name Name of the custom license type.
    /// @param description Description of the terms.
    /// @param canModify Permission flag.
    /// @param canDistribute Permission flag.
    /// @param canUseCommercially Permission flag.
    /// @param attributionRequired Permission flag.
    /// @param requiredPayment Required payment in Wei for this custom license type.
    /// @param defaultRoyaltyPercentage Default percentage (0-10000) if work has no specific recipient.
    /// @return The ID of the newly added creator custom license type (scoped to the work).
    function addCreatorCustomLicenseType(
        uint256 workId,
        string memory name,
        string memory description,
        bool canModify,
        bool canDistribute,
        bool canUseCommercially,
        bool attributionRequired,
        uint256 requiredPayment,
        uint96 defaultRoyaltyPercentage // 0-10000
    ) external onlyWorkCreator(workId) onlyWhenNotPaused returns (uint256) {
         if (defaultRoyaltyPercentage > 10000) revert InvalidRoyaltyPercentage();
         if (!_exists(workId)) revert InvalidWorkId();

        uint256 newLicenseTypeId = creatorCustomLicenseTypeIdCounters[workId]++;
        creatorCustomLicenseTypes[workId][newLicenseTypeId] = LicenseType({
             id: newLicenseTypeId, // This ID is unique *within* this work's custom licenses
             name: name,
             description: description,
             canModify: canModify,
             canDistribute: canDistribute,
             canUseCommercially: canUseCommercially,
             attributionRequired: attributionRequired,
             requiredPayment: requiredPayment,
             defaultRoyaltyPercentage: defaultRoyaltyPercentage
        });

        emit CreatorCustomLicenseTypeAdded(workId, newLicenseTypeId, name);
        return newLicenseTypeId;
    }

    /// @notice Gets the details of a creator-specific custom license type for a work.
    /// @param workId The ID of the work.
    /// @param licenseTypeId The ID of the custom license type (scoped to the work).
    /// @return The LicenseType struct.
    function getCreatorCustomLicenseType(uint256 workId, uint256 licenseTypeId) public view returns (LicenseType memory) {
        if (!_exists(workId)) revert InvalidWorkId();
        if (licenseTypeId >= creatorCustomLicenseTypeIdCounters[workId]) revert InvalidCreatorCustomLicenseId();
        return creatorCustomLicenseTypes[workId][licenseTypeId];
    }

     /// @notice Returns an array of all creator custom license type IDs for a specific work.
     /// @param workId The ID of the work.
     function getCreatorCustomLicenseTypeIdsForWork(uint256 workId) public view returns (uint256[] memory) {
         if (!_exists(workId)) revert InvalidWorkId();
         uint256 count = creatorCustomLicenseTypeIdCounters[workId];
         uint256[] memory ids = new uint256[](count);
         for (uint256 i = 0; i < count; i++) {
             ids[i] = i;
         }
         return ids;
     }


    // --- License Granting & Management Functions ---

    /// @notice Grants a license for a work to a specified user.
    /// @param workId The ID of the work.
    /// @param licensee The address to grant the license to.
    /// @param licenseTypeId The ID of the license type (system or custom).
    /// @param isSystemLicense True if licenseTypeId refers to a system type, false for custom.
    /// @param expiryDate Optional expiry timestamp (0 for perpetual).
    function grantLicense(
        uint256 workId,
        address licensee,
        uint256 licenseTypeId,
        bool isSystemLicense,
        uint256 expiryDate // 0 for perpetual
    ) external payable onlyWhenNotPaused {
        if (!_exists(workId)) revert InvalidWorkId();
        if (licensee == address(0)) revert ERC721InvalidRecipient();

        LicenseType memory licenseType;
        if (isSystemLicense) {
            if (licenseTypeId >= systemLicenseTypeIdCounter) revert InvalidLicenseTypeId();
            licenseType = systemLicenseTypes[licenseTypeId];
        } else {
             if (licenseTypeId >= creatorCustomLicenseTypeIdCounters[workId]) revert InvalidCreatorCustomLicenseId();
            licenseType = creatorCustomLicenseTypes[workId][licenseTypeId];
        }

        // Handle required payment
        if (licenseType.requiredPayment > 0) {
            if (msg.value < licenseType.requiredPayment) {
                revert PaymentInsufficient();
            }
            if (msg.value > licenseType.requiredPayment) {
                 // Refund excess Ether
                 (bool success, ) = payable(msg.sender).call{value: msg.value - licenseType.requiredPayment}("");
                 // Ideally, this should be in a check-effects-interactions pattern, but simple refund is okay here.
                 require(success, "Refund failed");
            }

            // Process payment and royalties
            uint256 paymentAmount = licenseType.requiredPayment;
            uint256 royaltyAmount = 0;
            address payable royaltyRecipient = payable(address(0));

            address workRoyaltyRecipient = _works[workId].royaltyRecipient;
            uint96 workRoyaltyPercentage = _works[workId].royaltyPercentage;

            if (workRoyaltyRecipient != address(0) && workRoyaltyPercentage > 0) {
                 // Use work-specific royalty info
                 royaltyRecipient = payable(workRoyaltyRecipient);
                 royaltyAmount = (paymentAmount * workRoyaltyPercentage) / 10000;
                 _works[workId].accumulatedRoyalties += royaltyAmount; // Hold royalties in contract
            } else if (licenseType.defaultRoyaltyPercentage > 0) {
                 // Use default license type royalty info if no work-specific one is set
                 royaltyRecipient = payable(_works[workId].creator); // Default to creator if no specific recipient
                 royaltyAmount = (paymentAmount * licenseType.defaultRoyaltyPercentage) / 10000;
                 _works[workId].accumulatedRoyalties += royaltyAmount; // Hold royalties in contract
            }

            uint256 amountToCreator = paymentAmount - royaltyAmount;
            if (amountToCreator > 0 && _works[workId].creator != address(0)) {
                 // Send remaining amount to the creator directly (or hold if desired)
                 (bool success, ) = payable(_works[workId].creator).call{value: amountToCreator}("");
                 require(success, "Payment to creator failed"); // Ensure creator receives payment portion
            }

        } else {
            // If no payment required, ensure no ETH was sent
            if (msg.value > 0) {
                 revert PaymentExceedsRequired(); // No payment expected
            }
        }


        uint256 newGrantedLicenseId = grantedLicenseIdCounter++;
        grantedLicenses[newGrantedLicenseId] = GrantedLicense({
            id: newGrantedLicenseId,
            workId: workId,
            licensee: licensee,
            licenseTypeId: licenseTypeId,
            isSystemLicense: isSystemLicense,
            grantDate: block.timestamp,
            expiryDate: expiryDate
        });

        emit LicenseGranted(newGrantedLicenseId, workId, licensee, licenseTypeId, isSystemLicense);
    }

    /// @notice Gets the details of a specific granted license instance.
    /// @param grantedLicenseId The ID of the granted license instance.
    /// @return The GrantedLicense struct.
    function getGrantedLicense(uint256 grantedLicenseId) public view returns (GrantedLicense memory) {
        if (grantedLicenseId >= grantedLicenseIdCounter || grantedLicenses[grantedLicenseId].workId == 0 && grantedLicenses[grantedLicenseId].licensee == address(0)) {
             // Check if ID is valid and the struct is not empty (default values)
             revert InvalidGrantedLicenseId();
        }
        return grantedLicenses[grantedLicenseId];
    }

     /// @notice (Helper) Returns an array of all granted license instance IDs for a specific work.
     /// Note: This can be computationally expensive for works with many licenses.
     /// Consider off-chain indexing or alternative query methods for production.
     /// @param workId The ID of the work.
     function getGrantedLicenseIdsForWork(uint256 workId) public view returns (uint256[] memory) {
         if (!_exists(workId)) revert InvalidWorkId();

         uint256[] memory ids = new uint256[](grantedLicenseIdCounter);
         uint256 count = 0;
         for (uint256 i = 0; i < grantedLicenseIdCounter; i++) {
             if (grantedLicenses[i].workId == workId && grantedLicenses[i].licensee != address(0)) {
                 ids[count++] = i;
             }
         }
         // Trim the array to the actual number of licenses found
         uint256[] memory result = new uint256[](count);
         for (uint256 i = 0; i < count; i++) {
             result[i] = ids[i];
         }
         return result;
     }

    /// @notice (Helper) Returns an array of all granted license instance IDs held by a specific user.
    /// Note: This can be computationally expensive for users with many licenses.
    /// Consider off-chain indexing or alternative query methods for production.
    /// @param user The address of the user.
    function getGrantedLicenseIdsForUser(address user) public view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](grantedLicenseIdCounter);
        uint256 count = 0;
        for (uint256 i = 0; i < grantedLicenseIdCounter; i++) {
            if (grantedLicenses[i].licensee == user) {
                ids[count++] = i;
            }
        }
        // Trim the array
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ids[i];
        }
        return result;
    }

     /// @notice Returns the total number of granted license instances.
    function getTotalGrantedLicenses() public view returns (uint256) {
        return grantedLicenseIdCounter;
    }


    // --- License Usage & Permission Checking Functions ---

    /// @notice Checks if a specific granted license instance is currently valid.
    /// Validity requires: the license exists, it's for the correct work/licensee (implicit via ID lookup), and it has not expired.
    /// @param grantedLicenseId The ID of the granted license instance.
    /// @return True if the license is valid, false otherwise.
    function checkLicenseValidity(uint256 grantedLicenseId) public view returns (bool) {
        if (grantedLicenseId >= grantedLicenseIdCounter || grantedLicenses[grantedLicenseId].licensee == address(0)) {
             // Check if ID is valid and the struct is not empty
             return false;
        }
        GrantedLicense memory granted = grantedLicenses[grantedLicenseId];
        // Check expiry date (0 means perpetual)
        if (granted.expiryDate != 0 && block.timestamp > granted.expiryDate) {
            return false;
        }
        return true;
    }

    /// @notice Checks if a user has *any* valid license for a work that permits a specific usage type.
    /// @param workId The ID of the work.
    /// @param user The address of the user.
    /// @param usageType The type of usage to check (0=Modify, 1=Distribute, 2=Commercial).
    /// @return True if the user has at least one valid license permitting the requested usage, false otherwise.
    function checkUsagePermission(uint256 workId, address user, uint8 usageType) public view returns (bool) {
        if (!_exists(workId)) return false; // Work must exist

        // Iterate through all granted licenses globally (inefficient for large number of licenses)
        // For a production system, a mapping from (user, workId) to grantedLicenseIds would be more efficient.
        for (uint256 i = 0; i < grantedLicenseIdCounter; i++) {
            GrantedLicense memory granted = grantedLicenses[i];

            // Check if the license is for this work and this user
            if (granted.workId == workId && granted.licensee == user) {
                // Check if the license is valid
                if (checkLicenseValidity(i)) { // Use the helper function
                    LicenseType memory licenseType;
                    if (granted.isSystemLicense) {
                        // Double check licenseTypeId validity (should be covered by grant check but safety first)
                        if (granted.licenseTypeId >= systemLicenseTypeIdCounter) continue;
                        licenseType = systemLicenseTypes[granted.licenseTypeId];
                    } else {
                         if (granted.licenseTypeId >= creatorCustomLicenseTypeIdCounters[workId]) continue;
                         licenseType = creatorCustomLicenseTypes[workId][granted.licenseTypeId];
                    }

                    // Check the specific permission flag
                    if (usageType == 0 && licenseType.canModify) return true;
                    if (usageType == 1 && licenseType.canDistribute) return true;
                    if (usageType == 2 && licenseType.canUseCommercially) return true;
                     // AttributionRequired isn't a usage *permission* but a condition, so not included here
                }
            }
        }

        return false; // No valid license found granting the required permission
    }

    // --- Royalty and Payment Management Functions ---

    /// @notice Allows the creator/owner of a work to set the address that receives royalties for that work.
    /// Defaults to the creator upon minting. Setting to address(0) means no specific recipient is set, and default license royalties will apply to creator.
    /// @param workId The ID of the work.
    /// @param recipient The address to receive royalties.
    function setWorkRoyaltyRecipient(uint256 workId, address recipient) external onlyWorkCreator(workId) onlyWhenNotPaused {
        if (!_exists(workId)) revert InvalidWorkId();
         // Only creator/owner can set recipient for their work. Check done by modifier.
        _works[workId].royaltyRecipient = recipient;
        emit WorkRoyaltyRecipientUpdated(workId, recipient);
    }

    /// @notice Allows the creator/owner of a work to set the royalty percentage for that work.
    /// This percentage overrides the default percentage on the license type.
    /// @param workId The ID of the work.
    /// @param percentage The royalty percentage (0-10000 for 0-100%).
     function setWorkRoyaltyPercentage(uint256 workId, uint96 percentage) external onlyWorkCreator(workId) onlyWhenNotPaused {
        if (!_exists(workId)) revert InvalidWorkId();
         if (percentage > 10000) revert InvalidRoyaltyPercentage();
         // Only creator/owner can set percentage for their work. Check done by modifier.
         _works[workId].royaltyPercentage = percentage;
     }


    /// @notice Gets the current royalty recipient for a work.
    /// @param workId The ID of the work.
    /// @return The address of the royalty recipient.
    function getWorkRoyaltyRecipient(uint256 workId) public view returns (address) {
         if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
        return _works[workId].royaltyRecipient;
    }

    /// @notice Gets the current accumulated royalty balance for a work.
    /// This balance is held in the contract for the work's designated recipient to withdraw.
    /// @param workId The ID of the work.
    /// @return The accumulated balance in Wei.
     function getWorkRoyaltyBalance(uint256 workId) public view returns (uint256) {
         if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists
         return _works[workId].accumulatedRoyalties;
     }


    /// @notice Allows the designated royalty recipient for a work to withdraw accumulated royalties.
    /// @param workId The ID of the work.
    function withdrawWorkRoyalties(uint256 workId) external onlyWhenNotPaused {
        if (_works[workId].creator == address(0)) revert InvalidWorkId(); // Ensure work exists

        address payable recipient = payable(_works[workId].royaltyRecipient);
        if (recipient == address(0)) revert RoyaltyRecipientNotSet();
        if (msg.sender != recipient) revert NotOwner(); // Only the designated recipient can withdraw

        uint256 balance = _works[workId].accumulatedRoyalties;
        if (balance == 0) revert ZeroRoyaltyBalance();

        _works[workId].accumulatedRoyalties = 0; // Reset balance before sending

        // Send ETH using a low-level call pattern for safety against reentrancy
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) {
            // Revert the balance change if the transfer failed
            _works[workId].accumulatedRoyalties = balance;
            revert("Withdrawal failed"); // Indicate transfer failure
        }

        emit WorkRoyaltiesWithdrawn(workId, recipient, balance);
    }

    // --- Emergency & Maintenance ---

    /// @notice Allows the contract owner to withdraw any ETH accidentally sent to the contract
    /// that is not part of the accumulated royalties.
    function rescueETH() external onlyOwner onlyWhenNotPaused {
        uint256 contractBalance = address(this).balance;
        uint256 totalAccumulatedRoyalties = 0;
        // This loop can be expensive - in a production system, manage total accumulated balance explicitly.
        for(uint256 i = 0; i < workIdCounter; i++) {
             if (_exists(i)) { // Check if work exists (was minted)
                totalAccumulatedRoyalties += _works[i].accumulatedRoyalties;
             }
        }

        uint256 rescueAmount = contractBalance - totalAccumulatedRoyalties;

        if (rescueAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: rescueAmount}("");
            require(success, "ETH rescue failed");
        }
    }

    // Receive Ether function to accept payments for licenses
    receive() external payable {
        // Intentionally empty or minimal logic.
        // Payments should primarily go through grantLicense() which handles payment processing.
        // Any ETH sent directly must be intended for accidental rescue or similar.
    }

    // --- View functions for counters (already included above) ---
    // getTotalWorks(), getTotalSystemLicenseTypes(), getTotalGrantedLicenses()
    // getCreatorCustomLicenseTypeIdsForWork() also implicitly gives the count.


    // Total function count check:
    // ERC721: 8 (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom x2) + _transfer, _approve, _exists (internals, total 11 related)
    // Base Mgmt: 5 (constructor, transferOwnership, owner, pause, unpause, paused)
    // Work Mgmt: 5 (mintWork, setWorkMetadataURI, getWorkDetails, getWorkMetadataURI, getTotalWorks)
    // System License Mgmt: 4 (addSystemLicenseType, getSystemLicenseType, getTotalSystemLicenseTypes, getAllSystemLicenseTypeIds)
    // Creator Custom License Mgmt: 3 (addCreatorCustomLicenseType, getCreatorCustomLicenseType, getCreatorCustomLicenseTypeIdsForWork)
    // Granted License Mgmt: 5 (grantLicense, getGrantedLicense, getGrantedLicenseIdsForWork, getGrantedLicenseIdsForUser, getTotalGrantedLicenses)
    // Permission Check: 2 (checkLicenseValidity, checkUsagePermission)
    // Royalty Mgmt: 4 (setWorkRoyaltyRecipient, setWorkRoyaltyPercentage, getWorkRoyaltyRecipient, getWorkRoyaltyBalance, withdrawWorkRoyalties - 5 functions)
    // Emergency: 1 (rescueETH)
    // Receive: 1 (receive)

    // Total: 11 (ERC721 related) + 5 (Base) + 5 (Work) + 4 (System License) + 3 (Custom License) + 5 (Granted License) + 2 (Permission) + 5 (Royalty) + 1 (Emergency) + 1 (Receive)
    // Roughly counting external/public functions callable or viewable outside:
    // 8 (ERC721) + 4 (Base: owner, pause, unpause, transferOwnership) + 5 (Work) + 4 (Sys License) + 3 (Custom License) + 5 (Granted License) + 2 (Permission) + 5 (Royalty) + 1 (Emergency) + 1 (Receive)
    // Total Public/External/View: 8 + 4 + 5 + 4 + 3 + 5 + 2 + 5 + 1 + 1 = 38 functions. Well over 20.

}
```

---

**Explanation of Advanced/Creative Concepts Used:**

1.  **NFTs for Creative Works:** Uses ERC-721 standard (implemented internally) to make each creative work a unique, transferable digital asset.
2.  **Layered Rights Management:** Separates ownership (NFT) from usage rights (Licenses). Owning the NFT doesn't automatically grant all usage rights; those are defined and managed separately via licenses.
3.  **System vs. Creator-Defined Licenses:** Allows for both standardized "Creative Commons"-like terms managed by the contract owner *and* unique, custom terms defined by individual creators for their specific works. This provides flexibility.
4.  **On-Chain License Grants:** Licenses are specific on-chain records linking a user, a work, and a set of terms (LicenseType), with a grant date and optional expiry.
5.  **Conditional Access/Usage Checks:** The `checkUsagePermission` function allows querying the contract to see if a user holds *any* valid license for a work that permits a specific action (modify, distribute, commercial), enabling potential integration with dApps that enforce these rights.
6.  **Royalty Management:** Implements a basic on-chain royalty splitting mechanism for payable licenses, allowing creators to set a recipient and percentage for their work, overriding the license type's default. Royalties are held in the contract and can be withdrawn.
7.  **Internal ERC721/Ownable/Pausable:** Rather than importing OpenZeppelin (to adhere to the "no open source duplication" request), these standard patterns are implemented directly within the contract. This increases complexity and code size but demonstrates understanding of the underlying mechanics. (Note: In a real-world scenario, using battle-tested libraries like OpenZeppelin is *highly* recommended for security).
8.  **Structs and Mappings for Complex State:** Uses multiple structs (`Work`, `LicenseType`, `GrantedLicense`) and nested mappings to manage the relationships between works, license types, and granted licenses efficiently on-chain.
9.  **Payment Handling (`payable`, `receive`):** Includes logic to handle ETH payments when granting licenses and distribute them between the creator and designated royalty recipient, while holding royalties for later withdrawal. Includes a `receive` function and `rescueETH` for robustness.
10. **Counters for Unique IDs:** Uses simple incrementing counters to generate unique IDs for works, license types, and granted licenses, ensuring distinct on-chain records.

This contract structure provides a foundation for building a decentralized platform around creative content, focusing on flexible rights management beyond simple NFT ownership.