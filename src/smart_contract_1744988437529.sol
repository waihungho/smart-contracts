```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative Content Creation
 * @author Bard (Inspired by user request)
 * @notice This smart contract implements a DAO focused on collaborative content creation,
 * featuring advanced concepts like quadratic voting, reputation-based governance,
 * dynamic role assignments, and NFT-based content licensing. It aims to be a unique
 * and feature-rich example, avoiding duplication of common open-source contracts.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Roles:**
 *    - `joinDAO()`: Allows users to request membership, subject to approval.
 *    - `approveMembership(address _member)`: Admin/Role-holders approve membership requests.
 *    - `rejectMembership(address _member)`: Admin/Role-holders reject membership requests.
 *    - `leaveDAO()`: Allows members to voluntarily leave the DAO.
 *    - `kickMember(address _member)`: Admin/Role-holders can remove a member (governance vote maybe needed in future iterations).
 *    - `assignRole(address _member, Role _role)`: Assigns specific roles to members (Content Creator, Editor, Reviewer, etc.).
 *    - `revokeRole(address _member, Role _role)`: Revokes roles from members.
 *    - `getMemberRoles(address _member)`: Returns the roles of a member.
 *    - `isMember(address _user)`: Checks if an address is a member.
 *    - `hasRole(address _user, Role _role)`: Checks if a member has a specific role.
 *
 * **2. Content Proposal & Management:**
 *    - `proposeContent(string memory _title, string memory _description, string memory _contentHash)`: Members propose content for creation.
 *    - `voteOnContentProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight)`: Members vote on content proposals using quadratic voting.
 *    - `getContentProposalState(uint256 _proposalId)`: Gets the current state of a content proposal.
 *    - `getContentProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a content proposal.
 *    - `submitContentRevision(uint256 _proposalId, string memory _revisedContentHash)`: Content creators submit revisions based on feedback.
 *    - `approveContentRevision(uint256 _proposalId)`: Editors/Reviewers approve content revisions.
 *    - `finalizeContent(uint256 _proposalId)`: Finalizes content after approval, mints an NFT license, and makes it available.
 *    - `getContentNFT(uint256 _contentId)`: Retrieves the NFT associated with finalized content.
 *
 * **3. Reputation & Governance:**
 *    - `increaseReputation(address _member, uint256 _amount)`:  Admin/Role-holders can reward members with reputation points.
 *    - `decreaseReputation(address _member, uint256 _amount)`: Admin/Role-holders can penalize members with reputation points.
 *    - `getMemberReputation(address _member)`: Returns the reputation points of a member.
 *    - `setReputationThresholdForRole(Role _role, uint256 _threshold)`: Sets the reputation threshold required for specific roles.
 *    - `proposeGovernanceChange(string memory _description, bytes memory _data)`: Members propose changes to DAO governance parameters.
 *    - `voteOnGovernanceChange(uint256 _proposalId, bool _approve, uint256 _voteWeight)`: Members vote on governance proposals.
 *    - `executeGovernanceChange(uint256 _proposalId)`: Executes approved governance changes.
 *    - `getGovernanceProposalState(uint256 _proposalId)`: Gets the state of a governance proposal.
 *
 * **4. Utility & Settings:**
 *    - `pauseContract()`: Admin function to pause the contract in case of emergency.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `withdrawFunds(address payable _recipient, uint256 _amount)`: Admin function to withdraw contract balance.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set default voting duration.
 *    - `setQuorumPercentage(uint256 _percentage)`: Admin function to set quorum percentage for proposals.
 */
