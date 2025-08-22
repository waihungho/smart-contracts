The "Æther Weaver Protocol" is a sophisticated, AI-driven decentralized prediction and action engine designed to leverage collective intelligence and automated execution on the blockchain. It enables a novel form of decentralized autonomous agents (DAAs) by integrating off-chain AI model predictions with on-chain smart contract actions.

---

## Æther Weaver Protocol: Outline & Function Summary

**Outline:**

1.  **Imports & Interfaces:** External contract interactions, e.g., for `ERC20` (if used for staking, will use native ETH for simplicity).
2.  **Errors & Events:** Custom errors for gas efficiency and informative events for off-chain monitoring.
3.  **Enums:** Define states for Scenarios and Autonomous Actions.
4.  **Structs:** Data models for Scenarios, AI Oracle Agents, Predictions, and Autonomous Action Requests.
5.  **Core Contract: ÆtherWeaver**
    *   **A. State Variables:** Storage for fees, counters, mappings of structs, and administrative addresses.
    *   **B. Modifiers:** Access control (`onlyOwner`, `onlyRegisteredAgent`, `nonReentrant`), state checks.
    *   **C. Constructor:** Initializes the protocol owner and base fees.
    *   **D. Protocol Management (Owner/Admin):** Functions for setting fees, pausing the protocol, and withdrawing funds.
    *   **E. AI Oracle Agent Management:** Registration, updates, and deactivation for AI models participating in predictions.
    *   **F. Scenario Management:** Creation, approval, and cancellation of predictive scenarios.
    *   **G. Prediction & Staking:** AI agents submit predictions for scenarios, staking funds to back their accuracy.
    *   **H. Scenario Resolution & Rewards:** Trusted oracle submits the scenario outcome, triggering reward distribution and stake slashing based on prediction accuracy.
    *   **I. Autonomous Action Management:** Create requests for on-chain actions to be triggered upon specific scenario outcomes.
    *   **J. Reputation & Efficacy Voting:** Community votes on the perceived efficacy of AI agents, influencing their reputation scores.
    *   **K. Internal/Utility Functions (View/Pure):** Read-only functions to query protocol state, details of scenarios, agents, and predictions.

**Function Summary (26+ functions):**

**I. Protocol Management (Owner/Admin):**
1.  `constructor()`: Initializes the contract, setting the owner and default fees.
2.  `setProtocolFee(uint256 _newFeeBasisPoints)`: Owner sets the protocol's cut from successful predictions (in basis points).
3.  `setAgentRegistrationFee(uint256 _newFee)`: Owner sets the fee required for AI agents to register.
4.  `setScenarioCreationFee(uint256 _newFee)`: Owner sets the fee for proposing a new predictive scenario.
5.  `setTrustedOutcomeOracle(address _oracle)`: Owner sets the address of the trusted oracle responsible for submitting scenario outcomes.
6.  `pauseProtocol()`: Owner can pause core functionalities in an emergency.
7.  `unpauseProtocol()`: Owner can unpause the protocol.
8.  `withdrawProtocolFunds(address _to, uint256 _amount)`: Owner can withdraw accumulated protocol fees.

**II. AI Oracle Agent Management:**
9.  `registerAIOracleAgent(string calldata _agentURI)`: An AI model registers, paying a fee, and providing a URI describing its capabilities.
10. `updateAIOracleAgentURI(string calldata _newAgentURI)`: A registered agent updates its descriptive URI.
11. `deactivateAIOracleAgent()`: An agent can temporarily deactivate their participation (e.g., for maintenance).
12. `reactivateAIOracleAgent()`: An agent reactivates their participation.

**III. Scenario Management:**
13. `proposeScenario(string calldata _descriptionHash, uint256 _targetDate)`: User proposes a new predictive scenario, paying a fee. `_descriptionHash` points to off-chain details.
14. `approveScenario(uint256 _scenarioId)`: Admin/Owner approves a proposed scenario, making it active for predictions.
15. `cancelScenarioProposal(uint256 _scenarioId)`: Proposer can cancel their unapproved scenario proposal.

**IV. Prediction & Staking:**
16. `submitAIOraclePrediction(uint256 _scenarioId, uint256 _predictionValue, uint256 _stakeAmount)`: Registered AI agent submits a prediction for an approved scenario, staking tokens to back it. `_predictionValue` is a numerical representation of the outcome (e.g., 0 for False, 1 for True, or a specific price point).

