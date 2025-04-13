```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Credentialing System with AI-Powered Insights
 * @author Bard (Example Smart Contract - Not for Production)
 * @dev This contract implements a decentralized reputation and credentialing system
 * with advanced features like AI-powered reputation insights, dynamic NFT-based credentials,
 * decentralized data storage integration, and community governance mechanisms.
 *
 * Function Summary:
 *
 * 1.  registerIdentity(string _metadataURI): Allows users to register their decentralized identity with metadata.
 * 2.  updateIdentityMetadata(string _newMetadataURI): Allows identity owners to update their metadata.
 * 3.  resolveIdentity(address _identityOwner): Retrieves the metadata URI associated with an identity owner.
 * 4.  issueReputation(address _targetIdentity, uint256 _score, string _reason): Issues reputation points to a target identity.
 * 5.  revokeReputation(address _targetIdentity, uint256 _score, string _reason): Revokes reputation points from a target identity.
 * 6.  getReputationScore(address _identityOwner): Retrieves the current reputation score of an identity.
 * 7.  getReputationHistory(address _identityOwner): Retrieves the history of reputation changes for an identity.
 * 8.  issueCredential(address _identityOwner, string _credentialType, string _credentialDataURI): Issues a dynamic NFT credential to an identity.
 * 9.  verifyCredential(address _credentialId): Verifies the validity and issuer of a credential NFT.
 * 10. getCredentialsByOwner(address _identityOwner): Retrieves all credential NFT IDs owned by an identity.
 * 11. updateCredentialMetadata(uint256 _credentialId, string _newMetadataURI): Updates the metadata URI of a credential NFT.
 * 12. revokeCredential(uint256 _credentialId): Revokes a credential NFT, marking it as invalid.
 * 13. delegateReputationVoting(address _delegate): Allows an identity to delegate their reputation voting power.
 * 14. voteOnReputationChange(address _targetIdentity, bool _upvote): Allows delegated voters to participate in reputation governance.
 * 15. requestAiReputationInsight(address _targetIdentity): Requests an AI-powered insight into a target identity's reputation (simulated).
 * 16. getAiReputationInsight(address _targetIdentity): Retrieves the AI-powered reputation insight (simulated).
 * 17. setContractMetadata(string _contractMetadataURI): Sets the metadata URI for the contract itself.
 * 18. getContractMetadata(): Retrieves the contract metadata URI.
 * 19. pauseContract(): Pauses critical contract functions for emergency situations (Owner only).
 * 20. unpauseContract(): Resumes contract functions after pausing (Owner only).
 * 21. withdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount): Allows the contract owner to withdraw accidentally sent tokens.
 * 22. getContractVersion(): Returns the contract version.
 */

contract DynamicReputationSystem {

    // --- State Variables ---

    address public owner;
    bool public paused = false;
    string public contractMetadataURI;
    string public contractVersion = "1.0.0";

    struct Identity {
        string metadataURI;
        uint256 reputationScore;
        address reputationDelegate;
        bool registered;
    }

    struct ReputationRecord {
        uint256 scoreChange;
        string reason;
        uint256 timestamp;
        address issuer;
        bool isRevocation;
    }

    struct Credential {
        address ownerIdentity;
        string credentialType;
        string metadataURI;
        bool isValid;
        uint256 issueTimestamp;
    }

    mapping(address => Identity) public identities;
    mapping(address => ReputationRecord[]) public reputationHistories;
    mapping(uint256 => Credential) public credentials; // Credential ID => Credential struct
    uint256 public nextCredentialId = 1;
    mapping(address => string) public aiReputationInsights; // Address => AI Insight (Simulated)

    // --- Events ---

    event IdentityRegistered(address indexed identityOwner, string metadataURI);
    event IdentityMetadataUpdated(address indexed identityOwner, string newMetadataURI);
    event ReputationIssued(address indexed targetIdentity, uint256 score, string reason, address issuer);
    event ReputationRevoked(address indexed targetIdentity, uint256 score, string reason, address issuer);
    event CredentialIssued(uint256 indexed credentialId, address indexed identityOwner, string credentialType, string metadataURI);
    event CredentialMetadataUpdated(uint256 indexed credentialId, string newMetadataURI);
    event CredentialRevoked(uint256 indexed credentialId);
    event ReputationVotingDelegated(address indexed delegator, address indexed delegate);
    event AiReputationInsightRequested(address indexed targetIdentity);
    event AiReputationInsightGenerated(address indexed targetIdentity, string insight);
    event ContractMetadataUpdated(string metadataURI);
    event ContractPaused();
    event ContractUnpaused();
    event TokensWithdrawn(address tokenAddress, address recipient, uint256 amount);

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

    modifier identityExists(address _identityOwner) {
        require(identities[_identityOwner].registered, "Identity not registered.");
        _;
    }

    modifier validCredential(uint256 _credentialId) {
        require(credentials[_credentialId].isValid, "Credential is not valid or revoked.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _contractMetadataURI) {
        owner = msg.sender;
        contractMetadataURI = _contractMetadataURI;
        emit ContractMetadataUpdated(_contractMetadataURI);
    }

    // --- Identity Management Functions ---

    /**
     * @dev Registers a new decentralized identity.
     * @param _metadataURI URI pointing to the identity metadata (e.g., IPFS hash).
     */
    function registerIdentity(string memory _metadataURI) external whenNotPaused {
        require(!identities[msg.sender].registered, "Identity already registered.");
        identities[msg.sender] = Identity({
            metadataURI: _metadataURI,
            reputationScore: 0,
            reputationDelegate: address(0),
            registered: true
        });
        emit IdentityRegistered(msg.sender, _metadataURI);
    }

    /**
     * @dev Updates the metadata URI of an existing identity.
     * @param _newMetadataURI New URI pointing to the updated identity metadata.
     */
    function updateIdentityMetadata(string memory _newMetadataURI) external whenNotPaused identityExists(msg.sender) {
        identities[msg.sender].metadataURI = _newMetadataURI;
        emit IdentityMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @dev Resolves the metadata URI for a given identity owner address.
     * @param _identityOwner Address of the identity owner.
     * @return string The metadata URI associated with the identity.
     */
    function resolveIdentity(address _identityOwner) external view identityExists(_identityOwner) returns (string memory) {
        return identities[_identityOwner].metadataURI;
    }

    /**
     * @dev Checks if an identity is registered.
     * @param _identityOwner Address to check.
     * @return bool True if the identity is registered, false otherwise.
     */
    function isIdentityRegistered(address _identityOwner) external view returns (bool) {
        return identities[_identityOwner].registered;
    }

    /**
     * @dev Gets the owner of the contract (for identity management context).
     * @return address The contract owner's address.
     */
    function getContractOwner() external view returns (address) {
        return owner;
    }

    // --- Reputation Management Functions ---

    /**
     * @dev Issues reputation points to a target identity.
     * @param _targetIdentity Address of the identity receiving reputation.
     * @param _score Number of reputation points to issue.
     * @param _reason Reason for issuing reputation.
     */
    function issueReputation(address _targetIdentity, uint256 _score, string memory _reason) external whenNotPaused identityExists(_targetIdentity) {
        require(identities[msg.sender].registered, "Issuer identity must be registered."); // Ensure issuer is also registered
        identities[_targetIdentity].reputationScore += _score;
        reputationHistories[_targetIdentity].push(ReputationRecord({
            scoreChange: _score,
            reason: _reason,
            timestamp: block.timestamp,
            issuer: msg.sender,
            isRevocation: false
        }));
        emit ReputationIssued(_targetIdentity, _score, _reason, msg.sender);
    }

    /**
     * @dev Revokes reputation points from a target identity.
     * @param _targetIdentity Address of the identity losing reputation.
     * @param _score Number of reputation points to revoke.
     * @param _reason Reason for revoking reputation.
     */
    function revokeReputation(address _targetIdentity, uint256 _score, string memory _reason) external whenNotPaused identityExists(_targetIdentity) {
        require(identities[msg.sender].registered, "Revoker identity must be registered."); // Ensure revoker is also registered
        require(identities[_targetIdentity].reputationScore >= _score, "Cannot revoke more reputation than available.");
        identities[_targetIdentity].reputationScore -= _score;
        reputationHistories[_targetIdentity].push(ReputationRecord({
            scoreChange: _score,
            reason: _reason,
            timestamp: block.timestamp,
            issuer: msg.sender,
            isRevocation: true
        }));
        emit ReputationRevoked(_targetIdentity, _score, _reason, msg.sender);
    }

    /**
     * @dev Retrieves the current reputation score of an identity.
     * @param _identityOwner Address of the identity.
     * @return uint256 The current reputation score.
     */
    function getReputationScore(address _identityOwner) external view identityExists(_identityOwner) returns (uint256) {
        return identities[_identityOwner].reputationScore;
    }

    /**
     * @dev Retrieves the history of reputation changes for an identity.
     * @param _identityOwner Address of the identity.
     * @return ReputationRecord[] Array of reputation records.
     */
    function getReputationHistory(address _identityOwner) external view identityExists(_identityOwner) returns (ReputationRecord[] memory) {
        return reputationHistories[_identityOwner];
    }

    // --- Credential Management Functions (Dynamic NFTs - Simulated) ---

    /**
     * @dev Issues a dynamic NFT-based credential to an identity.
     * @param _identityOwner Address of the identity receiving the credential.
     * @param _credentialType Type of credential being issued (e.g., "VerificationBadge", "SkillCertification").
     * @param _credentialDataURI URI pointing to detailed credential metadata (e.g., IPFS hash).
     * @return uint256 The ID of the issued credential.
     */
    function issueCredential(address _identityOwner, string memory _credentialType, string memory _credentialDataURI) external whenNotPaused identityExists(_identityOwner) returns (uint256) {
        require(identities[msg.sender].registered, "Issuer identity must be registered."); // Ensure issuer is registered

        uint256 credentialId = nextCredentialId++;
        credentials[credentialId] = Credential({
            ownerIdentity: _identityOwner,
            credentialType: _credentialType,
            metadataURI: _credentialDataURI,
            isValid: true,
            issueTimestamp: block.timestamp
        });
        emit CredentialIssued(credentialId, _identityOwner, _credentialType, _credentialDataURI);
        return credentialId;
    }

    /**
     * @dev Verifies the validity and issuer (implicitly this contract) of a credential NFT.
     * @param _credentialId ID of the credential NFT.
     * @return bool True if the credential is valid and issued by this contract.
     */
    function verifyCredential(uint256 _credentialId) external view validCredential(_credentialId) returns (bool) {
        // In a real NFT implementation, you would check ownership on the NFT contract itself.
        // Here, we are just checking validity within our contract's state.
        return credentials[_credentialId].isValid;
    }

    /**
     * @dev Retrieves all credential NFT IDs owned by a given identity.
     * @param _identityOwner Address of the identity.
     * @return uint256[] Array of credential IDs.
     */
    function getCredentialsByOwner(address _identityOwner) external view identityExists(_identityOwner) returns (uint256[] memory) {
        uint256[] memory credentialIds = new uint256[](nextCredentialId - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < nextCredentialId; i++) {
            if (credentials[i].ownerIdentity == _identityOwner) {
                credentialIds[count++] = i;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(credentialIds, count) // Update the array length
        }
        return credentialIds;
    }

    /**
     * @dev Updates the metadata URI of a credential NFT.
     * @param _credentialId ID of the credential NFT.
     * @param _newMetadataURI New URI pointing to the updated credential metadata.
     */
    function updateCredentialMetadata(uint256 _credentialId, string memory _newMetadataURI) external whenNotPaused validCredential(_credentialId) {
        require(identities[msg.sender].registered, "Updater identity must be registered."); // Ensure updater is registered
        // In a real NFT, access control would be on the NFT contract. Here, we are simplified.
        credentials[_credentialId].metadataURI = _newMetadataURI;
        emit CredentialMetadataUpdated(_credentialId, _newMetadataURI);
    }

    /**
     * @dev Revokes a credential NFT, marking it as invalid.
     * @param _credentialId ID of the credential NFT to revoke.
     */
    function revokeCredential(uint256 _credentialId) external whenNotPaused validCredential(_credentialId) {
        require(identities[msg.sender].registered, "Revoker identity must be registered."); // Ensure revoker is registered
        // In a real NFT, access control would be on the NFT contract. Here, we are simplified.
        credentials[_credentialId].isValid = false;
        emit CredentialRevoked(_credentialId);
    }

    // --- Reputation Voting Delegation (Example of Governance) ---

    /**
     * @dev Allows an identity to delegate their reputation voting power to another identity.
     * @param _delegate Address of the identity to delegate voting power to.
     */
    function delegateReputationVoting(address _delegate) external whenNotPaused identityExists(msg.sender) identityExists(_delegate) {
        identities[msg.sender].reputationDelegate = _delegate;
        emit ReputationVotingDelegated(msg.sender, _delegate);
    }

    /**
     * @dev Example function for voting on a reputation change (simplified governance).
     * @param _targetIdentity Address of the identity whose reputation is being voted on.
     * @param _upvote True for upvote, false for downvote.
     * @dev In a real system, this would be more complex with voting periods, thresholds, etc.
     */
    function voteOnReputationChange(address _targetIdentity, bool _upvote) external whenNotPaused identityExists(msg.sender) identityExists(_targetIdentity) {
        address voter = msg.sender;
        if (identities[msg.sender].reputationDelegate != address(0)) {
            voter = identities[msg.sender].reputationDelegate; // Use delegate if set
        }
        require(identities[voter].reputationScore > 0, "Voter must have reputation to vote."); // Example voting requirement

        uint256 voteScore = _upvote ? 1 : -1; // Simplified vote scoring
        issueReputation(_targetIdentity, uint256(voteScore), "Vote based reputation change"); // Directly apply score change - simplified
        // In a real system, votes would be tallied, and reputation updated based on consensus.
    }

    // --- AI-Powered Reputation Insights (Simulated) ---

    /**
     * @dev Requests an AI-powered insight into a target identity's reputation (simulated).
     * @param _targetIdentity Address of the identity to analyze.
     */
    function requestAiReputationInsight(address _targetIdentity) external whenNotPaused identityExists(_targetIdentity) {
        require(identities[msg.sender].registered, "Requestor identity must be registered."); // Ensure requestor is registered

        // --- Simulated AI Insight Generation ---
        // In a real application, this would involve calling an off-chain AI service
        // via an oracle or a decentralized AI network.
        string memory simulatedInsight = string(abi.encodePacked("Simulated AI Insight: Analyzing reputation history for ", toString(_targetIdentity), "."));
        aiReputationInsights[_targetIdentity] = simulatedInsight;
        emit AiReputationInsightRequested(_targetIdentity);
        emit AiReputationInsightGenerated(_targetIdentity, simulatedInsight);
    }

    /**
     * @dev Retrieves the AI-powered reputation insight for a target identity (simulated).
     * @param _targetIdentity Address of the identity.
     * @return string The AI-powered reputation insight (simulated).
     */
    function getAiReputationInsight(address _targetIdentity) external view identityExists(_targetIdentity) returns (string memory) {
        return aiReputationInsights[_targetIdentity];
    }

    // --- Contract Metadata Management ---

    /**
     * @dev Sets the metadata URI for the contract itself.
     * @param _contractMetadataURI URI pointing to contract-level metadata (e.g., documentation, terms).
     */
    function setContractMetadata(string memory _contractMetadataURI) external onlyOwner {
        contractMetadataURI = _contractMetadataURI;
        emit ContractMetadataUpdated(_contractMetadataURI);
    }

    /**
     * @dev Retrieves the contract metadata URI.
     * @return string The contract metadata URI.
     */
    function getContractMetadata() external view returns (string memory) {
        return contractMetadataURI;
    }

    // --- Emergency Pause Functionality ---

    /**
     * @dev Pauses critical contract functions in case of emergency or exploit.
     *      Only the contract owner can call this function.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Resumes contract functions after pausing.
     *      Only the contract owner can call this function.
     */
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Utility Functions ---

    /**
     * @dev Allows the contract owner to withdraw accidentally sent ERC20 tokens from the contract.
     * @param _tokenAddress Address of the ERC20 token contract.
     * @param _recipient Address to receive the withdrawn tokens.
     * @param _amount Amount of tokens to withdraw.
     */
    function withdrawStuckTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance in contract.");
        bool success = token.transfer(_recipient, _amount);
        require(success, "Token transfer failed.");
        emit TokensWithdrawn(_tokenAddress, _recipient, _amount);
    }

    /**
     * @dev Returns the contract version.
     * @return string Contract version string.
     */
    function getContractVersion() external pure returns (string memory) {
        return contractVersion;
    }

    // --- Helper function to convert address to string (for simulated AI insight) ---
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 15)];
        }
        return string(str);
    }
}

// --- Interface for ERC20 Token ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
```