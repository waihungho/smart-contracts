Here's a Solidity smart contract named `EtherealCanvasFoundry`, designed to explore advanced, creative, and trendy concepts in decentralized intellectual property (IP) management.

The core idea is a platform for multi-contributor, AI-assisted (metadata hash only) digital IP, managed as dynamic NFTs. It features on-chain licensing, automated royalty distribution to multiple creators, and explicit tracking of derivative works, all governed by a simplified on-chain voting system.

---

### Outline and Function Summary:

**Contract:** `EtherealCanvasFoundry`

A sophisticated protocol for managing decentralized, multi-contributor intellectual property (IP) as dynamic NFT-like assets. It enables collaborative creation, flexible licensing, automated royalty distribution, and tracking of derivative works, integrating community governance concepts for core IP changes and content moderation.

**Key Concepts:**

*   **IPAsset:** A structured record representing a unique piece of digital intellectual property. It includes metadata (e.g., IPFS hash of content), a list of current contributors, their dynamic royalty shares, and links to any parent or derivative IP. Unlike a standard ERC721, ownership is collective and managed through the contract's logic.
*   **LicenseOffer:** A formal proposal to license an IPAsset, specifying terms such as price, duration, and usage rights (via a metadata hash).
*   **ActiveLicense:** An instantiated license agreement resulting from an accepted LicenseOffer, detailing the licensee, period, and agreed terms.
*   **DerivativeLink:** A robust mechanism for tracking IP assets that are derivatives of existing parent IP. It ensures automatic royalty flow from the derivative to its parent.
*   **ContributorShare:** Defines the percentage of royalties each contributor receives from an IPAsset, which can be dynamically adjusted through a voting process.
*   **ProposalSystem:** A basic on-chain voting mechanism allowing IP contributors or general system participants to propose and vote on significant changes, such as adjusting royalty splits or flagging/removing problematic IP.

---

**Function Summary:**

**I. Core IP Management (Creation & Metadata)**
1.  `mintIPAsset(string memory _metadataHash, address[] memory _contributors, uint256[] memory _shares, uint256 _parentIpId, uint256 _derivativeRoyaltyShare)`:
    Mints a new IPAsset, establishing its initial metadata hash, defining its primary contributors, and setting their initial royalty shares. This function also supports registering the new IP as a derivative of an existing parent IP.
2.  `updateIPMetadataHash(uint256 _ipId, string memory _newMetadataHash)`:
    Allows authorized contributors of an IPAsset to update its associated content metadata hash, for instance, after a content revision or enhancement.
3.  `registerExternalIPAsset(address _externalNFTContract, uint256 _externalTokenId, string memory _metadataHash, address[] memory _contributors, uint256[] memory _shares)`:
    Enables the registration of an existing external NFT (e.g., from an ERC721 contract) as an IPAsset within the EtherealCanvas ecosystem, allowing it to leverage this contract's licensing and royalty features.
4.  `getIPAssetDetails(uint256 _ipId)`:
    Retrieves comprehensive, immutable details of a specified IPAsset.
5.  `getContributorShare(uint256 _ipId, address _contributor)`:
    Returns the current royalty share percentage allocated to a specific contributor for a given IPAsset.

**II. Contributor & Royalty Management**
6.  `proposeShareUpdate(uint256 _ipId, address[] memory _newContributors, uint256[] memory _newShares)`:
    Initiates a formal proposal to modify the royalty distribution percentages among contributors for a specific IPAsset.
7.  `voteOnShareUpdate(uint256 _proposalId, bool _for)`:
    Allows current contributors of an IPAsset to cast their vote (for or against) on a pending royalty share update proposal.
8.  `finalizeShareUpdate(uint256 _proposalId)`:
    Executes a royalty share update proposal once it has successfully passed its voting period and met the required consensus.
9.  `distributeRoyalties(uint256 _ipId)`:
    Triggers the calculation and internal distribution of accumulated license fees to the respective contributors of an IPAsset, based on their defined royalty shares.
10. `withdrawEarnedRoyalties()`:
    Enables individual contributors to withdraw their accumulated and distributed royalty earnings from the contract's balance to their wallet.

**III. Licensing & Monetization**
11. `createLicenseOffer(uint256 _ipId, uint256 _price, uint256 _duration, string memory _usageRightsHash)`:
    Allows a contributor to define and issue a new licensing offer for an IPAsset, specifying terms like price, duration, and permitted usage (via a content hash).
12. `acceptLicenseOffer(uint256 _offerId)`:
    Enables a prospective licensee to accept an existing license offer by paying the specified fee, thereby activating a new ActiveLicense.
13. `revokeLicenseOffer(uint256 _offerId)`:
    Allows the original creator of a license offer to withdraw it if it has not yet been accepted.
14. `terminateActiveLicense(uint256 _licenseId, string memory _reasonHash)`:
    Provides IP contributors the ability to terminate an active license agreement, typically due to a breach of the specified terms and conditions.
15. `renewActiveLicense(uint256 _licenseId)`:
    Allows a licensee to extend the duration of an existing active license by paying the renewal fee, based on the original offer's terms.
16. `getLicenseDetails(uint256 _licenseId)`:
    Retrieves detailed information about a specific license offer or an active license agreement.

**IV. Derivative Work Tracking**
17. `getDerivativeLinks(uint256 _parentIpId)`:
    Returns a list of all IPAsset IDs that have been explicitly registered as derivatives of a given parent IPAsset. (The `mintDerivativeIPAsset` functionality is now integrated directly into `mintIPAsset`).

**V. Governance & System Management**
18. `proposeIPRemoval(uint256 _ipId, string memory _reasonHash)`:
    Initiates a governance proposal to flag or remove an IPAsset from active status, possibly due to content violations, copyright infringement, or other community-driven reasons.
19. `voteOnIPRemoval(uint256 _proposalId, bool _for)`:
    Allows eligible voters (e.g., any contributor in the EtherealCanvas system) to cast their vote on a pending IP removal proposal.
