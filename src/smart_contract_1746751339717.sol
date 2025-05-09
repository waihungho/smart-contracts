Okay, let's create a smart contract concept that's a bit more involved than a standard token or NFT marketplace. We'll build a "Dimensional Marketplace" where unique assets ("Artifacts") exist within different "Dimensions," and moving/interacting with them requires "Energy," which is also managed within the contract. We'll incorporate dynamic properties for artifacts, dimension-specific rules and governance, and a custom marketplace tailored to this dimensional system.

This avoids duplicating standard ERC-20/721/1155 or simple marketplace contracts by adding interconnected mechanics like dimensions, energy costs, and property dynamics.

---

**Smart Contract: DimensionalMarketplace**

**Concept:** A marketplace for unique digital "Artifacts" that reside in different "Dimensions." Interacting with artifacts (minting, moving dimensions, rerolling properties) requires "Energy," a resource managed by the contract. Dimensions have adjustable parameters (like energy costs) influenced by designated governors. The marketplace allows trading these dimensional artifacts.

**Outline:**

1.  **State Variables:** Define core data structures (Artifact, Dimension, Listing, Proposal) and mappings for tracking artifacts, owners, dimensions, energy balances, marketplace listings, and governance proposals.
2.  **Events:** Define events to log key actions.
3.  **Errors:** Define custom errors for clearer failure reasons.
4.  **Modifiers:** Custom modifiers for access control and state checks.
5.  **Constructor:** Initialize the contract, set owner, create initial dimension.
6.  **Access Control/Pausable:** Standard owner functions and pausing mechanism.
7.  **Energy Management:** Functions to acquire and check energy.
8.  **Dimension Management:** Functions to create, view, and manage dimension parameters and governors.
9.  **Artifact Management (Core Logic):** Functions to mint, transfer, and view artifact details, including dimension location. Includes minimal ERC721-like functions for marketplace compatibility.
10. **Inter-Dimensional Mechanics:** Function to move artifacts between dimensions, consuming energy.
11. **Artifact Property Dynamics:** Functions to view and potentially re-roll artifact properties based on state.
12. **Marketplace:** Functions to list, cancel listings, and buy artifacts, incorporating dimensional aspects and fees.
13. **Dimension Governance (Simplified):** Functions for governors to propose and potentially implement dimension parameter changes (simplified voting or direct governor action).

**Function Summary (aiming for 20+ unique functions):**

