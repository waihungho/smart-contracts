```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI (Example - Inspired by user request)
 * @dev A smart contract for a decentralized autonomous art collective.
 *      This contract enables artists to submit their digital art (represented as URIs),
 *      community members to curate and vote on art pieces, manage a collective treasury,
 *      distribute royalties, and participate in various community-driven activities like
 *      art challenges, collaborative pieces, and decentralized exhibitions.
 *
 * Function Summary:
 * -----------------
 * Core Art Submission & Curation:
 * 1. submitArtProposal(string _artURI, string _metadataURI): Allows artists to submit art proposals.
 * 2. voteOnArtProposal(uint _proposalId, bool _vote): Members vote on submitted art proposals.
 * 3. finalizeArtProposal(uint _proposalId):  Admin finalizes a passed proposal, minting an NFT.
 * 4. rejectArtProposal(uint _proposalId): Admin rejects a proposal that failed voting.
 * 5. getArtProposalDetails(uint _proposalId): View details of a specific art proposal.
 * 6. getApprovedArtCount(): View the total number of approved art pieces in the collective.
 * 7. getArtPieceURI(uint _artId): View the URI of a specific approved art piece.
 * 8. getArtPieceMetadataURI(uint _artId): View the metadata URI of a specific approved art piece.
 *
 * Collective Governance & Membership:
 * 9. joinCollective(): Allows users to join the art collective (potentially with token gating).
 * 10. leaveCollective(): Allows members to leave the collective.
 * 11. proposeCollectiveRuleChange(string _description, bytes _data): Members propose changes to collective rules.
 * 12. voteOnRuleChange(uint _ruleChangeId, bool _vote): Members vote on rule change proposals.
 * 13. finalizeRuleChange(uint _ruleChangeId): Admin finalizes a passed rule change proposal.
 * 14. getCollectiveMemberCount(): View the current number of members in the collective.
 * 15. isCollectiveMember(address _account): Check if an address is a member of the collective.
 *
 * Treasury & Royalties:
 * 16. depositToTreasury() payable: Members or others can deposit ETH into the collective treasury.
 * 17. withdrawFromTreasury(address _recipient, uint _amount): Admin can withdraw funds from the treasury for collective purposes.
 * 18. setArtRoyalty(uint _artId, uint _royaltyPercentage): Admin sets the royalty percentage for an art piece.
 * 19. distributeRoyalties(uint _artId):  Distributes accumulated royalties for an art piece to artists and collective.
 * 20. getTreasuryBalance(): View the current balance of the collective treasury.
 *
 * Advanced/Creative Functions:
 * 21. createArtChallenge(string _challengeName, string _description, uint _submissionDeadline): Admin creates an art challenge for members.
 * 22. submitArtForChallenge(uint _challengeId, string _artURI, string _metadataURI): Members submit art for a specific challenge.
 * 23. voteOnChallengeSubmission(uint _challengeId, uint _submissionId, bool _vote): Members vote on submissions for a challenge.
 * 24. finalizeArtChallenge(uint _challengeId): Admin finalizes a challenge, selecting winners based on votes.
 * 25. createCollaborativeArtProject(string _projectName, string _description, uint _maxCollaborators): Admin starts a collaborative art project.
 * 26. joinCollaborativeProject(uint _projectId): Members can join a collaborative art project.
 * 27. proposeContributionToProject(uint _projectId, string _contributionDescription, string _contributionURI): Members propose contributions to a project.
 * 28. voteOnProjectContribution(uint _projectId, uint _contributionId, bool _vote): Members vote on project contributions.
 * 29. finalizeCollaborativeProject(uint _projectId): Admin finalizes a project after contributions are selected.
 * 30. initiateDecentralizedExhibition(string _exhibitionName, uint[] _artIds, uint _startDate, uint _endDate): Admin initiates a decentralized exhibition of selected art pieces.
 */

contract DecentralizedArtCollective {

    // --- State Variables ---
    address public admin; // Admin address with privileged functions
    uint public proposalCounter; // Counter for art proposals
    uint public ruleChangeCounter; // Counter for rule change proposals
    uint public artPieceCounter; // Counter for approved art pieces
    uint public memberCounter; // Counter for collective members
    uint public challengeCounter; // Counter for art challenges
    uint public collaborativeProjectCounter; // Counter for collaborative projects

    mapping(uint => ArtProposal) public artProposals; // Mapping of proposal IDs to ArtProposal structs
    mapping(uint => RuleChangeProposal) public ruleChangeProposals; // Mapping of rule change proposal IDs to RuleChangeProposal structs
    mapping(uint => ArtPiece) public approvedArtPieces; // Mapping of art piece IDs to ArtPiece structs
    mapping(address => bool) public collectiveMembers; // Mapping of addresses to membership status
    mapping(uint => ArtChallenge) public artChallenges; // Mapping of challenge IDs to ArtChallenge structs
    mapping(uint => CollaborativeArtProject) public collaborativeArtProjects; // Mapping of project IDs to CollaborativeArtProject structs

    uint public artProposalVoteQuorumPercentage = 50; // Percentage of members needed to vote for quorum in art proposals
    uint public ruleChangeVoteQuorumPercentage = 60; // Percentage of members needed to vote for quorum in rule change proposals
    uint public voteDurationDays = 7; // Default duration for voting periods in days
    uint public collectiveRoyaltyPercentage = 10; // Default percentage of royalties to go to the collective
    uint public artRoyaltyPercentage = 80; // Default percentage of royalties to go to the artist (remaining goes to collective if not set per art)

    event ArtProposalSubmitted(uint proposalId, address artist, string artURI, string metadataURI);
    event ArtProposalVoted(uint proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint proposalId, uint artId, string artURI, string metadataURI);
    event ArtProposalRejected(uint proposalId);
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);
    event RuleChangeProposed(uint ruleChangeId, address proposer, string description);
    event RuleChangeVoted(uint ruleChangeId, address voter, bool vote);
    event RuleChangeFinalized(uint ruleChangeId);
    event TreasuryDeposit(address sender, uint amount);
    event TreasuryWithdrawal(address recipient, uint amount);
    event ArtRoyaltySet(uint artId, uint royaltyPercentage);
    event RoyaltyDistributed(uint artId, uint artistRoyalty, uint collectiveRoyalty);
    event ArtChallengeCreated(uint challengeId, string challengeName, string description, uint submissionDeadline);
    event ArtSubmittedForChallenge(uint challengeId, uint submissionId, address submitter, string artURI, string metadataURI);
    event ChallengeSubmissionVoted(uint challengeId, uint submissionId, address voter, bool vote);
    event ArtChallengeFinalized(uint challengeId, uint[] winnerSubmissionIds);
    event CollaborativeProjectCreated(uint projectId, string projectName, string description, uint maxCollaborators);
    event CollaborativeProjectJoined(uint projectId, address member);
    event ContributionProposedToProject(uint projectId, uint contributionId, address contributor, string description, string contributionURI);
    event ProjectContributionVoted(uint projectId, uint contributionId, address voter, bool vote);
    event CollaborativeProjectFinalized(uint projectId, uint[] selectedContributionIds);
    event DecentralizedExhibitionInitiated(uint exhibitionName, uint[] artIds, uint startDate, uint endDate);


    // --- Structs ---
    struct ArtProposal {
        uint proposalId;
        address artist;
        string artURI;
        string metadataURI;
        uint voteStartTime;
        uint voteEndTime;
        mapping(address => bool) votes; // True for yes, false for no, not voted == not in mapping
        uint yesVotes;
        uint noVotes;
        bool finalized;
        bool approved; // True if proposal is approved by voting and finalized
    }

    struct RuleChangeProposal {
        uint ruleChangeId;
        address proposer;
        string description;
        bytes data; // To store specific data related to the rule change (e.g., new quorum percentage)
        uint voteStartTime;
        uint voteEndTime;
        mapping(address => bool) votes; // True for yes, false for no, not voted == not in mapping
        uint yesVotes;
        uint noVotes;
        bool finalized;
        bool approved;
    }

    struct ArtPiece {
        uint artId;
        address artist;
        string artURI;
        string metadataURI;
        uint royaltyPercentage; // Percentage for artist, if not set, default artRoyaltyPercentage is used
        uint accumulatedRoyalties; // Example - simplified royalty tracking
    }

    struct ArtChallenge {
        uint challengeId;
        string challengeName;
        string description;
        uint submissionDeadline;
        uint submissionCounter;
        mapping(uint => ChallengeSubmission) submissions;
        bool finalized;
    }

    struct ChallengeSubmission {
        uint submissionId;
        address submitter;
        string artURI;
        string metadataURI;
        mapping(address => bool) votes; // True for yes, false for no
        uint yesVotes;
        uint noVotes;
    }

    struct CollaborativeArtProject {
        uint projectId;
        string projectName;
        string description;
        uint maxCollaborators;
        address[] collaborators;
        uint contributionCounter;
        mapping(uint => ProjectContribution) contributions;
        bool finalized;
    }

    struct ProjectContribution {
        uint contributionId;
        address contributor;
        string description;
        string contributionURI;
        mapping(address => bool) votes; // True for yes, false for no
        uint yesVotes;
        uint noVotes;
    }


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyCollectiveMembers() {
        require(collectiveMembers[msg.sender], "Only collective members can call this function.");
        _;
    }

    modifier proposalExists(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && artProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier ruleChangeProposalExists(uint _ruleChangeId) {
        require(_ruleChangeId > 0 && _ruleChangeId <= ruleChangeCounter && ruleChangeProposals[_ruleChangeId].ruleChangeId == _ruleChangeId, "Rule change proposal does not exist.");
        _;
    }

    modifier challengeExists(uint _challengeId) {
        require(_challengeId > 0 && _challengeId <= challengeCounter && artChallenges[_challengeId].challengeId == _challengeId, "Art challenge does not exist.");
        _;
    }

    modifier collaborativeProjectExists(uint _projectId) {
        require(_projectId > 0 && _projectId <= collaborativeProjectCounter && collaborativeArtProjects[_projectId].projectId == _projectId, "Collaborative project does not exist.");
        _;
    }

    modifier submissionExistsInChallenge(uint _challengeId, uint _submissionId) {
        require(artChallenges[_challengeId].submissions[_submissionId].submissionId == _submissionId, "Submission does not exist in this challenge.");
        _;
    }

    modifier contributionExistsInProject(uint _projectId, uint _contributionId) {
        require(collaborativeArtProjects[_projectId].contributions[_contributionId].contributionId == _contributionId, "Contribution does not exist in this project.");
        _;
    }

    modifier votingNotStarted(uint _proposalId) {
        require(artProposals[_proposalId].voteStartTime == 0, "Voting has already started.");
        _;
    }

    modifier votingNotEnded(uint _proposalId) {
        require(block.timestamp < artProposals[_proposalId].voteEndTime, "Voting has already ended.");
        _;
    }

    modifier ruleChangeVotingNotStarted(uint _ruleChangeId) {
        require(ruleChangeProposals[_ruleChangeId].voteStartTime == 0, "Voting has already started.");
        _;
    }

    modifier ruleChangeVotingNotEnded(uint _ruleChangeId) {
        require(block.timestamp < ruleChangeProposals[_ruleChangeId].voteEndTime, "Voting has already ended.");
        _;
    }

    modifier challengeVotingNotFinalized(uint _challengeId) {
        require(!artChallenges[_challengeId].finalized, "Challenge is already finalized.");
        _;
    }

    modifier collaborativeProjectNotFinalized(uint _projectId) {
        require(!collaborativeArtProjects[_projectId].finalized, "Collaborative project is already finalized.");
        _;
    }

    modifier submissionVotingNotFinalized(uint _challengeId, uint _submissionId) {
        require(!artChallenges[_challengeId].submissions[_submissionId].finalized, "Submission voting is already finalized."); // Assuming finalization logic if needed
        _;
    }

    modifier contributionVotingNotFinalized(uint _projectId, uint _contributionId) {
        require(!collaborativeArtProjects[_projectId].contributions[_contributionId].finalized, "Contribution voting is already finalized."); // Assuming finalization logic if needed
        _;
    }

    modifier notAlreadyVotedOnProposal(uint _proposalId) {
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier notAlreadyVotedOnRuleChange(uint _ruleChangeId) {
        require(!ruleChangeProposals[_ruleChangeId].votes[msg.sender], "Already voted on this rule change.");
        _;
    }

    modifier notAlreadyVotedOnSubmission(uint _challengeId, uint _submissionId) {
        require(!artChallenges[_challengeId].submissions[_submissionId].votes[msg.sender], "Already voted on this submission.");
        _;
    }

    modifier notAlreadyVotedOnContribution(uint _projectId, uint _contributionId) {
        require(!collaborativeArtProjects[_projectId].contributions[_contributionId].votes[msg.sender], "Already voted on this contribution.");
        _;
    }

    modifier isChallengeSubmissionDeadlineValid(uint _submissionDeadline) {
        require(_submissionDeadline > block.timestamp, "Submission deadline must be in the future.");
        _;
    }

    modifier isSubmissionDeadlineNotExpired(uint _challengeId) {
        require(block.timestamp < artChallenges[_challengeId].submissionDeadline, "Submission deadline has expired.");
        _;
    }

    modifier isCollaborativeProjectJoinable(uint _projectId) {
        require(collaborativeArtProjects[_projectId].collaborators.length < collaborativeArtProjects[_projectId].maxCollaborators, "Collaborative project is full.");
        _;
    }

    modifier isCollaborativeProjectMember(uint _projectId) {
        bool isMember = false;
        for (uint i = 0; i < collaborativeArtProjects[_projectId].collaborators.length; i++) {
            if (collaborativeArtProjects[_projectId].collaborators[i] == msg.sender) {
                isMember = true;
                break;
            }
        }
        require(isMember, "You are not a member of this collaborative project.");
        _;
    }


    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        memberCounter = 0; // Initialize member count to 0
    }


    // --- Core Art Submission & Curation Functions ---

    /// @notice Allows artists to submit art proposals to the collective.
    /// @param _artURI URI pointing to the digital art piece.
    /// @param _metadataURI URI pointing to the metadata of the art piece.
    function submitArtProposal(string memory _artURI, string memory _metadataURI) external onlyCollectiveMembers {
        proposalCounter++;
        artProposals[proposalCounter] = ArtProposal({
            proposalId: proposalCounter,
            artist: msg.sender,
            artURI: _artURI,
            metadataURI: _metadataURI,
            voteStartTime: 0,
            voteEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit ArtProposalSubmitted(proposalCounter, msg.sender, _artURI, _metadataURI);
    }

    /// @notice Allows collective members to vote on an art proposal.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote True for approve, False for reject.
    function voteOnArtProposal(uint _proposalId, bool _vote) external onlyCollectiveMembers proposalExists(_proposalId) votingNotStarted(_proposalId) notAlreadyVotedOnProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        proposal.votes[msg.sender] = _vote;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Automatically start voting period upon first vote if not started yet.
        if (proposal.voteStartTime == 0) {
            proposal.voteStartTime = block.timestamp;
            proposal.voteEndTime = block.timestamp + voteDurationDays * 1 days; // Set vote end time
        }
    }

    /// @notice Finalizes an art proposal after voting period, minting an NFT if approved. Admin only.
    /// @param _proposalId ID of the art proposal to finalize.
    function finalizeArtProposal(uint _proposalId) external onlyAdmin proposalExists(_proposalId) votingNotEnded(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized.");

        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        uint quorum = (memberCounter * artProposalVoteQuorumPercentage) / 100; // Calculate quorum based on current members

        if (totalVotes >= quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.approved = true;
            artPieceCounter++;
            approvedArtPieces[artPieceCounter] = ArtPiece({
                artId: artPieceCounter,
                artist: proposal.artist,
                artURI: proposal.artURI,
                metadataURI: proposal.metadataURI,
                royaltyPercentage: 0, // Default royalty, can be set later
                accumulatedRoyalties: 0
            });
            emit ArtProposalFinalized(_proposalId, artPieceCounter, proposal.artURI, proposal.metadataURI);
        } else {
            proposal.approved = false;
            emit ArtProposalRejected(_proposalId);
        }
        proposal.finalized = true;
    }

    /// @notice Rejects an art proposal that failed voting. Admin only.
    /// @param _proposalId ID of the art proposal to reject.
    function rejectArtProposal(uint _proposalId) external onlyAdmin proposalExists(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized.");
        proposal.approved = false;
        proposal.finalized = true;
        emit ArtProposalRejected(_proposalId);
    }

    /// @notice Get details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint _proposalId) external view proposalExists(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Get the total count of approved art pieces in the collective.
    /// @return uint Total number of approved art pieces.
    function getApprovedArtCount() external view returns (uint) {
        return artPieceCounter;
    }

    /// @notice Get the URI of a specific approved art piece.
    /// @param _artId ID of the art piece.
    /// @return string URI of the art piece.
    function getArtPieceURI(uint _artId) external view returns (string memory) {
        require(_artId > 0 && _artId <= artPieceCounter, "Art piece ID invalid.");
        return approvedArtPieces[_artId].artURI;
    }

    /// @notice Get the metadata URI of a specific approved art piece.
    /// @param _artId ID of the art piece.
    /// @return string Metadata URI of the art piece.
    function getArtPieceMetadataURI(uint _artId) external view returns (string memory) {
        require(_artId > 0 && _artId <= artPieceCounter, "Art piece ID invalid.");
        return approvedArtPieces[_artId].metadataURI;
    }


    // --- Collective Governance & Membership Functions ---

    /// @notice Allows users to join the art collective.
    function joinCollective() external {
        if (!collectiveMembers[msg.sender]) {
            collectiveMembers[msg.sender] = true;
            memberCounter++;
            emit CollectiveMemberJoined(msg.sender);
        } else {
            revert("Already a member of the collective.");
        }
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() external onlyCollectiveMembers {
        if (collectiveMembers[msg.sender]) {
            collectiveMembers[msg.sender] = false;
            memberCounter--;
            emit CollectiveMemberLeft(msg.sender);
        } else {
            revert("Not a member of the collective.");
        }
    }

    /// @notice Allows members to propose changes to collective rules.
    /// @param _description Description of the rule change proposal.
    /// @param _data  Data related to the rule change, can be encoded parameters (e.g., new quorum).
    function proposeCollectiveRuleChange(string memory _description, bytes memory _data) external onlyCollectiveMembers {
        ruleChangeCounter++;
        ruleChangeProposals[ruleChangeCounter] = RuleChangeProposal({
            ruleChangeId: ruleChangeCounter,
            proposer: msg.sender,
            description: _description,
            data: _data,
            voteStartTime: 0,
            voteEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        });
        emit RuleChangeProposed(ruleChangeCounter, msg.sender, _description);
    }

    /// @notice Allows collective members to vote on a rule change proposal.
    /// @param _ruleChangeId ID of the rule change proposal to vote on.
    /// @param _vote True for approve, False for reject.
    function voteOnRuleChange(uint _ruleChangeId, bool _vote) external onlyCollectiveMembers ruleChangeProposalExists(_ruleChangeId) ruleChangeVotingNotStarted(_ruleChangeId) notAlreadyVotedOnRuleChange(_ruleChangeId) {
        RuleChangeProposal storage proposal = ruleChangeProposals[_ruleChangeId];
        proposal.votes[msg.sender] = _vote;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit RuleChangeVoted(_ruleChangeId, msg.sender, _vote);

        // Automatically start voting period upon first vote if not started yet.
        if (proposal.voteStartTime == 0) {
            proposal.voteStartTime = block.timestamp;
            proposal.voteEndTime = block.timestamp + voteDurationDays * 1 days; // Set vote end time
        }
    }

    /// @notice Finalizes a rule change proposal after voting period. Admin only.
    /// @param _ruleChangeId ID of the rule change proposal to finalize.
    function finalizeRuleChange(uint _ruleChangeId) external onlyAdmin ruleChangeProposalExists(_ruleChangeId) ruleChangeVotingNotEnded(_ruleChangeId) {
        RuleChangeProposal storage proposal = ruleChangeProposals[_ruleChangeId];
        require(!proposal.finalized, "Rule change proposal already finalized.");

        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        uint quorum = (memberCounter * ruleChangeVoteQuorumPercentage) / 100; // Rule change quorum might be different

        if (totalVotes >= quorum && proposal.yesVotes > proposal.noVotes) {
            proposal.approved = true;
            // Implement rule change logic based on proposal.data here if needed.
            // For example, if data contains new quorum percentage:
            // (Unpack data and update state variable if applicable)
            emit RuleChangeFinalized(_ruleChangeId);
        } else {
            proposal.approved = false;
            emit RuleChangeFinalized(_ruleChangeId); // Even if not approved, proposal is finalized.
        }
        proposal.finalized = true;
    }

    /// @notice Get the current number of members in the collective.
    /// @return uint Current member count.
    function getCollectiveMemberCount() external view returns (uint) {
        return memberCounter;
    }

    /// @notice Check if an address is a member of the collective.
    /// @param _account Address to check.
    /// @return bool True if member, false otherwise.
    function isCollectiveMember(address _account) external view returns (bool) {
        return collectiveMembers[_account];
    }


    // --- Treasury & Royalties Functions ---

    /// @notice Allows members or anyone to deposit ETH into the collective treasury.
    function depositToTreasury() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows admin to withdraw funds from the treasury for collective purposes. Admin only.
    /// @param _recipient Address to send the funds to.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawFromTreasury(address _recipient, uint _amount) external onlyAdmin {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Allows admin to set the royalty percentage for a specific art piece. Admin only.
    /// @param _artId ID of the art piece.
    /// @param _royaltyPercentage Royalty percentage (out of 100).
    function setArtRoyalty(uint _artId, uint _royaltyPercentage) external onlyAdmin {
        require(_artId > 0 && _artId <= artPieceCounter, "Art piece ID invalid.");
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100.");
        approvedArtPieces[_artId].royaltyPercentage = _royaltyPercentage;
        emit ArtRoyaltySet(_artId, _royaltyPercentage);
    }

    /// @notice Distributes accumulated royalties for an art piece to artists and collective. (Simplified example)
    /// @param _artId ID of the art piece.
    function distributeRoyalties(uint _artId) external onlyAdmin {
        require(_artId > 0 && _artId <= artPieceCounter, "Art piece ID invalid.");
        ArtPiece storage art = approvedArtPieces[_artId];
        uint totalRoyalties = art.accumulatedRoyalties; // Simplified - In real use case, tracking sales & royalties would be more complex.
        uint artistSharePercentage = (art.royaltyPercentage > 0) ? art.royaltyPercentage : artRoyaltyPercentage;
        uint artistRoyalty = (totalRoyalties * artistSharePercentage) / 100;
        uint collectiveSharePercentage = 100 - artistSharePercentage;
        uint collectiveRoyalty = (totalRoyalties * collectiveSharePercentage) / 100;

        if (artistRoyalty > 0) {
            payable(art.artist).transfer(artistRoyalty); // Assumes artist is payable.
        }
        if (collectiveRoyalty > 0) {
            payable(admin).transfer(collectiveRoyalty); // Example - sending collective share to admin address, could be a designated treasury wallet.
        }

        emit RoyaltyDistributed(_artId, artistRoyalty, collectiveRoyalty);
        art.accumulatedRoyalties = 0; // Reset accumulated royalties after distribution
    }

    /// @notice Get the current balance of the collective treasury.
    /// @return uint Treasury balance in Wei.
    function getTreasuryBalance() external view returns (uint) {
        return address(this).balance;
    }


    // --- Advanced/Creative Functions: Art Challenges, Collaborative Projects, Exhibitions ---

    /// @notice Admin creates an art challenge for collective members.
    /// @param _challengeName Name of the art challenge.
    /// @param _description Description of the challenge.
    /// @param _submissionDeadline Unix timestamp for submission deadline.
    function createArtChallenge(string memory _challengeName, string memory _description, uint _submissionDeadline) external onlyAdmin isChallengeSubmissionDeadlineValid(_submissionDeadline) {
        challengeCounter++;
        artChallenges[challengeCounter] = ArtChallenge({
            challengeId: challengeCounter,
            challengeName: _challengeName,
            description: _description,
            submissionDeadline: _submissionDeadline,
            submissionCounter: 0,
            finalized: false
        });
        emit ArtChallengeCreated(challengeCounter, _challengeName, _description, _submissionDeadline);
    }

    /// @notice Members submit art for a specific art challenge.
    /// @param _challengeId ID of the art challenge to submit to.
    /// @param _artURI URI of the art submission.
    /// @param _metadataURI Metadata URI for the submission.
    function submitArtForChallenge(uint _challengeId, string memory _artURI, string memory _metadataURI) external onlyCollectiveMembers challengeExists(_challengeId) isSubmissionDeadlineNotExpired(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        challenge.submissionCounter++;
        challenge.submissions[challenge.submissionCounter] = ChallengeSubmission({
            submissionId: challenge.submissionCounter,
            submitter: msg.sender,
            artURI: _artURI,
            metadataURI: _metadataURI,
            yesVotes: 0,
            noVotes: 0
        });
        emit ArtSubmittedForChallenge(_challengeId, challenge.submissionCounter, msg.sender, _artURI, _metadataURI);
    }

    /// @notice Members vote on submissions for a specific art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @param _submissionId ID of the submission to vote on.
    /// @param _vote True for approve (like), false for reject (dislike).
    function voteOnChallengeSubmission(uint _challengeId, uint _submissionId, bool _vote) external onlyCollectiveMembers challengeExists(_challengeId) submissionExistsInChallenge(_challengeId, _submissionId) challengeVotingNotFinalized(_challengeId) notAlreadyVotedOnSubmission(_challengeId, _submissionId) {
        ChallengeSubmission storage submission = artChallenges[_challengeId].submissions[_submissionId];
        submission.votes[msg.sender] = _vote;
        if (_vote) {
            submission.yesVotes++;
        } else {
            submission.noVotes++;
        }
        emit ChallengeSubmissionVoted(_challengeId, _submissionId, msg.sender, _vote);
    }

    /// @notice Admin finalizes an art challenge, selecting winners based on votes (e.g., top voted submissions). Admin only.
    /// @param _challengeId ID of the art challenge to finalize.
    function finalizeArtChallenge(uint _challengeId) external onlyAdmin challengeExists(_challengeId) challengeVotingNotFinalized(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(!challenge.finalized, "Challenge already finalized.");

        uint bestSubmissionId; // Simple winner selection - could be more complex based on requirements.
        uint maxVotes = 0;
        uint[] memory winnerSubmissionIds;

        for (uint i = 1; i <= challenge.submissionCounter; i++) {
            if (challenge.submissions[i].yesVotes > maxVotes) {
                maxVotes = challenge.submissions[i].yesVotes;
                bestSubmissionId = challenge.submissions[i].submissionId;
                winnerSubmissionIds = new uint[](1); // Start a new array with the current winner
                winnerSubmissionIds[0] = bestSubmissionId;
            } else if (challenge.submissions[i].yesVotes == maxVotes && maxVotes > 0) {
                // If tie in votes, add to winners array
                uint[] memory tempWinnerSubmissionIds = new uint[](winnerSubmissionIds.length + 1);
                for (uint j = 0; j < winnerSubmissionIds.length; j++) {
                    tempWinnerSubmissionIds[j] = winnerSubmissionIds[j];
                }
                tempWinnerSubmissionIds[winnerSubmissionIds.length] = challenge.submissions[i].submissionId;
                winnerSubmissionIds = tempWinnerSubmissionIds;
            }
        }

        challenge.finalized = true;
        emit ArtChallengeFinalized(_challengeId, winnerSubmissionIds);
        // Here, you could add logic to reward winners (e.g., mint special badges, distribute treasury funds, etc.)
    }

    /// @notice Admin creates a collaborative art project.
    /// @param _projectName Name of the collaborative project.
    /// @param _description Description of the project.
    /// @param _maxCollaborators Maximum number of collaborators allowed.
    function createCollaborativeArtProject(string memory _projectName, string memory _description, uint _maxCollaborators) external onlyAdmin {
        require(_maxCollaborators > 0, "Max collaborators must be greater than zero.");
        collaborativeProjectCounter++;
        collaborativeArtProjects[collaborativeProjectCounter] = CollaborativeArtProject({
            projectId: collaborativeProjectCounter,
            projectName: _projectName,
            description: _description,
            maxCollaborators: _maxCollaborators,
            collaborators: new address[](0), // Initialize with empty array
            contributionCounter: 0,
            finalized: false
        });
        emit CollaborativeProjectCreated(collaborativeProjectCounter, _projectName, _description, _maxCollaborators);
    }

    /// @notice Members can join a collaborative art project.
    /// @param _projectId ID of the collaborative project to join.
    function joinCollaborativeProject(uint _projectId) external onlyCollectiveMembers collaborativeProjectExists(_projectId) collaborativeProjectNotFinalized(_projectId) isCollaborativeProjectJoinable(_projectId) {
        CollaborativeArtProject storage project = collaborativeArtProjects[_projectId];
        for (uint i = 0; i < project.collaborators.length; i++) {
            require(project.collaborators[i] != msg.sender, "Already joined this project."); // Prevent duplicate joining
        }
        project.collaborators.push(msg.sender);
        emit CollaborativeProjectJoined(_projectId, msg.sender);
    }

    /// @notice Members of a collaborative project propose contributions.
    /// @param _projectId ID of the collaborative project.
    /// @param _contributionDescription Description of the contribution.
    /// @param _contributionURI URI of the contribution.
    function proposeContributionToProject(uint _projectId, string memory _contributionDescription, string memory _contributionURI) external onlyCollectiveMembers collaborativeProjectExists(_projectId) collaborativeProjectNotFinalized(_projectId) isCollaborativeProjectMember(_projectId) {
        CollaborativeArtProject storage project = collaborativeArtProjects[_projectId];
        project.contributionCounter++;
        project.contributions[project.contributionCounter] = ProjectContribution({
            contributionId: project.contributionCounter,
            contributor: msg.sender,
            description: _contributionDescription,
            contributionURI: _contributionURI,
            yesVotes: 0,
            noVotes: 0
        });
        emit ContributionProposedToProject(_projectId, project.contributionCounter, msg.sender, _contributionDescription, _contributionURI);
    }

    /// @notice Members of a collaborative project vote on proposed contributions.
    /// @param _projectId ID of the collaborative project.
    /// @param _contributionId ID of the contribution to vote on.
    /// @param _vote True to approve, false to reject.
    function voteOnProjectContribution(uint _projectId, uint _contributionId, bool _vote) external onlyCollectiveMembers collaborativeProjectExists(_projectId) contributionExistsInProject(_projectId, _contributionId) collaborativeProjectNotFinalized(_projectId) notAlreadyVotedOnContribution(_projectId, _contributionId) {
        ProjectContribution storage contribution = collaborativeArtProjects[_projectId].contributions[_contributionId];
        require(isCollaborativeProjectMember(_projectId), "Only project members can vote."); // Restrict voting to project members
        contribution.votes[msg.sender] = _vote;
        if (_vote) {
            contribution.yesVotes++;
        } else {
            contribution.noVotes++;
        }
        emit ProjectContributionVoted(_projectId, _contributionId, msg.sender, _vote);
    }

    /// @notice Admin finalizes a collaborative project, selecting approved contributions. Admin only.
    /// @param _projectId ID of the collaborative project to finalize.
    function finalizeCollaborativeProject(uint _projectId) external onlyAdmin collaborativeProjectExists(_projectId) collaborativeProjectNotFinalized(_projectId) {
        CollaborativeArtProject storage project = collaborativeArtProjects[_projectId];
        require(!project.finalized, "Project already finalized.");

        uint[] memory selectedContributionIds;
        for (uint i = 1; i <= project.contributionCounter; i++) {
            if (project.contributions[i].yesVotes > project.contributions[i].noVotes) { // Simple approval logic - more yes than no votes.
                uint[] memory tempSelectedContributionIds = new uint[](selectedContributionIds.length + 1);
                for (uint j = 0; j < selectedContributionIds.length; j++) {
                    tempSelectedContributionIds[j] = selectedContributionIds[j];
                }
                tempSelectedContributionIds[selectedContributionIds.length] = project.contributions[i].contributionId;
                selectedContributionIds = tempSelectedContributionIds;
            }
        }

        project.finalized = true;
        emit CollaborativeProjectFinalized(_projectId, selectedContributionIds);
        // Here you could add logic to combine selected contributions, mint a collaborative NFT, etc.
    }

    /// @notice Admin initiates a decentralized exhibition of selected art pieces. Admin only.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _artIds Array of art piece IDs to include in the exhibition.
    /// @param _startDate Unix timestamp for exhibition start date.
    /// @param _endDate Unix timestamp for exhibition end date.
    function initiateDecentralizedExhibition(string memory _exhibitionName, uint[] memory _artIds, uint _startDate, uint _endDate) external onlyAdmin {
        require(_startDate < _endDate, "Exhibition start date must be before end date.");
        // In a real application, you might store exhibition details and art piece IDs in a mapping or struct.
        // For this example, just emitting an event.
        emit DecentralizedExhibitionInitiated(_exhibitionName, _artIds, _startDate, _endDate);
        // Further implementation would involve off-chain or on-chain mechanisms to display/curate the exhibition
        // (e.g., updating a website, creating a virtual gallery using IPFS links, etc.).
    }

    // --- Fallback and Receive Functions (Optional - for receiving ETH directly) ---
    receive() external payable {}
    fallback() external payable {}
}
```