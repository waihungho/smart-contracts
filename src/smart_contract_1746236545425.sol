Okay, let's design a smart contract based on the metaphor of Quantum Entanglement, focusing on managing data or outcomes that are uncertain until a "collapse" event. This incorporates state machines, commit-reveal patterns, time-based mechanics, and conditional outcomes, which are advanced concepts.

We will call this contract `QuantumEntanglementMessenger`. It allows two parties to commit to secret data, enter a "superposition" state where the outcome based on this data is uncertain, and then trigger a "collapse" event that deterministically reveals an outcome and allows revelation of the secrets.

**Contract Name:** `QuantumEntanglementMessenger`

**Core Concept:** Manage pairs of "entangled" data states between two parties. The state remains in "superposition" until a "collapse" event, triggered by external action, resolves it deterministically based on committed secrets and blockchain data.

**Advanced Concepts Used:**
1.  **State Machine:** Pairs transition through defined states (`Created`, `ParticipantJoined`, `CommitmentPhase`, `Superposition`, `Collapsed`, `Cancelled`).
2.  **Commit-Reveal Scheme:** Parties commit hashes of secrets before revealing the actual secrets, preventing cheating.
3.  **Time-Based Logic:** Deadlines for commitments and reveals.
4.  **Conditional Outcomes:** Actions (like claiming funds) depend on the resolved "collapse outcome".
5.  **Delegation:** Ability for creator to delegate the collapse trigger right.
6.  **Access Control & Roles:** Owner, Creator, Participant, Witness, Delegated Collapser.
7.  **Pausable Pattern:** For emergency situations (using OpenZeppelin).
8.  **Reentrancy Guard:** For safe fund transfers (using OpenZeppelin).
9.  **Pseudo-Randomness (for Outcome):** Deterministic outcome derived from committed data hashes and block properties at the time of collapse (explaining limitations).
10. **Metadata Linking:** Associating off-chain data hashes.

---

**Outline:**

1.  **Imports:** OpenZeppelin contracts for utilities (Ownable, Pausable, ReentrancyGuard).
2.  **Enums:** `PairState`, `CollapseOutcome`.
3.  **Structs:** `EntangledPair`.
4.  **State Variables:** Mappings for pairs, counter for pair IDs, fees collected, addresses for roles (owner, delegated collapser mapping).
5.  **Events:** For pair creation, state changes, commitments, collapse, reveals, claims, delegation, etc.
6.  **Modifiers:** State checks, role checks.
7.  **Constructor:** Sets the contract owner.
8.  **Core Functions:**
    *   Pair creation and joining (`createEntangledPair`, `acceptPairInvitation`, `cancelPairInvitation`).
    *   Commitment (`commitDataHashA`, `commitDataHashB`).
    *   Deadline management (`extendCommitmentDeadline`).
    *   Collapse trigger and logic (`requestCollapse`, `_performCollapseLogic`).
    *   Reveal (`revealDataA`, `revealDataB`).
    *   Cancellation (`cancelPairPostCommitment`, `forceCancelUnrevealed`).
    *   Conditional actions (`claimFundsOutcomeA`, `claimFundsOutcomeB`).
9.  **Utility/View Functions:** Get pair details, state, deadlines, outcome, revealed data, metadata, delegated address, watchers.
10. **Access Control/Admin Functions:** Pause/unpause, withdraw fees, add witness, add watcher, delegate collapse permission.
11. **Receive/Fallback:** Allow receiving ETH (for fees/pair value).
12. **Internal Helpers:** Verification logic (`_verifyCommitment`).

---

**Function Summary:**

