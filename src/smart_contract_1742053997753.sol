```solidity
/**
 * @title Dynamic Governance DAO with Reputation and Staking
 * @author Gemini AI
 * @dev A Decentralized Autonomous Organization (DAO) smart contract with advanced features
 *      including dynamic governance parameters, a reputation system, member staking, and
 *      various proposal types for flexible and community-driven decision making.
 *      This contract aims to provide a robust and adaptable governance framework.
 *
 * Function Summary:
 *
 * **Core DAO Functions:**
 *   1. joinDAO(): Allows users to join the DAO and become members.
 *   2. leaveDAO(): Allows members to leave the DAO.
 *   3. getMemberCount(): Returns the current number of DAO members.
 *   4. getMemberDetails(address _member): Retrieves detailed information about a specific member.
 *
 * **Proposal Management:**
 *   5. submitProposal(ProposalType _proposalType, string memory _description, bytes memory _parameters):
 *      Allows members to submit proposals of different types.
 *   6. getProposalDetails(uint256 _proposalId): Retrieves details of a specific proposal.
 *   7. voteOnProposal(uint256 _proposalId, bool _support): Allows members to vote on active proposals.
 *   8. executeProposal(uint256 _proposalId): Executes a proposal if it has passed and is executable.
 *   9. cancelProposal(uint256 _proposalId): Allows the proposer to cancel a pending proposal (before voting starts).
 *  10. getProposalCount(): Returns the total number of proposals submitted.
 *  11. getActiveProposals(): Returns a list of IDs of currently active proposals.
 *  12. getPendingProposals(): Returns a list of IDs of proposals that are pending (waiting for voting).
 *  13. getExecutedProposals(): Returns a list of IDs of proposals that have been executed.
 *  14. getRejectedProposals(): Returns a list of IDs of proposals that were rejected.
 *
 * **Reputation System:**
 *  15. increaseReputation(address _member, uint256 _amount): Increases the reputation of a member (Admin function).
 *  16. decreaseReputation(address _member, uint256 _amount): Decreases the reputation of a member (Admin function).
 *  17. getMemberReputation(address _member): Returns the reputation score of a member.
 *
 * **Staking Mechanism:**
 *  18. stakeTokens(uint256 _amount): Allows members to stake tokens in the DAO.
 *  19. unstakeTokens(uint256 _amount): Allows members to unstake tokens from the DAO.
 *  20. getMemberStakedBalance(address _member): Returns the staked balance of a member.
 *  21. getContractStakedBalance(): Returns the total staked balance in the contract.
 *
 * **Governance Parameters (Dynamic):**
 *  22. submitGovernanceParameterChangeProposal(string memory _parameterName, uint256 _newValue, string memory _description):
 *      Allows members to propose changes to governance parameters.
 *  23. getGovernanceParameter(string memory _parameterName): Retrieves the current value of a governance parameter.
 *
 * **Admin Functions:**
 *  24. setAdmin(address _newAdmin): Transfers admin rights to a new address.
 *  25. rescueTokens(address _tokenAddress, address _recipient, uint256 _amount): Rescues accidentally sent tokens to the contract.
 *
 */
pragma solidity ^0.8.0;

contract DynamicGovernanceDAO {

    // --- Structs and Enums ---

    enum ProposalStatus { Pending, Active, Executed, Rejected, Cancelled }
    enum ProposalType { ParameterChange, ReputationChange, Generic, CustomFunction } // Expandable proposal types

    struct Member {
        address memberAddress;
        uint256 reputation;
        uint256 stakedBalance;
        bool isActive;
        uint256 joinTimestamp;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        ProposalType proposalType;
        string description;
        bytes parameters; // Generic parameter field for different proposal types
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }

    struct GovernanceParameters {
        uint256 quorumPercentage; // Percentage of total members required for quorum
        uint256 votingDuration;    // Duration of voting period in seconds
        uint256 minReputationForProposal; // Minimum reputation to submit a proposal
        uint256 minReputationForVoting;  // Minimum reputation to vote
        uint256 stakingRequirementForProposal; // Minimum staking required to submit a proposal
    }

    // --- State Variables ---

    address public admin;
    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    GovernanceParameters public governanceParams;
    uint256 public memberCount;
    uint256 public proposalCount;
    mapping(string => uint256) public governanceParameterValues; // Store governance parameters by name

    // --- Events ---

    event MemberJoined(address memberAddress, uint256 reputation, uint256 timestamp);
    event MemberLeft(address memberAddress, uint256 timestamp);
    event ProposalSubmitted(uint256 proposalId, ProposalType proposalType, address proposer, string description, uint256 timestamp);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 timestamp);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status, uint256 timestamp);
    event ProposalCancelled(uint256 proposalId, uint256 timestamp);
    event ReputationIncreased(address member, uint256 amount, uint256 newReputation, uint256 timestamp);
    event ReputationDecreased(address member, uint256 amount, uint256 newReputation, uint256 timestamp);
    event TokensStaked(address member, uint256 amount, uint256 newBalance, uint256 timestamp);
    event TokensUnstaked(address member, uint256 amount, uint256 newBalance, uint256 timestamp);
    event GovernanceParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, uint256 timestamp);
    event GovernanceParameterChanged(string parameterName, uint256 newValue, uint256 timestamp);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only members can perform this action");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can perform this action");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.timestamp >= proposals[_proposalId].startTime && block.timestamp <= proposals[_proposalId].endTime, "Voting period is not active");
        _;
    }

    modifier hasEnoughReputationForProposal() {
        require(members[msg.sender].reputation >= governanceParams.minReputationForProposal, "Not enough reputation to submit proposal");
        _;
    }

    modifier hasEnoughReputationForVoting() {
        require(members[msg.sender].reputation >= governanceParams.minReputationForVoting, "Not enough reputation to vote");
        _;
    }

    modifier hasEnoughStakingForProposal() {
        require(members[msg.sender].stakedBalance >= governanceParams.stakingRequirementForProposal, "Not enough staked balance to submit proposal");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialQuorumPercentage, uint256 _votingDuration, uint256 _minReputationProposal, uint256 _minReputationVoting, uint256 _stakingRequirementProposal) {
        admin = msg.sender;
        governanceParams = GovernanceParameters({
            quorumPercentage: _initialQuorumPercentage,
            votingDuration: _votingDuration,
            minReputationForProposal: _minReputationProposal,
            minReputationForVoting: _minReputationVoting,
            stakingRequirementForProposal: _stakingRequirementProposal
        });
        governanceParameterValues["initialQuorumPercentage"] = _initialQuorumPercentage; // Example: Store initial parameter value
        governanceParameterValues["votingDuration"] = _votingDuration; // Example: Store initial parameter value
        governanceParameterValues["minReputationForProposal"] = _minReputationProposal; // Example: Store initial parameter value
        governanceParameterValues["minReputationForVoting"] = _minReputationVoting; // Example: Store initial parameter value
        governanceParameterValues["stakingRequirementForProposal"] = _stakingRequirementProposal; // Example: Store initial parameter value

        memberCount = 0;
        proposalCount = 0;
    }

    // --- Core DAO Functions ---

    function joinDAO() external {
        require(!members[msg.sender].isActive, "Already a member");
        memberCount++;
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            reputation: 1, // Initial reputation
            stakedBalance: 0,
            isActive: true,
            joinTimestamp: block.timestamp
        });
        emit MemberJoined(msg.sender, members[msg.sender].reputation, block.timestamp);
    }

    function leaveDAO() external onlyMember {
        require(members[msg.sender].isActive, "Not a member");
        memberCount--;
        members[msg.sender].isActive = false;
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    function getMemberDetails(address _member) external view returns (Member memory) {
        return members[_member];
    }

    // --- Proposal Management ---

    function submitProposal(ProposalType _proposalType, string memory _description, bytes memory _parameters)
        external
        onlyMember
        hasEnoughReputationForProposal
        hasEnoughStakingForProposal
        returns (uint256 proposalId)
    {
        proposalCount++;
        proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            proposalType: _proposalType,
            description: _description,
            parameters: _parameters,
            startTime: 0, // Voting starts when activated
            endTime: 0,   // Voting ends when voting period expires
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
        });
        emit ProposalSubmitted(proposalId, _proposalType, msg.sender, _description, block.timestamp);
        return proposalId;
    }

    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyMember
        validProposal(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Active)
        votingPeriodActive(_proposalId)
        hasEnoughReputationForVoting
    {
        require(members[msg.sender].isActive, "Only active members can vote"); // Double check membership for extra safety
        require(proposals[_proposalId].startTime != 0 && proposals[_proposalId].endTime != 0, "Voting not started yet");

        // Check if member has already voted (optional, can add mapping to track votes per member per proposal if needed)

        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _support, block.timestamp);
    }

    function executeProposal(uint256 _proposalId)
        external
        onlyMember
        validProposal(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Active) // Can only execute active proposals that have finished voting
    {
        require(proposals[_proposalId].endTime <= block.timestamp, "Voting period is still active"); // Ensure voting period is over

        uint256 quorum = (memberCount * governanceParams.quorumPercentage) / 100;
        require(proposals[_proposalId].votesFor + proposals[_proposalId].votesAgainst >= quorum, "Quorum not reached");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal rejected");

        proposals[_proposalId].status = ProposalStatus.Executed;

        // Execute proposal logic based on proposal type
        if (proposals[_proposalId].proposalType == ProposalType.ParameterChange) {
            _executeParameterChangeProposal(_proposalId);
        } else if (proposals[_proposalId].proposalType == ProposalType.ReputationChange) {
            _executeReputationChangeProposal(_proposalId);
        } else if (proposals[_proposalId].proposalType == ProposalType.Generic) {
            // Generic execution logic or leave to custom function if needed
            _executeGenericProposal(_proposalId); // Example for generic proposals
        } else if (proposals[_proposalId].proposalType == ProposalType.CustomFunction) {
            _executeCustomFunctionProposal(_proposalId); // Example for custom function proposals
        }

        emit ProposalExecuted(_proposalId, proposals[_proposalId].status, block.timestamp);
    }

    function cancelProposal(uint256 _proposalId)
        external
        validProposal(_proposalId)
        onlyProposer(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Pending)
    {
        proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId, block.timestamp);
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.Active) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of active proposals
        assembly {
            mstore(activeProposalIds, count) // Update array length in memory
        }
        return activeProposalIds;
    }

     function getPendingProposals() external view returns (uint256[] memory) {
        uint256[] memory pendingProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.Pending) {
                pendingProposalIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(pendingProposalIds, count)
        }
        return pendingProposalIds;
    }

    function getExecutedProposals() external view returns (uint256[] memory) {
        uint256[] memory executedProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.Executed) {
                executedProposalIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(executedProposalIds, count)
        }
        return executedProposalIds;
    }

    function getRejectedProposals() external view returns (uint256[] memory) {
        uint256[] memory rejectedProposalIds = new uint256[](proposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].status == ProposalStatus.Rejected) { // Assuming you set status to Rejected when proposal fails
                rejectedProposalIds[count] = i;
                count++;
            } else if (proposals[i].status == ProposalStatus.Active && proposals[i].endTime <= block.timestamp && proposals[i].votesFor <= proposals[i].votesAgainst) {
                // Handle cases where voting finished and proposal failed due to votes
                proposals[i].status = ProposalStatus.Rejected; // Update status if not already set
                rejectedProposalIds[count] = i;
                count++;
            }
        }
        assembly {
            mstore(rejectedProposalIds, count)
        }
        return rejectedProposalIds;
    }


    // --- Reputation System ---

    function increaseReputation(address _member, uint256 _amount) external onlyAdmin {
        members[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount, members[_member].reputation, block.timestamp);
    }

    function decreaseReputation(address _member, uint256 _amount) external onlyAdmin {
        members[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount, members[_member].reputation, block.timestamp);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    // --- Staking Mechanism ---
    // **Note:** For a real staking implementation, you would likely integrate with an ERC20 token.
    // This example uses a simplified internal balance for demonstration.

    mapping(address => uint256) public memberStakedBalances; // Internal staked balance

    function stakeTokens(uint256 _amount) external onlyMember {
        require(_amount > 0, "Stake amount must be positive");
        memberStakedBalances[msg.sender] += _amount;
        members[msg.sender].stakedBalance = memberStakedBalances[msg.sender]; // Update member struct
        emit TokensStaked(msg.sender, _amount, members[msg.sender].stakedBalance, block.timestamp);
    }

    function unstakeTokens(uint256 _amount) external onlyMember {
        require(_amount > 0, "Unstake amount must be positive");
        require(memberStakedBalances[msg.sender] >= _amount, "Insufficient staked balance");
        memberStakedBalances[msg.sender] -= _amount;
        members[msg.sender].stakedBalance = memberStakedBalances[msg.sender]; // Update member struct
        emit TokensUnstaked(msg.sender, _amount, members[msg.sender].stakedBalance, block.timestamp);
    }

    function getMemberStakedBalance(address _member) external view returns (uint256) {
        return members[_member].stakedBalance;
    }

    function getContractStakedBalance() external view returns (uint256) {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i <= memberCount; i++) { // Inefficient for large member counts, optimize if needed
            // Could iterate through members mapping keys if available in future Solidity versions or maintain a members array.
            // For simplicity, iterating through memberCount for now (assuming members are added sequentially).
            address memberAddress;
            uint256 memberIndex = 0;
            for (address addr in members) {
                memberIndex++;
                if (memberIndex == i) {
                    memberAddress = addr;
                    break;
                }
            }
            if (members[memberAddress].isActive) {
                totalStaked += members[memberAddress].stakedBalance;
            }
        }
        return totalStaked;
    }


    // --- Governance Parameters (Dynamic) ---

    function submitGovernanceParameterChangeProposal(string memory _parameterName, uint256 _newValue, string memory _description)
        external
        onlyMember
        hasEnoughReputationForProposal
        hasEnoughStakingForProposal
        returns (uint256 proposalId)
    {
        proposalId = submitProposal(
            ProposalType.ParameterChange,
            _description,
            abi.encode(_parameterName, _newValue) // Encode parameter name and new value
        );
        emit GovernanceParameterChangeProposed(proposalId, _parameterName, _newValue, block.timestamp);
        return proposalId;
    }

    function getGovernanceParameter(string memory _parameterName) external view returns (uint256) {
        return governanceParameterValues[_parameterName];
    }

    // --- Admin Functions ---

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address");
        admin = _newAdmin;
    }

    function rescueTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyAdmin {
        // **Important Security Note:**
        //  - For real-world scenarios, use a proper ERC20 interface to interact with tokens safely.
        //  - Consider adding more checks and safeguards to prevent misuse of this function.
        // This is a basic rescue function for demonstration purposes.

        (bool success, bytes memory data) = _tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount)
        );
        require(success, "Token transfer failed");
        require(data.length == 0 || abi.decode(data, (bool))[0], "Token transfer failed (return data)"); // Handle return data if any
    }


    // --- Internal Execution Logic for Proposal Types ---

    function _executeParameterChangeProposal(uint256 _proposalId) internal {
        (string memory parameterName, uint256 newValue) = abi.decode(proposals[_proposalId].parameters, (string, uint256));
        governanceParameterValues[parameterName] = newValue;

        if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
            governanceParams.quorumPercentage = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("votingDuration"))) {
            governanceParams.votingDuration = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("minReputationForProposal"))) {
            governanceParams.minReputationForProposal = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("minReputationForVoting"))) {
            governanceParams.minReputationForVoting = newValue;
        } else if (keccak256(abi.encodePacked(parameterName)) == keccak256(abi.encodePacked("stakingRequirementForProposal"))) {
            governanceParams.stakingRequirementForProposal = newValue;
        }

        emit GovernanceParameterChanged(parameterName, newValue, block.timestamp);
    }

    function _executeReputationChangeProposal(uint256 _proposalId) internal {
        // Example: Decode parameters for reputation change proposal
        // Assume parameters are encoded as (address memberToChange, int256 reputationChangeAmount)
        (address memberToChange, int256 reputationChangeAmount) = abi.decode(proposals[_proposalId].parameters, (address, int256));

        if (reputationChangeAmount > 0) {
            increaseReputation(memberToChange, uint256(reputationChangeAmount)); // Cast to uint256 for increase
        } else if (reputationChangeAmount < 0) {
            decreaseReputation(memberToChange, uint256(uint256(-reputationChangeAmount))); // Cast negative to positive uint256 for decrease
        }
        // Note: Consider adding checks for valid reputation ranges and potential overflow/underflow.
    }

    function _executeGenericProposal(uint256 _proposalId) internal {
        // Add any logic for generic proposals here, or leave it empty if custom function proposals are preferred for specific actions.
        // Example: You could have generic proposals to execute arbitrary contract calls, but this requires careful security considerations.
        // For now, leaving it as a placeholder.
        // You might want to emit a generic proposal executed event with details.
        emit ProposalExecuted(_proposalId, proposals[_proposalId].status, block.timestamp); // Ensure event is emitted
    }

    function _executeCustomFunctionProposal(uint256 _proposalId) internal {
        // Example: Decode parameters for custom function call proposal
        // Assume parameters are encoded as (address targetContract, bytes functionData)
        (address targetContract, bytes memory functionData) = abi.decode(proposals[_proposalId].parameters, (address, bytes));

        (bool success, bytes memory returnData) = targetContract.call(functionData);
        require(success, "Custom function call failed");
        // You could further process returnData if needed, or just log success.
        emit ProposalExecuted(_proposalId, proposals[_proposalId].status, block.timestamp); // Ensure event is emitted
    }


    // --- Proposal Activation Function (Separate step to start voting) ---
    // This is a unique function to make proposal activation a separate step, adding a layer of control.

    function activateProposalVoting(uint256 _proposalId) external onlyMember validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) {
        require(proposals[_proposalId].proposer == msg.sender || msg.sender == admin, "Only proposer or admin can activate proposal"); // Proposer or Admin can activate

        proposals[_proposalId].status = ProposalStatus.Active;
        proposals[_proposalId].startTime = block.timestamp;
        proposals[_proposalId].endTime = block.timestamp + governanceParams.votingDuration;
        emit ProposalSubmitted(_proposalId, proposals[_proposalId].proposalType, proposals[_proposalId].proposer, proposals[_proposalId].description, block.timestamp); // Re-emit event to signal voting start? Or create a new "VotingStarted" event.
        emit ProposalExecuted(_proposalId, proposals[_proposalId].status, block.timestamp); // Re-using executed event for simplicity, consider a more specific event like "VotingStarted".
    }
}
```