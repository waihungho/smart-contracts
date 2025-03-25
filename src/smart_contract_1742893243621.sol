```solidity
/**
 * @title Decentralized Dynamic Art Marketplace - "ChronoCanvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT marketplace where art evolves over time,
 *      influenced by on-chain events and artist-defined rules.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1.  `mintDynamicArt(string memory _name, string memory _initialMetadataURI, address[] memory _collaborators)`: Allows artists to mint new dynamic NFTs.
 * 2.  `updateArtMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows artists to update the base metadata URI of their dynamic art.
 * 3.  `transferArtOwnership(uint256 _tokenId, address _newOwner)`: Allows the current owner to transfer ownership of a dynamic NFT.
 * 4.  `listArtForSale(uint256 _tokenId, uint256 _price)`: Allows art owners to list their art for sale in the marketplace.
 * 5.  `unlistArtForSale(uint256 _tokenId)`: Allows art owners to remove their art from sale.
 * 6.  `buyArt(uint256 _tokenId)`: Allows users to purchase art listed for sale.
 * 7.  `setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Allows artists to set a royalty percentage for secondary sales.
 * 8.  `withdrawArtistEarnings()`: Allows artists to withdraw their accumulated earnings from sales and royalties.
 * 9.  `getArtDetails(uint256 _tokenId)`: Retrieves detailed information about a specific dynamic art NFT.
 * 10. `getArtOwner(uint256 _tokenId)`: Retrieves the current owner of a dynamic art NFT.
 * 11. `getArtSalePrice(uint256 _tokenId)`: Retrieves the sale price of a listed art NFT.
 * 12. `isArtListedForSale(uint256 _tokenId)`: Checks if a dynamic art NFT is currently listed for sale.
 *
 * **Dynamic Evolution & Events:**
 * 13. `defineDynamicRule(uint256 _tokenId, string memory _ruleDescription, bytes memory _ruleLogic)`: Allows artists to define rules for their art's evolution based on on-chain events (advanced concept - rule logic is simplified here but could be extended).
 * 14. `triggerArtEvolution(uint256 _tokenId)`: (Internal/Automated) Function triggered by specific on-chain events (simulated here) to potentially evolve the art based on defined rules.
 * 15. `getArtEvolutionHistory(uint256 _tokenId)`: Retrieves the history of evolution events for a specific dynamic art NFT.
 *
 * **Collaboration & Community Features:**
 * 16. `addCollaborator(uint256 _tokenId, address _collaborator)`: Allows the artist to add collaborators to a dynamic art piece.
 * 17. `removeCollaborator(uint256 _tokenId, address _collaborator)`: Allows the artist to remove collaborators.
 * 18. `getArtCollaborators(uint256 _tokenId)`: Retrieves the list of collaborators for a dynamic art piece.
 * 19. `setMarketplaceFee(uint256 _feePercentage)`: Admin function to set the marketplace fee percentage.
 * 20. `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 * 21. `pauseMarketplace()`: Admin function to pause core marketplace functionalities.
 * 22. `unpauseMarketplace()`: Admin function to unpause marketplace functionalities.
 *
 * **Advanced Concepts Demonstrated:**
 * - **Dynamic NFTs:** Art that can evolve and change based on on-chain conditions.
 * - **Rule-Based Evolution:** Artists can define rules governing their art's transformation.
 * - **Collaborative Art Creation:** Support for multiple artists working on a single NFT.
 * - **On-Chain Royalties:** Automated royalty distribution on secondary sales.
 * - **Marketplace with Listing and Buying Features:** Standard marketplace functionalities.
 * - **Admin Controls:** Marketplace fee management and pausing/unpausing.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChronoCanvas is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // Struct to hold dynamic art details
    struct DynamicArt {
        string name;
        string baseMetadataURI;
        address artist;
        uint256 salePrice;
        uint256 royaltyPercentage;
        bool isListedForSale;
        address[] collaborators;
        string[] evolutionHistory; // Simple string log for evolution history
        bytes ruleLogic; // Placeholder for more complex rule logic in future iterations
    }

    mapping(uint256 => DynamicArt) public dynamicArts;
    mapping(uint256 => address) public artOwners;
    mapping(uint256 => uint256) public artRoyalties; // TokenId => Royalty Percentage
    mapping(address => uint256) public artistEarnings;

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address public marketplaceFeeRecipient;

    bool public marketplacePaused = false;

    event ArtMinted(uint256 tokenId, address artist, string name);
    event ArtMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ArtListedForSale(uint256 tokenId, uint256 price);
    event ArtUnlistedFromSale(uint256 tokenId);
    event ArtSold(uint256 tokenId, address buyer, address seller, uint256 price);
    event RoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event CollaboratorAdded(uint256 tokenId, address collaborator);
    event CollaboratorRemoved(uint256 tokenId, address collaborator);
    event ArtEvolved(uint256 tokenId, string evolutionDescription);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address recipient);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);

    constructor(string memory _name, string memory _symbol, address _feeRecipient) ERC721(_name, _symbol) {
        marketplaceFeeRecipient = _feeRecipient;
    }

    modifier onlyArtist(uint256 _tokenId) {
        require(dynamicArts[_tokenId].artist == _msgSender(), "Only the artist can perform this action.");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(artOwners[_tokenId] == _msgSender(), "Only the art owner can perform this action.");
        _;
    }

    modifier onlyCollaborator(uint256 _tokenId) {
        bool isCollaborator = false;
        for (uint i = 0; i < dynamicArts[_tokenId].collaborators.length; i++) {
            if (dynamicArts[_tokenId].collaborators[i] == _msgSender()) {
                isCollaborator = true;
                break;
            }
        }
        require(dynamicArts[_tokenId].artist == _msgSender() || isCollaborator, "Only the artist or a collaborator can perform this action.");
        _;
    }

    modifier whenMarketplaceActive() {
        require(!marketplacePaused, "Marketplace is currently paused.");
        _;
    }

    modifier onlyOwnerOrFeeRecipient() {
        require(_msgSender() == owner() || _msgSender() == marketplaceFeeRecipient, "Only owner or fee recipient can call this function.");
        _;
    }

    // 1. Mint Dynamic Art
    function mintDynamicArt(string memory _name, string memory _initialMetadataURI, address[] memory _collaborators) public whenMarketplaceActive returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        dynamicArts[tokenId] = DynamicArt({
            name: _name,
            baseMetadataURI: _initialMetadataURI,
            artist: _msgSender(),
            salePrice: 0,
            royaltyPercentage: 5, // Default royalty 5%
            isListedForSale: false,
            collaborators: _collaborators,
            evolutionHistory: new string[](0),
            ruleLogic: "" // Placeholder for rule logic
        });
        artOwners[tokenId] = _msgSender();

        _safeMint(_msgSender(), tokenId);
        emit ArtMinted(tokenId, _msgSender(), _name);
        return tokenId;
    }

    // 2. Update Art Metadata
    function updateArtMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyArtist(_tokenId) whenMarketplaceActive {
        dynamicArts[_tokenId].baseMetadataURI = _newMetadataURI;
        emit ArtMetadataUpdated(_tokenId, _newMetadataURI);
    }

    // 3. Transfer Art Ownership
    function transferArtOwnership(uint256 _tokenId, address _newOwner) public onlyArtOwner(_tokenId) whenMarketplaceActive {
        _transfer(artOwners[_tokenId], _newOwner, _tokenId);
        artOwners[_tokenId] = _newOwner;
    }

    // 4. List Art For Sale
    function listArtForSale(uint256 _tokenId, uint256 _price) public onlyArtOwner(_tokenId) whenMarketplaceActive {
        require(_price > 0, "Price must be greater than zero.");
        dynamicArts[_tokenId].salePrice = _price;
        dynamicArts[_tokenId].isListedForSale = true;
        emit ArtListedForSale(_tokenId, _price);
    }

    // 5. Unlist Art For Sale
    function unlistArtForSale(uint256 _tokenId) public onlyArtOwner(_tokenId) whenMarketplaceActive {
        dynamicArts[_tokenId].isListedForSale = false;
        emit ArtUnlistedFromSale(_tokenId);
    }

    // 6. Buy Art
    function buyArt(uint256 _tokenId) public payable whenMarketplaceActive {
        require(dynamicArts[_tokenId].isListedForSale, "Art is not listed for sale.");
        uint256 price = dynamicArts[_tokenId].salePrice;
        require(msg.value >= price, "Insufficient funds sent.");

        address seller = artOwners[_tokenId];

        // Marketplace Fee Calculation
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 artistPayment = price - marketplaceFee;

        // Royalty Calculation
        uint256 royaltyPayment = (price * dynamicArts[_tokenId].royaltyPercentage) / 100;
        artistPayment -= royaltyPayment; // Deduct royalty from artist's payment

        // Transfer funds
        payable(marketplaceFeeRecipient).transfer(marketplaceFee);
        payable(dynamicArts[_tokenId].artist).transfer(royaltyPayment); // Pay royalty to original artist
        payable(seller).transfer(artistPayment); // Pay seller (current owner, might be different from original artist)

        artistEarnings[dynamicArts[_tokenId].artist] += royaltyPayment; // Accumulate artist earnings
        artistEarnings[seller] += artistPayment; // Accumulate seller earnings (if seller is also an artist)

        // Update ownership and sale status
        artOwners[_tokenId] = _msgSender();
        dynamicArts[_tokenId].isListedForSale = false;
        dynamicArts[_tokenId].salePrice = 0;

        _transfer(seller, _msgSender(), _tokenId); // Transfer NFT ownership

        emit ArtSold(_tokenId, _msgSender(), seller, price);
    }

    // 7. Set Royalty Percentage
    function setRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) public onlyArtist(_tokenId) whenMarketplaceActive {
        require(_royaltyPercentage <= 20, "Royalty percentage cannot exceed 20%."); // Example limit
        dynamicArts[_tokenId].royaltyPercentage = _royaltyPercentage;
        emit RoyaltySet(_tokenId, _royaltyPercentage);
    }

    // 8. Withdraw Artist Earnings
    function withdrawArtistEarnings() public whenMarketplaceActive {
        uint256 amount = artistEarnings[_msgSender()];
        require(amount > 0, "No earnings to withdraw.");
        artistEarnings[_msgSender()] = 0; // Reset earnings to 0 after withdrawal
        payable(_msgSender()).transfer(amount);
        emit ArtistEarningsWithdrawn(_msgSender(), amount);
    }

    // 9. Get Art Details
    function getArtDetails(uint256 _tokenId) public view returns (DynamicArt memory) {
        return dynamicArts[_tokenId];
    }

    // 10. Get Art Owner
    function getArtOwner(uint256 _tokenId) public view returns (address) {
        return artOwners[_tokenId];
    }

    // 11. Get Art Sale Price
    function getArtSalePrice(uint256 _tokenId) public view returns (uint256) {
        return dynamicArts[_tokenId].salePrice;
    }

    // 12. Is Art Listed For Sale
    function isArtListedForSale(uint256 _tokenId) public view returns (bool) {
        return dynamicArts[_tokenId].isListedForSale;
    }

    // 13. Define Dynamic Rule (Simplified Example - In real scenario, ruleLogic would be more complex)
    function defineDynamicRule(uint256 _tokenId, string memory _ruleDescription, bytes memory _ruleLogic) public onlyArtist(_tokenId) whenMarketplaceActive {
        dynamicArts[_tokenId].ruleLogic = _ruleLogic; // Store rule logic (simplified bytes for example)
        // In a real application, _ruleLogic could be encoded instructions, pointers to external contracts, etc.
        _logEvolutionEvent(_tokenId, "Dynamic Rule Defined: " + _ruleDescription); // Log rule definition as an evolution event
    }

    // 14. Trigger Art Evolution (Simplified - In real scenario, this would be triggered by external events or oracles)
    function triggerArtEvolution(uint256 _tokenId) public whenMarketplaceActive {
        // Example: Simple time-based evolution - change metadata every 30 days (very basic example)
        uint256 currentTime = block.timestamp;
        uint256 mintTime = block.timestamp; // In reality, you'd need to store mint time or last evolution time
        // For simplicity, we are just using current time as a placeholder - in real scenario you'd need to track actual evolution triggers.

        // Example Rule: If token ID is even, and current second is even, evolve
        if (_tokenId % 2 == 0 && currentTime % 2 == 0) {
            _evolveArt(_tokenId, "Time-Based Evolution - Even Second Trigger");
        } else if (_tokenId % 2 != 0 && currentTime % 2 != 0) {
            _evolveArt(_tokenId, "Time-Based Evolution - Odd Second Trigger");
        }
        // In a real application, this would be triggered by oracles, external events, oracles, or other on-chain conditions
        // and the _ruleLogic would be parsed and executed to determine the evolution.
    }

    // Internal function to evolve art (updates metadata, logs history)
    function _evolveArt(uint256 _tokenId, string memory _reason) internal {
        // Example evolution: Append reason to metadata URI (very simplistic)
        string memory newMetadataURI = string(abi.encodePacked(dynamicArts[_tokenId].baseMetadataURI, "?evolved=", _reason, "&time=", block.timestamp.toString()));
        dynamicArts[_tokenId].baseMetadataURI = newMetadataURI;
        _logEvolutionEvent(_tokenId, _reason);
        emit ArtEvolved(_tokenId, _reason);
        emit ArtMetadataUpdated(_tokenId, newMetadataURI); // Inform metadata update
    }

    // 15. Get Art Evolution History
    function getArtEvolutionHistory(uint256 _tokenId) public view returns (string[] memory) {
        return dynamicArts[_tokenId].evolutionHistory;
    }

    // Internal function to log evolution events
    function _logEvolutionEvent(uint256 _tokenId, string memory _eventDescription) internal {
        dynamicArts[_tokenId].evolutionHistory.push(_eventDescription);
    }

    // 16. Add Collaborator
    function addCollaborator(uint256 _tokenId, address _collaborator) public onlyArtist(_tokenId) whenMarketplaceActive {
        // Check if already a collaborator
        bool alreadyCollaborator = false;
        for (uint i = 0; i < dynamicArts[_tokenId].collaborators.length; i++) {
            if (dynamicArts[_tokenId].collaborators[i] == _collaborator) {
                alreadyCollaborator = true;
                break;
            }
        }
        require(!alreadyCollaborator, "Address is already a collaborator.");
        dynamicArts[_tokenId].collaborators.push(_collaborator);
        emit CollaboratorAdded(_tokenId, _collaborator);
    }

    // 17. Remove Collaborator
    function removeCollaborator(uint256 _tokenId, address _collaborator) public onlyArtist(_tokenId) whenMarketplaceActive {
        bool collaboratorFound = false;
        uint indexToRemove;
        for (uint i = 0; i < dynamicArts[_tokenId].collaborators.length; i++) {
            if (dynamicArts[_tokenId].collaborators[i] == _collaborator) {
                collaboratorFound = true;
                indexToRemove = i;
                break;
            }
        }
        require(collaboratorFound, "Collaborator not found.");

        // Remove collaborator from array (efficient way to remove from array)
        if (indexToRemove < dynamicArts[_tokenId].collaborators.length - 1) {
            dynamicArts[_tokenId].collaborators[indexToRemove] = dynamicArts[_tokenId].collaborators[dynamicArts[_tokenId].collaborators.length - 1];
        }
        dynamicArts[_tokenId].collaborators.pop();
        emit CollaboratorRemoved(_tokenId, _collaborator);
    }

    // 18. Get Art Collaborators
    function getArtCollaborators(uint256 _tokenId) public view returns (address[] memory) {
        return dynamicArts[_tokenId].collaborators;
    }

    // 19. Set Marketplace Fee Percentage (Admin)
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenMarketplaceActive {
        require(_feePercentage <= 10, "Marketplace fee percentage cannot exceed 10%."); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    // 20. Withdraw Marketplace Fees (Admin/Fee Recipient)
    function withdrawMarketplaceFees() public onlyOwnerOrFeeRecipient whenMarketplaceActive {
        uint256 balance = address(this).balance;
        require(balance > 0, "No marketplace fees to withdraw.");
        payable(marketplaceFeeRecipient).transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, marketplaceFeeRecipient);
    }

    // 21. Pause Marketplace (Admin)
    function pauseMarketplace() public onlyOwner {
        marketplacePaused = true;
        emit MarketplacePaused();
    }

    // 22. Unpause Marketplace (Admin)
    function unpauseMarketplace() public onlyOwner {
        marketplacePaused = false;
        emit MarketplaceUnpaused();
    }

    // Override supportsInterface to declare ERC721Metadata extension
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    // Override tokenURI to dynamically construct URI based on current metadata
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return dynamicArts[tokenId].baseMetadataURI; // Return the current base metadata URI
    }
}
```