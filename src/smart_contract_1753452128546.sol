Here's a Solidity smart contract named `GenesisForge` that attempts to incorporate a variety of interesting, advanced, creative, and trendy concepts, while striving for uniqueness in its combination and implementation. It focuses on decentralized intellectual property (IP) management, dynamic monetization, simulated AI integration, a reputation system, and simplified DAO governance.

---

**Outline and Function Summary**

**Contract Name:** GenesisForge
**Purpose:** A decentralized platform for creating, owning, licensing, and monetizing unique digital intellectual property (IP) as NFTs. It integrates advanced concepts such as dynamic royalties, simulated AI analysis for originality, a reputation system for content curation, basic DAO governance for platform parameters, and considers carbon offsetting, aiming to be a novel and comprehensive solution for digital content creators.

**Core Modules & Functions:**

**I. IP NFT Management (ERC721 Compliant):**
  - `mintGenesisNFT(string memory _contentHash, string memory _tokenURI, LicenseModel _model, uint256 _price, uint256 _duration)`:
    Creates a new IP-NFT, linking it to a unique content hash (e.g., IPFS CID), initial metadata URI, and defines its initial licensing terms. A small fee is collected for platform operations and carbon offsetting.
  - `updateContentHash(uint256 _tokenId, string memory _newContentHash)`:
    Allows the IP-NFT owner to update the content hash of their NFT, crucial for representing revisions or new versions while maintaining the same NFT identity.
  - `setTokenURI(uint256 _tokenId, string memory _newTokenURI)`:
    Standard ERC721 function to update the metadata URI of an IP-NFT, allowing for updates to external metadata (e.g., hosted on IPFS).
  - `transferFrom(address from, address to, uint256 tokenId)` / `safeTransferFrom(...)`:
    Standard ERC721 functions inherited for transferring IP-NFT ownership between addresses.

**II. Dynamic Licensing & Monetization:**
  - `setLicenseModel(uint256 _tokenId, LicenseModel _model, uint256 _price, uint256 _duration)`:
    Defines or updates the licensing terms (e.g., fixed fee, pay-per-use, subscription, free) and initial price/duration for an existing IP-NFT.
  - `adjustLicensePrice(uint256 _tokenId, uint256 _newPrice)`:
    Allows IP-NFT owners to propose a new license price for their content. In this simplified DAO, it's a direct update but could be subject to further governance approval.
  - `purchaseLicense(uint256 _tokenId)`:
    Enables users to acquire a license for a specific IP-NFT based on its defined model and price. Collected fees are distributed to the owner, platform, and carbon offset fund.
  - `collectRoyalties(uint256 _tokenId)`:
    Allows the IP-NFT owner to withdraw their accumulated license fees (royalties) for their content from the contract.
  - `setUsageTierDiscount(uint256 _tokenId, uint256 _tierThreshold, uint256 _discountPercentage)`:
    Configures tiered discounts for licenses, where pricing changes based on cumulative usage or other predefined metrics. (Conceptual, requires extended logic for actual discount application).
  - `enableSubscription(uint256 _tokenId, uint256 _subscriptionPrice, uint256 _renewalPeriod)`:
    Activates a recurring subscription model for an IP-NFT, allowing for continuous access upon renewal.
  - `renewSubscription(uint256 _tokenId)`:
    Allows an existing subscriber to renew their active license, extending their access period for the IP.

**III. Proof of Originality & AI Integration (Simulated/Oracle-based):**
  - `submitOriginalityClaim(uint256 _tokenId, string memory _claimDetails)`:
    Users formally submit a content hash and declare originality for their IP-NFT, timestamping their claim on-chain.
  - `requestAIAnalysis(uint256 _tokenId)`:
    Triggers a simulated off-chain AI analysis request (e.g., for plagiarism detection, quality assessment, style analysis) for submitted IP content. This emits an event for an off-chain oracle.
  - `setAIAnalysisResult(uint256 _tokenId, AIAnalysisStatus _status, string memory _details)`:
    An authorized oracle (contract owner in this example) sets the result of an off-chain AI analysis for a given IP-NFT.
  - `attestOriginalityProof(uint256 _tokenId, address _attester)`:
    Allows a designated curator or oracle to formally attest to the originality of a content hash associated with an IP-NFT, adding a layer of trusted verification.
  - `setCrossChainAttestation(uint256 _tokenId, bytes32 _attestationId, string memory _chainDetails)`:
    Records a placeholder for a simulated cross-chain attestation of the IP's existence or originality on another blockchain, mimicking interoperability.

**IV. Decentralized Governance (Simplified DAO):**
  - `proposeGovernanceAction(ProposalType _type, uint256 _tokenId, uint256 _newValue, string memory _description)`:
    Allows stake-holders (IP-NFT owners or users with reputation) to propose changes to contract parameters, platform fees, or initiate dispute resolutions.
  - `castVote(uint256 _proposalId, bool _support)`:
    Users with voting power (derived from owned NFTs and reputation) can cast their vote on active proposals.
  - `executeProposal(uint256 _proposalId)`:
    Executes a proposal that has met its voting quorum and majority threshold after the voting period ends, enacting the proposed changes (e.g., fee adjustment, dispute resolution).
  - `delegateVote(address _delegatee)`:
    Allows users to signal their intent to delegate their voting power to another address, enabling proxy voting in a more complex setup. (Functionality is illustrative).

**V. Reputation & Gamification:**
  - `submitCuratorialReview(uint256 _tokenId, uint8 _score, string memory _reviewText)`:
    Users can submit a review for an IP-NFT, providing feedback and potentially influencing the IP's visibility and the reviewer's own reputation score.
  - `updateReputationScore(address _user, int256 _change)`:
    An internal/external function (callable by owner/governance) to adjust a user's reputation score based on their activities (e.g., quality reviews, successful proposals, active participation).
  - `claimReputationReward(address _recipient)`:
    Allows users to claim conceptual rewards (e.g., native tokens, discounts, special access) based on their achieved reputation tier, encouraging positive contributions.

