Okay, here is a smart contract for a Metaverse Property Registry. It combines concepts like unique digital assets (NFTs), virtual property management, dynamic attributes, access delegation, timed access, building permits, structure types, and listing mechanisms, aiming for a unique combination beyond standard implementations.

It includes an outline and function summary at the top, followed by the Solidity code.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; // Just for example, if we needed to check interface support

/*
* @title MetaversePropertyRegistry
* @author Your Name/Alias
* @dev This contract manages unique digital properties within a metaverse.
* It extends ERC721 for core ownership and adds complex features
* like state management, dynamic attributes, delegation, timed access,
* building permits, structure assignments, and listing for rent/sale.
*/

// --- Outline and Function Summary ---
/*
* I. State Definitions (Enums, Structs, Mappings, Counters)
*    - Enum PropertyState: Defines the development/occupancy status of a property.
*    - Struct PropertyData: Holds all dynamic and static data for a property NFT.
*    - Struct RentalInfo: Details for an active rental.
*    - Struct SaleInfo: Details for a property listed for sale.
*    - Struct ManagementDelegation: Details for management rights delegation.
*    - Struct TimedAccess: Details for temporary access grants.
*    - Struct StructureType: Defines administrative presets for structures.
*    - _properties: Mapping from tokenId to PropertyData.
*    - _propertyLocationToId: Mapping from unique location identifier to tokenId (ensures unique locations).
*    - _structureTypes: Mapping from structureTypeId to StructureType.
*    - _nextTokenId: Counter for minting new property NFTs.
*    - _nextStructureTypeId: Counter for registering structure types.
*    - _baseTokenURI: Base URI for metadata.
*
* II. Events
*    - Signaling key actions like minting, updates, state changes, listings, delegations, permits, etc.
*
* III. Modifiers
*    - Restricting function access based on ownership, delegation, or admin status, and token existence.
*
* IV. Constructor
*    - Initializes the contract with a name and symbol, and sets the deployer as owner (admin).
*
* V. Admin Functions (onlyOwner)
*    1. mintProperty: Mints a new property NFT at a unique location with initial data.
*    2. burnProperty: Destroys a property NFT.
*    3. setBaseTokenURI: Sets the base URI for token metadata.
*    4. grantBuildPermit: Grants a building permit flag for a specific property.
*    5. revokeBuildPermit: Revokes a building permit flag.
*    6. registerStructureType: Defines a new type of structure with required features.
*    7. setRequiredFeaturesForStructureType: Updates required features for an existing structure type.
*
* VI. Owner/Delegate Functions (onlyPropertyOwner or delegated manager)
*    8. updatePropertyDescription: Sets or updates the description of a property.
*    9. addPropertyFeature: Adds a specific feature (string) to a property's features list.
*   10. removePropertyFeature: Removes a specific feature from a property's features list.
*   11. setPropertyState: Updates the PropertyState enum value.
*   12. listPropertyForRent: Marks a property as available for rent with terms.
*   13. cancelRentalListing: Removes a property from the rental listing.
*   14. listForSale: Marks a property as available for sale with a price.
*   15. cancelSaleListing: Removes a property from the sale listing.
*   16. setProsperityScore: Updates the dynamic prosperity score (also callable by Admin).
*   17. attachExternalDataHash: Attaches a content hash linking to off-chain data.
*   18. updateDevelopmentStatus: Sets the development progress percentage.
*   19. assignStructureType: Links a property to a registered structure type.
*   20. grantTimedAccess: Grants temporary access rights to a third party for a specific purpose.
*   21. revokeTimedAccess: Revokes a specific timed access grant.
*   22. setPropertyTheme: Sets a visual theme string for the property.
*
* VII. Owner Only Functions (onlyPropertyOwner)
*   23. delegateManagement: Designates an address to manage the property (call certain owner/delegate functions).
*   24. revokeManagement: Removes a delegated manager.
*   25. updateTokenURI: Sets the full token URI for a specific property (overrides base URI).
*
* VIII. Public Functions
*   26. rentProperty: Allows a user to rent a property if listed (assumes external payment).
*   27. endRental: Allows the renter or owner to end an active rental.
*   28. buyProperty: Allows a user to buy a property if listed (assumes external payment, handles transfer).
*
* IX. View Functions (Read-only, no gas cost)
*   29. getPropertyData: Retrieves all data for a specific property.
*   30. isLocationOccupied: Checks if a location is already taken by a property.
*   31. getDelegatedManager: Gets the address of the current delegated manager for a property.
*   32. hasBuildPermit: Checks if a property has a build permit.
*   33. getAssignedStructureType: Gets the ID of the structure type assigned to a property.
*   34. getStructureTypeData: Retrieves data for a registered structure type.
*   35. getTimedAccessInfo: Retrieves details for a specific timed access grant on a property.
*   36. getPropertyTheme: Gets the theme string for a property.
*   37. meetsDevelopmentCriteria: Checks if a property's features match the required features for its assigned structure type.
*   38. getAllStructureTypeIds: Gets a list of all registered structure type IDs. (Note: Iteration is gas-intensive for large lists if not careful. This version is simple and fine for moderate numbers).
*
* X. Inherited ERC721 Functions (Standard NFT functionality)
*    - ownerOf, balanceOf, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, tokenURI, supportsInterface, name, symbol, totalSupply.
*    - Some might be overridden (e.g., tokenURI) or extended by custom logic (e.g., _beforeTokenTransfer).
*/