20. `finalizeIPRemoval(uint256 _proposalId)`:
    Executes an IP removal proposal that has successfully passed its voting phase, marking the IPAsset as inactive within the system.
21. `setOracleAddress(address _newOracleAddress)`:
    (Owner-only) Sets the address of an external oracle contract, enabling potential future integrations for dynamic pricing, external data feeds, or complex condition checks.
22. `setLicenseFeeMultiplier(uint256 _multiplier)`:
    (Owner-only) Adjusts a global multiplier that is applied to all license fees. This allows for dynamic pricing strategies, potentially informed by external oracle data.

**VI. Helper/View Functions**
23. `getIPAssetContributorCount(uint256 _ipId)`:
    Returns the total number of contributors currently associated with a specified IPAsset.
24. `getIPAssetContributors(uint256 _ipId)`:
    Returns an array of all contributor addresses for a given IPAsset.
25. `owner()`:
    Returns the address of the contract deployer (owner).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline and Function Summary:
//
// Contract: EtherealCanvasFoundry
// A sophisticated protocol for managing decentralized, multi-contributor intellectual property (IP) as dynamic NFT-like assets.
// It enables collaborative creation, flexible licensing, automated royalty distribution, and tracking of derivative works,
// integrating community governance concepts for core IP changes and content moderation.
//
// Key Concepts:
// - IPAsset: A structured record representing a unique piece of digital intellectual property. It includes metadata
//            (e.g., IPFS hash of content), a list of current contributors, their dynamic royalty shares, and links
//            to any parent or derivative IP. Unlike a standard ERC721, ownership is collective and managed through
//            the contract's logic.
// - LicenseOffer: A formal proposal to license an IPAsset, specifying terms such as price, duration, and usage
//                 rights (via a metadata hash).
// - ActiveLicense: An instantiated license agreement resulting from an accepted LicenseOffer, detailing the licensee,
//                  period, and agreed terms.
// - DerivativeLink: A robust mechanism for tracking IP assets that are derivatives of existing parent IP. It ensures
//                   automatic royalty flow from the derivative to its parent.
// - ContributorShare: Defines the percentage of royalties each contributor receives from an IPAsset, which can be
//                     dynamically adjusted through a voting process.
// - ProposalSystem: A basic on-chain voting mechanism allowing IP contributors or general system participants to
//                   propose and vote on significant changes, such as adjusting royalty splits or flagging/removing
//                   problematic IP.
//
// ---
//
// Function Summary:
//
// I. Core IP Management (Creation & Metadata)
// 1. mintIPAsset(string memory _metadataHash, address[] memory _contributors, uint256[] memory _shares, uint256 _parentIpId, uint256 _derivativeRoyaltyShare):
//    Mints a new IPAsset, establishing its initial metadata hash, defining its primary contributors, and setting their
//    initial royalty shares. This function also supports registering the new IP as a derivative of an existing parent IP.
// 2. updateIPMetadataHash(uint256 _ipId, string memory _newMetadataHash):
//    Allows authorized contributors of an IPAsset to update its associated content metadata hash, for instance, after
//    a content revision or enhancement.
// 3. registerExternalIPAsset(address _externalNFTContract, uint256 _externalTokenId, string memory _metadataHash, address[] memory _contributors, uint256[] memory _shares):
//    Enables the registration of an existing external NFT (e.g., from an ERC721 contract) as an IPAsset within the
//    EtherealCanvas ecosystem, allowing it to leverage this contract's licensing and royalty features.
// 4. getIPAssetDetails(uint256 _ipId):
//    Retrieves comprehensive, immutable details of a specified IPAsset.
// 5. getContributorShare(uint256 _ipId, address _contributor):
//    Returns the current royalty share percentage allocated to a specific contributor for a given IPAsset.
//
// II. Contributor & Royalty Management
// 6. proposeShareUpdate(uint256 _ipId, address[] memory _newContributors, uint256[] memory _newShares):
//    Initiates a formal proposal to modify the royalty distribution percentages among contributors for a specific IPAsset.
// 7. voteOnShareUpdate(uint256 _proposalId, bool _for):
//    Allows current contributors of an IPAsset to cast their vote (for or against) on a pending royalty share update proposal.
// 8. finalizeShareUpdate(uint256 _proposalId):
//    Executes a royalty share update proposal once it has successfully passed its voting period and met the required consensus.
// 9. distributeRoyalties(uint256 _ipId):
//    Triggers the calculation and internal distribution of accumulated license fees to the respective contributors of an
//    IPAsset, based on their defined royalty shares.
// 10. withdrawEarnedRoyalties():
//     Enables individual contributors to withdraw their accumulated and distributed royalty earnings from the contract's
//     balance to their wallet.
//
// III. Licensing & Monetization
// 11. createLicenseOffer(uint256 _ipId, uint256 _price, uint256 _duration, string memory _usageRightsHash):
//     Allows a contributor to define and issue a new licensing offer for an IPAsset, specifying terms like price,
//     duration, and permitted usage (via a content hash).
// 12. acceptLicenseOffer(uint256 _offerId):
//     Enables a prospective licensee to accept an existing license offer by paying the specified fee, thereby activating
//     a new ActiveLicense.
// 13. revokeLicenseOffer(uint256 _offerId):
//     Allows the original creator of a license offer to withdraw it if it has not yet been accepted.
// 14. terminateActiveLicense(uint256 _licenseId, string memory _reasonHash):
//     Provides IP contributors the ability to terminate an active license agreement, typically due to a breach of the
//     specified terms and conditions.
// 15. renewActiveLicense(uint256 _licenseId):
//     Allows a licensee to extend the duration of an existing active license by paying the renewal fee, based on the
//     original offer's terms.
// 16. getLicenseDetails(uint256 _licenseId):
//     Retrieves detailed information about a specific license offer or an active license agreement.
//
// IV. Derivative Work Tracking
// 17. getDerivativeLinks(uint256 _parentIpId):
//     Returns a list of all IPAsset IDs that have been explicitly registered as derivatives of a given parent IPAsset.
//     (The `mintDerivativeIPAsset` functionality is now integrated directly into `mintIPAsset`).
//
// V. Governance & System Management
// 18. proposeIPRemoval(uint256 _ipId, string memory _reasonHash):
//     Initiates a governance proposal to flag or remove an IPAsset from active status, possibly due to content
//     violations, copyright infringement, or other community-driven reasons.
// 19. voteOnIPRemoval(uint256 _proposalId, bool _for):
//     Allows eligible voters (e.g., any contributor in the EtherealCanvas system) to cast their vote on a pending
//     IP removal proposal.
// 20. finalizeIPRemoval(uint256 _proposalId):
//     Executes an IP removal proposal that has successfully passed its voting phase, marking the IPAsset as inactive
//     within the system.
// 21. setOracleAddress(address _newOracleAddress):
//     (Owner-only) Sets the address of an external oracle contract, enabling potential future integrations for
//     dynamic pricing, external data feeds, or complex condition checks.
// 22. setLicenseFeeMultiplier(uint256 _multiplier):
//     (Owner-only) Adjusts a global multiplier that is applied to all license fees. This allows for dynamic pricing
//     strategies, potentially informed by external oracle data.
//
// VI. Helper/View Functions
// 23. getIPAssetContributorCount(uint256 _ipId):
//     Returns the total number of contributors currently associated with a specified IPAsset.
// 24. getIPAssetContributors(uint256 _ipId):
//     Returns an array of all contributor addresses for a given IPAsset.
// 25. owner():
//     Returns the address of the contract deployer (owner).

