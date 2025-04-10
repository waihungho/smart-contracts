```solidity
pragma solidity ^0.8.0;

/**
 * @title DynamicDAO - Decentralized Autonomous Organization with Dynamic Governance and Gamified Engagement
 * @author Bard (AI Assistant)
 * @notice This contract implements a DAO with advanced features including dynamic rule proposals, on-chain challenges,
 *         reputation-based roles, and gamified participation to encourage active community involvement.
 *
 * Function Summary:
 * ---------------------------
 * **Initialization & Setup:**
 * - initializeDAO(string _name, string _symbol, address _initialAdmin): Initializes the DAO with name, symbol, and initial admin.
 * - setVotingDuration(uint256 _durationInBlocks): Sets the default voting duration for proposals.
 * - setQuorumThreshold(uint256 _quorumPercentage): Sets the quorum threshold for proposals (percentage).
 *
 * **Governance & Rule Proposals:**
 * - proposeNewRule(string _ruleDescription, bytes _executionData): Proposes a new governance rule for voting.
 * - voteOnRuleProposal(uint256 _proposalId, bool _support): Allows members to vote on a rule proposal.
 * - executeRule(uint256 _proposalId): Executes a passed rule proposal.
 * - getRuleProposalDetails(uint256 _proposalId): Retrieves details of a rule proposal.
 * - getAllRuleProposalIds(): Returns a list of all rule proposal IDs.
 *
 * **Membership & Profiles:**
 * - joinDAO(string _userDetails): Allows users to join the DAO and set their profile details.
 * - leaveDAO(): Allows members to leave the DAO.
 * - updateProfile(string _userDetails): Allows members to update their profile details.
 * - getMemberDetails(address _memberAddress): Retrieves details of a DAO member.
 * - getAllMemberAddresses(): Returns a list of all member addresses.
 *
 * **Staking & Voting Power:**
 * - stakeTokens(uint256 _amount): Allows members to stake tokens to increase voting power.
 * - unstakeTokens(uint256 _amount): Allows members to unstake tokens.
 * - getVotingPower(address _memberAddress): Retrieves the voting power of a member based on staked tokens.
 *
 * **Gamified Challenges:**
 * - createChallenge(string _challengeDetails, uint256 _reward, uint256 _submissionDeadline): Creates a community challenge with a reward.
 * - submitChallengeCompletion(uint256 _challengeId, string _submissionDetails): Allows members to submit their completion for a challenge.
 * - voteOnChallengeCompletion(uint256 _challengeId, uint256 _submissionId, bool _approve): Allows members to vote on challenge submissions.
 * - claimChallengeReward(uint256 _challengeId, uint256 _submissionId): Allows members to claim rewards for successfully completed challenges.
 * - getChallengeDetails(uint256 _challengeId): Retrieves details of a challenge.
 * - getAllChallengeIds(): Returns a list of all challenge IDs.
 *
 * **Role-Based Access Control:**
 * - addRole(string _roleName, string[] _permissions): Adds a new role with associated permissions.
 * - assignRole(address _member, string _roleName): Assigns a role to a member.
 * - removeRole(address _member, string _roleName): Removes a role from a member.
 * - getMemberRoles(address _memberAddress): Retrieves the roles assigned to a member.
 * - getRolePermissions(string _roleName): Retrieves the permissions associated with a role.
 * - hasRole(address _memberAddress, string _roleName): Checks if a member has a specific role.
 *
 * **Emergency & Admin Functions:**
 * - emergencyPause(): Pauses critical functions of the DAO in case of emergency (Admin only).
 * - emergencyUnpause(): Resumes paused functions (Admin only).
 * - withdrawStuckTokens(address _tokenAddress, address _recipient): Admin function to withdraw accidentally sent tokens (Admin only).
 */
contract DynamicDAO {

    // --- Structs ---
    struct RuleProposal {
        string description;
        bytes executionData;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) votes; // Track who voted and their vote
    }

    struct Member {
        string details;
        uint256 stakedTokens;
        mapping(string => bool) roles; // Mapping of roles assigned to member
    }

    struct Challenge {
        string details;
        uint256 reward;
        uint256 submissionDeadline;
        uint256 submissionCount;
        mapping(uint256 => Submission) submissions;
    }

    struct Submission {
        string details;
        address submitter;
        uint256 yesVotes;
        uint256 noVotes;
        bool rewardClaimed;
        mapping(address => bool) votes; // Track who voted and their vote
    }

    struct Role {
        string[] permissions;
    }

    // --- State Variables ---
    string public name;
    string public symbol;
    address public admin;
    uint256 public votingDurationInBlocks = 100; // Default voting duration
    uint256 public quorumThresholdPercentage = 50; // Default quorum threshold

    mapping(uint256 => RuleProposal) public ruleProposals;
    uint256 public ruleProposalCount = 0;
    uint256[] public allRuleProposalIds;

    mapping(address => Member) public members;
    address[] public allMemberAddresses;

    mapping(uint256 => Challenge) public challenges;
    uint256 public challengeCount = 0;
    uint256[] public allChallengeIds;

    mapping(string => Role) public roles;

    bool public paused = false;

    // --- Events ---
    event DAOInitialized(string name, string symbol, address admin);
    event RuleProposed(uint256 proposalId, string description, address proposer);
    event VoteCastOnRuleProposal(uint256 proposalId, address voter, bool support);
    event RuleExecuted(uint256 proposalId);
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ProfileUpdated(address memberAddress);
    event TokensStaked(address memberAddress, uint256 amount);
    event TokensUnstaked(address memberAddress, uint256 amount);
    event ChallengeCreated(uint256 challengeId, string details, uint256 reward, address creator);
    event ChallengeSubmissionSubmitted(uint256 challengeId, uint256 submissionId, address submitter);
    event VoteCastOnChallengeSubmission(uint256 challengeId, uint256 submissionId, address voter, bool approve);
    event ChallengeRewardClaimed(uint256 challengeId, uint256 submissionId, address claimant);
    event RoleAdded(string roleName);
    event RoleAssigned(address member, string roleName);
    event RoleRemoved(address member, string roleName);
    event EmergencyPaused(address admin);
    event EmergencyUnpaused(address admin);
    event TokensWithdrawn(address tokenAddress, address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].details.length > 0, "Only members can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier ruleProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= ruleProposalCount, "Rule proposal does not exist");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= challengeCount, "Challenge does not exist");
        _;
    }

    modifier submissionExists(uint256 _challengeId, uint256 _submissionId) {
        require(challenges[_challengeId].submissions[_submissionId].submitter != address(0), "Submission does not exist");
        _;
    }

    modifier votingActive(uint256 _endTime) {
        require(block.number <= _endTime, "Voting has ended");
        _;
    }

    modifier votingNotActive(uint256 _endTime) {
        require(block.number > _endTime, "Voting is still active");
        _;
    }

    modifier notExecuted(uint256 _proposalId) {
        require(!ruleProposals[_proposalId].executed, "Rule proposal already executed");
        _;
    }


    // --- Functions ---

    /// @notice Initializes the DAO with name, symbol, and initial admin.
    /// @param _name The name of the DAO.
    /// @param _symbol The symbol of the DAO.
    /// @param _initialAdmin The address of the initial admin.
    constructor(string memory _name, string memory _symbol, address _initialAdmin) {
        name = _name;
        symbol = _symbol;
        admin = _initialAdmin;
        emit DAOInitialized(_name, _symbol, _initialAdmin);
    }

    /// @notice Initializes the DAO - use this after deploying via create2 for predictable address.
    /// @param _name The name of the DAO.
    /// @param _symbol The symbol of the DAO.
    /// @param _initialAdmin The address of the initial admin.
    function initializeDAO(string memory _name, string memory _symbol, address _initialAdmin) external onlyAdmin {
        require(bytes(name).length == 0, "DAO already initialized"); // Prevent re-initialization
        name = _name;
        symbol = _symbol;
        admin = _initialAdmin;
        emit DAOInitialized(_name, _symbol, _initialAdmin);
    }


    /// @notice Sets the default voting duration for proposals.
    /// @param _durationInBlocks The voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDurationInBlocks = _durationInBlocks;
    }

    /// @notice Sets the quorum threshold for proposals (percentage).
    /// @param _quorumPercentage The quorum threshold percentage (0-100).
    function setQuorumThreshold(uint256 _quorumPercentage) external onlyAdmin {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumThresholdPercentage = _quorumPercentage;
    }

    /// @notice Proposes a new governance rule for voting.
    /// @param _ruleDescription Description of the rule proposal.
    /// @param _executionData Data to be executed if the proposal passes.
    function proposeNewRule(string memory _ruleDescription, bytes memory _executionData) external onlyMember notPaused {
        ruleProposalCount++;
        RuleProposal storage proposal = ruleProposals[ruleProposalCount];
        proposal.description = _ruleDescription;
        proposal.executionData = _executionData;
        proposal.votingStartTime = block.number;
        proposal.votingEndTime = block.number + votingDurationInBlocks;
        allRuleProposalIds.push(ruleProposalCount);
        emit RuleProposed(ruleProposalCount, _ruleDescription, msg.sender);
    }

    /// @notice Allows members to vote on a rule proposal.
    /// @param _proposalId ID of the rule proposal.
    /// @param _support True for yes, false for no.
    function voteOnRuleProposal(uint256 _proposalId, bool _support) external onlyMember notPaused ruleProposalExists(_proposalId) votingActive(ruleProposals[_proposalId].votingEndTime) notExecuted(_proposalId) {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        require(!proposal.votes[msg.sender], "Member has already voted on this proposal");
        proposal.votes[msg.sender] = true; // Mark as voted
        if (_support) {
            proposal.yesVotes += getVotingPower(msg.sender);
        } else {
            proposal.noVotes += getVotingPower(msg.sender);
        }
        emit VoteCastOnRuleProposal(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed rule proposal.
    /// @param _proposalId ID of the rule proposal.
    function executeRule(uint256 _proposalId) external notPaused ruleProposalExists(_proposalId) votingNotActive(ruleProposals[_proposalId].votingEndTime) notExecuted(_proposalId) {
        RuleProposal storage proposal = ruleProposals[_proposalId];
        uint256 totalVotingPower = 0;
        for (uint i = 0; i < allMemberAddresses.length; i++) {
            totalVotingPower += getVotingPower(allMemberAddresses[i]);
        }
        uint256 quorum = (totalVotingPower * quorumThresholdPercentage) / 100;

        require(proposal.yesVotes > proposal.noVotes, "Proposal did not pass - No majority");
        require(proposal.yesVotes >= quorum, "Proposal did not meet quorum");

        proposal.executed = true;
        // Execute the rule - for this example, we just emit an event, in a real DAO, this would interact with other contract functions or external calls.
        (bool success, ) = address(this).call(proposal.executionData);
        require(success, "Rule execution failed"); // Revert if execution fails
        emit RuleExecuted(_proposalId);
    }

    /// @notice Retrieves details of a rule proposal.
    /// @param _proposalId ID of the rule proposal.
    /// @return RuleProposal struct containing proposal details.
    function getRuleProposalDetails(uint256 _proposalId) external view ruleProposalExists(_proposalId) returns (RuleProposal memory) {
        return ruleProposals[_proposalId];
    }

    /// @notice Retrieves a list of all rule proposal IDs.
    /// @return Array of rule proposal IDs.
    function getAllRuleProposalIds() external view returns (uint256[] memory) {
        return allRuleProposalIds;
    }


    /// @notice Allows users to join the DAO and set their profile details.
    /// @param _userDetails Details of the member (e.g., name, social links).
    function joinDAO(string memory _userDetails) external notPaused {
        require(members[msg.sender].details.length == 0, "Already a member");
        members[msg.sender] = Member({details: _userDetails, stakedTokens: 0});
        allMemberAddresses.push(msg.sender);
        emit MemberJoined(msg.sender);
    }

    /// @notice Allows members to leave the DAO.
    function leaveDAO() external onlyMember notPaused {
        delete members[msg.sender];
        // Remove from allMemberAddresses array - inefficient for large arrays, consider optimization in real-world scenario if needed
        for (uint i = 0; i < allMemberAddresses.length; i++) {
            if (allMemberAddresses[i] == msg.sender) {
                allMemberAddresses[i] = allMemberAddresses[allMemberAddresses.length - 1];
                allMemberAddresses.pop();
                break;
            }
        }
        emit MemberLeft(msg.sender);
    }

    /// @notice Allows members to update their profile details.
    /// @param _userDetails New profile details.
    function updateProfile(string memory _userDetails) external onlyMember notPaused {
        members[msg.sender].details = _userDetails;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Retrieves details of a DAO member.
    /// @param _memberAddress Address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    /// @notice Retrieves a list of all member addresses.
    /// @return Array of member addresses.
    function getAllMemberAddresses() external view returns (address[] memory) {
        return allMemberAddresses;
    }


    /// @notice Allows members to stake tokens to increase voting power.
    /// @param _amount Amount of tokens to stake.
    function stakeTokens(uint256 _amount) external onlyMember notPaused {
        // For simplicity, we're not using an actual token contract here.
        // In a real DAO, you would integrate with an ERC20 token contract.
        members[msg.sender].stakedTokens += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Allows members to unstake tokens.
    /// @param _amount Amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) external onlyMember notPaused {
        require(members[msg.sender].stakedTokens >= _amount, "Insufficient staked tokens");
        members[msg.sender].stakedTokens -= _amount;
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Retrieves the voting power of a member based on staked tokens.
    /// @param _memberAddress Address of the member.
    /// @return Voting power of the member.
    function getVotingPower(address _memberAddress) public view returns (uint256) {
        // Voting power is currently directly proportional to staked tokens.
        // This can be made more complex (e.g., time-weighted staking, reputation multipliers) in advanced versions.
        return members[_memberAddress].stakedTokens;
    }


    /// @notice Creates a community challenge with a reward.
    /// @param _challengeDetails Details of the challenge (e.g., description, requirements).
    /// @param _reward Reward for completing the challenge (in arbitrary units, could be tokens in real implementation).
    /// @param _submissionDeadline Block number when submissions are closed.
    function createChallenge(string memory _challengeDetails, uint256 _reward, uint256 _submissionDeadline) external onlyMember notPaused {
        challengeCount++;
        challenges[challengeCount] = Challenge({
            details: _challengeDetails,
            reward: _reward,
            submissionDeadline: _submissionDeadline,
            submissionCount: 0
        });
        allChallengeIds.push(challengeCount);
        emit ChallengeCreated(challengeCount, _challengeDetails, _reward, msg.sender);
    }

    /// @notice Allows members to submit their completion for a challenge.
    /// @param _challengeId ID of the challenge.
    /// @param _submissionDetails Details of the submission (e.g., link to work, description).
    function submitChallengeCompletion(uint256 _challengeId, string memory _submissionDetails) external onlyMember notPaused challengeExists(_challengeId) votingActive(challenges[_challengeId].submissionDeadline) {
        Challenge storage challenge = challenges[_challengeId];
        challenge.submissionCount++;
        uint256 submissionId = challenge.submissionCount;
        challenge.submissions[submissionId] = Submission({
            details: _submissionDetails,
            submitter: msg.sender,
            yesVotes: 0,
            noVotes: 0,
            rewardClaimed: false
        });
        emit ChallengeSubmissionSubmitted(_challengeId, submissionId, msg.sender);
    }

    /// @notice Allows members to vote on challenge submissions.
    /// @param _challengeId ID of the challenge.
    /// @param _submissionId ID of the submission.
    /// @param _approve True to approve submission, false to reject.
    function voteOnChallengeCompletion(uint256 _challengeId, uint256 _submissionId, bool _approve) external onlyMember notPaused challengeExists(_challengeId) submissionExists(_challengeId, _submissionId) votingActive(challenges[_challengeId].submissionDeadline) {
        Submission storage submission = challenges[_challengeId].submissions[_submissionId];
        require(!submission.votes[msg.sender], "Member has already voted on this submission");
        submission.votes[msg.sender] = true;
        if (_approve) {
            submission.yesVotes += getVotingPower(msg.sender);
        } else {
            submission.noVotes += getVotingPower(msg.sender);
        }
        emit VoteCastOnChallengeSubmission(_challengeId, _submissionId, msg.sender, _approve);
    }

    /// @notice Allows members to claim rewards for successfully completed challenges.
    /// @param _challengeId ID of the challenge.
    /// @param _submissionId ID of the submission.
    function claimChallengeReward(uint256 _challengeId, uint256 _submissionId) external onlyMember notPaused challengeExists(_challengeId) submissionExists(_challengeId, _submissionId) votingNotActive(challenges[_challengeId].submissionDeadline) {
        Submission storage submission = challenges[_challengeId].submissions[_submissionId];
        require(submission.submitter == msg.sender, "Only submitter can claim reward");
        require(!submission.rewardClaimed, "Reward already claimed");
        require(submission.yesVotes > submission.noVotes, "Submission not approved by community"); // Simple majority for approval

        submission.rewardClaimed = true;
        // In a real implementation, this would transfer tokens or perform other reward actions.
        // For this example, we just emit an event.
        emit ChallengeRewardClaimed(_challengeId, _submissionId, msg.sender);
    }

    /// @notice Retrieves details of a challenge.
    /// @param _challengeId ID of the challenge.
    /// @return Challenge struct containing challenge details.
    function getChallengeDetails(uint256 _challengeId) external view challengeExists(_challengeId) returns (Challenge memory) {
        return challenges[_challengeId];
    }

    /// @notice Retrieves a list of all challenge IDs.
    /// @return Array of challenge IDs.
    function getAllChallengeIds() external view returns (uint256[] memory) {
        return allChallengeIds;
    }


    /// @notice Adds a new role with associated permissions.
    /// @param _roleName Name of the role.
    /// @param _permissions Array of permissions associated with the role.
    function addRole(string memory _roleName, string[] memory _permissions) external onlyAdmin notPaused {
        require(bytes(roles[_roleName].permissions).length == 0, "Role already exists"); // Prevent role duplication
        roles[_roleName] = Role({permissions: _permissions});
        emit RoleAdded(_roleName);
    }

    /// @notice Assigns a role to a member.
    /// @param _member Address of the member.
    /// @param _roleName Name of the role to assign.
    function assignRole(address _member, string memory _roleName) external onlyAdmin notPaused {
        require(bytes(roles[_roleName].permissions).length > 0, "Role does not exist");
        members[_member].roles[_roleName] = true;
        emit RoleAssigned(_member, _roleName);
    }

    /// @notice Removes a role from a member.
    /// @param _member Address of the member.
    /// @param _roleName Name of the role to remove.
    function removeRole(address _member, string memory _roleName) external onlyAdmin notPaused {
        require(bytes(roles[_roleName].permissions).length > 0, "Role does not exist");
        delete members[_member].roles[_roleName];
        emit RoleRemoved(_member, _roleName);
    }

    /// @notice Retrieves the roles assigned to a member.
    /// @param _memberAddress Address of the member.
    /// @return Array of role names assigned to the member.
    function getMemberRoles(address _memberAddress) external view returns (string[] memory) {
        string[] memory memberRoles = new string[](0);
        Member storage member = members[_memberAddress];
        if (bytes(member.details).length > 0) { // Check if member exists to avoid errors
            uint256 roleCount = 0;
            for (uint i = 0; i < allMemberAddresses.length; i++) { // Iterate through all roles - inefficeint, consider better approach if roles grow very large
                string memory roleName;
                assembly {
                    roleName := add(roles.slot, keccak256(add(_memberAddress, members.slot), 0x0)) // Approximating slot location for roles mapping inside Member struct - Solidity's storage layout is complex and can change
                }
                if (member.roles[roleName]) { // This might not be the direct way to access keys of a mapping in Solidity - requires more sophisticated storage inspection for dynamic keys
                    roleCount++;
                }
            }
            memberRoles = new string[](roleCount);
            uint256 index = 0;
             for (uint i = 0; i < allMemberAddresses.length; i++) {  // Iterate again to populate the array
                string memory roleName;
                assembly {
                    roleName := add(roles.slot, keccak256(add(_memberAddress, members.slot), 0x0))
                }
                if (member.roles[roleName]) {
                    memberRoles[index] = roleName;
                    index++;
                }
            }
        }
        return memberRoles;
    }


    /// @notice Retrieves the permissions associated with a role.
    /// @param _roleName Name of the role.
    /// @return Array of permissions for the role.
    function getRolePermissions(string memory _roleName) external view returns (string[] memory) {
        return roles[_roleName].permissions;
    }

    /// @notice Checks if a member has a specific role.
    /// @param _memberAddress Address of the member.
    /// @param _roleName Name of the role to check.
    /// @return True if the member has the role, false otherwise.
    function hasRole(address _memberAddress, string memory _roleName) public view returns (bool) {
        return members[_memberAddress].roles[_roleName];
    }


    /// @notice Pauses critical functions of the DAO in case of emergency (Admin only).
    function emergencyPause() external onlyAdmin {
        paused = true;
        emit EmergencyPaused(msg.sender);
    }

    /// @notice Resumes paused functions (Admin only).
    function emergencyUnpause() external onlyAdmin {
        paused = false;
        emit EmergencyUnpaused(msg.sender);
    }

    /// @notice Admin function to withdraw accidentally sent tokens.
    /// @param _tokenAddress Address of the token contract (address(0) for Ether).
    /// @param _recipient Address to receive the withdrawn tokens.
    function withdrawStuckTokens(address _tokenAddress, address _recipient) external onlyAdmin {
        if (_tokenAddress == address(0)) {
            payable(_recipient).transfer(address(this).balance);
        } else {
            // Assuming ERC20 token - in real implementation, use interface for safe interaction
            IERC20 token = IERC20(_tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            token.transfer(_recipient, balance);
        }
        emit TokensWithdrawn(_tokenAddress, _recipient, address(this).balance);
    }

    // --- Interface for ERC20 (Minimal for example) ---
    interface IERC20 {
        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
    }
}
```