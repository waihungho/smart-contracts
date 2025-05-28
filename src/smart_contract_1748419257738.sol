Okay, let's create a smart contract based on a creative, advanced, and somewhat abstract concept: a "Quantum Entanglement Ledger".

This contract allows users to submit "Entangled Proofs" – pieces of data linked to other proofs. The contract manages the state, verification, and a concept of "coherence" for these proofs, building a reputation ("Coherence Score") for users based on the coherence of their submissions. It incorporates concepts like state changes, linked data structures, role-based permissions (for verification), configurable parameters, pausing, and a basic delegation mechanism based on the reputation score.

**Concept:** `QuantumEntanglementLedger`
Users submit data packets (`EntangledProof`) that can reference (be "entangled" with) other existing proofs. These proofs go through states (`Pending`, `Verifying`, `Verified`, `Challenged`, `Resolved`). An authorized "Verifier" determines a "Coherence Score" for verified proofs, representing its validity or truthfulness within the system's context. Users accumulate a "Coherence Score" based on their successful, high-coherence submissions. The contract includes features for managing verifiers, parameters, challenging proofs, and delegating one's Coherence Score.

**Outline:**

1.  **License & Pragma**
2.  **Error Definitions**
3.  **State Variables:**
    *   Contract Owner
    *   Pause State
    *   Proof Counter
    *   Mappings: Proofs, User Coherence Scores, Approved Verifiers, Parameters, Proofs by Submitter, Proofs by State, Delegations
    *   Arrays: Recent Proof IDs, Parameter names (enum)
4.  **Enums:** Proof State, Parameter Names
5.  **Structs:** Entangled Proof
6.  **Events:** Proof Submitted, Proof State Changed, Coherence Score Updated, Verifier Added/Removed, Parameter Updated, Proof Challenged, Challenge Resolved, Funds Withdrawn, Paused/Unpaused, Delegation Updated
7.  **Modifiers:** onlyOwner, whenNotPaused, whenPaused, onlyApprovedVerifier, isValidProofId
8.  **Constructor:** Sets initial owner.
9.  **Core Proof Management Functions (8):**
    *   Submit Proof
    *   Get Proof Details
    *   Get Proof Submitter
    *   Get Proof Payload
    *   Get Proof Entanglements
    *   Get Proof Coherence Score
    *   Get Proof State
    *   Get Proof Challenge Reason
10. **State Change & Verification Functions (5):**
    *   Request Verification
    *   Submit Verification Result (by Verifier)
    *   Challenge Proof
    *   Resolve Challenge (by Owner/Resolver)
    *   Internal: Update User Coherence Score
11. **Query & Listing Functions (6):**
    *   Get Total Proof Count
    *   Get User's Proof IDs
    *   Get Proof IDs by State
    *   Get Recent Proof IDs
    *   Get Proof IDs Above Coherence Threshold
    *   Get User Coherence Score
12. **Configuration & Permission Functions (5):**
    *   Add Approved Verifier
    *   Remove Approved Verifier
    *   Set Parameter
    *   Get Parameter
    *   Withdraw Accumulated Funds
13. **Control Functions (2):**
    *   Pause Contract
    *   Unpause Contract
14. **Delegation Functions (3):**
    *   Delegate Coherence Score
    *   Undelegate Coherence Score
    *   Get Delegated Coherence Score
15. **Internal Helper Functions (Implicit/Simple):** Generating Proof IDs, state transitions.

**Function Summary (Count: 8 + 5 + 6 + 5 + 2 + 3 = 29 functions):**

