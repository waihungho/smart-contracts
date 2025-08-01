This smart contract, `AetherForge`, is designed as a Decentralized Autonomous Intellectual Property (DAIP) Vault. It aims to provide a comprehensive ecosystem for digital content creators to manage, license, and monetize their intellectual property in a truly decentralized manner. It integrates several advanced, creative, and trendy concepts:

*   **Dynamic NFTs:** IPs are represented as NFTs whose metadata can be updated.
*   **AI-Assisted Licensing & Provenance (Oracle-based):** Simulates AI interaction for uniqueness scoring and automated license suggestions, leveraging external oracles.
*   **Hierarchical Derivative Works Management:** Tracks and enforces royalty distribution across a "family tree" of original and derived IPs.
*   **Sophisticated Licensing Models:** Beyond simple sales, supports various license types, durations, and sub-licensing revenue sharing.
*   **On-chain Dispute Resolution:** A stake-based system for challenging IP registrations, resolved by a community of curators.
*   **Subscription-based IP Access:** Allows creators to offer recurring access to their IP.
*   **Decentralized Governance (DAO-Lite):** Key contract parameters are managed through community proposals and voting by staked curators.

---

### Contract Outline & Function Summary

**Contract Name:** AetherForge - Decentralized Autonomous Intellectual Property (DAIP) Vault

**Core Concept:** AetherForge is a pioneering smart contract platform designed to revolutionize the management and monetization of digital intellectual property. It integrates advanced concepts such as dynamic NFTs, AI-assisted licensing (via oracles), complex derivative work tracking with automated revenue distribution, on-chain dispute resolution, and a decentralized governance model. It aims to empower creators with unprecedented control over their digital assets, foster a vibrant ecosystem for content creation, and ensure fair compensation across the entire IP lifecycle.

---

