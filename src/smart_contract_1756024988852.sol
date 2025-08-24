This smart contract, **"Decentralized AI-Driven Intent Fulfillment Network" (DAIFN)**, creates a sophisticated ecosystem where users can submit high-level "intents" (goals like "maximize yield," "acquire NFT") and decentralized AI agents compete to fulfill them on-chain. The contract manages agent registration, staking, reputation, intent lifecycle, and a validation process, all designed to foster a reliable and efficient intent-based economy.

It incorporates advanced concepts such as:
*   **Intent-Based Architecture:** Users declare desired outcomes rather than explicit transaction paths.
*   **Dynamic Agent Reputation System:** Agents earn or lose reputation based on performance and user ratings, influencing their ability to secure future intents.
*   **Staking & Slashing Mechanism:** Agents stake ETH as collateral, ensuring accountability.
*   **Role-Based Access Control:** Differentiates between Owner, Validators, Agents, and Users.
*   **State Machine for Intents:** Manages the complex lifecycle of an intent from submission to resolution.
*   **Decentralized Validation (Conceptual):** Integrates trusted validators to confirm off-chain AI agent fulfillment.

---

## Contract Outline

**I. Core Data Structures**
    *   **Enums:** `IntentType`, `IntentStatus`
    *   **Structs:** `Intent`, `Agent`, `IntentConfiguration`, `AgentConfiguration`

**II. State Variables**
    *   `_nextIntentId`: Counter for unique intent IDs.
    *   `intents`: Mapping of intent ID to `Intent` struct.
    *   `agents`: Mapping of agent address to `Agent` struct.
    *   `_registeredAgents`: `EnumerableSet` for efficient tracking of active agents.
    *   `intentConfigs`: Mapping of `IntentType` to `IntentConfiguration`.
    *   `agentConfig`: Global `AgentConfiguration` settings.
    *   `_validators`: `EnumerableSet` for trusted validator addresses.

**III. Events**
    *   Comprehensive events for all critical state changes (e.g., `IntentSubmitted`, `AgentRegistered`, `IntentValidated`).

**IV. Modifiers & Utility Functions**
    *   `onlyAgent`, `onlyValidator` for access control.
    *   Internal helpers for ERC20 transfers and ETH transfers.
    *   `_updateAgentReputation`: Internal logic for adjusting agent reputation.

**V. Main Function Categories**
    *   **I. Configuration & Role Management (Owner/Admin):** Functions for setting global parameters and managing trusted validators.
    *   **II. User-Facing Intent Management:** Functions for users to submit, cancel, rate, and claim funds for their intents.
    *   **III. Agent-Facing Operations:** Functions for agents to register, commit to intents, report fulfillment, claim rewards, manage stake, and update profiles.
    *   **IV. Validator-Facing Operations:** Functions for authorized validators to confirm or reject agent fulfillment reports.
    *   **V. View Functions (Read-Only):** Functions to query the current state of intents, agents, and configurations.

---

## Function Summary

**I. Configuration & Role Management (Owner/Admin):**
1.  **`setIntentConfig(uint256 intentType, uint256 minCollateral, uint256 maxDuration, uint256 defaultAgentReward)`**: Sets parameters for a specific intent type.
2.  **`setAgentConfig(uint256 minStake, uint256 unbondingPeriod, uint256 disputePeriod, uint256 minReputationForCommit)`**: Sets global agent parameters (e.g., minimum stake, unbonding period, reputation thresholds).
3.  **`addValidator(address _validator)`**: Grants validator role to an address.
4.  **`removeValidator(address _validator)`**: Revokes validator role from an address.
5.  **`pause()`**: Pauses critical contract operations (e.g., submitting, committing, validating).
6.  **`unpause()`**: Unpauses contract operations.
7.  **`resolveDispute(uint256 intentId, bool agentSuccess)`**: Manually resolves a disputed intent, impacting agent status and reputation.
8.  **`rescueFunds(IERC20 token, address to, uint256 amount)`**: Allows the owner to rescue accidentally sent ERC20 tokens from the contract.

**II. User-Facing Intent Management:**
9.  **`submitIntent(IntentType _intentType, bytes calldata _parameters, IERC20 _collateralToken, uint256 _collateralAmount, IERC20 _targetAsset, uint256 _minOutputAmount, uint256 _agentReward, uint256 _deadline)`**: Creates a new intent, transferring `_collateralToken` from the user.
10. **`cancelIntent(uint256 _intentId)`**: User cancels an intent if it's not yet successfully validated. If committed, agent may be penalized.
11. **`rateAgentPerformance(uint256 _intentId, uint8 _rating)`**: User rates the agent's performance after a successfully validated intent, impacting reputation.
12. **`claimFunds(uint256 _intentId)`**: User claims output assets (target asset, or refunded collateral) after intent resolution.

