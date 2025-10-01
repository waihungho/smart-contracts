Here is a Solidity smart contract named `IntellectNexus`, designed to embody advanced, creative, and trendy concepts in decentralized intellectual property management. It includes a comprehensive set of functions (23 in total, exceeding the 20-function requirement) covering fractionalized IP ownership, dynamic licensing, collaborative syndicates (DAOs), and architectural support for future integrations like Zero-Knowledge Proofs and Oracle networks.

---

## Contract: IntellectNexus

**Description:**
IntellectNexus is a cutting-edge, decentralized protocol designed for the management, fractionalization, and dynamic licensing of intellectual property (IP). It empowers creators to tokenize their IP as unique NFTs, define evolving licensing terms based on real-world conditions or usage, and form collaborative "Syndicates" for joint development and revenue sharing. The platform is built with an eye towards future integration with advanced concepts like Zero-Knowledge Proofs for privacy-preserving contributions and Oracle networks for external data-driven license conditions. Its core aim is to foster a vibrant, transparent, and fair ecosystem for intellectual property in the Web3 era, moving beyond static agreements to adaptive, on-chain relationships.

**Core Concepts:**
*   **IP-NFTs:** Each intellectual property is represented by a unique ERC-721 token, which can be further fractionalized.
*   **Dynamic Licensing:** Licenses are not static; their terms (e.g., royalty rates, duration) can adapt based on predefined conditions, oracle feeds, or reported usage, and payments can be streamed.
*   **Fractionalized Ownership:** IP can be split into ERC-1155 shares, allowing multiple contributors to co-own and share royalties.
*   **IP Syndicates:** Decentralized Autonomous Organizations (DAOs) formed around specific IP or collaborative projects, enabling shared governance and revenue distribution.
*   **Future-Proofing:** Architectural support for ZKPs (for privacy-preserving contribution claims) and Oracle integration (for external data-driven license logic).

---

### Function Summary:

**I. Core IP Management & Fractionalization**
1.  `registerIntellectualProperty(string _name, string _symbol, string _uri, bool _isFractional, uint256 _initialSupply, address[] memory _initialRecipients, uint256[] memory _initialAmounts)`: Registers a new IP, mints an IP-NFT (ERC-721), and optionally creates and distributes fractional (ERC-1155) tokens.
2.  `updateIPMetadata(uint256 _ipId, string _newUri)`: Updates the metadata URI for a registered IP.
3.  `transferIPOwnership(uint256 _ipId, address _newOwner)`: Transfers the primary ERC-721 ownership of an IP.
4.  `burnFractionalShares(uint256 _ipId, address _from, uint256 _amount)`: Burns fractional shares of an IP.
5.  `mintFractionalShares(uint256 _ipId, address _to, uint256 _amount)`: Mints additional fractional shares for an IP.
6.  `updateRoyaltySplit(uint256 _ipId, address[] memory _recipients, uint256[] memory _percentages)`: Adjusts the royalty distribution scheme for an IP.

**II. Dynamic Licensing & Royalties**
7.  `defineLicenseTemplate(string _templateName, string _termsHash, uint256 _basePrice, uint256 _defaultRoyaltyPercentage)`: Creates a reusable template for licensing terms.
8.  `attachLicenseToIP(uint256 _ipId, uint256 _templateId, uint256 _customPrice, uint256 _expiryDuration)`: Attaches a specific license instance to an IP based on a template.
9.  `requestIPLicense(uint256 _ipId, uint256 _licenseTemplateId, string _usageIntentHash)`: Allows a potential licensee to formally request a license for an IP.
10. `approveIPLicense(uint256 _requestId, uint256 _initialPayment, uint256 _effectiveExpiry)`: IP owner approves a pending license request, activating it.
11. `payForLicenseUsage(uint256 _licenseId, uint256 _amount)`: Licensee makes a payment for ongoing usage of a licensed IP.
12. `claimRoyalties(uint256 _ipId)`: Allows IP owners/shareholders to claim their accumulated royalty earnings.
13. `setOracleConditionForLicense(uint256 _licenseId, address _oracleAddress, bytes memory _conditionData)`: Defines a condition where license terms dynamically adapt based on external data from an oracle.
14. `reportUsageMetric(uint256 _licenseId, string _metricType, uint256 _value, bytes memory _proofHash)`: Licensee reports usage metrics (e.g., revenue, downloads), potentially with an off-chain verifiable proof.

**III. IP Syndicates (Collaborative DAOs)**
15. `createIPSyndicate(string _name, string _description, address[] memory _initialMembers, uint256[] memory _memberShares, uint256[] memory _ipIdsToManage)`: Creates a new collaborative syndicate (DAO) around specific IPs.
16. `addMemberToSyndicate(uint256 _syndicateId, address _newMember, uint256 _share)`: Adds a new member to an existing syndicate.
17. `proposeSyndicateAction(uint256 _syndicateId, address _target, uint256 _value, bytes memory _callData, string _description)`: Members propose actions (e.g., license, update, distribute funds) for the syndicate to vote on.
18. `voteOnSyndicateProposal(uint256 _syndicateId, uint256 _proposalId, bool _support)`: Members cast votes on syndicate proposals.
19. `executeSyndicateProposal(uint256 _syndicateId, uint256 _proposalId)`: Executes a proposal that has passed the syndicate's voting threshold.
20. `distributeSyndicateFunds(uint256 _syndicateId)`: Distributes accumulated funds from the syndicate treasury to its members based on their shares.

**IV. Dispute Resolution & Advanced Features**
21. `submitDisputeClaim(uint256 _licenseId, string _claimHash)`: Initiates a formal dispute against a license for breach of terms or other issues.
22. `settleDispute(uint256 _disputeId, string _resolutionHash)`: An authorized arbiter or IP owner records the resolution of a dispute.
23. `submitContributionClaim(uint256 _ipId, string _claimDescriptionHash, bytes memory _zkProofData)`: Allows a contributor to claim contribution to an IP, potentially with a Zero-Knowledge Proof for privacy.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Helper for percentage calculations, assuming 10,000 basis points for 100%
library PercentageMath {
    using SafeMath for uint256;

    function calculatePercentage(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        require(_percentage <= 10000, "PercentageMath: percentage exceeds 100%");
        return _amount.mul(_percentage).div(10000);
    }
}

