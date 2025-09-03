Here's a smart contract system, named "Nebula Protocol," designed with advanced concepts around **Adaptive Tokenomics, Reputation-Bound NFTs (Soulbound), and Decentralized Value Accrual.**

The core idea is a protocol that dynamically adjusts its token emissions and incentivizes long-term, positive engagement through an evolving, non-transferable NFT (`NebulaCore`). This NFT represents a user's on-chain reputation and grants escalating influence within the protocol, which can also be delegated without transferring the NFT itself. The protocol's "health" is a dynamic metric, potentially derived from on-chain and off-chain data (via oracles), that directly influences reward distribution rates and other parameters.

---

## Nebula Protocol: Self-Optimizing Value Accrual & Reputation System

**Overview:**
The Nebula Protocol introduces a novel approach to decentralized value accrual and community engagement. It integrates a fungible utility token (`NEB`), a non-transferable, evolving reputation NFT (`NebulaCore`), and a dynamic "Gravity Pool" for emissions. The protocol's core parameters, especially its emission rate, are adaptively adjusted based on a calculated "Protocol Health Score," encouraging sustainable growth and rewarding loyal contributors. Users earn `NebulaCore` NFTs, which can be upgraded and staked to gain influence, vote on contributions, and claim dynamic rewards.

**Key Concepts:**
1.  **Adaptive Tokenomics:** Emission rates for the `NEB` token are not fixed but dynamically adjust based on the `Protocol Health Score`.
2.  **Reputation-Bound NFTs (NebulaCore):** `NebulaCore` is a non-transferable (soulbound) ERC-721 token that represents a user's standing and contribution within the protocol.
3.  **Evolving NFTs:** `NebulaCore` NFTs can be upgraded through on-chain actions (e.g., staking `NEB` or fulfilling criteria), unlocking higher levels of influence and benefits.
4.  **Delegated Influence:** `NebulaCore` holders can delegate their influence (voting power, claim to emissions) to another address without transferring the underlying NFT, enabling liquid democracy or specialized roles.
5.  **Gravity Pool:** A central treasury that accumulates `NEB` (and potentially other assets) from protocol fees, contributions, and deposits, acting as the source for adaptive emissions.
6.  **Protocol Health Score:** A dynamic, multi-variable metric (potentially from oracles like Chainlink) that reflects the protocol's overall well-being, TVL, engagement, etc., directly influencing emission rates.
7.  **Decentralized Contribution Validation:** `NebulaCore` holders can vote on and validate off-chain contributions, enabling a community-driven meritocracy.

---

### Function Summary:

**I. Core Protocol Management & Configuration (`NebulaProtocol` Operations)**
1.  `initializeProtocol()`: Sets initial admin, deploys the `NebulaCoreToken` (if not already), and configures base parameters.
2.  `updateProtocolConfig()`: Allows governance or admin to adjust core protocol parameters (e.g., `emissionFactor`, `healthScoreWeight`).
3.  `pauseProtocol()`: Pauses critical operations to mitigate risks or for upgrades.
4.  `unpauseProtocol()`: Unpauses the protocol.
5.  `setExternalOracle()`: Sets the address of an external oracle for fetching off-chain data relevant to the Protocol Health Score.
6.  `triggerHealthScoreRecalculation()`: Initiates the recalculation of the `protocolHealthScore` using oracle data and internal metrics.
7.  `getProtocolHealthScore()`: Returns the current calculated health score of the protocol.

**II. NebulaCore (Reputation SBT) Interactions (`NebulaProtocol` interfacing with `NebulaCoreToken`)**
8.  `issueNebulaCore()`: Mints a new `NebulaCore` NFT for an eligible user (e.g., first interaction, specific criteria met).
9.  `upgradeNebulaCoreLevel()`: Allows a `NebulaCore` holder to spend `NEB` or meet criteria to upgrade their NFT's level, enhancing its influence.
10. `delegateCoreInfluence()`: Enables a `NebulaCore` holder to delegate their NFT's staking and voting influence to another address.
11. `revokeCoreInfluenceDelegation()`: Revokes a previously set influence delegation.
12. `getNebulaCoreDetails()`: Retrieves the level, current influence (based on level & stake), and delegatee of a specific `NebulaCore` NFT.

**III. Gravity Pool & Adaptive Emission Dynamics (`NebulaProtocol` Operations)**
13. `depositToGravityPool()`: Allows users or other protocols to deposit `NEB` or whitelisted tokens into the central "Gravity Pool."
14. `distributeAdaptiveEmissions()`: Triggers the calculation and distribution of `NEB` rewards from the Gravity Pool to active `NebulaCore` stakers based on the current `protocolHealthScore`. Callable by anyone, potentially with a small bounty.
15. `claimEpochRewards()`: Allows users to claim their accumulated `NEB` rewards from past emission epochs.
16. `getGravityPoolBalance()`: Returns the total balance of the `NEB` token held within the Gravity Pool.
17. `getPendingEpochRewards()`: Calculates and returns the pending `NEB` rewards for a specific user from active epochs.