contract ContentCreationDAO {
    // --- Enums and Structs ---

    enum Role {
        MEMBER,
        CONTENT_CREATOR,
        EDITOR,
        REVIEWER,
        ADMIN
    }

    enum ProposalState {
        PENDING,
        ACTIVE,
        REJECTED,
        APPROVED,
        EXECUTED
    }

    struct ContentProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string contentHash; // IPFS hash or similar content identifier
        ProposalState state;
        uint256 startTime;
        uint256 endTime;
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => uint256) votes; // Voter address => vote weight (for quadratic voting)
        string currentContentHash; // Latest content hash, updated through revisions
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes data; // Encoded data for the governance change
        ProposalState state;
        uint256 startTime;
        uint256 endTime;
        uint256 positiveVotes;
        uint256 negativeVotes;
        mapping(address => uint256) votes;
    }

    struct ContentNFT {
        uint256 contentId;
        string metadataURI; // URI pointing to content metadata (e.g., IPFS link)
    }

    // --- State Variables ---

    address public admin;
    bool public paused;

    mapping(address => bool) public isMember;
    mapping(address => mapping(Role => bool)) public memberRoles;
    mapping(address => uint256) public memberReputation;
    mapping(Role => uint256) public reputationThresholdForRole;

    ContentProposal[] public contentProposals;
    uint256 public contentProposalCounter;

    GovernanceProposal[] public governanceProposals;
    uint256 public governanceProposalCounter;

    mapping(uint256 => ContentNFT) public contentNFTs;
    uint256 public contentNFTCounter;

    uint256 public votingDurationInBlocks = 100; // Default voting duration
    uint256 public quorumPercentage = 51; // Default quorum percentage

    // --- Events ---

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed member);
    event MemberLeft(address indexed member);
    event MemberKicked(address indexed member);
    event RoleAssigned(address indexed member, Role role);
    event RoleRevoked(address indexed member, Role role);
    event ReputationIncreased(address indexed member, uint256 amount);
    event ReputationDecreased(address indexed member, uint256 amount);

    event ContentProposalCreated(uint256 proposalId, address proposer, string title);
    event ContentProposalVoted(uint256 proposalId, address voter, bool approve, uint256 voteWeight);
    event ContentProposalStateUpdated(uint256 proposalId, ProposalState newState);
    event ContentRevisionSubmitted(uint256 proposalId, string revisedContentHash);
    event ContentRevisionApproved(uint256 proposalId);
    event ContentFinalized(uint256 contentId, uint256 proposalId, string contentHash);
    event ContentNFTMinted(uint256 contentId, address minter, string metadataURI);

    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool approve, uint256 voteWeight);
    event GovernanceProposalStateUpdated(uint256 proposalId, ProposalState newState);
    event GovernanceChangeExecuted(uint256 proposalId);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event FundsWithdrawn(address recipient, uint256 amount);
    event VotingDurationSet(uint256 durationInBlocks);
    event QuorumPercentageSet(uint256 percentage);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(hasRole(msg.sender, _role), "Insufficient role.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= contentProposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validGovernanceProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= governanceProposalCounter, "Invalid governance proposal ID.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        memberRoles[admin][Role.ADMIN] = true;
        memberRoles[admin][Role.MEMBER] = true; // Admin is also a member by default
        isMember[admin] = true;
        memberReputation[admin] = 100; // Initial reputation for admin
        reputationThresholdForRole[Role.CONTENT_CREATOR] = 10;
        reputationThresholdForRole[Role.EDITOR] = 20;
        reputationThresholdForRole[Role.REVIEWER] = 15;
        reputationThresholdForRole[Role.ADMIN] = 50; // Higher threshold for admin-level actions
    }

    // --- 1. Membership & Roles ---

    function joinDAO() external whenNotPaused {
        require(!isMember[msg.sender], "Already a member.");
        emit MembershipRequested(msg.sender);
        // In a real-world scenario, you might add a membership request queue or voting process here.
        // For simplicity, membership is initially granted by admin/role-holders.
    }

    function approveMembership(address _member) external onlyRole(Role.ADMIN) whenNotPaused {
        require(!isMember[_member], "Address is already a member.");
        isMember[_member] = true;
        memberRoles[_member][Role.MEMBER] = true;
        memberReputation[_member] = 1; // Initial reputation for new members
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) external onlyRole(Role.ADMIN) whenNotPaused {
        // In a more complex system, you might want to track rejected requests.
        emit MembershipRejected(_member);
    }

    function leaveDAO() external onlyMember whenNotPaused {
        isMember[msg.sender] = false;
        delete memberRoles[msg.sender];
        delete memberReputation[msg.sender];
        emit MemberLeft(msg.sender);
    }

    function kickMember(address _member) external onlyRole(Role.ADMIN) whenNotPaused {
        require(isMember[_member] && _member != admin, "Invalid member to kick."); // Cannot kick admin
        isMember[_member] = false;
        delete memberRoles[_member];
        delete memberReputation[_member];
        emit MemberKicked(_member);
        // In a real-world scenario, this might require a governance vote.
    }

    function assignRole(address _member, Role _role) public onlyRole(Role.ADMIN) whenNotPaused {
        require(isMember[_member], "Address is not a member.");
        require(memberReputation[_member] >= reputationThresholdForRole[_role] || msg.sender == admin, "Member reputation is too low for this role.");
        memberRoles[_member][_role] = true;
        emit RoleAssigned(_member, _role);
    }

    function revokeRole(address _member, Role _role) public onlyRole(Role.ADMIN) whenNotPaused {
        require(isMember[_member], "Address is not a member.");
        delete memberRoles[_member][_role];
        emit RoleRevoked(_member, _role);
    }

    function getMemberRoles(address _member) external view returns (Role[] memory) {
        Role[] memory roles = new Role[](5); // Max 5 roles defined
        uint256 roleCount = 0;
        if (memberRoles[_member][Role.MEMBER]) roles[roleCount++] = Role.MEMBER;
        if (memberRoles[_member][Role.CONTENT_CREATOR]) roles[roleCount++] = Role.CONTENT_CREATOR;
        if (memberRoles[_member][Role.EDITOR]) roles[roleCount++] = Role.EDITOR;
        if (memberRoles[_member][Role.REVIEWER]) roles[roleCount++] = Role.REVIEWER;
        if (memberRoles[_member][Role.ADMIN]) roles[roleCount++] = Role.ADMIN;

        Role[] memory memberRolesArray = new Role[](roleCount);
        for (uint256 i = 0; i < roleCount; i++) {
            memberRolesArray[i] = roles[i];
        }
        return memberRolesArray;
    }

    function isMember(address _user) external view returns (bool) {
        return isMember[_user];
    }

    function hasRole(address _user, Role _role) public view returns (bool) {
        return memberRoles[_user][_role];
    }

    // --- 2. Content Proposal & Management ---

    function proposeContent(string memory _title, string memory _description, string memory _contentHash) external onlyRole(Role.CONTENT_CREATOR) whenNotPaused {
        contentProposalCounter++;
        ContentProposal storage proposal = contentProposals.push();
        proposal.id = contentProposalCounter;
        proposal.proposer = msg.sender;
        proposal.title = _title;
        proposal.description = _description;
        proposal.contentHash = _contentHash;
        proposal.state = ProposalState.PENDING;
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDurationInBlocks;
        proposal.currentContentHash = _contentHash; // Initial content hash
        emit ContentProposalCreated(contentProposalCounter, msg.sender, _title);
        emit ContentProposalStateUpdated(contentProposalCounter, ProposalState.PENDING);
    }

    function voteOnContentProposal(uint256 _proposalId, bool _approve, uint256 _voteWeight) external onlyMember validProposalId(_proposalId) whenNotPaused {
        ContentProposal storage proposal = contentProposals[_proposalId - 1]; // Adjust index
        require(proposal.state == ProposalState.PENDING, "Proposal is not pending.");
        require(block.number <= proposal.endTime, "Voting period ended.");
        require(proposal.votes[msg.sender] == 0, "Already voted.");

        // Quadratic Voting: Cost is square of vote weight, but for simplicity, we'll use voteWeight directly.
        // In a real implementation, you'd implement quadratic voting logic here, potentially involving a voting token.
        require(_voteWeight > 0, "Vote weight must be positive.");

        proposal.votes[msg.sender] = _voteWeight;

        if (_approve) {
            proposal.positiveVotes += _voteWeight;
        } else {
            proposal.negativeVotes += _voteWeight;
        }

        emit ContentProposalVoted(_proposalId, msg.sender, _approve, _voteWeight);

        // Check if voting period is over and update proposal state
        if (block.number >= proposal.endTime) {
            _updateContentProposalState(_proposalId);
        }
    }

    function getContentProposalState(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalState) {
        return contentProposals[_proposalId - 1].state;
    }

    function getContentProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (ContentProposal memory) {
        return contentProposals[_proposalId - 1];
    }

    function submitContentRevision(uint256 _proposalId, string memory _revisedContentHash) external onlyRole(Role.CONTENT_CREATOR) validProposalId(_proposalId) whenNotPaused {
        ContentProposal storage proposal = contentProposals[_proposalId - 1];
        require(proposal.proposer == msg.sender, "Only proposer can submit revision.");
        require(proposal.state == ProposalState.PENDING || proposal.state == ProposalState.REJECTED, "Proposal must be pending or rejected for revision.");
        proposal.currentContentHash = _revisedContentHash;
        emit ContentRevisionSubmitted(_proposalId, _revisedContentHash);
        // Optionally, reset votes and proposal state back to PENDING for re-voting.
        proposal.state = ProposalState.PENDING;
        proposal.positiveVotes = 0;
        proposal.negativeVotes = 0;
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDurationInBlocks;
        emit ContentProposalStateUpdated(_proposalId, ProposalState.PENDING);
    }

    function approveContentRevision(uint256 _proposalId) external onlyRole(Role.REVIEWER) validProposalId(_proposalId) whenNotPaused {
        ContentProposal storage proposal = contentProposals[_proposalId - 1];
        require(proposal.state == ProposalState.PENDING, "Proposal must be pending for revision approval.");
        // In a more complex system, reviewers might need to vote on revisions.
        // For simplicity, a reviewer can directly approve.
        _updateContentProposalState(_proposalId); // Update state based on current votes after revision approval.
        emit ContentRevisionApproved(_proposalId);
    }

    function finalizeContent(uint256 _proposalId) external onlyRole(Role.EDITOR) validProposalId(_proposalId) whenNotPaused {
        ContentProposal storage proposal = contentProposals[_proposalId - 1];
        require(proposal.state == ProposalState.APPROVED, "Proposal must be approved to finalize.");
        contentNFTCounter++;
        contentNFTs[contentNFTCounter] = ContentNFT({
            contentId: contentNFTCounter,
            metadataURI: proposal.currentContentHash // Content hash acts as metadata URI for simplicity
        });
        proposal.state = ProposalState.EXECUTED;
        emit ContentFinalized(contentNFTCounter, _proposalId, proposal.currentContentHash);
        emit ContentNFTMinted(contentNFTCounter, msg.sender, proposal.currentContentHash);
        emit ContentProposalStateUpdated(_proposalId, ProposalState.EXECUTED);
    }

    function getContentNFT(uint256 _contentId) external view returns (ContentNFT memory) {
        return contentNFTs[_contentId];
    }

    // --- 3. Reputation & Governance ---

    function increaseReputation(address _member, uint256 _amount) external onlyRole(Role.ADMIN) whenNotPaused {
        require(isMember[_member], "Address is not a member.");
        memberReputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    function decreaseReputation(address _member, uint256 _amount) external onlyRole(Role.ADMIN) whenNotPaused {
        require(isMember[_member], "Address is not a member.");
        require(memberReputation[_member] >= _amount, "Reputation cannot be negative.");
        memberReputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    function setReputationThresholdForRole(Role _role, uint256 _threshold) external onlyAdmin whenNotPaused {
        reputationThresholdForRole[_role] = _threshold;
    }

    function proposeGovernanceChange(string memory _description, bytes memory _data) external onlyRole(Role.ADMIN) whenNotPaused {
        governanceProposalCounter++;
        GovernanceProposal storage proposal = governanceProposals.push();
        proposal.id = governanceProposalCounter;
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.data = _data;
        proposal.state = ProposalState.PENDING;
        proposal.startTime = block.number;
        proposal.endTime = block.number + votingDurationInBlocks;
        emit GovernanceProposalCreated(governanceProposalCounter, msg.sender, _description);
        emit GovernanceProposalStateUpdated(governanceProposalCounter, ProposalState.PENDING);
    }

    function voteOnGovernanceChange(uint256 _proposalId, bool _approve, uint256 _voteWeight) external onlyMember validGovernanceProposalId(_proposalId) whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId - 1];
        require(proposal.state == ProposalState.PENDING, "Governance proposal is not pending.");
        require(block.number <= proposal.endTime, "Voting period ended.");
        require(proposal.votes[msg.sender] == 0, "Already voted.");

        require(_voteWeight > 0, "Vote weight must be positive.");

        proposal.votes[msg.sender] = _voteWeight;

        if (_approve) {
            proposal.positiveVotes += _voteWeight;
        } else {
            proposal.negativeVotes += _voteWeight;
        }

        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve, _voteWeight);

        if (block.number >= proposal.endTime) {
            _updateGovernanceProposalState(_proposalId);
        }
    }

    function executeGovernanceChange(uint256 _proposalId) external onlyAdmin validGovernanceProposalId(_proposalId) whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId - 1];
        require(proposal.state == ProposalState.APPROVED, "Governance proposal must be approved to execute.");
        proposal.state = ProposalState.EXECUTED;
        // In a real application, you would decode and execute the governance change data here.
        // For simplicity, we just mark it as executed.
        emit GovernanceChangeExecuted(_proposalId);
        emit GovernanceProposalStateUpdated(_proposalId, ProposalState.EXECUTED);
    }

    function getGovernanceProposalState(uint256 _proposalId) external view validGovernanceProposalId(_proposalId) returns (ProposalState) {
        return governanceProposals[_proposalId - 1].state;
    }


    // --- 4. Utility & Settings ---

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin whenNotPaused {
        votingDurationInBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    function setQuorumPercentage(uint256 _percentage) external onlyAdmin whenNotPaused {
        require(_percentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _percentage;
        emit QuorumPercentageSet(_percentage);
    }

    // --- Internal Helper Functions ---

    function _updateContentProposalState(uint256 _proposalId) internal {
        ContentProposal storage proposal = contentProposals[_proposalId - 1];
        if (proposal.state != ProposalState.PENDING) return; // Prevent re-evaluation

        uint256 totalVotes = proposal.positiveVotes + proposal.negativeVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        if (proposal.positiveVotes >= quorum && proposal.positiveVotes > proposal.negativeVotes) {
            proposal.state = ProposalState.APPROVED;
            emit ContentProposalStateUpdated(_proposalId, ProposalState.APPROVED);
        } else {
            proposal.state = ProposalState.REJECTED;
            emit ContentProposalStateUpdated(_proposalId, ProposalState.REJECTED);
        }
    }

    function _updateGovernanceProposalState(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId - 1];
        if (proposal.state != ProposalState.PENDING) return; // Prevent re-evaluation

        uint256 totalVotes = proposal.positiveVotes + proposal.negativeVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        if (proposal.positiveVotes >= quorum && proposal.positiveVotes > proposal.negativeVotes) {
            proposal.state = ProposalState.APPROVED;
            emit GovernanceProposalStateUpdated(_proposalId, ProposalState.APPROVED);
        } else {
            proposal.state = ProposalState.REJECTED;
            emit GovernanceProposalStateUpdated(_proposalId, ProposalState.REJECTED);
        }
    }
}
```