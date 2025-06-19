Okay, let's design a smart contract that combines several advanced concepts: a **Decentralized AI Model Marketplace with NFT Licenses, Owner Earnings Distribution, and Reputation (Ratings/Reporting)**.

This contract will allow AI model developers to list their models, users to purchase licenses represented as NFTs, handle fee distribution to the marketplace owner and model owners, and include basic rating and reporting mechanisms.

It incorporates:
1.  **NFTs (ERC-721):** Licenses are unique ERC-721 tokens.
2.  **Payment Handling:** Accepts Ether (ETH) or ERC-20 tokens.
3.  **Fee Distribution:** Splits payment between model owner and marketplace owner.
4.  **Owner Earnings:** Allows model owners to withdraw earned ETH/tokens.
5.  **Time-Limited Licenses:** Supports licenses that expire.
6.  **Basic Reputation:** Allows buyers to rate models and users to report problematic ones.
7.  **Off-chain Data References:** Uses IPFS/Arweave hashes for model files and metadata.
8.  **Access Control:** Owner for marketplace settings, Model Owners for model management.
9.  **Reentrancy Protection:** Standard security practice.

This is significantly more complex than basic token or simple marketplace contracts and avoids duplicating common open-source patterns directly.

---

**Outline and Function Summary:**

**Contract Name:** `DecentralizedAIModelMarketplace`

**Core Concepts:**
*   AI Model Listing (referenced by IPFS/Arweave hashes)
*   NFT-based Licensing (ERC-721)
*   Payment Processing (ETH & ERC-20)
*   Fee & Earnings Distribution
*   Time-Limited Licenses & Renewal
*   Model Rating & Reporting System
*   ERC-721 Standard Implementation

**Structs:**
*   `Model`: Stores model details (owner, price, hashes, status, etc.)
*   `License`: Stores license details (buyer, modelId, type, expiry, price paid, etc.)
*   `Report`: Stores details of a model report (reporter, reason, status, etc.)

**Enums:**
*   `LicenseType`: PERPETUAL, TIME_LIMITED, SUBSCRIPTION (Simplified: use TIME_LIMITED for both variable expiry/subscription)
*   `ReportStatus`: PENDING, RESOLVED_VALID, RESOLVED_INVALID

