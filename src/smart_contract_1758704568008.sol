Here's a smart contract written in Solidity for a "Decentralized Autonomous Intellectual Property & Knowledge Network (DAI PKN)", incorporating advanced, creative, and trendy concepts.

The contract focuses on the lifecycle of digital intellectual property, from registration and licensing to community-driven knowledge curation, reputation building (using Soulbound Token-like profiles), and grant funding. It includes novel features like collateralized temporary IP access and explicit AI usage consent.

---

**Solidity Smart Contract: `IntellectusNexus`**

**Outline:**

1.  **Contract Description**: Core purpose and vision.
2.  **Global State & Configuration**: Counters, constants, and configurable parameters.
3.  **Enums**: Define various states for IP, licenses, knowledge nodes, and disputes.
4.  **Structs**: Data structures for IP, License Offers, Active Licenses, Knowledge Nodes, Grant Proposals, IP Disputes, and Collateralized Access.
5.  **Mappings**: To store instances of structs and track relationships.
6.  **Events**: For logging important on-chain actions.
7.  **Modifiers**: For access control and common checks.
8.  **Constructor**: Initializes external ERC721 contracts for IP and Profiles.
9.  **Function Categories**:
    *   **I. Core IP Management**: Registering, updating, transferring, and setting IP attributes.
    *   **II. Licensing & Monetization**: Creating, accepting, revoking licenses, and managing royalties.
    *   **III. Knowledge Curation & Reputation**: Minting profiles, submitting/voting on knowledge, and earning achievements.
    *   **IV. Funding & Collaboration**: Creating, voting on, and funding research grants.
    *   **V. Advanced / Creative Features**: IP dispute resolution, collateralized IP access, AI usage consent, and public domain release.
    *   **VI. View Functions**: Public getters for contract data.

**Function Summary:**

**I. Core IP Management (NFT-based `IntellectusProperty` ERC721)**
1.  `registerIntellectualProperty`: Mints a new IP NFT, setting initial metadata, ownership, and transferability status.
2.  `updateIPMetadata`: Allows IP owner to update certain non-critical metadata (e.g., description, tags, external links).
3.  `transferIPOwnership`: Transfers ownership of a *transferrable* IP NFT.
4.  `makeIPNonTransferable`: Allows an owner to make their IP NFT permanently non-transferable (e.g., for Soulbound IP).
5.  `addCoOwner`: Adds a co-owner to an IP, specifying their share (multi-sig or split ownership model).
6.  `removeCoOwner`: Removes a co-owner.

**II. Licensing & Monetization**
7.  `createLicenseOffer`: IP owner proposes a license agreement (terms, duration, price, royalty share).
8.  `acceptLicenseOffer`: A licensee accepts an existing license offer by paying the fee.
9.  `revokeLicenseOffer`: IP owner revokes an active, unaccepted license offer.
10. `terminateActiveLicense`: Either party (owner/licensee) can initiate termination based on contract terms.
11. `payLicenseFee`: Licensee pays recurring fees or royalty payments, with funds collected in a pool for the IP.
12. `distributeRoyalties`: Callable by anyone to distribute collected royalties from an IP's pool to its primary owner (simplified).
13. `setDerivedWorkRoyaltySplit`: IP owner defines a protocol-level royalty percentage to be paid to the original IP from derived work's revenue.

**III. Knowledge Curation & Reputation (SBT-like `IntellectusProfile` ERC721)**
14. `mintIntellectusProfile`: Mints a non-transferable profile NFT for a new user, establishing their on-chain identity.
15. `submitKnowledgeNode`: Users (with a profile) can submit verified knowledge/research related to an IP or a general concept.
16. `stakeForCuration`: Stake tokens (ETH) to gain rights to vote on `KnowledgeNodes` and earn rewards.
17. `voteOnKnowledgeNode`: Curators vote on the veracity, quality, and relevance of submitted knowledge.
18. `claimCurationReward`: Placeholder for successful curators to claim rewards based on their accurate votes (logic simplified).
19. `addAchievementToProfile`: IP owners or protocol can grant specific achievements/badges to `IntellectusProfiles`.

**IV. Funding & Collaboration**
20. `createResearchGrantProposal`: A user proposes a research or development project related to specific IP(s).
21. `voteOnGrantProposal`: `IntellectusProfile` holders can vote on grant proposals.
22. `contributeToGrant`: Anyone can contribute funds to an approved grant proposal.
23. `claimGrantFunds`: Project leader claims vested funds from a successful grant.

**V. Advanced / Creative Features**
24. `initiateIPDispute`: Users can formally initiate a dispute regarding IP ownership, license terms, or knowledge node validity.
25. `resolveDispute`: Designated arbitrators or DAO can resolve disputes, potentially triggering state changes.
26. `requestCollateralizedIPAccess`: Allows temporary, collateralized access to an IP's underlying data for analysis, AI training, or simulation.
27. `signalAIUsageConsent`: IP owner explicitly signals consent for their IP to be used for AI model training under specific terms.
28. `releaseIPToPublicDomain`: IP owner irrevocably releases their IP into the public domain.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// ERC721Burnable could be used for non-transferable IP in specific scenarios, but not explicitly used for primary IP in this version
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title IntellectusNexus
 * @dev A Decentralized Autonomous Intellectual Property & Knowledge Network (DAI PKN).
 * This contract enables on-chain registration, licensing, and monetization of intellectual property (IP),
 * fosters knowledge sharing and curation, builds creator reputation using Soulbound Token (SBT)-like profiles,
 * and facilitates grant-based funding for IP-related projects. It integrates advanced concepts like
 * dynamic NFT attributes, conditional collateralized IP access, and AI usage consent.
 *
 * It utilizes two external ERC721 contracts: one for representing Intellectual Property assets (`IntellectusProperty`)
 * and another for representing non-transferable creator profiles (`IntellectusProfile`).
 */
