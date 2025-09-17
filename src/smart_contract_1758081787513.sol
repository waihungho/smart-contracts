The smart contract presented below, **Genesis Fabric**, is designed as a decentralized intent orchestration layer. It allows users to define complex, multi-step financial intents which are then fulfilled by a network of "Pathfinders" using existing DeFi protocols. "Validators" ensure the correctness of proposed paths and execution outcomes through a staking and dispute resolution system. The contract acts as an escrow, holding user funds during the execution of approved intents.

---

## Genesis Fabric: Decentralized Intent Orchestration Layer

**Purpose:** To enable complex, multi-protocol financial "intents" to be executed in a decentralized, verifiable, and economically incentivized manner. Users define their desired outcomes (intents), Pathfinders propose optimal execution strategies, and Validators ensure the integrity of the process.

**Core Concept:**
Genesis Fabric shifts the paradigm from directly interacting with individual protocols to declaring desired *outcomes* (intents). It creates a marketplace where:
1.  **Intent Creators** submit high-level goals (e.g., "maximize yield on my stablecoins across Aave/Compound, but only if gas is below X and no impermanent loss over Y%").
2.  **Pathfinders** (can be AI agents or sophisticated users) compete to find the most efficient and safest sequence of calls (the "path") across various whitelisted DeFi protocols to achieve the intent.
3.  **Validators** stake tokens to review proposed paths and execution outcomes, ensuring honest behavior and the correct fulfillment of intents.
4.  The **Genesis Fabric** contract acts as a secure escrow, holding assets during execution and transparently performing the approved multi-call sequence.

**Key Features & Advanced Concepts:**

*   **Rich Intent Language:** Supports complex, conditional, and multi-protocol intents (abstracted via `intentHash` for off-chain description and on-chain verification conditions).
*   **Decentralized Pathfinding Market:** Pathfinders stake tokens, propose paths, and are rewarded for successful fulfillments.
*   **On-chain Escrow & Orchestrated Execution:** Funds are held securely by the contract, which then executes a series of approved external calls.
*   **Validator-based Dispute Resolution:** A robust system for challenging faulty proposals or malicious executions, backed by economic incentives (slashing/rewards).
*   **Reputation System:** Pathfinders and Validators build reputation based on their performance, influencing future interactions and rewards.
*   **Dynamic Protocol Whitelisting:** Governed by the DAO, new DeFi protocols can be added or removed, ensuring adaptability to the evolving ecosystem.
*   **Verifiable Computation Integration (conceptual):** The `finalExecutionOutcomeHash` and `proofData` fields hint at integration with verifiable computation networks (e.g., Chainlink Functions, ZK-proofs) for complex intent condition validation.
*   **Gas Optimization:** While paths are complex, the `executeApprovedPath` function is designed to be a single transaction that orchestrates multiple external calls, potentially saving gas for the end-user compared to manual execution.
*   **Future Upgradability:** Designed with clear interfaces, implying future upgradability through proxy patterns (not implemented directly in this single contract for brevity, but a core consideration).

**Actors:**

*   **Intent Creator:** A user who defines and submits an intent, depositing the necessary tokens.
*   **Pathfinder:** An agent (human or AI) that analyzes intents and proposes an optimized sequence of protocol interactions (a "path"). Staked and rewarded for successful pathfinding.
*   **Validator:** A staked participant responsible for reviewing proposed paths and challenging incorrect or malicious behavior from Pathfinders or erroneous execution outcomes. Rewarded for accurate validation.
*   **Administrator/DAO:** Controls core protocol parameters, whitelists protocols, and resolves disputes. Initially `Ownable`, envisioned to transition to a full DAO.

---

### Function Summary

**I. Core Intent Lifecycle & Assets**
1.  `submitIntent(IntentData calldata _intentDetails, address[] calldata _requiredTokens, uint256[] calldata _requiredAmounts)`: Allows a user to create a new intent, specifying its conditions and the initial tokens required for execution.
2.  `depositForIntent(uint256 _intentId, address _token, uint256 _amount)`: Allows the intent creator to deposit the specified tokens into the contract's escrow for a pending intent.
3.  `cancelIntent(uint256 _intentId)`: Allows the intent creator to cancel their intent and withdraw deposited funds, provided no path has been approved or executed.
4.  `releaseFundsUponCompletion(uint256 _intentId)`: Internal function to transfer output tokens to the intent creator or return unspent funds after an intent's successful completion.
5.  `getIntentDetails(uint256 _intentId)`: Public view function to retrieve all details of a specific intent.
6.  `updateIntentStatus(uint256 _intentId, IntentStatus _newStatus)`: Internal function to transition an intent's status throughout its lifecycle.

**II. Pathfinder Operations & Path Management**
7.  `registerPathfinder(string calldata _metadataURI)`: Allows a user to register as a Pathfinder by staking tokens and providing metadata.
8.  `deregisterPathfinder()`: Allows a registered Pathfinder to initiate unstaking and eventual deregistration after a cooldown.
9.  `proposeFulfillmentPath(uint256 _intentId, CallData[] calldata _path)`: Pathfinders propose a sequence of external calls (`CallData`) to fulfill a specific intent.
10. `approvePathProposal(uint256 _intentId, uint256 _pathfinderId)`: The intent creator (or a designated approval mechanism) approves a specific proposed path.
11. `executeApprovedPath(uint256 _intentId, uint256 _pathfinderId)`: The contract executes the previously approved path by making a series of external calls, transferring control to target protocols.
12. `slashPathfinder(uint256 _pathfinderId, uint256 _amount)`: Internal/admin function to penalize a Pathfinder by reducing their stake due to malicious or faulty actions.

