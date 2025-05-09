Okay, here is a Solidity smart contract implementing a "SoulBound Subscription Service".

This contract issues non-transferable "SoulBound" tokens (SBTs) to users upon subscription. Each SBT represents an active subscription to a service, granting tiered access for a specific duration. The contract includes features for managing tiers, handling subscriptions (minting, renewing, upgrading, cancelling), calculating loyalty based on continuous subscription, managing administrative controls (pause, withdraw), and providing helper functions for checking access and subscription status.

It attempts to be creative by:
1.  Using SBTs for subscription status (non-transferable identity/access).
2.  Implementing tiered access directly within the contract.
3.  Including loyalty logic based on continuous subscription duration.
4.  Handling subscription upgrades with pro-rata cost calculation.
5.  Allowing for temporary access grants by the admin.

---

**Smart Contract: SoulBoundSubscription**

**Outline:**

1.  **State Variables:** Owner, Pausability, Reentrancy Guard, Tier data, Subscription data (SBT data), Temporary access data, Total revenue, Token metadata base URI.
2.  **Enums:** Subscription Status, Access Level.
3.  **Structs:** TierData, SubscriptionData, TemporaryAccessData.
4.  **Events:** SubscriptionMinted, SubscriptionRenewed, SubscriptionUpgraded, SubscriptionDeactivated, TierAdded, TierUpdated, TierDeactivated, FundsWithdrawn, TemporaryAccessGranted, TemporaryAccessRevoked, Paused, Unpaused, OwnershipTransferred.
5.  **Modifiers:** onlyOwner, whenNotPaused, whenPaused, onlyActiveSubscriber, onlyMinimumAccessLevel.
6.  **Core Logic:**
    *   Constructor: Initializes owner.
    *   Tier Management: Add, update, deactivate tiers (owner only).
    *   Subscription Management: Mint, renew, upgrade, deactivate (user initiated or admin).
    *   SBT Representation: Data storage, `tokenURI`.
    *   Access Control: Check active subscription, check access level, grant/revoke temporary access.
    *   Loyalty: Calculate continuous subscription duration.
    *   Financials: Receive Ether, withdraw funds.
    *   Administrative: Pause/unpause, transfer ownership, set token URI.
    *   Queries: Get details about tiers, subscriptions, temporary access, stats.

**Function Summary:**

1.  `constructor()`: Sets contract owner.
2.  `addTier(uint256 _tierId, string memory _name, uint256 _price, uint256 _durationInSeconds, AccessLevel _accessLevel)`: Owner adds a new subscription tier.
3.  `updateTier(uint256 _tierId, string memory _name, uint256 _price, uint256 _durationInSeconds, AccessLevel _accessLevel, bool _isActive)`: Owner updates details of an existing tier.
4.  `deactivateTier(uint256 _tierId)`: Owner deactivates a tier, preventing new subscriptions to it.
5.  `getTierDetails(uint256 _tierId)`: Get details for a specific tier.
6.  `getAllTierIds()`: Get a list of all defined tier IDs.
7.  `mintSubscription(uint256 _tierId)`: User subscribes for the first time. Requires payment matching tier price. Mints an SBT for the user's address.
8.  `renewSubscription(uint256 _tierId)`: User renews their subscription, potentially changing tiers. Requires payment. Extends expiration time.
9.  `upgradeSubscription(uint256 _newTierId)`: User upgrades their *active* subscription mid-cycle to a higher tier. Calculates pro-rata cost.
10. `calculateUpgradeCost(uint256 _newTierId)`: Calculates the required payment for an upgrade from the user's current active tier.
11. `deactivateSubscription(address _user)`: Admin can deactivate a user's subscription (e.g., for terms violation). User can also call on themselves to signal cancellation (though it doesn't refund).
12. `hasActiveSubscription(address _user)`: Checks if a user currently has an active subscription.
13. `getSubscriptionDetails(address _user)`: Get detailed info about a user's current (or past) subscription.
14. `getAccessLevel(address _user)`: Get the access level granted by a user's current active subscription. Includes temporary access logic.
15. `checkFeatureAccess(address _user, AccessLevel _requiredLevel)`: Helper function to check if a user meets a minimum access level.
16. `getContinuousSubscriptionDuration(address _user)`: Calculates how long a user has held a subscription *continuously* since their first mint or last lapse.
17. `grantTemporaryAccess(address _user, AccessLevel _level, uint256 _durationInSeconds)`: Owner grants temporary access to a user without a subscription.
18. `revokeTemporaryAccess(address _user)`: Owner revokes any temporary access for a user.
19. `getTemporaryAccessDetails(address _user)`: Get details of a user's temporary access.
20. `withdrawFunds()`: Owner withdraws accumulated contract balance.
21. `pauseContract()`: Owner pauses contract (prevents state-changing user actions).
22. `unpauseContract()`: Owner unpauses contract.
23. `getOwner()`: Get contract owner address.
24. `transferOwnership(address newOwner)`: Owner transfers ownership.
25. `setBaseTokenURI(string memory _newBaseTokenURI)`: Owner sets the base URI for SBT metadata.
26. `tokenURI(uint256 _tokenId)`: Returns the metadata URI for a specific SBT (using address as ID).
27. `getTotalActiveSubscribers()`: Get the total count of currently active subscribers.
28. `getSubscriberCountByTier(uint256 _tierId)`: Get the count of active subscribers for a specific tier.
29. `getTotalRevenue()`: Get the total Ether received by the contract.
30. `getSubscriptionStatusText(address _user)`: Get a human-readable status ("None", "Active", "Expired").
31. `hasEverSubscribed(address _user)`: Checks if the user address exists in the subscription data mapping.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// SoulBound Subscription Service Contract

