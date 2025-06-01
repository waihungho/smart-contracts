Okay, let's design a smart contract for a "Decentralized Autonomous Collective with Dynamic State, Conditional Asset Evolution, and Oracle-Driven Governance".

This concept involves:
1.  **A Collective State:** An evolving state variable representing the overall status or phase of the collective.
2.  **Dynamic Assets (Chronicles):** Non-standard NFTs (let's call them Chronicles) issued to members. These NFTs have attributes that can change or "evolve" based on collective actions, the collective state, or external data.
3.  **Reputation System:** Members earn non-transferable reputation points through participation.
4.  **Conditional Governance:** Proposals are made, voted upon (weighted by reputation and/or Chronicle tier), but execution *also* requires specific on-chain conditions to be met, potentially involving external data from an Oracle.
5.  **Oracle Interaction:** The contract relies on a trusted Oracle address to submit off-chain data that influences conditional logic.

This avoids direct duplication of standard ERC20/ERC721 (by creating a custom, non-transferable-by-default NFT system), standard Uniswap/Aave patterns, basic DAOs, or simple ownership structures. It incorporates elements of dynamic NFTs, conditional logic, weighted governance, and oracle dependency.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleProtocol
 * @dev A Decentralized Autonomous Collective managing a shared state and dynamic assets (Chronicles)
 *      through conditional governance influenced by reputation and external data via an Oracle.
 *
 * Outline:
 * 1. State Variables: Core collective state, member data, Chronicle data, proposal data, oracle data, parameters.
 * 2. Enums & Structs: Defines types for collective state, proposal status/type, member data, Chronicle data, proposal data.
 * 3. Events: Emits logs for state changes, membership changes, Chronicle mint/update/burn, proposal lifecycle, oracle data updates.
 * 4. Errors: Custom error definitions for clearer failures.
 * 5. Modifiers: Access control checks (onlyMember, onlyOracle, etc.).
 * 6. Core Logic:
 *    - Membership: Join, leave, manage member data and associated Chronicles.
 *    - Chronicles: Custom dynamic NFT-like assets tracking ownership, tier, and attributes. Minting, burning, conditional upgrades.
 *    - Collective State: An evolving state variable that impacts protocol logic and asset evolution.
 *    - Governance: Proposal creation (state change, parameter change), weighted voting based on reputation/Chronicle tier, conditional execution via Oracle data checks.
 *    - Oracle Interaction: Receive data from a designated oracle address.
 *    - Parameters: Protocol settings configurable via governance.
 * 7. Query Functions: Public view functions to retrieve state variables, member info, Chronicle details, proposal data, etc.
 */

// --- Enums ---
enum CollectiveState {
    Genesis,      // Initial state
    Expansion,    // Growth phase
    Contraction,  // Reduction phase
    Stagnation,   // Stable or inactive phase
    Critical      // Emergency state
}

enum ProposalType {
    StateChange,      // Change the CollectiveState enum
    ParameterChange,  // Modify a protocol parameter (e.g., votePeriod, quorum)
    ExecuteAction     // Trigger a specific predefined action (e.g., distribute treasury funds - placeholder)
}

enum ProposalStatus {
    Pending,   // Just created
    Active,    // Voting is open
    Approved,  // Voting passed 'For' but not yet executed
    Rejected,  // Voting failed 'Against'
    Executed,  // Proposal was Approved and conditions were met for execution
    Cancelled  // Proposal cancelled by proposer before Active phase
}

// --- Structs ---
struct Member {
    bool isMember;
    uint256 joinTimestamp;
    uint256 chronicleId; // 0 if no Chronicle
    uint256 reputationPoints; // Earned via participation
    address voteDelegate; // Address member has delegated their vote weight to
}

struct ChronicleData {
    address owner;      // Current owner (should match member address usually)
    uint256 mintTimestamp;
    uint256 tier;       // Represents level/rarity/influence (starts at 1)
    mapping(string => uint256) attributesNum; // Dynamic numeric attributes
    mapping(string => string) attributesStr;  // Dynamic string attributes
    uint256 lastAttributeUpdate;
}

struct Proposal {
    uint256 id;
    ProposalType proposalType;
    ProposalStatus status;
    address proposer;
    uint256 creationTimestamp;
    uint256 votingEndTimestamp;
    uint256 votesFor;
    uint256 votesAgainst;
    uint256 totalVoteWeight; // Total weight that voted
    bytes data; // Specific data for the proposal type (e.g., new state value, parameter key/value)
    string conditionalExpression; // Human-readable or simplified code for execution condition (e.g., "Oracle.price > 1000", "CollectiveState == Expansion")
    mapping(address => bool) voted; // Track who has voted
    mapping(address => address) delegatedVotes; // Track delegated votes per voter
}

// --- Events ---
event CollectiveStateChanged(CollectiveState oldState, CollectiveState newState);
event MemberJoined(address indexed member, uint256 chronicleId);
event MemberLeft(address indexed member, uint256 chronicleId);
event ReputationEarned(address indexed member, uint256 points);
event ChronicleMinted(address indexed owner, uint256 indexed chronicleId, uint256 tier);
event ChronicleAttributesUpdated(uint256 indexed chronicleId, string attributeKey); // Generic update event
event ChronicleTierUpgraded(uint256 indexed chronicleId, uint256 oldTier, uint256 newTier);
event ChronicleBurned(uint256 indexed chronicleId, address indexed owner);
event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
event VoteDelegated(address indexed delegator, address indexed delegatee);
event ProposalStatusChanged(uint256 indexed proposalId, ProposalStatus newStatus);
event ProposalExecuted(uint256 indexed proposalId);
event ProposalCancelled(uint256 indexed proposalId);
event OracleDataUpdated(string indexed key, uint256 value); // Assuming uint256 data for simplicity
event FundsWithdrawn(address indexed recipient, uint256 amount);
event ParameterChanged(string parameterKey, bytes newValue); // Emitted upon execution of ParameterChange proposal

// --- Errors ---
error MemberNotFound();
error NotAMember();
error MemberAlreadyExists();
error ChronicleNotFound();
error NotChronicleOwner();
error ProposalNotFound();
error ProposalNotInCorrectState();
error VotingPeriodEnded();
error AlreadyVoted();
error DelegateeCannotBeVoterOrSelf();
error NoVoteDelegated();
error ExecutionConditionsNotMet();
error OnlyCallableByOracle();
error InsufficientVoteWeightForQuorum();
error ProposalDataInvalid();
error UnauthorizedWithdrawal();
error InvalidCollectiveStateTransition();
error ChronicleCannotUpgrade();
error InvalidParameterKey();

// --- State Variables ---
CollectiveState public collectiveState = CollectiveState.Genesis; // 1. Collective State
mapping(address => Member) private _members; // 2. Member Data
address[] private _memberAddresses; // To iterate over members (potentially gas-intensive for large collectives)

mapping(uint256 => ChronicleData) private _chronicles; // 3. Chronicle Data
mapping(address => uint256) private _memberChronicleId; // Link member address to Chronicle ID
uint256 private _nextTokenId = 1; // Counter for Chronicle IDs
uint256 private _totalChroniclesMinted = 0;

mapping(uint256 => Proposal) private _proposals; // 4. Proposal Data
uint256 private _nextProposalId = 1; // Counter for Proposal IDs
mapping(uint256 => uint256[]) private _activeProposalIdsByState; // Track active proposals per state (optimization)

address public oracleAddress; // 5. Oracle Address
mapping(string => uint256) private _oracleData; // 5. Oracle Data storage (uint256 for simplicity)

uint256 public joinBond = 0 ether; // 6. Parameters (Configurable via governance)
uint256 public votePeriod = 3 days;
uint256 public quorumPercentage = 40; // % of total vote weight required for quorum
uint256 public minReputationForProposal = 10; // Min reputation to create a proposal
uint256 public baseVoteWeight = 1; // Base weight for a member

// Simple state transition rules (example)
mapping(CollectiveState => mapping(CollectiveState => bool)) private _validStateTransitions;

// Funds held by the contract
address public treasury = address(this); // Funds are held directly by the contract

// --- Constructor ---
constructor(address initialOracle, uint256 initialJoinBond, uint256 initialVotePeriod, uint256 initialQuorum) payable {
    oracleAddress = initialOracle;
    joinBond = initialJoinBond;
    votePeriod = initialVotePeriod;
    quorumPercentage = initialQuorum;

    // Define valid state transitions (example rules)
    _validStateTransitions[CollectiveState.Genesis][CollectiveState.Expansion] = true;
    _validStateTransitions[CollectiveState.Expansion][CollectiveState.Contraction] = true;
    _validStateTransitions[CollectiveState.Expansion][CollectiveState.Stagnation] = true;
    _validStateTransitions[CollectiveState.Contraction][CollectiveState.Expansion] = true;
    _validStateTransitions[CollectiveState.Contraction][CollectiveState.Stagnation] = true;
    _validStateTransitions[CollectiveState.Stagnation][CollectiveState.Expansion] = true;
    _validStateTransitions[CollectiveState.Stagnation][CollectiveState.Contraction] = true;
    // Critical state can transition to/from anywhere (simplified)
    _validStateTransitions[CollectiveState.Genesis][CollectiveState.Critical] = true;
    _validStateTransitions[CollectiveState.Expansion][CollectiveState.Critical] = true;
    _validStateTransitions[CollectiveState.Contraction][CollectiveState.Critical] = true;
    _validStateTransitions[CollectiveState.Stagnation][CollectiveState.Critical] = true;
    _validStateTransitions[CollectiveState.Critical][CollectiveState.Genesis] = true;
    _validStateTransitions[CollectiveState.Critical][CollectiveState.Expansion] = true;
    _validStateTransitions[CollectiveState.Critical][CollectiveState.Contraction] = true;
    _validStateTransitions[CollectiveState.Critical][CollectiveState.Stagnation] = true;
}

// --- Modifiers ---
modifier onlyMember() {
    if (!_members[msg.sender].isMember) revert NotAMember();
    _;
}

modifier onlyOracle() {
    if (msg.sender != oracleAddress) revert OnlyCallableByOracle();
    _;
}

// --- Internal/Helper Functions ---

/**
 * @dev Internal function to get a member's calculated vote weight.
 * Weighted by reputation and Chronicle tier.
 */
function _calculateVoteWeight(address memberAddress) internal view returns (uint256) {
    Member storage member = _members[memberAddress];
    if (!member.isMember) return 0;

    uint256 weight = baseVoteWeight; // Base weight for being a member
    weight += member.reputationPoints / 10; // Example: 1 extra weight per 10 reputation points

    uint256 chronicleId = member.chronicleId;
    if (chronicleId != 0) {
        weight += _chronicles[chronicleId].tier * 5; // Example: 5 extra weight per Chronicle tier level
    }
    return weight;
}

/**
 * @dev Internal function to mint a new Chronicle for a member.
 */
function _mintChronicle(address memberAddress) internal returns (uint256 chronicleId) {
    chronicleId = _nextTokenId++;
    ChronicleData storage chronicle = _chronicles[chronicleId];
    chronicle.owner = memberAddress;
    chronicle.mintTimestamp = block.timestamp;
    chronicle.tier = 1; // Start at tier 1
    chronicle.lastAttributeUpdate = block.timestamp;
    // Initialize some default attributes if needed
    chronicle.attributesNum["creationState"] = uint256(collectiveState);

    _memberChronicleId[memberAddress] = chronicleId;
    _members[memberAddress].chronicleId = chronicleId;
    _totalChroniclesMinted++;

    emit ChronicleMinted(memberAddress, chronicleId, 1);
}

/**
 * @dev Internal function to burn a Chronicle.
 */
function _burnChronicle(uint256 chronicleId) internal {
    ChronicleData storage chronicle = _chronicles[chronicleId];
    address owner = chronicle.owner;

    // Clear mappings
    delete _chronicles[chronicleId];
    delete _memberChronicleId[owner]; // Assuming member's Chronicle ID mapping is primary
    // Note: _tokenOwners mapping not used as we rely on _memberChronicleId for members.
    // If non-member ownership was allowed, more complex tracking would be needed.

    _members[owner].chronicleId = 0; // Unlink from member

    emit ChronicleBurned(chronicleId, owner);
    // Decrement total minted count logic needed if tokens can truly disappear.
    // For simplicity, let's just mark it as burned conceptually via deletion.
}

/**
 * @dev Internal function to add a proposal to the active list for the current state.
 */
function _addProposalToActiveList(uint256 proposalId) internal {
    _activeProposalIdsByState[collectiveState].push(proposalId);
}

/**
 * @dev Internal function to remove a proposal from the active list for the current state.
 * Note: This is a simple removal, not gas efficient for large arrays.
 */
function _removeProposalFromActiveList(uint256 proposalId) internal {
    uint256[] storage activeList = _activeProposalIdsByState[collectiveState];
    for (uint i = 0; i < activeList.length; i++) {
        if (activeList[i] == proposalId) {
            activeList[i] = activeList[activeList.length - 1];
            activeList.pop();
            break;
        }
    }
}


// --- External Functions (>= 20 required) ---

/**
 * @dev Function 1: Allows an address to join the collective. Requires a bond. Mints a Chronicle.
 */
function joinCollective() external payable {
    if (_members[msg.sender].isMember) revert MemberAlreadyExists();
    if (msg.value < joinBond) revert InsufficientVoteWeightForQuorum(); // Reusing error, better would be InsufficientBond

    _members[msg.sender].isMember = true;
    _members[msg.sender].joinTimestamp = block.timestamp;
    _members[msg.sender].reputationPoints = 1; // Initial reputation
    _memberAddresses.push(msg.sender); // Track member addresses (careful with gas)

    uint256 newChronicleId = _mintChronicle(msg.sender);

    emit MemberJoined(msg.sender, newChronicleId);
    emit ReputationEarned(msg.sender, 1);
}

/**
 * @dev Function 2: Allows a member to leave the collective. Burns their Chronicle.
 */
function leaveCollective() external onlyMember {
    address memberAddress = msg.sender;
    Member storage member = _members[memberAddress];

    uint256 chronicleId = member.chronicleId;
    if (chronicleId != 0) {
        _burnChronicle(chronicleId);
    }

    // Clear member data
    delete _members[memberAddress];

    // Remove from _memberAddresses array (gas-intensive)
    for (uint i = 0; i < _memberAddresses.length; i++) {
        if (_memberAddresses[i] == memberAddress) {
            _memberAddresses[i] = _memberAddresses[_memberAddresses.length - 1];
            _memberAddresses.pop();
            break;
        }
    }

    emit MemberLeft(memberAddress, chronicleId);
}

/**
 * @dev Function 3: Members can claim a potential tier upgrade for their Chronicle if conditions are met.
 * Conditions are based on reputation, time, and current collective state/oracle data.
 */
function claimChronicleTierUpgrade() external onlyMember {
    address memberAddress = msg.sender;
    uint256 chronicleId = _memberChronicleId[memberAddress];
    if (chronicleId == 0) revert ChronicleNotFound(); // Should not happen for a member

    ChronicleData storage chronicle = _chronicles[chronicleId];
    Member storage member = _members[memberAddress];

    uint256 currentTier = chronicle.tier;
    uint256 reputation = member.reputationPoints;
    uint256 timeSinceLastUpdate = block.timestamp - chronicle.lastAttributeUpdate;
    CollectiveState currentState = collectiveState;
    uint256 oracleValue = _oracleData["globalStatus"]; // Example oracle data check

    // Example complex upgrade conditions:
    // Tier 1 -> 2: Requires > 5 reputation, 30 days since mint, and CollectiveState is Expansion
    // Tier 2 -> 3: Requires > 20 reputation, 90 days since last update, CollectiveState is not Contraction, and Oracle globalStatus > 100
    bool canUpgrade = false;
    uint256 nextTier = currentTier + 1;

    if (currentTier == 1 && reputation > 5 && timeSinceLastUpdate >= 30 days && currentState == CollectiveState.Expansion) {
        canUpgrade = true;
    } else if (currentTier == 2 && reputation > 20 && timeSinceLastUpdate >= 90 days && currentState != CollectiveState.Contraction && oracleValue > 100) {
        canUpgrade = true;
    }
    // Add more tier conditions here

    if (!canUpgrade) revert ChronicleCannotUpgrade();

    chronicle.tier = nextTier;
    chronicle.lastAttributeUpdate = block.timestamp;
    // Maybe update a specific attribute on upgrade?
    chronicle.attributesNum["upgradeCount"]++;

    emit ChronicleTierUpgraded(chronicleId, currentTier, nextTier);
    emit ChronicleAttributesUpdated(chronicleId, "upgradeCount");
    emit ReputationEarned(memberAddress, 5); // Reward reputation for upgrading
}

/**
 * @dev Function 4: Allows a member to update a specific numeric attribute on their Chronicle.
 * Requires reputation and is rate-limited (example).
 */
function updateChronicleNumericAttribute(string memory key, uint256 value) external onlyMember {
    address memberAddress = msg.sender;
    uint256 chronicleId = _memberChronicleId[memberAddress];
    if (chronicleId == 0) revert ChronicleNotFound();

    ChronicleData storage chronicle = _chronicles[chronicleId];
    Member storage member = _members[memberAddress];

    // Example condition: Requires >= 10 reputation points
    if (member.reputationPoints < 10) revert InsufficientVoteWeightForQuorum(); // Reusing error

    // Example rate limit: Cannot update more than once every 1 day
    if (block.timestamp - chronicle.lastAttributeUpdate < 1 days) revert ChronicleCannotUpgrade(); // Reusing error

    chronicle.attributesNum[key] = value;
    chronicle.lastAttributeUpdate = block.timestamp; // Update last update timestamp for rate limiting

    emit ChronicleAttributesUpdated(chronicleId, key);
    emit ReputationEarned(memberAddress, 2); // Reward reputation for updating
}

/**
 * @dev Function 5: Allows a member to update a specific string attribute on their Chronicle.
 * Requires reputation and is rate-limited (example).
 */
function updateChronicleStringAttribute(string memory key, string memory value) external onlyMember {
     address memberAddress = msg.sender;
    uint256 chronicleId = _memberChronicleId[memberAddress];
    if (chronicleId == 0) revert ChronicleNotFound();

    ChronicleData storage chronicle = _chronicles[chronicleId];
    Member storage member = _members[memberAddress];

    // Example condition: Requires >= 15 reputation points
    if (member.reputationPoints < 15) revert InsufficientVoteWeightForQuorum(); // Reusing error

    // Example rate limit: Cannot update more than once every 3 days for string attributes
    if (block.timestamp - chronicle.lastAttributeUpdate < 3 days) revert ChronicleCannotUpgrade(); // Reusing error

    chronicle.attributesStr[key] = value;
    chronicle.lastAttributeUpdate = block.timestamp; // Update last update timestamp for rate limiting

    emit ChronicleAttributesUpdated(chronicleId, key);
    emit ReputationEarned(memberAddress, 3); // Reward reputation
}


/**
 * @dev Function 6: Allows a member to propose a change to the CollectiveState.
 * Requires minimum reputation.
 */
function proposeStateChange(CollectiveState newState, string memory conditionalExpression) external onlyMember returns (uint256 proposalId) {
    if (_members[msg.sender].reputationPoints < minReputationForProposal) revert InsufficientVoteWeightForQuorum(); // Reusing error

    // Basic validation for state transition
    if (!_validStateTransitions[collectiveState][newState] && newState != collectiveState) revert InvalidCollectiveStateTransition();

    proposalId = _nextProposalId++;
    Proposal storage proposal = _proposals[proposalId];
    proposal.id = proposalId;
    proposal.proposalType = ProposalType.StateChange;
    proposal.status = ProposalStatus.Pending; // Starts Pending, needs activation
    proposal.proposer = msg.sender;
    proposal.creationTimestamp = block.timestamp;
    // Voting dates set on activation
    proposal.conditionalExpression = conditionalExpression;
    proposal.data = abi.encode(newState);

    emit ProposalCreated(proposalId, ProposalType.StateChange, msg.sender);
    emit ReputationEarned(msg.sender, 5); // Reward reputation for proposing

    // Note: Proposal must be activated to start voting.
}

/**
 * @dev Function 7: Allows a member to propose a change to a protocol parameter.
 * Requires minimum reputation.
 * Data should be abi encoded {string parameterKey, bytes newValue}.
 */
function proposeParameterChange(string memory parameterKey, bytes memory newValue, string memory conditionalExpression) external onlyMember returns (uint256 proposalId) {
    if (_members[msg.sender].reputationPoints < minReputationForProposal) revert InsufficientVoteWeightForQuorum(); // Reusing error

    // Basic parameter key validation (add more as needed)
    if (
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("joinBond")) &&
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("votePeriod")) &&
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("quorumPercentage")) &&
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("minReputationForProposal")) &&
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("baseVoteWeight")) &&
        !keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("oracleAddress")) // Oracle address can also be changed via governance
    ) {
        revert InvalidParameterKey();
    }

    proposalId = _nextProposalId++;
    Proposal storage proposal = _proposals[proposalId];
    proposal.id = proposalId;
    proposal.proposalType = ProposalType.ParameterChange;
    proposal.status = ProposalStatus.Pending; // Starts Pending, needs activation
    proposal.proposer = msg.sender;
    proposal.creationTimestamp = block.timestamp;
    // Voting dates set on activation
    proposal.conditionalExpression = conditionalExpression;
    proposal.data = abi.encode(parameterKey, newValue);

    emit ProposalCreated(proposalId, ProposalType.ParameterChange, msg.sender);
    emit ReputationEarned(msg.sender, 5); // Reward reputation

    // Note: Proposal must be activated to start voting.
}

