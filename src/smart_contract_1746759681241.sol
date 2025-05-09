Okay, let's create a smart contract with an interesting, complex, and somewhat abstract concept that isn't a direct copy of standard token, NFT, or DeFi protocols.

We'll design a contract around "Quantum Flow Shards" - non-fungible assets that have a dynamic `quantumState` influenced by time, bonded resources, and user interaction. Users accumulate a "Flow Rate" based on their Shards and activities, which unlocks certain conditional functions.

**Concept Name:** QuantumFlow

**Core Ideas:**

1.  **Flow Shards:** Unique NFTs (represented as structs here, though could be full ERC721) with a mutable `quantumState`.
2.  **Dynamic State:** `quantumState` decays over time but can be increased by "infusion" via bonding a specific ERC20 token (`BToken`).
3.  **Bonding:** Users lock `BToken` to their Shards to prevent decay and enable infusion.
4.  **User Flow Rate:** A reputation or capability score derived from the user's owned Shards' states and bonded tokens.
5.  **Conditional Functions:** Some actions require a minimum User Flow Rate or a Shard's `quantumState` to be within a specific range.
6.  **Time-Based Mechanics:** Decay is time-sensitive. Temporal locking prevents actions for a duration.
7.  **State Manipulation:** Functions to fuse/split Shards, attempt state transitions.
8.  **Delegation:** Users can delegate their Flow Rate calculation rights.

---

**Outline and Function Summary**

**Contract Name:** `QuantumFlow`

**Core Asset:** `FlowShard` (struct representing a unique, dynamic asset)
**Resource Token:** `BToken` (external ERC20 used for bonding and infusion)
**User Metric:** `FlowRate` (calculated based on Shards and bonding)

**State Variables:**
*   `owner`: Contract deployer.
*   `shardCounter`: Counter for unique Shard IDs.
*   `shards`: Mapping of Shard ID to `FlowShard` struct.
*   `shardOwner`: Mapping of Shard ID to owner address.
*   `ownerShardCount`: Mapping of owner address to number of Shards owned.
*   `bTokenAddress`: Address of the required bonding token.
*   `userDelegates`: Mapping for Flow Rate delegation.
*   Parameters: Factors for decay, infusion, costs, etc.
*   Pause state.

**Structs:**
*   `FlowShard`: Represents a single Shard with ID, owner, state, time tracking, bonding info, etc.

**Events:**
*   `ShardMinted`: When a new Shard is created.
*   `ShardTransferred`: When Shard ownership changes.
*   `Bonded`: When BToken is bonded to a Shard.
*   `Unbonded`: When BToken is unbonded from a Shard.
*   `ShardStateUpdated`: When a Shard's quantumState changes.
*   `FlowRateDelegated`: When Flow Rate delegation is set.
*   Other events for fusion, split, lock, etc.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when paused.
*   `whenPaused`: Allows execution only when paused.
*   `requireShardOwner(uint256 _shardId)`: Ensures msg.sender owns the Shard.
*   `requireMinFlowRate(address _user, uint256 _minRate)`: Ensures a user's calculated Flow Rate meets a minimum.
*   `requireShardStateRange(uint256 _shardId, uint256 _min, uint256 _max)`: Ensures a Shard's state is in a range.

**Functions (29 total):**

