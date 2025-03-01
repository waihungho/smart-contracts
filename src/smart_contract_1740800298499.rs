```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Subscription (DDCS) - Inspired by NFT-gated content and subscription models.
 * @author Gemini
 * @notice This contract allows creators to lock content behind an NFT ownership or ERC-20 token ownership.
 *  Creators can define a subscription period.  Users need to hold the specific NFT/Token AND have a valid subscription
 *  to access the content. The content is stored off-chain (e.g., IPFS, Arweave) with a hash stored on-chain for verification.
 * @dev This contract demonstrates an advanced pattern incorporating ERC-721/ERC-20 interaction, time-based subscriptions,
 *      and decentralized content storage. This design prioritizes flexibility and content creator control.
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedDynamicContentSubscription is Ownable {
    using Strings for uint256;

    // ********************
    // Structs and Enums
    // ********************

    /**
     * @notice Represents a content item that a creator has locked.
     * @param creator The address of the creator who uploaded the content.
     * @param contentHash The hash of the content stored off-chain (e.g., IPFS CID).
     * @param accessType The type of token required to access the content (NFT or ERC20).
     * @param tokenAddress The address of the NFT or ERC20 token required.
     * @param subscriptionPeriod The length of the subscription in seconds.
     * @param costPerPeriod The cost of one subscription period in ETH.
     * @param lastUpdated The last time this content item was updated.
     * @param isActive Whether the content is currently available.
     */
    struct ContentItem {
        address creator;
        string contentHash;
        AccessType accessType;
        address tokenAddress;
        uint256 subscriptionPeriod; //seconds
        uint256 costPerPeriod; //in Wei
        uint256 lastUpdated;
        bool isActive;
    }

    /**
     * @notice Represents a user's subscription to a piece of content.
     * @param expiryTime The time when the subscription expires (in seconds).
     */
    struct Subscription {
        uint256 expiryTime; // Epoch timestamp
    }

    enum AccessType {
        NFT,
        ERC20
    }

    // ********************
    // State Variables
    // ********************

    mapping(uint256 => ContentItem) public contentItems;  //contentId => ContentItem struct
    mapping(address => mapping(uint256 => Subscription)) public subscriptions; // user => contentId => Subscription struct

    uint256 public nextContentId = 1; //counter to increment for contentIds

    // Fee Structure
    uint256 public platformFeePercentage = 5; // Percentage of subscription revenue taken as platform fee.
    address public feeRecipient;

    // ********************
    // Events
    // ********************

    event ContentCreated(uint256 contentId, address creator, string contentHash, AccessType accessType, address tokenAddress, uint256 subscriptionPeriod, uint256 costPerPeriod);
    event SubscriptionPurchased(address user, uint256 contentId, uint256 expiryTime);
    event ContentUpdated(uint256 contentId, string newContentHash);
    event ContentDeactivated(uint256 contentId);
    event PlatformFeePercentageUpdated(uint256 newPercentage);
    event FeeRecipientUpdated(address newFeeRecipient);

    // ********************
    // Constructor
    // ********************

    constructor(address _feeRecipient) Ownable() {
        feeRecipient = _feeRecipient;
    }


    // ********************
    // Modifiers
    // ********************

    modifier onlyContentCreator(uint256 _contentId) {
        require(contentItems[_contentId].creator == _msgSender(), "Only the content creator can perform this action.");
        _;
    }

    modifier validContentId(uint256 _contentId) {
        require(contentItems[_contentId].creator != address(0), "Invalid content ID.");
        _;
    }

    // ********************
    // Core Functions
    // ********************

    /**
     * @notice Creates a new content item.
     * @param _contentHash The hash of the content (e.g., IPFS CID).
     * @param _accessType The type of token required (NFT or ERC20).
     * @param _tokenAddress The address of the required NFT or ERC20 token.
     * @param _subscriptionPeriod The duration of the subscription in seconds.
     * @param _costPerPeriod The cost per subscription period in Wei.
     */
    function createContent(
        string memory _contentHash,
        AccessType _accessType,
        address _tokenAddress,
        uint256 _subscriptionPeriod,
        uint256 _costPerPeriod
    ) external {
        require(_subscriptionPeriod > 0, "Subscription period must be greater than 0.");
        require(_costPerPeriod > 0, "Cost per period must be greater than 0.");

        uint256 contentId = nextContentId;
        nextContentId++;

        contentItems[contentId] = ContentItem({
            creator: _msgSender(),
            contentHash: _contentHash,
            accessType: _accessType,
            tokenAddress: _tokenAddress,
            subscriptionPeriod: _subscriptionPeriod,
            costPerPeriod: _costPerPeriod,
            lastUpdated: block.timestamp,
            isActive: true
        });

        emit ContentCreated(contentId, _msgSender(), _contentHash, _accessType, _tokenAddress, _subscriptionPeriod, _costPerPeriod);
    }

   /**
     * @notice Updates the content hash for a given content ID.  Only the creator can perform this action.
     * @param _contentId The ID of the content to update.
     * @param _newContentHash The new content hash.
     */
    function updateContent(uint256 _contentId, string memory _newContentHash) external onlyContentCreator(_contentId) validContentId(_contentId) {
        contentItems[_contentId].contentHash = _newContentHash;
        contentItems[_contentId].lastUpdated = block.timestamp;
        emit ContentUpdated(_contentId, _newContentHash);
    }

    /**
     * @notice Deactivates a content item.  Only the creator can perform this action.  Deactivated content is no longer accessible.
     * @param _contentId The ID of the content to deactivate.
     */
    function deactivateContent(uint256 _contentId) external onlyContentCreator(_contentId) validContentId(_contentId) {
        contentItems[_contentId].isActive = false;
        emit ContentDeactivated(_contentId);
    }



    /**
     * @notice Allows a user to purchase a subscription to a content item.
     * @param _contentId The ID of the content to subscribe to.
     */
    function purchaseSubscription(uint256 _contentId) external payable validContentId(_contentId) {
        ContentItem memory content = contentItems[_contentId];

        require(content.isActive, "Content is not currently active.");
        require(msg.value >= content.costPerPeriod, "Insufficient payment.");

        //Verify User Hold Required Token
        if (!hasRequiredToken(_msgSender(), _contentId)) {
            revert("User does not hold required token for this content.");
        }


        uint256 expiryTime = block.timestamp + content.subscriptionPeriod;
        // Check for existing subscription and extend it if it exists
        if (subscriptions[_msgSender()][_contentId].expiryTime > block.timestamp) {
            expiryTime = subscriptions[_msgSender()][_contentId].expiryTime + content.subscriptionPeriod;
        }


        subscriptions[_msgSender()][_contentId] = Subscription({
            expiryTime: expiryTime
        });


        // Transfer platform fee.
        uint256 platformFee = (content.costPerPeriod * platformFeePercentage) / 100;
        payable(feeRecipient).transfer(platformFee);

        // Transfer remaining amount to creator.
        uint256 creatorShare = content.costPerPeriod - platformFee;
        payable(content.creator).transfer(creatorShare);

        // Refund any overpayment.
        if (msg.value > content.costPerPeriod) {
            payable(_msgSender()).transfer(msg.value - content.costPerPeriod);
        }


        emit SubscriptionPurchased(_msgSender(), _contentId, expiryTime);
    }

    /**
     * @notice Checks if a user has an active subscription to a content item.
     * @param _user The address of the user.
     * @param _contentId The ID of the content.
     * @return True if the user has an active subscription, false otherwise.
     */
    function hasActiveSubscription(address _user, uint256 _contentId) public view returns (bool) {
        return subscriptions[_user][_contentId].expiryTime > block.timestamp;
    }


    /**
     * @notice Verifies if a user holds the required token for a given content ID.
     * @param _user The address of the user.
     * @param _contentId The ID of the content.
     * @return True if the user holds the required token, false otherwise.
     */
    function hasRequiredToken(address _user, uint256 _contentId) public view returns (bool) {
        ContentItem memory content = contentItems[_contentId];

        if (content.accessType == AccessType.NFT) {
            IERC721 nft = IERC721(content.tokenAddress);
            try nft.balanceOf(_user) returns (uint256 balance) {
                return balance > 0; //Checks if they own any of that NFT.
            } catch {
                return false;
            }

        } else if (content.accessType == AccessType.ERC20) {
            IERC20 token = IERC20(content.tokenAddress);
            return token.balanceOf(_user) > 0; //Checks if they own any balance of the token.
        } else {
            return false; // Should never reach here, but safety check.
        }
    }


    /**
     * @notice Checks if a user has access to a content item.
     * @param _user The address of the user.
     * @param _contentId The ID of the content.
     * @return True if the user has access, false otherwise.
     */
    function hasAccess(address _user, uint256 _contentId) public view returns (bool) {
        return contentItems[_contentId].isActive && hasRequiredToken(_user, _contentId) && hasActiveSubscription(_user, _contentId);
    }

    /**
     * @notice Returns the content hash for a given content ID.
     * @param _contentId The ID of the content.
     * @return The content hash.
     */
    function getContentHash(uint256 _contentId) public view returns (string memory) {
        require(contentItems[_contentId].creator != address(0), "Invalid content ID.");
        require(contentItems[_contentId].isActive, "Content is not currently active.");
        return contentItems[_contentId].contentHash;
    }

    // ********************
    // Admin Functions
    // ********************

    /**
     * @notice Updates the platform fee percentage.  Only the owner can perform this action.
     * @param _newPercentage The new fee percentage.
     */
    function updatePlatformFeePercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _newPercentage;
        emit PlatformFeePercentageUpdated(_newPercentage);
    }

    /**
     * @notice Updates the fee recipient address.  Only the owner can perform this action.
     * @param _newFeeRecipient The new fee recipient address.
     */
    function updateFeeRecipient(address _newFeeRecipient) external onlyOwner {
        require(_newFeeRecipient != address(0), "Invalid fee recipient address.");
        feeRecipient = _newFeeRecipient;
        emit FeeRecipientUpdated(_newFeeRecipient);
    }

    /**
     * @notice Allows the owner to withdraw any ether held by the contract.
     */
    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
```

