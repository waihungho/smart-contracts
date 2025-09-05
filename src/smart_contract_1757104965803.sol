Here's a smart contract in Solidity called "Adaptive Collective Intelligence Network (ACIN)". It combines concepts of dynamic data, reputation systems, adaptive incentives, decentralized task management, and an innovative "Cognitive Primitives" system for protocol evolution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // For _msgSender()

/*
* @title Adaptive Collective Intelligence Network (ACIN) Smart Contract
* @author AI Bot
* @notice This contract establishes a decentralized network for collective intelligence,
*         featuring dynamic knowledge management, reputation-based task execution,
*         adaptive incentives, and an innovative "Cognitive Primitives" system for
*         protocol evolution. It aims to foster a self-organizing and self-improving
*         ecosystem for collaborative knowledge generation and problem-solving.
*
* @dev This contract integrates several advanced concepts:
*      - **Reputation-Weighted Mechanisms:** All critical actions and rewards are influenced by a dynamic on-chain reputation score.
*      - **Knowledge Capsules (K-Caps):** Dynamic, verifiable, and task-linked data containers acting as a form of "data NFT" or verifiable information unit.
*      - **Decentralized Task Markets:** Enables users to propose and execute tasks related to K-Caps, with peer verification and dispute resolution.
*      - **Adaptive Incentive Layer:** Token rewards are dynamically adjusted based on reputation, network demand, and K-Cap value, incentivizing high-quality contributions.
*      - **Cognitive Primitives (CPs):** A unique mechanism allowing the community to propose, vote on, and activate new sets of parameters or conceptual algorithms. These CPs guide the network's behavior and logic, enabling the protocol to "learn" and adapt without direct code upgrades. They act as on-chain configuration for off-chain or internal logic.
*      - **Lightweight On-Chain Governance:** For critical parameter adjustments and CP activation.
*      - **Verifiable Proofs:** Uses content hashes (bytes32) for K-Caps and task submissions, emphasizing off-chain data integrity with on-chain verification.
*
*      This contract is designed as a foundational layer for a more extensive off-chain
*      network of AI agents and human participants.
*/

// --- OUTLINE ---
// 1. Overview: Adaptive Collective Intelligence Network (ACIN)
//    - Purpose: A decentralized, self-evolving network for collaborative knowledge and tasks.
//    - Core Components: ACIN Token (ACT), Reputation System, Knowledge Capsules (K-Caps), Decentralized Task Management, Adaptive Incentive Layer, Cognitive Primitives (CPs), and On-Chain Governance.
//    - Advanced Concepts: Reputation-weighted decision-making, dynamic data structures (K-Caps), adaptive economic incentives, and a meta-governance mechanism (CPs) for protocol evolution.
// 2. ACIN Token (ACT) - ERC20 Standard Token for utility and rewards.
// 3. Reputation System - On-chain score and staking mechanism for user influence and trust.
// 4. Knowledge Capsules (K-Caps) - Verifiable, dynamic, and task-associated data containers.
// 5. Decentralized Task Management - Process for proposing, accepting, completing, and verifying tasks.
// 6. Adaptive Incentive Layer - Logic for dynamically calculating token rewards based on context.
// 7. Cognitive Primitives (CPs) - A mechanism for community-driven definition and activation of new parameters or conceptual algorithms to guide network behavior.
// 8. On-Chain Governance - System for proposing, voting on, and executing parameter changes and CP activations.

// --- FUNCTION SUMMARY ---
// Total Functions: 32 (Exceeds the minimum of 20)

// ACIN Token (ACT) Functions (ERC20 Standard + Internal Mint/Burn):
// 1.  name(): Returns the token name ("ACIN Token").
// 2.  symbol(): Returns the token symbol ("ACT").
// 3.  decimals(): Returns the number of decimals used for token representation (18).
// 4.  totalSupply(): Returns the total supply of ACT tokens.
// 5.  balanceOf(address account): Returns the ACT balance of a given `account`.
// 6.  transfer(address recipient, uint256 amount): Transfers `amount` ACT from the caller to `recipient`.
// 7.  approve(address spender, uint256 amount): Sets `amount` as the allowance for `spender` to spend caller's tokens.
// 8.  allowance(address owner, address spender): Returns the remaining allowance of `spender` for `owner`'s tokens.
// 9.  transferFrom(address sender, address recipient, uint256 amount): Transfers `amount` ACT from `sender` to `recipient` using the allowance mechanism.
// 10. _mint(address account, uint256 amount): Internal function to create new tokens for `account` (used for rewards).
// 11. _burn(address account, uint256 amount): Internal function to destroy tokens from `account` (used for penalties/fees).