**State Variables:**
*   Counters for unique Model, License, and Report IDs.
*   Mappings for storing Model, License, Report data by ID.
*   Mapping for Model ratings (modelId -> list of ratings).
*   Mapping for owner balances (address -> ETH/token balance).
*   Marketplace fee percentage (basis points).
*   Standard ERC-721 mappings (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   Owner address (`Ownable`).
*   Supported ERC-20 token addresses.

**Events:**
*   `ModelListed(uint256 modelId, address owner, string ipfsHash, uint256 price)`
*   `ModelUpdated(uint256 modelId, uint256 newPrice, bool activeStatus)`
*   `ModelWithdrawn(uint256 modelId)`
*   `LicensePurchased(uint256 licenseId, uint256 modelId, address buyer, uint256 pricePaid, LicenseType licenseType, uint256 expiryTimestamp)`
*   `LicenseRenewed(uint256 licenseId, uint256 newExpiryTimestamp, uint256 amountPaid)`
*   `FundsWithdrawn(address owner, uint256 amount)` (For Model Owners)
*   `MarketplaceFeeWithdrawn(address to, uint256 amount)` (For Marketplace Owner)
*   `ModelRated(uint256 modelId, uint256 licenseId, uint8 rating)`
*   `ModelReported(uint256 reportId, uint256 modelId, address reporter)`
*   `ReportResolved(uint256 reportId, ReportStatus status)`
*   ERC-721 Standard Events (`Transfer`, `Approval`, `ApprovalForAll`)

**Function Summary (Minimum 20 functions):**

1.  `constructor()`: Initializes contract owner and fee percentage.
2.  `setMarketplaceFee(uint256 _feeBasisPoints)`: Owner function to set the marketplace fee.
3.  `addSupportedToken(address _tokenAddress)`: Owner function to add a supported ERC-20 token for payments.
4.  `removeSupportedToken(address _tokenAddress)`: Owner function to remove a supported ERC-20 token.
5.  `getMarketplaceFeeBasisPoints()`: Get current marketplace fee.
6.  `isTokenSupported(address _tokenAddress)`: Check if an ERC-20 token is supported.
7.  `listModel(string memory _ipfsHash, string memory _metadataHash, uint256 _price, address _paymentToken, LicenseType _licenseType, uint256 _licenseTermSeconds, string memory _description)`: List a new AI model on the marketplace.
8.  `updateModel(uint256 _modelId, uint256 _newPrice, string memory _newIpfsHash, string memory _newMetadataHash, string memory _newDescription, LicenseType _newLicenseType, uint256 _newLicenseTermSeconds)`: Update details of an existing model (only by model owner).
9.  `withdrawModel(uint256 _modelId)`: Deactivate a model listing (prevents new purchases).
10. `reactivateModel(uint256 _modelId)`: Re-activate a withdrawn model listing.
11. `getModelDetails(uint256 _modelId)`: Retrieve details of a specific model.
12. `getModelsCount()`: Get the total number of listed models.
13. `getModelsByOwner(address _owner)`: Get list of model IDs owned by an address.
14. `purchaseLicense(uint256 _modelId)`: Purchase a license for a model using ETH. Handles payment, fee distribution, mints NFT.
15. `purchaseLicenseERC20(uint256 _modelId, address _tokenContract)`: Purchase a license using a supported ERC-20 token (requires prior approval).
16. `getLicenseDetails(uint256 _licenseId)`: Retrieve details of a specific license.
17. `isLicenseValid(uint256 _licenseId)`: Check if a time-limited license is currently valid (not expired).
18. `renewLicense(uint256 _licenseId)`: Renew an expired or expiring time-limited license (requires payment).
19. `withdrawOwnerFunds(address payable _tokenContract)`: Model owners withdraw their accumulated earnings (either ETH or a specific ERC-20).
20. `getOwnerBalance(address _owner, address _tokenContract)`: Get the balance of earnings available for withdrawal by a model owner for a specific token (or ETH).
21. `submitModelRating(uint256 _licenseId, uint8 _rating)`: Submit a rating (1-5) for a model using a valid license.
22. `getModelAverageRating(uint256 _modelId)`: Get the calculated average rating for a model.
23. `reportModel(uint256 _modelId, string memory _reason)`: Submit a report about a specific model.
24. `getReportsCount()`: Get total number of reports submitted.
25. `getReportDetails(uint256 _reportId)`: Retrieve details of a specific report.
26. `resolveReport(uint256 _reportId, ReportStatus _status)`: Owner function to resolve a report.
27. `withdrawMarketplaceFees(address payable _tokenContract, address payable _to)`: Owner function to withdraw accumulated marketplace fees (either ETH or a specific ERC-20).
28. `tokenURI(uint256 _tokenId)`: ERC-721 standard - Returns the metadata URI for a license NFT.
29. `getApproved(uint256 tokenId)`: ERC-721 standard - Get the approved address for a single token.
30. `isApprovedForAll(address owner, address operator)`: ERC-721 standard - Query if an operator is approved for all owner's tokens.

*(Includes standard ERC-721 functions like `balanceOf`, `ownerOf`, `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll` implicitly via inheritance or explicit implementation, bringing the total well over 20)*.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary Above ---

contract DecentralizedAIModelMarketplace is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // State Variables
    Counters.Counter private _modelCounter;
    Counters.Counter private _licenseCounter;
    Counters.Counter private _reportCounter;

    // Data Structures
    enum LicenseType { PERPETUAL, TIME_LIMITED }
    enum ReportStatus { PENDING, RESOLVED_VALID, RESOLVED_INVALID }

    struct Model {
        uint256 id;
        address owner;
        string ipfsHash; // Hash of the actual model files (e.g., trained weights)
        string metadataHash; // Hash of the model metadata (description, requirements, etc.)
        uint256 price; // Price in Wei or ERC20 token units
        address paymentToken; // Address of the ERC20 token, or address(0) for ETH
        LicenseType licenseType;
        uint256 licenseTermSeconds; // Term for TIME_LIMITED in seconds
        string description;
        bool isActive; // True if available for purchase
        uint256 timestampListed;
    }

    struct License {
        uint256 id;
        uint256 modelId;
        address buyer;
        LicenseType licenseType;
        uint256 pricePaid; // Price paid in the original token units
        address paymentToken; // Token used for payment
        uint256 purchaseTimestamp;
        uint256 expiryTimestamp; // 0 for PERPETUAL
        // ERC721 token data handled by ERC721 contract storage (_owners, _tokenApprovals etc.)
    }

     struct Report {
        uint256 id;
        uint256 modelId;
        address reporter;
        string reason;
        ReportStatus status;
        uint256 timestamp;
     }

    // Mappings
    mapping(uint256 => Model) public models;
    mapping(uint256 => License) public licenses;
    mapping(uint256 => Report) public reports;

    // Model Ratings (Simple average for this example)
    mapping(uint256 => uint256[]) private _modelRatings; // modelId -> array of ratings (1-5)

    // Owner Balances (for withdrawing earnings)
    mapping(address => mapping(address => uint256)) private _ownerBalances; // ownerAddress -> tokenAddress -> balance (tokenAddress 0 for ETH)

    // Marketplace Fee Management
    uint256 private _marketplaceFeeBasisPoints; // e.g., 250 for 2.5% (250/10000)
    mapping(address => uint256) private _marketplaceFeeBalances; // tokenAddress -> balance (tokenAddress 0 for ETH)

    // Supported ERC-20 Tokens
    mapping(address => bool) private _supportedTokens;

    // Events
    event ModelListed(uint256 modelId, address owner, string ipfsHash, uint256 price);
    event ModelUpdated(uint256 modelId, uint256 newPrice, bool activeStatus);
    event ModelWithdrawn(uint256 modelId);
    event LicensePurchased(uint256 licenseId, uint256 modelId, address buyer, uint256 pricePaid, LicenseType licenseType, uint256 expiryTimestamp);
    event LicenseRenewed(uint256 licenseId, uint256 newExpiryTimestamp, uint256 amountPaid);
    event FundsWithdrawn(address owner, address tokenContract, uint256 amount); // Unified withdrawal event
    event MarketplaceFeeWithdrawn(address tokenContract, address to, uint256 amount);
    event ModelRated(uint256 modelId, uint256 licenseId, uint8 rating);
    event ModelReported(uint256 reportId, uint256 modelId, address reporter);
    event ReportResolved(uint256 reportId, ReportStatus status);

    // Constructor
    constructor(uint256 initialFeeBasisPoints) ERC721("AIModelLicense", "AILICENSE") Ownable(msg.sender) {
        require(initialFeeBasisPoints <= 10000, "Fee cannot exceed 100%");
        _marketplaceFeeBasisPoints = initialFeeBasisPoints;
    }

    // --- Owner/Admin Functions ---

    // 1. Initialized in constructor.
    // 2. Set marketplace fee percentage.
    function setMarketplaceFee(uint256 _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "Fee cannot exceed 100%");
        _marketplaceFeeBasisPoints = _feeBasisPoints;
    }

    // 3. Add a supported ERC-20 token.
    function addSupportedToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        _supportedTokens[_tokenAddress] = true;
    }

    // 4. Remove a supported ERC-20 token.
    function removeSupportedToken(address _tokenAddress) external onlyOwner {
        _supportedTokens[_tokenAddress] = false;
    }

    // 27. Owner withdraws accumulated marketplace fees for a specific token (or ETH).
    function withdrawMarketplaceFees(address payable _tokenContract, address payable _to) external onlyOwner nonReentrant {
        uint256 balance = _marketplaceFeeBalances[_tokenContract];
        require(balance > 0, "No fees available for withdrawal");

        _marketplaceFeeBalances[_tokenContract] = 0;

        if (_tokenContract == address(0)) { // ETH
            (bool success, ) = _to.call{value: balance}("");
            require(success, "ETH withdrawal failed");
        } else { // ERC20
            IERC20 token = IERC20(_tokenContract);
            require(token.transfer(_to, balance), "Token withdrawal failed");
        }

        emit MarketplaceFeeWithdrawn(_tokenContract, _to, balance);
    }

    // --- Getters for Marketplace Settings ---

    // 5. Get current marketplace fee.
    function getMarketplaceFeeBasisPoints() external view returns (uint256) {
        return _marketplaceFeeBasisPoints;
    }

    // 6. Check if an ERC-20 token is supported.
    function isTokenSupported(address _tokenAddress) external view returns (bool) {
        return _supportedTokens[_tokenAddress];
    }

    // --- Model Management (by Model Owners) ---

    // 7. List a new AI model.
    function listModel(
        string memory _ipfsHash,
        string memory _metadataHash,
        uint256 _price,
        address _paymentToken, // address(0) for ETH
        LicenseType _licenseType,
        uint256 _licenseTermSeconds,
        string memory _description
    ) external nonReentrant {
        require(bytes(_ipfsHash).length > 0, "IPFS hash is required");
        require(_price > 0, "Price must be greater than 0");
        require(_paymentToken == address(0) || _supportedTokens[_paymentToken], "Unsupported payment token");
        if (_licenseType == LicenseType.TIME_LIMITED) {
             require(_licenseTermSeconds > 0, "License term must be greater than 0 for time-limited licenses");
        } else {
             require(_licenseTermSeconds == 0, "License term must be 0 for perpetual licenses");
        }

        _modelCounter.increment();
        uint256 modelId = _modelCounter.current();

        models[modelId] = Model({
            id: modelId,
            owner: msg.sender,
            ipfsHash: _ipfsHash,
            metadataHash: _metadataHash,
            price: _price,
            paymentToken: _paymentToken,
            licenseType: _licenseType,
            licenseTermSeconds: _licenseTermSeconds,
            description: _description,
            isActive: true,
            timestampListed: block.timestamp
        });

        emit ModelListed(modelId, msg.sender, _ipfsHash, _price);
    }

    // 8. Update details of an existing model.
    function updateModel(
        uint256 _modelId,
        uint256 _newPrice,
        string memory _newIpfsHash,
        string memory _newMetadataHash,
        string memory _newDescription,
        LicenseType _newLicenseType,
        uint256 _newLicenseTermSeconds
    ) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can update");
        require(bytes(_newIpfsHash).length > 0, "IPFS hash is required");
        require(_newPrice > 0, "Price must be greater than 0");
         if (_newLicenseType == LicenseType.TIME_LIMITED) {
             require(_newLicenseTermSeconds > 0, "License term must be greater than 0 for time-limited licenses");
        } else {
             require(_newLicenseTermSeconds == 0, "License term must be 0 for perpetual licenses");
        }

        model.price = _newPrice;
        model.ipfsHash = _newIpfsHash;
        model.metadataHash = _newMetadataHash;
        model.description = _newDescription;
        model.licenseType = _newLicenseType;
        model.licenseTermSeconds = _newLicenseTermSeconds;

        emit ModelUpdated(_modelId, _newPrice, model.isActive);
    }

    // 9. Deactivate a model listing.
    function withdrawModel(uint256 _modelId) external nonReentrant {
        Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can withdraw");
        require(model.isActive, "Model is already withdrawn");

        model.isActive = false;
        emit ModelWithdrawn(_modelId);
    }

    // 10. Re-activate a withdrawn model listing.
    function reactivateModel(uint256 _modelId) external nonReentrant {
         Model storage model = models[_modelId];
        require(model.owner == msg.sender, "Only model owner can reactivate");
        require(!model.isActive, "Model is already active");

        model.isActive = true;
        emit ModelUpdated(_modelId, model.price, model.isActive); // Re-using event, maybe add a dedicated one?
    }

    // 19. Model owners withdraw their accumulated earnings.
    function withdrawOwnerFunds(address payable _tokenContract) external nonReentrant {
        uint256 balance = _ownerBalances[msg.sender][_tokenContract];
        require(balance > 0, "No funds available for withdrawal");

        _ownerBalances[msg.sender][_tokenContract] = 0;

        if (_tokenContract == address(0)) { // ETH
            (bool success, ) = msg.sender.call{value: balance}("");
             require(success, "ETH withdrawal failed");
        } else { // ERC20
            IERC20 token = IERC20(_tokenContract);
            require(token.transfer(msg.sender, balance), "Token withdrawal failed");
        }

        emit FundsWithdrawn(msg.sender, _tokenContract, balance);
    }

    // 20. Get the balance of earnings available for withdrawal by a model owner.
    function getOwnerBalance(address _owner, address _tokenContract) external view returns (uint256) {
        return _ownerBalances[_owner][_tokenContract];
    }

    // --- Model Browsing/Information ---

    // 11. Retrieve details of a specific model.
    function getModelDetails(uint256 _modelId) external view returns (Model memory) {
        require(_modelId > 0 && _modelId <= _modelCounter.current(), "Invalid model ID");
        return models[_modelId];
    }

    // 12. Get the total number of listed models (including inactive ones).
    function getModelsCount() external view returns (uint256) {
        return _modelCounter.current();
    }

    // 13. Get list of model IDs owned by an address.
    // Note: This can be gas-expensive if an owner has many models.
    // A more scalable approach would involve off-chain indexing or pagination.
    function getModelsByOwner(address _owner) external view returns (uint256[] memory) {
        uint256[] memory ownerModelIds = new uint256[](0);
        for (uint256 i = 1; i <= _modelCounter.current(); i++) {
            if (models[i].owner == _owner) {
                uint256 currentLength = ownerModelIds.length;
                uint256[] memory tmp = new uint256[](currentLength + 1);
                for (uint256 j = 0; j < currentLength; j++) {
                    tmp[j] = ownerModelIds[j];
                }
                tmp[currentLength] = i;
                ownerModelIds = tmp;
            }
        }
        return ownerModelIds;
    }


    // --- License Purchasing & Management ---

    // Internal function to handle payment and distribution
    function _handlePaymentAndDistribution(
        uint256 _totalAmount,
        address _paymentToken,
        address _payer,
        address _modelOwner
    ) private nonReentrant { // Mark as nonReentrant inside public/external callers
        uint256 marketplaceFee = (_totalAmount * _marketplaceFeeBasisPoints) / 10000;
        uint256 ownerShare = _totalAmount - marketplaceFee;

        if (_paymentToken == address(0)) { // ETH
            require(msg.value == _totalAmount, "Incorrect ETH amount sent");

            // Distribute to owner and marketplace balance
            _ownerBalances[_modelOwner][address(0)] += ownerShare;
            _marketplaceFeeBalances[address(0)] += marketplaceFee;

            // Remaining ETH stays in the contract to be withdrawn by owner/marketplace
            // No direct transfer here to prevent reentrancy
        } else { // ERC20
            IERC20 token = IERC20(_paymentToken);
            // Transfer from buyer to contract
            require(token.transferFrom(_payer, address(this), _totalAmount), "ERC20 transfer failed");

            // Distribute to owner and marketplace balances
            _ownerBalances[_modelOwner][_paymentToken] += ownerShare;
            _marketplaceFeeBalances[_paymentToken] += marketplaceFee;
        }
    }

    // 14. Purchase a license using ETH.
    function purchaseLicense(uint256 _modelId) external payable nonReentrant {
        Model storage model = models[_modelId];
        require(model.isActive, "Model is not active for purchase");
        require(model.paymentToken == address(0), "Model requires ERC20 payment, use purchaseLicenseERC20");

        uint256 totalEthAmount = model.price;
        require(msg.value == totalEthAmount, "Incorrect ETH amount sent");

        _handlePaymentAndDistribution(totalEthAmount, address(0), msg.sender, model.owner);

        _licenseCounter.increment();
        uint256 licenseId = _licenseCounter.current();

        uint256 expiry = 0;
        if (model.licenseType == LicenseType.TIME_LIMITED) {
            expiry = block.timestamp + model.licenseTermSeconds;
        }

        licenses[licenseId] = License({
            id: licenseId,
            modelId: _modelId,
            buyer: msg.sender,
            licenseType: model.licenseType,
            pricePaid: model.price,
            paymentToken: address(0),
            purchaseTimestamp: block.timestamp,
            expiryTimestamp: expiry
        });

        _safeMint(msg.sender, licenseId);

        emit LicensePurchased(licenseId, _modelId, msg.sender, model.price, model.licenseType, expiry);
    }

    // 15. Purchase a license using a supported ERC-20 token.
    // Buyer must approve this contract to spend the tokens first.
    function purchaseLicenseERC20(uint256 _modelId, address _tokenContract) external nonReentrant {
         Model storage model = models[_modelId];
        require(model.isActive, "Model is not active for purchase");
        require(model.paymentToken == _tokenContract, "Model requires different payment token");
        require(_supportedTokens[_tokenContract], "Unsupported payment token");

        uint256 totalTokenAmount = model.price;
        // Approval should be done by the user *before* calling this function

        _handlePaymentAndDistribution(totalTokenAmount, _tokenContract, msg.sender, model.owner);

        _licenseCounter.increment();
        uint256 licenseId = _licenseCounter.current();

        uint256 expiry = 0;
        if (model.licenseType == LicenseType.TIME_LIMITED) {
            expiry = block.timestamp + model.licenseTermSeconds;
        }

        licenses[licenseId] = License({
            id: licenseId,
            modelId: _modelId,
            buyer: msg.sender,
            licenseType: model.licenseType,
            pricePaid: model.price,
            paymentToken: _tokenContract,
            purchaseTimestamp: block.timestamp,
            expiryTimestamp: expiry
        });

        _safeMint(msg.sender, licenseId);

        emit LicensePurchased(licenseId, _modelId, msg.sender, model.price, model.licenseType, expiry);
    }

    // 16. Retrieve details of a specific license.
    function getLicenseDetails(uint256 _licenseId) external view returns (License memory) {
        require(_exists(_licenseId), "License does not exist");
        return licenses[_licenseId];
    }

    // 17. Check if a time-limited license is currently valid.
    function isLicenseValid(uint256 _licenseId) public view returns (bool) {
        require(_exists(_licenseId), "License does not exist");
        License memory license = licenses[_licenseId];

        if (license.licenseType == LicenseType.PERPETUAL) {
            return true;
        } else {
            // Add a grace period check here if needed, or just simple expiry
            return license.expiryTimestamp > block.timestamp;
        }
    }

    // 18. Renew an expired or expiring time-limited license.
    function renewLicense(uint256 _licenseId) external payable nonReentrant {
        require(_exists(_licenseId), "License does not exist");
        require(ownerOf(_licenseId) == msg.sender, "Only license owner can renew");

        License storage license = licenses[_licenseId];
        require(license.licenseType == LicenseType.TIME_LIMITED, "Only time-limited licenses can be renewed");

        // Allow renewal if expired or within a grace period (e.g., last 7 days)
        bool isExpired = license.expiryTimestamp <= block.timestamp;
        // bool isNearExpiry = license.expiryTimestamp > block.timestamp && license.expiryTimestamp <= block.timestamp + 7 days; // Example grace period
        require(isExpired /* || isNearExpiry */, "License is not expired or near expiry"); // Simplified: only allow if expired

        Model storage model = models[license.modelId];
        require(model.isActive, "Model is no longer active for renewal"); // Model owner can disable renewals by withdrawing

        // Price check - renewal is at the current model price
        uint256 renewalAmount = model.price;
        address paymentToken = model.paymentToken;

        if (paymentToken == address(0)) { // ETH
             require(msg.value == renewalAmount, "Incorrect ETH amount sent for renewal");
        } else { // ERC20
             IERC20 token = IERC20(paymentToken);
             // Approval needed BEFORE calling renewLicense if paying with ERC20
             require(token.transferFrom(msg.sender, address(this), renewalAmount), "ERC20 transfer failed for renewal");
        }

        // Distribute payment (same as initial purchase)
        _handlePaymentAndDistribution(renewalAmount, paymentToken, msg.sender, model.owner);

        // Update expiry timestamp
        // If expired, new term starts now. If renewing early, term extends from current expiry.
        uint256 newExpiry = isExpired ? block.timestamp + model.licenseTermSeconds : license.expiryTimestamp + model.licenseTermSeconds;

        license.expiryTimestamp = newExpiry;
        license.pricePaid = renewalAmount; // Update price paid to current model price
        license.paymentToken = paymentToken; // Update token used

        emit LicenseRenewed(_licenseId, newExpiry, renewalAmount);
    }

    // 28. ERC-721 standard: Returns the metadata URI for a license NFT.
    // This should point to a JSON file on IPFS/HTTP with token details.
    // For this example, we'll generate a basic URI.
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "ERC721: invalid token ID");
        License memory license = licenses[_tokenId];
        Model memory model = models[license.modelId];

        // Constructing a simple URI pointing to model metadata hash and license ID
        // In a real app, this might be a gateway URL:
        // e.g., ipfs://<model.metadataHash>/<license.id>.json
        return string(abi.encodePacked("ipfs://", model.metadataHash, "/", _tokenId.toString()));
    }

    // --- Model Rating System ---

    // 21. Submit a rating (1-5) for a model using a valid license.
    // Simple implementation: stores all ratings, average calculated dynamically.
    function submitModelRating(uint256 _licenseId, uint8 _rating) external nonReentrant {
        require(_exists(_licenseId), "License does not exist");
        require(ownerOf(_licenseId) == msg.sender, "Only license owner can rate");
        require(isLicenseValid(_licenseId), "License is not valid"); // Only valid licenses can rate
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

        License memory license = licenses[_licenseId];
        _modelRatings[license.modelId].push(_rating);

        emit ModelRated(license.modelId, _licenseId, _rating);
    }

    // 22. Get the calculated average rating for a model.
    function getModelAverageRating(uint256 _modelId) external view returns (uint256) {
        require(_modelId > 0 && _modelId <= _modelCounter.current(), "Invalid model ID");

        uint256[] storage ratings = _modelRatings[_modelId];
        if (ratings.length == 0) {
            return 0; // No ratings yet
        }

        uint256 totalRating = 0;
        for (uint256 i = 0; i < ratings.length; i++) {
            totalRating += ratings[i];
        }

        // Return average * 100 to keep some precision
        return (totalRating * 100) / ratings.length;
    }

    // Get raw ratings list (can be gas intensive)
     function getModelRatings(uint256 _modelId) external view returns (uint256[] memory) {
         require(_modelId > 0 && _modelId <= _modelCounter.current(), "Invalid model ID");
         return _modelRatings[_modelId];
     }


    // --- Model Reporting System ---

    // 23. Submit a report about a specific model.
    function reportModel(uint256 _modelId, string memory _reason) external nonReentrant {
        require(_modelId > 0 && _modelId <= _modelCounter.current(), "Invalid model ID");
        require(bytes(_reason).length > 0, "Report reason is required");

        _reportCounter.increment();
        uint256 reportId = _reportCounter.current();

        reports[reportId] = Report({
            id: reportId,
            modelId: _modelId,
            reporter: msg.sender,
            reason: _reason,
            status: ReportStatus.PENDING,
            timestamp: block.timestamp
        });

        emit ModelReported(reportId, _modelId, msg.sender);
    }

    // 24. Get total number of reports submitted.
    function getReportsCount() external view returns (uint256) {
        return _reportCounter.current();
    }

    // 25. Retrieve details of a specific report.
    function getReportDetails(uint256 _reportId) external view returns (Report memory) {
        require(_reportId > 0 && _reportId <= _reportCounter.current(), "Invalid report ID");
        return reports[_reportId];
    }

    // 26. Owner function to resolve a report.
    function resolveReport(uint256 _reportId, ReportStatus _status) external onlyOwner nonReentrant {
        require(_reportId > 0 && _reportId <= _reportCounter.current(), "Invalid report ID");
        require(_status != ReportStatus.PENDING, "Cannot set status to PENDING");

        Report storage report = reports[_reportId];
        require(report.status == ReportStatus.PENDING, "Report is not pending");

        report.status = _status;

        // Add logic here based on report status (e.g., if RESOLVED_VALID, maybe deactivate model?)
        // For simplicity, we just update status.
        if (_status == ReportStatus.RESOLVED_VALID) {
            // Optional: Implement logic to automatically withdraw/deactivate model here
            // e.g., models[report.modelId].isActive = false;
        }


        emit ReportResolved(_reportId, _status);
    }

    // --- ERC-721 Standard Functions (Implemented via inheritance, but adding some common ones for clarity) ---

    // 29. See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return super.getApproved(tokenId);
    }

    // 30. See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    // Other ERC721 functions like balanceOf, ownerOf, transferFrom, safeTransferFrom, approve, setApprovalForAll
    // are available because we inherit from ERC721.

    // Override _beforeTokenTransfer for potential hooks if needed (not implemented here)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {}

    // Override _update for potential hooks after transfer (not implemented here)
    // function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    //     return super._update(to, tokenId, auth);
    // }

    // Override _increaseBalance / _decreaseBalance if specific balance logic is needed (not implemented here)

    // Override supportsInterface if additional interfaces are implemented
    // function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    //    return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    // }
}
```