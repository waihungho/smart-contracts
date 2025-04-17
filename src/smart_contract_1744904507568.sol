```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production)
 * @notice This smart contract represents a Decentralized Autonomous Art Collective (DAAC)
 *         focused on collaborative art creation, curation, and community-driven governance.
 *         It incorporates advanced concepts like dynamic NFTs, fractional ownership, AI-assisted curation
 *         (conceptually via oracles), and decentralized reputation systems.
 *
 * Function Summary:
 *
 * **Membership & Governance:**
 * 1. requestMembership(): Allows users to request membership to the DAAC.
 * 2. approveMembership(address _member): Admin function to approve pending membership requests.
 * 3. revokeMembership(address _member): Admin function to revoke membership.
 * 4. submitProposal(string memory _title, string memory _description, bytes memory _data): Members can submit governance proposals.
 * 5. voteOnProposal(uint256 _proposalId, bool _vote): Members can vote on active proposals.
 * 6. executeProposal(uint256 _proposalId): Executes a proposal if it passes and is executable.
 * 7. setQuorum(uint256 _newQuorum): Admin function to change the quorum for proposals.
 * 8. setVotingDuration(uint256 _newDuration): Admin function to change the voting duration for proposals.
 *
 * **Art Creation & Curation:**
 * 9. submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash): Members propose new art pieces for the collective.
 * 10. voteOnArtProposal(uint256 _artProposalId, bool _vote): Members vote on art proposals.
 * 11. mintArtNFT(uint256 _artProposalId): Mints an NFT for approved art proposals (admin/curator role).
 * 12. purchaseFractionalArt(uint256 _tokenId, uint256 _amount): Allows purchasing fractional ownership of an art NFT.
 * 13. offerArtForSale(uint256 _tokenId, uint256 _price): NFT holders can offer their fractional shares for sale.
 * 14. buyArtFractionFromSale(uint256 _saleId): Allows buying fractional shares offered for sale.
 * 15. withdrawArtProceeds(uint256 _tokenId): Allows NFT owners to withdraw their share of proceeds from sales.
 *
 * **Advanced & Trendy Features:**
 * 16. requestAIArtCuration(uint256 _artProposalId, address _aiOracle): (Conceptual) Members request AI-based curation for art proposals via an oracle.
 * 17. reportArtContent(uint256 _tokenId, string memory _reportReason): Members can report potentially inappropriate art content.
 * 18. voteOnArtReport(uint256 _reportId, bool _isHarmful): Members vote on art content reports.
 * 19. burnHarmfulArt(uint256 _tokenId): Admin function to burn NFTs deemed harmful after a report.
 * 20. donateToCollective(): Allow users to donate ETH to the collective treasury.
 * 21. proposeTreasurySpending(string memory _description, address _recipient, uint256 _amount): Members propose spending from the collective treasury.
 * 22. withdrawDonations(): Admin function to withdraw collected donations to a designated address (for collective purposes).
 *
 * **Utility & Admin:**
 * 23. getProposalState(uint256 _proposalId): View function to check the state of a proposal.
 * 24. getArtProposalState(uint256 _artProposalId): View function to check the state of an art proposal.
 * 25. getFractionalBalance(uint256 _tokenId, address _owner): View function to get fractional balance of an NFT.
 * 26. getSaleDetails(uint256 _saleId): View function to get details of an art fraction sale.
 * 27. getMemberCount(): View function to get the current number of members.
 * 28. getPendingMembershipRequestsCount(): View function to get the number of pending membership requests.
 * 29. setAdmin(address _newAdmin): Admin function to change the contract admin.
 */
contract DecentralizedArtCollective {
    // --- State Variables ---

    address public admin;
    uint256 public quorum = 50; // Percentage quorum for proposals (e.g., 50% = 50)
    uint256 public votingDuration = 7 days; // Default voting duration

    mapping(address => bool) public members;
    mapping(address => bool) public pendingMembershipRequests;
    address[] public membershipRequestQueue;

    uint256 public proposalCount = 0;
    struct Proposal {
        uint256 id;
        string title;
        string description;
        bytes data; // Optional data for proposal execution
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes; // Members who voted
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;

    uint256 public artProposalCount = 0;
    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the art piece
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes;
        uint256 yesVotes;
        uint256 noVotes;
        bool approved;
        bool minted;
    }
    mapping(uint256 => ArtProposal) public artProposals;

    uint256 public nextArtTokenId = 1;
    mapping(uint256 => address) public artTokenCreators; // Creator of each art token
    mapping(uint256 => mapping(address => uint256)) public fractionalArtOwnership; // TokenId -> Owner -> Shares
    mapping(uint256 => uint256) public totalArtSupply; // TokenId -> Total fractional supply (e.g., 1000 for 100%)

    uint256 public saleIdCounter = 0;
    struct ArtFractionSale {
        uint256 id;
        uint256 tokenId;
        address seller;
        uint256 amount; // Amount of fractional shares for sale
        uint256 price; // Price per fractional share
        bool active;
    }
    mapping(uint256 => ArtFractionSale) public artSales;

    uint256 public reportCount = 0;
    struct ArtReport {
        uint256 id;
        uint256 tokenId;
        address reporter;
        string reason;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) votes;
        uint256 yesVotes; // Votes for "is harmful"
        uint256 noVotes;  // Votes for "is not harmful"
        bool resolved;
        bool isHarmful;
    }
    mapping(uint256 => ArtReport) public artReports;

    address public donationWallet; // Address to withdraw donations to

    // --- Events ---
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ArtProposalCreated(uint256 artProposalId, string title, address proposer);
    event ArtProposalVoted(uint256 artProposalId, address voter, bool vote);
    event ArtNFTMinted(uint256 tokenId, address creator, string ipfsHash);
    event FractionalArtPurchased(uint256 tokenId, address buyer, uint256 amount);
    event ArtFractionOfferedForSale(uint256 saleId, uint256 tokenId, address seller, uint256 amount, uint256 price);
    event ArtFractionSalePurchased(uint256 saleId, address buyer, uint256 amount);
    event ArtReportSubmitted(uint256 reportId, uint256 tokenId, address reporter);
    event ArtReportResolved(uint256 reportId, uint256 tokenId, bool isHarmful);
    event ArtBurned(uint256 tokenId);
    event DonationReceived(address donor, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, string description, address recipient, uint256 amount, address proposer);
    event DonationsWithdrawn(address admin, address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp <= proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier validArtProposal(uint256 _artProposalId) {
        require(_artProposalId > 0 && _artProposalId <= artProposalCount, "Invalid art proposal ID.");
        require(!artProposals[_artProposalId].minted, "Art proposal already minted.");
        require(block.timestamp <= artProposals[_artProposalId].endTime, "Art proposal voting period ended.");
        _;
    }

    modifier validArtToken(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId < nextArtTokenId, "Invalid art token ID.");
        _;
    }

    modifier validArtSale(uint256 _saleId) {
        require(_saleId > 0 && _saleId <= saleIdCounter, "Invalid sale ID.");
        require(artSales[_saleId].active, "Sale is not active.");
        _;
    }

    modifier validArtReport(uint256 _reportId) {
        require(_reportId > 0 && _reportId <= reportCount, "Invalid report ID.");
        require(!artReports[_reportId].resolved, "Report already resolved.");
        require(block.timestamp <= artReports[_reportId].endTime, "Report voting period ended.");
        _;
    }

    // --- Constructor ---
    constructor(address _donationWallet) payable {
        admin = msg.sender;
        donationWallet = _donationWallet;
    }

    // --- Membership & Governance Functions ---

    /// @notice Allows a user to request membership to the DAAC.
    function requestMembership() external {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMembershipRequests[msg.sender], "Membership request already pending.");
        pendingMembershipRequests[msg.sender] = true;
        membershipRequestQueue.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve a pending membership request.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyAdmin {
        require(pendingMembershipRequests[_member], "No pending membership request for this address.");
        members[_member] = true;
        pendingMembershipRequests[_member] = false;
        // Remove from queue (inefficient for large queues, consider optimization if needed)
        for (uint i = 0; i < membershipRequestQueue.length; i++) {
            if (membershipRequestQueue[i] == _member) {
                membershipRequestQueue[i] = membershipRequestQueue[membershipRequestQueue.length - 1];
                membershipRequestQueue.pop();
                break;
            }
        }
        emit MembershipApproved(_member);
    }

    /// @notice Admin function to revoke membership from a member.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyAdmin {
        require(members[_member], "Not a member.");
        delete members[_member];
        emit MembershipRevoked(_member);
    }

    /// @notice Allows members to submit a governance proposal.
    /// @param _title The title of the proposal.
    /// @param _description A detailed description of the proposal.
    /// @param _data Optional data to be used when executing the proposal (e.g., contract calls).
    function submitProposal(string memory _title, string memory _description, bytes memory _data) external onlyMember {
        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + votingDuration;
        emit ProposalCreated(proposalCount, _title, msg.sender);
    }

    /// @notice Allows members to vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) {
        require(!proposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        proposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a governance proposal if it has passed the quorum and voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyAdmin { // Admin can execute after voting
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp > proposal.endTime, "Voting period is not over yet.");

        uint256 totalMembers = getMemberCount();
        uint256 votesCast = proposal.yesVotes + proposal.noVotes;
        uint256 quorumNeeded = (totalMembers * quorum) / 100;

        if (votesCast >= quorumNeeded && proposal.yesVotes > proposal.noVotes) {
            proposal.passed = true;
            proposal.executed = true;
            // Execute proposal logic here based on proposal.data (e.g., contract calls)
            // Example: (Simple - be cautious with dynamic calls in production)
            // if (proposal.data.length > 0) {
            //     (bool success, ) = address(this).delegatecall(proposal.data);
            //     require(success, "Proposal execution failed.");
            // }
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.passed = false;
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution
        }
    }

    /// @notice Admin function to set the quorum percentage for proposals.
    /// @param _newQuorum The new quorum percentage (e.g., 50 for 50%).
    function setQuorum(uint256 _newQuorum) external onlyAdmin {
        require(_newQuorum <= 100, "Quorum percentage must be between 0 and 100.");
        quorum = _newQuorum;
    }

    /// @notice Admin function to set the voting duration for proposals.
    /// @param _newDuration The new voting duration in seconds.
    function setVotingDuration(uint256 _newDuration) external onlyAdmin {
        votingDuration = _newDuration;
    }


    // --- Art Creation & Curation Functions ---

    /// @notice Members propose a new art piece for the collective.
    /// @param _title The title of the art piece.
    /// @param _description A description of the art piece.
    /// @param _ipfsHash The IPFS hash of the art piece's metadata.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember {
        artProposalCount++;
        ArtProposal storage newArtProposal = artProposals[artProposalCount];
        newArtProposal.id = artProposalCount;
        newArtProposal.title = _title;
        newArtProposal.description = _description;
        newArtProposal.ipfsHash = _ipfsHash;
        newArtProposal.startTime = block.timestamp;
        newArtProposal.endTime = block.timestamp + votingDuration;
        emit ArtProposalCreated(artProposalCount, _title, msg.sender);
    }

    /// @notice Members vote on an art proposal.
    /// @param _artProposalId The ID of the art proposal to vote on.
    /// @param _vote True for approve, false for reject.
    function voteOnArtProposal(uint256 _artProposalId, bool _vote) external onlyMember validArtProposal(_artProposalId) {
        require(!artProposals[_artProposalId].votes[msg.sender], "Already voted on this art proposal.");
        artProposals[_artProposalId].votes[msg.sender] = true;
        if (_vote) {
            artProposals[_artProposalId].yesVotes++;
        } else {
            artProposals[_artProposalId].noVotes++;
        }
        emit ArtProposalVoted(_artProposalId, msg.sender, _vote);
    }

    /// @notice Mints an NFT for an approved art proposal. (Admin/Curator role - could be DAO governed later)
    /// @param _artProposalId The ID of the approved art proposal.
    function mintArtNFT(uint256 _artProposalId) external onlyAdmin { // Could be DAO governed minting in future
        require(_artProposalId > 0 && _artProposalId <= artProposalCount, "Invalid art proposal ID.");
        ArtProposal storage artProposal = artProposals[_artProposalId];
        require(!artProposal.minted, "Art proposal already minted.");
        require(block.timestamp > artProposal.endTime, "Art proposal voting period not over.");

        uint256 totalMembers = getMemberCount();
        uint256 votesCast = artProposal.yesVotes + artProposal.noVotes;
        uint256 quorumNeeded = (totalMembers * quorum) / 100;

        if (votesCast >= quorumNeeded && artProposal.yesVotes > artProposal.noVotes) {
            artProposal.approved = true;
            artProposal.minted = true;
            uint256 tokenId = nextArtTokenId++;
            artTokenCreators[tokenId] = msg.sender; // Admin minting, creator set to admin for now
            totalArtSupply[tokenId] = 1000; // Example: 1000 fractional shares = 100%
            fractionalArtOwnership[tokenId][address(this)] = 1000; // Collective initially owns 100%
            emit ArtNFTMinted(tokenId, msg.sender, artProposal.ipfsHash); // Creator might be art proposer in future
        } else {
            artProposal.approved = false;
            artProposal.minted = true; // Mark as minted to prevent re-minting even if failed
        }
    }

    /// @notice Allows purchasing fractional ownership of an art NFT from the collective.
    /// @param _tokenId The ID of the art NFT.
    /// @param _amount The amount of fractional shares to purchase.
    function purchaseFractionalArt(uint256 _tokenId, uint256 _amount) external payable validArtToken(_tokenId) {
        require(fractionalArtOwnership[_tokenId][address(this)] >= _amount, "Collective does not have enough shares to sell.");
        require(msg.value > 0, "Purchase amount must be greater than 0."); // In real world, price logic needed
        // In a real implementation, you would have pricing logic and potentially different tiers of fractional ownership.
        fractionalArtOwnership[_tokenId][address(this)] -= _amount;
        fractionalArtOwnership[_tokenId][msg.sender] += _amount;
        emit FractionalArtPurchased(_tokenId, msg.sender, _amount);
        // Transfer funds to collective treasury or artist, etc. (Decide on revenue distribution model)
        payable(donationWallet).transfer(msg.value); // Example: Direct donations to collective wallet
    }

    /// @notice Allows an NFT holder to offer their fractional shares for sale.
    /// @param _tokenId The ID of the art NFT.
    /// @param _amount The amount of fractional shares to sell.
    /// @param _price The price per fractional share.
    function offerArtForSale(uint256 _tokenId, uint256 _amount, uint256 _price) external validArtToken(_tokenId) {
        require(fractionalArtOwnership[_tokenId][msg.sender] >= _amount, "Not enough shares to sell.");
        saleIdCounter++;
        artSales[saleIdCounter] = ArtFractionSale({
            id: saleIdCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            amount: _amount,
            price: _price,
            active: true
        });
        emit ArtFractionOfferedForSale(saleIdCounter, _tokenId, msg.sender, _amount, _price);
    }

    /// @notice Allows buying fractional shares offered for sale.
    /// @param _saleId The ID of the art fraction sale.
    function buyArtFractionFromSale(uint256 _saleId) external payable validArtSale(_saleId) {
        ArtFractionSale storage sale = artSales[_saleId];
        require(msg.value >= sale.price * sale.amount, "Insufficient funds to purchase.");
        require(fractionalArtOwnership[sale.tokenId][sale.seller] >= sale.amount, "Seller no longer has enough shares."); // Double check in case of concurrent sales
        fractionalArtOwnership[sale.tokenId][sale.seller] -= sale.amount;
        fractionalArtOwnership[sale.tokenId][msg.sender] += sale.amount;
        sale.active = false; // Deactivate sale
        emit ArtFractionSalePurchased(_saleId, msg.sender, sale.amount);
        payable(sale.seller).transfer(msg.value); // Transfer funds to seller
    }

    /// @notice Allows NFT owners to withdraw their share of proceeds from sales (if revenue share model is implemented).
    /// @param _tokenId The ID of the art NFT.
    function withdrawArtProceeds(uint256 _tokenId) external validArtToken(_tokenId) {
        // In a real implementation, you would track proceeds and allow withdrawal based on ownership share.
        // This is a placeholder for a more complex revenue sharing mechanism.
        revert("Revenue sharing and withdrawal mechanism not implemented yet.");
    }


    // --- Advanced & Trendy Features ---

    /// @notice (Conceptual) Members can request AI-based curation for art proposals via an oracle.
    /// @param _artProposalId The ID of the art proposal to curate.
    /// @param _aiOracle Address of the AI oracle contract.
    function requestAIArtCuration(uint256 _artProposalId, address _aiOracle) external onlyMember validArtProposal(_artProposalId) {
        // This is a conceptual function. In reality, you'd interact with an off-chain AI oracle service.
        // You'd likely emit an event that an off-chain service listens to, performs AI analysis,
        // and then calls back to the contract (potentially via a dedicated oracle function - not shown here).
        // For simplicity, we'll just emit an event indicating a request.
        emit ArtProposalCurationRequested(_artProposalId, msg.sender, _aiOracle);
    }
     event ArtProposalCurationRequested(uint256 artProposalId, address requester, address aiOracle);


    /// @notice Members can report potentially inappropriate art content.
    /// @param _tokenId The ID of the art NFT being reported.
    /// @param _reportReason Reason for reporting the art content.
    function reportArtContent(uint256 _tokenId, string memory _reportReason) external onlyMember validArtToken(_tokenId) {
        reportCount++;
        ArtReport storage newReport = artReports[reportCount];
        newReport.id = reportCount;
        newReport.tokenId = _tokenId;
        newReport.reporter = msg.sender;
        newReport.reason = _reportReason;
        newReport.startTime = block.timestamp;
        newReport.endTime = block.timestamp + votingDuration;
        emit ArtReportSubmitted(reportCount, _tokenId, msg.sender);
    }

    /// @notice Members vote on an art content report.
    /// @param _reportId The ID of the art report.
    /// @param _isHarmful True if the content is deemed harmful, false otherwise.
    function voteOnArtReport(uint256 _reportId, bool _isHarmful) external onlyMember validArtReport(_reportId) {
        require(!artReports[_reportId].votes[msg.sender], "Already voted on this report.");
        artReports[_reportId].votes[msg.sender] = true;
        if (_isHarmful) {
            artReports[_reportId].yesVotes++;
        } else {
            artReports[_reportId].noVotes++;
        }
    }

    /// @notice Admin function to burn an NFT deemed harmful after a report is resolved.
    /// @param _tokenId The ID of the art NFT to burn.
    function burnHarmfulArt(uint256 _tokenId) external onlyAdmin validArtToken(_tokenId) {
        uint256 reportId = 0;
        for(uint256 i = 1; i <= reportCount; i++) {
            if(artReports[i].tokenId == _tokenId && !artReports[i].resolved && block.timestamp > artReports[i].endTime) {
                reportId = i;
                break;
            }
        }
        require(reportId != 0, "No resolved report found for this token.");
        ArtReport storage report = artReports[reportId];
        require(!report.resolved, "Report already resolved.");

        uint256 totalMembers = getMemberCount();
        uint256 votesCast = report.yesVotes + report.noVotes;
        uint256 quorumNeeded = (totalMembers * quorum) / 100;

        if (votesCast >= quorumNeeded && report.yesVotes > report.noVotes) {
            report.isHarmful = true;
            report.resolved = true;
            // In a real NFT contract, you would implement burning logic.
            // For simplicity, we'll just remove ownership and emit an event.
            delete fractionalArtOwnership[_tokenId];
            delete artTokenCreators[_tokenId];
            emit ArtBurned(_tokenId);
        } else {
            report.isHarmful = false;
            report.resolved = true;
        }
        emit ArtReportResolved(reportId, _tokenId, report.isHarmful);
    }

    /// @notice Allows users to donate ETH to the collective treasury.
    function donateToCollective() external payable {
        require(msg.value > 0, "Donation amount must be greater than 0.");
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Members propose spending from the collective treasury.
    /// @param _description Description of the spending proposal.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to spend (in wei).
    function proposeTreasurySpending(string memory _description, address _recipient, uint256 _amount) external onlyMember {
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount);
        submitProposal("Treasury Spending: " + _description, _description, data);
        emit TreasurySpendingProposed(proposalCount, _description, _recipient, _amount, msg.sender);
    }

    /// @notice Admin function to withdraw collected donations to a designated address.
    function withdrawDonations() external onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 contractDonations = balance - msg.value; // Assuming initial value is not donation
        require(contractDonations > 0, "No donations to withdraw.");
        payable(donationWallet).transfer(contractDonations);
        emit DonationsWithdrawn(msg.sender, donationWallet, contractDonations);
    }


    // --- Utility & Admin Functions ---

    /// @notice View function to get the state of a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return State of the proposal (e.g., "Active", "Passed", "Failed", "Executed").
    function getProposalState(uint256 _proposalId) external view returns (string memory) {
        if (_proposalId == 0 || _proposalId > proposalCount) return "Invalid Proposal ID";
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.executed && block.timestamp <= proposal.endTime) return "Active";
        if (proposal.executed && proposal.passed) return "Passed & Executed";
        if (proposal.executed && !proposal.passed) return "Failed & Executed";
        if (!proposal.executed && block.timestamp > proposal.endTime) return "Voting Ended - Not Executed";
        return "Unknown";
    }

    /// @notice View function to get the state of an art proposal.
    /// @param _artProposalId The ID of the art proposal.
    /// @return State of the art proposal (e.g., "Active", "Approved", "Rejected", "Minted").
    function getArtProposalState(uint256 _artProposalId) external view returns (string memory) {
        if (_artProposalId == 0 || _artProposalId > artProposalCount) return "Invalid Art Proposal ID";
        ArtProposal storage artProposal = artProposals[_artProposalId];
        if (!artProposal.minted && block.timestamp <= artProposal.endTime) return "Active";
        if (artProposal.approved && artProposal.minted) return "Approved & Minted";
        if (!artProposal.approved && artProposal.minted) return "Rejected & Minted (Failed)";
        if (!artProposal.minted && block.timestamp > artProposal.endTime) return "Voting Ended - Not Minted";
        return "Unknown";
    }

    /// @notice View function to get the fractional balance of an art NFT for a given owner.
    /// @param _tokenId The ID of the art NFT.
    /// @param _owner The address of the owner.
    /// @return The number of fractional shares owned by the address.
    function getFractionalBalance(uint256 _tokenId, address _owner) external view validArtToken(_tokenId) returns (uint256) {
        return fractionalArtOwnership[_tokenId][_owner];
    }

    /// @notice View function to get details of an art fraction sale.
    /// @param _saleId The ID of the art fraction sale.
    /// @return Sale details (tokenId, seller, amount, price, active).
    function getSaleDetails(uint256 _saleId) external view validArtSale(_saleId) returns (uint256 tokenId, address seller, uint256 amount, uint256 price, bool active) {
        ArtFractionSale storage sale = artSales[_saleId];
        return (sale.tokenId, sale.seller, sale.amount, sale.price, sale.active);
    }

    /// @notice View function to get the current number of members.
    /// @return The number of members in the DAAC.
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getAllMembers(); // Get all member addresses
        for (uint i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    function getAllMembers() public view returns (address[] memory) {
        address[] memory memberList = new address[](membershipRequestQueue.length + proposalCount + artProposalCount + reportCount + 100); // Estimate max size
        uint256 index = 0;

        for (uint i = 0; i < membershipRequestQueue.length; i++) {
            memberList[index++] = membershipRequestQueue[i];
        }
        for (uint i = 1; i <= proposalCount; i++) {
            for (address voter : getProposalVoters(i)) {
                bool found = false;
                for(uint j=0; j<index; j++) {
                    if(memberList[j] == voter) {
                        found = true;
                        break;
                    }
                }
                if(!found) memberList[index++] = voter;
            }
        }
        for (uint i = 1; i <= artProposalCount; i++) {
            for (address voter : getArtProposalVoters(i)) {
                bool found = false;
                for(uint j=0; j<index; j++) {
                    if(memberList[j] == voter) {
                        found = true;
                        break;
                    }
                }
                if(!found) memberList[index++] = voter;
            }
        }
         for (uint i = 1; i <= reportCount; i++) {
            for (address voter : getReportVoters(i)) {
                bool found = false;
                for(uint j=0; j<index; j++) {
                    if(memberList[j] == voter) {
                        found = true;
                        break;
                    }
                }
                if(!found) memberList[index++] = voter;
            }
        }


        address[] memory finalMemberList = new address[](index);
        for(uint i=0; i<index; i++) {
            finalMemberList[i] = memberList[i];
        }
        return finalMemberList;
    }

    function getProposalVoters(uint256 _proposalId) internal view returns (address[] memory) {
        address[] memory voters = new address[](getMemberCount()); // Max possible voters
        uint256 voterCount = 0;
        Proposal storage proposal = proposals[_proposalId];
        address[] memory allMembers = getAllMembers();
         for (uint i = 0; i < allMembers.length; i++) {
            if (proposal.votes[allMembers[i]]) {
                voters[voterCount++] = allMembers[i];
            }
        }
        address[] memory finalVoters = new address[](voterCount);
        for(uint i=0; i<voterCount; i++) {
            finalVoters[i] = voters[i];
        }
        return finalVoters;
    }

    function getArtProposalVoters(uint256 _artProposalId) internal view returns (address[] memory) {
        address[] memory voters = new address[](getMemberCount()); // Max possible voters
        uint256 voterCount = 0;
        ArtProposal storage artProposal = artProposals[_artProposalId];
        address[] memory allMembers = getAllMembers();
         for (uint i = 0; i < allMembers.length; i++) {
            if (artProposal.votes[allMembers[i]]) {
                voters[voterCount++] = allMembers[i];
            }
        }
        address[] memory finalVoters = new address[](voterCount);
        for(uint i=0; i<voterCount; i++) {
            finalVoters[i] = voters[i];
        }
        return finalVoters;
    }

    function getReportVoters(uint256 _reportId) internal view returns (address[] memory) {
        address[] memory voters = new address[](getMemberCount()); // Max possible voters
        uint256 voterCount = 0;
        ArtReport storage report = artReports[_reportId];
        address[] memory allMembers = getAllMembers();
         for (uint i = 0; i < allMembers.length; i++) {
            if (report.votes[allMembers[i]]) {
                voters[voterCount++] = allMembers[i];
            }
        }
        address[] memory finalVoters = new address[](voterCount);
        for(uint i=0; i<voterCount; i++) {
            finalVoters[i] = voters[i];
        }
        return finalVoters;
    }


    /// @notice View function to get the number of pending membership requests.
    /// @return The number of pending membership requests.
    function getPendingMembershipRequestsCount() external view returns (uint256) {
        return membershipRequestQueue.length;
    }

    /// @notice Admin function to change the contract admin.
    /// @param _newAdmin The address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Admin address cannot be zero address.");
        admin = _newAdmin;
    }

    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```