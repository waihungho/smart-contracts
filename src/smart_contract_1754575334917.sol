The `CognitoVeritasProtocol` is a decentralized protocol designed to bring transparency and verifiability to claims made about AI models and their training data. It aims to establish a "truth layer" on the blockchain for critical AI properties such as ethical compliance, bias, and data integrity. By leveraging advanced concepts like Zero-Knowledge Proof (ZKP) verification, Soulbound Tokens (SBTs) for reputation and certification, and a robust claim-challenge system, it seeks to build trust and accountability in the AI ecosystem.

## Contract: `CognitoVeritasProtocol`

### Purpose & Core Principles:
The protocol allows AI model providers, data curators, and auditors to submit claims (e.g., "This AI model has less than 0.01% gender bias on dataset X," or "This dataset contains no PII"), back them with a stake, and optionally provide ZK-proofs for privacy-preserving verification. Other participants can challenge these claims, initiating a dispute resolution process where reputation and economic incentives drive truthful outcomes. Verified claims can lead to the issuance of non-transferable Soulbound Tokens, acting as on-chain certifications for ethical AI practices.

### Advanced Concepts Integrated:
1.  **On-chain ZK-Proof Verification (Conceptual):** The contract provides the framework to submit and verify zero-knowledge proofs. This allows for privacy-preserving attestations about complex AI model characteristics (e.g., proving unbiasedness without revealing proprietary model weights or sensitive training data). It assumes the availability of an efficient ZKP verifier (e.g., a precompiled contract or a highly optimized Solidity library) for real-world application.
2.  **Soulbound Tokens (SBTs):** Implemented as non-transferable tokens for reputation tracking (`VeritasReputationSBT`) and ethical compliance certifications (`EthicalAIComplianceSBT`). These SBTs bind reputation and verifiable achievements directly to an address, preventing their transfer or sale and fostering a merit-based system.
3.  **Decentralized Claim-Challenge System:** A sophisticated mechanism for submitting, backing with financial stakes, challenging, and resolving claims. It uses economic incentives (initial bonds, slashing, rewards) to align participant behavior with honesty, deterring false claims and frivolous challenges.
4.  **Dynamic On-chain Attestations:** Claims are not static. Their status can evolve from `Pending` to `Verified`, `Challenged`, or `Overturned` based on verification outcomes and dispute resolutions, creating a living, auditable ledger of AI properties.
5.  **Role-Based Access Control & Governance:** Critical protocol roles (Auditors, Dispute Resolvers) are managed, and key protocol parameters are configurable by the protocol owner (which could be a DAO in a full production setup), ensuring controlled evolution and emergency response capabilities.

### Disclaimer:
Actual on-chain ZKP verification for complex proofs is extremely gas-intensive and typically requires highly specialized precompiles or libraries (e.g., for specific SNARK/STARK systems) not natively available or efficient in standard EVM opcodes. This contract provides the *interface* and *logic flow* for such a system, assuming the underlying ZKP verification capabilities are either external (off-chain verification with on-chain attestation) or integrated via a highly optimized solution.

---

### OUTLINE:

1.  **Constants & Immutables:** Fixed protocol parameters and owner.
2.  **Custom Errors:** Specific error messages for failed operations.
3.  **Events:** Logged actions for transparency and off-chain monitoring.
4.  **Enums:** State definitions for claims, challenges, and SBT types.
5.  **Structs:** Data structures for `Claim`, `Challenge`, `ZKPVerificationRequest`, and `SoulboundToken`.
6.  **Core State Variables:** Mappings and counters for tracking claims, challenges, ZKP requests, SBTs, roles, and reputation.
7.  **Constructor:** Initializes the contract with basic parameters.
8.  **Modifiers:** Access control and state-checking modifiers.
9.  **I. Claim Management Functions:** For submitting, tracking, and retrieving AI model and dataset claims.
10. **II. Verification & ZK-Proof Integration Functions:** For handling ZKP submissions and their on-chain verification.
11. **III. Challenge & Dispute Resolution Functions:** For the claim challenging process, staking, and resolution.
12. **IV. Reputation & Soulbound Tokens (SBTs) Functions:** For managing participant reputation and issuing non-transferable certifications.
13. **V. Role Management & Protocol Configuration Functions:** Admin functions for protocol governance and parameter adjustments.
14. **Internal/Helper Functions:** Utility functions for internal logic, such as ETH transfers and bond distribution.

---

### FUNCTION SUMMARY (25 Functions):

#### I. Claim Management Functions:
1.  `submitAICoherenceClaim(string memory _claimDescriptionURI, bytes32 _modelId, bytes32 _claimHash)`:
    *   Allows an entity to submit a claim about an AI model's behavior or properties (e.g., bias, fairness). Requires an ETH bond.
2.  `submitDatasetIntegrityClaim(string memory _claimDescriptionURI, bytes32 _datasetId, bytes32 _claimHash)`:
    *   Allows an entity to submit a claim about a dataset's integrity or characteristics (e.g., PII absence, data quality). Requires an ETH bond.
3.  `revokeClaim(bytes32 _claimId)`:
    *   Allows the original claimer to revoke their claim if it has not yet been verified or challenged, returning their initial bond.
4.  `getClaimDetails(bytes32 _claimId)`:
    *   Retrieves all stored details for a specific claim by its unique ID.
5.  `listClaimsForEntity(bytes32 _entityId)`:
    *   Returns an array of all claim IDs associated with a given AI model or dataset ID.

#### II. Verification & ZK-Proof Integration Functions:
6.  `requestZKPVerification(bytes32 _claimId, bytes memory _proof, bytes memory _publicInputs)`:
    *   Initiates a request for ZKP verification for a specific claim, submitting the proof and public inputs. This is the first step, signaling intent for verification.
7.  `verifyZKPForClaim(bytes32 _claimId, bytes memory _proof, bytes memory _publicInputs)`:
    *   **(Advanced/Conceptual)** Allows a designated `Auditor` to attempt direct on-chain verification of a ZKP for a claim. If successful, the claim's status is updated to `Verified`. This function assumes an underlying ZKP precompile or robust library for actual verification.
8.  `confirmZKPVerificationOutcome(bytes32 _requestId, bool _isVerified, address _verifier)`:
    *   Allows a designated `Auditor` (or an integrated Oracle) to confirm the outcome of an off-chain ZKP verification request, updating the claim's status accordingly.

