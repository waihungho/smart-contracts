```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Decentralized Dynamic Content Platform (DDCP) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Dynamic Content Platform (DDCP) enabling creators to upload, manage, monetize, and dynamically update their digital content (e.g., articles, courses, music, software updates) represented as NFTs.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1.  `createContentNFT(string memory _contentHash, string memory _metadataURI, uint256 _initialPrice)`: Allows creators to mint a new Content NFT with associated content hash, metadata URI, and initial price.
 * 2.  `updateContentHash(uint256 _tokenId, string memory _newContentHash)`: Allows creators to update the content hash associated with their Content NFT, reflecting dynamic content updates.
 * 3.  `setContentMetadataURI(uint256 _tokenId, string memory _newMetadataURI)`: Allows creators to update the metadata URI of their Content NFT.
 * 4.  `setContentPrice(uint256 _tokenId, uint256 _newPrice)`: Allows creators to change the price of their Content NFT.
 * 5.  `purchaseContentNFT(uint256 _tokenId)`: Allows users to purchase a Content NFT at its current price.
 * 6.  `transferContentNFT(address _to, uint256 _tokenId)`: Allows NFT owners to transfer their Content NFT.
 * 7.  `getContentDetails(uint256 _tokenId)`: Retrieves details of a Content NFT, including content hash, metadata URI, price, and creator.
 * 8.  `getContentHash(uint256 _tokenId)`: Retrieves the current content hash of a Content NFT.
 * 9.  `getContentMetadataURI(uint256 _tokenId)`: Retrieves the current metadata URI of a Content NFT.
 * 10. `getContentPrice(uint256 _tokenId)`: Retrieves the current price of a Content NFT.
 * 11. `getContentCreator(uint256 _tokenId)`: Retrieves the original creator of a Content NFT.
 * 12. `getContentOwner(uint256 _tokenId)`: Retrieves the current owner of a Content NFT.
 *
 * **Advanced & Creative Features:**
 * 13. `setContentAccessControl(uint256 _tokenId, bool _restrictedAccess)`: Enables/disables access control for content associated with an NFT. If restricted, only owners can access (off-chain implementation needed for content access).
 * 14. `setContentVersion(uint256 _tokenId, uint256 _version)`: Allows creators to manually set a version number for content, useful for tracking updates.
 * 15. `incrementContentVersion(uint256 _tokenId)`: Automatically increments the content version number when content is updated.
 * 16. `setContentRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Sets a royalty percentage for secondary sales of the Content NFT, distributed to the original creator.
 * 17. `withdrawCreatorEarnings()`: Allows creators to withdraw their accumulated earnings from NFT sales and royalties.
 * 18. `setPlatformFee(uint256 _feePercentage)`: Allows the contract owner to set a platform fee percentage on NFT sales.
 * 19. `setPlatformFeeRecipient(address _recipient)`: Allows the contract owner to set the address to receive platform fees.
 * 20. `pauseContract()`: Allows the contract owner to pause the contract in case of emergency or upgrade.
 * 21. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 22. `burnContentNFT(uint256 _tokenId)`: Allows the current owner to burn (destroy) their Content NFT.
 *
 * **Governance (Optional Extension - Can be built upon):**
 * (Governance features could be added using Governor contracts for community control of platform parameters like platform fees, allowed content types, etc.)
 */
