```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized art collective, enabling artists to submit work,
 *      members to vote on submissions, manage a treasury, participate in collaborative art projects,
 *      and more. This contract aims to foster a vibrant and self-governing art ecosystem on the blockchain.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Functionality (Art Submission & Curation):**
 *    - `submitArt(string _title, string _description, string _ipfsHash)`: Allows artists to submit their artwork proposals.
 *    - `voteOnSubmission(uint256 _submissionId, bool _approve)`: Members can vote to approve or reject submitted artwork.
 *    - `finalizeSubmission(uint256 _submissionId)`:  Admin/DAO can finalize a submission after voting, minting an NFT if approved.
 *    - `getSubmissionDetails(uint256 _submissionId)`: Retrieves details of a specific art submission.
 *    - `getAllSubmissions()`: Returns a list of all submission IDs.
 *    - `getApprovedSubmissions()`: Returns a list of IDs of approved submissions.
 *    - `getRejectedSubmissions()`: Returns a list of IDs of rejected submissions.
 *
 * **2. Membership & Governance:**
 *    - `requestMembership()`: Allows users to request membership in the collective.
 *    - `approveMembership(address _user)`: Admin/DAO can approve membership requests.
 *    - `revokeMembership(address _member)`: Admin/DAO can revoke membership.
 *    - `isMember(address _user)`: Checks if an address is a member of the collective.
 *    - `getMemberCount()`: Returns the total number of members.
 *    - `proposeGovernanceChange(string _proposalDescription, bytes memory _calldata)`: Members can propose changes to contract parameters.
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Members can vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Admin/DAO can execute approved governance proposals.
 *    - `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a governance proposal.
 *    - `getAllGovernanceProposals()`: Returns a list of all governance proposal IDs.
 *
 * **3. Collaborative Art & Treasury:**
 *    - `startCollaborativeProject(string _projectName, string _projectDescription)`: Initiates a collaborative art project.
 *    - `contributeToProject(uint256 _projectId, string _contributionDetails, string _ipfsContributionHash)`: Members can contribute to ongoing projects.
 *    - `finalizeProject(uint256 _projectId)`: Admin/DAO can finalize a project, potentially minting a collaborative NFT.
 *    - `depositToTreasury() payable`: Members can deposit funds into the collective's treasury.
 *    - `createTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string _reason)`: Members can propose withdrawals from the treasury.
 *    - `voteOnTreasuryWithdrawal(uint256 _proposalId, bool _support)`: Members vote on treasury withdrawal proposals.
 *    - `executeTreasuryWithdrawal(uint256 _proposalId)`: Admin/DAO executes approved treasury withdrawal proposals.
 *    - `getTreasuryBalance()`: Returns the current balance of the collective's treasury.
 *
 * **4. Advanced & Trendy Features:**
 *    - `setSubmissionVotingDuration(uint256 _durationInBlocks)`:  Dynamically sets the voting duration for art submissions.
 *    - `setGovernanceVotingDuration(uint256 _durationInBlocks)`: Dynamically sets the voting duration for governance proposals.
 *    - `setMembershipFee(uint256 _fee)`: Sets a membership fee (payable in native token) for joining the collective.
 *    - `withdrawMembershipFee()`: Allows the contract admin to withdraw accumulated membership fees.
 *    - `emergencyShutdown()`:  A circuit breaker function to pause critical contract functionalities in case of emergency (admin-only).
 *    - `setRoyaltyPercentage(uint256 _percentage)`: Sets the royalty percentage applied to secondary sales of collective NFTs (if implemented in NFT contract, concept here).
 *
 * **Note:** This contract outlines the core logic and functions. Real-world implementation would require further considerations like gas optimization, security audits,
 *         error handling, event emission, and integration with an NFT contract for minted artwork. The 'admin' role is assumed to be a multi-sig wallet or a DAO for true decentralization.
 */

