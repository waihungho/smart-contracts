```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Advanced Smart Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) with advanced features
 * for collaborative art creation, curation, ownership, and management using blockchain technology.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `joinCollective(string _artistName, string _artistStatement)`: Allows artists to apply to join the collective with their name and statement.
 * 2. `approveArtist(address _artistAddress)`:  Owner-only function to approve pending artist applications, making them collective members.
 * 3. `submitArtwork(string _artworkTitle, string _artworkDescription, string _artworkCID)`:  Allows approved artists to submit their artworks for collective consideration.
 * 4. `voteOnArtwork(uint _artworkId, bool _approve)`: Collective members can vote to approve or reject submitted artworks.
 * 5. `mintArtworkNFT(uint _artworkId)`: After artwork approval, owner can mint an NFT representing the artwork and assign ownership to the collective.
 * 6. `transferArtworkNFT(uint _artworkId, address _recipient)`: Owner-only function to transfer ownership of an artwork NFT (e.g., for sales or collaborations).
 * 7. `setArtworkPrice(uint _artworkId, uint _price)`: Owner-only function to set the sale price for a collective-owned artwork.
 * 8. `purchaseArtwork(uint _artworkId)`: Allows anyone to purchase a collective-owned artwork, funds go to the collective treasury.
 * 9. `donateToCollective()`: Allows anyone to donate ETH to the collective treasury.
 * 10. `createSpendingProposal(string _proposalDescription, address _recipient, uint _amount)`: Collective members can create proposals to spend funds from the treasury.
 * 11. `voteOnSpendingProposal(uint _proposalId, bool _approve)`: Collective members can vote on spending proposals.
 * 12. `executeSpendingProposal(uint _proposalId)`: Owner-only function to execute approved spending proposals, transferring funds.
 * 13. `leaveCollective()`: Allows artists to voluntarily leave the collective.
 * 14. `removeArtist(address _artistAddress)`: Owner-only function to remove an artist from the collective.
 *
 * **Advanced & Creative Features:**
 * 15. `proposeCurator(address _curatorAddress)`: Collective members can propose a new curator (a role with special curation privileges).
 * 16. `voteOnCuratorProposal(uint _curatorProposalId, bool _approve)`: Collective members vote on curator proposals.
 * 17. `setArtworkCurator(uint _artworkId, address _curatorAddress)`: Curator-only function to assign a specific curator to an artwork for focused management.
 * 18. `createCollaborativeArtwork(string[] _artistNames, string _artworkTitle, string _artworkDescription, string _artworkCID)`:  Allows multiple artists to propose a collaborative artwork submission.
 * 19. `artistApproveCollaboration(uint _collaborationId)`: Artists involved in a collaboration must approve the submission before it goes to collective voting.
 * 20. `voteOnCollaborativeArtwork(uint _collaborationId, bool _approve)`: Collective members vote on collaborative artwork submissions.
 * 21. `mintCollaborativeArtworkNFT(uint _collaborationId)`: Mints NFT for approved collaborative artworks, ownership shared amongst collaborators and collective.
 * 22. `setRoyaltyPercentage(uint _artworkId, uint _percentage)`: Owner-only function to set a secondary sales royalty percentage for an artwork, benefiting the collective.
 * 23. `withdrawTreasuryFunds(uint _amount)`: Owner-only emergency function to withdraw funds from treasury (with strong governance considerations - ideally replaced by DAO voting in a real-world scenario).
 * 24. `getCollectiveBalance()`:  View function to check the collective's treasury balance.
 * 25. `getArtistCount()`: View function to get the number of approved artists in the collective.
 * 26. `getArtworkCount()`: View function to get the total number of artworks submitted to the collective.
 * 27. `getPendingArtistApplicationsCount()`: View function to get the number of pending artist applications.
 * 28. `getSpendingProposalCount()`: View function to get the total number of spending proposals.
 * 29. `getArtistDetails(address _artistAddress)`: View function to retrieve details about a specific artist.
 * 30. `getArtworkDetails(uint _artworkId)`: View function to retrieve details about a specific artwork.
 * 31. `getSpendingProposalDetails(uint _proposalId)`: View function to retrieve details about a specific spending proposal.
 * 32. `isArtistApproved(address _artistAddress)`: View function to check if an address is an approved artist.
 * 33. `isArtworkApproved(uint _artworkId)`: View function to check if an artwork is approved.
 * 34. `isSpendingProposalApproved(uint _proposalId)`: View function to check if a spending proposal is approved.
 * 35. `getArtworkNFTAddress(uint _artworkId)`: View function to get the contract address of the NFT associated with an artwork.
 * 36. `getArtworkPrice(uint _artworkId)`: View function to get the sale price of an artwork.
 * 37. `getArtworkOwner(uint _artworkId)`: View function to get the current owner of an artwork NFT.
 * 38. `isCurator(address _address)`: View function to check if an address is a curator.
 * 39. `getCuratorProposalDetails(uint _curatorProposalId)`: View function to retrieve details about a curator proposal.
 * 40. `voteOnCuratorProposal(uint _curatorProposalId, bool _approve)`: Collective members vote on curator proposals. (Duplicated in outline, should be removed or clarified if different context). - *Correction: Outline combined 16 and 40, corrected to be distinct.*

 * **Events:**
 * - ArtistJoined(address artistAddress, string artistName)
 * - ArtistApproved(address artistAddress)
 * - ArtworkSubmitted(uint artworkId, address artistAddress, string artworkTitle)
 * - ArtworkVoted(uint artworkId, address voter, bool approve)
 * - ArtworkApproved(uint artworkId)
 * - ArtworkNFTMinted(uint artworkId, address nftContractAddress)
 * - ArtworkNFTSent(uint artworkId, address recipient)
 * - ArtworkPriceSet(uint artworkId, uint price)
 * - ArtworkPurchased(uint artworkId, address buyer, uint price)
 * - DonationReceived(address donor, uint amount)
 * - SpendingProposalCreated(uint proposalId, address proposer, string description, address recipient, uint amount)
 * - SpendingProposalVoted(uint proposalId, address voter, bool approve)
 * - SpendingProposalApproved(uint proposalId)
 * - SpendingProposalExecuted(uint proposalId, address recipient, uint amount)
 * - ArtistLeft(address artistAddress)
 * - ArtistRemoved(address artistAddress)
 * - CuratorProposed(uint proposalId, address proposer, address proposedCurator)
 * - CuratorProposalVoted(uint proposalId, address voter, bool approve)
 * - CuratorApproved(address curatorAddress)
 * - CollaborativeArtworkProposed(uint collaborationId, string[] artistNames, string artworkTitle)
 * - CollaborationArtistApproved(uint collaborationId, address artistAddress)
 * - CollaborativeArtworkVoted(uint collaborationId, address voter, bool approve)
 * - CollaborativeArtworkApproved(uint collaborationId)
 * - CollaborativeArtworkNFTMinted(uint collaborationId, address nftContractAddress)
 * - RoyaltyPercentageSet(uint artworkId, uint percentage)
 * - TreasuryWithdrawal(address recipient, uint amount)
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs & Enums ---

    struct ArtistApplication {
        string artistName;
        string artistStatement;
        address artistAddress;
        bool pending;
    }

    struct Artist {
        string artistName;
        string artistStatement;
        address artistAddress;
        bool isActive;
        uint joinTimestamp;
    }

    struct Artwork {
        uint id;
        string title;
        string description;
        string cid; // IPFS CID or similar content identifier
        address artistAddress;
        ArtworkStatus status;
        uint approvalVotes;
        uint rejectionVotes;
        uint price;
        address nftContractAddress;
        uint royaltyPercentage; // Percentage of secondary sales royalty for the collective
        address curatorAddress; // Optional curator assigned to manage this artwork
    }

    enum ArtworkStatus {
        PENDING,
        APPROVED,
        REJECTED,
        MINTED,
        LISTED_FOR_SALE,
        SOLD
    }

    struct SpendingProposal {
        uint id;
        string description;
        address proposer;
        address recipient;
        uint amount;
        uint approvalVotes;
        uint rejectionVotes;
        ProposalStatus status;
        uint creationTimestamp;
    }

    enum ProposalStatus {
        PENDING,
        APPROVED,
        REJECTED,
        EXECUTED
    }

    struct CuratorProposal {
        uint id;
        address proposer;
        address proposedCurator;
        uint approvalVotes;
        uint rejectionVotes;
        ProposalStatus status;
        uint creationTimestamp;
    }

    struct CollaborativeArtworkProposal {
        uint id;
        string[] artistNames; // Names of collaborating artists (for display, addresses used internally)
        address[] artistAddresses; // Addresses of collaborating artists
        string title;
        string description;
        string cid;
        ArtworkStatus status;
        uint approvalVotes;
        uint rejectionVotes;
        uint collaborationApprovals; // Count of artists confirming collaboration
        uint totalCollaborators; // Total number of artists in the collaboration
        uint price;
        address nftContractAddress;
        uint royaltyPercentage;
    }


    // --- State Variables ---

    mapping(address => ArtistApplication) public artistApplications;
    mapping(address => Artist) public artists;
    mapping(uint => Artwork) public artworks;
    mapping(uint => SpendingProposal) public spendingProposals;
    mapping(uint => CuratorProposal) public curatorProposals;
    mapping(uint => CollaborativeArtworkProposal) public collaborativeArtworkProposals;
    mapping(address => bool) public curators; // Map of curators

    Counters.Counter private _artistApplicationCounter;
    Counters.Counter private _artworkCounter;
    Counters.Counter private _spendingProposalCounter;
    Counters.Counter private _curatorProposalCounter;
    Counters.Counter private _collaborativeArtworkProposalCounter;

    uint public votingDuration = 7 days; // Default voting duration for proposals and artworks
    uint public artworkApprovalThreshold = 50; // Percentage of votes needed for artwork approval
    uint public proposalApprovalThreshold = 60; // Percentage of votes needed for spending proposal approval
    uint public curatorProposalApprovalThreshold = 70; // Percentage for curator proposal approval

    // --- Events ---

    event ArtistJoined(address indexed artistAddress, string artistName);
    event ArtistApproved(address indexed artistAddress);
    event ArtworkSubmitted(uint indexed artworkId, address indexed artistAddress, string artworkTitle);
    event ArtworkVoted(uint indexed artworkId, address indexed voter, bool approve);
    event ArtworkApproved(uint indexed artworkId);
    event ArtworkRejected(uint indexed artworkId);
    event ArtworkNFTMinted(uint indexed artworkId, address nftContractAddress);
    event ArtworkNFTSent(uint indexed artworkId, address recipient);
    event ArtworkPriceSet(uint indexed artworkId, uint price);
    event ArtworkPurchased(uint indexed artworkId, address indexed buyer, uint price);
    event DonationReceived(address indexed donor, uint amount);
    event SpendingProposalCreated(uint indexed proposalId, address indexed proposer, string description, address recipient, uint amount);
    event SpendingProposalVoted(uint indexed proposalId, address indexed voter, bool approve);
    event SpendingProposalApproved(uint indexed proposalId);
    event SpendingProposalRejected(uint indexed proposalId);
    event SpendingProposalExecuted(uint indexed proposalId, address recipient, uint amount);
    event ArtistLeft(address indexed artistAddress);
    event ArtistRemoved(address indexed artistAddress);
    event CuratorProposed(uint indexed proposalId, address indexed proposer, address proposedCurator);
    event CuratorProposalVoted(uint indexed proposalId, uint indexed voter, bool approve);
    event CuratorApproved(address indexed curatorAddress);
    event CuratorProposalRejected(uint indexed proposalId);
    event CollaborativeArtworkProposed(uint indexed collaborationId, string[] artistNames, string artworkTitle);
    event CollaborationArtistApproved(uint indexed collaborationId, address indexed artistAddress);
    event CollaborativeArtworkVoted(uint indexed collaborationId, address indexed voter, bool approve);
    event CollaborativeArtworkApproved(uint indexed collaborationId);
    event CollaborativeArtworkRejected(uint indexed collaborationId);
    event CollaborativeArtworkNFTMinted(uint indexed collaborationId, address nftContractAddress);
    event RoyaltyPercentageSet(uint indexed artworkId, uint percentage);
    event TreasuryWithdrawal(address indexed recipient, uint amount);

    // --- Modifiers ---

    modifier onlyArtist() {
        require(artists[msg.sender].isActive, "Not an approved artist");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Not a curator");
        _;
    }

    modifier onlyValidArtworkId(uint _artworkId) {
        require(_artworkId > 0 && _artworkId <= _artworkCounter.current(), "Invalid artwork ID");
        _;
    }

    modifier onlyValidProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= _spendingProposalCounter.current(), "Invalid proposal ID");
        _;
    }

    modifier onlyValidCuratorProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= _curatorProposalCounter.current(), "Invalid curator proposal ID");
        _;
    }

    modifier onlyValidCollaborationId(uint _collaborationId) {
        require(_collaborationId > 0 && _collaborationId <= _collaborativeArtworkProposalCounter.current(), "Invalid collaboration ID");
        _;
    }

    modifier onlyPendingArtwork(uint _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.PENDING, "Artwork is not pending");
        _;
    }

    modifier onlyPendingProposal(uint _proposalId) {
        require(spendingProposals[_proposalId].status == ProposalStatus.PENDING, "Proposal is not pending");
        _;
    }

    modifier onlyPendingCuratorProposal(uint _proposalId) {
        require(curatorProposals[_proposalId].status == ProposalStatus.PENDING, "Curator Proposal is not pending");
        _;
    }

    modifier onlyPendingCollaboration(uint _collaborationId) {
        require(collaborativeArtworkProposals[_collaborationId].status == ArtworkStatus.PENDING, "Collaboration is not pending");
        _;
    }

    modifier onlyArtworkApproved(uint _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.APPROVED, "Artwork is not approved");
        _;
    }

    modifier onlyArtworkMinted(uint _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.MINTED, "Artwork is not minted");
        _;
    }

    modifier onlyArtworkListed(uint _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.LISTED_FOR_SALE, "Artwork is not listed for sale");
        _;
    }

    modifier votingPeriodActive() {
        // In a real DAO, more robust voting period tracking would be implemented.
        // This is a simplified placeholder.
        _; // Placeholder for time-based voting constraints.
    }


    // --- Core Functions ---

    function joinCollective(string memory _artistName, string memory _artistStatement) public {
        require(!artists[msg.sender].isActive, "Already a member or application pending");
        require(bytes(_artistName).length > 0 && bytes(_artistStatement).length > 0, "Artist name and statement cannot be empty");

        artistApplications[msg.sender] = ArtistApplication({
            artistName: _artistName,
            artistStatement: _artistStatement,
            artistAddress: msg.sender,
            pending: true
        });
        _artistApplicationCounter.increment();
        emit ArtistJoined(msg.sender, _artistName);
    }

    function approveArtist(address _artistAddress) public onlyOwner {
        require(artistApplications[_artistAddress].pending, "No pending application for this address");
        ArtistApplication memory application = artistApplications[_artistAddress];
        artists[_artistAddress] = Artist({
            artistName: application.artistName,
            artistStatement: application.artistStatement,
            artistAddress: _artistAddress,
            isActive: true,
            joinTimestamp: block.timestamp
        });
        artistApplications[_artistAddress].pending = false;
        emit ArtistApproved(_artistAddress);
    }

    function submitArtwork(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkCID) public onlyArtist {
        require(bytes(_artworkTitle).length > 0 && bytes(_artworkDescription).length > 0 && bytes(_artworkCID).length > 0, "Artwork details cannot be empty");
        _artworkCounter.increment();
        artworks[_artworkCounter.current()] = Artwork({
            id: _artworkCounter.current(),
            title: _artworkTitle,
            description: _artworkDescription,
            cid: _artworkCID,
            artistAddress: msg.sender,
            status: ArtworkStatus.PENDING,
            approvalVotes: 0,
            rejectionVotes: 0,
            price: 0,
            nftContractAddress: address(0),
            royaltyPercentage: 0,
            curatorAddress: address(0) // Initially no curator assigned
        });
        emit ArtworkSubmitted(_artworkCounter.current(), msg.sender, _artworkTitle);
    }

    function voteOnArtwork(uint _artworkId, bool _approve) public onlyArtist onlyValidArtworkId(_artworkId) onlyPendingArtwork(_artworkId) votingPeriodActive {
        Artwork storage artwork = artworks[_artworkId];
        // Simple voting - no double voting prevention for simplicity in this example.
        // In a real DAO, track voters per proposal to prevent double voting.
        if (_approve) {
            artwork.approvalVotes++;
        } else {
            artwork.rejectionVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve);

        uint totalVotes = artwork.approvalVotes + artwork.rejectionVotes;
        if (totalVotes >= getArtistCount()) { // Basic quorum - all artists vote (can be adjusted)
            uint approvalPercentage = (artwork.approvalVotes * 100) / totalVotes;
            if (approvalPercentage >= artworkApprovalThreshold) {
                artwork.status = ArtworkStatus.APPROVED;
                emit ArtworkApproved(_artworkId);
            } else {
                artwork.status = ArtworkStatus.REJECTED;
                emit ArtworkRejected(_artworkId);
            }
        }
    }

    function mintArtworkNFT(uint _artworkId) public onlyOwner onlyValidArtworkId(_artworkId) onlyArtworkApproved(_artworkId) {
        // In a real application, deploy a separate NFT contract per artwork or use a factory pattern for scalability.
        // For simplicity, using a basic ERC721 implementation inline.
        ArtworkNFT nftContract = new ArtworkNFT(string(abi.encodePacked("DAAC Artwork NFT #", _artworkId.toString())), string(abi.encodePacked("DAAC-ART-", _artworkId.toString())));
        artworks[_artworkId].nftContractAddress = address(nftContract);
        artworks[_artworkId].status = ArtworkStatus.MINTED;
        nftContract.safeMint(address(this), _artworkId); // Collective owns the NFT initially
        emit ArtworkNFTMinted(_artworkId, address(nftContract));
    }

    function transferArtworkNFT(uint _artworkId, address _recipient) public onlyOwner onlyValidArtworkId(_artworkId) onlyArtworkMinted(_artworkId) {
        ArtworkNFT nftContract = ArtworkNFT(artworks[_artworkId].nftContractAddress);
        nftContract.transferFrom(address(this), _recipient, _artworkId); // Transfer NFT ownership
        emit ArtworkNFTSent(_artworkId, _recipient);
    }

    function setArtworkPrice(uint _artworkId, uint _price) public onlyOwner onlyValidArtworkId(_artworkId) onlyArtworkMinted(_artworkId) {
        artworks[_artworkId].price = _price;
        artworks[_artworkId].status = ArtworkStatus.LISTED_FOR_SALE;
        emit ArtworkPriceSet(_artworkId, _price);
    }

    function purchaseArtwork(uint _artworkId) payable public onlyValidArtworkId(_artworkId) onlyArtworkListed(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(msg.value >= artwork.price, "Insufficient funds sent");
        ArtworkNFT nftContract = ArtworkNFT(artwork.nftContractAddress);
        nftContract.transferFrom(address(this), msg.sender, _artworkId); // Transfer NFT to buyer
        artwork.status = ArtworkStatus.SOLD;
        payable(owner()).transfer(msg.value); // Funds go to the collective treasury (owner as placeholder - use a proper treasury contract in real scenario)
        emit ArtworkPurchased(_artworkId, msg.sender, artwork.price);
    }

    function donateToCollective() payable public {
        payable(owner()).transfer(msg.value); // Donations go to the collective treasury (owner as placeholder)
        emit DonationReceived(msg.sender, msg.value);
    }

    function createSpendingProposal(string memory _proposalDescription, address _recipient, uint _amount) public onlyArtist {
        require(bytes(_proposalDescription).length > 0 && _recipient != address(0) && _amount > 0, "Invalid proposal details");
        _spendingProposalCounter.increment();
        spendingProposals[_spendingProposalCounter.current()] = SpendingProposal({
            id: _spendingProposalCounter.current(),
            description: _proposalDescription,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            approvalVotes: 0,
            rejectionVotes: 0,
            status: ProposalStatus.PENDING,
            creationTimestamp: block.timestamp
        });
        emit SpendingProposalCreated(_spendingProposalCounter.current(), msg.sender, _proposalDescription, _recipient, _amount);
    }

    function voteOnSpendingProposal(uint _proposalId, bool _approve) public onlyArtist onlyValidProposalId(_proposalId) onlyPendingProposal(_proposalId) votingPeriodActive {
        SpendingProposal storage proposal = spendingProposals[_proposalId];
        // Simple voting - no double voting prevention for simplicity.
        if (_approve) {
            proposal.approvalVotes++;
        } else {
            proposal.rejectionVotes++;
        }
        emit SpendingProposalVoted(_proposalId, msg.sender, _approve);

        uint totalVotes = proposal.approvalVotes + proposal.rejectionVotes;
        if (totalVotes >= getArtistCount()) { // Basic quorum - all artists vote
            uint approvalPercentage = (proposal.approvalVotes * 100) / totalVotes;
            if (approvalPercentage >= proposalApprovalThreshold) {
                proposal.status = ProposalStatus.APPROVED;
                emit SpendingProposalApproved(_proposalId);
            } else {
                proposal.status = ProposalStatus.REJECTED;
                emit SpendingProposalRejected(_proposalId);
            }
        }
    }

    function executeSpendingProposal(uint _proposalId) public onlyOwner onlyValidProposalId(_proposalId) onlyPendingProposal(_proposalId) { // Changed to pending for security - approval happens via voting
        SpendingProposal storage proposal = spendingProposals[_proposalId];
        require(proposal.status == ProposalStatus.APPROVED, "Proposal not approved");
        require(address(this).balance >= proposal.amount, "Insufficient contract balance to execute proposal");

        proposal.status = ProposalStatus.EXECUTED;
        payable(proposal.recipient).transfer(proposal.amount);
        emit SpendingProposalExecuted(_proposalId, proposal.recipient, proposal.amount);
    }

    function leaveCollective() public onlyArtist {
        artists[msg.sender].isActive = false;
        emit ArtistLeft(msg.sender);
    }

    function removeArtist(address _artistAddress) public onlyOwner {
        require(artists[_artistAddress].isActive, "Address is not an active artist");
        artists[_artistAddress].isActive = false;
        emit ArtistRemoved(_artistAddress);
    }


    // --- Advanced & Creative Features ---

    function proposeCurator(address _curatorAddress) public onlyArtist {
        require(_curatorAddress != address(0) && !curators[_curatorAddress], "Invalid curator address or already a curator");
        _curatorProposalCounter.increment();
        curatorProposals[_curatorProposalCounter.current()] = CuratorProposal({
            id: _curatorProposalCounter.current(),
            proposer: msg.sender,
            proposedCurator: _curatorAddress,
            approvalVotes: 0,
            rejectionVotes: 0,
            status: ProposalStatus.PENDING,
            creationTimestamp: block.timestamp
        });
        emit CuratorProposed(_curatorProposalCounter.current(), msg.sender, _curatorAddress);
    }

    function voteOnCuratorProposal(uint _curatorProposalId, bool _approve) public onlyArtist onlyValidCuratorProposalId(_curatorProposalId) onlyPendingCuratorProposal(_curatorProposalId) votingPeriodActive {
        CuratorProposal storage proposal = curatorProposals[_curatorProposalId];
        // Simple voting - no double voting prevention.
        if (_approve) {
            proposal.approvalVotes++;
        } else {
            proposal.rejectionVotes++;
        }
        emit CuratorProposalVoted(_curatorProposalId, msg.sender, _approve);

        uint totalVotes = proposal.approvalVotes + proposal.rejectionVotes;
        if (totalVotes >= getArtistCount()) { // Basic quorum - all artists vote
            uint approvalPercentage = (proposal.approvalVotes * 100) / totalVotes;
            if (approvalPercentage >= curatorProposalApprovalThreshold) {
                proposal.status = ProposalStatus.APPROVED;
                curators[proposal.proposedCurator] = true; // Make proposed address a curator
                emit CuratorApproved(proposal.proposedCurator);
            } else {
                proposal.status = ProposalStatus.REJECTED;
                emit CuratorProposalRejected(_curatorProposalId);
            }
        }
    }

    function setArtworkCurator(uint _artworkId, address _curatorAddress) public onlyCurator onlyValidArtworkId(_artworkId) onlyArtworkMinted(_artworkId) {
        require(artists[_curatorAddress].isActive || curators[_curatorAddress] || _curatorAddress == address(0), "Curator must be an artist, curator or address(0)");
        artworks[_artworkId].curatorAddress = _curatorAddress;
        // No event for curator assignment for brevity, can be added if needed.
    }


    function createCollaborativeArtwork(string[] memory _artistNames, string memory _artworkTitle, string memory _artworkDescription, string memory _artworkCID) public onlyArtist {
        require(_artistNames.length > 0 && bytes(_artworkTitle).length > 0 && bytes(_artworkDescription).length > 0 && bytes(_artworkCID).length > 0, "Invalid collaborative artwork details");
        require(_artistNames.length <= 5, "Maximum 5 collaborators allowed for simplicity"); // Limit collaborators for this example
        address[] memory collaboratorAddresses = new address[](_artistNames.length);
        collaboratorAddresses[0] = msg.sender; // Proposer is always the first collaborator
        uint collaboratorCount = 1;
        for (uint i = 1; i < _artistNames.length; i++) {
            // In a real scenario, artists should be identified by addresses, not names for on-chain interaction.
            // This name-based approach is for demonstration and simplicity.
            // A more robust system would involve artists explicitly adding collaborators by address.
            // For now, assume names are provided and lookup addresses (inefficient and simplified).
            // **Important:** This name-based address lookup is highly simplified and not recommended for production.
            address foundAddress = address(0);
            for (address artistAddress => Artist memory artist in artists) {
                if (keccak256(bytes(artist.artistName)) == keccak256(bytes(_artistNames[i]))) {
                    foundAddress = artistAddress;
                    break;
                }
            }
            require(foundAddress != address(0) && foundAddress != msg.sender, "Invalid collaborator name or proposer name used");
            collaboratorAddresses[collaboratorCount] = foundAddress;
            collaboratorCount++;
        }

        _collaborativeArtworkProposalCounter.increment();
        collaborativeArtworkProposals[_collaborativeArtworkProposalCounter.current()] = CollaborativeArtworkProposal({
            id: _collaborativeArtworkProposalCounter.current(),
            artistNames: _artistNames,
            artistAddresses: collaboratorAddresses,
            title: _artworkTitle,
            description: _artworkDescription,
            cid: _artworkCID,
            status: ArtworkStatus.PENDING,
            approvalVotes: 0,
            rejectionVotes: 0,
            collaborationApprovals: 1, // Proposer implicitly approves
            totalCollaborators: collaboratorCount,
            price: 0,
            nftContractAddress: address(0),
            royaltyPercentage: 0
        });
        emit CollaborativeArtworkProposed(_collaborativeArtworkProposalCounter.current(), _artistNames, _artworkTitle);
        emit CollaborationArtistApproved(_collaborativeArtworkProposalCounter.current(), msg.sender); // Proposer auto-approves
    }

    function artistApproveCollaboration(uint _collaborationId) public onlyArtist onlyValidCollaborationId(_collaborationId) onlyPendingCollaboration(_collaborationId) {
        CollaborativeArtworkProposal storage collaboration = collaborativeArtworkProposals[_collaborationId];
        bool isCollaborator = false;
        for (uint i = 0; i < collaboration.artistAddresses.length; i++) {
            if (collaboration.artistAddresses[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator && collaboration.status == ArtworkStatus.PENDING, "Not a collaborator or collaboration not pending");

        // Prevent double approval (simplified, can be improved with mapping if needed)
        for (uint i = 0; i < collaboration.artistAddresses.length; i++) {
            if (collaboration.artistAddresses[i] == msg.sender) {
                if (collaboration.artistAddresses[i] != address(0)) { // Simple flag to mark approval - can be better implemented
                    collaboration.artistAddresses[i] = address(0); // Mark as approved by setting address to zero (not ideal for real app)
                    collaboration.collaborationApprovals++;
                    emit CollaborationArtistApproved(_collaborationId, msg.sender);
                    break;
                } else {
                    revert("Already approved collaboration");
                }
            }
        }


        if (collaboration.collaborationApprovals == collaboration.totalCollaborators) {
            // All collaborators have approved, proceed to collective voting
            // (In a more complex system, there might be a timeout for artist approvals before moving to collective vote)
            // For now, directly move to collective vote.
            // No automatic collective vote trigger here - collective vote needs to be initiated separately.
        }
    }


    function voteOnCollaborativeArtwork(uint _collaborationId, bool _approve) public onlyArtist onlyValidCollaborationId(_collaborationId) onlyPendingCollaboration(_collaborationId) votingPeriodActive {
        CollaborativeArtworkProposal storage collaboration = collaborativeArtworkProposals[_collaborationId];
        require(collaboration.collaborationApprovals == collaboration.totalCollaborators, "Not all collaborators have approved yet"); // Ensure all collaborators approved first

        // Simple voting - no double voting prevention for simplicity.
        if (_approve) {
            collaboration.approvalVotes++;
        } else {
            collaboration.rejectionVotes++;
        }
        emit CollaborativeArtworkVoted(_collaborationId, msg.sender, _approve);

        uint totalVotes = collaboration.approvalVotes + collaboration.rejectionVotes;
        if (totalVotes >= getArtistCount()) { // Basic quorum - all artists vote
            uint approvalPercentage = (collaboration.approvalVotes * 100) / totalVotes;
            if (approvalPercentage >= artworkApprovalThreshold) {
                collaboration.status = ArtworkStatus.APPROVED;
                emit CollaborativeArtworkApproved(_collaborationId);
            } else {
                collaboration.status = ArtworkStatus.REJECTED;
                emit CollaborativeArtworkRejected(_collaborationId);
            }
        }
    }

    function mintCollaborativeArtworkNFT(uint _collaborationId) public onlyOwner onlyValidCollaborationId(_collaborationId) onlyArtworkApproved(_collaborationId) {
        CollaborativeArtworkProposal storage collaboration = collaborativeArtworkProposals[_collaborationId];
        // Mint NFT similar to single artwork, but handle shared ownership
        ArtworkNFT nftContract = new ArtworkNFT(string(abi.encodePacked("DAAC Collaborative Artwork NFT #", _collaborationId.toString())), string(abi.encodePacked("DAAC-COLLAB-ART-", _collaborationId.toString())));
        collaboration.nftContractAddress = address(nftContract);
        collaboration.status = ArtworkStatus.MINTED;
        nftContract.safeMint(address(this), _collaborationId); // Collective still initial owner

        // Distribute ownership - example: 50% to collective, 50% split among collaborators.
        uint collaboratorShares = 5000 / collaboration.totalCollaborators; // 50% as 5000 basis points (0.01% unit)
        uint collectiveShare = 5000; // 50% for collective
        uint totalShares = collectiveShare + (collaboratorShares * collaboration.totalCollaborators);
        require(totalShares == 10000, "Share distribution error"); // Ensure 100% distribution

        // In a real application, fractional NFT or custom logic for shared ownership would be implemented.
        // For this example, ownership remains with the collective, and profit sharing logic would be handled off-chain or in a more complex system.
        // This is a simplified demonstration.

        emit CollaborativeArtworkNFTMinted(_collaborationId, address(nftContract));
    }

    function setRoyaltyPercentage(uint _artworkId, uint _percentage) public onlyOwner onlyValidArtworkId(_artworkId) onlyArtworkMinted(_artworkId) {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100%");
        artworks[_artworkId].royaltyPercentage = _percentage;
        emit RoyaltyPercentageSet(_artworkId, _percentage);
        // In a real application, royalty enforcement would be handled at the NFT marketplace level or using standards like ERC2981.
    }

    function withdrawTreasuryFunds(uint _amount) public onlyOwner { // **Emergency function - replace with DAO voting in real scenario**
        require(_amount > 0 && address(this).balance >= _amount, "Insufficient balance or invalid amount");
        payable(owner()).transfer(_amount); // Owner address acts as temporary treasury manager for simplicity
        emit TreasuryWithdrawal(owner(), _amount);
        // In a real DAO, treasury management should be governed by proposals and multi-sig wallets for security and decentralization.
    }


    // --- View Functions ---

    function getCollectiveBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getArtistCount() public view returns (uint) {
        uint count = 0;
        for (address artistAddress => Artist memory artist in artists) {
            if (artist.isActive) {
                count++;
            }
        }
        return count;
    }

    function getArtworkCount() public view returns (uint) {
        return _artworkCounter.current();
    }

    function getPendingArtistApplicationsCount() public view returns (uint) {
        uint count = 0;
        for (address artistAddress => ArtistApplication memory application in artistApplications) {
            if (application.pending) {
                count++;
            }
        }
        return count;
    }

    function getSpendingProposalCount() public view returns (uint) {
        return _spendingProposalCounter.current();
    }

    function getArtistDetails(address _artistAddress) public view returns (Artist memory) {
        return artists[_artistAddress];
    }

    function getArtworkDetails(uint _artworkId) public view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getSpendingProposalDetails(uint _proposalId) public view returns (SpendingProposal memory) {
        return spendingProposals[_proposalId];
    }

    function isArtistApproved(address _artistAddress) public view returns (bool) {
        return artists[_artistAddress].isActive;
    }

    function isArtworkApproved(uint _artworkId) public view returns (bool) {
        return artworks[_artworkId].status == ArtworkStatus.APPROVED || artworks[_artworkId].status == ArtworkStatus.MINTED || artworks[_artworkId].status == ArtworkStatus.LISTED_FOR_SALE || artworks[_artworkId].status == ArtworkStatus.SOLD;
    }

    function isSpendingProposalApproved(uint _proposalId) public view returns (bool) {
        return spendingProposals[_proposalId].status == ProposalStatus.APPROVED || spendingProposals[_proposalId].status == ProposalStatus.EXECUTED;
    }

    function getArtworkNFTAddress(uint _artworkId) public view returns (address) {
        return artworks[_artworkId].nftContractAddress;
    }

    function getArtworkPrice(uint _artworkId) public view returns (uint) {
        return artworks[_artworkId].price;
    }

    function getArtworkOwner(uint _artworkId) public view returns (address) {
        ArtworkNFT nftContract = ArtworkNFT(artworks[_artworkId].nftContractAddress);
        return nftContract.ownerOf(_artworkId);
    }

    function isCurator(address _address) public view returns (bool) {
        return curators[_address];
    }

    function getCuratorProposalDetails(uint _curatorProposalId) public view returns (CuratorProposal memory) {
        return curatorProposals[_curatorProposalId];
    }

    function getCollaborativeArtworkDetails(uint _collaborationId) public view returns (CollaborativeArtworkProposal memory) {
        return collaborativeArtworkProposals[_collaborationId];
    }

    function isCollaborativeArtworkApproved(uint _collaborationId) public view returns (bool) {
        return collaborativeArtworkProposals[_collaborationId].status == ArtworkStatus.APPROVED || collaborativeArtworkProposals[_collaborationId].status == ArtworkStatus.MINTED || collaborativeArtworkProposals[_collaborationId].status == ArtworkStatus.LISTED_FOR_SALE || collaborativeArtworkProposals[_collaborationId].status == ArtworkStatus.SOLD;
    }


    // --- NFT Contract (Simplified Inline for Demonstration) ---
    // In a real application, this would be a separate contract.

}

contract ArtworkNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        // Optionally set initial owner or other configurations here
    }

    function safeMint(address to, uint256 artworkId) public onlyOwner {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, artworkId); // Using artworkId as tokenId for simplicity - can be separate if needed.
    }

    // Override _beforeTokenTransfer to implement royalty logic if needed in NFT contract directly.
    // Or use ERC2981 standard for marketplace compatibility.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    //     super._beforeTokenTransfer(from, to, tokenId);
    //     // Implement royalty logic here if needed.
    // }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Example: Construct token URI dynamically based on artwork details from the DAAC contract.
        // In a real application, fetch artwork metadata (title, description, image CID) from the DAAC contract
        // and construct a JSON metadata URI pointing to IPFS or a similar decentralized storage.
        string memory baseURI = "ipfs://YOUR_BASE_IPFS_CID/"; // Replace with your base IPFS URI for metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
}
```