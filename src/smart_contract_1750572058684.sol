Okay, let's design a smart contract around a decentralized creative collective or "Syndicate". This Syndicate will manage membership (via an NFT), fund internal projects through a proposal/voting system, track contributions via a non-transferable "Influence" score, and even run creative "Challenges".

This involves several advanced concepts:
*   **NFT Gating:** Membership requires holding a specific NFT.
*   **Custom Non-Transferable Token (Influence):** A points system for reputation/contribution.
*   **Dynamic Voting Weight:** Voting power scales with Influence.
*   **State Machines:** Proposals and Projects have lifecycle states.
*   **Internal Treasury Management:** Funding projects from collected ETH.
*   **Decentralized Project Management:** Basic tracking of funded projects and milestones.
*   **Gamification/Incentives:** Challenges award Influence points.

We will create a contract that depends on an external ERC721 contract for the membership NFT.

Here's the contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity for owner functions
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Added for treasury withdrawal

// --- Outline and Function Summary ---
//
// Contract: SyndicateOfPerpetualCreation
// Description: A decentralized autonomous organization (DAO) for funding and managing creative projects.
// Membership is gated by holding a specific ERC721 NFT ("Genesis Stone").
// Members propose projects, vote on funding, manage project milestones, and earn non-transferable "Influence" points for contributions.
// Influence points determine dynamic voting weight and grant access to certain actions.
// The Syndicate manages a treasury to fund approved projects.
// Creative Challenges can be initiated to incentivize specific contributions and award Influence.
//
// State Variables:
// - owner: The contract deployer (basic admin role).
// - genesisStoneNFT: Address of the ERC721 contract representing Syndicate membership.
// - memberInfluence: Mapping from member address to their Influence points.
// - proposals: Mapping from proposal ID to Proposal struct.
// - projects: Mapping from project ID to Project struct.
// - challenges: Mapping from challenge ID to Challenge struct.
// - nextProposalId: Counter for new proposals.
// - nextProjectId: Counter for new projects.
// - nextChallengeId: Counter for new challenges.
// - totalInfluence: Total Influence points across all members.
// - memberVotingRecord: Nested mapping to track member votes on proposals.
// - proposalVoteCounts: Mapping to store yay/nay counts for proposals.
//
// Enums:
// - ProposalState: Lifecycle of a proposal (Pending, Approved, Rejected, Executed).
// - ProjectState: Lifecycle of a project (Planning, InProgress, Completed, Cancelled).
// - ChallengeState: Lifecycle of a challenge (Active, Completed).
//
// Structs:
// - Proposal: Details of a funding proposal.
// - Milestone: Details for a project milestone.
// - Project: Details of a funded project.
// - Challenge: Details of a creative challenge.
//
// Events: (Key actions logged)
// - GenesisStoneNFTSet
// - TreasuryDeposited
// - TreasuryWithdrawn
// - ProposalSubmitted
// - VotedOnProposal
// - ProposalExecuted
// - ProjectFunded
// - MilestoneReported
// - ProjectCancelled
// - ProjectFundsReturned
// - InfluenceAwarded
// - VoteWeightUpdated
// - ChallengeCreated
// - JoinedChallenge
// - ChallengeCompleted
//
// Functions (26 total):
//
// Management & Setup (4):
// 1. constructor(): Initializes the contract owner.
// 2. setGenesisStoneNFT(address _nftAddress): Sets the address of the membership NFT contract. (Owner only)
// 3. getGenesisStoneNFT(): Returns the address of the membership NFT contract. (View)
// 4. isMember(address _addr): Checks if an address holds a Genesis Stone NFT (is a member). (View)
//
// Treasury (3):
// 5. depositTreasury(): Allows anyone to send ETH to the contract treasury.
// 6. getTreasuryBalance(): Returns the current ETH balance of the treasury. (View)
// 7. withdrawTreasury(address _to, uint256 _amount): Owner/governance withdraws from treasury (simplified). (Owner only, ReentrancyGuard)
//
// Proposals & Voting (7):
// 8. submitProposal(string calldata _title, string calldata _description, uint256 _amountRequested, uint256 _votingDeadline): Member submits a new project proposal.
// 9. getProposal(uint256 _proposalId): Returns details of a specific proposal. (View)
// 10. voteOnProposal(uint256 _proposalId, bool _vote): Member votes Yay (true) or Nay (false) on a proposal. Awards base influence for voting.
// 11. getMemberVoteWeight(address _member): Returns a member's current voting weight based on Influence. (View)
// 12. executeProposal(uint256 _proposalId): Finalizes voting, approves/rejects the proposal, and funds the project if approved. Awards additional influence for voting participation based on outcome.
// 13. getProposalVoteCounts(uint256 _proposalId): Returns the current Yay and Nay vote counts for a proposal. (View)
// 14. getProposalState(uint256 _proposalId): Returns the current state of a proposal. (View)
//
// Projects (5):
// 15. getProject(uint256 _projectId): Returns details of a specific project. (View)
// 16. reportProjectMilestoneCompleted(uint256 _projectId, uint256 _milestoneIndex): Project lead (or designated role) reports a milestone completion. Awards influence.
// 17. getProjectMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex): Returns the completion status of a specific milestone. (View)
// 18. cancelProject(uint256 _projectId): Owner/Governance cancels a project. Funds returned to treasury. (Owner only)
// 19. returnUnusedProjectFunds(uint256 _projectId): Allows the project proposer to return excess funds to the treasury. (ReentrancyGuard)
//
// Influence & Reputation (2):
// 20. getMemberInfluence(address _member): Returns a member's current Influence points. (View)
// 21. getTotalInfluence(): Returns the total cumulative Influence points in the system. (View)
//
// Challenges (5):
// 22. createChallenge(string calldata _title, string calldata _description, uint256 _rewardInfluence, uint256 _deadline): Owner creates a new Challenge. (Owner only)
// 23. joinChallenge(uint256 _challengeId): Member joins an active Challenge.
// 24. completeChallenge(uint256 _challengeId): Owner marks a Challenge as completed and distributes reward Influence to participants. (Owner only)
// 25. getChallenge(uint256 _challengeId): Returns details of a specific Challenge. (View)
// 26. getMemberChallenges(address _member): Returns IDs of challenges a member has joined. (View - requires additional mapping or iteration, let's simplify and just check participation in `getChallenge`) - Replaced with simplified participation check. Let's add a function to check specific participation instead.
// 26. hasJoinedChallenge(uint256 _challengeId, address _member): Checks if a member has joined a specific challenge. (View)
//
// --- End of Outline ---

