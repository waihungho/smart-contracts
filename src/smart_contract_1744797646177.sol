```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 * It allows artists to submit art, community curation, exhibitions,
 * fractional ownership of art, dynamic pricing, and governance through proposals.
 *
 * **Outline & Function Summary:**
 *
 * **State Variables:**
 *  - `galleryOwner`: Address of the gallery owner (admin).
 *  - `artworks`: Mapping of artwork IDs to Artwork structs.
 *  - `artists`: Mapping of artist addresses to Artist profiles.
 *  - `exhibitions`: Mapping of exhibition IDs to Exhibition structs.
 *  - `curators`: Array of curator addresses.
 *  - `artworkCount`: Counter for artwork IDs.
 *  - `exhibitionCount`: Counter for exhibition IDs.
 *  - `minCurationVotes`: Minimum votes required for an artwork to be curated.
 *  - `galleryFeePercentage`: Percentage of sales taken as gallery fee.
 *  - `fractionalTokenName`: Name for the fractional ownership tokens.
 *  - `fractionalTokenSymbol`: Symbol for the fractional ownership tokens.
 *  - `proposalCount`: Counter for governance proposal IDs.
 *  - `proposals`: Mapping of proposal IDs to Proposal structs.
 *  - `votingPeriod`: Duration of the voting period for proposals.
 *  - `minProposalVotes`: Minimum votes required for a proposal to pass.
 *  - `artistRegistrationFee`: Fee to register as an artist.
 *  - `royaltyPercentage`: Default royalty percentage for artists on secondary sales.
 *  - `platformCurrency`: Address of the accepted currency token (e.g., ERC20 stablecoin).
 *
 * **Structs:**
 *  - `Artwork`: Represents an artwork in the gallery.
 *  - `Artist`: Represents an artist profile.
 *  - `Exhibition`: Represents an art exhibition.
 *  - `FractionalOwnership`: Represents fractional ownership details.
 *  - `Proposal`: Represents a governance proposal.
 *  - `Vote`: Represents a vote on a curation or governance proposal.
 *
 * **Events:**
 *  - `ArtworkSubmitted`: Emitted when an artwork is submitted.
 *  - `ArtworkCurated`: Emitted when an artwork is curated.
 *  - `ArtworkRejected`: Emitted when an artwork is rejected.
 *  - `ArtworkPurchased`: Emitted when an artwork is purchased.
 *  - `ExhibitionStarted`: Emitted when an exhibition starts.
 *  - `ExhibitionEnded`: Emitted when an exhibition ends.
 *  - `ArtistRegistered`: Emitted when an artist registers.
 *  - `CuratorAdded`: Emitted when a curator is added.
 *  - `CuratorRemoved`: Emitted when a curator is removed.
 *  - `ProposalCreated`: Emitted when a governance proposal is created.
 *  - `ProposalVoted`: Emitted when a vote is cast on a proposal.
 *  - `ProposalExecuted`: Emitted when a proposal is executed.
 *  - `FractionalTokenCreated`: Emitted when fractional tokens are created for an artwork.
 *  - `FractionalTokenBurnt`: Emitted when fractional tokens are burnt upon full artwork purchase.
 *  - `RoyaltyPaid`: Emitted when royalties are paid to an artist.
 *
 * **Modifiers:**
 *  - `onlyGalleryOwner`: Modifier to restrict function access to the gallery owner.
 *  - `onlyCurator`: Modifier to restrict function access to curators.
 *  - `onlyRegisteredArtist`: Modifier to restrict function access to registered artists.
 *  - `nonZeroAddress`: Modifier to ensure address parameters are not zero addresses.
 *  - `validArtworkId`: Modifier to ensure artwork ID is valid.
 *  - `validExhibitionId`: Modifier to ensure exhibition ID is valid.
 *  - `validProposalId`: Modifier to ensure proposal ID is valid.
 *
 * **Functions:**
 *
 *  **[Gallery Management]**
 *  1. `setGalleryFeePercentage(uint256 _feePercentage)`: Allows the gallery owner to set the gallery fee percentage.
 *  2. `setPlatformCurrency(address _currencyAddress)`: Allows the gallery owner to set the accepted platform currency.
 *  3. `addCurator(address _curatorAddress)`: Allows the gallery owner to add a curator.
 *  4. `removeCurator(address _curatorAddress)`: Allows the gallery owner to remove a curator.
 *  5. `setArtistRegistrationFee(uint256 _registrationFee)`: Allows the gallery owner to set the artist registration fee.
 *  6. `setDefaultRoyaltyPercentage(uint256 _royaltyPercentage)`: Allows the gallery owner to set the default royalty percentage for artists.
 *  7. `setMinCurationVotes(uint256 _minVotes)`: Allows the gallery owner to set the minimum votes needed for artwork curation.
 *  8. `setMinProposalVotes(uint256 _minVotes)`: Allows the gallery owner to set the minimum votes needed for a proposal to pass.
 *  9. `setVotingPeriod(uint256 _votingPeriodSeconds)`: Allows the gallery owner to set the voting period for proposals.
 *  10. `setFractionalTokenDetails(string memory _name, string memory _symbol)`: Allows the gallery owner to set the name and symbol for fractional tokens.
 *  11. `withdrawGalleryFees()`: Allows the gallery owner to withdraw accumulated gallery fees.
 *
 *  **[Artwork Management]**
 *  12. `submitArtwork(string memory _title, string memory _description, string memory _ipfsHash, uint256 _initialPrice)`: Allows registered artists to submit artworks for curation.
 *  13. `curateArtwork(uint256 _artworkId)`: Allows curators to vote to curate an artwork.
 *  14. `rejectArtwork(uint256 _artworkId)`: Allows curators to vote to reject an artwork.
 *  15. `purchaseArtwork(uint256 _artworkId)`: Allows users to purchase a fully curated artwork.
 *  16. `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Allows the artist to change the price of their artwork (if not yet sold or fractionized).
 *  17. `reportArtwork(uint256 _artworkId, string memory _reportReason)`: Allows users to report an artwork for inappropriate content (triggers curator review).
 *
 *  **[Artist Management]**
 *  18. `registerArtist(string memory _artistName, string memory _artistBio)`: Allows users to register as artists by paying a registration fee.
 *  19. `updateArtistProfile(string memory _artistName, string memory _artistBio)`: Allows registered artists to update their profile information.
 *  20. `withdrawArtistEarnings()`: Allows artists to withdraw their earnings from artwork sales.
 *
 *  **[Exhibition Management]**
 *  21. `createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: Allows gallery owner/curators to create a new exhibition.
 *  22. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Allows gallery owner/curators to add curated artworks to an exhibition.
 *  23. `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Allows gallery owner/curators to remove artworks from an exhibition.
 *  24. `startExhibition(uint256 _exhibitionId)`: Allows gallery owner/curators to manually start an exhibition.
 *  25. `endExhibition(uint256 _exhibitionId)`: Allows gallery owner/curators to manually end an exhibition.
 *
 *  **[Fractional Ownership (Advanced Concept)]**
 *  26. `fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions)`: Allows the artist (or gallery owner upon artist request) to fractionalize a curated artwork.
 *  27. `buyFractionalToken(uint256 _artworkId, uint256 _amount)`: Allows users to buy fractional ownership tokens of an artwork.
 *  28. `sellFractionalToken(uint256 _artworkId, uint256 _amount)`: Allows users to sell fractional ownership tokens of an artwork.
 *  29. `redeemArtworkOwnership(uint256 _artworkId)`: Allows fractional token holders (if they collectively hold 100% of tokens) to redeem full ownership of the artwork (burns fractional tokens).
 *
 *  **[Governance (DAO Concept)]**
 *  30. `createGovernanceProposal(string memory _title, string memory _description, address _targetContract, bytes memory _calldata)`: Allows registered users (or artists/curators - configurable) to create governance proposals.
 *  31. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows registered users to vote on governance proposals.
 *  32. `executeProposal(uint256 _proposalId)`: Allows anyone to execute a passed governance proposal after the voting period.
 *
 *  **[Utility & View Functions]**
 *  33. `getArtworkDetails(uint256 _artworkId)`: Returns detailed information about an artwork.
 *  34. `getArtistProfile(address _artistAddress)`: Returns the profile information of an artist.
 *  35. `getExhibitionDetails(uint256 _exhibitionId)`: Returns details about an exhibition.
 *  36. `getCurators()`: Returns a list of curator addresses.
 *  37. `isCurator(address _account)`: Checks if an address is a curator.
 *  38. `isRegisteredArtist(address _account)`: Checks if an address is a registered artist.
 *  39. `getProposalDetails(uint256 _proposalId)`: Returns details of a governance proposal.
 *  40. `getFractionalTokenAddress(uint256 _artworkId)`: Returns the address of the fractional token contract for an artwork (if fractionalized).
 */
