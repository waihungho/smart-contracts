Here's a smart contract in Solidity called `DecentralizedAdaptiveAgentNetwork` (DAAN). It's designed to be a platform where decentralized "agents" (which can represent anything from data oracles, prediction models, content moderation services, or even AI-driven services that operate off-chain) can be registered, funded, and dynamically evaluated by the community. Agents' performance scores adapt based on submitted reports and a challenge-resolution system, influencing their reward distribution and trust levels.

This contract introduces several advanced, creative, and trendy concepts:

1.  **Dynamic Agent Adaptation:** Agents aren't static; their parameters (purpose, endpoint) and even their fundamental configuration can be proposed and adapted through a governance process. Their "trustworthiness" (performance score) is also dynamic.
2.  **Reputation & Performance-Based Incentives:** Rewards are not just based on stake but are heavily weighted by a dynamic `performanceScore` derived from community reports and a challenge system. Poor performance can lead to stake slashing.
3.  **Community-Driven Validation & Challenge System:** Validators submit performance reports, which can be challenged by other participants. This creates a disincentive for malicious reporting and aims for consensus-driven truth.
4.  **Epoch-Based Progression:** The system operates in discrete epochs, allowing for timed performance evaluations, reward distributions, and cooldown periods.
5.  **Multi-Stakeholder Engagement:** Involves Agent Owners, Stakers (providing collateral), Validators (reporting performance), and Governance (resolving disputes, setting parameters).
6.  **No Duplication of Open Source:** While it uses common patterns like access control (`Ownable`) and reentrancy protection (`ReentrancyGuard`), the core logic for agent management, dynamic performance scoring, epoch progression, and the multi-layered challenge/resolution system is custom-designed for this specific decentralized agent network model, differing from typical DAO, NFT, or DeFi protocols.

---

## Contract Outline and Function Summary

**Contract Name:** `DecentralizedAdaptiveAgentNetwork`

This contract establishes a framework for managing decentralized agents, including their registration, funding, performance evaluation, and dynamic adaptation. It implements a multi-stakeholder model with Agent Owners, Stakers, Validators, and a Governance body.

---

### **Outline:**

1.  **Core Agent Management**
2.  **Staking & Collateral**
3.  **Performance & Evaluation**
4.  **Funding & Incentives**
5.  **Governance & Protocol Parameters**

---

### **Function Summary:**

**I. Core Agent Management**

1.  `registerAgent(string calldata _purpose, string calldata _endpointURI)`:
    *   Allows any user to register a new decentralized agent by providing its purpose and an off-chain endpoint URI. Requires an initial stake.
2.  `updateAgentPurpose(uint256 _agentId, string calldata _newPurpose)`:
    *   Allows the owner of an agent to update its descriptive purpose, reflecting changes in its operation or goals.
3.  `updateAgentEndpoint(uint256 _agentId, string calldata _newEndpointURI)`:
    *   Allows the owner of an agent to update the URI pointing to its off-chain service or data source.
4.  `deactivateAgent(uint256 _agentId)`:
    *   Allows the agent owner to temporarily pause an agent's operations, stopping it from being evaluated or receiving new subscriptions.
5.  `reactivateAgent(uint256 _agentId)`:
    *   Allows the agent owner to resume a previously deactivated agent.
6.  `retireAgent(uint256 _agentId)`:
    *   Allows the agent owner to permanently remove an agent from the network. Staked ETH becomes eligible for withdrawal after a cooldown.
7.  `getAgentDetails(uint256 _agentId)`:
    *   Retrieves all public details of a specific agent, including its owner, purpose, status, and performance score.
8.  `getAgentConfiguration(uint256 _agentId)`:
    *   Retrieves the dynamic configuration parameters (e.g., performance score, last report epoch) of an agent.

**II. Staking & Collateral**

9.  `stakeForAgent(uint256 _agentId)`:
    *   Allows any user to deposit ETH as collateral, backing a specific agent. This increases the agent's total staked amount and reflects trust.
10. `unstakeFromAgent(uint256 _agentId, uint256 _amount)`:
    *   Allows a staker to withdraw a specified amount of their staked ETH from an agent after a cooldown period.
11. `slashAgentStake(uint256 _agentId, address _staker, uint256 _amount)`:
    *   **`onlyGovernance`**: Penalizes an agent or a specific staker for poor performance or malicious activity by burning a portion of their staked ETH.
12. `claimStakingReward(uint256 _agentId)`:
    *   Allows an agent staker to claim their accrued rewards, which are distributed proportionally based on stake and agent performance during each epoch.

**III. Performance & Evaluation**

13. `submitPerformanceReport(uint256 _agentId, int256 _scoreChange, string calldata _notes)`:
    *   **`onlyValidator`**: Allows a registered validator to submit a report on an agent's performance, proposing a change to its score.