// Outline:
// 1. State Variables: Owner, Pausability, Reentrancy Guard, Tier data, Subscription data (SBT data), Temporary access data, Total revenue, Token metadata base URI.
// 2. Enums: Subscription Status, Access Level.
// 3. Structs: TierData, SubscriptionData, TemporaryAccessData.
// 4. Events: SubscriptionMinted, SubscriptionRenewed, SubscriptionUpgraded, SubscriptionDeactivated, TierAdded, TierUpdated, TierDeactivated, FundsWithdrawn, TemporaryAccessGranted, TemporaryAccessRevoked, Paused, Unpaused, OwnershipTransferred.
// 5. Modifiers: onlyOwner, whenNotPaused, whenPaused, onlyActiveSubscriber, onlyMinimumAccessLevel.
// 6. Core Logic:
//    - Constructor: Initializes owner.
//    - Tier Management: Add, update, deactivate tiers (owner only).
//    - Subscription Management: Mint, renew, upgrade, deactivate (user initiated or admin).
//    - SBT Representation: Data storage, `tokenURI`.
//    - Access Control: Check active subscription, check access level, grant/revoke temporary access.
//    - Loyalty: Calculate continuous subscription duration.
//    - Financials: Receive Ether, withdraw funds.
//    - Administrative: Pause/unpause, transfer ownership, set token URI.
//    - Queries: Get details about tiers, subscriptions, temporary access, stats.