*   `submitEntangledProof(bytes _payload, bytes32[] _entangledProofIds)`: Creates and registers a new `EntangledProof` with optional links to existing proofs.
*   `getProof(bytes32 _proofId)`: Retrieves the full details of a specific proof.
*   `getProofSubmitter(bytes32 _proofId)`: Returns the address that submitted a proof.
*   `getProofPayload(bytes32 _proofId)`: Returns the data payload of a proof.
*   `getProofEntanglements(bytes32 _proofId)`: Returns the list of proof IDs this proof is entangled with.
*   `getProofCoherenceScore(bytes32 _proofId)`: Returns the calculated coherence score of a proof.
*   `getProofState(bytes32 _proofId)`: Returns the current state (Pending, Verified, Challenged, etc.) of a proof.
*   `getProofChallengeReason(bytes32 _proofId)`: Returns the reason provided if the proof is challenged.
*   `requestProofVerification(bytes32 _proofId)`: Marks a `Pending` proof as `Verifying`, signaling it's ready for review.
*   `submitVerificationResult(bytes32 _proofId, uint256 _coherenceScore, string _verificationDetails)`: (Callable by Approved Verifier) Submits the verification outcome, updates the proof's state to `Verified`, sets its coherence score, and updates the submitter's total coherence score.
*   `challengeProof(bytes32 _proofId, string _reason)`: (Callable by any user) Marks a `Verified` proof as `Challenged`, providing a reason. Requires potential future resolution.
*   `resolveChallenge(bytes32 _proofId, bool _challengerWins, string _resolutionDetails)`: (Callable by Owner/Resolver) Resolves a `Challenged` proof. Updates state to `Resolved` and adjusts the Coherence Scores of the submitter and challenger based on the outcome.
*   `_updateUserCoherenceScore(address _user, int256 _scoreDelta)`: (Internal) Adjusts a user's total coherence score. Handles potential negative adjustments (e.g., from failed challenges).
*   `getProofCount()`: Returns the total number of proofs submitted.
*   `getUserProofIds(address _user)`: Returns an array of all proof IDs submitted by a specific user.
*   `getProofIdsByState(ProofState _state)`: Returns an array of proof IDs currently in a specific state.
*   `getRecentProofIds(uint256 _count)`: Returns the IDs of the most recently submitted proofs (up to `_count`).
*   `getProofIdsAboveCoherence(uint256 _threshold, uint256 _limit)`: Returns up to `_limit` proof IDs that have a coherence score equal to or higher than `_threshold`.
*   `getUserCoherenceScore(address _user)`: Returns the total accumulated coherence score for a user.
*   `addApprovedVerifier(address _verifier)`: (Callable by Owner) Adds an address to the list of entities allowed to submit verification results.
*   `removeApprovedVerifier(address _verifier)`: (Callable by Owner) Removes an address from the approved verifiers list.
*   `setParameter(Parameter _param, uint256 _value)`: (Callable by Owner) Sets a configurable parameter value (e.g., minimum challenge score, resolution penalty).
*   `getParameter(Parameter _param)`: Returns the value of a specific configurable parameter.
*   `withdrawFunds(address payable _to)`: (Callable by Owner) Allows withdrawing any ETH accumulated in the contract (e.g., from potential future challenge stakes).
*   `pauseContract()`: (Callable by Owner) Pauses key contract functionality (submissions, state changes).
*   `unpauseContract()`: (Callable by Owner) Unpauses the contract.
*   `delegateCoherenceScore(address _delegatee)`: Allows a user to delegate their coherence score (reputation) to another address (e.g., for off-chain governance polling).
*   `undelegateCoherenceScore()`: Removes a user's delegation.
*   `getDelegatedCoherenceScore(address _user)`: Returns the address to whom a user has delegated their score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title QuantumEntanglementLedger
/// @author Your Name/Handle
/// @notice A smart contract for managing Entangled Proofs, their verification state,
/// and user coherence scores based on successful submissions. Utilizes concepts
/// of linked data (entanglement), state transitions, role-based verification,
/// configurable parameters, and reputation delegation. The "Quantum Entanglement"
/// is a metaphorical concept used for the data structure and naming, not actual
/// quantum computing.

// --- Error Definitions ---
error InvalidProofId();
error ProofNotInState(bytes32 _proofId, ProofState _expectedState);
error NotApprovedVerifier();
error NotOwner();
error ContractPaused();
error ContractNotPaused();
error InvalidParameter();
error ZeroAddressDelegatee();


// --- State Variables ---

/// @notice Address of the contract owner, with elevated permissions.
address private immutable i_owner;

/// @notice Flag indicating if the contract is paused.
bool private s_paused;

