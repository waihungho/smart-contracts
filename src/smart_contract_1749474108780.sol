Okay, here is a smart contract concept called `QuantumKeyVault` that attempts to incorporate advanced, creative, and trendy ideas like multi-custodian governance, abstract ZK-proof verification flows, metaphorical "quantum entanglement" of access, and stochastic (probabilistic via VRF) access modifications, all centered around managing references and access conditions for off-chain secrets/keys.

It's designed to be complex and demonstrate interaction with potential off-chain systems (ZK provers, oracles, VRF) through on-chain state management and verification logic, without duplicating standard open-source patterns like basic ERC20/721 or simple timelocks/multisigs.

**Outline and Function Summary**

**Contract Name:** `QuantumKeyVault`

**Concept:** A secure vault managed by a decentralized set of custodians. It doesn't store secrets directly on-chain but manages verifiable references (hashes) and complex, multi-layered access conditions for off-chain secrets/keys. Access can require various proofs (simulated ZK proof verification), direct grants, or even be influenced by verifiable randomness ("stochastic influence") or linked to the state/access of other secrets ("quantum entanglement").

**Key Features:**

1.  **Multi-Custodian Governance:** Core configuration changes, custodian management, and critical secret operations (like removal) require proposals and majority voting by designated custodians.
2.  **Secret Reference Management:** Store secure hashes and access requirements for off-chain secrets. Supports different access models.
3.  **Abstract ZK-Proof Verification:** Users submit a *claim* of a ZK proof hash. The contract tracks this, and an authorized "Verifier Oracle" notifies the contract whether the off-chain ZK proof verification passed for that specific submission. Access can then be granted based on this verified status.
4.  **"Quantum Entanglement" (Metaphorical):** Link two secret references. Accessing one might depend on the state or a specific verifiable condition related to the *other* linked secret.
5.  **"Stochastic Influence" (Via VRF):** Integrate with a Verifiable Randomness Function (like Chainlink VRF) to introduce probabilistic elements to access, temporarily modifying conditions or chances based on a verifiably unpredictable seed.
6.  **Emergency Bypass:** A mechanism for custodians to collectively bypass standard access controls under defined emergency conditions.
7.  **Pause Mechanism:** Standard contract pausing for upgrades or emergency.

**Function Summary:**

*(Total Functions: 30+)*

**I. Governance & Configuration (Multi-Custodian)**
1.  `constructor(address[] initialCustodians, uint256 initialQuorum)`: Initializes the vault with custodians and required quorum for proposals.
2.  `addCustodianProposal(address newCustodian)`: Proposes adding a new custodian.
3.  `removeCustodianProposal(address custodianToRemove)`: Proposes removing a custodian.
4.  `proposeConfigChange(uint256 newQuorum)`: Proposes changing core vault configurations (e.g., quorum size).
5.  `voteOnProposal(uint256 proposalId, bool support)`: Cast a vote on an active proposal.
6.  `executeProposal(uint256 proposalId)`: Execute a proposal if quorum is met and time permits.
7.  `setVerifierOracle(address oracleAddress)`: Custodians propose/vote to set the address of the trusted ZK proof Verifier Oracle.
8.  `setEmergencyParameters(uint256 minEmergencyCustodians)`: Custodians propose/vote to set parameters for the emergency bypass.

**II. Secret Reference Management**
9.  `depositZKProofSecretReference(bytes32 secretId, bytes32 secretHash, bytes32 requiredZKProofConditionHash)`: Deposits a secret reference requiring a specific ZK proof condition to be met for access.
10. `depositDirectAccessSecretReference(bytes32 secretId, bytes32 secretHash, address initialGrantedUser)`: Deposits a secret reference initially granted to a specific user, bypassing ZK proofs for them.
11. `updateSecretHash(bytes32 secretId, bytes32 newSecretHash)`: Update the stored hash for a secret (custodian only).
12. `updateRequiredZKProofCondition(bytes32 secretId, bytes32 newConditionHash)`: Update the required ZK proof condition hash (custodian only).
13. `proposeSecretRemoval(bytes32 secretId)`: Proposes removing a secret reference (custodian vote required).
14. `executeSecretRemoval(uint256 proposalId)`: Executes secret removal if proposal passes.

**III. Access Control & Verification (ZK & Direct)**
15. `grantTemporaryDirectAccess(bytes32 secretId, address user, uint64 duration)`: Grants temporary direct access to a secret (even ZK-based ones) for a specific user (custodian only).
16. `revokeTemporaryDirectAccess(bytes32 secretId, address user)`: Revokes temporary access (custodian only).
17. `registerZKProofSubmissionAttempt(bytes32 secretId, bytes32 submittedProofHash)`: User registers their attempt to access a secret by providing the hash of their generated ZK proof.
18. `notifyZKProofVerificationResult(bytes32 secretId, bytes32 submittedProofHash, bool isValid, bytes proofVerificationData)`: Called *only* by the trusted Verifier Oracle to report the result of an off-chain ZK proof verification for a specific submission. Includes optional verification data.
19. `checkAccessEligibility(bytes32 secretId, address user)`: Pure function to check if a user is currently eligible to access a secret based on direct grants, temporary access, or verified ZK proof submissions.

**IV. "Quantum Entanglement" Mechanics**
20. `entangleSecrets(bytes32 secretIdA, bytes32 secretIdB, bytes32 entanglementConditionHash, uint8 entanglementType)`: Links two secrets. `entanglementConditionHash` and `entanglementType` define the rule (e.g., access to A requires meeting conditionHash related to B). Custodian-only or via proposal.
21. `resolveEntangledAccessAttempt(bytes32 secretIdToAccess, bytes32 potentiallyLinkedSecretId, bytes32 submittedEntanglementProofHash)`: Attempt to access `secretIdToAccess`. If it's entangled, this function checks if the `submittedEntanglementProofHash` satisfies the `entanglementConditionHash` related to `potentiallyLinkedSecretId`, alongside other access checks.

**V. "Stochastic Influence" Mechanics (Via VRF - Example Chainlink VRF)**
22. `requestStochasticInfluenceSeed(bytes32 secretId)`: Requests a random seed for a specific secret via VRF. Requires contract to be funded for VRF fees.
23. `fulfillRandomWords(uint256 requestId, uint256[] randomWords)`: VRF callback function. Receives the random seed.
24. `applyStochasticAccessModifier(bytes32 secretId)`: Uses the latest received random seed for this secret to temporarily modify access parameters (e.g., disable ZK check for one attempt, grant temporary access to a random user, etc., based on defined logic using the randomness). Logic must be complex and determined by the seed.

**VI. Emergency Bypass**
25. `initiateEmergencyBypass()`: A custodian proposes activating emergency bypass.
26. `supportEmergencyBypass(bytes32 emergencySessionId)`: Other custodians vote to support the emergency bypass session.
27. `triggerEmergencyOverride(bytes32 secretId, bytes32 emergencySessionId)`: If enough custodians support the session, this allows bypassing standard access checks for a specific secret during the emergency (custodian only).

**VII. Utility & State Inspection**
28. `pause()`: Pause certain contract operations (custodian only).
29. `unpause()`: Unpause contract (custodian only).
30. `getSecretDetails(bytes32 secretId)`: Get public information about a secret (hashes, type, entanglement).
31. `getUserAccessStatus(bytes32 secretId, address user)`: Get detailed status of a user's potential access paths (direct, temp, proof status).
32. `getProposalState(uint256 proposalId)`: Get the current state of a proposal.
33. `getCustodians()`: Get the list of current custodians.
34. `getVaultConfig()`: Get current vault configuration (quorum, verifier, emergency params).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Example: If needing to pay VRF fees

