Here's a smart contract written in Solidity, designed with advanced concepts, creative functionality, and trendy features, avoiding direct duplication of existing open-source projects while leveraging common standards like ERC-1155.

The core idea is a "Decentralized Autonomous Intellectual Property (DAIP) Nexus" that manages **Evolving Nexus Assets (ENAs)**. Each ENA represents a dynamic, fractionalized, and governed digital IP, which can have multiple "modules" (sub-components), track contributions, and offer flexible licensing. The governance is integrated for each ENA, allowing shareholders to collectively guide its evolution.

---

## Smart Contract: `EvolvingNexusIPCore`

### Outline and Function Summary:

This contract, `EvolvingNexusIPCore`, establishes a decentralized framework for managing dynamic, evolving intellectual properties (IPs), referred to as "Evolving Nexus Assets" (ENAs). It provides mechanisms for fractional ownership, on-chain governance, contribution tracking, and flexible licensing models for these digital assets and their sub-components (modules). The contract leverages ERC-1155 for fractional ownership shares of each ENA, where each ENA's ID is also its ERC-1155 token ID.

---

### **I. ENA Management (Creation & Core Lifecycle)**

1.  **`createEvolvingNexusAsset`**: Initializes a new ENA with core details (name, description, initial modules), mints initial fractional shares to the creator, and sets up its treasury and governance parameters.
2.  **`updateENAState`**: Allows ENA governance to update the ENA's overall state, such as its public description URI and current version number.
3.  **`deactivateENA`**: Pauses an ENA, preventing most operations until reactivated. This requires ENA governance approval.
4.  **`reactivateENA`**: Unpauses a deactivated ENA, making it active again. This requires ENA governance approval.
5.  **`setENATreasury`**: Changes the designated treasury address for an ENA. This requires ENA governance approval.

### **II. Module Management (Internal IP Components)**

6.  **`addModuleToENA`**: Adds a new, distinct module (e.g., a specific algorithm, dataset, art component) to an ENA. Modules can be individually licensable. Requires ENA governance approval.
7.  **`updateModule`**: Allows ENA governance to update an existing module's details, version, licensing status, and default licensing fee.
8.  **`removeModuleFromENA`**: Removes a module from an ENA. This is a sensitive operation and requires ENA governance approval.

### **III. Fractional Ownership & Revenue Aggregation**

9.  **`mintENAShares`**: Mints new fractional shares for a specific ENA to a recipient. Can be used for sales, rewarding contributions, etc. Requires ENA creator or contract owner's approval (or governance).
10. **`burnENAShares`**: Burns fractional shares from a holder. Requires ENA creator or contract owner's approval (or governance).
11. **`distributeRevenueToShareholders`**: Aggregates all revenue (ETH) collected by *this contract* for a specific ENA and transfers it to the ENA's designated `treasuryAddress`. The `treasuryAddress` is then responsible for actual distribution to individual shareholders (typically a separate, specialized contract).

### **IV. Contribution & Reputation System**

12. **`submitContribution`**: Allows any user to propose a contribution to an ENA, providing a description and proof URI.
13. **`approveContribution`**: ENA governance approves a pending contribution, assigning an impact score and potentially minting new shares to the contributor as a reward.
14. **`revokeContributionApproval`**: Reverts an approved contribution, resetting its impact score. This is a powerful action and should be protected by strong governance.

### **V. Licensing & Revenue Collection**

15. **`proposeLicenseAgreement`**: Initiates a proposal for a new licensing agreement for an ENA or a specific module within it. This proposal must be approved by ENA governance.
16. **`approveLicenseAgreement`**: ENA governance approves a proposed license, making it active and binding.
17. **`executeLicensePayment`**: Allows a licensee to make a one-time fixed fee payment for an active license. The payment is directed to this contract and then aggregated for distribution to the ENA's treasury.
18. **`recordExternalRevenue`**: Allows an authorized external agent (e.g., an oracle, an off-chain sales platform) to record and transfer revenue generated off-chain for an ENA. The funds are aggregated by this contract.

### **VI. On-chain Governance (for ENA-specific decisions)**

19. **`proposeENAGovernanceAction`**: Allows shareholders to propose a specific action or change for an ENA. The proposal includes a target contract and encoded `callData` for execution.
20. **`voteOnENAGovernanceProposal`**: Allows ENA shareholders to cast their vote (for or against) on a pending proposal, with their voting power determined by their share holdings.
21. **`executeENAGovernanceProposal`**: Executes a governance proposal that has passed its voting deadline, met quorum, and received more 'for' votes than 'against' votes.

### **VII. Query Functions (Read-only for Transparency)**

22. **`getENAInfo`**: Retrieves detailed information about a specific ENA.
23. **`getModuleInfo`**: Retrieves detailed information about a specific module within an ENA.
24. **`getPendingContributions`**: Lists all contributions awaiting approval for a given ENA. (Note: May be inefficient for very large lists in production.)
25. **`getActiveLicenseAgreements`**: Lists all active licensing agreements for a given ENA. (Note: May be inefficient for very large lists in production.)
26. **`getProposalState`**: Returns the current state (e.g., Active, Succeeded, Defeated, Executed) of a governance proposal.

### **VIII. Administrative Functions (Main Contract Owner)**

27. **`setApprovedExternalRevenueFeeder`**: Designates or revokes an address allowed to call `recordExternalRevenue`. This is a security feature controlled by the main contract deployer.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline and Function Summary:
// This contract, "EvolvingNexusIPCore", establishes a decentralized framework for managing dynamic, evolving intellectual properties (IPs),
// referred to as "Evolving Nexus Assets" (ENAs). It provides mechanisms for fractional ownership,
// on-chain governance, contribution tracking, and flexible licensing models for these digital assets and their sub-components (modules).
// The contract leverages ERC-1155 for fractional ownership shares of each ENA.

// I. ENA Management (Creation & Core Lifecycle)
// 1.  `createEvolvingNexusAsset`: Initializes a new ENA with core details and initial modules. Mints initial shares to the creator.
// 2.  `updateENAState`: Allows governance to update an ENA's overall state, description, and version.
// 3.  `deactivateENA`: Pauses an ENA, preventing further actions until reactivated (requires governance).
// 4.  `reactivateENA`: Unpauses a deactivated ENA (requires governance).
// 5.  `setENATreasury`: Changes the designated treasury address for an ENA (requires governance).