/// @notice Counter for submitted proofs, used for unique ID generation potentially.
uint256 private s_proofCounter;

/// @notice Mapping from proof ID to the EntangledProof struct.
mapping(bytes32 proofId => EntangledProof proof) public s_proofs;

/// @notice Mapping from user address to their accumulated coherence score.
mapping(address user => uint256 score) public s_userCoherenceScores;

/// @notice Mapping from verifier address to boolean indicating approval status.
mapping(address verifier => bool isApproved) public s_approvedVerifiers;

/// @notice Mapping from parameter name to its configured uint256 value.
mapping(Parameter param => uint256 value) public s_parameters;

/// @notice Mapping from user address to an array of proof IDs they submitted.
mapping(address user => bytes32[] proofIds) public s_proofIdsBySubmitter;

/// @notice Mapping from proof state to an array of proof IDs currently in that state.
mapping(ProofState state => bytes32[] proofIds) public s_proofIdsByState;

/// @notice Array storing the IDs of all submitted proofs, ordered by submission time.
/// This can grow large, use with caution or off-chain indexing.
bytes32[] public s_recentProofIds;

/// @notice Mapping from user address to the address they have delegated their coherence score to.
mapping(address user => address delegatee) public s_delegatedCoherenceScores;


// --- Enums ---

/// @notice Represents the current state of an EntangledProof.
enum ProofState {
    Pending,      // Submitted, awaiting verification request
    Verifying,    // Verification has been requested
    Verified,     // Verification complete, score assigned
    Challenged,   // Verification outcome is disputed
    Resolved      // Challenge has been adjudicated
}

/// @notice Configurable parameters for the ledger's operation.
enum Parameter {
    MIN_COHERENCE_THRESHOLD, // Minimum coherence score required for certain actions (e.g., challenging?)
    CHALLENGE_PENALTY,       // Coherence score penalty for unsuccessful challengers
    SUBMITTER_PENALTY        // Coherence score penalty for submitters whose proofs fail challenges
    // Add more parameters as needed
}


// --- Structs ---

/// @notice Represents a single Entangled Proof within the ledger.
struct EntangledProof {
    bytes32 id;              // Unique identifier for the proof
    address submitter;       // Address that submitted the proof
    uint256 timestamp;       // Timestamp of submission
    bytes payload;           // Arbitrary data associated with the proof
    bytes32[] entangledProofIds; // IDs of other proofs this one is linked to
    ProofState state;        // Current state of the proof
    uint256 coherenceScore;  // Assigned score after successful verification
    string challengeReason;  // Reason provided if the proof is challenged
}


// --- Events ---

/// @notice Emitted when a new proof is submitted.
event ProofSubmitted(bytes32 indexed proofId, address indexed submitter, uint256 timestamp);

/// @notice Emitted when a proof's state changes.
event ProofStateChanged(bytes32 indexed proofId, ProofState indexed oldState, ProofState indexed newState);

/// @notice Emitted when a user's total coherence score is updated.
event CoherenceScoreUpdated(address indexed user, uint256 newScore, int256 scoreDelta);

/// @notice Emitted when an address is added or removed as an approved verifier.
event VerifierStatusChanged(address indexed verifier, bool isApproved);

/// @notice Emitted when a contract parameter is updated.
event ParameterUpdated(Parameter indexed param, uint256 oldValue, uint256 newValue);

/// @notice Emitted when a verified proof is challenged.
event ProofChallenged(bytes32 indexed proofId, address indexed challenger, string reason);

/// @notice Emitted when a challenge is resolved.
event ChallengeResolved(bytes32 indexed proofId, address indexed resolver, bool challengerWins, string resolutionDetails);

/// @notice Emitted when funds are withdrawn from the contract.
event FundsWithdrawn(address indexed to, uint256 amount);

/// @notice Emitted when the contract state is paused or unpaused.
event Paused(address account);
event Unpaused(address account);

/// @notice Emitted when a user delegates their coherence score.
event DelegationUpdated(address indexed delegator, address indexed delegatee);


// --- Modifiers ---

