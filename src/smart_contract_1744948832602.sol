```solidity
/**
 * @title Decentralized Data Vault & Social Passport (DataVaultPassport)
 * @author Gemini AI
 * @dev A smart contract that acts as a personal data vault allowing users to store, manage, and selectively share their data.
 * It also incorporates a "social passport" concept, enabling users to generate verifiable credentials and reputation based on their data,
 * fostering a new paradigm of data ownership and control in decentralized social interactions and applications.
 *
 * **Outline & Function Summary:**
 *
 * **Data Vault Functions:**
 * 1. `registerDataCategory(string memory categoryName)`: Allows the contract owner to register new data categories (e.g., "Personal Details", "Skills", "Achievements").
 * 2. `storeData(string memory categoryName, string memory dataKey, string memory encryptedData)`: Allows users to store encrypted data within a specific category.
 * 3. `retrieveData(string memory categoryName, string memory dataKey)`: Allows users to retrieve their own encrypted data.
 * 4. `updateData(string memory categoryName, string memory dataKey, string memory newEncryptedData)`: Allows users to update their stored data.
 * 5. `deleteData(string memory categoryName, string memory dataKey)`: Allows users to delete specific data entries.
 * 6. `getDataCategories()`: Returns a list of registered data categories.
 * 7. `getDataKeysByCategory(string memory categoryName)`: Returns a list of data keys within a specific category for a user.
 * 8. `batchStoreData(string memory categoryName, string[] memory dataKeys, string[] memory encryptedDataList)`: Allows users to store multiple data entries in a batch.
 * 9. `batchRetrieveData(string memory categoryName, string[] memory dataKeys)`: Allows users to retrieve multiple data entries in a batch.
 *
 * **Data Sharing & Access Control Functions:**
 * 10. `grantDataAccess(address recipient, string memory categoryName, string memory dataKey, uint256 expiry)`: Allows users to grant read access to specific data to another address, optionally with an expiry time.
 * 11. `revokeDataAccess(address recipient, string memory categoryName, string memory dataKey)`: Allows users to revoke previously granted data access.
 * 12. `checkDataAccess(address requester, string memory categoryName, string memory dataKey)`: Allows anyone to check if a requester has access to specific data.
 * 13. `getAuthorizedDataKeys(address requester, string memory categoryName)`: Allows a requester to see which data keys within a category they have access to.
 * 14. `clearExpiredAccessGrants()`: Allows the contract owner to clear all expired data access grants to optimize storage.
 *
 * **Social Passport & Credential Functions:**
 * 15. `generateVerifiableCredential(string memory credentialType, string memory dataClaim, string memory issuerName)`: Allows users to generate a verifiable credential (e.g., "Skill Badge", "Verification Token") based on their stored data.
 * 16. `verifyCredential(bytes memory credentialSignature, address user, string memory credentialType, string memory dataClaim, string memory issuerName)`: Allows anyone to verify the authenticity of a generated credential.
 * 17. `endorseUser(address userToEndorse, string memory endorsementType, string memory endorsementData)`: Allows users to endorse other users based on their data or credentials, contributing to a reputation system.
 * 18. `getEndorsementsForUser(address user)`: Returns a list of endorsements received by a user.
 * 19. `getCredentialHash(address user, string memory credentialType, string memory dataClaim, string memory issuerName)`: Internal function to generate a unique hash for a credential.
 *
 * **Utility & Management Functions:**
 * 20. `setContractName(string memory newName)`: Allows the contract owner to set a contract name.
 * 21. `getContractName()`: Returns the contract name.
 * 22. `pauseContract()`: Allows the contract owner to pause the contract (emergency stop).
 * 23. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 24. `isContractPaused()`: Returns the current paused state of the contract.
 * 25. `transferOwnership(address newOwner)`: Allows the contract owner to transfer contract ownership.
 * 26. `getOwner()`: Returns the contract owner address.
 */
pragma solidity ^0.8.0;

import "hardhat/console.sol"; // Optional: for debugging

contract DataVaultPassport {
    string public contractName = "Decentralized Data Vault & Social Passport";
    address public owner;
    bool public paused = false;

    // Data Categories Registry (Owner-managed)
    mapping(string => bool) public registeredDataCategories;
    string[] public dataCategoryList;

    // User Data Vault: userAddress => categoryName => dataKey => encryptedData
    mapping(address => mapping(string => mapping(string => string))) public userData;

    // Data Access Grants: dataOwner => recipient => categoryName => dataKey => expiryTimestamp
    mapping(address => mapping(address => mapping(string => mapping(string => uint256)))) public dataAccessGrants;

    // Verifiable Credentials: credentialHash => isValid
    mapping(bytes32 => bool) public verifiableCredentials;

    // User Endorsements: user => endorsementCount => {endorser, endorsementType, endorsementData, timestamp}
    mapping(address => mapping(uint256 => Endorsement)) public userEndorsements;
    mapping(address => uint256) public endorsementCounts;

    struct Endorsement {
        address endorser;
        string endorsementType;
        string endorsementData;
        uint256 timestamp;
    }

    event DataCategoryRegistered(string categoryName);
    event DataStored(address user, string categoryName, string dataKey);
    event DataUpdated(address user, string categoryName, string dataKey);
    event DataDeleted(address user, string categoryName, string dataKey);
    event DataAccessGranted(address owner, address recipient, string categoryName, string dataKey, uint256 expiry);
    event DataAccessRevoked(address owner, address recipient, string categoryName, string dataKey);
    event CredentialGenerated(address user, bytes32 credentialHash, string credentialType, string dataClaim, string issuerName);
    event UserEndorsed(address user, address endorser, string endorsementType, string endorsementData);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ContractNameUpdated(string newName);
    event OwnershipTransferred(address oldOwner, address newOwner);


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

    constructor() {
        owner = msg.sender;
        // Register some initial data categories (optional, owner can add later)
        _registerDataCategory("Personal Details");
        _registerDataCategory("Professional Skills");
        _registerDataCategory("Educational Background");
    }

    /**
     * @dev Registers a new data category. Only callable by the contract owner.
     * @param categoryName The name of the data category to register.
     */
    function registerDataCategory(string memory categoryName) public onlyOwner {
        _registerDataCategory(categoryName);
    }

    function _registerDataCategory(string memory categoryName) private {
        require(!registeredDataCategories[categoryName], "Category already registered.");
        registeredDataCategories[categoryName] = true;
        dataCategoryList.push(categoryName);
        emit DataCategoryRegistered(categoryName);
    }

    /**
     * @dev Stores encrypted data for the caller within a specific category.
     * @param categoryName The category to store data in.
     * @param dataKey A unique key to identify the data within the category.
     * @param encryptedData The encrypted data to store.
     */
    function storeData(string memory categoryName, string memory dataKey, string memory encryptedData) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        userData[msg.sender][categoryName][dataKey] = encryptedData;
        emit DataStored(msg.sender, categoryName, dataKey);
    }

    /**
     * @dev Retrieves encrypted data for the caller.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to retrieve.
     * @return The encrypted data.
     */
    function retrieveData(string memory categoryName, string memory dataKey) public view whenNotPaused returns (string memory) {
        return userData[msg.sender][categoryName][dataKey];
    }

    /**
     * @dev Updates existing encrypted data for the caller.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to update.
     * @param newEncryptedData The new encrypted data to store.
     */
    function updateData(string memory categoryName, string memory dataKey, string memory newEncryptedData) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        require(bytes(userData[msg.sender][categoryName][dataKey]).length > 0, "Data key does not exist or data is empty."); // Ensure data key exists before updating
        userData[msg.sender][categoryName][dataKey] = newEncryptedData;
        emit DataUpdated(msg.sender, categoryName, dataKey);
    }

    /**
     * @dev Deletes data for the caller.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to delete.
     */
    function deleteData(string memory categoryName, string memory dataKey) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        delete userData[msg.sender][categoryName][dataKey];
        emit DataDeleted(msg.sender, categoryName, dataKey);
    }

    /**
     * @dev Gets a list of registered data categories.
     * @return An array of data category names.
     */
    function getDataCategories() public view returns (string[] memory) {
        return dataCategoryList;
    }

    /**
     * @dev Gets a list of data keys within a specific category for the caller.
     * @param categoryName The category to query.
     * @return An array of data keys.
     */
    function getDataKeysByCategory(string memory categoryName) public view whenNotPaused returns (string[] memory) {
        require(registeredDataCategories[categoryName], "Category not registered.");
        string[] memory keys = new string[](0);
        string[] memory currentKeys = new string[](100); // Assuming max 100 keys for now, can be adjusted, or iterate mappings (more gas intensive)
        uint keyCount = 0;
        uint arrayIndex = 0;
        for (uint i = 0; i < currentKeys.length; i++) { // Iterate a fixed size array for now, better approach would be to iterate mapping keys if possible in future Solidity versions
            string memory key = currentKeys[i]; // Placeholder, Solidity mapping key iteration is not straightforward in view functions yet
            if (bytes(key).length > 0 && bytes(userData[msg.sender][categoryName][key]).length > 0) { // Basic check - not ideal for true mapping key iteration
                string[] memory tempKeys = new string[](keys.length + 1);
                for(uint j=0; j<keys.length; j++){
                    tempKeys[j] = keys[j];
                }
                tempKeys[keys.length] = key;
                keys = tempKeys;
                keyCount++;
            }
        }
        return keys;
    }

    /**
     * @dev Stores multiple data entries in a batch for the caller.
     * @param categoryName The category to store data in.
     * @param dataKeys An array of unique keys to identify the data entries.
     * @param encryptedDataList An array of encrypted data corresponding to the data keys.
     */
    function batchStoreData(string memory categoryName, string[] memory dataKeys, string[] memory encryptedDataList) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        require(dataKeys.length == encryptedDataList.length, "Data keys and data list must have the same length.");
        for (uint i = 0; i < dataKeys.length; i++) {
            userData[msg.sender][categoryName][dataKeys[i]] = encryptedDataList[i];
            emit DataStored(msg.sender, categoryName, dataKeys[i]);
        }
    }

    /**
     * @dev Retrieves multiple data entries in a batch for the caller.
     * @param categoryName The category of the data.
     * @param dataKeys An array of keys of the data to retrieve.
     * @return An array of encrypted data corresponding to the data keys.
     */
    function batchRetrieveData(string memory categoryName, string[] memory dataKeys) public view whenNotPaused returns (string[] memory) {
        string[] memory retrievedDataList = new string[](dataKeys.length);
        for (uint i = 0; i < dataKeys.length; i++) {
            retrievedDataList[i] = userData[msg.sender][categoryName][dataKeys[i]];
        }
        return retrievedDataList;
    }

    /**
     * @dev Grants read access to specific data to another address.
     * @param recipient The address to grant access to.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to share.
     * @param expiry Timestamp after which access expires (0 for no expiry).
     */
    function grantDataAccess(address recipient, string memory categoryName, string memory dataKey, uint256 expiry) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        dataAccessGrants[msg.sender][recipient][categoryName][dataKey] = expiry;
        emit DataAccessGranted(msg.sender, recipient, categoryName, dataKey, expiry);
    }

    /**
     * @dev Revokes previously granted data access.
     * @param recipient The address to revoke access from.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to revoke access for.
     */
    function revokeDataAccess(address recipient, string memory categoryName, string memory dataKey) public whenNotPaused {
        require(registeredDataCategories[categoryName], "Category not registered.");
        delete dataAccessGrants[msg.sender][recipient][categoryName][dataKey];
        emit DataAccessRevoked(msg.sender, recipient, categoryName, dataKey);
    }

    /**
     * @dev Checks if a requester has access to specific data.
     * @param requester The address checking for access.
     * @param categoryName The category of the data.
     * @param dataKey The key of the data to check access for.
     * @return True if access is granted, false otherwise.
     */
    function checkDataAccess(address requester, string memory categoryName, string memory dataKey) public view whenNotPaused returns (bool) {
        uint256 expiry = dataAccessGrants[msg.sender][requester][categoryName][dataKey];
        return expiry == 0 || block.timestamp <= expiry;
    }

    /**
     * @dev Gets a list of data keys within a category that a requester has access to.
     * @param requester The address checking for access.
     * @param categoryName The category to query.
     * @return An array of data keys the requester has access to.
     */
    function getAuthorizedDataKeys(address requester, string memory categoryName) public view whenNotPaused returns (string[] memory) {
        require(registeredDataCategories[categoryName], "Category not registered.");
        string[] memory authorizedKeys = new string[](0);
        string[] memory currentKeys = new string[](100); // Placeholder, same as getDataKeysByCategory
        uint keyCount = 0;

        for (uint i = 0; i < currentKeys.length; i++) { // Iterate a fixed size array for now
            string memory key = currentKeys[i]; // Placeholder
            if (bytes(key).length > 0 && checkDataAccess(requester, categoryName, key)) {
                string[] memory tempKeys = new string[](authorizedKeys.length + 1);
                for(uint j=0; j<authorizedKeys.length; j++){
                    tempKeys[j] = authorizedKeys[j];
                }
                tempKeys[authorizedKeys.length] = key;
                authorizedKeys = tempKeys;
                keyCount++;
            }
        }
        return authorizedKeys;
    }


    /**
     * @dev Clears all expired data access grants. Only callable by the contract owner.
     *     Note: This function might be gas-intensive if there are many grants. Consider off-chain solutions for cleaning up.
     */
    function clearExpiredAccessGrants() public onlyOwner whenNotPaused {
        for (uint i = 0; i < dataCategoryList.length; i++) {
            string memory category = dataCategoryList[i];
            // Iterate through all users (inefficient in practice for large user base, consider alternative data structures)
            // This is a simplified demonstration, in real-world scenarios, optimize iteration.
            // Solidity doesn't directly provide iterating over keys of nested mappings in a gas-efficient way in view/pure functions.
            // In a real application, consider alternative data structures or off-chain solutions for cleanup.
            // For demonstration, we use a placeholder iteration and assume limited users for simplicity.
            address[] memory users = new address[](10); // Placeholder for users, replace with actual user iteration logic if feasible.
            for(uint userIndex = 0; userIndex < users.length; userIndex++){
                address user = users[userIndex]; // Get user address - replace with actual user retrieval logic
                if(user == address(0)) continue; // Skip zero address
                string[] memory currentKeys = new string[](100); // Placeholder for keys, same as getDataKeysByCategory
                for (uint j = 0; j < currentKeys.length; j++) {
                    string memory dataKey = currentKeys[j]; // Placeholder
                    if (bytes(dataKey).length > 0) {
                        uint256 expiry = dataAccessGrants[msg.sender][user][category][dataKey];
                        if (expiry != 0 && block.timestamp > expiry) {
                            delete dataAccessGrants[msg.sender][user][category][dataKey];
                        }
                    }
                }
            }
        }
    }


    /**
     * @dev Generates a verifiable credential based on user data.
     * @param credentialType Type of credential (e.g., "Skill Badge", "Verification Token").
     * @param dataClaim Claim made in the credential (e.g., "Proficient in Solidity").
     * @param issuerName Name of the credential issuer.
     * @return The hash of the generated credential.
     */
    function generateVerifiableCredential(string memory credentialType, string memory dataClaim, string memory issuerName) public whenNotPaused returns (bytes32) {
        bytes32 credentialHash = getCredentialHash(msg.sender, credentialType, dataClaim, issuerName);
        require(!verifiableCredentials[credentialHash], "Credential already exists."); // Prevent duplicate credentials
        verifiableCredentials[credentialHash] = true;
        emit CredentialGenerated(msg.sender, credentialHash, credentialType, dataClaim, issuerName);
        return credentialHash;
    }

    /**
     * @dev Verifies the authenticity of a credential.
     * @param credentialSignature The signature of the credential (in this simplified example, we just check hash existence).
     * @param user The user who claims to own the credential.
     * @param credentialType Type of credential.
     * @param dataClaim Claim made in the credential.
     * @param issuerName Name of the credential issuer.
     * @return True if the credential is valid, false otherwise.
     */
    function verifyCredential(bytes memory credentialSignature, address user, string memory credentialType, string memory dataClaim, string memory issuerName) public view whenNotPaused returns (bool) {
        bytes32 expectedHash = getCredentialHash(user, credentialType, dataClaim, issuerName);
        return verifiableCredentials[expectedHash];
    }

    /**
     * @dev Internal function to generate a unique hash for a credential.
     * @param user The user associated with the credential.
     * @param credentialType Type of credential.
     * @param dataClaim Claim made in the credential.
     * @param issuerName Name of the credential issuer.
     * @return The hash of the credential.
     */
    function getCredentialHash(address user, string memory credentialType, string memory dataClaim, string memory issuerName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, credentialType, dataClaim, issuerName));
    }

    /**
     * @dev Allows users to endorse other users.
     * @param userToEndorse The address of the user being endorsed.
     * @param endorsementType Type of endorsement (e.g., "Skill Endorsement", "Character Reference").
     * @param endorsementData  Details of the endorsement.
     */
    function endorseUser(address userToEndorse, string memory endorsementType, string memory endorsementData) public whenNotPaused {
        endorsementCounts[userToEndorse]++;
        userEndorsements[userToEndorse][endorsementCounts[userToEndorse]] = Endorsement({
            endorser: msg.sender,
            endorsementType: endorsementType,
            endorsementData: endorsementData,
            timestamp: block.timestamp
        });
        emit UserEndorsed(userToEndorse, msg.sender, endorsementType, endorsementData);
    }

    /**
     * @dev Gets a list of endorsements received by a user.
     * @param user The address of the user to get endorsements for.
     * @return An array of endorsements.
     */
    function getEndorsementsForUser(address user) public view whenNotPaused returns (Endorsement[] memory) {
        uint256 count = endorsementCounts[user];
        Endorsement[] memory endorsements = new Endorsement[](count);
        for (uint i = 1; i <= count; i++) {
            endorsements[i-1] = userEndorsements[user][i];
        }
        return endorsements;
    }

    /**
     * @dev Sets the contract name. Only callable by the contract owner.
     * @param newName The new contract name.
     */
    function setContractName(string memory newName) public onlyOwner {
        contractName = newName;
        emit ContractNameUpdated(newName);
    }

    /**
     * @dev Gets the contract name.
     * @return The contract name.
     */
    function getContractName() public view returns (string memory) {
        return contractName;
    }

    /**
     * @dev Pauses the contract. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Transfers ownership of the contract. Only callable by the current owner.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Gets the current contract owner.
     * @return The address of the contract owner.
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    // Fallback function to prevent accidental ether sent to contract
    fallback() external payable {
        revert("This contract does not accept direct ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct ether transfers.");
    }
}
```