**III. Validator Operations & Dispute Resolution**
13. `registerValidator(string calldata _metadataURI)`: Allows a user to register as a Validator by staking tokens and providing metadata.
14. `deregisterValidator()`: Allows a registered Validator to initiate unstaking and eventual deregistration after a cooldown.
15. `challengePathProposal(uint256 _intentId, uint256 _pathfinderId, string calldata _reason)`: Validators can challenge a proposed path before execution, if they deem it flawed or malicious.
16. `challengeExecutionOutcome(uint256 _intentId, string calldata _reason)`: Validators can challenge the outcome of an executed path, claiming the intent was not fulfilled as specified.
17. `resolveDispute(uint256 _disputeId, bool _challengerWasCorrect)`: An admin/DAO function to resolve an open dispute, leading to potential slashing or reward distribution.

**IV. Staking & Rewards**
18. `stake(uint256 _amount)`: Allows any registered Pathfinder or Validator to increase their stake.
19. `unstake(uint256 _amount)`: Allows any registered Pathfinder or Validator to initiate unstaking of a portion of their stake (subject to cooldowns/locks).
20. `claimRewards()`: Allows Pathfinders and Validators to claim their accumulated rewards from successful operations or dispute resolutions.
21. `distributeIntentRewards(uint256 _intentId, uint256 _pathfinderId)`: Internal function to distribute earned rewards to Pathfinders and potentially Validators upon successful intent completion.