**VI. Advanced & Trending Concepts:**
  - `setCarbonOffsetFactor(uint256 _factorBasisPoints)`:
    Sets a percentage (in basis points) of transaction fees or minting fees that are automatically allocated for simulated carbon offsetting initiatives, supporting environmental consciousness.
  - `withdrawCarbonOffsetFunds(address _recipient, uint256 _amount)`:
    Allows a designated address (e.g., a DAO treasury or partner organization) to withdraw accumulated carbon offset funds for off-chain environmental initiatives.
  - `initiateDisputeResolution(uint256 _tokenId, string memory _reason)`:
    Starts a formal dispute process regarding an IP-NFT (e.g., originality claims, licensing violations, ownership disputes), providing an on-chain record.
  - `resolveDispute(uint256 _disputeId, DisputeResult _result)`:
    An authorized entity (e.g., through a successful DAO vote, or a designated arbiter) resolves an active dispute, marking its outcome and potentially triggering further actions.
  - `updatePlatformFee(uint256 _newFeeBasisPoints)`:
    Allows governance (or the contract owner initially) to adjust the platform's service fee collected on various transactions.
  - `pauseContractOperations()`:
    Emergency function allowing the owner/governance to pause critical contract operations (e.g., minting, purchasing) in case of vulnerabilities or upgrades, providing a safety mechanism.
  - `unpauseContractOperations()`:
    Resumes contract operations after they have been paused, returning the system to full functionality.

**View Functions (Data Retrieval):**
  - `getIPDetails(uint256 _tokenId)`: Returns all stored details for a given IP-NFT.
  - `getLicenseDetails(uint256 _tokenId)`: Returns the current licensing configuration for an IP-NFT.
  - `getSubscriptionStatus(uint256 _tokenId, address _subscriber)`: Checks and returns the active status and duration of a user's subscription to an IP.
  - `getReputationScore(address _user)`: Retrieves a user's current reputation score.
  - `getProposalDetails(uint256 _proposalId)`: Returns the full details of a specific governance proposal.
  - `getDisputeDetails(uint256 _disputeId)`: Returns the full details of a specific dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary
/*
Contract Name: GenesisForge
Purpose: A decentralized platform for creating, owning, licensing, and monetizing unique digital intellectual property (IP) as NFTs. It integrates advanced concepts such as dynamic royalties, simulated AI analysis for originality, a reputation system for content curation, basic DAO governance for platform parameters, and considers carbon offsetting, aiming to be a novel and comprehensive solution for digital content creators.

Core Modules & Functions:

I. IP NFT Management (ERC721 Compliant):
  - `mintGenesisNFT(string memory _contentHash, string memory _tokenURI, LicenseModel _model, uint256 _price, uint256 _duration)`:
    Creates a new IP-NFT, linking it to a unique content hash, initial metadata URI, and defines its initial licensing terms.
  - `updateContentHash(uint256 _tokenId, string memory _newContentHash)`:
    Allows the owner to update the content hash of their IP-NFT, crucial for revisions or new versions.
  - `setTokenURI(uint256 _tokenId, string memory _newTokenURI)`:
    Standard ERC721 function to update the metadata URI of an IP-NFT.
  - `transferFrom(address from, address to, uint256 tokenId)` / `safeTransferFrom(...)`:
    Standard ERC721 functions inherited for transferring IP-NFT ownership.

II. Dynamic Licensing & Monetization:
  - `setLicenseModel(uint256 _tokenId, LicenseModel _model, uint256 _price, uint256 _duration)`:
    Defines or updates the licensing terms (model, price, duration) for an existing IP-NFT.
  - `adjustLicensePrice(uint256 _tokenId, uint256 _newPrice)`:
    Allows IP-NFT owners to propose a new license price for their content.
  - `purchaseLicense(uint256 _tokenId)`:
    Enables users to acquire a license for a specific IP-NFT based on its defined model and price. Fees are collected.
  - `collectRoyalties(uint256 _tokenId)`:
    Allows the IP-NFT owner to withdraw accrued license fees (royalties).
  - `setUsageTierDiscount(uint256 _tokenId, uint256 _tierThreshold, uint256 _discountPercentage)`:
    Configures tiered discounts for licenses based on cumulative usage or other metrics. (Conceptual, not fully implemented logic)
  - `enableSubscription(uint256 _tokenId, uint256 _subscriptionPrice, uint256 _renewalPeriod)`:
    Activates a recurring subscription model for an IP-NFT.
  - `renewSubscription(uint256 _tokenId)`:
    Allows an existing subscriber to renew their active license, extending access.

III. Proof of Originality & AI Integration (Simulated/Oracle-based):
  - `submitOriginalityClaim(uint256 _tokenId, string memory _claimDetails)`:
    Users submit a content hash and declare originality, timestamping their claim.
  - `requestAIAnalysis(uint256 _tokenId)`:
    Triggers a simulated off-chain AI analysis request for submitted IP content.
  - `setAIAnalysisResult(uint256 _tokenId, AIAnalysisStatus _status, string memory _details)`:
    An authorized oracle or curator sets the result of an off-chain AI analysis for an IP-NFT.
  - `attestOriginalityProof(uint256 _tokenId, address _attester)`:
    Allows a designated curator or oracle to formally attest to the originality of a content hash.
  - `setCrossChainAttestation(uint256 _tokenId, bytes32 _attestationId, string memory _chainDetails)`:
    Records a placeholder for a simulated cross-chain attestation of the IP's existence or originality on another chain.

IV. Decentralized Governance (Simplified DAO):
  - `proposeGovernanceAction(ProposalType _type, uint256 _tokenId, uint256 _newValue, string memory _description)`:
    Allows stake-holders to propose changes to contract parameters, platform fees, or initiate dispute resolutions.
  - `castVote(uint256 _proposalId, bool _support)`:
    Users with voting power can cast their vote on active proposals.
  - `executeProposal(uint256 _proposalId)`:
    Executes a proposal that has met its voting quorum and threshold.
  - `delegateVote(address _delegatee)`:
    Allows users to delegate their voting power to another address. (Illustrative)

V. Reputation & Gamification:
  - `submitCuratorialReview(uint256 _tokenId, uint8 _score, string memory _reviewText)`:
    Users can submit a review for an IP-NFT, potentially influencing its reputation score and the reviewer's own score.
  - `updateReputationScore(address _user, int256 _change)`:
    Internal/External function to adjust a user's reputation score based on activity.
  - `claimReputationReward(address _recipient)`:
    Allows users to claim rewards based on their reputation tier.

VI. Advanced & Trending Concepts:
  - `setCarbonOffsetFactor(uint256 _factorBasisPoints)`:
    Sets a percentage of transaction fees or minting fees that are allocated for simulated carbon offsetting.
  - `withdrawCarbonOffsetFunds(address _recipient, uint256 _amount)`:
    Allows a designated address to withdraw accumulated carbon offset funds for off-chain initiatives.
  - `initiateDisputeResolution(uint256 _tokenId, string memory _reason)`:
    Starts a formal dispute process regarding an IP-NFT.
  - `resolveDispute(uint256 _disputeId, DisputeResult _result)`:
    An authorized entity or successful DAO vote resolves an active dispute.
  - `updatePlatformFee(uint256 _newFeeBasisPoints)`:
    Allows governance to adjust the platform's service fee on transactions.
  - `pauseContractOperations()`:
    Emergency function to pause critical contract operations.
  - `unpauseContractOperations()`:
    Resumes contract operations after a pause.

View Functions:
  - `getIPDetails(uint256 _tokenId)`
  - `getLicenseDetails(uint256 _tokenId)`
  - `getSubscriptionStatus(uint256 _tokenId, address _subscriber)`
  - `getReputationScore(address _user)`
  - `getProposalDetails(uint256 _proposalId)`
  - `getDisputeDetails(uint256 _disputeId)`
*/