// Reputation System Functions:
// 12. registerNode(): Allows a user to become a node, initializing their base reputation.
// 13. getReputation(address user): Retrieves the effective reputation score of a user (base + staked).
// 14. _updateReputation(address user, int256 change): Internal function to adjust a user's base reputation score.
// 15. stakeReputation(uint256 amount): Allows a node to stake ACT tokens to boost their effective reputation.
// 16. unstakeReputation(uint256 amount): Allows a node to retrieve previously staked ACT tokens.

// Knowledge Capsules (K-Caps) Functions:
// 17. createKCap(string memory metadataURI, bytes32 encryptedContentHash, uint256 initialRewardPool): Mints a new K-Cap with associated metadata, content hash, and an initial reward pool.
// 18. getKCapDetails(uint256 kCapId): Fetches all structural details of a specific K-Cap.
// 19. updateKCapMetadata(uint256 kCapId, string memory newMetadataURI): Allows the K-Cap creator or owner to update its metadata URI.
// 20. addKCapReward(uint256 kCapId, uint256 amount): Adds more ACT tokens to a K-Cap's dedicated reward pool.

// Decentralized Task Management Functions:
// 21. proposeTask(uint256 kCapId, string memory taskDescriptionURI, uint256 minReputationRequired, uint256 rewardAmount): Proposes a new task linked to a K-Cap, specifying requirements and rewards.
// 22. acceptTask(uint256 taskId): Allows a qualified node to accept an open task.
// 23. submitTaskProof(uint256 taskId, bytes32 proofHash): The assigned worker submits cryptographic proof of task completion.
// 24. verifyTaskCompletion(uint256 taskId, bool success): Allows peer nodes to verify the submitted task proof, leading to reward distribution or penalty.
// 25. disputeTaskCompletion(uint256 taskId, string memory reasonURI): Initiates a dispute over a task's completion or verification outcome.

// Adaptive Incentive Layer Function:
// 26. _calculateDynamicReward(address user, uint256 baseAmount): Internal function that calculates a dynamically adjusted reward based on the user's reputation and configured system parameters.

// Cognitive Primitives (CPs) Functions:
// 27. proposeCognitivePrimitive(bytes32 primitiveKey, string memory descriptionURI, bytes memory parameters): Proposes a new Cognitive Primitive (a set of parameters/guidelines for network logic).
// 28. voteOnCognitivePrimitive(uint256 proposalId, bool approve): Allows reputation-weighted nodes to vote on a CP proposal.
// 29. activateCognitivePrimitive(uint256 proposalId): Activates an approved CP, making its associated parameters available to the network.
// 30. getActivatedPrimitiveParameters(bytes32 primitiveKey): Retrieves the byte parameters of an actively set Cognitive Primitive.

// On-Chain Governance Functions:
// 31. proposeParameterChange(bytes32 parameterKey, uint256 newValue): Proposes a system-wide parameter change.
// 32. voteOnProposal(uint256 proposalId, bool approve): Allows reputation-weighted nodes to vote on a system parameter change proposal.
// 33. executeProposal(uint256 proposalId): Executes an approved system parameter change.