**I. Core IP Management & NFT Functions (ERC721 Compliant)**
    *   `IPData` struct: Defines the structure for each registered Intellectual Property, including metadata, ownership, licensing state, uniqueness score, and a flag for availability.
    *   `registerOriginalIP(string memory _ipfsHash, string memory _metadataURI, uint256 _initialLicensingFee)`: Mints a new, unique IP NFT representing original content. The IP owner is the minter.
    *   `updateIPMetadata(uint256 _ipId, string memory _newMetadataURI)`: Allows the IP owner to dynamically update the metadata URI of their IP NFT, enabling evolving content or attributes.
    *   `transferIPOwnership(uint256 _ipId, address _newOwner)`: Standard ERC721 function to transfer ownership of an IP NFT.
    *   `setIPPrice(uint256 _ipId, uint256 _newPrice)`: Sets a direct sale price for an original IP, allowing it to be bought outright (external to this contract's direct buy, but sets value).
    *   `toggleIPAvailability(uint256 _ipId, bool _isAvailable)`: Allows the IP owner to control the public availability/discoverability of their IP for licensing or sale.
    *   `burnIP(uint256 _ipId)`: Allows the IP owner to irrevocably burn their IP NFT, removing it from circulation.

**II. Licensing & Royalties**
    *   `LicenseOffer` struct: Defines a template for a specific licensing arrangement.
    *   `License` struct: Represents an active license granted for an IP.
    *   `LicenseType` enum: Categorizes different types of licenses (e.g., Commercial, NonCommercial, LimitedUse).
    *   `createLicenseOffer(uint256 _ipId, LicenseType _licenseType, uint256 _fee, uint256 _duration, bytes32 _termsHash)`: Enables an IP owner to define and publish a new licensing offer for their IP.
    *   `purchaseLicense(uint256 _licenseOfferId, address _recipient)`: Allows a user to purchase a specific license offer for an IP. Automatically distributes royalties up the derivative chain.
    *   `distributeRoyalties(uint256 _ipId, uint256 _amount)`: Allows an IP owner or an oracle to push royalty payments to the original creator and derivative creators based on predefined shares, typically from off-chain earnings.
    *   `setLicenseShareRecipient(uint256 _licenseId, address _recipient, uint256 _percentage)`: Allows the original licensee to designate a portion of their future earnings from sub-licensing to another address.
    *   `extendLicenseDuration(uint256 _licenseId, uint256 _additionalDuration)`: Allows a current licensee to extend the validity period of their existing license, with prorated cost.

**III. Derivative Works & Provenance**
    *   `DerivativeLink` struct: Stores information about a derivative work and its link to the parent IP.
    *   `registerDerivativeWork(uint256 _parentIpId, string memory _derivativeIpfsHash, string memory _derivativeMetadataURI, uint256 _parentSharePercentage)`: Mints a new NFT for a derivative work, establishing an immutable link to its parent IP and setting the revenue share for the parent. Requires a valid license for the parent IP.
    *   `updateDerivativeShare(uint256 _derivativeIpId, uint256 _newParentSharePercentage)`: Allows the creator of a derivative work to adjust the revenue share allocated to its parent IP.
    *   `getDerivativeTree(uint256 _ipId)`: Retrieves a list of all direct derivatives registered for a given IP.

**IV. AI-Assisted Features (Oracle-based Simulation)**
    *   `requestUniquenessScore(uint256 _ipId)`: Sends a request to a trusted oracle to evaluate the uniqueness of an IP's content (e.g., against a large dataset) and return a score.
    *   `fulfillUniquenessScore(uint256 _ipId, uint256 _score, bytes32 _queryId)`: Callback function for the oracle to return the uniqueness score for a requested IP.
    *   `requestAutomatedLicenseSuggestion(uint256 _ipId, string memory _intendedUseDescription)`: Requests an AI oracle to suggest optimal licensing terms (fee, duration, terms) based on the IP's content and intended use.
    *   `fulfillLicenseSuggestion(uint256 _ipId, uint256 _suggestedFee, uint256 _suggestedDuration, bytes32 _suggestedTermsHash, bytes32 _queryId)`: Callback for the oracle to return AI-suggested license parameters.

**V. Governance & Treasury (DAO-Lite)**
    *   `Proposal` struct: Defines the structure for on-chain governance proposals.
    *   `ProposalState` enum: Tracks the lifecycle of a proposal (e.g., Pending, Active, Succeeded, Failed, Executed).
    *   `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Allows stakers (curators) to propose changes to critical contract parameters (e.g., oracle fees, staking minimums).
    *   `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible stakers to cast their vote on an active proposal.
    *   `executeProposal(uint255 _proposalId)`: Executes a proposal that has met the voting quorum and grace period, updating contract parameters.
    *   `setOracleAddress(address _newOracle)`: An initial owner function, intended to be controlled by governance after initial setup, to update the address of the trusted oracle.

**VI. Staking, Curation & Dispute Resolution**
    *   `Challenge` struct: Defines a dispute submitted against an IP.
    *   `ChallengeState` enum: Tracks the status of a challenge (e.g., Active, ResolvedValid, ResolvedInvalid).
    *   `stakeForCuratorialRights(uint256 _amount)`: Allows users to stake Ether to gain curatorial power (voting rights, dispute resolution participation).
    *   `unstakeCuratorialRights()`: Allows a staker to withdraw their staked Ether after a cool-down period.
    *   `challengeIPRegistration(uint256 _ipId, string memory _reason)`: Initiates a formal dispute against an IP's registration (e.g., for plagiarism or misrepresentation), requiring a staked amount.
    *   `resolveChallenge(uint256 _challengeId, bool _isValid)`: A function callable by elected curators or governance to decide the outcome of a dispute, affecting stakes (challenger either gets stake back or loses it to the treasury).

**VII. Advanced Utilities & Monetization Models**
    *   `TimedAccessGrant` struct: Represents temporary access granted to an IP.
    *   `IPSubscription` struct: Defines an IP owner's subscription offer.
    *   `UserSubscription` struct: Tracks a user's active subscription to an IP.
    *   `grantTimedAccess(uint256 _ipId, address _recipient, uint256 _duration)`: Allows an IP owner to grant temporary, non-transferable access to their IP to a specific address without full licensing.
    *   `setupSubscriptionAccess(uint256 _ipId, uint256 _monthlyFee, uint256 _minMonths)`: Enables an IP owner to configure a recurring subscription model for their IP.
    *   `subscribeToIP(uint256 _ipId, uint256 _numMonths)`: Allows a user to subscribe to an IP for a specified number of months. Payment automatically distributes royalties up the derivative chain.
    *   `claimSubscriptionEarnings(uint256 _ipId)`: Allows the IP owner to claim accumulated earnings from active subscriptions to their IP (from a simplified internal accounting).
    *   `hasTimedAccess(uint256 _ipId, address _user)`: Checks if a user has active timed access to a specific IP.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment, intended to transition to governance
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Useful for fetching all IPs or user's IPs

// --- Custom Errors ---
error AetherForge__InvalidIPId();
error AetherForge__NotIPOwner();
error AetherForge__IPNotAvailable();
error AetherForge__InvalidLicenseOffer();
error AetherForge__LicenseNotActive();
error AetherForge__InsufficientFunds();
error AetherForge__NotLicensee();
error AetherForge__InvalidSharePercentage();
error AetherForge__SelfDerivativeNotAllowed();
error AetherForge__InvalidParentShare();
error AetherForge__ChallengeAlreadyExists();
error AetherForge__ChallengeNotFound();
error AetherForge__ChallengeNotResolved();
error AetherForge__InsufficientStake();
error AetherForge__SubscriptionAlreadyActive();
error AetherForge__SubscriptionExpired();
error AetherForge__NotEnoughMonths();
error AetherForge__NoEarningsToClaim();
error AetherForge__InvalidProposalId();
error AetherForge__ProposalNotActive();
error AetherForge__AlreadyVoted();
error AetherForge__VotingPeriodNotEnded();
error AetherForge__ProposalNotPassed();
error AetherForge__ProposalAlreadyExecuted();
error AetherForge__OnlyOracle();
error AetherForge__OracleCallbackFailed();
error AetherForge__NotEnoughStakedForCurator();
error AetherForge__CannotUnstakeWhileChallenging(); // Re-used for cooldown period
error AetherForge__TimedAccessExpired();
error AetherForge__CreatorCannotSubscribeToOwnIP();

// --- Interfaces ---
interface IOracle {
    // A simplified oracle interface. In a real scenario, this would interact with Chainlink or similar.
    // requestData would trigger an off-chain computation/data fetch for AI analysis.
    function requestData(
        bytes32 _queryId, // Unique ID for the specific request
        string calldata _callbackFunction, // The function on this contract to call back
        bytes calldata _data // Encoded data for the oracle to process
    ) external returns (bytes32 requestId);
}

// --- Contract Outline & Function Summary ---
/*
Contract Name: AetherForge - Decentralized Autonomous Intellectual Property (DAIP) Vault

Core Concept: AetherForge is a pioneering smart contract platform designed to revolutionize the management and monetization of digital intellectual property. It integrates advanced concepts such as dynamic NFTs, AI-assisted licensing (via oracles), complex derivative work tracking with automated revenue distribution, on-chain dispute resolution, and a decentralized governance model. It aims to empower creators with unprecedented control over their digital assets, foster a vibrant ecosystem for content creation, and ensure fair compensation across the entire IP lifecycle.

---

I. Core IP Management & NFT Functions (ERC721 Compliant)
    - `IPData` struct: Defines the structure for each registered Intellectual Property, including metadata, ownership, licensing state, uniqueness score, and a flag for availability.
    - `registerOriginalIP(string memory _ipfsHash, string memory _metadataURI, uint256 _initialLicensingFee)`: Mints a new, unique IP NFT representing original content.
    - `updateIPMetadata(uint256 _ipId, string memory _newMetadataURI)`: Allows the IP owner to dynamically update the metadata URI of their IP NFT, enabling evolving content or attributes.
    - `transferIPOwnership(uint256 _ipId, address _newOwner)`: Standard ERC721 function to transfer ownership of an IP NFT.
    - `setIPPrice(uint256 _ipId, uint256 _newPrice)`: Sets a direct sale price for an original IP, allowing it to be bought outright.
    - `toggleIPAvailability(uint256 _ipId, bool _isAvailable)`: Allows the IP owner to control the public availability/discoverability of their IP for licensing or sale.
    - `burnIP(uint256 _ipId)`: Allows the IP owner to irrevocably burn their IP NFT, removing it from circulation.

II. Licensing & Royalties
    - `LicenseOffer` struct: Defines a template for a specific licensing arrangement.
    - `License` struct: Represents an active license granted for an IP.
    - `LicenseType` enum: Categorizes different types of licenses (e.g., Commercial, NonCommercial, LimitedUse).
    - `createLicenseOffer(uint256 _ipId, LicenseType _licenseType, uint256 _fee, uint256 _duration, bytes32 _termsHash)`: Enables an IP owner to define and publish a new licensing offer for their IP.
    - `purchaseLicense(uint256 _licenseOfferId, address _recipient)`: Allows a user to purchase a specific license offer for an IP.
    - `distributeRoyalties(uint256 _ipId, uint256 _amount)`: Allows an IP owner or an oracle to push royalty payments to the original creator and derivative creators based on predefined shares.
    - `setLicenseShareRecipient(uint256 _licenseId, address _recipient, uint256 _percentage)`: Allows the original licensee to designate a portion of their future earnings from sub-licensing to another address.
    - `extendLicenseDuration(uint256 _licenseId, uint256 _additionalDuration)`: Allows a current licensee to extend the validity period of their existing license.

III. Derivative Works & Provenance
    - `DerivativeLink` struct: Stores information about a derivative work and its link to the parent IP.
    - `registerDerivativeWork(uint256 _parentIpId, string memory _derivativeIpfsHash, string memory _derivativeMetadataURI, uint256 _parentSharePercentage)`: Mints a new NFT for a derivative work, establishing an immutable link to its parent IP and setting the revenue share for the parent.
    - `updateDerivativeShare(uint256 _derivativeIpId, uint256 _newParentSharePercentage)`: Allows the creator of a derivative work to adjust the revenue share allocated to its parent IP.
    - `getDerivativeTree(uint256 _ipId)`: Retrieves a list of all direct derivatives registered for a given IP.

IV. AI-Assisted Features (Oracle-based Simulation)
    - `requestUniquenessScore(uint256 _ipId)`: Sends a request to a trusted oracle to evaluate the uniqueness of an IP's content (e.g., against a large dataset) and return a score.
    - `fulfillUniquenessScore(uint256 _ipId, uint256 _score, bytes32 _queryId)`: Callback function for the oracle to return the uniqueness score for a requested IP.
    - `requestAutomatedLicenseSuggestion(uint256 _ipId, string memory _intendedUseDescription)`: Requests an AI oracle to suggest optimal licensing terms (fee, duration, terms) based on the IP's content and intended use.
    - `fulfillLicenseSuggestion(uint256 _ipId, uint256 _suggestedFee, uint256 _suggestedDuration, bytes32 _suggestedTermsHash, bytes32 _queryId)`: Callback for the oracle to return AI-suggested license parameters.

V. Governance & Treasury (DAO-Lite)
    - `Proposal` struct: Defines the structure for on-chain governance proposals.
    - `ProposalState` enum: Tracks the lifecycle of a proposal (e.g., Pending, Active, Succeeded, Failed, Executed).
    - `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Allows stakers (curators) to propose changes to critical contract parameters (e.g., oracle fees, staking minimums).
    - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible stakers to cast their vote on an active proposal.
    - `executeProposal(uint256 _proposalId)`: Executes a proposal that has met the voting quorum and grace period.
    - `setOracleAddress(address _newOracle)`: An initial owner function, intended to be controlled by governance later, to update the address of the trusted oracle.

VI. Staking, Curation & Dispute Resolution
    - `Challenge` struct: Defines a dispute submitted against an IP.
    - `ChallengeState` enum: Tracks the status of a challenge (e.g., Active, ResolvedValid, ResolvedInvalid).
    - `stakeForCuratorialRights(uint256 _amount)`: Allows users to stake AetherForge's native token (simulated, or a placeholder ERC20) to gain curatorial power (voting rights, dispute resolution participation).
    - `unstakeCuratorialRights()`: Allows a staker to withdraw their staked tokens after a cool-down period.
    - `challengeIPRegistration(uint256 _ipId, string memory _reason)`: Initiates a formal dispute against an IP's registration (e.g., for plagiarism or misrepresentation), requiring a stake.
    - `resolveChallenge(uint256 _challengeId, bool _isValid)`: A function callable by elected curators or governance to decide the outcome of a dispute, affecting stakes.

VII. Advanced Utilities & Monetization Models
    - `TimedAccessGrant` struct: Represents temporary access granted to an IP.
    - `IPSubscription` struct: Defines an IP owner's subscription offer.
    - `UserSubscription` struct: Tracks a user's active subscription to an IP.
    - `grantTimedAccess(uint256 _ipId, address _recipient, uint256 _duration)`: Allows an IP owner to grant temporary, non-transferable access to their IP to a specific address without full licensing.
    - `setupSubscriptionAccess(uint256 _ipId, uint256 _monthlyFee, uint256 _minMonths)`: Enables an IP owner to configure a recurring subscription model for their IP.
    - `subscribeToIP(uint256 _ipId, uint256 _numMonths)`: Allows a user to subscribe to an IP for a specified number of months.
    - `claimSubscriptionEarnings(uint256 _ipId)`: Allows the IP owner to claim accumulated earnings from active subscriptions to their IP.
    - `hasTimedAccess(uint256 _ipId, address _user)`: Checks if a user has active timed access to a specific IP.
*/

contract AetherForge is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables & Counters ---
    Counters.Counter private _ipIdCounter;
    Counters.Counter private _licenseOfferIdCounter;
    Counters.Counter private _licenseIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Data Structures ---

    enum LicenseType {
        Commercial,
        NonCommercial,
        LimitedUse,
        Educational
    }

    struct IPData {
        address creator;
        string ipfsHash;
        string metadataURI;
        uint256 uniquenessScore; // Set by oracle, 0-100, 0 = not set
        uint256 currentPrice; // For direct sale of original IP, in wei
        bool isAvailable; // Whether IP is generally available for licensing/sale
        // Note: _ownerOf[ipId] is managed by ERC721
    }
    mapping(uint256 => IPData) public ipData;

    struct LicenseOffer {
        uint256 ipId;
        LicenseType licenseType;
        uint256 fee; // in wei
        uint256 duration; // in seconds
        bytes32 termsHash; // Hash of legal terms off-chain
        bool isActive;
    }
    mapping(uint256 => LicenseOffer) public licenseOffers;

    struct License {
        uint256 ipId;
        address licensee;
        uint256 offerId;
        uint256 startTime;
        uint256 endTime;
        mapping(address => uint256) royaltyShareRecipients; // recipient address => percentage (out of 100) for sub-licensing
    }
    mapping(uint256 => License) public licenses;

    struct DerivativeLink {
        uint256 parentIpId;
        uint256 parentSharePercentage; // Percentage of revenue from derivative that goes to parent
    }
    mapping(uint256 => DerivativeLink) public derivativeLinks; // derivativeIpId => DerivativeLink
    mapping(uint256 => uint256[]) public parentToDerivatives; // parentIpId => list of derivativeIpIds

    enum ChallengeState {
        Active,
        ResolvedValid,
        ResolvedInvalid
    }

    struct Challenge {
        uint256 ipId;
        address challenger;
        string reason;
        uint256 stakeAmount;
        uint256 startTime;
        uint256 resolutionTime;
        ChallengeState state;
        bytes32 oracleQueryId; // For uniqueness score or other evidence requests
    }
    mapping(uint256 => Challenge) public challenges;

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        address proposer;
        bytes32 paramName;
        uint256 newValue;
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks which addresses have voted
    }
    mapping(uint256 => Proposal) public proposals;

    struct TimedAccessGrant {
        uint256 ipId;
        address grantee;
        uint256 expiryTime;
    }
    mapping(uint256 => TimedAccessGrant) public timedAccessGrants;
    mapping(uint256 => uint256) private _ipToTimedAccessGrantId; // Maps IP ID to the ID of its current active timed access grant (simplified: one active grant per IP)

    struct IPSubscription {
        uint256 ipId;
        uint256 monthlyFee; // in wei
        uint256 minMonths;
        bool isActive;
    }
    mapping(uint256 => IPSubscription) public ipSubscriptions;

    struct UserSubscription {
        uint256 ipId;
        uint256 lastPaymentTime; // The last time a payment was made for this subscription
        uint256 monthsPaid; // Total months paid for this subscription
        uint256 expiryTime;
    }
    mapping(address => mapping(uint256 => UserSubscription)) public userSubscriptions; // user => ipId => subscription data

    // --- Configuration Parameters (can be changed by governance) ---
    address public oracleAddress;
    uint256 public minCuratorialStake; // Minimum ETH/token stake for curatorial rights
    uint256 public votingPeriodDuration; // Duration for proposals to be active (seconds)
    uint256 public proposalQuorumPercentage; // Percentage of total votes required to meet quorum (0-100)
    uint256 public challengeStakeMultiplier; // Multiplier for challenge stake relative to IP initial fee/price
    uint256 public curatorialUnstakeCooldown; // Time (seconds) before staked funds can be withdrawn after unstaking request

    // --- Staking Balances ---
    mapping(address => uint256) public stakedCuratorialTokens; // ETH staked for curatorial rights
    mapping(address => uint256) public unstakeCooldownStartTime; // For tracking unstaking cooldown start time

    // Internal mapping to hold accumulated subscription revenue for each IP, for owner to claim
    // In a production system, this would be more sophisticated (e.g., using a pull-payment pattern or detailed accounting).
    mapping(uint256 => uint256) public ipSubscriptionRevenue;

    // --- Events ---
    event IPRegistered(uint256 indexed ipId, address indexed creator, string ipfsHash, string metadataURI);
    event IPMetadataUpdated(uint252 indexed ipId, string newMetadataURI);
    event IPPriceSet(uint256 indexed ipId, uint256 newPrice);
    event IPToggledAvailability(uint256 indexed ipId, bool isAvailable);
    event IPBurned(uint256 indexed ipId);

    event LicenseOfferCreated(uint256 indexed offerId, uint256 indexed ipId, LicenseType licenseType, uint256 fee, uint256 duration);
    event LicensePurchased(uint256 indexed licenseId, uint256 indexed ipId, address indexed licensee, uint256 feePaid);
    event RoyaltiesDistributed(uint256 indexed ipId, uint256 amount);
    event LicenseShareRecipientSet(uint256 indexed licenseId, address indexed recipient, uint252 percentage);
    event LicenseDurationExtended(uint256 indexed licenseId, uint256 newEndTime);

    event DerivativeRegistered(uint256 indexed derivativeIpId, uint256 indexed parentIpId, address indexed creator, uint256 parentSharePercentage);
    event DerivativeShareUpdated(uint256 indexed derivativeIpId, uint256 newParentSharePercentage);

    event UniquenessScoreRequested(uint256 indexed ipId, bytes32 indexed queryId);
    event UniquenessScoreFulfilled(uint256 indexed ipId, uint256 score);
    event LicenseSuggestionRequested(uint256 indexed ipId, bytes32 indexed queryId);
    event LicenseSuggestionFulfilled(uint256 indexed ipId, uint256 suggestedFee, uint256 suggestedDuration, bytes32 suggestedTermsHash);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 paramName, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OracleAddressSet(address indexed oldAddress, address indexed newAddress);

    event CuratorialStakeChanged(address indexed staker, uint256 newStakeAmount);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed ipId, address indexed challenger, uint256 stakeAmount);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeState state, address indexed resolver);

    event TimedAccessGranted(uint256 indexed ipId, address indexed grantee, uint256 expiryTime);
    event SubscriptionSetup(uint256 indexed ipId, uint256 monthlyFee, uint256 minMonths);
    event IPSubscribed(uint256 indexed ipId, address indexed subscriber, uint256 numMonths, uint256 totalCost);
    event SubscriptionEarningsClaimed(uint256 indexed ipId, address indexed owner, uint256 amount);

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert AetherForge__OnlyOracle();
        }
        _;
    }

    modifier onlyCurator() {
        if (stakedCuratorialTokens[msg.sender] < minCuratorialStake) {
            revert AetherForge__NotEnoughStakedForCurator();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _initialOracle,
        uint256 _minCuratorialStake,
        uint256 _votingPeriodDuration,
        uint256 _proposalQuorumPercentage,
        uint256 _challengeStakeMultiplier,
        uint256 _curatorialUnstakeCooldown
    ) ERC721("AetherForge IP", "AIP") Ownable(msg.sender) {
        oracleAddress = _initialOracle;
        minCuratorialStake = _minCuratorialStake;
        votingPeriodDuration = _votingPeriodDuration;
        proposalQuorumPercentage = _proposalQuorumPercentage;
        challengeStakeMultiplier = _challengeStakeMultiplier;
        curatorialUnstakeCooldown = _curatorialUnstakeCooldown;
    }

    // --- Fallback & Receive Functions ---
    receive() external payable {}

    fallback() external payable {}

    // --- I. Core IP Management & NFT Functions ---

    function registerOriginalIP(
        string memory _ipfsHash,
        string memory _metadataURI,
        uint256 _initialLicensingFee
    ) public nonReentrant returns (uint256) {
        _ipIdCounter.increment();
        uint256 newIpId = _ipIdCounter.current();

        _mint(msg.sender, newIpId);

        ipData[newIpId] = IPData({
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            metadataURI: _metadataURI,
            uniquenessScore: 0, // Will be set by oracle later
            currentPrice: _initialLicensingFee,
            isAvailable: true
        });

        emit IPRegistered(newIpId, msg.sender, _ipfsHash, _metadataURI);
        return newIpId;
    }

    function updateIPMetadata(uint256 _ipId, string memory _newMetadataURI) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        ipData[_ipId].metadataURI = _newMetadataURI;
        emit IPMetadataUpdated(_ipId, _newMetadataURI);
    }

    // transferIPOwnership is handled by ERC721's safeTransferFrom / transferFrom.
    // Overriding _transfer to add custom logic is possible, but for this example, ERC721's default behavior is sufficient.

    function setIPPrice(uint256 _ipId, uint256 _newPrice) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        ipData[_ipId].currentPrice = _newPrice;
        emit IPPriceSet(_ipId, _newPrice);
    }

    function toggleIPAvailability(uint256 _ipId, bool _isAvailable) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        ipData[_ipId].isAvailable = _isAvailable;
        emit IPToggledAvailability(_ipId, _isAvailable);
    }

    function burnIP(uint256 _ipId) public nonReentrant {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        _burn(_ipId);
        // Additional cleanup for associated data could be added here if necessary,
        // e.g., deleting license offers or subscription setups related to the IP.
        // For simplicity, we assume checks on `exists(_ipId)` are sufficient for most operations.
        emit IPBurned(_ipId);
    }

    // --- II. Licensing & Royalties ---

    function createLicenseOffer(
        uint256 _ipId,
        LicenseType _licenseType,
        uint256 _fee,
        uint256 _duration,
        bytes32 _termsHash
    ) public returns (uint256) {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (!ipData[_ipId].isAvailable) revert AetherForge__IPNotAvailable();
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId(); // Ensure IP exists

        _licenseOfferIdCounter.increment();
        uint256 newOfferId = _licenseOfferIdCounter.current();

        licenseOffers[newOfferId] = LicenseOffer({
            ipId: _ipId,
            licenseType: _licenseType,
            fee: _fee,
            duration: _duration,
            termsHash: _termsHash,
            isActive: true
        });

        emit LicenseOfferCreated(newOfferId, _ipId, _licenseType, _fee, _duration);
        return newOfferId;
    }

    function purchaseLicense(uint256 _licenseOfferId, address _recipient) public payable nonReentrant returns (uint256) {
        LicenseOffer storage offer = licenseOffers[_licenseOfferId];
        if (!offer.isActive) revert AetherForge__InvalidLicenseOffer();
        if (msg.value < offer.fee) revert AetherForge__InsufficientFunds();

        // Ensure IP is available and exists
        if (!ERC721.exists(offer.ipId) || !ipData[offer.ipId].isAvailable) {
            revert AetherForge__IPNotAvailable();
        }

        uint256 remainingFee = offer.fee;
        
        // Distribute royalties up the derivative chain
        uint256 currentIpInChain = offer.ipId;
        // Collect all parent IP owners and their shares.
        // This is a simplified approach, a more robust system might use a share registry.
        address[] memory payees = new address[](10); // Max 10 levels of derivatives for this example
        uint256[] memory shares = new uint256[](10);
        uint256 payeeCount = 0;

        // Traverse up the derivative chain, calculating royalties for each parent
        // Note: derivativeLinks[0] implies no parent.
        while (currentIpInChain != 0 && derivativeLinks[currentIpInChain].parentIpId != 0 && ERC721.exists(currentIpInChain)) {
            uint256 parentIpId = derivativeLinks[currentIpInChain].parentIpId;
            uint256 parentSharePercentage = derivativeLinks[currentIpInChain].parentSharePercentage;

            if (parentSharePercentage > 0 && ERC721.exists(parentIpId)) {
                uint256 royalty = (offer.fee * parentSharePercentage) / 100;
                payees[payeeCount] = ownerOf(parentIpId);
                shares[payeeCount] = royalty;
                remainingFee -= royalty;
                payeeCount++;
            }
            currentIpInChain = parentIpId;
        }

        // Add the direct IP owner's share (the one who created the offer)
        if (ERC721.exists(offer.ipId)) {
            payees[payeeCount] = ownerOf(offer.ipId);
            shares[payeeCount] = remainingFee;
            payeeCount++;
        }

        // Distribute collected funds
        for (uint256 i = 0; i < payeeCount; i++) {
            if (shares[i] > 0) {
                payable(payees[i]).transfer(shares[i]);
            }
        }
        
        // Refund any excess payment
        if (msg.value > offer.fee) {
            payable(msg.sender).transfer(msg.value - offer.fee);
        }

        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();
        uint256 expiryTime = block.timestamp + offer.duration;

        licenses[newLicenseId] = License({
            ipId: offer.ipId,
            licensee: _recipient,
            offerId: _licenseOfferId,
            startTime: block.timestamp,
            endTime: expiryTime
        });

        emit LicensePurchased(newLicenseId, offer.ipId, _recipient, msg.value);
        return newLicenseId;
    }

    function distributeRoyalties(uint256 _ipId, uint256 _amount) public nonReentrant {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (_amount == 0) return;
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        // This function is for creator to "push" earnings from off-chain activities
        // or for an oracle to report earnings and trigger distribution.

        uint256 remainingAmount = _amount;
        
        address[] memory payees = new address[](10); 
        uint256[] memory shares = new uint256[](10);
        uint256 payeeCount = 0;

        uint256 currentIpInChain = _ipId;

        // Traverse up the derivative chain to find all parent IPs and their owners
        while (currentIpInChain != 0 && derivativeLinks[currentIpInChain].parentIpId != 0 && ERC721.exists(currentIpInChain)) {
            uint256 parentIpId = derivativeLinks[currentIpInChain].parentIpId;
            uint256 parentSharePercentage = derivativeLinks[currentIpInChain].parentSharePercentage;

            if (parentSharePercentage > 0 && ERC721.exists(parentIpId)) {
                uint256 royalty = (_amount * parentSharePercentage) / 100;
                payees[payeeCount] = ownerOf(parentIpId); 
                shares[payeeCount] = royalty;
                remainingAmount -= royalty;
                payeeCount++;
            }
            currentIpInChain = parentIpId;
        }

        // Add the current IP owner's share
        if (ERC721.exists(_ipId)) {
            payees[payeeCount] = ownerOf(_ipId);
            shares[payeeCount] = remainingAmount;
            payeeCount++;
        }

        // Distribute funds
        for (uint256 i = 0; i < payeeCount; i++) {
            if (shares[i] > 0) {
                payable(payees[i]).transfer(shares[i]);
            }
        }

        emit RoyaltiesDistributed(_ipId, _amount);
    }

    function setLicenseShareRecipient(
        uint256 _licenseId,
        address _recipient,
        uint256 _percentage
    ) public {
        License storage lic = licenses[_licenseId];
        if (lic.licensee != msg.sender) revert AetherForge__NotLicensee();
        if (_percentage > 100) revert AetherForge__InvalidSharePercentage();
        if (block.timestamp >= lic.endTime) revert AetherForge__LicenseNotActive(); // Only set for active licenses

        lic.royaltyShareRecipients[_recipient] = _percentage;
        emit LicenseShareRecipientSet(_licenseId, _recipient, _percentage);
    }

    function extendLicenseDuration(uint256 _licenseId, uint256 _additionalDuration) public payable nonReentrant {
        License storage lic = licenses[_licenseId];
        if (lic.licensee != msg.sender) revert AetherForge__NotLicensee();
        if (block.timestamp >= lic.endTime) revert AetherForge__LicenseNotActive(); // Can only extend active licenses

        LicenseOffer storage offer = licenseOffers[lic.offerId];
        if (!offer.isActive) revert AetherForge__InvalidLicenseOffer(); // Ensure original offer is still valid

        uint256 extensionCost = (offer.fee * _additionalDuration) / offer.duration; // Prorated cost
        if (msg.value < extensionCost) revert AetherForge__InsufficientFunds();

        uint256 remainingCost = extensionCost;

        address[] memory payees = new address[](10); 
        uint256[] memory shares = new uint256[](10);
        uint256 payeeCount = 0;

        // Traverse up the derivative chain to distribute prorated extension cost
        uint256 currentIpInChain = offer.ipId;
        while (currentIpInChain != 0 && derivativeLinks[currentIpInChain].parentIpId != 0 && ERC721.exists(currentIpInChain)) {
            uint256 parentIpId = derivativeLinks[currentIpInChain].parentIpId;
            uint256 parentSharePercentage = derivativeLinks[currentIpInChain].parentSharePercentage;

            if (parentSharePercentage > 0 && ERC721.exists(parentIpId)) {
                uint256 royalty = (extensionCost * parentSharePercentage) / 100;
                payees[payeeCount] = ownerOf(parentIpId);
                shares[payeeCount] = royalty;
                remainingCost -= royalty;
                payeeCount++;
            }
            currentIpInChain = parentIpId;
        }

        // Add the direct IP owner's share
        if (ERC721.exists(offer.ipId)) {
            payees[payeeCount] = ownerOf(offer.ipId);
            shares[payeeCount] = remainingCost;
            payeeCount++;
        }

        // Distribute funds
        for (uint256 i = 0; i < payeeCount; i++) {
            if (shares[i] > 0) {
                payable(payees[i]).transfer(shares[i]);
            }
        }

        // Refund any excess payment
        if (msg.value > extensionCost) {
            payable(msg.sender).transfer(msg.value - extensionCost);
        }

        lic.endTime += _additionalDuration;
        emit LicenseDurationExtended(_licenseId, lic.endTime);
    }

    // --- III. Derivative Works & Provenance ---

    function registerDerivativeWork(
        uint256 _parentIpId,
        string memory _derivativeIpfsHash,
        string memory _derivativeMetadataURI,
        uint256 _parentSharePercentage
    ) public nonReentrant returns (uint256) {
        if (!ERC721.exists(_parentIpId)) revert AetherForge__InvalidIPId();
        if (ownerOf(_parentIpId) == msg.sender) revert AetherForge__SelfDerivativeNotAllowed(); // Prevent creator of parent from registering their own derivative

        // Check if caller has a valid license to create a derivative
        bool hasDerivativeLicense = false;
        for (uint256 i = 1; i <= _licenseIdCounter.current(); i++) {
            License storage lic = licenses[i];
            if (lic.ipId == _parentIpId && lic.licensee == msg.sender && block.timestamp < lic.endTime) {
                // Here, one could add logic to check `lic.licenseType` or specific derivative rights in `lic.termsHash`
                // For simplicity, any active license allows derivative registration.
                hasDerivativeLicense = true;
                break;
            }
        }
        if (!hasDerivativeLicense) {
            revert AetherForge__NotLicensee();
        }

        if (_parentSharePercentage > 100) revert AetherForge__InvalidParentShare();

        _ipIdCounter.increment();
        uint256 newDerivativeIpId = _ipIdCounter.current();

        _mint(msg.sender, newDerivativeIpId); // Mints the derivative NFT to the caller

        ipData[newDerivativeIpId] = IPData({
            creator: msg.sender,
            ipfsHash: _derivativeIpfsHash,
            metadataURI: _derivativeMetadataURI,
            uniquenessScore: 0,
            currentPrice: 0, // Derivatives typically have their own monetization, not a direct sale from this contract
            isAvailable: true
        });

        derivativeLinks[newDerivativeIpId] = DerivativeLink({
            parentIpId: _parentIpId,
            parentSharePercentage: _parentSharePercentage
        });
        parentToDerivatives[_parentIpId].push(newDerivativeIpId);

        emit DerivativeRegistered(newDerivativeIpId, _parentIpId, msg.sender, _parentSharePercentage);
        return newDerivativeIpId;
    }

    function updateDerivativeShare(uint256 _derivativeIpId, uint256 _newParentSharePercentage) public {
        if (ownerOf(_derivativeIpId) != msg.sender) revert AetherForge__NotIPOwner();
        if (derivativeLinks[_derivativeIpId].parentIpId == 0) revert AetherForge__InvalidIPId(); // Not a registered derivative
        if (!ERC721.exists(_derivativeIpId)) revert AetherForge__InvalidIPId();
        if (_newParentSharePercentage > 100) revert AetherForge__InvalidParentShare();

        derivativeLinks[_derivativeIpId].parentSharePercentage = _newParentSharePercentage;
        emit DerivativeShareUpdated(_derivativeIpId, _newParentSharePercentage);
    }

    function getDerivativeTree(uint256 _ipId) public view returns (uint256[] memory) {
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();
        return parentToDerivatives[_ipId];
    }

    // --- IV. AI-Assisted Features (Oracle-based Simulation) ---

    function requestUniquenessScore(uint256 _ipId) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (oracleAddress == address(0)) revert AetherForge__OracleCallbackFailed(); // Oracle not set
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        // In a real scenario, this would pass content identifier (ipfsHash) to oracle
        // Here, we just use ipId and simulate, assuming the oracle knows how to fetch the content.
        string memory callbackFunc = "fulfillUniquenessScore";
        bytes memory data = abi.encodePacked(_ipId); // Pass IP ID for the oracle to process
        bytes32 queryId = IOracle(oracleAddress).requestData(bytes32(0), callbackFunc, data); // bytes32(0) for a mock queryId

        emit UniquenessScoreRequested(_ipId, queryId);
    }

    function fulfillUniquenessScore(uint256 _ipId, uint256 _score, bytes32 _queryId) public onlyOracle {
        // _queryId would be used to verify the response against the original request in a real system.
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        ipData[_ipId].uniquenessScore = _score;
        emit UniquenessScoreFulfilled(_ipId, _score);
    }

    function requestAutomatedLicenseSuggestion(uint256 _ipId, string memory _intendedUseDescription) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (oracleAddress == address(0)) revert AetherForge__OracleCallbackFailed();
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        // Pass IP details and intended use description to oracle for AI analysis
        string memory callbackFunc = "fulfillLicenseSuggestion";
        bytes memory data = abi.encodePacked(_ipId, _intendedUseDescription, ipData[_ipId].ipfsHash);
        bytes32 queryId = IOracle(oracleAddress).requestData(bytes32(0), callbackFunc, data);

        emit LicenseSuggestionRequested(_ipId, queryId);
    }

    function fulfillLicenseSuggestion(
        uint256 _ipId,
        uint256 _suggestedFee,
        uint256 _suggestedDuration,
        bytes32 _suggestedTermsHash,
        bytes32 _queryId
    ) public onlyOracle {
        // Here, a new LicenseOffer could be automatically created based on AI suggestion,
        // or just store the suggestion for the owner to review.
        // For simplicity, we just emit an event. Owner still needs to call createLicenseOffer.
        if (_ipId == 0 || _ipId > _ipIdCounter.current() || !ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        emit LicenseSuggestionFulfilled(_ipId, _suggestedFee, _suggestedDuration, _suggestedTermsHash);
    }

    // --- V. Governance & Treasury (DAO-Lite) ---

    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) public onlyCurator {
        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(newProposalId, msg.sender, _paramName, _newValue);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyCurator {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert AetherForge__ProposalNotActive();
        if (block.timestamp >= proposal.votingPeriodEnd) revert AetherForge__VotingPeriodNotEnded();
        if (proposal.hasVoted[msg.sender]) revert AetherForge__AlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += stakedCuratorialTokens[msg.sender];
        } else {
            proposal.votesAgainst += stakedCuratorialTokens[msg.sender];
        }

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert AetherForge__InvalidProposalId();
        if (block.timestamp < proposal.votingPeriodEnd) revert AetherForge__VotingPeriodNotEnded();
        if (proposal.state == ProposalState.Executed) revert AetherForge__ProposalAlreadyExecuted();

        // For simplicity, `totalCuratorialStake` would need to be a globally tracked variable,
        // or derived from summing `stakedCuratorialTokens` which is computationally expensive.
        // For this example, we'll use a hardcoded value for the quorum check.
        // A more robust DAO would use a governance token's total staked supply.
        uint256 totalVotesInProposal = proposal.votesFor + proposal.votesAgainst;
        uint256 dummyTotalStakedSupply = 100_000 ether; // A large number representing total theoretical stake
        uint256 requiredVotesForQuorum = (dummyTotalStakedSupply * proposalQuorumPercentage) / 100;

        if (totalVotesInProposal < requiredVotesForQuorum || (proposal.votesFor * 100) / totalVotesInProposal < 50) {
            proposal.state = ProposalState.Failed;
            revert AetherForge__ProposalNotPassed();
        }

        // Apply parameter change based on _paramName
        if (proposal.paramName == "minCuratorialStake") {
            minCuratorialStake = proposal.newValue;
        } else if (proposal.paramName == "votingPeriodDuration") {
            votingPeriodDuration = proposal.newValue;
        } else if (proposal.paramName == "proposalQuorumPercentage") {
            if (proposal.newValue > 100) revert AetherForge__InvalidProposalId(); 
            proposalQuorumPercentage = proposal.newValue;
        } else if (proposal.paramName == "challengeStakeMultiplier") {
            challengeStakeMultiplier = proposal.newValue;
        } else if (proposal.paramName == "curatorialUnstakeCooldown") {
            curatorialUnstakeCooldown = proposal.newValue;
        } else {
            // Revert for unknown parameter or implement complex actions via ABI encoding/decoding.
            revert AetherForge__InvalidProposalId();
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    function setOracleAddress(address _newOracle) public onlyOwner {
        // This function would ideally be controlled by governance after initial setup in a decentralized system.
        // For simplicity, it's owned by deployer for initial setup.
        address oldOracle = oracleAddress;
        oracleAddress = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    // --- VI. Staking, Curation & Dispute Resolution ---

    function stakeForCuratorialRights(uint256 _amount) public payable nonReentrant {
        if (msg.value < _amount) revert AetherForge__InsufficientFunds();

        stakedCuratorialTokens[msg.sender] += _amount;
        emit CuratorialStakeChanged(msg.sender, stakedCuratorialTokens[msg.sender]);
    }

    function unstakeCuratorialRights() public nonReentrant {
        uint256 amount = stakedCuratorialTokens[msg.sender];
        if (amount == 0) revert AetherForge__InsufficientStake();

        // Simple check for any active challenge where msg.sender is challenger
        // A more robust system would check if they are involved in any ongoing challenge as a juror/challenger
        for (uint256 i = 1; i <= _challengeIdCounter.current(); i++) {
            Challenge storage c = challenges[i];
            if (c.challenger == msg.sender && c.state == ChallengeState.Active) {
                revert AetherForge__CannotUnstakeWhileChallenging();
            }
        }

        if (unstakeCooldownStartTime[msg.sender] == 0) {
            unstakeCooldownStartTime[msg.sender] = block.timestamp;
            revert AetherForge__CannotUnstakeWhileChallenging(); // Needs to wait for cooldown
        } else if (block.timestamp < unstakeCooldownStartTime[msg.sender] + curatorialUnstakeCooldown) {
            revert AetherForge__CannotUnstakeWhileChallenging();
        }

        stakedCuratorialTokens[msg.sender] = 0; // Unstake all
        unstakeCooldownStartTime[msg.sender] = 0; // Reset cooldown

        payable(msg.sender).transfer(amount);
        emit CuratorialStakeChanged(msg.sender, 0);
    }

    function challengeIPRegistration(uint256 _ipId, string memory _reason) public payable nonReentrant returns (uint256) {
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();
        // Prevent challenging own IP
        if (ownerOf(_ipId) == msg.sender) revert AetherForge__InvalidIPId(); 

        // Check if an active challenge already exists for this IP
        for (uint256 i = 1; i <= _challengeIdCounter.current(); i++) {
            if (challenges[i].ipId == _ipId && challenges[i].state == ChallengeState.Active) {
                revert AetherForge__ChallengeAlreadyExists();
            }
        }

        uint256 requiredStake = ipData[_ipId].currentPrice > 0 ? ipData[_ipId].currentPrice * challengeStakeMultiplier : 1 ether; // Minimum 1 ETH if no price set
        if (msg.value < requiredStake) revert AetherForge__InsufficientFunds();

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        challenges[newChallengeId] = Challenge({
            ipId: _ipId,
            challenger: msg.sender,
            reason: _reason,
            stakeAmount: msg.value,
            startTime: block.timestamp,
            resolutionTime: 0,
            state: ChallengeState.Active,
            oracleQueryId: bytes32(0) 
        });

        emit ChallengeInitiated(newChallengeId, _ipId, msg.sender, msg.value);
        return newChallengeId;
    }

    function resolveChallenge(uint256 _challengeId, bool _isValid) public onlyCurator nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        if (_challengeId == 0 || _challengeId > _challengeIdCounter.current()) revert AetherForge__ChallengeNotFound();
        if (challenge.state != ChallengeState.Active) revert AetherForge__ChallengeNotResolved(); // Already resolved or not active

        challenge.state = _isValid ? ChallengeState.ResolvedValid : ChallengeState.ResolvedInvalid;
        challenge.resolutionTime = block.timestamp;

        // Distribute stake based on resolution
        if (_isValid) {
            // Challenger wins: stake returned to challenger
            payable(challenge.challenger).transfer(challenge.stakeAmount);
            // In a real system, the IP owner might be penalized here.
        } else {
            // Challenger loses: stake is retained by the contract (e.g., to be distributed to successful curators or treasury)
            // For this example, it stays in the contract as part of its balance.
        }

        emit ChallengeResolved(_challengeId, challenge.state, msg.sender);
    }

    // --- VII. Advanced Utilities & Monetization Models ---

    function grantTimedAccess(uint256 _ipId, address _recipient, uint256 _duration) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        uint256 expiryTime = block.timestamp + _duration;
        // This simple implementation allows only one active timed access grant per IP.
        // Overwrites previous if any. For multiple, a mapping from IP ID to a list/counter would be needed.
        uint256 grantId = _ipId; // Using IP ID as grant ID for simplicity
        timedAccessGrants[grantId] = TimedAccessGrant({
            ipId: _ipId,
            grantee: _recipient,
            expiryTime: expiryTime
        });
        _ipToTimedAccessGrantId[_ipId] = grantId; // Link IP to its grant

        emit TimedAccessGranted(_ipId, _recipient, expiryTime);
    }

    function setupSubscriptionAccess(
        uint256 _ipId,
        uint256 _monthlyFee,
        uint256 _minMonths
    ) public {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (!ERC721.exists(_ipId) || !ipData[_ipId].isAvailable) revert AetherForge__IPNotAvailable();
        if (_monthlyFee == 0 || _minMonths == 0) revert AetherForge__NotEnoughMonths(); // Using existing error

        ipSubscriptions[_ipId] = IPSubscription({
            ipId: _ipId,
            monthlyFee: _monthlyFee,
            minMonths: _minMonths,
            isActive: true
        });

        emit SubscriptionSetup(_ipId, _monthlyFee, _minMonths);
    }

    function subscribeToIP(uint256 _ipId, uint256 _numMonths) public payable nonReentrant {
        IPSubscription storage subOffer = ipSubscriptions[_ipId];
        if (!subOffer.isActive) revert AetherForge__InvalidIPId(); // IP not set up for subscription
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();
        if (_numMonths < subOffer.minMonths) revert AetherForge__NotEnoughMonths();
        if (ownerOf(_ipId) == msg.sender) revert AetherForge__CreatorCannotSubscribeToOwnIP();

        uint256 totalCost = subOffer.monthlyFee * _numMonths;
        if (msg.value < totalCost) revert AetherForge__InsufficientFunds();

        UserSubscription storage userSub = userSubscriptions[msg.sender][_ipId];
        uint256 newExpiryTime;

        if (userSub.expiryTime > block.timestamp) { // Extend existing subscription
            newExpiryTime = userSub.expiryTime + (_numMonths * 30 days); // Approx. 30 days per month
            userSub.monthsPaid += _numMonths;
        } else { // New subscription
            userSub.ipId = _ipId;
            userSub.lastPaymentTime = block.timestamp;
            userSub.monthsPaid = _numMonths;
            newExpiryTime = block.timestamp + (_numMonths * 30 days);
        }
        userSub.expiryTime = newExpiryTime;

        // Distribute payment to IP owner and parents in derivative chain
        uint256 remainingEarnings = totalCost;
        uint256 currentIpInChain = _ipId;

        address[] memory payees = new address[](10);
        uint256[] memory shares = new uint256[](10);
        uint256 payeeCount = 0;

        while (currentIpInChain != 0 && derivativeLinks[currentIpInChain].parentIpId != 0 && ERC721.exists(currentIpInChain)) {
            uint256 parentIpId = derivativeLinks[currentIpInChain].parentIpId;
            uint256 parentSharePercentage = derivativeLinks[currentIpInChain].parentSharePercentage;

            if (parentSharePercentage > 0 && ERC721.exists(parentIpId)) {
                uint256 royalty = (totalCost * parentSharePercentage) / 100;
                payees[payeeCount] = ownerOf(parentIpId);
                shares[payeeCount] = royalty;
                remainingEarnings -= royalty;
                payeeCount++;
            }
            currentIpInChain = parentIpId;
        }

        // Add the current IP owner's share
        if (ERC721.exists(_ipId)) {
            payees[payeeCount] = ownerOf(_ipId);
            shares[payeeCount] = remainingEarnings;
            payeeCount++;
        }

        // Transfer collected funds for this IP
        for (uint256 i = 0; i < payeeCount; i++) {
            if (shares[i] > 0) {
                // Instead of direct transfer, add to ipSubscriptionRevenue for later claim
                ipSubscriptionRevenue[_ipId] += shares[i];
            }
        }
        
        // Refund any excess payment to the subscriber
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit IPSubscribed(_ipId, msg.sender, _numMonths, totalCost);
    }

    function claimSubscriptionEarnings(uint256 _ipId) public nonReentrant {
        if (ownerOf(_ipId) != msg.sender) revert AetherForge__NotIPOwner();
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();

        uint256 earnings = ipSubscriptionRevenue[_ipId];
        if (earnings == 0) revert AetherForge__NoEarningsToClaim();

        ipSubscriptionRevenue[_ipId] = 0; // Reset claimed amount

        payable(msg.sender).transfer(earnings);
        emit SubscriptionEarningsClaimed(_ipId, msg.sender, earnings);
    }

    function hasTimedAccess(uint256 _ipId, address _user) public view returns (bool) {
        if (!ERC721.exists(_ipId)) return false;
        uint256 grantId = _ipToTimedAccessGrantId[_ipId];
        TimedAccessGrant storage grant = timedAccessGrants[grantId];
        return (grant.grantee == _user && block.timestamp < grant.expiryTime);
    }

    // --- External view functions (for querying data) ---
    function getIpData(uint256 _ipId) public view returns (IPData memory) {
        if (!ERC721.exists(_ipId)) revert AetherForge__InvalidIPId();
        return ipData[_ipId];
    }

    function getLicenseOffer(uint256 _offerId) public view returns (LicenseOffer memory) {
        // No existence check needed here, returns default if not found
        return licenseOffers[_offerId];
    }

    function getLicense(uint256 _licenseId) public view returns (License memory) {
        // No existence check needed here
        return licenses[_licenseId];
    }

    function getDerivativeLink(uint256 _derivativeIpId) public view returns (DerivativeLink memory) {
        // No existence check needed here
        return derivativeLinks[_derivativeIpId];
    }

    function getChallenge(uint256 _challengeId) public view returns (Challenge memory) {
        // No existence check needed here
        return challenges[_challengeId];
    }

    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        // No existence check needed here
        return proposals[_proposalId];
    }

    function getIPSubscriptionOffer(uint256 _ipId) public view returns (IPSubscription memory) {
        // No existence check needed here
        return ipSubscriptions[_ipId];
    }

    function getUserIPSubscription(address _user, uint256 _ipId) public view returns (UserSubscription memory) {
        // No existence check needed here
        return userSubscriptions[_user][_ipId];
    }

    // Total supply of NFTs (IPs)
    function totalIPs() public view returns (uint256) {
        return _ipIdCounter.current();
    }
}
```