1.  `constructor()`: Initializes the contract and creates the genesis dimension.
2.  `pause()`: Pauses critical contract functions (owner only).
3.  `unpause()`: Unpauses the contract (owner only).
4.  `withdrawFees()`: Allows owner to withdraw collected marketplace fees.
5.  `addDimensionGovernor(uint256 _dimensionId, address _governor)`: Adds a governor for a specific dimension (owner only).
6.  `removeDimensionGovernor(uint256 _dimensionId, address _governor)`: Removes a governor for a specific dimension (owner only).
7.  `isDimensionGovernor(uint256 _dimensionId, address _addr) view`: Checks if an address is a governor for a dimension.
8.  `faucetEnergy(uint256 _amount)`: Allows users to acquire energy (utility/testing function, maybe capped).
9.  `getUserEnergy(address _user) view`: Gets the energy balance of a user.
10. `createDimension(string memory _name, uint256 _energyCostMultiplier)`: Creates a new dimension (owner or authorized address).
11. `getDimensionDetails(uint256 _dimensionId) view`: Gets details about a dimension.
12. `setDimensionEnergyMultiplier(uint256 _dimensionId, uint256 _newMultiplier)`: Sets the energy cost multiplier for a dimension (dimension governor only).
13. `mintArtifact(uint256 _initialDimensionId, uint256 _creationSeed)`: Mints a new artifact into a specified dimension, consuming energy.
14. `getArtifactDetails(uint256 _artifactId) view`: Gets details about an artifact (owner, dimension, properties, seed).
15. `ownerOf(uint256 _artifactId) view`: Gets the owner of an artifact (ERC721-like).
16. `balanceOf(address _owner) view`: Gets the number of artifacts owned by an address (ERC721-like).
17. `approve(address _to, uint256 _artifactId)`: Approves an address to transfer a specific artifact (ERC721-like).
18. `setApprovalForAll(address _operator, bool _approved)`: Approves/unapproves an operator for all owner's artifacts (ERC721-like).
19. `getApproved(uint256 _artifactId) view`: Gets the approved address for an artifact (ERC721-like).
20. `isApprovedForAll(address _owner, address _operator) view`: Checks if an operator is approved for all artifacts (ERC721-like).
21. `moveArtifactToDimension(uint256 _artifactId, uint256 _targetDimensionId)`: Moves an artifact the caller owns to a different dimension, consuming energy based on dimension multipliers.
22. `getArtifactMoveCost(uint256 _artifactId, uint256 _targetDimensionId) view`: Calculates the energy cost to move an artifact between dimensions.
23. `reRollArtifactProperties(uint256 _artifactId, bytes32 _additionalEntropy)`: Consumes energy to potentially reroll dynamic properties of an artifact based on its seed, current dimension, and entropy.
24. `getArtifactDynamicProperties(uint256 _artifactId) view`: Gets the current dynamic properties of an artifact.
25. `listArtifactForSale(uint256 _artifactId, uint256 _price, uint256 _destinationDimensionId)`: Lists an artifact for sale in the marketplace, specifying price and the dimension the buyer will receive it in.
26. `cancelListing(uint256 _listingId)`: Cancels an active marketplace listing.
27. `buyArtifact(uint256 _listingId) payable`: Buys a listed artifact. Transfers payment (including fee), moves artifact to specified destination dimension (consuming buyer's energy), and updates state.
28. `getListingDetails(uint256 _listingId) view`: Gets details about a specific marketplace listing.
29. `getArtifactListing(uint256 _artifactId) view`: Gets the active listing ID for an artifact, if any.
30. `getActiveListingCount() view`: Gets the total number of active listings.
31. `getActiveListingIdAtIndex(uint256 _index) view`: Gets a listing ID at a specific index of the active listings array (utility for iterating listings).
32. `getArtifactCountInDimension(uint256 _dimensionId) view`: Gets the count of artifacts in a specific dimension.
33. `getArtifactIdInDimensionAtIndex(uint256 _dimensionId, uint256 _index) view`: Gets an artifact ID in a specific dimension at a given index (utility for iterating artifacts in a dimension).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// We are not inheriting full ERC721 to avoid duplicating a standard open-source contract entirely,
// but we are implementing the necessary functions (_transfer, ownerOf, balanceOf, approvals)
// to allow basic compatibility with systems expecting these methods.

/**
 * @title DimensionalMarketplace
 * @dev A smart contract for managing and trading unique digital Artifacts that exist within different Dimensions.
 * Artifacts can be minted, moved between dimensions (consuming Energy), and have dynamic properties.
 * Dimensions have adjustable energy costs and are managed by designated governors.
 * A custom marketplace facilitates trading artifacts, including specifying the target dimension.
 *
 * Outline:
 * 1. State Variables: Structs and mappings for Artifacts, Dimensions, Listings, Energy, Governors.
 * 2. Events: Logging significant actions.
 * 3. Errors: Custom errors for clarity.
 * 4. Modifiers: Access control (Ownable, Pausable, Governor).
 * 5. Constructor: Initializes the contract and genesis dimension.
 * 6. Access Control/Pausable: Owner functions, pause/unpause logic.
 * 7. Energy Management: Faucet for demo/testing, user energy balance check.
 * 8. Dimension Management: Create, view, set parameters, add/remove governors.
 * 9. Artifact Management (Core Logic): Minting, transfers, views (incl. ERC721-like basics).
 * 10. Inter-Dimensional Mechanics: Moving artifacts with energy cost.
 * 11. Artifact Property Dynamics: Viewing and rerolling properties.
 * 12. Marketplace: List, cancel, buy artifacts, with dimensional destination and fees.
 * 13. Utility Views: Get counts and indexed IDs for iteration (Dimensions, Listings, Artifacts in Dimension).
 *
 * Function Summary (33+ functions):
 * - constructor(): Initializes contract, sets owner, creates genesis dimension.
 * - pause(): Owner pauses contract.
 * - unpause(): Owner unpauses contract.
 * - withdrawFees(): Owner withdraws collected marketplace fees.
 * - addDimensionGovernor(uint256 _dimensionId, address _governor): Adds governor to a dimension (owner only).
 * - removeDimensionGovernor(uint256 _dimensionId, address _governor): Removes governor from a dimension (owner only).
 * - isDimensionGovernor(uint256 _dimensionId, address _addr) view: Checks if address is dimension governor.
 * - faucetEnergy(uint256 _amount): Grants energy to caller (utility, capped).
 * - getUserEnergy(address _user) view: Gets user's energy balance.
 * - createDimension(string memory _name, uint256 _energyCostMultiplier): Creates a new dimension (owner or authorized).
 * - getDimensionDetails(uint256 _dimensionId) view: Gets dimension details.
 * - setDimensionEnergyMultiplier(uint256 _dimensionId, uint256 _newMultiplier): Sets dimension energy cost multiplier (governor only).
 * - mintArtifact(uint256 _initialDimensionId, uint256 _creationSeed): Mints artifact, consumes energy.
 * - getArtifactDetails(uint256 _artifactId) view: Gets artifact details.
 * - ownerOf(uint256 _artifactId) view: ERC721-like owner query.
 * - balanceOf(address _owner) view: ERC721-like balance query.
 * - approve(address _to, uint256 _artifactId): ERC721-like approval.
 * - setApprovalForAll(address _operator, bool _approved): ERC721-like operator approval.
 * - getApproved(uint256 _artifactId) view: ERC721-like approved address query.
 * - isApprovedForAll(address _owner, address _operator) view: ERC721-like operator status query.
 * - moveArtifactToDimension(uint256 _artifactId, uint256 _targetDimensionId): Moves artifact, consumes energy.
 * - getArtifactMoveCost(uint256 _artifactId, uint256 _targetDimensionId) view: Calculates move energy cost.
 * - reRollArtifactProperties(uint256 _artifactId, bytes32 _additionalEntropy): Rerolls properties, consumes energy.
 * - getArtifactDynamicProperties(uint256 _artifactId) view: Gets current dynamic properties.
 * - getArtifactSeed(uint256 _artifactId) view: Gets artifact creation seed.
 * - listArtifactForSale(uint256 _artifactId, uint256 _price, uint256 _destinationDimensionId): Lists artifact for sale.
 * - cancelListing(uint256 _listingId): Cancels listing.
 * - buyArtifact(uint256 _listingId) payable: Buys artifact, transfers ETH, moves artifact, applies fee.
 * - getListingDetails(uint256 _listingId) view: Gets listing details.
 * - getArtifactListing(uint256 _artifactId) view: Gets active listing ID for an artifact.
 * - getActiveListingCount() view: Gets count of active listings.
 * - getActiveListingIdAtIndex(uint256 _index) view: Gets active listing ID by index.
 * - getArtifactCountInDimension(uint256 _dimensionId) view: Gets artifact count in a dimension.
 * - getArtifactIdInDimensionAtIndex(uint256 _dimensionId, uint256 _index) view: Gets artifact ID by index in a dimension.
 */
contract DimensionalMarketplace is Ownable, Pausable {

    // --- State Variables ---

    struct Artifact {
        uint256 id;
        address owner; // Redundant with ownerArtifacts mapping, but useful in struct
        uint256 dimensionId;
        uint256 creationSeed; // Immutable seed influencing potential properties
        bytes dynamicProperties; // Example: Could store bytes representing stats, appearance traits, etc.
        uint256 mintedAt;
    }

    struct Dimension {
        uint256 id;
        string name;
        uint256 energyCostMultiplier; // Multiplier for moving *to* this dimension
        address[] governors; // Addresses allowed to propose/enact changes
        uint256[] artifactIds; // List of artifacts currently in this dimension (potentially gas heavy)
    }

    struct Listing {
        uint256 listingId;
        uint256 artifactId;
        address seller;
        uint256 price; // in Wei
        uint256 destinationDimensionId; // Dimension artifact goes to upon purchase
        bool active;
    }

    // Core Mappings
    mapping(uint256 => Artifact) private artifacts;
    mapping(uint256 => address) private artifactOwners; // Artifact ID to owner
    mapping(address => uint256) private ownerArtifactCount; // Owner to count
    mapping(uint256 => address) private artifactApproved; // Artifact ID to approved address (ERC721-like)
    mapping(address => mapping(address => bool)) private ownerOperatorApproved; // Owner to operator approval (ERC721-like)

    mapping(uint256 => Dimension) private dimensions;
    uint256 private nextDimensionId = 1; // Start Dimension IDs from 1

    mapping(address => uint256) private userEnergy;
    uint256 public baseEnergyCostPerMove = 100; // Base cost before dimension multipliers
    uint256 public artifactMintEnergyCost = 500; // Energy cost to mint a new artifact
    uint256 public artifactRerollEnergyCost = 200; // Energy cost to reroll properties

    mapping(uint256 => Listing) private marketplaceListings;
    mapping(uint256 => uint256) private artifactToListing; // Artifact ID to Listing ID (0 if not listed)
    uint256[] private activeListingIds; // Array of active listing IDs (for iteration)
    uint256 private nextListingId = 1; // Start Listing IDs from 1
    uint256 public marketplaceFeePercent = 200; // 2% fee (200 / 10000)
    uint256 constant private FEE_DENOMINATOR = 10000;
    address payable private feeRecipient; // Address to send fees

    uint256 private nextArtifactId = 1; // Start Artifact IDs from 1

    // Max amount allowed by faucet per call
    uint256 public maxFaucetEnergy = 10000;

    // --- Events ---

    event ArtifactMinted(uint256 indexed artifactId, address indexed owner, uint256 indexed dimensionId, uint256 creationSeed);
    event ArtifactTransfer(uint256 indexed artifactId, address indexed from, address indexed to); // ERC721-like
    event Approval(address indexed owner, address indexed approved, uint256 indexed artifactId); // ERC721-like
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // ERC721-like
    event ArtifactDimensionChanged(uint256 indexed artifactId, uint256 indexed fromDimensionId, uint256 indexed toDimensionId, uint256 energyCost);
    event EnergyGranted(address indexed user, uint256 amount);
    event EnergySpent(address indexed user, uint256 amount);
    event DimensionCreated(uint256 indexed dimensionId, string name, uint256 energyCostMultiplier);
    event DimensionMultiplierChanged(uint256 indexed dimensionId, uint256 oldMultiplier, uint256 newMultiplier);
    event DimensionGovernorAdded(uint256 indexed dimensionId, address indexed governor);
    event DimensionGovernorRemoved(uint256 indexed dimensionId, address indexed governor);
    event ArtifactPropertiesRerolled(uint256 indexed artifactId, uint256 energyCost);
    event ListingCreated(uint256 indexed listingId, uint256 indexed artifactId, address indexed seller, uint256 price, uint256 destinationDimensionId);
    event ListingCancelled(uint256 indexed listingId, uint256 indexed artifactId);
    event ArtifactPurchased(uint256 indexed listingId, uint256 indexed artifactId, address indexed buyer, address indexed seller, uint256 price, uint256 feeAmount, uint256 finalPriceToSeller, uint256 moveEnergyCost);

    // --- Errors ---

    error InvalidDimension(uint256 dimensionId);
    error ArtifactNotFound(uint256 artifactId);
    error NotArtifactOwnerOrApproved();
    error NotArtifactOwner();
    error InsufficientEnergy(uint256 required, uint256 available);
    error ArtifactAlreadyExists(uint256 artifactId);
    error DimensionAlreadyExists(uint256 dimensionId); // Should not happen with sequential ID
    error CannotMoveToSameDimension();
    error NotDimensionGovernor(uint256 dimensionId, address caller);
    error ZeroAddress();
    error InvalidPrice();
    error ArtifactAlreadyListed(uint256 artifactId);
    error ListingNotFound(uint256 listingId);
    error ListingNotActive();
    error NotListingSeller();
    error InsufficientPayment(uint256 required, uint256 provided);
    error FeeRecipientNotSet();
    error InvalidIndex();

    // --- Modifiers ---

    modifier isDimensionGovernor(uint256 _dimensionId) {
        bool found = false;
        Dimension storage dim = dimensions[_dimensionId];
        for (uint i = 0; i < dim.governors.length; i++) {
            if (dim.governors[i] == _msgSender()) {
                found = true;
                break;
            }
        }
        if (!found) revert NotDimensionGovernor(_dimensionId, _msgSender());
        _;
    }

    // --- Constructor ---

    constructor(address payable _feeRecipient) Ownable(msg.sender) Pausable(false) {
        if (_feeRecipient == address(0)) revert FeeRecipientNotSet();
        feeRecipient = _feeRecipient;
        _createDimension("Genesis Dimension", 100); // Create initial dimension with ID 1, base multiplier 100 (1x)
    }

    // --- Access Control & Pausable ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance - msg.value; // Avoid sending back incoming payment if called within payable function (shouldn't happen)
        if (balance > 0) {
            feeRecipient.transfer(balance);
        }
    }

    // --- Dimension Governance & Management ---

    function addDimensionGovernor(uint256 _dimensionId, address _governor) external onlyOwner {
        if (_governor == address(0)) revert ZeroAddress();
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) revert InvalidDimension(_dimensionId); // Dimension must exist

        for (uint i = 0; i < dim.governors.length; i++) {
            if (dim.governors[i] == _governor) {
                // Governor already exists
                return;
            }
        }
        dim.governors.push(_governor);
        emit DimensionGovernorAdded(_dimensionId, _governor);
    }

    function removeDimensionGovernor(uint256 _dimensionId, address _governor) external onlyOwner {
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) revert InvalidDimension(_dimensionId);

        for (uint i = 0; i < dim.governors.length; i++) {
            if (dim.governors[i] == _governor) {
                // Remove by swapping with last and popping
                dim.governors[i] = dim.governors[dim.governors.length - 1];
                dim.governors.pop();
                emit DimensionGovernorRemoved(_dimensionId, _governor);
                return;
            }
        }
        // Governor not found, no action needed
    }

    function isDimensionGovernor(uint256 _dimensionId, address _addr) public view returns (bool) {
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) return false; // Dimension must exist
        for (uint i = 0; i < dim.governors.length; i++) {
            if (dim.governors[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function _createDimension(string memory _name, uint256 _energyCostMultiplier) internal {
        uint256 newId = nextDimensionId++;
        dimensions[newId] = Dimension({
            id: newId,
            name: _name,
            energyCostMultiplier: _energyCostMultiplier,
            governors: new address[](0),
            artifactIds: new uint256[](0)
        });
        emit DimensionCreated(newId, _name, _energyCostMultiplier);
    }

    function createDimension(string memory _name, uint256 _energyCostMultiplier) external onlyOwner whenNotPaused {
        // Could add more complex creation rules (e.g., require energy, multi-sig, etc.)
        _createDimension(_name, _energyCostMultiplier);
    }

    function getDimensionDetails(uint256 _dimensionId) external view returns (uint256 id, string memory name, uint256 energyCostMultiplier, address[] memory governors) {
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) revert InvalidDimension(_dimensionId);
        return (dim.id, dim.name, dim.energyCostMultiplier, dim.governors);
    }

    function setDimensionEnergyMultiplier(uint256 _dimensionId, uint256 _newMultiplier) external whenNotPaused isDimensionGovernor(_dimensionId) {
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) revert InvalidDimension(_dimensionId); // Should not happen due to modifier but safety check
        uint256 oldMultiplier = dim.energyCostMultiplier;
        dim.energyCostMultiplier = _newMultiplier;
        emit DimensionMultiplierChanged(_dimensionId, oldMultiplier, _newMultiplier);
    }

    // --- Energy Management ---

    function faucetEnergy(uint256 _amount) external whenNotPaused {
        // Basic faucet for testing/demo. Add more complex energy acquisition if needed.
        uint256 amountToGrant = _amount > maxFaucetEnergy ? maxFaucetEnergy : _amount;
        userEnergy[_msgSender()] += amountToGrant;
        emit EnergyGranted(_msgSender(), amountToGrant);
    }

    function getUserEnergy(address _user) external view returns (uint256) {
        return userEnergy[_user];
    }

    function _spendEnergy(address _user, uint256 _amount) internal {
        if (userEnergy[_user] < _amount) revert InsufficientEnergy(_amount, userEnergy[_user]);
        userEnergy[_user] -= _amount;
        emit EnergySpent(_user, _amount);
    }

    // --- Artifact Management (Core Logic - ERC721-like subset) ---

    function _exists(uint256 _artifactId) internal view returns (bool) {
        return artifactOwners[_artifactId] != address(0);
    }

    function ownerOf(uint256 _artifactId) public view returns (address) {
        address owner = artifactOwners[_artifactId];
        if (owner == address(0)) revert ArtifactNotFound(_artifactId);
        return owner;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        if (_owner == address(0)) revert ZeroAddress();
        return ownerArtifactCount[_owner];
    }

    function _transfer(address _from, address _to, uint256 _artifactId) internal {
        if (_to == address(0)) revert ZeroAddress();
        if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
        if (artifactOwners[_artifactId] != _from) revert NotArtifactOwner(); // Should not happen if called correctly

        // Clear approvals
        uint256 approvedAddress = artifactApproved[_artifactId];
        if (approvedAddress != address(0)) {
            artifactApproved[_artifactId] = address(0);
            emit Approval(_from, address(0), _artifactId);
        }

        // Update counts
        ownerArtifactCount[_from]--;
        ownerArtifactCount[_to]++;

        // Update ownership mapping
        artifactOwners[_artifactId] = _to;
        artifacts[_artifactId].owner = _to; // Update owner in the struct copy

        emit ArtifactTransfer(_artifactId, _from, _to);

        // Update dimension's artifact list - This is gas intensive and error-prone.
        // A better design might not store arrays of artifact IDs directly in dimensions,
        // or require external indexing. For this example, we'll implement the removal
        // and addition, acknowledging its limitations for many artifacts/moves.
        _removeArtifactFromDimensionList(artifacts[_artifactId].dimensionId, _artifactId);
        // Note: Adding to the target dimension list happens *after* the move in moveArtifactToDimension
        // For simple transfers, the artifact stays in the same dimension, so we'd re-add it.
        // However, simple transfers are expected to keep the dimension. Let's keep dimension updates
        // tied *only* to the moveArtifactToDimension function for clarity and gas.
        // This means the `artifactIds` array in the Dimension struct is ONLY updated by `moveArtifactToDimension`.
        // Simple _transfer doesn't change dimension.
    }

    function _mint(address _to, uint256 _artifactId, uint256 _dimensionId, uint256 _creationSeed, bytes memory _dynamicProperties) internal {
        if (_to == address(0)) revert ZeroAddress();
        if (_exists(_artifactId)) revert ArtifactAlreadyExists(_artifactId);
        if (dimensions[_dimensionId].id == 0) revert InvalidDimension(_dimensionId);

        artifacts[_artifactId] = Artifact({
            id: _artifactId,
            owner: _to,
            dimensionId: _dimensionId,
            creationSeed: _creationSeed,
            dynamicProperties: _dynamicProperties,
            mintedAt: block.timestamp
        });
        artifactOwners[_artifactId] = _to;
        ownerArtifactCount[_to]++;

        // Add artifact to the dimension's list
        dimensions[_dimensionId].artifactIds.push(_artifactId);

        emit ArtifactMinted(_artifactId, _to, _dimensionId, _creationSeed);
    }

    function mintArtifact(uint256 _initialDimensionId, uint256 _creationSeed) external whenNotPaused {
        _spendEnergy(_msgSender(), artifactMintEnergyCost);

        uint256 newArtifactId = nextArtifactId++;
        // Initial dynamic properties could be derived from seed, dimension, or random
        bytes memory initialProperties = abi.encodePacked("InitialProps-Dim", _initialDimensionId, "Seed", _creationSeed);
        _mint(_msgSender(), newArtifactId, _initialDimensionId, _creationSeed, initialProperties);
    }

    function getArtifactDetails(uint256 _artifactId) external view returns (uint256 id, address owner, uint256 dimensionId, uint256 creationSeed, bytes memory dynamicProperties, uint256 mintedAt) {
        if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
        Artifact storage art = artifacts[_artifactId];
        return (art.id, art.owner, art.dimensionId, art.creationSeed, art.dynamicProperties, art.mintedAt);
    }

    // ERC721-like Approvals (needed for marketplace logic)

    function approve(address _to, uint256 _artifactId) public whenNotPaused {
        address owner = ownerOf(_artifactId); // Checks existence and gets owner
        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert NotArtifactOwnerOrApproved();
        }
        if (_to == owner) revert ZeroAddress(); // Cannot approve self

        artifactApproved[_artifactId] = _to;
        emit Approval(owner, _to, _artifactId);
    }

    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        if (_operator == _msgSender()) revert ZeroAddress(); // Cannot approve self as operator
        ownerOperatorApproved[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    function getApproved(uint256 _artifactId) public view returns (address) {
        if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
        return artifactApproved[_artifactId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return ownerOperatorApproved[_owner][_operator];
    }


    // --- Inter-Dimensional Mechanics ---

    function _calculateEnergyCost(uint256 _fromDimensionId, uint256 _toDimensionId) internal view returns (uint256) {
        if (_fromDimensionId == _toDimensionId) return 0; // No cost to stay in same dimension
        Dimension storage fromDim = dimensions[_fromDimensionId];
        Dimension storage toDim = dimensions[_toDimensionId];
        if (fromDim.id == 0) revert InvalidDimension(_fromDimensionId);
        if (toDim.id == 0) revert InvalidDimension(_toDimensionId);

        // Example calculation: Base cost * multiplier of starting dim * multiplier of ending dim (scaled)
        // Using a simple multiplier system. Need to handle potential overflow if multipliers are huge.
        // Let's assume multipliers are reasonable (e.g., 100 = 1x, 200 = 2x, etc., base 100)
        // cost = base * (from.mult / 100) * (to.mult / 100) -> (base * from.mult * to.mult) / 10000
        // Or simpler: base * avg(mult) / 100 -> (base * (from.mult + to.mult) / 2) / 100 -> (base * (from.mult + to.mult)) / 200
        // Let's use a simple additive model for safety: base + (from.mult - 100) + (to.mult - 100), minimum 1
         uint256 cost = baseEnergyCostPerMove;
         if (fromDim.energyCostMultiplier > 100) cost += (fromDim.energyCostMultiplier - 100);
         if (toDim.energyCostMultiplier > 100) cost += (toDim.energyCostMultiplier - 100);
         if (cost == 0) cost = 1; // Minimum cost 1 for cross-dimensional moves

        return cost;
    }

    function getArtifactMoveCost(uint256 _artifactId, uint256 _targetDimensionId) external view returns (uint256) {
        if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
        uint256 currentDimensionId = artifacts[_artifactId].dimensionId;
        return _calculateEnergyCost(currentDimensionId, _targetDimensionId);
    }


    function _removeArtifactFromDimensionList(uint256 _dimensionId, uint256 _artifactId) internal {
         Dimension storage dim = dimensions[_dimensionId];
         if (dim.id == 0) return; // Dimension doesn't exist, nothing to remove

         uint256 artifactIndex = type(uint256).max;
         for (uint i = 0; i < dim.artifactIds.length; i++) {
             if (dim.artifactIds[i] == _artifactId) {
                 artifactIndex = i;
                 break;
             }
         }

         if (artifactIndex != type(uint256).max) {
             // Remove by swapping with last and popping
             dim.artifactIds[artifactIndex] = dim.artifactIds[dim.artifactIds.length - 1];
             dim.artifactIds.pop();
         }
         // If not found, it's an inconsistency, but not a blocker for removal
    }

    function _addArtifactToDimensionList(uint256 _dimensionId, uint256 _artifactId) internal {
         Dimension storage dim = dimensions[_dimensionId];
         if (dim.id == 0) revert InvalidDimension(_dimensionId); // Must add to existing dimension

         // Check if already present (shouldn't be if removed correctly)
         for (uint i = 0; i < dim.artifactIds.length; i++) {
             if (dim.artifactIds[i] == _artifactId) {
                 // Already there, do nothing
                 return;
             }
         }
         dim.artifactIds.push(_artifactId);
    }


    function moveArtifactToDimension(uint256 _artifactId, uint256 _targetDimensionId) external whenNotPaused {
        address owner = ownerOf(_artifactId); // Checks existence and gets owner
        if (owner != _msgSender() && getApproved(_artifactId) != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotArtifactOwnerOrApproved();
        }
        if (_targetDimensionId == artifacts[_artifactId].dimensionId) revert CannotMoveToSameDimension();

        uint256 currentDimensionId = artifacts[_artifactId].dimensionId;
        uint256 cost = _calculateEnergyCost(currentDimensionId, _targetDimensionId);

        _spendEnergy(_msgSender(), cost); // Energy spent by the caller performing the move

        // Update artifact's dimension
        artifacts[_artifactId].dimensionId = _targetDimensionId;

        // Update dimension's artifact lists (this is the gas-heavy part)
        _removeArtifactFromDimensionList(currentDimensionId, _artifactId);
        _addArtifactToDimensionList(_targetDimensionId, _artifactId);


        // Clear approval after move (standard ERC721 behavior for transfers)
        if (getApproved(_artifactId) != address(0)) {
            artifactApproved[_artifactId] = address(0);
            emit Approval(owner, address(0), _artifactId);
        }

        emit ArtifactDimensionChanged(_artifactId, currentDimensionId, _targetDimensionId, cost);
    }

    // --- Artifact Property Dynamics ---

    function reRollArtifactProperties(uint256 _artifactId, bytes32 _additionalEntropy) external whenNotPaused {
        address owner = ownerOf(_artifactId); // Checks existence and gets owner
         if (owner != _msgSender() && getApproved(_artifactId) != _msgSender() && !isApprovedForAll(owner, _msgSender())) {
            revert NotArtifactOwnerOrApproved();
        }

        _spendEnergy(_msgSender(), artifactRerollEnergyCost); // Cost to attempt reroll

        Artifact storage art = artifacts[_artifactId];
        uint256 currentDimensionId = art.dimensionId;
        uint256 seed = art.creationSeed;

        // Simulate property change based on seed, current dimension, block data, and additional entropy
        // In a real application, this logic would be more complex and deterministic,
        // deriving traits from inputs. For this example, we'll just change the bytes
        // based on a hash of inputs.
        bytes32 entropy = keccak256(abi.encodePacked(seed, currentDimensionId, block.timestamp, block.difficulty, block.coinbase, _additionalEntropy));

        // Example: generate a simple property value based on the hash
        uint256 simulatedPower = uint256(entropy) % 1000; // Power between 0 and 999
        uint256 simulatedResistance = uint256(keccak256(abi.encodePacked(entropy, "resistance"))) % 100; // Resistance between 0 and 99

        art.dynamicProperties = abi.encodePacked("Power:", simulatedPower, ",Resistance:", simulatedResistance, ",Entropy:", entropy);

        emit ArtifactPropertiesRerolled(_artifactId, artifactRerollEnergyCost);
    }

    function getArtifactDynamicProperties(uint256 _artifactId) external view returns (bytes memory) {
        if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
        return artifacts[_artifactId].dynamicProperties;
    }

    function getArtifactSeed(uint256 _artifactId) external view returns (uint256) {
         if (!_exists(_artifactId)) revert ArtifactNotFound(_artifactId);
         return artifacts[_artifactId].creationSeed;
    }

    // --- Marketplace ---

    function listArtifactForSale(uint256 _artifactId, uint256 _price, uint256 _destinationDimensionId) external whenNotPaused {
        address owner = ownerOf(_artifactId); // Checks existence and gets owner
        if (owner != _msgSender()) revert NotArtifactOwner();
        if (_price == 0) revert InvalidPrice();
        if (artifactToListing[_artifactId] != 0) revert ArtifactAlreadyListed(_artifactId);
        if (dimensions[_destinationDimensionId].id == 0) revert InvalidDimension(_destinationDimensionId);

        // Transfer artifact to contract first (requires approval)
        // We re-implement a simple transferFrom logic here specific to listing
        // Check approval for the artifact
        address approvedAddress = artifactApproved[_artifactId];
        bool operatorApproved = ownerOperatorApproved[owner][_msgSender()];

        if (approvedAddress != _msgSender() && !operatorApproved) {
             revert NotArtifactOwnerOrApproved(); // Caller must be owner or approved
        }

        // Remove from owner, add to contract (temporarily)
        _transfer(owner, address(this), _artifactId);


        uint256 newListingId = nextListingId++;
        marketplaceListings[newListingId] = Listing({
            listingId: newListingId,
            artifactId: _artifactId,
            seller: owner, // The actual seller is the owner, not necessarily the caller (if operator)
            price: _price,
            destinationDimensionId: _destinationDimensionId,
            active: true
        });

        artifactToListing[_artifactId] = newListingId;
        activeListingIds.push(newListingId); // Add to active listings array

        emit ListingCreated(newListingId, _artifactId, owner, _price, _destinationDimensionId);
    }

     function cancelListing(uint256 _listingId) external whenNotPaused {
        Listing storage listing = marketplaceListings[_listingId];
        if (listing.listingId == 0 || !listing.active) revert ListingNotFound(_listingId);
        if (listing.seller != _msgSender()) revert NotListingSeller();

        // Transfer artifact back to seller
        _transfer(address(this), listing.seller, listing.artifactId);

        // Deactivate listing and clear mapping
        listing.active = false;
        artifactToListing[listing.artifactId] = 0;

        // Remove from active listings array (potentially gas heavy)
        // Find index and swap with last, then pop
        for (uint i = 0; i < activeListingIds.length; i++) {
            if (activeListingIds[i] == _listingId) {
                activeListingIds[i] = activeListingIds[activeListingIds.length - 1];
                activeListingIds.pop();
                break; // Found and removed
            }
        }

        emit ListingCancelled(_listingId, listing.artifactId);
    }

    function buyArtifact(uint256 _listingId) external payable whenNotPaused {
        Listing storage listing = marketplaceListings[_listingId];
        if (listing.listingId == 0 || !listing.active) revert ListingNotFound(_listingId);
        if (msg.value < listing.price) revert InsufficientPayment(listing.price, msg.value);
        if (_msgSender() == listing.seller) revert ZeroAddress(); // Cannot buy your own listing

        uint256 artifactId = listing.artifactId;
        address seller = listing.seller;
        uint256 price = listing.price;
        uint256 destinationDimensionId = listing.destinationDimensionId;

        // Ensure artifact is actually held by the contract for sale
        if (ownerOf(artifactId) != address(this)) {
            // This indicates a major state inconsistency
            revert ListingNotFound(_listingId);
        }

        // Calculate energy cost for moving to destination dimension
        // The artifact is currently in the dimension it was in when listed.
        // Its dimensionId in the Artifact struct is still its original dimension.
        uint256 currentDimensionId = artifacts[artifactId].dimensionId;
        uint256 moveCost = _calculateEnergyCost(currentDimensionId, destinationDimensionId);

        // Check if buyer has enough energy for the move
        _spendEnergy(_msgSender(), moveCost); // Buyer pays energy for the move

        // --- Payment Handling ---
        uint256 feeAmount = (price * marketplaceFeePercent) / FEE_DENOMINATOR;
        uint256 priceToSeller = price - feeAmount;

        // Send ETH to seller
        (bool successSeller, ) = payable(seller).call{value: priceToSeller}("");
        require(successSeller, "Payment to seller failed");

        // Send fee to fee recipient
        (bool successFee, ) = feeRecipient.call{value: feeAmount}("");
        require(successFee, "Fee payment failed");

        // Handle any leftover change
        uint256 refund = msg.value - price;
        if (refund > 0) {
             (bool successRefund, ) = payable(_msgSender()).call{value: refund}("");
             require(successRefund, "Refund failed");
        }
         // --- End Payment Handling ---


        // --- Artifact Transfer & Dimension Change ---
        // Transfer artifact from contract to buyer
        // This internal transfer *doesn't* update dimension list arrays
        _transfer(address(this), _msgSender(), artifactId);

        // Explicitly update artifact's dimension ID
        artifacts[artifactId].dimensionId = destinationDimensionId;

        // Update dimension's artifact lists
        _removeArtifactFromDimensionList(currentDimensionId, artifactId); // Remove from old dimension list
        _addArtifactToDimensionList(destinationDimensionId, artifactId); // Add to new dimension list

        // --- Listing Cleanup ---
        listing.active = false;
        artifactToListing[artifactId] = 0;

        // Remove from active listings array (potentially gas heavy)
         for (uint i = 0; i < activeListingIds.length; i++) {
            if (activeListingIds[i] == _listingId) {
                activeListingIds[i] = activeListingIds[activeListingIds.length - 1];
                activeListingIds.pop();
                break; // Found and removed
            }
        }

        emit ArtifactPurchased(_listingId, artifactId, _msgSender(), seller, price, feeAmount, priceToSeller, moveCost);
        emit ArtifactDimensionChanged(artifactId, currentDimensionId, destinationDimensionId, moveCost); // Also emit dimension change event

    }

    function getListingDetails(uint256 _listingId) external view returns (uint256 listingId, uint256 artifactId, address seller, uint256 price, uint256 destinationDimensionId, bool active) {
        Listing storage listing = marketplaceListings[_listingId];
         if (listing.listingId == 0) revert ListingNotFound(_listingId);
         return (listing.listingId, listing.artifactId, listing.seller, listing.price, listing.destinationDimensionId, listing.active);
    }

    function getArtifactListing(uint256 _artifactId) external view returns (uint256) {
        return artifactToListing[_artifactId]; // Returns 0 if not listed
    }


    // --- Utility View Functions for Iteration ---
    // These functions help external clients iterate through lists but can be gas-heavy for large lists.

    function getActiveListingCount() external view returns (uint256) {
        return activeListingIds.length;
    }

    function getActiveListingIdAtIndex(uint256 _index) external view returns (uint256) {
        if (_index >= activeListingIds.length) revert InvalidIndex();
        return activeListingIds[_index];
    }

    function getDimensionCount() external view returns (uint256) {
        // Note: nextDimensionId is count + 1
        return nextDimensionId - 1;
    }

    function getArtifactCountInDimension(uint256 _dimensionId) external view returns (uint256) {
        Dimension storage dim = dimensions[_dimensionId];
        if (dim.id == 0) revert InvalidDimension(_dimensionId);
        return dim.artifactIds.length;
    }

    function getArtifactIdInDimensionAtIndex(uint256 _dimensionId, uint256 _index) external view returns (uint256) {
         Dimension storage dim = dimensions[_dimensionId];
         if (dim.id == 0) revert InvalidDimension(_dimensionId);
         if (_index >= dim.artifactIds.length) revert InvalidIndex();
         return dim.artifactIds[_index];
    }
}
```