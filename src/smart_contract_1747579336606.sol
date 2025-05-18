Okay, let's design a smart contract that incorporates several advanced and trendy concepts: Decentralized AI task coordination, verifiable computation (simulated via ZK proof hashes and off-chain verification outcome), reputation systems, staking/slashing, dynamic NFT representation of AI agents, and on-chain governance.

It's crucial to understand that running complex AI computation *on-chain* is currently impossible due to gas limits and computational constraints. This contract focuses on the *coordination* and *incentivization* layer on the blockchain, managing tasks, participants, payments, verification outcomes, and reputation, while the heavy AI computation and ZK proof generation/verification happen *off-chain*.

Here's the contract structure and code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Outline & Function Summary
/*
Outline:
1.  State Variables: Mappings for participants (providers, verifiers), tasks, reputation, stakes, earnings, governance proposals, etc.
2.  Enums: Task Status, Proposal State.
3.  Structs: Task details, Proposal details.
4.  Events: Lifecycle events for tasks, participants, governance, staking, NFTs.
5.  Modifiers: Access control (roles), pausable, reentrancy guard.
6.  Constructor: Initializes contract with token addresses and initial parameters.
7.  Participant Management: Registering/deregistering Compute Providers and Verifiers (linked to Agent NFTs).
8.  Staking & Earnings: Allowing participants to stake tokens and withdraw earned rewards/unslashed stake.
9.  Task Lifecycle:
    *   Submit Task (Requester pays token)
    *   Claim Task (Provider locks stake)
    *   Submit Result (Provider includes result details and ZK proof hash)
    *   Claim Verification Task (Verifier locks stake)
    *   Submit Verification Result (Verifier confirms result validity based on off-chain ZK verification)
    *   Finalize Task (Distribute rewards/penalties based on verification outcome)
10. Reputation System: Simple score tracking based on task performance and verification accuracy.
11. Decentralized Governance: Proposal creation, voting (based on Gov Token), and execution for parameter changes or other actions.
12. Agent NFTs (ERC721): Each registered Compute Provider is minted a unique Agent NFT representing their identity and track record. Metadata can be dynamic.
13. Query Functions: Read state information (tasks, participants, reputation, parameters, proposals).
14. Administrative Functions: Pause/Unpause (initially owner, potentially governance).

Function Summary (>20 public/external functions):
- registerComputeProvider: Register as a compute provider, mints an Agent NFT.
- deregisterComputeProvider: Deregister, burns Agent NFT (if no active tasks/stake).
- registerVerifier: Register as a verifier.
- deregisterVerifier: Deregister (if no active verification tasks/stake).
- stakeTokens: Stake tokens to participate in tasks/verification.
- withdrawStake: Withdraw unstaked tokens.
- withdrawEarnings: Withdraw earned rewards.
- submitTask: Create a new AI computation task (requester pays).
- claimTask: Compute Provider claims an available task.
- submitTaskResult: Compute Provider submits the result and ZK proof hash.
- claimVerificationTask: Verifier claims a task for verification.
- submitVerificationResult: Verifier submits the validity result (based on off-chain ZK check).
- finalizeTask: Finalize a task, distribute rewards, apply penalties, update reputation.
- createProposal: Propose changes to contract parameters (requires Gov Token stake/holding).
- voteOnProposal: Vote on an active proposal.
- executeProposal: Execute a successful proposal.
- updateAgentNFTMetadataURI: Allow agent owner/contract to update NFT metadata URI (e.g., reflect reputation).
- getReputationScore: Query reputation for an address.
- getTaskDetails: Query details for a specific task.
- getParticipantInfo: Query registration and stake info for an address.
- getProposalDetails: Query details for a specific proposal.
- getParameter: Query the value of a governance parameter.
- pause: Pause contract operations (admin/governance).
- unpause: Unpause contract operations (admin/governance).
- getAgentNFTId: Get the Agent NFT ID for a provider address.
- getAgentNFTMetadataURI: Get the current metadata URI for an Agent NFT.

Advanced Concepts Used:
- Decentralized Coordination: Managing AI tasks/workflows on-chain.
- Verifiable Computation (Simulated): Using ZK proof hashes and relying on off-chain verification results recorded on-chain.
- Reputation System: On-chain tracking of participant reliability.
- Staking & Slashing: Economic incentives for good behavior and penalties for bad.
- Dynamic NFTs: ERC721s representing agents, with updatable metadata URI linked to on-chain state (reputation).
- On-chain Governance: A basic system for protocol parameter changes.
- Role-Based Access Control: Using modifiers and state to restrict function calls.
- Pausability & ReentrancyGuard: Standard security practices.
*/


