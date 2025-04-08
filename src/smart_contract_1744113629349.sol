```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Credential and Reputation Oracle
 * @author Bard (Example Contract - Not for Production)
 * @notice This contract implements a decentralized system for issuing, verifying, and aggregating verifiable credentials to build a reputation score.
 * It introduces concepts like Credential Schemas, Issuers, Verifiers, and a dynamic Reputation Scoring mechanism.
 * This is a creative and advanced concept contract, designed to showcase a range of Solidity features and functionalities beyond basic token contracts.
 * It is NOT intended for production use without thorough security audits and considerations.
 *
 * **Outline and Function Summary:**
 *
 * **Contract State and Configuration:**
 * 1. `contractName()`: Returns the name of the contract. (View)
 * 2. `contractVersion()`: Returns the version of the contract. (View)
 * 3. `owner()`: Returns the contract owner address. (View)
 * 4. `isPaused()`: Returns the current paused state of the contract. (View)
 * 5. `pauseContract()`: Pauses the contract, restricting most functions to owner only. (Admin)
 * 6. `unpauseContract()`: Unpauses the contract, restoring normal functionality. (Admin)
 *
 * **Credential Schema Management:**
 * 7. `createCredentialSchema(string _schemaName, string _schemaDescription, string[] memory _fields, uint256[] memory _fieldWeights)`: Creates a new Credential Schema. (Admin)
 * 8. `updateCredentialSchemaDescription(uint256 _schemaId, string _newDescription)`: Updates the description of a Credential Schema. (Admin)
 * 9. `addCredentialSchemaField(uint256 _schemaId, string _fieldName, uint256 _fieldWeight)`: Adds a new field to an existing Credential Schema. (Admin)
 * 10. `getCredentialSchemaDetails(uint256 _schemaId)`: Retrieves details of a specific Credential Schema. (View)
 * 11. `getAllSchemaIds()`: Retrieves a list of all created Schema IDs. (View)
 *
 * **Credential Issuance and Revocation:**
 * 12. `addIssuer(address _issuerAddress, uint256[] memory _schemaIds)`: Adds an address as an authorized issuer for specific Credential Schemas. (Admin)
 * 13. `removeIssuer(address _issuerAddress)`: Removes an address from being an authorized issuer. (Admin)
 * 14. `isAuthorizedIssuer(address _issuerAddress, uint256 _schemaId)`: Checks if an address is an authorized issuer for a specific Schema. (View)
 * 15. `issueCredential(uint256 _schemaId, address _recipient, string[] memory _fieldValues, string memory _credentialMetadata)`: Issues a new Credential to a recipient. (Issuer)
 * 16. `revokeCredential(uint256 _credentialId, string memory _revocationReason)`: Revokes a previously issued Credential. (Issuer)
 * 17. `getCredentialDetails(uint256 _credentialId)`: Retrieves details of a specific Credential. (View)
 * 18. `getRecipientCredentials(address _recipient)`: Retrieves a list of Credential IDs issued to a recipient. (View)
 *
 * **Reputation Scoring and Aggregation:**
 * 19. `calculateReputationScore(address _user)`: Calculates the reputation score for a user based on their valid credentials. (Internal)
 * 20. `getUserReputationScore(address _user)`: Retrieves the current reputation score for a user. (View)
 * 21. `updateSchemaReputationWeight(uint256 _schemaId, uint256 _newWeight)`: Updates the reputation weight of a specific Credential Schema. (Admin)
 * 22. `getSchemaReputationWeight(uint256 _schemaId)`: Retrieves the reputation weight of a specific Credential Schema. (View)
 *
 * **Events:**
 * Emits events for all critical actions (Schema Creation, Schema Update, Issuer Management, Credential Issuance, Credential Revocation, Reputation Update, Contract Paused/Unpaused).
 */
contract DecentralizedCredentialOracle {

    // Contract Metadata and Control
    string public constant contractName = "DecentralizedCredentialOracle";
    string public constant contractVersion = "1.0.0";
    address public immutable owner;
    bool private paused;

    // Data Structures
    struct CredentialSchema {
        string schemaName;
        string schemaDescription;
        string[] fields;
        uint256[] fieldWeights; // Weights associated with each field for reputation scoring
        uint256 reputationWeight; // Overall weight of this schema in reputation calculation
        bool exists;
    }

    struct Credential {
        uint256 schemaId;
        address recipient;
        string[] fieldValues;
        string credentialMetadata;
        uint256 issueTimestamp;
        bool isRevoked;
        string revocationReason;
        bool exists;
    }

    // Mappings for Data Storage and Lookups
    mapping(uint256 => CredentialSchema) public credentialSchemas;
    mapping(uint256 => Credential) public credentials;
    mapping(address => mapping(uint256 => bool)) public issuerAuthorization; // issuerAddress => schemaId => isAuthorized
    mapping(address => uint256) public userReputationScores;
    mapping(address => uint256[]) public recipientCredentials; // recipientAddress => array of credential IDs
    mapping(uint256 => uint256) public schemaReputationWeights; // schemaId => reputationWeight

    // Counters and Identifiers
    uint256 public nextSchemaId;
    uint256 public nextCredentialId;

    // Events
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event SchemaCreated(uint256 indexed schemaId, string schemaName, address indexed creator);
    event SchemaDescriptionUpdated(uint256 indexed schemaId, string newDescription, address indexed updater);
    event SchemaFieldAdded(uint256 indexed schemaId, string fieldName, uint256 fieldWeight, address indexed updater);
    event IssuerAdded(address indexed issuerAddress, uint256[] schemaIds, address indexed admin);
    event IssuerRemoved(address indexed issuerAddress, address indexed admin);
    event CredentialIssued(uint256 indexed credentialId, uint256 indexed schemaId, address indexed recipient, address indexed issuer);
    event CredentialRevoked(uint256 indexed credentialId, string revocationReason, address indexed revoker);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event SchemaReputationWeightUpdated(uint256 indexed schemaId, uint256 newWeight, address indexed updater);

    // Modifiers
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

    modifier onlyIssuer(uint256 _schemaId) {
        require(isAuthorizedIssuer(msg.sender, _schemaId), "Not an authorized issuer for this schema.");
        _;
    }


    constructor() {
        owner = msg.sender;
        paused = false;
        nextSchemaId = 1; // Start schema IDs from 1 for easier tracking
        nextCredentialId = 1; // Start credential IDs from 1
    }

    // ------------------------------------------------------------------------
    // Contract State and Configuration Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Returns the name of the contract.
     * @return string The name of the contract.
     */
    function contractName() external pure returns (string memory) {
        return contractName;
    }

    /**
     * @dev Returns the version of the contract.
     * @return string The version of the contract.
     */
    function contractVersion() external pure returns (string memory) {
        return contractVersion;
    }

    /**
     * @dev Returns the address of the contract owner.
     * @return address The owner address.
     */
    function owner() external view returns (address) {
        return owner;
    }

    /**
     * @dev Returns the paused state of the contract.
     * @return bool True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Pauses the contract. Only callable by the owner.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // ------------------------------------------------------------------------
    // Credential Schema Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Creates a new Credential Schema. Only callable by the contract owner.
     * @param _schemaName The name of the schema.
     * @param _schemaDescription A description of the schema.
     * @param _fields An array of field names for the schema.
     * @param _fieldWeights An array of weights corresponding to each field for reputation scoring.
     */
    function createCredentialSchema(
        string memory _schemaName,
        string memory _schemaDescription,
        string[] memory _fields,
        uint256[] memory _fieldWeights
    ) external onlyOwner whenNotPaused {
        require(bytes(_schemaName).length > 0, "Schema name cannot be empty.");
        require(_fields.length > 0, "Schema must have at least one field.");
        require(_fields.length == _fieldWeights.length, "Fields and weights arrays must have the same length.");

        credentialSchemas[nextSchemaId] = CredentialSchema({
            schemaName: _schemaName,
            schemaDescription: _schemaDescription,
            fields: _fields,
            fieldWeights: _fieldWeights,
            reputationWeight: 100, // Default reputation weight for a new schema
            exists: true
        });
        schemaReputationWeights[nextSchemaId] = 100; // Initialize default weight
        emit SchemaCreated(nextSchemaId, _schemaName, msg.sender);
        nextSchemaId++;
    }

    /**
     * @dev Updates the description of an existing Credential Schema. Only callable by the contract owner.
     * @param _schemaId The ID of the schema to update.
     * @param _newDescription The new description for the schema.
     */
    function updateCredentialSchemaDescription(uint256 _schemaId, string memory _newDescription) external onlyOwner whenNotPaused {
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        credentialSchemas[_schemaId].schemaDescription = _newDescription;
        emit SchemaDescriptionUpdated(_schemaId, _newDescription, msg.sender);
    }

    /**
     * @dev Adds a new field to an existing Credential Schema. Only callable by the contract owner.
     * @param _schemaId The ID of the schema to add the field to.
     * @param _fieldName The name of the new field.
     * @param _fieldWeight The weight of the new field for reputation scoring.
     */
    function addCredentialSchemaField(uint256 _schemaId, string memory _fieldName, uint256 _fieldWeight) external onlyOwner whenNotPaused {
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        credentialSchemas[_schemaId].fields.push(_fieldName);
        credentialSchemas[_schemaId].fieldWeights.push(_fieldWeight);
        emit SchemaFieldAdded(_schemaId, _fieldName, _fieldWeight, msg.sender);
    }

    /**
     * @dev Retrieves details of a specific Credential Schema.
     * @param _schemaId The ID of the schema to retrieve.
     * @return CredentialSchema The details of the schema.
     */
    function getCredentialSchemaDetails(uint256 _schemaId) external view returns (CredentialSchema memory) {
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        return credentialSchemas[_schemaId];
    }

    /**
     * @dev Retrieves a list of all created Schema IDs.
     * @return uint256[] An array of schema IDs.
     */
    function getAllSchemaIds() external view returns (uint256[] memory) {
        uint256[] memory schemaIds = new uint256[](nextSchemaId - 1);
        uint256 index = 0;
        for (uint256 i = 1; i < nextSchemaId; i++) {
            if (credentialSchemas[i].exists) {
                schemaIds[index] = i;
                index++;
            }
        }
        return schemaIds;
    }

    // ------------------------------------------------------------------------
    // Credential Issuer Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Adds an address as an authorized issuer for specific Credential Schemas. Only callable by the contract owner.
     * @param _issuerAddress The address to authorize as an issuer.
     * @param _schemaIds An array of schema IDs for which the issuer is authorized.
     */
    function addIssuer(address _issuerAddress, uint256[] memory _schemaIds) external onlyOwner whenNotPaused {
        require(_issuerAddress != address(0), "Invalid issuer address.");
        for (uint256 i = 0; i < _schemaIds.length; i++) {
            require(credentialSchemas[_schemaIds[i]].exists, "Schema does not exist.");
            issuerAuthorization[_issuerAddress][_schemaIds[i]] = true;
        }
        emit IssuerAdded(_issuerAddress, _schemaIds, msg.sender);
    }

    /**
     * @dev Removes an address from being an authorized issuer for all schemas. Only callable by the contract owner.
     * @param _issuerAddress The address to remove as an issuer.
     */
    function removeIssuer(address _issuerAddress) external onlyOwner whenNotPaused {
        delete issuerAuthorization[_issuerAddress]; // Removes all schema authorizations for this issuer
        emit IssuerRemoved(_issuerAddress, msg.sender);
    }

    /**
     * @dev Checks if an address is an authorized issuer for a specific Credential Schema.
     * @param _issuerAddress The address to check.
     * @param _schemaId The ID of the schema to check authorization for.
     * @return bool True if authorized, false otherwise.
     */
    function isAuthorizedIssuer(address _issuerAddress, uint256 _schemaId) public view returns (bool) {
        return issuerAuthorization[_issuerAddress][_schemaId];
    }

    // ------------------------------------------------------------------------
    // Credential Issuance and Revocation Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Issues a new Credential to a recipient. Only callable by authorized issuers for the given schema.
     * @param _schemaId The ID of the schema for the credential.
     * @param _recipient The address of the credential recipient.
     * @param _fieldValues An array of field values for the credential.
     * @param _credentialMetadata Optional metadata for the credential.
     */
    function issueCredential(
        uint256 _schemaId,
        address _recipient,
        string[] memory _fieldValues,
        string memory _credentialMetadata
    ) external whenNotPaused onlyIssuer(_schemaId) {
        require(_recipient != address(0), "Invalid recipient address.");
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        require(_fieldValues.length == credentialSchemas[_schemaId].fields.length, "Incorrect number of field values.");

        credentials[nextCredentialId] = Credential({
            schemaId: _schemaId,
            recipient: _recipient,
            fieldValues: _fieldValues,
            credentialMetadata: _credentialMetadata,
            issueTimestamp: block.timestamp,
            isRevoked: false,
            revocationReason: "",
            exists: true
        });
        recipientCredentials[_recipient].push(nextCredentialId);
        emit CredentialIssued(nextCredentialId, _schemaId, _recipient, msg.sender);
        calculateReputationScore(_recipient); // Update reputation score on credential issue
        nextCredentialId++;
    }

    /**
     * @dev Revokes a previously issued Credential. Only callable by the issuer who issued the credential.
     * @param _credentialId The ID of the credential to revoke.
     * @param _revocationReason The reason for revocation.
     */
    function revokeCredential(uint256 _credentialId, string memory _revocationReason) external whenNotPaused {
        require(credentials[_credentialId].exists, "Credential does not exist.");
        require(msg.sender == address(this) || isAuthorizedIssuer(msg.sender, credentials[_credentialId].schemaId), "Not authorized to revoke this credential."); // Allow contract owner to revoke as well for emergency.
        require(!credentials[_credentialId].isRevoked, "Credential already revoked.");

        credentials[_credentialId].isRevoked = true;
        credentials[_credentialId].revocationReason = _revocationReason;
        emit CredentialRevoked(_credentialId, _revocationReason, msg.sender);
        calculateReputationScore(credentials[_credentialId].recipient); // Update reputation score on credential revocation
    }

    /**
     * @dev Retrieves details of a specific Credential.
     * @param _credentialId The ID of the credential to retrieve.
     * @return Credential The details of the credential.
     */
    function getCredentialDetails(uint256 _credentialId) external view returns (Credential memory) {
        require(credentials[_credentialId].exists, "Credential does not exist.");
        return credentials[_credentialId];
    }

    /**
     * @dev Retrieves a list of Credential IDs issued to a recipient.
     * @param _recipient The address of the recipient.
     * @return uint256[] An array of credential IDs.
     */
    function getRecipientCredentials(address _recipient) external view returns (uint256[] memory) {
        return recipientCredentials[_recipient];
    }

    // ------------------------------------------------------------------------
    // Reputation Scoring and Aggregation Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Calculates the reputation score for a user based on their valid credentials. Internal function.
     * @param _user The address of the user to calculate reputation for.
     */
    function calculateReputationScore(address _user) internal {
        uint256 totalScore = 0;
        uint256[] memory credentialIds = recipientCredentials[_user];
        for (uint256 i = 0; i < credentialIds.length; i++) {
            Credential memory cred = credentials[credentialIds[i]];
            if (cred.exists && !cred.isRevoked) {
                CredentialSchema memory schema = credentialSchemas[cred.schemaId];
                uint256 schemaScore = schemaReputationWeights[cred.schemaId]; // Use schema-specific reputation weight
                uint256 fieldScore = 0;
                for (uint256 j = 0; j < schema.fieldWeights.length; j++) {
                    // Example: Simple field weight addition, can be made more complex
                    fieldScore += schema.fieldWeights[j];
                }
                totalScore += (schemaScore + fieldScore); // Combine schema weight and field weights
            }
        }
        userReputationScores[_user] = totalScore;
        emit ReputationScoreUpdated(_user, totalScore);
    }

    /**
     * @dev Retrieves the current reputation score for a user.
     * @param _user The address of the user.
     * @return uint256 The reputation score.
     */
    function getUserReputationScore(address _user) external view returns (uint256) {
        return userReputationScores[_user];
    }

    /**
     * @dev Updates the reputation weight of a specific Credential Schema. Only callable by the contract owner.
     * @param _schemaId The ID of the schema to update.
     * @param _newWeight The new reputation weight for the schema.
     */
    function updateSchemaReputationWeight(uint256 _schemaId, uint256 _newWeight) external onlyOwner whenNotPaused {
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        schemaReputationWeights[_schemaId] = _newWeight;
        emit SchemaReputationWeightUpdated(_schemaId, _newWeight, msg.sender);
    }

    /**
     * @dev Retrieves the reputation weight of a specific Credential Schema.
     * @param _schemaId The ID of the schema.
     * @return uint256 The reputation weight.
     */
    function getSchemaReputationWeight(uint256 _schemaId) external view returns (uint256) {
        require(credentialSchemas[_schemaId].exists, "Schema does not exist.");
        return schemaReputationWeights[_schemaId];
    }
}
```