contract DecentralizedArtCollective {

    // -------- State Variables --------

    address public admin; // Address of the contract admin (DAO or multi-sig)
    uint256 public membershipFee; // Fee to become a member
    uint256 public royaltyPercentage; // Royalty percentage for secondary sales (concept)
    uint256 public submissionVotingDuration = 100; // Voting duration for submissions in blocks
    uint256 public governanceVotingDuration = 200; // Voting duration for governance proposals in blocks

    mapping(address => bool) public isMember; // Mapping to track members of the collective
    address[] public members; // Array to list all members (for iteration if needed, could be optimized)

    uint256 public submissionCount = 0;
    struct ArtSubmission {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        SubmissionStatus status;
        mapping(address => bool) votes; // Members who have voted, to prevent double voting
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }
    enum SubmissionStatus { Pending, Approved, Rejected, Finalized }
    mapping(uint256 => ArtSubmission) public artSubmissions;
    uint256[] public allSubmissions;
    uint256[] public approvedSubmissions;
    uint256[] public rejectedSubmissions;

    uint256 public governanceProposalCount = 0;
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes calldata; // Calldata to execute if proposal passes
        uint256 proposalTimestamp;
        ProposalStatus status;
        mapping(address => bool) votes;
        uint256 supportVotes;
        uint256 againstVotes;
        uint256 votingEndTime;
    }
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256[] public allGovernanceProposals;

    uint256 public treasuryWithdrawalProposalCount = 0;
    struct TreasuryWithdrawalProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 proposalTimestamp;
        ProposalStatus status;
        mapping(address => bool) votes;
        uint256 supportVotes;
        uint256 againstVotes;
        uint256 votingEndTime;
    }
    mapping(uint256 => TreasuryWithdrawalProposal) public treasuryWithdrawalProposals;

    uint256 public collaborativeProjectCount = 0;
    struct CollaborativeProject {
        uint256 id;
        string name;
        string description;
        address creator;
        uint256 creationTimestamp;
        ProjectStatus status;
        Contribution[] contributions;
    }
    struct Contribution {
        address contributor;
        string details;
        string ipfsContributionHash;
        uint256 contributionTimestamp;
    }
    enum ProjectStatus { Active, Finalized }
    mapping(uint256 => CollaborativeProject) public collaborativeProjects;

    bool public contractPaused = false; // Emergency shutdown circuit breaker


    // -------- Events --------
    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ArtSubmitted(uint256 indexed submissionId, address indexed artist, string title);
    event SubmissionVoted(uint256 indexed submissionId, address indexed voter, bool approve);
    event SubmissionFinalized(uint256 indexed submissionId, SubmissionStatus status);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId, ProposalStatus status);
    event TreasuryWithdrawalProposalCreated(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event TreasuryWithdrawalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event TreasuryWithdrawalExecuted(uint256 indexed proposalId, ProposalStatus status, address recipient, uint256 amount);
    event CollaborativeProjectStarted(uint256 indexed projectId, string projectName, address indexed creator);
    event ProjectContributionMade(uint256 indexed projectId, address indexed contributor);
    event CollaborativeProjectFinalized(uint256 indexed projectId);
    event MembershipFeeSet(uint256 fee);
    event RoyaltyPercentageSet(uint256 percentage);
    event SubmissionVotingDurationSet(uint256 durationInBlocks);
    event GovernanceVotingDurationSet(uint256 durationInBlocks);
    event ContractPaused();
    event ContractUnpaused();
    event MembershipFeeWithdrawn(address admin, uint256 amount);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can perform this action");
        _;
    }

    modifier submissionExists(uint256 _submissionId) {
        require(_submissionId < submissionCount && artSubmissions[_submissionId].id == _submissionId, "Submission does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < governanceProposalCount && governanceProposals[_proposalId].id == _proposalId, "Governance proposal does not exist");
        _;
    }

    modifier withdrawalProposalExists(uint256 _proposalId) {
        require(_proposalId < treasuryWithdrawalProposalCount && treasuryWithdrawalProposals[_proposalId].id == _proposalId, "Withdrawal proposal does not exist");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId < collaborativeProjectCount && collaborativeProjects[_projectId].id == _projectId, "Collaborative project does not exist");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier votingNotEnded(uint256 _endTime) {
        require(block.number < _endTime, "Voting period has ended");
        _;
    }

    modifier votingNotStarted(uint256 _startTime) {
        require(block.number < _startTime, "Voting period has started"); // Example, might not be needed for all voting
        _;
    }


    // -------- Constructor --------
    constructor() {
        admin = msg.sender;
        membershipFee = 0.1 ether; // Initial membership fee
        royaltyPercentage = 5; // Initial royalty percentage
    }


    // -------- 1. Core Functionality (Art Submission & Curation) --------

    /// @notice Allows artists to submit their artwork proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash pointing to the artwork data.
    function submitArt(string memory _title, string memory _description, string memory _ipfsHash) external notPaused {
        submissionCount++;
        ArtSubmission storage newSubmission = artSubmissions[submissionCount];
        newSubmission.id = submissionCount;
        newSubmission.artist = msg.sender;
        newSubmission.title = _title;
        newSubmission.description = _description;
        newSubmission.ipfsHash = _ipfsHash;
        newSubmission.submissionTimestamp = block.timestamp;
        newSubmission.status = SubmissionStatus.Pending;
        newSubmission.votingEndTime = block.number + submissionVotingDuration;

        allSubmissions.push(submissionCount);

        emit ArtSubmitted(submissionCount, msg.sender, _title);
    }

    /// @notice Members can vote to approve or reject a submitted artwork.
    /// @param _submissionId ID of the art submission.
    /// @param _approve True to approve, false to reject.
    function voteOnSubmission(uint256 _submissionId, bool _approve) external onlyMember notPaused submissionExists(_submissionId) votingNotEnded(artSubmissions[_submissionId].votingEndTime) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(!submission.votes[msg.sender], "Already voted on this submission");
        require(submission.status == SubmissionStatus.Pending, "Submission is not in Pending status");

        submission.votes[msg.sender] = true;
        if (_approve) {
            submission.yesVotes++;
        } else {
            submission.noVotes++;
        }
        emit SubmissionVoted(_submissionId, msg.sender, _approve);
    }

    /// @notice Admin/DAO can finalize a submission after voting, minting an NFT if approved (concept).
    /// @param _submissionId ID of the art submission to finalize.
    function finalizeSubmission(uint256 _submissionId) external onlyAdmin notPaused submissionExists(_submissionId) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Pending, "Submission is not in Pending status");
        require(block.number >= submission.votingEndTime, "Voting period has not ended"); // Ensure voting ended

        if (submission.yesVotes > submission.noVotes) {
            submission.status = SubmissionStatus.Approved;
            approvedSubmissions.push(_submissionId);
            // In a real implementation: Mint NFT for approved artwork here, transfer to artist, etc.
            // ... NFT Minting Logic (Needs integration with an NFT contract) ...
            emit SubmissionFinalized(_submissionId, SubmissionStatus.Approved);
        } else {
            submission.status = SubmissionStatus.Rejected;
            rejectedSubmissions.push(_submissionId);
            emit SubmissionFinalized(_submissionId, SubmissionStatus.Rejected);
        }
        submission.status = SubmissionStatus.Finalized; // Mark as finalized regardless of outcome
    }

    /// @notice Retrieves details of a specific art submission.
    /// @param _submissionId ID of the art submission.
    /// @return Details of the submission.
    function getSubmissionDetails(uint256 _submissionId) external view submissionExists(_submissionId)
        returns (uint256 id, address artist, string memory title, string memory description, string memory ipfsHash, uint256 submissionTimestamp, SubmissionStatus status, uint256 yesVotes, uint256 noVotes, uint256 votingEndTime)
    {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        return (submission.id, submission.artist, submission.title, submission.description, submission.ipfsHash, submission.submissionTimestamp, submission.status, submission.yesVotes, submission.noVotes, submission.votingEndTime);
    }

    /// @notice Returns a list of all submission IDs.
    /// @return Array of submission IDs.
    function getAllSubmissions() external view returns (uint256[] memory) {
        return allSubmissions;
    }

    /// @notice Returns a list of IDs of approved submissions.
    /// @return Array of approved submission IDs.
    function getApprovedSubmissions() external view returns (uint256[] memory) {
        return approvedSubmissions;
    }

    /// @notice Returns a list of IDs of rejected submissions.
    /// @return Array of rejected submission IDs.
    function getRejectedSubmissions() external view returns (uint256[] memory) {
        return rejectedSubmissions;
    }


    // -------- 2. Membership & Governance --------

    /// @notice Allows users to request membership in the collective, paying a fee if set.
    function requestMembership() external payable notPaused {
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Membership fee not paid");
        } else {
            require(msg.value == 0, "Should not send value if membership is free");
        }
        emit MembershipRequested(msg.sender);
        // Admin needs to manually approve using approveMembership
    }

    /// @notice Admin/DAO can approve membership requests.
    /// @param _user Address of the user to approve for membership.
    function approveMembership(address _user) external onlyAdmin notPaused {
        require(!isMember[_user], "User is already a member");
        isMember[_user] = true;
        members.push(_user);
        emit MembershipApproved(_user);
    }

    /// @notice Admin/DAO can revoke membership.
    /// @param _member Address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(isMember[_member], "User is not a member");
        isMember[_member] = false;
        // Remove from members array (inefficient for large arrays, consider optimization if needed)
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _user Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _user) external view returns (bool) {
        return isMember[_user];
    }

    /// @notice Returns the total number of members.
    /// @return Number of members.
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }

    /// @notice Members can propose changes to contract parameters or functionality.
    /// @param _proposalDescription Description of the governance proposal.
    /// @param _calldata Encoded function call data to execute if the proposal passes.
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) external onlyMember notPaused {
        governanceProposalCount++;
        GovernanceProposal storage newProposal = governanceProposals[governanceProposalCount];
        newProposal.id = governanceProposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _proposalDescription;
        newProposal.calldata = _calldata;
        newProposal.proposalTimestamp = block.timestamp;
        newProposal.status = ProposalStatus.Active; // Or Pending -> Active if there's an activation process
        newProposal.votingEndTime = block.number + governanceVotingDuration;

        allGovernanceProposals.push(governanceProposalCount);
        emit GovernanceProposalCreated(governanceProposalCount, msg.sender, _proposalDescription);
    }

    /// @notice Members can vote on governance proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _support True to support, false to oppose.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyMember notPaused proposalExists(_proposalId) votingNotEnded(governanceProposals[_proposalId].votingEndTime) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active"); // Or Pending -> Active flow
        require(!proposal.votes[msg.sender], "Already voted on this proposal");

        proposal.votes[msg.sender] = true;
        if (_support) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Admin/DAO can execute approved governance proposals.
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active || proposal.status == ProposalStatus.Passed, "Proposal is not active or passed"); // Ensure active or already passed
        require(block.number >= proposal.votingEndTime, "Voting period has not ended"); // Ensure voting ended

        if (proposal.supportVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Passed;
            // Execute the proposed change using delegatecall or similar mechanism if needed for complex changes
            (bool success,) = address(this).delegatecall(proposal.calldata); // Be extremely careful with delegatecall, security risk
            require(success, "Governance proposal execution failed");
            proposal.status = ProposalStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId, ProposalStatus.Executed);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit GovernanceProposalExecuted(_proposalId, ProposalStatus.Rejected);
        }
    }

    /// @notice Retrieves details of a governance proposal.
    /// @param _proposalId ID of the governance proposal.
    /// @return Details of the governance proposal.
    function getGovernanceProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId)
        returns (uint256 id, address proposer, string memory description, bytes memory calldataData, uint256 proposalTimestamp, ProposalStatus status, uint256 supportVotes, uint256 againstVotes, uint256 votingEndTime)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (proposal.id, proposal.proposer, proposal.description, proposal.calldata, proposal.proposalTimestamp, proposal.status, proposal.supportVotes, proposal.againstVotes, proposal.votingEndTime);
    }

    /// @notice Returns a list of all governance proposal IDs.
    /// @return Array of governance proposal IDs.
    function getAllGovernanceProposals() external view returns (uint256[] memory) {
        return allGovernanceProposals;
    }


    // -------- 3. Collaborative Art & Treasury --------

    /// @notice Initiates a collaborative art project.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Description of the project.
    function startCollaborativeProject(string memory _projectName, string memory _projectDescription) external onlyMember notPaused {
        collaborativeProjectCount++;
        CollaborativeProject storage newProject = collaborativeProjects[collaborativeProjectCount];
        newProject.id = collaborativeProjectCount;
        newProject.name = _projectName;
        newProject.description = _projectDescription;
        newProject.creator = msg.sender;
        newProject.creationTimestamp = block.timestamp;
        newProject.status = ProjectStatus.Active;
        emit CollaborativeProjectStarted(collaborativeProjectCount, _projectName, msg.sender);
    }

    /// @notice Members can contribute to ongoing collaborative projects.
    /// @param _projectId ID of the project to contribute to.
    /// @param _contributionDetails Details about the contribution.
    /// @param _ipfsContributionHash IPFS hash of the contribution data.
    function contributeToProject(uint256 _projectId, string memory _contributionDetails, string memory _ipfsContributionHash) external onlyMember notPaused projectExists(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        Contribution memory newContribution = Contribution({
            contributor: msg.sender,
            details: _contributionDetails,
            ipfsContributionHash: _ipfsContributionHash,
            contributionTimestamp: block.timestamp
        });
        project.contributions.push(newContribution);
        emit ProjectContributionMade(_projectId, msg.sender);
    }

    /// @notice Admin/DAO can finalize a collaborative project.
    /// @param _projectId ID of the project to finalize.
    function finalizeProject(uint256 _projectId) external onlyAdmin notPaused projectExists(_projectId) {
        CollaborativeProject storage project = collaborativeProjects[_projectId];
        require(project.status == ProjectStatus.Active, "Project is not active");
        project.status = ProjectStatus.Finalized;
        // Potentially mint a collaborative NFT representing the project, distributing to contributors
        // ... NFT Minting and Distribution Logic ...
        emit CollaborativeProjectFinalized(_projectId);
    }

    /// @notice Members can deposit funds into the collective's treasury.
    function depositToTreasury() external payable notPaused onlyMember {
        // Funds are directly sent to the contract address.
        // No explicit logic needed here other than modifier checks.
    }

    /// @notice Members can propose withdrawals from the treasury.
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount to withdraw in wei.
    /// @param _reason Reason for the withdrawal.
    function createTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string memory _reason) external onlyMember notPaused {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Withdrawal amount must be positive");
        require(address(this).balance >= _amount, "Insufficient treasury balance for withdrawal");

        treasuryWithdrawalProposalCount++;
        TreasuryWithdrawalProposal storage newProposal = treasuryWithdrawalProposals[treasuryWithdrawalProposalCount];
        newProposal.id = treasuryWithdrawalProposalCount;
        newProposal.proposer = msg.sender;
        newProposal.recipient = _recipient;
        newProposal.amount = _amount;
        newProposal.reason = _reason;
        newProposal.proposalTimestamp = block.timestamp;
        newProposal.status = ProposalStatus.Active; // Or Pending -> Active flow
        newProposal.votingEndTime = block.number + governanceVotingDuration; // Use governance voting duration for treasury proposals

        emit TreasuryWithdrawalProposalCreated(treasuryWithdrawalProposalCount, msg.sender, _recipient, _amount);
    }

    /// @notice Members vote on treasury withdrawal proposals.
    /// @param _proposalId ID of the treasury withdrawal proposal.
    /// @param _support True to support, false to oppose.
    function voteOnTreasuryWithdrawal(uint256 _proposalId, bool _support) external onlyMember notPaused withdrawalProposalExists(_proposalId) votingNotEnded(treasuryWithdrawalProposals[_proposalId].votingEndTime) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active");
        require(!proposal.votes[msg.sender], "Already voted on this proposal");

        proposal.votes[msg.sender] = true;
        if (_support) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }
        emit TreasuryWithdrawalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Admin/DAO executes approved treasury withdrawal proposals.
    /// @param _proposalId ID of the treasury withdrawal proposal to execute.
    function executeTreasuryWithdrawal(uint256 _proposalId) external onlyAdmin notPaused withdrawalProposalExists(_proposalId) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active || proposal.status == ProposalStatus.Passed, "Proposal is not active or passed"); // Ensure active or already passed
        require(block.number >= proposal.votingEndTime, "Voting period has not ended"); // Ensure voting ended

        if (proposal.supportVotes > proposal.againstVotes) {
            proposal.status = ProposalStatus.Passed;
            (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
            require(success, "Treasury withdrawal failed");
            proposal.status = ProposalStatus.Executed;
            emit TreasuryWithdrawalExecuted(_proposalId, ProposalStatus.Executed, proposal.recipient, proposal.amount);
        } else {
            proposal.status = ProposalStatus.Rejected;
            emit TreasuryWithdrawalExecuted(_proposalId, ProposalStatus.Rejected, proposal.recipient, proposal.amount);
        }
    }

    /// @notice Returns the current balance of the collective's treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // -------- 4. Advanced & Trendy Features --------

    /// @notice Dynamically sets the voting duration for art submissions.
    /// @param _durationInBlocks New voting duration in blocks.
    function setSubmissionVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        submissionVotingDuration = _durationInBlocks;
        emit SubmissionVotingDurationSet(_durationInBlocks);
    }

    /// @notice Dynamically sets the voting duration for governance proposals.
    /// @param _durationInBlocks New voting duration in blocks.
    function setGovernanceVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        governanceVotingDuration = _durationInBlocks;
        emit GovernanceVotingDurationSet(_durationInBlocks);
    }

    /// @notice Sets a membership fee (payable in native token) for joining the collective.
    /// @param _fee Membership fee in wei.
    function setMembershipFee(uint256 _fee) external onlyAdmin notPaused {
        membershipFee = _fee;
        emit MembershipFeeSet(_fee);
    }

    /// @notice Allows the contract admin to withdraw accumulated membership fees.
    function withdrawMembershipFee() external onlyAdmin notPaused {
        uint256 balance = address(this).balance;
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Membership fee withdrawal failed");
        emit MembershipFeeWithdrawn(admin, balance);
    }

    /// @notice Sets the royalty percentage applied to secondary sales of collective NFTs (concept).
    /// @param _percentage Royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _percentage) external onlyAdmin notPaused {
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_percentage);
    }

    /// @notice A circuit breaker function to pause critical contract functionalities in case of emergency (admin-only).
    function emergencyShutdown() external onlyAdmin notPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract after an emergency shutdown (admin-only).
    function unpauseContract() external onlyAdmin {
        require(contractPaused, "Contract is not paused");
        contractPaused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```