```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Reputation-Gated Data Marketplace with Dynamic Access Control & AI Integration
 * @author Gemini AI (Example Smart Contract)
 * @dev This smart contract implements a decentralized data marketplace where data access is controlled by user reputation,
 *      dynamic access conditions, and integrates with an AI-powered data quality and relevance assessment mechanism.
 *      It features advanced functionalities beyond typical marketplaces, focusing on data integrity, personalized access, and future-proof AI integration.
 *
 * Function Outline:
 *
 * --- Core Data NFT Management ---
 * 1. mintDataNFT(string memory _metadataURI, uint256 _initialQualityScore): Mints a new Data NFT representing a dataset, with initial quality score.
 * 2. transferDataNFT(address _to, uint256 _tokenId): Transfers ownership of a Data NFT.
 * 3. getDataNFTMetadataURI(uint256 _tokenId): Retrieves the metadata URI associated with a Data NFT.
 * 4. setDataNFTMetadataURI(uint256 _tokenId, string memory _metadataURI): Updates the metadata URI of a Data NFT (owner only).
 * 5. getDataNFTQualityScore(uint256 _tokenId): Retrieves the current quality score of a Data NFT.
 * 6. reportDataNFTInaccuracy(uint256 _tokenId, string memory _reportDetails): Allows users to report inaccuracies in a Data NFT, triggering AI review.
 * 7. burnDataNFT(uint256 _tokenId): Burns a Data NFT, permanently removing it from the marketplace (owner only).
 *
 * --- Reputation System & Access Control ---
 * 8. getUserReputation(address _user): Retrieves the reputation score of a user.
 * 9. increaseUserReputation(address _user, uint256 _amount): Increases a user's reputation score (admin only).
 * 10. decreaseUserReputation(address _user, uint256 _amount): Decreases a user's reputation score (admin only).
 * 11. setMinReputationToAccess(uint256 _tokenId, uint256 _minReputation): Sets the minimum reputation required to access a Data NFT (owner only).
 * 12. getMinReputationToAccess(uint256 _tokenId): Retrieves the minimum reputation required to access a Data NFT.
 * 13. requestDataAccess(uint256 _tokenId): Allows a user to request access to a Data NFT if they meet the reputation requirement.
 * 14. checkDataAccessGranted(uint256 _tokenId, address _user): Checks if a user has been granted access to a Data NFT.
 * 15. revokeDataAccess(uint256 _tokenId, address _user): Revokes access to a Data NFT for a specific user (owner only).
 *
 * --- Dynamic Access Conditions & Marketplace Features ---
 * 16. setDynamicAccessCondition(uint256 _tokenId, bytes memory _conditionData): Sets a dynamic, potentially AI-driven access condition for a Data NFT (owner only).
 *     (Note: _conditionData is a placeholder for complex condition encoding - could be bytecode, JSON, etc.)
 * 17. evaluateDynamicAccessCondition(uint256 _tokenId, address _user, bytes memory _contextData): Evaluates the dynamic access condition for a user with context data.
 *     (Note: _contextData allows passing additional information for condition evaluation - user profile, current time, etc.)
 * 18. listDataNFTForSale(uint256 _tokenId, uint256 _price): Lists a Data NFT for sale in the marketplace (owner only).
 * 19. buyDataNFT(uint256 _tokenId): Allows a user to purchase a Data NFT listed for sale.
 * 20. withdrawMarketplaceFees(): Allows the contract owner to withdraw collected marketplace fees.
 *
 * --- Admin & Utility Functions ---
 * 21. setMarketplaceFee(uint256 _feePercentage): Sets the marketplace fee percentage (admin only).
 * 22. pauseContract(): Pauses core functionalities of the contract (admin only).
 * 23. unpauseContract(): Resumes core functionalities of the contract (admin only).
 * 24. setAIOracleAddress(address _aiOracleAddress): Sets the address of the AI Oracle contract (admin only).
 * 25. getAIOracleAddress(): Retrieves the address of the configured AI Oracle contract.
 * 26. setAdmin(address _newAdmin): Transfers admin role to a new address (admin only).
 * 27. getAdmin(): Retrieves the current admin address.
 * 28. getContractBalance(): Retrieves the contract's ETH balance.
 */

contract AdvancedDataMarketplace {
    // --- State Variables ---
    address public admin;
    address public aiOracleAddress; // Address of the AI Oracle contract (external)
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    bool public paused = false;

    // Data NFT related mappings and counters
    mapping(uint256 => string) public dataNFTMetadataURIs;
    mapping(uint256 => address) public dataNFTOwners;
    mapping(uint256 => uint256) public dataNFTQualityScores;
    uint256 public nextDataNFTTokenId = 1;

    // User Reputation System
    mapping(address => uint256) public userReputations;

    // Access Control Mappings
    mapping(uint256 => uint256) public minReputationToAccessNFT;
    mapping(uint256 => mapping(address => bool)) public dataAccessGranted;
    mapping(uint256 => bytes) public dynamicAccessConditions; // Placeholder for dynamic conditions

    // Marketplace Listings
    mapping(uint256 => uint256) public dataNFTListings; // tokenId => price (0 if not listed)

    // --- Events ---
    event DataNFTMinted(uint256 tokenId, address owner, string metadataURI, uint256 initialQualityScore);
    event DataNFTTransferred(uint256 tokenId, address from, address to);
    event DataNFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event DataNFTQualityReported(uint256 tokenId, address reporter, string reportDetails);
    event DataNFTQualityScoreUpdated(uint256 tokenId, uint256 newQualityScore, string reason);
    event DataNFTBurned(uint256 tokenId, address owner);

    event ReputationIncreased(address user, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address user, uint256 amount, uint256 newReputation);

    event MinReputationAccessSet(uint256 tokenId, uint256 minReputation);
    event DataAccessRequested(uint256 tokenId, address requester);
    event DataAccessGranted(uint256 tokenId, address user);
    event DataAccessRevoked(uint256 tokenId, address user);
    event DynamicAccessConditionSet(uint256 tokenId, bytes conditionData);

    event DataNFTListedForSale(uint256 tokenId, uint256 price);
    event DataNFTBought(uint256 tokenId, address buyer, uint256 price, uint256 marketplaceFee);
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(address admin, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();
    event AIOracleAddressSet(address newAIOracleAddress);
    event AdminRoleTransferred(address newAdmin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyDataNFTOwner(uint256 _tokenId) {
        require(dataNFTOwners[_tokenId] == msg.sender, "You are not the owner of this Data NFT");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Core Data NFT Management Functions ---

    /// @notice Mints a new Data NFT representing a dataset.
    /// @param _metadataURI URI pointing to the metadata of the dataset.
    /// @param _initialQualityScore Initial quality score assigned to the dataset.
    function mintDataNFT(string memory _metadataURI, uint256 _initialQualityScore) external whenNotPaused {
        uint256 tokenId = nextDataNFTTokenId++;
        dataNFTMetadataURIs[tokenId] = _metadataURI;
        dataNFTOwners[tokenId] = msg.sender;
        dataNFTQualityScores[tokenId] = _initialQualityScore;

        emit DataNFTMinted(tokenId, msg.sender, _metadataURI, _initialQualityScore);
    }

    /// @notice Transfers ownership of a Data NFT.
    /// @param _to Address of the new owner.
    /// @param _tokenId ID of the Data NFT to transfer.
    function transferDataNFT(address _to, uint256 _tokenId) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address");
        address from = msg.sender;
        dataNFTOwners[_tokenId] = _to;
        emit DataNFTTransferred(_tokenId, from, _to);
    }

    /// @notice Retrieves the metadata URI associated with a Data NFT.
    /// @param _tokenId ID of the Data NFT.
    /// @return Metadata URI of the Data NFT.
    function getDataNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        return dataNFTMetadataURIs[_tokenId];
    }

    /// @notice Updates the metadata URI of a Data NFT (owner only).
    /// @param _tokenId ID of the Data NFT.
    /// @param _metadataURI New metadata URI to set.
    function setDataNFTMetadataURI(uint256 _tokenId, string memory _metadataURI) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        dataNFTMetadataURIs[_tokenId] = _metadataURI;
        emit DataNFTMetadataUpdated(_tokenId, _metadataURI);
    }

    /// @notice Retrieves the current quality score of a Data NFT.
    /// @param _tokenId ID of the Data NFT.
    /// @return Quality score of the Data NFT.
    function getDataNFTQualityScore(uint256 _tokenId) external view returns (uint256) {
        return dataNFTQualityScores[_tokenId];
    }

    /// @notice Allows users to report inaccuracies in a Data NFT, triggering AI review.
    /// @param _tokenId ID of the Data NFT being reported.
    /// @param _reportDetails Details of the reported inaccuracy.
    function reportDataNFTInaccuracy(uint256 _tokenId, string memory _reportDetails) external whenNotPaused {
        emit DataNFTQualityReported(_tokenId, msg.sender, _reportDetails);
        // In a real-world scenario, this would trigger an off-chain process
        // involving the AI Oracle to review the report and potentially update the quality score.
        // For simplicity in this example, we'll just emit an event.
        // Future integration with AI Oracle would involve calling functions in the AI Oracle contract.
    }

    /// @notice Burns a Data NFT, permanently removing it from the marketplace (owner only).
    /// @param _tokenId ID of the Data NFT to burn.
    function burnDataNFT(uint256 _tokenId) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        delete dataNFTMetadataURIs[_tokenId];
        delete dataNFTOwners[_tokenId];
        delete dataNFTQualityScores[_tokenId];
        delete minReputationToAccessNFT[_tokenId];
        delete dataAccessGranted[_tokenId];
        delete dynamicAccessConditions[_tokenId];
        delete dataNFTListings[_tokenId];

        emit DataNFTBurned(_tokenId, msg.sender);
    }

    // --- Reputation System & Access Control Functions ---

    /// @notice Retrieves the reputation score of a user.
    /// @param _user Address of the user.
    /// @return Reputation score of the user.
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputations[_user];
    }

    /// @notice Increases a user's reputation score (admin only).
    /// @param _user Address of the user.
    /// @param _amount Amount to increase the reputation by.
    function increaseUserReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused {
        userReputations[_user] += _amount;
        emit ReputationIncreased(_user, _amount, userReputations[_user]);
    }

    /// @notice Decreases a user's reputation score (admin only).
    /// @param _user Address of the user.
    /// @param _amount Amount to decrease the reputation by.
    function decreaseUserReputation(address _user, uint256 _amount) external onlyAdmin whenNotPaused {
        require(userReputations[_user] >= _amount, "Reputation cannot be negative");
        userReputations[_user] -= _amount;
        emit ReputationDecreased(_user, _amount, userReputations[_user]);
    }

    /// @notice Sets the minimum reputation required to access a Data NFT (owner only).
    /// @param _tokenId ID of the Data NFT.
    /// @param _minReputation Minimum reputation score required to access.
    function setMinReputationToAccess(uint256 _tokenId, uint256 _minReputation) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        minReputationToAccessNFT[_tokenId] = _minReputation;
        emit MinReputationAccessSet(_tokenId, _minReputation);
    }

    /// @notice Retrieves the minimum reputation required to access a Data NFT.
    /// @param _tokenId ID of the Data NFT.
    /// @return Minimum reputation score required for access.
    function getMinReputationToAccess(uint256 _tokenId) external view returns (uint256) {
        return minReputationToAccessNFT[_tokenId];
    }

    /// @notice Allows a user to request access to a Data NFT if they meet the reputation requirement.
    /// @param _tokenId ID of the Data NFT being requested.
    function requestDataAccess(uint256 _tokenId) external whenNotPaused {
        require(userReputations[msg.sender] >= minReputationToAccessNFT[_tokenId], "Insufficient reputation to request access");
        dataAccessGranted[_tokenId][msg.sender] = true; // Automatically grant access if reputation is met
        emit DataAccessRequested(_tokenId, msg.sender);
        emit DataAccessGranted(_tokenId, msg.sender); // Grant access immediately in this example
    }

    /// @notice Checks if a user has been granted access to a Data NFT.
    /// @param _tokenId ID of the Data NFT.
    /// @param _user Address of the user to check.
    /// @return True if access is granted, false otherwise.
    function checkDataAccessGranted(uint256 _tokenId, address _user) external view returns (bool) {
        return dataAccessGranted[_tokenId][_user];
    }

    /// @notice Revokes access to a Data NFT for a specific user (owner only).
    /// @param _tokenId ID of the Data NFT.
    /// @param _user Address of the user to revoke access from.
    function revokeDataAccess(uint256 _tokenId, address _user) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        delete dataAccessGranted[_tokenId][_user]; // Revoke by deleting the mapping entry
        emit DataAccessRevoked(_tokenId, _user);
    }

    // --- Dynamic Access Conditions & Marketplace Features ---

    /// @notice Sets a dynamic, potentially AI-driven access condition for a Data NFT (owner only).
    /// @param _tokenId ID of the Data NFT.
    /// @param _conditionData Encoded data representing the dynamic access condition.
    function setDynamicAccessCondition(uint256 _tokenId, bytes memory _conditionData) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        dynamicAccessConditions[_tokenId] = _conditionData;
        emit DynamicAccessConditionSet(_tokenId, _conditionData);
        // In a real-world scenario, _conditionData could be:
        // - Bytecode to be executed by a condition evaluation contract.
        // - JSON describing rules to be interpreted by an off-chain service.
        // - A call to an AI Oracle for real-time access decision.
    }

    /// @notice Evaluates the dynamic access condition for a user with context data.
    /// @param _tokenId ID of the Data NFT.
    /// @param _user Address of the user requesting access.
    /// @param _contextData Additional context data relevant for condition evaluation.
    /// @return True if access is granted based on dynamic condition, false otherwise.
    function evaluateDynamicAccessCondition(uint256 _tokenId, address _user, bytes memory _contextData) external view returns (bool) {
        bytes memory conditionData = dynamicAccessConditions[_tokenId];
        if (conditionData.length == 0) {
            return true; // No dynamic condition set, default access granted (or fallback to reputation check)
        }

        // --- Placeholder for Dynamic Condition Evaluation Logic ---
        // In a real-world scenario, this function would:
        // 1. Decode/interpret _conditionData.
        // 2. Use _contextData and potentially call external contracts (like AI Oracle)
        //    to evaluate the condition.
        // 3. Return true if the condition is met, false otherwise.
        //
        // For this example, we'll just return true to simulate dynamic access being granted always.
        // In a real system, implement complex logic here based on _conditionData and _contextData.

        (void _user); // To avoid unused variable warning in this simplified example
        (void _contextData); // To avoid unused variable warning in this simplified example
        return true; // Simulating dynamic access granted in all cases for this example.
    }


    /// @notice Lists a Data NFT for sale in the marketplace (owner only).
    /// @param _tokenId ID of the Data NFT to list.
    /// @param _price Price in Wei for which the NFT is listed.
    function listDataNFTForSale(uint256 _tokenId, uint256 _price) external whenNotPaused onlyDataNFTOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero");
        dataNFTListings[_tokenId] = _price;
        emit DataNFTListedForSale(_tokenId, _price);
    }

    /// @notice Allows a user to purchase a Data NFT listed for sale.
    /// @param _tokenId ID of the Data NFT to buy.
    function buyDataNFT(uint256 _tokenId) external payable whenNotPaused {
        require(dataNFTListings[_tokenId] > 0, "Data NFT is not listed for sale");
        uint256 price = dataNFTListings[_tokenId];
        require(msg.value >= price, "Insufficient funds sent");

        address seller = dataNFTOwners[_tokenId];

        // Calculate marketplace fee
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = price - marketplaceFee;

        // Transfer funds
        payable(admin).transfer(marketplaceFee); // Send fee to admin
        payable(seller).transfer(sellerProceeds); // Send proceeds to seller

        // Transfer NFT ownership
        dataNFTOwners[_tokenId] = msg.sender;
        delete dataNFTListings[_tokenId]; // Remove from listing

        emit DataNFTBought(_tokenId, msg.sender, price, marketplaceFee);
        emit DataNFTTransferred(_tokenId, seller, msg.sender);

        // Refund any excess ETH sent
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /// @notice Allows the contract owner to withdraw collected marketplace fees.
    function withdrawMarketplaceFees() external onlyAdmin whenNotPaused {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit MarketplaceFeesWithdrawn(admin, balance);
    }


    // --- Admin & Utility Functions ---

    /// @notice Sets the marketplace fee percentage (admin only).
    /// @param _feePercentage New marketplace fee percentage.
    function setMarketplaceFee(uint256 _feePercentage) external onlyAdmin whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    /// @notice Pauses core functionalities of the contract (admin only).
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes core functionalities of the contract (admin only).
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Sets the address of the AI Oracle contract (admin only).
    /// @param _aiOracleAddress Address of the AI Oracle contract.
    function setAIOracleAddress(address _aiOracleAddress) external onlyAdmin whenNotPaused {
        aiOracleAddress = _aiOracleAddress;
        emit AIOracleAddressSet(_aiOracleAddress);
    }

    /// @notice Retrieves the address of the configured AI Oracle contract.
    /// @return Address of the AI Oracle contract.
    function getAIOracleAddress() external view returns (address) {
        return aiOracleAddress;
    }

    /// @notice Transfers admin role to a new address (admin only).
    /// @param _newAdmin Address of the new admin.
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address");
        emit AdminRoleTransferred(_newAdmin);
        admin = _newAdmin;
    }

    /// @notice Retrieves the current admin address.
    /// @return Address of the current admin.
    function getAdmin() external view returns (address) {
        return admin;
    }

    /// @notice Retrieves the contract's ETH balance.
    /// @return Contract's ETH balance in Wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Fallback and Receive Functions (Optional - for ETH reception) ---
    receive() external payable {} // Allow contract to receive ETH directly
    fallback() external payable {} // Allow contract to receive ETH in fallback calls
}
```

