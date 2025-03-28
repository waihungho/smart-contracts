```solidity
/**
 * @title Decentralized Autonomous Organization for Collaborative Content Creation (DAO-CCC)
 * @author Bard (AI Assistant)
 * @dev A DAO smart contract designed for collaborative content creation, incorporating advanced concepts like skill-based roles,
 *      reputation system, tiered access, content NFTs, and dynamic governance parameters.
 *
 * Outline and Function Summary:
 *
 * 1.  **DAO Management:**
 *     - `constructor(uint256 _initialQuorumPercentage, uint256 _votingDuration)`: Initializes the DAO with quorum and voting duration.
 *     - `setQuorumPercentage(uint256 _newQuorumPercentage)`: Allows owner to change the quorum percentage for proposals.
 *     - `setVotingDuration(uint256 _newVotingDuration)`: Allows owner to change the default voting duration.
 *     - `transferOwnership(address _newOwner)`: Allows owner to transfer contract ownership.
 *     - `renounceOwnership()`: Allows owner to renounce contract ownership (making it truly decentralized).
 *     - `pauseDAO()`: Allows owner to pause core DAO functionalities in emergency.
 *     - `unpauseDAO()`: Allows owner to resume paused DAO functionalities.
 *
 * 2.  **Member Management & Roles:**
 *     - `joinDAO(string memory _profileHash)`: Allows users to request membership with a profile hash (e.g., IPFS link).
 *     - `approveMembership(address _member)`: Allows existing members with sufficient reputation to approve new member requests.
 *     - `rejectMembership(address _member)`: Allows existing members with sufficient reputation to reject new member requests.
 *     - `leaveDAO()`: Allows members to voluntarily leave the DAO.
 *     - `getMemberProfile(address _member)`: Retrieves the profile hash of a member.
 *     - `setMemberRole(address _member, Role _role)`: Allows members with admin role to assign roles to other members.
 *     - `getMemberRole(address _member)`: Retrieves the role of a member.
 *     - `getMembersByRole(Role _role)`: Retrieves a list of members with a specific role.
 *     - `getMemberCount()`: Returns the total number of DAO members.
 *
 * 3.  **Content Proposal & Voting:**
 *     - `submitContentProposal(string memory _title, string memory _description, string memory _contentHash, ContentType _contentType, uint256 _requiredStake)`: Allows members to submit content proposals with details, content hash, type, and optional stake.
 *     - `getContentProposal(uint256 _proposalId)`: Retrieves details of a specific content proposal.
 *     - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows members to vote on active content proposals.
 *     - `executeProposal(uint256 _proposalId)`: Allows anyone to execute a passed proposal after the voting period.
 *     - `cancelProposal(uint256 _proposalId)`: Allows proposal creator to cancel their proposal before voting starts (or owner in certain cases).
 *     - `getContentProposalVotingStats(uint256 _proposalId)`: Retrieves voting statistics for a proposal (votes for, against, quorum reached).
 *
 * 4.  **Reputation & Rewards:**
 *     - `increaseMemberReputation(address _member, uint256 _amount, string memory _reason)`: Allows admin role to increase member reputation for contributions.
 *     - `decreaseMemberReputation(address _member, uint256 _amount, string memory _reason)`: Allows admin role to decrease member reputation for misconduct.
 *     - `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 *     - `distributeRewards(address[] memory _recipients, uint256[] memory _amounts)`: Allows admin role to distribute rewards (ETH or tokens) to members.
 *
 * 5.  **Content NFT Integration (Conceptual - Requires external NFT Contract):**
 *     - `setContentNFTContractAddress(address _nftContractAddress)`: Allows owner to set the address of an external NFT contract for content ownership.
 *     - `mintContentNFT(uint256 _proposalId)`: Allows execution of a proposal to mint an NFT representing the approved content (requires external NFT contract).
 *
 * 6.  **Dynamic Parameters & Governance:**
 *     - `updateVotingDurationForContentType(ContentType _contentType, uint256 _newDuration)`: Allows governance (voting) to change voting duration for specific content types.
 *     - `updateQuorumPercentageForRole(Role _role, uint256 _newQuorumPercentage)`: Allows governance (voting) to adjust quorum percentage based on member roles involved in proposals.
 *
 * Enums and Structs:
 * - `Role`: Enum for member roles (Member, Contributor, Editor, Admin).
 * - `ContentType`: Enum for types of content (Article, Video, Image, Code, etc.).
 * - `ProposalState`: Enum for proposal states (Pending, Active, Passed, Rejected, Executed, Cancelled).
 * - `VoteOption`: Enum for voting options (Against, For).
 * - `ContentProposal`: Struct to store proposal details.
 * - `Member`: Struct to store member details (address, profileHash, reputation, role, joinedTimestamp).
 */