/// @notice Throws if the caller is not the contract owner.
modifier onlyOwner() {
    if (msg.sender != i_owner) revert NotOwner();
    _;
}

/// @notice Throws if the contract is currently paused.
modifier whenNotPaused() {
    if (s_paused) revert ContractPaused();
    _;
}

/// @notice Throws if the contract is not currently paused.
modifier whenPaused() {
    if (!s_paused) revert ContractNotPaused();
    _;
}

/// @notice Throws if the caller is not an approved verifier.
modifier onlyApprovedVerifier() {
    if (!s_approvedVerifiers[msg.sender]) revert NotApprovedVerifier();
    _;
}

/// @notice Throws if the provided proof ID does not correspond to an existing proof.
modifier isValidProofId(bytes32 _proofId) {
    if (s_proofs[_proofId].id == bytes32(0)) revert InvalidProofId();
    _;
}


// --- Constructor ---

constructor() {
    i_owner = msg.sender;
    s_paused = false;
    s_proofCounter = 0;

    // Initialize some default parameters (example values)
    s_parameters[Parameter.MIN_COHERENCE_THRESHOLD] = 10; // Example: proofs must have >= 10 score to be 'meaningful'
    s_parameters[Parameter.CHALLENGE_PENALTY] = 50; // Example: challenger loses 50 score if they lose
    s_parameters[Parameter.SUBMITTER_PENALTY] = 100; // Example: submitter loses 100 score if proof fails challenge
}


// --- Core Proof Management Functions ---

/// @notice Submits a new Entangled Proof to the ledger.
/// @param _payload Arbitrary data payload for the proof.
/// @param _entangledProofIds Optional list of IDs of existing proofs this one is linked to.
/// @return The unique ID assigned to the newly submitted proof.
function submitEntangledProof(bytes memory _payload, bytes32[] memory _entangledProofIds) public whenNotPaused returns (bytes32 proofId) {
    // Basic validation for entangled links (optional, could add more checks)
    for (uint i = 0; i < _entangledProofIds.length; i++) {
         // Ensure linked proofs exist, but they don't need to be Verified yet.
         // This creates the 'entanglement' link structurally.
        if (s_proofs[_entangledProofIds[i]].id == bytes32(0)) {
             // Decide policy: fail submission if any link is invalid, or ignore invalid links?
             // Let's fail for strictness.
             revert InvalidProofId();
        }
    }

    s_proofCounter++;
    proofId = keccak256(abi.encodePacked(msg.sender, _payload, _entangledProofIds, block.timestamp, block.number, s_proofCounter));

    // Ensure generated ID is unique (highly probable with current factors)
    while (s_proofs[proofId].id != bytes32(0)) {
         s_proofCounter++; // Increment counter and try again
         proofId = keccak256(abi.encodePacked(msg.sender, _payload, _entangledProofIds, block.timestamp, block.number, s_proofCounter));
    }

    s_proofs[proofId] = EntangledProof({
        id: proofId,
        submitter: msg.sender,
        timestamp: block.timestamp,
        payload: _payload,
        entangledProofIds: _entangledProofIds,
        state: ProofState.Pending,
        coherenceScore: 0,
        challengeReason: ""
    });

    s_proofIdsBySubmitter[msg.sender].push(proofId);
    s_proofIdsByState[ProofState.Pending].push(proofId);
    s_recentProofIds.push(proofId);

    emit ProofSubmitted(proofId, msg.sender, block.timestamp);
    emit ProofStateChanged(proofId, ProofState.Pending, ProofState.Pending); // State starts Pending

    return proofId;
}

/// @notice Retrieves the full details of a specific proof.
/// @param _proofId The ID of the proof to retrieve.
/// @return The EntangledProof struct.
function getProof(bytes32 _proofId) public view isValidProofId(_proofId) returns (EntangledProof memory) {
    return s_proofs[_proofId];
}

/// @notice Returns the submitter address of a specific proof.
/// @param _proofId The ID of the proof.
/// @return The submitter's address.
function getProofSubmitter(bytes32 _proofId) public view isValidProofId(_proofId) returns (address) {
    return s_proofs[_proofId].submitter;
}

