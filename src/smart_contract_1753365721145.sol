The smart contract below, named `ChronosForge Protocol`, aims to be an interesting, advanced-concept, creative, and trendy piece of Solidity engineering. It combines elements of dynamic treasury management, a reputation-based governance council, and a gamified, adaptive staking mechanism, all tied to a time-based "Epoch" system. The goal is to create a protocol that can adapt its resource allocation strategies based on internal states and potentially external data.

---

**Contract Name:** `ChronosForge Protocol`

**Concept Overview:**
The `ChronosForge Protocol` is an innovative, time-anchored, and adaptive treasury and resource management system for digital assets (ERC20 tokens). It aims to create a dynamic and self-regulating decentralized economy by:

1.  **Epoch-based Operations:** Organizing all protocol activities and distributions into distinct time periods called "Epochs."
2.  **Adaptive Treasury Distribution:** Allowing the protocol's treasury to distribute funds based on a flexible plan that can be influenced by internal and external (oracle-fed) parameters, adapting to network health or market conditions.
3.  **Epoch Weaver System:** A decentralized governance council where users stake governance tokens to become "Weavers." Weavers propose and vote on adjustments to future epoch distribution plans, fostering community-driven resource allocation. This system includes a basic dispute resolution mechanism and dynamic limits on active weavers.
4.  **Temporal Forging (Dynamic Staking):** A gamified staking mechanism where users lock assets for specific epoch durations. Rewards are not fixed but scale dynamically with the lock-up period and can be influenced by protocol-wide reward multipliers, providing a more engaging yield experience.
5.  **Dynamic Oracle & Adaptive Strategy:** A flexible system to integrate abstract external data (via `bytes32` keys) that can influence internal protocol parameters, enabling a truly adaptive and potentially "AI-informed" (if paired with an off-chain AI oracle) resource allocation strategy.

---

**Function Summary:**

**I. Core Protocol State & Configuration**

1.  `constructor(address _owner, uint256 _initialEpochDuration, uint256 _minWeaverStakeAmount, address _governanceToken)`: Initializes the contract upon deployment. Sets the initial owner, epoch duration, minimum stake for Epoch Weavers, and the governance token address.
2.  `setEpochDuration(uint256 _newDuration)`: Allows the owner/governance to adjust the length (in seconds) of each epoch.
3.  `setMinWeaverStake(uint256 _newMinStake)`: Sets the minimum amount of governance tokens required for a user to be eligible as an Epoch Weaver.
4.  `setMaxActiveWeavers(uint256 _newLimit)`: Sets the maximum number of addresses that can be active Epoch Weavers at any given time.
5.  `setTreasuryDistributionPlan(uint256[] memory _percentagesForCategories)`: Defines the default percentage allocation of treasury funds across different categories (e.g., Forged Rewards, Bounties, Development Fund). Sum of percentages must be 100% (10000 basis points).
6.  `updateProtocolParameter(bytes32 _paramKey, uint256 _newValue)`: Allows the owner (or a whitelisted oracle in a real setup) to update abstract protocol-wide parameters (e.g., "protocol health score," "market volatility index") that can dynamically influence other protocol behaviors.
7.  `setDynamicInfluenceFactor(bytes32 _paramKey, uint256 _categoryIndex, uint256 _influencePercentage)`: Configures how much a specific `dynamicProtocolParameter` (identified by `_paramKey`) will influence the distribution percentage of a particular category (identified by `_categoryIndex`) in the treasury plan.

**II. Treasury & Epoch Management**

8.  `depositTreasuryFunds(address _token, uint256 _amount)`: Enables any user to deposit ERC20 tokens into the ChronosForge treasury.
9.  `withdrawTreasuryFunds(address _token, uint256 _amount, address _recipient)`: Allows the owner/governance to withdraw specified ERC20 tokens from the treasury, typically for approved initiatives or emergency.
10. `passEpoch()`: Advances the protocol to the next epoch if the current epoch duration has elapsed. This function also triggers the internal distribution of epoch rewards.

**III. Epoch Weaver System (Decentralized Governance Council)**

11. `stakeAsWeaver(uint256 _amount)`: Allows a user to stake governance tokens to become a candidate for an Epoch Weaver role. If the stake meets the minimum and a slot is available, they become active.
12. `unstakeAsWeaver(uint256 _amount)`: Allows a weaver to unstake their governance tokens. Active weavers must first be deactivated (e.g., via dispute resolution or stepping down).
13. `proposeDistributionOverride(uint256 _targetEpoch, uint256[] memory _newPercentages)`: Active Epoch Weavers can propose a temporary override to the default treasury distribution plan for a specified future epoch.
14. `voteOnProposal(uint256 _proposalId, bool _support)`: Active Epoch Weavers can cast a 'yes' or 'no' vote on outstanding distribution override proposals.
15. `executeProposal(uint256 _proposalId)`: Any user can call this to execute a proposal that has met its required vote threshold, applying the proposed distribution plan to the future `targetEpoch`.
16. `submitWeaverDispute(address _weaverAddress, string memory _reasonHash)`: Allows any user to submit a formal dispute against an Epoch Weaver, citing alleged malicious behavior with an off-chain evidence hash (e.g., IPFS link).
17. `resolveWeaverDispute(uint256 _disputeId, address _weaverAddress, bool _guilty, uint256 _slashAmount)`: Owner/governance resolves a submitted dispute. If the Weaver is found `_guilty`, a specified `_slashAmount` of their staked tokens can be removed and sent to the treasury.

