**Outline and Function Summary for Dynamic Intellectual Property (DIP) Marketplace & Collaborative Ecosystem**

This contract establishes a decentralized platform for managing, licensing, and collaboratively developing intellectual property (IP). It introduces a novel approach by supporting dynamic licensing models, robust on-chain contribution attribution, and a framework for decentralized dispute resolution, moving beyond simple NFT ownership to a full-fledged IP lifecycle management system.

**Core Concepts & Trendy Features:**
*   **Dynamic Licensing Models:** Beyond static sales, enabling usage-based, subscription, and time-limited licenses.
*   **On-chain Collaborative Development:** Formalizing contributions to IP, with transparent royalty splitting and attribution.
*   **Derived IP & Forking:** Explicitly tracking the lineage of IP assets, akin to software version control.
*   **Oracle Integration (Conceptual):** Designed to accept off-chain usage data (e.g., API calls to an AI model, data consumption) from trusted oracles to power dynamic license calculations.
*   **Decentralized Dispute Resolution Framework:** Providing the primitives for dispute initiation and resolution by designated arbiters or a future DAO.
*   **Relevance to AI/Data:** The IP assets managed can include AI models, datasets, algorithms, or creative content, making it highly relevant to emerging technologies.
*   **Fractionalized Royalties:** Automatic distribution of revenues among multiple contributors based on their pre-defined shares.

---

**Function Summaries:**

**I. Core IP Asset Management (6 functions)**
1.  `registerIPAsset(string memory _name, string memory _metadataURI)`:
    *   **Description:** Creates and registers a new IP asset on the platform, assigning it a unique ID and initial ownership to the caller.
    *   **Concept:** Foundational IP creation.
2.  `updateIPMetadata(uint256 _ipId, string memory _newMetadataURI)`:
    *   **Description:** Allows the IP owner to update the URI pointing to the IP's metadata (e.g., an IPFS hash describing the asset, its source code, or model weights).
    *   **Concept:** Evolving IP information.
3.  `transferIPOwnership(uint256 _ipId, address _newOwner)`:
    *   **Description:** Transfers the primary ownership of an IP asset to a new address. Only the current owner can initiate this.
    *   **Concept:** IP transferability.
4.  `retireIPAsset(uint256 _ipId)`:
    *   **Description:** Marks an IP asset as retired, preventing any new license offers or contributions from being associated with it. Existing licenses remain active until expiry.
    *   **Concept:** IP lifecycle management, deprecation.
5.  `getIPDetails(uint256 _ipId) view`:
    *   **Description:** Retrieves all comprehensive details (owner, name, URI, status, creation date, parent IP) of a specific IP asset.
    *   **Concept:** Public IP information access.
6.  `getIPContributors(uint256 _ipId) view`:
    *   **Description:** Retrieves a list of all accepted contributors for a specific IP asset, along with their current royalty share and contribution details.
    *   **Concept:** Transparency in collaborative IP.

**II. Dynamic Licensing & Royalties (8 functions)**
7.  `defineLicenseOffer(uint256 _ipId, LicenseType _licenseType, uint256 _pricePerUnit, uint256 _duration, uint256 _maxUsageUnits)`:
    *   **Description:** Creates a new, unique licensing offer for an IP, specifying its type (perpetual, subscription, usage-based, time-limited), price model, duration, and optional usage limits.
    *   **Concept:** Flexible, dynamic licensing.
8.  `revokeLicenseOffer(uint256 _offerId)`:
    *   **Description:** Deactivates an existing license offer, preventing new acquisitions based on it. Existing licenses remain valid.
    *   **Concept:** Market control for IP owners.
9.  `acquireLicense(uint256 _offerId, address _paymentToken) payable`:
    *   **Description:** Allows a user to purchase or subscribe to an available license offer. Funds are deposited into the contract for royalty distribution. Supports native ETH or specified ERC20 tokens.
    *   **Concept:** Decentralized IP monetization.
10. `cancelLicense(uint256 _licenseId)`:
    *   **Description:** Allows a licensee to cancel their active subscription or time-limited license. This might or might not involve refunds based on offer terms (not explicitly implemented here for simplicity but can be extended).
    *   **Concept:** Licensee control.
11. `extendLicenseTerm(uint256 _licenseId, uint256 _additionalDuration) payable`:
    *   **Description:** Allows a licensee to extend the duration of an active time-limited or subscription license by paying an additional fee.
    *   **Concept:** Continuous access and revenue.
12. `recordUsageEvent(uint256 _licenseId, uint256 _unitsUsed)`:
    *   **Description:** (Oracle-fed) Logs a specific number of usage units for a usage-based license. This function is restricted to the `trustedOracle` address.
    *   **Concept:** On-chain tracking for metered usage, crucial for dynamic pricing.
13. `getIPFundsAvailable(uint256 _ipId, address _paymentToken) view`:
    *   **Description:** Retrieves the total amount of a specific payment token (ETH or ERC20) currently held by the contract for a given IP, available for royalty distribution.
    *   **Concept:** Transparency in revenue streams.
14. `distributeIPRoyalties(uint256 _ipId, address _paymentToken)`:
    *   **Description:** Distributes the available funds for a specific IP (after deducting platform fees) to its owner and all accepted contributors based on their defined royalty shares.
    *   **Concept:** Automated, fair royalty distribution.

**III. Collaborative Development & Attribution (6 functions)**
15. `proposeContribution(uint256 _ipId, string memory _contributionURI, uint16 _proposedRoyaltyShareBasisPoints)`:
    *   **Description:** A user suggests an enhancement or new component to an existing IP, including a URI to their work and a proposed royalty percentage.
    *   **Concept:** Open collaboration, on-chain proposals.