// Note: This contract is a complex conceptual model.
// It requires integration with off-chain systems (ZK Provers, Oracles, VRF)
// and assumes the existence of external logic for generating and verifying
// ZK proofs against the stored `requiredZKProofConditionHash`.
// Security considerations for production use, especially around the Oracle,
// VRF integration, and emergency bypass, would require rigorous design & audits.

// --- Outline and Function Summary ---
// (See markdown above for detailed summary)
//
// Contract Name: QuantumKeyVault
// Concept: Multi-custodian vault managing off-chain secret references with complex access logic.
// Features: Multi-Custodian Governance, ZK-Proof Verification Flow, Metaphorical Quantum Entanglement, Stochastic Access (VRF), Emergency Bypass.
//
// Functions:
// I. Governance & Configuration (Multi-Custodian)
// 1. constructor
// 2. addCustodianProposal
// 3. removeCustodianProposal
// 4. proposeConfigChange
// 5. voteOnProposal
// 6. executeProposal
// 7. setVerifierOracleProposal // Renamed for clarity
// 8. setEmergencyParametersProposal // Renamed for clarity
//
// II. Secret Reference Management
// 9. depositZKProofSecretReference
// 10. depositDirectAccessSecretReference
// 11. updateSecretHash
// 12. updateRequiredZKProofCondition
// 13. proposeSecretRemoval
// 14. executeSecretRemoval (uses executeProposal internally)
//
// III. Access Control & Verification (ZK & Direct)
// 15. grantTemporaryDirectAccess
// 16. revokeTemporaryDirectAccess
// 17. registerZKProofSubmissionAttempt
// 18. notifyZKProofVerificationResult
// 19. checkAccessEligibility (View function)
//
// IV. "Quantum Entanglement" Mechanics
// 20. entangleSecretsProposal // Via proposal
// 21. resolveEntangledAccessAttempt
//
// V. "Stochastic Influence" Mechanics (Via VRF - Example Chainlink VRF)
// 22. requestStochasticInfluenceSeed
// 23. fulfillRandomWords (VRF callback)
// 24. applyStochasticAccessModifier
//
// VI. Emergency Bypass
// 25. initiateEmergencyBypass
// 26. supportEmergencyBypass
// 27. triggerEmergencyOverride
//
// VII. Utility & State Inspection
// 28. pause
// 29. unpause
// 30. getSecretDetails (View function)
// 31. getUserAccessStatus (View function)
// 32. getProposalState (View function)
// 33. getCustodians (View function)
// 34. getVaultConfig (View function)
// 35. getStochasticSeed (View function) // Added getter
// 36. getEmergencyState (View function) // Added getter
//
// Total: 36 Functions (exceeds 20)

// Note on VRF: Assumes Chainlink VRF v2 integration.
// `keyHash`, `s_vrfCoordinator`, `s_link` are standard VRF v2 state variables.
// Need to fund the contract with LINK to request randomness.

