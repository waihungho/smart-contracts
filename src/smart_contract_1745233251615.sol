```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Gemini AI
 * @dev A smart contract for a decentralized autonomous art gallery, incorporating advanced concepts like on-chain auctions,
 *      dynamic royalty splits, collaborative art creation, tokenized curation, and community governance through proposals.
 *
 * **Outline and Function Summary:**
 *
 * **1. Gallery Management:**
 *    - `setGalleryName(string _name)`: Sets the name of the art gallery (Only Gallery Owner).
 *    - `setGalleryFee(uint256 _feePercentage)`: Sets the gallery commission fee percentage for sales (Only Gallery Owner).
 *    - `withdrawGalleryBalance()`: Allows the gallery owner to withdraw accumulated gallery fees (Only Gallery Owner).
 *
 * **2. Artist Management:**
 *    - `registerArtist()`: Allows users to register as artists in the gallery.
 *    - `isRegisteredArtist(address _artist) view returns (bool)`: Checks if an address is a registered artist.
 *    - `setArtistRoyalty(uint256 _royaltyPercentage)`: Allows artists to set their default royalty percentage (Only Artist).
 *    - `getArtistRoyalty(address _artist) view returns (uint256)`: Retrieves an artist's royalty percentage.
 *
 * **3. Art Submission & Curation:**
 *    - `submitArt(string _title, string _description, string _ipfsHash, uint256 _initialPrice, address[] _collaborators, uint256[] _collaboratorShares)`: Artists submit artwork for consideration, including collaborators and royalty splits.
 *    - `voteOnArtSubmission(uint256 _artId, bool _approve)`: Registered curators can vote to approve or reject art submissions (Only Curator).
 *    - `addCurator(address _curator)`: Allows the Gallery Owner to add addresses as curators.
 *    - `removeCurator(address _curator)`: Allows the Gallery Owner to remove addresses as curators.
 *    - `isCurator(address _curator) view returns (bool)`: Checks if an address is a curator.
 *    - `listPendingArtSubmissions() view returns (uint256[])`: Returns IDs of art submissions awaiting curation.
 *    - `listApprovedArt() view returns (uint256[])`: Returns IDs of art that has been approved and is available in the gallery.
 *    - `getArtDetails(uint256 _artId) view returns (Art)`: Retrieves detailed information about a specific artwork.
 *
 * **4. Marketplace & Sales:**
 *    - `purchaseArt(uint256 _artId)`: Allows users to purchase approved artwork directly at the listed price.
 *    - `offerBid(uint256 _artId)`: Allows users to place a bid on artwork (starts an auction if no active auction).
 *    - `acceptBid(uint256 _artId, uint256 _bidId)`: Allows the artist to accept a specific bid for their artwork (Only Artist).
 *    - `buyNow(uint256 _artId)`: Allows users to buy artwork at the current "Buy Now" price if available (cancels active auction).
 *    - `setBuyNowPrice(uint256 _artId, uint256 _price)`: Allows artists to set or update a "Buy Now" price for their artwork (Only Artist).
 *    - `removeBuyNowPrice(uint256 _artId)`: Allows artists to remove the "Buy Now" price, making it auction-only (Only Artist).
 *
 * **5. Auction Functionality (Dutch Auction Concept - could be extended):**
 *    - `startDutchAuction(uint256 _artId, uint256 _startingPrice, uint256 _priceDropPerBlock, uint256 _durationInBlocks)`: Artist can initiate a Dutch Auction for their approved artwork (Only Artist).
 *    - `participateInDutchAuction(uint256 _artId)`: Users can participate in a Dutch Auction and purchase art at the current price.
 *    - `cancelAuction(uint256 _artId)`: Artist can cancel an ongoing auction (Only Artist, with potential penalties if bids exist - not implemented here for simplicity but can be added).
 *    - `getAuctionDetails(uint256 _artId) view returns (Auction)`: Retrieves details of an active auction for a given artwork.
 *
 * **6. Community Governance & Proposals (Simplified Proposal System):**
 *    - `createProposal(string _title, string _description, ProposalType _proposalType, bytes calldata _data)`:  Registered users can create governance proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _support)`: Registered users can vote on active proposals.
 *    - `executeProposal(uint256 _proposalId)`: Gallery Owner can execute a passed proposal (Simplified execution - more complex logic can be added).
 *    - `getProposalDetails(uint256 _proposalId) view returns (Proposal)`: Retrieves details of a specific governance proposal.
 *    - `listActiveProposals() view returns (uint256[])`: Returns IDs of proposals that are currently active for voting.
 *
 * **7. Royalty Management & Payouts:**
 *    - `distributeRoyalties(uint256 _artId, uint256 _salePrice)`: Internal function to distribute royalties to artists and collaborators after a sale.
 *    - `withdrawArtistEarnings()`: Artists can withdraw their accumulated earnings from sales and royalties (Only Artist).
 *
 * **8. Tokenized Curation (Conceptual - Simplified for demonstration):**
 *    - `stakeForCuration()`: Users can stake ETH to become eligible as curators (Simplified - can be token-based and more complex).
 *    - `unstakeFromCuration()`: Users can unstake ETH from curation.
 *    - `getCurationStake(address _user) view returns (uint256)`: Retrieves the stake amount of a user for curation.
 *
 * **9. Collaborative Art Enhancements:**
 *    - `addCollaborator(uint256 _artId, address _collaborator, uint256 _share)`: Artist can add collaborators to existing artwork (Only Artist, before any sale).
 *    - `updateCollaboratorShare(uint256 _artId, address _collaborator, uint256 _newShare)`: Artist can update collaborator shares (Only Artist, before any sale).
 *    - `removeCollaborator(uint256 _artId, address _collaborator)`: Artist can remove a collaborator (Only Artist, before any sale).
 *
 * **10. Event Logging:**
 *     - Events are emitted for key actions like art submission, approval, purchase, bids, auctions, proposals, etc. for off-chain monitoring.
 */
