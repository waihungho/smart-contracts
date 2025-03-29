```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Marketplace - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where content (represented by NFTs) can dynamically change based on various on-chain and off-chain factors.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `createContentNFT(string memory _contentURI, string memory _initialMetadataURI, uint256 _initialPrice)`: Allows creators to mint a "Chameleon Canvas" NFT with initial content, metadata, and price.
 * 2. `purchaseContentNFT(uint256 _tokenId)`: Allows users to purchase a Chameleon Canvas NFT.
 * 3. `setContentMetadataUpdater(uint256 _tokenId, address _updaterContract)`: Allows the NFT owner to set a smart contract that can dynamically update the content URI and metadata URI of the NFT.
 * 4. `updateContentDynamically(uint256 _tokenId)`: (Callable only by the designated updater contract) Triggers the content and metadata update logic.
 * 5. `setBasePrice(uint256 _tokenId, uint256 _newPrice)`: Allows the NFT owner to set a new base price for the NFT.
 * 6. `listForSale(uint256 _tokenId)`: Allows the NFT owner to list their NFT for sale at the current base price.
 * 7. `unlistFromSale(uint256 _tokenId)`: Allows the NFT owner to unlist their NFT from sale.
 * 8. `buyListedNFT(uint256 _tokenId)`: Allows users to buy a listed NFT.
 * 9. `transferNFT(address _to, uint256 _tokenId)`: Allows the NFT owner to transfer their NFT (with restrictions if listed for sale).
 *
 * **Advanced Features & Governance:**
 * 10. `setContentUpdateCriteria(uint256 _tokenId, bytes memory _criteria)`: Allows the NFT owner to set custom criteria (encoded data) that the updater contract can use to determine content updates.
 * 11. `getContentUpdateCriteria(uint256 _tokenId) view returns (bytes memory)`: Allows anyone to view the content update criteria for an NFT.
 * 12. `setRoyaltyRecipient(uint256 _tokenId, address _recipient)`: Allows the creator to set a royalty recipient for secondary sales.
 * 13. `setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage)`: Allows the creator to set a royalty percentage (up to a limit).
 * 14. `getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) view returns (address recipient, uint256 royaltyAmount)`: Returns royalty information for a given sale price.
 * 15. `pauseContract()`: Allows the contract owner to pause core functionalities.
 * 16. `unpauseContract()`: Allows the contract owner to unpause core functionalities.
 * 17. `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * 18. `setPlatformFeePercentage(uint256 _percentage)`: Allows the contract owner to set the platform fee percentage on sales.
 * 19. `getContentOwner(uint256 _tokenId) view returns (address)`:  Returns the current owner of the content NFT (distinct from standard ERC721 owner if needed).
 * 20. `getNFTListingDetails(uint256 _tokenId) view returns (bool isListed, uint256 listPrice)`: Returns listing details for an NFT if it is listed for sale.
 * 21. `cancelContentMetadataUpdater(uint256 _tokenId)`: Allows the NFT owner to remove the content metadata updater contract, reverting to static content.
 * 22. `supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)`:  Standard ERC721 interface support.
 */

