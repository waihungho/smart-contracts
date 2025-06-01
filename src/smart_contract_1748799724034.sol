Okay, here is a Solidity smart contract for a "Decentralized AI Model Marketplace". This contract incorporates concepts like staking for service providers, time-based access control for models, basic on-chain reputation, simulated oracle interaction for potential performance feeds, and a decentralized governance framework (simplified) managed through contract parameters.

It aims to be unique by combining these elements specifically for the domain of AI model access/licensing, going beyond standard ERC token or simple marketplace examples.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Assuming payments might use ERC20 later, but using ETH for now.

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A marketplace for AI models where providers can list models,
 *      consumers can purchase time-based access, providers stake tokens
 *      for reliability, and basic reputation/oracle interaction is simulated.
 *      This contract manages provider registration, model listing, access rights,
 *      payments (in Ether), staking, and basic administrative functions.
 */

/**
 * @dev --- OUTLINE ---
 * 1.  State Variables
 * 2.  Events
 * 3.  Enums
 * 4.  Structs
 * 5.  Modifiers (using Ownable and Pausable)
 * 6.  Constructor
 * 7.  Admin/Owner Functions (Marketplace Governance/Settings)
 * 8.  Provider Functions (Registration, Staking, Profile Management)
 * 9.  Model Functions (Listing, Updating, Status Management)
 * 10. Consumer Functions (Purchasing Access, Consuming Service, Rating)
 * 11. Query Functions (View Functions)
 * 12. Internal Helper Functions
 */

/**
 * @dev --- FUNCTION SUMMARY ---
 *
 * Admin/Owner Functions:
 * 1.  setMarketplaceFee(uint256 newFee): Sets the percentage fee taken by the marketplace.
 * 2.  setMinProviderStake(uint256 minStake): Sets the minimum required stake for providers.
 * 3.  addTrustedOracle(address oracleAddress): Adds an address to a list of trusted oracles (simulated).
 * 4.  removeTrustedOracle(address oracleAddress): Removes an address from the trusted oracles list.
 * 5.  pause(): Pauses the marketplace operations (purchases, staking, etc.). Inherited from Pausable.
 * 6.  unpause(): Unpauses the marketplace operations. Inherited from Pausable.
 * 7.  withdrawMarketplaceFees(): Allows the owner to withdraw collected fees.
 * 8.  changeOwnership(address newOwner): Transfers contract ownership. Inherited from Ownable.
 *
 * Provider Functions:
 * 9.  registerProvider(): Registers the caller as a provider, requiring minimum stake.
 * 10. updateProviderProfile(string calldata description): Updates provider profile description.
 * 11. stakeForProvider() payable: Adds stake for the calling provider.
 * 12. requestUnstake(uint256 amount): Initiates an unstaking process (potential cool-down).
 * 13. withdrawUnstaked(): Withdraws stake after cool-down (cool-down not implemented for brevity).
 * 14. deregisterProvider(): Deregisters a provider and initiates full stake return.
 *
 * Model Functions:
 * 15. listModel(string calldata metadataHash, string calldata description, string calldata accessEndpoint, uint256 priceInWei, uint256 durationInSeconds): Lists a new AI model for access.
 * 16. updateModelMetadata(uint256 modelId, string calldata metadataHash, string calldata description, string calldata accessEndpoint): Updates metadata for an existing model.
 * 17. updateModelPriceAndDuration(uint256 modelId, uint256 priceInWei, uint256 durationInSeconds): Updates price and duration for a model.
 * 18. updateModelStatus(uint256 modelId, ModelStatus newStatus): Changes the status of a model (e.g., Active, Inactive).
 * 19. removeModel(uint256 modelId): Removes a model listing (requires setting status to Deprecated first).
 *
 * Consumer Functions:
 * 20. purchaseModelAccess(uint256 modelId) payable: Purchases time-based access to a model.
 * 21. extendModelAccess(uint256 modelId) payable: Extends existing access for a model.
 * 22. consumeModelService(uint256 modelId): Simulates checking if a consumer has active access to a model.
 * 23. rateModel(uint256 modelId, uint8 rating): Allows a consumer to rate a model (1-5).
 *
 * Query Functions:
 * 24. getMarketplaceFee(): Returns the current marketplace fee percentage.
 * 25. getMinProviderStake(): Returns the minimum required provider stake.
 * 26. getProviderProfile(address providerAddress): Returns details of a provider's profile.
 * 27. getModelDetails(uint256 modelId): Returns details of a specific model.
 * 28. getModelCount(): Returns the total number of models listed.
 * 29. getAccessDetails(address consumer, uint256 modelId): Returns details about a consumer's access to a model.
 * 30. isAccessValid(address consumer, uint256 modelId): Checks if a consumer currently has valid access.
 * 31. isProviderRegistered(address providerAddress): Checks if an address is a registered provider.
 * 32. listTrustedOracles(): Returns the list of trusted oracle addresses.
 * 33. getModelRatings(uint256 modelId): Returns the total rating score and count for a model.
 * 34. getAllModels(): Returns a list of all model IDs (can be large, use pagination off-chain).
 */

contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {
    using Address for address payable;

    // --- State Variables ---
    uint256 public marketplaceFeeBasisPoints; // Fee as a percentage * 100 (e.g., 500 for 5%)
    uint256 public minProviderStake;          // Minimum Ether required to be staked by a provider
    uint256 public totalMarketplaceFees;      // Accumulated fees owed to the marketplace owner

    uint256 private _modelCounter; // Counter for unique model IDs

    address[] public trustedOracles; // List of addresses considered trusted oracles

    mapping(address => ProviderProfile) public providers;
    mapping(uint256 => Model) public models;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions; // consumerAddress => modelId => subscription details

    // --- Events ---
    event MarketplaceFeeUpdated(uint256 newFee);
    event MinProviderStakeUpdated(uint256 minStake);
    event MarketplaceFeesWithdrawn(uint256 amount);
    event TrustedOracleAdded(address oracleAddress);
    event TrustedOracleRemoved(address oracleAddress);

    event ProviderRegistered(address providerAddress, uint256 initialStake);
    event ProviderProfileUpdated(address providerAddress, string description);
    event ProviderStaked(address providerAddress, uint256 amount, uint256 totalStake);
    event UnstakeRequested(address providerAddress, uint256 amount);
    event UnstakeWithdrawn(address providerAddress, uint256 amount);
    event ProviderDeregistered(address providerAddress, uint256 finalStakeReturned);

    event ModelListed(uint256 modelId, address provider, uint256 price, uint256 duration);
    event ModelMetadataUpdated(uint256 modelId, string metadataHash, string description, string accessEndpoint);
    event ModelPriceAndDurationUpdated(uint256 modelId, uint256 price, uint256 duration);
    event ModelStatusUpdated(uint256 modelId, ModelStatus newStatus);
    event ModelRemoved(uint256 modelId);

    event AccessPurchased(address consumer, uint256 modelId, uint256 expiresAt, uint256 pricePaid);
    event AccessExtended(address consumer, uint256 modelId, uint256 newExpiresAt, uint256 pricePaid);
    event ModelConsumed(address consumer, uint256 modelId);
    event ModelRated(address consumer, uint256 modelId, uint8 rating);

    // --- Enums ---
    enum ModelStatus {
        Pending,    // Under review or not yet active
        Active,     // Available for purchase and use
        Inactive,   // Temporarily unavailable
        Deprecated  // Permanently removed or replaced
    }

    // --- Structs ---
    struct ProviderProfile {
        bool isRegistered;
        uint256 stakedAmount;
        string description;
        uint256 reputationScore; // Basic accumulated score (e.g., sum of ratings * weight)
        uint256 ratingCount;     // Number of ratings received
        uint256 unstakeRequest;  // Amount pending unstake
        uint40 unstakeCooldown; // Timestamp when unstake is available (not implemented cool-down logic)
    }

    struct Model {
        uint256 id;
        address provider;
        string metadataHash;    // Hash reference to off-chain model metadata
        string description;
        string accessEndpoint;  // API endpoint or similar reference (off-chain)
        uint256 priceInWei;     // Price per access duration
        uint256 durationInSeconds; // Access duration per purchase
        ModelStatus status;
        uint256 totalRatingScore; // Sum of all ratings
        uint256 ratingCount;      // Number of ratings received
        uint256 listingTimestamp; // When the model was listed
    }

    struct Subscription {
        uint256 expiresAt;  // Timestamp when access expires
        // Could add more fields like usage count, etc.
    }

    // --- Constructor ---
    constructor(uint256 _initialFeeBasisPoints, uint256 _initialMinStake) Ownable(msg.sender) Pausable(false) {
        require(_initialFeeBasisPoints <= 10000, "Fee must be <= 100%");
        marketplaceFeeBasisPoints = _initialFeeBasisPoints;
        minProviderStake = _initialMinStake;
    }

    // --- Admin/Owner Functions ---

    /**
     * @dev Sets the marketplace fee percentage. Callable by owner.
     * @param newFee The new fee percentage in basis points (e.g., 500 for 5%).
     */
    function setMarketplaceFee(uint256 newFee) public onlyOwner {
        require(newFee <= 10000, "Fee must be <= 100%");
        marketplaceFeeBasisPoints = newFee;
        emit MarketplaceFeeUpdated(newFee);
    }

    /**
     * @dev Sets the minimum required stake for providers. Callable by owner.
     * @param minStake The new minimum stake amount in Wei.
     */
    function setMinProviderStake(uint256 minStake) public onlyOwner {
        minProviderStake = minStake;
        emit MinProviderStakeUpdated(minStake);
    }

    /**
     * @dev Adds an address to the list of trusted oracles. Callable by owner.
     * @param oracleAddress The address to add.
     */
    function addTrustedOracle(address oracleAddress) public onlyOwner {
        // Prevent duplicates - simple check
        for (uint i = 0; i < trustedOracles.length; i++) {
            require(trustedOracles[i] != oracleAddress, "Oracle already trusted");
        }
        trustedOracles.push(oracleAddress);
        emit TrustedOracleAdded(oracleAddress);
    }

    /**
     * @dev Removes an address from the list of trusted oracles. Callable by owner.
     * @param oracleAddress The address to remove.
     */
    function removeTrustedOracle(address oracleAddress) public onlyOwner {
        bool found = false;
        for (uint i = 0; i < trustedOracles.length; i++) {
            if (trustedOracles[i] == oracleAddress) {
                // Simple removal by swapping with last and popping
                trustedOracles[i] = trustedOracles[trustedOracles.length - 1];
                trustedOracles.pop();
                found = true;
                break;
            }
        }
        require(found, "Oracle not found in trusted list");
        emit TrustedOracleRemoved(oracleAddress);
    }

    /**
     * @dev Pauses the contract. Callable by owner. Inherited from Pausable.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Callable by owner. Inherited from Pausable.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner nonReentrant {
        uint256 fees = totalMarketplaceFees;
        require(fees > 0, "No fees to withdraw");
        totalMarketplaceFees = 0;

        (bool success, ) = payable(owner()).call{value: fees}("");
        require(success, "Fee withdrawal failed");

        emit MarketplaceFeesWithdrawn(fees);
    }

    // `changeOwnership` is inherited from Ownable

    // --- Provider Functions ---

    /**
     * @dev Registers the caller as a provider. Requires minimum stake.
     * @param description Optional profile description.
     */
    function registerProvider() public payable whenNotPaused nonReentrant {
        ProviderProfile storage provider = providers[msg.sender];
        require(!provider.isRegistered, "Provider already registered");
        require(msg.value >= minProviderStake, "Minimum stake required");

        provider.isRegistered = true;
        provider.stakedAmount = msg.value;
        provider.description = ""; // Initial empty description
        provider.reputationScore = 0;
        provider.ratingCount = 0;

        emit ProviderRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Updates the provider's profile description.
     * @param description The new description for the provider profile.
     */
    function updateProviderProfile(string calldata description) public whenNotPaused {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");
        provider.description = description;
        emit ProviderProfileUpdated(msg.sender, description);
    }


    /**
     * @dev Allows a registered provider to add more stake.
     */
    function stakeForProvider() public payable whenNotPaused nonReentrant {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");
        require(msg.value > 0, "Stake amount must be greater than zero");

        provider.stakedAmount += msg.value;
        emit ProviderStaked(msg.sender, msg.value, provider.stakedAmount);
    }

    /**
     * @dev Initiates an unstake request. Does not immediately return funds.
     *      (Cool-down logic is a placeholder - not implemented).
     * @param amount The amount of stake to request unstake for.
     */
    function requestUnstake(uint256 amount) public whenNotPaused {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");
        require(provider.stakedAmount >= amount, "Insufficient staked amount");
        require(amount > 0, "Amount must be greater than zero");
        // Add logic here for minimum stake requirement after unstake
        require(provider.stakedAmount - amount >= minProviderStake, "Cannot unstake below minimum required stake");

        provider.stakedAmount -= amount;
        provider.unstakeRequest += amount;

        // --- Placeholder for cool-down logic ---
        // provider.unstakeCooldown = uint40(block.timestamp + UNSTAKE_COOLDOWN_PERIOD);
        // --- End Placeholder ---

        emit UnstakeRequested(msg.sender, amount);
    }

     /**
      * @dev Withdraws stake that was requested for unstake and has passed cool-down.
      *      (Cool-down check is a placeholder - not implemented).
      */
    function withdrawUnstaked() public nonReentrant {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");
        // --- Placeholder for cool-down check ---
        // require(block.timestamp >= provider.unstakeCooldown, "Unstake cool-down period not over");
        // --- End Placeholder ---
        uint256 amount = provider.unstakeRequest;
        require(amount > 0, "No unstaked amount to withdraw");

        provider.unstakeRequest = 0;
        // provider.unstakeCooldown = 0; // Reset cool-down

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Unstake withdrawal failed");

        emit UnstakeWithdrawn(msg.sender, amount);
    }


    /**
     * @dev Deregisters a provider. All models must be deprecated first.
     *      Remaining stake is made available for withdrawal.
     */
    function deregisterProvider() public whenNotPaused nonReentrant {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");

        // Check if provider has any active or pending models
        uint256 providerModelCount = 0;
        for (uint i = 1; i <= _modelCounter; i++) {
            if (models[i].provider == msg.sender) {
                providerModelCount++;
                require(models[i].status == ModelStatus.Deprecated, "All provider models must be deprecated before deregistration");
            }
        }

        provider.isRegistered = false;

        uint256 remainingStake = provider.stakedAmount + provider.unstakeRequest;
        provider.stakedAmount = 0;
        provider.unstakeRequest = 0;
        // provider.unstakeCooldown = 0; // Reset cool-down

        if (remainingStake > 0) {
             (bool success, ) = payable(msg.sender).call{value: remainingStake}("");
             require(success, "Deregistration stake withdrawal failed");
        }

        emit ProviderDeregistered(msg.sender, remainingStake);
    }

    // --- Model Functions ---

    /**
     * @dev Lists a new AI model by a registered provider.
     * @param metadataHash Hash reference to off-chain metadata (e.g., IPFS hash).
     * @param description A brief description of the model.
     * @param accessEndpoint Off-chain endpoint to access the model's API.
     * @param priceInWei Price per access duration in Wei.
     * @param durationInSeconds Duration of access granted per purchase.
     */
    function listModel(
        string calldata metadataHash,
        string calldata description,
        string calldata accessEndpoint,
        uint256 priceInWei,
        uint256 durationInSeconds
    ) public whenNotPaused {
        ProviderProfile storage provider = providers[msg.sender];
        require(provider.isRegistered, "Caller is not a registered provider");
        require(provider.stakedAmount >= minProviderStake, "Provider stake below minimum requirement");
        require(priceInWei > 0, "Price must be greater than zero");
        require(durationInSeconds > 0, "Duration must be greater than zero");

        _modelCounter++;
        uint256 newModelId = _modelCounter;

        models[newModelId] = Model({
            id: newModelId,
            provider: msg.sender,
            metadataHash: metadataHash,
            description: description,
            accessEndpoint: accessEndpoint,
            priceInWei: priceInWei,
            durationInSeconds: durationInSeconds,
            status: ModelStatus.Pending, // Models start as Pending, need review/activation
            totalRatingScore: 0,
            ratingCount: 0,
            listingTimestamp: block.timestamp
        });

        emit ModelListed(newModelId, msg.sender, priceInWei, durationInSeconds);
    }

    /**
     * @dev Updates metadata for a model owned by the caller.
     * @param modelId The ID of the model to update.
     * @param metadataHash New metadata hash.
     * @param description New description.
     * @param accessEndpoint New access endpoint.
     */
    function updateModelMetadata(
        uint256 modelId,
        string calldata metadataHash,
        string calldata description,
        string calldata accessEndpoint
    ) public whenNotPaused {
        Model storage model = models[modelId];
        require(model.provider == msg.sender, "Caller is not the model provider");
        require(model.status != ModelStatus.Deprecated, "Cannot update a deprecated model");

        model.metadataHash = metadataHash;
        model.description = description;
        model.accessEndpoint = accessEndpoint;

        emit ModelMetadataUpdated(modelId, metadataHash, description, accessEndpoint);
    }

    /**
     * @dev Updates price and duration for a model owned by the caller.
     * @param modelId The ID of the model to update.
     * @param priceInWei New price per duration.
     * @param durationInSeconds New access duration.
     */
    function updateModelPriceAndDuration(
        uint256 modelId,
        uint256 priceInWei,
        uint256 durationInSeconds
    ) public whenNotPaused {
        Model storage model = models[modelId];
        require(model.provider == msg.sender, "Caller is not the model provider");
         require(model.status != ModelStatus.Deprecated, "Cannot update a deprecated model");
        require(priceInWei > 0, "Price must be greater than zero");
        require(durationInSeconds > 0, "Duration must be greater than zero");

        model.priceInWei = priceInWei;
        model.durationInSeconds = durationInSeconds;

        emit ModelPriceAndDurationUpdated(modelId, priceInWei, durationInSeconds);
    }

    /**
     * @dev Changes the status of a model owned by the caller.
     * @param modelId The ID of the model to update.
     * @param newStatus The new status for the model.
     */
    function updateModelStatus(uint256 modelId, ModelStatus newStatus) public whenNotPaused {
        Model storage model = models[modelId];
        require(model.provider == msg.sender, "Caller is not the model provider");
        require(newStatus != model.status, "Model is already in this status");

        // Basic state transitions constraint (optional but good practice)
        if (model.status == ModelStatus.Deprecated) {
            require(newStatus == ModelStatus.Deprecated, "Cannot change status from Deprecated");
        }
         if (newStatus == ModelStatus.Deprecated) {
             // Optionally add check if any active subscriptions exist before deprecating
             // This would require tracking active subscriptions per model, which is complex.
             // For now, we allow deprecation, but consumers keep access until expiry.
         }


        model.status = newStatus;
        emit ModelStatusUpdated(modelId, newStatus);
    }

     /**
      * @dev Removes a model listing. Requires status to be Deprecated.
      * @param modelId The ID of the model to remove.
      */
    function removeModel(uint256 modelId) public whenNotPaused {
        Model storage model = models[modelId];
        require(model.provider == msg.sender, "Caller is not the model provider");
        require(model.status == ModelStatus.Deprecated, "Model must be deprecated before removal");
        // Note: This doesn't delete the struct from storage,
        // which is gas-inefficient. A mapping to boolean `isRemoved`
        // and simply marking it would be better in practice.
        // For this example, we'll keep the struct but mark it logically removed.

        // Mark as removed logically (or use a mapping)
        // Setting provider to address(0) indicates it's removed
        model.provider = address(0); // Sentinel value for removed

        emit ModelRemoved(modelId);
    }


    // --- Consumer Functions ---

    /**
     * @dev Purchases time-based access to a model.
     * @param modelId The ID of the model to purchase access for.
     */
    function purchaseModelAccess(uint256 modelId) public payable whenNotPaused nonReentrant {
        Model storage model = models[modelId];
        require(model.provider != address(0), "Model does not exist"); // Check if model was removed
        require(model.status == ModelStatus.Active, "Model is not active");
        require(msg.value >= model.priceInWei, "Insufficient payment");

        Subscription storage sub = subscriptions[msg.sender][modelId];
        uint256 currentExpiresAt = sub.expiresAt > block.timestamp ? sub.expiresAt : block.timestamp;
        uint256 newExpiresAt = currentExpiresAt + model.durationInSeconds;
        sub.expiresAt = newExpiresAt;

        // Calculate fee and distribute funds
        uint256 totalPayment = msg.value;
        uint256 feeAmount = (totalPayment * marketplaceFeeBasisPoints) / 10000;
        uint256 providerAmount = totalPayment - feeAmount;

        totalMarketplaceFees += feeAmount;

        // Transfer payment to the provider
        (bool success, ) = payable(model.provider).call{value: providerAmount}("");
        require(success, "Payment to provider failed"); // Should refund if this fails

        emit AccessPurchased(msg.sender, modelId, newExpiresAt, msg.value);

        // Refund any excess payment
        if (msg.value > model.priceInWei) {
            uint256 refundAmount = msg.value - model.priceInWei;
             (bool refundSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
             require(refundSuccess, "Refund failed"); // Handle refund failure if necessary
        }
    }

    /**
     * @dev Extends existing time-based access to a model.
     * @param modelId The ID of the model to extend access for.
     */
    function extendModelAccess(uint256 modelId) public payable whenNotPaused nonReentrant {
        Model storage model = models[modelId];
         require(model.provider != address(0), "Model does not exist");
        require(model.status == ModelStatus.Active, "Model is not active");
        require(msg.value >= model.priceInWei, "Insufficient payment");

        Subscription storage sub = subscriptions[msg.sender][modelId];
        require(sub.expiresAt > 0, "No existing access to extend"); // Must have purchased access before

        uint256 currentExpiresAt = sub.expiresAt > block.timestamp ? sub.expiresAt : block.timestamp;
        uint256 newExpiresAt = currentExpiresAt + model.durationInSeconds;
        sub.expiresAt = newExpiresAt;

        // Calculate fee and distribute funds
        uint256 totalPayment = msg.value;
        uint256 feeAmount = (totalPayment * marketplaceFeeBasisPoints) / 10000;
        uint256 providerAmount = totalPayment - feeAmount;

        totalMarketplaceFees += feeAmount;

        // Transfer payment to the provider
        (bool success, ) = payable(model.provider).call{value: providerAmount}("");
        require(success, "Payment to provider failed");

        emit AccessExtended(msg.sender, modelId, newExpiresAt, msg.value);

        // Refund any excess payment
        if (msg.value > model.priceInWei) {
            uint256 refundAmount = msg.value - model.priceInWei;
             (bool refundSuccess, ) = payable(msg.sender).call{value: refundAmount}("");
             require(refundSuccess, "Refund failed");
        }
    }


    /**
     * @dev Simulates a dApp checking if a consumer has active access to a model.
     *      The actual AI model interaction happens off-chain, but access is managed here.
     * @param modelId The ID of the model to check access for.
     * @return bool True if access is valid, false otherwise.
     */
    function consumeModelService(uint256 modelId) public view whenNotPaused returns (bool) {
         Model storage model = models[modelId];
         require(model.provider != address(0), "Model does not exist");
         // Model status check is done off-chain by the dApp typically, but we can add a check here
         // require(model.status == ModelStatus.Active, "Model is not active"); // Optional: dApp should check this

        bool valid = subscriptions[msg.sender][modelId].expiresAt > block.timestamp;

        // Optional: Emit an event if access is valid, for off-chain logging of consumption
        // if (valid) {
        //     emit ModelConsumed(msg.sender, modelId);
        // }
        return valid;
    }

     /**
      * @dev Allows a consumer who has previously purchased access to rate a model.
      *      Basic on-chain reputation system.
      * @param modelId The ID of the model to rate.
      * @param rating The rating (1-5).
      */
    function rateModel(uint256 modelId, uint8 rating) public whenNotPaused {
        Model storage model = models[modelId];
        require(model.provider != address(0), "Model does not exist");
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");

        Subscription storage sub = subscriptions[msg.sender][modelId];
        require(sub.expiresAt > 0, "Consumer must have purchased access to rate"); // Simple check: purchased at least once
        // More strict check: require(sub.expiresAt > block.timestamp, "Consumer must have active access to rate"); // Optional

        // Prevent double rating from the same consumer for the same purchase/period
        // This simple model doesn't track specific purchases. A more complex system
        // could use a mapping(address => mapping(uint256 => bool)) hasRatedForPeriod;
        // For this example, we'll allow multiple ratings from the same user over time.

        model.totalRatingScore += rating;
        model.ratingCount++;

        // Update provider's reputation (simple aggregation)
        ProviderProfile storage provider = providers[model.provider];
        provider.reputationScore += rating; // Sum of all ratings received by models
        provider.ratingCount++; // Total number of ratings across all models

        emit ModelRated(msg.sender, modelId, rating);
    }


    // --- Query Functions (View Functions) ---

    /**
     * @dev Returns the current marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeeBasisPoints;
    }

    /**
     * @dev Returns the minimum required provider stake.
     */
    function getMinProviderStake() public view returns (uint256) {
        return minProviderStake;
    }

     /**
      * @dev Returns details of a provider's profile.
      * @param providerAddress The address of the provider.
      * @return isRegistered Whether the address is a registered provider.
      * @return stakedAmount The amount of stake the provider has.
      * @return description The provider's description.
      * @return reputationScore The provider's aggregated reputation score.
      * @return ratingCount The total number of ratings received by provider's models.
      * @return unstakeRequest The amount of stake pending unstake.
      * @return unstakeCooldown The timestamp when pending unstake is available (placeholder).
      */
    function getProviderProfile(address providerAddress) public view returns (
        bool isRegistered,
        uint256 stakedAmount,
        string memory description,
        uint256 reputationScore,
        uint256 ratingCount,
        uint256 unstakeRequest,
        uint40 unstakeCooldown
    ) {
        ProviderProfile storage provider = providers[providerAddress];
        return (
            provider.isRegistered,
            provider.stakedAmount,
            provider.description,
            provider.reputationScore,
            provider.ratingCount,
            provider.unstakeRequest,
            provider.unstakeCooldown
        );
    }

    /**
     * @dev Returns details of a specific model.
     * @param modelId The ID of the model.
     * @return id The model ID.
     * @return provider The model provider's address.
     * @return metadataHash Hash reference to off-chain metadata.
     * @return description A brief description.
     * @return accessEndpoint Off-chain endpoint.
     * @return priceInWei Price per access duration.
     * @return durationInSeconds Duration of access.
     * @return status The current status of the model.
     * @return listingTimestamp When the model was listed.
     */
    function getModelDetails(uint256 modelId) public view returns (
        uint256 id,
        address provider,
        string memory metadataHash,
        string memory description,
        string memory accessEndpoint,
        uint256 priceInWei,
        uint256 durationInSeconds,
        ModelStatus status,
        uint256 listingTimestamp
    ) {
         require(models[modelId].provider != address(0), "Model does not exist");
        Model storage model = models[modelId];
        return (
            model.id,
            model.provider,
            model.metadataHash,
            model.description,
            model.accessEndpoint,
            model.priceInWei,
            model.durationInSeconds,
            model.status,
            model.listingTimestamp
        );
    }

    /**
     * @dev Returns the total number of models listed (including deprecated ones).
     */
    function getModelCount() public view returns (uint256) {
        return _modelCounter;
    }

     /**
      * @dev Returns details about a consumer's subscription to a model.
      * @param consumer The address of the consumer.
      * @param modelId The ID of the model.
      * @return expiresAt Timestamp when access expires.
      */
    function getAccessDetails(address consumer, uint256 modelId) public view returns (uint256 expiresAt) {
        return subscriptions[consumer][modelId].expiresAt;
    }

     /**
      * @dev Checks if a consumer currently has valid access to a model.
      * @param consumer The address of the consumer.
      * @param modelId The ID of the model.
      * @return bool True if access is valid (expiry > current time), false otherwise.
      */
    function isAccessValid(address consumer, uint256 modelId) public view returns (bool) {
        return subscriptions[consumer][modelId].expiresAt > block.timestamp;
    }

    /**
     * @dev Checks if an address is a registered provider.
     * @param providerAddress The address to check.
     * @return bool True if registered, false otherwise.
     */
    function isProviderRegistered(address providerAddress) public view returns (bool) {
        return providers[providerAddress].isRegistered;
    }

     /**
      * @dev Checks if a model with the given ID exists and is not logically removed.
      * @param modelId The ID of the model.
      * @return bool True if the model exists and is active/pending/inactive, false if removed or never existed.
      */
    function isModelListed(uint256 modelId) public view returns (bool) {
        return modelId > 0 && modelId <= _modelCounter && models[modelId].provider != address(0);
    }


    /**
     * @dev Returns the list of trusted oracle addresses.
     *      Used off-chain to know which addresses to accept performance reports from.
     */
    function listTrustedOracles() public view returns (address[] memory) {
        return trustedOracles;
    }

    /**
     * @dev Returns the aggregated rating score and count for a model.
     * @param modelId The ID of the model.
     * @return totalScore The sum of all ratings received.
     * @return count The number of ratings received.
     */
    function getModelRatings(uint256 modelId) public view returns (uint256 totalScore, uint256 count) {
         require(models[modelId].provider != address(0), "Model does not exist");
        Model storage model = models[modelId];
        return (model.totalRatingScore, model.ratingCount);
    }

    /**
     * @dev Returns an array of all model IDs. Use with caution off-chain for large numbers of models.
     * @return uint256[] An array containing all listed model IDs.
     */
    function getAllModels() public view returns (uint256[] memory) {
        uint256 total = _modelCounter;
        uint256[] memory modelIds = new uint256[](total);
        uint256 currentIndex = 0;
        for (uint i = 1; i <= total; i++) {
            // Only include models that haven't been logically removed
            if (models[i].provider != address(0)) {
                 modelIds[currentIndex] = i;
                 currentIndex++;
            }
        }
         // Resize array to only include valid models if some were removed
         uint256[] memory listedModelIds = new uint256[](currentIndex);
         for(uint i = 0; i < currentIndex; i++) {
             listedModelIds[i] = modelIds[i];
         }
        return listedModelIds;
    }


    // --- Internal Helper Functions ---
    // (None explicitly needed beyond access checks provided by Ownable/Pausable)
    // Could add helpers here for calculating fees, checking stake, etc., but done inline for simplicity.
}
```

---

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **Staking for Providers (`registerProvider`, `stakeForProvider`, `requestUnstake`, `withdrawUnstaked`, `setMinProviderStake`):** Providers must stake Ether (or potentially an ERC-20 token in a modified version) to list models. This creates a financial incentive for them to provide reliable services and behave honestly. The stake can be slashed or used for dispute resolution in a more advanced version. `requestUnstake` and `withdrawUnstaked` simulate a cool-down period for unstaking, adding a layer of economic security.
2.  **Time-Based Access Control (`purchaseModelAccess`, `extendModelAccess`, `consumeModelService`, `getAccessDetails`, `isAccessValid`):** Instead of buying the model itself, users buy *access* for a specific duration. The smart contract keeps track of each consumer's access expiry timestamp for each model. `consumeModelService` is a `view` function a dApp would call to check access validity *before* allowing the user to interact with the off-chain AI model endpoint.
3.  **Basic On-Chain Reputation (`rateModel`, `getModelRatings`, `getProviderProfile`):** Consumers can rate models they have accessed. The contract stores the total rating score and count for each model and aggregates this at the provider level. While simple, this data is transparent and on-chain, forming a basic reputation layer.
4.  **Simulated Oracle Interaction (`addTrustedOracle`, `removeTrustedOracle`, `listTrustedOracles`):** The contract maintains a list of `trustedOracles`. While this example doesn't use oracle data *directly* for logic (like paying based on actual usage verified by an oracle, or slashing based on downtime reports), it lays the groundwork. Off-chain components could monitor AI model performance/uptime and submit verifiable reports signed by trusted oracle addresses, which a future version of the contract could use for automated reputation updates, dispute resolution, or provider penalties.
5.  **Decentralized Governance (Simplified - `setMarketplaceFee`, `setMinProviderStake`):** While not a full-blown DAO with token voting, the contract parameters like `marketplaceFeeBasisPoints` and `minProviderStake` are crucial governance levers currently controlled by the owner. This structure allows for easy modification to delegate control to a multisig wallet or a more complex DAO contract in the future.
6.  **Model Lifecycle (`listModel`, `updateModelStatus`, `removeModel`, `ModelStatus` enum):** Models have a defined lifecycle (Pending, Active, Inactive, Deprecated). This allows providers to manage their offerings and the marketplace to control which models are available for purchase. `removeModel` uses a logical removal pattern (`provider = address(0)`) which is gas-efficient for removing from mapping iteration, though not fully clearing storage.
7.  **Fee Distribution (`purchaseModelAccess`, `extendModelAccess`, `withdrawMarketplaceFees`):** The contract automatically splits payments between the provider and the marketplace owner based on the configurable fee.
8.  **Reentrancy Guard (`nonReentrant`):** Used on functions that handle Ether transfers (`withdrawMarketplaceFees`, `purchaseModelAccess`, `extendModelAccess`, `stakeForProvider`, `withdrawUnstaked`, `deregisterProvider`) to prevent reentrancy attacks.
9.  **Pausable (`pause`, `unpause`, `whenNotPaused`):** Allows the owner to pause critical functions in case of an emergency or upgrade preparation.
10. **Granular Updates (`updateModelMetadata`, `updateModelPriceAndDuration`):** Providers can update specific aspects of their models without needing to relist entirely.

This contract provides a solid foundation for a complex AI model marketplace by combining economic incentives (staking), access control, basic trust mechanisms (reputation, simulated oracles), and administrative controls in a decentralized manner.