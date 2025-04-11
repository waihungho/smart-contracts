```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Credentialing System
 * @author Bard (Example Smart Contract - Not for Production)
 * @notice This contract implements a decentralized reputation and credentialing system.
 * It allows users to build and manage their on-chain reputation, earn verifiable credentials,
 * and utilize these for various decentralized applications.
 *
 * **Outline and Function Summary:**
 *
 * **Identity Management:**
 * 1. `registerIdentity(string _username, string _profileHash)`: Allows users to register a unique identity with a username and profile hash.
 * 2. `updateProfile(string _newProfileHash)`: Allows users to update their profile information.
 * 3. `resolveIdentity(address _userAddress)`: Returns the username and profile hash associated with an address.
 * 4. `getUsername(address _userAddress)`: Returns the username associated with an address.
 * 5. `getProfileHash(address _userAddress)`: Returns the profile hash associated with an address.
 * 6. `isIdentityRegistered(address _userAddress)`: Checks if an address has registered an identity.
 *
 * **Reputation System:**
 * 7. `increaseReputation(address _userAddress, uint256 _amount)`: Allows authorized reputation issuers to increase a user's reputation score.
 * 8. `decreaseReputation(address _userAddress, uint256 _amount)`: Allows authorized reputation issuers to decrease a user's reputation score.
 * 9. `getReputationScore(address _userAddress)`: Returns the reputation score of a user.
 * 10. `addReputationIssuer(address _issuerAddress)`: Allows the contract owner to add authorized reputation issuers.
 * 11. `removeReputationIssuer(address _issuerAddress)`: Allows the contract owner to remove authorized reputation issuers.
 * 12. `isReputationIssuer(address _issuerAddress)`: Checks if an address is an authorized reputation issuer.
 *
 * **Credentialing System:**
 * 13. `issueCredential(address _userAddress, string _credentialType, string _credentialHash, uint256 _expiry)`: Allows authorized credential issuers to issue verifiable credentials to users.
 * 14. `verifyCredential(address _userAddress, string _credentialType, string _credentialHash)`: Verifies if a user holds a specific credential.
 * 15. `revokeCredential(address _userAddress, string _credentialType, string _credentialHash)`: Allows credential issuers to revoke previously issued credentials.
 * 16. `getCredentialExpiry(address _userAddress, string _credentialType, string _credentialHash)`: Returns the expiry timestamp of a credential.
 * 17. `addCredentialIssuer(address _issuerAddress)`: Allows the contract owner to add authorized credential issuers.
 * 18. `removeCredentialIssuer(address _issuerAddress)`: Allows the contract owner to remove authorized credential issuers.
 * 19. `isCredentialIssuer(address _issuerAddress)`: Checks if an address is an authorized credential issuer.
 * 20. `getCredentialsByType(address _userAddress, string _credentialType)`: Returns a list of credential hashes of a specific type held by a user.
 * 21. `getAllCredentials(address _userAddress)`: Returns a list of all credential hashes held by a user.
 *
 * **Admin & Utility:**
 * 22. `pauseContract()`: Allows the contract owner to pause the contract.
 * 23. `unpauseContract()`: Allows the contract owner to unpause the contract.
 * 24. `isPaused()`: Returns the current paused state of the contract.
 * 25. `owner()`: Returns the contract owner's address.
 */
contract DecentralizedReputationCredential {

    // ** State Variables **

    // Identity Mapping: address => Identity struct
    mapping(address => Identity) public identities;
    struct Identity {
        string username;
        string profileHash; // IPFS hash or similar
        bool registered;
    }

    // Reputation Scores: address => reputation score (uint256)
    mapping(address => uint256) public reputationScores;

    // Credential Mapping: (address => (credentialType => (credentialHash => Credential struct)))
    mapping(address => mapping(string => mapping(string => Credential))) public credentials;
    struct Credential {
        string credentialHash; // IPFS hash or similar - detailed credential data
        uint256 expiry; // Timestamp, 0 for no expiry
        bool valid;
    }

    // Authorized Reputation Issuers
    mapping(address => bool) public reputationIssuers;

    // Authorized Credential Issuers
    mapping(address => bool) public credentialIssuers;

    // Contract Owner
    address public contractOwner;

    // Pause State
    bool public paused;

    // ** Events **

    event IdentityRegistered(address indexed userAddress, string username, string profileHash);
    event ProfileUpdated(address indexed userAddress, string newProfileHash);
    event ReputationIncreased(address indexed userAddress, uint256 amount, address indexed issuer);
    event ReputationDecreased(address indexed userAddress, uint256 amount, address indexed issuer);
    event CredentialIssued(address indexed userAddress, string credentialType, string credentialHash, uint256 expiry, address indexed issuer);
    event CredentialRevoked(address indexed userAddress, string credentialType, string credentialHash, address indexed issuer);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);

    // ** Modifiers **

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only owner can call this function.");
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

    modifier onlyReputationIssuer() {
        require(reputationIssuers[msg.sender], "Only reputation issuers can call this function.");
        _;
    }

    modifier onlyCredentialIssuer() {
        require(credentialIssuers[msg.sender], "Only credential issuers can call this function.");
        _;
    }


    // ** Constructor **
    constructor() {
        contractOwner = msg.sender;
        paused = false; // Contract starts in unpaused state
    }

    // ** Identity Management Functions **

    /// @notice Registers a new identity for a user.
    /// @param _username The desired username for the identity.
    /// @param _profileHash Hash of the user's profile data (e.g., IPFS hash).
    function registerIdentity(string memory _username, string memory _profileHash) public whenNotPaused {
        require(!identities[msg.sender].registered, "Identity already registered for this address.");
        identities[msg.sender] = Identity({
            username: _username,
            profileHash: _profileHash,
            registered: true
        });
        emit IdentityRegistered(msg.sender, _username, _profileHash);
    }

    /// @notice Updates the profile hash of an existing identity.
    /// @param _newProfileHash The new profile hash to update to.
    function updateProfile(string memory _newProfileHash) public whenNotPaused {
        require(identities[msg.sender].registered, "Identity not registered. Register identity first.");
        identities[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newProfileHash);
    }

    /// @notice Resolves an address to its registered username and profile hash.
    /// @param _userAddress The address to resolve.
    /// @return username The username associated with the address.
    /// @return profileHash The profile hash associated with the address.
    function resolveIdentity(address _userAddress) public view whenNotPaused returns (string memory username, string memory profileHash) {
        require(identities[_userAddress].registered, "Identity not registered for this address.");
        return (identities[_userAddress].username, identities[_userAddress].profileHash);
    }

    /// @notice Gets the username associated with an address.
    /// @param _userAddress The address to query.
    /// @return The username or an empty string if not registered.
    function getUsername(address _userAddress) public view whenNotPaused returns (string memory) {
        if (!identities[_userAddress].registered) {
            return "";
        }
        return identities[_userAddress].username;
    }

    /// @notice Gets the profile hash associated with an address.
    /// @param _userAddress The address to query.
    /// @return The profile hash or an empty string if not registered.
    function getProfileHash(address _userAddress) public view whenNotPaused returns (string memory) {
         if (!identities[_userAddress].registered) {
            return "";
        }
        return identities[_userAddress].profileHash;
    }

    /// @notice Checks if an identity is registered for a given address.
    /// @param _userAddress The address to check.
    /// @return True if identity is registered, false otherwise.
    function isIdentityRegistered(address _userAddress) public view whenNotPaused returns (bool) {
        return identities[_userAddress].registered;
    }


    // ** Reputation System Functions **

    /// @notice Increases the reputation score of a user. Only reputation issuers can call this.
    /// @param _userAddress The address of the user to increase reputation for.
    /// @param _amount The amount to increase the reputation by.
    function increaseReputation(address _userAddress, uint256 _amount) public onlyReputationIssuer whenNotPaused {
        reputationScores[_userAddress] += _amount;
        emit ReputationIncreased(_userAddress, _amount, msg.sender);
    }

    /// @notice Decreases the reputation score of a user. Only reputation issuers can call this.
    /// @param _userAddress The address of the user to decrease reputation for.
    /// @param _amount The amount to decrease the reputation by.
    function decreaseReputation(address _userAddress, uint256 _amount) public onlyReputationIssuer whenNotPaused {
        require(reputationScores[_userAddress] >= _amount, "Reputation score cannot be negative.");
        reputationScores[_userAddress] -= _amount;
        emit ReputationDecreased(_userAddress, _amount, msg.sender);
    }

    /// @notice Gets the reputation score of a user.
    /// @param _userAddress The address of the user to query.
    /// @return The reputation score of the user.
    function getReputationScore(address _userAddress) public view whenNotPaused returns (uint256) {
        return reputationScores[_userAddress];
    }

    /// @notice Adds an address as an authorized reputation issuer. Only contract owner can call this.
    /// @param _issuerAddress The address to add as a reputation issuer.
    function addReputationIssuer(address _issuerAddress) public onlyOwner whenNotPaused {
        reputationIssuers[_issuerAddress] = true;
    }

    /// @notice Removes an address from the list of authorized reputation issuers. Only contract owner can call this.
    /// @param _issuerAddress The address to remove as a reputation issuer.
    function removeReputationIssuer(address _issuerAddress) public onlyOwner whenNotPaused {
        reputationIssuers[_issuerAddress] = false;
    }

    /// @notice Checks if an address is an authorized reputation issuer.
    /// @param _issuerAddress The address to check.
    /// @return True if the address is a reputation issuer, false otherwise.
    function isReputationIssuer(address _issuerAddress) public view whenNotPaused returns (bool) {
        return reputationIssuers[_issuerAddress];
    }


    // ** Credentialing System Functions **

    /// @notice Issues a verifiable credential to a user. Only credential issuers can call this.
    /// @param _userAddress The address of the user to issue the credential to.
    /// @param _credentialType A string representing the type of credential (e.g., "KYC", "Skill").
    /// @param _credentialHash Hash of the detailed credential data (e.g., IPFS hash).
    /// @param _expiry Timestamp representing the credential expiry (0 for no expiry).
    function issueCredential(address _userAddress, string memory _credentialType, string memory _credentialHash, uint256 _expiry) public onlyCredentialIssuer whenNotPaused {
        credentials[_userAddress][_credentialType][_credentialHash] = Credential({
            credentialHash: _credentialHash,
            expiry: _expiry,
            valid: true
        });
        emit CredentialIssued(_userAddress, _credentialType, _credentialHash, _expiry, msg.sender);
    }

    /// @notice Verifies if a user holds a specific credential.
    /// @param _userAddress The address of the user to verify.
    /// @param _credentialType The type of credential to verify.
    /// @param _credentialHash The hash of the credential to verify.
    /// @return True if the credential is valid and held by the user, false otherwise.
    function verifyCredential(address _userAddress, string memory _credentialType, string memory _credentialHash) public view whenNotPaused returns (bool) {
        Credential storage cred = credentials[_userAddress][_credentialType][_credentialHash];
        if (!cred.valid) {
            return false; // Credential not found or revoked
        }
        if (cred.expiry != 0 && block.timestamp > cred.expiry) {
            return false; // Credential expired
        }
        return true; // Credential is valid and not expired
    }

    /// @notice Revokes a previously issued credential. Only credential issuers can call this.
    /// @param _userAddress The address of the user whose credential should be revoked.
    /// @param _credentialType The type of credential to revoke.
    /// @param _credentialHash The hash of the credential to revoke.
    function revokeCredential(address _userAddress, string memory _credentialType, string memory _credentialHash) public onlyCredentialIssuer whenNotPaused {
        require(credentials[_userAddress][_credentialType][_credentialHash].valid, "Credential not found or already revoked.");
        credentials[_userAddress][_credentialType][_credentialHash].valid = false;
        emit CredentialRevoked(_userAddress, _credentialType, _credentialHash, msg.sender);
    }

    /// @notice Gets the expiry timestamp of a credential.
    /// @param _userAddress The address of the user holding the credential.
    /// @param _credentialType The type of credential.
    /// @param _credentialHash The hash of the credential.
    /// @return The expiry timestamp of the credential (0 if no expiry), or 0 if credential not found.
    function getCredentialExpiry(address _userAddress, string memory _credentialType, string memory _credentialHash) public view whenNotPaused returns (uint256) {
        return credentials[_userAddress][_credentialType][_credentialHash].expiry;
    }

    /// @notice Adds an address as an authorized credential issuer. Only contract owner can call this.
    /// @param _issuerAddress The address to add as a credential issuer.
    function addCredentialIssuer(address _issuerAddress) public onlyOwner whenNotPaused {
        credentialIssuers[_issuerAddress] = true;
    }

    /// @notice Removes an address from the list of authorized credential issuers. Only contract owner can call this.
    /// @param _issuerAddress The address to remove as a credential issuer.
    function removeCredentialIssuer(address _issuerAddress) public onlyOwner whenNotPaused {
        credentialIssuers[_issuerAddress] = false;
    }

    /// @notice Checks if an address is an authorized credential issuer.
    /// @param _issuerAddress The address to check.
    /// @return True if the address is a credential issuer, false otherwise.
    function isCredentialIssuer(address _issuerAddress) public view whenNotPaused returns (bool) {
        return credentialIssuers[_issuerAddress];
    }

    /// @notice Gets a list of credential hashes of a specific type held by a user.
    /// @param _userAddress The address of the user.
    /// @param _credentialType The type of credential to filter by.
    /// @return An array of credential hashes of the specified type.
    function getCredentialsByType(address _userAddress, string memory _credentialType) public view whenNotPaused returns (string[] memory) {
        string[] memory credentialHashList = new string[](0);
        uint256 count = 0;
        for (uint256 i = 0; i < 100; i++) { // Limit to avoid unbounded loops, consider better iteration if scale is large
            string memory currentHash;
            uint256 index = 0;
            for (bytes32 keyHash in credentials[_userAddress][_credentialType]) { // Iterate over keys in the inner mapping
                if (index == i) {
                    currentHash = string(abi.encodePacked(keyHash)); // Convert bytes32 to string
                    break;
                }
                index++;
            }

            if (bytes(currentHash).length > 0 && credentials[_userAddress][_credentialType][currentHash].valid) {
                credentialHashList = _arrayPush(credentialHashList, credentials[_userAddress][_credentialType][currentHash].credentialHash);
                count++;
            }
            if (count >= 100) break; // Safety limit
        }
        return credentialHashList;
    }

    /// @notice Gets a list of all credential hashes held by a user, regardless of type.
    /// @param _userAddress The address of the user.
    /// @return An array of all credential hashes held by the user.
    function getAllCredentials(address _userAddress) public view whenNotPaused returns (string[] memory) {
        string[] memory allCredentialHashes = new string[](0);
        uint256 totalCount = 0;
        uint256 typeCount = 0;
        for (uint256 typeIndex = 0; typeIndex < 10; typeIndex++) { // Limit type iteration
            string memory currentType;
            uint256 indexType = 0;
             for (bytes32 keyType in credentials[_userAddress]) { // Iterate over credential types
                if (indexType == typeIndex) {
                    currentType = string(abi.encodePacked(keyType));
                    break;
                }
                indexType++;
            }
            if (bytes(currentType).length > 0) {
                string[] memory typeCredentials = getCredentialsByType(_userAddress, currentType);
                for (uint256 i = 0; i < typeCredentials.length; i++) {
                    allCredentialHashes = _arrayPush(allCredentialHashes, typeCredentials[i]);
                    totalCount++;
                }
            }
             if (totalCount >= 200) break; // Safety limit
             typeCount++;
             if (typeCount >= 10) break; // Safety limit for types
        }
        return allCredentialHashes;
    }

    // Helper function to push to dynamic array (memory only)
    function _arrayPush(string[] memory _array, string memory _value) internal pure returns (string[] memory) {
        string[] memory newArray = new string[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    // ** Admin & Utility Functions **

    /// @notice Pauses the contract, preventing most state-changing functions from being called. Only contract owner can call this.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing normal operation. Only contract owner can call this.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isPaused() public view returns (bool) {
        return paused;
    }

    /// @notice Returns the address of the contract owner.
    /// @return The contract owner's address.
    function owner() public view returns (address) {
        return contractOwner;
    }
}
```