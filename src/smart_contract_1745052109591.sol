```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Fractionalization
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT marketplace with advanced features:
 *      - Dynamic NFTs: NFTs that can evolve and change based on various factors.
 *      - AI-Simulated Art Generation: On-chain generation of art metadata based on user input (simulated AI).
 *      - Fractionalization: Allows NFT owners to fractionalize their NFTs into ERC20 tokens for wider accessibility and trading.
 *      - Decentralized Governance: Basic governance for setting marketplace parameters.
 *      - Staking & Yield Farming: Incentivizes holding fractionalized tokens.
 *      - Advanced Listing and Trading Mechanisms: Offers both direct listing and auction functionalities.
 *      - Dynamic Royalties: Royalties can be adjusted through governance.
 *
 * Function Outline & Summary:
 *
 * **NFT Creation & Management:**
 * 1. `mintDynamicNFT(string _initialMetadataURI, string _generationPrompt)`: Mints a new dynamic NFT with initial metadata and a generation prompt.
 * 2. `evolveNFT(uint256 _tokenId, string _evolutionPrompt)`: Evolves an existing dynamic NFT based on a new prompt, updating its metadata.
 * 3. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * 4. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI of an NFT.
 * 5. `getNFTGenerationPrompt(uint256 _tokenId)`: Retrieves the generation prompt associated with an NFT.
 * 6. `setBaseMetadataURI(string _baseURI)`: Allows the contract owner to set a base URI for metadata (for easier management).
 *
 * **Marketplace Functionality:**
 * 7. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for direct sale at a fixed price.
 * 8. `unlistNFTFromSale(uint256 _tokenId)`: Removes an NFT listing from direct sale.
 * 9. `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 * 10. `createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration)`: Creates a Dutch auction for an NFT.
 * 11. `bidOnAuction(uint256 _auctionId, uint256 _bidAmount)`: Allows bidding on an active auction.
 * 12. `settleAuction(uint256 _auctionId)`: Settles a completed auction and transfers the NFT to the highest bidder.
 * 13. `setMarketplaceFee(uint256 _feePercentage)`: Allows governance to set the marketplace fee percentage.
 * 14. `getMarketplaceFee()`: Retrieves the current marketplace fee percentage.
 *
 * **Fractionalization & Staking:**
 * 15. `fractionalizeNFT(uint256 _tokenId, string _fractionName, string _fractionSymbol, uint256 _fractionSupply)`: Fractionalizes an NFT into ERC20 tokens.
 * 16. `redeemFraction(uint256 _tokenId, uint256 _fractionAmount)`: Allows fraction holders to redeem a portion of the underlying NFT (requires governance approval and logic for handling joint ownership/redemption).
 * 17. `stakeFraction(uint256 _tokenId, uint256 _fractionAmount)`: Stakes fractionalized tokens to earn yield.
 * 18. `unstakeFraction(uint256 _tokenId, uint256 _fractionAmount)`: Unstakes fractionalized tokens.
 * 19. `claimYield(uint256 _tokenId)`: Claims accumulated yield from staking fractionalized tokens.
 * 20. `getFractionSupply(uint256 _tokenId)`: Retrieves the total supply of fractionalized tokens for an NFT.
 * 21. `getFractionContractAddress(uint256 _tokenId)`: Retrieves the address of the ERC20 contract for fractionalized NFT tokens.
 *
 * **Governance & Royalties:**
 * 22. `setRoyaltyFee(uint256 _royaltyPercentage)`: Allows governance to set the royalty fee percentage for secondary sales.
 * 23. `getRoyaltyFee()`: Retrieves the current royalty fee percentage.
 * 24. `proposeMarketplaceFeeChange(uint256 _newFee)`: Allows governance to propose a change to the marketplace fee.
 * 25. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows governance members to vote on proposals.
 * 26. `executeProposal(uint256 _proposalId)`: Executes a successful governance proposal.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public baseMetadataURI;
    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee by default
    uint256 public royaltyFeePercentage = 5;     // 5% royalty fee by default

    // Struct to represent dynamic NFT data
    struct DynamicNFT {
        string metadataURI;
        string generationPrompt;
        bool isFractionalized;
        address fractionContractAddress;
    }

    // Mapping from tokenId to DynamicNFT struct
    mapping(uint256 => DynamicNFT) public dynamicNFTs;

    // Marketplace listings
    struct Listing {
        bool isListed;
        uint256 price;
        address seller;
    }
    mapping(uint256 => Listing) public nftListings;

    // Dutch Auction struct
    struct Auction {
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 startingPrice;
        uint256 currentPrice;
        address highestBidder;
        uint256 highestBid;
        uint256 tokenId;
    }
    Counters.Counter private _auctionIdCounter;
    mapping(uint256 => Auction) public auctions;

    // Fractionalization details
    mapping(uint256 => address) public fractionContracts; // TokenId => Fraction Token Contract Address
    mapping(uint256 => uint256) public fractionSupplies; // TokenId => Total Fraction Supply

    // Simple Governance (expandable)
    struct Proposal {
        bool isActive;
        uint256 proposalId;
        uint256 creationTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalType proposalType;
        uint256 proposedValue; // Generic value, type depends on proposalType
        bool executed;
    }

    enum ProposalType {
        MARKETPLACE_FEE_CHANGE,
        ROYALTY_FEE_CHANGE
    }

    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    address[] public governanceMembers; // Placeholder for governance members, can be expanded to DAO

    // Staking (Simplified - basic example)
    mapping(uint256 => mapping(address => uint256)) public fractionStakes; // tokenId => (user => stakedAmount)
    mapping(uint256 => mapping(address => uint256)) public pendingYield;    // tokenId => (user => pendingYield)
    uint256 public stakingYieldPercentage = 1; // Example: 1% annual yield, adjust as needed
    uint256 public stakingInterval = 30 days; // Yield distribution interval


    event NFTMinted(uint256 tokenId, address minter, string metadataURI, string generationPrompt);
    event NFTEvolved(uint256 tokenId, string newMetadataURI, string evolutionPrompt);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTUnlisted(uint256 tokenId, address seller);
    event NFTSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, uint256 startingPrice, uint256 duration, address seller);
    event BidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event AuctionSettled(uint256 auctionId, uint256 tokenId, address winner, uint256 finalPrice);
    event NFTFractionalized(uint256 tokenId, address fractionContractAddress, uint256 fractionSupply);
    event FractionRedeemed(uint256 tokenId, address redeemer, uint256 fractionAmount);
    event FractionStaked(uint256 tokenId, address staker, uint256 fractionAmount);
    event FractionUnstaked(uint256 tokenId, address unstaker, uint256 fractionAmount);
    event YieldClaimed(uint256 tokenId, address claimant, uint256 yieldAmount);
    event MarketplaceFeeChanged(uint256 newFeePercentage, address governor);
    event RoyaltyFeeChanged(uint256 newRoyaltyPercentage, address governor);
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, uint256 proposedValue, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType, uint256 executedValue, address executor);


    constructor() ERC721("DynamicNFT", "DNFT") {
        baseMetadataURI = "ipfs://defaultBaseURI/"; // Set a default base URI
        governanceMembers.push(owner()); // Initialize governance with contract owner
    }

    modifier onlyGovernance() {
        bool isGovernor = false;
        for (uint256 i = 0; i < governanceMembers.length; i++) {
            if (governanceMembers[i] == _msgSender()) {
                isGovernor = true;
                break;
            }
        }
        require(isGovernor, "Only governance members can perform this action");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not NFT owner or approved");
        _;
    }

    modifier onlyListedNFT(uint256 _tokenId) {
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        _;
    }

    modifier validAuction(uint256 _auctionId) {
        require(auctions[_auctionId].isActive, "Auction is not active");
        _;
    }

    modifier auctionNotEnded(uint256 _auctionId) {
        require(block.timestamp < auctions[_auctionId].endTime, "Auction has ended");
        _;
    }

    modifier auctionEnded(uint256 _auctionId) {
        require(block.timestamp >= auctions[_auctionId].endTime, "Auction has not ended yet");
        _;
    }

    modifier notFractionalized(uint256 _tokenId) {
        require(!dynamicNFTs[_tokenId].isFractionalized, "NFT is already fractionalized");
        _;
    }

    modifier isFractionalized(uint256 _tokenId) {
        require(dynamicNFTs[_tokenId].isFractionalized, "NFT is not fractionalized");
        _;
    }

    modifier hasEnoughFractions(uint256 _tokenId, uint256 _fractionAmount) {
        require(ERC20(dynamicNFTs[_tokenId].fractionContractAddress).balanceOf(_msgSender()) >= _fractionAmount, "Not enough fractions");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal is not active or does not exist");
        _;
    }

    modifier proposalNotExecuted(uint256 _proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier proposalPassed(uint256 _proposalId) {
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal did not pass"); // Simple majority
        _;
    }


    /**
     * @dev Mints a new dynamic NFT with initial metadata and a generation prompt.
     * @param _initialMetadataURI URI for the initial metadata of the NFT.
     * @param _generationPrompt Prompt used to initially generate the art (simulated AI).
     */
    function mintDynamicNFT(string memory _initialMetadataURI, string memory _generationPrompt) public nonReentrant returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);

        dynamicNFTs[tokenId] = DynamicNFT({
            metadataURI: _initialMetadataURI,
            generationPrompt: _generationPrompt,
            isFractionalized: false,
            fractionContractAddress: address(0)
        });

        emit NFTMinted(tokenId, _msgSender(), _initialMetadataURI, _generationPrompt);
        return tokenId;
    }

    /**
     * @dev Evolves an existing dynamic NFT based on a new prompt, updating its metadata.
     * @param _tokenId ID of the NFT to evolve.
     * @param _evolutionPrompt New prompt to guide the evolution of the NFT (simulated AI).
     */
    function evolveNFT(uint256 _tokenId, string memory _evolutionPrompt) public onlyNFTOwner(_tokenId) nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");

        // Simulate AI-driven metadata generation based on prompt.
        // In a real application, this would interface with an off-chain AI service or oracle.
        string memory newMetadataURI = _generateAIArtMetadata(_tokenId, _evolutionPrompt);

        dynamicNFTs[_tokenId].metadataURI = newMetadataURI;
        dynamicNFTs[_tokenId].generationPrompt = _evolutionPrompt; // Update generation prompt

        emit NFTEvolved(_tokenId, newMetadataURI, _evolutionPrompt);
    }

    /**
     * @dev Internal function to simulate AI-driven metadata generation.
     * @param _tokenId ID of the NFT.
     * @param _prompt Prompt to generate metadata from.
     * @return string The generated metadata URI.
     */
    function _generateAIArtMetadata(uint256 _tokenId, string memory _prompt) internal view returns (string memory) {
        // This is a placeholder for actual AI-driven metadata generation.
        // In a real-world scenario, this would be much more complex, potentially involving:
        // 1. Off-chain AI model processing the prompt.
        // 2. Storing the generated art (e.g., on IPFS).
        // 3. Constructing metadata JSON referencing the art and other attributes.
        // 4. Returning the IPFS URI of the metadata JSON.

        // For this example, we'll just create a deterministic metadata URI based on the token ID and prompt hash.
        bytes32 promptHash = keccak256(bytes(_prompt));
        return string(abi.encodePacked(baseMetadataURI, "evolved/", _tokenId.toString(), "/", Strings.toHexString(uint256(promptHash))));
    }


    /**
     * @dev Transfers ownership of an NFT.
     * @param _to Address to transfer the NFT to.
     * @param _tokenId ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public onlyNFTOwner(_tokenId) nonReentrant {
        transferFrom(_msgSender(), _to, _tokenId);
    }

    /**
     * @dev Retrieves the current metadata URI of an NFT.
     * @param _tokenId ID of the NFT.
     * @return string The metadata URI.
     */
    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return dynamicNFTs[_tokenId].metadataURI;
    }

    /**
     * @dev Retrieves the generation prompt associated with an NFT.
     * @param _tokenId ID of the NFT.
     * @return string The generation prompt.
     */
    function getNFTGenerationPrompt(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return dynamicNFTs[_tokenId].generationPrompt;
    }

    /**
     * @dev Allows the contract owner to set a base URI for metadata (for easier management).
     * @param _baseURI The new base metadata URI.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner {
        baseMetadataURI = _baseURI;
    }

    /**
     * @dev Lists an NFT for direct sale at a fixed price.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");
        approve(address(this), _tokenId); // Approve marketplace to transfer the NFT
        nftListings[_tokenId] = Listing({
            isListed: true,
            price: _price,
            seller: _msgSender()
        });
        emit NFTListed(_tokenId, _price, _msgSender());
    }

    /**
     * @dev Removes an NFT listing from direct sale.
     * @param _tokenId ID of the NFT to unlist.
     */
    function unlistNFTFromSale(uint256 _tokenId) public onlyNFTOwner(_tokenId) nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        delete nftListings[_tokenId]; // Reset listing struct to default values (isListed becomes false)
        emit NFTUnlisted(_tokenId, _msgSender());
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable nonReentrant onlyListedNFT(_tokenId) {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = (listing.price * royaltyFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee - royaltyFee;

        // Transfer marketplace fee
        payable(owner()).transfer(marketplaceFee);

        // Transfer royalty fee to original creator (assuming creator is the minter for simplicity)
        payable(owner()).transfer(royaltyFee); // In real application, track creators separately

        // Transfer proceeds to seller
        payable(listing.seller).transfer(sellerProceeds);

        // Transfer NFT to buyer
        transferFrom(listing.seller, _msgSender(), _tokenId);

        // Remove listing after sale
        delete nftListings[_tokenId];

        emit NFTSold(_tokenId, _msgSender(), listing.seller, listing.price);
    }

    /**
     * @dev Creates a Dutch auction for an NFT. Price decreases over time.
     * @param _tokenId ID of the NFT to auction.
     * @param _startingPrice Starting price of the auction in wei.
     * @param _duration Auction duration in seconds.
     */
    function createAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public onlyNFTOwner(_tokenId) nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(!auctions[_auctionIdCounter.current()].isActive, "Another auction is already active for this NFT"); // Basic check

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();
        approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        auctions[auctionId] = Auction({
            isActive: true,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            startingPrice: _startingPrice,
            currentPrice: _startingPrice,
            highestBidder: address(0),
            highestBid: 0,
            tokenId: _tokenId
        });

        emit AuctionCreated(auctionId, _tokenId, _startingPrice, _duration, _msgSender());
    }

    /**
     * @dev Allows bidding on an active auction.
     * @param _auctionId ID of the auction.
     * @param _bidAmount Bid amount in wei.
     */
    function bidOnAuction(uint256 _auctionId, uint256 _bidAmount) public payable nonReentrant validAuction(_auctionId) auctionNotEnded(_auctionId) {
        Auction storage auction = auctions[_auctionId];

        // Calculate current Dutch auction price (simple linear decrease for example)
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 priceDecrease = (auction.startingPrice * timeElapsed) / (auction.endTime - auction.startTime);
        auction.currentPrice = auction.startingPrice - priceDecrease;
        if (auction.currentPrice < 0) { // Price can't go below 0
            auction.currentPrice = 0;
        }

        require(_bidAmount >= auction.currentPrice, "Bid amount is too low");
        require(_bidAmount > auction.highestBid, "Bid amount must be higher than current highest bid");

        // Refund previous bidder if any
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = _bidAmount;

        emit BidPlaced(_auctionId, _msgSender(), _bidAmount);
    }

    /**
     * @dev Settles a completed auction and transfers the NFT to the highest bidder.
     * @param _auctionId ID of the auction to settle.
     */
    function settleAuction(uint256 _auctionId) public nonReentrant validAuction(_auctionId) auctionEnded(_auctionId) {
        Auction storage auction = auctions[_auctionId];
        require(auction.highestBidder != address(0), "No bids placed on this auction");

        uint256 marketplaceFee = (auction.highestBid * marketplaceFeePercentage) / 100;
        uint256 royaltyFee = (auction.highestBid * royaltyFeePercentage) / 100;
        uint256 sellerProceeds = auction.highestBid - marketplaceFee - royaltyFee;

        // Transfer marketplace fee
        payable(owner()).transfer(marketplaceFee);

        // Transfer royalty fee
        payable(owner()).transfer(royaltyFee); // In real application, track creators separately

        // Transfer proceeds to seller (auction creator)
        payable(nftListings[auction.tokenId].seller).transfer(sellerProceeds); // Seller is stored in nftListings when auction is created

        // Transfer NFT to highest bidder
        transferFrom(nftListings[auction.tokenId].seller, auction.highestBidder, auction.tokenId);

        // Deactivate auction
        auctions[_auctionId].isActive = false;

        emit AuctionSettled(_auctionId, auction.tokenId, auction.highestBidder, auction.highestBid);
    }

    /**
     * @dev Allows governance to set the marketplace fee percentage.
     * @param _feePercentage New marketplace fee percentage.
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyGovernance {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeChanged(_feePercentage, _msgSender());
    }

    /**
     * @dev Retrieves the current marketplace fee percentage.
     * @return uint256 The marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /**
     * @dev Fractionalizes an NFT into ERC20 tokens.
     * @param _tokenId ID of the NFT to fractionalize.
     * @param _fractionName Name of the fractionalized token.
     * @param _fractionSymbol Symbol of the fractionalized token.
     * @param _fractionSupply Total supply of fractionalized tokens.
     */
    function fractionalizeNFT(uint256 _tokenId, string memory _fractionName, string memory _fractionSymbol, uint256 _fractionSupply) public onlyNFTOwner(_tokenId) notFractionalized(_tokenId) nonReentrant {
        require(_exists(_tokenId), "NFT does not exist");
        require(_fractionSupply > 0, "Fraction supply must be greater than zero");

        // Deploy a new ERC20 contract for the fractionalized tokens
        FractionToken fractionToken = new FractionToken(_fractionName, _fractionSymbol, _fractionSupply, address(this), _tokenId);
        fractionContracts[_tokenId] = address(fractionToken);
        fractionSupplies[_tokenId] = _fractionSupply;
        dynamicNFTs[_tokenId].isFractionalized = true;
        dynamicNFTs[_tokenId].fractionContractAddress = address(fractionToken);

        // Transfer NFT ownership to the fraction token contract (or a dedicated vault contract for more complex logic)
        transferFrom(_msgSender(), address(fractionToken), _tokenId);

        emit NFTFractionalized(_tokenId, address(fractionToken), _fractionSupply);
    }

    /**
     * @dev Allows fraction holders to redeem a portion of the underlying NFT.
     * @param _tokenId ID of the fractionalized NFT.
     * @param _fractionAmount Amount of fractions to redeem.
     */
    function redeemFraction(uint256 _tokenId, uint256 _fractionAmount) public isFractionalized(_tokenId) hasEnoughFractions(_tokenId, _fractionAmount) nonReentrant {
        // Note: Redemption logic can be complex and require governance approval,
        // especially for handling joint ownership and the physical NFT if applicable.
        // This is a simplified example.

        // Basic checks and transfer of fractions (burning) would happen here.
        // More advanced logic might involve:
        // 1. Governance voting on redemption requests.
        // 2. Logic for handling joint ownership if multiple users redeem fractions simultaneously.
        // 3. Potential for physical redemption of the NFT in real-world scenarios.

        ERC20 fractionToken = ERC20(dynamicNFTs[_tokenId].fractionContractAddress);
        fractionToken.transferFrom(_msgSender(), address(0), _fractionAmount); // Burn fractions

        // In a real application, more sophisticated logic for NFT redemption would be needed here.
        // For this example, we're just burning fractions as a placeholder for redemption.

        emit FractionRedeemed(_tokenId, _msgSender(), _fractionAmount);
    }

    /**
     * @dev Stakes fractionalized tokens to earn yield.
     * @param _tokenId ID of the fractionalized NFT.
     * @param _fractionAmount Amount of fractions to stake.
     */
    function stakeFraction(uint256 _tokenId, uint256 _fractionAmount) public isFractionalized(_tokenId) hasEnoughFractions(_tokenId, _fractionAmount) nonReentrant {
        ERC20 fractionToken = ERC20(dynamicNFTs[_tokenId].fractionContractAddress);
        fractionToken.transferFrom(_msgSender(), address(this), _fractionAmount); // Transfer fractions to staking contract
        fractionStakes[_tokenId][_msgSender()] += _fractionAmount;
        emit FractionStaked(_tokenId, _msgSender(), _fractionAmount);
    }

    /**
     * @dev Unstakes fractionalized tokens.
     * @param _tokenId ID of the fractionalized NFT.
     * @param _fractionAmount Amount of fractions to unstake.
     */
    function unstakeFraction(uint256 _tokenId, uint256 _fractionAmount) public isFractionalized(_tokenId) nonReentrant {
        require(fractionStakes[_tokenId][_msgSender()] >= _fractionAmount, "Not enough staked fractions");
        fractionStakes[_tokenId][_msgSender()] -= _fractionAmount;
        ERC20 fractionToken = ERC20(dynamicNFTs[_tokenId].fractionContractAddress);
        fractionToken.transfer(_msgSender(), _fractionAmount); // Transfer fractions back to user
        emit FractionUnstaked(_tokenId, _msgSender(), _fractionAmount);
    }

    /**
     * @dev Claims accumulated yield from staking fractionalized tokens.
     * @param _tokenId ID of the fractionalized NFT.
     */
    function claimYield(uint256 _tokenId) public isFractionalized(_tokenId) nonReentrant {
        uint256 yieldAmount = calculateYield(_tokenId, _msgSender());
        require(yieldAmount > 0, "No yield to claim");
        pendingYield[_tokenId][_msgSender()] = 0; // Reset pending yield
        payable(_msgSender()).transfer(yieldAmount); // Transfer yield in ETH (example, could be other tokens)
        emit YieldClaimed(_tokenId, _msgSender(), yieldAmount);
    }

    /**
     * @dev Internal function to calculate staking yield. (Simplified example)
     * @param _tokenId ID of the fractionalized NFT.
     * @param _user Address of the user claiming yield.
     * @return uint256 The amount of yield to claim.
     */
    function calculateYield(uint256 _tokenId, address _user) internal view returns (uint256) {
        uint256 stakedAmount = fractionStakes[_tokenId][_user];
        if (stakedAmount == 0) {
            return 0;
        }

        uint256 lastClaimTime = pendingYield[_tokenId][_user]; // Using pendingYield to store last claim time for simplicity
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastClaim = currentTime - lastClaimTime;

        if (timeSinceLastClaim < stakingInterval) {
            return 0; // Not enough time elapsed since last claim
        }

        uint256 yieldPerInterval = (stakedAmount * stakingYieldPercentage) / 100; // Example calculation
        uint256 intervalsElapsed = timeSinceLastClaim / stakingInterval;
        uint256 totalYield = yieldPerInterval * intervalsElapsed;

        return totalYield; // Yield calculated in wei of ETH for simplicity
    }


    /**
     * @dev Retrieves the total supply of fractionalized tokens for an NFT.
     * @param _tokenId ID of the NFT.
     * @return uint256 The total fraction supply.
     */
    function getFractionSupply(uint256 _tokenId) public view isFractionalized(_tokenId) returns (uint256) {
        return fractionSupplies[_tokenId];
    }

    /**
     * @dev Retrieves the address of the ERC20 contract for fractionalized NFT tokens.
     * @param _tokenId ID of the NFT.
     * @return address The fraction token contract address.
     */
    function getFractionContractAddress(uint256 _tokenId) public view isFractionalized(_tokenId) returns (address) {
        return dynamicNFTs[_tokenId].fractionContractAddress;
    }

    /**
     * @dev Allows governance to set the royalty fee percentage for secondary sales.
     * @param _royaltyPercentage New royalty fee percentage.
     */
    function setRoyaltyFee(uint256 _royaltyPercentage) public onlyGovernance {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyFeePercentage = _royaltyPercentage;
        emit RoyaltyFeeChanged(_royaltyPercentage, _msgSender());
    }

    /**
     * @dev Retrieves the current royalty fee percentage.
     * @return uint256 The royalty fee percentage.
     */
    function getRoyaltyFee() public view returns (uint256) {
        return royaltyFeePercentage;
    }

    /**
     * @dev Proposes a change to the marketplace fee.
     * @param _newFee The new marketplace fee percentage.
     */
    function proposeMarketplaceFeeChange(uint256 _newFee) public onlyGovernance {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            isActive: true,
            proposalId: proposalId,
            creationTime: block.timestamp,
            endTime: block.timestamp + 7 days, // Example: 7 days voting period
            votesFor: 0,
            votesAgainst: 0,
            proposalType: ProposalType.MARKETPLACE_FEE_CHANGE,
            proposedValue: _newFee,
            executed: false
        });

        emit ProposalCreated(proposalId, ProposalType.MARKETPLACE_FEE_CHANGE, _newFee, _msgSender());
    }

    /**
     * @dev Allows governance members to vote on proposals.
     * @param _proposalId ID of the proposal to vote on.
     * @param _vote True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyGovernance validProposal(_proposalId) proposalNotExecuted(_proposalId) {
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        Proposal storage proposal = proposals[_proposalId];

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes a successful governance proposal.
     * @param _proposalId ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyGovernance validProposal(_proposalId) proposalNotExecuted(_proposalId) proposalPassed(_proposalId) {
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period has not ended yet");
        Proposal storage proposal = proposals[_proposalId];

        proposal.executed = true;

        if (proposal.proposalType == ProposalType.MARKETPLACE_FEE_CHANGE) {
            setMarketplaceFee(proposal.proposedValue);
            emit ProposalExecuted(_proposalId, ProposalType.MARKETPLACE_FEE_CHANGE, proposal.proposedValue, _msgSender());
        } else if (proposal.proposalType == ProposalType.ROYALTY_FEE_CHANGE) {
            setRoyaltyFee(proposal.proposedValue);
            emit ProposalExecuted(_proposalId, ProposalType.ROYALTY_FEE_CHANGE, proposal.proposedValue, _msgSender());
        } else {
            revert("Unknown proposal type");
        }
    }

    // --- Helper Functions ---
    function isNFTListed(uint256 _tokenId) public view returns (bool) {
        return nftListings[_tokenId].isListed;
    }

    function getNFTListingPrice(uint256 _tokenId) public view returns (uint256) {
        return nftListings[_tokenId].price;
    }

    function isAuctionActive(uint256 _auctionId) public view returns (bool) {
        return auctions[_auctionId].isActive;
    }

    function getCurrentAuctionPrice(uint256 _auctionId) public view returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 priceDecrease = (auction.startingPrice * timeElapsed) / (auction.endTime - auction.startTime);
        uint256 currentPrice = auction.startingPrice - priceDecrease;
        return currentPrice > 0 ? currentPrice : 0;
    }

    function getAuctionHighestBid(uint256 _auctionId) public view returns (uint256) {
        return auctions[_auctionId].highestBid;
    }

    function getAuctionHighestBidder(uint256 _auctionId) public view returns (address) {
        return auctions[_auctionId].highestBidder;
    }


    // --- ERC20 Fraction Token Contract (Nested) ---
    contract FractionToken is ERC20, Ownable {
        address public marketplaceContract;
        uint256 public tokenId;

        constructor(string memory _name, string memory _symbol, uint256 _totalSupply, address _marketplaceContract, uint256 _tokenId) ERC20(_name, _symbol) {
            _mint(msg.sender, _totalSupply); // Initial minter is the NFT owner
            marketplaceContract = _marketplaceContract;
            tokenId = _tokenId;
            transferOwnership(_marketplaceContract); // Marketplace contract becomes owner for control
        }

        // Optional: Add any custom logic for the FractionToken if needed.
    }
}
```