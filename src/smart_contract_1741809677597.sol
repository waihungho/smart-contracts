```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)

 * @dev A smart contract implementing a Decentralized Autonomous Art Gallery (DAAG).
 * It allows artists to submit artwork, community members to vote on artwork curation,
 * organize themed exhibitions, facilitate art sales, and reward artists and curators.
 * This contract explores advanced concepts like decentralized governance, community curation,
 * dynamic exhibitions, and on-chain reputation within an art-focused ecosystem.

 * Function Summary:

 * **Admin & Gallery Setup:**
 * 1. `initializeGallery(string _galleryName, uint256 _curationVoteDuration, uint256 _exhibitionVoteDuration, uint256 _galleryCommission)`: Initializes the gallery with name, voting durations, and commission.
 * 2. `setGalleryName(string _newName)`: Allows admin to change the gallery name.
 * 3. `setAdmin(address _newAdmin)`: Allows current admin to change the gallery admin.
 * 4. `setCurationVoteDuration(uint256 _newDuration)`: Sets the duration for artwork curation votes.
 * 5. `setExhibitionVoteDuration(uint256 _newDuration)`: Sets the duration for exhibition theme votes.
 * 6. `setGalleryCommission(uint256 _newCommission)`: Sets the gallery commission percentage on sales.
 * 7. `withdrawGalleryBalance()`: Allows admin to withdraw the gallery's accumulated balance.

 * **Artwork Submission & Curation:**
 * 8. `submitArtwork(string _title, string _description, string _ipfsHash)`: Allows artists to submit artwork for curation.
 * 9. `voteOnArtwork(uint256 _artworkId, bool _approve)`: Community members can vote to approve or reject submitted artwork.
 * 10. `finalizeArtworkCuration(uint256 _artworkId)`: Finalizes the curation process for an artwork after voting period.
 * 11. `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 * 12. `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Allows approved artists to list their artwork for sale.
 * 13. `removeArtworkFromSale(uint256 _artworkId)`: Allows artists to remove their artwork from sale.
 * 14. `buyArtwork(uint256 _artworkId)`: Allows users to purchase artwork listed for sale.

 * **Exhibitions & Community Engagement:**
 * 15. `proposeExhibitionTheme(string _theme, string _description)`: Community members can propose exhibition themes.
 * 16. `voteOnExhibitionTheme(uint256 _proposalId, bool _approve)`: Community members can vote on proposed exhibition themes.
 * 17. `finalizeExhibitionThemeVoting(uint256 _proposalId)`: Finalizes voting for an exhibition theme proposal.
 * 18. `createExhibition(uint256 _proposalId)`: Admin creates an exhibition based on an approved theme proposal.
 * 19. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Admin adds approved artworks to an active exhibition.
 * 20. `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Admin removes artwork from an exhibition.
 * 21. `endExhibition(uint256 _exhibitionId)`: Admin ends an active exhibition.
 * 22. `getActiveExhibitions()`: Retrieves a list of currently active exhibition IDs.
 * 23. `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 * 24. `getArtworkInExhibition(uint256 _exhibitionId)`: Retrieves a list of artwork IDs in a specific exhibition.
 * 25. `likeArtwork(uint256 _artworkId)`: Allows users to 'like' an artwork, contributing to its on-chain reputation.
 * 26. `getArtworkLikes(uint256 _artworkId)`: Retrieves the like count for an artwork.

 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtGallery {
    string public galleryName;
    address public admin;
    uint256 public curationVoteDuration; // Duration for artwork curation votes in seconds
    uint256 public exhibitionVoteDuration; // Duration for exhibition theme votes in seconds
    uint256 public galleryCommission; // Percentage commission on art sales (e.g., 500 for 5%)

    uint256 public artworkCounter;
    uint256 public exhibitionProposalCounter;
    uint256 public exhibitionCounter;

    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        bool isApproved;
        bool onCurationVote;
        uint256 curationVoteEndTime;
        mapping(address => bool) curationVotes; // address => vote (true=approve, false=reject)
        uint256 approveVotes;
        uint256 rejectVotes;
        bool isForSale;
        uint256 price;
        bool inExhibition;
        uint256 likes;
    }

    struct ExhibitionProposal {
        uint256 id;
        address proposer;
        string theme;
        string description;
        bool onVote;
        uint256 voteEndTime;
        mapping(address => bool) votes; // address => vote (true=approve)
        uint256 approveCount;
        bool isApproved;
    }

    struct Exhibition {
        uint256 id;
        string theme;
        string description;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => bool) public activeExhibitionIds; // To quickly track active exhibitions

    event GalleryInitialized(string galleryName, address admin);
    event GalleryNameChanged(string newName, address admin);
    event AdminChanged(address newAdmin, address oldAdmin);
    event CurationVoteDurationChanged(uint256 newDuration, address admin);
    event ExhibitionVoteDurationChanged(uint256 newDuration, address admin);
    event GalleryCommissionChanged(uint256 newCommission, address admin);
    event GalleryBalanceWithdrawn(address admin, uint256 amount);

    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkVoteCast(uint256 artworkId, address voter, bool approve);
    event ArtworkCurationFinalized(uint256 artworkId, bool isApproved);
    event ArtworkListedForSale(uint256 artworkId, uint256 price, address artist);
    event ArtworkRemovedFromSale(uint256 artworkId, address artist);
    event ArtworkPurchased(uint256 artworkId, address buyer, address artist, uint256 price);
    event ArtworkLiked(uint256 artworkId, address liker);

    event ExhibitionThemeProposed(uint256 proposalId, address proposer, string theme);
    event ExhibitionThemeVoteCast(uint256 proposalId, address voter, bool approve);
    event ExhibitionThemeVotingFinalized(uint256 proposalId, bool isApproved);
    event ExhibitionCreated(uint256 exhibitionId, string theme, address admin);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId, address admin);
    event ArtworkRemovedFromExhibition(uint256 exhibitionId, uint256 artworkId, address admin);
    event ExhibitionEnded(uint256 exhibitionId, address admin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        _;
    }

    modifier exhibitionProposalExists(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].id != 0, "Exhibition proposal does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only artist can call this function.");
        _;
    }

    modifier onlyIfArtworkApproved(uint256 _artworkId) {
        require(artworks[_artworkId].isApproved, "Artwork must be approved.");
        _;
    }

    modifier onlyIfArtworkNotApproved(uint256 _artworkId) {
        require(!artworks[_artworkId].isApproved, "Artwork must not be approved yet.");
        _;
    }

    modifier onlyIfCurationVoteActive(uint256 _artworkId) {
        require(artworks[_artworkId].onCurationVote, "Curation vote is not active.");
        require(block.timestamp < artworks[_artworkId].curationVoteEndTime, "Curation vote has ended.");
        _;
    }

    modifier onlyIfCurationVoteEnded(uint256 _artworkId) {
        require(artworks[_artworkId].onCurationVote, "Curation vote is not active."); // Check if it was ever started
        require(block.timestamp >= artworks[_artworkId].curationVoteEndTime, "Curation vote has not ended.");
        _;
    }

    modifier onlyIfExhibitionVoteActive(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].onVote, "Exhibition vote is not active.");
        require(block.timestamp < exhibitionProposals[_proposalId].voteEndTime, "Exhibition vote has ended.");
        _;
    }

    modifier onlyIfExhibitionVoteEnded(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].onVote, "Exhibition vote is not active."); // Check if it was ever started
        require(block.timestamp >= exhibitionProposals[_proposalId].voteEndTime, "Exhibition vote has not ended.");
        _;
    }

    modifier onlyIfExhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function initializeGallery(string memory _galleryName, uint256 _curationVoteDuration, uint256 _exhibitionVoteDuration, uint256 _galleryCommission) external onlyAdmin {
        require(bytes(galleryName).length == 0, "Gallery already initialized."); // Prevent re-initialization
        galleryName = _galleryName;
        curationVoteDuration = _curationVoteDuration;
        exhibitionVoteDuration = _exhibitionVoteDuration;
        galleryCommission = _galleryCommission;
        emit GalleryInitialized(_galleryName, admin);
    }

    // **** Admin & Gallery Setup Functions ****

    function setGalleryName(string memory _newName) external onlyAdmin {
        galleryName = _newName;
        emit GalleryNameChanged(_newName, admin);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(_newAdmin, oldAdmin);
    }

    function setCurationVoteDuration(uint256 _newDuration) external onlyAdmin {
        curationVoteDuration = _newDuration;
        emit CurationVoteDurationChanged(_newDuration, admin);
    }

    function setExhibitionVoteDuration(uint256 _newDuration) external onlyAdmin {
        exhibitionVoteDuration = _newDuration;
        emit ExhibitionVoteDurationChanged(_newDuration, admin);
    }

    function setGalleryCommission(uint256 _newCommission) external onlyAdmin {
        require(_newCommission <= 10000, "Commission cannot exceed 100% (10000 basis points).");
        galleryCommission = _newCommission;
        emit GalleryCommissionChanged(_newCommission, admin);
    }

    function withdrawGalleryBalance() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit GalleryBalanceWithdrawn(admin, balance);
    }


    // **** Artwork Submission & Curation Functions ****

    function submitArtwork(string memory _title, string memory _description, string memory _ipfsHash) external {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            isApproved: false,
            onCurationVote: true,
            curationVoteEndTime: block.timestamp + curationVoteDuration,
            approveVotes: 0,
            rejectVotes: 0,
            isForSale: false,
            price: 0,
            inExhibition: false,
            likes: 0
        });
        emit ArtworkSubmitted(artworkCounter, msg.sender, _title);
    }

    function voteOnArtwork(uint256 _artworkId, bool _approve) external artworkExists(_artworkId) onlyIfArtworkNotApproved(_artworkId) onlyIfCurationVoteActive(_artworkId) {
        require(!artworks[_artworkId].curationVotes[msg.sender], "You have already voted on this artwork.");
        artworks[_artworkId].curationVotes[msg.sender] = true;
        if (_approve) {
            artworks[_artworkId].approveVotes++;
        } else {
            artworks[_artworkId].rejectVotes++;
        }
        emit ArtworkVoteCast(_artworkId, msg.sender, _approve);
    }

    function finalizeArtworkCuration(uint256 _artworkId) external artworkExists(_artworkId) onlyAdmin onlyIfArtworkNotApproved(_artworkId) onlyIfCurationVoteEnded(_artworkId) {
        require(artworks[_artworkId].onCurationVote, "Curation vote must be active to finalize."); // Double check
        artworks[_artworkId].onCurationVote = false;
        if (artworks[_artworkId].approveVotes > artworks[_artworkId].rejectVotes) {
            artworks[_artworkId].isApproved = true;
            emit ArtworkCurationFinalized(_artworkId, true);
        } else {
            emit ArtworkCurationFinalized(_artworkId, false);
        }
    }

    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (
        uint256 id,
        address artist,
        string memory title,
        string memory description,
        string memory ipfsHash,
        bool isApproved,
        bool onCurationVote,
        uint256 curationVoteEndTime,
        uint256 approveVotes,
        uint256 rejectVotes,
        bool isForSale,
        uint256 price,
        bool inExhibition,
        uint256 likes
    ) {
        Artwork storage artwork = artworks[_artworkId];
        return (
            artwork.id,
            artwork.artist,
            artwork.title,
            artwork.description,
            artwork.ipfsHash,
            artwork.isApproved,
            artwork.onCurationVote,
            artwork.curationVoteEndTime,
            artwork.approveVotes,
            artwork.rejectVotes,
            artwork.isForSale,
            artwork.price,
            artwork.inExhibition,
            artwork.likes
        );
    }

    function listArtworkForSale(uint256 _artworkId, uint256 _price) external artworkExists(_artworkId) onlyArtist(_artworkId) onlyIfArtworkApproved(_artworkId) {
        require(_price > 0, "Price must be greater than zero.");
        artworks[_artworkId].isForSale = true;
        artworks[_artworkId].price = _price;
        emit ArtworkListedForSale(_artworkId, _price, msg.sender);
    }

    function removeArtworkFromSale(uint256 _artworkId) external artworkExists(_artworkId) onlyArtist(_artworkId) {
        artworks[_artworkId].isForSale = false;
        artworks[_artworkId].price = 0;
        emit ArtworkRemovedFromSale(_artworkId, msg.sender);
    }

    function buyArtwork(uint256 _artworkId) external payable artworkExists(_artworkId) onlyIfArtworkApproved(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isForSale, "Artwork is not for sale.");
        require(msg.value >= artwork.price, "Insufficient funds sent.");

        uint256 artistShare = artwork.price * (10000 - galleryCommission) / 10000;
        uint256 galleryShare = artwork.price - artistShare;

        artwork.isForSale = false; // Remove from sale after purchase
        artwork.price = 0;

        payable(artwork.artist).transfer(artistShare);
        payable(admin).transfer(galleryShare); // Gallery commission goes to admin for now, could be DAO treasury later

        emit ArtworkPurchased(_artworkId, msg.sender, artwork.artist, artwork.price);

        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price); // Return extra ether
        }
    }

    // **** Exhibitions & Community Engagement Functions ****

    function proposeExhibitionTheme(string memory _theme, string memory _description) external {
        exhibitionProposalCounter++;
        exhibitionProposals[exhibitionProposalCounter] = ExhibitionProposal({
            id: exhibitionProposalCounter,
            proposer: msg.sender,
            theme: _theme,
            description: _description,
            onVote: true,
            voteEndTime: block.timestamp + exhibitionVoteDuration,
            approveCount: 0,
            isApproved: false
        });
        emit ExhibitionThemeProposed(exhibitionProposalCounter, msg.sender, _theme);
    }

    function voteOnExhibitionTheme(uint256 _proposalId, bool _approve) external exhibitionProposalExists(_proposalId) onlyIfExhibitionVoteActive(_proposalId) {
        require(!exhibitionProposals[_proposalId].votes[msg.sender], "You have already voted on this proposal.");
        exhibitionProposals[_proposalId].votes[msg.sender] = true;
        if (_approve) {
            exhibitionProposals[_proposalId].approveCount++;
        }
        emit ExhibitionThemeVoteCast(_proposalId, msg.sender, _approve);
    }

    function finalizeExhibitionThemeVoting(uint256 _proposalId) external onlyAdmin exhibitionProposalExists(_proposalId) onlyIfExhibitionVoteEnded(_proposalId) {
        require(exhibitionProposals[_proposalId].onVote, "Exhibition vote must be active to finalize."); // Double check
        exhibitionProposals[_proposalId].onVote = false;
        if (exhibitionProposals[_proposalId].approveCount > 0) { // Simple majority for now, can be adjusted
            exhibitionProposals[_proposalId].isApproved = true;
            emit ExhibitionThemeVotingFinalized(_proposalId, true);
        } else {
            emit ExhibitionThemeVotingFinalized(_proposalId, false);
        }
    }

    function createExhibition(uint256 _proposalId) external onlyAdmin exhibitionProposalExists(_proposalId) {
        require(exhibitionProposals[_proposalId].isApproved, "Exhibition proposal must be approved to create exhibition.");
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            id: exhibitionCounter,
            theme: exhibitionProposals[_proposalId].theme,
            description: exhibitionProposals[_proposalId].description,
            isActive: true,
            startTime: block.timestamp,
            endTime: 0, // Set endTime to 0 initially, ended manually by admin
            artworkIds: new uint256[](0)
        });
        activeExhibitionIds[exhibitionCounter] = true;
        emit ExhibitionCreated(exhibitionCounter, exhibitionProposals[_proposalId].theme, admin);
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyAdmin exhibitionExists(_exhibitionId) artworkExists(_artworkId) onlyIfExhibitionActive(_exhibitionId) onlyIfArtworkApproved(_artworkId) {
        require(!artworks[_artworkId].inExhibition, "Artwork is already in an exhibition.");
        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        artworks[_artworkId].inExhibition = true;
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId, admin);
    }

    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyAdmin exhibitionExists(_exhibitionId) artworkExists(_artworkId) onlyIfExhibitionActive(_exhibitionId) {
        bool found = false;
        uint256[] storage artworkList = exhibitions[_exhibitionId].artworkIds;
        for (uint256 i = 0; i < artworkList.length; i++) {
            if (artworkList[i] == _artworkId) {
                artworkList[i] = artworkList[artworkList.length - 1]; // Move last element to current position
                artworkList.pop(); // Remove last element (duplicate now at index i)
                found = true;
                break;
            }
        }
        require(found, "Artwork is not in this exhibition.");
        artworks[_artworkId].inExhibition = false;
        emit ArtworkRemovedFromExhibition(_exhibitionId, _artworkId, admin);
    }

    function endExhibition(uint256 _exhibitionId) external onlyAdmin exhibitionExists(_exhibitionId) onlyIfExhibitionActive(_exhibitionId) {
        exhibitions[_exhibitionId].isActive = false;
        exhibitions[_exhibitionId].endTime = block.timestamp;
        activeExhibitionIds[_exhibitionId] = false;
        emit ExhibitionEnded(_exhibitionId, admin);
    }

    function getActiveExhibitions() external view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](exhibitionCounter); // Max size possible, will trim later
        uint256 count = 0;
        for (uint256 i = 1; i <= exhibitionCounter; i++) {
            if (activeExhibitionIds[i]) {
                activeIds[count] = i;
                count++;
            }
        }
        // Trim the array to the actual number of active exhibitions
        uint256[] memory trimmedActiveIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmedActiveIds[i] = activeIds[i];
        }
        return trimmedActiveIds;
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (
        uint256 id,
        string memory theme,
        string memory description,
        bool isActive,
        uint256 startTime,
        uint256 endTime,
        uint256[] memory artworkIds
    ) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (
            exhibition.id,
            exhibition.theme,
            exhibition.description,
            exhibition.isActive,
            exhibition.startTime,
            exhibition.endTime,
            exhibition.artworkIds
        );
    }

    function getArtworkInExhibition(uint256 _exhibitionId) external view exhibitionExists(_exhibitionId) returns (uint256[] memory) {
        return exhibitions[_exhibitionId].artworkIds;
    }

    function likeArtwork(uint256 _artworkId) external artworkExists(_artworkId) {
        artworks[_artworkId].likes++;
        emit ArtworkLiked(_artworkId, msg.sender);
    }

    function getArtworkLikes(uint256 _artworkId) external view artworkExists(_artworkId) returns (uint256) {
        return artworks[_artworkId].likes;
    }
}
```