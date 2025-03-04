```solidity
pragma solidity ^0.8.0;

/**
 * @title  VerifiableCredentialNFT - Digital Identity and Credential Management on NFT
 * @author Bard (Example Smart Contract - Creative & Advanced Concept)
 * @dev    This smart contract implements a system for managing digital identities and verifiable credentials using NFTs.
 *         It allows users to own NFTs representing their digital identities and associate verifiable credentials with these NFTs.
 *         The contract goes beyond basic NFT functionality by incorporating features for credential issuance, verification,
 *         selective disclosure, and advanced access control based on credential attributes.
 *
 * **Contract Outline & Function Summary:**
 *
 * **1. Core NFT Functionality:**
 *    - `mintNFT(address _to, string memory _identityName) external`: Mints a new Digital Identity NFT to the specified address.
 *    - `transferNFT(address _from, address _to, uint256 _tokenId) external`: Transfers ownership of a Digital Identity NFT.
 *    - `ownerOfNFT(uint256 _tokenId) public view returns (address)`: Returns the owner of a given Digital Identity NFT.
 *    - `getIdentityName(uint256 _tokenId) public view returns (string memory)`: Retrieves the identity name associated with an NFT.
 *    - `tokenURI(uint256 _tokenId) public view returns (string memory)`:  Returns a URI pointing to the metadata for the NFT (can be extended for credential info).
 *
 * **2. Credential Definition Management:**
 *    - `defineCredentialSchema(string memory _schemaName, string[] memory _attributeNames) external onlyOwner`: Defines a new credential schema with attribute names.
 *    - `getCredentialSchema(string memory _schemaName) public view returns (string[] memory)`: Retrieves the attribute names for a given credential schema.
 *    - `credentialSchemaExists(string memory _schemaName) public view returns (bool)`: Checks if a credential schema exists.
 *
 * **3. Credential Issuance and Management:**
 *    - `issueCredential(uint256 _tokenId, string memory _schemaName, string[] memory _attributeValues) external`: Issues a credential of a specific schema to a Digital Identity NFT.
 *    - `getCredentialCount(uint256 _tokenId) public view returns (uint256)`: Returns the number of credentials associated with an NFT.
 *    - `getCredentialSchemaByIndex(uint256 _tokenId, uint256 _index) public view returns (string memory)`: Retrieves the schema name of a credential at a given index.
 *    - `getCredentialAttributes(uint256 _tokenId, string memory _schemaName) public view returns (string[] memory)`: Retrieves the attribute values for a specific credential schema associated with an NFT.
 *    - `revokeCredential(uint256 _tokenId, string memory _schemaName) external onlyOwnerOrNFTOwner`: Revokes a specific credential from a Digital Identity NFT.
 *    - `credentialExists(uint256 _tokenId, string memory _schemaName) public view returns (bool)`: Checks if a specific credential schema exists for an NFT.
 *
 * **4. Credential Verification and Selective Disclosure:**
 *    - `verifyCredentialAttribute(uint256 _tokenId, string memory _schemaName, string memory _attributeName, string memory _expectedValue) public view returns (bool)`: Verifies if a specific attribute of a credential matches an expected value.
 *    - `getAttributeVisibility(uint256 _tokenId, string memory _schemaName, string memory _attributeName) public view returns (bool)`: Checks if a specific credential attribute is set as publicly visible.
 *    - `setAttributeVisibility(uint256 _tokenId, string memory _schemaName, string memory _attributeName, bool _isVisible) external onlyOwnerOrNFTOwner`: Sets the visibility of a specific credential attribute (for selective disclosure).
 *    - `getVisibleCredentialAttributes(uint256 _tokenId, string memory _schemaName) public view returns (string[] memory, string[] memory)`: Retrieves only the publicly visible attributes and their values for a given credential schema.
 *
 * **5. Advanced Access Control (Example - Can be extended):**
 *    - `hasRequiredCredentialAttribute(address _user, string memory _schemaName, string memory _attributeName, string memory _requiredValue) public view returns (bool)`: Checks if a user (NFT owner) possesses a credential with a specific attribute matching a required value. This can be used for decentralized access control.
 *
 * **6. Contract Management & Utility:**
 *    - `setContractOwner(address _newOwner) external onlyOwner`: Allows the contract owner to change ownership.
 *    - `getContractOwner() public view returns (address)`: Returns the address of the contract owner.
 *    - `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Implements ERC165 interface detection (for potential future extensions).
 *    - `getVersion() public pure returns (string memory)`: Returns the contract version.
 */