**IV. Contribution & Staking System (`NebulaProtocol` Operations)**
18. `submitContribution()`: Users submit an identifier (e.g., IPFS hash) for an off-chain contribution they've made, pending community review.
19. `voteOnContribution()`: `NebulaCore` holders use their staked influence to vote on the validity and impact of submitted contributions.
20. `claimContributionReward()`: Allows the submitter of an approved contribution to claim a predefined `NEB` reward.
21. `stakeNebulaCoreForInfluence()`: Locks a `NebulaCore` NFT, making its influence active for governance, voting, and emission distribution.
22. `unstakeNebulaCoreForInfluence()`: Unlocks a previously staked `NebulaCore` NFT, making it available for other actions.
23. `getTotalStakedInfluence()`: Returns the total sum of influence staked across all `NebulaCore` NFTs.

**V. Light Governance & Proposals (`NebulaProtocol` Operations)**
24. `proposeConfigChange()`: Allows `NebulaCore` holders to submit a proposal for changing a protocol configuration parameter.
25. `voteOnProposal()`: Casts a vote on an active governance proposal using staked `NebulaCore` influence.
26. `executeProposal()`: Executes a governance proposal that has met its voting threshold and passed.

---

### Solidity Smart Contract Code:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety

// Mock Oracle for demonstration purposes. In a real scenario, this would be Chainlink or similar.
interface IExternalOracle {
    function getLatestHealthMetrics() external view returns (uint256 totalValueLocked, uint256 activeUsers, uint256 transactionVolume);
}

// Interface for the Nebula Core Token (SBT)
interface INebulaCoreToken {
    function mint(address to) external returns (uint256);
    function upgradeCore(uint256 tokenId, uint256 levelToAchieve) external;
    function getCoreLevel(uint256 tokenId) external view returns (uint256);
    function getCoreInfluence(uint256 tokenId) external view returns (uint256);
    function delegateInfluence(uint256 tokenId, address delegatee) external;
    function revokeInfluenceDelegation(uint256 tokenId) external;
    function getDelegatee(uint256 tokenId) external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
}

// Minimal ERC20 for NEB token for testing, replace with actual NEB token in production
contract MockNEBToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Nebula Token", "NEB") {
        _mint(msg.sender, initialSupply);
    }
}

/**
 * @title NebulaCoreToken
 * @dev An evolving, non-transferable (Soulbound) NFT representing user reputation and influence.
 */
contract NebulaCoreToken is ERC721Enumerable, INebulaCoreToken {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Mapping from tokenId to core level
    mapping(uint256 => uint256) public coreLevels;
    // Mapping from tokenId to delegated address
    mapping(uint256 => address) public delegatees;
    // Base influence per level. Influence scales quadratically.
    // e.g., Level 1: 1 unit, Level 2: 4 units, Level 3: 9 units
    uint256[] public levelBaseInfluence;

    // Reference to the main protocol contract to check for staking or eligibility
    address public nebulaProtocolAddress;

    modifier onlyNebulaProtocol() {
        require(msg.sender == nebulaProtocolAddress, "NCT: Only Nebula Protocol can call this function");
        _;
    }

    constructor(address _nebulaProtocolAddress) ERC721("Nebula Core", "NC") {
        nebulaProtocolAddress = _nebulaProtocolAddress;
        // Initialize level base influences. 0 is a placeholder.
        levelBaseInfluence.push(0); // Level 0 (unused)
        levelBaseInfluence.push(1); // Level 1 (base influence)
        levelBaseInfluence.push(4); // Level 2
        levelBaseInfluence.push(9); // Level 3
        levelBaseInfluence.push(16); // Level 4
        levelBaseInfluence.push(25); // Level 5 (max initial level)
    }

    // Prevents transfers, making it a Soulbound Token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        require(from == address(0) || to == address(0), "NCT: NebulaCore is non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @notice Mints a new NebulaCore NFT for an address.
     * @dev Only callable by the NebulaProtocol contract.
     * @param to The address to mint the NebulaCore for.
     * @return The tokenId of the newly minted NebulaCore.
     */
    function mint(address to) external onlyNebulaProtocol returns (uint256) {
        require(balanceOf(to) == 0, "NCT: Address already owns a NebulaCore.");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(to, newItemId);
        coreLevels[newItemId] = 1; // All new cores start at level 1
        return newItemId;
    }

    /**
     * @notice Allows a user to upgrade their NebulaCore's level.
     * @dev The actual cost or criteria for upgrade is managed by NebulaProtocol.
     * @param tokenId The ID of the NebulaCore to upgrade.
     * @param levelToAchieve The target level for the upgrade.
     */
    function upgradeCore(uint256 tokenId, uint256 levelToAchieve) external onlyNebulaProtocol {
        require(ownerOf(tokenId) != address(0), "NCT: Invalid tokenId");
        require(coreLevels[tokenId] < levelToAchieve, "NCT: Core is already at or above this level.");
        require(levelToAchieve < levelBaseInfluence.length, "NCT: Target level exceeds max configured level.");
        
        coreLevels[tokenId] = levelToAchieve;
        // Emit an event for upgrade
        emit CoreUpgraded(tokenId, levelToAchieve);
    }

    /**
     * @notice Returns the current level of a NebulaCore.
     */
    function getCoreLevel(uint256 tokenId) external view override returns (uint256) {
        return coreLevels[tokenId];
    }

    /**
     * @notice Returns the base influence points for a NebulaCore based on its level.
     * @dev Actual influence might be modified by staking status in NebulaProtocol.
     */
    function getCoreInfluence(uint256 tokenId) public view override returns (uint256) {
        uint256 level = coreLevels[tokenId];
        if (level == 0 || level >= levelBaseInfluence.length) return 0;
        return levelBaseInfluence[level];
    }

    /**
     * @notice Delegates the influence of a NebulaCore to another address.
     * @param tokenId The ID of the NebulaCore.
     * @param delegatee The address to delegate influence to.
     */
    function delegateInfluence(uint256 tokenId, address delegatee) external override {
        require(ownerOf(tokenId) == msg.sender, "NCT: Not owner of Core.");
        require(delegatee != address(0), "NCT: Delegatee cannot be zero address.");
        delegatees[tokenId] = delegatee;
        emit InfluenceDelegated(tokenId, msg.sender, delegatee);
    }

    /**
     * @notice Revokes the influence delegation for a NebulaCore.
     * @param tokenId The ID of the NebulaCore.
     */
    function revokeInfluenceDelegation(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "NCT: Not owner of Core.");
        require(delegatees[tokenId] != address(0), "NCT: No active delegation to revoke.");
        delete delegatees[tokenId];
        emit InfluenceRevoked(tokenId, msg.sender);
    }

    /**
     * @notice Returns the address to which a NebulaCore's influence is delegated.
     */
    function getDelegatee(uint256 tokenId) external view override returns (address) {
        return delegatees[tokenId];
    }

    /**
     * @notice Returns the total number of NebulaCore NFTs minted.
     */
    function getTotalSupply() external view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    event CoreUpgraded(uint256 indexed tokenId, uint256 newLevel);
    event InfluenceDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event InfluenceRevoked(uint256 indexed tokenId, address indexed delegator);
}