**Function Summary:**

This smart contract, `AdvancedDataMarketplace`, implements a sophisticated decentralized data marketplace with a focus on advanced features:

1.  **Data NFT Minting & Management:**  Allows creators to mint NFTs representing datasets, including metadata, quality scores, and burning capabilities.
2.  **Reputation-Based Access Control:** Implements a user reputation system that data owners can leverage to control access to their data NFTs. Access can be granted based on meeting a minimum reputation threshold.
3.  **Dynamic Access Conditions:** Introduces the concept of dynamic access conditions, allowing for more complex and potentially AI-driven access control mechanisms beyond simple reputation checks. This is a placeholder for future integration with AI oracles or complex on-chain logic.
4.  **Marketplace Functionality:** Includes standard marketplace features like listing NFTs for sale and purchasing them with ETH, with a marketplace fee mechanism.
5.  **AI Oracle Integration (Placeholder):**  Includes placeholders and functions designed to be integrated with an external AI Oracle contract. This would enable features like AI-driven data quality assessments, dynamic access condition evaluations, and more.
6.  **Admin & Utility Functions:** Provides administrative functions for managing the contract, including pausing/unpausing, setting fees, managing the AI Oracle address, and transferring admin roles.
7.  **Event Emission:**  Emits comprehensive events for all significant actions within the contract, enabling off-chain monitoring and integration.