1.  `constructor()`: Initializes the contract owner.
2.  `createEntangledPair(address _participant, uint256 _commitmentDeadline, uint256 _pairValue)`: Creates a new entangled pair, inviting a participant, setting deadline and associated value. Creator deposits `_pairValue`.
3.  `acceptPairInvitation(uint256 _pairId)`: Participant accepts invitation, deposits `_pairValue`.
4.  `cancelPairInvitation(uint256 _pairId)`: Creator cancels an unaccepted invitation. Refunds creator's deposit.
5.  `commitDataHashA(uint256 _pairId, bytes32 _dataHash)`: Creator commits hash of their secret data + salt.
6.  `commitDataHashB(uint256 _pairId, bytes32 _dataHash)`: Participant commits hash of their secret data + salt.
7.  `extendCommitmentDeadline(uint256 _pairId, uint256 _newDeadline)`: Creator can extend the commitment deadline (within limits).
8.  `requestCollapse(uint256 _pairId)`: Anyone (or delegated address) can trigger the collapse logic after commitments and deadline.
9.  `revealDataA(uint256 _pairId, bytes memory _data, bytes32 _salt)`: Creator reveals their data and salt after collapse. Verifies against commitment.
10. `revealDataB(uint256 _pairId, bytes memory _data, bytes32 _salt)`: Participant reveals their data and salt after collapse. Verifies against commitment.
11. `cancelPairPostCommitment(uint256 _pairId)`: Either party can cancel if the other party failed to reveal within the reveal deadline. Funds are split or returned based on logic.
12. `forceCancelUnrevealed(uint256 _pairId)`: Owner/Admin can force cancel a pair stuck after the reveal deadline.
13. `claimFundsOutcomeA(uint256 _pairId)`: Creator claims the `pairValue` if the collapse outcome was `OutcomeA` and data was revealed correctly.
14. `claimFundsOutcomeB(uint256 _pairId)`: Participant claims the `pairValue` if the collapse outcome was `OutcomeB` and data was revealed correctly.
15. `addWitness(uint256 _pairId, address _witness)`: Creator can add a witness (gets view access to certain details).
16. `setPairMetadataHash(uint256 _pairId, bytes32 _metadataHash)`: Creator can associate an off-chain metadata hash with the pair.
17. `delegateCollapsePermission(uint256 _pairId, address _delegatee)`: Creator delegates the right to call `requestCollapse`.
18. `addWatcher(uint256 _pairId, address _watcher)`: Allows an address to register interest (for off-chain tracking).
19. `pause()`: Owner pauses the contract (most functions disabled).
20. `unpause()`: Owner unpauses the contract.
21. `withdrawFees()`: Owner withdraws accumulated contract fees (e.g., a percentage of pair value, or separate fee).
22. `getPairDetails(uint256 _pairId)`: View function for comprehensive pair data.
23. `getPairState(uint256 _pairId)`: View function for current state.
24. `getCommitmentDeadline(uint256 _pairId)`: View function for commitment deadline.
25. `getCollapseOutcome(uint256 _pairId)`: View function for the determined outcome after collapse.
26. `getRevealedDataA(uint256 _pairId)`: View function for revealed data A.
27. `getRevealedDataB(uint256 _pairId)`: View function for revealed data B.
28. `getPairMetadataHash(uint256 _pairId)`: View function for metadata hash.
29. `getDelegatedCollapseTarget(uint256 _pairId)`: View function for collapse delegatee.
30. `getWatchers(uint256 _pairId)`: View function for the list of watchers.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline ---
// 1. Imports: OpenZeppelin contracts
// 2. Enums: PairState, CollapseOutcome
// 3. Structs: EntangledPair
// 4. State Variables: pairs mapping, nextPairId, collectedFees, delegatedCollapser mapping
// 5. Events: For pair creation, state changes, commitments, collapse, reveals, claims, delegation, etc.
// 6. Modifiers: State checks, role checks (Implicit via require)
// 7. Constructor: Sets owner
// 8. Core Functions: Create/Join/Cancel Pair, Commit, Extend Deadline, Collapse, Reveal, Post-Commitment Cancel, Force Cancel, Claim Funds
// 9. Utility/View Functions: Get pair details, state, deadlines, outcome, revealed data, metadata, delegated address, watchers.
// 10. Access Control/Admin Functions: Pause/unpause, withdraw fees, add witness, add watcher, delegate collapse permission.
// 11. Receive/Fallback: Allow receiving ETH
// 12. Internal Helpers: Verification logic

// --- Function Summary ---
// 1. constructor(): Initializes the contract owner.
// 2. createEntangledPair(address _participant, uint256 _commitmentDeadline, uint256 _pairValue): Creates a new pair.
// 3. acceptPairInvitation(uint256 _pairId): Participant accepts invitation.
// 4. cancelPairInvitation(uint256 _pairId): Creator cancels unaccepted invitation.
// 5. commitDataHashA(uint256 _pairId, bytes32 _dataHash): Creator commits hash.
// 6. commitDataHashB(uint256 _pairId, bytes32 _dataHash): Participant commits hash.
// 7. extendCommitmentDeadline(uint256 _pairId, uint256 _newDeadline): Creator extends deadline.
// 8. requestCollapse(uint256 _pairId): Triggers the collapse logic.
// 9. revealDataA(uint256 _pairId, bytes memory _data, bytes32 _salt): Creator reveals data.
// 10. revealDataB(uint256 _pairId, bytes memory _data, bytes32 _salt): Participant reveals data.
// 11. cancelPairPostCommitment(uint256 _pairId): Cancels if partner failed to reveal.
// 12. forceCancelUnrevealed(uint256 _pairId): Owner force cancels stuck pair.
// 13. claimFundsOutcomeA(uint256 _pairId): Creator claims funds if OutcomeA.
// 14. claimFundsOutcomeB(uint256 _pairId): Participant claims funds if OutcomeB.
// 15. addWitness(uint256 _pairId, address _witness): Add a witness.
// 16. setPairMetadataHash(uint256 _pairId, bytes32 _metadataHash): Set off-chain metadata hash.
// 17. delegateCollapsePermission(uint256 _pairId, address _delegatee): Delegate collapse right.
// 18. addWatcher(uint256 _pairId, address _watcher): Add a watcher.
// 19. pause(): Owner pauses contract.
// 20. unpause(): Owner unpauses contract.
// 21. withdrawFees(): Owner withdraws fees.
// 22. getPairDetails(uint256 _pairId): View pair struct.
// 23. getPairState(uint256 _pairId): View state.
// 24. getCommitmentDeadline(uint256 _pairId): View commitment deadline.
// 25. getCollapseOutcome(uint256 _pairId): View outcome.
// 26. getRevealedDataA(uint256 _pairId): View revealed data A.
// 27. getRevealedDataB(uint256 _pairId): View revealed data B.
// 28. getPairMetadataHash(uint256 _pairId): View metadata hash.
// 29. getDelegatedCollapseTarget(uint256 _pairId): View delegated address.
// 30. getWatchers(uint256 _pairId): View watchers list.


