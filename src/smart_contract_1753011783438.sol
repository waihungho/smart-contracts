The **ChronoShift Protocol** is a highly advanced, self-evolving decentralized autonomous organization (DAO) designed to manage and adapt a complex protocol ecosystem on the blockchain. It goes beyond traditional DAOs by enabling dynamic parameter adjustments, seamless integration of new functional modules, and self-amendment of its own governance rules. All these adaptations are driven by time-weighted community consensus, creating a truly adaptive and resilient decentralized system that can evolve without central authority intervention post-initialization.

**Core Vision:**
To establish a protocol foundation that is inherently capable of continuous, autonomous evolution. By decentralizing not just decision-making but also the very rules and functionalities of the protocol, ChronoShift aims to build a resilient, future-proof, and community-driven ecosystem.

---

**Outline:**

*   **I. Contract Description & Core Vision:** Overview of the ChronoShift Protocol's purpose and innovative design.
*   **II. Interfaces & Libraries:** External contracts and utility libraries utilized.
*   **III. State Variables & Data Structures:** Definition of enums, structs, and mappings storing the protocol's state.
*   **IV. Events:** Actions that emit logs for off-chain monitoring.
*   **V. Errors:** Custom error types for clearer feedback.
*   **VI. Modifiers:** Reusable access control and state checks.
*   **VII. Constructor & Initial Protocol Setup:** Functions for initial deployment and decentralization.
*   **VIII. ChronoToken (CHR) & Staking Management:** Logic for staking governance tokens, calculating voting power, and delegation.
*   **IX. Core Governance: Proposals, Voting, Execution:** Mechanisms for submitting, voting on, and executing various types of proposals.
*   **X. Dynamic Module Integration & Management:** Advanced functionality to register, configure, and interact with external smart contract modules.
*   **XI. Adaptive Parameter & Governance Rule Adjustment:** Functions to dynamically change core protocol parameters and governance rules.
*   **XII. Treasury & Dynamic Resource Allocation:** Management of the protocol's funds and their allocation.
*   **XIII. Utility & View Functions:** Helper functions for querying protocol state.

---

**Function Summary (29 Functions):**

**I. Protocol Initialization & Control**
1.  `constructor(address _chronoToken, address _initialFeeRecipient)`: Initializes the contract, sets the ChronoToken address and initial fee recipient. Starts the protocol in a paused state.
2.  `initiateProtocol(uint256 _initialVotingPeriod, uint256 _initialQuorumPercentage, uint256 _initialApprovalThresholdPercentage, uint256 _initialStakeLockupDuration, uint256 _initialVotingPowerDecayRate)`: Finalizes initial setup, sets critical governance parameters, unpauses the protocol, and relinquishes `Ownable` ownership to the contract itself, fully decentralizing control.
3.  `pauseProtocol()`: Allows governance (the contract itself via a successful proposal) to pause protocol functions in an emergency.
4.  `unpauseProtocol()`: Allows governance to unpause protocol functions.
5.  `setProtocolFeeRecipient(address _newRecipient)`: Allows governance to change the address receiving protocol fees.

**II. ChronoToken (CHR) & Staking Management**
6.  `stake(uint256 _amount)`: Users stake CHR tokens to gain voting power, starting their time-weighted contribution.
7.  `unstake()`: Users unstake their CHR tokens, receiving their original staked amount. This removes their voting power.
8.  `claimStakedRewards()`: Allows stakers to claim rewards for active and sustained participation in the protocol. (Placeholder for advanced reward distribution logic).
9.  `getVotingPower(address _staker)`: Calculates the current time-weighted voting power of a staker based on their staked amount and duration, with power decaying over time post-lockup. This represents their individual token's power.
10. `getEffectiveStake(address _staker)`: Returns the original amount of CHR tokens staked by a given address.
11. `delegateVote(address _delegatee)`: Allows a staker to delegate their voting power to another address. After delegation, the delegator cannot vote directly; their power is added to the delegatee's total.

**III. Governance: Proposals, Voting, Execution**
12. `submitParameterProposal(string calldata _paramName, uint256 _newValue, string calldata _description)`: Submits a proposal to change an internal protocol parameter (e.g., fee rates, stake duration).
13. `submitModuleIntegrationProposal(address _moduleAddress, string calldata _moduleType, string calldata _moduleName, string calldata _description)`: Submits a proposal to integrate a new external smart contract module into the ChronoShift ecosystem.
14. `submitGovernanceRuleProposal(string calldata _ruleName, uint256 _newValue, string calldata _description)`: Submits a proposal to change the protocol's governance rules themselves (e.g., quorum requirements, approval thresholds).
15. `submitFundAllocationProposal(address _recipient, uint256 _amount, string calldata _description)`: Submits a proposal to allocate funds from the protocol's treasury to a specified recipient.
16. `vote(uint256 _proposalId, bool _support)`: Casts a vote (for or against) on an active proposal using the voter's combined voting power (own stake + delegated power).
17. `executeProposal(uint256 _proposalId)`: Executes a proposal that has successfully passed its voting period and met all quorum and approval criteria.
18. `cancelProposal(uint256 _proposalId)`: Allows the original proposer to cancel their proposal under specific conditions (e.g., before voting starts, or if it failed).
19. `getProposalState(uint256 _proposalId)`: Returns the current state of a proposal (Pending, Active, Succeeded, Failed, Executed, Canceled).