contract DecentralizedDynamicContentPlatform is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to content hash (e.g., IPFS hash, Arweave TX ID)
    mapping(uint256 => string) private _contentHashes;

    // Mapping from token ID to content metadata URI (e.g., link to JSON metadata)
    mapping(uint256 => string) private _contentMetadataURIs;

    // Mapping from token ID to content price (in wei)
    mapping(uint256 => uint256) private _contentPrices;

    // Mapping from token ID to content creator address
    mapping(uint256 => address) private _contentCreators;

    // Mapping from token ID to content version
    mapping(uint256 => uint256) private _contentVersions;

    // Mapping from token ID to royalty percentage (e.g., 500 = 5%)
    mapping(uint256 => uint256) private _contentRoyalties;

    // Mapping to track if content access is restricted for a token
    mapping(uint256 => bool) private _restrictedAccess;

    // Platform fee percentage (e.g., 200 = 2%)
    uint256 public platformFeePercentage = 200; // Default 2% platform fee

    // Address to receive platform fees
    address public platformFeeRecipient;

    // Creator earnings balance
    mapping(address => uint256) private _creatorEarnings;

    event ContentNFTCreated(uint256 tokenId, address creator, string contentHash, string metadataURI, uint256 initialPrice);
    event ContentHashUpdated(uint256 tokenId, string newContentHash);
    event MetadataURIUpdated(uint256 tokenId, string newMetadataURI);
    event ContentPriceUpdated(uint256 tokenId, uint256 newPrice);
    event ContentNFTPurchased(uint256 tokenId, address buyer, address creator, uint256 price, uint256 platformFee);
    event ContentAccessControlUpdated(uint256 tokenId, bool restrictedAccess);
    event ContentVersionUpdated(uint256 tokenId, uint256 version);
    event ContentRoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event CreatorEarningsWithdrawn(address creator, uint256 amount);
    event PlatformFeePercentageUpdated(uint256 newFeePercentage);
    event PlatformFeeRecipientUpdated(address newRecipient);
    event ContentNFTBurned(uint256 tokenId, address owner);


    constructor() ERC721("DynamicContentNFT", "DCNFT") Ownable() {
        platformFeeRecipient = owner(); // Default platform fee recipient is contract owner
    }

    modifier onlyContentCreator(uint256 _tokenId) {
        require(_contentCreators[_tokenId] == _msgSender(), "Caller is not the content creator");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid token ID");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // 1. createContentNFT
    function createContentNFT(
        string memory _contentHash,
        string memory _metadataURI,
        uint256 _initialPrice
    ) external whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _mint(_msgSender(), tokenId);
        _contentHashes[tokenId] = _contentHash;
        _contentMetadataURIs[tokenId] = _metadataURI;
        _contentPrices[tokenId] = _initialPrice;
        _contentCreators[tokenId] = _msgSender();
        _contentVersions[tokenId] = 1; // Initial version is 1
        _contentRoyalties[tokenId] = 0; // Default royalty is 0%
        _restrictedAccess[tokenId] = false; // Default access is not restricted

        emit ContentNFTCreated(tokenId, _msgSender(), _contentHash, _metadataURI, _initialPrice);
        return tokenId;
    }

    // 2. updateContentHash
    function updateContentHash(uint256 _tokenId, string memory _newContentHash)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        _contentHashes[_tokenId] = _newContentHash;
        incrementContentVersion(_tokenId); // Increment version on content update
        emit ContentHashUpdated(_tokenId, _newContentHash);
    }

    // 3. setContentMetadataURI
    function setContentMetadataURI(uint256 _tokenId, string memory _newMetadataURI)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        _contentMetadataURIs[_tokenId] = _newMetadataURI;
        emit MetadataURIUpdated(_tokenId, _newMetadataURI);
    }

    // 4. setContentPrice
    function setContentPrice(uint256 _tokenId, uint256 _newPrice)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        _contentPrices[_tokenId] = _newPrice;
        emit ContentPriceUpdated(_tokenId, _newPrice);
    }

    // 5. purchaseContentNFT
    function purchaseContentNFT(uint256 _tokenId)
        external
        payable
        validTokenId(_tokenId)
        whenNotPaused
    {
        uint256 price = _contentPrices[_tokenId];
        require(msg.value >= price, "Insufficient funds sent");

        uint256 platformFee = price.mul(platformFeePercentage).div(10000); // Calculate platform fee
        uint256 creatorEarning = price.sub(platformFee);

        // Transfer platform fee to platform fee recipient
        payable(platformFeeRecipient).transfer(platformFee);

        // Add creator earning to creator's balance
        _creatorEarnings[_contentCreators[_tokenId]] = _creatorEarnings[_contentCreators[_tokenId]].add(creatorEarning);

        // Transfer NFT to buyer
        _transfer(ownerOf(_tokenId), _msgSender(), _tokenId);

        emit ContentNFTPurchased(_tokenId, _msgSender(), _contentCreators[_tokenId], price, platformFee);
    }

    // 6. transferContentNFT (Standard ERC721 transferFrom is available, but adding explicit name for clarity)
    function transferContentNFT(address _to, uint256 _tokenId)
        external
        whenNotPaused
    {
        transferFrom(_msgSender(), _to, _tokenId);
    }

    // 7. getContentDetails
    function getContentDetails(uint256 _tokenId)
        external
        view
        validTokenId(_tokenId)
        returns (
            string memory contentHash,
            string memory metadataURI,
            uint256 price,
            address creator,
            address owner,
            uint256 version,
            uint256 royaltyPercentage,
            bool restrictedAccess
        )
    {
        contentHash = _contentHashes[_tokenId];
        metadataURI = _contentMetadataURIs[_tokenId];
        price = _contentPrices[_tokenId];
        creator = _contentCreators[_tokenId];
        owner = ownerOf(_tokenId);
        version = _contentVersions[_tokenId];
        royaltyPercentage = _contentRoyalties[_tokenId];
        restrictedAccess = _restrictedAccess[_tokenId];
    }

    // 8. getContentHash
    function getContentHash(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        return _contentHashes[_tokenId];
    }

    // 9. getContentMetadataURI
    function getContentMetadataURI(uint256 _tokenId) external view validTokenId(_tokenId) returns (string memory) {
        return _contentMetadataURIs[_tokenId];
    }

    // 10. getContentPrice
    function getContentPrice(uint256 _tokenId) external view validTokenId(_tokenId) returns (uint256) {
        return _contentPrices[_tokenId];
    }

    // 11. getContentCreator
    function getContentCreator(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return _contentCreators[_tokenId];
    }

    // 12. getContentOwner
    function getContentOwner(uint256 _tokenId) external view validTokenId(_tokenId) returns (address) {
        return ownerOf(_tokenId);
    }

    // 13. setContentAccessControl
    function setContentAccessControl(uint256 _tokenId, bool _restrictedAccess)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        _restrictedAccess[_tokenId] = _restrictedAccess;
        emit ContentAccessControlUpdated(_tokenId, _restrictedAccess);
    }

    // 14. setContentVersion
    function setContentVersion(uint256 _tokenId, uint256 _version)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        _contentVersions[_tokenId] = _version;
        emit ContentVersionUpdated(_tokenId, _version);
    }

    // 15. incrementContentVersion (Internal utility function)
    function incrementContentVersion(uint256 _tokenId) internal validTokenId(_tokenId) {
        _contentVersions[_tokenId] = _contentVersions[_tokenId].add(1);
        emit ContentVersionUpdated(_tokenId, _contentVersions[_tokenId]);
    }

    // 16. setContentRoyalty
    function setContentRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)
        external
        validTokenId(_tokenId)
        onlyContentCreator(_tokenId)
        whenNotPaused
    {
        require(_royaltyPercentage <= 10000, "Royalty percentage cannot exceed 100%"); // Max 100% royalty
        _contentRoyalties[_tokenId] = _royaltyPercentage;
        emit ContentRoyaltySet(_tokenId, _royaltyPercentage);
    }

    // 17. withdrawCreatorEarnings
    function withdrawCreatorEarnings() external whenNotPaused {
        uint256 amount = _creatorEarnings[_msgSender()];
        require(amount > 0, "No earnings to withdraw");
        _creatorEarnings[_msgSender()] = 0; // Reset earnings to 0 after withdrawal
        payable(_msgSender()).transfer(amount);
        emit CreatorEarningsWithdrawn(_msgSender(), amount);
    }

    // 18. setPlatformFee
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 10000, "Platform fee cannot exceed 100%"); // Max 100% platform fee
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageUpdated(_feePercentage);
    }

    // 19. setPlatformFeeRecipient
    function setPlatformFeeRecipient(address _recipient) external onlyOwner whenNotPaused {
        require(_recipient != address(0), "Invalid recipient address");
        platformFeeRecipient = _recipient;
        emit PlatformFeeRecipientUpdated(_recipient);
    }

    // 20. pauseContract
    function pauseContract() external onlyOwner {
        _pause();
    }

    // 21. unpauseContract
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // 22. burnContentNFT
    function burnContentNFT(uint256 _tokenId) external validTokenId(_tokenId) whenNotPaused {
        require(ownerOf(_tokenId) == _msgSender(), "Only owner can burn NFT");
        _burn(_tokenId);
        emit ContentNFTBurned(_tokenId, _msgSender());
    }

    // Override for royalty payments on secondary sales (basic implementation - more complex standards exist)
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);

        if (from != address(0)) { // Not minting
            uint256 royaltyPercentage = _contentRoyalties[tokenId];
            if (royaltyPercentage > 0) {
                uint256 salePrice;
                // In a real marketplace integration, you'd need to get the actual sale price.
                // For simplicity, we'll assume the last set price is the sale price.
                salePrice = _contentPrices[tokenId]; // This is a simplification!

                uint256 royaltyAmount = salePrice.mul(royaltyPercentage).div(10000);
                if (royaltyAmount > 0) {
                    // Add royalty to creator's earnings
                    _creatorEarnings[_contentCreators[tokenId]] = _creatorEarnings[_contentCreators[tokenId]].add(royaltyAmount);
                    // In a real system, you might want to transfer royalties directly at sale time
                    // or have a separate royalty withdrawal mechanism.
                }
            }
        }
    }

    // The following functions are overrides required by Solidity when extending ERC721 and Ownable.
    // They are already implemented in OpenZeppelin contracts and do not need custom logic here.
    // _beforeTokenTransfer, supportsInterface, _approve, _setApprovalForAll, _transfer, approve, getApproved, isApprovedForAll,
    // safeTransferFrom, setApprovalForAll, transferFrom, owner, renounceOwnership, transferOwnership.
}
```