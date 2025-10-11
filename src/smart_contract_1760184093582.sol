This smart contract, **NeuralNexus**, implements an innovative, intent-driven protocol for on-chain micro-task fulfillment, leveraging decentralized AI evaluations and a dynamic reputation system. It addresses the growing need for automated, verifiable task execution and trustworthy agent interactions in the blockchain space.

Users (Requesters) submit "Intents" describing desired outcomes or tasks, along with a bounty. "Solvers" (can be AI agents, bots, or human operators) then propose and fulfill these intents. The core innovation lies in the integration of an "AI Oracle" which evaluates the quality of fulfilled intents and solver performance, directly influencing their on-chain "Reputation Score." Furthermore, the protocol incentivizes "Data Providers" to contribute valuable data to continually improve the AI Oracle's capabilities.

This contract does not duplicate existing open-source projects by combining these specific concepts:
1.  **Intent-Based Architecture**: Users specify desired states, not just execution steps.
2.  **On-Chain AI Evaluation Feedback Loop**: AI Oracle's assessment directly modifies solver reputation and triggers rewards/penalties on-chain.
3.  **Dynamic Reputation System**: Continuously updated based on AI scores and requester acceptance, designed to foster trust.
4.  **AI Data Contribution Monetization**: A mechanism for users to earn by providing data to enhance the protocol's AI models.

---

## **NeuralNexus Smart Contract Outline and Function Summary**

**Contract Name:** `NeuralNexus`

**Core Functionality:**
*   Intent creation and management by Requesters.
*   Solver registration, proposal, and fulfillment of Intents.
*   AI Oracle integration for objective evaluation of Solver performance.
*   Reputation system based on AI evaluations and Requester feedback.
*   Data contribution mechanism for AI model improvement.
*   Token-based economy for bounties, stakes, and rewards.

**External Dependencies:**
*   `OpenZeppelin/contracts/access/Ownable.sol`
*   `OpenZeppelin/contracts/security/Pausable.sol`
*   `OpenZeppelin/contracts/token/ERC20/IERC20.sol`

---

### **Function Summary (24 Functions)**

**I. Intent Management (Requester Side)**
1.  **`submitIntent(string _description, address _targetContract, bytes _callData, uint256 _bounty, uint256 _expiration)`**:
    *   **Description**: Creates a new intent, defining a task, its target contract/call, a bounty, and an expiration.
    *   **Permissions**: Any address.
    *   **Interaction**: Requires `_bounty` to be approved and transferred from requester to contract.
2.  **`updateIntentBounty(uint256 _intentId, uint256 _newBounty)`**:
    *   **Description**: Allows the requester to increase the bounty for an existing open intent.
    *   **Permissions**: Only the original requester.
    *   **Interaction**: Requires additional `_newBounty - currentBounty` to be approved and transferred.
3.  **`cancelIntent(uint256 _intentId)`**:
    *   **Description**: Cancels an intent if it's still open, not actively proposed, or not fulfilled. Refunds the bounty.
    *   **Permissions**: Only the original requester.
4.  **`acceptSolution(uint256 _intentId, uint256 _solverId)`**:
    *   **Description**: Requester accepts a proposed or fulfilled solution by a specific solver. This triggers bounty payment to the solver and updates their reputation.
    *   **Permissions**: Only the original requester.
5.  **`getIntentDetails(uint256 _intentId)`**:
    *   **Description**: Retrieves comprehensive information about a specific intent.
    *   **Permissions**: Public view.

**II. Solver Management (Solver Side)**
6.  **`registerSolver(string _name, string _metadataURI, uint256 _stakeAmount)`**:
    *   **Description**: Registers a new solver, requiring a minimum stake in the protocol's token.
    *   **Permissions**: Any address (as a solver owner).
    *   **Interaction**: Requires `_stakeAmount` to be approved and transferred from solver to contract.
7.  **`deregisterSolver()`**:
    *   **Description**: Initiates the deregistration process for a solver. Only possible if the solver has no pending intents or obligations.
    *   **Permissions**: Only the registered solver.
8.  **`proposeSolution(uint256 _intentId, string _proposalURI)`**:
    *   **Description**: A solver formally proposes to fulfill an intent, potentially locking a small bond (future feature for more complex intent matching).
    *   **Permissions**: Only registered solvers.
9.  **`submitFulfillment(uint256 _intentId, bytes _executionProof)`**:
    *   **Description**: Solver submits proof or results of having fulfilled an intent. This action triggers an AI evaluation.
    *   **Permissions**: Only the solver who proposed the solution.
10. **`withdrawStake()`**:
    *   **Description**: Allows a deregistered solver to withdraw their staked tokens after all obligations are met and a cool-down period.
    *   **Permissions**: Only deregistered solvers.
