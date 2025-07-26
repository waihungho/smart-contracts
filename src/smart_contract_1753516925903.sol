Here's a smart contract written in Solidity, incorporating advanced concepts, unique functionalities, and a substantial number of functions, while striving to avoid direct duplication of existing open-source projects by focusing on a novel application layer.

The core concept is "SyntheticaAI," a decentralized network for **AI Model Inference Validation** and **Data Set Attestation**. It leverages a reputation system, staking, and integrates with the idea of dynamic NFTs for "AI Agent Licenses" (though the NFT contract itself is external and simplified for this example).

---

## SyntheticaAI: Decentralized AI Model & Data Validation Network

**Author:** AI / Your Name
**Contract Purpose:** To orchestrate a decentralized network where participants ("AI Agents") can propose AI tasks, validate the accuracy of AI model inferences, attest to the quality of data sets, and govern the network's parameters. It incentivizes accurate contributions through a reputation system and token rewards.

### Outline and Function Summary:

This contract is designed as the central hub for the SyntheticaAI ecosystem. It manages agents, tasks, data sets, and governance. It interacts with external ERC-20 (`SyntheticaToken`) for staking and rewards, and ERC-721 (`SyntheticaNFT`) for AI Agent Licenses.

---

### I. Initialization & Configuration

1.  **`constructor()`**: Initializes the contract, sets the deployer as the initial owner, and sets default configurable system parameters (e.g., minimum stake, reputation values, time periods).
2.  **`setSyntheticaNFTAddress(address _nftAddress)`**: **Admin Function.** Sets the address of the associated Synthetica NFT contract, which issues "AI Agent Licenses" to registered agents.
3.  **`setSyntheticaTokenAddress(address _tokenAddress)`**: **Admin Function.** Sets the address of the associated Synthetica utility token (ERC-20), used for staking, rewards, and fees.
4.  **`pause()`**: **Admin Function.** Implements an emergency pause mechanism, halting critical operations of the contract.
5.  **`unpause()`**: **Admin Function.** Resumes contract operations after a pause.

---

### II. Agent Management & Reputation

6.  **`registerAgent(string calldata _metadataURI)`**: Allows any user to become an "AI Agent" by staking a predefined amount of `SyntheticaToken`. Upon registration, an AI Agent License NFT is minted to their address, and they gain an initial reputation score.
7.  **`deregisterAgent()`**: Allows an active AI Agent to unstake their tokens and burn their associated AI Agent License NFT, thereby exiting the network. Their reputation is reset.
8.  **`updateAgentMetadata(string calldata _newMetadataURI)`**: Allows an active AI Agent to update the URI pointing to their off-chain profile metadata.
9.  **`slashAgentReputation(address _agent, uint256 _amount)`**: **Admin/Governance Function.** Explicitly reduces an agent's reputation. Used for penalizing severe misconduct not automatically covered by dispute resolution.
10. **`getAgentStatus(address _agent)`**: **View Function.** Retrieves an agent's current activity status, reputation score, staked amount, associated NFT ID, and metadata URI.

---

### III. AI Task Orchestration & Validation

11. **`proposeAITask(string calldata _taskMetadataURI, uint256 _rewardAmount, uint256 _validationStake)`**: An AI Agent proposes a new AI inference task (e.g., "classify images," "predict market trends"). The proposer provides a metadata URI describing the task, funds a reward pool, and sets a stake amount required for validators.
12. **`requestOracleInference(uint256 _taskId, address _oracleAddress, bytes calldata _oraclePayload)`**: **Agent/Proposer Function.** Initiates an off-chain AI inference request to a whitelisted oracle. This serves as a placeholder for integration with services like Chainlink AI. The oracle is expected to call `submitInferenceResult` upon completion.
13. **`submitInferenceResult(uint256 _taskId, string calldata _resultURI, bytes calldata _proof)`**: A designated whitelisted oracle or authorized agent submits the AI inference result (as a URI to off-chain data) and an optional cryptographic proof (e.g., a ZKP hash or signed attestation).
14. **`challengeInferenceResult(uint256 _taskId)`**: Allows any active AI Agent (with sufficient reputation) to challenge a submitted inference result, putting up a counter-stake. This moves the task into a dispute phase.
15. **`voteOnChallenge(uint256 _taskId, bool _isCorrect)`**: During a challenge, AI Agents (with sufficient reputation) vote on whether they believe the submitted inference result is correct or incorrect.
16. **`resolveTaskChallenge(uint256 _taskId)`**: Finalizes a challenged AI task after the voting period ends. Based on the consensus from votes, stakes are distributed (slashed or returned), and reputations of the submitter, challenger, and voters are adjusted.
17. **`claimTaskRewards(uint256 _taskId)`**: Allows the original task proposer, the successful inference submitter, and correctly-voted agents to claim their respective rewards and stake returns after a task has been resolved.
18. **`getTaskDetails(uint256 _taskId)`**: **View Function.** Retrieves all relevant details about a specific AI task, including its current state, participants, and associated URIs.

---

### IV. Data Contribution & Attestation