**V. Scenario Resolution & Rewards:**
17. `submitScenarioOutcome(uint256 _scenarioId, uint256 _resolvedOutcome)`: Trusted outcome oracle submits the final outcome of a scenario after its target date.
18. `distributeScenarioRewards(uint256 _scenarioId)`: Callable by anyone after `submitScenarioOutcome`. It calculates and distributes rewards/slashes stakes for the given scenario.
19. `claimAIOracleReward(uint256 _agentId)`: AI agent claims their earned rewards from accurate predictions.
20. `claimScenarioProposerReward(uint256 _scenarioId)`: Scenario proposer claims their reward if the scenario was successfully resolved.

**VI. Autonomous Action Management:**
21. `createAutonomousActionRequest(uint256 _scenarioId, address _targetContract, bytes calldata _callData)`: A user requests an autonomous action to be executed if a specific scenario resolves with a high-confidence prediction. `_callData` specifies the function and parameters to call on `_targetContract`.
22. `executeAutonomousAction(uint256 _actionRequestId)`: A permissionless function (e.g., by a relayer/keeper) to trigger an autonomous action if its linked scenario has been successfully resolved and meets the confidence threshold.

**VII. Reputation & Efficacy Voting:**
23. `voteOnAIOracleEfficacy(uint256 _agentId, bool _isEffective)`: Community members vote on the perceived efficacy or trustworthiness of an AI agent. This influences their reputation.

**VIII. Viewing Functions (Read-only):**
24. `getScenarioDetails(uint256 _scenarioId)`: Retrieves all details of a specific scenario.
25. `getAIOracleAgentDetails(uint256 _agentId)`: Retrieves details of an AI agent, including its reputation.
26. `getPredictionDetails(uint256 _predictionId)`: Retrieves details of a specific prediction made by an agent.
27. `getAutonomousActionRequestDetails(uint256 _actionRequestId)`: Retrieves details of an autonomous action request.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline:
// 1. Imports & Interfaces (None explicitly needed for basic ETH operations)
// 2. Errors & Events
// 3. Enums
// 4. Structs
// 5. Core Contract: ÆtherWeaver
//    A. State Variables
//    B. Modifiers
//    C. Constructor
//    D. Protocol Management (Owner/Admin)
//    E. AI Oracle Agent Management
//    F. Scenario Management
//    G. Prediction & Staking
//    H. Scenario Resolution & Rewards
//    I. Autonomous Action Management
//    J. Reputation & Efficacy Voting
//    K. Internal/Utility Functions (View/Pure)

// Function Summary:
// I. Protocol Management (Owner/Admin):
// 1. constructor(): Initializes the contract, setting the owner and default fees.
// 2. setProtocolFee(uint256 _newFeeBasisPoints): Owner sets the protocol's cut from successful predictions (in basis points).
// 3. setAgentRegistrationFee(uint256 _newFee): Owner sets the fee required for AI agents to register.
// 4. setScenarioCreationFee(uint256 _newFee): Owner sets the fee for proposing a new predictive scenario.
// 5. setTrustedOutcomeOracle(address _oracle): Owner sets the address of the trusted oracle for outcome submission.
// 6. pauseProtocol(): Owner can pause core functionalities in an emergency.
// 7. unpauseProtocol(): Owner can unpause the protocol.
// 8. withdrawProtocolFunds(address _to, uint256 _amount): Owner can withdraw accumulated protocol fees.

// II. AI Oracle Agent Management:
// 9. registerAIOracleAgent(string calldata _agentURI): An AI model registers, paying a fee, and providing a URI.
// 10. updateAIOracleAgentURI(string calldata _newAgentURI): A registered agent updates its descriptive URI.
// 11. deactivateAIOracleAgent(): An agent can temporarily deactivate their participation.
// 12. reactivateAIOracleAgent(): An agent reactivates their participation.

// III. Scenario Management:
// 13. proposeScenario(string calldata _descriptionHash, uint256 _targetDate): User proposes a new predictive scenario, paying a fee.
// 14. approveScenario(uint256 _scenarioId): Admin/Owner approves a proposed scenario, making it active for predictions.
// 15. cancelScenarioProposal(uint256 _scenarioId): Proposer can cancel their unapproved scenario proposal.