contract SoulBoundSubscription is Ownable, Pausable, ReentrancyGuard {

    using Counters for Counters.Counter;

    // --- Enums ---
    enum SubscriptionStatus { None, Active, Expired }
    enum AccessLevel { None, Bronze, Silver, Gold, Platinum } // Example levels

    // --- Structs ---

    struct TierData {
        string name;
        uint256 price; // in wei
        uint256 durationInSeconds;
        AccessLevel accessLevel;
        bool isActive; // Can new subscriptions be created for this tier?
    }

    struct SubscriptionData {
        uint256 tierId;
        uint256 expirationTime; // Timestamp when subscription expires
        uint256 mintTimestamp; // Timestamp of initial mint
        uint256 lastRenewalTimestamp; // Timestamp of last mint or renewal
        bool exists; // To differentiate between non-existent and expired/inactive
    }

    struct TemporaryAccessData {
        AccessLevel level;
        uint256 expirationTime;
        bool exists;
    }

    // --- State Variables ---

    // Tier configuration: tierId => TierData
    mapping(uint256 => TierData) public tiers;
    uint256[] public tierIds; // To iterate through available tiers

    // Subscription data: userAddress => SubscriptionData (SBT data)
    mapping(address => SubscriptionData) private subscriptions;

    // Temporary access data: userAddress => TemporaryAccessData
    mapping(address => TemporaryAccessData) private temporaryAccess;

    // Total Ether received by the contract
    uint256 public totalRevenue;

    // Base URI for SoulBound Token metadata
    string private _baseTokenURI;

    // --- Events ---

    event SubscriptionMinted(address indexed user, uint256 tierId, uint256 expirationTime, uint256 mintTimestamp);
    event SubscriptionRenewed(address indexed user, uint256 oldTierId, uint256 newTierId, uint255 oldExpirationTime, uint256 newExpirationTime);
    event SubscriptionUpgraded(address indexed user, uint256 oldTierId, uint256 newTierId, uint255 oldExpirationTime, uint256 newExpirationTime, uint256 amountPaid);
    event SubscriptionDeactivated(address indexed user, string reason); // Reason could be "expired", "cancelled", "admin"

    event TierAdded(uint256 tierId, string name, uint256 price, uint256 duration, AccessLevel accessLevel);
    event TierUpdated(uint256 tierId, string name, uint256 price, uint256 duration, AccessLevel accessLevel, bool isActive);
    event TierDeactivated(uint256 tierId);

    event FundsReceived(address indexed from, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    event TemporaryAccessGranted(address indexed user, AccessLevel level, uint256 expirationTime);
    event TemporaryAccessRevoked(address indexed user);

    // OpenZeppelin Pausable & Ownable events are inherited

    // --- Modifiers ---

    modifier onlyActiveSubscriber(address _user) {
        require(hasActiveSubscription(_user), "Subscriber: Not active");
        _;
    }

    modifier onlyMinimumAccessLevel(address _user, AccessLevel _requiredLevel) {
        require(getAccessLevel(_user) >= _requiredLevel, "Access Control: Insufficient access level");
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) Pausable(false) {}

    // --- Tier Management (Owner Only) ---

    /**
     * @dev Adds a new subscription tier.
     * @param _tierId Unique identifier for the tier.
     * @param _name Name of the tier (e.g., "Gold Monthly").
     * @param _price Price of the tier in wei.
     * @param _durationInSeconds Duration of the subscription if purchased at this tier.
     * @param _accessLevel The access level granted by this tier.
     */
    function addTier(uint256 _tierId, string memory _name, uint256 _price, uint256 _durationInSeconds, AccessLevel _accessLevel) external onlyOwner {
        require(!tiers[_tierId].exists, "Tier: ID already exists");
        require(_price > 0, "Tier: Price must be greater than 0");
        require(_durationInSeconds > 0, "Tier: Duration must be greater than 0");
        require(_accessLevel > AccessLevel.None, "Tier: Access level must be greater than None");

        tiers[_tierId] = TierData({
            name: _name,
            price: _price,
            durationInSeconds: _durationInSeconds,
            accessLevel: _accessLevel,
            isActive: true,
            exists: true // Add exists check for mapping lookups
        });

        tierIds.push(_tierId);

        emit TierAdded(_tierId, _name, _price, _durationInSeconds, _accessLevel);
    }

    /**
     * @dev Updates an existing subscription tier.
     * @param _tierId Identifier of the tier to update.
     * @param _name New name.
     * @param _price New price.
     * @param _durationInSeconds New duration.
     * @param _accessLevel New access level.
     * @param _isActive New active status.
     */
    function updateTier(uint256 _tierId, string memory _name, uint256 _price, uint256 _durationInSeconds, AccessLevel _accessLevel, bool _isActive) external onlyOwner {
        TierData storage tier = tiers[_tierId];
        require(tier.exists, "Tier: ID does not exist");
        require(_price > 0, "Tier: Price must be greater than 0");
        require(_durationInSeconds > 0, "Tier: Duration must be greater than 0");
        require(_accessLevel > AccessLevel.None, "Tier: Access level must be greater than None");

        tier.name = _name;
        tier.price = _price;
        tier.durationInSeconds = _durationInSeconds;
        tier.accessLevel = _accessLevel;
        tier.isActive = _isActive;

        emit TierUpdated(_tierId, _name, _price, _durationInSeconds, _accessLevel, _isActive);
    }

     /**
     * @dev Deactivates a tier, preventing new subscriptions or renewals to it.
     * Existing subscribers keep their tier until expiration.
     * @param _tierId Identifier of the tier to deactivate.
     */
    function deactivateTier(uint256 _tierId) external onlyOwner {
        TierData storage tier = tiers[_tierId];
        require(tier.exists, "Tier: ID does not exist");
        require(tier.isActive, "Tier: Already inactive");

        tier.isActive = false;

        emit TierDeactivated(_tierId);
    }


    /**
     * @dev Gets details for a specific tier.
     * @param _tierId Identifier of the tier.
     * @return TierData struct.
     */
    function getTierDetails(uint256 _tierId) external view returns (TierData memory) {
         require(tiers[_tierId].exists, "Tier: ID does not exist");
         return tiers[_tierId];
    }

    /**
     * @dev Gets a list of all defined tier IDs.
     * @return Array of tier IDs.
     */
    function getAllTierIds() external view returns (uint256[] memory) {
        return tierIds;
    }

    // --- Subscription Management ---

    /**
     * @dev Mints a new SoulBound Subscription token (SBT) for the caller.
     * This is for the initial subscription purchase.
     * Reverts if the caller already has a subscription.
     * @param _tierId The ID of the tier to subscribe to.
     */
    function mintSubscription(uint256 _tierId) external payable whenNotPaused nonReentrant {
        SubscriptionData storage sub = subscriptions[msg.sender];
        require(!sub.exists || sub.expirationTime <= block.timestamp, "Subscription: User already has an active or expired subscription record");

        TierData storage tier = tiers[_tierId];
        require(tier.exists && tier.isActive, "Subscription: Invalid or inactive tier ID");
        require(msg.value >= tier.price, "Subscription: Insufficient payment");

        uint256 expiration = block.timestamp + tier.durationInSeconds;

        subscriptions[msg.sender] = SubscriptionData({
            tierId: _tierId,
            expirationTime: expiration,
            mintTimestamp: block.timestamp,
            lastRenewalTimestamp: block.timestamp,
            exists: true
        });

        totalRevenue += msg.value;

        emit SubscriptionMinted(msg.sender, _tierId, expiration, block.timestamp);
        if (msg.value > tier.price) {
             // Refund excess Ether
            payable(msg.sender).transfer(msg.value - tier.price);
        }
         emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Renews an existing subscription for the caller. Can change tiers.
     * Requires the user to have an existing subscription record (active or expired).
     * @param _tierId The ID of the tier to renew into.
     */
    function renewSubscription(uint256 _tierId) external payable whenNotPaused nonReentrant {
        SubscriptionData storage sub = subscriptions[msg.sender];
        require(sub.exists, "Subscription: No existing subscription found for user");

        TierData storage newTier = tiers[_tierId];
        require(newTier.exists && newTier.isActive, "Subscription: Invalid or inactive tier ID");
        require(msg.value >= newTier.price, "Subscription: Insufficient payment");

        uint256 oldTierId = sub.tierId;
        uint256 oldExpirationTime = sub.expirationTime;

        // Calculate new expiration time. If currently active, add duration from current expiration. Otherwise, add from now.
        uint256 startOfNewDuration = sub.expirationTime > block.timestamp ? sub.expirationTime : block.timestamp;
        uint256 newExpirationTime = startOfNewDuration + newTier.durationInSeconds;

        sub.tierId = _tierId;
        sub.expirationTime = newExpirationTime;
        sub.lastRenewalTimestamp = block.timestamp;
        // mintTimestamp remains the same for loyalty tracking from first subscription

        totalRevenue += msg.value;

        emit SubscriptionRenewed(msg.sender, oldTierId, _tierId, oldExpirationTime, newExpirationTime);
        if (msg.value > newTier.price) {
             // Refund excess Ether
            payable(msg.sender).transfer(msg.value - newTier.price);
        }
        emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Upgrades an *active* subscription mid-cycle to a higher access level tier.
     * Calculates a pro-rata cost based on the remaining time of the current subscription.
     * @param _newTierId The ID of the new tier to upgrade to.
     */
    function upgradeSubscription(uint256 _newTierId) external payable whenNotPaused nonReentrant onlyActiveSubscriber(msg.sender) {
        SubscriptionData storage sub = subscriptions[msg.sender];
        TierData storage currentTier = tiers[sub.tierId];
        TierData storage newTier = tiers[_newTierId];

        require(newTier.exists && newTier.isActive, "Upgrade: Invalid or inactive new tier ID");
        require(newTier.accessLevel > currentTier.accessLevel, "Upgrade: New tier must have a higher access level");

        uint256 requiredPayment = calculateUpgradeCost(_newTierId);
        require(msg.value >= requiredPayment, "Upgrade: Insufficient payment for upgrade");

        uint256 oldTierId = sub.tierId;
        uint256 oldExpirationTime = sub.expirationTime;

        // Keep the same expiration time, just change the tier and loyalty timestamp
        sub.tierId = _newTierId;
        sub.lastRenewalTimestamp = block.timestamp; // Reset loyalty time if we base it on continuous highest tier

        totalRevenue += msg.value;

        emit SubscriptionUpgraded(msg.sender, oldTierId, _newTierId, oldExpirationTime, sub.expirationTime, msg.value);
         if (msg.value > requiredPayment) {
             // Refund excess Ether
            payable(msg.sender).transfer(msg.value - requiredPayment);
        }
         emit FundsReceived(msg.sender, msg.value);
    }

    /**
     * @dev Calculates the pro-rata cost to upgrade an active subscription.
     * Cost = (Price of New Tier) - (Value of Remaining time on Current Tier)
     * Value of Remaining Time = (Price of Current Tier / Duration of Current Tier) * Remaining Time
     * @param _newTierId The ID of the tier to upgrade to.
     * @return The required payment amount in wei.
     */
    function calculateUpgradeCost(uint256 _newTierId) public view onlyActiveSubscriber(msg.sender) returns (uint256) {
        SubscriptionData storage sub = subscriptions[msg.sender];
        TierData storage currentTier = tiers[sub.tierId];
        TierData storage newTier = tiers[_newTierId];

        require(newTier.exists, "Calculate: Invalid new tier ID");
        require(newTier.accessLevel > currentTier.accessLevel, "Calculate: New tier must have a higher access level");

        uint256 currentTime = block.timestamp;
        require(sub.expirationTime > currentTime, "Calculate: Subscription is not active");

        uint256 remainingTime = sub.expirationTime - currentTime;

        // Avoid division by zero if tier duration was set to 0 (should be prevented by add/updateTier)
        if (currentTier.durationInSeconds == 0) {
             // This should not happen with require checks, but as a safeguard
            return newTier.price;
        }

        // Calculate the value of the remaining time on the current subscription
        uint256 remainingValue = (currentTier.price * remainingTime) / currentTier.durationInSeconds;

        // Cost to upgrade is the new price minus the remaining value of the old subscription
        uint256 requiredPayment = newTier.price > remainingValue ? newTier.price - remainingValue : 0;

        return requiredPayment;
    }


    /**
     * @dev Deactivates a user's subscription record. Can be called by admin or the user themselves.
     * User calling it acts as a cancellation signal (no refund). Admin can force deactivate.
     * @param _user The address of the user whose subscription to deactivate.
     */
    function deactivateSubscription(address _user) external whenNotPaused {
        SubscriptionData storage sub = subscriptions[_user];
        require(sub.exists, "Subscription: No subscription found for user");
        require(msg.sender == _user || msg.sender == owner(), "Subscription: Only user or owner can deactivate");

        // Set expiration to now or past to mark as inactive
        sub.expirationTime = block.timestamp;

        // Set exists to false to remove the record entirely if desired,
        // but keeping it allows tracking past subscribers. Let's keep exists true
        // but rely on expirationTime for active status.
        // If you wanted to allow re-minting after deactivation by user, you'd need
        // more complex logic or allow mintSubscription on expired records.
        // Current mintSubscription allows minting if expired.

        emit SubscriptionDeactivated(_user, msg.sender == _user ? "cancelled" : "admin_deactivated");
    }

    // --- SBT & Access Control Queries ---

     /**
     * @dev Checks if a user currently has an active subscription (SBT is valid).
     * @param _user The address to check.
     * @return bool True if active, false otherwise.
     */
    function hasActiveSubscription(address _user) public view returns (bool) {
        SubscriptionData storage sub = subscriptions[_user];
        return sub.exists && sub.expirationTime > block.timestamp;
    }

    /**
     * @dev Gets detailed information about a user's subscription.
     * @param _user The address to check.
     * @return tierId, expirationTime, mintTimestamp, lastRenewalTimestamp, exists, status (enum).
     */
    function getSubscriptionDetails(address _user) external view returns (
        uint256 tierId,
        uint256 expirationTime,
        uint256 mintTimestamp,
        uint256 lastRenewalTimestamp,
        bool exists,
        SubscriptionStatus status
    ) {
        SubscriptionData storage sub = subscriptions[_user];
        tierId = sub.tierId;
        expirationTime = sub.expirationTime;
        mintTimestamp = sub.mintTimestamp;
        lastRenewalTimestamp = sub.lastRenewalTimestamp;
        exists = sub.exists;

        if (!exists) {
            status = SubscriptionStatus.None;
        } else if (expirationTime > block.timestamp) {
            status = SubscriptionStatus.Active;
        } else {
            status = SubscriptionStatus.Expired;
        }
        return (tierId, expirationTime, mintTimestamp, lastRenewalTimestamp, exists, status);
    }

    /**
     * @dev Gets the highest access level for a user, considering both active subscription and temporary access.
     * @param _user The address to check.
     * @return AccessLevel enum.
     */
    function getAccessLevel(address _user) public view returns (AccessLevel) {
        AccessLevel subscriptionLevel = AccessLevel.None;
        if (hasActiveSubscription(_user)) {
            TierData storage tier = tiers[subscriptions[_user].tierId];
            if (tier.exists) { // Should always exist if subscription is active
                 subscriptionLevel = tier.accessLevel;
            }
        }

        AccessLevel temporaryLevel = AccessLevel.None;
        TemporaryAccessData storage tempAccess = temporaryAccess[_user];
        if (tempAccess.exists && tempAccess.expirationTime > block.timestamp) {
            temporaryLevel = tempAccess.level;
        }

        // Return the higher of the two levels
        return subscriptionLevel > temporaryLevel ? subscriptionLevel : temporaryLevel;
    }

    /**
     * @dev Helper function to check if a user's current access level meets a minimum requirement.
     * Can be used by other contracts or functions.
     * @param _user The address to check.
     * @param _requiredLevel The minimum access level required.
     * @return bool True if the user meets the level, false otherwise.
     */
    function checkFeatureAccess(address _user, AccessLevel _requiredLevel) public view returns (bool) {
        return getAccessLevel(_user) >= _requiredLevel;
    }


     /**
     * @dev Calculates the duration the user has held a subscription *continuously*.
     * A break in subscription resets this duration.
     * Based on mintTimestamp for first subscription, or lastRenewalTimestamp if subscription lapsed and was renewed.
     * Note: This simple implementation tracks continuous time from the *most recent* mint/renewal
     * *IF* the subscription is currently active. If it's expired, it returns 0.
     * A more robust loyalty might track total time ever active, which is more complex.
     * This version assumes "continuous" means from the last time they became active without lapsing.
     * A lapse and re-mint/renew starts the continuous clock over.
     * @param _user The address to check.
     * @return uint256 Duration in seconds. Returns 0 if not currently active.
     */
    function getContinuousSubscriptionDuration(address _user) public view returns (uint256) {
        SubscriptionData storage sub = subscriptions[_user];
        if (!hasActiveSubscription(_user)) {
            return 0; // Not continuously active
        }
        // Simple approach: continuous duration is time since the subscription became active or was last renewed.
        // This requires careful logic if you allow renewals *after* expiration.
        // If renewal extends from current expiration, lastRenewalTimestamp represents the start of the *latest* period added.
        // If renewal starts from *now* when expired, lastRenewalTimestamp is now.
        // Let's assume lastRenewalTimestamp is the timestamp when the *current active period* began (either mint or renewal).
        return block.timestamp - sub.lastRenewalTimestamp;
    }


    // --- Temporary Access (Owner Only) ---

    /**
     * @dev Grants temporary access to a user. Overrides subscription access if higher.
     * @param _user The address to grant access to.
     * @param _level The access level to grant temporarily.
     * @param _durationInSeconds How long the temporary access lasts from now.
     */
    function grantTemporaryAccess(address _user, AccessLevel _level, uint256 _durationInSeconds) external onlyOwner whenNotPaused {
        require(_user != address(0), "Temporary Access: Invalid address");
        require(_level > AccessLevel.None, "Temporary Access: Level must be greater than None");
        require(_durationInSeconds > 0, "Temporary Access: Duration must be greater than 0");

        temporaryAccess[_user] = TemporaryAccessData({
            level: _level,
            expirationTime: block.timestamp + _durationInSeconds,
            exists: true
        });

        emit TemporaryAccessGranted(_user, _level, temporaryAccess[_user].expirationTime);
    }

    /**
     * @dev Revokes any temporary access for a user immediately.
     * @param _user The address whose temporary access to revoke.
     */
    function revokeTemporaryAccess(address _user) external onlyOwner {
        TemporaryAccessData storage tempAccess = temporaryAccess[_user];
        require(tempAccess.exists && tempAccess.expirationTime > block.timestamp, "Temporary Access: No active temporary access found");

        tempAccess.expirationTime = block.timestamp; // Mark as expired immediately

        emit TemporaryAccessRevoked(_user);
    }

    /**
     * @dev Gets details about a user's temporary access.
     * @param _user The address to check.
     * @return level, expirationTime, exists (if a record exists, active or expired).
     */
    function getTemporaryAccessDetails(address _user) external view returns (AccessLevel level, uint256 expirationTime, bool exists) {
        TemporaryAccessData storage tempAccess = temporaryAccess[_user];
        return (tempAccess.level, tempAccess.expirationTime, tempAccess.exists);
    }


    // --- Financials ---

     /**
     * @dev Receives Ether sent to the contract. Automatically triggered on payment functions.
     */
    receive() external payable {
        // This receive function allows the contract to accept Ether directly.
        // Payments for subscriptions should primarily go through the payable functions (mint, renew, upgrade).
        // This is here as a fallback or for direct donations, logging the event.
         emit FundsReceived(msg.sender, msg.value);
         // totalRevenue += msg.value; // Don't add direct sends to totalRevenue unless they are explicitly for subscription.
                                     // totalRevenue is incremented only in mint/renew/upgrade.
    }

    /**
     * @dev Owner can withdraw the accumulated Ether balance.
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Withdraw: No funds to withdraw");

        totalRevenue -= balance; // Decrement total revenue by withdrawn amount (simple tracking)

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw: Failed to send Ether");

        emit FundsWithdrawn(owner(), balance);
    }

    // --- Administrative Controls ---

    /**
     * @dev Pauses the contract. Prevents state-changing user interactions like minting or renewing.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    // transferOwnership is inherited from Ownable

     /**
     * @dev Sets the base URI for the SBT metadata. Token URI will be baseURI + tokenId.json.
     * @param _newBaseTokenURI The new base URI string.
     */
    function setBaseTokenURI(string memory _newBaseTokenURI) external onlyOwner {
        _baseTokenURI = _newBaseTokenURI;
    }

    /**
     * @dev Returns the base URI for SBT metadata.
     */
    function getBaseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }


    // --- SoulBound Token (SBT) Specific Functions ---

    // Note: This contract does NOT implement the full ERC721 standard
    // as SBTs are non-transferable and user address maps directly to the "token".
    // We only implement the tokenURI function relevant for metadata.

    /**
     * @dev Returns the URI for metadata of a given token ID (which is the user's address).
     * Follows ERC721 metadata URI convention.
     * @param _tokenId The token ID (user address cast to uint256).
     * @return string The metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        // Convert uint256 token ID back to address
        address userAddress = address(uint160(_tokenId));

        // Check if a subscription record exists for this address
        // We return a URI even for expired/inactive subscriptions to allow metadata retrieval
        if (!subscriptions[userAddress].exists) {
             return string(abi.encodePacked(_baseTokenURI, "nonexistent")); // Or revert, depending on desired behavior for non-subscribers/non-ever-subscribers
        }

        // Standard ERC721 metadata URI format: baseURI + token ID.json
        // We use the user's address string representation as the "token ID" in the URI path
        return string(abi.encodePacked(_baseTokenURI, Strings.toHexString(userAddress), ".json"));
    }

    // --- Statistics and Query Functions ---

     /**
     * @dev Gets the total count of currently active subscribers.
     * Note: This requires iterating through all possible addresses or maintaining a separate count.
     * Iterating is gas-prohibitive for large numbers. A state variable counter is better but
     * needs careful increment/decrement logic in mint/renew/deactivate/expiration checks.
     * Implementing a simple, potentially expensive, query for demonstration.
     * A gas-efficient approach would be to maintain `activeSubscriberCount` state variable.
     * Let's implement the state variable approach for efficiency.
     */
    uint256 private _activeSubscriberCount = 0; // State variable for efficiency

     /**
     * @dev Internal helper to update the active subscriber count.
     */
    function _updateActiveSubscriberCount(address _user, bool isActive) internal {
        bool wasActive = subscriptions[_user].exists && subscriptions[_user].expirationTime > block.timestamp;

        if (isActive && !wasActive) {
             _activeSubscriberCount++;
        } else if (!isActive && wasActive) {
             _activeSubscriberCount--;
        }
         // If status didn't change (was inactive/expired and stayed, or was active and stayed), count doesn't change.
    }

     // Override _pause and _unpause to include potential count adjustment checks (though not strictly necessary here)
    function _pause() internal override {
        super._pause();
    }

    function _unpause() internal override {
        super._unpause();
    }

     // Modify subscription functions to update count
    function mintSubscription(uint256 _tierId) external payable override whenNotPaused nonReentrant {
         // ... existing checks ...
         require(!subscriptions[msg.sender].exists || subscriptions[msg.sender].expirationTime <= block.timestamp, "Subscription: User already has an active or expired subscription record");

         // ... mint logic ...
        subscriptions[msg.sender] = SubscriptionData({/* ... data ... */ exists: true});
        totalRevenue += msg.value;

        _updateActiveSubscriberCount(msg.sender, true); // User becomes active

         // ... event and refund ...
         emit SubscriptionMinted(msg.sender, _tierId, subscriptions[msg.sender].expirationTime, subscriptions[msg.sender].mintTimestamp);
         if (msg.value > tiers[_tierId].price) { payable(msg.sender).transfer(msg.value - tiers[_tierId].price); }
         emit FundsReceived(msg.sender, msg.value);
    }

     function renewSubscription(uint256 _tierId) external payable override whenNotPaused nonReentrant {
         // ... existing checks ...
         SubscriptionData storage sub = subscriptions[msg.sender];
         require(sub.exists, "Subscription: No existing subscription found for user");
         bool wasActive = sub.expirationTime > block.timestamp; // Check active status *before* renewal

         // ... renewal logic ...
         sub.expirationTime = block.timestamp > sub.expirationTime ? block.timestamp + tiers[_tierId].durationInSeconds : sub.expirationTime + tiers[_tierId].durationInSeconds;
         sub.tierId = _tierId;
         sub.lastRenewalTimestamp = block.timestamp; // Assuming this marks the start of the new active period for loyalty

         totalRevenue += msg.value;

         _updateActiveSubscriberCount(msg.sender, true); // User is now active (or remains active)

         // ... event and refund ...
         emit SubscriptionRenewed(msg.sender, sub.tierId, _tierId, sub.expirationTime - tiers[_tierId].durationInSeconds, sub.expirationTime); // old expiration is calculated back
         if (msg.value > tiers[_tierId].price) { payable(msg.sender).transfer(msg.value - tiers[_tierId].price); }
         emit FundsReceived(msg.sender, msg.value);
     }

     function upgradeSubscription(uint256 _newTierId) external payable override whenNotPaused nonReentrant onlyActiveSubscriber(msg.sender) {
         // ... existing checks and calculation ...
         uint256 requiredPayment = calculateUpgradeCost(_newTierId);
         require(msg.value >= requiredPayment, "Upgrade: Insufficient payment for upgrade");

         SubscriptionData storage sub = subscriptions[msg.sender];
         uint256 oldTierId = sub.tierId;
         uint256 oldExpirationTime = sub.expirationTime;

         // ... upgrade logic ...
         sub.tierId = _newTierId;
         sub.lastRenewalTimestamp = block.timestamp; // Mark the time of upgrade for loyalty logic adjustment

         totalRevenue += msg.value;

         // Active status doesn't change, so no need to update _activeSubscriberCount

         // ... event and refund ...
         emit SubscriptionUpgraded(msg.sender, oldTierId, _newTierId, oldExpirationTime, sub.expirationTime, msg.value);
         if (msg.value > requiredPayment) { payable(msg.sender).transfer(msg.value - requiredPayment); }
         emit FundsReceived(msg.sender, msg.value);
     }

     function deactivateSubscription(address _user) external override whenNotPaused {
         SubscriptionData storage sub = subscriptions[_user];
         require(sub.exists, "Subscription: No subscription found for user");
         require(msg.sender == _user || msg.sender == owner(), "Subscription: Only user or owner can deactivate");

         bool wasActive = sub.expirationTime > block.timestamp;

         // Set expiration to now or past to mark as inactive
         sub.expirationTime = block.timestamp;

         if (wasActive) {
             _activeSubscriberCount--; // User is no longer active
         }

         emit SubscriptionDeactivated(_user, msg.sender == _user ? "cancelled" : "admin_deactivated");
     }

    /**
     * @dev Gets the total count of currently active subscribers. Gas efficient using state variable.
     * @return uint256 Count of active subscribers.
     */
    function getTotalActiveSubscribers() external view returns (uint256) {
        return _activeSubscriberCount;
    }

    /**
     * @dev Gets the count of active subscribers for a specific tier.
     * Note: Maintaining this count accurately requires iterating or complex state management on renewals/upgrades/expiration.
     * A gas-efficient approach requires a mapping `tierId => count`. Expiration handling is the tricky part.
     * Implementing a simple iteration for demonstration, which can be expensive.
     * A gas-efficient solution would involve a background process or off-chain calculation, or tracking per-tier counts during updates.
     * Let's add a mapping and update it in mint/renew/upgrade, but acknowledge expiration drift might occur unless a check is added.
     * Implementing a gas-efficient version:
     */
     mapping(uint256 => uint256) private _activeSubscribersByTier;

    // Need to adjust mint, renew, upgrade, deactivate to update _activeSubscribersByTier
    // This adds complexity: when a subscription expires, the count for its tier needs to decrease.
    // On-chain contracts cannot reliably trigger actions *exactly* at expiration without external help.
    // A common pattern is to adjust counts lazily when a user interacts *after* expiration, or accept some drift.
    // For this contract, let's accept potential minor drift and update counts on state changes (mint, renew, upgrade, deactivate).
    // The count might be slightly high if subscribers expire without further interaction.

    // Adjust mint, renew, upgrade, deactivate again to update _activeSubscribersByTier

    function mintSubscription(uint256 _tierId) external payable override whenNotPaused nonReentrant {
        // ... existing checks ...
        SubscriptionData storage sub = subscriptions[msg.sender];
        bool wasActive = sub.exists && sub.expirationTime > block.timestamp;

        // ... mint logic ...
        subscriptions[msg.sender] = SubscriptionData({/* ... data ... */ exists: true});
        totalRevenue += msg.value;

        if (!wasActive) { // User becomes active for the first time
             _activeSubscriberCount++;
             _activeSubscribersByTier[_tierId]++; // Add to the new tier count
        }
         // If they had an expired record and now mint, they become active and get counted.

        // ... event and refund ...
         emit SubscriptionMinted(msg.sender, _tierId, subscriptions[msg.sender].expirationTime, subscriptions[msg.sender].mintTimestamp);
         if (msg.value > tiers[_tierId].price) { payable(msg.sender).transfer(msg.value - tiers[_tierId].price); }
         emit FundsReceived(msg.sender, msg.value);
    }

     function renewSubscription(uint256 _tierId) external payable override whenNotPaused nonReentrant {
         // ... existing checks ...
         SubscriptionData storage sub = subscriptions[msg.sender];
         require(sub.exists, "Subscription: No existing subscription found for user");
         bool wasActive = sub.expirationTime > block.timestamp; // Check active status *before* renewal
         uint256 oldTierId = sub.tierId;

         // ... renewal logic ...
         sub.expirationTime = block.timestamp > sub.expirationTime ? block.timestamp + tiers[_tierId].durationInSeconds : sub.expirationTime + tiers[_tierId].durationInSeconds;
         sub.tierId = _tierId;
         sub.lastRenewalTimestamp = block.timestamp;

         totalRevenue += msg.value;

         if (!wasActive) { // User was expired, now active
             _activeSubscriberCount++;
             _activeSubscribersByTier[_tierId]++;
         } else if (oldTierId != _tierId) { // Was active, changing tier
             _activeSubscribersByTier[oldTierId]--;
             _activeSubscribersByTier[_tierId]++;
         }
         // If was active and same tier, counts don't change.

         // ... event and refund ...
          emit SubscriptionRenewed(msg.sender, oldTierId, _tierId, sub.expirationTime - tiers[_tierId].durationInSeconds, sub.expirationTime); // old expiration is calculated back
         if (msg.value > tiers[_tierId].price) { payable(msg.sender).transfer(msg.value - tiers[_tierId].price); }
         emit FundsReceived(msg.sender, msg.value);
     }

     function upgradeSubscription(uint256 _newTierId) external payable override whenNotPaused nonReentrant onlyActiveSubscriber(msg.sender) {
         // ... existing checks and calculation ...
         uint256 requiredPayment = calculateUpgradeCost(_newTierId);
         require(msg.value >= requiredPayment, "Upgrade: Insufficient payment for upgrade");

         SubscriptionData storage sub = subscriptions[msg.sender];
         uint256 oldTierId = sub.tierId;
         // uint256 oldExpirationTime = sub.expirationTime; // not needed for count update

         // ... upgrade logic ...
         sub.tierId = _newTierId;
         sub.lastRenewalTimestamp = block.timestamp;

         totalRevenue += msg.value;

         // User was active and remains active, just changing tier
         _activeSubscribersByTier[oldTierId]--;
         _activeSubscribersByTier[_newTierId]++;

         // ... event and refund ...
         emit SubscriptionUpgraded(msg.sender, oldTierId, _newTierId, sub.expirationTime, sub.expirationTime, msg.value);
         if (msg.value > requiredPayment) { payable(msg.sender).transfer(msg.value - requiredPayment); }
         emit FundsReceived(msg.sender, msg.value);
     }

     function deactivateSubscription(address _user) external override whenNotPaused {
         SubscriptionData storage sub = subscriptions[_user];
         require(sub.exists, "Subscription: No subscription found for user");
         require(msg.sender == _user || msg.sender == owner(), "Subscription: Only user or owner can deactivate");

         bool wasActive = sub.expirationTime > block.timestamp;
         uint256 currentTierId = sub.tierId; // Get tier before marking inactive

         // Set expiration to now or past to mark as inactive
         sub.expirationTime = block.timestamp;

         if (wasActive) {
             _activeSubscriberCount--; // User is no longer active
             _activeSubscribersByTier[currentTierId]--; // Remove from tier count
         }

         emit SubscriptionDeactivated(_user, msg.sender == _user ? "cancelled" : "admin_deactivated");
     }


    /**
     * @dev Gets the count of active subscribers for a specific tier. Gas efficient using state variable.
     * @param _tierId The tier ID to check.
     * @return uint256 Count of active subscribers for the tier.
     */
    function getSubscriberCountByTier(uint256 _tierId) external view returns (uint256) {
         require(tiers[_tierId].exists, "Tier: ID does not exist");
        return _activeSubscribersByTier[_tierId];
    }

     /**
     * @dev Gets the total accumulated revenue (Ether received).
     * Note: This represents the total value of subscription payments and successful direct Ether transfers,
     * minus any amounts withdrawn by the owner. It does not track individual payment history or refunds.
     * @return uint256 Total revenue in wei.
     */
    function getTotalRevenue() external view returns (uint256) {
        return totalRevenue;
    }

    /**
     * @dev Checks if a user address has ever had a subscription record created (even if expired).
     * Useful for identifying past subscribers.
     * @param _user The address to check.
     * @return bool True if a record exists, false otherwise.
     */
    function hasEverSubscribed(address _user) external view returns (bool) {
        return subscriptions[_user].exists;
    }

     /**
     * @dev Gets a human-readable status string for a user's subscription.
     * @param _user The address to check.
     * @return string Status text ("None", "Active", "Expired").
     */
    function getSubscriptionStatusText(address _user) external view returns (string memory) {
        SubscriptionStatus status = getSubscriptionDetails(_user).status; // Use the internal helper
        if (status == SubscriptionStatus.Active) return "Active";
        if (status == SubscriptionStatus.Expired) return "Expired";
        return "None";
    }

    // Fallback function to reject direct Ether sends that aren't through receive or payable functions
    fallback() external payable {
        revert("Fallback: Direct Ether sends not allowed");
    }
}
```