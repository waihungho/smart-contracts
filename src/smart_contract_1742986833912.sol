```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation (Simulated)
 * @author Bard (Example - Not for Production)
 * @dev This contract implements a dynamic NFT marketplace with simulated AI art generation.
 * It features advanced concepts like dynamic NFTs, marketplace functionalities,
 * simulated AI art creation (on-chain prompt storage), governance features,
 * and innovative functionalities beyond typical marketplace contracts.
 *
 * Function Summary:
 * 1. createAINFT(string memory _prompt, string memory _initialMetadataURI): Allows users to create a new Dynamic AI NFT with a prompt and initial metadata.
 * 2. updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI): Updates the metadata URI of an existing NFT, showcasing dynamic NFT capabilities.
 * 3. setAIGenerationFee(uint256 _fee): Allows the contract owner to set the fee for creating AI NFTs.
 * 4. listNFT(uint256 _tokenId, uint256 _price): Lists an NFT on the marketplace for sale at a specified price.
 * 5. unlistNFT(uint256 _listingId): Removes an NFT listing from the marketplace.
 * 6. buyNFT(uint256 _listingId): Allows users to buy a listed NFT.
 * 7. placeBid(uint256 _listingId, uint256 _bidAmount): Allows users to place a bid on a listed NFT.
 * 8. acceptBid(uint256 _bidId): Allows the seller to accept the highest bid for their listed NFT.
 * 9. cancelListing(uint256 _listingId): Allows the seller to cancel their NFT listing.
 * 10. cancelBid(uint256 _bidId): Allows a bidder to cancel their bid if it hasn't been accepted yet.
 * 11. getListingDetails(uint256 _listingId): Retrieves details of a specific NFT listing.
 * 12. getNFTDetails(uint256 _tokenId): Retrieves details of a specific NFT.
 * 13. setDefaultRoyalty(uint256 _royaltyPercentage): Sets the default royalty percentage for all NFTs created on the platform.
 * 14. setTokenRoyalty(uint256 _tokenId, uint256 _royaltyPercentage): Sets a specific royalty percentage for a particular NFT, overriding the default.
 * 15. withdrawRoyalties(): Allows NFT creators to withdraw their accumulated royalties.
 * 16. setMarketplaceFee(uint256 _feePercentage): Allows the contract owner to set the marketplace fee percentage.
 * 17. withdrawMarketplaceFees(): Allows the contract owner to withdraw accumulated marketplace fees.
 * 18. pauseMarketplace(): Allows the contract owner to pause all marketplace functionalities for maintenance or emergencies.
 * 19. unpauseMarketplace(): Allows the contract owner to resume marketplace functionalities after pausing.
 * 20. createProposal(string memory _description): Allows community members to create governance proposals for platform improvements.
 * 21. voteOnProposal(uint256 _proposalId, bool _support): Allows users to vote on active governance proposals.
 * 22. executeProposal(uint256 _proposalId): Allows the contract owner to execute a passed governance proposal (basic execution).
 */

contract DynamicAINFTMarketplace {
    // --- Structs ---
    struct NFT {
        uint256 tokenId;
        address creator;
        address owner;
        string prompt; // Stored prompt for simulated AI generation
        string metadataURI; // URI for NFT metadata (can be dynamic)
        uint256 royaltyPercentage;
    }

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 amount;
        uint256 timestamp;
        bool isActive;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isExecuted;
    }

    // --- State Variables ---
    NFT[] public nfts;
    Listing[] public listings;
    Bid[] public bids;
    Proposal[] public proposals;

    mapping(uint256 => uint256) public nftToListingId; // TokenId to ListingId (for quick lookup)
    mapping(uint256 => uint256) public listingToHighestBidId; // ListingId to Highest Bid ID
    mapping(uint256 => address) public nftOwner; // TokenId to Owner Address
    mapping(uint256 => address) public nftCreator; // TokenId to Creator Address
    mapping(address => uint256) public creatorRoyaltiesDue; // Creator address to accumulated royalties
    mapping(address => bool) public hasVotedOnProposal; // User address to Proposal ID voted on

    uint256 public nextNFTTokenId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextBidId = 1;
    uint256 public nextProposalId = 1;

    uint256 public aiGenerationFee = 0.01 ether; // Fee for creating AI NFTs
    uint256 public marketplaceFeePercentage = 2; // Marketplace fee percentage (e.g., 2% of sale price)
    uint256 public defaultRoyaltyPercentage = 5; // Default royalty percentage for creators
    address public owner;
    bool public isMarketplacePaused = false;

    // --- Events ---
    event NFTCreated(uint256 tokenId, address creator, string prompt, string metadataURI);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTUnlisted(uint256 listingId);
    event NFTSold(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event BidPlaced(uint256 bidId, uint256 listingId, address bidder, uint256 amount);
    event BidAccepted(uint256 bidId, uint256 listingId, address seller, address buyer, uint256 price);
    event BidCancelled(uint256 bidId);
    event ListingCancelled(uint256 listingId);
    event RoyaltiesWithdrawn(address creator, uint256 amount);
    event MarketplaceFeesWithdrawn(address admin, uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event ProposalCreated(uint256 proposalId, address proposer, string description);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!isMarketplacePaused, "Marketplace is paused.");
        _;
    }

    modifier whenPaused() {
        require(isMarketplacePaused, "Marketplace is not paused.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= listings.length && listings[_listingId - 1].listingId == _listingId, "Listing does not exist.");
        _;
    }

    modifier bidExists(uint256 _bidId) {
        require(_bidId > 0 && _bidId <= bids.length && bids[_bidId - 1].bidId == _bidId, "Bid does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposals.length && proposals[_proposalId - 1].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId - 1].seller == msg.sender, "You are not the listing seller.");
        _;
    }

    modifier onlyBidder(uint256 _bidId) {
        require(bids[_bidId - 1].bidder == msg.sender, "You are not the bidder.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- NFT Creation and Management ---
    function createAINFT(string memory _prompt, string memory _initialMetadataURI) external payable whenNotPaused {
        require(msg.value >= aiGenerationFee, "Insufficient AI Generation Fee.");

        uint256 tokenId = nextNFTTokenId++;
        nfts.push(NFT({
            tokenId: tokenId,
            creator: msg.sender,
            owner: msg.sender,
            prompt: _prompt,
            metadataURI: _initialMetadataURI,
            royaltyPercentage: defaultRoyaltyPercentage
        }));
        nftOwner[tokenId] = msg.sender;
        nftCreator[tokenId] = msg.sender;

        emit NFTCreated(tokenId, msg.sender, _prompt, _initialMetadataURI);

        // Optionally refund excess fee if paid more than required.
        if (msg.value > aiGenerationFee) {
            payable(msg.sender).transfer(msg.value - aiGenerationFee);
        }
    }

    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(_tokenId > 0 && _tokenId <= nfts.length && nfts[_tokenId - 1].tokenId == _tokenId, "NFT does not exist.");
        nfts[_tokenId - 1].metadataURI = _newMetadataURI;
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    function setAIGenerationFee(uint256 _fee) external onlyOwner {
        aiGenerationFee = _fee;
    }

    // --- Marketplace Functions ---
    function listNFT(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) whenNotPaused {
        require(_tokenId > 0 && _tokenId <= nfts.length && nfts[_tokenId - 1].tokenId == _tokenId, "NFT does not exist.");
        require(nftToListingId[_tokenId] == 0, "NFT is already listed.");
        require(_price > 0, "Price must be greater than zero.");

        uint256 listingId = nextListingId++;
        listings.push(Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        }));
        nftToListingId[_tokenId] = listingId;

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    function unlistNFT(uint256 _listingId) external onlyListingSeller(_listingId) listingExists(_listingId) whenNotPaused {
        require(listings[_listingId - 1].isActive, "Listing is not active.");
        listings[_listingId - 1].isActive = false;
        nftToListingId[listings[_listingId - 1].tokenId] = 0; // Remove listing association
        emit NFTUnlisted(_listingId);
    }

    function buyNFT(uint256 _listingId) external payable listingExists(_listingId) whenNotPaused {
        Listing storage listing = listings[_listingId - 1];
        require(listing.isActive, "Listing is not active.");
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyAmount = (price * nfts[tokenId - 1].royaltyPercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Transfer funds
        payable(owner).transfer(marketplaceFee); // Marketplace fee to owner
        creatorRoyaltiesDue[nftCreator[tokenId]] += royaltyAmount; // Royalty to creator
        payable(seller).transfer(sellerPayout); // Seller gets the rest

        // Transfer NFT ownership
        nftOwner[tokenId] = msg.sender;
        listing.isActive = false; // Deactivate listing
        nftToListingId[tokenId] = 0; // Remove listing association

        emit NFTSold(_listingId, tokenId, msg.sender, price);

        // Optionally refund excess payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function placeBid(uint256 _listingId, uint256 _bidAmount) external payable listingExists(_listingId) whenNotPaused {
        Listing storage listing = listings[_listingId - 1];
        require(listing.isActive, "Listing is not active.");
        require(msg.value >= _bidAmount, "Insufficient bid amount.");
        require(_bidAmount > (listingToHighestBidId[_listingId] == 0 ? 0 : bids[listingToHighestBidId[_listingId] - 1].amount), "Bid amount must be higher than current highest bid.");

        uint256 bidId = nextBidId++;
        bids.push(Bid({
            bidId: bidId,
            listingId: _listingId,
            bidder: msg.sender,
            amount: _bidAmount,
            timestamp: block.timestamp,
            isActive: true
        }));

        // Refund previous highest bidder if exists (simplistic refund - more robust refund logic might be needed in real-world scenario)
        if (listingToHighestBidId[_listingId] != 0) {
            uint256 previousBidId = listingToHighestBidId[_listingId];
            payable(bids[previousBidId - 1].bidder).transfer(bids[previousBidId - 1].amount);
            bids[previousBidId - 1].isActive = false; // Mark previous bid as inactive
        }

        listingToHighestBidId[_listingId] = bidId;
        emit BidPlaced(bidId, _listingId, msg.sender, _bidAmount);
    }

    function acceptBid(uint256 _bidId) external bidExists(_bidId) whenNotPaused {
        Bid storage bid = bids[_bidId - 1];
        require(bid.isActive, "Bid is not active.");
        Listing storage listing = listings[bid.listingId - 1];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only the seller can accept bids.");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        address buyer = bid.bidder;
        uint256 price = bid.amount;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyAmount = (price * nfts[tokenId - 1].royaltyPercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Transfer funds
        payable(owner).transfer(marketplaceFee); // Marketplace fee to owner
        creatorRoyaltiesDue[nftCreator[tokenId]] += royaltyAmount; // Royalty to creator
        payable(seller).transfer(sellerPayout); // Seller gets the rest

        // Transfer NFT ownership
        nftOwner[tokenId] = buyer;
        listing.isActive = false; // Deactivate listing
        bid.isActive = false; // Deactivate bid
        nftToListingId[tokenId] = 0; // Remove listing association

        emit BidAccepted(_bidId, listing.listingId, seller, buyer, price);
    }


    function cancelListing(uint256 _listingId) external onlyListingSeller(_listingId) listingExists(_listingId) whenNotPaused {
        require(listings[_listingId - 1].isActive, "Listing is not active.");
        listings[_listingId - 1].isActive = false;
        nftToListingId[listings[_listingId - 1].tokenId] = 0; // Remove listing association

        // Refund highest bidder if bid exists and listing is cancelled
        if (listingToHighestBidId[_listingId] != 0) {
            uint256 highestBidId = listingToHighestBidId[_listingId];
            if (bids[highestBidId - 1].isActive) {
                payable(bids[highestBidId - 1].bidder).transfer(bids[highestBidId - 1].amount);
                bids[highestBidId - 1].isActive = false; // Mark bid as inactive
                listingToHighestBidId[_listingId] = 0; // Reset highest bid for listing
            }
        }

        emit ListingCancelled(_listingId);
    }

    function cancelBid(uint256 _bidId) external bidExists(_bidId) onlyBidder(_bidId) whenNotPaused {
        require(bids[_bidId - 1].isActive, "Bid is not active.");
        require(listings[bids[_bidId - 1].listingId - 1].isActive, "Listing is not active."); // Check if listing is still active
        bids[_bidId - 1].isActive = false;

        // If this was the highest bid, reset listing's highest bid tracker
        if (listingToHighestBidId[bids[_bidId - 1].listingId] == _bidId) {
            listingToHighestBidId[bids[_bidId - 1].listingId] = 0;
        }

        payable(msg.sender).transfer(bids[_bidId - 1].amount); // Refund bid amount
        emit BidCancelled(_bidId);
    }

    function getListingDetails(uint256 _listingId) external view listingExists(_listingId) returns (Listing memory) {
        return listings[_listingId - 1];
    }

    function getNFTDetails(uint256 _tokenId) external view returns (NFT memory) {
        require(_tokenId > 0 && _tokenId <= nfts.length && nfts[_tokenId - 1].tokenId == _tokenId, "NFT does not exist.");
        return nfts[_tokenId - 1];
    }

    // --- Royalty Management ---
    function setDefaultRoyalty(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%.");
        defaultRoyaltyPercentage = _royaltyPercentage;
    }

    function setTokenRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) external onlyNFTOwner(_tokenId) {
        require(_tokenId > 0 && _tokenId <= nfts.length && nfts[_tokenId - 1].tokenId == _tokenId, "NFT does not exist.");
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%.");
        nfts[_tokenId - 1].royaltyPercentage = _royaltyPercentage;
    }

    function withdrawRoyalties() external {
        uint256 amount = creatorRoyaltiesDue[msg.sender];
        require(amount > 0, "No royalties due for withdrawal.");
        creatorRoyaltiesDue[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit RoyaltiesWithdrawn(msg.sender, amount);
    }

    // --- Marketplace Fee Management ---
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Marketplace fee percentage cannot exceed 100%.");
        marketplaceFeePercentage = _feePercentage;
    }

    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalanceExcludingRoyalties = balance;
        for (uint256 i = 0; i < nfts.length; i++) {
            contractBalanceExcludingRoyalties -= creatorRoyaltiesDue[nfts[i].creator];
        }
        require(contractBalanceExcludingRoyalties > 0, "No marketplace fees to withdraw.");
        payable(owner).transfer(contractBalanceExcludingRoyalties);
        emit MarketplaceFeesWithdrawn(owner, contractBalanceExcludingRoyalties);
    }

    // --- Pause/Unpause Marketplace ---
    function pauseMarketplace() external onlyOwner whenNotPaused {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyOwner whenPaused {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    // --- Governance (Simple Proposal System) ---
    function createProposal(string memory _description) external whenNotPaused {
        require(bytes(_description).length > 0, "Proposal description cannot be empty.");
        require(block.timestamp >= proposals[proposals.length-1].votingEndTime + 1 days || proposals.length == 0, "Wait for the last proposal to finish voting."); // Prevent spamming proposals, at least 1 day gap between proposals

        uint256 proposalId = nextProposalId++;
        proposals.push(Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            votingStartTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7 days voting period
            yesVotes: 0,
            noVotes: 0,
            isExecuted: false
        }));
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused proposalExists(_proposalId) {
        require(!hasVotedOnProposal[msg.sender], "You have already voted on this proposal.");
        require(block.timestamp >= proposals[_proposalId - 1].votingStartTime && block.timestamp <= proposals[_proposalId - 1].votingEndTime, "Voting is not active for this proposal.");

        hasVotedOnProposal[msg.sender] = true; // Mark user as voted
        if (_support) {
            proposals[_proposalId - 1].yesVotes++;
        } else {
            proposals[_proposalId - 1].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner proposalExists(_proposalId) whenNotPaused {
        require(!proposals[_proposalId - 1].isExecuted, "Proposal already executed.");
        require(block.timestamp > proposals[_proposalId - 1].votingEndTime, "Voting period is not over yet.");
        require(proposals[_proposalId - 1].yesVotes > proposals[_proposalId - 1].noVotes, "Proposal did not pass (not enough yes votes).");

        proposals[_proposalId - 1].isExecuted = true;
        // --- Basic Example Execution - Add actual logic based on proposal type ---
        // In a real-world scenario, you'd have different proposal types and execution logic.
        // For simplicity, this example just emits an event.
        emit ProposalExecuted(_proposalId);
        // --- Example: If the proposal was to change marketplace fee ---
        // if (proposals[_proposalId - 1].description == "Change marketplace fee to X%") {
        //     // Logic to parse X% from description and update marketplaceFeePercentage
        //     marketplaceFeePercentage = ...;
        // }
    }

    // --- Fallback and Receive Functions (Optional - for receiving ETH directly) ---
    receive() external payable {}
    fallback() external payable {}
}
```