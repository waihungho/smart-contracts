```solidity
/**
 * @title Decentralized Personal Data Vault and Reputation System
 * @author Gemini AI
 * @dev A smart contract that allows users to store personal data securely and manage a decentralized reputation system.
 *
 * **Outline & Function Summary:**
 *
 * **Data Vault Functions:**
 * 1. `storeData(string dataType, string dataHash, string dataURI)`: Allows a user to store personal data, identified by type, hash, and URI.
 * 2. `retrieveData(string dataType)`: Allows a user to retrieve the data URI associated with a specific data type they stored.
 * 3. `updateData(string dataType, string newDataHash, string newDataURI)`: Allows a user to update the data URI and hash for a specific data type.
 * 4. `deleteData(string dataType)`: Allows a user to delete a specific type of data they have stored.
 * 5. `getDataHash(string dataType)`: Returns the data hash for a specific data type.
 * 6. `getDataURI(string dataType)`: Returns the data URI for a specific data type.
 * 7. `getSupportedDataTypes()`: Returns a list of supported data types in the contract.
 * 8. `addDataTypes(string[] newDataTypes)`: Allows the contract admin to add new supported data types.
 * 9. `removeDataTypes(string[] dataTypesToRemove)`: Allows the contract admin to remove supported data types.
 * 10. `isDataTypeSupported(string dataType)`: Checks if a given data type is supported by the contract.
 *
 * **Reputation System Functions:**
 * 11. `earnReputation(string reputationType, uint256 amount)`: Allows a user to increase their reputation for a specific reputation type.
 * 12. `grantReputation(address recipient, string reputationType, uint256 amount, string reason)`: Allows authorized entities (or admin) to grant reputation to users with a reason.
 * 13. `viewReputation(address user, string reputationType)`: Allows anyone to view a user's reputation score for a specific reputation type.
 * 14. `setReputationThreshold(string reputationType, uint256 threshold)`: Allows the contract admin to set a reputation threshold for a specific reputation type.
 * 15. `getReputationThreshold(string reputationType)`: Returns the reputation threshold for a given reputation type.
 * 16. `getSupportedReputationTypes()`: Returns a list of supported reputation types in the contract.
 * 17. `addReputationTypes(string[] newReputationTypes)`: Allows the contract admin to add new supported reputation types.
 * 18. `removeReputationTypes(string[] reputationTypesToRemove)`: Allows the contract admin to remove supported reputation types.
 * 19. `isReputationTypeSupported(string reputationType)`: Checks if a given reputation type is supported by the contract.
 *
 * **Admin & Utility Functions:**
 * 20. `setAdmin(address newAdmin)`: Allows the current admin to change the contract administrator.
 * 21. `isAdmin(address account)`: Checks if an account is the contract administrator.
 * 22. `pauseContract()`: Allows the admin to pause the contract, halting critical functions in case of emergency.
 * 23. `unpauseContract()`: Allows the admin to unpause the contract, resuming normal operation.
 * 24. `isPaused()`: Returns the current pause state of the contract.
 * 25. `withdrawContractBalance()`: Allows the admin to withdraw any Ether accidentally sent to the contract.
 */
pragma solidity ^0.8.0;

contract DecentralizedDataReputation {

    // State Variables

    address public admin;
    bool public paused;

    mapping(address => mapping(string => DataRecord)) public userData;
    mapping(address => mapping(string => uint256)) public reputationScores;
    mapping(string => uint256) public reputationThresholds;

    string[] public supportedDataTypes;
    string[] public supportedReputationTypes;

    struct DataRecord {
        string dataHash; // Hash of the data for integrity check
        string dataURI;  // URI pointing to the actual data (e.g., IPFS, Arweave)
        uint256 timestamp;
    }

    // Events

    event DataStored(address indexed user, string dataType, string dataHash, string dataURI, uint256 timestamp);
    event DataUpdated(address indexed user, string dataType, string newDataHash, string newDataURI, uint256 timestamp);
    event DataDeleted(address indexed user, string dataType);
    event ReputationEarned(address indexed user, string reputationType, uint256 amount);
    event ReputationGranted(address indexed granter, address indexed recipient, string reputationType, uint256 amount, string reason);
    event ReputationThresholdSet(string reputationType, uint256 threshold);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event DataTypeAdded(string dataType);
    event DataTypeRemoved(string dataType);
    event ReputationTypeAdded(string reputationType);
    event ReputationTypeRemoved(string reputationType);

    // Modifiers

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
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

    modifier supportedDataType(string memory dataType) {
        require(isDataTypeSupported(dataType), "Data type not supported.");
        _;
    }

    modifier supportedReputationType(string memory reputationType) {
        require(isReputationTypeSupported(reputationType), "Reputation type not supported.");
        _;
    }


    // Constructor

    constructor(string[] memory initialDataTypes, string[] memory initialReputationTypes) {
        admin = msg.sender;
        paused = false;
        supportedDataTypes = initialDataTypes;
        supportedReputationTypes = initialReputationTypes;
    }

    // ------------------------------------------------------------------------
    // Data Vault Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Stores personal data for the sender.
     * @param dataType Type of data being stored (e.g., "KYC", "MedicalRecord", "SocialProfile").
     * @param dataHash Hash of the data content for integrity verification.
     * @param dataURI URI where the data is stored (e.g., IPFS hash, Arweave URI).
     */
    function storeData(string memory dataType, string memory dataHash, string memory dataURI)
        public
        whenNotPaused
        supportedDataType(dataType)
    {
        userData[msg.sender][dataType] = DataRecord(dataHash, dataURI, block.timestamp);
        emit DataStored(msg.sender, dataType, dataHash, dataURI, block.timestamp);
    }

    /**
     * @dev Retrieves the data URI for a specific data type stored by the sender.
     * @param dataType Type of data to retrieve.
     * @return dataURI The URI where the data is stored.
     */
    function retrieveData(string memory dataType)
        public
        view
        whenNotPaused
        supportedDataType(dataType)
        returns (string memory dataURI)
    {
        require(bytes(userData[msg.sender][dataType].dataURI).length > 0, "No data stored for this type.");
        return userData[msg.sender][dataType].dataURI;
    }

    /**
     * @dev Updates the data URI and hash for a specific data type stored by the sender.
     * @param dataType Type of data to update.
     * @param newDataHash New hash of the data content.
     * @param newDataURI New URI where the data is stored.
     */
    function updateData(string memory dataType, string memory newDataHash, string memory newDataURI)
        public
        whenNotPaused
        supportedDataType(dataType)
    {
        require(bytes(userData[msg.sender][dataType].dataURI).length > 0, "No data stored for this type to update.");
        userData[msg.sender][dataType] = DataRecord(newDataHash, newDataURI, block.timestamp);
        emit DataUpdated(msg.sender, dataType, newDataHash, newDataURI, block.timestamp);
    }

    /**
     * @dev Deletes a specific type of data stored by the sender.
     * @param dataType Type of data to delete.
     */
    function deleteData(string memory dataType)
        public
        whenNotPaused
        supportedDataType(dataType)
    {
        require(bytes(userData[msg.sender][dataType].dataURI).length > 0, "No data stored for this type to delete.");
        delete userData[msg.sender][dataType];
        emit DataDeleted(msg.sender, dataType);
    }

    /**
     * @dev Returns the data hash for a specific data type stored by the sender.
     * @param dataType Type of data to get the hash for.
     * @return dataHash The hash of the stored data.
     */
    function getDataHash(string memory dataType)
        public
        view
        whenNotPaused
        supportedDataType(dataType)
        returns (string memory dataHash)
    {
        return userData[msg.sender][dataType].dataHash;
    }

    /**
     * @dev Returns the data URI for a specific data type stored by the sender.
     * @param dataType Type of data to get the URI for.
     * @return dataURI The URI of the stored data.
     */
    function getDataURI(string memory dataType)
        public
        view
        whenNotPaused
        supportedDataType(dataType)
        returns (string memory dataURI)
    {
        return userData[msg.sender][dataType].dataURI;
    }

    /**
     * @dev Returns a list of supported data types.
     * @return string[] Array of supported data type strings.
     */
    function getSupportedDataTypes()
        public
        view
        returns (string[] memory)
    {
        return supportedDataTypes;
    }

    /**
     * @dev Allows admin to add new supported data types.
     * @param newDataTypes Array of new data type strings to add.
     */
    function addDataTypes(string[] memory newDataTypes)
        public
        onlyAdmin
        whenNotPaused
    {
        for (uint256 i = 0; i < newDataTypes.length; i++) {
            if (!isDataTypeSupported(newDataTypes[i])) {
                supportedDataTypes.push(newDataTypes[i]);
                emit DataTypeAdded(newDataTypes[i]);
            }
        }
    }

    /**
     * @dev Allows admin to remove supported data types.
     * @param dataTypesToRemove Array of data type strings to remove.
     */
    function removeDataTypes(string[] memory dataTypesToRemove)
        public
        onlyAdmin
        whenNotPaused
    {
        for (uint256 i = 0; i < dataTypesToRemove.length; i++) {
            for (uint256 j = 0; j < supportedDataTypes.length; j++) {
                if (keccak256(abi.encodePacked(supportedDataTypes[j])) == keccak256(abi.encodePacked(dataTypesToRemove[i]))) {
                    delete supportedDataTypes[j];
                    emit DataTypeRemoved(dataTypesToRemove[i]);
                    // Compact the array (optional, but good for gas efficiency if removals are frequent)
                    string[] memory temp = new string[](supportedDataTypes.length - 1);
                    uint256 tempIndex = 0;
                    for (uint256 k = 0; k < supportedDataTypes.length; k++) {
                        if (bytes(supportedDataTypes[k]).length > 0) {
                            temp[tempIndex] = supportedDataTypes[k];
                            tempIndex++;
                        }
                    }
                    supportedDataTypes = temp;
                    break; // Move to the next data type to remove after finding and removing one
                }
            }
        }
    }

    /**
     * @dev Checks if a given data type is supported.
     * @param dataType The data type string to check.
     * @return bool True if supported, false otherwise.
     */
    function isDataTypeSupported(string memory dataType)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < supportedDataTypes.length; i++) {
            if (keccak256(abi.encodePacked(supportedDataTypes[i])) == keccak256(abi.encodePacked(dataType))) {
                return true;
            }
        }
        return false;
    }


    // ------------------------------------------------------------------------
    // Reputation System Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows a user to earn reputation points for a specific reputation type.
     *      This could be triggered by off-chain activities verified by oracles, or internal contract logic.
     * @param reputationType Type of reputation being earned (e.g., "CommunityEngagement", "SkillProficiency", "Reliability").
     * @param amount Amount of reputation points to earn.
     */
    function earnReputation(string memory reputationType, uint256 amount)
        public
        whenNotPaused
        supportedReputationType(reputationType)
    {
        reputationScores[msg.sender][reputationType] += amount;
        emit ReputationEarned(msg.sender, reputationType, amount);
    }

    /**
     * @dev Allows authorized entities (or admin) to grant reputation points to a user with a reason.
     *      This function could be restricted to specific roles or contracts in a more advanced system.
     * @param recipient Address of the user receiving reputation.
     * @param reputationType Type of reputation being granted.
     * @param amount Amount of reputation points to grant.
     * @param reason Reason for granting the reputation (for record keeping and transparency).
     */
    function grantReputation(address recipient, string memory reputationType, uint256 amount, string memory reason)
        public
        onlyAdmin // For simplicity, only admin can grant. In a real system, this could be more role-based.
        whenNotPaused
        supportedReputationType(reputationType)
    {
        reputationScores[recipient][reputationType] += amount;
        emit ReputationGranted(msg.sender, recipient, reputationType, amount, reason);
    }

    /**
     * @dev Allows anyone to view a user's reputation score for a specific reputation type.
     * @param user Address of the user whose reputation is being viewed.
     * @param reputationType Type of reputation to view.
     * @return uint256 The user's reputation score for the given type.
     */
    function viewReputation(address user, string memory reputationType)
        public
        view
        whenNotPaused
        supportedReputationType(reputationType)
        returns (uint256)
    {
        return reputationScores[user][reputationType];
    }

    /**
     * @dev Allows admin to set a reputation threshold for a specific reputation type.
     *      This threshold could be used for access control or other conditional logic in external applications.
     * @param reputationType Type of reputation to set the threshold for.
     * @param threshold The reputation score threshold value.
     */
    function setReputationThreshold(string memory reputationType, uint256 threshold)
        public
        onlyAdmin
        whenNotPaused
        supportedReputationType(reputationType)
    {
        reputationThresholds[reputationType] = threshold;
        emit ReputationThresholdSet(reputationType, threshold);
    }

    /**
     * @dev Returns the reputation threshold for a given reputation type.
     * @param reputationType Type of reputation to get the threshold for.
     * @return uint256 The reputation threshold value.
     */
    function getReputationThreshold(string memory reputationType)
        public
        view
        whenNotPaused
        supportedReputationType(reputationType)
        returns (uint256)
    {
        return reputationThresholds[reputationType];
    }

    /**
     * @dev Returns a list of supported reputation types.
     * @return string[] Array of supported reputation type strings.
     */
    function getSupportedReputationTypes()
        public
        view
        returns (string[] memory)
    {
        return supportedReputationTypes;
    }

    /**
     * @dev Allows admin to add new supported reputation types.
     * @param newReputationTypes Array of new reputation type strings to add.
     */
    function addReputationTypes(string[] memory newReputationTypes)
        public
        onlyAdmin
        whenNotPaused
    {
        for (uint256 i = 0; i < newReputationTypes.length; i++) {
            if (!isReputationTypeSupported(newReputationTypes[i])) {
                supportedReputationTypes.push(newReputationTypes[i]);
                emit ReputationTypeAdded(newReputationTypes[i]);
            }
        }
    }

    /**
     * @dev Allows admin to remove supported reputation types.
     * @param reputationTypesToRemove Array of reputation type strings to remove.
     */
    function removeReputationTypes(string[] memory reputationTypesToRemove)
        public
        onlyAdmin
        whenNotPaused
    {
        for (uint256 i = 0; i < reputationTypesToRemove.length; i++) {
            for (uint256 j = 0; j < supportedReputationTypes.length; j++) {
                if (keccak256(abi.encodePacked(supportedReputationTypes[j])) == keccak256(abi.encodePacked(reputationTypesToRemove[i]))) {
                    delete supportedReputationTypes[j];
                    emit ReputationTypeRemoved(reputationTypesToRemove[i]);
                    // Compact the array (optional)
                    string[] memory temp = new string[](supportedReputationTypes.length - 1);
                    uint256 tempIndex = 0;
                    for (uint256 k = 0; k < supportedReputationTypes.length; k++) {
                        if (bytes(supportedReputationTypes[k]).length > 0) {
                            temp[tempIndex] = supportedReputationTypes[k];
                            tempIndex++;
                        }
                    }
                    supportedReputationTypes = temp;
                    break; // Move to the next reputation type to remove after finding and removing one
                }
            }
        }
    }

    /**
     * @dev Checks if a given reputation type is supported.
     * @param reputationType The reputation type string to check.
     * @return bool True if supported, false otherwise.
     */
    function isReputationTypeSupported(string memory reputationType)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < supportedReputationTypes.length; i++) {
            if (keccak256(abi.encodePacked(supportedReputationTypes[i])) == keccak256(abi.encodePacked(reputationType))) {
                return true;
            }
        }
        return false;
    }

    // ------------------------------------------------------------------------
    // Admin & Utility Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows the current admin to change the contract administrator.
     * @param newAdmin Address of the new administrator.
     */
    function setAdmin(address newAdmin) public onlyAdmin whenNotPaused {
        require(newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @dev Checks if an address is the contract administrator.
     * @param account Address to check.
     * @return bool True if the address is the admin, false otherwise.
     */
    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    /**
     * @dev Pauses the contract, preventing critical functions from being executed.
     *      Only the admin can pause the contract.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Unpauses the contract, resuming normal operation.
     *      Only the admin can unpause the contract.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /**
     * @dev Returns the current pause state of the contract.
     * @return bool True if the contract is paused, false otherwise.
     */
    function isPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Allows the admin to withdraw any Ether accidentally sent to the contract.
     */
    function withdrawContractBalance() public onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }

    // Fallback function to prevent accidental Ether sent to contract from being stuck.
    receive() external payable {}
    fallback() external payable {}
}
```