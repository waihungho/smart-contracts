This smart contract, named `EvolveArtGenesis`, is designed as a decentralized platform for the creation, evolution, and licensing of unique digital intellectual property (IP) assets, represented as NFTs. It integrates several advanced and trendy concepts:

1.  **Dynamic NFTs**: Art Seed NFTs can "evolve" by updating their underlying DNA hash and metadata URI through a community-governed process.
2.  **AI-Assisted Curation**: Registered "AI Agents" (or delegated users) can propose evolutions for Art Seeds.
3.  **Decentralized Governance (DAO-like)**: Staked curators vote on proposed evolutions and can also propose and vote on changes to the contract's core parameters (self-amending governance).
4.  **Usage-Based Licensing & Advanced Royalties**: IP owners can set licensing terms, and licensees can record usage and pay royalties dynamically, with splits for the genesis creator and evolvers.
5.  **Staking for Influence**: Users stake a dedicated `CurationToken` to gain voting power, incentivizing active participation in the platform's evolution.

---

### Contract Outline & Function Summary

**I. Core IP & NFT Management (ERC721 Adapted)**
1.  **`mintArtSeed(bytes32 _initialDNAHash, string calldata _initialMetadataURI)`**: Mints a new "Art Seed" NFT, representing the genesis of an IP. Stores an initial DNA hash (for off-chain verification) and a metadata URI.
2.  **`getArtSeedDNAHash(uint256 tokenId)`**: Returns the current cryptographic hash of the Art Seed's DNA, reflecting its accumulated evolutions.
3.  **`getArtSeedMetadataURI(uint256 tokenId)`**: Returns the URI for the current metadata JSON of an Art Seed, which dynamically updates upon successful evolutions.
4.  **`delegateEvolutionRights(uint256 tokenId, address delegatee, uint256 duration)`**: Allows an Art Seed owner to grant temporary evolution proposal rights for their IP to another address (e.g., an AI agent).
5.  **`revokeEvolutionRights(uint256 tokenId)`**: Revokes any active evolution delegation for a specific Art Seed before its expiry.

**II. AI Agent & Evolution Mechanics**
6.  **`registerAIAgent(string calldata _agentName, string calldata _agentMetadataURI)`**: Registers an address as an "AI Agent" with a unique name and metadata (e.g., describing its algorithmic capabilities).
7.  **`submitEvolutionProposal(uint256 _targetTokenId, bytes32 _proposedDNAHash, string calldata _proposedMetadataURI)`**: An registered AI Agent or a delegated address proposes an evolution (new DNA hash, new metadata URI) for a specific Art Seed. Requires a `MIN_PROPOSAL_STAKE` in `CurationToken`.
8.  **`voteOnEvolutionProposal(uint256 _proposalId, bool _approve)`**: Staked curators vote on submitted evolution proposals. Their voting power is proportional to their `CurationToken` stake.
9.  **`executeEvolutionProposal(uint256 _proposalId)`**: If an evolution proposal passes the voting threshold, this function applies the proposed changes to the Art Seed's DNA hash and metadata. It manages the proposer's stake (refund on success, held on failure).
10. **`getEvolutionProposalDetails(uint256 _proposalId)`**: Retrieves detailed information about a specific evolution proposal, including votes, status, and proposed changes.

**III. Decentralized Licensing & Revenue Sharing**
11. **`setLicensingTerms(uint256 _tokenId, uint256 _baseFee, uint256 _royaltyShareGenesisCreatorBPS, uint256 _royaltyShareEvolversBPS, uint256 _minDuration, uint256 _maxDuration, bytes32 _licenseAgreementHash)`**: The Art Seed owner sets the general licensing terms, including a base fee, royalty splits (in basis points) for the genesis creator and evolvers, duration constraints, and a hash of the full legal license text.
12. **`requestLicense(uint256 _tokenId, uint256 _duration, address _licensee, bytes32 _agreementHash)`**: A user requests a license to use an Art Seed, specifying duration, agreeing to terms (via hash), and paying the base fee. The request goes into a pending state.
13. **`approveLicenseRequest(uint256 _licenseId)`**: The Art Seed owner approves a pending license request, activating it and allowing the licensee to proceed with usage.
14. **`revokeActiveLicense(uint256 _licenseId)`**: The Art Seed owner can revoke an active license, effectively terminating usage rights.
15. **`recordUsageAndPayRoyalties(uint256 _licenseId, uint256 _usageUnits)`**: A licensee reports usage units (e.g., views, prints) and pays additional, dynamic royalties based on the Art Seed's terms and the reported usage. Royalties are distributed to relevant parties.
16. **`withdrawEarnings()`**: Allows genesis creators, current Art Seed owners, and designated evolvers to withdraw their accumulated royalty shares (in native currency).

**IV. Curation & Governance (Staking & Self-Amending Parameters)**
17. **`stakeCurationTokens(uint256 _amount)`**: Users stake `CurationToken` (an external ERC20) to gain voting power for both evolution and governance proposals.
18. **`unstakeCurationTokens(uint256 _amount)`**: Users unstake a specified amount of their `CurationToken`. These tokens enter an unbonding period before they can be withdrawn.
19. **`withdrawUnstakedTokens()`**: Allows users to withdraw their `CurationTokens` after the `CURATOR_UNBONDING_PERIOD` has passed since their unstake request.
20. **`proposeGovernanceParameterChange(bytes32 _parameterName, uint256 _newValue)`**: A staked curator can propose changing a critical contract parameter (e.g., voting thresholds, unbonding periods).
21. **`voteOnGovernanceParameterChange(uint256 _proposalId, bool _approve)`**: Staked curators vote on proposed governance changes, using their `CurationToken` stake as voting power.
22. **`enactGovernanceParameterChange(uint256 _proposalId)`**: Enacts a governance parameter change after a successful vote and a specified `GOVERNANCE_ENACTMENT_DELAY`.

**V. Query & Utility Functions**
23. **`getAIAgentInfo(address _agentAddress)`**: Retrieves information about a registered AI Agent.
24. **`getArtSeedLicensingTerms(uint256 _tokenId)`**: Returns the current licensing terms configured for an Art Seed.
25. **`getPendingLicenses(uint256 _tokenId)`**: Returns a list of IDs for pending license requests for a given Art Seed, awaiting owner approval.
26. **`getActiveLicenses(uint256 _tokenId)`**: Returns a list of IDs for currently active (approved, not revoked, not expired) licenses associated with an Art Seed.
27. **`getLicenseDetails(uint256 _licenseId)`**: Returns comprehensive details for a specific license, regardless of its status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For Address.isContract() if needed, though direct checks used

