The following smart contract, **VerifiableIntentNetwork**, introduces an advanced concept for decentralized task execution and state verification. It allows users to express "intents" – desired on-chain state changes – by defining pre-conditions and post-conditions. "Solvers" (automated agents or individuals) compete to fulfill these intents off-chain, and then submit a claim for verification. The contract then rigorously verifies these claims on-chain by checking the specified conditions against the current blockchain state. Successful solvers are rewarded with a bounty, while failed or malicious fulfillments can lead to slashing of their staked collateral.

This design is unique in its focus on **on-chain verifiable conditions** as the core mechanism for intent fulfillment, minimizing reliance on external oracles for critical trust assumptions. It's a blend of decentralized task markets, verifiable computation (albeit state-based, not arbitrary code), and a reputation/incentive system, reflecting trends towards more expressive and automated on-chain operations.

---

## VerifiableIntentNetwork: Outline and Function Summary

This contract establishes a decentralized network for defining and fulfilling on-chain intents.

### Outline

1.  **Libraries & Interfaces**: External utilities for safe operations and token interactions.
2.  **Enums & Structs**: Define types for intents, solvers, conditions, and their statuses/operators.
3.  **Core State Variables**: Mappings and counters for managing intents, solvers, and network configuration.
4.  **Events**: Log significant actions for off-chain indexing and transparency.
5.  **Access Control**: Standard ownership for administrative functions.
6.  **Internal Helpers**: Private functions for condition checking and reputation management.
7.  **Intent Management (User-Facing)**: Functions for creating, managing, and canceling intents.
8.  **Solver Management (Solver-Facing)**: Functions for registering, staking, and managing solver profiles.
9.  **Fulfillment & Verification**: The core logic for solvers to claim and verify intent fulfillment.
10. **Reputation & Slashing**: Mechanism for challenging fulfillments, resolving disputes, and penalizing solvers.
11. **Configuration & Fees**: Functions for the owner to manage protocol parameters.
12. **Query Functions**: Read-only functions to retrieve network data.

### Function Summary

**I. Core State Management**
1.  `constructor()`: Initializes the contract owner, fee recipient, and protocol fee.

**II. Intent Management (User-Facing)**
2.  `createIntent(IntentData calldata _intentData, address _bountyToken, uint256 _bountyAmount)`: Allows a user to post a new intent with specified conditions, expiration, required solver bond, and bounty.
3.  `cancelIntent(uint256 _intentId)`: Permits the intent creator to cancel an unfulfilled intent and reclaim their bounty.
4.  `updateIntentMetadata(uint256 _intentId, string calldata _newMetadataURI)`: Allows the intent creator to update the off-chain metadata URI for their intent.
5.  `setIntentSolverBondRequirement(uint256 _intentId, uint256 _newBondAmount)`: Allows the intent creator to adjust the minimum solver bond required for a specific intent.
6.  `extendIntentExpiration(uint256 _intentId, uint64 _newExpiration)`: Allows the intent creator to extend the fulfillment deadline for an intent.

**III. Solver Management (Solver-Facing)**
7.  `registerSolver(string calldata _capabilitiesURI)`: Enables an address to register as a solver, requiring an initial stake and an optional URI describing capabilities.
8.  `deregisterSolver()`: Allows a registered solver to initiate the deregistration process and eventually withdraw their stake.
9.  `stakeSolverBond(uint256 _amount)`: Allows a solver to increase their staked collateral.
10. `unstakeSolverBond(uint256 _amount)`: Allows a solver to withdraw a portion of their stake, subject to cool-down periods.
11. `updateSolverCapabilities(string calldata _newCapabilitiesURI)`: Allows a solver to update their off-chain capabilities URI.

**IV. Fulfillment & Verification (Interaction)**
12. `submitAndVerifyFulfillment(uint256 _intentId)`: **The core function.** A registered solver calls this *after* they have performed the off-chain/on-chain actions necessary to fulfill an intent. The contract verifies all pre-conditions and post-conditions against the current state, and if successful, awards the bounty.

**V. Reputation & Slashing**
13. `challengeFulfillment(uint256 _intentId)`: Allows any participant (by staking a bond) to challenge a `Fulfilled` intent, claiming its post-conditions were not truly met.
14. `resolveChallenge(uint256 _intentId, bool _isSolverGuilty)`: The contract owner or designated operator resolves a challenge, leading to slashing the solver's bond (if guilty) or the challenger's bond (if solver is innocent).
15. `penalizeSolver(address _solver, uint256 _penaltyAmount)`: Allows the owner to directly penalize a solver by slashing a specified amount from their bond (e.g., for off-chain infractions or governance decisions).
16. `distributePenaltyFunds(address _recipient, uint256 _amount)`: Allows the owner to distribute collected penalty funds to a specified recipient (e.g., a community treasury or the successful challenger).