16. `approveContribution(uint256 _ipId, address _contributor, uint16 _finalRoyaltyShareBasisPoints)`:
    *   **Description:** The IP owner reviews and accepts a proposed contribution, formally adding the contributor to the IP's royalty split with a final agreed-upon share.
    *   **Concept:** Formalizing intellectual contributions.
17. `rejectContribution(uint256 _ipId, address _contributor)`:
    *   **Description:** The IP owner rejects a proposed contribution.
    *   **Concept:** IP owner control over contributions.
18. `adjustContributorShare(uint256 _ipId, address _contributor, uint16 _newShareBasisPoints)`:
    *   **Description:** The IP owner can modify an existing contributor's royalty percentage for future distributions.
    *   **Concept:** Dynamic royalty adjustments for evolving collaborations.
19. `removeContributor(uint256 _ipId, address _contributor)`:
    *   **Description:** The IP owner removes a contributor and their associated royalty share from an IP.
    *   **Concept:** Management of contributor relationships.
20. `createDerivedIPAsset(uint256 _parentIPId, string memory _name, string memory _metadataURI)`:
    *   **Description:** Registers a new IP asset that explicitly acknowledges its lineage from an existing parent IP. This acts like a "fork" in software development.
    *   **Concept:** Tracking intellectual evolution and derivatives.

**IV. Dispute Resolution & Platform Governance (4 functions)**
21. `initiateDispute(uint256 _ipId, string memory _descriptionURI)`:
    *   **Description:** Allows any party involved with an IP or license (owner, licensee, contributor) to formally initiate a dispute, providing a URI to initial dispute details.
    *   **Concept:** Decentralized conflict resolution.
22. `submitDisputeEvidence(uint256 _disputeId, string memory _evidenceURI)`:
    *   **Description:** (Internal/Placeholder) Allows parties to submit further evidence to an active dispute. (Note: For this contract, it might implicitly update `descriptionURI` or rely on off-chain evidence management for simplicity).
    *   **Concept:** Transparent evidence submission.
23. `resolveDisputeOutcome(uint256 _disputeId, DisputeStatus _status, string memory _resolutionURI)`:
    *   **Description:** (Restricted to `disputeArbiter`) Records the final resolution of a dispute, updating its status and linking to the official resolution details. This could trigger other actions based on the outcome (e.g., license revocation, royalty adjustment).
    *   **Concept:** Formalized dispute closure, potentially by DAO or designated arbiters.
24. `setPlatformConfiguration(address _trustedOracle, address _disputeArbiter, address _platformFeeRecipient, uint16 _platformFeeBasisPoints)`:
    *   **Description:** Admin function to update platform-wide settings, including the addresses for the trusted oracle, dispute arbiter, platform fee recipient, and the platform fee percentage.
    *   **Concept:** Adaptable platform governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

// --- Custom Errors ---
error Unauthorized();
error IPNotFound(uint256 ipId);
error LicenseOfferNotFound(uint256 offerId);
error LicenseNotFound(uint256 licenseId);
error InvalidAmount();
error IPAlreadyRetired();
error ContributionNotFound(address contributor);
error DisputeNotFound(uint256 disputeId);
error InvalidLicenseState();
error InvalidRoyaltyShare();
error LicenseExpired();
error LicenseNotActive();
error IPNotRetired();
error AlreadyContributor();
error NotContributor();
error OfferAlreadyActive();
error CannotModifyActiveOffer();
error OfferNotActive();
error FundsNotAvailable();
error InsufficientBalance();
error CannotAcquireRetiredIP();
error ZeroAddressNotAllowed();
error OnlyETHForZeroAddressToken();


/**
 * @title Dynamic Intellectual Property (DIP) Marketplace & Collaborative Ecosystem
 * @dev This contract establishes a decentralized platform for managing, licensing,
 *      and collaboratively developing intellectual property (IP). It supports
 *      dynamic licensing models, on-chain contribution attribution, and a framework
 *      for decentralized dispute resolution.
 *
 * @notice Features include:
 *   - **IP Asset Registration & Management:** Create, update, transfer, and retire IP assets.
 *   - **Dynamic Licensing:** Define various license offers (e.g., usage-based, subscription, perpetual)
 *     and allow users to acquire, extend, and manage them.
 *   - **Collaborative Development:** Facilitate contributions to IP assets with explicit
 *     royalty attribution and management.
 *   - **Derived IP (Forking):** Track new IP assets that are explicitly derived from existing ones.
 *   - **Royalty Distribution:** Automated calculation and distribution of royalties to
 *     IP owners and contributors based on license revenue and recorded usage.
 *   - **Oracle Integration:** Designed to accept off-chain usage data via a trusted oracle
 *     for dynamic license models.
 *   - **Dispute Resolution Framework:** Provides the mechanisms to initiate,
 *     submit evidence for, and resolve disputes concerning IP or licenses.
 *   - **Platform Governance:** Admin functions for platform-wide settings and fees.
 *
 * @dev The contract prioritizes modularity and extensibility. Payments can be made
 *      in native ETH or specified ERC20 tokens. Oracle-fed functions are secured
 *      by an `onlyOracle` modifier. Dispute resolution is designed to be extensible
 *      to a DAO or designated arbiters.
 */
