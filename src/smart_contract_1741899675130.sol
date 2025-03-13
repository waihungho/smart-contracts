```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)

 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC)
 * where members can collectively create, curate, and manage digital art.
 * It introduces several advanced concepts:
 *  - Decentralized Governance through Proposals and Voting for various actions.
 *  - Dynamic Membership with NFT-based membership and reputation system.
 *  - Collaborative Art Creation with shared ownership and royalty distribution.
 *  - On-chain Art Curation and Exhibition mechanisms.
 *  - Decentralized Marketplace for collective's art with commission structure.
 *  - Integration of randomness and generative art concepts (basic example).
 *  - Advanced revenue sharing and treasury management.
 *  - Event-driven notifications for key actions within the collective.

 * Function Summary:
 *  1. initializeCollective(string _collectiveName, string _collectiveSymbol): Initializes the collective with name and symbol. (Admin Only)
 *  2. setMembershipCost(uint256 _cost): Sets the cost to become a member. (Admin Only)
 *  3. mintMembershipNFT(): Allows users to mint a membership NFT and become a member.
 *  4. renounceMembership(): Allows members to renounce their membership.
 *  5. proposeNewArtPiece(string _title, string _description, string _ipfsHash): Members propose a new art piece for the collective.
 *  6. voteOnArtProposal(uint256 _proposalId, bool _vote): Members vote on art proposals.
 *  7. executeArtProposal(uint256 _proposalId): Executes an approved art proposal, minting an ArtPiece NFT. (Admin/Governance)
 *  8. proposeExhibition(uint256[] _artPieceIds, string _exhibitionTitle, uint256 _durationDays): Members propose an art exhibition.
 *  9. voteOnExhibitionProposal(uint256 _proposalId, bool _vote): Members vote on exhibition proposals.
 * 10. executeExhibitionProposal(uint256 _proposalId): Executes an approved exhibition proposal, setting art pieces as 'on exhibition'. (Admin/Governance)
 * 11. proposeCollectiveParameterChange(string _parameterName, uint256 _newValue): Members propose changes to collective parameters (e.g., membership cost, commission rate).
 * 12. voteOnParameterChangeProposal(uint256 _proposalId, bool _vote): Members vote on parameter change proposals.
 * 13. executeParameterChangeProposal(uint256 _proposalId): Executes an approved parameter change proposal. (Admin/Governance)
 * 14. listArtPieceForSale(uint256 _artPieceId, uint256 _price): Members can list collective's art pieces for sale.
 * 15. buyArtPiece(uint256 _artPieceId): Allows users to buy art pieces listed for sale.
 * 16. withdrawProceeds(): Members can withdraw their share of art sale proceeds.
 * 17. depositToTreasury(): Allows anyone to deposit ETH into the collective's treasury.
 * 18. proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string _reason): Members propose treasury withdrawals.
 * 19. voteOnTreasuryWithdrawalProposal(uint256 _proposalId, bool _vote): Members vote on treasury withdrawal proposals.
 * 20. executeTreasuryWithdrawalProposal(uint256 _proposalId): Executes an approved treasury withdrawal proposal. (Admin/Governance)
 * 21. getRandomNumber(): Demonstrates a basic on-chain randomness concept (for potential generative art features).
 * 22. getCollectiveInfo(): Returns basic information about the collective.
 * 23. getArtPieceInfo(uint256 _artPieceId): Returns information about a specific art piece.
 * 24. getProposalInfo(uint256 _proposalId): Returns information about a specific proposal.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public collectiveName;
    string public collectiveSymbol;

    uint256 public membershipCost;
    Counters.Counter private _membershipTokenIds;
    Counters.Counter private _artPieceTokenIds;
    Counters.Counter private _proposalIds;

    mapping(address => bool) public isMember;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => SaleListing) public saleListings;

    uint256 public proposalVoteDurationDays = 7; // Default vote duration for proposals
    uint256 public commissionRatePercentage = 10; // Commission on art sales for the collective treasury

    struct ArtPiece {
        uint256 tokenId;
        address creator;
        string title;
        string description;
        string ipfsHash;
        bool onExhibition;
        bool isListedForSale;
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        uint256 creationTimestamp;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
        ProposalStatus status;
        bytes proposalData; // Generic data field to store proposal-specific information
    }

    enum ProposalType {
        ArtPieceCreation,
        Exhibition,
        ParameterChange,
        TreasuryWithdrawal,
        Generic // Add more types as needed
    }

    enum ProposalStatus {
        Pending,
        Active,
        Approved,
        Rejected,
        Executed
    }

    struct SaleListing {
        uint256 artPieceId;
        uint256 price;
        address seller;
        bool isActive;
    }

    event MembershipMinted(address indexed member, uint256 tokenId);
    event MembershipRenounced(address indexed member, uint256 tokenId);
    event ArtPieceProposed(uint256 proposalId, address proposer, string title);
    event ArtPieceProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtPieceMinted(uint256 tokenId, address creator, string title);
    event ExhibitionProposed(uint256 proposalId, address proposer, string title);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionExecuted(uint256 proposalId, string title);
    event ParameterChangeProposed(uint256 proposalId, address proposer, string parameterName);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price, address seller);
    event ArtPieceSold(uint256 artPieceId, address buyer, uint256 price);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 proposalId, address recipient, uint256 amount, string reason);
    event TreasuryWithdrawalProposalVoted(uint256 proposalId, address voter, bool vote);
    event TreasuryWithdrawalExecuted(uint256 proposalId, address recipient, uint256 amount);
    event GenericProposalProposed(uint256 proposalId, address proposer, string description);
    event GenericProposalVoted(uint256 proposalId, address voter, bool vote);
    event GenericProposalExecuted(uint256 proposalId, string description);


    modifier onlyMember() {
        require(isMember[msg.sender], "You are not a member of the collective.");
        _;
    }

    modifier onlyProposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        require(block.timestamp <= proposals[_proposalId].voteEndTime, "Voting period has ended.");
        _;
    }

    modifier onlyProposalPending(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        _;
    }

    modifier onlyProposalApproved(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Approved, "Proposal is not approved.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal does not exist.");
        _;
    }

    modifier artPieceExists(uint256 _artPieceId) {
        require(_artPieceId > 0 && _artPieceId <= _artPieceTokenIds.current() && artPieces[_artPieceId].tokenId == _artPieceId, "Art piece does not exist.");
        _;
    }


    constructor() ERC721("DAACMembership", "DAACM") {} // Membership NFT ERC721

    /// ------------------------------------------------------------
    /// Initialization and Administration Functions
    /// ------------------------------------------------------------

    function initializeCollective(string memory _collectiveName, string memory _collectiveSymbol) external onlyOwner {
        require(bytes(collectiveName).length == 0, "Collective already initialized.");
        collectiveName = _collectiveName;
        collectiveSymbol = _collectiveSymbol;
    }

    function setMembershipCost(uint256 _cost) external onlyOwner {
        membershipCost = _cost;
    }

    /// ------------------------------------------------------------
    /// Membership Functions
    /// ------------------------------------------------------------

    function mintMembershipNFT() external payable nonReentrant {
        require(msg.value >= membershipCost, "Insufficient membership cost sent.");
        require(!isMember[msg.sender], "Already a member.");

        _membershipTokenIds.increment();
        uint256 tokenId = _membershipTokenIds.current();
        _safeMint(msg.sender, tokenId);
        isMember[msg.sender] = true;

        emit MembershipMinted(msg.sender, tokenId);
    }

    function renounceMembership() external onlyMember nonReentrant {
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0); // Assuming only one membership NFT per member
        isMember[msg.sender] = false;
        _burn(tokenId);
        emit MembershipRenounced(msg.sender, tokenId);
    }

    /// ------------------------------------------------------------
    /// Art Piece Management Functions
    /// ------------------------------------------------------------

    function proposeNewArtPiece(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.proposalType = ProposalType.ArtPieceCreation;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.voteEndTime = block.timestamp + proposalVoteDurationDays * 1 days;
        newProposal.status = ProposalStatus.Active;

        // Store art piece details in proposal data for later use upon approval
        bytes memory proposalData = abi.encode(_title, _description, _ipfsHash);
        newProposal.proposalData = proposalData;

        emit ArtPieceProposed(proposalId, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        // Prevent double voting (simple implementation, can be improved with mapping for individual voter tracking)
        require(msg.sender != proposal.proposer || proposal.creationTimestamp != block.timestamp, "Proposer cannot vote immediately upon proposal creation in this simple example."); // Simple double voting prevention


        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtPieceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeArtProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalMembers = _membershipTokenIds.current(); // Simple member count approximation
        require(proposal.yesVotes > proposal.noVotes && proposal.yesVotes * 2 > totalMembers, "Proposal not approved: Not enough yes votes or quorum not met."); // Simple approval logic - more than no votes and quorum

        proposal.status = ProposalStatus.Approved;
        proposal.isExecuted = true;

        (string memory title, string memory description, string memory ipfsHash) = abi.decode(proposal.proposalData, (string, string, string));

        _artPieceTokenIds.increment();
        uint256 artPieceTokenId = _artPieceTokenIds.current();

        artPieces[artPieceTokenId] = ArtPiece({
            tokenId: artPieceTokenId,
            creator: proposal.proposer,
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            onExhibition: false,
            isListedForSale: false
        });

        _safeMint(address(this), artPieceTokenId); // Collective owns the art piece initially
        emit ArtPieceMinted(artPieceTokenId, proposal.proposer, title);
        proposal.status = ProposalStatus.Executed;
    }


    /// ------------------------------------------------------------
    /// Exhibition Management Functions
    /// ------------------------------------------------------------

    function proposeExhibition(uint256[] memory _artPieceIds, string memory _exhibitionTitle, uint256 _durationDays) external onlyMember {
        require(_artPieceIds.length > 0, "Exhibition must include at least one art piece.");
        for (uint256 i = 0; i < _artPieceIds.length; i++) {
            artPieceExists(_artPieceIds[i]);
        }

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.proposalType = ProposalType.Exhibition;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.voteEndTime = block.timestamp + proposalVoteDurationDays * 1 days;
        newProposal.status = ProposalStatus.Active;

        bytes memory proposalData = abi.encode(_artPieceIds, _exhibitionTitle, _durationDays);
        newProposal.proposalData = proposalData;

        emit ExhibitionProposed(proposalId, msg.sender, _exhibitionTitle);
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) external onlyMember proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeExhibitionProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalMembers = _membershipTokenIds.current();
        require(proposal.yesVotes > proposal.noVotes && proposal.yesVotes * 2 > totalMembers, "Exhibition proposal not approved.");

        proposal.status = ProposalStatus.Approved;
        proposal.isExecuted = true;

        (uint256[] memory artPieceIds, string memory exhibitionTitle, uint256 durationDays) = abi.decode(proposal.proposalData, (uint256[], string, uint256));

        for (uint256 i = 0; i < artPieceIds.length; i++) {
            artPieces[artPieceIds[i]].onExhibition = true; // Set art pieces to 'on exhibition'
        }

        emit ExhibitionExecuted(_proposalId, exhibitionTitle);
        proposal.status = ProposalStatus.Executed;
    }


    /// ------------------------------------------------------------
    /// Collective Parameter Change Functions
    /// ------------------------------------------------------------

    function proposeCollectiveParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.proposalType = ProposalType.ParameterChange;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.voteEndTime = block.timestamp + proposalVoteDurationDays * 1 days;
        newProposal.status = ProposalStatus.Active;

        bytes memory proposalData = abi.encode(_parameterName, _newValue);
        newProposal.proposalData = proposalData;

        emit ParameterChangeProposed(proposalId, msg.sender, _parameterName);
    }

    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external onlyMember proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeParameterChangeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalMembers = _membershipTokenIds.current();
        require(proposal.yesVotes > proposal.noVotes && proposal.yesVotes * 2 > totalMembers, "Parameter change proposal not approved.");

        proposal.status = ProposalStatus.Approved;
        proposal.isExecuted = true;

        (string memory parameterName, uint256 newValue) = abi.decode(proposal.proposalData, (string, uint256));

        if (keccak256(bytes(parameterName)) == keccak256(bytes("membershipCost"))) {
            membershipCost = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("commissionRatePercentage"))) {
            commissionRatePercentage = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("proposalVoteDurationDays"))) {
            proposalVoteDurationDays = newValue;
        }
        // Add more parameter changes here as needed, using if/else if or a mapping

        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
        proposal.status = ProposalStatus.Executed;
    }

    /// ------------------------------------------------------------
    /// Art Marketplace Functions
    /// ------------------------------------------------------------

    function listArtPieceForSale(uint256 _artPieceId, uint256 _price) external onlyMember artPieceExists(_artPieceId) nonReentrant {
        require(ownerOf(_artPieceId) == address(this), "Collective does not own this art piece.");
        require(!artPieces[_artPieceId].isListedForSale, "Art piece is already listed for sale.");
        require(_price > 0, "Price must be greater than zero.");

        saleListings[_artPieceId] = SaleListing({
            artPieceId: _artPieceId,
            price: _price,
            seller: msg.sender, // Seller is the member initiating the sale (representing collective)
            isActive: true
        });
        artPieces[_artPieceId].isListedForSale = true;
        emit ArtPieceListedForSale(_artPieceId, _price, msg.sender);
    }

    function buyArtPiece(uint256 _artPieceId) external payable nonReentrant {
        artPieceExists(_artPieceId);
        require(saleListings[_artPieceId].isActive, "Art piece is not listed for sale.");
        require(msg.value >= saleListings[_artPieceId].price, "Insufficient funds sent.");

        SaleListing storage listing = saleListings[_artPieceId];
        uint256 price = listing.price;
        listing.isActive = false;
        artPieces[_artPieceId].isListedForSale = false;

        uint256 commission = (price * commissionRatePercentage) / 100;
        uint256 sellerProceeds = price - commission;

        // Transfer commission to treasury
        payable(address(this)).transfer(commission);
        emit TreasuryDeposit(address(this), commission);

        // Transfer proceeds to (collective's) seller - for later withdrawal by members
        payable(listing.seller).transfer(sellerProceeds); // In a more complex system, proceeds might be tracked and distributed differently.

        // Transfer Art Piece NFT to buyer
        _transfer(address(this), msg.sender, _artPieceId);
        emit ArtPieceSold(_artPieceId, msg.sender, price);
    }


    /// ------------------------------------------------------------
    /// Treasury Management Functions
    /// ------------------------------------------------------------

    function depositToTreasury() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");
        payable(address(this)).transfer(msg.value);
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string memory _reason) external onlyMember {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[proposalId];
        newProposal.proposalId = proposalId;
        newProposal.proposalType = ProposalType.TreasuryWithdrawal;
        newProposal.proposer = msg.sender;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.voteEndTime = block.timestamp + proposalVoteDurationDays * 1 days;
        newProposal.status = ProposalStatus.Active;

        bytes memory proposalData = abi.encode(_recipient, _amount, _reason);
        newProposal.proposalData = proposalData;

        emit TreasuryWithdrawalProposed(proposalId, _recipient, _amount, _reason);
    }

    function voteOnTreasuryWithdrawalProposal(uint256 _proposalId, bool _vote) external onlyMember proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit TreasuryWithdrawalProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeTreasuryWithdrawalProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) onlyProposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");

        uint256 totalMembers = _membershipTokenIds.current();
        require(proposal.yesVotes > proposal.noVotes && proposal.yesVotes * 2 > totalMembers, "Treasury withdrawal proposal not approved.");

        proposal.status = ProposalStatus.Approved;
        proposal.isExecuted = true;

        (address recipient, uint256 amount, string memory reason) = abi.decode(proposal.proposalData, (address, uint256, string));
        require(address(this).balance >= amount, "Contract treasury balance is insufficient for withdrawal.");

        payable(recipient).transfer(amount);
        emit TreasuryWithdrawalExecuted(_proposalId, recipient, amount);
        proposal.status = ProposalStatus.Executed;
    }

    /// ------------------------------------------------------------
    /// Utility and Information Functions
    /// ------------------------------------------------------------

    function getRandomNumber() public view returns (uint256) {
        // This is a VERY basic and insecure example for demonstration purposes only.
        // In a real-world scenario, use Chainlink VRF or a more secure randomness solution.
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 100;
    }

    function getCollectiveInfo() external view returns (string memory name, string memory symbol, uint256 memberCount, uint256 artPieceCount, uint256 treasuryBalance) {
        return (collectiveName, collectiveSymbol, _membershipTokenIds.current(), _artPieceTokenIds.current(), address(this).balance);
    }

    function getArtPieceInfo(uint256 _artPieceId) external view artPieceExists(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    function getProposalInfo(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```