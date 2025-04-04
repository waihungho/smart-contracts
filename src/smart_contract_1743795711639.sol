```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace that incorporates elements of personalization and advanced features.
 *      This contract allows for the creation, listing, trading, and personalization of Dynamic NFTs, which can evolve based on on-chain and off-chain data.
 *      It also introduces features like AI-powered recommendations (simulated on-chain for demonstration), NFT staking for marketplace benefits,
 *      rental functionalities, decentralized governance for marketplace parameters, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. Admin & Governance Functions:**
 *    - `setMarketplaceFee(uint256 _fee)`:  Sets the marketplace fee percentage. (Admin)
 *    - `pauseMarketplace()`: Pauses all marketplace trading activity. (Admin)
 *    - `unpauseMarketplace()`: Resumes marketplace trading activity. (Admin)
 *    - `addSupportedCurrency(address _currency)`: Adds a supported currency for trading (e.g., ERC20 tokens). (Governance)
 *    - `removeSupportedCurrency(address _currency)`: Removes a supported currency. (Governance)
 *    - `proposeGovernanceChange(string _proposalDescription, bytes _calldata)`: Proposes a governance change to be voted on. (Governance)
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on governance proposals. (Governance, Token Holders)
 *    - `executeGovernanceProposal(uint256 _proposalId)`: Executes a passed governance proposal. (Governance, after voting period)
 *
 * **2. NFT Management Functions:**
 *    - `createDynamicNFT(string memory _baseURI, string memory _initialMetadata)`: Mints a new Dynamic NFT with a base URI and initial metadata. (Users)
 *    - `updateDynamicMetadata(uint256 _tokenId, string memory _newMetadata)`: Updates the dynamic metadata of an NFT. (NFT Owner)
 *    - `customizeNFT(uint256 _tokenId, string memory _customizationData)`: Allows NFT owners to apply customizations (e.g., visual layers, traits). (NFT Owner)
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership. (NFT Owner)
 *
 * **3. Marketplace Listing & Trading Functions:**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price, address _currency)`: Lists an NFT for sale at a fixed price in a specified currency. (NFT Owner)
 *    - `cancelNFTListing(uint256 _tokenId)`: Cancels an NFT listing. (NFT Owner)
 *    - `buyNFT(uint256 _tokenId, address _currency)`: Buys a listed NFT using a supported currency. (Users)
 *    - `makeOffer(uint256 _tokenId, uint256 _price, address _currency)`: Makes an offer on an NFT (even if not listed, or at a different price). (Users)
 *    - `acceptOffer(uint256 _offerId)`: Accepts a specific offer on an NFT. (NFT Owner)
 *    - `rentNFT(uint256 _tokenId, address _renter, uint256 _rentalDurationDays, uint256 _rentalFee, address _currency)`: Allows NFT owners to rent out their NFTs for a period. (NFT Owner)
 *    - `endRental(uint256 _rentalId)`: Ends an NFT rental and returns the NFT to the owner. (Renter or NFT Owner)
 *
 * **4. Personalization & Recommendation (Simulated) Functions:**
 *    - `setUserPreferences(string memory _preferencesData)`: Allows users to set their preferences for NFT recommendations. (Users)
 *    - `getNFTRecommendations(address _user)`:  (Simulated AI) Returns a list of recommended NFT token IDs based on user preferences (for demonstration, uses simple on-chain logic). (Users)
 *    - `provideRecommendationFeedback(uint256 _recommendedTokenId, bool _isRelevant)`: Allows users to provide feedback on recommendations to improve future suggestions (simulated learning). (Users)
 *
 * **5. Utility & Staking Functions:**
 *    - `stakeNFTForBenefits(uint256 _tokenId)`: Allows users to stake their NFTs to receive marketplace benefits (e.g., reduced fees, governance power). (NFT Owners)
 *    - `unstakeNFT(uint256 _tokenId)`: Unstakes an NFT. (NFT Owners)
 *    - `getListingPrice(uint256 _price)`: Calculates the final listing price including marketplace fee. (View - Anyone)
 *    - `getOfferPrice(uint256 _price)`: Calculates the final offer price including marketplace fee. (View - Anyone)
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol"; // For governance

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _offerIdCounter;
    Counters.Counter private _rentalIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    bool public marketplacePaused = false;
    mapping(address => bool) public supportedCurrencies;
    address public governanceTimelock; // Address of the TimelockController for governance

    // NFT metadata information
    mapping(uint256 => string) public nftBaseURIs;
    mapping(uint256 => string) public nftMetadata;
    mapping(uint256 => string) public nftCustomizations;

    // Marketplace Listings
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        address currency;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;
    mapping(uint256 => uint256) public tokenIdToListingId; // Mapping tokenId to listingId for faster lookup

    // Offers
    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address buyer;
        uint256 price;
        address currency;
        bool isActive;
    }
    mapping(uint256 => Offer) public nftOffers;

    // Rentals
    struct Rental {
        uint256 rentalId;
        uint256 tokenId;
        address owner;
        address renter;
        uint256 rentalStartTime;
        uint256 rentalEndTime;
        uint256 rentalFee;
        address currency;
        bool isActive;
    }
    mapping(uint256 => Rental) public nftRentals;
    mapping(uint256 => bool) public isNFTOnRent; // Track if an NFT is currently rented

    // User Preferences (Simulated - In a real application, this would be off-chain or more sophisticated)
    mapping(address => string) public userPreferences;

    // NFT Staking
    mapping(uint256 => bool) public isNFTStaked;
    mapping(address => uint256[]) public stakedNFTsByUser;

    // Governance Proposals
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes calldataData;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voterAddress => votedYes

    event NFTMinted(uint256 tokenId, address creator);
    event MetadataUpdated(uint256 tokenId, string newMetadata);
    event CustomizationApplied(uint256 tokenId, uint256 tokenIdApplied, string customizationData);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price, address currency);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event NFTSold(uint256 listingId, uint256 tokenId, address buyer, uint256 price, address currency);
    event OfferMade(uint256 offerId, uint256 tokenId, address buyer, uint256 price, address currency);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price, address currency);
    event NFTRented(uint256 rentalId, uint256 tokenId, address owner, address renter, uint256 rentalEndTime, uint256 rentalFee, address currency);
    event RentalEnded(uint256 rentalId, uint256 tokenId, address owner, address renter);
    event UserPreferencesSet(address user, string preferencesData);
    event NFTStaked(uint256 tokenId, address user);
    event NFTUnstaked(uint256 tokenId, address user);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event CurrencyAdded(address currencyAddress);
    event CurrencyRemoved(address currencyAddress);


    constructor(string memory _name, string memory _symbol, address _governanceTimelock) ERC721(_name, _symbol) {
        governanceTimelock = _governanceTimelock;
        supportedCurrencies[address(0)] = true; // Native currency (ETH) supported by default
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceTimelock, "Only governance timelock contract can call this function");
        _;
    }

    modifier whenMarketplaceNotPaused() {
        require(!marketplacePaused, "Marketplace is currently paused");
        _;
    }

    modifier whenMarketplacePaused() {
        require(marketplacePaused, "Marketplace is not paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not the NFT owner or approved");
        _;
    }

    modifier validCurrency(address _currency) {
        require(supportedCurrencies[_currency], "Currency not supported");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(nftListings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier validOffer(uint256 _offerId) {
        require(nftOffers[_offerId].isActive, "Offer is not active");
        _;
    }

    modifier validRental(uint256 _rentalId) {
        require(nftRentals[_rentalId].isActive, "Rental is not active");
        _;
    }

    modifier notOnRent(uint256 _tokenId) {
        require(!isNFTOnRent[_tokenId], "NFT is currently on rent");
        _;
    }

    modifier notStaked(uint256 _tokenId) {
        require(!isNFTStaked[_tokenId], "NFT is currently staked");
        _;
    }

    modifier isStaked(uint256 _tokenId) {
        require(isNFTStaked[_tokenId], "NFT is not staked");
        _;
    }

    // ------------------------------------------------------------------------
    // 1. Admin & Governance Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _fee The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _fee) external onlyOwner {
        require(_fee <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _fee;
        emit MarketplaceFeeUpdated(_fee);
    }

    /**
     * @dev Pauses all marketplace trading activity. Only callable by the contract owner.
     */
    function pauseMarketplace() external onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Resumes marketplace trading activity. Only callable by the contract owner.
     */
    function unpauseMarketplace() external onlyOwner whenMarketplacePaused {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Adds a supported currency for trading. Only callable by the governance timelock.
     * @param _currency The address of the ERC20 token to support.
     */
    function addSupportedCurrency(address _currency) external onlyGovernance {
        supportedCurrencies[_currency] = true;
        emit CurrencyAdded(_currency);
    }

    /**
     * @dev Removes a supported currency. Only callable by the governance timelock.
     * @param _currency The address of the ERC20 token to remove.
     */
    function removeSupportedCurrency(address _currency) external onlyGovernance {
        require(_currency != address(0), "Cannot remove native currency support");
        delete supportedCurrencies[_currency];
        emit CurrencyRemoved(_currency);
    }

    /**
     * @dev Proposes a governance change to be voted on by token holders.
     * @param _proposalDescription A description of the proposal.
     * @param _calldata The calldata to be executed if the proposal passes.
     */
    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _calldata) external onlyGovernance {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _proposalDescription,
            calldataData: _calldata,
            isActive: true,
            startTime: block.timestamp,
            endTime: block.timestamp + 7 days, // 7-day voting period
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, _proposalDescription);
    }

    /**
     * @dev Allows token holders to vote on a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active");
        require(block.timestamp < proposal.endTime, "Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed governance proposal after the voting period. Only callable by governance timelock.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernance {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.isActive, "Proposal is not active");
        require(block.timestamp >= proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        proposal.isActive = false;
        proposal.executed = true;

        if (proposal.yesVotes > proposal.noVotes) {
            (bool success, ) = address(this).call(proposal.calldataData);
            require(success, "Governance proposal execution failed");
            emit GovernanceProposalExecuted(_proposalId);
        }
    }


    // ------------------------------------------------------------------------
    // 2. NFT Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic NFT with a base URI and initial metadata.
     * @param _baseURI The base URI for the NFT's metadata (can be IPFS, etc.).
     * @param _initialMetadata Initial metadata to be associated with the NFT.
     * @return The ID of the newly minted NFT.
     */
    function createDynamicNFT(string memory _baseURI, string memory _initialMetadata)
        external
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        nftBaseURIs[tokenId] = _baseURI;
        nftMetadata[tokenId] = _initialMetadata;
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @dev Updates the dynamic metadata of an NFT. Only callable by the NFT owner.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadata The new metadata for the NFT.
     */
    function updateDynamicMetadata(uint256 _tokenId, string memory _newMetadata) external onlyNFTOwner(_tokenId) {
        nftMetadata[_tokenId] = _newMetadata;
        emit MetadataUpdated(_tokenId, _newMetadata);
    }

    /**
     * @dev Allows NFT owners to apply customizations to their NFTs.
     * @param _tokenId The ID of the NFT to customize.
     * @param _customizationData Data representing the customization (e.g., JSON, URI).
     */
    function customizeNFT(uint256 _tokenId, string memory _customizationData) external onlyNFTOwner(_tokenId) {
        nftCustomizations[_tokenId] = _customizationData;
        emit CustomizationApplied(_tokenId, _tokenId, _customizationData);
    }

    /**
     * @dev Transfers NFT ownership. Standard ERC721 transfer function.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) external onlyNFTOwner(_tokenId) notOnRent(_tokenId) notStaked(_tokenId) {
        _transfer(msg.sender, _to, _tokenId);
    }


    // ------------------------------------------------------------------------
    // 3. Marketplace Listing & Trading Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Lists an NFT for sale at a fixed price in a specified currency.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price.
     * @param _currency The currency to list in (address(0) for ETH, ERC20 token address).
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price, address _currency)
        external
        onlyNFTOwner(_tokenId)
        whenMarketplaceNotPaused
        notOnRent(_tokenId)
        notStaked(_tokenId)
        validCurrency(_currency)
    {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(tokenIdToListingId[_tokenId] == 0 || !nftListings[tokenIdToListingId[_tokenId]].isActive, "NFT already listed or listing active");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        nftListings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            currency: _currency,
            isActive: true
        });
        tokenIdToListingId[_tokenId] = listingId;

        _approve(address(this), _tokenId); // Approve marketplace to handle sale
        emit NFTListed(listingId, _tokenId, msg.sender, _price, _currency);
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _tokenId The ID of the NFT to cancel the listing for.
     */
    function cancelNFTListing(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenMarketplaceNotPaused {
        uint256 listingId = tokenIdToListingId[_tokenId];
        require(listingId != 0, "NFT is not currently listed");
        require(nftListings[listingId].seller == msg.sender, "You are not the seller");
        require(nftListings[listingId].isActive, "Listing is not active");

        nftListings[listingId].isActive = false;
        tokenIdToListingId[_tokenId] = 0; // Clear the mapping
        _approve(address(0), _tokenId); // Remove marketplace approval
        emit ListingCancelled(listingId, _tokenId);
    }

    /**
     * @dev Buys a listed NFT.
     * @param _tokenId The ID of the NFT to buy.
     * @param _currency The currency to use for the purchase (must match listing currency).
     */
    function buyNFT(uint256 _tokenId, address _currency)
        external
        payable
        whenMarketplaceNotPaused
        nonReentrant
        validCurrency(_currency)
    {
        uint256 listingId = tokenIdToListingId[_tokenId];
        require(listingId != 0, "NFT is not currently listed");
        Listing storage listing = nftListings[listingId];
        require(listing.isActive, "Listing is not active");
        require(listing.currency == _currency, "Currency does not match listing currency");

        uint256 finalPrice = getListingPrice(listing.price);

        if (_currency == address(0)) { // Native currency (ETH)
            require(msg.value >= finalPrice, "Insufficient ETH sent");
            payable(listing.seller).transfer(finalPrice);
            if (msg.value > finalPrice) {
                payable(msg.sender).transfer(msg.value - finalPrice); // Return excess ETH
            }
        } else { // ERC20 token
            IERC20 token = IERC20(_currency);
            require(token.transferFrom(msg.sender, address(this), finalPrice), "ERC20 transfer failed");
            require(token.transfer(listing.seller, listing.price), "ERC20 payout to seller failed"); // Send price without fee to seller
        }

        listing.isActive = false;
        tokenIdToListingId[_tokenId] = 0; // Clear the mapping
        _approve(address(0), _tokenId); // Remove marketplace approval
        _transfer(listing.seller, msg.sender, _tokenId); // Transfer NFT to buyer
        emit NFTSold(listingId, _tokenId, msg.sender, listing.price, _currency);
    }

    /**
     * @dev Makes an offer on an NFT, even if not listed, or at a different price.
     * @param _tokenId The ID of the NFT to make an offer on.
     * @param _price The offer price.
     * @param _currency The currency for the offer.
     */
    function makeOffer(uint256 _tokenId, uint256 _price, address _currency)
        external
        payable
        whenMarketplaceNotPaused
        validCurrency(_currency)
    {
        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        nftOffers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            buyer: msg.sender,
            price: _price,
            currency: _currency,
            isActive: true
        });

        emit OfferMade(offerId, _tokenId, msg.sender, _price, _currency);
    }

    /**
     * @dev Accepts a specific offer on an NFT. Only callable by the NFT owner.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId)
        external
        onlyNFTOwner(nftOffers[_offerId].tokenId)
        whenMarketplaceNotPaused
        nonReentrant
        validOffer(_offerId)
    {
        Offer storage offer = nftOffers[_offerId];
        require(ownerOf(offer.tokenId) == msg.sender, "You are not the owner of this NFT");

        uint256 finalPrice = getOfferPrice(offer.price);

        if (offer.currency == address(0)) { // Native currency (ETH)
            payable(offer.buyer).transfer(finalPrice); // Refund offer amount (minus fee) to buyer
            payable(msg.sender).transfer(offer.price); // Send offer price to seller (without fee taken from offer)
        } else { // ERC20 token
            IERC20 token = IERC20(offer.currency);
            require(token.transferFrom(offer.buyer, address(this), finalPrice), "ERC20 transfer failed"); // Buyer pays offer amount + fee to marketplace
            require(token.transfer(msg.sender, offer.price), "ERC20 payout to seller failed"); // Seller receives offer amount (without fee)
        }

        offer.isActive = false;
        _transfer(msg.sender, offer.buyer, offer.tokenId); // Transfer NFT to buyer
        emit OfferAccepted(offer._offerId, offer.tokenId, msg.sender, offer.buyer, offer.price, offer.currency);
    }


    /**
     * @dev Allows NFT owners to rent out their NFTs for a period.
     * @param _tokenId The ID of the NFT to rent.
     * @param _renter The address of the renter.
     * @param _rentalDurationDays The duration of the rental in days.
     * @param _rentalFee The fee for the rental.
     * @param _currency The currency for the rental fee.
     */
    function rentNFT(uint256 _tokenId, address _renter, uint256 _rentalDurationDays, uint256 _rentalFee, address _currency)
        external
        onlyNFTOwner(_tokenId)
        whenMarketplaceNotPaused
        notOnRent(_tokenId)
        notStaked(_tokenId)
        validCurrency(_currency)
    {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        _rentalIdCounter.increment();
        uint256 rentalId = _rentalIdCounter.current();
        uint256 rentalEndTime = block.timestamp + (_rentalDurationDays * 1 days);

        nftRentals[rentalId] = Rental({
            rentalId: rentalId,
            tokenId: _tokenId,
            owner: msg.sender,
            renter: _renter,
            rentalStartTime: block.timestamp,
            rentalEndTime: rentalEndTime,
            rentalFee: _rentalFee,
            currency: _currency,
            isActive: true
        });
        isNFTOnRent[_tokenId] = true;
        _approve(_renter, _tokenId); // Approve renter to use the NFT during rental period

        emit NFTRented(rentalId, _tokenId, msg.sender, _renter, rentalEndTime, _rentalFee, _currency);
    }

    /**
     * @dev Ends an NFT rental and returns the NFT to the owner. Callable by renter or owner after rental period.
     * @param _rentalId The ID of the rental to end.
     */
    function endRental(uint256 _rentalId) external whenMarketplaceNotPaused validRental(_rentalId) {
        Rental storage rental = nftRentals[_rentalId];
        require(msg.sender == rental.renter || msg.sender == rental.owner || block.timestamp >= rental.rentalEndTime, "Only renter, owner or after rental end time can end rental");

        rental.isActive = false;
        isNFTOnRent[rental.tokenId] = false;
        _approve(address(0), rental.tokenId); // Remove renter approval
        emit RentalEnded(_rentalId, rental.tokenId, rental.owner, rental.renter);
    }


    // ------------------------------------------------------------------------
    // 4. Personalization & Recommendation (Simulated) Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to set their preferences for NFT recommendations.
     * @param _preferencesData Data representing user preferences (e.g., JSON, tags).
     */
    function setUserPreferences(string memory _preferencesData) external {
        userPreferences[msg.sender] = _preferencesData;
        emit UserPreferencesSet(msg.sender, _preferencesData);
    }

    /**
     * @dev (Simulated AI) Returns a list of recommended NFT token IDs based on user preferences.
     *       This is a simplified on-chain simulation for demonstration. A real AI recommendation system
     *       would likely be off-chain for complexity and cost reasons.
     * @param _user The address of the user to get recommendations for.
     * @return An array of recommended NFT token IDs.
     */
    function getNFTRecommendations(address _user) external view returns (uint256[] memory) {
        string memory preferences = userPreferences[_user];
        uint256[] memory recommendations = new uint256[](0);

        // *** Simple On-Chain Recommendation Logic (Example - Replace with more sophisticated logic or off-chain integration) ***
        // Here we just return NFTs with even token IDs as "recommended" for demonstration.
        // In a real scenario, you'd parse userPreferences, compare with NFT metadata/tags, and use algorithms.
        uint256 recommendationCount = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) != address(0) && i % 2 == 0) { // Example: Even token IDs are "recommended"
                recommendationCount++;
            }
        }
        recommendations = new uint256[](recommendationCount);
        uint256 index = 0;
         for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) != address(0) && i % 2 == 0) {
                recommendations[index] = i;
                index++;
            }
        }
        // *** End of Simple Recommendation Logic ***

        return recommendations;
    }

    /**
     * @dev Allows users to provide feedback on recommendations to improve future suggestions (simulated learning).
     *       In a real system, this feedback would be used to train an off-chain AI model.
     * @param _recommendedTokenId The token ID of the NFT that was recommended.
     * @param _isRelevant True if the recommendation was relevant to the user's preferences, false otherwise.
     */
    function provideRecommendationFeedback(uint256 _recommendedTokenId, bool _isRelevant) external {
        // In a real application, you would send this feedback off-chain to an AI service.
        // For this on-chain example, we can just store basic feedback (or ignore it for simplicity).
        // ... (Logic to store or process feedback - can be skipped for this example's scope)
    }


    // ------------------------------------------------------------------------
    // 5. Utility & Staking Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows users to stake their NFTs to receive marketplace benefits.
     * @param _tokenId The ID of the NFT to stake.
     */
    function stakeNFTForBenefits(uint256 _tokenId) external onlyNFTOwner(_tokenId) notStaked(_tokenId) notOnRent(_tokenId) {
        isNFTStaked[_tokenId] = true;
        stakedNFTsByUser[msg.sender].push(_tokenId);
        _approve(address(this), _tokenId); // Approve marketplace to hold the NFT during staking
        emit NFTStaked(_tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an NFT, returning it to the owner.
     * @param _tokenId The ID of the NFT to unstake.
     */
    function unstakeNFT(uint256 _tokenId) external onlyNFTOwner(_tokenId) isStaked(_tokenId) {
        isNFTStaked[_tokenId] = false;
        _approve(address(0), _tokenId); // Remove marketplace approval
        // Remove tokenId from stakedNFTsByUser array (inefficient but demonstration)
        uint256[] storage stakedTokens = stakedNFTsByUser[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == _tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Calculates the final listing price including marketplace fee.
     * @param _price The base listing price.
     * @return The final price including the marketplace fee.
     */
    function getListingPrice(uint256 _price) public view returns (uint256) {
        return _price + (_price * marketplaceFeePercentage / 100);
    }

    /**
     * @dev Calculates the final offer price including marketplace fee.
     * @param _price The base offer price.
     * @return The final price including the marketplace fee.
     */
    function getOfferPrice(uint256 _price) public view returns (uint256) {
        return _price + (_price * marketplaceFeePercentage / 100);
    }

    /**
     * @dev Returns the base URI for an NFT. Overrides ERC721 tokenURI to use dynamic base URI.
     * @param _tokenId The ID of the NFT.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = nftBaseURIs[_tokenId];
        string memory metadata = nftMetadata[_tokenId];
        return string(abi.encodePacked(baseURI, _toString(_tokenId), "/", metadata, ".json")); // Example URI construction
    }

    /**
     * @dev Helper function to convert uint256 to string.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```