1.  `constructor(address _bToken)`: Initializes the contract, sets owner and BToken address.
2.  `mintShard(uint256 _initialBondAmount)`: Mints a new Flow Shard for the caller. Requires bonding an initial amount of `BToken`. (Uses `transferFrom` of BToken).
3.  `getShard(uint256 _shardId)`: View function to get details of a specific Shard (state, owner, bonding, etc.).
4.  `ownerOf(uint256 _shardId)`: Gets the owner of a Shard (ERC721-like).
5.  `balanceOf(address _owner)`: Gets the number of Shards owned by an address (ERC721-like).
6.  `transferShard(address _to, uint256 _shardId)`: Transfers ownership of a Shard.
7.  `bondToShard(uint256 _shardId, uint256 _amount)`: Bonds `_amount` of `BToken` to `_shardId`. Requires `requireShardOwner` and `whenNotPaused`. (Uses `transferFrom` of BToken).
8.  `unbondFromShard(uint256 _shardId, uint256 _amount)`: Unbonds `_amount` of `BToken` from `_shardId`. Requires `requireShardOwner` and `whenNotPaused`. (Uses `transfer` of BToken).
9.  `updateShardState(uint256 _shardId)`: Public function to trigger the state calculation for a Shard based on time and bonded amount. This is a manual trigger, users benefit by calling it for their shards (or others can call it).
10. `getShardQuantumState(uint256 _shardId)`: View function to get the current calculated `quantumState` of a Shard (applies decay calculation without modifying state).
11. `calculateUserFlowRate(address _user)`: View function to calculate the Flow Rate for a user based on their owned Shards and bonded amounts. This calculation applies current shard states.
12. `getUserFlowRate(address _user)`: View function that returns the Flow Rate for a user, respecting delegation if set. Calls `calculateUserFlowRate` internally.
13. `fuseShards(uint256 _shardId1, uint256 _shardId2, uint256 _shardToKeep, uint256 _fuseFeeAmount)`: Fuses two shards (`_shardId1`, `_shardId2`). The one to keep (`_shardToKeep`) gets a state boost, the other is burned. Requires shard ownership, a fee (in BToken), and potentially minimum states. Uses `requireShardOwner` and `whenNotPaused`.
14. `splitShard(uint256 _shardId, uint256 _splitFeeAmount)`: Splits a high-state shard into two. Original state is reduced, a new shard is minted with a base state. Requires shard ownership, a fee (in BToken), and potentially a minimum state. Uses `requireShardOwner` and `whenNotPaused`.
15. `temporalLockShard(uint256 _shardId, uint256 _duration)`: Locks a shard for a specified duration. Prevents transfer, fuse, split during lock. Uses `requireShardOwner` and `whenNotPaused`.
16. `releaseTemporalLock(uint256 _shardId)`: Releases the lock on a shard if the duration has passed. Uses `requireShardOwner`.
17. `challengeStateTransition(uint256 _shardId, uint256 _targetState, uint256 _challengeFeeAmount)`: A conditional function to attempt to nudge a Shard's state towards a target. Requires a fee (BToken) and might depend on the current state and target difficulty (simulated). Uses `requireShardOwner` and `whenNotPaused`.
18. `delegateFlowRate(address _delegate)`: Delegates the calculation and use of the caller's Flow Rate to another address. Uses `whenNotPaused`.
19. `undelegateFlowRate()`: Removes Flow Rate delegation. Uses `whenNotPaused`.
20. `checkFlowRateDelegate(address _user)`: View function to see who a user has delegated their Flow Rate to.
21. `accessConditionalFunction(uint256 _minRateRequired)`: Example function that requires a minimum User Flow Rate (using `requireMinFlowRate`). This function itself doesn't do much but demonstrates the concept. Uses `whenNotPaused`.
22. `accessStateGatedFunction(uint256 _shardId, uint256 _minStateRequired, uint256 _maxStateRequired)`: Example function requiring a Shard's state to be in a specific range (using `requireShardStateRange`). Uses `requireShardOwner` and `whenNotPaused`.
23. `burnShard(uint256 _shardId)`: Allows the owner of a shard to burn it. Uses `requireShardOwner` and `whenNotPaused`.
24. `getTotalSupply()`: View function returning the total number of Shards minted.
25. `setParameters(uint256 _decayFactor, uint256 _infusionFactor, uint256 _fusionBoost, uint256 _splitPenalty)`: Owner-only function to adjust core state calculation parameters.
26. `setFees(uint256 _fuseFee, uint256 _splitFee, uint256 _challengeFee, uint256 _mintFee)`: Owner-only function to adjust various operation fees (in BToken).
27. `pause()`: Owner-only function to pause contract operations.
28. `unpause()`: Owner-only function to unpause contract operations.
29. `withdrawERC20(address _token, uint256 _amount)`: Owner-only function to withdraw any ERC20 (including BToken fees/mint costs) accidentally sent or collected by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Simple ERC20 Interface for interaction
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title QuantumFlow
 * @dev A creative smart contract managing dynamic 'Flow Shards' and user 'Flow Rate'.
 * Shards have a quantum state affected by time decay and bonded tokens.
 * User Flow Rate unlocks conditional functions.
 * Features: Dynamic state, bonding, time mechanics, conditional access, delegation, fusion/splitting.
 */

// --- Outline and Function Summary (Repeated from above for completeness within the source) ---

// **Outline**
// Contract Name: QuantumFlow
// Core Asset: FlowShard (struct representing a unique, dynamic asset)
// Resource Token: BToken (external ERC20 used for bonding and infusion)
// User Metric: FlowRate (calculated based on Shards and bonding)

// State Variables:
// - owner: Contract deployer.
// - shardCounter: Counter for unique Shard IDs.
// - shards: Mapping of Shard ID to FlowShard struct.
// - shardOwner: Mapping of Shard ID to owner address.
// - ownerShardCount: Mapping of owner address to number of Shards owned.
// - bTokenAddress: Address of the required bonding token.
// - userDelegates: Mapping for Flow Rate delegation.
// - Parameters: Factors for decay, infusion, costs, etc.
// - Pause state.

// Structs:
// - FlowShard: Represents a single Shard with ID, owner, state, time tracking, bonding info, etc.

// Events:
// - ShardMinted: When a new Shard is created.
// - ShardTransferred: When Shard ownership changes.
// - Bonded: When BToken is bonded to a Shard.
// - Unbonded: When BToken is unbonded from a Shard.
// - ShardStateUpdated: When a Shard's quantumState changes.
// - FlowRateDelegated: When Flow Rate delegation is set.
// - Other events for fusion, split, lock, etc.

// Modifiers:
// - onlyOwner: Restricts access to the contract owner.
// - whenNotPaused: Prevents execution when paused.
// - whenPaused: Allows execution only when paused.
// - requireShardOwner(uint256 _shardId): Ensures msg.sender owns the Shard.
// - requireMinFlowRate(address _user, uint256 _minRate): Ensures a user's calculated Flow Rate meets a minimum.
// - requireShardStateRange(uint256 _shardId, uint256 _min, uint256 _max): Ensures a Shard's state is in a range.

// Functions (29 total):
// 1. constructor(address _bToken)
// 2. mintShard(uint256 _initialBondAmount)
// 3. getShard(uint256 _shardId)
// 4. ownerOf(uint256 _shardId)
// 5. balanceOf(address _owner)
// 6. transferShard(address _to, uint256 _shardId)
// 7. bondToShard(uint256 _shardId, uint256 _amount)
// 8. unbondFromShard(uint256 _shardId, uint256 _amount)
// 9. updateShardState(uint256 _shardId)
// 10. getShardQuantumState(uint256 _shardId)
// 11. calculateUserFlowRate(address _user)
// 12. getUserFlowRate(address _user)
// 13. fuseShards(uint256 _shardId1, uint256 _shardId2, uint256 _shardToKeep, uint256 _fuseFeeAmount)
// 14. splitShard(uint256 _shardId, uint256 _splitFeeAmount)
// 15. temporalLockShard(uint256 _shardId, uint256 _duration)
// 16. releaseTemporalLock(uint256 _shardId)
// 17. challengeStateTransition(uint256 _shardId, uint256 _targetState, uint256 _challengeFeeAmount)
// 18. delegateFlowRate(address _delegate)
// 19. undelegateFlowRate()
// 20. checkFlowRateDelegate(address _user)
// 21. accessConditionalFunction(uint256 _minRateRequired)
// 22. accessStateGatedFunction(uint256 _shardId, uint256 _minStateRequired, uint256 _maxStateRequired)
// 23. burnShard(uint256 _shardId)
// 24. getTotalSupply()
// 25. setParameters(uint256 _decayFactor, uint256 _infusionFactor, uint256 _fusionBoost, uint256 _splitPenalty)
// 26. setFees(uint256 _fuseFee, uint256 _splitFee, uint256 _challengeFee, uint256 _mintFee)
// 27. pause()
// 28. unpause()
// 29. withdrawERC20(address _token, uint256 _amount)