pragma solidity ^0.8.0;

contract DecentralizedAutonomousArtGallery {
    string public galleryName = "Decentralized Art Haven";
    address public galleryOwner;
    uint256 public galleryFeePercentage = 5; // Default 5% gallery fee
    uint256 public galleryBalance;

    uint256 public nextArtId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextBidId = 1;

    mapping(uint256 => Art) public artCatalog;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => Auction) public activeAuctions;
    mapping(uint256 => mapping(uint256 => Bid)) public artBids; // artId => bidId => Bid
    mapping(address => bool) public registeredArtists;
    mapping(address => bool) public curators;
    mapping(address => uint256) public curationStake; // Simplified staking for curation eligibility
    mapping(address => uint256) public artistEarnings;

    struct Art {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        address artist;
        uint256 initialPrice;
        uint256 buyNowPrice;
        bool isApproved;
        bool onSale;
        address[] collaborators;
        uint256[] collaboratorShares; // Percentage shares out of 10000 (e.g., 5000 = 50%)
    }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        ProposalType proposalType;
        bytes data; // Generic data for proposal execution
        uint256 voteCount;
        uint256 againstVoteCount;
        bool isActive;
        bool isExecuted;
    }

    enum ProposalType {
        GALLERY_FEE_CHANGE,
        CURATOR_ADDITION,
        CURATOR_REMOVAL,
        OTHER // Example for extensibility
    }

    struct Auction {
        uint256 artId;
        AuctionType auctionType;
        uint256 startTime;
        uint256 endTime; // For fixed duration auctions
        uint256 startingPrice;
        uint256 currentPrice; // For Dutch auctions
        uint256 priceDropPerBlock; // For Dutch auctions
        uint256 durationInBlocks; // For Dutch auctions
        bool isActive;
    }

    enum AuctionType {
        DUTCH // Example - can add English Auction etc.
    }

    struct Bid {
        uint256 id;
        uint256 artId;
        address bidder;
        uint256 bidAmount;
        uint256 timestamp;
    }

    event GalleryNameChanged(string newName);
    event GalleryFeeChanged(uint256 newFeePercentage);
    event GalleryBalanceWithdrawn(uint256 amount, address recipient);

    event ArtistRegistered(address artist);
    event ArtistRoyaltySet(address artist, uint256 royaltyPercentage);

    event ArtSubmitted(uint256 artId, address artist, string title);
    event ArtApproved(uint256 artId);
    event ArtRejected(uint256 artId);
    event CuratorAdded(address curator);
    event CuratorRemoved(address curator);

    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event BidOffered(uint256 artId, uint256 bidId, address bidder, uint256 amount);
    event BidAccepted(uint256 artId, uint256 bidId, address artist, address bidder, uint256 amount);
    event BuyNowPriceSet(uint256 artId, uint256 price);
    event BuyNowPriceRemoved(uint256 artId);

    event DutchAuctionStarted(uint256 artId, uint256 startingPrice, uint256 priceDropPerBlock, uint256 durationInBlocks);
    event DutchAuctionParticipation(uint256 artId, address participant, uint256 price);
    event AuctionCancelled(uint256 artId);

    event ProposalCreated(uint256 proposalId, string title, ProposalType proposalType);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);

    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event CurationStakeIncreased(address user, uint256 amount);
    event CurationStakeDecreased(address user, uint256 amount);

    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can perform this action.");
        _;
    }

    modifier onlyArtist() {
        require(registeredArtists[msg.sender], "Only registered artists can perform this action.");
        _;
    }

    modifier artExists(uint256 _artId) {
        require(_artId > 0 && _artId < nextArtId && artCatalog[_artId].id == _artId, "Art does not exist.");
        _;
    }

    modifier artNotApproved(uint256 _artId) {
        require(!artCatalog[_artId].isApproved, "Art is already approved.");
        _;
    }

    modifier artApproved(uint256 _artId) {
        require(artCatalog[_artId].isApproved, "Art is not approved yet.");
        _;
    }

    modifier artOnSale(uint256 _artId) {
        require(artCatalog[_artId].onSale, "Art is not currently on sale.");
        _;
    }

    modifier notGalleryOwner() {
        require(msg.sender != galleryOwner, "Gallery owner cannot perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId && proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active.");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].isExecuted, "Proposal is already executed.");
        _;
    }

    modifier auctionActive(uint256 _artId) {
        require(activeAuctions[_artId].isActive, "No active auction for this art.");
        _;
    }

    constructor() {
        galleryOwner = msg.sender;
        curators[msg.sender] = true; // Gallery owner is also a curator by default
    }

    // -------------------- 1. Gallery Management --------------------
    function setGalleryName(string memory _name) external onlyGalleryOwner {
        galleryName = _name;
        emit GalleryNameChanged(_name);
    }

    function setGalleryFee(uint256 _feePercentage) external onlyGalleryOwner {
        require(_feePercentage <= 100, "Gallery fee percentage must be between 0 and 100.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeChanged(_feePercentage);
    }

    function withdrawGalleryBalance() external onlyGalleryOwner {
        uint256 amount = galleryBalance;
        galleryBalance = 0;
        payable(galleryOwner).transfer(amount);
        emit GalleryBalanceWithdrawn(amount, galleryOwner);
    }

    // -------------------- 2. Artist Management --------------------
    function registerArtist() external notGalleryOwner {
        require(!registeredArtists[msg.sender], "Already registered as an artist.");
        registeredArtists[msg.sender] = true;
        emit ArtistRegistered(msg.sender);
    }

    function isRegisteredArtist(address _artist) external view returns (bool) {
        return registeredArtists[_artist];
    }

    function setArtistRoyalty(uint256 _royaltyPercentage) external onlyArtist {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        // In a real system, store royalty per art, but for simplicity, using default artist royalty.
        // For this example, we are not storing it, but you could store it in a mapping `artistRoyalties[msg.sender] = _royaltyPercentage;`
        emit ArtistRoyaltySet(msg.sender, _royaltyPercentage);
    }

    function getArtistRoyalty(address _artist) external view returns (uint256) {
        // In a real system, retrieve royalty per art or default artist royalty.
        // For this example, returning a default value for simplicity.
        return 90; // Default 90% royalty for artists (example)
    }

    // -------------------- 3. Art Submission & Curation --------------------
    function submitArt(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice,
        address[] memory _collaborators,
        uint256[] memory _collaboratorShares
    ) external onlyArtist {
        require(_initialPrice > 0, "Initial price must be greater than 0.");
        require(_collaborators.length == _collaboratorShares.length, "Collaborators and shares arrays must have the same length.");
        uint256 totalShares = 0;
        for (uint256 i = 0; i < _collaboratorShares.length; i++) {
            totalShares += _collaboratorShares[i];
        }
        require(totalShares <= 10000, "Total collaborator shares cannot exceed 100%.");

        artCatalog[nextArtId] = Art({
            id: nextArtId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            artist: msg.sender,
            initialPrice: _initialPrice,
            buyNowPrice: 0, // Initially no "Buy Now" price
            isApproved: false,
            onSale: false,
            collaborators: _collaborators,
            collaboratorShares: _collaboratorShares
        });
        emit ArtSubmitted(nextArtId, msg.sender, _title);
        nextArtId++;
    }

    function voteOnArtSubmission(uint256 _artId, bool _approve) external onlyCurator artExists(_artId) artNotApproved(_artId) {
        if (_approve) {
            artCatalog[_artId].isApproved = true;
            emit ArtApproved(_artId);
        } else {
            emit ArtRejected(_artId); // Can add rejection logic/reasons if needed
            // Optionally, could delete the art submission if rejected: delete artCatalog[_artId];
        }
    }

    function addCurator(address _curator) external onlyGalleryOwner {
        curators[_curator] = true;
        emit CuratorAdded(_curator);
    }

    function removeCurator(address _curator) external onlyGalleryOwner {
        require(_curator != galleryOwner, "Cannot remove the gallery owner as curator.");
        delete curators[_curator];
        emit CuratorRemoved(_curator);
    }

    function isCurator(address _curator) external view returns (bool) {
        return curators[_curator];
    }

    function listPendingArtSubmissions() external view returns (uint256[] memory) {
        uint256[] memory pendingArtIds = new uint256[](nextArtId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtId; i++) {
            if (!artCatalog[i].isApproved && artCatalog[i].id == i) {
                pendingArtIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of pending submissions
        assembly {
            mstore(pendingArtIds, count) // Update the length of the array
        }
        return pendingArtIds;
    }

    function listApprovedArt() external view returns (uint256[] memory) {
        uint256[] memory approvedArtIds = new uint256[](nextArtId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtId; i++) {
            if (artCatalog[i].isApproved && artCatalog[i].id == i) {
                approvedArtIds[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of approved art pieces
        assembly {
            mstore(approvedArtIds, count) // Update the length of the array
        }
        return approvedArtIds;
    }


    function getArtDetails(uint256 _artId) external view artExists(_artId) returns (Art memory) {
        return artCatalog[_artId];
    }

    // -------------------- 4. Marketplace & Sales --------------------
    function purchaseArt(uint256 _artId) external payable artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        uint256 price = artCatalog[_artId].buyNowPrice > 0 ? artCatalog[_artId].buyNowPrice : artCatalog[_artId].initialPrice;
        require(msg.value >= price, "Insufficient funds sent.");
        require(activeAuctions[_artId].isActive == false, "Cannot purchase art with active auction via buy now. Participate in auction or cancel it first.");

        // Transfer funds and distribute royalties
        distributeRoyalties(_artId, price);

        // Update art ownership (In a real NFT gallery, this would involve transferring the NFT)
        artCatalog[_artId].onSale = false; // No longer on sale after purchase
        delete activeAuctions[_artId]; // Cancel any active auction upon direct purchase

        emit ArtPurchased(_artId, msg.sender, price);
    }

    function offerBid(uint256 _artId) external payable artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        require(msg.value > 0, "Bid amount must be greater than 0.");
        require(activeAuctions[_artId].auctionType != AuctionType.DUTCH, "Cannot bid directly on Dutch Auction, participate using participateInDutchAuction.");

        uint256 currentHighestBid = 0;
        if (artBids[_artId].length > 0) {
            uint256 lastBidId = artBids[_artId].length; // Assuming bid IDs are sequential
            currentHighestBid = artBids[_artId][lastBidId].bidAmount;
        }

        require(msg.value > currentHighestBid, "Bid amount must be higher than the current highest bid.");

        if (!activeAuctions[_artId].isActive) {
            // Start a simple auction if no auction is active
            activeAuctions[_artId] = Auction({
                artId: _artId,
                auctionType: AuctionType.DUTCH, // Example - could be different auction types
                startTime: block.timestamp,
                endTime: block.timestamp + 7 days, // Example auction duration
                startingPrice: 0, // Not relevant for standard bidding auction
                currentPrice: 0, // Not relevant for standard bidding auction
                priceDropPerBlock: 0, // Not relevant for standard bidding auction
                durationInBlocks: 0, // Not relevant for standard bidding auction
                isActive: true
            });
        }

        uint256 bidId = nextBidId++;
        artBids[_artId][bidId] = Bid({
            id: bidId,
            artId: _artId,
            bidder: msg.sender,
            bidAmount: msg.value,
            timestamp: block.timestamp
        });

        emit BidOffered(_artId, bidId, msg.sender, msg.value);
    }

    function acceptBid(uint256 _artId, uint256 _bidId) external onlyArtist artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        require(artBids[_artId][_bidId].bidder != address(0), "Bid does not exist.");
        Bid memory bid = artBids[_artId][_bidId];

        // Transfer funds and distribute royalties
        distributeRoyalties(_artId, bid.bidAmount);

        // Update art ownership (NFT transfer in real system)
        artCatalog[_artId].onSale = false;
        delete activeAuctions[_artId]; // Cancel auction upon bid acceptance

        emit BidAccepted(_artId, _bidId, artCatalog[_artId].artist, bid.bidder, bid.bidAmount);
    }

    function buyNow(uint256 _artId) external payable artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        require(artCatalog[_artId].buyNowPrice > 0, "Buy Now price is not set for this artwork.");
        require(msg.value >= artCatalog[_artId].buyNowPrice, "Insufficient funds sent.");
        require(activeAuctions[_artId].isActive == false, "Cannot buy now during active auction. Cancel auction or participate in it.");

        uint256 price = artCatalog[_artId].buyNowPrice;

        // Transfer funds and distribute royalties
        distributeRoyalties(_artId, price);

        // Update art ownership (NFT transfer in real system)
        artCatalog[_artId].onSale = false;
        delete activeAuctions[_artId]; // Cancel auction upon direct purchase

        emit ArtPurchased(_artId, msg.sender, price);
    }

    function setBuyNowPrice(uint256 _artId, uint256 _price) external onlyArtist artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        require(_price > 0, "Buy Now price must be greater than 0.");
        artCatalog[_artId].buyNowPrice = _price;
        emit BuyNowPriceSet(_artId, _price);
    }

    function removeBuyNowPrice(uint256 _artId) external onlyArtist artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        artCatalog[_artId].buyNowPrice = 0;
        emit BuyNowPriceRemoved(_artId);
    }

    // -------------------- 5. Auction Functionality (Dutch Auction) --------------------
    function startDutchAuction(uint256 _artId, uint256 _startingPrice, uint256 _priceDropPerBlock, uint256 _durationInBlocks) external onlyArtist artExists(_artId) artApproved(_artId) artOnSale(_artId) {
        require(_startingPrice > 0, "Starting price must be greater than 0.");
        require(_priceDropPerBlock > 0, "Price drop per block must be greater than 0.");
        require(_durationInBlocks > 0, "Duration in blocks must be greater than 0.");
        require(!activeAuctions[_artId].isActive, "An auction is already active for this artwork.");
        require(artCatalog[_artId].buyNowPrice == 0, "Cannot start auction when Buy Now price is set, remove Buy Now price first.");


        activeAuctions[_artId] = Auction({
            artId: _artId,
            auctionType: AuctionType.DUTCH,
            startTime: block.number, // Using block number for block-based time
            endTime: block.number + _durationInBlocks,
            startingPrice: _startingPrice,
            currentPrice: _startingPrice,
            priceDropPerBlock: _priceDropPerBlock,
            durationInBlocks: _durationInBlocks,
            isActive: true
        });
        emit DutchAuctionStarted(_artId, _startingPrice, _priceDropPerBlock, _durationInBlocks);
    }

    function participateInDutchAuction(uint256 _artId) external payable artExists(_artId) artApproved(_artId) artOnSale(_artId) auctionActive(_artId) {
        Auction storage auction = activeAuctions[_artId];
        require(auction.auctionType == AuctionType.DUTCH, "This is not a Dutch Auction.");

        uint256 blocksPassed = block.number - auction.startTime;
        uint256 priceDrop = blocksPassed * auction.priceDropPerBlock;
        uint256 currentDutchPrice = auction.startingPrice > priceDrop ? auction.startingPrice - priceDrop : 0; // Price cannot go below 0
        auction.currentPrice = currentDutchPrice; // Update current price

        require(msg.value >= currentDutchPrice, "Insufficient funds for current Dutch Auction price.");
        require(block.number <= auction.endTime, "Dutch Auction has ended.");

        // Transfer funds and distribute royalties
        distributeRoyalties(_artId, currentDutchPrice);

        // Update art ownership (NFT transfer in real system)
        artCatalog[_artId].onSale = false;
        delete activeAuctions[_artId]; // Auction ends upon purchase

        emit DutchAuctionParticipation(_artId, msg.sender, currentDutchPrice);
    }

    function cancelAuction(uint256 _artId) external onlyArtist artExists(_artId) artApproved(_artId) auctionActive(_artId) {
        delete activeAuctions[_artId];
        emit AuctionCancelled(_artId);
    }

    function getAuctionDetails(uint256 _artId) external view artExists(_artId) returns (Auction memory) {
        return activeAuctions[_artId];
    }

    // -------------------- 6. Community Governance & Proposals --------------------
    function createProposal(string memory _title, string memory _description, ProposalType _proposalType, bytes calldata _data) external notGalleryOwner {
        proposals[nextProposalId] = Proposal({
            id: nextProposalId,
            title: _title,
            description: _description,
            proposalType: _proposalType,
            data: _data,
            voteCount: 0,
            againstVoteCount: 0,
            isActive: true,
            isExecuted: false
        });
        emit ProposalCreated(nextProposalId, _title, _proposalType);
        nextProposalId++;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) notGalleryOwner {
        if (_support) {
            proposals[_proposalId].voteCount++;
        } else {
            proposals[_proposalId].againstVoteCount++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyGalleryOwner proposalExists(_proposalId) proposalActive(_proposalId) proposalNotExecuted(_proposalId) {
        require(proposals[_proposalId].voteCount > proposals[_proposalId].againstVoteCount, "Proposal not passed, more against votes or equal.");
        proposals[_proposalId].isActive = false;
        proposals[_proposalId].isExecuted = true;

        ProposalType proposalType = proposals[_proposalId].proposalType;
        bytes memory data = proposals[_proposalId].data;

        if (proposalType == ProposalType.GALLERY_FEE_CHANGE) {
            uint256 newFeePercentage = abi.decode(data, (uint256));
            setGalleryFee(newFeePercentage);
        } else if (proposalType == ProposalType.CURATOR_ADDITION) {
            address newCurator = abi.decode(data, (address));
            addCurator(newCurator);
        } else if (proposalType == ProposalType.CURATOR_REMOVAL) {
            address curatorToRemove = abi.decode(data, (address));
            removeCurator(curatorToRemove);
        }
        // Add more proposal type executions here as needed

        emit ProposalExecuted(_proposalId, proposalType);
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function listActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](nextProposalId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextProposalId; i++) {
            if (proposals[i].isActive && proposals[i].id == i) {
                activeProposalIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(activeProposalIds, count)
        }
        return activeProposalIds;
    }


    // -------------------- 7. Royalty Management & Payouts --------------------
    function distributeRoyalties(uint256 _artId, uint256 _salePrice) private {
        Art storage art = artCatalog[_artId];
        uint256 galleryFee = (_salePrice * galleryFeePercentage) / 100;
        uint256 artistRoyaltyPercentage = getArtistRoyalty(art.artist); // Get artist's royalty (using default for now)
        uint256 artistShare = (_salePrice * (artistRoyaltyPercentage - galleryFeePercentage)) / 100; // Artist gets their royalty - gallery fee

        // Distribute to collaborators first
        uint256 remainingShare = artistShare;
        for (uint256 i = 0; i < art.collaborators.length; i++) {
            uint256 collaboratorAmount = (artistShare * art.collaboratorShares[i]) / 10000;
            artistEarnings[art.collaborators[i]] += collaboratorAmount;
            remainingShare -= collaboratorAmount;
        }

        // Artist gets the remaining share after collaborators
        artistEarnings[art.artist] += remainingShare;

        // Gallery gets its fee
        galleryBalance += galleryFee;
    }

    function withdrawArtistEarnings() external onlyArtist {
        uint256 amount = artistEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");
        artistEarnings[msg.sender] = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(amount);
        emit ArtistEarningsWithdrawn(msg.sender, amount);
    }

    // -------------------- 8. Tokenized Curation (Simplified) --------------------
    function stakeForCuration() external payable {
        require(msg.value > 0, "Stake amount must be greater than 0.");
        curationStake[msg.sender] += msg.value;
        curators[msg.sender] = true; // Staking makes you a curator (simplified)
        emit CurationStakeIncreased(msg.sender, msg.value);
    }

    function unstakeFromCuration(uint256 _amount) external {
        require(_amount > 0, "Unstake amount must be greater than 0.");
        require(curationStake[msg.sender] >= _amount, "Insufficient stake to unstake.");
        curationStake[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit CurationStakeDecreased(msg.sender, _amount);
        if (curationStake[msg.sender] == 0) {
            delete curators[msg.sender]; // No stake, no longer curator (simplified)
        }
    }

    function getCurationStake(address _user) external view returns (uint256) {
        return curationStake[_user];
    }

    // -------------------- 9. Collaborative Art Enhancements --------------------
    function addCollaborator(uint256 _artId, address _collaborator, uint256 _share) external onlyArtist artExists(_artId) artNotApproved(_artId) {
        require(_share > 0 && _share <= 10000, "Collaborator share must be between 0 and 100%.");
        Art storage art = artCatalog[_artId];
        uint256 totalShares = 0;
        for (uint256 share in art.collaboratorShares) {
            totalShares += share;
        }
        require(totalShares + _share <= 10000, "Total collaborator shares cannot exceed 100%.");

        art.collaborators.push(_collaborator);
        art.collaboratorShares.push(_share);
    }

    function updateCollaboratorShare(uint256 _artId, address _collaborator, uint256 _newShare) external onlyArtist artExists(_artId) artNotApproved(_artId) {
        require(_newShare > 0 && _newShare <= 10000, "New collaborator share must be between 0 and 100%.");
        Art storage art = artCatalog[_artId];
        uint256 totalShares = 0;
        for (uint256 share in art.collaboratorShares) {
            totalShares += share;
        }
        // Subtract the old share and add the new share to check total
        uint256 currentCollaboratorIndex = type(uint256).max; // Initialize to max to detect if not found
        for (uint256 i = 0; i < art.collaborators.length; i++) {
            if (art.collaborators[i] == _collaborator) {
                currentCollaboratorIndex = i;
                break;
            }
        }
        require(currentCollaboratorIndex != type(uint256).max, "Collaborator not found.");

        uint256 oldShare = art.collaboratorShares[currentCollaboratorIndex];
        require((totalShares - oldShare + _newShare) <= 10000, "Total collaborator shares cannot exceed 100%.");

        art.collaboratorShares[currentCollaboratorIndex] = _newShare;
    }

    function removeCollaborator(uint256 _artId, address _collaborator) external onlyArtist artExists(_artId) artNotApproved(_artId) {
        Art storage art = artCatalog[_artId];
        uint256 collaboratorIndexToRemove = type(uint256).max;
        for (uint256 i = 0; i < art.collaborators.length; i++) {
            if (art.collaborators[i] == _collaborator) {
                collaboratorIndexToRemove = i;
                break;
            }
        }
        require(collaboratorIndexToRemove != type(uint256).max, "Collaborator not found.");

        // Remove from both arrays, maintaining order is not crucial here, so efficient removal by swapping with last element
        art.collaborators[collaboratorIndexToRemove] = art.collaborators[art.collaborators.length - 1];
        art.collaborators.pop();
        art.collaboratorShares[collaboratorIndexToRemove] = art.collaboratorShares[art.collaboratorShares.length - 1];
        art.collaboratorShares.pop();
    }
}
```