contract IntellectusNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- GLOBAL STATE ---
    Counters.Counter private _ipIdCounter;
    Counters.Counter private _profileIdCounter;
    Counters.Counter private _licenseIdCounter;
    Counters.Counter private _knowledgeNodeIdCounter;
    Counters.Counter private _grantProposalIdCounter;
    Counters.Counter private _disputeIdCounter;

    // --- CONFIGURABLE PARAMETERS ---
    uint256 public constant MIN_CURATION_STAKE = 1 ether; // Minimum ETH to stake for curation rights
    uint256 public constant KNOWLEDGE_NODE_VOTE_PERIOD = 7 days; // How long curators can vote on a knowledge node
    uint256 public constant GRANT_VOTING_PERIOD = 14 days; // How long for grant voting
    uint256 public constant GRANT_CONTRIBUTION_PERIOD = 30 days; // How long to contribute to a successful grant
    uint256 public constant MIN_DISPUTE_FEE = 0.1 ether; // Minimum ETH to initiate a dispute

    // --- ENUMS ---
    enum IPStatus { Registered, Licensed, Disputed, PublicDomain }
    enum LicenseStatus { Pending, Active, Terminated, Expired }
    enum KnowledgeNodeStatus { PendingValidation, Validated, Rejected }
    enum DisputeStatus { Pending, Resolved, Canceled }

    // --- STRUCTS ---

    // Represents an Intellectual Property asset (ERC721)
    struct IPData {
        string name;
        string uri; // IPFS hash or URL for core IP metadata
        address owner; // Primary owner address
        address[] coOwnerList; // List of all co-owner addresses, including the primary owner
        mapping(address => uint256) coOwners; // For shared ownership, percentage based (sum to 10000 for 100%)
        uint256 totalCoOwnersShare; // Sum of all co-owner percentages, should be 10000 when fully allocated
        bool isTransferable; // Can the IP NFT be transferred?
        IPStatus status;
        address creator; // Original minter of the IP
        uint256 registrationTimestamp;
        bool aiUsageConsent; // Creator's consent for AI model training under default terms
        string aiUsageTermsUri; // URI to specific AI usage terms if different from default
    }

    // Represents a License Offer made by an IP owner
    struct LicenseOffer {
        uint252 ipId;
        address offeredBy; // IP owner creating the offer
        address intendedLicensee; // Can be address(0) for open offer
        uint256 price; // Price in Wei
        uint256 royaltyPercentage; // Percentage of revenue from derived works (e.g., 500 for 5%)
        uint256 duration; // Duration in seconds (0 for perpetual)
        string termsUri; // IPFS hash or URL for detailed license terms
        LicenseStatus status;
        uint256 offerTimestamp;
    }

    // Represents an Active License
    struct ActiveLicense {
        uint252 licenseId; // Reference to original offer
        uint252 ipId;
        address licensee;
        address licensor;
        uint256 startTime;
        uint256 endTime; // 0 for perpetual
        uint256 royaltyPercentage;
        string termsUri;
        LicenseStatus status;
    }

    // Represents a Knowledge Node submitted by a user
    struct KnowledgeNode {
        uint252 ipId; // Related IP (0 if general knowledge)
        address submitter;
        string title;
        string contentUri; // IPFS hash or URL for the knowledge content
        KnowledgeNodeStatus status;
        uint256 submissionTime;
        mapping(address => bool) voted; // Tracks if an address has voted
        uint256 upvotes;
        uint256 downvotes;
    }

    // Represents a Grant Proposal for funding research/development
    struct GrantProposal {
        uint252 proposalId;
        address proposer;
        uint256 targetAmount; // Target funding in Wei
        string title;
        string descriptionUri; // IPFS hash for detailed proposal
        uint252 ipId; // Related IP (0 if general research)
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 fundingEndTime;
        uint256 totalContributions;
        mapping(address => bool) voted; // Tracks if an address has voted
        uint256 upvotes;
        uint256 downvotes;
        bool approved; // True if voting passed
        bool funded; // True if target amount was met
        address[] contributors; // List of unique contributors
        mapping(address => uint256) contributions; // Amount contributed by each address
        mapping(address => bool) fundsClaimed; // Track if proposer has claimed funds for this specific vesting tranche (simplified)
    }

    // Represents an IP Dispute
    struct IPDispute {
        uint252 disputeId;
        uint252 ipId;
        address initiator;
        address defendant;
        string reasonUri; // IPFS hash for dispute details
        DisputeStatus status;
        address[] arbitrators; // Addresses of arbitrators assigned to this dispute
        // mapping(address => bool) arbitratorVotes; // For multi-arbitrator system
        uint256 resolvedTimestamp;
        string resolutionUri; // IPFS hash for resolution details
    }

    // Represents a collateralized access agreement
    struct CollateralizedAccessData {
        uint256 amount;
        uint256 expiry;
        bool active;
    }

    // --- MAPPINGS ---

    // ERC721 for Intellectual Property NFTs (points to an external ERC721 contract)
    ERC721 private _intellectusProperty;
    // Mapping from IP Token ID to IPData
    mapping(uint256 => IPData) public ipData;
    // Mapping IP Token ID to current active license ID
    mapping(uint256 => uint256) public currentActiveLicenseId;
    // Collected royalties per IP, waiting for distribution
    mapping(uint256 => uint256) public ipRoyaltyPools;

    // ERC721 for Soulbound Creator Profile NFTs (points to an external ERC721 contract)
    ERC721 private _intellectusProfile;
    // Mapping from Profile Token ID to address (owner of SBT - always the minter)
    mapping(uint256 => address) public intellectusProfileOwner;
    // Mapping from address to Profile Token ID (for quick lookup)
    mapping(address => uint256) public addressToProfileId;
    // Mapping from Profile Token ID to achievements
    mapping(uint256 => string[]) public profileAchievements;
    // Quick check for profile existence
    mapping(address => bool) public hasProfile;

    // Licenses
    mapping(uint256 => LicenseOffer) public licenseOffers;
    mapping(uint256 => ActiveLicense) public activeLicenses;

    // Knowledge Nodes
    mapping(uint256 => KnowledgeNode) public knowledgeNodes;
    mapping(address => uint256) public curatorStakes; // Amount staked by each curator

    // Grant Proposals
    mapping(uint256 => GrantProposal) public grantProposals;

    // Disputes
    mapping(uint256 => IPDispute) public ipDisputes;
    mapping(address => bool) public isArbitrator; // Tracks who are registered arbitrators

    // Collateralized Access
    mapping(uint256 => mapping(address => CollateralizedAccessData)) public collateralizedAccess;

    // --- EVENTS ---
    event IPRegistered(uint256 indexed ipId, address indexed owner, string name, string uri);
    event IPMetadataUpdated(uint256 indexed ipId, string newUri);
    event IPOwnershipTransferred(uint256 indexed ipId, address indexed from, address indexed to);
    event IPNonTransferable(uint256 indexed ipId);
    event CoOwnerAdded(uint256 indexed ipId, address indexed coOwner, uint256 share);
    event CoOwnerRemoved(uint256 indexed ipId, address indexed coOwner);
    event IPReleasedToPublicDomain(uint256 indexed ipId);

    event LicenseOfferCreated(uint256 indexed licenseId, uint256 indexed ipId, address indexed creator, uint256 price);
    event LicenseOfferAccepted(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee);
    event LicenseOfferRevoked(uint256 indexed licenseId);
    event LicenseTerminated(uint256 indexed licenseId, uint256 indexed ipId, address indexed terminator);
    event LicenseFeePaid(uint256 indexed licenseId, uint256 ipId, address indexed payer, uint256 amount);
    event RoyaltyDistributed(uint256 indexed ipId, uint256 totalAmount, address indexed distributor);
    event DerivedWorkRoyaltySplitSet(uint256 indexed ipId, address indexed owner, uint256 percentage);

    event ProfileMinted(uint256 indexed profileId, address indexed owner);
    event AchievementAdded(uint256 indexed profileId, string achievement);

    event KnowledgeNodeSubmitted(uint256 indexed nodeId, uint256 indexed ipId, address indexed submitter, string title);
    event KnowledgeNodeVoted(uint256 indexed nodeId, address indexed voter, bool isUpvote);
    event KnowledgeNodeValidated(uint256 indexed nodeId);
    event KnowledgeNodeRejected(uint256 indexed nodeId);
    event CurationRewardClaimed(address indexed curator, uint256 amount);

    event GrantProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 targetAmount);
    event GrantProposalVoted(uint256 indexed proposalId, address indexed voter, bool isUpvote);
    event GrantProposalApproved(uint256 indexed proposalId);
    event GrantContributed(uint256 indexed proposalId, address indexed contributor, uint256 amount);
    event GrantFundsClaimed(uint256 indexed proposalId, address indexed claimant, uint256 amount);

    event IPDisputeInitiated(uint256 indexed disputeId, uint256 indexed ipId, address indexed initiator);
    event IPDisputeResolved(uint256 indexed disputeId, uint256 indexed ipId, DisputeStatus finalStatus);
    event ArbitratorSet(address indexed arbitrator, bool status);

    event CollateralizedIPAccessRequested(uint256 indexed ipId, address indexed accessor, uint256 collateralAmount, uint256 expiry);
    event CollateralReleased(uint256 indexed ipId, address indexed accessor, uint256 amount);
    event AIUsageConsentSignaled(uint256 indexed ipId, address indexed owner, bool consented);

    // --- MODIFIERS ---
    modifier onlyIPOwner(uint256 _ipId) {
        require(ipData[_ipId].owner == _msgSender(), "Not primary IP owner");
        _;
    }

    modifier onlyIPParticipant(uint256 _ipId) {
        IPData storage ip = ipData[_ipId];
        require(ip.owner == _msgSender() || ip.coOwners[_msgSender()] > 0, "Not IP owner or co-owner");
        _;
    }

    modifier onlyProfileOwner(uint256 _profileId) {
        require(addressToProfileId[_msgSender()] == _profileId && _profileId != 0, "Not profile owner");
        _;
    }

    modifier onlyWithProfile() {
        require(addressToProfileId[_msgSender()] != 0, "Requires an IntellectusProfile");
        _;
    }

    modifier onlyCurator() {
        require(curatorStakes[_msgSender()] >= MIN_CURATION_STAKE, "Requires minimum curation stake");
        _;
    }

    modifier onlyArbitrator() {
        require(isArbitrator[_msgSender()], "Caller is not an arbitrator");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(address _intellectusPropertyNFTAddress, address _intellectusProfileNFTAddress) Ownable() {
        require(_intellectusPropertyNFTAddress != address(0), "IntellectusProperty NFT address cannot be zero");
        require(_intellectusProfileNFTAddress != address(0), "IntellectusProfile NFT address cannot be zero");

        _intellectusProperty = ERC721(_intellectusPropertyNFTAddress);
        _intellectusProfile = ERC721(_intellectusProfileNFTAddress);
        // In a full implementation, these would likely be deployed by this contract or a factory.
        // For simplicity, we assume pre-deployed OpenZeppelin ERC721 contracts for managing the NFTs.
    }

    // --- I. CORE IP MANAGEMENT (NFT-based `IntellectusProperty` ERC721) ---

    /**
     * @dev 1. Registers a new Intellectual Property asset by minting an ERC721 NFT.
     *   The caller becomes the primary owner and creator. Initial co-owner share set to 100% for primary.
     * @param _name The name of the intellectual property.
     * @param _uri IPFS hash or URL pointing to the detailed IP metadata.
     * @param _isTransferable Whether the IP NFT can be transferred after minting.
     */
    function registerIntellectualProperty(
        string memory _name,
        string memory _uri,
        bool _isTransferable
    ) public nonReentrant returns (uint256) {
        _ipIdCounter.increment();
        uint256 newIpId = _ipIdCounter.current();

        _intellectusProperty.safeMint(_msgSender(), newIpId); // Mints the NFT to the caller

        // Initialize coOwnerList with the primary owner
        address[] memory initialCoOwnerList = new address[](1);
        initialCoOwnerList[0] = _msgSender();

        ipData[newIpId] = IPData({
            name: _name,
            uri: _uri,
            owner: _msgSender(),
            creator: _msgSender(),
            isTransferable: _isTransferable,
            status: IPStatus.Registered,
            registrationTimestamp: block.timestamp,
            aiUsageConsent: false, // Default to no consent
            aiUsageTermsUri: "",
            coOwnerList: initialCoOwnerList, // Store primary owner in the list
            totalCoOwnersShare: 10000 // Primary owner starts with 100%
        });
        ipData[newIpId].coOwners[_msgSender()] = 10000; // Primary owner gets 100.00% share

        emit IPRegistered(newIpId, _msgSender(), _name, _uri);
        return newIpId;
    }

    /**
     * @dev 2. Allows IP owner to update certain non-critical metadata (e.g., description, tags, external links).
     * @param _ipId The ID of the IP NFT.
     * @param _newUri The new IPFS hash or URL for IP metadata.
     */
    function updateIPMetadata(uint256 _ipId, string memory _newUri) public onlyIPParticipant(_ipId) {
        require(bytes(_newUri).length > 0, "URI cannot be empty");
        ipData[_ipId].uri = _newUri;
        emit IPMetadataUpdated(_ipId, _newUri);
    }

    /**
     * @dev 3. Transfers ownership of a *transferrable* IP NFT.
     *   Requires the caller to be the primary owner. This function also updates the primary owner in `ipData`.
     * @param _from Current primary owner.
     * @param _to New primary owner.
     * @param _ipId The ID of the IP NFT.
     */
    function transferIPOwnership(address _from, address _to, uint256 _ipId) public onlyIPOwner(_ipId) {
        require(ipData[_ipId].isTransferable, "IP is not transferable");
        require(_from == _msgSender(), "Caller must be the primary owner to initiate transfer");
        require(_to != address(0), "New owner cannot be the zero address");
        
        _intellectusProperty.transferFrom(_from, _to, _ipId);
        
        // Update primary owner in our struct
        IPData storage ip = ipData[_ipId];
        
        // Transfer primary owner's share to the new owner.
        // If co-owners exist, their shares remain. The new owner assumes the old primary owner's share.
        uint256 oldPrimaryShare = ip.coOwners[_from];
        ip.coOwners[_from] = 0; // Clear old primary owner's share
        
        // Remove old primary owner from coOwnerList
        for (uint i = 0; i < ip.coOwnerList.length; i++) {
            if (ip.coOwnerList[i] == _from) {
                ip.coOwnerList[i] = ip.coOwnerList[ip.coOwnerList.length - 1];
                ip.coOwnerList.pop();
                break;
            }
        }

        ip.owner = _to; // Set new primary owner
        if (ip.coOwners[_to] == 0) { // If new owner wasn't already a co-owner, add them to list
            ip.coOwnerList.push(_to);
        }
        ip.coOwners[_to] += oldPrimaryShare; // Assign old primary owner's share to new primary owner

        emit IPOwnershipTransferred(_ipId, _from, _to);
    }

    /**
     * @dev 4. Allows an owner to make their IP NFT permanently non-transferable (e.g., for Soulbound IP).
     *   Once made non-transferable, it cannot be reverted.
     * @param _ipId The ID of the IP NFT.
     */
    function makeIPNonTransferable(uint256 _ipId) public onlyIPOwner(_ipId) {
        require(ipData[_ipId].isTransferable, "IP is already non-transferable");
        ipData[_ipId].isTransferable = false;
        emit IPNonTransferable(_ipId);
    }

    /**
     * @dev 5. Adds a co-owner to an IP, specifying their royalty/ownership share.
     *   Total shares of all co-owners including the primary owner must sum up to 100.00% (10000 basis points).
     * @param _ipId The ID of the IP NFT.
     * @param _coOwner The address of the new co-owner.
     * @param _sharePercentage The share of ownership in basis points (e.g., 1000 for 10%).
     */
    function addCoOwner(uint256 _ipId, address _coOwner, uint256 _sharePercentage) public onlyIPOwner(_ipId) {
        require(_coOwner != address(0), "Co-owner cannot be zero address");
        require(ipData[_ipId].coOwners[_coOwner] == 0, "Address is already a co-owner or primary owner");
        require(_sharePercentage > 0 && _sharePercentage <= 10000, "Share percentage must be between 1 and 10000");
        require(ipData[_ipId].totalCoOwnersShare + _sharePercentage <= 10000, "Total shares exceed 100%");

        ipData[_ipId].coOwners[_coOwner] = _sharePercentage;
        ipData[_ipId].totalCoOwnersShare += _sharePercentage;
        ipData[_ipId].coOwnerList.push(_coOwner); // Add to list for iteration

        emit CoOwnerAdded(_ipId, _coOwner, _sharePercentage);
    }

    /**
     * @dev 6. Removes a co-owner from an IP.
     *   The primary owner cannot be removed this way; they must transfer primary ownership.
     * @param _ipId The ID of the IP NFT.
     * @param _coOwner The address of the co-owner to remove.
     */
    function removeCoOwner(uint256 _ipId, address _coOwner) public onlyIPOwner(_ipId) {
        require(_coOwner != ipData[_ipId].owner, "Cannot remove primary owner this way");
        uint256 currentShare = ipData[_ipId].coOwners[_coOwner];
        require(currentShare > 0, "Address is not a co-owner");

        ipData[_ipId].coOwners[_coOwner] = 0;
        ipData[_ipId].totalCoOwnersShare -= currentShare;

        // Remove from coOwnerList
        for (uint i = 0; i < ipData[_ipId].coOwnerList.length; i++) {
            if (ipData[_ipId].coOwnerList[i] == _coOwner) {
                ipData[_ipId].coOwnerList[i] = ipData[_ipId].coOwnerList[ipData[_ipId].coOwnerList.length - 1];
                ipData[_ipId].coOwnerList.pop();
                break;
            }
        }

        emit CoOwnerRemoved(_ipId, _coOwner);
    }

    // --- II. LICENSING & MONETIZATION ---

    /**
     * @dev 7. IP owner proposes a license agreement.
     * @param _ipId The ID of the IP to license.
     * @param _intendedLicensee The specific licensee, or address(0) for an open offer.
     * @param _price Price in Wei for the license.
     * @param _royaltyPercentage Royalty share from derived works in basis points (e.g., 500 for 5%).
     * @param _duration Duration of the license in seconds (0 for perpetual).
     * @param _termsUri IPFS hash or URL for detailed license terms.
     */
    function createLicenseOffer(
        uint256 _ipId,
        address _intendedLicensee,
        uint256 _price,
        uint256 _royaltyPercentage,
        uint256 _duration,
        string memory _termsUri
    ) public onlyIPParticipant(_ipId) nonReentrant returns (uint256) {
        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        require(_royaltyPercentage <= 10000, "Royalty percentage exceeds 100%");
        require(bytes(_termsUri).length > 0, "Terms URI cannot be empty");

        licenseOffers[newLicenseId] = LicenseOffer({
            ipId: _ipId,
            offeredBy: _msgSender(),
            intendedLicensee: _intendedLicensee,
            price: _price,
            royaltyPercentage: _royaltyPercentage,
            duration: _duration,
            termsUri: _termsUri,
            status: LicenseStatus.Pending,
            offerTimestamp: block.timestamp
        });

        emit LicenseOfferCreated(newLicenseId, _ipId, _msgSender(), _price);
        return newLicenseId;
    }

    /**
     * @dev 8. A licensee accepts an existing license offer.
     *   Requires exact price payment.
     * @param _licenseId The ID of the license offer to accept.
     */
    function acceptLicenseOffer(uint256 _licenseId) public payable nonReentrant {
        LicenseOffer storage offer = licenseOffers[_licenseId];
        require(offer.status == LicenseStatus.Pending, "License offer not pending");
        require(offer.ipId != 0, "Invalid license offer");
        require(msg.value == offer.price, "Incorrect payment amount");
        require(offer.intendedLicensee == address(0) || offer.intendedLicensee == _msgSender(), "Not intended licensee or not open offer");

        // Funds for initial license acceptance go to the IP's royalty pool.
        ipRoyaltyPools[offer.ipId] += msg.value;

        offer.status = LicenseStatus.Active; // Mark offer as active, although the actual license is created below

        uint256 endTime = offer.duration == 0 ? 0 : block.timestamp + offer.duration;
        activeLicenses[_licenseId] = ActiveLicense({
            licenseId: _licenseId,
            ipId: offer.ipId,
            licensee: _msgSender(),
            licensor: offer.offeredBy,
            startTime: block.timestamp,
            endTime: endTime,
            royaltyPercentage: offer.royaltyPercentage,
            termsUri: offer.termsUri,
            status: LicenseStatus.Active
        });

        currentActiveLicenseId[offer.ipId] = _licenseId; // Set this as the current active license for the IP
        ipData[offer.ipId].status = IPStatus.Licensed;

        emit LicenseOfferAccepted(_licenseId, offer.ipId, _msgSender());
    }

    /**
     * @dev 9. IP owner revokes an active, unaccepted license offer.
     * @param _licenseId The ID of the license offer to revoke.
     */
    function revokeLicenseOffer(uint256 _licenseId) public onlyIPParticipant(licenseOffers[_licenseId].ipId) {
        LicenseOffer storage offer = licenseOffers[_licenseId];
        require(offer.status == LicenseStatus.Pending, "License offer not pending");
        require(offer.offeredBy == _msgSender(), "Only creator of offer can revoke");

        offer.status = LicenseStatus.Terminated; // Mark as terminated
        emit LicenseOfferRevoked(_licenseId);
    }

    /**
     * @dev 10. Either party (owner/licensee) can initiate termination of an active license.
     *   Requires external arbitration or mutual agreement for contentious terminations.
     *   For this contract, it directly terminates, assuming terms allow.
     * @param _licenseId The ID of the active license to terminate.
     */
    function terminateActiveLicense(uint256 _licenseId) public nonReentrant {
        ActiveLicense storage license = activeLicenses[_licenseId];
        require(license.status == LicenseStatus.Active, "License not active");
        require(license.licensor == _msgSender() || license.licensee == _msgSender(), "Not a party to this license");

        license.status = LicenseStatus.Terminated;
        if (currentActiveLicenseId[license.ipId] == _licenseId) {
            currentActiveLicenseId[license.ipId] = 0; // Clear active license if it was this one
            ipData[license.ipId].status = IPStatus.Registered; // IP returns to registered status
        }

        emit LicenseTerminated(_licenseId, license.ipId, _msgSender());
    }

    /**
     * @dev 11. Licensee pays the required fee for an active license.
     *   This is for recurring fees or royalty payments, funds are held in contract's IP royalty pool.
     * @param _licenseId The ID of the active license.
     */
    function payLicenseFee(uint256 _licenseId) public payable nonReentrant {
        ActiveLicense storage license = activeLicenses[_licenseId];
        require(license.status == LicenseStatus.Active, "License not active");
        require(license.licensee == _msgSender(), "Only licensee can pay fees");
        require(msg.value > 0, "Payment amount must be greater than zero");

        ipRoyaltyPools[license.ipId] += msg.value; // Funds are held in contract for later distribution
        emit LicenseFeePaid(_licenseId, license.ipId, _msgSender(), msg.value);
    }

    /**
     * @dev 12. Callable by anyone to distribute collected royalties to IP owners/co-owners based on their defined split.
     *   Requires `totalCoOwnersShare` to sum to 10000 (100%).
     *   Funds are distributed from `ipRoyaltyPools[_ipId]`.
     * @param _ipId The ID of the IP for which to distribute royalties.
     */
    function distributeRoyalties(uint256 _ipId) public nonReentrant {
        IPData storage ip = ipData[_ipId];
        uint256 amountToDistribute = ipRoyaltyPools[_ipId];
        require(amountToDistribute > 0, "No royalties collected for this IP.");
        require(ip.totalCoOwnersShare == 10000, "IP co-owner shares are not fully allocated (sum to 100.00%)");

        uint256 distributedAmount = 0;
        for (uint i = 0; i < ip.coOwnerList.length; i++) {
            address currentOwner = ip.coOwnerList[i];
            uint256 share = ip.coOwners[currentOwner];
            if (share > 0) {
                uint256 amount = (amountToDistribute * share) / 10000;
                (bool sent, ) = currentOwner.call{value: amount}("");
                require(sent, "Failed to send royalty to owner");
                distributedAmount += amount;
            }
        }
        ipRoyaltyPools[_ipId] -= distributedAmount; // Deduct distributed amount from the pool

        emit RoyaltyDistributed(_ipId, distributedAmount, _msgSender());
    }

    /**
     * @dev 13. IP owner defines the royalty split for any works derived from their IP, to incentivize future creators.
     *   This is a protocol-level incentive, where derived works would conceptually (or via oracle)
     *   send a percentage of *their own earnings* back to the original IP's royalty pool.
     *   The percentage (basis points, e.g., 500 for 5%) is stored as metadata.
     * @param _ipId The ID of the IP.
     * @param _percentage The percentage (basis points) to be paid to original IP from derived work's revenue.
     */
    function setDerivedWorkRoyaltySplit(uint256 _ipId, uint256 _percentage) public onlyIPOwner(_ipId) {
        require(_percentage <= 10000, "Percentage exceeds 100%");
        // Using a special entry in coOwners mapping for derived royalty percentage.
        // In a more robust system, this would be a dedicated field in IPData struct.
        ipData[_ipId].coOwners[address(1)] = _percentage; // address(1) as a sentinel for derived royalty percentage

        emit DerivedWorkRoyaltySplitSet(_ipId, _msgSender(), _percentage);
    }

    // --- III. KNOWLEDGE CURATION & REPUTATION (SBT-like `IntellectusProfile` ERC721) ---

    /**
     * @dev 14. Mints a non-transferable profile NFT for a new user, establishing their on-chain identity.
     *   This profile acts as a Soulbound Token (SBT), enhancing reputation and access to features.
     */
    function mintIntellectusProfile() public nonReentrant returns (uint256) {
        require(addressToProfileId[_msgSender()] == 0, "Already has an IntellectusProfile");

        _profileIdCounter.increment();
        uint256 newProfileId = _profileIdCounter.current();

        _intellectusProfile.safeMint(_msgSender(), newProfileId); // Mints the NFT to the caller

        addressToProfileId[_msgSender()] = newProfileId;
        intellectusProfileOwner[newProfileId] = _msgSender();
        hasProfile[_msgSender()] = true;

        emit ProfileMinted(newProfileId, _msgSender());
        return newProfileId;
    }

    /**
     * @dev 15. Users (with `IntellectusProfile`) can submit verified knowledge/research related to an IP or a general concept.
     * @param _ipId The ID of the related IP (0 if general knowledge).
     * @param _title The title of the knowledge node.
     * @param _contentUri IPFS hash or URL for the knowledge content.
     */
    function submitKnowledgeNode(
        uint256 _ipId,
        string memory _title,
        string memory _contentUri
    ) public onlyWithProfile nonReentrant returns (uint256) {
        require(bytes(_title).length > 0 && bytes(_contentUri).length > 0, "Title and content URI cannot be empty");

        _knowledgeNodeIdCounter.increment();
        uint256 newNodeId = _knowledgeNodeIdCounter.current();

        knowledgeNodes[newNodeId] = KnowledgeNode({
            ipId: _ipId,
            submitter: _msgSender(),
            title: _title,
            contentUri: _contentUri,
            status: KnowledgeNodeStatus.PendingValidation,
            submissionTime: block.timestamp,
            upvotes: 0,
            downvotes: 0
        });

        emit KnowledgeNodeSubmitted(newNodeId, _ipId, _msgSender(), _title);
        return newNodeId;
    }

    /**
     * @dev 16. Stake tokens (ETH) to gain rights to vote on `KnowledgeNodes` and earn rewards.
     * @param _amount The amount of ETH to stake.
     */
    function stakeForCuration(uint256 _amount) public payable onlyWithProfile nonReentrant {
        require(_amount >= MIN_CURATION_STAKE, "Must stake at least MIN_CURATION_STAKE");
        require(msg.value == _amount, "Sent amount does not match specified amount");

        curatorStakes[_msgSender()] += _amount;
        // The staked funds are held by the contract.
    }

    /**
     * @dev 17. Curators vote on the veracity, quality, and relevance of submitted knowledge.
     *   Requires minimum stake. Only one vote per node per curator.
     * @param _nodeId The ID of the knowledge node.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function voteOnKnowledgeNode(uint256 _nodeId, bool _isUpvote) public onlyCurator nonReentrant {
        KnowledgeNode storage node = knowledgeNodes[_nodeId];
        require(node.status == KnowledgeNodeStatus.PendingValidation, "Knowledge node not in pending validation status");
        require(block.timestamp <= node.submissionTime + KNOWLEDGE_NODE_VOTE_PERIOD, "Voting period has ended");
        require(!node.voted[_msgSender()], "Already voted on this knowledge node");

        node.voted[_msgSender()] = true;
        if (_isUpvote) {
            node.upvotes++;
        } else {
            node.downvotes++;
        }

        emit KnowledgeNodeVoted(_nodeId, _msgSender(), _isUpvote);

        // Simple validation logic: if upvotes are significantly higher, validate.
        // Or if voting period ends, a separate function could finalize.
        if (node.upvotes > node.downvotes * 2 && node.upvotes >= 3) { // At least 3 upvotes to avoid spam validation
            node.status = KnowledgeNodeStatus.Validated;
            emit KnowledgeNodeValidated(_nodeId);
        } else if (node.downvotes > node.upvotes * 2 && node.downvotes >= 3) {
            node.status = KnowledgeNodeStatus.Rejected;
            emit KnowledgeNodeRejected(_nodeId);
        }
    }

    /**
     * @dev 18. Successful curators claim rewards based on their accurate votes and staked amount.
     *   (Reward pool logic omitted for brevity, would involve a token distribution mechanism).
     *   This function serves as a placeholder for claiming, and in a real system, a separate
     *   reward mechanism (e.g., from a protocol treasury or fees) would calculate and distribute.
     * @param _profileId The ID of the curator's profile.
     */
    function claimCurationReward(uint256 _profileId) public onlyProfileOwner(_profileId) nonReentrant {
        // This is a placeholder for a more complex reward calculation, possibly from a fees pool.
        // For demonstration, a small, fixed reward is given.
        uint256 rewardAmount = 0.01 ether; // Example static reward

        (bool sent, ) = _msgSender().call{value: rewardAmount}("");
        require(sent, "Failed to send curation reward");

        emit CurationRewardClaimed(_msgSender(), rewardAmount);
    }

    /**
     * @dev 19. IP owners or protocol can grant specific achievements/badges to `IntellectusProfiles`.
     *   This enhances the reputation of the profile holder.
     * @param _profileId The ID of the IntellectusProfile to grant the achievement to.
     * @param _achievement A string representing the achievement (e.g., "Verified Contributor", "Impactful Creator").
     */
    function addAchievementToProfile(uint256 _profileId, string memory _achievement) public {
        require(_profileId != 0, "Invalid profile ID");
        require(msg.sender == owner(), "Only contract owner can add achievement"); // Simplified, could be specific roles
        
        profileAchievements[_profileId].push(_achievement);
        emit AchievementAdded(_profileId, _achievement);
    }

    // --- IV. FUNDING & COLLABORATION ---

    /**
     * @dev 20. A user (with `IntellectusProfile`) proposes a research or development project related to specific IP(s).
     * @param _ipId The ID of the related IP (0 if general project).
     * @param _title The title of the grant proposal.
     * @param _descriptionUri IPFS hash or URL for detailed proposal.
     * @param _targetAmount The target funding amount in Wei.
     */
    function createResearchGrantProposal(
        uint256 _ipId,
        string memory _title,
        string memory _descriptionUri,
        uint256 _targetAmount
    ) public onlyWithProfile nonReentrant returns (uint256) {
        _grantProposalIdCounter.increment();
        uint256 newProposalId = _grantProposalIdCounter.current();

        grantProposals[newProposalId] = GrantProposal({
            proposalId: newProposalId,
            proposer: _msgSender(),
            targetAmount: _targetAmount,
            title: _title,
            descriptionUri: _descriptionUri,
            ipId: _ipId,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + GRANT_VOTING_PERIOD,
            fundingEndTime: 0, // Set after voting
            totalContributions: 0,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            funded: false,
            contributors: new address[](0),
            contributions: new mapping(address => uint256)(),
            fundsClaimed: new mapping(address => bool)()
        });

        emit GrantProposalCreated(newProposalId, _msgSender(), _targetAmount);
        return newProposalId;
    }

    /**
     * @dev 21. `IntellectusProfile` holders can vote on grant proposals.
     *   One vote per profile.
     * @param _proposalId The ID of the grant proposal.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function voteOnGrantProposal(uint256 _proposalId, bool _isUpvote) public onlyWithProfile nonReentrant {
        GrantProposal storage proposal = grantProposals[_proposalId];
        require(proposal.proposalId != 0, "Invalid proposal ID");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.voted[_msgSender()], "Already voted on this proposal");

        proposal.voted[_msgSender()] = true;
        if (_isUpvote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }

        emit GrantProposalVoted(_proposalId, _msgSender(), _isUpvote);

        // Simple approval logic: if voting period ends and more upvotes than downvotes
        if (block.timestamp >= proposal.votingEndTime && !proposal.approved) {
            if (proposal.upvotes > proposal.downvotes) {
                proposal.approved = true;
                proposal.fundingEndTime = block.timestamp + GRANT_CONTRIBUTION_PERIOD;
                emit GrantProposalApproved(_proposalId);
            }
        }
    }

    /**
     * @dev 22. Anyone can contribute funds to an approved grant proposal.
     * @param _proposalId The ID of the grant proposal.
     */
    function contributeToGrant(uint256 _proposalId) public payable nonReentrant {
        GrantProposal storage proposal = grantProposals[_proposalId];
        require(proposal.proposalId != 0, "Invalid proposal ID");
        require(proposal.approved, "Proposal not approved for funding");
        require(block.timestamp <= proposal.fundingEndTime, "Funding period has ended");
        require(msg.value > 0, "Contribution must be greater than zero");

        proposal.totalContributions += msg.value;
        if (proposal.contributions[_msgSender()] == 0) {
            proposal.contributors.push(_msgSender()); // Add to list of unique contributors
        }
        proposal.contributions[_msgSender()] += msg.value;

        if (proposal.totalContributions >= proposal.targetAmount && !proposal.funded) {
            proposal.funded = true;
        }

        emit GrantContributed(_proposalId, _msgSender(), msg.value);
    }

    /**
     * @dev 23. Project leader claims vested funds from a successful grant.
     *   For simplicity, funds are immediately claimable upon reaching target.
     *   A real vesting schedule would be more complex and could involve multiple claim tranches.
     * @param _proposalId The ID of the grant proposal.
     */
    function claimGrantFunds(uint256 _proposalId) public nonReentrant {
        GrantProposal storage proposal = grantProposals[_proposalId];
        require(proposal.proposalId != 0, "Invalid proposal ID");
        require(proposal.proposer == _msgSender(), "Only proposer can claim funds");
        require(proposal.funded, "Grant not fully funded yet");
        // Simplified: allow claiming once all at once.
        require(!proposal.fundsClaimed[_msgSender()], "Grant funds already claimed by proposer");

        uint256 amountToClaim = proposal.totalContributions;
        require(amountToClaim > 0, "No funds available to claim");

        proposal.fundsClaimed[_msgSender()] = true; // Mark as claimed
        proposal.totalContributions = 0; // Clear the balance for the proposal

        (bool sent, ) = _msgSender().call{value: amountToClaim}("");
        require(sent, "Failed to send grant funds");

        emit GrantFundsClaimed(_proposalId, _msgSender(), amountToClaim);
    }

    // --- V. ADVANCED / CREATIVE FEATURES ---

    /**
     * @dev 24. Users can formally initiate a dispute regarding IP ownership, license terms, or knowledge node validity.
     *   Requires a small fee to prevent spam.
     * @param _ipId The ID of the IP involved in the dispute.
     * @param _defendant The address of the party being disputed against.
     * @param _reasonUri IPFS hash or URL for detailed dispute reasons.
     */
    function initiateIPDispute(uint256 _ipId, address _defendant, string memory _reasonUri) public payable onlyWithProfile nonReentrant returns (uint256) {
        require(_ipId != 0, "Invalid IP ID");
        require(_defendant != address(0), "Defendant cannot be zero address");
        require(_defendant != _msgSender(), "Cannot dispute yourself");
        require(msg.value >= MIN_DISPUTE_FEE, "Minimum dispute fee required");

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        ipDisputes[newDisputeId] = IPDispute({
            disputeId: newDisputeId,
            ipId: _ipId,
            initiator: _msgSender(),
            defendant: _defendant,
            reasonUri: _reasonUri,
            status: DisputeStatus.Pending,
            arbitrators: new address[](0),
            resolvedTimestamp: 0,
            resolutionUri: ""
        });

        // Funds are held by the contract for potential arbitration costs/penalties.

        emit IPDisputeInitiated(newDisputeId, _ipId, _msgSender());
        return newDisputeId;
    }

    /**
     * @dev Sets an address as an arbitrator. Only callable by the contract owner.
     * @param _arbitrator The address to set as an arbitrator.
     * @param _status True to add, false to remove.
     */
    function setArbitrator(address _arbitrator, bool _status) public onlyOwner {
        require(_arbitrator != address(0), "Arbitrator address cannot be zero");
        isArbitrator[_arbitrator] = _status;
        emit ArbitratorSet(_arbitrator, _status);
    }

    /**
     * @dev 25. Designated arbitrators or DAO can resolve disputes, potentially triggering state changes.
     *   For this example, a single registered arbitrator can resolve. In a full DAO, this would involve voting.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolutionStatus The final status (e.g., Resolved).
     * @param _resolutionUri IPFS hash or URL for detailed resolution.
     */
    function resolveDispute(uint256 _disputeId, DisputeStatus _resolutionStatus, string memory _resolutionUri) public onlyArbitrator nonReentrant {
        IPDispute storage dispute = ipDisputes[_disputeId];
        require(dispute.disputeId != 0, "Invalid dispute ID");
        require(dispute.status == DisputeStatus.Pending, "Dispute not in pending state");
        require(_resolutionStatus == DisputeStatus.Resolved || _resolutionStatus == DisputeStatus.Canceled, "Invalid resolution status");

        dispute.arbitrators.push(_msgSender()); // Record arbitrator who resolved
        dispute.status = _resolutionStatus;
        dispute.resolvedTimestamp = block.timestamp;
        dispute.resolutionUri = _resolutionUri;

        // Implement logic here based on resolution status, e.g., if IP ownership dispute:
        // if (_resolutionStatus == DisputeStatus.Resolved && /* based on arbitrator vote for initiator */) {
        //   _intellectusProperty.transferFrom(dispute.defendant, dispute.initiator, dispute.ipId);
        //   ipData[dispute.ipId].owner = dispute.initiator;
        // }

        // The dispute fee collected during initiation can also be distributed or returned here.
        // Simplified: no fee distribution logic shown here.

        emit IPDisputeResolved(_disputeId, dispute.ipId, _resolutionStatus);
    }

    /**
     * @dev 26. Allows temporary, collateralized access to an IP's underlying data for analysis, AI training, or simulation.
     *   The collateral is locked and released upon expiry or breach of terms (which would need off-chain verification or oracle).
     * @param _ipId The ID of the IP to access.
     * @param _collateralAmount The amount of ETH to lock as collateral.
     * @param _accessDuration Duration of access in seconds.
     * @param _termsUri IPFS hash or URL for specific access terms (e.g., no redistribution).
     */
    function requestCollateralizedIPAccess(
        uint256 _ipId,
        uint256 _collateralAmount,
        uint256 _accessDuration,
        string memory _termsUri
    ) public payable nonReentrant {
        require(_ipId != 0, "Invalid IP ID");
        require(msg.value == _collateralAmount, "Collateral amount mismatch");
        require(_collateralAmount > 0, "Collateral must be greater than zero");
        require(_accessDuration > 0, "Access duration must be greater than zero");
        require(bytes(_termsUri).length > 0, "Terms URI cannot be empty");

        // Funds are held by the contract as collateral.
        // Off-chain mechanisms/oracles would then grant access to the IP data and monitor terms.
        // On-chain, this records the agreement.
        collateralizedAccess[_ipId][_msgSender()] = CollateralizedAccessData({
            amount: _collateralAmount,
            expiry: block.timestamp + _accessDuration,
            active: true
        });

        emit CollateralizedIPAccessRequested(_ipId, _msgSender(), _collateralAmount, block.timestamp + _accessDuration);
    }
    
    /**
     * @dev Releases collateral after successful collateralized access or if dispute resolution allows.
     *   This would typically be triggered by an oracle confirming terms were met or after expiry.
     *   For simplicity, allows accessor to claim after expiry.
     * @param _ipId The ID of the IP.
     * @param _accessor The address that requested access.
     */
    function releaseCollateral(uint256 _ipId, address _accessor) public nonReentrant {
        CollateralizedAccessData storage access = collateralizedAccess[_ipId][_accessor];
        require(access.active, "No active collateralized access for this accessor");
        require(block.timestamp >= access.expiry, "Access period not yet expired"); // Or oracle confirms terms met

        uint256 amountToRelease = access.amount;
        access.amount = 0;
        access.active = false; // Deactivate

        (bool sent, ) = _accessor.call{value: amountToRelease}("");
        require(sent, "Failed to release collateral");

        emit CollateralReleased(_ipId, _accessor, amountToRelease);
    }

    /**
     * @dev 27. IP owner explicitly signals consent for their IP to be used for AI model training
     *   under specific, machine-readable terms (e.g., royalty, attribution, data subset).
     * @param _ipId The ID of the IP.
     * @param _consent True to grant consent, false to revoke.
     * @param _aiUsageTermsUri URI to specific AI usage terms if different from default protocol terms.
     */
    function signalAIUsageConsent(uint256 _ipId, bool _consent, string memory _aiUsageTermsUri) public onlyIPOwner(_ipId) {
        ipData[_ipId].aiUsageConsent = _consent;
        if (_consent && bytes(_aiUsageTermsUri).length > 0) {
            ipData[_ipId].aiUsageTermsUri = _aiUsageTermsUri;
        } else {
            ipData[_ipId].aiUsageTermsUri = ""; // Clear if no consent or default terms
        }
        emit AIUsageConsentSignaled(_ipId, _msgSender(), _consent);
    }

    /**
     * @dev 28. IP owner irrevocably releases their IP into the public domain.
     *   This makes the IP non-transferable and explicitly marks it for free use.
     * @param _ipId The ID of the IP to release.
     */
    function releaseIPToPublicDomain(uint256 _ipId) public onlyIPOwner(_ipId) {
        ipData[_ipId].status = IPStatus.PublicDomain;
        ipData[_ipId].isTransferable = false; // Public domain IP cannot be privately transferred.
        emit IPReleasedToPublicDomain(_ipId);
    }

    // --- VI. VIEW FUNCTIONS (GETTERS) ---

    function getIPDetails(uint256 _ipId) public view returns (
        string memory name,
        string memory uri,
        address primaryOwner,
        bool isTransferable,
        IPStatus status,
        address creator,
        uint256 registrationTimestamp,
        bool aiUsageConsent,
        string memory aiUsageTermsUri
    ) {
        IPData storage ip = ipData[_ipId];
        return (
            ip.name,
            ip.uri,
            ip.owner,
            ip.isTransferable,
            ip.status,
            ip.creator,
            ip.registrationTimestamp,
            ip.aiUsageConsent,
            ip.aiUsageTermsUri
        );
    }

    function getIPCoOwners(uint256 _ipId) public view returns (address[] memory coOwnerAddresses, uint256[] memory shares) {
        IPData storage ip = ipData[_ipId];
        coOwnerAddresses = new address[](ip.coOwnerList.length);
        shares = new uint256[](ip.coOwnerList.length);

        for (uint i = 0; i < ip.coOwnerList.length; i++) {
            coOwnerAddresses[i] = ip.coOwnerList[i];
            shares[i] = ip.coOwners[ip.coOwnerList[i]];
        }
        return (coOwnerAddresses, shares);
    }

    function getLicenseOfferDetails(uint256 _licenseId) public view returns (
        uint256 ipId,
        address offeredBy,
        address intendedLicensee,
        uint256 price,
        uint256 royaltyPercentage,
        uint256 duration,
        string memory termsUri,
        LicenseStatus status,
        uint256 offerTimestamp
    ) {
        LicenseOffer storage offer = licenseOffers[_licenseId];
        return (
            offer.ipId,
            offer.offeredBy,
            offer.intendedLicensee,
            offer.price,
            offer.royaltyPercentage,
            offer.duration,
            offer.termsUri,
            offer.status,
            offer.offerTimestamp
        );
    }

    function getActiveLicenseDetails(uint256 _licenseId) public view returns (
        uint256 ipId,
        address licensee,
        address licensor,
        uint256 startTime,
        uint256 endTime,
        uint256 royaltyPercentage,
        string memory termsUri,
        LicenseStatus status
    ) {
        ActiveLicense storage license = activeLicenses[_licenseId];
        return (
            license.ipId,
            license.licensee,
            license.licensor,
            license.startTime,
            license.endTime,
            license.royaltyPercentage,
            license.termsUri,
            license.status
        );
    }

    function getKnowledgeNodeDetails(uint256 _nodeId) public view returns (
        uint256 ipId,
        address submitter,
        string memory title,
        string memory contentUri,
        KnowledgeNodeStatus status,
        uint256 submissionTime,
        uint256 upvotes,
        uint256 downvotes
    ) {
        KnowledgeNode storage node = knowledgeNodes[_nodeId];
        return (
            node.ipId,
            node.submitter,
            node.title,
            node.contentUri,
            node.status,
            node.submissionTime,
            node.upvotes,
            node.downvotes
        );
    }

    function getGrantProposalDetails(uint256 _proposalId) public view returns (
        address proposer,
        uint256 targetAmount,
        string memory title,
        string memory descriptionUri,
        uint256 ipId,
        uint256 submissionTime,
        uint256 votingEndTime,
        uint256 fundingEndTime,
        uint256 totalContributions,
        uint256 upvotes,
        uint256 downvotes,
        bool approved,
        bool funded
    ) {
        GrantProposal storage proposal = grantProposals[_proposalId];
        return (
            proposal.proposer,
            proposal.targetAmount,
            proposal.title,
            proposal.descriptionUri,
            proposal.ipId,
            proposal.submissionTime,
            proposal.votingEndTime,
            proposal.fundingEndTime,
            proposal.totalContributions,
            proposal.upvotes,
            proposal.downvotes,
            proposal.approved,
            proposal.funded
        );
    }

    function getIPDisputeDetails(uint256 _disputeId) public view returns (
        uint256 ipId,
        address initiator,
        address defendant,
        string memory reasonUri,
        DisputeStatus status,
        address[] memory arbitratorsList,
        uint256 resolvedTimestamp,
        string memory resolutionUri
    ) {
        IPDispute storage dispute = ipDisputes[_disputeId];
        return (
            dispute.ipId,
            dispute.initiator,
            dispute.defendant,
            dispute.reasonUri,
            dispute.status,
            dispute.arbitrators, // Returns the list of arbitrators who acted on this specific dispute
            dispute.resolvedTimestamp,
            dispute.resolutionUri
        );
    }

    function getProfileAchievements(uint256 _profileId) public view returns (string[] memory) {
        return profileAchievements[_profileId];
    }
}
```