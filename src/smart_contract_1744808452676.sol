```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization for Collaborative AI Model Training (DAOCAI)
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a DAO focused on collaborative AI model training.
 * It incorporates advanced concepts like reputation-based access, dynamic reward systems,
 * decentralized data governance, and modular AI task management.
 * This contract aims to be a creative and trendy solution for decentralized AI collaboration,
 * avoiding duplication of common open-source patterns by focusing on a unique combination
 * of features tailored for AI model development.
 *
 * **Outline & Function Summary:**
 *
 * **I. DAO Governance & Membership:**
 *   1. `proposeDAOParameterChange(string parameterName, uint256 newValue)`: Allows members to propose changes to DAO parameters (e.g., voting durations, reward rates).
 *   2. `voteOnProposal(uint256 proposalId, bool support)`: Members can vote on active DAO parameter change proposals.
 *   3. `executeProposal(uint256 proposalId)`: Executes a passed DAO parameter change proposal.
 *   4. `applyForMembership(string motivation)`: Users can apply to become members of the DAOCAI by providing a motivation statement.
 *   5. `approveMembership(address applicant, bool approve)`: DAO administrators (or via governance) can approve or reject membership applications.
 *   6. `revokeMembership(address member)`: DAO administrators can revoke membership from existing members (subject to governance if needed).
 *   7. `getMemberInfo(address member)`: Retrieves information about a member, including reputation score and participation metrics.
 *
 * **II. AI Project & Task Management:**
 *   8. `createAIProject(string projectName, string projectDescription, string dataRequirements, string modelArchitecture)`: Members can propose and create new AI model training projects.
 *   9. `addTrainingTask(uint256 projectId, string taskDescription, string taskRequirements, uint256 reward)`: Project managers can add specific training tasks to a project, defining requirements and rewards.
 *  10. `applyForTask(uint256 taskId)`: Members can apply to work on specific AI training tasks.
 *  11. `assignTask(uint256 taskId, address assignee)`: Project managers can assign tasks to qualified members.
 *  12. `submitTaskCompletion(uint256 taskId, string resultsHash)`: Members submit their completed task work, providing a hash of the results.
 *  13. `validateTaskCompletion(uint256 taskId, bool valid)`: Project validators (or DAO members) can validate the submitted task work.
 *  14. `distributeTaskRewards(uint256 taskId)`: Distributes rewards to members who completed and validated tasks.
 *
 * **III. Decentralized Data Governance & Contribution:**
 *  15. `proposeDataset(string datasetName, string datasetDescription, string dataHash, string accessConditions)`: Members can propose datasets for use in AI projects, including data hashes and access conditions.
 *  16. `voteOnDatasetProposal(uint256 datasetProposalId, bool support)`: DAO members vote on whether to approve proposed datasets.
 *  17. `registerApprovedDataset(uint256 datasetProposalId)`: Registers an approved dataset for use in projects.
 *  18. `requestDatasetAccess(uint256 datasetId, uint256 projectId)`: Members can request access to approved datasets for specific projects.
 *  19. `grantDatasetAccess(uint256 accessRequestId, bool grant)`: Dataset owners (or DAO governance) can grant or deny dataset access requests.
 *
 * **IV. Reputation & Reward System:**
 *  20. `updateMemberReputation(address member, int256 reputationChange)`: DAO administrators (or automated mechanisms) can update member reputation based on contributions and performance.
 *  21. `setTaskRewardMultiplier(uint256 taskId, uint256 multiplier)`: Project managers can dynamically adjust task reward multipliers based on task complexity or urgency.
 *  22. `withdrawRewards()`: Members can withdraw their accumulated rewards.
 *
 * **V. Utility & Information Functions:**
 *  23. `getProjectDetails(uint256 projectId)`: Retrieves detailed information about a specific AI project.
 *  24. `getTaskDetails(uint256 taskId)`: Retrieves detailed information about a specific AI training task.
 *  25. `getDatasetDetails(uint256 datasetId)`: Retrieves detailed information about a specific dataset.
 *  26. `getActiveProposals()`: Returns a list of currently active DAO parameter change proposals.
 *  27. `getApprovedDatasets()`: Returns a list of approved datasets available for projects.
 *  28. `getAvailableTasksInProject(uint256 projectId)`: Returns a list of tasks available in a specific project.
 */
contract DAOCAI {

    // --- Structs ---

    struct DAOProposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }

    struct Member {
        address memberAddress;
        string motivation;
        uint256 reputationScore;
        uint256 joinTime;
        bool isActive;
    }

    struct AIProject {
        string projectName;
        string projectDescription;
        string dataRequirements;
        string modelArchitecture;
        address projectManager;
        uint256 creationTime;
        bool isActive;
    }

    struct TrainingTask {
        uint256 projectId;
        string taskDescription;
        string taskRequirements;
        uint256 reward;
        address assignee;
        bool isCompleted;
        string resultsHash;
        bool isValidated;
        uint256 rewardMultiplier; // Dynamic reward adjustment
    }

    struct DatasetProposal {
        string datasetName;
        string datasetDescription;
        string dataHash;
        string accessConditions;
        address proposer;
        uint256 proposalTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isApproved;
        bool isRegistered;
    }

    struct Dataset {
        string datasetName;
        string datasetDescription;
        string dataHash;
        string accessConditions;
        address owner;
        uint256 registrationTime;
        bool isRegistered;
    }

    struct DatasetAccessRequest {
        uint256 datasetId;
        uint256 projectId;
        address requester;
        uint256 requestTime;
        bool isGranted;
    }

    // --- State Variables ---

    address public daoAdmin; // Address of the DAO administrator
    uint256 public proposalVoteDuration = 7 days; // Default duration for DAO parameter change proposals
    uint256 public membershipApprovalThreshold = 50; // Percentage of votes needed for membership approval (example)

    mapping(uint256 => DAOProposal) public daoProposals;
    uint256 public proposalCounter;

    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(uint256 => AIProject) public aiProjects;
    uint256 public projectCounter;

    mapping(uint256 => TrainingTask) public trainingTasks;
    uint256 public taskCounter;

    mapping(uint256 => DatasetProposal) public datasetProposals;
    uint256 public datasetProposalCounter;

    mapping(uint256 => Dataset) public datasets;
    uint256 public datasetCounter;

    mapping(uint256 => DatasetAccessRequest) public datasetAccessRequests;
    uint256 public accessRequestCounter;

    mapping(address => uint256) public memberRewardsBalance; // Track reward balances for members

    // --- Events ---

    event DAOParameterProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event DAOProposalVoted(uint256 proposalId, address voter, bool support);
    event DAOProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event MembershipApplied(address applicant, string motivation);
    event MembershipApproved(address member, bool approved);
    event MembershipRevoked(address member);
    event AIProjectCreated(uint256 projectId, string projectName, address projectManager);
    event TrainingTaskAdded(uint256 taskId, uint256 projectId, string taskDescription);
    event TaskApplied(uint256 taskId, address applicant);
    event TaskAssigned(uint256 taskId, address assignee);
    event TaskCompletionSubmitted(uint256 taskId, address submitter, string resultsHash);
    event TaskValidated(uint256 taskId, bool valid, address validator);
    event RewardsDistributed(uint256 taskId, address recipient, uint256 rewardAmount);
    event DatasetProposed(uint256 datasetProposalId, string datasetName, address proposer);
    event DatasetProposalVoted(uint256 datasetProposalId, address voter, bool support);
    event DatasetApproved(uint256 datasetId, string datasetName);
    event DatasetRegistered(uint256 datasetId, string datasetName);
    event DatasetAccessRequested(uint256 accessRequestId, uint256 datasetId, uint256 projectId, address requester);
    event DatasetAccessGranted(uint256 accessRequestId, bool granted);
    event ReputationUpdated(address member, int256 reputationChange, uint256 newReputation);
    event TaskRewardMultiplierSet(uint256 taskId, uint256 multiplier);
    event RewardsWithdrawn(address member, uint256 amount);


    // --- Modifiers ---

    modifier onlyDAOAdmin() {
        require(msg.sender == daoAdmin, "Only DAO admin can perform this action.");
        _;
    }

    modifier onlyDAOMember() {
        require(members[msg.sender].isActive, "Only DAO members can perform this action.");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(daoProposals[proposalId].endTime > block.timestamp, "Proposal has expired.");
        require(!daoProposals[proposalId].executed, "Proposal already executed.");
        _;
    }

    modifier validProject(uint256 projectId) {
        require(aiProjects[projectId].isActive, "Project is not active.");
        _;
    }

    modifier validTask(uint256 taskId) {
        require(trainingTasks[taskId].projectId != 0, "Invalid task ID."); // Assuming 0 is default and invalid
        _;
    }

    modifier validDatasetProposal(uint256 datasetProposalId) {
        require(!datasetProposals[datasetProposalId].isApproved, "Dataset proposal already decided.");
        _;
    }

    modifier validDataset(uint256 datasetId) {
        require(datasets[datasetId].isRegistered, "Dataset is not registered.");
        _;
    }

    modifier taskNotCompleted(uint256 taskId) {
        require(!trainingTasks[taskId].isCompleted, "Task is already completed.");
        _;
    }

    modifier taskNotAssigned(uint256 taskId) {
        require(trainingTasks[taskId].assignee == address(0), "Task is already assigned.");
        _;
    }

    modifier onlyProjectManager(uint256 projectId) {
        require(aiProjects[projectId].projectManager == msg.sender, "Only project manager can perform this action.");
        _;
    }

    modifier onlyTaskAssignee(uint256 taskId) {
        require(trainingTasks[taskId].assignee == msg.sender, "Only task assignee can perform this action.");
        _;
    }

    modifier onlyIfDatasetApproved(uint256 datasetId) {
        require(datasets[datasetId].isRegistered, "Dataset must be approved and registered.");
        _;
    }


    // --- Constructor ---

    constructor() {
        daoAdmin = msg.sender;
    }

    // --- I. DAO Governance & Membership Functions ---

    /// @notice Allows members to propose changes to DAO parameters.
    /// @param _parameterName The name of the DAO parameter to change.
    /// @param _newValue The new value for the parameter.
    function proposeDAOParameterChange(string memory _parameterName, uint256 _newValue) public onlyDAOMember {
        proposalCounter++;
        daoProposals[proposalCounter] = DAOProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit DAOParameterProposed(proposalCounter, _parameterName, _newValue, msg.sender);
    }

    /// @notice Members can vote on active DAO parameter change proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyDAOMember validProposal(_proposalId) {
        require(daoProposals[_proposalId].endTime > block.timestamp, "Voting period ended."); // Redundant check, modifier already handles time
        require(!daoProposals[_proposalId].executed, "Proposal already executed."); // Redundant check, modifier already handles execution

        if (_support) {
            daoProposals[_proposalId].votesFor++;
        } else {
            daoProposals[_proposalId].votesAgainst++;
        }
        emit DAOProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed DAO parameter change proposal if it has reached quorum.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyDAOAdmin validProposal(_proposalId) {
        require(daoProposals[_proposalId].endTime <= block.timestamp, "Voting period not ended yet."); // Check if voting period is over

        uint256 totalVotes = daoProposals[_proposalId].votesFor + daoProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast on proposal."); // Ensure votes were cast
        uint256 quorumPercentage = (daoProposals[_proposalId].votesFor * 100) / totalVotes; // Calculate percentage of 'for' votes

        require(quorumPercentage >= membershipApprovalThreshold, "Proposal did not reach quorum.");

        if (keccak256(abi.encodePacked(daoProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("proposalVoteDuration"))) {
            proposalVoteDuration = daoProposals[_proposalId].newValue;
        } else if (keccak256(abi.encodePacked(daoProposals[_proposalId].parameterName)) == keccak256(abi.encodePacked("membershipApprovalThreshold"))) {
            membershipApprovalThreshold = daoProposals[_proposalId].newValue;
        } // Add more parameter changes here as needed

        daoProposals[_proposalId].executed = true;
        emit DAOProposalExecuted(_proposalId, daoProposals[_proposalId].parameterName, daoProposals[_proposalId].newValue);
    }


    /// @notice Users can apply to become members of the DAOCAI.
    /// @param _motivation A statement explaining why the user wants to join.
    function applyForMembership(string memory _motivation) public {
        require(!members[msg.sender].isActive, "You are already a member.");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            motivation: _motivation,
            reputationScore: 0,
            joinTime: 0,
            isActive: false // Initially inactive, needs approval
        });
        emit MembershipApplied(msg.sender, _motivation);
    }

    /// @notice DAO administrators can approve or reject membership applications.
    /// @param _applicant The address of the user applying for membership.
    /// @param _approve True to approve, false to reject.
    function approveMembership(address _applicant, bool _approve) public onlyDAOAdmin {
        require(!members[_applicant].isActive, "Applicant is already a member or not found."); // Ensure not already member
        if (_approve) {
            members[_applicant].isActive = true;
            members[_applicant].joinTime = block.timestamp;
            memberList.push(_applicant);
            memberCount++;
            emit MembershipApproved(_applicant, true);
        } else {
            delete members[_applicant]; // Remove application data if rejected
            emit MembershipApproved(_applicant, false);
        }
    }

    /// @notice DAO administrators can revoke membership from existing members.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) public onlyDAOAdmin {
        require(members[_member].isActive, "Address is not an active member.");
        members[_member].isActive = false;

        // Remove from memberList (optional, depends on how you want to manage list)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                memberCount--;
                break;
            }
        }

        emit MembershipRevoked(_member);
    }

    /// @notice Retrieves information about a member.
    /// @param _member The address of the member.
    /// @return Member struct containing member information.
    function getMemberInfo(address _member) public view returns (Member memory) {
        return members[_member];
    }


    // --- II. AI Project & Task Management Functions ---

    /// @notice Members can propose and create new AI model training projects.
    /// @param _projectName The name of the AI project.
    /// @param _projectDescription A description of the project.
    /// @param _dataRequirements Description of data needed for the project.
    /// @param _modelArchitecture Description of the model architecture to be used.
    function createAIProject(
        string memory _projectName,
        string memory _projectDescription,
        string memory _dataRequirements,
        string memory _modelArchitecture
    ) public onlyDAOMember {
        projectCounter++;
        aiProjects[projectCounter] = AIProject({
            projectName: _projectName,
            projectDescription: _projectDescription,
            dataRequirements: _dataRequirements,
            modelArchitecture: _modelArchitecture,
            projectManager: msg.sender,
            creationTime: block.timestamp,
            isActive: true
        });
        emit AIProjectCreated(projectCounter, _projectName, msg.sender);
    }

    /// @notice Project managers can add specific training tasks to a project.
    /// @param _projectId The ID of the project to add the task to.
    /// @param _taskDescription A description of the training task.
    /// @param _taskRequirements Requirements for completing the task.
    /// @param _reward The reward offered for completing the task.
    function addTrainingTask(
        uint256 _projectId,
        string memory _taskDescription,
        string memory _taskRequirements,
        uint256 _reward
    ) public onlyDAOMember validProject(_projectId) onlyProjectManager(_projectId) {
        taskCounter++;
        trainingTasks[taskCounter] = TrainingTask({
            projectId: _projectId,
            taskDescription: _taskDescription,
            taskRequirements: _taskRequirements,
            reward: _reward,
            assignee: address(0), // Initially unassigned
            isCompleted: false,
            resultsHash: "",
            isValidated: false,
            rewardMultiplier: 100 // Default multiplier (100% reward)
        });
        emit TrainingTaskAdded(taskCounter, _projectId, _taskDescription);
    }

    /// @notice Members can apply to work on specific AI training tasks.
    /// @param _taskId The ID of the task to apply for.
    function applyForTask(uint256 _taskId) public onlyDAOMember validTask(_taskId) taskNotAssigned(_taskId) taskNotCompleted(_taskId) {
        emit TaskApplied(_taskId, msg.sender);
        // In a real application, you might store applications and have a selection process.
        // For simplicity in this example, task assignment is direct by project manager.
    }

    /// @notice Project managers can assign tasks to qualified members.
    /// @param _taskId The ID of the task to assign.
    /// @param _assignee The address of the member to assign the task to.
    function assignTask(uint256 _taskId, address _assignee) public onlyDAOMember validTask(_taskId) validProject(trainingTasks[_taskId].projectId) onlyProjectManager(trainingTasks[_taskId].projectId) taskNotAssigned(_taskId) taskNotCompleted(_taskId) {
        require(members[_assignee].isActive, "Assignee must be a DAO member.");
        trainingTasks[_taskId].assignee = _assignee;
        emit TaskAssigned(_taskId, _assignee);
    }

    /// @notice Members submit their completed task work, providing a hash of the results.
    /// @param _taskId The ID of the task that is completed.
    /// @param _resultsHash A hash representing the results of the completed task.
    function submitTaskCompletion(uint256 _taskId, string memory _resultsHash) public onlyDAOMember validTask(_taskId) taskNotCompleted(_taskId) onlyTaskAssignee(_taskId) {
        trainingTasks[_taskId].isCompleted = true;
        trainingTasks[_taskId].resultsHash = _resultsHash;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _resultsHash);
    }

    /// @notice Project validators (or DAO members) can validate the submitted task work.
    /// @param _taskId The ID of the task to validate.
    /// @param _valid True if the task is valid, false otherwise.
    function validateTaskCompletion(uint256 _taskId, bool _valid) public onlyDAOMember validTask(_taskId) taskNotCompleted(_taskId) {
        require(trainingTasks[_taskId].isCompleted, "Task must be submitted before validation.");
        trainingTasks[_taskId].isValidated = _valid;
        emit TaskValidated(_taskId, _valid, msg.sender);
    }

    /// @notice Distributes rewards to members who completed and validated tasks.
    /// @param _taskId The ID of the task for which rewards are distributed.
    function distributeTaskRewards(uint256 _taskId) public onlyDAOMember validTask(_taskId) taskNotCompleted(_taskId) {
        require(trainingTasks[_taskId].isValidated, "Task must be validated to distribute rewards.");
        require(trainingTasks[_taskId].assignee != address(0), "Task must be assigned to distribute rewards.");

        uint256 rewardAmount = (trainingTasks[_taskId].reward * trainingTasks[_taskId].rewardMultiplier) / 100; // Apply reward multiplier
        memberRewardsBalance[trainingTasks[_taskId].assignee] += rewardAmount;
        emit RewardsDistributed(_taskId, trainingTasks[_taskId].assignee, rewardAmount);
        // Mark task as completed and potentially inactive to prevent re-distribution.
        // In this simplified version, tasks are just marked completed and rewards distributed once.
    }

    // --- III. Decentralized Data Governance & Contribution Functions ---

    /// @notice Members can propose datasets for use in AI projects.
    /// @param _datasetName The name of the dataset.
    /// @param _datasetDescription A description of the dataset.
    /// @param _dataHash A hash representing the dataset's content.
    /// @param _accessConditions Conditions for accessing the dataset.
    function proposeDataset(
        string memory _datasetName,
        string memory _datasetDescription,
        string memory _dataHash,
        string memory _accessConditions
    ) public onlyDAOMember {
        datasetProposalCounter++;
        datasetProposals[datasetProposalCounter] = DatasetProposal({
            datasetName: _datasetName,
            datasetDescription: _datasetDescription,
            dataHash: _dataHash,
            accessConditions: _accessConditions,
            proposer: msg.sender,
            proposalTime: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            isApproved: false,
            isRegistered: false
        });
        emit DatasetProposed(datasetProposalCounter, _datasetName, msg.sender);
    }

    /// @notice DAO members vote on whether to approve proposed datasets.
    /// @param _datasetProposalId The ID of the dataset proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnDatasetProposal(uint256 _datasetProposalId, bool _support) public onlyDAOMember validDatasetProposal(_datasetProposalId) {
        if (_support) {
            datasetProposals[_datasetProposalId].votesFor++;
        } else {
            datasetProposals[_datasetProposalId].votesAgainst++;
        }
        emit DatasetProposalVoted(_datasetProposalId, msg.sender, _support);
    }

    /// @notice Registers an approved dataset for use in projects after voting.
    /// @param _datasetProposalId The ID of the dataset proposal to register.
    function registerApprovedDataset(uint256 _datasetProposalId) public onlyDAOAdmin validDatasetProposal(_datasetProposalId) {
        uint256 totalVotes = datasetProposals[_datasetProposalId].votesFor + datasetProposals[_datasetProposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast on dataset proposal.");
        uint256 quorumPercentage = (datasetProposals[_datasetProposalId].votesFor * 100) / totalVotes;

        require(quorumPercentage >= membershipApprovalThreshold, "Dataset proposal did not reach quorum.");

        datasetCounter++;
        datasets[datasetCounter] = Dataset({
            datasetName: datasetProposals[_datasetProposalId].datasetName,
            datasetDescription: datasetProposals[_datasetProposalId].datasetDescription,
            dataHash: datasetProposals[_datasetProposalId].dataHash,
            accessConditions: datasetProposals[_datasetProposalId].accessConditions,
            owner: datasetProposals[_datasetProposalId].proposer, // Proposer becomes owner
            registrationTime: block.timestamp,
            isRegistered: true
        });
        datasetProposals[_datasetProposalId].isApproved = true;
        datasetProposals[_datasetProposalId].isRegistered = true;

        emit DatasetApproved(datasetCounter, datasetProposals[_datasetProposalId].datasetName);
        emit DatasetRegistered(datasetCounter, datasetProposals[_datasetProposalId].datasetName);
    }

    /// @notice Members can request access to approved datasets for specific projects.
    /// @param _datasetId The ID of the dataset to request access to.
    /// @param _projectId The ID of the project requiring dataset access.
    function requestDatasetAccess(uint256 _datasetId, uint256 _projectId) public onlyDAOMember validDataset(_datasetId) validProject(_projectId) {
        accessRequestCounter++;
        datasetAccessRequests[accessRequestCounter] = DatasetAccessRequest({
            datasetId: _datasetId,
            projectId: _projectId,
            requester: msg.sender,
            requestTime: block.timestamp,
            isGranted: false
        });
        emit DatasetAccessRequested(accessRequestCounter, _datasetId, _projectId, msg.sender);
    }

    /// @notice Dataset owners (or DAO governance) can grant or deny dataset access requests.
    /// @param _accessRequestId The ID of the dataset access request.
    /// @param _grant True to grant access, false to deny.
    function grantDatasetAccess(uint256 _accessRequestId, bool _grant) public onlyDAOAdmin { // DAO Admin for simplicity, could be dataset owner or governance
        require(datasetAccessRequests[_accessRequestId].datasetId != 0, "Invalid access request ID.");
        datasetAccessRequests[_accessRequestId].isGranted = _grant;
        emit DatasetAccessGranted(_accessRequestId, _grant);
        // In a more complex system, this could trigger events for off-chain data access mechanisms.
    }


    // --- IV. Reputation & Reward System Functions ---

    /// @notice DAO administrators can update member reputation based on contributions and performance.
    /// @param _member The address of the member whose reputation is being updated.
    /// @param _reputationChange The amount to change the reputation score (positive or negative).
    function updateMemberReputation(address _member, int256 _reputationChange) public onlyDAOAdmin {
        members[_member].reputationScore = uint256(int256(members[_member].reputationScore) + _reputationChange); // Handle potential negative change
        emit ReputationUpdated(_member, _reputationChange, members[_member].reputationScore);
    }

    /// @notice Project managers can dynamically adjust task reward multipliers.
    /// @param _taskId The ID of the task to adjust the multiplier for.
    /// @param _multiplier The new reward multiplier percentage (e.g., 150 for 150% reward).
    function setTaskRewardMultiplier(uint256 _taskId, uint256 _multiplier) public onlyDAOMember validTask(_taskId) validProject(trainingTasks[_taskId].projectId) onlyProjectManager(trainingTasks[_taskId].projectId) {
        trainingTasks[_taskId].rewardMultiplier = _multiplier;
        emit TaskRewardMultiplierSet(_taskId, _multiplier);
    }

    /// @notice Members can withdraw their accumulated rewards.
    function withdrawRewards() public onlyDAOMember {
        uint256 amount = memberRewardsBalance[msg.sender];
        require(amount > 0, "No rewards to withdraw.");
        memberRewardsBalance[msg.sender] = 0; // Reset balance after withdrawal
        payable(msg.sender).transfer(amount); // Assuming rewards are in Ether for simplicity. Could be ERC20 token.
        emit RewardsWithdrawn(msg.sender, amount);
    }


    // --- V. Utility & Information Functions ---

    /// @notice Retrieves detailed information about a specific AI project.
    /// @param _projectId The ID of the project.
    /// @return AIProject struct containing project details.
    function getProjectDetails(uint256 _projectId) public view validProject(_projectId) returns (AIProject memory) {
        return aiProjects[_projectId];
    }

    /// @notice Retrieves detailed information about a specific training task.
    /// @param _taskId The ID of the task.
    /// @return TrainingTask struct containing task details.
    function getTaskDetails(uint256 _taskId) public view validTask(_taskId) returns (TrainingTask memory) {
        return trainingTasks[_taskId];
    }

    /// @notice Retrieves detailed information about a specific dataset.
    /// @param _datasetId The ID of the dataset.
    /// @return Dataset struct containing dataset details.
    function getDatasetDetails(uint256 _datasetId) public view validDataset(_datasetId) returns (Dataset memory) {
        return datasets[_datasetId];
    }

    /// @notice Returns a list of currently active DAO parameter change proposals.
    /// @return Array of proposal IDs.
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCounter); // Max size, can optimize if needed
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (daoProposals[i].endTime > block.timestamp && !daoProposals[i].executed) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of active proposals
        assembly {
            mstore(activeProposalIds, count) // Update array length
        }
        return activeProposalIds;
    }

    /// @notice Returns a list of approved datasets available for projects.
    /// @return Array of dataset IDs.
    function getApprovedDatasets() public view returns (uint256[] memory) {
        uint256[] memory approvedDatasetIds = new uint256[](datasetCounter); // Max size, can optimize
        uint256 count = 0;
        for (uint256 i = 1; i <= datasetCounter; i++) {
            if (datasets[i].isRegistered) {
                approvedDatasetIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(approvedDatasetIds, count) // Update array length
        }
        return approvedDatasetIds;
    }

    /// @notice Returns a list of tasks available in a specific project.
    /// @param _projectId The ID of the project.
    /// @return Array of task IDs.
    function getAvailableTasksInProject(uint256 _projectId) public view validProject(_projectId) returns (uint256[] memory) {
        uint256[] memory availableTaskIds = new uint256[](taskCounter); // Max size, can optimize
        uint256 count = 0;
        for (uint256 i = 1; i <= taskCounter; i++) {
            if (trainingTasks[i].projectId == _projectId && trainingTasks[i].assignee == address(0) && !trainingTasks[i].isCompleted) {
                availableTaskIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(availableTaskIds, count) // Update array length
        }
        return availableTaskIds;
    }

    // --- Fallback & Receive (Optional for reward token integration) ---
    // receive() external payable {}
    // fallback() external payable {}
}
```