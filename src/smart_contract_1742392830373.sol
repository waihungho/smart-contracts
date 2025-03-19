```solidity
/**
 * @title Decentralized Dynamic Content NFT Platform with Reputation and Governance
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized platform for content creation and curation, leveraging NFTs, reputation, and governance.
 *
 * **Contract Outline:**
 *
 * **Data Structures:**
 * - Content Proposal Struct: Represents content submissions with metadata, author, status, votes, etc.
 * - Content NFT Struct: Represents published content as NFTs, linking to metadata and author.
 * - Member Struct: Represents platform members with reputation scores and roles.
 * - Governance Proposal Struct:  Represents proposals for platform parameter changes.
 *
 * **State Variables:**
 * - contentProposals: Mapping to store content proposals by ID.
 * - contentNFTs: Mapping to store content NFTs by ID and track ownership.
 * - members: Mapping to store member information by address.
 * - governanceProposals: Mapping to store governance proposals by ID.
 * - proposalCounter, contentCounter, governanceCounter: Counters for IDs.
 * - reputationThresholds: Mapping to define reputation levels and associated thresholds.
 * - votingDuration: Default voting duration for proposals.
 * - quorumPercentage: Percentage of votes needed for proposal approval.
 * - platformFeePercentage: Percentage fee charged on NFT sales (optional).
 * - adminAddress: Address of the platform administrator.
 *
 * **Modifiers:**
 * - onlyMember: Restricts function access to registered platform members.
 * - onlyAdmin: Restricts function access to the platform administrator.
 * - proposalExists: Checks if a content proposal exists.
 * - contentExists: Checks if a content NFT exists.
 * - memberExists: Checks if a member exists.
 * - governanceProposalExists: Checks if a governance proposal exists.
 * - votingActive: Checks if a voting period is currently active for a proposal.
 *
 * **Events:**
 * - ContentProposalCreated: Emitted when a new content proposal is submitted.
 * - ContentProposalVoted: Emitted when a member votes on a content proposal.
 * - ContentProposalApproved: Emitted when a content proposal is approved.
 * - ContentProposalRejected: Emitted when a content proposal is rejected.
 * - ContentNFTMinted: Emitted when a content NFT is minted.
 * - MemberJoined: Emitted when a new member joins the platform.
 * - MemberReputationUpdated: Emitted when a member's reputation is updated.
 * - GovernanceProposalCreated: Emitted when a new governance proposal is submitted.
 * - GovernanceProposalVoted: Emitted when a member votes on a governance proposal.
 * - GovernanceProposalExecuted: Emitted when a governance proposal is executed.
 * - GovernanceProposalRejected: Emitted when a governance proposal is rejected.
 * - PlatformFeeUpdated: Emitted when the platform fee percentage is updated.
 *
 * **Functions:**
 *
 * **Content Proposal Functions:**
 * 1. submitContentProposal(string memory _title, string memory _metadataURI): Allows members to submit content proposals.
 * 2. voteOnContentProposal(uint256 _proposalId, bool _vote): Allows members to vote on content proposals.
 * 3. finalizeContentProposal(uint256 _proposalId): Finalizes a content proposal after voting period, mints NFT if approved.
 * 4. getContentProposalDetails(uint256 _proposalId): Retrieves detailed information about a content proposal.
 * 5. getContentNFTDetails(uint256 _contentId): Retrieves detailed information about a minted Content NFT.
 * 6. getContentNFTAuthor(uint256 _contentId): Retrieves the author of a Content NFT.
 * 7. getContentNFTOwner(uint256 _contentId): Retrieves the current owner of a Content NFT.
 *
 * **Member & Reputation Functions:**
 * 8. joinPlatform(string memory _username): Allows users to join the platform as members.
 * 9. getMemberReputation(address _memberAddress): Retrieves the reputation score of a member.
 * 10. increaseMemberReputation(address _memberAddress, uint256 _amount): (Admin) Increases a member's reputation.
 * 11. decreaseMemberReputation(address _memberAddress, uint256 _amount): (Admin) Decreases a member's reputation.
 * 12. getMemberDetails(address _memberAddress): Retrieves detailed information about a platform member.
 * 13. setReputationThreshold(uint256 _level, uint256 _threshold): (Admin) Sets reputation threshold for a level.
 * 14. getReputationThreshold(uint256 _level): Retrieves the reputation threshold for a level.
 *
 * **Governance Functions:**
 * 15. submitGovernanceProposal(string memory _description, bytes memory _data): Allows members to submit governance proposals.
 * 16. voteOnGovernanceProposal(uint256 _proposalId, bool _vote): Allows members to vote on governance proposals.
 * 17. finalizeGovernanceProposal(uint256 _proposalId): Finalizes a governance proposal and executes if approved.
 * 18. getGovernanceProposalDetails(uint256 _proposalId): Retrieves detailed information about a governance proposal.
 * 19. setVotingDuration(uint256 _durationInSeconds): (Admin Governance) Sets the default voting duration.
 * 20. setQuorumPercentage(uint256 _percentage): (Admin Governance) Sets the quorum percentage for proposals.
 * 21. setPlatformFeePercentage(uint256 _percentage): (Admin Governance) Sets the platform fee percentage for NFT sales.
 * 22. getPlatformFeePercentage(): Returns the current platform fee percentage.
 *
 * **Utility Functions:**
 * 23. withdrawPlatformFees(): (Admin) Allows the admin to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

contract DynamicContentPlatform {

    // --- Data Structures ---
    struct ContentProposal {
        uint256 id;
        address proposer;
        string title;
        string metadataURI;
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 upVotes;
        uint256 downVotes;
        bool finalized;
        bool approved;
    }

    struct ContentNFT {
        uint256 id;
        address author;
        string metadataURI;
        uint256 mintTime;
    }

    struct Member {
        address memberAddress;
        string username;
        uint256 reputation;
        uint256 joinTime;
        bool isActive;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        bytes data; // Encoded function call data for execution
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 upVotes;
        uint256 downVotes;
        bool finalized;
        bool approved;
        bool executed;
    }

    // --- State Variables ---
    mapping(uint256 => ContentProposal) public contentProposals;
    mapping(uint256 => ContentNFT) public contentNFTs;
    mapping(address => Member) public members;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    uint256 public proposalCounter;
    uint256 public contentCounter;
    uint256 public governanceCounter;

    mapping(uint256 => uint256) public reputationThresholds; // Level => Threshold
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Percentage for approval
    uint256 public platformFeePercentage = 2; // Percentage fee on NFT sales (e.g., 2% = 2)
    address public adminAddress;
    address payable public platformFeeWallet; // Wallet to collect platform fees

    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember(msg.sender), "Not a platform member.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(contentProposals[_proposalId].id != 0, "Content proposal does not exist.");
        _;
    }

    modifier contentExists(uint256 _contentId) {
        require(contentNFTs[_contentId].id != 0, "Content NFT does not exist.");
        _;
    }

    modifier memberExists(address _memberAddress) {
        require(isMember(_memberAddress), "Member does not exist.");
        _;
    }

    modifier governanceProposalExists(uint256 _proposalId) {
        require(governanceProposals[_proposalId].id != 0, "Governance proposal does not exist.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(block.timestamp <= contentProposals[_proposalId].votingEndTime && !contentProposals[_proposalId].finalized, "Voting is not active or proposal finalized.");
        _;
    }

    modifier governanceVotingActive(uint256 _proposalId) {
        require(block.timestamp <= governanceProposals[_proposalId].votingEndTime && !governanceProposals[_proposalId].finalized, "Voting is not active or proposal finalized.");
        _;
    }


    // --- Events ---
    event ContentProposalCreated(uint256 proposalId, address proposer, string title);
    event ContentProposalVoted(uint256 proposalId, address voter, bool vote);
    event ContentProposalApproved(uint256 proposalId, uint256 contentId);
    event ContentProposalRejected(uint256 proposalId);
    event ContentNFTMinted(uint256 contentId, address author, string metadataURI);
    event MemberJoined(address memberAddress, string username);
    event MemberReputationUpdated(address memberAddress, uint256 newReputation);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event GovernanceProposalRejected(uint256 proposalId);
    event PlatformFeeUpdated(uint256 percentage);
    event PlatformFeesWithdrawn(address admin, uint256 amount);


    // --- Constructor ---
    constructor(address payable _feeWallet) {
        adminAddress = msg.sender;
        platformFeeWallet = _feeWallet;
        reputationThresholds[1] = 100; // Example: Level 1 reputation threshold is 100
        reputationThresholds[2] = 500; // Example: Level 2 reputation threshold is 500
    }

    // --- Helper Functions ---
    function isMember(address _memberAddress) internal view returns (bool) {
        return members[_memberAddress].isActive;
    }

    function _mintContentNFT(uint256 _proposalId) internal {
        ContentProposal storage proposal = contentProposals[_proposalId];
        require(!proposal.finalized && proposal.approved, "Proposal not approved or already finalized.");

        contentCounter++;
        contentNFTs[contentCounter] = ContentNFT({
            id: contentCounter,
            author: proposal.proposer,
            metadataURI: proposal.metadataURI,
            mintTime: block.timestamp
        });

        emit ContentNFTMinted(contentCounter, proposal.proposer, proposal.metadataURI);
        emit ContentProposalApproved(_proposalId, contentCounter);
    }

    function _executeGovernanceProposal(uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.finalized && proposal.approved && !proposal.executed, "Proposal not approved, finalized, or already executed.");

        (bool success, ) = address(this).call(proposal.data); // Execute the encoded function call
        require(success, "Governance proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }


    // --- Content Proposal Functions ---
    function submitContentProposal(string memory _title, string memory _metadataURI) public onlyMember {
        proposalCounter++;
        contentProposals[proposalCounter] = ContentProposal({
            id: proposalCounter,
            proposer: msg.sender,
            title: _title,
            metadataURI: _metadataURI,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            upVotes: 0,
            downVotes: 0,
            finalized: false,
            approved: false
        });

        emit ContentProposalCreated(proposalCounter, msg.sender, _title);
    }

    function voteOnContentProposal(uint256 _proposalId, bool _vote) public onlyMember proposalExists(_proposalId) votingActive(_proposalId) {
        ContentProposal storage proposal = contentProposals[_proposalId];

        // Prevent double voting (simple approach, can be improved with mapping if needed for more complex voting)
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal."); // Basic anti-self-voting
        // In a real system, track individual votes per address to prevent multiple votes from same user

        if (_vote) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit ContentProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeContentProposal(uint256 _proposalId) public proposalExists(_proposalId) {
        ContentProposal storage proposal = contentProposals[_proposalId];
        require(!proposal.finalized && block.timestamp > proposal.votingEndTime, "Voting not ended or already finalized.");

        uint256 totalVotes = proposal.upVotes + proposal.downVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        if (proposal.upVotes >= quorum) {
            proposal.approved = true;
            _mintContentNFT(_proposalId); // Mint NFT if approved
        } else {
            proposal.approved = false;
            emit ContentProposalRejected(_proposalId);
        }
        proposal.finalized = true;
    }

    function getContentProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (ContentProposal memory) {
        return contentProposals[_proposalId];
    }

    function getContentNFTDetails(uint256 _contentId) public view contentExists(_contentId) returns (ContentNFT memory) {
        return contentNFTs[_contentId];
    }

    function getContentNFTAuthor(uint256 _contentId) public view contentExists(_contentId) returns (address) {
        return contentNFTs[_contentId].author;
    }

    function getContentNFTOwner(uint256 _contentId) public view contentExists(_contentId) returns (address) {
        // In a real NFT implementation, this would fetch the owner from an ERC721/ERC1155 contract.
        // For simplicity in this example, we assume the author is the initial owner.
        return contentNFTs[_contentId].author;
    }


    // --- Member & Reputation Functions ---
    function joinPlatform(string memory _username) public {
        require(!isMember(msg.sender), "Already a member.");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            username: _username,
            reputation: 0,
            joinTime: block.timestamp,
            isActive: true
        });
        emit MemberJoined(msg.sender, _username);
    }

    function getMemberReputation(address _memberAddress) public view memberExists(_memberAddress) returns (uint256) {
        return members[_memberAddress].reputation;
    }

    function increaseMemberReputation(address _memberAddress, uint256 _amount) public onlyAdmin memberExists(_memberAddress) {
        members[_memberAddress].reputation += _amount;
        emit MemberReputationUpdated(_memberAddress, members[_memberAddress].reputation);
    }

    function decreaseMemberReputation(address _memberAddress, uint256 _amount) public onlyAdmin memberExists(_memberAddress) {
        members[_memberAddress].reputation -= _amount;
        emit MemberReputationUpdated(_memberAddress, members[_memberAddress].reputation);
    }

    function getMemberDetails(address _memberAddress) public view memberExists(_memberAddress) returns (Member memory) {
        return members[_memberAddress];
    }

    function setReputationThreshold(uint256 _level, uint256 _threshold) public onlyAdmin {
        reputationThresholds[_level] = _threshold;
    }

    function getReputationThreshold(uint256 _level) public view returns (uint256) {
        return reputationThresholds[_level];
    }


    // --- Governance Functions ---
    function submitGovernanceProposal(string memory _description, bytes memory _data) public onlyMember {
        governanceCounter++;
        governanceProposals[governanceCounter] = GovernanceProposal({
            id: governanceCounter,
            proposer: msg.sender,
            description: _description,
            data: _data,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            upVotes: 0,
            downVotes: 0,
            finalized: false,
            approved: false,
            executed: false
        });
        emit GovernanceProposalCreated(governanceCounter, msg.sender, _description);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public onlyMember governanceProposalExists(_proposalId) governanceVotingActive(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
         // Prevent double voting (simple approach, can be improved with mapping if needed for more complex voting)
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal."); // Basic anti-self-voting

        if (_vote) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeGovernanceProposal(uint256 _proposalId) public governanceProposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.finalized && block.timestamp > proposal.votingEndTime, "Voting not ended or already finalized.");

        uint256 totalVotes = proposal.upVotes + proposal.downVotes;
        uint256 quorum = (totalVotes * quorumPercentage) / 100;

        if (proposal.upVotes >= quorum) {
            proposal.approved = true;
            _executeGovernanceProposal(_proposalId); // Execute governance action
        } else {
            proposal.approved = false;
            emit GovernanceProposalRejected(_proposalId);
        }
        proposal.finalized = true;
    }

    function getGovernanceProposalDetails(uint256 _proposalId) public view governanceProposalExists(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    // Example Governance actions - called via governance proposals
    function setVotingDuration(uint256 _durationInSeconds) public onlyAdmin { // Admin can also set directly, or governance can propose
        votingDuration = _durationInSeconds;
    }

    function setQuorumPercentage(uint256 _percentage) public onlyAdmin { // Admin can also set directly, or governance can propose
        quorumPercentage = _percentage;
    }

    function setPlatformFeePercentage(uint256 _percentage) public onlyAdmin { // Admin can also set directly, or governance can propose
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _percentage;
        emit PlatformFeeUpdated(_percentage);
    }

    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    // --- Utility Functions ---
    function withdrawPlatformFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 feeBalance = balance; // Assuming all contract balance is platform fees for simplicity
        require(feeBalance > 0, "No platform fees to withdraw.");

        (bool success, ) = platformFeeWallet.call{value: feeBalance}("");
        require(success, "Platform fee withdrawal failed.");
        emit PlatformFeesWithdrawn(msg.sender, feeBalance);
    }

    // Fallback function to receive Ether (for platform fees, etc.)
    receive() external payable {}
}
```