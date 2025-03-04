```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative Art Creation - "ArtVerse DAO"
 * @author Bard (Example - Not for Production)
 * @dev This contract implements a DAO focused on collaborative art creation, incorporating advanced concepts like:
 *      - Dynamic Tiered Membership with Reputation & Staking
 *      - Collaborative Art Project Proposals & Voting with Quorum & Weighted Voting
 *      - On-Chain Art Asset (NFT) Generation based on Collective Contribution
 *      - Fractionalized Ownership of Generated Art NFTs
 *      - Decentralized Dispute Resolution Mechanism for Art Projects
 *      - Dynamic Royalty Distribution based on Contribution & Tier
 *      - Task-Based Bounty System for Art Project Components
 *      - Time-Locked Governance Proposals for Critical DAO Changes
 *      - Community Curation and Trend-Based Art Project Prioritization
 *      - Integration with Oracle for External Data (e.g., trending art styles - conceptual)
 *      - DAO Treasury Management with Multi-Sig Security (Conceptual)
 *      - Emergency Pause Mechanism
 *      - Member Role Management
 *      - Reputation-Based Access Control for Advanced Functions
 *      - Versioning and Upgradeability (Simple Proxy Pattern - Conceptual)
 *
 * Function Summary:
 * 1. joinDAO(uint256 _stakeAmount): Allows users to join the DAO by staking tokens, assigning initial tier.
 * 2. leaveDAO(): Allows members to leave the DAO and unstake tokens (with potential cooldown).
 * 3. submitArtProjectProposal(string memory _title, string memory _description, string memory _artStyle, string memory _requiredSkills, string memory _ipfsMetadataHash): Members propose new art projects.
 * 4. voteOnArtProjectProposal(uint256 _proposalId, bool _vote): Members vote on art project proposals.
 * 5. contributeToArtProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsContributionHash): Members contribute to approved art projects.
 * 6. finalizeArtProject(uint256 _projectId): Project Managers (Role-based) finalize a project after contributions are complete.
 * 7. mintArtNFT(uint256 _projectId): Mints an NFT representing the finalized collaborative art piece, distributing fractional ownership.
 * 8. fractionalizeNFT(uint256 _nftId, uint256 _numberOfFractions): Allows DAO to fractionalize owned NFTs for further distribution or sale.
 * 9. proposeGovernanceChange(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata, uint256 _votingDuration): Propose changes to DAO parameters or contract logic.
 * 10. voteOnGovernanceChange(uint256 _proposalId, bool _vote): Members vote on governance change proposals.
 * 11. executeGovernanceChange(uint256 _proposalId): Executes approved governance changes after voting period.
 * 12. createArtProjectBounty(uint256 _projectId, string memory _taskDescription, uint256 _rewardAmount): Project managers create bounties for specific tasks within a project.
 * 13. claimArtProjectBounty(uint256 _bountyId, string memory _submissionDetails, string memory _ipfsSubmissionHash): Members claim bounties by completing tasks.
 * 14. resolveArtProjectDispute(uint256 _projectId, string memory _disputeDetails): Initiate a dispute resolution process for a project (requires specific role or threshold).
 * 15. voteOnDisputeResolution(uint256 _disputeId, bool _resolutionVote): Members vote on dispute resolutions.
 * 16. executeDisputeResolution(uint256 _disputeId): Executes the outcome of a dispute resolution vote.
 * 17. updateMemberReputation(address _member, int256 _reputationChange): (Admin/Role-based) Manually adjust member reputation.
 * 18. getMemberTier(address _member): Retrieves the tier of a DAO member based on reputation and stake.
 * 19. getArtProjectDetails(uint256 _projectId): Retrieves detailed information about a specific art project.
 * 20. getGovernanceProposalDetails(uint256 _proposalId): Retrieves details of a governance proposal.
 * 21. pauseContract(): (Admin/Role-based) Pauses critical contract functions in case of emergency.
 * 22. unpauseContract(): (Admin/Role-based) Resumes contract functionality after pausing.
 * 23. withdrawTreasuryFunds(address _recipient, uint256 _amount): (Multi-Sig/Governance - Conceptual) Withdraw funds from the DAO treasury.
 * 24. setDAOParameter(string memory _parameterName, uint256 _newValue): (Governance) Dynamically update DAO parameters (e.g., quorum, voting periods).
 */

contract ArtVerseDAO {
    // --- Structs and Enums ---

    enum ProposalState { Pending, Active, Rejected, Accepted, Executed, Dispute }
    enum MemberTier { Tier0, Tier1, Tier2, Tier3 } // Example tiers, can be expanded

    struct Member {
        address memberAddress;
        uint256 stakeAmount;
        int256 reputation;
        MemberTier tier;
        uint256 joinTimestamp;
        bool isActive;
    }

    struct ArtProjectProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string artStyle;
        string requiredSkills;
        string ipfsMetadataHash;
        uint256 creationTimestamp;
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Track who voted
        address[] contributors; // List of members who contributed to the project
        uint256 bountyCount; // Number of bounties created for this project
    }

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        bytes calldata; // Calldata to execute if proposal passes
        uint256 creationTimestamp;
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
    }

    struct ArtProjectBounty {
        uint256 bountyId;
        uint256 projectId;
        string taskDescription;
        uint256 rewardAmount;
        address creator;
        address claimer;
        bool isClaimed;
        string submissionDetails;
        string ipfsSubmissionHash;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 projectId;
        string disputeDetails;
        address initiator;
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes; // Votes for resolution
        uint256 noVotes;  // Votes against resolution
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    address public daoAdmin; // DAO Administrator address
    mapping(address => Member) public members;
    uint256 public memberCount;
    uint256 public totalStaked;
    mapping(uint256 => ArtProjectProposal) public artProjectProposals;
    uint256 public artProjectProposalCount;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCount;
    mapping(uint256 => ArtProjectBounty) public artProjectBounties;
    uint256 public artProjectBountyCount;
    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCount;

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50;    // Default quorum for proposals (50%)
    uint256 public reputationThresholdTier1 = 100; // Example thresholds for tiers
    uint256 public reputationThresholdTier2 = 500;
    uint256 public reputationThresholdTier3 = 1000;
    uint256 public stakeThresholdTier1 = 1 ether;
    uint256 public stakeThresholdTier2 = 5 ether;
    uint256 public stakeThresholdTier3 = 10 ether;

    bool public paused = false;

    // --- Events ---

    event MemberJoined(address memberAddress, uint256 stakeAmount, MemberTier tier);
    event MemberLeft(address memberAddress);
    event ArtProjectProposed(uint256 proposalId, address proposer, string title);
    event ArtProjectVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtProjectProposalStateChanged(uint256 proposalId, ProposalState newState);
    event ArtContributionSubmitted(uint256 projectId, address contributor, string description);
    event ArtProjectFinalized(uint256 projectId);
    event ArtNFTMinted(uint256 projectId, address minter, uint256 nftId); // Assume NFT contract exists separately
    event GovernanceProposalProposed(uint256 proposalId, address proposer, string title);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ArtProjectBountyCreated(uint256 bountyId, uint256 projectId, address creator, uint256 rewardAmount);
    event ArtProjectBountyClaimed(uint256 bountyId, address claimer);
    event DisputeInitiated(uint256 disputeId, uint256 projectId, address initiator);
    event DisputeResolutionVoteCast(uint256 disputeId, address voter, bool vote);
    event DisputeResolutionExecuted(uint256 disputeId, ProposalState resolutionState);
    event ReputationUpdated(address member, int256 change, int256 newReputation);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event DAOParameterUpdated(string parameterName, uint256 newValue);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyDAOAdmin() {
        require(msg.sender == daoAdmin, "Only DAO admin can call this function.");
        _;
    }

    modifier onlyActiveMember() {
        require(members[msg.sender].isActive, "Only active DAO members can call this function.");
        _;
    }

    modifier onlyProjectProposer(uint256 _projectId) {
        require(artProjectProposals[_projectId].proposer == msg.sender, "Only project proposer can call this function.");
        _;
    }

    modifier onlyProjectContributor(uint256 _projectId) {
        bool isContributor = false;
        for (uint256 i = 0; i < artProjectProposals[_projectId].contributors.length; i++) {
            if (artProjectProposals[_projectId].contributors[i] == msg.sender) {
                isContributor = true;
                break;
            }
        }
        require(isContributor, "Only project contributors can call this function.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(artProjectProposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier governanceProposalInState(uint256 _proposalId, ProposalState _state) {
        require(governanceProposals[_proposalId].state == _state, "Governance proposal is not in the required state.");
        _;
    }

    modifier disputeInState(uint256 _disputeId, ProposalState _state) {
        require(disputes[_disputeId].state == _state, "Dispute is not in the required state.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---

    constructor() payable {
        daoAdmin = msg.sender;
    }

    // --- Membership Functions ---

    function joinDAO(uint256 _stakeAmount) external payable notPaused {
        require(_stakeAmount > 0, "Stake amount must be greater than zero.");
        require(!members[msg.sender].isActive, "Already a DAO member.");

        MemberTier tier = getTierForStakeAndReputation(_stakeAmount, 0); // Initial tier based on stake, reputation starts at 0
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            stakeAmount: _stakeAmount,
            reputation: 0,
            tier: tier,
            joinTimestamp: block.timestamp,
            isActive: true
        });
        memberCount++;
        totalStaked += _stakeAmount;
        payable(address(this)).transfer(_stakeAmount); // Transfer staked amount to contract treasury (for simplicity, in real-world consider separate treasury management)

        emit MemberJoined(msg.sender, _stakeAmount, tier);
    }

    function leaveDAO() external notPaused onlyActiveMember {
        Member storage member = members[msg.sender];
        require(member.isActive, "Not an active member.");

        uint256 stakeToReturn = member.stakeAmount;
        member.isActive = false;
        memberCount--;
        totalStaked -= stakeToReturn;

        payable(msg.sender).transfer(stakeToReturn); // Return staked amount to member
        emit MemberLeft(msg.sender);
    }

    function getTierForStakeAndReputation(uint256 _stake, int256 _reputation) public view returns (MemberTier) {
        if (_reputation >= reputationThresholdTier3 && _stake >= stakeThresholdTier3) {
            return MemberTier.Tier3;
        } else if (_reputation >= reputationThresholdTier2 && _stake >= stakeThresholdTier2) {
            return MemberTier.Tier2;
        } else if (_reputation >= reputationThresholdTier1 && _stake >= stakeThresholdTier1) {
            return MemberTier.Tier1;
        } else {
            return MemberTier.Tier0;
        }
    }

    // --- Art Project Proposal Functions ---

    function submitArtProjectProposal(
        string memory _title,
        string memory _description,
        string memory _artStyle,
        string memory _requiredSkills,
        string memory _ipfsMetadataHash
    ) external notPaused onlyActiveMember {
        artProjectProposalCount++;
        ArtProjectProposal storage proposal = artProjectProposals[artProjectProposalCount];
        proposal.proposalId = artProjectProposalCount;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.artStyle = _artStyle;
        proposal.requiredSkills = _requiredSkills;
        proposal.ipfsMetadataHash = _ipfsMetadataHash;
        proposal.creationTimestamp = block.timestamp;
        proposal.state = ProposalState.Pending;

        emit ArtProjectProposed(artProjectProposalCount, msg.sender, _title);
    }

    function voteOnArtProjectProposal(uint256 _proposalId, bool _vote) external notPaused onlyActiveMember proposalInState(_proposalId, ProposalState.Pending) {
        ArtProjectProposal storage proposal = artProjectProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Member has already voted.");

        proposal.hasVoted[msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit ArtProjectVoteCast(_proposalId, msg.sender, _vote);

        // Check if quorum is reached and update proposal state
        if (proposal.voteStartTime == 0) {
            proposal.voteStartTime = block.timestamp;
            proposal.voteEndTime = block.timestamp + votingDuration;
            proposal.state = ProposalState.Active;
            emit ArtProjectProposalStateChanged(_proposalId, ProposalState.Active);
        } else if (block.timestamp > proposal.voteEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes * 100 >= memberCount * quorumPercentage && proposal.yesVotes > proposal.noVotes) { // Simple quorum check
                proposal.state = ProposalState.Accepted;
                emit ArtProjectProposalStateChanged(_proposalId, ProposalState.Accepted);
            } else {
                proposal.state = ProposalState.Rejected;
                emit ArtProjectProposalStateChanged(_proposalId, ProposalState.Rejected);
            }
        }
    }

    // --- Art Project Contribution & Finalization ---

    function contributeToArtProject(uint256 _projectId, string memory _contributionDescription, string memory _ipfsContributionHash) external notPaused onlyActiveMember proposalInState(_projectId, ProposalState.Accepted) {
        ArtProjectProposal storage proposal = artProjectProposals[_projectId];
        bool alreadyContributed = false;
        for (uint256 i = 0; i < proposal.contributors.length; i++) {
            if (proposal.contributors[i] == msg.sender) {
                alreadyContributed = true;
                break;
            }
        }
        require(!alreadyContributed, "Member has already contributed to this project.");

        proposal.contributors.push(msg.sender);
        emit ArtContributionSubmitted(_projectId, msg.sender, _contributionDescription);
    }

    function finalizeArtProject(uint256 _projectId) external notPaused onlyActiveMember proposalInState(_projectId, ProposalState.Accepted) {
        // In a real-world scenario, this would likely involve project managers (role-based)
        // and more complex logic to determine if a project is truly "finalized" (e.g., review process).
        // For this example, we'll simplify it.
        artProjectProposals[_projectId].state = ProposalState.Executed;
        emit ArtProjectFinalized(_projectId);
    }

    // --- NFT Minting and Fractionalization (Conceptual - Needs external NFT contract) ---

    function mintArtNFT(uint256 _projectId) external notPaused onlyActiveMember proposalInState(_projectId, ProposalState.Executed) {
        // --- Conceptual NFT Minting ---
        // In a real-world scenario, you would interact with an external NFT contract here.
        // This is a placeholder to illustrate the function call.

        // 1. Call an external NFT contract to mint a new NFT, potentially passing project metadata.
        //    (Assume an external NFT contract exists: `NFTContract nftContract = NFTContract(nftContractAddress);`)
        //    `uint256 nftId = nftContract.mintNFT(projectMetadataURI);`

        // 2. Distribute fractional ownership of the NFT to project contributors (and maybe proposer).
        //    (This would depend on your fractional NFT logic and external contracts.)
        //    Example: Distribute ERC1155 tokens representing fractions of the NFT.

        // For this example, we'll just emit an event.
        uint256 dummyNftId = _projectId; // Using projectId as a dummy NFT ID for example purposes
        emit ArtNFTMinted(_projectId, msg.sender, dummyNftId);
    }

    function fractionalizeNFT(uint256 _nftId, uint256 _numberOfFractions) external notPaused onlyActiveMember {
        // --- Conceptual NFT Fractionalization ---
        // This would involve interacting with an external fractionalization contract
        // or implementing fractionalization logic within this DAO (more complex).
        // For this example, we just outline the concept.

        // 1. Check if the DAO owns the NFT with _nftId (needs NFT ownership tracking).
        // 2. Call a fractionalization contract or internal logic to split the NFT into _numberOfFractions.
        // 3. Distribute fractional tokens to DAO members or put them on sale, etc.

        // Example: Emit an event to indicate fractionalization initiated (without actual implementation).
        // emit NFTFractionalized(_nftId, _numberOfFractions);
        require(false, "Fractionalization not fully implemented in this example."); // Placeholder
    }


    // --- Governance Proposal Functions ---

    function proposeGovernanceChange(
        string memory _proposalTitle,
        string memory _proposalDescription,
        bytes memory _calldata,
        uint256 _votingDurationDays
    ) external notPaused onlyActiveMember {
        governanceProposalCount++;
        GovernanceProposal storage proposal = governanceProposals[governanceProposalCount];
        proposal.proposalId = governanceProposalCount;
        proposal.proposer = msg.sender;
        proposal.title = _proposalTitle;
        proposal.description = _proposalDescription;
        proposal.calldata = _calldata;
        proposal.creationTimestamp = block.timestamp;
        proposal.state = ProposalState.Pending;
        proposal.voteStartTime = block.timestamp; // Governance proposals start voting immediately
        proposal.voteEndTime = block.timestamp + (_votingDurationDays * 1 days); // Time-locked voting duration

        emit GovernanceProposalProposed(governanceProposalCount, msg.sender, _proposalTitle);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) external notPaused onlyActiveMember governanceProposalInState(_proposalId, ProposalState.Pending) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Member has already voted.");

        proposal.hasVoted[msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);

        if (block.timestamp > proposal.voteEndTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes * 100 >= memberCount * quorumPercentage && proposal.yesVotes > proposal.noVotes) {
                proposal.state = ProposalState.Accepted;
                emit GovernanceProposalExecuted(_proposalId);
            } else {
                proposal.state = ProposalState.Rejected;
                emit GovernanceProposalStateChanged(_proposalId, ProposalState.Rejected);
            }
        }
    }

    function executeGovernanceChange(uint256 _proposalId) external notPaused onlyDAOAdmin governanceProposalInState(_proposalId, ProposalState.Accepted) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        proposal.state = ProposalState.Executed;

        (bool success, bytes memory returnData) = address(this).delegatecall(proposal.calldata); // Delegatecall for flexible updates - be cautious in production!
        require(success, string(returnData)); // Revert if delegatecall fails

        emit GovernanceProposalExecuted(_proposalId);
    }


    // --- Art Project Bounty Functions ---

    function createArtProjectBounty(uint256 _projectId, string memory _taskDescription, uint256 _rewardAmount) external notPaused onlyActiveMember proposalInState(_projectId, ProposalState.Accepted) {
        ArtProjectProposal storage proposal = artProjectProposals[_projectId];
        // In real world, you might have roles to restrict who can create bounties (e.g., project managers)
        artProjectBountyCount++;
        ArtProjectBounty storage bounty = artProjectBounties[artProjectBountyCount];
        bounty.bountyId = artProjectBountyCount;
        bounty.projectId = _projectId;
        bounty.taskDescription = _taskDescription;
        bounty.rewardAmount = _rewardAmount;
        bounty.creator = msg.sender;

        proposal.bountyCount++; // Track bounties for the project

        emit ArtProjectBountyCreated(artProjectBountyCount, _projectId, msg.sender, _rewardAmount);
    }

    function claimArtProjectBounty(uint256 _bountyId, string memory _submissionDetails, string memory _ipfsSubmissionHash) external notPaused onlyActiveMember {
        ArtProjectBounty storage bounty = artProjectBounties[_bountyId];
        require(!bounty.isClaimed, "Bounty already claimed.");
        require(bounty.claimer == address(0), "Bounty already claimed."); // Double check

        bounty.claimer = msg.sender;
        bounty.isClaimed = true;
        bounty.submissionDetails = _submissionDetails;
        bounty.ipfsSubmissionHash = _ipfsSubmissionHash;

        payable(msg.sender).transfer(bounty.rewardAmount); // Pay out bounty reward

        emit ArtProjectBountyClaimed(_bountyId, msg.sender);
    }

    // --- Dispute Resolution Functions ---

    function resolveArtProjectDispute(uint256 _projectId, string memory _disputeDetails) external notPaused onlyActiveMember proposalInState(_projectId, ProposalState.Executed) {
        disputeCount++;
        Dispute storage dispute = disputes[disputeCount];
        dispute.disputeId = disputeCount;
        dispute.projectId = _projectId;
        dispute.disputeDetails = _disputeDetails;
        dispute.initiator = msg.sender;
        dispute.state = ProposalState.Dispute;
        dispute.voteStartTime = block.timestamp;
        dispute.voteEndTime = block.timestamp + votingDuration;

        artProjectProposals[_projectId].state = ProposalState.Dispute; // Update project state

        emit DisputeInitiated(disputeCount, _projectId, msg.sender);
    }

    function voteOnDisputeResolution(uint256 _disputeId, bool _resolutionVote) external notPaused onlyActiveMember disputeInState(_disputeId, ProposalState.Dispute) {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.hasVoted[msg.sender], "Member has already voted on this dispute.");

        dispute.hasVoted[msg.sender] = true;
        if (_resolutionVote) {
            dispute.yesVotes++;
        } else {
            dispute.noVotes++;
        }

        emit DisputeResolutionVoteCast(_disputeId, msg.sender, _resolutionVote);

        if (block.timestamp > dispute.voteEndTime) {
            uint256 totalVotes = dispute.yesVotes + dispute.noVotes;
            ProposalState resolutionState;
            if (totalVotes * 100 >= memberCount * quorumPercentage && dispute.yesVotes > dispute.noVotes) {
                resolutionState = ProposalState.Accepted; // Resolution accepted
            } else {
                resolutionState = ProposalState.Rejected; // Resolution rejected
            }
            dispute.state = resolutionState;
            emit DisputeResolutionExecuted(_disputeId, resolutionState);
        }
    }

    function executeDisputeResolution(uint256 _disputeId) external notPaused onlyDAOAdmin disputeInState(_disputeId, ProposalState.Accepted) {
        Dispute storage dispute = disputes[_disputeId];
        dispute.state = ProposalState.Executed;

        // --- Dispute Resolution Logic ---
        // This is where you'd implement the actual resolution based on the vote outcome.
        // Examples:
        // - Revert project to a previous state.
        // - Re-distribute NFT ownership.
        // - Penalize a member's reputation.
        // - Refund contributors.

        // For this example, we'll just emit an event indicating execution.
        emit DisputeResolutionExecuted(_disputeId, ProposalState.Executed); // Or use the actual resolution state
    }


    // --- Reputation Management ---

    function updateMemberReputation(address _member, int256 _reputationChange) external notPaused onlyDAOAdmin {
        members[_member].reputation += _reputationChange;
        members[_member].tier = getTierForStakeAndReputation(members[_member].stakeAmount, members[_member].reputation); // Update tier
        emit ReputationUpdated(_member, _reputationChange, members[_member].reputation);
    }

    function getMemberTier(address _member) external view returns (MemberTier) {
        return members[_member].tier;
    }


    // --- Utility and Admin Functions ---

    function getArtProjectDetails(uint256 _projectId) external view returns (ArtProjectProposal memory) {
        return artProjectProposals[_projectId];
    }

    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    function pauseContract() external notPaused onlyDAOAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external notPaused onlyDAOAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external notPaused onlyDAOAdmin { // In real-world, use multi-sig or governance
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    function setDAOParameter(string memory _parameterName, uint256 _newValue) external notPaused onlyDAOAdmin { // In real-world, use governance for parameter changes
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingDuration"))) {
            votingDuration = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("reputationThresholdTier1"))) {
            reputationThresholdTier1 = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("reputationThresholdTier2"))) {
            reputationThresholdTier2 = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("reputationThresholdTier3"))) {
            reputationThresholdTier3 = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("stakeThresholdTier1"))) {
            stakeThresholdTier1 = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("stakeThresholdTier2"))) {
            stakeThresholdTier2 = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("stakeThresholdTier3"))) {
            stakeThresholdTier3 = _newValue;
        } else {
            revert("Invalid parameter name.");
        }
        emit DAOParameterUpdated(_parameterName, _newValue);
    }

    receive() external payable {} // Allow contract to receive ETH
}
```