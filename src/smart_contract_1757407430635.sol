```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // For receiving ERC1155 tokens if needed

// Custom Errors for clarity and gas efficiency
error InvalidIPId(uint256 ipId);
error InvalidLicenseId(uint256 licenseId);
error Unauthorized();
error IPAlreadyFractionalized(uint256 ipId);
error IPNotFractionalized(uint256 ipId);
error NoActiveLicenses(uint256 ipId);
error LicenseNotActive(uint256 licenseId);
error LicenseExpired(uint256 licenseId);
error LicenseNotRenewable(uint256 licenseId);
error InvalidRoyaltyShares();
error NoRoyaltiesToClaim();
error InsufficientPayment(uint256 required, uint256 provided);
error IPStillLicensed(uint256 ipId);
error ZeroAddress();
error ProtocolFeeTooHigh(uint256 fee);
error EmptyCollaboratorList();

// Outline:
// EvoluStream: Dynamic & Fractionalized Intellectual Property Monetization Platform
// This platform allows creators to register unique digital intellectual property (IP) as NFTs,
// propose dynamic licensing agreements, fractionalize IP ownership, manage collaborator royalty splits,
// and claim accumulated royalties. It incorporates an internal reputation system and protocol fees.

// Core Concepts:
// - IP Asset Management: Each IP is an ERC721 NFT with rich metadata and creator/collaborator information.
// - Dynamic Licensing: Licenses can have variable terms, duration, usage-based royalty adjustments, and reputation incentives.
// - Fractional Ownership: IPs can be fractionalized into ERC1155 shares, allowing multiple economic owners to participate in royalties.
// - Collaborative Royalties: Automated, pull-based distribution of royalties to original creators/collaborators and fractional owners based on predefined shares.
// - Reputation System: Basic on-chain tracking of user reputation, influencing future interactions (e.g., license terms).
// - Protocol Fees: Configurable fees to sustain the platform, collected by a designated address.
// - IP Evolution: Ability for IP owners to update metadata, representing ongoing development or versioning.

// Function Summary:

// IP Registration & Management (ERC721-like but enhanced):
// 1.  registerIP: Registers a new IP asset, mints an ERC721 NFT to the creator, sets collaborators, and defines initial royalty splits.
// 2.  updateIPMetadata: Allows the current IP owner to update the IPFS CID and description for an existing IP, enabling "IP Evolution" or versioning.
// 3.  transferIPOwnership: Transfers the primary ERC721 IP NFT ownership. This function also updates the owner recorded in the IPAsset struct.
// 4.  revokeIP: Allows the IP owner to revoke an IP and burn its NFT, provided there are no active licenses or fractional shares, and the IP is not fractionalized.
// 5.  getIPDetails: Retrieves comprehensive, publicly viewable details about a specific IP asset.
// 6.  getCreatorIPs: Returns a list of IP IDs originally created by a specific address (iterative, for demo purposes).

// Dynamic Licensing System:
// 7.  proposeLicense: The IP owner proposes a dynamic license agreement to a specified licensee with custom terms, including dynamic royalty rates based on usage.
// 8.  acceptLicense: A licensee accepts a proposed license, potentially paying an initial fee, and activating the agreement, which also updates their reputation.
// 9.  rejectLicense: A licensee rejects a proposed license offer, removing it from pending agreements.
// 10. reportUsageAndPayRoyalties: A critical function where a licensee (or trusted oracle) reports usage metrics and pays corresponding royalties. It handles dynamic rate adjustments and funnels payments into the IP's royalty pool.
// 11. renewLicense: Allows a licensee to extend the duration of an expiring active license agreement under specific conditions.
// 12. terminateLicense: Either the IP owner or licensee can terminate an active license, with a reputation impact on both parties.
// 13. getLicenseDetails: Retrieves all relevant details of a specific license agreement.
// 14. getActiveLicensesForIP: Returns an array of active license IDs associated with a given IP asset.

// Fractional Ownership & Royalty Distribution:
// 15. fractionalizeIP: Converts a full ERC721 IP NFT into a specified number of ERC1155 fractional shares, transferring the ERC721 to the contract itself.
// 16. transferFractionalShares: Allows a holder of ERC1155 fractional shares to transfer them to another address. (Acts as the underlying mechanism for buying/selling fractional shares on external platforms).
// 17. claimRoyalties: Enables any IP collaborator, primary ERC721 owner (if not fractionalized), or fractional share holder to claim their accumulated share of collected royalties for a specific IP. This is a pull-based system that prevents double-claiming.
// 18. getFractionalShareBalance: Returns the number of ERC1155 fractional shares an address holds for a particular IP.

// Reputation System (Basic):
// 19. getReputation: Retrieves the current reputation score for a given address. (Reputation updates happen internally on key actions).

// Protocol Fees & Governance:
// 20. setProtocolFee: Allows the contract owner to set the percentage of royalties collected as a platform fee (capped at 10%).
// 21. setFeeCollector: Allows the contract owner to designate an address responsible for collecting protocol fees.
// 22. withdrawProtocolFees: Allows the designated fee collector to withdraw accumulated protocol fees to a specified address.
// 23. pauseContract: (Inherited from Pausable) Allows the contract owner to pause core contract functionalities during emergencies or upgrades.
// 24. unpauseContract: (Inherited from Pausable) Allows the contract owner to unpause core contract functionalities once issues are resolved.

contract EvoluStreamIP is ERC721, ERC1155, Ownable, Pausable, IERC1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _ipIdCounter;
    Counters.Counter private _licenseIdCounter;

    // --- Structs ---

    struct IPAsset {
        uint256 id;
        address owner; // The current ERC721 owner (can be this contract if fractionalized)
        address originalCreator; // The initial minter of the IP
        string name;
        string description;
        string ipfsCID; // Content Identifier
        bool isFractionalized; // True if the ERC721 is held by this contract and ERC1155s are issued
        mapping(address => uint256) collaboratorRoyaltyShares; // Address => Permille (sum must be <= 1000)
        uint256 totalCollaboratorSharePermille; // Sum of all original collaborator shares
        bool exists; // To check if an IP ID is valid
    }

    struct LicenseAgreement {
        uint256 id;
        uint256 ipId;
        address licensee;
        address ipOwnerAtAgreement; // Snapshot of the IP owner when agreement was made
        uint256 creationTime;
        uint256 expirationTime;
        uint256 baseRoyaltyRatePermille; // Base rate out of 1000 (e.g., 50 = 5%)
        uint256 dynamicRateThreshold; // Usage metric threshold for dynamic rate increase (0 if no dynamic rate)
        uint256 dynamicRatePermille; // Higher rate applied if threshold exceeded (0 if no dynamic rate)
        bytes32 usageScopeHash; // Hash of off-chain detailed usage terms (e.g., commercial, non-commercial, geographical)
        uint256 totalPaidRoyalties; // Total royalties paid for this specific license
        bool isActive;
    }

    // --- Mappings ---
    mapping(uint256 => IPAsset) public ipAssets;
    mapping(uint256 => LicenseAgreement) public licenseAgreements;
    mapping(uint256 => address[]) public ipCollaboratorAddresses; // To iterate collaborators for an IP
    mapping(address => int256) public reputationScores; // Basic reputation, can be positive or negative

    // Mapping from IP ID to an array of its active license IDs (for easier lookup)
    mapping(uint256 => uint256[]) public ipActiveLicenses;
    // Helper mapping to check if a license ID is active for an IP (faster deletion)
    mapping(uint256 => mapping(uint256 => bool)) private _isLicenseActiveForIp;

    // Royalties collected for each IP (total pool before distribution)
    mapping(uint256 => uint256) public collectedRoyaltiesPerIP;

    // Mapping to track claimed royalties by each participant for each IP to prevent double-claiming
    mapping(uint256 => mapping(address => uint256)) public claimedRoyalties;

    // Protocol fees
    uint256 public protocolFeePermille; // 10 = 1% (out of 1000)
    address public feeCollector;
    uint256 public protocolFeesAccumulated;

    // --- Events ---
    event IPRegistered(uint256 indexed ipId, address indexed owner, address indexed originalCreator, string name, string ipfsCID);
    event IPMetadataUpdated(uint256 indexed ipId, string newDescription, string newIpfsCID);
    event IPRevoked(uint256 indexed ipId);
    event LicenseProposed(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 expirationTime, uint256 baseRoyaltyRatePermille);
    event LicenseAccepted(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee);
    event LicenseRejected(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee);
    event RoyaltiesPaid(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 usageMetric, uint256 paymentAmount, uint256 protocolFee, uint256 netRoyalties);
    event LicenseRenewed(uint256 indexed licenseId, uint256 newExpirationTime);
    event LicenseTerminated(uint256 indexed licenseId, uint256 indexed ipId, address indexed terminator);
    event IPFractionalized(uint256 indexed ipId, uint256 totalShares);
    event RoyaltiesClaimed(uint256 indexed ipId, address indexed claimant, uint256 amount);
    event ReputationUpdated(address indexed user, int256 newReputation);
    event ProtocolFeeSet(uint256 newFeePermille);
    event FeeCollectorSet(address indexed oldCollector, address indexed newCollector);
    event ProtocolFeesWithdrawn(address indexed collector, uint256 amount);

    constructor(string memory _nftName, string memory _nftSymbol, string memory _uri1155)
        ERC721(_nftName, _nftSymbol) // e.g., "EvoluStream IP Asset", "ESIP"
        ERC1155(_uri1155)             // e.g., "https://evolustream.io/ip/{id}"
        Ownable(msg.sender)
    {
        // Set initial protocol fee to 0, feeCollector to owner
        protocolFeePermille = 0;
        feeCollector = msg.sender;
    }

    // --- Internal Helpers ---

    function _existsIP(uint256 _ipId) internal view returns (bool) {
        return ipAssets[_ipId].exists;
    }

    function _getIPOwner(uint256 _ipId) internal view returns (address) {
        // Returns the current ERC721 owner for the IP
        return ownerOf(_ipId);
    }

    function _updateReputation(address _user, int256 _change) internal {
        reputationScores[_user] += _change;
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    function _removeLicenseFromActiveList(uint256 _ipId, uint256 _licenseId) internal {
        if (!_isLicenseActiveForIp[_ipId][_licenseId]) {
            return;
        }

        uint256[] storage activeLicenses = ipActiveLicenses[_ipId];
        for (uint256 i = 0; i < activeLicenses.length; i++) {
            if (activeLicenses[i] == _licenseId) {
                // Replace with last element and pop to maintain order-independent array
                activeLicenses[i] = activeLicenses[activeLicenses.length - 1];
                activeLicenses.pop();
                break;
            }
        }
        _isLicenseActiveForIp[_ipId][_licenseId] = false;
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC1155 Required Functions ---
    // These functions must be implemented when inheriting IERC1155Receiver.
    // In this contract, the contract itself will hold ERC721 tokens but will not receive ERC1155 tokens from users.
    // However, the interface requires implementation.
    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // --- 1. IP Registration & Management ---

    /// @notice Registers a new IP asset, mints an ERC721 NFT to the creator, sets collaborators, and defines initial royalty splits.
    /// @param _name The name of the IP.
    /// @param _description A description of the IP.
    /// @param _ipfsCID The IPFS CID pointing to the IP content.
    /// @param _collaborators An array of collaborator addresses.
    /// @param _royaltyShares An array of royalty shares (in permille, out of 1000) corresponding to collaborators.
    function registerIP(
        string memory _name,
        string memory _description,
        string memory _ipfsCID,
        address[] memory _collaborators,
        uint256[] memory _royaltyShares
    ) public whenNotPaused returns (uint256) {
        if (_collaborators.length == 0 && msg.sender == address(0)) revert EmptyCollaboratorList(); // At least one creator
        if (_collaborators.length != _royaltyShares.length) {
            revert InvalidRoyaltyShares();
        }

        _ipIdCounter.increment();
        uint256 newIpId = _ipIdCounter.current();

        uint256 totalShare = 0;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            if (_collaborators[i] == address(0)) revert ZeroAddress();
            totalShare += _royaltyShares[i];
        }

        if (totalShare > 1000) revert InvalidRoyaltyShares();

        // Mint ERC721 to the original creator
        _safeMint(msg.sender, newIpId);
        _setTokenURI(newIpId, string(abi.encodePacked("ipfs://", _ipfsCID))); // Basic token URI for ERC721

        IPAsset storage newIP = ipAssets[newIpId];
        newIP.id = newIpId;
        newIP.owner = msg.sender; // ERC721 owner
        newIP.originalCreator = msg.sender;
        newIP.name = _name;
        newIP.description = _description;
        newIP.ipfsCID = _ipfsCID;
        newIP.exists = true;

        for (uint256 i = 0; i < _collaborators.length; i++) {
            newIP.collaboratorRoyaltyShares[_collaborators[i]] = _royaltyShares[i];
            ipCollaboratorAddresses[newIpId].push(_collaborators[i]);
        }
        newIP.totalCollaboratorSharePermille = totalShare;

        emit IPRegistered(newIpId, msg.sender, msg.sender, _name, _ipfsCID);
        return newIpId;
    }

    /// @notice Allows the current IP owner to update the IPFS CID and description for an existing IP.
    /// @param _ipId The ID of the IP asset.
    /// @param _newDescription The new description for the IP.
    /// @param _newIpfsCID The new IPFS CID.
    function updateIPMetadata(
        uint256 _ipId,
        string memory _newDescription,
        string memory _newIpfsCID
    ) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (_getIPOwner(_ipId) != msg.sender) revert Unauthorized();

        ipAssets[_ipId].description = _newDescription;
        ipAssets[_ipId].ipfsCID = _newIpfsCID;
        _setTokenURI(_ipId, string(abi.encodePacked("ipfs://", _newIpfsCID))); // Update token URI for ERC721

        emit IPMetadataUpdated(_ipId, _newDescription, _newIpfsCID);
    }

    /// @notice Transfers the primary ERC721 IP NFT ownership.
    /// @dev This function calls the internal ERC721 `_transfer` which handles ownership change.
    /// @param _from The current owner of the IP.
    /// @param _to The new owner of the IP.
    /// @param _ipId The ID of the IP asset to transfer.
    function transferIPOwnership(address _from, address _to, uint256 _ipId) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (_from != ownerOf(_ipId)) revert Unauthorized(); // Only current ERC721 owner can initiate or approve
        if (_to == address(0)) revert ZeroAddress();

        // This calls the ERC721's _transfer function.
        // It's assumed the caller has proper approval or is the owner.
        _transfer(_from, _to, _ipId);
        ipAssets[_ipId].owner = _to; // Update internal owner record

        // Note: ERC721 already emits Transfer event. No need for a custom one here.
    }

    /// @notice Allows the IP owner to revoke an IP and burn its NFT, provided there are no active licenses or fractional shares.
    /// @param _ipId The ID of the IP asset to revoke.
    function revokeIP(uint256 _ipId) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        // Only the current ERC721 owner can revoke if NOT fractionalized
        if (ipAssets[_ipId].isFractionalized || _getIPOwner(_ipId) != msg.sender) {
            revert Unauthorized();
        }

        // Check for active licenses
        if (ipActiveLicenses[_ipId].length > 0) revert IPStillLicensed(_ipId);

        _burn(_ipId);
        delete ipAssets[_ipId];
        delete ipCollaboratorAddresses[_ipId]; // Clear collaborator data
        delete collectedRoyaltiesPerIP[_ipId]; // Clear any remaining royalties

        emit IPRevoked(_ipId);
    }

    /// @notice Retrieves comprehensive, publicly viewable details about a specific IP asset.
    /// @param _ipId The ID of the IP asset.
    /// @return The IPAsset struct data.
    function getIPDetails(uint256 _ipId) public view returns (IPAsset memory) {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        // Note: Cannot return mapping directly (collaboratorRoyaltyShares), so it will be empty in the returned struct.
        // A separate getter for collaborator shares is needed if full details are required.
        IPAsset memory ip = ipAssets[_ipId];
        ip.owner = _getIPOwner(_ipId); // Ensure current ERC721 owner is reflected, which might be this contract if fractionalized.
        return ip;
    }

    /// @notice Returns a list of IP IDs originally created by a specific address.
    /// @dev This function iterates through all existing IPs, which can be gas-intensive for a very large number of IPs.
    /// For very large scale, an additional mapping (address => uint256[]) would be more efficient.
    /// @param _creator The address of the original creator.
    /// @return An array of IP IDs.
    function getCreatorIPs(address _creator) public view returns (uint256[] memory) {
        uint256[] memory creatorIPs = new uint256[](0);
        uint256 currentCount = _ipIdCounter.current();
        for (uint256 i = 1; i <= currentCount; i++) {
            if (_existsIP(i) && ipAssets[i].originalCreator == _creator) {
                // Resize array (inefficient, but acceptable for this example)
                uint256 currentLength = creatorIPs.length;
                uint256[] memory temp = new uint256[](currentLength + 1);
                for (uint256 j = 0; j < currentLength; j++) {
                    temp[j] = creatorIPs[j];
                }
                temp[currentLength] = i;
                creatorIPs = temp;
            }
        }
        return creatorIPs;
    }

    // --- 2. Dynamic Licensing System ---

    /// @notice The IP owner proposes a dynamic license agreement to a specified licensee with custom terms.
    /// @param _ipId The ID of the IP asset.
    /// @param _licensee The address of the proposed licensee.
    /// @param _duration The duration of the license in seconds.
    /// @param _baseRoyaltyRatePermille Base royalty rate (e.g., 50 for 5% out of 1000).
    /// @param _dynamicRateThreshold Usage metric threshold for dynamic rate increase (0 if no dynamic rate).
    /// @param _dynamicRatePermille Higher rate if threshold exceeded (0 if no dynamic rate).
    /// @param _usageScopeHash Hash of off-chain detailed usage terms (e.g., commercial, geographical).
    function proposeLicense(
        uint256 _ipId,
        address _licensee,
        uint256 _duration,
        uint256 _baseRoyaltyRatePermille,
        uint256 _dynamicRateThreshold,
        uint256 _dynamicRatePermille,
        bytes32 _usageScopeHash
    ) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (_getIPOwner(_ipId) != msg.sender) revert Unauthorized();
        if (_licensee == address(0)) revert ZeroAddress();
        if (_baseRoyaltyRatePermille > 1000) revert InvalidRoyaltyShares(); // Royalty rate can't exceed 100%

        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        LicenseAgreement storage newLicense = licenseAgreements[newLicenseId];
        newLicense.id = newLicenseId;
        newLicense.ipId = _ipId;
        newLicense.licensee = _licensee;
        newLicense.ipOwnerAtAgreement = msg.sender; // Snapshot owner
        newLicense.creationTime = block.timestamp;
        newLicense.expirationTime = block.timestamp + _duration;
        newLicense.baseRoyaltyRatePermille = _baseRoyaltyRatePermille;
        newLicense.dynamicRateThreshold = _dynamicRateThreshold;
        newLicense.dynamicRatePermille = _dynamicRatePermille;
        newLicense.usageScopeHash = _usageScopeHash;
        newLicense.isActive = false; // Not active until accepted

        emit LicenseProposed(newLicenseId, _ipId, _licensee, newLicense.expirationTime, _baseRoyaltyRatePermille);
    }

    /// @notice A licensee accepts a proposed license, potentially paying an initial fee, and activating the agreement.
    /// @param _licenseId The ID of the proposed license.
    /// @param _initialFee Optional initial payment for the license (e.g., for a fixed-term license).
    function acceptLicense(uint256 _licenseId, uint256 _initialFee) public payable whenNotPaused {
        LicenseAgreement storage license = licenseAgreements[_licenseId];
        // Ensure license exists, is for msg.sender, and is not already active
        if (license.id == 0 || license.licensee != msg.sender || license.isActive) {
            revert InvalidLicenseId(_licenseId);
        }
        if (msg.value < _initialFee) {
            revert InsufficientPayment(_initialFee, msg.value);
        }

        license.isActive = true;
        ipActiveLicenses[license.ipId].push(_licenseId);
        _isLicenseActiveForIp[license.ipId][_licenseId] = true;

        if (msg.value > 0) {
            // Process initial fee like royalties (subject to protocol fee)
            uint256 fee = (msg.value * protocolFeePermille) / 1000;
            protocolFeesAccumulated += fee;
            collectedRoyaltiesPerIP[license.ipId] += (msg.value - fee);
            emit RoyaltiesPaid(_licenseId, license.ipId, msg.sender, 0, msg.value, fee, msg.value - fee);
        }

        _updateReputation(msg.sender, 10); // Positive reputation for accepting
        emit LicenseAccepted(_licenseId, license.ipId, msg.sender);
    }

    /// @notice A licensee rejects a proposed license offer.
    /// @param _licenseId The ID of the proposed license.
    function rejectLicense(uint256 _licenseId) public whenNotPaused {
        LicenseAgreement storage license = licenseAgreements[_licenseId];
        if (license.id == 0 || license.licensee != msg.sender || license.isActive) {
            revert InvalidLicenseId(_licenseId);
        }

        delete licenseAgreements[_licenseId]; // Remove the proposed license
        emit LicenseRejected(_licenseId, license.ipId, msg.sender);
    }

    /// @notice A critical function where a licensee (or trusted oracle) reports usage metrics and pays corresponding royalties.
    /// It handles dynamic rate adjustments and funnels payments into the IP's royalty pool.
    /// @param _licenseId The ID of the active license.
    /// @param _usageMetric A metric representing usage (e.g., number of streams, downloads, copies).
    /// @param _paymentAmount The amount of Ether being paid for this usage.
    function reportUsageAndPayRoyalties(
        uint256 _licenseId,
        uint256 _usageMetric,
        uint256 _paymentAmount
    ) public payable whenNotPaused {
        LicenseAgreement storage license = licenseAgreements[_licenseId];
        if (!license.isActive) revert LicenseNotActive(_licenseId);
        if (license.licensee != msg.sender) revert Unauthorized();
        if (block.timestamp > license.expirationTime) {
            // Automatically deactivate expired license
            _removeLicenseFromActiveList(license.ipId, _licenseId);
            license.isActive = false;
            revert LicenseExpired(_licenseId);
        }
        if (msg.value < _paymentAmount) revert InsufficientPayment(_paymentAmount, msg.value);

        uint256 royaltyRate = license.baseRoyaltyRatePermille;
        if (license.dynamicRateThreshold > 0 && _usageMetric >= license.dynamicRateThreshold) {
            royaltyRate = license.dynamicRatePermille;
        }

        uint256 calculatedRoyalty = (_paymentAmount * royaltyRate) / 1000;

        uint256 protocolFee = (calculatedRoyalty * protocolFeePermille) / 1000;
        protocolFeesAccumulated += protocolFee;

        uint256 netRoyalties = calculatedRoyalty - protocolFee;
        collectedRoyaltiesPerIP[license.ipId] += netRoyalties;
        license.totalPaidRoyalties += netRoyalties;

        _updateReputation(msg.sender, 5); // Positive reputation for paying royalties

        emit RoyaltiesPaid(_licenseId, license.ipId, msg.sender, _usageMetric, _paymentAmount, protocolFee, netRoyalties);
    }

    /// @notice Allows a licensee to extend the duration of an expiring active license agreement.
    /// @param _licenseId The ID of the license to renew.
    /// @param _newDuration The additional duration in seconds.
    function renewLicense(uint256 _licenseId, uint256 _newDuration) public whenNotPaused {
        LicenseAgreement storage license = licenseAgreements[_licenseId];
        if (!license.isActive || license.licensee != msg.sender) revert LicenseNotActive(_licenseId);
        if (_newDuration == 0) revert LicenseNotRenewable(_licenseId);

        // Only allow renewal if close to expiration (e.g., within 30 days) or already expired but still active
        // This prevents arbitrarily extending licenses far into the future without a new agreement.
        if (block.timestamp < license.expirationTime && license.expirationTime - block.timestamp > 30 days) {
            revert LicenseNotRenewable(_licenseId);
        }

        license.expirationTime += _newDuration;
        _updateReputation(msg.sender, 3); // Small positive for renewal
        emit LicenseRenewed(_licenseId, license.expirationTime);
    }

    /// @notice Either the IP owner or licensee can terminate an active license under specified conditions.
    /// @dev For simplicity, any party can terminate. Real-world applications might impose penalties or require arbitration.
    /// @param _licenseId The ID of the license to terminate.
    function terminateLicense(uint256 _licenseId) public whenNotPaused {
        LicenseAgreement storage license = licenseAgreements[_licenseId];
        if (!license.isActive) revert LicenseNotActive(_licenseId);
        if (license.ipOwnerAtAgreement != msg.sender && license.licensee != msg.sender) revert Unauthorized();

        license.isActive = false;
        _removeLicenseFromActiveList(license.ipId, _licenseId);
        _updateReputation(license.licensee, -5); // Negative reputation for early termination
        _updateReputation(license.ipOwnerAtAgreement, -5); // Both get a small hit for dispute/termination

        emit LicenseTerminated(_licenseId, license.ipId, msg.sender);
    }

    /// @notice Retrieves all relevant details of a specific license agreement.
    /// @param _licenseId The ID of the license.
    /// @return The LicenseAgreement struct data.
    function getLicenseDetails(uint256 _licenseId) public view returns (LicenseAgreement memory) {
        LicenseAgreement memory license = licenseAgreements[_licenseId];
        if (license.id == 0) revert InvalidLicenseId(_licenseId);
        return license;
    }

    /// @notice Returns an array of active license IDs associated with a given IP asset.
    /// @param _ipId The ID of the IP asset.
    /// @return An array of active license IDs.
    function getActiveLicensesForIP(uint256 _ipId) public view returns (uint256[] memory) {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        return ipActiveLicenses[_ipId];
    }

    // --- 3. Fractional Ownership & Royalty Distribution ---

    /// @notice Converts a full ERC721 IP NFT into a specified number of ERC1155 fractional shares, transferring the ERC721 to the contract.
    /// The contract becomes the holder of the ERC721, and the previous owner receives ERC1155 shares.
    /// @param _ipId The ID of the IP asset to fractionalize.
    /// @param _totalShares The total number of ERC1155 shares to mint.
    function fractionalizeIP(uint256 _ipId, uint256 _totalShares) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (_getIPOwner(_ipId) != msg.sender) revert Unauthorized(); // Only ERC721 owner can fractionalize
        if (ipAssets[_ipId].isFractionalized) revert IPAlreadyFractionalized(_ipId);
        if (_totalShares == 0) revert InvalidRoyaltyShares(); // Shares must be > 0

        // Transfer the ERC721 NFT to this contract
        _transfer(msg.sender, address(this), _ipId);
        ipAssets[_ipId].owner = address(this); // Update internal owner record to reflect contract holding ERC721

        // Mint ERC1155 shares to the original ERC721 owner
        _mint(msg.sender, _ipId, _totalShares, "");
        ipAssets[_ipId].isFractionalized = true;

        emit IPFractionalized(_ipId, _totalShares);
    }

    /// @notice Allows a holder of ERC1155 fractional shares to transfer them to another address.
    /// This acts as the underlying mechanism for buying/selling fractional shares on external platforms or direct transfers.
    /// @param _from The address currently holding the shares.
    /// @param _to The address to transfer shares to.
    /// @param _ipId The ID of the IP (which is also the ERC1155 token ID for shares).
    /// @param _amount The amount of shares to transfer.
    function transferFractionalShares(
        address _from,
        address _to,
        uint256 _ipId,
        uint256 _amount
    ) public whenNotPaused {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (!ipAssets[_ipId].isFractionalized) revert IPNotFractionalized(_ipId); // Must be fractionalized to transfer shares
        if (_to == address(0)) revert ZeroAddress();

        // This calls the ERC1155's safeTransferFrom function, which handles approval and ownership checks.
        // It's up to an external marketplace or direct agreement to handle payment for these transfers.
        _safeTransferFrom(_from, _to, _ipId, _amount, "");
        // ERC1155 already emits TransferSingle event. No need for a custom one.
    }

    /// @notice Enables any IP collaborator, primary ERC721 owner (if not fractionalized), or fractional share holder to claim their accumulated share of collected royalties for a specific IP.
    /// This is a pull-based system that uses `claimedRoyalties` to prevent double-claiming.
    /// @param _ipId The ID of the IP asset.
    function claimRoyalties(uint256 _ipId) public whenNotPaused {
        IPAsset storage ip = ipAssets[_ipId];
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (collectedRoyaltiesPerIP[_ipId] == 0) revert NoRoyaltiesToClaim();

        uint256 availableRoyalties = collectedRoyaltiesPerIP[_ipId]; // Total pool of royalties for this IP
        uint256 amountToClaim = 0;

        // Determine claimant's share:
        // Case 1: Claimant is a fixed collaborator
        uint256 collaboratorSharePermille = ip.collaboratorRoyaltyShares[msg.sender];
        if (collaboratorSharePermille > 0) {
            uint256 potentialCollaboratorShare = (availableRoyalties * collaboratorSharePermille) / 1000;
            amountToClaim += (potentialCollaboratorShare - claimedRoyalties[_ipId][msg.sender]);
        }

        // Case 2: Claimant is an owner (ERC721 owner if not fractionalized, or fractional share holder)
        uint256 ownerSharePermille = 1000 - ip.totalCollaboratorSharePermille;
        if (ownerSharePermille > 0) {
            uint256 ownerPoolPotential = (availableRoyalties * ownerSharePermille) / 1000;

            if (!ip.isFractionalized && _getIPOwner(_ipId) == msg.sender) {
                // If IP is not fractionalized, the ERC721 owner claims the entire owner pool
                amountToClaim += (ownerPoolPotential - claimedRoyalties[_ipId][msg.sender]);
            } else if (ip.isFractionalized) {
                // If IP is fractionalized, a fractional owner claims based on their ERC1155 balance
                uint256 totalFractionalShares = totalSupply(_ipId);
                if (totalFractionalShares > 0) { // Should always be > 0 if fractionalized
                    uint256 myShares = balanceOf(msg.sender, _ipId);
                    if (myShares > 0) {
                        uint256 myFractionalPotential = (ownerPoolPotential * myShares) / totalFractionalShares;
                        amountToClaim += (myFractionalPotential - claimedRoyalties[_ipId][msg.sender]);
                    }
                }
            }
        }

        if (amountToClaim == 0) revert NoRoyaltiesToClaim();

        // Update the amount claimed by msg.sender
        claimedRoyalties[_ipId][msg.sender] += amountToClaim;

        // Transfer funds
        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Royalty transfer failed");

        emit RoyaltiesClaimed(_ipId, msg.sender, amountToClaim);
    }

    /// @notice Returns the number of ERC1155 fractional shares an address holds for a particular IP.
    /// @param _ipId The ID of the IP asset.
    /// @param _holder The address whose balance is to be checked.
    /// @return The balance of fractional shares.
    function getFractionalShareBalance(uint256 _ipId, address _holder) public view returns (uint256) {
        if (!_existsIP(_ipId)) revert InvalidIPId(_ipId);
        if (!ipAssets[_ipId].isFractionalized) revert IPNotFractionalized(_ipId);
        return balanceOf(_holder, _ipId);
    }

    // --- 4. Reputation System (Basic) ---

    /// @notice Retrieves the current reputation score for a given address.
    /// @param _user The address to query.
    /// @return The reputation score.
    function getReputation(address _user) public view returns (int256) {
        return reputationScores[_user];
    }

    // --- 5. Protocol Fees & Governance ---

    /// @notice Allows the contract owner to set the percentage of royalties collected as a platform fee.
    /// @param _newFeePermille The new fee rate in permille (e.g., 10 for 1%). Capped at 100 (10%).
    function setProtocolFee(uint256 _newFeePermille) public onlyOwner whenNotPaused {
        if (_newFeePermille > 100) revert ProtocolFeeTooHigh(_newFeePermille); // Cap at 10%
        protocolFeePermille = _newFeePermille;
        emit ProtocolFeeSet(_newFeePermille);
    }

    /// @notice Allows the contract owner to designate an address responsible for collecting protocol fees.
    /// @param _newCollector The address of the new fee collector.
    function setFeeCollector(address _newCollector) public onlyOwner whenNotPaused {
        if (_newCollector == address(0)) revert ZeroAddress();
        address oldCollector = feeCollector;
        feeCollector = _newCollector;
        emit FeeCollectorSet(oldCollector, _newCollector);
    }

    /// @notice Allows the designated fee collector to withdraw accumulated protocol fees.
    function withdrawProtocolFees() public whenNotPaused {
        if (msg.sender != feeCollector) revert Unauthorized();
        if (protocolFeesAccumulated == 0) revert NoRoyaltiesToClaim(); // Reuse error for no fees

        uint256 amount = protocolFeesAccumulated;
        protocolFeesAccumulated = 0;

        (bool success, ) = payable(feeCollector).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit ProtocolFeesWithdrawn(feeCollector, amount);
    }
}
```