```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Reputation System
 * @author Bard (Example - Replace with your name)
 * @dev A smart contract implementing a dynamic NFT marketplace with advanced features:
 *      - Dynamic NFTs: NFTs that can evolve or change based on interactions.
 *      - AI-Assisted Art Generation: Integrated (conceptually) with off-chain AI for NFT evolution.
 *      - Reputation System: Tracks user reputation based on marketplace activity and community voting.
 *      - Advanced Marketplace Features: Auctions, Bidding, Renting/Leasing, Bundles, Royalties, Governance.
 *      - Community Governance: Basic governance for marketplace parameters and NFT evolution.
 *
 * Function Summary:
 *
 * // NFT Management & Dynamic Evolution
 * 1. mintNFT(address _to, string memory _initialMetadataURI) - Mints a new Dynamic NFT.
 * 2. evolveNFT(uint256 _tokenId, string memory _evolutionPrompt) - Triggers NFT evolution based on a prompt (conceptually AI-driven).
 * 3. getNFTMetadataURI(uint256 _tokenId) - Retrieves the current metadata URI of an NFT.
 * 4. getNFTEvolutionHistory(uint256 _tokenId) - Retrieves the history of evolution prompts for an NFT.
 * 5. setBaseMetadataURI(string memory _baseURI) - Sets the base URI for NFT metadata (Admin).
 *
 * // Marketplace Features
 * 6. listItemForSale(uint256 _tokenId, uint256 _price) - Lists an NFT for sale at a fixed price.
 * 7. buyNFT(uint256 _listingId) - Allows a user to buy an NFT listed for sale.
 * 8. cancelListing(uint256 _listingId) - Allows the seller to cancel an NFT listing.
 * 9. createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) - Creates an auction for an NFT.
 * 10. bidOnAuction(uint256 _auctionId) - Allows users to bid on an active auction.
 * 11. finalizeAuction(uint256 _auctionId) - Finalizes an auction and transfers NFT to the highest bidder.
 * 12. rentNFT(uint256 _tokenId, uint256 _rentalPrice, uint256 _rentalDuration) - Allows NFT owner to rent out their NFT.
 * 13. leaseNFT(uint256 _tokenId, uint256 _leasePrice, uint256 _leaseDuration) - Allows NFT owner to lease out their NFT (longer term rental).
 * 14. buyBundle(uint256[] memory _tokenIds) - Allows buying a bundle of NFTs at a discounted price.
 * 15. setMarketplaceFee(uint256 _feePercentage) - Sets the marketplace fee percentage (Admin).
 * 16. withdrawMarketplaceFees() - Allows the contract owner to withdraw accumulated marketplace fees (Admin).
 *
 * // Reputation & Governance
 * 17. upvoteUserReputation(address _user) - Allows users to upvote another user's reputation.
 * 18. downvoteUserReputation(address _user) - Allows users to downvote another user's reputation.
 * 19. getUserReputation(address _user) - Retrieves the reputation score of a user.
 * 20. proposeParameterChange(string memory _parameterName, uint256 _newValue) - Allows users to propose changes to marketplace parameters (Governance - basic example).
 * 21. voteOnProposal(uint256 _proposalId, bool _vote) - Allows users to vote on parameter change proposals (Governance - basic example).
 * 22. executeProposal(uint256 _proposalId) - Executes a passed parameter change proposal (Governance - basic example, Admin/Timelock).
 *
 * // Utility & Admin
 * 23. pauseContract() - Pauses core marketplace functionalities (Admin).
 * 24. unpauseContract() - Resumes core marketplace functionalities (Admin).
 * 25. withdrawContractBalance() - Allows the contract owner to withdraw any ERC20 tokens or ETH accidentally sent to the contract (Admin).
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---

    string public name = "Dynamic Art NFTs";
    string public symbol = "DNA";
    string public baseMetadataURI; // Base URI for NFT metadata
    uint256 public tokenCounter;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => string) public tokenMetadataURIs;
    mapping(uint256 => string[]) public nftEvolutionHistory; // Store evolution prompts for each NFT

    // Marketplace Listings
    uint256 public listingCounter;
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public tokenIdToListingId; // Map tokenId to active listingId

    // Auctions
    uint256 public auctionCounter;
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 startingBid;
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEndTime;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;

    // Rentals/Leases (Basic Example - Could be expanded with more features)
    struct Rental {
        uint256 tokenId;
        address renter;
        uint256 rentalPrice;
        uint256 rentalEndTime;
        bool isActive;
    }
    mapping(uint256 => Rental) public rentals;
    struct Lease {
        uint256 tokenId;
        address lessee;
        uint256 leasePrice;
        uint256 leaseEndTime;
        bool isActive;
    }
    mapping(uint256 => Lease) public leases;


    // Reputation System
    mapping(address => int256) public userReputation;

    // Governance (Basic Example)
    uint256 public proposalCounter;
    struct Proposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public contractOwner;
    bool public paused = false;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string metadataURI);
    event NFTEvolved(uint256 tokenId, string evolutionPrompt, string newMetadataURI);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 startingBid, uint256 auctionDuration);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionFinalized(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event NFTLeased(uint256 tokenId, address lessee, uint256 leasePrice, uint256 leaseDuration);
    event NFTRented(uint256 tokenId, address renter, uint256 rentalPrice, uint256 rentalDuration);
    event UserReputationChanged(address user, int256 newReputation);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue);
    event ProposalVoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event ContractPaused();
    event ContractUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
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

    modifier tokenExists(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId && listings[_listingId].isActive, "Listing does not exist or is not active.");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].auctionId == _auctionId && auctions[_auctionId].isActive, "Auction does not exist or is not active.");
        _;
    }


    // --- Constructor ---
    constructor(string memory _baseURI) payable {
        contractOwner = payable(msg.sender);
        baseMetadataURI = _baseURI;
    }

    // --- NFT Management & Dynamic Evolution ---

    /// @dev Mints a new Dynamic NFT and assigns it to the recipient.
    /// @param _to The address to receive the NFT.
    /// @param _initialMetadataURI The initial metadata URI for the NFT.
    function mintNFT(address _to, string memory _initialMetadataURI) public onlyOwner {
        tokenCounter++;
        uint256 newTokenId = tokenCounter;
        tokenOwner[newTokenId] = _to;
        tokenMetadataURIs[newTokenId] = _initialMetadataURI;
        emit NFTMinted(newTokenId, _to, _initialMetadataURI);
    }

    /// @dev Triggers the evolution of an NFT based on a prompt (conceptually AI-driven).
    ///      This is a simplified example. In a real-world scenario, this would interact with an off-chain AI service.
    ///      The `_evolutionPrompt` would be sent to the AI service, which would generate new metadata or visual assets.
    ///      The `fulfillAIArtGeneration` function (or a similar mechanism) would then be used to update the NFT's metadata based on the AI's output.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _evolutionPrompt A prompt describing the desired evolution (e.g., "make it more futuristic", "add fire elements", etc.).
    function evolveNFT(uint256 _tokenId, string memory _evolutionPrompt) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        nftEvolutionHistory[_tokenId].push(_evolutionPrompt);
        // In a real application, this is where you would:
        // 1. Send the _evolutionPrompt and _tokenId to an off-chain AI service.
        // 2. The AI service generates new metadata or assets based on the prompt.
        // 3. The AI service (or an oracle) calls a function like `fulfillAIArtGeneration` (not implemented here for simplicity)
        //    to update the tokenMetadataURIs[_tokenId] with the AI-generated metadata URI.

        // For this example, we'll just append the prompt to the metadata URI (very basic placeholder for AI evolution)
        string memory currentMetadataURI = tokenMetadataURIs[_tokenId];
        string memory newMetadataURI = string(abi.encodePacked(currentMetadataURI, "?evolved=", _evolutionPrompt, "&version=", nftEvolutionHistory[_tokenId].length));
        tokenMetadataURIs[_tokenId] = newMetadataURI;

        emit NFTEvolved(_tokenId, _evolutionPrompt, newMetadataURI);
    }


    /// @dev Retrieves the current metadata URI of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI of the NFT.
    function getNFTMetadataURI(uint256 _tokenId) public view tokenExists(_tokenId) returns (string memory) {
        return tokenMetadataURIs[_tokenId];
    }

    /// @dev Retrieves the history of evolution prompts for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return An array of evolution prompts.
    function getNFTEvolutionHistory(uint256 _tokenId) public view tokenExists(_tokenId) returns (string[] memory) {
        return nftEvolutionHistory[_tokenId];
    }

    /// @dev Sets the base metadata URI for NFTs (Admin function).
    /// @param _baseURI The new base URI.
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner {
        baseMetadataURI = _baseURI;
    }


    // --- Marketplace Features ---

    /// @dev Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price in wei for which the NFT is listed.
    function listItemForSale(uint256 _tokenId, uint256 _price) public whenNotPaused tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(tokenIdToListingId[_tokenId] == 0, "NFT is already listed for sale."); // Prevent relisting without canceling first
        listingCounter++;
        uint256 newListingId = listingCounter;
        listings[newListingId] = Listing({
            listingId: newListingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        tokenIdToListingId[_tokenId] = newListingId;
        emit NFTListed(newListingId, _tokenId, msg.sender, _price);
    }

    /// @dev Allows a user to buy an NFT listed for sale.
    /// @param _listingId The ID of the listing to buy.
    function buyNFT(uint256 _listingId) public payable whenNotPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds.");
        require(listing.seller != msg.sender, "Seller cannot buy their own NFT.");

        // Transfer NFT ownership
        tokenOwner[listing.tokenId] = msg.sender;
        tokenIdToListingId[listing.tokenId] = 0; // Clear listing mapping

        // Transfer funds to seller (after marketplace fee)
        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - marketplaceFee;
        payable(listing.seller).transfer(sellerPayout);
        payable(contractOwner).transfer(marketplaceFee); // Send fee to contract owner

        listing.isActive = false; // Deactivate listing

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }

    /// @dev Allows the seller to cancel an NFT listing.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId) public whenNotPaused listingExists(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only the seller can cancel the listing.");

        listing.isActive = false; // Deactivate listing
        tokenIdToListingId[listing.tokenId] = 0; // Clear listing mapping

        emit ListingCancelled(_listingId, listing.tokenId);
    }


    /// @dev Creates an auction for an NFT.
    /// @param _tokenId The ID of the NFT to auction.
    /// @param _startingBid The starting bid price in wei.
    /// @param _auctionDuration The duration of the auction in seconds.
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) public whenNotPaused tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(auctions[auctionCounter].auctionId == 0, "Previous auction not finalized yet."); // Simple check, could be improved
        auctionCounter++;
        uint256 newAuctionId = auctionCounter;
        auctions[newAuctionId] = Auction({
            auctionId: newAuctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            startingBid: _startingBid,
            highestBid: _startingBid,
            highestBidder: address(0), // No bidder initially
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });
        emit AuctionCreated(newAuctionId, _tokenId, msg.sender, _startingBid, _auctionDuration);
    }

    /// @dev Allows users to bid on an active auction.
    /// @param _auctionId The ID of the auction to bid on.
    function bidOnAuction(uint256 _auctionId) public payable whenNotPaused auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.auctionEndTime, "Auction has ended.");
        require(msg.value > auction.highestBid, "Bid amount is too low. Must be higher than current highest bid.");
        require(auction.seller != msg.sender, "Seller cannot bid on their own auction.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder (if any)
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /// @dev Finalizes an auction and transfers the NFT to the highest bidder.
    /// @param _auctionId The ID of the auction to finalize.
    function finalizeAuction(uint256 _auctionId) public whenNotPaused auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.auctionEndTime, "Auction is not yet over.");
        require(auction.isActive, "Auction is not active.");

        auction.isActive = false; // Deactivate auction

        if (auction.highestBidder != address(0)) {
            // Transfer NFT to highest bidder
            tokenOwner[auction.tokenId] = auction.highestBidder;

            // Transfer funds to seller (after marketplace fee)
            uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - marketplaceFee;
            payable(auction.seller).transfer(sellerPayout);
            payable(contractOwner).transfer(marketplaceFee); // Send fee to contract owner

            emit AuctionFinalized(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller (or handle as needed)
            tokenOwner[auction.tokenId] = auction.seller; // Return to seller
            // Optionally refund starting bid if seller deposited something initially to start auction
        }
    }

    /// @dev Allows NFT owner to rent out their NFT for a specified duration.
    /// @param _tokenId The ID of the NFT to rent.
    /// @param _rentalPrice The price per rental period.
    /// @param _rentalDuration The duration of the rental in seconds.
    function rentNFT(uint256 _tokenId, uint256 _rentalPrice, uint256 _rentalDuration) public payable whenNotPaused tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(msg.value >= _rentalPrice, "Insufficient rental fee.");
        require(rentals[_tokenId].tokenId == 0 || !rentals[_tokenId].isActive, "NFT is already rented."); // Check if not already rented

        rentals[_tokenId] = Rental({
            tokenId: _tokenId,
            renter: msg.sender,
            rentalPrice: _rentalPrice,
            rentalEndTime: block.timestamp + _rentalDuration,
            isActive: true
        });

        // Transfer rental fee to owner (after marketplace fee - optional for rentals, can be 0)
        uint256 marketplaceFee = (0 * marketplaceFeePercentage) / 100; // Example: 0% fee for rentals
        uint256 ownerPayout = _rentalPrice - marketplaceFee;
        payable(tokenOwner[_tokenId]).transfer(ownerPayout);
        payable(contractOwner).transfer(marketplaceFee); // Send fee to contract owner (if any)


        emit NFTRented(_tokenId, msg.sender, _rentalPrice, _rentalDuration);
    }

    /// @dev Allows NFT owner to lease out their NFT for a longer term.
    /// @param _tokenId The ID of the NFT to lease.
    /// @param _leasePrice The total lease price.
    /// @param _leaseDuration The duration of the lease in seconds.
    function leaseNFT(uint256 _tokenId, uint256 _leasePrice, uint256 _leaseDuration) public payable whenNotPaused tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(msg.value >= _leasePrice, "Insufficient lease fee.");
        require(leases[_tokenId].tokenId == 0 || !leases[_tokenId].isActive, "NFT is already leased."); // Check if not already leased

        leases[_tokenId] = Lease({
            tokenId: _tokenId,
            lessee: msg.sender,
            leasePrice: _leasePrice,
            leaseEndTime: block.timestamp + _leaseDuration,
            isActive: true
        });

        // Transfer lease fee to owner (after marketplace fee - optional for leases, can be 0)
        uint256 marketplaceFee = (0 * marketplaceFeePercentage) / 100; // Example: 0% fee for leases
        uint256 ownerPayout = _leasePrice - marketplaceFee;
        payable(tokenOwner[_tokenId]).transfer(ownerPayout);
        payable(contractOwner).transfer(marketplaceFee); // Send fee to contract owner (if any)


        emit NFTLeased(_tokenId, msg.sender, _leasePrice, _leaseDuration);
    }


    /// @dev Allows buying a bundle of NFTs at a discounted price (concept - not fully implemented discount logic here).
    /// @param _tokenIds An array of NFT token IDs to buy as a bundle.
    function buyBundle(uint256[] memory _tokenIds) public payable whenNotPaused {
        uint256 totalPrice = 0;
        address[] memory sellers = new address[](_tokenIds.length);
        uint256[] memory listingIds = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 listingId = tokenIdToListingId[tokenId];
            require(listingId != 0, "One or more NFTs in the bundle are not listed.");
            Listing storage listing = listings[listingId];
            require(listing.isActive, "One or more listings in the bundle are not active.");
            totalPrice += listing.price;
            sellers[i] = listing.seller;
            listingIds[i] = listingId;
        }

        require(msg.value >= totalPrice, "Insufficient funds for bundle purchase.");

        // Apply bundle discount logic here (e.g., calculate a discount percentage) - Not implemented in this basic example

        uint256 discountedPrice = totalPrice; // Placeholder - in real app, apply discount to totalPrice

        // Transfer NFTs and funds
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 listingId = listingIds[i];
            Listing storage listing = listings[listingId];

            tokenOwner[tokenId] = msg.sender;
            tokenIdToListingId[tokenId] = 0; // Clear listing mapping
            listing.isActive = false; // Deactivate listing

            // Calculate individual seller payout (proportional to their NFT price in the bundle)
            uint256 sellerPrice = listing.price;
            uint256 sellerPayout = (sellerPrice * discountedPrice) / totalPrice; // Proportional payout
            uint256 marketplaceFee = (sellerPayout * marketplaceFeePercentage) / 100;
            sellerPayout -= marketplaceFee;

            payable(sellers[i]).transfer(sellerPayout);
            payable(contractOwner).transfer(marketplaceFee); // Send fee to contract owner
            emit NFTBought(listingId, tokenId, msg.sender, listing.price); // Event for each NFT in bundle
        }
    }


    /// @dev Sets the marketplace fee percentage (Admin function).
    /// @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /// @dev Allows the contract owner to withdraw accumulated marketplace fees (Admin function).
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(contractOwner).transfer(balance);
    }


    // --- Reputation & Governance ---

    /// @dev Allows users to upvote another user's reputation.
    /// @param _user The address of the user to upvote.
    function upvoteUserReputation(address _user) public whenNotPaused {
        userReputation[_user]++;
        emit UserReputationChanged(_user, userReputation[_user]);
    }

    /// @dev Allows users to downvote another user's reputation.
    /// @param _user The address of the user to downvote.
    function downvoteUserReputation(address _user) public whenNotPaused {
        userReputation[_user]--;
        emit UserReputationChanged(_user, userReputation[_user]);
    }

    /// @dev Retrieves the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address _user) public view returns (int256) {
        return userReputation[_user];
    }

    /// @dev Allows users to propose changes to marketplace parameters (Governance - basic example).
    /// @param _parameterName The name of the parameter to change (e.g., "marketplaceFeePercentage").
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) public whenNotPaused {
        proposalCounter++;
        uint256 newProposalId = proposalCounter;
        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit ParameterProposalCreated(newProposalId, _parameterName, _newValue);
    }

    /// @dev Allows users to vote on parameter change proposals (Governance - basic example).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for "for", false for "against".
    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active.");
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record vote

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a passed parameter change proposal (Governance - basic example, Admin/Timelock needed for real use).
    ///      In a real-world scenario, this would likely involve a timelock and more robust governance logic.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused { // Admin execution for simplicity - Timelock needed for real governance
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "Proposal is not active.");
        require(!proposal.isExecuted, "Proposal is already executed.");
        // Basic pass/fail condition - improve with quorum, etc. in real governance
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass.");

        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("marketplaceFeePercentage"))) {
            marketplaceFeePercentage = proposal.newValue;
            emit MarketplaceFeeSet(marketplaceFeePercentage);
        } else {
            // Add more parameter checks and updates here for other governable parameters
            revert("Unknown parameter to change."); // Or handle unknown parameters gracefully
        }

        proposal.isActive = false;
        proposal.isExecuted = true;
        emit ProposalExecuted(_proposalId);
    }


    // --- Utility & Admin ---

    /// @dev Pauses core marketplace functionalities (Admin function).
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @dev Resumes core marketplace functionalities (Admin function).
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @dev Allows the contract owner to withdraw any ERC20 tokens or ETH accidentally sent to the contract (Admin function).
    function withdrawContractBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(contractOwner).transfer(balance);
    }


    // --- ERC721 Interface (Basic - for marketplace compatibility, could be expanded) ---
    function balanceOf(address _owner) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (tokenOwner[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    function ownerOf(uint256 _tokenId) public view tokenExists(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    // Basic transfer function (consider adding approval mechanisms for true ERC721)
    function transferNFT(address _to, uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(_to != address(0), "Transfer to the zero address.");
        tokenOwner[_tokenId] = _to;
        // Add event if needed
    }

    // Add approve, getApproved, setApprovalForAll functions for full ERC721 compliance if needed for broader marketplace integration.
}
```