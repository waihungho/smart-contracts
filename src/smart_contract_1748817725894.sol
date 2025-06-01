Okay, let's design a smart contract that facilitates decentralized creative collaboration on projects, incorporating elements of dynamic ownership, reputation, on-chain governance, and interaction with potential external data sources.

We will call this contract `DecentralizedCreativeCollaborator`.

**Concept:** The contract allows users to create projects, invite collaborators, submit contributions, vote on project direction and revenue splits, build reputation, and potentially integrate external data feeds that influence project decisions.

---

### Outline & Function Summary

**Contract Name:** `DecentralizedCreativeCollaborator`

**Core Concept:** A platform for managing decentralized creative projects with collaborative contributions, governance, and dynamic rewards.

**Key Features:**
*   Project Creation & Management
*   Collaborator Registration & Profiles
*   Contribution Submission, Review, and Approval
*   On-chain Governance (Proposals & Voting)
*   Dynamic Royalty/Revenue Split based on Contributions/Reputation
*   Collaborator Reputation System
*   Simulated External Data Feed Integration for Project Decisions
*   Fund Management for Royalties/Distributions

**Data Structures:**
*   `Project`: Represents a collaborative project with state, owner, core team, goals, and associated data.
*   `Contribution`: Represents a piece of work submitted to a project.
*   `CollaboratorProfile`: Stores basic info and reputation for a user.
*   `Proposal`: Represents a governance or royalty split proposal.
*   `Vote`: Records a collaborator's vote on a proposal.

**Enums:**
*   `ProjectState`: lifecycle of a project (Draft, Active, Review, Completed, Archived).
*   `ContributionState`: lifecycle of a contribution (Pending, Approved, Rejected, Retracted).
*   `ProposalState`: lifecycle of a proposal (Pending, Voting, Approved, Rejected, Executed).
*   `ProposalType`: type of governance proposal (GenericAction, RoyaltySplit, AddCoreTeam, RemoveCoreTeam, UpdateProjectDataFeed).
*   `VoteType`: Simple voting options (Yes, No, Abstain).

**Mappings & State Variables:**
*   Counters for unique IDs (projects, contributions, proposals).
*   Mappings from IDs to structs.
*   Mapping for collaborator profiles.
*   Mapping for project core team members.
*   Mapping for collaborator reputation score.
*   Mapping for proposal votes.
*   Mapping for project funds.
*   Owner address.

**Functions (Minimum 20 required):**

