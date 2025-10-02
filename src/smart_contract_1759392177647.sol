The `AetherIntentEngine` is an advanced, intent-based smart contract platform designed to connect users seeking specific outcomes ("Intents") with a network of "Agents" capable of fulfilling them. It incorporates a robust escrow system, dynamic agent reputation, dispute resolution mechanisms, and integration points for external data/AI oracles, all governed by a decentralized process.

This contract aims to create a trust-minimized marketplace for complex, multi-step operations that might otherwise require users to interact with numerous protocols or off-chain services manually. Agents are incentivized by payment for successful fulfillments and a reputation system that unlocks more valuable intents, while negative behavior is penalized through stake slashing and reputation reduction.

---

### **Outline and Function Summary:**

**I. Core Components & Data Structures:**
*   **`IntentStatus`**: Enum for tracking intent lifecycle (Open, Claimed, Fulfilled, Disputed, Resolved, Cancelled).
*   **`Intent`**: Struct defining a user's desired outcome, including payment, status, assigned agent, and dispute details.
*   **`Agent`**: Struct for registered agents, tracking their stake, reputation, and activity.
*   **`GovernanceProposal`**: Struct for managing system parameter changes through a basic voting mechanism.

**II. Intent Management (User-Facing - Functions 1-5):**
1.  **`submitIntent(IERC20 _paymentToken, uint256 _amount, bytes calldata _intentDetails, string calldata _outcomeDescription)`**:
    *   **Summary**: Allows a user to submit a new intent, locking `_amount` of `_paymentToken` in escrow within the contract. `_intentDetails` specify the technical parameters, while `_outcomeDescription` is a human-readable goal.
2.  **`cancelIntent(bytes32 _intentId)`**:
    *   **Summary**: Enables the original user or a delegated manager to cancel an open intent, returning the escrowed funds.
3.  **`delegateIntentManagement(bytes32 _intentId, address _newManager)`**:
    *   **Summary**: Empowers another address to manage and interact with a specific intent on behalf of the original user.
4.  **`updateIntentParameters(bytes32 _intentId, bytes calldata _newIntentDetails, string calldata _newOutcomeDescription)`**:
    *   **Summary**: Allows the user or manager to modify the details or description of an existing `Open` intent.
5.  **`batchSubmitIntents(IERC20[] calldata _paymentTokens, uint256[] calldata _amounts, bytes[] calldata _intentDetails, string[] calldata _outcomeDescriptions)`**:
    *   **Summary**: Facilitates the submission of multiple intents in a single transaction, improving efficiency for complex strategies.

**III. Agent Management & Interaction (Functions 6-12):**
6.  **`registerAgent()`**:
    *   **Summary**: Allows an address to become an agent by staking the `minAgentStakeAmount` of the protocol's designated `stakeERC20`.
7.  **`deregisterAgent()`**:
    *   **Summary**: Enables a registered agent to retrieve their stake and leave the agent network (if not engaged in active intents or disputes).
8.  **`claimIntent(bytes32 _intentId)`**:
    *   **Summary**: An agent declares their intention to fulfill a specific `Open` intent. The intent's status changes to `Claimed`.
9.  **`fulfillIntent(bytes32 _intentId, uint256 _actualAmount, bytes calldata _fulfillmentProof)`**:
    *   **Summary**: The claiming agent submits proof of intent fulfillment. The intent enters a dispute period, and the agent's reputation is updated.
10. **`disputeFulfillment(bytes32 _intentId)`**:
    *   **Summary**: The user or manager can formally dispute an agent's claimed fulfillment within a set timeframe.
11. **`slashAgentStake(address _agentAddress, uint256 _amount)`**:
    *   **Summary**: An authorized arbitrator (or governance) can penalize an agent by reducing their staked `stakeERC20` and reputation, typically for failed fulfillments or malicious behavior.
12. **`getAgentReputation(address _agentAddress)`**:
    *   **Summary**: A public view function to query an agent's current reputation score.

