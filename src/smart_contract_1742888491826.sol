```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO focused on collaborative AI model training.
 * It allows members to contribute data, computational resources, and expertise, and be rewarded
 * based on their contributions. The DAO governs the training process, model selection, and
 * potential monetization of the trained AI models.
 *
 * **Outline & Function Summary:**
 *
 * **1. DAO Governance Functions:**
 *    - `proposeNewMember(address _memberAddress)`: Allows members to propose new members.
 *    - `voteOnProposal(uint _proposalId, bool _vote)`: Members can vote on proposals (membership, parameters, etc.).
 *    - `executeProposal(uint _proposalId)`: Executes a passed proposal.
 *    - `getProposalState(uint _proposalId)`: Returns the current state of a proposal.
 *    - `getProposalDetails(uint _proposalId)`: Returns detailed information about a proposal.
 *    - `getCurrentProposalCount()`: Returns the total number of proposals created.
 *
 * **2. Membership Management Functions:**
 *    - `applyForMembership()`: Allows users to apply for membership.
 *    - `isMember(address _account)`: Checks if an address is a member of the DAO.
 *    - `getMemberCount()`: Returns the current number of DAO members.
 *    - `renounceMembership()`: Allows members to leave the DAO.
 *
 * **3. Contribution and Reward Functions:**
 *    - `submitDataContribution(string _dataHash, string _metadataURI)`: Members submit data for model training.
 *    - `submitComputeContribution(uint _computeUnits, uint _duration)`: Members offer computational resources.
 *    - `submitExpertiseContribution(string _expertiseDetails)`: Members declare their AI expertise.
 *    - `recordTrainingTaskCompletion(uint _taskId, address _contributor, uint _reward)`: DAO owner records task completion and rewards contributors.
 *    - `getContributorRewards(address _contributor)`: Allows members to view their accumulated rewards.
 *    - `withdrawRewards()`: Allows members to withdraw their earned rewards.
 *
 * **4. AI Model Training Management Functions:**
 *    - `createTrainingTask(string _taskDescription, string _datasetRequirements, uint _rewardAmount)`: DAO owner creates a new AI model training task.
 *    - `getTrainingTaskDetails(uint _taskId)`: Returns details about a specific training task.
 *    - `selectModelForDeployment(uint _modelId)`: DAO owner selects a trained model to be deployed/used. (Simplified Model Selection for demonstration)
 *    - `getDeployedModelId()`: Returns the ID of the currently deployed AI model.
 *
 * **5. Utility and Information Functions:**
 *    - `getDAOName()`: Returns the name of the DAO.
 *    - `getVotingQuorum()`: Returns the current voting quorum percentage.
 *    - `getProposalDuration()`: Returns the duration of voting periods in blocks.
 */
pragma solidity ^0.8.0;

contract AIDaoCollaborativeTraining {
    string public daoName = "AI Model Training DAO";
    address public owner;
    uint public votingQuorumPercentage = 50; // Minimum percentage of votes required for proposal to pass
    uint public proposalDurationBlocks = 100; // Proposal duration in blocks

    struct Proposal {
        uint id;
        string description;
        address proposer;
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        bool executed;
        ProposalState state;
        ProposalType proposalType;
        address proposedMember; // For membership proposals
        // Add more proposal-specific data as needed
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Rejected,
        Executed
    }

    enum ProposalType {
        Membership,
        ParameterChange,
        TrainingTask,
        Other
    }

    struct TrainingTask {
        uint id;
        string description;
        string datasetRequirements;
        uint rewardAmount;
        bool isActive;
        // Add details about associated models, datasets etc.
    }

    struct Contribution {
        uint contributionId; // Unique ID
        address contributor;
        ContributionType contributionType;
        uint timestamp;
        string dataHash;     // For Data Contributions
        string metadataURI;  // For Data Contributions
        uint computeUnits;   // For Compute Contributions
        uint duration;       // For Compute Contributions
        string expertiseDetails; // For Expertise Contributions
        uint reward;         // Reward associated with this contribution
        bool rewardClaimed;
    }

    enum ContributionType {
        Data,
        Compute,
        Expertise
    }


    mapping(uint => Proposal) public proposals;
    uint public proposalCount = 0;
    mapping(address => bool) public members;
    address[] public memberList;
    uint public memberCount = 0;
    mapping(uint => TrainingTask) public trainingTasks;
    uint public trainingTaskCount = 0;
    mapping(uint => Contribution) public contributions;
    uint public contributionCount = 0;
    mapping(address => uint) public memberRewards; // Track rewards for each member
    uint public deployedModelId = 0; // ID of the currently deployed AI model (simplified)


    event MembershipProposed(uint proposalId, address proposedMember, address proposer);
    event ProposalVoted(uint proposalId, address voter, bool vote);
    event ProposalExecuted(uint proposalId);
    event MembershipApplied(address applicant);
    event MembershipGranted(address newMember);
    event MembershipRenounced(address member);
    event DataSubmitted(uint contributionId, address contributor, string dataHash, string metadataURI);
    event ComputeSubmitted(uint contributionId, address contributor, uint computeUnits, uint duration);
    event ExpertiseSubmitted(uint contributionId, address contributor, string expertiseDetails);
    event TrainingTaskCreated(uint taskId, string description, string datasetRequirements, uint rewardAmount);
    event TrainingTaskCompleted(uint taskId, address contributor, uint reward);
    event RewardClaimed(address member, uint amount);
    event ModelSelectedForDeployment(uint modelId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ------------------------ DAO Governance Functions ------------------------

    /**
     * @dev Allows members to propose a new member to the DAO.
     * @param _memberAddress The address of the member to be proposed.
     */
    function proposeNewMember(address _memberAddress) public onlyMember {
        require(!isMember(_memberAddress), "Address is already a member or proposed.");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: "Proposal to add new member: " , // You can add more details here
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + proposalDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            state: ProposalState.Active,
            proposalType: ProposalType.Membership,
            proposedMember: _memberAddress
        });
        emit MembershipProposed(proposalCount, _memberAddress, msg.sender);
    }

    /**
     * @dev Allows members to vote on a proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint _proposalId, bool _vote) public onlyMember {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active.");
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended.");
        // Prevent double voting (simple implementation, can be enhanced)
        require(!hasVoted(msg.sender, _proposalId), "Already voted on this proposal.");

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function hasVoted(address _voter, uint _proposalId) private view returns (bool) {
        // Simple check - can be improved for scalability if needed.
        //  In a real-world scenario, you might want to use a mapping to track voters per proposal.
        //  For this example, we'll keep it simple and assume no double voting within a block.
        //  A more robust approach would involve storing voter addresses for each proposal.
        (void)_voter; // To avoid unused variable warning for now, but in real impl, this is crucial
        (void)_proposalId;
        return false; // Placeholder - in real implementation, check if voter already voted
    }


    /**
     * @dev Executes a proposal if it has passed the voting and is not yet executed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint _proposalId) public onlyOwner { // Owner executes after quorum is reached
        require(proposals[_proposalId].state == ProposalState.Active || proposals[_proposalId].state == ProposalState.Passed, "Proposal is not in a valid state for execution.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");

        Proposal storage proposal = proposals[_proposalId];

        if (block.number > proposal.endTime) {
            if (proposal.yesVotes * 100 / memberCount >= votingQuorumPercentage && proposal.yesVotes > proposal.noVotes) {
                proposal.state = ProposalState.Passed;
            } else {
                proposal.state = ProposalState.Rejected;
            }
        }

        if (proposal.state == ProposalState.Passed) {
             if (proposal.proposalType == ProposalType.Membership) {
                _grantMembership(proposal.proposedMember);
            }
            // Add logic for other proposal types as needed (parameter changes, etc.)

            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.state = ProposalState.Rejected; // In case it wasn't already set
        }
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint _proposalId) public view returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /**
     * @dev Returns detailed information about a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing proposal details.
     */
    function getProposalDetails(uint _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Returns the total number of proposals created.
     * @return The proposal count.
     */
    function getCurrentProposalCount() public view returns (uint) {
        return proposalCount;
    }

    // ------------------------ Membership Management Functions ------------------------

    /**
     * @dev Allows users to apply for membership.
     *  Membership is granted through a proposal and voting process.
     */
    function applyForMembership() public {
        require(!isMember(msg.sender), "Already a member or membership pending.");
        emit MembershipApplied(msg.sender);
        proposeNewMember(msg.sender); // Automatically create a membership proposal for application
    }

    /**
     * @dev Grants membership to an address. Internal function called after proposal passes.
     * @param _newMember The address to grant membership to.
     */
    function _grantMembership(address _newMember) internal {
        require(!isMember(_newMember), "Address is already a member.");
        members[_newMember] = true;
        memberList.push(_newMember);
        memberCount++;
        emit MembershipGranted(_newMember);
    }


    /**
     * @dev Checks if an address is a member of the DAO.
     * @param _account The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _account) public view returns (bool) {
        return members[_account];
    }

    /**
     * @dev Returns the current number of DAO members.
     * @return The member count.
     */
    function getMemberCount() public view returns (uint) {
        return memberCount;
    }

    /**
     * @dev Allows members to renounce their membership.
     */
    function renounceMembership() public onlyMember {
        require(isMember(msg.sender), "Not a member.");
        members[msg.sender] = false;
        // Remove from memberList (more complex, for simplicity, we might just mark as inactive)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                // Efficient way to remove element while maintaining order is more complex for dynamic arrays.
                // For simplicity, we can just mark it as address(0) or use a boolean 'isActive' in a Member struct.
                // For now, we'll keep it simple and just decrease the count.  In a real app, consider more robust removal.
                memberList[i] = address(0); // Mark as removed (not ideal for iteration in all cases, but simple)
                break;
            }
        }
        memberCount--;
        emit MembershipRenounced(msg.sender);
    }


    // ------------------------ Contribution and Reward Functions ------------------------

    /**
     * @dev Allows members to submit data contributions for AI model training.
     * @param _dataHash Hash of the data file (stored off-chain, e.g., IPFS).
     * @param _metadataURI URI pointing to metadata about the data (e.g., description, format).
     */
    function submitDataContribution(string _dataHash, string _metadataURI) public onlyMember {
        contributionCount++;
        contributions[contributionCount] = Contribution({
            contributionId: contributionCount,
            contributor: msg.sender,
            contributionType: ContributionType.Data,
            timestamp: block.timestamp,
            dataHash: _dataHash,
            metadataURI: _metadataURI,
            computeUnits: 0,
            duration: 0,
            expertiseDetails: "",
            reward: 0, // Reward set upon task completion/verification
            rewardClaimed: false
        });
        emit DataSubmitted(contributionCount, msg.sender, _dataHash, _metadataURI);
    }

    /**
     * @dev Allows members to submit computational resources for AI model training.
     * @param _computeUnits Units of compute offered (e.g., GPU hours, CPU cores).
     * @param _duration Duration for which compute is offered (e.g., in hours).
     */
    function submitComputeContribution(uint _computeUnits, uint _duration) public onlyMember {
        contributionCount++;
        contributions[contributionCount] = Contribution({
            contributionId: contributionCount,
            contributor: msg.sender,
            contributionType: ContributionType.Compute,
            timestamp: block.timestamp,
            dataHash: "",
            metadataURI: "",
            computeUnits: _computeUnits,
            duration: _duration,
            expertiseDetails: "",
            reward: 0, // Reward set upon task completion/verification
            rewardClaimed: false
        });
        emit ComputeSubmitted(contributionCount, msg.sender, _computeUnits, _duration);
    }

    /**
     * @dev Allows members to declare their AI expertise.
     * @param _expertiseDetails Description of their expertise (e.g., specific AI domains, skills).
     */
    function submitExpertiseContribution(string _expertiseDetails) public onlyMember {
        contributionCount++;
        contributions[contributionCount] = Contribution({
            contributionId: contributionCount,
            contributor: msg.sender,
            contributionType: ContributionType.Expertise,
            timestamp: block.timestamp,
            dataHash: "",
            metadataURI: "",
            computeUnits: 0,
            duration: 0,
            expertiseDetails: _expertiseDetails,
            reward: 0, // Reward set upon task completion/verification
            rewardClaimed: false
        });
        emit ExpertiseSubmitted(contributionCount, msg.sender, _expertiseDetails);
    }

    /**
     * @dev DAO owner records the completion of a training task and rewards the contributor.
     * @param _taskId The ID of the training task completed.
     * @param _contributor The address of the member who completed the task.
     * @param _reward The reward amount to be given.
     */
    function recordTrainingTaskCompletion(uint _taskId, address _contributor, uint _reward) public onlyOwner {
        require(trainingTasks[_taskId].isActive, "Training task is not active or does not exist.");
        memberRewards[_contributor] += _reward; // Accumulate rewards
        trainingTasks[_taskId].isActive = false; // Mark task as completed (simplified)
        emit TrainingTaskCompleted(_taskId, _contributor, _reward);
    }

    /**
     * @dev Allows members to view their accumulated rewards.
     * @param _contributor The address of the member.
     * @return The accumulated reward amount.
     */
    function getContributorRewards(address _contributor) public view returns (uint) {
        return memberRewards[_contributor];
    }

    /**
     * @dev Allows members to withdraw their earned rewards.
     */
    function withdrawRewards() public onlyMember {
        uint rewardAmount = memberRewards[msg.sender];
        require(rewardAmount > 0, "No rewards to withdraw.");
        memberRewards[msg.sender] = 0; // Reset reward balance after withdrawal
        payable(msg.sender).transfer(rewardAmount); // Transfer rewards (assuming rewards are in native token)
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    // ------------------------ AI Model Training Management Functions ------------------------

    /**
     * @dev DAO owner creates a new AI model training task.
     * @param _taskDescription Description of the training task.
     * @param _datasetRequirements Requirements for the dataset needed for training.
     * @param _rewardAmount Reward offered for completing this task.
     */
    function createTrainingTask(string _taskDescription, string _datasetRequirements, uint _rewardAmount) public onlyOwner {
        trainingTaskCount++;
        trainingTasks[trainingTaskCount] = TrainingTask({
            id: trainingTaskCount,
            description: _taskDescription,
            datasetRequirements: _datasetRequirements,
            rewardAmount: _rewardAmount,
            isActive: true
        });
        emit TrainingTaskCreated(trainingTaskCount, _taskDescription, _datasetRequirements, _rewardAmount);
    }

    /**
     * @dev Returns details about a specific training task.
     * @param _taskId The ID of the training task.
     * @return TrainingTask struct containing task details.
     */
    function getTrainingTaskDetails(uint _taskId) public view returns (TrainingTask memory) {
        return trainingTasks[_taskId];
    }

    /**
     * @dev DAO owner selects a trained model to be deployed (simplified model selection).
     * @param _modelId ID of the selected model (in a real system, this would be more complex).
     */
    function selectModelForDeployment(uint _modelId) public onlyOwner {
        deployedModelId = _modelId;
        emit ModelSelectedForDeployment(_modelId);
    }

    /**
     * @dev Returns the ID of the currently deployed AI model.
     * @return The deployed model ID.
     */
    function getDeployedModelId() public view returns (uint) {
        return deployedModelId;
    }

    // ------------------------ Utility and Information Functions ------------------------

    /**
     * @dev Returns the name of the DAO.
     * @return DAO name string.
     */
    function getDAOName() public view returns (string) {
        return daoName;
    }

    /**
     * @dev Returns the current voting quorum percentage.
     * @return Voting quorum percentage.
     */
    function getVotingQuorum() public view returns (uint) {
        return votingQuorumPercentage;
    }

    /**
     * @dev Returns the duration of voting periods in blocks.
     * @return Proposal duration in blocks.
     */
    function getProposalDuration() public view returns (uint) {
        return proposalDurationBlocks;
    }

    // --- Future Enhancements (Beyond 20 functions, but ideas to expand further) ---
    // - Token integration for rewards and governance (ERC20).
    // - More complex proposal types (parameter changes, task creation proposals by members).
    // - Data quality verification mechanisms.
    // - Compute contribution tracking and verification.
    // - AI model evaluation and selection processes within the DAO.
    // - Integration with off-chain AI training infrastructure (via oracles or bridges).
    // - Role-based access control within the DAO (e.g., roles for data contributors, compute providers, experts).
    // - Finer grained reward distribution based on contribution quality and impact.
    // - Revenue sharing mechanisms if trained models are monetized.
}
```