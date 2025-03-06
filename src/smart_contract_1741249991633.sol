```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Curator
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace that incorporates AI-driven curation.
 *
 * Function Summary:
 *
 * **Core Marketplace Functions:**
 * 1. `mintNFT(string memory _uri, string memory _initialDynamicData)`: Mints a new Dynamic NFT with initial URI and dynamic data.
 * 2. `listNFT(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * 3. `buyNFT(uint256 _listingId)`: Allows anyone to buy a listed NFT.
 * 4. `delistNFT(uint256 _listingId)`: Owner can delist their NFT from the marketplace.
 * 5. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Owner can update the price of their listed NFT.
 * 6. `transferNFT(address _to, uint256 _tokenId)`: Allows NFT owners to transfer their NFTs. (Standard ERC721 transferFrom wrapped for clarity).
 * 7. `getNFTDetails(uint256 _tokenId)`: Retrieves details of a specific NFT including owner and dynamic data.
 * 8. `getListingDetails(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 * 9. `getAllListings()`: Returns a list of all active NFT listings in the marketplace.
 * 10. `getUserListings(address _user)`: Returns a list of listings created by a specific user.
 *
 * **Dynamic NFT Features:**
 * 11. `updateDynamicData(uint256 _tokenId, string memory _newDynamicData)`: Allows the NFT owner to update the dynamic data associated with their NFT.
 * 12. `getDynamicData(uint256 _tokenId)`: Retrieves the dynamic data associated with an NFT.
 * 13. `setDynamicLogicContract(address _dynamicLogicContract)`: Allows the contract owner to set a Dynamic Logic Contract address (for advanced dynamic behavior - external contract interaction).
 * 14. `triggerDynamicUpdate(uint256 _tokenId)`: Allows authorized entities (like oracles or dynamic logic contract) to trigger a dynamic update for an NFT based on external events.
 *
 * **AI Curation & Recommendation Features:**
 * 15. `requestAICuration(uint256 _tokenId)`: Allows NFT owner to request AI curation for their NFT (triggers off-chain AI process - oracle interaction needed).
 * 16. `receiveAICurationResult(uint256 _tokenId, string memory _aiCurationData)`: Function for an authorized AI oracle to submit curation data for an NFT.
 * 17. `getAICurationData(uint256 _tokenId)`: Retrieves the AI curation data associated with an NFT.
 * 18. `setCuratorFee(uint256 _fee)`: Contract owner can set the fee for AI curation requests.
 * 19. `withdrawCuratorFees()`: Contract owner can withdraw accumulated curator fees.
 *
 * **Admin & Utility Functions:**
 * 20. `setMarketplaceFee(uint256 _fee)`: Contract owner can set the marketplace fee percentage.
 * 21. `withdrawMarketplaceFees()`: Contract owner can withdraw accumulated marketplace fees.
 * 22. `pauseMarketplace()`: Contract owner can pause the marketplace for emergency situations.
 * 23. `unpauseMarketplace()`: Contract owner can unpause the marketplace.
 * 24. `setAIOracleAddress(address _oracleAddress)`: Contract owner sets the authorized address for the AI oracle.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplaceAICurator is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;

    // Marketplace Fee (percentage, e.g., 200 for 2%)
    uint256 public marketplaceFeePercentage = 200;
    uint256 public curatorFee = 0.01 ether; // Fee for AI curation, set in ether

    // Mapping from tokenId to NFT details
    struct NFTDetails {
        address owner;
        string tokenURI;
        string dynamicData;
        string aiCurationData;
    }
    mapping(uint256 => NFTDetails) public nftDetails;

    // Listing structure
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public tokenIdToListingId; // For quick lookup from tokenId to listingId

    // Dynamic Logic Contract Address (Optional, for external dynamic logic)
    address public dynamicLogicContract;

    // Authorized AI Oracle Address
    address public aiOracleAddress;

    // Event declarations
    event NFTMinted(uint256 tokenId, address owner, string tokenURI);
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTDelisted(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event DynamicDataUpdated(uint256 tokenId, string newDynamicData);
    event AICurationRequested(uint256 tokenId, address requester);
    event AICurationReceived(uint256 tokenId, string curationData, address curator);

    constructor() ERC721("DynamicNFT", "DNFT") {}

    modifier whenNotPausedOrOwner() {
        require(!paused() || msg.sender == owner(), "Pausable: Contract is paused");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(listings[_listingId].seller == msg.sender, "You are not the seller of this listing");
        _;
    }

    // --------------------------------------------------
    // Core Marketplace Functions
    // --------------------------------------------------

    function mintNFT(string memory _uri, string memory _initialDynamicData) public whenNotPausedOrOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);

        nftDetails[tokenId] = NFTDetails({
            owner: msg.sender,
            tokenURI: _uri,
            dynamicData: _initialDynamicData,
            aiCurationData: "" // Initially no curation data
        });

        emit NFTMinted(tokenId, msg.sender, _uri);
        return tokenId;
    }

    function listNFT(uint256 _tokenId, uint256 _price) public whenNotPausedOrOwner onlyNFTOwner(_tokenId) {
        require(getApproved(_tokenId) == address(this) || ownerOf(_tokenId) == msg.sender, "NFT not approved for marketplace or not owner");
        require(listings[tokenIdToListingId[_tokenId]].isActive == false, "NFT is already listed or in another listing"); // Prevent double listing

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        tokenIdToListingId[_tokenId] = listingId; // Store mapping from tokenId to listingId

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    function buyNFT(uint256 _listingId) public payable whenNotPausedOrOwner {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 10000; // Calculate fee
        uint256 sellerProceeds = listing.price - marketplaceFee;

        // Transfer NFT to buyer
        _transfer(listing.seller, msg.sender, listing.tokenId);
        nftDetails[listing.tokenId].owner = msg.sender; // Update owner in NFT details

        // Transfer proceeds to seller and marketplace fee to contract owner
        payable(listing.seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee);

        // Deactivate listing
        listing.isActive = false;
        delete tokenIdToListingId[listing.tokenId]; // Clear tokenId to listingId mapping

        emit NFTBought(_listingId, listing.tokenId, msg.sender, listing.seller, listing.price);

        // Refund any extra ETH sent
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    function delistNFT(uint256 _listingId) public whenNotPausedOrOwner onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");

        listing.isActive = false;
        delete tokenIdToListingId[listing.tokenId]; // Clear tokenId to listingId mapping

        emit NFTDelisted(_listingId, listing.tokenId);
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPausedOrOwner onlyListingSeller(_listingId) {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "Listing is not active");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, listing.tokenId, _newPrice);
    }

    function transferNFT(address _to, uint256 _tokenId) public whenNotPausedOrOwner onlyNFTOwner(_tokenId) {
        require(listings[tokenIdToListingId[_tokenId]].isActive == false, "NFT is currently listed, delist first to transfer");
        safeTransferFrom(msg.sender, _to, _tokenId);
        nftDetails[_tokenId].owner = _to; // Update owner in NFT details
    }

    function getNFTDetails(uint256 _tokenId) public view returns (NFTDetails memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftDetails[_tokenId];
    }

    function getListingDetails(uint256 _listingId) public view returns (Listing memory) {
        require(listings[_listingId].listingId != 0, "Listing does not exist"); // Check if listingId is initialized
        return listings[_listingId];
    }

    function getAllListings() public view returns (Listing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256 activeListingCount = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListingCount++;
            }
        }

        Listing[] memory activeListings = new Listing[](activeListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListings[index] = listings[i];
                index++;
            }
        }
        return activeListings;
    }

    function getUserListings(address _user) public view returns (Listing[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256 userListingCount = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive && listings[i].seller == _user) {
                userListingCount++;
            }
        }

        Listing[] memory userListings = new Listing[](userListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive && listings[i].seller == _user) {
                userListings[index] = listings[i];
                index++;
            }
        }
        return userListings;
    }


    // --------------------------------------------------
    // Dynamic NFT Features
    // --------------------------------------------------

    function updateDynamicData(uint256 _tokenId, string memory _newDynamicData) public whenNotPausedOrOwner onlyNFTOwner(_tokenId) {
        nftDetails[_tokenId].dynamicData = _newDynamicData;
        emit DynamicDataUpdated(_tokenId, _newDynamicData);
    }

    function getDynamicData(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftDetails[_tokenId].dynamicData;
    }

    function setDynamicLogicContract(address _dynamicLogicContract) public onlyOwner {
        dynamicLogicContract = _dynamicLogicContract;
    }

    function triggerDynamicUpdate(uint256 _tokenId) public whenNotPausedOrOwner {
        // Example: Simple time-based dynamic update trigger (more complex logic can be in external contract)
        // In a real-world scenario, this might be triggered by an oracle or external event based on _dynamicLogicContract
        // This is a placeholder for more complex dynamic logic.
        nftDetails[_tokenId].dynamicData = string(abi.encodePacked("Updated at time: ", block.timestamp)); // Example update
        emit DynamicDataUpdated(_tokenId, nftDetails[_tokenId].dynamicData);
    }


    // --------------------------------------------------
    // AI Curation & Recommendation Features
    // --------------------------------------------------

    function requestAICuration(uint256 _tokenId) public payable whenNotPausedOrOwner onlyNFTOwner(_tokenId) {
        require(msg.value >= curatorFee, "Insufficient curator fee");
        payable(owner()).transfer(curatorFee); // Transfer curator fee to contract owner
        emit AICurationRequested(_tokenId, msg.sender);
        // In a real application, this would trigger an off-chain process to call the AI oracle.
        // The AI oracle would then call `receiveAICurationResult`.
    }

    function receiveAICurationResult(uint256 _tokenId, string memory _aiCurationData) public onlyAIOracle {
        nftDetails[_tokenId].aiCurationData = _aiCurationData;
        emit AICurationReceived(_tokenId, _aiCurationData, msg.sender);
    }

    function getAICurationData(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftDetails[_tokenId].aiCurationData;
    }

    function setCuratorFee(uint256 _fee) public onlyOwner {
        curatorFee = _fee;
    }

    function withdrawCuratorFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance); // Withdraw all contract balance, including curator fees.
    }


    // --------------------------------------------------
    // Admin & Utility Functions
    // --------------------------------------------------

    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Max 100% fee
        marketplaceFeePercentage = _feePercentage;
    }

    function withdrawMarketplaceFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance); // Withdraw all contract balance, including marketplace fees.
    }

    function pauseMarketplace() public onlyOwner {
        _pause();
    }

    function unpauseMarketplace() public onlyOwner {
        _unpause();
    }

    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        aiOracleAddress = _oracleAddress;
    }

    // Override supportsInterface to declare support for ERC721Metadata
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // The URI for each token is derived from the base URI and the token ID.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return nftDetails[tokenId].tokenURI; // Directly using stored URI in NFTDetails
    }

    // Function to set the base URI (if you want a common base for all NFTs - optional for this contract as URIs are set on mint)
    // function setBaseURI(string memory _baseURI) public onlyOwner {
    //     _baseURI = _baseURI; // Not used directly in tokenURI now, but could be adapted
    // }
}
```