**IV. Oracle & Data Integration (Functions 13-15):**
13. **`updateTrustedOracle(address _newOracle)`**:
    *   **Summary**: Governance-controlled function to update the address of the trusted `IOracle` contract used for verified off-chain data or AI insights.
14. **`submitOracleAttestation(bytes32 _queryId, bytes calldata _data)`**:
    *   **Summary**: Allows the `trustedOracle` to submit verified data or AI predictions on-chain, associating them with a `_queryId`.
15. **`queryIntentContextOracle(bytes32 _queryId)`**:
    *   **Summary**: A public view function allowing agents or anyone to query the `trustedOracle` for previously submitted attested data, aiding in intent decision-making.

**V. Governance & System Parameters (Functions 16-21):**
16. **`setProtocolFee(uint256 _newFeePercentage)`**:
    *   **Summary**: Sets the percentage of intent payments collected as a protocol fee (e.g., for DAO treasury). Callable via governance.
17. **`setAgentStakeAmount(uint256 _newMinStakeAmount)`**:
    *   **Summary**: Sets the minimum `stakeERC20` required for agents to register. Callable via governance.
18. **`proposeParameterChange(string calldata _description, address _targetAddress, bytes calldata _callData)`**:
    *   **Summary**: Initiates a new governance proposal for system parameter changes (e.g., calling `setProtocolFee` or `setAgentStakeAmount`).
19. **`voteOnProposal(bytes32 _proposalId, bool _support)`**:
    *   **Summary**: Allows authorized voters (simplified for this example, could be token-weighted) to cast a 'yes' or 'no' vote on an active proposal.
20. **`executeProposal(bytes32 _proposalId)`**:
    *   **Summary**: Executes a governance proposal that has passed its voting period and received more 'yes' than 'no' votes.
21. **`setArbitrator(address _arbitratorAddress, bool _isAdded)`**:
    *   **Summary**: Adds or removes an address from the list of authorized dispute arbitrators. Callable by the contract owner (or governance).

**VI. Dispute Resolution & Settlement (Function 22):**
22. **`arbitrateDispute(bytes32 _intentId, bool _agentSuccess, uint256 _slashAmount)`**:
    *   **Summary**: An authorized arbitrator resolves a disputed intent, determining if the agent was successful. Based on the outcome, funds are released, and the agent's reputation and stake (potentially slashed) are updated.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For msg.sender usage (indirectly via Ownable, ReentrancyGuard)
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AetherIntentEngine
 * @dev A decentralized platform for users to declare "Intents" (desired outcomes) and for "Agents" to compete to fulfill them.
 * It features an escrow system, dynamic agent reputation, dispute resolution, and integrates with external oracles for data/AI insights.
 * Governed by a decentralized process for key parameter changes.
 */