**Outline and Function Summary:**

**Contract:** `DecentralizedDynamicContentSubscription`

*   **Purpose:** Enables creators to lock content behind NFT/ERC20 token ownership with a time-based subscription. This is an advanced content subscription platform.

*   **Structs:**
    *   `ContentItem`: Represents a content item with its creator, hash, access type, token address, subscription period, cost, last updated timestamp, and active status.
    *   `Subscription`: Represents a user's subscription, storing the expiration timestamp.

*   **Enums:**
    *   `AccessType`: Specifies the type of token required for access (NFT or ERC20).

*   **State Variables:**
    *   `contentItems`: Mapping from content ID to `ContentItem`.
    *   `subscriptions`: Nested mapping from user address to content ID to `Subscription`.
    *   `nextContentId`: Counter for unique content IDs.
    *   `platformFeePercentage`: Percentage of subscription revenue taken as a platform fee.
    *   `feeRecipient`: Address that receives the platform fee.

*   **Events:**
    *   `ContentCreated`: Emitted when a new content item is created.
    *   `SubscriptionPurchased`: Emitted when a user purchases a subscription.
    *   `ContentUpdated`: Emitted when a content item's hash is updated.
    *   `ContentDeactivated`: Emitted when a content item is deactivated.
    *   `PlatformFeePercentageUpdated`: Emitted when the platform fee percentage is changed.
    *   `FeeRecipientUpdated`: Emitted when the fee recipient address is changed.