// --- Custom Errors ---
error EvolveArtGenesis__ZeroAddress();
error EvolveArtGenesis__ZeroAmount();
error EvolveArtGenesis__InsufficientFunds(uint256 required, uint256 provided);
error EvolveArtGenesis__NoBalanceToWithdraw();
error EvolveArtGenesis__NotAIAgent(address caller);
error EvolveArtGenesis__AgentNotRegistered(address agent);
error EvolveArtGenesis__NotAuthorizedToEvolve(address caller, uint256 tokenId);
error EvolveArtGenesis__TokenDoesNotExist(uint256 tokenId);
error EvolveArtGenesis__EvolutionRightsNotDelegated(uint256 tokenId);

// Evolution Proposal Errors
error EvolveArtGenesis__ProposalNotFound(uint256 proposalId);
error EvolveArtGenesis__AlreadyVoted(address voter, uint256 proposalId);
error EvolveArtGenesis__ProposalExpired(uint256 proposalId);
error EvolveArtGenesis__ProposalNotReadyForExecution(uint256 proposalId);
error EvolveArtGenesis__ProposalAlreadyExecuted(uint256 proposalId);
error EvolveArtGenesis__InsufficientStake(uint256 required, uint256 provided);
error EvolveArtGenesis__ProposalFailedToPass(uint256 proposalId);

// Licensing Errors
error EvolveArtGenesis__InvalidDuration(uint256 min, uint256 max, uint256 provided);
error EvolveArtGenesis__LicenseNotFound(uint256 licenseId);
error EvolveArtGenesis__LicenseNotApproved(uint256 licenseId);
error EvolveArtGenesis__LicenseAlreadyApproved(uint256 licenseId);
error EvolveArtGenesis__LicenseAlreadyRevoked(uint256 licenseId);
error EvolveArtGenesis__LicenseExpired(uint256 licenseId);
error EvolveArtGenesis__NoPendingLicenses();
error EvolveArtGenesis__NoActiveLicenses();
error EvolveArtGenesis__InvalidRoyaltySplit();

// Curation & Governance Errors
error EvolveArtGenesis__AlreadyRegistered(); // Used for AI Agent and also implies already staked for generic cases
error EvolveArtGenesis__InsufficientCurationStake(uint256 required, uint256 provided);
error EvolveArtGenesis__UnbondingPeriodActive(uint256 availableAt);
error EvolveArtGenesis__NoStakeToUnstake();
error EvolveArtGenesis__GovernanceProposalNotFound(uint256 proposalId);
error EvolveArtGenesis__GovernanceProposalExpired(uint256 proposalId);
error EvolveArtGenesis__GovernanceProposalNotReadyForEnactment(uint255 proposalId);
error EvolveArtGenesis__GovernanceProposalAlreadyEnacted(uint256 proposalId);
error EvolveArtGenesis__ParameterNotChangeable(bytes32 parameterName);
error EvolveArtGenesis__ExecutionDelayNotPassed(uint256 readyAt);
error EvolveArtGenesis__GovernanceProposalFailedToPass(uint256 proposalId);


// Interface for the external ERC20 token used for staking
interface ICurationToken is IERC20 {}

/// @title EvolveArtGenesis - Dynamic AI-Curated IP Genesis & Licensing Platform
/// @author [Your Name/Alias]
/// @notice This contract enables the creation and evolution of unique digital intellectual property (IP) assets represented as NFTs.
///         It incorporates AI agent proposals for IP evolution, community curation via staking, and advanced, usage-based licensing models.
///         The contract's key parameters are self-amendable through decentralized governance.

// --- Outline & Function Summary ---
//
// I. Core IP & NFT Management (ERC721 Adapted)
//    1.  mintArtSeed: Mints a new Art Seed NFT, representing the genesis of an IP. Stores initial DNA hash and metadata URI.
//    2.  getArtSeedDNAHash: Returns the current cryptographic hash of the Art Seed's DNA.
//    3.  getArtSeedMetadataURI: Returns the URI for the current metadata JSON of an Art Seed.
//    4.  delegateEvolutionRights: Grants temporary evolution proposal rights for an Art Seed to another address (e.g., an AI agent).
//    5.  revokeEvolutionRights: Revokes any active evolution delegation for a specific Art Seed.
//
// II. AI Agent & Evolution Mechanics
//    6.  registerAIAgent: Registers an address as an "AI Agent" with a name and metadata URI.
//    7.  submitEvolutionProposal: An AI Agent or delegated address proposes an evolution (new DNA hash, metadata URI) for an Art Seed. Requires a stake.
//    8.  voteOnEvolutionProposal: Staked curators vote on evolution proposals.
//    9.  executeEvolutionProposal: Applies the proposed changes if a proposal passes, updates DNA/metadata, and manages proposer's stake.
//    10. getEvolutionProposalDetails: Retrieves detailed information about a specific evolution proposal.
//
// III. Decentralized Licensing & Revenue Sharing
//    11. setLicensingTerms: Art Seed owner sets base licensing fees, royalty splits for genesis creator and evolvers, and duration constraints.
//    12. requestLicense: A user requests a license for an Art Seed, paying the base fee.
//    13. approveLicenseRequest: Art Seed owner approves a pending license request, activating it.
//    14. revokeActiveLicense: Art Seed owner (or licensee under specific terms) can revoke an active license.
//    15. recordUsageAndPayRoyalties: Licensee reports usage units and pays additional royalties based on usage.
//    16. withdrawEarnings: Allows genesis creators, owners, and evolvers to withdraw their accumulated royalty shares.
//
// IV. Curation & Governance (Staking & Self-Amending Parameters)
//    17. stakeCurationTokens: Users stake CurationToken (ERC20) to gain voting power for proposals.
//    18. unstakeCurationTokens: Users unstake CurationToken, subject to an unbonding period.
//    19. withdrawUnstakedTokens: Allows users to withdraw their CurationTokens after unbonding.
//    20. proposeGovernanceParameterChange: Staked curator proposes changing a critical contract parameter (e.g., voting thresholds).
//    21. voteOnGovernanceParameterChange: Staked curators vote on proposed governance changes.
//    22. enactGovernanceParameterChange: Enacts a governance change after a successful vote and time delay.
//
// V. Query & Utility Functions
//    23. getAIAgentInfo: Retrieves information about a registered AI Agent.
//    24. getArtSeedLicensingTerms: Returns the current licensing terms set for an Art Seed.
//    25. getPendingLicenses: Returns a list of pending license requests for an Art Seed.
//    26. getActiveLicenses: Returns a list of active licenses for an Art Seed (filtered by expiry/revocation).
//    27. getLicenseDetails: Returns details of a specific license.