#### III. Challenge & Dispute Resolution Functions:
9.  `challengeClaim(bytes32 _claimId, string memory _challengeReasonURI)`:
    *   Enables any participant to challenge a submitted claim by staking a bond. Claims can be challenged if `Pending` (within a challenge window) or `Verified`.
10. `supportClaim(bytes32 _claimId)`:
    *   Allows participants to stake additional tokens to support a claim, bolstering its defense against a challenge.
11. `supportChallenge(bytes32 _challengeId)`:
    *   Allows participants to stake additional tokens to support a challenge, strengthening its case against a claim.
12. `resolveChallengeVote(bytes32 _challengeId, bool _claimStands)`:
    *   **(Dispute Resolvers Only)** Finalizes a challenge, determining if the claim is upheld (`_claimStands = true`) or overturned (`_claimStands = false`). This function manages the distribution of staked bonds (rewards/slashing) and updates participant reputations.
13. `reclaimBond(bytes32 _claimIdOrChallengeId)`:
    *   Allows participants to reclaim their initial staked bond after a claim or challenge has been fully resolved and the funds are available for withdrawal (simplified; in a full system, this would be per-stake).
14. `appealResolution(bytes32 _challengeId)`:
    *   **(Advanced)** Provides an interface for initiating an appeal process for a challenge resolution, potentially triggering a higher-tier dispute mechanism (e.g., a separate DAO vote or arbitration court) with a higher bond.

#### IV. Reputation & Soulbound Tokens (SBTs) Functions:
15. `mintVeritasReputationSBT(address _recipient)`:
    *   Mints a non-transferable `VeritasReputation` SBT to a recipient, signifying their entry into the protocol's reputation system. Only callable by the protocol owner.
16. `updateReputationScore(address _account, int256 _delta)`:
    *   Adjusts the reputation score for an account based on their successful or unsuccessful participation in claims and challenges. This function is called internally.
17. `getReputationScore(address _account)`:
    *   Retrieves the current numerical reputation score for a given account.
18. `issueEthicalComplianceSBT(address _recipient, bytes32 _verifiedClaimId)`:
    *   Issues a non-transferable `EthicalCompliance` certification SBT to an entity once a specific ethical claim about their AI model or dataset has been successfully `Verified`.
19. `revokeSBT(address _owner, uint256 _tokenId)`:
    *   **(Admin/Protocol Only)** Allows the revocation of a specific SBT (if marked as `revocable`), for instance, if a compliance certification is later found to be based on false information or violated.

#### V. Role Management & Protocol Configuration Functions:
20. `setAuditorRole(address _auditor, bool _hasRole)`:
    *   Grants or revokes the `Auditor` role to an address, enabling them to confirm ZKP verification outcomes and submit direct on-chain ZKP verifications.
21. `setDisputeResolverRole(address _resolver, bool _hasRole)`:
    *   Grants or revokes the `Dispute Resolver` role to an address, authorizing them to finalize challenge resolutions.
22. `setChallengePeriod(uint256 _newPeriod)`:
    *   Allows the protocol owner to adjust the duration (in seconds) for which new claims can be challenged.
23. `setVerificationBond(uint256 _newBond)`:
    *   Allows the protocol owner to modify the required ETH bond amount for submitting claims and challenges.
24. `pauseProtocol()`:
    *   Allows the protocol owner to pause critical functions of the contract in case of an emergency or upgrade.
25. `unpauseProtocol()`:
    *   Allows the protocol owner to unpause the contract's functions after a pause.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
*   Contract Name: CognitoVeritasProtocol
*   Purpose: A decentralized protocol for verifiable claims about AI models and their training data,
*            focusing on ethical AI, bias detection, and transparency. It leverages ZK-proofs
*            for privacy-preserving claims and Soulbound Tokens for reputation and certification.
*            This contract aims to create a "truth layer" for AI properties on-chain, enabling
*            developers, auditors, and users to establish and verify critical attributes of
*            AI systems in a transparent and auditable manner.
*
*   Advanced Concepts Integrated:
*   1.  **On-chain ZK-Proof Verification (Conceptual):** The contract includes functions to initiate and verify zero-knowledge proofs,
*       allowing privacy-preserving attestations about complex AI model characteristics (e.g., "model is unbiased" without revealing internal data).
*       It assumes an underlying precompile or robust library for actual SNARK/STARK verification.
*   2.  **Soulbound Tokens (SBTs):** Implemented as non-transferable reputation scores and ethical compliance certifications.
*       These bind reputation and achievements directly to an address, preventing market speculation on critical protocol roles or merits.
*   3.  **Decentralized Claim-Challenge System:** A robust mechanism for submitting, staking on, challenging, and resolving claims.
*       It integrates economic incentives (bonds, slashing) to align participant behavior with truth-telling.
*   4.  **Dynamic On-chain Attestations:** Claims are not static; their status can change based on challenge outcomes,
*       creating a living ledger of verified AI properties.
*   5.  **Role-Based Access Control:** Managed through internal state and potentially tied to SBTs, ensuring only authorized
*       entities (e.g., Auditors, Dispute Resolvers) can perform critical actions.
*
*   Disclaimer: Actual ZKP verification on-chain for complex proofs is extremely gas-intensive and often requires specific
*   precompiles or highly optimized libraries for a production environment. This contract provides the *interface* and *logic flow*
*   for such a system, assuming the underlying ZKP verification capabilities are available or integrated.
*/

/*
*   OUTLINE:
*   1.  Constants & Immutables
*   2.  Custom Errors
*   3.  Events
*   4.  Enums
*   5.  Structs
*   6.  Core State Variables
*   7.  Constructor
*   8.  Modifiers
*   9.  I. Claim Management Functions
*   10. II. Verification & ZK-Proof Integration Functions
*   11. III. Challenge & Dispute Resolution Functions
*   12. IV. Reputation & Soulbound Tokens (SBTs) Functions
*   13. V. Role Management & Protocol Configuration Functions
*   14. Internal/Helper Functions
*/