/// @notice Returns the data payload of a specific proof.
/// @param _proofId The ID of the proof.
/// @return The data payload.
function getProofPayload(bytes32 _proofId) public view isValidProofId(_proofId) returns (bytes memory) {
    return s_proofs[_proofId].payload;
}

/// @notice Returns the list of proof IDs that a specific proof is entangled with.
/// @param _proofId The ID of the proof.
/// @return An array of entangled proof IDs.
function getProofEntanglements(bytes32 _proofId) public view isValidProofId(_proofId) returns (bytes32[] memory) {
    return s_proofs[_proofId].entangledProofIds;
}

/// @notice Returns the coherence score of a specific proof.
/// @param _proofId The ID of the proof.
/// @return The coherence score. Returns 0 if not yet verified.
function getProofCoherenceScore(bytes32 _proofId) public view isValidProofId(_proofId) returns (uint256) {
    return s_proofs[_proofId].coherenceScore;
}

/// @notice Returns the current state of a specific proof.
/// @param _proofId The ID of the proof.
/// @return The proof's current state enum.
function getProofState(bytes32 _proofId) public view isValidProofId(_proofId) returns (ProofState) {
    return s_proofs[_proofId].state;
}

/// @notice Returns the challenge reason for a specific proof, if applicable.
/// @param _proofId The ID of the proof.
/// @return The challenge reason string. Empty string if not challenged.
function getProofChallengeReason(bytes32 _proofId) public view isValidProofId(_proofId) returns (string memory) {
    return s_proofs[_proofId].challengeReason;
}


// --- State Change & Verification Functions ---

/// @notice Marks a pending proof as ready for verification.
/// Only proofs in the `Pending` state can request verification.
/// @param _proofId The ID of the proof to request verification for.
function requestProofVerification(bytes32 _proofId) public whenNotPaused isValidProofId(_proofId) {
    EntangledProof storage proof = s_proofs[_proofId];
    if (proof.state != ProofState.Pending) {
        revert ProofNotInState(_proofId, ProofState.Pending);
    }

    ProofState oldState = proof.state;
    proof.state = ProofState.Verifying;

    // Remove from Pending list, add to Verifying list
    _removeProofIdFromList(s_proofIdsByState[oldState], _proofId);
    s_proofIdsByState[proof.state].push(_proofId);

    emit ProofStateChanged(_proofId, oldState, proof.state);
}


/// @notice Submits the result of a proof verification.
/// Callable only by approved verifiers for proofs in the `Verifying` state.
/// @param _proofId The ID of the proof being verified.
/// @param _coherenceScore The calculated coherence score for the proof (0 or higher).
/// @param _verificationDetails Optional string with details about the verification process.
function submitVerificationResult(bytes32 _proofId, uint256 _coherenceScore, string memory _verificationDetails) public whenNotPaused onlyApprovedVerifier isValidProofId(_proofId) {
    // _verificationDetails is stored off-chain or emitted in event for gas efficiency
    EntangledProof storage proof = s_proofs[_proofId];
    if (proof.state != ProofState.Verifying) {
        revert ProofNotInState(_proofId, ProofState.Verifying);
    }

    ProofState oldState = proof.state;
    proof.state = ProofState.Verified;
    proof.coherenceScore = _coherenceScore;

    // Add the proof's coherence score to the submitter's total score
    _updateUserCoherenceScore(proof.submitter, int256(_coherenceScore));

    // Remove from Verifying list, add to Verified list
    _removeProofIdFromList(s_proofIdsByState[oldState], _proofId);
    s_proofIdsByState[proof.state].push(_proofId);

    emit ProofStateChanged(_proofId, oldState, proof.state);
    // Emit verification details separately as they are not stored on-chain
    emit event(bytes32(keccak256("VerificationDetails(bytes32,string)")), _proofId, bytes(_verificationDetails));
}