// II. Module Management (Internal IP Components)
// 6.  `addModuleToENA`: Adds a new, distinct module (e.g., a specific algorithm, dataset, art component) to an ENA.
// 7.  `updateModule`: Allows governance to update an existing module's details, version, and licensing parameters.
// 8.  `removeModuleFromENA`: Removes a module from an ENA (requires governance).

// III. Fractional Ownership & Revenue Aggregation
// 9.  `mintENAShares`: Mints new fractional shares for a specific ENA to a recipient. Can be used for sales, contributions, etc.
// 10. `burnENAShares`: Burns fractional shares from a holder.
// 11. `distributeRevenueToShareholders`: Aggregates all revenue (ETH) collected by *this contract* for a specific ENA and transfers it to the ENA's designated `treasuryAddress`.

// IV. Contribution & Reputation System
// 12. `submitContribution`: Allows a user to propose a contribution to an ENA, detailing their work.
// 13. `approveContribution`: ENA governance approves a pending contribution, assigning an impact score and potentially minting shares.
// 14. `revokeContributionApproval`: Reverts an approved contribution, adjusting impact score and burning shares if applicable.

// V. Licensing & Revenue Collection
// 15. `proposeLicenseAgreement`: Initiates a proposal for a new licensing agreement for an ENA or a specific module within it.
// 16. `approveLicenseAgreement`: ENA governance approves a proposed license, making it active.
// 17. `executeLicensePayment`: Allows a licensee to make a payment for an active license.
// 18. `recordExternalRevenue`: Allows authorized parties to record revenue generated off-chain for an ENA, transferring funds to this contract for aggregation.

// VI. On-chain Governance (for ENA-specific decisions)
// 19. `proposeENAGovernanceAction`: Allows shareholders to propose a specific action or change for an ENA, to be voted upon.
// 20. `voteOnENAGovernanceProposal`: Allows ENA shareholders to cast their vote (for or against) on a pending proposal.
// 21. `executeENAGovernanceProposal`: Executes a governance proposal that has passed and met its voting deadline.

// VII. Query Functions (Read-only for Transparency)
// 22. `getENAInfo`: Retrieves detailed information about a specific ENA.
// 23. `getModuleInfo`: Retrieves detailed information about a specific module within an ENA.
// 24. `getPendingContributions`: Lists all contributions awaiting approval for a given ENA.
// 25. `getActiveLicenseAgreements`: Lists all active licensing agreements for a given ENA.
// 26. `getProposalState`: Returns the current state of a governance proposal.

// VIII. Administrative Functions (Main Contract Owner)
// 27. `setApprovedExternalRevenueFeeder`: Designates an address allowed to call `recordExternalRevenue`.

