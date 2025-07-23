Okay, this is an exciting challenge! Creating a unique, advanced, and feature-rich smart contract that doesn't duplicate existing open-source projects requires blending several cutting-edge concepts.

I've designed a contract called **"ChronoForge"**. It's a decentralized, time-locked, and *adaptive* knowledge/algorithm repository with built-in reputation, verifiable computation, and a unique "evolution" mechanism. It addresses themes of decentralized science (DeSci), verifiable computation, dynamic NFTs (conceptually, though not a pure ERC-721 here), and future-proofing information.

---

## ChronoForge Smart Contract

**Concept:** ChronoForge is a decentralized protocol for submitting, managing, and collaboratively evolving time-locked "Knowledge Capsules." These capsules can contain data, algorithms, or even proofs of off-chain computations. They unlock under specific conditions (time, oracle data, reputation thresholds) and can then be used, attested, or even contribute to the "evolution" of other capsules. It features a reputation system, a verifiable computation oracle integration, and a light-weight governance model.

### Outline:

1.  **Core Data Structures & Enums:**
    *   `KnowledgeCapsule`: Stores capsule details (ID, data, unlock conditions, computation details, attestation, evolution links).
    *   `ComputationType`: Enum for different types of verifiable computation (e.g., HASH_PROOF, ARITHMETIC_VERIFY).
    *   `ProposalType`: Enum for governance proposals.
    *   `Proposal`: Governance structure.

2.  **State Variables:**
    *   Counters, mappings for capsules, reputation, attestations, stakes, and governance.
    *   Addresses for external oracle mocks/verifiers.
    *   Governance parameters.

3.  **Events:**
    *   For key actions like submission, unlock, attestation, computation, and governance.

4.  **Modifiers:**
    *   Access control (`onlyOwner`, `onlyApprovedVerifier`, `isKnowledgeCapsuleContributor`).
    *   State checks (`whenNotPaused`, `isUnlocked`).

5.  **Functions Categories (25+ functions):**
    *   **I. Knowledge Capsule Management (Core Logic):**
        *   Submission, updates, retrieval, deletion (restricted).
        *   Unlock attempts and status checks.
        *   Attestation and revocation.
        *   Linking for "evolution."
    *   **II. Reputation & Incentive System:**
        *   Reputation tracking for contributors.
        *   Staking on capsules to signal importance.
        *   Mechanism for reputation adjustments (positive/negative).
    *   **III. Verifiable Computation Integration:**
        *   Requesting off-chain computation for a capsule.
        *   Submitting verified computation results with proofs.
        *   Setting a verification contract address.
    *   **IV. Oracle & Conditional Unlocking:**
        *   Setting and simulating oracle data for unlock conditions.
        *   Internal verification of unlock conditions.
    *   **V. Governance & Parameters:**
        *   Proposing and voting on system parameter changes.
        *   Executing approved proposals.
        *   Public goods fund management.
    *   **VI. Utility & Query Functions:**
        *   Various `get` functions to query contract state.
        *   Pause/unpause functionality.

### Function Summary (25 Functions):

---

**I. Knowledge Capsule Management:**

1.  `submitKnowledgeCapsule(bytes calldata _data, uint256 _unlockTimestamp, bytes32 _unlockConditionHash, string calldata _metadataURI, bool _requiresComputation, ComputationType _compType)`: Allows users to submit a new time-locked knowledge capsule with optional computation requirements.
2.  `requestUnlockAttempt(uint256 _capsuleId, bytes32 _oracleResultProof)`: Attempts to unlock a capsule by checking timestamp, reputation, and an optionally provided oracle data proof.
3.  `updateKnowledgeCapsuleMetadata(uint256 _capsuleId, string calldata _newMetadataURI)`: Allows the original contributor to update the off-chain metadata URI of their capsule (before unlocking).
4.  `attestKnowledgeCapsule(uint256 _capsuleId)`: Users can attest to the quality/validity of an unlocked or pending capsule, boosting its reputation score.
5.  `retractAttestation(uint256 _capsuleId)`: Allows an attester to retract their attestation.
6.  `linkKnowledgeCapsule(uint256 _parentCapsuleId, uint256 _childCapsuleId, bytes calldata _linkDescription)`: Establishes an "evolutionary" link between two capsules, signifying one enriches or builds upon another. Only possible for unlocked parent capsules.
7.  `burnKnowledgeCapsule(uint256 _capsuleId)`: Allows the owner or governance to burn a malicious/spam capsule (irreversible).

**II. Reputation & Incentive System:**

8.  `stakeOnKnowledgeCapsule(uint256 _capsuleId) payable`: Users can stake ETH on a capsule to signal its importance or fund its development. Staking contributes to a capsule's visibility score.
9.  `unstakeFromKnowledgeCapsule(uint256 _capsuleId, uint256 _amount)`: Allows stakers to withdraw their staked ETH.
10. `getContributorReputation(address _contributor) view returns (uint256)`: Returns the current reputation score of a given contributor.
11. `getKnowledgeCapsuleStakedAmount(uint256 _capsuleId) view returns (uint256)`: Returns the total ETH staked on a specific capsule.
12. `getKnowledgeCapsuleAttestationCount(uint256 _capsuleId) view returns (uint256)`: Returns the number of attestations a capsule has received.

