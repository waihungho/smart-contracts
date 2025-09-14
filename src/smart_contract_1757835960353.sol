This smart contract, `DecentralizedAetherMind` (DAM), introduces a novel framework for decentralized AI inference, content curation, and prediction markets. It features "Knowledge Agent NFTs" (KANs) – dynamic ERC721 tokens that embody an AI agent's identity and reputation. KANs participate in tasks by submitting AI-driven inferences, engaging in a multi-stage resolution process (direct submission, challenges, community voting, and optional oracle override), and earning rewards based on their accuracy. Their "Knowledge Score," a dynamic trait, evolves with performance, making them valuable, self-improving digital assets.

---

**Solidity Smart Contract: DecentralizedAetherMind (DAM)**

**Outline and Function Summary:**

**I. Core Infrastructure & Access Control:**
    1.  `constructor()`: Initializes the protocol's ERC20 token (`AetherToken`), sets the deployer as the owner, and establishes initial protocol parameters.
    2.  `updateProtocolParameters(bytes32 paramName, uint256 value)`: Allows the owner to adjust critical system configurations (e.g., minimum staking requirements, reward percentages, time windows).
    3.  `pauseSystem()`: Enables the owner to temporarily halt core contract functionalities in case of emergencies or upgrades.
    4.  `unpauseSystem()`: Resumes operations after the system has been paused.
    5.  `setVerificationProofVerifier(address newVerifier)`: Designates an external contract responsible for verifying cryptographic proofs (e.g., Zero-Knowledge Proofs) submitted with AI inference results.

**II. Knowledge Agent NFT (KAN) Management (ERC721 Tokens):**
    6.  `mintKnowledgeAgent(string memory name, string memory initialMetadataURI)`: Mints a new KAN (an ERC721 token) to the caller. This requires an initial `AetherToken` deposit, which is then staked to the agent, activating it for task participation.
    7.  `updateAgentMetadata(uint256 tokenId, string memory newMetadataURI)`: Allows the KAN owner to modify the associated metadata URI, reflecting potential agent upgrades or identity changes.
    8.  `stakeToAgent(uint256 tokenId, uint256 amount)`: Increases the amount of `AetherToken` staked to a specific KAN, enhancing its eligibility for more significant tasks and demonstrating commitment.
    9.  `requestUnstakeFromAgent(uint256 tokenId, uint256 amount)`: Initiates a request to unstake tokens from a KAN. The requested amount is locked for a predefined cooldown period to ensure protocol stability.
    10. `finalizeUnstake(uint256 tokenId)`: Completes an unstaking request for a KAN after its cooldown period has passed, transferring the specified tokens back to the KAN owner.
    11. `delegateAgentOperations(uint256 tokenId, address delegatee, bool allow)`: Empowers a KAN owner to delegate task claiming and result submission rights to another address without transferring the NFT itself.

**III. Task Lifecycle Management (AI Inference & Curation):**
    12. `proposeInferenceTask(bytes32 dataHash, string memory descriptionURI, TaskType taskType, uint256 rewardPool, uint256 requiredAgentStake, uint256 submissionWindow, uint256 challengeWindow)`: Enables users to propose new AI inference tasks, specifying the data to be analyzed (e.g., via IPFS hash), task type, an initial reward pool, and relevant time windows.
    13. `claimTaskAndSubmitResult(uint256 taskId, uint256 agentId, bytes32 resultHash, bytes memory verifiableProof)`: A staked KAN claims an available task, locks its required stake, and submits its AI inference result along with an optional verifiable proof of computation (e.g., ZK-proof ID, oracle signature).
    14. `challengeInferenceResult(uint256 taskId, uint256 challengerAgentId, bytes32 counterResultHash, bytes memory verifiableProof, uint256 challengeStake)`: Any KAN can challenge a previously submitted result by proposing an alternative outcome, staking tokens, and providing supporting proof.
    15. `voteOnChallengedResult(uint256 taskId, uint256 voterAgentId, bytes32 preferredResultHash)`: During the challenge period, other KANs can vote on which of the competing results (original or challenged) they believe is correct, participating in a Schelling point game for decentralized consensus.
    16. `resolveTaskTruthByOracle(uint256 taskId, bytes32 finalTruthHash, bytes memory oracleSignature)`: A designated and trusted oracle (currently `onlyOwner` for simplicity) can provide the definitive truth for tasks that cannot be resolved by community consensus or require external, verifiable data. Callable only after the challenge window closes.
    17. `finalizeTaskAndDistributeRewards(uint256 taskId)`: Once a task is resolved (either by voting or oracle), this function distributes rewards and applies penalties to KANs based on their accuracy, and updates their Knowledge Scores.

**IV. Reputation & Dynamic NFT Attributes:**
    18. `getAgentKnowledgeScore(uint256 tokenId)`: Retrieves the current Knowledge Score of a specific KAN, which is a dynamic attribute reflecting its historical accuracy and reliability.
    19. `getAgentPerformanceMetrics(uint256 tokenId)`: Provides detailed performance statistics for a KAN, including total staked tokens, knowledge score, tasks completed, correct/incorrect submissions, and win rate.

**V. Token & Treasury Management:**
    20. `depositFunds(uint256 amount)`: Allows users to deposit `AetherToken` into the contract, which can be used to fund tasks or stake KANs.
    21. `withdrawProtocolFees(address recipient)`: Allows the protocol owner to withdraw accumulated protocol fees (e.g., task creation fees, incorrect challenge stakes) to a specified address.
    22. `registerExternalAIModel(bytes32 modelId, string memory modelDescriptionURI)`: Enables the protocol owner to register recognized off-chain AI models. These registered IDs can then be referenced in verifiable proofs for enhanced transparency and trust.
    23. `getAvailableFunds()`: A view function that returns the total `AetherToken` balance currently held by the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Outline and Function Summary ---
