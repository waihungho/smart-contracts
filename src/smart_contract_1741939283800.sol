```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Advanced Features
 * @author Gemini AI Assistant
 * @dev This contract implements a decentralized marketplace for Dynamic NFTs,
 * incorporating advanced features like NFT evolution, on-chain reputation,
 * community governance, staking, renting, and fractionalization, along with
 * robust marketplace functionalities and unique auction mechanisms.
 *
 * Function Summary:
 *
 * **NFT Management:**
 * 1. createNFT: Allows the contract owner to create a new Dynamic NFT.
 * 2. updateNFTMetadata: Allows the contract owner to update the metadata URI of an NFT.
 * 3. evolveNFT: Allows NFT owners to evolve their NFTs based on certain conditions.
 * 4. setNFTBaseURI: Allows the contract owner to set the base URI for NFT metadata.
 *
 * **Marketplace Core Operations:**
 * 5. listItem: Allows NFT owners to list their NFTs for sale on the marketplace.
 * 6. buyItem: Allows users to purchase listed NFTs.
 * 7. cancelListing: Allows NFT owners to cancel their NFT listing.
 * 8. updateListingPrice: Allows NFT owners to update the price of their listed NFT.
 * 9. offerItem: Allows users to make a direct offer on an NFT that is not listed.
 * 10. acceptOffer: Allows NFT owners to accept a direct offer on their NFT.
 * 11. startAuction: Allows NFT owners to start a timed auction for their NFT.
 * 12. bidOnAuction: Allows users to bid on active auctions.
 * 13. endAuction: Allows the auctioneer or anyone to end an auction after the time limit.
 *
 * **Advanced Features:**
 * 14. stakeMarketplaceToken: Allows users to stake marketplace tokens for benefits (e.g., reduced fees).
 * 15. unstakeMarketplaceToken: Allows users to unstake their marketplace tokens.
 * 16. rentNFT: Allows NFT owners to rent out their NFTs for a specific duration and fee.
 * 17. returnNFT: Allows renters to return rented NFTs, or automatically triggered after rental duration.
 * 18. fractionalizeNFT: Allows NFT owners to fractionalize their NFTs, creating ERC20 tokens representing fractions.
 * 19. redeemFraction: Allows fraction token holders to redeem fractions to collectively own the original NFT (governance needed for transfer).
 * 20. voteOnProposal: Allows staked token holders to vote on marketplace proposals (e.g., feature updates, fee changes).
 *
 * **Utility & Admin Functions:**
 * 21. setMarketplaceFee: Allows the contract owner to set the marketplace fee.
 * 22. withdrawFees: Allows the contract owner to withdraw accumulated marketplace fees.
 * 23. pauseContract: Allows the contract owner to pause core marketplace functions in emergencies.
 * 24. unpauseContract: Allows the contract owner to unpause the contract.
 * 25. emergencyWithdrawTokens: Allows the contract owner to withdraw any ERC20 tokens mistakenly sent to the contract.
 * 26. emergencyWithdrawETH: Allows the contract owner to withdraw any accidentally sent ETH to the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract DynamicNFTMarketplace is ERC721, Ownable, Pausable, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Marketplace Token (Example - Replace with your actual token if needed)
    ERC20 public marketplaceToken;

    // State Variables
    string public baseURI;
    uint256 public marketplaceFeePercentage = 2; // 2% fee
    address public feeRecipient;
    bool public contractPaused = false;

    // NFT Dynamic Traits (Example - Can be expanded and made more complex)
    struct NFTTraits {
        uint8 level;
        string rarity;
        uint256 experiencePoints;
        uint256 evolutionStage;
    }
    mapping(uint256 => NFTTraits) public nftTraits;

    // Marketplace Listings
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;

    // Direct Offers
    struct Offer {
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Offer[]) public offers; // TokenId -> Array of Offers

    // Auctions
    struct Auction {
        uint256 tokenId;
        address seller;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool isActive;
    }
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionDuration = 86400; // 24 hours in seconds

    // Staking
    mapping(address => uint256) public stakedTokens; // User -> Amount Staked

    // Renting
    struct Rental {
        uint256 tokenId;
        address renter;
        uint256 rentFee;
        uint256 rentalEndTime;
        bool isActive;
    }
    mapping(uint256 => Rental) public rentals;

    // Fractionalization
    mapping(uint256 => address) public fractionalizedNFTs; // NFT TokenId -> Fractional Token Contract Address
    mapping(address => uint256) public originalNFTOfFractionalToken; // Fractional Token Contract Address -> Original NFT TokenId

    // Governance Proposals
    struct Proposal {
        uint256 proposalId;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool passed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;

    // Events
    event NFTCreated(uint256 tokenId, address creator);
    event NFTMetadataUpdated(uint256 tokenId, string newURI);
    event NFTEvolved(uint256 tokenId, uint256 newLevel);
    event ItemListed(uint256 tokenId, address seller, uint256 price);
    event ItemBought(uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 tokenId);
    event ListingPriceUpdated(uint256 tokenId, uint256 newPrice);
    event OfferMade(uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 tokenId, address offerer, uint256 price);
    event AuctionStarted(uint256 tokenId, address seller, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 tokenId, address bidder, uint256 bidAmount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 finalPrice);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);
    event NFTRented(uint256 tokenId, address renter, uint256 rentFee, uint256 rentalEndTime);
    event NFTReturned(uint256 tokenId, address renter);
    event NFTFractionalized(uint256 tokenId, address fractionalTokenContract);
    event FractionRedeemed(uint256 tokenId, address redeemer);
    event ProposalCreated(uint256 proposalId, string description, uint256 endTime);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ContractPaused();
    event ContractUnpaused();
    event FeesWithdrawn(uint256 amount);

    // Modifiers
    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier onlyListingOwner(uint256 _tokenId) {
        require(listings[_tokenId].seller == _msgSender(), "You are not the listing owner");
        _;
    }

    modifier onlyOfferOwner(uint256 _tokenId, uint256 _offerIndex) {
        require(offers[_tokenId][_offerIndex].offerer == _msgSender(), "You are not the offer owner");
        _;
    }

    modifier onlyAuctionOwner(uint256 _tokenId) {
        require(auctions[_tokenId].seller == _msgSender(), "You are not the auction owner");
        _;
    }

    modifier onlyNFTFractionOwner(uint256 _tokenId) {
        require(_msgSender() == ownerOf(_tokenId), "You are not the NFT owner");
        _;
    }

    modifier onlyRenter(uint256 _tokenId) {
        require(rentals[_tokenId].renter == _msgSender(), "You are not the renter");
        _;
    }

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _marketplaceTokenAddress, address _feeRecipient) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        marketplaceToken = ERC20(IERC20(_marketplaceTokenAddress)); // Wrap IERC20 to ERC20 for transfer functions
        feeRecipient = _feeRecipient;
        _setDefaultRoyalty(address(this), 500); // Default 5% royalty for creators
    }

    // --- NFT Management Functions ---

    /**
     * @dev Creates a new Dynamic NFT. Only callable by the contract owner.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The metadata URI for the NFT.
     */
    function createNFT(address _to, string memory _tokenURI) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nftTraits[tokenId] = NFTTraits({level: 1, rarity: "Common", experiencePoints: 0, evolutionStage: 1}); // Initialize default traits
        emit NFTCreated(tokenId, _to);
    }

    /**
     * @dev Updates the metadata URI of an existing NFT. Only callable by the contract owner.
     * @param _tokenId The ID of the NFT to update.
     * @param _newTokenURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI) external onlyOwner {
        require(_exists(_tokenId), "NFT does not exist");
        _setTokenURI(_tokenId, _newTokenURI);
        emit NFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    /**
     * @dev Allows NFT owners to evolve their NFTs based on experience points.
     *      Evolution logic is simplified for example purposes.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) external onlyNFTFractionOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        NFTTraits storage traits = nftTraits[_tokenId];

        if (traits.experiencePoints >= 1000 && traits.evolutionStage == 1) {
            traits.evolutionStage = 2;
            traits.level = 2;
            traits.rarity = "Rare";
            emit NFTEvolved(_tokenId, traits.level);
            // In a real application, you'd update metadata or trigger other on-chain/off-chain actions.
        } else if (traits.experiencePoints >= 5000 && traits.evolutionStage == 2) {
            traits.evolutionStage = 3;
            traits.level = 3;
            traits.rarity = "Epic";
            emit NFTEvolved(_tokenId, traits.level);
        } else {
            revert("Not enough experience points to evolve yet.");
        }
    }

    /**
     * @dev Sets the base URI for all NFT metadata. Only callable by the contract owner.
     * @param _newBaseURI The new base URI.
     */
    function setNFTBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // Override _tokenURI to use baseURI
    function _tokenURI(uint256 tokenId) internal view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // --- Marketplace Core Operations ---

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listItem(uint256 _tokenId, uint256 _price) external onlyNFTFractionOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(!listings[_tokenId].isActive, "NFT is already listed");
        require(!auctions[_tokenId].isActive, "NFT is currently in auction");
        require(!rentals[_tokenId].isActive, "NFT is currently rented");

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        listings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        emit ItemListed(_tokenId, _msgSender(), _price);
    }

    /**
     * @dev Buys a listed NFT from the marketplace.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyItem(uint256 _tokenId) external payable whenNotPaused {
        require(listings[_tokenId].isActive, "NFT is not listed for sale");
        Listing storage listing = listings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = listing.price - feeAmount;

        listings[_tokenId].isActive = false;
        _transfer(listing.seller, _msgSender(), _tokenId);

        payable(listing.seller).transfer(sellerPayout);
        payable(feeRecipient).transfer(feeAmount);

        emit ItemBought(_tokenId, _msgSender(), listing.price);
    }

    /**
     * @dev Cancels an existing NFT listing.
     * @param _tokenId The ID of the NFT listing to cancel.
     */
    function cancelListing(uint256 _tokenId) external onlyListingOwner(_tokenId) whenNotPaused {
        require(listings[_tokenId].isActive, "NFT is not currently listed");
        listings[_tokenId].isActive = false;
        emit ListingCancelled(_tokenId);
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _tokenId The ID of the NFT listing to update.
     * @param _newPrice The new listing price.
     */
    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) external onlyListingOwner(_tokenId) whenNotPaused {
        require(listings[_tokenId].isActive, "NFT is not currently listed");
        listings[_tokenId].price = _newPrice;
        emit ListingPriceUpdated(_tokenId, _newPrice);
    }

    /**
     * @dev Allows users to make a direct offer on an NFT that is not listed.
     * @param _tokenId The ID of the NFT to make an offer on.
     */
    function offerItem(uint256 _tokenId) external payable whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) != _msgSender(), "Cannot offer on your own NFT");
        require(!listings[_tokenId].isActive, "NFT is already listed, use buyItem instead");
        require(!auctions[_tokenId].isActive, "NFT is currently in auction");
        require(!rentals[_tokenId].isActive, "NFT is currently rented");

        Offer memory newOffer = Offer({
            tokenId: _tokenId,
            offerer: _msgSender(),
            price: msg.value,
            isActive: true
        });
        offers[_tokenId].push(newOffer);
        emit OfferMade(_tokenId, _msgSender(), msg.value);
    }

    /**
     * @dev Allows NFT owners to accept a direct offer on their NFT.
     * @param _tokenId The ID of the NFT for which to accept an offer.
     * @param _offerIndex The index of the offer in the offers array for this tokenId.
     */
    function acceptOffer(uint256 _tokenId, uint256 _offerIndex) external onlyNFTFractionOwner(_tokenId) whenNotPaused {
        require(offers[_tokenId].length > _offerIndex, "Invalid offer index");
        Offer storage offer = offers[_tokenId][_offerIndex];
        require(offer.isActive, "Offer is not active");

        uint256 feeAmount = (offer.price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = offer.price - feeAmount;

        offer.isActive = false; // Mark offer as no longer active (accepted)
        _transfer(ownerOf(_tokenId), offer.offerer, _tokenId);

        payable(ownerOf(_tokenId)).transfer(sellerPayout);
        payable(feeRecipient).transfer(feeAmount);

        emit OfferAccepted(_tokenId, offer.offerer, offer.price);
    }

    /**
     * @dev Starts a timed auction for an NFT.
     * @param _tokenId The ID of the NFT to auction.
     * @param _startingPrice The starting bid price for the auction.
     */
    function startAuction(uint256 _tokenId, uint256 _startingPrice) external onlyNFTFractionOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(!listings[_tokenId].isActive, "NFT is already listed, cancel listing first");
        require(!auctions[_tokenId].isActive, "NFT is already in auction or auction already exists");
        require(!rentals[_tokenId].isActive, "NFT is currently rented");

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT

        auctions[_tokenId] = Auction({
            tokenId: _tokenId,
            seller: _msgSender(),
            startingPrice: _startingPrice,
            endTime: block.timestamp + auctionDuration,
            highestBidder: address(0),
            highestBid: 0,
            isActive: true
        });
        emit AuctionStarted(_tokenId, _msgSender(), _startingPrice, auctions[_tokenId].endTime);
    }

    /**
     * @dev Allows users to place a bid on an active auction.
     * @param _tokenId The ID of the NFT auction to bid on.
     */
    function bidOnAuction(uint256 _tokenId) external payable whenNotPaused {
        require(auctions[_tokenId].isActive, "Auction is not active");
        Auction storage auction = auctions[_tokenId];
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid amount is too low");

        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid); // Return previous highest bid
        }

        auction.highestBidder = _msgSender();
        auction.highestBid = msg.value;
        emit BidPlaced(_tokenId, _msgSender(), msg.value);
    }

    /**
     * @dev Ends an auction, transfers NFT to the highest bidder and pays the seller.
     * @param _tokenId The ID of the NFT auction to end.
     */
    function endAuction(uint256 _tokenId) external whenNotPaused {
        require(auctions[_tokenId].isActive, "Auction is not active");
        Auction storage auction = auctions[_tokenId];
        require(block.timestamp >= auction.endTime, "Auction time has not ended yet");

        auctions[_tokenId].isActive = false;
        if (auction.highestBidder != address(0)) {
            uint256 feeAmount = (auction.highestBid * marketplaceFeePercentage) / 100;
            uint256 sellerPayout = auction.highestBid - feeAmount;

            _transfer(auction.seller, auction.highestBidder, _tokenId);
            payable(auction.seller).transfer(sellerPayout);
            payable(feeRecipient).transfer(feeAmount);
            emit AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids placed, return NFT to seller
            _transfer(address(this), auction.seller, _tokenId); // Transfer from contract back to seller
            emit AuctionEnded(_tokenId, address(0), 0); // Indicate no winner
        }
    }

    // --- Advanced Features ---

    /**
     * @dev Allows users to stake marketplace tokens to gain benefits (e.g., reduced fees in future).
     * @param _amount The amount of marketplace tokens to stake.
     */
    function stakeMarketplaceToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount to stake must be greater than zero");
        require(marketplaceToken.transferFrom(_msgSender(), address(this), _amount), "Token transfer failed");
        stakedTokens[_msgSender()] += _amount;
        emit TokensStaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to unstake their marketplace tokens.
     * @param _amount The amount of marketplace tokens to unstake.
     */
    function unstakeMarketplaceToken(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount to unstake must be greater than zero");
        require(stakedTokens[_msgSender()] >= _amount, "Insufficient staked tokens");
        stakedTokens[_msgSender()] -= _amount;
        require(marketplaceToken.transfer(_msgSender(), _amount), "Token transfer failed");
        emit TokensUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows NFT owners to rent out their NFTs for a fixed duration and fee.
     * @param _tokenId The ID of the NFT to rent out.
     * @param _rentFee The fee for renting the NFT.
     * @param _rentalDurationSeconds The duration of the rental in seconds.
     */
    function rentNFT(uint256 _tokenId, uint256 _rentFee, uint256 _rentalDurationSeconds) external onlyNFTFractionOwner(_tokenId) payable whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT");
        require(msg.value >= _rentFee, "Insufficient rent fee provided");
        require(!listings[_tokenId].isActive, "NFT is already listed, cancel listing first");
        require(!auctions[_tokenId].isActive, "NFT is currently in auction");
        require(!rentals[_tokenId].isActive, "NFT is already rented");

        _approve(address(this), _tokenId); // Approve marketplace to transfer NFT for rental

        rentals[_tokenId] = Rental({
            tokenId: _tokenId,
            renter: _msgSender(),
            rentFee: _rentFee,
            rentalEndTime: block.timestamp + _rentalDurationSeconds,
            isActive: true
        });
        _transfer(_msgSender(), address(this), _tokenId); // Transfer NFT to contract for rental period
        payable(ownerOf(_tokenId)).transfer(_rentFee); // Pay rent fee immediately
        emit NFTRented(_tokenId, _msgSender(), _rentFee, rentals[_tokenId].rentalEndTime);
    }

    /**
     * @dev Allows renters to return rented NFTs before the rental period ends, or is called automatically after rental end.
     * @param _tokenId The ID of the rented NFT to return.
     */
    function returnNFT(uint256 _tokenId) external whenNotPaused {
        require(rentals[_tokenId].isActive, "NFT is not currently rented");
        Rental storage rental = rentals[_tokenId];

        require(_msgSender() == rental.renter || block.timestamp >= rental.rentalEndTime || _msgSender() == ownerOf(_tokenId), "Only renter or owner can return/auto-return or rental time not elapsed yet for auto-return");

        rental.isActive = false;
        _transfer(address(this), ownerOf(_tokenId), _tokenId); // Return NFT to owner
        emit NFTReturned(_tokenId, rental.renter);
    }

    /**
     * @dev Allows NFT owners to fractionalize their NFTs, creating ERC20 tokens representing fractions.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _fractionSymbol The symbol for the fractional ERC20 token.
     * @param _fractionName The name for the fractional ERC20 token.
     * @param _totalSupply The total supply of fractional tokens to create.
     */
    function fractionalizeNFT(uint256 _tokenId, string memory _fractionSymbol, string memory _fractionName, uint256 _totalSupply) external onlyNFTFractionOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(fractionalizedNFTs[_tokenId] == address(0), "NFT is already fractionalized");

        FractionalToken fractionalToken = new FractionalToken(_fractionName, _fractionSymbol, _totalSupply);
        fractionalizedNFTs[_tokenId] = address(fractionalToken);
        originalNFTOfFractionalToken[address(fractionalToken)] = _tokenId;

        _approve(address(fractionalToken), _tokenId); // Approve fractional token contract to handle NFT

        _transfer(_msgSender(), address(fractionalToken), _tokenId); // Transfer NFT ownership to fractional token contract
        fractionalToken.mint(_msgSender(), _totalSupply); // Mint fractional tokens to original NFT owner
        emit NFTFractionalized(_tokenId, address(fractionalToken));
    }

    /**
     * @dev Allows fraction token holders to redeem fractions to collectively own the original NFT (requires governance).
     * @param _fractionTokenContract The address of the fractional ERC20 token contract.
     * @param _amount The amount of fraction tokens to redeem.
     */
    function redeemFraction(address _fractionTokenContract, uint256 _amount) external whenNotPaused {
        require(originalNFTOfFractionalToken[_fractionTokenContract] != 0, "Not a fractional token contract");
        uint256 originalTokenId = originalNFTOfFractionalToken[_fractionTokenContract];

        FractionalToken fractionalToken = FractionalToken(IERC20(_fractionTokenContract)); // Wrap to access ERC20 functions

        require(fractionalToken.balanceOf(_msgSender()) >= _amount, "Insufficient fractional tokens");
        require(fractionalToken.allowance(_msgSender(), address(this)) >= _amount, "Approve marketplace to transfer fractional tokens");

        fractionalToken.transferFrom(_msgSender(), address(this), _amount); // Transfer fraction tokens to contract (burned effectively)
        fractionalToken.burn(_msgSender(), _amount); // Burn tokens

        // In a real scenario, you'd implement governance logic here to decide what happens to the original NFT.
        // For simplicity, let's assume redeeming a significant portion of fractions gives voting rights on NFT transfer.
        // This part needs a more complex implementation for real-world use cases (DAO, voting, etc.).

        emit FractionRedeemed(originalTokenId, _msgSender());
    }

    /**
     * @dev Allows staked token holders to vote on marketplace proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period ended");
        require(stakedTokens[_msgSender()] > 0, "You must stake marketplace tokens to vote"); // Require staking to vote

        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesVotes += stakedTokens[_msgSender()]; // Voting power based on staked amount
        } else {
            proposal.noVotes += stakedTokens[_msgSender()];
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Creates a new marketplace governance proposal. Only callable by the contract owner.
     * @param _description The description of the proposal.
     * @param _votingDurationSeconds The duration of the voting period in seconds.
     */
    function createProposal(string memory _description, uint256 _votingDurationSeconds) external onlyOwner whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: _description,
            startTime: block.timestamp,
            endTime: block.timestamp + _votingDurationSeconds,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            passed: false
        });
        emit ProposalCreated(proposalId, _description, proposals[proposalId].endTime);
    }

    /**
     * @dev Ends a proposal and determines if it passed based on votes. Only callable after voting period.
     * @param _proposalId The ID of the proposal to end.
     */
    function endProposal(uint256 _proposalId) external whenNotPaused {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(block.timestamp >= proposals[_proposalId].endTime, "Voting period not ended yet");

        Proposal storage proposal = proposals[_proposalId];
        proposal.isActive = false;

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.passed = true;
            // Implement actions based on proposal passing here (e.g., change fees, update features).
        } else {
            proposal.passed = false;
        }
    }


    // --- Utility & Admin Functions ---

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = _feePercentage;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 tokenBalance = marketplaceToken.balanceOf(address(this));
        payable(feeRecipient).transfer(balance);
        marketplaceToken.transfer(feeRecipient, tokenBalance);
        emit FeesWithdrawn(balance + tokenBalance);
    }

    /**
     * @dev Pauses core marketplace functions (listing, buying, auctions, renting). Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner {
        contractPaused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses core marketplace functions. Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Emergency function to withdraw any ERC20 tokens mistakenly sent to the contract. Only callable by the contract owner.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _amount The amount of tokens to withdraw.
     * @param _recipient The address to send the tokens to.
     */
    function emergencyWithdrawTokens(address _tokenAddress, uint256 _amount, address _recipient) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(_amount <= contractBalance, "Insufficient tokens in contract");
        require(token.transfer(_recipient, _amount), "Token transfer failed");
    }

    /**
     * @dev Emergency function to withdraw any accidentally sent ETH to the contract. Only callable by the contract owner.
     * @param _recipient The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw.
     */
    function emergencyWithdrawETH(address payable _recipient, uint256 _amount) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(_amount <= contractBalance, "Insufficient ETH in contract");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }

    // ERC2981 Royalty Information
    function _ royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    )
        internal
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (feeRecipient, (_salePrice * 500) / 10000); // 5% royalty
    }

    // --- Fractional Token Contract (Nested for simplicity, can be separate) ---
    contract FractionalToken is ERC20, Ownable {
        uint256 public originalNFTTokenId; // Track original NFT

        constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol) {
            _mint(msg.sender, _totalSupply); // Mint initial supply to deployer
        }

        function mint(address _to, uint256 _amount) public onlyOwner {
            _mint(_to, _amount);
        }

        function burn(address _from, uint256 _amount) public onlyOwner {
             _burn(_from, _amount); // Only owner (Marketplace Contract) can burn after redemption
        }

        function setOriginalNFTTokenId(uint256 _tokenId) external onlyOwner {
            originalNFTTokenId = _tokenId;
        }
    }
}
```