// IV. Prediction & Staking:
// 16. submitAIOraclePrediction(uint256 _scenarioId, uint256 _predictionValue, uint256 _stakeAmount): Registered AI agent submits a prediction for an approved scenario, staking tokens.

// V. Scenario Resolution & Rewards:
// 17. submitScenarioOutcome(uint256 _scenarioId, uint256 _resolvedOutcome): Trusted outcome oracle submits the final outcome.
// 18. distributeScenarioRewards(uint256 _scenarioId): Calculates and distributes rewards/slashes stakes.
// 19. claimAIOracleReward(uint256 _agentId): AI agent claims their earned rewards.
// 20. claimScenarioProposerReward(uint256 _scenarioId): Scenario proposer claims their reward.

// VI. Autonomous Action Management:
// 21. createAutonomousActionRequest(uint256 _scenarioId, address _targetContract, bytes calldata _callData): Requests an action upon scenario resolution.
// 22. executeAutonomousAction(uint256 _actionRequestId): Triggers an autonomous action if its linked scenario resolves successfully.

// VII. Reputation & Efficacy Voting:
// 23. voteOnAIOracleEfficacy(uint256 _agentId, bool _isEffective): Community members vote on the perceived efficacy of an AI agent.

// VIII. Viewing Functions (Read-only):
// 24. getScenarioDetails(uint256 _scenarioId): Retrieves all details of a specific scenario.
// 25. getAIOracleAgentDetails(uint256 _agentId): Retrieves details of an AI agent, including its reputation.
// 26. getPredictionDetails(uint256 _predictionId): Retrieves details of a specific prediction.
// 27. getAutonomousActionRequestDetails(uint256 _actionRequestId): Retrieves details of an autonomous action request.


// For reentrancy protection (standard pattern, not duplicating full library code)
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == _ENTERED) {
            revert ReentrantCall();
        }
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

// 2. Errors & Events
error NotOwner();
error ProtocolPaused();
error ProtocolNotPaused();
error InvalidFee();
error InsufficientFunds();
error AgentAlreadyRegistered();
error AgentNotRegistered();
error AgentNotActive();
error ScenarioNotFound();
error ScenarioNotInProposedState();
error ScenarioNotInApprovedState();
error ScenarioAlreadyResolved();
error ScenarioNotResolved();
error ScenarioOutcomeNotSubmitted();
error PredictionNotFound();
error PredictionTooLate();
error PredictionAlreadySubmitted();
error InvalidStakeAmount();
error OnlyTrustedOutcomeOracle();
error ReentrantCall();
error ActionRequestNotFound();
error ActionRequestNotExecutable();
error ActionAlreadyExecuted();
error InvalidReputationVote();
error Unauthorized();

event ProtocolFeeSet(uint256 newFeeBasisPoints);
event AgentRegistrationFeeSet(uint256 newFee);
event ScenarioCreationFeeSet(uint256 newFee);
event TrustedOutcomeOracleSet(address newOracle);
event ProtocolPausedEvent();
event ProtocolUnpausedEvent();
event FundsWithdrawn(address indexed to, uint256 amount);

event AIOracleAgentRegistered(uint256 indexed agentId, address indexed owner, string agentURI);
event AIOracleAgentURIDisclosed(uint256 indexed agentId, string agentURI);
event AIOracleAgentDeactivated(uint256 indexed agentId);
event AIOracleAgentReactivated(uint256 indexed agentId);

event ScenarioProposed(uint256 indexed scenarioId, address indexed proposer, string descriptionHash, uint256 targetDate, uint256 creationFee);
event ScenarioApproved(uint256 indexed scenarioId);
event ScenarioCancelled(uint256 indexed scenarioId);
event ScenarioOutcomeSubmitted(uint256 indexed scenarioId, uint256 resolvedOutcome);
event ScenarioRewardsDistributed(uint256 indexed scenarioId, uint256 totalRewardPool);

event AIOraclePredictionSubmitted(uint256 indexed predictionId, uint256 indexed scenarioId, uint256 indexed agentId, uint256 predictionValue, uint256 stakeAmount);
event AIOracleRewardClaimed(uint256 indexed agentId, uint256 amount);
event ScenarioProposerRewardClaimed(uint256 indexed scenarioId, uint256 amount);