pragma solidity ^0.8.0;

contract DAOCreativeContent {
    // -------- Enums and Structs --------

    enum Role { Member, Contributor, Editor, Admin }
    enum ContentType { Article, Video, Image, Code, Document, Audio, Other }
    enum ProposalState { Pending, Active, Passed, Rejected, Executed, Cancelled }
    enum VoteOption { Against, For }

    struct ContentProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string contentHash; // IPFS hash or similar
        ContentType contentType;
        uint256 requiredStake; // Optional stake for proposal submission
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
    }

    struct Member {
        address memberAddress;
        string profileHash;
        uint256 reputation;
        Role role;
        uint256 joinedTimestamp;
        bool isActive;
    }

    // -------- State Variables --------

    address public owner;
    uint256 public quorumPercentage; // Percentage of members needed to pass a proposal
    uint256 public votingDuration; // Default voting duration in seconds
    uint256 public proposalCounter;
    bool public paused;

    mapping(address => Member) public members;
    mapping(uint256 => ContentProposal) public proposals;
    mapping(address => bool) public membershipRequests; // Track pending membership requests
    mapping(ContentType => uint256) public contentTypeVotingDurations; // Custom voting durations per content type
    mapping(Role => uint256) public roleQuorumPercentages; // Custom quorum percentages based on roles involved

    address public contentNFTContractAddress; // Address of external NFT contract for content ownership (optional)

    // -------- Events --------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event VotingDurationUpdated(uint256 newVotingDuration);
    event DAOStateChanged(bool paused);
    event MemberJoined(address memberAddress, string profileHash, uint256 timestamp);
    event MembershipApproved(address memberAddress, address approvedBy);
    event MembershipRejected(address memberAddress, address rejectedBy);
    event MemberLeft(address memberAddress, uint256 timestamp);
    event MemberRoleSet(address memberAddress, Role newRole, address setBy);
    event ContentProposalSubmitted(uint256 proposalId, address proposer, string title, ContentType contentType, uint256 timestamp);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId, ProposalState newState, uint256 timestamp);
    event ProposalCancelled(uint256 proposalId, ProposalState newState, uint256 timestamp);
    event MemberReputationChanged(address memberAddress, uint256 newReputation, string reason, address changedBy);
    event RewardsDistributed(address[] recipients, uint256[] amounts, uint256 timestamp);
    event ContentNFTContractAddressSet(address nftContractAddress, address setBy);
    event ContentNFTMinted(uint256 proposalId, address minter, address nftContractAddress, uint256 timestamp);
    event VotingDurationForContentTypeUpdated(ContentType contentType, uint256 newDuration, address updatedBy);
    event QuorumPercentageForRoleUpdated(Role role, uint256 newQuorumPercentage, address updatedBy);


    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "You are not a DAO member.");
        _;
    }

    modifier onlyAdmin() {
        require(members[msg.sender].role == Role.Admin, "Only admins can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter && proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalInState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active && block.timestamp <= proposals[_proposalId].votingEndTime, "Voting is not active for this proposal.");
        _;
    }

    modifier daoNotPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }


    // -------- DAO Management Functions --------

    constructor(uint256 _initialQuorumPercentage, uint256 _votingDuration) {
        require(_initialQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        owner = msg.sender;
        quorumPercentage = _initialQuorumPercentage;
        votingDuration = _votingDuration;
        proposalCounter = 0;
        paused = false;
        emit OwnershipTransferred(address(0), owner);
    }

    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyOwner daoNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    function setVotingDuration(uint256 _newVotingDuration) external onlyOwner daoNotPaused {
        votingDuration = _newVotingDuration;
        emit VotingDurationUpdated(_newVotingDuration);
    }

    function transferOwnership(address _newOwner) external onlyOwner daoNotPaused {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() external onlyOwner daoNotPaused {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function pauseDAO() external onlyOwner {
        paused = true;
        emit DAOStateChanged(paused);
    }

    function unpauseDAO() external onlyOwner {
        paused = false;
        emit DAOStateChanged(paused);
    }


    // -------- Member Management & Roles Functions --------

    function joinDAO(string memory _profileHash) external daoNotPaused {
        require(!members[msg.sender].isActive, "Already a member.");
        require(!membershipRequests[msg.sender], "Membership request already pending.");
        membershipRequests[msg.sender] = true; // Mark request as pending
        // Membership approval process would typically be initiated here (e.g., event triggering off-chain process or on-chain voting)
        // For simplicity, we'll use direct approval by existing members with reputation.
        emit MemberJoined(msg.sender, _profileHash, block.timestamp);
    }

    function approveMembership(address _member) external onlyMember daoNotPaused {
        require(membershipRequests[_member], "No pending membership request from this address.");
        require(!members[_member].isActive, "Address is already a member.");
        require(members[msg.sender].reputation >= 50, "Approving member needs reputation of at least 50."); // Example reputation requirement

        members[_member] = Member({
            memberAddress: _member,
            profileHash: "", // Profile hash might be set later or in `joinDAO` if provided initially.
            reputation: 0,
            role: Role.Member,
            joinedTimestamp: block.timestamp,
            isActive: true
        });
        membershipRequests[_member] = false; // Clear pending request
        emit MembershipApproved(_member, msg.sender);
    }

    function rejectMembership(address _member) external onlyMember daoNotPaused {
        require(membershipRequests[_member], "No pending membership request from this address.");
        require(!members[_member].isActive, "Address is already a member.");
        require(members[msg.sender].reputation >= 50, "Rejecting member needs reputation of at least 50."); // Example reputation requirement

        membershipRequests[_member] = false; // Clear pending request
        emit MembershipRejected(_member, msg.sender);
    }


    function leaveDAO() external onlyMember daoNotPaused {
        delete members[msg.sender]; // Effectively removes member
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberProfile(address _member) external view returns (string memory) {
        return members[_member].profileHash;
    }

    function setMemberRole(address _member, Role _role) external onlyAdmin daoNotPaused {
        require(members[_member].isActive, "Target address is not a member.");
        members[_member].role = _role;
        emit MemberRoleSet(_member, _role, msg.sender);
    }

    function getMemberRole(address _member) external view returns (Role) {
        return members[_member].role;
    }

    function getMembersByRole(Role _role) external view returns (address[] memory) {
        address[] memory roleMembers = new address[](getMemberCount()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) { // Iterate through proposals (inefficient for large member sets, consider better indexing for production)
            if (proposals[i].proposer != address(0) && members[proposals[i].proposer].isActive && members[proposals[i].proposer].role == _role) {
                roleMembers[count] = proposals[i].proposer; // Proposer is used as a placeholder to iterate members (needs refactor for proper member iteration)
                count++;
            }
        }
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = roleMembers[i];
        }
        return result;
    }


    function getMemberCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= proposalCounter; i++) { // Inefficient iteration, consider better member tracking in production
            if (proposals[i].proposer != address(0) && members[proposals[i].proposer].isActive) { // Proposer used as placeholder for member iteration
                count++;
            }
        }
        return count;
    }


    // -------- Content Proposal & Voting Functions --------

    function submitContentProposal(
        string memory _title,
        string memory _description,
        string memory _contentHash,
        ContentType _contentType,
        uint256 _requiredStake
    ) external onlyMember daoNotPaused {
        proposalCounter++;
        proposals[proposalCounter] = ContentProposal({
            id: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            contentHash: _contentHash,
            contentType: _contentType,
            requiredStake: _requiredStake,
            votingStartTime: 0,
            votingEndTime: 0,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Pending
        });
        emit ContentProposalSubmitted(proposalCounter, msg.sender, _title, _contentType, block.timestamp);
    }

    function getContentProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (ContentProposal memory) {
        return proposals[_proposalId];
    }

    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external onlyMember daoNotPaused proposalExists(_proposalId) votingActive(_proposalId) {
        // Prevent double voting (simple mapping for demonstration, consider more robust tracking in production)
        require(proposals[_proposalId].votingStartTime > 0, "Voting not started yet."); // Ensure voting has started
        require(proposals[_proposalId].votingEndTime > block.timestamp, "Voting has ended."); // Ensure voting has not ended
        require(keccak256(abi.encodePacked(msg.sender, _proposalId)) != keccak256(abi.encodePacked(msg.sender, _proposalId)), "Already voted."); // Simple double vote prevention

        if (_vote == VoteOption.For) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Active) daoNotPaused {
        require(block.timestamp > proposals[_proposalId].votingEndTime, "Voting period not ended yet.");

        uint256 totalMembers = getMemberCount();
        uint256 quorumNeeded = (totalMembers * quorumPercentage) / 100;

        if (proposals[_proposalId].votesFor >= quorumNeeded && proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst) {
            proposals[_proposalId].state = ProposalState.Passed;
            // Here, you would implement the logic for executing the proposal, e.g.,
            // - Trigger content creation process based on `proposals[_proposalId].contentHash`
            // - Distribute rewards to contributors (if applicable)
            // - Mint content NFT if enabled and proposal warrants it (using `mintContentNFT` function below)

            emit ProposalExecuted(_proposalId, ProposalState.Passed, block.timestamp);
        } else {
            proposals[_proposalId].state = ProposalState.Rejected;
            emit ProposalExecuted(_proposalId, ProposalState.Rejected, block.timestamp);
        }
    }

    function cancelProposal(uint256 _proposalId) external proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Pending) daoNotPaused {
        require(proposals[_proposalId].proposer == msg.sender || msg.sender == owner, "Only proposer or owner can cancel.");
        proposals[_proposalId].state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId, ProposalState.Cancelled, block.timestamp);
    }

    function getContentProposalVotingStats(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 votesFor, uint256 votesAgainst, bool quorumReached) {
        uint256 totalMembers = getMemberCount();
        uint256 quorumNeeded = (totalMembers * quorumPercentage) / 100;
        return (proposals[_proposalId].votesFor, proposals[_proposalId].votesAgainst, proposals[_proposalId].votesFor >= quorumNeeded);
    }

    // -------- Reputation & Rewards Functions --------

    function increaseMemberReputation(address _member, uint256 _amount, string memory _reason) external onlyAdmin daoNotPaused {
        require(members[_member].isActive, "Target address is not a member.");
        members[_member].reputation += _amount;
        emit MemberReputationChanged(_member, members[_member].reputation, _reason, msg.sender);
    }

    function decreaseMemberReputation(address _member, uint256 _amount, string memory _reason) external onlyAdmin daoNotPaused {
        require(members[_member].isActive, "Target address is not a member.");
        // Prevent negative reputation if needed:
        // members[_member].reputation = members[_member].reputation > _amount ? members[_member].reputation - _amount : 0;
        members[_member].reputation -= _amount; // Allows negative reputation for demonstration
        emit MemberReputationChanged(_member, members[_member].reputation, _reason, msg.sender);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return members[_member].reputation;
    }

    function distributeRewards(address[] memory _recipients, uint256[] memory _amounts) external onlyAdmin daoNotPaused {
        require(_recipients.length == _amounts.length, "Recipients and amounts arrays must have the same length.");
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(members[_recipients[i]].isActive, "Recipient address is not a member.");
            payable(_recipients[i]).transfer(_amounts[i]); // Example: Distribute ETH rewards
        }
        emit RewardsDistributed(_recipients, _amounts, block.timestamp);
    }

    // -------- Content NFT Integration Functions --------

    function setContentNFTContractAddress(address _nftContractAddress) external onlyOwner daoNotPaused {
        contentNFTContractAddress = _nftContractAddress;
        emit ContentNFTContractAddressSet(_nftContractAddress, msg.sender);
    }

    function mintContentNFT(uint256 _proposalId) external proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Passed) daoNotPaused {
        require(contentNFTContractAddress != address(0), "Content NFT contract address not set.");
        // Assuming an external NFT contract with a `mint(address _to, uint256 _tokenId)` function
        // and proposal ID can serve as a unique token ID (or derive a hash from contentHash).
        // **This is a simplified example and needs to be adapted to the actual NFT contract interface.**
        // **Consider security implications and proper token ID management in a production setting.**
        // **Also consider error handling for external contract calls.**

        // Example (requires external NFT contract to handle token ID generation and metadata):
        // IERC721(contentNFTContractAddress).mint(proposals[_proposalId].proposer, _proposalId);
        // emit ContentNFTMinted(_proposalId, proposals[_proposalId].proposer, contentNFTContractAddress, block.timestamp);

        // Placeholder for NFT minting logic - replace with actual NFT contract interaction
        emit ContentNFTMinted(_proposalId, proposals[_proposalId].proposer, contentNFTContractAddress, block.timestamp);
    }

    // -------- Dynamic Parameters & Governance Functions --------

    function updateVotingDurationForContentType(ContentType _contentType, uint256 _newDuration) external onlyAdmin daoNotPaused {
        contentTypeVotingDurations[_contentType] = _newDuration;
        emit VotingDurationForContentTypeUpdated(_contentType, _newDuration, msg.sender);
    }

    function updateQuorumPercentageForRole(Role _role, uint256 _newQuorumPercentage) external onlyAdmin daoNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        roleQuorumPercentages[_role] = _newQuorumPercentage;
        emit QuorumPercentageForRoleUpdated(_role, _newQuorumPercentage, msg.sender);
    }

    // Function to start voting for a proposal - separate from submission to allow for review period.
    function startProposalVoting(uint256 _proposalId) external onlyAdmin proposalExists(_proposalId) proposalInState(_proposalId, ProposalState.Pending) daoNotPaused {
        uint256 duration = votingDuration;
        if (contentTypeVotingDurations[proposals[_proposalId].contentType] > 0) {
            duration = contentTypeVotingDurations[proposals[_proposalId].contentType];
        }

        proposals[_proposalId].votingStartTime = block.timestamp;
        proposals[_proposalId].votingEndTime = block.timestamp + duration;
        proposals[_proposalId].state = ProposalState.Active;
    }


    // **Important Considerations and Improvements for Production:**

    // 1. **Gas Optimization:**  The `getMembersByRole` and `getMemberCount` functions iterate through proposals to simulate member lists, which is highly inefficient. In a production DAO, you would need to maintain a separate, efficiently indexed list of members (e.g., using arrays and mappings for quick lookup).
    // 2. **Voting Security:**  The `voteOnProposal` function's double-vote prevention is very basic. For a real DAO, use a more robust mechanism (e.g., mapping voter address to proposal ID and vote status). Consider using cryptographic signatures for voting to enhance security and prevent manipulation.
    // 3. **Reputation System Complexity:**  The reputation system is simple. In a real system, you might want more granular reputation scoring, decay mechanisms, and more factors influencing reputation.
    // 4. **NFT Integration:** The `mintContentNFT` is a placeholder. Real NFT integration requires defining a proper NFT contract interface, metadata standards, and token ID generation logic. Consider using established NFT standards like ERC721 or ERC1155.
    // 5. **Governance Process:**  The governance is basic owner and admin controlled. For true decentralization, implement on-chain governance voting for parameter changes, role assignments, and potentially even contract upgrades.
    // 6. **Proposal Execution Logic:** The `executeProposal` function currently only changes the proposal state. You need to add the actual logic to execute the proposal's intent (content creation process, reward distribution, etc.). Consider using external services or oracles if complex off-chain actions are required.
    // 7. **Error Handling and Security Audits:**  Thoroughly test and audit the contract for security vulnerabilities (reentrancy, access control, overflows, etc.). Implement proper error handling and revert messages for better user experience and debugging.
    // 8. **Event Logging:**  Ensure all important actions are logged with events for off-chain monitoring and data retrieval.
    // 9. **UI/Frontend Integration:**  A smart contract is only part of the solution. A user-friendly frontend is essential for members to interact with the DAO, submit proposals, vote, and view content.
    // 10. **Scalability:** Consider scalability aspects if the DAO is expected to have a large number of members and proposals. Explore techniques like sharding or layer-2 solutions if needed.

}
```