// This smart contract, 'DecentralizedAetherMind' (DAM), is a novel protocol for decentralized AI inference,
// content curation, and prediction markets. It leverages dynamic NFTs called "Knowledge Agents" (KANs)
// which participate in tasks, submit AI-driven inferences, and earn rewards based on their accuracy.
// The system incorporates a multi-stage resolution mechanism involving direct submissions, challenges,
// community voting (Schelling point game), and an optional oracle for final truth resolution.
// KANs gain a dynamic "Knowledge Score" reflecting their historical performance, making them
// valuable digital assets that evolve with their computational accuracy.

// I. Core Infrastructure & Access Control:
//    1.  constructor(): Initializes the protocol token, deployer as owner, and initial parameters.
//    2.  updateProtocolParameters(bytes32 paramName, uint256 value): Allows the owner to adjust
//        various system parameters like staking minimums, reward percentages, window durations, etc.
//    3.  pauseSystem(): Allows the owner to pause critical functionalities in emergencies.
//    4.  unpauseSystem(): Allows the owner to unpause critical functionalities.
//    5.  setVerificationProofVerifier(address newVerifier): Sets an external contract address
//        responsible for validating ZK-proofs or other verifiable computation attestations.

// II. Knowledge Agent NFT (KAN) Management (ERC721 Tokens):
//    6.  mintKnowledgeAgent(string memory name, string memory initialMetadataURI): Mints a new KAN
//        to the caller, requiring an initial token deposit to activate it for task participation.
//    7.  updateAgentMetadata(uint256 tokenId, string memory newMetadataURI): KAN owner can update
//        the associated metadata URI, reflecting potential upgrades or identity changes.
//    8.  stakeToAgent(uint256 tokenId, uint256 amount): Increases the token stake associated with a KAN,
//        enhancing its eligibility for higher-value tasks and proving commitment.
//    9.  requestUnstakeFromAgent(uint256 tokenId, uint256 amount): Initiates an unstaking request for a KAN.
//        Funds are locked during a predefined cooldown period to prevent flash loan attacks or rapid exit.
//    10. finalizeUnstake(uint256 tokenId): Completes an unstaking request after the cooldown period,
//        transferring the specified tokens back to the KAN owner.
//    11. delegateAgentOperations(uint256 tokenId, address delegatee, bool allow): Allows a KAN owner
//        to delegate the rights to claim tasks and submit results to another address without transferring the NFT.

// III. Task Lifecycle Management (AI Inference & Curation):
//    12. proposeInferenceTask(bytes32 dataHash, string memory descriptionURI, TaskType taskType,
//        uint256 rewardPool, uint256 requiredAgentStake, uint256 submissionWindow, uint256 challengeWindow):
//        Users propose a new AI inference task, defining its parameters, associated data, and initial reward.
//    13. claimTaskAndSubmitResult(uint256 taskId, uint256 agentId, bytes32 resultHash, bytes memory verifiableProof):
//        A staked KAN claims an available task, locks its required stake, and submits its AI inference result
//        along with an optional verifiable proof of computation (e.g., ZK-proof ID or Oracle signature).
//    14. challengeInferenceResult(uint256 taskId, uint256 challengerAgentId, bytes32 counterResultHash,
//        bytes memory verifiableProof, uint256 challengeStake): Any KAN can challenge a submitted result
//        by proposing an alternative outcome, staking tokens, and providing a proof.
//    15. voteOnChallengedResult(uint256 taskId, uint256 voterAgentId, bytes32 preferredResultHash): During the challenge period,
//        other KANs can vote on which result (original or challenged) they believe is correct, forming a
//        decentralized consensus mechanism.
//    16. resolveTaskTruthByOracle(uint256 taskId, bytes32 finalTruthHash, bytes memory oracleSignature):
//        A designated and trusted oracle can provide the definitive truth for tasks that cannot be
//        resolved by community consensus or require external, verifiable data. Only callable after challenge window.
//    17. finalizeTaskAndDistributeRewards(uint256 taskId): After a task is resolved (by voting or oracle),
//        this function distributes rewards and penalties to KANs based on their accuracy, and updates their
//        Knowledge Scores and total staked amounts.

// IV. Reputation & Dynamic NFT Attributes:
//    18. getAgentKnowledgeScore(uint256 tokenId): Returns the current Knowledge Score of a KAN,
//        a dynamic trait reflecting its historical accuracy and reliability.
//    19. getAgentPerformanceMetrics(uint256 tokenId): Provides more detailed performance data
//        for a KAN, including tasks completed, correct/incorrect submissions, and win rate.

// V. Token & Treasury Management:
//    20. depositFunds(uint256 amount): Allows users to deposit AetherTokens into the contract
//        to fund tasks, stake KANs, or contribute to the protocol's liquidity.
//    21. withdrawProtocolFees(address recipient): Allows the protocol owner/governance to withdraw
//        accumulated protocol fees to a specified address.
//    22. registerExternalAIModel(bytes32 modelId, string memory modelDescriptionURI): Allows the protocol
//        owner to register recognized off-chain AI models, whose IDs can be referenced in verifiable proofs
//        for enhanced trust and transparency.
//    23. getAvailableFunds(): A view function to check the total AetherToken balance held by the contract.