*   **Constructor:**
    *   Initializes the `feeRecipient` and sets the owner of the contract via the `Ownable` contract.

*   **Modifiers:**
    *   `onlyContentCreator`: Restricts access to functions to the creator of the content.
    *   `validContentId`: Requires that a content ID is valid (exists).

*   **Core Functions:**
    *   `createContent()`: Creates a new content item. Requires content hash, access type (NFT or ERC20), token address, subscription period, and cost per period.
    *   `updateContent()`: Updates the content hash of an existing content item.  Only the creator can call.
    *   `deactivateContent()`: Deactivates a content item.  Only the creator can call.
    *   `purchaseSubscription()`: Allows a user to purchase a subscription to a content item, validating for existing tokens held and paying the content creator (after fees).
    *   `hasActiveSubscription()`: Checks if a user has a valid subscription.
    *   `hasRequiredToken()`: Checks if a user holds the required NFT or ERC20 token.
    *   `hasAccess()`: Checks if a user has both the required token and a valid subscription.
    *   `getContentHash()`: Returns the content hash for a given content ID.

*   **Admin Functions:**
    *   `updatePlatformFeePercentage()`: Updates the platform fee percentage (only owner).
    *   `updateFeeRecipient()`: Updates the address that receives the platform fee (only owner).
    *   `withdrawEther()`: Allows the owner to withdraw ether from the contract.

**Key Advanced Concepts & Creativity:**

1.  **Dynamic Content Gating:** Content is not just gated by NFT ownership but also by a subscription model. This combines the exclusivity of NFTs with the recurring revenue potential of subscriptions.

2.  **Flexible Access Types:**  Supports both ERC-721 (NFT) and ERC-20 tokens for gating content, providing greater flexibility for creators.

3.  **Decentralized Content Storage:** Content is stored off-chain (e.g., IPFS, Arweave), with only the content hash stored on-chain, minimizing storage costs and maximizing censorship resistance.

4.  **Platform Fee & Revenue Distribution:**  Implements a flexible platform fee model that automatically distributes revenue between the platform and the content creator.

5.  **Extensible Subscriptions:**  Existing subscriptions are extended if a user purchases a new subscription before their current one expires.

6.  **Active/Inactive Content:**  Allows creators to temporarily or permanently deactivate content, controlling access to it.

7. **Safety Checks and Reentrancy Prevention:** Uses OpenZeppelin's `Ownable` for access control and employs checks-effects-interactions pattern where external calls are made after internal state updates.

This contract offers a sophisticated and flexible platform for creators to monetize their content in a decentralized and innovative manner, going beyond basic NFT-gated content solutions.
