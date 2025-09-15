Here's a Solidity smart contract named `CognitoNexus`, designed as a decentralized platform for AI model co-creation, verification, and monetization. It integrates several advanced and trendy concepts: community-driven development, verifiable off-chain computation (via proofs and challenges), reputation systems, and on-chain model licensing.

This contract aims to be distinct by combining a full lifecycle of AI model development within a decentralized, incentive-aligned framework, focusing on the coordination and verification aspects on-chain, while heavy computation remains off-chain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Importing IERC20 as a placeholder for a future or integrated native token for advanced reward mechanisms.
// For the initial implementation, rewards will be distributed in ETH from project budgets and stakes.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

/**
 * @title CognitoNexus
 * @dev A Decentralized AI Model Co-creation, Verification, and Monetization Platform.
 *
 * This contract enables a community to collaboratively develop, train, validate, and monetize
 * AI models. It facilitates the entire lifecycle from project proposal to model deployment
 * and usage licensing, incorporating decentralized contributions for data, compute, and evaluation.
 * It features a reputation system and a robust mechanism for challenging potentially fraudulent submissions
 * of data, compute results, or evaluation reports.
 *
 * Outline and Function Summary:
 *
 * 1.  State Variables & Enums: Defines the core data structures and project/submission states.
 * 2.  Events: Notifies off-chain systems about significant contract activities.
 * 3.  Modifiers: Enforces access control, state-based logic, and pausing mechanisms.
 * 4.  I. Core Project Management: Functions for proposing, managing, updating, and finalizing AI projects.
 *     - `proposeProject`: Initiates a new AI model development project with initial budgets and details.
 *     - `updateProjectDetails`: Allows the project owner to update non-critical project information.
 *     - `setProjectBudgets`: Adjusts the ETH budgets allocated for data, compute, and evaluation phases of a project.
 *     - `updateProjectState`: Transitions a project through its lifecycle stages (e.g., from DataGathering to Training).
 *     - `submitFinalModel`: Marks a project as complete by submitting the final trained model's IPFS hash and licensing.
 *     - `withdrawProjectFunds`: Allows the project owner to withdraw any unspent project funds after completion/archiving.
 *     - `getProjectById`: Retrieves detailed information for a specific project.
 * 5.  II. Data Contribution & Licensing: Manages contributions of datasets, including staking and community approval.
 *     - `contributeData`: Users stake ETH to propose a dataset for a project, providing its IPFS hash and license.
 *     - `voteOnDataContribution`: Community members vote to approve or reject a data contribution.
 *     - `finalizeDataContribution`: Processes votes, distributes rewards for approved data, and handles stakes.
 *     - `getDataContributionById`: Retrieves details for a specific data contribution.
 * 6.  III. Compute/Training Task Management: Oversees off-chain AI model training, result submission, and verification.
 *     - `claimComputeTask`: A contributor stakes ETH to claim an off-chain model training task for a project.
 *     - `submitComputeResult`: The claimant submits the results of their training task, including model output and an optional verification proof hash.
 *     - `voteOnComputeResult`: Community members vote to approve or reject a compute result based on its quality/validity.
 *     - `finalizeComputeResult`: Processes votes, rewards successful compute tasks, and handles stakes.
 *     - `getComputeTaskById`: Retrieves details for a specific compute task.
 * 7.  IV. Model Evaluation & Deployment: Handles the evaluation phase of trained models and their eventual deployment.
 *     - `proposeModelEvaluation`: A project owner (or authorized member) initiates an evaluation phase for a specific trained model.
 *     - `submitEvaluationReport`: Evaluators submit their detailed reports (IPFS hash) and a performance score.
 *     - `voteOnEvaluationReport`: Community members vote on the veracity and quality of an evaluation report.
 *     - `finalizeEvaluationAndDeploy`: Finalizes the evaluation, potentially leading to model deployment and rewards for evaluators.
 * 8.  V. Reputation & Staking Management: Manages contributor reputation scores, staking, and reward distribution.
 *     - `getReputationScore`: Retrieves the current reputation score of a contributor.
 *     - `redeemStakedFunds`: A generic function allowing contributors to redeem their staked ETH after a task is finalized (win or lose).
 * 9.  VI. Advanced Concepts & Dispute Resolution: Implements mechanisms for challenging proofs and resolving disputes.
 *     - `challengeSubmission`: Allows any participant to challenge a data, compute, or evaluation submission by staking ETH and providing a reason.
 *     - `resolveChallenge`: An authorized entity (e.g., contract owner) resolves a challenge, penalizing the losing party and rewarding the winning one.
 * 10. VII. Model Monetization: Facilitates licensing of deployed models and revenue sharing.
 *     - `licenseModelUsage`: Allows users to pay a fee to license the usage of a deployed AI model, with funds distributed to project contributors.
 *     - `distributeLicenseRevenue`: Owner-only function to manually trigger revenue distribution from accumulated licensing fees.
 * 11. VIII. Administrative & Utility: Owner-only functions and general utility functions.
 *     - `setMinimumStakeAmount`: Owner-only function to adjust the minimum ETH required for various stakes (data, compute, challenges).
 *     - `pauseContract`: Owner-only function to pause critical contract operations in emergencies.
 *     - `unpauseContract`: Owner-only function to unpause the contract.
 */
