Here's a smart contract written in Solidity that embodies several advanced, creative, and trendy concepts, designed to avoid direct duplication of existing open-source projects while offering a comprehensive feature set.

This contract, `VeridianProtocol`, acts as a decentralized autonomous research and development hub. It integrates elements of Decentralized Science (DeSci), dynamic on-chain reputation systems, AI-assisted proposal/milestone evaluation (via oracle), and a novel conditional funding mechanism, alongside robust intellectual property (IP) management and revenue sharing.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Used for explicit clarity, though Solidity 0.8+ has overflow checks

/**
 * @title VeridianProtocol
 * @dev A Decentralized Autonomous Research & Development Hub.
 *      This contract facilitates the lifecycle of research projects, from proposal submission and AI-assisted
 *      evaluation, through funding and milestone completion, to intellectual property (IP) registration
 *      and revenue sharing. It incorporates dynamic researcher reputation, conditional funding intents,
 *      and oracle-driven AI integration for decision support, aiming for a transparent and meritocratic
 *      research ecosystem.
 *
 * @outline
 * I. Core Platform Management & Access Control: Functions for initial setup, role management (Admin, DAO, Oracle),
 *    fee configuration, and emergency pause/unpause mechanisms.
 * II. Researcher Profile & Reputation System: Manages unique researcher identities, their dynamic reputation scores
 *     (influenced by project success/failure and delegation), and profile ownership. These profiles act as conceptual dNFTs.
 * III. Project Lifecycle Management: Covers the entire journey of a research project, from proposal submission,
 *     AI-based screening, community/DAO approval for funding, public funding, milestone reporting, oracle-verified
 *     milestone completion, to finalization and malpractice resolution.
 * IV. Intellectual Property (IP) & Revenue Sharing: Enables registration of IP for completed projects, management
 *     of IP ownership, licensing to external parties, and on-chain distribution of generated revenue among collaborators.
 * V. Conditional Funding & Intent System: A sophisticated mechanism allowing funders to create "intent-based"
 *    commitments, where funds are released to a project only when predefined conditions (e.g., minimum AI score,
 *    specific milestone completion) are met, promoting trustless and outcome-driven investments.
 *
 * @function_summary
 * I. Core Platform Management & Access Control
 * 1.  constructor(): Initializes the contract, setting the deployer as initial Admin, DAO Executor, and Oracle.
 * 2.  updateOracleAddress(address _newOracle): Sets the trusted AI evaluation oracle address. Callable by Admin.
 * 3.  updateDAOExecutorAddress(address _newExecutor): Sets the address authorized to execute DAO-approved actions. Callable by Admin.
 * 4.  setProtocolFees(uint256 _proposalFee, uint256 _ipRegFee, uint256 _milestoneEvalFee): Configures various protocol fees (e.g., for proposals, IP registration, milestone evaluations). Callable by DAO.
 * 5.  setMinReputationToPropose(uint256 _minRep): Sets the minimum effective reputation a researcher needs to submit a proposal. Callable by DAO.
 * 6.  togglePause(): Pauses/unpauses all critical contract functionality for emergency situations. Callable by Admin.
 * 7.  withdrawProtocolFees(address _to, uint256 _amount): Allows the DAO to withdraw accumulated protocol fees. Callable by DAO.
 * 8.  upgradeContract(address _newImplementation): Conceptual function for future contract upgrades, assuming a proxy pattern. Callable by Admin.
 *
 * II. Researcher Profile & Reputation System
 * 9.  registerResearcher(string memory _name, string memory _profileURI): Creates a unique researcher profile (conceptual dNFT) for the caller, with initial metadata.
 * 10. updateResearcherProfile(uint256 _researcherId, string memory _newProfileURI): Updates the metadata URI of an existing researcher profile. Callable by researcher owner.
 * 11. delegateReputation(uint256 _fromResearcherId, uint256 _toResearcherId, uint256 _amount): Allows a researcher to temporarily boost another's effective reputation. Callable by delegator owner.
 * 12. undelegateReputation(uint256 _fromResearcherId, uint256 _toResearcherId, uint256 _amount): Reclaims previously delegated reputation. Callable by delegator owner.
 * 13. getResearcherReputation(uint256 _researcherId): Retrieves the effective reputation score for a given researcher, considering delegation.
 * 14. transferResearcherProfile(uint256 _researcherId, address _newOwner): Transfers ownership of a researcher profile to a new address. Callable by current researcher owner.
 *
 * III. Project Lifecycle Management
 * 15. submitResearchProposal(uint256 _researcherId, string memory _projectURI, uint256 _fundingGoal, uint256 _numMilestones): Submits a new research project proposal, requiring minimum reputation and a fee.
 * 16. triggerAIProposalEvaluation(uint256 _projectId, uint256 _aiScore, string memory _aiFeedbackURI): Oracle-only function to record AI-generated evaluation score and feedback for a proposal.
 * 17. approveProposalForFunding(uint256 _projectId): DAO-only function to officially approve a proposal, making it eligible for public funding.
 * 18. fundProject(uint256 _projectId): Allows anyone to contribute ETH to an approved project, working towards its funding goal.
 * 19. submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneReportURI): Researcher submits a milestone report for review, paying an evaluation fee.
 * 20. triggerAIMilestoneEvaluation(uint256 _projectId, uint256 _milestoneIndex, uint256 _aiScore, string memory _aiFeedbackURI): Oracle-only function to record AI evaluation for a milestone, potentially influencing researcher reputation.
 * 21. releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex): Releases allocated funds for an approved milestone to the project creator. Callable by project creator.
 * 22. reportProjectMalpractice(uint256 _projectId, string memory _reportURI): Allows any user to flag a project for potential misconduct, triggering DAO review.
 * 23. resolveMalpracticeReport(uint256 _projectId, bool _isMalpracticeConfirmed, uint256 _punishedResearcherId): DAO-only function to resolve a malpractice report, potentially penalizing researchers or failing projects.
 * 24. finalizeProject(uint256 _projectId): Marks a project as complete after all milestones, awarding final reputation and enabling IP registration. Callable by project creator.
 *
 * IV. Intellectual Property (IP) & Revenue Sharing
 * 25. registerProjectIP(uint256 _projectId, string memory _ipURI, uint256[] memory _collaboratorResearcherIds, uint256[] memory _shares): Registers IP for a finalized project, defining ownership, documentation URI, and revenue distribution shares among collaborators. Requires a fee.
 * 26. transferIPOwnership(uint256 _ipId, address _newOwner): Transfers the ownership of a registered IP asset to a new address. Callable by current IP owner.
 * 27. licenseIP(uint256 _ipId, uint256 _termInMonths, uint256 _feeAmount, string memory _licenseURI): Allows the IP owner to grant a time-bound license for a specified fee, accruing revenue.
 * 28. collectLicenseRevenue(uint256 _ipId): A placeholder function; in this design, `distributeIPRevenue` is the primary way to access IP-generated funds.
 * 29. distributeIPRevenue(uint256 _ipId): Distributes all accrued revenue from a licensed IP among its registered collaborators based on their defined shares. Callable by IP owner.
 *
 * V. Conditional Funding & Intent System
 * 30. createConditionalFundingIntent(uint256 _projectId, uint256 _amount, uint256 _minAIThreshold, uint256 _milestoneConditionIndex): Users commit funds to a project, specifying conditions (min AI score, milestone completion) that must be met for the funds to be transferred.
 * 31. cancelFundingIntent(uint256 _intentId): Allows the creator of a conditional funding intent to reclaim their funds if the intent has not yet been executed.
 * 32. executeFundingIntent(uint256 _intentId): Callable by anyone, this function checks if an intent's conditions are met and, if so, transfers the committed funds to the project.
 */
