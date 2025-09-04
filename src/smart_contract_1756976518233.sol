This smart contract, **IntentWeave Protocol**, introduces a novel decentralized system for users to declare, manage, and fulfill future intentions or commitments on-chain. It's designed around the concept of "intent-based architecture," a growing trend in Web3, by focusing on declarative statements of future actions rather than immediate transactions. The protocol integrates advanced concepts like on-chain reputation, non-transferable Soulbound Tokens (SBTs) for verifiable identity, and a robust attestation and challenge system to ensure accountability.

---

**Outline: IntentWeave Protocol - Decentralized Intent & Commitment Network**

This protocol enables users to formally declare their future intentions or commitments on-chain. These aren't just simple transactions, but structured promises that can be proposed, activated, fulfilled, or failed. A system of third-party attestation and challenging, overseen by a designated resolver, ensures the integrity of these intentions and their outcomes. Reputation scores, linked to Soulbound Tokens, incentivize good behavior and penalize breaches of trust, fostering a network of verifiable commitments.

---

**Function Summary**

**I. Core Intent Lifecycle Management**
1.  `proposeIntent(string memory _description, uint256 _deadline, address _targetAddress, uint256 _value, bytes32 _externalRefId)`: Allows a user (Intent Weaver) to propose a new future intent with specific details, a deadline, and an optional external reference ID. Returns a unique `intentId`.
2.  `updateProposedIntent(uint256 _intentId, string memory _newDescription, uint256 _newDeadline, address _newTargetAddress, uint256 _newValue)`: Permits the Intent Weaver to modify the details of their own intent before it becomes active, provided there's no active challenge.
3.  `cancelProposedIntent(uint256 _intentId)`: Enables the Intent Weaver to cancel their own intent if it is still in the 'Proposed' state and not actively challenged.
4.  `activateIntent(uint256 _intentId)`: Transitions a 'Proposed' intent into an 'Active' state, starting its commitment period. Requires any dependencies to be fulfilled.
5.  `signalIntentFulfillment(uint256 _intentId, string memory _proofURI)`: The Intent Weaver declares that they have fulfilled their active intent, providing a URI to off-chain proof.
6.  `signalIntentFailure(uint256 _intentId, string memory _reasonURI)`: The Intent Weaver declares that they have failed to fulfill their active intent, providing a reason URI.

**II. Attestation & Challenge System**
7.  `attestToIntentIntegrity(uint256 _intentId, bool _isLegitimate) payable`: A third party can vouch for (or against) the good faith and feasibility of a *proposed* intent. Requires a small fee, which goes to protocol treasury.
8.  `challengeIntentIntegrity(uint256 _intentId, string memory _reasonURI) payable`: A third party can formally challenge the legitimacy or feasibility of a *proposed* intent. Requires a stake, which is held in escrow.
9.  `attestToIntentOutcome(uint256 _intentId, bool _isFulfilled, string memory _proofURI) payable`: A third party can attest to whether an *active* intent has truly been fulfilled or failed as claimed by the weaver. Requires a small fee.
10. `challengeIntentOutcome(uint256 _intentId, string memory _reasonURI) payable`: A third party can formally challenge the claimed outcome (fulfillment or failure) of an active intent. Requires a stake.
11. `resolveChallenge(uint256 _intentId, bool _isChallengerCorrect)`: An appointed resolver (e.g., a DAO or admin) makes a final decision on a disputed intent's integrity or outcome. This function handles stake distribution, reputation updates, and finalizes intent status.
12. `delegateIntentManagement(uint256 _intentId, address _delegatee)`: The Intent Weaver can delegate the management rights (e.g., signalling fulfillment) of their *proposed* intent to another address.

**III. Reputation & Incentive Mechanisms**
13. `claimReputationReward(uint256 _intentId)`: (Internal/Reserved for future complex reward systems) This function is currently non-callable externally, as reputation updates are managed internally by the resolver.
14. `penalizeIntentWeaver(uint256 _intentId, address _weaver)`: Internal function called by the resolver to apply penalties (e.g., reputation deduction, collateral loss) for failed intents or false claims.
15. `mintReputationSBT(address _user, uint256 _reputationScore)`: Mints a non-transferable "IntentWeaverReputation" Soulbound Token (SBT) for users reaching significant reputation milestones (callable by owner, interacts with external `IReputationSBT` contract).
16. `burnReputationSBT(address _user, uint256 _sbtId)`: Burns an SBT from a user's wallet due to severe breaches of trust or protocol rules (callable by owner, interacts with external `IReputationSBT` contract).

**IV. Advanced Intent Features**
17. `attachCollateral(uint256 _intentId) payable`: Allows the Intent Weaver to stake collateral (ETH) for an intent, providing a financial commitment. Collateral is released on fulfillment or claimable on failure.
18. `claimCollateral(uint256 _intentId)`: Allows the appointed resolver to claim staked collateral upon a verified intent failure, as determined by a challenge resolution.
19. `releaseCollateral(uint256 _intentId)`: Releases the staked collateral back to the Intent Weaver upon verified successful fulfillment of the intent.
20. `setIntentDependency(uint256 _intentId, uint256 _dependentIntentId)`: Defines that one intent (`_intentId`) can only be activated after another specific intent (`_dependentIntentId`) by the same weaver is successfully completed.
21. `proposeIntentAmendment(uint256 _intentId, string memory _newDescription, uint256 _newDeadline, address _newTargetAddress, uint256 _newValue)`: Allows the Intent Weaver to propose changes to an *active* intent's terms. For simplicity, this directly applies the changes; a more complex system might require multi-party approval or a new challenge period.

