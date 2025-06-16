Okay, here is a Solidity smart contract for a `DecentralizedAIModelMarketplace`. This concept is interesting as it bridges Web3 with AI, handling rights management and payment for off-chain (referenced) AI models or services. It incorporates features like role-based access, collaboration splits, subscriptions, ratings, and fees, aiming for uniqueness beyond typical open-source examples.

**Outline and Function Summary**

**Contract Name:** `DecentralizedAIModelMarketplace`

**Concept:** A marketplace on the blockchain where creators can register AI models (or access to them, referenced by an IPFS hash), set prices, manage collaborations for revenue sharing, and users can purchase licenses or subscriptions. The contract handles payments, access control logic, fee distribution, and basic model rating. The AI models themselves reside off-chain (e.g., on IPFS, AWS, etc.), and the contract manages the *rights* and *financial transactions* associated with them.

**Key Features:**
*   **Model Registration & Management:** Creators can list, update, activate/deactivate models.
*   **Flexible Pricing:** One-time purchase and time-based subscriptions.
*   **Revenue Sharing:** Model owners can add collaborators and define their percentage splits.
*   **Marketplace Fees:** Owner collects a small fee on transactions.
*   **Access Control:** Role-based system (Owner, Admin).
*   **Pausability:** Contract can be paused in emergencies.
*   **Basic Rating System:** Users can rate purchased/subscribed models.
*   **IPFS Integration:** Stores IPFS hashes to reference off-chain model details/access info.
*   **Secure Payments:** Uses `payable` and `nonReentrant`.

**Function Summary:**

*   **Core Marketplace Logic:**
    1.  `constructor(address initialOwner, uint256 initialMarketplaceFee)`: Initializes the contract owner and marketplace fee percentage.
    2.  `registerModel(uint256 price, uint256 subscriptionPrice, uint256 subscriptionDuration, string memory ipfsHash)`: Registers a new AI model listing.
    3.  `updateModelMetadata(uint256 modelId, string memory newIpfsHash)`: Updates the IPFS hash associated with a model.
    4.  `updateModelPrice(uint256 modelId, uint256 newPrice)`: Updates the one-time purchase price of a model.
    5.  `updateSubscriptionPricing(uint256 modelId, uint256 newSubscriptionPrice, uint256 newSubscriptionDuration)`: Updates subscription details for a model.
    6.  `deactivateModel(uint256 modelId)`: Deactivates a model listing, preventing new purchases.
    7.  `activateModel(uint256 modelId)`: Activates a deactivated model listing.
    8.  `purchaseModelAccess(uint256 modelId) payable`: Allows a user to purchase perpetual access to a model with a one-time payment.
    9.  `purchaseSubscription(uint256 modelId) payable`: Allows a user to purchase a time-based subscription to a model.
*   **Collaboration & Payments:**
    10. `addCollaborator(uint256 modelId, address collaborator, uint256 shareBps)`: Adds or updates a collaborator's share for a model (in basis points, 1/100 of a percent).
    11. `removeCollaborator(uint256 modelId, address collaborator)`: Removes a collaborator from a model's revenue share.
    12. `withdrawFunds(uint256 modelId)`: Allows the model owner and collaborators to withdraw their accumulated earnings for a specific model.
    13. `withdrawMarketplaceFee()`: Allows the contract owner to withdraw accumulated marketplace fees.
*   **Access Control & Pausing:**
    14. `addAdmin(address account)`: Grants admin role to an address (can pause/unpause).
    15. `removeAdmin(address account)`: Revokes admin role.
    16. `pause()`: Pauses the contract (owner or admin).
    17. `unpause()`: Unpauses the contract (owner or admin).
    18. `transferOwnership(address newOwner)`: Transfers contract ownership.
*   **Rating System:**
    19. `rateModel(uint256 modelId, uint8 rating)`: Allows a user who purchased or subscribed to a model to rate it (1-5).
