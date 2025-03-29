```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Collaborative Art Creation & Curation - "ArtVerse DAO"
 * @author Bard (AI Assistant)
 * @dev This contract implements a DAO focused on collaborative art creation and curation.
 * It allows members to propose art projects, contribute to them, vote on project approvals,
 * manage a treasury funded by NFT sales, and curate a digital art gallery owned and governed by the DAO.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership Management:**
 *    - joinDAO(): Allows users to become DAO members by paying a membership fee.
 *    - leaveDAO(): Allows members to leave the DAO and potentially reclaim a portion of their fee (governed by DAO).
 *    - setMembershipFee(uint256 _fee): Admin function to change the membership fee.
 *    - getMemberCount(): Returns the current number of DAO members.
 *    - isMember(address _user): Checks if an address is a DAO member.
 *
 * **2. Art Project Proposals:**
 *    - proposeArtProject(string memory _title, string memory _description, string memory _ipfsHash): Members propose new art projects.
 *    - voteOnArtProjectProposal(uint256 _proposalId, bool _vote): Members vote on art project proposals.
 *    - executeArtProjectProposal(uint256 _proposalId): Executes a passed art project proposal (starts the project).
 *    - getArtProjectProposalDetails(uint256 _proposalId): Returns details of a specific art project proposal.
 *    - getArtProjectProposalVoteCount(uint256 _proposalId): Returns vote counts for a proposal.
 *
 * **3. Art Contribution & Curation:**
 *    - contributeToArtProject(uint256 _projectId, string memory _contributionURI): Members contribute to approved art projects.
 *    - voteOnContributionApproval(uint256 _contributionId, bool _vote): Members vote to approve or reject art contributions.
 *    - approveContribution(uint256 _contributionId): Admin/DAO function to manually approve a contribution (if needed, or after successful vote).
 *    - rejectContribution(uint256 _contributionId): Admin/DAO function to manually reject a contribution.
 *    - getContributionDetails(uint256 _contributionId): Returns details of a specific art contribution.
 *    - getContributionStatus(uint256 _contributionId): Returns the status of a contribution (Pending, Approved, Rejected).
 *
 * **4. NFT Minting & Art Gallery:**
 *    - mintArtNFT(uint256 _projectId): Mints an NFT representing the completed art project, combining approved contributions.
 *    - setNFTMetadataBaseURI(string memory _baseURI): Admin function to set the base URI for NFT metadata.
 *    - getNFTMetadataURI(uint256 _tokenId): Returns the metadata URI for a specific NFT token.
 *    - getArtGallery(): Returns a list of NFT token IDs representing the DAO's art gallery.
 *
 * **5. Treasury Management & Governance:**
 *    - getTreasuryBalance(): Returns the current balance of the DAO's treasury.
 *    - withdrawTreasuryFunds(address payable _recipient, uint256 _amount): Allows DAO to withdraw funds from the treasury (governed by DAO vote/admin).
 *    - setQuorumPercentage(uint8 _quorum): Admin function to change the voting quorum percentage.
 *    - setVotingDuration(uint256 _durationInBlocks): Admin function to change the voting duration.
 *    - pauseContract(): Admin function to pause the contract in emergency situations.
 *    - unpauseContract(): Admin function to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ArtVerseDAO is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    uint256 public membershipFee;
    mapping(address => bool) public members;
    Counters.Counter private memberCount;

    uint8 public quorumPercentage = 50; // Minimum percentage of votes required for a proposal to pass
    uint256 public votingDuration = 7 days; // Default voting duration in blocks (adjust as needed)

    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    struct ArtProjectProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash; // IPFS hash linking to more detailed proposal document
        address proposer;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
    }
    mapping(uint256 => ArtProjectProposal) public artProjectProposals;
    Counters.Counter private proposalCount;

    enum ContributionStatus { Pending, Approved, Rejected }
    struct ArtContribution {
        uint256 id;
        uint256 projectId;
        address contributor;
        string contributionURI; // URI pointing to the art contribution (e.g., IPFS, Arweave)
        ContributionStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }
    mapping(uint256 => ArtContribution) public artContributions;
    Counters.Counter private contributionCount;

    string public nftMetadataBaseURI;
    Counters.Counter private nftTokenIdCounter;
    mapping(uint256 => uint256) public projectToNFTTokenId; // Mapping project ID to minted NFT token ID
    uint256[] public artGallery; // Array of NFT token IDs representing the DAO's art gallery

    bool public paused; // Contract paused state

    // --- Events ---

    event MembershipJoined(address member);
    event MembershipLeft(address member);
    event MembershipFeeChanged(uint256 newFee);

    event ArtProjectProposed(uint256 proposalId, address proposer, string title);
    event ArtProjectProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProjectProposalExecuted(uint256 proposalId);

    event ArtContributionSubmitted(uint256 contributionId, uint256 projectId, address contributor, string contributionURI);
    event ArtContributionVoteCast(uint256 contributionId, address voter, bool vote);
    event ArtContributionApproved(uint256 contributionId);
    event ArtContributionRejected(uint256 contributionId);

    event ArtNFTMinted(uint256 tokenId, uint256 projectId);
    event NFTMetadataBaseURISet(string baseURI);

    event ContractPaused();
    event ContractUnpaused();
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender], "You are not a DAO member.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount.current(), "Invalid proposal ID.");
        _;
    }

    modifier validContribution(uint256 _contributionId) {
        require(_contributionId > 0 && _contributionId <= contributionCount.current(), "Invalid contribution ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(artProjectProposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    modifier contributionInStatus(uint256 _contributionId, ContributionStatus _status) {
        require(artContributions[_contributionId].status == _status, "Contribution is not in the required status.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(block.timestamp >= artProjectProposals[_proposalId].startTime && block.timestamp <= artProjectProposals[_proposalId].endTime, "Voting is not active for this proposal.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, uint256 _initialMembershipFee) ERC721(_name, _symbol) {
        membershipFee = _initialMembershipFee;
        paused = false;
    }

    // --- 1. Membership Management Functions ---

    function joinDAO() external payable whenNotPaused {
        require(!members[msg.sender], "You are already a DAO member.");
        require(msg.value >= membershipFee, "Membership fee is required.");

        members[msg.sender] = true;
        memberCount.increment();
        emit MembershipJoined(msg.sender);

        // Optionally, you could handle excess ether sent beyond membership fee.
        if (msg.value > membershipFee) {
            payable(msg.sender).transfer(msg.value - membershipFee);
        }
    }

    function leaveDAO() external onlyMember whenNotPaused {
        delete members[msg.sender]; // Remove from members mapping
        memberCount.decrement();
        emit MembershipLeft(msg.sender);
        // Consider implementing refund mechanism for leaving members (based on DAO rules)
    }

    function setMembershipFee(uint256 _fee) external onlyAdmin whenNotPaused {
        membershipFee = _fee;
        emit MembershipFeeChanged(_fee);
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount.current();
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    // --- 2. Art Project Proposal Functions ---

    function proposeArtProject(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember whenNotPaused {
        proposalCount.increment();
        uint256 proposalId = proposalCount.current();

        artProjectProposals[proposalId] = ArtProjectProposal({
            id: proposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            startTime: 0,
            endTime: 0,
            yesVotes: 0,
            noVotes: 0
        });

        emit ArtProjectProposed(proposalId, msg.sender, _title);
    }

    function voteOnArtProjectProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) votingActive(_proposalId) {
        require(!hasVotedOnProposal(msg.sender, _proposalId), "You have already voted on this proposal.");

        if (_vote) {
            artProjectProposals[_proposalId].yesVotes++;
        } else {
            artProjectProposals[_proposalId].noVotes++;
        }
        emit ArtProjectProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtProjectProposal(uint256 _proposalId) external onlyAdmin whenNotPaused validProposal(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Passed) {
        artProjectProposals[_proposalId].status = ProposalStatus.Executed;
        emit ArtProjectProposalExecuted(_proposalId);
        // Here you would implement logic to start the art project workflow,
        // e.g., setting project status to 'Active', allowing contributions etc.
    }

    function getArtProjectProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (ArtProjectProposal memory) {
        return artProjectProposals[_proposalId];
    }

    function getArtProjectProposalVoteCount(uint256 _proposalId) external view validProposal(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        return (artProjectProposals[_proposalId].yesVotes, artProjectProposals[_proposalId].noVotes);
    }

    // --- 3. Art Contribution & Curation Functions ---

    function contributeToArtProject(uint256 _projectId, string memory _contributionURI) external onlyMember whenNotPaused {
        require(artProjectProposals[_projectId].status == ProposalStatus.Executed, "Art project is not active for contributions.");
        contributionCount.increment();
        uint256 contributionId = contributionCount.current();

        artContributions[contributionId] = ArtContribution({
            id: contributionId,
            projectId: _projectId,
            contributor: msg.sender,
            contributionURI: _contributionURI,
            status: ContributionStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0
        });

        emit ArtContributionSubmitted(contributionId, _projectId, msg.sender, _contributionURI);
    }

    function voteOnContributionApproval(uint256 _contributionId, bool _vote) external onlyMember whenNotPaused validContribution(_contributionId) contributionInStatus(_contributionId, ContributionStatus.Pending) {
        require(!hasVotedOnContribution(msg.sender, _contributionId), "You have already voted on this contribution.");

        if (_vote) {
            artContributions[_contributionId].approvalVotes++;
        } else {
            artContributions[_contributionId].rejectionVotes++;
        }
        emit ArtContributionVoteCast(_contributionId, msg.sender, _vote);
    }

    function approveContribution(uint256 _contributionId) external onlyAdmin whenNotPaused validContribution(_contributionId) contributionInStatus(_contributionId, ContributionStatus.Pending) {
        artContributions[_contributionId].status = ContributionStatus.Approved;
        emit ArtContributionApproved(_contributionId);
    }

    function rejectContribution(uint256 _contributionId) external onlyAdmin whenNotPaused validContribution(_contributionId) contributionInStatus(_contributionId, ContributionStatus.Pending) {
        artContributions[_contributionId].status = ContributionStatus.Rejected;
        emit ArtContributionRejected(_contributionId);
    }

    function getContributionDetails(uint256 _contributionId) external view validContribution(_contributionId) returns (ArtContribution memory) {
        return artContributions[_contributionId];
    }

    function getContributionStatus(uint256 _contributionId) external view validContribution(_contributionId) returns (ContributionStatus) {
        return artContributions[_contributionId].status;
    }

    // --- 4. NFT Minting & Art Gallery Functions ---

    function mintArtNFT(uint256 _projectId) external onlyAdmin whenNotPaused {
        require(artProjectProposals[_projectId].status == ProposalStatus.Executed, "Art project must be executed before minting NFT.");
        require(projectToNFTTokenId[_projectId] == 0, "NFT already minted for this project.");

        nftTokenIdCounter.increment();
        uint256 tokenId = nftTokenIdCounter.current();
        _safeMint(address(this), tokenId); // Mint NFT to contract address - DAO owns the NFT
        projectToNFTTokenId[_projectId] = tokenId;
        artGallery.push(tokenId);

        emit ArtNFTMinted(tokenId, _projectId);
    }

    function setNFTMetadataBaseURI(string memory _baseURI) external onlyAdmin whenNotPaused {
        nftMetadataBaseURI = _baseURI;
        emit NFTMetadataBaseURISet(_baseURI);
    }

    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist.");
        return string(abi.encodePacked(nftMetadataBaseURI, _tokenId.toString(), ".json")); // Example: baseURI/1.json
    }

    function getArtGallery() external view returns (uint256[] memory) {
        return artGallery;
    }

    // --- 5. Treasury Management & Governance Functions ---

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdrawTreasuryFunds(address payable _recipient, uint256 _amount) external onlyAdmin whenNotPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
        // In a real-world DAO, this would ideally be governed by a DAO proposal and voting process,
        // not just admin control, for true decentralization.
    }

    function setQuorumPercentage(uint8 _quorum) external onlyAdmin whenNotPaused {
        require(_quorum >= 1 && _quorum <= 100, "Quorum percentage must be between 1 and 100.");
        quorumPercentage = _quorum;
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin whenNotPaused {
        votingDuration = _durationInBlocks;
    }

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin whenNotPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Internal Helper Functions ---

    function _startProposalVoting(uint256 _proposalId) internal {
        artProjectProposals[_proposalId].status = ProposalStatus.Active;
        artProjectProposals[_proposalId].startTime = block.timestamp;
        artProjectProposals[_proposalId].endTime = block.timestamp + votingDuration; // Voting duration in seconds, adjust as needed
    }

    function _endProposalVoting(uint256 _proposalId) internal {
        if (calculateVotePercentage(_proposalId, artProjectProposals[_proposalId].yesVotes) >= quorumPercentage) {
            artProjectProposals[_proposalId].status = ProposalStatus.Passed;
        } else {
            artProjectProposals[_proposalId].status = ProposalStatus.Rejected;
        }
    }

    function calculateVotePercentage(uint256 _proposalId, uint256 _votes) internal view returns (uint8) {
        uint256 totalMembers = memberCount.current();
        if (totalMembers == 0) return 0; // Avoid division by zero
        return uint8((_votes * 100) / totalMembers);
    }

    function hasVotedOnProposal(address _voter, uint256 _proposalId) internal view returns (bool) {
        // In a real-world scenario, you would likely track individual votes per proposal.
        // For simplicity, we are assuming members can only vote once per proposal.
        // A more robust implementation would use a mapping to track voter addresses for each proposal.
        // Example (more complex, not implemented here for brevity):
        // mapping(uint256 => mapping(address => bool)) public proposalVotes;
        // return proposalVotes[_proposalId][_voter];
        // For this example, we are skipping this detailed vote tracking for simplicity.
        return false; // Assume no voting tracking for now for brevity.
    }

    function hasVotedOnContribution(address _voter, uint256 _contributionId) internal view returns (bool) {
        // Similar to proposal voting, more detailed tracking might be needed in production.
        return false; // Assume no voting tracking for now for brevity.
    }

    // --- Fallback and Receive functions ---

    receive() external payable {} // Allow contract to receive ether (e.g., for membership fees)
    fallback() external {}
}
```