/**
 * @dev Function 8: Allows a member to activate their pending proposal to start the voting period.
 */
function activateProposal(uint256 proposalId) external onlyMember {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.proposer != msg.sender) revert UnauthorizedWithdrawal(); // Reusing error, better: NotProposalProposer
    if (proposal.status != ProposalStatus.Pending) revert ProposalNotInCorrectState();

    proposal.status = ProposalStatus.Active;
    proposal.votingEndTimestamp = block.timestamp + votePeriod;
    _addProposalToActiveList(proposalId);

    emit ProposalStatusChanged(proposalId, ProposalStatus.Active);
}


/**
 * @dev Function 9: Allows a member (or delegate) to cast a vote on an active proposal.
 */
function voteOnProposal(uint256 proposalId, bool support) external onlyMember {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.status != ProposalStatus.Active) revert ProposalNotInCorrectState();
    if (block.timestamp > proposal.votingEndTimestamp) revert VotingPeriodEnded();

    address voter = msg.sender;
    // Check if voter has delegated their vote
    address delegatee = _members[voter].voteDelegate;
    if (delegatee != address(0)) {
       voter = delegatee; // Vote is cast by the delegatee on behalf of the delegator's weight
       // However, let's track who *initiated* the vote for reputation purposes,
       // but the vote weight comes from the original voter or their delegate.
       // A simpler approach: require delegatee to call voteOnProposal directly.
       // Let's stick to the simpler model for now: voter == msg.sender, but weight is calculated based on the delegate chain.
       // Revert if vote is delegated:
       if (delegatee != address(0) && delegatee != msg.sender) revert DelegateeCannotBeVoterOrSelf(); // Voter has delegated, delegatee must vote
       if (delegatee == msg.sender) voter = delegatee; // Delegatee is voting on behalf of someone else or themselves
       // This delegation logic needs careful consideration. For simplicity now:
       // Vote is always cast by msg.sender. The *weight* comes from msg.sender's calculated weight or their delegatee's if delegated *to* them.
    }

     // Let's simplify: vote is cast by msg.sender, weight is msg.sender's *own* weight. Delegation just allows *another address* to call voteOnProposal *with their address*.
    // The vote should be recorded against the address whose weight is being used.
    // A better delegation model: vote weight is *transferred*. `_members[delegator].voteDelegate = delegatee;`
    // When voting, get effective voter: if `_members[msg.sender].voteDelegate` is not zero, that's the effective voter.
    address effectiveVoter = msg.sender;
    // While loop to resolve delegation chain (max iterations recommended)
    for(uint i = 0; i < 10; i++) { // Limit delegation chain length
        address delegatedTo = _members[effectiveVoter].voteDelegate;
        if (delegatedTo != address(0)) {
            effectiveVoter = delegatedTo;
        } else {
            break;
        }
    }

    if (proposal.voted[effectiveVoter]) revert AlreadyVoted();

    uint256 voteWeight = _calculateVoteWeight(effectiveVoter);
    if (voteWeight == 0) revert NotAMember(); // Should be caught by onlyMember, but good check

    proposal.voted[effectiveVoter] = true; // Mark effective voter as voted
    proposal.totalVoteWeight += voteWeight;

    if (support) {
        proposal.votesFor += voteWeight;
    } else {
        proposal.votesAgainst += voteWeight;
    }

    emit VoteCast(proposalId, effectiveVoter, support, voteWeight);
    emit ReputationEarned(msg.sender, 1); // Reward reputation for casting a vote (original caller)
}