**III. Agent-Facing Operations:**
13. **`registerAgent(string calldata _agentProfileUri)`**: Registers a new agent with an initial ETH stake (`msg.value`).
14. **`withdrawAgentStakeAndDeregister()`**: Initiates agent deregistration; stake becomes withdrawable after an unbonding period.
15. **`commitToIntent(uint256 _intentId)`**: Agent signals their commitment to fulfill an intent, requiring sufficient stake and reputation.
16. **`submitFulfillmentReport(uint256 _intentId, bytes calldata _fulfillmentData)`**: Agent submits proof of intent fulfillment for validation.
17. **`claimAgentReward(uint256 _intentId)`**: Agent claims their reward (in `collateralToken`) for successfully validated intents.
18. **`topUpAgentStake()`**: Agent adds more ETH to their stake.
19. **`updateAgentProfile(string calldata _newProfileUri)`**: Agent updates their off-chain profile metadata URI.

**IV. Validator-Facing Operations:**
20. **`validateFulfillment(uint256 _intentId, bool _success)`**: Validator confirms or rejects an agent's fulfillment report. This is a crucial step determining intent success/failure and agent's reputation.

**V. View Functions (Read-Only):**
21. **`getIntentDetails(uint256 _intentId)`**: Returns all details of a specific intent.
22. **`getAgentDetails(address _agentAddress)`**: Returns all details of a specific agent.
23. **`getAgentStake(address _agentAddress)`**: Returns the current ETH stake of an agent.
24. **`getAvailableIntents()`**: Returns a list of intent IDs that are currently `Pending` and available for agents to commit to.
25. **`isAgent(address _addr)`**: Checks if an address is a registered agent.
26. **`isValidator(address _addr)`**: Checks if an address is an authorized validator.
27. **`getAgentReputation(address _agentAddress)`**: Returns an agent's current reputation score.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Outline:
// 1. Core Data Structures: Enums, Structs for Intents, Agents, Configurations.
// 2. State Variables: Mappings for storing Intents, Agents, IDs, Configs.
// 3. Events: For all critical state changes.
// 4. Modifiers & Utility Functions: Access control, internal helpers.
// 5. I. Configuration & Role Management (Owner/Admin): Functions for setting global parameters and managing trusted validators.
// 6. II. User-Facing Intent Management: Functions for users to submit, cancel, rate, and claim funds for their intents.
// 7. III. Agent-Facing Operations: Functions for agents to register, commit to intents, report fulfillment, claim rewards, manage stake, and update profiles.
// 8. IV. Validator-Facing Operations: Functions for authorized validators to confirm or reject agent fulfillment reports.
// 9. V. View Functions (Read-Only): Functions to query the current state of intents, agents, and configurations.

// Function Summary:

// I. Configuration & Role Management (Owner/Admin):
// 1.  setIntentConfig(uint256 intentType, uint256 minCollateral, uint256 maxDuration, uint256 defaultAgentReward): Sets parameters for a specific intent type.
// 2.  setAgentConfig(uint256 minStake, uint256 unbondingPeriod, uint256 disputePeriod, uint256 minReputationForCommit): Sets global agent parameters (e.g., minimum stake, unbonding period, reputation thresholds).
// 3.  addValidator(address _validator): Grants validator role to an address.
// 4.  removeValidator(address _validator): Revokes validator role from an address.
// 5.  pause(): Pauses critical contract operations (e.g., submitting, committing, validating).
// 6.  unpause(): Unpauses contract operations.
// 7.  resolveDispute(uint256 intentId, bool agentSuccess): Manually resolves a disputed intent, impacting agent status and reputation.
// 8.  rescueFunds(IERC20 token, address to, uint256 amount): Allows the owner to rescue accidentally sent ERC20 tokens from the contract.

// II. User-Facing Intent Management:
// 9.  submitIntent(IntentType _intentType, bytes calldata _parameters, IERC20 _collateralToken, uint256 _collateralAmount, IERC20 _targetAsset, uint256 _minOutputAmount, uint256 _agentReward, uint256 _deadline): Creates a new intent, transferring `_collateralToken` from the user.
// 10. cancelIntent(uint256 _intentId): User cancels an intent if it's not yet successfully validated. If committed, agent may be penalized.
// 11. rateAgentPerformance(uint256 _intentId, uint8 _rating): User rates the agent's performance after a successfully validated intent, impacting reputation.
// 12. claimFunds(uint256 _intentId): User claims output assets (target asset, or refunded collateral) after intent resolution.

// III. Agent-Facing Operations:
// 13. registerAgent(string calldata _agentProfileUri): Registers a new agent with an initial ETH stake (`msg.value`).
// 14. withdrawAgentStakeAndDeregister(): Initiates agent deregistration; stake becomes withdrawable after an unbonding period.
// 15. commitToIntent(uint256 _intentId): Agent signals their commitment to fulfill an intent, requiring sufficient stake and reputation.
// 16. submitFulfillmentReport(uint256 _intentId, bytes calldata _fulfillmentData): Agent submits proof of intent fulfillment for validation.
// 17. claimAgentReward(uint256 _intentId): Agent claims their reward (in `collateralToken`) for successfully validated intents.
// 18. topUpAgentStake(): Agent adds more ETH to their stake.
// 19. updateAgentProfile(string calldata _newProfileUri): Agent updates their off-chain profile metadata URI.

