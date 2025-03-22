```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to showcase,
 *      sell, and manage their digital art (NFTs), governed by a community DAO.
 *
 * Function Summary:
 * -----------------
 *
 * **Artist Management:**
 * 1. registerArtist(string _artistName, string _artistDescription): Allows users to register as artists.
 * 2. updateArtistProfile(string _artistName, string _artistDescription): Artists can update their profile information.
 * 3. getArtistProfile(address _artistAddress): Retrieves artist profile information.
 * 4. isRegisteredArtist(address _artistAddress): Checks if an address is a registered artist.
 *
 * **Gallery Governance (DAO):**
 * 5. proposeGalleryParameterChange(string _parameterName, uint256 _newValue): Registered artists can propose changes to gallery parameters (e.g., commission rate).
 * 6. voteOnProposal(uint256 _proposalId, bool _vote): Registered artists can vote on active proposals.
 * 7. executeProposal(uint256 _proposalId): Executes a passed proposal after voting period ends.
 * 8. getProposalDetails(uint256 _proposalId): Retrieves details of a specific governance proposal.
 * 9. getCurrentGalleryParameters(): Returns the current gallery parameters.
 *
 * **NFT Management & Artworks:**
 * 10. mintArtworkNFT(string _artworkTitle, string _artworkDescription, string _artworkCID, uint256 _royaltyPercentage): Artists mint their digital artwork as NFTs.
 * 11. setArtworkPrice(uint256 _artworkId, uint256 _price): Artists can set the price for their NFTs.
 * 12. purchaseArtworkNFT(uint256 _artworkId): Allows anyone to purchase an artwork NFT.
 * 13. listArtworkForSale(uint256 _artworkId): Artists can list their owned NFTs for sale in the gallery.
 * 14. removeArtworkFromSale(uint256 _artworkId): Artists can remove their NFTs from sale.
 * 15. getArtworkDetails(uint256 _artworkId): Retrieves details of a specific artwork NFT.
 * 16. getArtistArtworks(address _artistAddress): Retrieves a list of artwork IDs created by a specific artist.
 * 17. transferArtworkOwnership(uint256 _artworkId, address _newOwner): Allows artwork owners to transfer ownership (secondary sales, gifting).
 *
 * **Exhibition & Curation (Advanced Concept):**
 * 18. proposeExhibition(string _exhibitionTitle, string _exhibitionDescription, uint256 _startTime, uint256 _endTime): Registered artists can propose exhibitions.
 * 19. voteForExhibition(uint256 _exhibitionProposalId, bool _vote): Registered artists vote on exhibition proposals.
 * 20. finalizeExhibition(uint256 _exhibitionProposalId): Finalizes an exhibition proposal if it passes voting.
 * 21. addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId): Artists can submit their artworks to accepted exhibitions.
 * 22. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of a specific exhibition.
 * 23. getActiveExhibitions(): Retrieves a list of currently active exhibitions.
 *
 * **Utility & Info:**
 * 24. getGalleryBalance(): Returns the contract's current ETH balance.
 * 25. withdrawGalleryFunds(address _recipient, uint256 _amount):  DAO-governed function to withdraw funds (requires proposal and execution - not directly callable).
 */

contract DecentralizedAutonomousArtGallery {

    // --- Structs and Enums ---

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        bool isRegistered;
    }

    struct ArtworkNFT {
        uint256 artworkId;
        address artistAddress;
        string artworkTitle;
        string artworkDescription;
        string artworkCID; // IPFS CID or similar content identifier
        uint256 price;
        uint256 royaltyPercentage;
        bool isForSale;
        address owner;
    }

    struct GalleryParameterProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        bool isActive;
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        string exhibitionTitle;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isExecuted;
        bool isActive;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionTitle;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256[] artworkIds;
    }

    // --- State Variables ---

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => ArtworkNFT) public artworkNFTs;
    mapping(uint256 => GalleryParameterProposal) public galleryParameterProposals;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => Exhibition) public exhibitions;

    uint256 public nextArtworkId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextExhibitionId = 1;

    uint256 public galleryCommissionPercentage = 5; // Default commission percentage
    uint256 public proposalVotingDuration = 7 days; // Default voting duration for proposals
    uint256 public exhibitionVotingDuration = 3 days; // Default voting duration for exhibitions
    uint256 public minVotesForProposalExecution = 50; // Minimum % of votes (for) to execute a proposal

    address public daoTreasuryAddress; // Address to receive gallery commissions and funds

    // --- Events ---

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);
    event ArtworkMinted(uint256 artworkId, address artistAddress, string artworkTitle);
    event ArtworkPriceSet(uint256 artworkId, uint256 price);
    event ArtworkPurchased(uint256 artworkId, address buyerAddress, address artistAddress, uint256 price);
    event ArtworkListedForSale(uint256 artworkId);
    event ArtworkRemovedFromSale(uint256 artworkId);
    event ArtworkOwnershipTransferred(uint256 artworkId, address oldOwner, address newOwner);
    event GalleryParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ExhibitionProposed(uint256 proposalId, string exhibitionTitle);
    event ExhibitionVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionFinalized(uint256 exhibitionId, string exhibitionTitle);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);

    // --- Modifiers ---

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId < nextArtworkId, "Invalid artwork ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid proposal ID.");
        _;
    }

    modifier validExhibitionProposalId(uint256 _exhibitionProposalId) {
        require(_exhibitionProposalId > 0 && _exhibitionProposalId < nextProposalId, "Invalid exhibition proposal ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid exhibition ID.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(galleryParameterProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp >= galleryParameterProposals[_proposalId].voteStartTime && block.timestamp <= galleryParameterProposals[_proposalId].voteEndTime, "Voting period is not active.");
        _;
    }

    modifier exhibitionProposalActive(uint256 _exhibitionProposalId) {
        require(exhibitionProposals[_exhibitionProposalId].isActive, "Exhibition proposal is not active.");
        require(block.timestamp >= exhibitionProposals[_exhibitionProposalId].voteStartTime && block.timestamp <= exhibitionProposals[_exhibitionProposalId].voteEndTime, "Voting period is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!galleryParameterProposals[_proposalId].isExecuted, "Proposal already executed.");
        _;
    }

    modifier exhibitionProposalNotExecuted(uint256 _exhibitionProposalId) {
        require(!exhibitionProposals[_exhibitionProposalId].isExecuted, "Exhibition proposal already executed.");
        _;
    }


    // --- Constructor ---

    constructor(address _treasuryAddress) {
        daoTreasuryAddress = _treasuryAddress;
    }

    // --- Artist Management Functions ---

    function registerArtist(string memory _artistName, string memory _artistDescription) public {
        require(!artistProfiles[msg.sender].isRegistered, "Artist is already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistDescription) public onlyRegisteredArtist {
        artistProfiles[msg.sender].artistName = _artistName;
        artistProfiles[msg.sender].artistDescription = _artistDescription;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    function isRegisteredArtist(address _artistAddress) public view returns (bool) {
        return artistProfiles[_artistAddress].isRegistered;
    }

    // --- Gallery Governance (DAO) Functions ---

    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) public onlyRegisteredArtist {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        galleryParameterProposals[nextProposalId] = GalleryParameterProposal({
            proposalId: nextProposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            isActive: true
        });
        emit GalleryParameterProposalCreated(nextProposalId, _parameterName, _newValue);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist validProposalId(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        GalleryParameterProposal storage proposal = galleryParameterProposals[_proposalId];
        require(!hasVoted(proposalIdToVoters[_proposalId], msg.sender), "Artist has already voted on this proposal.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposalIdToVoters[_proposalId].push(msg.sender); // Record voter
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public validProposalId(_proposalId) proposalNotExecuted(_proposalId) {
        GalleryParameterProposal storage proposal = galleryParameterProposals[_proposalId];
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over.");
        require(proposal.isActive, "Proposal is not active.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast, proposal cannot be executed."); // Prevent division by zero
        uint256 percentageVotesFor = (proposal.votesFor * 100) / totalVotes;

        if (percentageVotesFor >= minVotesForProposalExecution) {
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("galleryCommissionPercentage"))) {
                galleryCommissionPercentage = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("proposalVotingDuration"))) {
                proposalVotingDuration = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("exhibitionVotingDuration"))) {
                exhibitionVotingDuration = proposal.newValue;
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("minVotesForProposalExecution"))) {
                minVotesForProposalExecution = proposal.newValue;
            } else {
                revert("Unknown parameter name in proposal."); // Prevent execution for unknown parameters
            }

            proposal.isExecuted = true;
            proposal.isActive = false; // Mark as not active anymore
            emit ProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            proposal.isActive = false; // Mark as not active anymore even if not executed due to failed vote
            revert("Proposal failed to reach required votes and cannot be executed.");
        }
    }

    function getProposalDetails(uint256 _proposalId) public view validProposalId(_proposalId) returns (GalleryParameterProposal memory) {
        return galleryParameterProposals[_proposalId];
    }

    function getCurrentGalleryParameters() public view returns (uint256 commissionPercentage, uint256 propVotingDuration, uint256 exhibVotingDuration, uint256 minVotesPercent) {
        return (galleryCommissionPercentage, proposalVotingDuration, exhibitionVotingDuration, minVotesForProposalExecution);
    }

    // --- NFT Management & Artworks Functions ---

    function mintArtworkNFT(string memory _artworkTitle, string memory _artworkDescription, string memory _artworkCID, uint256 _royaltyPercentage) public onlyRegisteredArtist {
        require(bytes(_artworkTitle).length > 0 && bytes(_artworkDescription).length > 0 && bytes(_artworkCID).length > 0, "Artwork details cannot be empty.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        artworkNFTs[nextArtworkId] = ArtworkNFT({
            artworkId: nextArtworkId,
            artistAddress: msg.sender,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artworkCID: _artworkCID,
            price: 0, // Price initially set to 0, artist needs to set it later
            royaltyPercentage: _royaltyPercentage,
            isForSale: false,
            owner: msg.sender
        });
        emit ArtworkMinted(nextArtworkId, msg.sender, _artworkTitle);
        nextArtworkId++;
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _price) public onlyRegisteredArtist validArtworkId(_artworkId) {
        require(artworkNFTs[_artworkId].artistAddress == msg.sender, "Only artist can set artwork price.");
        artworkNFTs[_artworkId].price = _price;
        emit ArtworkPriceSet(_artworkId, _price);
    }

    function purchaseArtworkNFT(uint256 _artworkId) public payable validArtworkId(_artworkId) {
        ArtworkNFT storage artwork = artworkNFTs[_artworkId];
        require(artwork.isForSale, "Artwork is not for sale.");
        require(msg.value >= artwork.price, "Insufficient funds sent.");

        uint256 galleryCommission = (artwork.price * galleryCommissionPercentage) / 100;
        uint256 artistPayout = artwork.price - galleryCommission;

        // Transfer funds
        payable(daoTreasuryAddress).transfer(galleryCommission);
        payable(artwork.artistAddress).transfer(artistPayout);
        artwork.owner = msg.sender;
        artwork.isForSale = false; // Artwork no longer for sale after purchase

        emit ArtworkPurchased(_artworkId, msg.sender, artwork.artistAddress, artwork.price);

        // Return excess ether if any
        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price);
        }
    }

    function listArtworkForSale(uint256 _artworkId) public onlyRegisteredArtist validArtworkId(_artworkId) {
        require(artworkNFTs[_artworkId].owner == msg.sender, "Only artwork owner can list it for sale.");
        require(artworkNFTs[_artworkId].price > 0, "Artwork price must be set before listing for sale.");
        artworkNFTs[_artworkId].isForSale = true;
        emit ArtworkListedForSale(_artworkId);
    }

    function removeArtworkFromSale(uint256 _artworkId) public onlyRegisteredArtist validArtworkId(_artworkId) {
        require(artworkNFTs[_artworkId].owner == msg.sender, "Only artwork owner can remove it from sale.");
        artworkNFTs[_artworkId].isForSale = false;
        emit ArtworkRemovedFromSale(_artworkId);
    }

    function getArtworkDetails(uint256 _artworkId) public view validArtworkId(_artworkId) returns (ArtworkNFT memory) {
        return artworkNFTs[_artworkId];
    }

    function getArtistArtworks(address _artistAddress) public view returns (uint256[] memory) {
        uint256[] memory artistArtworkIds = new uint256[](nextArtworkId - 1); // Max possible size, might be less
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtworkId; i++) {
            if (artworkNFTs[i].artistAddress == _artistAddress) {
                artistArtworkIds[count] = artworkNFTs[i].artworkId;
                count++;
            }
        }
        // Resize array to actual number of artworks
        assembly {
            mstore(artistArtworkIds, count) // Update array length
        }
        return artistArtworkIds;
    }

    function transferArtworkOwnership(uint256 _artworkId, address _newOwner) public validArtworkId(_artworkId) {
        require(artworkNFTs[_artworkId].owner == msg.sender, "Only artwork owner can transfer ownership.");
        require(_newOwner != address(0), "Invalid new owner address.");
        artworkNFTs[_artworkId].owner = _newOwner;
        artworkNFTs[_artworkId].isForSale = false; // No longer for sale after transfer
        emit ArtworkOwnershipTransferred(_artworkId, msg.sender, _newOwner);
    }


    // --- Exhibition & Curation Functions ---

    function proposeExhibition(string memory _exhibitionTitle, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime) public onlyRegisteredArtist {
        require(bytes(_exhibitionTitle).length > 0 && bytes(_exhibitionDescription).length > 0, "Exhibition details cannot be empty.");
        require(_startTime < _endTime && _startTime > block.timestamp, "Invalid exhibition start and end times.");

        exhibitionProposals[nextProposalId] = ExhibitionProposal({
            proposalId: nextProposalId,
            exhibitionTitle: _exhibitionTitle,
            exhibitionDescription: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + exhibitionVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            isExecuted: false,
            isActive: true
        });
        emit ExhibitionProposed(nextProposalId, _exhibitionTitle);
        nextProposalId++;
    }

    function voteForExhibition(uint256 _exhibitionProposalId, bool _vote) public onlyRegisteredArtist validExhibitionProposalId(_exhibitionProposalId) exhibitionProposalActive(_exhibitionProposalId) exhibitionProposalNotExecuted(_exhibitionProposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_exhibitionProposalId];
        require(!hasVoted(exhibitionProposalIdToVoters[_exhibitionProposalId], msg.sender), "Artist has already voted on this exhibition proposal.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        exhibitionProposalIdToVoters[_exhibitionProposalId].push(msg.sender); // Record voter
        emit ExhibitionVoted(_exhibitionProposalId, msg.sender, _vote);
    }

    function finalizeExhibition(uint256 _exhibitionProposalId) public validExhibitionProposalId(_exhibitionProposalId) exhibitionProposalNotExecuted(_exhibitionProposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_exhibitionProposalId];
        require(block.timestamp > proposal.voteEndTime, "Voting period is not over.");
        require(proposal.isActive, "Exhibition proposal is not active.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast, exhibition cannot be finalized."); // Prevent division by zero
        uint256 percentageVotesFor = (proposal.votesFor * 100) / totalVotes;

        if (percentageVotesFor >= minVotesForProposalExecution) {
            exhibitions[nextExhibitionId] = Exhibition({
                exhibitionId: nextExhibitionId,
                exhibitionTitle: proposal.exhibitionTitle,
                exhibitionDescription: proposal.exhibitionDescription,
                startTime: proposal.startTime,
                endTime: proposal.endTime,
                isActive: true,
                artworkIds: new uint256[](0) // Initialize with empty artwork list
            });
            proposal.isExecuted = true;
            proposal.isActive = false; // Mark as not active anymore
            emit ExhibitionFinalized(nextExhibitionId, proposal.exhibitionTitle);
            nextExhibitionId++;
        } else {
            proposal.isActive = false; // Mark as not active even if not finalized due to failed vote
            revert("Exhibition proposal failed to reach required votes and cannot be finalized.");
        }
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) public onlyRegisteredArtist validExhibitionId(_exhibitionId) validArtworkId(_artworkId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(artworkNFTs[_artworkId].artistAddress == msg.sender, "Only artist of the artwork can add it to exhibition.");

        Exhibition storage exhibition = exhibitions[_exhibitionId];
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            require(exhibition.artworkIds[i] != _artworkId, "Artwork already added to this exhibition."); // Prevent duplicates
        }

        exhibition.artworkIds.push(_artworkId);
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getActiveExhibitions() public view returns (uint256[] memory) {
        uint256[] memory activeExhibitionIds = new uint256[](nextExhibitionId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextExhibitionId; i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startTime && block.timestamp <= exhibitions[i].endTime) {
                activeExhibitionIds[count] = exhibitions[i].exhibitionId;
                count++;
            }
        }
        // Resize array
        assembly {
            mstore(activeExhibitionIds, count)
        }
        return activeExhibitionIds;
    }


    // --- Utility & Info Functions ---

    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // DAO-governed withdrawal -  In a real DAO, this would be executed via a governance proposal
    function withdrawGalleryFunds(address _recipient, uint256 _amount) public {
        // In a real DAO, this function would be callable by a governance mechanism after a successful proposal.
        // For this example, we simplify and allow anyone to call it (for demonstration purposes only).
        // In a production DAO, access control would be critical here.
        require(msg.sender == daoTreasuryAddress, "Only treasury can initiate withdrawals in this simplified example."); // Security Note: Remove this in a real DAO implementation
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount <= getGalleryBalance(), "Insufficient gallery balance.");

        payable(_recipient).transfer(_amount);
    }


    // --- Helper Functions ---
    mapping(uint256 => address[]) private proposalIdToVoters;
    mapping(uint256 => address[]) private exhibitionProposalIdToVoters;

    function hasVoted(address[] storage _voters, address _voter) private view returns (bool) {
        for (uint256 i = 0; i < _voters.length; i++) {
            if (_voters[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```