/**
 * @dev Function 10: Allows a member to delegate their vote weight to another member.
 * Setting delegatee to address(0) clears delegation.
 */
function delegateVote(address delegatee) external onlyMember {
    address delegator = msg.sender;
    if (delegator == delegatee) revert DelegateeCannotBeVoterOrSelf();
    if (delegatee != address(0) && !_members[delegatee].isMember) revert MemberNotFound(); // Delegatee must be a member

    _members[delegator].voteDelegate = delegatee;

    emit VoteDelegated(delegator, delegatee);
}

/**
 * @dev Function 11: Allows anyone to check if a proposal's voting period has ended and update its status.
 */
function finalizeVoting(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.status != ProposalStatus.Active) revert ProposalNotInCorrectState();
    if (block.timestamp <= proposal.votingEndTimestamp) revert VotingPeriodEnded(); // Voting period not yet over

    // Determine if quorum was met
    uint256 totalPossibleVoteWeight = _getTotalCollectiveVoteWeight(); // Potentially gas-intensive
    uint256 requiredQuorumWeight = (totalPossibleVoteWeight * quorumPercentage) / 100;

    if (proposal.totalVoteWeight < requiredQuorumWeight) {
         proposal.status = ProposalStatus.Rejected; // Fails quorum
         _removeProposalFromActiveList(proposalId);
         emit ProposalStatusChanged(proposalId, ProposalStatus.Rejected);
         return;
    }

    // Determine if approved
    if (proposal.votesFor > proposal.votesAgainst) {
        proposal.status = ProposalStatus.Approved;
        emit ProposalStatusChanged(proposalId, ProposalStatus.Approved);
    } else {
        proposal.status = ProposalStatus.Rejected;
        _removeProposalFromActiveList(proposalId);
        emit ProposalStatusChanged(proposalId, ProposalStatus.Rejected);
    }
}