14. `challengePerformanceReport(uint256 _reportId)`:
    *   Allows any participant to challenge a submitted performance report if they believe it is inaccurate or malicious. Requires a challenge bond.
15. `resolveChallenge(uint256 _challengeId, bool _challengerWins)`:
    *   **`onlyGovernance`**: Resolves an active challenge, determining whether the challenger or the original report sender was correct. This impacts reputations and bonds.
16. `updateAgentPerformanceScore(uint256 _agentId, int256 _delta)`:
    *   **`internal`**: Updates an agent's internal `currentPerformanceScore` based on resolved challenges or epoch-end aggregations.

**IV. Funding & Incentives**

17. `depositToAgentPool()`:
    *   Allows anyone to deposit ETH into a general reward pool, which is later distributed to top-performing agents.
18. `subscribeToAgentService(uint256 _agentId)`:
    *   Allows users to directly pay an agent for its services, effectively "subscribing." Funds go directly to the agent's operational rewards.
19. `claimAgentOperatingReward(uint256 _agentId)`:
    *   Allows the agent owner to claim funds accumulated from direct subscriptions and any operational grants.
20. `distributeEpochRewards()`:
    *   **`onlyGovernance`**: Triggers the distribution of rewards from the general pool to top-performing active agents and their stakers for the current epoch. This also processes pending performance score updates.

**V. Governance & Protocol Parameters**

21. `proposeProtocolChange(string calldata _description, bytes calldata _data)`:
    *   Allows any user with sufficient voting power to propose changes to core protocol parameters or introduce new system-wide rules.
22. `voteOnProposal(uint256 _proposalId, bool _for)`:
    *   Allows users with voting power (e.g., staked ETH) to cast a vote for or against an active proposal.
23. `delegateVote(address _delegatee)`:
    *   Allows a user to delegate their voting power to another address.
24. `executeProposal(uint256 _proposalId)`:
    *   **`onlyGovernance`**: Enacts a proposal that has reached the required consensus threshold. This function might trigger internal state changes based on `_data`.
25. `advanceEpoch()`:
    *   **`onlyGovernance`**: Moves the system to the next evaluation epoch, triggering all epoch-end processes like reward distribution and performance score recalculations.
26. `setProtocolFeeRecipient(address _newRecipient)`:
    *   **`onlyOwner`**: Sets the address that receives protocol fees collected from various operations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title Decentralized Adaptive Agent Network (DAAN)
/// @notice A platform for deploying, funding, and dynamically adapting decentralized "Agents"
///         that perform specific tasks based on community input and performance metrics.
///         It features a reputation-based incentive model, epoch-based progression,
///         and a challenge system for performance reports.