contract QuantumKeyVault is VRFConsumerBaseV2 {

    // --- State Variables ---

    // Governance & Custodians
    address[] public custodians;
    mapping(address => bool) private isCustodian;
    uint256 public quorum; // Minimum number of custodians required for proposal execution

    // Proposals
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ProposalType { AddCustodian, RemoveCustodian, ChangeQuorum, SetVerifierOracle, SetEmergencyParams, RemoveSecret, EntangleSecrets }

    struct Proposal {
        uint256 id;
        ProposalType proposalType;
        address proposer;
        uint256 creationTimestamp;
        uint256 votingDeadline; // e.g., 2 days after creation
        mapping(address => bool) voted;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;

        // Proposal-specific data
        address targetAddress; // For Add/Remove Custodian, Set Verifier/Emergency
        uint256 targetValue; // For Change Quorum, Set Emergency Params
        bytes32 secretId; // For Remove Secret
        bytes32 secretIdA; // For Entangle Secrets
        bytes32 secretIdB; // For Entangle Secrets
        bytes32 entanglementConditionHash; // For Entangle Secrets
        uint8 entanglementType; // For Entangle Secrets
    }
    Proposal[] public proposals;
    uint256 public nextProposalId = 0;

    // Secret References
    enum SecretType { ZKProofRequired, DirectAccessGranted, Entangled } // Added Entangled as a type? Or just a flag? Let's use a flag.
    struct Secret {
        bytes32 secretHash; // Hash of the actual off-chain secret/key
        SecretType secretType;
        bytes32 requiredZKProofConditionHash; // Hash representing the condition the ZK proof must verify
        address initialDirectGrantedUser; // For DirectAccessGranted type

        // Entanglement data
        bool isEntangled;
        bytes32 linkedSecretId; // The ID of the secret this one is entangled with
        bytes32 entanglementConditionHash; // Hash of the condition related to the LINKED secret
        uint8 entanglementType; // Defines how the link works (e.g., 0: Access A requires proving B's condition, 1: Access A modifies B's state, etc.)
    }
    mapping(bytes32 => Secret) private secrets;
    bytes32[] public secretIds; // To list all secrets

    // Access Control & ZK Proof Verification
    struct AccessGrant {
        uint64 expirationTimestamp; // 0 for permanent direct grant, >0 for temporary
    }
    mapping(bytes32 => mapping(address => AccessGrant)) private directAccessGrants; // secretId => user => grant

    struct ProofSubmission {
        bytes32 submittedHash; // The hash the user submitted
        bool verified; // True if the Verifier Oracle confirmed it's valid
        address verifierAddress; // Who verified it
        bytes proofVerificationData; // Optional data from the verifier
        uint256 verificationTimestamp;
    }
    // Mapping to store the LATEST submission status for a user & secret
    mapping(bytes32 => mapping(address => ProofSubmission)) private latestProofSubmissions; // secretId => user => submission

    address public verifierOracle; // Trusted address that can call notifyZKProofVerificationResult

    // "Quantum Entanglement" State
    mapping(bytes32 => bytes32) private entangledPairs; // secretIdA => secretIdB (and vice versa might be implied or stored)
    mapping(bytes32 => bytes32) private entanglementConditionHashes; // secretIdA => conditionHash for the link
    mapping(bytes32 => uint8) private entanglementTypes; // secretIdA => type of entanglement

    // "Stochastic Influence" (VRF) State
    uint64 s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private s_callbackGasLimit;
    uint16 private s_requestConfirmations;
    uint32 private s_numWords;

    mapping(uint256 => bytes32) public requestIdToSecretId; // Track which secret requested which randomness
    mapping(bytes32 => uint256[]) public secretIdToRandomWords; // Store received randomness for a secret
    mapping(bytes32 => uint256) private secretIdToLatestRandomRequestId; // Track the latest request for a secret

    // Emergency Bypass
    uint256 public minEmergencyCustodians; // Number of custodians needed to trigger/support emergency
    struct EmergencySession {
        bytes32 sessionId;
        address initiator;
        mapping(address => bool) supported;
        uint224 supportCount; // Max custodians uint160
        uint64 expirationTimestamp;
        bool active;
    }
    mapping(bytes32 => EmergencySession) private emergencySessions;
    bytes32[] public activeEmergencySessions; // To iterate active sessions

    // Pausable
    bool public paused = false;

    // --- Events ---

    // Governance
    event ProposalCreated(uint256 proposalId, ProposalType proposalType, address proposer, uint256 votingDeadline, bytes data);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, ProposalState state);
    event CustodianAdded(address newCustodian);
    event CustodianRemoved(address removedCustodian);
    event QuorumChanged(uint256 newQuorum);
    event VerifierOracleSet(address oracleAddress);
    event EmergencyParametersSet(uint256 minCustodians);

    // Secret Management
    event SecretDeposited(bytes32 secretId, SecretType secretType, address indexed initiator);
    event SecretHashUpdated(bytes32 secretId, bytes32 newHash, address indexed initiator);
    event RequiredConditionUpdated(bytes32 secretId, bytes32 newConditionHash, address indexed initiator);
    event SecretRemoved(bytes32 secretId, address indexed initiator);

    // Access Control
    event TemporaryAccessGranted(bytes32 secretId, address indexed user, uint64 expirationTimestamp, address indexed granter);
    event TemporaryAccessRevoked(bytes32 secretId, address indexed user, address indexed revoker);
    event ZKProofSubmissionAttemptRegistered(bytes32 secretId, address indexed user, bytes32 submittedHash);
    event ZKProofVerificationResultNotified(bytes32 secretId, bytes32 submittedHash, bool isValid, address indexed verifier);
    event AccessEligibilityChecked(bytes32 secretId, address indexed user, bool isEligible);

    // Entanglement
    event SecretsEntangled(bytes32 secretIdA, bytes32 secretIdB, bytes32 entanglementConditionHash, uint8 entanglementType, address indexed initiator);
    event EntangledAccessAttemptResolved(bytes32 secretIdToAccess, address indexed user, bool success);

    // Stochastic Influence (VRF)
    event StochasticInfluenceSeedRequested(bytes32 secretId, uint256 requestId);
    event StochasticInfluenceSeedReceived(bytes32 secretId, uint256 requestId, uint256[] randomWords);
    event StochasticAccessModifierApplied(bytes32 secretId, address indexed user, uint256[] randomnessUsed);

    // Emergency
    event EmergencyBypassInitiated(bytes32 sessionId, address indexed initiator, uint64 expirationTimestamp);
    event EmergencyBypassSupported(bytes32 sessionId, address indexed supporter, uint256 supportCount);
    event EmergencyOverrideTriggered(bytes32 secretId, bytes32 sessionId, address indexed initiator);
    event EmergencySessionEnded(bytes32 sessionId);

    // Utility
    event Paused(address account);
    event Unpaused(address account);

    // --- Modifiers ---

    modifier onlyCustodian() {
        require(isCustodian[msg.sender], "Not a custodian");
        _;
    }

    modifier onlyVerifierOracle() {
        require(msg.sender == verifierOracle, "Not authorized verifier oracle");
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

    modifier secretExists(bytes32 _secretId) {
        require(secrets[_secretId].secretHash != bytes32(0), "Secret does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address[] memory initialCustodians, uint256 initialQuorum, uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords)
        VRFConsumerBaseV2(vrfCoordinator)
    {
        require(initialCustodians.length > 0, "Initial custodians required");
        require(initialQuorum > 0 && initialQuorum <= initialCustodians.length, "Invalid quorum");

        custodians = initialCustodians;
        for (uint i = 0; i < initialCustodians.length; i++) {
            isCustodian[initialCustodians[i]] = true;
        }
        quorum = initialQuorum;

        // VRF Configuration
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
        s_requestConfirmations = requestConfirmations;
        s_numWords = numWords;
        // Note: s_link would typically be set here if the contract holds LINK directly,
        // or assumed to be available via the VRFCoordinator's subscription funding.

        emit QuorumChanged(quorum);
        // Emit CustodianAdded for initial custodians? Depends on preference.
    }

    // --- Governance & Configuration ---

    /**
     * @notice Proposes adding a new custodian. Requires custodian role.
     * @param newCustodian The address of the potential new custodian.
     */
    function addCustodianProposal(address newCustodian) external onlyCustodian whenNotPaused {
        require(!isCustodian[newCustodian], "Already a custodian");
        nextProposalId++;
        proposals.push(
            Proposal({
                id: nextProposalId,
                proposalType: ProposalType.AddCustodian,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: newCustodian,
                targetValue: 0,
                secretId: bytes32(0),
                secretIdA: bytes32(0),
                secretIdB: bytes32(0),
                entanglementConditionHash: bytes32(0),
                entanglementType: 0
            })
        );
        emit ProposalCreated(nextProposalId, ProposalType.AddCustodian, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(newCustodian));
    }

    /**
     * @notice Proposes removing a custodian. Requires custodian role.
     * @param custodianToRemove The address of the custodian to remove.
     */
    function removeCustodianProposal(address custodianToRemove) external onlyCustodian whenNotPaused {
        require(isCustodian[custodianToRemove], "Not an active custodian");
         require(custodians.length > quorum, "Cannot reduce custodians below quorum"); // Prevent locking out governance
        nextProposalId++;
        proposals.push(
             Proposal({
                id: nextProposalId,
                proposalType: ProposalType.RemoveCustodian,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: custodianToRemove,
                targetValue: 0,
                secretId: bytes32(0),
                secretIdA: bytes32(0),
                secretIdB: bytes32(0),
                entanglementConditionHash: bytes32(0),
                entanglementType: 0
            })
        );
        emit ProposalCreated(nextProposalId, ProposalType.RemoveCustodian, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(custodianToRemove));
    }

    /**
     * @notice Proposes changing the required quorum size. Requires custodian role.
     * @param newQuorum The proposed new quorum size.
     */
    function proposeConfigChange(uint256 newQuorum) external onlyCustodian whenNotPaused {
        require(newQuorum > 0 && newQuorum <= custodians.length, "Invalid new quorum");
        nextProposalId++;
         proposals.push(
            Proposal({
                id: nextProposalId,
                proposalType: ProposalType.ChangeQuorum,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: address(0),
                targetValue: newQuorum,
                secretId: bytes32(0),
                secretIdA: bytes32(0),
                secretIdB: bytes32(0),
                entanglementConditionHash: bytes32(0),
                entanglementType: 0
            })
        );
        emit ProposalCreated(nextProposalId, ProposalType.ChangeQuorum, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(newQuorum));
    }

     /**
     * @notice Proposes setting the trusted Verifier Oracle address. Requires custodian role.
     * @param oracleAddress The proposed address for the Verifier Oracle.
     */
    function setVerifierOracleProposal(address oracleAddress) external onlyCustodian whenNotPaused {
         nextProposalId++;
         proposals.push(
            Proposal({
                id: nextProposalId,
                proposalType: ProposalType.SetVerifierOracle,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: oracleAddress,
                targetValue: 0,
                secretId: bytes32(0),
                secretIdA: bytes32(0),
                secretIdB: bytes32(0),
                entanglementConditionHash: bytes32(0),
                entanglementType: 0
            })
        );
        emit ProposalCreated(nextProposalId, ProposalType.SetVerifierOracle, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(oracleAddress));
    }

     /**
     * @notice Proposes setting the minimum number of custodians required for emergency bypass. Requires custodian role.
     * @param minEmergencyCustodians The proposed minimum number.
     */
    function setEmergencyParametersProposal(uint256 minEmergencyCustodians) external onlyCustodian whenNotPaused {
         require(minEmergencyCustodians > 0 && minEmergencyCustodians <= custodians.length, "Invalid minimum emergency custodians");
         nextProposalId++;
         proposals.push(
            Proposal({
                id: nextProposalId,
                proposalType: ProposalType.SetEmergencyParams,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: address(0),
                targetValue: minEmergencyCustodians,
                secretId: bytes32(0),
                secretIdA: bytes32(0),
                secretIdB: bytes32(0),
                entanglementConditionHash: bytes32(0),
                entanglementType: 0
            })
        );
        emit ProposalCreated(nextProposalId, ProposalType.SetEmergencyParams, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(minEmergencyCustodians));
    }


    /**
     * @notice Casts a vote on an active proposal. Requires custodian role.
     * @param proposalId The ID of the proposal.
     * @param support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 proposalId, bool support) external onlyCustodian {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId - 1];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting deadline passed");
        require(!proposal.voted[msg.sender], "Already voted on this proposal");

        proposal.voted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Optional: Auto-execute if quorum reached immediately
        // if (proposal.votesFor >= quorum) {
        //     proposal.state = ProposalState.Succeeded;
        //     executeProposal(proposalId); // Caution: Recursive call if executeProposal fails
        // } else if (proposal.votesAgainst > custodians.length - quorum) {
        //     proposal.state = ProposalState.Failed;
        // }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Executes a proposal if it has succeeded (met quorum and deadline passed/met). Requires custodian role.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) external onlyCustodian {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId - 1];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");

        // Determine if proposal succeeded or failed
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.votingDeadline) {
             if (proposal.votesFor >= quorum) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
        require(proposal.state == ProposalState.Succeeded, "Proposal did not succeed yet");

        // Execute based on type
        if (proposal.proposalType == ProposalType.AddCustodian) {
            require(!isCustodian[proposal.targetAddress], "Already a custodian");
            isCustodian[proposal.targetAddress] = true;
            custodians.push(proposal.targetAddress);
            emit CustodianAdded(proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.RemoveCustodian) {
            require(isCustodian[proposal.targetAddress], "Not an active custodian");
             require(custodians.length > quorum, "Cannot reduce custodians below quorum"); // Re-check before execution
            isCustodian[proposal.targetAddress] = false;
            // Find and remove from the array (simple linear scan)
            for (uint i = 0; i < custodians.length; i++) {
                if (custodians[i] == proposal.targetAddress) {
                    custodians[i] = custodians[custodians.length - 1];
                    custodians.pop();
                    break;
                }
            }
            emit CustodianRemoved(proposal.targetAddress);

        } else if (proposal.proposalType == ProposalType.ChangeQuorum) {
            require(proposal.targetValue > 0 && proposal.targetValue <= custodians.length, "Invalid new quorum value for execution");
            quorum = proposal.targetValue;
            emit QuorumChanged(quorum);

        } else if (proposal.proposalType == ProposalType.SetVerifierOracle) {
            verifierOracle = proposal.targetAddress;
            emit VerifierOracleSet(verifierOracle);

         } else if (proposal.proposalType == ProposalType.SetEmergencyParams) {
            require(proposal.targetValue > 0 && proposal.targetValue <= custodians.length, "Invalid emergency parameters value for execution");
            minEmergencyCustodians = proposal.targetValue;
            emit EmergencyParametersSet(minEmergencyCustodians);

        } else if (proposal.proposalType == ProposalType.RemoveSecret) {
             require(secrets[proposal.secretId].secretHash != bytes32(0), "Secret does not exist for removal");
             delete secrets[proposal.secretId];
             // Remove from secretIds array (linear scan) - inefficient for large arrays
             for(uint i = 0; i < secretIds.length; i++){
                 if(secretIds[i] == proposal.secretId){
                     secretIds[i] = secretIds[secretIds.length - 1];
                     secretIds.pop();
                     break;
                 }
             }
             // Clean up potential entanglement links if the secret was part of one
             if(entangledPairs[proposal.secretId] != bytes32(0)) {
                 bytes32 linkedId = entangledPairs[proposal.secretId];
                 delete entangledPairs[proposal.secretId];
                 delete entangledPairs[linkedId]; // Remove the reverse link
                 delete entanglementConditionHashes[proposal.secretId];
                 delete entanglementConditionHashes[linkedId];
                 delete entanglementTypes[proposal.secretId];
                 delete entanglementTypes[linkedId];
                 // Note: The other secret's `isEntangled` flag needs manual cleanup or logic adjustment
                 // For simplicity here, we might just leave it as true or add complexity to clean it up.
                 // Let's just set its linkedSecretId to zero.
                 if(secrets[linkedId].secretHash != bytes32(0)) {
                    secrets[linkedId].linkedSecretId = bytes32(0);
                    secrets[linkedId].isEntangled = false; // Explicitly clean up
                 }
             }
             // Clean up potential direct access grants or proof submissions for this secret
             // (This would require iterating mappings, which is gas intensive.
             // A production contract would handle this differently, e.g., lazy deletion or tracking grants per-secret).
             // For this example, we'll omit explicit cleanup of grants/submissions for simplicity,
             // they will just reference a non-existent secret.

             emit SecretRemoved(proposal.secretId, msg.sender);

        } else if (proposal.proposalType == ProposalType.EntangleSecrets) {
            require(secrets[proposal.secretIdA].secretHash != bytes32(0), "Secret A does not exist for entanglement");
            require(secrets[proposal.secretIdB].secretHash != bytes32(0), "Secret B does not exist for entanglement");
            require(proposal.secretIdA != proposal.secretIdB, "Cannot entangle a secret with itself");
            require(entangledPairs[proposal.secretIdA] == bytes32(0), "Secret A already entangled");
            require(entangledPairs[proposal.secretIdB] == bytes32(0), "Secret B already entangled");

            entangledPairs[proposal.secretIdA] = proposal.secretIdB;
            entangledPairs[proposal.secretIdB] = proposal.secretIdA; // Store reverse link
            entanglementConditionHashes[proposal.secretIdA] = proposal.entanglementConditionHash;
            entanglementConditionHashes[proposal.secretIdB] = proposal.entanglementConditionHash; // Condition applies to the link, same hash
            entanglementTypes[proposal.secretIdA] = proposal.entanglementType;
            entanglementTypes[proposal.secretIdB] = proposal.entanglementType; // Entanglement type applies to the link

            secrets[proposal.secretIdA].isEntangled = true;
            secrets[proposal.secretIdA].linkedSecretId = proposal.secretIdB;
             secrets[proposal.secretIdB].isEntangled = true;
            secrets[proposal.secretIdB].linkedSecretId = proposal.secretIdA;

            emit SecretsEntangled(proposal.secretIdA, proposal.secretIdB, proposal.entanglementConditionHash, proposal.entanglementType, msg.sender);
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId, proposal.state);
    }

    // --- Secret Reference Management ---

    /**
     * @notice Deposits a reference for a secret that requires a ZK proof verification for access.
     * @param secretId A unique identifier for the secret.
     * @param secretHash The cryptographic hash of the off-chain secret/key.
     * @param requiredZKProofConditionHash A hash representing the condition/statement the ZK proof must verify.
     */
    function depositZKProofSecretReference(bytes32 secretId, bytes32 secretHash, bytes32 requiredZKProofConditionHash) external onlyCustodian whenNotPaused {
        require(secrets[secretId].secretHash == bytes32(0), "Secret ID already exists");
        require(secretHash != bytes32(0), "Secret hash cannot be zero");
        require(requiredZKProofConditionHash != bytes32(0), "Required ZK proof condition hash cannot be zero");

        secrets[secretId] = Secret({
            secretHash: secretHash,
            secretType: SecretType.ZKProofRequired,
            requiredZKProofConditionHash: requiredZKProofConditionHash,
            initialDirectGrantedUser: address(0), // Not applicable
            isEntangled: false,
            linkedSecretId: bytes32(0),
            entanglementConditionHash: bytes32(0),
            entanglementType: 0
        });
        secretIds.push(secretId);
        emit SecretDeposited(secretId, SecretType.ZKProofRequired, msg.sender);
    }

    /**
     * @notice Deposits a reference for a secret that initially grants direct access to a specific user.
     * @param secretId A unique identifier for the secret.
     * @param secretHash The cryptographic hash of the off-chain secret/key.
     * @param initialGrantedUser The user who receives direct access.
     */
    function depositDirectAccessSecretReference(bytes32 secretId, bytes32 secretHash, address initialGrantedUser) external onlyCustodian whenNotPaused {
        require(secrets[secretId].secretHash == bytes32(0), "Secret ID already exists");
        require(secretHash != bytes32(0), "Secret hash cannot be zero");
        require(initialGrantedUser != address(0), "Initial granted user cannot be zero address");

        secrets[secretId] = Secret({
            secretHash: secretHash,
            secretType: SecretType.DirectAccessGranted,
            requiredZKProofConditionHash: bytes32(0), // Not applicable for this type
            initialDirectGrantedUser: initialGrantedUser,
            isEntangled: false,
            linkedSecretId: bytes32(0),
            entanglementConditionHash: bytes32(0),
            entanglementType: 0
        });
        secretIds.push(secretId);
        directAccessGrants[secretId][initialGrantedUser] = AccessGrant({expirationTimestamp: type(uint64).max}); // Max value represents permanent grant
        emit SecretDeposited(secretId, SecretType.DirectAccessGranted, msg.sender);
    }

    /**
     * @notice Updates the stored cryptographic hash for a secret. Requires custodian role.
     * @param secretId The ID of the secret.
     * @param newSecretHash The new hash of the off-chain secret/key.
     */
    function updateSecretHash(bytes32 secretId, bytes32 newSecretHash) external onlyCustodian whenNotPaused secretExists(secretId) {
        require(newSecretHash != bytes32(0), "New secret hash cannot be zero");
        secrets[secretId].secretHash = newSecretHash;
        emit SecretHashUpdated(secretId, newSecretHash, msg.sender);
    }

    /**
     * @notice Updates the required ZK proof condition hash for a ZK-based secret. Requires custodian role.
     * @param secretId The ID of the secret.
     * @param newConditionHash The new required ZK proof condition hash.
     */
    function updateRequiredZKProofCondition(bytes32 secretId, bytes32 newConditionHash) external onlyCustodian whenNotPaused secretExists(secretId) {
         require(secrets[secretId].secretType == SecretType.ZKProofRequired, "Secret is not ZK proof required type");
         require(newConditionHash != bytes32(0), "New condition hash cannot be zero");
         secrets[secretId].requiredZKProofConditionHash = newConditionHash;
         emit RequiredConditionUpdated(secretId, newConditionHash, msg.sender);
    }

     /**
     * @notice Proposes removing a secret reference. Requires custodian role.
     * @param secretId The ID of the secret to remove.
     */
    function proposeSecretRemoval(bytes32 secretId) external onlyCustodian whenNotPaused secretExists(secretId) {
         nextProposalId++;
         proposals.push(
             Proposal({
                id: nextProposalId,
                proposalType: ProposalType.RemoveSecret,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: address(0), targetValue: 0, // N/A for this type
                secretId: secretId,
                secretIdA: bytes32(0), secretIdB: bytes32(0), // N/A
                entanglementConditionHash: bytes32(0), entanglementType: 0 // N/A
            })
         );
         emit ProposalCreated(nextProposalId, ProposalType.RemoveSecret, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(secretId));
    }

    // executeSecretRemoval is handled by the generic executeProposal function


    // --- Access Control & Verification ---

    /**
     * @notice Grants temporary direct access to a secret for a specific user. Requires custodian role.
     * This bypasses ZK proof or initial direct grant requirements for the duration.
     * @param secretId The ID of the secret.
     * @param user The user to grant temporary access to.
     * @param duration The duration in seconds for the temporary access.
     */
    function grantTemporaryDirectAccess(bytes32 secretId, address user, uint64 duration) external onlyCustodian whenNotPaused secretExists(secretId) {
        require(user != address(0), "Cannot grant access to zero address");
        uint64 expiration = uint64(block.timestamp) + duration;
        directAccessGrants[secretId][user] = AccessGrant({expirationTimestamp: expiration});
        emit TemporaryAccessGranted(secretId, user, expiration, msg.sender);
    }

     /**
     * @notice Revokes temporary direct access for a user. Requires custodian role.
     * @param secretId The ID of the secret.
     * @param user The user whose temporary access to revoke.
     */
    function revokeTemporaryDirectAccess(bytes32 secretId, address user) external onlyCustodian whenNotPaused secretExists(secretId) {
         // Check if there's an active temporary grant (permanent is max uint64)
        if (directAccessGrants[secretId][user].expirationTimestamp > 0 && directAccessGrants[secretId][user].expirationTimestamp != type(uint64).max) {
            delete directAccessGrants[secretId][user];
            emit TemporaryAccessRevoked(secretId, user, msg.sender);
        }
    }


    /**
     * @notice User registers their attempt to access a secret by providing the hash of their generated ZK proof.
     * This initiates the off-chain verification process.
     * @param secretId The ID of the secret.
     * @param submittedProofHash The hash of the ZK proof generated by the user off-chain.
     */
    function registerZKProofSubmissionAttempt(bytes32 secretId, bytes32 submittedProofHash) external whenNotPaused secretExists(secretId) {
        require(secrets[secretId].secretType == SecretType.ZKProofRequired, "Secret is not ZK proof required type");
        require(submittedProofHash != bytes32(0), "Submitted proof hash cannot be zero");

        latestProofSubmissions[secretId][msg.sender] = ProofSubmission({
            submittedHash: submittedProofHash,
            verified: false, // Initially not verified
            verifierAddress: address(0),
            proofVerificationData: bytes(""),
            verificationTimestamp: 0
        });

        emit ZKProofSubmissionAttemptRegistered(secretId, msg.sender, submittedProofHash);
    }

    /**
     * @notice Called by the trusted Verifier Oracle to report the result of an off-chain ZK proof verification.
     * Updates the status of a user's proof submission for a specific secret.
     * @param secretId The ID of the secret.
     * @param submittedProofHash The hash of the proof that was verified. Must match the latest submission.
     * @param isValid True if the off-chain verification passed.
     * @param proofVerificationData Optional data from the verifier (e.g., proof identifier, timestamp from verifier).
     */
    function notifyZKProofVerificationResult(bytes32 secretId, bytes32 submittedProofHash, bool isValid, bytes calldata proofVerificationData) external onlyVerifierOracle whenNotPaused secretExists(secretId) {
         require(secrets[secretId].secretType == SecretType.ZKProofRequired, "Secret is not ZK proof required type");

         ProofSubmission storage submission = latestProofSubmissions[secretId][msg.sender]; // Using msg.sender assumes verifier is reporting for themselves, or need user address here?
         // Let's update the function signature to include the user address
         // Function signature changed: `notifyZKProofVerificationResult(bytes32 secretId, address user, bytes32 submittedProofHash, bool isValid, bytes calldata proofVerificationData)`
         // And the require check:
         // require(submission.submittedHash == submittedProofHash, "Submitted hash does not match latest registration"); // Ensures verifier is reporting on the exact hash the user registered

        // Due to the function signature change, this function needs re-writing. Let's use the correct one.
        // The correct function is below.

        // Placeholder to avoid compilation error on the initial function.
        revert("Incorrect notifyZKProofVerificationResult signature used.");
    }

    /**
     * @notice Called by the trusted Verifier Oracle to report the result of an off-chain ZK proof verification.
     * Updates the status of a user's proof submission for a specific secret.
     * @param secretId The ID of the secret.
     * @param user The user who submitted the proof.
     * @param submittedProofHash The hash of the proof that was verified. Must match the latest submission for this user/secret.
     * @param isValid True if the off-chain verification passed against the *requiredZKProofConditionHash*.
     * @param proofVerificationData Optional data from the verifier.
     */
     function notifyZKProofVerificationResult(bytes32 secretId, address user, bytes32 submittedProofHash, bool isValid, bytes calldata proofVerificationData) external onlyVerifierOracle whenNotPaused secretExists(secretId) {
         require(secrets[secretId].secretType == SecretType.ZKProofRequired, "Secret is not ZK proof required type");
         require(user != address(0), "User address cannot be zero");

         ProofSubmission storage submission = latestProofSubmissions[secretId][user];

         // Ensure the verifier is reporting on the *latest* hash submitted by the user
         // and also that the verified hash matches the *required* condition hash for the secret.
         // The off-chain verifier should handle the check `verify(submittedProofHash, requiredZKProofConditionHash, proofVerificationData)`.
         // The oracle then reports the *result* (`isValid`).
         // So, we only need to check if the `submittedProofHash` matches what the user registered.
         // If the user registered a different hash, or no hash, we ignore this verification result.
         require(submission.submittedHash != bytes32(0), "No proof submission registered for this user/secret");
         require(submission.submittedHash == submittedProofHash, "Submitted hash does not match latest registration");

         // Update the submission status
         submission.verified = isValid;
         submission.verifierAddress = msg.sender;
         submission.proofVerificationData = proofVerificationData; // Store verification data
         submission.verificationTimestamp = block.timestamp;

         emit ZKProofVerificationResultNotified(secretId, submittedProofHash, isValid, msg.sender);
     }


    /**
     * @notice Checks if a user is eligible to access a secret based on all criteria (direct grant, temp access, verified ZK proof).
     * This is a view function; it doesn't grant access but checks eligibility.
     * @param secretId The ID of the secret.
     * @param user The user whose eligibility is being checked.
     * @return bool True if the user is eligible for access.
     */
    function checkAccessEligibility(bytes32 secretId, address user) public view secretExists(secretId) returns (bool) {
        // 1. Check for Direct or Temporary Access Grant
        AccessGrant storage grant = directAccessGrants[secretId][user];
        if (grant.expirationTimestamp > 0 && (grant.expirationTimestamp == type(uint64).max || grant.expirationTimestamp > block.timestamp)) {
            // User has a permanent or non-expired temporary direct grant
            emit AccessEligibilityChecked(secretId, user, true);
            return true;
        }

        // 2. Check ZK Proof Verification Status (Only if the secret requires ZK proof)
        if (secrets[secretId].secretType == SecretType.ZKProofRequired) {
            ProofSubmission storage submission = latestProofSubmissions[secretId][user];
            // Check if the latest submitted hash has been verified as valid
            if (submission.submittedHash != bytes32(0) && submission.verified) {
                // Optional: Add checks here based on `proofVerificationData` or timestamp if needed,
                // e.g., proof is not too old.
                 emit AccessEligibilityChecked(secretId, user, true);
                return true;
            }
        }

        // 3. No eligibility found
        emit AccessEligibilityChecked(secretId, user, false);
        return false;
    }

    // --- "Quantum Entanglement" Mechanics ---

    /**
     * @notice Proposes entangling two secrets. Requires custodian role.
     * Entanglement means access to one secret can be linked to conditions related to the other.
     * @param secretIdA The ID of the first secret.
     * @param secretIdB The ID of the second secret.
     * @param entanglementConditionHash A hash representing the condition related to secretIdB that might be required when accessing secretIdA.
     * @param entanglementType Defines the specific logic of the entanglement (e.g., 0: access A needs valid proof for B's condition, 1: accessing A consumes B's access grant).
     */
    function entangleSecretsProposal(bytes32 secretIdA, bytes32 secretIdB, bytes32 entanglementConditionHash, uint8 entanglementType) external onlyCustodian whenNotPaused secretExists(secretIdA) secretExists(secretIdB) {
        require(secretIdA != secretIdB, "Cannot entangle a secret with itself");
        require(entangledPairs[secretIdA] == bytes32(0), "Secret A already entangled");
        require(entangledPairs[secretIdB] == bytes32(0), "Secret B already entangled");
        require(entanglementConditionHash != bytes32(0), "Entanglement condition hash cannot be zero");

        nextProposalId++;
         proposals.push(
             Proposal({
                id: nextProposalId,
                proposalType: ProposalType.EntangleSecrets,
                proposer: msg.sender,
                creationTimestamp: block.timestamp,
                votingDeadline: block.timestamp + 2 days, // Example deadline
                voted: new mapping(address => bool),
                votesFor: 0,
                votesAgainst: 0,
                state: ProposalState.Active,
                targetAddress: address(0), targetValue: 0, // N/A
                secretId: bytes32(0), // N/A
                secretIdA: secretIdA,
                secretIdB: secretIdB,
                entanglementConditionHash: entanglementConditionHash,
                entanglementType: entanglementType
            })
         );
         emit ProposalCreated(nextProposalId, ProposalType.EntangleSecrets, msg.sender, proposals[nextProposalId - 1].votingDeadline, abi.encode(secretIdA, secretIdB, entanglementConditionHash, entanglementType));
    }
    // executeEntangleSecrets is handled by the generic executeProposal function

    /**
     * @notice Attempts to access a secret that might be entangled with another.
     * Requires meeting the standard access eligibility AND potentially providing
     * a proof/condition related to the linked secret based on the entanglement type.
     * This is a function that implies an *attempt* to gain access, not just check eligibility.
     * Off-chain systems would call this after preparing necessary proofs.
     * @param secretIdToAccess The ID of the secret the user wants to access.
     * @param submittedEntanglementProofHash If the secret is entangled, this is the proof hash related to the LINKED secret's condition.
     * @return bool True if the access attempt was successful.
     */
    function resolveEntangledAccessAttempt(bytes32 secretIdToAccess, bytes32 submittedEntanglementProofHash) external whenNotPaused secretExists(secretIdToAccess) returns (bool) {
        address user = msg.sender;
        bool standardEligible = checkAccessEligibility(secretIdToAccess, user);

        if (!standardEligible) {
             emit EntangledAccessAttemptResolved(secretIdToAccess, user, false);
            return false; // Not eligible by standard means
        }

        Secret storage secret = secrets[secretIdToAccess];

        if (!secret.isEntangled) {
             // Not entangled, standard eligibility is sufficient
             emit EntangledAccessAttemptResolved(secretIdToAccess, user, true);
            return true;
        }

        bytes32 linkedId = secret.linkedSecretId;
        bytes32 requiredEntanglementCondition = secret.entanglementConditionHash;
        uint8 entanglementType = secret.entanglementType;

        // --- Entanglement Logic based on type ---
        bool entanglementConditionMet = false;

        if (entanglementType == 0) {
            // Type 0: Accessing A requires proving the condition hash related to B.
            // The user must have submitted AND had verified a proof matching the requiredEntanglementCondition
            // hash linked to secretIdToAccess (which is actually the condition related to `linkedId`).
             ProofSubmission storage linkedSecretSubmission = latestProofSubmissions[linkedId][user]; // Check submission status for the *linked* secret
             if (linkedSecretSubmission.submittedHash != bytes32(0)
                && linkedSecretSubmission.submittedHash == submittedEntanglementProofHash // User provided the hash they want checked
                && linkedSecretSubmission.verified // And it was verified by the oracle
                // Optional: Also check if linkedSecretSubmission.proofVerificationData somehow confirms it met the specific requiredEntanglementCondition
                // This would require complex logic or oracle commitment structure.
                // For this example, we assume oracle verification of `submittedEntanglementProofHash` implies meeting the relevant condition.
                ) {
                    entanglementConditionMet = true;
             }
        } else if (entanglementType == 1) {
             // Type 1: Accessing A consumes a specific resource or state linked to B.
             // E.g., Requires a temporary access grant on secret B, and accessing A consumes it.
             AccessGrant storage linkedSecretGrant = directAccessGrants[linkedId][user];
             if (linkedSecretGrant.expirationTimestamp > block.timestamp) {
                 entanglementConditionMet = true;
                 // Consume the grant:
                 delete directAccessGrants[linkedId][user]; // Revoke temporary access on B
                 emit TemporaryAccessRevoked(linkedId, user, address(this)); // Contract revokes on user's behalf
             }

        }
        // Add more entanglement types here...

        if (entanglementConditionMet) {
             emit EntangledAccessAttemptResolved(secretIdToAccess, user, true);
            return true;
        } else {
             // Standard eligibility met, but entanglement condition was NOT met
            emit EntangledAccessAttemptResolved(secretIdToAccess, user, false);
            return false;
        }
    }

    /**
     * @notice Proposes entangling two secrets. Requires custodian role.
     * Entanglement means access to one secret can be linked to conditions related to the other.
     * @param secretIdA The ID of the first secret.
     * @param secretIdB The ID of the second secret.
     * @param entanglementConditionHash A hash representing the condition related to secretIdB that might be required when accessing secretIdA.
     * @param entanglementType Defines the specific logic of the entanglement (e.g., 0: access A requires valid proof for B's condition, 1: accessing A consumes B's access grant).
     */
    // Moved this up to section IV and renamed to entangleSecretsProposal

    // --- "Stochastic Influence" Mechanics (Via VRF) ---

    /**
     * @notice Requests a random seed via Chainlink VRF to introduce stochastic influence for a secret.
     * Requires the contract to be funded with LINK and have an active VRF subscription.
     * @param secretId The ID of the secret the randomness is for.
     * @return uint256 The VRF request ID.
     */
    function requestStochasticInfluenceSeed(bytes32 secretId) external onlyCustodian whenNotPaused secretExists(secretId) returns (uint256) {
         // Note: This requires the contract to have LINK balance or be funded via subscription.
         // Check VRF subscription funding levels externally.
        uint256 requestId = requestRandomWords(s_keyHash, s_subscriptionId, s_requestConfirmations, s_callbackGasLimit, s_numWords);
        requestIdToSecretId[requestId] = secretId;
        secretIdToLatestRandomRequestId[secretId] = requestId;
        emit StochasticInfluenceSeedRequested(secretId, requestId);
        return requestId;
    }

    /**
     * @notice VRF callback function. Receives random words from Chainlink VRF.
     * This function is automatically called by the VRF Coordinator. DO NOT call manually.
     * @param requestId The ID of the VRF request.
     * @param randomWords An array of random uint256 words.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        bytes32 secretId = requestIdToSecretId[requestId];
        require(secretId != bytes32(0), "VRF request ID not tracked"); // Should not happen if request was made via this contract

        // Store the received randomness linked to the secret ID
        secretIdToRandomWords[secretId] = randomWords;

        // Logic could auto-apply stochastic effect here, or require a separate call.
        // A separate call (`applyStochasticAccessModifier`) is more explicit and gas-controlled.

        emit StochasticInfluenceSeedReceived(secretId, requestId, randomWords);

        // Clean up the request ID mapping
        delete requestIdToSecretId[requestId];
    }

    /**
     * @notice Applies a stochastic (random) modifier to a secret's access based on the latest VRF seed.
     * Requires a recent random seed to be available for this secret.
     * The logic for how randomness affects access is implemented here.
     * @param secretId The ID of the secret to apply the modifier to.
     * @dev Example logic: Use randomness to grant temporary access, disable ZK check for one attempt, etc.
     */
    function applyStochasticAccessModifier(bytes32 secretId) external onlyCustodian whenNotPaused secretExists(secretId) {
        uint256[] storage randomness = secretIdToRandomWords[secretId];
        require(randomness.length > 0, "No random seed available for this secret");

        // --- Example Stochastic Logic ---
        // Use randomness[0] to decide the effect
        uint256 seed = randomness[0];

        if (seed % 10 < 3) { // 30% chance
            // Grant temporary access to a random custodian or a hardcoded address
            address targetUser = custodians[seed % custodians.length]; // Example: Pick a random custodian
            uint64 duration = uint64(seed % 86400) + 3600; // 1 hour to 1 day duration example
            directAccessGrants[secretId][targetUser] = AccessGrant({expirationTimestamp: uint64(block.timestamp) + duration});
            emit TemporaryAccessGranted(secretId, targetUser, uint64(block.timestamp) + duration, address(this));
             // In a real scenario, emit a specific event for stochastic grant

        } else if (seed % 10 == 3 && secrets[secretId].secretType == SecretType.ZKProofRequired) { // 10% chance for ZK secrets
            // Temporarily disable ZK check requirement for the next attempt by anyone
             // This would require adding state to the Secret struct or a separate mapping
             // For this example, let's just log the event indicating this happened,
             // the `checkAccessEligibility` would need to read this temporary state.
             // Adding `uint64 zkCheckDisabledUntil;` to Secret struct for this.
             secrets[secretId].zkCheckDisabledUntil = uint64(block.timestamp) + 1 hour; // Example: Disable for 1 hour
             // In a real scenario, emit a specific event for stochastic effect

        } // Add more complex logic...

        // Clear the used randomness so it can't be applied again
        delete secretIdToRandomWords[secretId];

        emit StochasticAccessModifierApplied(secretId, msg.sender, randomness); // Log the randomness used
    }


    // --- Emergency Bypass ---

    /**
     * @notice Initiates an emergency bypass session. Requires custodian role.
     * Allows custodians to collectively trigger a bypass of standard access controls.
     */
    function initiateEmergencyBypass() external onlyCustodian whenNotPaused returns(bytes32 sessionId) {
        // Generate a unique session ID
        sessionId = keccak256(abi.encodePacked(block.timestamp, msg.sender, tx.origin, block.difficulty));
        require(emergencySessions[sessionId].sessionId == bytes32(0), "Emergency session ID collision"); // Extremely unlikely

        emergencySessions[sessionId] = EmergencySession({
            sessionId: sessionId,
            initiator: msg.sender,
            supported: new mapping(address => bool),
            supportCount: 1, // Initiator counts as 1 support
            expirationTimestamp: uint64(block.timestamp) + 1 hours, // Example: Session lasts 1 hour
            active: true
        });
        emergencySessions[sessionId].supported[msg.sender] = true;
        activeEmergencySessions.push(sessionId);

        emit EmergencyBypassInitiated(sessionId, msg.sender, emergencySessions[sessionId].expirationTimestamp);
        return sessionId;
    }

    /**
     * @notice Supports an active emergency bypass session. Requires custodian role.
     * @param sessionId The ID of the emergency session to support.
     */
    function supportEmergencyBypass(bytes32 sessionId) external onlyCustodian whenNotPaused {
        EmergencySession storage session = emergencySessions[sessionId];
        require(session.sessionId != bytes32(0), "Emergency session not found");
        require(session.active, "Emergency session not active");
        require(!session.supported[msg.sender], "Already supported this session");
        require(session.supportCount < minEmergencyCustodians, "Minimum support already reached"); // Prevent supporting after threshold

        session.supported[msg.sender] = true;
        session.supportCount++;

        if (session.supportCount >= minEmergencyCustodians) {
             // Session threshold met, remains active until expiration
        }

        emit EmergencyBypassSupported(sessionId, msg.sender, session.supportCount);
    }

    /**
     * @notice Triggers the emergency override for a specific secret. Requires custodian role.
     * Can only be called if an active emergency session has met the minimum support threshold.
     * @param secretId The ID of the secret to bypass access control for.
     * @param sessionId The ID of the active emergency session.
     */
    function triggerEmergencyOverride(bytes32 secretId, bytes32 sessionId) external onlyCustodian whenNotPaused secretExists(secretId) {
        EmergencySession storage session = emergencySessions[sessionId];
        require(session.sessionId != bytes32(0), "Emergency session not found");
        require(session.active, "Emergency session not active");
        require(session.supportCount >= minEmergencyCustodians, "Minimum support not met for session");
        require(block.timestamp <= session.expirationTimestamp, "Emergency session expired");

        // Emergency bypass logic here: Grant immediate temporary access to the caller?
        // Or just log that the override was triggered for this secret?
        // A common pattern is to grant temporary access to the calling custodian.
        directAccessGrants[secretId][msg.sender] = AccessGrant({expirationTimestamp: uint64(block.timestamp) + 10 minutes}); // Example: Short bypass window
        emit TemporaryAccessGranted(secretId, msg.sender, uint64(block.timestamp) + 10 minutes, address(this)); // Indicate granted by bypass
        emit EmergencyOverrideTriggered(secretId, sessionId, msg.sender);

        // Maybe automatically end the session after one trigger, or after a set time, or after accessing specific secrets?
        // For simplicity, session lasts until expiration.
    }

    // Helper to clean up expired emergency sessions (could be called by anyone, or a custodian)
     function cleanExpiredEmergencySessions() external {
        uint256 currentIndex = 0;
        while (currentIndex < activeEmergencySessions.length) {
            bytes32 sessionId = activeEmergencySessions[currentIndex];
            EmergencySession storage session = emergencySessions[sessionId];
            if (session.expirationTimestamp <= block.timestamp) {
                // Session expired, mark inactive and remove from active list
                session.active = false;
                 emit EmergencySessionEnded(sessionId);
                // Remove from dynamic array (maintain order is not needed)
                activeEmergencySessions[currentIndex] = activeEmergencySessions[activeEmergencySessions.length - 1];
                activeEmergencySessions.pop();
            } else {
                currentIndex++;
            }
        }
     }

    // --- Utility & State Inspection ---

    /**
     * @notice Pauses sensitive operations of the contract. Requires custodian role.
     */
    function pause() external onlyCustodian whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract. Requires custodian role.
     */
    function unpause() external onlyCustodian whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Gets public details about a secret reference.
     * @param secretId The ID of the secret.
     * @return bytes32 The secret hash.
     * @return SecretType The type of the secret access.
     * @return bytes32 The required ZK proof condition hash (if applicable).
     * @return address The initial direct granted user (if applicable).
     * @return bool Is the secret entangled?
     * @return bytes32 The ID of the linked secret (if entangled).
     * @return bytes32 The entanglement condition hash (if entangled).
     * @return uint8 The entanglement type (if entangled).
     */
    function getSecretDetails(bytes32 secretId) external view secretExists(secretId)
        returns (
            bytes32 sHash, SecretType sType, bytes32 zkConditionHash,
            address initialUser, bool isEnt, bytes32 linkedId,
            bytes32 entConditionHash, uint8 entType
        )
    {
        Secret storage s = secrets[secretId];
        sHash = s.secretHash;
        sType = s.secretType;
        zkConditionHash = s.requiredZKProofConditionHash;
        initialUser = s.initialDirectGrantedUser;
        isEnt = s.isEntangled;
        linkedId = s.linkedSecretId;
        entConditionHash = s.entanglementConditionHash; // Note: This is the hash stored *for this secret*, but it refers to the condition related to the *linked* secret.
        entType = s.entanglementType; // Note: This is the type stored *for this secret*, applies to the link.
    }

    /**
     * @notice Gets the current access status for a user on a specific secret.
     * Provides details on direct/temp grants and ZK proof verification status.
     * @param secretId The ID of the secret.
     * @param user The user address.
     * @return uint64 expirationTimestamp Direct/Temp grant expiration (0 if none).
     * @return bool latestProofSubmissionVerified Is the user's latest ZK proof submission verified?
     * @return bytes32 latestSubmittedProofHash The hash the user last submitted for ZK verification.
     */
    function getUserAccessStatus(bytes32 secretId, address user) external view secretExists(secretId)
        returns (uint64 expirationTimestamp, bool latestProofSubmissionVerified, bytes32 latestSubmittedProofHash)
    {
        expirationTimestamp = directAccessGrants[secretId][user].expirationTimestamp;
        latestProofSubmissionVerified = latestProofSubmissions[secretId][user].verified;
        latestSubmittedProofHash = latestProofSubmissions[secretId][user].submittedHash;
    }

    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return ProposalState The current state of the proposal.
     * @return uint256 votesFor The number of 'for' votes.
     * @return uint256 votesAgainst The number of 'against' votes.
     * @return uint256 votingDeadline The timestamp when voting ends.
     * @return ProposalType The type of the proposal.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState, uint256, uint256, uint256, ProposalType) {
        require(proposalId > 0 && proposalId <= proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId - 1];
        return (proposal.state, proposal.votesFor, proposal.votesAgainst, proposal.votingDeadline, proposal.proposalType);
    }

    /**
     * @notice Gets the current list of custodians.
     * @return address[] An array of custodian addresses.
     */
    function getCustodians() external view returns (address[] memory) {
        return custodians;
    }

    /**
     * @notice Gets the current vault configuration parameters.
     * @return uint256 currentQuorum The required quorum size.
     * @return address currentVerifierOracle The address of the trusted Verifier Oracle.
     * @return uint256 currentMinEmergencyCustodians The minimum custodians for emergency bypass.
     */
    function getVaultConfig() external view returns (uint256 currentQuorum, address currentVerifierOracle, uint256 currentMinEmergencyCustodians) {
        return (quorum, verifierOracle, minEmergencyCustodians);
    }

     /**
     * @notice Gets the latest received stochastic seed for a secret.
     * @param secretId The ID of the secret.
     * @return uint256[] The array of random words.
     */
    function getStochasticSeed(bytes32 secretId) external view returns (uint256[] memory) {
         return secretIdToRandomWords[secretId];
    }

    /**
     * @notice Gets details about an emergency session.
     * @param sessionId The ID of the emergency session.
     * @return bool isActive Is the session currently active?
     * @return address initiator The address that initiated the session.
     * @return uint256 supportCount The current number of custodians supporting the session.
     * @return uint64 expirationTimestamp The timestamp when the session expires.
     * @return uint256 requiredSupport The minimum support needed for override (minEmergencyCustodians).
     */
     function getEmergencyState(bytes32 sessionId) external view returns (bool isActive, address initiator, uint256 supportCount, uint64 expirationTimestamp, uint256 requiredSupport) {
         EmergencySession storage session = emergencySessions[sessionId];
         if (session.sessionId == bytes32(0)) {
             return (false, address(0), 0, 0, minEmergencyCustodians);
         }
         return (session.active, session.initiator, session.supportCount, session.expirationTimestamp, minEmergencyCustodians);
     }

     // Function to get all secret IDs (can be gas intensive)
     function getAllSecretIds() external view returns (bytes32[] memory) {
         return secretIds;
     }

    // Fallback and Receive functions to allow receiving ETH (e.g., for VRF fees or accidental sends)
    receive() external payable {}
    fallback() external payable {}

     // Example function to withdraw accumulated ETH (custodian only, subject to governance)
     // In a real system, this would likely be part of a proposal/multisig withdrawal mechanism.
     function withdrawETH(address payable to, uint256 amount) external onlyCustodian whenNotPaused {
         require(address(this).balance >= amount, "Insufficient balance");
         (bool success, ) = to.call{value: amount}("");
         require(success, "ETH withdrawal failed");
     }

    // Example function to update VRF subscription (requires LINK token, should be custodian/governed)
    // This is a simplified example; real VRF subscription management is more complex.
    function updateVRFSubscription(uint64 newSubscriptionId) external onlyCustodian whenNotPaused {
        s_subscriptionId = newSubscriptionId;
        // In a real scenario, you'd need to manage the subscription lifecycle (creation, funding, cancellation)
        // usually via interacting with the VRFCoordinator contract and potentially a LINK token contract.
        // This function just updates the stored ID.
    }
}
```