**VI. Configuration & Admin**
17. `setOperator(address _operator, bool _status)`: Grants or revokes operator roles, which might have permissions for certain admin tasks like resolving challenges.
18. `setFeeRecipient(address _newRecipient)`: Allows the owner to change the address where protocol fees are collected.
19. `setProtocolFee(uint16 _newFeeBps)`: Allows the owner to adjust the protocol fee percentage (in basis points) taken from bounties.
20. `withdrawProtocolFees(address _token)`: Allows the fee recipient to withdraw accumulated protocol fees for a specific token (or ETH).

**VII. Query Functions (Read-only)**
21. `getIntent(uint256 _intentId)`: Retrieves all details of a specific intent.
22. `getSolver(address _solverAddress)`: Retrieves all registration and reputation details for a specific solver.
23. `getSolverStake(address _solverAddress)`: Returns the current staked amount of a solver.
24. `isSolverRegistered(address _solverAddress)`: Checks if an address is currently registered as a solver.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title VerifiableIntentNetwork
/// @author YourName (replace with your actual name/handle)
/// @notice A decentralized network for defining and fulfilling on-chain intents with verifiable conditions.
/// @dev This contract allows users to post intents (desired state changes) with pre- and post-conditions.
///      Solvers fulfill these intents off-chain and submit for on-chain verification.
///      Includes staking, reputation, and challenge mechanisms.

