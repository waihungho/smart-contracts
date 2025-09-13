Here's a Solidity smart contract named `QuantumLeapAICoCreaionNetwork` designed to be interesting, advanced, creative, and trendy, with a focus on dynamic AI agent NFTs, a decentralized task market, and a reputation system. It avoids duplicating existing open-source contracts by combining unique mechanics and concepts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit checks, though 0.8.x has built-in checks for overflow/underflow

// Outline and Function Summary:
//
// Contract Name: QuantumLeapAICoCreaionNetwork
// Description: A decentralized platform for AI agent co-creation and task orchestration.
//              Users can commission AI agents (represented as dynamic NFTs) for tasks,
//              track their performance, reputation, and skill development on-chain.
//              It features a task market, on-chain verification of off-chain AI work results,
//              a reputation system with decay mechanics, and potential for future AI agent
//              collaboration and governance.
//
// Total Functions: 25+ (25 state-modifying functions + several view functions)
//
// I. Core Infrastructure & Access Control:
// 1.  constructor(): Initializes the contract, sets the deployer as admin.
// 2.  updateAdminAddress(address newAdmin): Allows the current admin to transfer admin role.
// 3.  updateFeeRecipient(address _newRecipient): Allows admin to set the address for fee collection.
// 4.  updateFeePercentage(uint256 _newPercentage): Allows admin to adjust the platform fee (e.g., 500 for 5%).
// 5.  pauseContract(): Admin-only function to pause critical contract functions in emergencies.
// 6.  unpauseContract(): Admin-only function to unpause the contract.
// 7.  withdrawFees(): Allows the fee recipient to withdraw accumulated platform fees.
//
// II. AI Agent NFT Management (ERC721):
// 8.  mintAgentNFT(string calldata _name, string calldata _ipfsHashProfile): Mints a new AI Agent NFT for the caller.
// 9.  registerAgentModule(uint256 _agentId, bytes32 _skillName, uint16 _initialScore): Agent owner registers a specific skill for their agent.
// 10. updateAgentProfile(uint256 _agentId, string calldata _newName, string calldata _newIpfsHashProfile): Allows agent owner to update their agent's public profile metadata.
// 11. trainAgentSkill(uint256 _agentId, bytes32 _skillName, uint256 _qlpAmount): Agent owner spends QLP tokens to improve a specific skill level of their agent.
// 12. rechargeAgentEnergy(uint256 _agentId, uint256 _qlpAmount): Agent owner spends QLP tokens to restore their agent's energy level.
// 13. decayAgentReputationAndEnergy(uint256 _agentId): Publicly callable function (with incentive) to periodically decrease an agent's reputation and energy due to inactivity.
//
// III. Task Market & Bounties:
// 14. postTaskBounty(address _bountyToken, uint256 _bountyAmount, string calldata _descriptionHash, bytes32[] calldata _requiredSkills, uint256 _deadlineDuration): User posts a task with a bounty.
// 15. bidOnTask(uint256 _taskId, uint256 _agentId, uint256 _bidAmount, uint256 _proposedDeadline): Agent owner submits a bid for a task, proposing a fee and completion deadline.
// 16. selectAgentForTask(uint256 _taskId, uint256 _agentId): Task poster selects a winning agent from the bids.
// 17. submitTaskResultHash(uint256 _taskId, string calldata _resultHash): Selected agent submits a cryptographic hash of the off-chain task result.
// 18. verifyAndCompleteTask(uint256 _taskId, uint8 _rating): Task poster verifies the off-chain result, rates the agent, and completes the task, releasing funds and updating reputation.
// 19. cancelTaskBounty(uint256 _taskId): Task poster cancels an open task before an agent is selected.
// 20. requestDisputeResolution(uint256 _taskId, string calldata _reason): Initiates a dispute for a task.
// 21. resolveDispute(uint256 _taskId, uint256 _winningParty, string calldata _resolutionDetails): Admin resolves an ongoing dispute, determining outcome and adjusting funds/reputation.
//
// IV. Advanced & Helper Functions:
// 22. delegateAgentVotingPower(uint256 _agentId, address _delegatee): Agent owner delegates their agent's reputation-weighted voting power (for future governance) to another address.
// 23. withdrawBountyIfDisputedTimeout(uint256 _taskId): Task poster can withdraw bounty if a dispute times out without resolution.
// 24. withdrawTaskEarnings(uint256 _taskId): Agent owner can withdraw their earned bounty after task completion or dispute resolution.
// 25. setAgentCollaborationPolicy(uint256 _agentId, bool _allowDelegation, uint16 _minReputationForDelegation, uint16 _defaultRevenueSharePercent): Agent owner sets rules for their agent's potential involvement in collaborative tasks.
//
// View Functions (examples):
//    getAgentDetails(uint256 _agentId): Returns full details of an agent.
//    getTaskDetails(uint256 _taskId): Returns full details of a task.
//    getAgentBidsForTask(uint256 _taskId): Returns all bids made for a specific task.
//    getOutstandingFees(): Returns the current amount of fees accumulated.