**V. Protocol Governance & Utilities**
22. `setProtocolParameter(bytes32 _paramName, uint256 _value)`: Allows the protocol admin/DAO to set various operational parameters (e.g., challenge periods, minimum stakes, attestation fees).
23. `withdrawProtocolFees()`: Allows the protocol admin/DAO to withdraw accumulated fees from attestations and forfeited challenge stakes.
24. `getIntentDetails(uint256 _intentId)`: A read-only function to retrieve all stored details and current status of a specific intent.
25. `getChallengeDetails(uint256 _challengeId)`: A read-only function to retrieve all stored details of a specific challenge.
26. `getUserReputation(address _user)`: A read-only function to get the current reputation score of a user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline: IntentWeave Protocol - Decentralized Intent & Commitment Network ---

// This protocol enables users to declare, manage, and fulfill future intentions or commitments on-chain.
// It incorporates concepts of on-chain reputation, soulbound tokens (SBTs), attestation, and challenge mechanisms
// to foster a robust network of verifiable commitments.

// --- Function Summary ---

// I. Core Intent Lifecycle Management
// 1.  proposeIntent(string memory _description, uint256 _deadline, address _targetAddress, uint256 _value, bytes32 _externalRefId):
//     Allows a user (Intent Weaver) to propose a new future intent with specific details and a deadline.
//     Returns a unique intentId.
// 2.  updateProposedIntent(uint256 _intentId, string memory _newDescription, uint256 _newDeadline, address _newTargetAddress, uint256 _newValue):
//     Permits the Intent Weaver to modify the details of their own intent before it becomes active.
// 3.  cancelProposedIntent(uint256 _intentId):
//     Enables the Intent Weaver to cancel their own intent if it is still in the 'Proposed' state.
// 4.  activateIntent(uint256 _intentId):
//     Transitions a 'Proposed' intent into an 'Active' state, marking the start of its commitment period.
// 5.  signalIntentFulfillment(uint256 _intentId, string memory _proofURI):
//     The Intent Weaver declares that they have fulfilled their active intent, providing a URI to off-chain proof.
// 6.  signalIntentFailure(uint256 _intentId, string memory _reasonURI):
//     The Intent Weaver declares that they have failed to fulfill their active intent, providing a reason URI.

// II. Attestation & Challenge System
// 7.  attestToIntentIntegrity(uint256 _intentId, bool _isLegitimate) payable:
//     A third party can vouch for (or against) the good faith and feasibility of a *proposed* intent.
//     Requires a small fee to prevent spam.
// 8.  challengeIntentIntegrity(uint256 _intentId, string memory _reasonURI) payable:
//     A third party can formally challenge the legitimacy or feasibility of a *proposed* intent.
//     Requires a stake.
// 9.  attestToIntentOutcome(uint256 _intentId, bool _isFulfilled, string memory _proofURI) payable:
//     A third party can attest to whether an *active* intent has truly been fulfilled or failed.
//     Requires a small fee.
// 10. challengeIntentOutcome(uint256 _intentId, string memory _reasonURI) payable:
//     A third party can formally challenge the claimed outcome (fulfillment or failure) of an active intent.
//     Requires a stake.
// 11. resolveChallenge(uint256 _intentId, bool _isChallengerCorrect):
//     An appointed resolver (e.g., a DAO or admin) makes a final decision on a disputed intent's integrity or outcome.
// 12. delegateIntentManagement(uint256 _intentId, address _delegatee):
//     The Intent Weaver can delegate the management (e.g., signalling fulfillment) rights of their intent to another address.

// III. Reputation & Incentive Mechanisms
// 13. claimReputationReward(uint256 _intentId):
//     (Internal/Reserved) Reputation rewards are managed internally by the resolver upon intent finalization.
// 14. penalizeIntentWeaver(uint256 _intentId, address _weaver):
//     Internal function to apply penalties (e.g., reputation deduction, collateral loss) for failed intents or false attestations.
// 15. mintReputationSBT(address _user, uint256 _reputationScore):
//     Mints a non-transferable "IntentWeaverReputation" Soulbound Token (SBT) for users reaching
//     significant reputation milestones (callable by owner, interacts with external SBT contract interface).
// 16. burnReputationSBT(address _user, uint256 _sbtId):
//     Burns an SBT from a user's wallet due to severe breaches of trust or protocol rules (callable by owner, interacts with external SBT contract interface).

