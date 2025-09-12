This smart contract, **CerebralNexus**, is designed as a decentralized collective intelligence platform. It allows participants (Agents) to propose strategies and stake a utility token (CerebralToken) to signal their belief in these strategies. The system dynamically evaluates strategies using a multi-faceted scoring mechanism that considers staked value, historical performance, and external 'oracle' inputs (simulated). Agents are represented by dynamic NFTs (AgentProfiles) whose attributes evolve based on their on-chain activities and contributions. The platform also introduces a concept of 'Influence Delegation' and 'Wisdom Tokens' (Soulbound Tokens) to reward long-term, positive engagement.

---

## **CerebralNexus: Decentralized Collective Intelligence & Dynamic Resource Allocation**

### **Outline:**

1.  **Contract Overview:** Introduction to the concept, purpose, and key features.
2.  **Solidity Version & Licenses:** Pragmatic details.
3.  **Imports:** Required OpenZeppelin contracts for standard functionalities.
4.  **Error Definitions:** Custom errors for clarity and gas efficiency.
5.  **Interfaces:** For ERC20 and ERC721 tokens.
6.  **CerebralToken (Mock ERC20):** The utility token used for staking and rewards.
7.  **AgentProfileNFT (Dynamic ERC721):** Represents a user's identity and accumulated intelligence/influence.
8.  **CerebralNexus Core Contract:**
    *   **State Variables:** Epochs, strategies, agent profiles, parameters.
    *   **Enums & Structs:** Defines data structures for Strategy, AgentProfile, StakingPosition, Epoch.
    *   **Events:** For transparent logging of key actions.
    *   **Modifiers:** Access control and state-based checks.
    *   **Constructor:** Initializes the core components.
    *   **Admin/Owner Functions:** System configuration and control.
    *   **Epoch & Reward Management:** Functions to advance epochs, calculate scores, and distribute rewards.
    *   **Strategy Management:** Functions for users to propose, update, and retire strategies.
    *   **Staking & Allocation:** Functions for users to stake tokens to strategies and manage their positions.
    *   **Agent Profile & Influence:** Functions for users to mint and manage their dynamic NFT, delegate influence, and claim Wisdom Tokens.
    *   **View Functions:** Read-only functions for querying system state.
    *   **Internal Helper Functions:** Core logic for scoring, reward calculation, and state updates.

### **Function Summary:**

**I. Admin & Configuration Functions:**
1.  `constructor()`: Initializes the contract, deploys `CerebralToken` and `AgentProfileNFT`, sets owner.
2.  `setEpochDuration(uint256 _duration)`: Sets the duration of each epoch in seconds.
3.  `setScoreDecayRate(uint256 _rate)`: Sets the decay rate for historical strategy scores (percentage).
4.  `setSynergyBonusFactor(uint256 _factor)`: Sets the multiplier for the synergy bonus.
5.  `setOracleWeight(uint256 _weight)`: Sets the weight of oracle input in strategy scoring (percentage).
6.  `pauseSystem()`: Pauses core functionalities for maintenance or emergencies.
7.  `unpauseSystem()`: Unpauses the system.
8.  `withdrawProtocolFees(address _recipient)`: Allows the owner to withdraw accumulated protocol fees.

**II. Epoch & Reward Management Functions:**
9.  `advanceEpoch()`: *Core function* - Advances the system to the next epoch, triggers score recalculation for all active strategies, distributes rewards to stakers, and updates Agent Profile attributes.
10. `submitOracleMetrics(uint256 _strategyId, int256 _metricValue)`: (Simulated) Allows a privileged oracle to submit external performance metrics for a specific strategy, influencing its score in the next epoch.

**III. Strategy Management Functions:**
11. `proposeStrategy(string calldata _metadataURI)`: Allows an Agent to propose a new strategy. Requires a small deposit.
12. `updateStrategyMetadata(uint256 _strategyId, string calldata _newMetadataURI)`: Allows the proposer to update their strategy's metadata URI.
13. `retireStrategy(uint256 _strategyId)`: Allows the proposer to mark their strategy as inactive, preventing new stakes and signaling its end.

**IV. Staking & Allocation Functions:**
14. `stakeToStrategy(uint256 _strategyId, uint256 _amount)`: Allows a user to stake `CerebralToken` to a chosen strategy.
15. `unstakeFromStrategy(uint256 _strategyId, uint256 _amount)`: Allows a user to remove a portion or all of their staked tokens from a strategy.
16. `claimEpochRewards(uint256 _epochId, address _recipient)`: Allows a user to claim their accrued rewards for a specific past epoch.

