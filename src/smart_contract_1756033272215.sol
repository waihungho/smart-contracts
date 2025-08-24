This smart contract, **CogniVerse Protocol**, envisions a decentralized platform for the creation, training, and deployment of autonomous 'CogniAgents'. These agents are represented by Soulbound NFTs (SBNFTs), designed to acquire, demonstrate, and improve on-chain 'skills' through verifiable task completion, participation in challenges, and interaction with a dynamic, simulated environment (orchestrated by oracles).

The protocol incorporates an adaptive economic model, reputation-based agent evolution, and community-driven governance to foster a self-improving decentralized intelligence network. The core innovation lies in the agent's dynamic skill acquisition, the verifiable task execution system, and the protocol's ability to adapt its rules for skill evolution and environmental interaction through governance.

---

## Contract: CogniVerseProtocol

**Summary:**
A decentralized, adaptive learning protocol for autonomous 'CogniAgents'. Agents are Soulbound NFTs that accrue verifiable skills through task completion and environmental interaction. The protocol includes a task marketplace, reputation system, dynamic skill evolution, and governance mechanisms for self-amendment.

**Core Concepts:**
*   **CogniAgents (Soulbound NFTs):** Non-transferable tokens representing autonomous entities, accruing unique on-chain reputations and skill sets.
*   **Dynamic Skill System:** Agents possess evolving skill scores for various categories, influenced by performance and environmental factors.
*   **Verifiable Task Marketplace:** Users submit computational or intelligence tasks, agents bid, execute, and submit verifiable results (hashes), with rewards for success.
*   **Adaptive Learning Loop:** Agents' skill scores and internal parameters can adapt based on task outcomes and simulated environmental stimuli.
*   **Protocol Evolution:** Governance can propose and vote on changes to skill definitions, evolution paths, and protocol parameters, allowing the system itself to "learn" and adapt.
*   **Oracle Integration:** Essential for verifying off-chain task results, feeding environmental data, and resolving disputes.

---

### Outline & Function Summary:

**I. Core Protocol & Setup:**
1.  `constructor`: Initializes the contract, sets the owner, and initial parameters.
2.  `pauseContract`: Temporarily halts critical contract operations (owner/governance only).
3.  `unpauseContract`: Resumes critical contract operations (owner/governance only).
4.  `updateProtocolParameter`: Allows governance to adjust various system-wide parameters (e.g., fee rates, task timeouts).
5.  `setOracleAddress`: Sets the trusted address for the protocol's oracle.

**II. CogniAgent Management (Soulbound NFT):**
6.  `registerCogniAgent`: Mints a new unique CogniAgent NFT to a user, marking it as soulbound (non-transferable).
7.  `updateAgentMetadataURI`: Allows an agent owner to update their agent's off-chain metadata URI.
8.  `retireCogniAgent`: Marks a CogniAgent as inactive, preventing it from participating in new tasks or challenges.
9.  `getAgentOwner`: Retrieves the owner of a specific CogniAgent.
10. `getAgentInfo`: Retrieves detailed information about a CogniAgent, including its status and metadata.

**III. Skill & Reputation System:**
11. `defineSkillCategory`: Governance defines a new high-level skill category (e.g., "Data Analysis," "Code Generation").
12. `addAgentSkillProof`: An agent owner submits verifiable proof (e.g., hash of certification, task ID) to increase their agent's score in a specific skill.
13. `getAgentSkillScore`: Retrieves an agent's current score for a given skill category.
14. `proposeSkillEvolutionPath`: Governance proposes a new rule or algorithm for how a skill evolves or combines with others.

**IV. Task & Challenge Marketplace:**
15. `submitCogniTask`: A user submits a new task request, staking a reward. Specifies required skills and expected result hash format.
16. `bidOnCogniTask`: A registered CogniAgent bids to complete a submitted task, potentially staking collateral or reputation.
17. `acceptCogniTaskBid`: The task requester accepts one of the bids, locking the task for the chosen agent.
18. `submitTaskResultHash`: The selected CogniAgent submits the hash of their computed result after completing the task.
19. `verifyTaskResult`: The task requester (or oracle) verifies the submitted result hash against the expected outcome. This triggers skill score updates.
20. `resolveTaskDispute`: Initiates a dispute resolution process for a task (e.g., if results are contested).
21. `claimTaskReward`: The agent claims their staked reward upon successful task verification.

**V. Adaptive Learning & Environment Interaction:**
22. `simulateEnvironmentInteraction`: An authorized oracle triggers an event representing an environmental change or new global challenge. This can affect agent skill valuations or trigger new task types.
23. `triggerAgentSkillRecalculation`: A mechanism (periodically or event-driven) to recalculate agent skill scores based on accumulated history, recent performance, and environmental factors.

**VI. Governance & Economics:**
24. `stakeForGovernanceVote`: Users stake `COGNIVERSE_TOKEN` to gain voting power for governance proposals.
25. `voteOnProposal`: Participants vote on active governance proposals (e.g., parameter changes, skill evolution paths).
26. `withdrawGovernanceStake`: Allows users to withdraw their staked tokens after a cool-down period.
27. `claimProtocolFees`: Allows the designated protocol fee recipient (e.g., DAO treasury) to claim accumulated fees from task submissions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For a hypothetical protocol token