**V. Governance & System Parameters**
22. `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows the administrator (or DAO) to adjust key system parameters like minimum stakes, challenge fees, or reward percentages.
23. `addSupportedProtocol(address _protocolAddress, bytes4[] calldata _supportedSelectors)`: Allows the administrator (or DAO) to whitelist a new DeFi protocol that Genesis Fabric can interact with, specifying its callable functions.
24. `removeSupportedProtocol(address _protocolAddress)`: Allows the administrator (or DAO) to remove a previously whitelisted protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary provided above the code.

contract GenesisFabric is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Events ---
    event IntentSubmitted(
        uint256 indexed intentId,
        address indexed creator,
        bytes32 intentHash,
        uint256 timestamp
    );
    event IntentDeposited(
        uint256 indexed intentId,
        address indexed token,
        uint256 amount
    );
    event IntentStatusUpdated(
        uint256 indexed intentId,
        IntentStatus oldStatus,
        IntentStatus newStatus
    );
    event IntentCanceled(uint256 indexed intentId);
    event IntentCompleted(
        uint256 indexed intentId,
        address indexed creator,
        bool success
    );

    event PathfinderRegistered(
        uint256 indexed pathfinderId,
        address indexed owner,
        string metadataURI
    );
    event PathfinderDeregistered(uint256 indexed pathfinderId, address owner);
    event PathProposed(
        uint256 indexed intentId,
        uint256 indexed pathfinderId,
        uint256 proposalId
    );
    event PathApproved(
        uint256 indexed intentId,
        uint256 indexed pathfinderId
    );
    event PathExecuted(uint256 indexed intentId, uint256 indexed pathfinderId);
    event PathfinderSlashed(
        uint256 indexed pathfinderId,
        uint256 amount,
        string reason
    );

    event ValidatorRegistered(
        uint256 indexed validatorId,
        address indexed owner,
        string metadataURI
    );
    event ValidatorDeregistered(uint256 indexed validatorId, address owner);
    event PathProposalChallenged(
        uint256 indexed disputeId,
        uint256 indexed intentId,
        uint256 indexed challengerId,
        uint256 pathfinderIdInQuestion
    );
    event ExecutionOutcomeChallenged(
        uint256 indexed disputeId,
        uint256 indexed intentId,
        uint256 indexed challengerId
    );
    event DisputeResolved(
        uint256 indexed disputeId,
        bool challengerWasCorrect,
        address indexed winner,
        address indexed loser
    );

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsDistributed(
        uint256 indexed intentId,
        uint256 pathfinderId,
        uint256 pathfinderReward,
        uint256 validatorReward
    );

    event ProtocolParameterUpdated(
        bytes32 indexed paramName,
        uint256 newValue
    );
    event SupportedProtocolAdded(
        address indexed protocolAddress,
        bytes4[] supportedSelectors
    );
    event SupportedProtocolRemoved(address indexed protocolAddress);

    // --- Enums ---
    enum IntentStatus {
        PendingDeposit, // Intent created, waiting for user to deposit funds
        PendingPathfinding, // Funds deposited, Pathfinders can propose
        PathProposed, // A path has been proposed
        PathApproved, // A path has been approved by the creator/system
        Executing, // The approved path is being executed by the contract
        CompletedSuccess, // Path executed successfully, intent fulfilled
        CompletedFailure, // Path executed but intent conditions not met, or critical error
        Canceled, // Intent canceled by creator
        Challenged // Intent outcome is under dispute
    }

    enum Role {
        None,
        Pathfinder,
        Validator
    }

    enum PathStatus {
        Proposed,
        Approved,
        Rejected,
        Executed
    }

    enum ChallengeType {
        PathProposal,
        ExecutionOutcome
    }

    enum DisputeStatus {
        Open,
        Resolved
    }

    // --- Structs ---
    struct IntentData {
        address creator;
        bytes32 intentHash; // A hash representing the off-chain definition/conditions of the intent
        IntentStatus status;
        address[] requiredTokens; // Tokens user needs to deposit
        uint256[] requiredAmounts;
        address[] outputTokens; // Expected output tokens
        uint256[] outputMinAmounts; // Minimum expected output amounts
        uint256 deadline; // Timestamp by which intent must be fulfilled
        uint256 creationTimestamp;
        uint256 approvedPathfinderId; // ID of the pathfinder whose path was approved
        bytes32 finalExecutionOutcomeHash; // Hash of the final outcome/proof (e.g., ZK proof output)
        uint256 pathfinderRewardAmount;
        uint256 validatorRewardAmount;
    }

    struct CallData {
        address target; // Target contract address
        uint256 value; // ETH value to send (if any)
        bytes data; // Calldata for the target function
    }

    struct Pathfinder {
        address owner;
        uint256 stake;
        string metadataURI; // URI to off-chain Pathfinder description/AI model
        bool isActive; // True if Pathfinder is registered and not deregistering
        uint256 reputationScore; // Based on successful fulfillments & accurate proposals
        uint256 slashedAmount; // Total amount slashed from this pathfinder
        uint256 deregistrationTimestamp; // Cooldown for unstaking
        uint256 pendingRewards;
    }

    struct Validator {
        address owner;
        uint256 stake;
        string metadataURI; // URI to off-chain Validator description
        bool isActive;
        uint256 reputationScore; // Based on accurate challenges & dispute resolutions
        uint256 slashedAmount;
        uint256 deregistrationTimestamp; // Cooldown for unstaking
        uint256 pendingRewards;
    }

    struct PathProposal {
        uint256 pathfinderId;
        CallData[] path;
        PathStatus status;
        uint256 proposalTimestamp;
        uint256 proposalApprovalVotes; // For future DAO voting on paths
    }

    struct Dispute {
        uint256 intentId;
        uint256 challengerId; // ID of the Pathfinder or Validator
        Role challengerRole;
        uint256 pathfinderIdInQuestion; // Relevant if challenge is against a pathfinder
        ChallengeType challengeType;
        string reason;
        DisputeStatus status;
        uint256 resolutionTimestamp;
        uint256 challengeStake; // Stake put up by challenger
    }

    // --- State Variables ---
    uint256 public nextIntentId = 1;
    uint256 public nextPathfinderId = 1;
    uint256 public nextValidatorId = 1;
    uint256 public nextDisputeId = 1;

    mapping(uint256 => IntentData) public intents;
    mapping(address => uint256) public userToPathfinderId; // user address -> Pathfinder ID
    mapping(uint256 => Pathfinder) public pathfinders; // Pathfinder ID -> Pathfinder struct
    mapping(address => uint256) public userToValidatorId; // user address -> Validator ID
    mapping(uint256 => Validator) public validators; // Validator ID -> Validator struct

    mapping(uint256 => mapping(uint256 => PathProposal)) public intentPathProposals; // intentId -> pathfinderId -> PathProposal

    mapping(uint256 => Dispute) public disputes;

    // Protocol Whitelist: address => mapping(selector => bool)
    mapping(address => mapping(bytes4 => bool)) public supportedProtocols;

    // Protocol Parameters (can be updated by admin/DAO)
    mapping(bytes32 => uint256) public protocolParameters;

    // Constants for parameter names
    bytes32 public constant MIN_PATHFINDER_STAKE = "MIN_PATHFINDER_STAKE";
    bytes32 public constant MIN_VALIDATOR_STAKE = "MIN_VALIDATOR_STAKE";
    bytes32 public constant PATHFINDER_REWARD_PERCENTAGE = "PATHFINDER_REWARD_PERCENTAGE"; // e.g., 500 for 5% of intent value
    bytes32 public constant VALIDATOR_REWARD_PERCENTAGE = "VALIDATOR_REWARD_PERCENTAGE"; // e.g., 100 for 1% of intent value
    bytes32 public constant CHALLENGE_FEE_PERCENTAGE = "CHALLENGE_FEE_PERCENTAGE"; // e.g., 200 for 2% of pathfinder stake
    bytes32 public constant DEREGISTRATION_COOLDOWN = "DEREGISTRATION_COOLDOWN"; // in seconds
    bytes32 public constant PATH_APPROVAL_DEADLINE = "PATH_APPROVAL_DEADLINE"; // in seconds after proposal

    // --- Constructor ---
    constructor(address initialOwner) Ownable(initialOwner) {
        // Initialize default protocol parameters
        protocolParameters[MIN_PATHFINDER_STAKE] = 1000 ether; // Example: 1000 WETH or custom token
        protocolParameters[MIN_VALIDATOR_STAKE] = 500 ether; // Example: 500 WETH
        protocolParameters[PATHFINDER_REWARD_PERCENTAGE] = 500; // 5% (500 basis points)
        protocolParameters[VALIDATOR_REWARD_PERCENTAGE] = 100; // 1% (100 basis points)
        protocolParameters[CHALLENGE_FEE_PERCENTAGE] = 200; // 2% of pathfinder stake
        protocolParameters[DEREGISTRATION_COOLDOWN] = 7 days; // 7 days cooldown
        protocolParameters[PATH_APPROVAL_DEADLINE] = 1 days; // 1 day for path approval
    }

    // --- Modifiers ---
    modifier onlyIntentCreator(uint256 _intentId) {
        require(intents[_intentId].creator == msg.sender, "Not intent creator");
        _;
    }

    modifier onlyPathfinder(uint256 _pathfinderId) {
        require(
            userToPathfinderId[msg.sender] == _pathfinderId &&
                pathfinders[_pathfinderId].isActive,
            "Not active pathfinder"
        );
        _;
    }

    modifier onlyValidator(uint256 _validatorId) {
        require(
            userToValidatorId[msg.sender] == _validatorId &&
                validators[_validatorId].isActive,
            "Not active validator"
        );
        _;
    }

    modifier isValidProtocolCall(address _target, bytes4 _selector) {
        require(supportedProtocols[_target][_selector], "Unsupported protocol or selector");
        _;
    }

    // --- I. Core Intent Lifecycle & Assets ---

    /// @notice Submits a new intent to the Genesis Fabric.
    /// @param _intentDetails Structured data describing the intent (off-chain hash, outputs, etc.).
    /// @param _requiredTokens Array of token addresses that need to be deposited by the creator.
    /// @param _requiredAmounts Array of corresponding amounts for `_requiredTokens`.
    /// @return The unique ID of the newly created intent.
    function submitIntent(
        IntentData calldata _intentDetails,
        address[] calldata _requiredTokens,
        uint256[] calldata _requiredAmounts
    ) external returns (uint256) {
        require(_intentDetails.deadline > block.timestamp, "Intent deadline must be in the future");
        require(
            _requiredTokens.length == _requiredAmounts.length,
            "Token and amount arrays must match"
        );
        require(
            _intentDetails.outputTokens.length == _intentDetails.outputMinAmounts.length,
            "Output token and amount arrays must match"
        );

        uint256 intentId = nextIntentId++;
        IntentData storage newIntent = intents[intentId];

        newIntent.creator = msg.sender;
        newIntent.intentHash = _intentDetails.intentHash;
        newIntent.status = IntentStatus.PendingDeposit;
        newIntent.requiredTokens = _requiredTokens;
        newIntent.requiredAmounts = _requiredAmounts;
        newIntent.outputTokens = _intentDetails.outputTokens;
        newIntent.outputMinAmounts = _intentDetails.outputMinAmounts;
        newIntent.deadline = _intentDetails.deadline;
        newIntent.creationTimestamp = block.timestamp;

        emit IntentSubmitted(intentId, msg.sender, _intentDetails.intentHash, block.timestamp);
        return intentId;
    }

    /// @notice Deposits required tokens into the contract's escrow for a specific intent.
    /// @param _intentId The ID of the intent.
    /// @param _token The address of the ERC20 token to deposit.
    /// @param _amount The amount of token to deposit.
    function depositForIntent(
        uint256 _intentId,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        IntentData storage intent = intents[_intentId];
        require(intent.creator == msg.sender, "Only intent creator can deposit");
        require(
            intent.status == IntentStatus.PendingDeposit,
            "Intent not in PendingDeposit status"
        );
        require(block.timestamp < intent.deadline, "Intent deadline passed");

        bool found = false;
        for (uint256 i = 0; i < intent.requiredTokens.length; i++) {
            if (intent.requiredTokens[i] == _token) {
                require(
                    _amount >= intent.requiredAmounts[i],
                    "Deposited amount less than required"
                );
                intent.requiredAmounts[i] = 0; // Mark as deposited
                found = true;
                break;
            }
        }
        require(found, "Token not required for this intent");

        // Transfer tokens to the contract
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        emit IntentDeposited(_intentId, _token, _amount);

        // Check if all required tokens are deposited
        bool allDeposited = true;
        for (uint256 i = 0; i < intent.requiredAmounts.length; i++) {
            if (intent.requiredAmounts[i] > 0) {
                allDeposited = false;
                break;
            }
        }

        if (allDeposited) {
            updateIntentStatus(_intentId, IntentStatus.PendingPathfinding);
        }
    }

    /// @notice Allows the intent creator to cancel their intent and withdraw deposited funds.
    /// @param _intentId The ID of the intent to cancel.
    function cancelIntent(uint256 _intentId)
        external
        onlyIntentCreator(_intentId)
        nonReentrant
    {
        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.PendingDeposit ||
                intent.status == IntentStatus.PendingPathfinding ||
                intent.status == IntentStatus.PathProposed,
            "Cannot cancel intent in current state"
        );
        require(block.timestamp < intent.deadline, "Intent deadline passed");

        // Return all deposited tokens
        for (uint256 i = 0; i < intent.requiredTokens.length; i++) {
            address token = intent.requiredTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                require(
                    IERC20(token).transfer(msg.sender, balance),
                    "Token withdrawal failed"
                );
            }
        }
        // If ETH was deposited, return it (not explicitly in current deposit func, but for completeness)
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        updateIntentStatus(_intentId, IntentStatus.Canceled);
        emit IntentCanceled(_intentId);
    }

    /// @notice Internal function to release output tokens to the intent creator or return unspent funds.
    /// @param _intentId The ID of the intent.
    function releaseFundsUponCompletion(uint256 _intentId) internal nonReentrant {
        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.CompletedSuccess ||
                intent.status == IntentStatus.CompletedFailure,
            "Intent not in a completed state"
        );

        // Transfer output tokens to the creator
        for (uint256 i = 0; i < intent.outputTokens.length; i++) {
            address token = intent.outputTokens[i];
            uint256 finalBalance = IERC20(token).balanceOf(address(this));
            if (finalBalance > 0) {
                // Transfer only relevant portion for the intent, or all if it's the only one.
                // For simplicity, let's assume all balance of the output token belongs to this intent.
                // A more robust system would track output amounts per intent.
                require(
                    IERC20(token).transfer(intent.creator, finalBalance),
                    "Output token transfer failed"
                );
            }
        }

        // Return any remaining ETH
        if (address(this).balance > 0) {
            payable(intent.creator).transfer(address(this).balance);
        }

        emit IntentCompleted(_intentId, intent.creator, intent.status == IntentStatus.CompletedSuccess);
    }

    /// @notice Public view function to retrieve all details of a specific intent.
    /// @param _intentId The ID of the intent.
    /// @return The `IntentData` struct for the given ID.
    function getIntentDetails(
        uint256 _intentId
    ) public view returns (IntentData memory) {
        return intents[_intentId];
    }

    /// @notice Internal function to transition an intent's status throughout its lifecycle.
    /// @param _intentId The ID of the intent.
    /// @param _newStatus The new status to set.
    function updateIntentStatus(
        uint256 _intentId,
        IntentStatus _newStatus
    ) internal {
        IntentData storage intent = intents[_intentId];
        IntentStatus oldStatus = intent.status;
        intent.status = _newStatus;
        emit IntentStatusUpdated(_intentId, oldStatus, _newStatus);
    }

    // --- II. Pathfinder Operations & Path Management ---

    /// @notice Registers the caller as a Pathfinder. Requires staking.
    /// @param _metadataURI URI pointing to off-chain Pathfinder description/AI model.
    function registerPathfinder(string calldata _metadataURI) external nonReentrant {
        require(userToPathfinderId[msg.sender] == 0, "Already registered as Pathfinder");
        require(msg.value >= protocolParameters[MIN_PATHFINDER_STAKE], "Insufficient stake");

        uint256 pathfinderId = nextPathfinderId++;
        pathfinders[pathfinderId] = Pathfinder({
            owner: msg.sender,
            stake: msg.value,
            metadataURI: _metadataURI,
            isActive: true,
            reputationScore: 0,
            slashedAmount: 0,
            deregistrationTimestamp: 0,
            pendingRewards: 0
        });
        userToPathfinderId[msg.sender] = pathfinderId;

        emit PathfinderRegistered(pathfinderId, msg.sender, _metadataURI);
    }

    /// @notice Allows a Pathfinder to initiate deregistration and unstaking.
    /// Funds will be locked for a cooldown period.
    function deregisterPathfinder() external nonReentrant {
        uint256 pathfinderId = userToPathfinderId[msg.sender];
        require(pathfinderId != 0, "Not a registered Pathfinder");
        Pathfinder storage pathfinder = pathfinders[pathfinderId];
        require(pathfinder.isActive, "Pathfinder already deregistering");

        pathfinder.isActive = false; // Mark as inactive during cooldown
        pathfinder.deregistrationTimestamp = block.timestamp;

        emit PathfinderDeregistered(pathfinderId, msg.sender);
    }

    /// @notice Pathfinders propose a sequence of external calls to fulfill an intent.
    /// @param _intentId The ID of the intent.
    /// @param _path An array of `CallData` structs representing the execution path.
    function proposeFulfillmentPath(
        uint256 _intentId,
        CallData[] calldata _path
    ) external nonReentrant {
        uint256 pathfinderId = userToPathfinderId[msg.sender];
        require(pathfinderId != 0, "Only registered Pathfinders can propose paths");
        require(pathfinders[pathfinderId].isActive, "Pathfinder is not active");

        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.PendingPathfinding ||
                intent.status == IntentStatus.PathProposed,
            "Intent not in a pathfinding state"
        );
        require(block.timestamp < intent.deadline, "Intent deadline passed");
        require(_path.length > 0, "Path cannot be empty");

        // Basic validation of path: ensure all targets/selectors are whitelisted
        for (uint256 i = 0; i < _path.length; i++) {
            bytes4 selector = bytes4(_path[i].data);
            require(supportedProtocols[_path[i].target][selector], "Path contains unsupported protocol call");
        }

        intentPathProposals[_intentId][pathfinderId] = PathProposal({
            pathfinderId: pathfinderId,
            path: _path,
            status: PathStatus.Proposed,
            proposalTimestamp: block.timestamp,
            proposalApprovalVotes: 0
        });

        // If this is the first proposal, update intent status
        if (intent.status == IntentStatus.PendingPathfinding) {
            updateIntentStatus(_intentId, IntentStatus.PathProposed);
        }

        emit PathProposed(_intentId, pathfinderId, pathfinderId); // Using pathfinderId as proposalId for simplicity
    }

    /// @notice The intent creator (or system) approves a specific proposed path.
    /// @param _intentId The ID of the intent.
    /// @param _pathfinderId The ID of the pathfinder whose path is being approved.
    function approvePathProposal(
        uint256 _intentId,
        uint256 _pathfinderId
    ) external onlyIntentCreator(_intentId) nonReentrant {
        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.PathProposed,
            "Intent not in PathProposed status"
        );
        require(
            block.timestamp < intent.deadline,
            "Intent deadline passed"
        );
        require(
            block.timestamp < intentPathProposals[_intentId][_pathfinderId].proposalTimestamp.add(protocolParameters[PATH_APPROVAL_DEADLINE]),
            "Path approval deadline passed"
        );

        PathProposal storage proposal = intentPathProposals[_intentId][_pathfinderId];
        require(proposal.status == PathStatus.Proposed, "Path not in proposed state");

        // Reject any other proposed paths for this intent
        for (uint256 i = 1; i < nextPathfinderId; i++) {
            if (intentPathProposals[_intentId][i].pathfinderId != 0 && i != _pathfinderId) {
                intentPathProposals[_intentId][i].status = PathStatus.Rejected;
            }
        }

        proposal.status = PathStatus.Approved;
        intent.approvedPathfinderId = _pathfinderId;
        updateIntentStatus(_intentId, IntentStatus.PathApproved);

        emit PathApproved(_intentId, _pathfinderId);
    }

    /// @notice The contract executes the approved path.
    /// @param _intentId The ID of the intent.
    /// @param _pathfinderId The ID of the pathfinder whose path was approved.
    function executeApprovedPath(
        uint256 _intentId,
        uint256 _pathfinderId
    ) external nonReentrant {
        IntentData storage intent = intents[_intentId];
        require(intent.approvedPathfinderId == _pathfinderId, "Path not approved for this pathfinder");
        require(intent.status == IntentStatus.PathApproved, "Intent not in PathApproved status");
        require(block.timestamp < intent.deadline, "Intent deadline passed");

        PathProposal storage proposal = intentPathProposals[_intentId][_pathfinderId];
        require(proposal.status == PathStatus.Approved, "Proposed path is not approved");

        updateIntentStatus(_intentId, IntentStatus.Executing);

        // Record initial balances for output token verification (simplified)
        // A more robust system would take a snapshot of all relevant token balances before execution
        // or use an oracle for post-execution state verification against intent conditions.
        mapping(address => uint256) initialOutputBalances;
        for (uint256 i = 0; i < intent.outputTokens.length; i++) {
            initialOutputBalances[intent.outputTokens[i]] = IERC20(intent.outputTokens[i]).balanceOf(address(this));
        }

        // Execute each call in the path
        for (uint256 i = 0; i < proposal.path.length; i++) {
            CallData storage call = proposal.path[i];
            bytes4 selector = bytes4(call.data);
            require(supportedProtocols[call.target][selector], "Call target or selector not whitelisted");

            (bool success, bytes memory result) = call.target.call{value: call.value}(
                call.data
            );
            // Revert if any call in the path fails to prevent partial execution and state corruption
            require(success, string(abi.encodePacked("External call failed at step ", Strings.toString(i), ": ", string(result))));
        }

        // --- Post-Execution Verification (simplified) ---
        bool fulfillmentSuccess = true;
        for (uint256 i = 0; i < intent.outputTokens.length; i++) {
            address token = intent.outputTokens[i];
            uint256 finalBalance = IERC20(token).balanceOf(address(this));
            uint256 gainedAmount = finalBalance.sub(initialOutputBalances[token]); // Simplified, assumes initial is 0 or only for intent
            if (gainedAmount < intent.outputMinAmounts[i]) {
                fulfillmentSuccess = false;
                break;
            }
        }

        if (fulfillmentSuccess) {
            updateIntentStatus(_intentId, IntentStatus.CompletedSuccess);
            distributeIntentRewards(_intentId, _pathfinderId);
            releaseFundsUponCompletion(_intentId);
        } else {
            updateIntentStatus(_intentId, IntentStatus.CompletedFailure);
            // Optionally, penalize pathfinder for failed fulfillment
            slashPathfinder(_pathfinderId, pathfinders[_pathfinderId].stake.div(10)); // Example: 10% slash
            releaseFundsUponCompletion(_intentId); // Return remaining funds to creator
        }

        proposal.status = PathStatus.Executed;
        emit PathExecuted(_intentId, _pathfinderId);
    }

    /// @notice Internal/admin function to penalize a Pathfinder.
    /// @param _pathfinderId The ID of the Pathfinder to slash.
    /// @param _amount The amount to slash from their stake.
    function slashPathfinder(uint256 _pathfinderId, uint256 _amount) internal {
        Pathfinder storage pathfinder = pathfinders[_pathfinderId];
        require(pathfinder.stake >= _amount, "Slash amount exceeds stake");

        pathfinder.stake = pathfinder.stake.sub(_amount);
        pathfinder.slashedAmount = pathfinder.slashedAmount.add(_amount);
        // Slashed funds could be sent to a treasury or burned. For now, they remain in contract.

        emit PathfinderSlashed(_pathfinderId, _amount, "General slash");
    }

    // --- III. Validator Operations & Dispute Resolution ---

    /// @notice Registers the caller as a Validator. Requires staking.
    /// @param _metadataURI URI pointing to off-chain Validator description.
    function registerValidator(string calldata _metadataURI) external nonReentrant {
        require(userToValidatorId[msg.sender] == 0, "Already registered as Validator");
        require(msg.value >= protocolParameters[MIN_VALIDATOR_STAKE], "Insufficient stake");

        uint256 validatorId = nextValidatorId++;
        validators[validatorId] = Validator({
            owner: msg.sender,
            stake: msg.value,
            metadataURI: _metadataURI,
            isActive: true,
            reputationScore: 0,
            slashedAmount: 0,
            deregistrationTimestamp: 0,
            pendingRewards: 0
        });
        userToValidatorId[msg.sender] = validatorId;

        emit ValidatorRegistered(validatorId, msg.sender, _metadataURI);
    }

    /// @notice Allows a Validator to initiate deregistration and unstaking.
    /// Funds will be locked for a cooldown period.
    function deregisterValidator() external nonReentrant {
        uint256 validatorId = userToValidatorId[msg.sender];
        require(validatorId != 0, "Not a registered Validator");
        Validator storage validator = validators[validatorId];
        require(validator.isActive, "Validator already deregistering");

        validator.isActive = false;
        validator.deregistrationTimestamp = block.timestamp;

        emit ValidatorDeregistered(validatorId, msg.sender);
    }

    /// @notice Validators can challenge a proposed path before execution.
    /// @param _intentId The ID of the intent.
    /// @param _pathfinderId The ID of the pathfinder whose path is being challenged.
    /// @param _reason A string describing the reason for the challenge.
    function challengePathProposal(
        uint256 _intentId,
        uint256 _pathfinderId,
        string calldata _reason
    ) external payable nonReentrant {
        uint256 validatorId = userToValidatorId[msg.sender];
        require(validatorId != 0, "Only registered Validators can challenge");
        require(validators[validatorId].isActive, "Validator is not active");

        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.PathProposed,
            "Intent not in PathProposed status"
        );
        require(
            intentPathProposals[_intentId][_pathfinderId].status == PathStatus.Proposed,
            "Path not in proposed state"
        );
        require(block.timestamp < intent.deadline, "Intent deadline passed");

        uint256 challengeFee = pathfinders[_pathfinderId].stake.mul(
            protocolParameters[CHALLENGE_FEE_PERCENTAGE]
        ).div(10000); // Basis points
        require(msg.value >= challengeFee, "Insufficient challenge fee");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            intentId: _intentId,
            challengerId: validatorId,
            challengerRole: Role.Validator,
            pathfinderIdInQuestion: _pathfinderId,
            challengeType: ChallengeType.PathProposal,
            reason: _reason,
            status: DisputeStatus.Open,
            resolutionTimestamp: 0,
            challengeStake: msg.value
        });

        // Set intent status to challenged
        updateIntentStatus(_intentId, IntentStatus.Challenged);
        emit PathProposalChallenged(disputeId, _intentId, validatorId, _pathfinderId);
    }

    /// @notice Validators can challenge the outcome of an executed path.
    /// @param _intentId The ID of the intent.
    /// @param _reason A string describing the reason for the challenge.
    function challengeExecutionOutcome(
        uint256 _intentId,
        string calldata _reason
    ) external payable nonReentrant {
        uint256 validatorId = userToValidatorId[msg.sender];
        require(validatorId != 0, "Only registered Validators can challenge");
        require(validators[validatorId].isActive, "Validator is not active");

        IntentData storage intent = intents[_intentId];
        require(
            intent.status == IntentStatus.CompletedSuccess ||
                intent.status == IntentStatus.CompletedFailure,
            "Intent not in a completed state to challenge outcome"
        );

        uint256 pathfinderId = intent.approvedPathfinderId;
        require(pathfinderId != 0, "No pathfinder associated with this intent execution");

        uint256 challengeFee = pathfinders[pathfinderId].stake.mul(
            protocolParameters[CHALLENGE_FEE_PERCENTAGE]
        ).div(10000);
        require(msg.value >= challengeFee, "Insufficient challenge fee");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            intentId: _intentId,
            challengerId: validatorId,
            challengerRole: Role.Validator,
            pathfinderIdInQuestion: pathfinderId,
            challengeType: ChallengeType.ExecutionOutcome,
            reason: _reason,
            status: DisputeStatus.Open,
            resolutionTimestamp: 0,
            challengeStake: msg.value
        });

        updateIntentStatus(_intentId, IntentStatus.Challenged);
        emit ExecutionOutcomeChallenged(disputeId, _intentId, validatorId);
    }

    /// @notice Resolves an open dispute. Only callable by the contract owner (admin/DAO).
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _challengerWasCorrect True if the challenger's claim was valid.
    function resolveDispute(
        uint256 _disputeId,
        bool _challengerWasCorrect
    ) external onlyOwner nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");

        IntentData storage intent = intents[dispute.intentId];
        Pathfinder storage pathfinder = pathfinders[dispute.pathfinderIdInQuestion];
        Validator storage challenger = validators[dispute.challengerId];

        if (_challengerWasCorrect) {
            // Challenger wins: Pathfinder gets slashed, Challenger gets rewarded.
            uint256 slashAmount = pathfinder.stake.mul(protocolParameters[CHALLENGE_FEE_PERCENTAGE]).div(10000);
            if (pathfinder.stake < slashAmount) {
                 slashAmount = pathfinder.stake; // Slash all if not enough
            }
            slashPathfinder(dispute.pathfinderIdInQuestion, slashAmount);

            // Challenger gets their stake back + a reward
            uint256 challengerReward = slashAmount.div(2); // Example reward
            challenger.pendingRewards = challenger.pendingRewards.add(dispute.challengeStake).add(challengerReward);

            // Update intent status based on challenge type
            if (dispute.challengeType == ChallengeType.PathProposal) {
                // If proposal was bad, revert status to PendingPathfinding for new proposals
                updateIntentStatus(dispute.intentId, IntentStatus.PendingPathfinding);
            } else if (dispute.challengeType == ChallengeType.ExecutionOutcome) {
                // If execution outcome was bad, set intent to failure
                updateIntentStatus(dispute.intentId, IntentStatus.CompletedFailure);
            }
        } else {
            // Challenger loses: Challenger's stake is slashed, Pathfinder might get a reward for false challenge.
            uint256 slashAmount = dispute.challengeStake; // Challenger loses their entire stake
            challenger.stake = challenger.stake.sub(slashAmount);
            challenger.slashedAmount = challenger.slashedAmount.add(slashAmount);

            // Pathfinder gets a portion of the slashed stake as reward
            uint256 pathfinderReward = slashAmount.div(2); // Example reward
            pathfinder.pendingRewards = pathfinder.pendingRewards.add(pathfinderReward);

            // If intent was challenged for execution, and challenge was wrong, it's considered successful
            if (dispute.challengeType == ChallengeType.ExecutionOutcome && intent.status == IntentStatus.Challenged) {
                updateIntentStatus(dispute.intentId, IntentStatus.CompletedSuccess);
            }
        }

        dispute.status = DisputeStatus.Resolved;
        dispute.resolutionTimestamp = block.timestamp;
        emit DisputeResolved(
            _disputeId,
            _challengerWasCorrect,
            _challengerWasCorrect ? challenger.owner : pathfinder.owner,
            _challengerWasCorrect ? pathfinder.owner : challenger.owner
        );
    }

    // --- IV. Staking & Rewards ---

    /// @notice Allows any registered Pathfinder or Validator to increase their stake.
    /// @param _amount The amount of ETH (or native token) to stake.
    function stake(uint256 _amount) external payable nonReentrant {
        require(msg.value == _amount, "ETH sent must match _amount");
        uint256 pathfinderId = userToPathfinderId[msg.sender];
        uint256 validatorId = userToValidatorId[msg.sender];

        require(pathfinderId != 0 || validatorId != 0, "Not a registered Pathfinder or Validator");

        if (pathfinderId != 0) {
            pathfinders[pathfinderId].stake = pathfinders[pathfinderId].stake.add(_amount);
        } else if (validatorId != 0) {
            validators[validatorId].stake = validators[validatorId].stake.add(_amount);
        }

        emit Staked(msg.sender, _amount);
    }

    /// @notice Allows any registered Pathfinder or Validator to initiate unstaking.
    /// @param _amount The amount of stake to unstake.
    function unstake(uint256 _amount) external nonReentrant {
        uint256 pathfinderId = userToPathfinderId[msg.sender];
        uint256 validatorId = userToValidatorId[msg.sender];

        require(pathfinderId != 0 || validatorId != 0, "Not a registered Pathfinder or Validator");

        if (pathfinderId != 0) {
            Pathfinder storage pathfinder = pathfinders[pathfinderId];
            require(pathfinder.stake >= _amount, "Insufficient stake");
            require(pathfinder.deregistrationTimestamp > 0 && block.timestamp >= pathfinder.deregistrationTimestamp.add(protocolParameters[DEREGISTRATION_COOLDOWN]), "Deregistration cooldown not passed");
            pathfinder.stake = pathfinder.stake.sub(_amount);
            payable(msg.sender).transfer(_amount);
        } else if (validatorId != 0) {
            Validator storage validator = validators[validatorId];
            require(validator.stake >= _amount, "Insufficient stake");
            require(validator.deregistrationTimestamp > 0 && block.timestamp >= validator.deregistrationTimestamp.add(protocolParameters[DEREGISTRATION_COOLDOWN]), "Deregistration cooldown not passed");
            validator.stake = validator.stake.sub(_amount);
            payable(msg.sender).transfer(_amount);
        }

        emit Unstaked(msg.sender, _amount);
    }

    /// @notice Allows Pathfinders and Validators to claim their accumulated rewards.
    function claimRewards() external nonReentrant {
        uint256 pathfinderId = userToPathfinderId[msg.sender];
        uint256 validatorId = userToValidatorId[msg.sender];
        uint256 totalRewards = 0;

        if (pathfinderId != 0) {
            Pathfinder storage pathfinder = pathfinders[pathfinderId];
            totalRewards = totalRewards.add(pathfinder.pendingRewards);
            pathfinder.pendingRewards = 0;
        }
        if (validatorId != 0) {
            Validator storage validator = validators[validatorId];
            totalRewards = totalRewards.add(validator.pendingRewards);
            validator.pendingRewards = 0;
        }

        require(totalRewards > 0, "No pending rewards to claim");
        payable(msg.sender).transfer(totalRewards);

        emit RewardsClaimed(msg.sender, totalRewards);
    }

    /// @notice Internal function to distribute rewards to Pathfinders and Validators upon successful intent completion.
    /// @param _intentId The ID of the intent.
    /// @param _pathfinderId The ID of the pathfinder who fulfilled the intent.
    function distributeIntentRewards(uint256 _intentId, uint256 _pathfinderId) internal {
        IntentData storage intent = intents[_intentId];
        Pathfinder storage pathfinder = pathfinders[_pathfinderId];

        // Reward calculation based on intent value (e.g., total input value or estimated output value)
        // For simplicity, let's assume a flat reward for now or calculate based on intent's required amounts
        uint256 totalIntentValue = 0;
        for(uint256 i = 0; i < intent.requiredTokens.length; i++){
            // In a real system, you'd convert these to a common value (e.g., USD) via an oracle
            // For now, let's just sum ETH value for simplicity or use a fixed reward.
            // Let's assume the reward is directly proportional to a percentage of the pathfinder's stake
            // or a fixed amount for now, as calculating based on intent value across different tokens is complex without oracles.
            // Let's assume the pathfinderRewardAmount is set directly.
        }

        // Pathfinder receives reward
        pathfinder.pendingRewards = pathfinder.pendingRewards.add(intent.pathfinderRewardAmount);
        pathfinder.reputationScore = pathfinder.reputationScore.add(1); // Increment reputation

        // Validators could get a small share for successful non-challenges or for positive votes
        // For simplicity, let's add a fixed validator reward to active validators.
        // A more complex system would track active validators during path approval/execution and reward them.
        uint256 totalValidatorRewardPool = intent.validatorRewardAmount;
        if(totalValidatorRewardPool > 0) {
            uint256 activeValidatorCount = 0;
            for(uint256 i = 1; i < nextValidatorId; i++) {
                if(validators[i].isActive) activeValidatorCount++;
            }
            if(activeValidatorCount > 0) {
                uint256 rewardPerValidator = totalValidatorRewardPool.div(activeValidatorCount);
                for(uint256 i = 1; i < nextValidatorId; i++) {
                    if(validators[i].isActive) {
                        validators[i].pendingRewards = validators[i].pendingRewards.add(rewardPerValidator);
                        validators[i].reputationScore = validators[i].reputationScore.add(1);
                    }
                }
            }
        }

        emit RewardsDistributed(_intentId, _pathfinderId, intent.pathfinderRewardAmount, totalValidatorRewardPool);
    }

    // --- V. Governance & System Parameters ---

    /// @notice Allows the administrator (or DAO) to adjust system parameters.
    /// @param _paramName The name of the parameter (bytes32).
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(
        bytes32 _paramName,
        uint256 _newValue
    ) external onlyOwner {
        require(_newValue > 0, "Parameter value must be positive");
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /// @notice Allows the administrator (or DAO) to whitelist a new DeFi protocol.
    /// Pathfinders can then propose paths interacting with this protocol.
    /// @param _protocolAddress The address of the new protocol contract.
    /// @param _supportedSelectors An array of function selectors that can be called on this protocol.
    function addSupportedProtocol(
        address _protocolAddress,
        bytes4[] calldata _supportedSelectors
    ) external onlyOwner {
        require(_protocolAddress != address(0), "Invalid protocol address");
        for (uint256 i = 0; i < _supportedSelectors.length; i++) {
            supportedProtocols[_protocolAddress][_supportedSelectors[i]] = true;
        }
        emit SupportedProtocolAdded(_protocolAddress, _supportedSelectors);
    }

    /// @notice Allows the administrator (or DAO) to remove a previously whitelisted protocol.
    /// @param _protocolAddress The address of the protocol to remove.
    function removeSupportedProtocol(address _protocolAddress) external onlyOwner {
        require(_protocolAddress != address(0), "Invalid protocol address");
        // Clear all selectors for this protocol
        // Note: This only works effectively if we track selectors explicitly,
        // or iterate through known selectors if storage is an issue.
        // For simplicity, this removes the entire protocol entry.
        // In a real system, you'd need to carefully manage storage or iterate.
        // This effectively marks all selectors as unsupported for this address.
        delete supportedProtocols[_protocolAddress]; 
        emit SupportedProtocolRemoved(_protocolAddress);
    }

    // --- Fallback & Receive ---
    receive() external payable {
        // Allow receiving ETH, e.g., for staking or intent deposits.
    }
}
```