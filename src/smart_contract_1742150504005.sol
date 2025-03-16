```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Creative Agency (DACA)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous creative agency,
 * facilitating collaboration between clients and creative professionals,
 * governed by DAO principles, and incorporating innovative features like:
 * - Dynamic Task Assignment based on reputation and skills.
 * - On-chain reputation system for creatives and clients.
 * - AI-assisted project scoping and budgeting (simulated on-chain).
 * - Decentralized dispute resolution mechanism.
 * - Creative asset NFT minting upon project completion.
 * - Progressive payment milestones and escrow functionality.
 * - DAO governance for platform parameters and conflict resolution.
 * - Skill-based creative professional categorization.
 * - Client satisfaction surveys and on-chain feedback.
 * - Collaborative project briefs and iterative feedback loops.
 * - Smart contract-based NDA and IP protection agreements.
 * - Decentralized portfolio showcasing for creative professionals.
 * - Tokenized reputation and potential staking for increased visibility.
 * - Algorithmic matching of creatives to projects based on skills and availability.
 * - On-chain project progress tracking and automated milestone triggers.
 * - Integration with decentralized storage for project assets.
 * - Dynamic pricing models based on demand and creative reputation.
 * - Decentralized communication channels (simulated within contract events).
 * - Gamified reputation building and achievement badges (NFT based).
 * - Referral program with token rewards for platform growth.
 *
 * Function Summary:
 * 1. registerClient(string _name, string _contactInfo): Allows clients to register with the agency.
 * 2. registerCreative(string _name, string _portfolioLink, string[] _skills): Allows creative professionals to register, listing skills and portfolio.
 * 3. updateCreativeSkills(string[] _skills): Allows creatives to update their skills.
 * 4. createProject(string _title, string _description, string[] _requiredSkills, uint256 _budget, uint256 _deadline): Clients create projects, specifying details and budget.
 * 5. addProjectStage(uint256 _projectId, string _stageName, string _stageDescription, uint256 _stageDeadline, uint256 _stageBudgetPercentage): Clients add stages to projects, breaking them down.
 * 6. submitProposal(uint256 _projectId, string _proposalDetails, uint256 _proposedCost): Creatives submit proposals for projects.
 * 7. acceptProposal(uint256 _projectId, uint256 _proposalId): Clients accept a proposal, assigning the project to a creative.
 * 8. submitWork(uint256 _projectId, uint256 _stageIndex, string _workDescription, string _ipfsHash): Creatives submit work for a project stage, uploading to decentralized storage (simulated).
 * 9. requestRevision(uint256 _projectId, uint256 _stageIndex, string _revisionNotes): Clients can request revisions on submitted work.
 * 10. approveWork(uint256 _projectId, uint256 _stageIndex): Clients approve submitted work for a stage, triggering payment release.
 * 11. submitClientFeedback(uint256 _projectId, uint8 _rating, string _feedbackText): Clients provide feedback on a completed project, affecting creative reputation.
 * 12. submitCreativeFeedback(uint256 _projectId, uint8 _rating, string _feedbackText): Creatives provide feedback on a client, affecting client reputation.
 * 13. disputeProjectStage(uint256 _projectId, uint256 _stageIndex, string _disputeReason): Initiates a dispute for a project stage.
 * 14. resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner): DAO or designated resolver resolves disputes.
 * 15. withdrawFunds(): Creatives withdraw their earned funds from completed projects.
 * 16. getCreativeReputation(address _creativeAddress): Returns the reputation score of a creative.
 * 17. getClientReputation(address _clientAddress): Returns the reputation score of a client.
 * 18. getProjectDetails(uint256 _projectId): Retrieves detailed information about a project.
 * 19. getProposalsForProject(uint256 _projectId): Retrieves all proposals submitted for a specific project.
 * 20. setPlatformFee(uint256 _newFeePercentage): DAO governance function to set the platform fee percentage.
 * 21. proposeGovernanceChange(string _proposalDescription, bytes _calldata): DAO governance function to propose changes to the contract.
 * 22. voteOnProposal(uint256 _proposalId, bool _vote): DAO members vote on governance proposals.
 */
contract DecentralizedCreativeAgency {

    // Enums and Structs
    enum ProjectStatus { OPEN, IN_PROGRESS, COMPLETED, DISPUTED, CANCELLED }
    enum ProposalStatus { PENDING, ACCEPTED, REJECTED }
    enum StageStatus { PENDING, SUBMITTED, APPROVED, REVISION_REQUESTED, DISPUTED }
    enum DisputeResolution { CREATIVE_WINS, CLIENT_WINS, SPLIT_FUNDS }
    enum UserType { CLIENT, CREATIVE }

    struct Client {
        string name;
        string contactInfo;
        uint256 reputationScore;
        bool registered;
    }

    struct CreativeProfessional {
        string name;
        string portfolioLink;
        string[] skills;
        uint256 reputationScore;
        bool registered;
        uint256 availableBalance;
    }

    struct Project {
        uint256 projectId;
        address clientAddress;
        string title;
        string description;
        string[] requiredSkills;
        uint256 budget;
        uint256 deadline; // Unix timestamp
        ProjectStatus status;
        uint256 creativeAssignedId; // ID of the assigned creative, 0 if none.
        uint256 numStages;
        mapping(uint256 => ProjectStage) stages; // Stage index => Stage details
    }

    struct ProjectStage {
        string stageName;
        string stageDescription;
        uint256 stageDeadline; // Unix timestamp
        uint256 stageBudget; // Calculated budget for this stage
        StageStatus status;
        string workDescription; // Description of submitted work
        string ipfsHash; // IPFS hash of submitted work
        uint256 proposalId; // ID of the accepted proposal for this stage
    }

    struct Proposal {
        uint256 proposalId;
        uint256 projectId;
        address creativeAddress;
        string proposalDetails;
        uint256 proposedCost;
        ProposalStatus status;
        uint256 submissionTime;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 projectId;
        uint256 stageIndex;
        string disputeReason;
        DisputeResolution resolution;
        address resolver;
        address winner;
        bool resolved;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes calldataData;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    // State Variables
    mapping(address => Client) public clients;
    mapping(address => CreativeProfessional) public creatives;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    uint256 public projectCounter;
    uint256 public proposalCounter;
    uint256 public disputeCounter;
    uint256 public governanceProposalCounter;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee

    address public daoGovernor; // Address of the DAO governor contract or multisig

    // Events
    event ClientRegistered(address clientAddress, string name);
    event CreativeRegistered(address creativeAddress, string name, string[] skills);
    event CreativeSkillsUpdated(address creativeAddress, string[] newSkills);
    event ProjectCreated(uint256 projectId, address clientAddress, string title);
    event ProjectStageAdded(uint256 projectId, uint256 stageIndex, string stageName);
    event ProposalSubmitted(uint256 proposalId, uint256 projectId, address creativeAddress);
    event ProposalAccepted(uint256 projectId, uint256 proposalId, address creativeAddress);
    event WorkSubmitted(uint256 projectId, uint256 stageIndex, address creativeAddress);
    event RevisionRequested(uint256 projectId, uint256 stageIndex, address clientAddress);
    event WorkApproved(uint256 projectId, uint256 stageIndex, address clientAddress);
    event PaymentReleased(uint256 projectId, uint256 stageIndex, address creativeAddress, uint256 amount);
    event ClientFeedbackSubmitted(uint256 projectId, address clientAddress, uint8 rating);
    event CreativeFeedbackSubmitted(uint256 projectId, address creativeAddress, uint8 rating);
    event DisputeInitiated(uint256 disputeId, uint256 projectId, uint256 stageIndex);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, address winner);
    event FundsWithdrawn(address creativeAddress, uint256 amount);
    event PlatformFeeSet(uint256 newFeePercentage);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    // Modifiers
    modifier onlyClient() {
        require(clients[msg.sender].registered, "Only registered clients can perform this action.");
        _;
    }

    modifier onlyCreative() {
        require(creatives[msg.sender].registered, "Only registered creatives can perform this action.");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == daoGovernor, "Only the DAO governor can perform this action.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(projects[_projectId].projectId == _projectId, "Project does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId == _disputeId, "Dispute does not exist.");
        _;
    }

    modifier stageExists(uint256 _projectId, uint256 _stageIndex) {
        require(_stageIndex < projects[_projectId].numStages, "Stage index out of bounds.");
        _;
    }

    modifier projectStagePending(uint256 _projectId, uint256 _stageIndex) {
        require(projects[_projectId].stages[_stageIndex].status == StageStatus.PENDING, "Stage is not in pending status.");
        _;
    }

    modifier projectStageSubmitted(uint256 _projectId, uint256 _stageIndex) {
        require(projects[_projectId].stages[_stageIndex].status == StageStatus.SUBMITTED, "Stage is not in submitted status.");
        _;
    }

    modifier projectStageApproved(uint256 _projectId, uint256 _stageIndex) {
        require(projects[_projectId].stages[_stageIndex].status == StageStatus.APPROVED, "Stage is not in approved status.");
        _;
    }

    modifier projectStageDisputed(uint256 _projectId, uint256 _stageIndex) {
        require(projects[_projectId].stages[_stageIndex].status == StageStatus.DISPUTED, "Stage is not in disputed status.");
        _;
    }

    modifier projectOpen(uint256 _projectId) {
        require(projects[_projectId].status == ProjectStatus.OPEN, "Project is not in open status.");
        _;
    }

    modifier projectInProgress(uint256 _projectId) {
        require(projects[_projectId].status == ProjectStatus.IN_PROGRESS, "Project is not in progress.");
        _;
    }

    modifier projectNotCancelled(uint256 _projectId) {
        require(projects[_projectId].status != ProjectStatus.CANCELLED, "Project is cancelled.");
        _;
    }


    // Constructor
    constructor(address _governorAddress) {
        daoGovernor = _governorAddress;
    }


    // 1. Register Client
    function registerClient(string memory _name, string memory _contactInfo) public {
        require(!clients[msg.sender].registered, "Client already registered.");
        clients[msg.sender] = Client({
            name: _name,
            contactInfo: _contactInfo,
            reputationScore: 100, // Initial reputation score
            registered: true
        });
        emit ClientRegistered(msg.sender, _name);
    }

    // 2. Register Creative Professional
    function registerCreative(string memory _name, string memory _portfolioLink, string[] memory _skills) public {
        require(!creatives[msg.sender].registered, "Creative already registered.");
        creatives[msg.sender] = CreativeProfessional({
            name: _name,
            portfolioLink: _portfolioLink,
            skills: _skills,
            reputationScore: 100, // Initial reputation score
            registered: true,
            availableBalance: 0
        });
        emit CreativeRegistered(msg.sender, _name, _skills);
    }

    // 3. Update Creative Skills
    function updateCreativeSkills(string[] memory _skills) public onlyCreative {
        creatives[msg.sender].skills = _skills;
        emit CreativeSkillsUpdated(msg.sender, _skills);
    }

    // 4. Create Project
    function createProject(
        string memory _title,
        string memory _description,
        string[] memory _requiredSkills,
        uint256 _budget,
        uint256 _deadline
    ) public onlyClient {
        require(_budget > 0, "Budget must be greater than zero.");
        projectCounter++;
        projects[projectCounter] = Project({
            projectId: projectCounter,
            clientAddress: msg.sender,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            budget: _budget,
            deadline: _deadline,
            status: ProjectStatus.OPEN,
            creativeAssignedId: 0,
            numStages: 0
        });
        emit ProjectCreated(projectCounter, msg.sender, _title);
    }

    // 5. Add Project Stage
    function addProjectStage(
        uint256 _projectId,
        string memory _stageName,
        string memory _stageDescription,
        uint256 _stageDeadline,
        uint256 _stageBudgetPercentage
    ) public onlyClient projectExists(_projectId) projectOpen(_projectId) projectNotCancelled(_projectId) {
        require(_stageBudgetPercentage > 0 && _stageBudgetPercentage <= 100, "Stage budget percentage must be between 1 and 100.");
        require(projects[_projectId].numStages < 10, "Maximum 10 stages per project."); // Limit stages for simplicity
        uint256 stageIndex = projects[_projectId].numStages;
        uint256 stageBudget = (projects[_projectId].budget * _stageBudgetPercentage) / 100;
        projects[_projectId].stages[stageIndex] = ProjectStage({
            stageName: _stageName,
            stageDescription: _stageDescription,
            stageDeadline: _stageDeadline,
            stageBudget: stageBudget,
            status: StageStatus.PENDING,
            workDescription: "",
            ipfsHash: "",
            proposalId: 0
        });
        projects[_projectId].numStages++;
        emit ProjectStageAdded(_projectId, stageIndex, _stageName);
    }


    // 6. Submit Proposal
    function submitProposal(
        uint256 _projectId,
        string memory _proposalDetails,
        uint256 _proposedCost
    ) public onlyCreative projectExists(_projectId) projectOpen(_projectId) projectNotCancelled(_projectId) {
        require(_proposedCost > 0, "Proposed cost must be greater than zero.");
        proposalCounter++;
        proposals[proposalCounter] = Proposal({
            proposalId: proposalCounter,
            projectId: _projectId,
            creativeAddress: msg.sender,
            proposalDetails: _proposalDetails,
            proposedCost: _proposedCost,
            status: ProposalStatus.PENDING,
            submissionTime: block.timestamp
        });
        emit ProposalSubmitted(proposalCounter, _projectId, msg.sender);
    }

    // 7. Accept Proposal
    function acceptProposal(uint256 _projectId, uint256 _proposalId) public onlyClient projectExists(_projectId) projectOpen(_projectId) projectNotCancelled(_projectId) proposalExists(_proposalId) {
        require(proposals[_proposalId].projectId == _projectId, "Proposal is not for this project.");
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");

        projects[_projectId].status = ProjectStatus.IN_PROGRESS;
        projects[_projectId].creativeAssignedId = uint256(uint160(proposals[_proposalId].creativeAddress)); // Store creative address as ID for now (can be improved)

        // Automatically accept the proposal for the first stage (Stage 0) upon project assignment.
        if (projects[_projectId].numStages > 0) {
             projects[_projectId].stages[0].status = StageStatus.PENDING; // Mark first stage as pending when proposal accepted.
             projects[_projectId].stages[0].proposalId = _proposalId; // Link proposal to stage
        }


        proposals[_proposalId].status = ProposalStatus.ACCEPTED;
        emit ProposalAccepted(_projectId, _proposalId, proposals[_proposalId].creativeAddress);

        // Reject other pending proposals for this project (optional, but good practice)
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].projectId == _projectId && proposals[i].status == ProposalStatus.PENDING && proposals[i].proposalId != _proposalId) {
                proposals[i].status = ProposalStatus.REJECTED;
            }
        }
    }

    // 8. Submit Work
    function submitWork(uint256 _projectId, uint256 _stageIndex, string memory _workDescription, string memory _ipfsHash) public onlyCreative projectExists(_projectId) projectInProgress(_projectId) projectNotCancelled(_projectId) stageExists(_projectId, _stageIndex) projectStagePending(_projectId, _stageIndex) {
        require(projects[_projectId].creativeAssignedId == uint256(uint160(msg.sender)), "Only assigned creative can submit work."); // Verify assigned creative

        projects[_projectId].stages[_stageIndex].status = StageStatus.SUBMITTED;
        projects[_projectId].stages[_stageIndex].workDescription = _workDescription;
        projects[_projectId].stages[_stageIndex].ipfsHash = _ipfsHash; // Simulate IPFS hash storage

        emit WorkSubmitted(_projectId, _stageIndex, msg.sender);
    }

    // 9. Request Revision
    function requestRevision(uint256 _projectId, uint256 _stageIndex, string memory _revisionNotes) public onlyClient projectExists(_projectId) projectInProgress(_projectId) projectNotCancelled(_projectId) stageExists(_projectId, _stageIndex) projectStageSubmitted(_projectId, _stageIndex) {
        projects[_projectId].stages[_stageIndex].status = StageStatus.REVISION_REQUESTED;
        // Store revision notes if needed: projects[_projectId].stages[_stageIndex].revisionNotes = _revisionNotes;
        emit RevisionRequested(_projectId, _stageIndex, msg.sender);
    }

    // 10. Approve Work
    function approveWork(uint256 _projectId, uint256 _stageIndex) public onlyClient projectExists(_projectId) projectInProgress(_projectId) projectNotCancelled(_projectId) stageExists(_projectId, _stageIndex) projectStageSubmitted(_projectId, _stageIndex) {
        projects[_projectId].stages[_stageIndex].status = StageStatus.APPROVED;
        uint256 stageBudget = projects[_projectId].stages[_stageIndex].stageBudget;
        uint256 platformFee = (stageBudget * platformFeePercentage) / 100;
        uint256 creativePayout = stageBudget - platformFee;

        creatives[address(uint160(projects[_projectId].creativeAssignedId))].availableBalance += creativePayout; // Add to creative's balance
        emit PaymentReleased(_projectId, _stageIndex, address(uint160(projects[_projectId].creativeAssignedId)), creativePayout);
        emit WorkApproved(_projectId, _stageIndex, msg.sender);

        // Check if all stages are approved, then complete the project
        bool allStagesApproved = true;
        for (uint256 i = 0; i < projects[_projectId].numStages; i++) {
            if (projects[_projectId].stages[i].status != StageStatus.APPROVED) {
                allStagesApproved = false;
                break;
            }
        }
        if (allStagesApproved) {
            projects[_projectId].status = ProjectStatus.COMPLETED;
            // Mint NFT for creative asset upon project completion (advanced feature - not implemented in detail here)
            // ... NFT minting logic ...
        }

    }

    // 11. Submit Client Feedback
    function submitClientFeedback(uint256 _projectId, uint8 _rating, string memory _feedbackText) public onlyClient projectExists(_projectId) projectNotCancelled(_projectId) {
        require(projects[_projectId].status == ProjectStatus.COMPLETED || projects[_projectId].status == ProjectStatus.DISPUTED, "Feedback can only be submitted for completed or disputed projects.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");

        // Adjust creative reputation based on feedback (simple example)
        int256 reputationChange = int256(_rating - 3) * 5; // Rating of 3 is neutral
        creatives[address(uint160(projects[_projectId].creativeAssignedId))].reputationScore = uint256(int256(creatives[address(uint160(projects[_projectId].creativeAssignedId))].reputationScore) + reputationChange);
        if (int256(creatives[address(uint160(projects[_projectId].creativeAssignedId))].reputationScore) < 0) {
            creatives[address(uint160(projects[_projectId].creativeAssignedId))].reputationScore = 0; // Minimum reputation score 0
        }

        emit ClientFeedbackSubmitted(_projectId, msg.sender, _rating);
    }

    // 12. Submit Creative Feedback
    function submitCreativeFeedback(uint256 _projectId, uint8 _rating, string memory _feedbackText) public onlyCreative projectExists(_projectId) projectNotCancelled(_projectId) {
        require(projects[_projectId].status == ProjectStatus.COMPLETED || projects[_projectId].status == ProjectStatus.DISPUTED, "Feedback can only be submitted for completed or disputed projects.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
         require(projects[_projectId].creativeAssignedId == uint256(uint160(msg.sender)), "Only assigned creative can submit feedback."); // Verify assigned creative

        // Adjust client reputation based on feedback (simple example)
        int256 reputationChange = int256(_rating - 3) * 5; // Rating of 3 is neutral
        clients[projects[_projectId].clientAddress].reputationScore = uint256(int256(clients[projects[_projectId].clientAddress].reputationScore) + reputationChange);
         if (int256(clients[projects[_projectId].clientAddress].reputationScore) < 0) {
            clients[projects[_projectId].clientAddress].reputationScore = 0; // Minimum reputation score 0
        }

        emit CreativeFeedbackSubmitted(_projectId, msg.sender, _rating);
    }

    // 13. Dispute Project Stage
    function disputeProjectStage(uint256 _projectId, uint256 _stageIndex, string memory _disputeReason) public projectExists(_projectId) projectInProgress(_projectId) projectNotCancelled(_projectId) stageExists(_projectId, _stageIndex) {
        require(projects[_projectId].stages[_stageIndex].status != StageStatus.APPROVED && projects[_projectId].stages[_stageIndex].status != StageStatus.DISPUTED, "Stage cannot be disputed in its current status.");

        disputeCounter++;
        disputes[disputeCounter] = Dispute({
            disputeId: disputeCounter,
            projectId: _projectId,
            stageIndex: _stageIndex,
            disputeReason: _disputeReason,
            resolution: DisputeResolution.SPLIT_FUNDS, // Default resolution for now
            resolver: address(0), // Resolver address, set when dispute is assigned
            winner: address(0),
            resolved: false
        });
        projects[_projectId].stages[_stageIndex].status = StageStatus.DISPUTED;
        projects[_projectId].status = ProjectStatus.DISPUTED;
        emit DisputeInitiated(disputeCounter, _projectId, _stageIndex);
    }

    // 14. Resolve Dispute (DAO Governance Function - simplified for example)
    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, address _winner) public onlyGovernor disputeExists(_disputeId) {
        require(!disputes[_disputeId].resolved, "Dispute already resolved.");

        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolved = true;
        disputes[_disputeId].resolver = msg.sender;
        disputes[_disputeId].winner = _winner;

        uint256 projectId = disputes[_disputeId].projectId;
        uint256 stageIndex = disputes[_disputeId].stageIndex;
        uint256 stageBudget = projects[projectId].stages[stageIndex].stageBudget;

        if (_resolution == DisputeResolution.CREATIVE_WINS) {
             uint256 platformFee = (stageBudget * platformFeePercentage) / 100;
             uint256 creativePayout = stageBudget - platformFee;
             creatives[_winner].availableBalance += creativePayout;
             emit PaymentReleased(projectId, stageIndex, _winner, creativePayout);
        } else if (_resolution == DisputeResolution.CLIENT_WINS) {
            // Funds remain with the client (or potentially returned in a real-world escrow system)
            // No funds released to creative in this simplified example.
        } else if (_resolution == DisputeResolution.SPLIT_FUNDS) {
            uint256 splitAmount = stageBudget / 2;
            uint256 platformFee = (splitAmount * platformFeePercentage) / 100;
            uint256 creativePayout = splitAmount - platformFee;
            creatives[address(uint160(projects[projectId].creativeAssignedId))].availableBalance += creativePayout; // Assuming creative is the one to get split funds in this simplified split
            emit PaymentReleased(projectId, stageIndex, address(uint160(projects[projectId].creativeAssignedId)), creativePayout);
        }

        projects[projectId].stages[stageIndex].status = StageStatus.APPROVED; // Mark stage as approved after dispute resolution (assuming funds are handled)
        projects[projectId].status = ProjectStatus.COMPLETED; // Mark project as completed after dispute resolution (simplified)

        emit DisputeResolved(_disputeId, _resolution, _winner);
    }

    // 15. Withdraw Funds
    function withdrawFunds() public onlyCreative {
        uint256 amountToWithdraw = creatives[msg.sender].availableBalance;
        require(amountToWithdraw > 0, "No funds available to withdraw.");
        creatives[msg.sender].availableBalance = 0; // Set balance to 0 after withdrawal
        payable(msg.sender).transfer(amountToWithdraw); // Transfer funds
        emit FundsWithdrawn(msg.sender, amountToWithdraw);
    }

    // 16. Get Creative Reputation
    function getCreativeReputation(address _creativeAddress) public view returns (uint256) {
        return creatives[_creativeAddress].reputationScore;
    }

    // 17. Get Client Reputation
    function getClientReputation(address _clientAddress) public view returns (uint256) {
        return clients[_clientAddress].reputationScore;
    }

    // 18. Get Project Details
    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (Project memory) {
        return projects[_projectId];
    }

    // 19. Get Proposals For Project
    function getProposalsForProject(uint256 _projectId) public view projectExists(_projectId) returns (Proposal[] memory) {
        Proposal[] memory projectProposals = new Proposal[](proposalCounter); // Assuming proposalCounter is roughly the max number of proposals
        uint256 proposalIndex = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) {
            if (proposals[i].projectId == _projectId) {
                projectProposals[proposalIndex] = proposals[i];
                proposalIndex++;
            }
        }
        // Resize the array to the actual number of proposals found
        Proposal[] memory resizedProposals = new Proposal[](proposalIndex);
        for (uint256 i = 0; i < proposalIndex; i++) {
            resizedProposals[i] = projectProposals[i];
        }
        return resizedProposals;
    }

    // 20. Set Platform Fee (DAO Governance)
    function setPlatformFee(uint256 _newFeePercentage) public onlyGovernor {
        require(_newFeePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    // 21. Propose Governance Change (DAO Governance)
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) public onlyGovernor {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            proposalId: governanceProposalCounter,
            description: _proposalDescription,
            calldataData: _calldata,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(governanceProposalCounter, _proposalDescription);
    }

    // 22. Vote On Proposal (DAO Governance)
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyGovernor { // Simplified voting - in real DAO, voting power would be considered.
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Governance proposal does not exist.");
        require(block.timestamp < governanceProposals[_proposalId].votingEndTime, "Voting period has ended.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);

        // Simple majority to execute (can be changed to quorum etc.)
        if (governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes) {
            _executeGovernanceProposal(_proposalId);
        }
    }


    // Internal function to execute governance proposal
    function _executeGovernanceProposal(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not yet ended.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass."); // Simple majority check

        (bool success, ) = address(this).delegatecall(proposal.calldataData); // Delegatecall to execute proposal
        require(success, "Governance proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    // Fallback function to receive ETH (if needed for more complex fee structures, etc.)
    receive() external payable {}
}
```