*   **View/Query Functions:**
    20. `getModelDetails(uint256 modelId) view`: Gets details of a specific model.
    21. `getUserModels(address user) view`: Gets the list of model IDs purchased by a user.
    22. `getUserSubscriptionEndTime(uint256 modelId, address user) view`: Gets the subscription end time for a user and model.
    23. `isSubscriptionActive(uint256 modelId, address user) view`: Checks if a user's subscription to a model is currently active.
    24. `getModelRating(uint256 modelId) view`: Gets the average rating and count for a model.
    25. `getMarketplaceFee() view`: Gets the current marketplace fee percentage.
    26. `isAdmin(address account) view`: Checks if an address has the admin role.
    27. `getOwner() view`: Gets the contract owner's address.
    28. `getTotalModels() view`: Gets the total number of registered models.
    29. `getModelCollaborators(uint56 modelId) view`: Gets the list of collaborators and their shares for a model.
    30. `getModelBalance(uint256 modelId, address account) view`: Gets the balance owed to a specific account for a specific model (owner/collaborator).
    31. `getMarketplaceFeeBalance() view`: Gets the total marketplace fees accumulated.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A smart contract for a decentralized marketplace selling access or licenses
 * to AI models (referenced off-chain via IPFS hashes). It handles registration,
 * one-time purchases, subscriptions, revenue sharing among collaborators,
 * marketplace fees, basic rating, and role-based access/pausability.
 * The AI models themselves are not stored on-chain due to size constraints;
 * only metadata, pricing, and access rights are managed by the contract.
 */
