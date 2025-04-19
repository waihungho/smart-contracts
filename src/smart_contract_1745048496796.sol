```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative AI Model Training
 * @author Bard (Example - Replace with your name)
 * @dev This contract implements a DAO focused on collaborative AI model training.
 * It allows members to contribute data, computational resources, and expertise to train AI models,
 * governed by decentralized proposals and voting. The trained models and derived insights
 * are managed and accessed through the DAO, fostering a community-driven AI ecosystem.
 *
 * Function Summary:
 * 1.  joinDAO(string _memberName, string _memberDescription): Allows users to request membership to the DAO.
 * 2.  approveMembership(address _memberAddress): Admin function to approve pending membership requests.
 * 3.  revokeMembership(address _memberAddress): Admin function to revoke membership.
 * 4.  submitDataContribution(string _dataHash, string _dataDescription, uint256 _dataSize): Members can contribute datasets with metadata.
 * 5.  voteOnDataContribution(uint256 _contributionId, bool _approve): Members can vote to approve or reject data contributions (quality control).
 * 6.  requestComputeResource(string _resourceDescription, uint256 _computeUnits): Members can request computational resources for model training.
 * 7.  allocateComputeResource(uint256 _resourceRequestId, address _memberAddress): Admin function to allocate compute resources to members.
 * 8.  submitModelTrainingProposal(string _modelGoal, string _datasetIds, string _algorithmDetails): Members propose AI model training projects.
 * 9.  voteOnTrainingProposal(uint256 _proposalId, bool _approve): Members vote on model training proposals.
 * 10. executeTrainingProposal(uint256 _proposalId): Admin function to execute approved training proposals (triggers off-chain process).
 * 11. submitTrainedModel(uint256 _proposalId, string _modelHash, string _modelDescription): Members submit trained models after proposal execution.
 * 12. voteOnModelAcceptance(uint256 _modelId, bool _approve): Members vote to accept or reject submitted trained models (quality assessment).
 * 13. accessTrainedModel(uint256 _modelId): Allows members to access approved trained models (model hashes).
 * 14. submitInsightProposal(uint256 _modelId, string _insightDescription): Members can propose insights derived from trained models.
 * 15. voteOnInsightProposal(uint256 _insightId, bool _approve): Members vote on the validity and value of proposed insights.
 * 16. accessApprovedInsights(uint256 _modelId): Allows members to access approved insights related to a trained model.
 * 17. depositDAOFunds(): Allows anyone to deposit funds into the DAO's treasury.
 * 18. proposeFundingAllocation(address _recipient, uint256 _amount, string _reason): Members can propose funding allocations from the DAO treasury.
 * 19. voteOnFundingAllocation(uint256 _allocationId, bool _approve): Members vote on funding allocation proposals.
 * 20. executeFundingAllocation(uint256 _allocationId): Admin function to execute approved funding allocations (transfer funds).
 * 21. setVotingDuration(uint256 _durationInBlocks): Admin function to change the default voting duration.
 * 22. withdrawAdminFunds(uint256 _amount): Admin function to withdraw funds for operational costs (with governance - optional).
 */

contract AIDao {

    // -------- Structs and Enums --------

    enum MembershipStatus { Pending, Approved, Revoked }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum ContributionStatus { Pending, Approved, Rejected }
    enum ResourceStatus { Requested, Allocated, Completed }
    enum ModelStatus { Submitted, Accepted, Rejected }
    enum InsightStatus { Proposed, Approved, Rejected }

    struct Member {
        string name;
        string description;
        MembershipStatus status;
        uint256 joinTimestamp;
    }

    struct DataContribution {
        address contributor;
        string dataHash; // IPFS hash or similar
        string description;
        uint256 size; // Data size in bytes
        ContributionStatus status;
        uint256 submissionTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    struct ComputeResourceRequest {
        address requester;
        string description;
        uint256 computeUnits; // e.g., GPU hours
        ResourceStatus status;
        uint256 requestTimestamp;
        address allocator;
        uint256 allocationTimestamp;
    }

    struct TrainingProposal {
        address proposer;
        string goal;
        string datasetIds; // Comma-separated IDs of approved datasets
        string algorithmDetails;
        ProposalStatus status;
        uint256 proposalTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    struct TrainedModel {
        uint256 proposalId;
        address submitter;
        string modelHash; // IPFS hash or similar
        string description;
        ModelStatus status;
        uint256 submissionTimestamp;
        uint256 acceptanceVotes;
        uint256 rejectionVotes;
    }

    struct InsightProposal {
        uint256 modelId;
        address proposer;
        string description;
        InsightStatus status;
        uint256 proposalTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    struct FundingAllocationProposal {
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        ProposalStatus status;
        uint256 proposalTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }

    struct Vote {
        address voter;
        bool vote; // true for approve, false for reject
    }


    // -------- State Variables --------

    address public admin;
    mapping(address => Member) public members;
    address[] public pendingMembers;
    address[] public approvedMembersList; // For easier iteration of approved members
    uint256 public memberCount;

    DataContribution[] public dataContributions;
    ComputeResourceRequest[] public computeResourceRequests;
    TrainingProposal[] public trainingProposals;
    TrainedModel[] public trainedModels;
    InsightProposal[] public insightProposals;
    FundingAllocationProposal[] public fundingAllocationProposals;

    uint256 public dataContributionCount;
    uint256 public resourceRequestCount;
    uint256 public trainingProposalCount;
    uint256 public trainedModelCount;
    uint256 public insightProposalCount;
    uint256 public fundingAllocationProposalCount;

    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks

    mapping(uint256 => mapping(address => Vote)) public dataContributionVotes;
    mapping(uint256 => mapping(address => Vote)) public trainingProposalVotes;
    mapping(uint256 => mapping(address => Vote)) public modelAcceptanceVotes;
    mapping(uint256 => mapping(address => Vote)) public insightProposalVotes;
    mapping(uint256 => mapping(address => Vote)) public fundingAllocationVotes;


    // -------- Events --------

    event MembershipRequested(address indexed memberAddress, string memberName);
    event MembershipApproved(address indexed memberAddress);
    event MembershipRevoked(address indexed memberAddress);
    event DataContributionSubmitted(uint256 contributionId, address indexed contributor, string dataHash);
    event DataContributionVoted(uint256 contributionId, address indexed voter, bool vote);
    event DataContributionStatusChanged(uint256 contributionId, ContributionStatus status);
    event ComputeResourceRequested(uint256 requestId, address indexed requester, uint256 computeUnits);
    event ComputeResourceAllocated(uint256 requestId, address indexed allocator, address indexed memberAddress);
    event TrainingProposalSubmitted(uint256 proposalId, address indexed proposer, string goal);
    event TrainingProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event TrainingProposalStatusChanged(uint256 proposalId, ProposalStatus status);
    event TrainingProposalExecuted(uint256 proposalId);
    event TrainedModelSubmitted(uint256 modelId, uint256 proposalId, address indexed submitter, string modelHash);
    event TrainedModelVoted(uint256 modelId, address indexed voter, bool vote);
    event TrainedModelStatusChanged(uint256 modelId, ModelStatus status);
    event InsightProposalSubmitted(uint256 insightId, uint256 modelId, address indexed proposer);
    event InsightProposalVoted(uint256 insightId, address indexed voter, bool vote);
    event InsightProposalStatusChanged(uint256 insightId, InsightStatus status);
    event FundingAllocationProposed(uint256 allocationId, address indexed proposer, address indexed recipient, uint256 amount);
    event FundingAllocationVoted(uint256 allocationId, address indexed voter, bool vote);
    event FundingAllocationStatusChanged(uint256 allocationId, ProposalStatus status);
    event FundingAllocationExecuted(uint256 allocationId, address indexed recipient, uint256 amount);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event AdminFundsWithdrawn(address indexed admin, uint256 amount);
    event VotingDurationChanged(uint256 newDuration);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].status == MembershipStatus.Approved, "Only approved members can call this function.");
        _;
    }

    modifier validDataContributionId(uint256 _contributionId) {
        require(_contributionId < dataContributionCount, "Invalid Data Contribution ID.");
        _;
    }

    modifier validResourceRequestId(uint256 _requestId) {
        require(_requestId < resourceRequestCount, "Invalid Resource Request ID.");
        _;
    }

    modifier validTrainingProposalId(uint256 _proposalId) {
        require(_proposalId < trainingProposalCount, "Invalid Training Proposal ID.");
        _;
    }

    modifier validTrainedModelId(uint256 _modelId) {
        require(_modelId < trainedModelCount, "Invalid Trained Model ID.");
        _;
    }

    modifier validInsightProposalId(uint256 _insightId) {
        require(_insightId < insightProposalCount, "Invalid Insight Proposal ID.");
        _;
    }

    modifier validFundingAllocationId(uint256 _allocationId) {
        require(_allocationId < fundingAllocationProposalCount, "Invalid Funding Allocation ID.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
    }


    // -------- Membership Management --------

    function joinDAO(string memory _memberName, string memory _memberDescription) public {
        require(members[msg.sender].status == MembershipStatus.Revoked || members[msg.sender].status == MembershipStatus.Pending || members[msg.sender].status == MembershipStatus.Approved == false , "Already a member or pending member.");
        members[msg.sender] = Member({
            name: _memberName,
            description: _memberDescription,
            status: MembershipStatus.Pending,
            joinTimestamp: block.timestamp
        });
        pendingMembers.push(msg.sender);
        emit MembershipRequested(msg.sender, _memberName);
    }

    function approveMembership(address _memberAddress) public onlyAdmin {
        require(members[_memberAddress].status == MembershipStatus.Pending, "Member is not pending approval.");
        members[_memberAddress].status = MembershipStatus.Approved;
        approvedMembersList.push(_memberAddress);
        memberCount++;

        // Remove from pending members array (more efficient way would be to use a mapping or linked list for pending members in production)
        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] == _memberAddress) {
                pendingMembers[i] = pendingMembers[pendingMembers.length - 1];
                pendingMembers.pop();
                break;
            }
        }

        emit MembershipApproved(_memberAddress);
    }

    function revokeMembership(address _memberAddress) public onlyAdmin {
        require(members[_memberAddress].status == MembershipStatus.Approved, "Member is not currently approved.");
        members[_memberAddress].status = MembershipStatus.Revoked;
        memberCount--;

        // Remove from approved members list (more efficient way would be to use a mapping or linked list for approved members in production)
        for (uint256 i = 0; i < approvedMembersList.length; i++) {
            if (approvedMembersList[i] == _memberAddress) {
                approvedMembersList[i] = approvedMembersList[approvedMembersList.length - 1];
                approvedMembersList.pop();
                break;
            }
        }
        emit MembershipRevoked(_memberAddress);
    }


    // -------- Data Contribution Management --------

    function submitDataContribution(string memory _dataHash, string memory _dataDescription, uint256 _dataSize) public onlyMember {
        dataContributions.push(DataContribution({
            contributor: msg.sender,
            dataHash: _dataHash,
            description: _dataDescription,
            size: _dataSize,
            status: ContributionStatus.Pending,
            submissionTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0
        }));
        emit DataContributionSubmitted(dataContributionCount, msg.sender, _dataHash);
        dataContributionCount++;
    }

    function voteOnDataContribution(uint256 _contributionId, bool _approve) public onlyMember validDataContributionId(_contributionId) {
        require(dataContributions[_contributionId].status == ContributionStatus.Pending, "Data contribution is not pending.");
        require(dataContributionVotes[_contributionId][msg.sender].voter == address(0), "Already voted on this contribution.");

        dataContributionVotes[_contributionId][msg.sender] = Vote({
            voter: msg.sender,
            vote: _approve
        });

        if (_approve) {
            dataContributions[_contributionId].approvalVotes++;
        } else {
            dataContributions[_contributionId].rejectionVotes++;
        }
        emit DataContributionVoted(_contributionId, msg.sender, _approve);

        // Simple majority for approval (can be adjusted based on DAO governance rules)
        if (dataContributions[_contributionId].approvalVotes > (approvedMembersList.length / 2)) {
            dataContributions[_contributionId].status = ContributionStatus.Approved;
            emit DataContributionStatusChanged(_contributionId, ContributionStatus.Approved);
        } else if (dataContributions[_contributionId].rejectionVotes > (approvedMembersList.length / 2)) {
            dataContributions[_contributionId].status = ContributionStatus.Rejected;
            emit DataContributionStatusChanged(_contributionId, ContributionStatus.Rejected);
        }
    }


    // -------- Compute Resource Management --------

    function requestComputeResource(string memory _resourceDescription, uint256 _computeUnits) public onlyMember {
        computeResourceRequests.push(ComputeResourceRequest({
            requester: msg.sender,
            description: _resourceDescription,
            computeUnits: _computeUnits,
            status: ResourceStatus.Requested,
            requestTimestamp: block.timestamp,
            allocator: address(0),
            allocationTimestamp: 0
        }));
        emit ComputeResourceRequested(resourceRequestCount, msg.sender, _computeUnits);
        resourceRequestCount++;
    }

    function allocateComputeResource(uint256 _resourceRequestId, address _memberAddress) public onlyAdmin validResourceRequestId(_resourceRequestId) {
        require(computeResourceRequests[_resourceRequestId].status == ResourceStatus.Requested, "Resource request is not pending.");
        require(members[_memberAddress].status == MembershipStatus.Approved, "Recipient is not an approved member.");

        computeResourceRequests[_resourceRequestId].status = ResourceStatus.Allocated;
        computeResourceRequests[_resourceRequestId].allocator = msg.sender;
        computeResourceRequests[_resourceRequestId].allocationTimestamp = block.timestamp;
        emit ComputeResourceAllocated(_resourceRequestId, msg.sender, _memberAddress);
    }

    function markComputeResourceCompleted(uint256 _resourceRequestId) public onlyAdmin validResourceRequestId(_resourceRequestId) {
        require(computeResourceRequests[_resourceRequestId].status == ResourceStatus.Allocated, "Resource request is not allocated.");
        computeResourceRequests[_resourceRequestId].status = ResourceStatus.Completed;
        // Potentially trigger reward distribution for compute providers here
    }


    // -------- Model Training Proposal Management --------

    function submitModelTrainingProposal(string memory _modelGoal, string memory _datasetIds, string memory _algorithmDetails) public onlyMember {
        trainingProposals.push(TrainingProposal({
            proposer: msg.sender,
            goal: _modelGoal,
            datasetIds: _datasetIds,
            algorithmDetails: _algorithmDetails,
            status: ProposalStatus.Pending,
            proposalTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0
        }));
        emit TrainingProposalSubmitted(trainingProposalCount, msg.sender, _modelGoal);
        trainingProposalCount++;
    }

    function voteOnTrainingProposal(uint256 _proposalId, bool _approve) public onlyMember validTrainingProposalId(_proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Pending, "Training proposal is not pending.");
        require(trainingProposalVotes[_proposalId][msg.sender].voter == address(0), "Already voted on this proposal.");

        trainingProposalVotes[_proposalId][msg.sender] = Vote({
            voter: msg.sender,
            vote: _approve
        });

        if (_approve) {
            trainingProposals[_proposalId].approvalVotes++;
        } else {
            trainingProposals[_proposalId].rejectionVotes++;
        }
        emit TrainingProposalVoted(_proposalId, msg.sender, _approve);

        // Simple majority for approval
        if (trainingProposals[_proposalId].approvalVotes > (approvedMembersList.length / 2)) {
            trainingProposals[_proposalId].status = ProposalStatus.Approved;
            emit TrainingProposalStatusChanged(_proposalId, ProposalStatus.Approved);
        } else if (trainingProposals[_proposalId].rejectionVotes > (approvedMembersList.length / 2)) {
            trainingProposals[_proposalId].status = ProposalStatus.Rejected;
            emit TrainingProposalStatusChanged(_proposalId, ProposalStatus.Rejected);
        }
    }

    function executeTrainingProposal(uint256 _proposalId) public onlyAdmin validTrainingProposalId(_proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Approved, "Training proposal is not approved.");
        trainingProposals[_proposalId].status = ProposalStatus.Executed;
        emit TrainingProposalExecuted(_proposalId);
        // In a real-world scenario, this function would trigger an off-chain process to start model training.
        // This could involve emitting an event that an off-chain service listens to, or interacting with an oracle.
    }


    // -------- Trained Model Management --------

    function submitTrainedModel(uint256 _proposalId, string memory _modelHash, string memory _modelDescription) public onlyMember validTrainingProposalId(_proposalId) {
        require(trainingProposals[_proposalId].status == ProposalStatus.Executed, "Training proposal must be executed to submit a model.");
        trainedModels.push(TrainedModel({
            proposalId: _proposalId,
            submitter: msg.sender,
            modelHash: _modelHash,
            description: _modelDescription,
            status: ModelStatus.Submitted,
            submissionTimestamp: block.timestamp,
            acceptanceVotes: 0,
            rejectionVotes: 0
        }));
        emit TrainedModelSubmitted(trainedModelCount, _proposalId, msg.sender, _modelHash);
        trainedModelCount++;
    }

    function voteOnModelAcceptance(uint256 _modelId, bool _approve) public onlyMember validTrainedModelId(_modelId) {
        require(trainedModels[_modelId].status == ModelStatus.Submitted, "Trained model is not pending acceptance.");
        require(modelAcceptanceVotes[_modelId][msg.sender].voter == address(0), "Already voted on this model.");

        modelAcceptanceVotes[_modelId][msg.sender] = Vote({
            voter: msg.sender,
            vote: _approve
        });

        if (_approve) {
            trainedModels[_modelId].acceptanceVotes++;
        } else {
            trainedModels[_modelId].rejectionVotes++;
        }
        emit TrainedModelVoted(_modelId, msg.sender, _approve);

        // Simple majority for acceptance
        if (trainedModels[_modelId].acceptanceVotes > (approvedMembersList.length / 2)) {
            trainedModels[_modelId].status = ModelStatus.Accepted;
            emit TrainedModelStatusChanged(_modelId, ModelStatus.Accepted);
        } else if (trainedModels[_modelId].rejectionVotes > (approvedMembersList.length / 2)) {
            trainedModels[_modelId].status = ModelStatus.Rejected;
            emit TrainedModelStatusChanged(_modelId, ModelStatus.Rejected);
        }
    }

    function accessTrainedModel(uint256 _modelId) public onlyMember validTrainedModelId(_modelId) view returns (string memory modelHash, string memory description) {
        require(trainedModels[_modelId].status == ModelStatus.Accepted, "Trained model is not accepted.");
        return (trainedModels[_modelId].modelHash, trainedModels[_modelId].description);
    }


    // -------- Insight Proposal Management --------

    function submitInsightProposal(uint256 _modelId, string memory _insightDescription) public onlyMember validTrainedModelId(_modelId) {
        require(trainedModels[_modelId].status == ModelStatus.Accepted, "Insights can only be proposed for accepted models.");
        insightProposals.push(InsightProposal({
            modelId: _modelId,
            proposer: msg.sender,
            description: _insightDescription,
            status: InsightStatus.Proposed,
            proposalTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0
        }));
        emit InsightProposalSubmitted(insightProposalCount, _modelId, msg.sender);
        insightProposalCount++;
    }

    function voteOnInsightProposal(uint256 _insightId, bool _approve) public onlyMember validInsightProposalId(_insightId) {
        require(insightProposals[_insightId].status == InsightStatus.Proposed, "Insight proposal is not pending.");
        require(insightProposalVotes[_insightId][msg.sender].voter == address(0), "Already voted on this insight proposal.");

        insightProposalVotes[_insightId][msg.sender] = Vote({
            voter: msg.sender,
            vote: _approve
        });

        if (_approve) {
            insightProposals[_insightId].approvalVotes++;
        } else {
            insightProposals[_insightId].rejectionVotes++;
        }
        emit InsightProposalVoted(_insightId, msg.sender, _approve);

        // Simple majority for approval
        if (insightProposals[_insightId].approvalVotes > (approvedMembersList.length / 2)) {
            insightProposals[_insightId].status = InsightStatus.Approved;
            emit InsightProposalStatusChanged(_insightId, InsightStatus.Approved);
        } else if (insightProposals[_insightId].rejectionVotes > (approvedMembersList.length / 2)) {
            insightProposals[_insightId].status = InsightStatus.Rejected;
            emit InsightProposalStatusChanged(_insightId, InsightStatus.Rejected);
        }
    }

    function accessApprovedInsights(uint256 _modelId) public onlyMember validTrainedModelId(_modelId) view returns (string[] memory insights) {
        require(trainedModels[_modelId].status == ModelStatus.Accepted, "Insights can only be accessed for accepted models.");
        uint256 approvedInsightCount = 0;
        for (uint256 i = 0; i < insightProposalCount; i++) {
            if (insightProposals[i].modelId == _modelId && insightProposals[i].status == InsightStatus.Approved) {
                approvedInsightCount++;
            }
        }
        insights = new string[](approvedInsightCount);
        uint256 index = 0;
        for (uint256 i = 0; i < insightProposalCount; i++) {
            if (insightProposals[i].modelId == _modelId && insightProposals[i].status == InsightStatus.Approved) {
                insights[index] = insightProposals[i].description;
                index++;
            }
        }
        return insights;
    }


    // -------- DAO Treasury and Funding --------

    function depositDAOFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function proposeFundingAllocation(address _recipient, uint256 _amount, string memory _reason) public onlyMember {
        require(address(this).balance >= _amount, "DAO treasury balance is insufficient.");
        fundingAllocationProposals.push(FundingAllocationProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            status: ProposalStatus.Pending,
            proposalTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0
        }));
        emit FundingAllocationProposed(fundingAllocationProposalCount, msg.sender, _recipient, _amount);
        fundingAllocationProposalCount++;
    }

    function voteOnFundingAllocation(uint256 _allocationId, bool _approve) public onlyMember validFundingAllocationId(_allocationId) {
        require(fundingAllocationProposals[_allocationId].status == ProposalStatus.Pending, "Funding allocation proposal is not pending.");
        require(fundingAllocationVotes[_allocationId][msg.sender].voter == address(0), "Already voted on this funding allocation proposal.");

        fundingAllocationVotes[_allocationId][msg.sender] = Vote({
            voter: msg.sender,
            vote: _approve
        });

        if (_approve) {
            fundingAllocationProposals[_allocationId].approvalVotes++;
        } else {
            fundingAllocationProposals[_allocationId].rejectionVotes++;
        }
        emit FundingAllocationVoted(_allocationId, msg.sender, _approve);

        // Simple majority for approval
        if (fundingAllocationProposals[_allocationId].approvalVotes > (approvedMembersList.length / 2)) {
            fundingAllocationProposals[_allocationId].status = ProposalStatus.Approved;
            emit FundingAllocationStatusChanged(_allocationId, ProposalStatus.Approved);
        } else if (fundingAllocationProposals[_allocationId].rejectionVotes > (approvedMembersList.length / 2)) {
            fundingAllocationProposals[_allocationId].status = ProposalStatus.Rejected;
            emit FundingAllocationStatusChanged(_allocationId, ProposalStatus.Rejected);
        }
    }

    function executeFundingAllocation(uint256 _allocationId) public onlyAdmin validFundingAllocationId(_allocationId) {
        require(fundingAllocationProposals[_allocationId].status == ProposalStatus.Approved, "Funding allocation proposal is not approved.");
        FundingAllocationProposal storage proposal = fundingAllocationProposals[_allocationId];
        proposal.status = ProposalStatus.Executed;
        (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
        require(success, "Funding allocation transfer failed.");
        emit FundingAllocationExecuted(_allocationId, proposal.recipient, proposal.amount);
    }

    function withdrawAdminFunds(uint256 _amount) public onlyAdmin {
        require(address(this).balance >= _amount, "DAO treasury balance is insufficient for admin withdrawal.");
        (bool success, ) = admin.call{value: _amount}("");
        require(success, "Admin withdrawal failed.");
        emit AdminFundsWithdrawn(admin, _amount);
    }


    // -------- Admin Configuration --------

    function setVotingDuration(uint256 _durationInBlocks) public onlyAdmin {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationChanged(_durationInBlocks);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```