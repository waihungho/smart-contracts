This smart contract, named `EthoshereImpactProtocol`, aims to build a decentralized and verifiable reputation layer for positive real-world contributions, leveraging Soulbound Tokens (SBTs) and a DAO-governed funding mechanism.

The core idea is to allow individuals and organizations to earn non-transferable "Impact Credentials" (SBTs) by demonstrating provable positive impact. These credentials are issued based on data verified by decentralized oracles (which can conceptually integrate AI for nuanced analysis). Credential holders gain reputation and influence within the protocol's DAO, which governs a treasury for funding new impactful projects.

**Advanced Concepts & Features:**

1.  **Soulbound Tokens (SBTs) for Reputation:** Impact Credentials are non-transferable, creating a persistent and verifiable on-chain identity for pro-social actions.
2.  **Decentralized Oracle Integration (AI-Enhanced):** The protocol relies on trusted oracles to submit and verify real-world data, enabling objective assessment of impact. While AI processing would happen off-chain, the oracle acts as a bridge for its verifiable output.
3.  **Dynamic Reputation System:** Different types and tiers of Impact Credentials contribute to a participant's overall reputation score, influencing their governance power and funding access.
4.  **DAO-Governed Impact Funding:** A community of Impact Credential holders collectively decides which new projects to fund from the protocol's treasury, ensuring alignment with its mission.
5.  **Role-Based Access Control:** Differentiated roles (Owner, Oracle, Participant) ensure secure and structured interaction with the protocol.
6.  **Configurable Credential Types:** The protocol can define various categories of impact (e.g., environmental, social, technological), each with its own verification criteria.
7.  **Emergency Pause Mechanism:** A standard but critical feature for protocol security in unforeseen circumstances.

---

## Contract: `EthoshereImpactProtocol`

**Outline & Function Summary:**

This contract manages participant profiles, issues non-transferable Impact Credentials (SBTs), facilitates project proposals and voting, and controls a treasury for funding approved initiatives. It integrates with an external Oracle for data verification.

---

### **I. Core Identity & Credential Management**

1.  `registerParticipant(string memory _name, string memory _uri)`:
    *   **Description:** Allows a new participant to register an on-chain profile, creating a unique participant ID linked to their address.
    *   **Access:** Anyone.
2.  `getParticipantProfile(address _participant)`:
    *   **Description:** Retrieves the detailed profile information for a given participant address.
    *   **Access:** Anyone.
3.  `requestImpactCredential(address _participant, bytes32 _credentialTypeId, string memory _metadataURI, bytes32 _verificationHash)`:
    *   **Description:** A participant (or their delegate) can initiate a request for an Impact Credential of a specific type. It includes a URI for off-chain metadata and a hash for verification data.
    *   **Access:** Registered participant or delegate.
4.  `issueImpactCredential(address _participant, bytes32 _credentialRequestId, bytes32 _credentialTypeId, string memory _metadataURI, uint256 _score, uint256 _issuedAt)`:
    *   **Description:** The designated `trustedOracle` issues a new Impact Credential (SBT) to a participant, linking it to a specific request and assigning a score. This is the minting equivalent for SBTs.
    *   **Access:** `onlyOracle`.
5.  `getImpactCredential(bytes32 _credentialId)`:
    *   **Description:** Retrieves the details of a specific Impact Credential by its ID.
    *   **Access:** Anyone.
6.  `getParticipantCredentials(address _participant)`:
    *   **Description:** Returns a list of all Impact Credential IDs held by a specific participant.
    *   **Access:** Anyone.
7.  `revokeImpactCredential(address _participant, bytes32 _credentialId, string memory _reason)`:
    *   **Description:** Allows the `owner` or `trustedOracle` to revoke an Impact Credential, typically in cases of fraud or misinformation.
    *   **Access:** `onlyOwner` or `onlyOracle`.

### **II. Oracle & Verification System**

8.  `setTrustedOracle(address _newOracle)`:
    *   **Description:** Sets or updates the address of the single trusted oracle for the protocol.
    *   **Access:** `onlyOwner`.