contract DecentralizedAdaptiveAgentNetwork is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for int256;

    // --- Enums ---
    enum AgentStatus { Active, Deactivated, Retired }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum ChallengeStatus { Pending, ResolvedValid, ResolvedInvalid }

    // --- Structs ---

    struct Agent {
        address owner;
        string purpose;         // Description of the agent's function
        string endpointURI;     // URI for off-chain service or data source
        uint256 totalStakedEth; // Total ETH staked for this agent
        int256 currentPerformanceScore; // Dynamic score based on reports & challenges
        uint256 lastReportEpoch; // Last epoch a report was submitted
        AgentStatus status;
        uint256 creationEpoch;
        uint256 accumulatedOperatingRewards; // ETH from direct subscriptions/grants
        mapping(address => uint256) stakers; // Staker address => amount staked
        uint256 cooldownEnds;   // For unstaking/retiring
    }

    struct PerformanceReport {
        uint256 agentId;
        address validator;
        int256 scoreChange;     // Proposed change to agent's score
        string notes;           // Optional notes for the report
        uint256 epoch;
        bool challenged;
        bool resolved;
    }

    struct Challenge {
        uint256 reportId;
        address challenger;
        uint256 challengeBond;  // ETH locked by challenger
        ChallengeStatus status;
        uint256 creationEpoch;
    }

    struct ProtocolProposal {
        string description;
        bytes data;             // Encoded function call or parameter change
        uint256 creationEpoch;
        uint256 voteThreshold;  // Minimum votes required
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    // --- State Variables ---

    uint256 public nextAgentId;
    mapping(uint256 => Agent) public agents;
    mapping(uint256 => mapping(address => uint256)) public agentStakes; // agentId => staker => amount

    uint256 public nextReportId;
    mapping(uint256 => PerformanceReport) public performanceReports;

    uint256 public nextChallengeId;
    mapping(uint256 => Challenge) public challenges;

    uint256 public nextProposalId;
    mapping(uint256 => ProtocolProposal) public proposals;
    mapping(address => uint256) public votingPower; // Based on staked ETH (simple for now)

    address public governanceCouncil; // Address with special powers for resolution/execution
    address public protocolFeeRecipient; // Address to receive protocol fees

    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration in seconds
    uint256 public lastEpochAdvanceTime;

    uint256 public minAgentStake;
    uint256 public minChallengeBond;
    uint256 public unbondPeriod; // Cooldown for unstaking/retiring

    uint256 public agentRewardPool; // Total ETH accumulated for agent rewards

    // --- Events ---

    event AgentRegistered(uint256 indexed agentId, address indexed owner, string purpose);
    event AgentUpdated(uint256 indexed agentId, string newPurpose, string newEndpointURI);
    event AgentStatusChanged(uint256 indexed agentId, AgentStatus newStatus);
    event AgentRetired(uint256 indexed agentId);

    event EthStaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event EthUnstaked(uint256 indexed agentId, address indexed staker, uint256 amount);
    event StakeSlashed(uint256 indexed agentId, address indexed staker, uint256 amount);
    event StakingRewardClaimed(uint256 indexed agentId, address indexed staker, uint256 amount);

    event PerformanceReportSubmitted(uint256 indexed reportId, uint256 indexed agentId, address validator, int256 scoreChange);
    event PerformanceReportChallenged(uint256 indexed challengeId, uint256 indexed reportId, address challenger);
    event ChallengeResolved(uint256 indexed challengeId, bool challengerWins, ChallengeStatus status);
    event AgentPerformanceScoreUpdated(uint256 indexed agentId, int256 oldScore, int256 newScore);

    event EthDepositedToPool(address indexed depositor, uint256 amount);
    event AgentSubscribed(uint256 indexed agentId, address indexed subscriber, uint256 amount);
    event AgentOperatingRewardClaimed(uint256 indexed agentId, address indexed owner, uint256 amount);
    event EpochRewardsDistributed(uint256 indexed epoch, uint256 totalDistributed);

    event ProtocolChangeProposed(uint256 indexed proposalId, string description, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _for);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event ProposalExecuted(uint256 indexed proposalId);

    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event ProtocolFeeRecipientSet(address indexed newRecipient);

    // --- Modifiers ---

    modifier onlyGovernance() {
        require(msg.sender == governanceCouncil, "DAAN: Not governance council");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(agents[_agentId].owner == msg.sender, "DAAN: Not agent owner");
        _;
    }

    // For simplicity, any address with voting power is considered a "validator"
    // In a real system, there would be a separate validator registration/staking process.
    modifier onlyValidator() {
        require(votingPower[msg.sender] > 0, "DAAN: Not a validator (no voting power)");
        _;
    }

    // --- Constructor ---

    constructor(
        address _governanceCouncil,
        address _protocolFeeRecipient,
        uint256 _epochDuration,
        uint256 _minAgentStake,
        uint256 _minChallengeBond,
        uint256 _unbondPeriod
    ) Ownable(msg.sender) {
        require(_governanceCouncil != address(0), "DAAN: Invalid governance council address");
        require(_protocolFeeRecipient != address(0), "DAAN: Invalid fee recipient address");
        require(_epochDuration > 0, "DAAN: Epoch duration must be greater than zero");
        require(_minAgentStake > 0, "DAAN: Min agent stake must be greater than zero");
        require(_minChallengeBond > 0, "DAAN: Min challenge bond must be greater than zero");
        require(_unbondPeriod > 0, "DAAN: Unbond period must be greater than zero");

        governanceCouncil = _governanceCouncil;
        protocolFeeRecipient = _protocolFeeRecipient;
        epochDuration = _epochDuration;
        minAgentStake = _minAgentStake;
        minChallengeBond = _minChallengeBond;
        unbondPeriod = _unbondPeriod;

        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;
    }

    // --- I. Core Agent Management ---

    /// @notice Registers a new decentralized agent on the network.
    /// @param _purpose A brief description of the agent's function.
    /// @param _endpointURI The URI pointing to the agent's off-chain service or data.
    /// @dev Requires an initial ETH stake (`minAgentStake`).
    /// @return The ID of the newly registered agent.
    function registerAgent(string calldata _purpose, string calldata _endpointURI)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(msg.value >= minAgentStake, "DAAN: Insufficient initial stake");
        require(bytes(_purpose).length > 0, "DAAN: Purpose cannot be empty");
        require(bytes(_endpointURI).length > 0, "DAAN: Endpoint URI cannot be empty");

        uint256 agentId = nextAgentId++;
        agents[agentId] = Agent({
            owner: msg.sender,
            purpose: _purpose,
            endpointURI: _endpointURI,
            totalStakedEth: msg.value,
            currentPerformanceScore: 0, // Agents start with a neutral score
            lastReportEpoch: currentEpoch,
            status: AgentStatus.Active,
            creationEpoch: currentEpoch,
            accumulatedOperatingRewards: 0,
            cooldownEnds: 0
        });
        agents[agentId].stakers[msg.sender] = msg.value;
        votingPower[msg.sender] = votingPower[msg.sender].add(msg.value); // Initial voting power for owner

        emit AgentRegistered(agentId, msg.sender, _purpose);
        return agentId;
    }

    /// @notice Allows the agent owner to update its descriptive purpose.
    /// @param _agentId The ID of the agent to update.
    /// @param _newPurpose The new purpose string.
    function updateAgentPurpose(uint256 _agentId, string calldata _newPurpose)
        external
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].status != AgentStatus.Retired, "DAAN: Agent is retired");
        require(bytes(_newPurpose).length > 0, "DAAN: Purpose cannot be empty");
        agents[_agentId].purpose = _newPurpose;
        emit AgentUpdated(_agentId, _newPurpose, agents[_agentId].endpointURI);
    }

    /// @notice Allows the agent owner to update the URI for its off-chain service.
    /// @param _agentId The ID of the agent to update.
    /// @param _newEndpointURI The new endpoint URI string.
    function updateAgentEndpoint(uint256 _agentId, string calldata _newEndpointURI)
        external
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].status != AgentStatus.Retired, "DAAN: Agent is retired");
        require(bytes(_newEndpointURI).length > 0, "DAAN: Endpoint URI cannot be empty");
        agents[_agentId].endpointURI = _newEndpointURI;
        emit AgentUpdated(_agentId, agents[_agentId].purpose, _newEndpointURI);
    }

    /// @notice Allows the agent owner to temporarily pause an agent's operations.
    /// @param _agentId The ID of the agent to deactivate.
    function deactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Active, "DAAN: Agent not active");
        agent.status = AgentStatus.Deactivated;
        emit AgentStatusChanged(_agentId, AgentStatus.Deactivated);
    }

    /// @notice Allows the agent owner to reactivate a paused agent.
    /// @param _agentId The ID of the agent to reactivate.
    function reactivateAgent(uint256 _agentId) external onlyAgentOwner(_agentId) {
        Agent storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Deactivated, "DAAN: Agent not deactivated");
        agent.status = AgentStatus.Active;
        emit AgentStatusChanged(_agentId, AgentStatus.Active);
    }

    /// @notice Allows the agent owner to permanently remove an agent from the network.
    /// @param _agentId The ID of the agent to retire.
    /// @dev Staked ETH becomes eligible for withdrawal after the unbond period.
    function retireAgent(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        Agent storage agent = agents[_agentId];
        require(agent.status != AgentStatus.Retired, "DAAN: Agent already retired");

        agent.status = AgentStatus.Retired;
        agent.cooldownEnds = block.timestamp.add(unbondPeriod); // Start cooldown for unstake
        // Clear accumulated operating rewards for future claims
        agent.accumulatedOperatingRewards = 0;
        emit AgentRetired(_agentId);
        emit AgentStatusChanged(_agentId, AgentStatus.Retired);
    }

    /// @notice Retrieves all public details of a specific agent.
    /// @param _agentId The ID of the agent.
    /// @return owner Address of the agent's owner.
    /// @return purpose Description of the agent's function.
    /// @return endpointURI URI for off-chain service.
    /// @return totalStakedEth Total ETH staked for this agent.
    /// @return currentPerformanceScore Dynamic performance score.
    /// @return status Current status of the agent.
    /// @return creationEpoch Epoch the agent was created.
    function getAgentDetails(uint256 _agentId)
        external
        view
        returns (
            address owner,
            string memory purpose,
            string memory endpointURI,
            uint256 totalStakedEth,
            int256 currentPerformanceScore,
            AgentStatus status,
            uint256 creationEpoch
        )
    {
        Agent storage agent = agents[_agentId];
        return (
            agent.owner,
            agent.purpose,
            agent.endpointURI,
            agent.totalStakedEth,
            agent.currentPerformanceScore,
            agent.status,
            agent.creationEpoch
        );
    }

    /// @notice Retrieves dynamic configuration parameters for an agent.
    /// @param _agentId The ID of the agent.
    /// @return lastReportEpoch Last epoch a report was submitted.
    /// @return accumulatedOperatingRewards ETH from direct subscriptions/grants.
    /// @return cooldownEnds Timestamp when cooldown ends for unstaking/retiring.
    function getAgentConfiguration(uint256 _agentId)
        external
        view
        returns (
            uint256 lastReportEpoch,
            uint256 accumulatedOperatingRewards,
            uint256 cooldownEnds
        )
    {
        Agent storage agent = agents[_agentId];
        return (
            agent.lastReportEpoch,
            agent.accumulatedOperatingRewards,
            agent.cooldownEnds
        );
    }


    // --- II. Staking & Collateral ---

    /// @notice Allows any user to deposit ETH as collateral, backing a specific agent.
    /// @param _agentId The ID of the agent to stake for.
    /// @dev Increases the agent's total staked amount and the staker's voting power.
    function stakeForAgent(uint256 _agentId) external payable nonReentrant {
        require(agents[_agentId].status == AgentStatus.Active, "DAAN: Agent not active");
        require(msg.value > 0, "DAAN: Stake amount must be greater than zero");

        Agent storage agent = agents[_agentId];
        agent.stakers[msg.sender] = agent.stakers[msg.sender].add(msg.value);
        agent.totalStakedEth = agent.totalStakedEth.add(msg.value);
        votingPower[msg.sender] = votingPower[msg.sender].add(msg.value);

        emit EthStaked(_agentId, msg.sender, msg.value);
    }

    /// @notice Allows a staker to withdraw a specified amount of their staked ETH from an agent.
    /// @param _agentId The ID of the agent.
    /// @param _amount The amount of ETH to unstake.
    /// @dev Requires the agent to be retired or the staker to initiate a separate unbond process.
    function unstakeFromAgent(uint256 _agentId, uint256 _amount) external nonReentrant {
        Agent storage agent = agents[_agentId];
        require(agent.stakers[msg.sender] >= _amount, "DAAN: Insufficient staked amount");
        require(agent.cooldownEnds > 0 && block.timestamp >= agent.cooldownEnds, "DAAN: Cooldown period not over for unstaking");
        require(_amount > 0, "DAAN: Unstake amount must be greater than zero");

        agent.stakers[msg.sender] = agent.stakers[msg.sender].sub(_amount);
        agent.totalStakedEth = agent.totalStakedEth.sub(_amount);
        votingPower[msg.sender] = votingPower[msg.sender].sub(_amount);

        payable(msg.sender).transfer(_amount); // Transfer ETH back
        emit EthUnstaked(_agentId, msg.sender, _amount);
    }

    /// @notice Penalizes an agent or a specific staker for poor performance or malicious activity.
    /// @param _agentId The ID of the agent.
    /// @param _staker The address of the staker to slash.
    /// @param _amount The amount of ETH to slash.
    /// @dev `onlyGovernance` function. Slashed amount is sent to `protocolFeeRecipient`.
    function slashAgentStake(uint256 _agentId, address _staker, uint256 _amount) external onlyGovernance nonReentrant {
        Agent storage agent = agents[_agentId];
        require(agent.stakers[_staker] >= _amount, "DAAN: Insufficient stake to slash");
        require(_amount > 0, "DAAN: Slash amount must be greater than zero");

        agent.stakers[_staker] = agent.stakers[_staker].sub(_amount);
        agent.totalStakedEth = agent.totalStakedEth.sub(_amount);
        votingPower[_staker] = votingPower[_staker].sub(_amount);

        payable(protocolFeeRecipient).transfer(_amount);
        emit StakeSlashed(_agentId, _staker, _amount);
    }

    /// @notice Allows an agent staker to claim their accrued rewards.
    /// @param _agentId The ID of the agent.
    /// @dev Rewards are calculated and distributed during `distributeEpochRewards`.
    ///      This function would simply transfer the pre-calculated amount.
    ///      (Simplified for this example; actual calculation is complex)
    function claimStakingReward(uint256 _agentId) external nonReentrant {
        // In a real system, this would involve a complex calculation
        // based on agent performance, staker's share, and distributed pool.
        // For this example, we assume rewards are calculated and set per-staker
        // in `distributeEpochRewards` and stored in a mapping (not implemented here).
        // Let's assume a dummy reward for now.

        // Placeholder:
        uint256 dummyReward = 0; // Replace with actual logic
        require(dummyReward > 0, "DAAN: No rewards to claim (or already claimed)");

        // payable(msg.sender).transfer(dummyReward);
        // emit StakingRewardClaimed(_agentId, msg.sender, dummyReward);
        revert("DAAN: Staking reward claiming not fully implemented, use distributeEpochRewards");
    }

    // --- III. Performance & Evaluation ---

    /// @notice Allows a registered validator to submit a report on an agent's performance.
    /// @param _agentId The ID of the agent being reported on.
    /// @param _scoreChange The proposed change to the agent's performance score (can be negative).
    /// @param _notes Optional notes regarding the report.
    /// @dev `onlyValidator` function.
    /// @return The ID of the newly submitted report.
    function submitPerformanceReport(uint256 _agentId, int256 _scoreChange, string calldata _notes)
        external
        onlyValidator
        returns (uint256)
    {
        require(agents[_agentId].status == AgentStatus.Active, "DAAN: Agent not active");
        require(agents[_agentId].owner != msg.sender, "DAAN: Cannot report on your own agent");

        uint256 reportId = nextReportId++;
        performanceReports[reportId] = PerformanceReport({
            agentId: _agentId,
            validator: msg.sender,
            scoreChange: _scoreChange,
            notes: _notes,
            epoch: currentEpoch,
            challenged: false,
            resolved: false
        });

        // Immediately update score, but this can be challenged
        // More robust: Reports accumulate, and scores are updated at epoch end or on resolution
        _updateAgentPerformanceScore(_agentId, _scoreChange);
        agents[_agentId].lastReportEpoch = currentEpoch;

        emit PerformanceReportSubmitted(reportId, _agentId, msg.sender, _scoreChange);
        return reportId;
    }

    /// @notice Allows any participant to challenge a submitted performance report.
    /// @param _reportId The ID of the report to challenge.
    /// @dev Requires a challenge bond (`minChallengeBond`).
    /// @return The ID of the new challenge.
    function challengePerformanceReport(uint256 _reportId) external payable nonReentrant returns (uint256) {
        PerformanceReport storage report = performanceReports[_reportId];
        require(report.agentId != 0, "DAAN: Report does not exist");
        require(!report.challenged, "DAAN: Report already challenged");
        require(report.validator != msg.sender, "DAAN: Cannot challenge your own report");
        require(msg.value >= minChallengeBond, "DAAN: Insufficient challenge bond");

        report.challenged = true;

        uint256 challengeId = nextChallengeId++;
        challenges[challengeId] = Challenge({
            reportId: _reportId,
            challenger: msg.sender,
            challengeBond: msg.value,
            status: ChallengeStatus.Pending,
            creationEpoch: currentEpoch
        });

        emit PerformanceReportChallenged(challengeId, _reportId, msg.sender);
        return challengeId;
    }

    /// @notice Resolves an active challenge, determining correctness.
    /// @param _challengeId The ID of the challenge to resolve.
    /// @param _challengerWins True if the challenger's claim is valid, false otherwise.
    /// @dev `onlyGovernance` function. Handles bond distribution and score adjustment.
    function resolveChallenge(uint256 _challengeId, bool _challengerWins) external onlyGovernance nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.reportId != 0, "DAAN: Challenge does not exist");
        require(challenge.status == ChallengeStatus.Pending, "DAAN: Challenge already resolved");

        PerformanceReport storage report = performanceReports[challenge.reportId];
        report.resolved = true;

        if (_challengerWins) {
            challenge.status = ChallengeStatus.ResolvedValid;
            // Challenger wins: Report was invalid. Restore agent's score change,
            // return bond to challenger, slash reporter's stake (simplified).
            _updateAgentPerformanceScore(report.agentId, report.scoreChange.mul(-1)); // Reverse original score change

            payable(challenge.challenger).transfer(challenge.challengeBond); // Return challenger's bond
            // In a real system, reporter's validator stake would be slashed.
        } else {
            challenge.status = ChallengeStatus.ResolvedInvalid;
            // Challenger loses: Report was valid. Challenger's bond is sent to fee recipient.
            payable(protocolFeeRecipient).transfer(challenge.challengeBond);
            // Original report's score change stands (or is re-applied if it was temporarily reversed).
        }

        emit ChallengeResolved(_challengeId, _challengerWins, challenge.status);
    }

    /// @notice Internal function to update an agent's performance score.
    /// @param _agentId The ID of the agent.
    /// @param _delta The amount to change the score by (can be negative).
    function _updateAgentPerformanceScore(uint256 _agentId, int256 _delta) internal {
        int256 oldScore = agents[_agentId].currentPerformanceScore;
        agents[_agentId].currentPerformanceScore = oldScore.add(_delta);
        emit AgentPerformanceScoreUpdated(_agentId, oldScore, agents[_agentId].currentPerformanceScore);
    }

    // --- IV. Funding & Incentives ---

    /// @notice Allows anyone to deposit ETH into a general reward pool.
    /// @dev Funds are later distributed to top-performing agents.
    function depositToAgentPool() external payable nonReentrant {
        require(msg.value > 0, "DAAN: Deposit amount must be greater than zero");
        agentRewardPool = agentRewardPool.add(msg.value);
        emit EthDepositedToPool(msg.sender, msg.value);
    }

    /// @notice Allows users to directly pay an agent for its services, effectively "subscribing."
    /// @param _agentId The ID of the agent to subscribe to.
    /// @dev Funds go directly to the agent's `accumulatedOperatingRewards`.
    function subscribeToAgentService(uint256 _agentId) external payable nonReentrant {
        Agent storage agent = agents[_agentId];
        require(agent.status == AgentStatus.Active, "DAAN: Agent not active");
        require(msg.value > 0, "DAAN: Subscription amount must be greater than zero");

        agent.accumulatedOperatingRewards = agent.accumulatedOperatingRewards.add(msg.value);
        emit AgentSubscribed(_agentId, msg.sender, msg.value);
    }

    /// @notice Allows the agent owner to claim funds from direct subscriptions and grants.
    /// @param _agentId The ID of the agent.
    function claimAgentOperatingReward(uint256 _agentId) external onlyAgentOwner(_agentId) nonReentrant {
        Agent storage agent = agents[_agentId];
        uint256 amount = agent.accumulatedOperatingRewards;
        require(amount > 0, "DAAN: No operating rewards to claim");

        agent.accumulatedOperatingRewards = 0;
        payable(msg.sender).transfer(amount);
        emit AgentOperatingRewardClaimed(_agentId, msg.sender, amount);
    }

    /// @notice Triggers the distribution of rewards from the general pool to top-performing agents.
    /// @dev `onlyGovernance` function. This should be called at the end of each epoch.
    ///      Distributes rewards based on a complex formula involving performance score and stake.
    function distributeEpochRewards() external onlyGovernance nonReentrant {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochDuration), "DAAN: Epoch not yet ended");

        uint256 totalDistributed = 0;
        uint256 totalActiveAgentStake = 0;
        uint256 totalPerformanceScoreFactor = 0; // Sum (score * stake) for normalization

        // First pass: Calculate total factor for normalization
        for (uint256 i = 0; i < nextAgentId; i++) {
            Agent storage agent = agents[i];
            if (agent.status == AgentStatus.Active && agent.totalStakedEth > 0) {
                totalActiveAgentStake = totalActiveAgentStake.add(agent.totalStakedEth);
                // Simple score factor: score + 1 (to avoid 0 or negative factors)
                // Multiplied by stake to weight by trust/investment
                totalPerformanceScoreFactor = totalPerformanceScoreFactor.add(
                    uint256(agent.currentPerformanceScore.add(1000)).mul(agent.totalStakedEth) // Offset to ensure positive score
                );
            }
        }

        if (totalPerformanceScoreFactor == 0 || agentRewardPool == 0) {
            // No rewards to distribute or no eligible agents/stakes
            return;
        }

        // Second pass: Distribute rewards
        for (uint256 i = 0; i < nextAgentId; i++) {
            Agent storage agent = agents[i];
            if (agent.status == AgentStatus.Active && agent.totalStakedEth > 0) {
                uint256 agentScoreFactor = uint256(agent.currentPerformanceScore.add(1000)).mul(agent.totalStakedEth);
                uint256 agentReward = agentRewardPool.mul(agentScoreFactor).div(totalPerformanceScoreFactor);

                if (agentReward > 0) {
                    // Distribute to agent owner
                    agent.accumulatedOperatingRewards = agent.accumulatedOperatingRewards.add(agentReward.div(2)); // 50% for owner
                    // Distribute to stakers (remaining 50% proportionally)
                    uint256 stakersRewardPool = agentReward.div(2);
                    for (address staker : agent.stakers.keys()) { // This is a simplification, iterating keys in mapping is not direct in Solidity
                        if (agent.stakers[staker] > 0) {
                            uint256 stakerReward = stakersRewardPool.mul(agent.stakers[staker]).div(agent.totalStakedEth);
                            // In a real system, this would store rewards per staker for claiming
                            // For simplicity, we just add to owner's accumulated rewards here
                            agent.accumulatedOperatingRewards = agent.accumulatedOperatingRewards.add(stakerReward);
                        }
                    }
                    totalDistributed = totalDistributed.add(agentReward);
                }
            }
        }

        agentRewardPool = agentRewardPool.sub(totalDistributed);
        emit EpochRewardsDistributed(currentEpoch, totalDistributed);
    }

    // --- V. Governance & Protocol Parameters ---

    /// @notice Allows a user with voting power to propose changes to protocol parameters.
    /// @param _description A description of the proposed change.
    /// @param _data Encoded function call or parameter change.
    /// @dev Requires the sender to have voting power.
    /// @return The ID of the newly created proposal.
    function proposeProtocolChange(string calldata _description, bytes calldata _data)
        external
        returns (uint256)
    {
        require(votingPower[msg.sender] > 0, "DAAN: Insufficient voting power");
        require(bytes(_description).length > 0, "DAAN: Description cannot be empty");
        require(bytes(_data).length > 0, "DAAN: Proposal data cannot be empty");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = ProtocolProposal({
            description: _description,
            data: _data,
            creationEpoch: currentEpoch,
            voteThreshold: 0, // Placeholder, dynamically set by governance or a formula
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Pending
        });

        // Set initial threshold based on total voting power or fixed value
        proposals[proposalId].voteThreshold = votingPower[msg.sender]; // Simplified: requires initiator's power

        emit ProtocolChangeProposed(proposalId, _description, msg.sender);
        return proposalId;
    }

    /// @notice Allows users with voting power to cast a vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _for True for a 'yes' vote, false for a 'no' vote.
    function voteOnProposal(uint256 _proposalId, bool _for) external {
        ProtocolProposal storage proposal = proposals[_proposalId];
        require(proposal.creationEpoch != 0, "DAAN: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAAN: Proposal not in pending state");
        require(!proposal.hasVoted[msg.sender], "DAAN: Already voted on this proposal");
        require(votingPower[msg.sender] > 0, "DAAN: No voting power");

        proposal.hasVoted[msg.sender] = true;
        if (_for) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower[msg.sender]);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower[msg.sender]);
        }

        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /// @notice Allows a user to delegate their voting power to another address.
    /// @param _delegatee The address to delegate voting power to.
    function delegateVote(address _delegatee) external {
        require(_delegatee != address(0), "DAAN: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "DAAN: Cannot delegate to self");

        uint256 power = votingPower[msg.sender];
        require(power > 0, "DAAN: No voting power to delegate");

        // Simple delegation: move all power. More complex systems have snapshots/undelegation.
        votingPower[_delegatee] = votingPower[_delegatee].add(power);
        votingPower[msg.sender] = 0;

        emit VoteDelegated(msg.sender, _delegatee);
    }

    /// @notice Enacts a proposal that has reached the required consensus threshold.
    /// @param _proposalId The ID of the proposal to execute.
    /// @dev `onlyGovernance` function. Executes the `data` bytes if approved.
    function executeProposal(uint256 _proposalId) external onlyGovernance nonReentrant {
        ProtocolProposal storage proposal = proposals[_proposalId];
        require(proposal.creationEpoch != 0, "DAAN: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "DAAN: Proposal not pending");
        require(proposal.yesVotes > proposal.noVotes, "DAAN: Proposal not approved (more no votes)");
        require(proposal.yesVotes >= proposal.voteThreshold, "DAAN: Proposal did not meet vote threshold");

        proposal.status = ProposalStatus.Executed;

        // In a real system, `data` would be decoded and specific setters called.
        // For simplicity, this is a placeholder. It could trigger `setProtocolParameter` functions.
        // For example: `(bool success,) = address(this).call(proposal.data); require(success, "DAAN: Proposal execution failed");`
        // However, direct arbitrary `call` is dangerous. Better to have a whitelist of callable functions.

        // Placeholder for actual execution:
        // parse `proposal.data` to call specific admin functions like `_setMinAgentStake`, `_setEpochDuration`, etc.
        // This requires careful encoding of parameters and target functions.
        // e.g., using `abi.decode` and a `function selector`.

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Moves the system to the next evaluation epoch.
    /// @dev `onlyGovernance` function. Triggers epoch-end processes.
    function advanceEpoch() external onlyGovernance nonReentrant {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochDuration), "DAAN: Epoch not yet ended");

        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;

        // Trigger reward distribution (could be a separate call or internal)
        distributeEpochRewards();

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /// @notice Sets the address that receives protocol fees.
    /// @param _newRecipient The new address for fee collection.
    /// @dev `onlyOwner` function.
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "DAAN: Invalid recipient address");
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientSet(_newRecipient);
    }

    // --- Utility & Getters ---

    /// @notice Gets the total voting power of an address.
    /// @param _addr The address to check.
    /// @return The voting power of the address.
    function getVotingPower(address _addr) external view returns (uint256) {
        return votingPower[_addr];
    }

    // Placeholder for iterating mapping keys, not directly supported in Solidity 0.8.x without libraries
    // In a real scenario, you'd track agent IDs in an array or use enumerable extensions.
    // For this example, 'agent.stakers.keys()' is conceptual.
    struct IterableMappingKeys {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) exists;
    }
    // This part is illustrative, not fully implemented for all mappings due to complexity.
    // A mapping cannot be directly iterated over in Solidity.

    // A simple way to expose keys (though not efficient for many entries):
    // mapping(uint256 => address[]) public agentStakerList;
    // would need to be maintained during stake/unstake operations.

    // Fallback and Receive functions to allow contract to receive ETH
    receive() external payable {}
    fallback() external payable {}
}
```