**Advanced Concepts and Trends Incorporated:**

*   **Data NFTs:**  Leverages NFTs to represent data assets, enabling ownership and control.
*   **Reputation Systems:**  Integrates a reputation system to build trust and incentivize quality contributions within the marketplace.
*   **Dynamic Access Control:**  Moves beyond static access rules to explore more flexible and intelligent access management.
*   **AI Integration (Future-Proof):**  Architected with future integration with AI oracles in mind, anticipating the trend of AI and blockchain convergence.
*   **Decentralized Data Marketplace:** Provides a framework for a decentralized and transparent data exchange.

**Important Notes:**

*   **AI Oracle Integration is Conceptual:** The AI Oracle integration is currently a placeholder.  A real-world implementation would require a separate AI Oracle contract and more complex logic for interacting with it. The `evaluateDynamicAccessCondition` and `reportDataNFTInaccuracy` functions are designed as starting points for this integration.
*   **Dynamic Condition Encoding is Abstract:** The `_conditionData` parameter in `setDynamicAccessCondition` is abstract. The actual encoding and interpretation of dynamic conditions would need to be defined based on the specific use case and desired complexity.
*   **Security Considerations:** This is an example contract and has not been rigorously audited for security vulnerabilities. In a production environment, thorough security audits are essential.
*   **Gas Optimization:**  This contract is written for clarity and feature demonstration. Gas optimization techniques could be applied for real-world deployment.
*   **Scalability:**  Considerations for scalability would be necessary for a production-level marketplace, potentially involving layer-2 solutions or data sharding techniques.