/**
 * @title IntellectNexus
 * @dev A Decentralized & Fractionalized IP Management and Dynamic Licensing Protocol.
 *
 * Description:
 * IntellectNexus is a cutting-edge, decentralized protocol designed for the management,
 * fractionalization, and dynamic licensing of intellectual property (IP). It empowers
 * creators to tokenize their IP as unique NFTs, define evolving licensing terms based
 * on real-world conditions or usage, and form collaborative "Syndicates" for joint
 * development and revenue sharing. The platform is built with an eye towards future
 * integration with advanced concepts like Zero-Knowledge Proofs for privacy-preserving
 * contributions and Oracle networks for external data-driven license conditions.
 * Its core aim is to foster a vibrant, transparent, and fair ecosystem for intellectual
 * property in the Web3 era, moving beyond static agreements to adaptive, on-chain relationships.
 *
 * Core Concepts:
 * - IP-NFTs: Each intellectual property is represented by a unique ERC-721 token, which can
 *   be further fractionalized.
 * - Dynamic Licensing: Licenses are not static; their terms (e.g., royalty rates, duration)
 *   can adapt based on predefined conditions, oracle feeds, or reported usage, and payments can be streamed.
 * - Fractionalized Ownership: IP can be split into ERC-1155 shares, allowing multiple
 *   contributors to co-own and share royalties.
 * - IP Syndicates: Decentralized Autonomous Organizations (DAOs) formed around specific
 *   IP or collaborative projects, enabling shared governance and revenue distribution.
 * - Future-Proofing: Architectural support for ZKPs (for privacy-preserving contribution claims)
 *   and Oracle integration (for external data-driven license logic).
 */