contract QuantumEntanglementMessenger is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum PairState {
        Created,
        ParticipantJoined,
        CommitmentPhase,
        Superposition,
        Collapsed,
        Cancelled
    }

    enum CollapseOutcome {
        Undetermined,
        OutcomeA, // Favors Creator
        OutcomeB, // Favors Participant
        Neutral   // Neither wins, or outcome invalid
    }

    // --- Structs ---
    struct EntangledPair {
        uint256 id;
        address payable creator;
        address payable participant; // Payable to potentially receive funds directly
        PairState state;
        bytes32 dataAHash;
        bytes32 dataBHash;
        bytes revealedDataA;
        bytes revealedDataB;
        bytes32 saltA;
        bytes32 saltB;
        uint256 creationTime;
        uint256 commitmentDeadline;
        uint256 revealDeadline; // New deadline for revealing data
        CollapseOutcome collapseOutcome;
        uint256 collapseTime;
        uint256 pairValue; // Value associated with the pair outcome
        address[] witnesses;
        bytes32 metadataHash; // Hash linking to off-chain data/description
        address delegatedCollapseTarget; // Address allowed to trigger collapse
        address[] watchers; // Addresses interested in this pair (for off-chain notification)
        bool fundsClaimedA;
        bool fundsClaimedB;
    }

    // --- State Variables ---
    mapping(uint256 => EntangledPair) public pairs;
    uint256 private nextPairId;
    uint256 public collectedFees;
    uint256 public constant COMMITMENT_EXTENSION_LIMIT = 7 days; // Max total extension
    uint256 public constant REVEAL_PERIOD = 3 days; // Time allowed for reveal after collapse
    uint256 public constant CREATION_FEE_PERCENT = 1; // 1% fee on pair value (scaled by 100)

    // --- Events ---
    event PairCreated(uint256 indexed pairId, address indexed creator, address participant, uint256 pairValue, uint256 commitmentDeadline);
    event PairAccepted(uint256 indexed pairId, address indexed participant);
    event PairCancelled(uint256 indexed pairId, PairState fromState, address initiator);
    event DataCommitted(uint256 indexed pairId, address indexed party, bytes32 dataHash);
    event CommitmentDeadlineExtended(uint256 indexed pairId, uint256 newDeadline);
    event CollapseRequested(uint256 indexed pairId, address indexed initiator);
    event Collapsed(uint256 indexed pairId, CollapseOutcome outcome);
    event DataRevealed(uint256 indexed pairId, address indexed party);
    event FundsClaimed(uint256 indexed pairId, address indexed receiver, uint256 amount, CollapseOutcome outcome);
    event WitnessAdded(uint256 indexed pairId, address indexed witness);
    event MetadataHashUpdated(uint256 indexed pairId, bytes32 metadataHash);
    event CollapsePermissionDelegated(uint256 indexed pairId, address indexed delegatee);
    event WatcherAdded(uint256 indexed pairId, address indexed watcher);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Modifiers (implicit via require statements) ---
    // Example: require(pairs[_pairId].creator == msg.sender, "Not pair creator");
    // Example: require(pairs[_pairId].state == PairState.Created, "Wrong state");

    // --- Constructor ---
    constructor() Ownable(msg.sender) Pausable(false) {}

    // --- Receive/Fallback ---
    receive() external payable {}
    fallback() external payable {} // Allow receiving ETH

    // --- Core Functions ---

    /**
     * @notice Creates a new entangled pair, setting the participant, deadline, and associated value.
     * Requires the creator to deposit the specified pair value plus a small fee.
     * @param _participant The address of the second party in the pair.
     * @param _commitmentDeadline The timestamp by which both parties must commit their data hashes.
     * @param _pairValue The value (in wei) associated with this pair, potentially claimable based on outcome.
     */
    function createEntangledPair(address _participant, uint256 _commitmentDeadline, uint256 _pairValue)
        external
        payable
        whenNotPaused
        returns (uint256 pairId)
    {
        require(_participant != address(0), "Participant cannot be zero address");
        require(_participant != msg.sender, "Cannot pair with yourself");
        require(_commitmentDeadline > block.timestamp, "Deadline must be in the future");
        require(_pairValue > 0, "Pair value must be greater than zero");

        uint256 totalRequired = _pairValue + ((_pairValue * CREATION_FEE_PERCENT) / 100);
        require(msg.value >= totalRequired, "Insufficient funds: requires pairValue + creation fee");

        pairId = nextPairId++;
        collectedFees += msg.value - _pairValue; // Collect the fee

        pairs[pairId] = EntangledPair({
            id: pairId,
            creator: payable(msg.sender),
            participant: payable(_participant),
            state: PairState.Created,
            dataAHash: bytes32(0),
            dataBHash: bytes32(0),
            revealedDataA: bytes(""), // Initialize as empty bytes
            revealedDataB: bytes(""),
            saltA: bytes32(0),
            saltB: bytes32(0),
            creationTime: block.timestamp,
            commitmentDeadline: _commitmentDeadline,
            revealDeadline: 0, // Set after collapse
            collapseOutcome: CollapseOutcome.Undetermined,
            collapseTime: 0,
            pairValue: _pairValue,
            witnesses: new address[](0),
            metadataHash: bytes32(0),
            delegatedCollapseTarget: address(0), // Initially no delegation
            watchers: new address[](0),
            fundsClaimedA: false,
            fundsClaimedB: false
        });

        emit PairCreated(pairId, msg.sender, _participant, _pairValue, _commitmentDeadline);
    }

    /**
     * @notice Allows the invited participant to accept the pair invitation.
     * Requires the participant to deposit the specified pair value.
     * @param _pairId The ID of the pair to accept.
     */
    function acceptPairInvitation(uint256 _pairId) external payable whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist"); // Ensure pairId exists
        require(pair.state == PairState.Created, "Pair not in Created state");
        require(pair.participant == msg.sender, "Not the invited participant");
        require(msg.value >= pair.pairValue, "Insufficient funds: requires pairValue deposit");

        // If more than pair.pairValue is sent, refund the excess
        if (msg.value > pair.pairValue) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - pair.pairValue}("");
            require(success, "Excess refund failed");
        }

        pair.state = PairState.ParticipantJoined;
        // Transition directly to CommitmentPhase after participant joins
        pair.state = PairState.CommitmentPhase;

        emit PairAccepted(_pairId, msg.sender);
        // Emitting state change for the transition to CommitmentPhase
        emit StateChanged(_pairId, PairState.Created, PairState.ParticipantJoined); // Log the intermediate state change
        emit StateChanged(_pairId, PairState.ParticipantJoined, PairState.CommitmentPhase);
    }

    /**
     * @notice Allows the creator to cancel a pair invitation if the participant hasn't accepted yet.
     * Refunds the creator's deposited funds.
     * @param _pairId The ID of the pair to cancel.
     */
    function cancelPairInvitation(uint256 _pairId) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.creator == msg.sender, "Not pair creator");
        require(pair.state == PairState.Created, "Pair not in Created state");

        // Refund creator's initial deposit (pairValue + fee)
        uint256 refundAmount = pair.pairValue + ((pair.pairValue * CREATION_FEE_PERCENT) / 100);
        (bool success, ) = payable(pair.creator).call{value: refundAmount}("");
        require(success, "Creator refund failed");

        pair.state = PairState.Cancelled;
        emit PairCancelled(_pairId, PairState.Created, msg.sender);
        emit StateChanged(_pairId, PairState.Created, PairState.Cancelled);
    }

    /**
     * @notice Allows the creator to commit the hash of their secret data and salt.
     * Must be in the CommitmentPhase and before the deadline.
     * @param _pairId The ID of the pair.
     * @param _dataHash The hash of the data (e.g., keccak256(abi.encodePacked(_data, _salt))).
     */
    function commitDataHashA(uint256 _pairId, bytes32 _dataHash) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.CommitmentPhase, "Pair not in CommitmentPhase");
        require(pair.creator == msg.sender, "Not pair creator");
        require(pair.dataAHash == bytes32(0), "Creator already committed");
        require(block.timestamp <= pair.commitmentDeadline, "Commitment deadline passed");
        require(_dataHash != bytes32(0), "Data hash cannot be zero");

        pair.dataAHash = _dataHash;
        emit DataCommitted(_pairId, msg.sender, _dataHash);

        // Check if participant has also committed
        if (pair.dataBHash != bytes32(0)) {
            pair.state = PairState.Superposition;
            emit StateChanged(_pairId, PairState.CommitmentPhase, PairState.Superposition);
        }
    }

    /**
     * @notice Allows the participant to commit the hash of their secret data and salt.
     * Must be in the CommitmentPhase and before the deadline.
     * @param _pairId The ID of the pair.
     * @param _dataHash The hash of the data (e.g., keccak256(abi.encodePacked(_data, _salt))).
     */
    function commitDataHashB(uint256 _pairId, bytes32 _dataHash) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.CommitmentPhase, "Pair not in CommitmentPhase");
        require(pair.participant == msg.sender, "Not pair participant");
        require(pair.dataBHash == bytes32(0), "Participant already committed");
        require(block.timestamp <= pair.commitmentDeadline, "Commitment deadline passed");
        require(_dataHash != bytes32(0), "Data hash cannot be zero");

        pair.dataBHash = _dataHash;
        emit DataCommitted(_pairId, msg.sender, _dataHash);

        // Check if creator has also committed
        if (pair.dataAHash != bytes32(0)) {
            pair.state = PairState.Superposition;
            emit StateChanged(_pairId, PairState.CommitmentPhase, PairState.Superposition);
        }
    }

    /**
     * @notice Allows the creator to extend the commitment deadline.
     * Can only be called in the CommitmentPhase and before the original deadline.
     * There is a total limit on how much the deadline can be extended.
     * @param _pairId The ID of the pair.
     * @param _newDeadline The new timestamp for the commitment deadline.
     */
    function extendCommitmentDeadline(uint256 _pairId, uint256 _newDeadline) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.CommitmentPhase, "Pair not in CommitmentPhase");
        require(pair.creator == msg.sender, "Not pair creator");
        require(block.timestamp <= pair.commitmentDeadline, "Original deadline already passed"); // Must extend before it passes
        require(_newDeadline > pair.commitmentDeadline, "New deadline must be after current deadline");
        // Check against total allowed extension from creation time
        require(_newDeadline <= pair.creationTime + COMMITMENT_EXTENSION_LIMIT, "New deadline exceeds total allowed extension");

        pair.commitmentDeadline = _newDeadline;
        emit CommitmentDeadlineExtended(_pairId, _newDeadline);
    }

    /**
     * @notice Triggers the 'collapse' event for an entangled pair, determining the outcome.
     * Can be called by anyone once the pair is in the Superposition state or if the commitment deadline has passed
     * (to force collapse if both committed, or transition to cancelable if not).
     * A delegated address can also trigger it if set.
     * @param _pairId The ID of the pair to collapse.
     */
    function requestCollapse(uint256 _pairId) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");

        // Check if caller is authorized
        bool isAuthorized = (msg.sender == pair.creator || msg.sender == pair.participant || msg.sender == pair.delegatedCollapseTarget || msg.sender == owner());

        if (pair.state == PairState.Superposition) {
             require(isAuthorized || pair.delegatedCollapseTarget == address(0), "Only creator, participant, delegatee, or owner can request collapse in Superposition if delegatee is set");
             _performCollapseLogic(_pairId);
        } else if (pair.state == PairState.CommitmentPhase && block.timestamp > pair.commitmentDeadline) {
             require(isAuthorized, "Only authorized parties can transition after deadline");
             // If deadline passed and not in Superposition, check commitments
             if (pair.dataAHash != bytes32(0) && pair.dataBHash != bytes32(0)) {
                 // Both committed before deadline, transition to Superposition and collapse
                 pair.state = PairState.Superposition;
                 emit StateChanged(_pairId, PairState.CommitmentPhase, PairState.Superposition);
                 _performCollapseLogic(_pairId);
             } else {
                 // Deadline passed, one or both did not commit
                 pair.state = PairState.Cancelled; // Or a specific state like 'CommitmentFailed'
                 emit PairCancelled(_pairId, PairState.CommitmentPhase, msg.sender);
                 emit StateChanged(_pairId, PairState.CommitmentPhase, PairState.Cancelled);
                 // Logic here to return funds or handle penalty - currently just marks cancelled.
                 // Requires implementing fund return logic based on who failed to commit.
             }
        } else {
            revert("Pair not in a collapsable state or deadline not passed");
        }

        emit CollapseRequested(_pairId, msg.sender);
    }

    /**
     * @notice Internal function to perform the deterministic collapse logic.
     * Determines the outcome based on committed hashes and block data.
     * @param _pairId The ID of the pair.
     */
    function _performCollapseLogic(uint256 _pairId) internal {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.state == PairState.Superposition, "Pair not in Superposition");
        require(pair.collapseOutcome == CollapseOutcome.Undetermined, "Collapse already performed");

        // --- Pseudo-random outcome logic ---
        // WARNING: Using block.timestamp and block.number for randomness is susceptible to miner manipulation,
        // especially if the pair value is significant. For truly secure randomness,
        // integrate with a VRF (Verifiable Random Function) oracle like Chainlink VRF.
        // This implementation is for demonstration of a deterministic outcome based on inputs *at collapse time*.
        bytes32 combinedEntropy = keccak256(
            abi.encodePacked(
                pair.dataAHash,
                pair.dataBHash,
                block.timestamp,
                block.number,
                block.difficulty, // Deprecated in PoS, less reliable
                block.prevrandao // More relevant in PoS, but still block-dependent
            )
        );

        // Determine outcome based on the combined entropy
        // Simple example: if the first byte is even, OutcomeA; if odd, OutcomeB.
        // This provides a ~50/50 distribution for the simplified case.
        if (uint256(combinedEntropy[0]) % 2 == 0) {
            pair.collapseOutcome = CollapseOutcome.OutcomeA;
        } else {
            pair.collapseOutcome = CollapseOutcome.OutcomeB;
        }
        // --- End Pseudo-random outcome logic ---

        pair.state = PairState.Collapsed;
        pair.collapseTime = block.timestamp;
        pair.revealDeadline = block.timestamp + REVEAL_PERIOD; // Set deadline for revealing data

        emit Collapsed(_pairId, pair.collapseOutcome);
        emit StateChanged(_pairId, PairState.Superposition, PairState.Collapsed);
    }

    /**
     * @notice Allows the creator to reveal their secret data and salt after collapse.
     * Verifies the revealed data against the committed hash.
     * @param _pairId The ID of the pair.
     * @param _data The actual secret data bytes.
     * @param _salt The salt bytes32 used in the commitment hash.
     */
    function revealDataA(uint256 _pairId, bytes memory _data, bytes32 _salt) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(pair.creator == msg.sender, "Not pair creator");
        require(pair.revealedDataA.length == 0, "Creator already revealed"); // Check if data A is already revealed
        require(block.timestamp <= pair.revealDeadline, "Reveal deadline passed for Creator A"); // Check reveal deadline for A

        bytes32 computedHash = keccak256(abi.encodePacked(_data, _salt));
        require(computedHash == pair.dataAHash, "Revealed data/salt does not match committed hash for A");

        pair.revealedDataA = _data;
        pair.saltA = _salt; // Store salt to verify again if needed or for transparency
        emit DataRevealed(_pairId, msg.sender);
    }

     /**
     * @notice Allows the participant to reveal their secret data and salt after collapse.
     * Verifies the revealed data against the committed hash.
     * @param _pairId The ID of the pair.
     * @param _data The actual secret data bytes.
     * @param _salt The salt bytes32 used in the commitment hash.
     */
    function revealDataB(uint256 _pairId, bytes memory _data, bytes32 _salt) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(pair.participant == msg.sender, "Not pair participant");
        require(pair.revealedDataB.length == 0, "Participant already revealed"); // Check if data B is already revealed
         require(block.timestamp <= pair.revealDeadline, "Reveal deadline passed for Participant B"); // Check reveal deadline for B

        bytes32 computedHash = keccak256(abi.encodePacked(_data, _salt));
        require(computedHash == pair.dataBHash, "Revealed data/salt does not match committed hash for B");

        pair.revealedDataB = _data;
        pair.saltB = _salt; // Store salt
        emit DataRevealed(_pairId, msg.sender);
    }

    /**
     * @notice Allows either party to cancel the pair if the other party failed to reveal their data within the deadline.
     * This prevents funds from being locked indefinitely if one party disappears after collapse.
     * @param _pairId The ID of the pair.
     */
    function cancelPairPostCommitment(uint256 _pairId) external whenNotPaused nonReentrant {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(block.timestamp > pair.revealDeadline, "Reveal deadline has not passed yet");
        require(msg.sender == pair.creator || msg.sender == pair.participant, "Not a participant in the pair");

        bool creatorRevealed = pair.revealedDataA.length > 0;
        bool participantRevealed = pair.revealedDataB.length > 0;

        require(!creatorRevealed || !participantRevealed, "Both parties have revealed or already cancelled/claimed");

        pair.state = PairState.Cancelled;
        emit PairCancelled(_pairId, PairState.Collapsed, msg.sender);
        emit StateChanged(_pairId, PairState.Collapsed, PairState.Cancelled);

        // Distribute funds:
        uint256 totalValue = pair.pairValue * 2; // Creator deposit + Participant deposit

        if (creatorRevealed && !participantRevealed) {
            // Participant failed to reveal, creator gets all
            (bool success, ) = payable(pair.creator).call{value: totalValue}("");
            require(success, "Fund distribution (creator win) failed");
        } else if (!creatorRevealed && participantRevealed) {
            // Creator failed to reveal, participant gets all
             (bool success, ) = payable(pair.participant).call{value: totalValue}("");
            require(success, "Fund distribution (participant win) failed");
        } else {
            // Neither revealed or something else went wrong, split or return to contract balance (owner withdrawal)
            // Returning to contract balance makes cleanup simpler for owner.
            // Funds remain in contract, owner needs to manually manage/refund if desired.
        }
    }

    /**
     * @notice Allows the contract owner to force cancel a pair that is stuck after the reveal deadline.
     * Funds remain in the contract balance. Intended for emergency cleanup.
     * @param _pairId The ID of the pair.
     */
    function forceCancelUnrevealed(uint256 _pairId) external onlyOwner whenNotPaused {
         EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(block.timestamp > pair.revealDeadline, "Reveal deadline has not passed yet");
        require(pair.revealedDataA.length == 0 || pair.revealedDataB.length == 0, "Both parties revealed or already cancelled/claimed");

        pair.state = PairState.Cancelled;
        emit PairCancelled(_pairId, PairState.Collapsed, msg.sender);
        emit StateChanged(_pairId, PairState.Collapsed, PairState.Cancelled);

        // Funds remain in the contract. Owner can withdraw all collected fees including any stuck pair values later.
    }


    /**
     * @notice Allows the creator to claim the pair value if the collapse outcome was OutcomeA
     * and both parties have revealed their data.
     * @param _pairId The ID of the pair.
     */
    function claimFundsOutcomeA(uint256 _pairId) external whenNotPaused nonReentrant {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.creator == msg.sender, "Not the pair creator");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(pair.collapseOutcome == CollapseOutcome.OutcomeA, "Outcome was not A");
        require(pair.revealedDataA.length > 0 && pair.revealedDataB.length > 0, "Both parties must reveal data first");
        require(!pair.fundsClaimedA, "Funds for OutcomeA already claimed");

        pair.fundsClaimedA = true;

        uint256 amountToClaim = pair.pairValue * 2; // Creator's deposit + Participant's deposit
        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Claim funds OutcomeA failed");

        emit FundsClaimed(_pairId, msg.sender, amountToClaim, pair.collapseOutcome);
    }

    /**
     * @notice Allows the participant to claim the pair value if the collapse outcome was OutcomeB
     * and both parties have revealed their data.
     * @param _pairId The ID of the pair.
     */
    function claimFundsOutcomeB(uint256 _pairId) external whenNotPaused nonReentrant {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.participant == msg.sender, "Not the pair participant");
        require(pair.state == PairState.Collapsed, "Pair not in Collapsed state");
        require(pair.collapseOutcome == CollapseOutcome.OutcomeB, "Outcome was not B");
        require(pair.revealedDataA.length > 0 && pair.revealedDataB.length > 0, "Both parties must reveal data first");
        require(!pair.fundsClaimedB, "Funds for OutcomeB already claimed");

        pair.fundsClaimedB = true;

        uint256 amountToClaim = pair.pairValue * 2; // Creator's deposit + Participant's deposit
        (bool success, ) = payable(msg.sender).call{value: amountToClaim}("");
        require(success, "Claim funds OutcomeB failed");

        emit FundsClaimed(_pairId, msg.sender, amountToClaim, pair.collapseOutcome);
    }


    // --- Utility/View Functions ---

    /**
     * @notice Gets the full details of an entangled pair.
     * @param _pairId The ID of the pair.
     * @return The EntangledPair struct.
     */
    function getPairDetails(uint256 _pairId) external view returns (EntangledPair memory) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId];
    }

     /**
     * @notice Gets the current state of an entangled pair.
     * @param _pairId The ID of the pair.
     * @return The current state of the pair.
     */
    function getPairState(uint256 _pairId) external view returns (PairState) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].state;
    }

    /**
     * @notice Gets the commitment deadline for a pair.
     * @param _pairId The ID of the pair.
     * @return The commitment deadline timestamp.
     */
    function getCommitmentDeadline(uint256 _pairId) external view returns (uint256) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].commitmentDeadline;
    }

    /**
     * @notice Gets the reveal deadline for a pair (set after collapse).
     * @param _pairId The ID of the pair.
     * @return The reveal deadline timestamp.
     */
     function getRevealDeadline(uint256 _pairId) external view returns (uint256) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].revealDeadline;
     }


    /**
     * @notice Gets the collapse outcome for a pair after it has collapsed.
     * @param _pairId The ID of the pair.
     * @return The collapse outcome.
     */
    function getCollapseOutcome(uint256 _pairId) external view returns (CollapseOutcome) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].collapseOutcome;
    }

    /**
     * @notice Gets the revealed data for party A (creator), if revealed.
     * @param _pairId The ID of the pair.
     * @return The revealed data bytes.
     */
    function getRevealedDataA(uint256 _pairId) external view returns (bytes memory) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].revealedDataA;
    }

    /**
     * @notice Gets the revealed data for party B (participant), if revealed.
     * @param _pairId The ID of the pair.
     * @return The revealed data bytes.
     */
    function getRevealedDataB(uint256 _pairId) external view returns (bytes memory) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].revealedDataB;
    }

    /**
     * @notice Gets the off-chain metadata hash associated with a pair.
     * @param _pairId The ID of the pair.
     * @return The metadata hash.
     */
    function getPairMetadataHash(uint256 _pairId) external view returns (bytes32) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].metadataHash;
    }

     /**
     * @notice Gets the address delegated the permission to request collapse for a pair.
     * @param _pairId The ID of the pair.
     * @return The delegated address, or address(0) if none is set.
     */
    function getDelegatedCollapseTarget(uint256 _pairId) external view returns (address) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].delegatedCollapseTarget;
    }

     /**
     * @notice Gets the list of addresses that have added themselves as watchers for a pair.
     * @param _pairId The ID of the pair.
     * @return An array of watcher addresses.
     */
    function getWatchers(uint256 _pairId) external view returns (address[] memory) {
         require(pairs[_pairId].id == _pairId, "Pair does not exist");
        return pairs[_pairId].watchers;
    }

    /**
     * @notice Gets the total number of pairs created.
     * @return The total count of pairs.
     */
    function getTotalPairs() external view returns (uint256) {
        return nextPairId;
    }

    // --- Access Control/Admin Functions ---

    /**
     * @notice Allows the creator to add a witness to the pair. Witnesses might have special view permissions (handled off-chain) or roles in future arbitration logic.
     * @param _pairId The ID of the pair.
     * @param _witness The address to add as a witness.
     */
    function addWitness(uint256 _pairId, address _witness) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.creator == msg.sender, "Not pair creator");
        require(_witness != address(0), "Witness address cannot be zero");

        // Avoid adding duplicates (simple check, could be optimized for large lists)
        bool alreadyWitness = false;
        for (uint i = 0; i < pair.witnesses.length; i++) {
            if (pair.witnesses[i] == _witness) {
                alreadyWitness = true;
                break;
            }
        }
        require(!alreadyWitness, "Address is already a witness");

        pair.witnesses.push(_witness);
        emit WitnessAdded(_pairId, _witness);
    }

    /**
     * @notice Allows the creator to set a hash linking to off-chain metadata about the pair (e.g., IPFS hash).
     * @param _pairId The ID of the pair.
     * @param _metadataHash The hash representing the off-chain metadata.
     */
    function setPairMetadataHash(uint256 _pairId, bytes32 _metadataHash) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.creator == msg.sender || pair.participant == msg.sender || msg.sender == owner(), "Not authorized to set metadata"); // Allow both participants and owner

        pair.metadataHash = _metadataHash;
        emit MetadataHashUpdated(_pairId, _metadataHash);
    }

    /**
     * @notice Allows the creator to delegate the permission to call `requestCollapse` for a specific pair to another address.
     * Can only be set before the pair collapses. Setting to address(0) revokes delegation.
     * @param _pairId The ID of the pair.
     * @param _delegatee The address to delegate the permission to, or address(0) to revoke.
     */
    function delegateCollapsePermission(uint256 _pairId, address _delegatee) external whenNotPaused {
        EntangledPair storage pair = pairs[_pairId];
        require(pair.id == _pairId, "Pair does not exist");
        require(pair.creator == msg.sender, "Not pair creator");
        require(pair.state < PairState.Collapsed, "Cannot delegate collapse permission after collapse");

        pair.delegatedCollapseTarget = _delegatee;
        emit CollapsePermissionDelegated(_pairId, _delegatee);
    }


     /**
     * @notice Allows any address to add themselves to a list of 'watchers' for a specific pair.
     * This is primarily for off-chain applications to track interesting pairs without special on-chain permissions.
     * @param _pairId The ID of the pair to watch.
     */
    function addWatcher(uint256 _pairId, address _watcher) external whenNotPaused {
         EntangledPair storage pair = pairs[_pairId];
         require(pair.id == _pairId, "Pair does not exist");
         require(_watcher != address(0), "Watcher address cannot be zero");

         // Simple check for duplicates
         bool alreadyWatcher = false;
         for(uint i = 0; i < pair.watchers.length; i++){
             if(pair.watchers[i] == _watcher){
                 alreadyWatcher = true;
                 break;
             }
         }
         require(!alreadyWatcher, "Address is already a watcher");

         pair.watchers.push(_watcher);
         emit WatcherAdded(_pairId, _watcher);
    }


    /**
     * @notice Pauses the contract, preventing most state-changing operations. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, allowing normal operations. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Allows the contract owner to withdraw accumulated fees.
     */
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = collectedFees;
        require(balance > 0, "No fees to withdraw");
        collectedFees = 0;

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(owner(), balance);
    }


    // --- Internal Helpers ---

    /**
     * @notice Internal helper to verify if revealed data and salt match a given hash.
     * @param _hash The committed hash.
     * @param _data The revealed data.
     * @param _salt The revealed salt.
     * @return True if the hash matches the data and salt, false otherwise.
     */
    function _verifyCommitment(bytes32 _hash, bytes memory _data, bytes32 _salt) internal pure returns (bool) {
        return _hash == keccak256(abi.encodePacked(_data, _salt));
    }

    // Overriding Pausable's _beforeTokenTransfer if using tokens, but we are using ETH here.
    // No need to override _beforeTokenTransfer as we are dealing with ETH payments using call.value.
    // The whenNotPaused modifier handles pausing logic on external/public functions.


    // --- Events for State Changes (Added for clarity) ---
    event StateChanged(uint256 indexed pairId, PairState oldState, PairState newState);
}
```