contract DecentralizedAIModelMarketplace is ReentrancyGuard, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    address private _owner;
    mapping(address => bool) private _admins; // Addresses with admin privileges (can pause/unpause)

    uint256 public marketplaceFeeBps; // Marketplace fee in basis points (e.g., 500 for 5%)

    uint256 private _modelCounter; // Counter for unique model IDs

    // Struct to hold AI Model details
    struct Model {
        address owner;
        uint256 price; // One-time purchase price in Wei
        uint256 subscriptionPrice; // Subscription price per duration in Wei
        uint256 subscriptionDuration; // Duration of subscription in seconds
        string ipfsHash; // IPFS hash referencing model details, access info, etc.
        bool isActive; // Is the model currently available for purchase/subscription?
        uint256 avgRating; // Average rating (scaled, e.g., 1-5 * 1000)
        uint256 ratingCount; // Number of ratings received
        mapping(address => uint256) collaborators; // Collaborator addresses => share in basis points (0-10000, sum cannot exceed 10000)
        address[] collaboratorList; // List of collaborator addresses for easy iteration
    }

    // Mappings for contract data
    mapping(uint256 => Model) public models; // modelId => Model details
    mapping(address => uint256[]) private userPurchasedModels; // user => list of modelIds purchased perpetually
    mapping(uint256 => mapping(address => uint256)) private userSubscriptionEndTimes; // modelId => user => subscription end timestamp
    mapping(uint256 => mapping(address => uint8)) private modelRatingsByUser; // modelId => user => rating (to prevent multiple ratings)

    mapping(uint256 => mapping(address => uint256)) private modelBalances; // modelId => owner/collaborator => balance owed (Wei)
    uint256 private marketplaceFeeBalance; // Accumulated marketplace fees (Wei)

    // --- Events ---

    event ModelRegistered(
        uint256 indexed modelId,
        address indexed owner,
        uint256 price,
        uint256 subscriptionPrice,
        uint256 subscriptionDuration,
        string ipfsHash
    );
    event ModelMetadataUpdated(uint256 indexed modelId, string newIpfsHash);
    event ModelPriceUpdated(uint256 indexed modelId, uint256 newPrice);
    event ModelSubscriptionPricingUpdated(
        uint256 indexed modelId,
        uint256 newSubscriptionPrice,
        uint256 newSubscriptionDuration
    );
    event ModelActivated(uint256 indexed modelId);
    event ModelDeactivated(uint256 indexed modelId);
    event ModelPurchased(
        uint256 indexed modelId,
        address indexed buyer,
        uint256 amountPaid
    );
    event SubscriptionPurchased(
        uint256 indexed modelId,
        address indexed buyer,
        uint256 amountPaid,
        uint256 endTime
    );
    event CollaboratorAdded(
        uint256 indexed modelId,
        address indexed collaborator,
        uint256 shareBps
    );
    event CollaboratorRemoved(
        uint256 indexed modelId,
        address indexed collaborator
    );
    event FundsWithdrawn(
        uint256 indexed modelId,
        address indexed account,
        uint256 amount
    );
    event MarketplaceFeeWithdrawn(address indexed owner, uint256 amount);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ModelRated(
        uint256 indexed modelId,
        address indexed rater,
        uint8 rating,
        uint256 newAvgRating
    );
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(
            msg.sender == _owner || _admins[msg.sender],
            "AccessControl: caller is not owner or admin"
        );
        _;
    }

    modifier modelExists(uint256 modelId) {
        require(modelId > 0 && modelId <= _modelCounter, "Model does not exist");
        _;
    }

    modifier isModelOwner(uint256 modelId) {
        require(
            modelExists(modelId) && models[modelId].owner == msg.sender,
            "Not model owner"
        );
        _;
    }

    modifier isModelPurchaserOrSubscriber(uint256 modelId, address user) {
         require(modelExists(modelId), "Model does not exist");
        // Check if user has perpetual purchase
        bool hasPerpetual = false;
        uint256[] storage purchasedModels = userPurchasedModels[user];
        for (uint i = 0; i < purchasedModels.length; i++) {
            if (purchasedModels[i] == modelId) {
                hasPerpetual = true;
                break;
            }
        }

        // Check if user has active subscription
        bool hasActiveSubscription = userSubscriptionEndTimes[modelId][user] > block.timestamp;

        require(hasPerpetual || hasActiveSubscription, "User has not purchased or subscribed to this model");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner, uint256 initialMarketplaceFeeBps) Pausable(false) {
        require(initialOwner != address(0), "Initial owner cannot be zero address");
        require(initialMarketplaceFeeBps <= 10000, "Fee cannot exceed 100%");
        _owner = initialOwner;
        marketplaceFeeBps = initialMarketplaceFeeBps;
        _modelCounter = 0;
    }

    // --- Access Control Functions ---

    /**
     * @dev Adds an account as an admin. Admins can pause/unpause the contract.
     * Only the owner can call this.
     */
    function addAdmin(address account) external onlyOwner {
        require(account != address(0), "Admin cannot be the zero address");
        _admins[account] = true;
        emit AdminAdded(account);
    }

    /**
     * @dev Removes an account as an admin.
     * Only the owner can call this.
     */
    function removeAdmin(address account) external onlyOwner {
        require(account != address(0), "Admin cannot be the zero address");
        _admins[account] = false;
        emit AdminRemoved(account);
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    // --- Pausable Functions ---

    /**
     * @dev Pauses the contract. Prevents most state-changing functions.
     * Can only be called by the owner or an admin.
     */
    function pause() external onlyAdminOrOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     * Can only be called by the owner or an admin.
     */
    function unpause() external onlyAdminOrOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Marketplace Fee Functions ---

    /**
     * @dev Sets the marketplace fee percentage in basis points.
     * Only the owner can call this.
     * @param newMarketplaceFeeBps The new fee percentage (0-10000).
     */
    function setMarketplaceFee(uint256 newMarketplaceFeeBps) external onlyOwner {
        require(newMarketplaceFeeBps <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBps = newMarketplaceFeeBps;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     * Only the owner can call this.
     */
    function withdrawMarketplaceFee() external onlyOwner nonReentrant {
        uint256 amount = marketplaceFeeBalance;
        require(amount > 0, "No marketplace fees to withdraw");
        marketplaceFeeBalance = 0;

        (bool success, ) = _owner.call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit MarketplaceFeeWithdrawn(_owner, amount);
    }

    // --- Model Management Functions ---

    /**
     * @dev Registers a new AI model listing.
     * Assigns a unique ID and sets initial parameters.
     * @param price One-time purchase price in Wei.
     * @param subscriptionPrice Subscription price per duration in Wei.
     * @param subscriptionDuration Duration of subscription in seconds.
     * @param ipfsHash IPFS hash linking to model details/access.
     * @return modelId The unique ID of the newly registered model.
     */
    function registerModel(
        uint256 price,
        uint256 subscriptionPrice,
        uint256 subscriptionDuration,
        string memory ipfsHash
    ) external whenNotPaused returns (uint256) {
        _modelCounter++;
        uint256 modelId = _modelCounter;
        models[modelId] = Model({
            owner: msg.sender,
            price: price,
            subscriptionPrice: subscriptionPrice,
            subscriptionDuration: subscriptionDuration,
            ipfsHash: ipfsHash,
            isActive: true, // Models are active by default
            avgRating: 0,
            ratingCount: 0,
            collaboratorList: new address[](0) // Initialize empty list
        });
        // Owner gets 100% of revenue initially, collaborators added later will take shares
        models[modelId].collaborators[msg.sender] = 10000; // 100% share initially for owner

        emit ModelRegistered(
            modelId,
            msg.sender,
            price,
            subscriptionPrice,
            subscriptionDuration,
            ipfsHash
        );
        return modelId;
    }

    /**
     * @dev Updates the IPFS hash for a registered model.
     * Only the model owner can call this.
     * @param modelId The ID of the model to update.
     * @param newIpfsHash The new IPFS hash.
     */
    function updateModelMetadata(
        uint256 modelId,
        string memory newIpfsHash
    ) external isModelOwner(modelId) whenNotPaused {
        models[modelId].ipfsHash = newIpfsHash;
        emit ModelMetadataUpdated(modelId, newIpfsHash);
    }

    /**
     * @dev Updates the one-time purchase price for a model.
     * Only the model owner can call this.
     * @param modelId The ID of the model to update.
     * @param newPrice The new price in Wei.
     */
    function updateModelPrice(
        uint256 modelId,
        uint256 newPrice
    ) external isModelOwner(modelId) whenNotPaused {
        models[modelId].price = newPrice;
        emit ModelPriceUpdated(modelId, newPrice);
    }

    /**
     * @dev Updates the subscription pricing details for a model.
     * Only the model owner can call this.
     * @param modelId The ID of the model to update.
     * @param newSubscriptionPrice The new subscription price in Wei.
     * @param newSubscriptionDuration The new subscription duration in seconds.
     */
    function updateSubscriptionPricing(
        uint256 modelId,
        uint256 newSubscriptionPrice,
        uint256 newSubscriptionDuration
    ) external isModelOwner(modelId) whenNotPaused {
        models[modelId].subscriptionPrice = newSubscriptionPrice;
        models[modelId].subscriptionDuration = newSubscriptionDuration;
        emit ModelSubscriptionPricingUpdated(
            modelId,
            newSubscriptionPrice,
            newSubscriptionDuration
        );
    }

    /**
     * @dev Deactivates a model listing.
     * Prevents new purchases or subscriptions but does not affect existing access/subscriptions.
     * Only the model owner can call this.
     * @param modelId The ID of the model to deactivate.
     */
    function deactivateModel(
        uint256 modelId
    ) external isModelOwner(modelId) whenNotPaused {
        models[modelId].isActive = false;
        emit ModelDeactivated(modelId);
    }

    /**
     * @dev Activates a deactivated model listing.
     * Allows new purchases or subscriptions again.
     * Only the model owner can call this.
     * @param modelId The ID of the model to activate.
     */
    function activateModel(
        uint256 modelId
    ) external isModelOwner(modelId) whenNotPaused {
        models[modelId].isActive = true;
        emit ModelActivated(modelId);
    }

    // --- Collaboration Functions ---

     /**
     * @dev Adds or updates a collaborator's revenue share for a model.
     * Shares are in basis points (1/100 of a percent), total collaborator shares cannot exceed 10000 (100%).
     * The model owner's share is implicitly the remainder (10000 - sum of collaborator shares).
     * Only the model owner can call this.
     * @param modelId The ID of the model.
     * @param collaborator The address of the collaborator.
     * @param shareBps The collaborator's share in basis points (0-10000).
     */
    function addCollaborator(
        uint256 modelId,
        address collaborator,
        uint256 shareBps
    ) external isModelOwner(modelId) whenNotPaused {
        require(collaborator != address(0), "Collaborator cannot be zero address");
        require(collaborator != models[modelId].owner, "Owner cannot be added as a collaborator this way");
        require(shareBps <= 10000, "Share cannot exceed 100%");

        Model storage model = models[modelId];
        uint256 currentShare = model.collaborators[collaborator];

        // Calculate total collaborator shares EXCLUDING the current collaborator's *old* share
        uint256 totalCollaboratorShares = 0;
        for (uint i = 0; i < model.collaboratorList.length; i++) {
            address currentCollaborator = model.collaboratorList[i];
             if (currentCollaborator != collaborator) {
                 totalCollaboratorShares = totalCollaboratorShares.add(model.collaborators[currentCollaborator]);
             }
        }

        // Check if adding the new share exceeds 100% for all collaborators
        uint256 newTotalCollaboratorShares = totalCollaboratorShares.add(shareBps);
        require(newTotalCollaboratorShares <= 10000, "Total collaborator shares exceed 100%");

        // Add collaborator to list if new and share > 0
        bool isNew = model.collaborators[collaborator] == 0 && shareBps > 0;
        if (isNew) {
             model.collaboratorList.push(collaborator);
        } else if (model.collaborators[collaborator] > 0 && shareBps == 0) {
            // If share is set to 0, effectively remove them (though they remain in list until removeCollaborator is called)
            // The actual removal from the list happens in removeCollaborator
        }


        model.collaborators[collaborator] = shareBps;
        emit CollaboratorAdded(modelId, collaborator, shareBps);
    }

    /**
     * @dev Removes a collaborator's revenue share entirely.
     * Only the model owner can call this.
     * @param modelId The ID of the model.
     * @param collaborator The address of the collaborator to remove.
     */
    function removeCollaborator(uint256 modelId, address collaborator) external isModelOwner(modelId) whenNotPaused {
        require(collaborator != address(0), "Collaborator cannot be zero address");
         require(collaborator != models[modelId].owner, "Cannot remove owner this way");
        require(models[modelId].collaborators[collaborator] > 0, "Collaborator not found for this model");

        Model storage model = models[modelId];
        model.collaborators[collaborator] = 0; // Set share to zero

        // Remove from collaborator list (expensive operation, consider alternative if list gets large)
        for (uint i = 0; i < model.collaboratorList.length; i++) {
            if (model.collaboratorList[i] == collaborator) {
                model.collaboratorList[i] = model.collaboratorList[model.collaboratorList.length - 1];
                model.collaboratorList.pop();
                break;
            }
        }

        emit CollaboratorRemoved(modelId, collaborator);
    }


    // --- Purchase Functions ---

    /**
     * @dev Allows a user to purchase perpetual access to a model with a one-time payment.
     * The paid amount is distributed based on marketplace fee and collaborator shares.
     * @param modelId The ID of the model to purchase.
     */
    function purchaseModelAccess(uint256 modelId) external payable nonReentrant whenNotPaused modelExists(modelId) {
        Model storage model = models[modelId];
        require(model.isActive, "Model is not active");
        require(msg.value >= model.price, "Insufficient funds");

        // Prevent repurchasing perpetual access
         for (uint i = 0; i < userPurchasedModels[msg.sender].length; i++) {
             if (userPurchasedModels[msg.sender][i] == modelId) {
                 revert("User already owns this model perpetually");
             }
         }

        uint256 totalAmount = msg.value;
        uint256 feeAmount = totalAmount.mul(marketplaceFeeBps).div(10000);
        uint256 payoutAmount = totalAmount.sub(feeAmount);

        marketplaceFeeBalance = marketplaceFeeBalance.add(feeAmount);

        // Distribute payout among owner and collaborators based on shares
        uint256 totalShares = 0;
         address modelOwner = model.owner; // Cache owner address
         uint256 ownerShareBps = 10000; // Owner's share starts at 100% (10000 bps)

        // Calculate total collaborator shares and deduct from owner's implicit share
        for (uint i = 0; i < model.collaboratorList.length; i++) {
            address collab = model.collaboratorList[i];
            uint256 collabShare = model.collaborators[collab];
            if (collabShare > 0) {
                uint256 collabPayout = payoutAmount.mul(collabShare).div(10000);
                modelBalances[modelId][collab] = modelBalances[modelId][collab].add(collabPayout);
                totalShares = totalShares.add(collabShare);
            }
        }
        ownerShareBps = ownerShareBps.sub(totalShares); // Owner gets the remaining percentage

        // Add owner's share to their balance
        uint256 ownerPayout = payoutAmount.mul(ownerShareBps).div(10000);
        modelBalances[modelId][modelOwner] = modelBalances[modelId][modelOwner].add(ownerPayout);


        // Record the perpetual purchase for the user
        userPurchasedModels[msg.sender].push(modelId);

        // Refund excess Ether if any
        if (msg.value > model.price) {
            payable(msg.sender).transfer(msg.value.sub(model.price));
        }


        emit ModelPurchased(modelId, msg.sender, model.price);
    }

    /**
     * @dev Allows a user to purchase or extend a subscription for a model.
     * The paid amount is distributed based on marketplace fee and collaborator shares.
     * @param modelId The ID of the model to subscribe to.
     */
    function purchaseSubscription(uint256 modelId) external payable nonReentrant whenNotPaused modelExists(modelId) {
        Model storage model = models[modelId];
        require(model.isActive, "Model is not active");
        require(model.subscriptionDuration > 0, "Subscription not available for this model");
        require(msg.value >= model.subscriptionPrice, "Insufficient funds for subscription");

        uint256 totalAmount = msg.value;
        uint256 feeAmount = totalAmount.mul(marketplaceFeeBps).div(10000);
        uint256 payoutAmount = totalAmount.sub(feeAmount);

        marketplaceFeeBalance = marketplaceFeeBalance.add(feeAmount);

         // Distribute payout among owner and collaborators based on shares (same logic as purchase)
        uint26 models_totalShares = 0;
        address modelOwner = model.owner;
        uint256 ownerShareBps = 10000;

        for (uint i = 0; i < model.collaboratorList.length; i++) {
             address collab = model.collaboratorList[i];
            uint256 collabShare = model.collaborators[collab];
            if (collabShare > 0) {
                uint256 collabPayout = payoutAmount.mul(collabShare).div(10000);
                modelBalances[modelId][collab] = modelBalances[modelId][collab].add(collabPayout);
                models_totalShares = models_totalShares.add(collabShare);
            }
        }
        ownerShareBps = ownerShareBps.sub(models_totalShares);

        uint256 ownerPayout = payoutAmount.mul(ownerShareBps).div(10000);
        modelBalances[modelId][modelOwner] = modelBalances[modelId][modelOwner].add(ownerPayout);

        // Calculate new subscription end time
        uint26 currentEndTime = userSubscriptionEndTimes[modelId][msg.sender];
        uint256 newEndTime;

        if (currentEndTime < block.timestamp) {
            // If subscription expired or never existed, start from now
            newEndTime = block.timestamp.add(model.subscriptionDuration);
        } else {
            // If subscription is active, extend from the current end time
            newEndTime = currentEndTime.add(model.subscriptionDuration);
        }

        userSubscriptionEndTimes[modelId][msg.sender] = newEndTime;

         // Refund excess Ether if any
        if (msg.value > model.subscriptionPrice) {
            payable(msg.sender).transfer(msg.value.sub(model.subscriptionPrice));
        }


        emit SubscriptionPurchased(
            modelId,
            msg.sender,
            model.subscriptionPrice,
            newEndTime
        );
    }

    // --- Withdrawal Functions ---

    /**
     * @dev Allows a model owner or collaborator to withdraw their accumulated earnings for a specific model.
     * Only the model owner or a registered collaborator can call this for their balance.
     * @param modelId The ID of the model.
     */
    function withdrawFunds(uint256 modelId) external nonReentrant modelExists(modelId) {
        Model storage model = models[modelId];
        address withdrawer = msg.sender;

        // Check if withdrawer is the owner or a collaborator with a share > 0
        bool isOwner = withdrawer == model.owner;
        bool isCollaborator = model.collaborators[b] > 0; // Check share > 0

        require(isOwner || isCollaborator, "Caller is not the owner or a registered collaborator for this model");

        uint256 amount = modelBalances[modelId][withdrawer];
        require(amount > 0, "No funds to withdraw for this model");

        modelBalances[modelId][withdrawer] = 0; // Reset balance first to prevent reentrancy

        (bool success, ) = payable(withdrawer).call{value: amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(modelId, withdrawer, amount);
    }


    // --- Rating Function ---

     /**
     * @dev Allows a user who has purchased or has an active subscription for a model to rate it.
     * Users can only rate a specific model once.
     * @param modelId The ID of the model to rate.
     * @param rating The rating (1-5).
     */
    function rateModel(uint256 modelId, uint8 rating) external whenNotPaused nonReentrant modelExists(modelId) isModelPurchaserOrSubscriber(modelId, msg.sender) {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        require(modelRatingsByUser[modelId][msg.sender] == 0, "User has already rated this model");

        Model storage model = models[modelId];

        // Store the user's rating
        modelRatingsByUser[modelId][msg.sender] = rating;

        // Update average rating (simple moving average calculation is complex on-chain)
        // We use sum / count. Store average scaled by 1000 to keep precision.
        uint256 currentAvgScaled = model.avgRating;
        uint256 currentCount = model.ratingCount;

        uint256 newSumScaled = currentAvgScaled.mul(currentCount).add(uint256(rating).mul(1000));
        uint256 newCount = currentCount.add(1);

        model.avgRating = newSumScaled.div(newCount);
        model.ratingCount = newCount;

        emit ModelRated(modelId, msg.sender, rating, model.avgRating);
    }


    // --- View Functions (Read Only) ---

    /**
     * @dev Gets the details of a specific model.
     * @param modelId The ID of the model.
     * @return owner The model owner's address.
     * @return price The one-time purchase price.
     * @return subscriptionPrice The subscription price.
     * @return subscriptionDuration The subscription duration in seconds.
     * @return ipfsHash The IPFS hash.
     * @return isActive Whether the model is active.
     * @return avgRating The average rating (scaled by 1000).
     * @return ratingCount The number of ratings.
     */
    function getModelDetails(
        uint256 modelId
    )
        external
        view
        modelExists(modelId)
        returns (
            address owner,
            uint256 price,
            uint256 subscriptionPrice,
            uint256 subscriptionDuration,
            string memory ipfsHash,
            bool isActive,
            uint256 avgRating,
            uint256 ratingCount
        )
    {
        Model storage model = models[modelId];
        return (
            model.owner,
            model.price,
            model.subscriptionPrice,
            model.subscriptionDuration,
            model.ipfsHash,
            model.isActive,
            model.avgRating,
            model.ratingCount
        );
    }

     /**
     * @dev Gets the list of model IDs that a user has purchased perpetually.
     * @param user The address of the user.
     * @return A list of model IDs.
     */
    function getUserModels(address user) external view returns (uint256[] memory) {
        return userPurchasedModels[user];
    }

     /**
     * @dev Gets the subscription end timestamp for a specific user and model.
     * @param modelId The ID of the model.
     * @param user The address of the user.
     * @return The timestamp when the subscription ends (0 if none or expired).
     */
    function getUserSubscriptionEndTime(
        uint256 modelId,
        address user
    ) external view modelExists(modelId) returns (uint256) {
        return userSubscriptionEndTimes[modelId][user];
    }

     /**
     * @dev Checks if a user's subscription to a model is currently active.
     * @param modelId The ID of the model.
     * @param user The address of the user.
     * @return True if the subscription is active, false otherwise.
     */
    function isSubscriptionActive(
        uint256 modelId,
        address user
    ) external view modelExists(modelId) returns (bool) {
        return userSubscriptionEndTimes[modelId][user] > block.timestamp;
    }

     /**
     * @dev Gets the average rating and count for a model.
     * @param modelId The ID of the model.
     * @return avgRating The average rating (scaled by 1000).
     * @return ratingCount The number of ratings.
     */
    function getModelRating(
        uint256 modelId
    ) external view modelExists(modelId) returns (uint256 avgRating, uint256 ratingCount) {
        Model storage model = models[modelId];
        return (model.avgRating, model.ratingCount);
    }

     /**
     * @dev Gets the current marketplace fee percentage in basis points.
     */
    function getMarketplaceFee() external view returns (uint256) {
        return marketplaceFeeBps;
    }

     /**
     * @dev Checks if an address has the admin role.
     * @param account The address to check.
     * @return True if the account is an admin, false otherwise.
     */
    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }

     /**
     * @dev Gets the contract owner's address.
     */
    function getOwner() external view returns (address) {
        return _owner;
    }

     /**
     * @dev Gets the total number of registered models.
     */
    function getTotalModels() external view returns (uint256) {
        return _modelCounter;
    }

    /**
     * @dev Gets the list of collaborators and their shares for a model.
     * @param modelId The ID of the model.
     * @return collaboratorAddresses An array of collaborator addresses.
     * @return sharesBps An array of their corresponding shares in basis points.
     */
     function getModelCollaborators(uint256 modelId) external view modelExists(modelId) returns (address[] memory collaboratorAddresses, uint256[] memory sharesBps) {
         Model storage model = models[modelId];
         address[] memory addresses = model.collaboratorList;
         uint256[] memory shares = new uint256[](addresses.length);
         for(uint i = 0; i < addresses.length; i++) {
             shares[i] = model.collaborators[addresses[i]];
         }
         return (addresses, shares);
     }

    /**
     * @dev Gets the balance owed to a specific account (owner or collaborator) for a specific model.
     * @param modelId The ID of the model.
     * @param account The address of the account (owner or collaborator).
     * @return The balance owed in Wei.
     */
    function getModelBalance(uint256 modelId, address account) external view modelExists(modelId) returns (uint256) {
        return modelBalances[modelId][account];
    }

    /**
     * @dev Gets the total accumulated marketplace fees.
     */
    function getMarketplaceFeeBalance() external view returns (uint256) {
        return marketplaceFeeBalance;
    }

    // Fallback function to prevent accidental Ether sends without calling a payable function
    receive() external payable {
        revert("Direct Ether deposit not allowed. Use purchase functions.");
    }

    fallback() external payable {
        revert("Call a specific function.");
    }
}
```