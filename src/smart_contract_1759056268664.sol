```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Outline and Function Summary:
//
// This contract, `DecentralizedVerifiableCognitionNetwork (DVCN)`, serves as a platform
// for decentralized knowledge generation, inference execution, and verifiable computation.
// It aims to build a trusted network where participants can:
// 1. Submit and verify "Knowledge Fragments" (data/claims).
// 2. Propose and execute "Inference Tasks" using "Inference Models".
// 3. Establish a reputation for honest participation.
// 4. Utilize an integrated staking mechanism for security and incentives.
// 5. Lay the groundwork for ZK-proof verifiable computation.
//
// Actors:
// - Admin/Owner: Manages core protocol parameters and resolves governance challenges.
// - Agent: A general participant who can be a Knowledge Provider, Inference Agent, Challenger, or Validator.
// - Requester: Initiates Inference Tasks.
//
// Core Concepts:
// - Knowledge Fragment: A piece of data or a claim, linked off-chain (IPFS).
// - Inference Model: An algorithm or program, linked off-chain (IPFS), used to process knowledge.
// - Inference Task: A request to execute a specific model on specific knowledge fragments.
// - Reputation System: Agents gain/lose reputation based on correct/incorrect actions (submissions, challenges, validations).
// - Staking: Required collateral for participation, securing honest behavior and incentivizing validation.
// - ZK-Proof Integration: Functions are designed to accept ZK-proofs for verifiable off-chain computation.
// - Governance: Initial Admin control with functions to evolve towards community governance.
//
// Function Summary (31 Functions):
//
// I. Core Management & Agent Lifecycle (7 functions):
// 1. constructor(): Initializes the contract with an admin and the staking token address.
// 2. registerAgent(string memory _alias, bytes32 _ipfsProfileHash): Allows a user to register as an agent, staking tokens.
// 3. updateAgentProfile(string memory _newAlias, bytes32 _ipfsProfileHash): Agents update their public profile details.
// 4. deregisterAgent(): Initiates the process for an agent to leave the network and unstake their tokens after an unbonding period.
// 5. stakeTokens(uint256 _amount): Allows an agent to increase their staked amount.
// 6. unstakeTokens(uint256 _amount): Initiates unstaking, subject to unbonding period.
// 7. claimUnstakedTokens(): Allows an agent to claim their unstaked tokens after the unbonding period.
//
// II. Knowledge Fragment Management (5 functions):
// 8. proposeNewTopic(string memory _topicName, string memory _description): Allows anyone to propose a new knowledge topic for governance approval.
// 9. approveTopic(uint256 _topicId): Admin/Governance function to approve a proposed topic.
// 10. submitKnowledgeFragment(uint256 _topicId, bytes32 _dataIpfsHash, string memory _description): Agents submit new knowledge fragments.
// 11. challengeKnowledgeFragment(uint256 _fragmentId, string memory _reason): Agents challenge the veracity of a knowledge fragment, requiring a bond.
// 12. validateKnowledgeFragment(uint256 _fragmentId): Agents validate (endorse) a knowledge fragment, requiring a bond.
//
// III. Inference Model & Task Management (6 functions):
// 13. submitInferenceModel(string memory _modelName, bytes32 _codeIpfsHash, string memory _parametersJson): Agents submit new inference models.
// 14. proposeInferenceTask(uint256 _modelId, uint256[] memory _fragmentIds, uint256 _rewardAmount, uint256 _deadline): Requesters propose tasks for agents to execute.
// 15. acceptInferenceTask(uint256 _taskId): Inference Agents accept and commit to an inference task.
// 16. submitInferenceResult(uint256 _taskId, bytes32 _resultIpfsHash, bytes memory _zkProofData): Inference Agents submit computation results, optionally with a ZK-proof.
// 17. challengeInferenceResult(uint256 _taskId, string memory _reason): Agents challenge an inference result, requiring a bond.
// 18. validateInferenceResult(uint256 _taskId): Agents validate (endorse) an inference result, requiring a bond.
//
// IV. Challenge Resolution & Rewards (3 functions):
// 19. resolveChallenge(uint256 _challengeId, bool _isChallengerCorrect): Admin/Governance resolves a challenge (either knowledge or result), adjusting reputations and distributing bonds/rewards.
// 20. claimTaskReward(uint256 _taskId): The winning agent of a validated task claims their reward.
// 21. claimChallengeReward(uint256 _challengeId): The winning party (challenger or defender) of a resolved challenge claims their adjusted bond/reward.
//
// V. Governance & System Parameters (4 functions):
// 22. updateProtocolParameter(bytes32 _paramName, uint256 _newValue): Admin/Governance function to update various protocol settings.
// 23. pauseContract(): Admin/Governance function to pause critical contract operations (e.g., during upgrades or emergencies).
// 24. unpauseContract(): Admin/Governance function to unpause the contract.
// 25. setZKVerifierContract(address _verifierAddress): Admin/Governance function to set an external ZK-proof verifier contract address.
//
// VI. View Functions (6 functions):
// 26. getAgentProfile(address _agent): Retrieves an agent's profile details.
// 27. getKnowledgeFragment(uint256 _fragmentId): Retrieves details of a knowledge fragment.
// 28. getInferenceModel(uint256 _modelId): Retrieves details of an inference model.
// 29. getInferenceTask(uint256 _taskId): Retrieves details of an inference task.
// 30. getChallenge(uint256 _challengeId): Retrieves details of a challenge.
// 31. getTopic(uint256 _topicId): Retrieves details of a topic.
//
// This contract uses the Pausable and Ownable patterns from OpenZeppelin for enhanced security and management.
// It uses a generic IERC20 for the staking/reward token, assuming its deployment separately,
// though for simplicity in this example, `msg.value` (native ETH) is used for staking and rewards.
// ZK-Proof integration is conceptual; actual on-chain verification would require a dedicated verifier contract or precompile.

contract DecentralizedVerifiableCognitionNetwork is Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables & Counters ---
    IERC20 public immutable stakingToken; // Placeholder for a real ERC20 staking token

    Counters.Counter private _agentIdCounter;
    Counters.Counter private _topicIdCounter;
    Counters.Counter private _knowledgeFragmentIdCounter;
    Counters.Counter private _inferenceModelIdCounter;
    Counters.Counter private _inferenceTaskIdCounter;
    Counters.Counter private _challengeIdCounter;

    // --- Data Structures ---

    enum AgentStatus {
        Inactive,
        Registered,
        Unbonding
    }

    enum ChallengeType {
        KnowledgeFragment,
        InferenceResult
    }

    enum ChallengeStatus {
        Open,
        ResolvedChallengerWon,
        ResolvedChallengerLost
    }

    enum InferenceTaskStatus {
        Proposed,
        Accepted,
        ResultSubmitted,
        Validated,
        Challenged,
        FailedDeadline
    }

    struct AgentProfile {
        uint256 id;
        address agentAddress;
        string alias;
        bytes32 ipfsProfileHash; // IPFS hash for a more detailed off-chain profile
        uint256 stakedAmount;
        int256 reputationScore; // Can be negative for bad actors
        AgentStatus status;
        uint256 unbondingStartTime; // Timestamp when unbonding started
        uint256 unbondingAmount; // Amount currently in unbonding
    }

    struct Topic {
        uint256 id;
        string name;
        string description;
        bool isApproved;
        address proposer;
        uint256 proposalTimestamp;
    }

    struct KnowledgeFragment {
        uint256 id;
        uint256 topicId;
        address provider;
        bytes32 dataIpfsHash; // IPFS hash pointing to the actual knowledge data
        string description;
        uint256 submissionTimestamp;
        int256 veracityScore; // Aggregate score from validations/challenges
        uint256 activeChallengeId; // 0 if no active challenge
    }

    struct InferenceModel {
        uint256 id;
        address owner; // The agent who submitted the model
        string name;
        bytes32 codeIpfsHash; // IPFS hash pointing to the model's executable code (e.g., WASM, Python script)
        string parametersJson; // JSON string of required model parameters
        uint256 submissionTimestamp;
    }

    struct InferenceTask {
        uint256 id;
        uint256 modelId;
        address requester;
        address executor; // Agent who accepted the task
        uint256[] fragmentIds; // Knowledge fragments to be used by the model
        uint256 rewardAmount; // Staking tokens offered for task completion
        uint256 deadline; // Timestamp by which the result must be submitted
        bytes32 resultIpfsHash; // IPFS hash of the submitted result
        bytes zkProofData; // Optional ZK-proof for the result
        InferenceTaskStatus status;
        uint256 submissionTimestamp; // Timestamp of result submission
        uint256 activeChallengeId; // 0 if no active challenge
    }

    struct Challenge {
        uint256 id;
        ChallengeType challengeType;
        uint256 entityId; // ID of the KnowledgeFragment or InferenceTask being challenged
        address challenger;
        string reason;
        uint256 challengeBond; // Tokens staked by the challenger
        ChallengeStatus status;
        uint256 challengeTimestamp;
        address defender; // The provider/executor of the challenged entity
        uint256 defenderBond; // Tokens staked by the defender for defense
    }

    // --- Mappings ---
    mapping(address => AgentProfile) public agents;
    mapping(uint256 => Topic) public topics;
    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    mapping(uint256 => InferenceModel) public inferenceModels;
    mapping(uint256 => InferenceTask) public inferenceTasks;
    mapping(uint256 => Challenge) public challenges;
    
    // Agent ID to Address mapping (useful for external systems looking up by ID)
    mapping(uint256 => address) public agentIdToAddress;

    // --- Protocol Parameters (Managed by Governance) ---
    mapping(bytes32 => uint256) public protocolParameters;

    // Default parameter names (hashed for efficiency)
    bytes32 public constant MIN_STAKE_AMOUNT_PARAM = keccak256("MIN_STAKE_AMOUNT");
    bytes32 public constant CHALLENGE_BOND_PARAM = keccak256("CHALLENGE_BOND");
    bytes32 public constant VALIDATION_BOND_PARAM = keccak256("VALIDATION_BOND");
    bytes32 public constant UNBONDING_PERIOD_PARAM = keccak256("UNBONDING_PERIOD");
    bytes32 public constant REPUTATION_CHANGE_ON_WIN_PARAM = keccak256("REPUTATION_CHANGE_ON_WIN");
    bytes32 public constant REPUTATION_CHANGE_ON_LOSS_PARAM = keccak256("REPUTATION_CHANGE_ON_LOSS");

    // ZK-proof verifier contract address (optional, for external verifier integration)
    address public zkVerifierContract;

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, uint256 agentId, string alias, uint256 stakedAmount);
    event AgentProfileUpdated(address indexed agentAddress, string newAlias, bytes32 ipfsProfileHash);
    event AgentDeregistered(address indexed agentAddress, uint256 agentId);
    event TokensStaked(address indexed agentAddress, uint256 amount, uint256 newTotalStake);
    event UnstakeRequested(address indexed agentAddress, uint256 amount, uint256 unbondingStartTime);
    event UnstakeCancelled(address indexed agentAddress, uint256 amount);
    event TokensUnstaked(address indexed agentAddress, uint256 amount);

    event TopicProposed(uint256 indexed topicId, string name, address indexed proposer);
    event TopicApproved(uint256 indexed topicId, string name);
    event KnowledgeFragmentSubmitted(uint256 indexed fragmentId, uint256 indexed topicId, address indexed provider, bytes32 dataIpfsHash);
    event KnowledgeFragmentChallenged(uint256 indexed fragmentId, uint256 indexed challengeId, address indexed challenger);
    event KnowledgeFragmentValidated(uint256 indexed fragmentId, uint256 indexed challengeId, address indexed validator);

    event InferenceModelSubmitted(uint256 indexed modelId, address indexed owner, string name, bytes32 codeIpfsHash);
    event InferenceTaskProposed(uint256 indexed taskId, uint256 indexed modelId, address indexed requester, uint256 rewardAmount, uint256 deadline);
    event InferenceTaskAccepted(uint256 indexed taskId, address indexed executor);
    event InferenceResultSubmitted(uint256 indexed taskId, address indexed executor, bytes32 resultIpfsHash, bool hasZkProof);
    event InferenceResultChallenged(uint256 indexed taskId, uint256 indexed challengeId, address indexed challenger);
    event InferenceResultValidated(uint256 indexed taskId, uint256 indexed challengeId, address indexed validator);
    event InferenceTaskRewardClaimed(uint256 indexed taskId, address indexed executor, uint256 rewardAmount);

    event ChallengeResolved(uint256 indexed challengeId, ChallengeType challengeType, uint256 entityId, ChallengeStatus status, address indexed winner, address indexed loser, uint256 winnerReward, uint256 loserPenalty);
    event ChallengeRewardClaimed(uint256 indexed challengeId, address indexed claimant, uint256 amount);

    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event ZKVerifierContractSet(address indexed verifierAddress);

    // --- Modifiers ---
    modifier onlyRegisteredAgent() {
        require(agents[msg.sender].status == AgentStatus.Registered, "DVCN: Caller is not a registered agent");
        _;
    }

    modifier onlyAgentWithMinStake() {
        require(agents[msg.sender].stakedAmount >= protocolParameters[MIN_STAKE_AMOUNT_PARAM], "DVCN: Insufficient stake");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the contract with the staking token address and default parameters.
    /// @param _stakingTokenAddress The address of the ERC20 token used for staking and rewards.
    constructor(address _stakingTokenAddress) Ownable(msg.sender) {
        require(_stakingTokenAddress != address(0), "DVCN: Staking token address cannot be zero");
        stakingToken = IERC20(_stakingTokenAddress);

        // Initialize default protocol parameters
        protocolParameters[MIN_STAKE_AMOUNT_PARAM] = 1000 * 10**18; // 1000 tokens (adjust for token decimals)
        protocolParameters[CHALLENGE_BOND_PARAM] = 100 * 10**18;   // 100 tokens
        protocolParameters[VALIDATION_BOND_PARAM] = 50 * 10**18;    // 50 tokens
        protocolParameters[UNBONDING_PERIOD_PARAM] = 7 days;       // 7 days
        protocolParameters[REPUTATION_CHANGE_ON_WIN_PARAM] = 50;   // Win 50 reputation points
        protocolParameters[REPUTATION_CHANGE_ON_LOSS_PARAM] = 25;  // Lose 25 reputation points
    }

    // --- I. Core Management & Agent Lifecycle (7 functions) ---

    /// @notice Allows a user to register as an agent by staking tokens.
    /// This function expects `msg.value` to be sent, assuming native ETH as staking,
    /// or, in a real ERC20 scenario, `stakingToken.approve` would be called externally
    /// and then `stakingToken.transferFrom` would be called here.
    /// @param _alias A public alias for the agent.
    /// @param _ipfsProfileHash IPFS hash of a detailed off-chain profile.
    function registerAgent(string memory _alias, bytes32 _ipfsProfileHash) public payable whenNotPaused {
        require(agents[msg.sender].status == AgentStatus.Inactive, "DVCN: Agent already registered or unbonding");
        require(bytes(_alias).length > 0, "DVCN: Alias cannot be empty");
        require(msg.value >= protocolParameters[MIN_STAKE_AMOUNT_PARAM], "DVCN: Must stake at least the minimum amount");

        _agentIdCounter.increment();
        uint256 newAgentId = _agentIdCounter.current();

        agents[msg.sender] = AgentProfile({
            id: newAgentId,
            agentAddress: msg.sender,
            alias: _alias,
            ipfsProfileHash: _ipfsProfileHash,
            stakedAmount: msg.value,
            reputationScore: 0,
            status: AgentStatus.Registered,
            unbondingStartTime: 0,
            unbondingAmount: 0
        });
        agentIdToAddress[newAgentId] = msg.sender;

        // If using ERC20: `require(stakingToken.transferFrom(msg.sender, address(this), msg.value), "DVCN: Staking token transfer failed");`
        // For this example, we're using ETH sent via `msg.value`.

        emit AgentRegistered(msg.sender, newAgentId, _alias, msg.value);
    }

    /// @notice Allows a registered agent to update their public profile details.
    /// @param _newAlias The new public alias for the agent.
    /// @param _ipfsProfileHash The new IPFS hash for their detailed off-chain profile.
    function updateAgentProfile(string memory _newAlias, bytes32 _ipfsProfileHash) public onlyRegisteredAgent whenNotPaused {
        agents[msg.sender].alias = _newAlias;
        agents[msg.sender].ipfsProfileHash = _ipfsProfileHash;
        emit AgentProfileUpdated(msg.sender, _newAlias, _ipfsProfileHash);
    }

    /// @notice Initiates the process for an agent to leave the network and unstake their tokens after an unbonding period.
    /// All currently staked tokens will enter the unbonding phase.
    function deregisterAgent() public onlyRegisteredAgent whenNotPaused {
        AgentProfile storage agent = agents[msg.sender];
        require(agent.stakedAmount > 0, "DVCN: No tokens to deregister");
        require(agent.unbondingStartTime == 0, "DVCN: Already has a pending unstake request");
        
        agent.status = AgentStatus.Unbonding;
        agent.unbondingStartTime = block.timestamp;
        agent.unbondingAmount = agent.stakedAmount; // All staked amount enters unbonding
        agent.stakedAmount = 0; // Move all to unbonding state

        emit UnstakeRequested(msg.sender, agent.unbondingAmount, agent.unbondingStartTime);
    }

    /// @notice Allows an agent to increase their staked amount.
    /// Expects `msg.value` to be sent (if using native ETH) or `stakingToken.approve` called prior (if using ERC20).
    /// @param _amount The amount of tokens to stake.
    function stakeTokens(uint256 _amount) public payable onlyRegisteredAgent whenNotPaused {
        require(_amount > 0, "DVCN: Stake amount must be greater than 0");
        require(msg.value == _amount, "DVCN: Sent amount must match stake amount"); // Native ETH for simplicity

        agents[msg.sender].stakedAmount += _amount;
        // If ERC20: require(stakingToken.transferFrom(msg.sender, address(this), _amount), "DVCN: Staking token transfer failed");

        emit TokensStaked(msg.sender, _amount, agents[msg.sender].stakedAmount);
    }

    /// @notice Initiates unstaking of a specific amount, subject to an unbonding period.
    /// The agent's status will change to Unbonding if they were Registered.
    /// @param _amount The amount of tokens to unstake.
    function unstakeTokens(uint256 _amount) public onlyRegisteredAgent whenNotPaused {
        AgentProfile storage agent = agents[msg.sender];
        require(_amount > 0, "DVCN: Unstake amount must be greater than 0");
        require(agent.stakedAmount >= _amount, "DVCN: Insufficient staked amount");
        require(agent.unbondingStartTime == 0, "DVCN: Already has a pending unstake request"); // Only one unbonding request at a time for simplicity

        agent.stakedAmount -= _amount;
        agent.unbondingAmount = _amount;
        agent.unbondingStartTime = block.timestamp;
        agent.status = AgentStatus.Unbonding; // Agent enters unbonding status even for partial unstake

        emit UnstakeRequested(msg.sender, _amount, agent.unbondingStartTime);
    }

    /// @notice Allows an agent to cancel a pending unstake request.
    /// The tokens will return to the agent's active staked balance.
    function cancelUnstakeRequest() public onlyRegisteredAgent whenNotPaused {
        AgentProfile storage agent = agents[msg.sender];
        require(agent.unbondingStartTime != 0, "DVCN: No active unstake request to cancel");

        agent.stakedAmount += agent.unbondingAmount;
        agent.unbondingAmount = 0;
        agent.unbondingStartTime = 0;
        agent.status = AgentStatus.Registered;

        emit UnstakeCancelled(msg.sender, agent.unbondingAmount);
    }

    /// @notice Allows an agent to claim their unstaked tokens after the unbonding period has passed.
    function claimUnstakedTokens() public onlyRegisteredAgent whenNotPaused {
        AgentProfile storage agent = agents[msg.sender];
        require(agent.unbondingStartTime != 0, "DVCN: No active unstake request");
        require(block.timestamp >= agent.unbondingStartTime + protocolParameters[UNBONDING_PERIOD_PARAM], "DVCN: Unbonding period not over yet");
        require(agent.unbondingAmount > 0, "DVCN: No tokens to claim from unbonding");

        uint256 amountToTransfer = agent.unbondingAmount;
        agent.unbondingAmount = 0;
        agent.unbondingStartTime = 0;
        if (agent.stakedAmount == 0) { // If all tokens were unbonded, set status to inactive
            agent.status = AgentStatus.Inactive;
        } else {
            agent.status = AgentStatus.Registered; // If partial unbond, set back to registered
        }

        // For simplicity, using native ETH transfer; in a real ERC20 scenario it would be `stakingToken.transfer()`
        (bool success, ) = payable(msg.sender).call{value: amountToTransfer}("");
        require(success, "DVCN: Failed to transfer unstaked tokens");

        emit TokensUnstaked(msg.sender, amountToTransfer);
    }


    // --- II. Knowledge Fragment Management (5 functions) ---

    /// @notice Allows anyone to propose a new knowledge topic for governance approval.
    /// @param _topicName The name of the proposed topic.
    /// @param _description A brief description of the topic.
    function proposeNewTopic(string memory _topicName, string memory _description) public whenNotPaused {
        require(bytes(_topicName).length > 0, "DVCN: Topic name cannot be empty");
        _topicIdCounter.increment();
        uint256 newTopicId = _topicIdCounter.current();

        topics[newTopicId] = Topic({
            id: newTopicId,
            name: _topicName,
            description: _description,
            isApproved: false,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp
        });

        emit TopicProposed(newTopicId, _topicName, msg.sender);
    }

    /// @notice Admin/Governance function to approve a proposed topic.
    /// @param _topicId The ID of the topic to approve.
    function approveTopic(uint256 _topicId) public onlyOwner whenNotPaused {
        require(_topicId > 0 && _topicId <= _topicIdCounter.current(), "DVCN: Invalid topic ID");
        require(!topics[_topicId].isApproved, "DVCN: Topic already approved");

        topics[_topicId].isApproved = true;
        emit TopicApproved(_topicId, topics[_topicId].name);
    }

    /// @notice Agents submit new knowledge fragments. Requires an approved topic and minimum stake.
    /// @param _topicId The ID of the approved topic this fragment belongs to.
    /// @param _dataIpfsHash IPFS hash pointing to the actual knowledge data.
    /// @param _description A brief description of the knowledge fragment.
    function submitKnowledgeFragment(uint256 _topicId, bytes32 _dataIpfsHash, string memory _description) public onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        require(topics[_topicId].isApproved, "DVCN: Topic not approved");
        require(_dataIpfsHash != bytes32(0), "DVCN: IPFS hash cannot be empty");

        _knowledgeFragmentIdCounter.increment();
        uint256 newFragmentId = _knowledgeFragmentIdCounter.current();

        knowledgeFragments[newFragmentId] = KnowledgeFragment({
            id: newFragmentId,
            topicId: _topicId,
            provider: msg.sender,
            dataIpfsHash: _dataIpfsHash,
            description: _description,
            submissionTimestamp: block.timestamp,
            veracityScore: 0, // Initial score
            activeChallengeId: 0
        });

        emit KnowledgeFragmentSubmitted(newFragmentId, _topicId, msg.sender, _dataIpfsHash);
    }

    /// @notice Agents challenge the veracity of a knowledge fragment, requiring a bond.
    /// This function expects `msg.value` to be sent (if using native ETH).
    /// @param _fragmentId The ID of the knowledge fragment to challenge.
    /// @param _reason A reason for the challenge.
    function challengeKnowledgeFragment(uint256 _fragmentId, string memory _reason) public payable onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.id != 0, "DVCN: Knowledge fragment not found");
        require(fragment.provider != msg.sender, "DVCN: Cannot challenge your own fragment");
        require(fragment.activeChallengeId == 0, "DVCN: Fragment already has an active challenge");
        require(msg.value == protocolParameters[CHALLENGE_BOND_PARAM], "DVCN: Incorrect challenge bond amount"); // Native ETH for simplicity

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            challengeType: ChallengeType.KnowledgeFragment,
            entityId: _fragmentId,
            challenger: msg.sender,
            reason: _reason,
            challengeBond: msg.value, // Native ETH
            status: ChallengeStatus.Open,
            challengeTimestamp: block.timestamp,
            defender: fragment.provider,
            defenderBond: 0 // Defender stakes when prompted or by validating
        });
        fragment.activeChallengeId = newChallengeId;

        emit KnowledgeFragmentChallenged(_fragmentId, newChallengeId, msg.sender);
    }

    /// @notice Agents validate (endorse) a knowledge fragment, requiring a bond.
    /// If there's an active challenge, this acts as the defender's bond.
    /// This function expects `msg.value` to be sent (if using native ETH).
    /// @param _fragmentId The ID of the knowledge fragment to validate.
    function validateKnowledgeFragment(uint256 _fragmentId) public payable onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        require(fragment.id != 0, "DVCN: Knowledge fragment not found");
        require(fragment.provider != msg.sender, "DVCN: Cannot validate your own fragment");
        require(msg.value == protocolParameters[VALIDATION_BOND_PARAM], "DVCN: Incorrect validation bond amount"); // Native ETH for simplicity

        _challengeIdCounter.increment(); 
        uint256 newValidationId = _challengeIdCounter.current(); 

        // If there's an active challenge, this acts as staking a defender's bond.
        if (fragment.activeChallengeId != 0) {
            Challenge storage activeChallenge = challenges[fragment.activeChallengeId];
            require(activeChallenge.status == ChallengeStatus.Open, "DVCN: Active challenge is not open");
            require(activeChallenge.challenger != msg.sender, "DVCN: Cannot validate if you are the challenger of the active challenge");
            
            // This validator acts as a secondary defender, contributing to the defense bond.
            // A more robust system would manage multiple defenders and their bonds.
            activeChallenge.defenderBond += msg.value; 
            
            // This particular entry records the individual validation, but the primary challenge is still activeChallengeId
            challenges[newValidationId] = Challenge({ // Create a new entry for this specific validation act
                id: newValidationId,
                challengeType: ChallengeType.KnowledgeFragment,
                entityId: _fragmentId,
                challenger: msg.sender, // The 'validator' is the challenger in a positive sense
                reason: "Validation of Knowledge Fragment against active challenge",
                challengeBond: msg.value, // Native ETH (validation bond)
                status: ChallengeStatus.Open, // Status tied to the primary challenge
                challengeTimestamp: block.timestamp,
                defender: fragment.provider, 
                defenderBond: 0 // This bond is from the validator, not the main defender bond
            });
            emit KnowledgeFragmentValidated(_fragmentId, newValidationId, msg.sender);
            return; 
        }

        // If no active challenge, this is a standalone positive validation.
        // It's recorded as a 'challenge' with a positive intent to eventually increase veracityScore.
        challenges[newValidationId] = Challenge({
            id: newValidationId,
            challengeType: ChallengeType.KnowledgeFragment,
            entityId: _fragmentId,
            challenger: msg.sender,
            reason: "Positive validation of Knowledge Fragment",
            challengeBond: msg.value, // Native ETH (validation bond)
            status: ChallengeStatus.Open, // Needs to be resolved by governance to affect veracity
            challengeTimestamp: block.timestamp,
            defender: fragment.provider, // No direct defender in a standalone validation
            defenderBond: 0
        });

        emit KnowledgeFragmentValidated(_fragmentId, newValidationId, msg.sender);
    }


    // --- III. Inference Model & Task Management (6 functions) ---

    /// @notice Agents submit new inference models. Requires minimum stake.
    /// @param _modelName The name of the model.
    /// @param _codeIpfsHash IPFS hash pointing to the model's executable code.
    /// @param _parametersJson JSON string of required model parameters.
    function submitInferenceModel(string memory _modelName, bytes32 _codeIpfsHash, string memory _parametersJson) public onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        require(bytes(_modelName).length > 0, "DVCN: Model name cannot be empty");
        require(_codeIpfsHash != bytes32(0), "DVCN: Code IPFS hash cannot be empty");

        _inferenceModelIdCounter.increment();
        uint256 newModelId = _inferenceModelIdCounter.current();

        inferenceModels[newModelId] = InferenceModel({
            id: newModelId,
            owner: msg.sender,
            name: _modelName,
            codeIpfsHash: _codeIpfsHash,
            parametersJson: _parametersJson,
            submissionTimestamp: block.timestamp
        });

        emit InferenceModelSubmitted(newModelId, msg.sender, _modelName, _codeIpfsHash);
    }

    /// @notice Requesters propose tasks for agents to execute.
    /// This function expects `msg.value` to be sent (if using native ETH) as the reward.
    /// @param _modelId The ID of the inference model to use.
    /// @param _fragmentIds IDs of knowledge fragments to be used as input.
    /// @param _rewardAmount Staking tokens offered for task completion.
    /// @param _deadline Timestamp by which the result must be submitted.
    function proposeInferenceTask(uint256 _modelId, uint256[] memory _fragmentIds, uint256 _rewardAmount, uint256 _deadline) public payable whenNotPaused {
        require(inferenceModels[_modelId].id != 0, "DVCN: Inference model not found");
        require(_rewardAmount > 0, "DVCN: Reward amount must be greater than 0");
        require(_deadline > block.timestamp, "DVCN: Deadline must be in the future");
        require(msg.value == _rewardAmount, "DVCN: Sent ETH must match reward amount"); // Native ETH for simplicity

        for (uint256 i = 0; i < _fragmentIds.length; i++) {
            require(knowledgeFragments[_fragmentIds[i]].id != 0, "DVCN: Invalid knowledge fragment ID");
        }

        _inferenceTaskIdCounter.increment();
        uint256 newTaskId = _inferenceTaskIdCounter.current();

        inferenceTasks[newTaskId] = InferenceTask({
            id: newTaskId,
            modelId: _modelId,
            requester: msg.sender,
            executor: address(0), // No executor yet
            fragmentIds: _fragmentIds,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            resultIpfsHash: bytes32(0),
            zkProofData: "",
            status: InferenceTaskStatus.Proposed,
            submissionTimestamp: 0,
            activeChallengeId: 0
        });

        emit InferenceTaskProposed(newTaskId, _modelId, msg.sender, _rewardAmount, _deadline);
    }

    /// @notice Inference Agents accept and commit to an inference task. Requires a minimum stake.
    /// @param _taskId The ID of the task to accept.
    function acceptInferenceTask(uint256 _taskId) public onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        require(task.id != 0, "DVCN: Inference task not found");
        require(task.status == InferenceTaskStatus.Proposed, "DVCN: Task not in proposed state");
        require(task.deadline > block.timestamp, "DVCN: Task deadline has passed");

        task.executor = msg.sender;
        task.status = InferenceTaskStatus.Accepted;

        // Optionally, an agent might need to stake an additional bond to accept a task.
        // For simplicity, we rely on the MIN_STAKE_AMOUNT for general participation.

        emit InferenceTaskAccepted(_taskId, msg.sender);
    }

    /// @notice Inference Agents submit computation results, optionally with a ZK-proof.
    /// @param _taskId The ID of the task for which the result is submitted.
    /// @param _resultIpfsHash IPFS hash of the computation result.
    /// @param _zkProofData Optional ZK-proof data for verifiable computation.
    function submitInferenceResult(uint256 _taskId, bytes32 _resultIpfsHash, bytes memory _zkProofData) public onlyRegisteredAgent whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        require(task.id != 0, "DVCN: Inference task not found");
        require(task.executor == msg.sender, "DVCN: Only assigned executor can submit result");
        require(task.status == InferenceTaskStatus.Accepted, "DVCN: Task not in accepted state");
        require(task.deadline > block.timestamp, "DVCN: Submission deadline passed");
        require(_resultIpfsHash != bytes32(0), "DVCN: Result IPFS hash cannot be empty");

        task.resultIpfsHash = _resultIpfsHash;
        task.zkProofData = _zkProofData;
        task.submissionTimestamp = block.timestamp;
        task.status = InferenceTaskStatus.ResultSubmitted;

        // If a ZK-proof is provided, an external verifier contract could be called here.
        // For this example, we just store it.
        // if (zkVerifierContract != address(0) && _zkProofData.length > 0) {
        //     IZKVerifier(zkVerifierContract).verifyProof(...); // Example call, requires IZKVerifier interface
        // }

        emit InferenceResultSubmitted(_taskId, msg.sender, _resultIpfsHash, _zkProofData.length > 0);
    }

    /// @notice Agents challenge an inference result, requiring a bond.
    /// This function expects `msg.value` to be sent (if using native ETH).
    /// @param _taskId The ID of the inference task whose result is being challenged.
    /// @param _reason A reason for the challenge.
    function challengeInferenceResult(uint256 _taskId, string memory _reason) public payable onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        require(task.id != 0, "DVCN: Inference task not found");
        require(task.status == InferenceTaskStatus.ResultSubmitted, "DVCN: Task result not submitted or already challenged/resolved");
        require(task.executor != msg.sender, "DVCN: Cannot challenge your own result");
        require(task.activeChallengeId == 0, "DVCN: Task result already has an active challenge");
        require(msg.value == protocolParameters[CHALLENGE_BOND_PARAM], "DVCN: Incorrect challenge bond amount"); // Native ETH for simplicity

        _challengeIdCounter.increment();
        uint256 newChallengeId = _challengeIdCounter.current();

        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            challengeType: ChallengeType.InferenceResult,
            entityId: _taskId,
            challenger: msg.sender,
            reason: _reason,
            challengeBond: msg.value, // Native ETH
            status: ChallengeStatus.Open,
            challengeTimestamp: block.timestamp,
            defender: task.executor,
            defenderBond: 0 // Defender stakes when prompted or by validating
        });
        task.activeChallengeId = newChallengeId;
        task.status = InferenceTaskStatus.Challenged;

        emit InferenceResultChallenged(_taskId, newChallengeId, msg.sender);
    }

    /// @notice Agents validate (endorse) an inference result, requiring a bond.
    /// If there's an active challenge, this acts as the defender's bond.
    /// This function expects `msg.value` to be sent (if using native ETH).
    /// @param _taskId The ID of the inference task whose result is being validated.
    function validateInferenceResult(uint256 _taskId) public payable onlyRegisteredAgent onlyAgentWithMinStake whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        require(task.id != 0, "DVCN: Inference task not found");
        require(task.executor != msg.sender, "DVCN: Cannot validate your own result");
        require(task.status == InferenceTaskStatus.ResultSubmitted || task.status == InferenceTaskStatus.Challenged, "DVCN: Task result not submitted or already resolved");
        require(msg.value == protocolParameters[VALIDATION_BOND_PARAM], "DVCN: Incorrect validation bond amount"); // Native ETH for simplicity

        _challengeIdCounter.increment(); 
        uint256 newValidationId = _challengeIdCounter.current();

        if (task.activeChallengeId != 0) {
            Challenge storage activeChallenge = challenges[task.activeChallengeId];
            require(activeChallenge.status == ChallengeStatus.Open, "DVCN: Active challenge is not open");
            require(activeChallenge.challenger != msg.sender, "DVCN: Cannot validate if you are the challenger of the active challenge");

            activeChallenge.defenderBond += msg.value; // Add to primary defender bond
            
            challenges[newValidationId] = Challenge({ // Create a new entry for this specific validation act
                id: newValidationId,
                challengeType: ChallengeType.InferenceResult,
                entityId: _taskId,
                challenger: msg.sender, // The validator acts as a positive challenger
                reason: "Validation of Inference Result against active challenge",
                challengeBond: msg.value, // Native ETH (validation bond)
                status: ChallengeStatus.Open, // Open until the original challenge is resolved
                challengeTimestamp: block.timestamp,
                defender: task.executor,
                defenderBond: 0 // This bond is from the validator
            });
            emit InferenceResultValidated(_taskId, newValidationId, msg.sender);
            return;
        }

        // If no active challenge, this is a standalone positive validation.
        // It's recorded as a 'challenge' with a positive intent.
        challenges[newValidationId] = Challenge({
            id: newValidationId,
            challengeType: ChallengeType.InferenceResult,
            entityId: _taskId,
            challenger: msg.sender,
            reason: "Positive validation of Inference Result",
            challengeBond: msg.value, // Native ETH (validation bond)
            status: ChallengeStatus.Open, // Needs governance resolution
            challengeTimestamp: block.timestamp,
            defender: task.executor, // Executor is the implicit defender
            defenderBond: 0
        });

        emit InferenceResultValidated(_taskId, newValidationId, msg.sender);
    }


    // --- IV. Challenge Resolution & Rewards (3 functions) ---

    /// @notice Admin/Governance resolves a challenge (either knowledge or result), adjusting reputations and distributing bonds/rewards.
    /// @param _challengeId The ID of the challenge to resolve. Note: this _challengeId refers to the *initial* challenge. 
    ///         Subsequent validations also create challenge entries, but this function resolves the root dispute.
    /// @param _isChallengerCorrect True if the challenger's claim is deemed correct, false otherwise.
    function resolveChallenge(uint256 _challengeId, bool _isChallengerCorrect) public onlyOwner whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "DVCN: Challenge not found");
        require(challenge.status == ChallengeStatus.Open, "DVCN: Challenge already resolved");

        address winner;
        address loser;
        uint256 winnerReward = 0;
        uint256 loserPenalty = 0;
        int256 reputationChangeOnWin = int256(protocolParameters[REPUTATION_CHANGE_ON_WIN_PARAM]);
        int256 reputationChangeOnLoss = int256(protocolParameters[REPUTATION_CHANGE_ON_LOSS_PARAM]);

        // Determine winner and loser based on _isChallengerCorrect
        if (_isChallengerCorrect) {
            challenge.status = ChallengeStatus.ResolvedChallengerWon;
            winner = challenge.challenger;
            loser = challenge.defender;
            winnerReward = challenge.challengeBond + challenge.defenderBond; // Challenger gets their bond back + defender's bond
            loserPenalty = challenge.defenderBond;
        } else {
            challenge.status = ChallengeStatus.ResolvedChallengerLost;
            winner = challenge.defender;
            loser = challenge.challenger;
            winnerReward = challenge.defenderBond + challenge.challengeBond; // Defender gets their bond back + challenger's bond
            loserPenalty = challenge.challengeBond;
        }

        // Adjust reputation scores (only for registered agents)
        if (agents[winner].status == AgentStatus.Registered) {
            agents[winner].reputationScore += reputationChangeOnWin;
        }
        if (agents[loser].status == AgentStatus.Registered) {
            agents[loser].reputationScore -= reputationChangeOnLoss;
        }

        // Handle entity-specific updates
        if (challenge.challengeType == ChallengeType.KnowledgeFragment) {
            KnowledgeFragment storage fragment = knowledgeFragments[challenge.entityId];
            fragment.activeChallengeId = 0; // Clear active challenge on fragment
            if (_isChallengerCorrect) {
                fragment.veracityScore -= reputationChangeOnWin; // Fragment's veracity decreases if challenged successfully
            } else {
                fragment.veracityScore += reputationChangeOnWin; // Fragment's veracity increases if challenge failed
            }
        } else if (challenge.challengeType == ChallengeType.InferenceResult) {
            InferenceTask storage task = inferenceTasks[challenge.entityId];
            task.activeChallengeId = 0; // Clear active challenge on task
            if (_isChallengerCorrect) {
                task.status = InferenceTaskStatus.FailedDeadline; // Treat as failed if result was bad
            } else {
                task.status = InferenceTaskStatus.Validated; // Task is validated if challenge failed
            }
        }

        emit ChallengeResolved(
            _challengeId,
            challenge.challengeType,
            challenge.entityId,
            challenge.status,
            winner,
            loser,
            winnerReward,
            loserPenalty
        );
    }

    /// @notice The winning agent of a validated task claims their reward.
    /// Requires the task to be in `Validated` status.
    /// @param _taskId The ID of the task to claim reward for.
    function claimTaskReward(uint256 _taskId) public onlyRegisteredAgent whenNotPaused {
        InferenceTask storage task = inferenceTasks[_taskId];
        require(task.id != 0, "DVCN: Task not found");
        require(task.executor == msg.sender, "DVCN: Only executor can claim reward");
        require(task.status == InferenceTaskStatus.Validated, "DVCN: Task not yet validated");
        require(task.rewardAmount > 0, "DVCN: No reward to claim");

        uint256 reward = task.rewardAmount;
        task.rewardAmount = 0; // Prevent re-claiming

        // For simplicity, using native ETH transfer
        (bool success, ) = payable(msg.sender).call{value: reward}("");
        require(success, "DVCN: Failed to transfer task reward");

        agents[msg.sender].reputationScore += int256(protocolParameters[REPUTATION_CHANGE_ON_WIN_PARAM]);
        emit InferenceTaskRewardClaimed(_taskId, msg.sender, reward);
    }

    /// @notice The winning party (challenger or defender) of a resolved challenge claims their adjusted bond/reward.
    /// @param _challengeId The ID of the resolved challenge.
    function claimChallengeReward(uint256 _challengeId) public onlyRegisteredAgent whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.id != 0, "DVCN: Challenge not found");
        require(challenge.status == ChallengeStatus.ResolvedChallengerWon || challenge.status == ChallengeStatus.ResolvedChallengerLost, "DVCN: Challenge not yet resolved");

        uint256 amountToClaim = 0;
        address claimant = msg.sender;

        if (challenge.status == ChallengeStatus.ResolvedChallengerWon) {
            require(claimant == challenge.challenger, "DVCN: Only challenger can claim for challenger win");
            amountToClaim = challenge.challengeBond + challenge.defenderBond;
        } else { // ResolvedChallengerLost
            require(claimant == challenge.defender, "DVCN: Only defender can claim for challenger loss");
            amountToClaim = challenge.defenderBond + challenge.challengeBond;
        }

        require(amountToClaim > 0, "DVCN: No claimable amount");

        // Set bonds to 0 to prevent re-claiming
        challenge.challengeBond = 0;
        challenge.defenderBond = 0;

        // For simplicity, using native ETH transfer
        (bool success, ) = payable(claimant).call{value: amountToClaim}("");
        require(success, "DVCN: Failed to transfer challenge reward");

        emit ChallengeRewardClaimed(_challengeId, claimant, amountToClaim);
    }


    // --- V. Governance & System Parameters (4 functions) ---

    /// @notice Admin/Governance function to update various protocol settings.
    /// @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("MIN_STAKE_AMOUNT")).
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner whenNotPaused {
        require(_paramName != bytes32(0), "DVCN: Parameter name cannot be empty");
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /// @notice Admin/Governance function to pause critical contract operations (e.g., during upgrades or emergencies).
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Admin/Governance function to unpause the contract.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Admin/Governance function to set an external ZK-proof verifier contract address.
    /// @param _verifierAddress The address of the ZK-proof verifier contract.
    function setZKVerifierContract(address _verifierAddress) public onlyOwner {
        require(_verifierAddress != address(0), "DVCN: ZK verifier address cannot be zero");
        zkVerifierContract = _verifierAddress;
        emit ZKVerifierContractSet(_verifierAddress);
    }

    // --- VI. View Functions (6 functions) ---

    /// @notice Retrieves an agent's profile details.
    /// @param _agent The address of the agent.
    /// @return id The agent's ID.
    /// @return agentAddress The agent's address.
    /// @return alias The agent's public alias.
    /// @return ipfsProfileHash IPFS hash of their off-chain profile.
    /// @return stakedAmount Total staked tokens by the agent.
    /// @return reputationScore The agent's current reputation score.
    /// @return status The agent's current status (Inactive, Registered, Unbonding).
    /// @return unbondingStartTime Timestamp when unbonding started (0 if not unbonding).
    /// @return unbondingAmount Amount currently in unbonding.
    function getAgentProfile(address _agent) public view returns (
        uint256 id,
        address agentAddress,
        string memory alias,
        bytes32 ipfsProfileHash,
        uint256 stakedAmount,
        int256 reputationScore,
        AgentStatus status,
        uint256 unbondingStartTime,
        uint256 unbondingAmount
    ) {
        AgentProfile storage profile = agents[_agent];
        return (
            profile.id,
            profile.agentAddress,
            profile.alias,
            profile.ipfsProfileHash,
            profile.stakedAmount,
            profile.reputationScore,
            profile.status,
            profile.unbondingStartTime,
            profile.unbondingAmount
        );
    }

    /// @notice Retrieves details of a knowledge fragment.
    /// @param _fragmentId The ID of the knowledge fragment.
    /// @return id The fragment's ID.
    /// @return topicId The ID of the associated topic.
    /// @return provider The address of the provider.
    /// @return dataIpfsHash IPFS hash of the data.
    /// @return description Description of the fragment.
    /// @return submissionTimestamp Timestamp of submission.
    /// @return veracityScore Current veracity score.
    /// @return activeChallengeId ID of active challenge (0 if none).
    function getKnowledgeFragment(uint256 _fragmentId) public view returns (
        uint256 id,
        uint256 topicId,
        address provider,
        bytes32 dataIpfsHash,
        string memory description,
        uint256 submissionTimestamp,
        int256 veracityScore,
        uint256 activeChallengeId
    ) {
        KnowledgeFragment storage fragment = knowledgeFragments[_fragmentId];
        return (
            fragment.id,
            fragment.topicId,
            fragment.provider,
            fragment.dataIpfsHash,
            fragment.description,
            fragment.submissionTimestamp,
            fragment.veracityScore,
            fragment.activeChallengeId
        );
    }

    /// @notice Retrieves details of an inference model.
    /// @param _modelId The ID of the inference model.
    /// @return id The model's ID.
    /// @return owner The owner's address.
    /// @return name The model's name.
    /// @return codeIpfsHash IPFS hash of the code.
    /// @return parametersJson JSON string of parameters.
    /// @return submissionTimestamp Timestamp of submission.
    function getInferenceModel(uint256 _modelId) public view returns (
        uint256 id,
        address owner,
        string memory name,
        bytes32 codeIpfsHash,
        string memory parametersJson,
        uint256 submissionTimestamp
    ) {
        InferenceModel storage model = inferenceModels[_modelId];
        return (
            model.id,
            model.owner,
            model.name,
            model.codeIpfsHash,
            model.parametersJson,
            model.submissionTimestamp
        );
    }

    /// @notice Retrieves details of an inference task.
    /// @param _taskId The ID of the inference task.
    /// @return id The task's ID.
    /// @return modelId The associated model ID.
    /// @return requester The requester's address.
    /// @return executor The executor's address (0 if not accepted).
    /// @return fragmentIds Input knowledge fragment IDs.
    /// @return rewardAmount Reward offered.
    /// @return deadline Submission deadline.
    /// @return resultIpfsHash IPFS hash of the result.
    /// @return status Current task status.
    /// @return submissionTimestamp Timestamp of result submission.
    /// @return activeChallengeId ID of active challenge (0 if none).
    function getInferenceTask(uint256 _taskId) public view returns (
        uint256 id,
        uint256 modelId,
        address requester,
        address executor,
        uint256[] memory fragmentIds,
        uint256 rewardAmount,
        uint256 deadline,
        bytes32 resultIpfsHash,
        InferenceTaskStatus status,
        uint256 submissionTimestamp,
        uint256 activeChallengeId
    ) {
        InferenceTask storage task = inferenceTasks[_taskId];
        return (
            task.id,
            task.modelId,
            task.requester,
            task.executor,
            task.fragmentIds,
            task.rewardAmount,
            task.deadline,
            task.resultIpfsHash,
            task.status,
            task.submissionTimestamp,
            task.activeChallengeId
        );
    }
    
    /// @notice Retrieves details of a challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return id The challenge's ID.
    /// @return challengeType Type of entity challenged (KnowledgeFragment or InferenceResult).
    /// @return entityId ID of the challenged entity.
    /// @return challenger Address of the challenger.
    /// @return reason Reason for the challenge.
    /// @return challengeBond Tokens staked by challenger.
    /// @return status Current challenge status.
    /// @return challengeTimestamp Timestamp of challenge.
    /// @return defender Address of the defender.
    /// @return defenderBond Tokens staked by defender.
    function getChallenge(uint256 _challengeId) public view returns (
        uint256 id,
        ChallengeType challengeType,
        uint256 entityId,
        address challenger,
        string memory reason,
        uint256 challengeBond,
        ChallengeStatus status,
        uint256 challengeTimestamp,
        address defender,
        uint256 defenderBond
    ) {
        Challenge storage challenge = challenges[_challengeId];
        return (
            challenge.id,
            challenge.challengeType,
            challenge.entityId,
            challenge.challenger,
            challenge.reason,
            challenge.challengeBond,
            challenge.status,
            challenge.challengeTimestamp,
            challenge.defender,
            challenge.defenderBond
        );
    }

    /// @notice Retrieves details of a topic.
    /// @param _topicId The ID of the topic.
    /// @return id The topic's ID.
    /// @return name The topic's name.
    /// @return description Description of the topic.
    /// @return isApproved Whether the topic is approved by governance.
    /// @return proposer The address of the topic proposer.
    /// @return proposalTimestamp Timestamp of proposal.
    function getTopic(uint256 _topicId) public view returns (
        uint256 id,
        string memory name,
        string memory description,
        bool isApproved,
        address proposer,
        uint256 proposalTimestamp
    ) {
        Topic storage topic = topics[_topicId];
        return (
            topic.id,
            topic.name,
            topic.description,
            topic.isApproved,
            topic.proposer,
            topic.proposalTimestamp
        );
    }
}
```