// IV. Validator-Facing Operations:
// 20. validateFulfillment(uint256 _intentId, bool _success): Validator confirms or rejects an agent's fulfillment report. This is a crucial step determining intent success/failure and agent's reputation.

// V. View Functions (Read-Only):
// 21. getIntentDetails(uint256 _intentId): Returns all details of a specific intent.
// 22. getAgentDetails(address _agentAddress): Returns all details of a specific agent.
// 23. getAgentStake(address _agentAddress): Returns the current ETH stake of an agent.
// 24. getAvailableIntents(): Returns a list of intent IDs that are currently `Pending` and available for agents to commit to.
// 25. isAgent(address _addr): Checks if an address is a registered agent.
// 26. isValidator(address _addr): Checks if an address is an authorized validator.
// 27. getAgentReputation(address _agentAddress): Returns an agent's current reputation score.

contract DAIFN is Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Custom Errors ---
    error InvalidIntentId();
    error Unauthorized();
    error AgentNotRegistered();
    error IntentNotInExpectedState();
    error AgentAlreadyRegistered();
    error InsufficientStake();
    error InvalidStakeAmount();
    error UnbondingPeriodNotElapsed();
    error IntentDeadlinePassed();
    error IntentConfigNotSet();
    error AgentConfigNotSet();
    error NoAgentRewardToClaim();
    error InsufficientBalance();
    error InvalidRating();
    error AlreadyRated();
    error InvalidParameters();
    error SelfCommitmentNotAllowed();
    error ValidatorAlreadyExists();
    error ValidatorDoesNotExist();
    error AgentStillHasActiveIntents();
    error AgentReputationTooLow();
    error CannotRescueEther();

    // --- Enums ---
    enum IntentType {
        YieldOptimization,
        NFTAcquisition,
        Arbitrage,
        LiquidityProvision,
        Custom
    }

    enum IntentStatus {
        Pending,                // User submitted, awaiting agent commitment
        Committed,              // Agent committed, awaiting fulfillment report
        Fulfilled_PendingValidation, // Agent submitted report, awaiting validator
        Validated_Success,      // Validator confirmed success
        Validated_Failure,      // Validator confirmed failure (or agent failed to report)
        Cancelled,              // User cancelled
        Disputed                // Intent is under dispute resolution
    }

    // --- Structs ---

    struct Intent {
        uint256 id;
        address user;
        IntentType intentType;
        bytes parameters; // Arbitrary data for the specific intent type
        IERC20 collateralToken;
        uint256 collateralAmount;
        IERC20 targetAsset; // Expected output asset (can be 0x0 if not applicable)
        uint256 minOutputAmount;
        address agent; // Address of the agent who committed
        uint256 agentReward; // Reward for the agent (in collateralToken units)
        uint256 deadline;
        IntentStatus status;
        uint256 committedTimestamp; // When agent committed
        uint256 fulfilledTimestamp; // When agent submitted report
        uint256 validatedTimestamp; // When validator acted
        bool rated; // True if user has rated this intent
        uint8 userRating; // 1-5 rating from user
    }

    struct Agent {
        address owner;
        uint256 stake; // ETH locked by the agent
        uint256 reputationScore; // Initial 1000, dynamically updated (e.g., 0 to 2000)
        uint256 lastDeregisterRequest; // Timestamp of deregistration request
        uint256 activeIntentCount; // Number of intents agent is currently working on
        string profileUri; // IPFS hash or URL for agent's off-chain profile/capabilities
    }

    struct IntentConfiguration {
        uint256 minCollateral; // Minimum collateral (in token units)
        uint256 maxDuration; // Max allowed deadline from submission (in seconds)
        uint256 defaultAgentReward; // Default reward (in token units) if not specified by user
    }

    struct AgentConfiguration {
        uint256 minStake; // Minimum ETH required to register/maintain stake
        uint256 unbondingPeriod; // Time agent's stake is locked after deregistration request (in seconds)
        uint256 disputePeriod; // Time window for users to dispute after fulfillment/validation (in seconds)
        uint256 minReputationForCommit; // Minimum reputation an agent needs to commit
    }

    // --- State Variables ---

    uint256 private _nextIntentId;
    mapping(uint256 => Intent) public intents;
    mapping(address => Agent) public agents;
    EnumerableSet.AddressSet private _registeredAgents; // For efficient agent iteration and lookup

    mapping(uint256 => IntentConfiguration) public intentConfigs;
    AgentConfiguration public agentConfig;

    EnumerableSet.AddressSet private _validators; // Set of trusted addresses for validation

    // --- Events ---
    event IntentSubmitted(uint256 indexed intentId, address indexed user, IntentType intentType, address indexed collateralToken, uint256 collateralAmount, uint256 deadline);
    event IntentCommitted(uint256 indexed intentId, address indexed agent, uint256 commitTimestamp);
    event IntentFulfillmentReported(uint256 indexed intentId, address indexed agent, bytes fulfillmentData, uint256 reportTimestamp);
    event IntentValidated(uint252 indexed intentId, address indexed validator, bool success, uint256 validatedTimestamp);
    event IntentCancelled(uint256 indexed intentId, address indexed user);
    event IntentFundsClaimed(uint256 indexed intentId, address indexed claimant, address indexed token, uint256 amount);
    event AgentRegistered(address indexed agentAddress, uint256 stake, string profileUri);
    event AgentDeregisterRequested(address indexed agentAddress, uint256 timestamp);
    event AgentDeregistered(address indexed agentAddress);
    event AgentStakeUpdated(address indexed agentAddress, uint256 newStake);
    event AgentRewardClaimed(uint256 indexed intentId, address indexed agent, address indexed token, uint256 amount);
    event AgentReputationUpdated(address indexed agentAddress, int256 reputationChange, uint256 newReputation);
    event AgentProfileUpdated(address indexed agentAddress, string newProfileUri);
    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event DisputeResolved(uint256 indexed intentId, address indexed resolver, bool agentSuccess);
    event FundsRescued(address indexed token, address indexed to, uint256 amount);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _nextIntentId = 1;
        // Set initial dummy configurations to prevent issues before owner sets them properly
        // Values in wei or seconds, scaled as appropriate
        agentConfig = AgentConfiguration(1 ether, 7 days, 2 days, 500); // 1 ETH min stake, 7 day unbonding, 2 day dispute, 500 min reputation
    }

    // --- Modifiers ---
    modifier onlyAgent(address _agentAddress) {
        if (!_registeredAgents.contains(_agentAddress)) {
            revert AgentNotRegistered();
        }
        _;
    }

    modifier onlyValidator() {
        if (!_validators.contains(msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    // --- Internal/Utility Functions ---

    function _transferERC20(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount > 0) {
            bool success = token.transferFrom(from, to, amount);
            require(success, "ERC20 transferFrom failed");
        }
    }

    function _transferERC20ToContract(IERC20 token, address from, uint256 amount) internal {
        if (amount > 0) {
            bool success = token.transferFrom(from, address(this), amount);
            require(success, "ERC20 transfer to contract failed");
        }
    }

    function _transferERC20FromContract(IERC20 token, address to, uint256 amount) internal {
        if (amount > 0) {
            bool success = token.transfer(to, amount);
            require(success, "ERC20 transfer from contract failed");
        }
    }

    function _transferETH(address to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    /// @dev Updates an agent's reputation score based on success and user rating.
    /// Reputation is clamped between 0 and 2000.
    function _updateAgentReputation(address _agentAddress, bool _success, uint8 _rating) internal {
        Agent storage agent = agents[_agentAddress];
        int256 reputationChange = 0;

        if (_success) {
            if (_rating == 5) reputationChange = 100;
            else if (_rating == 4) reputationChange = 50;
            else reputationChange = 20; // Even average performance adds some reputation
        } else {
            reputationChange = -150; // Significant penalty for failure
        }

        int256 newReputation = int256(agent.reputationScore) + reputationChange;
        if (newReputation < 0) newReputation = 0;
        if (newReputation > 2000) newReputation = 2000;

        agent.reputationScore = uint256(newReputation);
        emit AgentReputationUpdated(_agentAddress, reputationChange, agent.reputationScore);
    }

    // --- I. Configuration & Role Management (Owner/Admin) ---

    /// @notice Sets configuration parameters for a specific intent type.
    /// @param _intentType The enum value of the intent type.
    /// @param _minCollateral Minimum collateral required for this intent type (in token units).
    /// @param _maxDuration Maximum allowed duration for an intent of this type (in seconds from submission).
    /// @param _defaultAgentReward Default reward for agents fulfilling this intent type (in collateral token units).
    function setIntentConfig(
        IntentType _intentType,
        uint256 _minCollateral,
        uint256 _maxDuration,
        uint256 _defaultAgentReward
    ) external onlyOwner {
        intentConfigs[uint256(_intentType)] = IntentConfiguration(
            _minCollateral,
            _maxDuration,
            _defaultAgentReward
        );
    }

    /// @notice Sets global configuration parameters for agents.
    /// @param _minStake Minimum ETH stake required for agents.
    /// @param _unbondingPeriod Duration (in seconds) an agent's stake is locked during deregistration.
    /// @param _disputePeriod Duration (in seconds) for users to dispute after fulfillment/validation.
    /// @param _minReputationForCommit Minimum reputation an agent needs to commit.
    function setAgentConfig(
        uint256 _minStake,
        uint256 _unbondingPeriod,
        uint256 _disputePeriod,
        uint256 _minReputationForCommit
    ) external onlyOwner {
        agentConfig = AgentConfiguration(_minStake, _unbondingPeriod, _disputePeriod, _minReputationForCommit);
    }

    /// @notice Adds a new address to the list of authorized validators.
    /// @param _validator The address to be added as a validator.
    function addValidator(address _validator) external onlyOwner {
        if (_validators.contains(_validator)) {
            revert ValidatorAlreadyExists();
        }
        _validators.add(_validator);
        emit ValidatorAdded(_validator);
    }

    /// @notice Removes an address from the list of authorized validators.
    /// @param _validator The address to be removed as a validator.
    function removeValidator(address _validator) external onlyOwner {
        if (!_validators.contains(_validator)) {
            revert ValidatorDoesNotExist();
        }
        _validators.remove(_validator);
        emit ValidatorRemoved(_validator);
    }

    /// @notice Pauses critical functions of the contract. Only owner.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses critical functions of the contract. Only owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Owner can manually resolve a dispute for an intent.
    /// This is an emergency function to override validator/user interactions.
    /// @param _intentId The ID of the intent in dispute.
    /// @param _agentSuccess True if the agent is deemed successful, false otherwise.
    function resolveDispute(uint256 _intentId, bool _agentSuccess) external onlyOwner nonReentrant {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.status != IntentStatus.Disputed) revert IntentNotInExpectedState();

        intent.status = _agentSuccess ? IntentStatus.Validated_Success : IntentStatus.Validated_Failure;
        intent.validatedTimestamp = block.timestamp;
        
        // If agent fails during dispute, immediately update reputation and decrement active count
        if (!_agentSuccess) {
            _updateAgentReputation(intent.agent, false, 0); 
            agents[intent.agent].activeIntentCount--;
        }

        emit DisputeResolved(_intentId, msg.sender, _agentSuccess);
    }

    /// @notice Allows the owner to rescue accidentally sent ERC20 tokens.
    /// @param token The address of the ERC20 token contract.
    /// @param to The address to send the tokens to.
    /// @param amount The amount of tokens to rescue.
    function rescueFunds(IERC20 token, address to, uint256 amount) external onlyOwner {
        if (address(token) == address(0)) revert CannotRescueEther(); // Prevent accidental ETH rescue that might include agent stake
        if (amount == 0) revert InvalidParameters();
        if (amount > token.balanceOf(address(this))) revert InsufficientBalance();
        _transferERC20FromContract(token, to, amount);
        emit FundsRescued(address(token), to, amount);
    }

    // --- II. User-Facing Intent Management ---

    /// @notice Submits a new intent to the network. User must approve collateral token transfer to this contract first.
    /// @param _intentType The type of intent (e.g., YieldOptimization).
    /// @param _parameters Arbitrary bytes data specific to the intent type, interpreted off-chain by agents.
    /// @param _collateralToken The ERC20 token used as collateral.
    /// @param _collateralAmount The amount of collateral provided by the user.
    /// @param _targetAsset The expected ERC20 token as output (can be address(0) if not directly token output).
    /// @param _minOutputAmount The minimum desired output amount of the target asset.
    /// @param _agentReward The reward offered to the agent for successful fulfillment (in _collateralToken units).
    /// @param _deadline The block timestamp by which the intent must be fulfilled.
    function submitIntent(
        IntentType _intentType,
        bytes calldata _parameters,
        IERC20 _collateralToken,
        uint256 _collateralAmount,
        IERC20 _targetAsset,
        uint256 _minOutputAmount,
        uint256 _agentReward,
        uint256 _deadline
    ) external nonReentrant whenNotPaused {
        IntentConfiguration memory config = intentConfigs[uint256(_intentType)];
        if (config.maxDuration == 0) revert IntentConfigNotSet(); // Check if config exists

        if (_collateralAmount < config.minCollateral || _collateralAmount == 0) revert InvalidParameters();
        if (_deadline <= block.timestamp || _deadline > block.timestamp + config.maxDuration) revert IntentDeadlinePassed();
        if (_agentReward == 0) _agentReward = config.defaultAgentReward;
        if (_agentReward >= _collateralAmount) revert InvalidParameters(); // Reward cannot be >= collateral

        uint256 currentId = _nextIntentId++;
        intents[currentId] = Intent({
            id: currentId,
            user: msg.sender,
            intentType: _intentType,
            parameters: _parameters,
            collateralToken: _collateralToken,
            collateralAmount: _collateralAmount,
            targetAsset: _targetAsset,
            minOutputAmount: _minOutputAmount,
            agent: address(0), // No agent yet
            agentReward: _agentReward,
            deadline: _deadline,
            status: IntentStatus.Pending,
            committedTimestamp: 0,
            fulfilledTimestamp: 0,
            validatedTimestamp: 0,
            rated: false,
            userRating: 0
        });

        _transferERC20ToContract(_collateralToken, msg.sender, _collateralAmount);

        emit IntentSubmitted(currentId, msg.sender, _intentType, address(_collateralToken), _collateralAmount, _deadline);
    }

    /// @notice Allows a user to cancel an intent if it's still in `Pending` or `Committed` state and deadline not passed for agent completion.
    /// If committed, the agent will have its active intent count reduced and reputation penalized.
    /// @param _intentId The ID of the intent to cancel.
    function cancelIntent(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0 || intent.user != msg.sender) revert InvalidIntentId();

        if (intent.status == IntentStatus.Validated_Success ||
            intent.status == IntentStatus.Validated_Failure ||
            intent.status == IntentStatus.Disputed ||
            intent.status == IntentStatus.Fulfilled_PendingValidation // Cannot cancel if report submitted
        ) {
            revert IntentNotInExpectedState();
        }

        if (intent.status == IntentStatus.Committed) {
            // Agent committed, but user cancelled. Agent gets reputation hit and active count reduced.
            agents[intent.agent].activeIntentCount--;
            _updateAgentReputation(intent.agent, false, 0); // Agent gets negative reputation
        }
        
        intent.status = IntentStatus.Cancelled;
        _transferERC20FromContract(intent.collateralToken, intent.user, intent.collateralAmount);
        intent.collateralAmount = 0; // Mark as claimed

        emit IntentCancelled(_intentId, msg.sender);
        emit IntentFundsClaimed(_intentId, msg.sender, address(intent.collateralToken), intent.collateralAmount);
    }

    /// @notice Allows a user to rate the agent after a successfully validated intent.
    /// Affects agent's reputation. Can only be rated once.
    /// @param _intentId The ID of the intent to rate.
    /// @param _rating The rating from 1 to 5 (1 being worst, 5 best).
    function rateAgentPerformance(uint256 _intentId, uint8 _rating) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0 || intent.user != msg.sender) revert InvalidIntentId();
        if (intent.status != IntentStatus.Validated_Success) revert IntentNotInExpectedState();
        if (intent.rated) revert AlreadyRated();
        if (_rating < 1 || _rating > 5) revert InvalidRating();

        intent.rated = true;
        intent.userRating = _rating;
        _updateAgentReputation(intent.agent, true, _rating); // Update reputation based on rating
    }

    /// @notice Allows the user to claim their funds after an intent is resolved (success or failure).
    /// If successful, user claims `collateralAmount - agentReward`. If failed/cancelled/disputed, user claims full `collateralToken`.
    /// @param _intentId The ID of the intent to claim funds for.
    function claimFunds(uint256 _intentId) external nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0 || intent.user != msg.sender) revert InvalidIntentId();

        if (intent.collateralAmount == 0) revert NoAgentRewardToClaim(); // Funds already claimed or not present

        // Check for resolution states
        if (intent.status == IntentStatus.Pending || intent.status == IntentStatus.Committed || intent.status == IntentStatus.Fulfilled_PendingValidation) {
            revert IntentNotInExpectedState(); // Not yet resolved
        }

        uint256 amountToClaim = 0;
        if (intent.status == IntentStatus.Validated_Success) {
            // User gets collateral minus agent reward
            amountToClaim = intent.collateralAmount - intent.agentReward;
        } else if (intent.status == IntentStatus.Validated_Failure || intent.status == IntentStatus.Cancelled) {
            // User gets full collateral back
            amountToClaim = intent.collateralAmount;
        } else if (intent.status == IntentStatus.Disputed) {
            // If dispute period over, treat as failure for the agent if no explicit resolution by owner.
            if (block.timestamp < intent.validatedTimestamp + agentConfig.disputePeriod) {
                 revert IntentNotInExpectedState(); // Still in dispute period
            }
            amountToClaim = intent.collateralAmount; // Default to user gets collateral back
        } else {
            revert IntentNotInExpectedState();
        }

        _transferERC20FromContract(intent.collateralToken, intent.user, amountToClaim);
        emit IntentFundsClaimed(_intentId, msg.sender, address(intent.collateralToken), amountToClaim);
        intent.collateralAmount = 0; // Mark as claimed
    }

    // --- III. Agent-Facing Operations ---

    /// @notice Registers a new agent. Requires sending `agentConfig.minStake` ETH with the transaction.
    /// @param _agentProfileUri URI pointing to the agent's off-chain profile/capabilities.
    function registerAgent(string calldata _agentProfileUri) external payable nonReentrant whenNotPaused {
        if (_registeredAgents.contains(msg.sender)) revert AgentAlreadyRegistered();
        if (agentConfig.minStake == 0) revert AgentConfigNotSet(); // Ensure config is set
        if (msg.value < agentConfig.minStake) revert InsufficientStake();

        agents[msg.sender] = Agent({
            owner: msg.sender,
            stake: msg.value,
            reputationScore: 1000, // Starting reputation
            lastDeregisterRequest: 0,
            activeIntentCount: 0,
            profileUri: _agentProfileUri
        });
        _registeredAgents.add(msg.sender);
        emit AgentRegistered(msg.sender, msg.value, _agentProfileUri);
    }

    /// @notice Initiates the deregistration process for an agent.
    /// The agent's stake will be locked for the `unbondingPeriod`.
    /// Agent cannot have active intents.
    function deregisterAgent() external onlyAgent(msg.sender) nonReentrant whenNotPaused {
        Agent storage agent = agents[msg.sender];
        if (agent.activeIntentCount > 0) revert AgentStillHasActiveIntents();
        if (agent.lastDeregisterRequest > 0) revert IntentNotInExpectedState(); // Already requested deregistration

        agent.lastDeregisterRequest = block.timestamp;
        emit AgentDeregisterRequested(msg.sender, block.timestamp);
    }

    /// @notice Allows an agent to withdraw their stake after the unbonding period and finalize deregistration.
    function withdrawAgentStakeAndDeregister() external onlyAgent(msg.sender) nonReentrant whenNotPaused {
        Agent storage agent = agents[msg.sender];
        if (agent.lastDeregisterRequest == 0) revert IntentNotInExpectedState(); // Not requested deregistration
        if (block.timestamp < agent.lastDeregisterRequest + agentConfig.unbondingPeriod) revert UnbondingPeriodNotElapsed();
        if (agent.activeIntentCount > 0) revert AgentStillHasActiveIntents();

        uint256 totalETH = agent.stake;
        agent.stake = 0; // Clear stake before transfer

        _transferETH(msg.sender, totalETH);

        _registeredAgents.remove(msg.sender);
        delete agents[msg.sender]; // Clear agent data
        emit AgentDeregistered(msg.sender);
    }

    /// @notice An agent commits to fulfilling a specific intent.
    /// Requires agent's stake to be above `minStake` and reputation above `minReputationForCommit`.
    /// @param _intentId The ID of the intent to commit to.
    function commitToIntent(uint256 _intentId) external onlyAgent(msg.sender) nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.status != IntentStatus.Pending) revert IntentNotInExpectedState();
        if (block.timestamp >= intent.deadline) revert IntentDeadlinePassed();

        Agent storage agent = agents[msg.sender];
        if (agent.stake < agentConfig.minStake) revert InsufficientStake();
        if (agent.reputationScore < agentConfig.minReputationForCommit) revert AgentReputationTooLow();
        if (agent.owner == intent.user) revert SelfCommitmentNotAllowed(); // Agent cannot fulfill their own intent

        intent.agent = msg.sender;
        intent.status = IntentStatus.Committed;
        intent.committedTimestamp = block.timestamp;
        agent.activeIntentCount++;

        emit IntentCommitted(_intentId, msg.sender, block.timestamp);
    }

    /// @notice An agent submits a report detailing their fulfillment of an intent.
    /// This report will be validated by an authorized validator.
    /// @param _intentId The ID of the intent being fulfilled.
    /// @param _fulfillmentData Arbitrary bytes data representing the proof of fulfillment (e.g., transaction hashes, oracle data hash).
    function submitFulfillmentReport(uint256 _intentId, bytes calldata _fulfillmentData) external onlyAgent(msg.sender) nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0 || intent.agent != msg.sender) revert InvalidIntentId();
        if (intent.status != IntentStatus.Committed) revert IntentNotInExpectedState();
        if (block.timestamp >= intent.deadline) revert IntentDeadlinePassed(); // Agent missed deadline

        intent.status = IntentStatus.Fulfilled_PendingValidation;
        intent.fulfilledTimestamp = block.timestamp;

        emit IntentFulfillmentReported(_intentId, msg.sender, _fulfillmentData, block.timestamp);
    }

    /// @notice Allows an agent to claim their reward for a successfully validated intent.
    /// The reward is taken from the intent's collateral and transferred to the agent's wallet.
    /// @param _intentId The ID of the intent for which to claim reward.
    function claimAgentReward(uint256 _intentId) external onlyAgent(msg.sender) nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0 || intent.agent != msg.sender) revert InvalidIntentId();
        if (intent.status != IntentStatus.Validated_Success) revert IntentNotInExpectedState();
        if (intent.agentReward == 0) revert NoAgentRewardToClaim();

        Agent storage agent = agents[msg.sender];
        agent.activeIntentCount--; // Intent resolved, decrease active count.

        uint256 rewardAmount = intent.agentReward;
        _transferERC20FromContract(intent.collateralToken, msg.sender, rewardAmount); // Transfer collateral token to agent's wallet
        emit AgentRewardClaimed(_intentId, msg.sender, address(intent.collateralToken), rewardAmount);
        intent.agentReward = 0; // Mark as claimed
    }

    /// @notice Allows an agent to increase their ETH stake by sending ETH.
    function topUpAgentStake() external payable onlyAgent(msg.sender) nonReentrant whenNotPaused {
        if (msg.value == 0) revert InvalidStakeAmount();
        Agent storage agent = agents[msg.sender];
        agent.stake += msg.value;
        emit AgentStakeUpdated(msg.sender, agent.stake);
    }

    /// @notice Allows an agent to update their off-chain profile URI.
    /// @param _newProfileUri The new URI for the agent's profile.
    function updateAgentProfile(string calldata _newProfileUri) external onlyAgent(msg.sender) whenNotPaused {
        Agent storage agent = agents[msg.sender];
        agent.profileUri = _newProfileUri;
        emit AgentProfileUpdated(msg.sender, _newProfileUri);
    }

    // --- IV. Validator-Facing Operations ---

    /// @notice A validator confirms or rejects an agent's fulfillment report.
    /// This is a critical function that determines success/failure of an intent.
    /// @param _intentId The ID of the intent to validate.
    /// @param _success True if the fulfillment is valid, false otherwise.
    function validateFulfillment(uint252 _intentId, bool _success) external onlyValidator nonReentrant whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert InvalidIntentId();
        if (intent.status != IntentStatus.Fulfilled_PendingValidation) revert IntentNotInExpectedState();

        intent.status = _success ? IntentStatus.Validated_Success : IntentStatus.Validated_Failure;
        intent.validatedTimestamp = block.timestamp;

        // If validation fails, agent's reputation is immediately affected, and active count decreased.
        if (!_success) {
            _updateAgentReputation(intent.agent, false, 0); // Agent failed, low rating (0)
            agents[intent.agent].activeIntentCount--; // Active count decreases on failure
        }

        emit IntentValidated(_intentId, msg.sender, _success, block.timestamp);
    }

    // --- V. View Functions (Read-Only) ---

    /// @notice Returns full details of an intent.
    /// @param _intentId The ID of the intent.
    /// @return Intent struct containing all details.
    function getIntentDetails(uint256 _intentId) public view returns (Intent memory) {
        if (intents[_intentId].id == 0) revert InvalidIntentId();
        return intents[_intentId];
    }

    /// @notice Returns full details of an agent.
    /// @param _agentAddress The address of the agent.
    /// @return Agent struct containing all details.
    function getAgentDetails(address _agentAddress) public view returns (Agent memory) {
        if (!_registeredAgents.contains(_agentAddress)) revert AgentNotRegistered();
        return agents[_agentAddress];
    }

    /// @notice Returns the current stake of an agent.
    /// @param _agentAddress The address of the agent.
    /// @return The amount of ETH staked by the agent.
    function getAgentStake(address _agentAddress) public view returns (uint256) {
        if (!_registeredAgents.contains(_agentAddress)) revert AgentNotRegistered();
        return agents[_agentAddress].stake;
    }

    /// @notice Returns a list of all intent IDs that are currently in 'Pending' state.
    /// This allows agents to discover new work. Limits iterations for gas efficiency in a view function.
    /// @return An array of intent IDs.
    function getAvailableIntents() public view returns (uint256[] memory) {
        // Limits iteration for gas efficiency. In production, a more efficient off-chain index or
        // a different on-chain data structure (e.g., linked list) would be used for large numbers of intents.
        uint256 maxScan = _nextIntentId > 1000 ? 1000 : _nextIntentId; // Cap for view function to prevent OOG.
        uint256[] memory tempAvailable = new uint256[](maxScan);
        uint256 count = 0;

        for (uint256 i = 1; i < maxScan; i++) {
            if (intents[i].id != 0 && intents[i].status == IntentStatus.Pending && block.timestamp < intents[i].deadline) {
                tempAvailable[count] = i;
                count++;
            }
        }

        uint256[] memory available = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            available[i] = tempAvailable[i];
        }
        return available;
    }

    /// @notice Checks if an address is a registered agent.
    /// @param _addr The address to check.
    /// @return True if the address is a registered agent, false otherwise.
    function isAgent(address _addr) public view returns (bool) {
        return _registeredAgents.contains(_addr);
    }

    /// @notice Checks if an address is an authorized validator.
    /// @param _addr The address to check.
    /// @return True if the address is a validator, false otherwise.
    function isValidator(address _addr) public view returns (bool) {
        return _validators.contains(_addr);
    }

    /// @notice Returns an agent's current reputation score.
    /// @param _agentAddress The address of the agent.
    /// @return The agent's reputation score.
    function getAgentReputation(address _agentAddress) public view returns (uint256) {
        if (!_registeredAgents.contains(_agentAddress)) revert AgentNotRegistered();
        return agents[_agentAddress].reputationScore;
    }

    // Fallback function to accept ETH
    // This allows existing agents to top up their stake by simply sending ETH.
    // Any other sender will cause a revert to prevent accidental ETH accumulation.
    receive() external payable {
        if (_registeredAgents.contains(msg.sender)) {
            // This ETH is considered a stake top-up for an existing agent
            Agent storage agent = agents[msg.sender];
            agent.stake += msg.value;
            emit AgentStakeUpdated(msg.sender, agent.stake);
        } else {
            // Reject any other ETH transfers to ensure all ETH in contract is agent stake.
            revert Unauthorized();
        }
    }
}
```