**IV. Temporal Forging (Dynamic Staking/Locking)**

18. `forgeAssets(address _token, uint256 _amount, uint256 _lockUntilEpoch)`: Users lock specified ERC20 tokens for a duration until a future epoch. These "forged" assets accrue dynamic rewards.
19. `claimForgedRewards(address _token)`: Allows users to claim accumulated rewards from their forged assets for a specific token, based on elapsed epochs and defined reward rates.
20. `unforgeAssets(address _token)`: Allows users to unlock and withdraw their forged assets once their specified `_lockUntilEpoch` has passed.
21. `setForgingRewardRates(address _token, uint256[] memory _epochMultipliers)`: Owner/governance sets the reward multipliers for forging a specific token. Different multipliers can be set for different lock durations (e.g., longer locks get higher multipliers).
22. `registerForgeableToken(address _tokenAddress, bool _isForgeable)`: Owner/governance whitelists or blacklists ERC20 tokens that can be used in the Temporal Forging mechanism.

**V. Utility & View Functions**

23. `getLockedAssets(address _user, address _token)`: Returns the total amount of a specific token currently locked by a given user.
24. `getPendingForgedYield(address _user, address _token)`: Calculates and returns the estimated pending rewards for a user for a specific forged token, considering elapsed epochs and current reward rates.
25. `getWeaverStatus(address _weaverAddress)`: Returns the staked amount and active status of a given Epoch Weaver.
26. `getEpochMapProposal(uint256 _proposalId)`: Retrieves details about a specific epoch map adjustment proposal, including target epoch, proposed percentages, vote counts, and execution status.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Note: In a production system, `Ownable` should ideally be replaced by a more sophisticated
// governance module (e.g., a DAO contract like Compound's Governor, or Aragon DAO) that
// manages the "owner" role, allowing for decentralized control over sensitive functions.
// This contract serves as a functional demonstration of the core logic and concepts.

/**
 * @title ChronosForge Protocol
 * @dev A time-anchored and adaptive treasury/resource management system.
 *
 * This contract manages a treasury of ERC20 tokens, distributing them dynamically
 * based on a predefined "Epoch Map" that can be adjusted by a reputation-driven
 * "Epoch Weaver" council. It also features a "Temporal Forging" mechanism for
 * dynamic yield generation tied to epoch-based locking, and a general
 * adaptive parameter system for external influence.
 *
 * Outline:
 * I. Core Protocol State & Configuration
 * II. Treasury & Epoch Management
 * III. Epoch Weaver System (Decentralized Governance Council)
 * IV. Temporal Forging (Dynamic Staking/Locking)
 * V. Dynamic Oracle & Adaptive Strategy
 */