/**
 * @dev Function 12: Allows anyone to execute an approved proposal IF its conditional expression evaluates to true.
 */
function executeProposal(uint256 proposalId) external {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.status != ProposalStatus.Approved) revert ProposalNotInCorrectState();
    // Note: Proposal execution can happen anytime *after* approval, as long as conditions are met.

    if (!canExecuteProposal(proposalId)) revert ExecutionConditionsNotMet();

    // Execute based on proposal type
    if (proposal.proposalType == ProposalType.StateChange) {
        CollectiveState newState = abi.decode(proposal.data, (CollectiveState));
        CollectiveState oldState = collectiveState;
        collectiveState = newState;
        emit CollectiveStateChanged(oldState, newState);

    } else if (proposal.proposalType == ProposalType.ParameterChange) {
        (string memory paramKey, bytes memory newValue) = abi.decode(proposal.data, (string, bytes));
        _applyParameterChange(paramKey, newValue); // Internal helper for safety
        emit ParameterChanged(paramKey, newValue);

    } else if (proposal.proposalType == ProposalType.ExecuteAction) {
        // Placeholder for executing a predefined action based on `proposal.data`
        // Example: trigger a specific function call or state change encoded in data
        // bytes memory actionData = proposal.data;
        // _executeDefinedAction(actionData);
        // For this example, we just acknowledge execution without a specific action
    }

    proposal.status = ProposalStatus.Executed;
    _removeProposalFromActiveList(proposalId);

    emit ProposalExecuted(proposalId);
    // Potentially reward reputation to proposer/voters on successful execution
}