contract EvolvingNexusIPCore is ERC1155, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _enaIdCounter;
    Counters.Counter private _contributionIdCounter;
    Counters.Counter private _licenseIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Mapping of ENA ID to its details
    mapping(uint256 => EvolvingNexusAsset) public enas;
    // Mapping of ENA ID to its governance proposals
    mapping(uint256 => mapping(uint256 => Proposal)) public enaProposals;
    // Mapping of ENA ID to pending contributions (indexed by _contributionIdCounter)
    mapping(uint256 => mapping(uint256 => Contribution)) public enaContributions;
    // Mapping of ENA ID to active license agreements (indexed by _licenseIdCounter)
    mapping(uint256 => mapping(uint256 => LicenseAgreement)) public enaLicenses;

    // A list of approved addresses that can feed external revenue to ENAs.
    mapping(address => bool) public approvedExternalRevenueFeeders;

    // --- Struct Definitions ---

    struct EvolvingNexusAsset {
        uint256 id;
        string name;
        string descriptionURI; // URI to off-chain details (e.g., IPFS CID)
        address creator;
        uint256 creationTimestamp;
        uint256 currentVersion;
        mapping(string => ModuleInfo) coreModules; // Module name => ModuleInfo
        string[] moduleNames; // To iterate over modules
        uint256 totalShares; // Total supply of ERC1155 tokens for this ENA
        uint256 revenueAccrued; // Total revenue accumulated in *this contract* for this ENA before transfer to treasury
        address treasuryAddress; // Designated address (usually a specialized contract) to hold and distribute revenue for this ENA
        bool isActive; // If the ENA is active and can process actions
        uint256 proposalThresholdBasisPoints; // % (e.g., 100 for 1%) of total shares needed to propose
        uint256 votingQuorumBasisPoints; // % (e.g., 2000 for 20%) of total shares needed for a proposal to pass
        uint256 votingPeriod; // Duration for voting in seconds
    }

    struct ModuleInfo {
        string name;
        string descriptionURI; // URI to module specifics (code, data, etc.)
        uint256 version;
        bool isLicensable;
        uint256 defaultLicensingFeeBasisPoints; // % (e.g., 100 for 1%) applied to total revenue generated by module
        address moduleCreator;
        uint256 creationTimestamp;
    }

    struct Contribution {
        uint256 id;
        uint256 enaId;
        address contributor;
        string description; // What was contributed
        string proofURI; // URI to proof of contribution
        uint256 timestamp;
        uint256 impactScore; // Assigned by governance, potentially tied to shares minted
        bool isApproved;
    }

    struct LicenseAgreement {
        uint256 id;
        uint256 enaId;
        string moduleName; // Empty string if licensing the whole ENA
        address licensee;
        uint256 fixedFee; // One-time fee for the license (in wei)
        uint256 revenueShareBasisPoints; // % of licensee's revenue that goes to ENA (e.g., 100 for 1%)
        uint256 duration; // in seconds (0 for perpetual)
        uint256 creationTimestamp;
        uint256 expirationTimestamp; // 0 for perpetual
        bool isActive;
        string termsURI; // Link to specific legal terms off-chain
        bool fixedFeePaid; // To ensure fixed fee is only paid once
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        uint256 id;
        uint256 enaId;
        string description;
        address proposer;
        address targetContract; // Contract to call (e.g., this contract for internal changes)
        bytes callData; // Encoded function call for execution
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Voter address => true
        mapping(address => uint256) votesCast; // Voter address => shares voted
        bool executed;
        ProposalState state;
    }

    // --- Events ---

    event ENACreated(
        uint256 indexed enaId,
        string name,
        address indexed creator,
        uint256 totalShares
    );
    event ENAStateUpdated(uint256 indexed enaId, string newDescriptionURI, uint256 newVersion);
    event ENADeactivated(uint256 indexed enaId);
    event ENAReactivated(uint256 indexed enaId);
    event ENATreasuryUpdated(uint256 indexed enaId, address indexed newTreasury);

    event ModuleAdded(
        uint256 indexed enaId,
        string moduleName,
        address indexed creator,
        string descriptionURI
    );
    event ModuleUpdated(
        uint256 indexed enaId,
        string moduleName,
        string newDescriptionURI,
        uint256 newVersion
    );
    event ModuleRemoved(uint256 indexed enaId, string moduleName);

    event SharesMinted(
        uint256 indexed enaId,
        address indexed to,
        uint256 amount
    );
    event SharesBurned(
        uint256 indexed enaId,
        address indexed from,
        uint256 amount
    );
    event RevenueDistributed(uint256 indexed enaId, uint256 distributedAmount, address indexed toTreasury);

    event ContributionSubmitted(
        uint256 indexed enaId,
        uint256 indexed contributionId,
        address indexed contributor,
        string description
    );
    event ContributionApproved(
        uint256 indexed enaId,
        uint256 indexed contributionId,
        address indexed approver,
        uint256 impactScore,
        uint256 sharesMinted
    );
    event ContributionRevoked(
        uint256 indexed enaId,
        uint256 indexed contributionId
    );

    event LicenseProposed(
        uint256 indexed enaId,
        uint256 indexed licenseId,
        address indexed proposer,
        address licensee
    );
    event LicenseApproved(
        uint256 indexed enaId,
        uint256 indexed licenseId,
        address indexed approver
    );
    event LicensePaymentMade(
        uint256 indexed enaId,
        uint256 indexed licenseId,
        address indexed payer,
        uint256 amount
    );
    event ExternalRevenueRecorded(uint256 indexed enaId, uint256 amount, address indexed recordedBy);

    event ProposalCreated(
        uint256 indexed enaId,
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 votingDeadline
    );
    event VoteCast(
        uint256 indexed enaId,
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 sharesVoted
    );
    event ProposalStateChanged(
        uint256 indexed enaId,
        uint256 indexed proposalId,
        ProposalState newState
    );
    event ProposalExecuted(uint256 indexed enaId, uint256 indexed proposalId);

    event ApprovedExternalRevenueFeederSet(address indexed feeder, bool approved);

    // --- Constructor ---

    constructor(string memory uri_) ERC1155(uri_) Ownable(msg.sender) {
        // uri_ could be a base URI for ERC1155 metadata, e.g., "https://ipfs.io/ipfs/{id}"
    }

    // --- Modifiers ---

    modifier onlyENAShareholder(uint256 _enaId) {
        if (balanceOf(msg.sender, _enaId) == 0) revert InsufficientShares(_enaId, msg.sender, 1, 0);
        _;
    }

    modifier onlyENAActive(uint256 _enaId) {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);
        if (!enas[_enaId].isActive) revert ENAInactive(_enaId);
        _;
    }

    modifier onlyApprovedFeeder() {
        require(approvedExternalRevenueFeeders[msg.sender], "ENACore: Not an approved external revenue feeder");
        _;
    }

    // --- Error Types ---
    error InvalidENAId(uint256 enaId);
    error ENAInactive(uint256 enaId);
    error ModuleNotFound(uint256 enaId, string moduleName);
    error ModuleAlreadyExists(uint256 enaId, string moduleName);
    error InsufficientShares(uint256 enaId, address shareholder, uint256 required, uint256 current);
    error InvalidContribution(uint256 enaId, uint256 contributionId);
    error InvalidLicense(uint256 enaId, uint256 licenseId);
    error LicenseNotActive(uint256 enaId, uint256 licenseId);
    error InvalidProposal(uint256 enaId, uint256 proposalId);
    error ProposalNotExecutable(uint256 enaId, uint256 proposalId, ProposalState currentState);
    error ProposalThresholdNotMet(uint256 enaId, uint256 sharesRequired, uint256 sharesHeld);
    error VotingPeriodEnded(uint256 enaId, uint256 proposalId);
    error AlreadyVoted(uint256 enaId, uint256 proposalId, address voter);
    error NoRevenueToDistribute(uint256 enaId);
    error ZeroAmount();
    error ZeroShares();
    error NewVersionMustBeHigher(uint256 current, uint256 newVersion);
    error LicenseFixedFeeAlreadyPaid();


    // --- I. ENA Management ---

    /// @notice Creates a new Evolving Nexus Asset (ENA) with initial modules.
    /// @param _name The name of the ENA.
    /// @param _descriptionURI URI pointing to the ENA's detailed description (e.g., IPFS hash).
    /// @param _initialModuleNames Array of names for initial modules.
    /// @param _initialModuleURIs Array of URIs for initial modules.
    /// @param _totalShares Initial total fractional shares to mint for this ENA.
    /// @param _initialTreasury The address to set as the initial treasury for this ENA.
    /// @param _proposalThresholdBasisPoints Percentage (e.g., 100 for 1%) of total shares needed to propose.
    /// @param _votingQuorumBasisPoints Percentage (e.g., 2000 for 20%) of total shares needed for a proposal to pass.
    /// @param _votingPeriod Duration in seconds for a voting period.
    /// @dev Mints all initial shares to the creator. The `id` of the ENA also serves as its ERC1155 token ID.
    function createEvolvingNexusAsset(
        string memory _name,
        string memory _descriptionURI,
        string[] memory _initialModuleNames,
        string[] memory _initialModuleURIs,
        uint256 _totalShares,
        address _initialTreasury,
        uint256 _proposalThresholdBasisPoints,
        uint256 _votingQuorumBasisPoints,
        uint256 _votingPeriod
    ) external onlyOwner returns (uint256 enaId_) {
        require(_totalShares > 0, "ENACore: Initial shares must be greater than zero");
        require(_initialModuleNames.length == _initialModuleURIs.length, "ENACore: Module names and URIs mismatch");
        require(_initialTreasury != address(0), "ENACore: Initial treasury cannot be zero address");
        require(_votingPeriod > 0, "ENACore: Voting period must be greater than zero");
        require(_proposalThresholdBasisPoints <= 10000, "ENACore: Proposal threshold must be <= 10000 (100%)");
        require(_votingQuorumBasisPoints <= 10000, "ENACore: Voting quorum must be <= 10000 (100%)");


        _enaIdCounter.increment();
        uint256 newId = _enaIdCounter.current();

        EvolvingNexusAsset storage newENA = enas[newId];
        newENA.id = newId;
        newENA.name = _name;
        newENA.descriptionURI = _descriptionURI;
        newENA.creator = msg.sender;
        newENA.creationTimestamp = block.timestamp;
        newENA.currentVersion = 1;
        newENA.totalShares = _totalShares;
        newENA.revenueAccrued = 0; // Starts at 0, accumulates within this contract
        newENA.treasuryAddress = _initialTreasury;
        newENA.isActive = true;
        newENA.proposalThresholdBasisPoints = _proposalThresholdBasisPoints;
        newENA.votingQuorumBasisPoints = _votingQuorumBasisPoints;
        newENA.votingPeriod = _votingPeriod;

        for (uint256 i = 0; i < _initialModuleNames.length; i++) {
            require(bytes(_initialModuleNames[i]).length > 0, "ENACore: Module name cannot be empty");
            if (bytes(newENA.coreModules[_initialModuleNames[i]].name).length > 0) revert ModuleAlreadyExists(newId, _initialModuleNames[i]);

            newENA.coreModules[_initialModuleNames[i]] = ModuleInfo({
                name: _initialModuleNames[i],
                descriptionURI: _initialModuleURIs[i],
                version: 1,
                isLicensable: false, // Default to not licensable, can be changed by governance
                defaultLicensingFeeBasisPoints: 0,
                moduleCreator: msg.sender,
                creationTimestamp: block.timestamp
            });
            newENA.moduleNames.push(_initialModuleNames[i]);
            emit ModuleAdded(newId, _initialModuleNames[i], msg.sender, _initialModuleURIs[i]);
        }

        // Mint initial shares to the creator
        _mint(msg.sender, newId, _totalShares, ""); // The ENA ID is also the token ID for its shares
        emit SharesMinted(newId, msg.sender, _totalShares);

        emit ENACreated(newId, _name, msg.sender, _totalShares);
        enaId_ = newId;
    }

    /// @notice Allows governance to update an ENA's overall state, description, and version.
    /// @param _enaId The ID of the ENA to update.
    /// @param _newDescriptionURI The new URI for the ENA's description.
    /// @param _newVersion The new version number for the ENA.
    /// @dev This function is intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function updateENAState(
        uint256 _enaId,
        string memory _newDescriptionURI,
        uint256 _newVersion
    ) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        // Allow direct call by creator/owner for demonstration; in a full DAO, it would be `require(msg.sender == address(this))`
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to update ENA state directly");
        if (_newVersion <= ena.currentVersion) revert NewVersionMustBeHigher(ena.currentVersion, _newVersion);

        ena.descriptionURI = _newDescriptionURI;
        ena.currentVersion = _newVersion;
        emit ENAStateUpdated(_enaId, _newDescriptionURI, _newVersion);
    }

    /// @notice Pauses an ENA, preventing further actions until reactivated.
    /// @param _enaId The ID of the ENA to deactivate.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function deactivateENA(uint256 _enaId) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to deactivate ENA directly");

        ena.isActive = false;
        emit ENADeactivated(_enaId);
    }

    /// @notice Unpauses a deactivated ENA.
    /// @param _enaId The ID of the ENA to reactivate.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function reactivateENA(uint256 _enaId) external {
        EvolvingNexusAsset storage ena = enas[_enaId];
        if (bytes(ena.name).length == 0) revert InvalidENAId(_enaId);
        require(!ena.isActive, "ENACore: ENA is already active");
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to reactivate ENA directly");

        ena.isActive = true;
        emit ENAReactivated(_enaId);
    }

    /// @notice Changes the designated treasury address for an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _newTreasury The new treasury address.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function setENATreasury(uint256 _enaId, address _newTreasury) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(_newTreasury != address(0), "ENACore: New treasury cannot be zero address");
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to set ENA treasury directly");

        ena.treasuryAddress = _newTreasury;
        emit ENATreasuryUpdated(_enaId, _newTreasury);
    }

    // --- II. Module Management ---

    /// @notice Adds a new, distinct module to an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _moduleName The name of the new module.
    /// @param _moduleDescriptionURI URI for the module's details.
    /// @param _isLicensable Whether this module can be licensed independently.
    /// @param _defaultLicensingFeeBasisPoints Default fee percentage for licensing this module.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function addModuleToENA(
        uint256 _enaId,
        string memory _moduleName,
        string memory _moduleDescriptionURI,
        bool _isLicensable,
        uint256 _defaultLicensingFeeBasisPoints
    ) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(bytes(_moduleName).length > 0, "ENACore: Module name cannot be empty");
        if (bytes(ena.coreModules[_moduleName].name).length > 0) revert ModuleAlreadyExists(_enaId, _moduleName);
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to add module directly");

        ena.coreModules[_moduleName] = ModuleInfo({
            name: _moduleName,
            descriptionURI: _moduleDescriptionURI,
            version: 1,
            isLicensable: _isLicensable,
            defaultLicensingFeeBasisPoints: _defaultLicensingFeeBasisPoints,
            moduleCreator: msg.sender, // The one who initiates the addition (via proposal)
            creationTimestamp: block.timestamp
        });
        ena.moduleNames.push(_moduleName);
        emit ModuleAdded(_enaId, _moduleName, msg.sender, _moduleDescriptionURI);
    }

    /// @notice Allows governance to update an existing module's details, version, and licensing parameters.
    /// @param _enaId The ID of the ENA.
    /// @param _moduleName The name of the module to update.
    /// @param _newDescriptionURI New URI for the module's details.
    /// @param _newVersion New version number for the module.
    /// @param _isLicensable Whether this module can be licensed independently.
    /// @param _newDefaultLicensingFeeBasisPoints New default fee percentage for licensing.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function updateModule(
        uint256 _enaId,
        string memory _moduleName,
        string memory _newDescriptionURI,
        uint256 _newVersion,
        bool _isLicensable,
        uint256 _newDefaultLicensingFeeBasisPoints
    ) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        ModuleInfo storage module = ena.coreModules[_moduleName];
        if (bytes(module.name).length == 0) revert ModuleNotFound(_enaId, _moduleName);
        if (_newVersion <= module.version) revert NewVersionMustBeHigher(module.version, _newVersion);
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to update module directly");

        module.descriptionURI = _newDescriptionURI;
        module.version = _newVersion;
        module.isLicensable = _isLicensable;
        module.defaultLicensingFeeBasisPoints = _newDefaultLicensingFeeBasisPoints;
        emit ModuleUpdated(_enaId, _moduleName, _newDescriptionURI, _newVersion);
    }

    /// @notice Removes a module from an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _moduleName The name of the module to remove.
    /// @dev This can be a sensitive operation and should be protected by strong governance.
    ///      Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function removeModuleFromENA(uint256 _enaId, string memory _moduleName)
        external
        onlyENAActive(_enaId)
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        ModuleInfo storage module = ena.coreModules[_moduleName];
        if (bytes(module.name).length == 0) revert ModuleNotFound(_enaId, _moduleName);
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to remove module directly");

        // Simple removal, effectively deleting the module by name.
        // For robustness, consider if there are active licenses related to this module.
        // This implementation does not check for active licenses and does not invalidate them.
        delete ena.coreModules[_moduleName];

        // Remove from moduleNames array.
        for (uint256 i = 0; i < ena.moduleNames.length; i++) {
            if (keccak256(abi.encodePacked(ena.moduleNames[i])) == keccak256(abi.encodePacked(_moduleName))) {
                ena.moduleNames[i] = ena.moduleNames[ena.moduleNames.length - 1];
                ena.moduleNames.pop();
                break;
            }
        }
        emit ModuleRemoved(_enaId, _moduleName);
    }

    // --- III. Fractional Ownership & Revenue Aggregation ---

    /// @notice Mints new fractional shares for a specific ENA to a recipient.
    /// @param _enaId The ID of the ENA.
    /// @param _to The recipient address.
    /// @param _amount The number of shares to mint.
    /// @dev Only callable by the ENA's creator or the main contract owner (intended for governance approval).
    function mintENAShares(uint256 _enaId, address _to, uint256 _amount)
        external
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(_to != address(0), "ENACore: Cannot mint to zero address");
        if (_amount == 0) revert ZeroAmount();
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to mint shares directly");

        _mint(_to, _enaId, _amount, "");
        ena.totalShares += _amount;
        emit SharesMinted(_enaId, _to, _amount);
    }

    /// @notice Burns fractional shares from a holder.
    /// @param _enaId The ID of the ENA.
    /// @param _from The address from which to burn shares.
    /// @param _amount The number of shares to burn.
    /// @dev Only callable by the ENA's creator or the main contract owner (intended for governance approval).
    function burnENAShares(uint256 _enaId, address _from, uint256 _amount)
        external
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(_from != address(0), "ENACore: Cannot burn from zero address");
        if (_amount == 0) revert ZeroAmount();
        if (balanceOf(_from, _enaId) < _amount) revert InsufficientShares(_enaId, _from, _amount, balanceOf(_from, _enaId));
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to burn shares directly");

        _burn(_from, _enaId, _amount);
        ena.totalShares -= _amount;
        emit SharesBurned(_enaId, _from, _amount);
    }

    /// @notice Aggregates all revenue (ETH) collected by *this contract* for a specific ENA
    ///         and transfers it to the ENA's designated `treasuryAddress`.
    /// @param _enaId The ID of the ENA.
    /// @dev The `treasuryAddress` is expected to be a smart contract capable of managing and distributing claims
    ///      to individual shareholders. This function clears the `revenueAccrued` balance in this contract.
    ///      Callable by ENA creator or contract owner (intended for governance approval).
    function distributeRevenueToShareholders(uint256 _enaId)
        external
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        if (ena.revenueAccrued == 0) revert NoRevenueToDistribute(_enaId);
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to distribute revenue directly");

        uint256 amountToDistribute = ena.revenueAccrued;
        ena.revenueAccrued = 0; // Reset before distribution

        (bool success, ) = ena.treasuryAddress.call{value: amountToDistribute}("");
        require(success, "ENACore: Failed to transfer revenue to treasury");

        emit RevenueDistributed(_enaId, amountToDistribute, ena.treasuryAddress);
    }


    // --- IV. Contribution & Reputation System ---

    /// @notice Allows a user to propose a contribution to an ENA, detailing their work.
    /// @param _enaId The ID of the ENA.
    /// @param _description A description of the contribution.
    /// @param _proofURI URI pointing to proof of the contribution (e.g., GitHub PR, research paper).
    function submitContribution(
        uint256 _enaId,
        string memory _description,
        string memory _proofURI
    ) external onlyENAActive(_enaId) {
        require(bytes(_description).length > 0, "ENACore: Contribution description cannot be empty");

        _contributionIdCounter.increment();
        uint256 newContributionId = _contributionIdCounter.current();

        enaContributions[_enaId][newContributionId] = Contribution({
            id: newContributionId,
            enaId: _enaId,
            contributor: msg.sender,
            description: _description,
            proofURI: _proofURI,
            timestamp: block.timestamp,
            impactScore: 0, // Assigned upon approval
            isApproved: false
        });
        emit ContributionSubmitted(_enaId, newContributionId, msg.sender, _description);
    }

    /// @notice ENA governance approves a pending contribution, assigning an impact score.
    /// @param _enaId The ID of the ENA.
    /// @param _contributionId The ID of the contribution to approve.
    /// @param _impactScore The assigned impact score for the contribution.
    /// @param _sharesToMint Additional shares to mint to the contributor as reward.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function approveContribution(
        uint256 _enaId,
        uint256 _contributionId,
        uint256 _impactScore,
        uint256 _sharesToMint
    ) external onlyENAActive(_enaId) nonReentrant {
        EvolvingNexusAsset storage ena = enas[_enaId];
        Contribution storage contribution = enaContributions[_enaId][_contributionId];
        if (contribution.enaId == 0 || contribution.enaId != _enaId) revert InvalidContribution(_enaId, _contributionId); // Also checks _enaId validity
        require(!contribution.isApproved, "ENACore: Contribution already approved");
        require(_impactScore > 0, "ENACore: Impact score must be greater than zero");
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to approve contribution directly");

        contribution.isApproved = true;
        contribution.impactScore = _impactScore;

        if (_sharesToMint > 0) {
            _mint(contribution.contributor, _enaId, _sharesToMint, "");
            ena.totalShares += _sharesToMint;
            emit SharesMinted(_enaId, contribution.contributor, _sharesToMint);
        }
        emit ContributionApproved(_enaId, _contributionId, msg.sender, _impactScore, _sharesToMint);
    }

    /// @notice Reverts an approved contribution, adjusting impact score.
    /// @param _enaId The ID of the ENA.
    /// @param _contributionId The ID of the contribution to revoke.
    /// @dev This is a powerful action and should be protected by strong governance.
    ///      Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function revokeContributionApproval(uint256 _enaId, uint256 _contributionId)
        external
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        Contribution storage contribution = enaContributions[_enaId][_contributionId];
        if (contribution.enaId == 0 || contribution.enaId != _enaId) revert InvalidContribution(_enaId, _contributionId); // Also checks _enaId validity
        require(contribution.isApproved, "ENACore: Contribution is not approved");
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to revoke contribution directly");

        // If shares were minted specifically for this contribution and tracked, they would be burned here.
        // For simplicity, this example just revokes approval and resets impact score.
        contribution.isApproved = false;
        contribution.impactScore = 0; // Reset impact score

        emit ContributionRevoked(_enaId, _contributionId);
    }

    // --- V. Licensing & Revenue Collection ---

    /// @notice Initiates a proposal for a new licensing agreement for an ENA or a specific module within it.
    /// @param _enaId The ID of the ENA.
    /// @param _moduleName The name of the module to license (empty string for whole ENA).
    /// @param _licensee The address of the party seeking the license.
    /// @param _fixedFee One-time fixed fee for the license in wei.
    /// @param _revenueShareBasisPoints Percentage (e.g., 100 for 1%) of licensee's revenue that goes to ENA.
    /// @param _duration Duration of the license in seconds (0 for perpetual).
    /// @param _termsURI URI to the detailed legal terms of the agreement.
    /// @dev The proposal must be approved by ENA governance to become active.
    function proposeLicenseAgreement(
        uint256 _enaId,
        string memory _moduleName,
        address _licensee,
        uint256 _fixedFee,
        uint256 _revenueShareBasisPoints,
        uint256 _duration,
        string memory _termsURI
    ) external onlyENAActive(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(_licensee != address(0), "ENACore: Licensee cannot be zero address");
        if (bytes(_moduleName).length > 0) {
            ModuleInfo storage module = ena.coreModules[_moduleName];
            if (bytes(module.name).length == 0) revert ModuleNotFound(_enaId, _moduleName);
            require(module.isLicensable, "ENACore: Module is not licensable");
        }
        require(_revenueShareBasisPoints <= 10000, "ENACore: Revenue share must be <= 10000 (100%)");

        _licenseIdCounter.increment();
        uint256 newLicenseId = _licenseIdCounter.current();

        enaLicenses[_enaId][newLicenseId] = LicenseAgreement({
            id: newLicenseId,
            enaId: _enaId,
            moduleName: _moduleName,
            licensee: _licensee,
            fixedFee: _fixedFee,
            revenueShareBasisPoints: _revenueShareBasisPoints,
            duration: _duration,
            creationTimestamp: block.timestamp,
            expirationTimestamp: _duration == 0 ? 0 : block.timestamp + _duration,
            isActive: false, // Must be approved by governance
            termsURI: _termsURI,
            fixedFeePaid: false
        });
        emit LicenseProposed(_enaId, newLicenseId, msg.sender, _licensee);
    }

    /// @notice ENA governance approves a proposed license, making it active.
    /// @param _enaId The ID of the ENA.
    /// @param _licenseId The ID of the license agreement to approve.
    /// @dev Intended to be called via a successful governance proposal.
    ///      For demonstration purposes, it can also be called directly by the ENA's creator or main contract owner.
    function approveLicenseAgreement(uint256 _enaId, uint256 _licenseId)
        external
        onlyENAActive(_enaId)
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        LicenseAgreement storage license = enaLicenses[_enaId][_licenseId];
        if (license.enaId == 0 || license.enaId != _enaId) revert InvalidLicense(_enaId, _licenseId); // Also checks _enaId validity
        require(!license.isActive, "ENACore: License is already active");
        // Allow direct call by creator/owner for demonstration
        require(msg.sender == ena.creator || msg.sender == owner(), "ENACore: Unauthorized to approve license directly");

        license.isActive = true;
        emit LicenseApproved(_enaId, _licenseId, msg.sender);
    }

    /// @notice Allows a licensee to make a fixed fee payment for an active license.
    /// @param _enaId The ID of the ENA.
    /// @param _licenseId The ID of the license agreement.
    /// @dev Transfers the `fixedFee` to this contract, which then aggregates it for distribution to the ENA's treasury.
    function executeLicensePayment(uint256 _enaId, uint256 _licenseId)
        external
        payable
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        LicenseAgreement storage license = enaLicenses[_enaId][_licenseId];
        if (license.enaId == 0 || license.enaId != _enaId) revert InvalidLicense(_enaId, _licenseId); // Also checks _enaId validity
        if (!license.isActive) revert LicenseNotActive(_enaId, _licenseId);
        require(msg.sender == license.licensee, "ENACore: Only the licensee can make this payment");
        if (license.fixedFee == 0) revert("ENACore: This license has no fixed fee");
        if (license.fixedFeePaid) revert LicenseFixedFeeAlreadyPaid();
        require(msg.value >= license.fixedFee, "ENACore: Insufficient payment amount for fixed fee");

        // Accumulate revenue in this contract
        ena.revenueAccrued += license.fixedFee;
        license.fixedFeePaid = true;

        // Refund any excess payment
        if (msg.value > license.fixedFee) {
            (bool success, ) = msg.sender.call{value: msg.value - license.fixedFee}("");
            require(success, "ENACore: Failed to refund excess payment");
        }

        emit LicensePaymentMade(_enaId, _licenseId, msg.sender, license.fixedFee);
    }

    /// @notice Allows an authorized external agent to record revenue generated off-chain for an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _amount The amount of revenue (in wei) generated externally.
    /// @dev This function should be called by an approved external feeder (e.g., an oracle, an off-chain sales platform).
    ///      Funds sent with this transaction are accumulated by this contract in `ena.revenueAccrued`.
    function recordExternalRevenue(uint256 _enaId, uint256 _amount)
        external
        payable
        onlyENAActive(_enaId)
        onlyApprovedFeeder
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        if (_amount == 0) revert ZeroAmount();
        require(msg.value == _amount, "ENACore: Sent ETH must match specified amount");

        // Accumulate revenue in this contract
        ena.revenueAccrued += _amount;

        emit ExternalRevenueRecorded(_enaId, _amount, msg.sender);
    }

    // --- VI. On-chain Governance ---

    /// @notice Allows shareholders to propose a specific action or change for an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _description A description of the proposal.
    /// @param _targetContract The address of the contract to execute the action on (usually `this` contract).
    /// @param _callData Encoded function call data for the proposed action.
    /// @dev Requires the proposer to hold a minimum percentage of ENA shares.
    function proposeENAGovernanceAction(
        uint256 _enaId,
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external onlyENAActive(_enaId) onlyENAShareholder(_enaId) {
        EvolvingNexusAsset storage ena = enas[_enaId];
        require(bytes(_description).length > 0, "ENACore: Proposal description cannot be empty");

        uint256 proposerShares = balanceOf(msg.sender, _enaId);
        uint256 requiredShares = (ena.totalShares * ena.proposalThresholdBasisPoints) / 10000;
        if (proposerShares < requiredShares) {
            revert ProposalThresholdNotMet(_enaId, requiredShares, proposerShares);
        }

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        enaProposals[_enaId][newProposalId] = Proposal({
            id: newProposalId,
            enaId: _enaId,
            description: _description,
            proposer: msg.sender,
            targetContract: _targetContract,
            callData: _callData,
            votingDeadline: block.timestamp + ena.votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            votesCast: new mapping(address => uint256),
            executed: false,
            state: ProposalState.Active
        });
        emit ProposalCreated(_enaId, newProposalId, msg.sender, _description, block.timestamp + ena.votingPeriod);
    }

    /// @notice Allows ENA shareholders to cast their vote on a pending proposal.
    /// @param _enaId The ID of the ENA.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _voteFor True for 'for', false for 'against'.
    function voteOnENAGovernanceProposal(uint256 _enaId, uint256 _proposalId, bool _voteFor)
        external
        onlyENAActive(_enaId)
        onlyENAShareholder(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        Proposal storage proposal = enaProposals[_enaId][_proposalId];
        if (proposal.enaId == 0 || proposal.enaId != _enaId) revert InvalidProposal(_enaId, _proposalId); // Also checks _enaId validity
        require(proposal.state == ProposalState.Active, "ENACore: Proposal is not in active state");
        if (block.timestamp >= proposal.votingDeadline) revert VotingPeriodEnded(_enaId, _proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_enaId, _proposalId, msg.sender);

        uint256 voterShares = balanceOf(msg.sender, _enaId);
        if (voterShares == 0) revert InsufficientShares(_enaId, msg.sender, 1, 0); // Should be caught by onlyENAShareholder

        if (_voteFor) {
            proposal.votesFor += voterShares;
        } else {
            proposal.votesAgainst += voterShares;
        }
        proposal.hasVoted[msg.sender] = true;
        proposal.votesCast[msg.sender] = voterShares;

        emit VoteCast(_enaId, _proposalId, msg.sender, _voteFor, voterShares);
    }

    /// @notice Executes a governance proposal that has passed and met its voting deadline.
    /// @param _enaId The ID of the ENA.
    /// @param _proposalId The ID of the proposal to execute.
    /// @dev Can be called by anyone after the voting deadline, if the proposal has passed.
    function executeENAGovernanceProposal(uint256 _enaId, uint256 _proposalId)
        external
        onlyENAActive(_enaId)
        nonReentrant
    {
        EvolvingNexusAsset storage ena = enas[_enaId];
        Proposal storage proposal = enaProposals[_enaId][_proposalId];
        if (proposal.enaId == 0 || proposal.enaId != _enaId) revert InvalidProposal(_enaId, _proposalId); // Also checks _enaId validity

        if (proposal.state != ProposalState.Active) {
            revert ProposalNotExecutable(_enaId, _proposalId, proposal.state);
        }
        if (block.timestamp < proposal.votingDeadline) {
            revert ProposalNotExecutable(_enaId, _proposalId, ProposalState.Pending);
        }
        if (proposal.executed) {
            revert ProposalNotExecutable(_enaId, _proposalId, ProposalState.Executed);
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumRequired = (ena.totalShares * ena.votingQuorumBasisPoints) / 10000;

        if (totalVotes < quorumRequired) {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_enaId, _proposalId, ProposalState.Defeated);
            revert ProposalNotExecutable(_enaId, _proposalId, ProposalState.Defeated);
        }

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(_enaId, _proposalId, ProposalState.Succeeded);

            // Execute the proposed action
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "ENACore: Proposal execution failed");

            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_enaId, _proposalId);
        } else {
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_enaId, _proposalId, ProposalState.Defeated);
        }
    }

    // --- VII. Query Functions ---

    /// @notice Retrieves detailed information about a specific ENA.
    /// @param _enaId The ID of the ENA.
    /// @return EvolvingNexusAsset struct containing ENA details.
    function getENAInfo(uint256 _enaId)
        external
        view
        returns (EvolvingNexusAsset memory)
    {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);
        // Deep copy struct to avoid storage pointers being returned directly, which can lead to unexpected behavior.
        EvolvingNexusAsset storage enaStorage = enas[_enaId];
        EvolvingNexusAsset memory enaMemory = EvolvingNexusAsset({
            id: enaStorage.id,
            name: enaStorage.name,
            descriptionURI: enaStorage.descriptionURI,
            creator: enaStorage.creator,
            creationTimestamp: enaStorage.creationTimestamp,
            currentVersion: enaStorage.currentVersion,
            // coreModules mapping cannot be returned directly from storage in memory,
            // moduleNames array provides keys for individual module lookups.
            moduleNames: enaStorage.moduleNames,
            totalShares: enaStorage.totalShares,
            revenueAccrued: enaStorage.revenueAccrued,
            treasuryAddress: enaStorage.treasuryAddress,
            isActive: enaStorage.isActive,
            proposalThresholdBasisPoints: enaStorage.proposalThresholdBasisPoints,
            votingQuorumBasisPoints: enaStorage.votingQuorumBasisPoints,
            votingPeriod: enaStorage.votingPeriod
        });
        return enaMemory;
    }


    /// @notice Retrieves detailed information about a specific module within an ENA.
    /// @param _enaId The ID of the ENA.
    /// @param _moduleName The name of the module.
    /// @return ModuleInfo struct containing module details.
    function getModuleInfo(uint256 _enaId, string memory _moduleName)
        external
        view
        returns (ModuleInfo memory)
    {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);
        ModuleInfo storage module = enas[_enaId].coreModules[_moduleName];
        if (bytes(module.name).length == 0) revert ModuleNotFound(_enaId, _moduleName);
        return module;
    }

    /// @notice Lists all contributions awaiting approval for a given ENA.
    /// @param _enaId The ID of the ENA.
    /// @return An array of Contribution structs for pending contributions.
    /// @dev This might be inefficient if there are many contributions with high `_contributionIdCounter`.
    ///      For production, consider off-chain indexing or a more advanced on-chain data structure (e.g., paginated).
    function getPendingContributions(uint256 _enaId)
        external
        view
        returns (Contribution[] memory)
    {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);

        uint256 pendingCount = 0;
        uint256 currentContributionId = _contributionIdCounter.current();
        for (uint256 i = 1; i <= currentContributionId; i++) {
            if (enaContributions[_enaId][i].enaId == _enaId && !enaContributions[_enaId][i].isApproved) {
                pendingCount++;
            }
        }

        Contribution[] memory pendingContributions = new Contribution[](pendingCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= currentContributionId; i++) {
            if (enaContributions[_enaId][i].enaId == _enaId && !enaContributions[_enaId][i].isApproved) {
                pendingContributions[currentIndex] = enaContributions[_enaId][i];
                currentIndex++;
            }
        }
        return pendingContributions;
    }

    /// @notice Lists all active licensing agreements for a given ENA.
    /// @param _enaId The ID of the ENA.
    /// @return An array of LicenseAgreement structs for active licenses.
    /// @dev This might be inefficient if there are many licenses with high `_licenseIdCounter`.
    ///      For production, consider off-chain indexing or a more advanced on-chain data structure (e.g., paginated).
    function getActiveLicenseAgreements(uint256 _enaId)
        external
        view
        returns (LicenseAgreement[] memory)
    {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);

        uint256 activeCount = 0;
        uint256 currentLicenseId = _licenseIdCounter.current();
        for (uint256 i = 1; i <= currentLicenseId; i++) {
            if (enaLicenses[_enaId][i].enaId == _enaId && enaLicenses[_enaId][i].isActive && (enaLicenses[_enaId][i].duration == 0 || block.timestamp < enaLicenses[_enaId][i].expirationTimestamp)) {
                activeCount++;
            }
        }

        LicenseAgreement[] memory activeLicenses = new LicenseAgreement[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= currentLicenseId; i++) {
            if (enaLicenses[_enaId][i].enaId == _enaId && enaLicenses[_enaId][i].isActive && (enaLicenses[_enaId][i].duration == 0 || block.timestamp < enaLicenses[_enaId][i].expirationTimestamp)) {
                activeLicenses[currentIndex] = enaLicenses[_enaId][i];
                currentIndex++;
            }
        }
        return activeLicenses;
    }

    /// @notice Gets the current state of a governance proposal.
    /// @param _enaId The ID of the ENA.
    /// @param _proposalId The ID of the proposal.
    /// @return The current ProposalState enum.
    function getProposalState(uint256 _enaId, uint256 _proposalId)
        external
        view
        returns (ProposalState)
    {
        if (bytes(enas[_enaId].name).length == 0) revert InvalidENAId(_enaId);
        Proposal storage proposal = enaProposals[_enaId][_proposalId];
        if (proposal.enaId == 0) revert InvalidProposal(_enaId, _proposalId);

        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.state == ProposalState.Succeeded) { // If it succeeded but not yet executed
            return ProposalState.Succeeded;
        }
        if (block.timestamp >= proposal.votingDeadline && proposal.state == ProposalState.Active) {
            // Check if it passed quorum and votes
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 quorumRequired = (enas[_enaId].totalShares * enas[_enaId].votingQuorumBasisPoints) / 10000;

            if (totalVotes >= quorumRequired && proposal.votesFor > proposal.votesAgainst) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        return proposal.state;
    }

    // --- VIII. Administrative Functions (Main Contract Owner) ---

    /// @notice Designates an address allowed to call `recordExternalRevenue`.
    /// @param _feeder The address to approve or unapprove.
    /// @param _approved True to approve, false to unapprove.
    function setApprovedExternalRevenueFeeder(address _feeder, bool _approved)
        external
        onlyOwner
    {
        require(_feeder != address(0), "ENACore: Feeder address cannot be zero");
        approvedExternalRevenueFeeders[_feeder] = _approved;
        emit ApprovedExternalRevenueFeederSet(_feeder, _approved);
    }

    // Fallback function to receive Ether
    receive() external payable {
        // Revert to prevent accidental Ether transfers to the main contract address
        // unless they are explicitly part of a function call (e.g., executeLicensePayment).
        revert("ENACore: Direct Ether reception not supported, use specific functions for revenue.");
    }
}
```