contract EvolveArtGenesis is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 Token ID counter
    Counters.Counter private _tokenIdCounter;

    // External Curation Token
    ICurationToken public immutable curationToken;

    // Contract Parameters (governable)
    uint256 public MIN_PROPOSAL_STAKE;             // Minimum CurationToken stake for an evolution proposal
    uint256 public EVOLUTION_VOTING_PERIOD;        // Duration in seconds for evolution proposal voting
    uint256 public EVOLUTION_PASS_THRESHOLD_BPS;   // Percentage (basis points) of total staked power required to pass an evolution proposal (e.g., 6000 for 60%)
    uint256 public CURATOR_UNBONDING_PERIOD;       // Duration in seconds for unstaking CurationToken
    uint256 public GOVERNANCE_VOTING_PERIOD;       // Duration in seconds for governance proposal voting
    uint256 public GOVERNANCE_PASS_THRESHOLD_BPS;  // Percentage (basis points) of total staked power required to pass a governance proposal
    uint256 public GOVERNANCE_ENACTMENT_DELAY;     // Delay in seconds before a passed governance proposal can be enacted

    // --- Data Structures ---

    // Art Seed IP asset details
    struct ArtSeed {
        address genesisCreator;
        bytes32 currentDNAHash;
        string metadataURI;
        uint256 lastEvolutionTimestamp;
        // Royalty distribution for this specific IP
        uint256 baseLicenseFee;         // Base fee for a license in native currency (ETH/MATIC)
        uint256 royaltyShareGenesisCreatorBPS; // Basis points (e.g., 500 = 5%)
        uint256 royaltyShareEvolversBPS;       // Basis points (e.g., 500 = 5%)
        uint256 minLicenseDuration;
        uint256 maxLicenseDuration;
        bytes32 licenseAgreementHash; // Hash of a default or general license agreement text
    }
    mapping(uint256 => ArtSeed) public artSeeds;

    // Evolution Delegation
    struct EvolutionDelegate {
        address delegatee;
        uint256 expiresAt;
    }
    mapping(uint256 => EvolutionDelegate) public evolutionDelegations; // tokenId => EvolutionDelegate

    // AI Agents
    struct AIAgent {
        string name;
        string metadataURI; // e.g., describing its capabilities or algorithms
        bool isRegistered;
    }
    mapping(address => AIAgent) public aiAgents; // agentAddress => AIAgent

    // Evolution Proposals
    struct EvolutionProposal {
        uint256 tokenId;
        address proposer;
        bytes32 proposedDNAHash;
        string proposedMetadataURI;
        uint256 submissionTimestamp;
        uint256 votingEndsAt;
        uint256 requiredStake; // Stake amount transferred by proposer
        uint256 yesVotes; // Total CurationToken stake for 'yes'
        uint256 noVotes;  // Total CurationToken stake for 'no'
        bool executed;
        bool passed;
    }
    Counters.Counter private _evolutionProposalIdCounter;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedEvolution; // proposalId => voter => bool

    // Licensing
    struct License {
        uint256 tokenId;
        address licensee;
        address creator; // owner at time of license request
        uint256 issuedAt;
        uint256 expiresAt;
        uint256 baseFeePaid; // In native currency
        uint256 accumulatedUsageRoyalties; // In native currency
        bytes32 agreementHash; // Hash of the specific agreement text for this license
        bool approved;
        bool revoked;
    }
    Counters.Counter private _licenseIdCounter;
    mapping(uint256 => License) public licenses;
    mapping(uint256 => uint256[]) public pendingLicensesByTokenId; // tokenId => list of licenseIds
    mapping(uint256 => uint256[]) public activeLicensesByTokenId;  // tokenId => list of licenseIds

    // Royalty Balances
    mapping(address => uint256) public royaltyBalances; // address => amount (in native currency)

    // Curation Staking
    struct CurationStake {
        uint256 amount; // Amount currently staked
    }
    mapping(address => CurationStake) public stakedCurators;
    uint256 public totalStakedCurationTokens; // Total CurationTokens staked in the contract

    // For Unstaking: Tracking amounts put into unbonding period
    mapping(address => uint256) public pendingUnstakeAmounts; // Address => Amount of CurationToken waiting to be withdrawn
    mapping(address => uint256) public pendingUnstakeReadyAt; // Address => Timestamp when pendingUnstakeAmounts becomes withdrawable

    // Governance Proposals
    struct GovernanceProposal {
        bytes32 parameterName; // e.g., keccak256("MIN_PROPOSAL_STAKE")
        uint256 newValue;
        uint256 submissionTimestamp;
        uint256 votingEndsAt;
        uint256 enactmentReadyAt; // Timestamp after voting ends + GOVERNANCE_ENACTMENT_DELAY
        uint256 yesVotes;
        uint256 noVotes;
        bool enacted;
        bool passed;
    }
    Counters.Counter private _governanceProposalIdCounter;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedGovernance; // proposalId => voter => bool


    // --- Events ---
    event ArtSeedMinted(uint256 indexed tokenId, address indexed creator, bytes32 initialDNAHash, string initialMetadataURI);
    event EvolutionRightsDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee, uint256 expiresAt);
    event EvolutionRightsRevoked(uint256 indexed tokenId, address indexed delegator, address indexed previousDelegatee);
    event AIAgentRegistered(address indexed agentAddress, string agentName, string metadataURI);
    event EvolutionProposalSubmitted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer, bytes32 proposedDNAHash, string proposedMetadataURI, uint256 requiredStake);
    event EvolutionVoteCast(uint256 indexed proposalId, address indexed voter, bool approve, uint256 votingPower);
    event EvolutionExecuted(uint256 indexed proposalId, uint256 indexed tokenId, bytes32 newDNAHash, string newMetadataURI, bool passed);
    event LicensingTermsSet(uint256 indexed tokenId, address indexed owner, uint256 baseFee, uint256 royaltyGenesisBPS, uint256 royaltyEvolversBPS);
    event LicenseRequested(uint256 indexed licenseId, uint256 indexed tokenId, address indexed licensee, uint256 baseFeePaid, uint256 expiresAt);
    event LicenseApproved(uint256 indexed licenseId, uint256 indexed tokenId, address indexed approver);
    event LicenseRevoked(uint256 indexed licenseId, uint256 indexed tokenId, address indexed revoker);
    event UsageReported(uint256 indexed licenseId, uint256 indexed tokenId, address indexed licensee, uint256 usageUnits, uint256 royaltiesPaid);
    event EarningsWithdrawn(address indexed recipient, uint256 amount);
    event TokensStaked(address indexed curator, uint256 amount);
    event TokensUnstaked(address indexed curator, uint256 amount, uint256 unbondAvailableAt);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 parameterName, uint256 newValue, uint256 enactmentReadyAt);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool approve, uint256 votingPower);
    event GovernanceEnacted(uint256 indexed proposalId, bytes32 parameterName, uint256 newValue);


    // --- Constructor ---
    /// @param _curationTokenAddress The address of the ERC20 CurationToken used for staking and voting.
    constructor(address _curationTokenAddress)
        ERC721("EvolveArtGenesis NFT", "EAG")
        Ownable(msg.sender)
    {
        if (_curationTokenAddress == address(0)) revert EvolveArtGenesis__ZeroAddress();
        curationToken = ICurationToken(_curationTokenAddress);

        // Initialize governable parameters with sensible defaults
        MIN_PROPOSAL_STAKE = 1 ether; // 1 CurationToken
        EVOLUTION_VOTING_PERIOD = 3 days;
        EVOLUTION_PASS_THRESHOLD_BPS = 6000; // 60%
        CURATOR_UNBONDING_PERIOD = 7 days;
        GOVERNANCE_VOTING_PERIOD = 7 days;
        GOVERNANCE_PASS_THRESHOLD_BPS = 7000; // 70%
        GOVERNANCE_ENACTMENT_DELAY = 3 days;
    }

    // --- Modifier for AI Agents / Delegates ---
    modifier onlyAIAgentOrDelegate(uint256 _tokenId) {
        bool isAgent = aiAgents[msg.sender].isRegistered;
        EvolutionDelegate memory delegation = evolutionDelegations[_tokenId];
        bool isDelegate = (delegation.delegatee == msg.sender && block.timestamp <= delegation.expiresAt);

        if (!(isAgent || isDelegate)) {
            revert EvolveArtGenesis__NotAuthorizedToEvolve(msg.sender, _tokenId);
        }
        _;
    }

    modifier onlyRegisteredAIAgent() {
        if (!aiAgents[msg.sender].isRegistered) revert EvolveArtGenesis__NotAIAgent(msg.sender);
        _;
    }

    // --- I. Core IP & NFT Management ---

    /// @notice Mints a new "Art Seed" NFT, representing the genesis of a unique IP asset.
    /// @param _initialDNAHash The cryptographic hash of the initial DNA string (expected to be stored off-chain).
    /// @param _initialMetadataURI The URI pointing to the initial metadata JSON for the Art Seed.
    /// @return The ID of the newly minted Art Seed NFT.
    function mintArtSeed(bytes32 _initialDNAHash, string calldata _initialMetadataURI)
        public
        nonReentrant
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _initialMetadataURI); // ERC721 metadata URI

        artSeeds[newTokenId] = ArtSeed({
            genesisCreator: msg.sender,
            currentDNAHash: _initialDNAHash,
            metadataURI: _initialMetadataURI,
            lastEvolutionTimestamp: block.timestamp,
            baseLicenseFee: 0, // Default to 0, owner sets later
            royaltyShareGenesisCreatorBPS: 0,
            royaltyShareEvolversBPS: 0,
            minLicenseDuration: 0,
            maxLicenseDuration: type(uint256).max, // Effectively unlimited
            licenseAgreementHash: bytes32(0)
        });

        emit ArtSeedMinted(newTokenId, msg.sender, _initialDNAHash, _initialMetadataURI);
        return newTokenId;
    }

    /// @notice Returns the current cryptographic hash of the DNA string of a given Art Seed NFT.
    ///         The full DNA string is expected to be stored off-chain, verifiable by this hash.
    /// @param tokenId The ID of the Art Seed NFT.
    /// @return The current DNA hash.
    function getArtSeedDNAHash(uint256 tokenId) public view returns (bytes32) {
        if (artSeeds[tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(tokenId);
        return artSeeds[tokenId].currentDNAHash;
    }

    /// @notice Returns the URI pointing to the current metadata JSON for the Art Seed.
    /// @param tokenId The ID of the Art Seed NFT.
    /// @return The current metadata URI.
    function getArtSeedMetadataURI(uint256 tokenId) public view returns (string memory) {
        if (artSeeds[tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(tokenId);
        return artSeeds[tokenId].metadataURI;
    }

    /// @notice Allows the owner of an Art Seed to grant temporary evolution proposal rights to another address.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @param _delegatee The address to whom the rights are delegated.
    /// @param _duration The duration in seconds for which the rights are delegated.
    function delegateEvolutionRights(uint256 _tokenId, address _delegatee, uint256 _duration)
        public
        nonReentrant
    {
        if (ownerOf(_tokenId) != msg.sender) revert ERC721_NotApprovedOrOwner(msg.sender, _tokenId);
        if (_delegatee == address(0)) revert EvolveArtGenesis__ZeroAddress();
        if (_duration == 0) revert EvolveArtGenesis__InvalidDuration(1, type(uint256).max, 0);

        evolutionDelegations[_tokenId] = EvolutionDelegate({
            delegatee: _delegatee,
            expiresAt: block.timestamp + _duration
        });

        emit EvolutionRightsDelegated(_tokenId, msg.sender, _delegatee, block.timestamp + _duration);
    }

    /// @notice Revokes any active evolution delegation for a specific Art Seed.
    /// @param _tokenId The ID of the Art Seed NFT.
    function revokeEvolutionRights(uint256 _tokenId) public nonReentrant {
        if (ownerOf(_tokenId) != msg.sender) revert ERC721_NotApprovedOrOwner(msg.sender, _tokenId);

        EvolutionDelegate storage delegation = evolutionDelegations[_tokenId];
        address previousDelegatee = delegation.delegatee;
        
        if (previousDelegatee == address(0) || delegation.expiresAt < block.timestamp) {
            revert EvolveArtGenesis__EvolutionRightsNotDelegated(_tokenId); // Or a more specific error
        }

        delete evolutionDelegations[_tokenId]; // Clear the delegation
        emit EvolutionRightsRevoked(_tokenId, msg.sender, previousDelegatee);
    }

    // --- II. AI Agent & Evolution Mechanics ---

    /// @notice Registers an address as an "AI Agent" with a unique name and metadata.
    /// @param _agentName The name of the AI agent.
    /// @param _agentMetadataURI The URI pointing to metadata describing the agent's capabilities.
    function registerAIAgent(string calldata _agentName, string calldata _agentMetadataURI)
        public
        nonReentrant
    {
        if (aiAgents[msg.sender].isRegistered) revert EvolveArtGenesis__AlreadyRegistered();
        if (bytes(_agentName).length == 0) revert EvolveArtGenesis__ZeroAmount(); // Reusing for empty string

        aiAgents[msg.sender] = AIAgent({
            name: _agentName,
            metadataURI: _agentMetadataURI,
            isRegistered: true
        });

        emit AIAgentRegistered(msg.sender, _agentName, _agentMetadataURI);
    }

    /// @notice An registered AI Agent or a delegated address proposes an evolution for a specific Art Seed.
    ///         Requires a stake of `MIN_PROPOSAL_STAKE` in CurationToken.
    /// @param _targetTokenId The ID of the Art Seed NFT to be evolved.
    /// @param _proposedDNAHash The cryptographic hash of the entirely new DNA for the Art Seed after evolution.
    /// @param _proposedMetadataURI The URI pointing to the new metadata JSON for the evolved Art Seed.
    function submitEvolutionProposal(uint256 _targetTokenId, bytes32 _proposedDNAHash, string calldata _proposedMetadataURI)
        public
        nonReentrant
        onlyAIAgentOrDelegate(_targetTokenId)
    {
        if (artSeeds[_targetTokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(_targetTokenId);
        if (_proposedDNAHash == bytes32(0)) revert EvolveArtGenesis__ZeroAmount(); // Reusing for empty hash
        if (bytes(_proposedMetadataURI).length == 0) revert EvolveArtGenesis__ZeroAmount(); // Reusing for empty string

        // Transfer required stake from proposer to contract
        if (curationToken.balanceOf(msg.sender) < MIN_PROPOSAL_STAKE) {
            revert EvolveArtGenesis__InsufficientStake(MIN_PROPOSAL_STAKE, curationToken.balanceOf(msg.sender));
        }
        if (!curationToken.transferFrom(msg.sender, address(this), MIN_PROPOSAL_STAKE)) {
            revert EvolveArtGenesis__InsufficientFunds(MIN_PROPOSAL_STAKE, curationToken.balanceOf(msg.sender));
        }

        _evolutionProposalIdCounter.increment();
        uint256 newProposalId = _evolutionProposalIdCounter.current();

        evolutionProposals[newProposalId] = EvolutionProposal({
            tokenId: _targetTokenId,
            proposer: msg.sender,
            proposedDNAHash: _proposedDNAHash,
            proposedMetadataURI: _proposedMetadataURI,
            submissionTimestamp: block.timestamp,
            votingEndsAt: block.timestamp + EVOLUTION_VOTING_PERIOD,
            requiredStake: MIN_PROPOSAL_STAKE,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            passed: false
        });

        emit EvolutionProposalSubmitted(newProposalId, _targetTokenId, msg.sender, _proposedDNAHash, _proposedMetadataURI, MIN_PROPOSAL_STAKE);
    }

    /// @notice Staked curators vote on submitted evolution proposals. Their voting power is proportional to their stake.
    /// @param _proposalId The ID of the evolution proposal.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnEvolutionProposal(uint256 _proposalId, bool _approve) public nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.proposer == address(0)) revert EvolveArtGenesis__ProposalNotFound(_proposalId);
        if (proposal.votingEndsAt < block.timestamp) revert EvolveArtGenesis__ProposalExpired(_proposalId);
        if (hasVotedEvolution[_proposalId][msg.sender]) revert EvolveArtGenesis__AlreadyVoted(msg.sender, _proposalId);
        
        uint256 voterStake = stakedCurators[msg.sender].amount;
        if (voterStake == 0) revert EvolveArtGenesis__InsufficientCurationStake(1, 0); // Must be a staked curator

        if (_approve) {
            proposal.yesVotes += voterStake;
        } else {
            proposal.noVotes += voterStake;
        }
        hasVotedEvolution[_proposalId][msg.sender] = true;

        emit EvolutionVoteCast(_proposalId, msg.sender, _approve, voterStake);
    }

    /// @notice If an evolution proposal passes the voting threshold, this function applies the proposed changes to the Art Seed's DNA and metadata.
    ///         It also manages the proposer's stake: releasing it on success, or keeping it (effectively burned or sent to treasury) on failure.
    /// @param _proposalId The ID of the evolution proposal.
    function executeEvolutionProposal(uint256 _proposalId) public nonReentrant {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.proposer == address(0)) revert EvolveArtGenesis__ProposalNotFound(_proposalId);
        if (block.timestamp <= proposal.votingEndsAt) revert EvolveArtGenesis__ProposalNotReadyForExecution(_proposalId);
        if (proposal.executed) revert EvolveArtGenesis__ProposalAlreadyExecuted(_proposalId);

        proposal.executed = true; // Mark as executed regardless of pass/fail
        
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes == 0) { // No votes, automatically fail
            proposal.passed = false;
        } else {
            // Check if percentage of 'yes' votes crosses the threshold of total votes cast.
            // A more robust system might use a snapshot of totalStakedCurationTokens at proposal submission.
            if (proposal.yesVotes * 10000 >= totalVotes * EVOLUTION_PASS_THRESHOLD_BPS) {
                 proposal.passed = true;
            } else {
                 proposal.passed = false;
            }
        }

        if (proposal.passed) {
            ArtSeed storage artSeed = artSeeds[proposal.tokenId];
            artSeed.currentDNAHash = proposal.proposedDNAHash;
            artSeed.metadataURI = proposal.proposedMetadataURI;
            artSeed.lastEvolutionTimestamp = block.timestamp;
            
            // Refund proposer's stake
            if (!curationToken.transfer(proposal.proposer, proposal.requiredStake)) {
                // If transfer fails, this is a critical error. In a production system,
                // this would likely trigger an alert or manual intervention.
                // For this example, we proceed, but this is a potential fund lock risk.
            }
        } else {
            // If proposal fails, the stake is held by the contract.
            // It can be configured to be burned, sent to a DAO treasury, etc.
            // For this example, it remains in the contract, effectively lost to the proposer.
            revert EvolveArtGenesis__ProposalFailedToPass(_proposalId);
        }

        emit EvolutionExecuted(proposal.proposer, proposal.tokenId, proposal.proposedDNAHash, proposal.proposedMetadataURI, proposal.passed);
    }

    /// @notice Retrieves detailed information about a specific evolution proposal.
    /// @param _proposalId The ID of the evolution proposal.
    /// @return A tuple containing all relevant proposal details.
    function getEvolutionProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 tokenId,
            address proposer,
            bytes32 proposedDNAHash,
            string memory proposedMetadataURI,
            uint256 submissionTimestamp,
            uint256 votingEndsAt,
            uint256 requiredStake,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed,
            bool passed
        )
    {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        if (proposal.proposer == address(0)) revert EvolveArtGenesis__ProposalNotFound(_proposalId);

        return (
            proposal.tokenId,
            proposal.proposer,
            proposal.proposedDNAHash,
            proposal.proposedMetadataURI,
            proposal.submissionTimestamp,
            proposal.votingEndsAt,
            proposal.requiredStake,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executed,
            proposal.passed
        );
    }

    // --- III. Decentralized Licensing & Revenue Sharing ---

    /// @notice The Art Seed owner sets the general licensing terms for their IP.
    ///         Royalty splits are in basis points (e.g., 500 = 5%). Sum of splits cannot exceed 100%.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @param _baseFee The base fee for a license in native currency (ETH/MATIC).
    /// @param _royaltyShareGenesisCreatorBPS Basis points for the original minter.
    /// @param _royaltyShareEvolversBPS Basis points for the (last) AI agent/delegated evolver.
    /// @param _minDuration Minimum allowed license duration in seconds.
    /// @param _maxDuration Maximum allowed license duration in seconds.
    /// @param _licenseAgreementHash Hash of the full legal license text (stored off-chain).
    function setLicensingTerms(
        uint256 _tokenId,
        uint256 _baseFee,
        uint256 _royaltyShareGenesisCreatorBPS,
        uint256 _royaltyShareEvolversBPS,
        uint256 _minDuration,
        uint256 _maxDuration,
        bytes32 _licenseAgreementHash
    ) public nonReentrant {
        if (ownerOf(_tokenId) != msg.sender) revert ERC721_NotApprovedOrOwner(msg.sender, _tokenId);
        if (_royaltyShareGenesisCreatorBPS + _royaltyShareEvolversBPS > 10000) revert EvolveArtGenesis__InvalidRoyaltySplit();
        if (_minDuration > _maxDuration && _maxDuration != 0) revert EvolveArtGenesis__InvalidDuration(_minDuration, _maxDuration, 0); // maxDuration can be 0 for "unlimited" (type(uint256).max)

        ArtSeed storage artSeed = artSeeds[_tokenId];
        artSeed.baseLicenseFee = _baseFee;
        artSeed.royaltyShareGenesisCreatorBPS = _royaltyShareGenesisCreatorBPS;
        artSeed.royaltyShareEvolversBPS = _royaltyShareEvolversBPS;
        artSeed.minLicenseDuration = _minDuration;
        artSeed.maxLicenseDuration = _maxDuration;
        artSeed.licenseAgreementHash = _licenseAgreementHash;

        emit LicensingTermsSet(_tokenId, msg.sender, _baseFee, _royaltyShareGenesisCreatorBPS, _royaltyShareEvolversBPS);
    }

    /// @notice A user requests a license to use an Art Seed. Requires payment of the base fee.
    ///         The request is pending approval by the Art Seed owner.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @param _duration The requested license duration in seconds.
    /// @param _licensee The address of the licensee (can be msg.sender).
    /// @param _agreementHash Hash of the specific agreement text proposed by the licensee.
    function requestLicense(uint256 _tokenId, uint256 _duration, address _licensee, bytes32 _agreementHash)
        public
        payable
        nonReentrant
    {
        if (artSeeds[_tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(_tokenId);
        if (_licensee == address(0)) revert EvolveArtGenesis__ZeroAddress();

        ArtSeed storage artSeed = artSeeds[_tokenId];
        if (msg.value < artSeed.baseLicenseFee) {
            revert EvolveArtGenesis__InsufficientFunds(artSeed.baseLicenseFee, msg.value);
        }
        if (_duration < artSeed.minLicenseDuration || (_duration > artSeed.maxLicenseDuration && artSeed.maxLicenseDuration != type(uint256).max)) {
            revert EvolveArtGenesis__InvalidDuration(artSeed.minLicenseDuration, artSeed.maxLicenseDuration, _duration);
        }

        // Add base fee to the current owner's royalty balance for later withdrawal
        royaltyBalances[ownerOf(_tokenId)] += msg.value;

        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        licenses[newLicenseId] = License({
            tokenId: _tokenId,
            licensee: _licensee,
            creator: ownerOf(_tokenId), // Current owner at time of license request
            issuedAt: block.timestamp,
            expiresAt: block.timestamp + _duration,
            baseFeePaid: msg.value,
            accumulatedUsageRoyalties: 0,
            agreementHash: _agreementHash,
            approved: false, // Starts as pending
            revoked: false
        });

        pendingLicensesByTokenId[_tokenId].push(newLicenseId);
        emit LicenseRequested(newLicenseId, _tokenId, _licensee, msg.value, block.timestamp + _duration);
    }

    /// @notice The Art Seed owner approves a pending license request, activating it.
    /// @param _licenseId The ID of the license request.
    function approveLicenseRequest(uint256 _licenseId) public nonReentrant {
        License storage license = licenses[_licenseId];
        if (license.tokenId == 0) revert EvolveArtGenesis__LicenseNotFound(_licenseId); // check if struct is empty (i.e., license does not exist)
        if (ownerOf(license.tokenId) != msg.sender) revert ERC721_NotApprovedOrOwner(msg.sender, license.tokenId);
        if (license.approved) revert EvolveArtGenesis__LicenseAlreadyApproved(_licenseId);
        if (license.revoked) revert EvolveArtGenesis__LicenseAlreadyRevoked(_licenseId);

        license.approved = true;

        // Remove from pending list, add to active list
        uint256[] storage pending = pendingLicensesByTokenId[license.tokenId];
        for (uint256 i = 0; i < pending.length; i++) {
            if (pending[i] == _licenseId) {
                pending[i] = pending[pending.length - 1];
                pending.pop();
                break;
            }
        }
        activeLicensesByTokenId[license.tokenId].push(_licenseId);

        emit LicenseApproved(_licenseId, license.tokenId, msg.sender);
    }

    /// @notice The Art Seed owner can revoke an active license.
    /// @param _licenseId The ID of the license to revoke.
    function revokeActiveLicense(uint256 _licenseId) public nonReentrant {
        License storage license = licenses[_licenseId];
        if (license.tokenId == 0) revert EvolveArtGenesis__LicenseNotFound(_licenseId);
        if (ownerOf(license.tokenId) != msg.sender) revert ERC721_NotApprovedOrOwner(msg.sender, license.tokenId);
        if (!license.approved) revert EvolveArtGenesis__LicenseNotApproved(_licenseId);
        if (license.revoked) revert EvolveArtGenesis__LicenseAlreadyRevoked(_licenseId);

        license.revoked = true;
        // The license will be filtered out by getActiveLicenses, no need to remove from array for gas.

        emit LicenseRevoked(_licenseId, license.tokenId, msg.sender);
    }

    /// @notice A licensee reports usage units (e.g., views, prints) and pays additional royalties based on the terms.
    ///         This enables dynamic, usage-based IP monetization.
    /// @param _licenseId The ID of the active license.
    /// @param _usageUnits The number of usage units being reported.
    function recordUsageAndPayRoyalties(uint256 _licenseId, uint256 _usageUnits)
        public
        payable
        nonReentrant
    {
        License storage license = licenses[_licenseId];
        if (license.tokenId == 0) revert EvolveArtGenesis__LicenseNotFound(_licenseId);
        if (license.licensee != msg.sender) revert EvolveArtGenesis__NotAuthorizedToEvolve(msg.sender, license.tokenId); // Reusing error
        if (!license.approved) revert EvolveArtGenesis__LicenseNotApproved(_licenseId);
        if (license.revoked || license.expiresAt < block.timestamp) revert EvolveArtGenesis__LicenseExpired(_licenseId);
        if (_usageUnits == 0) revert EvolveArtGenesis__ZeroAmount();

        ArtSeed storage artSeed = artSeeds[license.tokenId];
        // For simplicity, let's assume each usage unit costs 1 wei. In a real system, this would be more complex.
        uint256 usageFee = _usageUnits * 1 wei; 
        if (msg.value < usageFee) {
            revert EvolveArtGenesis__InsufficientFunds(usageFee, msg.value);
        }

        license.accumulatedUsageRoyalties += msg.value;

        // Distribute royalties
        uint256 remainingAmount = msg.value;

        // Genesis Creator's share
        uint256 genesisShare = (msg.value * artSeed.royaltyShareGenesisCreatorBPS) / 10000;
        if (genesisShare > 0) {
            royaltyBalances[artSeed.genesisCreator] += genesisShare;
            remainingAmount -= genesisShare;
        }

        // Evolver's share (simplified: currently routed to current owner. A robust system would track individual evolvers)
        uint256 evolverShare = (msg.value * artSeed.royaltyShareEvolversBPS) / 10000;
        if (evolverShare > 0) {
             // For this example, we direct evolver share to the current owner.
             // A more complex system would store a list of previous evolvers and their contributions.
             royaltyBalances[ownerOf(license.tokenId)] += evolverShare; 
             remainingAmount -= evolverShare;
        }

        // Current Owner's share (includes any remaining after fixed splits)
        royaltyBalances[ownerOf(license.tokenId)] += remainingAmount;

        emit UsageReported(_licenseId, license.tokenId, msg.sender, _usageUnits, msg.value);
    }

    /// @notice Allows genesis creators, current owners, and evolvers to withdraw their accumulated royalty shares (in native currency).
    function withdrawEarnings() public nonReentrant {
        uint256 amount = royaltyBalances[msg.sender];
        if (amount == 0) revert EvolveArtGenesis__NoBalanceToWithdraw();

        royaltyBalances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            royaltyBalances[msg.sender] = amount; // Revert the balance update if send fails
            revert EvolveArtGenesis__InsufficientFunds(amount, 0); // Reusing for failed transfer
        }
        emit EarningsWithdrawn(msg.sender, amount);
    }

    // --- IV. Curation & Governance (Staking & Self-Amending Parameters) ---

    /// @notice Users stake CurationToken (ERC20) to gain voting power for evolution proposals and governance changes.
    /// @param _amount The amount of CurationToken to stake.
    function stakeCurationTokens(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert EvolveArtGenesis__ZeroAmount();
        if (curationToken.balanceOf(msg.sender) < _amount) {
            revert EvolveArtGenesis__InsufficientFunds(_amount, curationToken.balanceOf(msg.sender));
        }

        if (!curationToken.transferFrom(msg.sender, address(this), _amount)) {
            revert EvolveArtGenesis__InsufficientFunds(_amount, curationToken.balanceOf(msg.sender));
        }

        stakedCurators[msg.sender].amount += _amount;
        totalStakedCurationTokens += _amount;

        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Users unstake a specified amount of CurationToken. These tokens enter an unbonding period.
    ///         The voting power is reduced immediately.
    /// @param _amount The amount of CurationToken to unstake.
    function unstakeCurationTokens(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert EvolveArtGenesis__ZeroAmount();
        if (stakedCurators[msg.sender].amount < _amount) {
            revert EvolveArtGenesis__InsufficientCurationStake(_amount, stakedCurators[msg.sender].amount);
        }

        // Reduce the staked amount immediately, reducing voting power
        stakedCurators[msg.sender].amount -= _amount;
        totalStakedCurationTokens -= _amount;

        // Add to pending unbond, and set/update the readiness timestamp
        pendingUnstakeAmounts[msg.sender] += _amount;
        pendingUnstakeReadyAt[msg.sender] = block.timestamp + CURATOR_UNBONDING_PERIOD;

        emit TokensUnstaked(msg.sender, _amount, pendingUnstakeReadyAt[msg.sender]);
    }

    /// @notice Allows users to withdraw their CurationTokens after the unbonding period has passed.
    function withdrawUnstakedTokens() public nonReentrant {
        uint256 amountToWithdraw = pendingUnstakeAmounts[msg.sender];
        if (amountToWithdraw == 0) revert EvolveArtGenesis__NoStakeToUnstake();
        if (block.timestamp < pendingUnstakeReadyAt[msg.sender]) {
            revert EvolveArtGenesis__UnbondingPeriodActive(pendingUnstakeReadyAt[msg.sender]);
        }

        // Reset pending amounts before transfer to prevent re-entrancy issues if transfer fails
        pendingUnstakeAmounts[msg.sender] = 0;
        pendingUnstakeReadyAt[msg.sender] = 0; // Clear the timer

        // Transfer the CurationTokens
        if (!curationToken.transfer(msg.sender, amountToWithdraw)) {
            // Revert state changes if transfer fails
            pendingUnstakeAmounts[msg.sender] = amountToWithdraw;
            pendingUnstakeReadyAt[msg.sender] = block.timestamp - 1; // Mark as immediately available again
            revert EvolveArtGenesis__InsufficientFunds(amountToWithdraw, 0); // Reusing for failed transfer
        }
        emit EarningsWithdrawn(msg.sender, amountToWithdraw); // Reusing event
    }

    /// @notice A staked curator can propose changing a critical contract parameter.
    /// @param _parameterName A bytes32 representation of the parameter name (e.g., keccak256("MIN_PROPOSAL_STAKE")).
    /// @param _newValue The new value for the parameter.
    function proposeGovernanceParameterChange(bytes32 _parameterName, uint256 _newValue)
        public
        nonReentrant
    {
        if (stakedCurators[msg.sender].amount == 0) revert EvolveArtGenesis__InsufficientCurationStake(1, 0);
        
        // Ensure _parameterName is a changeable parameter
        if (_parameterName != keccak256("MIN_PROPOSAL_STAKE") &&
            _parameterName != keccak256("EVOLUTION_VOTING_PERIOD") &&
            _parameterName != keccak256("EVOLUTION_PASS_THRESHOLD_BPS") &&
            _parameterName != keccak256("CURATOR_UNBONDING_PERIOD") &&
            _parameterName != keccak256("GOVERNANCE_VOTING_PERIOD") &&
            _parameterName != keccak256("GOVERNANCE_PASS_THRESHOLD_BPS") &&
            _parameterName != keccak256("GOVERNANCE_ENACTMENT_DELAY"))
        {
            revert EvolveArtGenesis__ParameterNotChangeable(_parameterName);
        }

        _governanceProposalIdCounter.increment();
        uint256 newProposalId = _governanceProposalIdCounter.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            submissionTimestamp: block.timestamp,
            votingEndsAt: block.timestamp + GOVERNANCE_VOTING_PERIOD,
            enactmentReadyAt: 0, // Set after voting
            yesVotes: 0,
            noVotes: 0,
            enacted: false,
            passed: false
        });

        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _parameterName, _newValue, block.timestamp + GOVERNANCE_VOTING_PERIOD + GOVERNANCE_ENACTMENT_DELAY);
    }

    /// @notice Staked curators vote on proposed governance changes.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnGovernanceParameterChange(uint256 _proposalId, bool _approve) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.parameterName == bytes32(0)) revert EvolveArtGenesis__GovernanceProposalNotFound(_proposalId);
        if (proposal.votingEndsAt < block.timestamp) revert EvolveArtGenesis__GovernanceProposalExpired(_proposalId);
        if (hasVotedGovernance[_proposalId][msg.sender]) revert EvolveArtGenesis__AlreadyVoted(msg.sender, _proposalId);

        uint256 voterStake = stakedCurators[msg.sender].amount;
        if (voterStake == 0) revert EvolveArtGenesis__InsufficientCurationStake(1, 0);

        if (_approve) {
            proposal.yesVotes += voterStake;
        } else {
            proposal.noVotes += voterStake;
        }
        hasVotedGovernance[_proposalId][msg.sender] = true;

        emit GovernanceVoteCast(_proposalId, msg.sender, _approve, voterStake);
    }

    /// @notice Enacts a governance change after a successful vote and a specified time delay.
    /// @param _proposalId The ID of the governance proposal.
    function enactGovernanceParameterChange(uint256 _proposalId) public nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.parameterName == bytes32(0)) revert EvolveArtGenesis__GovernanceProposalNotFound(_proposalId);
        if (proposal.enacted) revert EvolveArtGenesis__GovernanceProposalAlreadyEnacted(_proposalId);
        if (block.timestamp <= proposal.votingEndsAt) revert EvolveArtGenesis__GovernanceProposalNotReadyForEnactment(_proposalId);

        // Calculate if proposal passed
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        if (totalVotes == 0 || (proposal.yesVotes * 10000 < totalVotes * GOVERNANCE_PASS_THRESHOLD_BPS)) {
            proposal.passed = false;
            revert EvolveArtGenesis__GovernanceProposalFailedToPass(_proposalId);
        } else {
            proposal.passed = true;
        }

        // Set enactment readiness timestamp if not already set (occurs after voting ends)
        if (proposal.enactmentReadyAt == 0) {
            proposal.enactmentReadyAt = proposal.votingEndsAt + GOVERNANCE_ENACTMENT_DELAY;
        }

        if (block.timestamp < proposal.enactmentReadyAt) revert EvolveArtGenesis__ExecutionDelayNotPassed(proposal.enactmentReadyAt);

        // Enact the change based on the parameter name
        bytes32 param = proposal.parameterName;
        uint256 val = proposal.newValue;

        if (param == keccak256("MIN_PROPOSAL_STAKE")) MIN_PROPOSAL_STAKE = val;
        else if (param == keccak256("EVOLUTION_VOTING_PERIOD")) EVOLUTION_VOTING_PERIOD = val;
        else if (param == keccak256("EVOLUTION_PASS_THRESHOLD_BPS")) EVOLUTION_PASS_THRESHOLD_BPS = val;
        else if (param == keccak256("CURATOR_UNBONDING_PERIOD")) CURATOR_UNBONDING_PERIOD = val;
        else if (param == keccak256("GOVERNANCE_VOTING_PERIOD")) GOVERNANCE_VOTING_PERIOD = val;
        else if (param == keccak256("GOVERNANCE_PASS_THRESHOLD_BPS")) GOVERNANCE_PASS_THRESHOLD_BPS = val;
        else if (param == keccak256("GOVERNANCE_ENACTMENT_DELAY")) GOVERNANCE_ENACTMENT_DELAY = val;
        else revert EvolveArtGenesis__ParameterNotChangeable(param); 

        proposal.enacted = true;
        emit GovernanceEnacted(_proposalId, param, val);
    }

    // --- V. Query & Utility Functions ---

    /// @notice Retrieves information about a registered AI Agent.
    /// @param _agentAddress The address of the AI Agent.
    /// @return A tuple containing the agent's name, metadata URI, and registration status.
    function getAIAgentInfo(address _agentAddress)
        public
        view
        returns (string memory name, string memory metadataURI, bool isRegistered)
    {
        AIAgent storage agent = aiAgents[_agentAddress];
        if (!agent.isRegistered) revert EvolveArtGenesis__AgentNotRegistered(_agentAddress);
        return (agent.name, agent.metadataURI, agent.isRegistered);
    }

    /// @notice Returns the current licensing terms set for an Art Seed.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @return A tuple containing all relevant licensing terms.
    function getArtSeedLicensingTerms(uint256 _tokenId)
        public
        view
        returns (
            uint256 baseFee,
            uint256 royaltyShareGenesisCreatorBPS,
            uint256 royaltyShareEvolversBPS,
            uint256 minDuration,
            uint256 maxDuration,
            bytes32 licenseAgreementHash
        )
    {
        if (artSeeds[_tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(_tokenId);
        ArtSeed storage artSeed = artSeeds[_tokenId];
        return (
            artSeed.baseLicenseFee,
            artSeed.royaltyShareGenesisCreatorBPS,
            artSeed.royaltyShareEvolversBPS,
            artSeed.minLicenseDuration,
            artSeed.maxLicenseDuration,
            artSeed.licenseAgreementHash
        );
    }

    /// @notice Returns a list of IDs for pending license requests for an Art Seed.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @return An array of license IDs.
    function getPendingLicenses(uint256 _tokenId) public view returns (uint256[] memory) {
        if (artSeeds[_tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(_tokenId);
        uint256[] storage pending = pendingLicensesByTokenId[_tokenId];
        if (pending.length == 0) revert EvolveArtGenesis__NoPendingLicenses();
        return pending;
    }

    /// @notice Returns a list of IDs for active (approved and not revoked/expired) licenses for an Art Seed.
    /// @param _tokenId The ID of the Art Seed NFT.
    /// @return An array of license IDs.
    function getActiveLicenses(uint256 _tokenId) public view returns (uint256[] memory) {
        if (artSeeds[_tokenId].genesisCreator == address(0)) revert EvolveArtGenesis__TokenDoesNotExist(_tokenId);
        uint256[] memory activeLicensesIds = activeLicensesByTokenId[_tokenId];
        if (activeLicensesIds.length == 0) revert EvolveArtGenesis__NoActiveLicenses();

        // Filter out expired/revoked ones for the view function
        uint256[] memory validLicenses = new uint256[](activeLicensesIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < activeLicensesIds.length; i++) {
            License storage license = licenses[activeLicensesIds[i]];
            if (license.approved && !license.revoked && license.expiresAt > block.timestamp) {
                validLicenses[count] = activeLicensesIds[i];
                count++;
            }
        }
        uint256[] memory filteredLicenses = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            filteredLicenses[i] = validLicenses[i];
        }
        return filteredLicenses;
    }

    /// @notice Returns details of a specific license (active, pending, or revoked).
    /// @param _licenseId The ID of the license.
    /// @return A tuple containing all relevant license details.
    function getLicenseDetails(uint256 _licenseId)
        public
        view
        returns (
            uint256 tokenId,
            address licensee,
            address creator,
            uint256 issuedAt,
            uint256 expiresAt,
            uint256 baseFeePaid,
            uint256 accumulatedUsageRoyalties,
            bytes32 agreementHash,
            bool approved,
            bool revoked
        )
    {
        License storage license = licenses[_licenseId];
        if (license.tokenId == 0) revert EvolveArtGenesis__LicenseNotFound(_licenseId); // check if struct is empty

        return (
            license.tokenId,
            license.licensee,
            license.creator,
            license.issuedAt,
            license.expiresAt,
            license.baseFeePaid,
            license.accumulatedUsageRoyalties,
            license.agreementHash,
            license.approved,
            license.revoked
        );
    }
}
```