// IV. Advanced Intent Features
// 17. attachCollateral(uint256 _intentId) payable:
//     Allows the Intent Weaver to stake collateral (ETH) for an intent, to be released on fulfillment or claimed on failure.
// 18. claimCollateral(uint256 _intentId):
//     Allows authorized parties (e.g., the resolver) to claim staked collateral upon a verified intent failure.
// 19. releaseCollateral(uint256 _intentId):
//     Releases the staked collateral back to the Intent Weaver upon verified successful fulfillment.
// 20. setIntentDependency(uint256 _intentId, uint256 _dependentIntentId):
//     Defines that `_intentId` can only be activated after `_dependentIntentId` is successfully completed.
// 21. proposeIntentAmendment(uint256 _intentId, string memory _newDescription, uint256 _newDeadline, address _newTargetAddress, uint256 _newValue):
//     Allows the Intent Weaver to propose changes to an *active* intent's terms. These amendments, for simplicity, apply directly.

// V. Protocol Governance & Utilities
// 22. setProtocolParameter(bytes32 _paramName, uint256 _value):
//     Allows the protocol admin/DAO to set various operational parameters (e.g., challenge periods, minimum stakes, fees).
// 23. withdrawProtocolFees():
//     Allows the protocol admin/DAO to withdraw accumulated fees from attestations and challenges.
// 24. getIntentDetails(uint256 _intentId):
//     A read-only function to retrieve all stored details and current status of a specific intent.
// 25. getChallengeDetails(uint256 _challengeId):
//     A read-only function to retrieve all stored details of a specific challenge.
// 26. getUserReputation(address _user):
//     A read-only function to get the current reputation score of a user.


// --- Interfaces ---

// Simplified interface for a hypothetical Soulbound Token (SBT) contract
interface IReputationSBT {
    function mint(address _to, uint256 _score) external returns (uint256 tokenId);
    function burn(address _from, uint256 _tokenId) external;
    // Add other relevant SBT functions as needed, e.g., getScore(address), getTokenId(address)
}