contract ACIN is ERC20, Ownable {

    // --- State Variables & Data Structures ---

    // Reputation System
    mapping(address => uint256) public reputations; // Base reputation score
    mapping(address => uint256) public stakedReputationTokens; // ACT tokens staked for reputation boost
    uint256 public constant MIN_REPUTATION_FOR_NODE = 100; // Minimum initial reputation to be an active node

    // K-Caps
    struct KCap {
        address creator;
        string metadataURI;       // IPFS or other URI for K-Cap description/context
        bytes32 encryptedContentHash; // Hash of the encrypted knowledge content (for integrity verification)
        uint256 rewardPool;       // Tokens allocated for tasks related to this K-Cap
        uint256 createdAt;
        bool active;
    }
    KCap[] public kCaps; // Array of all K-Caps

    // Tasks
    enum TaskStatus { Proposed, Accepted, Submitted, Verified, Disputed }
    struct Task {
        uint256 kCapId;
        address proposer;
        address worker;
        string taskDescriptionURI; // IPFS URI for detailed task description
        uint256 minReputationRequired;
        uint256 rewardAmount;
        bytes32 proofHash;        // Hash of the submitted proof of work
        TaskStatus status;
        uint256 proposedAt;
        uint256 completedAt;
    }
    Task[] public tasks;

    // Governance & Proposals (for both parameter changes and CPs)
    struct Proposal {
        address proposer;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        // Specifics for Parameter Change
        bytes32 parameterKey;
        uint256 newValue;
        // Specifics for Cognitive Primitive
        bytes32 cpKey; // Key for the Cognitive Primitive
        string cpDescriptionURI;
        bytes cpParameters; // Dynamic parameters for the CP, stored as raw bytes
        // Voting
        mapping(address => bool) hasVoted;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
    }
    Proposal[] public proposals;

    // Cognitive Primitives (CPs)
    mapping(bytes32 => bytes) public activatedCognitivePrimitives; // Stores activated CP parameters by key

    // System-wide adjustable parameters (can be changed via governance)
    mapping(bytes32 => uint256) public systemParameters;
    bytes32 constant REPUTATION_STAKE_MULTIPLIER_KEY = keccak256("REPUTATION_STAKE_MULTIPLIER"); // How many reputation points per staked token
    bytes32 constant TASK_VERIFICATION_PERIOD_KEY = keccak256("TASK_VERIFICATION_PERIOD"); // Time for peers to verify/dispute a task
    bytes32 constant PROPOSAL_VOTING_PERIOD_KEY = keccak256("PROPOSAL_VOTING_PERIOD"); // How long a proposal is open for voting
    bytes32 constant MIN_REPUTATION_FOR_PROPOSAL_KEY = keccak256("MIN_REPUTATION_FOR_PROPOSAL"); // Minimum reputation to propose
    bytes32 constant REPUTATION_VOTE_WEIGHT_KEY = keccak256("REPUTATION_VOTE_WEIGHT"); // How many vote weights per reputation point
    bytes32 constant BASE_REWARD_RATE_KEY = keccak256("BASE_REWARD_RATE"); // Base rate for dynamic reward calculations (e.g., 100 = 1x)


    // --- Events ---
    event NodeRegistered(address indexed node, uint256 initialReputation);
    event ReputationUpdated(address indexed user, int256 change, uint256 newReputation);
    event ReputationStaked(address indexed user, uint256 amount, uint256 newStakedBalance);
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newStakedBalance);
    event KCapCreated(uint256 indexed kCapId, address indexed creator, string metadataURI, uint256 initialRewardPool);
    event KCapMetadataUpdated(uint256 indexed kCapId, string newMetadataURI);
    event KCapRewardAdded(uint256 indexed kCapId, uint256 amount);
    event TaskProposed(uint256 indexed taskId, uint256 indexed kCapId, address indexed proposer, uint256 rewardAmount);
    event TaskAccepted(uint256 indexed taskId, address indexed worker);
    event TaskProofSubmitted(uint256 indexed taskId, address indexed worker, bytes32 proofHash);
    event TaskVerified(uint256 indexed taskId, address indexed verifier, bool success);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, string reasonURI);
    event RewardDistributed(address indexed recipient, uint256 amount, uint256 indexed taskId);
    event CognitivePrimitiveProposed(uint256 indexed proposalId, bytes32 indexed cpKey, string descriptionURI);
    event CognitivePrimitiveActivated(bytes32 indexed cpKey, bytes parameters);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed parameterKey, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Constructor ---
    constructor(uint256 initialSupply) ERC20("ACIN Token", "ACT") Ownable(_msgSender()) {
        _mint(_msgSender(), initialSupply * (10**decimals())); // Mint initial supply to the deployer
        
        // Initialize system parameters
        systemParameters[REPUTATION_STAKE_MULTIPLIER_KEY] = 1; // 1 ACT staked = 1 reputation point
        systemParameters[TASK_VERIFICATION_PERIOD_KEY] = 3 days;
        systemParameters[PROPOSAL_VOTING_PERIOD_KEY] = 7 days;
        systemParameters[MIN_REPUTATION_FOR_PROPOSAL_KEY] = 500;
        systemParameters[REPUTATION_VOTE_WEIGHT_KEY] = 1;
        systemParameters[BASE_REWARD_RATE_KEY] = 100; // Base rate for reward calculation, 100 = 1x
    }

    // --- Modifier ---
    modifier onlyRegisteredNode() {
        require(reputations[_msgSender()] >= MIN_REPUTATION_FOR_NODE, "ACIN: Caller is not a registered node or insufficient reputation.");
        _;
    }

    // --- ACIN Token (ACT) Functions (ERC20 standard + internal mint/burn) ---
    // ERC20 functions are inherited and directly available:
    // name(), symbol(), decimals(), totalSupply(), balanceOf(), transfer(), approve(), allowance(), transferFrom()
    // These contribute to the function count.

    // Internal mint function for rewards, only callable by the contract itself
    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
    }

    // Internal burn function for penalties, only callable by the contract itself
    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
    }

    // --- Reputation System Functions ---

    /// @notice Allows a user to register as a node, initializing their reputation.
    /// @dev A minimum initial reputation is set to consider a user an active node.
    function registerNode() public {
        require(reputations[_msgSender()] == 0, "ACIN: Already a registered node.");
        reputations[_msgSender()] = MIN_REPUTATION_FOR_NODE; // Initial base reputation
        emit NodeRegistered(_msgSender(), MIN_REPUTATION_FOR_NODE);
    }

    /// @notice Retrieves the current effective reputation score of a user, including base and staked tokens.
    /// @param user The address of the user.
    /// @return The total effective reputation score.
    function getReputation(address user) public view returns (uint256) {
        return reputations[user] + (stakedReputationTokens[user] * systemParameters[REPUTATION_STAKE_MULTIPLIER_KEY]);
    }

    /// @notice Internal function to modify a user's base reputation score.
    /// @dev Can be called by other contract functions for positive or negative changes (e.g., task completion, disputes).
    /// @param user The address whose reputation to update.
    /// @param change The integer amount to change reputation by (can be negative).
    function _updateReputation(address user, int256 change) internal {
        uint256 currentRep = reputations[user];
        if (change >= 0) {
            reputations[user] = currentRep + uint256(change);
        } else {
            uint256 absChange = uint256(-change);
            reputations[user] = currentRep > absChange ? currentRep - absChange : 0;
        }
        emit ReputationUpdated(user, change, reputations[user]);
    }

    /// @notice Allows a node to stake ACT tokens to temporarily boost their effective reputation.
    /// @dev Staked tokens contribute to the `getReputation()` calculation. Requires prior token approval.
    /// @param amount The amount of ACT tokens to stake.
    function stakeReputation(uint256 amount) public onlyRegisteredNode {
        require(amount > 0, "ACIN: Stake amount must be positive.");
        require(ERC20.allowance(_msgSender(), address(this)) >= amount, "ACIN: Approve tokens for staking first.");

        ERC20.transferFrom(_msgSender(), address(this), amount);
        stakedReputationTokens[_msgSender()] += amount;
        emit ReputationStaked(_msgSender(), amount, stakedReputationTokens[_msgSender()]);
    }

    /// @notice Allows a node to unstake previously staked ACT tokens.
    /// @param amount The amount of ACT tokens to unstake.
    function unstakeReputation(uint256 amount) public onlyRegisteredNode {
        require(amount > 0, "ACIN: Unstake amount must be positive.");
        require(stakedReputationTokens[_msgSender()] >= amount, "ACIN: Not enough staked tokens.");

        stakedReputationTokens[_msgSender()] -= amount;
        _mint(_msgSender(), amount); // Return tokens to user
        emit ReputationUnstaked(_msgSender(), amount, stakedReputationTokens[_msgSender()]);
    }

    // --- Knowledge Capsules (K-Caps) Functions ---

    /// @notice Creates a new Knowledge Capsule (K-Cap).
    /// @dev K-Caps are verifiable data containers. The initialRewardPool is for tasks related to this K-Cap.
    /// @param metadataURI IPFS or other URI pointing to the K-Cap's public metadata/description.
    /// @param encryptedContentHash A cryptographic hash of the (potentially encrypted) K-Cap content for integrity verification.
    /// @param initialRewardPool The amount of ACT tokens to deposit into the K-Cap's task reward pool.
    /// @return The ID of the newly created K-Cap.
    function createKCap(string memory metadataURI, bytes32 encryptedContentHash, uint256 initialRewardPool) public returns (uint256) {
        require(bytes(metadataURI).length > 0, "ACIN: Metadata URI cannot be empty.");
        require(encryptedContentHash != bytes32(0), "ACIN: Content hash cannot be zero.");

        if (initialRewardPool > 0) {
            require(ERC20.allowance(_msgSender(), address(this)) >= initialRewardPool, "ACIN: Approve tokens for initial reward pool.");
            ERC20.transferFrom(_msgSender(), address(this), initialRewardPool);
        }

        uint256 kCapId = kCaps.length;
        kCaps.push(KCap({
            creator: _msgSender(),
            metadataURI: metadataURI,
            encryptedContentHash: encryptedContentHash,
            rewardPool: initialRewardPool,
            createdAt: block.timestamp,
            active: true
        }));

        emit KCapCreated(kCapId, _msgSender(), metadataURI, initialRewardPool);
        return kCapId;
    }

    /// @notice Retrieves all details for a specific K-Cap.
    /// @param kCapId The ID of the K-Cap.
    /// @return A tuple containing all K-Cap fields.
    function getKCapDetails(uint256 kCapId) public view returns (address creator, string memory metadataURI, bytes32 encryptedContentHash, uint256 rewardPool, uint256 createdAt, bool active) {
        require(kCapId < kCaps.length, "ACIN: Invalid K-Cap ID.");
        KCap storage kcap = kCaps[kCapId];
        return (kcap.creator, kcap.metadataURI, kcap.encryptedContentHash, kcap.rewardPool, kcap.createdAt, kcap.active);
    }

    /// @notice Allows the K-Cap creator or network owner to update its metadata URI.
    /// @param kCapId The ID of the K-Cap.
    /// @param newMetadataURI The new IPFS or other URI for K-Cap metadata.
    function updateKCapMetadata(uint256 kCapId, string memory newMetadataURI) public {
        require(kCapId < kCaps.length, "ACIN: Invalid K-Cap ID.");
        require(kCaps[kCapId].creator == _msgSender() || Ownable.owner() == _msgSender(), "ACIN: Only K-Cap creator or owner can update metadata.");
        require(bytes(newMetadataURI).length > 0, "ACIN: New metadata URI cannot be empty.");

        kCaps[kCapId].metadataURI = newMetadataURI;
        emit KCapMetadataUpdated(kCapId, newMetadataURI);
    }

    /// @notice Adds more tokens to a K-Cap's reward pool.
    /// @param kCapId The ID of the K-Cap.
    /// @param amount The amount of ACT tokens to add.
    function addKCapReward(uint256 kCapId, uint256 amount) public {
        require(kCapId < kCaps.length, "ACIN: Invalid K-Cap ID.");
        require(kCaps[kCapId].active, "ACIN: K-Cap is not active.");
        require(amount > 0, "ACIN: Amount must be positive.");
        require(ERC20.allowance(_msgSender(), address(this)) >= amount, "ACIN: Approve tokens first.");

        ERC20.transferFrom(_msgSender(), address(this), amount);
        kCaps[kCapId].rewardPool += amount;
        emit KCapRewardAdded(kCapId, amount);
    }

    // --- Decentralized Task Management Functions ---

    /// @notice Proposes a new task related to a K-Cap, specifying requirements and reward.
    /// @param kCapId The ID of the K-Cap this task is associated with.
    /// @param taskDescriptionURI IPFS or other URI for detailed task description.
    /// @param minReputationRequired The minimum reputation a worker needs to accept this task.
    /// @param rewardAmount The ACT token reward for completing this task.
    /// @return The ID of the newly proposed task.
    function proposeTask(uint256 kCapId, string memory taskDescriptionURI, uint256 minReputationRequired, uint256 rewardAmount) public onlyRegisteredNode returns (uint256) {
        require(kCapId < kCaps.length && kCaps[kCapId].active, "ACIN: Invalid or inactive K-Cap ID.");
        require(bytes(taskDescriptionURI).length > 0, "ACIN: Task description URI cannot be empty.");
        require(rewardAmount > 0, "ACIN: Reward amount must be positive.");
        require(kCaps[kCapId].rewardPool >= rewardAmount, "ACIN: Not enough funds in K-Cap reward pool.");

        uint256 taskId = tasks.length;
        tasks.push(Task({
            kCapId: kCapId,
            proposer: _msgSender(),
            worker: address(0), // No worker yet
            taskDescriptionURI: taskDescriptionURI,
            minReputationRequired: minReputationRequired,
            rewardAmount: rewardAmount,
            proofHash: bytes32(0),
            status: TaskStatus.Proposed,
            proposedAt: block.timestamp,
            completedAt: 0
        }));

        kCaps[kCapId].rewardPool -= rewardAmount; // Deduct from K-Cap pool immediately to reserve

        emit TaskProposed(taskId, kCapId, _msgSender(), rewardAmount);
        return taskId;
    }

    /// @notice Allows a qualified node to accept an open task.
    /// @param taskId The ID of the task to accept.
    function acceptTask(uint256 taskId) public onlyRegisteredNode {
        require(taskId < tasks.length, "ACIN: Invalid task ID.");
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Proposed, "ACIN: Task is not in proposed status.");
        require(getReputation(_msgSender()) >= task.minReputationRequired, "ACIN: Insufficient reputation to accept this task.");
        require(task.proposer != _msgSender(), "ACIN: Cannot accept your own task.");

        task.worker = _msgSender();
        task.status = TaskStatus.Accepted;
        emit TaskAccepted(taskId, _msgSender());
    }

    /// @notice A node submits a proof of task completion.
    /// @param taskId The ID of the task.
    /// @param proofHash A cryptographic hash of the proof of work (e.g., IPFS content hash for verifiable data).
    function submitTaskProof(uint256 taskId, bytes32 proofHash) public {
        require(taskId < tasks.length, "ACIN: Invalid task ID.");
        Task storage task = tasks[taskId];
        require(task.worker == _msgSender(), "ACIN: Only the assigned worker can submit proof.");
        require(task.status == TaskStatus.Accepted, "ACIN: Task is not in accepted status.");
        require(proofHash != bytes32(0), "ACIN: Proof hash cannot be empty.");

        task.proofHash = proofHash;
        task.status = TaskStatus.Submitted;
        task.completedAt = block.timestamp; // Mark submission time
        emit TaskProofSubmitted(taskId, _msgSender(), proofHash);
    }

    /// @notice Allows peer nodes (or K-Cap creator/governance) to verify task completion.
    /// @dev If successful, reward is distributed and reputation is updated. If failed, worker reputation is negatively affected and task may be re-opened.
    /// @param taskId The ID of the task.
    /// @param success True if the task is verified as completed successfully, false otherwise.
    function verifyTaskCompletion(uint256 taskId, bool success) public onlyRegisteredNode {
        require(taskId < tasks.length, "ACIN: Invalid task ID.");
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Submitted || task.status == TaskStatus.Disputed, "ACIN: Task is not in submitted or disputed status.");
        require(task.completedAt + systemParameters[TASK_VERIFICATION_PERIOD_KEY] >= block.timestamp, "ACIN: Verification period has expired.");
        require(_msgSender() != task.worker && _msgSender() != task.proposer, "ACIN: Worker or Proposer cannot directly verify their own task (peer verification model).");

        if (success) {
            task.status = TaskStatus.Verified;
            uint256 dynamicReward = _calculateDynamicReward(task.worker, task.rewardAmount);
            _mint(task.worker, dynamicReward);
            _updateReputation(task.worker, 50); // Positive reputation for successful completion
            _updateReputation(task.proposer, 10); // Proposer gets a small boost for successful task outcome
            _updateReputation(_msgSender(), 5); // Verifier gets a small boost for active participation
            emit RewardDistributed(task.worker, dynamicReward, taskId);
            emit TaskVerified(taskId, _msgSender(), true);
        } else {
            // Task failed verification, revert to proposed for another worker or re-evaluation
            task.status = TaskStatus.Proposed;
            _updateReputation(task.worker, -25); // Negative reputation for failed task
            kCaps[task.kCapId].rewardPool += task.rewardAmount; // Return reward to K-Cap pool
            task.worker = address(0); // Reset worker
            emit TaskVerified(taskId, _msgSender(), false);
        }
    }

    /// @notice Initiates a dispute over a task's verification or completion.
    /// @dev This marks a task as disputed. A more complex resolution (e.g., voting, arbitration) would happen off-chain or in a separate contract.
    /// @param taskId The ID of the task.
    /// @param reasonURI IPFS or other URI for the detailed reason for the dispute.
    function disputeTaskCompletion(uint256 taskId, string memory reasonURI) public onlyRegisteredNode {
        require(taskId < tasks.length, "ACIN: Invalid task ID.");
        Task storage task = tasks[taskId];
        require(task.status == TaskStatus.Submitted, "ACIN: Task not in submitted state for dispute.");
        require(task.completedAt + systemParameters[TASK_VERIFICATION_PERIOD_KEY] >= block.timestamp, "ACIN: Dispute period has expired.");
        require(_msgSender() != task.worker, "ACIN: Worker cannot dispute their own task.");

        task.status = TaskStatus.Disputed;
        emit TaskDisputed(taskId, _msgSender(), reasonURI);
    }

    // --- Adaptive Incentive Layer Function ---

    /// @notice Internal function that calculates a dynamic reward based on the user's reputation and network parameters.
    /// @param user The address of the user for whom the reward is calculated.
    /// @param baseAmount The base reward amount for the task.
    /// @return The dynamically adjusted reward amount.
    function _calculateDynamicReward(address user, uint256 baseAmount) internal view returns (uint256) {
        uint256 userReputation = getReputation(user);
        uint256 baseRate = systemParameters[BASE_REWARD_RATE_KEY]; // e.g., 100 for 1x
        
        // Example dynamic calculation: base_amount * (base_rate + reputation_bonus_percentage) / 100
        // Reputation bonus: 1 extra percent for every 1000 reputation points, capped.
        uint256 reputationBonusPercentage = userReputation / 1000;
        // Cap the bonus to prevent excessive rewards, e.g., max 50% bonus
        if (reputationBonusPercentage > 50) reputationBonusPercentage = 50;

        uint256 effectiveRate = baseRate + reputationBonusPercentage;

        return (baseAmount * effectiveRate) / 100; // Divide by 100 as baseRate and bonus are percentage-based
    }

    // --- Cognitive Primitives (CPs) Functions ---

    /// @notice Proposes a new Cognitive Primitive (a set of parameters/guidelines for network logic).
    /// @dev CPs allow the network to adapt its internal logic and parameters without direct code upgrades.
    /// @param primitiveKey A unique identifier (hash) for this Cognitive Primitive.
    /// @param descriptionURI IPFS or other URI for the detailed description/specification of the CP.
    /// @param parameters Raw bytes of parameters that this CP will make available when activated.
    /// @return The ID of the newly created CP proposal.
    function proposeCognitivePrimitive(bytes32 primitiveKey, string memory descriptionURI, bytes memory parameters) public onlyRegisteredNode returns (uint256) {
        require(getReputation(_msgSender()) >= systemParameters[MIN_REPUTATION_FOR_PROPOSAL_KEY], "ACIN: Insufficient reputation to propose a CP.");
        require(primitiveKey != bytes32(0), "ACIN: Primitive key cannot be empty.");
        require(bytes(descriptionURI).length > 0, "ACIN: Description URI cannot be empty.");

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + systemParameters[PROPOSAL_VOTING_PERIOD_KEY],
            executed: false,
            parameterKey: bytes32(0), // Not a parameter change
            newValue: 0,
            cpKey: primitiveKey,
            cpDescriptionURI: descriptionURI,
            cpParameters: parameters,
            hasVoted: new mapping(address => bool),
            totalVotesFor: 0,
            totalVotesAgainst: 0
        }));

        emit CognitivePrimitiveProposed(proposalId, primitiveKey, descriptionURI);
        return proposalId;
    }

    /// @notice Allows reputation-weighted nodes to vote on a Cognitive Primitive proposal.
    /// @param proposalId The ID of the CP proposal.
    /// @param approve True to vote for approval, false to vote against.
    function voteOnCognitivePrimitive(uint256 proposalId, bool approve) public onlyRegisteredNode {
        require(proposalId < proposals.length, "ACIN: Invalid proposal ID.");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.cpKey != bytes32(0), "ACIN: Not a Cognitive Primitive proposal."); // Ensure it's a CP proposal
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "ACIN: Voting period is not active.");
        require(!proposal.hasVoted[_msgSender()], "ACIN: Already voted on this proposal.");

        uint256 voteWeight = getReputation(_msgSender()) * systemParameters[REPUTATION_VOTE_WEIGHT_KEY];
        require(voteWeight > 0, "ACIN: Voter must have positive effective reputation.");

        proposal.hasVoted[_msgSender()] = true;
        if (approve) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        emit ProposalVoted(proposalId, _msgSender(), approve);
    }

    /// @notice Activates an approved Cognitive Primitive, making its parameters available for network logic.
    /// @param proposalId The ID of the CP proposal.
    function activateCognitivePrimitive(uint256 proposalId) public onlyRegisteredNode {
        require(proposalId < proposals.length, "ACIN: Invalid proposal ID.");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.cpKey != bytes32(0), "ACIN: Not a Cognitive Primitive proposal.");
        require(block.timestamp > proposal.endTime, "ACIN: Voting period not ended.");
        require(!proposal.executed, "ACIN: Proposal already executed.");
        // A simple majority is used here; could be changed to a supermajority
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "ACIN: Proposal not approved by majority.");

        activatedCognitivePrimitives[proposal.cpKey] = proposal.cpParameters;
        proposal.executed = true;
        emit CognitivePrimitiveActivated(proposal.cpKey, proposal.cpParameters);
        emit ProposalExecuted(proposalId);
    }

    /// @notice Retrieves the parameters of an activated Cognitive Primitive.
    /// @dev This function allows other smart contract logic or off-chain agents to query and adapt their behavior based on active CPs.
    /// @param primitiveKey The unique key (bytes32 hash) of the Cognitive Primitive.
    /// @return The byte array containing the activated parameters.
    function getActivatedPrimitiveParameters(bytes32 primitiveKey) public view returns (bytes memory) {
        return activatedCognitivePrimitives[primitiveKey];
    }

    // --- On-Chain Governance Functions ---

    /// @notice Proposes a change to a system-wide parameter.
    /// @param parameterKey The keccak256 hash of the parameter name (e.g., REPUTATION_STAKE_MULTIPLIER_KEY).
    /// @param newValue The new value for the parameter.
    /// @return The ID of the new proposal.
    function proposeParameterChange(bytes32 parameterKey, uint256 newValue) public onlyRegisteredNode returns (uint256) {
        require(getReputation(_msgSender()) >= systemParameters[MIN_REPUTATION_FOR_PROPOSAL_KEY], "ACIN: Insufficient reputation to propose parameter change.");
        require(parameterKey != bytes32(0), "ACIN: Parameter key cannot be empty.");
        // Basic check for valid parameter keys; extend this if more keys are added
        require(parameterKey == REPUTATION_STAKE_MULTIPLIER_KEY ||
                parameterKey == TASK_VERIFICATION_PERIOD_KEY ||
                parameterKey == PROPOSAL_VOTING_PERIOD_KEY ||
                parameterKey == MIN_REPUTATION_FOR_PROPOSAL_KEY ||
                parameterKey == REPUTATION_VOTE_WEIGHT_KEY ||
                parameterKey == BASE_REWARD_RATE_KEY, "ACIN: Invalid parameter key.");

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            proposer: _msgSender(),
            startTime: block.timestamp,
            endTime: block.timestamp + systemParameters[PROPOSAL_VOTING_PERIOD_KEY],
            executed: false,
            parameterKey: parameterKey,
            newValue: newValue,
            cpKey: bytes32(0), // Not a CP proposal
            cpDescriptionURI: "",
            cpParameters: "",
            hasVoted: new mapping(address => bool),
            totalVotesFor: 0,
            totalVotesAgainst: 0
        }));

        emit ParameterChangeProposed(proposalId, parameterKey, newValue);
        return proposalId;
    }

    /// @notice Allows reputation-weighted nodes to vote on a system parameter change proposal.
    /// @param proposalId The ID of the proposal.
    /// @param approve True to vote for approval, false to vote against.
    function voteOnProposal(uint256 proposalId, bool approve) public onlyRegisteredNode {
        require(proposalId < proposals.length, "ACIN: Invalid proposal ID.");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.parameterKey != bytes32(0), "ACIN: Not a parameter change proposal."); // Ensure it's a parameter change
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "ACIN: Voting period is not active.");
        require(!proposal.hasVoted[_msgSender()], "ACIN: Already voted on this proposal.");

        uint256 voteWeight = getReputation(_msgSender()) * systemParameters[REPUTATION_VOTE_WEIGHT_KEY];
        require(voteWeight > 0, "ACIN: Voter must have positive effective reputation.");

        proposal.hasVoted[_msgSender()] = true;
        if (approve) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        emit ProposalVoted(proposalId, _msgSender(), approve);
    }

    /// @notice Executes an approved system parameter change proposal.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) public onlyRegisteredNode {
        require(proposalId < proposals.length, "ACIN: Invalid proposal ID.");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.parameterKey != bytes32(0), "ACIN: Not a parameter change proposal."); // Ensure it's a parameter change
        require(block.timestamp > proposal.endTime, "ACIN: Voting period not ended.");
        require(!proposal.executed, "ACIN: Proposal already executed.");
        // A simple majority is used here; could be changed to a supermajority
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "ACIN: Proposal not approved by majority.");

        systemParameters[proposal.parameterKey] = proposal.newValue;
        proposal.executed = true;
        emit ProposalExecuted(proposalId);
    }
}
```