/*
*   FUNCTION SUMMARY (Minimum 20 functions):
*   ---------------------------------------
*
*   I. Claim Management Functions:
*   1.  `submitAICoherenceClaim(string memory _claimDescriptionURI, bytes32 _modelId, bytes32 _claimHash)`:
*       Allows an entity to submit a claim about an AI model's behavior or properties.
*   2.  `submitDatasetIntegrityClaim(string memory _claimDescriptionURI, bytes32 _datasetId, bytes32 _claimHash)`:
*       Allows an entity to submit a claim about a dataset's integrity or characteristics.
*   3.  `revokeClaim(bytes32 _claimId)`:
*       Allows the original claimer to revoke an unverified or unchallenged claim.
*   4.  `getClaimDetails(bytes32 _claimId)`:
*       Retrieves all stored details for a specific claim.
*   5.  `listClaimsForEntity(bytes32 _entityId)`:
*       Returns a list of all claims associated with a given AI model or dataset ID.
*
*   II. Verification & ZK-Proof Integration Functions:
*   6.  `requestZKPVerification(bytes32 _claimId, bytes memory _proof, bytes memory _publicInputs)`:
*       Initiates a request for ZKP verification for a specific claim, submitting the proof and public inputs.
*       This acts as a placeholder for an on-chain verifier or trigger for off-chain verification.
*   7.  `verifyZKPForClaim(bytes32 _claimId, bytes memory _proof, bytes memory _publicInputs)`:
*       (Advanced/Conceptual) Directly attempts to verify a ZKP on-chain for a claim using a mock precompile/library.
*       If successful, marks the claim as 'Verified'.
*   8.  `confirmZKPVerificationOutcome(bytes32 _requestId, bool _isVerified, address _verifier)`:
*       Allows a designated verifier (e.g., an Oracle service or a trusted party) to confirm the outcome of an
*       off-chain ZKP verification request.
*
*   III. Challenge & Dispute Resolution Functions:
*   9.  `challengeClaim(bytes32 _claimId, string memory _challengeReasonURI)`:
*       Allows any participant to challenge a submitted claim by staking a bond.
*   10. `supportClaim(bytes32 _claimId)`:
*       Allows participants to stake tokens to support a claim, backing its validity.
*   11. `supportChallenge(bytes32 _challengeId)`:
*       Allows participants to stake tokens to support a challenge, backing its validity.
*   12. `resolveChallengeVote(bytes32 _challengeId, bool _claimStands)`:
*       (Dispute Resolvers Only) Finalizes a challenge, determining if the claim is upheld or overturned.
*       Distributes rewards/slashes bonds accordingly.
*   13. `reclaimBond(bytes32 _claimIdOrChallengeId)`:
*       Allows participants to reclaim their staked bond after a claim or challenge has been resolved.
*   14. `appealResolution(bytes32 _challengeId)`:
*       (Advanced) Allows for an appeal process for a challenge resolution, potentially triggering a higher-tier dispute mechanism (e.g., DAO vote).
*
*   IV. Reputation & Soulbound Tokens (SBTs) Functions:
*   15. `mintVeritasReputationSBT(address _recipient)`:
*       Mints a non-transferable (soulbound) reputation token to a recipient.
*   16. `updateReputationScore(address _account, int256 _delta)`:
*       Adjusts the reputation score for an account based on their successful/unsuccessful participation in claims/challenges.
*   17. `getReputationScore(address _account)`:
*       Retrieves the current reputation score for a given account.
*   18. `issueEthicalComplianceSBT(address _recipient, bytes32 _verifiedClaimId)`:
*       Issues a non-transferable "Ethical Compliance" certification SBT if a specific ethical claim about an AI model is verified.
*   19. `revokeSBT(address _owner, uint256 _tokenId)`:
*       (Admin/Protocol only) Allows revocation of a specific SBT, e.g., if a compliance claim is later found false.
*
*   V. Role Management & Protocol Configuration Functions:
*   20. `setAuditorRole(address _auditor, bool _hasRole)`:
*       Grants or revokes the 'Auditor' role, allowing an address to submit ZKP verifications.
*   21. `setDisputeResolverRole(address _resolver, bool _hasRole)`:
*       Grants or revokes the 'Dispute Resolver' role, allowing an address to resolve challenges.
*   22. `setChallengePeriod(uint256 _newPeriod)`:
*       Sets the duration for which claims can be challenged.
*   23. `setVerificationBond(uint256 _newBond)`:
*       Sets the required bond amount for submitting claims and challenges.
*   24. `pauseProtocol()`:
*       Allows the authorized party (owner/DAO) to pause critical protocol functions in emergencies.
*   25. `unpauseProtocol()`:
*       Allows the authorized party to unpause the protocol.
*
*   Total functions: 25.
*/

