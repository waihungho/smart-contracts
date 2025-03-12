```solidity
/**
 * @title Decentralized Dynamic Art Marketplace - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT art marketplace where art pieces can evolve
 * based on predefined conditions, owner interactions, or external oracles (simulated).
 * This contract is designed to be creative and incorporate advanced concepts while
 * avoiding duplication of common open-source marketplace contracts.
 *
 * **Outline and Function Summary:**
 *
 * **I. Marketplace Core Functions:**
 *   1. `createArtPiece(string _name, string _description, string _initialMetadata)`: Allows artists to create new dynamic art pieces (NFTs).
 *   2. `listArtPiece(uint256 _tokenId, uint256 _price)`: Artists can list their art pieces for sale on the marketplace.
 *   3. `purchaseArtPiece(uint256 _tokenId)`: Buyers can purchase listed art pieces.
 *   4. `delistArtPiece(uint256 _tokenId)`: Artists can remove their art pieces from the marketplace listing.
 *   5. `transferArtPiece(address _to, uint256 _tokenId)`: Standard NFT transfer function.
 *   6. `getArtPieceDetails(uint256 _tokenId)`: Retrieves detailed information about a specific art piece.
 *   7. `getMarketListing(uint256 _tokenId)`: Retrieves listing details for an art piece if it's listed.
 *
 * **II. Dynamic Evolution Functions:**
 *   8. `evolveArtPiece(uint256 _tokenId, uint8 _evolutionType)`: Allows owners to trigger manual evolution of their art piece based on types.
 *   9. `setAutoEvolveSettings(uint256 _tokenId, uint8 _evolutionTriggerType, uint256 _triggerValue)`: Sets up automated evolution rules based on simulated triggers (time, owner interaction count).
 *  10. `manualEvolveArtPiece(uint256 _tokenId, string _newMetadata)`: Allows artist/owner to manually update the art piece metadata (for unique evolutions).
 *  11. `getArtPieceEvolutionState(uint256 _tokenId)`: Retrieves the current evolution state and history of an art piece.
 *  12. `resetArtPieceEvolution(uint256 _tokenId)`: Resets the evolution state of an art piece to its initial state (artist-controlled).
 *
 * **III. Artist and Creator Features:**
 *  13. `registerArtist(string _artistName, string _artistDescription)`: Allows users to register as artists on the platform.
 *  14. `setArtistCommissionRate(uint256 _commissionRate)`: Platform owner can set the commission rate for artists' sales.
 *  15. `withdrawArtistEarnings()`: Artists can withdraw their accumulated earnings from sales.
 *  16. `getArtistProfile(address _artistAddress)`: Retrieves profile information for a registered artist.
 *
 * **IV. Platform Governance and Utility Functions:**
 *  17. `setPlatformFee(uint256 _feePercentage)`: Platform owner can set the marketplace platform fee.
 *  18. `withdrawPlatformFees()`: Platform owner can withdraw accumulated platform fees.
 *  19. `pauseMarketplace()`: Allows the platform owner to pause marketplace functionalities in case of emergency.
 *  20. `unpauseMarketplace()`: Resumes marketplace functionalities after being paused.
 *  21. `setBaseURI(string _baseURI)`: Sets the base URI for retrieving NFT metadata.
 *  22. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 *
 * **V.  Internal Utility Functions (Not directly callable externally, but counted for function count):**
 *  23. `_triggerAutomaticEvolution(uint256 _tokenId)`: Internal function triggered by simulated events to automatically evolve art pieces.
 *  24. `_applyEvolution(uint256 _tokenId, string _newMetadata)`: Internal function to update the metadata and evolution state of an art piece.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChameleonCanvas is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    string private _baseURI;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public artistCommissionRate = 95; // 95% commission for artists

    bool public paused = false;

    // Artist Registration
    mapping(address => ArtistProfile) public artistProfiles;
    struct ArtistProfile {
        string artistName;
        string artistDescription;
        bool isRegistered;
        uint256 earningsBalance;
    }

    // Art Piece Data
    struct ArtPiece {
        string name;
        string description;
        string currentMetadata;
        string initialMetadata;
        address artist;
        uint256 creationTimestamp;
        uint256 evolutionCount;
        mapping(uint8 => EvolutionLog) evolutionHistory; // Evolution type to log
        mapping(uint8 => AutoEvolutionSettings) autoEvolutionSettings;
    }

    struct EvolutionLog {
        uint256 timestamp;
        string metadata;
        uint8 evolutionType; // Type of evolution triggered
    }

    struct AutoEvolutionSettings {
        uint8 triggerType; // 1: Time-based, 2: Owner Interaction Count, etc. (Simulated)
        uint256 triggerValue;
        bool isEnabled;
        uint256 lastTriggerTime; // For time-based triggers
    }

    mapping(uint256 => ArtPiece) public artPieces;

    // Marketplace Listing
    struct MarketListing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => MarketListing) public marketListings;

    event ArtPieceCreated(uint256 tokenId, address artist, string name);
    event ArtPieceListed(uint256 tokenId, uint256 price, address seller);
    event ArtPiecePurchased(uint256 tokenId, address buyer, address seller, uint256 price);
    event ArtPieceDelisted(uint256 tokenId, uint256 price, address seller);
    event ArtPieceEvolved(uint256 tokenId, string newMetadata, uint8 evolutionType);
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistEarningsWithdrawn(address artistAddress, uint256 amount);
    event MarketplacePaused(address admin);
    event MarketplaceUnpaused(address admin);
    event PlatformFeeSet(uint256 feePercentage);


    constructor(string memory _name, string memory _symbol, string memory _baseUri) ERC721(_name, _symbol) {
        _baseURI = _baseUri;
    }

    // ============== I. Marketplace Core Functions ==============

    /**
     * @dev Creates a new dynamic art piece NFT. Only registered artists can create art.
     * @param _name The name of the art piece.
     * @param _description A brief description of the art piece.
     * @param _initialMetadata The initial metadata URI for the art piece.
     */
    function createArtPiece(string memory _name, string memory _description, string memory _initialMetadata) public onlyRegisteredArtist {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        ArtPiece storage newArt = artPieces[tokenId];
        newArt.name = _name;
        newArt.description = _description;
        newArt.currentMetadata = _initialMetadata;
        newArt.initialMetadata = _initialMetadata;
        newArt.artist = _msgSender();
        newArt.creationTimestamp = block.timestamp;
        newArt.evolutionCount = 0;

        _mint(_msgSender(), tokenId);
        emit ArtPieceCreated(tokenId, _msgSender(), _name);
    }

    /**
     * @dev Lists an art piece for sale on the marketplace. Only the art piece owner can list.
     * @param _tokenId The ID of the art piece to list.
     * @param _price The listing price in wei.
     */
    function listArtPiece(uint256 _tokenId, uint256 _price) public isTokenOwner(_tokenId) whenNotPaused {
        require(_price > 0, "Price must be greater than zero.");
        require(!marketListings[_tokenId].isListed, "Art piece already listed.");

        marketListings[_tokenId] = MarketListing({
            price: _price,
            seller: _msgSender(),
            isListed: true
        });
        _approve(address(this), _tokenId); // Approve marketplace to transfer on sale
        emit ArtPieceListed(_tokenId, _price, _msgSender());
    }

    /**
     * @dev Purchases a listed art piece.
     * @param _tokenId The ID of the art piece to purchase.
     */
    function purchaseArtPiece(uint256 _tokenId) public payable whenNotPaused {
        MarketListing storage listing = marketListings[_tokenId];
        require(listing.isListed, "Art piece is not listed for sale.");
        require(msg.value >= listing.price, "Insufficient funds sent.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 artistPayment = listing.price - platformFee;

        // Transfer funds
        payable(owner()).transfer(platformFee); // Platform Fee
        payable(listing.seller).transfer(artistPayment); // Artist Payment

        // Update Artist Earnings
        artistProfiles[listing.seller].earningsBalance += artistPayment;

        // Transfer NFT to buyer
        _transfer(listing.seller, _msgSender(), _tokenId);

        // Reset Listing
        listing.isListed = false;
        delete marketListings[_tokenId]; // Clean up listing data

        emit ArtPiecePurchased(_tokenId, _msgSender(), listing.seller, listing.price);
    }

    /**
     * @dev Delists an art piece from the marketplace. Only the seller can delist.
     * @param _tokenId The ID of the art piece to delist.
     */
    function delistArtPiece(uint256 _tokenId) public isSeller(_tokenId) whenNotPaused {
        require(marketListings[_tokenId].isListed, "Art piece is not listed.");
        marketListings[_tokenId].isListed = false;
        delete marketListings[_tokenId]; // Clean up listing data
        emit ArtPieceDelisted(_tokenId, marketListings[_tokenId].price, _msgSender());
    }

    /**
     * @dev Safely transfers an art piece NFT to another address.
     * @param _to The address to transfer the art piece to.
     * @param _tokenId The ID of the art piece to transfer.
     */
    function transferArtPiece(address _to, uint256 _tokenId) public isTokenOwner(_tokenId) whenNotPaused {
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    /**
     * @dev Retrieves detailed information about a specific art piece.
     * @param _tokenId The ID of the art piece.
     * @return ArtPiece struct containing details.
     */
    function getArtPieceDetails(uint256 _tokenId) public view returns (ArtPiece memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return artPieces[_tokenId];
    }

    /**
     * @dev Retrieves listing details for an art piece if it's listed.
     * @param _tokenId The ID of the art piece.
     * @return MarketListing struct containing listing details, or empty if not listed.
     */
    function getMarketListing(uint256 _tokenId) public view returns (MarketListing memory) {
        return marketListings[_tokenId];
    }


    // ============== II. Dynamic Evolution Functions ==============

    /**
     * @dev Allows the owner to manually trigger evolution of their art piece.
     * @param _tokenId The ID of the art piece to evolve.
     * @param _evolutionType  A code indicating the type of evolution (e.g., 1 for color shift, 2 for texture change - simulated).
     */
    function evolveArtPiece(uint256 _tokenId, uint8 _evolutionType) public isTokenOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");

        // **Simulated Evolution Logic - Replace with actual dynamic logic if needed**
        ArtPiece storage art = artPieces[_tokenId];
        string memory newMetadata;

        if (_evolutionType == 1) {
            newMetadata = string(abi.encodePacked(art.initialMetadata, "?evolution=colorShift&count=", art.evolutionCount.toString())); // Example: Append query params
        } else if (_evolutionType == 2) {
            newMetadata = string(abi.encodePacked(art.initialMetadata, "?evolution=textureChange&count=", art.evolutionCount.toString()));
        } else {
            newMetadata = string(abi.encodePacked(art.initialMetadata, "?evolution=generic&count=", art.evolutionCount.toString()));
        }

        _applyEvolution(_tokenId, newMetadata, _evolutionType);
    }

    /**
     * @dev Allows the owner to manually update the art piece metadata for unique evolutions.
     * @param _tokenId The ID of the art piece.
     * @param _newMetadata The new metadata URI for the art piece.
     */
    function manualEvolveArtPiece(uint256 _tokenId, string memory _newMetadata) public isTokenOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        _applyEvolution(_tokenId, _newMetadata, 0); // 0 indicates manual evolution
    }


    /**
     * @dev Sets up automated evolution rules for an art piece. (Simulated triggers).
     * @param _tokenId The ID of the art piece.
     * @param _evolutionTriggerType Type of trigger (1: Time-based, 2: Owner interaction count - simulated).
     * @param _triggerValue The value for the trigger (e.g., time interval in seconds, interaction count).
     */
    function setAutoEvolveSettings(uint256 _tokenId, uint8 _evolutionTriggerType, uint256 _triggerValue) public isTokenOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(_evolutionTriggerType > 0 && _evolutionTriggerType <= 2, "Invalid trigger type.");

        artPieces[_tokenId].autoEvolutionSettings[_evolutionTriggerType] = AutoEvolutionSettings({
            triggerType: _evolutionTriggerType,
            triggerValue: _triggerValue,
            isEnabled: true,
            lastTriggerTime: block.timestamp // Initial timestamp
        });
    }

    /**
     * @dev Retrieves the current evolution state and history of an art piece.
     * @param _tokenId The ID of the art piece.
     * @return EvolutionLog array representing evolution history.
     */
    function getArtPieceEvolutionState(uint256 _tokenId) public view returns (ArtPiece memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return artPieces[_tokenId]; // Returning the whole ArtPiece struct to access evolution history.
    }

    /**
     * @dev Resets the evolution state of an art piece back to its initial state (Artist controlled, might require artist ownership check in real scenarios).
     * @param _tokenId The ID of the art piece to reset.
     */
    function resetArtPieceEvolution(uint256 _tokenId) public isTokenOwner(_tokenId) whenNotPaused { // In real use-case, might restrict to artist or have more complex logic.
        require(_exists(_tokenId), "Token does not exist.");
        artPieces[_tokenId].currentMetadata = artPieces[_tokenId].initialMetadata;
        artPieces[_tokenId].evolutionCount = 0;
        delete artPieces[_tokenId].evolutionHistory; // Clear evolution history
        emit ArtPieceEvolved(_tokenId, artPieces[_tokenId].currentMetadata, 3); // Evolution type 3: Reset
    }


    // ============== III. Artist and Creator Features ==============

    /**
     * @dev Allows a user to register as an artist on the platform.
     * @param _artistName The name of the artist.
     * @param _artistDescription A description of the artist or their work.
     */
    function registerArtist(string memory _artistName, string memory _artistDescription) public whenNotPaused {
        require(!artistProfiles[_msgSender()].isRegistered, "Already registered as an artist.");
        artistProfiles[_msgSender()] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            isRegistered: true,
            earningsBalance: 0
        });
        emit ArtistRegistered(_msgSender(), _artistName);
    }

    /**
     * @dev Sets the commission rate for artists' sales. Only platform owner can set.
     * @param _commissionRate The commission rate percentage (e.g., 95 for 95%).
     */
    function setArtistCommissionRate(uint256 _commissionRate) public onlyOwner whenNotPaused {
        require(_commissionRate <= 100, "Commission rate cannot exceed 100%.");
        artistCommissionRate = _commissionRate;
    }

    /**
     * @dev Allows artists to withdraw their accumulated earnings.
     */
    function withdrawArtistEarnings() public onlyRegisteredArtist whenNotPaused {
        uint256 amount = artistProfiles[_msgSender()].earningsBalance;
        require(amount > 0, "No earnings to withdraw.");

        artistProfiles[_msgSender()].earningsBalance = 0; // Reset balance after withdrawal
        payable(_msgSender()).transfer(amount);
        emit ArtistEarningsWithdrawn(_msgSender(), amount);
    }

    /**
     * @dev Retrieves profile information for a registered artist.
     * @param _artistAddress The address of the artist.
     * @return ArtistProfile struct containing artist details.
     */
    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }


    // ============== IV. Platform Governance and Utility Functions ==============

    /**
     * @dev Sets the platform fee percentage for marketplace sales. Only platform owner can set.
     * @param _feePercentage The platform fee percentage (e.g., 2 for 2%).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Platform fee cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw.");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Pauses the marketplace functionalities. Only platform owner can pause.
     */
    function pauseMarketplace() public onlyOwner {
        paused = true;
        emit MarketplacePaused(_msgSender());
    }

    /**
     * @dev Resumes marketplace functionalities after being paused. Only platform owner can unpause.
     */
    function unpauseMarketplace() public onlyOwner {
        paused = false;
        emit MarketplaceUnpaused(_msgSender());
    }

    /**
     * @dev Sets the base URI for retrieving NFT metadata.
     * @param _baseURI The new base URI string.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseURI = _baseURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentMetadata = artPieces[tokenId].currentMetadata;
        if (bytes(currentMetadata).length > 0) {
            return currentMetadata; // Use current dynamic metadata if available
        } else {
            return string(abi.encodePacked(_baseURI, tokenId.toString())); // Fallback to base URI + tokenId
        }
    }

    // ============== V. Internal Utility Functions ==============

    /**
     * @dev Internal function to apply evolution changes to an art piece.
     * @param _tokenId The ID of the art piece.
     * @param _newMetadata The new metadata URI.
     * @param _evolutionType The type of evolution applied.
     */
    function _applyEvolution(uint256 _tokenId, string memory _newMetadata, uint8 _evolutionType) internal {
        artPieces[_tokenId].currentMetadata = _newMetadata;
        artPieces[_tokenId].evolutionCount++;
        artPieces[_tokenId].evolutionHistory[artPieces[_tokenId].evolutionCount] = EvolutionLog({
            timestamp: block.timestamp,
            metadata: _newMetadata,
            evolutionType: _evolutionType
        });
        emit ArtPieceEvolved(_tokenId, _newMetadata, _evolutionType);
    }

    /**
     * @dev Internal function to simulate automatic evolution based on triggers (time, owner interaction - simulated).
     *  This would be triggered by an off-chain service in a real application based on events.
     * @param _tokenId The ID of the art piece to potentially evolve.
     */
    function _triggerAutomaticEvolution(uint256 _tokenId) internal {
        if (!_exists(_tokenId)) return; // Token doesn't exist

        ArtPiece storage art = artPieces[_tokenId];

        // Time-based evolution simulation
        if (art.autoEvolutionSettings[1].isEnabled && art.autoEvolutionSettings[1].triggerType == 1) {
            if (block.timestamp >= art.autoEvolutionSettings[1].lastTriggerTime + art.autoEvolutionSettings[1].triggerValue) {
                string memory newMetadata = string(abi.encodePacked(art.initialMetadata, "?autoEvolution=time&count=", art.evolutionCount.toString()));
                _applyEvolution(_tokenId, newMetadata, 4); // Evolution type 4: Auto - Time
                art.autoEvolutionSettings[1].lastTriggerTime = block.timestamp; // Update last trigger time
            }
        }

        // Add other simulated trigger logic here (e.g., owner interaction count) if needed.
    }


    // ============== Modifiers ==============

    modifier onlyRegisteredArtist() {
        require(artistProfiles[_msgSender()].isRegistered, "You are not a registered artist.");
        _;
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "Token does not exist.");
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this art piece.");
        _;
    }

    modifier isSeller(uint256 _tokenId) {
        require(marketListings[_tokenId].isListed, "Art piece is not listed for sale.");
        require(marketListings[_tokenId].seller == _msgSender(), "You are not the seller of this art piece.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Marketplace is currently paused.");
        _;
    }
}
```