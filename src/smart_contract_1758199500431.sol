```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title AetherSentinels - Dynamic AI-Powered Digital Companions
 * @author Your Name / AI Assistant
 * @notice AetherSentinels are dynamic NFTs representing evolving AI companions.
 *         Their personality traits change based on user interactions (training),
 *         external data feeds (environmental oracles), and delegated missions.
 *         The contract integrates simulated AI learning, gamification (XP, levels, energy),
 *         and a robust multi-role oracle and governance system for protocol evolution.
 *
 * Outline & Function Summary:
 *
 * I. Core ERC721 & Initialization:
 *    - Constructor: Initializes the contract, sets up roles (DEFAULT_ADMIN_ROLE, MINTER_ROLE).
 *    - _baseURI: Standard ERC721 metadata base URI.
 *
 * II. Sentinel State & Data Management:
 *    - mintSentinel: Mints a new Aether Sentinel NFT with initial randomized traits.
 *    - getSentinelDetails: Returns a comprehensive struct of a Sentinel's current state.
 *    - getSentinelTraits: Returns the specific personality trait values for a Sentinel.
 *    - getTraitInfluence: Returns the current global influence factor for a specific trait.
 *    - getSentinelStatus: Returns the current activity status of a Sentinel (Idle, Training, Tasked).
 *
 * III. Evolution & Gamification System:
 *    - initiateTrainingSession: Owner initiates a training session for their Sentinel.
 *    - completeTrainingSession: Callable by `TRAINER_ORACLE_ROLE` to finalize training, update traits, and grant XP.
 *    - rechargeEnergy: Owner recharges a Sentinel's energy (potentially costing ETH).
 *    - tryLevelUp: Owner attempts to level up a Sentinel if enough XP is accumulated.
 *    - delegateSentinelForTask: Owner delegates their Sentinel for a specific "mission" or "task".
 *    - finalizeDelegatedTask: Callable by `TASK_ORACLE_ROLE` to finalize a task, distribute rewards/XP, and update traits.
 *    - claimTaskReward: Owner claims the rewards from a successfully completed task.
 *
 * IV. Oracle & External Data Integration:
 *    - updateGlobalTraitInfluence: Callable by `GOVERNOR_ROLE` or `ENVIRONMENTAL_ORACLE_ROLE` to adjust global trait impacts.
 *    - submitEnvironmentalData: Callable by `ENVIRONMENTAL_ORACLE_ROLE` to feed real-world data influencing Sentinel evolution.
 *    - setOracleAddress: `DEFAULT_ADMIN_ROLE` or `GOVERNOR_ROLE` sets authorized addresses for different oracle roles.
 *
 * V. Governance & Economic Model:
 *    - proposeMissionParameters: `GOVERNOR_ROLE` proposes new mission types, their costs, and rewards.
 *    - voteOnProposal: Allows `GOVERNOR_ROLE` members to vote on active proposals.
 *    - executeProposal: Executes a successfully voted proposal (e.g., adds new mission, adjusts fees).
 *    - updateEnergyRechargeCost: `GOVERNOR_ROLE` adjusts the cost of recharging energy.
 *    - withdrawFunds: `DEFAULT_ADMIN_ROLE` or `GOVERNOR_ROLE` withdraws accumulated funds.
 *    - adjustTrainingTypeWeights: `GOVERNOR_ROLE` adjusts how different training types influence trait adjustments.
 *    - toggleGlobalFeature: A flexible `GOVERNOR_ROLE` switch to enable/disable certain protocol features.
 *
 * VI. Utility & Security:
 *    - setBaseURI: `DEFAULT_ADMIN_ROLE` sets the base URI for NFT metadata.
 *    - pause: `DEFAULT_ADMIN_ROLE` or `PAUSER_ROLE` pauses critical functions.
 *    - unpause: `DEFAULT_ADMIN_ROLE` or `PAUSER_ROLE` unpauses the contract.
 */
contract AetherSentinels is ERC721, AccessControl, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- Roles ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TRAINER_ORACLE_ROLE = keccak256("TRAINER_ORACLE_ROLE");
    bytes32 public constant TASK_ORACLE_ROLE = keccak256("TASK_ORACLE_ROLE");
    bytes32 public constant ENVIRONMENTAL_ORACLE_ROLE = keccak256("ENVIRONMENTAL_ORACLE_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _trainingSessionIdCounter;
    Counters.Counter private _delegatedTaskIdCounter;
    Counters.Counter private _missionTypeIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public constant MAX_TRAIT_VALUE = 1000;
    uint256 public constant MIN_TRAIT_VALUE = 0;
    uint256 public constant BASE_ENERGY_RECHARGE_COST = 0.01 ether; // Default ETH cost to recharge
    uint256 public constant XP_FOR_LEVEL_1 = 100; // Base XP for first level-up

    uint256 public energyRechargeCost = BASE_ENERGY_RECHARGE_COST;

    // Maps for global feature toggles
    mapping(bytes32 => bool) public globalFeatures;

    // --- Data Structures ---

    enum SentinelStatus {
        Idle,
        Training,
        Tasked
    }

    struct Traits {
        uint256 curiosity;
        uint256 empathy;
        uint256 logic;
        uint256 creativity;
        uint256 resilience;
    }

    struct Sentinel {
        uint256 tokenId;
        address owner;
        uint256 level;
        uint256 experience;
        uint256 energy; // 0-100 scale, for example
        uint256 lastEnergyRechargeBlock; // To prevent spamming recharge or calculate passive recharge
        Traits traits;
        SentinelStatus status;
        uint256 currentActivityId; // Refers to TrainingSession or DelegatedTask ID
        uint256 creationTime;
    }

    struct TrainingSession {
        uint256 sessionId;
        uint256 tokenId;
        string trainingType; // e.g., "DataAnalysis", "CreativePrompt"
        uint256 startTime;
        bool completed;
    }

    struct DelegatedTask {
        uint256 taskId;
        uint256 tokenId;
        uint256 missionTypeId; // Reference to a predefined mission type
        uint256 startTime;
        uint256 duration; // Expected duration in seconds
        string resultHash; // IPFS hash or similar for off-chain result
        uint256 rewardAmount; // Amount in ETH or internal token
        uint256 xpGained;
        bool completed;
        bool rewardsClaimed;
    }

    struct MissionType {
        string name;
        uint256 baseEnergyCost;
        uint256 baseRewardAmount; // In ETH
        uint256 baseXpReward;
        uint256 maxDuration; // In seconds
        // Instead of mapping, use a dynamic array or fixed array for simplicity and gas
        int256[] traitInfluenceWeights; // [curiosity, empathy, logic, creativity, resilience]
        bool active;
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted; // `GOVERNOR_ROLE` addresses
        uint256 creationTime;
        uint256 votingDeadline;
        bool executed;
        bool passed;
    }

    mapping(uint256 => Sentinel) public sentinels;
    mapping(uint256 => TrainingSession) public trainingSessions;
    mapping(uint256 => DelegatedTask) public delegatedTasks;
    mapping(uint256 => MissionType) public missionTypes;
    mapping(uint256 => Proposal) public proposals;

    // Global factors influencing trait effectiveness (e.g., market volatility, social mood)
    mapping(string => int256) public globalTraitInfluences; // traitName => influenceFactor

    // Weights for how different training types affect traits
    // trainingType => [curiosity, empathy, logic, creativity, resilience] weights
    mapping(string => int256[5]) public trainingTypeTraitWeights;

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, Traits initialTraits);
    event SentinelEnergyRecharged(uint256 indexed tokenId, uint256 newEnergy);
    event SentinelLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event TrainingInitiated(uint256 indexed sessionId, uint256 indexed tokenId, string trainingType);
    event TrainingCompleted(uint256 indexed sessionId, uint256 indexed tokenId, uint256 xpGained, int256[] traitAdjustments);
    event TaskDelegated(uint256 indexed taskId, uint256 indexed tokenId, uint256 missionTypeId, uint256 duration);
    event TaskFinalized(uint256 indexed taskId, uint256 indexed tokenId, string resultHash, uint256 rewardAmount, uint256 xpGained);
    event TaskRewardClaimed(uint256 indexed taskId, uint256 indexed tokenId, uint256 amount);
    event GlobalTraitInfluenceUpdated(string traitName, int256 newInfluenceFactor);
    event EnvironmentalDataSubmitted(bytes32 dataFeedId, uint256 value);
    event OracleAddressSet(bytes32 role, address oldAddress, address newAddress);
    event MissionTypeProposed(uint256 indexed proposalId, uint256 missionTypeId, string name);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event EnergyRechargeCostUpdated(uint256 newCost);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event TrainingTypeWeightsAdjusted(string trainingType, int256[5] newWeights);
    event GlobalFeatureToggled(bytes32 featureName, bool isActive);

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(GOVERNOR_ROLE, msg.sender); // Initially admin is governor

        // Initialize default global trait influences (e.g., neutral)
        globalTraitInfluences["curiosity"] = 100;
        globalTraitInfluences["empathy"] = 100;
        globalTraitInfluences["logic"] = 100;
        globalTraitInfluences["creativity"] = 100;
        globalTraitInfluences["resilience"] = 100;

        // Initialize some example training type weights (example: Data Analysis boosts Logic & Curiosity)
        trainingTypeTraitWeights["DataAnalysis"] = [50, -10, 80, 0, 10]; // C, E, L, Cr, R
        trainingTypeTraitWeights["CreativeBrainstorm"] = [30, 0, 10, 70, 0];
    }

    // --- Modifier for role-based access to set oracle addresses dynamically ---
    modifier onlyOracleRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AetherSentinels: Caller is not a designated oracle for this role");
        _;
    }

    // --- I. Core ERC721 & Initialization ---
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://base_uri_placeholder/"; // To be updated by setBaseURI
    }

    /**
     * @notice Mints a new Aether Sentinel NFT with initial randomized traits.
     * @dev Only MINTER_ROLE can call this. Traits are initialized with a base value plus a random seed influence.
     * @param _to The address to mint the Sentinel to.
     * @param _initialTraitSeed A string seed used to pseudo-randomly initialize traits.
     */
    function mintSentinel(address _to, string memory _initialTraitSeed)
        public
        onlyRole(MINTER_ROLE)
        whenNotPaused
        returns (uint256)
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Simple pseudo-random trait initialization using keccak256 hash of seed
        uint256 seedHash = uint256(keccak256(abi.encodePacked(_initialTraitSeed, block.timestamp, newTokenId)));
        
        Traits memory initialTraits = Traits({
            curiosity: (seedHash % (MAX_TRAIT_VALUE / 3)) + (MAX_TRAIT_VALUE / 3), // Base + random [1/3 to 2/3 of max]
            empathy: ((seedHash * 2) % (MAX_TRAIT_VALUE / 3)) + (MAX_TRAIT_VALUE / 3),
            logic: ((seedHash * 3) % (MAX_TRAIT_VALUE / 3)) + (MAX_TRAIT_VALUE / 3),
            creativity: ((seedHash * 4) % (MAX_TRAIT_VALUE / 3)) + (MAX_TRAIT_VALUE / 3),
            resilience: ((seedHash * 5) % (MAX_TRAIT_VALUE / 3)) + (MAX_TRAIT_VALUE / 3)
        });

        sentinels[newTokenId] = Sentinel({
            tokenId: newTokenId,
            owner: _to,
            level: 1,
            experience: 0,
            energy: 100, // Starts with full energy
            lastEnergyRechargeBlock: block.number,
            traits: initialTraits,
            status: SentinelStatus.Idle,
            currentActivityId: 0,
            creationTime: block.timestamp
        });

        _safeMint(_to, newTokenId);
        emit SentinelMinted(newTokenId, _to, initialTraits);
        return newTokenId;
    }

    // --- II. Sentinel State & Data Management ---

    /**
     * @notice Returns a comprehensive struct of a Sentinel's current state.
     * @param _tokenId The ID of the Sentinel.
     * @return Sentinel struct containing all details.
     */
    function getSentinelDetails(uint256 _tokenId) public view returns (Sentinel memory) {
        require(_exists(_tokenId), "AetherSentinels: Sentinel does not exist");
        return sentinels[_tokenId];
    }

    /**
     * @notice Returns the specific personality trait values for a Sentinel.
     * @param _tokenId The ID of the Sentinel.
     * @return Traits struct containing current trait values.
     */
    function getSentinelTraits(uint256 _tokenId) public view returns (Traits memory) {
        require(_exists(_tokenId), "AetherSentinels: Sentinel does not exist");
        return sentinels[_tokenId].traits;
    }

    /**
     * @notice Returns the current global influence factor for a specific trait.
     * @dev These factors modify how traits impact mission outcomes or evolution.
     * @param _traitName The name of the trait (e.g., "curiosity").
     * @return The influence factor (e.g., 100 for no change, 120 for 20% boost).
     */
    function getTraitInfluence(string memory _traitName) public view returns (int256) {
        return globalTraitInfluences[_traitName];
    }

    /**
     * @notice Returns the current activity status of a Sentinel.
     * @param _tokenId The ID of the Sentinel.
     * @return The SentinelStatus (Idle, Training, Tasked).
     */
    function getSentinelStatus(uint256 _tokenId) public view returns (SentinelStatus) {
        require(_exists(_tokenId), "AetherSentinels: Sentinel does not exist");
        return sentinels[_tokenId].status;
    }

    // --- Internal Helper for Trait Adjustment ---
    function _adjustTrait(uint256 _tokenId, string memory _traitName, int256 _adjustment) internal {
        Sentinel storage sentinel = sentinels[_tokenId];
        uint256 currentTraitValue;

        if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("curiosity"))) {
            currentTraitValue = sentinel.traits.curiosity;
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("empathy"))) {
            currentTraitValue = sentinel.traits.empathy;
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("logic"))) {
            currentTraitValue = sentinel.traits.logic;
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("creativity"))) {
            currentTraitValue = sentinel.traits.creativity;
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("resilience"))) {
            currentTraitValue = sentinel.traits.resilience;
        } else {
            return; // Invalid trait name
        }

        int256 newTraitValue = int256(currentTraitValue) + _adjustment;
        if (newTraitValue < int256(MIN_TRAIT_VALUE)) newTraitValue = int256(MIN_TRAIT_VALUE);
        if (newTraitValue > int256(MAX_TRAIT_VALUE)) newTraitValue = int256(MAX_TRAIT_VALUE);

        if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("curiosity"))) {
            sentinel.traits.curiosity = uint256(newTraitValue);
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("empathy"))) {
            sentinel.traits.empathy = uint256(newTraitValue);
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("logic"))) {
            sentinel.traits.logic = uint256(newTraitValue);
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("creativity"))) {
            sentinel.traits.creativity = uint256(newTraitValue);
        } else if (keccak256(abi.encodePacked(_traitName)) == keccak256(abi.encodePacked("resilience"))) {
            sentinel.traits.resilience = uint256(newTraitValue);
        }
    }


    // --- III. Evolution & Gamification System ---

    /**
     * @notice Owner initiates a training session for their Sentinel.
     * @dev Sentinel must be idle and have enough energy.
     * @param _tokenId The ID of the Sentinel to train.
     * @param _trainingType The type of training (e.g., "DataAnalysis", "CreativePrompt").
     * @param _trainingData A hash or IPFS CID of the actual training input/data.
     */
    function initiateTrainingSession(uint256 _tokenId, string memory _trainingType, bytes memory _trainingData)
        public
        onlyOwnerOf(_tokenId)
        whenNotPaused
    {
        Sentinel storage sentinel = sentinels[_tokenId];
        require(sentinel.status == SentinelStatus.Idle, "AetherSentinels: Sentinel is currently busy");
        require(sentinel.energy >= 10, "AetherSentinels: Not enough energy for training (min 10)"); // Example cost
        require(trainingTypeTraitWeights[_trainingType][0] != 0 || // Check if training type exists by looking at first weight
                trainingTypeTraitWeights[_trainingType][1] != 0 ||
                trainingTypeTraitWeights[_trainingType][2] != 0 ||
                trainingTypeTraitWeights[_trainingType][3] != 0 ||
                trainingTypeTraitWeights[_trainingType][4] != 0,
                "AetherSentinels: Invalid training type");


        _trainingSessionIdCounter.increment();
        uint256 newSessionId = _trainingSessionIdCounter.current();

        trainingSessions[newSessionId] = TrainingSession({
            sessionId: newSessionId,
            tokenId: _tokenId,
            trainingType: _trainingType,
            startTime: block.timestamp,
            completed: false
        });

        sentinel.energy = sentinel.energy - 10; // Deduct energy
        sentinel.status = SentinelStatus.Training;
        sentinel.currentActivityId = newSessionId;

        // Note: _trainingData is recorded off-chain. The hash here serves as a reference.
        // Oracles will use this hash to verify the data used for training.

        emit TrainingInitiated(newSessionId, _tokenId, _trainingType);
    }

    /**
     * @notice Callable by `TRAINER_ORACLE_ROLE` to finalize a training session.
     * @dev Updates Sentinel's traits and grants XP based on off-chain computation.
     * @param _sessionId The ID of the training session.
     * @param _xpGained The amount of experience points gained.
     * @param _traitAdjustments An array of trait adjustments [curiosity, empathy, logic, creativity, resilience].
     */
    function completeTrainingSession(uint256 _sessionId, uint256 _xpGained, int256[] memory _traitAdjustments)
        public
        onlyOracleRole(TRAINER_ORACLE_ROLE)
        whenNotPaused
    {
        TrainingSession storage session = trainingSessions[_sessionId];
        require(!session.completed, "AetherSentinels: Training session already completed");
        require(session.tokenId != 0, "AetherSentinels: Invalid training session ID");
        require(_traitAdjustments.length == 5, "AetherSentinels: Invalid trait adjustments array length");

        Sentinel storage sentinel = sentinels[session.tokenId];
        require(sentinel.status == SentinelStatus.Training && sentinel.currentActivityId == _sessionId,
                "AetherSentinels: Sentinel not in this training session");

        // Apply trait adjustments
        _adjustTrait(session.tokenId, "curiosity", _traitAdjustments[0]);
        _adjustTrait(session.tokenId, "empathy", _traitAdjustments[1]);
        _adjustTrait(session.tokenId, "logic", _traitAdjustments[2]);
        _adjustTrait(session.tokenId, "creativity", _traitAdjustments[3]);
        _adjustTrait(session.tokenId, "resilience", _traitAdjustments[4]);

        sentinel.experience += _xpGained;
        sentinel.status = SentinelStatus.Idle;
        sentinel.currentActivityId = 0;
        session.completed = true;

        emit TrainingCompleted(_sessionId, session.tokenId, _xpGained, _traitAdjustments);
    }

    /**
     * @notice Owner recharges a Sentinel's energy.
     * @dev Costs ETH or other defined resource. Sentinel cannot exceed max energy.
     * @param _tokenId The ID of the Sentinel to recharge.
     */
    function rechargeEnergy(uint256 _tokenId) public payable onlyOwnerOf(_tokenId) whenNotPaused {
        Sentinel storage sentinel = sentinels[_tokenId];
        require(sentinel.energy < 100, "AetherSentinels: Sentinel already at max energy");
        require(msg.value >= energyRechargeCost, "AetherSentinels: Insufficient ETH for energy recharge");

        uint256 energyToAdd = msg.value / energyRechargeCost; // 1 ETH = X energy units
        sentinel.energy = sentinel.energy + energyToAdd > 100 ? 100 : sentinel.energy + energyToAdd;
        sentinel.lastEnergyRechargeBlock = block.number;

        // Refund any excess ETH
        if (msg.value > energyToAdd * energyRechargeCost) {
            payable(msg.sender).transfer(msg.value - (energyToAdd * energyRechargeCost));
        }

        emit SentinelEnergyRecharged(_tokenId, sentinel.energy);
    }

    /**
     * @notice Owner attempts to level up a Sentinel if it has enough XP.
     * @dev Leveling up might unlock new abilities or increase trait caps (not implemented, but implied).
     * @param _tokenId The ID of the Sentinel to level up.
     */
    function tryLevelUp(uint256 _tokenId) public onlyOwnerOf(_tokenId) whenNotPaused {
        Sentinel storage sentinel = sentinels[_tokenId];
        uint256 xpRequiredForNextLevel = XP_FOR_LEVEL_1 * (2**(sentinel.level - 1)); // Exponential XP curve

        require(sentinel.experience >= xpRequiredForNextLevel, "AetherSentinels: Not enough experience to level up");

        sentinel.level++;
        sentinel.experience -= xpRequiredForNextLevel; // Consume XP
        // Future: could add trait bonus or ability unlock here

        emit SentinelLeveledUp(_tokenId, sentinel.level);
    }

    /**
     * @notice Owner delegates their Sentinel for a specific "mission" or "task".
     * @dev Sentinel must be idle, have enough energy, and the mission type must be active.
     * @param _tokenId The ID of the Sentinel.
     * @param _missionTypeId The ID of the predefined mission type.
     * @param _duration The expected duration of the task in seconds.
     */
    function delegateSentinelForTask(uint256 _tokenId, uint256 _missionTypeId, uint256 _duration)
        public
        onlyOwnerOf(_tokenId)
        whenNotPaused
    {
        Sentinel storage sentinel = sentinels[_tokenId];
        MissionType storage mission = missionTypes[_missionTypeId];

        require(sentinel.status == SentinelStatus.Idle, "AetherSentinels: Sentinel is currently busy");
        require(mission.active, "AetherSentinels: Mission type is not active");
        require(sentinel.energy >= mission.baseEnergyCost, "AetherSentinels: Not enough energy for this mission");
        require(_duration <= mission.maxDuration, "AetherSentinels: Task duration exceeds mission type maximum");
        require(_duration > 0, "AetherSentinels: Task duration must be positive");

        _delegatedTaskIdCounter.increment();
        uint256 newTaskId = _delegatedTaskIdCounter.current();

        delegatedTasks[newTaskId] = DelegatedTask({
            taskId: newTaskId,
            tokenId: _tokenId,
            missionTypeId: _missionTypeId,
            startTime: block.timestamp,
            duration: _duration,
            resultHash: "",
            rewardAmount: 0,
            xpGained: 0,
            completed: false,
            rewardsClaimed: false
        });

        sentinel.energy -= mission.baseEnergyCost;
        sentinel.status = SentinelStatus.Tasked;
        sentinel.currentActivityId = newTaskId;

        emit TaskDelegated(newTaskId, _tokenId, _missionTypeId, _duration);
    }

    /**
     * @notice Callable by `TASK_ORACLE_ROLE` to finalize a delegated task.
     * @dev Distributes rewards, XP, and potentially updates traits based on off-chain result.
     * @param _taskId The ID of the delegated task.
     * @param _resultHash IPFS hash or similar of the task's computed result.
     * @param _rewardAmount The ETH amount to be rewarded to the Sentinel owner.
     * @param _xpGained The amount of experience points gained by the Sentinel.
     * @param _traitAdjustments An array of trait adjustments [curiosity, empathy, logic, creativity, resilience].
     */
    function finalizeDelegatedTask(
        uint256 _taskId,
        string memory _resultHash,
        uint256 _rewardAmount,
        uint256 _xpGained,
        int256[] memory _traitAdjustments
    ) public onlyOracleRole(TASK_ORACLE_ROLE) whenNotPaused {
        DelegatedTask storage task = delegatedTasks[_taskId];
        require(!task.completed, "AetherSentinels: Task already finalized");
        require(task.tokenId != 0, "AetherSentinels: Invalid task ID");
        require(_traitAdjustments.length == 5, "AetherSentinels: Invalid trait adjustments array length");

        Sentinel storage sentinel = sentinels[task.tokenId];
        require(sentinel.status == SentinelStatus.Tasked && sentinel.currentActivityId == _taskId,
                "AetherSentinels: Sentinel not on this task");

        // Apply trait adjustments
        _adjustTrait(task.tokenId, "curiosity", _traitAdjustments[0]);
        _adjustTrait(task.tokenId, "empathy", _traitAdjustments[1]);
        _adjustTrait(task.tokenId, "logic", _traitAdjustments[2]);
        _adjustTrait(task.tokenId, "creativity", _traitAdjustments[3]);
        _adjustTrait(task.tokenId, "resilience", _traitAdjustments[4]);

        sentinel.experience += _xpGained;
        sentinel.status = SentinelStatus.Idle;
        sentinel.currentActivityId = 0;

        task.resultHash = _resultHash;
        task.rewardAmount = _rewardAmount;
        task.xpGained = _xpGained;
        task.completed = true;

        emit TaskFinalized(_taskId, task.tokenId, _resultHash, _rewardAmount, _xpGained);
    }

    /**
     * @notice Owner claims the rewards from a successfully completed task.
     * @param _taskId The ID of the completed task.
     */
    function claimTaskReward(uint256 _taskId) public onlyOwnerOf(delegatedTasks[_taskId].tokenId) nonReentrant whenNotPaused {
        DelegatedTask storage task = delegatedTasks[_taskId];
        require(task.completed, "AetherSentinels: Task not yet completed");
        require(!task.rewardsClaimed, "AetherSentinels: Rewards already claimed");
        require(task.rewardAmount > 0, "AetherSentinels: No rewards to claim");

        task.rewardsClaimed = true;
        payable(msg.sender).transfer(task.rewardAmount); // Transfer ETH reward

        emit TaskRewardClaimed(_taskId, task.tokenId, task.rewardAmount);
    }

    // --- IV. Oracle & External Data Integration ---

    /**
     * @notice Callable by `GOVERNOR_ROLE` or `ENVIRONMENTAL_ORACLE_ROLE` to adjust global trait influences.
     * @dev These factors globally modify how a specific trait impacts mission outcomes or passive evolution.
     * @param _traitName The name of the trait (e.g., "curiosity").
     * @param _newInfluenceFactor The new influence factor (e.g., 100 for neutral, 120 for 20% boost, 80 for 20% penalty).
     */
    function updateGlobalTraitInfluence(string memory _traitName, int256 _newInfluenceFactor)
        public
        onlyRole(GOVERNOR_ROLE) // Can be extended to ENVIRONMENTAL_ORACLE_ROLE for more dynamic updates
        whenNotPaused
    {
        globalTraitInfluences[_traitName] = _newInfluenceFactor;
        emit GlobalTraitInfluenceUpdated(_traitName, _newInfluenceFactor);
    }

    /**
     * @notice Callable by `ENVIRONMENTAL_ORACLE_ROLE` to feed real-world data.
     * @dev This data can subtly influence all Sentinels' passive evolution or mission success rates.
     *      The actual impact logic would typically be off-chain (e.g., in a keeper bot that
     *      calls `updateGlobalTraitInfluence` or `completeTrainingSession` based on this).
     * @param _dataFeedId A unique ID for the type of environmental data (e.g., "marketSentiment", "weatherIndex").
     * @param _value The integer value of the environmental data.
     */
    function submitEnvironmentalData(bytes32 _dataFeedId, uint256 _value)
        public
        onlyOracleRole(ENVIRONMENTAL_ORACLE_ROLE)
        whenNotPaused
    {
        // This function primarily records the data. Off-chain logic or keeper bots would interpret it
        // and trigger further on-chain actions (e.g., by calling updateGlobalTraitInfluence or specific trait adjustments).
        // For direct on-chain impact, further logic would be needed here.
        // Example: if (_dataFeedId == keccak256("marketSentiment")) { ... update specific traits ... }
        emit EnvironmentalDataSubmitted(_dataFeedId, _value);
    }

    /**
     * @notice `DEFAULT_ADMIN_ROLE` or `GOVERNOR_ROLE` sets authorized addresses for different oracle roles.
     * @dev This is crucial for managing the decentralized off-chain computation.
     * @param _role The role to set the address for (e.g., TRAINER_ORACLE_ROLE, TASK_ORACLE_ROLE).
     * @param _newAddress The new address to grant the role to.
     */
    function setOracleAddress(bytes32 _role, address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newAddress != address(0), "AetherSentinels: New address cannot be zero");
        address oldAddress = address(0); // Cannot easily retrieve current role holder without iterating

        // Best practice is to remove and then grant, to ensure only one address holds the role, or manage multiple.
        // For simplicity, we assume one primary oracle per role. If multiple, change to _grantRole and _revokeRole.
        // This implementation allows only one per type and replaces it.
        // Iterate current role members to revoke (if any) and then grant. This is gas-intensive.
        // A simpler (less robust) approach: `_setupRole` (internal) if only one oracle per role is assumed, or just grant.

        // To properly manage one-to-one mapping, we'd need a `mapping(bytes32 => address)` for current oracles.
        // For demonstration, we'll just grant the new address the role, assuming previous holders are manually revoked
        // or that multiple addresses for a role is acceptable.
        
        // Simpler for demo: revoke all current holders and grant to new. (Not ideal for real production, as it clears all).
        // Or, if roles allow multiple, just add.
        
        // Let's assume for this contract that for these special oracle roles, only one active oracle address is intended.
        // If not, use _grantRole and _revokeRole for multiple.
        // The AccessControl.sol doesn't easily allow "setting" a single role holder directly.
        // We will grant the new address the role. The contract owner should manually revoke old oracles.

        _grantRole(_role, _newAddress);
        emit OracleAddressSet(_role, oldAddress, _newAddress); // oldAddress will be 0x0 if not explicitly tracked
    }

    // --- V. Governance & Economic Model ---

    /**
     * @notice `GOVERNOR_ROLE` proposes new mission types, their costs, and base rewards.
     * @dev This initiates a governance proposal that needs to be voted on.
     * @param _name Name of the new mission type.
     * @param _baseEnergyCost Base energy cost for the mission.
     * @param _baseRewardAmount Base ETH reward for completing the mission.
     * @param _baseXpReward Base experience points rewarded.
     * @param _maxDuration Maximum allowed duration for this mission type.
     * @param _traitInfluenceWeights Array of trait weights for the new mission type.
     */
    function proposeMissionParameters(
        string memory _name,
        uint256 _baseEnergyCost,
        uint256 _baseRewardAmount,
        uint256 _baseXpReward,
        uint256 _maxDuration,
        int256[] memory _traitInfluenceWeights
    ) public onlyRole(GOVERNOR_ROLE) whenNotPaused {
        require(_traitInfluenceWeights.length == 5, "AetherSentinels: Trait influence weights array length mismatch");
        _missionTypeIdCounter.increment();
        uint256 newMissionTypeId = _missionTypeIdCounter.current();

        MissionType memory newMission = MissionType({
            name: _name,
            baseEnergyCost: _baseEnergyCost,
            baseRewardAmount: _baseRewardAmount,
            baseXpReward: _baseXpReward,
            maxDuration: _maxDuration,
            traitInfluenceWeights: _traitInfluenceWeights, // Store directly
            active: false // Not active until proposal passes
        });

        bytes memory callData = abi.encodeWithSelector(
            this.updateMissionType.selector, // Using an internal helper function for execution
            newMissionTypeId,
            newMission
        );

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Propose new Mission Type: ", _name)),
            callData: callData,
            targetContract: address(this),
            voteCountYes: 0,
            voteCountNo: 0,
            hasVoted: new mapping(address => bool), // Initialize empty map
            creationTime: block.timestamp,
            votingDeadline: block.timestamp + 7 days, // Example: 7 days for voting
            executed: false,
            passed: false
        });

        // Store the mission temporarily for reference, but it's not active yet.
        missionTypes[newMissionTypeId] = newMission;

        emit MissionTypeProposed(newProposalId, newMissionTypeId, _name);
    }

    /**
     * @notice Allows `GOVERNOR_ROLE` members to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRole(GOVERNOR_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "AetherSentinels: Proposal does not exist");
        require(!proposal.executed, "AetherSentinels: Proposal already executed");
        require(block.timestamp <= proposal.votingDeadline, "AetherSentinels: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherSentinels: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Executes a successfully voted proposal.
     * @dev Can be called by anyone after the voting deadline, if the proposal passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "AetherSentinels: Proposal does not exist");
        require(!proposal.executed, "AetherSentinels: Proposal already executed");
        require(block.timestamp > proposal.votingDeadline, "AetherSentinels: Voting period not yet ended");

        uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
        // Example: Simple majority required, and at least 3 total votes to be considered.
        bool passed = (totalVotes >= 3 && proposal.voteCountYes > proposal.voteCountNo);

        if (passed) {
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "AetherSentinels: Proposal execution failed");
            proposal.passed = true;
        }
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, passed);
    }

    // Internal helper function for governance execution
    function updateMissionType(uint256 _missionTypeId, MissionType memory _newMission) internal onlyRole(GOVERNOR_ROLE) {
        // This function is intended to be called by `executeProposal` via `callData`.
        // It bypasses the `whenNotPaused` modifier because governance actions should still be possible.
        // It directly updates the mission type, making it active.
        _newMission.active = true; // Activate it now
        missionTypes[_missionTypeId] = _newMission;
    }

    /**
     * @notice `GOVERNOR_ROLE` adjusts the cost of recharging energy.
     * @param _newCost The new ETH cost for energy recharge (in wei).
     */
    function updateEnergyRechargeCost(uint256 _newCost) public onlyRole(GOVERNOR_ROLE) whenNotPaused {
        require(_newCost > 0, "AetherSentinels: Energy recharge cost must be positive");
        energyRechargeCost = _newCost;
        emit EnergyRechargeCostUpdated(_newCost);
    }

    /**
     * @notice Allows `DEFAULT_ADMIN_ROLE` or `GOVERNOR_ROLE` to withdraw accumulated funds.
     * @dev Funds could come from energy recharges, mission fees, etc.
     * @param _recipient The address to send the funds to.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE) // Or GOVERNOR_ROLE with a proposal system
        nonReentrant
        whenNotPaused
    {
        require(_recipient != address(0), "AetherSentinels: Cannot withdraw to zero address");
        require(address(this).balance >= _amount, "AetherSentinels: Insufficient contract balance");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /**
     * @notice `GOVERNOR_ROLE` to adjust how different training types influence trait adjustments.
     * @dev This allows tuning the AI simulation's learning dynamics.
     * @param _trainingType The name of the training type.
     * @param _newWeights An array of 5 weights [curiosity, empathy, logic, creativity, resilience].
     */
    function adjustTrainingTypeWeights(string memory _trainingType, int256[5] memory _newWeights)
        public
        onlyRole(GOVERNOR_ROLE)
        whenNotPaused
    {
        trainingTypeTraitWeights[_trainingType] = _newWeights;
        emit TrainingTypeWeightsAdjusted(_trainingType, _newWeights);
    }

    /**
     * @notice A flexible `GOVERNOR_ROLE` switch to enable/disable certain protocol features.
     * @dev This allows for dynamic activation/deactivation of features without redeploying logic.
     * @param _featureName Unique identifier for the feature (e.g., "AllowNewMissionProposals", "EnablePassiveEnergyRegen").
     * @param _isActive The desired status of the feature.
     */
    function toggleGlobalFeature(bytes32 _featureName, bool _isActive)
        public
        onlyRole(GOVERNOR_ROLE)
    {
        globalFeatures[_featureName] = _isActive;
        emit GlobalFeatureToggled(_featureName, _isActive);
    }

    // --- VI. Utility & Security ---

    /**
     * @notice Sets the base URI for NFT metadata.
     * @dev Only `DEFAULT_ADMIN_ROLE` can call this.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @notice Pauses the contract.
     * @dev Only `DEFAULT_ADMIN_ROLE` or `PAUSER_ROLE` can call this. Prevents most state-changing actions.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only `DEFAULT_ADMIN_ROLE` or `PAUSER_ROLE` can call this.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Optionally, handle ETH received, e.g., for direct energy purchase
    }
}
```