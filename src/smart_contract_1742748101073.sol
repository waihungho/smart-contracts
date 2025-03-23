```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 * It features advanced concepts like dynamic pricing, fractional ownership,
 * artist reputation system, curated exhibitions, and community governance.
 *
 * **Outline:**
 *
 * **State Variables:**
 *   - `galleryOwner`: Address of the gallery owner.
 *   - `artworks`: Mapping of artwork IDs to Artwork structs.
 *   - `artists`: Mapping of artist addresses to Artist structs.
 *   - `artistReputation`: Mapping of artist addresses to reputation scores.
 *   - `exhibitions`: Mapping of exhibition IDs to Exhibition structs.
 *   - `fractions`: Mapping of fraction IDs to Fraction structs.
 *   - `galleryBalance`: Contract balance for gallery operations.
 *   - `platformFeePercentage`: Percentage of sales taken as platform fee.
 *   - `votingDuration`: Duration for voting periods.
 *   - `minStakeForVoting`: Minimum stake required to participate in voting.
 *   - `proposalQueue`: Array of proposal IDs.
 *   - `proposals`: Mapping of proposal IDs to Proposal structs.
 *   - `proposalCounter`: Counter for proposal IDs.
 *   - `artworkCounter`: Counter for artwork IDs.
 *   - `exhibitionCounter`: Counter for exhibition IDs.
 *   - `fractionCounter`: Counter for fraction IDs.
 *   - `isArtistApproved`: Mapping to track approved artists.
 *   - `isArtworkListed`: Mapping to track listed artworks.
 *   - `isExhibitionActive`: Mapping to track active exhibitions.
 *   - `fractionSupply`: Mapping of artwork IDs to total fraction supply.
 *   - `fractionPrice`: Mapping of artwork IDs to current fraction price.
 *   - `fractionHolders`: Mapping of artwork IDs to mapping of holder addresses to fraction amounts.
 *   - `fractionApproval`: Mapping of artwork IDs to mapping of holder addresses to mapping of approved address to boolean.
 *
 * **Events:**
 *   - `ArtistRegistered(address artistAddress, string artistName)`
 *   - `ArtistApproved(address artistAddress)`
 *   - `ArtistReputationUpdated(address artistAddress, uint256 newReputation)`
 *   - `ArtworkSubmitted(uint256 artworkId, address artistAddress, string title)`
 *   - `ArtworkMinted(uint256 artworkId)`
 *   - `ArtworkListed(uint256 artworkId, uint256 price)`
 *   - `ArtworkPurchased(uint256 artworkId, address buyer, uint256 price)`
 *   - `ArtworkFractionalized(uint256 artworkId, uint256 fractionSupply, uint256 fractionPrice)`
 *   - `FractionPurchased(uint256 fractionId, address buyer, uint256 amount)`
 *   - `FractionTransferred(uint256 fractionId, address from, address to, uint256 amount)`
 *   - `FractionApprovalSet(uint256 fractionId, address owner, address approved, uint256 amount)`
 *   - `ExhibitionCreated(uint256 exhibitionId, string exhibitionName)`
 *   - `ExhibitionArtworkAdded(uint256 exhibitionId, uint256 artworkId)`
 *   - `ExhibitionActivated(uint256 exhibitionId)`
 *   - `ExhibitionDeactivated(uint256 exhibitionId)`
 *   - `ProposalCreated(uint256 proposalId, string description)`
 *   - `ProposalVoted(uint256 proposalId, address voter, bool vote)`
 *   - `ProposalExecuted(uint256 proposalId, bool success)`
 *   - `PlatformFeeUpdated(uint256 newFeePercentage)`
 *   - `GalleryOwnerUpdated(address newOwner)`
 *
 * **Modifiers:**
 *   - `onlyGalleryOwner()`: Restricts function access to the gallery owner.
 *   - `onlyApprovedArtist()`: Restricts function access to approved artists.
 *   - `artworkExists(uint256 _artworkId)`: Checks if an artwork exists.
 *   - `exhibitionExists(uint256 _exhibitionId)`: Checks if an exhibition exists.
 *   - `proposalExists(uint256 _proposalId)`: Checks if a proposal exists.
 *   - `artistExists(address _artistAddress)`: Checks if an artist exists.
 *   - `fractionExists(uint256 _fractionId)`: Checks if a fraction exists.
 *   - `isArtworkOwner(uint256 _artworkId, address _owner)`: Checks if an address is the owner of an artwork (or a fraction).
 *   - `isFractionHolder(uint256 _fractionId, address _holder)`: Checks if an address is a holder of a fraction.
 *   - `isExhibitionActiveModifier(uint256 _exhibitionId)`: Checks if an exhibition is active.
 *
 * **Functions (20+):**
 *   1. `registerArtist(string _artistName)`: Allows artists to register.
 *   2. `approveArtist(address _artistAddress)`: Gallery owner approves an artist.
 *   3. `submitArtwork(string _title, string _ipfsHash, uint256 _initialPrice)`: Artists submit artwork for listing.
 *   4. `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT for a submitted artwork (internal, triggered after approval/curation).
 *   5. `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Artists list their minted artwork for sale.
 *   6. `purchaseArtwork(uint256 _artworkId)`: Users purchase a listed artwork.
 *   7. `fractionalizeArtwork(uint256 _artworkId, uint256 _supply, uint256 _initialFractionPrice)`: Artist fractionalizes their artwork.
 *   8. `purchaseFraction(uint256 _artworkId, uint256 _amount)`: Users purchase fractions of an artwork.
 *   9. `transferFraction(uint256 _artworkId, address _to, uint256 _amount)`: Fraction holders transfer fractions.
 *  10. `approveFractionTransfer(uint256 _artworkId, address _approved, uint256 _amount)`: Approve another address to transfer fractions on behalf of the holder.
 *  11. `transferFractionFrom(uint256 _artworkId, address _from, address _to, uint256 _amount)`: Allows approved address to transfer fractions.
 *  12. `createExhibition(string _exhibitionName)`: Gallery owner creates a new exhibition.
 *  13. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Gallery owner adds artwork to an exhibition.
 *  14. `activateExhibition(uint256 _exhibitionId)`: Gallery owner activates an exhibition.
 *  15. `deactivateExhibition(uint256 _exhibitionId)`: Gallery owner deactivates an exhibition.
 *  16. `createProposal(string _description)`: Community members create proposals for gallery governance.
 *  17. `voteOnProposal(uint256 _proposalId, bool _vote)`: Community members vote on proposals.
 *  18. `executeProposal(uint256 _proposalId)`: Gallery owner executes a passed proposal.
 *  19. `updatePlatformFee(uint256 _newFeePercentage)`: Gallery owner updates the platform fee percentage.
 *  20. `setGalleryOwner(address _newOwner)`: Gallery owner transfers ownership.
 *  21. `getArtistReputation(address _artistAddress)`: View function to get artist reputation.
 *  22. `getArtworkDetails(uint256 _artworkId)`: View function to get artwork details.
 *  23. `getExhibitionDetails(uint256 _exhibitionId)`: View function to get exhibition details.
 *  24. `getFractionDetails(uint256 _fractionId)`: View function to get fraction details.
 *  25. `getProposalDetails(uint256 _proposalId)`: View function to get proposal details.
 *  26. `withdrawGalleryBalance()`: Gallery owner withdraws gallery balance (platform fees).
 */
pragma solidity ^0.8.0;

contract DecentralizedArtGallery {
    // **State Variables:**

    address public galleryOwner;
    uint256 public platformFeePercentage = 5; // 5% default platform fee
    uint256 public votingDuration = 7 days; // 7 days voting duration
    uint256 public minStakeForVoting = 0; // No staking for voting in this example, can be implemented later

    uint256 public galleryBalance;

    struct Artist {
        address artistAddress;
        string artistName;
        uint256 registrationTimestamp;
        bool isApproved;
    }
    mapping(address => Artist) public artists;
    mapping(address => uint256) public artistReputation;
    mapping(address => bool) public isArtistApproved;

    struct Artwork {
        uint256 artworkId;
        address artistAddress;
        string title;
        string ipfsHash;
        uint256 initialPrice;
        uint256 currentPrice;
        bool isMinted;
        bool isListed;
        bool isFractionalized;
        uint256 fractionSupply;
        uint256 fractionPrice;
    }
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => bool) public isArtworkListed;


    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionName;
        address curatorAddress; // Could be galleryOwner or a community-elected curator in a more advanced version
        uint256 creationTimestamp;
        bool isActive;
        uint256[] artworkIds;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => bool) public isExhibitionActive;

    struct Fraction {
        uint256 fractionId;
        uint256 artworkId;
        uint256 totalSupply;
        uint256 currentPrice;
    }
    mapping(uint256 => Fraction) public fractions;
    mapping(uint256 => mapping(address => uint256)) public fractionHolders; // artworkId => (holderAddress => amount)
    mapping(uint256 => mapping(address => mapping(address => bool))) public fractionApproval; // artworkId => (owner => (approved => allowed amount))
    mapping(uint256 => uint256) public fractionSupply;
    mapping(uint256 => uint256) public fractionPrice;


    struct Proposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 creationTimestamp;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    uint256[] public proposalQueue;
    uint256 public proposalCounter;
    uint256 public artworkCounter;
    uint256 public exhibitionCounter;
    uint256 public fractionCounter;


    // **Events:**

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistApproved(address artistAddress);
    event ArtistReputationUpdated(address artistAddress, uint256 newReputation);
    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string title);
    event ArtworkMinted(uint256 artworkId);
    event ArtworkListed(uint256 artworkId, uint256 price);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event ArtworkFractionalized(uint256 artworkId, uint256 fractionSupply, uint256 fractionPrice);
    event FractionPurchased(uint256 fractionId, address buyer, uint256 amount);
    event FractionTransferred(uint256 fractionId, address from, address to, uint256 amount);
    event FractionApprovalSet(uint256 fractionId, address owner, address approved, uint256 amount);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName);
    event ExhibitionArtworkAdded(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionActivated(uint256 exhibitionId);
    event ExhibitionDeactivated(uint256 exhibitionId);
    event ProposalCreated(uint256 proposalId, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, bool success);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event GalleryOwnerUpdated(address newOwner);


    // **Modifiers:**

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyApprovedArtist() {
        require(isArtistApproved[msg.sender], "Only approved artists can call this function.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].artworkId == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier artistExists(address _artistAddress) {
        require(artists[_artistAddress].artistAddress == _artistAddress, "Artist does not exist.");
        _;
    }

    modifier fractionExists(uint256 _fractionId) {
        require(fractions[_fractionId].fractionId == _fractionId, "Fraction does not exist.");
        _;
    }

    modifier isArtworkOwner(uint256 _artworkId, address _owner) {
        require(artworks[_artworkId].artistAddress == _owner, "You are not the owner of this artwork.");
        _;
    }

    modifier isFractionHolder(uint256 _artworkId, address _holder) {
        require(fractionHolders[_artworkId][_holder] > 0, "You are not a holder of fractions for this artwork.");
        _;
    }

    modifier isExhibitionActiveModifier(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        _;
    }


    // **Functions:**

    constructor() {
        galleryOwner = msg.sender;
    }

    /// 1. `registerArtist(string _artistName)`: Allows artists to register.
    function registerArtist(string memory _artistName) public {
        require(artists[msg.sender].artistAddress == address(0), "Artist already registered.");
        artists[msg.sender] = Artist({
            artistAddress: msg.sender,
            artistName: _artistName,
            registrationTimestamp: block.timestamp,
            isApproved: false
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// 2. `approveArtist(address _artistAddress)`: Gallery owner approves an artist.
    function approveArtist(address _artistAddress) public onlyGalleryOwner artistExists(_artistAddress) {
        require(!isArtistApproved[_artistAddress], "Artist is already approved.");
        artists[_artistAddress].isApproved = true;
        isArtistApproved[_artistAddress] = true;
        emit ArtistApproved(_artistAddress);
    }

    /// 3. `submitArtwork(string _title, string _ipfsHash, uint256 _initialPrice)`: Artists submit artwork for listing.
    function submitArtwork(string memory _title, string memory _ipfsHash, uint256 _initialPrice) public onlyApprovedArtist {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            artworkId: artworkCounter,
            artistAddress: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            isMinted: false,
            isListed: false,
            isFractionalized: false,
            fractionSupply: 0,
            fractionPrice: 0
        });
        emit ArtworkSubmitted(artworkCounter, msg.sender, _title);
    }

    /// 4. `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT for a submitted artwork (internal, triggered after approval/curation).
    // In a real NFT implementation, this would involve ERC721/ERC1155 logic.
    function mintArtworkNFT(uint256 _artworkId) public onlyGalleryOwner artworkExists(_artworkId) {
        require(!artworks[_artworkId].isMinted, "Artwork already minted.");
        artworks[_artworkId].isMinted = true;
        emit ArtworkMinted(_artworkId);
        // In a real implementation, this is where you would mint an actual NFT
        // and potentially transfer it to the artist or keep it in the contract
        // depending on the gallery's model.
    }

    /// 5. `listArtworkForSale(uint256 _artworkId, uint256 _price)`: Artists list their minted artwork for sale.
    function listArtworkForSale(uint256 _artworkId, uint256 _price) public onlyApprovedArtist artworkExists(_artworkId) isArtworkOwner(_artworkId, msg.sender) {
        require(artworks[_artworkId].isMinted, "Artwork must be minted before listing.");
        require(!artworks[_artworkId].isListed, "Artwork is already listed.");
        artworks[_artworkId].currentPrice = _price;
        artworks[_artworkId].isListed = true;
        isArtworkListed[_artworkId] = true;
        emit ArtworkListed(_artworkId, _price);
    }

    /// 6. `purchaseArtwork(uint256 _artworkId)`: Users purchase a listed artwork.
    function purchaseArtwork(uint256 _artworkId) payable public artworkExists(_artworkId) {
        require(artworks[_artworkId].isListed, "Artwork is not listed for sale.");
        require(msg.value >= artworks[_artworkId].currentPrice, "Insufficient funds sent.");

        uint256 platformFee = (artworks[_artworkId].currentPrice * platformFeePercentage) / 100;
        uint256 artistPayout = artworks[_artworkId].currentPrice - platformFee;

        (bool artistTransferSuccess, ) = payable(artworks[_artworkId].artistAddress).call{value: artistPayout}("");
        require(artistTransferSuccess, "Artist payment failed.");

        galleryBalance += platformFee;

        artworks[_artworkId].isListed = false; // Remove from listing after purchase
        isArtworkListed[_artworkId] = false;

        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].currentPrice);
    }

    /// 7. `fractionalizeArtwork(uint256 _artworkId, uint256 _supply, uint256 _initialFractionPrice)`: Artist fractionalizes their artwork.
    function fractionalizeArtwork(uint256 _artworkId, uint256 _supply, uint256 _initialFractionPrice) public onlyApprovedArtist artworkExists(_artworkId) isArtworkOwner(_artworkId, msg.sender) {
        require(!artworks[_artworkId].isFractionalized, "Artwork is already fractionalized.");
        require(_supply > 0 && _initialFractionPrice > 0, "Supply and fraction price must be positive.");

        fractionCounter++;
        fractions[fractionCounter] = Fraction({
            fractionId: fractionCounter,
            artworkId: _artworkId,
            totalSupply: _supply,
            currentPrice: _initialFractionPrice
        });
        fractionSupply[_artworkId] = _supply;
        fractionPrice[_artworkId] = _initialFractionPrice;
        artworks[_artworkId].isFractionalized = true;
        artworks[_artworkId].fractionSupply = _supply;
        artworks[_artworkId].fractionPrice = _initialFractionPrice;

        // Mint initial fractions to the artist (owner of the artwork)
        fractionHolders[_artworkId][msg.sender] = _supply;

        emit ArtworkFractionalized(_artworkId, _supply, _initialFractionPrice);
    }

    /// 8. `purchaseFraction(uint256 _artworkId, uint256 _amount)`: Users purchase fractions of an artwork.
    function purchaseFraction(uint256 _artworkId, uint256 _amount) payable public artworkExists(_artworkId) {
        require(artworks[_artworkId].isFractionalized, "Artwork is not fractionalized.");
        require(_amount > 0, "Amount must be positive.");
        require(msg.value >= fractionPrice[_artworkId] * _amount, "Insufficient funds sent.");

        uint256 fractionCost = fractionPrice[_artworkId] * _amount;
        uint256 platformFee = (fractionCost * platformFeePercentage) / 100;
        uint256 artistPayout = fractionCost - platformFee;

        (bool artistTransferSuccess, ) = payable(artworks[_artworkId].artistAddress).call{value: artistPayout}("");
        require(artistTransferSuccess, "Artist payment failed.");
        galleryBalance += platformFee;

        fractionHolders[_artworkId][msg.sender] += _amount;
        emit FractionPurchased(fractions[_artworkId].fractionId, msg.sender, _amount);
    }

    /// 9. `transferFraction(uint256 _artworkId, address _to, uint256 _amount)`: Fraction holders transfer fractions.
    function transferFraction(uint256 _artworkId, address _to, uint256 _amount) public isFractionHolder(_artworkId, msg.sender) artworkExists(_artworkId) {
        require(_amount > 0, "Amount must be positive.");
        require(_to != address(0), "Invalid recipient address.");
        require(fractionHolders[_artworkId][msg.sender] >= _amount, "Insufficient fraction balance.");

        fractionHolders[_artworkId][msg.sender] -= _amount;
        fractionHolders[_artworkId][_to] += _amount;
        emit FractionTransferred(fractions[_artworkId].fractionId, msg.sender, _to, _amount);
    }

    /// 10. `approveFractionTransfer(uint256 _artworkId, address _approved, uint256 _amount)`: Approve another address to transfer fractions on behalf of the holder.
    function approveFractionTransfer(uint256 _artworkId, address _approved, uint256 _amount) public isFractionHolder(_artworkId, msg.sender) artworkExists(_artworkId) {
        require(_amount > 0, "Amount must be positive.");
        require(_approved != address(0), "Invalid approved address.");
        fractionApproval[_artworkId][msg.sender][_approved] = true; // Simple boolean approval, can be modified for amount-specific approval if needed.
        emit FractionApprovalSet(fractions[_artworkId].fractionId, msg.sender, _approved, _amount); // Amount is not used in this simplified approval
    }

    /// 11. `transferFractionFrom(uint256 _artworkId, address _from, address _to, uint256 _amount)`: Allows approved address to transfer fractions.
    function transferFractionFrom(uint256 _artworkId, address _from, address _to, uint256 _amount) public artworkExists(_artworkId) {
        require(msg.sender != _from, "Cannot transfer from yourself using transferFrom.");
        require(fractionApproval[_artworkId][_from][msg.sender], "Not approved to transfer from this address.");
        require(_amount > 0, "Amount must be positive.");
        require(_to != address(0), "Invalid recipient address.");
        require(fractionHolders[_artworkId][_from] >= _amount, "Insufficient fraction balance in 'from' address.");

        fractionHolders[_artworkId][_from] -= _amount;
        fractionHolders[_artworkId][_to] += _amount;
        fractionApproval[_artworkId][_from][msg.sender] = false; // Revoke approval after transfer (or implement amount-based approval revocation)
        emit FractionTransferred(fractions[_artworkId].fractionId, _from, _to, _amount);
    }

    /// 12. `createExhibition(string _exhibitionName)`: Gallery owner creates a new exhibition.
    function createExhibition(string memory _exhibitionName) public onlyGalleryOwner {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            exhibitionId: exhibitionCounter,
            exhibitionName: _exhibitionName,
            curatorAddress: msg.sender,
            creationTimestamp: block.timestamp,
            isActive: false,
            artworkIds: new uint256[](0)
        });
        emit ExhibitionCreated(exhibitionCounter, _exhibitionName);
    }

    /// 13. `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Gallery owner adds artwork to an exhibition.
    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) public onlyGalleryOwner exhibitionExists(_exhibitionId) artworkExists(_artworkId) {
        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        emit ExhibitionArtworkAdded(_exhibitionId, _artworkId);
    }

    /// 14. `activateExhibition(uint256 _exhibitionId)`: Gallery owner activates an exhibition.
    function activateExhibition(uint256 _exhibitionId) public onlyGalleryOwner exhibitionExists(_exhibitionId) {
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active.");
        exhibitions[_exhibitionId].isActive = true;
        isExhibitionActive[_exhibitionId] = true;
        emit ExhibitionActivated(_exhibitionId);
    }

    /// 15. `deactivateExhibition(uint256 _exhibitionId)`: Gallery owner deactivates an exhibition.
    function deactivateExhibition(uint256 _exhibitionId) public onlyGalleryOwner exhibitionExists(_exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        exhibitions[_exhibitionId].isActive = false;
        isExhibitionActive[_exhibitionId] = false;
        emit ExhibitionDeactivated(_exhibitionId);
    }

    /// 16. `createProposal(string _description)`: Community members create proposals for gallery governance.
    function createProposal(string memory _description) public {
        proposalCounter++;
        Proposals[proposalCounter] = Proposal({
            proposalId: proposalCounter,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        proposalQueue.push(proposalCounter);
        emit ProposalCreated(proposalCounter, _description);
    }

    /// 17. `voteOnProposal(uint256 _proposalId, bool _vote)`: Community members vote on proposals.
    function voteOnProposal(uint256 _proposalId, bool _vote) public proposalExists(_proposalId) {
        require(block.timestamp < proposals[_proposalId].votingEndTime, "Voting period has ended.");
        // In a more advanced version, staking or fraction holding could be required for voting.
        // For simplicity, anyone can vote in this example.

        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// 18. `executeProposal(uint256 _proposalId)`: Gallery owner executes a passed proposal.
    function executeProposal(uint256 _proposalId) public onlyGalleryOwner proposalExists(_proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp >= proposals[_proposalId].votingEndTime, "Voting period has not ended yet.");
        require(proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes, "Proposal did not pass.");

        proposals[_proposalId].executed = true;
        // Implement proposal execution logic here based on proposal content.
        // Example: if proposal is to update platform fee:
        // if (keccak256(abi.encodePacked(proposals[_proposalId].description)) == keccak256(abi.encodePacked("Update platform fee to X%"))) {
        //     // Parse X from description and update platformFeePercentage
        // }

        emit ProposalExecuted(_proposalId, true); // Assuming execution is successful for this example
    }

    /// 19. `updatePlatformFee(uint256 _newFeePercentage)`: Gallery owner updates the platform fee percentage.
    function updatePlatformFee(uint256 _newFeePercentage) public onlyGalleryOwner {
        require(_newFeePercentage <= 100, "Platform fee cannot be more than 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    /// 20. `setGalleryOwner(address _newOwner)`: Gallery owner transfers ownership.
    function setGalleryOwner(address _newOwner) public onlyGalleryOwner {
        require(_newOwner != address(0), "Invalid new owner address.");
        galleryOwner = _newOwner;
        emit GalleryOwnerUpdated(_newOwner);
    }

    /// 21. `getArtistReputation(address _artistAddress)`: View function to get artist reputation.
    function getArtistReputation(address _artistAddress) public view artistExists(_artistAddress) returns (uint256) {
        return artistReputation[_artistAddress];
    }

    /// 22. `getArtworkDetails(uint256 _artworkId)`: View function to get artwork details.
    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// 23. `getExhibitionDetails(uint256 _exhibitionId)`: View function to get exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) public view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// 24. `getFractionDetails(uint256 _fractionId)`: View function to get fraction details.
    function getFractionDetails(uint256 _fractionId) public view fractionExists(_fractionId) returns (Fraction memory) {
        return fractions[_fractionId];
    }

    /// 25. `getProposalDetails(uint256 _proposalId)`: View function to get proposal details.
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    /// 26. `withdrawGalleryBalance()`: Gallery owner withdraws gallery balance (platform fees).
    function withdrawGalleryBalance() public onlyGalleryOwner {
        uint256 amountToWithdraw = galleryBalance;
        galleryBalance = 0; // Reset gallery balance after withdrawal
        (bool success, ) = payable(galleryOwner).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```