contract DecentralizedAetherMind is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public immutable AetherToken; // The utility and governance token

    Counters.Counter private _kanIdCounter;
    Counters.Counter private _taskIdCounter;

    // --- Data Structures ---

    enum TaskType { SentimentAnalysis, ImageClassification, PredictionMarket, GenerativeEvaluation }
    enum TaskStatus { Proposed, Claimed, Challenged, Resolved, Finalized }
    enum ResolutionMethod { ConsensusVote, OracleTruth }

    struct KnowledgeAgent {
        uint256 id;
        address owner;
        string name;
        uint256 totalStaked; // Tokens actively staked to this agent
        uint256 knowledgeScore; // A dynamic score reflecting accuracy (e.g., starts at 1000, increases/decreases)
        uint256 tasksCompleted;
        uint256 correctSubmissions;
        uint256 incorrectSubmissions;
    }

    struct InferenceTask {
        uint256 id;
        address proposer;
        bytes32 dataHash; // Hash of the content/data to be analyzed (e.g., IPFS CID)
        string descriptionURI; // URI pointing to a detailed description of the task
        TaskType taskType;
        TaskStatus status;
        uint256 rewardPool; // AetherTokens allocated for this task (excluding creation fee)
        uint256 requiredAgentStake; // Min stake KAN needs to claim/challenge this task
        uint256 submissionWindowEnd; // Timestamp when submission window closes
        uint256 challengeWindowEnd; // Timestamp when challenge window closes
        uint256 resolutionTime; // Timestamp when task was resolved

        uint256 claimedByAgentId;
        bytes32 claimedResultHash;
        bytes claimedVerifiableProof; // Proof of computation (e.g., ZK-proof ID, oracle signature)

        uint256 challengerAgentId; // KAN ID of the challenger
        bytes32 challengerResultHash;
        bytes challengerVerifiableProof; // Proof provided by challenger
        uint252 challengeStake; // Stake placed by the challenger

        bytes32 finalTruthHash;
        ResolutionMethod resolutionMethod;
        mapping(uint256 => bytes32) votes; // agentId => preferredResultHash
        mapping(bytes32 => uint256) resultVoteCounts; // resultHash => count
    }

    struct UnstakeRequest {
        uint256 amount;
        uint64 withdrawableAt;
    }

    // --- State Variables ---
    mapping(uint256 => KnowledgeAgent) public knowledgeAgents; // tokenId => KnowledgeAgent
    mapping(uint256 => InferenceTask) public inferenceTasks; // taskId => InferenceTask
    mapping(uint256 => UnstakeRequest) public pendingUnstakeRequests; // tokenId => UnstakeRequest (only one request per agent)
    mapping(uint256 => mapping(address => bool)) public delegatedAgentOperators; // agentId => operatorAddress => bool

    // Protocol parameters (adjustable by owner)
    mapping(bytes32 => uint256) public protocolParameters;

    bytes32 public constant PARAM_MIN_AGENT_STAKE = keccak256("MIN_AGENT_STAKE");
    bytes32 public constant PARAM_UNSTAKE_COOLDOWN = keccak256("UNSTAKE_COOLDOWN");
    bytes32 public constant PARAM_TASK_CREATION_FEE = keccak256("TASK_CREATION_FEE");
    bytes32 public constant PARAM_PROTOCOL_FEE_PERCENT = keccak256("PROTOCOL_FEE_PERCENT"); // in basis points (e.g., 100 for 1%)
    bytes32 public constant PARAM_KAN_MINT_DEPOSIT = keccak256("KAN_MINT_DEPOSIT");
    bytes32 public constant PARAM_MIN_CHALLENGE_STAKE = keccak256("MIN_CHALLENGE_STAKE");
    bytes32 public constant PARAM_AGENT_INITIAL_K_SCORE = keccak256("AGENT_INITIAL_K_SCORE");
    bytes32 public constant PARAM_K_SCORE_CORRECT_SUBMISSION_GAIN = keccak256("K_SCORE_CORRECT_SUBMISSION_GAIN");
    bytes32 public constant PARAM_K_SCORE_INCORRECT_SUBMISSION_LOSS = keccak256("K_SCORE_INCORRECT_SUBMISSION_LOSS");
    bytes32 public constant PARAM_K_SCORE_CORRECT_CHALLENGE_GAIN = keccak256("K_SCORE_CORRECT_CHALLENGE_GAIN");
    bytes32 public constant PARAM_K_SCORE_INCORRECT_CHALLENGE_LOSS = keccak256("K_SCORE_INCORRECT_CHALLENGE_LOSS");
    bytes32 public constant PARAM_K_SCORE_CORRECT_VOTE_GAIN = keccak256("K_SCORE_CORRECT_VOTE_GAIN");

    address public feeRecipient;
    address public verificationProofVerifier; // Address of a contract that verifies ZK proofs or other attestations

    // Tracks accumulated protocol fees, which can be withdrawn by the owner.
    uint256 public protocolFeeBalance;

    // Registered AI models for transparency
    mapping(bytes32 => string) public registeredAIModels; // modelId => descriptionURI

    bool public paused = false;

    // --- Events ---
    event KnowledgeAgentMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 initialStake);
    event AgentMetadataUpdated(uint256 indexed tokenId, string newURI);
    event AgentStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event UnstakeRequested(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 withdrawableAt);
    event UnstakeFinalized(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event AgentOperationDelegated(uint256 indexed tokenId, address indexed delegatee, bool allowed);

    event InferenceTaskProposed(uint256 indexed taskId, address indexed proposer, TaskType taskType, uint256 rewardPool);
    event TaskClaimedAndResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, bytes32 resultHash, bytes verifiableProof);
    event InferenceResultChallenged(uint256 indexed taskId, uint256 indexed challengerAgentId, bytes32 counterResultHash, uint256 challengeStake);
    event ResultVoted(uint256 indexed taskId, uint256 indexed voterAgentId, bytes32 preferredResultHash);
    event TaskResolvedByOracle(uint256 indexed taskId, bytes32 finalTruthHash);
    event TaskFinalized(uint256 indexed taskId, bytes32 finalTruthHash, uint256 totalRewardsDistributed);
    event KnowledgeScoreUpdated(uint256 indexed agentId, uint256 newScore, int256 scoreChange);

    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event VerificationProofVerifierSet(address indexed newVerifier);
    event ExternalAIModelRegistered(bytes32 indexed modelId, string descriptionURI);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier onlyAgentOwnerOrDelegate(uint256 _tokenId) {
        require(_exists(_tokenId), "KAN: Nonexistent token");
        require(
            ownerOf(_tokenId) == _msgSender() || delegatedAgentOperators[_tokenId][_msgSender()],
            "KAN: Not owner or delegate"
        );
        _;
    }

    // --- Constructor ---
    constructor(address _aetherTokenAddress) ERC721("KnowledgeAgentNFT", "KAN") {
        AetherToken = IERC20(_aetherTokenAddress);
        feeRecipient = msg.sender; // Initial fee recipient is deployer
        _transferOwnership(msg.sender); // Set deployer as owner

        // Set initial protocol parameters
        protocolParameters[PARAM_MIN_AGENT_STAKE] = 1000 * 10 ** 18; // 1000 AetherToken
        protocolParameters[PARAM_UNSTAKE_COOLDOWN] = 7 days;
        protocolParameters[PARAM_TASK_CREATION_FEE] = 50 * 10 ** 18; // 50 AetherToken
        protocolParameters[PARAM_PROTOCOL_FEE_PERCENT] = 500; // 5% (500 basis points)
        protocolParameters[PARAM_KAN_MINT_DEPOSIT] = 500 * 10 ** 18; // 500 AetherToken initial stake
        protocolParameters[PARAM_MIN_CHALLENGE_STAKE] = 100 * 10 ** 18; // 100 AetherToken
        protocolParameters[PARAM_AGENT_INITIAL_K_SCORE] = 1000; // Initial score of 1000
        protocolParameters[PARAM_K_SCORE_CORRECT_SUBMISSION_GAIN] = 10;
        protocolParameters[PARAM_K_SCORE_INCORRECT_SUBMISSION_LOSS] = 5;
        protocolParameters[PARAM_K_SCORE_CORRECT_CHALLENGE_GAIN] = 15;
        protocolParameters[PARAM_K_SCORE_INCORRECT_CHALLENGE_LOSS] = 10;
        protocolParameters[PARAM_K_SCORE_CORRECT_VOTE_GAIN] = 1;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Allows the owner to adjust various system parameters.
     * @param paramName The keccak256 hash of the parameter name (e.g., PARAM_MIN_AGENT_STAKE).
     * @param value The new value for the parameter.
     */
    function updateProtocolParameters(bytes32 paramName, uint256 value) public onlyOwner {
        protocolParameters[paramName] = value;
        emit ProtocolParameterUpdated(paramName, value);
    }

    /**
     * @notice Allows the owner to pause critical functionalities in emergencies.
     */
    function pauseSystem() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Allows the owner to unpause critical functionalities.
     */
    function unpauseSystem() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Sets the address of an external contract responsible for verifying proofs.
     * @param newVerifier The address of the new verifier contract.
     */
    function setVerificationProofVerifier(address newVerifier) public onlyOwner {
        require(newVerifier != address(0), "DAM: Verifier cannot be zero address");
        verificationProofVerifier = newVerifier;
        emit VerificationProofVerifierSet(newVerifier);
    }

    // --- II. Knowledge Agent NFT (KAN) Management ---

    /**
     * @notice Mints a new Knowledge Agent NFT (KAN) to the caller.
     * Requires an initial AetherToken deposit which is staked to the agent.
     * @param name The name of the KAN.
     * @param initialMetadataURI The initial metadata URI for the KAN.
     */
    function mintKnowledgeAgent(string memory name, string memory initialMetadataURI) public nonReentrant whenNotPaused {
        uint256 mintDeposit = protocolParameters[PARAM_KAN_MINT_DEPOSIT];
        require(mintDeposit > 0, "DAM: Mint deposit must be set");

        _kanIdCounter.increment();
        uint256 newId = _kanIdCounter.current();

        // Transfer initial stake from minter to contract
        require(AetherToken.transferFrom(_msgSender(), address(this), mintDeposit), "DAM: Token transfer failed for mint deposit");

        _safeMint(_msgSender(), newId);
        _setTokenURI(newId, initialMetadataURI);

        KnowledgeAgent storage newAgent = knowledgeAgents[newId];
        newAgent.id = newId;
        newAgent.owner = _msgSender();
        newAgent.name = name;
        newAgent.totalStaked = mintDeposit;
        newAgent.knowledgeScore = protocolParameters[PARAM_AGENT_INITIAL_K_SCORE];

        emit KnowledgeAgentMinted(newId, _msgSender(), name, mintDeposit);
        emit AgentStaked(newId, _msgSender(), mintDeposit);
    }

    /**
     * @notice Allows the KAN owner to update the associated metadata URI.
     * @param tokenId The ID of the KAN.
     * @param newMetadataURI The new metadata URI.
     */
    function updateAgentMetadata(uint256 tokenId, string memory newMetadataURI) public onlyAgentOwner(tokenId) {
        _setTokenURI(tokenId, newMetadataURI);
        emit AgentMetadataUpdated(tokenId, newMetadataURI);
    }

    /**
     * @notice Increases the token stake associated with a KAN.
     * @param tokenId The ID of the KAN.
     * @param amount The amount of AetherToken to stake.
     */
    function stakeToAgent(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "KAN: Nonexistent token");
        require(amount > 0, "DAM: Stake amount must be positive");
        require(ownerOf(tokenId) == _msgSender(), "KAN: Not owner of agent");

        require(AetherToken.transferFrom(_msgSender(), address(this), amount), "DAM: Token transfer failed for stake");

        knowledgeAgents[tokenId].totalStaked += amount;
        emit AgentStaked(tokenId, _msgSender(), amount);
    }

    /**
     * @notice Initiates an unstaking request for a KAN. Funds are locked during a cooldown period.
     * An agent can only have one pending unstake request at a time.
     * @param tokenId The ID of the KAN.
     * @param amount The amount to unstake.
     */
    function requestUnstakeFromAgent(uint256 tokenId, uint256 amount) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "KAN: Nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "KAN: Not owner of agent");
        require(amount > 0, "DAM: Unstake amount must be positive");
        require(pendingUnstakeRequests[tokenId].amount == 0, "DAM: Agent already has a pending unstake request"); // Only one request at a time

        KnowledgeAgent storage agent = knowledgeAgents[tokenId];
        uint256 minStake = protocolParameters[PARAM_MIN_AGENT_STAKE];
        
        require(agent.totalStaked >= amount, "DAM: Insufficient staked funds");
        require(agent.totalStaked - amount >= minStake, "DAM: Remaining stake too low after unstake request");

        uint256 cooldown = protocolParameters[PARAM_UNSTAKE_COOLDOWN];
        uint64 withdrawableAt = uint64(block.timestamp + cooldown);

        pendingUnstakeRequests[tokenId] = UnstakeRequest(amount, withdrawableAt);
        agent.totalStaked -= amount; // Deduct immediately from totalStaked
        
        emit UnstakeRequested(tokenId, _msgSender(), amount, withdrawableAt);
    }

    /**
     * @notice Completes an unstaking request after the cooldown period, transferring tokens back.
     * @param tokenId The ID of the KAN.
     */
    function finalizeUnstake(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "KAN: Nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "KAN: Not owner of agent");

        UnstakeRequest storage request = pendingUnstakeRequests[tokenId];
        require(request.amount > 0, "DAM: No pending unstake request for this agent");
        require(block.timestamp >= request.withdrawableAt, "DAM: Unstake cooldown period not over");
        
        uint256 amountToWithdraw = request.amount;
        delete pendingUnstakeRequests[tokenId]; // Clear the request

        require(AetherToken.transfer(_msgSender(), amountToWithdraw), "DAM: Token transfer failed for unstake");
        emit UnstakeFinalized(tokenId, _msgSender(), amountToWithdraw);
    }

    /**
     * @notice Allows a KAN owner to delegate the rights to claim tasks and submit results to another address.
     * @param tokenId The ID of the KAN.
     * @param delegatee The address to delegate operations to.
     * @param allow True to allow, false to disallow.
     */
    function delegateAgentOperations(uint256 tokenId, address delegatee, bool allow) public onlyAgentOwner(tokenId) {
        require(delegatee != address(0), "DAM: Delegatee cannot be zero address");
        delegatedAgentOperators[tokenId][delegatee] = allow;
        emit AgentOperationDelegated(tokenId, delegatee, allow);
    }

    // --- III. Task Lifecycle Management (AI Inference & Curation) ---

    /**
     * @notice Proposes a new AI inference task.
     * Requires a fee for task creation and an initial reward pool deposit.
     * @param dataHash Hash of the content/data to be analyzed (e.g., IPFS CID).
     * @param descriptionURI URI pointing to a detailed description of the task.
     * @param taskType The type of AI inference task.
     * @param rewardPool The total AetherTokens allocated as reward for this task.
     * @param requiredAgentStake The minimum stake a KAN needs to claim/challenge this task.
     * @param submissionWindow Duration for result submission from task creation.
     * @param challengeWindow Duration for challenges after submission window closes.
     */
    function proposeInferenceTask(
        bytes32 dataHash,
        string memory descriptionURI,
        TaskType taskType,
        uint256 rewardPool,
        uint256 requiredAgentStake,
        uint256 submissionWindow, // in seconds
        uint256 challengeWindow // in seconds
    ) public nonReentrant whenNotPaused {
        uint256 taskCreationFee = protocolParameters[PARAM_TASK_CREATION_FEE];
        require(taskCreationFee > 0, "DAM: Task creation fee must be set");
        require(rewardPool > 0, "DAM: Reward pool must be positive");
        require(requiredAgentStake >= protocolParameters[PARAM_MIN_AGENT_STAKE], "DAM: Required agent stake too low");
        require(submissionWindow > 0 && challengeWindow > 0, "DAM: Windows must be positive");

        uint256 totalFunds = taskCreationFee + rewardPool;
        require(AetherToken.transferFrom(_msgSender(), address(this), totalFunds), "DAM: Token transfer failed for task proposal");

        protocolFeeBalance += taskCreationFee; // Add task creation fee to protocol fees

        _taskIdCounter.increment();
        uint256 newId = _taskIdCounter.current();

        InferenceTask storage newTask = inferenceTasks[newId];
        newTask.id = newId;
        newTask.proposer = _msgSender();
        newTask.dataHash = dataHash;
        newTask.descriptionURI = descriptionURI;
        newTask.taskType = taskType;
        newTask.status = TaskStatus.Proposed;
        newTask.rewardPool = rewardPool; // This is the net reward pool after fees
        newTask.requiredAgentStake = requiredAgentStake;
        newTask.submissionWindowEnd = block.timestamp + submissionWindow;
        newTask.challengeWindowEnd = newTask.submissionWindowEnd + challengeWindow;

        emit InferenceTaskProposed(newId, _msgSender(), taskType, rewardPool);
    }

    /**
     * @notice A staked KAN claims an available task, locking its required stake, and submits its AI inference result.
     * @param taskId The ID of the task.
     * @param agentId The ID of the KAN claiming and submitting.
     * @param resultHash Hash of the inference result (e.g., IPFS CID of the actual result, or a simple value hash).
     * @param verifiableProof Optional proof of computation (e.g., ZK-proof ID, oracle signature attesting to model run).
     */
    function claimTaskAndSubmitResult(
        uint256 taskId,
        uint256 agentId,
        bytes32 resultHash,
        bytes memory verifiableProof
    ) public nonReentrant whenNotPaused onlyAgentOwnerOrDelegate(agentId) {
        InferenceTask storage task = inferenceTasks[taskId];
        require(task.id == taskId, "DAM: Task does not exist");
        require(task.status == TaskStatus.Proposed, "DAM: Task not in proposed state");
        require(block.timestamp <= task.submissionWindowEnd, "DAM: Submission window closed");

        KnowledgeAgent storage agent = knowledgeAgents[agentId];
        require(agent.totalStaked >= task.requiredAgentStake, "DAM: Agent lacks required stake");

        task.claimedByAgentId = agentId;
        task.claimedResultHash = resultHash;
        task.claimedVerifiableProof = verifiableProof;
        task.status = TaskStatus.Claimed;

        emit TaskClaimedAndResultSubmitted(taskId, agentId, resultHash, verifiableProof);
    }

    /**
     * @notice Any KAN can challenge a submitted result by proposing an alternative outcome, staking tokens, and providing a proof.
     * @param taskId The ID of the task.
     * @param challengerAgentId The ID of the KAN challenging the result.
     * @param counterResultHash The hash of the challenger's proposed result.
     * @param verifiableProof Optional proof of computation for the challenger's result.
     * @param challengeStake The amount of AetherToken to stake for the challenge.
     */
    function challengeInferenceResult(
        uint256 taskId,
        uint256 challengerAgentId,
        bytes32 counterResultHash,
        bytes memory verifiableProof,
        uint256 challengeStake
    ) public nonReentrant whenNotPaused onlyAgentOwnerOrDelegate(challengerAgentId) {
        InferenceTask storage task = inferenceTasks[taskId];
        require(task.id == taskId, "DAM: Task does not exist");
        require(task.status == TaskStatus.Claimed, "DAM: Task not in claimed state");
        require(block.timestamp > task.submissionWindowEnd, "DAM: Challenge window not yet open");
        require(block.timestamp <= task.challengeWindowEnd, "DAM: Challenge window closed");
        require(task.claimedByAgentId != 0, "DAM: No result submitted to challenge");
        require(challengerAgentId != task.claimedByAgentId, "DAM: Cannot challenge own result");
        require(counterResultHash != task.claimedResultHash, "DAM: Challenger must propose different result");

        KnowledgeAgent storage challengerAgent = knowledgeAgents[challengerAgentId];
        require(challengerAgent.totalStaked >= task.requiredAgentStake, "DAM: Challenger agent lacks required stake");
        require(challengeStake >= protocolParameters[PARAM_MIN_CHALLENGE_STAKE], "DAM: Challenge stake too low");

        // Transfer challenge stake from challenger to contract
        require(AetherToken.transferFrom(_msgSender(), address(this), challengeStake), "DAM: Token transfer failed for challenge stake");

        task.challengerAgentId = challengerAgentId;
        task.challengerResultHash = counterResultHash;
        task.challengerVerifiableProof = verifiableProof;
        task.challengeStake = challengeStake;
        task.status = TaskStatus.Challenged;

        emit InferenceResultChallenged(taskId, challengerAgentId, counterResultHash, challengeStake);
    }

    /**
     * @notice During the challenge period, other KANs can vote on which result they believe is correct.
     * This forms a Schelling point game where KANs align with the perceived truth.
     * @param taskId The ID of the task.
     * @param voterAgentId The ID of the KAN casting the vote.
     * @param preferredResultHash The hash of the result the agent believes to be correct (original or challenged).
     */
    function voteOnChallengedResult(uint256 taskId, uint256 voterAgentId, bytes32 preferredResultHash) public nonReentrant whenNotPaused onlyAgentOwnerOrDelegate(voterAgentId) {
        InferenceTask storage task = inferenceTasks[taskId];
        require(task.id == taskId, "DAM: Task does not exist");
        require(task.status == TaskStatus.Challenged, "DAM: Task not in challenged state");
        require(block.timestamp > task.submissionWindowEnd, "DAM: Voting window not yet open");
        require(block.timestamp <= task.challengeWindowEnd, "DAM: Voting window closed");
        require(preferredResultHash == task.claimedResultHash || preferredResultHash == task.challengerResultHash, "DAM: Invalid result hash to vote for");

        require(task.claimedByAgentId != voterAgentId && task.challengerAgentId != voterAgentId, "DAM: Participating agents cannot vote");
        require(task.votes[voterAgentId] == bytes32(0), "DAM: Agent already voted for this task");

        task.votes[voterAgentId] = preferredResultHash;
        task.resultVoteCounts[preferredResultHash]++;

        emit ResultVoted(taskId, voterAgentId, preferredResultHash);
    }

    /**
     * @notice A designated oracle can provide the definitive truth for tasks that cannot be resolved via consensus.
     * Only callable after the challenge window ends.
     * @param taskId The ID of the task.
     * @param finalTruthHash The definitive hash of the correct result.
     * @param oracleSignature Signature from a trusted oracle attesting to the truth. (Simplified: just owner for now).
     */
    function resolveTaskTruthByOracle(uint256 taskId, bytes32 finalTruthHash, bytes memory oracleSignature) public onlyOwner nonReentrant whenNotPaused {
        // NOTE: In a real advanced system, this would involve a complex oracle network
        // (e.g., Chainlink, or a decentralized committee) and cryptographic verification of the signature.
        // For this example, we simplify by allowing the contract owner to act as the ultimate oracle.
        // The `oracleSignature` field is a placeholder for future complex verification via `verificationProofVerifier`.
        require(verificationProofVerifier != address(0), "DAM: Oracle resolution requires a verifier set");
        InferenceTask storage task = inferenceTasks[taskId];
        require(task.id == taskId, "DAM: Task does not exist");
        require(task.status == TaskStatus.Claimed || task.status == TaskStatus.Challenged, "DAM: Task not in active resolution state");
        require(block.timestamp > task.challengeWindowEnd, "DAM: Challenge window still open");

        // Logic to verify oracleSignature against a registered oracle key or a specific verifier contract would go here.
        // Example: IOracleVerifier(verificationProofVerifier).verifyOracleSignature(finalTruthHash, oracleSignature);
        // We'll skip complex signature verification for brevity in this contract example.

        task.finalTruthHash = finalTruthHash;
        task.resolutionMethod = ResolutionMethod.OracleTruth;
        task.resolutionTime = block.timestamp;
        task.status = TaskStatus.Resolved;

        emit TaskResolvedByOracle(taskId, finalTruthHash);
    }

    /**
     * @notice Finalizes a task after resolution, distributing rewards/penalties and updating KAN scores.
     * Callable after challenge window ends AND resolution is determined (either by voting or oracle).
     * @param taskId The ID of the task to finalize.
     */
    function finalizeTaskAndDistributeRewards(uint256 taskId) public nonReentrant whenNotPaused {
        InferenceTask storage task = inferenceTasks[taskId];
        require(task.id == taskId, "DAM: Task does not exist");
        require(task.status == TaskStatus.Claimed || task.status == TaskStatus.Challenged || task.status == TaskStatus.Resolved, "DAM: Task not ready for finalization");
        require(block.timestamp > task.challengeWindowEnd, "DAM: Challenge window still open");

        if (task.status != TaskStatus.Resolved) {
            // Attempt to resolve via voting if not already resolved by oracle
            resolveByVoting(taskId);
        }
        require(task.status == TaskStatus.Resolved, "DAM: Task not yet resolved by vote or oracle");

        bytes32 finalTruth = task.finalTruthHash;
        uint256 totalRewardsDistributed = 0;
        uint256 protocolFeePercent = protocolParameters[PARAM_PROTOCOL_FEE_PERCENT];

        uint256 K_SCORE_CORRECT_SUBMISSION_GAIN = protocolParameters[PARAM_K_SCORE_CORRECT_SUBMISSION_GAIN];
        uint256 K_SCORE_INCORRECT_SUBMISSION_LOSS = protocolParameters[PARAM_K_SCORE_INCORRECT_SUBMISSION_LOSS];
        uint256 K_SCORE_CORRECT_CHALLENGE_GAIN = protocolParameters[PARAM_K_SCORE_CORRECT_CHALLENGE_GAIN];
        uint256 K_SCORE_INCORRECT_CHALLENGE_LOSS = protocolParameters[PARAM_K_SCORE_INCORRECT_CHALLENGE_LOSS];
        uint256 K_SCORE_CORRECT_VOTE_GAIN = protocolParameters[PARAM_K_SCORE_CORRECT_VOTE_GAIN];

        // --- Handle Primary Agent ---
        KnowledgeAgent storage claimedAgent = knowledgeAgents[task.claimedByAgentId];
        if (task.claimedResultHash == finalTruth) {
            // Correct submission: reward agent with net reward pool
            uint256 agentReward = (task.rewardPool * (10000 - protocolFeePercent)) / 10000;
            claimedAgent.totalStaked += agentReward;
            claimedAgent.knowledgeScore += K_SCORE_CORRECT_SUBMISSION_GAIN;
            claimedAgent.correctSubmissions++;
            totalRewardsDistributed += agentReward;
            protocolFeeBalance += task.rewardPool - agentReward; // Protocol fee from reward pool
            emit KnowledgeScoreUpdated(claimedAgent.id, claimedAgent.knowledgeScore, int256(K_SCORE_CORRECT_SUBMISSION_GAIN));
        } else {
            // Incorrect submission: penalize agent's score
            claimedAgent.knowledgeScore = claimedAgent.knowledgeScore > K_SCORE_INCORRECT_SUBMISSION_LOSS ? claimedAgent.knowledgeScore - K_SCORE_INCORRECT_SUBMISSION_LOSS : 0;
            claimedAgent.incorrectSubmissions++;
            protocolFeeBalance += task.rewardPool; // Entire reward pool goes to protocol if main agent is wrong and no challenger wins
            emit KnowledgeScoreUpdated(claimedAgent.id, claimedAgent.knowledgeScore, -int256(K_SCORE_INCORRECT_SUBMISSION_LOSS));
        }
        claimedAgent.tasksCompleted++;

        // --- Handle Challenger Agent (if exists) ---
        if (task.challengerAgentId != 0) {
            KnowledgeAgent storage challengerAgent = knowledgeAgents[task.challengerAgentId];
            if (task.challengerResultHash == finalTruth) {
                // Challenger was correct: get their stake back + a reward
                uint256 challengerReward = task.challengeStake; // Initial stake
                uint256 bonusFromPool = (task.rewardPool * (10000 - protocolFeePercent)) / 10000; // Simplified: Challenger gets the main reward pool if they're correct
                challengerAgent.totalStaked += challengerReward + bonusFromPool;
                challengerAgent.knowledgeScore += K_SCORE_CORRECT_CHALLENGE_GAIN;
                challengerAgent.correctSubmissions++;
                totalRewardsDistributed += challengerReward + bonusFromPool;
                // If challenger is correct, the original agent was wrong, so their potential reward is lost to challenger or protocol.
                protocolFeeBalance += task.rewardPool - bonusFromPool; // Protocol takes fee from the challenger's bonus, not the whole pool
            } else {
                // Challenger was incorrect: challenger loses stake, it goes to protocol fees.
                protocolFeeBalance += task.challengeStake;
                challengerAgent.knowledgeScore = challengerAgent.knowledgeScore > K_SCORE_INCORRECT_CHALLENGE_LOSS ? challengerAgent.knowledgeScore - K_SCORE_INCORRECT_CHALLENGE_LOSS : 0;
                challengerAgent.incorrectSubmissions++;
            }
            challengerAgent.tasksCompleted++;
            emit KnowledgeScoreUpdated(challengerAgent.id, challengerAgent.knowledgeScore, (task.challengerResultHash == finalTruth) ? int256(K_SCORE_CORRECT_CHALLENGE_GAIN) : -int256(K_SCORE_INCORRECT_CHALLENGE_LOSS));
        }

        // --- Handle Voters (score update only, no direct token distribution to avoid gas limits for many voters) ---
        if (task.status == TaskStatus.Resolved && task.resolutionMethod == ResolutionMethod.ConsensusVote) {
            for (uint256 agentId = 1; agentId <= _kanIdCounter.current(); agentId++) { // Iterate through all possible KAN IDs (inefficient for large scale)
                if (task.votes[agentId] == finalTruth) {
                    KnowledgeAgent storage voterAgent = knowledgeAgents[agentId];
                    // Ensure the voter is not the claimed or challenger agent to prevent double-dipping score
                    if (agentId != task.claimedByAgentId && agentId != task.challengerAgentId) {
                        voterAgent.knowledgeScore += K_SCORE_CORRECT_VOTE_GAIN;
                        emit KnowledgeScoreUpdated(agentId, voterAgent.knowledgeScore, int256(K_SCORE_CORRECT_VOTE_GAIN));
                    }
                }
            }
        }
        
        task.status = TaskStatus.Finalized;
        emit TaskFinalized(taskId, finalTruth, totalRewardsDistributed);
    }

    // Internal function to resolve task by voting majority
    function resolveByVoting(uint256 taskId) internal {
        InferenceTask storage task = inferenceTasks[taskId];
        if (task.status == TaskStatus.Challenged && block.timestamp > task.challengeWindowEnd) {
            bytes32 bestResult = bytes32(0);
            uint256 maxVotes = 0;

            if (task.resultVoteCounts[task.claimedResultHash] > maxVotes) {
                maxVotes = task.resultVoteCounts[task.claimedResultHash];
                bestResult = task.claimedResultHash;
            }
            // Check challenger's votes only if challenger exists
            if (task.challengerAgentId != 0 && task.resultVoteCounts[task.challengerResultHash] > maxVotes) {
                maxVotes = task.resultVoteCounts[task.challengerResultHash];
                bestResult = task.challengerResultHash;
            }

            // If there's a clear majority, set it as truth
            if (maxVotes > 0) { // More than 0 votes means at least one result got votes
                task.finalTruthHash = bestResult;
                task.resolutionMethod = ResolutionMethod.ConsensusVote;
                task.resolutionTime = block.timestamp;
                task.status = TaskStatus.Resolved;
            } else {
                // If no votes or a tie, the task remains in 'Challenged' state, awaiting oracle resolution.
                // Or, could have a default resolution like favoring the original claim if no clear challenge win.
                // For this example, it simply stays 'Challenged' until an oracle steps in.
            }
        }
    }


    // --- IV. Reputation & Dynamic NFT Attributes ---

    /**
     * @notice Returns the current Knowledge Score of a KAN.
     * @param tokenId The ID of the KAN.
     * @return The knowledge score.
     */
    function getAgentKnowledgeScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "KAN: Nonexistent token");
        return knowledgeAgents[tokenId].knowledgeScore;
    }

    /**
     * @notice Provides more detailed performance data for a KAN.
     * @param tokenId The ID of the KAN.
     * @return _totalStaked Total AetherTokens staked to the agent.
     * @return _knowledgeScore Current knowledge score.
     * @return _tasksCompleted Number of tasks agent participated in.
     * @return _correctSubmissions Number of correct submissions/challenges.
     * @return _incorrectSubmissions Number of incorrect submissions/challenges.
     * @return _winRate Percentage of correct submissions (times 10000 for precision).
     */
    function getAgentPerformanceMetrics(uint256 tokenId)
        public
        view
        returns (
            uint256 _totalStaked,
            uint256 _knowledgeScore,
            uint256 _tasksCompleted,
            uint256 _correctSubmissions,
            uint256 _incorrectSubmissions,
            uint256 _winRate
        )
    {
        require(_exists(tokenId), "KAN: Nonexistent token");
        KnowledgeAgent storage agent = knowledgeAgents[tokenId];
        _totalStaked = agent.totalStaked;
        _knowledgeScore = agent.knowledgeScore;
        _tasksCompleted = agent.tasksCompleted;
        _correctSubmissions = agent.correctSubmissions;
        _incorrectSubmissions = agent.incorrectSubmissions;

        if (agent.tasksCompleted > 0) {
            _winRate = (agent.correctSubmissions * 10000) / agent.tasksCompleted;
        } else {
            _winRate = 0;
        }
    }

    // --- V. Token & Treasury Management ---

    /**
     * @notice Allows users to deposit AetherTokens into the contract.
     * @param amount The amount of AetherTokens to deposit.
     */
    function depositFunds(uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "DAM: Deposit amount must be positive");
        require(AetherToken.transferFrom(_msgSender(), address(this), amount), "DAM: Token transfer failed for deposit");
        emit FundsDeposited(_msgSender(), amount);
    }

    /**
     * @notice Allows the protocol owner to withdraw accumulated protocol fees.
     * @param recipient The address to receive the fees.
     */
    function withdrawProtocolFees(address recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "DAM: Recipient cannot be zero address");
        uint256 amount = protocolFeeBalance;
        require(amount > 0, "DAM: No protocol fees to withdraw");
        protocolFeeBalance = 0; // Reset balance
        require(AetherToken.transfer(recipient, amount), "DAM: Protocol fee withdrawal failed");
        emit ProtocolFeesWithdrawn(recipient, amount);
    }
    
    /**
     * @notice Allows the protocol owner to register recognized off-chain AI models.
     * These IDs can be referenced in verifiable proofs for enhanced trust and transparency.
     * @param modelId A unique identifier for the AI model (e.g., hash of its code/weights).
     * @param modelDescriptionURI URI pointing to detailed information about the model (e.g., performance, architecture).
     */
    function registerExternalAIModel(bytes32 modelId, string memory modelDescriptionURI) public onlyOwner {
        require(modelId != bytes32(0), "DAM: Model ID cannot be zero");
        registeredAIModels[modelId] = modelDescriptionURI;
        emit ExternalAIModelRegistered(modelId, modelDescriptionURI);
    }

    /**
     * @notice Returns the total AetherToken balance held by the contract.
     */
    function getAvailableFunds() public view returns (uint256) {
        return AetherToken.balanceOf(address(this));
    }
}
```