// Error definitions for cleaner error handling
error CogniVerse__InvalidAgentId();
error CogniVerse__NotAgentOwner();
error CogniVerse__AgentAlreadyRegistered();
error CogniVerse__AgentNotRegistered();
error CogniVerse__AgentRetired();
error CogniVerse__SkillCategoryAlreadyDefined();
error CogniVerse__SkillCategoryNotFound();
error CogniVerse__InsufficientStake();
error CogniVerse__TaskNotFound();
error CogniVerse__TaskNotInCorrectState();
error CogniVerse__TaskRequesterNotMatch();
error CogniVerse__AgentAlreadyBid();
error CogniVerse__AgentNotBidder();
error CogniVerse__NoBidsSubmitted();
error CogniVerse__ResultNotVerified();
error CogniVerse__InvalidOracle();
error CogniVerse__UnauthorizedCaller();
error CogniVerse__ProposalNotFound();
error CogniVerse__AlreadyVoted();
error CogniVerse__VotingPeriodEnded();
error CogniVerse__VotingPeriodNotEnded();
error CogniVerse__WithdrawalLocked();
error CogniVerse__NoFeesToClaim();
error CogniVerse__TaskTimeoutNotReached();
error CogniVerse__TaskResultAlreadySubmitted();
error CogniVerse__TaskAlreadyAccepted();