contract IntentWeave {

    // --- Enums ---

    enum IntentStatus {
        Proposed,      // Intent is declared but not yet active
        Active,        // Intent is active and the commitment period has started
        Fulfilled,     // Intent Weaver claims fulfillment, awaiting review/attestation/challenge
        Failed,        // Intent Weaver claims failure, awaiting review/attestation/challenge
        Disputed,      // Intent outcome is challenged, awaiting resolution by resolver
        Completed,     // Intent is successfully fulfilled and finalized
        Unfulfilled,   // Intent has failed and is finalized (could be due to actual failure or integrity challenge)
        Cancelled      // Intent was cancelled before activation
    }

    enum ChallengeStatus {
        NoChallenge,
        Pending,       // Challenge is active, awaiting resolution
        Resolved       // Challenge has been resolved
    }

    enum ChallengeType {
        Integrity,     // Challenge related to the initial intent proposal's validity
        Outcome        // Challenge related to the fulfillment/failure claim after activation
    }

    // --- Structs ---

    struct Intent {
        uint256 id;
        address weaver;             // The address who declared the intent
        address currentManager;     // Can be delegated from `weaver` to another address
        string description;
        uint256 creationTime;
        uint256 deadline;
        address targetAddress;      // An optional target for the intent (e.g., a contract, another user)
        uint256 value;              // An optional associated value (e.g., amount of ETH, number of tokens)
        bytes32 externalRefId;      // An optional external identifier for cross-system linkage
        IntentStatus status;
        uint256 collateralAmount;   // Amount of collateral (ETH) attached
        uint256 dependentIntentId;  // If this intent depends on another's completion (0 if none)
        bool collateralClaimable;   // True if collateral can be claimed (set by resolver)
        address[] integrityAttestors; // Addresses who attested to intent's integrity (for or against)
        address[] outcomeAttestors;   // Addresses who attested to intent's outcome (for or against)
        string proofURI;            // URI for fulfillment/failure proof or amendment details
    }

    struct Challenge {
        uint256 intentId;
        address challenger;
        ChallengeType challengeType;
        ChallengeStatus status;
        uint256 stake;
        string reasonURI;
        uint256 challengeTime;
        uint256 resolutionTime;
        bool challengerWon; // True if challenger's claim was upheld by the resolver
    }

    // --- State Variables ---

    uint256 public nextIntentId = 1;
    uint256 public nextChallengeId = 1;

    mapping(uint256 => Intent) public intents;
    mapping(uint256 => Challenge) public challenges; // Maps challenge ID to Challenge struct
    mapping(uint256 => uint256) public intentToChallengeId; // Maps intent ID to active challenge ID for that intent

    mapping(address => uint256) public intentWeaverReputation; // Simple reputation score for users
    mapping(address => uint256) public totalProtocolFees; // Accumulated fees from attestations/challenges, held by owner

    address public owner; // Protocol deployer/admin, also acts as fee collector
    address public resolver; // Address/DAO responsible for resolving challenges and managing penalties/rewards

    IReputationSBT public reputationSBT; // Interface to the SBT contract

    // Protocol parameters (configurable by admin/DAO)
    mapping(bytes32 => uint256) public protocolParameters;
    bytes32 constant PARAM_CHALLENGE_PERIOD = "CHALLENGE_PERIOD"; // in seconds
    bytes32 constant PARAM_MIN_INTEGRITY_ATTESTATION_FEE = "MIN_INTEGRITY_ATTESTATION_FEE"; // ETH
    bytes32 constant PARAM_MIN_OUTCOME_ATTESTATION_FEE = "MIN_OUTCOME_ATTESTATION_FEE"; // ETH
    bytes32 constant PARAM_MIN_CHALLENGE_STAKE = "MIN_CHALLENGE_STAKE"; // ETH
    bytes32 constant PARAM_REPUTATION_FOR_SBT_MINT = "REPUTATION_FOR_SBT_MINT"; // Reputation score required for SBT
    bytes32 constant PARAM_REPUTATION_REWARD_ATT = "REPUTATION_REWARD_ATT"; // Reputation points for correct attestors
    bytes32 constant PARAM_REPUTATION_PENALTY_ATT = "REPUTATION_PENALTY_ATT"; // Reputation penalty for false attestors
    bytes32 constant PARAM_REPUTATION_REWARD_WEAVER = "REPUTATION_REWARD_WEAVER"; // Reputation points for successful weavers
    bytes32 constant PARAM_REPUTATION_PENALTY_WEAVER = "REPUTATION_PENALTY_WEAVER"; // Reputation penalty for failed weavers
    bytes32 constant PARAM_REPUTATION_REWARD_CHALLENGER = "REPUTATION_REWARD_CHALLENGER"; // Reputation points for correct challengers

    // --- Events ---

    event IntentProposed(uint256 indexed intentId, address indexed weaver, string description, uint256 deadline);
    event IntentUpdated(uint256 indexed intentId, string newDescription, uint256 newDeadline);
    event IntentCancelled(uint256 indexed intentId, address indexed weaver);
    event IntentActivated(uint256 indexed intentId);
    event IntentFulfilled(uint256 indexed intentId, string proofURI);
    event IntentFailed(uint256 indexed intentId, string reasonURI);
    event IntentStatusChanged(uint256 indexed intentId, IntentStatus oldStatus, IntentStatus newStatus);

    event AttestationMade(uint256 indexed intentId, address indexed attestor, bool isPositive, ChallengeType challengeType);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed intentId, address indexed challenger, ChallengeType challengeType, uint256 stake);
    event ChallengeResolved(uint256 indexed challengeId, uint256 indexed intentId, bool challengerWon);
    event IntentDelegated(uint256 indexed intentId, address indexed delegator, address indexed delegatee);

    event CollateralAttached(uint256 indexed intentId, address indexed weaver, uint256 amount);
    event CollateralClaimed(uint256 indexed intentId, address indexed claimant, uint256 amount);
    event CollateralReleased(uint256 indexed intentId, address indexed weaver, uint256 amount);
    event IntentDependencySet(uint256 indexed intentId, uint256 indexed dependentIntentId);
    event IntentAmendmentProposed(uint256 indexed intentId, string newDescription, uint256 newDeadline);

    event ProtocolParameterSet(bytes32 indexed paramName, uint256 value);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event ReputationSBTMinted(address indexed user, uint256 indexed tokenId, uint256 reputationScore);
    event ReputationSBTBurned(address indexed user, uint256 indexed tokenId);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyResolver() {
        require(msg.sender == resolver, "IntentWeave: caller is not the resolver");
        _;
    }

    modifier onlyWeaverOrDelegatee(uint256 _intentId) {
        require(
            intents[_intentId].weaver == msg.sender || intents[_intentId].currentManager == msg.sender,
            "IntentWeave: Not intent weaver or delegatee"
        );
        _;
    }

    modifier onlyIfIntentExists(uint256 _intentId) {
        require(intents[_intentId].id != 0, "IntentWeave: Intent does not exist");
        _;
    }

    modifier onlyIfIntentStatus(uint256 _intentId, IntentStatus _status) {
        require(intents[_intentId].status == _status, "IntentWeave: Intent is not in the required status");
        _;
    }

    constructor(address _resolver, address _reputationSBTAddress) {
        owner = msg.sender;
        resolver = _resolver;
        reputationSBT = IReputationSBT(_reputationSBTAddress);

        // Set initial protocol parameters
        protocolParameters[PARAM_CHALLENGE_PERIOD] = 3 days; // 3 days for challenge resolution
        protocolParameters[PARAM_MIN_INTEGRITY_ATTESTATION_FEE] = 0.001 ether;
        protocolParameters[PARAM_MIN_OUTCOME_ATTESTATION_FEE] = 0.001 ether;
        protocolParameters[PARAM_MIN_CHALLENGE_STAKE] = 0.01 ether;
        protocolParameters[PARAM_REPUTATION_FOR_SBT_MINT] = 1000;
        protocolParameters[PARAM_REPUTATION_REWARD_ATT] = 50;
        protocolParameters[PARAM_REPUTATION_PENALTY_ATT] = 100;
        protocolParameters[PARAM_REPUTATION_REWARD_WEAVER] = 200;
        protocolParameters[PARAM_REPUTATION_PENALTY_WEAVER] = 300;
        protocolParameters[PARAM_REPUTATION_REWARD_CHALLENGER] = 150;
    }

    // Allows the contract to receive ETH for collateral, stakes, and fees
    receive() external payable {}

    // --- Helper Functions (Internal / View) ---

    function _updateIntentStatus(uint256 _intentId, IntentStatus _newStatus) internal {
        IntentStatus oldStatus = intents[_intentId].status;
        intents[_intentId].status = _newStatus;
        emit IntentStatusChanged(_intentId, oldStatus, _newStatus);
    }

    function _recordProtocolFee(uint256 _amount) internal {
        totalProtocolFees[owner] += _amount; // Fees go to the contract owner (can be a DAO treasury)
    }

    function _updateReputation(address _user, int256 _change) internal {
        if (_change > 0) {
            intentWeaverReputation[_user] += uint256(_change);
        } else {
            // Ensure reputation does not go below zero
            if (intentWeaverReputation[_user] < uint256(-_change)) {
                intentWeaverReputation[_user] = 0;
            } else {
                intentWeaverReputation[_user] -= uint256(-_change);
            }
        }
    }

    function _ensureNoActiveChallenge(uint256 _intentId) internal view {
        uint256 activeChallengeId = intentToChallengeId[_intentId];
        require(activeChallengeId == 0 || challenges[activeChallengeId].status != ChallengeStatus.Pending, "IntentWeave: Intent has an active challenge");
    }

    // --- I. Core Intent Lifecycle Management ---

    function proposeIntent(
        string memory _description,
        uint256 _deadline,
        address _targetAddress,
        uint256 _value,
        bytes32 _externalRefId
    ) public returns (uint256) {
        require(_deadline > block.timestamp, "IntentWeave: Deadline must be in the future");

        uint256 intentId = nextIntentId++;
        intents[intentId] = Intent({
            id: intentId,
            weaver: msg.sender,
            currentManager: msg.sender, // Initially, the weaver is the manager
            description: _description,
            creationTime: block.timestamp,
            deadline: _deadline,
            targetAddress: _targetAddress,
            value: _value,
            externalRefId: _externalRefId,
            status: IntentStatus.Proposed,
            collateralAmount: 0,
            dependentIntentId: 0,
            collateralClaimable: false,
            integrityAttestors: new address[](0),
            outcomeAttestors: new address[](0),
            proofURI: "" // No proof needed at proposal stage
        });
        emit IntentProposed(intentId, msg.sender, _description, _deadline);
        return intentId;
    }

    function updateProposedIntent(
        uint256 _intentId,
        string memory _newDescription,
        uint256 _newDeadline,
        address _newTargetAddress,
        uint256 _newValue
    ) public onlyWeaverOrDelegatee(_intentId) onlyIfIntentStatus(_intentId, IntentStatus.Proposed) {
        require(_newDeadline > block.timestamp, "IntentWeave: New deadline must be in the future");
        _ensureNoActiveChallenge(_intentId);

        Intent storage intent = intents[_intentId];
        intent.description = _newDescription;
        intent.deadline = _newDeadline;
        intent.targetAddress = _newTargetAddress;
        intent.value = _newValue;

        emit IntentUpdated(_intentId, _newDescription, _newDeadline);
    }

    function cancelProposedIntent(uint256 _intentId)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Proposed)
    {
        _ensureNoActiveChallenge(_intentId);
        _updateIntentStatus(_intentId, IntentStatus.Cancelled);
        emit IntentCancelled(_intentId, intents[_intentId].weaver);
    }

    function activateIntent(uint256 _intentId)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Proposed)
    {
        _ensureNoActiveChallenge(_intentId);
        require(intents[_intentId].deadline > block.timestamp, "IntentWeave: Cannot activate an intent with a past deadline");

        // If it has a dependency, check if it's fulfilled
        if (intents[_intentId].dependentIntentId != 0) {
            require(intents[intents[_intentId].dependentIntentId].status == IntentStatus.Completed, "IntentWeave: Dependent intent not completed");
        }

        _updateIntentStatus(_intentId, IntentStatus.Active);
        emit IntentActivated(_intentId);
    }

    function signalIntentFulfillment(uint256 _intentId, string memory _proofURI)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Active)
    {
        _ensureNoActiveChallenge(_intentId);
        require(block.timestamp <= intents[_intentId].deadline, "IntentWeave: Deadline has passed for fulfillment");

        intents[_intentId].proofURI = _proofURI;
        _updateIntentStatus(_intentId, IntentStatus.Fulfilled);
        emit IntentFulfilled(_intentId, _proofURI);
    }

    function signalIntentFailure(uint256 _intentId, string memory _reasonURI)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Active)
    {
        _ensureNoActiveChallenge(_intentId);

        // Can signal failure any time during active period, or after deadline
        intents[_intentId].proofURI = _reasonURI; // Using proofURI field for reasonURI here
        _updateIntentStatus(_intentId, IntentStatus.Failed);
        emit IntentFailed(_intentId, _reasonURI);
    }

    // --- II. Attestation & Challenge System ---

    function attestToIntentIntegrity(uint256 _intentId, bool _isLegitimate) public payable onlyIfIntentExists(_intentId) {
        require(intents[_intentId].status == IntentStatus.Proposed, "IntentWeave: Can only attest integrity for proposed intents");
        require(msg.value >= protocolParameters[PARAM_MIN_INTEGRITY_ATTESTATION_FEE], "IntentWeave: Insufficient attestation fee");
        _recordProtocolFee(msg.value);

        // Prevent double attestation from the same address for integrity
        for (uint i = 0; i < intents[_intentId].integrityAttestors.length; i++) {
            require(intents[_intentId].integrityAttestors[i] != msg.sender, "IntentWeave: Already attested to integrity");
        }
        intents[_intentId].integrityAttestors.push(msg.sender);

        // The _isLegitimate parameter would inform the resolver's decision.
        emit AttestationMade(_intentId, msg.sender, _isLegitimate, ChallengeType.Integrity);
    }

    function challengeIntentIntegrity(uint256 _intentId, string memory _reasonURI) public payable onlyIfIntentExists(_intentId) {
        require(intents[_intentId].status == IntentStatus.Proposed, "IntentWeave: Can only challenge integrity of proposed intents");
        require(msg.value >= protocolParameters[PARAM_MIN_CHALLENGE_STAKE], "IntentWeave: Insufficient challenge stake");
        _ensureNoActiveChallenge(_intentId); // Only one active challenge per intent

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            intentId: _intentId,
            challenger: msg.sender,
            challengeType: ChallengeType.Integrity,
            status: ChallengeStatus.Pending,
            stake: msg.value,
            reasonURI: _reasonURI,
            challengeTime: block.timestamp,
            resolutionTime: 0,
            challengerWon: false
        });
        intentToChallengeId[_intentId] = challengeId;
        _updateIntentStatus(_intentId, IntentStatus.Disputed); // Intent becomes disputed
        emit ChallengeInitiated(challengeId, _intentId, msg.sender, ChallengeType.Integrity, msg.value);
    }

    function attestToIntentOutcome(uint256 _intentId, bool _isFulfilled, string memory _proofURI) public payable onlyIfIntentExists(_intentId) {
        require(intents[_intentId].status == IntentStatus.Fulfilled || intents[_intentId].status == IntentStatus.Failed,
            "IntentWeave: Can only attest outcome for fulfilled or failed intents");
        require(msg.value >= protocolParameters[PARAM_MIN_OUTCOME_ATTESTATION_FEE], "IntentWeave: Insufficient attestation fee");
        _recordProtocolFee(msg.value);

        // Prevent double attestation from the same address for outcome
        for (uint i = 0; i < intents[_intentId].outcomeAttestors.length; i++) {
            require(intents[_intentId].outcomeAttestors[i] != msg.sender, "IntentWeave: Already attested to outcome");
        }
        intents[_intentId].outcomeAttestors.push(msg.sender);

        // This attestation could support or refute the weaver's claim or an active challenge
        emit AttestationMade(_intentId, msg.sender, _isFulfilled, ChallengeType.Outcome);
    }

    function challengeIntentOutcome(uint256 _intentId, string memory _reasonURI) public payable onlyIfIntentExists(_intentId) {
        require(intents[_intentId].status == IntentStatus.Fulfilled || intents[_intentId].status == IntentStatus.Failed,
            "IntentWeave: Can only challenge outcome of fulfilled or failed intents");
        require(msg.value >= protocolParameters[PARAM_MIN_CHALLENGE_STAKE], "IntentWeave: Insufficient challenge stake");
        _ensureNoActiveChallenge(_intentId); // Only one active challenge per intent

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            intentId: _intentId,
            challenger: msg.sender,
            challengeType: ChallengeType.Outcome,
            status: ChallengeStatus.Pending,
            stake: msg.value,
            reasonURI: _reasonURI,
            challengeTime: block.timestamp,
            resolutionTime: 0,
            challengerWon: false
        });
        intentToChallengeId[_intentId] = challengeId;
        _updateIntentStatus(_intentId, IntentStatus.Disputed); // Intent becomes disputed
        emit ChallengeInitiated(challengeId, _intentId, msg.sender, ChallengeType.Outcome, msg.value);
    }

    function resolveChallenge(uint256 _intentId, bool _isChallengerCorrect) public onlyResolver onlyIfIntentExists(_intentId) {
        uint256 challengeId = intentToChallengeId[_intentId];
        require(challengeId != 0 && challenges[challengeId].status == ChallengeStatus.Pending, "IntentWeave: No active challenge for this intent");
        require(block.timestamp >= challenges[challengeId].challengeTime + protocolParameters[PARAM_CHALLENGE_PERIOD], "IntentWeave: Challenge period not over");

        Challenge storage challenge = challenges[challengeId];
        Intent storage intent = intents[_intentId];

        challenge.status = ChallengeStatus.Resolved;
        challenge.resolutionTime = block.timestamp;
        challenge.challengerWon = _isChallengerCorrect;

        if (_isChallengerCorrect) {
            // Challenger wins:
            // Challenger gets their stake back + a reputation reward
            (bool sent, ) = challenge.challenger.call{value: challenge.stake}("");
            require(sent, "Failed to return challenger stake");
            _updateReputation(challenge.challenger, int256(protocolParameters[PARAM_REPUTATION_REWARD_CHALLENGER]));

            if (challenge.challengeType == ChallengeType.Integrity) {
                // If integrity challenge won, the proposed intent is deemed invalid.
                _updateIntentStatus(_intentId, IntentStatus.Unfulfilled);
            } else { // Outcome challenge
                // Challenger proved weaver's claim was false. Penalize weaver.
                _updateReputation(intent.weaver, -int256(protocolParameters[PARAM_REPUTATION_PENALTY_WEAVER]));
                if (intent.status == IntentStatus.Fulfilled) { // Weaver claimed fulfilled, but challenger proved it was not.
                    _updateIntentStatus(_intentId, IntentStatus.Unfulfilled);
                } else if (intent.status == IntentStatus.Failed) { // Weaver claimed failed, challenger proved it was fulfilled.
                    _updateIntentStatus(_intentId, IntentStatus.Completed);
                }
                intent.collateralClaimable = true; // Allow claiming collateral on weaver's verified failure
            }
        } else {
            // Challenger loses:
            // Challenger's stake is forfeited to the protocol.
            _recordProtocolFee(challenge.stake);
            // Challenger does not receive reputation reward, no penalty for losing the challenge, just forfeits stake.

            if (challenge.challengeType == ChallengeType.Integrity) {
                // If integrity challenge lost, the intent's proposal stands. Revert to Proposed status.
                _updateIntentStatus(_intentId, IntentStatus.Proposed);
            } else { // Outcome challenge
                // If outcome challenge lost, weaver's claim stands. Reward weaver.
                if (intent.status == IntentStatus.Fulfilled) {
                    _updateIntentStatus(_intentId, IntentStatus.Completed);
                    _updateReputation(intent.weaver, int252(protocolParameters[PARAM_REPUTATION_REWARD_WEAVER]));
                } else if (intent.status == IntentStatus.Failed) {
                    _updateIntentStatus(_intentId, IntentStatus.Unfulfilled);
                }
            }
        }

        intentToChallengeId[_intentId] = 0; // Clear active challenge reference
        emit ChallengeResolved(challengeId, _intentId, _isChallengerCorrect);
    }

    function delegateIntentManagement(uint256 _intentId, address _delegatee)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Proposed) // Can only delegate before activation
    {
        require(_delegatee != address(0), "IntentWeave: Delegatee cannot be zero address");
        intents[_intentId].currentManager = _delegatee;
        emit IntentDelegated(_intentId, msg.sender, _delegatee);
    }

    // --- III. Reputation & Incentive Mechanisms ---

    function claimReputationReward(uint256 _intentId) public {
        // This function is intended to be managed internally by `resolveChallenge` or similar finalization logic.
        // It's kept here as a placeholder for a more complex external claim mechanism if desired,
        // but for this implementation, reputation is updated directly by the resolver.
        revert("IntentWeave: Reputation rewards are managed internally by the resolver.");
    }

    // This function is intended to be called internally by `resolveChallenge` or other penalty mechanisms
    function penalizeIntentWeaver(uint256 _intentId, address _weaver) internal {
        _updateReputation(_weaver, -int256(protocolParameters[PARAM_REPUTATION_PENALTY_WEAVER]));
        // Additional penalties like collateral confiscation are handled in resolveChallenge.
    }

    function mintReputationSBT(address _user, uint256 _reputationScore) public onlyOwner {
        require(reputationSBT != IReputationSBT(address(0)), "IntentWeave: SBT contract not set");
        // In a real scenario, this would likely be triggered by reaching a specific reputation threshold
        // and involve checking `intentWeaverReputation[_user]` against `PARAM_REPUTATION_FOR_SBT_MINT`
        // before calling the SBT contract. For this example, it's an admin-callable simulation.
        require(_reputationScore >= protocolParameters[PARAM_REPUTATION_FOR_SBT_MINT], "IntentWeave: Insufficient reputation for SBT mint");
        uint256 tokenId = reputationSBT.mint(_user, _reputationScore);
        emit ReputationSBTMinted(_user, tokenId, _reputationScore);
    }

    function burnReputationSBT(address _user, uint256 _sbtId) public onlyOwner {
        require(reputationSBT != IReputationSBT(address(0)), "IntentWeave: SBT contract not set");
        // In a real scenario, this would likely be triggered by severe protocol violations detected by the DAO/resolver.
        reputationSBT.burn(_user, _sbtId);
        emit ReputationSBTBurned(_user, _sbtId);
    }

    // --- IV. Advanced Intent Features ---

    function attachCollateral(uint256 _intentId) public payable onlyWeaverOrDelegatee(_intentId) {
        require(msg.value > 0, "IntentWeave: Collateral amount must be greater than zero");
        require(intents[_intentId].status == IntentStatus.Proposed || intents[_intentId].status == IntentStatus.Active, "IntentWeave: Collateral can only be attached to proposed or active intents");
        _ensureNoActiveChallenge(_intentId);

        intents[_intentId].collateralAmount += msg.value;
        emit CollateralAttached(_intentId, msg.sender, msg.value);
    }

    function claimCollateral(uint256 _intentId) public onlyResolver {
        Intent storage intent = intents[_intentId];
        require(intent.id != 0, "IntentWeave: Intent does not exist");
        require(intent.status == IntentStatus.Unfulfilled, "IntentWeave: Collateral can only be claimed for unfulfilled intents");
        require(intent.collateralAmount > 0, "IntentWeave: No collateral attached");
        require(intent.collateralClaimable, "IntentWeave: Collateral not yet claimable (must be set by resolver)");

        uint256 amountToClaim = intent.collateralAmount;
        intent.collateralAmount = 0; // Clear collateral amount
        intent.collateralClaimable = false; // Reset flag

        // In this simplified version, the resolver claims the collateral.
        // A more complex system might distribute it to winning challengers or a DAO treasury.
        (bool sent, ) = msg.sender.call{value: amountToClaim}("");
        require(sent, "Failed to send collateral to claimant");

        emit CollateralClaimed(_intentId, msg.sender, amountToClaim);
    }

    function releaseCollateral(uint256 _intentId) public onlyWeaverOrDelegatee(_intentId) {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Completed, "IntentWeave: Collateral can only be released for completed intents");
        require(intent.collateralAmount > 0, "IntentWeave: No collateral attached");

        uint256 amountToRelease = intent.collateralAmount;
        intent.collateralAmount = 0; // Clear collateral amount

        (bool sent, ) = intent.weaver.call{value: amountToRelease}("");
        require(sent, "Failed to release collateral to weaver");

        emit CollateralReleased(_intentId, intent.weaver, amountToRelease);
    }

    function setIntentDependency(uint256 _intentId, uint256 _dependentIntentId)
        public
        onlyWeaverOrDelegatee(_intentId)
        onlyIfIntentStatus(_intentId, IntentStatus.Proposed)
    {
        require(_intentId != _dependentIntentId, "IntentWeave: Intent cannot depend on itself");
        require(intents[_dependentIntentId].id != 0, "IntentWeave: Dependent intent does not exist");
        require(intents[_dependentIntentId].weaver == intents[_intentId].weaver, "IntentWeave: Dependent intent must be by the same weaver");
        // Could be extended to allow cross-weaver dependencies with more complex logic.

        intents[_intentId].dependentIntentId = _dependentIntentId;
        emit IntentDependencySet(_intentId, _dependentIntentId);
    }

    function proposeIntentAmendment(
        uint256 _intentId,
        string memory _newDescription,
        uint256 _newDeadline,
        address _newTargetAddress,
        uint256 _newValue
    ) public onlyWeaverOrDelegatee(_intentId) onlyIfIntentStatus(_intentId, IntentStatus.Active) {
        require(_newDeadline > block.timestamp, "IntentWeave: New deadline must be in the future");
        _ensureNoActiveChallenge(_intentId);

        // For simplicity, amendment is proposed and automatically applies.
        // In a more advanced version, this would trigger a new 'amendmentProposed' state, requiring
        // attestation from interested parties or a short challenge period before an `applyIntentAmendment` call.
        Intent storage intent = intents[_intentId];
        intent.description = _newDescription;
        intent.deadline = _newDeadline;
        intent.targetAddress = _newTargetAddress;
        intent.value = _newValue;

        emit IntentAmendmentProposed(_intentId, _newDescription, _newDeadline);
    }

    // --- V. Protocol Governance & Utilities ---

    function setProtocolParameter(bytes32 _paramName, uint256 _value) public onlyOwner {
        protocolParameters[_paramName] = _value;
        emit ProtocolParameterSet(_paramName, _value);
    }

    function withdrawProtocolFees() public onlyOwner {
        uint256 fees = totalProtocolFees[owner];
        require(fees > 0, "IntentWeave: No fees to withdraw");
        totalProtocolFees[owner] = 0;
        (bool sent, ) = owner.call{value: fees}("");
        require(sent, "Failed to withdraw fees");
        emit ProtocolFeesWithdrawn(owner, fees);
    }

    function getIntentDetails(uint256 _intentId) public view onlyIfIntentExists(_intentId) returns (
        uint256 id,
        address weaver,
        address currentManager,
        string memory description,
        uint256 creationTime,
        uint256 deadline,
        address targetAddress,
        uint256 value,
        bytes32 externalRefId,
        IntentStatus status,
        uint256 collateralAmount,
        uint256 dependentIntentId,
        bool collateralClaimable,
        address[] memory integrityAttestors,
        address[] memory outcomeAttestors,
        string memory proofURI
    ) {
        Intent storage intent = intents[_intentId];
        return (
            intent.id,
            intent.weaver,
            intent.currentManager,
            intent.description,
            intent.creationTime,
            intent.deadline,
            intent.targetAddress,
            intent.value,
            intent.externalRefId,
            intent.status,
            intent.collateralAmount,
            intent.dependentIntentId,
            intent.collateralClaimable,
            intent.integrityAttestors,
            intent.outcomeAttestors,
            intent.proofURI
        );
    }

    function getChallengeDetails(uint256 _challengeId) public view returns (
        uint256 intentId,
        address challenger,
        ChallengeType challengeType,
        ChallengeStatus status,
        uint256 stake,
        string memory reasonURI,
        uint256 challengeTime,
        uint256 resolutionTime,
        bool challengerWon
    ) {
        require(challenges[_challengeId].intentId != 0, "IntentWeave: Challenge does not exist");
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.intentId,
            challenge.challenger,
            challenge.challengeType,
            challenge.status,
            challenge.stake,
            challenge.reasonURI,
            challenge.challengeTime,
            challenge.resolutionTime,
            challenge.challengerWon
        );
    }

    function getUserReputation(address _user) public view returns (uint256) {
        return intentWeaverReputation[_user];
    }
}
```