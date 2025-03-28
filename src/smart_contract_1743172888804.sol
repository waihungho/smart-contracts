```solidity
/**
 * @title Decentralized Reputation and Influence Marketplace - "InfluenceSphere"
 * @author Bard (Example Smart Contract - Conceptual and for illustrative purposes only)
 * @dev A smart contract implementing a decentralized reputation and influence system with a marketplace.
 *
 * Outline and Function Summary:
 *
 * 1. **Initialization & Ownership:**
 *    - `constructor(address _admin)`: Sets the contract owner/admin.
 *    - `owner()`: Returns the contract owner.
 *    - `transferOwnership(address newOwner)`: Allows the owner to transfer contract ownership.
 *
 * 2. **User Reputation System:**
 *    - `registerUser(string _username)`: Registers a new user with a unique username.
 *    - `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 *    - `increaseReputation(address _user, uint256 _amount)`: Increases a user's reputation (admin-controlled).
 *    - `decreaseReputation(address _user, uint256 _amount)`: Decreases a user's reputation (admin-controlled).
 *    - `submitContent(string _contentHash)`: Allows registered users to submit content and earn reputation.
 *    - `upvoteContent(uint256 _contentId)`: Allows registered users to upvote content, increasing author's reputation.
 *    - `downvoteContent(uint256 _contentId)`: Allows registered users to downvote content, potentially decreasing author's reputation.
 *    - `reportContent(uint256 _contentId, string _reason)`: Allows users to report content for moderation (admin review).
 *
 * 3. **Influence Token & Staking:**
 *    - `stakeReputationForInfluence(uint256 _reputationAmount)`: Allows users to stake reputation to receive Influence Tokens.
 *    - `unstakeInfluence(uint256 _influenceAmount)`: Allows users to unstake Influence Tokens to reclaim reputation.
 *    - `getInfluenceTokenBalance(address _user)`: Retrieves the Influence Token balance of a user.
 *    - `transferInfluenceTokens(address _recipient, uint256 _amount)`: Allows users to transfer Influence Tokens to others.
 *
 * 4. **Influence Marketplace & Utility:**
 *    - `listInfluenceForSale(uint256 _influenceAmount, uint256 _pricePerToken)`: Allows users to list their Influence Tokens for sale.
 *    - `purchaseInfluence(uint256 _listingId, uint256 _amount)`: Allows users to purchase Influence Tokens from listings.
 *    - `cancelInfluenceListing(uint256 _listingId)`: Allows users to cancel their Influence Token listing.
 *    - `useInfluenceForFeature(uint256 _influenceAmount, uint256 _featureType)`: Example function - Use influence tokens for platform features (e.g., content promotion).
 *
 * 5. **Admin & Utility Functions:**
 *    - `setReputationThresholds(uint256 _upvoteReputationReward, uint256 _downvoteReputationPenalty, uint256 _contentSubmissionReward)`: Admin function to set reputation reward/penalty values.
 *    - `pauseContract()`: Admin function to pause certain contract functionalities.
 *    - `unpauseContract()`: Admin function to unpause contract functionalities.
 *    - `withdrawContractBalance()`: Admin function to withdraw contract's ETH balance.
 */

pragma solidity ^0.8.0;