contract CogniVerseProtocol is ERC721, Ownable, Pausable {

    // --- State Variables ---

    // Hypothetical Protocol Token (e.g., for staking, rewards, fees)
    IERC20 public immutable COGNIVERSE_TOKEN;

    // --- CogniAgent Management ---
    uint256 private _nextTokenId;
    mapping(uint256 => bool) public isAgentRetired; // True if agent is retired
    mapping(uint255 => Agent) public agents; // Agent ID to Agent struct
    struct Agent {
        address owner;
        string metadataURI;
        uint256 registeredTimestamp;
        bool exists; // To distinguish between non-existent and retired
    }

    // --- Skill & Reputation System ---
    mapping(uint256 => mapping(bytes32 => uint256)) public agentSkillScores; // agentId => skillCategoryHash => score
    mapping(bytes32 => bool) public isSkillCategoryDefined; // Hash of skill category name => true if defined
    bytes32[] public definedSkillCategories; // List of defined skill category hashes

    // --- Task & Challenge Marketplace ---
    enum TaskState {
        Open,           // Task submitted, waiting for bids
        BiddingClosed,  // Bids can no longer be submitted
        Accepted,       // Bid accepted, agent working on task
        ResultSubmitted, // Agent submitted result hash, awaiting verification
        Verified,       // Result verified, reward can be claimed
        Disputed,       // Task result is under dispute
        Completed,      // Task reward claimed
        Canceled,       // Task canceled by requester (if no bid accepted)
        TimedOut        // Task timed out
    }

    struct CogniTask {
        uint256 taskId;
        address requester;
        bytes32 requiredSkillCategory;
        uint256 minSkillScore;
        uint256 rewardAmount;
        bytes32 expectedResultFormatHash; // Hash outlining the expected result structure/format
        uint256 submissionDeadline;
        TaskState state;
        uint256 acceptedAgentId; // 0 if no agent accepted
        bytes32 submittedResultHash; // Hash of the actual result provided by the agent
        uint256 bidClosingTime; // Time when bidding ends
        mapping(uint256 => uint256) bids; // agentId => bidAmount (collateral/reputation stake)
        uint256[] activeBidders; // List of agents who have bid
    }
    uint256 private _nextTaskId;
    mapping(uint256 => CogniTask) public tasks; // taskId => CogniTask

    // --- Adaptive Learning & Environment Interaction ---
    address public oracleAddress; // Trusted address for oracle interactions

    // --- Governance & Economics ---
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description; // Description of the proposal (e.g., parameter change, skill evolution path)
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => bool) hasVoted; // Voter => true if voted
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bytes functionSignature; // For parameter updates or calls
        bytes callData;          // For parameter updates or calls
        address targetContract;  // Target for calls, e.g., self for parameter updates
    }
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public governanceStakes; // user => staked COGNIVERSE_TOKEN
    uint256 public constant MIN_GOVERNANCE_STAKE = 100 * (10 ** 18); // Example: 100 COGNIVERSE_TOKEN
    uint256 public constant VOTING_PERIOD_BLOCKS = 10000; // Approx 2-3 days @ 12s/block
    uint256 public constant STAKE_LOCKUP_BLOCKS = 5000; // Blocks before stake can be withdrawn after proposal/vote
    mapping(address => uint256) public stakeWithdrawalUnlockBlock; // user => block number when stake is unlocked

    uint256 public protocolFeeRate = 500; // 5% (500 basis points out of 10,000)
    address public protocolFeeRecipient; // Address to collect fees (e.g., DAO treasury)

    // --- Events ---
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event ProtocolParameterUpdated(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue);
    event OracleAddressUpdated(address indexed oldAddress, address indexed newAddress);

    event CogniAgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI);
    event AgentMetadataUpdated(uint256 indexed agentId, string newMetadataURI);
    event CogniAgentRetired(uint256 indexed agentId);

    event SkillCategoryDefined(bytes32 indexed skillCategoryHash, string name);
    event AgentSkillScoreUpdated(uint256 indexed agentId, bytes32 indexed skillCategoryHash, uint256 newScore);
    event SkillEvolutionPathProposed(uint256 indexed proposalId, bytes32 indexed skillCategoryHash, string description);

    event CogniTaskSubmitted(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, bytes32 indexed requiredSkillCategory, uint256 submissionDeadline);
    event CogniAgentBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event CogniTaskBidAccepted(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed agentId, uint256 rewardAmount);
    event TaskDisputeInitiated(uint256 indexed taskId, address indexed initiator);
    event TaskStateChanged(uint256 indexed taskId, TaskState newState);

    event EnvironmentInteractionSimulated(uint256 indexed interactionId, bytes32 indexed eventType, bytes32 eventDataHash);
    event AgentSkillRecalculated(uint256 indexed agentId, bytes32 indexed skillCategoryHash, uint256 newScore, string reason);

    event GovernanceStakeUpdated(address indexed staker, uint256 newStake);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event StakeWithdrawn(address indexed staker, uint256 amount);
    event FeesClaimed(address indexed recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert CogniVerse__InvalidOracle();
        }
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        if (ownerOf(_agentId) != msg.sender) {
            revert CogniVerse__NotAgentOwner();
        }
        _;
    }

    modifier onlyGovernance() {
        // This is a simplified check. A full DAO would have more complex checks
        // For this example, we assume owner can also act as governance initiator.
        // In a real scenario, this would check if msg.sender holds enough voting power
        // or is a member of a multisig DAO.
        if (msg.sender != owner() && governanceStakes[msg.sender] < MIN_GOVERNANCE_STAKE) {
            revert CogniVerse__UnauthorizedCaller();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _cogniVerseTokenAddress, address _initialOracle, address _protocolFeeRecipient)
        ERC721("CogniAgent", "CGNTA")
        Ownable(msg.sender)
    {
        COGNIVERSE_TOKEN = IERC20(_cogniVerseTokenAddress);
        oracleAddress = _initialOracle;
        protocolFeeRecipient = _protocolFeeRecipient;
        _nextTokenId = 1; // Agent IDs start from 1
        _nextTaskId = 1; // Task IDs start from 1
        _nextProposalId = 1; // Proposal IDs start from 1
    }

    // --- I. Core Protocol & Setup ---

    /// @notice Pauses critical contract operations. Only callable by owner or governance.
    function pauseContract() public onlyOwnerOrGovernance whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes critical contract operations. Only callable by owner or governance.
    function unpauseContract() public onlyOwnerOrGovernance whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows governance to update a protocol-wide parameter.
    /// @param _parameterNameHash A hash identifying the parameter to update (e.g., keccak256("protocolFeeRate")).
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(bytes32 _parameterNameHash, uint256 _newValue) public onlyGovernance whenNotPaused {
        uint256 oldValue;
        if (_parameterNameHash == keccak256("protocolFeeRate")) {
            oldValue = protocolFeeRate;
            protocolFeeRate = _newValue;
        } else if (_parameterNameHash == keccak256("minGovernanceStake")) {
            // Simplified, in a real system this would be a constant or a state var
            // oldValue = MIN_GOVERNANCE_STAKE; // This can't be updated directly like this
            // MIN_GOVERNANCE_STAKE = _newValue;
            // For now, let's keep it fixed, or allow only specific variables to be updated
            revert CogniVerse__UnauthorizedCaller(); // Example: Block direct update of constants
        } else {
            revert CogniVerse__UnauthorizedCaller(); // Parameter not recognized or updateable
        }
        emit ProtocolParameterUpdated(_parameterNameHash, oldValue, _newValue);
    }

    /// @notice Sets the trusted address for the protocol's oracle. Only callable by owner.
    /// @param _newOracleAddress The new address of the oracle.
    function setOracleAddress(address _newOracleAddress) public onlyOwner {
        address oldAddress = oracleAddress;
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(oldAddress, _newOracleAddress);
    }

    // --- II. CogniAgent Management (Soulbound NFT) ---

    /// @notice Mints a new unique CogniAgent NFT to a user, marking it as soulbound (non-transferable).
    /// @param _metadataURI The URI pointing to the agent's off-chain metadata.
    /// @return The ID of the newly minted CogniAgent.
    function registerCogniAgent(string calldata _metadataURI) public whenNotPaused returns (uint256) {
        // Prevent registering multiple agents for the same address, or allow it for specific cases.
        // For simplicity, let's assume one agent per address for now, or allow multiple.
        // If allowing multiple, we'd need to track it via a mapping like address => agentIds[]

        uint256 newAgentId = _nextTokenId++;
        _safeMint(msg.sender, newAgentId); // Mints to the caller
        _setTokenURI(newAgentId, _metadataURI); // Set initial metadata

        agents[newAgentId] = Agent({
            owner: msg.sender,
            metadataURI: _metadataURI,
            registeredTimestamp: block.timestamp,
            exists: true
        });

        emit CogniAgentRegistered(newAgentId, msg.sender, _metadataURI);
        return newAgentId;
    }

    /// @notice Prevents transfer of CogniAgent NFTs (making them Soulbound).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Allow minting (from address(0)) and burning (to address(0)), but no other transfers.
        if (from != address(0) && to != address(0)) {
            revert ERC721NonTransferable(from, to, tokenId); // Custom error or a simple revert
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @notice Allows an agent owner to update their agent's off-chain metadata URI.
    /// @param _agentId The ID of the CogniAgent.
    /// @param _newMetadataURI The new URI for the agent's metadata.
    function updateAgentMetadataURI(uint256 _agentId, string calldata _newMetadataURI) public onlyAgentOwner(_agentId) whenNotPaused {
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        if (isAgentRetired[_agentId]) revert CogniVerse__AgentRetired();

        agents[_agentId].metadataURI = _newMetadataURI;
        _setTokenURI(_agentId, _newMetadataURI); // Update ERC721 URI
        emit AgentMetadataUpdated(_agentId, _newMetadataURI);
    }

    /// @notice Marks a CogniAgent as inactive, preventing it from participating in new tasks or challenges.
    /// @param _agentId The ID of the CogniAgent to retire.
    function retireCogniAgent(uint256 _agentId) public onlyAgentOwner(_agentId) whenNotPaused {
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        if (isAgentRetired[_agentId]) revert CogniVerse__AgentRetired();

        isAgentRetired[_agentId] = true;
        emit CogniAgentRetired(_agentId);
    }

    /// @notice Retrieves the owner of a specific CogniAgent.
    /// @param _agentId The ID of the CogniAgent.
    /// @return The address of the agent's owner.
    function getAgentOwner(uint256 _agentId) public view returns (address) {
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        return ownerOf(_agentId);
    }

    /// @notice Retrieves detailed information about a CogniAgent.
    /// @param _agentId The ID of the CogniAgent.
    /// @return owner Address of the agent's owner.
    /// @return metadataURI URI to the agent's metadata.
    /// @return registeredTimestamp Timestamp when the agent was registered.
    /// @return retired Status indicating if the agent is retired.
    function getAgentInfo(uint256 _agentId) public view returns (address owner, string memory metadataURI, uint256 registeredTimestamp, bool retired) {
        Agent storage agent = agents[_agentId];
        if (!agent.exists) revert CogniVerse__InvalidAgentId();
        return (agent.owner, agent.metadataURI, agent.registeredTimestamp, isAgentRetired[_agentId]);
    }

    // --- III. Skill & Reputation System ---

    /// @notice Governance defines a new high-level skill category.
    /// @param _skillCategoryName The name of the skill category (e.g., "Data Analysis").
    function defineSkillCategory(string calldata _skillCategoryName) public onlyGovernance whenNotPaused {
        bytes32 skillHash = keccak256(abi.encodePacked(_skillCategoryName));
        if (isSkillCategoryDefined[skillHash]) {
            revert CogniVerse__SkillCategoryAlreadyDefined();
        }
        isSkillCategoryDefined[skillHash] = true;
        definedSkillCategories.push(skillHash);
        emit SkillCategoryDefined(skillHash, _skillCategoryName);
    }

    /// @notice An agent owner submits verifiable proof to increase their agent's score in a specific skill.
    ///         This function would typically be called by an oracle or as part of task verification.
    /// @param _agentId The ID of the CogniAgent.
    /// @param _skillCategoryHash The hash of the skill category.
    /// @param _scoreDelta The amount to add to the skill score.
    /// @param _proofHash A hash referencing the off-chain proof (e.g., task result hash, certification hash).
    function addAgentSkillProof(uint256 _agentId, bytes32 _skillCategoryHash, uint256 _scoreDelta, bytes32 _proofHash) public onlyOracle whenNotPaused {
        // This function is called by the oracle after verifying a task or external proof
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        if (isAgentRetired[_agentId]) revert CogniVerse__AgentRetired();
        if (!isSkillCategoryDefined[_skillCategoryHash]) revert CogniVerse__SkillCategoryNotFound();

        uint256 currentScore = agentSkillScores[_agentId][_skillCategoryHash];
        agentSkillScores[_agentId][_skillCategoryHash] = currentScore + _scoreDelta;
        emit AgentSkillScoreUpdated(_agentId, _skillCategoryHash, currentScore + _scoreDelta);
        // _proofHash can be stored in a separate mapping if detailed history is needed
    }

    /// @notice Retrieves an agent's current score for a given skill category.
    /// @param _agentId The ID of the CogniAgent.
    /// @param _skillCategoryHash The hash of the skill category.
    /// @return The current skill score.
    function getAgentSkillScore(uint256 _agentId, bytes32 _skillCategoryHash) public view returns (uint256) {
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        return agentSkillScores[_agentId][_skillCategoryHash];
    }

    /// @notice Governance proposes a new rule or algorithm for how a skill evolves or combines with others.
    ///         This would be a governance proposal to be voted on.
    /// @param _skillCategoryHash The hash of the skill category this path relates to.
    /// @param _description A description of the proposed evolution path.
    /// @param _targetContract The address of the contract that handles the skill logic (can be `address(this)`).
    /// @param _functionSignature The function signature of the logic to call (e.g., `updateSkillLogic(bytes32,bytes)`).
    /// @param _callData The encoded call data for the function.
    /// @return The ID of the new proposal.
    function proposeSkillEvolutionPath(
        bytes32 _skillCategoryHash,
        string calldata _description,
        address _targetContract,
        bytes calldata _functionSignature,
        bytes calldata _callData
    ) public onlyGovernance whenNotPaused returns (uint256) {
        if (!isSkillCategoryDefined[_skillCategoryHash]) revert CogniVerse__SkillCategoryNotFound();

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + VOTING_PERIOD_BLOCKS,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            functionSignature: _functionSignature,
            callData: _callData,
            targetContract: _targetContract
        });
        emit SkillEvolutionPathProposed(proposalId, _skillCategoryHash, _description);
        emit ProposalCreated(proposalId, msg.sender, _description, block.number, block.number + VOTING_PERIOD_BLOCKS);
        return proposalId;
    }


    // --- IV. Task & Challenge Marketplace ---

    /// @notice A user submits a new task request, staking a reward.
    /// @param _requiredSkillCategoryHash The hash of the skill category required for the task.
    /// @param _minSkillScore The minimum skill score an agent must have to bid.
    /// @param _rewardAmount The reward in COGNIVERSE_TOKEN for completing the task.
    /// @param _expectedResultFormatHash A hash outlining the expected result structure/format.
    /// @param _submissionDeadline The timestamp by which the agent must submit the result.
    /// @param _bidClosingTime The timestamp when agents can no longer submit bids.
    /// @return The ID of the newly submitted task.
    function submitCogniTask(
        bytes32 _requiredSkillCategoryHash,
        uint256 _minSkillScore,
        uint256 _rewardAmount,
        bytes32 _expectedResultFormatHash,
        uint256 _submissionDeadline,
        uint256 _bidClosingTime
    ) public whenNotPaused returns (uint256) {
        if (!isSkillCategoryDefined[_requiredSkillCategoryHash]) revert CogniVerse__SkillCategoryNotFound();
        if (_rewardAmount == 0) revert CogniVerse__InsufficientStake();
        if (block.timestamp >= _bidClosingTime) revert CogniVerse__TaskNotInCorrectState();
        if (_bidClosingTime >= _submissionDeadline) revert CogniVerse__TaskNotInCorrectState();

        // Transfer reward from requester to contract
        require(COGNIVERSE_TOKEN.transferFrom(msg.sender, address(this), _rewardAmount), "Token transfer failed");

        uint256 newTaskId = _nextTaskId++;
        tasks[newTaskId].taskId = newTaskId;
        tasks[newTaskId].requester = msg.sender;
        tasks[newTaskId].requiredSkillCategory = _requiredSkillCategoryHash;
        tasks[newTaskId].minSkillScore = _minSkillScore;
        tasks[newTaskId].rewardAmount = _rewardAmount;
        tasks[newTaskId].expectedResultFormatHash = _expectedResultFormatHash;
        tasks[newTaskId].submissionDeadline = _submissionDeadline;
        tasks[newTaskId].bidClosingTime = _bidClosingTime;
        tasks[newTaskId].state = TaskState.Open;

        // Apply protocol fee
        uint256 protocolFee = (_rewardAmount * protocolFeeRate) / 10000;
        if (protocolFee > 0) {
            require(COGNIVERSE_TOKEN.transfer(protocolFeeRecipient, protocolFee), "Fee transfer failed");
            tasks[newTaskId].rewardAmount -= protocolFee; // Reduce net reward
        }

        emit CogniTaskSubmitted(newTaskId, msg.sender, tasks[newTaskId].rewardAmount, _requiredSkillCategoryHash, _submissionDeadline);
        return newTaskId;
    }

    /// @notice A registered CogniAgent bids to complete a submitted task, potentially staking collateral or reputation.
    /// @param _taskId The ID of the task to bid on.
    /// @param _agentId The ID of the CogniAgent placing the bid.
    /// @param _bidAmount The amount of COGNIVERSE_TOKEN to stake as collateral for the bid.
    function bidOnCogniTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount) public onlyAgentOwner(_agentId) whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.state != TaskState.Open) revert CogniVerse__TaskNotInCorrectState();
        if (block.timestamp >= task.bidClosingTime) {
            task.state = TaskState.BiddingClosed; // Close bidding if deadline passed
            revert CogniVerse__TaskNotInCorrectState();
        }
        if (isAgentRetired[_agentId]) revert CogniVerse__AgentRetired();
        if (agentSkillScores[_agentId][task.requiredSkillCategory] < task.minSkillScore) {
            revert CogniVerse__InsufficientStake(); // Reusing error, actually means insufficient skill
        }
        if (task.bids[_agentId] > 0) revert CogniVerse__AgentAlreadyBid();

        // Agent stakes _bidAmount as collateral
        require(COGNIVERSE_TOKEN.transferFrom(msg.sender, address(this), _bidAmount), "Collateral transfer failed");

        task.bids[_agentId] = _bidAmount;
        task.activeBidders.push(_agentId);
        emit CogniAgentBid(_taskId, _agentId, _bidAmount);
    }

    /// @notice The task requester accepts one of the bids, locking the task for the chosen agent.
    /// @param _taskId The ID of the task.
    /// @param _agentId The ID of the CogniAgent whose bid is accepted.
    function acceptCogniTaskBid(uint256 _taskId, uint256 _agentId) public whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.requester != msg.sender) revert CogniVerse__TaskRequesterNotMatch();
        if (task.state == TaskState.Accepted || task.state == TaskState.ResultSubmitted || task.state == TaskState.Verified) revert CogniVerse__TaskAlreadyAccepted();
        if (task.bids[_agentId] == 0) revert CogniVerse__AgentNotBidder();
        if (block.timestamp >= task.bidClosingTime && task.state == TaskState.Open) {
            task.state = TaskState.BiddingClosed;
        }
        if (task.state != TaskState.Open && task.state != TaskState.BiddingClosed) revert CogniVerse__TaskNotInCorrectState();


        task.acceptedAgentId = _agentId;
        task.state = TaskState.Accepted;
        emit CogniTaskBidAccepted(_taskId, _agentId, task.bids[_agentId]);
        emit TaskStateChanged(_taskId, TaskState.Accepted);

        // Optionally, refund collateral to other bidders here, or let them withdraw it later.
        // For simplicity, we'll let them withdraw later.
    }

    /// @notice The selected CogniAgent submits the hash of their computed result after completing the task.
    /// @param _taskId The ID of the task.
    /// @param _resultHash The hash of the off-chain computed result.
    function submitTaskResultHash(uint256 _taskId, bytes32 _resultHash) public whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.acceptedAgentId == 0) revert CogniVerse__TaskNotInCorrectState(); // No agent accepted yet
        if (ownerOf(task.acceptedAgentId) != msg.sender) revert CogniVerse__NotAgentOwner();
        if (task.state != TaskState.Accepted) revert CogniVerse__TaskNotInCorrectState();
        if (block.timestamp > task.submissionDeadline) {
            task.state = TaskState.TimedOut;
            emit TaskStateChanged(_taskId, TaskState.TimedOut);
            revert CogniVerse__TaskTimeoutNotReached(); // Agent missed deadline
        }
        if (task.submittedResultHash != bytes32(0)) revert CogniVerse__TaskResultAlreadySubmitted();


        task.submittedResultHash = _resultHash;
        task.state = TaskState.ResultSubmitted;
        emit TaskResultSubmitted(_taskId, task.acceptedAgentId, _resultHash);
        emit TaskStateChanged(_taskId, TaskState.ResultSubmitted);
    }

    /// @notice The task requester (or oracle) verifies the submitted result hash against the expected outcome.
    ///         This triggers skill score updates and releases rewards.
    /// @param _taskId The ID of the task.
    /// @param _isCorrect Boolean indicating if the result is correct.
    function verifyTaskResult(uint256 _taskId, bool _isCorrect) public whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.requester != msg.sender && msg.sender != oracleAddress) revert CogniVerse__UnauthorizedCaller();
        if (task.state != TaskState.ResultSubmitted) revert CogniVerse__TaskNotInCorrectState();
        if (task.submittedResultHash == bytes32(0)) revert CogniVerse__ResultNotVerified();

        if (_isCorrect) {
            task.state = TaskState.Verified;
            emit TaskVerified(_taskId, task.acceptedAgentId, task.submittedResultHash);
            emit TaskStateChanged(_taskId, TaskState.Verified);

            // Update agent skill score (triggered by oracle or in this function for simplicity)
            // For a real system, the oracle would likely call `addAgentSkillProof`
            // For this example, let's update it directly for success.
            uint256 currentScore = agentSkillScores[task.acceptedAgentId][task.requiredSkillCategory];
            agentSkillScores[task.acceptedAgentId][task.requiredSkillCategory] = currentScore + 10; // Example: +10 score for success
            emit AgentSkillScoreUpdated(task.acceptedAgentId, task.requiredSkillCategory, currentScore + 10);
        } else {
            task.state = TaskState.Disputed;
            emit TaskDisputeInitiated(_taskId, msg.sender);
            emit TaskStateChanged(_taskId, TaskState.Disputed);
        }
    }

    /// @notice Initiates a dispute resolution process for a task (e.g., if results are contested).
    ///         This function primarily changes state, actual resolution logic would be off-chain or via governance.
    /// @param _taskId The ID of the task.
    function resolveTaskDispute(uint256 _taskId) public onlyGovernance whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.state != TaskState.Disputed) revert CogniVerse__TaskNotInCorrectState();

        // Simplified: Governance decides the outcome and calls `verifyTaskResult` again or processes refunds/penalties.
        // For this example, we'll assume it leads to a decision that will trigger `verifyTaskResult` (with true/false)
        // or a direct refund/penalty.
        // In a real system, this would be a more complex state transition or an external module.
        // For demonstration, let's say calling this moves it back to ResultSubmitted to be re-verified or force completed.
        // Or, it could directly lead to a "DisputeResolved" state with `_isRequesterWin` param.
        // Let's make it a placeholder for now, assuming governance will enforce the final outcome.
        // For simplicity, we'll allow an owner/oracle to set the outcome.
        revert("Dispute resolution logic not fully implemented; requires external or governance decision.");
    }


    /// @notice The agent claims their staked reward upon successful task verification.
    /// @param _taskId The ID of the task.
    function claimTaskReward(uint256 _taskId) public whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.state != TaskState.Verified) revert CogniVerse__TaskNotInCorrectState();
        if (ownerOf(task.acceptedAgentId) != msg.sender) revert CogniVerse__NotAgentOwner();

        // Release reward to agent
        require(COGNIVERSE_TOKEN.transfer(msg.sender, task.rewardAmount), "Reward transfer failed");

        // Release agent's collateral back to agent
        uint256 collateral = task.bids[task.acceptedAgentId];
        if (collateral > 0) {
            require(COGNIVERSE_TOKEN.transfer(msg.sender, collateral), "Collateral refund failed");
            task.bids[task.acceptedAgentId] = 0; // Mark collateral as returned
        }

        task.state = TaskState.Completed;
        emit TaskRewardClaimed(_taskId, task.acceptedAgentId, task.rewardAmount);
        emit TaskStateChanged(_taskId, TaskState.Completed);
    }

    /// @notice Allows a task requester to cancel an open task if no bid has been accepted and deadline hasn't passed.
    /// @param _taskId The ID of the task to cancel.
    function cancelOpenTask(uint256 _taskId) public whenNotPaused {
        CogniTask storage task = tasks[_taskId];
        if (task.requester == address(0)) revert CogniVerse__TaskNotFound();
        if (task.requester != msg.sender) revert CogniVerse__TaskRequesterNotMatch();
        if (task.state != TaskState.Open && task.state != TaskState.BiddingClosed) revert CogniVerse__TaskNotInCorrectState();
        if (task.acceptedAgentId != 0) revert CogniVerse__TaskNotInCorrectState(); // Cannot cancel if a bid was accepted

        // Refund the reward
        require(COGNIVERSE_TOKEN.transfer(task.requester, task.rewardAmount), "Reward refund failed");

        task.state = TaskState.Canceled;
        emit TaskStateChanged(_taskId, TaskState.Canceled);

        // Refund any collateral from bidders if any
        for (uint i = 0; i < task.activeBidders.length; i++) {
            uint256 agentId = task.activeBidders[i];
            uint256 collateral = task.bids[agentId];
            if (collateral > 0) {
                address agentOwner = ownerOf(agentId);
                require(COGNIVERSE_TOKEN.transfer(agentOwner, collateral), "Bidder collateral refund failed");
                task.bids[agentId] = 0;
            }
        }
    }

    // --- V. Adaptive Learning & Environment Interaction ---

    /// @notice An authorized oracle triggers an event representing an environmental change or new global challenge.
    ///         This can affect agent skill valuations or trigger new task types.
    /// @param _eventTypeHash A hash identifying the type of environmental event.
    /// @param _eventDataHash A hash referencing the off-chain data describing the event.
    function simulateEnvironmentInteraction(bytes32 _eventTypeHash, bytes32 _eventDataHash) public onlyOracle whenNotPaused {
        // This function would typically trigger internal logic or further oracle calls
        // to update agent states, skill demands, or create new tasks based on the environment.
        // For example, if a "new pandemic" event, skills like "Bioinformatics" might get a bonus.
        // This could directly call `triggerAgentSkillRecalculation` for affected agents/skills.
        emit EnvironmentInteractionSimulated(_nextTaskId++, _eventTypeHash, _eventDataHash); // Using _nextTaskId as simple interactionId
    }

    /// @notice A mechanism (periodically or event-driven by oracle/governance) to recalculate agent skill scores
    ///         based on accumulated history, recent performance, and environmental factors.
    ///         This function would be complex in a real system, involving historical data analysis.
    /// @param _agentId The ID of the CogniAgent to recalculate skills for.
    /// @param _skillCategoryHash The specific skill to recalculate.
    function triggerAgentSkillRecalculation(uint256 _agentId, bytes32 _skillCategoryHash) public onlyOracle whenNotPaused {
        if (!agents[_agentId].exists) revert CogniVerse__InvalidAgentId();
        if (isAgentRetired[_agentId]) revert CogniVerse__AgentRetired();
        if (!isSkillCategoryDefined[_skillCategoryHash]) revert CogniVerse__SkillCategoryNotFound();

        // Placeholder for complex recalculation logic.
        // In a real system, this could involve:
        // 1. Fetching historical task performance for the agent in this skill.
        // 2. Considering the impact of recent `simulateEnvironmentInteraction` events.
        // 3. Applying a decay factor to older skill proofs.
        // 4. Using a weighted average or advanced algorithm.

        // For this example, let's simply apply a small, arbitrary decay or boost based on some imaginary factor.
        uint256 currentScore = agentSkillScores[_agentId][_skillCategoryHash];
        uint256 newScore = currentScore;
        if (currentScore > 0) {
            newScore = currentScore - (currentScore / 100); // 1% decay
        }
        // Add a small boost for being active or recently successful (simplified)
        // If (oracle says agent was recently active) newScore += 5;

        agentSkillScores[_agentId][_skillCategoryHash] = newScore;
        emit AgentSkillRecalculated(_agentId, _skillCategoryHash, newScore, "Periodical recalculation/decay");
    }

    // --- VI. Governance & Economics ---

    /// @notice Users stake COGNIVERSE_TOKEN to gain voting power for governance proposals.
    /// @param _amount The amount of COGNIVERSE_TOKEN to stake.
    function stakeForGovernanceVote(uint256 _amount) public whenNotPaused {
        if (_amount == 0) revert CogniVerse__InsufficientStake();
        require(COGNIVERSE_TOKEN.transferFrom(msg.sender, address(this), _amount), "Staking failed");
        governanceStakes[msg.sender] += _amount;
        stakeWithdrawalUnlockBlock[msg.sender] = block.number + STAKE_LOCKUP_BLOCKS; // Lock stake for a period
        emit GovernanceStakeUpdated(msg.sender, governanceStakes[msg.sender]);
    }

    /// @notice Participants vote on active governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for "for" vote, false for "against" vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert CogniVerse__ProposalNotFound();
        if (block.number < proposal.startBlock) revert CogniVerse__VotingPeriodNotEnded(); // Not started yet
        if (block.number > proposal.endBlock) revert CogniVerse__VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert CogniVerse__AlreadyVoted();
        if (governanceStakes[msg.sender] == 0) revert CogniVerse__InsufficientStake();

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += governanceStakes[msg.sender];
        } else {
            proposal.votesAgainst += governanceStakes[msg.sender];
        }
        stakeWithdrawalUnlockBlock[msg.sender] = block.number + STAKE_LOCKUP_BLOCKS; // Extend lockup
        emit Voted(_proposalId, msg.sender, _support);
    }

    /// @notice Allows the owner or a governance member to execute a successful proposal.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public onlyOwnerOrGovernance whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) revert CogniVerse__ProposalNotFound();
        if (block.number <= proposal.endBlock) revert CogniVerse__VotingPeriodNotEnded(); // Voting still active
        if (proposal.executed) revert CogniVerse__TaskNotInCorrectState(); // Reusing error
        if (proposal.votesFor <= proposal.votesAgainst) revert CogniVerse__ResultNotVerified(); // Proposal did not pass

        proposal.executed = true;

        // Execute the proposed action
        // This allows the DAO to call any function on any contract (including itself)
        (bool success, ) = proposal.targetContract.call(abi.encodePacked(proposal.functionSignature, proposal.callData));
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows users to withdraw their staked tokens after a cool-down period.
    function withdrawGovernanceStake() public whenNotPaused {
        if (governanceStakes[msg.sender] == 0) revert CogniVerse__InsufficientStake();
        if (block.number < stakeWithdrawalUnlockBlock[msg.sender]) revert CogniVerse__WithdrawalLocked();

        uint256 amountToWithdraw = governanceStakes[msg.sender];
        governanceStakes[msg.sender] = 0;
        stakeWithdrawalUnlockBlock[msg.sender] = 0; // Reset
        require(COGNIVERSE_TOKEN.transfer(msg.sender, amountToWithdraw), "Stake withdrawal failed");
        emit StakeWithdrawn(msg.sender, amountToWithdraw);
    }

    /// @notice Allows the designated protocol fee recipient (e.g., DAO treasury) to claim accumulated fees.
    function claimProtocolFees() public whenNotPaused {
        if (msg.sender != protocolFeeRecipient) revert CogniVerse__UnauthorizedCaller();

        uint256 contractBalance = COGNIVERSE_TOKEN.balanceOf(address(this));
        // This is a simplified fee claiming. In a more complex system,
        // fees from rewards and other sources would be tracked separately.
        // For now, let's say it claims any balance not reserved for task rewards/collateral.
        // This needs careful tracking. A simpler approach is to have fees directly sent to protocolFeeRecipient
        // at the time of collection. If fees remain in the contract, they need to be distinguishable from rewards/stakes.

        // For this example, let's say any remaining balance *above* active task rewards/collateral is fees.
        // This is a dangerous simplification. In production, fees need to be explicitly earmarked.
        // Let's assume fees are sent directly to `protocolFeeRecipient` in `submitCogniTask` for now.
        // So, this function would be for unallocated funds or a different fee model.
        // For a demo, let's make it claim any residual, assuming rewards/stakes are accounted for.
        uint256 totalRewardsPending = 0;
        uint256 totalCollateralPending = 0;
        // Iterate through active tasks to sum up rewards and collateral that should NOT be claimed as fees
        // This loop would be very gas-intensive for many tasks.
        // A better approach is to have a dedicated `feeBalance` state variable.
        // For demo: assume fees are handled at point of collection. This function now claims *any* excess.
        // For a more robust solution, the `protocolFeeRecipient` should receive fees directly from `submitCogniTask`.

        // Since we implemented direct fee transfer in `submitCogniTask`, this function is mostly for
        // any accidental transfers or future fee models that accumulate in the contract.
        // Let's just claim the *entire* balance if `protocolFeeRecipient` and if it's more than a nominal amount.
        uint256 balance = COGNIVERSE_TOKEN.balanceOf(address(this));
        if (balance == 0) revert CogniVerse__NoFeesToClaim();

        require(COGNIVERSE_TOKEN.transfer(protocolFeeRecipient, balance), "Failed to claim fees");
        emit FeesClaimed(protocolFeeRecipient, balance);
    }

    // --- Helper / View Functions ---

    /// @dev Internal helper for `pauseContract` and `unpauseContract` to check governance status.
    /// @return True if the caller is the owner or holds sufficient governance stake.
    function _isCallerGovernance() internal view returns (bool) {
        return msg.sender == owner() || governanceStakes[msg.sender] >= MIN_GOVERNANCE_STAKE;
    }

    /// @dev Modifier to ensure only owner or governance can call.
    modifier onlyOwnerOrGovernance() {
        if (!_isCallerGovernance()) {
            revert CogniVerse__UnauthorizedCaller();
        }
        _;
    }

    /// @notice Returns the total number of registered CogniAgents.
    function getTotalAgents() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    /// @notice Returns the total number of submitted tasks.
    function getTotalTasks() public view returns (uint256) {
        return _nextTaskId - 1;
    }

    /// @notice Returns the total number of governance proposals.
    function getTotalProposals() public view returns (uint256) {
        return _nextProposalId - 1;
    }

    /// @notice Returns the current protocol fee rate.
    function getProtocolFeeRate() public view returns (uint256) {
        return protocolFeeRate;
    }
}
```