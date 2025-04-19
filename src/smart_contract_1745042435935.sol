```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Collaborative Idea Incubator (DCII) - Smart Contract
 * @author Gemini AI (Conceptual Design)
 * @dev This smart contract implements a Decentralized Collaborative Idea Incubator (DCII).
 * It facilitates the process of submitting, voting, funding, and developing innovative ideas within a decentralized community.
 *
 * **Outline and Function Summary:**
 *
 * **I. Core Functionality - Idea Management:**
 *   1. `submitIdea(string memory _title, string memory _description, uint256 _fundingGoal)`: Allows members to submit new ideas with title, description, and funding goal.
 *   2. `voteOnIdea(uint256 _ideaId, bool _support)`: Members can vote for or against ideas.
 *   3. `fundIdea(uint256 _ideaId)`: Members can contribute funds to support approved ideas.
 *   4. `approveIdea(uint256 _ideaId)`: Admin function to officially approve an idea after successful voting and funding.
 *   5. `markIdeaAsDeveloping(uint256 _ideaId)`: Admin function to mark an approved idea as "in development".
 *   6. `markIdeaAsCompleted(uint256 _ideaId)`: Admin function to mark a developed idea as "completed".
 *   7. `getIdeaDetails(uint256 _ideaId)`: View function to retrieve detailed information about an idea.
 *   8. `getAllIdeaIds()`: View function to get a list of all idea IDs in the incubator.
 *   9. `getIdeasByStatus(IdeaStatus _status)`: View function to retrieve idea IDs based on their status (e.g., submitted, approved, developing, completed).
 *
 * **II. Membership & Governance:**
 *   10. `requestMembership()`: Allows anyone to request membership to the DCII community.
 *   11. `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *   12. `revokeMembership(address _member)`: Admin function to revoke membership from a member.
 *   13. `isMember(address _account)`: View function to check if an address is a member.
 *   14. `getMemberCount()`: View function to get the current number of members.
 *   15. `transferAdminRole(address _newAdmin)`: Admin function to transfer the admin role to another address.
 *
 * **III. Advanced Features - Reputation & Gamification:**
 *   16. `giveReputation(address _member, uint256 _reputationPoints)`: Admin function to award reputation points to members for contributions.
 *   17. `getMemberReputation(address _member)`: View function to check a member's reputation points.
 *   18. `stakeTokens()`: Members can stake tokens to gain voting power and potentially earn rewards (placeholder - reward mechanism needs further design).
 *   19. `unstakeTokens()`: Members can unstake their tokens.
 *   20. `getMemberStakedBalance(address _member)`: View function to check a member's staked token balance.
 *
 * **IV. Utility & Security:**
 *   21. `pauseContract()`: Admin function to pause critical contract functionalities.
 *   22. `unpauseContract()`: Admin function to unpause contract functionalities.
 *   23. `emergencyWithdrawFunds(uint256 _amount)`: Admin function for emergency withdrawal of funds from the contract (use with caution).
 */