contract VerifiableCredentialNFT {
    // --- State Variables ---
    address public contractOwner;

    // Mapping from Token ID to Owner Address
    mapping(uint256 => address) public nftOwner;
    // Mapping from Token ID to Identity Name
    mapping(uint256 => string) public identityNames;
    // Token Counter for NFT IDs
    uint256 public tokenCounter;

    // Mapping to store Credential Schemas (Schema Name => Attribute Names Array)
    mapping(string => string[]) public credentialSchemas;

    // Mapping to store Credentials associated with NFTs
    // (Token ID => (Schema Name => (Attribute Name => Attribute Value)))
    mapping(uint256 => mapping(string => mapping(string => string))) public nftCredentials;

    // Mapping to track credential schemas for each NFT (Token ID => Schema Names Array)
    mapping(uint256 => string[]) public nftCredentialSchemas;

    // Mapping to track attribute visibility (Token ID => (Schema Name => (Attribute Name => isVisible)))
    mapping(uint256 => mapping(string => mapping(string => bool))) public attributeVisibility;


    // --- Events ---
    event NFTMinted(address indexed to, uint256 tokenId, string identityName);
    event NFTTransferred(address indexed from, address indexed to, uint256 tokenId);
    event CredentialSchemaDefined(string schemaName, string[] attributeNames);
    event CredentialIssued(uint256 indexed tokenId, string schemaName, string[] attributeNames, string[] attributeValues);
    event CredentialRevoked(uint256 indexed tokenId, string schemaName);
    event AttributeVisibilitySet(uint256 indexed tokenId, string schemaName, string attributeName, bool isVisible);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyOwnerOrNFTOwner(uint256 _tokenId) {
        require(msg.sender == contractOwner || msg.sender == nftOwner[_tokenId], "Only owner or NFT owner can call this function.");
        _;
    }

    modifier validTokenId(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "Invalid Token ID.");
        _;
    }

    modifier validCredentialSchema(string memory _schemaName) {
        require(credentialSchemaExists(_schemaName), "Invalid Credential Schema.");
        _;
    }

    modifier credentialExistsForNFT(uint256 _tokenId, string memory _schemaName) {
        require(credentialExists(_tokenId, _schemaName), "Credential does not exist for this NFT.");
        _;
    }


    // --- Constructor ---
    constructor() {
        contractOwner = msg.sender;
        tokenCounter = 1; // Start token IDs from 1
    }

    // --- 1. Core NFT Functionality ---

    /**
     * @dev Mints a new Digital Identity NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _identityName The name associated with the digital identity.
     */
    function mintNFT(address _to, string memory _identityName) external {
        require(_to != address(0), "Mint to the zero address.");
        require(bytes(_identityName).length > 0, "Identity name cannot be empty.");

        uint256 newTokenId = tokenCounter;
        nftOwner[newTokenId] = _to;
        identityNames[newTokenId] = _identityName;
        tokenCounter++;

        emit NFTMinted(_to, newTokenId, _identityName);
    }

    /**
     * @dev Transfers ownership of a Digital Identity NFT.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) external validTokenId(_tokenId) {
        require(msg.sender == _from, "Sender is not the current owner.");
        require(_from == nftOwner[_tokenId], "From address is not the owner.");
        require(_to != address(0), "Transfer to the zero address.");
        require(_from != _to, "Cannot transfer to self.");

        nftOwner[_tokenId] = _to;
        emit NFTTransferred(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the owner of a given Digital Identity NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOfNFT(uint256 _tokenId) public view validTokenId(_tokenId) returns (address) {
        return nftOwner[_tokenId];
    }

    /**
     * @dev Retrieves the identity name associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The identity name.
     */
    function getIdentityName(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        return identityNames[_tokenId];
    }

    /**
     * @dev Returns a URI pointing to the metadata for the NFT.
     * @param _tokenId The ID of the NFT.
     * @return The token URI (can be extended to include credential information).
     */
    function tokenURI(uint256 _tokenId) public view validTokenId(_tokenId) returns (string memory) {
        // In a real application, this would point to off-chain metadata, potentially including credential information.
        // For simplicity, we return a placeholder.
        return string(abi.encodePacked("ipfs://metadata/", uint256(_tokenId), ".json"));
    }


    // --- 2. Credential Definition Management ---

    /**
     * @dev Defines a new credential schema with attribute names. Only contract owner can call this.
     * @param _schemaName The name of the credential schema.
     * @param _attributeNames An array of attribute names for the schema.
     */
    function defineCredentialSchema(string memory _schemaName, string[] memory _attributeNames) external onlyOwner {
        require(bytes(_schemaName).length > 0, "Schema name cannot be empty.");
        require(!credentialSchemaExists(_schemaName), "Schema already exists.");
        require(_attributeNames.length > 0, "Schema must have at least one attribute.");

        credentialSchemas[_schemaName] = _attributeNames;
        emit CredentialSchemaDefined(_schemaName, _attributeNames);
    }

    /**
     * @dev Retrieves the attribute names for a given credential schema.
     * @param _schemaName The name of the credential schema.
     * @return An array of attribute names.
     */
    function getCredentialSchema(string memory _schemaName) public view validCredentialSchema(_schemaName) returns (string[] memory) {
        return credentialSchemas[_schemaName];
    }

    /**
     * @dev Checks if a credential schema exists.
     * @param _schemaName The name of the credential schema.
     * @return True if the schema exists, false otherwise.
     */
    function credentialSchemaExists(string memory _schemaName) public view returns (bool) {
        return credentialSchemas[_schemaName].length > 0;
    }


    // --- 3. Credential Issuance and Management ---

    /**
     * @dev Issues a credential of a specific schema to a Digital Identity NFT.
     * @param _tokenId The ID of the NFT to issue the credential to.
     * @param _schemaName The name of the credential schema.
     * @param _attributeValues An array of attribute values corresponding to the schema's attribute names.
     */
    function issueCredential(uint256 _tokenId, string memory _schemaName, string[] memory _attributeValues)
        external
        validTokenId(_tokenId)
        validCredentialSchema(_schemaName)
    {
        string[] memory schemaAttributes = credentialSchemas[_schemaName];
        require(schemaAttributes.length == _attributeValues.length, "Number of attribute values must match schema.");

        // Store credential attributes
        for (uint256 i = 0; i < schemaAttributes.length; i++) {
            nftCredentials[_tokenId][_schemaName][schemaAttributes[i]] = _attributeValues[i];
            attributeVisibility[_tokenId][_schemaName][schemaAttributes[i]] = false; // Default to private
        }

        // Track credential schema for the NFT (append if not already present)
        bool schemaAlreadyAdded = false;
        for (uint256 i = 0; i < nftCredentialSchemas[_tokenId].length; i++) {
            if (keccak256(bytes(nftCredentialSchemas[_tokenId][i])) == keccak256(bytes(_schemaName))) {
                schemaAlreadyAdded = true;
                break;
            }
        }
        if (!schemaAlreadyAdded) {
            nftCredentialSchemas[_tokenId].push(_schemaName);
        }


        emit CredentialIssued(_tokenId, _schemaName, schemaAttributes, _attributeValues);
    }

    /**
     * @dev Returns the number of credentials associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The number of credentials.
     */
    function getCredentialCount(uint256 _tokenId) public view validTokenId(_tokenId) returns (uint256) {
        return nftCredentialSchemas[_tokenId].length;
    }

    /**
     * @dev Retrieves the schema name of a credential at a given index for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _index The index of the credential (0-based).
     * @return The schema name of the credential.
     */
    function getCredentialSchemaByIndex(uint256 _tokenId, uint256 _index) public view validTokenId(_tokenId) returns (string memory) {
        require(_index < nftCredentialSchemas[_tokenId].length, "Credential index out of bounds.");
        return nftCredentialSchemas[_tokenId][_index];
    }


    /**
     * @dev Retrieves the attribute values for a specific credential schema associated with an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @return An array of attribute values.
     */
    function getCredentialAttributes(uint256 _tokenId, string memory _schemaName)
        public
        view
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
        returns (string[] memory)
    {
        string[] memory schemaAttributes = credentialSchemas[_schemaName];
        string[] memory attributeValues = new string[](schemaAttributes.length);
        for (uint256 i = 0; i < schemaAttributes.length; i++) {
            attributeValues[i] = nftCredentials[_tokenId][_schemaName][schemaAttributes[i]];
        }
        return attributeValues;
    }

    /**
     * @dev Revokes a specific credential from a Digital Identity NFT. Only contract owner or NFT owner can call this.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema to revoke.
     */
    function revokeCredential(uint256 _tokenId, string memory _schemaName)
        external
        onlyOwnerOrNFTOwner(_tokenId)
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
    {
        delete nftCredentials[_tokenId][_schemaName]; // Effectively removes the credential
        // Remove schema name from the list of schemas associated with the NFT
        string[] memory currentSchemas = nftCredentialSchemas[_tokenId];
        string[] memory updatedSchemas;
        uint256 updatedIndex = 0;
        for (uint256 i = 0; i < currentSchemas.length; i++) {
            if (keccak256(bytes(currentSchemas[i])) != keccak256(bytes(_schemaName))) {
                updatedSchemas.push(currentSchemas[i]); // Cannot directly resize dynamic arrays, so using push
                updatedIndex++;
            }
        }
        delete nftCredentialSchemas[_tokenId]; // Clear old array
        nftCredentialSchemas[_tokenId] = updatedSchemas; // Assign new array (may need to iterate and push if direct assignment doesn't work in older solidity versions)


        emit CredentialRevoked(_tokenId, _schemaName);
    }

    /**
     * @dev Checks if a specific credential schema exists for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @return True if the credential exists, false otherwise.
     */
    function credentialExists(uint256 _tokenId, string memory _schemaName) public view validTokenId(_tokenId) returns (bool) {
        return bytes(nftCredentials[_tokenId][_schemaName][credentialSchemas[_schemaName][0]]).length > 0; // Check if at least one attribute value exists
    }


    // --- 4. Credential Verification and Selective Disclosure ---

    /**
     * @dev Verifies if a specific attribute of a credential matches an expected value.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @param _attributeName The name of the attribute to verify.
     * @param _expectedValue The expected value of the attribute.
     * @return True if the attribute value matches the expected value, false otherwise.
     */
    function verifyCredentialAttribute(uint256 _tokenId, string memory _schemaName, string memory _attributeName, string memory _expectedValue)
        public
        view
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
        returns (bool)
    {
        return keccak256(bytes(nftCredentials[_tokenId][_schemaName][_attributeName])) == keccak256(bytes(_expectedValue));
    }

    /**
     * @dev Checks if a specific credential attribute is set as publicly visible.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @param _attributeName The name of the attribute to check visibility for.
     * @return True if the attribute is visible, false otherwise.
     */
    function getAttributeVisibility(uint256 _tokenId, string memory _schemaName, string memory _attributeName)
        public
        view
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
        returns (bool)
    {
        return attributeVisibility[_tokenId][_schemaName][_attributeName];
    }

    /**
     * @dev Sets the visibility of a specific credential attribute. Only owner or NFT owner can call this.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @param _attributeName The name of the attribute to set visibility for.
     * @param _isVisible True to make the attribute visible, false to make it private.
     */
    function setAttributeVisibility(uint256 _tokenId, string memory _schemaName, string memory _attributeName, bool _isVisible)
        external
        onlyOwnerOrNFTOwner(_tokenId)
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
    {
        attributeVisibility[_tokenId][_schemaName][_attributeName] = _isVisible;
        emit AttributeVisibilitySet(_tokenId, _schemaName, _attributeName, _isVisible);
    }

    /**
     * @dev Retrieves only the publicly visible attributes and their values for a given credential schema.
     * @param _tokenId The ID of the NFT.
     * @param _schemaName The name of the credential schema.
     * @return Two arrays: one with visible attribute names and another with corresponding values.
     */
    function getVisibleCredentialAttributes(uint256 _tokenId, string memory _schemaName)
        public
        view
        validTokenId(_tokenId)
        credentialExistsForNFT(_tokenId, _schemaName)
        validCredentialSchema(_schemaName)
        returns (string[] memory, string[] memory)
    {
        string[] memory schemaAttributes = credentialSchemas[_schemaName];
        string[] memory visibleAttributeNames;
        string[] memory visibleAttributeValues;

        for (uint256 i = 0; i < schemaAttributes.length; i++) {
            string memory attributeName = schemaAttributes[i];
            if (attributeVisibility[_tokenId][_schemaName][attributeName]) {
                visibleAttributeNames.push(attributeName);
                visibleAttributeValues.push(nftCredentials[_tokenId][_schemaName][attributeName]);
            }
        }
        return (visibleAttributeNames, visibleAttributeValues);
    }


    // --- 5. Advanced Access Control (Example) ---

    /**
     * @dev Checks if a user (NFT owner) possesses a credential with a specific attribute matching a required value.
     *      This example function can be used as a basis for more complex decentralized access control logic.
     * @param _user The address of the user (NFT owner) to check.
     * @param _schemaName The name of the credential schema to check for.
     * @param _attributeName The name of the attribute to verify.
     * @param _requiredValue The required value of the attribute.
     * @return True if the user possesses the credential with the required attribute value, false otherwise.
     */
    function hasRequiredCredentialAttribute(address _user, string memory _schemaName, string memory _attributeName, string memory _requiredValue)
        public
        view
        validCredentialSchema(_schemaName)
        returns (bool)
    {
        uint256 tokenId = _getTokenIdByOwner(_user); // Internal helper to find token ID by owner (if only one NFT per user)
        if (tokenId == 0) { // No NFT owned by this address
            return false;
        }
        if (!credentialExists(tokenId, _schemaName)) {
            return false;
        }
        return verifyCredentialAttribute(tokenId, _schemaName, _attributeName, _requiredValue);
    }

    // --- 6. Contract Management & Utility ---

    /**
     * @dev Allows the contract owner to change ownership.
     * @param _newOwner The address of the new contract owner.
     */
    function setContractOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        contractOwner = _newOwner;
    }

    /**
     * @dev Returns the address of the contract owner.
     * @return The address of the contract owner.
     */
    function getContractOwner() public view returns (address) {
        return contractOwner;
    }

    /**
     * @dev Implements ERC165 interface detection (for potential future extensions).
     * @param interfaceId The interface ID to check for.
     * @return True if the interface is supported (basic ERC165 support), false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // Basic ERC165 support (you can extend this for specific interfaces if needed)
        return interfaceId == 0x01ffc9a7; // ERC165 interface ID
    }

    /**
     * @dev Returns the contract version.
     * @return The contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return "1.0";
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal helper function to get Token ID by owner (assuming one NFT per owner for simplicity in access control example).
     *      In a real-world scenario with multiple NFTs per owner, you might need a different approach.
     * @param _owner The address of the owner.
     * @return The Token ID or 0 if no NFT is found for this owner.
     */
    function _getTokenIdByOwner(address _owner) internal view returns (uint256) {
        for (uint256 i = 1; i < tokenCounter; i++) {
            if (nftOwner[i] == _owner) {
                return i;
            }
        }
        return 0; // No NFT found for this owner
    }
}
```