Okay, let's design a smart contract for a "Decentralized AI Model Marketplace and Licensing Platform." This concept combines aspects of digital asset ownership, licensing, reputation, and staking, all managed on-chain. It doesn't run AI itself, but manages the *rights* and *incentives* around AI models which reside off-chain.

Here's the concept:
*   Users (Creators) can register AI models (metadata, off-chain URI, pricing).
*   Users (Customers) can purchase licenses to *use* these models (timed or usage-based).
*   The contract manages licenses, payments, and earnings distribution.
*   A staking mechanism allows users to stake on models, signalling confidence and potentially earning rewards (though reward distribution logic can be complex and might be left for L2 or future extensions, we can implement the staking itself).
*   A simple on-chain voting/reputation system for models (only accessible to license holders).
*   Marketplace fees are collected and managed by the owner.

This concept is relatively advanced as it goes beyond simple token transfers or basic NFT ownership, handling complex state like licenses, stakes, and reputation signals tied to specific digital assets (the models).

---

## Contract Outline and Function Summary

**Contract Name:** DecentralizedAIModelMarketplace

**Core Concept:** A platform for registering, licensing, and managing decentralized AI models (metadata and access rights managed on-chain, model execution off-chain). Includes features for model registration, license purchase/management, payments, staking on models, and model reputation voting.

**Key Components:**
*   `Model` Struct: Represents an AI model with metadata, pricing, status, and reputation scores.
*   `License` Struct: Represents a purchased license for a model, including user, duration, and status.
*   Mappings: Store models, licenses, user stakes, user earnings, etc.
*   Counters: Generate unique IDs for models and licenses.
*   `Ownable`: Standard access control for administrative functions.
*   `Pausable`: Allows pausing critical contract functions.

**Function Summary (Total: 25 Functions)**

**I. Model Management (7 functions)**
1.  `registerModel(string memory description, uint price, string memory modelURI)`: Register a new AI model. (Creator)
2.  `updateModelDetails(uint modelId, string memory description, string memory modelURI)`: Update description or URI for an existing model. (Creator)
3.  `updateModelPricing(uint modelId, uint newPrice)`: Update the price of a model. (Creator)
4.  `deactivateModel(uint modelId)`: Deactivate a model, preventing new licenses from being purchased. (Creator)
5.  `activateModel(uint modelId)`: Reactivate a deactivated model. (Creator)
6.  `getModelDetails(uint modelId)`: View function to get details of a specific model. (Anyone)
7.  `listAllModels()`: View function to list IDs of all registered models. (Anyone)

**II. Licensing and Usage (5 functions)**
8.  `purchaseLicense(uint modelId, uint durationInDays)`: Purchase a license for a model. (Customer)
9.  `extendLicense(uint licenseId, uint additionalDays)`: Extend the duration of an existing license. (Customer)
10. `revokeLicense(uint licenseId)`: Creator of the model (or admin) can revoke a license (e.g., for terms violation).
11. `checkLicenseStatus(uint licenseId)`: View function to check if a license is currently active. (Anyone)
12. `getUserLicenses(address user)`: View function to get list of license IDs owned by a user. (Anyone)

**III. Payments and Fees (3 functions)**
13. `withdrawCreatorEarnings()`: Creator withdraws accumulated earnings from license sales. (Creator)
14. `setMarketplaceFee(uint basisPoints)`: Set the marketplace fee percentage (in basis points, e.g., 100 = 1%). (Owner)
15. `withdrawMarketplaceFees()`: Owner withdraws collected marketplace fees. (Owner)

**IV. Model Staking (4 functions)**
16. `stakeForModelQuality(uint modelId)`: Stake Ether on a model to signal confidence/support. (Anyone)
17. `unstakeFromModel(uint modelId, uint amount)`: Withdraw a portion or all of staked Ether from a model. (Staker)
18. `getTotalStakedOnModel(uint modelId)`: View function for total Ether staked on a model. (Anyone)
19. `getUserStakeOnModel(address user, uint modelId)`: View function for a user's staked amount on a model. (Anyone)