contract ChronosForge is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Variables ---

    // I. Core Protocol State & Configuration
    uint256 public currentEpoch;
    uint256 public epochDuration; // Duration of an epoch in seconds
    uint256 public lastEpochAdvanceTime;

    // Defines how the treasury's distributable funds are split for the current epoch.
    // e.g., [6000 (60% for forged rewards), 3000 (30% for bounties), 1000 (10% for dev fund)]
    // Values are in basis points (10000 = 100%)
    uint256[] public currentDistributionPlan;

    // Mapping for dynamic protocol parameters (e.g., "protocol_health_score", "market_volatility_index")
    // Allows external oracles/governance to update abstract values that can influence protocol behavior.
    mapping(bytes32 => uint256) public dynamicProtocolParameters;
    // Mapping for how much a specific dynamic parameter influences a distribution category (basis points)
    // E.g., dynamicInfluenceFactor[keccak256("protocol_health_score")][category_index]
    mapping(bytes32 => mapping(uint256 => uint256)) public dynamicInfluenceFactor;

    // II. Treasury & Epoch Management
    mapping(address => uint256) public treasuryBalances; // ERC20 token address => balance

    // III. Epoch Weaver System
    address public governanceToken; // Token used for Weaver staking
    uint256 public minWeaverStake;
    uint256 public maxActiveWeavers; // Maximum number of active Epoch Weavers

    // Epoch Weaver data
    struct Weaver {
        uint256 stakedAmount;
        uint256 lastStakeTime; // To prevent rapid stake/unstake abuse
        bool isActive;
    }
    mapping(address => Weaver) public weavers;
    address[] public activeWeaverAddresses; // List of current active weavers, capped by maxActiveWeavers

    // Proposal Management for Epoch Map Adjustments
    struct EpochMapProposal {
        uint256 proposalId;
        uint256 targetEpoch;
        uint256[] newDistributionPercentages; // Proposed new percentages
        mapping(address => bool) votes; // address => true for support, false for no vote
        uint256 supportVotes;
        uint256 requiredVotes; // Number of votes required for proposal to pass
        bool executed;
        uint256 creationEpoch; // The epoch in which the proposal was created
    }
    uint256 public nextProposalId;
    mapping(uint256 => EpochMapProposal) public epochMapProposals;

    // Weaver Dispute System
    struct WeaverDispute {
        address weaverAddress; // The weaver being disputed
        address reporter;
        string reasonHash; // Hash of off-chain evidence (e.g., IPFS link)
        bool resolved;
        bool guilty;
        uint256 slashAmount;
    }
    uint256 public nextDisputeId;
    mapping(uint256 => WeaverDispute) public weaverDisputes;
    mapping(address => uint256) public weaverDisputeCount; // How many times a weaver has been disputed

    // IV. Temporal Forging (Dynamic Staking/Locking)
    struct ForgedPosition {
        address token;
        uint256 amount;
        uint256 lockUntilEpoch;
        uint256 lastClaimedEpoch; // Last epoch for which rewards were claimed
    }
    mapping(address => ForgedPosition[]) public userForgedPositions;

    // Reward rates for forging: token address => lock duration (epochs) => reward multiplier (basis points)
    // e.g., forgingRewardRates[USDC][5 epochs lock] = 12000 (1.2x base rate)
    mapping(address => mapping(uint256 => uint256)) public forgingRewardRates;
    uint256 public baseForgingRewardPerEpoch; // Base reward rate (basis points per token per epoch)
    mapping(address => bool) public isForgeableToken; // Whitelist for tokens that can be forged

    // --- Events ---
    event Initialized(address indexed owner, uint256 initialEpochDuration, uint256 minWeaverStakeAmount, address governanceToken);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event EpochDurationSet(uint256 newDuration);
    event MinWeaverStakeSet(uint256 newMinStake);
    event MaxActiveWeaversSet(uint256 newLimit);
    event TreasuryFundsDeposited(address indexed token, uint256 amount, address indexed depositor);
    event TreasuryFundsWithdrawn(address indexed token, uint256 amount, address indexed recipient);
    event EpochRewardsDistributed(uint256 indexed epoch, address indexed token, uint256 amount);
    event WeaverStaked(address indexed weaver, uint256 amount);
    event WeaverUnstaked(address indexed weaver, uint256 amount);
    event WeaverActivated(address indexed weaver);
    event WeaverDeactivated(address indexed weaver);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 targetEpoch);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event DistributionPlanSet(uint256[] newPlan);
    event ForgedAssets(address indexed user, address indexed token, uint256 amount, uint256 lockUntilEpoch);
    event ClaimedForgedRewards(address indexed user, address indexed token, uint256 amount);
    event UnforgedAssets(address indexed user, address indexed token, uint256 amount);
    event ForgingRewardRatesSet(address indexed token, uint256[] epochMultipliers);
    event ForgeableTokenStatusChanged(address indexed token, bool isForgeable);
    event DynamicParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event DynamicInfluenceFactorSet(bytes32 indexed paramKey, uint256 categoryIndex, uint256 influencePercentage);
    event WeaverDisputeSubmitted(uint256 indexed disputeId, address indexed weaver, address indexed reporter, string reasonHash);
    event WeaverDisputeResolved(uint256 indexed disputeId, address indexed weaver, bool guilty, uint256 slashAmount);


    // --- Modifiers ---
    modifier onlyEpochWeaver() {
        require(weavers[msg.sender].isActive, "ChronosForge: Caller is not an active Epoch Weaver");
        _;
    }

    modifier onlyWhenEpochIsReadyToAdvance() {
        require(block.timestamp >= lastEpochAdvanceTime.add(epochDuration), "ChronosForge: Epoch duration not yet passed");
        _;
    }

    // --- Constructor / Initializer ---
    // In a proxy-based upgradeable contract, this would be an `initialize` function
    // and `Ownable` would be initialized separately. For this example, it's combined.
    constructor(address _owner, uint256 _initialEpochDuration, uint256 _minWeaverStakeAmount, address _governanceToken) Ownable(_owner) {
        require(_initialEpochDuration > 0, "ChronosForge: Epoch duration must be greater than 0");
        require(_minWeaverStakeAmount > 0, "ChronosForge: Min weaver stake must be greater than 0");
        require(_governanceToken != address(0), "ChronosForge: Governance token cannot be zero address");

        currentEpoch = 0; // Epoch 0 is initial setup
        epochDuration = _initialEpochDuration;
        lastEpochAdvanceTime = block.timestamp;
        minWeaverStake = _minWeaverStakeAmount;
        governanceToken = _governanceToken;
        maxActiveWeavers = 10; // Default max weavers
        nextProposalId = 1;
        nextDisputeId = 1;

        // Default distribution: 100% to forged rewards (example). Add more categories as needed.
        // Index 0: Forged Rewards
        // Index 1: Bounties
        // Index 2: Dev Fund
        currentDistributionPlan = new uint256[](1);
        currentDistributionPlan[0] = 10000; // Represents 100%

        baseForgingRewardPerEpoch = 100; // 1% per token per epoch (100 basis points)

        emit Initialized(_owner, _initialEpochDuration, _minWeaverStakeAmount, _governanceToken);
    }

    // --- I. Core Protocol State & Configuration ---

    /**
     * @dev Sets the duration of each epoch in seconds. Only callable by the owner/governance.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        require(_newDuration > 0, "ChronosForge: New epoch duration must be greater than 0");
        epochDuration = _newDuration;
        emit EpochDurationSet(_newDuration);
    }

    /**
     * @dev Sets the minimum required stake for an address to become an Epoch Weaver.
     * @param _newMinStake The new minimum stake amount in governance tokens.
     */
    function setMinWeaverStake(uint256 _newMinStake) external onlyOwner {
        require(_newMinStake > 0, "ChronosForge: New min weaver stake must be greater than 0");
        minWeaverStake = _newMinStake;
        emit MinWeaverStakeSet(_newMinStake);
    }

    /**
     * @dev Sets the maximum number of active Epoch Weavers.
     * @param _newLimit The new maximum number of active weavers.
     */
    function setMaxActiveWeavers(uint256 _newLimit) external onlyOwner {
        require(_newLimit > 0, "ChronosForge: Max weavers must be greater than 0");
        maxActiveWeavers = _newLimit;
        // Optionally, deactivate weavers if new limit is lower than current active count
        if (activeWeaverAddresses.length > _newLimit) {
            _deactivateExcessWeavers();
        }
        emit MaxActiveWeaversSet(_newLimit);
    }

    /**
     * @dev Sets the default treasury distribution plan for future epochs.
     *      _percentagesForCategories: Array of percentages (in basis points, sum must be 10000)
     *      Each index represents a distribution category (e.g., 0 for Forged Rewards, 1 for Bounties, etc.)
     * @param _percentagesForCategories The new distribution plan.
     */
    function setTreasuryDistributionPlan(uint256[] memory _percentagesForCategories) external onlyOwner {
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _percentagesForCategories.length; i++) {
            totalPercentage = totalPercentage.add(_percentagesForCategories[i]);
        }
        require(totalPercentage == 10000, "ChronosForge: Total percentages must sum to 10000 (100%)");
        currentDistributionPlan = _percentagesForCategories;
        emit DistributionPlanSet(_percentagesForCategories);
    }

    /**
     * @dev Allows a whitelisted oracle or owner to update an abstract protocol parameter.
     *      These parameters can influence dynamic behaviors within the contract.
     * @param _paramKey A unique key (e.g., keccak256("protocol_health_score")).
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramKey, uint256 _newValue) external onlyOwner { // In a real system, this could be `onlyOracle` or a more specific role
        dynamicProtocolParameters[_paramKey] = _newValue;
        emit DynamicParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @dev Sets how much a dynamic parameter influences a specific distribution category.
     *      This allows for adaptive strategy.
     * @param _paramKey The key of the dynamic parameter.
     * @param _categoryIndex The index of the distribution category it influences.
     * @param _influencePercentage The percentage (basis points) of influence.
     */
    function setDynamicInfluenceFactor(bytes32 _paramKey, uint256 _categoryIndex, uint256 _influencePercentage) external onlyOwner {
        require(_categoryIndex < currentDistributionPlan.length, "ChronosForge: Invalid category index");
        require(_influencePercentage <= 10000, "ChronosForge: Influence percentage cannot exceed 100%");
        dynamicInfluenceFactor[_paramKey][_categoryIndex] = _influencePercentage;
        emit DynamicInfluenceFactorSet(_paramKey, _categoryIndex, _influencePercentage);
    }

    // --- II. Treasury & Epoch Management ---

    /**
     * @dev Allows anyone to deposit ERC20 tokens into the ChronosForge treasury.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositTreasuryFunds(address _token, uint256 _amount) external nonReentrant {
        require(_amount > 0, "ChronosForge: Deposit amount must be greater than 0");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        treasuryBalances[_token] = treasuryBalances[_token].add(_amount);
        emit TreasuryFundsDeposited(_token, _amount, msg.sender);
    }

    /**
     * @dev Allows the owner/governance to withdraw specific tokens from the treasury.
     *      Intended for approved bounties, emergency, or protocol upgrades.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     * @param _recipient The recipient address for the withdrawn tokens.
     */
    function withdrawTreasuryFunds(address _token, uint256 _amount, address _recipient) external onlyOwner nonReentrant {
        require(_amount > 0, "ChronosForge: Withdraw amount must be greater than 0");
        require(treasuryBalances[_token] >= _amount, "ChronosForge: Insufficient treasury balance");
        IERC20(_token).transfer(_recipient, _amount);
        treasuryBalances[_token] = treasuryBalances[_token].sub(_amount);
        emit TreasuryFundsWithdrawn(_token, _amount, _recipient);
    }

    /**
     * @dev Advances the current epoch. Can only be called once the current epoch duration has passed.
     *      This function also triggers the distribution of epoch rewards.
     */
    function passEpoch() external nonReentrant onlyWhenEpochIsReadyToAdvance {
        currentEpoch = currentEpoch.add(1);
        lastEpochAdvanceTime = block.timestamp;
        _distributeEpochRewards(); // Internal call to distribute
        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /**
     * @dev Internal function to distribute funds based on the current distribution plan.
     *      Called automatically when `passEpoch()` is invoked.
     *      This would ideally handle multiple tokens and categories. For simplicity,
     *      it assumes rewards are distributed in the governance token for 'forged rewards' category.
     */
    function _distributeEpochRewards() internal {
        // Example: Distribute a portion of governanceToken from treasury to forging rewards pool.
        // In a real system, this would be more sophisticated, potentially managing
        // separate pools for different tokens and categories.

        if (currentDistributionPlan.length == 0 || treasuryBalances[governanceToken] == 0) {
            return;
        }

        // Example: Only distribute based on the first category (e.g., Forged Rewards)
        // This is a simplified internal distribution. In a real system, funds would be moved to
        // designated reward pools or other sub-contracts for each category.
        uint256 forgedRewardsPercentage = currentDistributionPlan[0]; // Assuming index 0 is for forged rewards
        uint256 distributableAmount = treasuryBalances[governanceToken].mul(forgedRewardsPercentage).div(10000);

        // Apply dynamic influence if applicable (e.g., protocol health score influences forging rewards)
        // This makes the distribution truly adaptive.
        bytes32 healthScoreKey = keccak256(abi.encodePacked("protocol_health_score"));
        uint256 healthScore = dynamicProtocolParameters[healthScoreKey];
        uint256 influenceFactor = dynamicInfluenceFactor[healthScoreKey][0]; // Forged rewards category index 0

        if (healthScore > 0 && influenceFactor > 0) {
            // Example influence: Higher health score means more rewards.
            // This is a simple linear scale; real systems might use sigmoid or more complex curves.
            // For example, if healthScore is 1000 (meaning 10%) and influence is 1000 (10% of that),
            // it adds 1% (1000/10000 * 1000/10000) of the distributable amount.
            uint256 influenceAmount = distributableAmount.mul(healthScore).div(10000).mul(influenceFactor).div(10000);
            distributableAmount = distributableAmount.add(influenceAmount);
        }

        // Ensure we don't try to distribute more than available in the treasury for this token
        if (distributableAmount > treasuryBalances[governanceToken]) {
            distributableAmount = treasuryBalances[governanceToken];
        }

        // At this point, `distributableAmount` is the calculated portion for 'Forged Rewards'.
        // In a production setup, this would be transferred to a dedicated reward pool contract,
        // or a virtual balance updated for the forging mechanism to draw from.
        // For simplicity, `claimForgedRewards` directly accesses the treasury based on accrued rewards.
        emit EpochRewardsDistributed(currentEpoch, governanceToken, distributableAmount);
    }


    // --- III. Epoch Weaver System (Decentralized Governance Council) ---

    /**
     * @dev Allows a user to stake governance tokens to become an Epoch Weaver.
     *      If successful, they become an active weaver if slots are available.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeAsWeaver(uint256 _amount) external nonReentrant {
        require(_amount >= minWeaverStake, "ChronosForge: Stake amount less than minimum required");
        require(weavers[msg.sender].stakedAmount == 0, "ChronosForge: Already staked as a weaver");

        IERC20(governanceToken).transferFrom(msg.sender, address(this), _amount);
        weavers[msg.sender] = Weaver({
            stakedAmount: _amount,
            lastStakeTime: block.timestamp,
            isActive: false // Will activate if slot available
        });

        _tryActivateWeaver(msg.sender); // Attempt to activate
        emit WeaverStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows an active or inactive weaver to unstake their governance tokens.
     *      Requires a cooldown period or specific conditions based on their activity.
     *      For simplicity, this version allows immediate unstaking if not active.
     * @param _amount The amount to unstake.
     */
    function unstakeAsWeaver(uint256 _amount) external nonReentrant {
        Weaver storage weaver = weavers[msg.sender];
        require(weaver.stakedAmount >= _amount, "ChronosForge: Insufficient staked amount");
        require(!weaver.isActive, "ChronosForge: Cannot unstake while active. Must deactivate first.");

        weaver.stakedAmount = weaver.stakedAmount.sub(_amount);
        IERC20(governanceToken).transfer(msg.sender, _amount);

        if (weaver.stakedAmount == 0) {
            delete weavers[msg.sender]; // Remove from mapping if fully unstaked
        }
        emit WeaverUnstaked(msg.sender, _amount);
    }

    /**
     * @dev Internal function to try activating a weaver if there's an available slot and they meet criteria.
     *      Called after staking or when a slot opens up.
     */
    function _tryActivateWeaver(address _weaverAddress) internal {
        Weaver storage weaver = weavers[_weaverAddress];
        if (weaver.stakedAmount >= minWeaverStake && activeWeaverAddresses.length < maxActiveWeavers && !weaver.isActive) {
            weaver.isActive = true;
            activeWeaverAddresses.push(_weaverAddress);
            emit WeaverActivated(_weaverAddress);
        }
    }

    /**
     * @dev Internal function to deactivate excess weavers if `maxActiveWeavers` is reduced.
     *      Deactivates the last added weavers in `activeWeaverAddresses` array.
     */
    function _deactivateExcessWeavers() internal {
        while (activeWeaverAddresses.length > maxActiveWeavers) {
            address weaverToRemove = activeWeaverAddresses[activeWeaverAddresses.length - 1];
            weavers[weaverToRemove].isActive = false;
            activeWeaverAddresses.pop();
            emit WeaverDeactivated(weaverToRemove);
        }
    }

    /**
     * @dev Proposes an override for the default treasury distribution plan for a future epoch.
     *      Only active Epoch Weavers can propose.
     * @param _targetEpoch The epoch for which this override should apply. Must be in the future.
     * @param _newPercentages The proposed new distribution percentages (sum to 10000).
     */
    function proposeDistributionOverride(uint256 _targetEpoch, uint256[] memory _newPercentages) external onlyEpochWeaver {
        require(_targetEpoch > currentEpoch, "ChronosForge: Target epoch must be in the future");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _newPercentages.length; i++) {
            totalPercentage = totalPercentage.add(_newPercentages[i]);
        }
        require(totalPercentage == 10000, "ChronosForge: Proposed percentages must sum to 10000 (100%)");

        uint256 proposalId = nextProposalId++;
        epochMapProposals[proposalId] = EpochMapProposal({
            proposalId: proposalId,
            targetEpoch: _targetEpoch,
            newDistributionPercentages: _newPercentages,
            supportVotes: 0,
            requiredVotes: (activeWeaverAddresses.length.mul(5000)).div(10000).add(1), // 50% + 1 vote of active weavers
            executed: false,
            creationEpoch: currentEpoch
        });

        emit ProposalCreated(proposalId, msg.sender, _targetEpoch);
    }

    /**
     * @dev Allows an active Epoch Weaver to vote on an existing proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyEpochWeaver {
        EpochMapProposal storage proposal = epochMapProposals[_proposalId];
        require(proposal.proposalId != 0, "ChronosForge: Proposal does not exist");
        require(!proposal.executed, "ChronosForge: Proposal already executed");
        require(proposal.targetEpoch > currentEpoch, "ChronosForge: Cannot vote on past or current epoch proposals");
        require(!proposal.votes[msg.sender], "ChronosForge: Already voted on this proposal");

        proposal.votes[msg.sender] = true;
        if (_support) {
            proposal.supportVotes = proposal.supportVotes.add(1);
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal. Anyone can call this once the required votes are met.
     *      The proposal's new distribution percentages become the `currentDistributionPlan`
     *      when the `targetEpoch` is reached (or immediately if `currentEpoch` is past `creationEpoch`
     *      and before `targetEpoch`). This implementation simplifies by applying immediately.
     *      In a more complex system, pending overrides would be stored per epoch.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        EpochMapProposal storage proposal = epochMapProposals[_proposalId];
        require(proposal.proposalId != 0, "ChronosForge: Proposal does not exist");
        require(!proposal.executed, "ChronosForge: Proposal already executed");
        require(proposal.supportVotes >= proposal.requiredVotes, "ChronosForge: Proposal has not met required votes");
        require(currentEpoch < proposal.targetEpoch, "ChronosForge: Cannot execute proposal for past or current epoch");

        currentDistributionPlan = proposal.newDistributionPercentages; // Applies the plan for future epochs
        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows any user to submit a dispute against an Epoch Weaver for alleged malicious behavior.
     *      Requires off-chain evidence referenced by a hash.
     * @param _weaverAddress The address of the Weaver being disputed.
     * @param _reasonHash A hash referencing off-chain evidence (e.g., IPFS hash of a report).
     */
    function submitWeaverDispute(address _weaverAddress, string memory _reasonHash) external {
        require(weavers[_weaverAddress].stakedAmount > 0, "ChronosForge: Target is not a staked weaver");
        require(weavers[_weaverAddress].isActive, "ChronosForge: Target weaver is not active");
        require(bytes(_reasonHash).length > 0, "ChronosForge: Reason hash cannot be empty");

        uint256 disputeId = nextDisputeId++;
        weaverDisputes[disputeId] = WeaverDispute({
            weaverAddress: _weaverAddress,
            reporter: msg.sender,
            reasonHash: _reasonHash,
            resolved: false,
            guilty: false,
            slashAmount: 0
        });
        weaverDisputeCount[_weaverAddress] = weaverDisputeCount[_weaverAddress].add(1);
        emit WeaverDisputeSubmitted(disputeId, _weaverAddress, msg.sender, _reasonHash);
    }

    /**
     * @dev Allows the owner/governance to resolve a weaver dispute, potentially slashing their stake.
     *      This implies an off-chain dispute resolution process has occurred.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _guilty True if the weaver is found guilty, false otherwise.
     * @param _slashAmount The amount of tokens to slash from the weaver's stake if guilty.
     */
    function resolveWeaverDispute(uint256 _disputeId, bool _guilty, uint256 _slashAmount) external onlyOwner nonReentrant {
        WeaverDispute storage dispute = weaverDisputes[_disputeId];
        require(dispute.disputeId != 0, "ChronosForge: Dispute does not exist");
        require(!dispute.resolved, "ChronosForge: Dispute already resolved");
        address weaverAddress = dispute.weaverAddress; // The weaver being disputed

        require(weavers[weaverAddress].stakedAmount > 0, "ChronosForge: Weaver not found or not staked");

        dispute.resolved = true;
        dispute.guilty = _guilty;
        dispute.slashAmount = _slashAmount;

        if (_guilty && _slashAmount > 0) {
            Weaver storage weaver = weavers[weaverAddress];
            uint256 actualSlash = _slashAmount;
            if (weaver.stakedAmount < _slashAmount) {
                actualSlash = weaver.stakedAmount; // Slash only what's available
            }
            weaver.stakedAmount = weaver.stakedAmount.sub(actualSlash);
            // Transfer slashed tokens to treasury (or burn them)
            IERC20(governanceToken).transfer(address(this), actualSlash); 
            treasuryBalances[governanceToken] = treasuryBalances[governanceToken].add(actualSlash);

            // If Weaver's stake falls below minWeaverStake, they are deactivated
            if (weaver.stakedAmount < minWeaverStake && weaver.isActive) {
                weaver.isActive = false;
                // Remove from activeWeaverAddresses array
                for (uint256 i = 0; i < activeWeaverAddresses.length; i++) {
                    if (activeWeaverAddresses[i] == weaverAddress) {
                        activeWeaverAddresses[i] = activeWeaverAddresses[activeWeaverAddresses.length - 1];
                        activeWeaverAddresses.pop();
                        break;
                    }
                }
                emit WeaverDeactivated(weaverAddress);
            }
        }
        emit WeaverDisputeResolved(_disputeId, weaverAddress, _guilty, _slashAmount);
    }

    // --- IV. Temporal Forging (Dynamic Staking/Locking) ---

    /**
     * @dev Allows users to lock assets for a specified number of future epochs to earn rewards.
     * @param _token The address of the ERC20 token to forge.
     * @param _amount The amount of tokens to lock.
     * @param _lockUntilEpoch The epoch number until which the assets will be locked. Must be > currentEpoch.
     */
    function forgeAssets(address _token, uint256 _amount, uint256 _lockUntilEpoch) external nonReentrant {
        require(isForgeableToken[_token], "ChronosForge: Token is not forgeable");
        require(_amount > 0, "ChronosForge: Amount must be greater than 0");
        require(_lockUntilEpoch > currentEpoch, "ChronosForge: Lock epoch must be in the future");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Store the forged position
        userForgedPositions[msg.sender].push(ForgedPosition({
            token: _token,
            amount: _amount,
            lockUntilEpoch: _lockUntilEpoch,
            lastClaimedEpoch: currentEpoch // Claim up to currentEpoch immediately
        }));

        emit ForgedAssets(msg.sender, _token, _amount, _lockUntilEpoch);
    }

    /**
     * @dev Allows users to claim accumulated rewards from their forged assets.
     *      Rewards are based on the base rate and epoch multipliers.
     * @param _token The specific token to claim rewards for.
     */
    function claimForgedRewards(address _token) external nonReentrant {
        uint256 totalRewards = 0;
        ForgedPosition[] storage positions = userForgedPositions[msg.sender];

        for (uint256 i = 0; i < positions.length; i++) {
            ForgedPosition storage pos = positions[i];
            if (pos.token == _token && pos.amount > 0) {
                uint256 epochsPassedSinceLastClaim = currentEpoch.sub(pos.lastClaimedEpoch);
                if (epochsPassedSinceLastClaim > 0) {
                    uint256 effectiveLockDuration = pos.lockUntilEpoch.sub(currentEpoch); 
                    if (effectiveLockDuration == 0) effectiveLockDuration = 1; // For position that just expired

                    uint256 rewardMultiplier = forgingRewardRates[_token][effectiveLockDuration];
                    if (rewardMultiplier == 0) {
                        rewardMultiplier = baseForgingRewardPerEpoch; // Default to base if no specific multiplier set
                    }

                    uint256 rewardsForPosition = pos.amount
                        .mul(epochsPassedSinceLastClaim)
                        .mul(rewardMultiplier)
                        .div(10000); // Divide by 10000 for basis points

                    totalRewards = totalRewards.add(rewardsForPosition);
                    pos.lastClaimedEpoch = currentEpoch; // Update last claimed epoch
                }
            }
        }

        require(totalRewards > 0, "ChronosForge: No rewards to claim for this token");
        // Distribute rewards from the treasury (assuming treasury holds these tokens)
        require(treasuryBalances[_token] >= totalRewards, "ChronosForge: Insufficient treasury balance for rewards");
        IERC20(_token).transfer(msg.sender, totalRewards);
        treasuryBalances[_token] = treasuryBalances[_token].sub(totalRewards);
        emit ClaimedForgedRewards(msg.sender, _token, totalRewards);
    }

    /**
     * @dev Allows users to unlock their forged assets after their lock-up period has ended.
     * @param _token The specific token to unforge.
     */
    function unforgeAssets(address _token) external nonReentrant {
        ForgedPosition[] storage positions = userForgedPositions[msg.sender];
        uint256 totalUnforgedAmount = 0;
        uint256 originalLength = positions.length;

        for (uint256 i = 0; i < positions.length; ) {
            ForgedPosition storage pos = positions[i];
            if (pos.token == _token && currentEpoch >= pos.lockUntilEpoch && pos.amount > 0) {
                totalUnforgedAmount = totalUnforgedAmount.add(pos.amount);
                // Remove the position by swapping with the last element and popping
                positions[i] = positions[positions.length - 1];
                positions.pop();
            } else {
                i++;
            }
        }

        require(totalUnforgedAmount > 0, "ChronosForge: No assets to unforge for this token or lock period not ended");
        require(treasuryBalances[_token] >= totalUnforgedAmount, "ChronosForge: Insufficient treasury balance for unforge");
        IERC20(_token).transfer(msg.sender, totalUnforgedAmount);
        treasuryBalances[_token] = treasuryBalances[_token].sub(totalUnforgedAmount);
        emit UnforgedAssets(msg.sender, _token, totalUnforgedAmount);
    }

    /**
     * @dev Sets the reward multipliers for different lock durations for a specific forgeable token.
     * @param _token The address of the forgeable token.
     * @param _epochMultipliers An array where index i corresponds to (i+1) epochs locked duration multiplier.
     *                          e.g., _epochMultipliers[0] is for 1 epoch lock, _epochMultipliers[4] for 5 epochs lock.
     *                          Values are in basis points (10000 = 100% or 1x base rate).
     */
    function setForgingRewardRates(address _token, uint256[] memory _epochMultipliers) external onlyOwner {
        require(isForgeableToken[_token], "ChronosForge: Token is not registered as forgeable");
        for (uint256 i = 0; i < _epochMultipliers.length; i++) {
            forgingRewardRates[_token][i.add(1)] = _epochMultipliers[i];
        }
        emit ForgingRewardRatesSet(_token, _epochMultipliers);
    }

    /**
     * @dev Registers or unregisters a token as forgeable. Only owner/governance.
     * @param _tokenAddress The address of the token.
     * @param _isForgeable True to register, false to unregister.
     */
    function registerForgeableToken(address _tokenAddress, bool _isForgeable) external onlyOwner {
        isForgeableToken[_tokenAddress] = _isForgeable;
        emit ForgeableTokenStatusChanged(_tokenAddress, _isForgeable);
    }

    // --- V. Utility & View Functions ---

    /**
     * @dev Returns the total amount of a specific token locked by a user.
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The total locked amount.
     */
    function getLockedAssets(address _user, address _token) public view returns (uint256) {
        uint256 totalLocked = 0;
        ForgedPosition[] memory positions = userForgedPositions[_user]; // Use memory for view function
        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].token == _token) {
                totalLocked = totalLocked.add(positions[i].amount);
            }
        }
        return totalLocked;
    }

    /**
     * @dev Returns the estimated pending yield for a user for a specific token.
     *      This is an estimate and actual claim might differ based on current epoch and treasury.
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The estimated pending yield.
     */
    function getPendingForgedYield(address _user, address _token) public view returns (uint256) {
        uint256 estimatedRewards = 0;
        ForgedPosition[] memory positions = userForgedPositions[_user]; // Use memory for view function

        for (uint256 i = 0; i < positions.length; i++) {
            ForgedPosition memory pos = positions[i];
            if (pos.token == _token && pos.amount > 0) {
                uint256 epochsAccrued = currentEpoch.sub(pos.lastClaimedEpoch);
                if (epochsAccrued > 0) {
                    uint256 effectiveLockDuration = pos.lockUntilEpoch.sub(currentEpoch);
                    if (effectiveLockDuration == 0) effectiveLockDuration = 1;

                    uint256 rewardMultiplier = forgingRewardRates[_token][effectiveLockDuration];
                    if (rewardMultiplier == 0) {
                        rewardMultiplier = baseForgingRewardPerEpoch;
                    }

                    estimatedRewards = estimatedRewards.add(
                        pos.amount.mul(epochsAccrued).mul(rewardMultiplier).div(10000)
                    );
                }
            }
        }
        return estimatedRewards;
    }

    /**
     * @dev Returns the current status of an Epoch Weaver.
     * @param _weaverAddress The address of the weaver.
     * @return stakedAmount The amount staked.
     * @return isActive Whether the weaver is currently active.
     */
    function getWeaverStatus(address _weaverAddress) public view returns (uint256 stakedAmount, bool isActive) {
        Weaver storage weaver = weavers[_weaverAddress];
        return (weaver.stakedAmount, weaver.isActive);
    }

    /**
     * @dev Returns details of a specific epoch map proposal.
     * @param _proposalId The ID of the proposal.
     * @return targetEpoch The epoch this proposal targets.
     * @return newPercentages The proposed distribution percentages.
     * @return supportVotes The number of 'yes' votes.
     * @return requiredVotes The number of votes required for passage.
     * @return executed Whether the proposal has been executed.
     */
    function getEpochMapProposal(uint256 _proposalId)
        public view
        returns (
            uint256 targetEpoch,
            uint256[] memory newPercentages,
            uint256 supportVotes,
            uint256 requiredVotes,
            bool executed
        )
    {
        EpochMapProposal storage proposal = epochMapProposals[_proposalId];
        return (
            proposal.targetEpoch,
            proposal.newDistributionPercentages,
            proposal.supportVotes,
            proposal.requiredVotes,
            proposal.executed
        );
    }
}
```