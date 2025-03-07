```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation,
 * curation, fractional ownership, dynamic NFT evolution based on community voting, and more.
 *
 * Function Summary:
 *
 * --- Membership & Governance ---
 * 1. requestMembership(): Allows users to request membership to the DAAC.
 * 2. voteOnMembershipRequest(): Members vote on pending membership requests.
 * 3. getMembershipStatus(): Checks if an address is a member.
 * 4. proposeNewRule(): Members propose new rules or changes to the collective's governance.
 * 5. voteOnRuleProposal(): Members vote on governance proposals.
 * 6. executeRuleProposal(): Executes a rule proposal if it passes the voting.
 *
 * --- Art Submission & Curation ---
 * 7. submitArtPiece(): Members submit their art pieces for curation.
 * 8. voteOnArtPiece(): Members vote on submitted art pieces to be accepted into the collective's collection.
 * 9. acceptArtPiece(): Accepts an art piece into the collective's collection if it passes curation.
 * 10. rejectArtPiece(): Rejects an art piece if it fails curation.
 * 11. getArtPieceStatus(): Checks the status of a submitted art piece.
 * 12. listArtForSale(): Allows the collective to list accepted art pieces for sale.
 * 13. buyArtPiece(): Allows users to purchase art pieces listed by the collective.
 * 14. withdrawArtSaleProceeds(): Allows the collective to withdraw proceeds from art sales.
 *
 * --- Dynamic NFT Evolution & Community Interaction ---
 * 15. proposeNFTEvolution(): Members propose an evolution or modification to a curated NFT.
 * 16. voteOnNFTEvolution(): Members vote on proposed NFT evolutions.
 * 17. evolveNFT(): Executes an NFT evolution if it passes the voting, potentially changing metadata or visual aspects (simulated).
 * 18. createCommunityPoll(): Allows members to create polls for community decisions or feedback (non-binding).
 * 19. voteInPoll(): Members vote in active community polls.
 * 20. getPollResults(): Retrieves the results of a completed community poll.
 * 21. donateToCollective(): Allows anyone to donate ETH to the collective's treasury.
 * 22. withdrawDonations(): (Governance Controlled) Allows members to propose and vote on withdrawing donations for collective purposes.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _artPieceIds;
    Counters.Counter private _membershipRequestIds;
    Counters.Counter private _ruleProposalIds;
    Counters.Counter private _nftEvolutionProposalIds;
    Counters.Counter private _communityPollIds;

    // Structs
    struct MembershipRequest {
        address requester;
        uint256 requestId;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    struct ArtPieceProposal {
        address submitter;
        uint256 proposalId;
        string ipfsHash; // Link to IPFS metadata
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isAccepted;
    }

    struct RuleProposal {
        address proposer;
        uint256 proposalId;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }

    struct NFTEvolutionProposal {
        uint256 artPieceId;
        address proposer;
        uint256 proposalId;
        string description; // Description of the proposed evolution
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }

    struct CommunityPoll {
        address creator;
        uint256 pollId;
        string question;
        string[] options;
        mapping(address => uint256) votes; // address => option index voted
        uint256[] voteCounts;
        bool isActive;
        uint256 endTime;
    }

    // Enums
    enum MembershipStatus { Pending, Member, NotMember }
    enum ArtPieceStatus { Submitted, UnderReview, Accepted, Rejected }
    enum ProposalStatus { Active, Passed, Rejected, Executed }
    enum PollStatus { Active, Completed }

    // State Variables
    mapping(address => MembershipStatus) public membershipStatus;
    mapping(uint256 => MembershipRequest) public membershipRequests;
    mapping(uint256 => ArtPieceProposal) public artPieceProposals;
    mapping(uint256 => RuleProposal) public ruleProposals;
    mapping(uint256 => NFTEvolutionProposal) public nftEvolutionProposals;
    mapping(uint256 => CommunityPoll) public communityPolls;
    mapping(uint256 => address) public artPieceToSubmitter; // Track submitter of each art piece ID

    uint256 public membershipVoteDuration = 7 days;
    uint256 public artCurationVoteDuration = 7 days;
    uint256 public ruleProposalVoteDuration = 14 days;
    uint256 public nftEvolutionVoteDuration = 7 days;
    uint256 public communityPollDuration = 3 days;

    uint256 public artSaleProceeds = 0;
    uint256 public collectiveDonations = 0;
    uint256 public artPieceSalePrice = 0.1 ether; // Default sale price, can be changed by governance

    string private _baseTokenURI;

    event MembershipRequested(address requester, uint256 requestId);
    event MembershipVoteCast(uint256 requestId, address voter, bool vote);
    event MembershipAccepted(address member);
    event MembershipRejected(address requester);

    event ArtPieceSubmitted(address submitter, uint256 proposalId, string ipfsHash);
    event ArtPieceVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtPieceAccepted(uint256 artPieceId, uint256 proposalId);
    event ArtPieceRejected(uint256 proposalId);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price);
    event ArtPiecePurchased(uint256 artPieceId, address buyer, uint256 price);

    event RuleProposalCreated(uint256 proposalId, address proposer, string description);
    event RuleProposalVoteCast(uint256 proposalId, address voter, bool vote);
    event RuleProposalExecuted(uint256 proposalId);

    event NFTEvolutionProposed(uint256 artPieceId, uint256 proposalId, address proposer, string description);
    event NFTEvolutionVoteCast(uint256 proposalId, address voter, bool vote);
    event NFTEvolved(uint256 artPieceId, uint256 proposalId);

    event CommunityPollCreated(uint256 pollId, address creator, string question, string[] options, uint256 endTime);
    event PollVoteCast(uint256 pollId, address voter, uint256 optionIndex);
    event PollCompleted(uint256 pollId);

    event DonationReceived(address donor, uint256 amount);
    event DonationsWithdrawn(uint256 amount, address recipient);


    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) Ownable() {
        _baseTokenURI = baseURI;
    }

    // Override _baseURI function to set base URI for NFTs
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    modifier onlyMembers() {
        require(membershipStatus[msg.sender] == MembershipStatus.Member, "Not a member");
        _;
    }

    modifier onlyPendingMembers() {
        require(membershipStatus[msg.sender] == MembershipStatus.Pending, "Must be a pending member");
        _;
    }

    modifier notMembers() {
        require(membershipStatus[msg.sender] != MembershipStatus.Member, "Already a member");
        _;
    }

    modifier validMembershipRequest(uint256 requestId) {
        require(membershipRequests[requestId].isActive, "Membership request is not active");
        _;
    }

    modifier validArtProposal(uint256 proposalId) {
        require(artPieceProposals[proposalId].isActive, "Art proposal is not active");
        _;
    }

    modifier validRuleProposal(uint256 proposalId) {
        require(ruleProposals[proposalId].isActive, "Rule proposal is not active");
        _;
    }

    modifier validNFTEvolutionProposal(uint256 proposalId) {
        require(nftEvolutionProposals[proposalId].isActive, "NFT Evolution proposal is not active");
        _;
    }

    modifier validCommunityPoll(uint256 pollId) {
        require(communityPolls[pollId].isActive, "Community poll is not active");
        _;
    }

    modifier pollNotExpired(uint256 pollId) {
        require(communityPolls[pollId].endTime > block.timestamp, "Community poll has expired");
        _;
    }


    // --- Membership & Governance Functions ---

    /// @notice Allows users to request membership to the DAAC.
    function requestMembership() external notMembers {
        _membershipRequestIds.increment();
        uint256 requestId = _membershipRequestIds.current();
        membershipRequests[requestId] = MembershipRequest({
            requester: msg.sender,
            requestId: requestId,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        membershipStatus[msg.sender] = MembershipStatus.Pending;
        emit MembershipRequested(msg.sender, requestId);
    }

    /// @notice Members vote on pending membership requests.
    /// @param requestId The ID of the membership request to vote on.
    /// @param vote True for approval, false for rejection.
    function voteOnMembershipRequest(uint256 requestId, bool vote) external onlyMembers validMembershipRequest(requestId) {
        MembershipRequest storage request = membershipRequests[requestId];
        require(request.requester != msg.sender, "Members cannot vote on their own request.");

        if (vote) {
            request.votesFor++;
        } else {
            request.votesAgainst++;
        }
        emit MembershipVoteCast(requestId, msg.sender, vote);

        if (block.timestamp >= block.timestamp + membershipVoteDuration) { // Simplified time-based auto-execution for example
            _processMembershipVote(requestId);
        }
    }

    /// @dev Processes the membership vote and updates membership status.
    /// @param requestId The ID of the membership request.
    function _processMembershipVote(uint256 requestId) internal {
        MembershipRequest storage request = membershipRequests[requestId];
        if (!request.isActive) return; // Prevent re-processing

        request.isActive = false; // Deactivate request after processing

        uint256 totalMembers = 0; // In a real DAO, you'd track active members more robustly
        for (uint256 i = 1; i <= _membershipRequestIds.current(); i++) { // Simplified member count - not scalable for large DAOs
            if (membershipStatus[membershipRequests[i].requester] == MembershipStatus.Member) {
                totalMembers++;
            }
        }
        uint256 requiredVotes = (totalMembers / 2) + 1; // Simple majority for example

        if (request.votesFor >= requiredVotes) {
            membershipStatus[request.requester] = MembershipStatus.Member;
            emit MembershipAccepted(request.requester);
        } else {
            membershipStatus[request.requester] = MembershipStatus.NotMember; // Or back to NotMember if it was pending
            emit MembershipRejected(request.requester);
        }
    }

    /// @notice Checks if an address is a member.
    /// @param _address The address to check.
    /// @return MembershipStatus The membership status of the address.
    function getMembershipStatus(address _address) external view returns (MembershipStatus) {
        return membershipStatus[_address];
    }

    /// @notice Members propose new rules or changes to the collective's governance.
    /// @param _description A description of the proposed rule.
    function proposeNewRule(string memory _description) external onlyMembers {
        _ruleProposalIds.increment();
        uint256 proposalId = _ruleProposalIds.current();
        ruleProposals[proposalId] = RuleProposal({
            proposer: msg.sender,
            proposalId: proposalId,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit RuleProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Members vote on governance proposals.
    /// @param proposalId The ID of the rule proposal to vote on.
    /// @param vote True for approval, false for rejection.
    function voteOnRuleProposal(uint256 proposalId, bool vote) external onlyMembers validRuleProposal(proposalId) {
        RuleProposal storage proposal = ruleProposals[proposalId];
        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit RuleProposalVoteCast(proposalId, msg.sender, vote);

        if (block.timestamp >= block.timestamp + ruleProposalVoteDuration) { // Simplified time-based auto-execution
            _processRuleProposalVote(proposalId);
        }
    }

    /// @dev Processes the rule proposal vote and executes if passed.
    /// @param proposalId The ID of the rule proposal.
    function _processRuleProposalVote(uint256 proposalId) internal {
        RuleProposal storage proposal = ruleProposals[proposalId];
        if (!proposal.isActive) return; // Prevent re-processing
        proposal.isActive = false; // Deactivate after processing

        uint256 totalMembers = 0;
        for (uint256 i = 1; i <= _membershipRequestIds.current(); i++) { // Simplified member count
            if (membershipStatus[membershipRequests[i].requester] == MembershipStatus.Member) {
                totalMembers++;
            }
        }
        uint256 requiredVotes = (totalMembers / 2) + 1; // Simple majority

        if (proposal.votesFor >= requiredVotes) {
            proposal.isExecuted = true;
            emit RuleProposalExecuted(proposalId);
            // Rule execution logic would go here - for this example, just marking as executed
            // Example:  if (proposal.description == "Change art sale price to 0.2 ETH") { artPieceSalePrice = 0.2 ether; }
        }
    }

    /// @notice Executes a rule proposal if it passes the voting. (Can be called externally after voting period)
    /// @param proposalId The ID of the rule proposal to execute.
    function executeRuleProposal(uint256 proposalId) external onlyMembers validRuleProposal(proposalId) {
        RuleProposal storage proposal = ruleProposals[proposalId];
        require(!proposal.isExecuted, "Rule proposal already executed");
        _processRuleProposalVote(proposalId); // Re-process vote to ensure it's been checked, could optimize to just check status if vote period passed.
    }


    // --- Art Submission & Curation Functions ---

    /// @notice Members submit their art pieces for curation.
    /// @param _ipfsHash IPFS hash pointing to the art piece's metadata.
    function submitArtPiece(string memory _ipfsHash) external onlyMembers {
        _artPieceIds.increment();
        uint256 artPieceId = _artPieceIds.current();
        _mint(address(this), artPieceId); // Mint to contract address initially
        artPieceToSubmitter[artPieceId] = msg.sender;

        _artPieceProposals.increment();
        uint256 proposalId = _artPieceProposals.current();
        artPieceProposals[proposalId] = ArtPieceProposal({
            submitter: msg.sender,
            proposalId: proposalId,
            ipfsHash: _ipfsHash,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isAccepted: false
        });
        emit ArtPieceSubmitted(msg.sender, proposalId, _ipfsHash);
    }

    /// @notice Members vote on submitted art pieces to be accepted into the collective's collection.
    /// @param proposalId The ID of the art piece proposal.
    /// @param vote True for approval, false for rejection.
    function voteOnArtPiece(uint256 proposalId, bool vote) external onlyMembers validArtProposal(proposalId) {
        ArtPieceProposal storage proposal = artPieceProposals[proposalId];
        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtPieceVoteCast(proposalId, msg.sender, vote);

        if (block.timestamp >= block.timestamp + artCurationVoteDuration) { // Simplified time-based auto-execution
            _processArtPieceVote(proposalId);
        }
    }

    /// @dev Processes the art piece vote and accepts or rejects the piece based on votes.
    /// @param proposalId The ID of the art piece proposal.
    function _processArtPieceVote(uint256 proposalId) internal {
        ArtPieceProposal storage proposal = artPieceProposals[proposalId];
        if (!proposal.isActive) return; // Prevent re-processing
        proposal.isActive = false; // Deactivate after processing

        uint256 totalMembers = 0;
        for (uint256 i = 1; i <= _membershipRequestIds.current(); i++) { // Simplified member count
            if (membershipStatus[membershipRequests[i].requester] == MembershipStatus.Member) {
                totalMembers++;
            }
        }
        uint256 requiredVotes = (totalMembers / 2) + 1; // Simple majority

        if (proposal.votesFor >= requiredVotes) {
            proposal.isAccepted = true;
            uint256 artPieceId = _artPieceIds.current(); // Assuming _artPieceIds was incremented in submitArtPiece
            _safeTransfer(address(this), address(this), artPieceId); // Still held by contract until sold
            emit ArtPieceAccepted(artPieceId, proposalId);
        } else {
            uint256 artPieceId = _artPieceIds.current(); // Assuming _artPieceIds was incremented in submitArtPiece
            _burn(artPieceId); // Burn the NFT if rejected
            emit ArtPieceRejected(proposalId);
        }
    }

    /// @notice Accepts an art piece into the collective's collection if it passes curation. (Can be called externally after voting period)
    /// @param proposalId The ID of the art piece proposal to accept.
    function acceptArtPiece(uint256 proposalId) external onlyMembers validArtProposal(proposalId) {
        ArtPieceProposal storage proposal = artPieceProposals[proposalId];
        require(!proposal.isAccepted && !proposal.isActive, "Art piece proposal already processed or still active.");
        _processArtPieceVote(proposalId); // Re-process vote to ensure it's checked, could optimize.
    }

    /// @notice Rejects an art piece if it fails curation. (Can be called externally after voting period)
    /// @param proposalId The ID of the art piece proposal to reject.
    function rejectArtPiece(uint256 proposalId) external onlyMembers validArtProposal(proposalId) {
        ArtPieceProposal storage proposal = artPieceProposals[proposalId];
        require(proposal.isAccepted || !proposal.isActive, "Art piece proposal already processed or still active.");
        _processArtPieceVote(proposalId); // Re-process vote to ensure it's checked, could optimize.
    }

    /// @notice Checks the status of a submitted art piece.
    /// @param proposalId The ID of the art piece proposal.
    /// @return ArtPieceStatus The status of the art piece.
    function getArtPieceStatus(uint256 proposalId) external view returns (ArtPieceStatus) {
        if (!artPieceProposals[proposalId].isActive && artPieceProposals[proposalId].isAccepted) {
            return ArtPieceStatus.Accepted;
        } else if (!artPieceProposals[proposalId].isActive && !artPieceProposals[proposalId].isAccepted) {
            return ArtPieceStatus.Rejected;
        } else if (artPieceProposals[proposalId].isActive) {
            return ArtPieceStatus.UnderReview;
        } else {
            return ArtPieceStatus.Submitted; // Should not reach here in normal flow, but for completeness
        }
    }

    /// @notice Allows the collective to list accepted art pieces for sale.
    /// @param artPieceId The ID of the art piece NFT.
    /// @param price The sale price in wei.
    function listArtForSale(uint256 artPieceId, uint256 price) external onlyMembers {
        require(ownerOf(artPieceId) == address(this), "Art piece not owned by collective");
        artPieceSalePrice = price; // Simplifies to set a collective price for all for this example. In real scenario, might want individual pricing or auction.
        emit ArtPieceListedForSale(artPieceId, price);
    }

    /// @notice Allows users to purchase art pieces listed by the collective.
    /// @param artPieceId The ID of the art piece NFT to purchase.
    function buyArtPiece(uint256 artPieceId) external payable {
        require(ownerOf(artPieceId) == address(this), "Art piece not available for sale");
        require(msg.value >= artPieceSalePrice, "Insufficient funds sent");

        artSaleProceeds += artPieceSalePrice;
        _safeTransfer(address(this), msg.sender, artPieceId);
        emit ArtPiecePurchased(artPieceId, msg.sender, artPieceSalePrice);
    }

    /// @notice Allows the collective to withdraw proceeds from art sales. (Governance controlled in real scenario)
    function withdrawArtSaleProceeds() external onlyMembers { // In real DAO, this should be a governed proposal
        require(artSaleProceeds > 0, "No proceeds to withdraw");
        uint256 amountToWithdraw = artSaleProceeds;
        artSaleProceeds = 0;
        payable(owner()).transfer(amountToWithdraw); // Simplifies to owner withdrawal for example. In real DAO, would be treasury management.
        emit DonationsWithdrawn(amountToWithdraw, owner()); // Reusing event name for simplicity, should be renamed if needed.
    }


    // --- Dynamic NFT Evolution & Community Interaction Functions ---

    /// @notice Members propose an evolution or modification to a curated NFT.
    /// @param _artPieceId The ID of the art piece NFT to evolve.
    /// @param _description A description of the proposed evolution.
    function proposeNFTEvolution(uint256 _artPieceId, string memory _description) external onlyMembers {
        require(ownerOf(_artPieceId) == address(this), "Collective doesn't own this art piece");
        _nftEvolutionProposalIds.increment();
        uint256 proposalId = _nftEvolutionProposalIds.current();
        nftEvolutionProposals[proposalId] = NFTEvolutionProposal({
            artPieceId: _artPieceId,
            proposer: msg.sender,
            proposalId: proposalId,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit NFTEvolutionProposed(_artPieceId, proposalId, msg.sender, _description);
    }

    /// @notice Members vote on proposed NFT evolutions.
    /// @param proposalId The ID of the NFT evolution proposal.
    /// @param vote True for approval, false for rejection.
    function voteOnNFTEvolution(uint256 proposalId, bool vote) external onlyMembers validNFTEvolutionProposal(proposalId) {
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[proposalId];
        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit NFTEvolutionVoteCast(proposalId, msg.sender, vote);

        if (block.timestamp >= block.timestamp + nftEvolutionVoteDuration) { // Simplified time-based auto-execution
            _processNFTEvolutionVote(proposalId);
        }
    }

    /// @dev Processes the NFT evolution vote and executes if passed.
    /// @param proposalId The ID of the NFT evolution proposal.
    function _processNFTEvolutionVote(uint256 proposalId) internal {
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[proposalId];
        if (!proposal.isActive) return; // Prevent re-processing
        proposal.isActive = false; // Deactivate after processing

        uint256 totalMembers = 0;
        for (uint256 i = 1; i <= _membershipRequestIds.current(); i++) { // Simplified member count
            if (membershipStatus[membershipRequests[i].requester] == MembershipStatus.Member) {
                totalMembers++;
            }
        }
        uint256 requiredVotes = (totalMembers / 2) + 1; // Simple majority

        if (proposal.votesFor >= requiredVotes) {
            proposal.isExecuted = true;
            emit NFTEvolved(proposal.artPieceId, proposalId);
            // NFT Evolution logic would go here - for this example, just marking as executed and maybe update metadata in tokenURI
            // Example: if (proposal.description == "Add glowing effect") { _setTokenURI(proposal.artPieceId, "ipfs://...updated_metadata_with_glow..."); }
        }
    }

    /// @notice Executes an NFT evolution if it passes the voting. (Can be called externally after voting period)
    /// @param proposalId The ID of the NFT evolution proposal to execute.
    function evolveNFT(uint256 proposalId) external onlyMembers validNFTEvolutionProposal(proposalId) {
        NFTEvolutionProposal storage proposal = nftEvolutionProposals[proposalId];
        require(!proposal.isExecuted, "NFT evolution already executed");
        _processNFTEvolutionVote(proposalId); // Re-process vote to ensure it's checked, could optimize.
    }

    /// @notice Allows members to create polls for community decisions or feedback (non-binding).
    /// @param _question The question for the community poll.
    /// @param _options An array of options for the poll.
    function createCommunityPoll(string memory _question, string[] memory _options) external onlyMembers {
        require(_options.length > 0, "Poll must have options");
        _communityPollIds.increment();
        uint256 pollId = _communityPollIds.current();
        communityPolls[pollId] = CommunityPoll({
            creator: msg.sender,
            pollId: pollId,
            question: _question,
            options: _options,
            voteCounts: new uint256[](_options.length),
            isActive: true,
            endTime: block.timestamp + communityPollDuration
        });
        emit CommunityPollCreated(pollId, msg.sender, _question, _options, communityPolls[pollId].endTime);
    }

    /// @notice Members vote in active community polls.
    /// @param pollId The ID of the community poll.
    /// @param optionIndex The index of the option to vote for (starting from 0).
    function voteInPoll(uint256 pollId, uint256 optionIndex) external onlyMembers validCommunityPoll(pollId) pollNotExpired(pollId) {
        CommunityPoll storage poll = communityPolls[pollId];
        require(optionIndex < poll.options.length, "Invalid option index");
        require(poll.votes[msg.sender] == 0, "Already voted in this poll"); // Simple one-vote per member

        poll.votes[msg.sender] = optionIndex + 1; // Store option index + 1 to represent vote
        poll.voteCounts[optionIndex]++;
        emit PollVoteCast(pollId, msg.sender, optionIndex);

        if (block.timestamp >= poll.endTime) {
            _completeCommunityPoll(pollId);
        }
    }

    /// @dev Completes a community poll and deactivates it.
    /// @param pollId The ID of the community poll to complete.
    function _completeCommunityPoll(uint256 pollId) internal {
        CommunityPoll storage poll = communityPolls[pollId];
        if (!poll.isActive) return; // Prevent re-processing
        poll.isActive = false;
        emit PollCompleted(pollId);
    }

    /// @notice Retrieves the results of a completed community poll.
    /// @param pollId The ID of the community poll.
    /// @return string The poll question.
    /// @return string[] The poll options.
    /// @return uint256[] The vote counts for each option.
    /// @return PollStatus The status of the poll.
    function getPollResults(uint256 pollId) external view returns (string memory question, string[] memory options, uint256[] memory voteCounts, PollStatus status) {
        CommunityPoll storage poll = communityPolls[pollId];
        PollStatus pollStatus = poll.isActive ? PollStatus.Active : PollStatus.Completed;
        return (poll.question, poll.options, poll.voteCounts, pollStatus);
    }

    /// @notice Allows anyone to donate ETH to the collective's treasury.
    function donateToCollective() external payable {
        collectiveDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice (Governance Controlled) Allows members to propose and vote on withdrawing donations for collective purposes.
    function withdrawDonations(uint256 amount) external onlyMembers { // In real DAO, this should be a governed proposal process.
        require(collectiveDonations >= amount, "Insufficient donations to withdraw");
        collectiveDonations -= amount;
        payable(owner()).transfer(amount); // Simplifies to owner withdrawal for example. In real DAO, would be treasury management.
        emit DonationsWithdrawn(amount, owner());
    }

    // --- Token URI Overrides ---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        ArtPieceProposal storage proposal = artPieceProposals[tokenId]; // Assuming proposalId and tokenId are aligned for simplicity in this example. In real world, might need a separate mapping.
        if (proposal.isAccepted) {
            return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json")); // Construct URI based on tokenId.  .json is just a common convention.
        } else {
            return "ipfs://invalid_art_piece_metadata"; // Return a default URI for rejected or not yet accepted pieces.
        }
    }

    // --- Admin Functions ---
    function setMembershipVoteDuration(uint256 _duration) external onlyOwner {
        membershipVoteDuration = _duration;
    }

    function setArtCurationVoteDuration(uint256 _duration) external onlyOwner {
        artCurationVoteDuration = _duration;
    }

    function setRuleProposalVoteDuration(uint256 _duration) external onlyOwner {
        ruleProposalVoteDuration = _duration;
    }

    function setNFTEvolutionVoteDuration(uint256 _duration) external onlyOwner {
        nftEvolutionVoteDuration = _duration;
    }

    function setCommunityPollDuration(uint256 _duration) external onlyOwner {
        communityPollDuration = _duration;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Function to retrieve contract balance for debugging/admin purposes
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive ETH donations
    receive() external payable {
        donateToCollective();
    }

    // Payable function to receive ETH donations
    fallback() external payable {
        donateToCollective();
    }
}
```