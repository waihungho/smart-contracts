Okay, this is an exciting challenge! Let's design a smart contract that embodies advanced concepts, creative functionality, and trendy ideas without duplicating existing open-source projects.

My concept is a "Synergistic Adaptive Protocol Engine" (SAPE).
It's a decentralized, self-evolving protocol that aims to optimize a specific on-chain objective (e.g., maximizing yield for a community fund, optimizing resource allocation for a public good, or managing risk for a collective pool) by leveraging collective intelligence and external AI/ML model predictions via secure oracles. Participants contribute "wisdom" (oracle data feeds) and "influence" (staked tokens), earning rewards and upgrading unique "Wisdom Orb" NFTs based on the protocol's overall performance and their individual contributions.

**Key Advanced Concepts:**

1.  **Dynamic/Evolving NFTs (Wisdom Orbs):** NFTs that level up and change metadata based on the owner's contribution and the protocol's success.
2.  **Oracle-Driven Adaptive Strategy:** Not just price feeds, but complex data (e.g., AI model predictions, risk assessments, optimal parameter sets) fed by a trusted oracle network to drive strategic decisions.
3.  **Collective Intelligence & Wisdom Weighting:** Participants stake tokens to give weight to their contributed oracle data, creating a "wisdom consensus."
4.  **Epoch-Based Adaptive Learning:** The protocol operates in epochs, with performance evaluated, strategies adjusted, and rewards distributed at the end of each epoch.
5.  **Modular Strategy Execution:** The core contract can register and dynamically select between different "Strategy Modules" (external contracts) for execution, allowing for adaptability without core contract upgrades.
6.  **Goal-Oriented Optimization:** Instead of rigid rules, the protocol aims to achieve an abstract `targetGoal` which influences its decisions.
7.  **Reputation/Performance Scoring:** Internal metrics track individual participant performance and protocol-wide success.
8.  **Re-entrancy Guard, Pausable, Access Control:** Standard but crucial security features.

---

### **Outline & Function Summary: Synergistic Adaptive Protocol Engine (SAPE)**

**Contract Name:** `SAPE_Protocol`

**Core Purpose:** To collectively optimize a specific on-chain goal by leveraging staked influence, AI-driven oracle data, and adaptive strategy execution, rewarding participants with tokens and evolving NFTs.

---

**I. Core Infrastructure & State Management**
*   **`constructor`**: Initializes the protocol, setting up core parameters and linking initial dependencies.
*   **`pauseProtocol`**: Allows a designated governor to temporarily halt critical protocol operations in emergencies.
*   **`unpauseProtocol`**: Resumes operations after a pause.
*   **`setProtocolGovernor`**: Transfers governorship to a new address.
*   **`setCoreVaultAddress`**: Updates the address of the secure vault holding protocol funds.

**II. Influence Staking & Management**
*   **`stakeInfluence`**: Allows users to stake tokens, gaining "influence" within the protocol, which weights their wisdom contributions and unlocks NFT minting.
*   **`unstakeInfluence`**: Enables users to unstake their tokens and reduce their influence, subject to cooldowns or conditions.
*   **`claimStakingRewards`**: Allows stakers to claim their accumulated rewards from protocol performance.
*   **`getInfluenceBalance`**: Retrieves the influence (staked token amount) of a specific address.

**III. Wisdom Contribution & Oracle Integration**
*   **`contributeWisdomData`**: Allows authorized oracle networks to submit new `WisdomData` (e.g., AI model predictions, optimal parameters, risk assessments) to the protocol. This data is weighted by the submitting participant's influence.
*   **`setOracleAddress`**: Sets or updates the trusted oracle contract address allowed to submit `WisdomData`.
*   **`updateOracleThresholds`**: Modifies the confidence or validity thresholds for incoming oracle data.
*   **`getLatestWisdomData`**: Retrieves the most recently processed and weighted `WisdomData`.

**IV. Epoch Management & Adaptive Learning**
*   **`triggerDecisionCycle`**: Initiates a new protocol epoch. This function calculates the optimal strategy, executes actions, and prepares for reward distribution based on accumulated `WisdomData`.
*   **`advanceEpoch`**: Finalizes the current epoch, calculates performance, distributes rewards, and increments the epoch counter. Typically called after `triggerDecisionCycle` or on a schedule.
*   **`getEpochDetails`**: Provides information about a specific epoch, including performance, start/end times, and total rewards.
*   **`getProtocolPerformanceScore`**: Retrieves the current aggregated performance score of the protocol, indicating its success against the `targetGoal`.

**V. Dynamic NFT (Wisdom Orb) Management**
*   **`mintWisdomOrb`**: Allows eligible participants (e.g., those who have staked sufficient influence) to mint their unique "Wisdom Orb" NFT.
*   **`upgradeWisdomOrb`**: Automatically or manually triggers an upgrade for a Wisdom Orb based on its owner's sustained influence and the protocol's success, changing its level and metadata.
*   **`getWisdomOrbMetadataURI`**: Returns the dynamically generated metadata URI for a given Wisdom Orb NFT, reflecting its current level and status.
*   **`burnWisdomOrb`**: Allows an owner to burn their Wisdom Orb NFT, potentially reclaiming some value or resetting their participation.