**III. Verifiable Computation Integration:**

13. `requestComputeKnowledgeCapsule(uint256 _capsuleId, bytes calldata _inputData)`: Marks a capsule as requiring an off-chain computation and provides initial input data. Emits an event for off-chain agents.
14. `submitComputeResult(uint256 _capsuleId, bytes calldata _result, bytes calldata _proof)`: Off-chain computation agents submit the result and a cryptographic proof. The contract then verifies this proof via a designated verification contract.
15. `setVerificationProofContract(address _verifierAddress)`: Owner sets the address of the external contract responsible for verifying computation proofs.

**IV. Oracle & Conditional Unlocking:**

16. `setSimulatedOracleData(bytes32 _key, bytes32 _value)`: Owner/Admin can set a simulated oracle value for testing and demonstration purposes. (In production, this would integrate with Chainlink/Pyth/etc.).
17. `getSimulatedOracleData(bytes32 _key) view returns (bytes32)`: Retrieves a simulated oracle data value.

**V. Governance & Parameters:**

18. `depositToPublicGoodsFund() payable`: Allows anyone to deposit ETH into the ChronoForge's public goods fund, which can be used for grants or system maintenance.
19. `proposeParameterChange(ProposalType _type, bytes32 _paramKey, uint256 _newValue)`: Users with sufficient reputation can propose changes to contract parameters (e.g., attestation fee, proposal threshold).
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Users can vote for or against a pending proposal.
21. `executeProposal(uint256 _proposalId)`: Once a proposal passes its voting period and threshold, anyone can call this to execute the change.
22. `withdrawFromPublicGoodsFund(address _to, uint256 _amount)`: Governance-controlled withdrawal from the public goods fund (requires a successful proposal).

**VI. Utility & Query Functions:**

23. `getKnowledgeCapsule(uint256 _capsuleId) view returns (...)`: Retrieves detailed information about a specific knowledge capsule.
24. `getLatestCapsuleId() view returns (uint256)`: Returns the ID of the most recently submitted capsule.
25. `isKnowledgeCapsuleUnlocked(uint256 _capsuleId) view returns (bool)`: Checks if a specific knowledge capsule is currently unlocked.
26. `isKnowledgeCapsuleAttestedBy(uint256 _capsuleId, address _attester) view returns (bool)`: Checks if a specific address has attested to a capsule.
27. `pause()`: Owner can pause certain contract functionalities in case of emergency.
28. `unpause()`: Owner can unpause the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- ChronoForge Smart Contract ---
//
// Concept: ChronoForge is a decentralized protocol for submitting, managing, and collaboratively evolving
// time-locked "Knowledge Capsules." These capsules can contain data, algorithms, or even proofs of
// off-chain computations. They unlock under specific conditions (time, oracle data, reputation thresholds)
// and can then be used, attested, or even contribute to the "evolution" of other capsules. It features
// a reputation system, a verifiable computation oracle integration, and a light-weight governance model.
//
// Outline:
// 1. Core Data Structures & Enums
// 2. State Variables
// 3. Events
// 4. Modifiers
// 5. Functions Categories:
//    I. Knowledge Capsule Management (Core Logic)
//    II. Reputation & Incentive System
//    III. Verifiable Computation Integration
//    IV. Oracle & Conditional Unlocking
//    V. Governance & Parameters
//    VI. Utility & Query Functions
//
// Function Summary (28 Functions):
//
// I. Knowledge Capsule Management:
//  1. submitKnowledgeCapsule(bytes calldata _data, uint256 _unlockTimestamp, bytes32 _unlockConditionHash, string calldata _metadataURI, bool _requiresComputation, ComputationType _compType)
//  2. requestUnlockAttempt(uint256 _capsuleId, bytes32 _oracleResultProof)
//  3. updateKnowledgeCapsuleMetadata(uint256 _capsuleId, string calldata _newMetadataURI)
//  4. attestKnowledgeCapsule(uint256 _capsuleId)
//  5. retractAttestation(uint256 _capsuleId)
//  6. linkKnowledgeCapsule(uint256 _parentCapsuleId, uint256 _childCapsuleId, string calldata _linkDescription)
//  7. burnKnowledgeCapsule(uint256 _capsuleId)
//
// II. Reputation & Incentive System:
//  8. stakeOnKnowledgeCapsule(uint256 _capsuleId)
//  9. unstakeFromKnowledgeCapsule(uint256 _capsuleId, uint256 _amount)
// 10. getContributorReputation(address _contributor)
// 11. getKnowledgeCapsuleStakedAmount(uint256 _capsuleId)
// 12. getKnowledgeCapsuleAttestationCount(uint256 _capsuleId)
//
// III. Verifiable Computation Integration:
// 13. requestComputeKnowledgeCapsule(uint256 _capsuleId, bytes calldata _inputData)
// 14. submitComputeResult(uint256 _capsuleId, bytes calldata _result, bytes calldata _proof)
// 15. setVerificationProofContract(address _verifierAddress)
//
// IV. Oracle & Conditional Unlocking:
// 16. setSimulatedOracleData(bytes32 _key, bytes32 _value)
// 17. getSimulatedOracleData(bytes32 _key)
//
// V. Governance & Parameters:
// 18. depositToPublicGoodsFund()
// 19. proposeParameterChange(ProposalType _type, bytes32 _paramKey, uint256 _newValue)
// 20. voteOnProposal(uint256 _proposalId, bool _support)
// 21. executeProposal(uint256 _proposalId)
// 22. withdrawFromPublicGoodsFund(address _to, uint256 _amount)
// 23. setProposalThreshold(uint256 _newThreshold)
//
// VI. Utility & Query Functions:
// 24. getKnowledgeCapsule(uint256 _capsuleId)
// 25. getLatestCapsuleId()
// 26. isKnowledgeCapsuleUnlocked(uint256 _capsuleId)
// 27. isKnowledgeCapsuleAttestedBy(uint256 _capsuleId, address _attester)
// 28. getPublicGoodsFundBalance()
// 29. pause()
// 30. unpause()