/**
 * @title NebulaProtocol
 * @dev The main protocol contract managing adaptive tokenomics, Gravity Pool, and interactions with NebulaCore.
 */
contract NebulaProtocol is Ownable, Pausable {
    using SafeMath for uint256; // For explicit safety

    // --- Core Protocol Configuration ---
    IERC20 public NEB_TOKEN; // The primary utility token of the protocol
    INebulaCoreToken public nebulaCoreToken; // The reputation-bound NFT contract
    IExternalOracle public externalOracle; // Oracle for external data
    
    // Protocol parameters, adjustable by governance
    uint256 public emissionFactor; // Base factor for adaptive emissions (e.g., 1e18 for 1x)
    uint256 public healthScoreWeightTVL; // Weight for TVL in health score calculation
    uint256 public healthScoreWeightActiveUsers; // Weight for active users
    uint256 public healthScoreWeightTxVolume; // Weight for transaction volume
    uint256 public epochDuration; // Duration of an emission epoch in seconds
    uint256 public contributionRewardAmount; // NEB reward for approved contributions
    uint256 public minVoteInfluenceForProposal; // Minimum influence required to create a proposal

    uint256 public protocolHealthScore; // Current calculated health score

    // --- Gravity Pool (Treasury) ---
    mapping(address => uint256) public gravityPoolBalances; // Balances of various tokens in the pool (for NEB, we can use NEB_TOKEN.balanceOf(address(this)))

    // --- Emission & Rewards ---
    uint256 public lastEmissionEpochStartTime;
    uint256 public totalStakedInfluence; // Sum of all active staked NebulaCore influence
    mapping(address => uint256) public userStakedInfluence; // Influence staked by an address (could be delegated)
    mapping(uint256 => mapping(address => uint256)) public epochRewardsAccrued; // epochId => user => rewardsAccrued
    mapping(address => uint256) public lastRewardClaimEpoch; // user => last epoch rewards were claimed

    // --- Staking & NebulaCore Management ---
    mapping(uint256 => bool) public isCoreStaked; // tokenId => true if staked
    mapping(address => uint256[]) public stakedCoresByUser; // user => list of tokenIds they have staked
    mapping(uint256 => address) public coreStakingOwner; // tokenId => owner who staked it

    // --- Contribution System ---
    struct Contribution {
        address submitter;
        string identifier; // E.g., IPFS hash of the contribution details
        uint256 voteCount; // Total influence points voted for this contribution
        uint256 downVoteCount; // Total influence points voted against
        uint256 creationTime;
        bool claimed;
        mapping(address => bool) hasVoted; // User => Voted status
    }
    Counters.Counter private _contributionIdCounter;
    mapping(uint256 => Contribution) public contributions; // contributionId => Contribution

    // --- Light Governance ---
    struct Proposal {
        address proposer;
        bytes32 paramNameHash; // Hash of the parameter name (e.g., keccak256("emissionFactor"))
        uint256 newValue;
        uint256 voteCountFor; // Total influence points for
        uint256 voteCountAgainst; // Total influence points against
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingPeriod; // Duration for proposals to be open for voting

    // --- Events ---
    event ProtocolConfigUpdated(string indexed paramName, uint256 newValue);
    event ProtocolHealthScoreUpdated(uint256 newScore);
    event NebulaCoreIssued(address indexed owner, uint256 indexed tokenId);
    event NebulaCoreUpgraded(address indexed owner, uint256 indexed tokenId, uint256 newLevel);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee, uint256 tokenId);
    event InfluenceRevoked(address indexed delegator, uint256 tokenId);
    event DepositToGravityPool(address indexed depositor, address indexed token, uint256 amount);
    event AdaptiveEmissionsDistributed(uint256 indexed epochId, uint256 totalDistributedAmount, uint256 healthScore);
    event EpochRewardsClaimed(address indexed user, uint256 indexed epochId, uint256 amount);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed submitter, string identifier);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, uint256 influence, bool support);
    event ContributionRewardClaimed(uint256 indexed contributionId, address indexed submitter, uint256 amount);
    event NebulaCoreStaked(address indexed owner, uint256 indexed tokenId, uint256 influence);
    event NebulaCoreUnstaked(address indexed owner, uint256 indexed tokenId, uint256 influence);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 indexed paramNameHash, uint256 newValue, uint256 endTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 influence, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 indexed paramNameHash, uint256 newValue);

    // Modifier to check if the caller has active staked influence
    modifier hasStakedInfluence(address _address) {
        require(userStakedInfluence[_address] > 0, "NP: Caller has no active staked influence.");
        _;
    }

    constructor(address _nebTokenAddress, address _nebulaCoreTokenAddress) Ownable(msg.sender) {
        NEB_TOKEN = IERC20(_nebTokenAddress);
        nebulaCoreToken = INebulaCoreToken(_nebulaCoreTokenAddress);

        // Set initial protocol parameters
        emissionFactor = 100_000_000_000_000_000; // Represents 0.1 NEB per influence unit per epoch for a health score of 100
        healthScoreWeightTVL = 40; // 40%
        healthScoreWeightActiveUsers = 30; // 30%
        healthScoreWeightTxVolume = 30; // 30%
        epochDuration = 7 days; // 1 week
        contributionRewardAmount = 100 * (10 ** 18); // 100 NEB (assuming 18 decimals)
        minVoteInfluenceForProposal = 100; // Example: requires 100 influence points to propose
        proposalVotingPeriod = 3 days; // 3 days for voting
        
        lastEmissionEpochStartTime = block.timestamp;
    }

    // --- I. Core Protocol Management & Configuration ---

    /**
     * @notice Initializes core protocol parameters and contract addresses.
     * @dev Can only be called once by the deployer.
     * @param _externalOracleAddress The address of the external oracle contract.
     */
    function initializeProtocol(address _externalOracleAddress) external onlyOwner {
        require(address(externalOracle) == address(0), "NP: Protocol already initialized.");
        require(_externalOracleAddress != address(0), "NP: Oracle address cannot be zero.");
        externalOracle = IExternalOracle(_externalOracleAddress);
        emit ProtocolConfigUpdated("ExternalOracle", uint256(uint160(_externalOracleAddress)));
    }

    /**
     * @notice Allows governance to update core protocol configuration parameters.
     * @dev Only callable by the owner (or eventually by governance proposals).
     * @param _paramNameHash Hash identifier of the parameter to change (e.g., keccak256("emissionFactor")).
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolConfig(bytes32 _paramNameHash, uint256 _newValue) external onlyOwner whenNotPaused {
        if (_paramNameHash == keccak256("emissionFactor")) {
            emissionFactor = _newValue;
        } else if (_paramNameHash == keccak256("healthScoreWeightTVL")) {
            healthScoreWeightTVL = _newValue;
        } else if (_paramNameHash == keccak256("healthScoreWeightActiveUsers")) {
            healthScoreWeightActiveUsers = _newValue;
        } else if (_paramNameHash == keccak256("healthScoreWeightTxVolume")) {
            healthScoreWeightTxVolume = _newValue;
        } else if (_paramNameHash == keccak256("epochDuration")) {
            epochDuration = _newValue;
        } else if (_paramNameHash == keccak256("contributionRewardAmount")) {
            contributionRewardAmount = _newValue;
        } else if (_paramNameHash == keccak256("minVoteInfluenceForProposal")) {
            minVoteInfluenceForProposal = _newValue;
        } else if (_paramNameHash == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = _newValue;
        } else {
            revert("NP: Invalid parameter name.");
        }
        emit ProtocolConfigUpdated(string(abi.encodePacked(_paramNameHash)), _newValue);
    }

    /**
     * @notice Pauses critical protocol operations.
     * @dev Only callable by the owner.
     */
    function pauseProtocol() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses critical protocol operations.
     * @dev Only callable by the owner.
     */
    function unpauseProtocol() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Sets the address of the external oracle contract.
     * @dev Only callable by the owner.
     * @param _externalOracleAddress The new oracle contract address.
     */
    function setExternalOracle(address _externalOracleAddress) external onlyOwner {
        require(_externalOracleAddress != address(0), "NP: Oracle address cannot be zero.");
        externalOracle = IExternalOracle(_externalOracleAddress);
        emit ProtocolConfigUpdated("ExternalOracle", uint256(uint160(_externalOracleAddress)));
    }

    /**
     * @notice Triggers the recalculation of the protocol's health score.
     * @dev This function could be called periodically by a Keeper bot.
     */
    function triggerHealthScoreRecalculation() external whenNotPaused {
        require(address(externalOracle) != address(0), "NP: Oracle not set.");
        (uint256 tvl, uint256 activeUsers, uint256 txVolume) = externalOracle.getLatestHealthMetrics();

        // Implement a more sophisticated health score calculation.
        // For demonstration: simple weighted average. Normalize inputs to a common scale.
        // Example: Assume 1 unit of TVL = 1 point, 1 active user = 100 points, 1 tx volume = 10 points
        // In a real scenario, this would involve more robust scaling and thresholding.

        uint256 normalizedTVL = tvl.div(10**18); // Assuming TVL is in 18 decimals, normalize to whole units
        uint256 normalizedActiveUsers = activeUsers.mul(100); // Scale active users to be comparable
        uint256 normalizedTxVolume = txVolume.mul(10); // Scale tx volume

        uint256 score = (normalizedTVL.mul(healthScoreWeightTVL) +
                         normalizedActiveUsers.mul(healthScoreWeightActiveUsers) +
                         normalizedTxVolume.mul(healthScoreWeightTxVolume))
                         .div(100); // Divide by total weight (100)

        // Cap or floor the score as needed to prevent extreme values
        protocolHealthScore = score > 1000 ? 1000 : score; // Example cap
        if (protocolHealthScore < 10) protocolHealthScore = 10; // Example floor

        emit ProtocolHealthScoreUpdated(protocolHealthScore);
    }

    /**
     * @notice Returns the current calculated health score of the protocol.
     */
    function getProtocolHealthScore() external view returns (uint256) {
        return protocolHealthScore;
    }

    // --- II. NebulaCore (Reputation SBT) Interactions ---

    /**
     * @notice Mints a new NebulaCore NFT for an eligible user.
     * @dev Only callable if the user doesn't already own a NebulaCore.
     * @param to The address to issue the NebulaCore to.
     */
    function issueNebulaCore(address to) external onlyOwner whenNotPaused returns (uint256) {
        require(nebulaCoreToken.balanceOf(to) == 0, "NP: User already has a NebulaCore.");
        uint256 tokenId = nebulaCoreToken.mint(to);
        emit NebulaCoreIssued(to, tokenId);
        return tokenId;
    }

    /**
     * @notice Allows a user to upgrade their NebulaCore's level.
     * @dev Requires staking NEB or other criteria (implement specific logic here).
     * @param tokenId The ID of the NebulaCore to upgrade.
     * @param levelToAchieve The target level for the upgrade.
     */
    function upgradeNebulaCoreLevel(uint256 tokenId, uint256 levelToAchieve) external whenNotPaused {
        require(nebulaCoreToken.ownerOf(tokenId) == msg.sender, "NP: Not owner of NebulaCore.");
        require(levelToAchieve > nebulaCoreToken.getCoreLevel(tokenId), "NP: Target level must be higher.");
        
        // Example: Require spending NEB proportional to the level increase
        // uint256 cost = calculateUpgradeCost(nebulaCoreToken.getCoreLevel(tokenId), levelToAchieve);
        // require(NEB_TOKEN.transferFrom(msg.sender, address(this), cost), "NP: NEB transfer failed for upgrade.");
        // emit DepositToGravityPool(msg.sender, address(NEB_TOKEN), cost); // Upgrade costs go to Gravity Pool

        // The actual upgrade logic is in NebulaCoreToken.
        nebulaCoreToken.upgradeCore(tokenId, levelToAchieve);
        emit NebulaCoreUpgraded(msg.sender, tokenId, levelToAchieve);
    }

    /**
     * @notice Allows a NebulaCore holder to delegate their NFT's staking and voting influence.
     * @dev The actual influence is still associated with the tokenId, but claimed by the delegatee.
     * @param tokenId The ID of the NebulaCore to delegate.
     * @param delegatee The address to delegate influence to.
     */
    function delegateCoreInfluence(uint256 tokenId, address delegatee) external whenNotPaused {
        require(nebulaCoreToken.ownerOf(tokenId) == msg.sender, "NP: Not owner of NebulaCore.");
        nebulaCoreToken.delegateInfluence(tokenId, delegatee);
        emit InfluenceDelegated(msg.sender, delegatee, tokenId);
    }

    /**
     * @notice Revokes a previously set influence delegation.
     * @param tokenId The ID of the NebulaCore to revoke delegation from.
     */
    function revokeCoreInfluenceDelegation(uint256 tokenId) external whenNotPaused {
        require(nebulaCoreToken.ownerOf(tokenId) == msg.sender, "NP: Not owner of NebulaCore.");
        nebulaCoreToken.revokeInfluenceDelegation(tokenId);
        emit InfluenceRevoked(msg.sender, tokenId);
    }

    /**
     * @notice Retrieves the level, current influence (based on level & stake), and delegatee of a specific NebulaCore NFT.
     * @param tokenId The ID of the NebulaCore.
     * @return _owner The owner of the NFT.
     * @return _level The current level of the NFT.
     * @return _influence The base influence of the NFT.
     * @return _delegatee The address it's delegated to (or owner if not delegated).
     * @return _isStaked True if the NFT is currently staked.
     */
    function getNebulaCoreDetails(uint256 tokenId)
        external
        view
        returns (address _owner, uint256 _level, uint256 _influence, address _delegatee, bool _isStaked)
    {
        _owner = nebulaCoreToken.ownerOf(tokenId);
        _level = nebulaCoreToken.getCoreLevel(tokenId);
        _influence = nebulaCoreToken.getCoreInfluence(tokenId);
        _delegatee = nebulaCoreToken.getDelegatee(tokenId) == address(0) ? _owner : nebulaCoreToken.getDelegatee(tokenId);
        _isStaked = isCoreStaked[tokenId];
    }

    // --- III. Gravity Pool & Adaptive Emission Dynamics ---

    /**
     * @notice Allows users or other protocols to deposit NEB or whitelisted tokens into the Gravity Pool.
     * @param token The address of the token to deposit.
     * @param amount The amount of token to deposit.
     */
    function depositToGravityPool(address token, uint256 amount) external whenNotPaused {
        require(token != address(0), "NP: Invalid token address.");
        require(amount > 0, "NP: Amount must be greater than zero.");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (token == address(NEB_TOKEN)) {
            // For NEB, we can track internal balance or rely on NEB_TOKEN.balanceOf(this)
            // gravityPoolBalances[token] = gravityPoolBalances[token].add(amount); // Optional, if tracking other tokens explicitly
        } else {
            gravityPoolBalances[token] = gravityPoolBalances[token].add(amount); // Track for non-NEB tokens
        }
        emit DepositToGravityPool(msg.sender, token, amount);
    }

    /**
     * @notice Triggers the calculation and distribution of NEB rewards from the Gravity Pool.
     * @dev Can be called by anyone to advance the epoch and distribute rewards.
     *      The caller might be incentivized by a small portion of the distributed rewards (not implemented here).
     */
    function distributeAdaptiveEmissions() external whenNotPaused {
        require(block.timestamp >= lastEmissionEpochStartTime.add(epochDuration), "NP: Current epoch not finished yet.");
        require(protocolHealthScore > 0, "NP: Health score not calculated or is zero.");

        uint256 currentEpochId = lastEmissionEpochStartTime.add(epochDuration);
        uint256 timeSinceLastEpoch = currentEpochId.sub(lastEmissionEpochStartTime);
        
        // Calculate dynamic emission amount for the epoch
        // Example: emission = (totalStakedInfluence * emissionFactor * protocolHealthScore * time_in_epochs) / (1e18 * MaxHealthScore)
        // Adjust emissionFactor if you want a different base rate. MaxHealthScore for normalization.
        uint256 emissionsForEpoch = totalStakedInfluence
            .mul(emissionFactor)
            .mul(protocolHealthScore)
            .div(1000); // Assuming protocolHealthScore max is 1000 for easier calculation. Scale down.

        // Ensure there's enough NEB in the Gravity Pool
        uint256 availableNEB = NEB_TOKEN.balanceOf(address(this));
        uint256 actualDistributedAmount = emissionsForEpoch > availableNEB ? availableNEB : emissionsForEpoch;

        if (actualDistributedAmount == 0) {
            lastEmissionEpochStartTime = currentEpochId;
            emit AdaptiveEmissionsDistributed(currentEpochId, 0, protocolHealthScore);
            return;
        }

        // Distribute rewards proportionally to staked influence
        if (totalStakedInfluence > 0) {
            uint256 rewardPerInfluence = actualDistributedAmount.div(totalStakedInfluence);

            for (uint256 i = 0; i < nebulaCoreToken.getTotalSupply(); i++) {
                uint256 tokenId = nebulaCoreToken.tokenByIndex(i); // Iterate through all cores
                if (isCoreStaked[tokenId]) {
                    address coreOwner = coreStakingOwner[tokenId];
                    address delegatee = nebulaCoreToken.getDelegatee(tokenId);
                    address actualRecipient = delegatee == address(0) ? coreOwner : delegatee;
                    
                    uint256 influence = nebulaCoreToken.getCoreInfluence(tokenId);
                    uint256 userShare = influence.mul(rewardPerInfluence);
                    
                    if (userShare > 0) {
                        epochRewardsAccrued[currentEpochId][actualRecipient] = epochRewardsAccrued[currentEpochId][actualRecipient].add(userShare);
                    }
                }
            }
        }

        lastEmissionEpochStartTime = currentEpochId;
        emit AdaptiveEmissionsDistributed(currentEpochId, actualDistributedAmount, protocolHealthScore);
    }

    /**
     * @notice Allows users to claim their accumulated NEB rewards from past emission epochs.
     */
    function claimEpochRewards() external whenNotPaused {
        uint256 totalClaimable = 0;
        uint256 currentEpoch = block.timestamp.div(epochDuration).mul(epochDuration); // Current epoch start time
        if (currentEpoch == lastEmissionEpochStartTime.add(epochDuration)) { // if distributeAdaptiveEmissions() hasn't been called for current epoch
            currentEpoch = lastEmissionEpochStartTime;
        }

        for (uint256 epochId = lastRewardClaimEpoch[msg.sender]; epochId < currentEpoch; epochId = epochId.add(epochDuration)) {
            if (epochRewardsAccrued[epochId][msg.sender] > 0) {
                totalClaimable = totalClaimable.add(epochRewardsAccrued[epochId][msg.sender]);
                epochRewardsAccrued[epochId][msg.sender] = 0; // Clear claimed rewards
            }
        }
        
        require(totalClaimable > 0, "NP: No rewards to claim.");

        lastRewardClaimEpoch[msg.sender] = currentEpoch; // Update last claimed epoch

        NEB_TOKEN.transfer(msg.sender, totalClaimable);
        emit EpochRewardsClaimed(msg.sender, currentEpoch, totalClaimable);
    }
    
    /**
     * @notice Returns the total balance of NEB in the Gravity Pool.
     */
    function getGravityPoolBalance() external view returns (uint256) {
        return NEB_TOKEN.balanceOf(address(this));
    }

    /**
     * @notice Calculates and returns the pending NEB rewards for a specific user from active epochs.
     * @param user The address of the user to check.
     * @return The total pending NEB rewards for the user.
     */
    function getPendingEpochRewards(address user) external view returns (uint256) {
        uint256 totalPending = 0;
        uint256 currentEpoch = block.timestamp.div(epochDuration).mul(epochDuration);
        if (currentEpoch == lastEmissionEpochStartTime.add(epochDuration)) {
            currentEpoch = lastEmissionEpochStartTime;
        }

        for (uint256 epochId = lastRewardClaimEpoch[user]; epochId < currentEpoch; epochId = epochId.add(epochDuration)) {
            totalPending = totalPending.add(epochRewardsAccrued[epochId][user]);
        }
        return totalPending;
    }


    // --- IV. Contribution & Staking System ---

    /**
     * @notice Users submit an identifier for an off-chain contribution for community review.
     * @param identifier An IPFS hash or URL pointing to the contribution details.
     */
    function submitContribution(string calldata identifier) external hasStakedInfluence(msg.sender) whenNotPaused {
        _contributionIdCounter.increment();
        uint256 id = _contributionIdCounter.current();
        contributions[id] = Contribution({
            submitter: msg.sender,
            identifier: identifier,
            voteCount: 0,
            downVoteCount: 0,
            creationTime: block.timestamp,
            claimed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        emit ContributionSubmitted(id, msg.sender, identifier);
    }

    /**
     * @notice NebulaCore holders vote on submitted contributions.
     * @param contributionId The ID of the contribution to vote on.
     * @param support True for a positive vote, false for a negative vote.
     */
    function voteOnContribution(uint256 contributionId, bool support) external hasStakedInfluence(msg.sender) whenNotPaused {
        Contribution storage c = contributions[contributionId];
        require(c.submitter != address(0), "NP: Contribution does not exist.");
        require(c.hasVoted[msg.sender] == false, "NP: Already voted on this contribution.");

        uint256 influence = userStakedInfluence[msg.sender];
        require(influence > 0, "NP: You need active staked influence to vote.");

        if (support) {
            c.voteCount = c.voteCount.add(influence);
        } else {
            c.downVoteCount = c.downVoteCount.add(influence);
        }
        c.hasVoted[msg.sender] = true;
        emit ContributionVoted(contributionId, msg.sender, influence, support);
    }

    /**
     * @notice Allows the submitter of an approved contribution to claim a predefined NEB reward.
     * @dev A contribution is considered "approved" if it has significantly more positive votes than negative.
     *      Thresholds can be adjusted (e.g., voteCount > downVoteCount * 2).
     * @param contributionId The ID of the contribution.
     */
    function claimContributionReward(uint256 contributionId) external whenNotPaused {
        Contribution storage c = contributions[contributionId];
        require(c.submitter == msg.sender, "NP: Only submitter can claim reward.");
        require(c.claimed == false, "NP: Reward already claimed.");
        require(c.voteCount > c.downVoteCount.mul(2), "NP: Contribution not sufficiently approved."); // Example threshold

        c.claimed = true;
        NEB_TOKEN.transfer(msg.sender, contributionRewardAmount);
        emit ContributionRewardClaimed(contributionId, msg.sender, contributionRewardAmount);
    }

    /**
     * @notice Locks a NebulaCore NFT, making its influence active for governance and emissions.
     * @param tokenId The ID of the NebulaCore to stake.
     */
    function stakeNebulaCoreForInfluence(uint256 tokenId) external whenNotPaused {
        require(nebulaCoreToken.ownerOf(tokenId) == msg.sender, "NP: Not owner of NebulaCore.");
        require(isCoreStaked[tokenId] == false, "NP: NebulaCore is already staked.");

        uint256 influence = nebulaCoreToken.getCoreInfluence(tokenId);
        require(influence > 0, "NP: NebulaCore has no influence to stake.");

        isCoreStaked[tokenId] = true;
        coreStakingOwner[tokenId] = msg.sender;
        
        address actualInfluencer = nebulaCoreToken.getDelegatee(tokenId) == address(0) ? msg.sender : nebulaCoreToken.getDelegatee(tokenId);

        userStakedInfluence[actualInfluencer] = userStakedInfluence[actualInfluencer].add(influence);
        totalStakedInfluence = totalStakedInfluence.add(influence);
        
        stakedCoresByUser[msg.sender].push(tokenId);
        
        emit NebulaCoreStaked(msg.sender, tokenId, influence);
    }

    /**
     * @notice Unlocks a previously staked NebulaCore NFT.
     * @param tokenId The ID of the NebulaCore to unstake.
     */
    function unstakeNebulaCoreForInfluence(uint256 tokenId) external whenNotPaused {
        require(coreStakingOwner[tokenId] == msg.sender, "NP: Only original staker can unstake.");
        require(isCoreStaked[tokenId] == true, "NP: NebulaCore is not staked.");

        uint256 influence = nebulaCoreToken.getCoreInfluence(tokenId);
        isCoreStaked[tokenId] = false;
        delete coreStakingOwner[tokenId];

        address actualInfluencer = nebulaCoreToken.getDelegatee(tokenId) == address(0) ? msg.sender : nebulaCoreToken.getDelegatee(tokenId);

        userStakedInfluence[actualInfluencer] = userStakedInfluence[actualInfluencer].sub(influence);
        totalStakedInfluence = totalStakedInfluence.sub(influence);

        // Remove from stakedCoresByUser array (simple but potentially inefficient for large arrays)
        for (uint256 i = 0; i < stakedCoresByUser[msg.sender].length; i++) {
            if (stakedCoresByUser[msg.sender][i] == tokenId) {
                stakedCoresByUser[msg.sender][i] = stakedCoresByUser[msg.sender][stakedCoresByUser[msg.sender].length - 1];
                stakedCoresByUser[msg.sender].pop();
                break;
            }
        }

        emit NebulaCoreUnstaked(msg.sender, tokenId, influence);
    }

    /**
     * @notice Returns the total influence currently staked across all NebulaCore NFTs.
     */
    function getTotalStakedInfluence() external view returns (uint256) {
        return totalStakedInfluence;
    }

    // --- V. Light Governance & Proposals ---

    /**
     * @notice Allows NebulaCore holders to submit a proposal for changing a protocol configuration parameter.
     * @param _paramNameHash Hash identifier of the parameter to change.
     * @param _newValue The proposed new value for the parameter.
     */
    function proposeConfigChange(bytes32 _paramNameHash, uint256 _newValue) external hasStakedInfluence(msg.sender) whenNotPaused {
        require(userStakedInfluence[msg.sender] >= minVoteInfluenceForProposal, "NP: Not enough influence to propose.");
        
        _proposalIdCounter.increment();
        uint256 id = _proposalIdCounter.current();
        proposals[id] = Proposal({
            proposer: msg.sender,
            paramNameHash: _paramNameHash,
            newValue: _newValue,
            voteCountFor: 0,
            voteCountAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp.add(proposalVotingPeriod),
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize the mapping
        });
        emit ProposalCreated(id, msg.sender, _paramNameHash, _newValue, proposals[id].endTime);
    }

    /**
     * @notice Casts a vote on an active governance proposal using staked NebulaCore influence.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a positive vote, false for a negative vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external hasStakedInfluence(msg.sender) whenNotPaused {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "NP: Proposal does not exist.");
        require(block.timestamp <= p.endTime, "NP: Voting period has ended.");
        require(p.executed == false, "NP: Proposal already executed.");
        require(p.hasVoted[msg.sender] == false, "NP: Already voted on this proposal.");

        uint256 influence = userStakedInfluence[msg.sender];
        require(influence > 0, "NP: You need active staked influence to vote.");

        if (support) {
            p.voteCountFor = p.voteCountFor.add(influence);
        } else {
            p.voteCountAgainst = p.voteCountAgainst.add(influence);
        }
        p.hasVoted[msg.sender] = true;
        emit ProposalVoted(proposalId, msg.sender, influence, support);
    }

    /**
     * @notice Executes a governance proposal that has met its voting threshold and passed.
     * @dev A proposal is considered "passed" if it has significantly more positive votes than negative.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage p = proposals[proposalId];
        require(p.proposer != address(0), "NP: Proposal does not exist.");
        require(block.timestamp > p.endTime, "NP: Voting period not yet ended.");
        require(p.executed == false, "NP: Proposal already executed.");
        require(p.voteCountFor > p.voteCountAgainst.mul(2), "NP: Proposal did not pass voting threshold."); // Example threshold

        p.executed = true;
        updateProtocolConfig(p.paramNameHash, p.newValue); // Use internal update function
        emit ProposalExecuted(proposalId, p.paramNameHash, p.newValue);
    }
}
```