contract ChameleonCanvas {
    // --- State Variables ---
    string public name = "Chameleon Canvas";
    string public symbol = "CCANVAS";

    address public owner;
    bool public paused;
    uint256 public platformFeePercentage = 2; // 2% platform fee

    uint256 public nextTokenId = 1;
    mapping(uint256 => address) public contentOwners; // Track content owner (can be different from ERC721 owner in advanced use cases)
    mapping(uint256 => string) public contentURIs;
    mapping(uint256 => string) public metadataURIs;
    mapping(uint256 => uint256) public basePrices;
    mapping(uint256 => bool) public isListedForSale;
    mapping(uint256 => address) public contentMetadataUpdaters;
    mapping(uint256 => bytes) public contentUpdateCriteria;
    mapping(uint256 => address) public royaltyRecipients;
    mapping(uint256 => uint256) public royaltyPercentages;
    mapping(uint256 => uint256) public listPrices; // Price at which NFT is listed for sale

    uint256 public platformFeesCollected;

    // --- Events ---
    event ContentNFTCreated(uint256 tokenId, address creator, string contentURI, string metadataURI, uint256 initialPrice);
    event ContentNFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event ContentMetadataUpdaterSet(uint256 tokenId, address updaterContract);
    event ContentUpdatedDynamically(uint256 tokenId, string newContentURI, string newMetadataURI);
    event BasePriceSet(uint256 tokenId, uint256 newPrice);
    event NFTListedForSale(uint256 tokenId, uint256 price);
    event NFTUnlistedFromSale(uint256 tokenId);
    event ListedNFTBought(uint256 tokenId, address buyer, uint256 price);
    event PlatformFeePercentageSet(uint256 percentage);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event RoyaltyRecipientSet(uint256 tokenId, address recipient);
    event RoyaltyPercentageSet(uint256 tokenId, uint256 percentage);
    event ContentMetadataUpdaterCancelled(uint256 tokenId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
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

    modifier onlyContentOwner(uint256 _tokenId) {
        require(contentOwners[_tokenId] == msg.sender, "Only content owner can call this function.");
        _;
    }

    modifier onlyUpdaterContract(uint256 _tokenId) {
        require(contentMetadataUpdaters[_tokenId] == msg.sender, "Only designated updater contract can call this function.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
    }

    // --- Core Functionality ---

    /// @notice Creates a new Chameleon Canvas NFT.
    /// @param _contentURI URI pointing to the initial content of the NFT.
    /// @param _initialMetadataURI URI pointing to the initial metadata of the NFT.
    /// @param _initialPrice Initial base price for the NFT.
    function createContentNFT(string memory _contentURI, string memory _initialMetadataURI, uint256 _initialPrice) public whenNotPaused {
        uint256 tokenId = nextTokenId++;
        contentOwners[tokenId] = msg.sender;
        contentURIs[tokenId] = _contentURI;
        metadataURIs[tokenId] = _initialMetadataURI;
        basePrices[tokenId] = _initialPrice;
        emit ContentNFTCreated(tokenId, msg.sender, _contentURI, _initialMetadataURI, _initialPrice);
    }

    /// @notice Allows a user to purchase a Chameleon Canvas NFT directly from the creator at the base price.
    /// @param _tokenId ID of the NFT to purchase.
    function purchaseContentNFT(uint256 _tokenId) public payable whenNotPaused {
        require(contentOwners[_tokenId] != address(0), "NFT does not exist.");
        require(!isListedForSale[_tokenId], "NFT is currently listed for sale. Buy from listing.");
        uint256 price = basePrices[_tokenId];
        require(msg.value >= price, "Insufficient funds sent.");

        _processPurchase(_tokenId, msg.sender, price);
    }


    /// @notice Sets a smart contract address that is authorized to dynamically update the content and metadata of the NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _updaterContract Address of the smart contract that will update the content.
    function setContentMetadataUpdater(uint256 _tokenId, address _updaterContract) public onlyContentOwner(_tokenId) whenNotPaused {
        require(_updaterContract != address(0), "Updater contract address cannot be zero.");
        contentMetadataUpdaters[_tokenId] = _updaterContract;
        emit ContentMetadataUpdaterSet(_tokenId, _updaterContract);
    }

    /// @notice Allows the content owner to cancel the content metadata updater and revert to static content.
    /// @param _tokenId ID of the NFT.
    function cancelContentMetadataUpdater(uint256 _tokenId) public onlyContentOwner(_tokenId) whenNotPaused {
        delete contentMetadataUpdaters[_tokenId];
        delete contentUpdateCriteria[_tokenId]; // Optionally clear criteria as well
        emit ContentMetadataUpdaterCancelled(_tokenId);
    }


    /// @notice Function callable only by the designated updater contract to dynamically update the content and metadata.
    /// @dev The updater contract should implement logic to determine the new content and metadata URIs based on on-chain or off-chain factors and `contentUpdateCriteria`.
    /// @param _tokenId ID of the NFT to update.
    function updateContentDynamically(uint256 _tokenId) public onlyUpdaterContract(_tokenId) whenNotPaused {
        // In a real implementation, the updater contract would have logic to fetch new content and metadata URIs.
        // This is a placeholder example.
        string memory newContentURI = string(abi.encodePacked(contentURIs[_tokenId], "?updated=", block.timestamp)); // Example: Append timestamp for demonstration.
        string memory newMetadataURI = string(abi.encodePacked(metadataURIs[_tokenId], "?updated=", block.timestamp)); // Example: Append timestamp for demonstration.

        contentURIs[_tokenId] = newContentURI;
        metadataURIs[_tokenId] = newMetadataURI;
        emit ContentUpdatedDynamically(_tokenId, newContentURI, newMetadataURI);
    }

    /// @notice Sets a new base price for the NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _newPrice The new base price.
    function setBasePrice(uint256 _tokenId, uint256 _newPrice) public onlyContentOwner(_tokenId) whenNotPaused {
        basePrices[_tokenId] = _newPrice;
        emit BasePriceSet(_tokenId, _newPrice);
    }

    /// @notice Lists an NFT for sale at its current base price.
    /// @param _tokenId ID of the NFT to list.
    function listForSale(uint256 _tokenId) public onlyContentOwner(_tokenId) whenNotPaused {
        require(!isListedForSale[_tokenId], "NFT is already listed for sale.");
        isListedForSale[_tokenId] = true;
        listPrices[_tokenId] = basePrices[_tokenId]; // List at the current base price initially. Owner can change later.
        emit NFTListedForSale(_tokenId, listPrices[_tokenId]);
    }

    /// @notice Unlists an NFT from sale.
    /// @param _tokenId ID of the NFT to unlist.
    function unlistFromSale(uint256 _tokenId) public onlyContentOwner(_tokenId) whenNotPaused {
        require(isListedForSale[_tokenId], "NFT is not listed for sale.");
        isListedForSale[_tokenId] = false;
        delete listPrices[_tokenId]; // Clean up listing price
        emit NFTUnlistedFromSale(_tokenId);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// @param _tokenId ID of the listed NFT.
    function buyListedNFT(uint256 _tokenId) public payable whenNotPaused {
        require(contentOwners[_tokenId] != address(0), "NFT does not exist.");
        require(isListedForSale[_tokenId], "NFT is not listed for sale.");
        uint256 price = listPrices[_tokenId];
        require(msg.value >= price, "Insufficient funds sent.");

        _processPurchase(_tokenId, msg.sender, price);
        isListedForSale[_tokenId] = false; // Unlist after purchase
        delete listPrices[_tokenId];
        emit ListedNFTBought(_tokenId, msg.sender, price);
    }

    /// @notice Transfers the NFT to another address. Restrictions apply if listed for sale.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public onlyContentOwner(_tokenId) whenNotPaused {
        require(_to != address(0), "Cannot transfer to zero address.");
        require(!isListedForSale[_tokenId], "Cannot transfer NFT while it is listed for sale. Unlist first.");

        address previousOwner = contentOwners[_tokenId];
        contentOwners[_tokenId] = _to;
        // Consider adding ERC721-like transfer event if needed for more standard NFT behavior.
    }


    // --- Advanced Features & Governance ---

    /// @notice Sets custom criteria for content updates. This data is passed to the updater contract.
    /// @param _tokenId ID of the NFT.
    /// @param _criteria Byte data representing the criteria for content updates.  The interpretation of this data is up to the updater contract.
    function setContentUpdateCriteria(uint256 _tokenId, bytes memory _criteria) public onlyContentOwner(_tokenId) whenNotPaused {
        contentUpdateCriteria[_tokenId] = _criteria;
    }

    /// @notice Gets the content update criteria for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return bytes The content update criteria.
    function getContentUpdateCriteria(uint256 _tokenId) public view returns (bytes memory) {
        return contentUpdateCriteria[_tokenId];
    }

    /// @notice Sets the royalty recipient for secondary sales of the NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _recipient Address to receive royalties.
    function setRoyaltyRecipient(uint256 _tokenId, address _recipient) public onlyContentOwner(_tokenId) whenNotPaused {
        royaltyRecipients[_tokenId] = _recipient;
        emit RoyaltyRecipientSet(_tokenId, _recipient);
    }

    /// @notice Sets the royalty percentage for secondary sales of the NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _percentage Royalty percentage (e.g., 500 for 5%). Max 1000 (10%).
    function setRoyaltyPercentage(uint256 _tokenId, uint256 _percentage) public onlyContentOwner(_tokenId) whenNotPaused {
        require(_percentage <= 1000, "Royalty percentage cannot exceed 10%.");
        royaltyPercentages[_tokenId] = _percentage;
        emit RoyaltyPercentageSet(_tokenId, _percentage);
    }

    /// @notice Gets royalty information for a given sale price.
    /// @param _tokenId ID of the NFT.
    /// @param _salePrice Sale price of the NFT.
    /// @return recipient Address of the royalty recipient.
    /// @return royaltyAmount Amount of royalty to be paid.
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address recipient, uint256 royaltyAmount) {
        recipient = royaltyRecipients[_tokenId];
        uint256 percentage = royaltyPercentages[_tokenId];
        royaltyAmount = (_salePrice * percentage) / 10000; // Calculate royalty amount (percentage out of 10000 represents percentage out of 100)
        return (recipient, royaltyAmount);
    }


    // --- Admin Functions ---

    /// @notice Pauses the contract, preventing core functionalities from being used.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
    }

    /// @notice Unpauses the contract, restoring core functionalities.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = platformFeesCollected;
        platformFeesCollected = 0;
        payable(owner).transfer(amount);
        emit PlatformFeesWithdrawn(amount, owner);
    }

    /// @notice Sets the platform fee percentage for sales.
    /// @param _percentage New platform fee percentage (e.g., 200 for 2%). Max 1000 (10%).
    function setPlatformFeePercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 1000, "Platform fee percentage cannot exceed 10%.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    // --- Getter Functions ---

    /// @notice Gets the current content owner of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return address The content owner address.
    function getContentOwner(uint256 _tokenId) public view returns (address) {
        return contentOwners[_tokenId];
    }

    /// @notice Gets the listing details for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return isListed Whether the NFT is listed for sale.
    /// @return listPrice The listed price (0 if not listed).
    function getNFTListingDetails(uint256 _tokenId) public view returns (bool isListed, uint256 listPrice) {
        return (isListedForSale[_tokenId], listPrices[_tokenId]);
    }

    // --- Internal Functions ---

    /// @dev Internal function to process a purchase, handle platform fees, and royalties.
    /// @param _tokenId ID of the NFT being purchased.
    /// @param _buyer Address of the buyer.
    /// @param _price Purchase price.
    function _processPurchase(uint256 _tokenId, address _buyer, uint256 _price) internal {
        address previousOwner = contentOwners[_tokenId];
        contentOwners[_tokenId] = _buyer;

        // Platform Fee Calculation and Transfer
        uint256 platformFeeAmount = (_price * platformFeePercentage) / 10000;
        platformFeesCollected += platformFeeAmount;
        uint256 creatorProceeds = _price - platformFeeAmount;

        // Royalty Calculation and Transfer
        (address royaltyRecipient, uint256 royaltyAmount) = getRoyaltyInfo(_tokenId, creatorProceeds);
        uint256 sellerProceeds = creatorProceeds - royaltyAmount;

        // Transfer Funds
        if (royaltyRecipient != address(0) && royaltyAmount > 0) {
            payable(royaltyRecipient).transfer(royaltyAmount);
        }
        payable(previousOwner).transfer(sellerProceeds);

        emit ContentNFTPurchased(_tokenId, _buyer, _price);
    }


    // --- ERC721 Interface Support (Minimal - can be expanded if needed) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x80ac58cd; // ERC721 interface ID
    }
}
```