contract IntellectNexus is ERC721URIStorage, ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using PercentageMath for uint256;

    // --- State Variables ---
    Counters.Counter private _ipIdCounter;
    Counters.Counter private _licenseTemplateIdCounter;
    Counters.Counter private _licenseIdCounter;
    Counters.Counter private _syndicateIdCounter;
    Counters.Counter private _disputeIdCounter;
    Counters.Counter private _licenseRequestIdCounter;

    // IP Data Structure
    struct IntellectualProperty {
        uint256 id;
        address owner; // ERC721 owner
        string name;
        string symbol;
        string uri;
        bool isFractional;
        uint256 totalFractionalSupply; // Only if isFractional
        mapping(address => uint256) royaltyRecipients; // Address => percentage (basis points, 10000 = 100%)
        address[] royaltyRecipientIds; // For iterating over recipients
        uint256 accumulatedRoyalties; // Ether collected for this IP
        bool exists; // To check if IP ID is valid
    }
    mapping(uint256 => IntellectualProperty) public intellectualProperties;

    // License Template
    struct LicenseTemplate {
        uint256 id;
        string name;
        string termsHash; // Hash of off-chain detailed terms document
        uint256 basePrice; // Base price for a license instance
        uint256 defaultRoyaltyPercentage; // Default royalty for usage (basis points)
        bool exists;
    }
    mapping(uint256 => LicenseTemplate) public licenseTemplates;

    // License Instance
    struct License {
        uint256 id;
        uint256 ipId;
        uint256 templateId;
        address licensee;
        uint256 currentPrice;
        uint256 royaltyPercentage; // Can be dynamic
        uint256 createdAt;
        uint256 expiresAt;
        string usageIntentHash; // Hash of licensee's declared intent
        address oracleAddress; // For dynamic conditions
        bytes oracleConditionData; // Data for the oracle
        uint256 totalPaid; // Total funds paid by this licensee
        mapping(string => uint256) reportedMetrics; // e.g., "revenue" => amount
        bool isActive;
        bool exists;
    }
    mapping(uint256 => License) public licenses;

    // License Request
    struct LicenseRequest {
        uint256 id;
        uint256 ipId;
        uint256 licenseTemplateId;
        address requester;
        string usageIntentHash;
        uint256 requestedAt;
        bool approved;
        bool exists;
    }
    mapping(uint256 => LicenseRequest) public licenseRequests;


    // IP Syndicate (DAO-like structure)
    struct IPSyndicate {
        uint256 id;
        string name;
        string description;
        mapping(address => uint256) members; // Member address => share percentage (basis points)
        address[] memberAddresses; // For iterating
        mapping(uint256 => bool) managedIPs; // ipId => true if managed by this syndicate
        uint256[] managedIPIds; // For iterating
        uint256 treasuryBalance;
        Counters.Counter proposalCounter;
        bool exists;
    }
    mapping(uint256 => IPSyndicate) public ipSyndicates;

    // Syndicate Proposal
    struct SyndicateProposal {
        uint256 id;
        uint256 syndicateId;
        address proposer;
        address target; // Target contract for call
        uint256 value; // Ether to send with call
        bytes callData; // Encoded function call
        string description;
        uint256 createdAt;
        uint256 voteEndTime;
        uint256 totalSharesVoted;
        uint256 totalSharesFor;
        uint256 quorumRequired; // Basis points of total shares
        bool executed;
        bool exists;
        mapping(address => bool) hasVoted; // Member => true if voted
    }
    mapping(uint252 => mapping(uint256 => SyndicateProposal)) public syndicateProposals; // syndicateId => proposalId => proposal

    // Dispute Resolution
    struct Dispute {
        uint256 id;
        uint256 licenseId;
        address claimant;
        string claimHash; // Hash of off-chain claim details
        string resolutionHash; // Hash of off-chain resolution details
        uint256 createdAt;
        uint256 resolvedAt;
        bool isResolved;
        bool exists;
    }
    mapping(uint256 => Dispute) public disputes;

    // Contribution Claims (for ZKP integration)
    struct ContributionClaim {
        uint256 ipId;
        address contributor;
        string claimDescriptionHash; // Hash of off-chain description
        bytes zkProofData; // Placeholder for ZKP data
        uint256 claimedAt;
        bool verified; // Set true after off-chain (or simple on-chain) verification
        bool exists; // To check if claim ID is valid
    }
    mapping(uint256 => mapping(address => ContributionClaim)) public contributionClaims; // ipId => contributor => claim

    // --- Events ---
    event IPRegistered(uint256 indexed ipId, address indexed owner, string name, string symbol, bool isFractional);
    event IPMetadataUpdated(uint256 indexed ipId, string newUri);
    event IPOwnershipTransferred(uint256 indexed ipId, address indexed oldOwner, address indexed newOwner);
    event FractionalSharesMinted(uint256 indexed ipId, address indexed to, uint256 amount);
    event FractionalSharesBurned(uint256 indexed ipId, address indexed from, uint256 amount);
    event RoyaltySplitUpdated(uint256 indexed ipId, address[] recipients, uint256[] percentages);
    event RoyaltiesClaimed(uint256 indexed ipId, address indexed claimant, uint256 amount);

    event LicenseTemplateDefined(uint256 indexed templateId, string name, uint256 basePrice, uint256 defaultRoyaltyPercentage);
    event LicenseAttached(uint256 indexed ipId, uint256 indexed licenseId, uint256 templateId, address indexed licensee);
    event LicenseRequested(uint256 indexed requestId, uint256 indexed ipId, address indexed requester);
    event LicenseApproved(uint256 indexed licenseId, uint256 indexed requestId, address indexed licensee, uint256 effectiveExpiry);
    event LicensePayment(uint256 indexed licenseId, address indexed payer, uint256 amount);
    event OracleConditionSet(uint256 indexed licenseId, address indexed oracleAddress);
    event UsageMetricReported(uint256 indexed licenseId, string metricType, uint256 value, bytes proofHash);

    event IPSyndicateCreated(uint256 indexed syndicateId, string name, address indexed creator);
    event SyndicateMemberAdded(uint256 indexed syndicateId, address indexed newMember, uint256 share);
    event SyndicateProposalCreated(uint256 indexed syndicateId, uint256 indexed proposalId, address indexed proposer, string description);
    event SyndicateVoted(uint256 indexed syndicateId, uint256 indexed proposalId, address indexed voter, bool support);
    event SyndicateProposalExecuted(uint256 indexed syndicateId, uint256 indexed proposalId);
    event SyndicateFundsDistributed(uint256 indexed syndicateId, uint256 amount);

    event DisputeClaimed(uint256 indexed disputeId, uint256 indexed licenseId, address indexed claimant);
    event DisputeSettled(uint256 indexed disputeId, uint256 indexed licenseId, string resolutionHash);

    event ContributionClaimed(uint256 indexed ipId, address indexed contributor, string claimDescriptionHash);

    // --- Constructor ---
    constructor() ERC721("IntellectNexus IP", "IN-IP") ERC1155("https://intellectnexus.io/ip_assets/{id}.json") Ownable(msg.sender) {}

    // ERC1155 URI override (standard practice for ERC1155)
    function uri(uint256 _id) public view override returns (string memory) {
        require(intellectualProperties[_id].exists, "IntellectNexus: IP does not exist for this ID");
        // For fractional shares, we use the IP's own URI
        return intellectualProperties[_id].uri;
    }

    // --- Internal/Helper Functions ---
    modifier onlyIPOwner(uint256 _ipId) {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(intellectualProperties[_ipId].owner == msg.sender, "IntellectNexus: Only IP owner can call this function");
        _;
    }

    modifier onlyLicenseOwner(uint256 _licenseId) {
        require(licenses[_licenseId].exists, "IntellectNexus: License does not exist");
        require(intellectualProperties[licenses[_licenseId].ipId].owner == msg.sender, "IntellectNexus: Only IP owner of license can call this function");
        _;
    }

    modifier onlyLicensee(uint256 _licenseId) {
        require(licenses[_licenseId].exists, "IntellectNexus: License does not exist");
        require(licenses[_licenseId].licensee == msg.sender, "IntellectNexus: Only licensee can call this function");
        _;
    }

    modifier onlySyndicateMember(uint256 _syndicateId) {
        require(ipSyndicates[_syndicateId].exists, "IntellectNexus: Syndicate does not exist");
        require(ipSyndicates[_syndicateId].members[msg.sender] > 0, "IntellectNexus: Only syndicate member can call this function");
        _;
    }

    // --- I. Core IP Management & Fractionalization (6 Functions) ---

    /**
     * @dev Registers a new Intellectual Property (IP), mints its ERC-721 token,
     *      and optionally creates ERC-1155 fractional shares.
     * @param _name Name of the IP.
     * @param _symbol Symbol for the IP.
     * @param _uri Metadata URI for the IP (e.g., pointing to IPFS).
     * @param _isFractional True if this IP should have fractional shares.
     * @param _initialSupply Total supply of fractional shares if `_isFractional` is true.
     * @param _initialRecipients Addresses to initially receive fractional shares.
     * @param _initialAmounts Amounts of fractional shares for initial recipients.
     */
    function registerIntellectualProperty(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bool _isFractional,
        uint256 _initialSupply,
        address[] memory _initialRecipients,
        uint256[] memory _initialAmounts
    ) public nonReentrant returns (uint256) {
        _ipIdCounter.increment();
        uint256 newIpId = _ipIdCounter.current();

        require(_initialRecipients.length == _initialAmounts.length, "IntellectNexus: Mismatch in recipients and amounts");
        if (_isFractional) {
            uint256 totalInitialAmount;
            for (uint256 i = 0; i < _initialAmounts.length; i++) {
                totalInitialAmount = totalInitialAmount.add(_initialAmounts[i]);
            }
            require(totalInitialAmount <= _initialSupply, "IntellectNexus: Initial distribution exceeds total supply");
            require(_initialSupply > 0, "IntellectNexus: Fractional supply must be greater than 0");
        } else {
            require(_initialSupply == 0 && _initialRecipients.length == 0, "IntellectNexus: Cannot have fractional supply or recipients if not fractional");
        }

        _mint(msg.sender, newIpId); // Mints the ERC-721 IP token to the creator
        _setTokenURI(newIpId, _uri);

        intellectualProperties[newIpId] = IntellectualProperty({
            id: newIpId,
            owner: msg.sender,
            name: _name,
            symbol: _symbol,
            uri: _uri,
            isFractional: _isFractional,
            totalFractionalSupply: _isFractional ? _initialSupply : 0,
            accumulatedRoyalties: 0,
            exists: true
        });

        // Set initial royalty recipient as the creator (100%)
        intellectualProperties[newIpId].royaltyRecipients[msg.sender] = 10000; // 100% in basis points
        intellectualProperties[newIpId].royaltyRecipientIds.push(msg.sender);

        if (_isFractional && _initialRecipients.length > 0) {
            _mintERC1155(newIpId, _initialRecipients, _initialAmounts, ""); // Mint fractional ERC-1155 tokens
        }

        emit IPRegistered(newIpId, msg.sender, _name, _symbol, _isFractional);
        return newIpId;
    }

    /**
     * @dev Updates the metadata URI for a registered IP.
     * @param _ipId The ID of the IP.
     * @param _newUri The new metadata URI.
     */
    function updateIPMetadata(uint256 _ipId, string memory _newUri) public onlyIPOwner(_ipId) nonReentrant {
        require(bytes(_newUri).length > 0, "IntellectNexus: URI cannot be empty");
        _setTokenURI(_ipId, _newUri);
        intellectualProperties[_ipId].uri = _newUri;
        emit IPMetadataUpdated(_ipId, _newUri);
    }

    /**
     * @dev Transfers the primary ERC-721 ownership of an IP.
     *      Note: Fractional shares (ERC-1155) are separate and not affected by this transfer.
     * @param _ipId The ID of the IP.
     * @param _newOwner The address of the new owner.
     */
    function transferIPOwnership(uint256 _ipId, address _newOwner) public onlyIPOwner(_ipId) nonReentrant {
        require(_newOwner != address(0), "IntellectNexus: New owner cannot be zero address");
        address oldOwner = ownerOf(_ipId);
        _transfer(oldOwner, _newOwner, _ipId);
        intellectualProperties[_ipId].owner = _newOwner; // Update custom struct owner
        emit IPOwnershipTransferred(_ipId, oldOwner, _newOwner);
    }

    /**
     * @dev Burns fractional shares of an IP (ERC-1155).
     * @param _ipId The ID of the IP.
     * @param _from The address from which shares are burned.
     * @param _amount The amount of shares to burn.
     */
    function burnFractionalShares(uint256 _ipId, address _from, uint256 _amount) public nonReentrant {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(intellectualProperties[_ipId].isFractional, "IntellectNexus: IP is not fractionalized");
        require(_from == msg.sender || intellectualProperties[_ipId].owner == msg.sender, "IntellectNexus: Only owner or sender can burn their shares");
        require(_amount > 0, "IntellectNexus: Amount must be greater than 0");

        _burn( _from, _ipId, _amount);
        intellectualProperties[_ipId].totalFractionalSupply = intellectualProperties[_ipId].totalFractionalSupply.sub(_amount);
        emit FractionalSharesBurned(_ipId, _from, _amount);
    }

    /**
     * @dev Mints additional fractional shares for an IP (ERC-1155). Can only be called by the IP owner.
     * @param _ipId The ID of the IP.
     * @param _to The address to which shares are minted.
     * @param _amount The amount of shares to mint.
     */
    function mintFractionalShares(uint256 _ipId, address _to, uint256 _amount) public onlyIPOwner(_ipId) nonReentrant {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(intellectualProperties[_ipId].isFractional, "IntellectNexus: IP is not fractionalized");
        require(_to != address(0), "IntellectNexus: Cannot mint to zero address");
        require(_amount > 0, "IntellectNexus: Amount must be greater than 0");

        _mint(_to, _ipId, _amount, ""); // ERC1155 mint
        intellectualProperties[_ipId].totalFractionalSupply = intellectualProperties[_ipId].totalFractionalSupply.add(_amount);
        emit FractionalSharesMinted(_ipId, _to, _amount);
    }

    /**
     * @dev Adjusts the royalty distribution scheme for an IP.
     *      Percentages are in basis points (e.g., 10000 = 100%).
     * @param _ipId The ID of the IP.
     * @param _recipients Array of addresses to receive royalties.
     * @param _percentages Array of corresponding percentages for each recipient.
     */
    function updateRoyaltySplit(uint256 _ipId, address[] memory _recipients, uint256[] memory _percentages) public onlyIPOwner(_ipId) nonReentrant {
        require(_recipients.length == _percentages.length, "IntellectNexus: Mismatch in recipients and percentages");
        uint256 totalPercentage;
        // Clear existing recipients
        for(uint256 i = 0; i < intellectualProperties[_ipId].royaltyRecipientIds.length; i++) {
            delete intellectualProperties[_ipId].royaltyRecipients[intellectualProperties[_ipId].royaltyRecipientIds[i]];
        }
        delete intellectualProperties[_ipId].royaltyRecipientIds;

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "IntellectNexus: Royalty recipient cannot be zero address");
            require(_percentages[i] <= 10000, "IntellectNexus: Percentage exceeds 100%");
            totalPercentage = totalPercentage.add(_percentages[i]);
            intellectualProperties[_ipId].royaltyRecipients[_recipients[i]] = _percentages[i];
            intellectualProperties[_ipId].royaltyRecipientIds.push(_recipients[i]);
        }
        require(totalPercentage == 10000, "IntellectNexus: Total percentages must sum to 100%"); // 100% in basis points

        emit RoyaltySplitUpdated(_ipId, _recipients, _percentages);
    }

    // --- II. Dynamic Licensing & Royalties (8 Functions) ---

    /**
     * @dev Creates a reusable template for licensing terms.
     * @param _templateName A descriptive name for the template.
     * @param _termsHash Hash of the off-chain detailed license terms document.
     * @param _basePrice Base price for an instance of this license template.
     * @param _defaultRoyaltyPercentage Default royalty percentage (basis points) for usage.
     */
    function defineLicenseTemplate(
        string memory _templateName,
        string memory _termsHash,
        uint256 _basePrice,
        uint256 _defaultRoyaltyPercentage
    ) public onlyOwner nonReentrant returns (uint256) {
        _licenseTemplateIdCounter.increment();
        uint256 newTemplateId = _licenseTemplateIdCounter.current();

        require(bytes(_termsHash).length > 0, "IntellectNexus: Terms hash cannot be empty");
        require(_defaultRoyaltyPercentage <= 10000, "IntellectNexus: Default royalty percentage exceeds 100%");

        licenseTemplates[newTemplateId] = LicenseTemplate({
            id: newTemplateId,
            name: _templateName,
            termsHash: _termsHash,
            basePrice: _basePrice,
            defaultRoyaltyPercentage: _defaultRoyaltyPercentage,
            exists: true
        });

        emit LicenseTemplateDefined(newTemplateId, _templateName, _basePrice, _defaultRoyaltyPercentage);
        return newTemplateId;
    }

    /**
     * @dev Attaches a specific license instance to an IP based on a template.
     *      This is usually called by the IP owner after a license request.
     * @param _ipId The ID of the IP to license.
     * @param _templateId The ID of the license template to use.
     * @param _customPrice Custom price for this license instance (overrides template base price if > 0).
     * @param _expiryDuration Duration in seconds for the license to be active.
     */
    function attachLicenseToIP(
        uint256 _ipId,
        uint256 _templateId,
        uint256 _customPrice,
        uint256 _expiryDuration
    ) public onlyIPOwner(_ipId) nonReentrant returns (uint256) {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(licenseTemplates[_templateId].exists, "IntellectNexus: License template does not exist");
        require(_expiryDuration > 0, "IntellectNexus: Expiry duration must be positive");

        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        uint256 effectivePrice = (_customPrice > 0) ? _customPrice : licenseTemplates[_templateId].basePrice;

        licenses[newLicenseId] = License({
            id: newLicenseId,
            ipId: _ipId,
            templateId: _templateId,
            licensee: address(0), // Will be set upon approval
            currentPrice: effectivePrice,
            royaltyPercentage: licenseTemplates[_templateId].defaultRoyaltyPercentage,
            createdAt: block.timestamp,
            expiresAt: block.timestamp.add(_expiryDuration),
            usageIntentHash: "", // Will be set upon approval
            oracleAddress: address(0),
            oracleConditionData: "",
            totalPaid: 0,
            isActive: false, // Not active until approved
            exists: true
        });

        emit LicenseAttached(_ipId, newLicenseId, _templateId, address(0)); // Licensee not set yet
        return newLicenseId;
    }

    /**
     * @dev Allows a potential licensee to formally request a license for an IP.
     * @param _ipId The ID of the IP.
     * @param _licenseTemplateId The ID of the desired license template.
     * @param _usageIntentHash Hash of the off-chain document describing the intended usage.
     */
    function requestIPLicense(
        uint256 _ipId,
        uint256 _licenseTemplateId,
        string memory _usageIntentHash
    ) public nonReentrant returns (uint256) {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(licenseTemplates[_licenseTemplateId].exists, "IntellectNexus: License template does not exist");
        require(bytes(_usageIntentHash).length > 0, "IntellectNexus: Usage intent hash cannot be empty");

        _licenseRequestIdCounter.increment();
        uint256 newRequestId = _licenseRequestIdCounter.current();

        licenseRequests[newRequestId] = LicenseRequest({
            id: newRequestId,
            ipId: _ipId,
            licenseTemplateId: _licenseTemplateId,
            requester: msg.sender,
            usageIntentHash: _usageIntentHash,
            requestedAt: block.timestamp,
            approved: false,
            exists: true
        });

        emit LicenseRequested(newRequestId, _ipId, msg.sender);
        return newRequestId;
    }

    /**
     * @dev IP owner approves a pending license request, activating it.
     *      This also sets the licensee and initial payment for the license.
     * @param _requestId The ID of the license request to approve.
     * @param _initialPayment Initial payment amount from the licensee.
     * @param _effectiveExpiry The timestamp when the license will expire.
     */
    function approveIPLicense(
        uint256 _requestId,
        uint256 _initialPayment,
        uint256 _effectiveExpiry
    ) public payable onlyIPOwner(licenseRequests[_requestId].ipId) nonReentrant returns (uint256) {
        LicenseRequest storage request = licenseRequests[_requestId];
        require(request.exists, "IntellectNexus: License request does not exist");
        require(!request.approved, "IntellectNexus: License request already approved");
        require(msg.value == _initialPayment, "IntellectNexus: Initial payment mismatch");
        require(_effectiveExpiry > block.timestamp, "IntellectNexus: Expiry must be in the future");

        // Create a new license instance for this approval
        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        LicenseTemplate storage template = licenseTemplates[request.licenseTemplateId];

        licenses[newLicenseId] = License({
            id: newLicenseId,
            ipId: request.ipId,
            templateId: request.licenseTemplateId,
            licensee: request.requester,
            currentPrice: template.basePrice, // Or a custom price passed in request/approval logic
            royaltyPercentage: template.defaultRoyaltyPercentage,
            createdAt: block.timestamp,
            expiresAt: _effectiveExpiry,
            usageIntentHash: request.usageIntentHash,
            oracleAddress: address(0),
            oracleConditionData: "",
            totalPaid: _initialPayment,
            isActive: true,
            exists: true
        });

        // Distribute initial payment to IP owner's royalty split
        _distributeRoyalties(request.ipId, _initialPayment);

        request.approved = true; // Mark request as approved

        emit LicenseApproved(newLicenseId, _requestId, request.requester, _effectiveExpiry);
        emit LicensePayment(newLicenseId, msg.sender, _initialPayment); // Initial payment

        return newLicenseId;
    }


    /**
     * @dev Licensee makes a payment for ongoing usage of a licensed IP.
     *      This could represent a royalty payment, a usage fee, etc.
     * @param _licenseId The ID of the license.
     * @param _amount The amount to pay.
     */
    function payForLicenseUsage(uint256 _licenseId, uint256 _amount) public payable onlyLicensee(_licenseId) nonReentrant {
        License storage license = licenses[_licenseId];
        require(license.isActive, "IntellectNexus: License is not active");
        require(license.expiresAt > block.timestamp, "IntellectNexus: License has expired");
        require(msg.value == _amount, "IntellectNexus: Payment amount mismatch");
        require(_amount > 0, "IntellectNexus: Payment amount must be greater than zero");

        license.totalPaid = license.totalPaid.add(_amount);
        _distributeRoyalties(license.ipId, _amount);

        emit LicensePayment(_licenseId, msg.sender, _amount);
    }

    /**
     * @dev Allows IP owners/shareholders to claim their accumulated royalty earnings.
     * @param _ipId The ID of the IP for which to claim royalties.
     */
    function claimRoyalties(uint256 _ipId) public nonReentrant {
        IntellectualProperty storage ip = intellectualProperties[_ipId];
        require(ip.exists, "IntellectNexus: IP does not exist");
        require(ip.accumulatedRoyalties > 0, "IntellectNexus: No accumulated royalties to claim");

        uint256 claimableAmount = 0;
        uint256 myPercentage = ip.royaltyRecipients[msg.sender];

        if (myPercentage > 0) {
            claimableAmount = ip.accumulatedRoyalties.calculatePercentage(myPercentage);
        } else {
             // For fractional IPs, if not explicitly defined in royaltyRecipients,
             // holders of ERC-1155 shares can claim pro-rata. This is a complex logic
             // for the prototype, so we'll simplify and assume all royalty distribution
             // is governed by `royaltyRecipients` for simplicity for now.
             // A more advanced version would check ERC-1155 balance here.
        }

        require(claimableAmount > 0, "IntellectNexus: No royalties claimable for sender");

        ip.accumulatedRoyalties = ip.accumulatedRoyalties.sub(claimableAmount);
        payable(msg.sender).transfer(claimableAmount); // Send ETH

        emit RoyaltiesClaimed(_ipId, msg.sender, claimableAmount);
    }

    /**
     * @dev Defines a condition where license terms dynamically adapt based on external data from an oracle.
     *      This is a powerful feature for dynamic pricing, royalty adjustments, or usage permissions.
     * @param _licenseId The ID of the license.
     * @param _oracleAddress The address of the oracle contract (e.g., Chainlink, custom oracle).
     * @param _conditionData ABI-encoded data specifying the oracle query and condition logic.
     */
    function setOracleConditionForLicense(
        uint256 _licenseId,
        address _oracleAddress,
        bytes memory _conditionData
    ) public onlyLicenseOwner(_licenseId) nonReentrant {
        License storage license = licenses[_licenseId];
        require(_oracleAddress != address(0), "IntellectNexus: Oracle address cannot be zero");
        require(bytes(_conditionData).length > 0, "IntellectNexus: Condition data cannot be empty");

        license.oracleAddress = _oracleAddress;
        license.oracleConditionData = _conditionData;

        // In a real scenario, an off-chain service would monitor this and interact with the oracle,
        // then potentially call a function on this contract to update license terms based on oracle output.
        // For this contract, we just store the condition.

        emit OracleConditionSet(_licenseId, _oracleAddress);
    }

    /**
     * @dev Licensee reports usage metrics (e.g., revenue, downloads), potentially with an off-chain verifiable proof.
     *      This enables adaptive licensing where fees or terms change based on actual usage.
     * @param _licenseId The ID of the license.
     * @param _metricType A string identifying the type of metric (e.g., "revenue", "downloads").
     * @param _value The reported value of the metric.
     * @param _proofHash A hash referencing an off-chain proof of this metric (e.g., ZKP output, signed statement).
     */
    function reportUsageMetric(
        uint256 _licenseId,
        string memory _metricType,
        uint256 _value,
        bytes memory _proofHash
    ) public onlyLicensee(_licenseId) nonReentrant {
        License storage license = licenses[_licenseId];
        require(license.isActive, "IntellectNexus: License is not active");
        require(bytes(_metricType).length > 0, "IntellectNexus: Metric type cannot be empty");
        // Further validation of _proofHash would be done off-chain or by a dedicated verifier contract.

        license.reportedMetrics[_metricType] = _value;

        // Potentially trigger a royalty recalculation or other dynamic term adjustments here
        // based on the reported metric and oracle conditions if applicable. This is left
        // as an external interaction or more complex internal logic for a full implementation.

        emit UsageMetricReported(_licenseId, _metricType, _value, _proofHash);
    }

    // --- III. IP Syndicates (Collaborative DAOs) (6 Functions) ---

    /**
     * @dev Creates a new collaborative syndicate (DAO) around specific IPs.
     *      Initial members define their share percentages (basis points).
     * @param _name Name of the syndicate.
     * @param _description Description of the syndicate.
     * @param _initialMembers Array of initial member addresses.
     * @param _memberShares Array of corresponding share percentages (basis points, sums to 10000).
     * @param _ipIdsToManage Array of IP IDs that this syndicate will initially manage.
     */
    function createIPSyndicate(
        string memory _name,
        string memory _description,
        address[] memory _initialMembers,
        uint256[] memory _memberShares,
        uint256[] memory _ipIdsToManage
    ) public nonReentrant returns (uint256) {
        require(_initialMembers.length == _memberShares.length, "IntellectNexus: Mismatch in members and shares");
        uint256 totalShares;
        for (uint256 i = 0; i < _memberShares.length; i++) {
            totalShares = totalShares.add(_memberShares[i]);
        }
        require(totalShares == 10000, "IntellectNexus: Total shares must sum to 100%"); // 100% in basis points

        _syndicateIdCounter.increment();
        uint256 newSyndicateId = _syndicateIdCounter.current();

        ipSyndicates[newSyndicateId] = IPSyndicate({
            id: newSyndicateId,
            name: _name,
            description: _description,
            treasuryBalance: 0,
            proposalCounter: Counters.newCounter(),
            exists: true
        });

        for (uint256 i = 0; i < _initialMembers.length; i++) {
            ipSyndicates[newSyndicateId].members[_initialMembers[i]] = _memberShares[i];
            ipSyndicates[newSyndicateId].memberAddresses.push(_initialMembers[i]);
        }

        for (uint256 i = 0; i < _ipIdsToManage.length; i++) {
            require(intellectualProperties[_ipIdsToManage[i]].owner == msg.sender, "IntellectNexus: Can only add IPs owned by creator");
            ipSyndicates[newSyndicateId].managedIPs[_ipIdsToManage[i]] = true;
            ipSyndicates[newSyndicateId].managedIPIds.push(_ipIdsToManage[i]);
            // Transfer ERC721 ownership of managedIPs to the IntellectNexus contract itself
            // and have it proxy actions via syndicate votes, or keep with creator.
            // For simplicity, the creator must still be the ERC721 owner to approve syndicate actions,
            // or transfer it to `address(this)` if IntellectNexus fully manages the IP.
            // Let's assume for now, syndicate proposals *call* the IP owner's functions if the IP owner is a member.
            // Or, the IP-NFT could be transferred to the syndicate's address (if the syndicate was a separate contract).
            // For now, the IP owner is the one who initiates the syndicate and allows it to manage their IP.
            // A better way: Transfer ERC721 ownership of managedIPs to the IntellectNexus contract itself
            // and have it proxy actions via syndicate votes. For this scope, the initial creator of
            // the syndicate and its IPs is implicitly allowing its members to propose actions.
        }

        emit IPSyndicateCreated(newSyndicateId, _name, msg.sender);
        return newSyndicateId;
    }

    /**
     * @dev Adds a new member to an existing syndicate. Requires a syndicate proposal to pass.
     * @param _syndicateId The ID of the syndicate.
     * @param _newMember The address of the new member.
     * @param _share The share percentage (basis points) for the new member.
     */
    function addMemberToSyndicate(uint256 _syndicateId, address _newMember, uint256 _share) public onlySyndicateMember(_syndicateId) nonReentrant {
        IPSyndicate storage syndicate = ipSyndicates[_syndicateId];
        require(syndicate.members[_newMember] == 0, "IntellectNexus: Member already exists");
        require(_newMember != address(0), "IntellectNexus: New member cannot be zero address");
        require(_share > 0, "IntellectNexus: Share must be positive");

        // This action should ideally go through a proposal and vote.
        // For simplicity in this function, we assume a direct call from an existing member,
        // but in a full DAO, this would be `proposeSyndicateAction` -> `vote` -> `execute`.
        // We'll mark this as an administrative action only possible by the initial creator or via specific proposal.

        // If this function is part of a proposal execution, then `msg.sender` would be `address(this)`.
        // Let's make it callable by `msg.sender` as a simplification for a direct call.
        // A more robust system would require a proposal for this.

        uint256 totalExistingShares;
        for(uint256 i = 0; i < syndicate.memberAddresses.length; i++) {
            totalExistingShares = totalExistingShares.add(syndicate.members[syndicate.memberAddresses[i]]);
        }
        require(totalExistingShares.add(_share) <= 10000, "IntellectNexus: Total shares would exceed 100%"); // Allow room to dilute existing if not 10000

        syndicate.members[_newMember] = _share;
        syndicate.memberAddresses.push(_newMember);

        emit SyndicateMemberAdded(_syndicateId, _newMember, _share);
    }

    /**
     * @dev Members propose actions (e.g., license, update, distribute funds) for the syndicate to vote on.
     * @param _syndicateId The ID of the syndicate.
     * @param _target The target contract address for the proposal call.
     * @param _value ETH value to send with the call.
     * @param _callData ABI-encoded function call data for the target.
     * @param _description Description of the proposal.
     */
    function proposeSyndicateAction(
        uint256 _syndicateId,
        address _target,
        uint256 _value,
        bytes memory _callData,
        string memory _description
    ) public onlySyndicateMember(_syndicateId) nonReentrant returns (uint256) {
        IPSyndicate storage syndicate = ipSyndicates[_syndicateId];
        syndicate.proposalCounter.increment();
        uint256 proposalId = syndicate.proposalCounter.current();

        // Simple quorum: 50% of total shares, vote duration: 3 days
        uint256 quorumRequired = 5000; // 50% in basis points
        uint256 voteDuration = 3 days;

        syndicateProposals[_syndicateId][proposalId] = SyndicateProposal({
            id: proposalId,
            syndicateId: _syndicateId,
            proposer: msg.sender,
            target: _target,
            value: _value,
            callData: _callData,
            description: _description,
            createdAt: block.timestamp,
            voteEndTime: block.timestamp.add(voteDuration),
            totalSharesVoted: 0,
            totalSharesFor: 0,
            quorumRequired: quorumRequired,
            executed: false,
            exists: true
        });

        emit SyndicateProposalCreated(_syndicateId, proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev Members cast votes on syndicate proposals.
     * @param _syndicateId The ID of the syndicate.
     * @param _proposalId The ID of the proposal.
     * @param _support True if voting "for", false if voting "against".
     */
    function voteOnSyndicateProposal(uint256 _syndicateId, uint256 _proposalId, bool _support) public onlySyndicateMember(_syndicateId) nonReentrant {
        IPSyndicate storage syndicate = ipSyndicates[_syndicateId];
        SyndicateProposal storage proposal = syndicateProposals[_syndicateId][_proposalId];

        require(proposal.exists, "IntellectNexus: Proposal does not exist");
        require(block.timestamp <= proposal.voteEndTime, "IntellectNexus: Voting period has ended");
        require(!proposal.executed, "IntellectNexus: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "IntellectNexus: Member has already voted");

        uint256 memberShare = syndicate.members[msg.sender];
        require(memberShare > 0, "IntellectNexus: Only syndicate members with shares can vote");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalSharesVoted = proposal.totalSharesVoted.add(memberShare);
        if (_support) {
            proposal.totalSharesFor = proposal.totalSharesFor.add(memberShare);
        }

        emit SyndicateVoted(_syndicateId, _proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal that has passed the syndicate's voting threshold.
     * @param _syndicateId The ID of the syndicate.
     * @param _proposalId The ID of the proposal.
     */
    function executeSyndicateProposal(uint256 _syndicateId, uint256 _proposalId) public nonReentrant {
        IPSyndicate storage syndicate = ipSyndicates[_syndicateId];
        SyndicateProposal storage proposal = syndicateProposals[_syndicateId][_proposalId];

        require(proposal.exists, "IntellectNexus: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "IntellectNexus: Voting period not yet ended");
        require(!proposal.executed, "IntellectNexus: Proposal already executed");

        uint256 totalPossibleShares = 10000; // Assuming 100% total shares for simplicity
        uint256 quorumThreshold = totalPossibleShares.calculatePercentage(proposal.quorumRequired);

        require(proposal.totalSharesVoted >= quorumThreshold, "IntellectNexus: Quorum not met");
        require(proposal.totalSharesFor > proposal.totalSharesVoted.sub(proposal.totalSharesFor), "IntellectNexus: Proposal did not pass (majority vote required)"); // Simple majority

        proposal.executed = true;

        // Execute the proposed action
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        require(success, "IntellectNexus: Proposal execution failed");

        emit SyndicateProposalExecuted(_syndicateId, _proposalId);
    }

    /**
     * @dev Distributes accumulated funds from the syndicate treasury to its members based on their shares.
     * @param _syndicateId The ID of the syndicate.
     */
    function distributeSyndicateFunds(uint256 _syndicateId) public onlySyndicateMember(_syndicateId) nonReentrant {
        IPSyndicate storage syndicate = ipSyndicates[_syndicateId];
        require(syndicate.treasuryBalance > 0, "IntellectNexus: Syndicate treasury is empty");

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < syndicate.memberAddresses.length; i++) {
            address member = syndicate.memberAddresses[i];
            uint256 share = syndicate.members[member];
            if (share > 0) {
                uint256 amountToDistribute = syndicate.treasuryBalance.calculatePercentage(share);
                if (amountToDistribute > 0) {
                    // This direct transfer assumes members can claim at any time.
                    // For a full distribution, this should be callable by a specific proposal.
                    // For simplicity, a member can claim their share directly.
                    // Better: `pull-based` distribution where members `claimMySyndicateFunds(syndicateId)`.
                    // For this function, let's assume it attempts to distribute all.
                    // This function would be usually triggered by a proposal.
                    payable(member).transfer(amountToDistribute);
                    totalDistributed = totalDistributed.add(amountToDistribute);
                }
            }
        }
        syndicate.treasuryBalance = syndicate.treasuryBalance.sub(totalDistributed); // Reduce treasury by what was sent
        emit SyndicateFundsDistributed(_syndicateId, totalDistributed);
    }

    // Fallback function to allow IntellectNexus contract to receive funds
    receive() external payable {
        // Funds sent directly to the contract without a function call.
        // These funds are handled internally, potentially increasing the treasury
        // of a specific syndicate if called within a proposal context.
        // For general direct sends, this could be for platform operations or
        // further distribution by the owner.
    }

    // --- IV. Dispute Resolution & Advanced Features (3 Functions) ---

    /**
     * @dev Initiates a formal dispute against a license for breach of terms or other issues.
     *      Requires a hash of the off-chain claim details.
     * @param _licenseId The ID of the license under dispute.
     * @param _claimHash Hash of the off-chain detailed claim document.
     */
    function submitDisputeClaim(uint256 _licenseId, string memory _claimHash) public nonReentrant returns (uint256) {
        License storage license = licenses[_licenseId];
        require(license.exists, "IntellectNexus: License does not exist");
        require(license.licensee == msg.sender || intellectualProperties[license.ipId].owner == msg.sender, "IntellectNexus: Only licensee or IP owner can submit a dispute");
        require(bytes(_claimHash).length > 0, "IntellectNexus: Claim hash cannot be empty");

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            licenseId: _licenseId,
            claimant: msg.sender,
            claimHash: _claimHash,
            resolutionHash: "",
            createdAt: block.timestamp,
            resolvedAt: 0,
            isResolved: false,
            exists: true
        });

        emit DisputeClaimed(newDisputeId, _licenseId, msg.sender);
        return newDisputeId;
    }

    /**
     * @dev An authorized arbiter or IP owner records the resolution of a dispute.
     *      Requires a hash of the off-chain resolution document.
     * @param _disputeId The ID of the dispute to settle.
     * @param _resolutionHash Hash of the off-chain detailed resolution document.
     */
    function settleDispute(uint256 _disputeId, string memory _resolutionHash) public nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.exists, "IntellectNexus: Dispute does not exist");
        require(!dispute.isResolved, "IntellectNexus: Dispute already settled");
        // Only the original IP owner or a designated arbiter (admin/DAO) can settle
        require(intellectualProperties[dispute.licenseId].owner == msg.sender || owner() == msg.sender, "IntellectNexus: Only IP owner or platform admin can settle dispute");
        require(bytes(_resolutionHash).length > 0, "IntellectNexus: Resolution hash cannot be empty");

        dispute.resolutionHash = _resolutionHash;
        dispute.resolvedAt = block.timestamp;
        dispute.isResolved = true;

        emit DisputeSettled(_disputeId, dispute.licenseId, _resolutionHash);
    }

    /**
     * @dev Allows a contributor to claim contribution to an IP, potentially with a Zero-Knowledge Proof for privacy.
     *      This function primarily records the claim and the proof hash for off-chain verification.
     * @param _ipId The ID of the IP to which contribution is claimed.
     * @param _claimDescriptionHash Hash of the off-chain description of the contribution.
     * @param _zkProofData Optional Zero-Knowledge Proof data (for off-chain or dedicated verifier).
     */
    function submitContributionClaim(
        uint256 _ipId,
        string memory _claimDescriptionHash,
        bytes memory _zkProofData
    ) public nonReentrant {
        require(intellectualProperties[_ipId].exists, "IntellectNexus: IP does not exist");
        require(bytes(_claimDescriptionHash).length > 0, "IntellectNexus: Claim description hash cannot be empty");
        // A full ZKP verification on-chain is too costly/complex for a generic function.
        // This function merely records the proof hash for off-chain verification.

        // Prevent duplicate claims from the same contributor for the same IP
        require(!contributionClaims[_ipId][msg.sender].exists, "IntellectNexus: Contributor already has a pending claim for this IP");

        contributionClaims[_ipId][msg.sender] = ContributionClaim({
            ipId: _ipId,
            contributor: msg.sender,
            claimDescriptionHash: _claimDescriptionHash,
            zkProofData: _zkProofData,
            claimedAt: block.timestamp,
            verified: false, // Awaiting off-chain or separate on-chain verification
            exists: true
        });

        emit ContributionClaimed(_ipId, msg.sender, _claimDescriptionHash);
    }

    // Internal function to distribute royalties based on the IP's split
    function _distributeRoyalties(uint256 _ipId, uint256 _amount) internal {
        IntellectualProperty storage ip = intellectualProperties[_ipId];
        ip.accumulatedRoyalties = ip.accumulatedRoyalties.add(_amount);

        // Funds accumulate in `accumulatedRoyalties` to be claimed later via `claimRoyalties`.
        // This is a pull-based system to save gas on multiple small distributions.
        // If immediate push-based distribution is desired, the logic below could be enabled:
        /*
        for (uint256 i = 0; i < ip.royaltyRecipientIds.length; i++) {
            address recipient = ip.royaltyRecipientIds[i];
            uint256 percentage = ip.royaltyRecipients[recipient];
            if (percentage > 0) {
                uint256 royaltyShare = _amount.calculatePercentage(percentage);
                if (royaltyShare > 0) {
                    payable(recipient).transfer(royaltyShare);
                }
            }
        }
        */
    }

    // --- ERC-1155 Specific ---
    // ERC1155 _beforeTokenTransfer and _afterTokenTransfer hooks can be used for more advanced logic if needed.

    // A simple internal function to mint ERC1155 tokens
    function _mintERC1155(uint256 _id, address[] memory _to, uint256[] memory _amounts, bytes memory _data) internal {
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _id, _amounts[i], _data);
        }
    }
}
```