/// @notice Challenges a verified proof, marking it for review.
/// Callable by any user on proofs in the `Verified` state.
/// @param _proofId The ID of the proof to challenge.
/// @param _reason A brief explanation for the challenge.
function challengeProof(bytes32 _proofId, string memory _reason) public whenNotPaused isValidProofId(_proofId) {
    EntangledProof storage proof = s_proofs[_proofId];
    if (proof.state != ProofState.Verified) {
        revert ProofNotInState(_proofId, ProofState.Verified);
    }

    ProofState oldState = proof.state;
    proof.state = ProofState.Challenged;
    proof.challengeReason = _reason; // Store the reason
    // Could potentially require a stake here (ETH or token)

    // Remove from Verified list, add to Challenged list
    _removeProofIdFromList(s_proofIdsByState[oldState], _proofId);
    s_proofIdsByState[proof.state].push(_proofId);

    emit ProofChallenged(_proofId, msg.sender, _reason);
    emit ProofStateChanged(_proofId, oldState, proof.state);
}

/// @notice Resolves a challenged proof, determining the outcome.
/// Callable by the contract owner (or potentially a dedicated resolver role).
/// Adjusts submitter and challenger coherence scores based on `_challengerWins`.
/// @param _proofId The ID of the proof being resolved.
/// @param _challengerWins True if the challenger's claim is upheld, false if the original proof stands.
/// @param _resolutionDetails Optional string with details about the resolution process.
function resolveChallenge(bytes32 _proofId, bool _challengerWins, string memory _resolutionDetails) public whenNotPaused onlyOwner isValidProofId(_proofId) {
    // _resolutionDetails stored off-chain or emitted for gas efficiency
    EntangledProof storage proof = s_proofs[_proofId];
    if (proof.state != ProofState.Challenged) {
        revert ProofNotInState(_proofId, ProofState.Challenged);
    }

    ProofState oldState = proof.state;
    proof.state = ProofState.Resolved; // Move to Resolved state

    // Find the original challenger (requires storing challenger address when challenged)
    // To keep struct simple, we'll skip storing original challenger on-chain and
    // assume resolution logic is based purely on owner's determination impacting submitter.
    // A more complex version would store the challenger's address.
    // For this example, we'll just penalize the submitter if they lose.

    if (_challengerWins) {
        // Challenger wins: proof was incorrect/invalid. Penalize submitter.
        // Subtract the proof's score AND a penalty parameter amount.
        // Use unchecked for subtraction if score can go below zero,
        // or ensure score is >= penalty amount. Let's ensure >= 0.
        uint256 penalty = s_parameters[Parameter.SUBMITTER_PENALTY];
        uint256 scoreToRemove = proof.coherenceScore + penalty;
        int256 delta = - int256(scoreToRemove);

        _updateUserCoherenceScore(proof.submitter, delta);

        // Proof's coherence score is now effectively invalid
        proof.coherenceScore = 0;

        // In a real system, handle stakes here: refund challenger, slash submitter's stake
    } else {
        // Challenger loses: proof was correct. Penalize challenger.
        // We don't have the challenger's address stored in the proof struct.
        // A robust implementation would store the challenger's address in the Proof struct
        // or a separate mapping upon challenge.
        // For simplicity, we skip penalizing the challenger here, or assume
        // it's handled off-chain based on event data.
        // Example if challenger address was stored:
        // address challenger = getOriginalChallenger(_proofId); // Needs implementation
        // _updateUserCoherenceScore(challenger, - int256(s_parameters[Parameter.CHALLENGE_PENALTY]));

        // In a real system, handle stakes here: refund submitter, slash challenger's stake
    }

    // Remove from Challenged list, add to Resolved list
    _removeProofIdFromList(s_proofIdsByState[oldState], _proofId);
    s_proofIdsByState[proof.state].push(_proofId);

    emit ChallengeResolved(_proofId, msg.sender, _challengerWins, _resolutionDetails);
    emit ProofStateChanged(_proofId, oldState, proof.state);
}

