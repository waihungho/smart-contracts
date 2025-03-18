```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Evolving Traits
 * @author Bard (Example Smart Contract - Educational Purposes)
 * @dev A sophisticated smart contract implementing a dynamic NFT marketplace with integrated AI art generation
 * and evolving NFT traits based on on-chain events and user interactions.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Functionality (NFT & Marketplace):**
 *    - `createAIArtRequest(string _prompt, uint256 _initialPrice)`:  Allows users to request AI art generation with a prompt and set an initial listing price.
 *    - `mintDynamicNFT(uint256 _requestId, string _aiGeneratedImageURI)`: (Callable by authorized AI service - simulated) Mints a Dynamic NFT based on a request and AI-generated image URI.
 *    - `listItem(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 *    - `buyItem(uint256 _listingId)`: Allows users to buy listed NFTs.
 *    - `cancelListing(uint256 _listingId)`: Allows sellers to cancel their NFT listings.
 *    - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows sellers to update the price of their listed NFTs.
 *    - `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 *    - `getAllListings()`: Returns a list of all active marketplace listings.
 *    - `getUserListings(address _user)`: Returns a list of listings created by a specific user.
 *
 * **2. Dynamic NFT Traits & Evolution:**
 *    - `evolveNFTTrait(uint256 _tokenId, string _traitName, string _newValue)`: Allows authorized admin/oracle to evolve a specific NFT trait based on external events.
 *    - `getNFTEvolutionHistory(uint256 _tokenId)`: Retrieves the evolution history of a specific NFT, showing trait changes over time.
 *    - `triggerRandomTraitEvolution(uint256 _tokenId)`: (Example - for demonstrative purposes) Triggers a random trait evolution based on on-chain randomness (using Chainlink VRF or similar in production).
 *
 * **3. AI Art Generation Simulation & Management:**
 *    - `setAIServiceAddress(address _aiServiceAddress)`: Allows contract owner to set the address of the authorized AI service (simulated in this example).
 *    - `getAIArtRequestDetails(uint256 _requestId)`: Retrieves details of a specific AI art request.
 *    - `getAllAIArtRequests()`: Returns a list of all AI art requests.
 *
 * **4. Advanced Marketplace & User Features:**
 *    - `offerBid(uint256 _listingId, uint256 _bidPrice)`: Allows users to place bids on listed NFTs (offer system, not auction).
 *    - `acceptBid(uint256 _bidId)`: Allows sellers to accept a specific bid on their listed NFT.
 *    - `cancelBid(uint256 _bidId)`: Allows bidders to cancel their pending bids.
 *    - `getUserBids(address _user)`: Returns a list of bids placed by a specific user.
 *
 * **5. Utility & Admin Functions:**
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Allows contract owner to set the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Allows contract owner to withdraw accumulated marketplace fees.
 *    - `pauseMarketplace()`:  Allows contract owner to pause marketplace operations in emergency scenarios.
 *    - `unpauseMarketplace()`: Allows contract owner to resume marketplace operations.
 *    - `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // Optional: Royalty Standard

contract DynamicAIArtMarketplace is ERC721, Ownable, IERC2981 { // Implement ERC721, Ownable for admin, and ERC2981 for royalties (optional)
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _requestIdCounter;
    Counters.Counter private _bidIdCounter;

    uint256 public marketplaceFeePercentage = 2; // 2% marketplace fee
    address public aiServiceAddress; // Address authorized to mint NFTs (simulated AI service)
    bool public isMarketplacePaused = false;

    struct AIArtRequest {
        address requester;
        string prompt;
        uint256 initialPrice;
        bool isFulfilled;
        uint256 tokenId; // ID of the minted NFT, if fulfilled
    }

    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    struct NFTTraitEvolution {
        uint256 timestamp;
        string traitName;
        string newValue;
    }

    struct NFTDynamicData {
        string aiArtURI;
        mapping(string => string) currentTraits; // Current traits of the NFT
        NFTTraitEvolution[] evolutionHistory; // History of trait evolutions
    }

    struct Bid {
        uint256 bidId;
        uint256 listingId;
        address bidder;
        uint256 bidPrice;
        bool isActive;
    }

    mapping(uint256 => AIArtRequest) public aiArtRequests;
    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => NFTDynamicData) private _nftDynamicData;
    mapping(uint256 => Bid) public bids;
    mapping(uint256 => uint256) private _tokenListingId; // Token ID to Listing ID mapping for quick lookup
    mapping(uint256 => uint256) private _tokenIdToRequestId; // Token ID to Request ID mapping

    event AIArtRequested(uint256 requestId, address requester, string prompt, uint256 initialPrice);
    event NFTMinted(uint256 tokenId, uint256 requestId, address minter, string tokenURI);
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event NFTTraitEvolved(uint256 tokenId, string traitName, string newValue);
    event BidOffered(uint256 bidId, uint256 listingId, address bidder, uint256 bidPrice);
    event BidAccepted(uint256 bidId, uint256 listingId, address seller, address buyer, uint256 price);
    event BidCancelled(uint256 bidId, uint256 listingId, address bidder);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event FeesWithdrawn(address withdrawer, uint256 amount);

    constructor() ERC721("DynamicAIArtNFT", "DAIANFT") {
        // Initialize contract - Optionally set initial AI service address during deployment
        // setAIServiceAddress(initialAIServiceAddress);
    }

    modifier onlyAIService() {
        require(msg.sender == aiServiceAddress, "Only AI Service can call this function");
        _;
    }

    modifier marketplaceActive() {
        require(!isMarketplacePaused, "Marketplace is currently paused");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(nftListings[_listingId].listingId == _listingId && nftListings[_listingId].isActive, "Listing does not exist or is inactive");
        _;
    }

    modifier bidExists(uint256 _bidId) {
        require(bids[_bidId].bidId == _bidId && bids[_bidId].isActive, "Bid does not exist or is inactive");
        _;
    }

    modifier isListingOwner(uint256 _listingId) {
        require(nftListings[_listingId].seller == msg.sender, "You are not the owner of this listing");
        _;
    }

    modifier isBidOwner(uint256 _bidId) {
        require(bids[_bidId].bidder == msg.sender, "You are not the owner of this bid");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _;
    }

    // ------------------------------------------------------------
    // 1. Core Functionality (NFT & Marketplace)
    // ------------------------------------------------------------

    /// @notice Allows users to request AI art generation with a prompt and set an initial listing price.
    /// @param _prompt The prompt for AI art generation.
    /// @param _initialPrice The initial price to list the NFT for sale after minting. Set to 0 if not listing immediately.
    function createAIArtRequest(string memory _prompt, uint256 _initialPrice) external marketplaceActive {
        uint256 requestId = _requestIdCounter.current();
        aiArtRequests[requestId] = AIArtRequest({
            requester: msg.sender,
            prompt: _prompt,
            initialPrice: _initialPrice,
            isFulfilled: false,
            tokenId: 0 // Initially no token minted
        });
        emit AIArtRequested(requestId, msg.sender, _prompt, _initialPrice);
        _requestIdCounter.increment();
    }

    /// @notice (Callable by authorized AI service - simulated) Mints a Dynamic NFT based on a request and AI-generated image URI.
    /// @param _requestId The ID of the AI art request.
    /// @param _aiGeneratedImageURI The URI of the AI-generated image (e.g., IPFS link).
    function mintDynamicNFT(uint256 _requestId, string memory _aiGeneratedImageURI) external onlyAIService marketplaceActive {
        require(!aiArtRequests[_requestId].isFulfilled, "Request already fulfilled");

        uint256 tokenId = _tokenIdCounter.current();
        _mint(aiArtRequests[_requestId].requester, tokenId);

        _nftDynamicData[tokenId] = NFTDynamicData({
            aiArtURI: _aiGeneratedImageURI
        });
        _tokenIdToRequestId[tokenId] = _requestId; // Map Token ID to Request ID

        aiArtRequests[_requestId].isFulfilled = true;
        aiArtRequests[_requestId].tokenId = tokenId;

        emit NFTMinted(tokenId, _requestId, aiArtRequests[_requestId].requester, _aiGeneratedImageURI);
        _tokenIdCounter.increment();

        // Optionally list the NFT immediately if an initial price was set in the request
        if (aiArtRequests[_requestId].initialPrice > 0) {
            listItem(tokenId, aiArtRequests[_requestId].initialPrice);
        }
    }

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The price to list the NFT for.
    function listItem(uint256 _tokenId, uint256 _price) public marketplaceActive isNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero");
        require(_tokenListingId[_tokenId] == 0 || !nftListings[_tokenListingId[_tokenId]].isActive, "NFT is already listed or listing is active"); // Check if not already listed or existing listing is inactive

        uint256 listingId = _listingIdCounter.current();
        nftListings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        _tokenListingId[_tokenId] = listingId; // Map Token ID to Listing ID

        _approve(address(this), _tokenId); // Approve marketplace to operate on NFT

        emit ItemListed(listingId, _tokenId, msg.sender, _price);
        _listingIdCounter.increment();
    }

    /// @notice Allows users to buy listed NFTs.
    /// @param _listingId The ID of the marketplace listing.
    function buyItem(uint256 _listingId) external payable marketplaceActive listingExists(_listingId) {
        NFTListing storage listing = nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;
        address seller = listing.seller;

        // Transfer NFT to buyer
        _transfer(seller, msg.sender, tokenId);

        // Calculate marketplace fee
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = price - marketplaceFee;

        // Transfer funds to seller (minus fee) and marketplace
        payable(seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee);

        // Deactivate the listing
        listing.isActive = false;
        _tokenListingId[tokenId] = 0; // Remove token ID to listing ID mapping

        emit ItemBought(_listingId, tokenId, msg.sender, price);
    }

    /// @notice Allows sellers to cancel their NFT listings.
    /// @param _listingId The ID of the marketplace listing.
    function cancelListing(uint256 _listingId) external marketplaceActive listingExists(_listingId) isListingOwner(_listingId) {
        NFTListing storage listing = nftListings[_listingId];
        listing.isActive = false;
        _tokenListingId[listing.tokenId] = 0; // Remove token ID to listing ID mapping
        emit ListingCancelled(_listingId, listing.tokenId, msg.sender);
    }

    /// @notice Allows sellers to update the price of their listed NFTs.
    /// @param _listingId The ID of the marketplace listing.
    /// @param _newPrice The new price for the NFT.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) external marketplaceActive listingExists(_listingId) isListingOwner(_listingId) {
        require(_newPrice > 0, "New price must be greater than zero");
        nftListings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, nftListings[_listingId].tokenId, _newPrice);
    }

    /// @notice Retrieves details of a specific marketplace listing.
    /// @param _listingId The ID of the marketplace listing.
    /// @return NFTListing struct containing listing details.
    function getListingDetails(uint256 _listingId) external view listingExists(_listingId) returns (NFTListing memory) {
        return nftListings[_listingId];
    }

    /// @notice Returns a list of all active marketplace listings.
    /// @return An array of NFTListing structs representing active listings.
    function getAllListings() external view returns (NFTListing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        NFTListing[] memory activeListings = new NFTListing[](listingCount);
        uint256 activeListingIndex = 0;
        for (uint256 i = 0; i < listingCount; i++) {
            if (nftListings[i].isActive) {
                activeListings[activeListingIndex] = nftListings[i];
                activeListingIndex++;
            }
        }

        // Resize the array to remove empty slots if needed
        if (activeListingIndex < activeListings.length) {
            NFTListing[] memory resizedListings = new NFTListing[](activeListingIndex);
            for (uint256 i = 0; i < activeListingIndex; i++) {
                resizedListings[i] = activeListings[i];
            }
            return resizedListings;
        } else {
            return activeListings;
        }
    }

    /// @notice Returns a list of listings created by a specific user.
    /// @param _user The address of the user.
    /// @return An array of NFTListing structs representing listings by the user.
    function getUserListings(address _user) external view returns (NFTListing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256 userListingCount = 0;
        for (uint256 i = 0; i < listingCount; i++) {
            if (nftListings[i].seller == _user && nftListings[i].isActive) {
                userListingCount++;
            }
        }

        NFTListing[] memory userListings = new NFTListing[](userListingCount);
        uint256 userListingIndex = 0;
        for (uint256 i = 0; i < listingCount; i++) {
            if (nftListings[i].seller == _user && nftListings[i].isActive) {
                userListings[userListingIndex] = nftListings[i];
                userListingIndex++;
            }
        }
        return userListings;
    }

    // ------------------------------------------------------------
    // 2. Dynamic NFT Traits & Evolution
    // ------------------------------------------------------------

    /// @notice Allows authorized admin/oracle to evolve a specific NFT trait based on external events.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _traitName The name of the trait to evolve.
    /// @param _newValue The new value of the trait.
    function evolveNFTTrait(uint256 _tokenId, string memory _traitName, string memory _newValue) external onlyOwner { // In real-world, this might be an oracle or DAO controlled
        require(_exists(_tokenId), "NFT does not exist");
        _nftDynamicData[_tokenId].currentTraits[_traitName] = _newValue;
        _nftDynamicData[_tokenId].evolutionHistory.push(NFTTraitEvolution({
            timestamp: block.timestamp,
            traitName: _traitName,
            newValue: _newValue
        }));
        emit NFTTraitEvolved(_tokenId, _traitName, _newValue);
    }

    /// @notice Retrieves the evolution history of a specific NFT, showing trait changes over time.
    /// @param _tokenId The ID of the NFT.
    /// @return An array of NFTTraitEvolution structs representing the evolution history.
    function getNFTEvolutionHistory(uint256 _tokenId) external view returns (NFTTraitEvolution[] memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return _nftDynamicData[_tokenId].evolutionHistory;
    }

    /// @notice (Example - for demonstrative purposes) Triggers a random trait evolution based on on-chain randomness (using Chainlink VRF or similar in production).
    /// @param _tokenId The ID of the NFT to evolve.
    function triggerRandomTraitEvolution(uint256 _tokenId) external marketplaceActive isNFTOwner(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");

        // In a real application, use Chainlink VRF or a similar secure randomness source
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenId)));
        uint256 traitIndex = randomValue % 3; // Example: 3 possible traits to evolve

        string memory traitName;
        string memory newValue;

        if (traitIndex == 0) {
            traitName = "Color Palette";
            newValue = _generateRandomColorPalette(); // Example function to generate a random color palette
        } else if (traitIndex == 1) {
            traitName = "Texture Style";
            newValue = _generateRandomTextureStyle(); // Example function to generate a random texture style
        } else {
            traitName = "Background Element";
            newValue = _generateRandomBackgroundElement(); // Example function to generate a random background element
        }

        evolveNFTTrait(_tokenId, traitName, newValue);
    }

    // Example helper functions (replace with actual logic or external calls for real randomness and generation)
    function _generateRandomColorPalette() private pure returns (string memory) {
        // Placeholder - In real app, fetch from external source or use more complex logic
        uint256 randomVal = uint256(keccak256(abi.encodePacked(block.timestamp))) % 3;
        if (randomVal == 0) return "Vibrant Warm Tones";
        if (randomVal == 1) return "Cool Blues and Greens";
        return "Monochromatic Grayscale";
    }

    function _generateRandomTextureStyle() private pure returns (string memory) {
        // Placeholder
        uint256 randomVal = uint256(keccak256(abi.encodePacked(block.timestamp))) % 3;
        if (randomVal == 0) return "Abstract Brushstrokes";
        if (randomVal == 1) return "Geometric Patterns";
        return "Smooth Gradient";
    }

    function _generateRandomBackgroundElement() private pure returns (string memory) {
        // Placeholder
        uint256 randomVal = uint256(keccak256(abi.encodePacked(block.timestamp))) % 3;
        if (randomVal == 0) return "Celestial Nebula";
        if (randomVal == 1) return "Urban Cityscape";
        return "Abstract Shapes";
    }


    // ------------------------------------------------------------
    // 3. AI Art Generation Simulation & Management
    // ------------------------------------------------------------

    /// @notice Allows contract owner to set the address of the authorized AI service (simulated in this example).
    /// @param _aiServiceAddress The address of the authorized AI service contract/EOA.
    function setAIServiceAddress(address _aiServiceAddress) external onlyOwner {
        aiServiceAddress = _aiServiceAddress;
    }

    /// @notice Retrieves details of a specific AI art request.
    /// @param _requestId The ID of the AI art request.
    /// @return AIArtRequest struct containing request details.
    function getAIArtRequestDetails(uint256 _requestId) external view returns (AIArtRequest memory) {
        return aiArtRequests[_requestId];
    }

    /// @notice Returns a list of all AI art requests.
    /// @return An array of AIArtRequest structs representing all requests.
    function getAllAIArtRequests() external view returns (AIArtRequest[] memory) {
        uint256 requestCount = _requestIdCounter.current();
        AIArtRequest[] memory allRequests = new AIArtRequest[](requestCount);
        for (uint256 i = 0; i < requestCount; i++) {
            allRequests[i] = aiArtRequests[i];
        }
        return allRequests;
    }

    // ------------------------------------------------------------
    // 4. Advanced Marketplace & User Features
    // ------------------------------------------------------------

    /// @notice Allows users to place bids on listed NFTs (offer system, not auction).
    /// @param _listingId The ID of the marketplace listing.
    /// @param _bidPrice The price the user is bidding.
    function offerBid(uint256 _listingId, uint256 _bidPrice) external payable marketplaceActive listingExists(_listingId) {
        require(msg.value >= _bidPrice, "Bid price is less than sent value");
        require(nftListings[_listingId].seller != msg.sender, "Cannot bid on your own listing");

        uint256 bidId = _bidIdCounter.current();
        bids[bidId] = Bid({
            bidId: bidId,
            listingId: _listingId,
            bidder: msg.sender,
            bidPrice: _bidPrice,
            isActive: true
        });

        emit BidOffered(bidId, _listingId, msg.sender, _bidPrice);
        _bidIdCounter.increment();
    }

    /// @notice Allows sellers to accept a specific bid on their listed NFT.
    /// @param _bidId The ID of the bid to accept.
    function acceptBid(uint256 _bidId) external marketplaceActive bidExists(_bidId) isListingOwner(bids[_bidId].listingId) {
        Bid storage bid = bids[_bidId];
        require(bid.listingId == nftListings[bid.listingId].listingId, "Bid listing ID mismatch"); // Sanity check
        require(nftListings[bid.listingId].isActive, "Listing is not active");

        uint256 listingId = bid.listingId;
        uint256 tokenId = nftListings[listingId].tokenId;
        uint256 bidPrice = bid.bidPrice;
        address seller = nftListings[listingId].seller;
        address buyer = bid.bidder;

        // Transfer NFT to buyer
        _transfer(seller, buyer, tokenId);

        // Calculate marketplace fee
        uint256 marketplaceFee = (bidPrice * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = bidPrice - marketplaceFee;

        // Transfer funds to seller (minus fee) and marketplace
        payable(seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee);

        // Deactivate the listing and the bid
        nftListings[listingId].isActive = false;
        _tokenListingId[tokenId] = 0; // Remove token ID to listing ID mapping
        bid.isActive = false;

        // Refund other bidders (optional - for more advanced bid system, could keep bids active or have a bid queue)
        _refundOtherBidders(listingId, _bidId);

        emit BidAccepted(_bidId, listingId, seller, buyer, bidPrice);
    }

    function _refundOtherBidders(uint256 _listingId, uint256 _acceptedBidId) private {
        uint256 bidCount = _bidIdCounter.current();
        for (uint256 i = 0; i < bidCount; i++) {
            if (bids[i].isActive && bids[i].listingId == _listingId && i != _acceptedBidId) {
                payable(bids[i].bidder).transfer(bids[i].bidPrice);
                bids[i].isActive = false; // Deactivate other bids for this listing
            }
        }
    }


    /// @notice Allows bidders to cancel their pending bids.
    /// @param _bidId The ID of the bid to cancel.
    function cancelBid(uint256 _bidId) external marketplaceActive bidExists(_bidId) isBidOwner(_bidId) {
        require(bids[_bidId].listingId == nftListings[bids[_bidId].listingId].listingId, "Bid listing ID mismatch"); // Sanity check
        require(nftListings[bids[_bidId].listingId].isActive, "Listing is not active");

        Bid storage bid = bids[_bidId];
        bid.isActive = false;
        payable(bid.bidder).transfer(bid.bidPrice); // Refund the bid amount
        emit BidCancelled(_bidId, bid.listingId, msg.sender);
    }

    /// @notice Returns a list of bids placed by a specific user.
    /// @param _user The address of the user.
    /// @return An array of Bid structs representing bids by the user.
    function getUserBids(address _user) external view returns (Bid[] memory) {
        uint256 bidCount = _bidIdCounter.current();
        uint256 userBidCount = 0;
        for (uint256 i = 0; i < bidCount; i++) {
            if (bids[i].bidder == _user && bids[i].isActive) {
                userBidCount++;
            }
        }

        Bid[] memory userBids = new Bid[](userBidCount);
        uint256 userBidIndex = 0;
        for (uint256 i = 0; i < bidCount; i++) {
            if (bids[i].bidder == _user && bids[i].isActive) {
                userBids[userBidIndex] = bids[i];
                userBidIndex++;
            }
        }
        return userBids;
    }


    // ------------------------------------------------------------
    // 5. Utility & Admin Functions
    // ------------------------------------------------------------

    /// @notice Allows contract owner to set the marketplace fee percentage.
    /// @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /// @notice Allows contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
        emit FeesWithdrawn(owner(), balance);
    }

    /// @notice Allows contract owner to pause marketplace operations in emergency scenarios.
    function pauseMarketplace() external onlyOwner {
        isMarketplacePaused = true;
        emit MarketplacePaused();
    }

    /// @notice Allows contract owner to resume marketplace operations.
    function unpauseMarketplace() external onlyOwner {
        isMarketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    // ------------------------------------------------------------
    // ERC721 Metadata Override (Optional - Customize as needed)
    // ------------------------------------------------------------
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real application, construct a dynamic metadata URI based on _nftDynamicData[_tokenId]
        // and potentially off-chain metadata storage (IPFS, etc.)
        // Example: return string(abi.encodePacked("ipfs://your_base_uri/", _tokenId.toString(), ".json"));

        // For this example, just return the AI generated URI
        return _nftDynamicData[_tokenId].aiArtURI;
    }

    // ------------------------------------------------------------
    // ERC2981 Royalty Support (Optional - Implement if needed)
    // ------------------------------------------------------------
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        // Example: Set a fixed royalty of 5% to the contract owner for all NFTs
        return (owner(), (_salePrice * 5) / 100); // 5% royalty
    }
}
```