contract SyndicateOfPerpetualCreation is Ownable, ReentrancyGuard {

    // --- Dependencies ---
    IERC721 public genesisStoneNFT;

    // --- State Variables ---
    mapping(address => uint256) public memberInfluence;
    uint256 public totalInfluence; // Cumulative influence awarded

    // Proposals
    enum ProposalState { Pending, Approved, Rejected, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 amountRequested;
        uint256 votingDeadline;
        ProposalState state;
        uint256 projectId; // ID of the project if approved and executed
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    // Voting
    mapping(uint256 => mapping(address => bool)) private memberVotingRecord; // proposalId => memberAddress => voted
    mapping(uint256 => uint256) public proposalYayVotes;
    mapping(uint256 => uint256) public proposalNayVotes;

    // Projects
    enum ProjectState { Planning, InProgress, Completed, Cancelled }
    struct Milestone {
        string description;
        bool completed;
    }
    struct Project {
        uint256 id;
        uint256 proposalId; // Link back to the funding proposal
        address proposer; // Original proposer who likely leads the project
        uint256 fundedAmount;
        Milestone[] milestones; // Array of milestones
        ProjectState state;
        uint256 currentMilestoneIndex; // Index of the next expected milestone completion
    }
    mapping(uint256 => Project) public projects;
    uint256 public nextProjectId;

    // Challenges
    enum ChallengeState { Active, Completed }
    struct Challenge {
        uint256 id;
        string title;
        string description;
        uint256 rewardInfluence; // Total influence distributed to participants
        uint256 deadline; // When challenge ends
        ChallengeState state;
        mapping(address => bool) participants; // Tracks who joined
        address[] participantList; // To iterate over participants when completing
    }
    mapping(uint256 => Challenge) public challenges;
    uint256 public nextChallengeId;

    // --- Events ---
    event GenesisStoneNFTSet(address indexed _nftAddress);
    event TreasuryDeposited(address indexed _from, uint256 _amount);
    event TreasuryWithdrawn(address indexed _to, uint256 _amount);

    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, uint256 _amountRequested, uint256 _votingDeadline);
    event VotedOnProposal(uint256 indexed _proposalId, address indexed _voter, bool _vote, uint256 _influenceAwarded);
    event ProposalExecuted(uint256 indexed _proposalId, ProposalState _finalState);

    event ProjectFunded(uint256 indexed _projectId, uint256 indexed _proposalId, uint256 _amount);
    event MilestoneReported(uint256 indexed _projectId, uint256 _milestoneIndex, address indexed _reporter, uint256 _influenceAwarded);
    event ProjectCancelled(uint256 indexed _projectId);
    event ProjectFundsReturned(uint256 indexed _projectId, uint256 _amount);

    event InfluenceAwarded(address indexed _member, uint256 _amount, string _reason);
    event VoteWeightUpdated(address indexed _member, uint256 _newWeight);

    event ChallengeCreated(uint256 indexed _challengeId, string _title, uint256 _rewardInfluence, uint256 _deadline);
    event JoinedChallenge(uint256 indexed _challengeId, address indexed _participant);
    event ChallengeCompleted(uint256 indexed _challengeId, address indexed _completer, uint256 _totalInfluenceAwarded);

    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember(msg.sender), "Syndicate: Must be a member");
        _;
    }

    modifier whenProposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Pending, "Syndicate: Proposal is not pending");
        _;
    }

    modifier whenProposalVotingActive(uint256 _proposalId) {
        require(block.timestamp < proposals[_proposalId].votingDeadline, "Syndicate: Voting period has ended");
        _;
    }

    modifier whenProposalVotingEnded(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].votingDeadline, "Syndicate: Voting period is still active");
        _;
        require(proposals[_proposalId].state == ProposalState.Pending, "Syndicate: Proposal already executed");
    }

    modifier whenProjectInProgress(uint256 _projectId) {
        require(projects[_projectId].state == ProjectState.InProgress || projects[_projectId].state == ProjectState.Planning, "Syndicate: Project is not in progress or planning");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {} // Sets the initial owner

    // --- Management & Setup ---

    /// @notice Sets the address of the Genesis Stone ERC721 NFT contract.
    /// @dev Can only be called once by the owner.
    /// @param _nftAddress The address of the deployed Genesis Stone NFT contract.
    function setGenesisStoneNFT(address _nftAddress) public onlyOwner {
        require(address(genesisStoneNFT) == address(0), "Syndicate: NFT address already set");
        require(_nftAddress != address(0), "Syndicate: Invalid NFT address");
        genesisStoneNFT = IERC721(_nftAddress);
        emit GenesisStoneNFTSet(_nftAddress);
    }

    /// @notice Returns the address of the Genesis Stone NFT contract.
    function getGenesisStoneNFT() public view returns (address) {
        return address(genesisStoneNFT);
    }

    /// @notice Checks if an address is currently a member by holding a Genesis Stone NFT.
    /// @param _addr The address to check.
    /// @return True if the address holds a Genesis Stone NFT, false otherwise.
    function isMember(address _addr) public view returns (bool) {
        if (address(genesisStoneNFT) == address(0)) {
            return false; // NFT contract not set yet
        }
        return genesisStoneNFT.balanceOf(_addr) > 0;
    }

    // --- Treasury ---

    /// @notice Allows sending ETH to the Syndicate treasury.
    receive() external payable {
        depositTreasury();
    }

    /// @notice Allows sending ETH to the Syndicate treasury.
    /// @dev Any address can deposit.
    function depositTreasury() public payable nonReentrant {
        require(msg.value > 0, "Syndicate: Must send ETH");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice Returns the current ETH balance held in the treasury.
    /// @return The treasury balance in Wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows the owner to withdraw funds from the treasury.
    /// @dev This function is simplified; a real DAO would require governance approval for withdrawals.
    /// @param _to The address to send the ETH to.
    /// @param _amount The amount of ETH to withdraw in Wei.
    function withdrawTreasury(address _to, uint256 _amount) public onlyOwner nonReentrant {
        require(_amount > 0, "Syndicate: Amount must be greater than 0");
        require(address(this).balance >= _amount, "Syndicate: Insufficient treasury balance");
        require(_to != address(0), "Syndicate: Invalid recipient address");

        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Syndicate: ETH transfer failed");
        emit TreasuryWithdrawn(_to, _amount);
    }

    // --- Proposals & Voting ---

    /// @notice Allows a member to submit a new project proposal.
    /// @param _title The title of the proposal.
    /// @param _description A description of the proposed project.
    /// @param _amountRequested The amount of ETH requested from the treasury.
    /// @param _votingDeadline The timestamp when voting for this proposal ends. Must be in the future.
    function submitProposal(string calldata _title, string calldata _description, uint256 _amountRequested, uint256 _votingDeadline)
        public
        onlyMember
    {
        require(bytes(_title).length > 0, "Syndicate: Title cannot be empty");
        require(_amountRequested > 0, "Syndicate: Amount requested must be greater than 0");
        require(_votingDeadline > block.timestamp, "Syndicate: Voting deadline must be in the future");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            amountRequested: _amountRequested,
            votingDeadline: _votingDeadline,
            state: ProposalState.Pending,
            projectId: 0 // Will be set if approved and executed
        });

        emit ProposalSubmitted(proposalId, msg.sender, _amountRequested, _votingDeadline);
    }

    /// @notice Returns the details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The Proposal struct details.
    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        require(_proposalId < nextProposalId, "Syndicate: Invalid proposal ID");
        return proposals[_proposalId];
    }

    /// @notice Allows a member to vote on a pending proposal during the voting period.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for Yay, False for Nay.
    function voteOnProposal(uint256 _proposalId, bool _vote)
        public
        onlyMember
        whenProposalPending(_proposalId)
        whenProposalVotingActive(_proposalId)
    {
        require(!memberVotingRecord[_proposalId][msg.sender], "Syndicate: Already voted on this proposal");

        memberVotingRecord[_proposalId][msg.sender] = true;

        uint256 voterWeight = getMemberVoteWeight(msg.sender);

        if (_vote) {
            proposalYayVotes[_proposalId] += voterWeight;
        } else {
            proposalNayVotes[_proposalId] += voterWeight;
        }

        // Award base influence for simply participating in the vote
        uint256 baseVoteInfluence = 1;
        _awardInfluence(msg.sender, baseVoteInfluence, "Voted on proposal");

        emit VotedOnProposal(_proposalId, msg.sender, _vote, baseVoteInfluence);
    }

    /// @notice Calculates a member's current voting weight based on their Influence points.
    /// @dev Weight starts at 1 and increases based on Influence (e.g., 1 point = 0.01 weight increase).
    /// @param _member The address of the member.
    /// @return The voting weight as a scaled integer (e.g., 100 = 1x weight, 150 = 1.5x weight).
    function getMemberVoteWeight(address _member) public view returns (uint256) {
        // Base weight is 100 (representing 1x)
        // Add 1 weight point for every 10 Influence points
        // Max Influence could lead to overflow if not careful, but uint256 is large.
        // Let's simplify: 1 weight point for every 5 Influence points.
        // Base weight = 100 (for 1x)
        // Influence adds: memberInfluence / 5
        // Total weight = 100 + (memberInfluence / 5)
        // This ensures a minimum weight of 100 even with 0 influence.
        // When casting votes, we'll add `voterWeight` to the counts.
        // The effective ratio is proposalYayVotes / proposalNayVotes * (votingWeight scale)
        // To make it simpler to read ratios: base weight is 1, add 0.01 per influence point.
        // Scale by 100 for integer math: 100 + memberInfluence * 1
        // So 100 influence = 200 weight (2x). 0 influence = 100 weight (1x)
        return 100 + (memberInfluence[_member]); // Every 1 Influence point adds 1 weight point
    }

    /// @notice Executes a proposal after the voting deadline has passed.
    /// @dev Determines if the proposal is approved based on weighted votes (simple majority).
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        public
        nonReentrant
        whenProposalVotingEnded(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Pending, "Syndicate: Proposal already executed");

        uint256 yay = proposalYayVotes[_proposalId];
        uint256 nay = proposalNayVotes[_proposalId];
        uint256 totalVotes = yay + nay;

        // Determine Outcome (Simple majority of votes cast)
        bool approved = false;
        if (totalVotes > 0 && yay > nay) {
             // Optional: Add a quorum check, e.g., totalVotes must be > 10% of totalInfluence at deadline?
             // For simplicity, let's just use simple majority of votes cast.
            approved = true;
        }

        ProposalState finalState;
        if (approved) {
            // --- Funding and Project Creation ---
            require(address(this).balance >= proposal.amountRequested, "Syndicate: Insufficient treasury funds for proposal");

            // Transfer funds to proposer (who is assumed to lead the project)
            (bool success, ) = payable(proposal.proposer).call{value: proposal.amountRequested}("");
            require(success, "Syndicate: Funding transfer failed");

            // Create Project entry
            uint256 projectId = nextProjectId++;
            projects[projectId] = Project({
                id: projectId,
                proposalId: _proposalId,
                proposer: proposal.proposer,
                fundedAmount: proposal.amountRequested,
                milestones: new Milestone[](0), // Milestones added via separate function
                state: ProjectState.Planning,
                currentMilestoneIndex: 0
            });
            proposal.projectId = projectId;
            finalState = ProposalState.Approved; // Mark as Approved first, then Executed
            projects[projectId].state = ProjectState.InProgress; // Set project directly to InProgress upon funding
            emit ProjectFunded(projectId, _proposalId, proposal.amountRequested);

        } else {
            finalState = ProposalState.Rejected;
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, finalState);

        // Optional: Award additional influence to voters based on whether their vote aligned with the outcome?
        // Or just based on total votes cast? Let's skip outcome alignment for simplicity, base influence is enough.
    }

    /// @notice Returns the current Yay and Nay vote counts for a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return yayVotes The total weighted Yay votes.
    /// @return nayVotes The total weighted Nay votes.
    function getProposalVoteCounts(uint256 _proposalId) public view returns (uint256 yayVotes, uint256 nayVotes) {
        require(_proposalId < nextProposalId, "Syndicate: Invalid proposal ID");
        return (proposalYayVotes[_proposalId], proposalNayVotes[_proposalId]);
    }

    /// @notice Returns the current state of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The current state as a ProposalState enum.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
         require(_proposalId < nextProposalId, "Syndicate: Invalid proposal ID");
         return proposals[_proposalId].state;
    }


    // --- Projects ---

    /// @notice Returns the details of a specific project.
    /// @param _projectId The ID of the project.
    /// @return The Project struct details.
    function getProject(uint256 _projectId) public view returns (Project memory) {
        require(_projectId < nextProjectId, "Syndicate: Invalid project ID");
        return projects[_projectId];
    }

     /// @notice Allows the project proposer to add milestones to a project.
     /// @dev Can only be called when the project is in Planning or InProgress state.
     /// @param _projectId The ID of the project.
     /// @param _milestoneDescriptions An array of descriptions for the milestones.
     function addProjectMilestones(uint256 _projectId, string[] calldata _milestoneDescriptions) public onlyMember whenProjectInProgress(_projectId) {
         Project storage project = projects[_projectId];
         require(msg.sender == project.proposer, "Syndicate: Only project proposer can add milestones");

         for (uint i = 0; i < _milestoneDescriptions.length; i++) {
             project.milestones.push(Milestone({
                 description: _milestoneDescriptions[i],
                 completed: false
             }));
         }
     }

    /// @notice Allows the project proposer (or potentially future designated role) to report a milestone as completed.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone in the project's milestones array.
    function reportProjectMilestoneCompleted(uint256 _projectId, uint256 _milestoneIndex)
        public
        onlyMember
        whenProjectInProgress(_projectId)
    {
        Project storage project = projects[_projectId];
        require(msg.sender == project.proposer, "Syndicate: Only project proposer can report milestones");
        require(_milestoneIndex < project.milestones.length, "Syndicate: Invalid milestone index");
        require(!project.milestones[_milestoneIndex].completed, "Syndicate: Milestone already reported as completed");
        require(_milestoneIndex == project.currentMilestoneIndex, "Syndicate: Milestones must be reported in order");

        project.milestones[_milestoneIndex].completed = true;
        project.currentMilestoneIndex++;

        // Award influence for completing a milestone
        // Influence calculation could be more complex (e.g., based on funded amount, milestone importance)
        // For simplicity, let's award a fixed amount or a percentage of funded amount per milestone
        uint256 milestoneInfluence = project.fundedAmount / project.milestones.length / 1 ether; // Award 1 Influence point per ETH funded per milestone (simplified)
        milestoneInfluence = milestoneInfluence > 0 ? milestoneInfluence : 1; // Ensure at least 1 influence
        _awardInfluence(msg.sender, milestoneInfluence, string(abi.encodePacked("Completed milestone for project ", uint256ToString(_projectId))));

        // Check if all milestones are completed
        if (project.currentMilestoneIndex == project.milestones.length) {
             project.state = ProjectState.Completed;
        }

        emit MilestoneReported(_projectId, _milestoneIndex, msg.sender, milestoneInfluence);
    }

    /// @notice Returns the completion status of a specific milestone for a project.
    /// @param _projectId The ID of the project.
    /// @param _milestoneIndex The index of the milestone.
    /// @return True if the milestone is completed, false otherwise.
    function getProjectMilestoneStatus(uint256 _projectId, uint256 _milestoneIndex) public view returns (bool) {
         require(_projectId < nextProjectId, "Syndicate: Invalid project ID");
         Project memory project = projects[_projectId];
         require(_milestoneIndex < project.milestones.length, "Syndicate: Invalid milestone index");
         return project.milestones[_milestoneIndex].completed;
    }

     /// @notice Returns the total number of milestones defined for a project.
     /// @param _projectId The ID of the project.
     /// @return The total number of milestones.
    function getProjectMilestoneCount(uint256 _projectId) public view returns (uint256) {
        require(_projectId < nextProjectId, "Syndicate: Invalid project ID");
        return projects[_projectId].milestones.length;
    }


    /// @notice Allows the owner/governance to cancel a project.
    /// @dev Remaining funds associated with the project (if traceable or assumed to be held by proposer) would ideally be returned.
    /// This simple version just marks the project cancelled. A more complex version would claw back funds.
    /// @param _projectId The ID of the project to cancel.
    function cancelProject(uint256 _projectId) public onlyOwner {
        Project storage project = projects[_projectId];
        require(_projectId < nextProjectId, "Syndicate: Invalid project ID");
        require(project.state != ProjectState.Cancelled && project.state != ProjectState.Completed, "Syndicate: Project is already cancelled or completed");

        project.state = ProjectState.Cancelled;
        // In a real system, remaining funds held by the proposer might be returned or clawed back via governance.
        // For this example, we assume funds are with the proposer and they *might* return them voluntarily via returnUnusedProjectFunds.

        emit ProjectCancelled(_projectId);
    }

    /// @notice Allows the project proposer to return unused funds from the project to the treasury.
    /// @param _projectId The ID of the project.
    function returnUnusedProjectFunds(uint256 _projectId) public payable nonReentrant {
        Project storage project = projects[_projectId];
        require(_projectId < nextProjectId, "Syndicate: Invalid project ID");
        require(msg.sender == project.proposer, "Syndicate: Only project proposer can return funds");
        require(msg.value > 0, "Syndicate: Must send ETH to return");

        emit ProjectFundsReturned(_projectId, msg.value);
    }


    // --- Influence & Reputation ---

    /// @notice Returns the current Influence points of a member.
    /// @param _member The address of the member.
    /// @return The total Influence points for the member.
    function getMemberInfluence(address _member) public view returns (uint256) {
        return memberInfluence[_member];
    }

    /// @notice Returns the total cumulative Influence points across all members.
    /// @return The total influence points.
    function getTotalInfluence() public view returns (uint256) {
        return totalInfluence;
    }

    /// @dev Internal function to award Influence points to a member.
    /// @param _member The address to award influence to.
    /// @param _amount The amount of influence to award.
    /// @param _reason A string describing why influence was awarded.
    function _awardInfluence(address _member, uint256 _amount, string memory _reason) internal {
        require(_member != address(0), "Syndicate: Cannot award influence to zero address");
        if (_amount == 0) return; // No influence to award

        memberInfluence[_member] += _amount;
        totalInfluence += _amount;

        // Vote weight is recalculated on the fly in getMemberVoteWeight, no storage update needed here.

        emit InfluenceAwarded(_member, _amount, _reason);
    }

    // --- Challenges ---

    /// @notice Allows the owner to create a new Syndicate Challenge.
    /// @param _title The title of the challenge.
    /// @param _description A description of the challenge.
    /// @param _rewardInfluence The total amount of Influence points to distribute among participants upon completion.
    /// @param _deadline The timestamp when the challenge ends. Must be in the future.
    function createChallenge(string calldata _title, string calldata _description, uint256 _rewardInfluence, uint256 _deadline)
        public
        onlyOwner
    {
        require(bytes(_title).length > 0, "Syndicate: Title cannot be empty");
        require(_rewardInfluence > 0, "Syndicate: Reward influence must be greater than 0");
        require(_deadline > block.timestamp, "Syndicate: Challenge deadline must be in the future");

        uint256 challengeId = nextChallengeId++;
        Challenge storage newChallenge = challenges[challengeId];
        newChallenge.id = challengeId;
        newChallenge.title = _title;
        newChallenge.description = _description;
        newChallenge.rewardInfluence = _rewardInfluence;
        newChallenge.deadline = _deadline;
        newChallenge.state = ChallengeState.Active;
        // participants mapping and participantList array initialized empty by default

        emit ChallengeCreated(challengeId, _title, _rewardInfluence, _deadline);
    }

    /// @notice Allows a member to join an active challenge.
    /// @param _challengeId The ID of the challenge to join.
    function joinChallenge(uint256 _challengeId) public onlyMember {
        Challenge storage challenge = challenges[_challengeId];
        require(_challengeId < nextChallengeId, "Syndicate: Invalid challenge ID");
        require(challenge.state == ChallengeState.Active, "Syndicate: Challenge is not active");
        require(block.timestamp <= challenge.deadline, "Syndicate: Challenge join period has ended");
        require(!challenge.participants[msg.sender], "Syndicate: Already joined this challenge");

        challenge.participants[msg.sender] = true;
        challenge.participantList.push(msg.sender); // Add to list for easy iteration
        emit JoinedChallenge(_challengeId, msg.sender);
    }

    /// @notice Allows the owner to mark a challenge as completed and distribute reward Influence to participants.
    /// @param _challengeId The ID of the challenge to complete.
    function completeChallenge(uint256 _challengeId) public onlyOwner nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(_challengeId < nextChallengeId, "Syndicate: Invalid challenge ID");
        require(challenge.state == ChallengeState.Active, "Syndicate: Challenge is not active");

        challenge.state = ChallengeState.Completed;

        uint256 totalParticipants = challenge.participantList.length;
        if (totalParticipants > 0) {
            uint256 influencePerParticipant = challenge.rewardInfluence / totalParticipants;
            if (influencePerParticipant > 0) {
                 for (uint i = 0; i < totalParticipants; i++) {
                    address participant = challenge.participantList[i];
                    // Double check they are still members if desired, but awarding is fine even if they left later.
                    _awardInfluence(participant, influencePerParticipant, string(abi.encodePacked("Participated in challenge ", uint256ToString(_challengeId))));
                 }
            }
            // Any remainder influence stays unassigned or could be awarded to owner/treasury
        }

        emit ChallengeCompleted(_challengeId, msg.sender, challenge.rewardInfluence);
    }

    /// @notice Returns the details of a specific challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return The Challenge struct details (excluding the participants mapping).
    function getChallenge(uint256 _challengeId) public view returns (uint256 id, string memory title, string memory description, uint256 rewardInfluence, uint256 deadline, ChallengeState state, address[] memory participantList) {
        require(_challengeId < nextChallengeId, "Syndicate: Invalid challenge ID");
        Challenge storage challenge = challenges[_challengeId];
        return (challenge.id, challenge.title, challenge.description, challenge.rewardInfluence, challenge.deadline, challenge.state, challenge.participantList);
    }

     /// @notice Checks if a specific member has joined a specific challenge.
     /// @param _challengeId The ID of the challenge.
     /// @param _member The address of the member.
     /// @return True if the member has joined the challenge, false otherwise.
    function hasJoinedChallenge(uint256 _challengeId, address _member) public view returns (bool) {
        require(_challengeId < nextChallengeId, "Syndicate: Invalid challenge ID");
        // No require on member existence here, just check the mapping.
        return challenges[_challengeId].participants[_member];
    }


    // --- Utility/View Functions ---

    /// @notice Returns key metrics and summary information about the Syndicate.
    /// @return treasuryBalance The current balance of the treasury.
    /// @return totalMembers The estimated total number of members (based on total influence awarded divided by minimum influence unit - estimation). Or better: use NFT contract balance. Let's use NFT balance.
    /// @return totalProposals The total number of proposals ever submitted.
    /// @return totalProjects The total number of projects ever funded.
    /// @return totalChallenges The total number of challenges ever created.
    /// @return cumulativeInfluence The total cumulative influence awarded.
    function getSyndicateMetrics() public view returns (uint256 treasuryBalance, uint256 totalMembers, uint256 totalProposals, uint256 totalProjects, uint256 totalChallenges, uint256 cumulativeInfluence) {
        uint256 memberCount = 0;
        if (address(genesisStoneNFT) != address(0)) {
            // Note: genesisStoneNFT.totalSupply() would be better if available and accurate,
            // but balanceOf(address(this)) might represent NFTs held by the contract itself,
            // or we'd need a different way to track unique members if not using balance.
            // Assuming NFT balance of THIS contract isn't membership.
            // A true member count would require iterating or a separate mechanism like a registry.
            // Let's return 0 or use total supply if available on the NFT contract.
            // If IERC721 had totalSupply: memberCount = genesisStoneNFT.totalSupply();
            // For this example, we'll just return 0 or a placeholder.
        }

        return (
            address(this).balance,
            memberCount, // Placeholder or requires external logic/NFT totalSupply()
            nextProposalId,
            nextProjectId,
            nextChallengeId,
            totalInfluence
        );
    }

    // Simple utility to convert uint256 to string for event logging/reasons
    // Found in many examples, e.g., OpenZeppelin
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}
```

**Explanation of Advanced/Creative Concepts and Functions:**

1.  **NFT Gating (`isMember`, `onlyMember`, `genesisStoneNFT` state variable, `setGenesisStoneNFT`)**: Membership isn't just an address in a mapping; it's tied to holding a specific ERC721 token. This enables integration with NFT marketplaces, provenance tracking of membership, and potential future features based on NFT attributes. `isMember` view function provides the check, and `onlyMember` modifier enforces it on relevant functions.
2.  **Custom Non-Transferable Token (Influence Points):** Modeled by the `memberInfluence` mapping and `totalInfluence` variable. This is a form of a Soulbound Token (SBT) concept where the points represent non-transferable reputation or contribution within the Syndicate ecosystem. `getMemberInfluence` and `getTotalInfluence` provide visibility, and the internal `_awardInfluence` function is the sole way points are created.
3.  **Dynamic Voting Weight (`getMemberVoteWeight`, `voteOnProposal` logic):** Voting power is not fixed (like 1 token = 1 vote or 1 address = 1 vote). It scales based on a member's accumulated Influence points. This incentivizes long-term contribution and participation to gain more voting power.
4.  **State Machines (`ProposalState`, `ProjectState`, `ChallengeState` enums and struct fields, corresponding modifiers like `whenProposalPending`, `whenProjectInProgress`):** Tracks the lifecycle of key entities (Proposals, Projects, Challenges). This prevents invalid actions (e.g., voting on an executed proposal, completing a milestone on a cancelled project) and structures the process flow. `getProposalState` provides visibility into a proposal's status.
5.  **Internal Treasury Management (`depositTreasury`, `getTreasuryBalance`, `withdrawTreasury`, `returnUnusedProjectFunds`, `payable` receive function):** The contract itself holds ETH, acting as a decentralized treasury. Funds are explicitly sent in (`depositTreasury`, `receive`) and can only be withdrawn for specific purposes (`executeProposal` funding, `withdrawTreasury` by owner - simplified, `returnUnusedProjectFunds`). `ReentrancyGuard` is used on withdrawal/deposits for basic security.
6.  **Decentralized Project Management (`projects` mapping, `Project` struct, `addProjectMilestones`, `reportProjectMilestoneCompleted`, `getProjectMilestoneStatus`, `getProjectMilestoneCount`, `cancelProject`):** The Syndicate funds internal projects proposed by members. The contract tracks these projects, their funded amount, and allows project leads to report milestone completion, which is tied to the Influence system. While basic, it's an on-chain record of funded initiatives and progress.
7.  **Gamification/Incentives (Challenges):** The `challenges` mapping, `Challenge` struct, and related functions (`createChallenge`, `joinChallenge`, `completeChallenge`, `getChallenge`, `hasJoinedChallenge`) introduce a distinct mechanism for structured activities that reward participation with Influence points. This encourages engagement beyond standard proposals and voting.
8.  **Multiple Contribution Streams for Influence:** Influence points are earned through various actions: voting on proposals (`voteOnProposal`), completing project milestones (`reportProjectMilestoneCompleted`), and participating in challenges (`completeChallenge`). This creates a multi-faceted contribution system.
9.  **Comprehensive Metrics (`getSyndicateMetrics`):** Provides a single view function to get a snapshot of the Syndicate's activity and resources (treasury, counts of proposals/projects/challenges, total influence). Note the member count is a placeholder as direct iteration over all members isn't feasible on-chain, relying on external tools or the NFT contract's `totalSupply` if available.
10. **Clear Event Logging:** Numerous events are emitted for key state changes and actions (submission, voting, funding, completing milestones, awarding influence, creating/joining/completing challenges). This provides transparency and allows off-chain applications to easily track activity.

This contract provides a framework for a dynamic, contribution-driven decentralized creative organization, combining elements of DAOs, NFTs, and custom incentive systems in a single, albeit simplified, contract. It meets the requirement of having over 20 functions covering diverse aspects of such an organization.