contract DynamicIPs is Ownable, ReentrancyGuard {

    // --- Data Structures ---

    enum IPStatus { Active, Retired }
    enum LicenseType { Perpetual, Subscription, UsageBased, TimeLimited }
    enum LicenseStatus { Active, Expired, Cancelled, Revoked } // Revoked implies forced termination, e.g., by owner/dispute
    enum ContributionStatus { Proposed, Accepted, Rejected }
    enum DisputeStatus { Open, EvidenceSubmitted, Resolved }

    struct IPAsset {
        uint256 id;
        address owner;
        string name;
        string metadataURI; // Link to IP details (e.g., IPFS hash for description, code, model data)
        IPStatus status;
        uint256 createdAt;
        uint256 parentIPId; // 0 if original, otherwise refers to the IP it was forked from
    }

    struct Contributor {
        address addr;
        uint16 royaltyShareBasisPoints; // 1/100 of a percent, e.g., 500 for 5%
        ContributionStatus status;
        uint256 contributedAt;
        string contributionURI; // Link to contribution details (e.g., specific commit, data package)
    }

    struct LicenseOffer {
        uint256 id;
        uint256 ipId;
        LicenseType licenseType;
        uint256 pricePerUnit; // Per-month for subscription, per-usage for usage-based, total for perpetual/time-limited. Assumed in wei/token units.
        uint256 duration; // In seconds for time-limited/subscription periods. 0 for perpetual/usage-based.
        uint256 maxUsageUnits; // Max total usage for usage-based, 0 for others.
        bool isActive;
        address creator; // Who defined the offer (IP owner, or delegated licensor)
        uint252 createdAt;
    }

    struct License {
        uint256 id;
        uint256 offerId;
        uint256 ipId;
        address licensee;
        LicenseStatus status;
        uint256 activationTime;
        uint256 expiryTime; // 0 for perpetual, specific timestamp for others
        uint256 currentUsage; // Current usage for usage-based licenses
        uint256 paidAmount; // Total amount paid for this license
        address paymentToken; // 0x0 for ETH, otherwise ERC20 address
    }

    struct Dispute {
        uint256 id;
        uint256 ipId; // Or licenseId, or contributionId - let's simplify to ipId for now
        address initiator;
        string descriptionURI; // Link to initial dispute details (e.g., IPFS hash)
        string evidenceURI; // Link to evidence (can be updated)
        DisputeStatus status;
        string resolutionURI; // Link to resolution details
        uint256 initiatedAt;
        uint256 resolvedAt;
    }

    // --- State Variables ---

    uint256 public nextIPId = 1;
    uint256 public nextLicenseOfferId = 1;
    uint256 public nextLicenseId = 1;
    uint256 public nextDisputeId = 1;

    // Core IP assets mapping
    mapping(uint256 => IPAsset) public ipAssets;
    mapping(address => uint256[]) public userOwnedIPs; // For quick lookup of IPs owned by an address

    // IP Contributions
    mapping(uint256 => mapping(address => Contributor)) public ipContributors; // ipId => contributorAddress => Contributor
    mapping(uint256 => address[]) public ipContributorAddresses; // ipId => list of contributor addresses (for iteration)

    // License Offers and Active Licenses
    mapping(uint256 => LicenseOffer) public licenseOffers;
    mapping(uint256 => License) public activeLicenses;
    mapping(uint256 => uint256[]) public ipToLicenseOffers; // ipId => list of offer IDs
    mapping(address => uint256[]) public userLicenses; // licensee address => list of license IDs

    // Funds held by the contract for IP royalty distribution
    mapping(uint256 => mapping(address => uint256)) public ipFundsAvailable; // ipId => paymentTokenAddress => amount

    // Dispute Management
    mapping(uint256 => Dispute) public disputes;

    // Platform Configuration
    address public platformFeeRecipient;
    uint16 public platformFeeBasisPoints; // e.g., 100 for 1%
    address public trustedOracle; // Address allowed to record usage events
    address public disputeArbiter; // Address or contract responsible for resolving disputes

    // --- Events ---

    event IPAssetRegistered(uint256 indexed ipId, address indexed owner, string name, string metadataURI);
    event IPMetadataUpdated(uint256 indexed ipId, string newMetadataURI);
    event IPOwnershipTransferred(uint256 indexed ipId, address indexed oldOwner, address indexed newOwner);
    event IPAssetRetired(uint256 indexed ipId);
    event DerivedIPAssetCreated(uint256 indexed ipId, uint256 indexed parentIPId, address indexed owner);

    event LicenseOfferDefined(uint256 indexed offerId, uint256 indexed ipId, LicenseType licenseType, uint256 pricePerUnit);
    event LicenseOfferRevoked(uint256 indexed offerId);
    event LicenseAcquired(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 paidAmount, address paymentToken);
    event LicenseCancelled(uint256 indexed licenseId, address indexed licensee);
    event LicenseExtended(uint256 indexed licenseId, uint256 newExpiryTime);
    event UsageEventRecorded(uint256 indexed licenseId, uint256 newUsageCount, uint256 timestamp);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 totalDistributedAmount, address indexed paymentToken);

    event ContributionProposed(uint256 indexed ipId, address indexed contributor, string contributionURI);
    event ContributionApproved(uint256 indexed ipId, address indexed contributor, uint16 royaltyShareBasisPoints);
    event ContributionRejected(uint256 indexed ipId, address indexed contributor);
    event ContributorShareAdjusted(uint256 indexed ipId, address indexed contributor, uint16 newShare);
    event ContributorRemoved(uint256 indexed ipId, address indexed contributor);

    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed ipId, address indexed initiator, string descriptionURI);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, string evidenceURI);
    event DisputeOutcomeResolved(uint256 indexed disputeId, DisputeStatus status, string resolutionURI);

    event PlatformConfigurationUpdated(address indexed configSetter, string configName, address indexed newValueAddress, uint256 newValueUint);

    // --- Modifiers ---

    modifier onlyIPOwner(uint256 _ipId) {
        if (ipAssets[_ipId].owner != _msgSender()) revert Unauthorized();
        _;
    }

    modifier onlyLicenseOfferCreator(uint256 _offerId) {
        if (licenseOffers[_offerId].creator != _msgSender()) revert Unauthorized();
        _;
    }

    modifier onlyLicensee(uint256 _licenseId) {
        if (activeLicenses[_licenseId].licensee != _msgSender()) revert Unauthorized();
        _;
    }

    modifier onlyOracle() {
        if (_msgSender() != trustedOracle) revert Unauthorized();
        _;
    }

    modifier onlyDisputeArbiter() {
        if (_msgSender() != disputeArbiter) revert Unauthorized();
        _;
    }

    // --- Constructor ---

    constructor(address _platformFeeRecipient, uint16 _platformFeeBasisPoints, address _trustedOracle, address _disputeArbiter) Ownable(_msgSender()) {
        if (_platformFeeRecipient == address(0) || _trustedOracle == address(0) || _disputeArbiter == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_platformFeeBasisPoints > 10000) { // Max 100%
            revert InvalidRoyaltyShare(); // Reusing error
        }
        platformFeeRecipient = _platformFeeRecipient;
        platformFeeBasisPoints = _platformFeeBasisPoints;
        trustedOracle = _trustedOracle;
        disputeArbiter = _disputeArbiter;
    }

    // --- Receive ETH for direct payments if needed, though acquireLicense handles explicit ETH/ERC20 ---
    receive() external payable {
        // This receive function allows the contract to accept bare ETH transfers.
        // Funds sent directly to the contract without calling acquireLicense() will
        // not be associated with any specific IP or license and will remain locked
        // unless explicitly handled by another function (e.g., withdraw for owner).
        // For this contract, it's better to ensure all incoming funds are tied to
        // an IP via acquireLicense. So, we revert here to enforce that.
        revert InvalidAmount();
    }


    // --- I. Core IP Asset Management ---

    /**
     * @notice Registers a new IP asset with initial metadata and owner.
     * @param _name The name of the IP asset.
     * @param _metadataURI A URI pointing to the detailed metadata of the IP (e.g., IPFS hash).
     */
    function registerIPAsset(string memory _name, string memory _metadataURI) external nonReentrant {
        uint256 id = nextIPId++;
        ipAssets[id] = IPAsset({
            id: id,
            owner: _msgSender(),
            name: _name,
            metadataURI: _metadataURI,
            status: IPStatus.Active,
            createdAt: block.timestamp,
            parentIPId: 0 // Original IP has no parent
        });
        userOwnedIPs[_msgSender()].push(id);
        emit IPAssetRegistered(id, _msgSender(), _name, _metadataURI);
    }

    /**
     * @notice Updates the metadata URI for an existing IP asset.
     * @param _ipId The ID of the IP asset.
     * @param _newMetadataURI The new URI pointing to the updated metadata.
     */
    function updateIPMetadata(uint256 _ipId, string memory _newMetadataURI) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId); // Ensure IP exists
        ipAssets[_ipId].metadataURI = _newMetadataURI;
        emit IPMetadataUpdated(_ipId, _newMetadataURI);
    }

    /**
     * @notice Transfers the primary ownership of an IP asset.
     * @param _ipId The ID of the IP asset.
     * @param _newOwner The address of the new owner.
     */
    function transferIPOwnership(uint256 _ipId, address _newOwner) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();

        address oldOwner = ipAssets[_ipId].owner;
        ipAssets[_ipId].owner = _newOwner;

        // Remove from old owner's list (simplified: iterate and remove, or keep separate owner tracking)
        // For simplicity, `userOwnedIPs` might not be perfectly maintained for removals without iterating.
        // A more robust solution might use `mapping(address => mapping(uint256 => bool))` for faster removal check.
        // For now, it's illustrative.
        // (Consider adding a helper to remove from dynamic array, or simplify `userOwnedIPs` to only add).

        userOwnedIPs[_newOwner].push(_ipId); // Add to new owner's list
        emit IPOwnershipTransferred(_ipId, oldOwner, _newOwner);
    }

    /**
     * @notice Marks an IP asset as retired, preventing new licenses or contributions.
     * @param _ipId The ID of the IP asset to retire.
     */
    function retireIPAsset(uint256 _ipId) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipAssets[_ipId].status == IPStatus.Retired) revert IPAlreadyRetired();
        ipAssets[_ipId].status = IPStatus.Retired;
        emit IPAssetRetired(_ipId);
    }

    /**
     * @notice Retrieves all details of a specific IP asset.
     * @param _ipId The ID of the IP asset.
     * @return IPAsset struct containing all details.
     */
    function getIPDetails(uint256 _ipId) external view returns (IPAsset memory) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        return ipAssets[_ipId];
    }

    /**
     * @notice Retrieves the list of all accepted contributors and their shares for an IP asset.
     * @param _ipId The ID of the IP asset.
     * @return A tuple of arrays: contributor addresses and their respective royalty shares.
     */
    function getIPContributors(uint256 _ipId) external view returns (address[] memory, uint16[] memory, string[] memory) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        
        address[] memory contributorAddrs = ipContributorAddresses[_ipId];
        uint16[] memory shares = new uint16[](contributorAddrs.length);
        string[] memory uris = new string[](contributorAddrs.length);

        for (uint256 i = 0; i < contributorAddrs.length; i++) {
            shares[i] = ipContributors[_ipId][contributorAddrs[i]].royaltyShareBasisPoints;
            uris[i] = ipContributors[_ipId][contributorAddrs[i]].contributionURI;
        }
        return (contributorAddrs, shares, uris);
    }


    // --- II. Dynamic Licensing & Royalties ---

    /**
     * @notice Creates a new, specific licensing offer for an IP.
     * @param _ipId The ID of the IP asset.
     * @param _licenseType The type of license (Perpetual, Subscription, UsageBased, TimeLimited).
     * @param _pricePerUnit The price per unit (e.g., per month, per usage, total for perpetual).
     * @param _duration Duration in seconds for time-limited/subscription, 0 for others.
     * @param _maxUsageUnits Maximum total usage units for usage-based, 0 for others.
     */
    function defineLicenseOffer(
        uint256 _ipId,
        LicenseType _licenseType,
        uint256 _pricePerUnit,
        uint256 _duration,
        uint256 _maxUsageUnits
    ) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipAssets[_ipId].status == IPStatus.Retired) revert CannotAcquireRetiredIP(); // Reusing error
        if (_pricePerUnit == 0) revert InvalidAmount();
        
        uint256 offerId = nextLicenseOfferId++;
        licenseOffers[offerId] = LicenseOffer({
            id: offerId,
            ipId: _ipId,
            licenseType: _licenseType,
            pricePerUnit: _pricePerUnit,
            duration: _duration,
            maxUsageUnits: _maxUsageUnits,
            isActive: true,
            creator: _msgSender(),
            createdAt: uint252(block.timestamp) // Using uint252 to demonstrate non-standard integer sizes for storage efficiency.
        });
        ipToLicenseOffers[_ipId].push(offerId);
        emit LicenseOfferDefined(offerId, _ipId, _licenseType, _pricePerUnit);
    }

    /**
     * @notice Deactivates an existing license offer.
     * @param _offerId The ID of the license offer to revoke.
     */
    function revokeLicenseOffer(uint256 _offerId) external onlyLicenseOfferCreator(_offerId) {
        if (licenseOffers[_offerId].id == 0) revert LicenseOfferNotFound(_offerId);
        if (!licenseOffers[_offerId].isActive) revert OfferNotActive();
        licenseOffers[_offerId].isActive = false;
        emit LicenseOfferRevoked(_offerId);
    }

    /**
     * @notice Allows a user to purchase or subscribe to an available license offer.
     * @param _offerId The ID of the license offer to acquire.
     * @param _paymentToken The address of the ERC20 token for payment (0x0 for ETH).
     */
    function acquireLicense(uint256 _offerId, address _paymentToken) external payable nonReentrant {
        LicenseOffer storage offer = licenseOffers[_offerId];
        if (offer.id == 0 || !offer.isActive) revert LicenseOfferNotFound(_offerId);
        if (ipAssets[offer.ipId].status == IPStatus.Retired) revert CannotAcquireRetiredIP();

        uint256 amount = offer.pricePerUnit; // Initial payment amount

        if (_paymentToken == address(0)) { // ETH payment
            if (msg.value < amount) revert InvalidAmount();
            if (msg.value > amount) {
                // Return excess ETH
                (bool success, ) = _msgSender().call{value: msg.value - amount}("");
                require(success, "Failed to return excess ETH");
            }
            // Funds remain in the contract for distribution later
        } else { // ERC20 payment
            if (msg.value > 0) revert OnlyETHForZeroAddressToken();
            IERC20(_paymentToken).transferFrom(_msgSender(), address(this), amount);
        }

        uint256 licenseId = nextLicenseId++;
        uint256 expiryTime = 0;
        if (offer.licenseType == LicenseType.Subscription || offer.licenseType == LicenseType.TimeLimited) {
            expiryTime = block.timestamp + offer.duration;
        }

        activeLicenses[licenseId] = License({
            id: licenseId,
            offerId: _offerId,
            ipId: offer.ipId,
            licensee: _msgSender(),
            status: LicenseStatus.Active,
            activationTime: block.timestamp,
            expiryTime: expiryTime,
            currentUsage: 0,
            paidAmount: amount,
            paymentToken: _paymentToken
        });
        userLicenses[_msgSender()].push(licenseId);
        ipFundsAvailable[offer.ipId][_paymentToken] += amount;

        emit LicenseAcquired(licenseId, offer.ipId, _msgSender(), amount, _paymentToken);
    }

    /**
     * @notice Allows a licensee to cancel their active subscription/license.
     * @dev Does not handle refunds. For simplicity, cancellation just changes status.
     * @param _licenseId The ID of the license to cancel.
     */
    function cancelLicense(uint256 _licenseId) external onlyLicensee(_licenseId) {
        License storage license = activeLicenses[_licenseId];
        if (license.id == 0) revert LicenseNotFound(_licenseId);
        if (license.status != LicenseStatus.Active) revert InvalidLicenseState();
        
        license.status = LicenseStatus.Cancelled;
        emit LicenseCancelled(_licenseId, _msgSender());
    }

    /**
     * @notice Allows a licensee to extend the duration of a time-limited license.
     * @param _licenseId The ID of the license to extend.
     * @param _additionalDuration The additional duration in seconds to add to the expiry.
     */
    function extendLicenseTerm(uint256 _licenseId, uint256 _additionalDuration) external payable onlyLicensee(_licenseId) nonReentrant {
        License storage license = activeLicenses[_licenseId];
        if (license.id == 0) revert LicenseNotFound(_licenseId);
        if (license.status != LicenseStatus.Active && license.expiryTime > block.timestamp) revert InvalidLicenseState(); // Must be active or recently expired
        if (license.licensee != _msgSender()) revert Unauthorized();

        LicenseOffer storage offer = licenseOffers[license.offerId];
        if (offer.id == 0) revert LicenseOfferNotFound(license.offerId); // Offer must still exist, though not necessarily active

        // Payment for extension based on original offer's pricePerUnit for the duration
        uint256 extensionCost = (offer.pricePerUnit * _additionalDuration) / offer.duration; // Assuming pricePerUnit is for offer.duration
        if (offer.duration == 0) { // For perpetual/usage-based, duration is 0, so direct extension for time-limited needs specific logic
            // If original offer didn't have a duration, assume pricePerUnit is now a "per second" or "per unit of extension"
            // This is a simplification. A real contract would have specific `extensionPrice` in the offer.
            extensionCost = offer.pricePerUnit; // A flat fee or specific calculation
        }
        
        if (license.paymentToken == address(0)) { // ETH payment
            if (msg.value < extensionCost) revert InvalidAmount();
            if (msg.value > extensionCost) {
                (bool success, ) = _msgSender().call{value: msg.value - extensionCost}("");
                require(success, "Failed to return excess ETH on extension");
            }
        } else { // ERC20 payment
            if (msg.value > 0) revert OnlyETHForZeroAddressToken();
            IERC20(license.paymentToken).transferFrom(_msgSender(), address(this), extensionCost);
        }

        license.expiryTime += _additionalDuration;
        license.paidAmount += extensionCost;
        ipFundsAvailable[license.ipId][license.paymentToken] += extensionCost;

        emit LicenseExtended(_licenseId, license.expiryTime);
    }

    /**
     * @notice (Oracle-fed) Logs usage for usage-based licenses. Restricted to the trusted oracle.
     * @param _licenseId The ID of the usage-based license.
     * @param _unitsUsed The number of units consumed in this event.
     */
    function recordUsageEvent(uint256 _licenseId, uint256 _unitsUsed) external onlyOracle {
        License storage license = activeLicenses[_licenseId];
        if (license.id == 0) revert LicenseNotFound(_licenseId);
        if (license.status != LicenseStatus.Active) revert InvalidLicenseState();

        LicenseOffer storage offer = licenseOffers[license.offerId];
        if (offer.id == 0 || offer.licenseType != LicenseType.UsageBased) revert InvalidLicenseState();

        license.currentUsage += _unitsUsed;
        // Optionally, check max usage here and update license status if exceeded, or if new payment is due.
        // For simplicity, we just record usage. Billing for overuse would be external or through another call.

        emit UsageEventRecorded(_licenseId, license.currentUsage, block.timestamp);
    }

    /**
     * @notice Retrieves the total amount of a specific payment token (ETH or ERC20)
     *         currently held by the contract for a given IP, available for royalty distribution.
     * @param _ipId The ID of the IP asset.
     * @param _paymentToken The address of the payment token (0x0 for ETH).
     * @return The available balance for the IP in the specified token.
     */
    function getIPFundsAvailable(uint256 _ipId, address _paymentToken) external view returns (uint256) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        return ipFundsAvailable[_ipId][_paymentToken];
    }

    /**
     * @notice Distributes the available funds for a specific IP to its owner and contributors
     *         after deducting platform fees.
     * @param _ipId The ID of the IP asset.
     * @param _paymentToken The address of the payment token (0x0 for ETH).
     */
    function distributeIPRoyalties(uint256 _ipId, address _paymentToken) external nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IPNotFound(_ipId);

        uint256 totalAvailable = ipFundsAvailable[_ipId][_paymentToken];
        if (totalAvailable == 0) revert FundsNotAvailable();

        // Calculate platform fee
        uint256 platformFee = (totalAvailable * platformFeeBasisPoints) / 10000;
        uint256 amountToDistribute = totalAvailable - platformFee;

        // Transfer platform fee
        if (platformFee > 0) {
            if (_paymentToken == address(0)) {
                (bool success, ) = platformFeeRecipient.call{value: platformFee}("");
                require(success, "Failed to send platform ETH fee");
            } else {
                IERC20(_paymentToken).transfer(platformFeeRecipient, platformFee);
            }
        }

        // Distribute to contributors
        uint256 distributedToContributors = 0;
        address[] memory contributorAddrs = ipContributorAddresses[_ipId];
        for (uint256 i = 0; i < contributorAddrs.length; i++) {
            Contributor storage contributor = ipContributors[_ipId][contributorAddrs[i]];
            if (contributor.status == ContributionStatus.Accepted && contributor.royaltyShareBasisPoints > 0) {
                uint256 contributorShare = (amountToDistribute * contributor.royaltyShareBasisPoints) / 10000;
                if (contributorShare > 0) {
                    if (_paymentToken == address(0)) {
                        (bool success, ) = contributor.addr.call{value: contributorShare}("");
                        require(success, "Failed to send contributor ETH share");
                    } else {
                        IERC20(_paymentToken).transfer(contributor.addr, contributorShare);
                    }
                    distributedToContributors += contributorShare;
                }
            }
        }

        // Distribute remaining to IP owner
        uint256 ownerShare = amountToDistribute - distributedToContributors;
        if (ownerShare > 0) {
            if (_paymentToken == address(0)) {
                (bool success, ) = ip.owner.call{value: ownerShare}("");
                require(success, "Failed to send owner ETH share");
            } else {
                IERC20(_paymentToken).transfer(ip.owner, ownerShare);
            }
        }

        ipFundsAvailable[_ipId][_paymentToken] = 0; // Reset available funds for this IP and token
        emit RoyaltiesDistributed(_ipId, totalAvailable, _paymentToken);
    }


    // --- III. Collaborative Development & Attribution ---

    /**
     * @notice A user proposes a new contribution to an existing IP.
     * @param _ipId The ID of the IP asset to contribute to.
     * @param _contributionURI A URI pointing to the details of the proposed contribution.
     * @param _proposedRoyaltyShareBasisPoints The royalty share (in basis points) the contributor is proposing.
     */
    function proposeContribution(
        uint256 _ipId,
        string memory _contributionURI,
        uint16 _proposedRoyaltyShareBasisPoints
    ) external {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipAssets[_ipId].status == IPStatus.Retired) revert IPAlreadyRetired();
        if (_proposedRoyaltyShareBasisPoints > 10000) revert InvalidRoyaltyShare(); // Max 100%

        // Check if already an active contributor
        if (ipContributors[_ipId][_msgSender()].status == ContributionStatus.Accepted) revert AlreadyContributor();

        ipContributors[_ipId][_msgSender()] = Contributor({
            addr: _msgSender(),
            royaltyShareBasisPoints: _proposedRoyaltyShareBasisPoints,
            status: ContributionStatus.Proposed,
            contributedAt: block.timestamp,
            contributionURI: _contributionURI
        });

        emit ContributionProposed(_ipId, _msgSender(), _contributionURI);
    }

    /**
     * @notice The IP owner accepts a proposed contribution, integrating it and setting the contributor's royalty share.
     * @param _ipId The ID of the IP asset.
     * @param _contributor The address of the contributor.
     * @param _finalRoyaltyShareBasisPoints The final agreed-upon royalty share for the contributor.
     */
    function approveContribution(
        uint256 _ipId,
        address _contributor,
        uint16 _finalRoyaltyShareBasisPoints
    ) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipContributors[_ipId][_contributor].addr == address(0) || ipContributors[_ipId][_contributor].status != ContributionStatus.Proposed) {
            revert ContributionNotFound(_contributor);
        }
        if (_finalRoyaltyShareBasisPoints > 10000) revert InvalidRoyaltyShare();

        ipContributors[_ipId][_contributor].status = ContributionStatus.Accepted;
        ipContributors[_ipId][_contributor].royaltyShareBasisPoints = _finalRoyaltyShareBasisPoints;

        // Add to the list of contributor addresses for iteration if not already present
        bool found = false;
        for (uint256 i = 0; i < ipContributorAddresses[_ipId].length; i++) {
            if (ipContributorAddresses[_ipId][i] == _contributor) {
                found = true;
                break;
            }
        }
        if (!found) {
            ipContributorAddresses[_ipId].push(_contributor);
        }

        emit ContributionApproved(_ipId, _contributor, _finalRoyaltyShareBasisPoints);
    }

    /**
     * @notice The IP owner rejects a proposed contribution.
     * @param _ipId The ID of the IP asset.
     * @param _contributor The address of the contributor whose proposal is rejected.
     */
    function rejectContribution(uint256 _ipId, address _contributor) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipContributors[_ipId][_contributor].addr == address(0) || ipContributors[_ipId][_contributor].status != ContributionStatus.Proposed) {
            revert ContributionNotFound(_contributor);
        }
        ipContributors[_ipId][_contributor].status = ContributionStatus.Rejected;
        emit ContributionRejected(_ipId, _contributor);
    }

    /**
     * @notice The IP owner adjusts an existing contributor's royalty percentage.
     * @param _ipId The ID of the IP asset.
     * @param _contributor The address of the contributor.
     * @param _newShareBasisPoints The new royalty share in basis points.
     */
    function adjustContributorShare(uint256 _ipId, address _contributor, uint16 _newShareBasisPoints) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipContributors[_ipId][_contributor].addr == address(0) || ipContributors[_ipId][_contributor].status != ContributionStatus.Accepted) {
            revert NotContributor();
        }
        if (_newShareBasisPoints > 10000) revert InvalidRoyaltyShare();

        ipContributors[_ipId][_contributor].royaltyShareBasisPoints = _newShareBasisPoints;
        emit ContributorShareAdjusted(_ipId, _contributor, _newShareBasisPoints);
    }

    /**
     * @notice The IP owner removes a contributor and their associated royalty share from an IP.
     * @param _ipId The ID of the IP asset.
     * @param _contributor The address of the contributor to remove.
     */
    function removeContributor(uint256 _ipId, address _contributor) external onlyIPOwner(_ipId) {
        if (ipAssets[_ipId].id == 0) revert IPNotFound(_ipId);
        if (ipContributors[_ipId][_contributor].addr == address(0) || ipContributors[_ipId][_contributor].status != ContributionStatus.Accepted) {
            revert NotContributor();
        }

        // Set status to rejected to effectively remove from active distribution
        ipContributors[_ipId][_contributor].status = ContributionStatus.Rejected;
        ipContributors[_ipId][_contributor].royaltyShareBasisPoints = 0; // Ensure no future royalties

        // Optional: Remove from ipContributorAddresses array (more gas, but keeps array clean)
        address[] storage contributorAddrs = ipContributorAddresses[_ipId];
        for (uint256 i = 0; i < contributorAddrs.length; i++) {
            if (contributorAddrs[i] == _contributor) {
                if (i != contributorAddrs.length - 1) {
                    contributorAddrs[i] = contributorAddrs[contributorAddrs.length - 1];
                }
                contributorAddrs.pop();
                break;
            }
        }

        emit ContributorRemoved(_ipId, _contributor);
    }

    /**
     * @notice Registers a new IP asset that explicitly acknowledges its parent IP.
     *         This creates a 'fork' or derivative work.
     * @param _parentIPId The ID of the IP asset this new IP is derived from.
     * @param _name The name of the new derived IP asset.
     * @param _metadataURI A URI pointing to the detailed metadata of the derived IP.
     */
    function createDerivedIPAsset(uint256 _parentIPId, string memory _name, string memory _metadataURI) external nonReentrant {
        if (ipAssets[_parentIPId].id == 0) revert IPNotFound(_parentIPId);
        
        uint256 id = nextIPId++;
        ipAssets[id] = IPAsset({
            id: id,
            owner: _msgSender(),
            name: _name,
            metadataURI: _metadataURI,
            status: IPStatus.Active,
            createdAt: block.timestamp,
            parentIPId: _parentIPId // Link to parent IP
        });
        userOwnedIPs[_msgSender()].push(id);
        emit DerivedIPAssetCreated(id, _parentIPId, _msgSender());
    }


    // --- IV. Dispute Resolution & Platform Governance ---

    /**
     * @notice Allows any involved party to formally initiate a dispute concerning an IP or license.
     * @param _ipId The ID of the IP asset the dispute pertains to (or 0 if dispute is about platform).
     * @param _descriptionURI A URI pointing to initial dispute details and arguments.
     */
    function initiateDispute(uint256 _ipId, string memory _descriptionURI) external nonReentrant {
        // Can add more specific checks here, e.g., if msg.sender is owner/licensee/contributor for _ipId
        if (_ipId != 0 && ipAssets[_ipId].id == 0) revert IPNotFound(_ipId); // Allow platform-level disputes (ipId=0)
        
        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            ipId: _ipId,
            initiator: _msgSender(),
            descriptionURI: _descriptionURI,
            evidenceURI: "", // Initially empty
            status: DisputeStatus.Open,
            resolutionURI: "",
            initiatedAt: block.timestamp,
            resolvedAt: 0
        });
        emit DisputeInitiated(disputeId, _ipId, _msgSender(), _descriptionURI);
    }
    
    /**
     * @notice Allows any party involved in an open dispute to submit additional evidence.
     * @param _disputeId The ID of the dispute.
     * @param _evidenceURI A URI pointing to the new evidence.
     */
    function submitDisputeEvidence(uint256 _disputeId, string memory _evidenceURI) external {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound(_disputeId);
        if (dispute.status != DisputeStatus.Open) revert InvalidLicenseState(); // Reusing error for dispute status

        // For simplicity, overwrites existing evidenceURI. A more complex system might store an array of URIs.
        dispute.evidenceURI = _evidenceURI;
        dispute.status = DisputeStatus.EvidenceSubmitted; // Indicate evidence has been submitted
        emit DisputeEvidenceSubmitted(_disputeId, _msgSender(), _evidenceURI);
    }

    /**
     * @notice (Restricted to `disputeArbiter`) Records the final resolution of a dispute.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _status The final status of the dispute (e.g., Resolved).
     * @param _resolutionURI A URI pointing to the official resolution details.
     */
    function resolveDisputeOutcome(uint256 _disputeId, DisputeStatus _status, string memory _resolutionURI) external onlyDisputeArbiter {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert DisputeNotFound(_disputeId);
        if (dispute.status == DisputeStatus.Resolved) revert InvalidLicenseState(); // Already resolved

        dispute.status = _status;
        dispute.resolutionURI = _resolutionURI;
        dispute.resolvedAt = block.timestamp;

        // Future extension: Based on resolution, this function could trigger other actions
        // like `revokeLicense(licenseId)` or `adjustContributorShare(ipId, contributor, newShare)`.
        // This would require passing more parameters to this function or having the arbiter
        // call those functions separately after resolving the dispute.

        emit DisputeOutcomeResolved(_disputeId, _status, _resolutionURI);
    }

    /**
     * @notice Admin function to update platform-wide settings.
     * @param _trustedOracle The new address for the trusted oracle.
     * @param _disputeArbiter The new address for the dispute arbiter.
     * @param _platformFeeRecipient The new address for the platform fee recipient.
     * @param _platformFeeBasisPoints The new platform fee percentage in basis points (e.g., 100 for 1%).
     */
    function setPlatformConfiguration(
        address _trustedOracle,
        address _disputeArbiter,
        address _platformFeeRecipient,
        uint16 _platformFeeBasisPoints
    ) external onlyOwner {
        if (_trustedOracle == address(0) || _disputeArbiter == address(0) || _platformFeeRecipient == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_platformFeeBasisPoints > 10000) {
            revert InvalidRoyaltyShare();
        }

        trustedOracle = _trustedOracle;
        disputeArbiter = _disputeArbiter;
        platformFeeRecipient = _platformFeeRecipient;
        platformFeeBasisPoints = _platformFeeBasisPoints;

        emit PlatformConfigurationUpdated(_msgSender(), "trustedOracle", _trustedOracle, 0);
        emit PlatformConfigurationUpdated(_msgSender(), "disputeArbiter", _disputeArbiter, 0);
        emit PlatformConfigurationUpdated(_msgSender(), "platformFeeRecipient", _platformFeeRecipient, 0);
        emit PlatformConfigurationUpdated(_msgSender(), "platformFeeBasisPoints", address(0), _platformFeeBasisPoints);
    }
}
```