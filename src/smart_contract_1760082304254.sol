Here's a Solidity smart contract named `AetherComputeDAO` that implements advanced concepts for decentralized AI model training, ownership, and governance.

**Core Idea:** A decentralized protocol where users (Trainer Nodes) contribute computational resources to train AI models requested by others (Task Creators). The process is governed by a DAO, and successful models can be minted as NFTs, while trainer performance is managed by a dynamic reputation system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; // Use a recent stable version

// --- Interfaces ---

interface IAetherToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint222 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8); // Crucial for scaling
}

interface IAetherModelNFT {
    function mint(address to, uint256 tokenId, string calldata tokenURI) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

// --- Library for safe ERC20 interactions ---
library SafeERC20 {
    function safeTransfer(IAetherToken token, address to, uint256 value) internal {
        require(token.transfer(to, value), "SafeERC20: transfer failed");
    }

    function safeTransferFrom(IAetherToken token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value), "SafeERC20: transferFrom failed");
    }

    // safeApprove is not strictly needed for this contract's direct token interactions (receives and sends),
    // but would be important if it approved other contracts to spend its tokens.
}

/**
 * @title AetherComputeDAO
 * @dev A decentralized autonomous organization governing a protocol for
 *      decentralized AI model training and ownership.
 *      It integrates staking-based trainer nodes, a dynamic reputation system,
 *      AI model task management, and NFTization of trained models.
 *
 * @outline
 * The AetherComputeDAO facilitates a decentralized marketplace for AI model training.
 * Task Creators define and fund AI model training tasks. Trainer Nodes stake tokens
 * and use their computational resources to fulfill these tasks. A dynamic reputation
 * system rewards good performance and penalizes poor contributions. Successfully
 * trained models can be minted as unique NFTs, representing ownership or intellectual
 * property. The entire protocol is governed by the DAO through proposals and voting.
 *
 * 1.  **Core DAO Governance**: Manages proposals, voting, and execution of on-chain changes.
 * 2.  **Trainer Node Management**: Handles registration, staking, and deregistration of AI model trainers.
 * 3.  **AI Model Task Management**: Orchestrates the creation, assignment, submission, and verification of AI model training tasks.
 * 4.  **Reputation & Reward System**: Manages trainer reputation based on performance and facilitates reward distribution.
 * 5.  **NFTization of Models**: Allows for the minting of unique NFTs representing successfully trained AI models.
 *
 * @function_summary
 *
 * --- I. Core DAO Governance (5 Functions) ---
 * 1.  `propose(string calldata _title, string calldata _description, address _targetContract, bytes calldata _callData, uint256 _votingPeriodBlocks)`
 *     - **Concept**: Decentralized Governance, Parameter Updates.
 *     - Creates a new governance proposal for the DAO to vote on, allowing for on-chain modification of contract parameters or execution of arbitrary calls.
 * 2.  `vote(uint256 _proposalId, bool _support)`
 *     - **Concept**: Weighted Voting, Reputation-Based Influence.
 *     - Allows registered trainer nodes to cast their vote (for or against) on an active proposal. Voting power is dynamically calculated based on their staked tokens and current reputation score.
 * 3.  `finalizeProposal(uint256 _proposalId)`
 *     - **Concept**: State Transition, Quorum Enforcement.
 *     - Marks a proposal as 'Succeeded' or 'Failed' after its voting period ends, based on vote counts and a minimum participation quorum.
 * 4.  `queueProposal(uint256 _proposalId)`
 *     - **Concept**: Timelock, Security.
 *     - Queues a successful proposal for execution after a defined timelock, providing a grace period for review or emergency actions.
 * 5.  `executeProposal(uint256 _proposalId)`
 *     - **Concept**: Executable Governance, On-chain Automation.
 *     - Executes a queued proposal's payload (function call) after its timelock has passed, applying the approved changes to the protocol.
 *
 * --- II. Trainer Node Management (5 Functions) ---
 * 6.  `registerTrainerNode(uint256 _initialStakeAmount)`
 *     - **Concept**: Proof-of-Stake (PoS) for Participation, Sybil Resistance.
 *     - Allows an address to register as a Trainer Node by staking Aether Tokens, gaining an ID and an initial reputation score.
 * 7.  `updateNodeStake(uint256 _newStakeAmount)`
 *     - **Concept**: Dynamic Staking, Resource Commitment.
 *     - Adjusts the staked amount of an existing Trainer Node, affecting their voting power, task eligibility, and commitment to the network.
 * 8.  `deregisterTrainerNode()`
 *     - **Concept**: Cooldown Periods, Exit Scenarios.
 *     - Initiates the deregistration process for a Trainer Node, which includes a cooldown period before their full stake can be safely withdrawn, preventing sudden exits.
 * 9.  `getTrainerNodeDetails(uint256 _trainerNodeId)`
 *     - **Concept**: Transparency, Auditing.
 *     - Retrieves comprehensive details about a specific Trainer Node, including their stake, reputation, and task activity.
 * 10. `getTrainerNodeIdByAddress(address _trainerAddress)`
 *     - **Concept**: Utility Function, User Lookup.
 *     - Returns the unique ID associated with a given trainer's Ethereum address, facilitating easy lookup.
 *
 * --- III. AI Model Task Management (5 Functions) ---
 * 11. `createModelTask(uint256 _rewardAmount, uint256 _requiredStakePerTrainer, uint256 _targetAccuracy, string calldata _modelConfigCID, uint256 _submissionDeadlineBlocks)`
 *     - **Concept**: Decentralized Task Creation, Funded Tasks.
 *     - Creates a new AI model training task, specifying its requirements, Aether Token rewards, and submission deadline, funded by the task creator.
 * 12. `acceptTask(uint256 _taskId)`
 *     - **Concept**: Task Assignment, Eligibility Checks.
 *     - Allows an eligible Trainer Node to accept an available AI model training task, becoming responsible for its completion.
 * 13. `submitModelResult(uint256 _taskId, string calldata _modelResultCID, uint256 _achievedAccuracy)`
 *     - **Concept**: Off-chain Computation, On-chain Submission.
 *     - A Trainer Node submits the results (e.g., IPFS CID for model weights and achieved accuracy) for an assigned task.
 * 14. `verifyAndRewardTask(uint256 _taskId, bool _isSuccessful, uint256 _verifiedAccuracy)`
 *     - **Concept**: Oracle Integration (simulated), Incentivized Verification, Slashing.
 *     - A privileged 'Oracle' or DAO Council verifies the submitted task results, distributing rewards to successful trainers and applying penalties (slashing stake, reducing reputation) for failures.
 * 15. `getTaskDetails(uint256 _taskId)`
 *     - **Concept**: Transparency, Task Tracking.
 *     - Retrieves all relevant information about a specific AI model training task, from creation to verification.
 *
 * --- IV. Reputation & Reward System (3 Functions) ---
 * 16. `queryReputationScore(uint256 _trainerNodeId)`
 *     - **Concept**: Dynamic Reputation, Transparency.
 *     - Returns the current reputation score of a Trainer Node, which influences their voting power and task eligibility.
 * 17. `claimPendingRewards(uint256 _trainerNodeId)`
 *     - **Concept**: Reward Distribution, Safe Withdrawal.
 *     - Allows a Trainer Node to claim their accumulated Aether Token rewards, and also finalizes deregistration by returning their staked tokens if the cooldown period has passed.
 * 18. `setReputationModifier(int256 _successModifier, int256 _failureModifier)`
 *     - **Concept**: DAO-Governed Parameters, Adaptive Incentives.
 *     - A DAO-governed function to dynamically adjust the impact (positive or negative) of successful or failed tasks on trainer reputation scores, allowing the protocol to adapt its incentive structure.
 *
 * --- V. NFTization of Models (2 Functions) ---
 * 19. `mintModelNFT(uint256 _taskId, address _recipient, string calldata _ipfsHash)`
 *     - **Concept**: AI Model Ownership, Digital Assets, ERC721 Integration.
 *     - Mints a unique ERC721 NFT (representing the trained AI model) to a specified recipient after a task has been successfully verified. This NFT can represent ownership, royalties, or access to the model.
 * 20. `getMintedModelNFTInfo(uint256 _taskId)`
 *     - **Concept**: Asset Tracking, Metadata Linkage.
 *     - Retrieves the token ID and IPFS hash of the NFT associated with a successfully completed model task, linking the on-chain task to its digital asset representation.
 */