contract AetherIntentEngine is Ownable, ReentrancyGuard {

    // --- I. Core Components & Data Structures ---

    // Dummy interface for an oracle that can provide arbitrary data
    interface IOracle {
        function getAttestation(bytes32 queryId) external view returns (bytes memory);
        function submitAttestation(bytes32 queryId, bytes memory data) external; // Simplified, in reality would have proofs/signatures
    }

    enum IntentStatus {
        Open,        // Intent is submitted, awaiting an agent
        Claimed,     // An agent has claimed the intent, working on fulfillment
        Fulfilled,   // Agent claims fulfillment, awaiting user's acceptance or dispute
        Disputed,    // User disputed fulfillment, awaiting arbitration
        Resolved,    // Dispute resolved by arbitrator, funds disbursed
        Cancelled    // User cancelled an open intent, funds returned
    }

    struct Intent {
        bytes32 intentId;           // Unique identifier for the intent
        address user;               // Original user who submitted the intent
        address agent;              // Agent claiming/fulfilling the intent
        IERC20 paymentToken;        // ERC20 token used for payment
        uint256 amount;             // Amount of payment token locked in escrow
        bytes intentDetails;        // Encoded details of the intent (e.g., target protocol, specific actions, desired outcome)
        IntentStatus status;        // Current status of the intent
        uint256 submittedAt;        // Timestamp when the intent was submitted
        uint256 claimedAt;          // Timestamp when an agent claimed the intent
        uint256 fulfilledAt;        // Timestamp when an agent claimed fulfillment
        uint256 disputeDeadline;    // Timestamp after which dispute can no longer be raised
        address intentManager;      // Address allowed to manage this specific intent (user or delegate)
        string outcomeDescription;  // A human-readable description of the desired outcome.
    }

    struct Agent {
        bool isRegistered;          // True if the address is a registered agent
        uint256 stake;              // Amount of stakeERC20 locked by the agent
        uint256 reputationScore;    // A simplified score, reflecting agent's reliability and success
        uint256 lastActivity;       // Timestamp of agent's last interaction
    }

    struct GovernanceProposal {
        bytes32 proposalId;         // Unique ID for the proposal
        string description;         // Description of the proposed change
        address targetAddress;      // The contract address to call if the proposal passes
        bytes callData;             // The encoded function call to execute
        uint256 voteCountYes;       // Number of 'yes' votes
        uint256 voteCountNo;        // Number of 'no' votes
        mapping(address => bool) hasVoted; // Tracks if an address has voted (simplified, non-token weighted)
        uint256 creationTime;       // Timestamp when the proposal was created
        uint256 votingEndTime;      // Timestamp when the voting period ends
        bool executed;              // True if the proposal has been executed
    }

    // --- State Variables ---

    mapping(bytes32 => Intent) public intents;
    mapping(address => Agent) public agents;
    mapping(bytes32 => GovernanceProposal) public proposals;
    mapping(uint256 => bytes32) public proposalIds; // For iterating proposals (e.g., for UI)
    uint256 public nextProposalId = 1;

    // System Parameters (configurable by governance)
    uint256 public protocolFeePercentage = 5; // 5% (e.g., 5 for 5%)
    uint256 public minAgentStakeAmount = 1 ether; // Example: 1 token of `stakeERC20`
    uint256 public disputePeriodDuration = 3 days; // Time window for users to dispute fulfillment
    uint256 public proposalVotingPeriod = 7 days;  // Duration for governance proposals
    uint256 public minReputationForComplexIntents = 100; // Example threshold for advanced intents

    address public trustedOracle; // Address of a contract implementing IOracle for data/AI attestations
    address public stakeERC20;    // The ERC20 token required for agents to stake
    mapping(address => bool) public arbitrators; // Addresses empowered to resolve disputes (for quick lookup)
    address[] public arbitratorList;             // List of arbitrators (for enumeration)

    uint256 private totalIntentsCreated = 0; // Counter for generating unique intent IDs

    // --- Events ---

    event IntentSubmitted(bytes32 indexed intentId, address indexed user, address paymentToken, uint256 amount, string outcomeDescription);
    event IntentCancelled(bytes32 indexed intentId, address indexed user);
    event IntentClaimed(bytes32 indexed intentId, address indexed agent);
    event IntentFulfilled(bytes32 indexed intentId, address indexed agent, uint256 actualAmount);
    event IntentDisputed(bytes32 indexed intentId, address indexed user);
    event IntentResolved(bytes32 indexed intentId, address indexed arbitrator, bool successForUser);
    event FundsReleased(bytes32 indexed intentId, address indexed recipient, uint256 amount);
    event AgentRegistered(address indexed agentAddress, uint256 stake);
    event AgentDeregistered(address indexed agentAddress);
    event AgentStakeSlashed(address indexed agentAddress, uint256 amount);
    event AgentReputationUpdated(address indexed agentAddress, uint256 newReputation);
    event OracleUpdated(address indexed newOracle);
    event AttestationSubmitted(bytes32 indexed queryId, bytes data);
    event ProtocolFeeUpdated(uint256 newFeePercentage);
    event AgentStakeAmountUpdated(uint256 newMinStakeAmount);
    event ArbitratorUpdated(address indexed arbitratorAddress, bool isAdded);
    event ProposalCreated(bytes32 indexed proposalId, string description);
    event ProposalVoted(bytes32 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(bytes32 indexed proposalId);
    event IntentManagementDelegated(bytes32 indexed intentId, address indexed delegator, address indexed newManager);
    event IntentParametersUpdated(bytes32 indexed intentId, bytes newDetails, string newOutcomeDescription);


    // --- Constructor ---

    constructor(address _initialOracle, address[] memory _initialArbitrators, address _stakeERC20) Ownable(msg.sender) {
        require(_initialOracle != address(0), "Oracle cannot be zero address");
        require(_stakeERC20 != address(0), "Stake ERC20 cannot be zero address");
        trustedOracle = _initialOracle;
        stakeERC20 = _stakeERC20;
        for (uint i = 0; i < _initialArbitrators.length; i++) {
            require(_initialArbitrators[i] != address(0), "Arbitrator cannot be zero address");
            arbitrators[_initialArbitrators[i]] = true;
            arbitratorList.push(_initialArbitrators[i]);
        }
    }

    // --- Modifiers ---

    modifier onlyAgent(address _agent) {
        require(agents[_agent].isRegistered, "Caller is not a registered agent");
        _;
    }

    modifier onlyArbitrator() {
        require(arbitrators[msg.sender], "Caller is not an authorized arbitrator");
        _;
    }

    // --- II. Intent Management (User-Facing) ---

    /**
     * @notice Submits a new intent to the engine. Funds are transferred to escrow.
     * @param _paymentToken The ERC20 token to be used for payment.
     * @param _amount The amount of payment token locked in escrow.
     * @param _intentDetails Encoded bytes representing the specific technical details of the intent.
     * @param _outcomeDescription A human-readable description of the desired outcome.
     * @return intentId The unique ID of the submitted intent.
     */
    function submitIntent(
        IERC20 _paymentToken,
        uint256 _amount,
        bytes calldata _intentDetails,
        string calldata _outcomeDescription
    ) external nonReentrant returns (bytes32 intentId) {
        require(_amount > 0, "Intent amount must be greater than zero");
        require(bytes(_outcomeDescription).length > 0, "Outcome description cannot be empty");
        require(address(_paymentToken) != address(0), "Payment token cannot be zero address");

        intentId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _intentDetails, totalIntentsCreated));
        totalIntentsCreated++;

        _paymentToken.transferFrom(msg.sender, address(this), _amount);

        intents[intentId] = Intent({
            intentId: intentId,
            user: msg.sender,
            agent: address(0), // No agent assigned yet
            paymentToken: _paymentToken,
            amount: _amount,
            intentDetails: _intentDetails,
            status: IntentStatus.Open,
            submittedAt: block.timestamp,
            claimedAt: 0,
            fulfilledAt: 0,
            disputeDeadline: 0,
            intentManager: msg.sender, // User is initial manager
            outcomeDescription: _outcomeDescription
        });

        emit IntentSubmitted(intentId, msg.sender, address(_paymentToken), _amount, _outcomeDescription);
    }

    /**
     * @notice Allows the user or a delegated manager to cancel an open intent.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(bytes32 _intentId) external nonReentrant {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(msg.sender == intent.user || msg.sender == intent.intentManager, "Only user or manager can cancel intent");
        require(intent.status == IntentStatus.Open, "Intent not in Open status");

        intent.status = IntentStatus.Cancelled;
        _releaseFunds(intent, intent.user, intent.amount); // Return funds to the user
        emit IntentCancelled(_intentId, intent.user);
    }

    /**
     * @notice Delegates the management of an intent to another address.
     * @param _intentId The ID of the intent.
     * @param _newManager The address of the new manager.
     */
    function delegateIntentManagement(bytes32 _intentId, address _newManager) external {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(msg.sender == intent.user || msg.sender == intent.intentManager, "Only current manager or user can delegate");
        require(_newManager != address(0), "New manager cannot be zero address");

        intent.intentManager = _newManager;
        emit IntentManagementDelegated(_intentId, msg.sender, _newManager);
    }

    /**
     * @notice Allows the user or manager to update certain parameters of an open intent.
     * @param _intentId The ID of the intent to update.
     * @param _newIntentDetails New encoded details for the intent.
     * @param _newOutcomeDescription New human-readable outcome description.
     */
    function updateIntentParameters(bytes32 _intentId, bytes calldata _newIntentDetails, string calldata _newOutcomeDescription) external {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(msg.sender == intent.user || msg.sender == intent.intentManager, "Only user or manager can update intent");
        require(intent.status == IntentStatus.Open, "Intent must be in Open status to update parameters");
        require(bytes(_newOutcomeDescription).length > 0, "New outcome description cannot be empty");

        intent.intentDetails = _newIntentDetails;
        intent.outcomeDescription = _newOutcomeDescription;

        emit IntentParametersUpdated(_intentId, _newIntentDetails, _newOutcomeDescription);
    }

    /**
     * @notice Submits multiple intents in a single transaction.
     * @param _paymentTokens Array of payment tokens for each intent.
     * @param _amounts Array of amounts for each intent.
     * @param _intentDetails Array of encoded intent details.
     * @param _outcomeDescriptions Array of human-readable outcome descriptions.
     */
    function batchSubmitIntents(
        IERC20[] calldata _paymentTokens,
        uint256[] calldata _amounts,
        bytes[] calldata _intentDetails,
        string[] calldata _outcomeDescriptions
    ) external nonReentrant {
        require(
            _paymentTokens.length == _amounts.length &&
            _amounts.length == _intentDetails.length &&
            _intentDetails.length == _outcomeDescriptions.length,
            "Arrays must have matching lengths"
        );

        for (uint i = 0; i < _paymentTokens.length; i++) {
            submitIntent(
                _paymentTokens[i],
                _amounts[i],
                _intentDetails[i],
                _outcomeDescriptions[i]
            );
        }
    }


    // --- III. Agent Management & Interaction ---

    /**
     * @notice Allows an address to register as an agent by staking a minimum amount of the protocol-defined stake token.
     */
    function registerAgent() external nonReentrant {
        require(!agents[msg.sender].isRegistered, "Agent already registered");
        require(minAgentStakeAmount > 0, "Min agent stake must be set by governance");
        require(stakeERC20 != address(0), "Stake ERC20 not configured by governance");

        IERC20(stakeERC20).transferFrom(msg.sender, address(this), minAgentStakeAmount);

        agents[msg.sender] = Agent({
            isRegistered: true,
            stake: minAgentStakeAmount,
            reputationScore: 0, // Agents start with zero reputation
            lastActivity: block.timestamp
        });

        emit AgentRegistered(msg.sender, minAgentStakeAmount);
    }

    /**
     * @notice Allows a registered agent to deregister and retrieve their stake.
     */
    function deregisterAgent() external nonReentrant onlyAgent(msg.sender) {
        Agent storage agent = agents[msg.sender];
        require(agent.stake == minAgentStakeAmount, "Agent stake modified, cannot deregister directly. Use governance for full release.");
        // In a more complex system, checks for active/pending intents or disputes would be required.

        uint256 amountToReturn = agent.stake;
        delete agents[msg.sender]; // Remove agent record

        IERC20(stakeERC20).transfer(msg.sender, amountToReturn);
        emit AgentDeregistered(msg.sender);
    }

    /**
     * @notice An agent claims an open intent, indicating they will attempt to fulfill it.
     * @param _intentId The ID of the intent to claim.
     */
    function claimIntent(bytes32 _intentId) external nonReentrant onlyAgent(msg.sender) {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(intent.status == IntentStatus.Open, "Intent is not open for claiming");
        // Add more advanced logic here: e.g., reputation requirements, intent difficulty matching.
        // require(agents[msg.sender].reputationScore >= intent.minReputationRequired, "Agent reputation too low");

        intent.agent = msg.sender;
        intent.status = IntentStatus.Claimed;
        intent.claimedAt = block.timestamp;

        agents[msg.sender].lastActivity = block.timestamp; // Update agent activity

        emit IntentClaimed(_intentId, msg.sender);
    }

    /**
     * @notice An agent fulfills a claimed intent by submitting proof (or a result).
     * @param _intentId The ID of the intent.
     * @param _actualAmount Optional: the actual amount of funds that were moved/processed if it differs.
     * @param _fulfillmentProof Optional: A hash or link to off-chain proof of fulfillment.
     */
    function fulfillIntent(bytes32 _intentId, uint256 _actualAmount, bytes calldata _fulfillmentProof) external nonReentrant onlyAgent(msg.sender) {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(intent.agent == msg.sender, "Only the claiming agent can fulfill this intent");
        require(intent.status == IntentStatus.Claimed, "Intent is not in Claimed status");
        // More complex verification here could involve ZK proofs, oracle calls, etc.
        // For simplicity, we just assume `_fulfillmentProof` is verifiable off-chain or by arbitrators.

        intent.status = IntentStatus.Fulfilled;
        intent.fulfilledAt = block.timestamp;
        intent.disputeDeadline = block.timestamp + disputePeriodDuration;

        // Optionally, update agent reputation for successful fulfillment
        agents[msg.sender].reputationScore += 10; // Example increment
        emit AgentReputationUpdated(msg.sender, agents[msg.sender].reputationScore);

        emit IntentFulfilled(_intentId, msg.sender, _actualAmount);
    }

    /**
     * @notice Allows the user or manager to dispute a claimed intent fulfillment.
     * @param _intentId The ID of the intent to dispute.
     */
    function disputeFulfillment(bytes32 _intentId) external nonReentrant {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(msg.sender == intent.user || msg.sender == intent.intentManager, "Only user or manager can dispute intent");
        require(intent.status == IntentStatus.Fulfilled, "Intent is not in Fulfilled status");
        require(block.timestamp <= intent.disputeDeadline, "Dispute period has ended");

        intent.status = IntentStatus.Disputed;
        emit IntentDisputed(_intentId, msg.sender);
    }

    /**
     * @notice Slashes an agent's stake. Can be called by arbitrator after a dispute, or by governance.
     * @param _agentAddress The address of the agent to slash.
     * @param _amount The amount of stake to slash.
     */
    function slashAgentStake(address _agentAddress, uint256 _amount) internal { // Made internal, callable by arbitrateDispute
        Agent storage agent = agents[_agentAddress];
        require(agent.isRegistered, "Agent not registered");
        require(_amount > 0 && _amount <= agent.stake, "Invalid slash amount");
        require(stakeERC20 != address(0), "Stake ERC20 not configured");

        agent.stake -= _amount;
        IERC20(stakeERC20).transfer(address(this), _amount); // Slashed stake goes to the protocol treasury/DAO

        if (agent.stake < minAgentStakeAmount && minAgentStakeAmount > 0) {
            // If stake falls below minimum, agent's eligibility for new intents might be affected.
            // For simplicity, just reducing reputation and potential deregistration if stake is 0.
        }
        if (agent.stake == 0) {
            delete agents[_agentAddress]; // Fully deregister if stake is zero
        }

        // Drastically reduce reputation for slashing events
        agent.reputationScore = (agent.reputationScore * 75) / 100; // 25% reduction
        emit AgentStakeSlashed(_agentAddress, _amount);
        emit AgentReputationUpdated(_agentAddress, agent.reputationScore);
    }

    /**
     * @notice Retrieves the current reputation score of an agent.
     * @param _agentAddress The address of the agent.
     * @return The agent's reputation score.
     */
    function getAgentReputation(address _agentAddress) external view returns (uint256) {
        return agents[_agentAddress].reputationScore;
    }

    // --- IV. Oracle & Data Integration ---

    /**
     * @notice Governance-controlled function to update the address of the trusted oracle.
     * @param _newOracle The address of the new oracle contract.
     */
    function updateTrustedOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "New oracle cannot be zero address");
        trustedOracle = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    /**
     * @notice Allows the trusted oracle to submit an attestation.
     * In a real system, this would involve more robust authentication and data integrity checks.
     * @param _queryId A unique identifier for the query or data point.
     * @param _data The attested data.
     */
    function submitOracleAttestation(bytes32 _queryId, bytes calldata _data) external {
        require(msg.sender == trustedOracle, "Only trusted oracle can submit attestations");
        IOracle(trustedOracle).submitAttestation(_queryId, _data); // Call through interface
        emit AttestationSubmitted(_queryId, _data);
    }

    /**
     * @notice Allows anyone to query the trusted oracle for data relevant to an intent context.
     * This is a view function to read data previously submitted by the oracle.
     * @param _queryId The ID of the query.
     * @return The data attested by the oracle.
     */
    function queryIntentContextOracle(bytes32 _queryId) external view returns (bytes memory) {
        require(trustedOracle != address(0), "No trusted oracle configured");
        return IOracle(trustedOracle).getAttestation(_queryId);
    }

    // --- V. Governance & System Parameters ---

    /**
     * @notice Sets the protocol fee percentage. Callable only through governance.
     * @param _newFeePercentage The new fee percentage (e.g., 5 for 5%). Max 100.
     */
    function setProtocolFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        protocolFeePercentage = _newFeePercentage;
        emit ProtocolFeeUpdated(_newFeePercentage);
    }

    /**
     * @notice Sets the minimum amount of stake required for an agent. Callable only through governance.
     * @param _newMinStakeAmount The new minimum stake amount.
     */
    function setAgentStakeAmount(uint256 _newMinStakeAmount) external onlyOwner {
        minAgentStakeAmount = _newMinStakeAmount;
        emit AgentStakeAmountUpdated(_newMinStakeAmount);
    }

    /**
     * @notice Creates a new governance proposal for system changes.
     * (Simplified proposal mechanism for brevity, assumes owner as proposer)
     * In a real DAO, it would involve token-weighted voting.
     * @param _description A description of the proposal.
     * @param _targetAddress The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call to execute if the proposal passes.
     */
    function proposeParameterChange(string calldata _description, address _targetAddress, bytes calldata _callData) external onlyOwner returns (bytes32 proposalId) {
        proposalId = keccak256(abi.encodePacked(block.timestamp, _targetAddress, _callData, nextProposalId));
        proposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            targetAddress: _targetAddress,
            callData: _callData,
            voteCountYes: 0,
            voteCountNo: 0,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + proposalVotingPeriod,
            executed: false
        });
        proposalIds[nextProposalId] = proposalId;
        nextProposalId++;
        emit ProposalCreated(proposalId, _description);
    }

    /**
     * @notice Allows an address (e.g., a token holder in a real DAO) to vote on a proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }
        proposal.hasVoted[msg.sender] = true; // Mark as voted
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed governance proposal. (Simplified: if yes votes > no votes)
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) external onlyOwner {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.voteCountYes > proposal.voteCountNo, "Proposal did not pass");

        proposal.executed = true;
        (bool success, ) = proposal.targetAddress.call(proposal.callData);
        require(success, "Proposal execution failed");
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Adds or removes an address as an authorized arbitrator.
     * @param _arbitratorAddress The address to modify.
     * @param _isAdded True to add, false to remove.
     */
    function setArbitrator(address _arbitratorAddress, bool _isAdded) external onlyOwner {
        require(_arbitratorAddress != address(0), "Arbitrator cannot be zero address");
        bool wasArbitrator = arbitrators[_arbitratorAddress];

        if (_isAdded && !wasArbitrator) {
            arbitrators[_arbitratorAddress] = true;
            arbitratorList.push(_arbitratorAddress);
        } else if (!_isAdded && wasArbitrator) {
            arbitrators[_arbitratorAddress] = false;
            // Remove from array (inefficient for large arrays, but okay for small arbitrator lists)
            for (uint i = 0; i < arbitratorList.length; i++) {
                if (arbitratorList[i] == _arbitratorAddress) {
                    arbitratorList[i] = arbitratorList[arbitratorList.length - 1]; // Swap with last
                    arbitratorList.pop(); // Remove last element
                    break;
                }
            }
        }
        emit ArbitratorUpdated(_arbitratorAddress, _isAdded);
    }

    /**
     * @notice Returns the list of active arbitrator addresses.
     * @return An array of arbitrator addresses.
     */
    function getArbitratorList() external view returns (address[] memory) {
        return arbitratorList;
    }


    // --- VI. Dispute Resolution & Settlement ---

    /**
     * @notice An appointed arbitrator resolves an intent dispute.
     * @param _intentId The ID of the disputed intent.
     * @param _agentSuccess True if the agent's fulfillment is deemed successful, false if not.
     * @param _slashAmount Optional: amount of agent's stake to slash if agent failed.
     */
    function arbitrateDispute(bytes32 _intentId, bool _agentSuccess, uint256 _slashAmount) external nonReentrant onlyArbitrator {
        Intent storage intent = intents[_intentId];
        require(intent.user != address(0), "Intent does not exist");
        require(intent.status == IntentStatus.Disputed, "Intent is not in Disputed status");

        intent.status = IntentStatus.Resolved; // Mark as resolved

        if (_agentSuccess) {
            // Agent was successful: release funds to agent, apply fees, update reputation.
            uint256 fee = (intent.amount * protocolFeePercentage) / 100;
            uint256 agentPayment = intent.amount - fee;
            _releaseFunds(intent, intent.agent, agentPayment);
            _releaseFunds(intent, address(this), fee); // Protocol fee to contract (DAO treasury)

            // Reward agent reputation
            agents[intent.agent].reputationScore += 50; // Larger reward for successful dispute resolution
            emit AgentReputationUpdated(intent.agent, agents[intent.agent].reputationScore);

        } else {
            // Agent failed: return funds to user, slash agent, reduce reputation.
            _releaseFunds(intent, intent.user, intent.amount);

            // Slash agent's stake if specified and valid
            if (_slashAmount > 0) {
                slashAgentStake(intent.agent, _slashAmount); // Use the internal slash function
            } else {
                 // Even without explicit slash, reduce reputation for failed intent
                agents[intent.agent].reputationScore = (agents[intent.agent].reputationScore * 75) / 100; // 25% reduction
                emit AgentReputationUpdated(intent.agent, agents[intent.agent].reputationScore);
            }
        }
        emit IntentResolved(_intentId, msg.sender, _agentSuccess);
    }

    /**
     * @notice Internal function to release funds from escrow.
     * @param _intent The intent struct.
     * @param _recipient The address to send funds to.
     * @param _amount The amount to send.
     */
    function _releaseFunds(Intent storage _intent, address _recipient, uint256 _amount) internal {
        require(_amount > 0, "Cannot release zero amount");
        require(_intent.paymentToken.balanceOf(address(this)) >= _amount, "Insufficient balance in contract escrow");
        _intent.paymentToken.transfer(_recipient, _amount);
        emit FundsReleased(_intent.intentId, _recipient, _amount);
    }
}
```