event AutonomousActionRequested(uint256 indexed requestId, uint256 indexed scenarioId, address targetContract);
event AutonomousActionExecuted(uint256 indexed requestId, uint256 indexed scenarioId, bool success);

event AIOracleEfficacyVoted(uint256 indexed voter, uint256 indexed agentId, bool isEffective);


// 3. Enums
enum ScenarioStatus {
    Proposed,
    Approved,
    Resolved,
    Cancelled
}

enum ActionStatus {
    Pending,
    Executed,
    Failed
}

// 4. Structs
struct Scenario {
    uint256 id;
    address proposer;
    string descriptionHash; // IPFS/Arweave hash for detailed scenario description
    uint256 targetDate;    // Timestamp when the scenario should resolve
    ScenarioStatus status;
    uint256 creationFee;   // Fee paid by proposer
    uint256 resolvedOutcome; // The actual outcome once submitted
    bool outcomeSubmitted;
    uint256 totalStaked;   // Total ETH staked across all predictions for this scenario
    uint256 distributedRewardPool; // Total rewards distributed for this scenario
    uint256 proposerRewardAmount; // Specific reward for the proposer
}

struct AIOracleAgent {
    uint256 id;
    address owner;
    string agentURI;      // IPFS/Arweave hash for agent's description, model details
    int256 reputationScore; // Can be negative for poor performance
    bool isActive;        // Can be deactivated by agent or protocol (e.g., if reputation is too low)
    uint256 registrationFee;
    uint256 totalRewardsEarned;
    uint256 totalStaked;
    uint256 successfulPredictions;
    uint256 failedPredictions;
}

struct Prediction {
    uint256 id;
    uint256 scenarioId;
    uint256 agentId;
    uint256 predictionValue; // Represents the predicted outcome (e.g., 0, 1, or a specific number)
    uint256 stakedAmount;    // ETH staked by the AI agent
    bool isRewarded;         // True if the agent was rewarded for this prediction
    bool isClaimed;          // True if the reward has been claimed
}

struct AutonomousActionRequest {
    uint256 id;
    uint256 scenarioId;
    address targetContract; // Contract to call
    bytes callData;         // Function signature and encoded parameters
    ActionStatus status;
}

