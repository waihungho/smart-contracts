```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery - Smart Contract
 * @author Bard (AI Assistant)

 * @dev This smart contract implements a decentralized autonomous art gallery,
 * allowing artists to submit artworks, users to curate and vote on exhibitions,
 * and for the gallery to autonomously manage itself based on community input.
 * It incorporates advanced concepts like decentralized governance, dynamic royalties,
 * and on-chain reputation systems, aiming to create a vibrant and evolving art ecosystem.

 * Function Summary:
 * -----------------
 * **Art Submission & Management:**
 * 1. submitArt(string _ipfsHash, string _title, string _description, uint256 _royaltyPercentage): Allows artists to submit their artwork with metadata and set royalty.
 * 2. updateArtMetadata(uint256 _artId, string _ipfsHash, string _title, string _description): Allows artists to update metadata of their submitted artwork.
 * 3. removeArt(uint256 _artId): Allows artists to remove their artwork from the gallery (if not in active exhibition).
 * 4. censorArt(uint256 _artId): Allows community members to report inappropriate art for review and potential removal.
 * 5. getArtDetails(uint256 _artId): Retrieves detailed information about a specific artwork.
 * 6. getArtistArtworks(address _artist): Retrieves all artworks submitted by a specific artist.

 * **Exhibition Management & Curation:**
 * 7. proposeExhibitionTheme(string _theme, uint256 _votingDurationDays): Allows community members to propose new exhibition themes.
 * 8. voteForExhibitionTheme(uint256 _proposalId, bool _support): Allows community members to vote for or against proposed exhibition themes.
 * 9. selectArtForExhibition(uint256 _exhibitionId, uint256[] _artIds): Allows curators to select artworks for a specific exhibition.
 * 10. startExhibition(uint256 _exhibitionId): Starts an exhibition, making it active and visible.
 * 11. endExhibition(uint256 _exhibitionId): Ends an exhibition, potentially rewarding participating artists and curators.
 * 12. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of a specific exhibition.
 * 13. getActiveExhibitions(): Retrieves a list of currently active exhibitions.
 * 14. getPastExhibitions(): Retrieves a list of past exhibitions.

 * **NFT Minting & Sales (Conceptual - can be extended with NFT standards):**
 * 15. mintArtNFT(uint256 _artId): (Conceptual) Allows users to mint an NFT representing ownership of a specific artwork (requires integration with NFT standards).
 * 16. purchaseArtNFT(uint256 _artId): (Conceptual) Allows users to purchase an NFT of an artwork, distributing funds and royalties.
 * 17. setArtPrice(uint256 _artId, uint256 _price): (Conceptual) Allows artists to set a price for their artwork NFTs.

 * **Governance & Community Features:**
 * 18. contributeToGalleryFund(): Allows community members to contribute to a gallery fund for future development or artist grants.
 * 19. voteForGalleryParameterChange(string _parameterName, uint256 _newValue, uint256 _votingDurationDays): Allows community to vote on changes to gallery parameters (e.g., curation threshold, royalty splits).
 * 20. getGalleryStats(): Retrieves general statistics and information about the gallery (e.g., number of artworks, exhibitions, active users).
 * 21. withdrawGalleryFunds(address _recipient, uint256 _amount): (Admin/Governance controlled) Allows withdrawal of funds from the gallery fund for approved purposes.
 * 22. setCurationThreshold(uint256 _newThreshold): (Governance controlled) Allows changing the curation threshold for exhibitions.
 * 23. setGalleryFee(uint256 _newFeePercentage): (Governance controlled) Allows setting a fee percentage charged on NFT sales.

 * **Reputation System (Basic - can be expanded):**
 * 24. upvoteArt(uint256 _artId): Allows users to upvote artworks, contributing to a basic reputation score for artists.
 * 25. getArtistReputation(address _artist): Retrieves a basic reputation score for an artist based on upvotes.

 * **Emergency & Admin Functions (Controlled access):**
 * 26. pauseContract(): (Admin controlled) Emergency function to pause core functionalities of the contract.
 * 27. unpauseContract(): (Admin controlled) Resumes core functionalities of the contract.
 * 28. setAdmin(address _newAdmin): (Admin controlled) Transfers admin rights to a new address.
 */

contract DecentralizedArtGallery {
    // --- Data Structures ---

    struct ArtPiece {
        uint256 id;
        address artist;
        string ipfsHash; // IPFS hash for decentralized storage of artwork data
        string title;
        string description;
        uint256 royaltyPercentage; // Percentage of secondary sales royalty for the artist
        uint256 submissionTimestamp;
        bool isCensored;
        uint256 upvotes;
    }

    struct Exhibition {
        uint256 id;
        string theme;
        address curator; // Address responsible for curating the exhibition
        uint256 startTime;
        uint256 endTime;
        uint256 votingEndTime; // For theme voting
        uint256 curationThreshold; // Minimum votes required for art to be included in exhibition
        uint256[] artIds; // IDs of ArtPieces in this exhibition
        bool isActive;
        bool themeVotingActive;
        uint256 proposalId; // Reference to theme proposal if theme is being voted on
    }

    struct ThemeProposal {
        uint256 id;
        string theme;
        address proposer;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
    }

    // --- State Variables ---

    ArtPiece[] public artPieces;
    Exhibition[] public exhibitions;
    ThemeProposal[] public themeProposals;

    mapping(uint256 => mapping(address => bool)) public hasVotedForTheme; // proposalId => user => voted?
    mapping(address => uint256[]) public artistArtworks; // artist address => array of art IDs
    mapping(address => uint256) public artistReputation; // artist address => reputation score

    uint256 public nextArtId = 1;
    uint256 public nextExhibitionId = 1;
    uint256 public nextProposalId = 1;

    address public admin; // Admin address for contract management
    bool public paused = false;
    uint256 public galleryFeePercentage = 5; // Default gallery fee on NFT sales (conceptual)
    uint256 public defaultCurationThreshold = 10; // Default votes needed for art in exhibition

    uint256 public galleryFundBalance = 0; // Funds contributed to the gallery


    // --- Events ---

    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtMetadataUpdated(uint256 artId, string title);
    event ArtRemoved(uint256 artId, address artist);
    event ArtCensored(uint256 artId);
    event ExhibitionProposed(uint256 proposalId, string theme, address proposer);
    event ThemeVoteCast(uint256 proposalId, address voter, bool support);
    event ExhibitionCreated(uint256 exhibitionId, string theme, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event GalleryParameterChangeProposed(string parameterName, uint256 newValue, uint256 votingDurationDays);
    event GalleryFundsContributed(address contributor, uint256 amount);
    event GalleryFundsWithdrawn(address recipient, uint256 amount, address admin);
    event CurationThresholdChanged(uint256 newThreshold, address admin);
    event GalleryFeePercentageChanged(uint256 newFeePercentage, address admin);
    event ArtUpvoted(uint256 artId, address user);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address newAdmin, address oldAdmin);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- Art Submission & Management Functions ---

    function submitArt(string memory _ipfsHash, string memory _title, string memory _description, uint256 _royaltyPercentage)
        public
        whenNotPaused
    {
        require(bytes(_ipfsHash).length > 0 && bytes(_title).length > 0, "IPFS Hash and Title cannot be empty.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");

        artPieces.push(ArtPiece({
            id: nextArtId,
            artist: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            royaltyPercentage: _royaltyPercentage,
            submissionTimestamp: block.timestamp,
            isCensored: false,
            upvotes: 0
        }));
        artistArtworks[msg.sender].push(nextArtId);

        emit ArtSubmitted(nextArtId, msg.sender, _title);
        nextArtId++;
    }

    function updateArtMetadata(uint256 _artId, string memory _ipfsHash, string memory _title, string memory _description)
        public
        whenNotPaused
    {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(artPieces[_artId - 1].artist == msg.sender, "Only artist can update their art.");
        require(!artPieces[_artId - 1].isCensored, "Cannot update censored art.");

        artPieces[_artId - 1].ipfsHash = _ipfsHash;
        artPieces[_artId - 1].title = _title;
        artPieces[_artId - 1].description = _description;

        emit ArtMetadataUpdated(_artId, _title);
    }

    function removeArt(uint256 _artId) public whenNotPaused {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(artPieces[_artId - 1].artist == msg.sender, "Only artist can remove their art.");
        require(!artPieces[_artId - 1].isCensored, "Cannot remove censored art.");

        // Basic check to prevent removal if art is in an active exhibition (can be made more robust)
        for (uint256 i = 0; i < exhibitions.length; i++) {
            if (exhibitions[i].isActive) {
                for (uint256 j = 0; j < exhibitions[i].artIds.length; j++) {
                    if (exhibitions[i].artIds[j] == _artId) {
                        revert("Cannot remove art currently in an active exhibition.");
                    }
                }
            }
        }

        delete artPieces[_artId - 1]; // Consider alternative approaches for data management in production
        emit ArtRemoved(_artId, msg.sender);
    }

    function censorArt(uint256 _artId) public whenNotPaused {
        // Basic censorship mechanism - community reporting can trigger admin review in a real application
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(!artPieces[_artId - 1].isCensored, "Art is already censored.");

        artPieces[_artId - 1].isCensored = true;
        emit ArtCensored(_artId);
        // In a real application, this would trigger a governance/admin review process.
    }

    function getArtDetails(uint256 _artId) public view returns (ArtPiece memory) {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        return artPieces[_artId - 1];
    }

    function getArtistArtworks(address _artist) public view returns (uint256[] memory) {
        return artistArtworks[_artist];
    }


    // --- Exhibition Management & Curation Functions ---

    function proposeExhibitionTheme(string memory _theme, uint256 _votingDurationDays) public whenNotPaused {
        require(bytes(_theme).length > 0, "Theme cannot be empty.");
        require(_votingDurationDays > 0 && _votingDurationDays <= 30, "Voting duration must be between 1 and 30 days.");

        themeProposals.push(ThemeProposal({
            id: nextProposalId,
            theme: _theme,
            proposer: msg.sender,
            votingEndTime: block.timestamp + (_votingDurationDays * 1 days),
            yesVotes: 0,
            noVotes: 0,
            isActive: true
        }));

        emit ExhibitionProposed(nextProposalId, _theme, msg.sender);
        nextProposalId++;
    }

    function voteForExhibitionTheme(uint256 _proposalId, bool _support) public whenNotPaused {
        require(_proposalId > 0 && _proposalId < nextProposalId, "Invalid Proposal ID.");
        require(themeProposals[_proposalId - 1].isActive, "Voting for this proposal is not active.");
        require(block.timestamp <= themeProposals[_proposalId - 1].votingEndTime, "Voting period has ended.");
        require(!hasVotedForTheme[_proposalId][msg.sender], "You have already voted for this proposal.");

        hasVotedForTheme[_proposalId][msg.sender] = true;

        if (_support) {
            themeProposals[_proposalId - 1].yesVotes++;
        } else {
            themeProposals[_proposalId - 1].noVotes++;
        }
        emit ThemeVoteCast(_proposalId, msg.sender, _support);
    }

    function createExhibition(string memory _theme) public whenNotPaused returns (uint256) {
        exhibitions.push(Exhibition({
            id: nextExhibitionId,
            theme: _theme,
            curator: msg.sender, // Curator is the creator initially, can be changed via governance
            startTime: 0,
            endTime: 0,
            votingEndTime: 0,
            curationThreshold: defaultCurationThreshold,
            artIds: new uint256[](0),
            isActive: false,
            themeVotingActive: false,
            proposalId: 0
        }));
        emit ExhibitionCreated(nextExhibitionId, _theme, msg.sender);
        nextExhibitionId++;
        return nextExhibitionId - 1;
    }


    function selectArtForExhibition(uint256 _exhibitionId, uint256[] memory _artIds) public whenNotPaused {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid Exhibition ID.");
        require(exhibitions[_exhibitionId - 1].curator == msg.sender, "Only curator can select art for this exhibition.");
        require(!exhibitions[_exhibitionId - 1].isActive, "Cannot add art to an active exhibition.");

        for (uint256 i = 0; i < _artIds.length; i++) {
            require(_artIds[i] > 0 && _artIds[i] < nextArtId, "Invalid Art ID in selection.");
            bool alreadyInExhibition = false;
            for (uint256 j = 0; j < exhibitions[_exhibitionId - 1].artIds.length; j++) {
                if (exhibitions[_exhibitionId - 1].artIds[j] == _artIds[i]) {
                    alreadyInExhibition = true;
                    break;
                }
            }
            require(!alreadyInExhibition, "Art already added to this exhibition.");
            exhibitions[_exhibitionId - 1].artIds.push(_artIds[i]);
            emit ArtAddedToExhibition(_exhibitionId, _artIds[i]);
        }
    }


    function startExhibition(uint256 _exhibitionId) public whenNotPaused {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid Exhibition ID.");
        require(exhibitions[_exhibitionId - 1].curator == msg.sender || msg.sender == admin, "Only curator or admin can start exhibition.");
        require(!exhibitions[_exhibitionId - 1].isActive, "Exhibition is already active.");

        exhibitions[_exhibitionId - 1].isActive = true;
        exhibitions[_exhibitionId - 1].startTime = block.timestamp;
        emit ExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) public whenNotPaused {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid Exhibition ID.");
        require(exhibitions[_exhibitionId - 1].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId - 1].curator == msg.sender || msg.sender == admin, "Only curator or admin can end exhibition.");

        exhibitions[_exhibitionId - 1].isActive = false;
        exhibitions[_exhibitionId - 1].endTime = block.timestamp;
        emit ExhibitionEnded(_exhibitionId);
        // Here you could add logic to reward curators or artists based on exhibition performance.
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid Exhibition ID.");
        return exhibitions[_exhibitionId - 1];
    }

    function getActiveExhibitions() public view returns (Exhibition[] memory) {
        Exhibition[] memory activeExhibitions = new Exhibition[](exhibitions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < exhibitions.length; i++) {
            if (exhibitions[i].isActive) {
                activeExhibitions[count] = exhibitions[i];
                count++;
            }
        }
        // Resize the array to the actual number of active exhibitions
        assembly {
            mstore(activeExhibitions, count)
        }
        return activeExhibitions;
    }

    function getPastExhibitions() public view returns (Exhibition[] memory) {
        Exhibition[] memory pastExhibitions = new Exhibition[](exhibitions.length);
        uint256 count = 0;
        for (uint256 i = 0; i < exhibitions.length; i++) {
            if (!exhibitions[i].isActive && exhibitions[i].endTime > 0) {
                pastExhibitions[count] = exhibitions[i];
                count++;
            }
        }
        // Resize the array to the actual number of past exhibitions
        assembly {
            mstore(pastExhibitions, count)
        }
        return pastExhibitions;
    }


    // --- NFT Minting & Sales (Conceptual Functions) ---
    // These are placeholders and would require integration with ERC721/ERC1155 standards
    // and potentially a marketplace contract for a full implementation.

    function mintArtNFT(uint256 _artId) public payable whenNotPaused {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(artPieces[_artId - 1].artist == msg.sender, "Only artist can mint NFT for their art.");
        require(!artPieces[_artId - 1].isCensored, "Cannot mint NFT for censored art.");

        // --- Conceptual NFT Minting Logic (Needs ERC721/1155 integration) ---
        // Example:  _mintNFT(msg.sender, _artId);  // Assuming _mintNFT function from an NFT contract
        // For demonstration, we'll just emit an event.
        emit MintArtNFT(msg.sender, _artId);
    }

    event MintArtNFT(address minter, uint256 artId);


    function purchaseArtNFT(uint256 _artId) public payable whenNotPaused {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        // --- Conceptual Purchase Logic (Needs ERC721/1155 and marketplace integration) ---
        // Example:
        // uint256 price = getArtPrice(_artId); // Function to get the set price
        // require(msg.value >= price, "Insufficient funds.");
        // _transferNFT(ownerOfNFT(_artId), msg.sender, _artId); // Transfer NFT ownership
        // _payArtistRoyalty(_artId, price);
        // _payGalleryFee(price);

        emit PurchaseArtNFT(msg.sender, _artId);
    }
    event PurchaseArtNFT(address buyer, uint256 artId);


    function setArtPrice(uint256 _artId, uint256 _price) public whenNotPaused {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(artPieces[_artId - 1].artist == msg.sender, "Only artist can set price for their art.");
        // --- Conceptual Price Setting Logic (Needs NFT integration) ---
        emit SetArtPrice(_artId, _price);
    }
    event SetArtPrice(uint256 artId, uint256 price);


    // --- Governance & Community Functions ---

    function contributeToGalleryFund() public payable whenNotPaused {
        require(msg.value > 0, "Contribution must be greater than zero.");
        galleryFundBalance += msg.value;
        emit GalleryFundsContributed(msg.sender, msg.value);
    }


    function voteForGalleryParameterChange(string memory _parameterName, uint256 _newValue, uint256 _votingDurationDays) public whenNotPaused {
        // Basic parameter change proposal - in a real DAO, more robust governance mechanisms are needed.
        // Example parameters: curationThreshold, galleryFeePercentage.
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        require(_votingDurationDays > 0 && _votingDurationDays <= 30, "Voting duration must be between 1 and 30 days.");

        // In a real system, you'd store proposals and voting state more formally.
        // This is a simplified example.
        emit GalleryParameterChangeProposed(_parameterName, _newValue, _votingDurationDays);
        // Implement voting logic and parameter update based on voting outcome (e.g., in a separate function called after voting period).
    }


    function getGalleryStats() public view returns (uint256 numArtworks, uint256 numExhibitions, uint256 activeExhibitionCount, uint256 galleryFund) {
        return (nextArtId - 1, nextExhibitionId - 1, getActiveExhibitions().length, galleryFundBalance);
    }


    function withdrawGalleryFunds(address _recipient, uint256 _amount) public onlyAdmin whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0 && _amount <= galleryFundBalance, "Insufficient gallery funds or invalid amount.");

        payable(_recipient).transfer(_amount);
        galleryFundBalance -= _amount;
        emit GalleryFundsWithdrawn(_recipient, _amount, msg.sender);
    }

    function setCurationThreshold(uint256 _newThreshold) public onlyAdmin whenNotPaused {
        require(_newThreshold > 0, "Curation threshold must be greater than zero.");
        defaultCurationThreshold = _newThreshold;
        for (uint256 i = 0; i < exhibitions.length; i++) {
            exhibitions[i].curationThreshold = _newThreshold; // Update existing exhibitions too for consistency
        }
        emit CurationThresholdChanged(_newThreshold, msg.sender);
    }

    function setGalleryFee(uint256 _newFeePercentage) public onlyAdmin whenNotPaused {
        require(_newFeePercentage <= 100, "Gallery fee percentage must be between 0 and 100.");
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeePercentageChanged(_newFeePercentage, msg.sender);
    }


    // --- Reputation System Functions ---

    function upvoteArt(uint256 _artId) public whenNotPaused {
        require(_artId > 0 && _artId < nextArtId, "Invalid Art ID.");
        require(!artPieces[_artId - 1].isCensored, "Cannot upvote censored art.");

        artPieces[_artId - 1].upvotes++;
        artistReputation[artPieces[_artId - 1].artist]++; // Simple reputation increment

        emit ArtUpvoted(_artId, msg.sender);
    }

    function getArtistReputation(address _artist) public view returns (uint256) {
        return artistReputation[_artist];
    }


    // --- Emergency & Admin Functions ---

    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        emit AdminChanged(_newAdmin, admin);
        admin = _newAdmin;
    }

    receive() external payable {} // To accept ETH contributions to the gallery fund.
}
```