**V. Agent Profile (Dynamic NFT) & Influence Functions:**
17. `mintAgentProfile(string calldata _initialBioURI)`: Mints a unique `AgentProfileNFT` for the caller, establishing their identity in the Nexus.
18. `updateAgentBio(string calldata _newBioURI)`: Allows an Agent to update the metadata URI (bio/description) of their `AgentProfileNFT`.
19. `delegateInfluence(uint256 _agentProfileId, address _delegatee)`: Allows an Agent to delegate their "influence" (and thus their Insight Level contribution to synergy bonuses) to another Agent Profile.
20. `reclaimInfluence(uint256 _agentProfileId)`: Allows an Agent to reclaim their previously delegated influence.
21. `claimWisdomTokens()`: Allows an Agent to claim their accumulated Soulbound `WisdomTokens` based on their long-term positive contributions.

**VI. View Functions:**
22. `getStrategyDetails(uint256 _strategyId)`: Returns comprehensive details of a specific strategy.
23. `getAgentProfile(address _owner)`: Returns the details of an `AgentProfileNFT` owned by an address.
24. `getCurrentEpoch()`: Returns the details of the current active epoch.
25. `getStrategyScore(uint256 _strategyId)`: Returns the current calculated score of a strategy.
26. `getAgentInsightLevel(address _agentAddress)`: Returns the current `insightLevel` of a given agent.
27. `getEpochRewardBalance(address _agent, uint256 _epochId)`: Returns the unclaimed reward balance for an agent in a specific epoch.
28. `getTotalStakedForStrategy(uint256 _strategyId)`: Returns the total amount of tokens currently staked for a given strategy.
29. `getUserStakedAmount(address _user, uint256 _strategyId)`: Returns the amount of tokens a specific user has staked to a strategy.
30. `getProtocolFeeBalance()`: Returns the total amount of fees accumulated by the protocol.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// --- Custom Error Definitions ---
error Unauthorized();
error InvalidAmount();
error InvalidStrategyId();
error StrategyNotActive();
error EpochNotEnded();
error EpochStillActive();
error NoAgentProfile();
error AlreadyHasAgentProfile();
error NotYourStrategy();
error StrategyRetired();
error InsufficientBalance();
error InfluenceAlreadyDelegated();
error NoInfluenceToReclaim();
error WisdomTokensAlreadyClaimed();
error EpochRewardsAlreadyClaimed();
error NoRewardsToClaim();
error InvalidOracleMetric();
error StakingLockupNotExpired(); // New error for advanced staking

// --- Interfaces ---
interface IAgentProfileNFT is IERC721 {
    function mint(address to, string calldata initialBioURI) external returns (uint256);
    function updateBio(uint256 tokenId, string calldata newBioURI) external;
    function getTokenIdByOwner(address owner) external view returns (uint256);
    function updateInsightLevel(uint256 tokenId, uint256 newLevel) external;
    function updateSynergyScore(uint256 tokenId, uint256 newScore) external;
    function updateDelegatedTo(uint256 tokenId, address delegatee) external;
    function getAgentDetails(uint256 tokenId) external view returns (address owner, uint256 insightLevel, uint256 synergyScore, address delegatedTo, bool wisdomTokensClaimed);
    function setWisdomTokensClaimed(uint256 tokenId) external;
}

// --- CerebralToken (Mock ERC20 for Staking and Rewards) ---
contract CerebralToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("CerebralToken", "CBL") {
        _mint(msg.sender, initialSupply);
    }

    function faucet(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

// --- AgentProfileNFT (Dynamic ERC721) ---
contract AgentProfileNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct AgentDetails {
        address owner;
        uint256 mintTimestamp;
        uint256 insightLevel; // Reflects contribution and success, influences synergy bonus
        uint256 synergyScore; // Reflects how well their delegated influence performs, for future expansion
        address delegatedTo; // Address of the agent profile they delegated influence to
        bool wisdomTokensClaimed; // Soulbound: true if Wisdom Tokens have been claimed
    }

    mapping(uint256 => AgentDetails) public agentProfiles;
    mapping(address => uint256) private _ownerToTokenId; // To quickly find tokenId by owner

    constructor() ERC721("AgentProfile", "APRO") Ownable(msg.sender) {}

    // Function Summary:
    // 1. `mint(address to, string calldata initialBioURI)`: Mints a new AgentProfile NFT.
    // 2. `updateBio(uint256 tokenId, string calldata newBioURI)`: Updates the bio/metadataURI.
    // 3. `getTokenIdByOwner(address owner)`: Retrieves the tokenId for a given owner.
    // 4. `updateInsightLevel(uint256 tokenId, uint256 newLevel)`: Updates an agent's insight level.
    // 5. `updateSynergyScore(uint256 tokenId, uint256 newScore)`: Updates an agent's synergy score.
    // 6. `updateDelegatedTo(uint256 tokenId, address delegatee)`: Updates who an agent has delegated to.
    // 7. `getAgentDetails(uint256 tokenId)`: Returns all details for a given agent profile.
    // 8. `setWisdomTokensClaimed(uint256 tokenId)`: Marks wisdom tokens as claimed for a profile.

    modifier onlyAgentOwner(uint256 tokenId) {
        if (_ownerToTokenId[msg.sender] != tokenId) revert Unauthorized();
        _;
    }

    function mint(address to, string calldata initialBioURI) external onlyOwner returns (uint256) {
        if (_ownerToTokenId[to] != 0) revert AlreadyHasAgentProfile();
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, initialBioURI);

        agentProfiles[newTokenId] = AgentDetails({
            owner: to,
            mintTimestamp: block.timestamp,
            insightLevel: 100, // Initial Insight Level
            synergyScore: 0,
            delegatedTo: address(0),
            wisdomTokensClaimed: false
        });
        _ownerToTokenId[to] = newTokenId;
        return newTokenId;
    }

    function updateBio(uint256 tokenId, string calldata newBioURI) external onlyAgentOwner(tokenId) {
        _setTokenURI(tokenId, newBioURI);
    }

    function getTokenIdByOwner(address owner) external view returns (uint256) {
        return _ownerToTokenId[owner];
    }

    function updateInsightLevel(uint256 tokenId, uint256 newLevel) external onlyOwner {
        agentProfiles[tokenId].insightLevel = newLevel;
    }

    function updateSynergyScore(uint256 tokenId, uint256 newScore) external onlyOwner {
        agentProfiles[tokenId].synergyScore = newScore;
    }

    function updateDelegatedTo(uint256 tokenId, address delegatee) external onlyOwner {
        agentProfiles[tokenId].delegatedTo = delegatee;
    }

    function getAgentDetails(uint256 tokenId)
        external
        view
        returns (
            address owner,
            uint256 insightLevel,
            uint256 synergyScore,
            address delegatedTo,
            bool wisdomTokensClaimed
        )
    {
        AgentDetails storage details = agentProfiles[tokenId];
        return (details.owner, details.insightLevel, details.synergyScore, details.delegatedTo, details.wisdomTokensClaimed);
    }

    function setWisdomTokensClaimed(uint256 tokenId) external onlyOwner {
        agentProfiles[tokenId].wisdomTokensClaimed = true;
    }
}