// --- End of Outline and Function Summary ---


contract QuantumFlow {

    address public owner;
    uint256 private shardCounter;

    struct FlowShard {
        uint256 id;
        // uint256 ownerId; // Owner tracked separately for ERC721-like compatibility
        uint256 quantumState; // Dynamic state, 0 is lowest
        uint256 creationTime; // Timestamp of creation
        uint256 lastStateUpdateTime; // Timestamp when state was last calculated/updated
        uint256 bondedAmount; // Amount of BToken bonded
        uint256 lastBondUpdateTime; // Timestamp of last bond/unbond
        uint256 temporalLockEnd; // Timestamp when temporal lock ends (0 if not locked)
    }

    // Mappings for Shards and Ownership (ERC721-like structure)
    mapping(uint256 => FlowShard) private shards;
    mapping(uint256 => address) private shardOwner;
    mapping(address => uint256) private ownerShardCount;

    address public immutable bTokenAddress;

    // Delegation mapping: user => delegate
    mapping(address => address) private userDelegates;

    // Parameters influencing state changes
    uint256 public decayFactor;       // State lost per second per unit of state
    uint256 public infusionFactor;    // State gained per unit of bonded BToken per second
    uint256 public fusionBoostFactor; // State multiplier when fusing shards
    uint256 public splitPenaltyFactor; // State reduction factor when splitting

    // Fees (in BToken) for certain operations
    uint256 public fuseFee;
    uint256 public splitFee;
    uint256 public challengeFee;
    uint256 public mintFee;

    bool public paused;

    // Errors
    error NotOwner();
    error Paused();
    error NotPaused();
    error ShardNotFound(uint256 shardId);
    error NotShardOwner(uint256 shardId);
    error InsufficientFunds(uint256 requested, uint256 available);
    error TemporalLockActive(uint256 shardId);
    error TemporalLockNotActive(uint256 shardId);
    error TemporalLockNotExpired(uint256 shardId);
    error InvalidAmount();
    error InvalidShardId();
    error FusionError();
    error SplitError();
    error SelfDelegationForbidden();
    error DelegationAlreadySet();
    error DelegationNotSet();
    error InsufficientFlowRate(uint256 required, uint256 available);
    error ShardStateOutOfRange(uint256 shardId, uint256 min, uint256 max, uint256 currentState);


    // Events
    event ShardMinted(uint256 indexed shardId, address indexed owner, uint256 initialBond);
    event ShardTransferred(uint256 indexed shardId, address indexed from, address indexed to);
    event Bonded(uint256 indexed shardId, address indexed user, uint256 amount);
    event Unbonded(uint256 indexed shardId, address indexed user, uint256 amount);
    event ShardStateUpdated(uint256 indexed shardId, uint256 oldState, uint256 newState);
    event ShardFused(uint256 indexed shardToKeep, uint256 indexed shardBurned1, uint256 indexed shardBurned2);
    event ShardSplit(uint256 indexed originalShardId, uint256 indexed newShardId);
    event ShardTemporalLocked(uint256 indexed shardId, uint256 duration, uint256 unlockTime);
    event ShardTemporalLockReleased(uint256 indexed shardId);
    event StateTransitionChallenged(uint256 indexed shardId, uint256 targetState, uint256 feeAmount);
    event FlowRateDelegated(address indexed delegator, address indexed delegate);
    event FlowRateUndelegated(address indexed delegator);
    event ShardBurned(uint256 indexed shardId, address indexed owner);
    event ParametersSet(uint256 decay, uint256 infusion, uint256 fusionBoost, uint256 splitPenalty);
    event FeesSet(uint256 fuse, uint256 split, uint256 challenge, uint256 mint);
    event Paused(address account);
    event Unpaused(address account);
    event ERC20Withdrawn(address indexed token, address indexed to, uint256 amount);


    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier requireShardExists(uint256 _shardId) {
        if (shardOwner[_shardId] == address(0)) revert ShardNotFound(_shardId);
        _;
    }

    modifier requireShardOwner(uint256 _shardId) {
        if (shardOwner[_shardId] == address(0)) revert ShardNotFound(_shardId);
        if (shardOwner[_shardId] != msg.sender) revert NotShardOwner(_shardId);
        _;
    }

    modifier requireMinFlowRate(uint256 _minRate) {
        if (getUserFlowRate(msg.sender) < _minRate) revert InsufficientFlowRate(_minRate, getUserFlowRate(msg.sender));
        _;
    }

    modifier requireShardStateRange(uint256 _shardId, uint256 _min, uint256 _max) {
        uint256 currentState = getShardQuantumState(_shardId);
        if (currentState < _min || currentState > _max) revert ShardStateOutOfRange(_shardId, _min, _max, currentState);
        _;
    }

    // --- Core Logic ---

    /**
     * @dev Calculates the potential state change (decay or infusion) for a shard based on time elapsed and bonded amount.
     * @param _shard The shard struct.
     * @param _currentTime The current timestamp.
     * @return The calculated change in quantumState (can be negative for decay).
     */
    function _calculateStateChange(FlowShard storage _shard, uint256 _currentTime) internal view returns (int256) {
        uint256 timeElapsed = _currentTime - _shard.lastStateUpdateTime;
        if (timeElapsed == 0) {
            return 0; // No time elapsed, no state change
        }

        // Decay is proportional to current state and time
        uint256 potentialDecay = (_shard.quantumState * decayFactor * timeElapsed) / 1e18; // Use 1e18 for precision if factors are < 1

        // Infusion is proportional to bonded amount and time
        uint256 potentialInfusion = (_shard.bondedAmount * infusionFactor * timeElapsed) / 1e18; // Use 1e18 for precision

        // Net change is infusion minus decay
        if (potentialInfusion >= potentialDecay) {
            return int256(potentialInfusion - potentialDecay);
        } else {
            return -int256(potentialDecay - potentialInfusion);
        }
    }

    /**
     * @dev Updates a shard's quantumState and lastStateUpdateTime based on elapsed time and bonded amount.
     * This internal function is called by external functions that modify state or are state-dependent.
     * @param _shardId The ID of the shard to update.
     */
    function _applyStateUpdate(uint256 _shardId) internal {
        FlowShard storage shard = shards[_shardId];
        if (shardOwner[_shardId] == address(0)) return; // Shard doesn't exist

        uint256 currentTime = block.timestamp;
        if (currentTime <= shard.lastStateUpdateTime) {
            return; // State is already up-to-date or time hasn't moved forward
        }

        int256 stateChange = _calculateStateChange(shard, currentTime);
        uint256 oldState = shard.quantumState;
        uint256 newState;

        if (stateChange >= 0) {
             newState = shard.quantumState + uint256(stateChange);
        } else {
            // Prevent state from going below 0
            uint256 absoluteDecay = uint256(-stateChange);
            newState = shard.quantumState >= absoluteDecay ? shard.quantumState - absoluteDecay : 0;
        }

        // Cap state at a theoretical max? (Optional, uncomment if needed)
        // uint256 MAX_STATE = 1e18; // Example max state
        // if (newState > MAX_STATE) newState = MAX_STATE;


        shard.quantumState = newState;
        shard.lastStateUpdateTime = currentTime; // Update timestamp after applying change

        if (oldState != newState) {
            emit ShardStateUpdated(_shardId, oldState, newState);
        }
    }

    /**
     * @dev Transfers a shard, updating ownership mappings.
     * @param _from The current owner.
     * @param _to The new owner.
     * @param _shardId The ID of the shard to transfer.
     */
    function _transfer(address _from, address _to, uint256 _shardId) internal {
        _applyStateUpdate(_shardId); // Update state before transfer

        ownerShardCount[_from]--;
        shardOwner[_shardId] = _to;
        ownerShardCount[_to]++;

        emit ShardTransferred(_shardId, _from, _to);
    }

    /**
     * @dev Mints a new shard and assigns it to an owner.
     * @param _to The address to mint the shard for.
     * @param _initialBondAmount The initial amount of BToken to bond.
     */
    function _mint(address _to, uint256 _initialBondAmount) internal {
        uint256 newShardId = shardCounter;
        shardCounter++;

        require(_to != address(0), "Mint to zero address");

        uint256 currentTime = block.timestamp;
        shards[newShardId] = FlowShard({
            id: newShardId,
            quantumState: 0, // Starts at base state
            creationTime: currentTime,
            lastStateUpdateTime: currentTime,
            bondedAmount: 0, // Bonded amount added below
            lastBondUpdateTime: currentTime, // Set when initial bond is added
            temporalLockEnd: 0
        });

        shardOwner[newShardId] = _to;
        ownerShardCount[_to]++;

        emit ShardMinted(newShardId, _to, _initialBondAmount);

        // Apply initial bond
        if (_initialBondAmount > 0) {
            _bondInternal(newShardId, _initialBondAmount);
        }
    }

    /**
     * @dev Burns a shard, removing it from the system.
     * @param _shardId The ID of the shard to burn.
     * @param _owner The current owner of the shard.
     */
    function _burn(uint256 _shardId, address _owner) internal {
        // Ensure any bonded tokens are returned before burning (Optional, depends on desired behavior)
        // For simplicity here, let's say bonded tokens are forfeited or must be unbonded first.
        // Add a check or automatic unbonding if needed:
        // require(shards[_shardId].bondedAmount == 0, "Unbond tokens before burning");

        _applyStateUpdate(_shardId); // Final state update before burning

        ownerShardCount[_owner]--;
        delete shardOwner[_shardId];
        delete shards[_shardId];

        emit ShardBurned(_shardId, _owner);
    }

     /**
     * @dev Internal function to handle bonding BToken to a shard.
     * Assumes transferFrom has already occurred.
     * @param _shardId The ID of the shard.
     * @param _amount The amount to bond.
     */
    function _bondInternal(uint256 _shardId, uint256 _amount) internal requireShardExists(_shardId) {
        FlowShard storage shard = shards[_shardId];
        _applyStateUpdate(_shardId); // Update state before changing bonded amount affects future calcs

        shard.bondedAmount += _amount;
        shard.lastBondUpdateTime = block.timestamp;

        emit Bonded(_shardId, shardOwner[_shardId], _amount);
    }

    /**
     * @dev Internal function to handle unbonding BToken from a shard.
     * Assumes transfer has already occurred.
     * @param _shardId The ID of the shard.
     * @param _amount The amount to unbond.
     */
    function _unbondInternal(uint256 _shardId, uint256 _amount) internal requireShardExists(_shardId) {
        FlowShard storage shard = shards[_shardId];
        require(shard.bondedAmount >= _amount, InsufficientFunds(shard.bondedAmount, _amount));

        _applyStateUpdate(_shardId); // Update state before changing bonded amount affects future calcs

        shard.bondedAmount -= _amount;
        shard.lastBondUpdateTime = block.timestamp; // Update timestamp even if unbonding

        emit Unbonded(_shardId, shardOwner[_shardId], _amount);
    }


    // --- Constructor ---

    /**
     * @dev Deploys the contract, setting the owner and BToken address.
     * Also initializes default parameters and fees.
     * @param _bToken The address of the ERC20 token used for bonding.
     */
    constructor(address _bToken) {
        owner = msg.sender;
        bTokenAddress = _bToken;
        shardCounter = 0;
        paused = false;

        // Set initial default parameters (these are examples, tune based on desired mechanics)
        decayFactor = 1e15;      // 0.1% decay per second per unit of state
        infusionFactor = 1e15;   // 0.1% state boost per second per unit of bonded token
        fusionBoostFactor = 1.5e18; // 1.5x boost on incoming state during fusion
        splitPenaltyFactor = 0.5e18; // 0.5x state retained on split (loses half)

        // Set initial default fees (in BToken)
        fuseFee = 10e18; // 10 BToken
        splitFee = 20e18; // 20 BToken
        challengeFee = 5e18; // 5 BToken
        mintFee = 5e18; // 5 BToken initial bond
    }

    // --- Read Functions ---

    /**
     * @dev Get details of a specific Shard.
     * @param _shardId The ID of the shard.
     * @return FlowShard struct containing all shard details.
     */
    function getShard(uint256 _shardId) public view requireShardExists(_shardId) returns (FlowShard memory) {
        return shards[_shardId];
    }

    /**
     * @dev Gets the owner of a specific Shard. ERC721-like function.
     * @param _shardId The ID of the shard.
     * @return The address of the shard's owner.
     */
    function ownerOf(uint256 _shardId) public view requireShardExists(_shardId) returns (address) {
        return shardOwner[_shardId];
    }

    /**
     * @dev Gets the number of Shards owned by an address. ERC721-like function.
     * @param _owner The address to query.
     * @return The count of shards owned by the address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for zero address");
        return ownerShardCount[_owner];
    }

    /**
     * @dev Gets the current calculated quantum state of a shard, accounting for potential decay since last update.
     * Does NOT modify the stored state.
     * @param _shardId The ID of the shard.
     * @return The current calculated quantum state.
     */
    function getShardQuantumState(uint256 _shardId) public view requireShardExists(_shardId) returns (uint256) {
        FlowShard storage shard = shards[_shardId];
        uint256 currentTime = block.timestamp;

        // Calculate potential state change since last update
        int256 stateChange = _calculateStateChange(shard, currentTime);

        // Return the state as if the update happened now, but don't store it
        if (stateChange >= 0) {
             return shard.quantumState + uint256(stateChange);
        } else {
            uint256 absoluteDecay = uint256(-stateChange);
            return shard.quantumState >= absoluteDecay ? shard.quantumState - absoluteDecay : 0;
        }
    }


    /**
     * @dev Calculates the current Flow Rate for a user.
     * Flow Rate is an example calculation: sum of (sqrt(bonded_amount) + shard_state * factor) for owned shards.
     * Applies current shard states for calculation accuracy.
     * @param _user The address to calculate Flow Rate for.
     * @return The calculated Flow Rate.
     */
    function calculateUserFlowRate(address _user) public view returns (uint256) {
        uint256 totalFlowRate = 0;
        uint256 ownedCount = ownerShardCount[_user];

        if (ownedCount == 0) {
            return 0;
        }

        // Iterate through all shards (inefficient for many shards, but simple for example)
        // In a real application, you'd store owned shard IDs in an array or linked list.
        // For this example, we iterate up to the current shardCounter.
        // NOTE: This loop can become very expensive with many shards! This is a limitation of this simplified example structure.
        for (uint256 i = 0; i < shardCounter; i++) {
            if (shardOwner[i] == _user) {
                // Calculate effective state for this shard
                uint256 currentShardState = getShardQuantumState(i); // Get state applying current time decay/infusion

                // Example calculation: FlowRate increases with bonded amount (sqrt to give diminishing returns) and shard state
                // Using a simple approach for sqrt: integer approximation or just bondedAmount
                // Let's simplify: FlowRate = sum(bondedAmount * factor + shardState * factor)
                totalFlowRate += (shards[i].bondedAmount * infusionFactor + currentShardState * fusionBoostFactor) / 1e18; // Use factors for scaling
            }
        }

        return totalFlowRate;
    }

     /**
     * @dev Gets the effective Flow Rate for a user, respecting delegation.
     * If a user has delegated their Flow Rate, this returns the delegate's Flow Rate.
     * @param _user The user's address.
     * @return The effective Flow Rate.
     */
    function getUserFlowRate(address _user) public view returns (uint256) {
        address delegate = userDelegates[_user];
        if (delegate != address(0)) {
            return calculateUserFlowRate(delegate); // Use delegate's Flow Rate
        } else {
            return calculateUserFlowRate(_user); // Use user's own Flow Rate
        }
    }

    /**
     * @dev Checks who a user has delegated their Flow Rate calculation to.
     * @param _user The address to check.
     * @return The delegate address, or address(0) if no delegation is set.
     */
    function checkFlowRateDelegate(address _user) public view returns (address) {
        return userDelegates[_user];
    }

    /**
     * @dev Returns the total number of Shards minted.
     * @return Total supply of shards.
     */
    function getTotalSupply() public view returns (uint256) {
        return shardCounter;
    }

    // --- Write Functions ---

    /**
     * @dev Mints a new Flow Shard for the caller.
     * Requires bonding an initial amount of `BToken` as the mint fee.
     * @param _initialBondAmount The amount of BToken to bond initially. Must be at least `mintFee`.
     */
    function mintShard(uint256 _initialBondAmount) public whenNotPaused {
        require(_initialBondAmount >= mintFee, InsufficientFunds(mintFee, _initialBondAmount));

        // Transfer BToken from caller to the contract
        bool success = IERC20(bTokenAddress).transferFrom(msg.sender, address(this), _initialBondAmount);
        require(success, "BToken transfer failed for mint");

        _mint(msg.sender, _initialBondAmount);
    }

    /**
     * @dev Transfers ownership of a Flow Shard. ERC721-like function.
     * @param _to The recipient address.
     * @param _shardId The ID of the shard to transfer.
     */
    function transferShard(address _to, uint256 _shardId) public whenNotPaused requireShardOwner(_shardId) {
        require(_to != address(0), "Transfer to zero address");
        require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardId));

        _transfer(msg.sender, _to, _shardId);
    }

    /**
     * @dev Bonds `_amount` of `BToken` to a specific Shard.
     * The BToken is transferred from the caller to the contract's balance.
     * Requires the caller to have approved the contract beforehand.
     * @param _shardId The ID of the shard to bond to.
     * @param _amount The amount of BToken to bond.
     */
    function bondToShard(uint256 _shardId, uint256 _amount) public whenNotPaused requireShardOwner(_shardId) {
        require(_amount > 0, InvalidAmount());

        // Transfer BToken from caller to the contract
        bool success = IERC20(bTokenAddress).transferFrom(msg.sender, address(this), _amount);
        require(success, "BToken transfer failed for bonding");

        _bondInternal(_shardId, _amount);
    }

    /**
     * @dev Unbonds `_amount` of `BToken` from a specific Shard.
     * The BToken is transferred from the contract's balance back to the caller.
     * @param _shardId The ID of the shard to unbond from.
     * @param _amount The amount of BToken to unbond.
     */
    function unbondFromShard(uint256 _shardId, uint256 _amount) public whenNotPaused requireShardOwner(_shardId) {
        require(_amount > 0, InvalidAmount());
        require(shards[_shardId].bondedAmount >= _amount, InsufficientFunds(_amount, shards[_shardId].bondedAmount));

        _unbondInternal(_shardId, _amount);

        // Transfer BToken from the contract to the caller
        bool success = IERC20(bTokenAddress).transfer(msg.sender, _amount);
        require(success, "BToken transfer failed for unbonding"); // Should not fail if contract balance is sufficient
    }

    /**
     * @dev Manually triggers the state update calculation for a shard.
     * Anyone can call this to update a shard's state based on time and bonding.
     * This makes the state calculation 'lazy' - it only updates when triggered.
     * @param _shardId The ID of the shard to update.
     */
    function updateShardState(uint256 _shardId) public whenNotPaused requireShardExists(_shardId) {
        _applyStateUpdate(_shardId);
    }

    /**
     * @dev Fuses two shards into one. One shard is burned, the other receives a state boost.
     * Requires ownership of both shards and payment of a fee.
     * @param _shardId1 The ID of the first shard.
     * @param _shardId2 The ID of the second shard.
     * @param _shardToKeep The ID of the shard that will remain and receive the boost (must be _shardId1 or _shardId2).
     * @param _fuseFeeAmount The amount of BToken paid as fee. Must be at least `fuseFee`.
     */
    function fuseShards(uint256 _shardId1, uint256 _shardId2, uint256 _shardToKeep, uint256 _fuseFeeAmount) public whenNotPaused {
        require(msg.sender == shardOwner[_shardId1], NotShardOwner(_shardId1));
        require(msg.sender == shardOwner[_shardId2], NotShardOwner(_shardId2));
        require(_shardId1 != _shardId2, InvalidShardId());
        require(_shardToKeep == _shardId1 || _shardToKeep == _shardId2, InvalidShardId());
        require(_fuseFeeAmount >= fuseFee, InsufficientFunds(fuseFee, _fuseFeeAmount));

        uint256 shardToBurn = (_shardToKeep == _shardId1) ? _shardId2 : _shardId1;

        require(shards[_shardToKeep].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardToKeep));
        require(shards[shardToBurn].temporalLockEnd <= block.timestamp, TemporalLockActive(shardToBurn));

        // Transfer fee from caller to contract
        bool success = IERC20(bTokenAddress).transferFrom(msg.sender, address(this), _fuseFeeAmount);
        require(success, "BToken transfer failed for fusion fee");

        // Apply state updates before fusion logic
        _applyStateUpdate(_shardToKeep);
        _applyStateUpdate(shardToBurn);

        // Calculate state boost from the burned shard
        // Example: Boost is proportional to the burned shard's state multiplied by a factor
        uint256 boostAmount = (shards[shardToBurn].quantumState * fusionBoostFactor) / 1e18;

        // Apply boost to the kept shard
        shards[_shardToKeep].quantumState += boostAmount;

        // Burn the other shard
        _burn(shardToBurn, msg.sender);

        emit ShardFused(_shardToKeep, _shardId1, _shardId2);
    }

    /**
     * @dev Splits a shard into two. The original state is divided with a penalty,
     * creating a new shard with part of the state. Requires payment of a fee.
     * @param _shardId The ID of the shard to split.
     * @param _splitFeeAmount The amount of BToken paid as fee. Must be at least `splitFee`.
     */
    function splitShard(uint256 _shardId, uint256 _splitFeeAmount) public whenNotPaused requireShardOwner(_shardId) {
        require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardId));
        require(_splitFeeAmount >= splitFee, InsufficientFunds(splitFee, _splitFeeAmount));
        // Optional: Require minimum state to split
        // require(shards[_shardId].quantumState > 1000, "Shard state too low to split");

        // Transfer fee from caller to contract
        bool success = IERC20(bTokenAddress).transferFrom(msg.sender, address(this), _splitFeeAmount);
        require(success, "BToken transfer failed for split fee");

        // Apply state update before splitting
        _applyStateUpdate(_shardId);

        FlowShard storage originalShard = shards[_shardId];
        uint256 originalState = originalShard.quantumState;

        // Calculate state retained for the original and new shard after penalty
        uint256 stateAfterPenalty = (originalState * splitPenaltyFactor) / 1e18;
        uint256 newStateAmount = stateAfterPenalty / 2;
        uint256 originalRetainedState = stateAfterPenalty - newStateAmount;

        // Update original shard's state
        originalShard.quantumState = originalRetainedState;
        // Note: bonded amount is NOT split, it remains with the original shard.

        // Mint a new shard
        uint256 newShardId = shardCounter;
        shardCounter++;

        uint256 currentTime = block.timestamp;
        shards[newShardId] = FlowShard({
            id: newShardId,
            quantumState: newStateAmount, // New shard gets split state
            creationTime: currentTime,
            lastStateUpdateTime: currentTime,
            bondedAmount: 0, // New shard starts with no bonded tokens
            lastBondUpdateTime: currentTime,
            temporalLockEnd: 0
        });

        shardOwner[newShardId] = msg.sender;
        ownerShardCount[msg.sender]++;

        emit ShardSplit(_shardId, newShardId);
        emit ShardMinted(newShardId, msg.sender, 0); // Emit mint event for the new shard
    }

    /**
     * @dev Locks a shard, preventing transfer, fusion, or splitting until the lock duration passes.
     * @param _shardId The ID of the shard to lock.
     * @param _duration The duration of the lock in seconds.
     */
    function temporalLockShard(uint256 _shardId, uint256 _duration) public whenNotPaused requireShardOwner(_shardId) {
        require(_duration > 0, InvalidAmount());
        require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardId)); // Cannot lock an already locked shard (or extend it directly)

        shards[_shardId].temporalLockEnd = block.timestamp + _duration;

        emit ShardTemporalLocked(_shardId, _duration, shards[_shardId].temporalLockEnd);
    }

    /**
     * @dev Releases the temporal lock on a shard if the lock duration has passed.
     * @param _shardId The ID of the shard to unlock.
     */
    function releaseTemporalLock(uint256 _shardId) public requireShardOwner(_shardId) {
        require(shards[_shardId].temporalLockEnd > 0, TemporalLockNotActive(_shardId));
        require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockNotExpired(_shardId));

        shards[_shardId].temporalLockEnd = 0;

        emit ShardTemporalLockReleased(_shardId);
    }

    /**
     * @dev Allows a user to attempt to 'challenge' a shard's state transition,
     * potentially nudging its state towards a target value. This is a simplified
     * representation of a complex interaction or game mechanic. Requires a fee.
     * The outcome (if any) is simulated here by adding a small state bonus towards target.
     * @param _shardId The ID of the shard to challenge.
     * @param _targetState An arbitrary target state value.
     * @param _challengeFeeAmount The amount of BToken paid as fee. Must be at least `challengeFee`.
     */
    function challengeStateTransition(uint256 _shardId, uint256 _targetState, uint256 _challengeFeeAmount) public whenNotPaused requireShardOwner(_shardId) {
        require(_challengeFeeAmount >= challengeFee, InsufficientFunds(challengeFee, _challengeFeeAmount));
        require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardId));

         // Transfer fee from caller to contract
        bool success = IERC20(bTokenAddress).transferFrom(msg.sender, address(this), _challengeFeeAmount);
        require(success, "BToken transfer failed for challenge fee");

        // Apply state update before challenge effect
        _applyStateUpdate(_shardId);

        // Simulate the "challenge" effect: nudge state towards the target
        // This is a placeholder. Real logic could be complex, maybe based on fee amount,
        // current state, target state difference, or even requiring external oracle data.
        uint256 currentState = shards[_shardId].quantumState;
        uint256 newState = currentState;

        if (currentState < _targetState) {
             // Example: Add 1% of the difference towards the target state
             uint256 difference = _targetState - currentState;
             newState += (difference * 1e16) / 1e18; // Add 1%
        } else if (currentState > _targetState && currentState > 0) {
             // Example: Subtract 0.5% of the difference (avoiding state going negative)
             uint256 difference = currentState - _targetState;
             uint256 reduction = (difference * 5e15) / 1e18; // Reduce by 0.5%
             newState = currentState >= reduction ? currentState - reduction : 0;
        }
        // If currentState == _targetState, no change

        shards[_shardId].quantumState = newState;
        shards[_shardId].lastStateUpdateTime = block.timestamp; // Update time since state changed

        emit StateTransitionChallenged(_shardId, _targetState, _challengeFeeAmount);
        emit ShardStateUpdated(_shardId, currentState, newState); // Emit state change event
    }


    /**
     * @dev Delegates the calculation and use of the caller's Flow Rate to another address.
     * This allows the delegate to use the delegator's combined Flow Rate in functions requiring `requireMinFlowRate`.
     * @param _delegate The address to delegate to. Set to address(0) to remove delegation.
     */
    function delegateFlowRate(address _delegate) public whenNotPaused {
        require(_delegate != msg.sender, SelfDelegationForbidden());
        require(userDelegates[msg.sender] == address(0) || _delegate == address(0), DelegationAlreadySet()); // Only set if not already set, unless removing

        userDelegates[msg.sender] = _delegate;
        emit FlowRateDelegated(msg.sender, _delegate);
    }

    /**
     * @dev Removes Flow Rate delegation for the caller.
     */
    function undelegateFlowRate() public whenNotPaused {
        require(userDelegates[msg.sender] != address(0), DelegationNotSet());

        delete userDelegates[msg.sender];
        emit FlowRateUndelegated(msg.sender);
    }

    /**
     * @dev An example function that is gated by a minimum required User Flow Rate.
     * This function itself doesn't perform a complex action but demonstrates how `requireMinFlowRate` works.
     * @param _minRateRequired The minimum calculated Flow Rate needed to call this function.
     */
    function accessConditionalFunction(uint256 _minRateRequired) public whenNotPaused requireMinFlowRate(_minRateRequired) {
        // Placeholder logic: could emit an event, distribute rewards, unlock a feature, etc.
        // requireMinFlowRate modifier handles the access control based on getUserFlowRate(msg.sender)
        // This function is callable ONLY if the caller's (or their delegate's) Flow Rate >= _minRateRequired.
        // Example: emit an event indicating successful access
        // emit ConditionalAccessGranted(msg.sender, _minRateRequired);
    }

    /**
     * @dev An example function that is gated by a Shard's quantumState being within a specific range.
     * Requires ownership of the shard.
     * @param _shardId The ID of the shard to check.
     * @param _minStateRequired The minimum state required.
     * @param _maxStateRequired The maximum state allowed.
     */
     function accessStateGatedFunction(uint256 _shardId, uint256 _minStateRequired, uint256 _maxStateRequired)
        public
        whenNotPaused
        requireShardOwner(_shardId)
        requireShardStateRange(_shardId, _minStateRequired, _maxStateRequired)
    {
        // Placeholder logic: could emit an event, perform an action related to the shard, etc.
        // requireShardStateRange modifier handles the access control based on getShardQuantumState(_shardId)
        // This function is callable ONLY if the caller owns _shardId AND its state is within the range.
        // Example: emit an event
        // emit StateGatedAccessGranted(msg.sender, _shardId, _minStateRequired, _maxStateRequired);
    }


    /**
     * @dev Allows the owner of a shard to burn it, removing it permanently.
     * Any bonded tokens on this shard are forfeited to the contract.
     * @param _shardId The ID of the shard to burn.
     */
    function burnShard(uint256 _shardId) public whenNotPaused requireShardOwner(_shardId) {
         require(shards[_shardId].temporalLockEnd <= block.timestamp, TemporalLockActive(_shardId));
        // Bonded tokens remain in the contract. Implement unbonding requirement before burn if desired.
        _burn(_shardId, msg.sender);
    }


    // --- Owner / Admin Functions ---

    /**
     * @dev Owner-only function to set the parameters influencing shard state dynamics.
     * Factors are expected to be fixed point numbers (e.g., 1e18 for 1x).
     * @param _decayFactor_ State lost per second per unit of state.
     * @param _infusionFactor_ State gained per unit of bonded BToken per second.
     * @param _fusionBoost_ State multiplier when fusing shards.
     * @param _splitPenalty_ State reduction factor when splitting.
     */
    function setParameters(uint256 _decayFactor_, uint256 _infusionFactor_, uint256 _fusionBoost_, uint256 _splitPenalty_) public onlyOwner {
        decayFactor = _decayFactor_;
        infusionFactor = _infusionFactor_;
        fusionBoostFactor = _fusionBoost_;
        splitPenaltyFactor = _splitPenalty_;
        emit ParametersSet(decayFactor, infusionFactor, fusionBoostFactor, splitPenaltyFactor);
    }

    /**
     * @dev Owner-only function to set the BToken fees for various operations.
     * @param _fuseFee_ Fee for fusing shards.
     * @param _splitFee_ Fee for splitting shards.
     * @param _challengeFee_ Fee for challenging state transitions.
     * @param _mintFee_ Initial bond amount required for minting.
     */
     function setFees(uint256 _fuseFee_, uint256 _splitFee_, uint256 _challengeFee_, uint256 _mintFee_) public onlyOwner {
        fuseFee = _fuseFee_;
        splitFee = _splitFee_;
        challengeFee = _challengeFee_;
        mintFee = _mintFee_;
        emit FeesSet(fuseFee, splitFee, challengeFee, mintFee);
     }


    /**
     * @dev Owner-only function to pause contract operations.
     * Blocks most user interactions using the `whenNotPaused` modifier.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Owner-only function to unpause contract operations.
     * Allows user interactions again.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Owner-only function to withdraw any ERC20 token held by the contract,
     * including collected BToken fees or tokens sent accidentally.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawERC20(address _token, uint256 _amount) public onlyOwner {
        require(_amount > 0, InvalidAmount());
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) >= _amount, InsufficientFunds(_amount, token.balanceOf(address(this))));

        bool success = token.transfer(owner, _amount);
        require(success, "ERC20 withdrawal failed");
        emit ERC20Withdrawn(_token, owner, _amount);
    }

    // Fallback function to accept potential ETH (not required by concept, but good practice if ETH might be sent)
    // receive() external payable {}

     // Function to withdraw ETH if any was sent
    // function withdrawETH(uint256 _amount) public onlyOwner {
    //     require(_amount > 0, InvalidAmount());
    //     require(address(this).balance >= _amount, InsufficientFunds(_amount, address(this).balance));
    //     (bool success, ) = payable(owner).call{value: _amount}("");
    //     require(success, "ETH withdrawal failed");
    // }
}
```