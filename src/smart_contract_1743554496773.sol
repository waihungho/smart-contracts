```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to collaborate,
 * curate, exhibit, and monetize digital art in a novel and community-driven way.
 *
 * **Outline and Function Summary:**
 *
 * **1. Collective Membership & Governance:**
 *    - `joinCollective()`: Allows artists to request membership to the collective.
 *    - `leaveCollective()`: Allows members to leave the collective.
 *    - `proposeGovernanceChange(string description, bytes calldata data)`: Allows members to propose changes to the contract's governance parameters.
 *    - `voteOnGovernanceChange(uint256 proposalId, bool vote)`: Allows members to vote on governance change proposals.
 *    - `executeGovernanceChange(uint256 proposalId)`: Executes a governance change proposal if it passes.
 *    - `getCollectiveMembers()`: Returns a list of current collective members.
 *    - `isCollectiveMember(address account)`: Checks if an address is a collective member.
 *
 * **2. Decentralized Art Submission & Curation:**
 *    - `submitArtProposal(string title, string description, string ipfsHash, address[] collaborators)`: Allows members to propose new art pieces for the collective.
 *    - `voteOnArtProposal(uint256 proposalId, bool vote)`: Allows members to vote on art proposals.
 *    - `mintArtNFT(uint256 proposalId)`: Mints an NFT for an approved art proposal, transferring ownership to collaborators based on agreed shares.
 *    - `getArtProposalDetails(uint256 proposalId)`: Returns details of a specific art proposal.
 *    - `getApprovedArtNFTs()`: Returns a list of NFTs approved by the collective.
 *
 * **3. Collaborative Art Creation & Revenue Sharing:**
 *    - `setCollaborationShares(uint256 proposalId, address[] collaborators, uint256[] shares)`:  (Governance function) Sets the revenue sharing percentages for collaborators of an art piece.
 *    - `getCollaborationShares(uint256 tokenId)`: Retrieves the revenue sharing percentages for an NFT.
 *    - `distributeRevenue(uint256 tokenId)`: Distributes revenue generated from an NFT to its collaborators based on their shares.
 *
 * **4. Decentralized Art Exhibition & Display:**
 *    - `proposeExhibition(string title, string description, uint256[] tokenIds)`: Allows members to propose a curated digital art exhibition.
 *    - `voteOnExhibitionProposal(uint256 proposalId, bool vote)`: Allows members to vote on exhibition proposals.
 *    - `startExhibition(uint256 proposalId)`: Starts an approved exhibition, making it publicly viewable (on-chain metadata for exhibition details).
 *    - `getExhibitionDetails(uint256 exhibitionId)`: Retrieves details of a specific exhibition.
 *    - `getActiveExhibitions()`: Returns a list of currently active exhibitions.
 *
 * **5. Collective Treasury & Funding:**
 *    - `donateToCollective()` payable: Allows anyone to donate ETH to the collective treasury.
 *    - `proposeFundingRequest(string description, address recipient, uint256 amount)`: Allows members to propose funding requests from the collective treasury.
 *    - `voteOnFundingRequest(uint256 proposalId, bool vote)`: Allows members to vote on funding requests.
 *    - `executeFundingRequest(uint256 proposalId)`: Executes an approved funding request, sending ETH from the treasury.
 *    - `getCollectiveTreasuryBalance()`: Returns the current balance of the collective treasury.
 *
 * **6. Reputation & Contribution System (Advanced Concept):**
 *    - `recordContribution(address member, string contributionType, string details)`: (Governance function) Records contributions of members to the collective, building a reputation system.
 *    - `getMemberReputation(address member)`: Returns a member's reputation score (simple example: count of recorded contributions).  This could be expanded with more complex reputation metrics.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _artProposalIds;
    Counters.Counter private _exhibitionProposalIds;
    Counters.Counter private _governanceProposalIds;
    Counters.Counter private _fundingProposalIds;
    Counters.Counter private _artNFTIds;

    uint256 public membershipFee = 0.1 ether; // Example membership fee, can be changed via governance
    uint256 public votingDuration = 7 days;     // Example voting duration, can be changed via governance
    uint256 public governanceQuorum = 50;      // Example quorum percentage, can be changed via governance
    uint256 public artApprovalQuorum = 50;    // Example quorum for art approval, can be changed via governance
    uint256 public exhibitionQuorum = 50;     // Example quorum for exhibition approval, can be changed via governance
    uint256 public fundingQuorum = 50;        // Example quorum for funding requests, can be changed via governance

    EnumerableSet.AddressSet private collectiveMembers;
    mapping(address => uint256) public memberReputation; // Simple reputation system

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        address[] collaborators;
        uint256[] votesFor;
        uint256[] votesAgainst;
        bool isActive;
        bool isApproved;
        uint256 tokenId; // NFT ID if approved and minted
    }
    mapping(uint256 => ArtProposal) public artProposals;

    struct CollaborationShares {
        address[] collaborators;
        uint256[] shares; // Percentages out of 100
    }
    mapping(uint256 => CollaborationShares) public nftCollaborationShares; // tokenId => CollaborationShares

    struct ExhibitionProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256[] tokenIds;
        uint256[] votesFor;
        uint256[] votesAgainst;
        bool isActive;
        bool isApproved;
        bool isRunning;
    }
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    uint256[] public activeExhibitions;

    struct GovernanceProposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes data; // Encoded function call data
        uint256[] votesFor;
        uint256[] votesAgainst;
        bool isActive;
        bool isExecuted;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    struct FundingRequest {
        uint256 proposalId;
        address proposer;
        string description;
        address recipient;
        uint256 amount;
        uint256[] votesFor;
        uint256[] votesAgainst;
        bool isActive;
        bool isApproved;
        bool isExecuted;
    }
    mapping(uint256 => FundingRequest) public fundingRequests;


    modifier onlyCollectiveMember() {
        require(collectiveMembers.contains(_msgSender()), "Not a collective member");
        _;
    }

    modifier onlyGovernance() { // For functions only governance can call (owner and members with enough reputation could be considered)
        require(_msgSender() == owner(), "Only governance can call this function"); // Simple governance for now, could be DAO later
        _;
    }

    constructor() ERC721("Decentralized Art Collective NFT", "DAAC-NFT") {}

    // ------------------------------------------------------------------------
    // 1. Collective Membership & Governance
    // ------------------------------------------------------------------------

    function joinCollective() external payable {
        require(msg.value >= membershipFee, "Membership fee required");
        require(!collectiveMembers.contains(_msgSender()), "Already a member");
        collectiveMembers.add(_msgSender());
        payable(owner()).transfer(msg.value); // Send membership fee to contract owner (governance for now)
        emit CollectiveMemberJoined(_msgSender());
    }

    function leaveCollective() external onlyCollectiveMember {
        collectiveMembers.remove(_msgSender());
        emit CollectiveMemberLeft(_msgSender());
    }

    function proposeGovernanceChange(string memory description, bytes calldata data) external onlyCollectiveMember {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            description: description,
            data: data,
            votesFor: new uint256[](0),
            votesAgainst: new uint256[](0),
            isActive: true,
            isExecuted: false
        });
        emit GovernanceProposalCreated(proposalId, _msgSender(), description);
    }

    function voteOnGovernanceChange(uint256 proposalId, bool vote) external onlyCollectiveMember {
        require(governanceProposals[proposalId].isActive, "Proposal is not active");
        require(!hasVotedOnGovernance(proposalId, _msgSender()), "Already voted");

        if (vote) {
            governanceProposals[proposalId].votesFor.push(block.timestamp);
        } else {
            governanceProposals[proposalId].votesAgainst.push(block.timestamp);
        }
        emit GovernanceVoteCast(proposalId, _msgSender(), vote);

        if (isGovernanceProposalPassed(proposalId)) {
            governanceProposals[proposalId].isActive = false;
            emit GovernanceProposalPassed(proposalId);
        }
    }

    function executeGovernanceChange(uint256 proposalId) external onlyGovernance { // For simplicity, only owner can execute, could be time-locked or multi-sig
        require(!governanceProposals[proposalId].isExecuted, "Proposal already executed");
        require(!governanceProposals[proposalId].isActive, "Proposal is still active or not passed");
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        (bool success, ) = address(this).call(proposal.data);
        require(success, "Governance change execution failed");
        proposal.isExecuted = true;
        emit GovernanceProposalExecuted(proposalId);
    }

    function getCollectiveMembers() external view returns (address[] memory) {
        return collectiveMembers.values();
    }

    function isCollectiveMember(address account) external view returns (bool) {
        return collectiveMembers.contains(account);
    }

    // ------------------------------------------------------------------------
    // 2. Decentralized Art Submission & Curation
    // ------------------------------------------------------------------------

    function submitArtProposal(string memory title, string memory description, string memory ipfsHash, address[] memory collaborators) external onlyCollectiveMember {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            collaborators: collaborators,
            votesFor: new uint256[](0),
            votesAgainst: new uint256[](0),
            isActive: true,
            isApproved: false,
            tokenId: 0
        });
        emit ArtProposalCreated(proposalId, _msgSender(), title);
    }

    function voteOnArtProposal(uint256 proposalId, bool vote) external onlyCollectiveMember {
        require(artProposals[proposalId].isActive, "Proposal is not active");
        require(!hasVotedOnArt(proposalId, _msgSender()), "Already voted");

        if (vote) {
            artProposals[proposalId].votesFor.push(block.timestamp);
        } else {
            artProposals[proposalId].votesAgainst.push(block.timestamp);
        }
        emit ArtVoteCast(proposalId, _msgSender(), vote);

        if (isArtProposalApproved(proposalId)) {
            artProposals[proposalId].isApproved = true;
            artProposals[proposalId].isActive = false;
            emit ArtProposalApproved(proposalId);
        }
    }

    function mintArtNFT(uint256 proposalId) external onlyGovernance { // Governance mints after approval
        require(artProposals[proposalId].isApproved, "Art proposal not approved");
        require(artProposals[proposalId].tokenId == 0, "NFT already minted for this proposal");

        _artNFTIds.increment();
        uint256 tokenId = _artNFTIds.current();
        ArtProposal storage proposal = artProposals[proposalId];
        proposal.tokenId = tokenId;

        _mint(address(this), tokenId); // Mint to contract, ownership will be managed by the collective/collaborators
        emit ArtNFTMinted(tokenId, proposalId, proposal.title);
    }

    function getArtProposalDetails(uint256 proposalId) external view returns (ArtProposal memory) {
        return artProposals[proposalId];
    }

    function getApprovedArtNFTs() external view returns (uint256[] memory) {
        uint256[] memory approvedTokenIds = new uint256[](_artNFTIds.current()); // Max size, might have empty slots
        uint256 count = 0;
        for (uint256 i = 1; i <= _artNFTIds.current(); i++) {
            for (uint256 j = 1; j <= _artProposalIds.current(); j++) {
                if (artProposals[j].tokenId == i && artProposals[j].isApproved) { // Find the proposal that minted this token and check if approved
                    approvedTokenIds[count] = i;
                    count++;
                    break; // Move to next tokenId after finding a match
                }
            }
        }
        // Resize array to actual count of approved NFTs
        uint256[] memory resizedApprovedTokenIds = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            resizedApprovedTokenIds[i] = approvedTokenIds[i];
        }
        return resizedApprovedTokenIds;
    }

    // ------------------------------------------------------------------------
    // 3. Collaborative Art Creation & Revenue Sharing
    // ------------------------------------------------------------------------

    function setCollaborationShares(uint256 proposalId, address[] memory collaborators, uint256[] memory shares) external onlyGovernance {
        require(artProposals[proposalId].isApproved, "Art proposal not approved");
        require(collaborators.length == shares.length, "Collaborators and shares length mismatch");
        uint256 totalShares = 0;
        for (uint256 share in shares) {
            totalShares += share;
        }
        require(totalShares == 100, "Total shares must equal 100%");

        nftCollaborationShares[artProposals[proposalId].tokenId] = CollaborationShares({
            collaborators: collaborators,
            shares: shares
        });
        emit CollaborationSharesSet(artProposals[proposalId].tokenId, collaborators, shares);
    }

    function getCollaborationShares(uint256 tokenId) external view returns (CollaborationShares memory) {
        return nftCollaborationShares[tokenId];
    }

    function distributeRevenue(uint256 tokenId) external payable onlyGovernance { // Governance distributes revenue, could be automated with oracles or triggers later
        CollaborationShares memory shares = nftCollaborationShares[tokenId];
        require(shares.collaborators.length > 0, "No collaboration shares set for this NFT");
        uint256 totalRevenue = msg.value;

        for (uint256 i = 0; i < shares.collaborators.length; i++) {
            uint256 shareAmount = (totalRevenue * shares.shares[i]) / 100;
            payable(shares.collaborators[i]).transfer(shareAmount);
            emit RevenueDistributed(tokenId, shares.collaborators[i], shareAmount);
        }
        uint256 remainingRevenue = totalRevenue;
        for (uint256 i = 0; i < shares.collaborators.length; i++) {
            remainingRevenue -= (totalRevenue * shares.shares[i]) / 100;
        }
        if(remainingRevenue > 0) {
            payable(owner()).transfer(remainingRevenue); // Send any remainder to governance/owner
        }
    }

    // ------------------------------------------------------------------------
    // 4. Decentralized Art Exhibition & Display
    // ------------------------------------------------------------------------

    function proposeExhibition(string memory title, string memory description, uint256[] memory tokenIds) external onlyCollectiveMember {
        require(tokenIds.length > 0, "Exhibition must include at least one NFT");
        for(uint256 tokenId in tokenIds) {
            require(ownerOf(tokenId) == address(this), "All NFTs in exhibition must be owned by the collective");
        }

        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            proposer: _msgSender(),
            title: title,
            description: description,
            tokenIds: tokenIds,
            votesFor: new uint256[](0),
            votesAgainst: new uint256[](0),
            isActive: true,
            isApproved: false,
            isRunning: false
        });
        emit ExhibitionProposalCreated(proposalId, _msgSender(), title);
    }

    function voteOnExhibitionProposal(uint256 proposalId, bool vote) external onlyCollectiveMember {
        require(exhibitionProposals[proposalId].isActive, "Proposal is not active");
        require(!hasVotedOnExhibition(proposalId, _msgSender()), "Already voted");

        if (vote) {
            exhibitionProposals[proposalId].votesFor.push(block.timestamp);
        } else {
            exhibitionProposals[proposalId].votesAgainst.push(block.timestamp);
        }
        emit ExhibitionVoteCast(proposalId, _msgSender(), vote);

        if (isExhibitionProposalApproved(proposalId)) {
            exhibitionProposals[proposalId].isApproved = true;
            exhibitionProposals[proposalId].isActive = false;
            emit ExhibitionProposalApproved(proposalId);
        }
    }

    function startExhibition(uint256 proposalId) external onlyGovernance { // Governance starts exhibition after approval
        require(exhibitionProposals[proposalId].isApproved, "Exhibition proposal not approved");
        require(!exhibitionProposals[proposalId].isRunning, "Exhibition already running");

        exhibitionProposals[proposalId].isRunning = true;
        activeExhibitions.push(proposalId);
        emit ExhibitionStarted(proposalId);
    }

    function getExhibitionDetails(uint256 exhibitionId) external view returns (ExhibitionProposal memory) {
        return exhibitionProposals[exhibitionId];
    }

    function getActiveExhibitions() external view returns (uint256[] memory) {
        return activeExhibitions;
    }

    // ------------------------------------------------------------------------
    // 5. Collective Treasury & Funding
    // ------------------------------------------------------------------------

    function donateToCollective() external payable {
        emit DonationReceived(_msgSender(), msg.value);
    }

    function proposeFundingRequest(string memory description, address recipient, uint256 amount) external onlyCollectiveMember {
        require(amount > 0, "Funding amount must be greater than zero");
        _fundingProposalIds.increment();
        uint256 proposalId = _fundingProposalIds.current();
        fundingRequests[proposalId] = FundingRequest({
            proposalId: proposalId,
            proposer: _msgSender(),
            description: description,
            recipient: recipient,
            amount: amount,
            votesFor: new uint256[](0),
            votesAgainst: new uint256[](0),
            isActive: true,
            isApproved: false,
            isExecuted: false
        });
        emit FundingRequestCreated(proposalId, _msgSender(), description, recipient, amount);
    }

    function voteOnFundingRequest(uint256 proposalId, bool vote) external onlyCollectiveMember {
        require(fundingRequests[proposalId].isActive, "Funding request is not active");
        require(!hasVotedOnFunding(proposalId, _msgSender()), "Already voted");

        if (vote) {
            fundingRequests[proposalId].votesFor.push(block.timestamp);
        } else {
            fundingRequests[proposalId].votesAgainst.push(block.timestamp);
        }
        emit FundingVoteCast(proposalId, _msgSender(), vote);

        if (isFundingRequestApproved(proposalId)) {
            fundingRequests[proposalId].isApproved = true;
            fundingRequests[proposalId].isActive = false;
            emit FundingRequestApproved(proposalId);
        }
    }

    function executeFundingRequest(uint256 proposalId) external onlyGovernance { // Governance executes funding after approval
        require(fundingRequests[proposalId].isApproved, "Funding request not approved");
        require(!fundingRequests[proposalId].isExecuted, "Funding request already executed");
        require(address(this).balance >= fundingRequests[proposalId].amount, "Insufficient treasury balance");

        FundingRequest storage request = fundingRequests[proposalId];
        (bool success, ) = request.recipient.call{value: request.amount}("");
        require(success, "Funding transfer failed");
        request.isExecuted = true;
        emit FundingRequestExecuted(proposalId, request.recipient, request.amount);
    }

    function getCollectiveTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ------------------------------------------------------------------------
    // 6. Reputation & Contribution System (Advanced Concept)
    // ------------------------------------------------------------------------

    function recordContribution(address member, string memory contributionType, string memory details) external onlyGovernance { // Governance records contributions
        require(collectiveMembers.contains(member), "Recipient is not a collective member");
        memberReputation[member]++; // Simple increment, can be expanded to different contribution types and weights
        emit ContributionRecorded(member, contributionType, details);
    }

    function getMemberReputation(address member) external view returns (uint256) {
        return memberReputation[member];
    }

    // ------------------------------------------------------------------------
    // Internal Helper Functions
    // ------------------------------------------------------------------------

    function hasVotedOnGovernance(uint256 proposalId, address voter) internal view returns (bool) {
        for (uint256 i = 0; i < governanceProposals[proposalId].votesFor.length; i++) {
            if (governanceProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        for (uint256 i = 0; i < governanceProposals[proposalId].votesAgainst.length; i++) {
             if (governanceProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        return false;
    }

    function isGovernanceProposalPassed(uint256 proposalId) internal view returns (bool) {
        uint256 totalMembers = collectiveMembers.length();
        if (totalMembers == 0) return false; // Avoid division by zero
        uint256 votesForCount = governanceProposals[proposalId].votesFor.length;
        return (votesForCount * 100) / totalMembers >= governanceQuorum;
    }

    function hasVotedOnArt(uint256 proposalId, address voter) internal view returns (bool) {
         for (uint256 i = 0; i < artProposals[proposalId].votesFor.length; i++) {
            if (artProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        for (uint256 i = 0; i < artProposals[proposalId].votesAgainst.length; i++) {
             if (artProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        return false;
    }

    function isArtProposalApproved(uint256 proposalId) internal view returns (bool) {
        uint256 totalMembers = collectiveMembers.length();
        if (totalMembers == 0) return false;
        uint256 votesForCount = artProposals[proposalId].votesFor.length;
        return (votesForCount * 100) / totalMembers >= artApprovalQuorum;
    }

    function hasVotedOnExhibition(uint256 proposalId, address voter) internal view returns (bool) {
         for (uint256 i = 0; i < exhibitionProposals[proposalId].votesFor.length; i++) {
            if (exhibitionProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        for (uint256 i = 0; i < exhibitionProposals[proposalId].votesAgainst.length; i++) {
             if (exhibitionProposals[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        return false;
    }

    function isExhibitionProposalApproved(uint256 proposalId) internal view returns (bool) {
        uint256 totalMembers = collectiveMembers.length();
        if (totalMembers == 0) return false;
        uint256 votesForCount = exhibitionProposals[proposalId].votesFor.length;
        return (votesForCount * 100) / totalMembers >= exhibitionQuorum;
    }

    function hasVotedOnFunding(uint256 proposalId, address voter) internal view returns (bool) {
         for (uint256 i = 0; i < fundingRequests[proposalId].votesFor.length; i++) {
            if (fundingRequests[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        for (uint256 i = 0; i < fundingRequests[proposalId].votesAgainst.length; i++) {
             if (fundingRequests[proposalId].proposer == voter) return true; // For simplicity, in real implementation, track voters addresses, not timestamps
        }
        return false;
    }

    function isFundingRequestApproved(uint256 proposalId) internal view returns (bool) {
        uint256 totalMembers = collectiveMembers.length();
        if (totalMembers == 0) return false;
        uint256 votesForCount = fundingRequests[proposalId].votesFor.length;
        return (votesForCount * 100) / totalMembers >= fundingQuorum;
    }


    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    event CollectiveMemberJoined(address member);
    event CollectiveMemberLeft(address member);

    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalPassed(uint256 proposalId);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ArtProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, string title);

    event CollaborationSharesSet(uint256 tokenId, address[] collaborators, uint256[] shares);
    event RevenueDistributed(uint256 tokenId, address recipient, uint256 amount);

    event ExhibitionProposalCreated(uint256 proposalId, address proposer, string title);
    event ExhibitionVoteCast(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalApproved(uint256 proposalId);
    event ExhibitionStarted(uint256 proposalId);

    event DonationReceived(address donor, uint256 amount);
    event FundingRequestCreated(uint256 proposalId, address proposer, string description, address recipient, uint256 amount);
    event FundingVoteCast(uint256 proposalId, address voter, bool vote);
    event FundingRequestApproved(uint256 proposalId);
    event FundingRequestExecuted(uint256 proposalId, address recipient, uint256 amount);

    event ContributionRecorded(address member, string contributionType, string details);
}
```