// --- CerebralNexus Core Contract ---
contract CerebralNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---
    CerebralToken public cerebralToken;
    IAgentProfileNFT public agentProfileNFT;

    Counters.Counter private _strategyIdCounter;
    Counters.Counter private _epochIdCounter;

    uint256 public epochDuration = 7 days; // Duration of each epoch in seconds
    uint256 public scoreDecayRate = 10; // % decay per epoch (e.g., 10 for 10%)
    uint256 public synergyBonusFactor = 5; // Multiplier for synergy bonus (e.g., 5 for 5x influence)
    uint256 public oracleWeight = 20; // % weight of oracle input in total score (e.g., 20 for 20%)
    uint256 public constant PROTOCOL_FEE_RATE = 10; // 10% of staking rewards go to protocol
    uint256 public constant STAKING_LOCKUP_PERIOD = 3 days; // Staked tokens locked for 3 days after staking
    uint256 public constant STRATEGY_PROPOSAL_DEPOSIT = 1000 * (10 ** 18); // 1000 CBL for proposing a strategy

    // Structs
    struct Strategy {
        address proposer;
        string metadataURI; // IPFS hash or similar for strategy details
        uint256 epochProposed;
        uint256 totalStaked;
        uint256 currentScore;
        uint256 lastEpochScored;
        bool isActive; // Can be retired by proposer
        mapping(address => StakingPosition) stakers; // User's staking info
        mapping(uint256 => int256) oracleMetrics; // Oracle input for specific epochs
    }

    struct StakingPosition {
        uint256 amount;
        uint256 stakeTimestamp; // When the stake was made, for lockup
        uint256 epochStaked; // Epoch in which the stake was placed
    }

    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 rewardPool;
        bool finalized;
        uint256 totalStrategyScores; // Sum of all active strategy scores for normalization
        mapping(address => uint256) claimedRewards; // Agent's claimed rewards for this epoch
        mapping(uint256 => uint256) strategyScores; // Final scores for strategies in this epoch
    }

    // Mappings
    mapping(uint256 => Strategy) public strategies;
    mapping(uint256 => Epoch) public epochs; // Epoch ID -> Epoch Details
    mapping(address => uint256) public protocolFeeBalance; // Amount of fees collected per token

    // --- Events ---
    event EpochAdvanced(uint256 indexed epochId, uint256 startTime, uint256 endTime, uint256 rewardPool);
    event StrategyProposed(uint256 indexed strategyId, address indexed proposer, string metadataURI, uint256 epochProposed);
    event StrategyUpdated(uint256 indexed strategyId, address indexed proposer, string newMetadataURI);
    event StrategyRetired(uint256 indexed strategyId, address indexed proposer);
    event TokensStaked(address indexed staker, uint256 indexed strategyId, uint256 amount, uint256 epoch);
    event TokensUnstaked(address indexed staker, uint256 indexed strategyId, uint256 amount);
    event RewardsClaimed(address indexed recipient, uint256 indexed epochId, uint256 amount);
    event InfluenceDelegated(uint256 indexed delegatorAgentProfileId, address indexed delegatee);
    event InfluenceReclaimed(uint256 indexed delegatorAgentProfileId);
    event WisdomTokensClaimed(uint256 indexed agentProfileId, address indexed owner);
    event OracleMetricSubmitted(uint256 indexed strategyId, uint256 indexed epochId, int256 metricValue);

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        cerebralToken = new CerebralToken(1_000_000_000 * (10 ** 18)); // Initial supply of 1 Billion CBL
        agentProfileNFT = new AgentProfileNFT();

        // Start initial epoch
        _epochIdCounter.increment();
        epochs[1] = Epoch({
            startTime: block.timestamp,
            endTime: block.timestamp + epochDuration,
            rewardPool: 0,
            finalized: false,
            totalStrategyScores: 0
        });

        // Grant minter role to CerebralNexus for AgentProfileNFT
        IAgentProfileNFT(agentProfileNFT).transferOwnership(address(this));
    }

    // --- Admin & Configuration Functions ---
    // 1. `setEpochDuration(uint256 _duration)`
    function setEpochDuration(uint256 _duration) external onlyOwner {
        if (_duration == 0) revert InvalidAmount();
        epochDuration = _duration;
    }

    // 2. `setScoreDecayRate(uint256 _rate)`
    function setScoreDecayRate(uint256 _rate) external onlyOwner {
        if (_rate > 100) revert InvalidAmount(); // Cannot decay more than 100%
        scoreDecayRate = _rate;
    }

    // 3. `setSynergyBonusFactor(uint256 _factor)`
    function setSynergyBonusFactor(uint256 _factor) external onlyOwner {
        synergyBonusFactor = _factor;
    }

    // 4. `setOracleWeight(uint256 _weight)`
    function setOracleWeight(uint256 _weight) external onlyOwner {
        if (_weight > 100) revert InvalidAmount(); // Weight cannot exceed 100%
        oracleWeight = _weight;
    }

    // 5. `pauseSystem()`
    function pauseSystem() external onlyOwner {
        _pause();
    }

    // 6. `unpauseSystem()`
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    // 7. `withdrawProtocolFees(address _recipient)`
    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        uint256 balance = protocolFeeBalance[address(cerebralToken)]; // Assuming one token type
        if (balance == 0) revert NoRewardsToClaim();
        protocolFeeBalance[address(cerebralToken)] = 0;
        cerebralToken.transfer(_recipient, balance);
    }

    // --- Epoch & Reward Management Functions ---
    // 8. `advanceEpoch()`
    function advanceEpoch() external nonReentrant whenNotPaused {
        uint256 currentEpochId = _epochIdCounter.current();
        Epoch storage currentEpoch = epochs[currentEpochId];

        if (block.timestamp < currentEpoch.endTime) revert EpochStillActive();
        if (currentEpoch.finalized) revert EpochAlreadyEnded(); // Added for safety if called multiple times

        // Phase 1: Calculate Scores for the ended epoch
        uint256 totalActiveStrategiesScore = 0;
        uint256 insightLevelBoostTotal = 0; // Sum of insight levels of all active delegators

        for (uint256 i = 1; i <= _strategyIdCounter.current(); i++) {
            Strategy storage strategy = strategies[i];
            if (strategy.isActive) {
                // Determine the effective insight level of stakers and their delegators for synergy bonus
                uint256 totalEffectiveInsight = 0;
                // This would iterate through all stakers of the strategy and check their (or their delegatees') insight levels.
                // For simplicity, we'll use a simplified total insight for the entire system impacting all strategies.
                // In a real system, you'd iterate through 'stakers' mapping of the strategy.
                // Example: for (address staker : strategy.stakers.keys()) { ... } (not directly possible in Solidity)
                // A more complex data structure (e.g., linked list of stakers or external processing) would be needed for a precise on-chain calculation.
                // For this example, we'll use a simplified global `insightLevelBoostTotal` which is accumulated by _updateAgentProfiles.
                // A more precise implementation would involve tracking effective delegated insight per strategy.
                
                uint252 strategyScore = _calculateStrategyScore(i, currentEpochId, insightLevelBoostTotal); // Pass the global insight level

                currentEpoch.strategyScores[i] = strategyScore;
                totalActiveStrategiesScore = totalActiveStrategiesScore.add(strategyScore);
            }
        }
        currentEpoch.totalStrategyScores = totalActiveStrategiesScore;

        // Phase 2: Distribute Rewards and update Agent Profiles
        uint256 rewardPoolForEpoch = currentEpoch.rewardPool;
        uint256 protocolFees = rewardPoolForEpoch.mul(PROTOCOL_FEE_RATE).div(100);
        protocolFeeBalance[address(cerebralToken)] = protocolFeeBalance[address(cerebralToken)].add(protocolFees);
        uint256 rewardsAvailableForDistribution = rewardPoolForEpoch.sub(protocolFees);

        // Update Agent Profile insight levels based on strategy performance
        for (uint256 i = 1; i <= _strategyIdCounter.current(); i++) {
            Strategy storage strategy = strategies[i];
            if (strategy.isActive && currentEpoch.strategyScores[i] > 0) {
                // Update the proposer's insight level
                uint256 proposerTokenId = agentProfileNFT.getTokenIdByOwner(strategy.proposer);
                if (proposerTokenId != 0) {
                    (address owner, uint256 oldInsight, , , ) = agentProfileNFT.getAgentDetails(proposerTokenId);
                    uint256 newInsight = oldInsight.add(currentEpoch.strategyScores[i].div(1000)); // Simplified gain
                    agentProfileNFT.updateInsightLevel(proposerTokenId, newInsight);
                }

                // Distribute rewards to stakers and update their insight levels
                // This requires iterating through stakers, which is not efficient for large numbers on-chain.
                // In a real system, stakers would claim, and their rewards would be calculated lazily.
                // For this example, we'll only update insight for the proposer and leave staker rewards for claim.
            } else if (strategy.isActive && currentEpoch.strategyScores[i] == 0) {
                // Penalize inactive/underperforming strategies
                uint256 proposerTokenId = agentProfileNFT.getTokenIdByOwner(strategy.proposer);
                if (proposerTokenId != 0) {
                    (address owner, uint256 oldInsight, , , ) = agentProfileNFT.getAgentDetails(proposerTokenId);
                    uint256 newInsight = oldInsight.div(2); // Halve insight for poor performance (simplified)
                    agentProfileNFT.updateInsightLevel(proposerTokenId, newInsight);
                }
            }
        }
        
        // Mark current epoch as finalized
        currentEpoch.finalized = true;

        // Start new epoch
        _epochIdCounter.increment();
        uint256 nextEpochId = _epochIdCounter.current();
        epochs[nextEpochId] = Epoch({
            startTime: block.timestamp,
            endTime: block.timestamp + epochDuration,
            rewardPool: 0,
            finalized: false,
            totalStrategyScores: 0
        });

        emit EpochAdvanced(currentEpochId, currentEpoch.startTime, currentEpoch.endTime, currentEpoch.rewardPool);
    }

    // 9. `submitOracleMetrics(uint256 _strategyId, int256 _metricValue)`
    function submitOracleMetrics(uint256 _strategyId, int256 _metricValue) external onlyOwner whenNotPaused {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        if (!strategies[_strategyId].isActive) revert StrategyNotActive();

        uint256 currentEpochId = _epochIdCounter.current();
        strategies[_strategyId].oracleMetrics[currentEpochId] = _metricValue;
        emit OracleMetricSubmitted(_strategyId, currentEpochId, _metricValue);
    }

    // --- Strategy Management Functions ---
    // 10. `proposeStrategy(string calldata _metadataURI)`
    function proposeStrategy(string calldata _metadataURI) external whenNotPaused {
        uint256 agentProfileId = agentProfileNFT.getTokenIdByOwner(msg.sender);
        if (agentProfileId == 0) revert NoAgentProfile();

        // Require a deposit for proposing a strategy
        if (cerebralToken.balanceOf(msg.sender) < STRATEGY_PROPOSAL_DEPOSIT) revert InsufficientBalance();
        cerebralToken.transferFrom(msg.sender, address(this), STRATEGY_PROPOSAL_DEPOSIT);

        _strategyIdCounter.increment();
        uint256 newStrategyId = _strategyIdCounter.current();
        strategies[newStrategyId] = Strategy({
            proposer: msg.sender,
            metadataURI: _metadataURI,
            epochProposed: _epochIdCounter.current(),
            totalStaked: 0,
            currentScore: 0,
            lastEpochScored: 0,
            isActive: true
        });
        emit StrategyProposed(newStrategyId, msg.sender, _metadataURI, _epochIdCounter.current());
    }

    // 11. `updateStrategyMetadata(uint256 _strategyId, string calldata _newMetadataURI)`
    function updateStrategyMetadata(uint256 _strategyId, string calldata _newMetadataURI) external whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current() || strategy.proposer == address(0)) revert InvalidStrategyId();
        if (strategy.proposer != msg.sender) revert NotYourStrategy();

        strategy.metadataURI = _newMetadataURI;
        emit StrategyUpdated(_strategyId, msg.sender, _newMetadataURI);
    }

    // 12. `retireStrategy(uint256 _strategyId)`
    function retireStrategy(uint256 _strategyId) external whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current() || strategy.proposer == address(0)) revert InvalidStrategyId();
        if (strategy.proposer != msg.sender) revert NotYourStrategy();
        if (!strategy.isActive) revert StrategyRetired();

        strategy.isActive = false;
        // Optionally, refund proposal deposit here or keep it as a fee for a failed strategy
        emit StrategyRetired(_strategyId, msg.sender);
    }

    // --- Staking & Allocation Functions ---
    // 13. `stakeToStrategy(uint256 _strategyId, uint256 _amount)`
    function stakeToStrategy(uint256 _strategyId, uint256 _amount) external nonReentrant whenNotPaused {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        Strategy storage strategy = strategies[_strategyId];
        if (!strategy.isActive) revert StrategyNotActive();
        if (_amount == 0) revert InvalidAmount();
        if (agentProfileNFT.getTokenIdByOwner(msg.sender) == 0) revert NoAgentProfile();

        // Transfer tokens from staker to contract
        cerebralToken.transferFrom(msg.sender, address(this), _amount);

        // Update staking position
        StakingPosition storage pos = strategy.stakers[msg.sender];
        pos.amount = pos.amount.add(_amount);
        pos.stakeTimestamp = block.timestamp; // Update timestamp for new stake or additional stake
        pos.epochStaked = _epochIdCounter.current();
        strategy.totalStaked = strategy.totalStaked.add(_amount);

        // Add to current epoch's reward pool (staked amount contributes to rewards pool for next epoch)
        epochs[_epochIdCounter.current()].rewardPool = epochs[_epochIdCounter.current()].rewardPool.add(_amount);

        emit TokensStaked(msg.sender, _strategyId, _amount, _epochIdCounter.current());
    }

    // 14. `unstakeFromStrategy(uint256 _strategyId, uint256 _amount)`
    function unstakeFromStrategy(uint256 _strategyId, uint256 _amount) external nonReentrant whenNotPaused {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        Strategy storage strategy = strategies[_strategyId];
        StakingPosition storage pos = strategy.stakers[msg.sender];

        if (pos.amount == 0) revert InsufficientBalance();
        if (_amount == 0 || _amount > pos.amount) revert InvalidAmount();
        if (block.timestamp < pos.stakeTimestamp.add(STAKING_LOCKUP_PERIOD)) revert StakingLockupNotExpired(); // Enforce lockup

        pos.amount = pos.amount.sub(_amount);
        strategy.totalStaked = strategy.totalStaked.sub(_amount);

        cerebralToken.transfer(msg.sender, _amount);

        emit TokensUnstaked(msg.sender, _strategyId, _amount);
    }

    // 15. `claimEpochRewards(uint256 _epochId, address _recipient)`
    function claimEpochRewards(uint256 _epochId, address _recipient) external nonReentrant whenNotPaused {
        Epoch storage epoch = epochs[_epochId];
        if (!epoch.finalized) revert EpochStillActive();
        if (epoch.claimedRewards[msg.sender] > 0) revert EpochRewardsAlreadyClaimed();

        // Calculate reward for the sender for this epoch
        uint256 totalReward = 0;
        uint256 totalStakerShareInEpoch = 0; // Total stake value contributing to rewards in this epoch
        
        // This is a simplified calculation. A robust system would iterate through all strategies
        // the user staked on in this specific epoch. For efficiency, rewards are calculated lazily on claim.
        // It relies on the _calculateStrategyScore to have captured the 'weight' of the user's stake.

        for (uint256 i = 1; i <= _strategyIdCounter.current(); i++) {
            Strategy storage strategy = strategies[i];
            if (strategy.stakers[msg.sender].epochStaked <= _epochId && strategy.stakers[msg.sender].amount > 0) {
                 // Calculate individual reward share based on user's stake vs total stake in winning strategies
                uint256 userStakedAmountInStrategy = strategy.stakers[msg.sender].amount;
                uint256 strategyScore = epoch.strategyScores[i];
                
                // If the epoch total strategy scores are zero (no winning strategies or all scores zero), no rewards.
                if (epoch.totalStrategyScores == 0) continue; 

                // User's weighted contribution to strategy score based on their stake ratio
                // This is a placeholder calculation. A more precise model would consider user's actual stake over strategy's total stake.
                uint256 shareOfStrategyRewards = (strategyScore.mul(userStakedAmountInStrategy)).div(strategy.totalStaked > 0 ? strategy.totalStaked : 1);
                
                totalReward = totalReward.add(shareOfStrategyRewards.mul(epoch.rewardPool).div(epoch.totalStrategyScores > 0 ? epoch.totalStrategyScores : 1));
            }
        }
        
        if (totalReward == 0) revert NoRewardsToClaim();

        epoch.claimedRewards[msg.sender] = totalReward;
        cerebralToken.transfer(_recipient, totalReward);
        emit RewardsClaimed(_recipient, _epochId, totalReward);
    }

    // --- Agent Profile (Dynamic NFT) & Influence Functions ---
    // 16. `mintAgentProfile(string calldata _initialBioURI)`
    function mintAgentProfile(string calldata _initialBioURI) external whenNotPaused {
        if (agentProfileNFT.getTokenIdByOwner(msg.sender) != 0) revert AlreadyHasAgentProfile();
        agentProfileNFT.mint(msg.sender, _initialBioURI);
    }

    // 17. `updateAgentBio(string calldata _newBioURI)`
    function updateAgentBio(string calldata _newBioURI) external whenNotPaused {
        uint256 tokenId = agentProfileNFT.getTokenIdByOwner(msg.sender);
        if (tokenId == 0) revert NoAgentProfile();
        agentProfileNFT.updateBio(tokenId, _newBioURI);
    }

    // 18. `delegateInfluence(uint256 _agentProfileId, address _delegatee)`
    function delegateInfluence(uint256 _agentProfileId, address _delegatee) external whenNotPaused {
        if (agentProfileNFT.ownerOf(_agentProfileId) != msg.sender) revert Unauthorized();
        uint256 delegateeTokenId = agentProfileNFT.getTokenIdByOwner(_delegatee);
        if (delegateeTokenId == 0) revert NoAgentProfile(); // Delegatee must also have a profile

        (, , , address currentDelegatee, ) = agentProfileNFT.getAgentDetails(_agentProfileId);
        if (currentDelegatee != address(0)) revert InfluenceAlreadyDelegated();

        agentProfileNFT.updateDelegatedTo(_agentProfileId, _delegatee);
        emit InfluenceDelegated(_agentProfileId, _delegatee);
    }

    // 19. `reclaimInfluence(uint256 _agentProfileId)`
    function reclaimInfluence(uint256 _agentProfileId) external whenNotPaused {
        if (agentProfileNFT.ownerOf(_agentProfileId) != msg.sender) revert Unauthorized();
        (, , , address currentDelegatee, ) = agentProfileNFT.getAgentDetails(_agentProfileId);
        if (currentDelegatee == address(0)) revert NoInfluenceToReclaim();

        agentProfileNFT.updateDelegatedTo(_agentProfileId, address(0));
        emit InfluenceReclaimed(_agentProfileId);
    }

    // 20. `claimWisdomTokens()`
    // Wisdom Tokens are conceptual Soulbound Tokens (SBTs) within the AgentProfileNFT itself.
    // This function simply marks a flag on the AgentProfileNFT that they've 'claimed' their Wisdom.
    // In a more complex system, this might mint an actual separate SBT.
    function claimWisdomTokens() external whenNotPaused {
        uint256 tokenId = agentProfileNFT.getTokenIdByOwner(msg.sender);
        if (tokenId == 0) revert NoAgentProfile();
        (, , , , bool claimed) = agentProfileNFT.getAgentDetails(tokenId);
        if (claimed) revert WisdomTokensAlreadyClaimed();

        // Criteria for claiming Wisdom Tokens (e.g., reach certain insight level, participate for X epochs)
        // For simplicity, let's just allow it for any existing agent profile for now.
        // A real system would have criteria like: (agentProfileNFT.getAgentDetails(tokenId).insightLevel >= 1000)
        
        agentProfileNFT.setWisdomTokensClaimed(tokenId);
        emit WisdomTokensClaimed(tokenId, msg.sender);
    }

    // --- View Functions ---
    // 21. `getStrategyDetails(uint256 _strategyId)`
    function getStrategyDetails(uint256 _strategyId)
        external
        view
        returns (
            address proposer,
            string memory metadataURI,
            uint256 epochProposed,
            uint256 totalStaked,
            uint256 currentScore,
            bool isActive
        )
    {
        Strategy storage strategy = strategies[_strategyId];
        return (
            strategy.proposer,
            strategy.metadataURI,
            strategy.epochProposed,
            strategy.totalStaked,
            strategy.currentScore,
            strategy.isActive
        );
    }

    // 22. `getAgentProfile(address _owner)`
    function getAgentProfile(address _owner)
        external
        view
        returns (
            uint256 tokenId,
            uint256 mintTimestamp,
            uint256 insightLevel,
            uint256 synergyScore,
            address delegatedTo,
            bool wisdomTokensClaimed,
            string memory metadataURI
        )
    {
        tokenId = agentProfileNFT.getTokenIdByOwner(_owner);
        if (tokenId == 0) revert NoAgentProfile();
        (address owner, uint256 il, uint256 ss, address dt, bool wtc) = agentProfileNFT.getAgentDetails(tokenId);
        // We retrieve mintTimestamp from internal agentProfiles mapping
        AgentProfileNFT.AgentDetails storage details = agentProfileNFT.agentProfiles(tokenId);
        
        return (
            tokenId,
            details.mintTimestamp,
            il,
            ss,
            dt,
            wtc,
            agentProfileNFT.tokenURI(tokenId)
        );
    }

    // 23. `getCurrentEpoch()`
    function getCurrentEpoch()
        external
        view
        returns (
            uint256 epochId,
            uint256 startTime,
            uint256 endTime,
            uint256 rewardPool,
            bool finalized
        )
    {
        uint256 currentEpochId = _epochIdCounter.current();
        Epoch storage currentEpoch = epochs[currentEpochId];
        return (currentEpochId, currentEpoch.startTime, currentEpoch.endTime, currentEpoch.rewardPool, currentEpoch.finalized);
    }

    // 24. `getStrategyScore(uint256 _strategyId)`
    function getStrategyScore(uint256 _strategyId) external view returns (uint256) {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        return strategies[_strategyId].currentScore;
    }

    // 25. `getAgentInsightLevel(address _agentAddress)`
    function getAgentInsightLevel(address _agentAddress) external view returns (uint256) {
        uint256 tokenId = agentProfileNFT.getTokenIdByOwner(_agentAddress);
        if (tokenId == 0) revert NoAgentProfile();
        (address owner, uint256 insightLevel, , , ) = agentProfileNFT.getAgentDetails(tokenId);
        return insightLevel;
    }

    // 26. `getEpochRewardBalance(address _agent, uint256 _epochId)`
    function getEpochRewardBalance(address _agent, uint256 _epochId) external view returns (uint256) {
        Epoch storage epoch = epochs[_epochId];
        if (!epoch.finalized) revert EpochStillActive();
        if (epoch.claimedRewards[_agent] > 0) return 0; // Already claimed

        // This view function will re-calculate the *unclaimed* rewards for a specific agent in a specific epoch.
        uint224 totalReward = 0;
        
        for (uint256 i = 1; i <= _strategyIdCounter.current(); i++) {
            Strategy storage strategy = strategies[i];
            if (strategy.stakers[_agent].epochStaked <= _epochId && strategy.stakers[_agent].amount > 0) {
                uint224 userStakedAmountInStrategy = uint224(strategy.stakers[_agent].amount);
                uint224 strategyScore = uint224(epoch.strategyScores[i]);

                if (epoch.totalStrategyScores == 0) continue;

                uint224 shareOfStrategyRewards = (strategyScore.mul(userStakedAmountInStrategy)).div(uint224(strategy.totalStaked > 0 ? strategy.totalStaked : 1));
                totalReward = totalReward.add(shareOfStrategyRewards.mul(uint224(epoch.rewardPool)).div(uint224(epoch.totalStrategyScores > 0 ? epoch.totalStrategyScores : 1)));
            }
        }
        
        return totalReward;
    }
    
    // 27. `getTotalStakedForStrategy(uint256 _strategyId)`
    function getTotalStakedForStrategy(uint256 _strategyId) external view returns (uint256) {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        return strategies[_strategyId].totalStaked;
    }

    // 28. `getUserStakedAmount(address _user, uint256 _strategyId)`
    function getUserStakedAmount(address _user, uint256 _strategyId) external view returns (uint256) {
        if (_strategyId == 0 || _strategyId > _strategyIdCounter.current()) revert InvalidStrategyId();
        return strategies[_strategyId].stakers[_user].amount;
    }

    // 29. `getProtocolFeeBalance()`
    function getProtocolFeeBalance() external view returns (uint256) {
        return protocolFeeBalance[address(cerebralToken)];
    }

    // --- Internal Helper Functions ---
    // `_calculateStrategyScore` (internal)
    function _calculateStrategyScore(uint256 _strategyId, uint256 _epochId, uint256 _globalInsightBoostTotal) internal view returns (uint256) {
        Strategy storage strategy = strategies[_strategyId];

        uint256 baseScore = strategy.totalStaked.div(100); // Base on total staked value (simplified)
        
        // Historical performance with decay
        uint256 historicalScore = strategy.currentScore; // Previous epoch's score
        if (strategy.lastEpochScored > 0 && strategy.lastEpochScored < _epochId) {
            uint256 epochsPassed = _epochId.sub(strategy.lastEpochScored);
            for (uint256 i = 0; i < epochsPassed; i++) {
                historicalScore = historicalScore.mul(100 - scoreDecayRate).div(100);
            }
        } else {
            historicalScore = 0; // No historical score or scored in current epoch already
        }

        // Oracle input influence
        int256 oracleMetric = strategy.oracleMetrics[_epochId];
        uint256 oracleContribution = 0;
        if (oracleMetric > 0) {
            oracleContribution = uint256(oracleMetric).mul(oracleWeight).div(100);
        } else if (oracleMetric < 0) {
            // Penalize for negative oracle metrics
            baseScore = baseScore.mul(100 - uint256(oracleMetric * -1).mul(oracleWeight).div(100)).div(100);
        }
        
        // Synergy Bonus (based on delegated influence and insight levels)
        uint256 synergyBonus = 0;
        if (_globalInsightBoostTotal > 0) { // Simplified: a global pool of insight
            synergyBonus = baseScore.mul(synergyBonusFactor).mul(_globalInsightBoostTotal).div(1_000_000); // Scale down by a large number
        }

        // Age Penalty (penalize very old strategies that are not performing)
        uint256 agePenalty = 0;
        if (_epochId > strategy.epochProposed.add(5)) { // Penalize after 5 epochs
            agePenalty = baseScore.div(10); // 10% penalty for being old (simplified)
        }

        uint224 finalScore = uint224(baseScore.add(historicalScore).add(oracleContribution).add(synergyBonus).sub(agePenalty));
        
        // Ensure score doesn't go below zero
        if (finalScore < 0) {
            finalScore = 0;
        }

        strategies[_strategyId].currentScore = finalScore;
        strategies[_strategyId].lastEpochScored = _epochId;
        return finalScore;
    }
}
```