**IV. Dynamic Module Integration & Management**
20. `registerModule(address _moduleAddress, string calldata _moduleType, string calldata _moduleName)`: Internal function called automatically upon successful execution of a `ModuleIntegrationProposal` to officially register a new module.
21. `deregisterModule(bytes32 _moduleId)`: Allows governance to deactivate or remove a registered module from the protocol's active list.
22. `getModuleAddress(bytes32 _moduleId)`: Returns the on-chain address of a registered module given its unique ID.
23. `setModuleConfiguration(bytes32 _moduleId, bytes calldata _callData)`: Allows governance to call a specific `configure` type function on a registered module, enabling dynamic setup or updates of external components.
24. `callModuleFunction(bytes32 _moduleId, bytes calldata _callData)`: A powerful, generic function allowing the ChronoShift protocol (via governance) to call *any* function on *any* registered module, enabling deep and flexible inter-protocol communication.

**V. Adaptive Parameter & Governance Rule Adjustment**
25. `getProtocolParameter(string calldata _paramName)`: Retrieves the current value of a specific protocol parameter.
26. `updateProtocolParameter(string memory _paramName, uint256 _newValue)`: Internal function called upon successful execution of a `ParameterChange` or `GovernanceRuleChange` proposal to update a protocol parameter's value.

**VI. Treasury & Dynamic Resource Allocation**
27. `getCurrentTreasuryBalance()`: Returns the current ETH balance held by the ChronoShift Protocol's treasury.
28. `receiveFunds()`: A payable fallback function allowing anyone to send ETH to the protocol's treasury.

**VII. Utility & View Functions**
29. `getAdjustedQuorum()`: Calculates the current quorum requirement based on the total staked tokens and the dynamically set `QUORUM_PERCENTAGE` parameter.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import necessary OpenZeppelin contracts for common patterns and security
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For the ChronoToken
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // To prevent re-entrancy attacks
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial setup before decentralization

// I. Contract Description & Core Vision
// ChronoShift Protocol is a self-evolving decentralized autonomous organization (DAO)
// designed to manage and adapt a complex protocol ecosystem. It enables dynamic
// parameter adjustments, seamless integration of new functional modules, and
// self-amendment of its own governance rules, all driven by time-weighted
// community consensus. It aims to create a truly adaptive and resilient
// decentralized system that can evolve without central authority intervention
// post-initialization.

// II. Interfaces & Libraries
/// @title IModule
/// @notice Defines a standard interface for modules that can be integrated into the ChronoShift Protocol.
interface IModule {
    /// @notice A common function for modules to receive configuration data from the protocol.
    /// @param _data Encoded configuration data specific to the module.
    function configure(bytes calldata _data) external;
    // Future expansion: Could include `upgradeModule`, `emergencyPause`, etc.
}