contract CognitoNexus is Ownable {
    using Counters for Counters.Counter;

    // --- State Variables & Enums ---

    // Project lifecycle states
    enum ProjectState {
        Proposed,       // Project is defined, awaiting data
        DataGathering,  // Actively collecting data contributions
        Training,       // Actively processing compute tasks
        Evaluation,     // Evaluating trained models
        Deployed,       // Final model is deployed and available for licensing
        Archived        // Project is completed or no longer active
    }

    // Status of a submitted contribution (data, compute, evaluation)
    enum SubmissionStatus {
        Pending,    // Awaiting votes or challenge period to conclude
        Challenged, // Under dispute, awaiting resolution
        Approved,   // Successfully reviewed/verified, eligible for rewards/redeem stake
        Rejected    // Failed review/verification or lost challenge, stake may be penalized
    }

    // Structs for various entities
    struct Project {
        uint256 id;
        address owner;
        string name;
        string description;
        string initialDataRequirements;
        ProjectState state;
        uint256 creationTimestamp;
        uint256 dataBudget;          // ETH budget for data contributions (rewards)
        uint256 computeBudget;       // ETH budget for compute contributions (rewards)
        uint256 evaluationBudget;    // ETH budget for evaluation tasks (rewards)
        string finalModelIpfsHash;   // IPFS hash of the final trained model
        string modelLicenseURI;      // License for the final model usage
        uint256 totalStakedEth;      // Total ETH currently staked by contributors for this project
        uint256 totalLicensedEth;    // Total ETH generated from licensing this model
    }

    struct DataContribution {
        uint256 id;
        uint256 projectId;
        address contributor;
        string ipfsHash;
        string licenseURI;
        uint256 stakeAmount;
        SubmissionStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 submissionTimestamp;
    }

    struct ComputeTask {
        uint256 id;
        uint256 projectId;
        address contributor;
        string[] dataHashesUsed;      // IPFS hashes of data used for training
        string modelOutputHash;       // IPFS hash of the trained model output
        string proofHash;             // IPFS hash of off-chain verification proof (e.g., ZKP claim, can be empty)
        uint256 stakeAmount;
        SubmissionStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 submissionTimestamp;
    }

    struct EvaluationReport {
        uint256 id;
        uint256 projectId;
        uint256 computeTaskId;
        address evaluator;
        string ipfsHashOfReport;
        uint256 performanceScore;     // A score from 0-1000, for example
        uint256 stakeAmount;
        SubmissionStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 submissionTimestamp;
    }

    struct Challenge {
        uint256 id;
        uint256 submissionId;         // The ID of the challenged submission (data, compute, evaluation)
        uint256 projectId;
        address challenger;
        uint256 challengeStake;
        string reasonIpfsHash;        // IPFS hash of the detailed reason for challenge
        bool resolved;
        bool challengerWon;           // True if challenger won, false if submitter won
        uint256 resolutionTimestamp;
        uint8 submissionType;         // 0: Data, 1: Compute, 2: Evaluation. To differentiate submission type.
    }

    // Mapping for reputation scores (simple uint for now)
    mapping(address => uint256) public reputationScores;

    // Counters for unique IDs
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _dataIdCounter;
    Counters.Counter private _computeIdCounter;
    Counters.Counter private _evaluationIdCounter;
    Counters.Counter private _challengeIdCounter;

    // Mappings to store entities by ID
    mapping(uint256 => Project) public projects;
    mapping(uint256 => DataContribution) public dataContributions;
    mapping(uint256 => ComputeTask) public computeTasks;
    mapping(uint256 => EvaluationReport) public evaluationReports;
    mapping(uint256 => Challenge) public challenges;

    // Internal balances for each project's budget and collected fees
    mapping(uint256 => uint256) private projectBalances;

    // To prevent double voting per submission
    mapping(uint256 => mapping(address => bool)) private hasVotedOnData;
    mapping(uint256 => mapping(address => bool)) private hasVotedOnCompute;
    mapping(uint256 => mapping(address => bool)) private hasVotedOnEvaluation;

    // Global parameters
    uint256 public minStakeAmount = 0.01 ether;
    uint256 public minVoteApprovalThreshold = 3; // Minimum positive votes required for approval (can be set to 0 for simple majority)
    uint256 public votePeriodDuration = 3 days; // Duration for voting or challenge period

    // Conceptual token integration (for future advanced rewards)
    IERC20 public cognitoToken;
    address public cognitoTokenMinter; // Address allowed to mint cognitoToken for rewards (optional, for future)

    // Contract pause mechanism
    bool public paused;

    // --- Events ---

    event ProjectProposed(uint256 projectId, address indexed owner, string name, uint256 timestamp);
    event ProjectStateUpdated(uint256 projectId, ProjectState newState, uint256 timestamp);
    event ProjectBudgetsUpdated(uint256 projectId, uint256 dataBudget, uint256 computeBudget, uint256 evaluationBudget);
    event FinalModelSubmitted(uint256 projectId, string ipfsHash, string licenseURI);
    event ProjectFundsWithdrawn(uint256 projectId, address indexed recipient, uint256 amount);

    event DataContributionSubmitted(uint256 dataId, uint256 indexed projectId, address indexed contributor, uint256 stakeAmount);
    event DataContributionVoted(uint256 dataId, address indexed voter, bool approved);
    event DataContributionFinalized(uint256 dataId, SubmissionStatus status, uint256 rewardsDistributed);

    event ComputeTaskClaimed(uint256 computeId, uint256 indexed projectId, address indexed contributor, uint256 stakeAmount);
    event ComputeResultSubmitted(uint252 computeId, uint256 indexed projectId, address indexed contributor, string modelOutputHash);
    event ComputeResultVoted(uint256 computeId, address indexed voter, bool approved);
    event ComputeResultFinalized(uint256 computeId, SubmissionStatus status, uint256 rewardsDistributed);

    event EvaluationReportSubmitted(uint256 evaluationId, uint256 indexed projectId, address indexed evaluator, string ipfsHash);
    event EvaluationReportVoted(uint256 evaluationId, address indexed voter, bool approved);
    event EvaluationFinalized(uint256 evaluationId, SubmissionStatus status, uint256 rewardsDistributed);

    event SubmissionChallenged(uint256 challengeId, uint256 indexed submissionId, uint8 submissionType, address indexed challenger, uint256 challengeStake);
    event ChallengeResolved(uint256 challengeId, bool challengerWon, address indexed winner, address indexed loser, uint256 penaltyAmount);

    event ModelUsageLicensed(uint256 projectId, address indexed licensee, uint256 amountPaid);
    event LicenseRevenueDistributed(uint256 projectId, uint256 totalDistributed);

    event ReputationUpdated(address indexed contributor, uint256 newScore);
    event MinimumStakeAmountSet(uint256 newAmount);

    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].owner == _msgSender(), "CognitoNexus: Not project owner");
        _;
    }

    modifier atProjectState(uint256 _projectId, ProjectState _state) {
        require(projects[_projectId].state == _state, "CognitoNexus: Project is not in the required state");
        _;
    }

    modifier isSubmissionPending(uint256 _id, uint8 _type) {
        if (_type == 0) require(dataContributions[_id].status == SubmissionStatus.Pending, "CognitoNexus: Data submission not pending");
        else if (_type == 1) require(computeTasks[_id].status == SubmissionStatus.Pending, "CognitoNexus: Compute submission not pending");
        else if (_type == 2) require(evaluationReports[_id].status == SubmissionStatus.Pending, "CognitoNexus: Evaluation submission not pending");
        else revert("CognitoNexus: Invalid submission type");
        _;
    }

    modifier hasNotVoted(uint256 _id, uint8 _type) {
        if (_type == 0) {
            require(!hasVotedOnData[_id][_msgSender()], "CognitoNexus: Already voted on this data contribution");
        } else if (_type == 1) {
            require(!hasVotedOnCompute[_id][_msgSender()], "CognitoNexus: Already voted on this compute task");
        } else if (_type == 2) {
            require(!hasVotedOnEvaluation[_id][_msgSender()], "CognitoNexus: Already voted on this evaluation report");
        } else {
            revert("CognitoNexus: Invalid submission type for voting check");
        }
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "CognitoNexus: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "CognitoNexus: Contract is not paused");
        _;
    }

    constructor() {
        paused = false; // Initialize contract as unpaused
        // Optionally set a default CognitoToken address if one is known at deployment
        // cognitoToken = IERC20(0x...); 
        // cognitoTokenMinter = address(this); // Contract itself would be minter, or separate minter contract
    }

    // --- I. Core Project Management ---

    /**
     * @dev Proposes a new AI model development project with initial budgets and details.
     * The `msg.value` sent with this call funds the initial budgets for rewards.
     * @param _name Name of the project.
     * @param _description Detailed description of the project goals.
     * @param _initialDataRequirements Initial data requirements (e.g., "100k images of cats").
     * @param _dataBudget ETH budget allocated for data contributions (rewards).
     * @param _computeBudget ETH budget allocated for compute tasks (rewards).
     * @param _evaluationBudget ETH budget allocated for model evaluation (rewards).
     * @param _initialModelLicenseURI URI for initial licensing terms (e.g., "MIT", "Creative Commons").
     */
    function proposeProject(
        string calldata _name,
        string calldata _description,
        string calldata _initialDataRequirements,
        uint256 _dataBudget,
        uint256 _computeBudget,
        uint256 _evaluationBudget,
        string calldata _initialModelLicenseURI
    ) external payable whenNotPaused {
        require(msg.value == (_dataBudget + _computeBudget + _evaluationBudget), "CognitoNexus: Sent ETH must match sum of all budgets");
        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        projects[newProjectId] = Project({
            id: newProjectId,
            owner: _msgSender(),
            name: _name,
            description: _description,
            initialDataRequirements: _initialDataRequirements,
            state: ProjectState.Proposed,
            creationTimestamp: block.timestamp,
            dataBudget: _dataBudget,
            computeBudget: _computeBudget,
            evaluationBudget: _evaluationBudget,
            finalModelIpfsHash: "",
            modelLicenseURI: _initialModelLicenseURI,
            totalStakedEth: 0,
            totalLicensedEth: 0
        });

        projectBalances[newProjectId] += msg.value; // Add funds to project's internal balance

        emit ProjectProposed(newProjectId, _msgSender(), _name, block.timestamp);
    }

    /**
     * @dev Allows the project owner to update non-critical project information.
     * @param _projectId The ID of the project to update.
     * @param _description New description for the project.
     * @param _initialDataRequirements New initial data requirements.
     * @param _initialModelLicenseURI New initial model license URI.
     */
    function updateProjectDetails(
        uint256 _projectId,
        string calldata _description,
        string calldata _initialDataRequirements,
        string calldata _initialModelLicenseURI
    ) external onlyProjectOwner(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        project.description = _description;
        project.initialDataRequirements = _initialDataRequirements;
        project.modelLicenseURI = _initialModelLicenseURI;
    }

    /**
     * @dev Adjusts the ETH budgets allocated for data, compute, and evaluation phases of a project.
     * Only callable by project owner. Can only add funds to increase the budget.
     * @param _projectId The ID of the project.
     * @param _newDataBudget New ETH budget for data.
     * @param _newComputeBudget New ETH budget for compute.
     * @param _newEvaluationBudget New ETH budget for evaluation.
     */
    function setProjectBudgets(
        uint256 _projectId,
        uint256 _newDataBudget,
        uint256 _newComputeBudget,
        uint256 _newEvaluationBudget
    ) external payable onlyProjectOwner(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        uint256 currentTotalBudget = project.dataBudget + project.computeBudget + project.evaluationBudget;
        uint256 newTotalBudget = _newDataBudget + _newComputeBudget + _newEvaluationBudget;

        require(newTotalBudget >= currentTotalBudget, "CognitoNexus: Cannot decrease total project budget this way. Use withdrawProjectFunds if applicable.");
        
        uint256 fundsToAdd = newTotalBudget - currentTotalBudget;
        require(msg.value == fundsToAdd, "CognitoNexus: Sent ETH must match the increase in total budget.");

        project.dataBudget = _newDataBudget;
        project.computeBudget = _newComputeBudget;
        project.evaluationBudget = _newEvaluationBudget;
        projectBalances[_projectId] += msg.value; // Add the new funds to the project balance

        emit ProjectBudgetsUpdated(_projectId, _newDataBudget, _newComputeBudget, _newEvaluationBudget);
    }

    /**
     * @dev Transitions a project through its lifecycle stages.
     * Only project owner can call this. Basic linear progression, or to Archive.
     * @param _projectId The ID of the project.
     * @param _newState The new state for the project.
     */
    function updateProjectState(uint256 _projectId, ProjectState _newState)
        external
        onlyProjectOwner(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        // Basic state transition logic: must progress or archive
        require(_newState > project.state || _newState == ProjectState.Archived, "CognitoNexus: Invalid state transition");
        
        project.state = _newState;
        emit ProjectStateUpdated(_projectId, _newState, block.timestamp);
    }

    /**
     * @dev Marks a project as complete by submitting the final trained model's IPFS hash and licensing.
     * Only project owner can call this, and project must be in Evaluation state.
     * Automatically moves the project to `Deployed` state.
     * @param _projectId The ID of the project.
     * @param _ipfsHashOfModel IPFS hash pointing to the final trained model.
     * @param _modelLicenseURI Final license URI for the model.
     */
    function submitFinalModel(
        uint256 _projectId,
        string calldata _ipfsHashOfModel,
        string calldata _modelLicenseURI
    ) external onlyProjectOwner(_projectId) atProjectState(_projectId, ProjectState.Evaluation) whenNotPaused {
        Project storage project = projects[_projectId];
        project.finalModelIpfsHash = _ipfsHashOfModel;
        project.modelLicenseURI = _modelLicenseURI;
        project.state = ProjectState.Deployed; // Automatically move to deployed
        
        emit FinalModelSubmitted(_projectId, _ipfsHashOfModel, _modelLicenseURI);
        emit ProjectStateUpdated(_projectId, ProjectState.Deployed, block.timestamp);
    }

    /**
     * @dev Allows the project owner to withdraw any unspent project budget funds after completion or archiving.
     * Callable when project is `Deployed` or `Archived`.
     * @param _projectId The ID of the project.
     */
    function withdrawProjectFunds(uint256 _projectId)
        external
        onlyProjectOwner(_projectId)
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Deployed || project.state == ProjectState.Archived, "CognitoNexus: Project must be deployed or archived to withdraw funds");
        
        uint256 amountToWithdraw = projectBalances[_projectId];
        require(amountToWithdraw > 0, "CognitoNexus: No funds available for withdrawal from this project.");

        projectBalances[_projectId] = 0;
        payable(_msgSender()).transfer(amountToWithdraw);
        emit ProjectFundsWithdrawn(_projectId, _msgSender(), amountToWithdraw);
    }

    /**
     * @dev Retrieves detailed information for a specific project.
     * @param _projectId The ID of the project.
     * @return Project struct containing all details.
     */
    function getProjectById(uint256 _projectId) public view returns (Project memory) {
        require(_projectId <= _projectIdCounter.current() && _projectId > 0, "CognitoNexus: Project does not exist");
        return projects[_projectId];
    }

    // --- II. Data Contribution & Licensing ---

    /**
     * @dev Users stake ETH to propose a dataset for a project, providing its IPFS hash and license.
     * Project must be in `DataGathering` state.
     * @param _projectId The ID of the project to contribute data to.
     * @param _ipfsHash IPFS hash of the dataset.
     * @param _licenseURI License URI for the dataset (e.g., "CC-BY-SA 4.0").
     */
    function contributeData(uint256 _projectId, string calldata _ipfsHash, string calldata _licenseURI) 
        external payable atProjectState(_projectId, ProjectState.DataGathering) whenNotPaused {
        require(msg.value >= minStakeAmount, "CognitoNexus: Insufficient stake amount");
        require(bytes(_ipfsHash).length > 0, "CognitoNexus: Data IPFS hash cannot be empty");

        _dataIdCounter.increment();
        uint256 newDataId = _dataIdCounter.current();

        dataContributions[newDataId] = DataContribution({
            id: newDataId,
            projectId: _projectId,
            contributor: _msgSender(),
            ipfsHash: _ipfsHash,
            licenseURI: _licenseURI,
            stakeAmount: msg.value,
            status: SubmissionStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            submissionTimestamp: block.timestamp
        });

        projects[_projectId].totalStakedEth += msg.value; // For tracking total staked

        emit DataContributionSubmitted(newDataId, _projectId, _msgSender(), msg.value);
    }

    /**
     * @dev Community members vote to approve or reject a data contribution.
     * Requires the submission to be `Pending` and within the `votePeriodDuration`.
     * @param _dataId The ID of the data contribution.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnDataContribution(uint256 _dataId, bool _approve) 
        external isSubmissionPending(_dataId, 0) hasNotVoted(_dataId, 0) whenNotPaused {
        DataContribution storage dataCont = dataContributions[_dataId];
        require(block.timestamp <= dataCont.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period has ended");

        if (_approve) {
            dataCont.approvalVotes++;
        } else {
            dataCont.rejectionVotes++;
        }
        hasVotedOnData[_dataId][_msgSender()] = true; // Mark voter

        emit DataContributionVoted(_dataId, _msgSender(), _approve);
    }

    /**
     * @dev Processes votes, distributes rewards for approved data, and handles stakes.
     * Callable after voting period ends and if not challenged.
     * @param _dataId The ID of the data contribution.
     */
    function finalizeDataContribution(uint256 _dataId) external whenNotPaused {
        DataContribution storage dataCont = dataContributions[_dataId];
        require(dataCont.status == SubmissionStatus.Pending, "CognitoNexus: Data contribution is not pending or already challenged");
        require(block.timestamp > dataCont.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period not yet ended");
        
        uint256 projectId = dataCont.projectId;
        uint256 rewardAmount = 0;
        uint256 reputationChange = 0;

        if (dataCont.approvalVotes >= minVoteApprovalThreshold && dataCont.approvalVotes > dataCont.rejectionVotes) {
            dataCont.status = SubmissionStatus.Approved;
            // Reward for successful data contribution from project's data budget
            rewardAmount = projects[projectId].dataBudget / 100; // Example: 1% of data budget per approval
            if (projectBalances[projectId] >= rewardAmount) {
                projectBalances[projectId] -= rewardAmount;
                payable(dataCont.contributor).transfer(rewardAmount);
            } else {
                rewardAmount = 0; // Not enough budget
            }
            reputationChange = 10; // Increase reputation
        } else {
            dataCont.status = SubmissionStatus.Rejected;
            reputationChange = 0; 
        }

        reputationScores[dataCont.contributor] += reputationChange;
        emit ReputationUpdated(dataCont.contributor, reputationScores[dataCont.contributor]);
        
        emit DataContributionFinalized(_dataId, dataCont.status, rewardAmount);
    }

    /**
     * @dev Retrieves details for a specific data contribution.
     * @param _dataId The ID of the data contribution.
     * @return DataContribution struct containing all details.
     */
    function getDataContributionById(uint256 _dataId) public view returns (DataContribution memory) {
        require(_dataId <= _dataIdCounter.current() && _dataId > 0, "CognitoNexus: Data contribution does not exist");
        return dataContributions[_dataId];
    }

    // --- III. Compute/Training Task Management ---

    /**
     * @dev A contributor stakes ETH to claim an off-chain model training task for a project.
     * This registers their intent to perform computation. Project must be in `Training` state.
     * @param _projectId The ID of the project.
     */
    function claimComputeTask(uint256 _projectId) 
        external payable atProjectState(_projectId, ProjectState.Training) whenNotPaused {
        require(msg.value >= minStakeAmount, "CognitoNexus: Insufficient stake amount");

        _computeIdCounter.increment();
        uint256 newComputeId = _computeIdCounter.current();

        computeTasks[newComputeId] = ComputeTask({
            id: newComputeId,
            projectId: _projectId,
            contributor: _msgSender(),
            dataHashesUsed: new string[](0), // Will be set on submission
            modelOutputHash: "",            // Will be set on submission
            proofHash: "",                  // Will be set on submission
            stakeAmount: msg.value,
            status: SubmissionStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            submissionTimestamp: block.timestamp // Timestamp for claiming, not submission
        });

        projects[_projectId].totalStakedEth += msg.value;

        emit ComputeTaskClaimed(newComputeId, _projectId, _msgSender(), msg.value);
    }

    /**
     * @dev The claimant submits the results of their training task, including model output and an optional verification proof hash.
     * Requires the task to be `Pending`.
     * @param _computeTaskId The ID of the compute task.
     * @param _dataHashesUsed IPFS hashes of the datasets used for training.
     * @param _modelOutputHash IPFS hash of the resulting trained model artifacts.
     * @param _proofHash IPFS hash of an off-chain verification proof (e.g., ZKP). Can be empty.
     */
    function submitComputeResult(
        uint256 _computeTaskId,
        string[] calldata _dataHashesUsed,
        string calldata _modelOutputHash,
        string calldata _proofHash
    ) external whenNotPaused {
        ComputeTask storage computeTask = computeTasks[_computeTaskId];
        require(computeTask.contributor == _msgSender(), "CognitoNexus: Not the contributor for this compute task");
        require(computeTask.status == SubmissionStatus.Pending, "CognitoNexus: Compute task is not pending submission");
        require(bytes(_modelOutputHash).length > 0, "CognitoNexus: Model output hash cannot be empty");

        computeTask.dataHashesUsed = _dataHashesUsed;
        computeTask.modelOutputHash = _modelOutputHash;
        computeTask.proofHash = _proofHash;
        computeTask.submissionTimestamp = block.timestamp; // Set timestamp for voting period
        // Status remains Pending, awaiting votes/challenge

        emit ComputeResultSubmitted(_computeTaskId, computeTask.projectId, _msgSender(), _modelOutputHash);
    }

    /**
     * @dev Community members vote to approve or reject a compute result based on its quality/validity.
     * Requires the submission to be `Pending` and within the `votePeriodDuration`.
     * @param _computeTaskId The ID of the compute task.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnComputeResult(uint256 _computeTaskId, bool _approve) 
        external isSubmissionPending(_computeTaskId, 1) hasNotVoted(_computeTaskId, 1) whenNotPaused {
        ComputeTask storage computeTask = computeTasks[_computeTaskId];
        require(block.timestamp <= computeTask.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period has ended");

        if (_approve) {
            computeTask.approvalVotes++;
        } else {
            computeTask.rejectionVotes++;
        }
        hasVotedOnCompute[_computeTaskId][_msgSender()] = true; // Mark voter

        emit ComputeResultVoted(_computeTaskId, _msgSender(), _approve);
    }

    /**
     * @dev Processes votes, rewards successful compute tasks, and handles stakes.
     * Callable after voting period ends and if not challenged.
     * @param _computeTaskId The ID of the compute task.
     */
    function finalizeComputeResult(uint256 _computeTaskId) external whenNotPaused {
        ComputeTask storage computeTask = computeTasks[_computeTaskId];
        require(computeTask.status == SubmissionStatus.Pending, "CognitoNexus: Compute task is not pending or already challenged");
        require(block.timestamp > computeTask.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period not yet ended");

        uint256 projectId = computeTask.projectId;
        uint256 rewardAmount = 0;
        uint256 reputationChange = 0;

        if (computeTask.approvalVotes >= minVoteApprovalThreshold && computeTask.approvalVotes > computeTask.rejectionVotes) {
            computeTask.status = SubmissionStatus.Approved;
            rewardAmount = projects[projectId].computeBudget / 50; // Example: 2% of compute budget
            if (projectBalances[projectId] >= rewardAmount) {
                projectBalances[projectId] -= rewardAmount;
                payable(computeTask.contributor).transfer(rewardAmount);
            } else {
                rewardAmount = 0;
            }
            reputationChange = 20;
        } else {
            computeTask.status = SubmissionStatus.Rejected;
            reputationChange = 0;
        }

        reputationScores[computeTask.contributor] += reputationChange;
        emit ReputationUpdated(computeTask.contributor, reputationScores[computeTask.contributor]);

        emit ComputeResultFinalized(_computeTaskId, computeTask.status, rewardAmount);
    }

    /**
     * @dev Retrieves details for a specific compute task.
     * @param _computeTaskId The ID of the compute task.
     * @return ComputeTask struct containing all details.
     */
    function getComputeTaskById(uint256 _computeTaskId) public view returns (ComputeTask memory) {
        require(_computeTaskId <= _computeIdCounter.current() && _computeTaskId > 0, "CognitoNexus: Compute task does not exist");
        return computeTasks[_computeTaskId];
    }

    // --- IV. Model Evaluation & Deployment ---

    /**
     * @dev A project owner (or authorized member) initiates an evaluation phase for a specific trained model.
     * Requires the project to be in `Evaluation` state. The evaluator's stake is for their report.
     * @param _projectId The ID of the project.
     * @param _computeTaskId The ID of the compute task whose result is to be evaluated.
     */
    function proposeModelEvaluation(uint256 _projectId, uint256 _computeTaskId)
        external payable atProjectState(_projectId, ProjectState.Evaluation) whenNotPaused {
        require(msg.value >= minStakeAmount, "CognitoNexus: Insufficient stake amount"); // Stake from the evaluator for submitting report
        require(computeTasks[_computeTaskId].projectId == _projectId, "CognitoNexus: Compute task does not belong to this project");
        require(computeTasks[_computeTaskId].status == SubmissionStatus.Approved, "CognitoNexus: Compute task must be approved before evaluation");

        _evaluationIdCounter.increment();
        uint256 newEvaluationId = _evaluationIdCounter.current();

        evaluationReports[newEvaluationId] = EvaluationReport({
            id: newEvaluationId,
            projectId: _projectId,
            computeTaskId: _computeTaskId,
            evaluator: _msgSender(),
            ipfsHashOfReport: "", // Will be set on submission
            performanceScore: 0,  // Will be set on submission
            stakeAmount: msg.value,
            status: SubmissionStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            submissionTimestamp: block.timestamp // Timestamp for claiming, not submission
        });
        
        projects[_projectId].totalStakedEth += msg.value;

        emit EvaluationReportSubmitted(newEvaluationId, _projectId, _msgSender(), ""); // ipfsHashOfReport is empty initially
    }

    /**
     * @dev Evaluators submit their detailed reports (IPFS hash) and a performance score.
     * Requires the evaluation task to be `Pending`.
     * @param _evaluationId The ID of the evaluation task.
     * @param _ipfsHashOfReport IPFS hash of the detailed evaluation report.
     * @param _performanceScore A score from 0-1000 representing model performance.
     */
    function submitEvaluationReport(uint256 _evaluationId, string calldata _ipfsHashOfReport, uint256 _performanceScore)
        external whenNotPaused {
        EvaluationReport storage evalReport = evaluationReports[_evaluationId];
        require(evalReport.evaluator == _msgSender(), "CognitoNexus: Not the assigned evaluator");
        require(evalReport.status == SubmissionStatus.Pending, "CognitoNexus: Evaluation task not pending submission");
        require(bytes(_ipfsHashOfReport).length > 0, "CognitoNexus: Report IPFS hash cannot be empty");
        require(_performanceScore <= 1000, "CognitoNexus: Performance score out of bounds (0-1000)");

        evalReport.ipfsHashOfReport = _ipfsHashOfReport;
        evalReport.performanceScore = _performanceScore;
        evalReport.submissionTimestamp = block.timestamp; // Set timestamp for voting period
        // Status remains Pending

        emit EvaluationReportSubmitted(_evaluationId, evalReport.projectId, _msgSender(), _ipfsHashOfReport);
    }

    /**
     * @dev Community members vote on the veracity and quality of an evaluation report.
     * Requires the submission to be `Pending` and within the `votePeriodDuration`.
     * @param _evaluationId The ID of the evaluation report.
     * @param _approve True for approval, false for rejection.
     */
    function voteOnEvaluationReport(uint256 _evaluationId, bool _approve) 
        external isSubmissionPending(_evaluationId, 2) hasNotVoted(_evaluationId, 2) whenNotPaused {
        EvaluationReport storage evalReport = evaluationReports[_evaluationId];
        require(block.timestamp <= evalReport.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period has ended");

        if (_approve) {
            evalReport.approvalVotes++;
        } else {
            evalReport.rejectionVotes++;
        }
        hasVotedOnEvaluation[_evaluationId][_msgSender()] = true; // Mark voter

        emit EvaluationReportVoted(_evaluationId, _msgSender(), _approve);
    }

    /**
     * @dev Finalizes the evaluation, potentially leading to model deployment and rewards for evaluators.
     * If approved, project state can be advanced to `Deployed` (handled by project owner `submitFinalModel`).
     * Callable after voting period ends and if not challenged.
     * @param _evaluationId The ID of the evaluation report.
     */
    function finalizeEvaluationAndDeploy(uint256 _evaluationId) external whenNotPaused {
        EvaluationReport storage evalReport = evaluationReports[_evaluationId];
        require(evalReport.status == SubmissionStatus.Pending, "CognitoNexus: Evaluation report is not pending or already challenged");
        require(block.timestamp > evalReport.submissionTimestamp + votePeriodDuration, "CognitoNexus: Voting period not yet ended");

        uint256 projectId = evalReport.projectId;
        uint256 rewardAmount = 0;
        uint256 reputationChange = 0;

        if (evalReport.approvalVotes >= minVoteApprovalThreshold && evalReport.approvalVotes > evalReport.rejectionVotes) {
            evalReport.status = SubmissionStatus.Approved;
            rewardAmount = projects[projectId].evaluationBudget / 20; // Example: 5% of evaluation budget
            if (projectBalances[projectId] >= rewardAmount) {
                projectBalances[projectId] -= rewardAmount;
                payable(evalReport.evaluator).transfer(rewardAmount);
            } else {
                rewardAmount = 0;
            }
            reputationChange = 15;
            // Project owner would then call `submitFinalModel` to officially deploy based on this evaluation
        } else {
            evalReport.status = SubmissionStatus.Rejected;
            reputationChange = 0;
        }

        reputationScores[evalReport.evaluator] += reputationChange;
        emit ReputationUpdated(evalReport.evaluator, reputationScores[evalReport.evaluator]);
        
        emit EvaluationFinalized(_evaluationId, evalReport.status, rewardAmount);
    }

    // --- V. Reputation & Staking Management ---

    /**
     * @dev Retrieves the current reputation score of a contributor.
     * @param _contributor The address of the contributor.
     * @return The reputation score.
     */
    function getReputationScore(address _contributor) external view returns (uint256) {
        return reputationScores[_contributor];
    }

    /**
     * @dev Allows contributors to redeem their staked ETH after a task is finalized (win or lose).
     * If submission was approved, full stake is returned. If rejected or lost challenge, stake is partially returned or forfeited.
     * @param _submissionId The ID of the submission (data, compute, evaluation).
     * @param _submissionType The type of submission (0: Data, 1: Compute, 2: Evaluation).
     */
    function redeemStakedFunds(uint256 _submissionId, uint8 _submissionType) external whenNotPaused {
        uint256 stakeAmount = 0;
        address contributor;
        SubmissionStatus status;
        uint256 projectId;

        if (_submissionType == 0) { // Data Contribution
            DataContribution storage dc = dataContributions[_submissionId];
            require(dc.contributor == _msgSender(), "CognitoNexus: Not the contributor of this data submission");
            require(dc.status == SubmissionStatus.Approved || dc.status == SubmissionStatus.Rejected, "CognitoNexus: Data submission not finalized");
            stakeAmount = dc.stakeAmount;
            contributor = dc.contributor;
            status = dc.status;
            projectId = dc.projectId;
            dc.stakeAmount = 0; // Prevent double redemption
        } else if (_submissionType == 1) { // Compute Task
            ComputeTask storage ct = computeTasks[_submissionId];
            require(ct.contributor == _msgSender(), "CognitoNexus: Not the contributor of this compute task");
            require(ct.status == SubmissionStatus.Approved || ct.status == SubmissionStatus.Rejected, "CognitoNexus: Compute task not finalized");
            stakeAmount = ct.stakeAmount;
            contributor = ct.contributor;
            status = ct.status;
            projectId = ct.projectId;
            ct.stakeAmount = 0; // Prevent double redemption
        } else if (_submissionType == 2) { // Evaluation Report
            EvaluationReport storage er = evaluationReports[_submissionId];
            require(er.evaluator == _msgSender(), "CognitoNexus: Not the evaluator of this report");
            require(er.status == SubmissionStatus.Approved || er.status == SubmissionStatus.Rejected, "CognitoNexus: Evaluation report not finalized");
            stakeAmount = er.stakeAmount;
            contributor = er.evaluator;
            status = er.status;
            projectId = er.projectId;
            er.stakeAmount = 0; // Prevent double redemption
        } else {
            revert("CognitoNexus: Invalid submission type");
        }

        require(stakeAmount > 0, "CognitoNexus: No stake to redeem or already redeemed");

        uint256 returnAmount = 0;
        if (status == SubmissionStatus.Approved) {
            returnAmount = stakeAmount;
        } else { // Rejected or lost a challenge
            // For rejected submissions, a portion of the stake is forfeited to the project.
            // Example: 50% penalty for rejected submissions.
            returnAmount = stakeAmount / 2;
            projectBalances[projectId] += (stakeAmount - returnAmount); // Add forfeited stake to project budget
        }

        projects[projectId].totalStakedEth -= stakeAmount; // Decrease conceptual total staked
        payable(contributor).transfer(returnAmount);
    }

    // --- VI. Advanced Concepts & Dispute Resolution ---

    /**
     * @dev Allows any participant to challenge a data, compute, or evaluation submission by staking ETH and providing a reason.
     * This moves the submission to a `Challenged` state. Requires the submission to be `Pending`.
     * @param _submissionId The ID of the submission to challenge.
     * @param _submissionType The type of submission (0: Data, 1: Compute, 2: Evaluation).
     * @param _reasonIpfsHash IPFS hash of the detailed reason for the challenge.
     */
    function challengeSubmission(uint256 _submissionId, uint8 _submissionType, string calldata _reasonIpfsHash) 
        external payable whenNotPaused {
        require(msg.value >= minStakeAmount * 2, "CognitoNexus: Insufficient challenge stake (must be double min stake)");
        require(bytes(_reasonIpfsHash).length > 0, "CognitoNexus: Reason for challenge cannot be empty");

        address submitter;
        uint256 projectId;

        if (_submissionType == 0) { // Data Contribution
            DataContribution storage dc = dataContributions[_submissionId];
            require(dc.status == SubmissionStatus.Pending, "CognitoNexus: Data contribution not pending");
            submitter = dc.contributor;
            projectId = dc.projectId;
            dc.status = SubmissionStatus.Challenged;
        } else if (_submissionType == 1) { // Compute Task
            ComputeTask storage ct = computeTasks[_submissionId];
            require(ct.status == SubmissionStatus.Pending, "CognitoNexus: Compute task not pending");
            submitter = ct.contributor;
            projectId = ct.projectId;
            ct.status = SubmissionStatus.Challenged;
        } else if (_submissionType == 2) { // Evaluation Report
            EvaluationReport storage er = evaluationReports[_submissionId];
            require(er.status == SubmissionStatus.Pending, "CognitoNexus: Evaluation report not pending");
            submitter = er.evaluator;
            projectId = er.projectId;
            er.status = SubmissionStatus.Challenged;
        } else {
            revert("CognitoNexus: Invalid submission type");
        }
        
        require(submitter != _msgSender(), "CognitoNexus: Cannot challenge your own submission");

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            submissionId: _submissionId,
            projectId: projectId,
            challenger: _msgSender(),
            challengeStake: msg.value,
            reasonIpfsHash: _reasonIpfsHash,
            resolved: false,
            challengerWon: false,
            resolutionTimestamp: 0,
            submissionType: _submissionType
        });

        projects[projectId].totalStakedEth += msg.value; // For tracking total staked

        emit SubmissionChallenged(newChallengeId, _submissionId, _submissionType, _msgSender(), msg.value);
    }

    /**
     * @dev An authorized entity (e.g., contract owner) resolves a challenge, penalizing the losing party and rewarding the winning one.
     * This function effectively determines the final status of the challenged submission.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _challengerWon True if the challenger's claim is upheld, false if the original submitter is validated.
     */
    function resolveChallenge(uint256 _challengeId, bool _challengerWon) external onlyOwner whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.resolved, "CognitoNexus: Challenge already resolved");

        address submitter;
        uint256 submitterStake = 0;
        SubmissionStatus finalStatus;
        uint256 projectId = challenge.projectId;

        // Retrieve submission details and set final status based on challenge outcome
        if (challenge.submissionType == 0) {
            DataContribution storage dc = dataContributions[challenge.submissionId];
            require(dc.status == SubmissionStatus.Challenged, "CognitoNexus: Data submission not in challenged state");
            submitter = dc.contributor;
            submitterStake = dc.stakeAmount;
            dc.status = _challengerWon ? SubmissionStatus.Rejected : SubmissionStatus.Approved;
            finalStatus = dc.status;
        } else if (challenge.submissionType == 1) {
            ComputeTask storage ct = computeTasks[challenge.submissionId];
            require(ct.status == SubmissionStatus.Challenged, "CognitoNexus: Compute task not in challenged state");
            submitter = ct.contributor;
            submitterStake = ct.stakeAmount;
            ct.status = _challengerWon ? SubmissionStatus.Rejected : SubmissionStatus.Approved;
            finalStatus = ct.status;
        } else if (challenge.submissionType == 2) {
            EvaluationReport storage er = evaluationReports[challenge.submissionId];
            require(er.status == SubmissionStatus.Challenged, "CognitoNexus: Evaluation report not in challenged state");
            submitter = er.evaluator;
            submitterStake = er.stakeAmount;
            er.status = _challengerWon ? SubmissionStatus.Rejected : SubmissionStatus.Approved;
            finalStatus = er.status;
        } else {
            revert("CognitoNexus: Invalid submission type in challenge");
        }

        uint256 totalStake = submitterStake + challenge.challengeStake;
        uint256 penaltyPortion = totalStake / 2; // Example: 50% penalty for loser, goes to winner and project
        uint256 winnerReward = totalStake - penaltyPortion; // Winner gets half of the combined stakes

        address winner;
        address loser;
        uint256 reputationChangeWinner = 0;
        uint256 reputationChangeLoser = 0;

        if (_challengerWon) {
            winner = challenge.challenger;
            loser = submitter;
            reputationChangeWinner = 30; // Significant reputation boost
            reputationChangeLoser = -20; // Significant reputation drop
        } else {
            winner = submitter;
            loser = challenge.challenger;
            reputationChangeWinner = 20;
            reputationChangeLoser = -10;
        }

        // Transfer rewards and penalties
        projectBalances[projectId] += (totalStake - winnerReward); // Forfeited funds go to project budget
        payable(winner).transfer(winnerReward);

        // Update reputation
        reputationScores[winner] += reputationChangeWinner;
        // Ensure reputation doesn't go negative
        reputationScores[loser] = reputationScores[loser] >= uint256(reputationChangeLoser * -1) ? reputationScores[loser] + reputationChangeLoser : 0;
        emit ReputationUpdated(winner, reputationScores[winner]);
        emit ReputationUpdated(loser, reputationScores[loser]);

        // Mark challenge as resolved
        challenge.resolved = true;
        challenge.challengerWon = _challengerWon;
        challenge.resolutionTimestamp = block.timestamp;
        
        // Remove stakes from project's conceptual total staked amount
        projects[projectId].totalStakedEth -= (submitterStake + challenge.challengeStake);

        // Clear individual stake amounts to prevent double redemption from `redeemStakedFunds`
        if (challenge.submissionType == 0) dataContributions[challenge.submissionId].stakeAmount = 0;
        else if (challenge.submissionType == 1) computeTasks[challenge.submissionId].stakeAmount = 0;
        else if (challenge.submissionType == 2) evaluationReports[challenge.submissionId].stakeAmount = 0;

        emit ChallengeResolved(_challengeId, _challengerWon, winner, loser, penaltyPortion);

        // Emit a finalization event to reflect the outcome of the challenged submission
        if (challenge.submissionType == 0) emit DataContributionFinalized(challenge.submissionId, finalStatus, 0); // Rewards handled by challenge resolution
        else if (challenge.submissionType == 1) emit ComputeResultFinalized(challenge.submissionId, finalStatus, 0);
        else if (challenge.submissionType == 2) emit EvaluationFinalized(challenge.submissionId, finalStatus, 0);
    }

    // --- VII. Model Monetization ---

    /**
     * @dev Allows users to pay a fee to license the usage of a deployed AI model, with funds accumulated for distribution.
     * Requires the project to be in `Deployed` state.
     * @param _projectId The ID of the deployed project.
     */
    function licenseModelUsage(uint256 _projectId) external payable atProjectState(_projectId, ProjectState.Deployed) whenNotPaused {
        require(msg.value > 0, "CognitoNexus: Licensing fee must be greater than zero");
        
        Project storage project = projects[_projectId];
        project.totalLicensedEth += msg.value;
        projectBalances[_projectId] += msg.value; // Add to project balance for distribution

        emit ModelUsageLicensed(_projectId, _msgSender(), msg.value);
    }

    /**
     * @dev Owner-only function to manually trigger revenue distribution from accumulated licensing fees.
     * This is a simplified distribution. A more advanced system would have specific contributor splits
     * based on their contribution type and reputation. For this example, a portion goes to the project
     * owner and the remainder to the contract owner (as a protocol fee).
     * @param _projectId The ID of the project.
     */
    function distributeLicenseRevenue(uint256 _projectId) external onlyProjectOwner(_projectId) atProjectState(_projectId, ProjectState.Deployed) whenNotPaused {
        Project storage project = projects[_projectId];
        require(projectBalances[_projectId] > 0, "CognitoNexus: No licensing revenue to distribute");

        uint256 totalRevenue = projectBalances[_projectId];
        projectBalances[_projectId] = 0; // Clear project balance

        // Simplified distribution:
        // 50% to project owner
        // 50% to protocol (contract owner)
        uint256 ownerShare = totalRevenue / 2;
        uint256 protocolShare = totalRevenue - ownerShare;

        payable(project.owner).transfer(ownerShare);
        payable(owner()).transfer(protocolShare); // Protocol fee to contract owner

        emit LicenseRevenueDistributed(_projectId, totalRevenue);
    }

    // --- VIII. Administrative & Utility ---

    /**
     * @dev Owner-only function to adjust the minimum ETH required for various stakes (data, compute, challenges).
     * @param _newAmount The new minimum stake amount in wei.
     */
    function setMinimumStakeAmount(uint256 _newAmount) external onlyOwner whenNotPaused {
        require(_newAmount > 0, "CognitoNexus: Minimum stake amount must be greater than zero");
        minStakeAmount = _newAmount;
        emit MinimumStakeAmountSet(_newAmount);
    }

    /**
     * @dev Owner-only function to pause critical contract operations in emergencies.
     * Prevents most state-changing user interactions.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Owner-only function to unpause the contract after an emergency.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Fallback function to prevent accidental ETH transfers without specific methods.
     * Reverts if ETH is sent directly to the contract without calling an explicit function.
     */
    receive() external payable {
        revert("CognitoNexus: ETH sent directly to contract. Please use specific functions.");
    }
}
```