contract VerifiableIntentNetwork is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /*///////////////////////////////////////////////////////////////
                            ENUMS & STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Represents the current status of an intent.
    enum IntentStatus {
        Pending,   // Intent is active and awaiting fulfillment
        Fulfilled, // Intent has been successfully fulfilled and verified
        Challenged, // Intent fulfillment is under dispute
        Expired,   // Intent's expiration time has passed
        Canceled,  // Intent creator canceled it
        Failed     // Intent failed verification or solver was slashed
    }

    /// @dev Defines types of on-chain conditions that can be checked.
    enum ConditionType {
        ERC20_BALANCE,          // Checks balance of an ERC20 token for an address
        ERC20_ALLOWANCE,        // Checks allowance of an ERC20 token for a spender by an owner
        ETH_BALANCE,            // Checks native ETH balance of an address
        CONTRACT_CALL_BOOLEAN   // Calls a view function on a contract expected to return a boolean
    }

    /// @dev Defines comparison operators for conditions.
    enum ComparisonOperator {
        EQ,  // Equal to
        NE,  // Not equal to
        GT,  // Greater than
        LT,  // Less than
        GTE, // Greater than or equal to
        LTE  // Less than or equal to
    }

    /// @dev Represents a single verifiable condition.
    struct Condition {
        ConditionType conditionType;
        address targetAddress;      // e.g., token address (for ERC20), contract address (for CALL_BOOLEAN)
        address subjectAddress;     // e.g., account address (for balance), owner address (for allowance)
        address secondaryAddress;   // e.g., spender address (for allowance)
        uint256 value;              // The value to compare against
        ComparisonOperator operator;
        bytes callData;             // For CONTRACT_CALL_BOOLEAN, the ABI-encoded call data (selector + params)
    }

    /// @dev Represents an intent posted by a user.
    struct Intent {
        uint256 intentId;
        address creator;
        address bountyToken;         // address(0) for native ETH
        uint256 bountyAmount;
        uint64 expiration;
        uint256 solverBondRequired;  // Minimum bond required for a solver to attempt this intent
        Condition[] preConditions;
        Condition[] postConditions;
        IntentStatus status;
        address solverAddress;       // Address of the solver who fulfilled it
        bytes32 fulfillmentHash;     // Hash of the fulfillment transaction (optional, or tx.hash of `submitAndVerifyFulfillment`)
        string metadataURI;          // URI to off-chain human-readable intent description
        uint256 challengedBy;        // Intent ID of a challenge bond if challenged (0 if not challenged)
        uint64 fulfilledTimestamp;   // Timestamp when intent was fulfilled
    }

    /// @dev Represents a registered solver in the network.
    struct SolverData {
        bool isRegistered;
        uint256 stake;
        uint256 lockedStake;         // Stake locked during cool-down or dispute
        int256 reputationScore;       // Can be negative for penalization
        string capabilitiesURI;      // URI to off-chain description of solver's capabilities
        uint64 lastActive;           // Timestamp of last successful fulfillment
        uint64 unstakeCooldownEnd;   // Timestamp when unstake cooldown ends
    }

    /*///////////////////////////////////////////////////////////////
                            CORE STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 private s_nextIntentId;
    mapping(uint256 => Intent) private s_intents;
    mapping(address => SolverData) private s_solverData;
    mapping(address => bool) private s_operators; // Addresses granted operator roles

    address public s_feeRecipient;          // Address to collect protocol fees
    uint16 public s_protocolFeeBps;         // Protocol fee percentage in basis points (e.g., 100 = 1%)
    uint256 public constant MIN_SOLVER_STAKE = 0.01 ether; // Minimum stake to register as a solver
    uint64 public constant UNSTAKE_COOLDOWN = 7 days;      // Cooldown period for unstaking
    uint64 public constant CHALLENGE_PERIOD = 2 days;      // Time window for challenging a fulfilled intent

    int256 public constant REPUTATION_SUCCESS_BONUS = 100;
    int256 public constant REPUTATION_FAILURE_PENALTY = 200;
    int256 public constant REPUTATION_CHALLENGE_WIN_BONUS = 50;
    int256 public constant REPUTATION_CHALLENGE_LOSE_PENALTY = 100;
    
    // Minimum and maximum reputation scores to prevent overflow/underflow
    int256 public constant MIN_REPUTATION_SCORE = -1_000_000;
    int256 public constant MAX_REPUTATION_SCORE = 1_000_000;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event IntentCreated(
        uint256 indexed intentId,
        address indexed creator,
        address bountyToken,
        uint256 bountyAmount,
        uint64 expiration,
        string metadataURI
    );
    event IntentCanceled(uint256 indexed intentId, address indexed creator);
    event IntentFulfilled(
        uint256 indexed intentId,
        address indexed solver,
        uint256 solverReward,
        uint64 fulfilledTimestamp
    );
    event IntentStatusUpdated(
        uint256 indexed intentId,
        IntentStatus oldStatus,
        IntentStatus newStatus
    );

    event SolverRegistered(
        address indexed solverAddress,
        uint256 initialStake,
        string capabilitiesURI
    );
    event SolverDeregistered(address indexed solverAddress);
    event SolverStaked(address indexed solverAddress, uint256 amount);
    event SolverUnstaked(address indexed solverAddress, uint256 amount);
    event SolverReputationUpdated(
        address indexed solverAddress,
        int256 oldReputation,
        int256 newReputation
    );
    event SolverPenalized(
        address indexed solverAddress,
        uint256 amount,
        string reason
    );

    event FulfillmentChallenged(
        uint256 indexed intentId,
        address indexed challenger,
        uint256 challengeBondAmount
    );
    event ChallengeResolved(
        uint256 indexed intentId,
        address indexed challenger,
        bool isSolverGuilty
    );

    event ProtocolFeeUpdated(uint16 newFeeBps);
    event FeeRecipientUpdated(address newRecipient);
    event FeesWithdrawn(address indexed recipient, address indexed token, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    /// @dev Modifier to restrict access to operators or the owner.
    modifier onlyOperator() {
        require(s_operators[msg.sender] || owner() == msg.sender, "Caller is not an operator");
        _;
    }

    /// @notice Constructor to initialize the contract.
    /// @param _feeRecipient The initial address to receive protocol fees.
    /// @param _protocolFeeBps The initial protocol fee percentage in basis points (e.g., 100 for 1%).
    constructor(address _feeRecipient, uint16 _protocolFeeBps) Ownable(msg.sender) {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        require(_protocolFeeBps <= 1000, "Fee cannot exceed 10%"); // Max 10% for safety

        s_feeRecipient = _feeRecipient;
        s_protocolFeeBps = _protocolFeeBps;
        s_nextIntentId = 1; // Start intent IDs from 1
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Internal function to check a single condition against the current chain state.
    /// @param _condition The Condition struct to check.
    /// @return True if the condition is met, false otherwise.
    function _checkCondition(
        Condition memory _condition
    ) internal view returns (bool) {
        uint256 currentValue;

        if (_condition.conditionType == ConditionType.ERC20_BALANCE) {
            require(_condition.targetAddress != address(0), "ERC20 token address cannot be zero");
            currentValue = IERC20(_condition.targetAddress).balanceOf(_condition.subjectAddress);
        } else if (_condition.conditionType == ConditionType.ERC20_ALLOWANCE) {
            require(_condition.targetAddress != address(0), "ERC20 token address cannot be zero");
            currentValue = IERC20(_condition.targetAddress).allowance(
                _condition.subjectAddress,
                _condition.secondaryAddress
            );
        } else if (_condition.conditionType == ConditionType.ETH_BALANCE) {
            currentValue = _condition.subjectAddress.balance;
        } else if (_condition.conditionType == ConditionType.CONTRACT_CALL_BOOLEAN) {
            require(_condition.targetAddress != address(0), "Target contract address cannot be zero");
            (bool success, bytes memory returndata) =
                _condition.targetAddress.staticcall(_condition.callData);
            require(success, "Contract call for condition failed");
            require(returndata.length == 32, "Contract call must return a single boolean"); // Solidity bools are 32 bytes when encoded
            bool result = abi.decode(returndata, (bool));
            return result == _condition.value == 1; // Assuming value 1 for true, 0 for false
        } else {
            revert("Invalid condition type");
        }

        return _evaluateComparison(currentValue, _condition.value, _condition.operator);
    }

    /// @dev Internal function to evaluate a comparison between two values.
    /// @param _current The current value from the chain state.
    /// @param _expected The expected value from the condition.
    /// @param _operator The comparison operator.
    /// @return True if the comparison holds, false otherwise.
    function _evaluateComparison(
        uint256 _current,
        uint256 _expected,
        ComparisonOperator _operator
    ) internal pure returns (bool) {
        if (_operator == ComparisonOperator.EQ) return _current == _expected;
        if (_operator == ComparisonOperator.NE) return _current != _expected;
        if (_operator == ComparisonOperator.GT) return _current > _expected;
        if (_operator == ComparisonOperator.LT) return _current < _expected;
        if (_operator == ComparisonOperator.GTE) return _current >= _expected;
        if (_operator == ComparisonOperator.LTE) return _current <= _expected;
        revert("Invalid comparison operator");
    }

    /// @dev Internal function to update a solver's reputation, clamped within min/max bounds.
    /// @param _solverAddress The address of the solver.
    /// @param _delta The amount to change the reputation by (positive or negative).
    function _updateSolverReputation(address _solverAddress, int256 _delta) internal {
        SolverData storage solver = s_solverData[_solverAddress];
        int256 oldReputation = solver.reputationScore;
        
        solver.reputationScore = solver.reputationScore.add(_delta);
        if (solver.reputationScore < MIN_REPUTATION_SCORE) {
            solver.reputationScore = MIN_REPUTATION_SCORE;
        }
        if (solver.reputationScore > MAX_REPUTATION_SCORE) {
            solver.reputationScore = MAX_REPUTATION_SCORE;
        }

        emit SolverReputationUpdated(_solverAddress, oldReputation, solver.reputationScore);
    }

    /// @dev Internal function to change an intent's status and emit an event.
    /// @param _intentId The ID of the intent.
    /// @param _newStatus The new status for the intent.
    function _updateIntentStatus(uint256 _intentId, IntentStatus _newStatus) internal {
        Intent storage intent = s_intents[_intentId];
        IntentStatus oldStatus = intent.status;
        intent.status = _newStatus;
        emit IntentStatusUpdated(_intentId, oldStatus, _newStatus);
    }

    /*///////////////////////////////////////////////////////////////
                            INTENT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows a user to post a new intent with specified conditions and bounty.
    /// @dev The user must either send ETH with the transaction (for ETH bounty)
    ///      or approve the contract to pull ERC20 tokens (for ERC20 bounty) before calling this.
    /// @param _intentData Struct containing metadata, expiration, solver bond, pre/post conditions.
    /// @param _bountyToken The address of the bounty token (address(0) for native ETH).
    /// @param _bountyAmount The amount of bounty for the solver.
    /// @return The ID of the newly created intent.
    function createIntent(
        IntentData calldata _intentData,
        address _bountyToken,
        uint256 _bountyAmount
    ) public payable returns (uint256) {
        require(_intentData.expiration > block.timestamp, "Expiration must be in the future");
        require(_bountyAmount > 0, "Bounty must be greater than zero");
        require(_intentData.solverBondRequired >= MIN_SOLVER_STAKE, "Solver bond must meet minimum stake");

        if (_bountyToken == address(0)) {
            require(msg.value == _bountyAmount, "ETH bounty amount mismatch");
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20 bounty");
            IERC20(_bountyToken).safeTransferFrom(msg.sender, address(this), _bountyAmount);
        }

        uint256 newIntentId = s_nextIntentId++;
        s_intents[newIntentId] = Intent({
            intentId: newIntentId,
            creator: msg.sender,
            bountyToken: _bountyToken,
            bountyAmount: _bountyAmount,
            expiration: _intentData.expiration,
            solverBondRequired: _intentData.solverBondRequired,
            preConditions: _intentData.preConditions,
            postConditions: _intentData.postConditions,
            status: IntentStatus.Pending,
            solverAddress: address(0),
            fulfillmentHash: 0,
            metadataURI: _intentData.metadataURI,
            challengedBy: 0,
            fulfilledTimestamp: 0
        });

        emit IntentCreated(
            newIntentId,
            msg.sender,
            _bountyToken,
            _bountyAmount,
            _intentData.expiration,
            _intentData.metadataURI
        );
        return newIntentId;
    }

    /// @notice Allows the intent creator to cancel an unfulfilled intent and reclaim their bounty.
    /// @param _intentId The ID of the intent to cancel.
    function cancelIntent(uint256 _intentId) public {
        Intent storage intent = s_intents[_intentId];
        require(intent.creator == msg.sender, "Only creator can cancel intent");
        require(
            intent.status == IntentStatus.Pending || intent.status == IntentStatus.Expired,
            "Intent cannot be canceled in current status"
        );

        _updateIntentStatus(_intentId, IntentStatus.Canceled);

        // Refund bounty
        if (intent.bountyToken == address(0)) {
            (bool sent, ) = intent.creator.call{value: intent.bountyAmount}("");
            require(sent, "Failed to send ETH bounty back");
        } else {
            IERC20(intent.bountyToken).safeTransfer(intent.creator, intent.bountyAmount);
        }

        emit IntentCanceled(_intentId, msg.sender);
    }

    /// @notice Allows the intent creator to update the off-chain metadata URI for their intent.
    /// @param _intentId The ID of the intent to update.
    /// @param _newMetadataURI The new URI for the intent's metadata.
    function updateIntentMetadata(uint256 _intentId, string calldata _newMetadataURI) public {
        Intent storage intent = s_intents[_intentId];
        require(intent.creator == msg.sender, "Only creator can update intent metadata");
        require(
            intent.status == IntentStatus.Pending || intent.status == IntentStatus.Expired,
            "Intent metadata can only be updated if pending or expired"
        );
        intent.metadataURI = _newMetadataURI;
    }

    /// @notice Allows the intent creator to adjust the minimum solver bond required for a specific intent.
    /// @dev Can only be done for pending or expired intents.
    /// @param _intentId The ID of the intent to update.
    /// @param _newBondAmount The new minimum bond amount.
    function setIntentSolverBondRequirement(uint256 _intentId, uint256 _newBondAmount) public {
        Intent storage intent = s_intents[_intentId];
        require(intent.creator == msg.sender, "Only creator can set solver bond requirement");
        require(
            intent.status == IntentStatus.Pending || intent.status == IntentStatus.Expired,
            "Intent solver bond can only be updated if pending or expired"
        );
        require(_newBondAmount >= MIN_SOLVER_STAKE, "Solver bond must meet minimum stake");
        intent.solverBondRequired = _newBondAmount;
    }

    /// @notice Allows the intent creator to extend the expiration of an intent.
    /// @dev Can only be done for pending intents, and the new expiration must be in the future.
    /// @param _intentId The ID of the intent to extend.
    /// @param _newExpiration The new expiration timestamp.
    function extendIntentExpiration(uint256 _intentId, uint64 _newExpiration) public {
        Intent storage intent = s_intents[_intentId];
        require(intent.creator == msg.sender, "Only creator can extend intent expiration");
        require(intent.status == IntentStatus.Pending, "Intent must be pending to extend expiration");
        require(_newExpiration > block.timestamp, "New expiration must be in the future");
        require(_newExpiration > intent.expiration, "New expiration must be later than current expiration");

        intent.expiration = _newExpiration;
    }

    /*///////////////////////////////////////////////////////////////
                            SOLVER MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows an address to register as a solver.
    /// @dev Requires sending at least `MIN_SOLVER_STAKE` ETH or depositing equivalent ERC20 (not implemented for ERC20 yet).
    /// @param _capabilitiesURI URI to off-chain description of solver's capabilities.
    function registerSolver(string calldata _capabilitiesURI) public payable {
        require(!s_solverData[msg.sender].isRegistered, "Solver already registered");
        require(msg.value >= MIN_SOLVER_STAKE, "Insufficient initial stake");

        s_solverData[msg.sender] = SolverData({
            isRegistered: true,
            stake: msg.value,
            lockedStake: 0,
            reputationScore: 0,
            capabilitiesURI: _capabilitiesURI,
            lastActive: block.timestamp,
            unstakeCooldownEnd: 0
        });

        emit SolverRegistered(msg.sender, msg.value, _capabilitiesURI);
    }

    /// @notice Allows a solver to initiate deregistration.
    /// @dev All stake is locked during a cooldown period before it can be withdrawn.
    function deregisterSolver() public {
        SolverData storage solver = s_solverData[msg.sender];
        require(solver.isRegistered, "Solver not registered");
        require(solver.lockedStake == 0, "Cannot deregister with locked stake"); // Cannot have locked stake

        // Set cooldown and mark for deregistration
        solver.isRegistered = false; // Mark as unregistered, but funds are still held
        solver.unstakeCooldownEnd = uint64(block.timestamp) + UNSTAKE_COOLDOWN;
        solver.lockedStake = solver.stake; // Lock all remaining stake

        emit SolverDeregistered(msg.sender);
    }

    /// @notice Allows a solver to stake additional funds.
    /// @dev Funds are added to the solver's total stake.
    /// @param _amount The amount of ETH to stake.
    function stakeSolverBond(uint256 _amount) public payable {
        SolverData storage solver = s_solverData[msg.sender];
        require(solver.isRegistered, "Solver not registered");
        require(msg.value == _amount, "ETH amount mismatch");
        require(_amount > 0, "Stake amount must be positive");

        solver.stake = solver.stake.add(_amount);
        emit SolverStaked(msg.sender, _amount);
    }

    /// @notice Allows a solver to unstake a portion of their bond after cooldown.
    /// @dev Can only unstake after `UNSTAKE_COOLDOWN` if deregistered, or if not locked.
    /// @param _amount The amount to unstake.
    function unstakeSolverBond(uint256 _amount) public {
        SolverData storage solver = s_solverData[msg.sender];
        require(!solver.isRegistered, "Solver must be deregistered to unstake all bond"); // Can only full unstake if deregistered
        require(solver.unstakeCooldownEnd <= block.timestamp, "Unstake cooldown not over");
        require(_amount <= solver.stake, "Amount exceeds available stake");
        require(solver.stake.sub(_amount) >= MIN_SOLVER_STAKE || _amount == solver.stake, "Remaining stake below minimum"); // Ensure min stake if not full unstake
        
        solver.stake = solver.stake.sub(_amount);
        solver.lockedStake = solver.lockedStake.sub(_amount); // Reduce locked stake as well

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send ETH");

        if (solver.stake == 0) {
             // If all stake is withdrawn after deregistration, reset solver data
            delete s_solverData[msg.sender];
        }

        emit SolverUnstaked(msg.sender, _amount);
    }

    /// @notice Allows a solver to update their off-chain capabilities URI.
    /// @param _newCapabilitiesURI The new URI for the solver's capabilities.
    function updateSolverCapabilities(string calldata _newCapabilitiesURI) public {
        SolverData storage solver = s_solverData[msg.sender];
        require(solver.isRegistered, "Solver not registered");
        solver.capabilitiesURI = _newCapabilitiesURI;
    }

    /*///////////////////////////////////////////////////////////////
                        FULFILLMENT & VERIFICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows a registered solver to submit a claim of fulfillment for an intent.
    /// @dev This function performs on-chain verification of pre-conditions and post-conditions.
    ///      The solver is expected to have executed the necessary actions *before* calling this function.
    /// @param _intentId The ID of the intent to verify and settle.
    function submitAndVerifyFulfillment(uint256 _intentId) public {
        Intent storage intent = s_intents[_intentId];
        SolverData storage solver = s_solverData[msg.sender];

        require(intent.status == IntentStatus.Pending, "Intent not pending");
        require(intent.expiration > block.timestamp, "Intent expired");
        require(solver.isRegistered, "Solver not registered");
        require(solver.stake >= intent.solverBondRequired, "Insufficient solver stake to attempt this intent");

        // 1. Verify Pre-conditions
        for (uint i = 0; i < intent.preConditions.length; i++) {
            require(_checkCondition(intent.preConditions[i]), "Pre-condition not met");
        }

        // 2. Verify Post-conditions
        // The solver is assumed to have made the state changes *before* calling this.
        for (uint i = 0; i < intent.postConditions.length; i++) {
            require(_checkCondition(intent.postConditions[i]), "Post-condition not met");
        }

        // If all conditions pass:
        _updateIntentStatus(_intentId, IntentStatus.Fulfilled);
        intent.solverAddress = msg.sender;
        intent.fulfillmentHash = bytes32(tx.hash); // Hash of this transaction which verifies the fulfillment
        intent.fulfilledTimestamp = uint64(block.timestamp);

        // Calculate and transfer bounty, deducting protocol fee
        uint256 protocolFee = (intent.bountyAmount * s_protocolFeeBps) / 10000;
        uint256 solverReward = intent.bountyAmount.sub(protocolFee);

        if (intent.bountyToken == address(0)) { // ETH bounty
            (bool sentSolver, ) = msg.sender.call{value: solverReward}("");
            require(sentSolver, "Failed to send ETH to solver");
            (bool sentFee, ) = s_feeRecipient.call{value: protocolFee}("");
            require(sentFee, "Failed to send ETH to fee recipient");
        } else { // ERC20 bounty
            IERC20(intent.bountyToken).safeTransfer(msg.sender, solverReward);
            IERC20(intent.bountyToken).safeTransfer(s_feeRecipient, protocolFee);
        }

        // Update solver reputation (increase for success)
        _updateSolverReputation(msg.sender, REPUTATION_SUCCESS_BONUS);
        solver.lastActive = uint64(block.timestamp);

        emit IntentFulfilled(_intentId, msg.sender, solverReward, uint64(block.timestamp));
    }

    /*///////////////////////////////////////////////////////////////
                            REPUTATION & SLASHING
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows any participant to challenge a fulfilled intent.
    /// @dev Challenger must stake a bond. If successful, challenger is rewarded. If unsuccessful, bond is slashed.
    /// @param _intentId The ID of the fulfilled intent to challenge.
    function challengeFulfillment(uint256 _intentId) public payable {
        Intent storage intent = s_intents[_intentId];
        require(intent.status == IntentStatus.Fulfilled, "Intent not fulfilled");
        require(intent.fulfilledTimestamp + CHALLENGE_PERIOD > block.timestamp, "Challenge period expired");
        require(msg.value >= intent.solverBondRequired.div(2), "Insufficient challenge bond"); // Challenger stakes half the solver bond

        uint256 challengeBondId = s_nextIntentId++; // Use a new intentId for the challenge bond tracking
        s_intents[challengeBondId] = Intent({ // Represents the challenge bond
            intentId: challengeBondId,
            creator: msg.sender, // Challenger is creator of this 'challenge bond' intent
            bountyToken: address(0), // ETH for challenge bond
            bountyAmount: msg.value,
            expiration: uint64(block.timestamp) + CHALLENGE_PERIOD, // Challenge bond expires after resolution
            solverBondRequired: 0, // Not applicable
            preConditions: new Condition[](0),
            postConditions: new Condition[](0),
            status: IntentStatus.Pending, // Pending resolution
            solverAddress: address(0),
            fulfillmentHash: 0,
            metadataURI: "Challenge bond for intent",
            challengedBy: _intentId, // Link to the challenged intent
            fulfilledTimestamp: 0
        });

        intent.challengedBy = challengeBondId; // Mark original intent as challenged
        _updateIntentStatus(_intentId, IntentStatus.Challenged);

        emit FulfillmentChallenged(_intentId, msg.sender, msg.value);
    }

    /// @notice The contract owner or operator resolves a challenge.
    /// @dev If solver is guilty, their bond is slashed, challenger is rewarded. If not guilty, challenger's bond is slashed.
    /// @param _intentId The ID of the challenged intent.
    /// @param _isSolverGuilty True if the solver failed to meet post-conditions, false otherwise.
    function resolveChallenge(uint256 _intentId, bool _isSolverGuilty) public onlyOperator {
        Intent storage intent = s_intents[_intentId];
        require(intent.status == IntentStatus.Challenged, "Intent is not challenged");
        require(intent.challengedBy != 0, "No active challenge for this intent");

        Intent storage challengeBond = s_intents[intent.challengedBy]; // Retrieve the challenge bond intent
        address challenger = challengeBond.creator;
        address solver = intent.solverAddress;

        uint256 solverPenalty = 0;
        uint256 challengerPenalty = 0;
        uint256 challengerReward = 0;
        uint256 originalSolverBond = s_intents[_intentId].solverBondRequired; // For calculating penalty

        if (_isSolverGuilty) {
            // Solver is guilty: Slash solver's bond, reward challenger, update reputations
            solverPenalty = originalSolverBond.div(2); // Slash 50% of original required bond
            challengerReward = challengeBond.bountyAmount.add(solverPenalty); // Challenger gets their bond back + solver penalty

            SolverData storage solverData = s_solverData[solver];
            require(solverData.stake >= solverPenalty, "Solver does not have enough stake to cover penalty");
            solverData.stake = solverData.stake.sub(solverPenalty);
            _updateSolverReputation(solver, REPUTATION_FAILURE_PENALTY);

            // Transfer funds to challenger
            (bool sent, ) = challenger.call{value: challengerReward}("");
            require(sent, "Failed to send reward to challenger");

            _updateSolverReputation(challenger, REPUTATION_CHALLENGE_WIN_BONUS); // Challenger gets reputation
            _updateIntentStatus(_intentId, IntentStatus.Failed); // Original intent failed
        } else {
            // Solver is innocent: Slash challenger's bond, release solver's bond/reputation
            challengerPenalty = challengeBond.bountyAmount; // Challenger loses their entire bond
            solverPenalty = 0; // Solver is not penalized

            // Transfer challenger's bond to fee recipient or treasury
            (bool sent, ) = s_feeRecipient.call{value: challengerPenalty}("");
            require(sent, "Failed to send challenger penalty to fee recipient");

            _updateSolverReputation(challenger, REPUTATION_CHALLENGE_LOSE_PENALTY); // Challenger loses reputation
            _updateIntentStatus(_intentId, IntentStatus.Fulfilled); // Revert original intent to fulfilled
        }

        // Clean up challenge bond and original intent's challengedBy flag
        _updateIntentStatus(challengeBond.intentId, IntentStatus.Fulfilled); // Mark challenge bond as resolved
        delete s_intents[challengeBond.intentId]; // Remove challenge bond from storage
        intent.challengedBy = 0;

        emit ChallengeResolved(_intentId, challenger, _isSolverGuilty);
        emit SolverPenalized(solver, solverPenalty, _isSolverGuilty ? "Guilty of failed fulfillment" : "N/A");
    }

    /// @notice Allows the owner to directly penalize a solver.
    /// @dev This can be used for off-chain infractions or governance decisions.
    /// @param _solver The address of the solver to penalize.
    /// @param _penaltyAmount The amount of ETH to slash from their stake.
    function penalizeSolver(address _solver, uint256 _penaltyAmount) public onlyOwner {
        SolverData storage solver = s_solverData[_solver];
        require(solver.isRegistered, "Solver not registered");
        require(_penaltyAmount > 0, "Penalty amount must be positive");
        require(solver.stake >= _penaltyAmount, "Penalty exceeds solver's stake");

        solver.stake = solver.stake.sub(_penaltyAmount);
        _updateSolverReputation(_solver, REPUTATION_FAILURE_PENALTY);

        // Transfer penalized funds to the fee recipient
        (bool sent, ) = s_feeRecipient.call{value: _penaltyAmount}("");
        require(sent, "Failed to send penalized funds to fee recipient");

        emit SolverPenalized(_solver, _penaltyAmount, "Owner enforced penalty");
    }

    /// @notice Allows the owner or fee recipient to withdraw collected protocol fees for a specific token or ETH.
    /// @param _token The address of the token to withdraw (address(0) for ETH).
    /// @param _amount The amount to withdraw.
    function withdrawProtocolFees(address _token, uint256 _amount) public {
        require(msg.sender == owner() || msg.sender == s_feeRecipient, "Only owner or fee recipient can withdraw fees");
        require(_amount > 0, "Withdrawal amount must be positive");

        if (_token == address(0)) { // ETH fees
            require(address(this).balance >= _amount, "Insufficient ETH balance for withdrawal");
            (bool sent, ) = s_feeRecipient.call{value: _amount}("");
            require(sent, "Failed to send ETH fees");
        } else { // ERC20 token fees
            IERC20(_token).safeTransfer(s_feeRecipient, _amount);
        }

        emit FeesWithdrawn(s_feeRecipient, _token, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            CONFIGURATION & ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Grants or revokes operator roles.
    /// @dev Operators can perform certain administrative tasks (e.g., resolving challenges).
    /// @param _operator The address to set as operator.
    /// @param _status True to grant, false to revoke.
    function setOperator(address _operator, bool _status) public onlyOwner {
        s_operators[_operator] = _status;
    }

    /// @notice Sets the address to collect protocol fees.
    /// @param _newRecipient The new address for fee collection.
    function setFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "Invalid fee recipient address");
        s_feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /// @notice Sets the protocol fee percentage.
    /// @param _newFeeBps The new fee percentage in basis points (e.g., 100 = 1%).
    function setProtocolFee(uint16 _newFeeBps) public onlyOwner {
        require(_newFeeBps <= 1000, "Fee cannot exceed 10%"); // Max 10%
        s_protocolFeeBps = _newFeeBps;
        emit ProtocolFeeUpdated(_newFeeBps);
    }

    /*///////////////////////////////////////////////////////////////
                            QUERY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves all details of a specific intent.
    /// @param _intentId The ID of the intent.
    /// @return The Intent struct containing all its data.
    function getIntent(uint256 _intentId) public view returns (Intent memory) {
        return s_intents[_intentId];
    }

    /// @notice Retrieves all registration and reputation details for a specific solver.
    /// @param _solverAddress The address of the solver.
    /// @return The SolverData struct containing all its data.
    function getSolver(address _solverAddress) public view returns (SolverData memory) {
        return s_solverData[_solverAddress];
    }

    /// @notice Returns the current staked amount of a solver.
    /// @param _solverAddress The address of the solver.
    /// @return The total staked amount.
    function getSolverStake(address _solverAddress) public view returns (uint256) {
        return s_solverData[_solverAddress].stake;
    }

    /// @notice Checks if an address is currently registered as a solver.
    /// @param _solverAddress The address to check.
    /// @return True if registered, false otherwise.
    function isSolverRegistered(address _solverAddress) public view returns (bool) {
        return s_solverData[_solverAddress].isRegistered;
    }

    /// @notice Returns the current next available intent ID.
    function getNextIntentId() public view returns (uint256) {
        return s_nextIntentId;
    }
}
```