contract MetaversePropertyRegistry is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    Counters.Counter private _nextStructureTypeId;

    // I. State Definitions
    enum PropertyState { Empty, Developed, ForRent, Rented, ForSale }

    struct RentalInfo {
        address renter;
        uint64 expiry; // Timestamp when rental ends
        uint256 pricePerDuration; // Price listed (info only, payment assumed external)
        uint64 duration; // Duration unit listed (e.g., seconds, days)
    }

    struct SaleInfo {
        bool isListed;
        uint256 price; // Price listed (info only, payment assumed external)
    }

    struct ManagementDelegation {
        address manager;
        bool active;
    }

    struct TimedAccess {
        uint64 expiry; // Timestamp when access expires
        string purpose; // Reason/scope of access (e.g., "decorate", "host_event")
    }

    struct PropertyData {
        uint256 location; // Unique identifier for location in the metaverse (e.g., encoded coordinates, zone ID)
        string description;
        string[] features; // List of string features (e.g., "pool", "garden", "ocean view")
        PropertyState state;
        uint8 developmentStatus; // Percentage 0-100
        uint prosperityScore; // Dynamic score, can be updated
        bytes32 externalDataHash; // Hash linking to off-chain data (e.g., complex 3D model info)
        bool hasBuildPermit; // Flag for building permission
        uint256 assignedStructureType; // ID linking to a registered StructureType (0 if none)
        string theme; // Visual theme identifier

        // Nested structs for conditional states
        RentalInfo rentalInfo;
        SaleInfo saleInfo;
        ManagementDelegation managementDelegation;
        mapping(address => TimedAccess) timedAccess; // Timed access grants per address
    }

    struct StructureType {
        string name;
        string description;
        string[] requiredFeatures; // Features required for a property to meet this type's criteria
    }

    mapping(uint256 => PropertyData) private _properties;
    mapping(uint256 => uint256) private _propertyLocationToId; // Maps location hash/id to tokenId (0 if unoccupied)
    mapping(uint256 => StructureType) private _structureTypes;

    uint256[] private _structureTypeIds; // To keep track of registered structure types (for view function)

    string private _baseTokenURI;

    // II. Events
    event PropertyMinted(address indexed owner, uint256 indexed tokenId, uint256 indexed location);
    event PropertyDescriptionUpdated(uint256 indexed tokenId, string newDescription);
    event PropertyFeatureAdded(uint256 indexed tokenId, string feature);
    event PropertyFeatureRemoved(uint256 indexed tokenId, string feature);
    event PropertyStateChanged(uint256 indexed tokenId, PropertyState newState);
    event PropertyListedForRent(uint256 indexed tokenId, uint256 pricePerDuration, uint64 duration);
    event PropertyRented(uint256 indexed tokenId, address indexed renter, uint64 expiry);
    event RentalEnded(uint256 indexed tokenId, address indexed renter);
    event RentalListingCancelled(uint256 indexed tokenId);
    event PropertyListedForSale(uint256 indexed tokenId, uint256 price);
    event SaleListingCancelled(uint256 indexed tokenId);
    event PropertySold(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner, uint256 price);
    event ManagementDelegated(uint256 indexed tokenId, address indexed delegate);
    event ManagementRevoked(uint256 indexed tokenId);
    event ProsperityScoreUpdated(uint256 indexed tokenId, uint newScore);
    event ExternalDataHashAttached(uint256 indexed tokenId, bytes32 dataHash);
    event DevelopmentStatusUpdated(uint256 indexed tokenId, uint8 newStatus);
    event BuildPermitGranted(uint256 indexed tokenId);
    event BuildPermitRevoked(uint256 indexed tokenId);
    event StructureTypeRegistered(uint256 indexed structureTypeId, string name);
    event StructureTypeAssigned(uint256 indexed tokenId, uint256 indexed structureTypeId);
    event TimedAccessGranted(uint256 indexed tokenId, address indexed grantee, uint64 expiry, string purpose);
    event TimedAccessRevoked(uint256 indexed tokenId, address indexed grantee);
    event PropertyThemeUpdated(uint256 indexed tokenId, string theme);

    // III. Modifiers
    modifier whenPropertyExists(uint256 tokenId) {
        require(_exists(tokenId), "MVP: Property does not exist");
        _;
    }

    modifier onlyPropertyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "MVP: Caller is not property owner");
        _;
    }

    modifier onlyPropertyOwnerOrDelegate(uint256 tokenId) {
        address currentOwner = ownerOf(tokenId);
        PropertyData storage property = _properties[tokenId];
        require(currentOwner == msg.sender || (property.managementDelegation.active && property.managementDelegation.manager == msg.sender), "MVP: Caller is not owner or authorized delegate");
        _;
    }

    modifier onlyPropertyOwnerOrDelegateOrAdmin(uint255 tokenId) {
        address currentOwner = ownerOf(tokenId);
        PropertyData storage property = _properties[tokenId];
        require(currentOwner == msg.sender || property.managementDelegation.active && property.managementDelegation.manager == msg.sender || owner() == msg.sender, "MVP: Caller is not owner, delegate, or admin");
        _;
    }

    modifier onlyPropertyOwnerOrAdmin(uint256 tokenId) {
         require(ownerOf(tokenId) == msg.sender || owner() == msg.sender, "MVP: Caller is not owner or admin");
         _;
    }

    // IV. Constructor
    constructor() ERC721("Metaverse Property", "MVP") Ownable(msg.sender) {}

    // V. Admin Functions (onlyOwner)

    /**
     * @notice Mints a new property NFT at a specified unique location.
     * @dev Callable only by the contract owner. Location must be unique.
     * @param to The address to mint the property to.
     * @param location The unique identifier for the property's location.
     * @param description Initial description of the property.
     */
    function mintProperty(address to, uint256 location, string memory description) public onlyOwner {
        require(location != 0, "MVP: Location cannot be zero");
        require(_propertyLocationToId[location] == 0, "MVP: Location is already occupied");

        _nextTokenId.increment();
        uint256 newTokenId = _nextTokenId.current();

        _properties[newTokenId].location = location;
        _properties[newTokenId].description = description;
        _properties[newTokenId].state = PropertyState.Empty;
        _properties[newTokenId].developmentStatus = 0;
        _properties[newTokenId].prosperityScore = 0;
        _properties[newTokenId].assignedStructureType = 0;
        _properties[newTokenId].hasBuildPermit = false;
        _properties[newTokenId].managementDelegation.active = false;
        _properties[newTokenId].saleInfo.isListed = false;

        _safeMint(to, newTokenId);
        _propertyLocationToId[location] = newTokenId;

        emit PropertyMinted(to, newTokenId, location);
    }

     /**
     * @notice Burns a property NFT.
     * @dev Callable only by the contract owner (admin). Removes the property from existence.
     * @param tokenId The ID of the property to burn.
     */
    function burnProperty(uint256 tokenId) public onlyOwner whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(ownerOf(tokenId) != address(0), "MVP: Property must be owned to be burned"); // Double check exists

        _propertyLocationToId[property.location] = 0; // Free up the location

        delete _properties[tokenId]; // Clear property data

        _burn(tokenId); // Burn the NFT

        // Event is emitted by ERC721 _burn hook
    }

    /**
     * @notice Sets the base URI for token metadata.
     * @dev Callable only by the contract owner. Used by tokenURI if property-specific URI is not set.
     * @param baseUri The base URI string.
     */
    function setBaseTokenURI(string memory baseUri) public onlyOwner {
        _baseTokenURI = baseUri;
    }

    /**
     * @notice Grants a building permit for a specific property.
     * @dev Callable only by the contract owner.
     * @param tokenId The ID of the property to grant the permit to.
     */
    function grantBuildPermit(uint256 tokenId) public onlyOwner whenPropertyExists(tokenId) {
        _properties[tokenId].hasBuildPermit = true;
        emit BuildPermitGranted(tokenId);
    }

    /**
     * @notice Revokes a building permit for a specific property.
     * @dev Callable only by the contract owner.
     * @param tokenId The ID of the property to revoke the permit from.
     */
    function revokeBuildPermit(uint256 tokenId) public onlyOwner whenPropertyExists(tokenId) {
        _properties[tokenId].hasBuildPermit = false;
        emit BuildPermitRevoked(tokenId);
    }

    /**
     * @notice Registers a new type of structure with required features for development criteria.
     * @dev Callable only by the contract owner. Returns the new structure type ID.
     * @param name The name of the structure type (e.g., "House", "Shop", "Park").
     * @param description A description of the structure type.
     * @param requiredFeatures Features a property must have to meet this type's criteria.
     * @return The ID of the newly registered structure type.
     */
    function registerStructureType(string memory name, string memory description, string[] memory requiredFeatures) public onlyOwner returns (uint256) {
        _nextStructureTypeId.increment();
        uint256 newTypeId = _nextStructureTypeId.current();

        _structureTypes[newTypeId] = StructureType(name, description, requiredFeatures);
        _structureTypeIds.push(newTypeId); // Add to array for enumeration

        emit StructureTypeRegistered(newTypeId, name);
        return newTypeId;
    }

     /**
     * @notice Updates the required features for an existing structure type.
     * @dev Callable only by the contract owner.
     * @param structureTypeId The ID of the structure type to update.
     * @param newRequiredFeatures The new list of required features.
     */
    function setRequiredFeaturesForStructureType(uint256 structureTypeId, string[] memory newRequiredFeatures) public onlyOwner {
        require(structureTypeId > 0 && structureTypeId <= _nextStructureTypeId.current(), "MVP: Invalid structure type ID");
        _structureTypes[structureTypeId].requiredFeatures = newRequiredFeatures;
        // Consider adding an event here if needed
    }


    // VI. Owner/Delegate Functions (onlyPropertyOwnerOrDelegate)

    /**
     * @notice Updates the description for a property.
     * @dev Callable by the property owner or their delegated manager.
     * @param tokenId The ID of the property.
     * @param description The new description string.
     */
    function updatePropertyDescription(uint256 tokenId, string memory description) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].description = description;
        emit PropertyDescriptionUpdated(tokenId, description);
    }

    /**
     * @notice Adds a feature to a property's features list.
     * @dev Callable by the property owner or their delegated manager. Only adds if the feature is not already present.
     * @param tokenId The ID of the property.
     * @param feature The feature string to add.
     */
    function addPropertyFeature(uint256 tokenId, string memory feature) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        // Check if feature already exists (simple iteration, okay for small arrays)
        for (uint i = 0; i < property.features.length; i++) {
            if (keccak256(bytes(property.features[i])) == keccak256(bytes(feature))) {
                return; // Feature already exists
            }
        }
        property.features.push(feature);
        emit PropertyFeatureAdded(tokenId, feature);
    }

    /**
     * @notice Removes a feature from a property's features list.
     * @dev Callable by the property owner or their delegated manager.
     * @param tokenId The ID of the property.
     * @param feature The feature string to remove.
     */
    function removePropertyFeature(uint256 tokenId, string memory feature) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        for (uint i = 0; i < property.features.length; i++) {
            if (keccak256(bytes(property.features[i])) == keccak256(bytes(feature))) {
                // Swap with last element and pop
                property.features[i] = property.features[property.features.length - 1];
                property.features.pop();
                emit PropertyFeatureRemoved(tokenId, feature);
                return;
            }
        }
        // Feature not found, do nothing
    }

    /**
     * @notice Updates the state of a property (e.g., Empty, Developed, ForRent).
     * @dev Callable by the property owner or their delegated manager. Specific transitions may be enforced (not implemented here for flexibility).
     * @param tokenId The ID of the property.
     * @param newState The new PropertyState value.
     */
    function setPropertyState(uint256 tokenId, PropertyState newState) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].state = newState;
        // Reset related listing/rental info if state changes
        if (newState != PropertyState.ForRent && newState != PropertyState.Rented) {
            delete _properties[tokenId].rentalInfo;
        }
         if (newState != PropertyState.ForSale) {
            _properties[tokenId].saleInfo.isListed = false;
             _properties[tokenId].saleInfo.price = 0; // Reset price
        }
        emit PropertyStateChanged(tokenId, newState);
    }

    /**
     * @notice Lists a property as available for rent.
     * @dev Callable by the property owner or their delegated manager. Changes state to ForRent.
     * Assumes payment and duration are handled externally or by another contract.
     * @param tokenId The ID of the property.
     * @param pricePerDuration The listed price per duration unit (info only).
     * @param duration The duration unit (info only, e.g., 86400 for days).
     */
    function listPropertyForRent(uint256 tokenId, uint256 pricePerDuration, uint64 duration) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state != PropertyState.Rented && property.state != PropertyState.ForSale, "MVP: Property must not be currently rented or for sale to list for rent");

        property.state = PropertyState.ForRent;
        property.rentalInfo.pricePerDuration = pricePerDuration;
        property.rentalInfo.duration = duration;
        property.rentalInfo.renter = address(0); // Clear any old renter info
        property.rentalInfo.expiry = 0;

        emit PropertyListedForRent(tokenId, pricePerDuration, duration);
    }

    /**
     * @notice Cancels the rental listing for a property.
     * @dev Callable by the property owner or their delegated manager. Changes state back to Developed (if previously Developed/Empty).
     * @param tokenId The ID of the property.
     */
    function cancelRentalListing(uint256 tokenId) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state == PropertyState.ForRent, "MVP: Property is not listed for rent");

        // Revert state to Developed if it was Developed or Empty before listing, otherwise handle appropriately
        property.state = PropertyState.Developed; // Or maybe track previous state? Simple: default to Developed.
        delete property.rentalInfo; // Clear rental info

        emit RentalListingCancelled(tokenId);
        emit PropertyStateChanged(tokenId, property.state);
    }

    /**
     * @notice Lists a property as available for sale.
     * @dev Callable by the property owner or their delegated manager. Changes state to ForSale.
     * Assumes payment is handled externally or by another contract.
     * @param tokenId The ID of the property.
     * @param price The listed sale price (info only).
     */
    function listForSale(uint256 tokenId, uint256 price) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state != PropertyState.Rented && property.state != PropertyState.ForRent, "MVP: Property must not be currently rented or for rent to list for sale");

        property.state = PropertyState.ForSale;
        property.saleInfo.isListed = true;
        property.saleInfo.price = price;

        emit PropertyListedForSale(tokenId, price);
    }

    /**
     * @notice Cancels the sale listing for a property.
     * @dev Callable by the property owner or their delegated manager. Changes state back to Developed (if previously Developed/Empty).
     * @param tokenId The ID of the property.
     */
    function cancelSaleListing(uint256 tokenId) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state == PropertyState.ForSale && property.saleInfo.isListed, "MVP: Property is not listed for sale");

         // Revert state to Developed if it was Developed or Empty before listing, otherwise handle appropriately
        property.state = PropertyState.Developed; // Simple: default to Developed.
        property.saleInfo.isListed = false;
        property.saleInfo.price = 0;

        emit SaleListingCancelled(tokenId);
        emit PropertyStateChanged(tokenId, property.state);
    }

    /**
     * @notice Updates the dynamic prosperity score for a property.
     * @dev Callable by the property owner, their delegated manager, or the contract admin.
     * @param tokenId The ID of the property.
     * @param newScore The new prosperity score value.
     */
    function setProsperityScore(uint256 tokenId, uint newScore) public onlyPropertyOwnerOrAdmin(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].prosperityScore = newScore;
        emit ProsperityScoreUpdated(tokenId, newScore);
    }

    /**
     * @notice Attaches a hash to a property's data, linking to off-chain information.
     * @dev Callable by the property owner or their delegated manager. Can be used to point to IPFS CIDs, etc.
     * @param tokenId The ID of the property.
     * @param dataHash The bytes32 hash to attach.
     */
    function attachExternalDataHash(uint256 tokenId, bytes32 dataHash) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].externalDataHash = dataHash;
        emit ExternalDataHashAttached(tokenId, dataHash);
    }

    /**
     * @notice Updates the development status percentage for a property.
     * @dev Callable by the property owner or their delegated manager. Value should be between 0 and 100.
     * @param tokenId The ID of the property.
     * @param newStatus The new development status (0-100).
     */
    function updateDevelopmentStatus(uint256 tokenId, uint8 newStatus) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        require(newStatus <= 100, "MVP: Development status cannot exceed 100");
        _properties[tokenId].developmentStatus = newStatus;
        emit DevelopmentStatusUpdated(tokenId, newStatus);
    }

    /**
     * @notice Assigns a registered structure type to a property.
     * @dev Callable by the property owner or their delegated manager. Requires the structure type ID to exist.
     * @param tokenId The ID of the property.
     * @param structureTypeId The ID of the structure type to assign (0 to unassign).
     */
    function assignStructureType(uint256 tokenId, uint256 structureTypeId) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        if (structureTypeId > 0) {
             require(structureTypeId > 0 && structureTypeId <= _nextStructureTypeId.current(), "MVP: Invalid structure type ID");
             // Optional: require hasBuildPermit? Not enforced here for flexibility.
        }

        _properties[tokenId].assignedStructureType = structureTypeId;
        emit StructureTypeAssigned(tokenId, structureTypeId);
    }

    /**
     * @notice Grants temporary access rights to a specified address for a property.
     * @dev Callable by the property owner or their delegated manager. Allows defining an expiry and purpose.
     * Multiple addresses can have timed access for different purposes.
     * @param tokenId The ID of the property.
     * @param grantee The address to grant access to.
     * @param durationSeconds The duration of access in seconds from now.
     * @param purpose The reason or scope of the timed access.
     */
    function grantTimedAccess(uint256 tokenId, address grantee, uint64 durationSeconds, string memory purpose) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        require(grantee != address(0), "MVP: Grantee cannot be the zero address");
        uint64 expiry = uint64(block.timestamp) + durationSeconds;
        _properties[tokenId].timedAccess[grantee] = TimedAccess(expiry, purpose);
        emit TimedAccessGranted(tokenId, grantee, expiry, purpose);
    }

    /**
     * @notice Revokes a specific timed access grant for an address on a property.
     * @dev Callable by the property owner or their delegated manager.
     * @param tokenId The ID of the property.
     * @param grantee The address whose access to revoke.
     */
    function revokeTimedAccess(uint256 tokenId, address grantee) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
         require(grantee != address(0), "MVP: Grantee cannot be the zero address");
         require(_properties[tokenId].timedAccess[grantee].expiry > block.timestamp, "MVP: Timed access grant does not exist or has already expired"); // Check if there's an active grant

        delete _properties[tokenId].timedAccess[grantee];
        emit TimedAccessRevoked(tokenId, grantee);
    }

     /**
     * @notice Sets the visual theme string for a property.
     * @dev Callable by the property owner or their delegated manager.
     * @param tokenId The ID of the property.
     * @param theme The theme string (e.g., "cyberpunk", "fantasy", "modern").
     */
    function setPropertyTheme(uint256 tokenId, string memory theme) public onlyPropertyOwnerOrDelegate(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].theme = theme;
        emit PropertyThemeUpdated(tokenId, theme);
    }


    // VII. Owner Only Functions (onlyPropertyOwner)

    /**
     * @notice Designates an address as the delegated manager for a property.
     * @dev Callable only by the property owner. The manager can call certain functions on behalf of the owner.
     * Only one manager can be active at a time.
     * @param tokenId The ID of the property.
     * @param delegate The address to delegate management rights to (address(0) to disable).
     */
    function delegateManagement(uint256 tokenId, address delegate) public onlyPropertyOwner(tokenId) whenPropertyExists(tokenId) {
        _properties[tokenId].managementDelegation.manager = delegate;
        _properties[tokenId].managementDelegation.active = (delegate != address(0));
        emit ManagementDelegated(tokenId, delegate);
    }

    /**
     * @notice Revokes the delegated management rights for a property.
     * @dev Callable only by the property owner.
     * @param tokenId The ID of the property.
     */
    function revokeManagement(uint256 tokenId) public onlyPropertyOwner(tokenId) whenPropertyExists(tokenId) {
        require(_properties[tokenId].managementDelegation.active, "MVP: No active management delegation for this property");
        _properties[tokenId].managementDelegation.manager = address(0);
        _properties[tokenId].managementDelegation.active = false;
        emit ManagementRevoked(tokenId);
    }

     /**
     * @notice Sets the token URI for a specific property, overriding the base URI.
     * @dev Callable only by the property owner.
     * @param tokenId The ID of the property.
     * @param tokenURI_ The full URI string for the property's metadata.
     */
    function updateTokenURI(uint256 tokenId, string memory tokenURI_) public onlyPropertyOwner(tokenId) whenPropertyExists(tokenId) {
         _setTokenURI(tokenId, tokenURI_);
         // ERC721 standard does not emit an event for URI update, but we could add one
    }


    // VIII. Public Functions

    /**
     * @notice Allows a user to "rent" a property if it is listed for rent.
     * @dev Callable by any address. Assumes rental payment is handled externally or by another contract.
     * Updates property state and rental info.
     * @param tokenId The ID of the property to rent.
     * @param renter The address who is renting (usually msg.sender).
     * @param durationSeconds The actual duration of the rental in seconds.
     */
    function rentProperty(uint256 tokenId, address renter, uint64 durationSeconds) public whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state == PropertyState.ForRent, "MVP: Property is not listed for rent");
        require(durationSeconds > 0, "MVP: Rental duration must be greater than zero");
        require(renter != address(0), "MVP: Renter cannot be the zero address");

        property.state = PropertyState.Rented;
        property.rentalInfo.renter = renter;
        property.rentalInfo.expiry = uint64(block.timestamp) + durationSeconds;

        // Note: pricePerDuration and duration in rentalInfo remain as listed info, not actual transaction details

        emit PropertyRented(tokenId, renter, property.rentalInfo.expiry);
        emit PropertyStateChanged(tokenId, PropertyState.Rented);
    }

    /**
     * @notice Allows the current renter or the property owner to end a rental early.
     * @dev Callable by the current renter or the property owner. Resets rental state.
     * @param tokenId The ID of the property.
     */
    function endRental(uint256 tokenId) public whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state == PropertyState.Rented, "MVP: Property is not currently rented");

        address currentOwner = ownerOf(tokenId);
        address currentRenter = property.rentalInfo.renter;

        require(msg.sender == currentOwner || msg.sender == currentRenter, "MVP: Caller must be the owner or the current renter");

        address endedRenter = property.rentalInfo.renter; // Store before deleting
        delete property.rentalInfo; // Clear rental info
        property.state = PropertyState.Developed; // Revert state, e.g., to Developed

        emit RentalEnded(tokenId, endedRenter);
        emit PropertyStateChanged(tokenId, PropertyState.Developed);
    }

     /**
     * @notice Allows a user to "buy" a property if it is listed for sale.
     * @dev Callable by any address. Assumes payment is handled externally or by another contract
     * before this function is called. Executes the ownership transfer.
     * @param tokenId The ID of the property to buy.
     * @param buyer The address who is buying (usually msg.sender).
     */
    function buyProperty(uint256 tokenId, address buyer) public whenPropertyExists(tokenId) {
        PropertyData storage property = _properties[tokenId];
        require(property.state == PropertyState.ForSale && property.saleInfo.isListed, "MVP: Property is not listed for sale");
        require(buyer != address(0), "MVP: Buyer cannot be the zero address");
        address currentOwner = ownerOf(tokenId);
        require(currentOwner != address(0), "MVP: Current owner must exist"); // Should always be true if token exists

        // *** IMPORTANT: Payment is assumed to be handled OUTSIDE this contract. ***
        // This function only handles the transfer and state update AFTER payment is verified.

        uint256 listedPrice = property.saleInfo.price; // Get price before state change

        // Update state and clear sale info
        property.state = PropertyState.Developed; // Revert state, e.g., to Developed
        property.saleInfo.isListed = false;
        property.saleInfo.price = 0;

        // Perform the transfer
        // Use _transfer directly as we are managing the process
        _transfer(currentOwner, buyer, tokenId);

        emit PropertySold(tokenId, currentOwner, buyer, listedPrice);
        emit PropertyStateChanged(tokenId, PropertyState.Developed);
    }


    // IX. View Functions (Read-only)

    /**
     * @notice Retrieves all data associated with a specific property.
     * @dev Provides a comprehensive view of the property's state and attributes.
     * @param tokenId The ID of the property.
     * @return A tuple containing all property data fields.
     */
    function getPropertyData(uint256 tokenId)
        public
        view
        whenPropertyExists(tokenId)
        returns (
            uint256 location,
            string memory description,
            string[] memory features,
            PropertyState state,
            uint8 developmentStatus,
            uint prosperityScore,
            bytes32 externalDataHash,
            bool hasBuildPermit,
            uint256 assignedStructureType,
            string memory theme,
            RentalInfo memory rentalInfo,
            SaleInfo memory saleInfo,
            ManagementDelegation memory managementDelegation
            // Note: timedAccess mapping cannot be returned directly
        )
    {
        PropertyData storage property = _properties[tokenId];
        return (
            property.location,
            property.description,
            property.features,
            property.state,
            property.developmentStatus,
            property.prosperityScore,
            property.externalDataHash,
            property.hasBuildPermit,
            property.assignedStructureType,
            property.theme,
            property.rentalInfo,
            property.saleInfo,
            property.managementDelegation
        );
    }

    /**
     * @notice Checks if a specific location in the metaverse is already occupied by a property.
     * @param location The unique location identifier.
     * @return True if a property exists at the location, false otherwise.
     */
    function isLocationOccupied(uint256 location) public view returns (bool) {
        return _propertyLocationToId[location] != 0;
    }

    /**
     * @notice Gets the address of the currently delegated manager for a property.
     * @param tokenId The ID of the property.
     * @return The address of the delegated manager, or address(0) if none or inactive.
     */
    function getDelegatedManager(uint256 tokenId) public view whenPropertyExists(tokenId) returns (address) {
        PropertyData storage property = _properties[tokenId];
        return property.managementDelegation.active ? property.managementDelegation.manager : address(0);
    }

    /**
     * @notice Checks if a property has been granted a build permit.
     * @param tokenId The ID of the property.
     * @return True if the property has a build permit, false otherwise.
     */
    function hasBuildPermit(uint256 tokenId) public view whenPropertyExists(tokenId) returns (bool) {
        return _properties[tokenId].hasBuildPermit;
    }

     /**
     * @notice Gets the ID of the structure type assigned to a property.
     * @param tokenId The ID of the property.
     * @return The assigned structure type ID (0 if none assigned).
     */
    function getAssignedStructureType(uint256 tokenId) public view whenPropertyExists(tokenId) returns (uint256) {
        return _properties[tokenId].assignedStructureType;
    }

    /**
     * @notice Retrieves data for a registered structure type.
     * @param structureTypeId The ID of the structure type.
     * @return A tuple containing the structure type's name, description, and required features.
     */
    function getStructureTypeData(uint256 structureTypeId) public view returns (string memory, string memory, string[] memory) {
         require(structureTypeId > 0 && structureTypeId <= _nextStructureTypeId.current(), "MVP: Invalid structure type ID");
         StructureType storage stype = _structureTypes[structureTypeId];
         return (stype.name, stype.description, stype.requiredFeatures);
    }

    /**
     * @notice Retrieves details for a specific timed access grant on a property.
     * @param tokenId The ID of the property.
     * @param grantee The address whose timed access is being queried.
     * @return A tuple containing the expiry timestamp and purpose string. Expiry will be 0 if no active grant exists for this grantee.
     */
    function getTimedAccessInfo(uint256 tokenId, address grantee) public view whenPropertyExists(tokenId) returns (uint64 expiry, string memory purpose) {
        TimedAccess storage access = _properties[tokenId].timedAccess[grantee];
        // Return grant if still active or just expired, otherwise return empty/zero
        if (access.expiry > block.timestamp) {
             return (access.expiry, access.purpose);
        } else {
             return (0, ""); // Indicate no active grant
        }
    }

     /**
     * @notice Gets the visual theme string for a property.
     * @param tokenId The ID of the property.
     * @return The theme string.
     */
    function getPropertyTheme(uint256 tokenId) public view whenPropertyExists(tokenId) returns (string memory) {
        return _properties[tokenId].theme;
    }

     /**
     * @notice Checks if a property currently possesses all features required by its assigned structure type.
     * @dev Iterates through required features. Gas cost depends on number of required and property features.
     * @param tokenId The ID of the property.
     * @return True if the property has an assigned structure type and contains all its required features, false otherwise.
     */
    function meetsDevelopmentCriteria(uint256 tokenId) public view whenPropertyExists(tokenId) returns (bool) {
        PropertyData storage property = _properties[tokenId];
        uint256 structureTypeId = property.assignedStructureType;

        if (structureTypeId == 0) {
            return false; // No structure type assigned, criteria not met
        }

        require(structureTypeId > 0 && structureTypeId <= _nextStructureTypeId.current(), "MVP: Assigned structure type ID is invalid");
        string[] memory requiredFeatures = _structureTypes[structureTypeId].requiredFeatures;
        string[] memory propertyFeatures = property.features;

        if (requiredFeatures.length == 0) {
            return true; // No features required means criteria is met
        }

        // Check if ALL required features are present in property features
        for (uint i = 0; i < requiredFeatures.length; i++) {
            bool found = false;
            for (uint j = 0; j < propertyFeatures.length; j++) {
                if (keccak256(bytes(requiredFeatures[i])) == keccak256(bytes(propertyFeatures[j]))) {
                    found = true;
                    break; // Found required feature, move to next
                }
            }
            if (!found) {
                return false; // A required feature was not found
            }
        }

        return true; // All required features were found
    }

    /**
     * @notice Gets a list of all registered structure type IDs.
     * @dev Note: For a very large number of structure types, this function may exceed gas limits.
     * @return An array of all registered structure type IDs.
     */
    function getAllStructureTypeIds() public view returns (uint256[] memory) {
        return _structureTypeIds;
    }


    // X. Inherited ERC721 Functions

    /**
     * @dev See {ERC721-tokenURI}.
     * Overridden to include base URI logic and potential dynamic data lookup.
     */
    function tokenURI(uint256 tokenId) public view override whenPropertyExists(tokenId) returns (string memory) {
        // Check if a specific token URI is set (using _tokenURIs mapping from ERC721)
        string memory _tokenURI = super.tokenURI(tokenId);

        if (bytes(_tokenURI).length == 0) {
            // If no specific URI, use the base URI + token ID
             if (bytes(_baseTokenURI).length == 0) {
                 return ""; // No base URI set either
             }
             // Conventionally, token URI is baseURI/tokenId
             return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));

            // Alternative: use baseURI + tokenId + ".json" or point to an API gateway
            // return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json"));
            // return string(abi.encodePacked(_baseTokenURI, "api/metadata/", Strings.toString(tokenId)));

             // Note: To make metadata truly dynamic reflecting state (features, score, etc.),
             // the URI should point to an external service (API gateway, decentralized oracle)
             // that queries the contract state and generates the JSON metadata on the fly.
        } else {
            return _tokenURI; // Return the specific URI if set
        }
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     * Hook used to update the location mapping when properties are minted, transferred, or burned.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) {
            // Minting: Location is already set in mintProperty, mapping is updated there.
        } else if (to == address(0)) {
            // Burning: Location mapping is cleared in burnProperty.
        } else {
            // Transferring: No change needed for location mapping, as the location stays with the token.
            // However, if the property was listed for sale or rent, those listings should probably be cancelled on transfer.
             if (_properties[tokenId].state == PropertyState.ForSale || _properties[tokenId].state == PropertyState.ForRent) {
                 _properties[tokenId].state = PropertyState.Developed; // Assume developed state after transfer
                 _properties[tokenId].saleInfo.isListed = false;
                 _properties[tokenId].saleInfo.price = 0;
                 delete _properties[tokenId].rentalInfo;
                 emit PropertyStateChanged(tokenId, PropertyState.Developed);
                 // Note: Events like SaleListingCancelled might also be appropriate here.
             }
             // Also consider clearing management delegation, timed access etc on transfer if desired.
             // Clearing delegation:
             if(_properties[tokenId].managementDelegation.active) {
                 _properties[tokenId].managementDelegation.active = false;
                 _properties[tokenId].managementDelegation.manager = address(0);
                 emit ManagementRevoked(tokenId);
             }
             // Clearing timed access grants: (Gas intensive if many grants)
             // A safer pattern might be to make TimedAccess checks verify msg.sender is current owner if expiry is in the future.
             // For simplicity here, we won't iterate and clear all timed access grants on transfer.

        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Add other interface IDs if implemented (e.g., ERC2981 Royalties)
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId // If Enumerable extension is used
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // Note: Other standard ERC721 functions (ownerOf, balanceOf, transferFrom, etc.) are inherited directly from OpenZeppelin.
    // totalSupply is also inherited if using the ERC721Enumerable extension, or can be added using Counters.

    // Using Counters for total supply tracking if not using Enumerable
    // function totalSupply() public view override returns (uint256) {
    //     return _nextTokenId.current();
    // }

}
```