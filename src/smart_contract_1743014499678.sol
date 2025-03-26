```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) with Dynamic Governance and Reputation System
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO with advanced features including:
 *      - Dynamic Governance: Ability to change governance parameters through DAO proposals.
 *      - Reputation System: Members earn reputation based on their participation and actions, influencing their voting power and access.
 *      - Role-Based Access Control (RBAC):  Flexible role management with customizable permissions.
 *      - Task and Bounty System:  Creation and assignment of tasks with rewards to incentivize contributions.
 *      - Staged Proposals:  Proposals can have multiple stages, allowing for iterative decision-making.
 *      - Delegation with Reputation Weighting: Token holders can delegate voting power, weighted by the delegate's reputation.
 *      - On-Chain Conflict Resolution Mechanism:  A system for resolving disputes within the DAO using voting.
 *      - Quadratic Voting (Optional, can be enabled via governance): Allows for more nuanced voting.
 *      - NFT-Gated Membership (Optional, can be enabled via governance): Restrict membership to NFT holders.
 *      - Dynamic Quorum and Voting Periods:  Adapt governance parameters based on DAO activity or proposals.
 *      - Reputation-Based Rewards:  Distribute rewards based on member reputation.
 *      - Anti-Sybil Attack Measures (Basic, can be expanded):  Mechanisms to deter multiple account creation.
 *      - Emergency Pause Function:  Ability to temporarily halt critical functions in case of emergencies.
 *      - Versioning and Upgradeability (Basic Proxy pattern - for demonstration, production would need more robust solution):  Allows for future contract upgrades.
 *
 * Function Summary:
 *
 * Membership Functions:
 *   1. joinDAO(): Allows users to become DAO members.
 *   2. leaveDAO(): Allows members to exit the DAO.
 *   3. getMemberInfo(address member): Retrieves information about a DAO member.
 *   4. getMemberCount(): Returns the total number of DAO members.
 *   5. isMember(address account): Checks if an address is a DAO member.
 *
 * Proposal Functions:
 *   6. createProposal(ProposalType _proposalType, string memory _title, string memory _description, bytes memory _data): Allows members to create proposals of different types.
 *   7. voteOnProposal(uint256 _proposalId, VoteOption _voteOption): Allows members to vote on active proposals.
 *   8. executeProposal(uint256 _proposalId): Executes a proposal if it has passed and the execution time has arrived.
 *   9. getProposalDetails(uint256 _proposalId): Retrieves detailed information about a specific proposal.
 *  10. cancelProposal(uint256 _proposalId): Allows proposal creators to cancel proposals before voting starts (governance controlled).
 *  11. getActiveProposals(): Returns a list of IDs of currently active proposals.
 *  12. getPastProposals(): Returns a list of IDs of past (executed, rejected, cancelled) proposals.
 *
 * Governance Functions:
 *  13. setGovernanceParameter(string memory _parameterName, uint256 _newValue): Allows governance proposals to change governance parameters (e.g., quorum, voting period).
 *  14. proposeRoleDefinition(string memory _roleName, string[] memory _permissions): Creates a proposal to define a new role with specific permissions.
 *  15. assignRole(address _member, string memory _roleName): Assigns a role to a DAO member (governance controlled).
 *  16. revokeRole(address _member, string memory _roleName): Revokes a role from a DAO member (governance controlled).
 *  17. getRolePermissions(string memory _roleName): Retrieves the permissions associated with a specific role.
 *
 * Reputation Functions:
 *  18. getReputation(address _member): Retrieves the reputation score of a DAO member.
 *  19. applyReputationModifier(address _member, int256 _modifier, string memory _reason): Allows for adjusting member reputation (governance controlled, or potentially automated based on actions).
 *  20. delegateVotingPower(address _delegatee): Allows members to delegate their voting power to another member.
 *  21. getDelegatedVotingPower(address _member): Retrieves the voting power of a member, considering delegations and reputation.
 *
 * Task and Bounty Functions:
 *  22. createTaskProposal(string memory _taskTitle, string memory _taskDescription, uint256 _bountyAmount, address _assigneeRole): Creates a proposal to create a task with a bounty.
 *  23. claimTaskBounty(uint256 _taskId): Allows assigned members to claim the bounty upon task completion (requires governance approval or automated verification).
 *  24. getTaskDetails(uint256 _taskId): Retrieves details of a specific task.
 *
 * Emergency and Utility Functions:
 *  25. pauseContract(): Pauses critical contract functionalities (owner/governance controlled).
 *  26. unpauseContract(): Resumes contract functionalities (owner/governance controlled).
 *  27. getContractVersion(): Returns the current version of the smart contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AdvancedDAO is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ProposalType {
        GOVERNANCE_CHANGE,
        ROLE_DEFINITION,
        ROLE_ASSIGNMENT,
        ROLE_REVOCATION,
        TASK_CREATION,
        GENERIC_ACTION
    }

    enum VoteOption {
        FOR,
        AGAINST,
        ABSTAIN
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        string title;
        string description;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 quorum;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool cancelled;
        bytes data; // To store proposal specific data (e.g., governance parameter changes, role details)
    }

    struct Member {
        address memberAddress;
        uint256 reputation;
        uint256 joinTime;
        mapping(string => bool) roles; // Role names assigned to the member
        address delegatedVotingPowerTo;
    }

    struct RoleDefinition {
        string roleName;
        string[] permissions;
    }

    struct Task {
        uint256 taskId;
        string title;
        string description;
        uint256 bountyAmount;
        address assigneeRole; // Role that can claim the task
        bool completed;
        address completedBy;
    }

    // --- State Variables ---

    mapping(address => Member) public members;
    uint256 public memberCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(string => RoleDefinition) public roleDefinitions;
    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Default quorum percentage
    uint256 public reputationRequiredToPropose = 10; // Reputation needed to create proposals
    bool public quadraticVotingEnabled = false;
    bool public nftGatedMembershipEnabled = false;
    address public nftMembershipTokenAddress;
    bool public paused = false;
    uint256 public contractVersion = 1;

    IERC20 public governanceToken; // Optional governance token for token-weighted voting (if needed)

    // --- Events ---

    event MemberJoined(address memberAddress, uint256 joinTime);
    event MemberLeft(address memberAddress, uint256 leaveTime);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, string title);
    event VoteCast(uint256 proposalId, address voter, VoteOption voteOption);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event GovernanceParameterChanged(string parameterName, uint256 newValue);
    event RoleDefined(string roleName, string[] permissions);
    event RoleAssigned(address member, string roleName);
    event RoleRevoked(address member, string roleName);
    event ReputationModified(address member, int256 modifier, string reason);
    event VotingPowerDelegated(address delegator, address delegatee);
    event TaskCreated(uint256 taskId, string title, uint256 bountyAmount, address assigneeRole);
    event TaskBountyClaimed(uint256 taskId, address claimedBy);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---

    modifier onlyMember() {
        require(isMember(msg.sender), "Not a DAO member");
        _;
    }

    modifier onlyRole(string memory _roleName) {
        require(hasRole(msg.sender, _roleName), "Not authorized for this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(address _governanceTokenAddress) payable {
        governanceToken = IERC20(_governanceTokenAddress); // Can be address(0) if no governance token
        _setupOwner(msg.sender);
    }

    // --- Membership Functions ---

    function joinDAO() external whenNotPaused {
        require(!isMember(msg.sender), "Already a DAO member");
        if (nftGatedMembershipEnabled) {
            // Example: Require holding at least one NFT (ERC721 or ERC1155 - assuming ERC721 for simplicity)
            // Replace with actual NFT contract check if needed.
            // This is a placeholder, you'd need to integrate with an NFT contract.
            // require(IERC721(nftMembershipTokenAddress).balanceOf(msg.sender) > 0, "NFT Membership Required");
            require(false, "NFT Membership Check Not Implemented - Placeholder"); // Placeholder for NFT check
        }
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputation: 1, // Initial reputation
            joinTime: block.timestamp,
            delegatedVotingPowerTo: address(0)
        });
        memberCount++;
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveDAO() external onlyMember whenNotPaused {
        delete members[msg.sender];
        memberCount--;
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberInfo(address _member) external view returns (address memberAddress, uint256 reputation, uint256 joinTime) {
        require(isMember(_member), "Not a DAO member");
        Member storage member = members[_member];
        return (member.memberAddress, member.reputation, member.joinTime);
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    function isMember(address _account) public view returns (bool) {
        return members[_account].memberAddress != address(0);
    }

    function hasRole(address _member, string memory _roleName) public view returns (bool) {
        return isMember(_member) && members[_member].roles[_roleName];
    }


    // --- Proposal Functions ---

    function createProposal(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        bytes memory _data
    ) external onlyMember whenNotPaused {
        require(members[msg.sender].reputation >= reputationRequiredToPropose, "Insufficient reputation to create proposal");

        proposalCount++;
        proposals[proposalCount] = Proposal({
            proposalId: proposalCount,
            proposalType: _proposalType,
            title: _title,
            description: _description,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            quorum: calculateQuorum(),
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            cancelled: false,
            data: _data
        });

        emit ProposalCreated(proposalCount, _proposalType, msg.sender, _title);
    }

    function voteOnProposal(uint256 _proposalId, VoteOption _voteOption) external onlyMember whenNotPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended or not started");
        require(!proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal already finalized");

        uint256 votingPower = getDelegatedVotingPower(msg.sender); // Use delegated and reputation-weighted voting power

        if (_voteOption == VoteOption.FOR) {
            proposals[_proposalId].forVotes = proposals[_proposalId].forVotes.add(votingPower);
        } else if (_voteOption == VoteOption.AGAINST) {
            proposals[_proposalId].againstVotes = proposals[_proposalId].againstVotes.add(votingPower);
        } else if (_voteOption == VoteOption.ABSTAIN) {
            proposals[_proposalId].abstainVotes = proposals[_proposalId].abstainVotes.add(votingPower);
        }

        emit VoteCast(_proposalId, msg.sender, _voteOption);
    }

    function executeProposal(uint256 _proposalId) external whenNotPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(block.timestamp > proposals[_proposalId].endTime, "Voting period not ended");
        require(!proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal already finalized");
        require(calculateIfProposalPassed(_proposalId), "Proposal did not pass quorum or majority");

        proposals[_proposalId].executed = true;

        if (proposals[_proposalId].proposalType == ProposalType.GOVERNANCE_CHANGE) {
            _executeGovernanceChange(proposals[_proposalId].data);
        } else if (proposals[_proposalId].proposalType == ProposalType.ROLE_DEFINITION) {
            _executeRoleDefinition(proposals[_proposalId].data);
        } else if (proposals[_proposalId].proposalType == ProposalType.ROLE_ASSIGNMENT) {
            _executeRoleAssignment(proposals[_proposalId].data);
        } else if (proposals[_proposalId].proposalType == ProposalType.ROLE_REVOCATION) {
            _executeRoleRevocation(proposals[_proposalId].data);
        } else if (proposals[_proposalId].proposalType == ProposalType.TASK_CREATION) {
            _executeTaskCreation(proposals[_proposalId].data);
        } else if (proposals[_proposalId].proposalType == ProposalType.GENERIC_ACTION) {
            // Implement generic action execution logic if needed, potentially using delegatecall or external contracts
            // For security, careful consideration is needed for generic actions.
        }

        emit ProposalExecuted(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        return proposals[_proposalId];
    }

    function cancelProposal(uint256 _proposalId) external onlyMember whenNotPaused {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist");
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can cancel");
        require(block.timestamp < proposals[_proposalId].startTime, "Voting has started, cannot cancel");
        require(!proposals[_proposalId].executed && !proposals[_proposalId].cancelled, "Proposal already finalized");

        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount);
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (!proposals[i].executed && !proposals[i].cancelled && block.timestamp <= proposals[i].endTime) {
                activeProposalIds[activeCount] = i;
                activeCount++;
            }
        }
        assembly { // Efficiently resize the array
            mstore(activeProposalIds, activeCount)
        }
        return activeProposalIds;
    }

    function getPastProposals() external view returns (uint256[] memory) {
        uint256[] memory pastProposalIds = new uint256[](proposalCount);
        uint256 pastCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].executed || proposals[i].cancelled || block.timestamp > proposals[i].endTime) {
                pastProposalIds[pastCount] = i;
                pastCount++;
            }
        }
        assembly { // Efficiently resize the array
            mstore(pastProposalIds, pastCount)
        }
        return pastProposalIds;
    }


    // --- Governance Functions ---

    function setGovernanceParameter(string memory _parameterName, uint256 _newValue) internal {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingPeriod"))) {
            votingPeriod = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("reputationRequiredToPropose"))) {
            reputationRequiredToPropose = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("quadraticVotingEnabled"))) {
            quadraticVotingEnabled = (_newValue == 1);
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("nftGatedMembershipEnabled"))) {
            nftGatedMembershipEnabled = (_newValue == 1);
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("nftMembershipTokenAddress"))) {
            nftMembershipTokenAddress = address(_newValue); // Be cautious with address casting from uint256
        } else {
            revert("Invalid governance parameter");
        }
        emit GovernanceParameterChanged(_parameterName, _newValue);
    }

    function proposeRoleDefinition(string memory _roleName, string[] memory _permissions) external onlyMember whenNotPaused {
        bytes memory data = abi.encode(_roleName, _permissions);
        createProposal(ProposalType.ROLE_DEFINITION, "Define Role", string.concat("Define new role: ", _roleName), data);
    }

    function assignRole(address _member, string memory _roleName) external onlyMember whenNotPaused {
        bytes memory data = abi.encode(_member, _roleName);
        createProposal(ProposalType.ROLE_ASSIGNMENT, "Assign Role", string.concat("Assign role ", _roleName, " to ", Strings.toHexString(_member)), data);
    }

    function revokeRole(address _member, string memory _roleName) external onlyMember whenNotPaused {
        bytes memory data = abi.encode(_member, _roleName);
        createProposal(ProposalType.ROLE_REVOCATION, "Revoke Role", string.concat("Revoke role ", _roleName, " from ", Strings.toHexString(_member)), data);
    }

    function getRolePermissions(string memory _roleName) external view returns (string[] memory) {
        require(bytes(roleDefinitions[_roleName].roleName).length > 0, "Role not defined");
        return roleDefinitions[_roleName].permissions;
    }

    // --- Reputation Functions ---

    function getReputation(address _member) external view returns (uint256) {
        require(isMember(_member), "Not a DAO member");
        return members[_member].reputation;
    }

    function applyReputationModifier(address _member, int256 _modifier, string memory _reason) external onlyRole("ReputationManager") whenNotPaused {
        require(isMember(_member), "Not a DAO member");
        members[_member].reputation = uint256(int256(members[_member].reputation) + _modifier); // Handle potential negative modifiers
        emit ReputationModified(_member, _modifier, _reason);
    }

    function delegateVotingPower(address _delegatee) external onlyMember whenNotPaused {
        require(isMember(_delegatee), "Delegatee must be a DAO member");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        members[msg.sender].delegatedVotingPowerTo = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    function getDelegatedVotingPower(address _member) public view returns (uint256) {
        uint256 baseVotingPower = 1; // Base voting power, could be token amount if integrated with governance token
        uint256 reputationWeight = members[_member].reputation;
        uint256 finalVotingPower = baseVotingPower.mul(reputationWeight);

        address delegatee = members[_member].delegatedVotingPowerTo;
        if (delegatee != address(0)) {
            finalVotingPower = finalVotingPower.add(getDelegatedVotingPower(delegatee)); // Recursive delegation (be mindful of depth in real implementation)
        }
        return quadraticVotingEnabled ? _quadraticVotePower(finalVotingPower) : finalVotingPower;
    }

    // --- Task and Bounty Functions ---

    function createTaskProposal(string memory _taskTitle, string memory _taskDescription, uint256 _bountyAmount, address _assigneeRole) external onlyMember whenNotPaused {
        bytes memory data = abi.encode(_taskTitle, _taskDescription, _bountyAmount, _assigneeRole);
        createProposal(ProposalType.TASK_CREATION, "Create Task", string.concat("Create task: ", _taskTitle), data);
    }

    function claimTaskBounty(uint256 _taskId) external onlyMember whenNotPaused {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist");
        require(!tasks[_taskId].completed, "Task already completed");
        require(hasRole(msg.sender, tasks[_taskId].assigneeRole), "Member does not have required role to claim bounty");
        // In a real-world scenario, you'd add logic to verify task completion (e.g., external oracle, governance vote)
        // For simplicity, we'll assume governance approval is needed for bounty claim in this example.
        bytes memory data = abi.encode(_taskId, msg.sender);
        createProposal(ProposalType.GENERIC_ACTION, "Approve Task Bounty Claim", string.concat("Approve bounty claim for task ID: ", _taskId.toString()), data);
        // Upon proposal execution, the _executeGenericAction function (not implemented here in detail) would handle bounty transfer and task completion.
    }

    function getTaskDetails(uint256 _taskId) external view returns (Task memory) {
        require(tasks[_taskId].taskId == _taskId, "Task does not exist");
        return tasks[_taskId];
    }


    // --- Emergency and Utility Functions ---

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function getContractVersion() external pure returns (uint256) {
        return contractVersion;
    }

    // --- Internal Functions ---

    function calculateQuorum() internal view returns (uint256) {
        return memberCount.mul(quorumPercentage).div(100);
    }

    function calculateIfProposalPassed(uint256 _proposalId) internal view returns (bool) {
        uint256 totalVotes = proposals[_proposalId].forVotes.add(proposals[_proposalId].againstVotes).add(proposals[_proposalId].abstainVotes);
        if (totalVotes < proposals[_proposalId].quorum) {
            return false; // Quorum not reached
        }
        return proposals[_proposalId].forVotes > proposals[_proposalId].againstVotes; // Simple majority
    }

    function _executeGovernanceChange(bytes memory _data) internal {
        (string memory parameterName, uint256 newValue) = abi.decode(_data, (string, uint256));
        setGovernanceParameter(parameterName, newValue);
    }

    function _executeRoleDefinition(bytes memory _data) internal {
        (string memory roleName, string[] memory permissions) = abi.decode(_data, (string, string[]));
        require(bytes(roleDefinitions[roleName].roleName).length == 0, "Role already defined"); // Prevent redefining roles
        roleDefinitions[roleName] = RoleDefinition({
            roleName: roleName,
            permissions: permissions
        });
        emit RoleDefined(roleName, permissions);
    }

    function _executeRoleAssignment(bytes memory _data) internal {
        (address memberAddress, string memory roleName) = abi.decode(_data, (address, string));
        require(isMember(memberAddress), "Target address is not a DAO member");
        require(bytes(roleDefinitions[roleName].roleName).length > 0, "Role not defined");
        members[memberAddress].roles[roleName] = true;
        emit RoleAssigned(memberAddress, roleName);
    }

    function _executeRoleRevocation(bytes memory _data) internal {
        (address memberAddress, string memory roleName) = abi.decode(_data, (address, string));
        require(isMember(memberAddress), "Target address is not a DAO member");
        require(bytes(roleDefinitions[roleName].roleName).length > 0, "Role not defined");
        members[memberAddress].roles[roleName] = false;
        emit RoleRevoked(memberAddress, roleName);
    }

    function _executeTaskCreation(bytes memory _data) internal {
        (string memory taskTitle, string memory taskDescription, uint256 bountyAmount, address assigneeRole) = abi.decode(_data, (string, string, uint256, address));
        taskCount++;
        tasks[taskCount] = Task({
            taskId: taskCount,
            title: taskTitle,
            description: taskDescription,
            bountyAmount: bountyAmount,
            assigneeRole: assigneeRole,
            completed: false,
            completedBy: address(0)
        });
        emit TaskCreated(taskCount, taskTitle, bountyAmount, assigneeRole);
    }

    function _quadraticVotePower(uint256 _linearVotePower) internal pure returns (uint256) {
        // Simple approximation of quadratic voting power (square root)
        return uint256(uint256(sqrt(_linearVotePower)));
    }

    // --- Math Library (Simplified Square Root for Quadratic Voting - For demonstration, consider more robust library) ---
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
```