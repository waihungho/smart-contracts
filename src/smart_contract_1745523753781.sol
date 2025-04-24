Okay, let's design a smart contract around a decentralized creative collaboration platform that allows users to propose projects, contribute content, vote on submissions and outcomes, build on-chain reputation, and collectively own dynamic NFTs generated from successful projects.

This concept is novel in combining structured collaboration workflows, on-chain reputation specific to contribution, multi-stage voting, and dynamic NFT traits influenced by the collaboration itself. It goes beyond simple NFT minting or basic DAO governance.

Here's the contract structure and the code.

---

**Contract Name:** DecentralizedCreativeCollaboration

**Concept:** A platform for collaborative creative projects. Users propose projects, others join by staking, participants contribute content (represented by hashes), vote on submissions, vote on the final project outcome, build on-chain reputation, and successful projects result in a dynamic NFT jointly owned or attributed, with potential royalty splits.

**Outline:**

1.  **State Variables & Constants:**
    *   Counters for Projects, Contributions, NFTs.
    *   Mappings for Projects, Contributions, User Reputation, User Participation, Project-NFT link, NFT-Project link.
    *   Configuration parameters (stake requirement, voting periods, reputation gain amounts).
    *   NFT details (name, symbol).
2.  **Structs:**
    *   `Project`: Details about a project (creator, state, participants, deadlines, content, votes, associated NFT, royalty split).
    *   `Contribution`: Details about a submitted content piece (contributor, project, content hash, status, votes).
    *   `RoyaltyRecipient`: Address and percentage for royalty distribution.
3.  **Enums:**
    *   `ProjectState`: Proposed, Active, ContentVoting, OutcomeVoting, Completed, Cancelled.
    *   `VoteType`: Approve, Reject.
4.  **Events:**
    *   Project lifecycle events (Proposed, Activated, VotingStarted, Completed, Cancelled).
    *   Participation events (JoinedProject, LeftProject).
    *   Contribution events (Submitted, Updated, Withdrawn, Accepted, Rejected).
    *   Voting events (VotedOnContent, VotedOnOutcome).
    *   NFT events (ProjectNFTMinted, NFTTraitUpdated).
    *   Reputation events (ReputationUpdated).
    *   Financial events (StakeClaimed, RoyaltiesDistributed).
5.  **Modifiers:**
    *   `onlyParticipant`: Ensures caller is a participant of a given project.
    *   `inProjectState`: Ensures project is in a specific state.
    *   `isValidRoyaltySplit`: Ensures royalty percentages sum to 100.
6.  **Core Logic (Functions):**
    *   **Project Management:**
        *   `proposeProject`: Create a new project proposal.
        *   `stakeAndJoinProject`: Join a project by staking funds.
        *   `leaveProjectBeforeActive`: Leave a project before it becomes active.
        *   `activateProject`: Move a project from Proposed to Active (requires stake threshold/time).
        *   `startProjectVoting`: Move project to ContentVoting state (time-based).
        *   `startOutcomeVoting`: Move project to OutcomeVoting state (time-based after content voting).
        *   `finalizeProjectVoting`: Tally votes, determine outcome, potentially mint NFT.
        *   `cancelProjectProposal`: Cancel project before it's active.
        *   `claimStakedFunds`: Claim back stake if project fails or is cancelled.
    *   **Contribution Management:**
        *   `submitContribution`: Add content hash to a project.
        *   `updateContribution`: Update an existing contribution.
        *   `withdrawContribution`: Remove a contribution (if not yet voted on/accepted).
    *   **Voting & Governance:**
        *   `voteOnContent`: Vote on a specific contribution within a project.
        *   `voteOnProjectOutcome`: Vote on the project's final success.
        *   `revokeVote`: Remove a previous vote.
    *   **Reputation System:**
        *   `(Internal) _updateReputation`: Helper to adjust user reputation.
        *   `getUserReputation`: Get reputation score for an address.
    *   **NFT & Royalties:**
        *   `(Internal) _mintProjectNFT`: Mint the ERC721 NFT for a successful project.
        *   `updateNFTTraitState`: Update a dynamic trait on a project's NFT (specific conditions).
        *   `setProjectRoyaltySplit`: Define how future revenue is split for a completed project.
        *   `distributeProjectRevenue`: Callable function to send revenue to royalty recipients.
        *   `getProjectNFTId`: Get the NFT token ID for a project.
    *   **Querying (Read Functions):**
        *   `getProjectDetails`: Get all details of a project.
        *   `getProjectParticipants`: List participants of a project.
        *   `getProjectContributions`: List contributions for a project.
        *   `getContributionDetails`: Get details of a specific contribution.
        *   `getProjectContentVotes`: Get votes for content in a project.
        *   `getProjectOutcomeVotes`: Get votes for project outcome.
        *   `getProjectAcceptedContent`: List accepted contributions for a project.
        *   `getUserProjects`: List projects a user is participating in.
        *   `getNFTTraitState`: Get the current dynamic trait state of a project NFT.
        *   `getProjectRoyaltySplit`: Get the royalty distribution for a project.

**Function Summary (Custom Functions, minimum 20):**

