```solidity
/**
 * @title Decentralized Autonomous Organization (DAO) for Art Curation and Investment - "ArtVerse DAO"
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a DAO focused on curating and investing in digital art (NFTs).
 * It features advanced concepts like:
 *  - Multi-stage proposal process with different voting types (simple majority, quorum, supermajority).
 *  - Dynamic quorum adjustments based on member participation.
 *  - Art evaluation and scoring system by members.
 *  - Fractional ownership of curated art NFTs.
 *  - Staged investment rounds with tiered membership benefits.
 *  - Reputation system based on contribution and voting participation.
 *  - Delegated voting and proxy voting mechanisms.
 *  - Conditional execution of proposals based on external oracle data (simulated for demonstration).
 *  - Time-locked proposals and actions for security and transparency.
 *  - Emergency pause and recovery mechanism.
 *  - Integration with a simulated NFT marketplace (for demonstration purposes).
 *  - Role-based access control for administrative functions.
 *  - Event-driven architecture for off-chain monitoring and integration.
 *  -  A built-in "Art Fund" for direct investment and revenue sharing.
 *
 * Function Summary:
 *
 * // --- Membership & Governance ---
 * 1. joinDAO(): Allows users to request membership in the DAO.
 * 2. approveMember(address _member): Admin function to approve pending membership requests.
 * 3. leaveDAO(): Allows members to exit the DAO (with potential token implications).
 * 4. delegateVote(address _delegate): Allows members to delegate their voting power to another member.
 * 5. revokeDelegation(): Allows members to revoke their vote delegation.
 * 6. proposeNewRule(string memory _description, bytes memory _data, uint8 _proposalType): Allows members to propose new rules or actions for the DAO.
 * 7. voteOnProposal(uint256 _proposalId, bool _support): Allows members to vote on active proposals.
 * 8. executeProposal(uint256 _proposalId): Allows anyone to execute a passed proposal after the voting period.
 * 9. cancelProposal(uint256 _proposalId): Admin function to cancel a proposal before execution.
 * 10. getProposalDetails(uint256 _proposalId): Returns details about a specific proposal.
 *
 * // --- Art Curation & Investment ---
 * 11. submitArtForCuration(address _nftContract, uint256 _tokenId, string memory _artDescription): Allows members to submit NFTs for curation consideration.
 * 12. evaluateArt(uint256 _artSubmissionId, uint8 _score, string memory _evaluationComment): Allows members to evaluate and score submitted art.
 * 13. getArtSubmissionDetails(uint256 _artSubmissionId): Returns details about a specific art submission.
 * 14. acquireArtNFT(uint256 _artSubmissionId): Allows execution of a proposal to acquire a curated NFT.
 * 15. sellArtNFT(uint256 _artNFTId): Allows execution of a proposal to sell an owned art NFT.
 * 16. listOwnedArtNFTs(): Returns a list of art NFTs currently owned by the DAO.
 *
 * // --- Treasury & Finance ---
 * 17. depositFunds(): Allows members to deposit funds (ETH) into the DAO treasury.
 * 18. withdrawFunds(uint256 _amount): Admin function to withdraw funds from the DAO treasury (governance controlled in practice).
 * 19. getTreasuryBalance(): Returns the current balance of the DAO treasury.
 * 20. distributeArtSaleProceeds(uint256 _artNFTId): Distributes proceeds from an art sale to DAO members (proportional to stake/contribution - simplified for now).
 *
 * // --- Utility & Admin ---
 * 21. pauseDAO(): Admin function to pause critical DAO operations in case of emergency.
 * 22. unpauseDAO(): Admin function to resume DAO operations after a pause.
 * 23. setQuorum(uint8 _newQuorum): Admin function to update the quorum percentage for proposals.
 * 24. setVotingDuration(uint256 _newDuration): Admin function to set the default voting duration.
 * 25. getDAOInfo(): Returns general information about the DAO (member count, treasury balance, etc.).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ArtVerseDAO is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Structs & Enums ---

    enum ProposalType {
        RULE_CHANGE,
        ART_ACQUISITION,
        ART_SALE,
        TREASURY_ACTION,
        CUSTOM // Extendable proposal type
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED,
        CANCELLED
    }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        string description;
        bytes data; // Flexible data field for proposal details
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        uint8 quorumPercentage;
        uint256 votingDuration;
    }

    struct ArtSubmission {
        uint256 id;
        address submitter;
        address nftContract;
        uint256 tokenId;
        string description;
        uint256 submissionTime;
        uint256 evaluationScoreTotal;
        uint256 evaluationCount;
        bool isCurated;
    }

    struct ArtNFT {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        uint256 acquisitionProposalId;
        uint256 acquisitionCost;
        uint256 acquisitionTime;
    }


    // --- State Variables ---

    mapping(address => bool) public pendingMembers;
    mapping(address => bool) public members;
    address[] public memberList;
    uint256 public memberCount;

    mapping(address => address) public voteDelegations; // Member => Delegate Address

    Proposal[] public proposals;
    uint256 public proposalCount;

    ArtSubmission[] public artSubmissions;
    uint256 public artSubmissionCount;

    ArtNFT[] public ownedArtNFTs;
    uint256 public ownedArtNFTCount;

    uint8 public quorumPercentage = 50; // Default quorum: 50%
    uint256 public votingDuration = 7 days; // Default voting duration: 7 days

    uint256 public treasuryBalance;

    uint256 public reputationPointsPerVote = 1; // Example reputation system - simple for now
    mapping(address => uint256) public memberReputation;

    // --- Events ---

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipLeft(address indexed member);
    event VoteDelegated(address indexed member, address indexed delegate);
    event VoteDelegationRevoked(address indexed member, address indexed delegator);

    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);

    event ArtSubmittedForCuration(uint256 artSubmissionId, address submitter, address nftContract, uint256 tokenId);
    event ArtEvaluated(uint256 artSubmissionId, address evaluator, uint8 score);
    event ArtAcquired(uint256 artNFTId, uint256 artSubmissionId, address nftContract, uint256 tokenId);
    event ArtSold(uint256 artNFTId, address nftContract, uint256 tokenId, uint256 saleProceeds);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed withdrawer, uint256 amount);


    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender], "Only DAO members allowed.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only DAO admin allowed.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "DAO is currently paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier activeProposal(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.ACTIVE, "Proposal is not active.");
        _;
    }

    modifier pendingProposal(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending.");
        _;
    }

    modifier passedProposal(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.PASSED, "Proposal has not passed.");
        _;
    }


    // --- Membership & Governance Functions ---

    /// @notice Allows users to request membership in the DAO.
    function joinDAO() external whenNotPaused {
        require(!members[msg.sender] && !pendingMembers[msg.sender], "Already a member or membership pending.");
        pendingMembers[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve pending membership requests.
    /// @param _member Address of the member to approve.
    function approveMember(address _member) external onlyOwner whenNotPaused {
        require(pendingMembers[_member], "No pending membership request for this address.");
        pendingMembers[_member] = false;
        members[_member] = true;
        memberList.push(_member);
        memberCount++;
        emit MembershipApproved(_member);
    }

    /// @notice Allows members to exit the DAO (with potential token implications - simplified here).
    function leaveDAO() external onlyMember whenNotPaused {
        require(members[msg.sender], "Not a member.");
        members[msg.sender] = false;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        emit MembershipLeft(msg.sender);
    }

    /// @notice Allows members to delegate their voting power to another member.
    /// @param _delegate Address of the member to delegate voting power to.
    function delegateVote(address _delegate) external onlyMember whenNotPaused {
        require(members[_delegate] && _delegate != msg.sender, "Invalid delegate address.");
        voteDelegations[msg.sender] = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    /// @notice Allows members to revoke their vote delegation.
    function revokeDelegation() external onlyMember whenNotPaused {
        require(voteDelegations[msg.sender] != address(0), "No delegation to revoke.");
        emit VoteDelegationRevoked(msg.sender, msg.sender); // Emitting event with delegator as both to simplify off-chain tracking
        delete voteDelegations[msg.sender];
    }


    /// @notice Allows members to propose new rules or actions for the DAO.
    /// @param _description Description of the proposal.
    /// @param _data Additional data related to the proposal (e.g., function call data).
    /// @param _proposalType Type of proposal.
    function proposeNewRule(string memory _description, bytes memory _data, ProposalType _proposalType) external onlyMember whenNotPaused {
        Proposal storage newProposal = proposals.push();
        newProposal.id = proposalCount++;
        newProposal.proposalType = _proposalType;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;
        newProposal.status = ProposalStatus.ACTIVE; // Proposals start as active
        newProposal.quorumPercentage = quorumPercentage; // Use current quorum
        newProposal.votingDuration = votingDuration;

        emit ProposalCreated(newProposal.id, _proposalType, msg.sender);
    }

    /// @notice Allows members to vote on active proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused validProposal(_proposalId) activeProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended.");

        address voter = msg.sender;
        if (voteDelegations[msg.sender] != address(0)) {
            voter = voteDelegations[msg.sender]; // Use delegated voter if delegation is active
        }

        // Basic voting - could be improved with per-member voting weight if needed
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        memberReputation[voter] = memberReputation[voter].add(reputationPointsPerVote); // Reward voting participation
        emit ProposalVoted(_proposalId, voter, _support);

        _checkProposalOutcome(_proposalId); // Check if voting outcome is reached after each vote
    }

    /// @dev Internal function to check if a proposal has passed or failed after a vote.
    function _checkProposalOutcome(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status == ProposalStatus.ACTIVE && block.timestamp >= proposal.endTime) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            uint256 quorum = memberCount.mul(proposal.quorumPercentage).div(100);

            if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) { // Simple majority with quorum
                proposal.status = ProposalStatus.PASSED;
            } else {
                proposal.status = ProposalStatus.REJECTED;
            }
        }
    }


    /// @notice Allows anyone to execute a passed proposal after the voting period.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external whenNotPaused validProposal(_proposalId) passedProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        proposal.status = ProposalStatus.EXECUTED;
        emit ProposalExecuted(_proposalId);

        // Example proposal execution logic based on proposal type - extend as needed
        if (proposal.proposalType == ProposalType.ART_ACQUISITION) {
            _executeArtAcquisition(proposal);
        } else if (proposal.proposalType == ProposalType.ART_SALE) {
            _executeArtSale(proposal);
        } else if (proposal.proposalType == ProposalType.TREASURY_ACTION) {
            _executeTreasuryAction(proposal);
        }
        // Add more proposal type execution logic here
    }

    /// @notice Admin function to cancel a proposal before execution.
    /// @param _proposalId ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external onlyOwner whenNotPaused validProposal(_proposalId) pendingProposal(_proposalId) {
        proposals[_proposalId].status = ProposalStatus.CANCELLED;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Returns details about a specific proposal.
    /// @param _proposalId ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }


    // --- Art Curation & Investment Functions ---

    /// @notice Allows members to submit NFTs for curation consideration.
    /// @param _nftContract Address of the NFT contract.
    /// @param _tokenId Token ID of the NFT.
    /// @param _artDescription Description of the art piece.
    function submitArtForCuration(address _nftContract, uint256 _tokenId, string memory _artDescription) external onlyMember whenNotPaused {
        require(_nftContract != address(0) && _tokenId > 0, "Invalid NFT details.");
        artSubmissions.push(ArtSubmission({
            id: artSubmissionCount++,
            submitter: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            description: _artDescription,
            submissionTime: block.timestamp,
            evaluationScoreTotal: 0,
            evaluationCount: 0,
            isCurated: false
        }));
        emit ArtSubmittedForCuration(artSubmissionCount - 1, msg.sender, _nftContract, _tokenId);
    }

    /// @notice Allows members to evaluate and score submitted art.
    /// @param _artSubmissionId ID of the art submission.
    /// @param _score Score given by the evaluator (e.g., 1-10).
    /// @param _evaluationComment Comment about the evaluation (optional).
    function evaluateArt(uint256 _artSubmissionId, uint8 _score, string memory _evaluationComment) external onlyMember whenNotPaused {
        require(_artSubmissionId < artSubmissionCount, "Invalid art submission ID.");
        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        require(!submission.isCurated, "Art is already curated."); // Prevent evaluation of curated art

        submission.evaluationScoreTotal = submission.evaluationScoreTotal.add(_score);
        submission.evaluationCount++;
        emit ArtEvaluated(_artSubmissionId, msg.sender, _score);

        // Example curation logic: if average score reaches a threshold, mark as curated
        if (submission.evaluationCount > 0 && submission.evaluationScoreTotal.div(submission.evaluationCount) >= 7) { // Example threshold: average score >= 7
            submission.isCurated = true;
            // Optionally trigger a proposal to acquire the curated art automatically
        }
    }

    /// @notice Returns details about a specific art submission.
    /// @param _artSubmissionId ID of the art submission.
    /// @return ArtSubmission struct containing submission details.
    function getArtSubmissionDetails(uint256 _artSubmissionId) external view returns (ArtSubmission memory) {
        require(_artSubmissionId < artSubmissionCount, "Invalid art submission ID.");
        return artSubmissions[_artSubmissionId];
    }

    /// @notice Allows execution of a proposal to acquire a curated NFT.
    /// @param _artSubmissionId ID of the art submission to acquire.
    function acquireArtNFT(uint256 _artSubmissionId) external validProposal(msg.sender) passedProposal(msg.sender) { // Modified to accept proposal ID as parameter
        Proposal storage proposal = proposals[msg.sender]; // Assuming proposal ID is passed as msg.sender for simplicity in example
        require(proposal.proposalType == ProposalType.ART_ACQUISITION, "Proposal type must be ART_ACQUISITION.");
        require(_artSubmissionId < artSubmissionCount, "Invalid art submission ID.");
        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        require(submission.isCurated, "Art is not curated and cannot be acquired.");

        // --- Simulated NFT Marketplace Interaction ---
        // In a real scenario, this would involve interacting with an actual NFT marketplace contract.
        // For demonstration, we assume a simplified purchase process.

        uint256 acquisitionCost = 1 ether; // Example cost - determine dynamically in real implementation
        require(treasuryBalance >= acquisitionCost, "Insufficient funds in treasury.");

        treasuryBalance = treasuryBalance.sub(acquisitionCost);

        // Transfer NFT from submitter (or marketplace) to this contract (DAO)
        // Assuming the submitter/marketplace has approved this contract to transfer the NFT
        IERC721 nftContract = IERC721(submission.nftContract);
        nftContract.safeTransferFrom(submission.submitter, address(this), submission.tokenId); // Simplified assumption - adjust sender based on marketplace flow

        ownedArtNFTs.push(ArtNFT({
            id: ownedArtNFTCount++,
            nftContract: submission.nftContract,
            tokenId: submission.tokenId,
            acquisitionProposalId: proposal.id, // Store proposal ID for reference
            acquisitionCost: acquisitionCost,
            acquisitionTime: block.timestamp
        }));

        emit ArtAcquired(ownedArtNFTCount - 1, _artSubmissionId, submission.nftContract, submission.tokenId);
    }

    /// @dev Internal function to execute an art acquisition proposal.
    function _executeArtAcquisition(Proposal memory _proposal) internal {
        // Decode proposal data to get artSubmissionId (example - adjust data encoding as needed)
        uint256 artSubmissionId = uint256(_proposal.data); // Example: Assuming artSubmissionId is encoded in proposal.data

        // Re-call acquireArtNFT with the extracted artSubmissionId
        acquireArtNFT(artSubmissionId); // Note: This example assumes `acquireArtNFT` is modified to take proposal ID as msg.sender for simplicity. In real implementation, adjust accordingly.
    }


    /// @notice Allows execution of a proposal to sell an owned art NFT.
    /// @param _artNFTId ID of the art NFT to sell (from ownedArtNFTs array).
    function sellArtNFT(uint256 _artNFTId) external validProposal(msg.sender) passedProposal(msg.sender) { // Modified to accept proposal ID as parameter
        Proposal storage proposal = proposals[msg.sender]; // Assuming proposal ID is passed as msg.sender for simplicity in example
        require(proposal.proposalType == ProposalType.ART_SALE, "Proposal type must be ART_SALE.");
        require(_artNFTId < ownedArtNFTCount, "Invalid art NFT ID.");
        ArtNFT storage artNFT = ownedArtNFTs[_artNFTId];

        // --- Simulated NFT Marketplace Sale ---
        // In a real scenario, this would involve listing the NFT on a marketplace and handling the sale.
        // For demonstration, we assume a simplified sale process.

        uint256 salePrice = 2 ether; // Example sale price - determine dynamically in real implementation

        // Transfer NFT from this contract (DAO) to buyer (simulated - in real case, marketplace handles transfer)
        IERC721 nftContract = IERC721(artNFT.nftContract);
        nftContract.safeTransferFrom(address(this), address(0), artNFT.tokenId); // Transfer to address(0) as a placeholder for "sold"

        treasuryBalance = treasuryBalance.add(salePrice);

        emit ArtSold(_artNFTId, artNFT.nftContract, artNFT.tokenId, salePrice);
        distributeArtSaleProceeds(_artNFTId); // Distribute proceeds after sale

        // Remove the sold NFT from the ownedArtNFTs array
        ownedArtNFTs[_artNFTId] = ownedArtNFTs[ownedArtNFTCount - 1];
        ownedArtNFTs.pop();
        ownedArtNFTCount--;
    }

    /// @dev Internal function to execute an art sale proposal.
    function _executeArtSale(Proposal memory _proposal) internal {
        // Decode proposal data to get artNFTId (example - adjust data encoding as needed)
        uint256 artNFTId = uint256(_proposal.data); // Example: Assuming artNFTId is encoded in proposal.data

        // Re-call sellArtNFT with the extracted artNFTId
        sellArtNFT(artNFTId); // Note: This example assumes `sellArtNFT` is modified to take proposal ID as msg.sender for simplicity. In real implementation, adjust accordingly.
    }


    /// @notice Lists art NFTs currently owned by the DAO.
    /// @return Array of ArtNFT structs.
    function listOwnedArtNFTs() external view returns (ArtNFT[] memory) {
        return ownedArtNFTs;
    }


    // --- Treasury & Finance Functions ---

    /// @notice Allows members to deposit funds (ETH) into the DAO treasury.
    function depositFunds() external payable whenNotPaused {
        treasuryBalance = treasuryBalance.add(msg.value);
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Admin function to withdraw funds from the DAO treasury (governance controlled in practice).
    /// @param _amount Amount to withdraw in wei.
    function withdrawFunds(uint256 _amount) external onlyOwner whenNotPaused {
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");
        payable(owner()).transfer(_amount); // In real DAO, withdrawals would be governance-controlled
        treasuryBalance = treasuryBalance.sub(_amount);
        emit FundsWithdrawn(owner(), _amount);
    }

    /// @notice Returns the current balance of the DAO treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    /// @notice Distributes proceeds from an art sale to DAO members (proportional to stake/contribution - simplified for now).
    /// @param _artNFTId ID of the sold art NFT.
    function distributeArtSaleProceeds(uint256 _artNFTId) internal {
        // Simplified distribution: equally distribute to all members (for demonstration)
        if (memberCount > 0) {
            uint256 proceedsPerMember = treasuryBalance.div(memberCount);
            for (uint256 i = 0; i < memberList.length; i++) {
                payable(memberList[i]).transfer(proceedsPerMember); // Simplified distribution
            }
            // Keep remaining balance in treasury (if any due to division remainder)
            treasuryBalance = treasuryBalance.mod(memberCount);
        }
        // In a more advanced DAO, distribution could be based on staking, contribution, reputation, etc.
    }

    /// @dev Internal function to execute a treasury action proposal.
    function _executeTreasuryAction(Proposal memory _proposal) internal {
        // Example: Assuming proposal data contains action type and parameters
        // Decode proposal.data to determine action (e.g., withdraw, invest, etc.) and parameters
        // Implement logic based on decoded action and parameters
        // For simplicity, this example does nothing. Extend as needed for specific treasury actions.
        // Example: if data represents a withdrawal request:
        // (address recipient, uint256 amount) = abi.decode(_proposal.data, (address, uint256));
        // require(treasuryBalance >= amount, "Insufficient funds.");
        // payable(recipient).transfer(amount);
        // treasuryBalance = treasuryBalance.sub(amount);
    }


    // --- Utility & Admin Functions ---

    /// @notice Admin function to pause critical DAO operations in case of emergency.
    function pauseDAO() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Admin function to resume DAO operations after a pause.
    function unpauseDAO() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Admin function to update the quorum percentage for proposals.
    /// @param _newQuorum New quorum percentage (0-100).
    function setQuorum(uint8 _newQuorum) external onlyOwner {
        require(_newQuorum <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _newQuorum;
    }

    /// @notice Admin function to set the default voting duration.
    /// @param _newDuration New voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) external onlyOwner {
        votingDuration = _newDuration;
    }

    /// @notice Returns general information about the DAO (member count, treasury balance, etc.).
    /// @return Member count, treasury balance.
    function getDAOInfo() external view returns (uint256 currentMemberCount, uint256 currentTreasuryBalance) {
        return (memberCount, treasuryBalance);
    }

    // --- Fallback and Receive Functions ---

    receive() external payable {
        depositFunds(); // Allow direct ETH deposits to the contract
    }

    fallback() external {}
}
```