contract GenesisForge is ERC721Enumerable, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _disputeIdCounter;

    // Platform fees and carbon offsetting
    uint256 public platformFeeBasisPoints; // e.g., 500 for 5%
    uint256 public carbonOffsetFactorBasisPoints; // e.g., 100 for 1%

    // --- Enums ---
    enum LicenseModel {
        OneTimePurchase,
        PayPerUse,
        Subscription,
        Free
    }

    enum AIAnalysisStatus {
        Pending,
        Pass,
        Fail,
        ReviewRequired
    }

    enum ProposalType {
        AdjustPlatformFee,
        ChangeLicensePrice,
        ResolveDispute,
        GenericParameterChange
    }

    enum VoteStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    enum DisputeResult {
        Pending,
        ResolvedInFavorClaimant,
        ResolvedInFavorDefendant,
        InvalidClaim
    }

    // --- Structs ---
    struct IPDetails {
        string contentHash; // Immutable hash of the content (e.g., IPFS CID)
        string tokenURI;    // ERC721 metadata URI
        address owner;      // Current owner of the NFT
        uint256 creationTime;
        License license;
        AIAnalysisStatus aiStatus;
        string aiDetails;
        string originalClaimDetails; // Details provided during originality claim
        address originalClaimer;
        uint256 originalityClaimTime;
        address originalityAttester; // Address that attested originality
        bytes32 crossChainAttestationId; // ID from a simulated cross-chain attestation
        string crossChainAttestationDetails; // Details of the cross-chain attestation
        mapping(address => uint256) licenseUsageCounts; // For PayPerUse/Subscription tracking
    }

    struct License {
        LicenseModel model;
        uint256 price; // Price in WEI for OneTimePurchase/PayPerUse, or subscription price
        uint256 duration; // Duration in seconds for OneTimePurchase, or subscription period
        uint256 totalCollected; // Total accumulated fees for this IP, waiting to be collected by owner
        bool subscriptionEnabled;
        uint256 subscriptionPrice;
        uint256 renewalPeriod; // For subscription model, in seconds
    }

    struct ActiveSubscription {
        uint256 tokenId;
        address subscriber;
        uint224 lastPaymentTime; // last 224 bits of uint256 is enough for timestamp
        uint32 periodEnd;       // remaining 32 bits for small int (seconds timestamp)
    }

    struct Proposal {
        uint256 id;
        ProposalType _type;
        uint256 targetId;       // Can be tokenId, disputeId, etc. depending on _type
        uint256 newValue;       // For numerical changes (e.g., new fee, new price, DisputeResult enum)
        string description;
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotingPowerAtCreation; // Snapshot of voting power at proposal creation
        VoteStatus status;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    struct Reputation {
        int256 score; // Can be positive or negative
        uint256 lastRewardClaimTime;
    }

    struct Dispute {
        uint256 id;
        uint256 tokenId;
        address initiator;
        string reason;
        uint256 initiationTime;
        DisputeResult result;
        address arbiter; // Address that resolved the dispute (e.g., DAO executor, admin)
        uint256 resolutionTime;
    }

    // --- Mappings ---
    mapping(uint256 => IPDetails) public ipDetails;
    mapping(uint256 => mapping(address => ActiveSubscription)) public activeSubscriptions; // tokenId => subscriber => ActiveSubscription
    mapping(address => Reputation) public reputations;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event IPNFTMinted(uint256 indexed tokenId, address indexed owner, string contentHash, string tokenURI, LicenseModel model, uint256 price);
    event ContentHashUpdated(uint256 indexed tokenId, string newContentHash);
    event LicenseModelUpdated(uint256 indexed tokenId, LicenseModel model, uint256 price, uint256 duration);
    event LicensePurchased(uint256 indexed tokenId, address indexed buyer, uint256 amountPaid, LicenseModel model);
    event RoyaltiesCollected(uint256 indexed tokenId, address indexed collector, uint256 amount);
    event SubscriptionEnabled(uint256 indexed tokenId, uint256 price, uint256 renewalPeriod);
    event SubscriptionRenewed(uint256 indexed tokenId, address indexed subscriber, uint256 newPeriodEnd);
    event OriginalityClaimSubmitted(uint256 indexed tokenId, address indexed claimer, string claimDetails);
    event AIAnalysisRequested(uint256 indexed tokenId);
    event AIAnalysisResultUpdated(uint256 indexed tokenId, AIAnalysisStatus status, string details);
    event OriginalityAttested(uint256 indexed tokenId, address indexed attester);
    event CrossChainAttestationSet(uint256 indexed tokenId, bytes32 attestationId, string chainDetails);
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event CuratorialReviewSubmitted(uint256 indexed tokenId, address indexed reviewer, uint8 score);
    event ReputationScoreUpdated(address indexed user, int256 newScore);
    event ReputationRewardClaimed(address indexed user, uint256 amount);
    event CarbonOffsetFundsAllocated(uint256 amount); // Funds are implicitly held by contract, but this event marks allocation
    event CarbonOffsetFundsWithdrawn(address indexed recipient, uint256 amount);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed tokenId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed disputeId, DisputeResult result);
    event PlatformFeeUpdated(uint256 newFeeBasisPoints);

    // --- Constructor ---
    constructor() ERC721("GenesisForge IP-NFT", "GFIP") Ownable(msg.sender) {
        platformFeeBasisPoints = 500; // Default 5%
        carbonOffsetFactorBasisPoints = 100; // Default 1%
    }

    // --- Modifiers ---
    modifier onlyIPOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the IP owner");
        _;
    }

    modifier onlyOracle() {
        // In a real system, this would be a more sophisticated role-based access control or a whitelisted oracle address.
        // For this example, only the contract owner can act as an oracle.
        require(owner() == msg.sender, "Caller is not an authorized oracle");
        _;
    }

    // --- Core IP NFT Management ---

    /// @notice Mints a new IP-NFT, assigning a content hash and initial metadata.
    /// @param _contentHash A unique hash identifying the content (e.g., IPFS CID).
    /// @param _tokenURI The URI for the NFT's metadata (e.g., IPFS gateway URL).
    /// @param _model The initial licensing model for this IP.
    /// @param _price The initial price for the license (if applicable, in WEI).
    /// @param _duration The initial duration for the license (if applicable, in seconds).
    function mintGenesisNFT(
        string memory _contentHash,
        string memory _tokenURI,
        LicenseModel _model,
        uint256 _price,
        uint256 _duration
    ) public payable whenNotPaused nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");
        require(bytes(_tokenURI).length > 0, "Token URI cannot be empty");

        // Calculate platform and carbon offset shares from msg.value
        uint256 platformShare = (msg.value * platformFeeBasisPoints) / 10000;
        uint256 carbonOffsetAmount = (msg.value * carbonOffsetFactorBasisPoints) / 10000;
        // The remaining `msg.value` (if any) is assumed to be an explicit minting fee or excess.
        // For simplicity, these amounts are just "collected" into the contract balance
        // and marked by events. A real system would transfer to dedicated treasuries.
        emit CarbonOffsetFundsAllocated(carbonOffsetAmount); // For tracking
        // platformShare is implicitly held by the contract address

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        IPDetails storage newIP = ipDetails[newItemId];
        newIP.contentHash = _contentHash;
        newIP.tokenURI = _tokenURI;
        newIP.owner = msg.sender;
        newIP.creationTime = block.timestamp;
        newIP.license = License({
            model: _model,
            price: _price,
            duration: _duration,
            totalCollected: 0,
            subscriptionEnabled: false,
            subscriptionPrice: 0,
            renewalPeriod: 0
        });
        newIP.aiStatus = AIAnalysisStatus.Pending; // Initial status

        emit IPNFTMinted(newItemId, msg.sender, _contentHash, _tokenURI, _model, _price);
        return newItemId;
    }

    /// @notice Allows the IP-NFT owner to update the content hash of their NFT.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _newContentHash The new content hash (e.g., for a revised version).
    function updateContentHash(uint256 _tokenId, string memory _newContentHash)
        public
        onlyIPOwner(_tokenId)
        whenNotPaused
    {
        require(bytes(_newContentHash).length > 0, "New content hash cannot be empty");
        ipDetails[_tokenId].contentHash = _newContentHash;
        emit ContentHashUpdated(_tokenId, _newContentHash);
    }

    /// @notice Standard ERC721 function to update the metadata URI.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _newTokenURI The new URI for the metadata.
    function setTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyIPOwner(_tokenId)
        whenNotPaused
    {
        _setTokenURI(_tokenId, _newTokenURI);
    }

    // --- Dynamic Licensing & Monetization ---

    /// @notice Sets or updates the licensing model, price, and duration for an IP-NFT.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _model The new licensing model.
    /// @param _price The new price for the license.
    /// @param _duration The new duration for the license (if applicable).
    function setLicenseModel(
        uint256 _tokenId,
        LicenseModel _model,
        uint256 _price,
        uint256 _duration
    ) public onlyIPOwner(_tokenId) whenNotPaused {
        IPDetails storage ip = ipDetails[_tokenId];
        ip.license.model = _model;
        ip.license.price = _price;
        ip.license.duration = _duration;
        emit LicenseModelUpdated(_tokenId, _model, _price, _duration);
    }

    /// @notice Allows the IP-NFT owner to propose a new license price.
    /// @dev In a full DAO, this might trigger a governance proposal. For simplicity, this acts as a direct change by owner.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _newPrice The new proposed price.
    function adjustLicensePrice(uint256 _tokenId, uint256 _newPrice)
        public
        onlyIPOwner(_tokenId)
        whenNotPaused
    {
        ipDetails[_tokenId].license.price = _newPrice;
        emit LicenseModelUpdated(_tokenId, ipDetails[_tokenId].license.model, _newPrice, ipDetails[_tokenId].license.duration);
    }

    /// @notice Allows a user to purchase a license for an IP-NFT.
    /// @param _tokenId The ID of the IP-NFT.
    function purchaseLicense(uint256 _tokenId) public payable nonReentrant whenNotPaused {
        IPDetails storage ip = ipDetails[_tokenId];
        require(ip.license.model != LicenseModel.Free, "License is free, no purchase required.");
        require(msg.value >= ip.license.price, "Insufficient payment for license.");

        uint256 platformShare = (msg.value * platformFeeBasisPoints) / 10000;
        uint256 carbonOffsetShare = (msg.value * carbonOffsetFactorBasisPoints) / 10000;
        uint256 ownerShare = msg.value - platformShare - carbonOffsetShare;

        // Transfer owner share, collect platform share and carbon offset internally
        // In a real system, platformShare would go to a treasury contract.
        // carbonOffsetShare would go to a dedicated carbon offset fund.
        payable(ip.owner).transfer(ownerShare);
        ip.license.totalCollected += ownerShare; // Track owner's collectible royalties
        emit CarbonOffsetFundsAllocated(carbonOffsetShare);

        // Increment usage count for PayPerUse or Subscription models
        ip.licenseUsageCounts[msg.sender]++;

        emit LicensePurchased(_tokenId, msg.sender, msg.value, ip.license.model);
    }

    /// @notice Allows the IP-NFT owner to collect their accumulated royalties.
    /// @param _tokenId The ID of the IP-NFT.
    function collectRoyalties(uint256 _tokenId) public onlyIPOwner(_tokenId) nonReentrant whenNotPaused {
        IPDetails storage ip = ipDetails[_tokenId];
        uint256 amount = ip.license.totalCollected;
        require(amount > 0, "No royalties to collect.");

        ip.license.totalCollected = 0; // Reset after collection
        payable(msg.sender).transfer(amount);
        emit RoyaltiesCollected(_tokenId, msg.sender, amount);
    }

    /// @notice Configures tiered discounts for licenses based on usage counts.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _tierThreshold The usage count threshold to qualify for the discount.
    /// @param _discountPercentage The discount percentage (e.g., 10 for 10%).
    /// @dev This function merely signals the intent to set up tiers. Actual discount application logic in `purchaseLicense` would be more complex.
    function setUsageTierDiscount(
        uint256 _tokenId,
        uint256 _tierThreshold,
        uint256 _discountPercentage
    ) public onlyIPOwner(_tokenId) whenNotPaused {
        require(_discountPercentage <= 100, "Discount percentage cannot exceed 100%");
        // This function would typically store these tiers in a dedicated mapping
        // (e.g., `mapping(uint256 => mapping(uint256 => uint256)) public usageTiers;`).
        // For simplicity, we just emit an event to indicate the setup.
        emit LicenseModelUpdated(_tokenId, ipDetails[_tokenId].license.model, ipDetails[_tokenId].license.price, ipDetails[_tokenId].license.duration); // Re-use event
    }

    /// @notice Activates a recurring subscription model for an IP-NFT.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _subscriptionPrice The price per renewal period.
    /// @param _renewalPeriod The duration of one subscription period in seconds.
    function enableSubscription(
        uint256 _tokenId,
        uint256 _subscriptionPrice,
        uint256 _renewalPeriod
    ) public onlyIPOwner(_tokenId) whenNotPaused {
        IPDetails storage ip = ipDetails[_tokenId];
        ip.license.subscriptionEnabled = true;
        ip.license.subscriptionPrice = _subscriptionPrice;
        ip.license.renewalPeriod = _renewalPeriod;
        ip.license.model = LicenseModel.Subscription; // Ensure model is set to Subscription
        emit SubscriptionEnabled(_tokenId, _subscriptionPrice, _renewalPeriod);
    }

    /// @notice Allows an existing subscriber to renew their active license.
    /// @param _tokenId The ID of the IP-NFT.
    function renewSubscription(uint256 _tokenId) public payable nonReentrant whenNotPaused {
        IPDetails storage ip = ipDetails[_tokenId];
        require(ip.license.subscriptionEnabled, "Subscription not enabled for this IP.");
        require(msg.value >= ip.license.subscriptionPrice, "Insufficient payment for renewal.");

        ActiveSubscription storage sub = activeSubscriptions[_tokenId][msg.sender];
        // If it's a new subscription for this user, tokenId will be 0.
        // If it's a renewal, sub.subscriber will be msg.sender.
        require(sub.subscriber == msg.sender || sub.tokenId == 0, "Invalid subscription record.");
        
        uint256 platformShare = (msg.value * platformFeeBasisPoints) / 10000;
        uint256 carbonOffsetShare = (msg.value * carbonOffsetFactorBasisPoints) / 10000;
        uint256 ownerShare = msg.value - platformShare - carbonOffsetShare;

        payable(ip.owner).transfer(ownerShare);
        ip.license.totalCollected += ownerShare;
        emit CarbonOffsetFundsAllocated(carbonOffsetShare);

        // Calculate the new subscription end time. If initial subscription, start from now. Else, extend.
        uint256 currentPeriodEnd = (sub.tokenId == 0 || block.timestamp > uint256(sub.periodEnd)) ? block.timestamp : uint256(sub.periodEnd);
        uint256 newPeriodEnd = currentPeriodEnd + ip.license.renewalPeriod;

        activeSubscriptions[_tokenId][msg.sender] = ActiveSubscription({
            tokenId: _tokenId,
            subscriber: msg.sender,
            lastPaymentTime: uint224(block.timestamp),
            periodEnd: uint32(newPeriodEnd)
        });

        // Increment usage count even for subscriptions
        ip.licenseUsageCounts[msg.sender]++;

        emit SubscriptionRenewed(_tokenId, msg.sender, newPeriodEnd);
    }

    // --- Proof of Originality & AI Integration (Simulated/Oracle-based) ---

    /// @notice Allows a user to submit a claim of originality for their content.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _claimDetails A string containing details about the originality claim.
    function submitOriginalityClaim(uint256 _tokenId, string memory _claimDetails)
        public
        onlyIPOwner(_tokenId)
        whenNotPaused
    {
        IPDetails storage ip = ipDetails[_tokenId];
        ip.originalClaimer = msg.sender;
        ip.originalClaimDetails = _claimDetails;
        ip.originalityClaimTime = block.timestamp;
        emit OriginalityClaimSubmitted(_tokenId, msg.sender, _claimDetails);
    }

    /// @notice Triggers a simulated off-chain AI analysis request for submitted content.
    /// @dev This function merely emits an event to signal an off-chain process.
    /// @param _tokenId The ID of the IP-NFT to analyze.
    function requestAIAnalysis(uint256 _tokenId) public onlyIPOwner(_tokenId) whenNotPaused {
        emit AIAnalysisRequested(_tokenId);
    }

    /// @notice An authorized oracle sets the result of an off-chain AI analysis.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _status The status of the AI analysis (e.g., Pass, Fail).
    /// @param _details Additional details about the AI analysis result.
    function setAIAnalysisResult(
        uint256 _tokenId,
        AIAnalysisStatus _status,
        string memory _details
    ) public onlyOracle whenNotPaused {
        ipDetails[_tokenId].aiStatus = _status;
        ipDetails[_tokenId].aiDetails = _details;
        emit AIAnalysisResultUpdated(_tokenId, _status, _details);
    }

    /// @notice Allows a designated curator/oracle to formally attest to the originality of content.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _attester The address of the attester.
    function attestOriginalityProof(uint256 _tokenId, address _attester) public onlyOracle whenNotPaused {
        ipDetails[_tokenId].originalityAttester = _attester;
        emit OriginalityAttested(_tokenId, _attester);
    }

    /// @notice Records a placeholder for a simulated cross-chain attestation.
    /// @dev This function does not perform actual cross-chain communication, only records data.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _attestationId A unique ID for the cross-chain attestation.
    /// @param _chainDetails Details about the chain and attestation (e.g., "Polygon:0x123...").
    function setCrossChainAttestation(
        uint256 _tokenId,
        bytes32 _attestationId,
        string memory _chainDetails
    ) public onlyOracle whenNotPaused {
        ipDetails[_tokenId].crossChainAttestationId = _attestationId;
        ipDetails[_tokenId].crossChainAttestationDetails = _chainDetails;
        emit CrossChainAttestationSet(_tokenId, _attestationId, _chainDetails);
    }

    // --- Decentralized Governance (Simplified DAO) ---

    /// @notice Allows stake-holders to propose changes to contract parameters or initiate actions.
    /// @dev For simplicity, any owner of an IP-NFT or user with reputation can propose. In a real DAO, this would involve dedicated governance tokens.
    /// @param _type The type of proposal.
    /// @param _targetId The ID relevant to the proposal (e.g., tokenId for price changes, disputeId for resolution).
    /// @param _newValue A numerical value relevant to the proposal (e.g., new fee, new price, DisputeResult enum value).
    /// @param _description A detailed description of the proposal.
    function proposeGovernanceAction(
        ProposalType _type,
        uint256 _targetId,
        uint256 _newValue,
        string memory _description
    ) public whenNotPaused returns (uint256) {
        // Require some form of stake (e.g., owning an IP-NFT) or reputation to propose
        require(balanceOf(msg.sender) > 0 || reputations[msg.sender].score > 0, "No voting power to propose.");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            _type: _type,
            targetId: _targetId,
            newValue: _newValue,
            description: _description,
            proposer: msg.sender,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            totalVotingPowerAtCreation: totalVotingPower(), // Snapshot total voting power
            status: VoteStatus.Active,
            executed: false
        });

        emit ProposalCreated(proposalId, _type, msg.sender, _description);
        return proposalId;
    }

    /// @notice Allows users with voting power to cast their vote on active proposals.
    /// @param _proposalId The ID of the proposal.
    /// @param _support True for Yes, False for No.
    function castVote(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == VoteStatus.Active, "Proposal is not active.");
        require(block.timestamp <= proposal.voteEndTime, "Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal.");

        uint256 voterPower = getVotingPower(msg.sender);
        require(voterPower > 0, "Caller has no voting power.");

        if (_support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a proposal that has met its voting quorum and threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == VoteStatus.Active, "Proposal not active.");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended.");
        require(!proposal.executed, "Proposal already executed.");

        // Example: simple majority rule, assuming minimum 10% participation (quorum)
        uint256 totalVoted = proposal.yesVotes + proposal.noVotes;
        uint256 quorumThreshold = (proposal.totalVotingPowerAtCreation * 10) / 100; // 10% quorum

        if (totalVoted >= quorumThreshold && proposal.yesVotes > proposal.noVotes) {
            // Proposal Succeeded
            proposal.status = VoteStatus.Succeeded;
            proposal.executed = true;

            // Execute the specific action based on proposal type
            if (proposal._type == ProposalType.AdjustPlatformFee) {
                _updatePlatformFee(proposal.newValue);
            } else if (proposal._type == ProposalType.ChangeLicensePrice) {
                // This assumes `_targetId` is the tokenId and `_newValue` is the new price.
                // In a real system, more validation might be needed (e.g., only owner can propose, or this specific IP-NFT exists).
                ipDetails[proposal.targetId].license.price = proposal.newValue;
                emit LicenseModelUpdated(proposal.targetId, ipDetails[proposal.targetId].license.model, proposal.newValue, ipDetails[proposal.targetId].license.duration);
            } else if (proposal._type == ProposalType.ResolveDispute) {
                // This assumes `_targetId` is the disputeId and `_newValue` encodes the `DisputeResult` enum value.
                resolveDispute(proposal.targetId, DisputeResult(proposal.newValue));
            }
            // Add more proposal type handling here for other GenericParameterChange cases

            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = VoteStatus.Failed;
        }
    }

    /// @notice Allows users to delegate their voting power to another address.
    /// @dev This function is illustrative. In a real system, this would modify a mapping: `user -> delegatedTo`,
    /// and `getVotingPower` would recursively resolve the delegation chain.
    /// For demonstration, we simply emit an event.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) public {
        require(_delegatee != address(0), "Cannot delegate to zero address.");
        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @dev Internal function to get voting power (e.g., based on NFT holdings and reputation).
    function getVotingPower(address _voter) internal view returns (uint256) {
        // Simple voting power: 1 vote per IP-NFT owned, plus reputation bonus.
        // Can be much more complex (e.g., governance token balance, time-locked tokens).
        return balanceOf(_voter) + uint256(reputations[_voter].score / 100); // Example: 100 reputation points = 1 additional vote
    }

    /// @dev Internal function to calculate total voting power for snapshot at proposal creation.
    function totalVotingPower() internal view returns (uint256) {
        uint256 total = 0;
        uint256 numTokens = totalSupply(); // Total minted NFTs
        for (uint256 i = 0; i < numTokens; i++) {
            address owner = ownerOf(tokenByIndex(i));
            total += getVotingPower(owner);
        }
        return total;
    }

    // --- Reputation & Gamification ---

    /// @notice Allows users to submit a review for an IP-NFT, influencing reputation.
    /// @param _tokenId The ID of the IP-NFT being reviewed.
    /// @param _score The review score (e.g., 1-5).
    /// @param _reviewText The text of the review.
    function submitCuratorialReview(
        uint256 _tokenId,
        uint8 _score,
        string memory _reviewText
    ) public whenNotPaused {
        require(_score >= 1 && _score <= 5, "Score must be between 1 and 5.");
        // This function would typically store reviews (e.g., in a separate mapping or struct).
        // For simplicity, it directly impacts the reviewer's reputation based on score.
        // In a real system, reviews might be subject to auditing before affecting reputation to prevent abuse.
        if (_score >= 4) {
            updateReputationScore(msg.sender, 5); // Reward good reviews
        } else if (_score <= 2) {
            updateReputationScore(msg.sender, -2); // Penalize low-quality reviews if system detects spam/malice
        }
        emit CuratorialReviewSubmitted(_tokenId, msg.sender, _score);
        // A full system would also update a composite quality score for the IP-NFT itself based on reviews.
    }

    /// @notice Internal/External function to adjust a user's reputation score.
    /// @dev Can be called by contract owner, governance (DAO) after a vote, or other trusted contract functions.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _change The change in reputation score (can be positive or negative).
    function updateReputationScore(address _user, int256 _change) public onlyOwner {
        // Can only be called by contract owner or governance (DAO)
        reputations[_user].score += _change;
        emit ReputationScoreUpdated(_user, reputations[_user].score);
    }

    /// @notice Allows users to claim rewards based on their reputation tier.
    /// @dev Rewards would be specific to the platform (e.g., discounts, native tokens, special access).
    /// For demonstration, it transfers native currency (ETH/MATIC etc.) from contract balance.
    /// @param _recipient The address to send the reward to.
    function claimReputationReward(address _recipient) public nonReentrant whenNotPaused {
        Reputation storage rep = reputations[msg.sender];
        require(rep.score > 0, "No positive reputation to claim rewards.");
        require(block.timestamp >= rep.lastRewardClaimTime + 30 days, "Can only claim rewards once a month."); // Cooldown period

        uint256 rewardAmount = uint256(rep.score * 100); // Example: 100 WEI per score point
        require(address(this).balance >= rewardAmount, "Insufficient contract balance for reward.");

        rep.lastRewardClaimTime = block.timestamp;
        payable(_recipient).transfer(rewardAmount); // Transfer from contract balance
        emit ReputationRewardClaimed(msg.sender, rewardAmount);
    }

    // --- Advanced & Trending Concepts ---

    /// @notice Sets a percentage of collected fees that are allocated for simulated carbon offsetting.
    /// @param _factorBasisPoints The percentage in basis points (e.g., 100 for 1%).
    function setCarbonOffsetFactor(uint256 _factorBasisPoints) public onlyOwner whenNotPaused {
        require(_factorBasisPoints <= 10000, "Factor cannot exceed 100%");
        carbonOffsetFactorBasisPoints = _factorBasisPoints;
    }

    /// @notice Allows a designated address to withdraw accumulated carbon offset funds for off-chain initiatives.
    /// @dev In a real system, these funds would be in a separate treasury contract managed by the DAO.
    /// For simplicity, they are held in this contract's balance implicitly by `emit CarbonOffsetFundsAllocated`.
    /// This function needs to be carefully handled as the contract doesn't explicitly track allocated funds but assumes
    /// this withdrawal aligns with the off-chain carbon offset initiatives.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount of funds to withdraw.
    function withdrawCarbonOffsetFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant {
        require(_recipient != address(0), "Recipient cannot be zero address.");
        require(address(this).balance >= _amount, "Insufficient contract balance for withdrawal.");
        
        payable(_recipient).transfer(_amount);
        emit CarbonOffsetFundsWithdrawn(_recipient, _amount);
    }

    /// @notice Initiates a formal dispute resolution process for an IP-NFT.
    /// @param _tokenId The ID of the IP-NFT involved in the dispute.
    /// @param _reason A description of the dispute.
    function initiateDisputeResolution(uint256 _tokenId, string memory _reason)
        public
        whenNotPaused
        returns (uint256)
    {
        _disputeIdCounter.increment();
        uint256 disputeId = _disputeIdCounter.current();

        disputes[disputeId] = Dispute({
            id: disputeId,
            tokenId: _tokenId,
            initiator: msg.sender,
            reason: _reason,
            initiationTime: block.timestamp,
            result: DisputeResult.Pending,
            arbiter: address(0), // To be set by DAO or admin later upon resolution
            resolutionTime: 0
        });
        emit DisputeInitiated(disputeId, _tokenId, msg.sender, _reason);
        return disputeId;
    }

    /// @notice An authorized entity (e.g., DAO vote, designated arbiter) resolves an active dispute.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _result The outcome of the dispute.
    function resolveDispute(uint256 _disputeId, DisputeResult _result) public onlyOwner nonReentrant whenNotPaused {
        // In a real system, this would be callable by DAO via a successful proposal execution, or a designated arbiter contract.
        // For this example, only the contract owner can resolve.
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.result == DisputeResult.Pending, "Dispute already resolved.");
        require(_result != DisputeResult.Pending, "Result cannot be pending.");

        dispute.result = _result;
        dispute.arbiter = msg.sender; // Or the address that executed the DAO proposal
        dispute.resolutionTime = block.timestamp;

        // Example: If dispute resolves in favor of claimant, potentially trigger actions (e.g., transfer ownership).
        // This is complex and requires careful logic depending on the dispute type.
        // For simplicity, we just mark it resolved. Actual ownership transfer would need specific parameters
        // and robust checks if triggered here directly.
        // if (_result == DisputeResult.ResolvedInFavorClaimant) {
        //     _transfer(ownerOf(dispute.tokenId), dispute.initiator, dispute.tokenId);
        // }
        emit DisputeResolved(_disputeId, _result);
    }

    /// @notice Allows governance (or the contract owner initially) to adjust the platform's service fee.
    /// @param _newFeeBasisPoints The new platform fee in basis points (e.g., 500 for 5%).
    function updatePlatformFee(uint256 _newFeeBasisPoints) public onlyOwner {
        _updatePlatformFee(_newFeeBasisPoints);
    }

    /// @dev Internal function to update the platform fee, callable by owner or executeProposal.
    function _updatePlatformFee(uint256 _newFeeBasisPoints) internal {
        require(_newFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        platformFeeBasisPoints = _newFeeBasisPoints;
        emit PlatformFeeUpdated(_newFeeBasisPoints);
    }

    /// @notice Emergency function allowing the owner/governance to pause critical contract operations.
    function pauseContractOperations() public onlyOwner {
        _pause();
    }

    /// @notice Resumes contract operations after they have been paused.
    function unpauseContractOperations() public onlyOwner {
        _unpause();
    }

    // --- View Functions ---

    /// @notice Returns the details of a specific IP-NFT.
    /// @param _tokenId The ID of the IP-NFT.
    /// @return ipDetailsStruct The struct containing all IP details.
    function getIPDetails(uint256 _tokenId) public view returns (IPDetails memory) {
        IPDetails storage ip = ipDetails[_tokenId];
        return ip;
    }

    /// @notice Returns the current license details for an IP-NFT.
    /// @param _tokenId The ID of the IP-NFT.
    /// @return licenseModel The licensing model.
    /// @return price The price.
    /// @return duration The duration.
    /// @return totalCollected The total royalties collected.
    /// @return subscriptionEnabled True if subscription is enabled.
    /// @return subscriptionPrice The subscription price.
    /// @return renewalPeriod The subscription renewal period.
    function getLicenseDetails(uint256 _tokenId)
        public
        view
        returns (
            LicenseModel licenseModel,
            uint256 price,
            uint256 duration,
            uint256 totalCollected,
            bool subscriptionEnabled,
            uint256 subscriptionPrice,
            uint256 renewalPeriod
        )
    {
        License storage lic = ipDetails[_tokenId].license;
        return (
            lic.model,
            lic.price,
            lic.duration,
            lic.totalCollected,
            lic.subscriptionEnabled,
            lic.subscriptionPrice,
            lic.renewalPeriod
        );
    }

    /// @notice Returns the current subscription status for a user and IP.
    /// @param _tokenId The ID of the IP-NFT.
    /// @param _subscriber The address of the subscriber.
    /// @return isActive True if subscription is active (current time < periodEnd).
    /// @return lastPaymentTime The timestamp of the last payment.
    /// @return periodEnd The timestamp when the current subscription period ends.
    function getSubscriptionStatus(uint256 _tokenId, address _subscriber)
        public
        view
        returns (bool isActive, uint256 lastPaymentTime, uint256 periodEnd)
    {
        ActiveSubscription storage sub = activeSubscriptions[_tokenId][_subscriber];
        if (sub.tokenId == 0) return (false, 0, 0); // No record found for this subscriber

        isActive = (block.timestamp < uint256(sub.periodEnd));
        return (isActive, uint256(sub.lastPaymentTime), uint256(sub.periodEnd));
    }

    /// @notice Returns a user's current reputation score.
    /// @param _user The address of the user.
    /// @return score The current reputation score.
    function getReputationScore(address _user) public view returns (int256) {
        return reputations[_user].score;
    }

    /// @notice Returns the details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposalStruct The struct containing all proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Returns the details of a specific dispute.
    /// @param _disputeId The ID of the dispute.
    /// @return disputeStruct The struct containing all dispute details.
    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        return disputes[_disputeId];
    }
}
```