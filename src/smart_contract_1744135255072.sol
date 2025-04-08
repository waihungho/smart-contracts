```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Asset Management
 * @author Bard (AI Assistant)
 * @dev A sophisticated DAO contract showcasing advanced concepts like role-based governance,
 *      dynamic voting mechanisms, on-chain reputation, decentralized asset management, and
 *      integrations with external oracles and DeFi protocols. This contract is designed to be
 *      highly customizable and adaptable to various organizational needs.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Roles:**
 *    - `joinDAO()`: Allows anyone to request membership to the DAO.
 *    - `approveMembership(address _member)`:  Admin/Role to approve a pending membership request.
 *    - `revokeMembership(address _member)`: Admin/Role to revoke membership from a member.
 *    - `defineRole(string memory _roleName, uint256 _votingWeight)`: Admin/Role to define new roles within the DAO with specific voting weights.
 *    - `assignRole(address _member, string memory _roleName)`: Admin/Role to assign a role to a member.
 *    - `revokeRole(address _member, string memory _roleName)`: Admin/Role to revoke a role from a member.
 *    - `getMemberRoles(address _member)`:  View function to get the roles of a member.
 *    - `getRoleMembers(string memory _roleName)`: View function to get members of a specific role.
 *
 * **2. Dynamic Governance & Voting:**
 *    - `createGovernanceProposal(string memory _title, string memory _description, bytes memory _executionData)`: Members can create governance proposals with execution data.
 *    - `createWeightedGovernanceProposal(string memory _title, string memory _description, bytes memory _executionData, string[] memory _requiredRoles)`: Members can create governance proposals requiring specific role participation.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Members can vote on active proposals based on their roles and voting weight.
 *    - `getProposalDetails(uint256 _proposalId)`: View function to get details of a specific proposal.
 *    - `getProposalVotingStatus(uint256 _proposalId)`: View function to get the current voting status of a proposal.
 *    - `executeProposal(uint256 _proposalId)`:  Callable after proposal reaches quorum and approval to execute the proposal's actions.
 *    - `cancelProposal(uint256 _proposalId)`: Admin/Role to cancel a proposal before it is executed.
 *
 * **3. On-Chain Reputation & Skill-Based Contributions:**
 *    - `reportContribution(address _member, string memory _contributionDescription)`: Members can report their contributions to the DAO.
 *    - `validateContribution(uint256 _contributionId, address _validator, bool _isApproved)`: Role/Designated members can validate reported contributions, increasing reputation.
 *    - `getMemberReputation(address _member)`: View function to get a member's reputation score.
 *    - `getContributionDetails(uint256 _contributionId)`: View function to get details of a specific contribution.
 *
 * **4. Decentralized Asset Management & Treasury:**
 *    - `depositToTreasury() payable`: Members or external parties can deposit funds into the DAO treasury.
 *    - `proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)`: Members can propose spending from the treasury for DAO activities.
 *    - `executeTreasurySpending(uint256 _proposalId)`: Executes treasury spending after proposal approval.
 *    - `getTreasuryBalance()`: View function to get the current balance of the DAO treasury.
 *
 * **5. Advanced & Trendy Features:**
 *    - `integrateExternalOracle(address _oracleAddress)`: Admin/Role to integrate with an external oracle for data feeds (e.g., price feeds, randomness).
 *    - `requestOracleData(string memory _query)`:  DAO can request data from the integrated oracle (requires governance proposal).
 *    - `onOracleDataReceived(bytes memory _data)`: Internal callback function to handle data received from the oracle and trigger further actions.
 *    - `pauseContract()`: Admin/Role to pause critical functionalities of the contract in emergencies.
 *    - `unpauseContract()`: Admin/Role to unpause the contract after an emergency is resolved.
 */
contract DynamicGovernanceDAO {

    // ** State Variables **

    // Membership
    mapping(address => bool) public isMember;
    mapping(address => bool) public pendingMembership;
    address[] public members;

    // Roles
    mapping(string => uint256) public roleVotingWeight; // Role name to voting weight
    mapping(string => address[]) public roleMembers; // Role name to list of members in that role
    mapping(address => string[]) public memberRoles; // Member address to list of roles assigned

    // Proposals
    uint256 public proposalCount;
    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Cancelled }
    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalState state;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bytes executionData;
        address executionTarget; // Optional target for execution
        uint256 quorum; // Required percentage of total voting power for quorum
        uint256 approvalThreshold; // Required percentage of quorum for approval
        mapping(address => bool) votes; // Member address to vote status (true = support, false = against)
        uint256 yesVotes;
        uint256 noVotes;
        string[] requiredRoles; // Roles required to participate in voting (optional)
    }
    mapping(uint256 => Proposal) public proposals;

    // Reputation & Contributions
    uint256 public contributionCount;
    struct Contribution {
        uint256 id;
        address member;
        string description;
        uint256 timestamp;
        bool validated;
        address[] validators; // List of addresses who validated the contribution
    }
    mapping(uint256 => Contribution) public contributions;
    mapping(address => uint256) public memberReputation; // Member address to reputation score

    // Treasury
    uint256 public treasuryBalance;

    // Oracle Integration (Example - Placeholder for external oracle)
    address public externalOracleAddress;
    mapping(uint256 => bytes) public oracleDataResponses; // Proposal ID to oracle data received

    // Governance Parameters (Can be modified via governance proposals)
    uint256 public defaultProposalQuorum = 50; // Default quorum percentage (50%)
    uint256 public defaultProposalApprovalThreshold = 60; // Default approval threshold percentage (60%)
    uint256 public proposalVotingDuration = 7 days; // Default voting duration
    address public admin; // Admin address - can be replaced by multi-sig or governance later
    bool public paused; // Contract paused state

    // ** Events **
    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event RoleDefined(string roleName, uint256 votingWeight);
    event RoleAssigned(address member, string roleName);
    event RoleRevoked(address member, string roleName);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string title);
    event WeightedGovernanceProposalCreated(uint256 proposalId, address proposer, string title, string[] requiredRoles);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ContributionReported(uint256 contributionId, address member);
    event ContributionValidated(uint256 contributionId, address validator, bool isApproved);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string reason);
    event TreasurySpendingExecuted(uint256 proposalId, address recipient, uint256 amount);
    event OracleIntegrated(address oracleAddress);
    event OracleDataRequested(uint256 proposalId, string query);
    event OracleDataReceived(uint256 proposalId, bytes data);
    event ContractPaused();
    event ContractUnpaused();

    // ** Modifiers **
    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAO member");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyRole(string memory _roleName) {
        bool hasRole = false;
        string[] memory roles = memberRoles[msg.sender];
        for (uint256 i = 0; i < roles.length; i++) {
            if (keccak256(bytes(roles[i])) == keccak256(bytes(_roleName))) {
                hasRole = true;
                break;
            }
        }
        require(hasRole, "Caller does not have the required role");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount && proposals[_proposalId].id == _proposalId, "Proposal does not exist");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // ** Constructor **
    constructor() {
        admin = msg.sender;
        roleVotingWeight["CoreMember"] = 100; // Default CoreMember role with high voting weight
        defineRole("Contributor", 10); // Example Contributor role
        defineRole("Reviewer", 50); // Example Reviewer role
    }

    // ** 1. Membership & Roles Functions **

    /// @notice Allows anyone to request membership to the DAO.
    function joinDAO() external notPaused {
        require(!isMember[msg.sender], "Already a member");
        require(!pendingMembership[msg.sender], "Membership request already pending");
        pendingMembership[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Approves a pending membership request. Only callable by admin or a designated role.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyAdmin notPaused { // Example: could be `onlyRole("MembershipManager")` instead of admin for decentralization
        require(pendingMembership[_member], "No pending membership request");
        require(!isMember[_member], "Already a member");
        isMember[_member] = true;
        pendingMembership[_member] = false;
        members.push(_member);
        emit MembershipApproved(_member);
    }

    /// @notice Revokes membership from a member. Only callable by admin or a designated role.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused { // Example: could be `onlyRole("MembershipManager")`
        require(isMember[_member], "Not a member");
        isMember[_member] = false;
        // Remove from member list (inefficient for large lists, consider optimization for production)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    /// @notice Defines a new role with a specific voting weight. Only callable by admin or a designated role.
    /// @param _roleName The name of the role.
    /// @param _votingWeight The voting weight associated with the role.
    function defineRole(string memory _roleName, uint256 _votingWeight) public onlyAdmin notPaused { // Example: could be `onlyRole("RoleManager")`
        require(bytes(_roleName).length > 0, "Role name cannot be empty");
        require(roleVotingWeight[_roleName] == 0, "Role already defined");
        roleVotingWeight[_roleName] = _votingWeight;
        emit RoleDefined(_roleName, _votingWeight);
    }

    /// @notice Assigns a role to a member. Only callable by admin or a designated role.
    /// @param _member The address of the member to assign the role to.
    /// @param _roleName The name of the role to assign.
    function assignRole(address _member, string memory _roleName) external onlyAdmin notPaused { // Example: could be `onlyRole("RoleManager")`
        require(isMember[_member], "Member address is not a DAO member");
        require(roleVotingWeight[_roleName] > 0, "Role does not exist");
        bool roleExists = false;
        string[] memory roles = memberRoles[_member];
        for (uint256 i = 0; i < roles.length; i++) {
            if (keccak256(bytes(roles[i])) == keccak256(bytes(_roleName))) {
                roleExists = true;
                break;
            }
        }
        require(!roleExists, "Member already has this role");

        memberRoles[_member].push(_roleName);
        roleMembers[_roleName].push(_member);
        emit RoleAssigned(_member, _roleName);
    }

    /// @notice Revokes a role from a member. Only callable by admin or a designated role.
    /// @param _member The address of the member to revoke the role from.
    /// @param _roleName The name of the role to revoke.
    function revokeRole(address _member, string memory _roleName) external onlyAdmin notPaused { // Example: could be `onlyRole("RoleManager")`
        require(isMember[_member], "Member address is not a DAO member");
        bool roleExists = false;
        uint256 roleIndex = 0;
        string[] memory roles = memberRoles[_member];
        for (uint256 i = 0; i < roles.length; i++) {
            if (keccak256(bytes(roles[i])) == keccak256(bytes(_roleName))) {
                roleExists = true;
                roleIndex = i;
                break;
            }
        }
        require(roleExists, "Member does not have this role");

        // Remove role from member's role list (inefficient, optimize for production)
        if (memberRoles[_member].length > 1) {
            memberRoles[_member][roleIndex] = memberRoles[_member][memberRoles[_member].length - 1];
            memberRoles[_member].pop();
        } else {
            delete memberRoles[_member]; // Clear mapping if only one role
        }

        // Remove member from role's member list (inefficient, optimize for production)
        uint256 memberIndexInRole = 0;
        address[] memory membersInRole = roleMembers[_roleName];
        for (uint256 i = 0; i < membersInRole.length; i++) {
            if (membersInRole[i] == _member) {
                memberIndexInRole = i;
                break;
            }
        }
        if (roleMembers[_roleName].length > 1) {
            roleMembers[_roleName][memberIndexInRole] = roleMembers[_roleName][roleMembers[_roleName].length - 1];
            roleMembers[_roleName].pop();
        } else {
            delete roleMembers[_roleName]; // Clear mapping if only one member
        }

        emit RoleRevoked(_member, _roleName);
    }

    /// @notice Gets the roles assigned to a member.
    /// @param _member The address of the member.
    /// @return string[] An array of role names assigned to the member.
    function getMemberRoles(address _member) external view returns (string[] memory) {
        return memberRoles[_member];
    }

    /// @notice Gets the members who have a specific role.
    /// @param _roleName The name of the role.
    /// @return address[] An array of member addresses with the specified role.
    function getRoleMembers(string memory _roleName) external view returns (address[] memory) {
        return roleMembers[_roleName];
    }


    // ** 2. Dynamic Governance & Voting Functions **

    /// @notice Creates a governance proposal. Callable by DAO members.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _executionData Encoded data for contract execution upon proposal approval.
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _executionData) external onlyMember notPaused {
        _createProposal(_title, _description, _executionData, address(this), new string[](0)); // No specific roles required
        emit GovernanceProposalCreated(proposalCount, msg.sender, _title);
    }

    /// @notice Creates a governance proposal that requires participation from specific roles. Callable by DAO members.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _executionData Encoded data for contract execution upon proposal approval.
    /// @param _requiredRoles An array of role names that are required to participate in voting.
    function createWeightedGovernanceProposal(string memory _title, string memory _description, bytes memory _executionData, string[] memory _requiredRoles) external onlyMember notPaused {
        _createProposal(_title, _description, _executionData, address(this), _requiredRoles);
        emit WeightedGovernanceProposalCreated(proposalCount, msg.sender, _title, _requiredRoles);
    }

    /// @dev Internal function to create a new proposal.
    function _createProposal(string memory _title, string memory _description, bytes memory _executionData, address _executionTarget, string[] memory _requiredRoles) internal {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.state = ProposalState.Active;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + proposalVotingDuration;
        newProposal.executionData = _executionData;
        newProposal.executionTarget = _executionTarget;
        newProposal.quorum = defaultProposalQuorum;
        newProposal.approvalThreshold = defaultProposalApprovalThreshold;
        newProposal.requiredRoles = _requiredRoles;
    }


    /// @notice Allows a member to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for supporting the proposal, false for opposing.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember notPaused proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.votes[msg.sender], "Already voted on this proposal");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");

        // Check if voter has required roles (if any)
        if (proposal.requiredRoles.length > 0) {
            bool hasRequiredRole = false;
            string[] memory voterRoles = memberRoles[msg.sender];
            for (uint256 i = 0; i < proposal.requiredRoles.length; i++) {
                for (uint256 j = 0; j < voterRoles.length; j++) {
                    if (keccak256(bytes(proposal.requiredRoles[i])) == keccak256(bytes(voterRoles[j]))) {
                        hasRequiredRole = true;
                        break;
                    }
                }
                if (hasRequiredRole) break;
            }
            require(hasRequiredRole, "Voter does not have the required role to vote on this proposal");
        }


        proposal.votes[msg.sender] = true;
        if (_support) {
            proposal.yesVotes += getVotingWeight(msg.sender);
        } else {
            proposal.noVotes += getVotingWeight(msg.sender);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);

        _updateProposalState(_proposalId); // Check if proposal state needs to be updated after each vote
    }

    /// @dev Gets the voting weight of a member based on their roles.
    function getVotingWeight(address _member) internal view returns (uint256) {
        uint256 totalWeight = 0;
        string[] memory roles = memberRoles[_member];
        for (uint256 i = 0; i < roles.length; i++) {
            totalWeight += roleVotingWeight[roles[i]];
        }
        if (totalWeight == 0) {
            return 1; // Default voting weight for members without specific roles
        }
        return totalWeight;
    }

    /// @dev Updates the proposal state based on current votes and time.
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return; // No need to update if not active

        if (block.timestamp > proposal.endTime) {
            uint256 totalVotingPower = _getTotalVotingPower();
            uint256 quorumReached = (totalVotingPower * proposal.quorum) / 100;

            if (proposal.yesVotes + proposal.noVotes >= quorumReached) {
                uint256 approvalPercentage = (proposal.yesVotes * 100) / (proposal.yesVotes + proposal.noVotes);
                if (approvalPercentage >= proposal.approvalThreshold) {
                    proposal.state = ProposalState.Passed;
                } else {
                    proposal.state = ProposalState.Rejected;
                }
            } else {
                proposal.state = ProposalState.Rejected; // Quorum not reached, proposal fails
            }
        }
    }

    /// @dev Calculates the total voting power of all members.
    function _getTotalVotingPower() internal view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 0; i < members.length; i++) {
            totalPower += getVotingWeight(members[i]);
        }
        return totalPower;
    }


    /// @notice Gets details of a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Proposal The proposal struct.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Gets the current voting status of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ProposalState The current state of the proposal.
    function getProposalVotingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Executes a passed proposal. Callable after proposal voting period ends and proposal is passed.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyMember notPaused proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Passed) {
        Proposal storage proposal = proposals[_proposalId];
        proposal.state = ProposalState.Executed;
        (bool success, ) = proposal.executionTarget.call(proposal.executionData);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Cancels a proposal before it is executed. Only callable by admin or a designated role.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external onlyAdmin notPaused proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Active) { // Example: could be `onlyRole("GovernanceManager")`
        Proposal storage proposal = proposals[_proposalId];
        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }


    // ** 3. On-Chain Reputation & Skill-Based Contributions Functions **

    /// @notice Allows members to report their contributions to the DAO.
    /// @param _contributionDescription A description of the contribution.
    function reportContribution(address _member, string memory _contributionDescription) public onlyMember notPaused {
        contributionCount++;
        contributions[contributionCount] = Contribution({
            id: contributionCount,
            member: _member,
            description: _contributionDescription,
            timestamp: block.timestamp,
            validated: false,
            validators: new address[](0)
        });
        emit ContributionReported(contributionCount, _member);
    }

    /// @notice Allows designated role (e.g., "Reviewer") to validate a reported contribution.
    /// @param _contributionId The ID of the contribution to validate.
    /// @param _validator The address of the validator.
    /// @param _isApproved True if the contribution is approved, false otherwise.
    function validateContribution(uint256 _contributionId, address _validator, bool _isApproved) external onlyRole("Reviewer") notPaused { // Example: "Reviewer" role for validation
        require(_contributionId > 0 && _contributionId <= contributionCount, "Contribution does not exist");
        Contribution storage contribution = contributions[_contributionId];
        require(!contribution.validated, "Contribution already validated");
        require(contribution.member != _validator, "Validator cannot validate their own contribution");

        contribution.validated = true;
        contribution.validators.push(_validator);
        if (_isApproved) {
            memberReputation[contribution.member] += 10; // Example: increase reputation by 10 for approved contributions
        } else {
            memberReputation[contribution.member] -= 5; // Example: decrease reputation by 5 for rejected contributions
        }
        emit ContributionValidated(_contributionId, _validator, _isApproved);
    }

    /// @notice Gets a member's reputation score.
    /// @param _member The address of the member.
    /// @return uint256 The reputation score of the member.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Gets details of a specific contribution.
    /// @param _contributionId The ID of the contribution.
    /// @return Contribution The contribution struct.
    function getContributionDetails(uint256 _contributionId) external view returns (Contribution memory) {
        return contributions[_contributionId];
    }


    // ** 4. Decentralized Asset Management & Treasury Functions **

    /// @notice Allows members or external parties to deposit funds into the DAO treasury.
    function depositToTreasury() external payable notPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows members to propose spending from the treasury for DAO activities.
    /// @param _recipient The address to receive the funds.
    /// @param _amount The amount to spend (in wei).
    /// @param _reason The reason for the spending.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external onlyMember notPaused {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= treasuryBalance, "Insufficient treasury balance");

        bytes memory executionData = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        _createProposal(
            string.concat("Treasury Spending Proposal: ", _reason),
            string.concat("Proposal to spend ", Strings.toString(_amount), " wei from treasury to ", _recipient, " for reason: ", _reason),
            executionData,
            address(this), // Execute on this contract (treasury transfer)
            new string[](0) // No specific roles required for voting
        );
        emit TreasurySpendingProposed(proposalCount, _recipient, _amount, _reason);
    }

    /// @notice Executes a treasury spending proposal after approval.
    /// @param _proposalId The ID of the treasury spending proposal.
    function executeTreasurySpending(uint256 _proposalId) external onlyMember notPaused proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Passed) {
        Proposal storage proposal = proposals[_proposalId];
        require(keccak256(proposal.executionTarget.code) == keccak256(address(this).code), "Execution target is not this contract"); // Ensure execution target is this contract
        require(keccak256(proposal.executionData.slice(0, 4)) == keccak256(bytes4(keccak256("transfer(address,uint256)"))), "Execution data is not a treasury transfer"); // Ensure function signature is transfer

        address recipient;
        uint256 amount;
        (bool success) = abi.decode(proposal.executionData.slice(4), (address, uint256)); // Attempt to decode - could use try-catch in real-world
        if (success) {
            (success, bytes memory returnData) = address(this).call(proposal.executionData); // Call the transfer function on this contract
            require(success, string(returnData)); // Revert with reason from internal `transfer` if it fails
            recipient = abi.decode(proposal.executionData.slice(4), (address, uint256))[0];
            amount = abi.decode(proposal.executionData.slice(4), (address, uint256))[1];
            treasuryBalance -= amount; // Update treasury balance after successful transfer
            emit TreasurySpendingExecuted(_proposalId, recipient, amount);
            executeProposal(_proposalId); // Mark proposal as executed after treasury action is complete
        } else {
            revert("Failed to decode treasury spending proposal data");
        }
    }

    /// @dev Internal function to transfer funds from the treasury (only callable by this contract in `executeTreasurySpending`).
    function transfer(address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= treasuryBalance, "Insufficient treasury balance");
        (bool success, ) = _recipient.call{value: _amount}(bytes("")); // Low-level transfer
        require(success, "Treasury transfer failed");
    }


    /// @notice Gets the current balance of the DAO treasury.
    /// @return uint256 The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // ** 5. Advanced & Trendy Features Functions **

    /// @notice Allows admin or designated role to integrate an external oracle for data feeds.
    /// @param _oracleAddress The address of the external oracle contract.
    function integrateExternalOracle(address _oracleAddress) external onlyAdmin notPaused { // Example: `onlyRole("OracleManager")`
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        externalOracleAddress = _oracleAddress;
        emit OracleIntegrated(_oracleAddress);
    }

    /// @notice Allows the DAO to request data from the integrated external oracle. Requires a governance proposal.
    /// @param _query The query string to send to the oracle.
    function requestOracleData(string memory _query) external onlyMember notPaused {
        require(externalOracleAddress != address(0), "No external oracle integrated");
        require(bytes(_query).length > 0, "Query cannot be empty");

        bytes memory executionData = abi.encodeWithSignature("requestData(string)", _query);
        _createProposal(
            string.concat("Oracle Data Request: ", _query),
            string.concat("Proposal to request data from external oracle with query: ", _query),
            executionData,
            address(this), // Execute on this contract (oracle request)
            new string[](0) // No specific roles for voting
        );
        emit OracleDataRequested(proposalCount, _query);
    }

    /// @dev Internal callback function to handle data received from the oracle.
    ///  (This is a placeholder - actual implementation depends on the specific oracle interface)
    /// @param _data The data received from the oracle.
    function onOracleDataReceived(bytes memory _data) internal {
        // Example: This would be called by the oracle contract (or a dedicated callback mechanism)
        //  after data is retrieved.
        //  - Decode the data based on the oracle's response format.
        //  - Trigger further actions based on the received oracle data.
        //  - Example: Update DAO parameters, trigger automated actions, etc.
        //  - For simplicity, let's just store the raw data associated with the last proposal.
        oracleDataResponses[proposalCount] = _data; // Associate data with the current proposal (assuming oracle request is always tied to a proposal)
        emit OracleDataReceived(proposalCount, _data);

        // Example: Decode and use the oracle data (This is highly dependent on the oracle's API)
        // (Assuming oracle returns uint256 for example)
        // uint256 oracleValue = abi.decode(_data, (uint256));
        // if (oracleValue > 100) {
        //     // Take some action based on oracle data
        // }
    }

    /// @notice Pauses critical functionalities of the contract in emergencies. Only callable by admin or designated role.
    function pauseContract() external onlyAdmin notPaused { // Example: `onlyRole("EmergencyManager")`
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, restoring normal functionalities after an emergency is resolved. Only callable by admin or designated role.
    function unpauseContract() external onlyAdmin { // Example: `onlyRole("EmergencyManager")`
        paused = false;
        emit ContractUnpaused();
    }


    // ** Helper Library (Simple String Conversion) **
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = bytes(digits);
            while (value != 0) {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```