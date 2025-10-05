Here's a Solidity smart contract named "AetherForge" that combines several advanced and trendy concepts: AI oracle integration (simulated on-chain), dynamic digital assets (NFTs), a project funding mechanism, a reputation system, and a decentralized autonomous organization (DAO) for governance and sustainability initiatives. It avoids direct duplication of any single open-source project by integrating these features into a unique overarching system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Outline: AetherForge - AI-Enhanced Dynamic Digital Asset & Project Foundry
//
// This contract establishes a decentralized platform for creating, funding, and evolving digital assets and projects,
// leveraging simulated AI insights and community governance. Projects are composed of "modules" which can dynamically
// change their traits and evolve based on AI recommendations, community feedback, and on-chain events.
// A reputation system encourages quality contributions from creators, curators, and AI oracles.
// A portion of platform fees is directed to a "Sustainability Pool" for real-world impact initiatives.

// Function Summary:
//
// I. Core Setup & Administration (3 functions)
// 1.  constructor(): Initializes the contract, setting the owner and initial parameters.
// 2.  setFeeWallet(address _newWallet): Admin function (Owner-only) to change the wallet receiving platform fees.
// 3.  adjustSystemFees(uint256 _newProjectFeePercent, uint256 _newSustainabilityFeePercent): Governance-controlled function to update platform fee percentages. Callable only via a successful governance proposal.
//
// II. Project & Module Creation (5 functions)
// 4.  proposeProject(string memory _name, string memory _description, uint256 _fundingGoal, uint256 _durationDays): Allows users to propose new projects, requiring a stake.
// 5.  updateProjectDetails(uint256 _projectId, string memory _newName, string memory _newDescription): Project creator can update project info before funding completion.
// 6.  addModuleToProject(uint256 _projectId, string memory _initialURI, string memory _initialTraits): Adds a new, initial module (conceptual NFT component) to a project.
// 7.  cancelProjectProposal(uint256 _projectId): Allows a project creator to cancel their unfunded proposal.
// 8.  approveModuleForNFTMint(uint256 _moduleId): Allows project creator (or owner for simplicity) to mark a module ready for NFT minting.
//
// III. Funding & Treasury Management (4 functions)
// 9.  fundProject(uint256 _projectId): Allows users to contribute Ether to a project's funding goal.
// 10. claimProjectFunds(uint256 _projectId): Project creator can claim funded Ether after goal is met and duration passed.
// 11. withdrawContributorRefund(uint256 _projectId): Contributors can claim refunds if a project fails to meet its funding goal.
// 12. distributeSustainabilityPoolFunds(address _recipient, uint256 _amount): Governance-controlled function to distribute funds from the sustainability pool. Callable only via a successful governance proposal.
//
// IV. AI Oracle & Dynamic Module Evolution (5 functions)
// 13. registerAIOracle(address _oracleAddress, string memory _name): Governance-controlled function to register a new AI oracle. Callable only via a successful governance proposal.
// 14. submitAIAnalysisReport(uint256 _moduleId, string memory _analysisURI, uint8 _score): Registered AI oracles submit an analysis report for a module.
// 15. submitAIRecommendation(uint256 _moduleId, string memory _recommendationURI): Registered AI oracles provide a recommendation for module evolution.
// 16. applyModuleTraitUpdate(uint256 _moduleId, string memory _newTraits, string memory _newURI): Allows approved entities (e.g., project creator, governance-approved AI proxy) to update a module's dynamic traits and URI.
// 17. mintDynamicModuleNFT(uint256 _moduleId): Mints a module as a dynamic NFT (ERC721-like), available only after project funding and approval.
//
// V. Reputation & Governance (5 functions)
// 18. proposeGovernanceAction(string memory _description, bytes memory _callData, address _target, uint256 _value): Allows users with sufficient reputation to propose system changes.
// 19. voteOnProposal(uint256 _proposalId, bool _support): Stakeholders vote on active governance proposals.
// 20. executeProposal(uint256 _proposalId): Executes a passed governance proposal.
// 21. rewardUserReputation(address _user, uint256 _amount): Governance-controlled function to manually reward user reputation. Callable only via a successful governance proposal.
// 22. penalizeUserReputation(address _user, uint256 _amount): Governance-controlled function to manually penalize user reputation. Callable only via a successful governance proposal.

