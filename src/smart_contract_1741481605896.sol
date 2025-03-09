```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized NFT marketplace with dynamic NFTs,
 *      reputation system, fractional ownership, lending, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core NFT Functionality:**
 *    - `mintDynamicNFT(string memory _name, string memory _baseURI, string memory _initialDynamicData)`: Mints a new dynamic NFT.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership.
 *    - `getNFTOwner(uint256 _tokenId)`: Retrieves the owner of an NFT.
 *    - `getNFTDynamicData(uint256 _tokenId)`: Retrieves the dynamic data of an NFT.
 *    - `updateNFTDynamicData(uint256 _tokenId, string memory _newDynamicData)`: Updates the dynamic data of an NFT (Admin/Owner controlled).
 *
 * **2. Marketplace Listing & Trading:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale at a fixed price.
 *    - `unlistNFTFromSale(uint256 _tokenId)`: Removes an NFT listing from sale.
 *    - `buyNFT(uint256 _tokenId)`: Buys a listed NFT.
 *    - `getListingPrice(uint256 _tokenId)`: Retrieves the listing price of an NFT.
 *    - `isNFTListed(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **3. Auction Functionality:**
 *    - `createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration)`: Creates an auction for an NFT.
 *    - `bidOnAuction(uint256 _auctionId)`: Places a bid on an active auction.
 *    - `endAuction(uint256 _auctionId)`: Ends an auction and settles the sale to the highest bidder.
 *    - `getAuctionDetails(uint256 _auctionId)`: Retrieves details of a specific auction.
 *    - `getActiveAuctions()`: Returns a list of active auction IDs.
 *
 * **4. Fractional Ownership (DAO Based):**
 *    - `fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions)`: Fractionalizes an NFT into a specified number of fungible tokens.
 *    - `redeemNFTFraction(uint256 _fractionTokenId)`: Allows fraction token holders to redeem their fractions for a share of the NFT (DAO voting needed).
 *    - `getFractionTokenSupply(uint256 _tokenId)`: Gets the total supply of fraction tokens for an NFT.
 *    - `getFractionTokenBalance(uint256 _tokenId, address _account)`: Gets the fraction token balance of an account for an NFT.
 *
 * **5. NFT Lending & Borrowing:**
 *    - `lendNFT(uint256 _tokenId, uint256 _loanAmount, uint256 _loanDuration)`: Offers an NFT for lending at a specified loan amount and duration.
 *    - `borrowNFT(uint256 _loanId)`: Borrows an NFT based on a lending offer.
 *    - `repayLoan(uint256 _loanId)`: Repays a loan and returns the NFT to the lender.
 *    - `liquidateLoan(uint256 _loanId)`: Liquidates a loan if the borrower defaults, transferring NFT ownership to the lender.
 *    - `getLoanDetails(uint256 _loanId)`: Retrieves details of a specific loan.
 *
 * **6. Reputation System (NFT-Based Badges):**
 *    - `awardReputationBadge(address _user, string memory _badgeName, string memory _badgeURI)`: Awards a reputation badge NFT to a user (Admin controlled).
 *    - `getUserReputationBadges(address _user)`: Retrieves a list of reputation badge NFTs owned by a user.
 *
 * **7. Utility & Admin Functions:**
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (Admin only).
 *    - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees (Admin only).
 *    - `pauseContract()`: Pauses all marketplace functionalities (Admin only).
 *    - `unpauseContract()`: Resumes marketplace functionalities (Admin only).
 */

contract DynamicNFTMarketplace {
    // --- State Variables ---

    // NFT Metadata and Dynamic Data
    uint256 public nextNFTId = 1;
    mapping(uint256 => address) public nftOwner;
    mapping(uint256 => string) public nftBaseURI;
    mapping(uint256 => string) public nftDynamicData;
    mapping(uint256 => string) public nftName;

    // Marketplace Listings
    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;

    // Auction Data
    struct Auction {
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 startingBid;
        uint256 highestBid;
        address highestBidder;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId = 1;

    // Fractional Ownership Data
    mapping(uint256 => uint256) public fractionTokenSupply; // NFT ID => total fraction tokens
    mapping(uint256 => mapping(address => uint256)) public fractionTokenBalances; // NFT ID => (address => balance)
    mapping(uint256 => uint256) public nftToFractionTokenId; // NFT ID => Fraction Token ID (for ERC20 representation)
    uint256 public nextFractionTokenId = 1;

    // Lending Data
    struct LoanOffer {
        uint256 tokenId;
        uint256 loanAmount;
        uint256 loanDuration; // in seconds
        address lender;
        bool isActive;
    }
    mapping(uint256 => LoanOffer) public loanOffers;
    uint256 public nextLoanId = 1;
    mapping(uint256 => uint256) public loanStartTime; // loanId => startTime
    mapping(uint256 => uint256) public loanEndTime;   // loanId => endTime

    // Reputation Badges
    uint256 public nextBadgeId = 1;
    mapping(uint256 => string) public badgeName;
    mapping(uint256 => string) public badgeURI;
    mapping(address => uint256[]) public userBadges; // address => array of badge NFT IDs

    // Marketplace Fees
    uint256 public marketplaceFeePercentage = 2; // Default 2% fee
    address payable public contractOwner;
    uint256 public accumulatedFees;

    // Contract State
    bool public paused = false;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner, string name);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTUnlistedFromSale(uint256 tokenId, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingBid, uint256 duration, address seller);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 auctionId, uint256 tokenId, address winner, uint256 price);
    event NFTFractionalized(uint256 tokenId, uint256 fractionTokenId, uint256 numberOfFractions);
    event NFTFractionRedeemed(uint256 tokenId, address redeemer, uint256 fractionAmount);
    event NFTLoanOffered(uint256 loanId, uint256 tokenId, uint256 loanAmount, uint256 duration, address lender);
    event NFTLoanBorrowed(uint256 loanId, uint256 tokenId, address borrower);
    event LoanRepaid(uint256 loanId, uint256 tokenId, address borrower, address lender);
    event LoanLiquidated(uint256 loanId, uint256 tokenId, address lender, address borrower);
    event ReputationBadgeAwarded(uint256 badgeId, address user, string badgeName);
    event ContractPaused();
    event ContractUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);
    event FeesWithdrawn(uint256 amount, address admin);


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

    modifier nftExists(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwner[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier auctionExists(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction does not exist or is not active.");
        _;
    }

    modifier loanOfferExists(uint256 _loanId) {
        require(loanOffers[_loanId].isActive, "Loan offer does not exist or is not active.");
        _;
    }


    // --- Constructor ---
    constructor() payable {
        contractOwner = payable(msg.sender);
    }

    // --- 1. Core NFT Functionality ---

    /**
     * @dev Mints a new dynamic NFT.
     * @param _name The name of the NFT.
     * @param _baseURI The base URI for the NFT metadata.
     * @param _initialDynamicData Initial dynamic data associated with the NFT.
     */
    function mintDynamicNFT(string memory _name, string memory _baseURI, string memory _initialDynamicData) external whenNotPaused {
        uint256 tokenId = nextNFTId++;
        nftOwner[tokenId] = msg.sender;
        nftBaseURI[tokenId] = _baseURI;
        nftDynamicData[tokenId] = _initialDynamicData;
        nftName[tokenId] = _name;

        emit NFTMinted(tokenId, msg.sender, _name);
    }

    /**
     * @dev Transfers NFT ownership.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /**
     * @dev Retrieves the owner of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function getNFTOwner(uint256 _tokenId) external view nftExists(_tokenId) returns (address) {
        return nftOwner[_tokenId];
    }

    /**
     * @dev Retrieves the dynamic data of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The dynamic data string of the NFT.
     */
    function getNFTDynamicData(uint256 _tokenId) external view nftExists(_tokenId) returns (string memory) {
        return nftDynamicData[_tokenId];
    }

    /**
     * @dev Updates the dynamic data of an NFT (Admin/Owner controlled - in this example, only owner).
     * @param _tokenId The ID of the NFT.
     * @param _newDynamicData The new dynamic data string.
     */
    function updateNFTDynamicData(uint256 _tokenId, string memory _newDynamicData) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        nftDynamicData[_tokenId] = _newDynamicData;
    }


    // --- 2. Marketplace Listing & Trading ---

    /**
     * @dev Lists an NFT for sale at a fixed price.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        require(!nftListings[_tokenId].isActive, "NFT is already listed for sale.");

        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Removes an NFT listing from sale.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistNFTFromSale(uint256 _tokenId) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) listingExists(_tokenId) {
        require(nftListings[_tokenId].seller == msg.sender, "Only the seller can unlist.");

        nftListings[_tokenId].isActive = false;
        emit NFTUnlistedFromSale(_tokenId, msg.sender);
    }

    /**
     * @dev Buys a listed NFT.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) external payable whenNotPaused nftExists(_tokenId) listingExists(_tokenId) {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds sent.");
        require(listing.seller != msg.sender, "Seller cannot buy their own NFT.");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - feeAmount;

        accumulatedFees += feeAmount;
        payable(listing.seller).transfer(sellerProceeds);
        nftOwner[_tokenId] = msg.sender;
        listing.isActive = false; // Deactivate listing

        emit NFTBought(_tokenId, msg.sender, listing.seller, listing.price);
        emit NFTTransferred(_tokenId, listing.seller, msg.sender);

        // Refund excess payment if any
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    /**
     * @dev Retrieves the listing price of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The listing price in wei.
     */
    function getListingPrice(uint256 _tokenId) external view nftExists(_tokenId) listingExists(_tokenId) returns (uint256) {
        return nftListings[_tokenId].price;
    }

    /**
     * @dev Checks if an NFT is currently listed for sale.
     * @param _tokenId The ID of the NFT.
     * @return True if listed, false otherwise.
     */
    function isNFTListed(uint256 _tokenId) external view nftExists(_tokenId) returns (bool) {
        return nftListings[_tokenId].isActive;
    }


    // --- 3. Auction Functionality ---

    /**
     * @dev Creates an auction for an NFT.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startingBid The starting bid price in wei.
     * @param _auctionDuration The duration of the auction in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startingBid, uint256 _auctionDuration) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_startingBid > 0, "Starting bid must be greater than zero.");
        require(_auctionDuration > 0 && _auctionDuration <= 7 days, "Auction duration must be between 1 second and 7 days."); // Example limit

        uint256 auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            tokenId: _tokenId,
            startTime: block.timestamp,
            endTime: block.timestamp + _auctionDuration,
            startingBid: _startingBid,
            highestBid: _startingBid,
            highestBidder: address(0), // No bidder initially
            isActive: true
        });

        emit AuctionCreated(auctionId, _tokenId, _startingBid, _auctionDuration, msg.sender);
    }

    /**
     * @dev Places a bid on an active auction.
     * @param _auctionId The ID of the auction.
     */
    function bidOnAuction(uint256 _auctionId) external payable whenNotPaused auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction has already ended.");
        require(msg.value >= auction.highestBid, "Bid amount must be greater than the current highest bid.");
        require(nftOwner[auction.tokenId] != msg.sender, "Owner cannot bid on their own NFT auction.");

        if (auction.highestBidder != address(0)) {
            // Refund previous highest bidder
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    /**
     * @dev Ends an auction and settles the sale to the highest bidder.
     * @param _auctionId The ID of the auction to end.
     */
    function endAuction(uint256 _auctionId) external whenNotPaused auctionExists(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction is not yet ended.");
        require(auction.isActive, "Auction is not active.");

        auction.isActive = false; // Deactivate auction
        uint256 tokenId = auction.tokenId;

        if (auction.highestBidder != address(0)) {
            uint256 feeAmount = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerProceeds = auction.highestBid - feeAmount;

            accumulatedFees += feeAmount;
            payable(nftOwner[tokenId]).transfer(sellerProceeds);
            nftOwner[tokenId] = auction.highestBidder; // Transfer NFT to highest bidder

            emit AuctionEnded(_auctionId, tokenId, auction.highestBidder, auction.highestBid);
            emit NFTTransferred(tokenId, nftOwner[tokenId], auction.highestBidder); // Emit NFT transfer event
        } else {
            // No bids, return NFT to owner (no sale)
            emit AuctionEnded(_auctionId, tokenId, address(0), 0); // Auction ended with no winner
        }
    }

    /**
     * @dev Retrieves details of a specific auction.
     * @param _auctionId The ID of the auction.
     * @return Auction details struct.
     */
    function getAuctionDetails(uint256 _auctionId) external view auctionExists(_auctionId) returns (Auction memory) {
        return auctions[_auctionId];
    }

    /**
     * @dev Returns a list of active auction IDs.
     * @return Array of active auction IDs.
     */
    function getActiveAuctions() external view returns (uint256[] memory) {
        uint256[] memory activeAuctionIds = new uint256[](nextAuctionId - 1);
        uint256 count = 0;
        for (uint256 i = 1; i < nextAuctionId; i++) {
            if (auctions[i].isActive) {
                activeAuctionIds[count++] = i;
            }
        }
        // Resize the array to remove extra slots if fewer auctions are active than initially allocated
        assembly {
            mstore(activeAuctionIds, count) // Update the length of the array
        }
        return activeAuctionIds;
    }


    // --- 4. Fractional Ownership (DAO Based - Simplified in this example) ---

    /**
     * @dev Fractionalizes an NFT into a specified number of fungible tokens.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _numberOfFractions The number of fungible tokens to create.
     */
    function fractionalizeNFT(uint256 _tokenId, uint256 _numberOfFractions) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero.");
        require(fractionTokenSupply[_tokenId] == 0, "NFT is already fractionalized.");

        uint256 fractionTokenId = nextFractionTokenId++;
        nftToFractionTokenId[_tokenId] = fractionTokenId;
        fractionTokenSupply[_tokenId] = _numberOfFractions;
        fractionTokenBalances[_tokenId][msg.sender] = _numberOfFractions; // Owner gets all initial fraction tokens

        emit NFTFractionalized(_tokenId, fractionTokenId, _numberOfFractions);
    }

    /**
     * @dev Allows fraction token holders to redeem their fractions for a share of the NFT (DAO voting needed - simplified here, just owner redeem).
     * @param _fractionTokenId The ID of the fraction token (not NFT token ID).
     */
    function redeemNFTFraction(uint256 _fractionTokenId) external whenNotPaused {
        // In a real DAO implementation, this would be triggered by a DAO vote.
        // For simplicity, let's assume only the original NFT owner can redeem (for demonstration purposes).
        uint256 originalNFTTokenId;
        for (uint256 nftId = 1; nftId < nextNFTId; nftId++) {
            if (nftToFractionTokenId[nftId] == _fractionTokenId) {
                originalNFTTokenId = nftId;
                break;
            }
        }
        require(originalNFTTokenId > 0, "Invalid fraction token ID.");
        require(nftOwner[originalNFTTokenId] == msg.sender, "Only the original NFT owner can redeem in this simplified example.");

        // In a real implementation, this would involve a more complex logic to distribute the NFT
        // or its value proportionally to fraction holders based on DAO voting.
        // For this example, we just log an event.
        emit NFTFractionRedeemed(originalNFTTokenId, msg.sender, fractionTokenSupply[originalNFTTokenId]);
        // In a real scenario, you might burn the fraction tokens and transfer the NFT ownership to a DAO or multisig.
    }

    /**
     * @dev Gets the total supply of fraction tokens for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The total supply of fraction tokens.
     */
    function getFractionTokenSupply(uint256 _tokenId) external view nftExists(_tokenId) returns (uint256) {
        return fractionTokenSupply[_tokenId];
    }

    /**
     * @dev Gets the fraction token balance of an account for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _account The address to check the balance for.
     * @return The fraction token balance of the account.
     */
    function getFractionTokenBalance(uint256 _tokenId, address _account) external view nftExists(_tokenId) returns (uint256) {
        return fractionTokenBalances[_tokenId][_account];
    }


    // --- 5. NFT Lending & Borrowing ---

    /**
     * @dev Offers an NFT for lending at a specified loan amount and duration.
     * @param _tokenId The ID of the NFT to lend.
     * @param _loanAmount The amount to be borrowed against the NFT.
     * @param _loanDuration The duration of the loan in seconds.
     */
    function lendNFT(uint256 _tokenId, uint256 _loanAmount, uint256 _loanDuration) external whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(_loanAmount > 0, "Loan amount must be greater than zero.");
        require(_loanDuration > 0, "Loan duration must be greater than zero.");
        require(!loanOffers[_tokenId].isActive, "NFT is already offered for lending.");

        uint256 loanId = nextLoanId++;
        loanOffers[loanId] = LoanOffer({
            tokenId: _tokenId,
            loanAmount: _loanAmount,
            loanDuration: _loanDuration,
            lender: msg.sender,
            isActive: true
        });

        emit NFTLoanOffered(loanId, _tokenId, _loanAmount, _loanDuration, msg.sender);
    }

    /**
     * @dev Borrows an NFT based on a lending offer.
     * @param _loanId The ID of the loan offer.
     */
    function borrowNFT(uint256 _loanId) external payable whenNotPaused loanOfferExists(_loanId) {
        LoanOffer storage offer = loanOffers[_loanId];
        require(offer.isActive, "Loan offer is not active.");
        require(msg.value >= offer.loanAmount, "Insufficient loan amount sent.");
        require(nftOwner[offer.tokenId] == offer.lender, "Lender is not the NFT owner anymore."); // Double check owner

        nftOwner[offer.tokenId] = msg.sender; // Transfer NFT to borrower (temporarily)
        loanStartTime[_loanId] = block.timestamp;
        loanEndTime[_loanId] = block.timestamp + offer.loanDuration;
        offer.isActive = false; // Deactivate loan offer

        emit NFTLoanBorrowed(_loanId, offer.tokenId, msg.sender);
        emit NFTTransferred(offer.tokenId, offer.lender, msg.sender); // Temporary transfer event
    }

    /**
     * @dev Repays a loan and returns the NFT to the lender.
     * @param _loanId The ID of the loan.
     */
    function repayLoan(uint256 _loanId) external payable whenNotPaused loanOfferExists(_loanId) {
        LoanOffer storage offer = loanOffers[_loanId];
        require(nftOwner[offer.tokenId] == msg.sender, "Only the borrower can repay the loan.");
        require(block.timestamp <= loanEndTime[_loanId], "Loan duration has expired."); // Still within loan period
        require(msg.value >= offer.loanAmount, "Insufficient repayment amount sent.");

        nftOwner[offer.tokenId] = offer.lender; // Return NFT to lender
        payable(offer.lender).transfer(offer.loanAmount); // Pay back loan amount

        emit LoanRepaid(_loanId, offer.tokenId, msg.sender, offer.lender);
        emit NFTTransferred(offer.tokenId, msg.sender, offer.lender); // Return transfer event
    }

    /**
     * @dev Liquidates a loan if the borrower defaults, transferring NFT ownership to the lender.
     * @param _loanId The ID of the loan.
     */
    function liquidateLoan(uint256 _loanId) external whenNotPaused loanOfferExists(_loanId) {
        LoanOffer storage offer = loanOffers[_loanId];
        require(block.timestamp > loanEndTime[_loanId], "Loan duration has not expired yet."); // Loan expired
        require(nftOwner[offer.tokenId] != offer.lender, "Lender already owns the NFT."); // NFT not with lender

        nftOwner[offer.tokenId] = offer.lender; // Lender reclaims NFT
        offer.isActive = false; // Deactivate loan offer

        emit LoanLiquidated(_loanId, offer.tokenId, offer.lender, nftOwner[offer.tokenId]);
        emit NFTTransferred(offer.tokenId, nftOwner[offer.tokenId], offer.lender); // Transfer back event
    }

    /**
     * @dev Retrieves details of a specific loan.
     * @param _loanId The ID of the loan.
     * @return Loan details struct.
     */
    function getLoanDetails(uint256 _loanId) external view loanOfferExists(_loanId) returns (LoanOffer memory, uint256 startTime, uint256 endTime) {
        return (loanOffers[_loanId], loanStartTime[_loanId], loanEndTime[_loanId]);
    }


    // --- 6. Reputation System (NFT-Based Badges) ---

    /**
     * @dev Awards a reputation badge NFT to a user (Admin controlled).
     * @param _user The address to award the badge to.
     * @param _badgeName The name of the badge.
     * @param _badgeURI The URI for the badge metadata.
     */
    function awardReputationBadge(address _user, string memory _badgeName, string memory _badgeURI) external onlyOwner whenNotPaused {
        uint256 badgeId = nextBadgeId++;
        badgeName[badgeId] = _badgeName;
        badgeURI[badgeId] = _badgeURI;
        nftOwner[badgeId] = _user; // Badge ownership

        userBadges[_user].push(badgeId); // Add badge to user's badge list

        emit ReputationBadgeAwarded(badgeId, _user, _badgeName);
    }

    /**
     * @dev Retrieves a list of reputation badge NFTs owned by a user.
     * @param _user The address to check for badges.
     * @return Array of reputation badge NFT IDs.
     */
    function getUserReputationBadges(address _user) external view returns (uint256[] memory) {
        return userBadges[_user];
    }


    // --- 7. Utility & Admin Functions ---

    /**
     * @dev Sets the marketplace fee percentage (Admin only).
     * @param _feePercentage The new marketplace fee percentage.
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees (Admin only).
     */
    function withdrawMarketplaceFees() external onlyOwner whenNotPaused {
        uint256 amountToWithdraw = accumulatedFees;
        accumulatedFees = 0; // Reset accumulated fees
        payable(contractOwner).transfer(amountToWithdraw);
        emit FeesWithdrawn(amountToWithdraw, contractOwner);
    }

    /**
     * @dev Pauses all marketplace functionalities (Admin only).
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes marketplace functionalities (Admin only).
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback and Receive Functions (Optional for this example, but good practice) ---
    receive() external payable {} // To receive ETH for buying NFTs etc.
    fallback() external payable {}
}
```