```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Reputation System
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO with advanced features including:
 *      - Dynamic Governance Parameters: Voting periods, quorum, and reputation thresholds can be adjusted through governance proposals.
 *      - Reputation System: Members gain reputation for positive contributions and lose reputation for negative actions, influencing voting power.
 *      - Skill-Based Roles:  DAO members can be assigned roles based on their skills, granting specific permissions.
 *      - Delegated Voting: Members can delegate their voting power to other trusted members.
 *      - Proposal Batching: Allows for submitting multiple actions within a single proposal for efficiency.
 *      - Emergency Pause Mechanism: Governance can pause critical functions in case of unforeseen issues.
 *      - Reputation-Based Access Control: Certain functions are restricted based on reputation levels.
 *      - Treasury Management: Securely manages DAO funds with governance-controlled spending.
 *
 * Function Summary:
 *
 * **Governance & Proposals:**
 * 1. createProposal(string _title, string _description, ProposalType _proposalType, Action[] memory _actions): Allows members to create proposals for various DAO actions.
 * 2. voteOnProposal(uint256 _proposalId, VoteOption _vote): Allows members to vote on active proposals.
 * 3. executeProposal(uint256 _proposalId): Executes a passed proposal after the voting period.
 * 4. cancelProposal(uint256 _proposalId): Allows the proposer to cancel a proposal before the voting period ends (with conditions).
 * 5. getProposalState(uint256 _proposalId): Returns the current state of a proposal (Active, Passed, Failed, Executed, Cancelled).
 * 6. getProposalDetails(uint256 _proposalId): Returns detailed information about a specific proposal.
 * 7. updateGovernanceParameter(GovernanceParameter _parameter, uint256 _newValue): Governance function to update key DAO parameters like voting periods and quorum.
 * 8. batchVote(uint256[] memory _proposalIds, VoteOption[] memory _votes): Allows members to vote on multiple proposals in a single transaction.
 * 9. pauseDAO(): Governance function to temporarily pause critical DAO functionalities.
 * 10. unpauseDAO(): Governance function to resume DAO functionalities after pausing.
 *
 * **Membership & Roles:**
 * 11. joinDAO(): Allows anyone to become a member of the DAO (potentially with initial reputation).
 * 12. leaveDAO(): Allows members to leave the DAO.
 * 13. assignRole(address _member, Role _role): Governance function to assign roles to DAO members.
 * 14. revokeRole(address _member, Role _role): Governance function to revoke roles from DAO members.
 * 15. getUserRoles(address _member): Returns the roles assigned to a specific member.
 * 16. getRolePermissions(Role _role): Returns the permissions associated with a specific role.
 *
 * **Reputation System:**
 * 17. contributeToDAO(ContributionType _contributionType, string _details): Allows members to record positive contributions to gain reputation.
 * 18. reportMisconduct(address _member, string _reportDetails): Allows members to report misconduct by other members, potentially leading to reputation loss (governance review).
 * 19. getReputation(address _member): Returns the reputation score of a member.
 * 20. stakeTokensForReputation(uint256 _amount): Allows members to stake tokens to temporarily boost their reputation (optional, and can be a governance-controlled feature).
 * 21. claimReputationRewards(): Allows members to claim rewards based on their reputation (if reward system is implemented via governance).
 *
 * **Treasury Management:**
 * 22. depositToTreasury(): Allows depositing funds into the DAO treasury.
 * 23. withdrawFromTreasury(uint256 _amount, address _recipient): Governance-controlled function to withdraw funds from the treasury for approved proposals.
 * 24. getTreasuryBalance(): Returns the current balance of the DAO treasury.
 */
pragma solidity ^0.8.0;

contract AdvancedDAO {
    // -------- Enums and Structs --------

    enum ProposalType {
        GovernanceChange,
        TreasurySpending,
        RoleAssignment,
        RoleRevocation,
        GenericAction
    }

    enum ProposalState {
        Active,
        Passed,
        Failed,
        Executed,
        Cancelled
    }

    enum VoteOption {
        Against,
        For,
        Abstain
    }

    enum GovernanceParameter {
        VotingPeriod,
        QuorumPercentage,
        ReputationThresholdForProposal,
        ReputationGainForContribution,
        ReputationLossForMisconduct
    }

    enum Role {
        Member,             // Basic DAO member
        Contributor,        // Recognized contributor
        Moderator,          // Community moderator
        Expert,             // Subject matter expert
        Governor,           // Governance role, can change parameters
        Admin              // DAO administrator (limited, for emergencies)
    }

    enum Permission {
        CreateProposal,
        Vote,
        ExecuteProposal,    // Execute certain types of proposals
        ManageRoles,        // Assign/revoke roles
        ManageGovernance,    // Change governance parameters
        AccessRestrictedData // Access to specific DAO information
    }

    enum ContributionType {
        CodeContribution,
        Documentation,
        CommunitySupport,
        Design,
        Marketing,
        BugReport,
        Other
    }

    struct Action {
        address targetContract;
        bytes data; // Function call data
        string description;
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 votingPeriod;
        uint256 quorum; // Percentage, e.g., 51 for 51%
        mapping(address => VoteOption) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalState state;
        Action[] actions;
    }

    // -------- State Variables --------

    address public governor; // Initial governor, can be changed through governance
    mapping(address => bool) public isMember;
    mapping(address => uint256) public reputation;
    mapping(address => mapping(Role => bool)) public memberRoles;
    mapping(Role => Permission[]) public rolePermissions;
    Proposal[] public proposals;
    uint256 public proposalCount;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 51; // Default quorum percentage
    uint256 public reputationThresholdForProposal = 10; // Minimum reputation to create proposals
    uint256 public reputationGainForContribution = 5; // Reputation gained for a standard contribution
    uint256 public reputationLossForMisconduct = 10; // Reputation lost for misconduct

    bool public paused = false; // Emergency pause state

    mapping(address => address) public voteDelegation; // Member can delegate voting power

    mapping(address => uint256) public treasuryBalance; // DAO Treasury balance

    // -------- Events --------

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event GovernanceParameterUpdated(GovernanceParameter parameter, uint256 newValue);
    event MemberJoined(address member);
    event MemberLeft(address member);
    event RoleAssigned(address member, Role role, address assignedBy);
    event RoleRevoked(address member, Role role, address revokedBy);
    event ReputationIncreased(address member, uint256 amount, ContributionType contributionType);
    event ReputationDecreased(address member, uint256 amount, string reason);
    event DAOPaused(address governor);
    event DAOUnpaused(address governor);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount, address withdrawnBy);

    // -------- Modifiers --------

    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAO member");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor || hasRole(msg.sender, Role.Governor) || hasRole(msg.sender, Role.Admin), "Not a governor or admin");
        _;
    }

    modifier onlyRole(Role _role) {
        require(hasRole(msg.sender, _role) || hasRole(msg.sender, Role.Admin), "Insufficient permissions");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is paused");
        _;
    }

    // -------- Constructor --------

    constructor() {
        governor = msg.sender; // Initial governor is the contract deployer
        isMember[msg.sender] = true; // Deployer is also the first member
        assignRole(msg.sender, Role.Governor); // Deployer gets governor role
        assignRole(msg.sender, Role.Admin); // Deployer gets admin role for initial setup

        // Initialize default role permissions (example - customize as needed)
        rolePermissions[Role.Member] = [Permission.CreateProposal, Permission.Vote];
        rolePermissions[Role.Contributor] = [Permission.CreateProposal, Permission.Vote]; // Contributor has same base permissions as member by default, can add more.
        rolePermissions[Role.Moderator] = [Permission.CreateProposal, Permission.Vote]; // Example: Moderators could have permissions to manage content in a forum (if integrated)
        rolePermissions[Role.Expert] = [Permission.CreateProposal, Permission.Vote]; // Experts could have permissions to review technical proposals
        rolePermissions[Role.Governor] = [Permission.CreateProposal, Permission.Vote, Permission.ManageGovernance, Permission.ManageRoles, Permission.ExecuteProposal];
        rolePermissions[Role.Admin] = [Permission.CreateProposal, Permission.Vote, Permission.ManageGovernance, Permission.ManageRoles, Permission.ExecuteProposal, Permission.AccessRestrictedData]; // Admin has all permissions

        treasuryBalance[address(this)] = 0; // Initialize treasury balance to 0
    }

    // -------- Governance & Proposal Functions --------

    /// @notice Creates a new proposal.
    /// @param _title Title of the proposal.
    /// @param _description Detailed description of the proposal.
    /// @param _proposalType Type of proposal.
    /// @param _actions Array of actions to be executed if the proposal passes.
    function createProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        Action[] memory _actions
    ) public onlyMember notPaused {
        require(reputation[msg.sender] >= reputationThresholdForProposal, "Insufficient reputation to create proposal");
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty");
        require(_actions.length > 0, "Proposal must include at least one action");

        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            votingPeriod: votingPeriod,
            quorum: quorumPercentage,
            votes: mapping(address => VoteOption)(),
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            actions: _actions
        });

        proposals.push(newProposal);
        proposalCount++;

        emit ProposalCreated(proposalCount - 1, _proposalType, msg.sender, _title);
    }

    /// @notice Allows members to vote on an active proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote Vote option (For, Against, Abstain).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote) public onlyMember notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        require(proposals[_proposalId].votes[msg.sender] == VoteOption.Abstain || proposals[_proposalId].votes[msg.sender] == VoteOption.Against || proposals[_proposalId].votes[msg.sender] == VoteOption.For || proposals[_proposalId].votes[msg.sender] == VoteOption.Abstain, "Already voted on this proposal"); // Ensure only one vote per member
        require(block.timestamp <= proposals[_proposalId].startTime + proposals[_proposalId].votingPeriod, "Voting period has ended");

        address voter = msg.sender;
        if (voteDelegation[msg.sender] != address(0)) {
            voter = voteDelegation[msg.sender]; // Use delegated voter if delegation is set
        }

        proposals[_proposalId].votes[voter] = _vote;

        if (_vote == VoteOption.For) {
            proposals[_proposalId].forVotes++;
        } else if (_vote == VoteOption.Against) {
            proposals[_proposalId].againstVotes++;
        } else if (_vote == VoteOption.Abstain) {
            proposals[_proposalId].abstainVotes++;
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a proposal if it has passed the voting period and quorum.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public notPaused proposalExists(_proposalId) {
        require(proposals[_proposalId].state == ProposalState.Passed, "Proposal not passed");
        require(block.timestamp > proposals[_proposalId].startTime + proposals[_proposalId].votingPeriod, "Voting period not ended");

        uint256 totalVotes = proposals[_proposalId].forVotes + proposals[_proposalId].againstVotes + proposals[_proposalId].abstainVotes;
        uint256 quorumReached = (totalVotes * 100) / getMemberCount(); // Calculate quorum based on current member count

        require(quorumReached >= quorumPercentage, "Quorum not reached");
        require(proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes, "Proposal not passed: more against votes");

        proposals[_proposalId].state = ProposalState.Executed;

        for (uint256 i = 0; i < proposals[_proposalId].actions.length; i++) {
            Action memory action = proposals[_proposalId].actions[i];
            (bool success, ) = action.targetContract.call(action.data);
            require(success, "Action execution failed");
        }

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the proposer to cancel a proposal before the voting period ends.
    /// @param _proposalId ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) public proposalExists(_proposalId) proposalActive(_proposalId) {
        require(msg.sender == proposals[_proposalId].proposer, "Only proposer can cancel");
        require(block.timestamp < proposals[_proposalId].startTime + proposals[_proposalId].votingPeriod, "Voting period already ended");

        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Gets the current state of a proposal.
    /// @param _proposalId ID of the proposal.
    /// @return The state of the proposal (Active, Passed, Failed, Executed, Cancelled).
    function getProposalState(uint256 _proposalId) public view proposalExists(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Gets detailed information about a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Governance function to update DAO parameters.
    /// @param _parameter Parameter to update (VotingPeriod, QuorumPercentage, etc.).
    /// @param _newValue New value for the parameter.
    function updateGovernanceParameter(GovernanceParameter _parameter, uint256 _newValue) public onlyGovernor notPaused {
        require(_newValue > 0, "New value must be positive");

        if (_parameter == GovernanceParameter.VotingPeriod) {
            votingPeriod = _newValue;
        } else if (_parameter == GovernanceParameter.QuorumPercentage) {
            require(_newValue <= 100, "Quorum percentage cannot exceed 100");
            quorumPercentage = _newValue;
        } else if (_parameter == GovernanceParameter.ReputationThresholdForProposal) {
            reputationThresholdForProposal = _newValue;
        } else if (_parameter == GovernanceParameter.ReputationGainForContribution) {
            reputationGainForContribution = _newValue;
        } else if (_parameter == GovernanceParameter.ReputationLossForMisconduct) {
            reputationLossForMisconduct = _newValue;
        } else {
            revert("Invalid governance parameter");
        }

        emit GovernanceParameterUpdated(_parameter, _newValue);
    }

    /// @notice Allows members to vote on multiple proposals in a single transaction.
    /// @param _proposalIds Array of proposal IDs to vote on.
    /// @param _votes Array of vote options corresponding to each proposal ID.
    function batchVote(uint256[] memory _proposalIds, VoteOption[] memory _votes) public onlyMember notPaused {
        require(_proposalIds.length == _votes.length, "Proposal IDs and votes arrays must have the same length");
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            voteOnProposal(_proposalIds[i], _votes[i]);
        }
    }

    /// @notice Governance function to pause critical DAO functionalities in case of emergency.
    function pauseDAO() public onlyGovernor notPaused {
        paused = true;
        emit DAOPaused(msg.sender);
    }

    /// @notice Governance function to unpause DAO functionalities after emergency.
    function unpauseDAO() public onlyGovernor {
        paused = false;
        emit DAOUnpaused(msg.sender);
    }


    // -------- Membership & Role Functions --------

    /// @notice Allows anyone to join the DAO.
    function joinDAO() public notPaused {
        require(!isMember[msg.sender], "Already a member");
        isMember[msg.sender] = true;
        reputation[msg.sender] = 1; // Initial reputation for new members
        assignRole(msg.sender, Role.Member); // Automatically assign member role
        emit MemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the DAO.
    function leaveDAO() public onlyMember notPaused {
        isMember[msg.sender] = false;
        delete reputation[msg.sender];
        // Remove all roles for the leaving member (optional - or decide to keep roles for historical context)
        delete memberRoles[msg.sender];
        emit MemberLeft(msg.sender);
    }

    /// @notice Governance function to assign roles to DAO members.
    /// @param _member Address of the member to assign the role to.
    /// @param _role Role to assign.
    function assignRole(address _member, Role _role) public onlyGovernor notPaused {
        require(isMember[_member], "Target address is not a DAO member");
        memberRoles[_member][_role] = true;
        emit RoleAssigned(_member, _role, msg.sender);
    }

    /// @notice Governance function to revoke roles from DAO members.
    /// @param _member Address of the member to revoke the role from.
    /// @param _role Role to revoke.
    function revokeRole(address _member, Role _role) public onlyGovernor notPaused {
        require(isMember[_member], "Target address is not a DAO member");
        delete memberRoles[_member][_role];
        emit RoleRevoked(_member, _role, msg.sender);
    }

    /// @notice Gets the roles assigned to a specific member.
    /// @param _member Address of the member.
    /// @return Array of roles assigned to the member.
    function getUserRoles(address _member) public view returns (Role[] memory) {
        Role[] memory roles = new Role[](countRoles(_member));
        uint256 index = 0;
        for (uint256 i = 0; i < uint256(type(Role).max); i++) {
            Role role = Role(i);
            if (memberRoles[_member][role]) {
                roles[index] = role;
                index++;
            }
        }
        return roles;
    }

    /// @notice Gets the permissions associated with a specific role.
    /// @param _role Role to query permissions for.
    /// @return Array of permissions associated with the role.
    function getRolePermissions(Role _role) public view returns (Permission[] memory) {
        return rolePermissions[_role];
    }

    /// @dev Helper function to count the number of roles a member has.
    function countRoles(address _member) private view returns (uint256) {
        uint256 roleCount = 0;
        for (uint256 i = 0; i < uint256(type(Role).max); i++) {
            if (memberRoles[_member][Role(i)]) {
                roleCount++;
            }
        }
        return roleCount;
    }

    /// @dev Helper function to check if a member has a specific role.
    function hasRole(address _member, Role _role) public view returns (bool) {
        return memberRoles[_member][_role];
    }

    /// @dev Helper function to get the total number of DAO members.
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        // Inefficient for large DAOs, consider maintaining a member list for efficiency if needed.
        for (uint256 i = 0; i < proposalCount + 1000; i++) { // Iterate through potential member range (adjust upper bound as needed - better to maintain a member list in a real application)
           if (i < proposals.length) {
              if (isMember[proposals[i].proposer]) {
                count++;
              }
           } else if (i < proposalCount + 500) { // Example: Check some addresses within a reasonable range beyond proposal creators, adjust range or use better member tracking
               address potentialMember = address(uint160(i)); // Example - adjust address generation if needed, or use a proper member list
               if (isMember[potentialMember]) {
                   count++;
               }
           }
        }
        return count;
    }

    // -------- Reputation System Functions --------

    /// @notice Allows members to record positive contributions to gain reputation.
    /// @param _contributionType Type of contribution made.
    /// @param _details Details of the contribution.
    function contributeToDAO(ContributionType _contributionType, string memory _details) public onlyMember notPaused {
        reputation[msg.sender] += reputationGainForContribution;
        emit ReputationIncreased(msg.sender, reputationGainForContribution, _contributionType);
    }

    /// @notice Allows members to report misconduct by other members, potentially leading to reputation loss (governance review needed in a real system).
    /// @param _member Address of the member being reported.
    /// @param _reportDetails Details of the misconduct report.
    function reportMisconduct(address _member, string memory _reportDetails) public onlyMember notPaused {
        // In a real system, this would trigger a governance proposal or moderator review process.
        // For this example, we directly decrease reputation (simplified for demonstration).
        require(isMember[_member] && _member != msg.sender, "Invalid member to report");

        if (reputation[_member] >= reputationLossForMisconduct) {
            reputation[_member] -= reputationLossForMisconduct;
            emit ReputationDecreased(_member, reputationLossForMisconduct, _reportDetails);
        } else {
            reputation[_member] = 0; // Set to 0 if reputation is lower than the loss amount
            emit ReputationDecreased(_member, reputation[_member], _reportDetails); // Emit actual reputation decrease
        }
         // In a real-world scenario, reporting misconduct should initiate a proper governance process to verify the report and decide on appropriate penalties.
         // This simplified version directly decreases reputation for demonstration purposes.
    }

    /// @notice Gets the reputation score of a member.
    /// @param _member Address of the member.
    /// @return Reputation score of the member.
    function getReputation(address _member) public view returns (uint256) {
        return reputation[_member];
    }

    /// @notice Allows members to stake tokens to temporarily boost their reputation (optional feature, can be governed).
    /// @param _amount Amount of tokens to stake.
    function stakeTokensForReputation(uint256 _amount) public payable onlyMember notPaused {
        // Example: For every X tokens staked, reputation increases by Y for a certain period.
        // This is a placeholder, implement actual token staking and reputation boost logic if needed.
        require(msg.value == _amount, "Incorrect amount sent for staking"); // Simple example - sender must send ETH equal to stake amount
        reputation[msg.sender] += (_amount / 1 ether); // Example: 1 ETH staked gives 1 reputation point (adjust ratio as needed)
        // In a real system, you'd need to track staked tokens, implement unstaking, and potentially time-limited reputation boost.
        // This is a simplified demonstration.
    }

    /// @notice Allows members to claim rewards based on their reputation (optional, governed reward system).
    function claimReputationRewards() public onlyMember notPaused {
        // Example: Members with reputation above a certain threshold can claim rewards.
        // This is a placeholder, implement actual reward distribution logic based on reputation and governance.
        uint256 currentReputation = reputation[msg.sender];
        if (currentReputation >= 50) { // Example threshold - governance could set this
            uint256 rewardAmount = currentReputation / 10; // Example reward calculation - governance could define this
            payable(msg.sender).transfer(rewardAmount); // Transfer ETH as reward (example)
            // In a real system, rewards could be in other tokens, NFTs, or DAO governance rights.
            // This is a simplified demonstration.
            reputation[msg.sender] -= (rewardAmount / 1 ether) * 10; // Reduce reputation after claiming reward (example - adjust logic as needed)
            // In a real system, reward claiming and reputation adjustment logic should be carefully designed based on DAO's goals.
        } else {
            revert("Insufficient reputation to claim rewards");
        }
    }

    // -------- Treasury Management Functions --------

    /// @notice Allows depositing funds into the DAO treasury.
    function depositToTreasury() public payable {
        treasuryBalance[address(this)] += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Governance-controlled function to withdraw funds from the treasury for approved proposals.
    /// @param _amount Amount to withdraw.
    /// @param _recipient Address to receive the withdrawn funds.
    function withdrawFromTreasury(uint256 _amount, address payable _recipient) public onlyRole(Role.Governor) notPaused {
        require(treasuryBalance[address(this)] >= _amount, "Insufficient treasury balance");
        treasuryBalance[address(this)] -= _amount;
        _recipient.transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount, msg.sender);
    }

    /// @notice Returns the current balance of the DAO treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance[address(this)];
    }

    // -------- Vote Delegation --------

    /// @notice Allows a member to delegate their voting power to another member.
    /// @param _delegate Address of the member to delegate voting power to.
    function delegateVote(address _delegate) public onlyMember notPaused {
        require(isMember[_delegate], "Delegate must be a DAO member");
        require(_delegate != msg.sender, "Cannot delegate to self");
        voteDelegation[msg.sender] = _delegate;
    }

    /// @notice Removes vote delegation, reverting to direct voting.
    function removeVoteDelegation() public onlyMember notPaused {
        delete voteDelegation[msg.sender];
    }

    /// @notice Gets the address of the member a voter has delegated to, or address(0) if no delegation.
    /// @param _voter Address of the voter.
    /// @return Address of the delegate, or address(0) if no delegation.
    function getVoteDelegate(address _voter) public view returns (address) {
        return voteDelegation[_voter];
    }
}
```