// 5. Core Contract: ÆtherWeaver
contract ÆtherWeaver is ReentrancyGuard {
    // A. State Variables
    address public owner;
    address public trustedOutcomeOracle; // Can be owner initially, or a DAO/multi-sig later

    uint256 public protocolFeeBasisPoints; // e.g., 100 = 1%
    uint256 public agentRegistrationFee;
    uint256 public scenarioCreationFee;

    bool public paused;

    uint256 private _nextScenarioId;
    uint256 private _nextAgentId;
    uint256 private _nextPredictionId;
    uint256 private _nextActionRequestId;

    mapping(uint256 => Scenario) public scenarios;
    mapping(uint256 => AIOracleAgent) public aiOracleAgents;
    mapping(address => uint256) public agentAddressToId; // Map agent owner address to agentId
    mapping(uint256 => Prediction) public predictions;
    mapping(uint256 => AutonomousActionRequest) public autonomousActionRequests;

    mapping(uint256 => mapping(uint256 => bool)) public scenarioAgentPredictions; // scenarioId => agentId => hasPredicted

    // Funds management
    mapping(address => uint256) public _rewards; // For agents and scenario proposers to claim
    uint256 public protocolFunds; // Accumulated fees

    // B. Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyTrustedOutcomeOracle() {
        if (msg.sender != trustedOutcomeOracle) revert OnlyTrustedOutcomeOracle();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ProtocolPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ProtocolNotPaused();
        _;
    }

    modifier onlyRegisteredAgent() {
        if (agentAddressToId[msg.sender] == 0) revert AgentNotRegistered();
        if (!aiOracleAgents[agentAddressToId[msg.sender]].isActive) revert AgentNotActive();
        _;
    }

    // C. Constructor
    constructor() {
        owner = msg.sender;
        trustedOutcomeOracle = msg.sender; // Owner is the initial trusted oracle
        protocolFeeBasisPoints = 500; // 5%
        agentRegistrationFee = 0.05 ether;
        scenarioCreationFee = 0.01 ether;
        _nextScenarioId = 1;
        _nextAgentId = 1;
        _nextPredictionId = 1;
        _nextActionRequestId = 1;
        paused = false;
    }

    // D. Protocol Management (Owner/Admin)
    function setProtocolFee(uint256 _newFeeBasisPoints) external onlyOwner {
        if (_newFeeBasisPoints > 10000) revert InvalidFee(); // Max 100%
        protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeSet(_newFeeBasisPoints);
    }

    function setAgentRegistrationFee(uint256 _newFee) external onlyOwner {
        agentRegistrationFee = _newFee;
        emit AgentRegistrationFeeSet(_newFee);
    }

    function setScenarioCreationFee(uint256 _newFee) external onlyOwner {
        scenarioCreationFee = _newFee;
        emit ScenarioCreationFeeSet(_newFee);
    }

    function setTrustedOutcomeOracle(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert InvalidFee(); // Address 0 is invalid
        trustedOutcomeOracle = _oracle;
        emit TrustedOutcomeOracleSet(_oracle);
    }

    function pauseProtocol() external onlyOwner whenNotPaused {
        paused = true;
        emit ProtocolPausedEvent();
    }

    function unpauseProtocol() external onlyOwner whenPaused {
        paused = false;
        emit ProtocolUnpausedEvent();
    }

    function withdrawProtocolFunds(address _to, uint256 _amount) external onlyOwner nonReentrant {
        if (_amount == 0 || _amount > protocolFunds) revert InsufficientFunds();
        protocolFunds -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert Unauthorized(); // Should not revert unless receiver is problematic
        emit FundsWithdrawn(_to, _amount);
    }

    // E. AI Oracle Agent Management
    function registerAIOracleAgent(string calldata _agentURI) external payable whenNotPaused {
        if (agentAddressToId[msg.sender] != 0) revert AgentAlreadyRegistered();
        if (msg.value < agentRegistrationFee) revert InsufficientFunds();

        uint256 newAgentId = _nextAgentId++;
        aiOracleAgents[newAgentId] = AIOracleAgent({
            id: newAgentId,
            owner: msg.sender,
            agentURI: _agentURI,
            reputationScore: 0, // Starts neutral
            isActive: true,
            registrationFee: msg.value,
            totalRewardsEarned: 0,
            totalStaked: 0,
            successfulPredictions: 0,
            failedPredictions: 0
        });
        agentAddressToId[msg.sender] = newAgentId;
        protocolFunds += msg.value; // Add fee to protocol funds
        emit AIOracleAgentRegistered(newAgentId, msg.sender, _agentURI);
    }

    function updateAIOracleAgentURI(string calldata _newAgentURI) external onlyRegisteredAgent {
        uint256 agentId = agentAddressToId[msg.sender];
        aiOracleAgents[agentId].agentURI = _newAgentURI;
        emit AIOracleAgentURIDisclosed(agentId, _newAgentURI);
    }

    function deactivateAIOracleAgent() external onlyRegisteredAgent {
        uint256 agentId = agentAddressToId[msg.sender];
        aiOracleAgents[agentId].isActive = false;
        emit AIOracleAgentDeactivated(agentId);
    }

    function reactivateAIOracleAgent() external onlyRegisteredAgent {
        uint256 agentId = agentAddressToId[msg.sender];
        aiOracleAgents[agentId].isActive = true;
        emit AIOracleAgentReactivated(agentId);
    }

    // F. Scenario Management
    function proposeScenario(string calldata _descriptionHash, uint256 _targetDate) external payable whenNotPaused returns (uint256) {
        if (msg.value < scenarioCreationFee) revert InsufficientFunds();
        if (_targetDate <= block.timestamp) revert PredictionTooLate(); // Target date must be in the future

        uint256 newScenarioId = _nextScenarioId++;
        scenarios[newScenarioId] = Scenario({
            id: newScenarioId,
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            targetDate: _targetDate,
            status: ScenarioStatus.Proposed,
            creationFee: msg.value,
            resolvedOutcome: 0, // Default for unresolved
            outcomeSubmitted: false,
            totalStaked: 0,
            distributedRewardPool: 0,
            proposerRewardAmount: 0
        });
        protocolFunds += msg.value; // Add fee to protocol funds
        emit ScenarioProposed(newScenarioId, msg.sender, _descriptionHash, _targetDate, msg.value);
        return newScenarioId;
    }

    function approveScenario(uint256 _scenarioId) external onlyOwner {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.status != ScenarioStatus.Proposed) revert ScenarioNotInProposedState();

        scenario.status = ScenarioStatus.Approved;
        emit ScenarioApproved(_scenarioId);
    }

    function cancelScenarioProposal(uint256 _scenarioId) external nonReentrant {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.proposer != msg.sender) revert Unauthorized();
        if (scenario.status != ScenarioStatus.Proposed) revert ScenarioNotInProposedState();

        scenario.status = ScenarioStatus.Cancelled;
        // Refund creation fee
        (bool success, ) = scenario.proposer.call{value: scenario.creationFee}("");
        if (!success) revert Unauthorized(); // Refund failed
        protocolFunds -= scenario.creationFee; // Deduct from protocol funds
        emit ScenarioCancelled(_scenarioId);
    }

    // G. Prediction & Staking
    function submitAIOraclePrediction(uint256 _scenarioId, uint256 _predictionValue, uint256 _stakeAmount) external payable whenNotPaused onlyRegisteredAgent {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.status != ScenarioStatus.Approved) revert ScenarioNotInApprovedState();
        if (block.timestamp >= scenario.targetDate) revert PredictionTooLate();
        if (_stakeAmount == 0) revert InvalidStakeAmount();
        if (msg.value < _stakeAmount) revert InsufficientFunds();

        uint256 agentId = agentAddressToId[msg.sender];
        if (scenarioAgentPredictions[_scenarioId][agentId]) revert PredictionAlreadySubmitted();

        uint256 newPredictionId = _nextPredictionId++;
        predictions[newPredictionId] = Prediction({
            id: newPredictionId,
            scenarioId: _scenarioId,
            agentId: agentId,
            predictionValue: _predictionValue,
            stakedAmount: msg.value,
            isRewarded: false,
            isClaimed: false
        });

        scenarioAgentPredictions[_scenarioId][agentId] = true;
        scenario.totalStaked += msg.value;
        aiOracleAgents[agentId].totalStaked += msg.value;

        // Remaining value (if any) is sent back
        if (msg.value > _stakeAmount) {
            (bool success, ) = msg.sender.call{value: msg.value - _stakeAmount}("");
            if (!success) revert Unauthorized(); // Refund failed
        }
        
        emit AIOraclePredictionSubmitted(newPredictionId, _scenarioId, agentId, _predictionValue, _stakeAmount);
    }

    // H. Scenario Resolution & Rewards
    function submitScenarioOutcome(uint256 _scenarioId, uint256 _resolvedOutcome) external onlyTrustedOutcomeOracle {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.status != ScenarioStatus.Approved) revert ScenarioNotInApprovedState();
        if (block.timestamp < scenario.targetDate) revert ScenarioNotResolved(); // Outcome cannot be submitted before target date
        if (scenario.outcomeSubmitted) revert ScenarioAlreadyResolved();

        scenario.resolvedOutcome = _resolvedOutcome;
        scenario.outcomeSubmitted = true;
        scenario.status = ScenarioStatus.Resolved;
        emit ScenarioOutcomeSubmitted(_scenarioId, _resolvedOutcome);
    }

    function distributeScenarioRewards(uint256 _scenarioId) external nonReentrant {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (!scenario.outcomeSubmitted) revert ScenarioOutcomeNotSubmitted();
        if (scenario.distributedRewardPool > 0) return; // Already distributed

        uint256 totalRewardPool = scenario.totalStaked + scenario.creationFee; // All stakes + creation fee
        uint256 totalSuccessfulStakes = 0;

        // First pass: Calculate successful stakes and total reward pool
        // This is inefficient for many predictions, but simpler for this example.
        // A more advanced system would use a Merkle tree or off-chain aggregation.
        uint256[] memory predictionIds = new uint256[](_nextPredictionId - 1);
        uint256 predictionCount = 0;

        for (uint256 i = 1; i < _nextPredictionId; i++) {
            if (predictions[i].scenarioId == _scenarioId) {
                predictionIds[predictionCount++] = i;
                if (predictions[i].predictionValue == scenario.resolvedOutcome) {
                    totalSuccessfulStakes += predictions[i].stakedAmount;
                }
            }
        }

        uint256 protocolCut = (totalRewardPool * protocolFeeBasisPoints) / 10000;
        protocolFunds += protocolCut;
        totalRewardPool -= protocolCut;

        uint256 proposerReward = (scenario.creationFee * 2) / 100; // 2% of creation fee, simple example
        if (proposerReward > totalRewardPool) proposerReward = totalRewardPool;
        scenario.proposerRewardAmount = proposerReward;
        totalRewardPool -= proposerReward;


        // Second pass: Distribute rewards
        for (uint256 i = 0; i < predictionCount; i++) {
            Prediction storage prediction = predictions[predictionIds[i]];
            AIOracleAgent storage agent = aiOracleAgents[prediction.agentId];

            if (prediction.predictionValue == scenario.resolvedOutcome) {
                // Agent was correct: get stake back + share of profit
                uint256 rewardShare = 0;
                if (totalSuccessfulStakes > 0) {
                     rewardShare = (prediction.stakedAmount * totalRewardPool) / totalSuccessfulStakes;
                }
                
                uint256 totalPayout = prediction.stakedAmount + rewardShare;
                _rewards[agent.owner] += totalPayout;
                agent.totalRewardsEarned += totalPayout;
                agent.successfulPredictions++;
                agent.reputationScore += 10; // Positive reputation
                prediction.isRewarded = true;
            } else {
                // Agent was incorrect: stake is slashed and added to the pool implicitly
                agent.failedPredictions++;
                agent.reputationScore -= 5; // Negative reputation
            }
        }

        scenario.distributedRewardPool = totalRewardPool + protocolCut + proposerReward; // Track total distributed
        emit ScenarioRewardsDistributed(_scenarioId, scenario.distributedRewardPool);
    }

    function claimAIOracleReward(uint256 _agentId) external nonReentrant {
        AIOracleAgent storage agent = aiOracleAgents[_agentId];
        if (agent.owner != msg.sender) revert Unauthorized();
        if (_rewards[msg.sender] == 0) revert InsufficientFunds();

        uint256 amount = _rewards[msg.sender];
        _rewards[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Unauthorized(); // Revert if transfer fails
        emit AIOracleRewardClaimed(_agentId, amount);
    }

    function claimScenarioProposerReward(uint256 _scenarioId) external nonReentrant {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.proposer != msg.sender) revert Unauthorized();
        if (!scenario.outcomeSubmitted) revert ScenarioOutcomeNotSubmitted();
        if (scenario.proposerRewardAmount == 0) revert InsufficientFunds(); // Or already claimed

        uint256 amount = scenario.proposerRewardAmount;
        scenario.proposerRewardAmount = 0; // Mark as claimed
        _rewards[msg.sender] += amount; // Add to general reward balance for proposer to claim
        emit ScenarioProposerRewardClaimed(_scenarioId, amount);

        // Actual ETH transfer happens via claimAIOracleReward (or a dedicated claimProposerReward if separate balance is needed)
        // For simplicity, I'm funneling to a shared _rewards mapping for the address
    }

    // I. Autonomous Action Management
    function createAutonomousActionRequest(uint256 _scenarioId, address _targetContract, bytes calldata _callData) external payable whenNotPaused returns (uint256) {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        if (scenario.status != ScenarioStatus.Approved) revert ScenarioNotInApprovedState();
        if (block.timestamp >= scenario.targetDate) revert PredictionTooLate();

        // Optional: Require a fee for action requests, or a stake to prevent spam
        // For now, no extra fee, just the ability to attach ETH for the action.

        uint256 newActionRequestId = _nextActionRequestId++;
        autonomousActionRequests[newActionRequestId] = AutonomousActionRequest({
            id: newActionRequestId,
            scenarioId: _scenarioId,
            targetContract: _targetContract,
            callData: _callData,
            status: ActionStatus.Pending
        });
        // If there's an attached value, it's held by the ÆtherWeaver contract to be sent with the callData
        if (msg.value > 0) {
            _rewards[address(this)] += msg.value; // Temporarily hold value in protocol's general balance
        }

        emit AutonomousActionRequested(newActionRequestId, _scenarioId, _targetContract);
        return newActionRequestId;
    }

    function executeAutonomousAction(uint256 _actionRequestId) external nonReentrant {
        AutonomousActionRequest storage actionRequest = autonomousActionRequests[_actionRequestId];
        if (actionRequest.id == 0) revert ActionRequestNotFound();
        if (actionRequest.status != ActionStatus.Pending) revert ActionAlreadyExecuted();

        Scenario storage scenario = scenarios[actionRequest.scenarioId];
        if (!scenario.outcomeSubmitted) revert ScenarioOutcomeNotSubmitted();
        
        // This is a simplified condition. In a real system, you'd need a "confidence threshold"
        // based on the number/stake of accurate AI predictions for the scenario.
        // For this example, we assume if the scenario is resolved, it's actionable if it met some implicit condition.
        // Let's say any scenario resolution is enough for now, or you could add a 'scenario.isActionable' flag.

        // Placeholder for confidence check:
        // uint256 successfulAgents = 0;
        // for (uint256 i = 1; i < _nextPredictionId; i++) {
        //     if (predictions[i].scenarioId == actionRequest.scenarioId && predictions[i].predictionValue == scenario.resolvedOutcome) {
        //         successfulAgents++;
        //     }
        // }
        // if (successfulAgents < MIN_CONFIDENCE_AGENTS) revert ActionRequestNotExecutable();

        // Execute the call
        uint256 valueToSend = 0; // If original request had ETH attached
        // Find if request had value, for simplicity, this contract itself will hold it.
        // A more robust system would store the value per request.
        // For this design, let's assume the _callData includes any value to send, or the action doesn't require ETH from this contract.
        // If the action creator sent value, it's held in protocol's balance, and needs to be explicitly passed.
        // For now, let's assume `_callData` implies a function call with its own value or no value needed.
        // If `createAutonomousActionRequest` received value, a mechanism to track it per request is needed.
        // For simplicity, let's assume action does not transfer value from this contract.

        (bool success, ) = actionRequest.targetContract.call(actionRequest.callData);
        actionRequest.status = success ? ActionStatus.Executed : ActionStatus.Failed;

        emit AutonomousActionExecuted(_actionRequestId, actionRequest.scenarioId, success);
        if (!success) revert ActionRequestNotExecutable(); // Revert on failed action to make it clear
    }

    // J. Reputation & Efficacy Voting
    function voteOnAIOracleEfficacy(uint256 _agentId, bool _isEffective) external whenNotPaused {
        AIOracleAgent storage agent = aiOracleAgents[_agentId];
        if (agent.id == 0) revert AgentNotFound(); // Simplified error message
        if (msg.sender == agent.owner) revert InvalidReputationVote(); // Agent cannot vote on self

        // For simplicity, a simple vote adds/subtracts a fixed amount.
        // A more advanced system would involve staking for votes, weighted votes, or NFT-based voting power.
        if (_isEffective) {
            agent.reputationScore += 1;
        } else {
            agent.reputationScore -= 1;
        }
        emit AIOracleEfficacyVoted(msg.sender, _agentId, _isEffective);
    }

    // K. Internal/Utility Functions (View/Pure)
    function getScenarioDetails(uint256 _scenarioId) external view returns (Scenario memory) {
        Scenario storage scenario = scenarios[_scenarioId];
        if (scenario.id == 0) revert ScenarioNotFound();
        return scenario;
    }

    function getAIOracleAgentDetails(uint256 _agentId) external view returns (AIOracleAgent memory) {
        AIOracleAgent storage agent = aiOracleAgents[_agentId];
        if (agent.id == 0) revert AgentNotFound(); // Simplified error message
        return agent;
    }

    function getPredictionDetails(uint256 _predictionId) external view returns (Prediction memory) {
        Prediction storage prediction = predictions[_predictionId];
        if (prediction.id == 0) revert PredictionNotFound();
        return prediction;
    }

    function getAutonomousActionRequestDetails(uint256 _actionRequestId) external view returns (AutonomousActionRequest memory) {
        AutonomousActionRequest storage actionRequest = autonomousActionRequests[_actionRequestId];
        if (actionRequest.id == 0) revert ActionRequestNotFound();
        return actionRequest;
    }
}

```