1.  `constructor()`: Initializes the contract owner.
2.  `registerCollaborator(string memory _name, string memory _profileURI)`: Creates or updates a collaborator profile.
3.  `getCollaboratorProfile(address _collaborator)`: View collaborator profile details.
4.  `createProject(string memory _name, string memory _description, string memory _goal)`: Creates a new project, assigning creator as initial core team.
5.  `getProjectDetails(uint256 _projectId)`: View project details.
6.  `updateProjectDetails(uint256 _projectId, string memory _description, string memory _goal)`: Update project description/goal (Core Team only).
7.  `addCoreTeamMember(uint256 _projectId, address _collaborator)`: Add a collaborator to the core team (Project Owner/Vote only).
8.  `removeCoreTeamMember(uint256 _projectId, address _collaborator)`: Remove a collaborator from the core team (Project Owner/Vote only).
9.  `submitContribution(uint256 _projectId, string memory _contentURI, string memory _description)`: Submit a new contribution to a project (Collaborator only).
10. `getContributionDetails(uint256 _contributionId)`: View contribution details.
11. `getProjectContributions(uint256 _projectId)`: Get list of contribution IDs for a project.
12. `approveContribution(uint256 _contributionId)`: Approve a pending contribution (Core Team only). Increases contributor's potential royalty share/reputation.
13. `rejectContribution(uint256 _contributionId)`: Reject a pending contribution (Core Team only).
14. `retractContribution(uint256 _contributionId)`: Collaborator retracts their own pending contribution.
15. `createRoyaltySplitProposal(uint256 _projectId, address[] memory _collaborators, uint256[] memory _shares)`: Propose a revenue split (Core Team only). Shares are in basis points (summing to 10000).
16. `createGovernanceProposal(uint256 _projectId, ProposalType _proposalType, bytes memory _proposalData, string memory _description)`: Create a general governance proposal (Core Team only).
17. `getProposalDetails(uint256 _proposalId)`: View proposal details.
18. `voteOnProposal(uint256 _proposalId, VoteType _vote)`: Cast a vote on an active proposal (Collaborator only, weighted by reputation?). Simple 1-person-1-vote for now.
19. `finalizeProposalVoting(uint256 _proposalId)`: Close voting and determine outcome (Anyone can call, but outcome based on votes).
20. `executeProposal(uint256 _proposalId)`: Execute an approved proposal (Anyone can call, but needs approved state).
21. `depositFundsForDistribution(uint256 _projectId) payable`: Deposit funds into a project's balance for future distribution.
22. `distributeFunds(uint256 _projectId, uint256 _proposalId)`: Distribute funds based on an *executed* RoyaltySplit proposal (Core Team only).
23. `getProjectBalance(uint256 _projectId)`: View the contract's balance for a specific project.
24. `updateProjectState(uint256 _projectId, ProjectState _newState)`: Update the project's state (Project Owner/Vote only).
25. `getCollaboratorReputation(address _collaborator)`: View a collaborator's reputation score.
26. `proposeProjectDataFeed(uint256 _projectId, string memory _dataFeedName, address _dataFeedAddress)`: Suggest an external data feed integration (Core Team only).
27. `voteOnProjectDataFeed(uint256 _proposalId, VoteType _vote)`: Vote on a data feed proposal (Collaborators).
28. `ingestDataFeedUpdate(uint256 _projectId, bytes memory _data)`: Simulate updating project-specific data from a feed (Requires trusted caller, e.g., oracle or owner). Note: Complex oracle interaction is outside the scope of this basic example but the structure allows for it.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline & Function Summary ---
// Contract Name: DecentralizedCreativeCollaborator
// Core Concept: A platform for managing decentralized creative projects with collaborative contributions, governance, and dynamic rewards.
// Key Features:
//   - Project Creation & Management
//   - Collaborator Registration & Profiles
//   - Contribution Submission, Review, and Approval
//   - On-chain Governance (Proposals & Voting)
//   - Dynamic Royalty/Revenue Split based on Contributions/Reputation (Simulated calculation)
//   - Collaborator Reputation System
//   - Simulated External Data Feed Integration for Project Decisions
//   - Fund Management for Royalties/Distributions
//
// Data Structures: Project, Contribution, CollaboratorProfile, Proposal, Vote.
// Enums: ProjectState, ContributionState, ProposalState, ProposalType, VoteType.
// Mappings & State Variables: Counters, ID->Struct mappings, collaborator mappings, project core teams, reputation, project funds, owner.
//
// Functions (28 included, > 20):
// 1. constructor()
// 2. registerCollaborator(string memory _name, string memory _profileURI)
// 3. getCollaboratorProfile(address _collaborator)
// 4. createProject(string memory _name, string memory _description, string memory _goal)
// 5. getProjectDetails(uint256 _projectId)
// 6. updateProjectDetails(uint256 _projectId, string memory _description, string memory _goal)
// 7. addCoreTeamMember(uint256 _projectId, address _collaborator)
// 8. removeCoreTeamMember(uint256 _projectId, address _collaborator)
// 9. submitContribution(uint256 _projectId, string memory _contentURI, string memory _description)
// 10. getContributionDetails(uint256 _contributionId)
// 11. getProjectContributions(uint256 _projectId)
// 12. approveContribution(uint256 _contributionId)
// 13. rejectContribution(uint256 _contributionId)
// 14. retractContribution(uint256 _contributionId)
// 15. createRoyaltySplitProposal(uint256 _projectId, address[] memory _collaborators, uint256[] memory _shares)
// 16. createGovernanceProposal(uint256 _projectId, ProposalType _proposalType, bytes memory _proposalData, string memory _description)
// 17. getProposalDetails(uint256 _proposalId)
// 18. voteOnProposal(uint256 _proposalId, VoteType _vote)
// 19. finalizeProposalVoting(uint256 _proposalId)
// 20. executeProposal(uint256 _proposalId)
// 21. depositFundsForDistribution(uint256 _projectId) payable
// 22. distributeFunds(uint256 _projectId, uint256 _proposalId)
// 23. getProjectBalance(uint256 _projectId)
// 24. updateProjectState(uint256 _projectId, ProjectState _newState)
// 25. getCollaboratorReputation(address _collaborator)
// 26. proposeProjectDataFeed(uint256 _projectId, string memory _dataFeedName, address _dataFeedAddress)
// 27. voteOnProjectDataFeed(uint256 _proposalId, VoteType _vote) - Note: In this implementation, this vote is handled by the generic voteOnProposal function. Need to adjust summary or add dedicated vote. Let's use generic.
// 28. ingestDataFeedUpdate(uint256 _projectId, bytes memory _data)
// --- End Outline & Summary ---