contract AetherForge is Ownable, ReentrancyGuard {

    // --- Data Structures ---

    enum ProjectStatus { Proposed, Active, Funded, Failed, Cancelled }

    struct Project {
        uint256 id;
        address creator;
        string name;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 startDate;
        uint256 endDate; // Funding end date
        ProjectStatus status;
        address[] contributorAddresses; // To track who contributed for refunds
        uint256[] moduleIds; // IDs of modules belonging to this project
        uint256 creatorStake; // Stake required to propose a project
    }

    // Mapping for project contributions: projectId => contributorAddress => amount
    mapping(uint256 => mapping(address => uint256)) public projectContributedAmounts;


    enum ModuleStatus { Proposed, AwaitingAnalysis, AnalysisSubmitted, RecommendationSubmitted, ApprovedForMint, Minted }

    struct Module {
        uint256 id;
        uint256 projectId;
        address creator; // Original creator of this specific module
        string currentURI; // Metadata URI, can change dynamically
        string currentTraits; // JSON string of dynamic traits, can change
        ModuleStatus status;
        address aiOracleAnalysis; // Last AI oracle to submit analysis
        address aiOracleRecommendation; // Last AI oracle to submit recommendation
        string analysisReportURI; // URI to AI analysis report
        string recommendationURI; // URI to AI recommendation
        bool approvedForMint; // Flag set by project creator/governance
        bool isMintedAsNFT; // True if minted as a dynamic NFT
        address nftOwner; // Owner of the conceptual NFT (if minted)
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed, FailedExecution }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        address target;
        bytes callData;
        uint256 value;
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 startBlock;
        uint256 endBlock;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
    }

    struct AIOracle {
        string name;
        uint256 reputation;
        bool isActive;
    }

    // --- State Variables ---

    uint256 public nextProjectId;
    uint256 public nextModuleId;
    uint256 public nextProposalId;

    address public feeWallet;
    uint256 public projectFeePercent; // % of claimed project funds sent to feeWallet (e.g., 500 for 5%)
    uint256 public sustainabilityFeePercent; // % of claimed project funds sent to sustainabilityPool (e.g., 200 for 2%)
    uint256 public constant MAX_FEE_PERCENT = 1000; // 10% (out of 10000 basis points, so 10000 = 100%)

    uint256 public projectProposalStake; // ETH required to propose a project
    uint256 public minProjectFundingGoal;

    uint256 public sustainabilityPool; // Funds collected for sustainability initiatives

    // Governance parameters
    uint256 public governanceVotingPeriodBlocks; // How many blocks a proposal is open for voting
    uint256 public governanceMinVotingPower; // Minimum reputation to propose/vote
    uint256 public governanceQuorumPercent; // % of total *cast* votes (for simplicity) for 'for' to reach (e.g., 5000 for 50%)

    // Mappings
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Module) public modules;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => AIOracle) public aiOracles; // AI oracle address => AIOracle struct
    mapping(address => uint256) public userReputation; // General user reputation score

    // --- Events ---

    event ProjectProposed(uint256 indexed projectId, address indexed creator, string name, uint256 fundingGoal, uint256 endDate);
    event ProjectFunded(uint256 indexed projectId, address indexed contributor, uint256 amount, uint256 newTotalFunding);
    event ProjectFundsClaimed(uint256 indexed projectId, address indexed creator, uint256 amount);
    event ProjectRefunded(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event ProjectCancelled(uint256 indexed projectId);

    event ModuleAdded(uint256 indexed moduleId, uint256 indexed projectId, address indexed creator, string initialURI);
    event ModuleApprovedForMint(uint256 indexed moduleId, address indexed approver);
    event ModuleNFTMinted(uint256 indexed moduleId, address indexed owner, string tokenURI);
    event ModuleTraitsUpdated(uint256 indexed moduleId, address indexed updater, string newTraits);

    event AIOracleRegistered(address indexed oracleAddress, string name);
    event AIAnalysisSubmitted(uint256 indexed moduleId, address indexed oracleAddress, string analysisURI, uint8 score);
    event AIRecommendationSubmitted(uint256 indexed moduleId, address indexed oracleAddress, string recommendationURI);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address target, uint256 value);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalExecutionFailed(uint256 indexed proposalId, bytes reason);

    event ReputationRewarded(address indexed user, uint256 amount);
    event ReputationPenalized(address indexed user, uint256 amount);
    event FundsDistributedFromSustainabilityPool(address indexed recipient, uint256 amount);
    event SystemFeesAdjusted(uint256 newProjectFee, uint256 newSustainabilityFee);

    // --- Modifiers ---

    modifier onlyRegisteredOracle() {
        require(aiOracles[msg.sender].isActive, "AetherForge: Caller is not a registered AI oracle");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == _msgSender(), "AetherForge: Caller is not the project creator");
        _;
    }

    // --- Constructor ---

    constructor(
        address _initialFeeWallet,
        uint256 _initialProjectFeePercent, // e.g., 500 for 5%
        uint256 _initialSustainabilityFeePercent, // e.g., 200 for 2%
        uint256 _initialProposalStake,
        uint256 _initialMinFundingGoal,
        uint256 _initialVotingPeriodBlocks,
        uint256 _initialMinVotingPower,
        uint256 _initialQuorumPercent // e.g., 5000 for 50%
    ) Ownable(_msgSender()) {
        require(_initialFeeWallet != address(0), "AetherForge: Fee wallet cannot be zero address");
        require(_initialProjectFeePercent + _initialSustainabilityFeePercent <= MAX_FEE_PERCENT, "AetherForge: Total fees exceed max");
        require(_initialMinFundingGoal > 0, "AetherForge: Min funding goal must be greater than zero");
        require(_initialVotingPeriodBlocks > 0, "AetherForge: Voting period must be positive");
        require(_initialQuorumPercent > 0 && _initialQuorumPercent <= 10000, "AetherForge: Quorum percent must be between 1 and 100%");

        feeWallet = _initialFeeWallet;
        projectFeePercent = _initialProjectFeePercent;
        sustainabilityFeePercent = _initialSustainabilityFeePercent;
        projectProposalStake = _initialProposalStake;
        minProjectFundingGoal = _initialMinFundingGoal;
        governanceVotingPeriodBlocks = _initialVotingPeriodBlocks;
        governanceMinVotingPower = _initialMinVotingPower;
        governanceQuorumPercent = _initialQuorumPercent;

        nextProjectId = 1;
        nextModuleId = 1;
        nextProposalId = 1;
        userReputation[_msgSender()] = 1000; // Initial reputation for owner to propose governance actions
    }

    // --- I. Core Setup & Administration (3 functions) ---

    // 1. setFeeWallet: Admin function to change the wallet receiving platform fees.
    function setFeeWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "AetherForge: New fee wallet cannot be zero address");
        feeWallet = _newWallet;
    }

    // 2. adjustSystemFees: Governance-controlled function to update platform fee percentages.
    // This function is designed to be called by a governance proposal's `executeProposal`.
    function adjustSystemFees(uint256 _newProjectFeePercent, uint256 _newSustainabilityFeePercent) external {
        // Only this contract itself, when executing a proposal, should call this.
        require(_msgSender() == address(this), "AetherForge: Only governance can call this function directly");
        require(_newProjectFeePercent + _newSustainabilityFeePercent <= MAX_FEE_PERCENT, "AetherForge: Total fees exceed max percentage");
        projectFeePercent = _newProjectFeePercent;
        sustainabilityFeePercent = _newSustainabilityFeePercent;
        emit SystemFeesAdjusted(_newProjectFeePercent, _newSustainabilityFeePercent);
    }

    // --- II. Project & Module Creation (5 functions) ---

    // 3. proposeProject: Allows users to propose new projects, requiring a stake.
    function proposeProject(
        string memory _name,
        string memory _description,
        uint256 _fundingGoal,
        uint256 _durationDays
    ) external payable returns (uint256) {
        require(msg.value == projectProposalStake, "AetherForge: Insufficient project proposal stake");
        require(_fundingGoal >= minProjectFundingGoal, "AetherForge: Funding goal below minimum");
        require(_durationDays > 0, "AetherForge: Project duration must be positive");
        require(bytes(_name).length > 0, "AetherForge: Project name cannot be empty");

        uint256 projectId = nextProjectId++;
        projects[projectId] = Project({
            id: projectId,
            creator: _msgSender(),
            name: _name,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            startDate: block.timestamp,
            endDate: block.timestamp + (_durationDays * 1 days),
            status: ProjectStatus.Proposed,
            contributorAddresses: new address[](0),
            moduleIds: new uint256[](0),
            creatorStake: msg.value
        });
        // projectContributedAmounts[projectId] is initialized by its first usage

        emit ProjectProposed(projectId, _msgSender(), _name, _fundingGoal, projects[projectId].endDate);
        return projectId;
    }

    // 4. updateProjectDetails: Project creator can update project info before funding completion.
    function updateProjectDetails(
        uint256 _projectId,
        string memory _newName,
        string memory _newDescription
    ) external onlyProjectCreator(_projectId) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "AetherForge: Project not in updatable status");
        require(block.timestamp < project.endDate, "AetherForge: Project funding period has ended");
        require(bytes(_newName).length > 0, "AetherForge: Project name cannot be empty");

        project.name = _newName;
        project.description = _newDescription;

        emit ProjectProposed(_projectId, _msgSender(), _newName, project.fundingGoal, project.endDate); // Re-emit with updated info
    }

    // 5. addModuleToProject: Adds a new, initial module (conceptual NFT component) to a project.
    function addModuleToProject(
        uint256 _projectId,
        string memory _initialURI,
        string memory _initialTraits
    ) external onlyProjectCreator(_projectId) returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status != ProjectStatus.Cancelled && project.status != ProjectStatus.Failed, "AetherForge: Cannot add module to inactive project");
        
        uint256 moduleId = nextModuleId++;
        modules[moduleId] = Module({
            id: moduleId,
            projectId: _projectId,
            creator: _msgSender(),
            currentURI: _initialURI,
            currentTraits: _initialTraits,
            status: ModuleStatus.Proposed,
            aiOracleAnalysis: address(0),
            aiOracleRecommendation: address(0),
            analysisReportURI: "",
            recommendationURI: "",
            approvedForMint: false,
            isMintedAsNFT: false,
            nftOwner: address(0)
        });
        project.moduleIds.push(moduleId);

        emit ModuleAdded(moduleId, _projectId, _msgSender(), _initialURI);
        return moduleId;
    }

    // 6. cancelProjectProposal: Allows a project creator to cancel their unfunded proposal.
    function cancelProjectProposal(uint256 _projectId) external onlyProjectCreator(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "AetherForge: Project not in updatable status");
        require(project.currentFunding == 0, "AetherForge: Cannot cancel project with funding");

        project.status = ProjectStatus.Cancelled;
        // Refund creator stake
        (bool success, ) = _msgSender().call{value: project.creatorStake}("");
        require(success, "AetherForge: Failed to refund creator stake");
        project.creatorStake = 0; // Clear stake after refund

        emit ProjectCancelled(_projectId);
    }

    // 7. approveModuleForNFTMint: Allows project creator (or owner for simplicity) to mark a module ready for NFT minting.
    // In a full DAO, this might require a governance proposal or a community vote on module readiness.
    function approveModuleForNFTMint(uint256 _moduleId) external {
        Module storage module = modules[_moduleId];
        require(module.id != 0, "AetherForge: Module does not exist");
        Project storage project = projects[module.projectId];
        require(project.creator == _msgSender() || owner() == _msgSender(), "AetherForge: Only project creator or contract owner can approve module");
        require(project.status == ProjectStatus.Funded, "AetherForge: Project must be funded to approve module for mint");
        require(!module.isMintedAsNFT, "AetherForge: Module already minted as NFT");

        module.approvedForMint = true;
        module.status = ModuleStatus.ApprovedForMint;
        emit ModuleApprovedForMint(_moduleId, _msgSender());
    }

    // --- III. Funding & Treasury Management (4 functions) ---

    // 8. fundProject: Allows users to contribute Ether to a project's funding goal.
    function fundProject(uint256 _projectId) external payable nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status == ProjectStatus.Proposed || project.status == ProjectStatus.Active, "AetherForge: Project is not open for funding");
        require(block.timestamp < project.endDate, "AetherForge: Funding period has ended");
        require(msg.value > 0, "AetherForge: Contribution must be greater than zero");

        // Update project status to Active if it's currently Proposed and received first funding.
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Active;
        }

        project.currentFunding += msg.value;
        if (projectContributedAmounts[_projectId][_msgSender()] == 0) {
            project.contributorAddresses.push(_msgSender());
        }
        projectContributedAmounts[_projectId][_msgSender()] += msg.value;

        if (project.currentFunding >= project.fundingGoal) {
            project.status = ProjectStatus.Funded;
        }

        emit ProjectFunded(_projectId, _msgSender(), msg.value, project.currentFunding);
    }

    // 9. claimProjectFunds: Project creator can claim funded Ether after goal is met and duration passed.
    function claimProjectFunds(uint256 _projectId) external onlyProjectCreator(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status == ProjectStatus.Funded, "AetherForge: Project not fully funded or already claimed");
        require(block.timestamp >= project.endDate, "AetherForge: Funding period not yet ended");
        require(project.currentFunding > 0, "AetherForge: No funds to claim");

        uint256 totalClaimable = project.currentFunding;

        // Calculate fees (e.g., 500 = 5%, 10000 = 100%)
        uint256 projectFee = (totalClaimable * projectFeePercent) / 10000; 
        uint256 sustainabilityFee = (totalClaimable * sustainabilityFeePercent) / 10000;
        uint256 netClaimable = totalClaimable - projectFee - sustainabilityFee;

        // Transfer fees
        (bool feeSuccess, ) = feeWallet.call{value: projectFee}("");
        require(feeSuccess, "AetherForge: Failed to transfer project fee");

        sustainabilityPool += sustainabilityFee;
        (bool creatorSuccess, ) = _msgSender().call{value: netClaimable}("");
        require(creatorSuccess, "AetherForge: Failed to transfer funds to creator");

        project.currentFunding = 0; // Reset funding after claim
        project.status = ProjectStatus.Active; // Project is now "active" after funding and claiming
                                                // Could also introduce a 'Completed' status if applicable.

        // Refund creator's initial stake
        if (project.creatorStake > 0) {
            (bool stakeRefundSuccess, ) = _msgSender().call{value: project.creatorStake}("");
            require(stakeRefundSuccess, "AetherForge: Failed to refund creator stake after claim");
            project.creatorStake = 0;
        }

        emit ProjectFundsClaimed(_projectId, _msgSender(), netClaimable);
    }

    // 10. withdrawContributorRefund: Contributors can claim refunds if a project fails to meet its funding goal.
    function withdrawContributorRefund(uint256 _projectId) external nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherForge: Project does not exist");
        require(project.status != ProjectStatus.Funded, "AetherForge: Project was funded, no refund due");
        require(block.timestamp >= project.endDate, "AetherForge: Funding period not yet ended or still active");
        require(projectContributedAmounts[_projectId][_msgSender()] > 0, "AetherForge: No contribution from this address");

        uint256 refundAmount = projectContributedAmounts[_projectId][_msgSender()];
        projectContributedAmounts[_projectId][_msgSender()] = 0; // Clear amount after refund

        (bool success, ) = _msgSender().call{value: refundAmount}("");
        require(success, "AetherForge: Failed to refund contributor");

        project.currentFunding -= refundAmount; // Reduce total funding (if project failed)
                                                // Note: This simplified model doesn't fully handle if `currentFunding` drops below zero
                                                // with multiple contributors and potential `currentFunding` being used for other things.
                                                // For a robust system, the `currentFunding` should be treated as the total remaining pool.

        emit ProjectRefunded(_projectId, _msgSender(), refundAmount);
    }

    // 11. distributeSustainabilityPoolFunds: Governance-controlled function to distribute funds from the sustainability pool.
    // This function is designed to be called by a governance proposal's `executeProposal`.
    function distributeSustainabilityPoolFunds(address _recipient, uint256 _amount) external nonReentrant {
        require(_msgSender() == address(this), "AetherForge: Only governance can call this function directly");
        require(_recipient != address(0), "AetherForge: Recipient cannot be zero address");
        require(_amount > 0, "AetherForge: Amount must be greater than zero");
        require(sustainabilityPool >= _amount, "AetherForge: Insufficient funds in sustainability pool");

        sustainabilityPool -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "AetherForge: Failed to distribute sustainability funds");

        emit FundsDistributedFromSustainabilityPool(_recipient, _amount);
    }

    // --- IV. AI Oracle & Dynamic Module Evolution (5 functions) ---

    // 12. registerAIOracle: Governance-controlled function to register a new AI oracle.
    // This function is designed to be called by a governance proposal's `executeProposal`.
    function registerAIOracle(address _oracleAddress, string memory _name) external {
        require(_msgSender() == address(this), "AetherForge: Only governance can call this function directly");
        require(_oracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        require(!aiOracles[_oracleAddress].isActive, "AetherForge: Oracle already registered");
        require(bytes(_name).length > 0, "AetherForge: Oracle name cannot be empty");

        aiOracles[_oracleAddress] = AIOracle({
            name: _name,
            reputation: 100, // Initial reputation
            isActive: true
        });
        emit AIOracleRegistered(_oracleAddress, _name);
    }

    // 13. submitAIAnalysisReport: Registered AI oracles submit an analysis report for a module.
    function submitAIAnalysisReport(uint256 _moduleId, string memory _analysisURI, uint8 _score) external onlyRegisteredOracle {
        Module storage module = modules[_moduleId];
        require(module.id != 0, "AetherForge: Module does not exist");
        require(module.projectId != 0, "AetherForge: Module not part of a valid project");
        require(modules[_moduleId].status != ModuleStatus.Minted, "AetherForge: Cannot analyze a minted module");
        require(_score <= 100, "AetherForge: Score cannot exceed 100");

        module.aiOracleAnalysis = _msgSender();
        module.analysisReportURI = _analysisURI;
        module.status = ModuleStatus.AnalysisSubmitted;
        // Optionally update AI oracle reputation based on accuracy later (e.g., via governance proposal)

        emit AIAnalysisSubmitted(_moduleId, _msgSender(), _analysisURI, _score);
    }

    // 14. submitAIRecommendation: Registered AI oracles provide a recommendation for module evolution.
    function submitAIRecommendation(uint256 _moduleId, string memory _recommendationURI) external onlyRegisteredOracle {
        Module storage module = modules[_moduleId];
        require(module.id != 0, "AetherForge: Module does not exist");
        require(module.projectId != 0, "AetherForge: Module not part of a valid project");
        require(modules[_moduleId].status != ModuleStatus.Minted, "AetherForge: Cannot recommend for a minted module");

        module.aiOracleRecommendation = _msgSender();
        module.recommendationURI = _recommendationURI;
        module.status = ModuleStatus.RecommendationSubmitted;

        emit AIRecommendationSubmitted(_moduleId, _msgSender(), _recommendationURI);
    }

    // 15. applyModuleTraitUpdate: Allows approved entities to update a module's dynamic traits.
    // This could be the project creator, or a governance-approved AI proxy, or even a direct AI oracle after approval.
    function applyModuleTraitUpdate(
        uint256 _moduleId,
        string memory _newTraits,
        string memory _newURI // Allow updating URI as well if traits affect metadata location
    ) external {
        Module storage module = modules[_moduleId];
        require(module.id != 0, "AetherForge: Module does not exist");
        require(module.projectId != 0, "AetherForge: Module not part of a valid project");
        require(module.status != ModuleStatus.Minted, "AetherForge: Cannot update traits of a minted module directly via this function (use NFT update logic)");
        
        // Example access control: Only project creator or contract owner (acting as a governance proxy)
        // can directly update module traits/URI.
        // In a real system, this would be more complex, potentially requiring a mini-governance vote per module
        // or linkage to AI oracle recommendations being approved.
        Project storage project = projects[module.projectId];
        require(project.creator == _msgSender() || owner() == _msgSender(), "AetherForge: Unauthorized to update module traits");

        module.currentTraits = _newTraits;
        module.currentURI = _newURI; // Update URI along with traits

        emit ModuleTraitsUpdated(_moduleId, _msgSender(), _newTraits);
    }

    // 16. mintDynamicModuleNFT: Mints a module as a dynamic NFT (ERC721-like), available only after project funding and approval.
    // This function acts as an internal "ERC721 mint" by assigning ownership and URI within the contract.
    function mintDynamicModuleNFT(uint256 _moduleId) external nonReentrant {
        Module storage module = modules[_moduleId];
        require(module.id != 0, "AetherForge: Module does not exist");
        require(module.projectId != 0, "AetherForge: Module not part of a valid project");
        Project storage project = projects[module.projectId];
        require(module.approvedForMint, "AetherForge: Module not approved for minting");
        require(!module.isMintedAsNFT, "AetherForge: Module already minted as NFT");
        require(project.status == ProjectStatus.Funded, "AetherForge: Project must be fully funded");
        
        // For simplicity, the minter becomes the first owner. In a real system, this could be
        // a contributor, or distributed based on project rules, perhaps via another governance action.
        module.nftOwner = _msgSender();
        module.isMintedAsNFT = true;
        module.status = ModuleStatus.Minted; // Update status to reflect it's now an NFT
        
        emit ModuleNFTMinted(_moduleId, _msgSender(), module.currentURI);
    }
    
    // --- V. Reputation & Governance (5 functions) ---

    // 17. proposeGovernanceAction: Allows users with sufficient reputation to propose system changes.
    function proposeGovernanceAction(
        string memory _description,
        bytes memory _callData, // The encoded function call to be executed
        address _target,       // The target contract for the call (can be this contract)
        uint256 _value         // ETH to be sent with the call (e.g., for transferring from sustainability pool)
    ) external returns (uint256) {
        require(userReputation[_msgSender()] >= governanceMinVotingPower, "AetherForge: Insufficient reputation to propose");
        require(bytes(_description).length > 0, "AetherForge: Description cannot be empty");
        require(_target != address(0), "AetherForge: Target address cannot be zero");

        uint256 proposalId = nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: _msgSender(),
            description: _description,
            target: _target,
            callData: _callData,
            value: _value,
            voteCountFor: 0,
            voteCountAgainst: 0,
            startBlock: block.number,
            endBlock: block.number + governanceVotingPeriodBlocks,
            status: ProposalStatus.Pending,
            hasVoted: new mapping(address => bool)()
        });

        emit GovernanceProposalCreated(proposalId, _msgSender(), _description, _target, _value);
        return proposalId;
    }

    // 18. voteOnProposal: Stakeholders vote on active governance proposals.
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "AetherForge: Proposal not open for voting");
        require(block.number <= proposal.endBlock, "AetherForge: Voting period has ended");
        require(userReputation[_msgSender()] >= governanceMinVotingPower, "AetherForge: Insufficient reputation to vote");
        require(!proposal.hasVoted[_msgSender()], "AetherForge: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.voteCountFor += userReputation[_msgSender()]; // Vote weight by reputation
        } else {
            proposal.voteCountAgainst += userReputation[_msgSender()];
        }
        
        emit VotedOnProposal(_proposalId, _msgSender(), _support);
    }

    // 19. executeProposal: Executes a passed governance proposal.
    function executeProposal(uint256 _proposalId) external nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.id != 0, "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "AetherForge: Proposal not in pending state");
        require(block.number > proposal.endBlock, "AetherForge: Voting period not yet ended");

        uint256 votesCast = proposal.voteCountFor + proposal.voteCountAgainst;
        require(votesCast > 0, "AetherForge: No votes cast on proposal");

        // Quorum check: 'for' votes must meet a percentage of total votes cast AND 'for' must have majority
        require(proposal.voteCountFor > proposal.voteCountAgainst, "AetherForge: Proposal did not pass majority");
        // Simplified quorum: require that 'for' votes make up a certain percentage of ALL votes cast on this proposal.
        // A truly advanced DAO might calculate quorum based on total eligible voting power in the system.
        require((proposal.voteCountFor * 10000) / votesCast >= governanceQuorumPercent, "AetherForge: Quorum not met for 'for' votes percentage");

        proposal.status = ProposalStatus.Approved; // Mark as approved before execution attempt

        (bool success, bytes memory returnData) = proposal.target.call{value: proposal.value}(proposal.callData);
        if (success) {
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.FailedExecution;
            // Attempt to decode error message from returnData
            string memory reason = "Execution reverted without specific reason";
            if (returnData.length >= 68) { // Standard error string format is selector (4 bytes) + offset (32 bytes) + string length (32 bytes)
                // This is a common pattern for decoding Solidity revert strings
                assembly {
                    reason := add(returnData, 0x20)
                }
            }
            emit ProposalExecutionFailed(_proposalId, bytes(reason));
            revert(string(abi.encodePacked("AetherForge: Proposal execution failed: ", reason)));
        }
    }

    // 20. rewardUserReputation: Governance-controlled function to manually reward user reputation.
    // This function is designed to be called by a governance proposal's `executeProposal`.
    function rewardUserReputation(address _user, uint256 _amount) external {
        require(_msgSender() == address(this), "AetherForge: Only governance can call this function directly");
        require(_user != address(0), "AetherForge: User address cannot be zero");
        require(_amount > 0, "AetherForge: Amount must be positive");
        userReputation[_user] += _amount;
        emit ReputationRewarded(_user, _amount);
    }

    // 21. penalizeUserReputation: Governance-controlled function to manually penalize user reputation.
    // This function is designed to be called by a governance proposal's `executeProposal`.
    function penalizeUserReputation(address _user, uint256 _amount) external {
        require(_msgSender() == address(this), "AetherForge: Only governance can call this function directly");
        require(_user != address(0), "AetherForge: User address cannot be zero");
        require(_amount > 0, "AetherForge: Amount must be positive");
        if (userReputation[_user] <= _amount) {
            userReputation[_user] = 0;
        } else {
            userReputation[_user] -= _amount;
        }
        emit ReputationPenalized(_user, _amount);
    }

    // --- View Functions (Read-only) ---

    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory name,
            string memory description,
            uint256 fundingGoal,
            uint256 currentFunding,
            uint256 startDate,
            uint256 endDate,
            ProjectStatus status,
            uint256[] memory moduleIds,
            uint256 creatorStake
        )
    {
        Project storage p = projects[_projectId];
        return (
            p.id,
            p.creator,
            p.name,
            p.description,
            p.fundingGoal,
            p.currentFunding,
            p.startDate,
            p.endDate,
            p.status,
            p.moduleIds,
            p.creatorStake
        );
    }

    function getModuleDetails(uint256 _moduleId)
        external
        view
        returns (
            uint256 id,
            uint256 projectId,
            address creator,
            string memory currentURI,
            string memory currentTraits,
            ModuleStatus status,
            address aiOracleAnalysis,
            address aiOracleRecommendation,
            string memory analysisReportURI,
            string memory recommendationURI,
            bool approvedForMint,
            bool isMintedAsNFT,
            address nftOwner
        )
    {
        Module storage m = modules[_moduleId];
        return (
            m.id,
            m.projectId,
            m.creator,
            m.currentURI,
            m.currentTraits,
            m.status,
            m.aiOracleAnalysis,
            m.aiOracleRecommendation,
            m.analysisReportURI,
            m.recommendationURI,
            m.approvedForMint,
            m.isMintedAsNFT,
            m.nftOwner
        );
    }

    function getAIOracleDetails(address _oracleAddress)
        external
        view
        returns (
            string memory name,
            uint256 reputation,
            bool isActive
        )
    {
        AIOracle storage oracle = aiOracles[_oracleAddress];
        return (
            oracle.name,
            oracle.reputation,
            oracle.isActive
        );
    }

    function getGovernanceProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address target,
            bytes memory callData,
            uint256 value,
            uint256 voteCountFor,
            uint256 voteCountAgainst,
            uint256 startBlock,
            uint256 endBlock,
            ProposalStatus status
        )
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.value,
            proposal.voteCountFor,
            proposal.voteCountAgainst,
            proposal.startBlock,
            proposal.endBlock,
            proposal.status
        );
    }

    function getUserContribution(uint256 _projectId, address _user) external view returns (uint256) {
        return projectContributedAmounts[_projectId][_user];
    }
    
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function getOracleReputation(address _oracleAddress) external view returns (uint256) {
        return aiOracles[_oracleAddress].reputation;
    }
}
```