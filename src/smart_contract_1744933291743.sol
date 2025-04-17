```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It allows artists to submit art, community members to curate and vote on art,
 * mint NFTs for approved art, manage a treasury, and implement governance features
 * for the collective's operations. This contract aims to be a comprehensive platform
 * for artists and art enthusiasts to collaboratively manage and appreciate digital art.
 *
 * Function Summary:
 * ----------------
 * **Art Submission and Curation:**
 * 1. submitArt(string _artMetadataURI): Allows artists to submit their art with metadata URI.
 * 2. getArtSubmissionDetails(uint256 _submissionId): Retrieves details of a specific art submission.
 * 3. getArtSubmissionStatus(uint256 _submissionId): Checks the current status of an art submission.
 * 4. voteForArt(uint256 _submissionId, bool _approve): Allows community members to vote on art submissions.
 * 5. getArtVotes(uint256 _submissionId): Retrieves the current vote count for an art submission.
 * 6. finalizeArtCuration(uint256 _submissionId): Admin function to finalize curation process for a submission.
 * 7. withdrawArtSubmission(uint256 _submissionId): Allows artists to withdraw their art submission before finalization.
 *
 * **NFT Minting and Management:**
 * 8. mintArtNFT(uint256 _submissionId): Mints an NFT for an approved and finalized art submission.
 * 9. getArtNFTContractAddress(): Returns the address of the deployed Art NFT contract.
 * 10. setArtNFTContractAddress(address _artNFTContractAddress): Admin function to set the Art NFT contract address.
 * 11. setRoyaltyPercentage(uint256 _percentage): Admin function to set the royalty percentage on secondary sales.
 * 12. getRoyaltyPercentage(): Returns the current royalty percentage.
 *
 * **Treasury and Funding:**
 * 13. depositFunds(): Allows anyone to deposit funds into the DAAC treasury.
 * 14. getTreasuryBalance(): Retrieves the current balance of the DAAC treasury.
 * 15. createFundingProposal(string _proposalDescription, uint256 _amount): Allows members to propose funding proposals.
 * 16. voteOnFundingProposal(uint256 _proposalId, bool _approve): Allows community members to vote on funding proposals.
 * 17. finalizeFundingProposal(uint256 _proposalId): Admin function to finalize a funding proposal and execute transfer.
 * 18. getFundingProposalDetails(uint256 _proposalId): Retrieves details of a funding proposal.
 *
 * **Governance and Community:**
 * 19. joinCollective(): Allows users to join the art collective as members.
 * 20. leaveCollective(): Allows members to leave the art collective.
 * 21. getMemberCount(): Returns the current number of members in the collective.
 * 22. isMember(address _account): Checks if an address is a member of the collective.
 * 23. setCurationThreshold(uint256 _threshold): Admin function to set the curation approval threshold.
 * 24. getCurationThreshold(): Returns the current curation approval threshold.
 * 25. setVotingDuration(uint256 _durationInBlocks): Admin function to set the voting duration for proposals.
 * 26. getVotingDuration(): Returns the current voting duration.
 * 27. transferAdminRole(address _newAdmin): Admin function to transfer admin role.
 * 28. emergencyWithdraw(address _recipient): Admin function for emergency fund withdrawal.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DecentralizedArtCollective is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _submissionIds;
    Counters.Counter private _proposalIds;

    // --- Structs and Enums ---
    enum ArtSubmissionStatus { Pending, Approved, Rejected, Finalized, Withdrawn }
    struct ArtSubmission {
        address artist;
        string artMetadataURI;
        ArtSubmissionStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 submissionTimestamp;
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    struct FundingProposal {
        address proposer;
        string description;
        uint256 amount;
        ProposalStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 proposalTimestamp;
    }

    // --- State Variables ---
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => FundingProposal) public fundingProposals;
    mapping(uint256 => mapping(address => bool)) public artSubmissionVotes; // submissionId => voter => vote (true=approve, false=reject)
    mapping(uint256 => mapping(address => bool)) public fundingProposalVotes; // proposalId => voter => vote (true=approve, false=reject)
    mapping(address => bool) public members;
    uint256 public memberCount;

    uint256 public curationThreshold = 50; // Percentage of votes required for approval (e.g., 50% for majority)
    uint256 public votingDurationInBlocks = 100; // Number of blocks for voting duration
    address public artNFTContractAddress;
    uint256 public royaltyPercentage = 5; // Default royalty percentage on NFT sales

    // --- Events ---
    event ArtSubmitted(uint256 submissionId, address artist, string artMetadataURI);
    event ArtVoteCast(uint256 submissionId, address voter, bool approve);
    event ArtCurationFinalized(uint256 submissionId, ArtSubmissionStatus status);
    event ArtNFTMinted(uint256 submissionId, address minter, uint256 tokenId);
    event FundsDeposited(address depositor, uint256 amount);
    event FundingProposalCreated(uint256 proposalId, address proposer, string description, uint256 amount);
    event FundingProposalVoteCast(uint256 proposalId, address voter, bool approve);
    event FundingProposalFinalized(uint256 proposalId, ProposalStatus status);
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event AdminRoleTransferred(address previousAdmin, address newAdmin);
    event EmergencyWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender], "You are not a member of the collective.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= _submissionIds.current(), "Invalid submission ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Invalid proposal ID.");
        _;
    }

    modifier validRoyaltyPercentage(uint256 _percentage) {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100.");
        _;
    }

    // --- Constructor ---
    constructor() payable Ownable() {
        // Constructor can be left empty, Ownable constructor sets the deployer as owner.
    }

    // --- Art Submission and Curation Functions ---
    function submitArt(string memory _artMetadataURI) external onlyMember nonReentrant {
        _submissionIds.increment();
        uint256 submissionId = _submissionIds.current();
        artSubmissions[submissionId] = ArtSubmission({
            artist: msg.sender,
            artMetadataURI: _artMetadataURI,
            status: ArtSubmissionStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            submissionTimestamp: block.timestamp
        });
        emit ArtSubmitted(submissionId, msg.sender, _artMetadataURI);
    }

    function getArtSubmissionDetails(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtSubmission memory) {
        return artSubmissions[_submissionId];
    }

    function getArtSubmissionStatus(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtSubmissionStatus) {
        return artSubmissions[_submissionId].status;
    }

    function voteForArt(uint256 _submissionId, bool _approve) external onlyMember validSubmissionId(_submissionId) nonReentrant {
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Pending, "Voting is not active for this submission.");
        require(!artSubmissionVotes[_submissionId][msg.sender], "You have already voted on this submission.");

        artSubmissionVotes[_submissionId][msg.sender] = true;
        if (_approve) {
            artSubmissions[_submissionId].approvalVotes++;
        } else {
            artSubmissions[_submissionId].rejectionVotes++;
        }
        emit ArtVoteCast(_submissionId, msg.sender, _approve);

        // Auto-finalize if threshold is reached (optional, can be removed and only finalized by admin)
        // _checkAndAutoFinalizeCuration(_submissionId); // Removed auto-finalize for admin control
    }

    function getArtVotes(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (uint256 approvalVotes, uint256 rejectionVotes) {
        return (artSubmissions[_submissionId].approvalVotes, artSubmissions[_submissionId].rejectionVotes);
    }

    function finalizeArtCuration(uint256 _submissionId) external onlyAdmin validSubmissionId(_submissionId) nonReentrant {
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Pending, "Curation already finalized.");

        uint256 totalVotes = artSubmissions[_submissionId].approvalVotes + artSubmissions[_submissionId].rejectionVotes;
        uint256 approvalPercentage = (totalVotes == 0) ? 0 : (artSubmissions[_submissionId].approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= curationThreshold) {
            artSubmissions[_submissionId].status = ArtSubmissionStatus.Approved;
        } else {
            artSubmissions[_submissionId].status = ArtSubmissionStatus.Rejected;
        }
        artSubmissions[_submissionId].status = ArtSubmissionStatus.Finalized; // Mark as finalized regardless of outcome
        emit ArtCurationFinalized(_submissionId, artSubmissions[_submissionId].status);
    }

    function withdrawArtSubmission(uint256 _submissionId) external validSubmissionId(_submissionId) nonReentrant {
        require(artSubmissions[_submissionId].artist == msg.sender, "You are not the artist of this submission.");
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Pending, "Submission cannot be withdrawn at this status.");
        artSubmissions[_submissionId].status = ArtSubmissionStatus.Withdrawn;
        emit ArtCurationFinalized(_submissionId, ArtSubmissionStatus.Withdrawn);
    }

    // --- NFT Minting and Management Functions ---
    function mintArtNFT(uint256 _submissionId) external onlyAdmin validSubmissionId(_submissionId) nonReentrant {
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Approved, "Art must be approved to mint NFT.");
        require(artNFTContractAddress != address(0), "Art NFT contract address not set.");

        // Assume ArtNFT contract has a mint function: mint(address _to, uint256 _submissionId, string memory _tokenURI)
        IERC721 artNFT = IERC721(artNFTContractAddress);
        // For simplicity, assuming submissionId can be used as tokenId, adjust as needed.
        // You would typically need a separate NFT contract deployed, and interact with it here.
        // In a real scenario, you would have a more robust NFT minting process, potentially using a separate NFT contract.
        // This is a placeholder. Implement actual NFT minting logic interacting with your ArtNFT contract.
        // For demonstration, we just emit an event as if minting happened.
        uint256 tokenId = _submissionId; // Using submissionId as tokenId for simplicity, consider a better approach
        //  artNFT.mint(artSubmissions[_submissionId].artist, tokenId, artSubmissions[_submissionId].artMetadataURI); // Example mint call - adapt to your NFT contract
        emit ArtNFTMinted(_submissionId, artSubmissions[_submissionId].artist, tokenId); // Placeholder event emit
    }

    function getArtNFTContractAddress() external view returns (address) {
        return artNFTContractAddress;
    }

    function setArtNFTContractAddress(address _artNFTContractAddress) external onlyAdmin {
        artNFTContractAddress = _artNFTContractAddress;
    }

    function setRoyaltyPercentage(uint256 _percentage) external onlyAdmin validRoyaltyPercentage(_percentage) {
        royaltyPercentage = _percentage;
    }

    function getRoyaltyPercentage() external view returns (uint256) {
        return royaltyPercentage;
    }

    // --- Treasury and Funding Functions ---
    function depositFunds() external payable nonReentrant {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function createFundingProposal(string memory _proposalDescription, uint256 _amount) external onlyMember nonReentrant {
        require(_amount > 0, "Funding amount must be greater than zero.");
        require(_amount <= getTreasuryBalance(), "Funding amount exceeds treasury balance."); // Optional: check if funds are available
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        fundingProposals[proposalId] = FundingProposal({
            proposer: msg.sender,
            description: _proposalDescription,
            amount: _amount,
            status: ProposalStatus.Pending,
            approvalVotes: 0,
            rejectionVotes: 0,
            proposalTimestamp: block.timestamp
        });
        emit FundingProposalCreated(proposalId, msg.sender, _proposalDescription, _amount);
    }

    function voteOnFundingProposal(uint256 _proposalId, bool _approve) external onlyMember validProposalId(_proposalId) nonReentrant {
        require(fundingProposals[_proposalId].status == ProposalStatus.Pending, "Voting is not active for this proposal.");
        require(!fundingProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        fundingProposalVotes[_proposalId][msg.sender] = true;
        if (_approve) {
            fundingProposals[_proposalId].approvalVotes++;
        } else {
            fundingProposals[_proposalId].rejectionVotes++;
        }
        emit FundingProposalVoteCast(_proposalId, msg.sender, _approve);
    }

    function finalizeFundingProposal(uint256 _proposalId) external onlyAdmin validProposalId(_proposalId) nonReentrant {
        require(fundingProposals[_proposalId].status == ProposalStatus.Pending, "Proposal already finalized.");

        uint256 totalVotes = fundingProposals[_proposalId].approvalVotes + fundingProposals[_proposalId].rejectionVotes;
        uint256 approvalPercentage = (totalVotes == 0) ? 0 : (fundingProposals[_proposalId].approvalVotes * 100) / totalVotes;

        if (approvalPercentage >= curationThreshold) { // Reusing curationThreshold for funding proposals too, can be separate if needed
            fundingProposals[_proposalId].status = ProposalStatus.Approved;
            // Execute funding transfer
            payable(fundingProposals[_proposalId].proposer).transfer(fundingProposals[_proposalId].amount); // Transfer to proposer for simplicity, adjust recipient as needed.
            fundingProposals[_proposalId].status = ProposalStatus.Executed;
        } else {
            fundingProposals[_proposalId].status = ProposalStatus.Rejected;
        }
        emit FundingProposalFinalized(_proposalId, fundingProposals[_proposalId].status);
    }

    function getFundingProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (FundingProposal memory) {
        return fundingProposals[_proposalId];
    }

    // --- Governance and Community Functions ---
    function joinCollective() external nonReentrant {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberCount++;
        emit MemberJoined(msg.sender);
    }

    function leaveCollective() external onlyMember nonReentrant {
        delete members[msg.sender];
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    function isMember(address _account) external view returns (bool) {
        return members[_account];
    }

    function setCurationThreshold(uint256 _threshold) external onlyAdmin {
        require(_threshold <= 100, "Curation threshold cannot exceed 100.");
        curationThreshold = _threshold;
    }

    function getCurationThreshold() external view returns (uint256) {
        return curationThreshold;
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDurationInBlocks = _durationInBlocks;
    }

    function getVotingDuration() external view returns (uint256) {
        return votingDurationInBlocks;
    }

    function transferAdminRole(address _newAdmin) external onlyAdmin {
        _transferOwnership(_newAdmin);
        emit AdminRoleTransferred(msg.sender, _newAdmin);
    }

    function emergencyWithdraw(address _recipient) external onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(_recipient).transfer(balance);
        emit EmergencyWithdrawal(_recipient, balance);
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Allow direct deposits to the contract
    }

    fallback() external {}
}
```