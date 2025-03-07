```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic & Verifiable Credential Registry - "VerityChain"
 * @author Bard (Example Smart Contract - Conceptual and for educational purposes)
 *
 * @dev This smart contract implements a dynamic and verifiable credential registry.
 * It allows issuers to create and issue verifiable credentials to subjects,
 * with features for dynamic updates, revocation, and on-chain verification.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality - Credential Management:**
 * 1. `issueCredential(address _subject, string memory _credentialType, bytes memory _credentialData, uint256 _expiration)`: Issues a new credential to a subject.
 * 2. `updateCredentialData(uint256 _credentialId, bytes memory _newCredentialData)`: Updates the data of an existing credential.
 * 3. `revokeCredential(uint256 _credentialId)`: Revokes a credential, making it invalid.
 * 4. `getCredential(uint256 _credentialId)`: Retrieves the details of a specific credential.
 * 5. `getCredentialData(uint256 _credentialId)`: Retrieves only the data payload of a credential.
 * 6. `getCredentialStatus(uint256 _credentialId)`: Checks if a credential is valid and not revoked.
 * 7. `getCredentialsBySubject(address _subject)`: Retrieves a list of credential IDs associated with a subject.
 * 8. `getCredentialsByType(string memory _credentialType)`: Retrieves a list of credential IDs of a specific type.
 * 9. `getTotalCredentialsIssued()`: Returns the total number of credentials issued by the contract.
 * 10. `setDefaultExpirationDuration(uint256 _duration)`: Sets the default expiration duration for newly issued credentials.
 *
 * **Issuer and Registry Management:**
 * 11. `addIssuer(address _issuerAddress)`: Allows the contract owner to add a new authorized issuer.
 * 12. `removeIssuer(address _issuerAddress)`: Allows the contract owner to remove an authorized issuer.
 * 13. `isAuthorizedIssuer(address _address)`: Checks if an address is an authorized issuer.
 * 14. `setContractMetadata(string memory _name, string memory _description, string memory _version)`: Sets metadata for the contract itself.
 * 15. `getContractMetadata()`: Retrieves the contract metadata.
 * 16. `pauseIssuance()`: Pauses the issuance of new credentials (emergency stop).
 * 17. `unpauseIssuance()`: Resumes the issuance of credentials.
 * 18. `isIssuancePaused()`: Checks if credential issuance is currently paused.
 *
 * **Utility & Verification Functions:**
 * 19. `hashCredentialData(bytes memory _data)`: Calculates the keccak256 hash of credential data (for off-chain verification).
 * 20. `verifyCredentialIntegrity(uint256 _credentialId, bytes memory _dataHash)`: Allows anyone to verify the data integrity of a credential against a provided hash.
 * 21. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support for discoverability.
 *
 * **Advanced Concepts Incorporated:**
 * - **Dynamic Credentials:**  `updateCredentialData` allows for updating credential information after issuance, making them more adaptable to real-world scenarios (e.g., updating skill certifications, course completion dates).
 * - **On-Chain Verification:** `verifyCredentialIntegrity` provides a basic on-chain mechanism to check if the data of a credential matches a known hash, enhancing trust and verifiability.
 * - **Credential Types:** Categorization of credentials using `_credentialType` enables efficient querying and management of different types of credentials (e.g., diplomas, licenses, memberships).
 * - **Issuer Authorization:** Restricting credential issuance to authorized issuers adds a layer of security and control over the registry.
 * - **Emergency Pause:** `pauseIssuance` provides a safety mechanism to halt credential issuance in case of critical issues or security breaches.
 * - **Contract Metadata:**  Including metadata directly in the contract enhances discoverability and provides context about the contract's purpose and version.
 */
contract VerityChain {
    // ** State Variables **

    struct Credential {
        uint256 id;
        address subject;
        address issuer;
        string credentialType;
        bytes credentialData;
        uint256 issuanceDate;
        uint256 expirationDate;
        bool revoked;
    }

    mapping(uint256 => Credential) public credentialsById; // Mapping of credential ID to Credential struct
    mapping(address => uint256[]) public credentialsBySubject; // Mapping of subject address to list of credential IDs
    mapping(string => uint256[]) public credentialsByType; // Mapping of credential type to list of credential IDs
    mapping(address => bool) public authorizedIssuers; // Mapping of authorized issuer addresses to boolean
    uint256 public credentialCounter; // Counter for generating unique credential IDs
    uint256 public defaultExpirationDuration = 365 days; // Default credential expiration duration (1 year)
    bool public issuancePaused = false; // Flag to pause/unpause credential issuance

    // Contract Metadata
    string public contractName = "VerityChain";
    string public contractDescription = "Dynamic & Verifiable Credential Registry";
    string public contractVersion = "1.0.0";

    address public owner; // Contract owner address

    // ** Events **
    event CredentialIssued(uint256 credentialId, address subject, string credentialType, address issuer);
    event CredentialDataUpdated(uint256 credentialId, bytes newData);
    event CredentialRevoked(uint256 credentialId);
    event IssuerAdded(address issuerAddress);
    event IssuerRemoved(address issuerAddress);
    event IssuancePaused();
    event IssuanceUnpaused();
    event ContractMetadataUpdated(string name, string description, string version);
    event DefaultExpirationDurationSet(uint256 duration);

    // ** Modifiers **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyAuthorizedIssuer() {
        require(authorizedIssuers[msg.sender], "Only authorized issuers can call this function.");
        _;
    }

    modifier whenIssuanceNotPaused() {
        require(!issuancePaused, "Issuance is currently paused.");
        _;
    }

    // ** Constructor **
    constructor() {
        owner = msg.sender;
        authorizedIssuers[msg.sender] = true; // Owner is initially an authorized issuer
    }

    // ** Core Functionality - Credential Management Functions **

    /// @notice Issues a new verifiable credential to a subject.
    /// @param _subject The address of the credential subject.
    /// @param _credentialType A string representing the type of credential (e.g., "Diploma", "License", "Membership").
    /// @param _credentialData The data associated with the credential (can be encoded JSON, CBOR, etc.).
    /// @param _expiration The expiration timestamp of the credential (0 for no expiration).
    function issueCredential(
        address _subject,
        string memory _credentialType,
        bytes memory _credentialData,
        uint256 _expiration
    ) external onlyAuthorizedIssuer whenIssuanceNotPaused {
        require(_subject != address(0), "Subject address cannot be zero address.");
        require(bytes(_credentialType).length > 0, "Credential type cannot be empty.");

        credentialCounter++;
        uint256 credentialId = credentialCounter;

        uint256 expiration = _expiration == 0 ? block.timestamp + defaultExpirationDuration : _expiration;

        credentialsById[credentialId] = Credential({
            id: credentialId,
            subject: _subject,
            issuer: msg.sender,
            credentialType: _credentialType,
            credentialData: _credentialData,
            issuanceDate: block.timestamp,
            expirationDate: expiration,
            revoked: false
        });

        credentialsBySubject[_subject].push(credentialId);
        credentialsByType[_credentialType].push(credentialId);

        emit CredentialIssued(credentialId, _subject, _credentialType, msg.sender);
    }

    /// @notice Updates the data associated with an existing credential.
    /// @param _credentialId The ID of the credential to update.
    /// @param _newCredentialData The new data payload for the credential.
    function updateCredentialData(uint256 _credentialId, bytes memory _newCredentialData) external onlyAuthorizedIssuer {
        require(credentialsById[_credentialId].issuer == msg.sender, "Only the issuer can update credential data.");
        require(!credentialsById[_credentialId].revoked, "Cannot update a revoked credential.");
        require(credentialsById[_credentialId].expirationDate > block.timestamp || credentialsById[_credentialId].expirationDate == 0, "Cannot update an expired credential.");

        credentialsById[_credentialId].credentialData = _newCredentialData;
        emit CredentialDataUpdated(_credentialId, _newCredentialData);
    }

    /// @notice Revokes a credential, making it invalid.
    /// @param _credentialId The ID of the credential to revoke.
    function revokeCredential(uint256 _credentialId) external onlyAuthorizedIssuer {
        require(credentialsById[_credentialId].issuer == msg.sender, "Only the issuer can revoke a credential.");
        require(!credentialsById[_credentialId].revoked, "Credential is already revoked.");

        credentialsById[_credentialId].revoked = true;
        emit CredentialRevoked(_credentialId);
    }

    /// @notice Retrieves the details of a specific credential.
    /// @param _credentialId The ID of the credential to retrieve.
    /// @return Credential struct containing credential details.
    function getCredential(uint256 _credentialId) external view returns (Credential memory) {
        require(_credentialId > 0 && _credentialId <= credentialCounter, "Invalid credential ID.");
        return credentialsById[_credentialId];
    }

    /// @notice Retrieves only the data payload of a credential.
    /// @param _credentialId The ID of the credential.
    /// @return bytes The credential data payload.
    function getCredentialData(uint256 _credentialId) external view returns (bytes memory) {
        require(_credentialId > 0 && _credentialId <= credentialCounter, "Invalid credential ID.");
        return credentialsById[_credentialId].credentialData;
    }

    /// @notice Checks if a credential is valid (not revoked and not expired).
    /// @param _credentialId The ID of the credential to check.
    /// @return bool True if the credential is valid, false otherwise.
    function getCredentialStatus(uint256 _credentialId) external view returns (bool) {
        require(_credentialId > 0 && _credentialId <= credentialCounter, "Invalid credential ID.");
        Credential memory credential = credentialsById[_credentialId];
        return !credential.revoked && (credential.expirationDate == 0 || credential.expirationDate > block.timestamp);
    }

    /// @notice Retrieves a list of credential IDs associated with a subject address.
    /// @param _subject The address of the subject.
    /// @return uint256[] Array of credential IDs.
    function getCredentialsBySubject(address _subject) external view returns (uint256[] memory) {
        return credentialsBySubject[_subject];
    }

    /// @notice Retrieves a list of credential IDs of a specific type.
    /// @param _credentialType The type of credential to search for.
    /// @return uint256[] Array of credential IDs.
    function getCredentialsByType(string memory _credentialType) external view returns (uint256[] memory) {
        return credentialsByType[_credentialType];
    }

    /// @notice Returns the total number of credentials issued by the contract.
    /// @return uint256 Total number of credentials.
    function getTotalCredentialsIssued() external view returns (uint256) {
        return credentialCounter;
    }

    /// @notice Sets the default expiration duration for newly issued credentials.
    /// @param _duration The expiration duration in seconds.
    function setDefaultExpirationDuration(uint256 _duration) external onlyOwner {
        defaultExpirationDuration = _duration;
        emit DefaultExpirationDurationSet(_duration);
    }


    // ** Issuer and Registry Management Functions **

    /// @notice Adds a new address as an authorized credential issuer.
    /// @param _issuerAddress The address to authorize as an issuer.
    function addIssuer(address _issuerAddress) external onlyOwner {
        require(_issuerAddress != address(0), "Issuer address cannot be zero address.");
        require(!authorizedIssuers[_issuerAddress], "Address is already an authorized issuer.");
        authorizedIssuers[_issuerAddress] = true;
        emit IssuerAdded(_issuerAddress);
    }

    /// @notice Removes an address from the list of authorized credential issuers.
    /// @param _issuerAddress The address to remove from authorized issuers.
    function removeIssuer(address _issuerAddress) external onlyOwner {
        require(_issuerAddress != owner, "Cannot remove the contract owner as issuer.");
        require(authorizedIssuers[_issuerAddress], "Address is not an authorized issuer.");
        delete authorizedIssuers[_issuerAddress];
        emit IssuerRemoved(_issuerAddress);
    }

    /// @notice Checks if an address is an authorized credential issuer.
    /// @param _address The address to check.
    /// @return bool True if the address is an authorized issuer, false otherwise.
    function isAuthorizedIssuer(address _address) external view returns (bool) {
        return authorizedIssuers[_address];
    }

    /// @notice Sets the contract metadata (name, description, version).
    /// @param _name The name of the contract.
    /// @param _description A description of the contract.
    /// @param _version The version of the contract.
    function setContractMetadata(string memory _name, string memory _description, string memory _version) external onlyOwner {
        contractName = _name;
        contractDescription = _description;
        contractVersion = _version;
        emit ContractMetadataUpdated(_name, _description, _version);
    }

    /// @notice Retrieves the contract metadata.
    /// @return string, string, string Contract name, description, and version.
    function getContractMetadata() external view returns (string memory, string memory, string memory) {
        return (contractName, contractDescription, contractVersion);
    }

    /// @notice Pauses the issuance of new credentials.
    function pauseIssuance() external onlyOwner {
        require(!issuancePaused, "Issuance is already paused.");
        issuancePaused = true;
        emit IssuancePaused();
    }

    /// @notice Resumes the issuance of new credentials.
    function unpauseIssuance() external onlyOwner {
        require(issuancePaused, "Issuance is not paused.");
        issuancePaused = false;
        emit IssuanceUnpaused();
    }

    /// @notice Checks if credential issuance is currently paused.
    /// @return bool True if issuance is paused, false otherwise.
    function isIssuancePaused() external view returns (bool) {
        return issuancePaused;
    }

    // ** Utility & Verification Functions **

    /// @notice Calculates the keccak256 hash of credential data.
    /// @param _data The credential data to hash.
    /// @return bytes32 The keccak256 hash of the data.
    function hashCredentialData(bytes memory _data) external pure returns (bytes32) {
        return keccak256(_data);
    }

    /// @notice Allows anyone to verify the data integrity of a credential against a provided hash.
    /// @param _credentialId The ID of the credential to verify.
    /// @param _dataHash The keccak256 hash of the expected credential data.
    /// @return bool True if the hash matches the credential data hash, false otherwise.
    function verifyCredentialIntegrity(uint256 _credentialId, bytes memory _dataHash) external view returns (bool) {
        require(_credentialId > 0 && _credentialId <= credentialCounter, "Invalid credential ID.");
        bytes32 calculatedHash = keccak256(credentialsById[_credentialId].credentialData);
        return calculatedHash == _dataHash;
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(VerityChain).interfaceId || interfaceId == 0x01ffc9a7; // ERC165 interface ID for ERC165 itself
    }
}
```