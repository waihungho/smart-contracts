```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *
 * Outline and Function Summary:
 *
 * 1.  **Initialization and Configuration:**
 *     - `constructor(string _collectiveName, uint256 _proposalVoteDuration, uint256 _membershipFee)`: Initializes the DAAC with a name, proposal vote duration, and membership fee.
 *     - `setProposalVoteDuration(uint256 _duration)`: Allows the DAO to change the proposal vote duration through governance.
 *     - `setMembershipFee(uint256 _fee)`: Allows the DAO to change the membership fee through governance.
 *     - `setPlatformFeePercentage(uint256 _percentage)`: Allows the DAO to set the platform fee percentage for art sales.
 *
 * 2.  **Membership Management:**
 *     - `joinCollective()`: Allows artists to join the collective by paying the membership fee.
 *     - `leaveCollective()`: Allows members to leave the collective.
 *     - `kickMember(address _member)`: Allows the DAO to kick a member through governance.
 *     - `isMember(address _account)`: Checks if an address is a member of the collective.
 *     - `getMemberCount()`: Returns the current number of members.
 *
 * 3.  **Artwork Proposal and Creation:**
 *     - `proposeArtworkIdea(string memory _title, string memory _description, string memory _ipfsHash)`: Members propose new artwork ideas with title, description, and IPFS hash.
 *     - `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Members vote on artwork proposals.
 *     - `executeArtworkProposal(uint256 _proposalId)`: Executes an approved artwork proposal, minting an NFT for the artwork.
 *     - `getArtworkProposalDetails(uint256 _proposalId)`: Retrieves details of a specific artwork proposal.
 *     - `getArtworkCount()`: Returns the total number of artworks created by the collective.
 *     - `getArtworkById(uint256 _artworkId)`: Retrieves details of a specific artwork.
 *
 * 4.  **Curation and Exhibition:**
 *     - `proposeCuration(uint256 _artworkId)`: Members propose artworks for official curation and exhibition.
 *     - `voteOnCurationProposal(uint256 _curationProposalId, bool _vote)`: Members vote on curation proposals.
 *     - `executeCurationProposal(uint256 _curationProposalId)`: Executes an approved curation proposal, marking the artwork as curated.
 *     - `getCurationProposalDetails(uint256 _curationProposalId)`: Retrieves details of a specific curation proposal.
 *     - `getCurtatedArtworks()`: Returns a list of IDs of curated artworks.
 *
 * 5.  **Marketplace and Sales:**
 *     - `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Members can list their collective artworks for sale.
 *     - `purchaseArtwork(uint256 _artworkId)`: Allows anyone to purchase an artwork listed for sale.
 *     - `withdrawArtworkSaleProceeds(uint256 _artworkId)`: Allows the artist who created the artwork to withdraw their share of the sale proceeds.
 *
 * 6.  **DAO Governance and Treasury:**
 *     - `proposeTreasuryWithdrawal(address payable _recipient, uint256 _amount, string memory _reason)`: Members propose treasury withdrawals for collective purposes.
 *     - `voteOnTreasuryWithdrawalProposal(uint256 _proposalId, bool _vote)`: Members vote on treasury withdrawal proposals.
 *     - `executeTreasuryWithdrawalProposal(uint256 _proposalId)`: Executes an approved treasury withdrawal proposal.
 *     - `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *     - `getPayoutForArtwork(uint256 _artworkId)`: Calculates and returns the payout amount for an artwork sale after platform fees.
 *
 * 7.  **Reputation and Contribution (Advanced - Conceptual):**
 *     - `recordContribution(address _member, string memory _activity)`: (Conceptual - Could be extended with voting or more complex logic) - Allows recording member contributions for potential future reputation systems.
 *     - `getMemberContributionCount(address _member)`: (Conceptual) - Returns the contribution count of a member.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public collectiveName;
    uint256 public proposalVoteDuration; // In blocks
    uint256 public membershipFee;
    uint256 public platformFeePercentage; // Percentage of sale price to DAO treasury

    Counters.Counter private _artworkProposalIds;
    Counters.Counter private _curationProposalIds;
    Counters.Counter private _artworkIds;
    Counters.Counter private _treasuryWithdrawalProposalIds;

    struct ArtworkProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    struct CurationProposal {
        uint256 id;
        address proposer;
        uint256 artworkId;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address creator;
        bool curated;
        bool forSale;
        uint256 salePrice;
        bool saleProceedsWithdrawn;
    }

    struct TreasuryWithdrawalProposal {
        uint256 id;
        address proposer;
        address payable recipient;
        uint256 amount;
        string reason;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(uint256 => CurationProposal) public curationProposals;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => TreasuryWithdrawalProposal) public treasuryWithdrawalProposals;
    mapping(address => bool) public isCollectiveMember;
    mapping(address => uint256) public memberContributionCount; // Conceptual reputation tracking

    address payable public treasury;

    event MembershipJoined(address member);
    event MembershipLeft(address member);
    event MemberKicked(address member, address initiator);
    event ArtworkProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkProposalExecuted(uint256 proposalId, uint256 artworkId);
    event CurationProposalCreated(uint256 proposalId, address proposer, uint256 artworkId);
    event CurationProposalVoted(uint256 proposalId, address voter, bool vote);
    event CurationProposalExecuted(uint256 proposalId, uint256 artworkId);
    event ArtworkListedForSale(uint256 artworkId, uint256 price);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event SaleProceedsWithdrawn(uint256 artworkId, address artist, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 proposalId, address proposer, address payable recipient, uint256 amount, string reason);
    event TreasuryWithdrawalVoted(uint256 proposalId, address voter, bool vote);
    event TreasuryWithdrawalExecuted(uint256 proposalId, address payable recipient, uint256 amount);
    event PlatformFeePercentageSet(uint256 percentage, address initiator);
    event ProposalVoteDurationSet(uint256 duration, address initiator);
    event MembershipFeeSet(uint256 fee, address initiator);
    event ContributionRecorded(address member, string activity);


    modifier onlyCollectiveMember() {
        require(isCollectiveMember[msg.sender], "Not a collective member");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(block.number <= getProposal(proposalType(_proposalId), _proposalId).voteEndTime && !getProposal(proposalType(_proposalId), _proposalId).executed, "Proposal is not active or already executed");
        _;
    }

    modifier onlyProposalNotExecuted(uint256 _proposalId) {
        require(!getProposal(proposalType(_proposalId), _proposalId).executed, "Proposal already executed");
        _;
    }

    modifier onlyArtworkCreator(uint256 _artworkId) {
        require(artworks[_artworkId].creator == msg.sender, "Only artwork creator can perform this action");
        _;
    }

    modifier onlyArtworkForSale(uint256 _artworkId) {
        require(artworks[_artworkId].forSale, "Artwork is not for sale");
        _;
    }

    modifier onlySaleProceedsNotWithdrawn(uint256 _artworkId) {
        require(!artworks[_artworkId].saleProceedsWithdrawn, "Sale proceeds already withdrawn");
        _;
    }

    constructor(string memory _collectiveName, uint256 _proposalVoteDuration, uint256 _membershipFee) ERC721(_collectiveName, "DACNFT") {
        collectiveName = _collectiveName;
        proposalVoteDuration = _proposalVoteDuration;
        membershipFee = _membershipFee;
        platformFeePercentage = 10; // Default 10% platform fee
        treasury = payable(address(this)); // Treasury is the contract itself initially
    }

    // ---- 1. Initialization and Configuration ----

    function setProposalVoteDuration(uint256 _duration) external onlyOwner {
        proposalVoteDuration = _duration;
        emit ProposalVoteDurationSet(_duration, msg.sender);
    }

    function setMembershipFee(uint256 _fee) external onlyOwner {
        membershipFee = _fee;
        emit MembershipFeeSet(_fee, msg.sender);
    }

    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage, msg.sender);
    }

    // ---- 2. Membership Management ----

    function joinCollective() external payable {
        require(!isCollectiveMember[msg.sender], "Already a member");
        require(msg.value >= membershipFee, "Membership fee required");
        isCollectiveMember[msg.sender] = true;
        emit MembershipJoined(msg.sender);
    }

    function leaveCollective() external onlyCollectiveMember {
        isCollectiveMember[msg.sender] = false;
        emit MembershipLeft(msg.sender);
    }

    function kickMember(address _member) external onlyOwner { // Governance decision - onlyOwner for simplicity, could be DAO vote
        require(isCollectiveMember[_member], "Not a member");
        require(_member != owner(), "Cannot kick the owner"); // Prevent kicking the owner (for simplicity in this example)
        isCollectiveMember[_member] = false;
        emit MemberKicked(_member, msg.sender);
    }

    function isMember(address _account) external view returns (bool) {
        return isCollectiveMember[_account];
    }

    function getMemberCount() external view returns (uint256) {
        uint256 count = 0;
        address currentMember;
        for (uint256 i = 0; i < _artworkProposalIds.current(); i++) { // Inefficient way to count in a real-world scenario, but works for example
            if (artworkProposals[i+1].proposer != address(0) && isCollectiveMember[artworkProposals[i+1].proposer]) { // Just checking proposers as a rough estimate, better tracking needed for accurate count
                count++;
            }
        }
         for (uint256 i = 0; i < _curationProposalIds.current(); i++) {
            if (curationProposals[i+1].proposer != address(0) && isCollectiveMember[curationProposals[i+1].proposer]) {
                count++;
            }
        }
        // In a real application, maintain a separate member list or counter for efficiency.
        return count; // This is a very basic approximation, needs improvement for accuracy
    }


    // ---- 3. Artwork Proposal and Creation ----

    function proposeArtworkIdea(string memory _title, string memory _description, string memory _ipfsHash) external onlyCollectiveMember {
        _artworkProposalIds.increment();
        uint256 proposalId = _artworkProposalIds.current();
        artworkProposals[proposalId] = ArtworkProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            voteEndTime: block.number + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit ArtworkProposalCreated(proposalId, msg.sender, _title);
    }

    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) external onlyCollectiveMember onlyProposalActive(_proposalId) onlyProposalNotExecuted(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist"); // Ensure proposal exists
        require(block.number <= proposal.voteEndTime, "Voting has ended");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtworkProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtworkProposal(uint256 _proposalId) external onlyProposalNotExecuted(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist"); // Ensure proposal exists
        require(block.number > proposal.voteEndTime, "Voting is still active");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not approved"); // Simple majority for approval
        require(!proposal.executed, "Proposal already executed");

        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            creator: proposal.proposer,
            curated: false,
            forSale: false,
            salePrice: 0,
            saleProceedsWithdrawn: false
        });

        _mint(proposal.proposer, artworkId); // Mint NFT to the proposer (creator)
        proposal.executed = true;
        emit ArtworkProposalExecuted(_proposalId, artworkId);
    }

    function getArtworkProposalDetails(uint256 _proposalId) external view returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    function getArtworkCount() external view returns (uint256) {
        return _artworkIds.current();
    }

    function getArtworkById(uint256 _artworkId) external view returns (Artwork memory) {
        return artworks[_artworkId];
    }


    // ---- 4. Curation and Exhibition ----

    function proposeCuration(uint256 _artworkId) external onlyCollectiveMember {
        require(artworks[_artworkId].creator != address(0), "Artwork does not exist"); // Ensure artwork exists
        _curationProposalIds.increment();
        uint256 proposalId = _curationProposalIds.current();
        curationProposals[proposalId] = CurationProposal({
            id: proposalId,
            proposer: msg.sender,
            artworkId: _artworkId,
            voteEndTime: block.number + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit CurationProposalCreated(proposalId, msg.sender, _artworkId);
    }

    function voteOnCurationProposal(uint256 _curationProposalId, bool _vote) external onlyCollectiveMember onlyProposalActive(_curationProposalId) onlyProposalNotExecuted(_curationProposalId) {
        CurationProposal storage proposal = curationProposals[_curationProposalId];
        require(proposal.proposer != address(0), "Curation proposal does not exist"); // Ensure proposal exists
        require(block.number <= proposal.voteEndTime, "Voting has ended");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit CurationProposalVoted(_curationProposalId, msg.sender, _vote);
    }

    function executeCurationProposal(uint256 _curationProposalId) external onlyProposalNotExecuted(_curationProposalId) {
        CurationProposal storage proposal = curationProposals[_curationProposalId];
        require(proposal.proposer != address(0), "Curation proposal does not exist"); // Ensure proposal exists
        require(block.number > proposal.voteEndTime, "Voting is still active");
        require(proposal.yesVotes > proposal.noVotes, "Curation proposal not approved"); // Simple majority for approval
        require(!proposal.executed, "Curation proposal already executed");

        artworks[proposal.artworkId].curated = true;
        proposal.executed = true;
        emit CurationProposalExecuted(_curationProposalId, proposal.artworkId);
    }

    function getCurationProposalDetails(uint256 _curationProposalId) external view returns (CurationProposal memory) {
        return curationProposals[_curationProposalId];
    }

    function getCurtatedArtworks() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            if (artworks[i].curated) {
                count++;
            }
        }
        uint256[] memory curatedArtworkIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _artworkIds.current(); i++) {
            if (artworks[i].curated) {
                curatedArtworkIds[index] = artworks[i].id;
                index++;
            }
        }
        return curatedArtworkIds;
    }


    // ---- 5. Marketplace and Sales ----

    function listArtworkForSale(uint256 _artworkId, uint256 _price) external onlyCollectiveMember onlyArtworkCreator(_artworkId) {
        require(_price > 0, "Price must be greater than zero");
        require(!artworks[_artworkId].forSale, "Artwork already listed for sale");
        artworks[_artworkId].forSale = true;
        artworks[_artworkId].salePrice = _price;
        emit ArtworkListedForSale(_artworkId, _price);
    }

    function purchaseArtwork(uint256 _artworkId) external payable onlyArtworkForSale(_artworkId) {
        require(msg.value >= artworks[_artworkId].salePrice, "Insufficient funds");
        require(ownerOf(_artworkId) == artworks[_artworkId].creator, "Artwork ownership mismatch"); // Double check ownership

        uint256 platformFee = (artworks[_artworkId].salePrice * platformFeePercentage) / 100;
        uint256 artistPayout = artworks[_artworkId].salePrice - platformFee;

        // Transfer platform fee to treasury
        (bool treasuryTransferSuccess, ) = treasury.call{value: platformFee}("");
        require(treasuryTransferSuccess, "Treasury transfer failed");

        // Transfer artist payout to the artwork creator
        (bool artistTransferSuccess, ) = payable(artworks[_artworkId].creator).call{value: artistPayout}("");
        require(artistTransferSuccess, "Artist payout failed");

        artworks[_artworkId].forSale = false;
        _transfer(ownerOf(_artworkId), msg.sender, _artworkId); // Transfer NFT ownership to buyer
        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].salePrice);
    }

    function withdrawArtworkSaleProceeds(uint256 _artworkId) external onlyCollectiveMember onlyArtworkCreator(_artworkId) onlySaleProceedsNotWithdrawn(_artworkId) {
        require(!artworks[_artworkId].forSale, "Artwork is still listed for sale"); // Ensure it's not for sale anymore (already bought)
        require(ownerOf(_artworkId) != artworks[_artworkId].creator, "Artist still owns the artwork"); // Double check artist doesn't own it anymore

        artworks[_artworkId].saleProceedsWithdrawn = true; // Mark as withdrawn (even though payout happens on purchase)
        emit SaleProceedsWithdrawn(_artworkId, msg.sender, getPayoutForArtwork(_artworkId)); // Event emitted for tracking, amount is calculated payout
        // Payout is already handled in purchaseArtwork, this function primarily serves as a confirmation/flag and could be used for more complex payout logic in future
    }


    // ---- 6. DAO Governance and Treasury ----

    function proposeTreasuryWithdrawal(address payable _recipient, uint256 _amount, string memory _reason) external onlyCollectiveMember {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(_amount <= address(this).balance, "Insufficient treasury funds");

        _treasuryWithdrawalProposalIds.increment();
        uint256 proposalId = _treasuryWithdrawalProposalIds.current();
        treasuryWithdrawalProposals[proposalId] = TreasuryWithdrawalProposal({
            id: proposalId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            voteEndTime: block.number + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit TreasuryWithdrawalProposed(proposalId, msg.sender, _recipient, _amount, _reason);
    }

    function voteOnTreasuryWithdrawalProposal(uint256 _proposalId, bool _vote) external onlyCollectiveMember onlyProposalActive(_proposalId) onlyProposalNotExecuted(_proposalId) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.proposer != address(0), "Treasury withdrawal proposal does not exist"); // Ensure proposal exists
        require(block.number <= proposal.voteEndTime, "Voting has ended");

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit TreasuryWithdrawalVoted(_proposalId, msg.sender, _vote);
    }

    function executeTreasuryWithdrawalProposal(uint256 _proposalId) external onlyProposalNotExecuted(_proposalId) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.proposer != address(0), "Treasury withdrawal proposal does not exist"); // Ensure proposal exists
        require(block.number > proposal.voteEndTime, "Voting is still active");
        require(proposal.yesVotes > proposal.noVotes, "Treasury withdrawal proposal not approved"); // Simple majority for approval
        require(!proposal.executed, "Treasury withdrawal proposal already executed");

        (bool transferSuccess, ) = proposal.recipient.call{value: proposal.amount}("");
        require(transferSuccess, "Treasury withdrawal failed");

        proposal.executed = true;
        emit TreasuryWithdrawalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getPayoutForArtwork(uint256 _artworkId) public view returns (uint256) {
        uint256 platformFee = (artworks[_artworkId].salePrice * platformFeePercentage) / 100;
        return artworks[_artworkId].salePrice - platformFee;
    }


    // ---- 7. Reputation and Contribution (Advanced - Conceptual) ----

    function recordContribution(address _member, string memory _activity) external onlyOwner { // For simplicity, onlyOwner can record, in real use DAO vote or automated system
        require(isCollectiveMember[_member], "Not a collective member");
        memberContributionCount[_member]++;
        emit ContributionRecorded(_member, _activity);
    }

    function getMemberContributionCount(address _member) external view returns (uint256) {
        return memberContributionCount[_member];
    }

    // ---- Internal Helper Functions ----

    function getProposal(ProposalType _proposalType, uint256 _proposalId) internal view returns (Proposal memory) {
        if (_proposalType == ProposalType.Artwork) {
            return Proposal(artworkProposals[_proposalId].proposer, artworkProposals[_proposalId].voteEndTime, artworkProposals[_proposalId].yesVotes, artworkProposals[_proposalId].noVotes, artworkProposals[_proposalId].executed);
        } else if (_proposalType == ProposalType.Curation) {
            return Proposal(curationProposals[_proposalId].proposer, curationProposals[_proposalId].voteEndTime, curationProposals[_proposalId].yesVotes, curationProposals[_proposalId].noVotes, curationProposals[_proposalId].executed);
        } else if (_proposalType == ProposalType.TreasuryWithdrawal) {
            return Proposal(treasuryWithdrawalProposals[_proposalId].proposer, treasuryWithdrawalProposals[_proposalId].voteEndTime, treasuryWithdrawalProposals[_proposalId].yesVotes, treasuryWithdrawalProposals[_proposalId].noVotes, treasuryWithdrawalProposals[_proposalId].executed);
        } else {
            revert("Invalid Proposal Type");
        }
    }

    function proposalType(uint256 _proposalId) internal pure returns (ProposalType) {
        if (_proposalId <= _artworkProposalIds.current()) {
            return ProposalType.Artwork;
        } else if (_proposalId <= _artworkProposalIds.current() + _curationProposalIds.current()) {
            return ProposalType.Curation;
        } else {
            return ProposalType.TreasuryWithdrawal;
        }
    }

    enum ProposalType {
        Artwork,
        Curation,
        TreasuryWithdrawal
    }

    struct Proposal {
        address proposer;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
}
```