contract DecentralizedAICollective is Ownable, Pausable, ReentrancyGuard, ERC721URIStorage {

    // --- State Variables ---

    IERC20 public immutable rewardToken; // Token used for task payment, staking, and rewards
    IERC20 public immutable governanceToken; // Token used for governance voting

    // Participant Management
    struct Participant {
        bool isComputeProvider;
        bool isVerifier;
        uint256 stake; // Amount staked by the participant
        uint256 earnings; // Earned but not yet withdrawn rewards
        uint256 agentNFTId; // 0 if not a compute provider
        uint256 activeTaskId; // ID of task currently claimed (0 if none)
        uint256 activeVerificationTaskId; // ID of verification task currently claimed (0 if none)
    }
    mapping(address => Participant) public participants;
    mapping(uint256 => address) public agentIdToProvider; // Map NFT ID to provider address
    uint256 private _nextAgentId = 1; // Counter for Agent NFTs

    // Reputation System
    mapping(address => int256) public reputation; // Reputation score (can be negative)

    // Task Management
    enum TaskStatus { Pending, ClaimedByProvider, ResultSubmitted, ClaimedByVerifier, VerificationSubmitted, Finalized, Cancelled }
    struct Task {
        uint256 id;
        address requester;
        uint256 rewardAmount; // Reward for successful completion (paid by requester)
        bytes32 taskDataHash; // Hash of off-chain task input data
        address provider; // Address of compute provider who claimed the task
        address verifier; // Address of verifier who claimed the verification task
        TaskStatus status;
        bytes32 resultHash; // Hash of off-chain result data submitted by provider
        bytes32 zkProofHash; // Hash of ZK proof submitted by provider
        bool verificationResult; // True if verifier confirmed result validity
        uint256 creationTime;
        uint256 claimTime;
        uint256 resultSubmitTime;
        uint256 verificationClaimTime;
        uint256 verificationSubmitTime;
        uint256 finalizeTime;
    }
    mapping(uint256 => Task) public tasks;
    uint256 private _nextTaskId = 1; // Counter for tasks

    // Governance System
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if proposal succeeds
        address targetContract; // Contract address to call for execution
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingSupplySnapshot; // Total Gov Tokens at proposal creation
        mapping(address => bool) hasVoted;
        uint256 votingDeadline;
        ProposalState state;
        string parameterName; // Optional: For parameter change proposals
        uint256 parameterValue; // Optional: For parameter change proposals
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId = 1; // Counter for proposals
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public proposalThreshold = 100 * 10**18; // Min Gov Token needed to create proposal
    uint256 public quorumNumerator = 4; // 4/10 = 40% quorum
    uint256 public quorumDenominator = 10;

    // Governance Parameters (settable via governance)
    mapping(string => uint256) public governanceParameters;

    // Slashing & Reward Parameters (settable via governance parameters)
    string public constant PARAM_TASK_STAKE_REQUIRED = "taskStakeRequired";
    string public constant PARAM_VERIFICATION_STAKE_REQUIRED = "verificationStakeRequired";
    string public constant PARAM_PROVIDER_TASK_TIMEOUT = "providerTaskTimeout";
    string public constant PARAM_VERIFIER_TASK_TIMEOUT = "verifierTaskTimeout";
    string public constant PARAM_PROVIDER_SLASH_PERCENT = "providerSlashPercent"; // e.g., 5000 for 50%
    string public constant PARAM_VERIFIER_SLASH_PERCENT = "verifierSlashPercent"; // e.g., 5000 for 50%
    string public constant PARAM_REPUTATION_INCREASE_SUCCESS = "reputationIncreaseSuccess";
    string public constant PARAM_REPUTATION_DECREASE_FAILURE = "reputationDecreaseFailure";
    string public constant PARAM_MIN_REPUTATION_PROVIDER = "minReputationProvider";
    string public constant PARAM_MIN_REPUTATION_VERIFIER = "minReputationVerifier";
    string public constant PARAM_TASK_REWARD_PROVIDER_PERCENT = "taskRewardProviderPercent"; // e.g., 7000 for 70%
    string public constant PARAM_TASK_REWARD_VERIFIER_PERCENT = "taskRewardVerifierPercent"; // e.g., 3000 for 30%
    string public constant PARAM_PROPOSAL_THRESHOLD = "proposalThreshold"; // Overrides fixed threshold
    string public constant PARAM_VOTING_PERIOD = "votingPeriod"; // Overrides fixed votingPeriod
    string public constant PARAM_QUORUM_NUMERATOR = "quorumNumerator"; // Overrides fixed quorum
    string public constant PARAM_QUORUM_DENOMINATOR = "quorumDenominator";


    // --- Events ---

    event ComputeProviderRegistered(address indexed provider, uint256 agentNFTId);
    event ComputeProviderDeregistered(address indexed provider, uint256 agentNFTId);
    event VerifierRegistered(address indexed verifier);
    event VerifierDeregistered(address indexed verifier);
    event TokensStaked(address indexed participant, uint256 amount);
    event StakeWithdrawn(address indexed participant, uint256 amount);
    event EarningsWithdrawn(address indexed participant, uint256 amount);

    event TaskSubmitted(uint256 indexed taskId, address indexed requester, uint256 rewardAmount, bytes32 taskDataHash);
    event TaskClaimed(uint256 indexed taskId, address indexed provider);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed provider, bytes32 resultHash, bytes32 zkProofHash);
    event VerificationTaskClaimed(uint256 indexed taskId, address indexed verifier);
    event VerificationResultSubmitted(uint256 indexed taskId, address indexed verifier, bool isValid);
    event TaskFinalized(uint256 indexed taskId, TaskStatus finalStatus, uint256 providerReward, uint256 verifierReward, uint256 slashedAmount);
    event TaskCancelled(uint256 indexed taskId); // For timeouts or requester cancellation

    event StakeSlash(address indexed participant, uint256 taskId, uint256 slashedAmount, string reason);
    event ReputationUpdated(address indexed participant, int256 oldScore, int256 newScore);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 votingDeadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(string indexed paramName, uint256 newValue);


    // --- Constructor ---

    constructor(address _rewardToken, address _governanceToken, address initialOwner)
        ERC721("AIAgentNFT", "AIAgent")
        Ownable(initialOwner) // Set initial owner for pause/unpause (can be transferred to governance)
        Pausable()
    {
        require(_rewardToken != address(0), "Invalid reward token address");
        require(_governanceToken != address(0), "Invalid governance token address");

        rewardToken = IERC20(_rewardToken);
        governanceToken = IERC20(_governanceToken);

        // Initialize default governance parameters (can be changed via governance)
        governanceParameters[PARAM_TASK_STAKE_REQUIRED] = 100 * 10**rewardToken.decimals(); // Example value
        governanceParameters[PARAM_VERIFICATION_STAKE_REQUIRED] = 50 * 10**rewardToken.decimals(); // Example value
        goverancers[PARAM_PROVIDER_TASK_TIMEOUT] = 1 hours; // Example timeout
        governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT] = 30 minutes; // Example timeout
        governanceParameters[PARAM_PROVIDER_SLASH_PERCENT] = 5000; // 50%
        governanceParameters[PARAM_VERIFIER_SLASH_PERCENT] = 7500; // 75%
        governanceParameters[PARAM_REPUTATION_INCREASE_SUCCESS] = 10;
        governanceParameters[PARAM_REPUTATION_DECREASE_FAILURE] = 15;
        governanceParameters[PARAM_MIN_REPUTATION_PROVIDER] = 0; // Providers must have >= 0 rep
        governanceParameters[PARAM_MIN_REPUTATION_VERIFIER] = 50; // Verifiers must have >= 50 rep
        governanceParameters[PARAM_TASK_REWARD_PROVIDER_PERCENT] = 7000; // 70%
        governanceParameters[PARAM_TASK_REWARD_VERIFIER_PERCENT] = 3000; // 30%
        governanceParameters[PARAM_PROPOSAL_THRESHOLD] = proposalThreshold; // Use initial values
        governanceParameters[PARAM_VOTING_PERIOD] = votingPeriod;
        governanceParameters[PARAM_QUORUM_NUMERATOR] = quorumNumerator;
        governanceParameters[PARAM_QUORUM_DENOMINATOR] = quorumDenominator;
    }

    // --- Modifiers ---

    modifier onlyRegisteredProvider() {
        require(participants[msg.sender].isComputeProvider, "Not a registered compute provider");
        _;
    }

    modifier onlyRegisteredVerifier() {
        require(participants[msg.sender].isVerifier, "Not a registered verifier");
        _;
    }

    modifier onlyGovTokenHolder(uint256 _proposalId) {
         require(proposals[_proposalId].state == ProposalState.Active, "Proposal not active");
         // This is a simplified check based on snapshot logic. A real implementation would need
         // a more robust snapshot mechanism like ERC20Votes
         // For this example, we'll assume a snapshot taken at proposal creation time
         // requires checking a separate snapshot mapping or using a standard like ERC20Votes
         // For simplicity here, we'll require holding the token *now* and assume snapshot logic
         // is handled externally or in a more complex mapping.
         // A better simple approach for this example is to just check current balance
         require(governanceToken.balanceOf(msg.sender) > 0, "Requires governance token holding");
         _;
    }

    // --- Participant Management (5 functions) ---

    /// @notice Register as a compute provider. Mints an Agent NFT.
    /// @dev Requires staking the required amount.
    /// @param initialMetadataURI The initial metadata URI for the Agent NFT.
    function registerComputeProvider(string calldata initialMetadataURI) external whenNotPaused nonReentrancy {
        require(!participants[msg.sender].isComputeProvider, "Already a compute provider");
        uint256 requiredStake = governanceParameters[PARAM_TASK_STAKE_REQUIRED];
        require(participants[msg.sender].stake >= requiredStake, string(abi.encodePacked("Minimum stake of ", requiredStake, " required")));
        require(reputation[msg.sender] >= int256(governanceParameters[PARAM_MIN_REPUTATION_PROVIDER]), "Insufficient reputation");

        participants[msg.sender].isComputeProvider = true;

        // Mint Agent NFT
        uint256 newItemId = _nextAgentId++;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, initialMetadataURI);
        participants[msg.sender].agentNFTId = newItemId;
        agentIdToProvider[newItemId] = msg.sender;

        emit ComputeProviderRegistered(msg.sender, newItemId);
    }

    /// @notice Deregister as a compute provider. Burns the Agent NFT.
    /// @dev Only allowed if participant has no active tasks or staked tokens.
    function deregisterComputeProvider() external whenNotPaused nonReentrancy {
        require(participants[msg.sender].isComputeProvider, "Not a compute provider");
        require(participants[msg.sender].activeTaskId == 0, "Cannot deregister with active task");
        // Consider requiring stake to be 0 as well, or adding a function to unstake completely first
        // For simplicity, allow deregistering if no active task, stake can be withdrawn separately
        participants[msg.sender].isComputeProvider = false;

        // Burn Agent NFT
        uint256 agentId = participants[msg.sender].agentNFTId;
        require(agentId != 0, "No Agent NFT found"); // Should not happen if isComputeProvider is true
        _burn(agentId);
        delete participants[msg.sender].agentNFTId;
        delete agentIdToProvider[agentId];

        emit ComputeProviderDeregistered(msg.sender, agentId);
    }

    /// @notice Register as a verifier.
    /// @dev Requires staking the required amount.
    function registerVerifier() external whenNotPaused nonReentrancy {
        require(!participants[msg.sender].isVerifier, "Already a verifier");
        uint256 requiredStake = governanceParameters[PARAM_VERIFICATION_STAKE_REQUIRED];
        require(participants[msg.sender].stake >= requiredStake, string(abi.encodePacked("Minimum stake of ", requiredStake, " required")));
        require(reputation[msg.sender] >= int256(governanceParameters[PARAM_MIN_REPUTATION_VERIFIER]), "Insufficient reputation");

        participants[msg.sender].isVerifier = true;

        emit VerifierRegistered(msg.sender);
    }

    /// @notice Deregister as a verifier.
    /// @dev Only allowed if participant has no active verification tasks or staked tokens.
    function deregisterVerifier() external whenNotPaused nonReentrancy {
        require(participants[msg.sender].isVerifier, "Not a verifier");
        require(participants[msg.sender].activeVerificationTaskId == 0, "Cannot deregister with active verification task");
        // Consider requiring stake to be 0 as well
        participants[msg.sender].isVerifier = false;
        emit VerifierDeregistered(msg.sender);
    }

    /// @notice Stake reward tokens in the contract.
    /// @param amount The amount of tokens to stake.
    function stakeTokens(uint256 amount) external whenNotPaused nonReentrancy {
        require(amount > 0, "Stake amount must be greater than 0");
        require(rewardToken.transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        participants[msg.sender].stake += amount;
        emit TokensStaked(msg.sender, amount);
    }

    /// @notice Withdraw unstaked tokens.
    /// @dev Cannot withdraw stake if participating in an active task or verification.
    function withdrawStake(uint256 amount) external whenNotPaused nonReentrancy {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(participants[msg.sender].stake >= amount, "Insufficient staked balance");
        require(participants[msg.sender].activeTaskId == 0 && participants[msg.sender].activeVerificationTaskId == 0, "Cannot withdraw active stake");

        participants[msg.sender].stake -= amount;
        require(rewardToken.transfer(msg.sender, amount), "Token transfer failed");
        emit StakeWithdrawn(msg.sender, amount);
    }

     /// @notice Withdraw earned reward tokens.
    function withdrawEarnings() external whenNotPaused nonReentrancy {
        uint256 amount = participants[msg.sender].earnings;
        require(amount > 0, "No earnings to withdraw");

        participants[msg.sender].earnings = 0;
        require(rewardToken.transfer(msg.sender, amount), "Token transfer failed");
        emit EarningsWithdrawn(msg.sender, amount);
    }


    // --- Task Management (7 functions) ---

    /// @notice Submit a new AI computation task.
    /// @dev Requester pays the reward amount upfront.
    /// @param rewardAmount The reward offered for successful task completion.
    /// @param taskDataHash A hash representing the off-chain task data (e.g., IPFS hash).
    function submitTask(uint256 rewardAmount, bytes32 taskDataHash) external whenNotPaused nonReentrancy {
        require(rewardAmount > 0, "Reward amount must be greater than 0");
        require(taskDataHash != bytes32(0), "Task data hash cannot be zero");
        require(rewardToken.transferFrom(msg.sender, address(this), rewardAmount), "Token transfer failed");

        uint256 newTaskId = _nextTaskId++;
        tasks[newTaskId] = Task({
            id: newTaskId,
            requester: msg.sender,
            rewardAmount: rewardAmount,
            taskDataHash: taskDataHash,
            provider: address(0),
            verifier: address(0),
            status: TaskStatus.Pending,
            resultHash: bytes32(0),
            zkProofHash: bytes32(0),
            verificationResult: false, // Default value, will be set by verifier
            creationTime: block.timestamp,
            claimTime: 0,
            resultSubmitTime: 0,
            verificationClaimTime: 0,
            verificationSubmitTime: 0,
            finalizeTime: 0
        });

        emit TaskSubmitted(newTaskId, msg.sender, rewardAmount, taskDataHash);
    }

    /// @notice Compute Provider claims a pending task.
    /// @dev Provider must be registered, have minimum reputation, and required stake.
    /// @param taskId The ID of the task to claim.
    function claimTask(uint256 taskId) external onlyRegisteredProvider whenNotPaused nonReentrancy {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Pending, "Task is not pending");
        require(participants[msg.sender].activeTaskId == 0, "Participant already has an active task");
        require(participants[msg.sender].stake >= governanceParameters[PARAM_TASK_STAKE_REQUIRED], "Insufficient stake to claim task");
         require(reputation[msg.sender] >= int256(governanceParameters[PARAM_MIN_REPUTATION_PROVIDER]), "Insufficient reputation");

        task.provider = msg.sender;
        task.status = TaskStatus.ClaimedByProvider;
        task.claimTime = block.timestamp;
        participants[msg.sender].activeTaskId = taskId;

        emit TaskClaimed(taskId, msg.sender);
    }

    /// @notice Compute Provider submits the result and ZK proof hash for a claimed task.
    /// @dev Must be the provider who claimed the task and within the timeout.
    /// @param taskId The ID of the task.
    /// @param resultHash The hash of the computation result data.
    /// @param zkProofHash The hash of the ZK proof verifying the computation.
    function submitTaskResult(uint256 taskId, bytes32 resultHash, bytes32 zkProofHash) external onlyRegisteredProvider whenNotPaused nonReentrancy {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ClaimedByProvider, "Task is not claimed by provider");
        require(task.provider == msg.sender, "Not the provider for this task");
        require(block.timestamp <= task.claimTime + governanceParameters[PARAM_PROVIDER_TASK_TIMEOUT], "Task submission timed out");
        require(resultHash != bytes32(0), "Result hash cannot be zero");
        require(zkProofHash != bytes32(0), "ZK Proof hash cannot be zero");

        task.resultHash = resultHash;
        task.zkProofHash = zkProofHash;
        task.status = TaskStatus.ResultSubmitted;
        task.resultSubmitTime = block.timestamp;
        participants[msg.sender].activeTaskId = 0; // Provider task is now done, can claim another

        emit TaskResultSubmitted(taskId, msg.sender, resultHash, zkProofHash);
    }

    /// @notice Verifier claims a task that has had its result submitted.
    /// @dev Verifier must be registered, have minimum reputation, and required stake.
    /// @param taskId The ID of the task to verify.
    function claimVerificationTask(uint256 taskId) external onlyRegisteredVerifier whenNotPaused nonReentrancy {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ResultSubmitted, "Task is not awaiting verification");
         require(participants[msg.sender].activeVerificationTaskId == 0, "Participant already has an active verification task");
        require(participants[msg.sender].stake >= governanceParameters[PARAM_VERIFICATION_STAKE_REQUIRED], "Insufficient stake to claim verification task");
         require(reputation[msg.sender] >= int256(governanceParameters[PARAM_MIN_REPUTATION_VERIFIER]), "Insufficient reputation");
         require(task.provider != msg.sender, "Cannot verify your own task"); // Verifier cannot be the provider

        task.verifier = msg.sender;
        task.status = TaskStatus.ClaimedByVerifier;
        task.verificationClaimTime = block.timestamp;
        participants[msg.sender].activeVerificationTaskId = taskId;

        emit VerificationTaskClaimed(taskId, msg.sender);
    }

    /// @notice Verifier submits the result of their off-chain verification.
    /// @dev Must be the verifier who claimed the task and within the timeout.
    /// @param taskId The ID of the task.
    /// @param isValid True if the off-chain ZK proof verification was successful and result matches parameters.
    function submitVerificationResult(uint256 taskId, bool isValid) external onlyRegisteredVerifier whenNotPaused nonReentrancy {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.ClaimedByVerifier, "Task is not claimed by verifier");
        require(task.verifier == msg.sender, "Not the verifier for this task");
        require(block.timestamp <= task.verificationClaimTime + governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT], "Verification submission timed out");

        task.verificationResult = isValid;
        task.status = TaskStatus.VerificationSubmitted;
        task.verificationSubmitTime = block.timestamp;
        participants[msg.sender].activeVerificationTaskId = 0; // Verifier task done, can claim another

        emit VerificationResultSubmitted(taskId, msg.sender, isValid);
    }

    /// @notice Finalize a task after result and verification have been submitted.
    /// @dev Distributes rewards, applies penalties/slashing, and updates reputation.
    /// Can be called by anyone once verification is submitted or timeouts occur.
    /// @param taskId The ID of the task to finalize.
    function finalizeTask(uint256 taskId) external whenNotPaused nonReentrancy {
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.VerificationSubmitted || _isTaskTimedOut(taskId), "Task not ready for finalization or timed out");
        require(task.status != TaskStatus.Finalized && task.status != TaskStatus.Cancelled, "Task already finalized or cancelled");

        uint256 providerSlashAmount = 0;
        uint256 verifierSlashAmount = 0;
        uint256 providerReward = 0;
        uint256 verifierReward = 0;
        int256 providerRepChange = 0;
        int256 verifierRepChange = 0;
        TaskStatus finalStatus;

        // Check for timeouts
        bool providerTimedOut = task.status == TaskStatus.ClaimedByProvider && block.timestamp > task.claimTime + governanceParameters[PARAM_PROVIDER_TASK_TIMEOUT];
        bool verifierTimedOut = task.status == TaskStatus.ClaimedByVerifier && block.timestamp > task.verificationClaimTime + governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT];
        bool taskStuckAfterResult = task.status == TaskStatus.ResultSubmitted && block.timestamp > task.resultSubmitTime + governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT]; // If no verifier claims

        if (providerTimedOut || task.status == TaskStatus.Submitted) { // Provider failed to submit or stuck after submitting (no verifier)
             // Provider failed to claim or submit result in time
            if (task.provider != address(0)) { // Provider claimed but timed out
                 providerSlashAmount = (participants[task.provider].stake * governanceParameters[PARAM_PROVIDER_SLASH_PERCENT]) / 10000;
                 _slashStake(task.provider, providerSlashAmount, "Provider timeout or failure");
                 providerRepChange = -int256(governanceParameters[PARAM_REPUTATION_DECREASE_FAILURE]);
            }
             finalStatus = TaskStatus.Cancelled; // Task failed

        } else if (verifierTimedOut || task.status == TaskStatus.ResultSubmitted) {
            // Verifier failed to submit result or verify in time, OR no verifier claimed the result
            // In this simplified model, if no verifier validates, the provider's result is considered unverified or failed.
             if (task.verifier != address(0)) { // Verifier claimed but timed out
                 verifierSlashAmount = (participants[task.verifier].stake * governanceParameters[PARAM_VERIFIER_SLASH_PERCENT]) / 10000;
                 _slashStake(task.verifier, verifierSlashAmount, "Verifier timeout");
                 // Verifier timed out, can't assess their rep based on a result
             }
             // Since verification didn't complete (or happen), provider is not rewarded/may be penalized
             if (task.provider != address(0)) { // Only penalize if a provider actually submitted something
                 providerRepChange = -int256(governanceParameters[PARAM_REPUTATION_DECREASE_FAILURE]); // Provider failed to get verified
             }
             finalStatus = TaskStatus.Cancelled; // Task failed verification or verification didn't happen

        } else if (task.status == TaskStatus.VerificationSubmitted) {
            // Verification submitted successfully
            if (task.verificationResult) {
                // Result verified as correct
                providerReward = (task.rewardAmount * governanceParameters[PARAM_TASK_REWARD_PROVIDER_PERCENT]) / 10000;
                verifierReward = (task.rewardAmount * governanceParameters[PARAM_TASK_REWARD_VERIFIER_PERCENT]) / 10000;

                participants[task.provider].earnings += providerReward;
                participants[task.verifier].earnings += verifierReward;

                providerRepChange = int256(governanceParameters[PARAM_REPUTATION_INCREASE_SUCCESS]);
                verifierRepChange = int256(governanceParameters[PARAM_REPUTATION_INCREASE_SUCCESS]);

                 finalStatus = TaskStatus.Finalized;

            } else {
                // Result verified as incorrect
                providerSlashAmount = (participants[task.provider].stake * governanceParameters[PARAM_PROVIDER_SLASH_PERCENT]) / 10000;
                 _slashStake(task.provider, providerSlashAmount, "Incorrect result");
                 providerRepChange = -int256(governanceParameters[PARAM_REPUTATION_DECREASE_FAILURE]);

                 // Verifier was correct, reward them (e.g., a small fee or from slashed amount)
                 // For simplicity, reward verifier from the task reward pool even if provider failed.
                 // More complex logic could reward from slashed stake or a separate pool.
                 verifierReward = (task.rewardAmount * governanceParameters[PARAM_TASK_REWARD_VERIFIER_PERCENT]) / 10000; // Verifier still gets their cut for correct verification
                 participants[task.verifier].earnings += verifierReward;
                 verifierRepChange = int256(governanceParameters[PARAM_REPUTATION_INCREASE_SUCCESS]);

                 finalStatus = TaskStatus.Cancelled; // Task failed due to incorrect result
            }
        } else {
            revert("Task status is not ready for finalization");
        }

        // Update reputations
        if (task.provider != address(0)) {
             _updateReputation(task.provider, providerRepChange);
        }
        if (task.verifier != address(0)) {
             _updateReputation(task.verifier, verifierRepChange);
        }

        // Handle funds (reward distribution already done by adding to earnings)
        // Remaining task reward after distribution/slashing stays in contract or is returned/burned (decided by governance)
        // For simplicity, any remaining reward stays in the contract.
        uint256 remainingReward = task.rewardAmount - providerReward - verifierReward; // Includes slashed amounts conceptually returning to pool

        // Reset participant active task state if it wasn't already (e.g., due to timeout handling)
        if (task.provider != address(0) && participants[task.provider].activeTaskId == taskId) {
             participants[task.provider].activeTaskId = 0;
        }
         if (task.verifier != address(0) && participants[task.verifier].activeVerificationTaskId == taskId) {
             participants[task.verifier].activeVerificationTaskId = 0;
        }

        task.status = finalStatus;
        task.finalizeTime = block.timestamp;

        emit TaskFinalized(taskId, finalStatus, providerReward, verifierReward, providerSlashAmount + verifierSlashAmount);

        // Consider refunding requester if cancelled, or adding cancelled task penalty logic
        // For simplicity, requester's reward is kept by the contract on cancellation/failure.
    }

    // --- Internal Helper Functions ---

    function _slashStake(address participant, uint256 amount, string memory reason) internal {
        uint256 slashAmount = amount;
        if (participants[participant].stake < slashAmount) {
            slashAmount = participants[participant].stake; // Cannot slash more than they have
        }
        if (slashAmount > 0) {
            participants[participant].stake -= slashAmount;
            // Slashed stake could be sent to a treasury, burned, or redistributed.
            // For simplicity, it remains in the contract balance.
            emit StakeSlash(participant, participants[participant].activeTaskId == 0 ? participants[participant].activeVerificationTaskId : participants[participant].activeTaskId, slashAmount, reason);
        }
    }

     function _updateReputation(address participant, int256 change) internal {
        int256 oldRep = reputation[participant];
        reputation[participant] += change;
        emit ReputationUpdated(participant, oldRep, reputation[participant]);
     }

     function _isTaskTimedOut(uint256 taskId) internal view returns (bool) {
         Task storage task = tasks[taskId];
         if (task.status == TaskStatus.ClaimedByProvider && block.timestamp > task.claimTime + governanceParameters[PARAM_PROVIDER_TASK_TIMEOUT]) {
             return true;
         }
          if (task.status == TaskStatus.ClaimedByVerifier && block.timestamp > task.verificationClaimTime + governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT]) {
             return true;
         }
          // Check if stuck after result submission because no verifier claimed
         if (task.status == TaskStatus.ResultSubmitted && block.timestamp > task.resultSubmitTime + governanceParameters[PARAM_VERIFIER_TASK_TIMEOUT] * 2) { // Give verifiers double their timeout to claim/submit
              return true;
         }
         return false;
     }


    // --- Governance (5 functions) ---

    /// @notice Creates a new governance proposal.
    /// @dev Requires holding the minimum governance token threshold.
    /// @param description A description of the proposal.
    /// @param targetContract The address of the contract to call (usually this contract).
    /// @param callData The encoded function call (e.g., `abi.encodeWithSignature("setParameter(string,uint256)", paramName, paramValue)`).
     function createProposal(string calldata description, address targetContract, bytes calldata callData) external whenNotPaused nonReentrancy {
        uint256 currentThreshold = governanceParameters[PARAM_PROPOSAL_THRESHOLD];
        require(governanceToken.balanceOf(msg.sender) >= currentThreshold, "Insufficient governance tokens to create proposal");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            callData: callData,
            targetContract: targetContract,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingSupplySnapshot: governanceToken.totalSupply(), // Simplified snapshot
            hasVoted: new mapping(address => bool),
            votingDeadline: block.timestamp + governanceParameters[PARAM_VOTING_PERIOD],
            state: ProposalState.Active,
            parameterName: "", // Default empty
            parameterValue: 0 // Default 0
        });

         // Attempt to decode if it's a setParameter call for parameter tracking
         bytes memory expectedSignature = abi.encodeWithSignature("setParameter(string,uint256)");
         if (callData.length >= 4 && callData[:4] == expectedSignature[:4]) {
              // Check if callData is long enough to contain the arguments + signature
             // Basic length check: 4 bytes sig + 32 bytes string ptr + 32 bytes string len + N bytes string data + 32 bytes uint256
             // Minimum length for setParameter("x", 1) approx 4 + 32 + 32 + 1*byte + 32 = 101 bytes.
             // A more robust check would decode properly. For this example, just check signature prefix.
             if (callData.length > 100) { // A heuristic check for plausible length
                 // Note: Proper decoding requires more complex ABI decoding logic
                 // This is a simplified check
                 // If you need to *use* the parameter values in the struct, you'd need
                 // to implement a proper abi.decode or use a library.
                 // For now, we'll just flag it as potentially a parameter change proposal.
                 // You might set a flag or store parts of the expected data if possible.
                 // We'll store a placeholder if structure looks right, but won't decode fully here.
             }
         }


        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].votingDeadline);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }

    /// @notice Cast a vote on an active proposal.
    /// @dev Requires holding governance tokens at the time the proposal snapshot was taken (simulated by current holding).
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for a vote "for", False for a vote "against".
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused nonReentrancy onlyGovTokenHolder(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");

        // In a real DAO, vote weight would be governanceToken.balanceOfAt(msg.sender, snapshotBlock)
        // Here, we use current balance for simplicity, assuming snapshot was current.
        uint256 voteWeight = governanceToken.balanceOf(msg.sender);
        require(voteWeight > 0, "Must hold governance tokens to vote"); // Redundant check due to modifier, but good practice

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

     /// @notice Check if a proposal has met quorum and majority threshold.
     /// @param proposalId The ID of the proposal.
     /// @return bool True if the proposal succeeded based on votes and quorum.
    function checkProposalSucceeded(uint256 proposalId) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state != ProposalState.Pending && proposal.state != ProposalState.Active && proposal.state != ProposalState.Executed, "Proposal not in final state"); // Should only call after voting deadline

        if (proposal.state == ProposalState.Succeeded) return true;
        if (proposal.state == ProposalState.Failed) return false;

        // Calculate quorum based on snapshot total supply
        uint256 quorumVotes = (proposal.totalVotingSupplySnapshot * governanceParameters[PARAM_QUORUM_NUMERATOR]) / governanceParameters[PARAM_QUORUM_DENOMINATOR];

        // Check quorum
        if (proposal.votesFor + proposal.votesAgainst < quorumVotes) {
            return false; // Did not meet quorum
        }

        // Check majority (> 50% of votes cast must be FOR)
        if (proposal.votesFor > proposal.votesAgainst) {
            return true; // Majority FOR
        } else {
             return false; // Majority AGAINST or tied
        }
    }


    /// @notice Updates the state of a proposal based on the voting outcome after the deadline.
    /// @dev Can be called by anyone after the voting deadline.
    /// @param proposalId The ID of the proposal.
    function updateProposalState(uint256 proposalId) external nonReentrancy {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.state == ProposalState.Active, "Proposal not active");
         require(block.timestamp > proposal.votingDeadline, "Voting period not ended");

         bool succeeded = checkProposalSucceeded(proposalId); // Use the check function

         if (succeeded) {
             proposal.state = ProposalState.Succeeded;
             emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
         } else {
             proposal.state = ProposalState.Failed;
             emit ProposalStateChanged(proposalId, ProposalState.Failed);
         }
    }


    /// @notice Execute a successful proposal.
    /// @dev Can be called by anyone after the proposal has succeeded.
    /// Requires the target contract and call data to be valid.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external nonReentrancy {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal has not succeeded");

        proposal.state = ProposalState.Executed; // Set to executed immediately to prevent re-execution
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        // Execute the proposed action
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "Proposal execution failed");

        // If the proposal was to set a parameter, capture the name and value for event/tracking
        // This requires knowing the ABI of setParameter and decoding callData.
        // A robust implementation would decode or have a separate governance action enum.
        // For this example, we'll emit a generic event or rely on the target contract's event.
        // If the target *is* this contract and the call is setParameter, we could try to decode.
        // Example (simplified):
        // if (proposal.targetContract == address(this) && proposal.callData.length >= 4 && proposal.callData[:4] == abi.encodeWithSignature("setParameter(string,uint256)")[:4]) {
        //    // Requires decoding logic here
        //    // emit ParameterChanged(...)
        // }


        emit ProposalExecuted(proposalId);
    }

    /// @notice Allows governance to set a governance parameter.
    /// @dev Only callable via a successful governance proposal execution.
    /// @param paramName The name of the parameter to set.
    /// @param newValue The new value for the parameter.
    function setParameter(string calldata paramName, uint256 newValue) external nonReentrancy {
        // In a real DAO, this should check if the call originated from a successful proposal execution
        // For this example, we'll check if `msg.sender` is the owner, assuming ownership is transferred
        // to the governance contract or a multisig controlled by governance after deployment.
        // A more robust check involves comparing msg.sender with the address that holds the execution power.
        // For now, let's assume `owner()` is set to the executor address after setup.
        require(msg.sender == owner(), "Only callable by authorized executor");

        // Basic validation for some parameters
        if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_PROVIDER_SLASH_PERCENT)) ||
            keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_VERIFIER_SLASH_PERCENT)) ||
            keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_TASK_REWARD_PROVIDER_PERCENT)) ||
            keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_TASK_REWARD_VERIFIER_PERCENT))) {
             require(newValue <= 10000, "Percentage parameters must be <= 10000 (100%)");
        }
         if (keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_TASK_REWARD_PROVIDER_PERCENT)) ||
            keccak256(abi.encodePacked(paramName)) == keccak256(abi.encodePacked(PARAM_TASK_REWARD_VERIFIER_PERCENT))) {
             // Ensure reward percentages don't exceed 100% combined (though this logic is better in finalizeTask)
         }

        governanceParameters[paramName] = newValue;
        emit ParameterChanged(paramName, newValue);
    }


    // --- Agent NFT (ERC721) Functions (already have standard ones + 1 custom) ---

    /// @notice Update the metadata URI for an Agent NFT.
    /// @dev Can be called by the token owner or the contract itself (e.g., on reputation change).
    /// Allows dynamic metadata linked to on-chain state.
    /// @param agentId The ID of the Agent NFT.
    /// @param newURI The new metadata URI.
     function updateAgentNFTMetadataURI(uint256 agentId, string calldata newURI) external {
        // Only the token owner or the contract owner/governance executor can call this
        require(_isApprovedOrOwner(_msgSender(), agentId) || msg.sender == owner(), "Not authorized to update metadata"); // owner() check for governance execution

        _setTokenURI(agentId, newURI);
         // Consider emitting an event here if ERC721 base doesn't already
    }

    // ERC721 standard functions like `ownerOf`, `balanceOf`, `transferFrom`, `safeTransferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `tokenURI` are inherited and count towards the function count conceptually, but we list the ones specific to this contract's logic. Let's list some standard ones explicitly or ensure we have enough other distinct functions. We have 7 participant/stake, 7 task, 5 governance, 1 custom NFT update. That's 20. Plus queries and admin. We are well over 20.

    // --- Query Functions (6 functions) ---

    /// @notice Get the current reputation score for an address.
    /// @param participant The address to query.
    /// @return The reputation score.
    function getReputationScore(address participant) external view returns (int256) {
        return reputation[participant];
    }

    /// @notice Get details for a specific task.
    /// @param taskId The ID of the task.
    /// @return Task struct details.
    function getTaskDetails(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }

    /// @notice Get participant information.
    /// @param participant The address to query.
    /// @return Participant struct details.
    function getParticipantInfo(address participant) external view returns (Participant memory) {
        return participants[participant];
    }

     /// @notice Get details for a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct details (excluding the hasVoted mapping).
     function getProposalDetails(uint256 proposalId) external view returns (
         uint256 id,
         address proposer,
         string memory description,
         address targetContract,
         uint256 votesFor,
         uint256 votesAgainst,
         uint256 totalVotingSupplySnapshot,
         uint256 votingDeadline,
         ProposalState state
     ) {
         Proposal storage p = proposals[proposalId];
         return (
             p.id,
             p.proposer,
             p.description,
             p.targetContract,
             p.votesFor,
             p.votesAgainst,
             p.totalVotingSupplySnapshot,
             p.votingDeadline,
             p.state
         );
     }

    /// @notice Get the current value of a governance parameter.
    /// @param paramName The name of the parameter.
    /// @return The current value.
    function getParameter(string calldata paramName) external view returns (uint256) {
        return governanceParameters[paramName];
    }

    /// @notice Get the Agent NFT ID for a compute provider address.
    /// @param provider The address of the compute provider.
    /// @return The Agent NFT ID (0 if not registered or no NFT).
    function getAgentNFTId(address provider) external view returns (uint256) {
        return participants[provider].agentNFTId;
    }

     /// @notice Get the metadata URI for a specific Agent NFT.
     /// @dev Uses the standard ERC721 tokenURI function. Included here for clarity in summary.
     /// @param tokenId The ID of the Agent NFT.
     /// @return The metadata URI.
    function getAgentNFTMetadataURI(uint256 tokenId) external view returns (string memory) {
         return tokenURI(tokenId); // Calls inherited ERC721URIStorage function
    }


    // --- Administrative Functions (2 functions + Inherited Ownable/Pausable) ---

    /// @notice Pause contract operations.
    /// @dev Only callable by the owner (or eventually governance).
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpause contract operations.
    /// @dev Only callable by the owner (or eventually governance).
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // Standard ERC721 overrides required by compiler
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(ERC721URIStorage).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Fallback/Receive (Optional but good practice) ---
    // receive() external payable {
    //     revert("Cannot send ETH directly"); // Or handle ETH payments if needed
    // }

    // fallback() external payable {
    //      revert("Cannot send ETH directly or call unknown function");
    // }
}
```