contract AetherComputeDAO {
    using SafeERC20 for IAetherToken;

    // --- State Variables ---

    IAetherToken public immutable AETHER_TOKEN;
    IAetherModelNFT public immutable AETHER_MODEL_NFT;

    address public daoCouncilAddress; // Initial admin/oracle, to be replaced by DAO governance via proposal
    uint256 public constant MIN_INITIAL_STAKE = 100 * (10**18); // Example: 100 Aether Tokens (assuming 18 decimals)
    uint256 public constant MIN_VOTE_POWER = 1 * (10**18); // Minimum vote power required to cast a vote (in scaled units)

    uint256 public nextProposalId;
    uint256 public nextTrainerNodeId;
    uint256 public nextModelTaskId;
    uint256 public nextModelNFTId; // Tracks next available NFT token ID

    // DAO Governance Parameters (can be adjusted by successful proposals)
    uint256 public proposalTimelockBlocks = 100; // Blocks required between queue and execution
    uint256 public minProposalQuorumNumerator = 4; // 4/10 = 40% quorum
    uint256 public constant QUORUM_DENOMINATOR = 10;
    int256 public reputationSuccessModifier = 50; // Points added to reputation for success
    int256 public reputationFailureModifier = -100; // Points deducted from reputation for failure

    // --- Data Structures ---

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Queued, Executed, Canceled }
    enum TaskStatus { Created, Assigned, Submitted, VerifiedSuccess, VerifiedFailure, Disputed }

    struct DAOProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address targetContract; // Contract address to interact with if proposal executes
        bytes callData;         // Encoded function call to execute
        uint256 voteStartTimeBlock;
        uint256 voteEndTimeBlock;
        uint256 snapshotVotePower; // Total *potential* vote power from active trainers at proposal creation
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProposalStatus status;
        uint256 queueTimeBlock; // Block when proposal was queued (0 if not queued)
    }
    mapping(uint256 => DAOProposal) public proposals;

    struct TrainerNode {
        uint256 id;
        address owner;
        uint256 stakedAmount; // AetherToken staked (raw amount, e.g., 100 * 10^18)
        int256 reputationScore; // Can be negative, influences voting power and task eligibility
        uint256 activeTasksCount;
        uint256 lastActivityBlock; // Block of last stake update or task submission
        bool isRegistered; // True if actively registered, false if deregistered or in cooldown
        uint256 pendingRewards; // AetherToken rewards accumulated
        uint256 deregisterCooldownBlock; // Block when deregistration cooldown is complete (0 if not in cooldown)
    }
    mapping(uint256 => TrainerNode) public trainerNodes;
    mapping(address => uint256) public addressToTrainerNodeId; // Maps owner address to their unique node ID

    struct ModelTask {
        uint256 id;
        address creator; // The address who requested/funded the task
        uint256 rewardPool; // Total AetherToken reward for this task
        uint256 requiredStakePerTrainer; // Minimum stake a trainer needs to accept this task
        uint256 targetAccuracy; // Desired accuracy (e.g., 9000 for 90.00%, scaled by 100)
        string modelConfigCID; // IPFS/Arweave CID for dataset and architecture configuration
        uint256 assignedTrainerNodeId; // ID of the trainer node assigned to this task (0 if unassigned)
        uint256 submissionDeadlineBlock; // Block by which the model results must be submitted
        string modelResultCID; // IPFS/Arweave CID for submitted model weights/result
        uint256 achievedAccuracy; // Accuracy achieved by the submitted model (scaled by 100)
        TaskStatus status;
        uint256 mintedNFTId; // ID of the NFT minted for this model (0 if no NFT minted yet)
        string mintedNFTIpfsHash; // IPFS hash stored if NFT minted
    }
    mapping(uint256 => ModelTask) public modelTasks;

    // --- Events ---

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string title, uint256 voteEndTimeBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status);
    event ProposalQueued(uint256 indexed proposalId, uint256 queueTimeBlock);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId); // Added this event for completeness

    event TrainerNodeRegistered(uint256 indexed trainerNodeId, address indexed owner, uint256 initialStake);
    event TrainerNodeStakeUpdated(uint256 indexed trainerNodeId, uint256 newStake);
    event TrainerNodeDeregistered(uint256 indexed trainerNodeId, address indexed owner, uint256 finalStake);
    event RewardsClaimed(uint256 indexed trainerNodeId, address indexed owner, uint256 amount);
    event ReputationAdjusted(uint256 indexed trainerNodeId, int256 newReputation);

    event ModelTaskCreated(uint256 indexed taskId, address indexed creator, uint256 rewardAmount);
    event ModelTaskAccepted(uint256 indexed taskId, uint256 indexed trainerNodeId);
    event ModelResultSubmitted(uint256 indexed taskId, uint256 indexed trainerNodeId, string modelResultCID, uint256 achievedAccuracy);
    event ModelTaskVerified(uint256 indexed taskId, bool isSuccessful, uint256 verifiedAccuracy);

    event ModelNFTMinted(uint256 indexed taskId, uint256 indexed nftTokenId, address indexed recipient, string ipfsHash);

    // --- Modifiers ---

    modifier onlyDaoCouncil() {
        require(msg.sender == daoCouncilAddress, "AetherComputeDAO: Only DAO council can call this function");
        _;
    }

    modifier onlyRegisteredTrainerNode() {
        require(addressToTrainerNodeId[msg.sender] != 0, "AetherComputeDAO: Not a registered trainer node");
        require(trainerNodes[addressToTrainerNodeId[msg.sender]].isRegistered, "AetherComputeDAO: Trainer node is not active");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < nextProposalId, "AetherComputeDAO: Proposal does not exist");
        _;
    }

    modifier trainerNodeExists(uint256 _trainerNodeId) {
        require(_trainerNodeId > 0 && _trainerNodeId < nextTrainerNodeId, "AetherComputeDAO: Trainer node does not exist");
        _; // Only checks existence, not necessarily if it's active or registered
    }

    modifier modelTaskExists(uint256 _taskId) {
        require(_taskId > 0 && _taskId < nextModelTaskId, "AetherComputeDAO: Model task does not exist");
        _;
    }

    // --- Constructor ---

    constructor(address _aetherTokenAddress, address _aetherModelNFTAddress) {
        require(_aetherTokenAddress != address(0), "AetherComputeDAO: Invalid Aether Token address");
        require(_aetherModelNFTAddress != address(0), "AetherComputeDAO: Invalid Aether Model NFT address");

        AETHER_TOKEN = IAetherToken(_aetherTokenAddress);
        AETHER_MODEL_NFT = IAetherModelNFT(_aetherModelNFTAddress);
        daoCouncilAddress = msg.sender; // Deployer is the initial DAO council (can be changed by proposal)
        nextProposalId = 1;
        nextTrainerNodeId = 1;
        nextModelTaskId = 1;
        nextModelNFTId = 1; // ERC721 token IDs typically start from 1 or 0
    }

    // --- I. Core DAO Governance ---

    /**
     * @dev Creates a new governance proposal for the DAO to vote on.
     *      Requires the proposer to be an active Trainer Node with stake.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposal.
     * @param _targetContract The address of the contract that the proposal aims to interact with.
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _votingPeriodBlocks The number of blocks the voting period will last.
     */
    function propose(
        string calldata _title,
        string calldata _description,
        address _targetContract,
        bytes calldata _callData,
        uint256 _votingPeriodBlocks
    ) external onlyRegisteredTrainerNode returns (uint256) {
        require(bytes(_title).length > 0, "AetherComputeDAO: Title cannot be empty");
        require(_votingPeriodBlocks > 0, "AetherComputeDAO: Voting period must be greater than 0");

        uint256 proposerNodeId = addressToTrainerNodeId[msg.sender];
        require(trainerNodes[proposerNodeId].stakedAmount > 0, "AetherComputeDAO: Proposer must have active stake");

        uint256 proposalId = nextProposalId++;
        uint256 currentBlock = block.number;

        // Snapshot total *potential* vote power at the time of proposal creation.
        // This is crucial for quorum calculation. For scalable DAOs, this would typically
        // involve a checkpointing system or a dedicated snapshot contract, rather than iterating.
        // For this example, we iterate over active nodes, which is okay for a limited number of trainers.
        uint256 totalActiveVotePower = 0;
        for (uint256 i = 1; i < nextTrainerNodeId; i++) {
            if (trainerNodes[i].isRegistered) {
                totalActiveVotePower += _getVotePower(trainerNodes[i].owner);
            }
        }
        require(totalActiveVotePower > 0, "AetherComputeDAO: No active trainer nodes with vote power to snapshot");

        DAOProposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.targetContract = _targetContract;
        newProposal.callData = _callData;
        newProposal.voteStartTimeBlock = currentBlock;
        newProposal.voteEndTimeBlock = currentBlock + _votingPeriodBlocks;
        newProposal.snapshotVotePower = totalActiveVotePower; // Represents max possible votes if all active trainers voted
        newProposal.status = ProposalStatus.Active;

        emit ProposalCreated(proposalId, msg.sender, _title, newProposal.voteEndTimeBlock);
        return proposalId;
    }

    /**
     * @dev Allows registered trainer nodes to cast their vote (for or against) on an active proposal.
     *      Voting power is calculated based on their staked tokens and reputation at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes) vote, false for 'against' (no) vote.
     */
    function vote(uint256 _proposalId, bool _support)
        external
        onlyRegisteredTrainerNode
        proposalExists(_proposalId)
    {
        DAOProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherComputeDAO: Proposal not active");
        require(block.number >= proposal.voteStartTimeBlock, "AetherComputeDAO: Voting not started yet");
        require(block.number <= proposal.voteEndTimeBlock, "AetherComputeDAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherComputeDAO: Already voted on this proposal");

        uint256 votePower = _getVotePower(msg.sender);
        require(votePower >= MIN_VOTE_POWER, "AetherComputeDAO: Insufficient vote power to cast a vote");

        if (_support) {
            proposal.votesFor += votePower;
        } else {
            proposal.votesAgainst += votePower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /**
     * @dev Marks a proposal as 'Succeeded' or 'Failed' after its voting period ends.
     *      Anyone can call this to finalize a proposal's voting outcome, provided the voting period has expired.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        DAOProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherComputeDAO: Proposal not active");
        require(block.number > proposal.voteEndTimeBlock, "AetherComputeDAO: Voting period not ended yet");

        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        require(totalVotesCast > 0, "AetherComputeDAO: No votes cast, cannot finalize");

        // Quorum check: A certain percentage of the *snapshot* total vote power must have participated
        // for the proposal to be considered valid and potentially succeed.
        require(totalVotesCast * QUORUM_DENOMINATOR >= proposal.snapshotVotePower * minProposalQuorumNumerator, "AetherComputeDAO: Quorum not met");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
        } else {
            proposal.status = ProposalStatus.Failed;
        }
        emit ProposalFinalized(_proposalId, proposal.status);
    }

    /**
     * @dev Queues a successful proposal for execution after a defined timelock.
     *      Requires the proposal to be in a 'Succeeded' state.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        DAOProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "AetherComputeDAO: Proposal must be in Succeeded state");
        require(proposal.queueTimeBlock == 0, "AetherComputeDAO: Proposal already queued");

        proposal.status = ProposalStatus.Queued;
        proposal.queueTimeBlock = block.number;
        emit ProposalQueued(_proposalId, block.number);
    }

    /**
     * @dev Executes a queued proposal's payload (function call) after its timelock has passed.
     *      Requires the proposal to be in a 'Queued' state and the timelock to have expired.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        DAOProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Queued, "AetherComputeDAO: Proposal not in Queued state");
        require(block.number >= proposal.queueTimeBlock + proposalTimelockBlocks, "AetherComputeDAO: Timelock not passed yet");

        // Execute the call on the target contract specified in the proposal.
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        require(success, "AetherComputeDAO: Proposal execution failed");

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    // --- II. Trainer Node Management ---

    /**
     * @dev Allows an address to register as a Trainer Node by staking Aether Tokens.
     *      Gains a unique ID and initial reputation.
     * @param _initialStakeAmount The amount of Aether Tokens to stake (in raw token units, e.g., 100 * 10^18 if 18 decimals).
     */
    function registerTrainerNode(uint256 _initialStakeAmount) external {
        uint256 existingNodeId = addressToTrainerNodeId[msg.sender];
        require(existingNodeId == 0 || !trainerNodes[existingNodeId].isRegistered, "AetherComputeDAO: Address already registered or recently deregistered");
        require(_initialStakeAmount >= MIN_INITIAL_STAKE, "AetherComputeDAO: Initial stake below minimum");
        
        // This is a critical token transfer. In a production system, consider OpenZeppelin's ReentrancyGuard.
        AETHER_TOKEN.safeTransferFrom(msg.sender, address(this), _initialStakeAmount);

        uint256 nodeId = nextTrainerNodeId++;
        TrainerNode storage newNode = trainerNodes[nodeId];
        newNode.id = nodeId;
        newNode.owner = msg.sender;
        newNode.stakedAmount = _initialStakeAmount;
        newNode.reputationScore = 0; // Starting reputation
        newNode.activeTasksCount = 0;
        newNode.lastActivityBlock = block.number;
        newNode.isRegistered = true;
        addressToTrainerNodeId[msg.sender] = nodeId;

        emit TrainerNodeRegistered(nodeId, msg.sender, _initialStakeAmount);
    }

    /**
     * @dev Adjusts the staked amount of an existing Trainer Node.
     *      Can increase (by transferring more tokens) or decrease (by withdrawing) stake.
     *      Decreasing stake is restricted if the trainer has active tasks.
     * @param _newStakeAmount The new total stake amount for the trainer (in raw token units).
     */
    function updateNodeStake(uint256 _newStakeAmount) external onlyRegisteredTrainerNode {
        uint256 nodeId = addressToTrainerNodeId[msg.sender];
        TrainerNode storage node = trainerNodes[nodeId];

        require(_newStakeAmount >= MIN_INITIAL_STAKE, "AetherComputeDAO: New stake below minimum");
        
        uint256 currentStake = node.stakedAmount;

        if (_newStakeAmount > currentStake) {
            uint256 amountToTransfer = _newStakeAmount - currentStake;
            AETHER_TOKEN.safeTransferFrom(msg.sender, address(this), amountToTransfer);
            node.stakedAmount = _newStakeAmount;
        } else if (_newStakeAmount < currentStake) {
            require(node.activeTasksCount == 0, "AetherComputeDAO: Cannot decrease stake with active tasks");
            uint256 amountToRefund = currentStake - _newStakeAmount;
            AETHER_TOKEN.safeTransfer(msg.sender, amountToRefund);
            node.stakedAmount = _newStakeAmount;
        }
        // If _newStakeAmount == currentStake, no change is performed.

        node.lastActivityBlock = block.number;
        emit TrainerNodeStakeUpdated(nodeId, node.stakedAmount);
    }

    /**
     * @dev Initiates the deregistration process for a Trainer Node.
     *      The node becomes inactive immediately, but their staked tokens are locked for a cooldown period.
     *      Cannot deregister if currently assigned to active tasks.
     */
    function deregisterTrainerNode() external onlyRegisteredTrainerNode {
        uint256 nodeId = addressToTrainerNodeId[msg.sender];
        TrainerNode storage node = trainerNodes[nodeId];
        require(node.activeTasksCount == 0, "AetherComputeDAO: Cannot deregister with active tasks");
        require(node.deregisterCooldownBlock == 0, "AetherComputeDAO: Already initiated deregistration"); // Not currently in a cooldown

        node.isRegistered = false; // Mark as inactive immediately
        node.deregisterCooldownBlock = block.number + 50; // Example: 50 blocks cooldown before full refund
        // Stake is not refunded immediately; it's pending claim after cooldown.

        emit TrainerNodeDeregistered(nodeId, msg.sender, node.stakedAmount);
    }

    /**
     * @dev Retrieves comprehensive details about a specific Trainer Node.
     *      Can retrieve details for both active and inactive/deregistered nodes.
     * @param _trainerNodeId The ID of the trainer node.
     * @return id, owner, stakedAmount, reputationScore, activeTasksCount, lastActivityBlock, isRegistered, pendingRewards, deregisterCooldownBlock.
     */
    function getTrainerNodeDetails(uint256 _trainerNodeId)
        external
        view
        trainerNodeExists(_trainerNodeId)
        returns (
            uint256 id,
            address owner,
            uint256 stakedAmount,
            int256 reputationScore,
            uint256 activeTasksCount,
            uint256 lastActivityBlock,
            bool isRegistered,
            uint256 pendingRewards,
            uint256 deregisterCooldownBlock
        )
    {
        TrainerNode storage node = trainerNodes[_trainerNodeId];
        return (
            node.id,
            node.owner,
            node.stakedAmount,
            node.reputationScore,
            node.activeTasksCount,
            node.lastActivityBlock,
            node.isRegistered,
            node.pendingRewards,
            node.deregisterCooldownBlock
        );
    }

    /**
     * @dev Returns the unique ID associated with a given trainer's Ethereum address.
     * @param _trainerAddress The address of the trainer.
     * @return The trainer node ID, or 0 if not registered.
     */
    function getTrainerNodeIdByAddress(address _trainerAddress) external view returns (uint256) {
        return addressToTrainerNodeId[_trainerAddress];
    }

    // --- III. AI Model Task Management ---

    /**
     * @dev Creates a new AI model training task.
     *      The creator must first approve `_rewardAmount` to this contract before calling this function.
     * @param _rewardAmount The total Aether Tokens reward for completing this task (in raw token units).
     * @param _requiredStakePerTrainer Minimum stake a trainer needs to accept this task (in raw token units).
     * @param _targetAccuracy The desired accuracy for the trained model (e.g., 9000 for 90.00%, scaled by 100).
     * @param _modelConfigCID IPFS/Arweave CID for dataset and architecture configuration, linking to off-chain data.
     * @param _submissionDeadlineBlocks The number of blocks from creation for submission.
     * @return The ID of the newly created model task.
     */
    function createModelTask(
        uint256 _rewardAmount,
        uint256 _requiredStakePerTrainer,
        uint256 _targetAccuracy,
        string calldata _modelConfigCID,
        uint256 _submissionDeadlineBlocks
    ) external returns (uint256) {
        require(_rewardAmount > 0, "AetherComputeDAO: Reward must be positive");
        require(_requiredStakePerTrainer >= MIN_INITIAL_STAKE / 2, "AetherComputeDAO: Required stake too low");
        require(_targetAccuracy > 0 && _targetAccuracy <= 10000, "AetherComputeDAO: Invalid target accuracy (0-10000)");
        require(bytes(_modelConfigCID).length > 0, "AetherComputeDAO: Model config CID cannot be empty");
        require(_submissionDeadlineBlocks > 0, "AetherComputeDAO: Submission deadline must be positive");

        AETHER_TOKEN.safeTransferFrom(msg.sender, address(this), _rewardAmount); // Transfer reward to contract

        uint256 taskId = nextModelTaskId++;
        ModelTask storage newTask = modelTasks[taskId];
        newTask.id = taskId;
        newTask.creator = msg.sender;
        newTask.rewardPool = _rewardAmount;
        newTask.requiredStakePerTrainer = _requiredStakePerTrainer;
        newTask.targetAccuracy = _targetAccuracy;
        newTask.modelConfigCID = _modelConfigCID;
        newTask.submissionDeadlineBlock = block.number + _submissionDeadlineBlocks;
        newTask.status = TaskStatus.Created;

        emit ModelTaskCreated(taskId, msg.sender, _rewardAmount);
        return taskId;
    }

    /**
     * @dev Allows an eligible Trainer Node to accept an available AI model training task.
     *      Requires the trainer to meet the minimum stake and be active.
     * @param _taskId The ID of the task to accept.
     */
    function acceptTask(uint256 _taskId) external onlyRegisteredTrainerNode modelTaskExists(_taskId) {
        ModelTask storage task = modelTasks[_taskId];
        require(task.status == TaskStatus.Created, "AetherComputeDAO: Task not available for assignment");
        require(task.assignedTrainerNodeId == 0, "AetherComputeDAO: Task already assigned");

        uint256 trainerNodeId = addressToTrainerNodeId[msg.sender];
        TrainerNode storage node = trainerNodes[trainerNodeId];

        require(node.stakedAmount >= task.requiredStakePerTrainer, "AetherComputeDAO: Insufficient stake to accept task");
        require(block.number < task.submissionDeadlineBlock, "AetherComputeDAO: Task deadline has passed for acceptance");

        task.assignedTrainerNodeId = trainerNodeId;
        task.status = TaskStatus.Assigned;
        node.activeTasksCount++;
        node.lastActivityBlock = block.number;

        emit ModelTaskAccepted(_taskId, trainerNodeId);
    }

    /**
     * @dev A Trainer Node submits the results for an assigned task.
     *      This includes the IPFS CID of the trained model and its achieved accuracy.
     * @param _taskId The ID of the task.
     * @param _modelResultCID IPFS/Arweave CID for the submitted model weights.
     * @param _achievedAccuracy The accuracy achieved by the trained model (e.g., 8800 for 88.00%, scaled by 100).
     */
    function submitModelResult(
        uint256 _taskId,
        string calldata _modelResultCID,
        uint256 _achievedAccuracy
    ) external onlyRegisteredTrainerNode modelTaskExists(_taskId) {
        ModelTask storage task = modelTasks[_taskId];
        uint256 trainerNodeId = addressToTrainerNodeId[msg.sender];

        require(task.assignedTrainerNodeId == trainerNodeId, "AetherComputeDAO: Task not assigned to this trainer");
        require(task.status == TaskStatus.Assigned, "AetherComputeDAO: Task not in Assigned state");
        require(block.number <= task.submissionDeadlineBlock, "AetherComputeDAO: Submission deadline passed");
        require(bytes(_modelResultCID).length > 0, "AetherComputeDAO: Model result CID cannot be empty");
        require(_achievedAccuracy <= 10000, "AetherComputeDAO: Invalid achieved accuracy (max 10000)");

        task.modelResultCID = _modelResultCID;
        task.achievedAccuracy = _achievedAccuracy;
        task.status = TaskStatus.Submitted;

        TrainerNode storage node = trainerNodes[trainerNodeId];
        node.lastActivityBlock = block.number;

        emit ModelResultSubmitted(_taskId, trainerNodeId, _modelResultCID, _achievedAccuracy);
    }

    /**
     * @dev A privileged 'Oracle' or DAO Council verifies the submitted task results.
     *      Distributes rewards to successful trainers and applies penalties (slashing stake, reducing reputation) for failures.
     *      This function assumes off-chain verification by a trusted entity.
     * @param _taskId The ID of the task to verify.
     * @param _isSuccessful True if the task was successfully completed according to criteria.
     * @param _verifiedAccuracy The accuracy determined by the verifier (e.g., 8800 for 88.00%, scaled by 100).
     */
    function verifyAndRewardTask(
        uint256 _taskId,
        bool _isSuccessful,
        uint256 _verifiedAccuracy
    ) external onlyDaoCouncil modelTaskExists(_taskId) {
        ModelTask storage task = modelTasks[_taskId];
        require(task.status == TaskStatus.Submitted, "AetherComputeDAO: Task not in Submitted state");

        uint256 trainerNodeId = task.assignedTrainerNodeId;
        TrainerNode storage node = trainerNodes[trainerNodeId];

        // First, update trainer's active task count.
        require(node.activeTasksCount > 0, "AetherComputeDAO: Trainer has no active tasks to complete");
        node.activeTasksCount--;

        if (_isSuccessful) {
            task.status = TaskStatus.VerifiedSuccess;
            task.achievedAccuracy = _verifiedAccuracy; // Update with verified accuracy
            node.pendingRewards += task.rewardPool; // Add full reward to trainer's pending balance
            node.reputationScore += reputationSuccessModifier; // Boost reputation
            emit ReputationAdjusted(trainerNodeId, node.reputationScore);
        } else {
            task.status = TaskStatus.VerifiedFailure;
            // Penalize trainer: slash a portion of their stake and reduce reputation
            uint222 slashAmount = node.stakedAmount / 10; // Example: 10% stake slash
            if (node.stakedAmount > slashAmount) {
                node.stakedAmount -= slashAmount;
            } else {
                node.stakedAmount = 0; // Prevent underflow if stake is very small
            }
            node.reputationScore += reputationFailureModifier; // Deduct reputation
            emit TrainerNodeStakeUpdated(trainerNodeId, node.stakedAmount); // Log new stake amount
            emit ReputationAdjusted(trainerNodeId, node.reputationScore);
        }
        node.lastActivityBlock = block.number;
        emit ModelTaskVerified(_taskId, _isSuccessful, _verifiedAccuracy);
    }

    /**
     * @dev Retrieves all relevant information about a specific AI model training task.
     * @param _taskId The ID of the model task.
     * @return id, creator, rewardPool, requiredStakePerTrainer, targetAccuracy, modelConfigCID,
     *         assignedTrainerNodeId, submissionDeadlineBlock, modelResultCID, achievedAccuracy, status,
     *         mintedNFTId, mintedNFTIpfsHash.
     */
    function getTaskDetails(uint256 _taskId)
        external
        view
        modelTaskExists(_taskId)
        returns (
            uint256 id,
            address creator,
            uint256 rewardPool,
            uint256 requiredStakePerTrainer,
            uint256 targetAccuracy,
            string memory modelConfigCID,
            uint256 assignedTrainerNodeId,
            uint256 submissionDeadlineBlock,
            string memory modelResultCID,
            uint256 achievedAccuracy,
            TaskStatus status,
            uint256 mintedNFTId,
            string memory mintedNFTIpfsHash
        )
    {
        ModelTask storage task = modelTasks[_taskId];
        return (
            task.id,
            task.creator,
            task.rewardPool,
            task.requiredStakePerTrainer,
            task.targetAccuracy,
            task.modelConfigCID,
            task.assignedTrainerNodeId,
            task.submissionDeadlineBlock,
            task.modelResultCID,
            task.achievedAccuracy,
            task.status,
            task.mintedNFTId,
            task.mintedNFTIpfsHash
        );
    }

    // --- IV. Reputation & Reward System ---

    /**
     * @dev Returns the current reputation score of a Trainer Node.
     * @param _trainerNodeId The ID of the trainer node.
     * @return The trainer's reputation score.
     */
    function queryReputationScore(uint256 _trainerNodeId)
        external
        view
        trainerNodeExists(_trainerNodeId)
        returns (int256)
    {
        return trainerNodes[_trainerNodeId].reputationScore;
    }

    /**
     * @dev Allows a Trainer Node to claim their accumulated Aether Token rewards.
     *      Also handles deregistration finalization (stake refund) if the cooldown period is over.
     * @param _trainerNodeId The ID of the trainer node.
     */
    function claimPendingRewards(uint256 _trainerNodeId) external trainerNodeExists(_trainerNodeId) {
        TrainerNode storage node = trainerNodes[_trainerNodeId];
        require(msg.sender == node.owner, "AetherComputeDAO: Only trainer node owner can claim rewards");

        uint256 totalClaimAmount = node.pendingRewards;
        node.pendingRewards = 0; // Reset pending rewards before transfer

        // If deregistration cooldown is over, add the staked amount to the total claim.
        if (!node.isRegistered && node.deregisterCooldownBlock > 0 && block.number >= node.deregisterCooldownBlock) {
            totalClaimAmount += node.stakedAmount;
            node.stakedAmount = 0; // Clear staked amount
            node.deregisterCooldownBlock = 0; // Reset cooldown flag
            delete addressToTrainerNodeId[node.owner]; // Optionally remove mapping for a completely inactive node
        } else {
             require(totalClaimAmount > 0, "AetherComputeDAO: No pending rewards or stake to claim");
        }

        AETHER_TOKEN.safeTransfer(msg.sender, totalClaimAmount); // Perform the actual token transfer
        emit RewardsClaimed(_trainerNodeId, msg.sender, totalClaimAmount);
    }

    /**
     * @dev DAO-governed function to dynamically adjust the impact of successful or failed tasks on trainer reputation.
     *      This function can only be called via a successful DAO proposal.
     * @param _successModifier The points to add for a successful task.
     * @param _failureModifier The points to deduct for a failed task.
     */
    function setReputationModifier(int256 _successModifier, int256 _failureModifier) external onlyDaoCouncil {
        reputationSuccessModifier = _successModifier;
        reputationFailureModifier = _failureModifier;
        // An event could be emitted here to log parameter changes if desired.
    }

    // --- V. NFTization of Models ---

    /**
     * @dev Mints a unique ERC721 NFT (representing the trained AI model) to a specified recipient.
     *      Only callable by the task creator or DAO Council after the task has been successfully verified.
     * @param _taskId The ID of the successfully completed model task.
     * @param _recipient The address to receive the NFT.
     * @param _ipfsHash The IPFS/Arweave hash of the finalized model for the NFT's metadata.
     */
    function mintModelNFT(uint256 _taskId, address _recipient, string calldata _ipfsHash)
        external
        modelTaskExists(_taskId)
    {
        ModelTask storage task = modelTasks[_taskId];
        require(task.status == TaskStatus.VerifiedSuccess, "AetherComputeDAO: Task must be successfully verified to mint NFT");
        require(task.mintedNFTId == 0, "AetherComputeDAO: NFT already minted for this task");
        require(msg.sender == task.creator || msg.sender == daoCouncilAddress, "AetherComputeDAO: Only task creator or DAO council can mint NFT");
        require(bytes(_ipfsHash).length > 0, "AetherComputeDAO: NFT IPFS hash cannot be empty");
        require(_recipient != address(0), "AetherComputeDAO: Invalid recipient address");

        uint256 nftTokenId = nextModelNFTId++;
        AETHER_MODEL_NFT.mint(_recipient, nftTokenId, _ipfsHash); // Call the external NFT contract to mint

        task.mintedNFTId = nftTokenId;
        task.mintedNFTIpfsHash = _ipfsHash;

        emit ModelNFTMinted(_taskId, nftTokenId, _recipient, _ipfsHash);
    }

    /**
     * @dev Retrieves the token ID and IPFS hash of the NFT associated with a successfully completed model task.
     * @param _taskId The ID of the model task.
     * @return nftTokenId The ID of the minted NFT, or 0 if none has been minted.
     * @return nftIpfsHash The IPFS hash associated with the NFT's metadata.
     */
    function getMintedModelNFTInfo(uint256 _taskId)
        external
        view
        modelTaskExists(_taskId)
        returns (uint256 nftTokenId, string memory nftIpfsHash)
    {
        ModelTask storage task = modelTasks[_taskId];
        return (task.mintedNFTId, task.mintedNFTIpfsHash);
    }

    // --- Internal / Private Helper Functions ---

    /**
     * @dev Calculates the total voting power for a given address.
     *      Voting power is derived from the trainer's staked Aether Tokens and their positive reputation score.
     *      - Staked tokens contribute directly (e.g., 1 Aether Token = 1 vote unit).
     *      - Positive reputation contributes fractionally (e.g., 100 reputation points = 1 Aether Token vote unit).
     * @param _voter The address of the voter.
     * @return The calculated total voting power (in scaled units, e.g., 10^18 for base unit).
     */
    function _getVotePower(address _voter) internal view returns (uint256) {
        uint256 nodeId = addressToTrainerNodeId[_voter];
        if (nodeId == 0 || !trainerNodes[nodeId].isRegistered) {
            return 0; // Not a registered or active trainer
        }

        TrainerNode storage node = trainerNodes[nodeId];
        
        // Staked amount is already in raw token units (e.g., 10^18 for 1 token).
        uint256 scaledStakedPower = node.stakedAmount;

        // Positive reputation contributes to vote power, scaled.
        // For example, if AETHER_TOKEN has 18 decimals, then `10**AETHER_TOKEN.decimals()` is 10^18.
        // So, `reputation / 100` means every 100 reputation points adds 1 full token's worth of vote power.
        uint256 scaledReputationPower = 0;
        if (node.reputationScore > 0) {
            scaledReputationPower = (uint256(node.reputationScore) * (10**AETHER_TOKEN.decimals())) / 100;
        }

        return scaledStakedPower + scaledReputationPower;
    }
}
```