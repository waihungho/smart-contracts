```solidity
/**
 * @title Decentralized Digital Identity & Reputation Platform (DID-Rep)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized digital identity and reputation system.
 *
 * Outline:
 * 1. Identity Management:
 *    - registerIdentity(): Allows users to register a unique digital identity.
 *    - updateProfile(): Users can update their profile information (e.g., name, bio).
 *    - getProfile(): Retrieve a user's profile information.
 *    - verifyIdentityClaim(): Allow users to cryptographically prove claims about their identity.
 *    - deactivateIdentity(): User can temporarily deactivate their identity.
 *
 * 2. Reputation System:
 *    - endorseIdentity(): Users can endorse other identities for specific skills/attributes.
 *    - reportMisconduct(): Users can report misconduct associated with an identity.
 *    - getReputationScore(): Calculate a reputation score based on endorsements and reports.
 *    - stakeForReputation(): Users can stake tokens to vouch for their reputation or others.
 *    - disputeReputationReport(): Allow users to dispute misconduct reports.
 *
 * 3. Credentialing & Attestation:
 *    - issueCredential(): Authorized entities can issue verifiable credentials to identities.
 *    - verifyCredential(): Verify the validity and issuer of a credential.
 *    - revokeCredential(): Issuers can revoke previously issued credentials.
 *    - requestCredential(): Users can request specific credentials from issuers.
 *
 * 4. Data Privacy & Control:
 *    - setProfileVisibility(): Users can control the visibility of their profile information.
 *    - grantDataAccess(): Users can grant specific entities access to parts of their data.
 *    - revokeDataAccess(): Users can revoke data access granted to entities.
 *    - getAuthorizedEntities(): View entities authorized to access a user's data.
 *
 * 5. Governance & Community Features:
 *    - proposeReputationRuleChange(): Community can propose changes to reputation calculation rules.
 *    - voteOnRuleChangeProposal(): Token holders can vote on proposed rule changes.
 *    - getActiveReputationRules(): View the currently active reputation calculation rules.
 *
 * Function Summary:
 * - registerIdentity: Registers a new digital identity linked to the sender's address.
 * - updateProfile: Allows users to update their profile information stored on-chain.
 * - getProfile: Retrieves the profile information associated with a given identity.
 * - verifyIdentityClaim: Verifies a cryptographic claim made by a user about their identity.
 * - deactivateIdentity: Allows a user to deactivate their identity temporarily.
 * - endorseIdentity: Allows registered identities to endorse other identities for specific attributes.
 * - reportMisconduct: Allows users to report misconduct associated with an identity.
 * - getReputationScore: Calculates a reputation score for an identity based on endorsements and reports.
 * - stakeForReputation: Allows users to stake tokens to vouch for their own or others' reputation.
 * - disputeReputationReport: Enables users to dispute misconduct reports filed against them.
 * - issueCredential: Allows authorized issuers to issue verifiable credentials to identities.
 * - verifyCredential: Verifies the validity and issuer of a given credential.
 * - revokeCredential: Allows credential issuers to revoke previously issued credentials.
 * - requestCredential: Enables users to request specific credentials from authorized issuers.
 * - setProfileVisibility: Allows users to control the visibility of their profile information.
 * - grantDataAccess: Allows users to grant specific entities access to parts of their profile data.
 * - revokeDataAccess: Allows users to revoke previously granted data access.
 * - getAuthorizedEntities: Retrieves a list of entities authorized to access a user's data.
 * - proposeReputationRuleChange: Allows community members to propose changes to the reputation rules.
 * - voteOnRuleChangeProposal: Allows token holders to vote on proposed reputation rule changes.
 * - getActiveReputationRules: Retrieves the currently active reputation calculation rules.
 */
pragma solidity ^0.8.0;

contract DIDRepPlatform {

    // --- Structs ---
    struct Profile {
        string name;
        string bio;
        bool isVisible;
    }

    struct Credential {
        address issuer;
        string credentialType;
        string credentialData;
        uint256 issueTimestamp;
        bool isRevoked;
    }

    struct ReputationRuleProposal {
        string description;
        string newRuleDetails;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    struct Endorsement {
        address endorserIdentity;
        string attribute;
        uint256 timestamp;
    }

    struct MisconductReport {
        address reporterIdentity;
        string reportDetails;
        uint256 timestamp;
        bool isDisputed;
        address disputerIdentity;
        string disputeReason;
        uint256 disputeTimestamp;
    }


    // --- State Variables ---
    mapping(address => bool) public isIdentityRegistered; // Address to identity registration status
    mapping(address => Profile) public profiles; // Identity address to profile information
    mapping(address => mapping(string => Credential)) public credentials; // Identity address to credential type to credential details
    mapping(address => mapping(address => bool)) public dataAccessPermissions; // Identity to authorized entity to permission status
    mapping(address => mapping(address => Endorsement[])) public endorsements; // Identity to endorsed identity to list of endorsements
    mapping(address => MisconductReport[]) public misconductReports; // Identity to list of misconduct reports
    mapping(uint256 => ReputationRuleProposal) public ruleProposals; // Proposal ID to rule proposal details
    uint256 public nextProposalId = 0;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID to voter address to vote status
    address public platformOwner;
    uint256 public stakingAmountForReputation = 1 ether; // Example staking amount
    mapping(address => uint256) public stakedTokens; // Identity address to staked tokens
    string public currentReputationRules = "Default rules: Endorsements increase reputation, misconduct reports decrease it.";


    // --- Events ---
    event IdentityRegistered(address identityAddress);
    event ProfileUpdated(address identityAddress);
    event IdentityDeactivated(address identityAddress);
    event IdentityEndorsed(address identityAddress, address endorsedIdentity, string attribute);
    event MisconductReported(address identityAddress, address reporterIdentity, string reportDetails);
    event ReputationScoreUpdated(address identityAddress, uint256 reputationScore);
    event TokensStakedForReputation(address identityAddress, uint256 amount);
    event ReputationReportDisputed(address identityAddress, uint256 reportIndex, address disputerIdentity, string disputeReason);
    event CredentialIssued(address identityAddress, address issuer, string credentialType);
    event CredentialVerified(address identityAddress, string credentialType, bool isValid);
    event CredentialRevoked(address identityAddress, string credentialType);
    event DataVisibilitySet(address identityAddress, bool isVisible);
    event DataAccessGranted(address identityAddress, address authorizedEntity);
    event DataAccessRevoked(address identityAddress, address authorizedEntity);
    event RuleChangeProposed(uint256 proposalId, string description);
    event RuleChangeVoted(uint256 proposalId, address voter, bool vote);
    event RuleChangeActivated(uint256 proposalId, string newRules);


    // --- Modifiers ---
    modifier onlyRegisteredIdentity() {
        require(isIdentityRegistered[msg.sender], "Sender is not a registered identity.");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(ruleProposals[_proposalId].votingEndTime > block.timestamp && ruleProposals[_proposalId].isActive, "Invalid or inactive proposal ID.");
        _;
    }


    // --- Constructor ---
    constructor() {
        platformOwner = msg.sender;
    }


    // --- 1. Identity Management Functions ---

    /**
     * @dev Registers a new digital identity for the sender.
     * @notice Emits IdentityRegistered event.
     */
    function registerIdentity() public {
        require(!isIdentityRegistered[msg.sender], "Identity already registered for this address.");
        isIdentityRegistered[msg.sender] = true;
        profiles[msg.sender] = Profile({name: "", bio: "", isVisible: true}); // Initialize default profile
        emit IdentityRegistered(msg.sender);
    }

    /**
     * @dev Updates the profile information of the sender's identity.
     * @param _name The new name.
     * @param _bio The new bio.
     * @notice Emits ProfileUpdated event.
     */
    function updateProfile(string memory _name, string memory _bio) public onlyRegisteredIdentity {
        profiles[msg.sender].name = _name;
        profiles[msg.sender].bio = _bio;
        emit ProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves the profile information for a given identity address.
     * @param _identityAddress The address of the identity.
     * @return Profile struct containing the profile information.
     */
    function getProfile(address _identityAddress) public view returns (Profile memory) {
        require(isIdentityRegistered[_identityAddress], "Identity is not registered.");
        return profiles[_identityAddress];
    }

    /**
     * @dev Allows a user to cryptographically prove a claim about their identity (example - not fully implemented for brevity, concept only).
     * @param _claimType Type of claim (e.g., "age", "location").
     * @param _claimValue Value of the claim.
     * @param _signature Cryptographic signature proving the claim is from the identity owner (external verification needed).
     * @return bool True if the signature is valid (basic example - more robust verification needed in real-world).
     */
    function verifyIdentityClaim(string memory _claimType, string memory _claimValue, bytes memory _signature) public view onlyRegisteredIdentity returns (bool) {
        // In a real-world scenario, this would involve recovering the address from the signature and verifying it matches msg.sender.
        // This is a simplified example for conceptual illustration.
        (address recoveredAddress, ) = ecrecover(keccak256(abi.encode(_claimType, _claimValue)), _signature);
        return recoveredAddress == msg.sender; // Basic check - needs more robust signature verification in practice
    }

    /**
     * @dev Allows an identity to deactivate itself temporarily, hiding its profile and reputation.
     * @notice Emits IdentityDeactivated event.
     */
    function deactivateIdentity() public onlyRegisteredIdentity {
        isIdentityRegistered[msg.sender] = false; // Temporarily deactivate - can be reversed with a reactivation function if needed
        emit IdentityDeactivated(msg.sender);
    }


    // --- 2. Reputation System Functions ---

    /**
     * @dev Allows a registered identity to endorse another identity for a specific attribute.
     * @param _endorsedIdentity The identity to be endorsed.
     * @param _attribute The attribute for which the identity is being endorsed (e.g., "skilledProgrammer", "reliableTrader").
     * @notice Emits IdentityEndorsed event.
     */
    function endorseIdentity(address _endorsedIdentity, string memory _attribute) public onlyRegisteredIdentity {
        require(isIdentityRegistered[_endorsedIdentity], "Endorsed identity is not registered.");
        endorsements[_endorsedIdentity][msg.sender].push(Endorsement({
            endorserIdentity: msg.sender,
            attribute: _attribute,
            timestamp: block.timestamp
        }));
        emit IdentityEndorsed(msg.sender, _endorsedIdentity, _attribute);
        _updateReputationScore(_endorsedIdentity);
    }

    /**
     * @dev Allows a registered identity to report misconduct associated with another identity.
     * @param _reportedIdentity The identity being reported.
     * @param _reportDetails Details of the misconduct.
     * @notice Emits MisconductReported event.
     */
    function reportMisconduct(address _reportedIdentity, string memory _reportDetails) public onlyRegisteredIdentity {
        require(isIdentityRegistered[_reportedIdentity], "Reported identity is not registered.");
        misconductReports[_reportedIdentity].push(MisconductReport({
            reporterIdentity: msg.sender,
            reportDetails: _reportDetails,
            timestamp: block.timestamp,
            isDisputed: false,
            disputerIdentity: address(0),
            disputeReason: "",
            disputeTimestamp: 0
        }));
        emit MisconductReported(_reportedIdentity, msg.sender, _reportDetails);
        _updateReputationScore(_reportedIdentity);
    }

    /**
     * @dev Calculates and returns a reputation score for a given identity.
     * @param _identityAddress The identity address.
     * @return uint256 The reputation score.
     * @notice Emits ReputationScoreUpdated event.
     */
    function getReputationScore(address _identityAddress) public view returns (uint256) {
        require(isIdentityRegistered[_identityAddress], "Identity is not registered.");
        uint256 endorsementCount = 0;
        for (address endorser in endorsements[_identityAddress]) {
            endorsementCount += endorsements[_identityAddress][endorser].length;
        }
        uint256 reportCount = misconductReports[_identityAddress].length;
        uint256 reputationScore = endorsementCount * 10 - reportCount * 20; // Example scoring logic - can be customized
        return reputationScore;
    }

    /**
     * @dev Allows a user to stake tokens to vouch for their reputation or another identity's reputation.
     * @notice Emits TokensStakedForReputation event.
     */
    function stakeForReputation() public payable onlyRegisteredIdentity {
        require(msg.value >= stakingAmountForReputation, "Staking amount is insufficient.");
        stakedTokens[msg.sender] += msg.value;
        emit TokensStakedForReputation(msg.sender, msg.value);
        // In a real system, consider locking/releasing staked tokens and potentially using them for governance or rewards.
    }

    /**
     * @dev Allows an identity to dispute a misconduct report filed against them.
     * @param _reportIndex Index of the misconduct report in the misconductReports array.
     * @param _disputeReason Reason for disputing the report.
     * @notice Emits ReputationReportDisputed event.
     */
    function disputeReputationReport(uint256 _reportIndex, string memory _disputeReason) public onlyRegisteredIdentity {
        require(_reportIndex < misconductReports[msg.sender].length, "Invalid report index.");
        require(!misconductReports[msg.sender][_reportIndex].isDisputed, "Report already disputed.");
        misconductReports[msg.sender][_reportIndex].isDisputed = true;
        misconductReports[msg.sender][_reportIndex].disputerIdentity = msg.sender;
        misconductReports[msg.sender][_reportIndex].disputeReason = _disputeReason;
        misconductReports[msg.sender][_reportIndex].disputeTimestamp = block.timestamp;
        emit ReputationReportDisputed(msg.sender, _reportIndex, msg.sender, _disputeReason);
        // In a real system, consider adding a dispute resolution mechanism (e.g., community voting or moderation).
    }


    // --- 3. Credentialing & Attestation Functions ---

    /**
     * @dev Allows an authorized entity (e.g., issuer contract) to issue a verifiable credential to an identity.
     * @param _identityAddress The identity receiving the credential.
     * @param _credentialType Type of credential (e.g., "Degree", "Certification").
     * @param _credentialData Data associated with the credential (e.g., IPFS hash, JSON string).
     * @notice Emits CredentialIssued event.
     */
    function issueCredential(address _identityAddress, string memory _credentialType, string memory _credentialData) public onlyPlatformOwner { // Example: Only platform owner can issue, adjust as needed
        require(isIdentityRegistered[_identityAddress], "Recipient identity is not registered.");
        credentials[_identityAddress][_credentialType] = Credential({
            issuer: msg.sender,
            credentialType: _credentialType,
            credentialData: _credentialData,
            issueTimestamp: block.timestamp,
            isRevoked: false
        });
        emit CredentialIssued(_identityAddress, msg.sender, _credentialType);
    }

    /**
     * @dev Verifies the validity of a credential for a given identity and credential type.
     * @param _identityAddress The identity holding the credential.
     * @param _credentialType The type of credential to verify.
     * @return bool True if the credential is valid and not revoked.
     * @notice Emits CredentialVerified event.
     */
    function verifyCredential(address _identityAddress, string memory _credentialType) public view returns (bool) {
        require(isIdentityRegistered[_identityAddress], "Identity is not registered.");
        Credential memory cred = credentials[_identityAddress][_credentialType];
        bool isValid = (cred.issuer != address(0) && !cred.isRevoked);
        emit CredentialVerified(_identityAddress, _credentialType, isValid);
        return isValid;
    }

    /**
     * @dev Allows a credential issuer to revoke a previously issued credential.
     * @param _identityAddress The identity whose credential is being revoked.
     * @param _credentialType The type of credential to revoke.
     * @notice Emits CredentialRevoked event.
     */
    function revokeCredential(address _identityAddress, string memory _credentialType) public onlyPlatformOwner { // Example: Only platform owner can revoke, adjust issuer logic as needed
        require(isIdentityRegistered[_identityAddress], "Identity is not registered.");
        require(credentials[_identityAddress][_credentialType].issuer != address(0), "Credential does not exist.");
        credentials[_identityAddress][_credentialType].isRevoked = true;
        emit CredentialRevoked(_identityAddress, _credentialType);
    }

    /**
     * @dev Allows a user to request a specific credential from a designated issuer (example - can be expanded with request workflow).
     * @param _issuerAddress Address of the credential issuer.
     * @param _credentialType Type of credential being requested.
     */
    function requestCredential(address _issuerAddress, string memory _credentialType) public onlyRegisteredIdentity {
        // In a real system, this could trigger an off-chain process or another smart contract interaction
        // to handle the credential request workflow.
        // This is a placeholder function to demonstrate a potential feature.
        // For example, you might emit an event that an off-chain service listens to.
        // Or you could interact with another smart contract that manages credential requests.
        // For now, just emitting an event as a placeholder.
        emit CredentialRequestMade(msg.sender, _issuerAddress, _credentialType);
    }

    event CredentialRequestMade(address requesterIdentity, address issuerAddress, string credentialType);


    // --- 4. Data Privacy & Control Functions ---

    /**
     * @dev Allows a user to set the visibility of their profile information (public or private).
     * @param _isVisible True for public, false for private.
     * @notice Emits DataVisibilitySet event.
     */
    function setProfileVisibility(bool _isVisible) public onlyRegisteredIdentity {
        profiles[msg.sender].isVisible = _isVisible;
        emit DataVisibilitySet(msg.sender, _isVisible);
    }

    /**
     * @dev Allows a user to grant a specific entity (e.g., another identity, contract) access to their profile data.
     * @param _authorizedEntity The address of the entity being granted access.
     * @notice Emits DataAccessGranted event.
     */
    function grantDataAccess(address _authorizedEntity) public onlyRegisteredIdentity {
        dataAccessPermissions[msg.sender][_authorizedEntity] = true;
        emit DataAccessGranted(msg.sender, _authorizedEntity);
    }

    /**
     * @dev Allows a user to revoke data access previously granted to an entity.
     * @param _authorizedEntity The address of the entity whose access is being revoked.
     * @notice Emits DataAccessRevoked event.
     */
    function revokeDataAccess(address _authorizedEntity) public onlyRegisteredIdentity {
        dataAccessPermissions[msg.sender][_authorizedEntity] = false;
        emit DataAccessRevoked(msg.sender, _authorizedEntity);
    }

    /**
     * @dev Retrieves a list of entities authorized to access a user's data.
     * @param _identityAddress The identity whose authorized entities are being queried.
     * @return address[] Array of authorized entity addresses.
     */
    function getAuthorizedEntities(address _identityAddress) public view onlyRegisteredIdentity returns (address[] memory) {
        address[] memory authorizedEntities = new address[](0);
        uint256 index = 0;
        for (address entity in dataAccessPermissions[_identityAddress]) {
            if (dataAccessPermissions[_identityAddress][entity]) {
                authorizedEntities = _pushAddress(authorizedEntities, entity);
                index++;
            }
        }
        return authorizedEntities;
    }

    function _pushAddress(address[] memory _array, address _value) private pure returns (address[] memory) {
        address[] memory newArray = new address[](_array.length + 1);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _value;
        return newArray;
    }


    // --- 5. Governance & Community Features ---

    /**
     * @dev Allows any registered identity to propose a change to the reputation calculation rules.
     * @param _description Description of the proposed rule change.
     * @param _newRuleDetails Details of the new rules (e.g., JSON string, text description).
     * @param _votingDurationInSeconds Duration of the voting period in seconds.
     * @notice Emits RuleChangeProposed event.
     */
    function proposeReputationRuleChange(string memory _description, string memory _newRuleDetails, uint256 _votingDurationInSeconds) public onlyRegisteredIdentity {
        ruleProposals[nextProposalId] = ReputationRuleProposal({
            description: _description,
            newRuleDetails: _newRuleDetails,
            votingEndTime: block.timestamp + _votingDurationInSeconds,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit RuleChangeProposed(nextProposalId, _description);
        nextProposalId++;
    }

    /**
     * @dev Allows token holders to vote on a proposed reputation rule change.
     * @param _proposalId ID of the rule change proposal.
     * @param _vote True for 'for', false for 'against'.
     * @notice Emits RuleChangeVoted event.
     */
    function voteOnRuleChangeProposal(uint256 _proposalId, bool _vote) public onlyRegisteredIdentity validProposalId(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Address has already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            ruleProposals[_proposalId].votesFor++;
        } else {
            ruleProposals[_proposalId].votesAgainst++;
        }
        emit RuleChangeVoted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Retrieves the currently active reputation calculation rules.
     * @return string The current reputation rules.
     */
    function getActiveReputationRules() public view returns (string memory) {
        return currentReputationRules;
    }

    /**
     * @dev Platform owner can finalize a rule change proposal after voting ends and update the active rules.
     * @param _proposalId ID of the rule change proposal to finalize.
     * @notice Emits RuleChangeActivated event.
     */
    function finalizeRuleChangeProposal(uint256 _proposalId) public onlyPlatformOwner {
        require(ruleProposals[_proposalId].votingEndTime <= block.timestamp, "Voting is still active.");
        require(ruleProposals[_proposalId].isActive, "Proposal is not active.");
        ruleProposals[_proposalId].isActive = false; // Deactivate the proposal
        if (ruleProposals[_proposalId].votesFor > ruleProposals[_proposalId].votesAgainst) {
            currentReputationRules = ruleProposals[_proposalId].newRuleDetails; // Update rules if proposal passes (simple majority example)
            emit RuleChangeActivated(_proposalId, currentReputationRules);
        }
        // Else, proposal fails, and rules remain unchanged.
    }


    // --- Internal Helper Function ---
    function _updateReputationScore(address _identityAddress) private {
        uint256 newScore = getReputationScore(_identityAddress);
        emit ReputationScoreUpdated(_identityAddress, newScore);
    }
}
```