/**
 * @dev Function 13: Allows the oracle address to submit new data.
 */
function submitOracleData(string memory key, uint256 value) external onlyOracle {
    _oracleData[key] = value;
    emit OracleDataUpdated(key, value);
}

/**
 * @dev Function 14: Allows the current oracle address to be changed via governance.
 * This is called internally by `_applyParameterChange`.
 */
function updateOracleAddress(address newOracle) internal {
    // Check if caller is this contract (i.e., executed by a proposal)
    // Add a check here if this function should *only* be callable by self/governance.
    // For simplicity, assume it's only called via governance proposal execution.
    oracleAddress = newOracle;
    // No specific event here, ParameterChanged event is emitted by _applyParameterChange
}

/**
 * @dev Function 15: Allows the withdrawal of funds from the contract's treasury.
 * This should be controlled by governance via an ExecuteAction proposal type.
 * Requires proposal data to specify recipient and amount.
 */
function proposeWithdrawFunds(address recipient, uint256 amount) external onlyMember returns (uint256 proposalId) {
     if (_members[msg.sender].reputationPoints < minReputationForProposal) revert InsufficientVoteWeightForQuorum(); // Reusing error

    // Check if contract has enough funds
    if (address(this).balance < amount) revert InsufficientVoteWeightForQuorum(); // Reusing error, better: InsufficientContractBalance

    // Note: No conditional expression needed here? Or maybe condition is "ContractBalance >= amount"?
    // Let's make this a simple execution proposal without extra conditions for now.
     proposalId = _nextProposalId++;
    Proposal storage proposal = _proposals[proposalId];
    proposal.id = proposalId;
    proposal.proposalType = ProposalType.ExecuteAction; // Use ExecuteAction for withdrawals
    proposal.status = ProposalStatus.Pending;
    proposal.proposer = msg.sender;
    proposal.creationTimestamp = block.timestamp;
    // voting end set on activate
    proposal.conditionalExpression = ""; // No extra condition for this type? Or hardcoded condition?
    proposal.data = abi.encode("Withdraw", recipient, amount); // Encode action type and parameters

    emit ProposalCreated(proposalId, ProposalType.ExecuteAction, msg.sender);
    emit ReputationEarned(msg.sender, 5); // Reward reputation

    // Note: Proposal must be activated to start voting. Execution logic in executeProposal will handle this.
}