9.  `getTrustedOracle()`:
    *   **Description:** Returns the address of the currently trusted oracle.
    *   **Access:** Anyone.
10. `submitVerificationResult(bytes32 _credentialRequestId, bool _isVerified, string memory _detailsHash)`:
    *   **Description:** The `trustedOracle` submits the outcome of a verification request for a pending Impact Credential.
    *   **Access:** `onlyOracle`.
11. `getCredentialRequest(bytes32 _requestId)`:
    *   **Description:** Retrieves the details and current status of a specific Impact Credential request.
    *   **Access:** Anyone.

### **III. Project Proposals & Funding DAO**

12. `submitImpactProjectProposal(string memory _title, string memory _descriptionURI, uint256 _requestedAmount)`:
    *   **Description:** Allows any registered participant with sufficient reputation (based on their Impact Credentials) to submit a project proposal for funding.
    *   **Access:** Registered participant with min reputation.
11. `voteOnProjectProposal(bytes32 _proposalId, bool _support)`:
    *   **Description:** Allows Impact Credential holders to cast their vote (for or against) on an active project proposal. Voting power is weighted by accumulated impact score.
    *   **Access:** Registered participant with Impact Credentials.
12. `finalizeProjectProposal(bytes32 _proposalId)`:
    *   **Description:** Triggers the finalization of a proposal after its voting period ends, determining if it passes or fails based on votes and thresholds.
    *   **Access:** Anyone (after voting period).
13. `fundApprovedProject(bytes32 _proposalId)`:
    *   **Description:** Transfers the requested amount from the protocol's treasury to the project's designated recipient address if the proposal was approved and funds are available.
    *   **Access:** `onlyOwner` (or can be automated upon finalization).
14. `getProjectProposal(bytes32 _proposalId)`:
    *   **Description:** Retrieves the full details and current status of a project proposal.
    *   **Access:** Anyone.
15. `getProposalVoteCount(bytes32 _proposalId)`:
    *   **Description:** Returns the current cumulative 'for' and 'against' vote weight for a proposal.
    *   **Access:** Anyone.

### **IV. Treasury & Protocol Governance**

16. `depositFunds()`:
    *   **Description:** Allows anyone to deposit native currency (e.g., ETH) into the protocol's treasury, increasing funds available for projects.
    *   **Access:** Anyone (`payable`).
17. `getTreasuryBalance()`:
    *   **Description:** Returns the current balance of the protocol's treasury.
    *   **Access:** Anyone.
18. `setProposalVotingPeriod(uint256 _newPeriod)`:
    *   **Description:** Sets the duration for which project proposals are open for voting.
    *   **Access:** `onlyOwner`.
19. `setMinimumReputationForProposal(uint256 _minScore)`:
    *   **Description:** Defines the minimum aggregated impact score a participant needs to submit a project proposal.
    *   **Access:** `onlyOwner`.

### **V. Utility & Configuration**

20. `addCredentialType(bytes32 _typeId, string memory _name, string memory _description, uint256 _baseScore)`:
    *   **Description:** Allows the owner to define new categories or types of Impact Credentials, each with a base score and description.
    *   **Access:** `onlyOwner`.
21. `getCredentialType(bytes32 _typeId)`:
    *   **Description:** Retrieves the configuration details for a specific credential type.
    *   **Access:** Anyone.
22. `pauseContract()`:
    *   **Description:** An emergency function to pause critical operations of the contract in case of vulnerabilities or unexpected issues.
    *   **Access:** `onlyOwner`.
23. `unpauseContract()`:
    *   **Description:** Unpauses the contract, re-enabling critical operations.
    *   **Access:** `onlyOwner`.
24. `updateParticipantURI(address _participant, string memory _newURI)`:
    *   **Description:** Allows a participant to update their profile metadata URI.
    *   **Access:** `onlyParticipant`.