contract InfluenceSphere {
    // --- State Variables ---
    address public owner;
    bool public paused;

    // User Data
    mapping(address => string) public usernames; // User address to username
    mapping(address => uint256) public userReputation; // User address to reputation score
    mapping(address => uint256) public influenceTokenBalance; // User address to influence token balance
    uint256 public nextUserId = 1; // Simple User ID counter (not used in this example, but could be useful)

    // Content Data
    struct Content {
        uint256 id;
        address author;
        string contentHash;
        uint256 upvotes;
        uint256 downvotes;
        uint256 submissionTimestamp;
    }
    Content[] public contentList;
    uint256 public nextContentId = 1;

    // Influence Marketplace Data
    struct InfluenceListing {
        uint256 id;
        address seller;
        uint256 influenceAmount;
        uint256 pricePerToken;
        bool isActive;
    }
    mapping(uint256 => InfluenceListing) public influenceListings;
    uint256 public nextListingId = 1;

    // Reputation Thresholds & Parameters (Admin-configurable)
    uint256 public upvoteReputationReward = 5;
    uint256 public downvoteReputationPenalty = 2;
    uint256 public contentSubmissionReward = 10;
    uint256 public reputationToInfluenceRatio = 100; // 100 Reputation = 1 Influence Token

    // Events
    event UserRegistered(address user, string username);
    event ReputationIncreased(address user, uint256 amount, string reason);
    event ReputationDecreased(address user, uint256 amount, string reason);
    event ContentSubmitted(uint256 contentId, address author, string contentHash);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event InfluenceStaked(address user, uint256 reputationAmount, uint256 influenceAmount);
    event InfluenceUnstaked(address user, uint256 influenceAmount, uint256 reputationAmount);
    event InfluenceTokensTransferred(address from, address to, uint256 amount);
    event InfluenceListedForSale(uint256 listingId, address seller, uint256 influenceAmount, uint256 pricePerToken);
    event InfluencePurchased(uint256 listingId, address buyer, uint256 amount, uint256 totalPrice);
    event InfluenceListingCancelled(uint256 listingId);
    event InfluenceUsedForFeature(address user, uint256 influenceAmount, uint256 featureType);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier registeredUser() {
        require(bytes(usernames[msg.sender]).length > 0, "User not registered.");
        _;
    }

    // --- Constructor ---
    constructor(address _admin) {
        owner = _admin;
        paused = false;
        emit OwnershipTransferred(address(0), owner);
    }

    // --- Ownership Functions ---
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    // --- Pause/Unpause Functions ---
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- User Reputation System Functions ---
    function registerUser(string memory _username) public whenNotPaused {
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(bytes(usernames[msg.sender]).length == 0, "User already registered.");
        // In a real application, you'd want to check for username uniqueness more thoroughly
        usernames[msg.sender] = _username;
        userReputation[msg.sender] = 0; // Initial reputation
        emit UserRegistered(msg.sender, _username);
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    function increaseReputation(address _user, uint256 _amount) public onlyOwner {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, "Admin increase");
    }

    function decreaseReputation(address _user, uint256 _amount) public onlyOwner {
        require(userReputation[_user] >= _amount, "Reputation cannot go below zero.");
        userReputation[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, "Admin decrease");
    }

    function submitContent(string memory _contentHash) public whenNotPaused registeredUser {
        require(bytes(_contentHash).length > 0 && bytes(_contentHash).length <= 256, "Content hash must be between 1 and 256 characters.");
        contentList.push(Content({
            id: nextContentId,
            author: msg.sender,
            contentHash: _contentHash,
            upvotes: 0,
            downvotes: 0,
            submissionTimestamp: block.timestamp
        }));
        emit ContentSubmitted(nextContentId, msg.sender, _contentHash);
        userReputation[msg.sender] += contentSubmissionReward; // Reward for submitting content
        emit ReputationIncreased(msg.sender, contentSubmissionReward, "Content submission reward");
        nextContentId++;
    }

    function upvoteContent(uint256 _contentId) public whenNotPaused registeredUser {
        require(_contentId > 0 && _contentId < nextContentId, "Invalid content ID.");
        Content storage content = contentList[_contentId - 1]; // Adjust index for array
        // Prevent self-upvoting (optional, can be removed if self-upvotes are allowed)
        require(content.author != msg.sender, "Cannot upvote your own content.");
        // Prevent double upvoting (optional, can be tracked with a mapping)
        content.upvotes++;
        userReputation[content.author] += upvoteReputationReward;
        emit ContentUpvoted(_contentId, msg.sender);
        emit ReputationIncreased(content.author, upvoteReputationReward, "Content upvote reward");
    }

    function downvoteContent(uint256 _contentId) public whenNotPaused registeredUser {
        require(_contentId > 0 && _contentId < nextContentId, "Invalid content ID.");
        Content storage content = contentList[_contentId - 1]; // Adjust index for array
        // Prevent self-downvoting (optional)
        require(content.author != msg.sender, "Cannot downvote your own content.");
        // Prevent double downvoting (optional, can be tracked with a mapping)
        content.downvotes++;
        // Reputation penalty for author based on downvotes (optional - can be removed or adjusted)
        if (userReputation[content.author] >= downvoteReputationPenalty) {
            userReputation[content.author] -= downvoteReputationPenalty;
            emit ReputationDecreased(content.author, downvoteReputationPenalty, "Content downvote penalty");
        } else {
            userReputation[content.author] = 0; // Prevent negative reputation
            emit ReputationDecreased(content.author, userReputation[content.author], "Content downvote penalty (capped)");
        }
        emit ContentDownvoted(_contentId, msg.sender);
    }

    function reportContent(uint256 _contentId, string memory _reason) public whenNotPaused registeredUser {
        require(_contentId > 0 && _contentId < nextContentId, "Invalid content ID.");
        require(bytes(_reason).length > 0 && bytes(_reason).length <= 256, "Report reason must be between 1 and 256 characters.");
        emit ContentReported(_contentId, msg.sender, _reason);
        // In a real application, you would likely store reports and implement admin moderation logic
        // For example, create a mapping or array of reports for admin review.
        // This is a basic example, so we're just emitting an event.
    }

    // --- Influence Token & Staking Functions ---
    function stakeReputationForInfluence(uint256 _reputationAmount) public whenNotPaused registeredUser {
        require(userReputation[msg.sender] >= _reputationAmount, "Insufficient reputation to stake.");
        require(_reputationAmount > 0, "Reputation amount must be greater than zero.");

        uint256 influenceAmount = _reputationAmount / reputationToInfluenceRatio;
        userReputation[msg.sender] -= _reputationAmount;
        influenceTokenBalance[msg.sender] += influenceAmount;
        emit InfluenceStaked(msg.sender, _reputationAmount, influenceAmount);
    }

    function unstakeInfluence(uint256 _influenceAmount) public whenNotPaused registeredUser {
        require(influenceTokenBalance[msg.sender] >= _influenceAmount, "Insufficient influence tokens to unstake.");
        require(_influenceAmount > 0, "Influence amount must be greater than zero.");

        uint256 reputationAmount = _influenceAmount * reputationToInfluenceRatio;
        influenceTokenBalance[msg.sender] -= _influenceAmount;
        userReputation[msg.sender] += reputationAmount;
        emit InfluenceUnstaked(msg.sender, _influenceAmount, reputationAmount);
    }

    function getInfluenceTokenBalance(address _user) public view returns (uint256) {
        return influenceTokenBalance[_user];
    }

    function transferInfluenceTokens(address _recipient, uint256 _amount) public whenNotPaused registeredUser {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(_recipient != msg.sender, "Cannot transfer to yourself.");
        require(influenceTokenBalance[msg.sender] >= _amount, "Insufficient influence tokens to transfer.");
        require(_amount > 0, "Transfer amount must be greater than zero.");

        influenceTokenBalance[msg.sender] -= _amount;
        influenceTokenBalance[_recipient] += _amount;
        emit InfluenceTokensTransferred(msg.sender, _recipient, _amount);
    }

    // --- Influence Marketplace Functions ---
    function listInfluenceForSale(uint256 _influenceAmount, uint256 _pricePerToken) public whenNotPaused registeredUser {
        require(_influenceAmount > 0, "Influence amount to list must be greater than zero.");
        require(_pricePerToken > 0, "Price per token must be greater than zero.");
        require(influenceTokenBalance[msg.sender] >= _influenceAmount, "Insufficient influence tokens to list.");

        influenceListings[nextListingId] = InfluenceListing({
            id: nextListingId,
            seller: msg.sender,
            influenceAmount: _influenceAmount,
            pricePerToken: _pricePerToken,
            isActive: true
        });

        influenceTokenBalance[msg.sender] -= _influenceAmount; // Lock tokens for sale
        emit InfluenceListedForSale(nextListingId, msg.sender, _influenceAmount, _pricePerToken);
        nextListingId++;
    }

    function purchaseInfluence(uint256 _listingId, uint256 _amount) public payable whenNotPaused registeredUser {
        require(_listingId > 0 && _listingId < nextListingId, "Invalid listing ID.");
        InfluenceListing storage listing = influenceListings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller != msg.sender, "Cannot purchase from your own listing.");
        require(_amount > 0, "Purchase amount must be greater than zero.");
        require(_amount <= listing.influenceAmount, "Purchase amount exceeds available influence.");

        uint256 totalPrice = _amount * listing.pricePerToken;
        require(msg.value >= totalPrice, "Insufficient ETH sent for purchase.");

        listing.influenceAmount -= _amount;
        influenceTokenBalance[msg.sender] += _amount;

        // Transfer ETH to seller
        payable(listing.seller).transfer(totalPrice);

        emit InfluencePurchased(_listingId, msg.sender, _amount, totalPrice);

        if (listing.influenceAmount == 0) {
            listing.isActive = false; // Deactivate listing if all influence is sold
        }

        // Refund extra ETH if any
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function cancelInfluenceListing(uint256 _listingId) public whenNotPaused registeredUser {
        require(_listingId > 0 && _listingId < nextListingId, "Invalid listing ID.");
        InfluenceListing storage listing = influenceListings[_listingId];
        require(listing.isActive, "Listing is not active.");
        require(listing.seller == msg.sender, "Only seller can cancel listing.");

        listing.isActive = false;
        influenceTokenBalance[msg.sender] += listing.influenceAmount; // Return unsold tokens
        listing.influenceAmount = 0; // Reset amount to prevent issues

        emit InfluenceListingCancelled(_listingId);
    }

    function useInfluenceForFeature(uint256 _influenceAmount, uint256 _featureType) public whenNotPaused registeredUser {
        require(_influenceAmount > 0, "Influence amount must be greater than zero.");
        require(influenceTokenBalance[msg.sender] >= _influenceAmount, "Insufficient influence tokens for feature.");
        // Example Feature Types (can be extended):
        // 1: Content Promotion
        // 2: Premium Access
        // 3: ...

        influenceTokenBalance[msg.sender] -= _influenceAmount;
        emit InfluenceUsedForFeature(msg.sender, _influenceAmount, _featureType);

        // Implement logic for different feature types based on _featureType
        if (_featureType == 1) {
            // Content Promotion logic (e.g., prioritize user's content in feeds)
            // ... Implementation details for content promotion ...
        } else if (_featureType == 2) {
            // Premium Access logic (e.g., grant access to gated content)
            // ... Implementation details for premium access ...
        } else {
            // Handle unknown feature type or revert
            revert("Invalid feature type.");
        }
    }

    // --- Admin Configuration Functions ---
    function setReputationThresholds(
        uint256 _upvoteReward,
        uint256 _downvotePenalty,
        uint256 _contentReward
    ) public onlyOwner {
        upvoteReputationReward = _upvoteReward;
        downvoteReputationPenalty = _downvotePenalty;
        contentSubmissionReward = _contentReward;
    }

    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
```