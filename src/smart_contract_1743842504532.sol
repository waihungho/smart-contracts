```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation & Advanced Features
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic NFT marketplace with advanced features like AI-driven curation scores,
 *      NFT rental, fractional ownership, voting mechanisms, and dynamic metadata updates based on market conditions.
 *      It aims to be a comprehensive and innovative NFT platform, going beyond basic marketplace functionalities.
 *
 * **Outline of Functions:**
 *
 * 1.  `mintNFT(address _to, string memory _uri)`: Mints a new NFT with a given URI to a recipient.
 * 2.  `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT, removing it from circulation.
 * 3.  `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT to another address.
 * 4.  `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * 5.  `buyItem(uint256 _listingId)`: Allows users to buy a listed NFT.
 * 6.  `cancelListing(uint256 _listingId)`: Allows the seller to cancel a listing.
 * 7.  `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Updates the price of a listed NFT.
 * 8.  `rentNFT(uint256 _tokenId, uint256 _rentalPeriod)`: Allows NFT owners to rent out their NFTs for a specified period.
 * 9.  `endRental(uint256 _rentalId)`: Allows renters or owners to end an active NFT rental.
 * 10. `createFractionalOwnership(uint256 _tokenId, uint256 _numberOfShares)`: Creates fractional ownership for an NFT, dividing it into shares.
 * 11. `buyFractionalShare(uint256 _fractionalId, uint256 _numberOfShares)`: Allows users to buy fractional shares of an NFT.
 * 12. `voteOnNFTMetadataChange(uint256 _tokenId, string memory _newMetadataURI)`: Initiates a vote among fractional owners to change NFT metadata.
 * 13. `executeMetadataChangeVote(uint256 _tokenId)`: Executes a successful metadata change vote.
 * 14. `submitNFTForAICuration(uint256 _tokenId)`: Allows users to submit an NFT for AI-based curation (simulated off-chain).
 * 15. `setAICurationScore(uint256 _tokenId, uint256 _score)`: Admin function to set the AI curation score for an NFT.
 * 16. `getAICurationScore(uint256 _tokenId)`: Retrieves the AI curation score of an NFT.
 * 17. `setMarketplaceFee(uint256 _feePercentage)`: Admin function to set the marketplace fee percentage.
 * 18. `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 * 19. `pauseMarketplace()`: Admin function to temporarily pause the marketplace.
 * 20. `unpauseMarketplace()`: Admin function to resume a paused marketplace.
 * 21. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 * 22. `getRentalDetails(uint256 _rentalId)`: Retrieves details of a specific NFT rental.
 * 23. `getFractionalDetails(uint256 _fractionalId)`: Retrieves details of a specific fractional ownership setup.
 * 24. `getUserNFTBalance(address _user)`: Gets the number of NFTs owned by a user.
 * 25. `isNFTListed(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *
 * **Function Summary:**
 *
 * - **NFT Core Functions (Mint, Burn, Transfer):** Basic NFT management.
 * - **Marketplace Listing Functions (List, Buy, Cancel, Update Price):** Core marketplace trading functionality.
 * - **NFT Rental Functions (Rent, End Rental):** Enables temporary NFT access and utility.
 * - **Fractional Ownership Functions (Create Fractional, Buy Share, Vote Metadata, Execute Vote):** Allows shared ownership and governance of NFTs.
 * - **AI Curation Functions (Submit for AI, Set AI Score, Get AI Score):** Simulates off-chain AI curation influence on NFT value and discoverability.
 * - **Marketplace Administration Functions (Set Fee, Withdraw Fees, Pause, Unpause):** Management and control of the marketplace by the contract owner.
 * - **Data Retrieval Functions (Get Listing Details, Get Rental Details, Get Fractional Details, Get User NFT Balance, Is NFT Listed):**  Functions to query and access marketplace data.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicAICuratedNFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _nftCounter;
    Counters.Counter private _listingCounter;
    Counters.Counter private _rentalCounter;
    Counters.Counter private _fractionalCounter;
    Counters.Counter private _voteCounter;

    string public nftName = "DynamicAICuratedNFT";
    string public nftSymbol = "DACNFT";

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => address) private _nftOwners;
    mapping(uint256 => address) private _nftApprovals;
    mapping(address => uint256) private _userNFTBalance;

    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;

    struct Rental {
        uint256 rentalId;
        uint256 tokenId;
        address owner;
        address renter;
        uint256 rentalPeriod; // in blocks or time units
        uint256 rentalStartTime;
        bool isActive;
    }
    mapping(uint256 => Rental) public rentals;

    struct FractionalOwnership {
        uint256 fractionalId;
        uint256 tokenId;
        uint256 totalShares;
        mapping(address => uint256) sharesOwned;
    }
    mapping(uint256 => FractionalOwnership) public fractionalOwnerships;
    mapping(uint256 => address[]) public fractionalOwners; // Keep track of owners for voting

    struct MetadataChangeVote {
        uint256 voteId;
        uint256 tokenId;
        string newMetadataURI;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        bool isActive;
    }
    mapping(uint256 => MetadataChangeVote) public metadataChangeVotes;

    mapping(uint256 => uint256) public aiCurationScores; // NFT ID => AI Curation Score
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public marketplaceFeeRecipient;

    bool public isMarketplacePaused = false;

    event NFTMinted(uint256 tokenId, address to, string tokenURI);
    event NFTBurned(uint256 tokenId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event NFTRented(uint256 rentalId, uint256 tokenId, address owner, address renter, uint256 rentalPeriod);
    event RentalEnded(uint256 rentalId, uint256 tokenId, address renter);
    event FractionalOwnershipCreated(uint256 fractionalId, uint256 tokenId, uint256 totalShares);
    event FractionalShareBought(uint256 fractionalId, uint256 tokenId, address buyer, uint256 numberOfShares);
    event MetadataChangeVoteInitiated(uint256 voteId, uint256 tokenId, string newMetadataURI);
    event MetadataChangeVoteCast(uint256 voteId, address voter, bool vote);
    event MetadataChanged(uint256 tokenId, string newMetadataURI);
    event AICurationScoreSet(uint256 tokenId, uint256 score);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    constructor() payable Ownable() {
        marketplaceFeeRecipient = payable(msg.sender); // Owner initially is fee recipient
    }

    modifier whenNotPaused() {
        require(!isMarketplacePaused, "Marketplace is paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_nftOwners[_tokenId] == msg.sender, "You are not the NFT owner");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 _tokenId) {
        require(_nftOwners[_tokenId] == msg.sender || _nftApprovals[_tokenId] == msg.sender, "Not NFT owner or approved");
        _;
    }

    modifier onlyFractionalOwner(uint256 _fractionalId) {
        require(fractionalOwnerships[_fractionalId].sharesOwned[msg.sender] > 0, "You are not a fractional owner");
        _;
    }


    // ------------------------ NFT Core Functions ------------------------

    /**
     * @dev Mints a new NFT to the specified address with the given metadata URI.
     * @param _to The address to receive the NFT.
     * @param _uri The URI for the NFT metadata.
     */
    function mintNFT(address _to, string memory _uri) public onlyOwner {
        _nftCounter.increment();
        uint256 tokenId = _nftCounter.current();
        _tokenURIs[tokenId] = _uri;
        _nftOwners[tokenId] = _to;
        _userNFTBalance[_to]++;
        emit NFTMinted(tokenId, _to, _uri);
    }

    /**
     * @dev Burns an NFT, removing it from circulation. Only the owner can burn their NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        address owner = _nftOwners[_tokenId];

        delete _tokenURIs[_tokenId];
        delete _nftOwners[_tokenId];
        delete _nftApprovals[_tokenId];
        _userNFTBalance[owner]--;
        emit NFTBurned(_tokenId);
    }

    /**
     * @dev Transfers ownership of an NFT to another address.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public onlyApprovedOrOwner(_tokenId) whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        address from = _nftOwners[_tokenId];
        require(from != _to, "Cannot transfer to self");
        require(_to != address(0), "Cannot transfer to zero address");

        delete _nftApprovals[_tokenId]; // Reset approval on transfer

        _nftOwners[_tokenId] = _to;
        _userNFTBalance[from]--;
        _userNFTBalance[_to]++;
        emit NFTTransferred(_tokenId, from, _to);
    }

    function approve(address _approved, uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        _nftApprovals[_tokenId] = _approved;
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return _nftApprovals[_tokenId];
    }

    function getOwnerOf(uint256 _tokenId) public view returns (address) {
        return _nftOwners[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        return _tokenURIs[_tokenId];
    }

    // ------------------------ Marketplace Listing Functions ------------------------

    /**
     * @dev Lists an NFT for sale in the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in Wei.
     */
    function listItem(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        require(_price > 0, "Price must be greater than zero");
        require(!isNFTListed(_tokenId), "NFT is already listed");

        _listingCounter.increment();
        uint256 listingId = _listingCounter.current();
        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows a user to buy a listed NFT.
     * @param _listingId The ID of the listing to buy.
     */
    function buyItem(uint256 _listingId) public payable whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");
        require(listing.seller != msg.sender, "Cannot buy your own listing");

        uint256 marketplaceFee = listing.price.mul(marketplaceFeePercentage).div(100);
        uint256 sellerProceeds = listing.price.sub(marketplaceFee);

        // Transfer funds
        payable(listing.seller).transfer(sellerProceeds);
        marketplaceFeeRecipient.transfer(marketplaceFee);

        // Transfer NFT ownership
        _nftOwners[listing.tokenId] = msg.sender;
        _userNFTBalance[listing.seller]--;
        _userNFTBalance[msg.sender]++;

        // Deactivate listing
        listing.isActive = false;

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.seller, listing.price);
        emit NFTTransferred(listing.tokenId, listing.seller, msg.sender); // Emit transfer event as well
    }

    /**
     * @dev Allows the seller to cancel a listing.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        require(listings[_listingId].seller == msg.sender, "Only seller can cancel listing");

        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId, listings[_listingId].tokenId);
    }

    /**
     * @dev Updates the price of a listed NFT.
     * @param _listingId The ID of the listing to update.
     * @param _newPrice The new price for the NFT.
     */
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPaused {
        require(listings[_listingId].isActive, "Listing is not active");
        require(listings[_listingId].seller == msg.sender, "Only seller can update listing price");
        require(_newPrice > 0, "Price must be greater than zero");

        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }


    // ------------------------ NFT Rental Functions ------------------------

    /**
     * @dev Allows NFT owners to rent out their NFTs for a specified period.
     * @param _tokenId The ID of the NFT to rent out.
     * @param _rentalPeriod The rental period in blocks (or time units, adjust as needed).
     */
    function rentNFT(uint256 _tokenId, uint256 _rentalPeriod) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        require(_rentalPeriod > 0, "Rental period must be greater than zero");
        require(!isNFTListed(_tokenId), "NFT cannot be rented if listed for sale"); // Prevent listing and renting simultaneously

        _rentalCounter.increment();
        uint256 rentalId = _rentalCounter.current();
        rentals[rentalId] = Rental({
            rentalId: rentalId,
            tokenId: _tokenId,
            owner: msg.sender,
            renter: address(0), // Renter is set when someone rents
            rentalPeriod: _rentalPeriod,
            rentalStartTime: 0, // Start time is set when someone rents
            isActive: false // Initially not rented
        });
        // In a real-world scenario, you would likely need a separate function for someone to *request* a rental and pay a rental fee.
        // For this example, we'll simplify it to just setting up the rental availability.

        emit NFTRented(rentalId, _tokenId, msg.sender, address(0), _rentalPeriod); // Renter is unknown at this point
    }

    /**
     * @dev Allows a user to start renting an available NFT. (Simplified version - more logic needed for real rental process)
     * @param _rentalId The ID of the rental to start.
     */
    function startRental(uint256 _rentalId) public whenNotPaused payable {
        require(rentals[_rentalId].isActive == false, "Rental is already active");
        Rental storage rental = rentals[_rentalId];
        require(rental.owner != msg.sender, "Owner cannot rent their own NFT");
        // Add logic here for rental price, payment, etc. - Simplified for this example

        rental.renter = msg.sender;
        rental.rentalStartTime = block.timestamp; // or block.number for block-based period
        rental.isActive = true;

        emit NFTRented(rental.rentalId, rental.tokenId, rental.owner, msg.sender, rental.rentalPeriod);
    }


    /**
     * @dev Allows renters or owners to end an active NFT rental.
     * @param _rentalId The ID of the rental to end.
     */
    function endRental(uint256 _rentalId) public whenNotPaused {
        require(rentals[_rentalId].isActive, "Rental is not active");
        Rental storage rental = rentals[_rentalId];
        require(rental.renter == msg.sender || rental.owner == msg.sender, "Only renter or owner can end rental");

        rental.isActive = false;
        emit RentalEnded(_rentalId, rental.tokenId, rental.renter);
        // In a real-world scenario, you might need to handle return of rental deposit, etc.
    }


    // ------------------------ Fractional Ownership Functions ------------------------

    /**
     * @dev Creates fractional ownership for an NFT, dividing it into shares.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _numberOfShares The total number of shares to create.
     */
    function createFractionalOwnership(uint256 _tokenId, uint256 _numberOfShares) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        require(_numberOfShares > 0, "Number of shares must be greater than zero");
        require(fractionalOwnerships[0].tokenId != _tokenId, "NFT is already fractionalized"); // Basic check to prevent double fractionalization

        _fractionalCounter.increment();
        uint256 fractionalId = _fractionalCounter.current();
        fractionalOwnerships[fractionalId] = FractionalOwnership({
            fractionalId: fractionalId,
            tokenId: _tokenId,
            totalShares: _numberOfShares,
            sharesOwned: mapping(address => uint256)() // Initialize empty sharesOwned mapping
        });
        fractionalOwnerships[fractionalId].sharesOwned[msg.sender] = _numberOfShares; // Initial creator owns all shares
        fractionalOwners[fractionalId].push(msg.sender); // Add initial owner to owner list

        // Transfer NFT ownership to the fractional contract (or keep track internally)
        // For simplicity, we'll assume ownership is tracked via fractional ownership contract.
        delete _nftOwners[_tokenId]; // NFT is now controlled by fractional ownership
        _userNFTBalance[msg.sender]--; // Reduce balance from original owner

        emit FractionalOwnershipCreated(fractionalId, _tokenId, _numberOfShares);
    }

    /**
     * @dev Allows users to buy fractional shares of an NFT.
     * @param _fractionalId The ID of the fractional ownership setup.
     * @param _numberOfShares The number of shares to buy.
     */
    function buyFractionalShare(uint256 _fractionalId, uint256 _numberOfShares) public payable whenNotPaused {
        require(fractionalOwnerships[_fractionalId].tokenId != 0, "Fractional ownership setup does not exist");
        require(_numberOfShares > 0, "Number of shares to buy must be greater than zero");
        // Add logic for share price calculation and payment. Simplified for this example.

        FractionalOwnership storage fractional = fractionalOwnerships[_fractionalId];
        fractional.sharesOwned[msg.sender] += _numberOfShares;
        bool isNewOwner = true;
        for(uint i=0; i < fractionalOwners[_fractionalId].length; i++) {
            if(fractionalOwners[_fractionalId][i] == msg.sender) {
                isNewOwner = false;
                break;
            }
        }
        if(isNewOwner) {
            fractionalOwners[_fractionalId].push(msg.sender);
        }

        emit FractionalShareBought(_fractionalId, fractional.tokenId, msg.sender, _numberOfShares);
    }

    /**
     * @dev Initiates a vote among fractional owners to change NFT metadata.
     * @param _tokenId The ID of the NFT to vote on metadata change for.
     * @param _newMetadataURI The proposed new metadata URI.
     */
    function voteOnNFTMetadataChange(uint256 _tokenId, string memory _newMetadataURI) public onlyFractionalOwner(0) whenNotPaused { // Assume fractionalId '0' is used for simplicity, adjust as needed
        require(fractionalOwnerships[0].tokenId == _tokenId, "Not a fractionalized NFT or incorrect fractional ID"); // Adjust fractional ID lookup
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty");

        _voteCounter.increment();
        uint256 voteId = _voteCounter.current();
        metadataChangeVotes[voteId] = MetadataChangeVote({
            voteId: voteId,
            tokenId: _tokenId,
            newMetadataURI: _newMetadataURI,
            yesVotes: 0,
            noVotes: 0,
            hasVoted: mapping(address => bool)(),
            isActive: true
        });

        emit MetadataChangeVoteInitiated(voteId, _tokenId, _newMetadataURI);
    }

    /**
     * @dev Allows fractional owners to vote on a metadata change proposal.
     * @param _voteId The ID of the metadata change vote.
     * @param _vote True for yes, false for no.
     */
    function castMetadataChangeVote(uint256 _voteId, bool _vote) public onlyFractionalOwner(0) whenNotPaused { // Assuming fractionalId '0' for simplicity
        require(metadataChangeVotes[_voteId].isActive, "Vote is not active");
        require(!metadataChangeVotes[_voteId].hasVoted[msg.sender], "Already voted");
        require(fractionalOwnerships[0].tokenId == metadataChangeVotes[_voteId].tokenId, "Incorrect fractional ID or token mismatch"); // Adjust fractional ID lookup

        MetadataChangeVote storage vote = metadataChangeVotes[_voteId];
        vote.hasVoted[msg.sender] = true;
        if (_vote) {
            vote.yesVotes++;
        } else {
            vote.noVotes++;
        }
        emit MetadataChangeVoteCast(_voteId, msg.sender, _vote);
    }

    /**
     * @dev Executes a successful metadata change vote if majority vote is reached.
     * @param _tokenId The ID of the NFT for which metadata change was voted upon.
     */
    function executeMetadataChangeVote(uint256 _tokenId) public onlyFractionalOwner(0) whenNotPaused { // Assuming fractionalId '0' for simplicity
        require(fractionalOwnerships[0].tokenId == _tokenId, "Incorrect fractional ID or token mismatch"); // Adjust fractional ID lookup
        uint256 activeVoteId = 0; // In a real scenario, you'd need to track the active vote for the token. Simplified here.
        require(metadataChangeVotes[activeVoteId].isActive, "No active metadata change vote found");
        MetadataChangeVote storage vote = metadataChangeVotes[activeVoteId];

        uint256 totalFractionalOwners = fractionalOwners[0].length; // Assuming fractionalId '0'
        uint256 requiredYesVotes = totalFractionalOwners.div(2).add(1); // Simple majority

        require(vote.yesVotes >= requiredYesVotes, "Vote not passed yet");

        _tokenURIs[_tokenId] = vote.newMetadataURI;
        vote.isActive = false; // End the vote

        emit MetadataChanged(_tokenId, vote.newMetadataURI);
    }


    // ------------------------ AI Curation Functions ------------------------

    /**
     * @dev Allows users to submit an NFT for AI-based curation (simulated off-chain).
     *      In a real application, this would trigger an off-chain process.
     * @param _tokenId The ID of the NFT to submit for AI curation.
     */
    function submitNFTForAICuration(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        // In a real-world scenario, you would:
        // 1. Emit an event containing NFT metadata URI or relevant data.
        // 2. An off-chain service (AI model) would listen for this event.
        // 3. The AI service would process the NFT data, generate a curation score.
        // 4. The AI service or admin would call `setAICurationScore` to update the score on-chain.

        // For this example, we just emit an event to simulate submission.
        // In a real implementation, you would likely pass more data in the event.
        emit AICurationScoreSet(_tokenId, 0); // Placeholder score, actual score set off-chain later
    }

    /**
     * @dev Admin function to set the AI curation score for an NFT.
     *      This would typically be called by an off-chain AI service or admin.
     * @param _tokenId The ID of the NFT to set the score for.
     * @param _score The AI curation score (e.g., 0-100).
     */
    function setAICurationScore(uint256 _tokenId, uint256 _score) public onlyOwner {
        require(_nftOwners[_tokenId] != address(0), "NFT does not exist");
        require(_score <= 100, "AI score cannot exceed 100"); // Example score range

        aiCurationScores[_tokenId] = _score;
        emit AICurationScoreSet(_tokenId, _score);
    }

    /**
     * @dev Retrieves the AI curation score of an NFT.
     * @param _tokenId The ID of the NFT to get the score for.
     * @return The AI curation score.
     */
    function getAICurationScore(uint256 _tokenId) public view returns (uint256) {
        return aiCurationScores[_tokenId];
    }


    // ------------------------ Marketplace Administration Functions ------------------------

    /**
     * @dev Admin function to set the marketplace fee percentage.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 10, "Fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Admin function to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = getContractBalance();
        uint256 withdrawableAmount = balance.sub(contractBalance); // Avoid withdrawing contract's gas reserve if any

        require(withdrawableAmount > 0, "No fees to withdraw");
        marketplaceFeeRecipient.transfer(withdrawableAmount);
        emit MarketplaceFeesWithdrawn(withdrawableAmount);
    }

    /**
     * @dev Admin function to temporarily pause the marketplace.
     */
    function pauseMarketplace() public onlyOwner {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Admin function to resume a paused marketplace.
     */
    function unpauseMarketplace() public onlyOwner {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }


    // ------------------------ Data Retrieval Functions ------------------------

    /**
     * @dev Retrieves details of a specific marketplace listing.
     * @param _listingId The ID of the listing.
     * @return Listing struct containing listing details.
     */
    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Retrieves details of a specific NFT rental.
     * @param _rentalId The ID of the rental.
     * @return Rental struct containing rental details.
     */
    function getRentalDetails(uint256 _rentalId) public view returns (Rental memory) {
        return rentals[_rentalId];
    }

    /**
     * @dev Retrieves details of a specific fractional ownership setup.
     * @param _fractionalId The ID of the fractional ownership.
     * @return FractionalOwnership struct containing fractional ownership details.
     */
    function getFractionalDetails(uint256 _fractionalId) public view returns (FractionalOwnership memory) {
        return fractionalOwnerships[_fractionalId];
    }

    /**
     * @dev Gets the number of NFTs owned by a user.
     * @param _user The address of the user.
     * @return The number of NFTs owned by the user.
     */
    function getUserNFTBalance(address _user) public view returns (uint256) {
        return _userNFTBalance[_user];
    }

    /**
     * @dev Checks if an NFT is currently listed for sale.
     * @param _tokenId The ID of the NFT to check.
     * @return True if listed, false otherwise.
     */
    function isNFTListed(uint256 _tokenId) public view returns (bool) {
        for (uint256 i = 1; i <= _listingCounter.current(); i++) {
            if (listings[i].tokenId == _tokenId && listings[i].isActive) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Gets the contract balance.
     * @return The contract balance in Wei.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to prevent accidental sending of ether to contract.
     */
    fallback() external payable {
        revert("Do not send Ether directly to this contract. Use buyItem function.");
    }

    receive() external payable {
        revert("Do not send Ether directly to this contract. Use buyItem function.");
    }
}
```