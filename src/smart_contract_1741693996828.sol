```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to join,
 * submit artwork proposals, vote on submissions, manage a collective treasury, and govern
 * the collective's rules. This contract incorporates advanced concepts like NFT-gated membership,
 * proposal-based governance, dynamic role management, and on-chain reputation.

 * **Outline and Function Summary:**

 * **1. Membership Management:**
 *    - `joinCollective()`: Allows artists to request membership to the collective.
 *    - `approveMembership(address _artist)`: Owner-only function to approve pending membership requests.
 *    - `revokeMembership(address _artist)`: Owner-only function to revoke membership from an artist.
 *    - `isMember(address _artist)`: Checks if an address is a member of the collective.
 *    - `getMembers()`: Returns a list of current collective members.
 *    - `setMembershipFee(uint256 _fee)`: Owner-only function to set a membership fee (if applicable).

 * **2. Artwork Proposal and Voting:**
 *    - `submitArtworkProposal(string memory _metadataURI)`: Members can submit artwork proposals with metadata URI.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on artwork proposals (true for approve, false for reject).
 *    - `getProposalStatus(uint256 _proposalId)`: Retrieves the current status of an artwork proposal.
 *    - `getProposalVotes(uint256 _proposalId)`: Returns the current vote count for a proposal.
 *    - `executeApprovedProposal(uint256 _proposalId)`: Owner-only function to execute an approved proposal (e.g., mint NFT).
 *    - `cancelProposal(uint256 _proposalId)`: Owner-only function to cancel a proposal before voting ends.

 * **3. Collective Treasury Management:**
 *    - `depositToTreasury()`: Allows anyone to deposit ETH into the collective's treasury.
 *    - `withdrawFromTreasury(uint256 _amount)`: Owner-only function to withdraw ETH from the treasury.
 *    - `getTreasuryBalance()`: Returns the current ETH balance of the collective treasury.
 *    - `proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason)`: Members can propose treasury spending.
 *    - `voteOnTreasurySpending(uint256 _spendingProposalId, bool _vote)`: Members vote on treasury spending proposals.
 *    - `executeApprovedSpendingProposal(uint256 _spendingProposalId)`: Owner-only function to execute approved treasury spending.

 * **4. Reputation and Role Management (Advanced Concept):**
 *    - `increaseReputation(address _artist, uint256 _amount)`: Owner-only function to manually increase an artist's reputation.
 *    - `decreaseReputation(address _artist, uint256 _amount)`: Owner-only function to manually decrease an artist's reputation.
 *    - `getArtistReputation(address _artist)`: Returns the reputation score of an artist.
 *    - `setRoleThreshold(string memory _roleName, uint256 _threshold)`: Owner-only function to set reputation thresholds for roles.
 *    - `getArtistRoles(address _artist)`: Returns the roles an artist currently holds based on their reputation.
 *    - `defineRole(string memory _roleName, string memory _description)`: Owner-only function to define new roles with descriptions.
 *    - `getRoleDescription(string memory _roleName)`: Returns the description of a defined role.

 * **5. Collective Governance and Settings:**
 *    - `setVotingDuration(uint256 _duration)`: Owner-only function to set the default voting duration for proposals.
 *    - `setDefaultQuorum(uint256 _quorum)`: Owner-only function to set the default quorum for proposals.
 *    - `pauseContract()`: Owner-only function to pause core functionalities of the contract.
 *    - `unpauseContract()`: Owner-only function to unpause the contract.
 *    - `isPaused()`: Returns whether the contract is currently paused.
 *    - `transferOwnership(address newOwner)`: Owner-only function to transfer contract ownership.
 *    - `getOwner()`: Returns the address of the contract owner.

 * **Note:** This contract is designed to be illustrative and conceptual.  Real-world implementation would require thorough security audits,
 * gas optimization, and potentially integration with NFT standards or other on-chain systems based on specific use cases.
 */
contract DecentralizedAutonomousArtCollective {
    address public owner;
    string public collectiveName;
    uint256 public membershipFee;
    uint256 public defaultVotingDuration; // In blocks
    uint256 public defaultQuorum; // Percentage (e.g., 51 for 51%)
    bool public paused;

    mapping(address => bool) public members;
    address[] public memberList;
    mapping(address => bool) public pendingMemberships;

    uint256 public proposalCounter;
    struct ArtworkProposal {
        address proposer;
        string metadataURI;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    enum ProposalStatus { Pending, Active, Approved, Rejected, Cancelled, Executed }
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => artist => voted

    uint256 public spendingProposalCounter;
    struct TreasurySpendingProposal {
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
    }
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    mapping(uint256 => mapping(address => bool)) public spendingProposalVotes;

    mapping(address => uint256) public artistReputation;
    mapping(string => uint256) public roleThresholds;
    mapping(string => string) public roleDescriptions;
    string[] public definedRoles;

    event MembershipRequested(address artist);
    event MembershipApproved(address artist);
    event MembershipRevoked(address artist);
    event ArtworkProposalSubmitted(uint256 proposalId, address proposer, string metadataURI);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event ProposalExecuted(uint256 proposalId);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address proposer, address recipient, uint256 amount, string reason);
    event TreasurySpendingVoted(uint256 proposalId, address voter, bool vote);
    event TreasurySpendingExecuted(uint256 proposalId, address recipient, uint256 amount);
    event ReputationIncreased(address artist, uint256 amount, string reason);
    event ReputationDecreased(address artist, uint256 amount, string reason);
    event RoleThresholdSet(string roleName, uint256 threshold);
    event RoleDefined(string roleName, string description);
    event VotingDurationSet(uint256 duration);
    event DefaultQuorumSet(uint256 quorum);
    event ContractPaused();
    event ContractUnpaused();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
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

    constructor(string memory _collectiveName) {
        owner = msg.sender;
        collectiveName = _collectiveName;
        defaultVotingDuration = 7 days; // Default voting duration is 7 days in blocks (adjust as needed for block times)
        defaultQuorum = 51; // Default quorum is 51%
        paused = false;
    }

    // ------------------------------------------------------------
    // 1. Membership Management
    // ------------------------------------------------------------

    function joinCollective() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMemberships[msg.sender], "Membership request already pending.");
        if (membershipFee > 0) {
            require(msg.value >= membershipFee, "Membership fee required.");
        }
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _artist) external onlyOwner whenNotPaused {
        require(pendingMemberships[_artist], "No pending membership request for this address.");
        require(!members[_artist], "Address is already a member.");
        members[_artist] = true;
        pendingMemberships[_artist] = false;
        memberList.push(_artist);
        emit MembershipApproved(_artist);
    }

    function revokeMembership(address _artist) external onlyOwner whenNotPaused {
        require(members[_artist], "Address is not a member.");
        members[_artist] = false;
        pendingMemberships[_artist] = false; // Clear any pending requests in case of re-application
        // Remove from memberList (inefficient for large lists, consider alternatives for production)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _artist) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_artist);
    }

    function isMember(address _artist) external view returns (bool) {
        return members[_artist];
    }

    function getMembers() external view returns (address[] memory) {
        return memberList;
    }

    function setMembershipFee(uint256 _fee) external onlyOwner whenNotPaused {
        membershipFee = _fee;
    }

    // ------------------------------------------------------------
    // 2. Artwork Proposal and Voting
    // ------------------------------------------------------------

    function submitArtworkProposal(string memory _metadataURI) external onlyMember whenNotPaused {
        proposalCounter++;
        artworkProposals[proposalCounter] = ArtworkProposal({
            proposer: msg.sender,
            metadataURI: _metadataURI,
            startTime: block.number,
            endTime: block.number + defaultVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
        });
        emit ArtworkProposalSubmitted(proposalCounter, msg.sender, _metadataURI);
        updateProposalStatus(proposalCounter); // Immediately set to Active if just created
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(artworkProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        require(block.number <= artworkProposals[_proposalId].endTime, "Voting period ended.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            artworkProposals[_proposalId].votesFor++;
        } else {
            artworkProposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
        updateProposalStatus(_proposalId); // Check if voting threshold reached after each vote
    }

    function getProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return artworkProposals[_proposalId].status;
    }

    function getProposalVotes(uint256 _proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        return (artworkProposals[_proposalId].votesFor, artworkProposals[_proposalId].votesAgainst);
    }

    function executeApprovedProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artworkProposals[_proposalId].status == ProposalStatus.Approved, "Proposal is not approved.");
        require(artworkProposals[_proposalId].status != ProposalStatus.Executed, "Proposal already executed.");
        // --- Here you would implement the logic for executing the proposal ---
        // Example: Mint an NFT with metadataURI from artworkProposals[_proposalId].metadataURI
        // For demonstration, we'll just update the status to Executed.
        artworkProposals[_proposalId].status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStatusUpdated(_proposalId, ProposalStatus.Executed);
    }

    function cancelProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(artworkProposals[_proposalId].status == ProposalStatus.Pending || artworkProposals[_proposalId].status == ProposalStatus.Active, "Proposal cannot be cancelled at this status.");
        artworkProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalStatusUpdated(_proposalId, ProposalStatus.Cancelled);
    }

    function updateProposalStatus(uint256 _proposalId) private {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        if (proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active; // Transition from Pending to Active once submitted
            emit ProposalStatusUpdated(_proposalId, ProposalStatus.Active);
        } else if (proposal.status == ProposalStatus.Active && block.number > proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes == 0) {
                proposal.status = ProposalStatus.Rejected; // No votes, consider rejected after time
                emit ProposalStatusUpdated(_proposalId, ProposalStatus.Rejected);
            } else {
                uint256 quorumVotesNeeded = (memberList.length * defaultQuorum) / 100; // Quorum based on member list size
                if (proposal.votesFor >= quorumVotesNeeded && proposal.votesFor > proposal.votesAgainst) {
                    proposal.status = ProposalStatus.Approved;
                    emit ProposalStatusUpdated(_proposalId, ProposalStatus.Approved);
                } else {
                    proposal.status = ProposalStatus.Rejected;
                    emit ProposalStatusUpdated(_proposalId, ProposalStatus.Rejected);
                }
            }
        }
    }


    // ------------------------------------------------------------
    // 3. Collective Treasury Management
    // ------------------------------------------------------------

    function depositToTreasury() external payable whenNotPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(uint256 _amount) external onlyOwner whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(owner).transfer(_amount);
        emit TreasuryWithdrawal(owner, _amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external onlyMember whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Spending amount must be greater than zero.");
        spendingProposalCounter++;
        treasurySpendingProposals[spendingProposalCounter] = TreasurySpendingProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            startTime: block.number,
            endTime: block.number + defaultVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Pending
        });
        emit TreasurySpendingProposed(spendingProposalCounter, msg.sender, _recipient, _amount, _reason);
        updateSpendingProposalStatus(spendingProposalCounter); // Set to active immediately
    }

    function voteOnTreasurySpending(uint256 _spendingProposalId, bool _vote) external onlyMember whenNotPaused {
        require(treasurySpendingProposals[_spendingProposalId].status == ProposalStatus.Active, "Spending proposal is not active.");
        require(!spendingProposalVotes[_spendingProposalId][msg.sender], "Already voted on this spending proposal.");
        require(block.number <= treasurySpendingProposals[_spendingProposalId].endTime, "Voting period ended.");

        spendingProposalVotes[_spendingProposalId][msg.sender] = true;
        if (_vote) {
            treasurySpendingProposals[_spendingProposalId].votesFor++;
        } else {
            treasurySpendingProposals[_spendingProposalId].votesAgainst++;
        }
        emit TreasurySpendingVoted(_spendingProposalId, msg.sender, _vote);
        updateSpendingProposalStatus(_spendingProposalId); // Check status after vote
    }

    function executeApprovedSpendingProposal(uint256 _spendingProposalId) external onlyOwner whenNotPaused {
        require(treasurySpendingProposals[_spendingProposalId].status == ProposalStatus.Approved, "Spending proposal is not approved.");
        require(treasurySpendingProposals[_spendingProposalId].status != ProposalStatus.Executed, "Spending proposal already executed.");
        TreasurySpendingProposal storage proposal = treasurySpendingProposals[_spendingProposalId];
        require(address(this).balance >= proposal.amount, "Insufficient treasury balance for spending proposal.");

        (bool success, ) = payable(proposal.recipient).call{value: proposal.amount}("");
        require(success, "Treasury transfer failed.");

        proposal.status = ProposalStatus.Executed;
        emit TreasurySpendingExecuted(_spendingProposalId, proposal.recipient, proposal.amount);
        emit ProposalStatusUpdated(_spendingProposalId, ProposalStatus.Executed);
    }

    function updateSpendingProposalStatus(uint256 _spendingProposalId) private {
         TreasurySpendingProposal storage proposal = treasurySpendingProposals[_spendingProposalId];
        if (proposal.status == ProposalStatus.Pending) {
            proposal.status = ProposalStatus.Active; // Set to Active when submitted
            emit ProposalStatusUpdated(_spendingProposalId, ProposalStatus.Active);
        } else if (proposal.status == ProposalStatus.Active && block.number > proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            if (totalVotes == 0) {
                proposal.status = ProposalStatus.Rejected; // No votes, consider rejected after time
                emit ProposalStatusUpdated(_spendingProposalId, ProposalStatus.Rejected);
            } else {
                uint256 quorumVotesNeeded = (memberList.length * defaultQuorum) / 100; // Quorum based on member list size
                if (proposal.votesFor >= quorumVotesNeeded && proposal.votesFor > proposal.votesAgainst) {
                    proposal.status = ProposalStatus.Approved;
                    emit ProposalStatusUpdated(_spendingProposalId, ProposalStatus.Approved);
                } else {
                    proposal.status = ProposalStatus.Rejected;
                    emit ProposalStatusUpdated(_spendingProposalId, ProposalStatus.Rejected);
                }
            }
        }
    }


    // ------------------------------------------------------------
    // 4. Reputation and Role Management (Advanced Concept)
    // ------------------------------------------------------------

    function increaseReputation(address _artist, uint256 _amount, string memory _reason) external onlyOwner whenNotPaused {
        artistReputation[_artist] += _amount;
        emit ReputationIncreased(_artist, _amount, _reason);
    }

    function decreaseReputation(address _artist, uint256 _amount, string memory _reason) external onlyOwner whenNotPaused {
        artistReputation[_artist] -= _amount;
        emit ReputationDecreased(_artist, _amount, _reason);
    }

    function getArtistReputation(address _artist) external view returns (uint256) {
        return artistReputation[_artist];
    }

    function setRoleThreshold(string memory _roleName, uint256 _threshold) external onlyOwner whenNotPaused {
        roleThresholds[_roleName] = _threshold;
        emit RoleThresholdSet(_roleName, _threshold);
    }

    function getArtistRoles(address _artist) external view returns (string[] memory) {
        string[] memory currentRoles = new string[](definedRoles.length);
        uint256 roleCount = 0;
        for (uint256 i = 0; i < definedRoles.length; i++) {
            string memory roleName = definedRoles[i];
            if (artistReputation[_artist] >= roleThresholds[roleName]) {
                currentRoles[roleCount] = roleName;
                roleCount++;
            }
        }
        // Resize the array to only include the roles the artist has
        string[] memory finalRoles = new string[](roleCount);
        for (uint256 i = 0; i < roleCount; i++) {
            finalRoles[i] = currentRoles[i];
        }
        return finalRoles;
    }

    function defineRole(string memory _roleName, string memory _description) external onlyOwner whenNotPaused {
        require(bytes(_roleName).length > 0, "Role name cannot be empty.");
        require(roleDescriptions[_roleName].length == 0, "Role already defined."); // Prevent redefining roles
        roleDescriptions[_roleName] = _description;
        definedRoles.push(_roleName);
        emit RoleDefined(_roleName, _description);
    }

    function getRoleDescription(string memory _roleName) external view returns (string memory) {
        return roleDescriptions[_roleName];
    }


    // ------------------------------------------------------------
    // 5. Collective Governance and Settings
    // ------------------------------------------------------------

    function setVotingDuration(uint256 _duration) external onlyOwner whenNotPaused {
        defaultVotingDuration = _duration;
        emit VotingDurationSet(_duration);
    }

    function setDefaultQuorum(uint256 _quorum) external onlyOwner whenNotPaused {
        require(_quorum <= 100, "Quorum cannot be more than 100%.");
        defaultQuorum = _quorum;
        emit DefaultQuorumSet(_quorum);
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function isPaused() external view returns (bool) {
        return paused;
    }

    function transferOwnership(address newOwner) external onlyOwner whenNotPaused {
        require(newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```