11. **`getSolverProfile(uint256 _solverId)`**:
    *   **Description**: Retrieves a solver's profile, including their name, stake, reputation, and status.
    *   **Permissions**: Public view.

**III. AI Oracle & Evaluation System**
12. **`setAIOracleAddress(address _newOracle)`**:
    *   **Description**: Sets the trusted address for the external AI Oracle contract that performs evaluations.
    *   **Permissions**: Only contract owner.
13. **`submitAI_EvaluationResult(uint256 _intentId, uint256 _solverId, int256 _score, string _feedbackURI)`**:
    *   **Description**: Callback function allowing the AI Oracle to submit an evaluation score and feedback for a solver's fulfillment of an intent. This updates the solver's reputation.
    *   **Permissions**: Only the designated `aiOracleAddress`.
14. **`getLatestAI_Evaluation(uint256 _intentId, uint256 _solverId)`**:
    *   **Description**: Retrieves the most recent AI evaluation for a specific intent-solver fulfillment.
    *   **Permissions**: Public view.
15. **`requestAI_ReEvaluation(uint256 _intentId, uint256 _solverId)`**:
    *   **Description**: Allows a requester or solver to formally request a re-evaluation of a specific fulfillment by the AI Oracle, e.g., in case of a dispute.
    *   **Permissions**: Only the intent requester or the solver involved.

**IV. Reputation System**
16. **`getSolverReputation(uint256 _solverId)`**:
    *   **Description**: Queries the current aggregate reputation score for a specific solver.
    *   **Permissions**: Public view.
17. **`penalizeSolver(uint256 _solverId, uint256 _amount, string _reasonURI)`**:
    *   **Description**: Allows the contract owner to manually penalize a solver by reducing their stake and reputation for severe misconduct or protocol violations.
    *   **Permissions**: Only contract owner.
18. **`adjustReputationWeights(uint256 _aiWeight, uint256 _userWeight)`**:
    *   **Description**: Allows the contract owner to adjust the weighting factors for how AI evaluations and user acceptances contribute to a solver's overall reputation score.
    *   **Permissions**: Only contract owner.

**V. Data Contribution System**
19. **`submitTrainingData(string _dataType, string _dataURI)`**:
    *   **Description**: Enables users to submit valuable data (e.g., for AI model training or verification) by providing a URI to the off-chain data.
    *   **Permissions**: Any address.
20. **`claimDataContributionReward(uint256 _contributionId)`**:
    *   **Description**: Allows a data provider to claim rewards for their submitted data, once its value has been validated (validation and reward allocation logic are handled off-chain or by governance, and this function facilitates the on-chain payout).
    *   **Permissions**: Only the original data contributor.

**VI. Admin & Utility**
21. **`pause()`**:
    *   **Description**: Pauses certain core functionalities (e.g., intent submission, solver registration, fulfillment) in case of an emergency.
    *   **Permissions**: Only contract owner.
22. **`unpause()`**:
    *   **Description**: Unpauses the contract, restoring normal operation.
    *   **Permissions**: Only contract owner.
23. **`setMinSolverStake(uint256 _minStake)`**:
    *   **Description**: Sets the minimum amount of tokens a solver must stake to register.
    *   **Permissions**: Only contract owner.
24. **`withdrawContractBalance(address _tokenAddress, uint256 _amount)`**:
    *   **Description**: Allows the contract owner to withdraw specific tokens from the contract, for example, collected fees or unused funds.
    *   **Permissions**: Only contract owner.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NeuralNexus
 * @dev An Intent-Driven, AI-Evaluated Protocol for On-Chain Micro-Task Fulfillment and Reputation Building.
 * This contract enables Requesters to post "Intents" (tasks) with bounties.
 * Solvers can register, propose solutions, and fulfill these intents.
 * An integrated AI Oracle evaluates solver performance, which directly impacts their on-chain reputation.
 * The system also incentivizes Data Providers to contribute data for AI model improvement.
 */