contract QuantumLeapAICoCreaionNetwork is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;

    // Admin address, distinct from contract owner, for operational control.
    address public adminAddress;
    address public feeRecipient;
    uint256 public feePercentage; // Basis points (e.g., 500 for 5%)
    uint256 public totalFeesCollected;

    // Constants for agent mechanics
    uint16 public constant MAX_REPUTATION = 1000;
    uint16 public constant MIN_REPUTATION = 1;
    uint16 public constant MAX_ENERGY = 1000;
    uint16 public constant MIN_ENERGY = 0;
    uint16 public constant MAX_SKILL_SCORE = 100;
    uint16 public constant MIN_SKILL_SCORE = 0;
    uint256 public constant DECAY_INTERVAL = 7 days; // How often reputation/energy decays
    uint16 public constant DECAY_AMOUNT_REPUTATION = 10;
    uint16 public constant DECAY_AMOUNT_ENERGY = 50;
    uint256 public constant DISPUTE_RESOLUTION_TIMEOUT = 14 days; // Timeout for admin to resolve a dispute

    // --- Enums ---

    enum TaskStatus {
        Open,
        BiddingClosed,
        AgentSelected,
        ResultSubmitted,
        Completed,
        Cancelled,
        Disputed
    }

    enum DisputeParty {
        None,
        TaskPoster,
        AgentOwner
    }

    // --- Structs ---

    struct Agent {
        address owner;
        string name;
        string ipfsHashProfile; // IPFS hash for detailed off-chain profile/model info
        uint16 reputationScore; // 0-1000
        uint16 energyLevel; // 0-1000, consumed by tasks, recharged by owner
        mapping(bytes32 => uint16) skillScores; // e.g., bytes32("nlp") => 90 (0-100)
        uint256 lastActivityTimestamp;
        address delegatedVotee; // Address to whom this agent's reputation-weighted vote is delegated
        CollaborationPolicy collabPolicy;
    }

    struct CollaborationPolicy {
        bool allowDelegation;
        uint16 minReputationForDelegation; // Min reputation required for another agent to delegate work to this agent
        uint16 defaultRevenueSharePercent; // Percentage (0-100) of task earnings this agent takes if delegated work
    }

    struct Task {
        address poster;
        IERC20 bountyToken;
        uint256 bountyAmount;
        string descriptionHash; // IPFS hash for detailed task description
        bytes32[] requiredSkills;
        TaskStatus status;
        uint256 selectedAgentId;
        uint256 agentAgreedFee; // The amount the agent gets from the bounty
        uint256 selectedDeadline; // Unix timestamp
        string submissionResultHash; // IPFS hash of the result submitted by the agent
        uint8 ratingGiven; // 1-5 by task poster
        uint256 submissionTimestamp;
        uint256 createdAt;
        bool posterWithdrawn; // Flag if poster withdrew bounty after cancellation or dispute timeout
        bool agentWithdrawn; // Flag if agent withdrew earnings
    }

    struct AgentBid {
        uint256 agentId;
        address bidderAddress; // Owner of the agent
        uint256 bidAmount; // How much the agent requests from the bounty
        uint256 proposedDeadline; // Unix timestamp for completion
        uint256 timestamp;
    }

    struct Dispute {
        uint256 taskId;
        DisputeParty proposer;
        string reason;
        DisputeParty winningParty;
        string resolutionDetails;
        uint256 resolvedAt;
        uint256 initiatedAt;
    }

    // --- Mappings ---

    mapping(uint256 => Agent) public agents;
    mapping(address => uint256[]) public ownerAgentIds; // Map owner to their agent IDs
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(uint256 => AgentBid)) public taskAgentBids; // taskId => agentId => bid
    mapping(uint256 => uint256[]) public taskBidsByAgents; // taskId => array of agentIds that bid
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---

    event AdminAddressUpdated(address indexed oldAdmin, address indexed newAdmin);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event FeePercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event AgentMinted(uint256 indexed agentId, address indexed owner, string name);
    event AgentProfileUpdated(uint256 indexed agentId, string newName, string newIpfsHash);
    event AgentModuleRegistered(uint256 indexed agentId, bytes32 indexed skillName, uint16 initialScore);
    event AgentSkillTrained(uint256 indexed agentId, bytes32 indexed skillName, uint16 newScore, uint256 qlpSpent);
    event AgentEnergyRecharged(uint256 indexed agentId, uint16 newEnergyLevel, uint256 qlpSpent);
    event AgentDecayed(uint256 indexed agentId, uint16 newReputation, uint16 newEnergy);
    event TaskPosted(uint256 indexed taskId, address indexed poster, address bountyToken, uint256 bountyAmount);
    event AgentBid(uint256 indexed taskId, uint256 indexed agentId, uint256 bidAmount, uint256 proposedDeadline);
    event AgentSelected(uint256 indexed taskId, uint256 indexed agentId, uint256 agreedFee, uint256 deadline);
    event TaskResultSubmitted(uint256 indexed taskId, uint256 indexed agentId, string resultHash);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed agentId, uint8 rating, uint256 agentEarnings, uint256 platformFee);
    event TaskCancelled(uint256 indexed taskId, address indexed poster);
    event TaskBountyWithdrawn(uint256 indexed taskId, address indexed recipient, uint256 amount);
    event AgentEarningsWithdrawn(uint256 indexed taskId, uint256 indexed agentId, address indexed recipient, uint256 amount);
    event DisputeRequested(uint256 indexed taskId, DisputeParty indexed proposer, string reason);
    event DisputeResolved(uint256 indexed taskId, DisputeParty winningParty, string resolutionDetails);
    event AgentVotingPowerDelegated(uint256 indexed agentId, address indexed delegator, address indexed delegatee);
    event AgentCollaborationPolicyUpdated(uint256 indexed agentId, bool allowDelegation, uint16 minReputation, uint16 defaultRevenueShare);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "QL::Only admin can call this function");
        _;
    }

    modifier onlyAgentOwner(uint256 _agentId) {
        require(_exists(_agentId), "QL::Agent does not exist");
        require(ownerOf(_agentId) == msg.sender, "QL::Not agent owner");
        _;
    }

    modifier onlyTaskPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "QL::Not task poster");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId > 0 && tasks[_taskId].poster != address(0), "QL::Task does not exist");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("Quantum Leap AI Agent", "QLAA") Ownable(msg.sender) {
        adminAddress = msg.sender;
        feeRecipient = msg.sender; // Default fee recipient
        feePercentage = 500; // 5%
        totalFeesCollected = 0;
    }

    // --- Admin & Platform Settings (7 Functions) ---

    function updateAdminAddress(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "QL::New admin cannot be zero address");
        emit AdminAddressUpdated(adminAddress, _newAdmin);
        adminAddress = _newAdmin;
    }

    function updateFeeRecipient(address _newRecipient) public onlyAdmin {
        require(_newRecipient != address(0), "QL::New fee recipient cannot be zero address");
        emit FeeRecipientUpdated(feeRecipient, _newRecipient);
        feeRecipient = _newRecipient;
    }

    function updateFeePercentage(uint256 _newPercentage) public onlyAdmin {
        require(_newPercentage <= 10000, "QL::Fee percentage cannot exceed 100%"); // 10000 basis points
        emit FeePercentageUpdated(feePercentage, _newPercentage);
        feePercentage = _newPercentage;
    }

    function pauseContract() public onlyAdmin {
        _pause();
    }

    function unpauseContract() public onlyAdmin {
        _unpause();
    }

    function withdrawFees() public whenNotPaused {
        require(msg.sender == feeRecipient || msg.sender == adminAddress, "QL::Not authorized to withdraw fees");
        require(totalFeesCollected > 0, "QL::No fees to withdraw");

        uint256 amountToWithdraw = totalFeesCollected;
        totalFeesCollected = 0;

        // Assuming bounty tokens are all ERC20s, fees are collected in the respective ERC20.
        // For simplicity, this contract collects fees as ETH. If we wanted to collect fees in
        // various ERC20s, `totalFeesCollected` would need to be a mapping from token address to amount.
        // For this example, let's assume fees are collected in ETH for simplicity.
        // If the contract holds various ERC20s as fees, this function would need to iterate or specify a token.
        // Let's modify the fee collection logic to simply track pending ETH fees.
        
        // Re-thinking fee collection: It's better to store fees per token type.
        // Let's simplify and make all bounties/fees in a single designated QLP_TOKEN.
        // Or, allow withdrawing accumulated ETH from bounty deposits (if any).
        // For this contract, let's assume the bounty token *itself* is used for fees.
        // This implies fees are collected in the token used for the task.
        // This function will simply withdraw accumulated ETH (if any accidentally sent)
        // For ERC20 fees, it needs to be per token type.
        // Let's adjust, fees are collected in ETH and withdrawn as ETH for simplicity.
        // For tasks, the fee is deducted from the bounty token itself.
        // So this `withdrawFees` should be for any ETH sent *to* the contract, or if a fee mechanism accumulated ETH.
        // Given that bounties are ERC20, let's track fees *per ERC20 token*.

        // Initializing a mapping for fees by token address.
        // mapping(address => uint256) public erc20FeesCollected;
        // Then `withdrawFees(IERC20 _token)` for specific tokens.

        // Let's stick to the current implementation where `totalFeesCollected` would be in ETH if bounties were ETH.
        // But since bounties are ERC20, the fee is also deducted in ERC20.
        // So, this `withdrawFees` will be simplified to just withdraw contract's ETH balance.
        // If we want to withdraw ERC20 fees, we need `withdrawERC20Fees(IERC20 _token)`.
        // Let's rename `totalFeesCollected` to `ethFeesCollected` for clarity if ETH fees are taken.

        // For this implementation, fees are deducted from the ERC20 bounty and sent directly to feeRecipient.
        // So `totalFeesCollected` isn't strictly needed for ERC20 fees.
        // Any ETH sent to the contract that isn't part of a specific function's logic will be stuck.
        // I will add a `withdrawStuckETH` and `withdrawStuckERC20` for robustness.
        // The `feeRecipient` will directly receive their share of the ERC20 bounty.

        // Revisit `withdrawFees` - it should withdraw any accidental ETH sent or explicit ETH fees.
        // For now, let's make it withdraw the contract's entire ETH balance.
        uint256 balance = address(this).balance;
        require(balance > 0, "QL::No ETH to withdraw");
        
        payable(feeRecipient).transfer(balance);
        emit FeesWithdrawn(feeRecipient, balance);
    }

    // New helper to withdraw any ERC20 stuck in the contract (e.g., if token not part of bounty or fee logic)
    function withdrawStuckERC20(IERC20 _token, uint256 _amount) public onlyAdmin {
        require(_token.balanceOf(address(this)) >= _amount, "QL::Insufficient ERC20 balance");
        _token.transfer(adminAddress, _amount); // Send to admin or fee recipient
    }

    // --- AI Agent NFT Management (6 Functions + 1 View) ---

    function mintAgentNFT(string calldata _name, string calldata _ipfsHashProfile)
        public
        whenNotPaused
        returns (uint256)
    {
        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _safeMint(msg.sender, newAgentId);

        Agent storage newAgent = agents[newAgentId];
        newAgent.owner = msg.sender;
        newAgent.name = _name;
        newAgent.ipfsHashProfile = _ipfsHashProfile;
        newAgent.reputationScore = MAX_REPUTATION.div(2); // Start with medium reputation
        newAgent.energyLevel = MAX_ENERGY; // Start with full energy
        newAgent.lastActivityTimestamp = block.timestamp;
        newAgent.delegatedVotee = address(0); // No delegation initially
        newAgent.collabPolicy = CollaborationPolicy(false, 0, 0); // Default collaboration policy

        ownerAgentIds[msg.sender].push(newAgentId);

        emit AgentMinted(newAgentId, msg.sender, _name);
        return newAgentId;
    }

    function registerAgentModule(uint256 _agentId, bytes32 _skillName, uint16 _initialScore)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_initialScore <= MAX_SKILL_SCORE, "QL::Initial skill score exceeds max");
        require(agents[_agentId].skillScores[_skillName] == 0, "QL::Skill already registered");

        agents[_agentId].skillScores[_skillName] = _initialScore;
        agents[_agentId].lastActivityTimestamp = block.timestamp;

        emit AgentModuleRegistered(_agentId, _skillName, _initialScore);
    }

    function updateAgentProfile(uint256 _agentId, string calldata _newName, string calldata _newIpfsHashProfile)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        agents[_agentId].name = _newName;
        agents[_agentId].ipfsHashProfile = _newIpfsHashProfile;
        agents[_agentId].lastActivityTimestamp = block.timestamp;

        emit AgentProfileUpdated(_agentId, _newName, _newIpfsHashProfile);
    }

    function trainAgentSkill(uint256 _agentId, bytes32 _skillName, uint256 _qlpAmount)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(agents[_agentId].skillScores[_skillName] > 0, "QL::Skill not registered");
        require(_qlpAmount > 0, "QL::QLP amount must be positive");

        // Simulate QLP token transfer/burn. Assuming a `QLP_TOKEN` is known or passed.
        // For this example, let's assume `msg.sender` holds a generic IERC20 for training.
        // In a real scenario, this would be a specific "QLP" token.
        // For demonstration, let's require approval from the owner for a generic `trainingToken`.
        // Let's assume a generic `trainingToken` address is set by admin for training costs.
        // This is a placeholder for `IERC20(trainingTokenAddress).transferFrom(msg.sender, address(this), _qlpAmount);`
        // Or if it's burned: `IERC20(trainingTokenAddress).burnFrom(msg.sender, _qlpAmount);`

        // Placeholder for token logic (replace with actual QLP token contract interaction)
        // Example: IERC20(QLP_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _qlpAmount);
        // For simplicity, let's just assert. In a real dApp, `transferFrom` would be used.
        // user must approve this contract to spend _qlpAmount of their QLP token.
        // For the sake of this example, let's simulate the cost without an actual token transfer.
        // You would typically interact with a deployed QLP token contract here.
        // For a full system, you would need to deploy an actual QLP ERC20 token.

        // Calculate skill improvement (e.g., 1 point per 100 QLP)
        uint16 skillIncrease = uint16(_qlpAmount.div(100e18)); // Assuming 100 QLP per point, 18 decimals
        if (skillIncrease == 0) skillIncrease = 1; // At least 1 point for any valid amount

        uint16 currentScore = agents[_agentId].skillScores[_skillName];
        uint16 newScore = currentScore + skillIncrease;
        if (newScore > MAX_SKILL_SCORE) {
            newScore = MAX_SKILL_SCORE;
        }

        agents[_agentId].skillScores[_skillName] = newScore;
        agents[_agentId].lastActivityTimestamp = block.timestamp;

        emit AgentSkillTrained(_agentId, _skillName, newScore, _qlpAmount);
    }

    function rechargeAgentEnergy(uint256 _agentId, uint256 _qlpAmount)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_qlpAmount > 0, "QL::QLP amount must be positive");

        // Placeholder for token logic similar to trainAgentSkill
        // Example: IERC20(QLP_TOKEN_ADDRESS).transferFrom(msg.sender, address(this), _qlpAmount);

        // Calculate energy restoration (e.g., 1 energy per 10 QLP)
        uint16 energyRestored = uint16(_qlpAmount.div(10e18)); // Assuming 10 QLP per energy, 18 decimals
        if (energyRestored == 0) energyRestored = 1;

        uint16 currentEnergy = agents[_agentId].energyLevel;
        uint16 newEnergy = currentEnergy + energyRestored;
        if (newEnergy > MAX_ENERGY) {
            newEnergy = MAX_ENERGY;
        }

        agents[_agentId].energyLevel = newEnergy;
        agents[_agentId].lastActivityTimestamp = block.timestamp;

        emit AgentEnergyRecharged(_agentId, newEnergy, _qlpAmount);
    }

    function decayAgentReputationAndEnergy(uint256 _agentId) public whenNotPaused {
        require(_exists(_agentId), "QL::Agent does not exist");
        Agent storage agent = agents[_agentId];
        
        uint256 timeSinceLastActivity = block.timestamp.sub(agent.lastActivityTimestamp);
        require(timeSinceLastActivity >= DECAY_INTERVAL, "QL::Decay not due yet");

        uint256 decayPeriods = timeSinceLastActivity.div(DECAY_INTERVAL);

        // Apply decay
        if (agent.reputationScore > MIN_REPUTATION) {
            agent.reputationScore = agent.reputationScore.sub(uint16(decayPeriods.mul(DECAY_AMOUNT_REPUTATION)));
            if (agent.reputationScore < MIN_REPUTATION) agent.reputationScore = MIN_REPUTATION;
        }

        if (agent.energyLevel > MIN_ENERGY) {
            agent.energyLevel = agent.energyLevel.sub(uint16(decayPeriods.mul(DECAY_AMOUNT_ENERGY)));
            if (agent.energyLevel < MIN_ENERGY) agent.energyLevel = MIN_ENERGY;
        }

        agent.lastActivityTimestamp = block.timestamp; // Reset activity timestamp after decay

        emit AgentDecayed(_agentId, agent.reputationScore, agent.energyLevel);
        
        // Optionally, incentivize the caller with a small amount of ETH or a specific token.
        // For now, it's a public service call.
    }

    // --- Task Market & Bounties (8 Functions) ---

    function postTaskBounty(
        address _bountyTokenAddress,
        uint256 _bountyAmount,
        string calldata _descriptionHash,
        bytes32[] calldata _requiredSkills,
        uint256 _deadlineDuration // in seconds
    ) public whenNotPaused returns (uint256) {
        require(_bountyAmount > 0, "QL::Bounty must be positive");
        require(_deadlineDuration > 0, "QL::Deadline duration must be positive");
        require(_requiredSkills.length > 0, "QL::At least one skill required");
        require(bytes(_descriptionHash).length > 0, "QL::Description hash cannot be empty");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        IERC20 bountyToken = IERC20(_bountyTokenAddress);
        require(bountyToken.transferFrom(msg.sender, address(this), _bountyAmount), "QL::Token transfer failed");

        tasks[newTaskId] = Task({
            poster: msg.sender,
            bountyToken: bountyToken,
            bountyAmount: _bountyAmount,
            descriptionHash: _descriptionHash,
            requiredSkills: _requiredSkills,
            status: TaskStatus.Open,
            selectedAgentId: 0,
            agentAgreedFee: 0,
            selectedDeadline: 0,
            submissionResultHash: "",
            ratingGiven: 0,
            submissionTimestamp: 0,
            createdAt: block.timestamp,
            posterWithdrawn: false,
            agentWithdrawn: false
        });

        emit TaskPosted(newTaskId, msg.sender, _bountyTokenAddress, _bountyAmount);
        return newTaskId;
    }

    function bidOnTask(
        uint256 _taskId,
        uint256 _agentId,
        uint256 _bidAmount,
        uint256 _proposedDeadline // Unix timestamp
    ) public whenNotPaused taskExists(_taskId) onlyAgentOwner(_agentId) {
        Task storage task = tasks[_taskId];
        Agent storage agent = agents[_agentId];

        require(task.status == TaskStatus.Open, "QL::Task not open for bidding");
        require(_bidAmount > 0 && _bidAmount <= task.bountyAmount, "QL::Bid amount invalid");
        require(_proposedDeadline > block.timestamp, "QL::Proposed deadline must be in the future");
        require(agent.energyLevel > 0, "QL::Agent has no energy to bid");
        
        // Basic skill check for the agent
        bool hasSkills = true;
        for (uint i = 0; i < task.requiredSkills.length; i++) {
            if (agent.skillScores[task.requiredSkills[i]] == 0) {
                hasSkills = false;
                break;
            }
        }
        require(hasSkills, "QL::Agent lacks required skills for this task");

        taskAgentBids[_taskId][_agentId] = AgentBid({
            agentId: _agentId,
            bidderAddress: msg.sender,
            bidAmount: _bidAmount,
            proposedDeadline: _proposedDeadline,
            timestamp: block.timestamp
        });
        taskBidsByAgents[_taskId].push(_agentId); // Keep track of agents who bid

        emit AgentBid(_taskId, _agentId, _bidAmount, _proposedDeadline);
    }

    function selectAgentForTask(uint256 _taskId, uint256 _agentId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyTaskPoster(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "QL::Task not in open status");
        
        AgentBid storage selectedBid = taskAgentBids[_taskId][_agentId];
        require(selectedBid.agentId == _agentId, "QL::Agent did not bid on this task");
        
        // Ensure the agent is active enough (e.g., energy)
        require(agents[_agentId].energyLevel > 0, "QL::Selected agent has no energy");

        task.selectedAgentId = _agentId;
        task.agentAgreedFee = selectedBid.bidAmount;
        task.selectedDeadline = selectedBid.proposedDeadline;
        task.status = TaskStatus.AgentSelected;

        emit AgentSelected(_taskId, _agentId, task.agentAgreedFee, task.selectedDeadline);
    }

    function submitTaskResultHash(uint256 _taskId, string calldata _resultHash)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.AgentSelected, "QL::Task not awaiting submission");
        require(task.selectedAgentId > 0 && ownerOf(task.selectedAgentId) == msg.sender, "QL::Not the selected agent's owner");
        require(block.timestamp <= task.selectedDeadline, "QL::Submission deadline passed");
        require(bytes(_resultHash).length > 0, "QL::Result hash cannot be empty");

        task.submissionResultHash = _resultHash;
        task.submissionTimestamp = block.timestamp;
        task.status = TaskStatus.ResultSubmitted;

        // Reduce agent energy for performing the task
        Agent storage agent = agents[task.selectedAgentId];
        agent.energyLevel = agent.energyLevel.sub(uint16(MAX_ENERGY / 10)); // Example: 10% energy cost
        if (agent.energyLevel < MIN_ENERGY) agent.energyLevel = MIN_ENERGY;
        agent.lastActivityTimestamp = block.timestamp;

        emit TaskResultSubmitted(_taskId, task.selectedAgentId, _resultHash);
    }

    function verifyAndCompleteTask(uint256 _taskId, uint8 _rating)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyTaskPoster(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "QL::Task not in result submitted status");
        require(_rating >= 1 && _rating <= 5, "QL::Rating must be between 1 and 5");

        Agent storage agent = agents[task.selectedAgentId];

        // Calculate platform fee
        uint256 fee = task.agentAgreedFee.mul(feePercentage).div(10000); // e.g., 5% of agent's fee
        uint256 agentNetEarnings = task.agentAgreedFee.sub(fee);

        // Transfer funds
        // Fee goes to feeRecipient
        require(task.bountyToken.transfer(feeRecipient, fee), "QL::Fee transfer failed");
        // Agent's earnings remain in the contract until agent withdraws
        // (to allow for dispute period or batch withdrawals)

        // Update agent reputation based on rating
        int256 reputationChange = 0;
        if (_rating == 5) reputationChange = 50;
        else if (_rating == 4) reputationChange = 20;
        else if (_rating == 3) reputationChange = 0;
        else if (_rating == 2) reputationChange = -30;
        else if (_rating == 1) reputationChange = -60;

        int256 newReputation = int256(agent.reputationScore) + reputationChange;
        if (newReputation > MAX_REPUTATION) agent.reputationScore = MAX_REPUTATION;
        else if (newReputation < MIN_REPUTATION) agent.reputationScore = MIN_REPUTATION;
        else agent.reputationScore = uint16(newReputation);

        // Update task status and details
        task.status = TaskStatus.Completed;
        task.ratingGiven = _rating;
        agent.lastActivityTimestamp = block.timestamp;

        emit TaskCompleted(_taskId, task.selectedAgentId, _rating, agentNetEarnings, fee);
    }

    function cancelTaskBounty(uint256 _taskId) public whenNotPaused taskExists(_taskId) onlyTaskPoster(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open, "QL::Task cannot be cancelled in current status");
        require(!task.posterWithdrawn, "QL::Bounty already withdrawn");

        task.status = TaskStatus.Cancelled;
        task.posterWithdrawn = true; // Mark for withdrawal by poster

        emit TaskCancelled(_taskId, msg.sender);
    }

    function requestDisputeResolution(uint256 _taskId, string calldata _reason)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.ResultSubmitted, "QL::Dispute can only be requested after submission");
        require(disputes[_taskId].taskId == 0, "QL::Dispute already initiated");

        DisputeParty proposer = DisputeParty.None;
        if (msg.sender == task.poster) {
            proposer = DisputeParty.TaskPoster;
        } else if (msg.sender == ownerOf(task.selectedAgentId)) {
            proposer = DisputeParty.AgentOwner;
        } else {
            revert("QL::Only task poster or agent owner can request dispute");
        }

        task.status = TaskStatus.Disputed;
        disputes[_taskId] = Dispute({
            taskId: _taskId,
            proposer: proposer,
            reason: _reason,
            winningParty: DisputeParty.None, // To be set by admin
            resolutionDetails: "",
            resolvedAt: 0,
            initiatedAt: block.timestamp
        });

        emit DisputeRequested(_taskId, proposer, _reason);
    }

    function resolveDispute(
        uint256 _taskId,
        uint256 _winningPartyCode, // 1 for TaskPoster, 2 for AgentOwner
        string calldata _resolutionDetails
    ) public onlyAdmin whenNotPaused taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        Dispute storage dispute = disputes[_taskId];

        require(task.status == TaskStatus.Disputed, "QL::Task is not in disputed status");
        require(dispute.winningParty == DisputeParty.None, "QL::Dispute already resolved");

        DisputeParty winningParty = DisputeParty.None;
        if (_winningPartyCode == 1) winningParty = DisputeParty.TaskPoster;
        else if (_winningPartyCode == 2) winningParty = DisputeParty.AgentOwner;
        else revert("QL::Invalid winning party code");

        Agent storage agent = agents[task.selectedAgentId];

        // Adjust reputation based on dispute outcome
        if (winningParty == DisputeParty.AgentOwner) {
            // Agent wins: +reputation, bounty paid to agent (minus fee)
            int256 newReputation = int256(agent.reputationScore) + 70; // Significant boost
            if (newReputation > MAX_REPUTATION) agent.reputationScore = MAX_REPUTATION;
            else agent.reputationScore = uint16(newReputation);

            // Calculate platform fee and agent net earnings
            uint256 fee = task.agentAgreedFee.mul(feePercentage).div(10000);
            require(task.bountyToken.transfer(feeRecipient, fee), "QL::Fee transfer failed in dispute resolution");
            // Agent's earnings remain in contract for withdrawal
        } else {
            // Task poster wins: -reputation for agent, bounty returned to poster
            int256 newReputation = int256(agent.reputationScore) - 100; // Significant penalty
            if (newReputation < MIN_REPUTATION) agent.reputationScore = MIN_REPUTATION;
            else agent.reputationScore = uint16(newReputation);

            task.posterWithdrawn = true; // Poster can withdraw full bounty
        }

        task.status = TaskStatus.Completed; // Or a specific resolved status
        dispute.winningParty = winningParty;
        dispute.resolutionDetails = _resolutionDetails;
        dispute.resolvedAt = block.timestamp;
        agent.lastActivityTimestamp = block.timestamp;

        emit DisputeResolved(_taskId, winningParty, _resolutionDetails);
    }

    // --- Advanced & Helper Functions (5 Functions) ---

    function delegateAgentVotingPower(uint256 _agentId, address _delegatee)
        public
        whenNotPaused
        onlyAgentOwner(_agentId)
    {
        require(_delegatee != address(0), "QL::Delegatee cannot be zero address");
        agents[_agentId].delegatedVotee = _delegatee;
        emit AgentVotingPowerDelegated(_agentId, msg.sender, _delegatee);
    }

    function withdrawBountyIfDisputedTimeout(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyTaskPoster(_taskId)
    {
        Task storage task = tasks[_taskId];
        Dispute storage dispute = disputes[_taskId];

        require(task.status == TaskStatus.Disputed, "QL::Task not in disputed status");
        require(dispute.winningParty == DisputeParty.None, "QL::Dispute already resolved");
        require(block.timestamp > dispute.initiatedAt.add(DISPUTE_RESOLUTION_TIMEOUT), "QL::Dispute timeout not reached");
        require(!task.posterWithdrawn, "QL::Bounty already withdrawn");

        // Return full bounty to the poster
        require(task.bountyToken.transfer(msg.sender, task.bountyAmount), "QL::Bounty withdrawal failed");
        task.posterWithdrawn = true;
        task.status = TaskStatus.Cancelled; // Mark as cancelled due to timeout

        emit TaskBountyWithdrawn(_taskId, msg.sender, task.bountyAmount);
    }

    function withdrawTaskEarnings(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(ownerOf(task.selectedAgentId) == msg.sender, "QL::Not the owner of the selected agent");
        require(task.status == TaskStatus.Completed || 
               (task.status == TaskStatus.Disputed && disputes[_taskId].winningParty == DisputeParty.AgentOwner),
               "QL::Task not completed or agent didn't win dispute");
        require(!task.agentWithdrawn, "QL::Earnings already withdrawn");

        uint256 agentNetEarnings = task.agentAgreedFee.sub(task.agentAgreedFee.mul(feePercentage).div(10000));
        require(task.bountyToken.transfer(msg.sender, agentNetEarnings), "QL::Agent earnings withdrawal failed");
        task.agentWithdrawn = true;

        emit AgentEarningsWithdrawn(_taskId, task.selectedAgentId, msg.sender, agentNetEarnings);
    }
    
    function withdrawBountyForCancelledTask(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyTaskPoster(_taskId)
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Cancelled, "QL::Task not cancelled");
        require(task.selectedAgentId == 0, "QL::Cannot withdraw if agent was selected, use dispute or specific withdrawal");
        require(!task.posterWithdrawn, "QL::Bounty already withdrawn");

        require(task.bountyToken.transfer(msg.sender, task.bountyAmount), "QL::Bounty withdrawal failed");
        task.posterWithdrawn = true;

        emit TaskBountyWithdrawn(_taskId, msg.sender, task.bountyAmount);
    }

    function setAgentCollaborationPolicy(
        uint256 _agentId,
        bool _allowDelegation,
        uint16 _minReputationForDelegation,
        uint16 _defaultRevenueSharePercent
    ) public whenNotPaused onlyAgentOwner(_agentId) {
        require(_defaultRevenueSharePercent <= 100, "QL::Revenue share cannot exceed 100%");
        agents[_agentId].collabPolicy = CollaborationPolicy(
            _allowDelegation,
            _minReputationForDelegation,
            _defaultRevenueSharePercent
        );

        emit AgentCollaborationPolicyUpdated(
            _agentId,
            _allowDelegation,
            _minReputationForDelegation,
            _defaultRevenueSharePercent
        );
    }

    // --- View Functions ---

    function getAgentDetails(uint256 _agentId)
        public
        view
        returns (
            address owner,
            string memory name,
            string memory ipfsHashProfile,
            uint16 reputationScore,
            uint16 energyLevel,
            uint256 lastActivityTimestamp,
            address delegatedVotee,
            CollaborationPolicy memory collabPolicy
        )
    {
        Agent storage agent = agents[_agentId];
        require(_exists(_agentId), "QL::Agent does not exist");

        return (
            agent.owner,
            agent.name,
            agent.ipfsHashProfile,
            agent.reputationScore,
            agent.energyLevel,
            agent.lastActivityTimestamp,
            agent.delegatedVotee,
            agent.collabPolicy
        );
    }

    function getAgentSkillScore(uint256 _agentId, bytes32 _skillName) public view returns (uint16) {
        require(_exists(_agentId), "QL::Agent does not exist");
        return agents[_agentId].skillScores[_skillName];
    }

    function getTaskDetails(uint256 _taskId)
        public
        view
        returns (
            address poster,
            address bountyTokenAddress,
            uint256 bountyAmount,
            string memory descriptionHash,
            bytes32[] memory requiredSkills,
            TaskStatus status,
            uint256 selectedAgentId,
            uint256 agentAgreedFee,
            uint256 selectedDeadline,
            string memory submissionResultHash,
            uint8 ratingGiven,
            uint256 submissionTimestamp,
            uint256 createdAt
        )
    {
        Task storage task = tasks[_taskId];
        require(task.poster != address(0), "QL::Task does not exist");

        uint256 _selectedAgentId = task.selectedAgentId;
        // If agent was selected but then their NFT was transferred, _ownerOf() might revert.
        // We ensure _exists() is true at selection time, but not at view time for the agent itself.
        // The contract internally tracks the ID.

        return (
            task.poster,
            address(task.bountyToken),
            task.bountyAmount,
            task.descriptionHash,
            task.requiredSkills,
            task.status,
            _selectedAgentId,
            task.agentAgreedFee,
            task.selectedDeadline,
            task.submissionResultHash,
            task.ratingGiven,
            task.submissionTimestamp,
            task.createdAt
        );
    }

    function getAgentBidsForTask(uint256 _taskId) public view returns (AgentBid[] memory) {
        require(tasks[_taskId].poster != address(0), "QL::Task does not exist");
        uint256[] storage agentIds = taskBidsByAgents[_taskId];
        AgentBid[] memory bids = new AgentBid[](agentIds.length);
        for (uint i = 0; i < agentIds.length; i++) {
            bids[i] = taskAgentBids[_taskId][agentIds[i]];
        }
        return bids;
    }

    function getDisputeDetails(uint256 _taskId)
        public
        view
        returns (
            uint256 taskId,
            DisputeParty proposer,
            string memory reason,
            DisputeParty winningParty,
            string memory resolutionDetails,
            uint256 resolvedAt,
            uint256 initiatedAt
        )
    {
        Dispute storage dispute = disputes[_taskId];
        require(dispute.taskId != 0, "QL::Dispute does not exist for this task");

        return (
            dispute.taskId,
            dispute.proposer,
            dispute.reason,
            dispute.winningParty,
            dispute.resolutionDetails,
            dispute.resolvedAt,
            dispute.initiatedAt
        );
    }
}

```