**VI. Strategy Module Management & Execution**
*   **`registerStrategyModule`**: Allows the governor to register a new external `IStrategyModule` contract that the SAPE can utilize for its operations.
*   **`deactivateStrategyModule`**: Disables a previously registered strategy module, preventing the protocol from selecting it.
*   **`executeOptimizedAction`**: An internal function called by `triggerDecisionCycle` that interacts with the selected `IStrategyModule` to perform the protocol's optimized action.
*   **`getRegisteredStrategyModules`**: Lists all currently registered (and active) strategy modules.

**VII. Governance & Parameter Adjustment**
*   **`proposeParameterChange`**: Allows a minimum threshold of influence holders to propose changes to protocol parameters (e.g., reward rates, cooldowns).
*   **`voteOnParameterChange`**: Allows influence holders to vote on active proposals.
*   **`executeParameterChange`**: Executes a parameter change proposal if it passes the required vote threshold.

---

### **Solidity Smart Contract: SAPE_Protocol.sol**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---

// Interface for the Oracle providing complex wisdom data
interface IOracle {
    function requestWisdomData(address callbackContract, bytes32 requestId) external;
    function fulfillWisdomData(bytes32 requestId, bytes memory data) external; // Data could be encoded AI model output
}

// Interface for external Strategy Modules the protocol can call
interface IStrategyModule {
    function executeStrategy(address _targetGoalContract, bytes memory _actionParameters) external returns (bool success);
    function getStrategyType() external pure returns (string memory);
}

// --- Errors ---
error SAPE_Protocol__NotEnoughInfluence(uint256 required, uint256 provided);
error SAPE_Protocol__AlreadyMintedOrb();
error SAPE_Protocol__InvalidOracle();
error SAPE_Protocol__InvalidStrategyModule();
error SAPE_Protocol__NoActiveProposal();
error SAPE_Protocol__AlreadyVoted();
error SAPE_Protocol__ProposalNotReadyForExecution();
error SAPE_Protocol__ProposalFailedThreshold();
error SAPE_Protocol__NotEnoughStakedFunds();
error SAPE_Protocol__WisdomDataTooOld();
error SAPE_Protocol__EpochNotReady();


