```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Advanced Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) with advanced features for art creation,
 * curation, fractionalization, collaborative art, dynamic royalties, on-chain exhibitions, and community governance.
 * It aims to empower artists and art enthusiasts in a decentralized and transparent manner.
 *
 * Function Summary:
 *
 * 1. registerArtist(string memory artistName, string memory artistBio): Allows artists to register with the collective.
 * 2. submitArtProposal(string memory title, string memory description, string memory ipfsHash, uint256[] memory collaboratorIds): Artists propose new artworks with details and optional collaborators.
 * 3. voteOnArtProposal(uint256 proposalId, bool vote): Members can vote on art proposals to decide which artworks are accepted.
 * 4. finalizeArtProposal(uint256 proposalId):  After successful voting, finalizes a proposal, mints an NFT representing the artwork, and credits creators.
 * 5. rejectArtProposal(uint256 proposalId): Rejects a proposal if it fails to get enough votes.
 * 6. fractionizeArt(uint256 artPieceId, uint256 numberOfFractions): Allows the collective to fractionize an approved artwork into ERC1155 tokens.
 * 7. purchaseArtFraction(uint256 fractionId, uint256 amount): Allows members to purchase fractions of an artwork.
 * 8. setFractionPrice(uint256 fractionId, uint256 newPrice): Governance function to set the price of art fractions.
 * 9. proposeCollaborativeArt(string memory title, string memory description, string memory initialIpfsHash, uint256[] memory collaboratorIds): Allows artists to propose collaborative artworks.
 * 10. contributeToCollaborativeArt(uint256 collaborativeArtId, string memory contributionIpfsHash): Collaborators can contribute to an ongoing collaborative artwork.
 * 11. finalizeCollaborativeArt(uint256 collaborativeArtId):  Finalizes a collaborative art piece after all contributions are made and mints an NFT.
 * 12. createExhibition(string memory exhibitionName, uint256[] memory artPieceIds, uint256 startTime, uint256 endTime):  Propose and create on-chain exhibitions of curated artworks.
 * 13. attendExhibition(uint256 exhibitionId): Allows members to "attend" an on-chain exhibition (could trigger events, rewards, etc. - placeholder functionality).
 * 14. proposeRoyaltyAdjustment(uint256 artPieceId, uint256 newRoyaltyPercentage):  Propose changes to the royalty percentage for a specific artwork.
 * 15. voteOnRoyaltyAdjustment(uint256 royaltyProposalId, bool vote): Members vote on royalty adjustment proposals.
 * 16. finalizeRoyaltyAdjustment(uint256 royaltyProposalId): Executes approved royalty adjustment proposals.
 * 17. donateToCollective(): Allows users to donate ETH to the collective for operational funds or artist support.
 * 18. withdrawDonations(uint256 amount): Governance function to withdraw donations for collective purposes.
 * 19. setGovernanceThreshold(uint256 newThreshold): Governance function to change the voting threshold for proposals.
 * 20. getArtPieceDetails(uint256 artPieceId): Retrieves detailed information about a specific art piece.
 * 21. getArtistProfile(uint256 artistId): Retrieves the profile information of a registered artist.
 * 22. getProposalDetails(uint256 proposalId): Retrieves details of a specific art proposal or royalty proposal.
 * 23. getExhibitionDetails(uint256 exhibitionId): Retrieves details of a specific exhibition.
 * 24. getFractionDetails(uint256 fractionId): Retrieves details of a specific art fraction.
 */

contract DecentralizedAutonomousArtCollective {
    // -------- State Variables --------

    uint256 public nextArtistId = 1;
    uint256 public nextArtPieceId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextFractionId = 1;
    uint256 public nextExhibitionId = 1;
    uint256 public governanceThresholdPercentage = 60; // Percentage of votes needed for approval

    address public governanceAdmin; // Address allowed to perform governance functions

    struct Artist {
        uint256 id;
        string artistName;
        string artistBio;
        address artistAddress;
        bool isRegistered;
    }
    mapping(uint256 => Artist) public artists;
    mapping(address => uint256) public artistIdByAddress; // Reverse lookup

    enum ArtProposalStatus { Pending, Approved, Rejected }
    struct ArtProposal {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        uint256[] creatorArtistIds; // Artists involved in creation
        ArtProposalStatus status;
        uint256 voteCount;
        mapping(address => bool) votes; // Track votes per address to prevent double voting
        uint256 deadline; // Voting deadline
    }
    mapping(uint256 => ArtProposal) public artProposals;

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        uint256[] creatorArtistIds;
        address minter; // Address that finalized and minted the NFT
        uint256 royaltyPercentage; // Dynamic royalty percentage
        uint256 fractionId; // ID of the fraction related to this art piece, if fractionized (0 if not)
        bool isFractionized;
    }
    mapping(uint256 => ArtPiece) public artPieces;

    struct ArtFraction {
        uint256 id;
        uint256 artPieceId;
        uint256 totalSupply;
        uint256 price;
        mapping(address => uint256) public balances; // ERC1155-like balance tracking
    }
    mapping(uint256 => ArtFraction) public artFractions;

    struct CollaborativeArt {
        uint256 id;
        string title;
        string description;
        string initialIpfsHash;
        uint256[] collaboratorArtistIds;
        string[] contributionsIpfsHashes; // Array to store IPFS hashes of contributions
        bool isFinalized;
        uint256 finalArtPieceId; // ID of the ArtPiece NFT minted after finalization
    }
    mapping(uint256 => CollaborativeArt) public collaborativeArts;

    struct Exhibition {
        uint256 id;
        string exhibitionName;
        uint256[] artPieceIds;
        uint256 startTime;
        uint256 endTime;
        uint256 attendeesCount; // Simple counter for exhibition attendance
    }
    mapping(uint256 => Exhibition) public exhibitions;

    enum RoyaltyProposalStatus { Pending, Approved, Rejected }
    struct RoyaltyAdjustmentProposal {
        uint256 id;
        uint256 artPieceId;
        uint256 newRoyaltyPercentage;
        RoyaltyProposalStatus status;
        uint256 voteCount;
        mapping(address => bool) votes;
        uint256 deadline;
    }
    mapping(uint256 => RoyaltyAdjustmentProposal) public royaltyProposals;

    uint256 public collectiveDonations; // Accumulated donations to the collective

    // -------- Events --------

    event ArtistRegistered(uint256 artistId, address artistAddress, string artistName);
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, uint256 artPieceId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtFractionized(uint256 artPieceId, uint256 fractionId, uint256 numberOfFractions);
    event ArtFractionPurchased(uint256 fractionId, address buyer, uint256 amount);
    event FractionPriceSet(uint256 fractionId, uint256 newPrice, address governanceAdmin);
    event CollaborativeArtProposed(uint256 collaborativeArtId, string title, address proposer);
    event CollaborativeArtContributionMade(uint256 collaborativeArtId, address contributor, string contributionIpfsHash);
    event CollaborativeArtFinalized(uint256 collaborativeArtId, uint256 finalArtPieceId);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName);
    event ExhibitionAttended(uint256 exhibitionId, address attendee);
    event RoyaltyAdjustmentProposed(uint256 proposalId, uint256 artPieceId, uint256 newRoyaltyPercentage, address proposer);
    event RoyaltyAdjustmentVoted(uint256 proposalId, address voter, bool vote);
    event RoyaltyAdjustmentFinalized(uint256 proposalId, uint256 artPieceId, uint256 newRoyaltyPercentage);
    event DonationReceived(address donor, uint256 amount);
    event DonationsWithdrawn(uint256 amount, address governanceAdmin);
    event GovernanceThresholdSet(uint256 newThreshold, address governanceAdmin);

    // -------- Modifiers --------

    modifier onlyGovernanceAdmin() {
        require(msg.sender == governanceAdmin, "Only governance admin can call this function.");
        _;
    }

    modifier artistExists(uint256 _artistId) {
        require(artists[_artistId].isRegistered, "Artist does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(artProposals[_proposalId].id != 0, "Art proposal does not exist.");
        _;
    }

    modifier fractionExists(uint256 _fractionId) {
        require(artFractions[_fractionId].id != 0, "Art fraction does not exist.");
        _;
    }

    modifier artPieceExists(uint256 _artPieceId) {
        require(artPieces[_artPieceId].id != 0, "Art piece does not exist.");
        _;
    }

    modifier collaborativeArtExists(uint256 _collaborativeArtId) {
        require(collaborativeArts[_collaborativeArtId].id != 0, "Collaborative art does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        _;
    }

    modifier royaltyProposalExists(uint256 _royaltyProposalId) {
        require(royaltyProposals[_royaltyProposalId].id != 0, "Royalty proposal does not exist.");
        _;
    }

    modifier votingNotFinished(uint256 _proposalId) {
        require(block.timestamp < artProposals[_proposalId].deadline, "Voting deadline has passed.");
        _;
    }

    modifier royaltyVotingNotFinished(uint256 _royaltyProposalId) {
        require(block.timestamp < royaltyProposals[_royaltyProposalId].deadline, "Royalty voting deadline has passed.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        governanceAdmin = msg.sender; // Set contract deployer as initial governance admin
    }

    // -------- Artist Management Functions --------

    function registerArtist(string memory _artistName, string memory _artistBio) public {
        require(artistIdByAddress[msg.sender] == 0, "Artist already registered.");
        Artist storage newArtist = artists[nextArtistId];
        newArtist.id = nextArtistId;
        newArtist.artistName = _artistName;
        newArtist.artistBio = _artistBio;
        newArtist.artistAddress = msg.sender;
        newArtist.isRegistered = true;
        artistIdByAddress[msg.sender] = nextArtistId;
        emit ArtistRegistered(nextArtistId, msg.sender, _artistName);
        nextArtistId++;
    }

    function getArtistProfile(uint256 _artistId) public view artistExists(_artistId) returns (Artist memory) {
        return artists[_artistId];
    }

    // -------- Art Proposal and Curation Functions --------

    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256[] memory _collaboratorIds
    ) public {
        uint256 artistId = artistIdByAddress[msg.sender];
        require(artistId != 0, "Only registered artists can submit proposals.");

        ArtProposal storage newProposal = artProposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.ipfsHash = _ipfsHash;
        newProposal.creatorArtistIds.push(artistId); // Proposer is always a creator
        for (uint256 i = 0; i < _collaboratorIds.length; i++) {
            require(artists[_collaboratorIds[i]].isRegistered, "Collaborator artist ID is invalid.");
            newProposal.creatorArtistIds.push(_collaboratorIds[i]);
        }
        newProposal.status = ArtProposalStatus.Pending;
        newProposal.deadline = block.timestamp + 7 days; // 7 days voting period

        emit ArtProposalSubmitted(nextProposalId, _title, msg.sender);
        nextProposalId++;
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public proposalExists(_proposalId) votingNotFinished(_proposalId) {
        require(!artProposals[_proposalId].votes[msg.sender], "Address has already voted on this proposal.");
        artProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].voteCount++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeArtProposal(uint256 _proposalId) public onlyGovernanceAdmin proposalExists(_proposalId) votingNotFinished(_proposalId) {
        require(artProposals[_proposalId].status == ArtProposalStatus.Pending, "Proposal is not pending.");
        uint256 requiredVotes = (address(this).balance * governanceThresholdPercentage) / 100; // Example: Voting power based on contract balance (can be replaced with token voting)
        require(artProposals[_proposalId].voteCount >= requiredVotes, "Proposal does not meet governance threshold.");

        artProposals[_proposalId].status = ArtProposalStatus.Approved;

        ArtPiece storage newArtPiece = artPieces[nextArtPieceId];
        newArtPiece.id = nextArtPieceId;
        newArtPiece.title = artProposals[_proposalId].title;
        newArtPiece.description = artProposals[_proposalId].description;
        newArtPiece.ipfsHash = artProposals[_proposalId].ipfsHash;
        newArtPiece.creatorArtistIds = artProposals[_proposalId].creatorArtistIds;
        newArtPiece.minter = msg.sender;
        newArtPiece.royaltyPercentage = 5; // Default royalty percentage
        newArtPiece.isFractionized = false;

        emit ArtProposalFinalized(_proposalId, nextArtPieceId);
        nextArtPieceId++;
    }

    function rejectArtProposal(uint256 _proposalId) public onlyGovernanceAdmin proposalExists(_proposalId) votingNotFinished(_proposalId) {
        require(artProposals[_proposalId].status == ArtProposalStatus.Pending, "Proposal is not pending.");
        artProposals[_proposalId].status = ArtProposalStatus.Rejected;
        emit ArtProposalRejected(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtPieceDetails(uint256 _artPieceId) public view artPieceExists(_artPieceId) returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    // -------- Art Fractionalization Functions --------

    function fractionizeArt(uint256 _artPieceId, uint256 _numberOfFractions) public onlyGovernanceAdmin artPieceExists(_artPieceId) {
        require(!artPieces[_artPieceId].isFractionized, "Art piece is already fractionized.");
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero.");

        ArtFraction storage newFraction = artFractions[nextFractionId];
        newFraction.id = nextFractionId;
        newFraction.artPieceId = _artPieceId;
        newFraction.totalSupply = _numberOfFractions;
        newFraction.price = 0.01 ether; // Initial fraction price - can be changed via governance

        artPieces[_artPieceId].fractionId = nextFractionId;
        artPieces[_artPieceId].isFractionized = true;

        emit ArtFractionized(_artPieceId, nextFractionId, _numberOfFractions);
        nextFractionId++;
    }

    function purchaseArtFraction(uint256 _fractionId, uint256 _amount) public payable fractionExists(_fractionId) {
        require(_amount > 0, "Purchase amount must be greater than zero.");
        ArtFraction storage fraction = artFractions[_fractionId];
        require(msg.value >= fraction.price * _amount, "Insufficient funds sent.");
        require(fraction.balances[address(0)] + _amount <= fraction.totalSupply, "Not enough fractions available."); // Simple supply check

        fraction.balances[msg.sender] += _amount;
        fraction.balances[address(0)] += _amount; // Track total minted fractions (address(0) as supply count)


        // Transfer funds to the collective (or artist/treasury - logic to be defined)
        payable(governanceAdmin).transfer(msg.value); // Example: Send to governance admin for now, refine distribution logic

        emit ArtFractionPurchased(_fractionId, msg.sender, _amount);
    }

    function setFractionPrice(uint256 _fractionId, uint256 _newPrice) public onlyGovernanceAdmin fractionExists(_fractionId) {
        artFractions[_fractionId].price = _newPrice;
        emit FractionPriceSet(_fractionId, _newPrice, msg.sender);
    }

    function getFractionDetails(uint256 _fractionId) public view fractionExists(_fractionId) returns (ArtFraction memory) {
        return artFractions[_fractionId];
    }


    // -------- Collaborative Art Functions --------

    function proposeCollaborativeArt(
        string memory _title,
        string memory _description,
        string memory _initialIpfsHash,
        uint256[] memory _collaboratorIds
    ) public {
        uint256 artistId = artistIdByAddress[msg.sender];
        require(artistId != 0, "Only registered artists can propose collaborative art.");
        require(_collaboratorIds.length > 0, "At least one collaborator is required.");

        CollaborativeArt storage newCollaborativeArt = collaborativeArts[nextExhibitionId];
        newCollaborativeArt.id = nextExhibitionId;
        newCollaborativeArt.title = _title;
        newCollaborativeArt.description = _description;
        newCollaborativeArt.initialIpfsHash = _initialIpfsHash;
        newCollaborativeArt.collaboratorArtistIds.push(artistId); // Proposer is always a collaborator
        for (uint256 i = 0; i < _collaboratorIds.length; i++) {
            require(artists[_collaboratorIds[i]].isRegistered, "Collaborator artist ID is invalid.");
            newCollaborativeArt.collaboratorArtistIds.push(_collaboratorIds[i]);
        }
        newCollaborativeArt.isFinalized = false;

        emit CollaborativeArtProposed(nextExhibitionId, _title, msg.sender);
        nextExhibitionId++;
    }

    function contributeToCollaborativeArt(uint256 _collaborativeArtId, string memory _contributionIpfsHash) public collaborativeArtExists(_collaborativeArtId) {
        uint256 artistId = artistIdByAddress[msg.sender];
        bool isCollaborator = false;
        for (uint256 i = 0; i < collaborativeArts[_collaborativeArtId].collaboratorArtistIds.length; i++) {
            if (collaborativeArts[_collaborativeArtId].collaboratorArtistIds[i] == artistId) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Only listed collaborators can contribute.");
        require(!collaborativeArts[_collaborativeArtId].isFinalized, "Collaborative art is already finalized.");

        collaborativeArts[_collaborativeArtId].contributionsIpfsHashes.push(_contributionIpfsHash);
        emit CollaborativeArtContributionMade(_collaborativeArtId, msg.sender, _contributionIpfsHash);
    }

    function finalizeCollaborativeArt(uint256 _collaborativeArtId) public onlyGovernanceAdmin collaborativeArtExists(_collaborativeArtId) {
        require(!collaborativeArts[_collaborativeArtId].isFinalized, "Collaborative art is already finalized.");
        collaborativeArts[_collaborativeArtId].isFinalized = true;

        ArtPiece storage newArtPiece = artPieces[nextArtPieceId];
        newArtPiece.id = nextArtPieceId;
        newArtPiece.title = collaborativeArts[_collaborativeArtId].title;
        newArtPiece.description = collaborativeArts[_collaborativeArtId].description;
        // For collaborative art, you might want to combine IPFS hashes or use a process to create a final combined IPFS hash
        newArtPiece.ipfsHash = collaborativeArts[_collaborativeArtId].contributionsIpfsHashes[collaborativeArts[_collaborativeArtId].contributionsIpfsHashes.length - 1]; // Example: Use the last contribution as final hash (needs better logic)
        newArtPiece.creatorArtistIds = collaborativeArts[_collaborativeArtId].collaboratorArtistIds;
        newArtPiece.minter = msg.sender;
        newArtPiece.royaltyPercentage = 5; // Default royalty percentage
        newArtPiece.isFractionized = false;

        collaborativeArts[_collaborativeArtId].finalArtPieceId = nextArtPieceId;

        emit CollaborativeArtFinalized(_collaborativeArtId, nextArtPieceId);
        nextArtPieceId++;
    }

    // -------- On-Chain Exhibition Functions --------

    function createExhibition(
        string memory _exhibitionName,
        uint256[] memory _artPieceIds,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyGovernanceAdmin {
        require(_artPieceIds.length > 0, "Exhibition must include at least one art piece.");
        require(_startTime < _endTime, "Start time must be before end time.");

        Exhibition storage newExhibition = exhibitions[nextExhibitionId];
        newExhibition.id = nextExhibitionId;
        newExhibition.exhibitionName = _exhibitionName;
        newExhibition.artPieceIds = _artPieceIds;
        newExhibition.startTime = _startTime;
        newExhibition.endTime = _endTime;
        newExhibition.attendeesCount = 0;

        emit ExhibitionCreated(nextExhibitionId, _exhibitionName);
        nextExhibitionId++;
    }

    function attendExhibition(uint256 _exhibitionId) public exhibitionExists(_exhibitionId) {
        require(block.timestamp >= exhibitions[_exhibitionId].startTime && block.timestamp <= exhibitions[_exhibitionId].endTime, "Exhibition is not currently active.");
        exhibitions[_exhibitionId].attendeesCount++; // Simple attendance tracking
        emit ExhibitionAttended(_exhibitionId, msg.sender);
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }


    // -------- Dynamic Royalty Functions --------

    function proposeRoyaltyAdjustment(uint256 _artPieceId, uint256 _newRoyaltyPercentage) public onlyGovernanceAdmin artPieceExists(_artPieceId) {
        require(_newRoyaltyPercentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        require(_newRoyaltyPercentage >= 0, "Royalty percentage cannot be negative.");

        RoyaltyAdjustmentProposal storage newRoyaltyProposal = royaltyProposals[nextProposalId];
        newRoyaltyProposal.id = nextProposalId;
        newRoyaltyProposal.artPieceId = _artPieceId;
        newRoyaltyProposal.newRoyaltyPercentage = _newRoyaltyPercentage;
        newRoyaltyProposal.status = RoyaltyProposalStatus.Pending;
        newRoyaltyProposal.deadline = block.timestamp + 5 days; // 5 days royalty voting period

        emit RoyaltyAdjustmentProposed(nextProposalId, _artPieceId, _newRoyaltyPercentage, msg.sender);
        nextProposalId++;
    }

    function voteOnRoyaltyAdjustment(uint256 _royaltyProposalId, bool _vote) public royaltyProposalExists(_royaltyProposalId) royaltyVotingNotFinished(_royaltyProposalId) {
        require(!royaltyProposals[_royaltyProposalId].votes[msg.sender], "Address has already voted on this royalty proposal.");
        royaltyProposals[_royaltyProposalId].votes[msg.sender] = true;
        if (_vote) {
            royaltyProposals[_royaltyProposalId].voteCount++;
        }
        emit RoyaltyAdjustmentVoted(_royaltyProposalId, msg.sender, _vote);
    }

    function finalizeRoyaltyAdjustment(uint256 _royaltyProposalId) public onlyGovernanceAdmin royaltyProposalExists(_royaltyProposalId) royaltyVotingNotFinished(_royaltyProposalId) {
        require(royaltyProposals[_royaltyProposalId].status == RoyaltyProposalStatus.Pending, "Royalty proposal is not pending.");
        uint256 requiredVotes = (address(this).balance * governanceThresholdPercentage) / 100; // Example voting power
        require(royaltyProposals[_royaltyProposalId].voteCount >= requiredVotes, "Royalty proposal does not meet governance threshold.");

        royaltyProposals[_royaltyProposalId].status = RoyaltyProposalStatus.Approved;
        uint256 artPieceId = royaltyProposals[_royaltyProposalId].artPieceId;
        artPieces[artPieceId].royaltyPercentage = royaltyProposals[_royaltyProposalId].newRoyaltyPercentage;

        emit RoyaltyAdjustmentFinalized(_royaltyProposalId, artPieceId, artPieces[artPieceId].royaltyPercentage);
    }

    function getRoyaltyProposalDetails(uint256 _royaltyProposalId) public view royaltyProposalExists(_royaltyProposalId) returns (RoyaltyAdjustmentProposal memory) {
        return royaltyProposals[_royaltyProposalId];
    }


    // -------- Collective Utility Functions --------

    function donateToCollective() public payable {
        collectiveDonations += msg.value;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdrawDonations(uint256 _amount) public onlyGovernanceAdmin {
        require(collectiveDonations >= _amount, "Insufficient donations in collective.");
        collectiveDonations -= _amount;
        payable(governanceAdmin).transfer(_amount); // Send to governance admin - refine withdrawal logic
        emit DonationsWithdrawn(_amount, msg.sender);
    }

    function setGovernanceThreshold(uint256 _newThreshold) public onlyGovernanceAdmin {
        require(_newThreshold <= 100 && _newThreshold >= 0, "Governance threshold must be between 0 and 100.");
        governanceThresholdPercentage = _newThreshold;
        emit GovernanceThresholdSet(_newThreshold, msg.sender);
    }

    // -------- Fallback and Receive --------

    receive() external payable {
        donateToCollective(); // Allow direct ETH donations to the contract
    }

    fallback() external {}
}
```