**V. Model Reputation (3 functions)**
20. `upvoteModel(uint modelId)`: Upvote a model (only for users who have ever held a license for this model).
21. `downvoteModel(uint modelId)`: Downvote a model (only for users who have ever held a license for this model).
22. `getModelVotes(uint modelId)`: View function to get upvote and downvote counts for a model. (Anyone)

**VI. Admin and Utility (3 functions)**
23. `pause()`: Pause core contract operations (licensing, staking, withdrawals). (Owner)
24. `unpause()`: Unpause contract operations. (Owner)
25. `transferOwnership(address newOwner)`: Transfer contract ownership. (Owner)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Optional: Could use ERC20 later

// Outline and Function Summary is provided above the contract code block.

contract DecentralizedAIModelMarketplace is Ownable, Pausable, ReentrancyGuard {

    // --- Data Structures ---

    struct Model {
        address creator;
        string description;
        uint price; // Price in Wei
        string modelURI; // URI or IPFS hash pointing to model metadata/access point
        bool isActive; // Can licenses be purchased?
        uint upvotes;
        uint downvotes;
        uint totalStaked; // Total Ether staked on this model
    }

    struct License {
        address user;
        uint modelId;
        uint purchaseTimestamp;
        uint expirationTimestamp; // 0 if perpetual or duration-based
        bool isActive; // Can be revoked
    }

    // --- State Variables ---

    uint private _modelIdCounter;
    mapping(uint => Model) public models;
    uint[] public allModelIds; // Simple array to list all model IDs

    uint private _licenseIdCounter;
    mapping(uint => License) public licenses;
    mapping(address => uint[]) public userLicenses; // User address => list of their license IDs
    mapping(uint => uint[]) public modelLicenses; // Model ID => list of associated license IDs

    // For tracking earnings per creator
    mapping(address => uint) public creatorEarnings;

    // Marketplace fee in basis points (e.g., 100 = 1%)
    uint public marketplaceFeeBasisPoints;
    uint public collectedFees;

    // Staking: user address => modelId => amount staked
    mapping(address => mapping(uint => uint)) public stakedBalances;

    // Reputation: User address => modelId => boolean (true if user ever held a license)
    mapping(address => mapping(uint => bool)) private userHasLicenseHistory;
    // Reputation: User address => modelId => vote status (-1: downvote, 0: no vote, 1: upvote)
    mapping(address => mapping(uint => int8)) private userVote;


    // --- Events ---

    event ModelRegistered(uint modelId, address creator, string description, uint price, string modelURI);
    event ModelUpdated(uint modelId, string description, string modelURI);
    event ModelPricingUpdated(uint modelId, uint newPrice);
    event ModelDeactivated(uint modelId);
    event ModelActivated(uint modelId);

    event LicensePurchased(uint licenseId, address indexed user, uint indexed modelId, uint pricePaid, uint durationInDays);
    event LicenseExtended(uint licenseId, uint additionalDays);
    event LicenseRevoked(uint licenseId, address indexed revoker);

    event EarningsWithdrawn(address indexed creator, uint amount);
    event MarketplaceFeeSet(uint newFeeBasisPoints);
    event MarketplaceFeesWithdrawn(uint amount);

    event Staked(address indexed user, uint indexed modelId, uint amount);
    event Unstaked(address indexed user, uint indexed modelId, uint amount);

    event Upvoted(address indexed user, uint indexed modelId);
    event Downvoted(address indexed user, uint indexed modelId);


    // --- Constructor ---

    constructor(uint initialMarketplaceFeeBasisPoints) Ownable(msg.sender) Pausable() {
        require(initialMarketplaceFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = initialMarketplaceFeeBasisPoints;
        _modelIdCounter = 0;
        _licenseIdCounter = 0;
    }

    // --- Modifiers ---

    modifier onlyModelCreator(uint _modelId) {
        require(models[_modelId].creator == msg.sender, "Only model creator can perform this action");
        _;
    }

    modifier onlyLicenseHolder(uint _licenseId) {
        require(licenses[_licenseId].user == msg.sender, "Only license holder can perform this action");
        _;
    }

     modifier onlyLicenseHistoryHolder(uint _modelId) {
        require(userHasLicenseHistory[msg.sender][_modelId], "Only users with past or current license can vote");
        _;
    }

    // --- I. Model Management (7 functions) ---

    /// @notice Registers a new AI model on the marketplace.
    /// @param description A brief description of the model.
    /// @param price The price of a license in Wei.
    /// @param modelURI A URI or hash pointing to the off-chain model metadata/access point.
    /// @return The ID of the newly registered model.
    function registerModel(string memory description, uint price, string memory modelURI)
        external
        whenNotPaused
        returns (uint)
    {
        _modelIdCounter++;
        uint modelId = _modelIdCounter;
        models[modelId] = Model(
            msg.sender,
            description,
            price,
            modelURI,
            true, // active by default
            0,    // initial upvotes
            0,    // initial downvotes
            0     // initial total staked
        );
        allModelIds.push(modelId);

        emit ModelRegistered(modelId, msg.sender, description, price, modelURI);
        return modelId;
    }

    /// @notice Updates the description or URI for an existing model.
    /// @param modelId The ID of the model to update.
    /// @param description The new description.
    /// @param modelURI The new URI.
    function updateModelDetails(uint modelId, string memory description, string memory modelURI)
        external
        whenNotPaused
        onlyModelCreator(modelId)
    {
        Model storage model = models[modelId];
        model.description = description;
        model.modelURI = modelURI;

        emit ModelUpdated(modelId, description, modelURI);
    }

    /// @notice Updates the price for an existing model.
    /// @param modelId The ID of the model to update.
    /// @param newPrice The new price in Wei.
    function updateModelPricing(uint modelId, uint newPrice)
        external
        whenNotPaused
        onlyModelCreator(modelId)
    {
        models[modelId].price = newPrice;
        emit ModelPricingUpdated(modelId, newPrice);
    }

    /// @notice Deactivates a model, preventing new licenses from being purchased.
    /// @param modelId The ID of the model to deactivate.
    function deactivateModel(uint modelId)
        external
        whenNotPaused
        onlyModelCreator(modelId)
    {
        require(models[modelId].isActive, "Model is already inactive");
        models[modelId].isActive = false;
        emit ModelDeactivated(modelId);
    }

    /// @notice Reactivates a deactivated model.
    /// @param modelId The ID of the model to activate.
    function activateModel(uint modelId)
        external
        whenNotPaused
        onlyModelCreator(modelId)
    {
        require(!models[modelId].isActive, "Model is already active");
        models[modelId].isActive = true;
        emit ModelActivated(modelId);
    }

    /// @notice Gets details of a specific model.
    /// @param modelId The ID of the model.
    /// @return Model details.
    function getModelDetails(uint modelId)
        external
        view
        returns (
            address creator,
            string memory description,
            uint price,
            string memory modelURI,
            bool isActive,
            uint upvotes,
            uint downvotes,
            uint totalStaked
        )
    {
        Model storage model = models[modelId];
        return (
            model.creator,
            model.description,
            model.price,
            model.modelURI,
            model.isActive,
            model.upvotes,
            model.downvotes,
            model.totalStaked
        );
    }

    /// @notice Lists IDs of all registered models.
    /// @return An array of all model IDs.
    function listAllModels() external view returns (uint[] memory) {
        return allModelIds;
    }

    // --- II. Licensing and Usage (5 functions) ---

    /// @notice Purchases a license for a specific model.
    /// @param modelId The ID of the model to purchase a license for.
    /// @param durationInDays The duration of the license in days (0 for perpetual, though implementation assumes duration > 0 for expiration).
    /// @return The ID of the newly created license.
    function purchaseLicense(uint modelId, uint durationInDays)
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint)
    {
        Model storage model = models[modelId];
        require(model.isActive, "Model is not active for licensing");
        require(msg.value >= model.price, "Insufficient payment");
        require(durationInDays > 0, "Duration must be greater than 0 days"); // For simplicity, no perpetual licenses

        uint pricePaid = model.price;
        uint feeAmount = (pricePaid * marketplaceFeeBasisPoints) / 10000;
        uint creatorAmount = pricePaid - feeAmount;

        // Distribute funds (no direct transfer here, collect for withdrawal)
        creatorEarnings[model.creator] += creatorAmount;
        collectedFees += feeAmount;

        // Refund any excess payment
        if (msg.value > pricePaid) {
            payable(msg.sender).transfer(msg.value - pricePaid);
        }

        _licenseIdCounter++;
        uint licenseId = _licenseIdCounter;
        uint expirationTimestamp = block.timestamp + (durationInDays * 1 days); // 1 days is a constant in Solidity

        licenses[licenseId] = License(
            msg.sender,
            modelId,
            block.timestamp,
            expirationTimestamp,
            true // active
        );

        userLicenses[msg.sender].push(licenseId);
        modelLicenses[modelId].push(licenseId);
        userHasLicenseHistory[msg.sender][modelId] = true; // Mark user has license history for this model

        emit LicensePurchased(licenseId, msg.sender, modelId, pricePaid, durationInDays);
        return licenseId;
    }

    /// @notice Extends the duration of an existing license.
    /// @param licenseId The ID of the license to extend.
    /// @param additionalDays The number of additional days to add to the expiration.
    function extendLicense(uint licenseId, uint additionalDays)
        external
        payable
        whenNotPaused
        nonReentrant
        onlyLicenseHolder(licenseId)
    {
        License storage license = licenses[licenseId];
        Model storage model = models[license.modelId];

        // Require payment based on current model price
        require(msg.value >= model.price, "Insufficient payment for extension");
        require(additionalDays > 0, "Additional duration must be greater than 0");

        uint pricePaid = model.price;
        uint feeAmount = (pricePaid * marketplaceFeeBasisPoints) / 10000;
        uint creatorAmount = pricePaid - feeAmount;

        // Distribute funds
        creatorEarnings[model.creator] += creatorAmount;
        collectedFees += feeAmount;

        // Refund any excess payment
        if (msg.value > pricePaid) {
            payable(msg.sender).transfer(msg.value - pricePaid);
        }

        // Extend expiration. If already expired, start from now. Otherwise, add to existing expiration.
        uint currentExpiration = license.expirationTimestamp;
        uint newExpiration;
        if (currentExpiration < block.timestamp) {
            newExpiration = block.timestamp + (additionalDays * 1 days);
        } else {
             newExpiration = currentExpiration + (additionalDays * 1 days);
        }

        license.expirationTimestamp = newExpiration;
        license.isActive = true; // Ensure license is active after extension

        emit LicenseExtended(licenseId, additionalDays);
    }

    /// @notice Revokes an active license. Can be called by the model creator or contract owner.
    /// @param licenseId The ID of the license to revoke.
    function revokeLicense(uint licenseId)
        external
        whenNotPaused
    {
        License storage license = licenses[licenseId];
        require(license.isActive, "License is already inactive");
        
        Model storage model = models[license.modelId];
        require(msg.sender == model.creator || msg.sender == owner(), "Only model creator or owner can revoke");

        license.isActive = false; // Mark as inactive

        emit LicenseRevoked(licenseId, msg.sender);
        // Note: No refund is implemented here. This is a harsh revocation.
    }


    /// @notice Checks the status of a specific license.
    /// @param licenseId The ID of the license.
    /// @return isActive Whether the license is currently active and not expired.
    /// @return expirationTimestamp The expiration timestamp of the license.
    function checkLicenseStatus(uint licenseId)
        external
        view
        returns (bool isActive, uint expirationTimestamp)
    {
        License storage license = licenses[licenseId];
        isActive = license.isActive && (license.expirationTimestamp == 0 || license.expirationTimestamp > block.timestamp);
        expirationTimestamp = license.expirationTimestamp;
    }

    /// @notice Gets all license IDs for a specific user.
    /// @param user The address of the user.
    /// @return An array of license IDs.
    function getUserLicenses(address user) external view returns (uint[] memory) {
        return userLicenses[user];
    }

     /// @notice Gets details of a specific license.
    /// @param licenseId The ID of the license.
    /// @return license details.
    function getLicenseDetails(uint licenseId)
        external
        view
        returns (
            address user,
            uint modelId,
            uint purchaseTimestamp,
            uint expirationTimestamp,
            bool isActive
        )
    {
        License storage license = licenses[licenseId];
        return (
            license.user,
            license.modelId,
            license.purchaseTimestamp,
            license.expirationTimestamp,
            license.isActive && (license.expirationTimestamp == 0 || license.expirationTimestamp > block.timestamp) // Check active and not expired
        );
    }


    // --- III. Payments and Fees (3 functions) ---

    /// @notice Creator withdraws their accumulated earnings.
    function withdrawCreatorEarnings()
        external
        nonReentrant
        whenNotPaused // Prevent withdrawal if paused? Depends on desired pause scope. Let's allow it.
    {
        uint amount = creatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");

        creatorEarnings[msg.sender] = 0; // Set balance to 0 before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");

        emit EarningsWithdrawn(msg.sender, amount);
    }

    /// @notice Sets the marketplace fee percentage.
    /// @param basisPoints The new fee in basis points (e.g., 100 = 1%). Max 10000 (100%).
    function setMarketplaceFee(uint basisPoints) external onlyOwner {
        require(basisPoints <= 10000, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = basisPoints;
        emit MarketplaceFeeSet(basisPoints);
    }

    /// @notice Owner withdraws collected marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner nonReentrant {
        uint amount = collectedFees;
        require(amount > 0, "No fees to withdraw");

        collectedFees = 0; // Set balance to 0 before sending

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");

        emit MarketplaceFeesWithdrawn(amount);
    }

    // --- IV. Model Staking (4 functions) ---

    /// @notice Stakes Ether on a specific model. Signifies support/confidence.
    /// @param modelId The ID of the model to stake on.
    function stakeForModelQuality(uint modelId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(msg.value > 0, "Must stake a non-zero amount");
        require(models[modelId].creator != address(0), "Model does not exist"); // Check if modelId is valid

        stakedBalances[msg.sender][modelId] += msg.value;
        models[modelId].totalStaked += msg.value;

        emit Staked(msg.sender, modelId, msg.value);
    }

    /// @notice Unstakes Ether from a specific model.
    /// @param modelId The ID of the model to unstake from.
    /// @param amount The amount of Ether to unstake (in Wei).
    function unstakeFromModel(uint modelId, uint amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "Must unstake a non-zero amount");
        require(models[modelId].creator != address(0), "Model does not exist"); // Check if modelId is valid
        require(stakedBalances[msg.sender][modelId] >= amount, "Insufficient staked balance");

        stakedBalances[msg.sender][modelId] -= amount;
        models[modelId].totalStaked -= amount; // Should not underflow due to previous check

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Ether transfer failed");

        emit Unstaked(msg.sender, modelId, amount);
    }

    /// @notice Gets the total amount of Ether staked on a model.
    /// @param modelId The ID of the model.
    /// @return The total staked amount in Wei.
    function getTotalStakedOnModel(uint modelId) external view returns (uint) {
        // No require check here, just returns 0 if model doesn't exist
        return models[modelId].totalStaked;
    }

    /// @notice Gets the amount of Ether a specific user has staked on a model.
    /// @param user The address of the user.
    /// @param modelId The ID of the model.
    /// @return The user's staked amount in Wei.
    function getUserStakeOnModel(address user, uint modelId) external view returns (uint) {
        // No require check here, just returns 0 if not staked
        return stakedBalances[user][modelId];
    }

    // --- V. Model Reputation (3 functions) ---

    /// @notice Upvotes a model. Limited to users who have ever held a license for this model.
    /// @param modelId The ID of the model to upvote.
    function upvoteModel(uint modelId)
        external
        whenNotPaused
        onlyLicenseHistoryHolder(modelId) // Restrict voting to past/present license holders
    {
        require(models[modelId].creator != address(0), "Model does not exist"); // Check if modelId is valid
        int8 currentVote = userVote[msg.sender][modelId];

        if (currentVote == 1) {
            // Already upvoted, do nothing
            return;
        }

        if (currentVote == -1) {
            // Previously downvoted, remove downvote first
            models[modelId].downvotes--;
        }

        models[modelId].upvotes++;
        userVote[msg.sender][modelId] = 1;

        emit Upvoted(msg.sender, modelId);
    }

    /// @notice Downvotes a model. Limited to users who have ever held a license for this model.
    /// @param modelId The ID of the model to downvote.
    function downvoteModel(uint modelId)
        external
        whenNotPaused
        onlyLicenseHistoryHolder(modelId) // Restrict voting to past/present license holders
    {
        require(models[modelId].creator != address(0), "Model does not exist"); // Check if modelId is valid
        int8 currentVote = userVote[msg.sender][modelId];

        if (currentVote == -1) {
            // Already downvoted, do nothing
            return;
        }

        if (currentVote == 1) {
            // Previously upvoted, remove upvote first
            models[modelId].upvotes--;
        }

        models[modelId].downvotes++;
        userVote[msg.sender][modelId] = -1;

        emit Downvoted(msg.sender, modelId);
    }

    /// @notice Gets the upvote and downvote counts for a model.
    /// @param modelId The ID of the model.
    /// @return upvotes Count of upvotes.
    /// @return downvotes Count of downvotes.
    function getModelVotes(uint modelId) external view returns (uint upvotes, uint downvotes) {
         // No require check here, just returns 0 if model doesn't exist
        Model storage model = models[modelId];
        return (model.upvotes, model.downvotes);
    }

    // --- VI. Admin and Utility (3 functions) ---

    /// @notice Pauses core contract operations.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses core contract operations.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership is inherited from Ownable

    // Fallback function to accept Ether (e.g., for staking without calling a specific function)
    receive() external payable {
        // Optional: Add logic here to handle Ether sent directly.
        // For this contract, sending Ether without calling stakeForModelQuality
        // or purchaseLicense will increase the contract balance but won't be allocated.
        // It's generally better practice to require explicit function calls for actions.
        // Leaving this minimal for simplicity.
    }

    // Optional: function to allow withdrawal of accidental Ether sends not associated with stakes/earnings
    // function withdrawAccidentalEther() external onlyOwner nonReentrant {
    //     uint balance = address(this).balance - collectedFees - creatorEarnings[owner()] - totalStakedOnContract();
    //     require(balance > 0, "No accidental ether to withdraw");
    //     (bool success, ) = payable(owner()).call{value: balance}("");
    //     require(success, "Ether transfer failed");
    // }

    // Helper view function (not counted in the 20+) - useful for debugging
    // function totalStakedOnContract() internal view returns(uint) {
    //     // Calculating total staked across all models would require iterating all models,
    //     // which is gas expensive. models[modelId].totalStaked is better.
    //     // This helper is omitted for practicality.
    //     return 0; // Placeholder
    // }
}
```