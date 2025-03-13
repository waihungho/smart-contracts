```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Credentialing System
 * @author Bard (Example Smart Contract - Educational Purposes Only)
 * @dev A smart contract for managing decentralized reputation and verifiable credentials.
 *
 * **Outline and Function Summary:**
 *
 * **1. Identity Management:**
 *   - `registerIdentity(string _handle, string _profileUri)`: Registers a new identity with a unique handle and profile URI.
 *   - `updateProfile(string _newProfileUri)`: Updates the profile URI of the caller's identity.
 *   - `getIdentityProfile(address _identityAddress)`: Retrieves the profile URI and handle associated with an address.
 *   - `resolveHandleToAddress(string _handle)`: Resolves a handle to its associated identity address.
 *   - `isIdentityRegistered(address _identityAddress)`: Checks if an address is registered as an identity.
 *   - `disableIdentity()`: Allows an identity to temporarily disable their profile (e.g., for privacy).
 *   - `enableIdentity()`: Re-enables a disabled identity profile.
 *
 * **2. Reputation Scoring & Endorsements:**
 *   - `endorseIdentity(address _targetIdentity, string _endorsementMessage)`: Allows registered identities to endorse other identities with a message.
 *   - `reportIdentity(address _targetIdentity, string _reportReason)`: Allows registered identities to report other identities with a reason.
 *   - `getReputationScore(address _identityAddress)`: Calculates and retrieves a reputation score for an identity (simple example).
 *   - `getEndorsements(address _identityAddress)`: Retrieves a list of endorsements received by an identity.
 *   - `getReports(address _identityAddress)`: Retrieves a list of reports against an identity.
 *   - `setReputationWeights(uint256 _endorsementWeight, uint256 _reportWeight)`: Admin function to set weights for endorsements and reports in reputation calculation.
 *
 * **3. Verifiable Credential Management:**
 *   - `issueCredential(address _recipientIdentity, string _credentialType, string _credentialDataUri)`: Issues a verifiable credential to an identity.
 *   - `verifyCredential(address _identityAddress, string _credentialType, string _credentialDataUri)`: Allows anyone to verify if an identity holds a specific credential.
 *   - `getCredentialsByType(address _identityAddress, string _credentialType)`: Retrieves all credentials of a specific type held by an identity.
 *   - `revokeCredential(address _identityAddress, string _credentialType, string _credentialDataUri)`: Allows the issuer to revoke a previously issued credential.
 *   - `setCredentialIssuer(string _credentialType, address _issuerAddress)`: Admin function to designate specific addresses as authorized issuers for credential types.
 *   - `isCredentialIssuer(string _credentialType, address _issuerAddress)`: Checks if an address is an authorized issuer for a credential type.
 *
 * **4. Advanced Features (Trendy & Creative):**
 *   - `delegateReputationVoting(address _delegateAddress, uint256 _votingPower)`: Allows an identity to delegate a portion of their reputation voting power to another identity.
 *   - `stakeForReputationBoost(uint256 _stakeAmount)`: Allows identities to stake tokens to temporarily boost their reputation score.
 *   - `createReputationSnapshotNFT(address _identityAddress)`: Mints an NFT representing a snapshot of an identity's reputation at a point in time.
 *
 * **Important Notes:**
 * - This is a conceptual example and is not production-ready. It lacks thorough security audits, gas optimization, and advanced features like access control lists for more granular permissions.
 * - The reputation scoring is a simplified example and can be significantly enhanced with more sophisticated algorithms.
 * - Credential verification in this example is based on matching data URIs, which might need stronger cryptographic verification in a real-world scenario.
 * - The "advanced features" are illustrative and can be expanded upon for more complex functionalities.
 */
contract DecentralizedReputationSystem {

    // --- Structs ---

    struct IdentityProfile {
        string handle;
        string profileUri;
        bool isActive;
    }

    struct Endorsement {
        address endorser;
        string message;
        uint256 timestamp;
    }

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
    }

    struct Credential {
        string credentialType;
        string credentialDataUri;
        address issuer;
        uint256 issueTimestamp;
        bool isRevoked;
    }

    // --- State Variables ---

    mapping(address => IdentityProfile) public identities; // Address to Identity Profile
    mapping(string => address) public handleToAddress;    // Handle to Address resolution
    mapping(address => uint256) public reputationScores;   // Address to Reputation Score
    mapping(address => Endorsement[]) public endorsementsReceived; // Identity to Endorsements received
    mapping(address => Report[]) public reportsReceived;        // Identity to Reports received
    mapping(address => mapping(string => Credential[])) public credentialsByType; // Identity -> Credential Type -> Credentials
    mapping(string => address) public credentialIssuers;     // Credential Type to Authorized Issuer Address
    mapping(address => mapping(address => uint256)) public reputationDelegations; // Delegator -> Delegate -> Voting Power
    mapping(address => uint256) public reputationStakes;       // Identity -> Stake Amount

    uint256 public endorsementWeight = 1;  // Weight for positive endorsements in reputation
    uint256 public reportWeight = 2;     // Weight for negative reports in reputation (can be higher)
    address public admin;                 // Admin address for privileged functions

    // --- Events ---

    event IdentityRegistered(address indexed identityAddress, string handle, string profileUri);
    event ProfileUpdated(address indexed identityAddress, string newProfileUri);
    event IdentityDisabled(address indexed identityAddress);
    event IdentityEnabled(address indexed identityAddress);
    event IdentityEndorsed(address indexed endorser, address indexed targetIdentity, string message);
    event IdentityReported(address indexed reporter, address indexed targetIdentity, string reason);
    event ReputationScoreUpdated(address indexed identityAddress, uint256 newScore);
    event CredentialIssued(address indexed recipientIdentity, string credentialType, string credentialDataUri, address indexed issuer);
    event CredentialRevoked(address indexed identityAddress, string credentialType, string credentialDataUri, address indexed issuer);
    event CredentialIssuerSet(string credentialType, address issuerAddress);
    event ReputationVotingDelegated(address indexed delegator, address indexed delegate, uint256 votingPower);
    event ReputationStakeIncreased(address indexed identityAddress, uint256 stakeAmount);
    event ReputationSnapshotNFTMinted(address indexed identityAddress, uint256 tokenId); // Placeholder for NFT minting event


    // --- Modifiers ---

    modifier onlyRegisteredIdentity() {
        require(isIdentityRegistered(msg.sender), "Caller is not a registered identity.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyCredentialIssuer(string memory _credentialType) {
        require(isCredentialIssuer(_credentialType, msg.sender), "Caller is not authorized to issue this credential type.");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender; // Set the contract deployer as the initial admin
    }

    // ------------------------------------------------------------------------
    // 1. Identity Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Registers a new identity.
     * @param _handle Unique identifier handle for the identity.
     * @param _profileUri URI pointing to the identity's profile data (e.g., IPFS hash).
     */
    function registerIdentity(string memory _handle, string memory _profileUri) public {
        require(!isIdentityRegistered(msg.sender), "Identity already registered for this address.");
        require(handleToAddress[_handle] == address(0), "Handle already taken.");
        identities[msg.sender] = IdentityProfile({
            handle: _handle,
            profileUri: _profileUri,
            isActive: true
        });
        handleToAddress[_handle] = msg.sender;
        emit IdentityRegistered(msg.sender, _handle, _profileUri);
    }

    /**
     * @dev Updates the profile URI of the caller's identity.
     * @param _newProfileUri New URI pointing to the identity's profile data.
     */
    function updateProfile(string memory _newProfileUri) public onlyRegisteredIdentity {
        identities[msg.sender].profileUri = _newProfileUri;
        emit ProfileUpdated(msg.sender, _newProfileUri);
    }

    /**
     * @dev Retrieves the profile URI and handle associated with an address.
     * @param _identityAddress Address of the identity to query.
     * @return handle The handle of the identity.
     * @return profileUri The URI of the identity's profile.
     * @return isActive Whether the identity is currently active.
     */
    function getIdentityProfile(address _identityAddress) public view returns (string memory handle, string memory profileUri, bool isActive) {
        require(isIdentityRegistered(_identityAddress), "Identity not registered.");
        IdentityProfile storage profile = identities[_identityAddress];
        return (profile.handle, profile.profileUri, profile.isActive);
    }

    /**
     * @dev Resolves a handle to its associated identity address.
     * @param _handle The handle to resolve.
     * @return The address associated with the handle, or address(0) if not found.
     */
    function resolveHandleToAddress(string memory _handle) public view returns (address) {
        return handleToAddress[_handle];
    }

    /**
     * @dev Checks if an address is registered as an identity.
     * @param _identityAddress Address to check.
     * @return True if the address is registered, false otherwise.
     */
    function isIdentityRegistered(address _identityAddress) public view returns (bool) {
        return identities[_identityAddress].handle.length > 0; // Simple check if handle is set
    }

    /**
     * @dev Allows an identity to temporarily disable their profile.
     */
    function disableIdentity() public onlyRegisteredIdentity {
        identities[msg.sender].isActive = false;
        emit IdentityDisabled(msg.sender);
    }

    /**
     * @dev Re-enables a disabled identity profile.
     */
    function enableIdentity() public onlyRegisteredIdentity {
        identities[msg.sender].isActive = true;
        emit IdentityEnabled(msg.sender);
    }

    // ------------------------------------------------------------------------
    // 2. Reputation Scoring & Endorsements Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows registered identities to endorse other identities.
     * @param _targetIdentity Address of the identity being endorsed.
     * @param _endorsementMessage Message accompanying the endorsement.
     */
    function endorseIdentity(address _targetIdentity, string memory _endorsementMessage) public onlyRegisteredIdentity {
        require(isIdentityRegistered(_targetIdentity), "Target identity is not registered.");
        require(_targetIdentity != msg.sender, "Cannot endorse yourself.");

        endorsementsReceived[_targetIdentity].push(Endorsement({
            endorser: msg.sender,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));
        _updateReputationScore(_targetIdentity);
        emit IdentityEndorsed(msg.sender, _targetIdentity, _endorsementMessage);
    }

    /**
     * @dev Allows registered identities to report other identities.
     * @param _targetIdentity Address of the identity being reported.
     * @param _reportReason Reason for the report.
     */
    function reportIdentity(address _targetIdentity, string memory _reportReason) public onlyRegisteredIdentity {
        require(isIdentityRegistered(_targetIdentity), "Target identity is not registered.");
        require(_targetIdentity != msg.sender, "Cannot report yourself.");

        reportsReceived[_targetIdentity].push(Report({
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp
        }));
        _updateReputationScore(_targetIdentity); // Reports can negatively impact reputation
        emit IdentityReported(msg.sender, _targetIdentity, _reportReason);
    }

    /**
     * @dev Calculates and retrieves a reputation score for an identity.
     *      (Simple example: Endorsements - Reports * reportWeight / endorsementWeight)
     * @param _identityAddress Address of the identity to get the score for.
     * @return The reputation score.
     */
    function getReputationScore(address _identityAddress) public view returns (uint256) {
        return reputationScores[_identityAddress];
    }

    /**
     * @dev Retrieves a list of endorsements received by an identity.
     * @param _identityAddress Address of the identity.
     * @return An array of Endorsement structs.
     */
    function getEndorsements(address _identityAddress) public view returns (Endorsement[] memory) {
        return endorsementsReceived[_identityAddress];
    }

    /**
     * @dev Retrieves a list of reports against an identity.
     * @param _identityAddress Address of the identity.
     * @return An array of Report structs.
     */
    function getReports(address _identityAddress) public view returns (Report[] memory) {
        return reportsReceived[_identityAddress];
    }

    /**
     * @dev Admin function to set weights for endorsements and reports in reputation calculation.
     * @param _endorsementWeight Weight for endorsements.
     * @param _reportWeight Weight for reports.
     */
    function setReputationWeights(uint256 _endorsementWeight, uint256 _reportWeight) public onlyAdmin {
        endorsementWeight = _endorsementWeight;
        reportWeight = _reportWeight;
    }

    /**
     * @dev Internal function to update the reputation score of an identity.
     * @param _identityAddress Address of the identity to update.
     */
    function _updateReputationScore(address _identityAddress) internal {
        uint256 endorsementCount = endorsementsReceived[_identityAddress].length;
        uint256 reportCount = reportsReceived[_identityAddress].length;

        // Simple reputation calculation: (Endorsements * endorsementWeight) - (Reports * reportWeight)
        uint256 newScore = (endorsementCount * endorsementWeight) - (reportCount * reportWeight);
        reputationScores[_identityAddress] = newScore;
        emit ReputationScoreUpdated(_identityAddress, newScore);
    }

    // ------------------------------------------------------------------------
    // 3. Verifiable Credential Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Admin function to set an authorized issuer for a specific credential type.
     * @param _credentialType Type of credential (e.g., "Education", "Skill").
     * @param _issuerAddress Address authorized to issue this credential type.
     */
    function setCredentialIssuer(string memory _credentialType, address _issuerAddress) public onlyAdmin {
        credentialIssuers[_credentialType] = _issuerAddress;
        emit CredentialIssuerSet(_credentialType, _issuerAddress);
    }

    /**
     * @dev Checks if an address is an authorized issuer for a credential type.
     * @param _credentialType Type of credential.
     * @param _issuerAddress Address to check.
     * @return True if the address is an authorized issuer, false otherwise.
     */
    function isCredentialIssuer(string memory _credentialType, address _issuerAddress) public view returns (bool) {
        return credentialIssuers[_credentialType] == _issuerAddress;
    }

    /**
     * @dev Issues a verifiable credential to an identity.
     * @param _recipientIdentity Address of the identity receiving the credential.
     * @param _credentialType Type of credential being issued.
     * @param _credentialDataUri URI pointing to the credential data (e.g., IPFS hash).
     */
    function issueCredential(address _recipientIdentity, string memory _credentialType, string memory _credentialDataUri) public onlyCredentialIssuer(_credentialType) {
        require(isIdentityRegistered(_recipientIdentity), "Recipient identity is not registered.");

        credentialsByType[_recipientIdentity][_credentialType].push(Credential({
            credentialType: _credentialType,
            credentialDataUri: _credentialDataUri,
            issuer: msg.sender,
            issueTimestamp: block.timestamp,
            isRevoked: false
        }));
        emit CredentialIssued(_recipientIdentity, _credentialType, _credentialDataUri, msg.sender);
    }

    /**
     * @dev Verifies if an identity holds a specific credential.
     * @param _identityAddress Address of the identity to check.
     * @param _credentialType Type of credential to verify.
     * @param _credentialDataUri URI of the credential data to verify.
     * @return True if the identity holds the credential, false otherwise.
     */
    function verifyCredential(address _identityAddress, string memory _credentialType, string memory _credentialDataUri) public view returns (bool) {
        Credential[] storage credentials = credentialsByType[_identityAddress][_credentialType];
        for (uint256 i = 0; i < credentials.length; i++) {
            if (!credentials[i].isRevoked && keccak256(bytes(credentials[i].credentialDataUri)) == keccak256(bytes(_credentialDataUri))) {
                return true; // Found a non-revoked credential with matching data URI
            }
        }
        return false;
    }

    /**
     * @dev Retrieves all credentials of a specific type held by an identity.
     * @param _identityAddress Address of the identity.
     * @param _credentialType Type of credential to retrieve.
     * @return An array of Credential structs of the specified type.
     */
    function getCredentialsByType(address _identityAddress, string memory _credentialType) public view returns (Credential[] memory) {
        return credentialsByType[_identityAddress][_credentialType];
    }

    /**
     * @dev Allows the issuer to revoke a previously issued credential.
     * @param _identityAddress Address of the identity holding the credential.
     * @param _credentialType Type of credential to revoke.
     * @param _credentialDataUri URI of the credential data to revoke.
     */
    function revokeCredential(address _identityAddress, string memory _credentialType, string memory _credentialDataUri) public onlyCredentialIssuer(_credentialType) {
        Credential[] storage credentials = credentialsByType[_identityAddress][_credentialType];
        for (uint256 i = 0; i < credentials.length; i++) {
            if (!credentials[i].isRevoked && credentials[i].issuer == msg.sender && keccak256(bytes(credentials[i].credentialDataUri)) == keccak256(bytes(_credentialDataUri))) {
                credentials[i].isRevoked = true;
                emit CredentialRevoked(_identityAddress, _credentialType, _credentialDataUri, msg.sender);
                return; // Revoke only the first matching credential
            }
        }
        revert("Credential not found or not issued by caller.");
    }

    // ------------------------------------------------------------------------
    // 4. Advanced Features (Trendy & Creative) Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows an identity to delegate a portion of their reputation voting power to another identity.
     * @param _delegateAddress Address of the identity to delegate voting power to.
     * @param _votingPower Percentage of voting power to delegate (e.g., 50 for 50%).
     *                     Note: This is a simplified concept and voting power calculation would depend on the use case.
     */
    function delegateReputationVoting(address _delegateAddress, uint256 _votingPower) public onlyRegisteredIdentity {
        require(isIdentityRegistered(_delegateAddress), "Delegate identity is not registered.");
        require(_votingPower <= 100, "Voting power percentage must be between 0 and 100.");
        reputationDelegations[msg.sender][_delegateAddress] = _votingPower;
        emit ReputationVotingDelegated(msg.sender, _delegateAddress, _votingPower);
        // In a real voting system, this delegation would be considered when calculating voting weights.
    }

    /**
     * @dev Allows identities to stake tokens to temporarily boost their reputation score.
     *      This is a conceptual example and requires an external token contract and staking mechanism in a real implementation.
     * @param _stakeAmount Amount of tokens staked (in hypothetical token units).
     */
    function stakeForReputationBoost(uint256 _stakeAmount) public payable onlyRegisteredIdentity {
        // In a real implementation, you would integrate with an ERC20 token and a staking contract.
        // For simplicity, we just record the stake amount and conceptually increase reputation.
        require(msg.value > 0, "Must send some ETH to represent stake (conceptual)."); // Using ETH as placeholder
        reputationStakes[msg.sender] += msg.value; //  Accumulate stake (ETH in this example)
        _updateReputationScore(msg.sender); // Update reputation to reflect the (conceptual) stake boost
        emit ReputationStakeIncreased(msg.sender, msg.value);
        // In a real system, reputation boost could be proportional to stake amount and duration.
    }

    /**
     * @dev Creates a snapshot of an identity's reputation and mints an NFT representing it.
     *      This is a placeholder function. NFT minting logic and integration with an NFT contract would be required.
     * @param _identityAddress Address of the identity for whom to create a reputation snapshot NFT.
     */
    function createReputationSnapshotNFT(address _identityAddress) public onlyAdmin {
        require(isIdentityRegistered(_identityAddress), "Identity not registered.");
        uint256 currentReputation = getReputationScore(_identityAddress);

        // --- Placeholder for NFT Minting Logic ---
        // In a real implementation:
        // 1. Interact with an ERC721/ERC1155 NFT contract.
        // 2. Generate metadata for the NFT (including reputation score, timestamp, etc.).
        // 3. Mint an NFT to the _identityAddress.
        uint256 tokenId = block.timestamp; // Placeholder tokenId (replace with actual NFT minting logic)
        // Example (pseudocode):
        // nftContract.mint(_identityAddress, tokenId, metadataUri);

        emit ReputationSnapshotNFTMinted(_identityAddress, tokenId);
        // --- End Placeholder ---
    }

     /**
     * @dev Fallback function to receive ETH for the stakeForReputationBoost function (conceptual).
     */
    receive() external payable {}
}
```