/// @notice Internal function to update a user's coherence score, handling deltas.
/// @param _user The user address whose score is being updated.
/// @param _scoreDelta The amount to add or subtract from the score (can be negative).
function _updateUserCoherenceScore(address _user, int256 _scoreDelta) internal {
    uint256 currentScore = s_userCoherenceScores[_user];
    uint256 newScore;
    if (_scoreDelta >= 0) {
        newScore = currentScore + uint256(_scoreDelta);
    } else {
        uint256 scoreSubtraction = uint256(-_scoreDelta);
        if (currentScore >= scoreSubtraction) {
            newScore = currentScore - scoreSubtraction;
        } else {
            newScore = 0; // Score cannot go below zero
        }
    }
    s_userCoherenceScores[_user] = newScore;
    emit CoherenceScoreUpdated(_user, newScore, _scoreDelta);
}


// --- Query & Listing Functions ---

/// @notice Returns the total number of proofs submitted to the ledger.
/// @return The total count of proofs.
function getProofCount() public view returns (uint256) {
    return s_recentProofIds.length; // Or use s_proofCounter
}

/// @notice Returns an array of all proof IDs submitted by a specific user.
/// @param _user The address of the user.
/// @return An array of proof IDs.
function getUserProofIds(address _user) public view returns (bytes32[] memory) {
    return s_proofIdsBySubmitter[_user];
}

/// @notice Returns an array of proof IDs currently in a specific state.
/// Note: Iterating large arrays on-chain can be gas-intensive.
/// Consider off-chain indexing for large lists.
/// @param _state The proof state to filter by.
/// @return An array of proof IDs.
function getProofIdsByState(ProofState _state) public view returns (bytes32[] memory) {
    return s_proofIdsByState[_state];
}

/// @notice Returns the IDs of the most recently submitted proofs.
/// Note: Retrieves up to `_count` from the end of the array.
/// @param _count The maximum number of recent proofs to retrieve.
/// @return An array of the most recent proof IDs.
function getRecentProofIds(uint256 _count) public view returns (bytes32[] memory) {
    uint256 totalProofs = s_recentProofIds.length;
    uint256 startIndex = 0;
    if (totalProofs > _count) {
        startIndex = totalProofs - _count;
    }
    uint256 resultSize = totalProofs - startIndex;
    bytes32[] memory recentIds = new bytes32[](resultSize);
    for (uint256 i = 0; i < resultSize; i++) {
        recentIds[i] = s_recentProofIds[startIndex + i];
    }
    return recentIds;
}

/// @notice Returns proof IDs that have a coherence score greater than or equal to a threshold.
/// Note: Iterates through all proofs which can be gas-intensive.
/// @param _threshold The minimum coherence score required.
/// @param _limit The maximum number of results to return.
/// @return An array of proof IDs meeting the criteria, up to the limit.
function getProofIdsAboveCoherence(uint256 _threshold, uint256 _limit) public view returns (bytes32[] memory) {
    bytes32[] memory result = new bytes32[](_limit);
    uint256 count = 0;
    // Warning: Iterating through all proofIds in s_recentProofIds can be very gas-expensive
    // for a large number of proofs. This function is for demonstration; off-chain indexing
    // or a different on-chain structure (like a sorted list/tree, which is complex)
    // would be required for production scaling.
    for (uint256 i = 0; i < s_recentProofIds.length; i++) {
        bytes32 proofId = s_recentProofIds[i];
        // Check if proof exists and is Verified (Resolved proofs might lose score)
        if (s_proofs[proofId].state == ProofState.Verified && s_proofs[proofId].coherenceScore >= _threshold) {
            result[count] = proofId;
            count++;
            if (count == _limit) break;
        }
    }
    bytes32[] memory finalResult = new bytes32[](count);
    for (uint256 i = 0; i < count; i++) {
        finalResult[i] = result[i];
    }
    return finalResult;
}

/// @notice Returns the total accumulated coherence score for a user.
/// @param _user The address of the user.
/// @return The user's total coherence score.
function getUserCoherenceScore(address _user) public view returns (uint256) {
    return s_userCoherenceScores[_user];
}


// --- Configuration & Permission Functions ---

/// @notice Adds an address to the list of approved verifiers.
/// Callable only by the contract owner.
/// @param _verifier The address to approve.
function addApprovedVerifier(address _verifier) public onlyOwner {
    if (!s_approvedVerifiers[_verifier]) {
        s_approvedVerifiers[_verifier] = true;
        emit VerifierStatusChanged(_verifier, true);
    }
}

