```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation Oracle & Credentialing System
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a decentralized reputation and credentialing system.
 * It allows for issuers to define and issue verifiable credentials to users, and for reputation scores to be assigned and managed based on various on-chain activities.
 * This system can be used for various applications like decentralized identity, skill verification, community reputation, and more.
 *
 * **Outline and Function Summary:**
 *
 * **1. Ownership & Admin Functions:**
 *    - `constructor(address _admin)`: Initializes the contract with an admin address.
 *    - `transferOwnership(address newOwner)`: Allows the contract owner to transfer ownership.
 *    - `pauseContract()`: Pauses most contract functionalities (admin only).
 *    - `unpauseContract()`: Resumes contract functionalities (admin only).
 *    - `setContractAdmin(address _newAdmin)`: Changes the contract admin (owner only).
 *
 * **2. Issuer Management:**
 *    - `registerIssuer(address _issuerAddress, string memory _issuerName, string memory _issuerDescription)`: Registers a new credential issuer (admin only).
 *    - `revokeIssuer(address _issuerAddress)`: Revokes issuer status (admin only).
 *    - `isIssuer(address _address)`: Checks if an address is a registered issuer.
 *    - `getIssuerDetails(address _issuerAddress)`: Retrieves details of a registered issuer.
 *
 * **3. Credential Definition Management:**
 *    - `defineCredential(string memory _credentialName, string memory _credentialDescription, string[] memory _attributeNames)`: Defines a new type of credential (issuer only).
 *    - `updateCredentialDefinition(uint256 _credentialId, string memory _newDescription, string[] memory _newAttributeNames)`: Updates an existing credential definition (issuer only, original definer).
 *    - `getCredentialDefinition(uint256 _credentialId)`: Retrieves details of a credential definition.
 *    - `getAllCredentialDefinitions()`: Retrieves a list of all defined credential IDs.
 *
 * **4. Credential Issuance & Revocation:**
 *    - `issueCredential(uint256 _credentialDefinitionId, address _recipient, string[] memory _attributeValues, uint256 _expiryTimestamp)`: Issues a credential to a recipient (issuer only, for defined credential type).
 *    - `batchIssueCredentials(uint256 _credentialDefinitionId, address[] memory _recipients, string[][] memory _attributeValueSets, uint256[] memory _expiryTimestamps)`: Issues multiple credentials in a batch (issuer only).
 *    - `revokeCredential(uint256 _credentialId)`: Revokes a specific credential (issuer only, original issuer).
 *    - `isCredentialValid(uint256 _credentialId)`: Checks if a credential is valid (not revoked and not expired).
 *    - `getCredentialDetails(uint256 _credentialId)`: Retrieves details of a specific credential.
 *    - `getUserCredentials(address _userAddress)`: Retrieves a list of credential IDs held by a user.
 *
 * **5. Reputation Scoring & Badges (Advanced Concept):**
 *    - `updateReputationScore(address _userAddress, int256 _scoreChange, string memory _reason)`: Updates a user's reputation score (admin or designated reputation updater role).
 *    - `getReputationScore(address _userAddress)`: Retrieves a user's current reputation score.
 *    - `defineReputationBadge(string memory _badgeName, string memory _badgeDescription, int256 _requiredScore)`: Defines a reputation badge that users can earn (admin only).
 *    - `awardReputationBadge(address _userAddress, uint256 _badgeId)`: Awards a reputation badge to a user (automatically triggered or admin/designated role).
 *    - `getUserReputationBadges(address _userAddress)`: Retrieves a list of badge IDs earned by a user.
 *
 * **6. Data Retrieval & Utility Functions:**
 *    - `getContractBalance()`: Retrieves the contract's ETH balance.
 *    - `getVersion()`: Returns the contract version string.
 */
contract DecentralizedReputationOracle {
    // --- State Variables ---
    address public owner;
    address public admin;
    bool public paused;
    uint256 public credentialDefinitionCount;
    uint256 public credentialCount;
    uint256 public reputationBadgeCount;
    string public constant VERSION = "1.0.0"; // Contract version

    // Issuer Registry
    mapping(address => Issuer) public issuers;
    address[] public issuerList;

    struct Issuer {
        string name;
        string description;
        bool isActive;
    }

    // Credential Definitions
    mapping(uint256 => CredentialDefinition) public credentialDefinitions;
    mapping(uint256 => uint256) public credentialDefinitionIssuer; // Map definition ID to issuer address
    uint256[] public credentialDefinitionIdList;

    struct CredentialDefinition {
        string name;
        string description;
        string[] attributeNames;
        address definerIssuer; // Issuer who defined this credential type
    }

    // Credentials
    mapping(uint256 => Credential) public credentials;
    mapping(address => uint256[]) public userCredentials; // Map user address to list of credential IDs
    uint256[] public credentialIdList;

    struct Credential {
        uint256 definitionId;
        address recipient;
        string[] attributeValues;
        uint256 issueTimestamp;
        uint256 expiryTimestamp; // 0 for no expiry
        bool isRevoked;
        address issuer; // Issuer of this specific credential instance
    }

    // Reputation System
    mapping(address => ReputationProfile) public reputationProfiles;

    struct ReputationProfile {
        int256 score;
        uint256[] earnedBadges;
    }

    // Reputation Badges
    mapping(uint256 => ReputationBadgeDefinition) public reputationBadgeDefinitions;
    uint256[] public reputationBadgeIdList;

    struct ReputationBadgeDefinition {
        string name;
        string description;
        int256 requiredScore;
    }

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    event IssuerRegistered(address indexed issuerAddress, string issuerName);
    event IssuerRevoked(address indexed issuerAddress);
    event CredentialDefinitionCreated(uint256 indexed definitionId, address indexed issuer, string definitionName);
    event CredentialDefinitionUpdated(uint256 indexed definitionId, address indexed issuer);
    event CredentialIssued(uint256 indexed credentialId, uint256 indexed definitionId, address indexed recipient, address issuer);
    event CredentialsBatchIssued(uint256 definitionId, address issuer, uint256 count);
    event CredentialRevoked(uint256 indexed credentialId, address indexed issuer);
    event ReputationScoreUpdated(address indexed userAddress, int256 scoreChange, int256 newScore, string reason);
    event ReputationBadgeDefined(uint256 indexed badgeId, string badgeName, int256 requiredScore);
    event ReputationBadgeAwarded(address indexed userAddress, uint256 indexed badgeId);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    modifier onlyIssuer() {
        require(isIssuer(msg.sender), "Caller is not a registered issuer");
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
    constructor(address _admin) {
        owner = msg.sender;
        admin = _admin;
        paused = false;
        credentialDefinitionCount = 0;
        credentialCount = 0;
        reputationBadgeCount = 0;
        emit OwnershipTransferred(address(0), owner);
        emit AdminChanged(address(0), admin);
    }

    // --- 1. Ownership & Admin Functions ---

    /**
     * @dev Transfers contract ownership to a new address.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Sets a new admin address for the contract. Only callable by the owner.
     * @param _newAdmin The address of the new admin.
     */
    function setContractAdmin(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0), "New admin is the zero address");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @dev Pauses the contract, restricting most functionalities. Only callable by the admin.
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(admin);
    }

    /**
     * @dev Unpauses the contract, restoring functionalities. Only callable by the admin.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(admin);
    }

    // --- 2. Issuer Management ---

    /**
     * @dev Registers a new credential issuer. Only callable by the admin.
     * @param _issuerAddress The address of the issuer to register.
     * @param _issuerName The name of the issuer.
     * @param _issuerDescription A brief description of the issuer.
     */
    function registerIssuer(address _issuerAddress, string memory _issuerName, string memory _issuerDescription) public onlyAdmin whenNotPaused {
        require(_issuerAddress != address(0), "Issuer address cannot be zero address");
        require(!isIssuer(_issuerAddress), "Issuer already registered");
        issuers[_issuerAddress] = Issuer({
            name: _issuerName,
            description: _issuerDescription,
            isActive: true
        });
        issuerList.push(_issuerAddress);
        emit IssuerRegistered(_issuerAddress, _issuerName);
    }

    /**
     * @dev Revokes issuer status. Only callable by the admin.
     * @param _issuerAddress The address of the issuer to revoke.
     */
    function revokeIssuer(address _issuerAddress) public onlyAdmin whenNotPaused {
        require(isIssuer(_issuerAddress), "Issuer not registered");
        issuers[_issuerAddress].isActive = false;
        emit IssuerRevoked(_issuerAddress);
    }

    /**
     * @dev Checks if an address is a registered and active issuer.
     * @param _address The address to check.
     * @return True if the address is a registered and active issuer, false otherwise.
     */
    function isIssuer(address _address) public view returns (bool) {
        return issuers[_address].isActive;
    }

    /**
     * @dev Retrieves details of a registered issuer.
     * @param _issuerAddress The address of the issuer.
     * @return Issuer struct containing issuer details.
     */
    function getIssuerDetails(address _issuerAddress) public view returns (Issuer memory) {
        require(isIssuer(_issuerAddress), "Issuer not registered");
        return issuers[_issuerAddress];
    }

    // --- 3. Credential Definition Management ---

    /**
     * @dev Defines a new type of credential. Only callable by registered issuers.
     * @param _credentialName The name of the credential type.
     * @param _credentialDescription A description of the credential type.
     * @param _attributeNames An array of attribute names for this credential type.
     * @return The ID of the newly created credential definition.
     */
    function defineCredential(
        string memory _credentialName,
        string memory _credentialDescription,
        string[] memory _attributeNames
    ) public onlyIssuer whenNotPaused returns (uint256) {
        require(bytes(_credentialName).length > 0, "Credential name cannot be empty");
        require(_attributeNames.length > 0, "At least one attribute name is required");

        credentialDefinitionCount++;
        uint256 definitionId = credentialDefinitionCount;
        credentialDefinitions[definitionId] = CredentialDefinition({
            name: _credentialName,
            description: _credentialDescription,
            attributeNames: _attributeNames,
            definerIssuer: msg.sender
        });
        credentialDefinitionIssuer[definitionId] = definitionId; // Storing definition ID again for easier lookup if needed
        credentialDefinitionIdList.push(definitionId);
        emit CredentialDefinitionCreated(definitionId, msg.sender, _credentialName);
        return definitionId;
    }

    /**
     * @dev Updates an existing credential definition. Only callable by the issuer who defined it.
     * @param _credentialId The ID of the credential definition to update.
     * @param _newDescription The new description for the credential type.
     * @param _newAttributeNames The new array of attribute names.
     */
    function updateCredentialDefinition(
        uint256 _credentialId,
        string memory _newDescription,
        string[] memory _newAttributeNames
    ) public onlyIssuer whenNotPaused {
        require(credentialDefinitions[_credentialId].definerIssuer == msg.sender, "Only definer issuer can update");
        require(credentialDefinitions[_credentialId].definerIssuer != address(0), "Credential definition not found"); // Ensure definition exists

        credentialDefinitions[_credentialId].description = _newDescription;
        credentialDefinitions[_credentialId].attributeNames = _newAttributeNames;
        emit CredentialDefinitionUpdated(_credentialId, msg.sender);
    }

    /**
     * @dev Retrieves details of a credential definition.
     * @param _credentialId The ID of the credential definition.
     * @return CredentialDefinition struct containing definition details.
     */
    function getCredentialDefinition(uint256 _credentialId) public view returns (CredentialDefinition memory) {
        require(credentialDefinitions[_credentialId].definerIssuer != address(0), "Credential definition not found");
        return credentialDefinitions[_credentialId];
    }

    /**
     * @dev Retrieves a list of all defined credential definition IDs.
     * @return An array of credential definition IDs.
     */
    function getAllCredentialDefinitions() public view returns (uint256[] memory) {
        return credentialDefinitionIdList;
    }

    // --- 4. Credential Issuance & Revocation ---

    /**
     * @dev Issues a credential to a recipient. Only callable by registered issuers.
     * @param _credentialDefinitionId The ID of the credential definition to issue.
     * @param _recipient The address of the credential recipient.
     * @param _attributeValues An array of attribute values for this credential instance.
     * @param _expiryTimestamp Unix timestamp for credential expiry (0 for no expiry).
     * @return The ID of the newly issued credential.
     */
    function issueCredential(
        uint256 _credentialDefinitionId,
        address _recipient,
        string[] memory _attributeValues,
        uint256 _expiryTimestamp
    ) public onlyIssuer whenNotPaused returns (uint256) {
        require(credentialDefinitions[_credentialDefinitionId].definerIssuer != address(0), "Credential definition not found"); // Definition exists
        require(credentialDefinitions[_credentialDefinitionId].attributeNames.length == _attributeValues.length, "Attribute values count mismatch");
        require(_recipient != address(0), "Recipient address cannot be zero");

        credentialCount++;
        uint256 credentialId = credentialCount;
        credentials[credentialId] = Credential({
            definitionId: _credentialDefinitionId,
            recipient: _recipient,
            attributeValues: _attributeValues,
            issueTimestamp: block.timestamp,
            expiryTimestamp: _expiryTimestamp,
            isRevoked: false,
            issuer: msg.sender
        });
        userCredentials[_recipient].push(credentialId);
        credentialIdList.push(credentialId);
        emit CredentialIssued(credentialId, _credentialDefinitionId, _recipient, msg.sender);
        return credentialId;
    }

    /**
     * @dev Issues multiple credentials in a batch.  Reduces gas costs for bulk issuance.
     * @param _credentialDefinitionId The ID of the credential definition to issue.
     * @param _recipients An array of recipient addresses.
     * @param _attributeValueSets An array of arrays of attribute values, corresponding to each recipient.
     * @param _expiryTimestamps An array of expiry timestamps for each credential.
     */
    function batchIssueCredentials(
        uint256 _credentialDefinitionId,
        address[] memory _recipients,
        string[][] memory _attributeValueSets,
        uint256[] memory _expiryTimestamps
    ) public onlyIssuer whenNotPaused {
        require(credentialDefinitions[_credentialDefinitionId].definerIssuer != address(0), "Credential definition not found"); // Definition exists
        require(_recipients.length == _attributeValueSets.length && _recipients.length == _expiryTimestamps.length, "Input arrays length mismatch");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(_recipients[i] != address(0), "Recipient address cannot be zero");
            require(credentialDefinitions[_credentialDefinitionId].attributeNames.length == _attributeValueSets[i].length, "Attribute values count mismatch for recipient");

            credentialCount++;
            uint256 credentialId = credentialCount;
            credentials[credentialId] = Credential({
                definitionId: _credentialDefinitionId,
                recipient: _recipients[i],
                attributeValues: _attributeValueSets[i],
                issueTimestamp: block.timestamp,
                expiryTimestamp: _expiryTimestamps[i],
                isRevoked: false,
                issuer: msg.sender
            });
            userCredentials[_recipients[i]].push(credentialId);
            credentialIdList.push(credentialId);
            emit CredentialIssued(credentialId, _credentialDefinitionId, _recipients[i], msg.sender); // Emit individual events for batch for indexing
        }
        emit CredentialsBatchIssued(_credentialDefinitionId, msg.sender, _recipients.length);
    }

    /**
     * @dev Revokes a specific credential. Only callable by the issuer who issued it.
     * @param _credentialId The ID of the credential to revoke.
     */
    function revokeCredential(uint256 _credentialId) public onlyIssuer whenNotPaused {
        require(credentials[_credentialId].issuer == msg.sender, "Only issuer can revoke");
        require(!credentials[_credentialId].isRevoked, "Credential already revoked"); // Prevent double revocation

        credentials[_credentialId].isRevoked = true;
        emit CredentialRevoked(_credentialId, msg.sender);
    }

    /**
     * @dev Checks if a credential is valid (not revoked and not expired).
     * @param _credentialId The ID of the credential to check.
     * @return True if the credential is valid, false otherwise.
     */
    function isCredentialValid(uint256 _credentialId) public view returns (bool) {
        Credential memory cred = credentials[_credentialId];
        if (cred.recipient == address(0)) return false; // Credential doesn't exist
        if (cred.isRevoked) return false;
        if (cred.expiryTimestamp != 0 && block.timestamp > cred.expiryTimestamp) return false;
        return true;
    }

    /**
     * @dev Retrieves details of a specific credential.
     * @param _credentialId The ID of the credential.
     * @return Credential struct containing credential details.
     */
    function getCredentialDetails(uint256 _credentialId) public view returns (Credential memory) {
        require(credentials[_credentialId].recipient != address(0), "Credential not found");
        return credentials[_credentialId];
    }

    /**
     * @dev Retrieves a list of credential IDs held by a user.
     * @param _userAddress The address of the user.
     * @return An array of credential IDs held by the user.
     */
    function getUserCredentials(address _userAddress) public view returns (uint256[] memory) {
        return userCredentials[_userAddress];
    }

    // --- 5. Reputation Scoring & Badges (Advanced Concept) ---

    /**
     * @dev Updates a user's reputation score. Only callable by admin or designated reputation updaters (role-based access control can be further implemented).
     * @param _userAddress The address of the user whose reputation score to update.
     * @param _scoreChange The amount to change the score by (can be positive or negative).
     * @param _reason A string describing the reason for the score change.
     */
    function updateReputationScore(address _userAddress, int256 _scoreChange, string memory _reason) public onlyAdmin whenNotPaused { // In real-world, consider role-based access
        if (reputationProfiles[_userAddress].score == 0 && _scoreChange > 0) {
            _initializeReputationProfile(_userAddress); // Lazy initialization
        }
        reputationProfiles[_userAddress].score += _scoreChange;

        // Check for badge awards based on new score
        _checkAndAwardBadges(_userAddress, reputationProfiles[_userAddress].score);

        emit ReputationScoreUpdated(_userAddress, _scoreChange, reputationProfiles[_userAddress].score, _reason);
    }

    /**
     * @dev Retrieves a user's current reputation score.
     * @param _userAddress The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _userAddress) public view returns (int256) {
        return reputationProfiles[_userAddress].score;
    }

    /**
     * @dev Defines a new reputation badge. Only callable by admin.
     * @param _badgeName The name of the badge.
     * @param _badgeDescription A description of the badge.
     * @param _requiredScore The reputation score required to earn this badge.
     * @return The ID of the newly created badge definition.
     */
    function defineReputationBadge(string memory _badgeName, string memory _badgeDescription, int256 _requiredScore) public onlyAdmin whenNotPaused returns (uint256) {
        require(bytes(_badgeName).length > 0, "Badge name cannot be empty");
        reputationBadgeCount++;
        uint256 badgeId = reputationBadgeCount;
        reputationBadgeDefinitions[badgeId] = ReputationBadgeDefinition({
            name: _badgeName,
            description: _badgeDescription,
            requiredScore: _requiredScore
        });
        reputationBadgeIdList.push(badgeId);
        emit ReputationBadgeDefined(badgeId, _badgeName, _requiredScore);
        return badgeId;
    }

    /**
     * @dev Awards a reputation badge to a user. Can be triggered automatically or by admin/designated role.
     * @param _userAddress The address of the user to award the badge to.
     * @param _badgeId The ID of the badge to award.
     */
    function awardReputationBadge(address _userAddress, uint256 _badgeId) public onlyAdmin whenNotPaused { // Can also be triggered internally
        require(reputationBadgeDefinitions[_badgeId].requiredScore != 0 || reputationBadgeDefinitions[_badgeId].name != "", "Badge definition not found"); // Badge exists
        require(!_hasBadge(reputationProfiles[_userAddress].earnedBadges, _badgeId), "Badge already awarded"); // Prevent duplicate badges

        reputationProfiles[_userAddress].earnedBadges.push(_badgeId);
        emit ReputationBadgeAwarded(_userAddress, _badgeId);
    }

    /**
     * @dev Retrieves a list of badge IDs earned by a user.
     * @param _userAddress The address of the user.
     * @return An array of badge IDs.
     */
    function getUserReputationBadges(address _userAddress) public view returns (uint256[] memory) {
        return reputationProfiles[_userAddress].earnedBadges;
    }

    // --- 6. Data Retrieval & Utility Functions ---

    /**
     * @dev Gets the contract's current ETH balance.
     * @return The contract's ETH balance in wei.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the contract version string.
     * @return The contract version string.
     */
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Initializes a reputation profile for a user if it doesn't exist.
     * @param _userAddress The address of the user.
     */
    function _initializeReputationProfile(address _userAddress) internal {
        if (reputationProfiles[_userAddress].score == 0 && reputationProfiles[_userAddress].earnedBadges.length == 0) {
            reputationProfiles[_userAddress] = ReputationProfile({
                score: 0,
                earnedBadges: new uint256[](0) // Initialize with empty badge array
            });
        }
    }

    /**
     * @dev Checks if a user's score meets requirements for new badges and awards them.
     * @param _userAddress The address of the user.
     * @param _currentScore The user's current reputation score.
     */
    function _checkAndAwardBadges(address _userAddress, int256 _currentScore) internal {
        for (uint256 i = 0; i < reputationBadgeIdList.length; i++) {
            uint256 badgeId = reputationBadgeIdList[i];
            if (_currentScore >= reputationBadgeDefinitions[badgeId].requiredScore && !_hasBadge(reputationProfiles[_userAddress].earnedBadges, badgeId)) {
                awardReputationBadge(_userAddress, badgeId); // Award badge if score threshold is met and badge not already awarded
            }
        }
    }

    /**
     * @dev Checks if a user has already earned a specific badge.
     * @param _userBadges Array of badge IDs earned by the user.
     * @param _badgeId The badge ID to check for.
     * @return True if the user has the badge, false otherwise.
     */
    function _hasBadge(uint256[] memory _userBadges, uint256 _badgeId) internal pure returns (bool) {
        for (uint256 i = 0; i < _userBadges.length; i++) {
            if (_userBadges[i] == _badgeId) {
                return true;
            }
        }
        return false;
    }
}
```