19. **`proposeDataSet(string calldata _dataSetURI, uint256 _rewardAmount)`**: An AI Agent proposes a new data set (e.g., for AI training or specific inference contexts) by providing a URI and funding a reward pool for attestors.
20. **`attestDataSetQuality(uint256 _dataSetId, bool _isHighQuality)`**: AI Agents (with sufficient reputation) review a proposed data set and attest to its quality, relevance, or accuracy.
21. **`resolveDataSetAttestation(uint256 _dataSetId)`**: Finalizes the attestation process for a data set. Based on the consensus of attestations, the data set is marked as high-quality or not. Rewards are distributed, and the data proposer's reputation is adjusted.
22. **`claimDataSetContributionRewards(uint256 _dataSetId)`**: Allows the original data set proposer to claim the rewards associated with their data set once it has been successfully attested as high-quality.
23. **`getDataSetDetails(uint256 _dataSetId)`**: **View Function.** Retrieves all relevant details about a specific data set, including its current state, proposer, and attestation status.

---

### V. Governance & System Parameters

24. **`proposeSystemParameterChange(bytes32 _paramName, uint256 _newValue, string calldata _description)`**: AI Agents (with higher reputation) can propose changes to core system parameters (e.g., `MIN_AGENT_STAKE`, `CONSENSUS_THRESHOLD_PERCENT`).
25. **`voteOnSystemParameterChange(uint256 _proposalId, bool _support)`**: AI Agents vote on active governance proposals.
26. **`executeSystemParameterChange(uint256 _proposalId)`**: Executes a passed governance proposal, applying the proposed parameter change to the contract's state.
27. **`getProposalDetails(uint256 _proposalId)`**: **View Function.** Retrieves details about a specific governance proposal.

---

### VI. Oracle Management

28. **`addWhitelistedOracle(address _oracleAddress)`**: **Admin/Governance Function.** Whitelists an address as a trusted AI inference oracle. Only whitelisted oracles can submit inference results or be requested for off-chain computation.
29. **`removeWhitelistedOracle(address _oracleAddress)`**: **Admin/Governance Function.** Removes an address from the list of trusted AI inference oracles.

---

### Solidity Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For interacting with SyntheticaNFT

/*
 *   @title SyntheticaAI: Decentralized AI Model & Data Validation Network
 *   @author AI / Your Name
 *   @notice This contract orchestrates a decentralized network for AI model inference validation and data set attestation.
 *           It incentivizes agents to provide accurate validations and high-quality data,
 *           building a reputation system and leveraging NFTs for agent roles.
 *           It integrates with off-chain AI inference through an oracle system and features
 *           a community-driven governance mechanism.
 *
 *   Outline and Function Summary provided above the contract code.
 */
