Here's a smart contract in Solidity that implements an advanced, creative, and trendy concept, focusing on decentralized intellectual property (IP) co-creation, dynamic ownership, AI-assisted curation, and a reputation system.

This contract, named `CognitoCanvas`, aims to provide a novel framework for managing the lifecycle of digital intellectual property on-chain. It combines elements of dynamic NFTs (for IP assets), soulbound tokens (for non-transferable contributions), decentralized autonomous organizations (simplified governance), and AI oracle integration (simulated for on-chain proof of reports).

The core idea is that IP assets can be collaboratively built by multiple contributors, with their ownership shares dynamically adjusting based on their contributions' weighted value. AI oracles can review and rate IP, influencing its status and contributor reputations. Licensing and royalty distribution are handled on-chain, and a bounty system encourages further development.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
// SafeMath is included for explicit clarity, though Solidity 0.8.0+ handles overflow/underflow by default.
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 

/**
 * @title CognitoCanvas
 * @dev A Decentralized Intellectual Property (IP) Co-creation & Licensing Platform.
 *      This contract enables the collaborative creation, dynamic ownership,
 *      granular licensing, AI-assisted curation, and reputation building for digital assets.
 *      It aims to provide a novel framework for IP lifecycle management on-chain.
 */
contract CognitoCanvas is Ownable {
    using SafeMath for uint256; 

    /* =================================================================================================
     *                                   Contract Outline and Function Summary
     * =================================================================================================
     *
     * I. Core IP Management & Creation
     *    1. createIPAsset(): Registers a new IP asset, assigning the caller as its initial creator and primary contributor.
     *    2. addContribution(): Allows users to add contributions (e.g., text, code, images) to an existing IP, impacting ownership share.
     *    3. evolveIPVersion(): Creates a new, distinct version of an existing IP, linking it to its parent and maintaining lineage.
     *    4. archiveIPAsset(): Marks an IP asset as archived, preventing further contributions or new licenses.
     *
     * II. Dynamic Contribution & Ownership
     *    5. updateContributionWeight(): Adjusts a specific contributor's weight for an IP. Callable by IP owners after specific events (e.g., AI review, dispute resolution).
     *    6. getIPOwnersAndShares(): Calculates and returns the current proportional ownership shares for all contributors to an IP.
     *    7. getContributorIPs(): Retrieves a list of all IP assets a specific contributor has contributed to.
     *
     * III. Licensing & Royalties
     *    8. defineLicenseTerms(): Allows an IP owner to define custom, granular licensing terms for their asset.
     *    9. acquireLicense(): Enables a user to purchase a license for an IP based on predefined terms, paying the specified royalty fee.
     *    10. revokeLicense(): Allows an IP owner to revoke an active license under specified conditions (e.g., breach of terms).
     *    11. distributeRoyalties(): Triggers the distribution of collected license fees for a specific IP to its contributors, based on their dynamic ownership shares.
     *
     * IV. AI-Assisted Curation & Verification (Simulated Oracle)
     *    12. requestAICuration(): Submits an IP asset for review by a designated AI oracle (e.g., for originality, quality, compliance).
     *    13. submitAICurationReport(): Callable only by the designated AI oracle, submits a comprehensive report for a given IP.
     *    14. applyAICurationFeedback(): Allows the IP owner to update the IP's metadata, content, quality score, or status based on an AI report.
     *
     * V. Reputation & Governance (Simplified)
     *    15. updateReputationScore(): Adjusts a contributor's reputation score, which can be influenced by successful IPs, AI reviews, or dispute resolutions. (Owner-only for simplification)
     *    16. proposeIPStatusChange(): Allows a user to propose a change in an IP's status (e.g., from Draft to Published).
     *    17. voteOnIPStatusChange(): Enables users to vote on a pending IP status change proposal.
     *    18. resolveDispute(): An admin/arbiter function to formally resolve disputes related to an IP, potentially affecting contributor reputations. (Owner-only for simplification)
     *
     * VI. Funding & Bounties
     *    19. fundIPDevelopment(): Allows any user to contribute funds (ETH) directly to support the development or maintenance of a specific IP asset.
     *    20. createBountyForIPImprovement(): An IP owner or community member can create a bounty for specific improvements or tasks related to an IP.
     *    21. claimBounty(): A contributor can claim a bounty by providing proof of work, which is then reviewed (off-chain or by admin/DAO).
     *    22. withdrawFunds(): Admin function to withdraw platform fees or unallocated funds. (Owner-only)
     *
     * VII. Helper/View Functions
     *    23. getIPDetails(): Retrieves all core details of a specific IP asset.
     *    24. getLicenseTermDetails(): Retrieves the details of a specific license term for an IP.
     *    25. getActiveLicenseDetails(): Retrieves details of an active license.
     *    26. getIPContributions(): Retrieves a list of all contributions for a given IP.
     *    27. getAICurationReports(): Retrieves a list of all AI curation reports for a given IP.
     * =================================================================================================
     */

    /* ================================== Custom Errors =================================== */
    error CognitoCanvas__IPNotFound(uint256 ipId);
    error CognitoCanvas__ContributionNotFound(uint256 ipId, address contributor);
    error CognitoCanvas__LicenseTermNotFound(uint256 ipId, uint256 licenseTermId);
    error CognitoCanvas__ActiveLicenseNotFound(uint256 ipId, uint256 licenseId);
    error CognitoCanvas__InsufficientFunds();
    error CognitoCanvas__Unauthorized();
    error CognitoCanvas__InvalidIPStatus();
    error CognitoCanvas__IPNotPublished();
    error CognitoCanvas__IPArchived();
    error CognitoCanvas__LicenseExpired();
    error CognitoCanvas__LicenseAlreadyActive();
    error CognitoCanvas__AIReportPending();
    error CognitoCanvas__InvalidAIOracle();
    error CognitoCanvas__BountyNotFound(uint256 bountyId);
    error CognitoCanvas__BountyNotActive();
    error CognitoCanvas__BountyAlreadyClaimed();
    error CognitoCanvas__NoRoyaltiesToDistribute();
    error CognitoCanvas__NoContributionsFound(uint256 ipId);
    error CognitoCanvas__SelfContributionNotAllowed();
    error CognitoCanvas__InvalidWeight();
    error CognitoCanvas__InvalidReputationDelta();
    error CognitoCanvas__LicenseTermsMismatch();
    error CognitoCanvas__AlreadyVoted();
    error CognitoCanvas__RoyaltyDistributionFailed();
    error CognitoCanvas__WithdrawalFailed();


    /* ======================================== Enums ========================================= */
    enum IPStatus {
        Draft,
        Published,
        Reviewed,
        Archived,
        Disputed,
        AwaitingAICuration // New status for clarity
    }

    enum ContributionType {
        Idea,
        Text,
        Image,
        Code,
        Audio,
        Video,
        Design,
        ResearchData, // Added for DeSci aspect
        Other
    }

    enum LicenseStatus {
        Active,
        Revoked,
        Expired
    }

    /* ======================================= Structs ======================================== */
    struct IPAsset {
        uint256 id;
        address creator; // Initial creator of the IP
        uint256 parentIpId; // For versioning (0 if original)
        bytes32 metadataHash; // IPFS hash or similar for descriptive metadata
        bytes32 contentHash; // IPFS hash or similar for the actual content
        uint256 creationTimestamp;
        uint224 lastUpdateTimestamp; // Reduced size for gas efficiency, sufficient for timestamps up to ~58 trillion years
        IPStatus status;
        bool isSoulbound; // If true, IP ownership/contribution is non-transferable (mimics SBT property)
        uint256 aiQualityScore; // Score from AI curation, e.g., 0-100
        bytes32 lastAICurationReportHash; // Hash of the latest AI report
        bool aiReportPending; // True if an AI report has been requested but not yet submitted
        uint256 collectedRoyalties; // Total royalties collected for this IP
    }

    struct IPContribution {
        address contributor;
        bytes32 contributionHash; // Hash of the specific contribution content/metadata
        ContributionType contributionType;
        uint256 timestamp;
        uint256 weight; // Represents the significance of this contribution to the IP
    }

    struct LicenseTerm {
        uint256 id;
        string name;
        uint256 royaltyFeeBasisPoints; // e.g., 100 = 1% (10000 basis points = 100%)
        uint256 durationSeconds; // 0 for perpetual
        bytes32 usageRestrictionsHash; // Hash of a document outlining restrictions
        uint256 creationTimestamp;
    }

    struct ActiveLicense {
        uint256 id;
        uint256 ipId;
        address licensee;
        uint256 licenseTermId;
        uint256 acquisitionTimestamp;
        uint256 expiryTimestamp; // 0 if perpetual
        LicenseStatus status;
    }

    struct AICurationReport {
        bytes32 reportHash;
        uint256 qualityScore;
        bool isOriginal;
        string feedbackSummary;
        uint256 timestamp;
    }

    struct Bounty {
        uint256 id;
        uint256 ipId;
        address creator;
        bytes32 descriptionHash;
        uint256 amount; // Amount in Wei
        bool isActive;
        address claimer;
        bytes32 proofOfWorkHash; // Hash submitted by claimer
        uint256 claimTimestamp;
        bool claimed; // True if claimed, awaiting review/payout
    }

    /* ====================================== State Variables ===================================== */
    uint256 public nextIpId = 1;
    uint256 public nextLicenseTermId = 1;
    uint256 public nextLicenseId = 1;
    uint256 public nextBountyId = 1;

    // Core IP data
    mapping(uint256 => IPAsset) public ipAssets;
    mapping(uint256 => IPContribution[]) private _ipContributions; // ipId => list of contributions

    // Licensing data
    mapping(uint256 => mapping(uint256 => LicenseTerm)) private _ipLicenseTerms; // ipId => licenseTermId => LicenseTerm
    mapping(uint256 => mapping(uint256 => ActiveLicense)) private _activeLicenses; // ipId => licenseId => ActiveLicense
    mapping(address => uint256[]) private _contributorToIPs; // contributor => list of ipIds they contributed to

    // AI Curation data
    address public aiOracleAddress; // Address authorized to submit AI reports
    mapping(uint256 => AICurationReport[]) private _aiReports; // ipId => list of AICurationReports

    // Reputation data
    mapping(address => uint256) public reputationScores;

    // Governance/Voting data (simplified)
    // ipId => proposedStatus => voterAddress => hasVoted
    mapping(uint256 => mapping(IPStatus => mapping(address => bool))) private _ipStatusVotes;
    // ipId => proposedStatus => voteCountFor
    mapping(uint256 => mapping(IPStatus => uint256)) private _ipStatusVoteCountsFor;
    // ipId => proposedStatus => voteCountAgainst
    mapping(uint256 => mapping(IPStatus => uint256)) private _ipStatusVoteCountsAgainst;
    // ipId => proposedStatus => proposalTimestamp
    mapping(uint256 => mapping(IPStatus => uint256)) private _ipStatusProposalTimestamp;

    // Bounty data
    mapping(uint256 => Bounty) private _bounties;
    mapping(uint256 => uint256[]) private _ipBounties; // ipId => list of bounty IDs

    // Platform fees
    uint256 public platformFeeBasisPoints; // e.g., 500 = 5%

    /* ======================================== Events ======================================== */
    event IPAssetCreated(uint256 indexed ipId, address indexed creator, bytes32 metadataHash, bool isSoulbound);
    event ContributionAdded(uint256 indexed ipId, address indexed contributor, ContributionType contributionType, uint256 weight);
    event ContributionWeightUpdated(uint256 indexed ipId, address indexed contributor, uint256 newWeight);
    event IPVersionEvolved(uint256 indexed parentIpId, uint256 indexed newIpId, bytes32 newMetadataHash);
    event IPAssetArchived(uint256 indexed ipId);

    event LicenseTermDefined(uint256 indexed ipId, uint256 indexed licenseTermId, string name, uint256 royaltyFeeBasisPoints);
    event LicenseAcquired(uint256 indexed ipId, uint256 indexed licenseId, address indexed licensee, uint256 licenseTermId, uint256 royaltyPaid);
    event LicenseRevoked(uint256 indexed ipId, uint256 indexed licenseId, address indexed revoker);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 distributedAmount);

    event AICurationRequested(uint256 indexed ipId, address indexed requester);
    event AICurationReportSubmitted(uint256 indexed ipId, bytes32 reportHash, uint256 qualityScore, bool isOriginal);
    event AICurationFeedbackApplied(uint256 indexed ipId, bytes32 newMetadataHash, IPStatus newStatus);

    event ReputationScoreUpdated(address indexed contributor, int256 delta, uint256 newScore);
    event IPStatusChangeProposed(uint256 indexed ipId, IPStatus indexed newStatus, address indexed proposer);
    event IPStatusVoteCast(uint256 indexed ipId, IPStatus indexed newStatus, address indexed voter, bool _forChange);
    event IPStatusChanged(uint256 indexed ipId, IPStatus oldStatus, IPStatus newStatus);
    event DisputeResolved(uint256 indexed ipId, address indexed winningParty, bytes32 resolutionDetailsHash);

    event IPFunded(uint256 indexed ipId, address indexed funder, uint256 amount);
    event BountyCreated(uint256 indexed ipId, uint256 indexed bountyId, address indexed creator, uint256 amount);
    event BountyClaimed(uint256 indexed bountyId, address indexed claimer, uint256 amount);

    event FundsWithdrawn(address indexed to, uint256 amount);

    /* ====================================== Constructor ===================================== */
    constructor(address _aiOracleAddress, uint256 _platformFeeBasisPoints) Ownable() {
        if (_aiOracleAddress == address(0)) revert CognitoCanvas__InvalidAIOracle();
        if (_platformFeeBasisPoints > 10000) revert CognitoCanvas__InvalidWeight(); // Max 100% (10000 basis points)

        aiOracleAddress = _aiOracleAddress;
        platformFeeBasisPoints = _platformFeeBasisPoints;
    }

    /* ================================== Modifiers & Internal Functions ================================= */

    /**
     * @dev Modifier to restrict access to functions to an address that is a contributor to the specified IP.
     *      Being an IP owner implies being a contributor.
     * @param _ipId The ID of the IP asset.
     */
    modifier onlyIPContributor(uint256 _ipId) {
        bool isContributor = false;
        for (uint256 i = 0; i < _ipContributions[_ipId].length; i++) {
            if (_ipContributions[_ipId][i].contributor == msg.sender) {
                isContributor = true;
                break;
            }
        }
        if (!isContributor) revert CognitoCanvas__Unauthorized();
        _;
    }

    /**
     * @dev Modifier to restrict access to functions to an address that is considered an owner of the specified IP.
     *      Ownership is dynamic, calculated by `getIPOwnersAndShares`.
     * @param _ipId The ID of the IP asset.
     */
    modifier onlyIPOwner(uint256 _ipId) {
        (address[] memory owners, ) = getIPOwnersAndShares(_ipId);
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        if (!isOwner) revert CognitoCanvas__Unauthorized();
        _;
    }

    /**
     * @dev Modifier to restrict access to functions to the designated AI oracle address.
     */
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) revert CognitoCanvas__InvalidAIOracle();
        _;
    }

    /**
     * @dev Internal function to calculate the total weight of all contributions for a given IP.
     * @param _ipId The ID of the IP asset.
     * @return The sum of all contribution weights.
     */
    function _getIPTotalWeight(uint256 _ipId) internal view returns (uint256) {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _ipContributions[_ipId].length; i++) {
            totalWeight = totalWeight.add(_ipContributions[_ipId][i].weight);
        }
        return totalWeight;
    }

    /**
     * @dev Internal function to add an IP ID to a contributor's list of IPs.
     *      Ensures no duplicates are added.
     * @param _contributor The address of the contributor.
     * @param _ipId The ID of the IP asset.
     */
    function _addContributorToIPList(address _contributor, uint256 _ipId) internal {
        bool found = false;
        for (uint256 i = 0; i < _contributorToIPs[_contributor].length; i++) {
            if (_contributorToIPs[_contributor][i] == _ipId) {
                found = true;
                break;
            }
        }
        if (!found) {
            _contributorToIPs[_contributor].push(_ipId);
        }
    }

    /**
     * @dev Helper to append to a dynamic array in memory (for view functions).
     * @param arr The original array.
     * @param item The item to append.
     * @return A new array with the item appended.
     */
    function _appendAddress(address[] memory arr, address item) internal pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint256 i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = item;
        return newArr;
    }

    /* =========================== I. Core IP Management & Creation =========================== */

    /**
     * @dev Registers a new IP asset, assigning the caller as its initial creator and primary contributor.
     * @param _metadataHash IPFS hash or similar for descriptive metadata of the IP.
     * @param _initialContentHash IPFS hash or similar for the initial content of the IP.
     * @param _isSoulbound If true, the IP's ownership/contribution is non-transferable (mimics SBT).
     * @return The ID of the newly created IP asset.
     */
    function createIPAsset(
        bytes32 _metadataHash,
        bytes32 _initialContentHash,
        bool _isSoulbound
    ) external returns (uint256) {
        uint256 ipId = nextIpId++;
        uint256 currentTimestamp = block.timestamp;

        ipAssets[ipId] = IPAsset({
            id: ipId,
            creator: msg.sender,
            parentIpId: 0, // 0 indicates an original IP
            metadataHash: _metadataHash,
            contentHash: _initialContentHash,
            creationTimestamp: currentTimestamp,
            lastUpdateTimestamp: uint224(currentTimestamp),
            status: IPStatus.Draft,
            isSoulbound: _isSoulbound,
            aiQualityScore: 0,
            lastAICurationReportHash: bytes32(0),
            aiReportPending: false,
            collectedRoyalties: 0
        });

        // Add creator as the initial contributor with an initial weight
        _ipContributions[ipId].push(
            IPContribution({
                contributor: msg.sender,
                contributionHash: _initialContentHash, // Initial content acts as initial contribution
                contributionType: ContributionType.Other, // Can be specified or default
                timestamp: currentTimestamp,
                weight: 100 // Initial weight for the creator, can be adjusted later
            })
        );
        _addContributorToIPList(msg.sender, ipId);

        emit IPAssetCreated(ipId, msg.sender, _metadataHash, _isSoulbound);
        emit ContributionAdded(ipId, msg.sender, ContributionType.Other, 100);
        return ipId;
    }

    /**
     * @dev Allows users to add contributions (e.g., text, code, images) to an existing IP,
     *      impacting their ownership share based on a given initial weight.
     *      Requires the IP to not be archived.
     * @param _ipId The ID of the IP asset to contribute to.
     * @param _contributionHash IPFS hash or similar for the new contribution's content.
     * @param _contributionType The type of contribution (e.g., Text, Image, Code).
     * @param _initialWeight The initial weight assigned to this new contribution.
     */
    function addContribution(
        uint256 _ipId,
        bytes32 _contributionHash,
        ContributionType _contributionType,
        uint256 _initialWeight
    ) external {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();
        if (_initialWeight == 0) revert CognitoCanvas__InvalidWeight();

        _ipContributions[_ipId].push(
            IPContribution({
                contributor: msg.sender,
                contributionHash: _contributionHash,
                contributionType: _contributionType,
                timestamp: block.timestamp,
                weight: _initialWeight
            })
        );
        _addContributorToIPList(msg.sender, _ipId);

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit ContributionAdded(_ipId, msg.sender, _contributionType, _initialWeight);
    }

    /**
     * @dev Creates a new, distinct version of an existing IP, linking it to its parent and maintaining lineage.
     *      Only callable by an existing owner/contributor of the parent IP.
     * @param _parentIpId The ID of the IP asset to create a new version from.
     * @param _newMetadataHash IPFS hash for the new version's descriptive metadata.
     * @param _newContentHash IPFS hash for the new version's actual content.
     * @return The ID of the newly created IP version.
     */
    function evolveIPVersion(
        uint256 _parentIpId,
        bytes32 _newMetadataHash,
        bytes32 _newContentHash
    ) external onlyIPOwner(_parentIpId) returns (uint256) {
        IPAsset storage parentIp = ipAssets[_parentIpId];
        if (parentIp.id == 0) revert CognitoCanvas__IPNotFound(_parentIpId);
        if (parentIp.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();

        uint256 newIpId = nextIpId++;
        uint256 currentTimestamp = block.timestamp;

        ipAssets[newIpId] = IPAsset({
            id: newIpId,
            creator: msg.sender, // Creator of the new version
            parentIpId: _parentIpId,
            metadataHash: _newMetadataHash,
            contentHash: _newContentHash,
            creationTimestamp: currentTimestamp,
            lastUpdateTimestamp: uint224(currentTimestamp),
            status: IPStatus.Draft,
            isSoulbound: parentIp.isSoulbound, // Inherit soulbound status from parent
            aiQualityScore: 0,
            lastAICurationReportHash: bytes32(0),
            aiReportPending: false,
            collectedRoyalties: 0
        });

        // The creator of the new version is the initial contributor
        _ipContributions[newIpId].push(
            IPContribution({
                contributor: msg.sender,
                contributionHash: _newContentHash,
                contributionType: ContributionType.Other,
                timestamp: currentTimestamp,
                weight: 100
            })
        );
        _addContributorToIPList(msg.sender, newIpId);

        emit IPVersionEvolved(_parentIpId, newIpId, _newMetadataHash);
        emit IPAssetCreated(newIpId, msg.sender, _newMetadataHash, parentIp.isSoulbound);
        emit ContributionAdded(newIpId, msg.sender, ContributionType.Other, 100);
        return newIpId;
    }

    /**
     * @dev Marks an IP asset as archived, preventing further contributions or new licenses.
     *      Callable by an IP owner.
     * @param _ipId The ID of the IP asset to archive.
     */
    function archiveIPAsset(uint256 _ipId) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();

        ip.status = IPStatus.Archived;
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit IPAssetArchived(_ipId);
    }

    /* ========================== II. Dynamic Contribution & Ownership ========================= */

    /**
     * @dev Adjusts a specific contributor's weight for an IP. This can be used to reflect
     *      the impact of a contribution, typically after AI review, community voting, or dispute resolution.
     *      Callable by an IP owner.
     * @param _ipId The ID of the IP asset.
     * @param _contributor The address of the contributor whose weight is to be adjusted.
     * @param _newWeight The new weight to assign to the contributor's latest contribution.
     */
    function updateContributionWeight(
        uint256 _ipId,
        address _contributor,
        uint256 _newWeight
    ) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (_newWeight == 0) revert CognitoCanvas__InvalidWeight(); 

        bool found = false;
        // This logic simplifies to updating the first matching contributor's weight.
        // A more granular system might require a `contributionIndex` to update specific contributions.
        for (uint256 i = 0; i < _ipContributions[_ipId].length; i++) {
            if (_ipContributions[_ipId][i].contributor == _contributor) {
                _ipContributions[_ipId][i].weight = _newWeight;
                found = true;
                // For simplicity, we update the first matching.
                // In a real advanced system, `updateContributionWeight` might take a `contributionIndex`
                // to specify exactly which contribution to update.
                break; 
            }
        }
        if (!found) revert CognitoCanvas__ContributionNotFound(_ipId, _contributor);

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit ContributionWeightUpdated(_ipId, _contributor, _newWeight);
    }

    /**
     * @dev Calculates and returns the current proportional ownership shares for all contributors to an IP.
     *      Shares are based on the sum of individual contribution weights.
     * @param _ipId The ID of the IP asset.
     * @return An array of contributor addresses and their respective shares (basis points, 10000 = 100%).
     */
    function getIPOwnersAndShares(
        uint256 _ipId
    ) public view returns (address[] memory, uint256[] memory) {
        if (ipAssets[_ipId].id == 0) revert CognitoCanvas__IPNotFound(_ipId);

        uint256 totalWeight = _getIPTotalWeight(_ipId);
        if (totalWeight == 0) revert CognitoCanvas__NoContributionsFound(_ipId);

        // Aggregate contributions by unique contributor
        mapping(address => uint256) individualWeights;
        address[] memory uniqueContributors;
        uint256 uniqueCount = 0;

        for (uint256 i = 0; i < _ipContributions[_ipId].length; i++) {
            address contributor = _ipContributions[_ipId][i].contributor;
            uint256 weight = _ipContributions[_ipId][i].weight;

            if (individualWeights[contributor] == 0) {
                uniqueContributors = _appendAddress(uniqueContributors, contributor);
                uniqueCount++;
            }
            individualWeights[contributor] = individualWeights[contributor].add(weight);
        }

        address[] memory owners = new address[](uniqueCount);
        uint256[] memory shares = new uint256[](uniqueCount);

        for (uint256 i = 0; i < uniqueCount; i++) {
            owners[i] = uniqueContributors[i];
            shares[i] = individualWeights[uniqueContributors[i]].mul(10000).div(totalWeight);
        }
        return (owners, shares);
    }

    /**
     * @dev Retrieves a list of all IP assets a specific contributor has contributed to.
     * @param _contributor The address of the contributor.
     * @return An array of IP IDs the contributor has participated in.
     */
    function getContributorIPs(address _contributor) external view returns (uint256[] memory) {
        return _contributorToIPs[_contributor];
    }

    /* =========================== III. Licensing & Royalties =========================== */

    /**
     * @dev Allows an IP owner to define custom, granular licensing terms for their asset.
     *      Requires the IP to be in a Published or Reviewed status.
     * @param _ipId The ID of the IP asset.
     * @param _licenseName A human-readable name for the license term (e.g., "Commercial Use, 1 year").
     * @param _royaltyFeeBasisPoints The fee (in basis points) charged for this license.
     * @param _durationSeconds The duration of the license in seconds (0 for perpetual).
     * @param _usageRestrictionsHash IPFS hash or similar for the detailed usage restrictions.
     * @return The ID of the newly defined license term.
     */
    function defineLicenseTerms(
        uint256 _ipId,
        string calldata _licenseName,
        uint256 _royaltyFeeBasisPoints,
        uint256 _durationSeconds,
        bytes32 _usageRestrictionsHash
    ) external onlyIPOwner(_ipId) returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status != IPStatus.Published && ip.status != IPStatus.Reviewed) revert CognitoCanvas__IPNotPublished();
        if (_royaltyFeeBasisPoints > 10000) revert CognitoCanvas__InvalidWeight(); 

        uint256 termId = nextLicenseTermId++;
        _ipLicenseTerms[_ipId][termId] = LicenseTerm({
            id: termId,
            name: _licenseName,
            royaltyFeeBasisPoints: _royaltyFeeBasisPoints,
            durationSeconds: _durationSeconds,
            usageRestrictionsHash: _usageRestrictionsHash,
            creationTimestamp: block.timestamp
        });

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit LicenseTermDefined(_ipId, termId, _licenseName, _royaltyFeeBasisPoints);
        return termId;
    }

    /**
     * @dev Enables a user to purchase a license for an IP based on predefined terms,
     *      paying the specified royalty fee in ETH.
     * @param _ipId The ID of the IP asset.
     * @param _licenseTermId The ID of the specific license term to acquire.
     */
    function acquireLicense(uint256 _ipId, uint256 _licenseTermId) external payable {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status != IPStatus.Published && ip.status != IPStatus.Reviewed) revert CognitoCanvas__IPNotPublished();
        if (ip.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();

        LicenseTerm storage term = _ipLicenseTerms[_ipId][_licenseTermId];
        if (term.id == 0) revert CognitoCanvas__LicenseTermNotFound(_ipId, _licenseTermId);

        uint256 royaltyAmount = msg.value; // The sent value is the royalty fee
        if (royaltyAmount == 0) revert CognitoCanvas__InsufficientFunds();

        // Calculate platform fee
        uint256 platformFee = royaltyAmount.mul(platformFeeBasisPoints).div(10000);
        uint256 netRoyalties = royaltyAmount.sub(platformFee);

        ip.collectedRoyalties = ip.collectedRoyalties.add(netRoyalties); // Store net royalties for distribution

        uint256 licenseId = nextLicenseId++;
        uint256 expiry = term.durationSeconds == 0 ? 0 : block.timestamp.add(term.durationSeconds);

        _activeLicenses[_ipId][licenseId] = ActiveLicense({
            id: licenseId,
            ipId: _ipId,
            licensee: msg.sender,
            licenseTermId: _licenseTermId,
            acquisitionTimestamp: block.timestamp,
            expiryTimestamp: expiry,
            status: LicenseStatus.Active
        });

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit LicenseAcquired(_ipId, licenseId, msg.sender, _licenseTermId, royaltyAmount);
    }

    /**
     * @dev Allows an IP owner to revoke an active license under specified conditions (e.g., breach of terms).
     * @param _ipId The ID of the IP asset.
     * @param _licenseId The ID of the active license to revoke.
     */
    function revokeLicense(uint256 _ipId, uint256 _licenseId) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);

        ActiveLicense storage license = _activeLicenses[_ipId][_licenseId];
        if (license.id == 0 || license.ipId != _ipId) revert CognitoCanvas__ActiveLicenseNotFound(_ipId, _licenseId);
        if (license.status != LicenseStatus.Active) revert CognitoCanvas__InvalidIPStatus(); // Already revoked or expired

        license.status = LicenseStatus.Revoked;
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit LicenseRevoked(_ipId, _licenseId, msg.sender);
    }

    /**
     * @dev Triggers the distribution of collected license fees for a specific IP to its contributors,
     *      based on their dynamic ownership shares.
     *      Callable by anyone, but only transfers if there are royalties.
     * @param _ipId The ID of the IP asset.
     */
    function distributeRoyalties(uint256 _ipId) external {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.collectedRoyalties == 0) revert CognitoCanvas__NoRoyaltiesToDistribute();

        uint256 amountToDistribute = ip.collectedRoyalties;
        ip.collectedRoyalties = 0; // Reset collected royalties immediately (checks-effects-interactions)

        (address[] memory owners, uint256[] memory shares) = getIPOwnersAndShares(_ipId);

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 shareAmount = amountToDistribute.mul(shares[i]).div(10000);
            if (shareAmount > 0) {
                (bool success, ) = owners[i].call{value: shareAmount}("");
                if (!success) {
                    // Revert if any transfer fails to ensure atomicity or use a pull-payment system.
                    revert CognitoCanvas__RoyaltyDistributionFailed();
                }
            }
        }
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit RoyaltiesDistributed(_ipId, amountToDistribute);
    }

    /* =================== IV. AI-Assisted Curation & Verification (Simulated Oracle) =================== */

    /**
     * @dev Submits an IP asset for review by a designated AI oracle (e.g., for originality, quality, compliance).
     *      Callable by an IP owner.
     * @param _ipId The ID of the IP asset to send for AI curation.
     */
    function requestAICuration(uint256 _ipId) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();
        if (ip.aiReportPending) revert CognitoCanvas__AIReportPending();

        ip.aiReportPending = true;
        ip.status = IPStatus.AwaitingAICuration;
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit AICurationRequested(_ipId, msg.sender);
    }

    /**
     * @dev Callable only by the designated AI oracle, submits a comprehensive report for a given IP.
     *      This simulates an off-chain AI service providing feedback.
     * @param _ipId The ID of the IP asset being reported on.
     * @param _reportHash IPFS hash or similar for the full AI report document.
     * @param _qualityScore The quality score assigned by the AI (e.g., 0-100).
     * @param _isOriginal Boolean indicating AI's originality assessment.
     * @param _feedbackSummary A brief summary of the AI's feedback.
     */
    function submitAICurationReport(
        uint256 _ipId,
        bytes32 _reportHash,
        uint256 _qualityScore,
        bool _isOriginal,
        string calldata _feedbackSummary
    ) external onlyAIOracle {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (!ip.aiReportPending) revert CognitoCanvas__AIReportPending(); // Only accept if a request was pending

        _aiReports[_ipId].push(
            AICurationReport({
                reportHash: _reportHash,
                qualityScore: _qualityScore,
                isOriginal: _isOriginal,
                feedbackSummary: _feedbackSummary,
                timestamp: block.timestamp
            })
        );

        ip.aiQualityScore = _qualityScore;
        ip.lastAICurationReportHash = _reportHash;
        ip.aiReportPending = false; // Report is no longer pending
        ip.status = IPStatus.Reviewed; // IP moves to reviewed status

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit AICurationReportSubmitted(_ipId, _reportHash, _qualityScore, _isOriginal);
    }

    /**
     * @dev Allows the IP owner to update the IP's metadata, content, quality score, or status based on an AI report.
     *      Requires the IP to be in 'Reviewed' status.
     * @param _ipId The ID of the IP asset.
     * @param _newMetadataHash New metadata hash (can be same as current).
     * @param _newContentHash New content hash (can be same as current).
     * @param _newQualityScore New AI quality score (can be same as current).
     * @param _newStatus The new status for the IP (e.g., Published).
     */
    function applyAICurationFeedback(
        uint256 _ipId,
        bytes32 _newMetadataHash,
        bytes32 _newContentHash,
        uint256 _newQualityScore,
        IPStatus _newStatus
    ) external onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status != IPStatus.Reviewed) revert CognitoCanvas__InvalidIPStatus();
        if (_newStatus == IPStatus.Archived || _newStatus == IPStatus.AwaitingAICuration || _newStatus == IPStatus.Disputed) revert CognitoCanvas__InvalidIPStatus();

        ip.metadataHash = _newMetadataHash;
        ip.contentHash = _newContentHash;
        ip.aiQualityScore = _newQualityScore;
        ip.status = _newStatus; // E.g., moving from Reviewed to Published

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit AICurationFeedbackApplied(_ipId, _newMetadataHash, _newStatus);
    }

    /* ========================= V. Reputation & Governance (Simplified) ========================= */

    /**
     * @dev Adjusts a contributor's reputation score. This function is typically called by
     *      an admin or a DAO based on successful IP, AI reviews, or dispute resolutions.
     *      (Owner-only for simplification; in a real DAO, this would be a governance action).
     * @param _contributor The address of the contributor.
     * @param _delta The amount to change the reputation score by (can be negative).
     */
    function updateReputationScore(address _contributor, int256 _delta) external onlyOwner {
        uint256 currentScore = reputationScores[_contributor];
        uint256 newScore;

        if (_delta >= 0) {
            newScore = currentScore.add(uint256(_delta));
        } else {
            uint256 absDelta = uint256(-_delta);
            if (currentScore < absDelta) {
                newScore = 0; // Reputation cannot go below zero
            } else {
                newScore = currentScore.sub(absDelta);
            }
        }
        reputationScores[_contributor] = newScore;
        emit ReputationScoreUpdated(_contributor, _delta, newScore);
    }

    /**
     * @dev Allows a user to propose a change in an IP's status (e.g., from Draft to Published).
     *      Callable by any user. Voting will determine if the change occurs.
     * @param _ipId The ID of the IP asset.
     * @param _newStatus The proposed new status for the IP.
     */
    function proposeIPStatusChange(uint256 _ipId, IPStatus _newStatus) external {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (ip.status == IPStatus.Archived) revert CognitoCanvas__IPArchived();
        if (_newStatus == ip.status) revert CognitoCanvas__InvalidIPStatus();
        if (_newStatus == IPStatus.Archived || _newStatus == IPStatus.AwaitingAICuration) revert CognitoCanvas__InvalidIPStatus(); // Direct proposal not allowed for these

        _ipStatusProposalTimestamp[_ipId][_newStatus] = block.timestamp;
        emit IPStatusChangeProposed(_ipId, _newStatus, msg.sender);
    }

    /**
     * @dev Enables users to vote on a pending IP status change proposal.
     *      Requires a proposal to exist and the voting period (simplified, no explicit period check here).
     * @param _ipId The ID of the IP asset.
     * @param _proposedStatus The status that was proposed.
     * @param _forChange True to vote for the change, false to vote against.
     */
    function voteOnIPStatusChange(uint256 _ipId, IPStatus _proposedStatus, bool _forChange) external {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (_ipStatusProposalTimestamp[_ipId][_proposedStatus] == 0) revert CognitoCanvas__InvalidIPStatus(); // No active proposal

        // Prevent double voting
        if (_ipStatusVotes[_ipId][_proposedStatus][msg.sender]) revert CognitoCanvas__AlreadyVoted();
        _ipStatusVotes[_ipId][_proposedStatus][msg.sender] = true;

        if (_forChange) {
            _ipStatusVoteCountsFor[_ipId][_proposedStatus]++;
        } else {
            _ipStatusVoteCountsAgainst[_ipId][_proposedStatus]++;
        }

        emit IPStatusVoteCast(_ipId, _proposedStatus, msg.sender, _forChange);

        // Simple majority rule for now, can be expanded to require more complex quorum.
        // For a true DAO, this would trigger an execution after a period and quorum.
        // A simple threshold: at least 3 votes for and more votes for than against.
        if (_ipStatusVoteCountsFor[_ipId][_proposedStatus] > _ipStatusVoteCountsAgainst[_ipId][_proposedStatus] &&
            _ipStatusVoteCountsFor[_ipId][_proposedStatus] >= 3 
        ) {
            IPStatus oldStatus = ip.status;
            ip.status = _proposedStatus;
            ip.lastUpdateTimestamp = uint224(block.timestamp);
            // Reset votes for this proposal
            _ipStatusVoteCountsFor[_ipId][_proposedStatus] = 0;
            _ipStatusVoteCountsAgainst[_ipId][_proposedStatus] = 0;
            _ipStatusProposalTimestamp[_ipId][_proposedStatus] = 0;
            // Note: _ipStatusVotes mapping will remain, but effectively ignored for past proposals.

            emit IPStatusChanged(_ipId, oldStatus, _proposedStatus);
        }
    }

    /**
     * @dev An admin/arbiter function to formally resolve disputes related to an IP,
     *      potentially affecting contributor reputations.
     *      This is a simplified dispute resolution (Owner-only for simplification).
     * @param _ipId The ID of the IP asset in dispute.
     * @param _disputeDetailsHash Hash of off-chain details of the dispute and its resolution.
     * @param _winningParty The address deemed to be the winner of the dispute.
     * @param _losingParty The address deemed to be the loser of the dispute (can be address(0) if no specific loser).
     * @param _reputationDeltaWinner Reputation change for the winning party.
     * @param _reputationDeltaLoser Reputation change for the losing party (applied only if _losingParty is not address(0)).
     */
    function resolveDispute(
        uint256 _ipId,
        bytes32 _disputeDetailsHash,
        address _winningParty,
        address _losingParty,
        int256 _reputationDeltaWinner,
        int256 _reputationDeltaLoser
    ) external onlyOwner {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);

        ip.status = IPStatus.Reviewed; // After dispute, move to reviewed for potential adjustments
        ip.lastUpdateTimestamp = uint224(block.timestamp);

        // Apply reputation changes
        updateReputationScore(_winningParty, _reputationDeltaWinner);
        if (_losingParty != address(0)) {
            updateReputationScore(_losingParty, _reputationDeltaLoser);
        }
        emit DisputeResolved(_ipId, _winningParty, _disputeDetailsHash);
    }

    /* ============================= VI. Funding & Bounties ============================= */

    /**
     * @dev Allows any user to contribute funds (ETH) directly to support the development or maintenance of a specific IP asset.
     * @param _ipId The ID of the IP asset to fund.
     */
    function fundIPDevelopment(uint256 _ipId) external payable {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (msg.value == 0) revert CognitoCanvas__InsufficientFunds();

        // Funds are held by the contract for later use or specific bounties
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit IPFunded(_ipId, msg.sender, msg.value);
    }

    /**
     * @dev An IP owner or community member can create a bounty for specific improvements or tasks related to an IP.
     *      The bounty amount is paid from the caller's ETH.
     * @param _ipId The ID of the IP asset the bounty is for.
     * @param _bountyDescriptionHash IPFS hash for the detailed bounty description.
     * @param _amount The ETH amount for the bounty.
     * @return The ID of the newly created bounty.
     */
    function createBountyForIPImprovement(
        uint256 _ipId,
        bytes32 _bountyDescriptionHash,
        uint256 _amount
    ) external payable onlyIPContributor(_ipId) returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        if (msg.value < _amount) revert CognitoCanvas__InsufficientFunds(); // Ensure enough ETH sent
        if (_amount == 0) revert CognitoCanvas__InvalidWeight(); 

        uint256 bountyId = nextBountyId++;
        _bounties[bountyId] = Bounty({
            id: bountyId,
            ipId: _ipId,
            creator: msg.sender,
            descriptionHash: _bountyDescriptionHash,
            amount: _amount,
            isActive: true,
            claimer: address(0), // No claimer yet
            proofOfWorkHash: bytes32(0), // No proof yet
            claimTimestamp: 0,
            claimed: false
        });
        _ipBounties[_ipId].push(bountyId);

        // Any excess ETH sent (msg.value > _amount) remains in the contract's balance.

        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit BountyCreated(_ipId, bountyId, msg.sender, _amount);
        return bountyId;
    }

    /**
     * @dev A contributor can claim a bounty by providing proof of work.
     *      The claim needs to be reviewed (off-chain or by admin/DAO) before payout.
     *      For this contract, an admin or owner (simplified) would then approve the payout via another function.
     * @param _bountyId The ID of the bounty to claim.
     * @param _proofOfWorkHash IPFS hash for the proof of work submitted by the claimer.
     */
    function claimBounty(uint256 _bountyId, bytes32 _proofOfWorkHash) external {
        Bounty storage bounty = _bounties[_bountyId];
        if (bounty.id == 0) revert CognitoCanvas__BountyNotFound(_bountyId);
        if (!bounty.isActive) revert CognitoCanvas__BountyNotActive();
        if (bounty.claimed) revert CognitoCanvas__BountyAlreadyClaimed();
        if (msg.sender == bounty.creator) revert CognitoCanvas__SelfContributionNotAllowed();

        bounty.claimer = msg.sender;
        bounty.proofOfWorkHash = _proofOfWorkHash;
        bounty.claimTimestamp = block.timestamp;
        bounty.claimed = true; // Mark as claimed, awaiting review and payout approval

        IPAsset storage ip = ipAssets[bounty.ipId];
        ip.lastUpdateTimestamp = uint224(block.timestamp);
        emit BountyClaimed(_bountyId, msg.sender, bounty.amount);

        // A separate `approveBountyClaim` function (callable by bounty.creator or owner) would be needed
        // to actually transfer the `bounty.amount` from this contract to `bounty.claimer`.
        // This keeps the `claimBounty` function focused on registration of intent.
    }
    
    /**
     * @dev Allows the creator of a bounty (or platform owner, for simplification) to approve a claim
     *      and release the bounty funds to the claimer.
     * @param _bountyId The ID of the bounty to approve.
     */
    function approveBountyClaim(uint256 _bountyId) external onlyOwner { // Can be restricted to bounty.creator instead
        Bounty storage bounty = _bounties[_bountyId];
        if (bounty.id == 0) revert CognitoCanvas__BountyNotFound(_bountyId);
        if (!bounty.claimed) revert("CognitoCanvas__BountyNotClaimed");
        if (!bounty.isActive) revert CognitoCanvas__BountyNotActive();
        if (bounty.claimer == address(0)) revert("CognitoCanvas__NoClaimerForBounty");
        
        // Mark bounty inactive after payout
        bounty.isActive = false; 

        // Transfer funds
        (bool success, ) = bounty.claimer.call{value: bounty.amount}("");
        if (!success) {
            bounty.isActive = true; // Revert state if transfer fails
            revert CognitoCanvas__WithdrawalFailed();
        }

        // Update IP last update timestamp if this bounty implies improvement
        IPAsset storage ip = ipAssets[bounty.ipId];
        ip.lastUpdateTimestamp = uint224(block.timestamp);

        emit FundsWithdrawn(bounty.claimer, bounty.amount);
    }

    /**
     * @dev Admin function to withdraw platform fees or unallocated funds.
     *      Only callable by the contract owner.
     * @param _to The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFunds(address _to, uint256 _amount) external onlyOwner {
        if (_amount == 0) revert CognitoCanvas__InsufficientFunds();
        if (address(this).balance < _amount) revert CognitoCanvas__InsufficientFunds();

        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert CognitoCanvas__WithdrawalFailed();

        emit FundsWithdrawn(_to, _amount);
    }

    /* =========================== VII. Helper/View Functions =========================== */

    /**
     * @dev Retrieves all core details of a specific IP asset.
     * @param _ipId The ID of the IP asset.
     * @return An IPAsset struct containing all its details.
     */
    function getIPDetails(uint256 _ipId) external view returns (IPAsset memory) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        return ip;
    }

    /**
     * @dev Retrieves the details of a specific license term for an IP.
     * @param _ipId The ID of the IP asset.
     * @param _licenseTermId The ID of the license term.
     * @return A LicenseTerm struct containing all its details.
     */
    function getLicenseTermDetails(uint256 _ipId, uint256 _licenseTermId) external view returns (LicenseTerm memory) {
        LicenseTerm storage term = _ipLicenseTerms[_ipId][_licenseTermId];
        if (term.id == 0) revert CognitoCanvas__LicenseTermNotFound(_ipId, _licenseTermId);
        return term;
    }

    /**
     * @dev Retrieves details of an active license.
     * @param _ipId The ID of the IP asset.
     * @param _licenseId The ID of the active license.
     * @return An ActiveLicense struct containing all its details.
     */
    function getActiveLicenseDetails(uint256 _ipId, uint256 _licenseId) external view returns (ActiveLicense memory) {
        ActiveLicense storage license = _activeLicenses[_ipId][_licenseId];
        if (license.id == 0 || license.ipId != _ipId) revert CognitoCanvas__ActiveLicenseNotFound(_ipId, _licenseId);
        return license;
    }

    /**
     * @dev Retrieves a list of all contributions for a given IP.
     * @param _ipId The ID of the IP asset.
     * @return An array of IPContribution structs.
     */
    function getIPContributions(uint256 _ipId) external view returns (IPContribution[] memory) {
        if (ipAssets[_ipId].id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        return _ipContributions[_ipId];
    }

    /**
     * @dev Retrieves a list of all AI curation reports for a given IP.
     * @param _ipId The ID of the IP asset.
     * @return An array of AICurationReport structs.
     */
    function getAICurationReports(uint256 _ipId) external view returns (AICurationReport[] memory) {
        if (ipAssets[_ipId].id == 0) revert CognitoCanvas__IPNotFound(_ipId);
        return _aiReports[_ipId];
    }
}
```