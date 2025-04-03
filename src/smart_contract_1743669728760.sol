```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Attribute NFT Marketplace with On-Chain Evolution
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where NFTs have evolving attributes.
 *      This contract introduces the concept of NFTs with attributes that can be upgraded or changed on-chain
 *      through specific interactions, making them dynamic and engaging.
 *
 * Function Summary:
 *
 * **NFT Core Functions:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new DynamicAttributeNFT to the specified address with initial attributes and sets the base URI.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT, with custom logic to preserve attribute history (if needed).
 * 3. `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of an NFT, dynamically generated based on attributes (placeholder - real implementation might be off-chain).
 * 4. `ownerOf(uint256 _tokenId)`: Returns the owner of the specified NFT ID.
 * 5. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on the specified NFT.
 * 6. `getNFTAttribute(uint256 _tokenId, string memory _attributeName)`: Retrieves the current value of a specific attribute for an NFT.
 * 7. `setBaseURI(string memory _newBaseURI)`: Allows the contract owner to update the base URI for metadata.
 *
 * **Dynamic Attribute Evolution Functions:**
 * 8. `evolveAttribute(uint256 _tokenId, string memory _attributeName, uint256 _evolutionPoints)`: Allows the NFT owner to evolve a specific attribute using evolution points.
 * 9. `getAttributeEvolutionCost(uint256 _tokenId, string memory _attributeName, uint256 _evolutionPoints)`: Calculates the cost in ETH to evolve an attribute based on current level and evolution points.
 * 10. `viewAttributeLevel(uint256 _tokenId, string memory _attributeName)`: Returns the current evolution level of a specific attribute.
 * 11. `resetAttribute(uint256 _tokenId, string memory _attributeName)`: Resets a specific attribute of an NFT to its initial state (might have cooldown or cost).
 * 12. `setMaxAttributeLevel(string memory _attributeName, uint256 _maxLevel)`:  Allows the contract owner to set the maximum evolution level for a specific attribute.
 * 13. `getAttributeInitialValue(uint256 _tokenId, string memory _attributeName)`: Returns the initial value of an attribute for an NFT.
 *
 * **Marketplace Listing Functions:**
 * 14. `listItem(uint256 _tokenId, uint256 _price)`: Allows the NFT owner to list their NFT for sale in the marketplace.
 * 15. `buyItem(uint256 _listingId)`: Allows anyone to buy a listed NFT from the marketplace.
 * 16. `cancelListing(uint256 _listingId)`: Allows the NFT owner to cancel their listing from the marketplace.
 * 17. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows the NFT owner to update the price of their listed NFT.
 * 18. `getListing(uint256 _listingId)`: Retrieves details of a specific marketplace listing.
 * 19. `getAllListings()`: Returns a list of all active marketplace listings.
 *
 * **Utility/Admin Functions:**
 * 20. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 21. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 22. `pauseContract()`: Allows the contract owner to pause core functionalities for emergency purposes.
 * 23. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 24. `isContractPaused()`: Returns whether the contract is currently paused.
 */
