```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Artist Integration
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where NFTs can evolve based on predefined rules and integrate with AI artists for unique NFT generation.
 *
 * **Outline:**
 * 1. **NFT Core Functionality:**
 *    - Minting Dynamic NFTs with initial properties.
 *    - Transferring NFTs.
 *    - Getting NFT details.
 *    - Burning NFTs.
 * 2. **Dynamic NFT Evolution:**
 *    - Defining evolution rules based on time or on-chain events.
 *    - Triggering NFT evolution.
 *    - Getting NFT evolution history.
 *    - Pausing/Resuming NFT evolution.
 * 3. **Marketplace Functionality:**
 *    - Listing NFTs for sale.
 *    - Buying NFTs from listings.
 *    - Canceling NFT listings.
 *    - Updating NFT listing price.
 *    - Viewing active listings.
 *    - Filtering listings by NFT properties or evolution stage.
 * 4. **AI Artist Integration:**
 *    - Registering AI Artists (external accounts representing AI services).
 *    - Requesting AI-generated NFT art (using off-chain AI and oracles in practice, simulated here).
 *    - Setting AI Artist royalty percentage.
 *    - Approving/Rejecting AI Artists (governance mechanism).
 *    - Getting AI Artist details.
 * 5. **Governance and Platform Management:**
 *    - Setting platform fees for marketplace transactions.
 *    - Withdrawing platform fees.
 *    - Pausing/Unpausing the entire marketplace.
 *    - Setting allowed NFT contracts for the marketplace.
 * 6. **Utility and Helper Functions:**
 *    - Getting contract balance.
 *    - Getting platform owner.
 *    - Getting current platform fee.
 *
 * **Function Summary:**
 * 1. `mintDynamicNFT(address _to, string memory _initialMetadataURI, uint256[] memory _initialProperties) external`: Mints a new dynamic NFT to a specified address with initial metadata and properties.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId) external`: Transfers an NFT from one address to another, with ownership checks.
 * 3. `getNFTDetails(uint256 _tokenId) external view returns (address owner, string memory metadataURI, uint256[] memory properties, uint256 evolutionStage)`: Retrieves detailed information about a specific NFT.
 * 4. `burnNFT(uint256 _tokenId) external`: Burns (destroys) a specific NFT, removing it from circulation.
 * 5. `defineEvolutionRule(uint256 _tokenId, uint256 _stage, uint256 _timeDelaySeconds, uint256[] memory _propertyChanges) external`: Defines an evolution rule for an NFT, triggered after a time delay.
 * 6. `triggerNFTEvolution(uint256 _tokenId) external`: Manually triggers the evolution of an NFT if conditions are met.
 * 7. `getNFTEvolutionHistory(uint256 _tokenId) external view returns (uint256[] memory evolutionStages, uint256[] memory evolutionTimestamps)`: Retrieves the evolution history of an NFT, showing stages and timestamps.
 * 8. `pauseNFTEvolution(uint256 _tokenId) external`: Pauses the automatic evolution of a specific NFT.
 * 9. `resumeNFTEvolution(uint256 _tokenId) external`: Resumes the automatic evolution of a paused NFT.
 * 10. `listNFTForSale(uint256 _tokenId, uint256 _price) external`: Lists an NFT for sale on the marketplace at a specified price.
 * 11. `buyNFT(uint256 _listingId) payable external`: Buys an NFT listed on the marketplace, paying the listed price plus platform fee.
 * 12. `cancelNFTListing(uint256 _listingId) external`: Cancels an NFT listing from the marketplace.
 * 13. `updateNFTListingPrice(uint256 _listingId, uint256 _newPrice) external`: Updates the price of an NFT listing.
 * 14. `getActiveListings() external view returns (uint256[] memory listingIds)`: Retrieves a list of IDs of all currently active NFT listings.
 * 15. `filterListingsByProperty(uint256 _propertyIndex, uint256 _propertyValue) external view returns (uint256[] memory listingIds)`: Filters active listings to find NFTs with a specific property value at a given index.
 * 16. `registerAIArtist(address _aiArtistAddress, string memory _aiArtistName, uint256 _royaltyPercentage) external`: Registers a new AI Artist with a name and royalty percentage.
 * 17. `requestAIGeneratedArt(uint256 _tokenId, address _aiArtistAddress) external`: Requests AI-generated art for a specific NFT from a registered AI Artist (simulated AI response).
 * 18. `setAIArtistRoyaltyPercentage(address _aiArtistAddress, uint256 _royaltyPercentage) external`: Sets the royalty percentage for a registered AI Artist.
 * 19. `approveAIArtist(address _aiArtistAddress) external`: Approves a registered AI Artist, allowing them to be selected for AI art requests.
 * 20. `rejectAIArtist(address _aiArtistAddress) external`: Rejects a registered AI Artist, preventing them from being selected.
 * 21. `getAIArtistDetails(address _aiArtistAddress) external view returns (string memory aiArtistName, uint256 royaltyPercentage, bool isApproved)`: Retrieves details of a registered AI Artist.
 * 22. `setPlatformFee(uint256 _newFeePercentage) external`: Sets the platform fee percentage for marketplace transactions.
 * 23. `withdrawPlatformFees() external`: Allows the contract owner to withdraw accumulated platform fees.
 * 24. `pauseMarketplace() external`: Pauses all marketplace functionalities.
 * 25. `unpauseMarketplace() external`: Resumes marketplace functionalities after being paused.
 * 26. `setAllowedNFTContract(address _nftContractAddress, bool _isAllowed) external`: Sets whether a specific NFT contract is allowed to be listed on the marketplace.
 * 27. `getContractBalance() external view returns (uint256 balance)`: Gets the current balance of the smart contract.
 * 28. `getPlatformOwner() external view returns (address owner)`: Gets the address of the platform owner.
 * 29. `getCurrentPlatformFee() external view returns (uint256 feePercentage)`: Gets the current platform fee percentage.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;

    // Struct to represent a Dynamic NFT
    struct DynamicNFT {
        string metadataURI;
        uint256[] properties; // Array of properties, can be numbers or enum-like values
        uint256 evolutionStage;
        uint256 lastEvolutionTime;
        bool evolutionPaused;
    }

    // Struct to define NFT evolution rules
    struct EvolutionRule {
        uint256 stage;
        uint256 timeDelaySeconds;
        uint256[] propertyChanges; // Changes to properties at this stage
    }

    // Struct for marketplace listings
    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    // Struct for AI Artist information
    struct AIArtist {
        string name;
        uint256 royaltyPercentage;
        bool isApproved;
    }

    mapping(uint256 => DynamicNFT) public dynamicNFTs;
    mapping(uint256 => EvolutionRule[]) public evolutionRules;
    mapping(uint256 => Listing) public listings;
    mapping(address => AIArtist) public aiArtists;
    mapping(uint256 => uint256[]) public nftEvolutionHistory; // tokenId => array of evolution stages
    mapping(uint256 => uint256[]) public nftEvolutionTimestamps; // tokenId => array of timestamps for evolution

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    bool public marketplacePaused = false;
    mapping(address => bool) public allowedNFTContracts; // Whitelist of allowed NFT contracts on marketplace

    event NFTMinted(uint256 tokenId, address to, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event NFTListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTListingCancelled(uint256 listingId);
    event NFTListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event NFTEvolutionRuleDefined(uint256 tokenId, uint256 stage, uint256 timeDelaySeconds);
    event NFTEvolved(uint256 tokenId, uint256 newStage);
    event NFTEvolutionPaused(uint256 tokenId);
    event NFTEvolutionResumed(uint256 tokenId);
    event AIArtistRegistered(address aiArtistAddress, string aiArtistName);
    event AIArtistRoyaltySet(address aiArtistAddress, uint256 royaltyPercentage);
    event AIArtistApproved(address aiArtistAddress);
    event AIArtistRejected(address aiArtistAddress);
    event PlatformFeeSet(uint256 feePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event AllowedNFTContractSet(address nftContractAddress, bool isAllowed);

    constructor() ERC721("DynamicNFT", "DNFT") Ownable() {
        // Initialize any contract setup here
    }

    modifier onlyMarketplaceActive() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "You are not the NFT owner.");
        _;
    }

    modifier onlyApprovedAIArtist(address _aiArtistAddress) {
        require(aiArtists[_aiArtistAddress].isApproved, "AI Artist is not approved.");
        _;
    }

    // 1. NFT Core Functionality

    /**
     * @dev Mints a new dynamic NFT.
     * @param _to The address to mint the NFT to.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     * @param _initialProperties Initial properties of the NFT.
     */
    function mintDynamicNFT(address _to, string memory _initialMetadataURI, uint256[] memory _initialProperties) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);

        dynamicNFTs[tokenId] = DynamicNFT({
            metadataURI: _initialMetadataURI,
            properties: _initialProperties,
            evolutionStage: 0, // Initial stage
            lastEvolutionTime: block.timestamp,
            evolutionPaused: false
        });

        emit NFTMinted(tokenId, _to, _initialMetadataURI);
    }

    /**
     * @dev Safely transfers an NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        safeTransferFrom(_msgSender(), _to, _tokenId);
        emit NFTTransferred(_tokenId, _msgSender(), _to);
    }

    /**
     * @dev Gets details of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return owner The owner of the NFT.
     * @return metadataURI The metadata URI of the NFT.
     * @return properties The current properties of the NFT.
     * @return evolutionStage The current evolution stage of the NFT.
     */
    function getNFTDetails(uint256 _tokenId) external view returns (address owner, string memory metadataURI, uint256[] memory properties, uint256 evolutionStage) {
        owner = ERC721.ownerOf(_tokenId);
        metadataURI = dynamicNFTs[_tokenId].metadataURI;
        properties = dynamicNFTs[_tokenId].properties;
        evolutionStage = dynamicNFTs[_tokenId].evolutionStage;
    }

    /**
     * @dev Burns (destroys) an NFT.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        _burn(_tokenId);
        delete dynamicNFTs[_tokenId]; // Clean up dynamic NFT data
        emit NFTBurned(_tokenId);
    }

    // 2. Dynamic NFT Evolution

    /**
     * @dev Defines an evolution rule for an NFT at a specific stage.
     * @param _tokenId The ID of the NFT.
     * @param _stage The evolution stage number.
     * @param _timeDelaySeconds Time delay in seconds before this stage can be reached.
     * @param _propertyChanges Array of property changes to apply at this stage.
     */
    function defineEvolutionRule(uint256 _tokenId, uint256 _stage, uint256 _timeDelaySeconds, uint256[] memory _propertyChanges) external onlyOwner {
        evolutionRules[_tokenId].push(EvolutionRule({
            stage: _stage,
            timeDelaySeconds: _timeDelaySeconds,
            propertyChanges: _propertyChanges
        }));
        emit NFTEvolutionRuleDefined(_tokenId, _stage, _timeDelaySeconds);
    }

    /**
     * @dev Triggers the evolution of an NFT if conditions are met (time elapsed and not paused).
     * @param _tokenId The ID of the NFT to evolve.
     */
    function triggerNFTEvolution(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        require(!dynamicNFTs[_tokenId].evolutionPaused, "Evolution is paused for this NFT.");

        uint256 currentStage = dynamicNFTs[_tokenId].evolutionStage;
        EvolutionRule[] memory rules = evolutionRules[_tokenId];

        for (uint256 i = 0; i < rules.length; i++) {
            if (rules[i].stage == currentStage + 1) { // Check for the next stage
                if (block.timestamp >= dynamicNFTs[_tokenId].lastEvolutionTime + rules[i].timeDelaySeconds) {
                    dynamicNFTs[_tokenId].evolutionStage = rules[i].stage;
                    dynamicNFTs[_tokenId].properties = rules[i].propertyChanges; // Apply property changes
                    dynamicNFTs[_tokenId].lastEvolutionTime = block.timestamp;

                    nftEvolutionHistory[_tokenId].push(rules[i].stage);
                    nftEvolutionTimestamps[_tokenId].push(block.timestamp);

                    emit NFTEvolved(_tokenId, rules[i].stage);
                    return; // Evolved to the next stage, exit function
                }
            }
        }
        // If no evolution rule met for the next stage, nothing happens.
    }

    /**
     * @dev Gets the evolution history of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return evolutionStages Array of evolution stages reached.
     * @return evolutionTimestamps Array of timestamps when each stage was reached.
     */
    function getNFTEvolutionHistory(uint256 _tokenId) external view returns (uint256[] memory evolutionStages, uint256[] memory evolutionTimestamps) {
        evolutionStages = nftEvolutionHistory[_tokenId];
        evolutionTimestamps = nftEvolutionTimestamps[_tokenId];
    }

    /**
     * @dev Pauses the automatic evolution of an NFT.
     * @param _tokenId The ID of the NFT.
     */
    function pauseNFTEvolution(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].evolutionPaused = true;
        emit NFTEvolutionPaused(_tokenId);
    }

    /**
     * @dev Resumes the automatic evolution of a paused NFT.
     * @param _tokenId The ID of the NFT.
     */
    function resumeNFTEvolution(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        dynamicNFTs[_tokenId].evolutionPaused = false;
        emit NFTEvolutionResumed(_tokenId);
    }


    // 3. Marketplace Functionality

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei for which the NFT is listed.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) onlyMarketplaceActive {
        require(allowedNFTContracts[address(this)], "NFT contract is not allowed on this marketplace."); // Ensure this contract's NFTs are allowed
        require(listings[_tokenId].isActive == false, "NFT is already listed for sale.");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();
        listings[listingId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: _msgSender(),
            isActive: true
        });
        _approve(address(this), _tokenId); // Approve marketplace to handle transfer
        emit NFTListed(listingId, _tokenId, _price, _msgSender());
    }

    /**
     * @dev Buys an NFT from the marketplace listing.
     * @param _listingId The ID of the listing to buy.
     */
    function buyNFT(uint256 _listingId) payable external onlyMarketplaceActive {
        require(listings[_listingId].isActive, "Listing is not active.");
        require(listings[_listingId].seller != _msgSender(), "Seller cannot buy their own NFT.");
        require(msg.value >= listings[_listingId].price + (listings[_listingId].price * platformFeePercentage / 100), "Insufficient funds sent.");

        uint256 tokenId = listings[_listingId].tokenId;
        uint256 price = listings[_listingId].price;
        address seller = listings[_listingId].seller;

        listings[_listingId].isActive = false; // Deactivate listing
        _transfer(seller, _msgSender(), tokenId); // Transfer NFT to buyer

        // Transfer funds: Seller gets price, platform gets fee
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerPayout = price; // For simplicity, assuming all to seller after fee. Can be split further for AI artist royalties.

        payable(owner()).transfer(platformFee); // Transfer platform fee to owner
        payable(seller).transfer(sellerPayout); // Transfer price to seller

        emit NFTBought(_listingId, tokenId, _msgSender(), seller, price);
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelNFTListing(uint256 _listingId) external onlyMarketplaceActive {
        require(listings[_listingId].isActive, "Listing is not active.");
        require(listings[_listingId].seller == _msgSender(), "Only seller can cancel listing.");

        listings[_listingId].isActive = false;
        emit NFTListingCancelled(_listingId);
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _listingId The ID of the listing to update.
     * @param _newPrice The new price in wei.
     */
    function updateNFTListingPrice(uint256 _listingId, uint256 _newPrice) external onlyMarketplaceActive {
        require(listings[_listingId].isActive, "Listing is not active.");
        require(listings[_listingId].seller == _msgSender(), "Only seller can update listing price.");

        listings[_listingId].price = _newPrice;
        emit NFTListingPriceUpdated(_listingId, _newPrice);
    }

    /**
     * @dev Gets a list of active listing IDs.
     * @return listingIds Array of active listing IDs.
     */
    function getActiveListings() external view onlyMarketplaceActive returns (uint256[] memory listingIds) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _listingIdCounter.current(); i++) {
            if (listings[i].isActive) {
                count++;
            }
        }
        listingIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _listingIdCounter.current(); i++) {
            if (listings[i].isActive) {
                listingIds[index++] = i;
            }
        }
        return listingIds;
    }

    /**
     * @dev Filters active listings by a specific NFT property.
     * @param _propertyIndex The index of the property to filter by.
     * @param _propertyValue The value of the property to filter for.
     * @return listingIds Array of listing IDs matching the property filter.
     */
    function filterListingsByProperty(uint256 _propertyIndex, uint256 _propertyValue) external view onlyMarketplaceActive returns (uint256[] memory listingIds) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _listingIdCounter.current(); i++) {
            if (listings[i].isActive && dynamicNFTs[listings[i].tokenId].properties.length > _propertyIndex && dynamicNFTs[listings[i].tokenId].properties[_propertyIndex] == _propertyValue) {
                count++;
            }
        }
        listingIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= _listingIdCounter.current(); i++) {
            if (listings[i].isActive && dynamicNFTs[listings[i].tokenId].properties.length > _propertyIndex && dynamicNFTs[listings[i].tokenId].properties[_propertyIndex] == _propertyValue) {
                listingIds[index++] = i;
            }
        }
        return listingIds;
    }


    // 4. AI Artist Integration

    /**
     * @dev Registers a new AI Artist.
     * @param _aiArtistAddress The address representing the AI Artist (could be a contract or EO).
     * @param _aiArtistName The name of the AI Artist.
     * @param _royaltyPercentage The royalty percentage for the AI Artist.
     */
    function registerAIArtist(address _aiArtistAddress, string memory _aiArtistName, uint256 _royaltyPercentage) external onlyOwner {
        require(aiArtists[_aiArtistAddress].name == "", "AI Artist already registered."); // Prevent re-registration
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%.");

        aiArtists[_aiArtistAddress] = AIArtist({
            name: _aiArtistName,
            royaltyPercentage: _royaltyPercentage,
            isApproved: false // Initially not approved, needs admin approval
        });
        emit AIArtistRegistered(_aiArtistAddress, _aiArtistName);
    }

    /**
     * @dev Requests AI-generated art for an NFT from a registered AI Artist.
     * @param _tokenId The ID of the NFT for which art is requested.
     * @param _aiArtistAddress The address of the AI Artist to request from.
     *
     * @dev **Note:** In a real-world scenario, this would trigger an off-chain process involving an oracle
     *      to interact with the AI Artist service and update the NFT's metadataURI with AI-generated art.
     *      For this example, we are simulating a successful AI art generation by updating metadata.
     */
    function requestAIGeneratedArt(uint256 _tokenId, address _aiArtistAddress) external onlyNFTOwner(_tokenId) onlyApprovedAIArtist(_aiArtistAddress) {
        // In a real implementation:
        // 1. Emit an event to trigger an off-chain oracle service.
        // 2. The oracle service calls the AI Artist (off-chain).
        // 3. AI Artist generates art based on NFT properties or other context.
        // 4. Oracle service updates the NFT's metadataURI in this contract via a callback function.

        // Simulation: For demonstration, we just update the metadataURI directly.
        string memory simulatedAIArtURI = string(abi.encodePacked("ipfs://simulated-ai-art/", _tokenId.toString()));
        dynamicNFTs[_tokenId].metadataURI = simulatedAIArtURI;

        // In a real scenario, royalty handling for AI Artists would be implemented upon NFT sale.
        // For simplicity in this example, royalty is only set but not automatically distributed on sales.

        // Optionally, emit an event indicating AI art requested and (simulated) updated.
        // event AIArtRequested(uint256 tokenId, address aiArtistAddress, string newMetadataURI);
        // emit AIArtRequested(_tokenId, _aiArtistAddress, simulatedAIArtURI);
    }

    /**
     * @dev Sets the royalty percentage for a registered AI Artist.
     * @param _aiArtistAddress The address of the AI Artist.
     * @param _royaltyPercentage The new royalty percentage.
     */
    function setAIArtistRoyaltyPercentage(address _aiArtistAddress, uint256 _royaltyPercentage) external onlyOwner {
        require(aiArtists[_aiArtistAddress].name != "", "AI Artist not registered.");
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%.");

        aiArtists[_aiArtistAddress].royaltyPercentage = _royaltyPercentage;
        emit AIArtistRoyaltySet(_aiArtistAddress, _royaltyPercentage);
    }

    /**
     * @dev Approves a registered AI Artist.
     * @param _aiArtistAddress The address of the AI Artist to approve.
     */
    function approveAIArtist(address _aiArtistAddress) external onlyOwner {
        require(aiArtists[_aiArtistAddress].name != "", "AI Artist not registered.");
        aiArtists[_aiArtistAddress].isApproved = true;
        emit AIArtistApproved(_aiArtistAddress);
    }

    /**
     * @dev Rejects a registered AI Artist.
     * @param _aiArtistAddress The address of the AI Artist to reject.
     */
    function rejectAIArtist(address _aiArtistAddress) external onlyOwner {
        require(aiArtists[_aiArtistAddress].name != "", "AI Artist not registered.");
        aiArtists[_aiArtistAddress].isApproved = false;
        emit AIArtistRejected(_aiArtistAddress);
    }

    /**
     * @dev Gets details of a registered AI Artist.
     * @param _aiArtistAddress The address of the AI Artist.
     * @return aiArtistName The name of the AI Artist.
     * @return royaltyPercentage The royalty percentage of the AI Artist.
     * @return isApproved Whether the AI Artist is approved.
     */
    function getAIArtistDetails(address _aiArtistAddress) external view returns (string memory aiArtistName, uint256 royaltyPercentage, bool isApproved) {
        aiArtistName = aiArtists[_aiArtistAddress].name;
        royaltyPercentage = aiArtists[_aiArtistAddress].royaltyPercentage;
        isApproved = aiArtists[_aiArtistAddress].isApproved;
    }


    // 5. Governance and Platform Management

    /**
     * @dev Sets the platform fee percentage for marketplace transactions.
     * @param _newFeePercentage The new platform fee percentage.
     */
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Pauses the entire marketplace.
     */
    function pauseMarketplace() external onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace.
     */
    function unpauseMarketplace() external onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Sets whether a specific NFT contract is allowed to be listed on the marketplace.
     * @param _nftContractAddress The address of the NFT contract.
     * @param _isAllowed True if allowed, false if not.
     */
    function setAllowedNFTContract(address _nftContractAddress, bool _isAllowed) external onlyOwner {
        allowedNFTContracts[_nftContractAddress] = _isAllowed;
        emit AllowedNFTContractSet(_nftContractAddress, _isAllowed);
    }


    // 6. Utility and Helper Functions

    /**
     * @dev Gets the contract's ETH balance.
     * @return balance The contract's ETH balance.
     */
    function getContractBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
    }

    /**
     * @dev Gets the platform owner address.
     * @return owner The address of the platform owner.
     */
    function getPlatformOwner() external view returns (address owner) {
        owner = owner();
    }

    /**
     * @dev Gets the current platform fee percentage.
     * @return feePercentage The current platform fee percentage.
     */
    function getCurrentPlatformFee() external view returns (uint256 feePercentage) {
        feePercentage = platformFeePercentage;
    }

    // Override supportsInterface to declare ERC721 interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```