/// @title ChronoShiftProtocol
/// @notice The main contract for the ChronoShift Protocol, managing governance, staking, and module orchestration.
contract ChronoShiftProtocol is Ownable, ReentrancyGuard {

    // III. State Variables & Data Structures

    IERC20 public immutable CHR_TOKEN; // The immutable address of the governance token (ChronoToken)
    address public protocolFeeRecipient; // Address to receive any protocol-level fees
    bool public paused; // Global pause switch for emergency situations

    // Protocol Parameters: Dynamically adjustable via governance proposals
    mapping(string => uint256) public protocolParameters;

    // Staking Management
    struct Staker {
        uint256 amount;            // The total amount of CHR tokens staked by this address
        uint64 lastStakeTime;      // Unix timestamp when the tokens were last staked or increased
        address delegatedTo;       // The address to which this staker has delegated their voting power
        uint256 lastClaimBlock;    // Block number of last reward claim (for potential future reward logic)
    }
    mapping(address => Staker) public stakers; // Maps staker address to their Staker struct
    mapping(address => uint256) public delegatedVotingPower; // Maps delegatee address to sum of power delegated to them
    uint256 public totalStakedTokens; // Total CHR tokens currently staked in the protocol

    // Governance System (Proposals, Voting)
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }
    enum ProposalType { ParameterChange, ModuleIntegration, GovernanceRuleChange, FundAllocation }

    struct Proposal {
        uint256 id;                   // Unique identifier for the proposal
        address proposer;             // Address that submitted the proposal
        ProposalType proposalType;    // Type of change proposed (e.g., parameter, module)
        bytes data;                   // Encoded data specific to the proposal type for execution
        string description;           // Human-readable description of the proposal
        uint64 startBlock;            // Block number when voting period begins
        uint64 endBlock;              // Block number when voting period ends
        uint256 votesFor;             // Accumulated 'for' votes
        uint256 votesAgainst;         // Accumulated 'against' votes
        uint256 totalVotingPowerAtStart; // Snapshot of total staked tokens at proposal creation (for quorum base)
        uint256 quorumRequired;       // Snapshot of calculated quorum amount at proposal creation
        uint256 approvalThresholdRequired; // Snapshot of approval percentage at proposal creation (e.g., 5000 for 50%)
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;                // True if the proposal has been successfully executed
        bool canceled;                // True if the proposal has been canceled
    }

    uint256 public nextProposalId; // Counter for the next proposal ID
    mapping(uint256 => Proposal) public proposals; // Maps proposal ID to its Proposal struct

    // Module Management
    struct Module {
        address addr;      // The on-chain address of the module contract
        string moduleType; // Categorization of the module (e.g., "Lending", "Oracle", "NFTMarket")
        string name;       // A unique human-readable name for the module
        bool isActive;     // True if the module is currently active and usable by the protocol
        uint256 version;   // Version number of the module for upgrades/tracking
    }
    mapping(bytes32 => Module) public modules; // Maps module ID (keccak256(moduleName)) to its Module struct
    mapping(string => bytes32) public moduleNameToId; // Maps module name to its ID for quick lookup
    bytes32[] public activeModuleIds; // Array of active module IDs for easy iteration or discovery

    // IV. Events
    event ProtocolInitiated(address indexed _initialOwner, address indexed _chronoToken);
    event ProtocolPaused(address indexed _by);
    event ProtocolUnpaused(address indexed _by);
    event FeeRecipientUpdated(address indexed _oldRecipient, address indexed _newRecipient);

    event TokensStaked(address indexed _staker, uint256 _amount, uint256 _calculatedPower);
    event TokensUnstaked(address indexed _staker, uint256 _amount);
    event StakedRewardsClaimed(address indexed _staker, uint256 _rewards);
    event VoteDelegated(address indexed _delegator, address indexed _delegatee);

    event ProposalSubmitted(uint256 indexed _proposalId, address indexed _proposer, ProposalType _type, string _description);
    event VoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support, uint256 _votingPowerUsed);
    event ProposalExecuted(uint256 indexed _proposalId);
    event ProposalCanceled(uint256 indexed _proposalId);
    event ParameterChanged(string _paramName, uint256 _oldValue, uint256 _newValue);

    event ModuleRegistered(bytes32 indexed _moduleId, address indexed _moduleAddress, string _moduleType, string _moduleName, uint256 _version);
    event ModuleDeregistered(bytes32 indexed _moduleId);
    event ModuleConfigurationSet(bytes32 indexed _moduleId, bytes _callData);
    event ModuleFunctionCalled(bytes32 indexed _moduleId, bytes _callData);

    event FundsAllocated(uint256 indexed _proposalId, address indexed _recipient, uint256 _amount);
    event FundsReceived(address indexed _sender, uint256 _amount);

    // V. Errors
    error ProtocolNotInitiated();
    error ProtocolAlreadyInitiated();
    error NotGovernanceExecutor();
    error ProtocolPausedError();
    error InsufficientStake();
    error AlreadyStaked(); // Specific error if trying to stake again without unstaking
    error NoStakeToUnstake();
    error CannotDelegateToSelf();
    error DelegationLoop(); // Simplified, prevents direct A->B->A
    error HasDelegatedVote(); // If a user tries to vote directly after delegating their power
    error InsufficientVotingPower();

    error ProposalNotFound();
    error ProposalNotEnded();
    error ProposalNotActive(); // Proposal is pending or already ended
    error ProposalAlreadyVoted();
    error ProposalAlreadyExecuted();
    error ProposalCanceled();
    error ProposalNotProposer();
    error InvalidProposalState(); // General error for proposals in wrong state
    error ProposalNotSucceeded(); // Specific for execution phase

    error InvalidParameterName(); // Not currently used, but good for future validation
    error InvalidModuleAddress(); // For address(0) or other invalid module addresses
    error ModuleAlreadyRegistered();
    error ModuleNotRegistered();
    error ModuleCallFailed(); // Generic error for external calls to modules failing

    error InsufficientTreasuryBalance();

    // VI. Modifiers
    modifier whenNotPaused() {
        if (paused) revert ProtocolPausedError();
        _;
    }

    /// @notice Ensures the caller is the contract itself, acting as the decentralized governance executor.
    /// @dev This modifier is used after `initiateProtocol` has transferred `Ownable` ownership to `address(this)`.
    modifier onlyGovernanceExecutor() {
        if (msg.sender != address(this)) revert NotGovernanceExecutor();
        _;
    }

    // VII. Constructor & Initial Protocol Setup
    /// @notice Constructor for the ChronoShiftProtocol contract.
    /// @dev Sets the ChronoToken address and an initial fee recipient. The protocol starts paused.
    /// @param _chronoToken The address of the ERC20 token used for staking and governance.
    /// @param _initialFeeRecipient The initial address to receive any protocol fees.
    constructor(address _chronoToken, address _initialFeeRecipient) Ownable(msg.sender) {
        CHR_TOKEN = IERC20(_chronoToken);
        protocolFeeRecipient = _initialFeeRecipient;
        paused = true; // Protocol starts paused, must be initiated by the initial owner
        nextProposalId = 1;
    }

    /// @notice Finalizes initial setup, sets core governance parameters, unpauses, and decentralizes control.
    /// @dev This function can only be called once by the initial `Ownable` owner.
    /// It relinquishes ownership to the contract itself, meaning all subsequent admin actions
    /// must be approved via the governance process.
    /// @param _initialVotingPeriod The default duration for proposals in blocks.
    /// @param _initialQuorumPercentage The percentage (in basis points, e.g., 4000 for 40%) of total voting power required for a proposal to pass.
    /// @param _initialApprovalThresholdPercentage The percentage (in basis points, e.g., 5000 for 50%) of 'for' votes needed (of total cast votes) for a proposal to pass.
    /// @param _initialStakeLockupDuration The duration in seconds tokens are "actively" providing full voting power post-stake.
    /// @param _initialVotingPowerDecayRate The rate (in basis points per day) at which voting power decays after `STAKE_LOCKUP_DURATION`.
    function initiateProtocol(
        uint256 _initialVotingPeriod,
        uint256 _initialQuorumPercentage,
        uint256 _initialApprovalThresholdPercentage,
        uint256 _initialStakeLockupDuration,
        uint256 _initialVotingPowerDecayRate
    ) external onlyOwner {
        if (!paused) revert ProtocolAlreadyInitiated(); // Ensure not already initiated

        // Set initial dynamic governance parameters
        protocolParameters["PROPOSAL_VOTING_PERIOD"] = _initialVotingPeriod;
        protocolParameters["QUORUM_PERCENTAGE"] = _initialQuorumPercentage;
        protocolParameters["APPROVAL_THRESHOLD_PERCENTAGE"] = _initialApprovalThresholdPercentage;
        protocolParameters["STAKE_LOCKUP_DURATION"] = _initialStakeLockupDuration;
        protocolParameters["VOTING_POWER_DECAY_RATE"] = _initialVotingPowerDecayRate;
        protocolParameters["GOVERNANCE_REWARD_PER_VOTE"] = 1e16; // Example: 0.01 CHR per active vote (adjust based on token decimals)

        paused = false; // Unpause the protocol
        _transferOwnership(address(this)); // Relinquish ownership to the contract itself (decentralize)
        emit ProtocolInitiated(msg.sender, address(CHR_TOKEN));
    }

    /// @notice Allows governance to pause critical protocol functions in an emergency.
    /// @dev Callable only by the governance executor (i.e., this contract itself, via a successful proposal).
    function pauseProtocol() external onlyGovernanceExecutor whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /// @notice Allows governance to unpause critical protocol functions.
    /// @dev Callable only by the governance executor.
    function unpauseProtocol() external onlyGovernanceExecutor {
        if (!paused) revert ProtocolNotInitiated(); // Should only be callable if paused
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /// @notice Allows governance to change the address designated to receive protocol fees.
    /// @dev Callable only by the governance executor.
    /// @param _newRecipient The new address that will receive protocol fees.
    function setProtocolFeeRecipient(address _newRecipient) external onlyGovernanceExecutor {
        address oldRecipient = protocolFeeRecipient;
        protocolFeeRecipient = _newRecipient;
        emit FeeRecipientUpdated(oldRecipient, _newRecipient);
    }

    // VIII. ChronoToken (CHR) & Staking Management

    /// @notice Users stake CHR tokens to gain voting power within the ChronoShift Protocol.
    /// @dev Tokens are transferred from the staker to this contract. A staker can only have one active stake for simplicity of decay calculation.
    /// @param _amount The amount of CHR tokens to stake.
    function stake(uint256 _amount) external whenNotPaused nonReentrant {
        if (_amount == 0) revert InsufficientStake();
        if (stakers[msg.sender].amount > 0) revert AlreadyStaked(); // Prevents multiple stakes by same address without unstaking first

        CHR_TOKEN.transferFrom(msg.sender, address(this), _amount); // Pull tokens from user
        stakers[msg.sender].amount = _amount;
        stakers[msg.sender].lastStakeTime = uint64(block.timestamp);
        stakers[msg.sender].delegatedTo = msg.sender; // Self-delegate by default
        stakers[msg.sender].lastClaimBlock = uint256(block.number); // Initialize last claim block

        // Update total staked tokens, used for quorum calculation
        totalStakedTokens += _amount;

        // Update delegated power: initially, their own power counts towards their delegated power
        delegatedVotingPower[msg.sender] += getVotingPower(msg.sender);

        emit TokensStaked(msg.sender, _amount, getVotingPower(msg.sender));
    }

    /// @notice Allows users to unstake their CHR tokens.
    /// @dev The original staked amount is returned to the user. This operation removes voting power.
    function unstake() external whenNotPaused nonReentrant {
        Staker storage staker = stakers[msg.sender];
        if (staker.amount == 0) revert NoStakeToUnstake();

        // Transfer back the original staked amount
        CHR_TOKEN.transfer(msg.sender, staker.amount);

        // Adjust delegated voting power before clearing staker data
        // Subtract their own current voting power from their current delegatee
        uint256 currentSelfPower = getVotingPower(msg.sender); // The power this staker currently has
        if (currentSelfPower > 0) { // Only if they actually have voting power right now
            if (delegatedVotingPower[staker.delegatedTo] < currentSelfPower) {
                delegatedVotingPower[staker.delegatedTo] = 0; // Prevent underflow if edge case
            } else {
                delegatedVotingPower[staker.delegatedTo] -= currentSelfPower;
            }
        }

        totalStakedTokens -= staker.amount; // Reduce total staked tokens
        delete stakers[msg.sender]; // Clear the staker's data

        emit TokensUnstaked(msg.sender, staker.amount);
    }

    /// @notice Allows stakers to claim rewards for their active participation in governance.
    /// @dev This is a simplified placeholder. A real implementation would involve more complex
    /// tracking of active participation (e.g., number of votes, proportion of stake over time).
    function claimStakedRewards() external whenNotPaused nonReentrant {
        Staker storage staker = stakers[msg.sender];
        if (staker.amount == 0) revert NoStakeToUnstake();

        // Calculate rewards based on GOVERNANCE_REWARD_PER_VOTE and blocks since last claim
        // This is a simple linear example. More complex systems use "checkpoints" or specific proposal votes.
        uint256 rewardPerBlock = protocolParameters["GOVERNANCE_REWARD_PER_VOTE"];
        uint256 blocksActive = block.number - staker.lastClaimBlock;
        uint256 rewards = (staker.amount * rewardPerBlock * blocksActive) / 1e18; // Scale rewards
        // Ensure rewards are not zero to avoid unnecessary transfers
        if (rewards == 0) return;

        staker.lastClaimBlock = block.number; // Update last claim block
        CHR_TOKEN.transfer(msg.sender, rewards);
        emit StakedRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Calculates the current time-weighted voting power of a specific staker's tokens.
    /// @dev This function calculates the individual power yield by a staker's tokens, not including delegated power.
    /// Voting power decays after an initial lockup duration.
    /// @param _staker The address of the staker.
    /// @return The calculated individual voting power of the staker.
    function getVotingPower(address _staker) public view returns (uint256) {
        Staker storage staker = stakers[_staker];
        if (staker.amount == 0) return 0;

        uint256 lockupDuration = protocolParameters["STAKE_LOCKUP_DURATION"];
        uint256 decayRate = protocolParameters["VOTING_POWER_DECAY_RATE"]; // In basis points per day (e.g., 100 for 1%)

        uint256 currentPower = staker.amount;

        // Apply decay if beyond initial lockup period
        if (block.timestamp > staker.lastStakeTime + lockupDuration) {
            uint256 timeElapsedBeyondLockup = block.timestamp - (staker.lastStakeTime + lockupDuration);
            // Decay amount = (currentPower * timeElapsedBeyondLockup * decayRate) / (1 day in seconds * 10000 bp)
            uint256 decayAmount = (currentPower * timeElapsedBeyondLockup * decayRate) / (1 days * 10000);
            currentPower = currentPower > decayAmount ? currentPower - decayAmount : 0;
        }
        return currentPower;
    }

    /// @notice Returns the raw, original amount of staked tokens for a given address, irrespective of decay.
    /// @param _staker The address of the staker.
    /// @return The raw staked amount.
    function getEffectiveStake(address _staker) public view returns (uint256) {
        return stakers[_staker].amount;
    }

    /// @notice Allows a staker to delegate their voting power to another address.
    /// @dev This transfers the staker's individual voting power to the delegatee.
    /// A staker who has delegated their vote cannot vote directly.
    /// @param _delegatee The address to which voting power will be delegated.
    function delegateVote(address _delegatee) external whenNotPaused {
        if (_delegatee == address(0)) revert InvalidModuleAddress(); // Reusing error, should be more specific
        if (_delegatee == msg.sender) revert CannotDelegateToSelf();

        Staker storage delegator = stakers[msg.sender];
        if (delegator.amount == 0) revert InsufficientStake(); // Must have staked tokens to delegate

        // Prevent immediate delegation loops (e.g., A delegates to B, B tries to delegate back to A)
        // This is a simplified check; complex systems need more robust loop detection.
        if (stakers[_delegatee].delegatedTo == msg.sender) revert DelegationLoop();

        // Get the delegator's current individual voting power
        uint256 delegatorPower = getVotingPower(msg.sender);

        // Adjust power from the old delegatee (if any)
        if (delegator.delegatedTo != address(0)) {
            // Subtract only if the delegator actually had power that was delegated
            if (delegator.delegatedTo != msg.sender && delegatedVotingPower[delegator.delegatedTo] >= delegatorPower) {
                delegatedVotingPower[delegator.delegatedTo] -= delegatorPower;
            }
        }

        // Set the new delegatee
        delegator.delegatedTo = _delegatee;

        // Add the delegator's power to the new delegatee
        delegatedVotingPower[_delegatee] += delegatorPower;

        emit VoteDelegated(msg.sender, _delegatee);
    }

    // IX. Core Governance: Proposals, Voting, Execution

    /// @notice Submits a proposal to change a specific protocol parameter.
    /// @dev Requires the proposer to have active stake.
    /// @param _paramName The string name of the parameter to change (e.g., "PROPOSAL_VOTING_PERIOD").
    /// @param _newValue The new uint256 value for the parameter.
    /// @param _description A human-readable description explaining the proposal's intent.
    /// @return The unique ID of the newly submitted proposal.
    function submitParameterProposal(string calldata _paramName, uint256 _newValue, string calldata _description)
        external whenNotPaused returns (uint256)
    {
        if (stakers[msg.sender].amount == 0) revert InsufficientStake();
        bytes memory data = abi.encode(_paramName, _newValue);
        return _submitProposal(ProposalType.ParameterChange, data, _description);
    }

    /// @notice Submits a proposal to integrate a new functional smart contract module into the protocol.
    /// @dev Requires the proposer to have active stake. The module must not be already registered.
    /// @param _moduleAddress The on-chain address of the new module contract.
    /// @param _moduleType The category or type of the module (e.g., "Lending", "Oracle").
    /// @param _moduleName A unique string name for the module.
    /// @param _description A detailed description of the module and its proposed integration.
    /// @return The unique ID of the newly submitted proposal.
    function submitModuleIntegrationProposal(address _moduleAddress, string calldata _moduleType, string calldata _moduleName, string calldata _description)
        external whenNotPaused returns (uint256)
    {
        if (stakers[msg.sender].amount == 0) revert InsufficientStake();
        if (_moduleAddress == address(0)) revert InvalidModuleAddress();
        if (moduleNameToId[_moduleName] != bytes32(0)) revert ModuleAlreadyRegistered(); // Check if module name is already taken
        bytes memory data = abi.encode(_moduleAddress, _moduleType, _moduleName);
        return _submitProposal(ProposalType.ModuleIntegration, data, _description);
    }

    /// @notice Submits a proposal to change fundamental governance rules of the protocol.
    /// @dev Requires the proposer to have active stake. Semantically distinct but functionally similar to parameter changes.
    /// @param _ruleName The string name of the governance rule to change (e.g., "QUORUM_PERCENTAGE").
    /// @param _newValue The new uint256 value for the rule.
    /// @param _description A detailed description explaining the proposed governance rule change.
    /// @return The unique ID of the newly submitted proposal.
    function submitGovernanceRuleProposal(string calldata _ruleName, uint256 _newValue, string calldata _description)
        external whenNotPaused returns (uint256)
    {
        if (stakers[msg.sender].amount == 0) revert InsufficientStake();
        bytes memory data = abi.encode(_ruleName, _newValue);
        return _submitProposal(ProposalType.GovernanceRuleChange, data, _description);
    }

    /// @notice Submits a proposal to allocate a specific amount of funds from the protocol's treasury.
    /// @dev Requires the proposer to have active stake and for the amount to be greater than zero.
    /// @param _recipient The address to which the funds will be sent.
    /// @param _amount The amount of ETH (in wei) to be allocated.
    /// @param _description A detailed description explaining the purpose of the fund allocation.
    /// @return The unique ID of the newly submitted proposal.
    function submitFundAllocationProposal(address _recipient, uint256 _amount, string calldata _description)
        external whenNotPaused returns (uint256)
    {
        if (stakers[msg.sender].amount == 0) revert InsufficientStake();
        if (_recipient == address(0)) revert InvalidModuleAddress(); // Reusing error for address(0)
        if (_amount == 0) revert InsufficientTreasuryBalance(); // Amount must be positive

        bytes memory data = abi.encode(_recipient, _amount);
        return _submitProposal(ProposalType.FundAllocation, data, _description);
    }

    /// @notice Internal helper function for submitting various types of proposals.
    /// @param _type The type of proposal being submitted.
    /// @param _data Encoded data specific to the proposal's type.
    /// @param _description A human-readable description.
    /// @return The ID of the submitted proposal.
    function _submitProposal(ProposalType _type, bytes memory _data, string calldata _description)
        internal returns (uint256)
    {
        uint256 proposalId = nextProposalId++;
        // Snapshot current protocol state relevant for proposal validation/execution
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: _type,
            data: _data,
            description: _description,
            startBlock: uint64(block.number),
            endBlock: uint64(block.number + protocolParameters["PROPOSAL_VOTING_PERIOD"]),
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtStart: totalStakedTokens, // Snapshot total tokens as base for quorum
            quorumRequired: getAdjustedQuorum(),
            approvalThresholdRequired: protocolParameters["APPROVAL_THRESHOLD_PERCENTAGE"],
            executed: false,
            canceled: false
        });

        emit ProposalSubmitted(proposalId, msg.sender, _type, _description);
        return proposalId;
    }

    /// @notice Allows a user to cast their vote (for or against) on an active proposal.
    /// @dev The voting power used includes the staker's individual power and any power delegated to them.
    /// A user cannot vote if they have delegated their own power to someone else.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote 'for' the proposal, false to vote 'against'.
    function vote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.number <= proposal.startBlock) revert ProposalNotActive(); // Voting hasn't started yet
        if (block.number > proposal.endBlock) revert ProposalEnded(); // Voting period has ended
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted(); // User has already voted
        if (proposal.executed || proposal.canceled) revert InvalidProposalState(); // Proposal cannot be voted on if already executed or canceled

        // Check if the user has delegated their vote away
        if (stakers[msg.sender].amount > 0 && stakers[msg.sender].delegatedTo != msg.sender) {
            revert HasDelegatedVote(); // User has delegated their vote, so they cannot vote directly
        }

        // Calculate the total voting power available to the msg.sender (their own + delegated to them)
        uint256 totalVotingPower = getVotingPower(msg.sender) + delegatedVotingPower[msg.sender];
        if (totalVotingPower == 0) revert InsufficientVotingPower(); // User has no voting power

        if (_support) {
            proposal.votesFor += totalVotingPower;
        } else {
            proposal.votesAgainst += totalVotingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, totalVotingPower);
    }

    /// @notice Executes a proposal that has passed its voting period and met all success criteria.
    /// @dev Can be called by anyone after the voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (block.number <= proposal.endBlock) revert ProposalNotEnded(); // Voting period must be over
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.canceled) revert ProposalCanceled();

        ProposalState state = getProposalState(_proposalId);
        if (state != ProposalState.Succeeded) revert ProposalNotSucceeded(); // Only succeeded proposals can be executed

        proposal.executed = true; // Mark as executed to prevent re-execution

        // Execute actions based on proposal type
        if (proposal.proposalType == ProposalType.ParameterChange || proposal.proposalType == ProposalType.GovernanceRuleChange) {
            (string memory paramName, uint256 newValue) = abi.decode(proposal.data, (string, uint256));
            _updateProtocolParameter(paramName, newValue); // Internal call to update parameter
        } else if (proposal.proposalType == ProposalType.ModuleIntegration) {
            (address moduleAddress, string memory moduleType, string memory moduleName) = abi.decode(proposal.data, (address, string, string));
            _registerModule(moduleAddress, moduleType, moduleName); // Internal call to register module
        } else if (proposal.proposalType == ProposalType.FundAllocation) {
            (address recipient, uint256 amount) = abi.decode(proposal.data, (address, uint256));
            if (address(this).balance < amount) revert InsufficientTreasuryBalance(); // Double check balance
            (bool success,) = recipient.call{value: amount}(""); // Send ETH to recipient
            if (!success) revert ModuleCallFailed(); // Reusing for general external call failure
            emit FundsAllocated(_proposalId, recipient, amount);
        }

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the original proposer to cancel their own proposal under specific conditions.
    /// @dev A proposal can typically be canceled before its voting period starts, or if it has already failed.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.proposer != msg.sender) revert ProposalNotProposer(); // Only the proposer can cancel
        if (proposal.executed || proposal.canceled) revert InvalidProposalState(); // Cannot cancel if already processed

        // Allow cancellation if voting hasn't started, or if it has finished and the proposal failed
        if (block.number < proposal.startBlock || getProposalState(_proposalId) == ProposalState.Failed) {
            proposal.canceled = true;
            emit ProposalCanceled(_proposalId);
        } else {
            revert InvalidProposalState(); // Cannot cancel once active and not failed
        }
    }

    /// @notice Returns the current state of a given proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The current `ProposalState` of the proposal.
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) return ProposalState.Pending; // Non-existent proposal implicitly pending or error

        if (proposal.executed) return ProposalState.Executed;
        if (proposal.canceled) return ProposalState.Canceled;
        if (block.number < proposal.startBlock) return ProposalState.Pending;
        if (block.number <= proposal.endBlock) return ProposalState.Active;

        // Voting period has ended, determine final outcome
        uint256 votesCast = proposal.votesFor + proposal.votesAgainst;

        // Quorum check: total votes cast must meet the quorum percentage of total voting power at proposal start
        if ((votesCast * 10000) < (proposal.totalVotingPowerAtStart * proposal.quorumRequired)) {
            return ProposalState.Failed; // Not enough participation
        }

        // Approval threshold check: 'for' votes must be >= threshold percentage of total cast votes
        if ((proposal.votesFor * 10000) >= (votesCast * proposal.approvalThresholdRequired)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }

    // X. Dynamic Module Integration & Management

    /// @notice Internal function to register a new functional module with the protocol.
    /// @dev This function is designed to be called only by the contract itself upon successful execution
    /// of a `ModuleIntegrationProposal`.
    /// @param _moduleAddress The address of the module contract.
    /// @param _moduleType The category type of the module.
    /// @param _moduleName A unique name for the module.
    function _registerModule(address _moduleAddress, string memory _moduleType, string memory _moduleName) internal onlyGovernanceExecutor {
        bytes32 moduleId = keccak256(abi.encodePacked(_moduleName));
        if (modules[moduleId].addr != address(0)) revert ModuleAlreadyRegistered(); // Ensure module ID is unique

        modules[moduleId] = Module({
            addr: _moduleAddress,
            moduleType: _moduleType,
            name: _moduleName,
            isActive: true, // New modules are active by default
            version: 1 // Initial version for tracking
        });
        moduleNameToId[_moduleName] = moduleId; // Store name-to-ID mapping
        activeModuleIds.push(moduleId); // Add to dynamic array for discovery

        emit ModuleRegistered(moduleId, _moduleAddress, _moduleType, _moduleName, 1);
    }

    /// @notice Allows governance to deregister an existing module, effectively deactivating it.
    /// @dev Callable only by the governance executor. Deregistration makes a module inactive but does not delete its data.
    /// @param _moduleId The unique ID of the module to deregister.
    function deregisterModule(bytes32 _moduleId) external onlyGovernanceExecutor {
        if (modules[_moduleId].addr == address(0) || !modules[_moduleId].isActive) revert ModuleNotRegistered(); // Ensure exists and is active

        modules[_moduleId].isActive = false; // Mark module as inactive

        // Remove from activeModuleIds array (simple iteration, potentially inefficient for many modules)
        for (uint i = 0; i < activeModuleIds.length; i++) {
            if (activeModuleIds[i] == _moduleId) {
                activeModuleIds[i] = activeModuleIds[activeModuleIds.length - 1]; // Swap with last element
                activeModuleIds.pop(); // Remove last element
                break;
            }
        }

        emit ModuleDeregistered(_moduleId);
    }

    /// @notice Returns the on-chain address of a registered module.
    /// @param _moduleId The unique ID of the module.
    /// @return The address of the module.
    function getModuleAddress(bytes32 _moduleId) public view returns (address) {
        if (modules[_moduleId].addr == address(0)) revert ModuleNotRegistered();
        return modules[_moduleId].addr;
    }

    /// @notice Allows governance to call the `configure` function on a registered module.
    /// @dev Callable only by the governance executor. This enables dynamic configuration updates for modules.
    /// It assumes modules implement the `IModule` interface.
    /// @param _moduleId The ID of the module to configure.
    /// @param _callData The ABI-encoded function call (selector + arguments) for the module's `configure` function.
    function setModuleConfiguration(bytes32 _moduleId, bytes calldata _callData) external onlyGovernanceExecutor {
        Module storage module = modules[_moduleId];
        if (module.addr == address(0) || !module.isActive) revert ModuleNotRegistered();

        // Perform the call to the module's configure function
        IModule targetModule = IModule(module.addr);
        targetModule.configure(_callData);

        emit ModuleConfigurationSet(_moduleId, _callData);
    }

    /// @notice A powerful, generic function allowing the ChronoShift Protocol (via governance)
    /// to call any function on any registered module.
    /// @dev Callable only by the governance executor. This provides maximum flexibility for future
    /// interactions and module management, allowing the protocol to adapt to new module needs.
    /// Use with extreme caution as incorrect `_callData` can lead to unintended consequences.
    /// @param _moduleId The ID of the module to interact with.
    /// @param _callData The full ABI-encoded function call (including selector and arguments).
    function callModuleFunction(bytes32 _moduleId, bytes calldata _callData) external onlyGovernanceExecutor {
        Module storage module = modules[_moduleId];
        if (module.addr == address(0) || !module.isActive) revert ModuleNotRegistered();

        // Perform a low-level call to the module address
        (bool success, bytes memory returnData) = module.addr.call(_callData);
        if (!success) {
            // Revert with the returned error message from the module if available
            if (returnData.length > 0) {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            } else {
                revert ModuleCallFailed(); // Generic error if no specific message
            }
        }
        emit ModuleFunctionCalled(_moduleId, _callData);
    }

    // XI. Adaptive Parameter & Governance Rule Adjustment

    /// @notice Retrieves the current value of a specific protocol parameter.
    /// @param _paramName The string name of the parameter.
    /// @return The current uint256 value associated with the parameter name.
    function getProtocolParameter(string calldata _paramName) public view returns (uint256) {
        return protocolParameters[_paramName];
    }

    /// @notice Internal function to update a protocol parameter or governance rule.
    /// @dev This function is callable only by the contract itself, typically as a result of a
    /// successful `ParameterChange` or `GovernanceRuleChange` proposal execution.
    /// @param _paramName The name of the parameter/rule to update.
    /// @param _newValue The new value to set for the parameter/rule.
    function _updateProtocolParameter(string memory _paramName, uint256 _newValue) internal onlyGovernanceExecutor {
        uint256 oldValue = protocolParameters[_paramName];
        protocolParameters[_paramName] = _newValue;
        emit ParameterChanged(_paramName, oldValue, _newValue);
    }

    // XII. Treasury & Dynamic Resource Allocation

    /// @notice Returns the current ETH balance held by the ChronoShift Protocol's treasury.
    /// @return The current ETH balance in wei.
    function getCurrentTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Payable fallback function allowing anyone to send ETH to the protocol's treasury.
    /// @dev All received funds are managed by governance proposals.
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    // XIII. Utility & View Functions

    /// @notice Calculates the current quorum requirement in terms of total voting power.
    /// @dev This calculation is based on the total staked tokens and the dynamically set `QUORUM_PERCENTAGE`.
    /// @return The calculated minimum amount of votes required for a proposal to pass quorum.
    function getAdjustedQuorum() public view returns (uint256) {
        uint256 quorumPercentage = protocolParameters["QUORUM_PERCENTAGE"]; // e.g., 4000 for 40%
        return (totalStakedTokens * quorumPercentage) / 10000; // Divide by 10000 to convert basis points to percentage
    }
}

```