contract DecentralizedCreativeCollaborator {

    address public owner;

    // --- Enums ---
    enum ProjectState { Draft, Active, Review, Completed, Archived }
    enum ContributionState { Pending, Approved, Rejected, Retracted }
    enum ProposalState { Pending, Voting, Approved, Rejected, Executed }
    enum ProposalType { GenericAction, RoyaltySplit, AddCoreTeam, RemoveCoreTeam, UpdateProjectDataFeed }
    enum VoteType { Yes, No, Abstain }

    // --- Structs ---
    struct CollaboratorProfile {
        string name;
        string profileURI; // e.g., link to IPFS profile data
        uint256 reputationScore; // Simple reputation counter
        bool exists; // To check if address is registered
    }

    struct Project {
        uint256 id;
        address creator;
        string name;
        string description;
        string goal;
        ProjectState state;
        uint256 createdAt;
        mapping(address => bool) coreTeam; // Members with elevated permissions
        uint256[] contributionIds; // List of contributions submitted to this project
        uint256[] proposalIds; // List of proposals for this project
        mapping(uint256 => bytes) projectDataFeeds; // Simulated data feed updates per project
        mapping(string => address) activeDataFeeds; // Configured data feeds (name -> address/identifier)
    }

    struct Contribution {
        uint256 id;
        uint256 projectId;
        address contributor;
        string contentURI; // e.g., link to IPFS file/data
        string description;
        ContributionState state;
        uint256 submittedAt;
        uint256 approvedAt; // When it was approved
    }

    struct Proposal {
        uint256 id;
        uint256 projectId;
        address proposer;
        ProposalType proposalType;
        bytes proposalData; // Data relevant to the proposal (e.g., addresses and shares for royalty split)
        string description;
        ProposalState state;
        uint256 createdAt;
        uint256 votingEndsAt; // Timestamp when voting ends
        mapping(address => Vote) votes; // Collaborator address -> vote
        uint256 yesVotes;
        uint256 noVotes;
        uint256 abstainVotes;
        uint256 totalVoters; // Count of unique voters
        bool executed;
    }

    // --- State Variables ---
    uint256 private nextProjectId = 1;
    uint256 private nextContributionId = 1;
    uint256 private nextProposalId = 1;

    mapping(uint256 => Project) public projects;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => CollaboratorProfile) public collaboratorProfiles;
    mapping(uint256 => uint256) public projectBalances; // ETH/token balance per project

    // --- Events ---
    event CollaboratorRegistered(address indexed collaborator, string name, string profileURI);
    event ProjectCreated(uint256 indexed projectId, address indexed creator, string name);
    event ProjectStateUpdated(uint256 indexed projectId, ProjectState newState);
    event CoreTeamMemberAdded(uint256 indexed projectId, address indexed member);
    event CoreTeamMemberRemoved(uint256 indexed projectId, address indexed member);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed projectId, address indexed contributor);
    event ContributionStateUpdated(uint256 indexed contributionId, ContributionState newState);
    event ReputationUpdated(address indexed collaborator, uint256 newScore);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed projectId, ProposalType proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, VoteType vote);
    event ProposalVotingFinalized(uint256 indexed proposalId, ProposalState finalState);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(uint256 indexed projectId, uint256 amount);
    event FundsDistributed(uint256 indexed projectId, uint256 distributedAmount);
    event ProjectDataFeedProposed(uint256 indexed projectId, string dataFeedName, address dataFeedAddress);
    event ProjectDataFeedUpdated(uint256 indexed projectId, bytes data);


    // --- Modifiers ---
    modifier onlyRegisteredCollaborator() {
        require(collaboratorProfiles[msg.sender].exists, "Not a registered collaborator");
        _;
    }

    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender || owner == msg.sender, "Not project owner or contract owner");
        _;
    }

    modifier onlyCoreTeamMember(uint256 _projectId) {
        require(projects[_projectId].coreTeam[msg.sender] || projects[_projectId].creator == msg.sender || owner == msg.sender, "Not a project core team member");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender || owner == msg.sender, "Not proposal proposer or contract owner");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Collaborator Management ---

    /// @notice Creates or updates a collaborator profile.
    /// @param _name The name of the collaborator.
    /// @param _profileURI The URI for detailed profile data (e.g., IPFS).
    function registerCollaborator(string memory _name, string memory _profileURI) public {
        collaboratorProfiles[msg.sender] = CollaboratorProfile({
            name: _name,
            profileURI: _profileURI,
            reputationScore: collaboratorProfiles[msg.sender].reputationScore, // Preserve existing score if updating
            exists: true
        });
        emit CollaboratorRegistered(msg.sender, _name, _profileURI);
    }

    /// @notice Gets the profile details for a collaborator.
    /// @param _collaborator The address of the collaborator.
    /// @return name, profileURI, reputationScore, exists
    function getCollaboratorProfile(address _collaborator) public view returns (string memory name, string memory profileURI, uint256 reputationScore, bool exists) {
        CollaboratorProfile storage profile = collaboratorProfiles[_collaborator];
        return (profile.name, profile.profileURI, profile.reputationScore, profile.exists);
    }

    /// @notice Gets the reputation score for a collaborator.
    /// @param _collaborator The address of the collaborator.
    /// @return The collaborator's reputation score.
    function getCollaboratorReputation(address _collaborator) public view returns (uint256) {
        return collaboratorProfiles[_collaborator].reputationScore;
    }


    // --- Project Management ---

    /// @notice Creates a new collaborative project.
    /// @param _name The name of the project.
    /// @param _description A brief description of the project.
    /// @param _goal The main objective or goal of the project.
    /// @return The ID of the newly created project.
    function createProject(string memory _name, string memory _description, string memory _goal) public onlyRegisteredCollaborator returns (uint256) {
        uint256 projectId = nextProjectId++;
        Project storage project = projects[projectId];
        project.id = projectId;
        project.creator = msg.sender;
        project.name = _name;
        project.description = _description;
        project.goal = _goal;
        project.state = ProjectState.Draft;
        project.createdAt = block.timestamp;
        project.coreTeam[msg.sender] = true; // Creator is initial core team

        emit ProjectCreated(projectId, msg.sender, _name);
        return projectId;
    }

    /// @notice Gets the details of a project.
    /// @param _projectId The ID of the project.
    /// @return id, creator, name, description, goal, state, createdAt
    function getProjectDetails(uint256 _projectId) public view returns (uint256 id, address creator, string memory name, string memory description, string memory goal, ProjectState state, uint256 createdAt) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        return (project.id, project.creator, project.name, project.description, project.goal, project.state, project.createdAt);
    }

    /// @notice Updates the description and goal of a project.
    /// @param _projectId The ID of the project.
    /// @param _description The new description.
    /// @param _goal The new goal.
    function updateProjectDetails(uint256 _projectId, string memory _description, string memory _goal) public onlyCoreTeamMember(_projectId) {
        Project storage project = projects[_projectId];
        project.description = _description;
        project.goal = _goal;
    }

    /// @notice Updates the state of a project.
    /// @param _projectId The ID of the project.
    /// @param _newState The new state for the project.
    function updateProjectState(uint256 _projectId, ProjectState _newState) public onlyProjectOwner(_projectId) {
         Project storage project = projects[_projectId];
         project.state = _newState;
         emit ProjectStateUpdated(_projectId, _newState);
    }

     /// @notice Adds a collaborator to the core team of a project.
     /// @param _projectId The ID of the project.
     /// @param _collaborator The address of the collaborator to add.
    function addCoreTeamMember(uint256 _projectId, address _collaborator) public onlyProjectOwner(_projectId) onlyRegisteredCollaborator {
        Project storage project = projects[_projectId];
        require(!project.coreTeam[_collaborator], "Collaborator is already a core team member");
        project.coreTeam[_collaborator] = true;
        emit CoreTeamMemberAdded(_projectId, _collaborator);
    }

    /// @notice Removes a collaborator from the core team of a project.
    /// @param _projectId The ID of the project.
    /// @param _collaborator The address of the collaborator to remove.
    function removeCoreTeamMember(uint256 _projectId, address _collaborator) public onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.coreTeam[_collaborator], "Collaborator is not a core team member");
        require(project.creator != _collaborator, "Cannot remove project creator from core team this way");
        project.coreTeam[_collaborator] = false;
        emit CoreTeamMemberRemoved(_projectId, _collaborator);
    }


    // --- Contribution Management ---

    /// @notice Submits a contribution to a project.
    /// @param _projectId The ID of the project.
    /// @param _contentURI The URI pointing to the contribution content.
    /// @param _description A description of the contribution.
    /// @return The ID of the newly created contribution.
    function submitContribution(uint256 _projectId, string memory _contentURI, string memory _description) public onlyRegisteredCollaborator returns (uint256) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(project.state == ProjectState.Active, "Project is not accepting contributions");

        uint256 contributionId = nextContributionId++;
        contributions[contributionId] = Contribution({
            id: contributionId,
            projectId: _projectId,
            contributor: msg.sender,
            contentURI: _contentURI,
            description: _description,
            state: ContributionState.Pending,
            submittedAt: block.timestamp,
            approvedAt: 0 // Not approved yet
        });
        project.contributionIds.push(contributionId);

        emit ContributionSubmitted(contributionId, _projectId, msg.sender);
        return contributionId;
    }

    /// @notice Gets the details of a contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return id, projectId, contributor, contentURI, description, state, submittedAt, approvedAt
    function getContributionDetails(uint256 _contributionId) public view returns (uint256 id, uint256 projectId, address contributor, string memory contentURI, string memory description, ContributionState state, uint256 submittedAt, uint256 approvedAt) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.projectId != 0, "Contribution does not exist");
        return (contribution.id, contribution.projectId, contribution.contributor, contribution.description, contribution.contentURI, contribution.state, contribution.submittedAt, contribution.approvedAt);
    }

     /// @notice Gets the list of contribution IDs for a project.
     /// @param _projectId The ID of the project.
     /// @return An array of contribution IDs.
    function getProjectContributions(uint256 _projectId) public view returns (uint256[] memory) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        return project.contributionIds;
    }

    /// @notice Approves a pending contribution.
    /// @param _contributionId The ID of the contribution.
    function approveContribution(uint256 _contributionId) public onlyCoreTeamMember(contributions[_contributionId].projectId) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.projectId != 0, "Contribution does not exist");
        require(contribution.state == ContributionState.Pending, "Contribution is not pending");

        contribution.state = ContributionState.Approved;
        contribution.approvedAt = block.timestamp;

        // Simple reputation boost for approved work
        collaboratorProfiles[contribution.contributor].reputationScore += 10; // Arbitrary value
        emit ReputationUpdated(contribution.contributor, collaboratorProfiles[contribution.contributor].reputationScore);

        emit ContributionStateUpdated(_contributionId, ContributionState.Approved);
    }

    /// @notice Rejects a pending contribution.
    /// @param _contributionId The ID of the contribution.
    function rejectContribution(uint256 _contributionId) public onlyCoreTeamMember(contributions[_contributionId].projectId) {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.projectId != 0, "Contribution does not exist");
        require(contribution.state == ContributionState.Pending, "Contribution is not pending");

        contribution.state = ContributionState.Rejected;
        emit ContributionStateUpdated(_contributionId, ContributionState.Rejected);
    }

    /// @notice Allows a collaborator to retract their own pending contribution.
    /// @param _contributionId The ID of the contribution.
    function retractContribution(uint256 _contributionId) public {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.projectId != 0, "Contribution does not exist");
        require(contribution.contributor == msg.sender, "Not your contribution");
        require(contribution.state == ContributionState.Pending, "Contribution is not pending");

        contribution.state = ContributionState.Retracted;
        emit ContributionStateUpdated(_contributionId, ContributionState.Retracted);
    }

    // --- Governance & Proposals ---

    /// @notice Creates a proposal for a project.
    /// @param _projectId The ID of the project.
    /// @param _proposalType The type of proposal.
    /// @param _proposalData Data relevant to the proposal (e.g., encoded addresses/shares for RoyaltySplit).
    /// @param _description A description of the proposal.
    /// @return The ID of the newly created proposal.
    function createGovernanceProposal(uint256 _projectId, ProposalType _proposalType, bytes memory _proposalData, string memory _description) public onlyCoreTeamMember(_projectId) returns (uint256) {
         Project storage project = projects[_projectId];
         require(project.creator != address(0), "Project does not exist");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            projectId: _projectId,
            proposer: msg.sender,
            proposalType: _proposalType,
            proposalData: _proposalData,
            description: _description,
            state: ProposalState.Voting, // Starts in voting state
            createdAt: block.timestamp,
            votingEndsAt: block.timestamp + 7 days, // Example: 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0,
            totalVoters: 0,
            executed: false
        });
        project.proposalIds.push(proposalId);

        emit ProposalCreated(proposalId, _projectId, _proposalType, msg.sender);
        return proposalId;
    }

    /// @notice Creates a specific proposal for royalty split.
    /// @param _projectId The ID of the project.
    /// @param _collaborators Array of collaborator addresses.
    /// @param _shares Array of corresponding shares in basis points (sum should ideally be 10000).
    /// @return The ID of the newly created proposal.
    function createRoyaltySplitProposal(uint256 _projectId, address[] memory _collaborators, uint256[] memory _shares) public onlyCoreTeamMember(_projectId) returns (uint256) {
        require(_collaborators.length == _shares.length, "Collaborators and shares arrays must match length");
        // Optional: Add check here to ensure total shares sum to 10000 (basis points)

        // Encode data for the proposal
        bytes memory proposalData = abi.encode(_collaborators, _shares);

        // Use the generic proposal creation
        return createGovernanceProposal(_projectId, ProposalType.RoyaltySplit, proposalData, "Proposed royalty split distribution");
    }


    /// @notice Gets the details of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return id, projectId, proposer, proposalType, description, state, createdAt, votingEndsAt, yesVotes, noVotes, abstainVotes, executed
    function getProposalDetails(uint256 _proposalId) public view returns (uint256 id, uint256 projectId, address proposer, ProposalType proposalType, string memory description, ProposalState state, uint256 createdAt, uint256 votingEndsAt, uint256 yesVotes, uint256 noVotes, uint256 abstainVotes, bool executed) {
        Proposal storage proposal = proposals[_proposalId];
         require(proposal.projectId != 0, "Proposal does not exist");
         return (proposal.id, proposal.projectId, proposal.proposer, proposal.proposalType, proposal.description, proposal.state, proposal.createdAt, proposal.votingEndsAt, proposal.yesVotes, proposal.noVotes, proposal.abstainVotes, proposal.executed);
    }

    /// @notice Casts a vote on a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _vote The type of vote (Yes, No, Abstain).
    function voteOnProposal(uint256 _proposalId, VoteType _vote) public onlyRegisteredCollaborator {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.projectId != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Voting, "Proposal is not in voting state");
        require(block.timestamp <= proposal.votingEndsAt, "Voting period has ended");
        require(proposal.votes[msg.sender] == VoteType.Abstain || proposal.votes[msg.sender] == VoteType(0), "Already voted"); // Check if already voted (0 is default enum value)

        // Ensure voter is a collaborator on the project associated with the proposal
        // Note: This requires iterating through project.contributionIds or having a separate list of project collaborators.
        // For simplicity here, assuming any registered collaborator can vote on any project's proposal,
        // OR we'd need to enforce that msg.sender has an approved contribution or is core team on proposal.projectId.
        // Let's assume only Core Team members on the project can vote for now to keep it simple.
        require(projects[proposal.projectId].coreTeam[msg.sender], "Only project core team can vote on this proposal");


        proposal.votes[msg.sender] = _vote;
        proposal.totalVoters++;

        if (_vote == VoteType.Yes) {
            proposal.yesVotes++;
        } else if (_vote == VoteType.No) {
            proposal.noVotes++;
        } else if (_vote == VoteType.Abstain) {
            proposal.abstainVotes++;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Finalizes the voting process for a proposal.
    /// @param _proposalId The ID of the proposal.
    function finalizeProposalVoting(uint256 _proposalId) public {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.projectId != 0, "Proposal does not exist");
         require(proposal.state == ProposalState.Voting, "Proposal is not in voting state");
         require(block.timestamp > proposal.votingEndsAt, "Voting period has not ended");

         // Simple majority quorum logic: Need at least 2 core team members to vote, and Yes votes > No votes
         uint256 coreTeamCount = 0;
         // This requires iterating core team members, which is gas-intensive.
         // A better way involves tracking active core team count directly or requiring a minimum totalVotes.
         // Let's simplify: require minimum total voters (e.g., 2) and simple majority.
         require(proposal.totalVoters >= 2, "Not enough voters to finalize"); // Simple quorum example

         if (proposal.yesVotes > proposal.noVotes) {
             proposal.state = ProposalState.Approved;
         } else {
             proposal.state = ProposalState.Rejected;
         }

         emit ProposalVotingFinalized(_proposalId, proposal.state);
    }


    /// @notice Executes an approved proposal.
    /// @param _proposalId The ID of the proposal.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.projectId != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Approved, "Proposal is not approved");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;

        // Execute logic based on ProposalType
        if (proposal.proposalType == ProposalType.RoyaltySplit) {
            // Store the approved royalty split data somewhere accessible
            // For simplicity, let's assume the proposalData itself represents the final approved split
            // and will be consumed by distributeFunds.
            // In a real system, you'd likely store this split on the Project struct or similar.
            // projects[proposal.projectId].activeRoyaltySplit = proposal.proposalData; // Example placeholder
            // This implementation is simplified; the actual distribution needs access to the split data.
            // distributeFunds takes the proposalId to access the split data.
             emit ProposalExecuted(_proposalId);

        } else if (proposal.proposalType == ProposalType.AddCoreTeam) {
            (address memberToAdd) = abi.decode(proposal.proposalData, (address));
            projects[proposal.projectId].coreTeam[memberToAdd] = true;
            emit CoreTeamMemberAdded(proposal.projectId, memberToAdd);
             emit ProposalExecuted(_proposalId);

        } else if (proposal.proposalType == ProposalType.RemoveCoreTeam) {
             (address memberToRemove) = abi.decode(proposal.proposalData, (address));
             // Add safety check: cannot remove the project creator via this method
             if (projects[proposal.projectId].creator != memberToRemove) {
                 projects[proposal.projectId].coreTeam[memberToRemove] = false;
                  emit CoreTeamMemberRemoved(proposal.projectId, memberToRemove);
             }
             emit ProposalExecuted(_proposalId);

        } else if (proposal.proposalType == ProposalType.UpdateProjectDataFeed) {
            (string memory dataFeedName, address dataFeedAddress) = abi.decode(proposal.proposalData, (string, address));
            projects[proposal.projectId].activeDataFeeds[dataFeedName] = dataFeedAddress;
            emit ProjectDataFeedProposed(proposal.projectId, dataFeedName, dataFeedAddress); // Renaming event as it's now activated
            emit ProposalExecuted(_proposalId);

        } else { // GenericAction or future types
            // No specific on-chain action for generic proposals in this example
            // Could emit a generic event indicating a decision was made
            emit ProposalExecuted(_proposalId);
        }

        proposal.state = ProposalState.Executed; // Mark as executed
    }


    // --- Fund Management ---

    /// @notice Deposits funds into a project's balance.
    /// @param _projectId The ID of the project.
    function depositFundsForDistribution(uint256 _projectId) public payable {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        require(msg.value > 0, "Must send Ether");

        projectBalances[_projectId] += msg.value;
        emit FundsDeposited(_projectId, msg.value);
    }

    /// @notice Distributes funds from a project's balance based on an executed RoyaltySplit proposal.
    /// @param _projectId The ID of the project.
    /// @param _proposalId The ID of the executed RoyaltySplit proposal containing the distribution plan.
    function distributeFunds(uint256 _projectId, uint256 _proposalId) public onlyCoreTeamMember(_projectId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.projectId == _projectId, "Proposal does not belong to this project");
        require(proposal.proposalType == ProposalType.RoyaltySplit, "Proposal is not a Royalty Split proposal");
        require(proposal.executed, "Royalty Split proposal must be executed");

        // Decode the stored split data
        (address[] memory collaborators, uint256[] memory shares) = abi.decode(proposal.proposalData, (address[], uint256[]));
        require(collaborators.length == shares.length, "Corrupted proposal data"); // Should be guaranteed by creation

        uint256 totalShares = 0;
        for(uint i = 0; i < shares.length; i++) {
            totalShares += shares[i];
        }
         require(totalShares > 0, "Total shares must be greater than 0"); // Prevent division by zero

        uint256 projectBalance = projectBalances[_projectId];
        require(projectBalance > 0, "Project has no funds to distribute");

        // Distribute funds
        for (uint i = 0; i < collaborators.length; i++) {
            uint256 amount = (projectBalance * shares[i]) / totalShares;
            if (amount > 0) {
                 // Using transfer() is safer than send() or call() for simple value transfers,
                 // although call() with gas limit is generally preferred for external contract calls.
                 // For simple ETH transfer to EOA, transfer is acceptable.
                (bool success, ) = payable(collaborators[i]).call{value: amount}("");
                 // Handle success/failure appropriately in production (e.g., logging, retry mechanism)
                 require(success, "Failed to send funds"); // Simple failure detection
            }
        }

        // Any remainder might stay in the project balance due to rounding or failed transfers
        projectBalances[_projectId] = 0; // Reset balance assumes full distribution attempt
        emit FundsDistributed(_projectId, projectBalance);
    }

    /// @notice Gets the current balance held by the contract for a specific project.
    /// @param _projectId The ID of the project.
    /// @return The balance in wei.
    function getProjectBalance(uint256 _projectId) public view returns (uint256) {
        return projectBalances[_projectId];
    }

    // --- External Data Feed Simulation ---

    /// @notice Proposes to link an external data feed (simulated address/identifier) to a project.
    /// Note: This is a governance proposal; actual linking happens upon execution.
    /// @param _projectId The ID of the project.
    /// @param _dataFeedName A name for the data feed (e.g., "MarketPrice", "EventStatus").
    /// @param _dataFeedAddress A placeholder address or identifier for the data feed.
    /// @return The ID of the governance proposal created for this.
    function proposeProjectDataFeed(uint256 _projectId, string memory _dataFeedName, address _dataFeedAddress) public onlyCoreTeamMember(_projectId) returns (uint256) {
        // Encode data for the proposal
        bytes memory proposalData = abi.encode(_dataFeedName, _dataFeedAddress);

        // Create a governance proposal of type UpdateProjectDataFeed
        return createGovernanceProposal(_projectId, ProposalType.UpdateProjectDataFeed, proposalData, string(abi.encodePacked("Propose linking data feed: ", _dataFeedName)));
    }

    /// @notice Simulates an update from a linked data feed for a project.
    /// In a real scenario, this would likely be called by a Chainlink oracle or trusted source.
    /// @param _projectId The ID of the project.
    /// @param _data The raw bytes data from the feed update.
    // Note: Add access control here for a real oracle. For demo, owner only.
    function ingestDataFeedUpdate(uint256 _projectId, bytes memory _data) public onlyProjectOwner(_projectId) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        // Store the latest data update
        // Note: Storing raw bytes on chain can be expensive. This is a simplified example.
        // Real implementations might process data or store a hash/summary.
        project.projectDataFeeds[block.timestamp] = _data; // Store data keyed by timestamp

        // Potential complex logic triggered by data update would go here.
        // E.g., if price feed drops below threshold, change project state or trigger event.

        emit ProjectDataFeedUpdated(_projectId, _data);
    }

    // --- View Functions (continued) ---

     /// @notice Gets the details of a vote for a specific collaborator on a proposal.
     /// @param _proposalId The ID of the proposal.
     /// @param _collaborator The address of the collaborator.
     /// @return The vote type (Yes, No, Abstain). Returns 0 (Abstain) if no vote recorded.
     function getProposalVotes(uint256 _proposalId, address _collaborator) public view returns (VoteType) {
         Proposal storage proposal = proposals[_proposalId];
          require(proposal.projectId != 0, "Proposal does not exist");
          return proposal.votes[_collaborator];
     }

    /// @notice Gets the list of proposal IDs for a project.
    /// @param _projectId The ID of the project.
    /// @return An array of proposal IDs.
    function getProjectProposals(uint256 _projectId) public view returns (uint256[] memory) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        return project.proposalIds;
    }

    /// @notice Checks if an address is currently a core team member for a project.
    /// @param _projectId The ID of the project.
    /// @param _collaborator The address to check.
    /// @return True if the address is a core team member, false otherwise.
    function isCoreTeamMember(uint256 _projectId, address _collaborator) public view returns (bool) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        return project.coreTeam[_collaborator];
    }

    /// @notice Gets the raw data associated with a simulated data feed update for a project at a specific timestamp.
    /// @param _projectId The ID of the project.
    /// @param _timestamp The timestamp of the data update.
    /// @return The raw bytes data.
    function getProjectDataFeedUpdate(uint256 _projectId, uint256 _timestamp) public view returns (bytes memory) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "Project does not exist");
        return project.projectDataFeeds[_timestamp];
    }
}
```