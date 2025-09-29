This smart contract, **ChameleonProtocol**, is designed as an advanced, adaptive DeFi platform. It introduces several innovative and trendy concepts:

1.  **Dynamic Yield Staking:** Users stake tokens and earn rewards, but the Annual Percentage Yield (APY) is not fixed. It dynamically adjusts based on the user's on-chain reputation, the protocol's overall "health factor," and specific "Skill NFTs" they hold.
2.  **Reputation System:** Users accumulate reputation points through staking, holding valuable Skill NFTs, and potentially other contributions. Reputation is not static; it gradually decays over time if a user is inactive, encouraging continuous engagement. Higher reputation tiers unlock better yield multipliers.
3.  **Soul-Bound Skill NFTs:** These are non-transferable (soul-bound) NFTs that act as on-chain credentials or badges, representing verified achievements, roles, or skills within the protocol (e.g., "Data Verifier," "Community Moderator"). Holding specific Skill NFTs can significantly boost a user's reputation and yield rate.
4.  **Adaptive Protocol Parameters:** Key protocol parameters, such as the overall "protocol health factor" (which influences the base yield) and reputation decay rates, can be adjusted. This adaptability allows the protocol to respond to market conditions or internal states.
5.  **Autonomous Agent Integration:** The protocol includes a module to whitelist and grant specific permissions to external autonomous agents (e.g., AI-driven strategies, algorithmic rebalancers, or specialized oracle bots). These agents can execute predefined, permissioned actions to manage and optimize protocol parameters.

The design aims to create a more engaging, meritocratic, and resilient DeFi ecosystem where participation and earned reputation directly impact rewards and privileges.

---

## ChameleonProtocol Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For potentially string keys in attributes


/*
 * @title ChameleonProtocol
 * @dev An advanced, adaptive DeFi protocol featuring dynamic yield, a reputation system,
 *      soul-bound "Skill NFTs", and an integrated autonomous agent module.
 *      The protocol's parameters (e.g., yield rates, reputation decay) are adaptive
 *      and can be influenced by governance or whitelisted algorithmic agents.
 *
 * Outline and Function Summary:
 *
 * I. Core Staking & Rewards (6 functions)
 *    - stake(uint256 amount): Allows users to stake their tokens into the protocol.
 *    - unstake(uint256 amount): Allows users to withdraw their staked tokens.
 *    - claimRewards(): Allows users to claim their accumulated dynamic rewards.
 *    - getPendingRewards(address user): Public view function to check pending rewards for a user.
 *    - _updateUserReward(address user): Internal helper to update a user's reward state and global reward accrual.
 *    - getCurrentYieldRate(address user): Public view function to calculate the current personalized annual percentage yield (APY) for a user, considering reputation, skill NFTs, and protocol health.
 *
 * II. Reputation Management (5 functions)
 *    - getReputation(address user): Public view function to get a user's current reputation score, reflecting potential decay.
 *    - addReputation(address user, uint256 points): Governor-only function to manually add reputation points to a user for contributions.
 *    - _applyReputationDecay(address user): Internal helper to apply time-based reputation decay and persist the updated score.
 *    - getReputationDecayRate(): Public view function to get the current daily reputation decay rate.
 *    - setReputationDecayRate(uint256 newRate): Governor-only function to set the daily reputation decay rate.
 *
 * III. Skill NFT Management (6 functions)
 *    - mintSkillNFT(address recipient, uint256 skillId, string memory uri): Governor-only function to issue a soul-bound (non-transferable) Skill NFT.
 *    - burnSkillNFT(address owner, uint256 tokenId): Governor-only function to burn a specific Skill NFT, e.g., if a skill is revoked.
 *    - getSkillNFTMetadataURI(uint256 tokenId): Public view function to get the metadata URI of a specific Skill NFT.
 *    - getSkillsOf(address user): Public view function to retrieve all Skill NFT token IDs held by a user.
 *    - setSkillNFTAttribute(uint256 skillId, string memory key, uint256 value): Governor-only function to define numerical attributes for a skill type (e.g., "reputationBoostFactor").
 *    - getSkillNFTAttribute(uint256 skillId, string memory key): Public view function to get a specific numerical attribute for a skill type.
 *
 * IV. Protocol Parameter Control (6 functions)
 *    - setProtocolHealthFactor(uint256 newFactor): Governor-only or Whitelisted Agent function to update the protocol's health factor, impacting base yield.
 *    - getProtocolHealthFactor(): Public view function to get the current protocol health factor.
 *    - setYieldMultiplier(uint256 reputationTier, uint256 multiplier): Governor-only function to set a yield multiplier for a specific reputation tier.
 *    - getYieldMultiplier(uint256 reputationTier): Public view function to get the yield multiplier for a given reputation tier.
 *    - withdrawTreasuryFunds(address recipient, uint256 amount): Governor-only function to withdraw funds from the protocol's treasury for operations or liquidity.
 *    - depositTreasuryFunds(uint256 amount): Public function allowing anyone to deposit tokens into the protocol's treasury.
 *
 * V. Autonomous Agent Module (4 functions)
 *    - whitelistAgent(address agentAddress, uint256 permissionBitmap): Governor-only function to whitelist an agent with specific execution permissions.
 *    - revokeAgent(address agentAddress): Governor-only function to remove an agent's whitelist status and permissions.
 *    - getAgentPermissions(address agentAddress): Public view function to get the permission bitmap of a whitelisted agent.
 *    - executeAgentAction(uint256 actionId, bytes calldata data): Whitelisted Agent function to perform pre-approved actions based on their granted permissions.
 *
 * Total Functions: 27
 */