25. `calculateParticipantReputation(address _participant)`:
    *   **Description:** An internal/external view function to calculate the aggregate impact score (reputation) for a participant based on their issued credentials.
    *   **Access:** Anyone (view).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title EthoshereImpactProtocol
 * @dev A decentralized protocol for issuing verifiable "Impact Credentials" (Soulbound Tokens) based on
 * real-world positive contributions, facilitated by decentralized oracles, and managing a
 * community-governed treasury for funding impactful projects. It aims to create a reputation layer
 * for pro-social actions.
 *
 * Advanced Concepts & Features:
 * 1. Soulbound Tokens (SBTs) for Reputation: Impact Credentials are non-transferable, creating a
 *    persistent and verifiable on-chain identity for pro-social actions.
 * 2. Decentralized Oracle Integration (AI-Enhanced): The protocol relies on trusted oracles to
 *    submit and verify real-world data, enabling objective assessment of impact. While AI
 *    processing would happen off-chain, the oracle acts as a bridge for its verifiable output.
 * 3. Dynamic Reputation System: Different types and tiers of Impact Credentials contribute to a
 *    participant's overall reputation score, influencing their governance power and funding access.
 * 4. DAO-Governed Impact Funding: A community of Impact Credential holders collectively decides
 *    which new projects to fund from the protocol's treasury, ensuring alignment with its mission.
 * 5. Role-Based Access Control: Differentiated roles (Owner, Oracle, Participant) ensure secure
 *    and structured interaction with the protocol.
 * 6. Configurable Credential Types: The protocol can define various categories of impact (e.g.,
 *    environmental, social, technological), each with its own verification criteria.
 * 7. Emergency Pause Mechanism: A standard but critical feature for protocol security.
 */
