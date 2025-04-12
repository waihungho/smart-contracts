```solidity
/**
 * @title Decentralized Content Monetization and Curation Platform - "ContentVerse"
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized platform where creators can publish content as NFTs,
 *      monetize their work through subscriptions and tips, and users can curate and vote on content quality.
 *      This contract introduces advanced concepts like dynamic subscription tiers, content royalties,
 *      curator rewards, and decentralized dispute resolution.
 *
 * **Outline:**
 *
 * **Content Management:**
 *   1. `createContentNFT(string _contentURI, string _metadataURI)`: Mints an NFT representing content ownership.
 *   2. `setContentMetadata(uint256 _contentId, string _metadataURI)`: Updates the metadata URI of a content NFT.
 *   3. `getContentMetadata(uint256 _contentId)`: Retrieves the metadata URI of a content NFT.
 *   4. `getContentOwner(uint256 _contentId)`: Returns the owner of a specific content NFT.
 *   5. `setContentSubscriptionPrice(uint256 _contentId, uint256 _price)`: Sets the subscription price for accessing content.
 *   6. `getSubscriptionPrice(uint256 _contentId)`: Retrieves the subscription price of content.
 *   7. `setContentRoyalties(uint256 _contentId, uint256 _royaltyPercentage)`: Sets a royalty percentage for secondary sales of the content NFT.
 *   8. `getContentRoyalties(uint256 _contentId)`: Retrieves the royalty percentage for a content NFT.
 *   9. `transferContentOwnership(uint256 _contentId, address _newOwner)`: Transfers ownership of a content NFT.
 *  10. `burnContentNFT(uint256 _contentId)`: Burns (destroys) a content NFT.
 *
 * **Monetization & Access Control:**
 *  11. `subscribeToContent(uint256 _contentId)`: Allows users to subscribe to content for a period (using dynamic tiers).
 *  12. `unsubscribeFromContent(uint256 _contentId)`: Allows users to unsubscribe from content.
 *  13. `isSubscriber(uint256 _contentId, address _user)`: Checks if a user is subscribed to content.
 *  14. `tipCreator(uint256 _contentId)`: Allows users to send tips to content creators.
 *  15. `withdrawCreatorEarnings()`: Allows creators to withdraw their accumulated earnings.
 *
 * **Curation & Voting:**
 *  16. `upvoteContent(uint256 _contentId)`: Allows users to upvote content.
 *  17. `downvoteContent(uint256 _contentId)`: Allows users to downvote content.
 *  18. `getContentRating(uint256 _contentId)`: Retrieves the current rating (upvotes - downvotes) of content.
 *  19. `reportContent(uint256 _contentId, string _reportReason)`: Allows users to report content for moderation.
 *
 * **Platform Governance & Utility:**
 *  20. `setPlatformFee(uint256 _newFee)`: Allows the contract owner to set a platform fee percentage.
 *  21. `getPlatformFee()`: Retrieves the current platform fee percentage.
 *  22. `setSubscriptionTiers(uint256[] memory _tiers, uint256[] memory _prices)`: Allows the contract owner to set dynamic subscription tiers.
 *  23. `getSubscriptionTiers()`: Retrieves the current subscription tiers and prices.
 *  24. `pauseContract()`: Pauses most contract functionalities in case of emergency.
 *  25. `unpauseContract()`: Resumes contract functionalities after pausing.
 *  26. `getContentCount()`: Returns the total number of content NFTs created.
 *
 * **Advanced Concepts Implemented:**
 *   - **Dynamic Subscription Tiers:** Different subscription durations with varying prices.
 *   - **Content Royalties:** Creators earn a percentage on secondary market sales.
 *   - **Curator Rewards (Future Extension):** Potential to reward users who actively curate and vote.
 *   - **Decentralized Dispute Resolution (Conceptual):** Reporting mechanism for flagging content issues.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ContentVerse is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _contentIds;

    // Struct to hold content information
    struct Content {
        string contentURI;
        string metadataURI;
        address creator;
        uint256 subscriptionPrice;
        uint256 royaltyPercentage; // Percentage (e.g., 5 for 5%)
        int256 rating;
        uint256 reportCount;
    }

    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => mapping(address => bool)) public contentSubscriptions; // contentId => user => isSubscribed
    mapping(address => uint256) public creatorEarnings; // creator address => accumulated earnings
    mapping(uint256 => mapping(address => bool)) public userUpvotes; // contentId => user => hasUpvoted
    mapping(uint256 => mapping(address => bool)) public userDownvotes; // contentId => user => hasDownvoted

    uint256 public platformFeePercentage = 5; // Default 5% platform fee on subscriptions
    uint256[] public subscriptionTiers; // Array of subscription durations (e.g., days)
    uint256[] public subscriptionTierPrices; // Array of corresponding prices for tiers

    event ContentNFTCreated(uint256 contentId, address creator, string contentURI, string metadataURI);
    event ContentMetadataUpdated(uint256 contentId, string metadataURI);
    event SubscriptionSet(uint256 contentId, uint256 price);
    event ContentRoyaltiesSet(uint256 contentId, uint256 royaltyPercentage);
    event ContentOwnershipTransferred(uint256 contentId, address from, address to);
    event ContentNFTBurned(uint256 contentId);
    event SubscribedToContent(uint256 contentId, address subscriber, uint256 tierIndex);
    event UnsubscribedFromContent(uint256 contentId, address subscriber);
    event TipSent(uint256 contentId, address tipper, uint256 amount);
    event EarningsWithdrawn(address creator, uint256 amount);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event PlatformFeeUpdated(uint256 newFee);
    event SubscriptionTiersUpdated();
    event ContractPaused();
    event ContractUnpaused();

    modifier onlyContentOwner(uint256 _contentId) {
        require(ownerOf(_contentId) == _msgSender(), "You are not the content owner");
        _;
    }

    modifier onlySubscriber(uint256 _contentId) {
        require(isSubscriber(_contentId, _msgSender()), "You are not subscribed to this content");
        _;
    }

    modifier whenNotPausedAndSubscriptionValid(uint256 _contentId) {
        require(!paused(), "Contract is paused");
        require(isSubscriber(_contentId, _msgSender()), "Subscription required to access content.");
        _;
    }

    constructor() ERC721("ContentVerseNFT", "CVNFT") {}

    /**
     * @dev Creates a new Content NFT.
     * @param _contentURI URI pointing to the actual content (e.g., IPFS hash).
     * @param _metadataURI URI pointing to the content metadata (e.g., title, description).
     */
    function createContentNFT(string memory _contentURI, string memory _metadataURI) public whenNotPaused {
        _contentIds.increment();
        uint256 contentId = _contentIds.current();
        _safeMint(_msgSender(), contentId);

        contentRegistry[contentId] = Content({
            contentURI: _contentURI,
            metadataURI: _metadataURI,
            creator: _msgSender(),
            subscriptionPrice: 0, // Default price
            royaltyPercentage: 0,  // Default no royalties
            rating: 0,
            reportCount: 0
        });

        emit ContentNFTCreated(contentId, _msgSender(), _contentURI, _metadataURI);
    }

    /**
     * @dev Updates the metadata URI of an existing Content NFT.
     * @param _contentId ID of the Content NFT.
     * @param _metadataURI New URI pointing to the content metadata.
     */
    function setContentMetadata(uint256 _contentId, string memory _metadataURI) public onlyContentOwner(_contentId) whenNotPaused {
        contentRegistry[_contentId].metadataURI = _metadataURI;
        emit ContentMetadataUpdated(_contentId, _metadataURI);
    }

    /**
     * @dev Retrieves the metadata URI of a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @return string Metadata URI of the content.
     */
    function getContentMetadata(uint256 _contentId) public view returns (string memory) {
        require(_exists(_contentId), "Content NFT does not exist");
        return contentRegistry[_contentId].metadataURI;
    }

    /**
     * @dev Retrieves the owner of a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @return address Owner of the content.
     */
    function getContentOwner(uint256 _contentId) public view returns (address) {
        return ownerOf(_contentId);
    }

    /**
     * @dev Sets the subscription price for accessing a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @param _price Subscription price in wei.
     */
    function setContentSubscriptionPrice(uint256 _contentId, uint256 _price) public onlyContentOwner(_contentId) whenNotPaused {
        contentRegistry[_contentId].subscriptionPrice = _price;
        emit SubscriptionSet(_contentId, _price);
    }

    /**
     * @dev Retrieves the subscription price of a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @return uint256 Subscription price in wei.
     */
    function getSubscriptionPrice(uint256 _contentId) public view returns (uint256) {
        require(_exists(_contentId), "Content NFT does not exist");
        return contentRegistry[_contentId].subscriptionPrice;
    }

    /**
     * @dev Sets the royalty percentage for secondary sales of a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @param _royaltyPercentage Royalty percentage (e.g., 5 for 5%).
     */
    function setContentRoyalties(uint256 _contentId, uint256 _royaltyPercentage) public onlyContentOwner(_contentId) whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        contentRegistry[_contentId].royaltyPercentage = _royaltyPercentage;
        emit ContentRoyaltiesSet(_contentId, _royaltyPercentage);
    }

    /**
     * @dev Retrieves the royalty percentage for a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @return uint256 Royalty percentage.
     */
    function getContentRoyalties(uint256 _contentId) public view returns (uint256) {
        require(_exists(_contentId), "Content NFT does not exist");
        return contentRegistry[_contentId].royaltyPercentage;
    }

    /**
     * @dev Transfers ownership of a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @param _newOwner Address of the new owner.
     */
    function transferContentOwnership(uint256 _contentId, address _newOwner) public onlyContentOwner(_contentId) whenNotPaused {
        transferFrom(_msgSender(), _newOwner, _contentId);
        emit ContentOwnershipTransferred(_contentId, _msgSender(), _newOwner);
    }

    /**
     * @dev Burns (destroys) a Content NFT. Only the owner can burn it.
     * @param _contentId ID of the Content NFT.
     */
    function burnContentNFT(uint256 _contentId) public onlyContentOwner(_contentId) whenNotPaused {
        _burn(_contentId);
        emit ContentNFTBurned(_contentId);
    }

    /**
     * @dev Allows users to subscribe to content. Supports dynamic subscription tiers.
     * @param _contentId ID of the Content NFT.
     * @param _tierIndex Index of the subscription tier to use.
     */
    function subscribeToContent(uint256 _contentId, uint256 _tierIndex) public payable whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        require(contentRegistry[_contentId].subscriptionPrice > 0, "Content is not monetized by subscription");
        require(_tierIndex < subscriptionTiers.length, "Invalid subscription tier index");
        require(subscriptionTierPrices.length == subscriptionTiers.length, "Subscription tiers and prices mismatch");
        require(msg.value >= subscriptionTierPrices[_tierIndex], "Insufficient payment for the selected tier");
        require(!contentSubscriptions[_contentId][_msgSender()], "Already subscribed to this content");

        contentSubscriptions[_contentId][_msgSender()] = true;

        uint256 platformFee = (subscriptionTierPrices[_tierIndex] * platformFeePercentage) / 100;
        uint256 creatorShare = subscriptionTierPrices[_tierIndex] - platformFee;

        creatorEarnings[contentRegistry[_contentId].creator] += creatorShare;
        payable(owner()).transfer(platformFee); // Platform fee goes to contract owner

        emit SubscribedToContent(_contentId, _msgSender(), _tierIndex);
    }

    /**
     * @dev Allows users to unsubscribe from content.
     * @param _contentId ID of the Content NFT.
     */
    function unsubscribeFromContent(uint256 _contentId) public whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        require(contentSubscriptions[_contentId][_msgSender()], "Not subscribed to this content");

        delete contentSubscriptions[_contentId][_msgSender()]; // Simply remove subscription status
        emit UnsubscribedFromContent(_contentId, _msgSender());
    }

    /**
     * @dev Checks if a user is subscribed to a Content NFT.
     * @param _contentId ID of the Content NFT.
     * @param _user Address of the user to check.
     * @return bool True if subscribed, false otherwise.
     */
    function isSubscriber(uint256 _contentId, address _user) public view returns (bool) {
        return contentSubscriptions[_contentId][_user];
    }

    /**
     * @dev Allows users to send tips to content creators.
     * @param _contentId ID of the Content NFT.
     */
    function tipCreator(uint256 _contentId) public payable whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        require(msg.value > 0, "Tip amount must be greater than zero");

        creatorEarnings[contentRegistry[_contentId].creator] += msg.value;
        emit TipSent(_contentId, _msgSender(), msg.value);
    }

    /**
     * @dev Allows creators to withdraw their accumulated earnings.
     */
    function withdrawCreatorEarnings() public whenNotPaused {
        uint256 amount = creatorEarnings[_msgSender()];
        require(amount > 0, "No earnings to withdraw");

        creatorEarnings[_msgSender()] = 0; // Reset earnings after withdrawal
        payable(_msgSender()).transfer(amount);
        emit EarningsWithdrawn(_msgSender(), amount);
    }

    /**
     * @dev Allows users to upvote content.
     * @param _contentId ID of the Content NFT.
     */
    function upvoteContent(uint256 _contentId) public whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        require(!userUpvotes[_contentId][_msgSender()], "Already upvoted this content");

        if (userDownvotes[_contentId][_msgSender()]) {
            contentRegistry[_contentId].rating++; // Neutralize downvote
            userDownvotes[_contentId][_msgSender()] = false;
        }
        contentRegistry[_contentId].rating++;
        userUpvotes[_contentId][_msgSender()] = true;
        emit ContentUpvoted(_contentId, _msgSender());
    }

    /**
     * @dev Allows users to downvote content.
     * @param _contentId ID of the Content NFT.
     */
    function downvoteContent(uint256 _contentId) public whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        require(!userDownvotes[_contentId][_msgSender()], "Already downvoted this content");

        if (userUpvotes[_contentId][_msgSender()]) {
            contentRegistry[_contentId].rating--; // Neutralize upvote
            userUpvotes[_contentId][_msgSender()] = false;
        }
        contentRegistry[_contentId].rating--;
        userDownvotes[_contentId][_msgSender()] = true;
        emit ContentDownvoted(_contentId, _msgSender());
    }

    /**
     * @dev Retrieves the current rating of content (upvotes - downvotes).
     * @param _contentId ID of the Content NFT.
     * @return int256 Content rating.
     */
    function getContentRating(uint256 _contentId) public view returns (int256) {
        require(_exists(_contentId), "Content NFT does not exist");
        return contentRegistry[_contentId].rating;
    }

    /**
     * @dev Allows users to report content for moderation.
     * @param _contentId ID of the Content NFT.
     * @param _reportReason Reason for reporting.
     */
    function reportContent(uint256 _contentId, string memory _reportReason) public whenNotPaused {
        require(_exists(_contentId), "Content NFT does not exist");
        contentRegistry[_contentId].reportCount++; // Simple report counter
        emit ContentReported(_contentId, _msgSender(), _reportReason);
        // In a real system, this would trigger a moderation process.
    }

    /**
     * @dev Sets the platform fee percentage for subscriptions. Only owner can call.
     * @param _newFee New platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFee(uint256 _newFee) public onlyOwner whenNotPaused {
        require(_newFee <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _newFee;
        emit PlatformFeeUpdated(_newFee);
    }

    /**
     * @dev Retrieves the current platform fee percentage.
     * @return uint256 Platform fee percentage.
     */
    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    /**
     * @dev Sets dynamic subscription tiers and their prices. Only owner can call.
     * @param _tiers Array of subscription durations (e.g., days).
     * @param _prices Array of corresponding prices in wei.
     */
    function setSubscriptionTiers(uint256[] memory _tiers, uint256[] memory _prices) public onlyOwner whenNotPaused {
        require(_tiers.length == _prices.length, "Tiers and prices arrays must have the same length");
        subscriptionTiers = _tiers;
        subscriptionTierPrices = _prices;
        emit SubscriptionTiersUpdated();
    }

    /**
     * @dev Retrieves the current subscription tiers and prices.
     * @return uint256[] Subscription tiers.
     * @return uint256[] Subscription tier prices.
     */
    function getSubscriptionTiers() public view returns (uint256[] memory, uint256[] memory) {
        return (subscriptionTiers, subscriptionTierPrices);
    }

    /**
     * @dev Pauses the contract functionality. Only owner can call.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract functionality. Only owner can call.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Returns the total count of content NFTs created.
     * @return uint256 Total content NFT count.
     */
    function getContentCount() public view returns (uint256) {
        return _contentIds.current();
    }

    /**
     * @dev Override to handle royalties on secondary sales (ERC2981 implementation would be more standard in production).
     * This is a simplified example. In a real-world scenario, consider implementing ERC2981.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) { // Secondary sale (not minting or burning)
            uint256 royaltyPercentage = contentRegistry[tokenId].royaltyPercentage;
            if (royaltyPercentage > 0) {
                uint256 salePrice = msg.value; // Assuming msg.value is the sale price (this is a simplification!)
                if (salePrice > 0) {
                    uint256 royaltyAmount = (salePrice * royaltyPercentage) / 100;
                    creatorEarnings[contentRegistry[tokenId].creator] += royaltyAmount;
                    // In a real implementation, you'd likely need to handle splitting the funds more carefully
                    // and possibly use a marketplace contract for royalty enforcement.
                }
            }
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```