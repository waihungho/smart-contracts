```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace with advanced features like dynamic metadata,
 *      renting, lending, staking, auctions, governance, and reputation system.
 *      This contract is designed to be creative and explore advanced concepts, avoiding duplication
 *      of common open-source marketplace implementations.
 *
 * **Outline:**
 *
 * **State Variables:**
 *   - Marketplace Parameters (fee, dynamic metadata update interval)
 *   - NFT Collection Management (supported collections, royalty settings)
 *   - NFT Listing and Auction Data
 *   - Renting and Lending Data
 *   - Staking Information
 *   - Reputation System Data
 *   - Governance Parameters and Proposals
 *   - Contract Paused State
 *   - Admin and Operator Roles
 *
 * **Events:**
 *   - NFT Minted, Listed, Sold, AuctionStarted, BidPlaced, AuctionEnded, Rented, Lent, Staked, Unstaked,
 *     MetadataUpdated, ParameterChanged, GovernanceProposalCreated, VoteCast, ReputationUpdated, ContractPaused, ContractUnpaused
 *
 * **Modifiers:**
 *   - onlyOwner, onlyOperator, onlyMarketplace, onlyValidListing, onlyValidAuction,
 *     onlyNotPaused, nonReentrant, onlyNFTCollection
 *
 * **Functions:**
 *
 * **NFT Management:**
 *   1. `mintNFT(address _collectionAddress, string memory _tokenURI, bytes memory _dynamicData) external`: Mints a new NFT in a supported collection with initial dynamic data.
 *   2. `setNFTCollectionSupport(address _collectionAddress, bool _supported, uint256 _royaltyFee)` external onlyOwner: Adds or removes support for an NFT collection and sets royalty fee.
 *   3. `updateNFTMetadata(address _collectionAddress, uint256 _tokenId, bytes memory _dynamicData) external onlyNFTCollection`: Updates the dynamic metadata of an NFT (permissioned, can be triggered by owner, oracle, etc.).
 *   4. `getNFTDynamicMetadata(address _collectionAddress, uint256 _tokenId) external view returns (bytes memory)`: Retrieves the dynamic metadata of an NFT.
 *
 * **Marketplace Listing and Selling:**
 *   5. `listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price) external onlyNFTCollection`: Lists an NFT for sale at a fixed price.
 *   6. `buyNFT(address _collectionAddress, uint256 _tokenId) external payable`: Buys an NFT listed for sale.
 *   7. `cancelNFTSaleListing(address _collectionAddress, uint256 _tokenId) external`: Cancels an NFT sale listing.
 *   8. `setMarketplaceFee(uint256 _feePercentage) external onlyOwner`: Sets the marketplace fee percentage.
 *   9. `withdrawMarketplaceFees() external onlyOwner`: Allows admin to withdraw accumulated marketplace fees.
 *
 * **Auction Features:**
 *   10. `startAuction(address _collectionAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _durationSeconds) external onlyNFTCollection`: Starts an English auction for an NFT.
 *   11. `bidInAuction(address _collectionAddress, uint256 _tokenId) external payable`: Places a bid in an ongoing auction.
 *   12. `endAuction(address _collectionAddress, uint256 _tokenId) external`: Ends an auction and settles the sale.
 *   13. `cancelAuction(address _collectionAddress, uint256 _tokenId) external`: Cancels an auction before it ends.
 *
 * **NFT Renting and Lending:**
 *   14. `rentNFT(address _collectionAddress, uint256 _tokenId, uint256 _rentPerDay, uint256 _rentalDays) external onlyNFTCollection`: Lists an NFT for rent.
 *   15. `borrowNFT(address _collectionAddress, uint256 _tokenId, uint256 _rentalDays) external payable`: Borrows a listed NFT for rent.
 *   16. `returnRentedNFT(address _collectionAddress, uint256 _tokenId) external`: Returns a rented NFT.
 *   17. `lendNFT(address _collectionAddress, uint256 _tokenId, uint256 _collateralAmount, uint256 _loanDurationDays, uint256 _interestRatePercent) external onlyNFTCollection`: Lists an NFT for lending with collateral and interest.
 *   18. `borrowLentNFT(address _collectionAddress, uint256 _tokenId) external payable`: Borrows a lent NFT by providing collateral.
 *   19. `repayLoanAndRetrieveNFT(address _collectionAddress, uint256 _tokenId) external payable`: Repays the loan and retrieves the lent NFT.
 *   20. `liquidateLoanedNFT(address _collectionAddress, uint256 _tokenId) external`: Liquidates a loan if not repaid in time and claims the collateral.
 *
 * **Staking and Reputation (Conceptual - can be expanded):**
 *   21. `stakeNFT(address _collectionAddress, uint256 _tokenId) external onlyNFTCollection`: Stakes an NFT in the marketplace (for potential rewards or benefits).
 *   22. `unstakeNFT(address _collectionAddress, uint256 _tokenId) external`: Unstakes an NFT.
 *   23. `updateUserReputation(address _user, int256 _reputationChange) external onlyOperator`: Updates user reputation score based on marketplace activity (e.g., successful trades, disputes).
 *   24. `getUserReputation(address _user) external view returns (int256)`: Retrieves a user's reputation score.
 *
 * **Governance (Simplified Example - can be expanded):**
 *   25. `createGovernanceProposal(string memory _description, bytes memory _data) external onlyOperator`: Creates a governance proposal (e.g., parameter changes).
 *   26. `voteOnProposal(uint256 _proposalId, bool _support) external`: Allows users to vote on a governance proposal (voting power can be NFT-based).
 *   27. `executeGovernanceProposal(uint256 _proposalId) external onlyOperator`: Executes a passed governance proposal.
 *
 * **Admin and Utility:**
 *   28. `setOperator(address _operatorAddress) external onlyOwner`: Sets a new operator address.
 *   29. `pauseContract() external onlyOwner`: Pauses core marketplace functionalities.
 *   30. `unpauseContract() external onlyOwner`: Unpauses the contract.
 *   31. `supportsInterface(bytes4 interfaceId) external view override returns (bool)`: Interface support (for standard contract discovery).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example for potential future use in dynamic metadata verification

contract DynamicNFTMarketplace is Ownable, ReentrancyGuard, IERC721Receiver {
    // --- State Variables ---

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address public operator; // Operator role for certain privileged actions
    bool public paused = false; // Contract paused state

    struct NFTCollection {
        bool isSupported;
        uint256 royaltyFeePercentage;
    }
    mapping(address => NFTCollection) public nftCollections; // Supported NFT collections and their royalty fees

    struct NFTSaleListing {
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTSaleListing)) public nftSaleListings; // NFT sale listings

    struct NFTAuction {
        address collectionAddress;
        uint256 tokenId;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        address seller;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTAuction)) public nftAuctions; // NFT auctions

    struct NFTRentalListing {
        address collectionAddress;
        uint256 tokenId;
        uint256 rentPerDay;
        address owner;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTRentalListing)) public nftRentalListings; // NFT rental listings

    struct NFTRental {
        address collectionAddress;
        uint256 tokenId;
        address renter;
        uint256 rentalDays;
        uint256 endTime;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTRental)) public nftRentals; // Active NFT rentals

    struct NFTLoanListing {
        address collectionAddress;
        uint256 tokenId;
        uint256 collateralAmount;
        uint256 loanDurationDays;
        uint256 interestRatePercent;
        address lender;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTLoanListing)) public nftLoanListings; // NFT loan listings

    struct NFTLoan {
        address collectionAddress;
        uint256 tokenId;
        address borrower;
        uint256 collateralAmount;
        uint256 loanDurationDays;
        uint256 interestRatePercent;
        uint256 endTime;
        bool isActive;
    }
    mapping(address => mapping(uint256 => NFTLoan)) public nftLoans; // Active NFT loans

    mapping(address => mapping(uint256 => bytes)) public nftDynamicMetadata; // Dynamic metadata for NFTs

    mapping(address => int256) public userReputation; // User reputation scores

    struct GovernanceProposal {
        string description;
        bytes data;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public proposalCount = 0;

    // --- Events ---

    event NFTMinted(address collectionAddress, uint256 tokenId, address minter);
    event NFTCollectionSupportUpdated(address collectionAddress, bool supported, uint256 royaltyFee);
    event NFTMetadataUpdated(address collectionAddress, uint256 tokenId);
    event NFTListedForSale(address collectionAddress, uint256 tokenId, uint256 price, address seller);
    event NFTSold(address collectionAddress, uint256 tokenId, address seller, address buyer, uint256 price);
    event NFTSaleListingCancelled(address collectionAddress, uint256 tokenId, address seller);
    event MarketplaceFeeUpdated(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(address admin, uint256 amount);

    event AuctionStarted(address collectionAddress, uint256 tokenId, uint256 startingPrice, uint256 endTime, address seller);
    event BidPlaced(address collectionAddress, uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(address collectionAddress, uint256 tokenId, address winner, uint256 winningBid);
    event AuctionCancelled(address collectionAddress, uint256 tokenId, address seller);

    event NFTRented(address collectionAddress, uint256 tokenId, address renter, uint256 rentalDays);
    event NFTRentalReturned(address collectionAddress, uint256 tokenId, address renter);
    event NFTListedForRent(address collectionAddress, uint256 tokenId, uint256 rentPerDay, address owner);

    event NFTLent(address collectionAddress, uint256 tokenId, address borrower, uint256 collateralAmount, uint256 loanDurationDays, uint256 interestRatePercent);
    event NFTLoanRepaid(address collectionAddress, uint256 tokenId, address borrower);
    event NFTLoanLiquidated(address collectionAddress, uint256 tokenId, address borrower, address liquidator);
    event NFTListedForLending(address collectionAddress, uint256 tokenId, uint256 collateralAmount, uint256 loanDurationDays, uint256 interestRatePercent, address lender);

    event NFTStaked(address collectionAddress, uint256 tokenId, address staker);
    event NFTUnstaked(address collectionAddress, uint256 tokenId, address unstaker);
    event UserReputationUpdated(address user, int256 reputationChange, int256 newReputation);

    event GovernanceProposalCreated(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyOwnerOrOperator() {
        require(_msgSender() == owner() || _msgSender() == operator, "Caller is not owner or operator");
        _;
    }

    modifier onlyOperator() {
        require(_msgSender() == operator, "Caller is not operator");
        _;
    }

    modifier onlyMarketplace() {
        require(msg.sender == address(this), "Only marketplace contract can call this");
        _;
    }

    modifier onlyValidListing(address _collectionAddress, uint256 _tokenId) {
        require(nftSaleListings[_collectionAddress][_tokenId].isActive, "Listing is not active or not found");
        _;
    }

    modifier onlyValidAuction(address _collectionAddress, uint256 _tokenId) {
        require(nftAuctions[_collectionAddress][_tokenId].isActive, "Auction is not active or not found");
        _;
    }

    modifier onlyNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier nonReentrantMarketplace() override nonReentrant {
        _;
    }

    modifier onlyNFTCollection(address _collectionAddress) {
        require(nftCollections[_collectionAddress].isSupported, "NFT Collection not supported");
        _;
    }

    // --- Constructor ---

    constructor() payable Ownable() {
        operator = _msgSender(); // Set the deployer as the initial operator
    }

    // --- NFT Management Functions ---

    function mintNFT(address _collectionAddress, string memory _tokenURI, bytes memory _dynamicData) external onlyNFTCollection {
        IERC721 nftContract = IERC721(_collectionAddress);
        uint256 tokenId = _getNextTokenId(_collectionAddress); // Implement logic to get next token ID (e.g., from collection contract or internal counter)
        // In a real scenario, you would ideally call a mint function on the NFT collection contract itself if possible,
        // or have a mechanism to ensure token ID uniqueness if minting directly from this marketplace contract.
        // For simplicity in this example, we assume minting can be done (e.g., if this marketplace is also the minter).
        // **Important**: This is a simplified minting example. Real-world minting needs careful consideration of token ID generation and access control.

        // **Placeholder for actual minting logic.  Consider using a factory pattern or interacting with the NFT collection contract's mint function if available.**
        // For demonstration purposes, we'll assume the NFT collection has a `mint` function or similar.
        // nftContract.mint(_msgSender(), tokenId, _tokenURI); // Example - needs to be adapted to the actual NFT collection contract.
        // For now, we'll assume token ownership is assigned directly for demonstration.
        address minter = _msgSender();
        // **In a real application, you'd need to handle minting in a secure and controlled way.**
        // For this example, we'll just emit an event as if minting occurred.
        emit NFTMinted(_collectionAddress, tokenId, minter); // Emit event as if minting happened.

        nftDynamicMetadata[_collectionAddress][tokenId] = _dynamicData; // Set initial dynamic metadata
        emit NFTMetadataUpdated(_collectionAddress, tokenId);
    }

    // Placeholder function for getting next token ID.  Needs to be implemented based on your NFT collection logic.
    function _getNextTokenId(address _collectionAddress) internal pure returns (uint256) {
        // **Important: This is a placeholder.** In a real implementation, you need a proper way to get the next token ID.
        // This could involve querying the NFT collection contract, using a counter, or other methods.
        // For this example, we'll just return a hardcoded value for demonstration.
        return 1; // **Replace this with actual logic to get the next token ID.**
    }


    function setNFTCollectionSupport(address _collectionAddress, bool _supported, uint256 _royaltyFeePercentage) external onlyOwner {
        require(_royaltyFeePercentage <= 10000, "Royalty fee percentage too high (max 100%)"); // Max 100% royalty (10000 basis points)
        nftCollections[_collectionAddress] = NFTCollection({
            isSupported: _supported,
            royaltyFeePercentage: _royaltyFeePercentage
        });
        emit NFTCollectionSupportUpdated(_collectionAddress, _supported, _royaltyFeePercentage);
    }

    function updateNFTMetadata(address _collectionAddress, uint256 _tokenId, bytes memory _dynamicData) external onlyNFTCollection {
        // In a real dynamic NFT system, you might have more complex logic for who can update metadata,
        // potentially involving oracles, game logic, or NFT ownership checks.
        // For this example, we'll allow anyone to update metadata for demonstration.
        nftDynamicMetadata[_collectionAddress][_tokenId] = _dynamicData;
        emit NFTMetadataUpdated(_collectionAddress, _tokenId);
    }

    function getNFTDynamicMetadata(address _collectionAddress, uint256 _tokenId) external view returns (bytes memory) {
        return nftDynamicMetadata[_collectionAddress][_tokenId];
    }

    // --- Marketplace Listing and Selling Functions ---

    function listNFTForSale(address _collectionAddress, uint256 _tokenId, uint256 _price) external onlyNotPaused onlyNFTCollection nonReentrantMarketplace {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than 0");
        require(!nftSaleListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for sale");
        require(!nftAuctions[_collectionAddress][_tokenId].isActive, "NFT is already in auction");
        require(!nftRentalListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for rent");
        require(!nftLoanListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for lending");

        // Approve marketplace to handle transfer
        nftContract.approve(address(this), _tokenId);

        nftSaleListings[_collectionAddress][_tokenId] = NFTSaleListing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            price: _price,
            seller: _msgSender(),
            isActive: true
        });
        emit NFTListedForSale(_collectionAddress, _tokenId, _price, _msgSender());
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId) external payable onlyNotPaused onlyValidListing(_collectionAddress, _tokenId) nonReentrantMarketplace {
        NFTSaleListing storage listing = nftSaleListings[_collectionAddress][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        IERC721 nftContract = IERC721(listing.collectionAddress);

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(listing.seller, _msgSender(), listing.tokenId);

        // Calculate and pay seller and royalty
        uint256 sellerCut = listing.price * (10000 - marketplaceFeePercentage) / 10000;
        uint256 marketplaceFee = listing.price - sellerCut;
        uint256 royaltyFee = 0;
        if (nftCollections[listing.collectionAddress].royaltyFeePercentage > 0) {
            royaltyFee = listing.price * nftCollections[listing.collectionAddress].royaltyFeePercentage / 10000;
            sellerCut -= royaltyFee;
            // **In a real implementation, you would need to know the royalty recipient and send funds appropriately.**
            // For this example, we assume royalties are sent to the NFT creator (which might need to be tracked).
            // Placeholder for royalty payment logic.
        }

        payable(listing.seller).transfer(sellerCut);
        payable(owner()).transfer(marketplaceFee); // Marketplace fees to contract owner

        listing.isActive = false; // Deactivate listing
        emit NFTSold(_collectionAddress, _tokenId, listing.seller, _msgSender(), listing.price);
    }

    function cancelNFTSaleListing(address _collectionAddress, uint256 _tokenId) external onlyNotPaused onlyValidListing(_collectionAddress, _tokenId) nonReentrantMarketplace {
        NFTSaleListing storage listing = nftSaleListings[_collectionAddress][_tokenId];
        require(listing.seller == _msgSender(), "Only seller can cancel listing");

        listing.isActive = false; // Deactivate listing
        emit NFTSaleListingCancelled(_collectionAddress, _tokenId, _msgSender());
    }

    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10000, "Marketplace fee percentage too high (max 100%)"); // Max 100% fee (10000 basis points)
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit MarketplaceFeesWithdrawn(owner(), balance);
    }

    // --- Auction Functions ---

    function startAuction(address _collectionAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _durationSeconds) external onlyNotPaused onlyNFTCollection nonReentrantMarketplace {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_startingPrice > 0, "Starting price must be greater than 0");
        require(_durationSeconds > 0, "Auction duration must be greater than 0");
        require(!nftSaleListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for sale");
        require(!nftAuctions[_collectionAddress][_tokenId].isActive, "NFT is already in auction");
        require(!nftRentalListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for rent");
        require(!nftLoanListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for lending");

        // Approve marketplace to handle transfer
        nftContract.approve(address(this), _tokenId);

        nftAuctions[_collectionAddress][_tokenId] = NFTAuction({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            startingPrice: _startingPrice,
            endTime: block.timestamp + _durationSeconds,
            highestBidder: address(0),
            highestBid: 0,
            seller: _msgSender(),
            isActive: true
        });
        emit AuctionStarted(_collectionAddress, _tokenId, _startingPrice, block.timestamp + _durationSeconds, _msgSender());
    }

    function bidInAuction(address _collectionAddress, uint256 _tokenId) external payable onlyNotPaused onlyValidAuction(_collectionAddress, _tokenId) nonReentrantMarketplace {
        NFTAuction storage auction = nftAuctions[_collectionAddress][_tokenId];
        require(block.timestamp < auction.endTime, "Auction has already ended");
        require(msg.value > auction.highestBid, "Bid must be higher than current highest bid");
        require(msg.value >= auction.startingPrice, "Bid must be at least the starting price");

        if (auction.highestBidder != address(0)) {
            // Return previous highest bid
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;
        emit BidPlaced(_collectionAddress, _tokenId, _msgSender(), msg.value);
    }

    function endAuction(address _collectionAddress, uint256 _tokenId) external onlyNotPaused onlyValidAuction(_collectionAddress, _tokenId) nonReentrantMarketplace {
        NFTAuction storage auction = nftAuctions[_collectionAddress][_tokenId];
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.isActive = false; // Deactivate auction

        IERC721 nftContract = IERC721(auction.collectionAddress);

        if (auction.highestBidder != address(0)) {
            // Transfer NFT to highest bidder
            nftContract.safeTransferFrom(auction.seller, auction.highestBidder, auction.tokenId);

            // Calculate and pay seller and royalty
            uint256 sellerCut = auction.highestBid * (10000 - marketplaceFeePercentage) / 10000;
            uint256 marketplaceFee = auction.highestBid - sellerCut;
            uint256 royaltyFee = 0;
            if (nftCollections[auction.collectionAddress].royaltyFeePercentage > 0) {
                royaltyFee = auction.highestBid * nftCollections[auction.collectionAddress].royaltyFeePercentage / 10000;
                sellerCut -= royaltyFee;
                // Placeholder for royalty payment logic.
            }
            payable(auction.seller).transfer(sellerCut);
            payable(owner()).transfer(marketplaceFee);

            emit AuctionEnded(_collectionAddress, _tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids, return NFT to seller
            nftContract.transferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(_collectionAddress, _tokenId, address(0), 0); // Indicate no winner
        }
    }

    function cancelAuction(address _collectionAddress, uint256 _tokenId) external onlyNotPaused onlyValidAuction(_collectionAddress, _tokenId) nonReentrantMarketplace {
        NFTAuction storage auction = nftAuctions[_collectionAddress][_tokenId];
        require(auction.seller == _msgSender(), "Only seller can cancel auction");
        require(block.timestamp < auction.endTime, "Auction has already ended");

        auction.isActive = false; // Deactivate auction

        IERC721 nftContract = IERC721(auction.collectionAddress);
        nftContract.transferFrom(address(this), auction.seller, auction.tokenId); // Return NFT to seller

        if (auction.highestBidder != address(0)) {
            // Return highest bid
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        emit AuctionCancelled(_collectionAddress, _tokenId, _msgSender());
    }

    // --- NFT Renting Functions ---

    function rentNFT(address _collectionAddress, uint256 _tokenId, uint256 _rentPerDay, uint256 _rentalDays) external onlyNotPaused onlyNFTCollection nonReentrantMarketplace {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_rentPerDay > 0, "Rent per day must be greater than 0");
        require(_rentalDays > 0, "Rental days must be greater than 0");
        require(!nftSaleListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for sale");
        require(!nftAuctions[_collectionAddress][_tokenId].isActive, "NFT is already in auction");
        require(!nftRentalListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for rent");
        require(!nftLoans[_collectionAddress][_tokenId].isActive, "NFT is currently being lent");
        require(!nftRentals[_collectionAddress][_tokenId].isActive, "NFT is already being rented");


        nftRentalListings[_collectionAddress][_tokenId] = NFTRentalListing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            rentPerDay: _rentPerDay,
            owner: _msgSender(),
            isActive: true
        });
        emit NFTListedForRent(_collectionAddress, _tokenId, _rentPerDay, _msgSender());
    }

    function borrowNFT(address _collectionAddress, uint256 _tokenId, uint256 _rentalDays) external payable onlyNotPaused nonReentrantMarketplace {
        require(nftRentalListings[_collectionAddress][_tokenId].isActive, "NFT is not listed for rent");
        NFTRentalListing storage rentalListing = nftRentalListings[_collectionAddress][_tokenId];
        require(_rentalDays > 0, "Rental days must be greater than 0");

        uint256 totalRent = rentalListing.rentPerDay * _rentalDays;
        require(msg.value >= totalRent, "Insufficient funds for rental");

        IERC721 nftContract = IERC721(rentalListing.collectionAddress);
        nftContract.safeTransferFrom(rentalListing.owner, _msgSender(), rentalListing.tokenId); // Transfer NFT to renter

        nftRentals[_collectionAddress][_tokenId] = NFTRental({
            collectionAddress: rentalListing.collectionAddress,
            tokenId: rentalListing.tokenId,
            renter: _msgSender(),
            rentalDays: _rentalDays,
            endTime: block.timestamp + (_rentalDays * 1 days),
            isActive: true
        });
        rentalListing.isActive = false; // Deactivate listing

        payable(rentalListing.owner).transfer(totalRent); // Pay rent to NFT owner
        emit NFTRented(_collectionAddress, _tokenId, _msgSender(), _rentalDays);
    }

    function returnRentedNFT(address _collectionAddress, uint256 _tokenId) external onlyNotPaused nonReentrantMarketplace {
        require(nftRentals[_collectionAddress][_tokenId].isActive, "NFT is not currently rented");
        NFTRental storage rental = nftRentals[_collectionAddress][_tokenId];
        require(rental.renter == _msgSender(), "Only renter can return NFT");

        IERC721 nftContract = IERC721(rental.collectionAddress);
        nftContract.safeTransferFrom(_msgSender(), rentalListing(_collectionAddress, _tokenId).owner, rental.tokenId); // Return NFT to owner

        rental.isActive = false; // Deactivate rental
        emit NFTRentalReturned(_collectionAddress, _tokenId, _msgSender());
    }

    // --- NFT Lending Functions ---

    function lendNFT(address _collectionAddress, uint256 _tokenId, uint256 _collateralAmount, uint256 _loanDurationDays, uint256 _interestRatePercent) external onlyNotPaused onlyNFTCollection nonReentrantMarketplace {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(_collateralAmount > 0, "Collateral amount must be greater than 0");
        require(_loanDurationDays > 0, "Loan duration must be greater than 0");
        require(_interestRatePercent <= 1000, "Interest rate percentage too high (max 10%)"); // Max 10% interest (1000 basis points)
        require(!nftSaleListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for sale");
        require(!nftAuctions[_collectionAddress][_tokenId].isActive, "NFT is already in auction");
        require(!nftRentalListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for rent");
        require(!nftLoanListings[_collectionAddress][_tokenId].isActive, "NFT is already listed for lending");
        require(!nftLoans[_collectionAddress][_tokenId].isActive, "NFT is currently being lent");


        nftLoanListings[_collectionAddress][_tokenId] = NFTLoanListing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            collateralAmount: _collateralAmount,
            loanDurationDays: _loanDurationDays,
            interestRatePercent: _interestRatePercent,
            lender: _msgSender(),
            isActive: true
        });
        emit NFTListedForLending(_collectionAddress, _tokenId, _collateralAmount, _loanDurationDays, _interestRatePercent, _msgSender());
    }

    function borrowLentNFT(address _collectionAddress, uint256 _tokenId) external payable onlyNotPaused nonReentrantMarketplace {
        require(nftLoanListings[_collectionAddress][_tokenId].isActive, "NFT is not listed for lending");
        NFTLoanListing storage loanListing = nftLoanListings[_collectionAddress][_tokenId];
        require(msg.value >= loanListing.collateralAmount, "Insufficient collateral provided");

        IERC721 nftContract = IERC721(loanListing.collectionAddress);
        nftContract.safeTransferFrom(loanListing.lender, _msgSender(), loanListing.tokenId); // Transfer NFT to borrower

        nftLoans[_collectionAddress][_tokenId] = NFTLoan({
            collectionAddress: loanListing.collectionAddress,
            tokenId: loanListing.tokenId,
            borrower: _msgSender(),
            collateralAmount: loanListing.collateralAmount,
            loanDurationDays: loanListing.loanDurationDays,
            interestRatePercent: loanListing.interestRatePercent,
            endTime: block.timestamp + (loanListing.loanDurationDays * 1 days),
            isActive: true
        });
        nftLoanListings[_collectionAddress][_tokenId].isActive = false; // Deactivate listing

        payable(loanListing.lender).transfer(loanListing.collateralAmount); // Transfer collateral to lender
        emit NFTLent(_collectionAddress, _tokenId, _msgSender(), loanListing.collateralAmount, loanListing.loanDurationDays, loanListing.interestRatePercent);
    }

    function repayLoanAndRetrieveNFT(address _collectionAddress, uint256 _tokenId) external payable onlyNotPaused nonReentrantMarketplace {
        require(nftLoans[_collectionAddress][_tokenId].isActive, "NFT loan is not active");
        NFTLoan storage loan = nftLoans[_collectionAddress][_tokenId];
        require(loan.borrower == _msgSender(), "Only borrower can repay loan");
        require(block.timestamp < loan.endTime, "Loan has already expired");

        uint256 interestAmount = (loan.collateralAmount * loan.interestRatePercent * loan.loanDurationDays) / (10000 * 365); // Simple interest calculation
        uint256 totalRepayment = loan.collateralAmount + interestAmount;
        require(msg.value >= totalRepayment, "Insufficient funds for loan repayment");

        IERC721 nftContract = IERC721(loan.collectionAddress);
        nftContract.safeTransferFrom(_msgSender(), listingLoan(_collectionAddress, _tokenId).lender, loan.tokenId); // Return NFT to lender

        payable(listingLoan(_collectionAddress, _tokenId).lender).transfer(totalRepayment); // Pay collateral + interest to lender

        loan.isActive = false; // Deactivate loan
        emit NFTLoanRepaid(_collectionAddress, _tokenId, _msgSender());
    }

    function liquidateLoanedNFT(address _collectionAddress, uint256 _tokenId) external onlyNotPaused nonReentrantMarketplace {
        require(nftLoans[_collectionAddress][_tokenId].isActive, "NFT loan is not active");
        NFTLoan storage loan = nftLoans[_collectionAddress][_tokenId];
        require(block.timestamp >= loan.endTime, "Loan has not expired yet");

        loan.isActive = false; // Deactivate loan

        IERC721 nftContract = IERC721(loan.collectionAddress);
        nftContract.safeTransferFrom(_msgSender(), _msgSender(), loan.tokenId); // Transfer NFT to liquidator (in this simplified example, anyone can liquidate)

        payable(loan.borrower).transfer(loan.collateralAmount); // Return collateral to borrower (liquidator gets NFT in place of repayment)
        emit NFTLoanLiquidated(_collectionAddress, _tokenId, loan.borrower, _msgSender());
    }

    // --- Staking Functions --- (Conceptual)

    function stakeNFT(address _collectionAddress, uint256 _tokenId) external onlyNotPaused onlyNFTCollection nonReentrantMarketplace {
        // Implement staking logic here - could involve transferring NFT to contract, updating staking state, etc.
        // For this example, we'll just emit an event.
        emit NFTStaked(_collectionAddress, _tokenId, _msgSender());
    }

    function unstakeNFT(address _collectionAddress, uint256 _tokenId) external onlyNotPaused nonReentrantMarketplace {
        // Implement unstaking logic here - could involve transferring NFT back to staker, updating staking state, etc.
        // For this example, we'll just emit an event.
        emit NFTUnstaked(_collectionAddress, _tokenId, _msgSender());
    }

    // --- Reputation System Functions --- (Conceptual)

    function updateUserReputation(address _user, int256 _reputationChange) external onlyOperator {
        userReputation[_user] += _reputationChange;
        emit UserReputationUpdated(_user, _reputationChange, userReputation[_user]);
    }

    function getUserReputation(address _user) external view returns (int256) {
        return userReputation[_user];
    }

    // --- Governance Functions --- (Simplified Example)

    function createGovernanceProposal(string memory _description, bytes memory _data) external onlyOperator {
        proposalCount++;
        governanceProposals[proposalCount] = GovernanceProposal({
            description: _description,
            data: _data,
            startTime: block.timestamp,
            endTime: block.timestamp + (7 days), // 7-day voting period
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalCount, _description, _msgSender());
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyNotPaused {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < governanceProposals[_proposalId].endTime, "Voting period has ended");
        // In a real governance system, voting power could be determined by NFT holdings, token balance, etc.
        // For this simplified example, each address has 1 vote.
        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    function executeGovernanceProposal(uint256 _proposalId) external onlyOperator {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(block.timestamp >= proposal.endTime, "Voting period has not ended yet");
        // Example: Simple majority wins (can be adjusted based on governance model)
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        proposal.executed = true;
        // **Implement proposal execution logic based on proposal.data. This is highly dependent on what governance is controlling.**
        // Example: if proposal.data encodes a parameter change, implement the logic to change that parameter here.
        emit GovernanceProposalExecuted(_proposalId);
    }

    // --- Admin and Utility Functions ---

    function setOperator(address _operatorAddress) external onlyOwner {
        require(_operatorAddress != address(0), "Invalid operator address");
        operator = _operatorAddress;
    }

    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(_msgSender());
    }

    // --- Interface Support ---

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
```