// --- Main Contract ---
contract SAPE_Protocol is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Events ---
    event InfluenceStaked(address indexed participant, uint256 amount);
    event InfluenceUnstaked(address indexed participant, uint256 amount);
    event RewardsClaimed(address indexed participant, uint256 amount);
    event WisdomDataContributed(address indexed contributor, uint256 weightedScore, bytes dataHash);
    event DecisionCycleTriggered(uint256 indexed epoch, bytes32 selectedStrategyId, bytes actionParametersHash);
    event EpochAdvanced(uint256 indexed epoch, uint256 performanceScore, uint256 totalRewardsDistributed);
    event WisdomOrbMinted(address indexed owner, uint256 indexed tokenId, uint256 initialLevel);
    event WisdomOrbUpgraded(uint256 indexed tokenId, uint256 newLevel);
    event StrategyModuleRegistered(address indexed moduleAddress, bytes32 strategyId);
    event StrategyModuleDeactivated(address indexed moduleAddress, bytes32 strategyId);
    event ParameterChangeProposed(uint256 indexed proposalId, bytes parameterData, uint256 requiredVotes);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 influenceWeight);
    event ParameterChangeExecuted(uint256 indexed proposalId, bool success);

    // --- Enums ---
    enum ProtocolState {
        Active,
        Paused,
        DecisionPending // Waiting for oracle data after triggerDecisionCycle
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    // --- Structs ---
    struct WisdomOrb {
        uint256 level;           // Current level of the Orb
        uint256 XP;              // Experience points for leveling up
        uint256 lastUpgradeEpoch; // Epoch when it last upgraded
        uint256 mintEpoch;       // Epoch when it was minted
    }

    struct WisdomData {
        bytes data;               // Encoded complex data (e.g., AI model output for optimal params)
        uint256 weightedScore;    // The original score * contributor's influence weight
        address contributor;      // Address of the participant who submitted via oracle
        uint256 timestamp;        // When data was submitted
        bytes32 requestId;        // Oracle request ID
    }

    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 totalWisdomContributions;
        uint256 totalRewardsDistributed;
        int256 performanceScore; // Can be negative if performance is bad
        bytes32 selectedStrategyId;
    }

    struct Proposal {
        uint256 id;
        bytes data; // Encoded function call (e.g., `abi.encodeWithSelector(SAPE_Protocol.setRewardRate.selector, newRate)`)
        uint256 proposalEndTime;
        uint224 votesFor; // Use uint224 for large values
        uint224 votesAgainst;
        uint256 proposer; // Store proposer's influence at time of proposal
        ProposalState state;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    // Core Tokens
    IERC20 public immutable stakingToken; // Token used for staking influence and distributing rewards
    address public coreVaultAddress;      // Address of the vault holding protocol funds for strategy execution

    // Protocol State & Control
    ProtocolState public currentProtocolState;
    address public protocolGovernor;      // Can be a multisig or DAO contract in future
    uint256 public constant INFLUENCE_STAKE_MIN_AMOUNT = 100 * 10 ** 18; // Min amount to stake for influence (e.g., 100 tokens)
    uint256 public constant ORB_MINT_INFLUENCE_THRESHOLD = 500 * 10 ** 18; // Min influence to mint an Orb

    // Oracle & Wisdom
    address public trustedOracleAddress;
    uint256 public wisdomDataValidityPeriod = 1 hours; // Max age of wisdom data for consideration
    uint256 public oracleRequestCooldown = 5 minutes; // Min time between oracle requests
    uint256 public lastOracleRequestTime;
    mapping(uint256 => WisdomData) public latestWeightedWisdomData; // Stored by epoch or a single latest entry
    uint256 public currentWisdomDataTimestamp;

    // Epoch & Performance
    uint256 public currentEpoch;
    uint256 public epochDuration = 24 hours; // Duration of each epoch
    uint256 public lastEpochAdvanceTime;
    mapping(uint256 => Epoch) public epochs;
    int256 public protocolPerformanceScore; // Accumulated performance score over epochs

    // Rewards
    uint256 public baseRewardRatePerEpoch = 0.01e18; // 1% of total staked influence, as example
    uint256 public performanceRewardMultiplier = 100; // Multiplier for performance-based rewards (e.g., 100 = 1x)

    // Participants
    mapping(address => uint256) public influenceStaked; // Token amount staked by each participant
    mapping(address => uint256) public participantRewards; // Accumulating rewards for each participant
    mapping(address => uint256) public participantOrbTokenId; // Maps participant address to their Orb tokenId
    Counters.Counter private _wisdomOrbTokenIds;

    // Dynamic NFTs
    string private _baseTokenURI; // Base URI for dynamically generated metadata

    // Strategy Modules
    mapping(bytes32 => address) public registeredStrategyModules; // bytes32 ID => contract address
    mapping(bytes32 => bool) public isStrategyModuleActive; // Whether a module is active
    bytes32[] public activeStrategyModuleIds; // Array of active module IDs for iteration

    // Governance & Proposals
    Counters.Counter public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotePeriod = 3 days;
    uint256 public proposalMinInfluenceToPropose = 1000 * 10 ** 18; // E.g., 1000 tokens
    uint256 public proposalVoteThreshold = 6000; // 60.00% (value / 10000) of total staked influence needed to pass

    // Target Goal (abstract representation, could be an address or specific parameter)
    address public targetGoalContract; // The contract or entity whose objective the SAPE is optimizing

    // --- Modifiers ---
    modifier onlyProtocolGovernor() {
        if (msg.sender != protocolGovernor) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable error
        }
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != trustedOracleAddress) {
            revert SAPE_Protocol__InvalidOracle();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _stakingTokenAddress,
        address _initialOracleAddress,
        address _initialCoreVaultAddress,
        address _initialTargetGoalContract,
        string memory _name,
        string memory _symbol,
        string memory __baseTokenURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) Pausable() {
        require(_stakingTokenAddress != address(0), "Invalid staking token address");
        require(_initialOracleAddress != address(0), "Invalid oracle address");
        require(_initialCoreVaultAddress != address(0), "Invalid vault address");
        require(_initialTargetGoalContract != address(0), "Invalid target goal contract");

        stakingToken = IERC20(_stakingTokenAddress);
        trustedOracleAddress = _initialOracleAddress;
        coreVaultAddress = _initialCoreVaultAddress;
        targetGoalContract = _initialTargetGoalContract;
        _baseTokenURI = __baseTokenURI;

        protocolGovernor = msg.sender; // Initially owner is governor
        currentProtocolState = ProtocolState.Active;
        currentEpoch = 0; // Start at epoch 0
    }

    // --- I. Core Infrastructure & State Management ---

    /**
     * @notice Allows the protocol governor to temporarily pause critical operations.
     * @dev Only the designated protocol governor can call this.
     */
    function pauseProtocol() external onlyProtocolGovernor whenNotPaused {
        _pause();
        currentProtocolState = ProtocolState.Paused;
    }

    /**
     * @notice Allows the protocol governor to resume operations after a pause.
     * @dev Only the designated protocol governor can call this.
     */
    function unpauseProtocol() external onlyProtocolGovernor onlyWhenPaused {
        _unpause();
        currentProtocolState = ProtocolState.Active;
    }

    /**
     * @notice Transfers the governorship of the protocol to a new address.
     * @param _newGovernor The address of the new protocol governor.
     * @dev This is a critical function; should ideally be behind a timelock or DAO vote.
     */
    function setProtocolGovernor(address _newGovernor) external onlyProtocolGovernor {
        require(_newGovernor != address(0), "New governor cannot be zero address");
        protocolGovernor = _newGovernor;
        emit OwnershipTransferred(msg.sender, _newGovernor); // Reusing Ownable event
    }

    /**
     * @notice Updates the address of the secure vault holding protocol funds.
     * @param _newVaultAddress The new address for the core vault.
     */
    function setCoreVaultAddress(address _newVaultAddress) external onlyProtocolGovernor {
        require(_newVaultAddress != address(0), "New vault cannot be zero address");
        coreVaultAddress = _newVaultAddress;
    }

    // --- II. Influence Staking & Management ---

    /**
     * @notice Allows a user to stake `stakingToken` to gain influence.
     * @param _amount The amount of staking tokens to stake.
     * @dev Requires approval of tokens to this contract. Influence is directly proportional to staked amount.
     */
    function stakeInfluence(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(_amount >= INFLUENCE_STAKE_MIN_AMOUNT, "Must stake minimum influence amount");
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        influenceStaked[msg.sender] += _amount;
        emit InfluenceStaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to unstake their `stakingToken` and reduce influence.
     * @param _amount The amount of staking tokens to unstake.
     * @dev Subject to an optional cooldown or conditions (not implemented for brevity, but a common feature).
     */
    function unstakeInfluence(uint256 _amount) external nonReentrant whenNotPaused {
        require(influenceStaked[msg.sender] >= _amount, "Not enough staked influence");
        require(stakingToken.transfer(msg.sender, _amount), "Token transfer failed");

        influenceStaked[msg.sender] -= _amount;
        emit InfluenceUnstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows participants to claim their accumulated rewards.
     * @dev Rewards are calculated based on epoch performance and individual contributions.
     */
    function claimStakingRewards() external nonReentrant {
        uint256 rewards = participantRewards[msg.sender];
        require(rewards > 0, "No rewards to claim");

        participantRewards[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, rewards), "Reward transfer failed");
        emit RewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice Retrieves the current influence (staked token amount) of an address.
     * @param _participant The address to query.
     * @return The amount of influence staked by the participant.
     */
    function getInfluenceBalance(address _participant) external view returns (uint256) {
        return influenceStaked[_participant];
    }

    // --- III. Wisdom Contribution & Oracle Integration ---

    /**
     * @notice Allows the trusted oracle to submit new WisdomData to the protocol.
     * @param _requestId The request ID associated with the oracle query.
     * @param _data Encoded bytes representing the complex wisdom data (e.g., AI model output).
     * @param _contributor The address of the participant on whose behalf the data was requested/contributed.
     * @param _score A raw score or evaluation from the oracle for this data.
     * @dev This function is critical for the adaptive nature of the protocol.
     */
    function contributeWisdomData(
        bytes32 _requestId,
        bytes memory _data,
        address _contributor,
        uint256 _score
    ) external onlyOracle whenNotPaused {
        // Ensure data is not too old based on request time if available, or just submission time
        require(block.timestamp - lastOracleRequestTime < wisdomDataValidityPeriod, "Wisdom data too old or not requested");

        uint256 weightedScore = _score * influenceStaked[_contributor] / (10 ** 18); // Example weighting (adjust precision)

        latestWeightedWisdomData[currentEpoch] = WisdomData({
            data: _data,
            weightedScore: weightedScore,
            contributor: _contributor,
            timestamp: block.timestamp,
            requestId: _requestId
        });
        currentWisdomDataTimestamp = block.timestamp;

        emit WisdomDataContributed(_contributor, weightedScore, keccak256(_data));
    }

    /**
     * @notice Sets or updates the trusted oracle contract address.
     * @param _newOracleAddress The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracleAddress) external onlyProtocolGovernor {
        require(_newOracleAddress != address(0), "Oracle address cannot be zero");
        trustedOracleAddress = _newOracleAddress;
        // Optionally request initial data here or just wait for triggerDecisionCycle
    }

    /**
     * @notice Modifies the confidence or validity thresholds for incoming oracle data.
     * @param _newValidityPeriod The new maximum age for wisdom data to be considered valid.
     * @param _newCooldown The new minimum time between oracle requests.
     */
    function updateOracleThresholds(uint256 _newValidityPeriod, uint256 _newCooldown) external onlyProtocolGovernor {
        wisdomDataValidityPeriod = _newValidityPeriod;
        oracleRequestCooldown = _newCooldown;
    }

    /**
     * @notice Retrieves the most recently processed and weighted WisdomData for the current epoch.
     * @return A tuple containing the WisdomData details.
     */
    function getLatestWisdomData() external view returns (bytes memory data, uint256 weightedScore, address contributor, uint256 timestamp, bytes32 requestId) {
        WisdomData storage wd = latestWeightedWisdomData[currentEpoch];
        return (wd.data, wd.weightedScore, wd.contributor, wd.timestamp, wd.requestId);
    }

    // --- IV. Epoch Management & Adaptive Learning ---

    /**
     * @notice Initiates a new protocol epoch and triggers the decision-making process.
     * @dev This function should ideally be called by an automated keeper network or DAO.
     * It requests new oracle data and then, upon its fulfillment, executes an action.
     */
    function triggerDecisionCycle() external nonReentrant whenNotPaused {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "Epoch not yet ended");
        require(currentProtocolState == ProtocolState.Active, "Protocol not in active state");
        require(block.timestamp >= lastOracleRequestTime + oracleRequestCooldown, "Oracle request cooldown active");

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp; // Mark epoch start time
        epochs[currentEpoch].startTime = block.timestamp;

        // Simulate Oracle Request - In a real scenario, this would call IOracle.requestWisdomData
        // and a callback would then trigger the actual decision and execution.
        // For this example, we'll assume the data is available.
        lastOracleRequestTime = block.timestamp;
        currentProtocolState = ProtocolState.DecisionPending;

        // In a real scenario, you'd emit an event and wait for Oracle to fulfill
        // e.g., emit OracleRequestSent(currentEpoch, requestDataHash);
        // Then an external bot would see the event, query a real AI model, and call `contributeWisdomData`
        // which then triggers `_executeOptimizedAction`
    }

    /**
     * @notice Finalizes the current epoch, calculates performance, distributes rewards, and increments epoch.
     * @dev This function should be called after `triggerDecisionCycle` and subsequent oracle fulfillment.
     */
    function advanceEpoch() internal {
        require(currentProtocolState == ProtocolState.DecisionPending, "Epoch decision pending state required");
        require(block.timestamp - currentWisdomDataTimestamp < wisdomDataValidityPeriod, "Wisdom data too old for decision");

        // Step 1: Process Wisdom Data to determine optimal strategy & action parameters
        // This is where the "collective intelligence" logic happens.
        // For simplicity, we'll use the latest submitted wisdom data directly.
        // A more complex system would aggregate multiple submissions, filter, or run a voting mechanism.
        WisdomData storage epochWisdom = latestWeightedWisdomData[currentEpoch];
        require(epochWisdom.timestamp > 0, "No wisdom data for current epoch");

        bytes32 selectedStrategyId = _selectOptimalStrategy(epochWisdom.data);
        bytes memory actionParameters = _deriveActionParameters(epochWisdom.data);

        // Step 2: Execute the determined action
        bool success = _executeOptimizedAction(selectedStrategyId, actionParameters);

        // Step 3: Evaluate Protocol Performance for the epoch
        // This score would typically come from an oracle or be calculated based on on-chain metrics
        // (e.g., increase in vault funds, achievement of a specific target on `targetGoalContract`).
        // For this example, we'll use a placeholder.
        int256 epochPerformance = success ? int256(epochWisdom.weightedScore / 1e16) : -1 * int256(epochWisdom.weightedScore / 1e16); // Placeholder logic
        protocolPerformanceScore += epochPerformance; // Accumulate global score

        // Step 4: Distribute Rewards
        uint256 totalStaked = stakingToken.balanceOf(address(this)); // Total funds in contract
        uint256 totalRewardPool = (totalStaked * baseRewardRatePerEpoch) / (10 ** 18);
        if (epochPerformance > 0) {
            totalRewardPool += (totalRewardPool * uint256(epochPerformance) * performanceRewardMultiplier) / (10000 * 10 ** 18); // Example
        }

        uint256 totalInfluence = _getTotalStakedInfluence();
        if (totalInfluence > 0 && totalRewardPool > 0) {
             _distributeEpochRewards(totalRewardPool, totalInfluence);
        }

        // Step 5: Update Epoch details
        epochs[currentEpoch].endTime = block.timestamp;
        epochs[currentEpoch].totalWisdomContributions = epochWisdom.weightedScore;
        epochs[currentEpoch].totalRewardsDistributed = totalRewardPool;
        epochs[currentEpoch].performanceScore = epochPerformance;
        epochs[currentEpoch].selectedStrategyId = selectedStrategyId;

        currentProtocolState = ProtocolState.Active; // Ready for next cycle
        emit EpochAdvanced(currentEpoch, uint256(epochPerformance), totalRewardPool);
    }

    /**
     * @notice Retrieves details about a specific epoch.
     * @param _epochId The ID of the epoch to query.
     * @return A tuple containing epoch details.
     */
    function getEpochDetails(uint256 _epochId) external view returns (uint256 startTime, uint256 endTime, uint256 totalWisdomContributions, uint256 totalRewardsDistributed, int256 performanceScore, bytes32 selectedStrategyId) {
        Epoch storage ep = epochs[_epochId];
        return (ep.startTime, ep.endTime, ep.totalWisdomContributions, ep.totalRewardsDistributed, ep.performanceScore, ep.selectedStrategyId);
    }

    /**
     * @notice Retrieves the current aggregated performance score of the protocol.
     * @return The accumulated performance score.
     */
    function getProtocolPerformanceScore() external view returns (int256) {
        return protocolPerformanceScore;
    }

    /**
     * @dev Internal function to select the optimal strategy based on aggregated wisdom data.
     * @param _wisdomData The aggregated wisdom data.
     * @return The bytes32 ID of the selected strategy module.
     */
    function _selectOptimalStrategy(bytes memory _wisdomData) internal view returns (bytes32) {
        // This is highly complex in a real scenario, potentially involving on-chain voting
        // or a highly sophisticated algorithm interpreting the wisdom data.
        // For demonstration: Assume the wisdom data directly encodes the strategy ID.
        if (activeStrategyModuleIds.length == 0) return bytes32(0); // No active modules

        // Example: Assume the first 32 bytes of _wisdomData contain the desired strategyId
        bytes32 strategyId;
        assembly {
            strategyId := mload(add(_wisdomData, 32)) // Load first 32 bytes (after length)
        }
        if (isStrategyModuleActive[strategyId]) {
            return strategyId;
        }
        // Fallback: If recommended strategy not active, pick first active one.
        return activeStrategyModuleIds[0];
    }

    /**
     * @dev Internal function to derive action parameters from wisdom data.
     * @param _wisdomData The aggregated wisdom data.
     * @return The encoded action parameters for the selected strategy.
     */
    function _deriveActionParameters(bytes memory _wisdomData) internal pure returns (bytes memory) {
        // Assume _wisdomData contains the parameters directly or encoded.
        // This function would parse and prepare the arguments for the strategy module.
        // For demonstration, return the rest of the wisdom data as parameters.
        if (_wisdomData.length <= 32) return new bytes(0); // No parameters if only strategy ID
        bytes memory params = new bytes(_wisdomData.length - 32);
        for (uint256 i = 0; i < params.length; i++) {
            params[i] = _wisdomData[i + 32];
        }
        return params;
    }

    /**
     * @dev Internal function to distribute epoch rewards to participants based on their influence.
     * @param _totalRewardPool The total amount of rewards to distribute for the current epoch.
     * @param _totalInfluence The sum of all staked influence.
     */
    function _distributeEpochRewards(uint256 _totalRewardPool, uint256 _totalInfluence) internal {
        // This is a simplified distribution. In a real system, it would iterate
        // through active stakers or use a Merkle tree for gas efficiency.
        // For demonstration, we'll just increment participantRewards for anyone who has staked.
        // A more complex system might track individual 'wisdom contribution scores' for distribution.

        if (_totalInfluence == 0) return;

        // Note: This iteration is gas-inefficient for many stakers.
        // For production, consider an "on-demand" calculation or Merkle proof system.
        // For this example, we're assuming a manageable number of active stakers for direct iteration.
        address[] memory stakers = _getAllStakers(); // Placeholder, very gas-inefficient for large number of stakers
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            if (influenceStaked[staker] > 0) {
                uint256 share = (_totalRewardPool * influenceStaked[staker]) / _totalInfluence;
                participantRewards[staker] += share;
            }
        }
    }

    /**
     * @dev Helper function (gas-inefficient for large sets) to get all staker addresses.
     * @return An array of staker addresses.
     */
    function _getAllStakers() internal view returns (address[] memory) {
        // This is a placeholder and should NOT be used in production for large user bases.
        // A more scalable solution would involve iterating over a `Set` or `EnumerableSet` from OpenZeppelin,
        // or using an off-chain Merkle tree for claimable rewards.
        // For this example, we assume a small, manageable number of stakers.
        address[] memory stakers; // This would be populated from a state variable (e.g., `EnumerableSet<address>`)
        // For now, return an empty array or hardcoded example stakers.
        return stakers;
    }

    function _getTotalStakedInfluence() internal view returns (uint256) {
        // In a real system, this would be `stakingToken.balanceOf(address(this))`
        // or a dynamically updated sum if tokens can be held elsewhere.
        // For this example, let's just use the direct balance for simplicity.
        return stakingToken.balanceOf(address(this));
    }


    // --- V. Dynamic NFT (Wisdom Orb) Management ---

    /**
     * @notice Allows eligible participants to mint their unique "Wisdom Orb" NFT.
     * @dev Eligibility requires meeting the `ORB_MINT_INFLUENCE_THRESHOLD` and not having an existing Orb.
     */
    function mintWisdomOrb() external nonReentrant whenNotPaused {
        require(influenceStaked[msg.sender] >= ORB_MINT_INFLUENCE_THRESHOLD, "Not enough influence to mint an Orb");
        require(participantOrbTokenId[msg.sender] == 0, "You already have a Wisdom Orb");

        _wisdomOrbTokenIds.increment();
        uint256 newTokenId = _wisdomOrbTokenIds.current();

        _mint(msg.sender, newTokenId);
        participantOrbTokenId[msg.sender] = newTokenId;

        WisdomOrb storage newOrb = _wisdomOrbs[newTokenId];
        newOrb.level = 1;
        newOrb.XP = 0;
        newOrb.mintEpoch = currentEpoch;
        newOrb.lastUpgradeEpoch = currentEpoch;

        emit WisdomOrbMinted(msg.sender, newTokenId, newOrb.level);
    }

    /**
     * @notice Dynamically updates the metadata URI for a Wisdom Orb.
     * @dev This function calculates the Orb's level based on accumulated performance and upgrades it.
     * This is a simplified example; a real system would have more complex XP/leveling logic.
     */
    function upgradeWisdomOrb(uint256 _tokenId) external {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not Orb owner or approved");
        WisdomOrb storage orb = _wisdomOrbs[_tokenId];
        require(orb.level > 0, "Orb does not exist");

        // Calculate XP based on owner's influence and protocol performance
        uint256 currentInfluence = influenceStaked[ownerOf(_tokenId)];
        uint256 rawXP = (currentInfluence * uint256(protocolPerformanceScore > 0 ? protocolPerformanceScore : 0)) / (10 ** 18); // Simplified XP
        orb.XP += rawXP;

        uint256 newLevel = orb.level;
        // Simple leveling system: e.g., level up for every 1000 XP
        while (orb.XP >= newLevel * 1000) {
            newLevel++;
            if (newLevel > 100) break; // Cap level for example
        }

        if (newLevel > orb.level) {
            orb.level = newLevel;
            orb.lastUpgradeEpoch = currentEpoch;
            emit WisdomOrbUpgraded(_tokenId, newLevel);
        }

        // The tokenURI function will now reflect the new level
    }

    /**
     * @notice Returns the dynamically generated metadata URI for a given Wisdom Orb NFT.
     * @param _tokenId The ID of the Wisdom Orb NFT.
     * @return The URI pointing to the JSON metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId);
        WisdomOrb storage orb = _wisdomOrbs[_tokenId];
        string memory base = _baseTokenURI;
        string memory tokenIdStr = _tokenId.toString();
        string memory levelStr = orb.level.toString();
        string memory performanceStr = protocolPerformanceScore.toString(); // Include global performance

        // Construct dynamic metadata URL
        // Example: https://api.example.com/sape/metadata/{tokenId}?level={level}&perf={performance}
        return string(abi.encodePacked(
            base,
            tokenIdStr,
            "?level=", levelStr,
            "&performance=", performanceStr,
            "&last_upgrade_epoch=", orb.lastUpgradeEpoch.toString()
        ));
    }

    /**
     * @notice Allows an owner to burn their Wisdom Orb NFT.
     * @param _tokenId The ID of the Wisdom Orb to burn.
     * @dev This removes the NFT from existence.
     */
    function burnWisdomOrb(uint256 _tokenId) external {
        _requireOwned(_tokenId);
        // Additional logic could include reclaiming a portion of staked influence, etc.
        delete _wisdomOrbs[_tokenId];
        delete participantOrbTokenId[ownerOf(_tokenId)]; // Remove mapping from owner to tokenId
        _burn(_tokenId);
    }

    // Internal mapping for Wisdom Orbs
    mapping(uint256 => WisdomOrb) private _wisdomOrbs;

    // --- VI. Strategy Module Management & Execution ---

    /**
     * @notice Allows the governor to register a new external IStrategyModule contract.
     * @param _moduleAddress The address of the strategy module contract.
     * @param _moduleId A unique bytes32 identifier for this module.
     * @dev This enables modularity, allowing new strategies to be added without upgrading the core contract.
     */
    function registerStrategyModule(address _moduleAddress, bytes32 _moduleId) external onlyProtocolGovernor {
        require(_moduleAddress != address(0), "Module address cannot be zero");
        require(registeredStrategyModules[_moduleId] == address(0), "Module ID already registered");
        require(IStrategyModule(_moduleAddress).getStrategyType() != "", "Invalid Strategy Module interface");

        registeredStrategyModules[_moduleId] = _moduleAddress;
        isStrategyModuleActive[_moduleId] = true;
        activeStrategyModuleIds.push(_moduleId);
        emit StrategyModuleRegistered(_moduleAddress, _moduleId);
    }

    /**
     * @notice Deactivates a previously registered strategy module, preventing it from being selected.
     * @param _moduleId The bytes32 identifier of the module to deactivate.
     * @dev Deactivation does not remove the module, just makes it inactive.
     */
    function deactivateStrategyModule(bytes32 _moduleId) external onlyProtocolGovernor {
        require(registeredStrategyModules[_moduleId] != address(0), "Module not registered");
        require(isStrategyModuleActive[_moduleId], "Module is already inactive");

        isStrategyModuleActive[_moduleId] = false;
        // Remove from activeStrategyModuleIds array (inefficient for large arrays)
        for (uint256 i = 0; i < activeStrategyModuleIds.length; i++) {
            if (activeStrategyModuleIds[i] == _moduleId) {
                activeStrategyModuleIds[i] = activeStrategyModuleIds[activeStrategyModuleIds.length - 1];
                activeStrategyModuleIds.pop();
                break;
            }
        }
        emit StrategyModuleDeactivated(registeredStrategyModules[_moduleId], _moduleId);
    }

    /**
     * @notice Retrieves a list of all currently registered and active strategy module IDs.
     * @return An array of bytes32 module IDs.
     */
    function getRegisteredStrategyModules() external view returns (bytes32[] memory) {
        return activeStrategyModuleIds;
    }

    /**
     * @dev Internal function to execute the chosen optimized action using a Strategy Module.
     * @param _strategyId The bytes32 ID of the strategy module to call.
     * @param _actionParameters The encoded parameters for the strategy's execution.
     * @return True if the strategy execution was successful, false otherwise.
     */
    function _executeOptimizedAction(bytes32 _strategyId, bytes memory _actionParameters) internal returns (bool) {
        address moduleAddress = registeredStrategyModules[_strategyId];
        if (moduleAddress == address(0) || !isStrategyModuleActive[_strategyId]) {
            revert SAPE_Protocol__InvalidStrategyModule();
        }

        // Call the external strategy module using low-level call to handle arbitrary parameters
        (bool success, ) = moduleAddress.call(
            abi.encodeWithSelector(
                IStrategyModule.executeStrategy.selector,
                targetGoalContract,
                _actionParameters
            )
        );
        return success;
    }

    // --- VII. Governance & Parameter Adjustment ---

    /**
     * @notice Allows influence holders to propose changes to protocol parameters.
     * @param _encodedCall The ABI-encoded function call to be executed if the proposal passes.
     * @dev Example: `abi.encodeWithSelector(SAPE_Protocol.setBaseRewardRatePerEpoch.selector, newRate)`
     */
    function proposeParameterChange(bytes memory _encodedCall) external whenNotPaused {
        require(influenceStaked[msg.sender] >= proposalMinInfluenceToPropose, "Not enough influence to propose");

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            data: _encodedCall,
            proposalEndTime: block.timestamp + proposalVotePeriod,
            votesFor: 0,
            votesAgainst: 0,
            proposer: influenceStaked[msg.sender], // Store proposer's influence at time of proposal
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize the nested mapping
        });

        emit ParameterChangeProposed(proposalId, _encodedCall, proposalMinInfluenceToPropose);
    }

    /**
     * @notice Allows influence holders to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', False for 'against'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.proposalEndTime, "Voting period has ended");
        require(influenceStaked[msg.sender] > 0, "No influence to vote with");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterInfluence = influenceStaked[msg.sender];
        if (_support) {
            proposal.votesFor += uint224(voterInfluence);
        } else {
            proposal.votesAgainst += uint224(voterInfluence);
        }
        proposal.hasVoted[msg.sender] = true;

        // Check if proposal can be updated to Succeeded/Failed
        uint256 totalInfluence = _getTotalStakedInfluence();
        if (block.timestamp >= proposal.proposalEndTime) {
            uint256 requiredVotes = (totalInfluence * proposalVoteThreshold) / 10000;
            if (proposal.votesFor >= requiredVotes && proposal.votesFor > proposal.votesAgainst) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }

        emit VoteCast(_proposalId, msg.sender, voterInfluence);
    }

    /**
     * @notice Executes a parameter change proposal if it has succeeded.
     * @param _proposalId The ID of the proposal to execute.
     * @dev Only the governor can trigger execution, ensuring proper state transitions.
     */
    function executeParameterChange(uint256 _proposalId) external onlyProtocolGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Succeeded, "Proposal not in Succeeded state");
        require(proposal.proposalEndTime < block.timestamp, "Voting period has not ended yet"); // Ensure end of voting period

        proposal.state = ProposalState.Executed;
        bool success;
        bytes memory returnData;

        // Execute the proposed call
        (success, returnData) = address(this).call(proposal.data);

        emit ParameterChangeExecuted(_proposalId, success);
        require(success, "Proposal execution failed");
    }

    /**
     * @notice Allows the protocol governor to update the target goal contract.
     * @param _newTargetGoalContract The address of the new target goal contract.
     */
    function setTargetGoalContract(address _newTargetGoalContract) external onlyProtocolGovernor {
        require(_newTargetGoalContract != address(0), "Target goal contract cannot be zero address");
        targetGoalContract = _newTargetGoalContract;
    }

    /**
     * @notice Allows the protocol governor to set the base reward rate per epoch.
     * @param _newRate The new base reward rate (e.g., 1e18 for 1%).
     */
    function setBaseRewardRatePerEpoch(uint256 _newRate) external onlyProtocolGovernor {
        baseRewardRatePerEpoch = _newRate;
    }

    /**
     * @notice Allows the protocol governor to set the performance reward multiplier.
     * @param _newMultiplier The new multiplier (e.g., 100 for 1x).
     */
    function setPerformanceRewardMultiplier(uint256 _newMultiplier) external onlyProtocolGovernor {
        performanceRewardMultiplier = _newMultiplier;
    }
}
```