contract DecentralizedArtGallery {
    // State Variables
    address public galleryOwner;
    mapping(uint256 => Artwork) public artworks;
    mapping(address => Artist) public artists;
    mapping(uint256 => Exhibition) public exhibitions;
    address[] public curators;
    uint256 public artworkCount;
    uint256 public exhibitionCount;
    uint256 public minCurationVotes = 3; // Default minimum votes for curation
    uint256 public galleryFeePercentage = 5; // Default gallery fee percentage (5%)
    string public fractionalTokenName = "DAAG Fractional Token"; // Default fractional token name
    string public fractionalTokenSymbol = "DAFT"; // Default fractional token symbol
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriod = 7 days; // Default voting period (7 days)
    uint256 public minProposalVotes = 5; // Default minimum votes for proposal to pass
    uint256 public artistRegistrationFee = 0.1 ether; // Default registration fee
    uint256 public royaltyPercentage = 10; // Default royalty percentage (10%)
    address public platformCurrency; // Address of the accepted currency token (ERC20)

    // Structs
    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 price;
        bool isCurated;
        bool isRejected;
        uint256 curationVotes;
        uint256 rejectionVotes;
        address[] curatorVotes;
        address fractionalTokenContract; // Address of the fractional token contract if fractionalized
        bool isFractionalized;
        uint256 salesCount;
        uint256 lastSaleTimestamp;
        uint256 reportCount;
        string lastReportReason;
    }

    struct Artist {
        address artistAddress;
        string artistName;
        string artistBio;
        bool isRegistered;
        uint256 earningsBalance;
        uint256 registrationTimestamp;
    }

    struct Exhibition {
        uint256 id;
        string exhibitionName;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        uint256 createdTimestamp;
        address createdBy;
        uint256[] artworkIds;
        bool isActive;
    }

    // Struct for simplified fractional ownership (can be extended to ERC1155 for more advanced features)
    struct FractionalOwnership {
        uint256 artworkId;
        address tokenContractAddress; // Placeholder for future fractional token contract integration
        uint256 totalSupply;
    }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        address targetContract;
        bytes calldata;
        uint256 createdTimestamp;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        address[] voters; // Addresses that have voted
        bool executed;
        bool passed;
    }

    struct Vote {
        address voter;
        bool support;
        uint256 timestamp;
    }

    // Events
    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkCurated(uint256 artworkId, address curator);
    event ArtworkRejected(uint256 artworkId, address curator);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event ExhibitionStarted(uint256 exhibitionId, string exhibitionName);
    event ExhibitionEnded(uint256 exhibitionId, string exhibitionName);
    event ArtistRegistered(address artistAddress, string artistName);
    event CuratorAdded(address curatorAddress, address addedBy);
    event CuratorRemoved(address curatorAddress, address removedBy);
    event ProposalCreated(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event FractionalTokenCreated(uint256 artworkId, address tokenContractAddress, uint256 totalSupply);
    event FractionalTokenBurnt(uint256 artworkId);
    event RoyaltyPaid(uint256 artworkId, address artist, uint256 amount);

    // Modifiers
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        bool isCurator_ = false;
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == msg.sender) {
                isCurator_ = true;
                break;
            }
        }
        require(isCurator_, "Only curators can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artists[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be zero address.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(artworks[_artworkId].id != 0, "Invalid artwork ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].id != 0, "Invalid exhibition ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(proposals[_proposalId].id != 0, "Invalid proposal ID.");
        _;
    }


    // Constructor
    constructor(address _initialOwner, address[] memory _initialCurators, address _platformCurrencyAddress) {
        require(_initialOwner != address(0), "Initial owner address cannot be zero.");
        galleryOwner = _initialOwner;
        curators = _initialCurators;
        platformCurrency = _platformCurrencyAddress;
    }

    // --- [Gallery Management Functions] ---
    function setGalleryFeePercentage(uint256 _feePercentage) external onlyGalleryOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        galleryFeePercentage = _feePercentage;
    }

    function setPlatformCurrency(address _currencyAddress) external onlyGalleryOwner nonZeroAddress(_currencyAddress) {
        platformCurrency = _currencyAddress;
    }

    function addCurator(address _curatorAddress) external onlyGalleryOwner nonZeroAddress(_curatorAddress) {
        for (uint256 i = 0; i < curators.length; i++) {
            require(curators[i] != _curatorAddress, "Curator already exists.");
        }
        curators.push(_curatorAddress);
        emit CuratorAdded(_curatorAddress, msg.sender);
    }

    function removeCurator(address _curatorAddress) external onlyGalleryOwner nonZeroAddress(_curatorAddress) {
        bool removed = false;
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curatorAddress) {
                curators[i] = curators[curators.length - 1];
                curators.pop();
                removed = true;
                break;
            }
        }
        require(removed, "Curator not found.");
        emit CuratorRemoved(_curatorAddress, msg.sender);
    }

    function setArtistRegistrationFee(uint256 _registrationFee) external onlyGalleryOwner {
        artistRegistrationFee = _registrationFee;
    }

    function setDefaultRoyaltyPercentage(uint256 _royaltyPercentage) external onlyGalleryOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100.");
        royaltyPercentage = _royaltyPercentage;
    }

    function setMinCurationVotes(uint256 _minVotes) external onlyGalleryOwner {
        minCurationVotes = _minVotes;
    }

    function setMinProposalVotes(uint256 _minVotes) external onlyGalleryOwner {
        minProposalVotes = _minVotes;
    }

    function setVotingPeriod(uint256 _votingPeriodSeconds) external onlyGalleryOwner {
        votingPeriod = _votingPeriodSeconds;
    }

    function setFractionalTokenDetails(string memory _name, string memory _symbol) external onlyGalleryOwner {
        fractionalTokenName = _name;
        fractionalTokenSymbol = _symbol;
    }

    function withdrawGalleryFees() external onlyGalleryOwner {
        // TODO: Implement fee collection mechanism during purchases and withdrawal logic.
        // For now, placeholder -  requires integration with purchase function.
        //  (Example -  transfer accumulated fees to galleryOwner address from a balance held within contract)
        //  This will depend on how you implement the platform currency and fee collection.
        //  For simplicity, assuming fees are directly sent to the contract balance upon purchase.
        (bool success, ) = payable(galleryOwner).call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }

    // --- [Artwork Management Functions] ---
    function submitArtwork(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice
    ) external onlyRegisteredArtist {
        artworkCount++;
        artworks[artworkCount] = Artwork({
            id: artworkCount,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            price: _initialPrice,
            isCurated: false,
            isRejected: false,
            curationVotes: 0,
            rejectionVotes: 0,
            curatorVotes: new address[](0),
            fractionalTokenContract: address(0),
            isFractionalized: false,
            salesCount: 0,
            lastSaleTimestamp: 0,
            reportCount: 0,
            lastReportReason: ""
        });
        emit ArtworkSubmitted(artworkCount, msg.sender, _title);
    }

    function curateArtwork(uint256 _artworkId) external onlyCurator validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isCurated && !artwork.isRejected, "Artwork already curated or rejected.");
        bool alreadyVoted = false;
        for(uint i=0; i < artwork.curatorVotes.length; i++){
            if(artwork.curatorVotes[i] == msg.sender){
                alreadyVoted = true;
                break;
            }
        }
        require(!alreadyVoted, "Curator has already voted on this artwork.");

        artwork.curationVotes++;
        artwork.curatorVotes.push(msg.sender);

        if (artwork.curationVotes >= minCurationVotes) {
            artwork.isCurated = true;
            emit ArtworkCurated(_artworkId, msg.sender);
        }
    }

    function rejectArtwork(uint256 _artworkId) external onlyCurator validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(!artwork.isCurated && !artwork.isRejected, "Artwork already curated or rejected.");
        bool alreadyVoted = false;
        for(uint i=0; i < artwork.curatorVotes.length; i++){
            if(artwork.curatorVotes[i] == msg.sender){
                alreadyVoted = true;
                break;
            }
        }
        require(!alreadyVoted, "Curator has already voted on this artwork.");

        artwork.rejectionVotes++;
        artwork.curatorVotes.push(msg.sender); // Reusing curatorVotes array to track who voted (can be separated if needed)


        // No rejection vote threshold implemented for simplicity - can be added if needed.
        if (artwork.rejectionVotes > artwork.curationVotes && artwork.rejectionVotes > curators.length / 2) { // Example: Simple rejection logic
            artwork.isRejected = true;
            emit ArtworkRejected(_artworkId, msg.sender);
        }
    }

    function purchaseArtwork(uint256 _artworkId) external payable validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isCurated && !artwork.isRejected, "Artwork is not curated or is rejected.");
        require(!artwork.isFractionalized, "Artwork is fractionalized, purchase fractions instead.");
        require(msg.value >= artwork.price, "Insufficient funds sent.");

        // Transfer funds to artist (after deducting gallery fee)
        uint256 galleryFee = (artwork.price * galleryFeePercentage) / 100;
        uint256 artistPayment = artwork.price - galleryFee;

        // TODO: Implement currency transfer using platformCurrency ERC20 token if platformCurrency is set.
        // For now, assuming native currency (ETH) for simplicity.
        (bool transferArtistSuccess, ) = payable(artwork.artist).call{value: artistPayment}("");
        require(transferArtistSuccess, "Artist payment failed.");

        // Gallery fee is implicitly accumulated in contract balance for withdrawGalleryFees()

        artwork.salesCount++;
        artwork.lastSaleTimestamp = block.timestamp;
        emit ArtworkPurchased(_artworkId, msg.sender, artwork.price);
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) external onlyRegisteredArtist validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.artist == msg.sender, "Only artist can set artwork price.");
        require(!artwork.isFractionalized && artwork.salesCount == 0, "Cannot change price after fractionalization or sale."); // Simple condition
        artwork.price = _newPrice;
    }

    function reportArtwork(uint256 _artworkId, string memory _reportReason) external validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        artwork.reportCount++;
        artwork.lastReportReason = _reportReason;
        // TODO: Trigger curator review process based on report count or severity.
        // For now, just recording report.
    }

    // --- [Artist Management Functions] ---
    function registerArtist(string memory _artistName, string memory _artistBio) external payable {
        require(!artists[msg.sender].isRegistered, "Artist already registered.");
        require(msg.value >= artistRegistrationFee, "Insufficient registration fee.");

        artists[msg.sender] = Artist({
            artistAddress: msg.sender,
            artistName: _artistName,
            artistBio: _artistBio,
            isRegistered: true,
            earningsBalance: 0,
            registrationTimestamp: block.timestamp
        });
        emit ArtistRegistered(msg.sender, _artistName);

        // Transfer registration fee to gallery owner (or contract balance - depends on fee management)
        (bool transferFeeSuccess, ) = payable(galleryOwner).call{value: artistRegistrationFee}(""); // Simple transfer to owner
        require(transferFeeSuccess, "Registration fee transfer failed.");
    }

    function updateArtistProfile(string memory _artistName, string memory _artistBio) external onlyRegisteredArtist {
        Artist storage artistProfile = artists[msg.sender];
        artistProfile.artistName = _artistName;
        artistProfile.artistBio = _artistBio;
    }

    function withdrawArtistEarnings() external onlyRegisteredArtist {
        Artist storage artistProfile = artists[msg.sender];
        uint256 earnings = artistProfile.earningsBalance;
        require(earnings > 0, "No earnings to withdraw.");
        artistProfile.earningsBalance = 0;

        // TODO: Implement currency transfer using platformCurrency ERC20 token if platformCurrency is set.
        // For now, assuming native currency (ETH) for simplicity.
        (bool transferSuccess, ) = payable(msg.sender).call{value: earnings}("");
        require(transferSuccess, "Withdrawal failed.");
    }

    // --- [Exhibition Management Functions] ---
    function createExhibition(
        string memory _exhibitionName,
        string memory _exhibitionDescription,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyGalleryOwner { // Or allow curators to create exhibitions - configurable
        exhibitionCount++;
        exhibitions[exhibitionCount] = Exhibition({
            id: exhibitionCount,
            exhibitionName: _exhibitionName,
            exhibitionDescription: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            createdTimestamp: block.timestamp,
            createdBy: msg.sender,
            artworkIds: new uint256[](0),
            isActive: false
        });
    }

    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyGalleryOwner validExhibitionId(_exhibitionId) validArtworkId(_artworkId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isCurated, "Artwork must be curated to be added to an exhibition.");
        exhibition.artworkIds.push(_artworkId);
    }

    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyGalleryOwner validExhibitionId(_exhibitionId) validArtworkId(_artworkId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        bool removed = false;
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            if (exhibition.artworkIds[i] == _artworkId) {
                exhibition.artworkIds[i] = exhibition.artworkIds[exhibition.artworkIds.length - 1];
                exhibition.artworkIds.pop();
                removed = true;
                break;
            }
        }
        require(removed, "Artwork not found in exhibition.");
    }

    function startExhibition(uint256 _exhibitionId) external onlyGalleryOwner validExhibitionId(_exhibitionId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(!exhibition.isActive, "Exhibition already active.");
        require(block.timestamp >= exhibition.startTime, "Exhibition start time not reached.");
        exhibition.isActive = true;
        emit ExhibitionStarted(_exhibitionId, exhibition.exhibitionName);
    }

    function endExhibition(uint256 _exhibitionId) external onlyGalleryOwner validExhibitionId(_exhibitionId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition not active.");
        require(block.timestamp >= exhibition.endTime, "Exhibition end time not reached.");
        exhibition.isActive = false;
        emit ExhibitionEnded(_exhibitionId, exhibition.exhibitionName);
    }


    // --- [Fractional Ownership Functions] ---
    function fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions) external onlyRegisteredArtist validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.artist == msg.sender, "Only artist can fractionalize their artwork.");
        require(artwork.isCurated && !artwork.isFractionalized && artwork.salesCount == 0, "Artwork cannot be fractionalized.");
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero.");

        // TODO: Integrate with a fractional token contract (e.g., ERC1155 based or a custom minimal token)
        // For simplicity, just marking artwork as fractionalized and storing placeholder token address.
        // In a real implementation, deploy a new fractional token contract for this artwork here.

        // Placeholder - for demonstration purposes, assume a simple internal token management.
        // In a real application, deploy a dedicated fractional token contract per artwork.
        artwork.isFractionalized = true;
        artwork.fractionalTokenContract = address(this); // Using contract address as placeholder.
        emit FractionalTokenCreated(_artworkId, address(this), _numberOfFractions); // Placeholder token address
    }

    function buyFractionalToken(uint256 _artworkId, uint256 _amount) external payable validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isFractionalized, "Artwork is not fractionalized.");
        require(msg.value >= artwork.price / 100 * _amount, "Insufficient funds for fractional tokens."); // Example: Assuming 100 fractions initially, price per fraction = artwork.price / 100

        // TODO: Implement fractional token transfer/minting logic.
        // In a real implementation, interact with the fractional token contract (artwork.fractionalTokenContract).
        // For simplicity, assuming internal token management is handled elsewhere or externally.
        // (Example -  mint tokens to buyer's address in a separate fractional token contract.)

        // Placeholder - for demonstration purposes.
        //  (Assume tokens are tracked and managed externally)
        emit ArtworkPurchased(_artworkId, msg.sender, msg.value); // Example event - adjust as needed
    }

    function sellFractionalToken(uint256 _artworkId, uint256 _amount) external validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isFractionalized, "Artwork is not fractionalized.");

        // TODO: Implement fractional token transfer/burning logic.
        // In a real implementation, interact with the fractional token contract (artwork.fractionalTokenContract).
        // For simplicity, assuming internal token management.
        // (Example - burn tokens from seller's address in a separate fractional token contract and transfer funds back.)

        // Placeholder - for demonstration purposes.
        // (Assume tokens are tracked and managed externally)
        emit ArtworkPurchased(_artworkId, msg.sender, 0); // Example event - adjust as needed (price calculation needed)
    }

    function redeemArtworkOwnership(uint256 _artworkId) external validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.isFractionalized, "Artwork is not fractionalized.");

        // TODO: Implement logic to check if the caller (or collective of callers) owns 100% of fractional tokens.
        // In a real implementation, interact with the fractional token contract to query balances.
        // For simplicity, assuming ownership check is handled externally.
        // (Example -  check total balance of fractional tokens held by msg.sender and collaborators against total supply in fractional token contract.)

        // Placeholder - for demonstration purposes.
        // (Assume ownership check and token burning are handled externally)
        artwork.isFractionalized = false; // Revert artwork to full ownership status
        emit FractionalTokenBurnt(_artworkId);
    }


    // --- [Governance Functions] ---
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        address _targetContract,
        bytes memory _calldata
    ) external onlyRegisteredArtist { // Example: Only registered artists can create proposals - configurable
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            proposer: msg.sender,
            targetContract: _targetContract,
            calldata: _calldata,
            createdTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voters: new address[](0),
            executed: false,
            passed: false
        });
        emit ProposalCreated(proposalCount, _title, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external validProposalId(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended.");
        require(!proposal.executed, "Proposal already executed.");
        bool alreadyVoted = false;
        for(uint i=0; i < proposal.voters.length; i++){
            if(proposal.voters[i] == msg.sender){
                alreadyVoted = true;
                break;
            }
        }
        require(!alreadyVoted, "You have already voted on this proposal.");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.voters.push(msg.sender);
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external validProposalId(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended.");
        require(!proposal.executed, "Proposal already executed.");

        if (proposal.votesFor >= minProposalVotes && proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            (bool success, ) = proposal.targetContract.call(proposal.calldata);
            require(success, "Proposal execution failed.");
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.executed = true; // Mark as executed even if not passed to prevent re-execution
        }
    }


    // --- [Utility & View Functions] ---
    function getArtworkDetails(uint256 _artworkId) external view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtistProfile(address _artistAddress) external view nonZeroAddress(_artistAddress) returns (Artist memory) {
        return artists[_artistAddress];
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibitionId(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getCurators() external view returns (address[] memory) {
        return curators;
    }

    function isCurator(address _account) external view nonZeroAddress(_account) returns (bool) {
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function isRegisteredArtist(address _account) external view nonZeroAddress(_account) returns (bool) {
        return artists[_account].isRegistered;
    }

    function getProposalDetails(uint256 _proposalId) external view validProposalId(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getFractionalTokenAddress(uint256 _artworkId) external view validArtworkId(_artworkId) returns (address) {
        return artworks[_artworkId].fractionalTokenContract;
    }

    // Fallback function to receive Ether (if needed for direct ETH purchases or fees)
    receive() external payable {}
}
```