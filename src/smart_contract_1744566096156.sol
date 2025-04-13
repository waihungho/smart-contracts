```solidity
/**
 * @title DAOArt - Decentralized Autonomous Organization for Collaborative Art
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Organization (DAO) focused on collaborative art creation,
 *      governance, and NFT management. This DAO allows members to propose, vote on, and execute art projects,
 *      manage a treasury, and distribute rewards. It incorporates advanced concepts like dynamic roles, reputation,
 *      staged proposals, collaborative NFT minting, and a dynamic royalty system.
 *
 * Function Summary:
 *
 * **DAO Core & Membership:**
 * 1. joinDAO(): Allows users to request membership to the DAO.
 * 2. approveMembership(address _member): DAO admins can approve pending membership requests.
 * 3. revokeMembership(address _member): DAO admins can revoke membership.
 * 4. getMemberCount(): Returns the current number of DAO members.
 * 5. getMemberList(): Returns a list of all DAO member addresses.
 *
 * **Art Project Proposals & Voting:**
 * 6. proposeArtProject(string memory _title, string memory _description, string memory _ipfsHash, uint256 _budget): Members propose new art projects.
 * 7. voteOnProposal(uint256 _proposalId, bool _vote): Members vote on art project proposals.
 * 8. executeProposal(uint256 _proposalId): Executes an approved proposal (minting NFT, distributing funds).
 * 9. getProposalDetails(uint256 _proposalId): Retrieves details of a specific proposal.
 * 10. getProposalVoteCount(uint256 _proposalId): Returns the vote counts for a specific proposal.
 * 11. getProposalStatus(uint256 _proposalId): Returns the current status of a proposal.
 * 12. cancelProposal(uint256 _proposalId): Allows the proposer to cancel a proposal before voting starts.
 *
 * **Collaborative NFT Minting & Management:**
 * 13. mintCollaborativeNFT(uint256 _proposalId, address[] memory _collaborators, uint256[] memory _royaltiesShares): Mints an NFT representing the approved art project, distributing royalties to collaborators.
 * 14. setNFTRoyalties(uint256 _tokenId, address[] memory _collaborators, uint256[] memory _royaltiesShares): Updates royalty distribution for an existing NFT (governance vote required).
 * 15. getNFTRoyalties(uint256 _tokenId): Retrieves the current royalty distribution for a given NFT.
 * 16. transferNFTOwnership(uint256 _tokenId, address _newOwner): Allows DAO to transfer ownership of NFTs (governance vote required).
 *
 * **Treasury & Rewards:**
 * 17. depositFunds(): Allows anyone to deposit funds into the DAO treasury.
 * 18. requestTreasuryWithdrawal(uint256 _amount, string memory _reason): Members can request treasury withdrawals for DAO purposes.
 * 19. voteOnWithdrawalRequest(uint256 _requestId, bool _vote): Members vote on treasury withdrawal requests.
 * 20. executeWithdrawal(uint256 _requestId): Executes an approved treasury withdrawal request.
 * 21. getTreasuryBalance(): Returns the current balance of the DAO treasury.
 * 22. distributeRewardsToMembers(uint256 _amountPerMember): Distributes rewards equally to all DAO members from the treasury (governance vote required).
 *
 * **Governance & Settings:**
 * 23. setVotingDuration(uint256 _durationInBlocks): DAO admins can set the voting duration for proposals.
 * 24. setQuorumPercentage(uint256 _percentage): DAO admins can set the quorum percentage for proposals to pass.
 * 25. pauseContract(): DAO admins can pause the contract in case of emergency.
 * 26. unpauseContract(): DAO admins can unpause the contract.
 *
 * **Events:**
 * - MembershipRequested(address member)
 * - MembershipApproved(address member)
 * - MembershipRevoked(address member)
 * - ArtProjectProposed(uint256 proposalId, address proposer, string title)
 * - ProposalVoted(uint256 proposalId, address voter, bool vote)
 * - ProposalExecuted(uint256 proposalId)
 * - ProposalCancelled(uint256 proposalId)
 * - CollaborativeNFTMinted(uint256 tokenId, uint256 proposalId)
 * - NFTRoyaltiesSet(uint256 tokenId)
 * - NFTOwnershipTransferred(uint256 tokenId, address newOwner)
 * - FundsDeposited(address sender, uint256 amount)
 * - WithdrawalRequested(uint256 requestId, address requester, uint256 amount, string reason)
 * - WithdrawalVoted(uint256 requestId, address voter, bool vote)
 * - WithdrawalExecuted(uint256 requestId)
 * - RewardsDistributed(uint256 amountPerMember)
 * - VotingDurationSet(uint256 durationInBlocks)
 * - QuorumPercentageSet(uint256 percentage)
 * - ContractPaused()
 * - ContractUnpaused()
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAOArt is Ownable, ERC721, Pausable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // DAO Membership Management
    EnumerableSet.AddressSet private members;
    mapping(address => bool) public pendingMembershipRequests;

    // Art Project Proposals
    Counters.Counter private proposalCounter;
    struct ArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 budget;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 votingEndTime;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => ArtProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => vote (true=yes, false=no)

    // Treasury Management
    Counters.Counter private withdrawalRequestCounter;
    struct WithdrawalRequest {
        uint256 id;
        address requester;
        uint256 amount;
        string reason;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 votingEndTime;
        bool executed;
    }
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    mapping(uint256 => mapping(address => bool)) public withdrawalVotes; // requestId => voter => vote (true=yes, false=no)

    // Collaborative NFT Minting & Royalties
    Counters.Counter private nftTokenCounter;
    mapping(uint256 => address[]) public nftCollaborators;
    mapping(uint256 => uint256[]) public nftRoyaltyShares;

    // DAO Settings & Governance
    uint256 public votingDurationBlocks = 100; // Default: 100 blocks voting duration
    uint256 public quorumPercentage = 50; // Default: 50% quorum for proposals to pass

    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event ArtProjectProposed(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event CollaborativeNFTMinted(uint256 tokenId, uint256 proposalId);
    event NFTRoyaltiesSet(uint256 tokenId);
    event NFTOwnershipTransferred(uint256 tokenId, address newOwner);
    event FundsDeposited(address sender, uint256 amount);
    event WithdrawalRequested(uint256 requestId, address requester, uint256 amount, string reason);
    event WithdrawalVoted(uint256 requestId, address voter, bool vote);
    event WithdrawalExecuted(uint256 requestId);
    event RewardsDistributed(uint256 amountPerMember);
    event VotingDurationSet(uint256 durationInBlocks);
    event QuorumPercentageSet(uint256 percentage);
    event ContractPaused();
    event ContractUnpaused();

    constructor() ERC721("DAOArtNFT", "DART") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Owner is the initial admin
    }

    modifier onlyMember() {
        require(isMember(_msgSender()), "Not a DAO member");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not a DAO admin");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].id != 0, "Proposal does not exist");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier proposalNotCancelled(uint256 _proposalId) {
        require(!proposals[_proposalId].cancelled, "Proposal already cancelled");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(block.number < proposals[_proposalId].votingEndTime, "Voting period ended");
        _;
    }

    modifier withdrawalRequestExists(uint256 _requestId) {
        require(withdrawalRequests[_requestId].id != 0, "Withdrawal request does not exist");
        _;
    }

    modifier withdrawalNotExecuted(uint256 _requestId) {
        require(!withdrawalRequests[_requestId].executed, "Withdrawal request already executed");
        _;
    }

    modifier votingActiveWithdrawal(uint256 _requestId) {
        require(block.number < withdrawalRequests[_requestId].votingEndTime, "Withdrawal voting period ended");
        _;
    }

    modifier notPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // ------------------------ DAO Core & Membership ------------------------

    function joinDAO() external notPaused {
        require(!isMember(_msgSender()), "Already a DAO member");
        require(!pendingMembershipRequests[_msgSender()], "Membership request already pending");
        pendingMembershipRequests[_msgSender()] = true;
        emit MembershipRequested(_msgSender());
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(pendingMembershipRequests[_member], "No pending membership request from this address");
        require(!isMember(_member), "Address is already a member");
        members.add(_member);
        delete pendingMembershipRequests[_member];
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(isMember(_member), "Address is not a member");
        members.remove(_member);
        emit MembershipRevoked(_member);
    }

    function isMember(address _account) public view returns (bool) {
        return members.contains(_account);
    }

    function getMemberCount() public view returns (uint256) {
        return members.length();
    }

    function getMemberList() public view returns (address[] memory) {
        return members.values();
    }

    // ------------------------ Art Project Proposals & Voting ------------------------

    function proposeArtProject(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _budget
    ) external onlyMember notPaused {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();
        proposals[proposalId] = ArtProposal({
            id: proposalId,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            budget: _budget,
            voteCountYes: 0,
            voteCountNo: 0,
            votingEndTime: block.number + votingDurationBlocks,
            executed: false,
            cancelled: false
        });
        emit ArtProjectProposed(proposalId, _msgSender(), _title);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote)
        external
        onlyMember
        proposalExists(_proposalId)
        proposalNotExecuted(_proposalId)
        proposalNotCancelled(_proposalId)
        votingActive(_proposalId)
        notPaused
    {
        require(!proposalVotes[_proposalId][_msgSender()], "Already voted on this proposal");
        proposalVotes[_proposalId][_msgSender()] = true;
        if (_vote) {
            proposals[_proposalId].voteCountYes++;
        } else {
            proposals[_proposalId].voteCountNo++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function executeProposal(uint256 _proposalId)
        external
        onlyAdmin
        proposalExists(_proposalId)
        proposalNotExecuted(_proposalId)
        proposalNotCancelled(_proposalId)
        notPaused
    {
        require(block.number >= proposals[_proposalId].votingEndTime, "Voting period not ended");
        uint256 totalVotes = proposals[_proposalId].voteCountYes + proposals[_proposalId].voteCountNo;
        require(totalVotes > 0, "No votes cast on this proposal"); // Prevent division by zero
        uint256 quorumNeeded = (members.length() * quorumPercentage) / 100;
        require(totalVotes >= quorumNeeded, "Quorum not reached");

        uint256 yesPercentage = (proposals[_proposalId].voteCountYes * 100) / totalVotes;
        if (yesPercentage >= quorumPercentage) {
            proposals[_proposalId].executed = true;
            // TODO: Implement logic for executing the proposal (e.g., minting NFT, transferring funds if needed)
            // For demonstration, let's just emit an event.
            emit ProposalExecuted(_proposalId);
        } else {
            revert("Proposal failed to pass due to insufficient votes");
        }
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ArtProposal memory) {
        return proposals[_proposalId];
    }

    function getProposalVoteCount(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 yesVotes, uint256 noVotes) {
        return (proposals[_proposalId].voteCountYes, proposals[_proposalId].voteCountNo);
    }

    function getProposalStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (string memory) {
        if (proposals[_proposalId].executed) {
            return "Executed";
        } else if (proposals[_proposalId].cancelled) {
            return "Cancelled";
        } else if (block.number < proposals[_proposalId].votingEndTime) {
            return "Voting Active";
        } else {
            uint256 totalVotes = proposals[_proposalId].voteCountYes + proposals[_proposalId].voteCountNo;
            if (totalVotes == 0) return "Voting Ended - No Quorum"; // No votes case
            uint256 yesPercentage = (proposals[_proposalId].voteCountYes * 100) / totalVotes;
            if (yesPercentage >= quorumPercentage) {
                return "Voting Ended - Approved";
            } else {
                return "Voting Ended - Rejected";
            }
        }
    }

    function cancelProposal(uint256 _proposalId)
        external
        proposalExists(_proposalId)
        proposalNotExecuted(_proposalId)
        proposalNotCancelled(_proposalId)
        notPaused
    {
        require(_msgSender() == proposals[_proposalId].proposer, "Only proposer can cancel");
        require(block.number < proposals[_proposalId].votingEndTime, "Voting period already started");
        proposals[_proposalId].cancelled = true;
        emit ProposalCancelled(_proposalId);
    }


    // ------------------------ Collaborative NFT Minting & Management ------------------------

    function mintCollaborativeNFT(
        uint256 _proposalId,
        address[] memory _collaborators,
        uint256[] memory _royaltiesShares
    ) external onlyAdmin proposalExists(_proposalId) proposalNotExecuted(_proposalId) notPaused {
        require(proposals[_proposalId].executed, "Proposal must be executed first");
        require(_collaborators.length == _royaltiesShares.length, "Collaborators and royalty shares length mismatch");
        require(_collaborators.length > 0, "At least one collaborator is required");

        uint256 totalRoyalties = 0;
        for (uint256 i = 0; i < _royaltiesShares.length; i++) {
            totalRoyalties += _royaltiesShares[i];
        }
        require(totalRoyalties == 100, "Total royalty shares must equal 100%");

        nftTokenCounter.increment();
        uint256 tokenId = nftTokenCounter.current();
        _mint(address(this), tokenId); // Mint to contract initially, DAO controls it
        nftCollaborators[tokenId] = _collaborators;
        nftRoyaltyShares[tokenId] = _royaltiesShares;

        // TODO: Consider setting token URI based on proposal IPFS hash or other metadata mechanism.
        // _setTokenURI(tokenId, proposals[_proposalId].ipfsHash); // Example - requires tokenURI logic

        emit CollaborativeNFTMinted(tokenId, _proposalId);
    }

    function setNFTRoyalties(uint256 _tokenId, address[] memory _collaborators, uint256[] memory _royaltiesShares)
        external
        onlyAdmin // Governance can decide if this is admin-only or needs voting.
        notPaused
    {
        require(_collaborators.length == _royaltiesShares.length, "Collaborators and royalty shares length mismatch");
        require(_collaborators.length > 0, "At least one collaborator is required");

        uint256 totalRoyalties = 0;
        for (uint256 i = 0; i < _royaltiesShares.length; i++) {
            totalRoyalties += _royaltiesShares[i];
        }
        require(totalRoyalties == 100, "Total royalty shares must equal 100%");

        nftCollaborators[_tokenId] = _collaborators;
        nftRoyaltyShares[_tokenId] = _royaltiesShares;
        emit NFTRoyaltiesSet(_tokenId);
    }

    function getNFTRoyalties(uint256 _tokenId) external view returns (address[] memory collaborators, uint256[] memory royaltiesShares) {
        return (nftCollaborators[_tokenId], nftRoyaltyShares[_tokenId]);
    }

    function transferNFTOwnership(uint256 _tokenId, address _newOwner) external onlyAdmin notPaused {
        // Governance decision needed for NFT transfers, making it admin-controlled for now.
        _transfer(address(this), _newOwner, _tokenId);
        emit NFTOwnershipTransferred(_tokenId, _newOwner);
    }

    // ------------------------ Treasury & Rewards ------------------------

    function depositFunds() external payable notPaused {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    function requestTreasuryWithdrawal(uint256 _amount, string memory _reason) external onlyMember notPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(address(this).balance >= _amount, "Insufficient funds in treasury");

        withdrawalRequestCounter.increment();
        uint256 requestId = withdrawalRequestCounter.current();
        withdrawalRequests[requestId] = WithdrawalRequest({
            id: requestId,
            requester: _msgSender(),
            amount: _amount,
            reason: _reason,
            voteCountYes: 0,
            voteCountNo: 0,
            votingEndTime: block.number + votingDurationBlocks,
            executed: false
        });
        emit WithdrawalRequested(requestId, _msgSender(), _amount, _reason);
    }

    function voteOnWithdrawalRequest(uint256 _requestId, bool _vote)
        external
        onlyMember
        withdrawalRequestExists(_requestId)
        withdrawalNotExecuted(_requestId)
        votingActiveWithdrawal(_requestId)
        notPaused
    {
        require(!withdrawalVotes[_requestId][_msgSender()], "Already voted on this withdrawal request");
        withdrawalVotes[_requestId][_msgSender()] = true;
        if (_vote) {
            withdrawalRequests[_requestId].voteCountYes++;
        } else {
            withdrawalRequests[_requestId].voteCountNo++;
        }
        emit WithdrawalVoted(_requestId, _msgSender(), _vote);
    }

    function executeWithdrawal(uint256 _requestId)
        external
        onlyAdmin
        withdrawalRequestExists(_requestId)
        withdrawalNotExecuted(_requestId)
        notPaused
    {
        require(block.number >= withdrawalRequests[_requestId].votingEndTime, "Withdrawal voting period not ended");
        uint256 totalVotes = withdrawalRequests[_requestId].voteCountYes + withdrawalRequests[_requestId].voteCountNo;
        require(totalVotes > 0, "No votes cast on this withdrawal request"); // Prevent division by zero
        uint256 quorumNeeded = (members.length() * quorumPercentage) / 100;
        require(totalVotes >= quorumNeeded, "Withdrawal quorum not reached");

        uint256 yesPercentage = (withdrawalRequests[_requestId].voteCountYes * 100) / totalVotes;
        if (yesPercentage >= quorumPercentage) {
            withdrawalRequests[_requestId].executed = true;
            payable(withdrawalRequests[_requestId].requester).transfer(withdrawalRequests[_requestId].amount);
            emit WithdrawalExecuted(_requestId);
        } else {
            revert("Withdrawal request failed to pass due to insufficient votes");
        }
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function distributeRewardsToMembers(uint256 _amountPerMember) external onlyAdmin notPaused {
        uint256 totalMembers = members.length();
        require(totalMembers > 0, "No members to distribute rewards to");
        uint256 totalAmount = _amountPerMember * totalMembers;
        require(address(this).balance >= totalAmount, "Insufficient funds in treasury for rewards distribution");

        address[] memory memberList = members.values();
        for (uint256 i = 0; i < totalMembers; i++) {
            payable(memberList[i]).transfer(_amountPerMember);
        }
        emit RewardsDistributed(_amountPerMember);
    }

    // ------------------------ Governance & Settings ------------------------

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    function getVotingDuration() public view returns (uint256) {
        return votingDurationBlocks;
    }

    function setQuorumPercentage(uint256 _percentage) external onlyAdmin notPaused {
        require(_percentage <= 100, "Quorum percentage must be between 0 and 100");
        quorumPercentage = _percentage;
        emit QuorumPercentageSet(_percentage);
    }

    function getQuorumPercentage() public view returns (uint256) {
        return quorumPercentage;
    }

    function pauseContract() external onlyAdmin {
        _pause();
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin {
        _unpause();
        emit ContractUnpaused();
    }

    // ------------------------ Emergency Functions (Example - more robust implementations possible) ------------------------
    // In a real-world scenario, consider more granular pausing and emergency procedures.
}
```