contract CognitoVeritasProtocol {
    // --- 1. Constants & Immutables ---
    uint256 public constant MIN_CLAIM_DESCRIPTION_URI_LENGTH = 10;
    uint256 public constant MIN_CHALLENGE_REASON_URI_LENGTH = 10;

    address public immutable PROTOCOL_OWNER; // Could be a DAO in a real setup

    // --- 2. Custom Errors ---
    error Unauthorized();
    error ClaimNotFound();
    error ChallengeNotFound();
    error InvalidClaimStatus();
    error InvalidChallengeStatus();
    error InsufficientBond();
    error ClaimAlreadyVerified();
    error ClaimAlreadyChallenged();
    error ChallengeNotOver();
    error BondNotReclaimable();
    error ZKPRequestNotFound();
    error InvalidProofOrInputs();
    error OnlyAuditorAllowed();
    error OnlyDisputeResolverAllowed();
    error InvalidURILength();
    error SBTNotFound();
    error SBTAlreadyMinted();
    error ProtocolPaused();
    error ProtocolNotPaused();

    // --- 3. Events ---
    event ClaimSubmitted(bytes32 indexed claimId, address indexed claimer, uint256 submissionTime, string claimType);
    event ClaimRevoked(bytes32 indexed claimId, address indexed revoker);
    event ZKPVerificationRequested(bytes32 indexed requestId, bytes32 indexed claimId, address indexed prover);
    event ZKPVerificationConfirmed(bytes32 indexed requestId, bytes32 indexed claimId, bool isVerified, address verifier);
    event ClaimVerified(bytes32 indexed claimId, address indexed verifier);
    event ClaimChallenged(bytes32 indexed claimId, bytes32 indexed challengeId, address indexed challenger);
    event StakeAddedToClaim(bytes32 indexed claimId, address indexed staker, uint256 amount);
    event StakeAddedToChallenge(bytes32 indexed challengeId, address indexed staker, uint256 amount);
    event ChallengeResolved(bytes32 indexed challengeId, bool claimStands, address indexed resolver);
    event BondReclaimed(bytes32 indexed bondId, address indexed recipient, uint256 amount); // Simplified, a real one tracks sender
    event ReputationScoreUpdated(address indexed account, int256 delta, uint256 newScore);
    event VeritasReputationSBT_Minted(address indexed recipient, uint256 tokenId);
    event EthicalComplianceSBT_Issued(address indexed recipient, uint256 tokenId, bytes32 indexed verifiedClaimId);
    event SBTRevoked(address indexed owner, uint256 tokenId);
    event AuditorRoleSet(address indexed auditor, bool hasRole);
    event DisputeResolverRoleSet(address indexed resolver, bool hasRole);
    event ProtocolPausedEvent(address indexed by);
    event ProtocolUnpausedEvent(address indexed by);

    // --- 4. Enums ---
    enum ClaimStatus { Pending, Verified, Challenged, Overturned, Withdrawn }
    enum ChallengeStatus { Active, Resolved, Appealed }
    enum SBTType { VeritasReputation, EthicalCompliance }

    // --- 5. Structs ---
    struct Claim {
        bytes32 claimId;
        address claimer;
        string claimDescriptionURI; // URI to IPFS/Arweave for detailed claim
        bytes32 claimHash;         // Cryptographic hash of the claim content
        string claimType;          // "AI_COHERENCE", "DATASET_INTEGRITY", etc.
        bytes32 targetEntityId;    // ID of the AI model or dataset
        uint256 submissionTime;
        ClaimStatus status;
        uint256 initialBond;
        address verifier;          // Address of the auditor/verifier if verified via ZKP
        bytes32 verificationProofHash; // Hash of the proof if ZKP verified
        bytes32 currentChallengeId; // The active challenge ID if in Challenged state
        uint256 totalClaimStake;   // Total stake supporting the claim
    }

    struct Challenge {
        bytes32 challengeId;
        bytes32 claimId;
        address challenger;
        string challengeReasonURI; // URI to IPFS/Arweave for detailed reason
        uint256 submissionTime;
        ChallengeStatus status;
        uint256 challengerBond;    // Initial bond from challenger
        uint256 totalChallengeStake; // Total stake supporting the challenge
        uint256 resolutionTime;
        bool claimStandsResult;    // True if claim stands, False if overturned
    }

    struct ZKPVerificationRequest {
        bytes32 requestId;
        bytes32 claimId;
        address prover;
        bytes proofHash;
        bytes publicInputsHash;
        bool isCompleted;
        bool isVerified;
    }

    // Simplified SBT structure, mapping `tokenId` to `SBT` details
    struct SoulboundToken {
        uint256 tokenId;
        address owner;
        SBTType tokenType;
        string metadataURI;
        uint256 mintTime;
        bool revocable; // Some SBTs might be revocable under protocol rules
    }

    // --- 6. Core State Variables ---
    mapping(bytes32 => Claim) public claims;
    mapping(bytes32 => bytes32[]) public entityToClaims; // Maps model/dataset ID to a list of claim IDs
    mapping(bytes32 => Challenge) public challenges;
    mapping(bytes32 => ZKPVerificationRequest) public zkpVerificationRequests;
    uint256 private _nextClaimId = 1; // Used for generating unique claim IDs
    uint256 private _nextChallengeId = 1; // Used for generating unique challenge IDs
    uint256 private _nextZKPRequestId = 1; // Used for generating unique ZKP request IDs
    uint256 private _nextSBTId = 1; // Used for generating unique SBT IDs

    mapping(address => uint256) public reputationScores; // Tracks reputation for all participants
    mapping(address => uint256[]) public userSBTs;       // Tracks SBTs owned by an address (list of tokenIds)
    mapping(uint256 => SoulboundToken) public sbtDetails; // Stores details for each SBT

    mapping(address => bool) public isAuditor;
    mapping(address => bool) public isDisputeResolver;

    uint256 public challengePeriod; // Time in seconds for a claim to be challenged
    uint256 public verificationBondAmount; // Required bond for submitting claims/challenges

    bool public paused; // Protocol pause state

    // --- 7. Constructor ---
    constructor(uint256 _initialChallengePeriod, uint256 _initialVerificationBond) {
        PROTOCOL_OWNER = msg.sender;
        challengePeriod = _initialChallengePeriod; // e.g., 3 days = 3 * 24 * 60 * 60
        verificationBondAmount = _initialVerificationBond; // e.g., 1 ether
        paused = false;
    }

    // --- 8. Modifiers ---
    modifier onlyProtocolOwner() {
        if (msg.sender != PROTOCOL_OWNER) revert Unauthorized();
        _;
    }

    modifier onlyAuditor() {
        if (!isAuditor[msg.sender]) revert OnlyAuditorAllowed();
        _;
    }

    modifier onlyDisputeResolver() {
        if (!isDisputeResolver[msg.sender]) revert OnlyDisputeResolverAllowed();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ProtocolPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ProtocolNotPaused();
        _;
    }

    // --- 9. I. Claim Management Functions ---

    /**
     * @notice Allows an entity to submit a claim about an AI model's behavior or properties.
     * @param _claimDescriptionURI URI to off-chain details (e.g., IPFS) describing the claim.
     * @param _modelId Unique identifier for the AI model (e.g., `bytes32(keccak256(abi.encodePacked("model_name_v1.0")))`).
     * @param _claimHash Cryptographic hash of the claim content for integrity verification.
     */
    function submitAICoherenceClaim(
        string memory _claimDescriptionURI,
        bytes32 _modelId,
        bytes32 _claimHash
    ) external payable whenNotPaused {
        if (msg.value < verificationBondAmount) revert InsufficientBond();
        if (bytes(_claimDescriptionURI).length < MIN_CLAIM_DESCRIPTION_URI_LENGTH) revert InvalidURILength();

        bytes32 claimId = keccak256(abi.encodePacked("claim", _nextClaimId, block.timestamp, msg.sender));
        _nextClaimId++;

        claims[claimId] = Claim({
            claimId: claimId,
            claimer: msg.sender,
            claimDescriptionURI: _claimDescriptionURI,
            claimHash: _claimHash,
            claimType: "AI_COHERENCE",
            targetEntityId: _modelId,
            submissionTime: block.timestamp,
            status: ClaimStatus.Pending,
            initialBond: msg.value,
            verifier: address(0),
            verificationProofHash: bytes32(0),
            currentChallengeId: bytes32(0),
            totalClaimStake: msg.value
        });

        entityToClaims[_modelId].push(claimId);
        emit ClaimSubmitted(claimId, msg.sender, block.timestamp, "AI_COHERENCE");
    }

    /**
     * @notice Allows an entity to submit a claim about a dataset's integrity or characteristics.
     * @param _claimDescriptionURI URI to off-chain details (e.g., IPFS) describing the claim.
     * @param _datasetId Unique identifier for the dataset (e.g., `bytes32(keccak256(abi.encodePacked("dataset_v2")))`).
     * @param _claimHash Cryptographic hash of the claim content for integrity verification.
     */
    function submitDatasetIntegrityClaim(
        string memory _claimDescriptionURI,
        bytes32 _datasetId,
        bytes32 _claimHash
    ) external payable whenNotPaused {
        if (msg.value < verificationBondAmount) revert InsufficientBond();
        if (bytes(_claimDescriptionURI).length < MIN_CLAIM_DESCRIPTION_URI_LENGTH) revert InvalidURILength();

        bytes32 claimId = keccak256(abi.encodePacked("claim", _nextClaimId, block.timestamp, msg.sender));
        _nextClaimId++;

        claims[claimId] = Claim({
            claimId: claimId,
            claimer: msg.sender,
            claimDescriptionURI: _claimDescriptionURI,
            claimHash: _claimHash,
            claimType: "DATASET_INTEGRITY",
            targetEntityId: _datasetId,
            submissionTime: block.timestamp,
            status: ClaimStatus.Pending,
            initialBond: msg.value,
            verifier: address(0),
            verificationProofHash: bytes32(0),
            currentChallengeId: bytes32(0),
            totalClaimStake: msg.value
        });

        entityToClaims[_datasetId].push(claimId);
        emit ClaimSubmitted(claimId, msg.sender, block.timestamp, "DATASET_INTEGRITY");
    }

    /**
     * @notice Allows the original claimer to revoke an unverified or unchallenged claim.
     * @param _claimId The ID of the claim to revoke.
     */
    function revokeClaim(bytes32 _claimId) external whenNotPaused {
        Claim storage claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.claimer != msg.sender) revert Unauthorized();
        if (claim.status == ClaimStatus.Verified || claim.status == ClaimStatus.Challenged) revert InvalidClaimStatus();

        claim.status = ClaimStatus.Withdrawn;
        _safeTransferETH(claim.claimer, claim.initialBond); // Return initial bond
        emit ClaimRevoked(_claimId, msg.sender);
    }

    /**
     * @notice Retrieves all stored details for a specific claim.
     * @param _claimId The ID of the claim.
     * @return Claim struct containing all details.
     */
    function getClaimDetails(bytes32 _claimId) external view returns (Claim memory) {
        Claim memory claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        return claim;
    }

    /**
     * @notice Returns a list of all claims associated with a given AI model or dataset ID.
     * @param _entityId The ID of the AI model or dataset.
     * @return An array of claim IDs.
     */
    function listClaimsForEntity(bytes32 _entityId) external view returns (bytes32[] memory) {
        return entityToClaims[_entityId];
    }

    // --- 10. II. Verification & ZK-Proof Integration Functions ---

    /**
     * @notice Initiates a request for ZKP verification for a specific claim, submitting the proof and public inputs.
     *         This acts as a placeholder for an on-chain verifier or trigger for off-chain verification.
     * @param _claimId The ID of the claim to verify.
     * @param _proof The serialized zero-knowledge proof.
     * @param _publicInputs The public inputs for the proof.
     */
    function requestZKPVerification(
        bytes32 _claimId,
        bytes memory _proof,
        bytes memory _publicInputs
    ) external whenNotPaused {
        Claim storage claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.status != ClaimStatus.Pending) revert InvalidClaimStatus();
        if (bytes(_proof).length == 0 || bytes(_publicInputs).length == 0) revert InvalidProofOrInputs();

        bytes32 requestId = keccak256(abi.encodePacked("zkp_req", _nextZKPRequestId, block.timestamp, msg.sender));
        _nextZKPRequestId++;

        zkpVerificationRequests[requestId] = ZKPVerificationRequest({
            requestId: requestId,
            claimId: _claimId,
            prover: msg.sender,
            proofHash: keccak256(_proof),
            publicInputsHash: keccak256(_publicInputs),
            isCompleted: false,
            isVerified: false
        });

        emit ZKPVerificationRequested(requestId, _claimId, msg.sender);
    }

    /**
     * @notice (Advanced/Conceptual) Directly attempts to verify a ZKP on-chain for a claim using a mock precompile/library.
     *         If successful, marks the claim as 'Verified'.
     * @dev In a real dApp, this would interact with a precompiled contract for specific ZKP systems (e.g., BN254.pairing for Groth16)
     *      or a complex verification library, which is highly gas-intensive and outside the scope of a simple example.
     *      For this example, it's a mock verification.
     * @param _claimId The ID of the claim to verify.
     * @param _proof The serialized zero-knowledge proof.
     * @param _publicInputs The public inputs for the proof.
     */
    function verifyZKPForClaim(
        bytes32 _claimId,
        bytes memory _proof,
        bytes memory _publicInputs
    ) external onlyAuditor whenNotPaused {
        Claim storage claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.status != ClaimStatus.Pending) revert InvalidClaimStatus();
        if (bytes(_proof).length == 0 || bytes(_publicInputs).length == 0) revert InvalidProofOrInputs();

        // --- Mock ZKP Verification Logic ---
        // In a real dApp, this would call a precompile or a complex Solidity library:
        // bool verified = ZKPVerifierLibrary.verify(_proof, _publicInputs, claim.claimHash);
        // For demonstration, let's assume it always passes for valid input for the purpose of function flow.
        bool verified = (keccak256(_proof) != bytes32(0) && keccak256(_publicInputs) != bytes32(0)); // A trivial check

        if (verified) {
            claim.status = ClaimStatus.Verified;
            claim.verifier = msg.sender;
            claim.verificationProofHash = keccak256(_proof); // Store hash of the proof
            emit ClaimVerified(_claimId, msg.sender);
        } else {
            // Potentially re-allow re-submission or trigger a penalty for failed verification attempt
            // For now, no state change if verification fails via this path.
        }
    }

    /**
     * @notice Allows a designated verifier (e.g., an Oracle service or a trusted party) to confirm the outcome of an
     *         off-chain ZKP verification request.
     * @param _requestId The ID of the ZKP verification request.
     * @param _isVerified Boolean indicating if the proof was successfully verified off-chain.
     * @param _verifier The address of the verifier confirming the outcome.
     */
    function confirmZKPVerificationOutcome(
        bytes32 _requestId,
        bool _isVerified,
        address _verifier
    ) external onlyAuditor whenNotPaused {
        ZKPVerificationRequest storage req = zkpVerificationRequests[_requestId];
        if (req.requestId == bytes32(0)) revert ZKPRequestNotFound();
        if (req.isCompleted) revert ZKPRequestNotFound(); // Already completed

        Claim storage claim = claims[req.claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.status != ClaimStatus.Pending) revert InvalidClaimStatus();

        req.isCompleted = true;
        req.isVerified = _isVerified;

        if (_isVerified) {
            claim.status = ClaimStatus.Verified;
            claim.verifier = _verifier; // The address confirming the outcome
            claim.verificationProofHash = req.proofHash; // Store hash of the original proof
            emit ClaimVerified(req.claimId, _verifier);
        }
        // If not verified, the claim remains in 'Pending' or could be marked 'Rejected'
        emit ZKPVerificationConfirmed(_requestId, req.claimId, _isVerified, _verifier);
    }

    // --- 11. III. Challenge & Dispute Resolution Functions ---

    /**
     * @notice Allows any participant to challenge a submitted claim by staking a bond.
     *         A claim can only be challenged if it's Pending and within the challenge period, or if it's Verified.
     * @param _claimId The ID of the claim to challenge.
     * @param _challengeReasonURI URI to off-chain details explaining the challenge reason.
     */
    function challengeClaim(
        bytes32 _claimId,
        string memory _challengeReasonURI
    ) external payable whenNotPaused {
        Claim storage claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.status == ClaimStatus.Challenged) revert ClaimAlreadyChallenged();
        if (claim.status == ClaimStatus.Overturned || claim.status == ClaimStatus.Withdrawn) revert InvalidClaimStatus();
        // Claims can be challenged if Pending (and within challenge window) or Verified
        if (claim.status == ClaimStatus.Pending && (block.timestamp > claim.submissionTime + challengePeriod)) revert InvalidClaimStatus(); // Challenge period elapsed
        if (msg.value < verificationBondAmount) revert InsufficientBond();
        if (bytes(_challengeReasonURI).length < MIN_CHALLENGE_REASON_URI_LENGTH) revert InvalidURILength();

        bytes32 challengeId = keccak256(abi.encodePacked("challenge", _nextChallengeId, block.timestamp, msg.sender));
        _nextChallengeId++;

        challenges[challengeId] = Challenge({
            challengeId: challengeId,
            claimId: _claimId,
            challenger: msg.sender,
            challengeReasonURI: _challengeReasonURI,
            submissionTime: block.timestamp,
            status: ChallengeStatus.Active,
            challengerBond: msg.value,
            totalChallengeStake: msg.value,
            resolutionTime: 0,
            claimStandsResult: false
        });

        claim.status = ClaimStatus.Challenged;
        claim.currentChallengeId = challengeId;

        emit ClaimChallenged(_claimId, challengeId, msg.sender);
    }

    /**
     * @notice Allows participants to stake tokens to support a claim, backing its validity.
     *         Can only be done when the claim is in 'Challenged' status.
     * @param _claimId The ID of the claim to support.
     */
    function supportClaim(bytes32 _claimId) external payable whenNotPaused {
        Claim storage claim = claims[_claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound();
        if (claim.status != ClaimStatus.Challenged) revert InvalidClaimStatus();
        if (msg.value == 0) revert InsufficientBond(); // Must provide some stake

        claim.totalClaimStake += msg.value;
        // Optionally, track individual stakes in a sub-mapping for more granular bond reclamation.
        // For simplicity, total stake is tracked here.
        emit StakeAddedToClaim(_claimId, msg.sender, msg.value);
    }

    /**
     * @notice Allows participants to stake tokens to support a challenge, backing its validity.
     *         Can only be done when the challenge is in 'Active' status.
     * @param _challengeId The ID of the challenge to support.
     */
    function supportChallenge(bytes32 _challengeId) external payable whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == bytes32(0)) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Active) revert InvalidChallengeStatus();
        if (msg.value == 0) revert InsufficientBond(); // Must provide some stake

        challenge.totalChallengeStake += msg.value;
        // Optionally, track individual stakes in a sub-mapping for more granular bond reclamation.
        // For simplicity, total stake is tracked here.
        emit StakeAddedToChallenge(_challengeId, msg.sender, msg.value);
    }

    /**
     * @notice (Dispute Resolvers Only) Finalizes a challenge, determining if the claim is upheld or overturned.
     *         Distributes rewards/slashes bonds accordingly.
     * @param _challengeId The ID of the challenge to resolve.
     * @param _claimStands True if the claim is upheld, False if it is overturned.
     */
    function resolveChallengeVote(
        bytes32 _challengeId,
        bool _claimStands
    ) external onlyDisputeResolver whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == bytes32(0)) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Active) revert InvalidChallengeStatus();

        Claim storage claim = claims[challenge.claimId];
        if (claim.claimId == bytes32(0)) revert ClaimNotFound(); // Should not happen if challenge exists

        challenge.status = ChallengeStatus.Resolved;
        challenge.resolutionTime = block.timestamp;
        challenge.claimStandsResult = _claimStands;

        if (_claimStands) {
            // Claim is upheld. Challenger and supporters are slashed. Claimer and supporters are rewarded.
            claim.status = ClaimStatus.Verified; // Re-verify or confirm verification
            _distributeRewardsAndSlashing(
                claim.claimer,
                claim.totalClaimStake,
                challenge.challenger,
                challenge.totalChallengeStake,
                true // Claim wins
            );
            updateReputationScore(claim.claimer, 100); // Reward claimer
            updateReputationScore(challenge.challenger, -50); // Penalize challenger
        } else {
            // Claim is overturned. Claimer and supporters are slashed. Challenger and supporters are rewarded.
            claim.status = ClaimStatus.Overturned;
            _distributeRewardsAndSlashing(
                claim.claimer,
                claim.totalClaimStake,
                challenge.challenger,
                challenge.totalChallengeStake,
                false // Challenge wins
            );
            updateReputationScore(claim.claimer, -100); // Penalize claimer
            updateReputationScore(challenge.challenger, 50); // Reward challenger
        }

        emit ChallengeResolved(_challengeId, _claimStands, msg.sender);
    }

    /**
     * @notice Allows participants to reclaim their staked bond after a claim or challenge has been resolved.
     * @param _claimIdOrChallengeId The ID of the claim or challenge.
     */
    function reclaimBond(bytes32 _claimIdOrChallengeId) external whenNotPaused {
        // This function would need a more sophisticated mapping of individual staker amounts.
        // For this example, assuming all stake is pooled and bonds are returned based on outcome for initial staker.
        // In a real system, `msg.sender` would claim their specific share.

        // Check if it's a claim bond reclaim
        if (claims[_claimIdOrChallengeId].claimId != bytes32(0) && claims[_claimIdOrChallengeId].claimer == msg.sender) {
            Claim storage claim = claims[_claimIdOrChallengeId];
            if (claim.status == ClaimStatus.Withdrawn) {
                // Initial bond was already refunded by revokeClaim
                revert BondNotReclaimable();
            }
            if (claim.status == ClaimStatus.Overturned) {
                // Bond was slashed
                revert BondNotReclaimable();
            }
            // If claim is Verified or Challenged but resolved to True, initial bond is part of the rewards.
            // This simplified version only refunds if withdrawn explicitly.
            revert BondNotReclaimable(); // For simplicity, initial bond is part of the reward distribution in resolveChallengeVote.
        }

        // Check if it's a challenge bond reclaim
        if (challenges[_claimIdOrChallengeId].challengeId != bytes32(0) && challenges[_claimIdOrChallengeId].challenger == msg.sender) {
            Challenge storage challenge = challenges[_claimIdOrChallengeId];
            if (challenge.status != ChallengeStatus.Resolved) revert ChallengeNotOver();
            if (challenge.claimStandsResult == false) {
                // Challenger won, bond was part of reward.
                revert BondNotReclaimable();
            }
            // Challenger lost, bond was slashed.
            revert BondNotReclaimable();
        }

        revert BondNotReclaimable(); // Neither a reclaimable claim nor challenge bond for msg.sender
    }

    /**
     * @notice (Advanced) Allows for an appeal process for a challenge resolution,
     *         potentially triggering a higher-tier dispute mechanism (e.g., DAO vote).
     * @param _challengeId The ID of the challenge to appeal.
     */
    function appealResolution(bytes32 _challengeId) external payable whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.challengeId == bytes32(0)) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Resolved) revert InvalidChallengeStatus();
        if (msg.value < (verificationBondAmount * 2)) revert InsufficientBond(); // Higher bond for appeal

        // Here, integrate with a DAO or a higher-level dispute court
        // For this example, we simply change the status to Appealed.
        challenge.status = ChallengeStatus.Appealed;
        // The appeal process itself (e.g., voting, re-evaluation) would happen off-chain or in a separate contract.
        // This bond would secure the appeal.
        emit ChallengeResolved(_challengeId, challenge.claimStandsResult, address(0)); // Emit with address(0) to signify appeal, not final resolution
    }

    // --- 12. IV. Reputation & Soulbound Tokens (SBTs) Functions ---

    /**
     * @notice Mints a non-transferable (soulbound) reputation token to a recipient.
     *         This function can only be called by the protocol owner or a designated minter.
     * @param _recipient The address to mint the SBT to.
     */
    function mintVeritasReputationSBT(address _recipient) external onlyProtocolOwner {
        // Prevent duplicate initial minting for simplicity, or allow based on a role.
        if (userSBTs[_recipient].length > 0) {
            // Check if VeritasReputation SBT already exists for recipient
            for (uint256 i = 0; i < userSBTs[_recipient].length; i++) {
                if (sbtDetails[userSBTs[_recipient][i]].tokenType == SBTType.VeritasReputation) {
                    revert SBTAlreadyMinted();
                }
            }
        }

        uint256 tokenId = _nextSBTId++;
        SoulboundToken storage newSBT = sbtDetails[tokenId];
        newSBT.tokenId = tokenId;
        newSBT.owner = _recipient;
        newSBT.tokenType = SBTType.VeritasReputation;
        newSBT.metadataURI = "ipfs://Qmb_initial_reputation_sbt_metadata"; // Example URI
        newSBT.mintTime = block.timestamp;
        newSBT.revocable = false; // Reputation SBTs are generally not revocable

        userSBTs[_recipient].push(tokenId);
        reputationScores[_recipient] = 1; // Initial reputation score upon receiving an SBT
        emit VeritasReputationSBT_Minted(_recipient, tokenId);
    }

    /**
     * @notice Adjusts the reputation score for an account based on their successful/unsuccessful participation.
     * @param _account The account whose reputation to update.
     * @param _delta The amount to change the reputation score by (can be negative).
     */
    function updateReputationScore(address _account, int256 _delta) public {
        // This function is public as it's called by internal logic (e.g., resolveChallengeVote)
        // Ensure the account has a reputation SBT (meaning they are part of the system)
        bool hasReputationSBT = false;
        for (uint256 i = 0; i < userSBTs[_account].length; i++) {
            if (sbtDetails[userSBTs[_account][i]].tokenType == SBTType.VeritasReputation) {
                hasReputationSBT = true;
                break;
            }
        }
        if (!hasReputationSBT) return; // Cannot update reputation for non-participants (or mint a default one)

        unchecked { // Safe for underflow if reputation can go negative, but unlikely to go below 0 for score.
            reputationScores[_account] = uint256(int256(reputationScores[_account]) + _delta);
        }
        emit ReputationScoreUpdated(_account, _delta, reputationScores[_account]);
    }

    /**
     * @notice Retrieves the current reputation score for a given account.
     * @param _account The address of the account.
     * @return The current reputation score.
     */
    function getReputationScore(address _account) external view returns (uint256) {
        return reputationScores[_account];
    }

    /**
     * @notice Issues a non-transferable "Ethical Compliance" certification SBT if a specific ethical claim about an AI model is verified.
     * @param _recipient The address of the entity (e.g., model provider) to issue the SBT to.
     * @param _verifiedClaimId The ID of the claim that was successfully verified.
     */
    function issueEthicalComplianceSBT(address _recipient, bytes32 _verifiedClaimId) external onlyDisputeResolver {
        // Only dispute resolvers or automated system can issue this after a claim is verified
        Claim memory claim = claims[_verifiedClaimId];
        if (claim.claimId == bytes32(0) || claim.status != ClaimStatus.Verified) revert ClaimNotFound();
        // Additional logic: Check if claim is indeed about "ethical compliance"
        if (keccak256(abi.encodePacked(claim.claimType)) != keccak256(abi.encodePacked("AI_COHERENCE"))) {
            revert InvalidClaimStatus(); // Or a more specific error
        }

        uint256 tokenId = _nextSBTId++;
        SoulboundToken storage newSBT = sbtDetails[tokenId];
        newSBT.tokenId = tokenId;
        newSBT.owner = _recipient;
        newSBT.tokenType = SBTType.EthicalCompliance;
        newSBT.metadataURI = string(abi.encodePacked("ipfs://Qmb_ethical_compliance_sbt_", _verifiedClaimId)); // Link to verified claim
        newSBT.mintTime = block.timestamp;
        newSBT.revocable = true; // Ethical compliance might be revocable if claim is later overturned

        userSBTs[_recipient].push(tokenId);
        emit EthicalComplianceSBT_Issued(_recipient, tokenId, _verifiedClaimId);
    }

    /**
     * @notice (Admin/Protocol only) Allows revocation of a specific SBT, e.g., if a compliance claim is later found false.
     * @param _owner The current owner of the SBT.
     * @param _tokenId The ID of the SBT to revoke.
     */
    function revokeSBT(address _owner, uint256 _tokenId) external onlyProtocolOwner {
        SoulboundToken storage sbt = sbtDetails[_tokenId];
        if (sbt.tokenId == 0 || sbt.owner != _owner) revert SBTNotFound();
        if (!sbt.revocable) revert Unauthorized(); // Cannot revoke non-revocable SBTs

        // Remove from owner's list
        uint256[] storage ownerSBTs = userSBTs[_owner];
        for (uint256 i = 0; i < ownerSBTs.length; i++) {
            if (ownerSBTs[i] == _tokenId) {
                ownerSBTs[i] = ownerSBTs[ownerSBTs.length - 1];
                ownerSBTs.pop();
                break;
            }
        }

        delete sbtDetails[_tokenId]; // Delete the SBT data
        emit SBTRevoked(_owner, _tokenId);
    }

    // --- 13. V. Role Management & Protocol Configuration Functions ---

    /**
     * @notice Grants or revokes the 'Auditor' role, allowing an address to submit ZKP verifications.
     * @param _auditor The address to set the role for.
     * @param _hasRole Boolean indicating whether to grant (true) or revoke (false) the role.
     */
    function setAuditorRole(address _auditor, bool _hasRole) external onlyProtocolOwner {
        isAuditor[_auditor] = _hasRole;
        emit AuditorRoleSet(_auditor, _hasRole);
    }

    /**
     * @notice Grants or revokes the 'Dispute Resolver' role, allowing an address to resolve challenges.
     * @param _resolver The address to set the role for.
     * @param _hasRole Boolean indicating whether to grant (true) or revoke (false) the role.
     */
    function setDisputeResolverRole(address _resolver, bool _hasRole) external onlyProtocolOwner {
        isDisputeResolver[_resolver] = _hasRole;
        emit DisputeResolverRoleSet(_resolver, _hasRole);
    }

    /**
     * @notice Sets the duration for which claims can be challenged.
     * @param _newPeriod The new challenge period in seconds.
     */
    function setChallengePeriod(uint256 _newPeriod) external onlyProtocolOwner {
        challengePeriod = _newPeriod;
    }

    /**
     * @notice Sets the required bond amount for submitting claims and challenges.
     * @param _newBond The new bond amount in Wei.
     */
    function setVerificationBond(uint256 _newBond) external onlyProtocolOwner {
        verificationBondAmount = _newBond;
    }

    /**
     * @notice Allows the authorized party (owner/DAO) to pause critical protocol functions in emergencies.
     */
    function pauseProtocol() external onlyProtocolOwner whenNotPaused {
        paused = true;
        emit ProtocolPausedEvent(msg.sender);
    }

    /**
     * @notice Allows the authorized party to unpause the protocol.
     */
    function unpauseProtocol() external onlyProtocolOwner whenPaused {
        paused = false;
        emit ProtocolUnpausedEvent(msg.sender);
    }

    // --- 14. Internal/Helper Functions ---

    /**
     * @dev Internal function to handle the distribution of rewards and slashing of bonds.
     *      Simplified model: winner takes all losing stakes, minus a small protocol fee.
     * @param _claimer The address of the claimer.
     * @param _claimStake Total stake backing the claim.
     * @param _challenger The address of the challenger.
     * @param _challengeStake Total stake backing the challenge.
     * @param _claimWins True if the claim is upheld, false if overturned.
     */
    function _distributeRewardsAndSlashing(
        address _claimer,
        uint256 _claimStake,
        address _challenger,
        uint256 _challengeStake,
        bool _claimWins
    ) internal {
        uint256 protocolFee = (_claimStake + _challengeStake) / 100; // 1% fee for example
        uint256 totalPool = _claimStake + _challengeStake - protocolFee;

        if (_claimWins) {
            // Claimer and supporters win, challenger and supporters lose
            _safeTransferETH(_claimer, totalPool); // Give winner the whole pool for simplicity
        } else {
            // Challenger and supporters win, claimer and supporters lose
            _safeTransferETH(_challenger, totalPool); // Give winner the whole pool for simplicity
        }
        // Protocol owner collects fee implicitly, or send explicitly to treasury:
        // _safeTransferETH(PROTOCOL_OWNER, protocolFee);
    }

    /**
     * @dev Internal function to safely transfer ETH, handling potential failures.
     * @param _to The address to send ETH to.
     * @param _amount The amount of ETH to send.
     */
    function _safeTransferETH(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "ETH transfer failed");
    }
}
```