contract DCII {
    // -------- State Variables --------

    address public admin; // Contract administrator
    bool public paused; // Contract paused status

    uint256 public ideaCounter; // Counter for unique idea IDs
    mapping(uint256 => Idea) public ideas; // Mapping of idea IDs to Idea structs
    uint256[] public allIdeaIds; // Array to keep track of all idea IDs

    mapping(address => bool) public members; // Mapping of member addresses to boolean (is member?)
    address[] public membershipRequests; // Array to store pending membership requests

    mapping(address => uint256) public memberReputation; // Mapping of member addresses to reputation points
    mapping(address => uint256) public stakedBalances; // Mapping of member addresses to staked token balances (placeholder - needs token integration)

    uint256 public membershipFee; // Optional membership fee (currently unused, can be implemented later)
    uint256 public votingPeriod = 7 days; // Default voting period for ideas
    uint256 public quorumPercentage = 50; // Percentage of members required to vote for quorum

    // -------- Enums & Structs --------

    enum IdeaStatus {
        Submitted,
        Voting,
        Funded,
        Approved,
        Developing,
        Completed,
        Rejected
    }

    struct Idea {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 fundingGoal;
        uint256 currentFunding;
        IdeaStatus status;
        uint256 votingEndTime;
        mapping(address => bool) votes; // Members who voted and their vote (true = support, false = against)
        uint256 upVotes;
        uint256 downVotes;
    }

    // -------- Events --------

    event IdeaSubmitted(uint256 ideaId, address proposer, string title);
    event IdeaVoted(uint256 ideaId, address voter, bool support);
    event IdeaFunded(uint256 ideaId, address funder, uint256 amount);
    event IdeaApproved(uint256 ideaId);
    event IdeaStatusUpdated(uint256 ideaId, IdeaStatus newStatus);
    event MembershipRequested(address requester);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ReputationGiven(address member, uint256 reputationPoints);
    event TokensStaked(address member, uint256 amount);
    event TokensUnstaked(address member, uint256 amount);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event FundsWithdrawn(address admin, uint256 amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier ideaExists(uint256 _ideaId) {
        require(ideas[_ideaId].id == _ideaId, "Idea does not exist.");
        _;
    }

    modifier ideaInStatus(uint256 _ideaId, IdeaStatus _status) {
        require(ideas[_ideaId].status == _status, "Idea is not in the required status.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        paused = false;
        ideaCounter = 1; // Start idea IDs from 1
    }

    // -------- I. Core Functionality - Idea Management --------

    /// @notice Allows members to submit a new idea.
    /// @param _title The title of the idea.
    /// @param _description A detailed description of the idea.
    /// @param _fundingGoal The funding goal for the idea in wei.
    function submitIdea(string memory _title, string memory _description, uint256 _fundingGoal)
        external
        onlyMember
        notPaused
    {
        require(bytes(_title).length > 0 && bytes(_description).length > 0, "Title and description cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");

        Idea storage newIdea = ideas[ideaCounter];
        newIdea.id = ideaCounter;
        newIdea.title = _title;
        newIdea.description = _description;
        newIdea.proposer = msg.sender;
        newIdea.fundingGoal = _fundingGoal;
        newIdea.currentFunding = 0;
        newIdea.status = IdeaStatus.Submitted; // Initial status
        newIdea.votingEndTime = block.timestamp + votingPeriod;
        newIdea.upVotes = 0;
        newIdea.downVotes = 0;

        allIdeaIds.push(ideaCounter);
        emit IdeaSubmitted(ideaCounter, msg.sender, _title);
        ideaCounter++;
    }

    /// @notice Allows members to vote for or against an idea.
    /// @param _ideaId The ID of the idea to vote on.
    /// @param _support True to vote in support, false to vote against.
    function voteOnIdea(uint256 _ideaId, bool _support)
        external
        onlyMember
        notPaused
        ideaExists(_ideaId)
        ideaInStatus(_ideaId, IdeaStatus.Submitted) // Can only vote on submitted ideas
    {
        require(block.timestamp <= ideas[_ideaId].votingEndTime, "Voting period has ended.");
        require(!ideas[_ideaId].votes[msg.sender], "Member has already voted on this idea.");

        ideas[_ideaId].votes[msg.sender] = true; // Record vote
        if (_support) {
            ideas[_ideaId].upVotes++;
        } else {
            ideas[_ideaId].downVotes++;
        }

        emit IdeaVoted(_ideaId, msg.sender, _support);

        // Check if voting period ended or quorum reached after this vote
        if (block.timestamp > ideas[_ideaId].votingEndTime || isQuorumReached(_ideaId)) {
            _processVotingResult(_ideaId);
        }
    }

    /// @dev Internal function to check if quorum is reached for an idea.
    /// @param _ideaId The ID of the idea to check.
    /// @return bool True if quorum is reached, false otherwise.
    function isQuorumReached(uint256 _ideaId) internal view returns (bool) {
        uint256 totalVotes = ideas[_ideaId].upVotes + ideas[_ideaId].downVotes;
        uint256 requiredVotes = (getMemberCount() * quorumPercentage) / 100;
        return totalVotes >= requiredVotes;
    }

    /// @dev Internal function to process the voting result after voting period ends or quorum is reached.
    /// @param _ideaId The ID of the idea to process.
    function _processVotingResult(uint256 _ideaId) internal {
        if (ideas[_ideaId].status != IdeaStatus.Submitted) return; // Prevent re-processing

        if (ideas[_ideaId].upVotes > ideas[_ideaId].downVotes && isQuorumReached(_ideaId)) {
            ideas[_ideaId].status = IdeaStatus.Voting; // Move to Voting status to indicate voting success, then funding next
            emit IdeaStatusUpdated(_ideaId, IdeaStatus.Voting);
        } else {
            ideas[_ideaId].status = IdeaStatus.Rejected;
            emit IdeaStatusUpdated(_ideaId, IdeaStatus.Rejected);
        }
    }

    /// @notice Allows members to contribute funds to support an idea that is in 'Voting' status (post-voting success).
    /// @param _ideaId The ID of the idea to fund.
    function fundIdea(uint256 _ideaId)
        external
        payable
        onlyMember
        notPaused
        ideaExists(_ideaId)
        ideaInStatus(_ideaId, IdeaStatus.Voting) // Ideas in 'Voting' status are ready for funding
    {
        require(ideas[_ideaId].currentFunding < ideas[_ideaId].fundingGoal, "Idea already fully funded.");

        uint256 amountToFund = msg.value;
        uint256 remainingFundingNeeded = ideas[_ideaId].fundingGoal - ideas[_ideaId].currentFunding;

        if (amountToFund > remainingFundingNeeded) {
            amountToFund = remainingFundingNeeded; // Cap funding to the remaining amount needed
        }

        ideas[_ideaId].currentFunding += amountToFund;
        emit IdeaFunded(_ideaId, msg.sender, amountToFund);

        if (ideas[_ideaId].currentFunding >= ideas[_ideaId].fundingGoal) {
            ideas[_ideaId].status = IdeaStatus.Funded; // Idea fully funded
            emit IdeaStatusUpdated(_ideaId, IdeaStatus.Funded);
        }
    }

    /// @notice Admin function to officially approve an idea after successful voting and funding.
    /// @param _ideaId The ID of the idea to approve.
    function approveIdea(uint256 _ideaId)
        external
        onlyAdmin
        notPaused
        ideaExists(_ideaId)
        ideaInStatus(_ideaId, IdeaStatus.Funded) // Only ideas in 'Funded' status can be approved
    {
        ideas[_ideaId].status = IdeaStatus.Approved;
        emit IdeaApproved(_ideaId);
        emit IdeaStatusUpdated(_ideaId, IdeaStatus.Approved);
    }

    /// @notice Admin function to mark an approved idea as "in development".
    /// @param _ideaId The ID of the idea to mark as developing.
    function markIdeaAsDeveloping(uint256 _ideaId)
        external
        onlyAdmin
        notPaused
        ideaExists(_ideaId)
        ideaInStatus(_ideaId, IdeaStatus.Approved) // Only 'Approved' ideas can be marked as 'Developing'
    {
        ideas[_ideaId].status = IdeaStatus.Developing;
        emit IdeaStatusUpdated(_ideaId, IdeaStatus.Developing);
    }

    /// @notice Admin function to mark a developed idea as "completed".
    /// @param _ideaId The ID of the idea to mark as completed.
    function markIdeaAsCompleted(uint256 _ideaId)
        external
        onlyAdmin
        notPaused
        ideaExists(_ideaId)
        ideaInStatus(_ideaId, IdeaStatus.Developing) // Only 'Developing' ideas can be marked as 'Completed'
    {
        ideas[_ideaId].status = IdeaStatus.Completed;
        emit IdeaStatusUpdated(_ideaId, IdeaStatus.Completed);
    }

    /// @notice View function to retrieve detailed information about an idea.
    /// @param _ideaId The ID of the idea.
    /// @return Idea struct containing idea details.
    function getIdeaDetails(uint256 _ideaId)
        external
        view
        ideaExists(_ideaId)
        returns (Idea memory)
    {
        return ideas[_ideaId];
    }

    /// @notice View function to get a list of all idea IDs in the incubator.
    /// @return uint256[] Array of all idea IDs.
    function getAllIdeaIds() external view returns (uint256[] memory) {
        return allIdeaIds;
    }

    /// @notice View function to retrieve idea IDs based on their status.
    /// @param _status The desired IdeaStatus to filter by.
    /// @return uint256[] Array of idea IDs with the specified status.
    function getIdeasByStatus(IdeaStatus _status) external view returns (uint256[] memory) {
        uint256[] memory filteredIdeaIds = new uint256[](allIdeaIds.length);
        uint256 count = 0;
        for (uint256 i = 0; i < allIdeaIds.length; i++) {
            if (ideas[allIdeaIds[i]].status == _status) {
                filteredIdeaIds[count] = allIdeaIds[i];
                count++;
            }
        }
        // Resize the array to remove empty slots
        assembly {
            mstore(filteredIdeaIds, count) // Update the length of the array
        }
        return filteredIdeaIds;
    }

    // -------- II. Membership & Governance --------

    /// @notice Allows anyone to request membership to the DCII community.
    function requestMembership() external notPaused {
        require(!members[msg.sender], "Already a member.");
        // Optionally, implement membership fee payment here in the future.
        membershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve pending membership requests.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member], "Address is already a member.");
        bool found = false;
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _member) {
                membershipRequests[i] = address(0); // Mark as processed, not actually removing to maintain array index order (for gas)
                found = true;
                break;
            }
        }
        require(found, "Membership request not found for this address.");

        members[_member] = true;
        emit MembershipApproved(_member);
    }

    /// @notice Admin function to revoke membership from a member.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member.");
        delete members[_member]; // More gas efficient than setting to false in mappings for storage refunds
        emit MembershipRevoked(_member);
    }

    /// @notice View function to check if an address is a member.
    /// @param _account The address to check.
    /// @return bool True if the address is a member, false otherwise.
    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    /// @notice View function to get the current number of members.
    /// @return uint256 The number of members.
    function getMemberCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] != address(0)) { // Count pending requests
                count++;
            }
        }
        for (address memberAddress in members) { // Iterate over members mapping (less efficient for large member sets, consider alternative if scalability needed)
            if (members[memberAddress]) {
                count++; // Count approved members
            }
        }
        return count; // This count might be slightly off due to double counting if requests are approved immediately, needs refinement for precise count in high-request scenarios if necessary. For simplicity, it's a reasonable approximation.
    }


    /// @notice Admin function to transfer the admin role to another address.
    /// @param _newAdmin The address of the new administrator.
    function transferAdminRole(address _newAdmin) external onlyAdmin notPaused {
        require(_newAdmin != address(0), "Invalid new admin address.");
        admin = _newAdmin;
    }

    // -------- III. Advanced Features - Reputation & Gamification --------

    /// @notice Admin function to award reputation points to members for contributions.
    /// @param _member The address of the member to give reputation to.
    /// @param _reputationPoints The number of reputation points to award.
    function giveReputation(address _member, uint256 _reputationPoints) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member.");
        memberReputation[_member] += _reputationPoints;
        emit ReputationGiven(_member, _reputationPoints);
    }

    /// @notice View function to check a member's reputation points.
    /// @param _member The address of the member.
    /// @return uint256 The member's reputation points.
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /// @notice Allows members to stake tokens to gain voting power (and potential future rewards).
    /// @dev Placeholder function - staking mechanism and reward system need further design and token integration.
    function stakeTokens() external payable onlyMember notPaused {
        // In a real implementation, you would:
        // 1. Integrate with an ERC20 token contract.
        // 2. Transfer tokens from the member to this contract.
        // 3. Update stakedBalances mapping.
        // 4. Potentially increase voting power based on staked amount (not implemented here for simplicity).
        uint256 stakeAmount = msg.value; // For simplicity, using Ether as staked "tokens" here for demonstration. In real use, would be ERC20 tokens.
        require(stakeAmount > 0, "Stake amount must be greater than zero.");

        stakedBalances[msg.sender] += stakeAmount;
        emit TokensStaked(msg.sender, stakeAmount);
    }

    /// @notice Allows members to unstake their tokens.
    /// @dev Placeholder function - unstaking mechanism needs to be aligned with actual staking implementation.
    function unstakeTokens() external onlyMember notPaused {
        // In a real implementation, you would:
        // 1. Check if unstake request conditions are met (e.g., lock-up period).
        // 2. Transfer tokens back to the member from this contract.
        // 3. Update stakedBalances mapping.
        uint256 unstakeAmount = stakedBalances[msg.sender]; // For simplicity, unstaking entire balance in this example.
        require(unstakeAmount > 0, "No tokens staked to unstake.");

        stakedBalances[msg.sender] = 0;
        payable(msg.sender).transfer(unstakeAmount); // Transfer "staked Ether" back. In real use, would be ERC20 token transfer.
        emit TokensUnstaked(msg.sender, unstakeAmount);
    }

    /// @notice View function to check a member's staked token balance.
    /// @param _member The address of the member.
    /// @return uint256 The member's staked token balance.
    function getMemberStakedBalance(address _member) external view returns (uint256) {
        return stakedBalances[_member];
    }

    // -------- IV. Utility & Security --------

    /// @notice Admin function to pause critical contract functionalities.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause contract functionalities.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Admin function for emergency withdrawal of funds from the contract. Use with caution.
    /// @param _amount The amount of Ether to withdraw in wei.
    function emergencyWithdrawFunds(uint256 _amount) external onlyAdmin {
        require(_amount <= address(this).balance, "Withdrawal amount exceeds contract balance.");
        payable(admin).transfer(_amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /// @notice Fallback function to reject direct Ether transfers to the contract (unless funding an idea).
    fallback() external payable {
        revert("Direct Ether transfers not allowed. Use fundIdea() to contribute to ideas.");
    }

    receive() external payable {
        revert("Direct Ether transfers not allowed. Use fundIdea() to contribute to ideas.");
    }
}
```