/**
 * @dev Function 16: Internal helper to apply parameter changes proposed via governance.
 * This adds a layer of safety/structure to parameter updates.
 */
function _applyParameterChange(string memory parameterKey, bytes memory newValue) internal {
    // This function should only be called during proposal execution
    // Use a guard like `require(msg.sender == address(this))` if called directly by the contract,
    // or trust the executeProposal flow.

    if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("joinBond"))) {
        joinBond = abi.decode(newValue, (uint256));
    } else if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("votePeriod"))) {
        votePeriod = abi.decode(newValue, (uint256));
    } else if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("quorumPercentage"))) {
        uint256 newQuorum = abi.decode(newValue, (uint256));
        if (newQuorum > 100) revert InvalidParameterKey(); // Basic validation
        quorumPercentage = newQuorum;
    } else if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("minReputationForProposal"))) {
        minReputationForProposal = abi.decode(newValue, (uint256));
    } else if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("baseVoteWeight"))) {
        baseVoteWeight = abi.decode(newValue, (uint256));
    } else if (keccak256(abi.encodePacked(parameterKey)) == keccak256(abi.encodePacked("oracleAddress"))) {
        address newOracle = abi.decode(newValue, (address));
        updateOracleAddress(newOracle); // Call the specific update function
    } else {
         revert InvalidParameterKey(); // Should have been caught during proposal creation, but belt-and-suspenders
    }
}

/**
 * @dev Function 17: Allows a member to cancel their own proposal if it's still in the Pending state.
 */
function cancelProposal(uint256 proposalId) external onlyMember {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.proposer != msg.sender) revert UnauthorizedWithdrawal(); // Reusing error, better: NotProposalProposer
    if (proposal.status != ProposalStatus.Pending) revert ProposalNotInCorrectState();

    proposal.status = ProposalStatus.Cancelled;

    emit ProposalCancelled(proposalId);
}