/// @notice Removes an address from the list of approved verifiers.
/// Callable only by the contract owner.
/// @param _verifier The address to remove approval from.
function removeApprovedVerifier(address _verifier) public onlyOwner {
    if (s_approvedVerifiers[_verifier]) {
        s_approvedVerifiers[_verifier] = false;
        emit VerifierStatusChanged(_verifier, false);
    }
}

/// @notice Sets the value for a configurable parameter.
/// Callable only by the contract owner.
/// @param _param The parameter to set.
/// @param _value The new value for the parameter.
function setParameter(Parameter _param, uint256 _value) public onlyOwner {
    // Optional: add validation based on Parameter enum
    // For simplicity, any uint256 value is allowed here.
    uint256 oldValue = s_parameters[_param];
    s_parameters[_param] = _value;
    emit ParameterUpdated(_param, oldValue, _value);
}

/// @notice Gets the current value for a configurable parameter.
/// @param _param The parameter to retrieve.
/// @return The current value of the parameter.
function getParameter(Parameter _param) public view returns (uint256) {
     // Although the mapping returns 0 for uninitialized values,
     // we could add a check if the parameter name is known/valid.
     // For this example, assume querying any Parameter enum member is fine.
    return s_parameters[_param];
}

/// @notice Allows the contract owner to withdraw any Ether held by the contract.
/// Useful for withdrawing potential fees or lost stakes (if staking is implemented).
/// @param payable _to The address to send the funds to.
function withdrawFunds(address payable _to) public onlyOwner {
    uint256 balance = address(this).balance;
    if (balance > 0) {
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(_to, balance);
    }
}


// --- Control Functions ---

/// @notice Pauses the contract, preventing most state-changing operations.
/// Callable only by the contract owner.
function pauseContract() public onlyOwner whenNotPaused {
    s_paused = true;
    emit Paused(msg.sender);
}

/// @notice Unpauses the contract, re-enabling state-changing operations.
/// Callable only by the contract owner.
function unpauseContract() public onlyOwner whenPaused {
    s_paused = false;
    emit Unpaused(msg.sender);
}


// --- Delegation Functions ---

/// @notice Allows a user to delegate their total coherence score to another address.
/// Delegation is mainly for off-chain use (e.g., voting power based on score).
/// @param _delegatee The address to delegate the score to. Cannot be the zero address.
function delegateCoherenceScore(address _delegatee) public whenNotPaused {
    if (_delegatee == address(0)) revert ZeroAddressDelegatee();
    s_delegatedCoherenceScores[msg.sender] = _delegatee;
    emit DelegationUpdated(msg.sender, _delegatee);
}

/// @notice Removes a user's delegation of their coherence score.
function undelegateCoherenceScore() public whenNotPaused {
    s_delegatedCoherenceScores[msg.sender] = address(0);
    emit DelegationUpdated(msg.sender, address(0));
}

/// @notice Gets the address to which a user's coherence score is delegated.
/// Returns the zero address if no delegation is active.
/// @param _user The user address to check delegation for.
/// @return The address the user's score is delegated to.
function getDelegatedCoherenceScore(address _user) public view returns (address) {
    return s_delegatedCoherenceScores[_user];
}


// --- Internal Helper Functions ---

/// @notice Internal helper to remove a proof ID from a dynamic array.
/// Warning: This operation can be gas-expensive for large arrays as it requires shifting elements.
/// @param _list The dynamic array to modify.
/// @param _proofId The proof ID to remove.
function _removeProofIdFromList(bytes32[] storage _list, bytes32 _proofId) internal {
    for (uint256 i = 0; i < _list.length; i++) {
        if (_list[i] == _proofId) {
            // Replace with the last element and pop
            _list[i] = _list[_list.length - 1];
            _list.pop();
            break; // Assuming proofId is unique in the list
        }
    }
    // Note: Does not revert if ID is not found; assumes caller ensures ID is expected in the list.
}
```