contract VeridianProtocol is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Role Definitions ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For AI evaluation results
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE"); // For governance decisions like project approval, malpractice resolution

    // --- State Variables ---
    address public oracleAddress; // Address of the trusted AI oracle service
    address public daoExecutorAddress; // Address authorized to execute DAO-approved actions

    uint256 public proposalFee;
    uint256 public ipRegistrationFee;
    uint256 public milestoneEvaluationFee;
    uint256 public minReputationToPropose; // Minimum reputation required to submit a proposal

    bool public paused; // Emergency pause mechanism

    // --- Counters for unique IDs ---
    Counters.Counter private _researcherIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _ipIdCounter;
    Counters.Counter private _fundingIntentIdCounter;

    // --- Structs ---

    enum ProjectStatus {
        PendingEvaluation,      // Proposal submitted, awaiting AI & DAO review
        ApprovedForFunding,     // Approved, open for funding (or funding already started)
        FundingInProgress,      // Funding actively being collected
        MilestoneInProgress,    // A milestone is currently under evaluation
        MalpracticeReported,    // Project reported for misconduct, under DAO review
        Completed,              // All milestones completed, project successfully finished
        Failed,                 // Project failed (e.g., due to malpractice, or unmet goals)
        IPRegistered            // Project completed and its IP has been formally registered
    }

    // Represents a unique researcher profile, conceptually like a dNFT
    struct Researcher {
        uint256 id;
        address owner; // The wallet address controlling this researcher profile
        string name;
        string profileURI; // IPFS URI for researcher's detailed profile metadata (e.g., bio, publications)
        uint256 baseReputation; // Reputation earned through successful projects and contributions
        uint256 delegatedReputation; // Reputation received from other researchers
        uint256 delegatingReputation; // Reputation this researcher has delegated to others
    }

    // Represents a research project lifecycle
    struct Project {
        uint256 id;
        uint256 creatorResearcherId; // The ID of the researcher who initiated the project
        string projectURI; // IPFS URI for project details, scope, team, whitepaper, etc.
        uint256 fundingGoal; // Total ETH target for the project
        uint256 currentFunding; // Current ETH collected
        ProjectStatus status;
        uint256 aiEvaluationScore; // Latest AI-generated score for the project/milestone
        string aiFeedbackURI; // IPFS URI for detailed AI feedback
        uint256 numMilestones;
        uint256 completedMilestones;
        mapping(uint256 => bool) milestoneApproved; // milestoneIndex => true if approved
        uint256 ipId; // ID of the registered IP asset, 0 if not registered
        address[] funders; // List of addresses that funded the project
        mapping(address => uint256) funderContributions; // funder address => amount contributed
        mapping(uint256 => uint256) milestoneFundsAllocated; // milestoneIndex => funds allocated for it (for distribution)
        bool malpracticeReported; // Flag if malpractice has been reported
    }

    // Represents a registered Intellectual Property asset
    struct IPAsset {
        uint256 id;
        uint256 projectId; // The project ID this IP belongs to
        address owner; // Wallet address owning the IP (can be transferred)
        string ipURI; // IPFS URI for IP documentation (e.g., patent document, research paper, creative commons license)
        uint256[] collaboratorResearcherIds; // Researcher IDs of collaborators sharing revenue
        uint256[] shares; // Corresponding percentage shares for collaborators (sum to 10000 for 100.00%)
        uint256 totalCollectedRevenue; // Total revenue (from licensing) collected for this IP
        mapping(uint256 => uint256) collectedCollaboratorShare; // collaboratorId => collected share for this IP
    }

    // Represents a commitment to fund a project if specific conditions are met
    struct ConditionalFundingIntent {
        uint256 id;
        address funder; // The address creating this intent
        uint256 projectId;
        uint256 amount; // Amount of ETH committed
        uint256 minAIThreshold; // Minimum AI evaluation score the project must achieve
        uint256 milestoneConditionIndex; // 0-indexed milestone that must be completed (0 for no specific milestone condition)
        bool executed; // True if the intent has been successfully executed
    }

    // --- Mappings ---
    mapping(uint256 => Researcher) public researchers;
    mapping(address => uint256) public researcherIdByOwner; // Maps owner address to their researcher ID
    mapping(uint256 => Project) public projects;
    mapping(uint256 => IPAsset) public ipAssets;
    mapping(uint256 => ConditionalFundingIntent) public fundingIntents;

    // Protocol fee balance, holding collected fees and conditional funding deposits
    uint256 public protocolFeeBalance;

    // --- Events ---
    event OracleAddressUpdated(address indexed newAddress);
    event DAOExecutorAddressUpdated(address indexed newAddress);
    event ProtocolFeesUpdated(uint256 proposalFee, uint256 ipRegFee, uint256 milestoneEvalFee);
    event MinReputationToProposeUpdated(uint256 newMinReputation);
    event Paused(address account);
    event Unpaused(address account);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    event ResearcherRegistered(uint256 indexed researcherId, address indexed owner, string name, string profileURI);
    event ResearcherProfileUpdated(uint256 indexed researcherId, string newProfileURI);
    event ReputationDelegated(uint256 indexed fromId, uint256 indexed toId, uint256 amount);
    event ReputationUndelegated(uint256 indexed fromId, uint256 indexed toId, uint256 amount);
    event ResearcherProfileTransferred(uint256 indexed researcherId, address indexed oldOwner, address indexed newOwner);
    event ReputationAwarded(uint256 indexed researcherId, uint256 amount);
    event ReputationPenalized(uint256 indexed researcherId, uint256 amount);

    event ProposalSubmitted(uint256 indexed projectId, uint256 indexed creatorResearcherId, string projectURI, uint256 fundingGoal, uint256 numMilestones);
    event AIProposalEvaluated(uint256 indexed projectId, uint256 aiScore, string aiFeedbackURI);
    event ProposalApprovedForFunding(uint256 indexed projectId);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 milestoneIndex, string milestoneReportURI);
    event AIMilestoneEvaluated(uint256 indexed projectId, uint256 milestoneIndex, uint256 aiScore, string aiFeedbackURI);
    event MilestoneFundsReleased(uint256 indexed projectId, uint256 milestoneIndex, uint256 amount);
    event ProjectMalpracticeReported(uint256 indexed projectId, address indexed reporter, string reportURI);
    event MalpracticeReportResolved(uint256 indexed projectId, bool isConfirmed, uint256 punishedResearcherId);
    event ProjectFinalized(uint256 indexed projectId);

    event IPRegistered(uint256 indexed ipId, uint256 indexed projectId, address indexed owner, string ipURI);
    event IPTransfered(uint256 indexed ipId, address indexed oldOwner, address indexed newOwner);
    event IPLicensed(uint256 indexed ipId, address indexed licensee, uint256 termEnd, uint256 feeAmount);
    event IPRevenueDistributed(uint256 indexed ipId, uint256 totalAmount, uint256[] collaboratorIds, uint256[] shares);

    event ConditionalFundingIntentCreated(uint256 indexed intentId, address indexed funder, uint256 indexed projectId, uint256 amount, uint256 minAIThreshold, uint256 milestoneConditionIndex);
    event ConditionalFundingIntentCanceled(uint256 indexed intentId);
    event ConditionalFundingIntentExecuted(uint256 indexed intentId, uint256 indexed projectId, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "AccessControl: caller is not a required role");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == oracleAddress, "Caller is not the Oracle");
        _;
    }

    modifier onlyDAO() {
        require(_msgSender() == daoExecutorAddress, "Caller is not the DAO executor");
        _;
    }

    modifier onlyResearcherOwner(uint256 _researcherId) {
        require(researchers[_researcherId].id != 0, "Researcher not found");
        require(researchers[_researcherId].owner == _msgSender(), "Only researcher owner can perform this action");
        _;
    }

    modifier onlyIPOwner(uint256 _ipId) {
        require(ipAssets[_ipId].id != 0, "IP not found");
        require(ipAssets[_ipId].owner == _msgSender(), "Only IP owner can perform this action");
        _;
    }

    // --- Constructor ---
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender()); // Deployer is initial Admin
        _grantRole(ORACLE_ROLE, _msgSender()); // Grant deployer ORACLE_ROLE, should be updated for dedicated oracle
        _grantRole(DAO_ROLE, _msgSender()); // Grant deployer DAO_ROLE, should be updated for DAO contract
        
        daoExecutorAddress = _msgSender(); // Initialize DAO executor to deployer
        oracleAddress = _msgSender(); // Initialize oracle address to deployer

        // Set default fees (can be updated by DAO/admin)
        proposalFee = 0.01 ether; // Example: 0.01 ETH
        ipRegistrationFee = 0.05 ether; // Example: 0.05 ETH
        milestoneEvaluationFee = 0.005 ether; // Example: 0.005 ETH
        minReputationToPropose = 100; // Example: 100 reputation points
    }

    /**
     * @dev The fallback function and receive function are used to accumulate ETH for fees and conditional intents.
     *      Funds sent directly to the contract will increase the protocolFeeBalance.
     *      In a more complex system, this might distinguish funds or revert.
     */
    receive() external payable whenNotPaused {
        protocolFeeBalance = protocolFeeBalance.add(msg.value);
    }

    fallback() external payable {
        // Fallback for unexpected calls. Reverts as direct calls should be explicit.
        revert("VeridianProtocol: Unexpected call - use specific functions.");
    }

    // --- I. Core Platform Management & Access Control ---

    /**
     * @dev Sets or updates the address of the trusted AI evaluation oracle.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param _newOracle The new address for the AI oracle.
     */
    function updateOracleAddress(address _newOracle) external onlyRole(ADMIN_ROLE) {
        require(_newOracle != address(0), "Invalid address");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @dev Sets or updates the address that can execute DAO-approved actions.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param _newExecutor The new address for the DAO executor.
     */
    function updateDAOExecutorAddress(address _newExecutor) external onlyRole(ADMIN_ROLE) {
        require(_newExecutor != address(0), "Invalid address");
        daoExecutorAddress = _newExecutor;
        emit DAOExecutorAddressUpdated(_newExecutor);
    }

    /**
     * @dev Configures various fees charged by the protocol.
     *      Only callable by an address with the DAO_ROLE.
     * @param _proposalFee_ The fee to submit a research proposal.
     * @param _ipRegFee_ The fee to register intellectual property.
     * @param _milestoneEvalFee_ The fee for AI evaluation of a project milestone.
     */
    function setProtocolFees(uint256 _proposalFee_, uint256 _ipRegFee_, uint256 _milestoneEvalFee_) external onlyDAO {
        proposalFee = _proposalFee_;
        ipRegistrationFee = _ipRegFee_;
        milestoneEvaluationFee = _milestoneEvalFee_;
        emit ProtocolFeesUpdated(proposalFee, ipRegistrationFee, milestoneEvaluationFee);
    }

    /**
     * @dev Sets the minimum reputation required for a researcher to submit a project proposal.
     *      Only callable by an address with the DAO_ROLE.
     * @param _minRep The new minimum reputation score.
     */
    function setMinReputationToPropose(uint256 _minRep) external onlyDAO {
        minReputationToPropose = _minRep;
        emit MinReputationToProposeUpdated(_minRep);
    }

    /**
     * @dev Pauses contract functionality in case of an emergency.
     *      Only callable by an address with the ADMIN_ROLE.
     */
    function togglePause() external onlyRole(ADMIN_ROLE) {
        paused = !paused;
        if (paused) {
            emit Paused(_msgSender());
        } else {
            emit Unpaused(_msgSender());
        }
    }

    /**
     * @dev Allows the DAO executor to withdraw accumulated protocol fees.
     *      Only callable by an address with the DAO_ROLE.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyDAO nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(protocolFeeBalance >= _amount, "Insufficient protocol fees balance");
        
        protocolFeeBalance = protocolFeeBalance.sub(_amount);
        (bool success,) = payable(_to).call{value: _amount}("");
        require(success, "Failed to withdraw protocol fees");
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    /**
     * @dev Placeholder for contract upgradeability. Assumes an upgradeable proxy pattern.
     *      This function itself, in a non-proxy contract, would simply revert as it cannot directly upgrade.
     *      In a UUPS proxy, this would be an `_upgradeTo` call by the proxy's admin.
     *      Only callable by an address with the ADMIN_ROLE.
     * @param _newImplementation The address of the new contract implementation.
     */
    function upgradeContract(address _newImplementation) external onlyRole(ADMIN_ROLE) {
        // This function is purely conceptual in a standalone contract.
        // In a real system using an upgradeable proxy (like UUPS), this would involve calling the proxy's upgrade function.
        revert("Upgrade function must be called via a proxy contract, not directly on the implementation.");
    }

    // --- II. Researcher Profile & Reputation System ---

    /**
     * @dev Registers a new researcher profile, associating it with the caller's address.
     *      Each address can only register one researcher profile.
     * @param _name The name of the researcher.
     * @param _profileURI IPFS URI or similar for detailed researcher profile metadata.
     */
    function registerResearcher(string memory _name, string memory _profileURI) external whenNotPaused {
        require(researcherIdByOwner[_msgSender()] == 0, "Researcher already registered for this address");
        require(bytes(_name).length > 0, "Name cannot be empty");

        _researcherIdCounter.increment();
        uint256 newId = _researcherIdCounter.current();

        researchers[newId] = Researcher({
            id: newId,
            owner: _msgSender(),
            name: _name,
            profileURI: _profileURI,
            baseReputation: 0,
            delegatedReputation: 0,
            delegatingReputation: 0
        });
        researcherIdByOwner[_msgSender()] = newId;
        emit ResearcherRegistered(newId, _msgSender(), _name, _profileURI);
    }

    /**
     * @dev Updates the profile metadata URI for a registered researcher.
     *      Only callable by the owner of the researcher profile.
     * @param _researcherId The ID of the researcher profile to update.
     * @param _newProfileURI The new IPFS URI for profile metadata.
     */
    function updateResearcherProfile(uint256 _researcherId, string memory _newProfileURI) external whenNotPaused onlyResearcherOwner(_researcherId) {
        researchers[_researcherId].profileURI = _newProfileURI;
        emit ResearcherProfileUpdated(_researcherId, _newProfileURI);
    }

    /**
     * @dev Allows a researcher to temporarily delegate their *available* base reputation to another researcher,
     *      boosting the recipient's effective reputation.
     *      Can be used to support collaborators on specific projects.
     * @param _fromResearcherId The ID of the researcher delegating reputation.
     * @param _toResearcherId The ID of the researcher receiving the delegated reputation.
     * @param _amount The amount of reputation to delegate.
     */
    function delegateReputation(uint256 _fromResearcherId, uint256 _toResearcherId, uint256 _amount) external whenNotPaused onlyResearcherOwner(_fromResearcherId) {
        require(researchers[_toResearcherId].id != 0, "Recipient researcher not found");
        require(_fromResearcherId != _toResearcherId, "Cannot delegate reputation to self");
        require(_amount > 0, "Amount must be greater than zero");
        // Ensure the delegator has enough base reputation that isn't already delegated
        require(researchers[_fromResearcherId].baseReputation.sub(researchers[_fromResearcherId].delegatingReputation) >= _amount, "Insufficient available base reputation to delegate");

        researchers[_fromResearcherId].delegatingReputation = researchers[_fromResearcherId].delegatingReputation.add(_amount);
        researchers[_toResearcherId].delegatedReputation = researchers[_toResearcherId].delegatedReputation.add(_amount);
        emit ReputationDelegated(_fromResearcherId, _toResearcherId, _amount);
    }

    /**
     * @dev Allows a researcher to reclaim previously delegated reputation.
     * @param _fromResearcherId The ID of the researcher reclaiming reputation.
     * @param _toResearcherId The ID of the researcher from whom reputation is being reclaimed.
     * @param _amount The amount of reputation to undelegate.
     */
    function undelegateReputation(uint256 _fromResearcherId, uint256 _toResearcherId, uint256 _amount) external whenNotPaused onlyResearcherOwner(_fromResearcherId) {
        require(researchers[_toResearcherId].id != 0, "Recipient researcher not found");
        require(_amount > 0, "Amount must be greater than zero");
        require(researchers[_fromResearcherId].delegatingReputation >= _amount, "Not enough reputation delegated by sender to reclaim");
        require(researchers[_toResearcherId].delegatedReputation >= _amount, "Recipient does not have this much delegated reputation from sender");

        researchers[_fromResearcherId].delegatingReputation = researchers[_fromResearcherId].delegatingReputation.sub(_amount);
        researchers[_toResearcherId].delegatedReputation = researchers[_toResearcherId].delegatedReputation.sub(_amount);
        emit ReputationUndelegated(_fromResearcherId, _toResearcherId, _amount);
    }

    /**
     * @dev Calculates and returns the effective reputation score for a researcher.
     *      Effective reputation includes base reputation plus received delegated reputation, minus what they've delegated.
     * @param _researcherId The ID of the researcher.
     * @return The effective reputation score.
     */
    function getResearcherReputation(uint256 _researcherId) public view returns (uint256) {
        require(researchers[_researcherId].id != 0, "Researcher not found");
        return researchers[_researcherId].baseReputation.add(researchers[_researcherId].delegatedReputation).sub(researchers[_researcherId].delegatingReputation);
    }

    /**
     * @dev Transfers ownership of a researcher profile (conceptual dNFT) to a new address.
     *      The new owner must not already have a registered researcher profile.
     * @param _researcherId The ID of the researcher profile to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferResearcherProfile(uint256 _researcherId, address _newOwner) external whenNotPaused onlyResearcherOwner(_researcherId) {
        require(_newOwner != address(0), "New owner address cannot be zero");
        require(researcherIdByOwner[_newOwner] == 0, "New owner already has a researcher profile");

        address oldOwner = researchers[_researcherId].owner;
        researcherIdByOwner[oldOwner] = 0; // Remove old owner's mapping
        researchers[_researcherId].owner = _newOwner;
        researcherIdByOwner[_newOwner] = _researcherId; // Set new owner's mapping

        emit ResearcherProfileTransferred(_researcherId, oldOwner, _newOwner);
    }

    /**
     * @dev Internal function to award reputation to a researcher.
     * @param _researcherId The ID of the researcher.
     * @param _amount The amount of reputation to award.
     */
    function _awardReputation(uint256 _researcherId, uint256 _amount) internal {
        require(researchers[_researcherId].id != 0, "Researcher not found for reputation award");
        researchers[_researcherId].baseReputation = researchers[_researcherId].baseReputation.add(_amount);
        emit ReputationAwarded(_researcherId, _amount);
    }

    /**
     * @dev Internal function to penalize reputation of a researcher.
     * @param _researcherId The ID of the researcher.
     * @param _amount The amount of reputation to penalize.
     */
    function _penalizeReputation(uint256 _researcherId, uint256 _amount) internal {
        require(researchers[_researcherId].id != 0, "Researcher not found for reputation penalty");
        researchers[_researcherId].baseReputation = researchers[_researcherId].baseReputation.sub(
            _amount > researchers[_researcherId].baseReputation ? researchers[_researcherId].baseReputation : _amount, // Cap at 0
            "Reputation cannot go below zero"
        );
        emit ReputationPenalized(_researcherId, _amount);
    }

    // --- III. Project Lifecycle Management ---

    /**
     * @dev Submits a new research project proposal. Requires a registered researcher profile,
     *      sufficient effective reputation, and payment of the protocol's proposal fee.
     * @param _researcherId The ID of the researcher submitting the proposal.
     * @param _projectURI IPFS URI for detailed project description, scope, team, etc.
     * @param _fundingGoal The total ETH amount targeted for the project.
     * @param _numMilestones The number of milestones planned for the project.
     */
    function submitResearchProposal(
        uint256 _researcherId,
        string memory _projectURI,
        uint256 _fundingGoal,
        uint256 _numMilestones
    ) external payable whenNotPaused onlyResearcherOwner(_researcherId) {
        require(getResearcherReputation(_researcherId) >= minReputationToPropose, "Insufficient reputation to propose");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_numMilestones > 0, "Project must have at least one milestone");
        require(msg.value == proposalFee, "Incorrect proposal fee provided");

        protocolFeeBalance = protocolFeeBalance.add(msg.value); // Collect proposal fee

        _projectIdCounter.increment();
        uint256 newId = _projectIdCounter.current();

        projects[newId].id = newId;
        projects[newId].creatorResearcherId = _researcherId;
        projects[newId].projectURI = _projectURI;
        projects[newId].fundingGoal = _fundingGoal;
        projects[newId].currentFunding = 0;
        projects[newId].status = ProjectStatus.PendingEvaluation;
        projects[newId].numMilestones = _numMilestones;
        // milestoneFundsAllocated is initialized when funds are raised or approved, not on submission.

        emit ProposalSubmitted(newId, _researcherId, _projectURI, _fundingGoal, _numMilestones);
    }

    /**
     * @dev Oracle-only function to record the AI evaluation results for a project proposal.
     *      Updates the proposal's AI score and associated feedback.
     * @param _projectId The ID of the project proposal to evaluate.
     * @param _aiScore The AI-generated score for the proposal (e.g., 0-100).
     * @param _aiFeedbackURI IPFS URI for detailed AI feedback.
     */
    function triggerAIProposalEvaluation(uint256 _projectId, uint256 _aiScore, string memory _aiFeedbackURI) external onlyOracle {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(project.status == ProjectStatus.PendingEvaluation, "Project not in pending evaluation status");

        project.aiEvaluationScore = _aiScore;
        project.aiFeedbackURI = _aiFeedbackURI;
        // Note: Automatic approval based on high AI score can be integrated here,
        // but for human oversight, it currently awaits explicit DAO approval.
        emit AIProposalEvaluated(_projectId, _aiScore, _aiFeedbackURI);
    }

    /**
     * @dev Approves a project proposal for public funding. This action is typically
     *      the result of a DAO vote or an internal approval process based on AI evaluation.
     *      Only callable by the DAO executor.
     * @param _projectId The ID of the project to approve.
     */
    function approveProposalForFunding(uint256 _projectId) external onlyDAO {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(project.status == ProjectStatus.PendingEvaluation, "Project not in pending evaluation status");
        // Additional requirement: DAO might approve based on high AI score (e.g., project.aiEvaluationScore >= MIN_AI_SCORE_FOR_APPROVAL)
        
        project.status = ProjectStatus.ApprovedForFunding;
        emit ProposalApprovedForFunding(_projectId);
    }

    /**
     * @dev Allows users to contribute ETH to an approved project.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(msg.value > 0, "Funding amount must be greater than zero");
        require(project.status == ProjectStatus.ApprovedForFunding || project.status == ProjectStatus.FundingInProgress, "Project not open for funding");
        require(project.currentFunding.add(msg.value) <= project.fundingGoal, "Funding would exceed project goal");

        project.currentFunding = project.currentFunding.add(msg.value);
        project.status = ProjectStatus.FundingInProgress; // Ensure status is set correctly

        if (project.funderContributions[_msgSender()] == 0) {
            project.funders.push(_msgSender()); // Track unique funders
        }
        project.funderContributions[_msgSender()] = project.funderContributions[_msgSender()].add(msg.value);

        emit ProjectFunded(_projectId, _msgSender(), msg.value);
    }

    /**
     * @dev Researcher submits a milestone report for their project.
     *      Requires payment of the milestone evaluation fee.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The 0-indexed index of the milestone being submitted.
     * @param _milestoneReportURI IPFS URI for the detailed milestone report.
     */
    function submitProjectMilestone(uint256 _projectId, uint256 _milestoneIndex, string memory _milestoneReportURI) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(researcherIdByOwner[_msgSender()] == project.creatorResearcherId, "Only project creator can submit milestones");
        require(_milestoneIndex < project.numMilestones, "Invalid milestone index");
        require(!project.milestoneApproved[_milestoneIndex], "Milestone already approved or under review");
        require(project.completedMilestones == _milestoneIndex, "Milestones must be submitted sequentially");
        require(msg.value == milestoneEvaluationFee, "Incorrect milestone evaluation fee provided");

        protocolFeeBalance = protocolFeeBalance.add(msg.value); // Collect milestone evaluation fee
        project.status = ProjectStatus.MilestoneInProgress; // Change status while evaluation occurs

        // The _milestoneReportURI would ideally trigger an off-chain AI analysis via the oracle.
        emit MilestoneSubmitted(_projectId, _milestoneIndex, _milestoneReportURI);
    }

    /**
     * @dev Oracle-only function to record the AI evaluation results for a project milestone.
     *      If approved by the AI, it updates the project's completed milestones and awards reputation.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone being evaluated.
     * @param _aiScore The AI-generated score for the milestone.
     * @param _aiFeedbackURI IPFS URI for detailed AI feedback specific to the milestone.
     */
    function triggerAIMilestoneEvaluation(uint256 _projectId, uint256 _milestoneIndex, uint256 _aiScore, string memory _aiFeedbackURI) external onlyOracle {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(_milestoneIndex < project.numMilestones, "Invalid milestone index");
        require(project.completedMilestones == _milestoneIndex, "Milestone evaluation out of sequence or already completed");
        require(!project.milestoneApproved[_milestoneIndex], "Milestone already approved");
        require(project.status == ProjectStatus.MilestoneInProgress, "Project not in milestone evaluation status");

        project.aiEvaluationScore = _aiScore; // Update the general AI score, or a separate milestone score could be used
        project.aiFeedbackURI = _aiFeedbackURI; // Update the general AI feedback, or separate for milestones

        // For demonstration, an AI score > 70 is considered approved. This threshold is configurable by DAO in a real system.
        if (_aiScore >= 70) {
            project.milestoneApproved[_milestoneIndex] = true;
            _awardReputation(project.creatorResearcherId, 50); // Award reputation for successful milestone
            project.status = ProjectStatus.FundingInProgress; // Revert to funding status or awaiting next milestone
        } else {
            project.status = ProjectStatus.FundingInProgress; // Milestone failed, project remains in funding/progress or can be marked as failed by DAO
            _penalizeReputation(project.creatorResearcherId, 25); // Minor penalty for failed milestone
        }

        emit AIMilestoneEvaluated(_projectId, _milestoneIndex, _aiScore, _aiFeedbackURI);
    }

    /**
     * @dev Releases funds allocated for an approved milestone to the project creator.
     *      Callable by the project creator once the milestone is approved.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone for which to release funds.
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(researcherIdByOwner[_msgSender()] == project.creatorResearcherId, "Only project creator can release milestone funds");
        require(_milestoneIndex < project.numMilestones, "Invalid milestone index");
        require(project.milestoneApproved[_milestoneIndex], "Milestone not yet approved");
        require(project.milestoneFundsAllocated[_milestoneIndex] == 0, "Funds for this milestone already released"); // Already 0 if not allocated yet
        
        // Simple equal distribution for demonstration. A real system might have custom milestone budgets.
        uint256 fundsToRelease = project.fundingGoal.div(project.numMilestones); 
        require(project.currentFunding >= fundsToRelease, "Insufficient funds raised or remaining for this milestone release");

        // Mark funds as allocated and decrement currentFunding for proper accounting
        project.milestoneFundsAllocated[_milestoneIndex] = fundsToRelease; // Set to the amount released for this specific milestone
        project.currentFunding = project.currentFunding.sub(fundsToRelease); // Deduct from main pool
        project.completedMilestones = project.completedMilestones.add(1);

        (bool success,) = payable(researchers[project.creatorResearcherId].owner).call{value: fundsToRelease}("");
        require(success, "Failed to send milestone funds");

        emit MilestoneFundsReleased(_projectId, _milestoneIndex, fundsToRelease);
    }

    /**
     * @dev Allows anyone to report potential malpractice or issues with a project.
     *      Changes the project status to 'MalpracticeReported' for DAO review.
     * @param _projectId The ID of the project being reported.
     * @param _reportURI IPFS URI for detailed evidence or report.
     */
    function reportProjectMalpractice(uint256 _projectId, string memory _reportURI) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(project.status != ProjectStatus.Completed && project.status != ProjectStatus.Failed && project.status != ProjectStatus.IPRegistered, "Cannot report malpractice on completed, failed, or IP registered projects");
        require(!project.malpracticeReported, "Malpractice already reported for this project");

        project.malpracticeReported = true;
        project.status = ProjectStatus.MalpracticeReported;

        // In a real system, this would trigger a governance proposal for the DAO to vote on.
        emit ProjectMalpracticeReported(_projectId, _msgSender(), _reportURI);
    }

    /**
     * @dev DAO function to resolve a malpractice report, either confirming or dismissing it.
     *      If confirmed, it can penalize the researcher and/or mark the project as failed.
     *      Any remaining funds in `currentFunding` could be returned to funders or frozen.
     * @param _projectId The ID of the project under review.
     * @param _isMalpracticeConfirmed True if malpractice is confirmed, false otherwise.
     * @param _punishedResearcherId The researcher ID to penalize if malpractice is confirmed (can be 0 if no specific researcher is punished).
     */
    function resolveMalpracticeReport(uint256 _projectId, bool _isMalpracticeConfirmed, uint256 _punishedResearcherId) external onlyDAO {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(project.status == ProjectStatus.MalpracticeReported, "Project is not currently under malpractice review");

        project.malpracticeReported = false; // Reset flag

        if (_isMalpracticeConfirmed) {
            project.status = ProjectStatus.Failed;
            if (_punishedResearcherId != 0 && researchers[_punishedResearcherId].id != 0) {
                _penalizeReputation(_punishedResearcherId, 500); // Significant penalty
            }
            // Additional logic: DAO could decide to refund remaining `project.currentFunding` to funders.
            // For now, these funds remain in the contract and could be withdrawn by DAO through a separate mechanism.
        } else {
            // Revert to previous logical active status
            project.status = project.completedMilestones == project.numMilestones ? ProjectStatus.Completed : ProjectStatus.FundingInProgress;
        }
        emit MalpracticeReportResolved(_projectId, _isMalpracticeConfirmed, _punishedResearcherId);
    }

    /**
     * @dev Marks a project as complete, typically after all milestones are finished and reviewed.
     *      Awards final reputation to the creator and enables IP registration for the project.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(researcherIdByOwner[_msgSender()] == project.creatorResearcherId, "Only project creator can finalize their project");
        require(project.status == ProjectStatus.FundingInProgress || project.status == ProjectStatus.MilestoneInProgress, "Project cannot be finalized in current status (e.g., already completed, failed, or under malpractice)");
        require(project.completedMilestones == project.numMilestones, "All milestones must be completed to finalize project");
        // Additional check: Ensure any remaining `currentFunding` is handled (e.g., transferred to DAO or returned to funders)
        
        project.status = ProjectStatus.Completed;
        _awardReputation(project.creatorResearcherId, 200); // Significant reputation award for full completion

        emit ProjectFinalized(_projectId);
    }

    // --- IV. Intellectual Property (IP) & Revenue Sharing ---

    /**
     * @dev Registers Intellectual Property (IP) for a finalized project.
     *      The project creator becomes the initial owner. Collaborator shares define future revenue distribution.
     *      Requires payment of the IP registration fee.
     * @param _projectId The ID of the project whose IP is being registered.
     * @param _ipURI IPFS URI for the IP documentation (e.g., patent document, research paper details).
     * @param _collaboratorResearcherIds Array of researcher IDs who collaborated and will share IP revenue.
     * @param _shares Corresponding array of percentage shares (e.g., [7000, 3000] for 70%/30%, summing to 10000).
     */
    function registerProjectIP(
        uint256 _projectId,
        string memory _ipURI,
        uint256[] memory _collaboratorResearcherIds,
        uint256[] memory _shares
    ) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project not found");
        require(researcherIdByOwner[_msgSender()] == project.creatorResearcherId, "Only project creator can register IP");
        require(project.status == ProjectStatus.Completed, "Project must be completed to register IP");
        require(project.ipId == 0, "IP already registered for this project");
        require(msg.value == ipRegistrationFee, "Incorrect IP registration fee provided");
        require(_collaboratorResearcherIds.length == _shares.length, "Collaborator IDs and shares arrays must have same length");

        uint256 totalShares;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShares = totalShares.add(_shares[i]);
            require(researchers[_collaboratorResearcherIds[i]].id != 0, "Invalid collaborator researcher ID provided");
        }
        require(totalShares == 10000, "Total shares must sum to 10000 (representing 100%)");

        protocolFeeBalance = protocolFeeBalance.add(msg.value); // Collect IP registration fee

        _ipIdCounter.increment();
        uint256 newIpId = _ipIdCounter.current();

        ipAssets[newIpId].id = newIpId;
        ipAssets[newIpId].projectId = _projectId;
        ipAssets[newIpId].owner = _msgSender(); // Project creator is initial IP owner
        ipAssets[newIpId].ipURI = _ipURI;
        ipAssets[newIpId].collaboratorResearcherIds = _collaboratorResearcherIds;
        ipAssets[newIpId].shares = _shares;
        ipAssets[newIpId].totalCollectedRevenue = 0;

        project.ipId = newIpId;
        project.status = ProjectStatus.IPRegistered;

        emit IPRegistered(newIpId, _projectId, _msgSender(), _ipURI);
    }

    /**
     * @dev Transfers ownership of a registered IP asset to a new address.
     *      Only callable by the current owner of the IP.
     * @param _ipId The ID of the IP asset to transfer.
     * @param _newOwner The address of the new owner.
     */
    function transferIPOwnership(uint256 _ipId, address _newOwner) external whenNotPaused onlyIPOwner(_ipId) {
        require(_newOwner != address(0), "New owner address cannot be zero");

        address oldOwner = ipAssets[_ipId].owner;
        ipAssets[_ipId].owner = _newOwner;

        emit IPTransfered(_ipId, oldOwner, _newOwner);
    }

    /**
     * @dev Allows the IP owner to grant a license for their IP.
     *      The licensee pays a fee (in ETH) and gains rights for a specified term.
     *      The fee amount is added to the IP's total collected revenue for distribution.
     * @param _ipId The ID of the IP to license.
     * @param _termInMonths The duration of the license in months.
     * @param _feeAmount The fee for the license (in ETH).
     * @param _licenseURI IPFS URI for the specific license agreement details.
     */
    function licenseIP(uint256 _ipId, uint256 _termInMonths, uint256 _feeAmount, string memory _licenseURI) external payable whenNotPaused onlyIPOwner(_ipId) {
        require(_feeAmount > 0, "License fee must be greater than zero");
        require(msg.value == _feeAmount, "Sent amount does not match license fee");
        require(_termInMonths > 0, "License term must be positive");

        IPAsset storage ip = ipAssets[_ipId];
        ip.totalCollectedRevenue = ip.totalCollectedRevenue.add(msg.value);

        // A more advanced system could track individual licenses in a mapping or array for revocation, etc.
        // For simplicity, we just track the revenue.
        emit IPLicensed(_ipId, _msgSender(), block.timestamp + _termInMonths.mul(30 days), _feeAmount);
    }

    /**
     * @dev This function is conceptually for the IP owner to collect revenue.
     *      However, in this contract's design, all collected IP revenue is held
     *      within the IPAsset's `totalCollectedRevenue` and is distributed to all
     *      collaborators (including the owner if they are a collaborator) via `distributeIPRevenue`.
     *      Thus, direct `collectLicenseRevenue` is redundant and reverts to encourage `distributeIPRevenue`.
     * @param _ipId The ID of the IP.
     */
    function collectLicenseRevenue(uint256 _ipId) external pure onlyIPOwner(_ipId) {
        // As per current design, owner's share is handled within collaborator shares by `distributeIPRevenue`.
        // This function would be needed if there was a separate "owner's cut" before collaborator distribution.
        revert("Use distributeIPRevenue to distribute all accrued revenue to collaborators.");
    }

    /**
     * @dev Distributes collected IP revenue among collaborators (including the owner if they are a collaborator)
     *      based on their predefined shares.
     *      Only callable by the owner of the IP.
     * @param _ipId The ID of the IP.
     */
    function distributeIPRevenue(uint256 _ipId) external nonReentrant onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        require(ip.totalCollectedRevenue > 0, "No revenue to distribute");

        uint256 totalRevenueToDistribute = ip.totalCollectedRevenue;
        ip.totalCollectedRevenue = 0; // Reset collected revenue after initiating distribution

        uint256[] memory distributedSharesAmounts = new uint256[](ip.collaboratorResearcherIds.length);

        for (uint256 i = 0; i < ip.collaboratorResearcherIds.length; i++) {
            uint256 collaboratorId = ip.collaboratorResearcherIds[i];
            uint256 shareAmount = totalRevenueToDistribute.mul(ip.shares[i]).div(10000); // Shares are out of 10000 for 100%

            address payable collaboratorAddress = payable(researchers[collaboratorId].owner);
            require(collaboratorAddress != address(0), "Collaborator wallet address not found");

            (bool success,) = collaboratorAddress.call{value: shareAmount}("");
            require(success, "Failed to send funds to collaborator");

            ip.collectedCollaboratorShare[collaboratorId] = ip.collectedCollaboratorShare[collaboratorId].add(shareAmount);
            distributedSharesAmounts[i] = shareAmount;
        }

        emit IPRevenueDistributed(_ipId, totalRevenueToDistribute, ip.collaboratorResearcherIds, distributedSharesAmounts);
    }

    // --- V. Conditional Funding & Intent System ---

    /**
     * @dev Creates a conditional funding intent. Funds are held in the contract (specifically, in `protocolFeeBalance`)
     *      until the specified conditions (minimum AI score, milestone completion) for the project are met.
     * @param _projectId The ID of the project to fund conditionally.
     * @param _amount The amount of ETH to commit.
     * @param _minAIThreshold The minimum AI evaluation score the project must achieve.
     * @param _milestoneConditionIndex The 0-indexed milestone that must be completed (0 for no specific milestone condition).
     */
    function createConditionalFundingIntent(
        uint256 _projectId,
        uint256 _amount,
        uint256 _minAIThreshold,
        uint256 _milestoneConditionIndex
    ) external payable whenNotPaused nonReentrant {
        require(projects[_projectId].id != 0, "Project not found");
        require(msg.value == _amount, "Sent amount does not match intent amount");
        require(_amount > 0, "Amount must be greater than zero");
        if (_milestoneConditionIndex > 0) { // If milestone condition is set
            require(_milestoneConditionIndex <= projects[_projectId].numMilestones, "Invalid milestone condition index: must be 0-indexed and within project milestones count");
        }

        _fundingIntentIdCounter.increment();
        uint256 newIntentId = _fundingIntentIdCounter.current();

        fundingIntents[newIntentId] = ConditionalFundingIntent({
            id: newIntentId,
            funder: _msgSender(),
            projectId: _projectId,
            amount: _amount,
            minAIThreshold: _minAIThreshold,
            milestoneConditionIndex: _milestoneConditionIndex,
            executed: false
        });

        // Funds are held by the contract, increasing the general protocol balance.
        // A dedicated mapping for intent balances would be more precise in a production system.
        protocolFeeBalance = protocolFeeBalance.add(msg.value);

        emit ConditionalFundingIntentCreated(newIntentId, _msgSender(), _projectId, _amount, _minAIThreshold, _milestoneConditionIndex);
    }

    /**
     * @dev Allows the creator of a conditional funding intent to cancel it,
     *      reclaiming their committed funds if not already executed.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelFundingIntent(uint256 _intentId) external whenNotPaused nonReentrant {
        ConditionalFundingIntent storage intent = fundingIntents[_intentId];
        require(intent.id != 0, "Funding intent not found");
        require(intent.funder == _msgSender(), "Only intent creator can cancel");
        require(!intent.executed, "Funding intent already executed or cancelled");

        uint256 amountToReturn = intent.amount;
        intent.executed = true; // Mark as "executed" to prevent re-execution or further actions on this intent.

        // Deduct funds from the overall protocol balance
        require(protocolFeeBalance >= amountToReturn, "Protocol balance insufficient for intent cancellation. This indicates a severe accounting error.");
        protocolFeeBalance = protocolFeeBalance.sub(amountToReturn);

        (bool success,) = payable(_msgSender()).call{value: amountToReturn}("");
        require(success, "Failed to return funds during cancellation");

        emit ConditionalFundingIntentCanceled(_intentId);
    }

    /**
     * @dev Anyone can call this function to attempt to execute a conditional funding intent
     *      if all specified conditions (AI score, milestone completion) are met.
     *      If successful, the funds are transferred from the protocol balance to the project's current funding.
     * @param _intentId The ID of the intent to execute.
     */
    function executeFundingIntent(uint256 _intentId) external nonReentrant {
        ConditionalFundingIntent storage intent = fundingIntents[_intentId];
        require(intent.id != 0, "Funding intent not found");
        require(!intent.executed, "Funding intent already executed or cancelled");

        Project storage project = projects[intent.projectId];
        require(project.id != 0, "Project for intent not found");
        require(project.status == ProjectStatus.ApprovedForFunding || project.status == ProjectStatus.FundingInProgress, "Project not in fundable state");
        require(project.aiEvaluationScore >= intent.minAIThreshold, "Project AI score below threshold for intent execution");

        // Check milestone condition if specified (0 means no specific milestone needed)
        if (intent.milestoneConditionIndex > 0) {
            // Milestone index is 0-indexed internally, so condition index 1 refers to milestone[0]
            require(project.milestoneApproved[intent.milestoneConditionIndex - 1], "Required milestone for intent not completed");
        }
        
        // Ensure project has capacity for additional funding
        require(project.currentFunding.add(intent.amount) <= project.fundingGoal, "Funding intent would exceed project goal");

        // Transfer funds from protocol balance to project's current funding
        require(protocolFeeBalance >= intent.amount, "Protocol balance insufficient for intent execution. This indicates a severe accounting error.");
        protocolFeeBalance = protocolFeeBalance.sub(intent.amount);

        project.currentFunding = project.currentFunding.add(intent.amount);
        project.status = ProjectStatus.FundingInProgress; // Ensure project is marked as in progress

        // Track funder contribution for the project
        if (project.funderContributions[intent.funder] == 0) {
            project.funders.push(intent.funder);
        }
        project.funderContributions[intent.funder] = project.funderContributions[intent.funder].add(intent.amount);

        intent.executed = true; // Mark as executed

        emit ConditionalFundingIntentExecuted(_intentId, intent.projectId, intent.amount);
    }
}
```