contract ChameleonProtocol is AccessControl {
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE"); // For whitelisted autonomous agents

    // --- Configuration ---
    IERC20 public immutable stakingToken;
    uint256 public constant SECONDS_IN_YEAR = 31536000; // 365 * 24 * 60 * 60
    uint256 public constant SCALE_FACTOR = 1e18; // For internal calculations requiring high precision

    // --- Staking State ---
    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastRewardUpdateTime; // Last time user's rewards were updated/claimed
    mapping(address => uint256) public rewardPerTokenPaid; // Global rewardPerTokenStored value at user's last update
    uint256 public totalStaked;
    uint256 public rewardPerTokenStored; // Cumulative global reward per unit of staked token, scaled by SCALE_FACTOR
    // lastRewardUpdateTime[address(0)] tracks the last time rewardPerTokenStored was updated globally.
    // This allows for continuous global reward accrual.

    // --- Reward Configuration ---
    uint256 public protocolHealthFactor = 1000; // Scaled by 1000, e.g., 1000 = 1.0, 1500 = 1.5
    mapping(uint256 => uint256) public yieldMultipliers; // reputationTier => multiplier (scaled by 1000, e.g., 1500 = 1.5x)
    uint256 public baseYieldRate = 500; // Base APY percentage scaled by 10000 (e.g., 500 = 5.00% APY)

    // --- Reputation System State ---
    mapping(address => uint256) public reputationScores;
    mapping(address => uint256) public lastReputationUpdate; // Timestamp of last reputation update/decay
    uint256 public reputationDecayRatePerDay = 10; // Reputation points decayed per day (e.g., 10 points per day)

    // --- Skill NFTs (Soul-bound ERC-721-like) State ---
    uint256 private _nextTokenId; // Counter for unique NFT IDs
    mapping(uint256 => address) public skillTokenIdToOwner; // NFT ID to owner (null if burned)
    mapping(address => uint256[]) public ownerToSkillTokenIds; // For easier lookup of user's NFTs
    mapping(uint256 => string) public skillTokenIdToUri; // NFT ID to metadata URI
    mapping(uint256 => mapping(string => uint256)) public skillTypeAttributes; // skillId (type) => key => numerical value

    // --- Autonomous Agent Module State ---
    mapping(address => uint256) public whitelistedAgents; // agentAddress => permissionBitmap
    uint256 public constant AGENT_PERM_SET_HEALTH_FACTOR = 1 << 0; // Example permission: can call setProtocolHealthFactor
    // Additional permission bits can be defined here for other agent actions.

    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationAdded(address indexed user, uint256 points);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);
    event SkillNFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 indexed skillId, string uri);
    event SkillNFTBurned(address indexed owner, uint256 indexed tokenId);
    event ProtocolHealthFactorUpdated(uint256 oldFactor, uint256 newFactor);
    event YieldMultiplierUpdated(uint256 indexed reputationTier, uint256 oldMultiplier, uint256 newMultiplier);
    event AgentWhitelisted(address indexed agent, uint256 permissions);
    event AgentRevoked(address indexed agent);
    event AgentActionExecuted(address indexed agent, uint256 actionId, bytes data);

    constructor(address _stakingTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // The deployer is the default admin
        _grantRole(GOVERNOR_ROLE, msg.sender); // The deployer is initially the governor
        stakingToken = IERC20(_stakingTokenAddress);

        // Set default yield multiplier for tier 0 (base tier)
        yieldMultipliers[0] = 1000; // 1.0x multiplier by default
        lastRewardUpdateTime[address(0)] = block.timestamp; // Initialize global reward update time
    }

    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Chameleon: Must have GOVERNOR_ROLE");
        _;
    }

    modifier onlyWhitelistedAgentOrGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()) || hasRole(AGENT_ROLE, _msgSender()), "Chameleon: Caller not Governor or Whitelisted Agent");
        _;
    }

    // --- I. Core Staking & Rewards ---

    /**
     * @dev Allows users to stake their tokens into the protocol.
     * @param amount The amount of tokens to stake.
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Chameleon: Cannot stake 0");
        _updateUserReward(_msgSender()); // Update user's rewards before changing state
        _applyReputationDecay(_msgSender()); // Apply reputation decay
        
        // Transfer tokens from user to contract
        stakingToken.transferFrom(_msgSender(), address(this), amount);
        
        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].add(amount);
        totalStaked = totalStaked.add(amount);

        // Example: Add some base reputation for staking
        reputationScores[_msgSender()] = reputationScores[_msgSender()].add(1);
        lastReputationUpdate[_msgSender()] = block.timestamp;

        emit Staked(_msgSender(), amount);
    }

    /**
     * @dev Allows users to withdraw their staked tokens.
     * @param amount The amount of tokens to unstake.
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "Chameleon: Cannot unstake 0");
        require(stakedBalances[_msgSender()] >= amount, "Chameleon: Insufficient staked balance");

        _updateUserReward(_msgSender()); // Update user's rewards before changing state
        _applyReputationDecay(_msgSender()); // Apply reputation decay

        stakedBalances[_msgSender()] = stakedBalances[_msgSender()].sub(amount);
        totalStaked = totalStaked.sub(amount);
        stakingToken.transfer(_msgSender(), amount);

        emit Unstaked(_msgSender(), amount);
    }

    /**
     * @dev Allows users to claim their accumulated dynamic rewards.
     */
    function claimRewards() external {
        _updateUserReward(_msgSender()); // Ensure rewards are up-to-date
        _applyReputationDecay(_msgSender()); // Apply reputation decay

        uint256 rewards = getPendingRewards(_msgSender());
        require(rewards > 0, "Chameleon: No rewards to claim");

        // Transfer rewards (assuming stakingToken is also the reward token for simplicity)
        stakingToken.transfer(_msgSender(), rewards);
        rewardPerTokenPaid[_msgSender()] = rewardPerTokenStored; // Mark rewards as paid

        emit RewardsClaimed(_msgSender(), rewards);
    }

    /**
     * @dev Public view function to check pending rewards for a user.
     * @param user The address of the user.
     * @return The amount of pending rewards.
     */
    function getPendingRewards(address user) public view returns (uint256) {
        if (stakedBalances[user] == 0) return 0;
        
        // Calculate the current global reward per token (up to this moment)
        uint256 currentGlobalRewardPerToken = rewardPerTokenStored;
        if (totalStaked > 0 && block.timestamp > lastRewardUpdateTime[address(0)]) {
            uint256 timeElapsed = block.timestamp.sub(lastRewardUpdateTime[address(0)]);
            uint256 effectiveYield = baseYieldRate.mul(protocolHealthFactor).div(1000); // baseYield * healthFactor (e.g., 500 * 1000 / 1000 = 500)
            // rewardsAccruedGlobally is value per totalStaked
            uint256 rewardsAccruedGlobally = totalStaked.mul(effectiveYield).mul(timeElapsed).div(SECONDS_IN_YEAR).div(10000); // 10000 for baseYieldRate scaling (e.g., 500 -> 0.05)
            
            if (rewardsAccruedGlobally > 0) {
                 currentGlobalRewardPerToken = currentGlobalRewardPerToken.add(rewardsAccruedGlobally.mul(SCALE_FACTOR).div(totalStaked));
            }
        }
        
        // Calculate user's pending rewards
        return (stakedBalances[user].mul(currentGlobalRewardPerToken.sub(rewardPerTokenPaid[user]))).div(SCALE_FACTOR);
    }

    /**
     * @dev Internal helper to update a user's reward state. This should be called before any
     *      state-changing interaction (stake, unstake, claimRewards, reputation changes)
     *      and also updates the global `rewardPerTokenStored` based on protocol health and time.
     * @param user The address of the user.
     */
    function _updateUserReward(address user) internal {
        uint256 currentTimestamp = block.timestamp;

        // Calculate global reward accretion (if any rewards can be generated)
        if (totalStaked > 0 && currentTimestamp > lastRewardUpdateTime[address(0)]) {
            uint256 timeElapsed = currentTimestamp.sub(lastRewardUpdateTime[address(0)]);
            uint256 effectiveYield = baseYieldRate.mul(protocolHealthFactor).div(1000); // baseYield * healthFactor (e.g., 500 * 1000 / 1000 = 500)
            uint256 rewardsAccruedGlobally = totalStaked.mul(effectiveYield).mul(timeElapsed).div(SECONDS_IN_YEAR).div(10000); // 10000 for baseYieldRate scaling
            
            if (rewardsAccruedGlobally > 0) {
                rewardPerTokenStored = rewardPerTokenStored.add(rewardsAccruedGlobally.mul(SCALE_FACTOR).div(totalStaked));
            }
        }
        lastRewardUpdateTime[address(0)] = currentTimestamp; // Update global last update time

        // Now, update the user's specific reward state
        // This marks the point up to which the user has "received" their share of global rewards.
        rewardPerTokenPaid[user] = rewardPerTokenStored;
        lastRewardUpdateTime[user] = currentTimestamp;
    }


    /**
     * @dev Public view function to calculate the current personalized annual percentage yield (APY) for a user.
     *      Takes into account reputation, skill NFTs, and protocol health.
     * @param user The address of the user.
     * @return The current APY for the user, scaled by 10000 (e.g., 500 = 5.00%).
     */
    function getCurrentYieldRate(address user) public view returns (uint256) {
        uint256 currentReputation = getReputation(user); // Get reputation with potential decay applied
        uint256 tier = currentReputation.div(100); // Simple tiering: 0-99 = tier 0, 100-199 = tier 1, etc.

        uint256 effectiveMultiplier = yieldMultipliers[tier];
        if (effectiveMultiplier == 0) { // If no specific multiplier for this tier, use base (tier 0)
            effectiveMultiplier = yieldMultipliers[0]; 
        }

        // Incorporate Skill NFT boosts
        uint256[] memory userSkills = ownerToSkillTokenIds[user];
        uint256 skillBoostFactor = 0; // Cumulative boost from all held skill NFTs
        for (uint256 i = 0; i < userSkills.length; i++) {
            uint256 skillId = userSkills[i];
            skillBoostFactor = skillBoostFactor.add(skillTypeAttributes[skillId]["reputationBoostFactor"]); // Example attribute
        }

        // Calculate total effective yield
        uint256 totalEffectiveYield = baseYieldRate
            .mul(protocolHealthFactor)
            .div(1000) // Divide by 1000 for healthFactor scaling (e.g., 1000 -> 1.0)
            .mul(effectiveMultiplier)
            .div(1000) // Divide by 1000 for yieldMultiplier scaling (e.g., 1500 -> 1.5)
            .add(skillBoostFactor); // Add direct skill boost factor

        return totalEffectiveYield;
    }

    // --- II. Reputation Management ---

    /**
     * @dev Public view function to get a user's current reputation score.
     *      This function calculates the score dynamically, applying decay without changing state.
     * @param user The address of the user.
     * @return The user's reputation score.
     */
    function getReputation(address user) public view returns (uint256) {
        if (block.timestamp <= lastReputationUpdate[user] || reputationScores[user] == 0) {
            return reputationScores[user];
        }
        uint256 timeElapsed = block.timestamp.sub(lastReputationUpdate[user]);
        uint256 daysElapsed = timeElapsed.div(1 days);
        uint256 decayedPoints = daysElapsed.mul(reputationDecayRatePerDay);
        
        // Ensure reputation doesn't go negative
        return reputationScores[user].sub(decayedPoints > reputationScores[user] ? reputationScores[user] : decayedPoints);
    }

    /**
     * @dev Governor-only function to manually add reputation points to a user.
     *      This could be for specific contributions, bug bounties, etc.
     * @param user The address of the user.
     * @param points The number of reputation points to add.
     */
    function addReputation(address user, uint256 points) external onlyGovernor {
        _applyReputationDecay(user); // Apply decay before adding new points
        reputationScores[user] = reputationScores[user].add(points);
        lastReputationUpdate[user] = block.timestamp; // Reset update time
        emit ReputationAdded(user, points);
    }

    /**
     * @dev Internal helper to apply time-based reputation decay.
     *      This is called on any user interaction that might need an up-to-date reputation.
     *      It updates the state (reputationScores and lastReputationUpdate).
     * @param user The address of the user.
     */
    function _applyReputationDecay(address user) internal {
        if (block.timestamp <= lastReputationUpdate[user] || reputationScores[user] == 0) {
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(lastReputationUpdate[user]);
        uint256 daysElapsed = timeElapsed.div(1 days);
        uint256 oldScore = reputationScores[user];
        uint256 decayedPoints = daysElapsed.mul(reputationDecayRatePerDay);

        if (decayedPoints >= reputationScores[user]) {
            reputationScores[user] = 0; // Reputation fully decayed
        } else {
            reputationScores[user] = reputationScores[user].sub(decayedPoints);
        }
        lastReputationUpdate[user] = block.timestamp; // Reset update time
        emit ReputationDecayed(user, oldScore, reputationScores[user]);
    }

    /**
     * @dev Public view function to get the current reputation decay rate per day.
     * @return The daily reputation decay rate.
     */
    function getReputationDecayRate() public view returns (uint256) {
        return reputationDecayRatePerDay;
    }

    /**
     * @dev Governor-only function to set the daily reputation decay rate.
     * @param newRate The new reputation decay rate per day.
     */
    function setReputationDecayRate(uint256 newRate) external onlyGovernor {
        reputationDecayRatePerDay = newRate;
    }

    // --- III. Skill NFT Management (Soul-bound ERC-721-like) ---
    // These NFTs are non-transferable and serve as verifiable credentials on-chain.

    /**
     * @dev Governor-only function to issue a soul-bound Skill NFT to a recipient.
     *      These NFTs are non-transferable.
     * @param recipient The address to mint the NFT to.
     * @param skillId A unique identifier for the type of skill (e.g., 1 for "Data Verifier", 2 for "Community Mod").
     * @param uri The URI pointing to the metadata of the NFT.
     */
    function mintSkillNFT(address recipient, uint256 skillId, string memory uri) external onlyGovernor {
        require(recipient != address(0), "Chameleon: Mint to the zero address");
        _applyReputationDecay(recipient); // Apply decay before potentially boosting reputation

        uint256 newTokenId = _nextTokenId++;
        skillTokenIdToOwner[newTokenId] = recipient;
        ownerToSkillTokenIds[recipient].push(newTokenId); // Add to user's list of NFTs
        skillTokenIdToUri[newTokenId] = uri;

        // Optionally, add reputation for minting a skill NFT, based on skill type attributes
        uint256 reputationBoost = skillTypeAttributes[skillId]["reputationBoost"];
        if (reputationBoost > 0) {
            reputationScores[recipient] = reputationScores[recipient].add(reputationBoost);
            lastReputationUpdate[recipient] = block.timestamp; // Update last reputation update
        }

        emit SkillNFTMinted(recipient, newTokenId, skillId, uri);
    }

    /**
     * @dev Governor-only function to burn a specific Skill NFT from its owner.
     * @param owner The address currently holding the NFT.
     * @param tokenId The ID of the NFT to burn.
     */
    function burnSkillNFT(address owner, uint256 tokenId) external onlyGovernor {
        require(skillTokenIdToOwner[tokenId] == owner, "Chameleon: Not NFT owner");
        _applyReputationDecay(owner); // Apply decay before burning (no direct rep change from burn in this example)

        // Remove from ownerToSkillTokenIds mapping
        uint256[] storage skills = ownerToSkillTokenIds[owner];
        for (uint256 i = 0; i < skills.length; i++) {
            if (skills[i] == tokenId) {
                // Replace with last element and pop to maintain array density
                skills[i] = skills[skills.length - 1];
                skills.pop();
                break;
            }
        }

        delete skillTokenIdToOwner[tokenId]; // Clear owner
        delete skillTokenIdToUri[tokenId]; // Clear URI

        emit SkillNFTBurned(owner, tokenId);
    }

    /**
     * @dev Public view function to get the metadata URI of a specific Skill NFT.
     * @param tokenId The ID of the Skill NFT.
     * @return The metadata URI string.
     */
    function getSkillNFTMetadataURI(uint256 tokenId) public view returns (string memory) {
        return skillTokenIdToUri[tokenId];
    }

    /**
     * @dev Public view function to retrieve all Skill NFT token IDs held by a user.
     * @param user The address of the user.
     * @return An array of Skill NFT token IDs.
     */
    function getSkillsOf(address user) public view returns (uint256[] memory) {
        return ownerToSkillTokenIds[user];
    }

    /**
     * @dev Governor-only function to set a numerical attribute for a specific skill type.
     *      E.g., set "reputationBoost" or "reputationBoostFactor" for skillId 1.
     * @param skillId The ID representing the type of skill.
     * @param key The string key for the attribute (e.g., "reputationBoost").
     * @param value The numerical value for the attribute.
     */
    function setSkillNFTAttribute(uint256 skillId, string memory key, uint256 value) external onlyGovernor {
        skillTypeAttributes[skillId][key] = value;
    }

    /**
     * @dev Public view function to get a specific numerical attribute for a skill type.
     * @param skillId The ID representing the type of skill.
     * @param key The string key for the attribute.
     * @return The numerical value of the attribute.
     */
    function getSkillNFTAttribute(uint256 skillId, string memory key) public view returns (uint256) {
        return skillTypeAttributes[skillId][key];
    }

    // --- IV. Protocol Parameter Control ---

    /**
     * @dev Governor-only or Whitelisted Agent function to update the protocol's health factor.
     *      This factor directly influences the base yield rate.
     * @param newFactor The new health factor, scaled by 1000 (e.g., 1000 = 1.0, 500 = 0.5).
     */
    function setProtocolHealthFactor(uint256 newFactor) external onlyWhitelistedAgentOrGovernor {
        require(newFactor > 0, "Chameleon: Health factor must be positive");
        emit ProtocolHealthFactorUpdated(protocolHealthFactor, newFactor);
        protocolHealthFactor = newFactor;
        // Optionally trigger global reward update here to instantly apply new health factor
        _updateUserReward(address(0)); // Update global reward state
    }

    /**
     * @dev Public view function to get the current protocol health factor.
     * @return The current health factor, scaled by 1000.
     */
    function getProtocolHealthFactor() public view returns (uint256) {
        return protocolHealthFactor;
    }

    /**
     * @dev Governor-only function to set a yield multiplier for a specific reputation tier.
     *      Tier 0 is the base tier. Multipliers are scaled by 1000 (e.g., 1500 = 1.5x).
     * @param reputationTier The integer representation of the reputation tier.
     * @param multiplier The yield multiplier for this tier, scaled by 1000.
     */
    function setYieldMultiplier(uint256 reputationTier, uint256 multiplier) external onlyGovernor {
        require(multiplier > 0, "Chameleon: Multiplier must be positive");
        emit YieldMultiplierUpdated(reputationTier, yieldMultipliers[reputationTier], multiplier);
        yieldMultipliers[reputationTier] = multiplier;
    }

    /**
     * @dev Public view function to get the yield multiplier for a specific reputation tier.
     * @param reputationTier The integer representation of the reputation tier.
     * @return The yield multiplier for the tier, scaled by 1000.
     */
    function getYieldMultiplier(uint256 reputationTier) public view returns (uint256) {
        return yieldMultipliers[reputationTier];
    }

    /**
     * @dev Governor-only function to withdraw funds from the protocol's treasury.
     *      This could be used for protocol operations, liquidity management, etc.
     * @param recipient The address to send the funds to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawTreasuryFunds(address recipient, uint256 amount) external onlyGovernor {
        require(stakingToken.balanceOf(address(this)) >= amount, "Chameleon: Insufficient treasury balance");
        stakingToken.transfer(recipient, amount);
    }

    /**
     * @dev Public function to deposit funds directly into the protocol's treasury.
     *      These funds can be used to support protocol operations or reward pools.
     * @param amount The amount of tokens to deposit.
     */
    function depositTreasuryFunds(uint256 amount) external {
        require(amount > 0, "Chameleon: Deposit amount must be positive");
        stakingToken.transferFrom(_msgSender(), address(this), amount);
    }

    // --- V. Autonomous Agent Module ---

    /**
     * @dev Governor-only function to whitelist an autonomous agent with specific permissions.
     *      Permissions are granted using a bitmap (e.g., 1 for health factor, 2 for other, 3 for both).
     * @param agentAddress The address of the agent contract.
     * @param permissionBitmap A bitmap representing the permissions granted to the agent.
     */
    function whitelistAgent(address agentAddress, uint256 permissionBitmap) external onlyGovernor {
        require(agentAddress != address(0), "Chameleon: Cannot whitelist zero address");
        whitelistedAgents[agentAddress] = permissionBitmap;
        _grantRole(AGENT_ROLE, agentAddress); // Grant the agent role from AccessControl
        emit AgentWhitelisted(agentAddress, permissionBitmap);
    }

    /**
     * @dev Governor-only function to revoke an agent's whitelist status and permissions.
     * @param agentAddress The address of the agent contract.
     */
    function revokeAgent(address agentAddress) external onlyGovernor {
        require(agentAddress != address(0), "Chameleon: Cannot revoke zero address");
        whitelistedAgents[agentAddress] = 0; // Clear permissions
        _revokeRole(AGENT_ROLE, agentAddress); // Revoke the agent role
        emit AgentRevoked(agentAddress);
    }

    /**
     * @dev Public view function to get the permission bitmap of a whitelisted agent.
     * @param agentAddress The address of the agent contract.
     * @return The permission bitmap.
     */
    function getAgentPermissions(address agentAddress) public view returns (uint256) {
        return whitelistedAgents[agentAddress];
    }

    /**
     * @dev Whitelisted Agent function to perform pre-approved actions.
     *      The `actionId` determines which specific action the agent intends to perform.
     *      A more robust system would use a direct mapping or a lookup table for `actionId` to function calls.
     * @param actionId A unique identifier for the action to be executed (e.g., 1 for updating health factor).
     * @param data Arbitrary calldata specific to the action, encoded for the target function.
     */
    function executeAgentAction(uint256 actionId, bytes calldata data) external {
        require(hasRole(AGENT_ROLE, _msgSender()), "Chameleon: Caller not a whitelisted AGENT_ROLE");
        uint256 permissions = whitelistedAgents[_msgSender()];

        if (actionId == 1) { // Action: setProtocolHealthFactor
            require((permissions & AGENT_PERM_SET_HEALTH_FACTOR) != 0, "Chameleon: Agent lacks permission for this action");
            
            // Decode the parameter for setProtocolHealthFactor (assuming it expects uint256)
            uint256 newHealthFactor = abi.decode(data, (uint256));
            setProtocolHealthFactor(newHealthFactor); // Call the internal function
        } else {
            revert("Chameleon: Agent action not recognized or invalid");
        }
        emit AgentActionExecuted(_msgSender(), actionId, data);
    }

    // Fallback function for receiving Ether (optional, but good practice for contracts that might receive ETH)
    receive() external payable {}
}
```