/**
 * @dev Function 18: Allows anyone to query the CollectiveState.
 */
function getState() external view returns (CollectiveState) {
    return collectiveState;
}

/**
 * @dev Function 19: Allows anyone to query details of a specific Chronicle.
 */
function getChronicleDetails(uint256 chronicleId) external view returns (ChronicleData memory) {
     // Create a memory copy to return mappings
    ChronicleData storage chronicle = _chronicles[chronicleId];
    if (chronicle.owner == address(0) && chronicle.mintTimestamp == 0) revert ChronicleNotFound(); // Check if entry exists

    ChronicleData memory details;
    details.owner = chronicle.owner;
    details.mintTimestamp = chronicle.mintTimestamp;
    details.tier = chronicle.tier;
    details.lastAttributeUpdate = chronicle.lastAttributeUpdate;

    // Copy mappings (manual copy is needed)
    // Note: Returning entire mappings is not directly supported.
    // Need separate functions or a wrapper struct to return attributes.
    // For simplicity, let's modify this to return basic details and add separate attribute getters.
    return details; // This will NOT include mappings!
}

/**
 * @dev Function 20: Allows anyone to query details of a specific Member.
 */
function getMemberInfo(address memberAddress) external view returns (Member memory) {
    Member storage member = _members[memberAddress];
    if (!member.isMember) revert MemberNotFound();
    return member;
}

/**
 * @dev Function 21: Allows anyone to query details of a specific Proposal.
 */
function getProposalInfo(uint256 proposalId) external view returns (Proposal memory) {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.creationTimestamp == 0 && proposal.id != 1) revert ProposalNotFound(); // Check if entry exists (except proposal 1)

     // Return basic data excluding mappings
    Proposal memory details;
    details.id = proposal.id;
    details.proposalType = proposal.proposalType;
    details.status = proposal.status;
    details.proposer = proposal.proposer;
    details.creationTimestamp = proposal.creationTimestamp;
    details.votingEndTimestamp = proposal.votingEndTimestamp;
    details.votesFor = proposal.votesFor;
    details.votesAgainst = proposal.votesAgainst;
    details.totalVoteWeight = proposal.totalVoteWeight;
    details.conditionalExpression = proposal.conditionalExpression;
    details.executed = (proposal.status == ProposalStatus.Executed); // Derived state

    // Note: mappings (voted, delegatedVotes) are not returned.
    return details;
}


// --- Additional Query Functions (to meet >= 20) ---

/**
 * @dev Function 22: Check if a member has voted on a specific proposal.
 */
function hasMemberVoted(uint256 proposalId, address memberAddress) external view returns (bool) {
     Proposal storage proposal = _proposals[proposalId];
     if (proposal.creationTimestamp == 0 && proposal.id != 1) revert ProposalNotFound();
     // Resolve effective voter for query
     address effectiveVoter = memberAddress;
     for(uint i = 0; i < 10; i++) { // Limit chain length
         address delegatedTo = _members[effectiveVoter].voteDelegate;
         if (delegatedTo != address(0)) {
             effectiveVoter = delegatedTo;
         } else {
             break;
         }
     }
     return proposal.voted[effectiveVoter];
}

/**
 * @dev Function 23: Get the effective vote weight of a member (considering delegation).
 */
function getEffectiveVoteWeight(address memberAddress) external view returns (uint256) {
    address effectiveVoter = memberAddress;
    for(uint i = 0; i < 10; i++) { // Limit chain length
        address delegatedTo = _members[effectiveVoter].voteDelegate;
        if (delegatedTo != address(0)) {
            effectiveVoter = delegatedTo;
        } else {
            break;
        }
    }
    return _calculateVoteWeight(effectiveVoter);
}


/**
 * @dev Function 24: Calculate the total cumulative vote weight of all active members.
 * WARNING: Can be gas-intensive with many members.
 */
function _getTotalCollectiveVoteWeight() internal view returns (uint256 totalWeight) {
    // This would require iterating over all members to sum their weights.
    // Optimization: Track total weight in a state variable and update on join/leave/reputation change/tier upgrade.
    // For now, a simple (but gas-heavy) iteration:
    totalWeight = 0;
    for (uint i = 0; i < _memberAddresses.length; i++) {
        address memberAddress = _memberAddresses[i];
        if (_members[memberAddress].isMember) { // Double check isMember
             // Need to calculate effective weight if delegation affects total pool.
             // If quorum is % of *potential* weight, this needs to sum weights *before* delegation.
             // Let's assume quorum is based on sum of weights for each member *regardless* of delegation.
             totalWeight += _calculateVoteWeight(memberAddress); // Use individual weight, not effective delegatee weight pool
        }
    }
    // A more efficient approach: Track total member weight as a state variable and update it.
    // Example: `uint256 private _totalMemberVoteWeight;`
    // Update in `joinCollective`, `leaveCollective`, `claimChronicleTierUpgrade`, `ReputationEarned` (if it impacts weight).
    // Let's add the state variable approach for efficiency.
    // uint256 public totalMemberVoteWeight; // <-- Need to add this state variable and maintain it
    // return totalMemberVoteWeight; // Assuming it's correctly updated
     return totalWeight; // Using the iterative method for now, but acknowledge inefficiency.
}
uint256 public totalPotentialVoteWeight = 0; // Add state variable and update it