1.  `proposeProject(string memory _title, string memory _description, uint256 _activationStakeRequired, uint256 _contentVotingPeriodDuration, uint256 _outcomeVotingPeriodDuration)`: Proposes a new project.
2.  `stakeAndJoinProject(uint256 _projectId) payable`: Joins a project by sending the required stake.
3.  `leaveProjectBeforeActive(uint256 _projectId)`: Allows a user to leave a project *before* it's active and reclaim stake.
4.  `activateProject(uint256 _projectId)`: Moves a project from `Proposed` to `Active` state (requires sufficient staked funds and creator call - *could be time-triggered by oracle*).
5.  `startProjectVoting(uint256 _projectId)`: Initiates the content voting phase (time-triggered).
6.  `startOutcomeVoting(uint256 _projectId)`: Initiates the outcome voting phase (time-triggered after content voting ends).
7.  `finalizeProjectVoting(uint256 _projectId)`: Finalizes voting, determines accepted content, decides project success, mints NFT, distributes/locks stake.
8.  `cancelProjectProposal(uint256 _projectId)`: Creator cancels project proposal before activation.
9.  `claimStakedFunds(uint256 _projectId)`: Participants claim stake if project is cancelled or fails.
10. `submitContribution(uint256 _projectId, string memory _contentHash)`: Submit content hash for a project.
11. `updateContribution(uint256 _contributionId, string memory _newContentHash)`: Update a previously submitted contribution.
12. `withdrawContribution(uint256 _contributionId)`: Remove a contribution if eligible.
13. `voteOnContent(uint256 _projectId, uint256 _contributionId, VoteType _vote)`: Cast a vote on a specific content piece.
14. `voteOnProjectOutcome(uint256 _projectId, VoteType _vote)`: Cast a vote on the overall project success.
15. `revokeVote(uint256 _projectId, uint256 _targetId, uint256 _voteTypeIdentifier)`: Revoke a vote (on content or outcome). `_voteTypeIdentifier`: 0 for content, 1 for outcome.
16. `getUserReputation(address _user) view`: Retrieve a user's reputation score.
17. `updateNFTTraitState(uint256 _projectId, uint256 _newState)`: Update a dynamic trait of the project's NFT (callable by contract logic or authorized address).
18. `setProjectRoyaltySplit(uint256 _projectId, RoyaltyRecipient[] memory _recipients)`: Set the royalty distribution for a *completed* project.
19. `distributeProjectRevenue(uint256 _projectId) payable`: Distributes received ETH revenue according to the set royalty split.
20. `getProjectDetails(uint256 _projectId) view`: Retrieve project information.
21. `getProjectParticipants(uint256 _projectId) view`: Get the list of participant addresses.
22. `getProjectContributions(uint256 _projectId) view`: Get the list of contribution IDs for a project.
23. `getContributionDetails(uint256 _contributionId) view`: Retrieve contribution information.
24. `getProjectContentVotes(uint256 _projectId) view`: Get detailed content voting results for a project.
25. `getProjectOutcomeVotes(uint256 _projectId) view`: Get detailed outcome voting results for a project.
26. `getProjectAcceptedContent(uint256 _projectId) view`: Get the list of accepted contribution IDs.
27. `getUserProjects(address _user) view`: Get list of projects a user participated in.
28. `getProjectNFTId(uint256 _projectId) view`: Get the NFT token ID associated with a project.
29. `getNFTTraitState(uint256 _tokenId) view`: Get the dynamic trait state of an NFT.
30. `getProjectRoyaltySplit(uint256 _projectId) view`: Get the configured royalty recipients and percentages for a project.