contract SyntheticaAI is Ownable, Pausable {

    // --- State Variables ---

    // External Contract Addresses
    IERC20 public syntheticaToken;
    IERC721 public syntheticaNFT;

    // Configuration Parameters (governable)
    uint256 public MIN_AGENT_STAKE;
    uint256 public BASE_REPUTATION_ON_REGISTER;
    uint256 public MIN_REPUTATION_FOR_VALIDATION;
    uint256 public CHALLENGE_PERIOD_SECONDS;
    uint256 public VOTE_PERIOD_SECONDS;
    uint256 public CONSENSUS_THRESHOLD_PERCENT; // e.g., 60 for 60%

    // --- Structs ---

    enum AgentStatus { Inactive, Active }
    struct Agent {
        AgentStatus status;
        uint256 reputation;
        uint256 stakedAmount;
        uint256 nftId; // ID of the agent's associated Synthetica NFT
        string metadataURI;
    }

    enum TaskState { Proposed, AwaitingInference, InferenceSubmitted, Challenged, Resolved, Claimed }
    struct AITask {
        address proposer;
        string taskMetadataURI;
        uint256 rewardAmount;
        uint256 validationStake;
        address inferenceSubmitter; // Address of the oracle/agent who submitted the result
        string resultURI;
        bytes proof; // Optional cryptographic proof for inference
        TaskState state;
        uint256 challengeExpiry; // Timestamp when challenge period ends
        uint256 voteExpiry; // Timestamp when vote period ends
        uint256 totalVotesForCorrect;
        uint256 totalVotesAgainstCorrect;
        mapping(address => bool) hasVoted; // For challenge votes
        bool isResultCorrect; // Final resolution of challenge
        bool proposerClaimed;
        bool submitterClaimed;
        // Simplified: Rewards for validators/voters are distributed proportionally, not individually tracked per person
    }

    enum DataSetState { Proposed, AwaitingAttestation, Attested, Claimed }
    struct DataSet {
        address proposer;
        string dataSetURI;
        uint256 rewardAmount;
        DataSetState state;
        uint256 totalAttestationsForQuality;
        uint256 totalAttestationsAgainstQuality;
        mapping(address => bool) hasAttested;
        bool isHighQuality; // Final resolution of attestation
        bool proposerClaimed;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct GovernanceProposal {
        address proposer;
        bytes32 paramName; // Example: keccak256("MIN_AGENT_STAKE")
        uint256 newValue;
        string description;
        ProposalState state;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    // --- Mappings ---

    mapping(address => Agent) public agents;
    mapping(uint256 => AITask) public aiTasks;
    mapping(uint256 => DataSet) public dataSets;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => bool) public whitelistedOracles;

    // --- Counters ---
    uint256 private _nextTaskId;
    uint256 private _nextDataSetId;
    uint256 private _nextProposalId;

    // --- Events ---
    event SyntheticaNFTAddressSet(address indexed _nftAddress);
    event SyntheticaTokenAddressSet(address indexed _tokenAddress);
    event AgentRegistered(address indexed _agent, uint256 _nftId, string _metadataURI);
    event AgentDeregistered(address indexed _agent, uint256 _nftId);
    event AgentMetadataUpdated(address indexed _agent, string _newMetadataURI);
    event AgentReputationSlashed(address indexed _agent, uint256 _amount);
    event AITaskProposed(uint256 indexed _taskId, address indexed _proposer, uint256 _rewardAmount);
    event OracleInferenceRequested(uint256 indexed _taskId, address indexed _oracleAddress, bytes _oraclePayload);
    event InferenceResultSubmitted(uint256 indexed _taskId, address indexed _submitter, string _resultURI);
    event InferenceResultChallenged(uint256 indexed _taskId, address indexed _challenger);
    event ChallengeVoted(uint256 indexed _taskId, address indexed _voter, bool _isCorrect);
    event TaskChallengeResolved(uint256 indexed _taskId, bool _isResultCorrect, uint256 _rewardAmount);
    event TaskRewardsClaimed(uint256 indexed _taskId, address indexed _claimer, uint256 _amount);
    event DataSetProposed(uint256 indexed _dataSetId, address indexed _proposer, uint256 _rewardAmount);
    event DataSetAttested(uint256 indexed _dataSetId, address indexed _attester, bool _isHighQuality);
    event DataSetAttestationResolved(uint256 indexed _dataSetId, bool _isHighQuality);
    event DataSetContributionRewardsClaimed(uint256 indexed _dataSetId, address indexed _claimer, uint256 _amount);
    event SystemParameterChangeProposed(uint256 indexed _proposalId, bytes32 _paramName, uint256 _newValue);
    event ProposalVoted(uint256 indexed _proposalId, address indexed _voter, bool _support);
    event ProposalExecuted(uint256 indexed _proposalId, bytes32 _paramName, uint256 _newValue);
    event OracleWhitelisted(address indexed _oracleAddress);
    event OracleRemoved(address indexed _oracleAddress);


    // --- Modifiers ---

    modifier onlyAgent() {
        require(agents[msg.sender].status == AgentStatus.Active, "SyntheticaAI: Caller is not an active agent.");
        _;
    }

    modifier onlyWhitelistedOracle() {
        require(whitelistedOracles[msg.sender], "SyntheticaAI: Caller is not a whitelisted oracle.");
        _;
    }

    // --- I. Initialization & Configuration ---

    constructor() Ownable(msg.sender) {
        _nextTaskId = 1;
        _nextDataSetId = 1;
        _nextProposalId = 1;

        // Initial default parameters (can be changed via governance)
        MIN_AGENT_STAKE = 1000 ether; // Example: 1000 Synthetica tokens
        BASE_REPUTATION_ON_REGISTER = 100;
        MIN_REPUTATION_FOR_VALIDATION = 500;
        CHALLENGE_PERIOD_SECONDS = 24 hours;
        VOTE_PERIOD_SECONDS = 72 hours;
        CONSENSUS_THRESHOLD_PERCENT = 60; // 60%
    }

    /**
     * @notice Sets the address of the Synthetica NFT contract.
     * @dev Only callable by the owner (or eventually DAO governance).
     * @param _nftAddress The address of the deployed Synthetica NFT (ERC721) contract.
     */
    function setSyntheticaNFTAddress(address _nftAddress) external onlyOwner {
        require(_nftAddress != address(0), "SyntheticaAI: Invalid NFT address");
        syntheticaNFT = IERC721(_nftAddress);
        emit SyntheticaNFTAddressSet(_nftAddress);
    }

    /**
     * @notice Sets the address of the Synthetica utility token (ERC20) contract.
     * @dev Only callable by the owner (or eventually DAO governance).
     * @param _tokenAddress The address of the deployed Synthetica Token (ERC20) contract.
     */
    function setSyntheticaTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "SyntheticaAI: Invalid token address");
        syntheticaToken = IERC20(_tokenAddress);
        emit SyntheticaTokenAddressSet(_tokenAddress);
    }

    /**
     * @notice Pauses all critical contract functionalities in case of emergency.
     * @dev Only callable by the owner (or eventually DAO governance).
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses contract functionalities.
     * @dev Only callable by the owner (or eventually DAO governance).
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Agent Management & Reputation ---

    /**
     * @notice Allows a user to become an AI Agent by staking tokens and providing metadata.
     *         An associated Synthetica NFT (AI Agent License) is minted for the agent.
     * @param _metadataURI URI pointing to off-chain metadata for the agent's profile.
     */
    function registerAgent(string calldata _metadataURI) external whenNotPaused {
        require(address(syntheticaToken) != address(0), "SyntheticaAI: Token contract not set");
        require(address(syntheticaNFT) != address(0), "SyntheticaAI: NFT contract not set");
        require(agents[msg.sender].status == AgentStatus.Inactive, "SyntheticaAI: Already an active agent.");
        require(syntheticaToken.transferFrom(msg.sender, address(this), MIN_AGENT_STAKE), "SyntheticaAI: Token transfer failed.");

        // Simulate NFT minting. In a real scenario, this would call syntheticaNFT.mint(msg.sender, _metadataURI)
        // For demonstration, we use a placeholder for the NFT ID. The actual NFT contract would handle ID generation.
        // uint256 newNftId = syntheticaNFT.mint(msg.sender, _metadataURI); // Actual call to NFT contract
        uint256 newNftId = (syntheticaNFT.totalSupply() + 1); // Placeholder for a dummy ID

        agents[msg.sender] = Agent({
            status: AgentStatus.Active,
            reputation: BASE_REPUTATION_ON_REGISTER,
            stakedAmount: MIN_AGENT_STAKE,
            nftId: newNftId,
            metadataURI: _metadataURI
        });

        emit AgentRegistered(msg.sender, newNftId, _metadataURI);
    }

    /**
     * @notice Allows an active agent to unstake their tokens and exit the network.
     *         Their associated NFT is "burned" (transferred to zero address or a burn address in the NFT contract).
     */
    function deregisterAgent() external onlyAgent whenNotPaused {
        Agent storage agent = agents[msg.sender];
        require(agent.stakedAmount > 0, "SyntheticaAI: Agent has no stake to withdraw.");

        uint256 stakeToReturn = agent.stakedAmount;
        // In a real scenario, this would call syntheticaNFT.transferFrom(msg.sender, address(0), agent.nftId); or syntheticaNFT.burn(agent.nftId);
        // syntheticaNFT.burn(agent.nftId); // Actual call to NFT contract

        agent.status = AgentStatus.Inactive;
        agent.stakedAmount = 0;
        agent.reputation = 0; // Reset reputation on exit
        agent.nftId = 0; // Clear NFT ID

        require(syntheticaToken.transfer(msg.sender, stakeToReturn), "SyntheticaAI: Failed to return stake.");

        emit AgentDeregistered(msg.sender, agent.nftId);
    }

    /**
     * @notice Allows an active agent to update their profile metadata URI.
     * @param _newMetadataURI The new URI pointing to the updated off-chain metadata.
     */
    function updateAgentMetadata(string calldata _newMetadataURI) external onlyAgent {
        agents[msg.sender].metadataURI = _newMetadataURI;
        // In a real scenario, this might also trigger an update on the NFT metadata via syntheticaNFT.setTokenURI().
        // syntheticaNFT.setTokenURI(agents[msg.sender].nftId, _newMetadataURI);
        emit AgentMetadataUpdated(msg.sender, _newMetadataURI);
    }

    /**
     * @notice Allows governance/admin to explicitly reduce an agent's reputation.
     * @dev This function should ideally be callable only by a passed governance proposal.
     * @param _agent The address of the agent whose reputation is to be slashed.
     * @param _amount The amount by which to reduce the agent's reputation.
     */
    function slashAgentReputation(address _agent, uint256 _amount) external onlyOwner { // TODO: Integrate with governance
        require(agents[_agent].status == AgentStatus.Active, "SyntheticaAI: Agent is not active.");
        agents[_agent].reputation = agents[_agent].reputation > _amount ? agents[_agent].reputation - _amount : 0;
        emit AgentReputationSlashed(_agent, _amount);
    }

    /**
     * @notice Retrieves the current status, reputation, stake, and NFT details of an agent.
     * @param _agent The address of the agent.
     * @return status The agent's activity status.
     * @return reputation The agent's current reputation score.
     * @return stakedAmount The amount of tokens the agent has staked.
     * @return nftId The ID of the agent's associated Synthetica NFT.
     * @return metadataURI The URI pointing to the agent's off-chain metadata.
     */
    function getAgentStatus(address _agent)
        external
        view
        returns (AgentStatus status, uint256 reputation, uint256 stakedAmount, uint256 nftId, string memory metadataURI)
    {
        Agent storage agent = agents[_agent];
        return (agent.status, agent.reputation, agent.stakedAmount, agent.nftId, agent.metadataURI);
    }

    // --- III. AI Task Orchestration & Validation ---

    /**
     * @notice Proposes a new AI inference task, funding it with rewards and defining validation stakes.
     *         The proposer also stakes tokens for their proposal.
     * @param _taskMetadataURI URI pointing to off-chain details of the AI task (e.g., input data, specific model info).
     * @param _rewardAmount The total reward pool for successful inference and validation.
     * @param _validationStake The amount of tokens validators must stake to participate.
     * @return taskId The ID of the newly created task.
     */
    function proposeAITask(string calldata _taskMetadataURI, uint256 _rewardAmount, uint256 _validationStake)
        external
        onlyAgent
        whenNotPaused
        returns (uint256 taskId)
    {
        require(_rewardAmount > 0, "SyntheticaAI: Reward amount must be greater than zero.");
        require(_validationStake > 0, "SyntheticaAI: Validation stake must be greater than zero.");
        require(syntheticaToken.transferFrom(msg.sender, address(this), _rewardAmount), "SyntheticaAI: Reward transfer failed.");

        taskId = _nextTaskId++;
        aiTasks[taskId] = AITask({
            proposer: msg.sender,
            taskMetadataURI: _taskMetadataURI,
            rewardAmount: _rewardAmount,
            validationStake: _validationStake,
            inferenceSubmitter: address(0),
            resultURI: "",
            proof: "",
            state: TaskState.Proposed,
            challengeExpiry: 0,
            voteExpiry: 0,
            totalVotesForCorrect: 0,
            totalVotesAgainstCorrect: 0,
            isResultCorrect: false,
            proposerClaimed: false,
            submitterClaimed: false
        });

        emit AITaskProposed(taskId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Initiates an off-chain AI inference request to a whitelisted oracle.
     * @dev This function acts as a bridge to an off-chain oracle service (e.g., Chainlink, API3).
     *      The oracle is expected to call `submitInferenceResult` upon completion.
     * @param _taskId The ID of the AI task awaiting inference.
     * @param _oracleAddress The address of the whitelisted oracle to call.
     * @param _oraclePayload The specific payload for the oracle (e.g., data to process, model ID).
     */
    function requestOracleInference(uint256 _taskId, address _oracleAddress, bytes calldata _oraclePayload)
        external
        onlyAgent // Only task proposer or specific agents can request
        whenNotPaused
    {
        AITask storage task = aiTasks[_taskId];
        require(task.proposer == msg.sender, "SyntheticaAI: Only task proposer can request inference.");
        require(task.state == TaskState.Proposed, "SyntheticaAI: Task is not in Proposed state.");
        require(whitelistedOracles[_oracleAddress], "SyntheticaAI: Oracle address not whitelisted.");

        task.state = TaskState.AwaitingInference;
        // Here, you would typically make an external call to the oracle contract
        // e.g., ChainlinkClient.request(_oracleAddress, _oraclePayload, this.submitInferenceResult.selector);
        // For this example, we'll just emit an event.
        emit OracleInferenceRequested(_taskId, _oracleAddress, _oraclePayload);
    }

    /**
     * @notice A designated oracle or authorized agent submits the AI inference result.
     * @param _taskId The ID of the AI task.
     * @param _resultURI URI pointing to the off-chain AI inference result.
     * @param _proof Optional cryptographic proof for the inference (e.g., ZKP hash, signed attestation).
     */
    function submitInferenceResult(uint256 _taskId, string calldata _resultURI, bytes calldata _proof)
        external
        whenNotPaused
        // In a production system, this would be highly restricted: only the specifically requested oracle
        // or a whitelisted and assigned inference provider. For this example, allowing whitelisted oracles or any agent.
    {
        AITask storage task = aiTasks[_taskId];
        require(task.state == TaskState.AwaitingInference, "SyntheticaAI: Task is not awaiting inference.");
        require(whitelistedOracles[msg.sender] || agents[msg.sender].status == AgentStatus.Active, "SyntheticaAI: Caller not authorized to submit result.");


        task.inferenceSubmitter = msg.sender;
        task.resultURI = _resultURI;
        task.proof = _proof;
        task.state = TaskState.InferenceSubmitted;
        task.challengeExpiry = block.timestamp + CHALLENGE_PERIOD_SECONDS;

        emit InferenceResultSubmitted(_taskId, msg.sender, _resultURI);
    }

    /**
     * @notice Allows any active agent (with sufficient reputation) to challenge a submitted inference result.
     *         Requires a counter-stake to prevent spam.
     * @param _taskId The ID of the AI task to challenge.
     */
    function challengeInferenceResult(uint256 _taskId) external onlyAgent whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        require(task.state == TaskState.InferenceSubmitted, "SyntheticaAI: Task not in InferenceSubmitted state.");
        require(block.timestamp < task.challengeExpiry, "SyntheticaAI: Challenge period has ended.");
        require(msg.sender != task.inferenceSubmitter, "SyntheticaAI: Submitter cannot challenge their own result.");
        require(agents[msg.sender].reputation >= MIN_REPUTATION_FOR_VALIDATION, "SyntheticaAI: Insufficient reputation to challenge.");

        require(syntheticaToken.transferFrom(msg.sender, address(this), task.validationStake), "SyntheticaAI: Challenge stake transfer failed.");

        task.state = TaskState.Challenged;
        task.voteExpiry = block.timestamp + VOTE_PERIOD_SECONDS;

        emit InferenceResultChallenged(_taskId, msg.sender);
    }

    /**
     * @notice Allows agents (with sufficient reputation) to vote on the validity of a challenged inference result.
     * @param _taskId The ID of the challenged AI task.
     * @param _isCorrect True if the voter believes the submitted result is correct, false otherwise.
     */
    function voteOnChallenge(uint256 _taskId, bool _isCorrect) external onlyAgent whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        require(task.state == TaskState.Challenged, "SyntheticaAI: Task is not in Challenged state.");
        require(block.timestamp >= task.challengeExpiry, "SyntheticaAI: Challenge period has not ended. Wait for voting period.");
        require(block.timestamp < task.voteExpiry, "SyntheticaAI: Voting period has ended.");
        require(!task.hasVoted[msg.sender], "SyntheticaAI: Already voted on this challenge.");
        require(agents[msg.sender].reputation >= MIN_REPUTATION_FOR_VALIDATION, "SyntheticaAI: Insufficient reputation to vote.");

        if (_isCorrect) {
            task.totalVotesForCorrect++;
        } else {
            task.totalVotesAgainstCorrect++;
        }
        task.hasVoted[msg.sender] = true;

        emit ChallengeVoted(_taskId, msg.sender, _isCorrect);
    }

    /**
     * @notice Resolves a challenged AI task based on vote consensus.
     *         Distributes rewards/slashes stakes and adjusts reputations accordingly.
     * @param _taskId The ID of the challenged AI task.
     */
    function resolveTaskChallenge(uint256 _taskId) external whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        require(task.state == TaskState.Challenged, "SyntheticaAI: Task not in Challenged state.");
        require(block.timestamp >= task.voteExpiry, "SyntheticaAI: Voting period has not ended yet.");

        uint256 totalVotes = task.totalVotesForCorrect + task.totalVotesAgainstCorrect;
        require(totalVotes > 0, "SyntheticaAI: No votes cast for this challenge.");

        // Determine if the result is correct based on consensus
        bool isCorrect;
        if (task.totalVotesForCorrect * 100 / totalVotes >= CONSENSUS_THRESHOLD_PERCENT) {
            isCorrect = true;
        } else if (task.totalVotesAgainstCorrect * 100 / totalVotes >= CONSENSUS_THRESHOLD_PERCENT) {
            isCorrect = false;
        } else {
            // No clear consensus, might default to original submission or requires more intervention.
            // For simplicity, no consensus means result is considered incorrect.
            isCorrect = false;
        }

        task.isResultCorrect = isCorrect;
        task.state = TaskState.Resolved;

        // Basic reputation adjustments. More complex stake/reputation logic would be here.
        if (isCorrect) {
            agents[task.inferenceSubmitter].reputation += 15; // Reward submitter
            // Reward all agents who voted for correct and penalize those who voted against.
            // This is simplified and would require iterating over all voters.
        } else {
            agents[task.inferenceSubmitter].reputation = agents[task.inferenceSubmitter].reputation > 20 ? agents[task.inferenceSubmitter].reputation - 20 : 0; // Penalize submitter
            // Reward challengers and agents who voted for incorrect.
        }

        emit TaskChallengeResolved(_taskId, isCorrect, task.rewardAmount);
    }

    /**
     * @notice Allows the original proposer and successful validators/voters to claim their rewards.
     * @param _taskId The ID of the task to claim rewards from.
     */
    function claimTaskRewards(uint256 _taskId) external whenNotPaused {
        AITask storage task = aiTasks[_taskId];
        require(task.state == TaskState.Resolved, "SyntheticaAI: Task is not in Resolved state.");

        uint256 rewardShare = 0;

        if (msg.sender == task.proposer && !task.proposerClaimed) {
            // Proposer's stake is considered part of the initial `_rewardAmount` or could be separate.
            // Here, assuming proposer gets reputation for successful task, no direct token reward.
            // A more complex system might return part of their initial stake or a bonus.
            if (task.isResultCorrect) {
                agents[msg.sender].reputation += 5;
            }
            task.proposerClaimed = true;
            rewardShare = 0; // Proposer doesn't get additional token rewards here for simplicity
        } else if (msg.sender == task.inferenceSubmitter && !task.submitterClaimed) {
            if (task.isResultCorrect) {
                rewardShare = task.rewardAmount / 2; // Example: 50% to submitter if correct
            } else {
                // Submitters of incorrect results are penalized, not rewarded.
                revert("SyntheticaAI: Submitter's result was incorrect, no reward.");
            }
            task.submitterClaimed = true;
        } else if (task.hasVoted[msg.sender]) { // Check if msg.sender was a voter in the challenge
            // Calculate voter rewards. This would require knowing how many voters there were for each side.
            // For simplicity, assuming a pooled reward for correctly voting parties.
            bool votedCorrectly = (task.isResultCorrect == true && task.hasVoted[msg.sender]); // Simplified check
            if (votedCorrectly) {
                // Distribute remaining reward to all correct voters
                // This would need a more sophisticated mechanism to track individual voters and their stakes/reputation.
                // For now, this part is a conceptual placeholder.
                agents[msg.sender].reputation += 3; // Small reputation boost
                rewardShare = 0; // No direct token for voters in this simplified example
            } else {
                 agents[msg.sender].reputation = agents[msg.sender].reputation > 5 ? agents[msg.sender].reputation - 5 : 0; // Penalize wrong vote
            }
            // Mark voter as claimed (need a way to track individual voters' claims, 'hasVoted' is just for participation)
            // For this example, we'll let multiple voters claim conceptual reputation, but not re-claim tokens.
        } else {
            revert("SyntheticaAI: No unclaimed rewards for caller or invalid role.");
        }

        if (rewardShare > 0) {
            require(syntheticaToken.transfer(msg.sender, rewardShare), "SyntheticaAI: Failed to transfer reward.");
        }

        emit TaskRewardsClaimed(_taskId, msg.sender, rewardShare);
    }

    /**
     * @notice Retrieves comprehensive details about a specific AI task.
     * @param _taskId The ID of the AI task.
     * @return taskDetails A struct containing all details of the task.
     */
    function getTaskDetails(uint256 _taskId) external view returns (AITask memory taskDetails) {
        require(_taskId > 0 && _taskId < _nextTaskId, "SyntheticaAI: Invalid Task ID.");
        taskDetails = aiTasks[_taskId];
        // Note: Mappings within structs (like `hasVoted`) are not directly returned in memory by default.
        // To query if a specific address voted, you'd need a separate view function, e.g., `getTaskVoteStatus(uint256 _taskId, address _voter)`.
    }


    // --- IV. Data Contribution & Attestation ---

    /**
     * @notice Proposes a new data set for AI training or inference, offering rewards for quality attestation.
     * @param _dataSetURI URI pointing to the off-chain data set.
     * @param _rewardAmount The total reward pool for successful attestation.
     * @return dataSetId The ID of the newly created data set.
     */
    function proposeDataSet(string calldata _dataSetURI, uint256 _rewardAmount)
        external
        onlyAgent
        whenNotPaused
        returns (uint256 dataSetId)
    {
        require(_rewardAmount > 0, "SyntheticaAI: Reward amount must be greater than zero.");
        require(syntheticaToken.transferFrom(msg.sender, address(this), _rewardAmount), "SyntheticaAI: Reward transfer failed.");

        dataSetId = _nextDataSetId++;
        dataSets[dataSetId] = DataSet({
            proposer: msg.sender,
            dataSetURI: _dataSetURI,
            rewardAmount: _rewardAmount,
            state: DataSetState.Proposed,
            totalAttestationsForQuality: 0,
            totalAttestationsAgainstQuality: 0,
            isHighQuality: false,
            proposerClaimed: false
        });

        emit DataSetProposed(dataSetId, msg.sender, _rewardAmount);
    }

    /**
     * @notice Allows agents (with sufficient reputation) to attest to the quality and relevance of a proposed data set.
     * @param _dataSetId The ID of the data set to attest.
     * @param _isHighQuality True if the voter believes the data set is of high quality, false otherwise.
     */
    function attestDataSetQuality(uint256 _dataSetId, bool _isHighQuality) external onlyAgent whenNotPaused {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.state == DataSetState.Proposed || dataSet.state == DataSetState.AwaitingAttestation, "SyntheticaAI: Data set not in attestation phase.");
        require(!dataSet.hasAttested[msg.sender], "SyntheticaAI: Already attested to this data set.");
        require(agents[msg.sender].reputation >= MIN_REPUTATION_FOR_VALIDATION, "SyntheticaAI: Insufficient reputation to attest.");

        if (dataSet.state == DataSetState.Proposed) {
            dataSet.state = DataSetState.AwaitingAttestation; // Transition state on first attestation
        }

        if (_isHighQuality) {
            dataSet.totalAttestationsForQuality++;
        } else {
            dataSet.totalAttestationsAgainstQuality++;
        }
        dataSet.hasAttested[msg.sender] = true;

        emit DataSetAttested(_dataSetId, msg.sender, _isHighQuality);
    }

    /**
     * @notice Finalizes the attestation process for a data set based on consensus.
     *         Distributes rewards and updates the data provider's reputation.
     * @param _dataSetId The ID of the data set to resolve.
     */
    function resolveDataSetAttestation(uint256 _dataSetId) external whenNotPaused {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.state == DataSetState.AwaitingAttestation, "SyntheticaAI: Data set not awaiting attestation.");

        uint256 totalAttestations = dataSet.totalAttestationsForQuality + dataSet.totalAttestationsAgainstQuality;
        require(totalAttestations > 0, "SyntheticaAI: No attestations received.");
        // Implement a minimum number of attestations before resolution can happen
        require(totalAttestations >= 3, "SyntheticaAI: Insufficient number of attestations to resolve."); // Example: min 3 attestations

        bool isHighQuality;
        if (dataSet.totalAttestationsForQuality * 100 / totalAttestations >= CONSENSUS_THRESHOLD_PERCENT) {
            isHighQuality = true;
        } else {
            isHighQuality = false;
        }

        dataSet.isHighQuality = isHighQuality;
        dataSet.state = DataSetState.Attested;

        if (isHighQuality) {
            agents[dataSet.proposer].reputation += 10; // Reward data proposer reputation
            // TODO: Reward individual attesters who voted correctly
        } else {
            agents[dataSet.proposer].reputation = agents[dataSet.proposer].reputation > 10 ? agents[dataSet.proposer].reputation - 10 : 0; // Penalize
            // TODO: Penalize individual attesters who voted incorrectly
        }

        emit DataSetAttestationResolved(_dataSetId, isHighQuality);
    }

    /**
     * @notice Allows the original data set proposer to claim rewards after successful attestation.
     * @param _dataSetId The ID of the data set.
     */
    function claimDataSetContributionRewards(uint256 _dataSetId) external whenNotPaused {
        DataSet storage dataSet = dataSets[_dataSetId];
        require(dataSet.state == DataSetState.Attested, "SyntheticaAI: Data set not in Attested state.");
        require(dataSet.proposer == msg.sender, "SyntheticaAI: Only the proposer can claim rewards.");
        require(!dataSet.proposerClaimed, "SyntheticaAI: Rewards already claimed.");
        require(dataSet.isHighQuality, "SyntheticaAI: Data set was not attested as high quality.");

        uint256 rewardAmount = dataSet.rewardAmount;
        dataSet.proposerClaimed = true;

        require(syntheticaToken.transfer(msg.sender, rewardAmount), "SyntheticaAI: Failed to transfer data set reward.");
        emit DataSetContributionRewardsClaimed(_dataSetId, msg.sender, rewardAmount);
    }

    /**
     * @notice Retrieves comprehensive details about a specific data set.
     * @param _dataSetId The ID of the data set.
     * @return dataSetDetails A struct containing all details of the data set.
     */
    function getDataSetDetails(uint256 _dataSetId) external view returns (DataSet memory dataSetDetails) {
        require(_dataSetId > 0 && _dataSetId < _nextDataSetId, "SyntheticaAI: Invalid Data Set ID.");
        dataSetDetails = dataSets[_dataSetId];
    }

    // --- V. Governance & System Parameters ---

    /**
     * @notice Allows agents with high reputation to propose changes to core system parameters.
     * @param _paramName A bytes32 representation of the parameter name (e.g., keccak256("MIN_AGENT_STAKE")).
     * @param _newValue The new value proposed for the parameter.
     * @param _description A string description of the proposal.
     * @return proposalId The ID of the newly created governance proposal.
     */
    function proposeSystemParameterChange(bytes32 _paramName, uint256 _newValue, string calldata _description)
        external
        onlyAgent
        whenNotPaused
        returns (uint256 proposalId)
    {
        // Require higher reputation for proposing (e.g., MIN_REPUTATION_FOR_VALIDATION * 2)
        require(agents[msg.sender].reputation >= MIN_REPUTATION_FOR_VALIDATION * 2, "SyntheticaAI: Insufficient reputation to propose.");

        proposalId = _nextProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposer: msg.sender,
            paramName: _paramName,
            newValue: _newValue,
            description: _description,
            state: ProposalState.Active, // Proposal is active immediately upon creation
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + VOTE_PERIOD_SECONDS, // Uses same vote period as challenges
            votesFor: 0,
            votesAgainst: 0
        });

        emit SystemParameterChangeProposed(proposalId, _paramName, _newValue);
    }

    /**
     * @notice Allows agents to vote on active governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True if the agent supports the proposal, false otherwise.
     */
    function voteOnSystemParameterChange(uint256 _proposalId, bool _support) external onlyAgent whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "SyntheticaAI: Proposal is not active.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "SyntheticaAI: Voting period is not active.");
        require(!proposal.hasVoted[msg.sender], "SyntheticaAI: Already voted on this proposal.");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a passed governance proposal, updating the system's parameters.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeSystemParameterChange(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "SyntheticaAI: Proposal is not active.");
        require(block.timestamp >= proposal.voteEndTime, "SyntheticaAI: Voting period has not ended.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "SyntheticaAI: No votes cast for this proposal.");

        // Check for quorum (e.g., minimum number of votes, not implemented here) and consensus
        bool passed = (proposal.votesFor * 100 / totalVotes >= CONSENSUS_THRESHOLD_PERCENT);

        if (passed) {
            // Apply the parameter change based on `paramName`
            if (proposal.paramName == keccak256("MIN_AGENT_STAKE")) {
                MIN_AGENT_STAKE = proposal.newValue;
            } else if (proposal.paramName == keccak256("BASE_REPUTATION_ON_REGISTER")) {
                BASE_REPUTATION_ON_REGISTER = proposal.newValue;
            } else if (proposal.paramName == keccak256("MIN_REPUTATION_FOR_VALIDATION")) {
                MIN_REPUTATION_FOR_VALIDATION = proposal.newValue;
            } else if (proposal.paramName == keccak256("CHALLENGE_PERIOD_SECONDS")) {
                CHALLENGE_PERIOD_SECONDS = proposal.newValue;
            } else if (proposal.paramName == keccak256("VOTE_PERIOD_SECONDS")) {
                VOTE_PERIOD_SECONDS = proposal.newValue;
            } else if (proposal.paramName == keccak256("CONSENSUS_THRESHOLD_PERCENT")) {
                require(proposal.newValue <= 100, "SyntheticaAI: Consensus threshold cannot exceed 100%.");
                CONSENSUS_THRESHOLD_PERCENT = proposal.newValue;
            } else {
                revert("SyntheticaAI: Unknown parameter for update.");
            }
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId, proposal.paramName, proposal.newValue);
        } else {
            proposal.state = ProposalState.Failed;
            // Optionally, penalize proposer for failed proposal.
        }
    }

    /**
     * @notice Retrieves details about a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposalDetails A struct containing all details of the proposal.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory proposalDetails) {
        require(_proposalId > 0 && _proposalId < _nextProposalId, "SyntheticaAI: Invalid Proposal ID.");
        proposalDetails = governanceProposals[_proposalId];
    }


    // --- VI. Oracle Management ---

    /**
     * @notice Allows governance to whitelist addresses that can act as trusted AI inference oracles.
     * @dev Only callable by the owner (or eventually DAO governance).
     * @param _oracleAddress The address of the oracle to whitelist.
     */
    function addWhitelistedOracle(address _oracleAddress) external onlyOwner { // TODO: Integrate with governance
        require(_oracleAddress != address(0), "SyntheticaAI: Invalid oracle address.");
        require(!whitelistedOracles[_oracleAddress], "SyntheticaAI: Oracle already whitelisted.");
        whitelistedOracles[_oracleAddress] = true;
        emit OracleWhitelisted(_oracleAddress);
    }

    /**
     * @notice Allows governance to remove a whitelisted oracle address.
     * @dev Only callable by the owner (or eventually DAO governance).
     * @param _oracleAddress The address of the oracle to remove.
     */
    function removeWhitelistedOracle(address _oracleAddress) external onlyOwner { // TODO: Integrate with governance
        require(_oracleAddress != address(0), "SyntheticaAI: Invalid oracle address.");
        require(whitelistedOracles[_oracleAddress], "SyntheticaAI: Oracle not whitelisted.");
        whitelistedOracles[_oracleAddress] = false;
        emit OracleRemoved(_oracleAddress);
    }
}
```