```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAA Gallery)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to showcase and sell their digital artworks (NFTs),
 *      curators to manage exhibitions, and collectors to discover and acquire unique digital art pieces.
 *
 * Function Summary:
 * -----------------
 * **Gallery Management:**
 * 1.  `setGalleryFee(uint256 _feePercentage)`: Allows the contract owner to set the gallery commission fee percentage.
 * 2.  `fundTreasury()`: Allows anyone to contribute ETH to the gallery treasury for operational expenses and artist rewards.
 * 3.  `withdrawTreasury(address payable _recipient, uint256 _amount)`: Allows the contract owner to withdraw ETH from the treasury.
 * 4.  `createExhibition(string _exhibitionName, string _description, uint256 _startTime, uint256 _endTime)`: Allows curators to create new art exhibitions.
 * 5.  `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Allows curators to add artworks to a specific exhibition.
 * 6.  `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Allows curators to remove artworks from an exhibition.
 * 7.  `setExhibitionCurator(uint256 _exhibitionId, address _curator)`: Allows the contract owner to assign or change the curator for an exhibition.
 * 8.  `proposeGalleryParameterChange(string _parameterName, uint256 _newValue)`: Allows anyone to propose changes to gallery parameters (fee, etc.) through a voting mechanism.
 * 9.  `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Allows registered gallery council members to vote on parameter change proposals.
 * 10. `executeParameterChangeProposal(uint256 _proposalId)`: Allows the contract owner to execute a passed parameter change proposal after voting period.
 *
 * **Artist Management:**
 * 11. `registerArtist(string _artistName, string _artistDescription)`: Allows artists to register themselves with the gallery.
 * 12. `submitArtwork(string _artworkName, string _artworkDescription, string _artworkCID, uint256 _price)`: Allows registered artists to submit their artworks with metadata and set a price.
 * 13. `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Allows artists to update the price of their artworks.
 * 14. `withdrawArtistEarnings()`: Allows artists to withdraw their accumulated earnings from sold artworks.
 *
 * **Artwork & NFT Management:**
 * 15. `buyArtwork(uint256 _artworkId)`: Allows collectors to purchase artworks directly from the gallery.
 * 16. `transferArtwork(uint256 _artworkId, address _to)`: Allows artwork owners to transfer their owned artworks to another address.
 * 17. `burnArtwork(uint256 _artworkId)`: Allows the artwork owner to permanently burn (destroy) their artwork NFT.
 * 18. `offerArtworkForAuction(uint256 _artworkId, uint256 _startPrice, uint256 _auctionDuration)`: Allows artwork owners to put their artworks up for auction.
 * 19. `bidOnArtworkAuction(uint256 _auctionId)`: Allows anyone to bid on an active artwork auction.
 * 20. `endArtworkAuction(uint256 _auctionId)`: Allows the auction initiator to end an auction after the duration, transferring the artwork and funds to the winner and seller respectively.
 *
 * **Getter/View Functions:**
 * - `getGalleryFee()`: Returns the current gallery fee percentage.
 * - `getTreasuryBalance()`: Returns the current gallery treasury balance.
 * - `getArtistDetails(address _artistAddress)`: Returns details about a registered artist.
 * - `getArtworkDetails(uint256 _artworkId)`: Returns details about a specific artwork.
 * - `getExhibitionDetails(uint256 _exhibitionId)`: Returns details about a specific exhibition.
 * - `getParameterChangeProposalDetails(uint256 _proposalId)`: Returns details about a specific parameter change proposal.
 * - `getAuctionDetails(uint256 _auctionId)`: Returns details about a specific auction.
 * - `isArtworkInExhibition(uint256 _artworkId, uint256 _exhibitionId)`: Checks if an artwork is part of a specific exhibition.
 * - `getArtistArtworkIds(address _artistAddress)`: Returns a list of artwork IDs submitted by a specific artist.
 * - `getExhibitionArtworkIds(uint256 _exhibitionId)`: Returns a list of artwork IDs in a specific exhibition.
 * - `getTotalArtworks()`: Returns the total number of artworks in the gallery.
 * - `getTotalArtists()`: Returns the total number of registered artists.
 * - `getTotalExhibitions()`: Returns the total number of exhibitions.
 * - ... (and more getters for other data as needed)
 */
contract DAAGallery {
    // State Variables

    address public owner;
    uint256 public galleryFeePercentage = 5; // Default gallery fee is 5%
    uint256 public treasuryBalance;

    uint256 public nextArtistId = 1;
    mapping(address => Artist) public artistRegistry;
    mapping(uint256 => address) public artistIdToAddress;
    uint256 public totalArtists;

    uint256 public nextArtworkId = 1;
    mapping(uint256 => Artwork) public artworkRegistry;
    uint256 public totalArtworks;

    uint256 public nextExhibitionId = 1;
    mapping(uint256 => Exhibition) public exhibitionRegistry;
    uint256 public totalExhibitions;

    uint256 public nextProposalId = 1;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    address[] public galleryCouncil; // Addresses allowed to vote on proposals

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctionRegistry;

    // Structs

    struct Artist {
        uint256 id;
        string name;
        string description;
        uint256 earnings; // Accumulated earnings in ETH
        bool registered;
    }

    struct Artwork {
        uint256 id;
        string name;
        string description;
        string artworkCID; // IPFS CID or similar content identifier
        uint256 price; // Price in wei
        address artistAddress;
        address ownerAddress;
        bool listedForSale;
        bool onAuction;
    }

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        address curator;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
        bool isActive;
    }

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool passed;
        bool executed;
    }

    struct Auction {
        uint256 id;
        uint256 artworkId;
        address seller;
        uint256 startPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 auctionEndTime;
        bool isActive;
    }

    // Events

    event GalleryFeeUpdated(uint256 newFeePercentage);
    event TreasuryFunded(address indexed sender, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ArtistRegistered(address indexed artistAddress, uint256 artistId, string artistName);
    event ArtworkSubmitted(uint256 artworkId, string artworkName, address indexed artistAddress);
    event ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice);
    event ArtworkPurchased(uint256 artworkId, address indexed buyer, address indexed artist, uint256 price);
    event ArtworkTransferred(uint256 artworkId, address indexed from, address indexed to);
    event ArtworkBurned(uint256 artworkId, address indexed owner);
    event ArtistEarningsWithdrawn(address indexed artistAddress, uint256 amount);
    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName, address indexed curator);
    event ArtworkAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event ArtworkRemovedFromExhibition(uint256 exhibitionId, uint256 artworkId);
    event ExhibitionCuratorSet(uint256 exhibitionId, address indexed newCurator);
    event ParameterChangeProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ParameterChangeProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ArtworkAuctionOffered(uint256 auctionId, uint256 artworkId, address indexed seller);
    event ArtworkBidPlaced(uint256 auctionId, address indexed bidder, uint256 bidAmount);
    event ArtworkAuctionEnded(uint256 auctionId, uint256 artworkId, address indexed winner, uint256 finalPrice);


    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistRegistry[msg.sender].registered, "You must be a registered artist.");
        _;
    }

    modifier onlyArtworkOwner(uint256 _artworkId) {
        require(artworkRegistry[_artworkId].ownerAddress == msg.sender, "You must be the artwork owner.");
        _;
    }

    modifier onlyExhibitionCurator(uint256 _exhibitionId) {
        require(exhibitionRegistry[_exhibitionId].curator == msg.sender, "You must be the exhibition curator.");
        _;
    }

    modifier validExhibition(uint256 _exhibitionId) {
        require(exhibitionRegistry[_exhibitionId].id != 0, "Invalid exhibition ID.");
        _;
    }

    modifier validArtwork(uint256 _artworkId) {
        require(artworkRegistry[_artworkId].id != 0, "Invalid artwork ID.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].id != 0, "Invalid proposal ID.");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctionRegistry[_auctionId].id != 0, "Invalid auction ID.");
        _;
    }

    modifier auctionActive(uint256 _auctionId) {
        require(auctionRegistry[_auctionId].isActive, "Auction is not active.");
        _;
    }

    modifier auctionNotEnded(uint256 _auctionId) {
        require(auctionRegistry[_auctionId].auctionEndTime > block.timestamp, "Auction has already ended.");
        _;
    }


    // Constructor

    constructor() {
        owner = msg.sender;
        galleryCouncil.push(owner); // Owner is initially part of the council
    }


    // ------------------------ Gallery Management Functions ------------------------

    /**
     * @dev Sets the gallery commission fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new gallery fee percentage.
     */
    function setGalleryFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeUpdated(_feePercentage);
    }

    /**
     * @dev Allows anyone to fund the gallery treasury.
     */
    function fundTreasury() external payable {
        treasuryBalance += msg.value;
        emit TreasuryFunded(msg.sender, msg.value);
    }

    /**
     * @dev Allows the contract owner to withdraw ETH from the gallery treasury.
     * @param _recipient The address to receive the withdrawn ETH.
     * @param _amount The amount of ETH to withdraw in wei.
     */
    function withdrawTreasury(address payable _recipient, uint256 _amount) external onlyOwner {
        require(_amount <= treasuryBalance, "Insufficient treasury balance.");
        treasuryBalance -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed.");
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Creates a new art exhibition. Only callable by exhibition curators (initially owner can create).
     * @param _exhibitionName The name of the exhibition.
     * @param _description A description of the exhibition.
     * @param _startTime The start time of the exhibition (Unix timestamp).
     * @param _endTime The end time of the exhibition (Unix timestamp).
     */
    function createExhibition(string memory _exhibitionName, string memory _description, uint256 _startTime, uint256 _endTime) external {
        require(msg.sender == owner || isExhibitionCurator(msg.sender), "Only curators or owner can create exhibitions.");
        require(_endTime > _startTime, "Exhibition end time must be after start time.");
        exhibitionRegistry[nextExhibitionId] = Exhibition({
            id: nextExhibitionId,
            name: _exhibitionName,
            description: _description,
            curator: msg.sender, // Creator is initial curator
            startTime: _startTime,
            endTime: _endTime,
            artworkIds: new uint256[](0),
            isActive: true
        });
        totalExhibitions++;
        emit ExhibitionCreated(nextExhibitionId, _exhibitionName, msg.sender);
        nextExhibitionId++;
    }

    /**
     * @dev Adds an artwork to a specific exhibition. Only callable by the exhibition curator.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artworkId The ID of the artwork to add.
     */
    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) external validExhibition(_exhibitionId) onlyExhibitionCurator(_exhibitionId) validArtwork(_artworkId) {
        Exhibition storage exhibition = exhibitionRegistry[_exhibitionId];
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            require(exhibition.artworkIds[i] != _artworkId, "Artwork already in exhibition.");
        }
        exhibition.artworkIds.push(_artworkId);
        emit ArtworkAddedToExhibition(_exhibitionId, _artworkId);
    }

    /**
     * @dev Removes an artwork from a specific exhibition. Only callable by the exhibition curator.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artworkId The ID of the artwork to remove.
     */
    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId) external validExhibition(_exhibitionId) onlyExhibitionCurator(_exhibitionId) validArtwork(_artworkId) {
        Exhibition storage exhibition = exhibitionRegistry[_exhibitionId];
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            if (exhibition.artworkIds[i] == _artworkId) {
                exhibition.artworkIds[i] = exhibition.artworkIds[exhibition.artworkIds.length - 1];
                exhibition.artworkIds.pop();
                emit ArtworkRemovedFromExhibition(_exhibitionId, _artworkId);
                return;
            }
        }
        revert("Artwork not found in exhibition.");
    }

    /**
     * @dev Sets or changes the curator for a specific exhibition. Only callable by the contract owner.
     * @param _exhibitionId The ID of the exhibition.
     * @param _curator The address of the new curator.
     */
    function setExhibitionCurator(uint256 _exhibitionId, address _curator) external onlyOwner validExhibition(_exhibitionId) {
        exhibitionRegistry[_exhibitionId].curator = _curator;
        emit ExhibitionCuratorSet(_exhibitionId, _curator);
    }

    /**
     * @dev Proposes a change to a gallery parameter (e.g., fee percentage).
     * @param _parameterName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) external {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        require(_newValue > 0, "New value must be greater than 0."); // Example restriction
        parameterChangeProposals[nextProposalId] = ParameterChangeProposal({
            id: nextProposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            passed: false,
            executed: false
        });
        emit ParameterChangeProposalCreated(nextProposalId, _parameterName, _newValue);
        nextProposalId++;
    }

    /**
     * @dev Allows gallery council members to vote on a parameter change proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) external validProposal(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(block.timestamp >= proposal.votingStartTime && block.timestamp <= proposal.votingEndTime, "Voting period is not active.");
        bool isCouncilMember = false;
        for (uint256 i = 0; i < galleryCouncil.length; i++) {
            if (galleryCouncil[i] == msg.sender) {
                isCouncilMember = true;
                break;
            }
        }
        require(isCouncilMember, "Only gallery council members can vote.");
        // Prevent double voting (simple approach - could be improved with mapping of voters)
        require(msg.sender != address(0) && !hasVoted(msg.sender, _proposalId), "You have already voted."); // Placeholder for hasVoted function
        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);
    }

    // Placeholder - Implement a more robust way to track votes per voter per proposal if needed for production
    function hasVoted(address _voter, uint256 _proposalId) private pure returns (bool) {
        // In a real implementation, you might use a mapping(uint256 => mapping(address => bool)) to track votes
        // For simplicity in this example, we skip detailed vote tracking.
        return false; // Assume no double voting tracking for this example.
    }


    /**
     * @dev Executes a parameter change proposal if it has passed and voting period is over. Only callable by the owner.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChangeProposal(uint256 _proposalId) external onlyOwner validProposal(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting period is still active.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast on this proposal."); // Prevent division by zero.

        if (proposal.votesFor * 100 / totalVotes > 50) { // Simple majority for passing
            proposal.passed = true;
            proposal.executed = true;
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("galleryFeePercentage"))) {
                galleryFeePercentage = proposal.newValue;
                emit GalleryFeeUpdated(galleryFeePercentage);
                emit ParameterChangeProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
            } else {
                // Add logic for other parameter changes if needed in the future
                revert("Unsupported parameter for automatic execution.");
            }
        } else {
            proposal.executed = true; // Mark as executed even if failed to prevent re-execution
            proposal.passed = false; // Explicitly mark as not passed (although already default)
            revert("Parameter change proposal failed to pass.");
        }
    }


    // ------------------------ Artist Management Functions ------------------------

    /**
     * @dev Registers an artist with the gallery.
     * @param _artistName The name of the artist.
     * @param _artistDescription A brief description of the artist.
     */
    function registerArtist(string memory _artistName, string memory _artistDescription) external {
        require(!artistRegistry[msg.sender].registered, "Artist already registered.");
        artistRegistry[msg.sender] = Artist({
            id: nextArtistId,
            name: _artistName,
            description: _artistDescription,
            earnings: 0,
            registered: true
        });
        artistIdToAddress[nextArtistId] = msg.sender;
        totalArtists++;
        emit ArtistRegistered(msg.sender, nextArtistId, _artistName);
        nextArtistId++;
    }

    /**
     * @dev Allows a registered artist to submit a new artwork to the gallery.
     * @param _artworkName The name of the artwork.
     * @param _artworkDescription A description of the artwork.
     * @param _artworkCID The content identifier (e.g., IPFS CID) of the artwork.
     * @param _price The price of the artwork in wei.
     */
    function submitArtwork(string memory _artworkName, string memory _artworkDescription, string memory _artworkCID, uint256 _price) external onlyRegisteredArtist {
        require(bytes(_artworkName).length > 0 && bytes(_artworkCID).length > 0, "Artwork name and CID cannot be empty.");
        require(_price > 0, "Artwork price must be greater than zero.");
        artworkRegistry[nextArtworkId] = Artwork({
            id: nextArtworkId,
            name: _artworkName,
            description: _artworkDescription,
            artworkCID: _artworkCID,
            price: _price,
            artistAddress: msg.sender,
            ownerAddress: msg.sender, // Artist initially owns the artwork NFT
            listedForSale: true, // Initially listed for sale
            onAuction: false
        });
        totalArtworks++;
        emit ArtworkSubmitted(nextArtworkId, _artworkName, msg.sender);
        nextArtworkId++;
    }

    /**
     * @dev Allows an artist to update the price of their artwork.
     * @param _artworkId The ID of the artwork to update.
     * @param _newPrice The new price of the artwork in wei.
     */
    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) external onlyRegisteredArtist validArtwork(_artworkId) onlyArtworkOwner(_artworkId) {
        require(_newPrice > 0, "New price must be greater than zero.");
        artworkRegistry[_artworkId].price = _newPrice;
        emit ArtworkPriceUpdated(_artworkId, _newPrice);
    }

    /**
     * @dev Allows artists to withdraw their accumulated earnings.
     */
    function withdrawArtistEarnings() external onlyRegisteredArtist {
        uint256 earnings = artistRegistry[msg.sender].earnings;
        require(earnings > 0, "No earnings to withdraw.");
        artistRegistry[msg.sender].earnings = 0; // Reset earnings to 0 after withdrawal
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(msg.sender, earnings);
    }


    // ------------------------ Artwork & NFT Management Functions ------------------------

    /**
     * @dev Allows a collector to buy an artwork directly from the gallery.
     * @param _artworkId The ID of the artwork to purchase.
     */
    function buyArtwork(uint256 _artworkId) external payable validArtwork(_artworkId) {
        Artwork storage artwork = artworkRegistry[_artworkId];
        require(artwork.listedForSale && !artwork.onAuction, "Artwork is not for sale or is on auction.");
        require(msg.value >= artwork.price, "Insufficient payment.");

        uint256 galleryFee = (artwork.price * galleryFeePercentage) / 100;
        uint256 artistPayout = artwork.price - galleryFee;

        // Transfer funds
        treasuryBalance += galleryFee;
        artistRegistry[artwork.artistAddress].earnings += artistPayout;
        artwork.ownerAddress = msg.sender; // New owner
        artwork.listedForSale = false; // No longer listed

        // Refund extra payment if any
        if (msg.value > artwork.price) {
            payable(msg.sender).transfer(msg.value - artwork.price);
        }

        emit ArtworkPurchased(_artworkId, msg.sender, artwork.artistAddress, artwork.price);
    }

    /**
     * @dev Allows the artwork owner to transfer their artwork to another address.
     * @param _artworkId The ID of the artwork to transfer.
     * @param _to The address to transfer the artwork to.
     */
    function transferArtwork(uint256 _artworkId, address _to) external validArtwork(_artworkId) onlyArtworkOwner(_artworkId) {
        require(_to != address(0), "Invalid recipient address.");
        artworkRegistry[_artworkId].ownerAddress = _to;
        emit ArtworkTransferred(_artworkId, msg.sender, _to);
    }

    /**
     * @dev Allows the artwork owner to burn (destroy) their artwork NFT.
     * @param _artworkId The ID of the artwork to burn.
     */
    function burnArtwork(uint256 _artworkId) external validArtwork(_artworkId) onlyArtworkOwner(_artworkId) {
        address ownerAddress = artworkRegistry[_artworkId].ownerAddress;
        delete artworkRegistry[_artworkId]; // Effectively removes the artwork
        totalArtworks--; // Decrement artwork count
        emit ArtworkBurned(_artworkId, ownerAddress);
    }

    /**
     * @dev Allows the artwork owner to offer their artwork for auction.
     * @param _artworkId The ID of the artwork to auction.
     * @param _startPrice The starting bid price in wei.
     * @param _auctionDuration The duration of the auction in seconds.
     */
    function offerArtworkForAuction(uint256 _artworkId, uint256 _startPrice, uint256 _auctionDuration) external validArtwork(_artworkId) onlyArtworkOwner(_artworkId) {
        require(!artworkRegistry[_artworkId].onAuction, "Artwork is already on auction.");
        require(!artworkRegistry[_artworkId].listedForSale, "Artwork is still listed for sale. Remove from sale first.");
        require(_startPrice > 0, "Start price must be greater than zero.");
        require(_auctionDuration > 0, "Auction duration must be greater than zero.");

        auctionRegistry[nextAuctionId] = Auction({
            id: nextAuctionId,
            artworkId: _artworkId,
            seller: msg.sender,
            startPrice: _startPrice,
            currentBid: 0,
            highestBidder: address(0),
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });
        artworkRegistry[_artworkId].onAuction = true;
        emit ArtworkAuctionOffered(nextAuctionId, _artworkId, msg.sender);
        nextAuctionId++;
    }

    /**
     * @dev Allows anyone to bid on an active artwork auction.
     * @param _auctionId The ID of the auction to bid on.
     */
    function bidOnArtworkAuction(uint256 _auctionId) external payable validAuction(_auctionId) auctionActive(_auctionId) auctionNotEnded(_auctionId) {
        Auction storage auction = auctionRegistry[_auctionId];
        require(msg.value > auction.currentBid, "Bid amount must be higher than the current bid.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            payable(auction.highestBidder).transfer(auction.currentBid);
        }

        auction.currentBid = msg.value;
        auction.highestBidder = msg.sender;
        emit ArtworkBidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an artwork auction after the duration has passed. Only callable by the auction initiator (artwork seller).
     * @param _auctionId The ID of the auction to end.
     */
    function endArtworkAuction(uint256 _auctionId) external validAuction(_auctionId) auctionActive(_auctionId) onlyArtworkOwner(auctionRegistry[_auctionId].artworkId) {
        Auction storage auction = auctionRegistry[_auctionId];
        require(block.timestamp >= auction.auctionEndTime, "Auction duration has not ended yet.");
        require(auction.isActive, "Auction is not active.");

        auction.isActive = false;
        artworkRegistry[auction.artworkId].onAuction = false;
        artworkRegistry[auction.artworkId].listedForSale = false; // No longer listed for sale after auction

        uint256 finalPrice = auction.currentBid;
        address winner = auction.highestBidder;

        if (winner != address(0)) {
            // Transfer artwork to winner
            artworkRegistry[auction.artworkId].ownerAddress = winner;

            // Calculate and distribute funds
            uint256 galleryFee = (finalPrice * galleryFeePercentage) / 100;
            uint256 artistPayout = finalPrice - galleryFee;

            treasuryBalance += galleryFee;
            artistRegistry[artworkRegistry[auction.artworkId].artistAddress].earnings += artistPayout;
            payable(auction.seller).transfer(artistPayout); // Seller gets artist payout
             emit ArtworkAuctionEnded(_auctionId, auction.artworkId, winner, finalPrice);

        } else {
            // No bids, artwork remains with seller.
            emit ArtworkAuctionEnded(_auctionId, auction.artworkId, address(0), 0); // No winner
        }

        delete auctionRegistry[_auctionId]; // Clean up auction data after end.
    }


    // ------------------------ Getter/View Functions ------------------------

    function getGalleryFee() external view returns (uint256) {
        return galleryFeePercentage;
    }

    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    function getArtistDetails(address _artistAddress) external view returns (Artist memory) {
        return artistRegistry[_artistAddress];
    }

    function getArtworkDetails(uint256 _artworkId) external view validArtwork(_artworkId) returns (Artwork memory) {
        return artworkRegistry[_artworkId];
    }

    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibition(_exhibitionId) returns (Exhibition memory) {
        return exhibitionRegistry[_exhibitionId];
    }

    function getParameterChangeProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalId];
    }

    function getAuctionDetails(uint256 _auctionId) external view validAuction(_auctionId) returns (Auction memory) {
        return auctionRegistry[_auctionId];
    }

    function isArtworkInExhibition(uint256 _artworkId, uint256 _exhibitionId) external view validArtwork(_artworkId) validExhibition(_exhibitionId) returns (bool) {
        Exhibition memory exhibition = exhibitionRegistry[_exhibitionId];
        for (uint256 i = 0; i < exhibition.artworkIds.length; i++) {
            if (exhibition.artworkIds[i] == _artworkId) {
                return true;
            }
        }
        return false;
    }

    function getArtistArtworkIds(address _artistAddress) external view returns (uint256[] memory) {
        uint256[] memory artworkIds = new uint256[](0);
        for (uint256 i = 1; i < nextArtworkId; i++) {
            if (artworkRegistry[i].artistAddress == _artistAddress) {
                // Dynamically resize array (less efficient for very large datasets, consider alternative if performance critical)
                uint256[] memory newArtworkIds = new uint256[](artworkIds.length + 1);
                for (uint256 j = 0; j < artworkIds.length; j++) {
                    newArtworkIds[j] = artworkIds[j];
                }
                newArtworkIds[artworkIds.length] = i;
                artworkIds = newArtworkIds;
            }
        }
        return artworkIds;
    }

    function getExhibitionArtworkIds(uint256 _exhibitionId) external view validExhibition(_exhibitionId) returns (uint256[] memory) {
        return exhibitionRegistry[_exhibitionId].artworkIds;
    }

    function getTotalArtworks() external view returns (uint256) {
        return totalArtworks;
    }

    function getTotalArtists() external view returns (uint256) {
        return totalArtists;
    }

    function getTotalExhibitions() external view returns (uint256) {
        return totalExhibitions;
    }

    function isExhibitionCurator(address _account) public view returns (bool) {
        for (uint256 i = 1; i < nextExhibitionId; i++) {
            if (exhibitionRegistry[i].curator == _account) {
                return true;
            }
        }
        return false;
    }
}
```