*(Note: The basic ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, etc., are inherited and would also be part of the contract's functional interface, bringing the total well over 30, but the list above focuses on the *custom* logic functions implementing the unique platform features)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Contract Name: DecentralizedCreativeCollaboration ---
// --- Concept: A platform for collaborative creative projects. ---
// --- Users propose projects, others join by staking, participants contribute content (represented by hashes), ---
// --- vote on submissions, vote on the final project outcome, build on-chain reputation, ---
// --- and successful projects result in a dynamic NFT jointly owned or attributed, ---
// --- with potential royalty splits. ---

// --- Outline: ---
// 1. State Variables & Constants (Counters, Mappings, Config)
// 2. Structs (Project, Contribution, RoyaltyRecipient)
// 3. Enums (ProjectState, VoteType)
// 4. Events
// 5. Modifiers
// 6. Core Logic (Functions for Project Management, Contribution, Voting, Reputation, NFT, Royalties, Querying)

// --- Function Summary (Custom Functions, min 20): ---
// 01. proposeProject(string memory _title, string memory _description, uint256 _activationStakeRequired, uint256 _contentVotingPeriodDuration, uint256 _outcomeVotingPeriodDuration)
// 02. stakeAndJoinProject(uint256 _projectId)
// 03. leaveProjectBeforeActive(uint256 _projectId)
// 04. activateProject(uint256 _projectId)
// 05. startProjectVoting(uint256 _projectId)
// 06. startOutcomeVoting(uint256 _projectId)
// 07. finalizeProjectVoting(uint256 _projectId)
// 08. cancelProjectProposal(uint256 _projectId)
// 09. claimStakedFunds(uint256 _projectId)
// 10. submitContribution(uint256 _projectId, string memory _contentHash)
// 11. updateContribution(uint256 _contributionId, string memory _newContentHash)
// 12. withdrawContribution(uint256 _contributionId)
// 13. voteOnContent(uint256 _projectId, uint256 _contributionId, VoteType _vote)
// 14. voteOnProjectOutcome(uint256 _projectId, VoteType _vote)
// 15. revokeVote(uint256 _projectId, uint256 _targetId, uint256 _voteTypeIdentifier)
// 16. getUserReputation(address _user) view
// 17. updateNFTTraitState(uint256 _projectId, uint256 _newState)
// 18. setProjectRoyaltySplit(uint256 _projectId, RoyaltyRecipient[] memory _recipients)
// 19. distributeProjectRevenue(uint256 _projectId) payable
// 20. getProjectDetails(uint256 _projectId) view
// 21. getProjectParticipants(uint256 _projectId) view
// 22. getProjectContributions(uint256 _projectId) view
// 23. getContributionDetails(uint256 _contributionId) view
// 24. getProjectContentVotes(uint256 _projectId) view
// 25. getProjectOutcomeVotes(uint256 _projectId) view
// 26. getProjectAcceptedContent(uint256 _projectId) view
// 27. getUserProjects(address _user) view
// 28. getProjectNFTId(uint256 _projectId) view
// 29. getNFTTraitState(uint256 _tokenId) view
// 30. getProjectRoyaltySplit(uint256 _projectId) view

contract DecentralizedCreativeCollaboration is ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _projectIds;
    Counters.Counter private _contributionIds;
    Counters.Counter private _tokenIds; // For ERC721 NFTs

    enum ProjectState {
        Proposed,       // Project is proposed, gathering participants/stake
        Active,         // Stake goal met or time passed, collaboration is active
        ContentVoting,  // Voting phase for submitted content pieces
        OutcomeVoting,  // Voting phase for the final project success
        Completed,      // Project successful, NFT minted, stake potentially locked/distributed
        Cancelled       // Project failed to activate or was cancelled
    }

    enum VoteType {
        None,
        Approve,
        Reject
    }

    struct RoyaltyRecipient {
        address recipient;
        uint256 percentage; // Percentage out of 10000 (e.g., 100 = 1%)
    }

    struct Project {
        uint256 id;
        address creator;
        ProjectState state;
        string title;
        string description;
        uint256 activationStakeRequired;
        uint256 totalStaked;
        uint256 proposalTimestamp;
        uint256 activationTimestamp;
        uint256 contentVotingStartTimestamp;
        uint256 contentVotingEndTimestamp;
        uint256 outcomeVotingStartTimestamp;
        uint256 outcomeVotingEndTimestamp;
        uint256 contentVotingPeriodDuration;
        uint256 outcomeVotingPeriodDuration;
        address[] participants;
        mapping(address => uint256) stakedFunds;
        mapping(address => bool) isParticipant;
        uint256[] contributionIds; // IDs of all contributions submitted
        uint256[] acceptedContributionIds; // IDs of contributions accepted via voting
        mapping(address => VoteType) contentVotes; // Outcome of content votes by participant address (aggregated or specific?) - Let's track per content piece and participant
        mapping(uint256 => mapping(address => VoteType)) contributionVotes; // contributionId -> participantAddress -> VoteType
        mapping(address => VoteType) outcomeVotes; // participantAddress -> VoteType
        uint256 associatedNFT; // Token ID of the minted NFT (0 if none)
        RoyaltyRecipient[] royaltySplit; // Defines how revenue is split post-completion
        bool royaltySplitSet;
    }

    struct Contribution {
        uint256 id;
        uint256 projectId;
        address contributor;
        string contentHash; // e.g., IPFS CID
        uint256 submissionTimestamp;
        ProjectState submissionState; // Project state when submitted
        VoteType status; // Result of content voting (None, Accepted, Rejected)
        uint256 approveVotes;
        uint256 rejectVotes;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => Contribution) public contributions;
    mapping(address => uint256) public userReputation; // Simple reputation score
    mapping(address => uint256[]) public userProjects; // List of projects a user is/was part of
    mapping(uint256 => uint256) public projectNFT; // projectId -> tokenId
    mapping(uint256 => uint256) public nftProject; // tokenId -> projectId
    mapping(uint256 => uint256) public nftDynamicTrait; // tokenId -> uint256 representing a trait state

    // Configuration parameters
    uint256 public minStakeRequirement = 0.01 ether; // Default minimum stake
    uint256 public reputationGainContributionAccepted = 5; // Reputation gained per accepted contribution
    uint256 public reputationGainProjectCompleted = 10; // Reputation gained per project completion

    modifier onlyParticipant(uint256 _projectId) {
        require(projects[_projectId].isParticipant[msg.sender], "Not a participant");
        _;
    }

    modifier inProjectState(uint256 _projectId, ProjectState _expectedState) {
        require(projects[_projectId].state == _expectedState, "Invalid project state");
        _;
    }

    modifier isValidRoyaltySplit(RoyaltyRecipient[] memory _recipients) {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i].recipient != address(0), "Invalid recipient address");
            totalPercentage = totalPercentage.add(_recipients[i].percentage);
        }
        require(totalPercentage == 10000, "Royalty percentages must sum to 100%");
        _;
    }

    event ProjectProposed(uint256 indexed projectId, address indexed creator, string title, uint256 activationStake);
    event ProjectActivated(uint256 indexed projectId, uint256 activationTimestamp);
    event JoinedProject(uint256 indexed projectId, address indexed participant, uint256 stakedAmount);
    event LeftProject(uint256 indexed projectId, address indexed participant, uint256 refundedAmount);
    event ContentVotingStarted(uint256 indexed projectId, uint256 endTime);
    event OutcomeVotingStarted(uint256 indexed projectId, uint256 endTime);
    event ProjectCompleted(uint256 indexed projectId, uint256 indexed nftId);
    event ProjectCancelled(uint256 indexed projectId);
    event StakeClaimed(uint256 indexed projectId, address indexed participant, uint256 amount);

    event ContributionSubmitted(uint256 indexed projectId, uint256 indexed contributionId, address indexed contributor, string contentHash);
    event ContributionUpdated(uint256 indexed contributionId, string newContentHash);
    event ContributionWithdrawn(uint256 indexed contributionId);
    event ContributionAccepted(uint256 indexed contributionId);
    event ContributionRejected(uint256 indexed contributionId);

    event VotedOnContent(uint256 indexed projectId, uint256 indexed contributionId, address indexed voter, VoteType vote);
    event VotedOnOutcome(uint256 indexed projectId, address indexed voter, VoteType vote);
    event VoteRevoked(uint256 indexed projectId, uint256 targetId, address indexed voter, uint256 voteTypeIdentifier);

    event ReputationUpdated(address indexed user, uint256 newReputation);

    event ProjectNFTMinted(uint256 indexed projectId, uint256 indexed tokenId);
    event NFTTraitUpdated(uint256 indexed tokenId, uint256 newState);

    event RoyaltySplitSet(uint256 indexed projectId, RoyaltyRecipient[] recipients);
    event RoyaltiesDistributed(uint256 indexed projectId, uint256 totalAmount);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    // --- Project Management ---

    /**
     * @notice Proposes a new collaborative project.
     * @param _title The title of the project.
     * @param _description A description of the project.
     * @param _activationStakeRequired The total amount of ETH required to be staked by participants to activate the project.
     * @param _contentVotingPeriodDuration Duration for the content voting phase in seconds.
     * @param _outcomeVotingPeriodDuration Duration for the outcome voting phase in seconds.
     */
    function proposeProject(
        string memory _title,
        string memory _description,
        uint256 _activationStakeRequired,
        uint256 _contentVotingPeriodDuration,
        uint256 _outcomeVotingPeriodDuration
    ) external returns (uint256 projectId) {
        _projectIds.increment();
        projectId = _projectIds.current();

        projects[projectId] = Project({
            id: projectId,
            creator: msg.sender,
            state: ProjectState.Proposed,
            title: _title,
            description: _description,
            activationStakeRequired: _activationStakeRequired,
            totalStaked: 0,
            proposalTimestamp: block.timestamp,
            activationTimestamp: 0,
            contentVotingStartTimestamp: 0,
            contentVotingEndTimestamp: 0,
            outcomeVotingStartTimestamp: 0,
            outcomeVotingEndTimestamp: 0,
            contentVotingPeriodDuration: _contentVotingPeriodDuration,
            outcomeVotingPeriodDuration: _outcomeVotingPeriodDuration,
            participants: new address[](0),
            stakedFunds: mapping(address => uint256), // Handled by compiler/runtime
            isParticipant: mapping(address => bool), // Handled by compiler/runtime
            contributionIds: new uint256[](0),
            acceptedContributionIds: new uint256[](0),
            contentVotes: mapping(address => VoteType), // Deprecated, using contributionVotes
            contributionVotes: mapping(uint256 => mapping(address => VoteType)),
            outcomeVotes: mapping(address => VoteType),
            associatedNFT: 0,
            royaltySplit: new RoyaltyRecipient[](0),
            royaltySplitSet: false
        });

        // Creator is automatically a participant
        _addParticipant(projectId, msg.sender, 0); // Creator doesn't need to stake initially, but can later if desired/required

        emit ProjectProposed(projectId, msg.sender, _title, _activationStakeRequired);
    }

    /**
     * @notice Allows a user to join a project proposal by staking ETH.
     * @param _projectId The ID of the project to join.
     */
    function stakeAndJoinProject(uint256 _projectId) external payable inProjectState(_projectId, ProjectState.Proposed) {
        Project storage project = projects[_projectId];
        require(msg.value > 0, "Must stake a positive amount");
        require(!project.isParticipant[msg.sender], "Already a participant");

        project.stakedFunds[msg.sender] = project.stakedFunds[msg.sender].add(msg.value);
        project.totalStaked = project.totalStaked.add(msg.value);

        _addParticipant(_projectId, msg.sender, msg.value);

        emit JoinedProject(_projectId, msg.sender, msg.value);
    }

    /**
     * @notice Allows a participant to leave a project proposal before it's active.
     * @param _projectId The ID of the project.
     */
    function leaveProjectBeforeActive(uint256 _projectId) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.Proposed) nonReentrant {
        Project storage project = projects[_projectId];
        uint256 staked = project.stakedFunds[msg.sender];
        require(staked > 0, "No stake to claim");

        project.stakedFunds[msg.sender] = 0;
        project.totalStaked = project.totalStaked.sub(staked);

        _removeParticipant(_projectId, msg.sender);

        (bool success, ) = payable(msg.sender).call{value: staked}("");
        require(success, "Stake transfer failed");

        emit LeftProject(_projectId, msg.sender, staked);
        emit StakeClaimed(_projectId, msg.sender, staked);
    }

    /**
     * @notice Activates a project if the stake requirement is met. Callable by any participant (or could be time-based).
     * @param _projectId The ID of the project.
     */
    function activateProject(uint256 _projectId) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.Proposed) {
        Project storage project = projects[_projectId];
        require(project.totalStaked >= project.activationStakeRequired, "Stake requirement not met");

        project.state = ProjectState.Active;
        project.activationTimestamp = block.timestamp;

        emit ProjectActivated(_projectId, block.timestamp);
    }

    /**
     * @notice Starts the content voting phase. (Intended to be called via automation/oracle or by creator after sufficient active time)
     * @param _projectId The ID of the project.
     */
    function startProjectVoting(uint256 _projectId) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.Active) {
        Project storage project = projects[_projectId];
        require(project.contentVotingPeriodDuration > 0, "Content voting period not set");

        project.state = ProjectState.ContentVoting;
        project.contentVotingStartTimestamp = block.timestamp;
        project.contentVotingEndTimestamp = block.timestamp.add(project.contentVotingPeriodDuration);

        emit ContentVotingStarted(_projectId, project.contentVotingEndTimestamp);
    }

    /**
     * @notice Starts the outcome voting phase after content voting ends. (Intended to be called via automation/oracle)
     * @param _projectId The ID of the project.
     */
    function startOutcomeVoting(uint256 _projectId) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.ContentVoting) {
        Project storage project = projects[_projectId];
        require(block.timestamp >= project.contentVotingEndTimestamp, "Content voting is not over yet");
        require(project.outcomeVotingPeriodDuration > 0, "Outcome voting period not set");

        // Determine accepted content based on content voting results
        _tallyContentVotes(_projectId);

        project.state = ProjectState.OutcomeVoting;
        project.outcomeVotingStartTimestamp = block.timestamp;
        project.outcomeVotingEndTimestamp = block.timestamp.add(project.outcomeVotingPeriodDuration);

        emit OutcomeVotingStarted(_projectId, project.outcomeVotingEndTimestamp);
    }


    /**
     * @notice Finalizes the project after outcome voting ends. Determines success, mints NFT, handles stake. (Intended via automation/oracle)
     * @param _projectId The ID of the project.
     */
    function finalizeProjectVoting(uint256 _projectId) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.OutcomeVoting) nonReentrant {
        Project storage project = projects[_projectId];
        require(block.timestamp >= project.outcomeVotingEndTimestamp, "Outcome voting is not over yet");

        uint256 approveVotes = 0;
        uint256 rejectVotes = 0;

        // Tally outcome votes
        for (uint256 i = 0; i < project.participants.length; i++) {
            address participant = project.participants[i];
            if (project.outcomeVotes[participant] == VoteType.Approve) {
                approveVotes++;
            } else if (project.outcomeVotes[participant] == VoteType.Reject) {
                rejectVotes++;
            }
            // Note: Users who didn't vote are not counted
        }

        bool projectSuccessful = approveVotes > rejectVotes && approveVotes > 0; // Needs a positive vote count

        if (projectSuccessful) {
            project.state = ProjectState.Completed;
            _mintProjectNFT(_projectId);

            // Reputation gain for participants and contributors of accepted content
            for(uint256 i = 0; i < project.participants.length; i++) {
                 _updateReputation(project.participants[i], reputationGainProjectCompleted);
            }
            for(uint256 i = 0; i < project.acceptedContributionIds.length; i++) {
                 _updateReputation(contributions[project.acceptedContributionIds[i]].contributor, reputationGainContributionAccepted);
            }

            // Staked funds remain locked/potentially distributed later (e.g., if NFT has fractional ownership & sales)
            // For this example, they remain locked. A more complex version might have a governance vote on stake use.

            emit ProjectCompleted(_projectId, project.associatedNFT);

        } else {
            // Project failed
            project.state = ProjectState.Cancelled; // Consider 'Failed' state? Cancelled works for now.

            // Allow participants to claim staked funds back
            // Stake claim is handled by `claimStakedFunds` function

            emit ProjectCancelled(_projectId);
        }
    }

     /**
     * @notice Allows the creator to cancel a project proposal before it's active.
     * @param _projectId The ID of the project.
     */
    function cancelProjectProposal(uint256 _projectId) external inProjectState(_projectId, ProjectState.Proposed) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator == msg.sender, "Only creator can cancel proposal");

        project.state = ProjectState.Cancelled;

        // Allow participants to claim staked funds back
        // Stake claim is handled by `claimStakedFunds` function

        emit ProjectCancelled(_projectId);
    }


    /**
     * @notice Allows a participant to claim their staked funds if the project is in a Cancelled state.
     * @param _projectId The ID of the project.
     */
    function claimStakedFunds(uint256 _projectId) external onlyParticipant(_projectId) nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Cancelled, "Project must be cancelled to claim stake");

        uint256 staked = project.stakedFunds[msg.sender];
        require(staked > 0, "No stake to claim");

        project.stakedFunds[msg.sender] = 0;
        // No need to update totalStaked as project is finished/cancelled

        (bool success, ) = payable(msg.sender).call{value: staked}("");
        require(success, "Stake transfer failed");

        emit StakeClaimed(_projectId, msg.sender, staked);
    }

    // --- Contribution Management ---

    /**
     * @notice Submits a content hash (e.g., IPFS CID) as a contribution to a project.
     * @param _projectId The ID of the project.
     * @param _contentHash The hash representing the content.
     */
    function submitContribution(uint256 _projectId, string memory _contentHash) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.Active) {
        _contributionIds.increment();
        uint256 contributionId = _contributionIds.current();

        projects[_projectId].contributionIds.push(contributionId);

        contributions[contributionId] = Contribution({
            id: contributionId,
            projectId: _projectId,
            contributor: msg.sender,
            contentHash: _contentHash,
            submissionTimestamp: block.timestamp,
            submissionState: projects[_projectId].state, // Snapshot state
            status: VoteType.None,
            approveVotes: 0,
            rejectVotes: 0
        });

        emit ContributionSubmitted(_projectId, contributionId, msg.sender, _contentHash);
    }

    /**
     * @notice Updates a previously submitted contribution's content hash. Only callable by the contributor before voting starts.
     * @param _contributionId The ID of the contribution to update.
     * @param _newContentHash The new hash for the content.
     */
    function updateContribution(uint256 _contributionId, string memory _newContentHash) external {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor == msg.sender, "Only the contributor can update");
        require(projects[contribution.projectId].state == ProjectState.Active, "Project is not in active state"); // Can only update before voting
        require(contribution.approveVotes == 0 && contribution.rejectVotes == 0, "Cannot update once voting has started"); // Check if any votes cast

        contribution.contentHash = _newContentHash;
        emit ContributionUpdated(_contributionId, _newContentHash);
    }

    /**
     * @notice Allows a contributor to withdraw their contribution if eligible.
     * @param _contributionId The ID of the contribution.
     */
    function withdrawContribution(uint256 _contributionId) external {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor == msg.sender, "Only the contributor can withdraw");
        require(projects[contribution.projectId].state <= ProjectState.Active, "Contribution cannot be withdrawn after voting starts");
        require(contribution.approveVotes == 0 && contribution.rejectVotes == 0, "Cannot withdraw once voting has started");

        // Remove contribution from project's list (potentially gas costly if list is very long, use a sparse representation for large projects)
        Project storage project = projects[contribution.projectId];
        for (uint265 i = 0; i < project.contributionIds.length; i++) {
             if (project.contributionIds[i] == _contributionId) {
                 // Simple remove: replace with last element and pop (changes order)
                 project.contributionIds[i] = project.contributionIds[project.contributionIds.length - 1];
                 project.contributionIds.pop();
                 break;
             }
        }

        delete contributions[_contributionId]; // Delete data (saves gas on future reads)
        emit ContributionWithdrawn(_contributionId);
    }


    // --- Voting & Governance ---

    /**
     * @notice Allows a participant to vote on a specific content contribution. 1 participant, 1 vote per contribution.
     * @param _projectId The ID of the project.
     * @param _contributionId The ID of the contribution to vote on.
     * @param _vote The vote (Approve or Reject).
     */
    function voteOnContent(uint256 _projectId, uint256 _contributionId, VoteType _vote) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.ContentVoting) {
        require(_vote == VoteType.Approve || _vote == VoteType.Reject, "Invalid vote type");
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.projectId == _projectId, "Contribution does not belong to this project");

        Project storage project = projects[_projectId];
        require(project.contributionVotes[_contributionId][msg.sender] == VoteType.None, "Already voted on this content");

        project.contributionVotes[_contributionId][msg.sender] = _vote;

        if (_vote == VoteType.Approve) {
            contribution.approveVotes++;
        } else {
            contribution.rejectVotes++;
        }

        emit VotedOnContent(_projectId, _contributionId, msg.sender, _vote);
    }

    /**
     * @notice Allows a participant to vote on the overall project outcome. 1 participant, 1 vote per project outcome.
     * @param _projectId The ID of the project.
     * @param _vote The vote (Approve or Reject).
     */
    function voteOnProjectOutcome(uint256 _projectId, VoteType _vote) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.OutcomeVoting) {
        require(_vote == VoteType.Approve || _vote == VoteType.Reject, "Invalid vote type");
        Project storage project = projects[_projectId];
        require(project.outcomeVotes[msg.sender] == VoteType.None, "Already voted on project outcome");

        project.outcomeVotes[msg.sender] = _vote;

        emit VotedOnOutcome(_projectId, msg.sender, _vote);
    }

     /**
     * @notice Allows a participant to revoke a previous vote before the voting period ends.
     * @param _projectId The ID of the project.
     * @param _targetId The ID of the target (Contribution ID for content vote, 0 or project ID for outcome vote).
     * @param _voteTypeIdentifier 0 for content vote, 1 for outcome vote.
     */
    function revokeVote(uint256 _projectId, uint256 _targetId, uint256 _voteTypeIdentifier) external onlyParticipant(_projectId) {
        Project storage project = projects[_projectId];

        if (_voteTypeIdentifier == 0) { // Content Vote
            require(project.state == ProjectState.ContentVoting, "Cannot revoke content vote in current state");
             require(block.timestamp < project.contentVotingEndTimestamp, "Cannot revoke content vote after period ends");
            Contribution storage contribution = contributions[_targetId];
            require(contribution.projectId == _projectId, "Target ID is not a contribution for this project");

            VoteType currentVote = project.contributionVotes[_targetId][msg.sender];
            require(currentVote != VoteType.None, "No vote cast on this content");

            if (currentVote == VoteType.Approve) {
                contribution.approveVotes--;
            } else { // Reject
                contribution.rejectVotes--;
            }
            project.contributionVotes[_targetId][msg.sender] = VoteType.None;

            emit VoteRevoked(_projectId, _targetId, msg.sender, _voteTypeIdentifier);

        } else if (_voteTypeIdentifier == 1) { // Outcome Vote
            require(project.state == ProjectState.OutcomeVoting, "Cannot revoke outcome vote in current state");
             require(block.timestamp < project.outcomeVotingEndTimestamp, "Cannot revoke outcome vote after period ends");

            VoteType currentVote = project.outcomeVotes[msg.sender];
            require(currentVote != VoteType.None, "No outcome vote cast");

            project.outcomeVotes[msg.sender] = VoteType.None;

            emit VoteRevoked(_projectId, _targetId, msg.sender, _voteTypeIdentifier);

        } else {
            revert("Invalid vote type identifier");
        }
    }


    // --- Reputation System (Internal Helper) ---

    /**
     * @notice Internal function to update a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount to add to reputation.
     */
    function _updateReputation(address _user, uint256 _amount) internal {
        userReputation[_user] = userReputation[_user].add(_amount);
        emit ReputationUpdated(_user, userReputation[_user]);
    }

    /**
     * @notice Get a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }


    // --- NFT & Royalties ---

    /**
     * @notice Internal function to mint the project NFT upon successful completion.
     * @param _projectId The ID of the completed project.
     */
    function _mintProjectNFT(uint256 _projectId) internal {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "Project not in completed state");
        require(project.associatedNFT == 0, "NFT already minted for this project");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Mint to the creator or the contract/a governance mechanism for shared ownership?
        // Let's mint to the contract initially, representing collective ownership or requiring a claim mechanism.
        // For simplicity in this example, let's mint to the project creator. A more advanced system might
        // use fractional ownership (ERC1155 or external protocol) or a dedicated vault.
        _safeMint(project.creator, newTokenId);

        project.associatedNFT = newTokenId;
        projectNFT[_projectId] = newTokenId;
        nftProject[newTokenId] = _projectId;

        // Set initial dynamic trait state (e.g., based on # accepted contributions)
        nftDynamicTrait[newTokenId] = project.acceptedContributionIds.length; // Example trait

        emit ProjectNFTMinted(_projectId, newTokenId);
        emit NFTTraitUpdated(newTokenId, nftDynamicTrait[newTokenId]);
    }

    /**
     * @notice Allows updating a dynamic trait state on a project's NFT.
     * Callable by the contract itself (e.g., from `finalizeProjectVoting`) or specific roles.
     * In this simplified example, let's allow the project creator to trigger updates
     * on *some* conditions, or perhaps governance. Restricting for now.
     * A realistic scenario would have specific triggers (e.g., NFT staked, revenue generated).
     * Let's make it callable by the contract's creator or a designated admin for demonstration.
     * @param _projectId The ID of the project whose NFT trait to update.
     * @param _newState The new state for the dynamic trait.
     */
    function updateNFTTraitState(uint256 _projectId, uint256 _newState) external {
        Project storage project = projects[_projectId];
        require(project.associatedNFT != 0, "Project does not have an associated NFT");
        // Basic access control: only contract deployer or creator? Let's allow creator for demo.
        require(project.creator == msg.sender, "Only project creator can trigger trait update");

        uint256 tokenId = project.associatedNFT;
        nftDynamicTrait[tokenId] = _newState;

        emit NFTTraitUpdated(tokenId, _newState);
    }

    /**
     * @notice Allows setting the royalty split for a completed project's NFT revenue.
     * Can only be set once after the project is completed, ideally voted on by participants.
     * For simplicity, allows the project creator to propose, subject to participant approval (not implemented fully).
     * Requires the project to be Completed and royalty split not yet set.
     * @param _projectId The ID of the completed project.
     * @param _recipients Array of recipients and their percentage shares (out of 10000).
     */
    function setProjectRoyaltySplit(uint256 _projectId, RoyaltyRecipient[] memory _recipients) external onlyParticipant(_projectId) inProjectState(_projectId, ProjectState.Completed) isValidRoyaltySplit(_recipients) {
        Project storage project = projects[_projectId];
        require(!project.royaltySplitSet, "Royalty split already set for this project");
        // In a real system, this might require participant voting/approval
        // require(project.creator == msg.sender || /* check governance/voting outcome */, "Unauthorized to set royalty split");

        project.royaltySplit = _recipients;
        project.royaltySplitSet = true;

        emit RoyaltySplitSet(_projectId, _recipients);
    }

    /**
     * @notice Receives ETH and distributes it as royalties according to the set split for a completed project.
     * Any address can send funds here, specifying the project ID.
     * @param _projectId The ID of the completed project.
     */
    function distributeProjectRevenue(uint256 _projectId) external payable nonReentrant {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Completed, "Project must be completed");
        require(project.royaltySplitSet, "Royalty split not set for this project");
        require(msg.value > 0, "Must send ETH to distribute");

        uint256 totalAmount = msg.value;
        uint256 distributedAmount = 0;

        for (uint256 i = 0; i < project.royaltySplit.length; i++) {
            address recipient = project.royaltySplit[i].recipient;
            uint256 percentage = project.royaltySplit[i].percentage;
            uint256 share = totalAmount.mul(percentage).div(10000);

            if (share > 0) {
                 // Use low-level call for robustness in distribution loop
                (bool success, ) = payable(recipient).call{value: share}("");
                // Log success/failure internally, or handle failure, but don't revert the whole distribution
                if (success) {
                    distributedAmount = distributedAmount.add(share);
                }
            }
        }

        // Send any remainder back to the sender if distribution failed partially
        if (totalAmount > distributedAmount) {
             (bool success, ) = payable(msg.sender).call{value: totalAmount.sub(distributedAmount)}("");
             // Log if remainder couldn't be sent back
             require(success, "Failed to return remainder");
        }


        emit RoyaltiesDistributed(_projectId, distributedAmount);
    }


    // --- Internal Helpers ---

    /**
     * @notice Helper to add a participant to a project's internal lists/mappings.
     * @param _projectId The project ID.
     * @param _participant The participant address.
     * @param _stakedAmount The amount staked (can be 0).
     */
    function _addParticipant(uint256 _projectId, address _participant, uint256 _stakedAmount) internal {
        Project storage project = projects[_projectId];
        project.participants.push(_participant);
        project.isParticipant[_participant] = true;

        // Add project ID to user's list of projects (avoiding duplicates, gas-wise simple append)
        bool alreadyListed = false;
        for(uint256 i = 0; i < userProjects[_participant].length; i++) {
            if(userProjects[_participant][i] == _projectId) {
                alreadyListed = true;
                break;
            }
        }
        if (!alreadyListed) {
             userProjects[_participant].push(_projectId);
        }
    }

     /**
     * @notice Helper to remove a participant from a project's internal lists/mappings (if leaving).
     * @param _projectId The project ID.
     * @param _participant The participant address.
     */
    function _removeParticipant(uint256 _projectId, address _participant) internal {
        Project storage project = projects[_projectId];
        project.isParticipant[_participant] = false;

        // Remove from the participants array (order changes, less gas)
        for (uint256 i = 0; i < project.participants.length; i++) {
            if (project.participants[i] == _participant) {
                project.participants[i] = project.participants[project.participants.length - 1];
                project.participants.pop();
                break;
            }
        }

        // Note: User's project list (userProjects) is NOT updated here for simplicity and gas.
        // It remains a history of projects the user joined, regardless of whether they left later.
    }


    /**
     * @notice Internal function to tally content votes and update contribution statuses.
     * Called when moving from ContentVoting to OutcomeVoting.
     * Requires a simple majority (> 50%) of participating votes to be accepted.
     * Only participants who voted on a specific contribution are counted for that contribution's tally.
     * @param _projectId The ID of the project.
     */
    function _tallyContentVotes(uint256 _projectId) internal {
        Project storage project = projects[_projectId];

        for (uint256 i = 0; i < project.contributionIds.length; i++) {
            uint256 contributionId = project.contributionIds[i];
            Contribution storage contribution = contributions[contributionId];

            // Count total votes cast on THIS specific contribution by participants
            uint256 totalContributionVotesCast = contribution.approveVotes.add(contribution.rejectVotes);

            if (totalContributionVotesCast > 0) {
                // Simple majority: approve votes > reject votes AND approve votes > 0
                if (contribution.approveVotes > contribution.rejectVotes) {
                     contribution.status = VoteType.Approve;
                     project.acceptedContributionIds.push(contributionId);
                     emit ContributionAccepted(contributionId);
                } else {
                     contribution.status = VoteType.Reject;
                     emit ContributionRejected(contributionId);
                }
            } else {
                // No votes cast on this contribution
                 contribution.status = VoteType.None; // Or define 'Neutral'?
            }
        }
    }


    // --- Query Functions (View) ---

    /**
     * @notice Gets detailed information about a project.
     * @param _projectId The ID of the project.
     * @return Project struct containing all details.
     */
    function getProjectDetails(uint256 _projectId) external view returns (Project memory) {
        Project storage project = projects[_projectId];
         // Need to manually copy struct state variables that are mappings
        Project memory projectDetails = project;
        // Mappings are not returned by value in structs.
        // Other specific get functions provide mapping data.
        // For simplicity, this basic struct return is shown, but mapping data requires separate calls.
         // A more complete solution would fetch mapping data separately or pass necessary parts.
         // Let's return the base struct data and rely on other view functions for mapping data.
         projectDetails.stakedFunds = mapping(address => uint256); // Reset mapping fields in memory struct
         projectDetails.isParticipant = mapping(address => bool);
         projectDetails.contributionVotes = mapping(uint256 => mapping(address => VoteType));
         projectDetails.outcomeVotes = mapping(address => VoteType);
         projectDetails.royaltySplit = project.royaltySplit; // Arrays CAN be returned

        return projectDetails;
    }

    /**
     * @notice Gets the list of participant addresses for a project.
     * @param _projectId The ID of the project.
     * @return An array of participant addresses.
     */
    function getProjectParticipants(uint256 _projectId) external view returns (address[] memory) {
        return projects[_projectId].participants;
    }

    /**
     * @notice Gets the list of contribution IDs for a project.
     * @param _projectId The ID of the project.
     * @return An array of contribution IDs.
     */
    function getProjectContributions(uint256 _projectId) external view returns (uint256[] memory) {
        return projects[_projectId].contributionIds;
    }

     /**
     * @notice Gets detailed information about a contribution.
     * @param _contributionId The ID of the contribution.
     * @return Contribution struct containing details.
     */
    function getContributionDetails(uint256 _contributionId) external view returns (Contribution memory) {
        return contributions[_contributionId];
    }


    /**
     * @notice Gets the votes cast on each content contribution within a project by each participant.
     * @param _projectId The ID of the project.
     * @return An array of structs or a more complex representation of votes.
     * Note: Returning complex mapping data directly from a view function is limited.
     * This requires iterating or having separate functions.
     * Let's return a simplified view or require clients to query per contribution/participant.
     * A common pattern is to return arrays of relevant IDs, then clients query details.
     * Returning votes per content item for demonstration:
     */
    function getProjectContentVotes(uint256 _projectId) external view returns (uint256[] memory contributionIds, VoteType[][] memory votesByParticipant) {
        Project storage project = projects[_projectId];
        uint256[] memory cIds = project.contributionIds;
        contributionIds = cIds; // shallow copy

        votesByParticipant = new VoteType[][](cIds.length);
        for (uint256 i = 0; i < cIds.length; i++) {
            uint256 cId = cIds[i];
            VoteType[] memory participantVotes = new VoteType[](project.participants.length);
            for (uint265 j = 0; j < project.participants.length; j++) {
                 participantVotes[j] = project.contributionVotes[cId][project.participants[j]];
            }
            votesByParticipant[i] = participantVotes;
        }
        return (contributionIds, votesByParticipant);
    }


    /**
     * @notice Gets the votes cast on the project outcome by each participant.
     * @param _projectId The ID of the project.
     * @return Two arrays: participant addresses and their corresponding VoteType (Approve/Reject).
     */
    function getProjectOutcomeVotes(uint256 _projectId) external view returns (address[] memory participants, VoteType[] memory votes) {
        Project storage project = projects[_projectId];
        participants = project.participants;
        votes = new VoteType[](participants.length);
        for (uint256 i = 0; i < participants.length; i++) {
            votes[i] = project.outcomeVotes[participants[i]];
        }
        return (participants, votes);
    }


     /**
     * @notice Gets the list of contribution IDs that were accepted via voting.
     * @param _projectId The ID of the project.
     * @return An array of accepted contribution IDs.
     */
    function getProjectAcceptedContent(uint256 _projectId) external view returns (uint256[] memory) {
        return projects[_projectId].acceptedContributionIds;
    }

     /**
     * @notice Gets a list of projects a user has participated in.
     * @param _user The address of the user.
     * @return An array of project IDs.
     */
    function getUserProjects(address _user) external view returns (uint256[] memory) {
        return userProjects[_user];
    }

    /**
     * @notice Gets the NFT token ID associated with a completed project.
     * @param _projectId The ID of the project.
     * @return The NFT token ID (0 if not minted yet).
     */
    function getProjectNFTId(uint256 _projectId) external view returns (uint256) {
        return projects[_projectId].associatedNFT;
    }

    /**
     * @notice Gets the current state of the dynamic trait for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The uint256 value representing the dynamic trait state.
     */
    function getNFTTraitState(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "ERC721: token query for nonexistent token");
        return nftDynamicTrait[_tokenId];
    }

    /**
     * @notice Gets the configured royalty split for a completed project.
     * @param _projectId The ID of the project.
     * @return An array of RoyaltyRecipient structs.
     */
    function getProjectRoyaltySplit(uint256 _projectId) external view returns (RoyaltyRecipient[] memory) {
        return projects[_projectId].royaltySplit;
    }

     /**
     * @notice Gets the current state of a project.
     * @param _projectId The ID of the project.
     * @return The ProjectState enum value.
     */
    function getProjectState(uint256 _projectId) external view returns (ProjectState) {
        return projects[_projectId].state;
    }


    // The following functions are standard ERC721Enumerable overrides/implementations.
    // Included for completeness but not counted in the 20+ *custom* functions list.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```