contract EtherealCanvasFoundry {

    address public owner; // Contract deployer
    address public oracleAddress; // Address of a potential external oracle
    uint256 public licenseFeeMultiplier = 10000; // 10000 = 1x multiplier (100%), for dynamic pricing

    uint256 public nextIpId = 1;
    uint256 public nextLicenseOfferId = 1;
    uint256 public nextActiveLicenseId = 1;
    uint256 public nextShareProposalId = 1;
    uint256 public nextRemovalProposalId = 1;

    // --- Data Structures ---

    struct IPAsset {
        uint256 ipId;
        string metadataHash; // IPFS hash or similar for actual content/description
        uint256 creationTimestamp;
        address[] contributors; // Addresses of current creators/owners
        mapping(address => uint256) royaltyShares; // Percentage shares (e.g., 5000 for 50%, total 10000)
        uint256 totalShares; // Should sum to 10000 (100%)
        uint256 parentIpId; // 0 if not a derivative
        uint256 derivativeRoyaltyShare; // % of derivative sales to go to parent (e.g., 500 for 5%)
        bool isActive; // Can be marked inactive if removed/flagged
        uint256 pendingLicenseFees; // Funds collected from licenses for this IP, awaiting distribution
    }

    struct LicenseOffer {
        uint256 offerId;
        uint256 ipId;
        address licensor; // The specific contributor who created this offer
        uint256 price; // Price in Wei
        uint256 duration; // Duration in seconds
        string usageRightsHash; // IPFS hash for detailed terms (e.g., commercial, non-commercial)
        bool isActive; // Can be revoked
        uint256 createdTimestamp;
    }

    struct ActiveLicense {
        uint256 licenseId;
        uint256 ipId;
        uint256 offerId; // Link to the offer it was based on
        address licensee;
        uint256 startDate;
        uint256 endDate;
        uint256 paymentAmount; // Total amount paid for this license (including renewals)
        string usageRightsHash;
        bool isActive; // Can be terminated
    }

    struct ShareUpdateProposal {
        uint256 proposalId;
        uint256 ipId;
        address[] newContributorsList; // For iterating over proposed contributors
        mapping(address => uint256) newShares; // Proposed new shares
        uint256 totalProposedShares; // Must sum to 10000
        uint256 creationTimestamp;
        mapping(address => bool) hasVoted; // Tracks votes from eligible contributors
        uint256 votesFor; // Number of unique contributors who voted "for"
        uint256 totalContributorsAtProposal; // Snapshot of contributors at time of proposal for quorum
        bool executed;
        bool rejected;
    }

    struct IPRemovalProposal {
        uint256 proposalId;
        uint256 ipId;
        address proposer;
        string reasonHash; // IPFS hash for detailed reason
        uint256 creationTimestamp;
        mapping(address => bool) hasVoted; // Tracks votes from eligible voters
        uint256 votesFor; // Number of unique voters who voted "for"
        uint256 totalVotersAtProposal; // Snapshot of total eligible voters for quorum
        bool executed;
        bool rejected;
    }

    // --- Mappings ---
    mapping(uint256 => IPAsset) public ipAssets;
    mapping(uint256 => LicenseOffer) public licenseOffers;
    mapping(uint256 => ActiveLicense) public activeLicenses;
    mapping(uint256 => ShareUpdateProposal) public shareUpdateProposals;
    mapping(uint256 => IPRemovalProposal) public ipRemovalProposals;

    // Mapping for tracking accumulated royalties for contributors
    mapping(address => uint256) public earnedRoyalties;
    // Mapping for tracking derivative links (Parent IP -> List of Derivative IPs)
    mapping(uint256 => uint256[]) public derivativeLinks;

    // Mapping for external NFTs registered (contract, tokenID) -> ipId
    mapping(address => mapping(uint256 => uint256)) public externalNFTtoIPId;

    // --- Events ---
    event IPAssetMinted(uint256 indexed ipId, address indexed minter, string metadataHash, uint256 parentIpId);
    event IPMetadataUpdated(uint256 indexed ipId, string newMetadataHash, address indexed updater);
    event ExternalIPAssetRegistered(uint256 indexed ipId, address indexed externalContract, uint256 externalTokenId);
    event RoyaltySharesProposed(uint256 indexed proposalId, uint256 indexed ipId, address proposer);
    event RoyaltyShareVoted(uint256 indexed proposalId, uint256 indexed ipId, address indexed voter, bool _for);
    event RoyaltySharesUpdated(uint256 indexed ipId, uint256 proposalId);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 amountDistributedToContributors, uint256 amountToParent);
    event RoyaltiesWithdrawn(address indexed recipient, uint256 amount);
    event LicenseOfferCreated(uint256 indexed offerId, uint256 indexed ipId, address indexed licensor, uint256 price, uint256 duration);
    event LicenseOfferAccepted(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 paymentAmount);
    event LicenseOfferRevoked(uint256 indexed offerId);
    event ActiveLicenseTerminated(uint256 indexed licenseId, uint256 indexed ipId, string reasonHash);
    event ActiveLicenseRenewed(uint256 indexed licenseId, uint256 newEndDate, uint256 additionalPayment);
    event IPRemovalProposed(uint256 indexed proposalId, uint256 indexed ipId, address proposer, string reasonHash);
    event IPRemovalVoted(uint256 indexed proposalId, uint256 indexed ipId, address indexed voter, bool _for);
    event IPRemovalFinalized(uint256 indexed ipId, uint256 proposalId);
    event OracleAddressSet(address indexed newOracleAddress);
    event LicenseFeeMultiplierSet(uint256 newMultiplier);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "ECF: Only contract owner can call this function");
        _;
    }

    modifier onlyIPContributor(uint256 _ipId) {
        bool isContributor = false;
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.ipId != 0, "ECF: IPAsset does not exist");
        for (uint256 i = 0; i < ip.contributors.length; i++) {
            if (ip.contributors[i] == msg.sender) {
                isContributor = true;
                break;
            }
        }
        require(isContributor, "ECF: Caller is not a contributor of this IP asset");
        _;
    }

    modifier onlyLicenseOfferCreator(uint256 _offerId) {
        require(licenseOffers[_offerId].licensor == msg.sender, "ECF: Only the license offer creator can call this function");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- I. Core IP Management (Creation & Metadata) ---

    /**
     * @dev Mints a new IPAsset, setting initial metadata, contributors, and their royalty shares.
     * Can also register as a derivative of an existing IP.
     * @param _metadataHash IPFS hash or similar for the actual content/description.
     * @param _contributors Addresses of the initial creators/owners.
     * @param _shares Percentage shares for each contributor (e.g., 5000 for 50%). Must sum to 10000.
     * @param _parentIpId The IP ID of the parent asset, or 0 if this is an original IP.
     * @param _derivativeRoyaltyShare The percentage of this derivative's royalties to be sent to the parent IP's contributors (e.g., 500 for 5%). Only applicable if _parentIpId > 0.
     */
    function mintIPAsset(
        string memory _metadataHash,
        address[] memory _contributors,
        uint256[] memory _shares,
        uint256 _parentIpId,
        uint256 _derivativeRoyaltyShare
    ) external {
        require(_contributors.length > 0, "ECF: Must have at least one contributor");
        require(_contributors.length == _shares.length, "ECF: Contributors and shares arrays must be of equal length");

        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares == 10000, "ECF: Total shares must sum to 10000 (100%)");

        if (_parentIpId != 0) {
            require(ipAssets[_parentIpId].ipId != 0, "ECF: Parent IP does not exist");
            require(ipAssets[_parentIpId].isActive, "ECF: Parent IP is not active");
            require(_derivativeRoyaltyShare > 0 && _derivativeRoyaltyShare < 10000, "ECF: Derivative royalty share must be between 1 and 9999 for derivatives");
            derivativeLinks[_parentIpId].push(nextIpId);
        } else {
            require(_derivativeRoyaltyShare == 0, "ECF: Derivative royalty share only applicable for derivative IPs");
        }

        uint256 currentIpId = nextIpId++;
        IPAsset storage newIP = ipAssets[currentIpId];
        newIP.ipId = currentIpId;
        newIP.metadataHash = _metadataHash;
        newIP.creationTimestamp = block.timestamp;
        newIP.contributors = _contributors; // Store the list for iteration
        newIP.totalShares = totalShares;
        newIP.parentIpId = _parentIpId;
        newIP.derivativeRoyaltyShare = _derivativeRoyaltyShare;
        newIP.isActive = true;
        newIP.pendingLicenseFees = 0;

        for (uint256 i = 0; i < _contributors.length; i++) {
            newIP.royaltyShares[_contributors[i]] = _shares[i];
        }

        emit IPAssetMinted(currentIpId, msg.sender, _metadataHash, _parentIpId);
    }

    /**
     * @dev Allows authorized contributors to update the IP's associated content hash (e.g., after a revision).
     * Requires the caller to be a contributor of the IP.
     * @param _ipId The ID of the IPAsset to update.
     * @param _newMetadataHash The new IPFS hash or similar.
     */
    function updateIPMetadataHash(uint256 _ipId, string memory _newMetadataHash) external onlyIPContributor(_ipId) {
        require(ipAssets[_ipId].isActive, "ECF: IPAsset is not active");
        ipAssets[_ipId].metadataHash = _newMetadataHash;
        emit IPMetadataUpdated(_ipId, _newMetadataHash, msg.sender);
    }

    /**
     * @dev Registers an existing external NFT as an EtherealCanvas IPAsset.
     * This allows external NFTs to leverage EtherealCanvas's licensing and royalty features.
     * The `metadataHash` should point to the content that this external NFT represents.
     * The EOA calling this function becomes the initial contributor(s) if not specified otherwise.
     * @param _externalNFTContract Address of the external NFT contract (e.g., ERC721).
     * @param _externalTokenId Token ID of the external NFT.
     * @param _metadataHash IPFS hash for the content this external NFT represents.
     * @param _contributors Addresses of the initial creators/owners in this system.
     * @param _shares Percentage shares for each contributor (e.g., 5000 for 50%). Must sum to 10000.
     */
    function registerExternalIPAsset(
        address _externalNFTContract,
        uint256 _externalTokenId,
        string memory _metadataHash,
        address[] memory _contributors,
        uint256[] memory _shares
    ) external {
        require(_externalNFTContract != address(0), "ECF: Invalid external NFT contract address");
        require(externalNFTtoIPId[_externalNFTContract][_externalTokenId] == 0, "ECF: External NFT already registered");
        require(_contributors.length > 0, "ECF: Must have at least one contributor");
        require(_contributors.length == _shares.length, "ECF: Contributors and shares arrays must be of equal length");

        uint256 totalShares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares += _shares[i];
        }
        require(totalShares == 10000, "ECF: Total shares must sum to 10000 (100%)");

        uint256 currentIpId = nextIpId++;
        IPAsset storage newIP = ipAssets[currentIpId];
        newIP.ipId = currentIpId;
        newIP.metadataHash = _metadataHash;
        newIP.creationTimestamp = block.timestamp;
        newIP.contributors = _contributors; // Store the list for iteration
        newIP.totalShares = totalShares;
        newIP.parentIpId = 0; // External NFTs are treated as original in this system context
        newIP.derivativeRoyaltyShare = 0;
        newIP.isActive = true;
        newIP.pendingLicenseFees = 0;

        for (uint256 i = 0; i < _contributors.length; i++) {
            newIP.royaltyShares[_contributors[i]] = _shares[i];
        }

        externalNFTtoIPId[_externalNFTContract][_externalTokenId] = currentIpId;
        emit ExternalIPAssetRegistered(currentIpId, _externalNFTContract, _externalTokenId);
    }

    /**
     * @dev Retrieves comprehensive details of an IPAsset.
     * @param _ipId The ID of the IPAsset.
     * @return tuple (ipId, metadataHash, creationTimestamp, parentIpId, derivativeRoyaltyShare, isActive, pendingLicenseFees)
     */
    function getIPAssetDetails(uint256 _ipId)
        external
        view
        returns (
            uint256 ipId,
            string memory metadataHash,
            uint256 creationTimestamp,
            uint256 parentIpId,
            uint256 derivativeRoyaltyShare,
            bool isActive,
            uint256 pendingLicenseFees
        )
    {
        require(ipAssets[_ipId].ipId != 0, "ECF: IPAsset does not exist");
        IPAsset storage ip = ipAssets[_ipId];
        return (ip.ipId, ip.metadataHash, ip.creationTimestamp, ip.parentIpId, ip.derivativeRoyaltyShare, ip.isActive, ip.pendingLicenseFees);
    }

    /**
     * @dev Returns the current royalty share for a specific contributor on an IPAsset.
     * @param _ipId The ID of the IPAsset.
     * @param _contributor The address of the contributor.
     * @return The royalty share percentage (e.g., 5000 for 50%).
     */
    function getContributorShare(uint256 _ipId, address _contributor) external view returns (uint256) {
        require(ipAssets[_ipId].ipId != 0, "ECF: IPAsset does not exist");
        return ipAssets[_ipId].royaltyShares[_contributor];
    }

    // --- II. Contributor & Royalty Management ---

    /**
     * @dev Initiates a proposal to change contributor royalty splits for an IPAsset.
     * Requires the caller to be a current contributor of the IP.
     * @param _ipId The ID of the IPAsset.
     * @param _newContributors Addresses of the proposed new contributors (can include existing ones).
     * @param _newShares Proposed percentage shares for each contributor. Must sum to 10000.
     * @return The ID of the new share update proposal.
     */
    function proposeShareUpdate(
        uint256 _ipId,
        address[] memory _newContributors,
        uint256[] memory _newShares
    ) external onlyIPContributor(_ipId) returns (uint256) {
        require(ipAssets[_ipId].isActive, "ECF: IPAsset is not active");
        require(_newContributors.length > 0, "ECF: Must have at least one contributor in the proposal");
        require(_newContributors.length == _newShares.length, "ECF: Contributors and shares arrays must be of equal length");

        uint256 totalProposedShares = 0;
        for (uint256 i = 0; i < _newShares.length; i++) {
            totalProposedShares += _newShares[i];
        }
        require(totalProposedShares == 10000, "ECF: Total proposed shares must sum to 10000 (100%)");

        uint256 proposalId = nextShareProposalId++;
        ShareUpdateProposal storage proposal = shareUpdateProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.ipId = _ipId;
        proposal.newContributorsList = _newContributors;
        proposal.totalProposedShares = totalProposedShares;
        proposal.creationTimestamp = block.timestamp;
        proposal.totalContributorsAtProposal = ipAssets[_ipId].contributors.length; // Snapshot
        proposal.executed = false;
        proposal.rejected = false;

        for (uint256 i = 0; i < _newContributors.length; i++) {
            proposal.newShares[_newContributors[i]] = _newShares[i];
        }

        emit RoyaltySharesProposed(proposalId, _ipId, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows contributors of an IPAsset to vote on a proposed royalty split change.
     * Requires the caller to be a contributor of the IP.
     * A simple majority (e.g., >50%) of existing contributors' votes is required for passing.
     * @param _proposalId The ID of the share update proposal.
     * @param _for True to vote "for", false to vote "against".
     */
    function voteOnShareUpdate(uint256 _proposalId, bool _for) external {
        ShareUpdateProposal storage proposal = shareUpdateProposals[_proposalId];
        require(proposal.proposalId != 0, "ECF: Proposal does not exist");
        require(ipAssets[proposal.ipId].ipId != 0, "ECF: Invalid IP ID in proposal");
        require(!proposal.executed && !proposal.rejected, "ECF: Proposal already executed or rejected");
        require(proposal.creationTimestamp + 7 days > block.timestamp, "ECF: Voting period has ended (7 days)"); // Example voting period

        bool isCurrentContributor = false;
        for (uint256 i = 0; i < ipAssets[proposal.ipId].contributors.length; i++) {
            if (ipAssets[proposal.ipId].contributors[i] == msg.sender) {
                isCurrentContributor = true;
                break;
            }
        }
        require(isCurrentContributor, "ECF: Only current contributors can vote on share updates for this IP");
        require(!proposal.hasVoted[msg.sender], "ECF: Contributor has already voted");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        }

        emit RoyaltyShareVoted(_proposalId, proposal.ipId, msg.sender, _for);
    }

    /**
     * @dev Executes a passed royalty share update proposal.
     * Requires a simple majority of contributors to have voted "for".
     * Any contributor can finalize the proposal after the voting period ends.
     * @param _proposalId The ID of the share update proposal.
     */
    function finalizeShareUpdate(uint256 _proposalId) external {
        ShareUpdateProposal storage proposal = shareUpdateProposals[_proposalId];
        require(proposal.proposalId != 0, "ECF: Proposal does not exist");
        require(!proposal.executed && !proposal.rejected, "ECF: Proposal already executed or rejected");
        require(block.timestamp >= proposal.creationTimestamp + 7 days, "ECF: Voting period is still active"); // Ensure voting period has ended

        // Simple majority: More than 50% of the contributors at the time of proposal creation voted "for"
        if (proposal.votesFor * 2 > proposal.totalContributorsAtProposal) {
            IPAsset storage ip = ipAssets[proposal.ipId];

            // Clear existing shares and contributors list
            for (uint256 i = 0; i < ip.contributors.length; i++) {
                ip.royaltyShares[ip.contributors[i]] = 0;
            }
            delete ip.contributors; // Clear the dynamic array

            // Apply new shares and contributors
            ip.contributors = proposal.newContributorsList; // Replace with the proposed list
            for (uint252 i = 0; i < proposal.newContributorsList.length; i++) {
                ip.royaltyShares[proposal.newContributorsList[i]] = proposal.newShares[proposal.newContributorsList[i]];
            }
            ip.totalShares = proposal.totalProposedShares; // Should be 10000

            proposal.executed = true;
            emit RoyaltySharesUpdated(proposal.ipId, _proposalId);
        } else {
            proposal.rejected = true;
            // Optionally emit a rejection event
        }
    }

    /**
     * @dev Triggers the distribution of collected license fees to an IPAsset's contributors.
     * Can be called by anyone. It moves funds from the contract's `pendingLicenseFees` for that IP
     * to the `earnedRoyalties` balance of each contributor.
     * Handles derivative royalty splits by sending a portion to the parent IP's `pendingLicenseFees`.
     * @param _ipId The ID of the IPAsset.
     */
    function distributeRoyalties(uint256 _ipId) external {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.ipId != 0, "ECF: IPAsset does not exist");
        require(ip.isActive, "ECF: IPAsset is not active");
        require(ip.pendingLicenseFees > 0, "ECF: No royalties to distribute for this IP");

        uint256 amountToDistribute = ip.pendingLicenseFees;
        ip.pendingLicenseFees = 0; // Reset for next cycle

        uint256 amountToParent = 0;

        // Handle derivative royalty split first
        if (ip.parentIpId != 0 && ip.derivativeRoyaltyShare > 0) {
            amountToParent = (amountToDistribute * ip.derivativeRoyaltyShare) / 10000;
            // Add to parent IP's pending fees for its contributors
            ipAssets[ip.parentIpId].pendingLicenseFees += amountToParent;
            amountToDistribute -= amountToParent;
        }

        for (uint256 i = 0; i < ip.contributors.length; i++) {
            address contributor = ip.contributors[i];
            uint256 shareAmount = (amountToDistribute * ip.royaltyShares[contributor]) / ip.totalShares;
            earnedRoyalties[contributor] += shareAmount;
        }

        emit RoyaltiesDistributed(_ipId, amountToDistribute, amountToParent);
    }

    /**
     * @dev Allows individual contributors to withdraw their accumulated royalties.
     */
    function withdrawEarnedRoyalties() external {
        uint256 amount = earnedRoyalties[msg.sender];
        require(amount > 0, "ECF: No royalties to withdraw");
        earnedRoyalties[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ECF: Failed to withdraw royalties");

        emit RoyaltiesWithdrawn(msg.sender, amount);
    }

    // --- III. Licensing & Monetization ---

    /**
     * @dev Creates a new licensing offer for an IPAsset.
     * Requires the caller to be a contributor of the IP.
     * @param _ipId The ID of the IPAsset.
     * @param _price Price of the license in Wei.
     * @param _duration Duration of the license in seconds.
     * @param _usageRightsHash IPFS hash for detailed terms (e.g., commercial, non-commercial).
     * @return The ID of the new license offer.
     */
    function createLicenseOffer(
        uint256 _ipId,
        uint256 _price,
        uint256 _duration,
        string memory _usageRightsHash
    ) external onlyIPContributor(_ipId) returns (uint256) {
        require(ipAssets[_ipId].isActive, "ECF: IPAsset is not active");
        require(_price > 0, "ECF: License price must be greater than zero");
        require(_duration > 0, "ECF: License duration must be greater than zero");

        uint256 offerId = nextLicenseOfferId++;
        LicenseOffer storage newOffer = licenseOffers[offerId];
        newOffer.offerId = offerId;
        newOffer.ipId = _ipId;
        newOffer.licensor = msg.sender; // The specific contributor who created the offer
        newOffer.price = _price;
        newOffer.duration = _duration;
        newOffer.usageRightsHash = _usageRightsHash;
        newOffer.isActive = true;
        newOffer.createdTimestamp = block.timestamp;

        emit LicenseOfferCreated(offerId, _ipId, msg.sender, _price, _duration);
        return offerId;
    }

    /**
     * @dev Accepts an existing license offer, paying the fee and activating the license.
     * The `msg.value` must match the offer price adjusted by the global multiplier.
     * @param _offerId The ID of the license offer to accept.
     * @return The ID of the new active license.
     */
    function acceptLicenseOffer(uint256 _offerId) external payable returns (uint256) {
        LicenseOffer storage offer = licenseOffers[_offerId];
        require(offer.offerId != 0, "ECF: License offer does not exist");
        require(offer.isActive, "ECF: License offer is not active or has been revoked");
        require(ipAssets[offer.ipId].isActive, "ECF: IPAsset associated with this offer is not active");

        uint256 adjustedPrice = (offer.price * licenseFeeMultiplier) / 10000;
        require(msg.value == adjustedPrice, "ECF: Incorrect payment amount");

        uint256 licenseId = nextActiveLicenseId++;
        ActiveLicense storage newLicense = activeLicenses[licenseId];
        newLicense.licenseId = licenseId;
        newLicense.ipId = offer.ipId;
        newLicense.offerId = _offerId;
        newLicense.licensee = msg.sender;
        newLicense.startDate = block.timestamp;
        newLicense.endDate = block.timestamp + offer.duration;
        newLicense.paymentAmount = msg.value;
        newLicense.usageRightsHash = offer.usageRightsHash;
        newLicense.isActive = true;

        // Add the payment to the IP's pending license fees for distribution
        ipAssets[offer.ipId].pendingLicenseFees += msg.value;

        emit LicenseOfferAccepted(licenseId, offer.ipId, msg.sender, msg.value);
        return licenseId;
    }

    /**
     * @dev Allows the contributor who created the license offer to revoke it if it hasn't been accepted
     * or if there are no active licenses currently linked to it.
     * @param _offerId The ID of the license offer to revoke.
     */
    function revokeLicenseOffer(uint256 _offerId) external onlyLicenseOfferCreator(_offerId) {
        LicenseOffer storage offer = licenseOffers[_offerId];
        require(offer.isActive, "ECF: License offer is already inactive");

        // For simplicity, we assume an offer can be revoked if no active licenses are currently linked.
        // A more complex system would track this explicitly, possibly by iterating activeLicenses.
        // For this prototype, we'll allow revocation if it hasn't been accepted yet.
        // If there's an active license, the offer is merely marked inactive but the license persists.
        offer.isActive = false;
        emit LicenseOfferRevoked(_offerId);
    }

    /**
     * @dev Allows an IP contributor to terminate an active license due to a breach of terms.
     * Requires the caller to be a contributor of the IP.
     * @param _licenseId The ID of the active license to terminate.
     * @param _reasonHash IPFS hash for detailed reason of termination.
     */
    function terminateActiveLicense(uint256 _licenseId, string memory _reasonHash) external onlyIPContributor(activeLicenses[_licenseId].ipId) {
        ActiveLicense storage license = activeLicenses[_licenseId];
        require(license.licenseId != 0, "ECF: Active license does not exist");
        require(license.isActive, "ECF: License is already inactive");

        license.isActive = false;
        emit ActiveLicenseTerminated(_licenseId, license.ipId, _reasonHash);
    }

    /**
     * @dev Allows a licensee to renew an expiring active license.
     * The renewal price and duration will be based on the original offer.
     * @param _licenseId The ID of the active license to renew.
     */
    function renewActiveLicense(uint256 _licenseId) external payable {
        ActiveLicense storage license = activeLicenses[_licenseId];
        require(license.licenseId != 0, "ECF: Active license does not exist");
        require(license.isActive, "ECF: License is not active and cannot be renewed");
        require(license.licensee == msg.sender, "ECF: Only the original licensee can renew");
        require(license.endDate < block.timestamp + 30 days, "ECF: License not close enough to expiry for renewal (e.g., within 30 days)"); // Example condition

        LicenseOffer storage originalOffer = licenseOffers[license.offerId];
        require(originalOffer.offerId != 0, "ECF: Original offer not found for renewal");
        require(originalOffer.isActive, "ECF: Original offer is no longer active for renewal"); // The *offer* must still be active for renewal

        uint256 adjustedPrice = (originalOffer.price * licenseFeeMultiplier) / 10000;
        require(msg.value == adjustedPrice, "ECF: Incorrect payment amount for renewal");

        license.endDate = license.endDate + originalOffer.duration; // Extend duration
        license.paymentAmount += msg.value; // Add renewal payment
        ipAssets[license.ipId].pendingLicenseFees += msg.value; // Add to IP's pending fees

        emit ActiveLicenseRenewed(_licenseId, license.endDate, msg.value);
    }

    /**
     * @dev Retrieves details of a specific license offer or active license.
     * @param _id The ID of the active license or license offer.
     * @return tuple (ipId, partyAddress, amount, timeInfo, usageRightsHash, activeStatus, licenseType (0=offer, 1=active))
     *         timeInfo will be `duration` for offers and `endDate` for active licenses.
     */
    function getLicenseDetails(uint256 _id)
        external
        view
        returns (
            uint256 ipId,
            address partyAddress,
            uint256 amount,
            uint256 timeInfo,
            string memory usageRightsHash,
            bool activeStatus,
            uint256 licenseType // 0 for offer, 1 for active license
        )
    {
        if (activeLicenses[_id].licenseId != 0) {
            ActiveLicense storage al = activeLicenses[_id];
            return (al.ipId, al.licensee, al.paymentAmount, al.endDate, al.usageRightsHash, al.isActive, 1);
        } else if (licenseOffers[_id].offerId != 0) {
            LicenseOffer storage lo = licenseOffers[_id];
            return (lo.ipId, lo.licensor, lo.price, lo.duration, lo.usageRightsHash, lo.isActive, 0);
        } else {
            revert("ECF: License or Offer not found");
        }
    }

    // --- IV. Derivative Work Tracking ---

    // `mintDerivativeIPAsset` functionality is now integrated into `mintIPAsset` using `_parentIpId` and `_derivativeRoyaltyShare` parameters.

    /**
     * @dev Retrieves all derivative IP assets linked to a parent IPAsset.
     * @param _parentIpId The ID of the parent IPAsset.
     * @return An array of IP IDs that are derivatives of the parent.
     */
    function getDerivativeLinks(uint256 _parentIpId) external view returns (uint256[] memory) {
        require(ipAssets[_parentIpId].ipId != 0, "ECF: Parent IPAsset does not exist");
        return derivativeLinks[_parentIpId];
    }

    // --- V. Governance & System Management ---

    /**
     * @dev Initiates a vote to remove or flag an IPAsset (e.g., for copyright infringement or harmful content).
     * Any IP contributor can propose removal.
     * @param _ipId The ID of the IPAsset to propose for removal.
     * @param _reasonHash IPFS hash for detailed reason.
     * @return The ID of the new IP removal proposal.
     */
    function proposeIPRemoval(uint256 _ipId, string memory _reasonHash) external onlyIPContributor(_ipId) returns (uint256) {
        require(ipAssets[_ipId].isActive, "ECF: IPAsset is already inactive or under removal process");

        uint256 proposalId = nextRemovalProposalId++;
        IPRemovalProposal storage proposal = ipRemovalProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.ipId = _ipId;
        proposal.proposer = msg.sender;
        proposal.reasonHash = _reasonHash;
        proposal.creationTimestamp = block.timestamp;
        // Simplified: total voters is count of all active IPs in the system.
        // In a real system, this would be a defined DAO or governance committee with explicit membership.
        proposal.totalVotersAtProposal = nextIpId - 1; // Approximate number of IPs/voters in the system
        proposal.executed = false;
        proposal.rejected = false;

        emit IPRemovalProposed(proposalId, _ipId, msg.sender, _reasonHash);
        return proposalId;
    }

    /**
     * @dev Allows authorized voters (e.g., any IP contributor in the system, or a specific committee)
     * to vote on an IP removal proposal.
     * @param _proposalId The ID of the IP removal proposal.
     * @param _for True to vote "for" removal, false to vote "against".
     */
    function voteOnIPRemoval(uint256 _proposalId, bool _for) external {
        IPRemovalProposal storage proposal = ipRemovalProposals[_proposalId];
        require(proposal.proposalId != 0, "ECF: Proposal does not exist");
        require(!proposal.executed && !proposal.rejected, "ECF: Proposal already executed or rejected");
        require(proposal.creationTimestamp + 7 days > block.timestamp, "ECF: Voting period has ended (7 days)"); // Example voting period

        // Simplified: Any address that has contributed to an IP in this system can vote on removals.
        // In a more complex system, this would be `onlyGoverningCouncil` or `onlyStakedVoter`.
        bool canVote = false;
        // Iterate through all IPs to check if msg.sender is a contributor to any active IP
        for (uint256 i = 1; i < nextIpId; i++) {
            if (ipAssets[i].ipId != 0 && ipAssets[i].isActive) {
                for (uint256 j = 0; j < ipAssets[i].contributors.length; j++) {
                    if (ipAssets[i].contributors[j] == msg.sender) {
                        canVote = true;
                        break;
                    }
                }
            }
            if (canVote) break;
        }
        require(canVote, "ECF: Only a contributor of any active IP in this system can vote on removal");
        require(!proposal.hasVoted[msg.sender], "ECF: Voter has already voted");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.votesFor++;
        }

        emit IPRemovalVoted(_proposalId, proposal.ipId, msg.sender, _for);
    }

    /**
     * @dev Executes a passed IP removal proposal, marking the IP as inactive.
     * Requires a simple majority of votes "for" removal.
     * Any voter can finalize the proposal after the voting period ends.
     * @param _proposalId The ID of the IP removal proposal.
     */
    function finalizeIPRemoval(uint256 _proposalId) external {
        IPRemovalProposal storage proposal = ipRemovalProposals[_proposalId];
        require(proposal.proposalId != 0, "ECF: Proposal does not exist");
        require(!proposal.executed && !proposal.rejected, "ECF: Proposal already executed or rejected");
        require(block.timestamp >= proposal.creationTimestamp + 7 days, "ECF: Voting period is still active"); // Ensure voting period has ended

        // Simple majority: More than 50% of total possible votes for removal
        if (proposal.votesFor * 2 > proposal.totalVotersAtProposal) {
            ipAssets[proposal.ipId].isActive = false;
            proposal.executed = true;
            emit IPRemovalFinalized(proposal.ipId, _proposalId);
        } else {
            proposal.rejected = true;
            // Optionally emit a rejection event
        }
    }

    /**
     * @dev Sets the address of an external oracle for potential dynamic pricing or data feeds.
     * Only callable by the contract owner.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyOwner {
        require(_newOracleAddress != address(0), "ECF: Oracle address cannot be zero");
        oracleAddress = _newOracleAddress;
        emit OracleAddressSet(_newOracleAddress);
    }

    /**
     * @dev Allows the contract owner to set a global multiplier for license fees.
     * This could be used to implement dynamic pricing based on oracle data, for example.
     * @param _multiplier The new multiplier (e.g., 10000 for 1x, 12000 for 1.2x).
     */
    function setLicenseFeeMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier > 0, "ECF: Multiplier must be greater than zero");
        licenseFeeMultiplier = _multiplier;
        emit LicenseFeeMultiplierSet(_multiplier);
    }

    // --- VI. Helper/View Functions ---

    /**
     * @dev Returns the number of contributors for a given IP asset.
     * @param _ipId The ID of the IPAsset.
     * @return The count of contributors.
     */
    function getIPAssetContributorCount(uint256 _ipId) external view returns (uint256) {
        require(ipAssets[_ipId].ipId != 0, "ECF: IPAsset does not exist");
        return ipAssets[_ipId].contributors.length;
    }

    /**
     * @dev Returns the list of all contributors for a given IP asset.
     * @param _ipId The ID of the IPAsset.
     * @return An array of contributor addresses.
     */
    function getIPAssetContributors(uint256 _ipId) external view returns (address[] memory) {
        require(ipAssets[_ipId].ipId != 0, "ECF: IPAsset does not exist");
        return ipAssets[_ipId].contributors;
    }

    /**
     * @dev Returns the address of the contract deployer.
     */
    function owner() external view returns (address) {
        return owner;
    }

    // Fallback function to accept Ether
    receive() external payable {}
    fallback() external payable {}
}
```