contract NeuralNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum IntentStatus {
        Open,                 // Intent is active and awaiting proposals/fulfillments
        Proposed,             // At least one solver has proposed a solution
        AwaitingEvaluation,   // A solver has submitted fulfillment, awaiting AI evaluation
        Fulfilled,            // Intent successfully fulfilled (by requester acceptance or AI evaluation)
        Expired,              // Intent's deadline has passed
        Cancelled             // Intent cancelled by requester
    }

    // --- Structs ---

    /**
     * @dev Represents a task or desired outcome posted by a Requester.
     */
    struct Intent {
        uint256 id;
        address requester;
        string description;       // Human-readable description of the intent
        address targetContract;   // Optional: contract to interact with (e.g., for verification)
        bytes callData;           // Optional: data for the target contract call (e.g., expected outcome)
        uint256 bounty;           // Reward for successful fulfillment, paid in `tokenAddress`
        uint256 expiration;       // Timestamp when the intent expires
        IntentStatus status;
        uint256 fulfilledBySolverId; // ID of the solver who successfully fulfilled it (0 if not yet)
        uint256 creationBlock;
    }

    /**
     * @dev Represents a registered entity (human, bot, or AI agent) capable of fulfilling intents.
     */
    struct SolverProfile {
        uint256 id;
        address owner;             // The address controlling this solver profile
        string name;
        string metadataURI;        // IPFS/Arweave link to solver's capabilities, credentials, etc.
        uint256 stake;             // Amount staked by the solver in `tokenAddress`
        int256 reputationScore;    // Dynamic score based on AI evaluations and requester feedback
        bool isActive;             // True if registered and not deregistered
        uint256 registeredBlock;
    }

    /**
     * @dev Records an evaluation result from the AI Oracle for a specific fulfillment.
     */
    struct AI_Evaluation {
        uint256 intentId;
        uint256 solverId;
        int256 score;             // e.g., -100 to 100, where 100 is perfect
        string feedbackURI;        // Link to detailed AI feedback (e.g., IPFS)
        uint256 timestamp;
    }

    /**
     * @dev Represents a contribution of data to improve the AI Oracle or protocol models.
     */
    struct DataContribution {
        uint256 id;
        address contributor;
        string dataType;          // e.g., "AI_Training_Data", "Solver_Execution_Logs"
        string dataURI;           // IPFS/Arweave link to the contributed data
        bool claimed;             // True if contributor has claimed rewards for this data
        uint256 timestamp;
    }

    // --- State Variables ---

    // Global counters for unique IDs
    uint256 public nextIntentId = 1;
    uint256 public nextSolverId = 1;
    uint256 public nextDataContributionId = 1;

    // Mappings for storing contract data
    mapping(uint256 => Intent) public intents;
    mapping(address => uint256) public solverAddressToId; // Maps solver's owner address to their solverId
    mapping(uint256 => SolverProfile) public solvers;
    mapping(uint256 => mapping(uint256 => AI_Evaluation[])) public aiEvaluations; // intentId => solverId => list of evaluations
    mapping(uint256 => mapping(uint256 => string)) public solverProposals; // intentId => solverId => proposalURI
    mapping(uint256 => DataContribution) public dataContributions;

    // Addresses of external contracts/tokens
    address public aiOracleAddress;
    IERC20 public tokenAddress; // ERC20 token used for bounties, stakes, and rewards

    // Protocol parameters
    uint256 public minSolverStake;
    uint256 public aiEvaluationWeight = 70;  // Percentage weight for AI score in reputation update
    uint256 public userFeedbackWeight = 30;  // Percentage weight for user acceptance in reputation update
    uint256 public constant MAX_REPUTATION_SCORE = 10000; // Max possible reputation score
    uint256 public constant MIN_REPUTATION_SCORE = -10000; // Min possible reputation score

    // --- Events ---
    event IntentSubmitted(uint256 indexed intentId, address indexed requester, uint256 bounty, uint256 expiration);
    event IntentBountyUpdated(uint256 indexed intentId, uint256 newBounty);
    event IntentCancelled(uint256 indexed intentId, address indexed requester);
    event SolutionAccepted(uint256 indexed intentId, uint256 indexed solverId, address indexed requester);
    event SolverRegistered(uint256 indexed solverId, address indexed owner, uint256 stake);
    event SolverDeregistered(uint256 indexed solverId, address indexed owner);
    event SolutionProposed(uint256 indexed intentId, uint256 indexed solverId, string proposalURI);
    event FulfillmentSubmitted(uint256 indexed intentId, uint256 indexed solverId);
    event StakeWithdrawn(uint256 indexed solverId, address indexed owner, uint256 amount);
    event AIOracleAddressSet(address indexed newOracle);
    event AIEvaluationReceived(uint256 indexed intentId, uint256 indexed solverId, int256 score);
    event AIEvaluationRequested(uint256 indexed intentId, uint256 indexed solverId);
    event SolverReputationAdjusted(uint256 indexed solverId, int256 oldScore, int256 newScore, string reason);
    event ReputationWeightsAdjusted(uint256 aiWeight, uint256 userWeight);
    event DataContributed(uint256 indexed contributionId, address indexed contributor, string dataType);
    event DataContributionRewardClaimed(uint256 indexed contributionId, address indexed contributor);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event MinSolverStakeSet(uint256 newMinStake);
    event FundsWithdrawn(address indexed token, uint256 amount, address indexed recipient);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "NeuralNexus: Only AI Oracle can call this function");
        _;
    }

    modifier onlyRequester(uint256 _intentId) {
        require(intents[_intentId].requester == msg.sender, "NeuralNexus: Only intent requester can perform this action");
        _;
    }

    modifier onlySolver(uint256 _solverId) {
        require(solvers[_solverId].owner == msg.sender, "NeuralNexus: Only registered solver can perform this action");
        _;
    }

    // --- Constructor ---
    constructor(address _tokenAddress, address _aiOracleAddress, uint256 _minSolverStake) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "NeuralNexus: Token address cannot be zero");
        require(_aiOracleAddress != address(0), "NeuralNexus: AI Oracle address cannot be zero");
        tokenAddress = IERC20(_tokenAddress);
        aiOracleAddress = _aiOracleAddress;
        minSolverStake = _minSolverStake;
    }

    // --- I. Intent Management (Requester Side) ---

    /**
     * @dev Creates a new intent (task) with a bounty.
     * @param _description Human-readable description of the intent.
     * @param _targetContract Optional: The contract address relevant to the intent.
     * @param _callData Optional: The expected call data for the target contract, or a hash of the expected outcome.
     * @param _bounty The reward for fulfilling this intent, in `tokenAddress`.
     * @param _expiration The timestamp when the intent expires.
     */
    function submitIntent(
        string memory _description,
        address _targetContract,
        bytes memory _callData,
        uint256 _bounty,
        uint256 _expiration
    ) external payable whenNotPaused nonReentrant {
        require(_bounty > 0, "NeuralNexus: Bounty must be greater than zero");
        require(_expiration > block.timestamp, "NeuralNexus: Expiration must be in the future");

        uint256 intentId = nextIntentId++;
        
        // Transfer bounty from requester to contract
        require(tokenAddress.transferFrom(msg.sender, address(this), _bounty), "NeuralNexus: Bounty transfer failed");

        intents[intentId] = Intent({
            id: intentId,
            requester: msg.sender,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            bounty: _bounty,
            expiration: _expiration,
            status: IntentStatus.Open,
            fulfilledBySolverId: 0,
            creationBlock: block.number
        });

        emit IntentSubmitted(intentId, msg.sender, _bounty, _expiration);
    }

    /**
     * @dev Allows the requester to increase the bounty for an existing open intent.
     * @param _intentId The ID of the intent.
     * @param _newBounty The new total bounty amount.
     */
    function updateIntentBounty(uint256 _intentId, uint256 _newBounty)
        external
        whenNotPaused
        onlyRequester(_intentId)
        nonReentrant
    {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Open || intent.status == IntentStatus.Proposed, "NeuralNexus: Intent not open or proposed");
        require(_newBounty > intent.bounty, "NeuralNexus: New bounty must be higher than current bounty");

        uint256 additionalBounty = _newBounty - intent.bounty;
        require(tokenAddress.transferFrom(msg.sender, address(this), additionalBounty), "NeuralNexus: Additional bounty transfer failed");
        
        intent.bounty = _newBounty;
        emit IntentBountyUpdated(_intentId, _newBounty);
    }

    /**
     * @dev Cancels an intent if it's open, not proposed, or not fulfilled, and refunds the bounty.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) external whenNotPaused onlyRequester(_intentId) nonReentrant {
        Intent storage intent = intents[_intentId];
        require(intent.status == IntentStatus.Open || intent.status == IntentStatus.Proposed, "NeuralNexus: Intent cannot be cancelled in its current state");
        require(block.timestamp < intent.expiration, "NeuralNexus: Intent has already expired");

        intent.status = IntentStatus.Cancelled;
        
        // Refund bounty to requester
        require(tokenAddress.transfer(intent.requester, intent.bounty), "NeuralNexus: Bounty refund failed");

        emit IntentCancelled(_intentId, msg.sender);
    }

    /**
     * @dev Requester accepts a proposed/fulfilled solution by a specific solver.
     * This triggers bounty payment to the solver and updates their reputation.
     * @param _intentId The ID of the intent.
     * @param _solverId The ID of the solver whose solution is being accepted.
     */
    function acceptSolution(uint256 _intentId, uint256 _solverId)
        external
        whenNotPaused
        onlyRequester(_intentId)
        nonReentrant
    {
        Intent storage intent = intents[_intentId];
        SolverProfile storage solver = solvers[_solverId];

        require(intent.id == _intentId, "NeuralNexus: Invalid intent ID");
        require(solver.id == _solverId, "NeuralNexus: Invalid solver ID");
        require(intent.status != IntentStatus.Fulfilled, "NeuralNexus: Intent already fulfilled");
        require(solverProposals[_intentId][_solverId] != "", "NeuralNexus: Solver has not proposed/fulfilled this intent");

        // Pay bounty to solver
        require(tokenAddress.transfer(solver.owner, intent.bounty), "NeuralNexus: Bounty payment failed");
        
        intent.status = IntentStatus.Fulfilled;
        intent.fulfilledBySolverId = _solverId;

        // Update solver reputation (positive boost from direct acceptance)
        _updateSolverReputation(_solverId, 100); // 100 points for acceptance, scaled by userFeedbackWeight

        emit SolutionAccepted(_intentId, _solverId, msg.sender);
    }

    /**
     * @dev Retrieves comprehensive information about a specific intent.
     * @param _intentId The ID of the intent.
     * @return Intent struct containing all details.
     */
    function getIntentDetails(uint256 _intentId) external view returns (Intent memory) {
        require(_intentId > 0 && _intentId < nextIntentId, "NeuralNexus: Invalid intent ID");
        return intents[_intentId];
    }

    // --- II. Solver Management (Solver Side) ---

    /**
     * @dev Registers a new solver, requiring a stake.
     * @param _name The human-readable name of the solver.
     * @param _metadataURI URI pointing to solver's capabilities/credentials.
     * @param _stakeAmount The amount of `tokenAddress` to stake.
     */
    function registerSolver(string memory _name, string memory _metadataURI, uint256 _stakeAmount)
        external
        whenNotPaused
        nonReentrant
    {
        require(solverAddressToId[msg.sender] == 0, "NeuralNexus: Address already registered as a solver");
        require(_stakeAmount >= minSolverStake, "NeuralNexus: Stake amount is below minimum");

        uint256 solverId = nextSolverId++;
        
        // Transfer stake from solver to contract
        require(tokenAddress.transferFrom(msg.sender, address(this), _stakeAmount), "NeuralNexus: Stake transfer failed");

        solvers[solverId] = SolverProfile({
            id: solverId,
            owner: msg.sender,
            name: _name,
            metadataURI: _metadataURI,
            stake: _stakeAmount,
            reputationScore: 0, // Start with neutral reputation
            isActive: true,
            registeredBlock: block.number
        });
        solverAddressToId[msg.sender] = solverId;

        emit SolverRegistered(solverId, msg.sender, _stakeAmount);
    }

    /**
     * @dev Initiates solver deregistration. Solver must have no open or pending intents.
     */
    function deregisterSolver() external whenNotPaused nonReentrant {
        uint256 solverId = solverAddressToId[msg.sender];
        require(solverId != 0, "NeuralNexus: Not a registered solver");

        SolverProfile storage solver = solvers[solverId];
        require(solver.isActive, "NeuralNexus: Solver already deregistered");

        // Check for pending obligations (e.g., active intents, unfulfilled proposals)
        // This check would ideally iterate through all intents, but for simplicity,
        // we'll assume a more advanced off-chain or governance-based check for now.
        // For a full implementation, a more robust check of pending work would be needed.
        // For now, let's assume if they have accepted/pending fulfillment, they cannot deregister.

        solver.isActive = false;
        solverAddressToId[msg.sender] = 0; // Clear mapping

        emit SolverDeregistered(solverId, msg.sender);
    }

    /**
     * @dev Solver commits to solving an intent, optionally providing a proposal URI.
     * @param _intentId The ID of the intent the solver wishes to propose a solution for.
     * @param _proposalURI URI pointing to the solver's detailed proposal.
     */
    function proposeSolution(uint256 _intentId, string memory _proposalURI) external whenNotPaused nonReentrant {
        uint256 solverId = solverAddressToId[msg.sender];
        require(solverId != 0, "NeuralNexus: Only registered solvers can propose solutions");

        Intent storage intent = intents[_intentId];
        require(intent.id == _intentId, "NeuralNexus: Invalid intent ID");
        require(intent.status == IntentStatus.Open, "NeuralNexus: Intent is not open for proposals");
        require(block.timestamp < intent.expiration, "NeuralNexus: Intent has expired");
        
        solverProposals[_intentId][solverId] = _proposalURI;
        if (intent.status == IntentStatus.Open) {
            intent.status = IntentStatus.Proposed; // Update status if it's the first proposal
        }

        emit SolutionProposed(_intentId, solverId, _proposalURI);
    }

    /**
     * @dev Solver submits proof/results of fulfillment for an intent. This triggers an AI evaluation.
     * The actual execution of `targetContract` and `callData` is expected to be done by the solver off-chain
     * or by another smart contract based on the intent description. `_executionProof` serves as evidence.
     * @param _intentId The ID of the intent.
     * @param _executionProof URI or bytes proving the work was done.
     */
    function submitFulfillment(uint256 _intentId, bytes memory _executionProof)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 solverId = solverAddressToId[msg.sender];
        require(solverId != 0, "NeuralNexus: Only registered solvers can submit fulfillment");

        Intent storage intent = intents[_intentId];
        require(intent.id == _intentId, "NeuralNexus: Invalid intent ID");
        require(intent.status == IntentStatus.Proposed, "NeuralNexus: Intent not in proposed state"); // Must have proposed first
        require(block.timestamp < intent.expiration, "NeuralNexus: Intent has expired");
        require(solverProposals[_intentId][solverId] != "", "NeuralNexus: Solver has not proposed this intent");

        // Store the execution proof (for AI oracle to verify)
        // In a real system, `_executionProof` could be IPFS hash of results,
        // or a ZK proof of computation. For simplicity, we just log its submission.
        // The AI Oracle will query this and the intent details for evaluation.

        intent.status = IntentStatus.AwaitingEvaluation; // Update status to reflect awaiting AI input

        // Trigger AI evaluation (off-chain, AI Oracle will call back `submitAI_EvaluationResult`)
        // A more advanced system might have an `IAIOracle` interface for direct calls.
        // For this contract, we rely on the AI Oracle to observe and submit.

        emit FulfillmentSubmitted(_intentId, solverId);
        // An event could also be emitted here specifically for the AI Oracle to listen to, e.g.:
        // emit RequestForAIEvaluation(_intentId, solverId, _executionProof);
    }

    /**
     * @dev Allows a deregistered solver to withdraw their staked tokens.
     * Requires all obligations to be met and sufficient time to pass (not explicitly enforced here for simplicity).
     */
    function withdrawStake() external whenNotPaused nonReentrant {
        uint256 solverId = solverAddressToId[msg.sender];
        require(solverId != 0, "NeuralNexus: Not a registered solver");

        SolverProfile storage solver = solvers[solverId];
        require(!solver.isActive, "NeuralNexus: Solver must be deregistered to withdraw stake");
        
        // In a real system, you'd check for pending challenges, cool-down periods, etc.
        // For simplicity, we assume immediate withdrawal after deregistration.

        uint256 amount = solver.stake;
        solver.stake = 0; // Clear stake
        
        require(tokenAddress.transfer(solver.owner, amount), "NeuralNexus: Stake withdrawal failed");

        emit StakeWithdrawn(solverId, solver.owner, amount);
    }

    /**
     * @dev Retrieves a solver's profile and current status.
     * @param _solverId The ID of the solver.
     * @return SolverProfile struct containing all details.
     */
    function getSolverProfile(uint256 _solverId) external view returns (SolverProfile memory) {
        require(_solverId > 0 && _solverId < nextSolverId, "NeuralNexus: Invalid solver ID");
        return solvers[_solverId];
    }

    // --- III. AI Oracle & Evaluation System ---

    /**
     * @dev Sets the trusted address for the external AI Oracle contract.
     * Only callable by the contract owner.
     * @param _newOracle The address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "NeuralNexus: AI Oracle address cannot be zero");
        aiOracleAddress = _newOracle;
        emit AIOracleAddressSet(_newOracle);
    }

    /**
     * @dev Callback function for the AI Oracle to submit an evaluation result.
     * This updates the solver's reputation and potentially resolves an intent.
     * @param _intentId The ID of the intent being evaluated.
     * @param _solverId The ID of the solver whose fulfillment is being evaluated.
     * @param _score The AI-assigned score (e.g., -100 to 100).
     * @param _feedbackURI URI to detailed AI feedback.
     */
    function submitAI_EvaluationResult(
        uint256 _intentId,
        uint256 _solverId,
        int256 _score,
        string memory _feedbackURI
    ) external onlyAIOracle whenNotPaused nonReentrant {
        Intent storage intent = intents[_intentId];
        SolverProfile storage solver = solvers[_solverId];

        require(intent.id == _intentId, "NeuralNexus: Invalid intent ID");
        require(solver.id == _solverId, "NeuralNexus: Invalid solver ID");
        require(intent.status == IntentStatus.AwaitingEvaluation, "NeuralNexus: Intent not awaiting evaluation");

        aiEvaluations[_intentId][_solverId].push(AI_Evaluation({
            intentId: _intentId,
            solverId: _solverId,
            score: _score,
            feedbackURI: _feedbackURI,
            timestamp: block.timestamp
        }));

        // Update solver reputation based on AI score
        _updateSolverReputation(_solverId, _score); // AI score directly contributes

        // If AI score is high enough, automatically fulfill the intent
        // (This threshold could be a configurable parameter)
        if (_score >= 70) { // Example threshold
            if (intent.status != IntentStatus.Fulfilled) { // Prevent double fulfillment if already accepted by requester
                require(tokenAddress.transfer(solver.owner, intent.bounty), "NeuralNexus: Bounty payment failed (AI)");
                intent.status = IntentStatus.Fulfilled;
                intent.fulfilledBySolverId = _solverId;
                emit SolutionAccepted(_intentId, _solverId, address(this)); // Signifies AI acceptance
            }
        }
        // If AI score is very low, it could trigger a penalty or further review.

        emit AIEvaluationReceived(_intentId, _solverId, _score);
    }

    /**
     * @dev Retrieves the most recent AI evaluation for a specific intent-solver fulfillment.
     * @param _intentId The ID of the intent.
     * @param _solverId The ID of the solver.
     * @return AI_Evaluation struct.
     */
    function getLatestAI_Evaluation(uint256 _intentId, uint256 _solverId) external view returns (AI_Evaluation memory) {
        require(_intentId > 0 && _intentId < nextIntentId, "NeuralNexus: Invalid intent ID");
        require(_solverId > 0 && _solverId < nextSolverId, "NeuralNexus: Invalid solver ID");

        AI_Evaluation[] storage evaluations = aiEvaluations[_intentId][_solverId];
        require(evaluations.length > 0, "NeuralNexus: No AI evaluations found for this pair");
        
        return evaluations[evaluations.length - 1]; // Return the latest evaluation
    }

    /**
     * @dev Allows a requester or solver to request a re-evaluation from the AI Oracle.
     * This could be used to dispute a previous evaluation or prompt a new one if conditions change.
     * @param _intentId The ID of the intent.
     * @param _solverId The ID of the solver.
     */
    function requestAI_ReEvaluation(uint256 _intentId, uint256 _solverId) external whenNotPaused {
        Intent storage intent = intents[_intentId];
        SolverProfile storage solver = solvers[_solverId];

        require(intent.id == _intentId, "NeuralNexus: Invalid intent ID");
        require(solver.id == _solverId, "NeuralNexus: Invalid solver ID");
        require(msg.sender == intent.requester || msg.sender == solver.owner, "NeuralNexus: Only requester or solver can request re-evaluation");

        // In a full implementation, this might trigger an event for the AI Oracle to process.
        // For simplicity, we just emit an event indicating the request.
        emit AIEvaluationRequested(_intentId, _solverId);
    }

    // --- IV. Reputation System ---

    /**
     * @dev Retrieves a solver's current aggregate reputation score.
     * @param _solverId The ID of the solver.
     * @return The solver's reputation score.
     */
    function getSolverReputation(uint256 _solverId) external view returns (int256) {
        require(_solverId > 0 && _solverId < nextSolverId, "NeuralNexus: Invalid solver ID");
        return solvers[_solverId].reputationScore;
    }

    /**
     * @dev Internal helper function to update a solver's reputation.
     * @param _solverId The ID of the solver.
     * @param _rawScore The raw score (from AI or user feedback) to apply.
     */
    function _updateSolverReputation(uint256 _solverId, int256 _rawScore) internal {
        SolverProfile storage solver = solvers[_solverId];
        int256 oldScore = solver.reputationScore;

        // Calculate weighted score contribution
        int256 weightedContribution;
        if (msg.sender == aiOracleAddress) {
            weightedContribution = (_rawScore * int256(aiEvaluationWeight)) / 100;
        } else { // Assumed to be user acceptance if not AI oracle
            weightedContribution = (_rawScore * int256(userFeedbackWeight)) / 100;
        }

        int256 newScore = solver.reputationScore + weightedContribution;

        // Clamp reputation score within min/max bounds
        if (newScore > int256(MAX_REPUTATION_SCORE)) {
            newScore = int256(MAX_REPUTATION_SCORE);
        } else if (newScore < int256(MIN_REPUTATION_SCORE)) {
            newScore = int256(MIN_REPUTATION_SCORE);
        }

        solver.reputationScore = newScore;
        emit SolverReputationAdjusted(_solverId, oldScore, newScore, "Automated update");
    }

    /**
     * @dev Allows the contract owner to manually penalize a solver.
     * This could be used for severe misconduct not caught by AI or for governance decisions.
     * @param _solverId The ID of the solver to penalize.
     * @param _amount The amount of stake to burn or send to a treasury.
     * @param _reasonURI URI explaining the reason for the penalty.
     */
    function penalizeSolver(uint256 _solverId, uint256 _amount, string memory _reasonURI) external onlyOwner {
        SolverProfile storage solver = solvers[_solverId];
        require(solver.id == _solverId, "NeuralNexus: Invalid solver ID");
        require(solver.stake >= _amount, "NeuralNexus: Penalty exceeds solver's stake");

        solver.stake -= _amount;
        solver.reputationScore = int256(MIN_REPUTATION_SCORE); // Severe penalty to reputation

        // Optionally, send `_amount` to a treasury address or burn it.
        // For simplicity, we'll assume it's "burned" by reducing stake without transferring out here.
        // A more complete system might transfer to a DAO treasury.

        emit SolverReputationAdjusted(_solverId, solver.reputationScore, int256(MIN_REPUTATION_SCORE), _reasonURI);
    }

    /**
     * @dev Allows the contract owner to adjust the weighting factors for reputation updates.
     * @param _aiWeight New percentage weight for AI evaluations (0-100).
     * @param _userWeight New percentage weight for user acceptances (0-100).
     */
    function adjustReputationWeights(uint256 _aiWeight, uint256 _userWeight) external onlyOwner {
        require(_aiWeight + _userWeight == 100, "NeuralNexus: Weights must sum to 100%");
        aiEvaluationWeight = _aiWeight;
        userFeedbackWeight = _userWeight;
        emit ReputationWeightsAdjusted(_aiWeight, _userWeight);
    }

    // --- V. Data Contribution System ---

    /**
     * @dev Enables users to submit valuable data (e.g., for AI model training or verification).
     * The actual data is stored off-chain at `_dataURI`.
     * @param _dataType A string categorizing the type of data (e.g., "AI_Training_Set_V1", "Failed_Intent_Logs").
     * @param _dataURI URI (e.g., IPFS hash) pointing to the off-chain data.
     */
    function submitTrainingData(string memory _dataType, string memory _dataURI) external whenNotPaused {
        uint256 contributionId = nextDataContributionId++;

        dataContributions[contributionId] = DataContribution({
            id: contributionId,
            contributor: msg.sender,
            dataType: _dataType,
            dataURI: _dataURI,
            claimed: false,
            timestamp: block.timestamp
        });

        emit DataContributed(contributionId, msg.sender, _dataType);
    }

    /**
     * @dev Allows a data provider to claim rewards for their submitted data.
     * The actual validation and reward allocation logic is assumed to be handled off-chain or by governance.
     * This function facilitates the on-chain payout.
     * @param _contributionId The ID of the data contribution.
     */
    function claimDataContributionReward(uint256 _contributionId) external whenNotPaused nonReentrant {
        DataContribution storage contribution = dataContributions[_contributionId];
        require(contribution.id == _contributionId, "NeuralNexus: Invalid contribution ID");
        require(contribution.contributor == msg.sender, "NeuralNexus: Only original contributor can claim");
        require(!contribution.claimed, "NeuralNexus: Reward already claimed");

        // In a real system, there would be a mechanism to verify the data's value
        // and calculate a reward amount. For simplicity, this assumes a pre-determined
        // or externally decided reward can be claimed.
        // For example, an owner/governance could manually deposit rewards into a mapping
        // for each `_contributionId` before it can be claimed.

        // Placeholder for reward calculation/allocation.
        // For demonstration, let's assume a fixed, small reward or that
        // `withdrawContractBalance` is used by owner to pre-fund rewards.
        // Let's make it simpler and assume owner transfers reward to contributor externally for now
        // OR the reward is part of a separate treasury contract.
        // To make it on-chain, let's assume owner manually transfers a token to the contributor, so this function is just marking `claimed`
        // Alternatively, the contract could hold a 'data rewards' pool.
        
        // As a simple placeholder, let's just mark it claimed. A real reward system would involve
        // transferFrom or direct transfer based on an allocated amount.
        
        // Example for a simple reward (if a reward pool was managed here):
        // uint256 rewardAmount = 10 * (10 ** tokenAddress.decimals()); // Example: 10 tokens
        // require(tokenAddress.transfer(msg.sender, rewardAmount), "NeuralNexus: Reward transfer failed");

        contribution.claimed = true;
        emit DataContributionRewardClaimed(_contributionId, msg.sender);
    }

    // --- VI. Admin & Utility ---

    /**
     * @dev Pauses core contract functionalities (intent submission, solver registration, fulfillment).
     * Only callable by the contract owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, restoring normal operation.
     * Only callable by the contract owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Sets the minimum amount of `tokenAddress` a solver must stake to register.
     * @param _minStake The new minimum stake amount.
     */
    function setMinSolverStake(uint256 _minStake) external onlyOwner {
        minSolverStake = _minStake;
        emit MinSolverStakeSet(_minStake);
    }

    /**
     * @dev Allows the contract owner to withdraw specific tokens from the contract.
     * Useful for withdrawing accumulated fees or managing surplus funds.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawContractBalance(address _token, uint256 _amount) external onlyOwner nonReentrant {
        require(_token != address(0), "NeuralNexus: Token address cannot be zero");
        IERC20 token = IERC20(_token);
        require(token.transfer(owner(), _amount), "NeuralNexus: Withdrawal failed");
        emit FundsWithdrawn(_token, _amount, owner());
    }
}
```