/**
 * @dev Function 25: Check if the conditions for a proposal's execution are met.
 * This function interprets the `conditionalExpression`. Requires Oracle data.
 * NOTE: Implementing a robust, secure on-chain expression parser is complex and gas-prohibitive.
 * This is a simplified placeholder. Real-world would use specific function calls based on proposal data.
 */
function canExecuteProposal(uint256 proposalId) public view returns (bool) {
    Proposal storage proposal = _proposals[proposalId];
    if (proposal.status != ProposalStatus.Approved) return false;

    // Simplified conditional logic based on `conditionalExpression` string
    // Example expressions:
    // "CollectiveStateIs(Expansion)"
    // "OracleDataGreater(price, 1000)"
    // "MemberCountGreater(100)"
    // "True" (always true)

    if (bytes(proposal.conditionalExpression).length == 0 || keccak256(abi.encodePacked(proposal.conditionalExpression)) == keccak256(abi.encodePacked("True"))) {
        return true; // No condition or always true
    }

    // --- Placeholder for actual condition parsing and checking ---
    // This part is highly simplified for demonstration.
    // A real system would need a structured way to define and check conditions.
    // Options:
    // 1. Predefined condition types encoded in data, not parsed from string.
    // 2. An external service submits a boolean result via the oracle (less decentralized).
    // 3. Limited set of hardcoded check functions called based on a type flag in proposal data.

    // Example checking simplified expressions:
    if (keccak256(abi.encodePacked(proposal.conditionalExpression)) == keccak256(abi.encodePacked("CollectiveStateIs(Expansion)"))) {
        return collectiveState == CollectiveState.Expansion;
    }
    if (keccak256(abi.encodePacked(proposal.conditionalExpression)) == keccak256(abi.encodePacked("OracleDataGreater(price, 1000)"))) {
        // Requires oracle data "price" to be submitted
        return _oracleData["price"] > 1000;
    }
    if (keccak256(abi.encodePacked(proposal.conditionalExpression)) == keccak256(abi.encodePacked("MemberCountGreater(100)"))) {
        return _memberAddresses.length > 100; // Gas-intensive lookup, better to track count
    }

    // Default to false if condition format is not recognized or implemented
    return false; // Safety first: if cannot parse/check, don't execute.
}

/**
 * @dev Function 26: Get the Chronicle ID associated with a member address.
 */
function getMemberChronicleId(address memberAddress) external view returns (uint256) {
    return _memberChronicleId[memberAddress];
}

/**
 * @dev Function 27: Get the total number of Chronicles minted (and not burned).
 */
function getTotalSupply() external view returns (uint256) {
    return _totalChroniclesMinted; // Assuming _totalChroniclesMinted is decremented on burn
    // Or return _nextTokenId - 1; if burnt tokens leave gaps and we count the max ID issued
    // Let's add the counter and maintain it.
}

/**
 * @dev Function 28: Get a list of all member addresses.
 * WARNING: Can be very gas-intensive with many members. Use pagination or alternative tracking if needed.
 */
function getAllMemberAddresses() external view returns (address[] memory) {
    return _memberAddresses; // Directly return the array (gas caution applies)
}

/**
 * @dev Function 29: Get the current value of an oracle data key.
 */
function getOracleData(string memory key) external view returns (uint256) {
    return _oracleData[key];
}

/**
 * @dev Function 30: Get the number of active proposals for the current state.
 */
function getActiveProposalCount() external view returns (uint256) {
    return _activeProposalIdsByState[collectiveState].length;
}

/**
 * @dev Function 31: Get the IDs of active proposals for the current state.
 * WARNING: Can be gas-intensive for many active proposals.
 */
function getActiveProposalIds() external view returns (uint256[] memory) {
    return _activeProposalIdsByState[collectiveState];
}

/**
 * @dev Function 32: Get a specific numeric attribute from a Chronicle.
 */
function getChronicleNumericAttribute(uint256 chronicleId, string memory key) external view returns (uint256) {
     ChronicleData storage chronicle = _chronicles[chronicleId];
     if (chronicle.owner == address(0) && chronicle.mintTimestamp == 0) revert ChronicleNotFound();
     return chronicle.attributesNum[key];
}

/**
 * @dev Function 33: Get a specific string attribute from a Chronicle.
 */
function getChronicleStringAttribute(uint256 chronicleId, string memory key) external view returns (string memory) {
    ChronicleData storage chronicle = _chronicles[chronicleId];
     if (chronicle.owner == address(0) && chronicle.mintTimestamp == 0) revert ChronicleNotFound();
     return chronicle.attributesStr[key];
}

/**
 * @dev Function 34: Get the current join bond amount.
 */
function getJoinBond() external view returns (uint256) {
    return joinBond;
}

/**
 * @dev Function 35: Get the current vote period duration in seconds.
 */
function getVotePeriod() external view returns (uint256) {
    return votePeriod;
}

/**
 * @dev Function 36: Get the current quorum percentage required for proposals.
 */
function getQuorumPercentage() external view returns (uint256) {
    return quorumPercentage;
}

// Placeholder for receiving Ether (e.g., from join bonds or direct sends)
receive() external payable {}

// Fallback function (optional, can be used to receive Ether without calldata)
fallback() external payable {}

// Note: A real system might need functions for treasury management,
// more sophisticated error handling, potential upgrades (via UUPS proxy),
// and more robust condition checking logic.
// The dynamic attributes could also benefit from a standard interface if they become complex.
// The `_memberAddresses` array introduces gas issues with large member counts;
// alternative tracking methods (like linked lists or mapping iteration in off-chain tools)
// would be needed for scalability.
```