contract DynamicAttributeNFTMarketplace {
    // --- State Variables ---

    string public name = "DynamicAttributeNFT";
    string public symbol = "DANFT";
    string public baseURI;
    address public owner;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    uint256 private _nextTokenIdCounter;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => mapping(string => uint256)) private _nftAttributes; // tokenId => attributeName => attributeValue
    mapping(uint256 => mapping(string => uint256)) private _initialAttributeValues; // Store initial values
    mapping(string => uint256) private _maxAttributeLevels; // attributeName => maxLevel (optional)
    mapping(uint256 => Listing) public listings; // listingId => Listing details
    uint256 public listingCounter = 0;
    mapping(uint256 => bool) public isListingActive;
    mapping(uint256 => address) public listingSeller; // listingId => seller address

    uint256 public marketplaceFeesCollected;
    bool public contractPaused = false;

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
    }

    // --- Events ---

    event NFTMinted(uint256 tokenId, address to);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event AttributeEvolved(uint256 tokenId, string attributeName, uint256 newValue);
    event AttributeReset(uint256 tokenId, string attributeName);
    event ItemListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event ItemBought(uint256 listingId, uint256 tokenId, uint256 price, address buyer);
    event ListingCancelled(uint256 listingId, uint256 tokenId);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_ownerOf[_tokenId] == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier validListing(uint256 _listingId) {
        require(isListingActive[_listingId], "Listing is not active or does not exist.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _baseTokenURI) {
        owner = msg.sender;
        baseURI = _baseTokenURI;
        _nextTokenIdCounter = 1; // Start token IDs from 1
    }

    // --- NFT Core Functions ---

    /**
     * @dev Mints a new DynamicAttributeNFT to the specified address with initial attributes.
     * @param _to The address to mint the NFT to.
     * @param _baseURI The base URI for the NFT metadata.
     */
    function mintNFT(address _to, string memory _baseURI) public onlyOwner whenNotPaused {
        require(_to != address(0), "Mint to the zero address");
        uint256 tokenId = _nextTokenIdCounter++;
        _balanceOf[_to]++;
        _ownerOf[tokenId] = _to;
        baseURI = _baseURI; // Update base URI if needed on mint (or can have separate admin function)

        // Define initial attributes for the NFT (example - can be customized in a more complex system)
        _initialAttributeValues[tokenId]["Power"] = 10;
        _nftAttributes[tokenId]["Power"] = 10;
        _initialAttributeValues[tokenId]["Speed"] = 5;
        _nftAttributes[tokenId]["Speed"] = 5;
        _initialAttributeValues[tokenId]["Defense"] = 7;
        _nftAttributes[tokenId]["Defense"] = 7;

        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_ownerOf[_tokenId] == _from, "Incorrect from address");
        require(_to != address(0), "Transfer to the zero address");
        require(msg.sender == _from || msg.sender == _tokenApprovals[_tokenId], "Not authorized to transfer");

        _clearApproval(_tokenId); // Clear any approvals
        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        emit NFTTransferred(_tokenId, _from, _to);
    }

    /**
     * @dev Returns the URI for the metadata of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The URI string for the NFT metadata.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        // In a real-world scenario, this might fetch dynamic metadata based on attributes from an off-chain service.
        // For simplicity, this is a placeholder.
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Returns the owner of the specified NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddr = _ownerOf[_tokenId];
        require(ownerAddr != address(0), "Owner query for nonexistent token");
        return ownerAddr;
    }

    /**
     * @dev Approves an address to operate on the specified NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT to be approved for.
     */
    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        address tokenOwner = ownerOf(_tokenId);
        require(msg.sender == tokenOwner, "Approve caller is not owner");
        require(_approved != address(0), "Approve to the zero address");

        _tokenApprovals[_tokenId] = _approved;
    }

    /**
     * @dev Retrieves the current value of a specific attribute for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _attributeName The name of the attribute to retrieve.
     * @return The current value of the attribute.
     */
    function getNFTAttribute(uint256 _tokenId, string memory _attributeName) public view returns (uint256) {
        require(_exists(_tokenId), "Attribute query for nonexistent token");
        return _nftAttributes[_tokenId][_attributeName];
    }

    /**
     * @dev Allows the contract owner to update the base URI for metadata.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner whenNotPaused {
        baseURI = _newBaseURI;
    }

    // --- Dynamic Attribute Evolution Functions ---

    /**
     * @dev Allows the NFT owner to evolve a specific attribute using evolution points (ETH in this example).
     * @param _tokenId The ID of the NFT to evolve.
     * @param _attributeName The name of the attribute to evolve.
     * @param _evolutionPoints The amount of evolution points to apply (in ETH value).
     */
    function evolveAttribute(uint256 _tokenId, string memory _attributeName, uint256 _evolutionPoints) public payable onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "Evolve attribute for nonexistent token");
        require(_evolutionPoints > 0, "Evolution points must be greater than zero");

        uint256 evolutionCost = getAttributeEvolutionCost(_tokenId, _attributeName, _evolutionPoints);
        require(msg.value >= evolutionCost, "Insufficient ETH sent for evolution");

        uint256 currentAttributeLevel = viewAttributeLevel(_tokenId, _attributeName);
        uint256 maxLevel = _maxAttributeLevels[_attributeName];
        if (maxLevel > 0) { // If max level is set
            require(currentAttributeLevel + _evolutionPoints <= maxLevel, "Attribute evolution exceeds maximum level");
        }

        _nftAttributes[_tokenId][_attributeName] += _evolutionPoints; // Simple linear evolution - can be more complex

        // Refund extra ETH if sent
        if (msg.value > evolutionCost) {
            payable(msg.sender).transfer(msg.value - evolutionCost);
        }

        emit AttributeEvolved(_tokenId, _attributeName, _nftAttributes[_tokenId][_attributeName]);
    }

    /**
     * @dev Calculates the cost in ETH to evolve an attribute based on current level and evolution points.
     * @param _tokenId The ID of the NFT.
     * @param _attributeName The name of the attribute.
     * @param _evolutionPoints The amount of evolution points to apply.
     * @return The cost in ETH for evolution.
     */
    function getAttributeEvolutionCost(uint256 _tokenId, string memory _attributeName, uint256 _evolutionPoints) public view returns (uint256) {
        require(_exists(_tokenId), "Cost query for nonexistent token");
        // Example: Cost increases linearly with current level and evolution points
        uint256 currentLevel = viewAttributeLevel(_tokenId, _attributeName);
        return (currentLevel + 1) * _evolutionPoints * 1 gwei; // Example cost function - adjust as needed
    }

    /**
     * @dev Returns the current evolution level (which is currently same as attribute value) of a specific attribute.
     * @param _tokenId The ID of the NFT.
     * @param _attributeName The name of the attribute.
     * @return The current evolution level.
     */
    function viewAttributeLevel(uint256 _tokenId, string memory _attributeName) public view returns (uint256) {
        require(_exists(_tokenId), "Level query for nonexistent token");
        return _nftAttributes[_tokenId][_attributeName]; // In this simple model, level is same as attribute value
    }

    /**
     * @dev Resets a specific attribute of an NFT to its initial state (might have cooldown or cost - not implemented here).
     * @param _tokenId The ID of the NFT to reset.
     * @param _attributeName The name of the attribute to reset.
     */
    function resetAttribute(uint256 _tokenId, string memory _attributeName) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "Reset attribute for nonexistent token");
        _nftAttributes[_tokenId][_attributeName] = _initialAttributeValues[_tokenId][_attributeName]; // Reset to initial value
        emit AttributeReset(_tokenId, _attributeName);
    }

    /**
     * @dev Allows the contract owner to set the maximum evolution level for a specific attribute.
     * @param _attributeName The name of the attribute.
     * @param _maxLevel The maximum level allowed for the attribute.
     */
    function setMaxAttributeLevel(string memory _attributeName, uint256 _maxLevel) public onlyOwner whenNotPaused {
        _maxAttributeLevels[_attributeName] = _maxLevel;
    }

    /**
     * @dev Returns the initial value of an attribute for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _attributeName The name of the attribute.
     * @return The initial value of the attribute.
     */
    function getAttributeInitialValue(uint256 _tokenId, string memory _attributeName) public view returns (uint256) {
        require(_exists(_tokenId), "Initial value query for nonexistent token");
        return _initialAttributeValues[_tokenId][_attributeName];
    }


    // --- Marketplace Listing Functions ---

    /**
     * @dev Allows the NFT owner to list their NFT for sale in the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in Wei to list the NFT for.
     */
    function listItem(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "List item for nonexistent token");
        require(_price > 0, "Price must be greater than zero");
        require(_tokenApprovals[_tokenId] == address(this) || _ownerOf[_tokenId] == msg.sender, "Contract not approved or not owner"); // Allow marketplace contract or owner to list

        uint256 listingId = ++listingCounter;
        listings[listingId] = Listing(_tokenId, _price, msg.sender);
        isListingActive[listingId] = true;
        listingSeller[listingId] = msg.sender;

        // Approve marketplace to transfer the NFT when sold (important for marketplace to work)
        approve(address(this), _tokenId);

        emit ItemListed(listingId, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows anyone to buy a listed NFT from the marketplace.
     * @param _listingId The ID of the listing to buy.
     */
    function buyItem(uint256 _listingId) public payable validListing(_listingId) whenNotPaused {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy item");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        // Transfer NFT from seller to buyer
        transferNFT(seller, msg.sender, tokenId);

        // Transfer funds from buyer to seller (minus marketplace fee)
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee;
        marketplaceFeesCollected += marketplaceFee;

        payable(seller).transfer(sellerPayout);

        // Mark listing as inactive
        isListingActive[_listingId] = false;
        delete listings[_listingId]; // Clean up listing data

        emit ItemBought(_listingId, tokenId, price, msg.sender);
    }

    /**
     * @dev Allows the NFT owner to cancel their listing from the marketplace.
     * @param _listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 _listingId) public validListing(_listingId) onlyNFTOwner(listings[_listingId].tokenId) whenNotPaused {
        require(listingSeller[_listingId] == msg.sender, "You are not the seller of this listing.");

        isListingActive[_listingId] = false;
        delete listings[_listingId]; // Clean up listing data

        emit ListingCancelled(_listingId, listings[_listingId].tokenId);
    }

    /**
     * @dev Allows the NFT owner to update the price of their listed NFT.
     * @param _listingId The ID of the listing to update.
     * @param _newPrice The new price in Wei.
     */
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public validListing(_listingId) onlyNFTOwner(listings[_listingId].tokenId) whenNotPaused {
        require(listingSeller[_listingId] == msg.sender, "You are not the seller of this listing.");
        require(_newPrice > 0, "New price must be greater than zero");

        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }

    /**
     * @dev Retrieves details of a specific marketplace listing.
     * @param _listingId The ID of the listing to retrieve.
     * @return Listing struct containing listing details.
     */
    function getListing(uint256 _listingId) public view validListing(_listingId) returns (Listing memory) {
        return listings[_listingId];
    }

    /**
     * @dev Returns a list of all active marketplace listings.
     * @return Array of Listing structs representing active listings.
     */
    function getAllListings() public view returns (Listing[] memory) {
        Listing[] memory activeListings = new Listing[](listingCounter); // Max possible size
        uint256 listingIndex = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (isListingActive[i]) {
                activeListings[listingIndex++] = listings[i];
            }
        }

        // Resize the array to actual number of active listings
        Listing[] memory finalListings = new Listing[](listingIndex);
        for (uint256 i = 0; i < listingIndex; i++) {
            finalListings[i] = activeListings[i];
        }
        return finalListings;
    }

    // --- Utility/Admin Functions ---

    /**
     * @dev Allows the contract owner to set the marketplace fee percentage.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        uint256 amountToWithdraw = marketplaceFeesCollected;
        marketplaceFeesCollected = 0; // Reset collected fees
        payable(owner).transfer(amountToWithdraw);
        emit MarketplaceFeesWithdrawn(amountToWithdraw, owner);
    }

    /**
     * @dev Allows the contract owner to pause core functionalities for emergency purposes.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused(owner);
    }

    /**
     * @dev Allows the contract owner to unpause the contract.
     */
    function unpauseContract() public onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused(owner);
    }

    /**
     * @dev Returns whether the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return contractPaused;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Checks if a token ID exists.
     * @param _tokenId The ID of the token to check.
     * @return True if the token exists, false otherwise.
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    /**
     * @dev Clears the approval for a token ID.
     * @param _tokenId The ID of the token to clear approval for.
     */
    function _clearApproval(uint256 _tokenId) internal {
        if (_tokenApprovals[_tokenId] != address(0)) {
            delete _tokenApprovals[_tokenId];
        }
    }
}

// --- Helper Library for String Conversions (from OpenZeppelin Contracts) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.5.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```