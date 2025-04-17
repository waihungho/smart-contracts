```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Credentialing System (DReCS)
 * @author Bard (Example Smart Contract - For Educational Purposes)
 * @notice This contract implements a decentralized reputation and credentialing system.
 * It allows issuers to create credentials, users to earn and manage them, and verifiers
 * to check the validity and reputation of users based on their credentials.
 *
 * **Outline:**
 *
 * 1. **Credential Definition & Issuance:**
 *    - `defineCredentialType(string _typeName, string _description)`: Allows the contract owner to define new credential types.
 *    - `issueCredential(address _recipient, uint256 _credentialTypeId, string memory _credentialData)`: Allows authorized issuers to issue credentials to users.
 *    - `authorizeIssuer(address _issuer, uint256 _credentialTypeId)`: Allows the contract owner to authorize addresses to issue specific credential types.
 *    - `revokeIssuerAuthorization(address _issuer, uint256 _credentialTypeId)`: Allows the contract owner to revoke issuer authorization.
 *
 * 2. **User Credential Management:**
 *    - `getUserCredentials(address _user)`: Retrieves all credentials held by a user.
 *    - `getCredentialDetails(uint256 _credentialId)`: Retrieves detailed information about a specific credential.
 *    - `transferCredential(uint256 _credentialId, address _newRecipient)`: Allows a credential holder to transfer a credential to another user (if transferable).
 *    - `setCredentialTransferable(uint256 _credentialId, bool _isTransferable)`: Allows the issuer to set if a credential type is transferable.
 *
 * 3. **Reputation Scoring and Verification:**
 *    - `rateUser(address _user, uint256 _rating, string memory _feedback)`: Allows authorized raters to rate users.
 *    - `authorizeRater(address _rater)`: Allows the contract owner to authorize addresses to rate users.
 *    - `revokeRaterAuthorization(address _rater)`: Allows the contract owner to revoke rater authorization.
 *    - `getUserReputation(address _user)`: Retrieves the average reputation score of a user.
 *    - `getRatingDetails(uint256 _ratingId)`: Retrieves details about a specific rating.
 *    - `verifyCredential(address _user, uint256 _credentialTypeId)`: Allows verifiers to check if a user holds a specific type of credential.
 *    - `verifyReputationThreshold(address _user, uint256 _threshold)`: Allows verifiers to check if a user's reputation score meets a certain threshold.
 *
 * 4. **Advanced Features & Utilities:**
 *    - `getCredentialTypeDetails(uint256 _credentialTypeId)`: Retrieves details about a specific credential type.
 *    - `pauseContract()`: Pauses the contract, preventing most state-changing functions (owner only).
 *    - `unpauseContract()`: Resumes contract functionality (owner only).
 *    - `setContractMetadata(string memory _metadataUri)`: Allows the owner to set a URI pointing to contract metadata.
 *    - `getContractMetadataUri()`: Retrieves the contract metadata URI.
 *    - `renounceOwnership()`: Allows the contract owner to renounce ownership (careful!).
 *
 * **Function Summary:**
 *
 * - **Credential Definition:**
 *   - `defineCredentialType`: Define a new type of credential.
 *   - `getCredentialTypeDetails`: Get details about a credential type.
 * - **Credential Issuance & Management:**
 *   - `issueCredential`: Issue a credential to a user.
 *   - `authorizeIssuer`: Authorize an address to issue a specific credential type.
 *   - `revokeIssuerAuthorization`: Revoke issuer authorization.
 *   - `getUserCredentials`: Get all credentials of a user.
 *   - `getCredentialDetails`: Get details of a specific credential.
 *   - `transferCredential`: Transfer a credential to another user.
 *   - `setCredentialTransferable`: Set if a credential type is transferable.
 * - **Reputation & Verification:**
 *   - `rateUser`: Rate a user.
 *   - `authorizeRater`: Authorize an address to rate users.
 *   - `revokeRaterAuthorization`: Revoke rater authorization.
 *   - `getUserReputation`: Get the reputation score of a user.
 *   - `getRatingDetails`: Get details of a specific rating.
 *   - `verifyCredential`: Verify if a user has a specific credential.
 *   - `verifyReputationThreshold`: Verify if a user meets a reputation threshold.
 * - **Utility & Governance:**
 *   - `pauseContract`: Pause the contract.
 *   - `unpauseContract`: Unpause the contract.
 *   - `setContractMetadata`: Set contract metadata URI.
 *   - `getContractMetadataUri`: Get contract metadata URI.
 *   - `renounceOwnership`: Renounce contract ownership.
 */
contract DecentralizedReputationCredential {

    // --- Structs ---
    struct CredentialType {
        string typeName;
        string description;
        bool isTransferable;
    }

    struct Credential {
        uint256 credentialTypeId;
        address recipient;
        string credentialData;
        uint256 issueTimestamp;
        address issuer;
        bool isActive;
        bool isTransferable; // Inherited from CredentialType but stored per instance for potential overrides
    }

    struct Rating {
        address rater;
        address ratedUser;
        uint256 ratingValue; // e.g., 1-5 star rating
        string feedback;
        uint256 ratingTimestamp;
    }

    // --- State Variables ---
    address public owner;
    bool public paused;
    string public contractMetadataUri;

    uint256 public nextCredentialTypeId;
    uint256 public nextCredentialId;
    uint256 public nextRatingId;

    mapping(uint256 => CredentialType) public credentialTypes;
    mapping(uint256 => Credential) public credentials;
    mapping(uint256 => Rating) public ratings;
    mapping(uint256 => mapping(address => bool)) public authorizedIssuers; // credentialTypeId => issuerAddress => isAuthorized
    mapping(address => bool) public authorizedRaters;

    mapping(address => uint256[]) public userCredentials; // userAddress => array of credentialIds
    mapping(address => Rating[]) public userRatings; // userAddress => array of Rating structs

    // --- Events ---
    event CredentialTypeDefined(uint256 credentialTypeId, string typeName);
    event CredentialIssued(uint256 credentialId, uint256 credentialTypeId, address recipient, address issuer);
    event IssuerAuthorized(address issuer, uint256 credentialTypeId);
    event IssuerAuthorizationRevoked(address issuer, uint256 credentialTypeId);
    event CredentialTransferred(uint256 credentialId, address oldRecipient, address newRecipient);
    event CredentialTransferabilitySet(uint256 credentialId, bool isTransferable);
    event UserRated(uint256 ratingId, address rater, address ratedUser, uint256 ratingValue);
    event RaterAuthorized(address rater);
    event RaterAuthorizationRevoked(address rater);
    event ContractPaused();
    event ContractUnpaused();
    event ContractMetadataUpdated(string metadataUri);
    event OwnershipRenounced(address previousOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
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

    modifier onlyAuthorizedIssuer(uint256 _credentialTypeId) {
        require(authorizedIssuers[_credentialTypeId][msg.sender], "Issuer not authorized for this credential type.");
        _;
    }

    modifier onlyAuthorizedRater() {
        require(authorizedRaters[msg.sender], "Rater not authorized.");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
        nextCredentialTypeId = 1; // Start from 1 for easier readability
        nextCredentialId = 1;
        nextRatingId = 1;
    }

    // --- Credential Type Definition ---
    /// @notice Defines a new credential type. Only callable by the contract owner.
    /// @param _typeName The name of the credential type.
    /// @param _description A description of the credential type.
    function defineCredentialType(string memory _typeName, string memory _description, bool _isTransferable) external onlyOwner {
        require(bytes(_typeName).length > 0 && bytes(_typeName).length <= 100, "Credential type name must be between 1 and 100 characters.");
        require(bytes(_description).length <= 500, "Credential type description must be at most 500 characters.");

        credentialTypes[nextCredentialTypeId] = CredentialType({
            typeName: _typeName,
            description: _description,
            isTransferable: _isTransferable
        });

        emit CredentialTypeDefined(nextCredentialTypeId, _typeName);
        nextCredentialTypeId++;
    }

    /// @notice Retrieves details about a specific credential type.
    /// @param _credentialTypeId The ID of the credential type.
    /// @return typeName The name of the credential type.
    /// @return description The description of the credential type.
    /// @return isTransferable Whether the credential type is transferable.
    function getCredentialTypeDetails(uint256 _credentialTypeId)
        external
        view
        returns (string memory typeName, string memory description, bool isTransferable)
    {
        require(credentialTypes[_credentialTypeId].typeName.length > 0, "Credential type does not exist.");
        CredentialType storage cType = credentialTypes[_credentialTypeId];
        return (cType.typeName, cType.description, cType.isTransferable);
    }


    // --- Credential Issuance ---
    /// @notice Issues a credential of a specific type to a recipient. Only callable by authorized issuers for the credential type.
    /// @param _recipient The address of the credential recipient.
    /// @param _credentialTypeId The ID of the credential type to issue.
    /// @param _credentialData Data associated with the credential (e.g., JSON string, IPFS hash).
    function issueCredential(address _recipient, uint256 _credentialTypeId, string memory _credentialData)
        external
        whenNotPaused
        onlyAuthorizedIssuer(_credentialTypeId)
    {
        require(_recipient != address(0), "Invalid recipient address.");
        require(credentialTypes[_credentialTypeId].typeName.length > 0, "Credential type does not exist.");
        require(bytes(_credentialData).length <= 1000, "Credential data must be at most 1000 characters.");

        CredentialType storage cType = credentialTypes[_credentialTypeId];

        credentials[nextCredentialId] = Credential({
            credentialTypeId: _credentialTypeId,
            recipient: _recipient,
            credentialData: _credentialData,
            issueTimestamp: block.timestamp,
            issuer: msg.sender,
            isActive: true,
            isTransferable: cType.isTransferable
        });

        userCredentials[_recipient].push(nextCredentialId);

        emit CredentialIssued(nextCredentialId, _credentialTypeId, _recipient, msg.sender);
        nextCredentialId++;
    }

    /// @notice Authorizes an address to issue credentials of a specific type. Only callable by the contract owner.
    /// @param _issuer The address to authorize as an issuer.
    /// @param _credentialTypeId The ID of the credential type for which to authorize the issuer.
    function authorizeIssuer(address _issuer, uint256 _credentialTypeId) external onlyOwner {
        require(_issuer != address(0), "Invalid issuer address.");
        require(credentialTypes[_credentialTypeId].typeName.length > 0, "Credential type does not exist.");

        authorizedIssuers[_credentialTypeId][_issuer] = true;
        emit IssuerAuthorized(_issuer, _credentialTypeId);
    }

    /// @notice Revokes issuer authorization for a specific credential type. Only callable by the contract owner.
    /// @param _issuer The address to revoke issuer authorization from.
    /// @param _credentialTypeId The ID of the credential type for which to revoke authorization.
    function revokeIssuerAuthorization(address _issuer, uint256 _credentialTypeId) external onlyOwner {
        require(_issuer != address(0), "Invalid issuer address.");
        require(credentialTypes[_credentialTypeId].typeName.length > 0, "Credential type does not exist.");

        authorizedIssuers[_credentialTypeId][_issuer] = false;
        emit IssuerAuthorizationRevoked(_issuer, _credentialTypeId);
    }

    // --- User Credential Management ---
    /// @notice Retrieves all credential IDs held by a user.
    /// @param _user The address of the user.
    /// @return An array of credential IDs held by the user.
    function getUserCredentials(address _user) external view returns (uint256[] memory) {
        return userCredentials[_user];
    }

    /// @notice Retrieves detailed information about a specific credential.
    /// @param _credentialId The ID of the credential.
    /// @return credentialTypeId The ID of the credential type.
    /// @return recipient The address of the credential recipient.
    /// @return credentialData Data associated with the credential.
    /// @return issueTimestamp The timestamp when the credential was issued.
    /// @return issuer The address of the credential issuer.
    /// @return isActive Whether the credential is active.
    function getCredentialDetails(uint256 _credentialId)
        external
        view
        returns (
            uint256 credentialTypeId,
            address recipient,
            string memory credentialData,
            uint256 issueTimestamp,
            address issuer,
            bool isActive,
            bool isTransferable
        )
    {
        require(credentials[_credentialId].recipient != address(0), "Credential does not exist."); // Basic check if credential exists
        Credential storage cred = credentials[_credentialId];
        return (
            cred.credentialTypeId,
            cred.recipient,
            cred.credentialData,
            cred.issueTimestamp,
            cred.issuer,
            cred.isActive,
            cred.isTransferable
        );
    }

    /// @notice Transfers a credential to a new recipient. Only callable by the current credential holder and if the credential type is transferable.
    /// @param _credentialId The ID of the credential to transfer.
    /// @param _newRecipient The address of the new recipient.
    function transferCredential(uint256 _credentialId, address _newRecipient) external whenNotPaused {
        require(_newRecipient != address(0), "Invalid new recipient address.");
        require(credentials[_credentialId].recipient == msg.sender, "Only credential holder can transfer.");
        require(credentials[_credentialId].isTransferable, "Credential type is not transferable.");
        require(credentials[_credentialId].isActive, "Credential is not active.");

        address oldRecipient = credentials[_credentialId].recipient;
        credentials[_credentialId].recipient = _newRecipient;

        // Update user credential mappings - remove from old user, add to new user. (Inefficient for large lists, consider better data structure for production)
        uint256[] storage oldUserCreds = userCredentials[oldRecipient];
        for (uint256 i = 0; i < oldUserCreds.length; i++) {
            if (oldUserCreds[i] == _credentialId) {
                oldUserCreds[i] = oldUserCreds[oldUserCreds.length - 1]; // Move last element to current position
                oldUserCreds.pop(); // Remove last element (which is now duplicated or original element replaced)
                break;
            }
        }
        userCredentials[_newRecipient].push(_credentialId);

        emit CredentialTransferred(_credentialId, oldRecipient, _newRecipient);
    }

    /// @notice Sets whether a credential type is transferable. Only callable by the contract owner.
    /// @param _credentialTypeId The ID of the credential type.
    /// @param _isTransferable True if transferable, false otherwise.
    function setCredentialTransferable(uint256 _credentialTypeId, bool _isTransferable) external onlyOwner {
        require(credentialTypes[_credentialTypeId].typeName.length > 0, "Credential type does not exist.");
        credentialTypes[_credentialTypeId].isTransferable = _isTransferable;

        // Optionally update existing credential instances of this type if needed.
        // This example doesn't retroactively change existing credentials for simplicity,
        // but you could iterate through all credentials and update `isTransferable` if desired.
    }

    // --- Reputation Scoring and Verification ---
    /// @notice Allows an authorized rater to rate a user.
    /// @param _user The address of the user being rated.
    /// @param _rating The rating value (e.g., 1-5).
    /// @param _feedback Optional feedback text for the rating.
    function rateUser(address _user, uint256 _rating, string memory _feedback) external whenNotPaused onlyAuthorizedRater {
        require(_user != address(0) && _user != msg.sender, "Invalid user to rate.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example rating scale

        ratings[nextRatingId] = Rating({
            rater: msg.sender,
            ratedUser: _user,
            ratingValue: _rating,
            feedback: _feedback,
            ratingTimestamp: block.timestamp
        });

        userRatings[_user].push(ratings[nextRatingId]);

        emit UserRated(nextRatingId, msg.sender, _user, _rating);
        nextRatingId++;
    }

    /// @notice Authorizes an address to rate users. Only callable by the contract owner.
    /// @param _rater The address to authorize as a rater.
    function authorizeRater(address _rater) external onlyOwner {
        require(_rater != address(0), "Invalid rater address.");
        authorizedRaters[_rater] = true;
        emit RaterAuthorized(_rater);
    }

    /// @notice Revokes rater authorization. Only callable by the contract owner.
    /// @param _rater The address to revoke rater authorization from.
    function revokeRaterAuthorization(address _rater) external onlyOwner {
        require(_rater != address(0), "Invalid rater address.");
        authorizedRaters[_rater] = false;
        emit RaterAuthorizationRevoked(_rater);
    }

    /// @notice Retrieves the average reputation score of a user.
    /// @param _user The address of the user.
    /// @return The average reputation score, or 0 if no ratings.
    function getUserReputation(address _user) external view returns (uint256) {
        uint256[] storage userRatingIds = userCredentials[_user]; // Reusing credential mapping for example, should ideally be userRatings
        Rating[] storage userRatingList = userRatings[_user];
        if (userRatingList.length == 0) {
            return 0;
        }

        uint256 totalRating = 0;
        for (uint256 i = 0; i < userRatingList.length; i++) {
            totalRating += userRatingList[i].ratingValue;
        }
        return totalRating / userRatingList.length; // Integer division, consider scaling for more precision in real applications
    }

    /// @notice Retrieves details about a specific rating.
    /// @param _ratingId The ID of the rating.
    /// @return rater The address of the rater.
    /// @return ratedUser The address of the rated user.
    /// @return ratingValue The rating value.
    /// @return feedback The feedback text.
    /// @return ratingTimestamp The timestamp of the rating.
    function getRatingDetails(uint256 _ratingId)
        external
        view
        returns (
            address rater,
            address ratedUser,
            uint256 ratingValue,
            string memory feedback,
            uint256 ratingTimestamp
        )
    {
        require(ratings[_ratingId].ratedUser != address(0), "Rating does not exist."); // Basic check if rating exists
        Rating storage rating = ratings[_ratingId];
        return (rating.rater, rating.ratedUser, rating.ratingValue, rating.feedback, rating.ratingTimestamp);
    }

    /// @notice Verifies if a user holds a specific type of credential.
    /// @param _user The address of the user to verify.
    /// @param _credentialTypeId The ID of the credential type to check for.
    /// @return True if the user holds the credential type, false otherwise.
    function verifyCredential(address _user, uint256 _credentialTypeId) external view returns (bool) {
        uint256[] storage credIds = userCredentials[_user];
        for (uint256 i = 0; i < credIds.length; i++) {
            if (credentials[credIds[i]].credentialTypeId == _credentialTypeId && credentials[credIds[i]].isActive) {
                return true;
            }
        }
        return false;
    }

    /// @notice Verifies if a user's reputation score meets a certain threshold.
    /// @param _user The address of the user to verify.
    /// @param _threshold The minimum reputation threshold to meet.
    /// @return True if the user's reputation meets the threshold, false otherwise.
    function verifyReputationThreshold(address _user, uint256 _threshold) external view returns (bool) {
        return getUserReputation(_user) >= _threshold;
    }

    // --- Contract Governance & Utility ---
    /// @notice Pauses the contract. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Sets the URI for contract metadata (e.g., for IPFS hosted metadata). Only callable by the contract owner.
    /// @param _metadataUri The URI of the contract metadata.
    function setContractMetadata(string memory _metadataUri) external onlyOwner {
        contractMetadataUri = _metadataUri;
        emit ContractMetadataUpdated(_metadataUri);
    }

    /// @notice Retrieves the contract metadata URI.
    /// @return The contract metadata URI.
    function getContractMetadataUri() external view returns (string memory) {
        return contractMetadataUri;
    }

    /// @notice Allows the contract owner to renounce ownership. Use with caution!
    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0); // Set owner to zero address, effectively renouncing ownership.
    }

    // --- Fallback and Receive (Optional - for handling ETH if needed, not strictly necessary for this contract logic) ---
    receive() external payable {}
    fallback() external payable {}
}
```