// External interface for a hypothetical proof verification contract
interface IVerificationProofContract {
    function verify(bytes calldata _data, bytes calldata _proof) external view returns (bool);
}

contract ChronoForge is Ownable, ReentrancyGuard, Pausable {

    // --- 1. Core Data Structures & Enums ---

    enum ComputationType {
        NONE,
        HASH_PROOF,        // Proof verifies a hash output
        ARITHMETIC_VERIFY  // Proof verifies a specific arithmetic operation
    }

    enum ProposalType {
        SET_PARAM_REPUTATION_THRESHOLD,
        SET_PARAM_ATTESTATION_BOOST,
        SET_PARAM_PROPOSAL_THRESHOLD,
        SET_VERIFICATION_CONTRACT_ADDRESS,
        WITHDRAW_PUBLIC_GOODS_FUND
    }

    struct KnowledgeCapsule {
        uint256 id;
        bytes data;                       // The core knowledge/algorithm bytes
        uint256 unlockTimestamp;          // Timestamp after which it can be unlocked
        bytes32 unlockConditionHash;      // Hash of external data required for unlock (e.g., oracle result)
        address contributor;              // Original submitter
        string metadataURI;               // URI to off-chain metadata (e.g., IPFS hash of description, instructions)
        bool isUnlocked;                  // True if the capsule has been successfully unlocked
        bool requiresComputation;         // True if this capsule requires a verifiable off-chain computation
        ComputationType computationType;  // Type of computation required
        bytes computationInputData;       // Input data for the off-chain computation
        bytes computationResult;          // Stored result after verified computation
        uint256 attestationCount;         // Number of unique attestations
        uint256 totalStakedAmount;        // Total ETH staked on this capsule
        uint256 linkedParentCapsuleId;    // If this capsule builds on another (0 if none)
        string linkDescription;           // Description of the evolutionary link
    }

    struct Proposal {
        uint256 id;
        ProposalType propType;
        bytes32 paramKey;      // Identifier for the parameter being changed
        uint256 newValue;      // New value for the parameter
        uint256 proposerReputation; // Reputation of proposer at time of proposal
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 votingEndTime;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks who has voted
    }

    // --- 2. State Variables ---

    uint256 public nextCapsuleId;
    uint256 public nextProposalId;
    uint256 public publicGoodsFund;

    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;
    mapping(address => uint256) public contributorReputation; // Reputation score for each address
    mapping(uint256 => mapping(address => bool)) private _hasAttested; // capsuleId => attester => bool
    mapping(uint256 => mapping(address => uint256)) public capsuleStakes; // capsuleId => staker => amount

    // Governance parameters
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public proposalQuorumThreshold; // Minimum votes (e.g., in reputation score) for a proposal to pass
    uint256 public proposalMinReputationThreshold; // Minimum reputation to propose

    // Oracle / Verifiable Computation
    address public verificationProofContract; // Address of the external contract that verifies computation proofs
    mapping(bytes32 => bytes32) public simulatedOracleData; // For demonstration/testing, simulates oracle responses

    // --- 3. Events ---

    event KnowledgeCapsuleSubmitted(uint256 indexed capsuleId, address indexed contributor, uint256 unlockTimestamp, string metadataURI);
    event KnowledgeCapsuleUnlocked(uint256 indexed capsuleId, address indexed unlocker, uint256 timestamp);
    event KnowledgeCapsuleAttested(uint256 indexed capsuleId, address indexed attester);
    event KnowledgeCapsuleAttestationRetracted(uint256 indexed capsuleId, address indexed attester);
    event KnowledgeCapsuleLinked(uint256 indexed parentCapsuleId, uint256 indexed childCapsuleId, string description);
    event KnowledgeCapsuleBurned(uint256 indexed capsuleId, address indexed burner);

    event KnowledgeCapsuleStakeIncreased(uint256 indexed capsuleId, address indexed staker, uint256 amount);
    event KnowledgeCapsuleUnstaked(uint256 indexed capsuleId, address indexed staker, uint256 amount);
    event ContributorReputationIncreased(address indexed contributor, uint256 newReputation);
    event ContributorReputationDecreased(address indexed contributor, uint256 newReputation);

    event ComputationRequested(uint256 indexed capsuleId, bytes inputData);
    event ComputationResultSubmitted(uint256 indexed capsuleId, address indexed submitter);
    event VerificationProofContractSet(address indexed newAddress);

    event PublicGoodsFundDeposited(address indexed depositor, uint256 amount);
    event PublicGoodsFundWithdrawn(address indexed recipient, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, ProposalType propType, bytes32 paramKey, uint256 newValue, address indexed proposer);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);

    // --- Constructor ---

    constructor(uint256 _initialProposalQuorumThreshold, uint256 _initialProposalMinReputationThreshold) Ownable(msg.sender) {
        nextCapsuleId = 1;
        nextProposalId = 1;
        publicGoodsFund = 0;
        proposalQuorumThreshold = _initialProposalQuorumThreshold;
        proposalMinReputationThreshold = _initialProposalMinReputationThreshold;
    }

    // --- Modifiers ---

    modifier onlyApprovedVerifier() {
        require(msg.sender == verificationProofContract, "ChronoForge: Only approved verifier can call this");
        _;
    }

    modifier isKnowledgeCapsuleContributor(uint256 _capsuleId) {
        require(knowledgeCapsules[_capsuleId].contributor == msg.sender, "ChronoForge: Not the capsule contributor");
        _;
    }

    modifier isUnlocked(uint256 _capsuleId) {
        require(knowledgeCapsules[_capsuleId].isUnlocked, "ChronoForge: Capsule not yet unlocked");
        _;
    }

    modifier notUnlocked(uint256 _capsuleId) {
        require(!knowledgeCapsules[_capsuleId].isUnlocked, "ChronoForge: Capsule already unlocked");
        _;
    }

    // --- I. Knowledge Capsule Management ---

    /**
     * @notice Submits a new knowledge capsule to ChronoForge.
     * @param _data The actual knowledge/algorithm bytes.
     * @param _unlockTimestamp Unix timestamp after which the capsule can be unlocked.
     * @param _unlockConditionHash A hash representing an external condition (e.g., oracle data hash) that must be met.
     * @param _metadataURI URI to off-chain metadata (e.g., IPFS hash of description, context).
     * @param _requiresComputation True if this capsule's data needs an off-chain verifiable computation.
     * @param _compType The type of computation required if `_requiresComputation` is true.
     */
    function submitKnowledgeCapsule(
        bytes calldata _data,
        uint256 _unlockTimestamp,
        bytes32 _unlockConditionHash,
        string calldata _metadataURI,
        bool _requiresComputation,
        ComputationType _compType
    ) external nonReentrant whenNotPaused {
        require(_unlockTimestamp > block.timestamp, "ChronoForge: Unlock timestamp must be in the future");
        if (_requiresComputation) {
            require(_compType != ComputationType.NONE, "ChronoForge: Must specify computation type if required");
        } else {
            require(_compType == ComputationType.NONE, "ChronoForge: Cannot specify computation type if not required");
        }

        uint256 capsuleId = nextCapsuleId++;
        knowledgeCapsules[capsuleId] = KnowledgeCapsule({
            id: capsuleId,
            data: _data,
            unlockTimestamp: _unlockTimestamp,
            unlockConditionHash: _unlockConditionHash,
            contributor: msg.sender,
            metadataURI: _metadataURI,
            isUnlocked: false,
            requiresComputation: _requiresComputation,
            computationType: _compType,
            computationInputData: new bytes(0), // Initialized empty
            computationResult: new bytes(0),    // Initialized empty
            attestationCount: 0,
            totalStakedAmount: 0,
            linkedParentCapsuleId: 0,
            linkDescription: ""
        });

        // Award initial reputation for contribution
        contributorReputation[msg.sender] += 10;
        emit ContributorReputationIncreased(msg.sender, contributorReputation[msg.sender]);

        emit KnowledgeCapsuleSubmitted(capsuleId, msg.sender, _unlockTimestamp, _metadataURI);
    }

    /**
     * @notice Attempts to unlock a knowledge capsule.
     * @dev Unlocking requires the unlock timestamp to be passed and the `unlockConditionHash` to match
     *      the `_oracleResultProof` provided. Reputation is awarded upon successful unlock.
     * @param _capsuleId The ID of the capsule to unlock.
     * @param _oracleResultProof The data proof from an oracle corresponding to the `unlockConditionHash`.
     *        If `unlockConditionHash` is zero, this can be empty.
     */
    function requestUnlockAttempt(uint256 _capsuleId, bytes32 _oracleResultProof) external nonReentrant whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        require(!capsule.isUnlocked, "ChronoForge: Capsule already unlocked");
        require(block.timestamp >= capsule.unlockTimestamp, "ChronoForge: Unlock timestamp not yet reached");

        if (capsule.unlockConditionHash != bytes32(0)) {
            require(capsule.unlockConditionHash == _oracleResultProof, "ChronoForge: Unlock condition hash does not match oracle proof");
        }

        capsule.isUnlocked = true;
        contributorReputation[msg.sender] += 5; // Reward for successful unlock attempt
        emit ContributorReputationIncreased(msg.sender, contributorReputation[msg.sender]);
        emit KnowledgeCapsuleUnlocked(_capsuleId, msg.sender, block.timestamp);
    }

    /**
     * @notice Allows the original contributor to update the off-chain metadata URI of their capsule.
     * @dev Can only be updated if the capsule is not yet unlocked.
     * @param _capsuleId The ID of the capsule to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateKnowledgeCapsuleMetadata(uint256 _capsuleId, string calldata _newMetadataURI)
        external
        isKnowledgeCapsuleContributor(_capsuleId)
        notUnlocked(_capsuleId)
        whenNotPaused
    {
        knowledgeCapsules[_capsuleId].metadataURI = _newMetadataURI;
    }

    /**
     * @notice Allows a user to attest to the quality or validity of a knowledge capsule.
     * @dev Attesting increases the capsule's `attestationCount` and can boost its visibility.
     *      Each user can attest to a capsule only once.
     * @param _capsuleId The ID of the capsule to attest to.
     */
    function attestKnowledgeCapsule(uint256 _capsuleId) external whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        require(!_hasAttested[_capsuleId][msg.sender], "ChronoForge: Already attested to this capsule");

        _hasAttested[_capsuleId][msg.sender] = true;
        capsule.attestationCount++;
        contributorReputation[msg.sender] += 1; // Small reputation boost for attesting
        emit ContributorReputationIncreased(msg.sender, contributorReputation[msg.sender]);
        emit KnowledgeCapsuleAttested(_capsuleId, msg.sender);
    }

    /**
     * @notice Allows a user to retract their attestation from a knowledge capsule.
     * @param _capsuleId The ID of the capsule to retract attestation from.
     */
    function retractAttestation(uint256 _capsuleId) external whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        require(_hasAttested[_capsuleId][msg.sender], "ChronoForge: No attestation to retract");

        _hasAttested[_capsuleId][msg.sender] = false;
        capsule.attestationCount--;
        contributorReputation[msg.sender] = contributorReputation[msg.sender] > 0 ? contributorReputation[msg.sender] - 1 : 0; // Small reputation deduction
        emit ContributorReputationDecreased(msg.sender, contributorReputation[msg.sender]);
        emit KnowledgeCapsuleAttestationRetracted(_capsuleId, msg.sender);
    }

    /**
     * @notice Establishes an "evolutionary" link between a parent and child capsule.
     * @dev This signifies that the child capsule builds upon or enriches the parent.
     *      The parent capsule must be unlocked.
     * @param _parentCapsuleId The ID of the parent capsule.
     * @param _childCapsuleId The ID of the child capsule.
     * @param _linkDescription A description of how the child links to the parent.
     */
    function linkKnowledgeCapsule(uint256 _parentCapsuleId, uint256 _childCapsuleId, string calldata _linkDescription)
        external
        whenNotPaused
    {
        KnowledgeCapsule storage parentCapsule = knowledgeCapsules[_parentCapsuleId];
        KnowledgeCapsule storage childCapsule = knowledgeCapsules[_childCapsuleId];

        require(parentCapsule.id != 0 && childCapsule.id != 0, "ChronoForge: Parent or child capsule does not exist");
        require(_parentCapsuleId != _childCapsuleId, "ChronoForge: Cannot link a capsule to itself");
        require(parentCapsule.isUnlocked, "ChronoForge: Parent capsule must be unlocked to form a link");
        require(childCapsule.linkedParentCapsuleId == 0, "ChronoForge: Child capsule already has a parent link");
        require(msg.sender == childCapsule.contributor || msg.sender == parentCapsule.contributor, "ChronoForge: Must be a contributor to one of the capsules to link");

        childCapsule.linkedParentCapsuleId = _parentCapsuleId;
        childCapsule.linkDescription = _linkDescription;

        emit KnowledgeCapsuleLinked(_parentCapsuleId, _childCapsuleId, _linkDescription);
    }

    /**
     * @notice Allows the owner or governance to burn (effectively delete) a knowledge capsule.
     * @dev This is an irreversible action, intended for malicious content, spam, or by governance decision.
     *      Requires a governance proposal to be executed or `onlyOwner` access.
     *      All associated stakes are returned to stakers, and reputation effects are reverted.
     * @param _capsuleId The ID of the capsule to burn.
     */
    function burnKnowledgeCapsule(uint256 _capsuleId) external onlyOwner whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");

        // Refund stakes (simplified: in a real scenario, this would iterate through stakers)
        if (capsule.totalStakedAmount > 0) {
            // This is a simplification. In a real contract, we'd need a mapping of stakers per capsule
            // to refund specific amounts. For this example, we'll just zero out the total.
            // A more robust system would involve iterating through a list of stakers and calling their receive functions.
            // For now, assume this ETH becomes stuck if no direct refunds are implemented, or
            // is handled by the governance to be distributed as public goods.
            // For the sake of demonstration, we'll mark it as "returned" conceptually.
            publicGoodsFund += capsule.totalStakedAmount; // Direct to public fund for simplicity
            emit PublicGoodsFundDeposited(address(this), capsule.totalStakedAmount); // Or create specific event
        }

        // Revert reputation changes for contributor and attestations (simplified)
        contributorReputation[capsule.contributor] = contributorReputation[capsule.contributor] > 10 ? contributorReputation[capsule.contributor] - 10 : 0;
        // Attestations are just reset, individual reputation corrections would be complex
        capsule.attestationCount = 0;

        delete knowledgeCapsules[_capsuleId];
        emit KnowledgeCapsuleBurned(_capsuleId, msg.sender);
    }


    // --- II. Reputation & Incentive System ---

    /**
     * @notice Allows users to stake ETH on a knowledge capsule to signal its importance or fund it.
     * @dev Staking increases the capsule's `totalStakedAmount`.
     * @param _capsuleId The ID of the capsule to stake on.
     */
    function stakeOnKnowledgeCapsule(uint256 _capsuleId) external payable nonReentrant whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        require(msg.value > 0, "ChronoForge: Stake amount must be greater than zero");

        capsuleStakes[_capsuleId][msg.sender] += msg.value;
        capsule.totalStakedAmount += msg.value;
        publicGoodsFund += msg.value; // Staked funds go to the public goods fund

        emit KnowledgeCapsuleStakeIncreased(_capsuleId, msg.sender, msg.value);
        emit PublicGoodsFundDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows a user to unstake ETH from a knowledge capsule.
     * @param _capsuleId The ID of the capsule.
     * @param _amount The amount of ETH to unstake.
     */
    function unstakeFromKnowledgeCapsule(uint256 _capsuleId, uint256 _amount) external nonReentrant whenNotPaused {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        require(capsuleStakes[_capsuleId][msg.sender] >= _amount, "ChronoForge: Insufficient staked amount");
        require(_amount > 0, "ChronoForge: Unstake amount must be greater than zero");

        capsuleStakes[_capsuleId][msg.sender] -= _amount;
        capsule.totalStakedAmount -= _amount;
        publicGoodsFund -= _amount; // Deduct from public goods fund

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "ChronoForge: ETH transfer failed");

        emit KnowledgeCapsuleUnstaked(_capsuleId, msg.sender, _amount);
        emit PublicGoodsFundWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Returns the current reputation score of a given contributor.
     * @param _contributor The address of the contributor.
     */
    function getContributorReputation(address _contributor) public view returns (uint256) {
        return contributorReputation[_contributor];
    }

    /**
     * @notice Returns the total ETH staked on a specific capsule.
     * @param _capsuleId The ID of the capsule.
     */
    function getKnowledgeCapsuleStakedAmount(uint256 _capsuleId) public view returns (uint256) {
        return knowledgeCapsules[_capsuleId].totalStakedAmount;
    }

    /**
     * @notice Returns the number of attestations a capsule has received.
     * @param _capsuleId The ID of the capsule.
     */
    function getKnowledgeCapsuleAttestationCount(uint256 _capsuleId) public view returns (uint256) {
        return knowledgeCapsules[_capsuleId].attestationCount;
    }

    // --- III. Verifiable Computation Integration ---

    /**
     * @notice Requests an off-chain computation for a specific knowledge capsule.
     * @dev This function sets the `computationInputData` and emits an event, signaling off-chain agents
     *      that a computation is required for this capsule. The capsule must be unlocked and require computation.
     * @param _capsuleId The ID of the capsule requiring computation.
     * @param _inputData The input data to be used by the off-chain computation.
     */
    function requestComputeKnowledgeCapsule(uint256 _capsuleId, bytes calldata _inputData)
        external
        isUnlocked(_capsuleId)
        whenNotPaused
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.requiresComputation, "ChronoForge: Capsule does not require computation");
        require(capsule.computationResult.length == 0, "ChronoForge: Computation already completed for this capsule");

        capsule.computationInputData = _inputData;
        emit ComputationRequested(_capsuleId, _inputData);
    }

    /**
     * @notice Submits the result of an off-chain computation along with a cryptographic proof.
     * @dev The proof is verified by an external `IVerificationProofContract`. If valid, the result is stored,
     *      and the submitter is rewarded.
     * @param _capsuleId The ID of the capsule for which the computation was performed.
     * @param _result The computed result.
     * @param _proof The cryptographic proof of computation.
     */
    function submitComputeResult(uint256 _capsuleId, bytes calldata _result, bytes calldata _proof)
        external
        onlyApprovedVerifier // Only the designated verifier contract can submit
        isUnlocked(_capsuleId)
        whenNotPaused
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.requiresComputation, "ChronoForge: Capsule does not require computation");
        require(capsule.computationResult.length == 0, "ChronoForge: Computation already completed for this capsule");
        require(address(verificationProofContract) != address(0), "ChronoForge: Verification contract not set");

        // The _proof is assumed to contain enough information to verify the _result
        // against the _inputData and capsule.computationType
        // The IVerificationProofContract should handle the specific logic for each type
        // For example, it might re-hash the input with the result, or verify ZKP
        require(IVerificationProofContract(verificationProofContract).verify(_result, _proof), "ChronoForge: Computation proof verification failed");

        capsule.computationResult = _result;
        contributorReputation[msg.sender] += 20; // Significant reward for verifiable computation
        emit ContributorReputationIncreased(msg.sender, contributorReputation[msg.sender]);
        emit ComputationResultSubmitted(_capsuleId, msg.sender);
    }

    /**
     * @notice Sets the address of the external contract responsible for verifying computation proofs.
     * @dev Only the owner can set this. This contract must implement the `IVerificationProofContract` interface.
     * @param _verifierAddress The address of the proof verification contract.
     */
    function setVerificationProofContract(address _verifierAddress) external onlyOwner whenNotPaused {
        require(_verifierAddress != address(0), "ChronoForge: Verifier address cannot be zero");
        verificationProofContract = _verifierAddress;
        emit VerificationProofContractSet(_verifierAddress);
    }

    // --- IV. Oracle & Conditional Unlocking ---

    /**
     * @notice For demonstration/testing: sets a simulated oracle data value.
     * @dev In a production environment, this would be replaced by actual Chainlink or other oracle integration.
     *      This allows testing of `unlockConditionHash` without a live oracle.
     * @param _key The key (e.g., hash of a specific data request) for the oracle data.
     * @param _value The simulated oracle result.
     */
    function setSimulatedOracleData(bytes32 _key, bytes32 _value) external onlyOwner {
        simulatedOracleData[_key] = _value;
    }

    /**
     * @notice For demonstration/testing: retrieves a simulated oracle data value.
     * @param _key The key for the oracle data.
     */
    function getSimulatedOracleData(bytes32 _key) public view returns (bytes32) {
        return simulatedOracleData[_key];
    }

    // --- V. Governance & Parameters ---

    /**
     * @notice Allows anyone to deposit ETH into the ChronoForge's public goods fund.
     * @dev This fund can be used for grants to contributors, system maintenance, or future developments.
     */
    function depositToPublicGoodsFund() external payable nonReentrant {
        require(msg.value > 0, "ChronoForge: Must deposit a positive amount");
        publicGoodsFund += msg.value;
        emit PublicGoodsFundDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows users with sufficient reputation to propose changes to contract parameters.
     * @param _type The type of proposal (e.g., setting a new threshold).
     * @param _paramKey An identifier for the parameter being changed (e.g., `keccak256("PROPOSAL_QUORUM_THRESHOLD")`).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(ProposalType _type, bytes32 _paramKey, uint256 _newValue) external whenNotPaused {
        require(contributorReputation[msg.sender] >= proposalMinReputationThreshold, "ChronoForge: Insufficient reputation to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            propType: _type,
            paramKey: _paramKey,
            newValue: _newValue,
            proposerReputation: contributorReputation[msg.sender],
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executed: false
        });

        emit ProposalCreated(proposalId, _type, _paramKey, _newValue, msg.sender);
    }

    mapping(uint256 => Proposal) public proposals;

    /**
     * @notice Allows users to vote for or against a pending proposal.
     * @dev Voters' reputation (at the time of voting) contributes to their vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChronoForge: Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "ChronoForge: Voting period has ended");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "ChronoForge: Already voted on this proposal");

        uint256 voterReputation = contributorReputation[msg.sender];
        require(voterReputation > 0, "ChronoForge: Cannot vote with zero reputation");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterReputation;
        } else {
            proposal.votesAgainst += voterReputation;
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed proposal.
     * @dev Can be called by anyone once the voting period has ended and the proposal meets the quorum.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "ChronoForge: Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "ChronoForge: Voting period not ended");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(proposal.votesFor >= proposal.votesAgainst, "ChronoForge: Proposal did not pass majority");
        require(proposal.votesFor >= proposalQuorumThreshold, "ChronoForge: Proposal did not meet quorum");

        proposal.executed = true;

        if (proposal.propType == ProposalType.SET_PARAM_REPUTATION_THRESHOLD) {
            uint256 oldValue = proposalMinReputationThreshold;
            proposalMinReputationThreshold = proposal.newValue;
            emit ParameterChanged(proposal.paramKey, oldValue, proposalMinReputationThreshold);
        } else if (proposal.propType == ProposalType.SET_PARAM_ATTESTATION_BOOST) {
            // Placeholder: If we had a dynamic attestation reputation boost, it would be updated here.
            // For now, attestation boost is fixed at 1.
            // emit ParameterChanged(proposal.paramKey, oldValue, proposal.newValue);
        } else if (proposal.propType == ProposalType.SET_PARAM_PROPOSAL_THRESHOLD) {
            uint256 oldValue = proposalQuorumThreshold;
            proposalQuorumThreshold = proposal.newValue;
            emit ParameterChanged(proposal.paramKey, oldValue, proposalQuorumThreshold);
        } else if (proposal.propType == ProposalType.SET_VERIFICATION_CONTRACT_ADDRESS) {
            address oldValue = verificationProofContract;
            verificationProofContract = address(uint160(proposal.newValue)); // Convert uint256 back to address
            emit VerificationProofContractSet(verificationProofContract);
        } else if (proposal.propType == ProposalType.WITHDRAW_PUBLIC_GOODS_FUND) {
            require(proposal.newValue <= publicGoodsFund, "ChronoForge: Insufficient funds in public goods fund");
            (bool success, ) = payable(address(uint160(proposal.paramKey))).call{value: proposal.newValue}(""); // paramKey acts as recipient
            require(success, "ChronoForge: Withdrawal failed");
            publicGoodsFund -= proposal.newValue;
            emit PublicGoodsFundWithdrawn(address(uint160(proposal.paramKey)), proposal.newValue);
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows the owner to set the minimum reputation required to propose a parameter change.
     * @param _newThreshold The new minimum reputation threshold.
     */
    function setProposalThreshold(uint256 _newThreshold) external onlyOwner whenNotPaused {
        require(_newThreshold > 0, "ChronoForge: Threshold must be positive");
        uint256 oldValue = proposalMinReputationThreshold;
        proposalMinReputationThreshold = _newThreshold;
        emit ParameterChanged(keccak256("PROPOSAL_MIN_REPUTATION_THRESHOLD"), oldValue, _newThreshold);
    }

    // --- VI. Utility & Query Functions ---

    /**
     * @notice Retrieves detailed information about a specific knowledge capsule.
     * @param _capsuleId The ID of the capsule.
     */
    function getKnowledgeCapsule(uint256 _capsuleId)
        public
        view
        returns (
            uint256 id,
            bytes memory data,
            uint256 unlockTimestamp,
            bytes32 unlockConditionHash,
            address contributor,
            string memory metadataURI,
            bool isUnlocked,
            bool requiresComputation,
            ComputationType computationType,
            bytes memory computationInputData,
            bytes memory computationResult,
            uint256 attestationCount,
            uint256 totalStakedAmount,
            uint256 linkedParentCapsuleId,
            string memory linkDescription
        )
    {
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        require(capsule.id != 0, "ChronoForge: Capsule does not exist");
        return (
            capsule.id,
            capsule.data,
            capsule.unlockTimestamp,
            capsule.unlockConditionHash,
            capsule.contributor,
            capsule.metadataURI,
            capsule.isUnlocked,
            capsule.requiresComputation,
            capsule.computationType,
            capsule.computationInputData,
            capsule.computationResult,
            capsule.attestationCount,
            capsule.totalStakedAmount,
            capsule.linkedParentCapsuleId,
            capsule.linkDescription
        );
    }

    /**
     * @notice Returns the ID of the most recently submitted capsule.
     */
    function getLatestCapsuleId() public view returns (uint256) {
        return nextCapsuleId - 1;
    }

    /**
     * @notice Checks if a specific knowledge capsule is currently unlocked.
     * @param _capsuleId The ID of the capsule.
     */
    function isKnowledgeCapsuleUnlocked(uint256 _capsuleId) public view returns (bool) {
        return knowledgeCapsules[_capsuleId].isUnlocked;
    }

    /**
     * @notice Checks if a specific address has attested to a capsule.
     * @param _capsuleId The ID of the capsule.
     * @param _attester The address to check.
     */
    function isKnowledgeCapsuleAttestedBy(uint256 _capsuleId, address _attester) public view returns (bool) {
        return _hasAttested[_capsuleId][_attester];
    }

    /**
     * @notice Returns the current balance of the public goods fund.
     */
    function getPublicGoodsFundBalance() public view returns (uint256) {
        return publicGoodsFund;
    }

    /**
     * @notice Pauses contract functionality in case of emergency.
     * @dev Only callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functionality.
     * @dev Only callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
```