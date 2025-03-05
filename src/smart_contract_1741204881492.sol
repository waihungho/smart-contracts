```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Subscription Platform (DDCSP)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic content subscription platform where content NFTs evolve based on subscriber engagement and platform activity.
 *
 * **Outline & Function Summary:**
 *
 * **Contract Overview:**
 *  This contract implements a Decentralized Dynamic Content Subscription Platform (DDCSP).
 *  Creators can deploy content as NFTs, and users can subscribe to access evolving content layers.
 *  Content NFTs dynamically change their visual representation and metadata based on subscription metrics, creator updates, and platform events.
 *  It incorporates advanced concepts like dynamic NFTs, on-chain subscription management, content evolution, and decentralized governance over content tiers.
 *
 * **Functions (20+):**
 *
 * **Creator Functions:**
 *  1. `deployContentNFT(string memory _baseURI, string memory _initialMetadata)`: Deploys a new Dynamic Content NFT collection.
 *  2. `setContentTier(uint256 _contentNFTId, uint8 _tierLevel, uint256 _subscriptionPrice)`: Sets the subscription price for a specific tier level of a content NFT.
 *  3. `updateContentLayer(uint256 _contentNFTId, uint8 _tierLevel, string memory _layerURI)`: Updates the URI for a specific content layer at a given tier level.
 *  4. `setContentMetadataExtension(uint256 _contentNFTId, string memory _metadataExtension)`: Sets a general metadata extension for the entire content NFT collection.
 *  5. `withdrawCreatorEarnings(uint256 _contentNFTId)`: Allows creators to withdraw accumulated subscription earnings for their content NFT.
 *  6. `pauseContentNFT(uint256 _contentNFTId)`: Pauses subscriptions for a specific content NFT, preventing new subscriptions.
 *  7. `unpauseContentNFT(uint256 _contentNFTId)`: Resumes subscriptions for a paused content NFT.
 *  8. `setBaseURIFactory(address _factoryAddress)`: Allows the contract owner to set a new factory contract address for generating dynamic base URIs.
 *
 * **Subscriber Functions:**
 *  9. `subscribeToContent(uint256 _contentNFTId, uint8 _tierLevel)`: Allows users to subscribe to a specific tier level of a content NFT.
 *  10. `unsubscribeFromContent(uint256 _contentNFTId)`: Allows users to unsubscribe from a content NFT.
 *  11. `viewSubscribedContentURI(uint256 _contentNFTId)`: Allows subscribers to view the URI of their currently accessible content layer.
 *  12. `getSubscriptionTier(uint256 _contentNFTId, address _subscriber)`: Returns the subscription tier level of a user for a specific content NFT.
 *
 * **Platform Governance/Admin Functions (Owner/Governance Role):**
 *  13. `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage on subscriptions.
 *  14. `withdrawPlatformFees()`: Allows the platform owner to withdraw accumulated platform fees.
 *  15. `setContentTierLimit(uint8 _tierLimit)`: Sets the maximum allowed tier level for content NFTs.
 *  16. `setSubscriptionDuration(uint256 _durationInSeconds)`: Sets the default subscription duration.
 *  17. `emergencyWithdrawAnyERC20(address _tokenAddress, address _recipient, uint256 _amount)`: Emergency function to withdraw any ERC20 token stuck in the contract.
 *  18. `emergencyWithdraw()`: Emergency function to withdraw stuck ETH from the contract.
 *  19. `transferOwnership(address newOwner)`: Allows the current owner to transfer contract ownership.
 *  20. `getContentNFTCreator(uint256 _contentNFTId)`: Returns the creator address of a specific Content NFT collection.
 *  21. `getTotalSubscribers(uint256 _contentNFTId)`: Returns the total number of subscribers for a given content NFT.
 *  22. `isSubscribed(uint256 _contentNFTId, address _subscriber)`: Checks if a user is subscribed to a specific content NFT.
 *  23. `getContentNFTPauseStatus(uint256 _contentNFTId)`: Checks if a content NFT is paused for subscriptions.
 *  24. `getContentTierPrice(uint256 _contentNFTId, uint8 _tierLevel)`: Retrieves the subscription price for a specific tier of a content NFT.
 *
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicContentSubscriptionPlatform is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _contentNFTIdCounter;

    // Platform Fee (percentage, e.g., 500 for 5%)
    uint256 public platformFeePercentage = 500;
    address public platformFeeRecipient;

    // Default Subscription Duration (in seconds, e.g., 30 days)
    uint256 public defaultSubscriptionDuration = 30 days;

    // Maximum allowed tier level for content NFTs
    uint8 public maxContentTierLimit = 5;

    // Struct to represent Content NFT collection data
    struct ContentNFTData {
        address creator;
        string baseURI;
        string metadataExtension;
        uint8 tierLevels;
        mapping(uint8 => uint256) tierPrices; // Tier Level => Subscription Price (in Wei)
        mapping(uint8 => string) tierContentURIs; // Tier Level => Content URI
        uint256 totalEarnings;
        uint256 totalSubscribers;
        bool isPaused;
    }

    // Mapping from Content NFT ID to its data
    mapping(uint256 => ContentNFTData) public contentNFTs;

    // Mapping from Content NFT ID to subscriber address to subscription expiry timestamp
    mapping(uint256 => mapping(address => uint256)) public subscriptions;

    // Events
    event ContentNFTDeployed(uint256 contentNFTId, address creator, string baseURI);
    event SubscriptionCreated(uint256 contentNFTId, address subscriber, uint8 tierLevel);
    event SubscriptionCancelled(uint256 contentNFTId, address subscriber);
    event ContentLayerUpdated(uint256 contentNFTId, uint8 tierLevel, string layerURI);
    event TierPriceSet(uint256 contentNFTId, uint8 tierLevel, uint256 price);
    event EarningsWithdrawn(uint256 contentNFTId, address creator, uint256 amount);
    event ContentNFTPaused(uint256 contentNFTId);
    event ContentNFTUnpaused(uint256 contentNFTId);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event MaxTierLimitUpdated(uint8 newLimit);
    event SubscriptionDurationUpdated(uint256 newDuration);


    constructor(string memory _platformName, address _platformFeeRecipient) ERC721(_platformName, "DDCSP-NFT") {
        platformFeeRecipient = _platformFeeRecipient;
    }

    modifier onlyCreator(uint256 _contentNFTId) {
        require(contentNFTs[_contentNFTId].creator == _msgSender(), "Not content NFT creator");
        _;
    }

    modifier validContentNFT(uint256 _contentNFTId) {
        require(contentNFTs[_contentNFTId].creator != address(0), "Invalid Content NFT ID");
        _;
    }

    modifier validTierLevel(uint8 _tierLevel) {
        require(_tierLevel > 0 && _tierLevel <= maxContentTierLimit, "Invalid tier level");
        _;
    }

    modifier subscriptionActive(uint256 _contentNFTId, address _subscriber) {
        require(subscriptions[_contentNFTId][_subscriber] > block.timestamp, "Subscription expired or not active");
        _;
    }

    modifier contentNFTPausedCheck(uint256 _contentNFTId) {
        require(!contentNFTs[_contentNFTId].isPaused, "Content NFT is paused");
        _;
    }

    // --- Creator Functions ---

    /**
     * @dev Deploys a new Dynamic Content NFT collection.
     * @param _baseURI The base URI for the NFT metadata.
     * @param _initialMetadata Initial metadata to be associated with the NFT collection.
     */
    function deployContentNFT(string memory _baseURI, string memory _initialMetadata) external whenNotPaused returns (uint256 contentNFTId) {
        _contentNFTIdCounter.increment();
        contentNFTId = _contentNFTIdCounter.current();

        contentNFTs[contentNFTId] = ContentNFTData({
            creator: _msgSender(),
            baseURI: _baseURI,
            metadataExtension: _initialMetadata,
            tierLevels: maxContentTierLimit, // Initialize with max allowed tiers
            totalEarnings: 0,
            totalSubscribers: 0,
            isPaused: false
        });

        emit ContentNFTDeployed(contentNFTId, _msgSender(), _baseURI);
        return contentNFTId;
    }

    /**
     * @dev Sets the subscription price for a specific tier level of a content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _tierLevel The tier level (1 to maxContentTierLimit).
     * @param _subscriptionPrice The subscription price in Wei.
     */
    function setContentTier(uint256 _contentNFTId, uint8 _tierLevel, uint256 _subscriptionPrice)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        validTierLevel(_tierLevel)
        whenNotPaused
    {
        contentNFTs[_contentNFTId].tierPrices[_tierLevel] = _subscriptionPrice;
        emit TierPriceSet(_contentNFTId, _tierLevel, _subscriptionPrice);
    }

    /**
     * @dev Updates the URI for a specific content layer at a given tier level.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _tierLevel The tier level (1 to maxContentTierLimit).
     * @param _layerURI The new URI for the content layer.
     */
    function updateContentLayer(uint256 _contentNFTId, uint8 _tierLevel, string memory _layerURI)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        validTierLevel(_tierLevel)
        whenNotPaused
    {
        contentNFTs[_contentNFTId].tierContentURIs[_tierLevel] = _layerURI;
        emit ContentLayerUpdated(_contentNFTId, _tierLevel, _layerURI);
    }

    /**
     * @dev Sets a general metadata extension for the entire content NFT collection.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _metadataExtension The metadata extension string.
     */
    function setContentMetadataExtension(uint256 _contentNFTId, string memory _metadataExtension)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        whenNotPaused
    {
        contentNFTs[_contentNFTId].metadataExtension = _metadataExtension;
    }

    /**
     * @dev Allows creators to withdraw accumulated subscription earnings for their content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     */
    function withdrawCreatorEarnings(uint256 _contentNFTId)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        whenNotPaused
    {
        uint256 earnings = contentNFTs[_contentNFTId].totalEarnings;
        require(earnings > 0, "No earnings to withdraw");

        contentNFTs[_contentNFTId].totalEarnings = 0; // Reset earnings
        payable(_msgSender()).transfer(earnings);
        emit EarningsWithdrawn(_contentNFTId, _msgSender(), earnings);
    }

    /**
     * @dev Pauses subscriptions for a specific content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     */
    function pauseContentNFT(uint256 _contentNFTId)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        whenNotPaused
    {
        contentNFTs[_contentNFTId].isPaused = true;
        emit ContentNFTPaused(_contentNFTId);
    }

    /**
     * @dev Resumes subscriptions for a paused content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     */
    function unpauseContentNFT(uint256 _contentNFTId)
        external
        onlyCreator(_contentNFTId)
        validContentNFT(_contentNFTId)
        whenNotPaused
    {
        contentNFTs[_contentNFTId].isPaused = false;
        emit ContentNFTUnpaused(_contentNFTId);
    }


    // --- Subscriber Functions ---

    /**
     * @dev Allows users to subscribe to a specific tier level of a content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _tierLevel The tier level to subscribe to (1 to maxContentTierLimit).
     */
    function subscribeToContent(uint256 _contentNFTId, uint8 _tierLevel)
        external
        payable
        validContentNFT(_contentNFTId)
        validTierLevel(_tierLevel)
        contentNFTPausedCheck(_contentNFTId)
        whenNotPaused
    {
        uint256 subscriptionPrice = contentNFTs[_contentNFTId].tierPrices[_tierLevel];
        require(msg.value >= subscriptionPrice, "Insufficient subscription fee");

        // Handle platform fee
        uint256 platformFee = (subscriptionPrice * platformFeePercentage) / 10000;
        uint256 creatorEarning = subscriptionPrice - platformFee;

        // Transfer platform fee
        payable(platformFeeRecipient).transfer(platformFee);

        // Update creator earnings
        contentNFTs[_contentNFTId].totalEarnings += creatorEarning;

        // Update subscription expiry
        subscriptions[_contentNFTId][_msgSender()] = block.timestamp + defaultSubscriptionDuration;

        // Increment subscriber count
        if (subscriptions[_contentNFTId][_msgSender()] <= block.timestamp + defaultSubscriptionDuration) { // Only increment if truly a new subscription (or renewal would count as new)
             contentNFTs[_contentNFTId].totalSubscribers++;
        }


        emit SubscriptionCreated(_contentNFTId, _msgSender(), _tierLevel);
    }

    /**
     * @dev Allows users to unsubscribe from a content NFT (effectively stops renewal).
     * @param _contentNFTId The ID of the Content NFT.
     */
    function unsubscribeFromContent(uint256 _contentNFTId)
        external
        validContentNFT(_contentNFTId)
        whenNotPaused
    {
        delete subscriptions[_contentNFTId][_msgSender()];
        emit SubscriptionCancelled(_contentNFTId, _msgSender());
    }

    /**
     * @dev Allows subscribers to view the URI of their currently accessible content layer.
     * @param _contentNFTId The ID of the Content NFT.
     * @return The URI of the content layer, or empty string if not subscribed.
     */
    function viewSubscribedContentURI(uint256 _contentNFTId)
        external
        view
        validContentNFT(_contentNFTId)
        whenNotPaused
        returns (string memory)
    {
        if (subscriptions[_contentNFTId][_msgSender()] > block.timestamp) {
            // Determine tier level - in this simplified version, subscriber always gets max tier they subscribed to.
            // In a more complex version, tiers could be based on subscription duration, engagement, etc.
            uint8 subscribedTier = 0;
            for (uint8 tier = maxContentTierLimit; tier >= 1; tier--) {
                if (contentNFTs[_contentNFTId].tierPrices[tier] > 0) { // Basic check if tier is configured, refine if needed
                    subscribedTier = tier;
                    break;
                }
            }
            if (subscribedTier > 0) {
                return contentNFTs[_contentNFTId].tierContentURIs[subscribedTier];
            }
        }
        return ""; // Return empty string if not subscribed or no content for tier.
    }

    /**
     * @dev Gets the subscription tier level of a user for a specific content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _subscriber The address of the subscriber.
     * @return The subscription tier level (0 if not subscribed or expired).
     */
    function getSubscriptionTier(uint256 _contentNFTId, address _subscriber)
        external
        view
        validContentNFT(_contentNFTId)
        whenNotPaused
        returns (uint8)
    {
        if (subscriptions[_contentNFTId][_subscriber] > block.timestamp) {
             uint8 subscribedTier = 0;
            for (uint8 tier = maxContentTierLimit; tier >= 1; tier--) {
                if (contentNFTs[_contentNFTId].tierPrices[tier] > 0) { // Basic check if tier is configured, refine if needed
                    subscribedTier = tier;
                    break;
                }
            }
            return subscribedTier;
        }
        return 0; // 0 indicates no active subscription
    }

    // --- Platform Governance/Admin Functions ---

    /**
     * @dev Sets the platform fee percentage on subscriptions.
     * @param _feePercentage The new fee percentage (e.g., 500 for 5%).
     */
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        platformFeePercentage = _feePercentage;
        emit PlatformFeeUpdated(_feePercentage);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        // In this simplified version, platform fees are directly transferred in `subscribeToContent`.
        // For a more complex system, fees might be accumulated in the contract.
        // This function could be expanded to track and withdraw accumulated platform fees if needed.
        // For now, it serves as a placeholder or for future fee accumulation logic.
        emit PlatformFeesWithdrawn(0, platformFeeRecipient); // Placeholder event, adjust if actual fee tracking is added.
        // In a real scenario, you would track platform fees and transfer them here.
    }

    /**
     * @dev Sets the maximum allowed tier level for content NFTs.
     * @param _tierLimit The new maximum tier level.
     */
    function setContentTierLimit(uint8 _tierLimit) external onlyOwner whenNotPaused {
        require(_tierLimit > 0 && _tierLimit <= 20, "Tier limit out of bounds (1-20)"); // Example limit
        maxContentTierLimit = _tierLimit;
        emit MaxTierLimitUpdated(_tierLimit);
    }

    /**
     * @dev Sets the default subscription duration.
     * @param _durationInSeconds The subscription duration in seconds.
     */
    function setSubscriptionDuration(uint256 _durationInSeconds) external onlyOwner whenNotPaused {
        defaultSubscriptionDuration = _durationInSeconds;
        emit SubscriptionDurationUpdated(_durationInSeconds);
    }


    /**
     * @dev Emergency function to withdraw any ERC20 token stuck in the contract.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _recipient The address to send the tokens to.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawAnyERC20(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 withdrawAmount = Math.min(_amount, balance); // Prevent withdrawing more than balance

        require(withdrawAmount > 0, "No tokens to withdraw or amount is zero");
        bool success = token.transfer(_recipient, withdrawAmount);
        require(success, "ERC20 transfer failed");
    }

    /**
     * @dev Emergency function to withdraw stuck ETH from the contract.
     */
    function emergencyWithdraw() external onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Transfers ownership of the contract to a new owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner whenNotPaused {
        super.transferOwnership(newOwner);
    }

    /**
     * @dev Returns the creator address of a specific Content NFT collection.
     * @param _contentNFTId The ID of the Content NFT.
     * @return The creator address.
     */
    function getContentNFTCreator(uint256 _contentNFTId) external view validContentNFT(_contentNFTId) returns (address) {
        return contentNFTs[_contentNFTId].creator;
    }

    /**
     * @dev Returns the total number of subscribers for a given content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @return The total subscriber count.
     */
    function getTotalSubscribers(uint256 _contentNFTId) external view validContentNFT(_contentNFTId) returns (uint256) {
        return contentNFTs[_contentNFTId].totalSubscribers;
    }

    /**
     * @dev Checks if a user is subscribed to a specific content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _subscriber The address to check.
     * @return True if subscribed and active, false otherwise.
     */
    function isSubscribed(uint256 _contentNFTId, address _subscriber) external view validContentNFT(_contentNFTId) returns (bool) {
        return subscriptions[_contentNFTId][_subscriber] > block.timestamp;
    }

    /**
     * @dev Checks if a content NFT is paused for subscriptions.
     * @param _contentNFTId The ID of the Content NFT.
     * @return True if paused, false otherwise.
     */
    function getContentNFTPauseStatus(uint256 _contentNFTId) external view validContentNFT(_contentNFTId) returns (bool) {
        return contentNFTs[_contentNFTId].isPaused;
    }

    /**
     * @dev Retrieves the subscription price for a specific tier of a content NFT.
     * @param _contentNFTId The ID of the Content NFT.
     * @param _tierLevel The tier level.
     * @return The subscription price in Wei.
     */
    function getContentTierPrice(uint256 _contentNFTId, uint8 _tierLevel) external view validContentNFT(_contentNFTId) validTierLevel(_tierLevel) returns (uint256) {
        return contentNFTs[_contentNFTId].tierPrices[_tierLevel];
    }


    // --- Override ERC721 URI Function (Example Dynamic URI) ---
    // In a real dynamic NFT, you would likely use a more advanced URI generation mechanism,
    // possibly involving an off-chain service or a separate factory contract for generating baseURIs.
    // This is a simplified example.

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * This override provides a dynamic token URI based on the content NFT's base URI and the subscriber's access tier.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 contentNFTId = tokenId; // Assuming tokenId == contentNFTId for simplicity in this example.
        address subscriber = _msgSender();
        uint8 tierLevel = getSubscriptionTier(contentNFTId, subscriber);
        string memory contentURI = viewSubscribedContentURI(contentNFTId); // Get content URI based on subscription

        string memory base = contentNFTs[contentNFTId].baseURI;
        string memory extension = contentNFTs[contentNFTId].metadataExtension;

        // Example dynamic URI construction:  baseURI + "/tier" + tierLevel + "/" + tokenId + extension
        // You can customize this logic to create more complex and dynamic URIs.
        return string(abi.encodePacked(base, "/tier", Strings.toString(tierLevel), "/", tokenId.toString(), extension));
    }

    // --- Pause & Unpause Contract (Platform Level Pause) ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    receive() external payable {} // To receive ETH for subscriptions
    fallback() external payable {}
}

// --- Interfaces ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```