contract EthoshereImpactProtocol is Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---
    address public trustedOracle;
    uint256 public proposalVotingPeriod; // Duration in seconds
    uint256 public minimumReputationForProposal; // Minimum aggregated impact score to propose
    uint256 public proposalQuorumThreshold; // Percentage of total reputation needed to pass (e.g., 5000 for 50%)

    // --- Structs ---

    struct Participant {
        address walletAddress;
        string name;
        string metadataURI; // URI to off-chain profile data (e.g., IPFS)
        bool registered;
        uint256 totalImpactScore; // Aggregated score from all issued credentials
        bytes32[] issuedCredentials; // List of credential IDs held by this participant
    }

    struct CredentialType {
        bytes32 typeId;
        string name;
        string description;
        uint256 baseScore; // Base score for this type of credential
        bool isActive;
    }

    enum CredentialRequestStatus { Pending, Verified, Rejected, Issued }

    struct ImpactCredentialRequest {
        bytes32 requestId;
        address participant;
        bytes32 credentialTypeId;
        string metadataURI; // URI to off-chain data relevant to this request
        bytes32 verificationHash; // Hash of external data to be verified by oracle
        CredentialRequestStatus status;
        uint256 requestedAt;
        uint256 verifiedAt;
    }

    struct ImpactCredential {
        bytes32 credentialId;
        bytes32 requestId; // Link to the request that led to this credential
        address ownerAddress; // The address this SBT is bound to
        bytes32 credentialTypeId;
        string metadataURI; // URI to off-chain data for this credential
        uint256 score;
        uint256 issuedAt;
        bool revoked;
    }

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct ProjectProposal {
        bytes32 proposalId;
        address proposer;
        string title;
        string descriptionURI; // URI to detailed project description
        uint256 requestedAmount;
        uint256 startVoteTime;
        uint256 endVoteTime;
        uint256 ForVotes;    // Total impact score weighted votes for
        uint256 AgainstVotes; // Total impact score weighted votes against
        ProposalStatus status;
        address recipientAddress; // Address to send funds if approved
        bool executed; // True if funds have been sent
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- Mappings ---
    mapping(address => Participant) public participants;
    mapping(address => bool) public isParticipantRegistered;
    mapping(bytes32 => CredentialType) public credentialTypes;
    mapping(bytes32 => ImpactCredentialRequest) public credentialRequests;
    mapping(bytes32 => ImpactCredential) public impactCredentials;
    mapping(bytes32 => ProjectProposal) public projectProposals;
    uint256 public nextCredentialRequestId = 1; // Counter for unique credential request IDs
    uint256 public nextCredentialId = 1;      // Counter for unique credential IDs
    uint256 public nextProposalId = 1;        // Counter for unique proposal IDs

    // --- Events ---
    event ParticipantRegistered(address indexed participant, string name, string metadataURI);
    event ParticipantProfileUpdated(address indexed participant, string newMetadataURI);
    event CredentialTypeAdded(bytes32 indexed typeId, string name);
    event ImpactCredentialRequestSubmitted(bytes32 indexed requestId, address indexed participant, bytes32 indexed credentialTypeId, bytes32 verificationHash);
    event VerificationResultSubmitted(bytes32 indexed requestId, bool isVerified, string detailsHash);
    event ImpactCredentialIssued(bytes32 indexed credentialId, address indexed owner, bytes32 indexed credentialTypeId, uint256 score);
    event ImpactCredentialRevoked(bytes32 indexed credentialId, address indexed owner, string reason);
    event OracleUpdated(address indexed newOracle);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProjectProposalSubmitted(bytes32 indexed proposalId, address indexed proposer, uint256 requestedAmount);
    event ProjectVoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProjectProposalFinalized(bytes32 indexed proposalId, ProposalStatus status);
    event ProjectFunded(bytes32 indexed proposalId, address indexed recipient, uint256 amount);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);

    // --- Modifiers ---
    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "Ethoshere: Not the trusted oracle");
        _;
    }

    modifier onlyParticipant(address _participant) {
        require(msg.sender == _participant, "Ethoshere: Not the participant");
        _;
    }

    modifier onlyRegisteredParticipant() {
        require(participants[msg.sender].registered, "Ethoshere: Caller not a registered participant");
        _;
    }

    // --- Constructor ---
    constructor(address initialOracle) Ownable(msg.sender) {
        require(initialOracle != address(0), "Ethoshere: Initial oracle cannot be zero address");
        trustedOracle = initialOracle;
        proposalVotingPeriod = 7 days; // Default 7 days
        minimumReputationForProposal = 100; // Default minimum score for proposals
        proposalQuorumThreshold = 5000; // Default 50%
        emit OracleUpdated(initialOracle);
    }

    // --- I. Core Identity & Credential Management ---

    /**
     * @dev Allows a new participant to register an on-chain profile.
     * @param _name The display name of the participant.
     * @param _uri URI to off-chain metadata (e.g., IPFS) for the participant's profile.
     */
    function registerParticipant(string memory _name, string memory _uri) public whenNotPaused {
        require(!participants[msg.sender].registered, "Ethoshere: Participant already registered");
        require(bytes(_name).length > 0, "Ethoshere: Name cannot be empty");

        participants[msg.sender] = Participant({
            walletAddress: msg.sender,
            name: _name,
            metadataURI: _uri,
            registered: true,
            totalImpactScore: 0,
            issuedCredentials: new bytes32[](0)
        });
        isParticipantRegistered[msg.sender] = true;
        emit ParticipantRegistered(msg.sender, _name, _uri);
    }

    /**
     * @dev Retrieves the detailed profile information for a given participant address.
     * @param _participant The address of the participant.
     * @return Participant struct details.
     */
    function getParticipantProfile(address _participant) public view returns (Participant memory) {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        return participants[_participant];
    }

    /**
     * @dev Allows a participant to update their profile metadata URI.
     * @param _newURI The new URI for the participant's profile metadata.
     */
    function updateParticipantURI(address _participant, string memory _newURI) public onlyParticipant(_participant) whenNotPaused {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        participants[_participant].metadataURI = _newURI;
        emit ParticipantProfileUpdated(_participant, _newURI);
    }

    /**
     * @dev Allows a participant (or their delegate if implemented) to initiate a request for an Impact Credential.
     * @param _participant The address of the participant requesting the credential.
     * @param _credentialTypeId The ID of the desired credential type.
     * @param _metadataURI URI to off-chain data relevant to this specific credential request.
     * @param _verificationHash Hash of external data (e.g., proof of work, report) that the oracle will verify.
     */
    function requestImpactCredential(
        address _participant,
        bytes32 _credentialTypeId,
        string memory _metadataURI,
        bytes32 _verificationHash
    ) public whenNotPaused {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        require(credentialTypes[_credentialTypeId].isActive, "Ethoshere: Invalid or inactive credential type");
        require(bytes(_metadataURI).length > 0, "Ethoshere: Metadata URI cannot be empty");
        require(_verificationHash != bytes32(0), "Ethoshere: Verification hash cannot be zero");

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _participant, _credentialTypeId, nextCredentialRequestId++));

        credentialRequests[requestId] = ImpactCredentialRequest({
            requestId: requestId,
            participant: _participant,
            credentialTypeId: _credentialTypeId,
            metadataURI: _metadataURI,
            verificationHash: _verificationHash,
            status: CredentialRequestStatus.Pending,
            requestedAt: block.timestamp,
            verifiedAt: 0
        });

        emit ImpactCredentialRequestSubmitted(requestId, _participant, _credentialTypeId, _verificationHash);
    }

    /**
     * @dev The designated trustedOracle issues a new Impact Credential (SBT) to a participant.
     * This is the "minting" equivalent for non-transferable SBTs.
     * @param _participant The address to issue the credential to.
     * @param _credentialRequestId The ID of the request associated with this issuance.
     * @param _credentialTypeId The ID of the credential type being issued.
     * @param _metadataURI URI to off-chain data for this credential.
     * @param _score The specific score for this credential (can override baseScore or be dynamic).
     * @param _issuedAt The timestamp when the credential was issued.
     */
    function issueImpactCredential(
        address _participant,
        bytes32 _credentialRequestId,
        bytes32 _credentialTypeId,
        string memory _metadataURI,
        uint256 _score,
        uint256 _issuedAt
    ) public onlyOracle whenNotPaused {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        require(credentialTypes[_credentialTypeId].isActive, "Ethoshere: Invalid or inactive credential type");
        require(_score > 0, "Ethoshere: Credential score must be positive");
        require(credentialRequests[_credentialRequestId].status == CredentialRequestStatus.Verified, "Ethoshere: Request not verified");
        require(credentialRequests[_credentialRequestId].participant == _participant, "Ethoshere: Request participant mismatch");
        require(credentialRequests[_credentialRequestId].credentialTypeId == _credentialTypeId, "Ethoshere: Request credential type mismatch");

        bytes32 credentialId = keccak256(abi.encodePacked(block.timestamp, _participant, _credentialTypeId, nextCredentialId++));

        impactCredentials[credentialId] = ImpactCredential({
            credentialId: credentialId,
            requestId: _credentialRequestId,
            ownerAddress: _participant,
            credentialTypeId: _credentialTypeId,
            metadataURI: _metadataURI,
            score: _score,
            issuedAt: _issuedAt,
            revoked: false
        });

        participants[_participant].issuedCredentials.push(credentialId);
        participants[_participant].totalImpactScore = participants[_participant].totalImpactScore.add(_score);

        credentialRequests[_credentialRequestId].status = CredentialRequestStatus.Issued;

        emit ImpactCredentialIssued(credentialId, _participant, _credentialTypeId, _score);
    }

    /**
     * @dev Retrieves the details of a specific Impact Credential by its ID.
     * @param _credentialId The ID of the credential.
     * @return ImpactCredential struct details.
     */
    function getImpactCredential(bytes32 _credentialId) public view returns (ImpactCredential memory) {
        require(impactCredentials[_credentialId].ownerAddress != address(0), "Ethoshere: Credential not found");
        return impactCredentials[_credentialId];
    }

    /**
     * @dev Returns a list of all Impact Credential IDs held by a specific participant.
     * @param _participant The address of the participant.
     * @return An array of credential IDs.
     */
    function getParticipantCredentials(address _participant) public view returns (bytes32[] memory) {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        return participants[_participant].issuedCredentials;
    }

    /**
     * @dev Allows the owner or trustedOracle to revoke an Impact Credential, typically in cases of fraud.
     * @param _participant The address of the credential owner.
     * @param _credentialId The ID of the credential to revoke.
     * @param _reason A string explaining the reason for revocation.
     */
    function revokeImpactCredential(address _participant, bytes32 _credentialId, string memory _reason) public whenNotPaused {
        require(msg.sender == owner() || msg.sender == trustedOracle, "Ethoshere: Only owner or oracle can revoke");
        require(impactCredentials[_credentialId].ownerAddress == _participant, "Ethoshere: Credential owner mismatch");
        require(!impactCredentials[_credentialId].revoked, "Ethoshere: Credential already revoked");

        impactCredentials[_credentialId].revoked = true;
        // Optionally adjust participant's total impact score. For simplicity, we'll keep the history.
        // If score adjustment is desired:
        // participants[_participant].totalImpactScore = participants[_participant].totalImpactScore.sub(impactCredentials[_credentialId].score);

        emit ImpactCredentialRevoked(_credentialId, _participant, _reason);
    }

    // --- II. Oracle & Verification System ---

    /**
     * @dev Sets or updates the address of the single trusted oracle for the protocol.
     * @param _newOracle The address of the new trusted oracle.
     */
    function setTrustedOracle(address _newOracle) public onlyOwner whenNotPaused {
        require(_newOracle != address(0), "Ethoshere: Oracle address cannot be zero");
        trustedOracle = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    /**
     * @dev Returns the address of the currently trusted oracle.
     * @return The address of the trusted oracle.
     */
    function getTrustedOracle() public view returns (address) {
        return trustedOracle;
    }

    /**
     * @dev The trustedOracle submits the outcome of a verification request for a pending Impact Credential.
     * @param _requestId The ID of the credential request being verified.
     * @param _isVerified True if the verification passed, false otherwise.
     * @param _detailsHash A hash linking to off-chain verification details (e.g., IPFS).
     */
    function submitVerificationResult(bytes32 _requestId, bool _isVerified, string memory _detailsHash) public onlyOracle whenNotPaused {
        ImpactCredentialRequest storage request = credentialRequests[_requestId];
        require(request.participant != address(0), "Ethoshere: Request not found");
        require(request.status == CredentialRequestStatus.Pending, "Ethoshere: Request already verified or issued");

        request.status = _isVerified ? CredentialRequestStatus.Verified : CredentialRequestStatus.Rejected;
        request.verifiedAt = block.timestamp;
        // Optionally store _detailsHash in the request struct if needed.

        emit VerificationResultSubmitted(_requestId, _isVerified, _detailsHash);
    }

    /**
     * @dev Retrieves the details and current status of a specific Impact Credential request.
     * @param _requestId The ID of the request.
     * @return ImpactCredentialRequest struct details.
     */
    function getCredentialRequest(bytes32 _requestId) public view returns (ImpactCredentialRequest memory) {
        require(credentialRequests[_requestId].participant != address(0), "Ethoshere: Request not found");
        return credentialRequests[_requestId];
    }

    // --- III. Project Proposals & Funding DAO ---

    /**
     * @dev Allows any registered participant with sufficient reputation to submit a project proposal for funding.
     * @param _title The title of the project.
     * @param _descriptionURI URI to detailed off-chain project description (e.g., IPFS).
     * @param _requestedAmount The amount of native currency requested for the project.
     */
    function submitImpactProjectProposal(
        string memory _title,
        string memory _descriptionURI,
        uint256 _requestedAmount
    ) public onlyRegisteredParticipant whenNotPaused {
        require(bytes(_title).length > 0, "Ethoshere: Project title cannot be empty");
        require(bytes(_descriptionURI).length > 0, "Ethoshere: Project description URI cannot be empty");
        require(_requestedAmount > 0, "Ethoshere: Requested amount must be positive");
        require(participants[msg.sender].totalImpactScore >= minimumReputationForProposal, "Ethoshere: Insufficient reputation to propose");

        bytes32 proposalId = keccak256(abi.encodePacked(block.timestamp, msg.sender, nextProposalId++));

        projectProposals[proposalId].proposalId = proposalId;
        projectProposals[proposalId].proposer = msg.sender;
        projectProposals[proposalId].title = _title;
        projectProposals[proposalId].descriptionURI = _descriptionURI;
        projectProposals[proposalId].requestedAmount = _requestedAmount;
        projectProposals[proposalId].startVoteTime = block.timestamp;
        projectProposals[proposalId].endVoteTime = block.timestamp.add(proposalVotingPeriod);
        projectProposals[proposalId].status = ProposalStatus.Active;
        // The recipient address could be the proposer's address or a specified address in the proposal.
        // For simplicity, let's assume it's the proposer's address.
        projectProposals[proposalId].recipientAddress = msg.sender;

        emit ProjectProposalSubmitted(proposalId, msg.sender, _requestedAmount);
    }

    /**
     * @dev Allows Impact Credential holders to cast their vote (for or against) on an active project proposal.
     * Voting power is weighted by accumulated impact score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProjectProposal(bytes32 _proposalId, bool _support) public onlyRegisteredParticipant whenNotPaused {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer != address(0), "Ethoshere: Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Ethoshere: Proposal not in active voting period");
        require(block.timestamp >= proposal.startVoteTime, "Ethoshere: Voting has not started");
        require(block.timestamp < proposal.endVoteTime, "Ethoshere: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Ethoshere: Already voted on this proposal");

        uint256 voteWeight = participants[msg.sender].totalImpactScore;
        require(voteWeight > 0, "Ethoshere: Participant has no impact score to vote");

        if (_support) {
            proposal.ForVotes = proposal.ForVotes.add(voteWeight);
        } else {
            proposal.AgainstVotes = proposal.AgainstVotes.add(voteWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProjectVoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Triggers the finalization of a proposal after its voting period ends,
     * determining if it passes or fails based on votes and thresholds.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProjectProposal(bytes32 _proposalId) public whenNotPaused {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer != address(0), "Ethoshere: Proposal not found");
        require(proposal.status == ProposalStatus.Active, "Ethoshere: Proposal not active");
        require(block.timestamp >= proposal.endVoteTime, "Ethoshere: Voting period not ended yet");

        uint256 totalVotes = proposal.ForVotes.add(proposal.AgainstVotes);
        require(totalVotes > 0, "Ethoshere: No votes cast on this proposal");

        if (proposal.ForVotes > proposal.AgainstVotes &&
            proposal.ForVotes.mul(10000).div(totalVotes) >= proposalQuorumThreshold) { // Quorum check
            proposal.status = ProposalStatus.Succeeded;
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        emit ProjectProposalFinalized(_proposalId, proposal.status);
    }

    /**
     * @dev Transfers the requested amount from the protocol's treasury to the project's
     * designated recipient address if the proposal was approved and funds are available.
     * @param _proposalId The ID of the approved proposal.
     */
    function fundApprovedProject(bytes32 _proposalId) public onlyOwner whenNotPaused {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer != address(0), "Ethoshere: Proposal not found");
        require(proposal.status == ProposalStatus.Succeeded, "Ethoshere: Proposal not succeeded");
        require(!proposal.executed, "Ethoshere: Project already funded");
        require(address(this).balance >= proposal.requestedAmount, "Ethoshere: Insufficient treasury balance");
        require(proposal.recipientAddress != address(0), "Ethoshere: Recipient address not set");

        (bool success, ) = payable(proposal.recipientAddress).call{value: proposal.requestedAmount}("");
        require(success, "Ethoshere: Failed to send funds");

        proposal.executed = true;
        proposal.status = ProposalStatus.Executed;
        emit ProjectFunded(_proposalId, proposal.recipientAddress, proposal.requestedAmount);
    }

    /**
     * @dev Retrieves the full details and current status of a project proposal.
     * @param _proposalId The ID of the proposal.
     * @return ProjectProposal struct details.
     */
    function getProjectProposal(bytes32 _proposalId) public view returns (ProjectProposal memory) {
        require(projectProposals[_proposalId].proposer != address(0), "Ethoshere: Proposal not found");
        return projectProposals[_proposalId];
    }

    /**
     * @dev Returns the current cumulative 'for' and 'against' vote weight for a proposal.
     * @param _proposalId The ID of the proposal.
     * @return ForVotes and AgainstVotes.
     */
    function getProposalVoteCount(bytes32 _proposalId) public view returns (uint256 ForVotes, uint256 AgainstVotes) {
        ProjectProposal storage proposal = projectProposals[_proposalId];
        require(proposal.proposer != address(0), "Ethoshere: Proposal not found");
        return (proposal.ForVotes, proposal.AgainstVotes);
    }

    // --- IV. Treasury & Protocol Governance ---

    /**
     * @dev Allows anyone to deposit native currency (e.g., ETH) into the protocol's treasury.
     */
    function depositFunds() public payable whenNotPaused {
        require(msg.value > 0, "Ethoshere: Deposit amount must be greater than zero");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Returns the current balance of the protocol's treasury.
     * @return The treasury balance in native currency.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Sets the duration for which project proposals are open for voting.
     * @param _newPeriod The new voting period in seconds.
     */
    function setProposalVotingPeriod(uint256 _newPeriod) public onlyOwner whenNotPaused {
        require(_newPeriod > 0, "Ethoshere: Voting period must be positive");
        proposalVotingPeriod = _newPeriod;
    }

    /**
     * @dev Defines the minimum aggregated impact score a participant needs to submit a project proposal.
     * @param _minScore The new minimum reputation score.
     */
    function setMinimumReputationForProposal(uint256 _minScore) public onlyOwner whenNotPaused {
        minimumReputationForProposal = _minScore;
    }

    /**
     * @dev Sets the percentage of total votes needed for a proposal to pass (quorum).
     * @param _threshold Percentage * 100 (e.g., 5000 for 50%).
     */
    function setProposalQuorumThreshold(uint256 _threshold) public onlyOwner whenNotPaused {
        require(_threshold <= 10000, "Ethoshere: Quorum threshold cannot exceed 100%");
        proposalQuorumThreshold = _threshold;
    }

    // --- V. Utility & Configuration ---

    /**
     * @dev Allows the owner to define new categories or types of Impact Credentials.
     * @param _typeId A unique ID for the new credential type.
     * @param _name The name of the credential type (e.g., "Environmental Steward").
     * @param _description A description of what this credential represents.
     * @param _baseScore The default score associated with this credential type.
     */
    function addCredentialType(
        bytes32 _typeId,
        string memory _name,
        string memory _description,
        uint256 _baseScore
    ) public onlyOwner whenNotPaused {
        require(!credentialTypes[_typeId].isActive, "Ethoshere: Credential type already exists");
        require(bytes(_name).length > 0, "Ethoshere: Name cannot be empty");
        require(_baseScore > 0, "Ethoshere: Base score must be positive");

        credentialTypes[_typeId] = CredentialType({
            typeId: _typeId,
            name: _name,
            description: _description,
            baseScore: _baseScore,
            isActive: true
        });
        emit CredentialTypeAdded(_typeId, _name);
    }

    /**
     * @dev Retrieves the configuration details for a specific credential type.
     * @param _typeId The ID of the credential type.
     * @return CredentialType struct details.
     */
    function getCredentialType(bytes32 _typeId) public view returns (CredentialType memory) {
        require(credentialTypes[_typeId].isActive, "Ethoshere: Credential type not found or inactive");
        return credentialTypes[_typeId];
    }

    /**
     * @dev An emergency function to pause critical operations of the contract.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, re-enabling critical operations.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Internal/external view function to calculate the aggregate impact score (reputation) for a participant.
     * This is already maintained in the Participant struct, but this provides a dedicated getter.
     * @param _participant The address of the participant.
     * @return The total aggregated impact score.
     */
    function calculateParticipantReputation(address _participant) public view returns (uint256) {
        require(participants[_participant].registered, "Ethoshere: Participant not registered");
        return participants[_participant].totalImpactScore;
    }
}
```