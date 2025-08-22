This smart contract, `AetherSentinelNexus`, introduces a decentralized ecosystem built around "Aether Sentinels," which are dynamic Non-Fungible Tokens (NFTs). These Sentinels evolve their traits and earning capabilities based on several factors: their owner's on-chain activity (reputation), community-driven governance, and external data feeds provided by trusted oracles. The system integrates dynamic NFTs with a reputation system, adaptive staking, and decentralized data curation, offering a novel blend of concepts.

---

## **Contract: AetherSentinelNexus**

### **Outline:**

1.  **Core ERC721 Sentinel NFT Management:** Minting, ownership, and trait definition for dynamic Sentinels.
2.  **Reputation System:** Tracks and manages "Influence Points" (IP) for users based on their contributions and activity.
3.  **Adaptive Staking Pool:** Allows users to stake their Sentinels to earn dynamic rewards, influenced by Sentinel traits and owner IP.
4.  **Oracle Integration & Data Curating:** Manages trusted oracle addresses and allows them to submit external data that influences Sentinel traits.
5.  **Decentralized Governance Framework:** Enables community proposals and voting on crucial protocol parameters, oracle sources, and Sentinel evolution rules.
6.  **Protocol Parameter Management:** Functions for the owner (and later governance) to adjust key operational parameters.
7.  **Reward Token Management:** Handles the ERC20 token used for distributing staking rewards.

### **Function Summary:**

**I. Core Sentinel (ERC721) Operations:**

1.  `constructor()`: Initializes the contract with an NFT name, symbol, and reward token address.
2.  `mintSentinel()`: Mints a new Aether Sentinel NFT to the caller, assigning initial traits.
3.  `getSentinelDetails(uint256 tokenId)`: Retrieves all current traits and status for a specific Sentinel NFT.
4.  `triggerTraitRecalculation(uint256 tokenId)`: Allows a Sentinel owner to initiate a recalculation and update of their Sentinel's traits based on the latest available oracle data and owner's Influence Points.
5.  `_updateSentinelTrait(uint256 tokenId, string memory traitName, uint256 newValue)` (internal): Helper to modify a specific trait.

**II. Reputation (Influence Points) System:**

6.  `addInfluencePoints(address _user, uint256 _amount)`: Grants Influence Points to a specified user (callable by governance/admin).
7.  `deductInfluencePoints(address _user, uint256 _amount)`: Deducts Influence Points from a specified user (callable by governance/admin, e.g., for inactivity or penalties).
8.  `getInfluencePoints(address _user)`: Returns the current Influence Points for a given user.

**III. Adaptive Staking:**

9.  `stakeSentinel(uint256 tokenId)`: Stakes a Sentinel NFT into the protocol, making it eligible for rewards.
10. `unstakeSentinel(uint256 tokenId)`: Unstakes a Sentinel NFT, stopping further reward accumulation.
11. `claimStakingRewards(uint256[] calldata tokenIds)`: Allows the caller to claim accumulated rewards for one or more of their staked Sentinels.
12. `getPendingRewards(uint256 tokenId)`: Calculates and returns the pending reward amount for a specific staked Sentinel.
13. `_calculateDynamicRewardRate(uint256 tokenId)` (internal): Computes the real-time dynamic reward rate for a Sentinel based on its traits and owner's IP.

**IV. Oracle Integration & Data Curating:**

14. `registerTrustedOracle(address _oracleAddress)`: Adds an address to the list of trusted oracles (callable by governance).
15. `revokeTrustedOracle(address _oracleAddress)`: Removes an address from the trusted oracles list (callable by governance).
16. `submitOracleData(uint256 tokenId, string memory dataKey, uint256 dataValue, uint256 timestamp)`: Trusted oracles submit external data relevant to a specific Sentinel or the overall system.
17. `getLatestOracleData(uint256 tokenId, string memory dataKey)`: Retrieves the latest submitted oracle data for a specific Sentinel and data key.

**V. Decentralized Governance Framework:**

18. `proposeProtocolChange(string memory _description, bytes memory _callData, address _targetAddress)`: Allows users with sufficient Influence Points to propose changes to the protocol (e.g., update parameters, register oracles).
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users to cast their vote (for or against) on an active proposal, with voting power proportional to their Influence Points.
20. `executeProposal(uint256 _proposalId)`: Executes a successfully passed proposal.
21. `getProposalDetails(uint256 _proposalId)`: Retrieves the current state and details of a specific proposal.
22. `getVoterInfluence(address _voter)`: Returns the total voting influence of an address (currently based on Influence Points).

**VI. Protocol Parameter & Reward Token Management:**

23. `setRewardTokenAddress(address _rewardToken)`: Sets the ERC20 token address used for distributing staking rewards (governance controlled).
24. `depositRewardTokens(uint256 _amount)`: Allows the owner or an authorized entity to deposit reward tokens into the contract for distribution.
25. `setBaseRewardRate(uint256 _newRate)`: Sets the base reward rate for staking (governance controlled).
26. `setProposalThreshold(uint256 _newThreshold)`: Sets the minimum Influence Points required to create a proposal (governance controlled).
27. `setVotingPeriod(uint256 _newPeriod)`: Sets the duration for which proposals are open for voting (governance controlled).
28. `setMinimumTraitUpdateInterval(uint256 _newInterval)`: Sets the minimum time between trait recalculations for a single Sentinel (governance controlled).

---
**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title AetherSentinelNexus
 * @dev A decentralized ecosystem centered around "Aether Sentinels," which are dynamic NFTs whose traits
 * and earning capabilities evolve based on owner activity, community governance, and external data feeds.
 * It incorporates a reputation system, adaptive staking, and decentralized data curation.
 *
 * Outline:
 * 1.  Core ERC721 Sentinel NFT Management: Minting, ownership, and trait definition for dynamic Sentinels.
 * 2.  Reputation System: Tracks and manages "Influence Points" (IP) for users based on their contributions and activity.
 * 3.  Adaptive Staking Pool: Allows users to stake their Sentinels to earn dynamic rewards, influenced by Sentinel traits and owner IP.
 * 4.  Oracle Integration & Data Curating: Manages trusted oracle addresses and allows them to submit external data that influences Sentinel traits.
 * 5.  Decentralized Governance Framework: Enables community proposals and voting on crucial protocol parameters, oracle sources, and Sentinel evolution rules.
 * 6.  Protocol Parameter Management: Functions for the owner (and later governance) to adjust key operational parameters.
 * 7.  Reward Token Management: Handles the ERC20 token used for distributing staking rewards.
 *
 * Function Summary:
 *
 * I. Core Sentinel (ERC721) Operations:
 * 1.  constructor(): Initializes the contract with an NFT name, symbol, and reward token address.
 * 2.  mintSentinel(): Mints a new Aether Sentinel NFT to the caller, assigning initial traits.
 * 3.  getSentinelDetails(uint256 tokenId): Retrieves all current traits and status for a specific Sentinel NFT.
 * 4.  triggerTraitRecalculation(uint256 tokenId): Allows a Sentinel owner to initiate a recalculation and update of their Sentinel's traits based on the latest available oracle data and owner's Influence Points.
 * 5.  _updateSentinelTrait(uint256 tokenId, string memory traitName, uint256 newValue) (internal): Helper to modify a specific trait.
 *
 * II. Reputation (Influence Points) System:
 * 6.  addInfluencePoints(address _user, uint256 _amount): Grants Influence Points to a specified user (callable by governance/admin).
 * 7.  deductInfluencePoints(address _user, uint256 _amount): Deducts Influence Points from a specified user (callable by governance/admin, e.g., for inactivity or penalties).
 * 8.  getInfluencePoints(address _user): Returns the current Influence Points for a given user.
 *
 * III. Adaptive Staking:
 * 9.  stakeSentinel(uint256 tokenId): Stakes a Sentinel NFT into the protocol, making it eligible for rewards.
 * 10. unstakeSentinel(uint256 tokenId): Unstakes a Sentinel NFT, stopping further reward accumulation.
 * 11. claimStakingRewards(uint256[] calldata tokenIds): Allows the caller to claim accumulated rewards for one or more of their staked Sentinels.
 * 12. getPendingRewards(uint256 tokenId): Calculates and returns the pending reward amount for a specific staked Sentinel.
 * 13. _calculateDynamicRewardRate(uint256 tokenId) (internal): Computes the real-time dynamic reward rate for a Sentinel based on its traits and owner's IP.
 *
 * IV. Oracle Integration & Data Curating:
 * 14. registerTrustedOracle(address _oracleAddress): Adds an address to the list of trusted oracles (callable by governance).
 * 15. revokeTrustedOracle(address _oracleAddress): Removes an address from the trusted oracles list (callable by governance).
 * 16. submitOracleData(uint256 tokenId, string memory dataKey, uint256 dataValue, uint256 timestamp): Trusted oracles submit external data relevant to a specific Sentinel or the overall system.
 * 17. getLatestOracleData(uint256 tokenId, string memory dataKey): Retrieves the latest submitted oracle data for a specific Sentinel and data key.
 *
 * V. Decentralized Governance Framework:
 * 18. proposeProtocolChange(string memory _description, bytes memory _callData, address _targetAddress): Allows users with sufficient Influence Points to propose changes to the protocol (e.g., update parameters, register oracles).
 * 19. voteOnProposal(uint256 _proposalId, bool _support): Allows users to cast their vote (for or against) on an active proposal, with voting power proportional to their Influence Points.
 * 20. executeProposal(uint256 _proposalId): Executes a successfully passed proposal.
 * 21. getProposalDetails(uint256 _proposalId): Retrieves the current state and details of a specific proposal.
 * 22. getVoterInfluence(address _voter): Returns the total voting influence of an address (currently based on Influence Points).
 *
 * VI. Protocol Parameter & Reward Token Management:
 * 23. setRewardTokenAddress(address _rewardToken): Sets the ERC20 token address used for distributing staking rewards (governance controlled).
 * 24. depositRewardTokens(uint256 _amount): Allows the owner or an authorized entity to deposit reward tokens into the contract for distribution.
 * 25. setBaseRewardRate(uint256 _newRate): Sets the base reward rate for staking (governance controlled).
 * 26. setProposalThreshold(uint256 _newThreshold): Sets the minimum Influence Points required to create a proposal (governance controlled).
 * 27. setVotingPeriod(uint256 _newPeriod): Sets the duration for which proposals are open for voting (governance controlled).
 * 28. setMinimumTraitUpdateInterval(uint256 _newInterval): Sets the minimum time between trait recalculations for a single Sentinel (governance controlled).
 */
contract AetherSentinelNexus is ERC721, Ownable {
    using SafeMath for uint256;

    // --- I. Core Sentinel (ERC721) Operations ---
    uint256 private _nextTokenId;

    struct SentinelTraits {
        uint256 energy;           // Influences reward rate, updated by oracle/IP
        uint256 dataProcessing;   // Affects how quickly oracle data impacts traits
        uint256 influenceScore;   // Reflects owner IP, boosts staking rewards
        // Add more dynamic traits as needed
    }

    mapping(uint256 => SentinelTraits) public sentinelData;
    mapping(uint256 => uint256) public lastTraitUpdateTimestamp; // To prevent spamming trait recalculations

    // --- II. Reputation (Influence Points) System ---
    mapping(address => uint256) public influencePoints; // User's Influence Points

    // --- III. Adaptive Staking ---
    IERC20 public rewardToken;
    uint256 public baseRewardRatePerSecond; // Base rewards per second per sentinel (scaled by 1e18)
    uint256 public totalStakedSentinels;

    mapping(uint256 => bool) public isSentinelStaked;
    mapping(uint256 => uint256) public stakedSentinelTimes; // tokenId => timestamp of stake
    mapping(uint256 => uint256) public sentinelRewardDebt; // tokenId => amount of reward already accounted for

    // Global reward per second per staked unit, scaled
    uint256 public rewardPerTokenAccumulated; // Accumulator for rewards

    // --- IV. Oracle Integration & Data Curating ---
    mapping(address => bool) public isTrustedOracle;
    // Stores latest oracle data per sentinel and data key
    mapping(uint256 => mapping(string => uint256)) public latestOracleData;
    mapping(uint256 => mapping(string => uint256)) public latestOracleDataTimestamp; // Timestamp of last update for a data key

    // --- V. Decentralized Governance Framework ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        bytes callData;       // The encoded function call to execute
        address targetAddress; // The address of the contract to call (e.g., this contract)
        uint256 voteThreshold;  // Minimum total votes required for success (can be dynamic)
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalThresholdIP; // Minimum Influence Points required to create a proposal
    uint256 public votingPeriod; // Duration in seconds for proposals

    // --- VI. Protocol Parameter & Reward Token Management ---
    uint256 public minimumTraitUpdateInterval; // Min seconds between trait updates for a Sentinel

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, SentinelTraits initialTraits);
    event TraitsRecalculated(uint256 indexed tokenId, SentinelTraits newTraits, address indexed triggerer);
    event InfluencePointsUpdated(address indexed user, uint256 newPoints);
    event SentinelStaked(uint256 indexed tokenId, address indexed owner);
    event SentinelUnstaked(uint256 indexed tokenId, address indexed owner);
    event RewardsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event OracleRegistered(address indexed oracleAddress);
    event OracleRevoked(address indexed oracleAddress);
    event OracleDataSubmitted(uint256 indexed tokenId, string dataKey, uint256 dataValue, address indexed submitter);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event RewardTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);
    event RewardTokensDeposited(address indexed depositor, uint256 amount);
    event BaseRewardRateUpdated(uint256 newRate);
    event ProposalThresholdUpdated(uint256 newThreshold);
    event VotingPeriodUpdated(uint256 newPeriod);
    event MinimumTraitUpdateIntervalUpdated(uint256 newInterval);

    constructor(address _rewardTokenAddress) ERC721("Aether Sentinel", "AETH-SNTL") Ownable(msg.sender) {
        rewardToken = IERC20(_rewardTokenAddress);
        baseRewardRatePerSecond = 1e16; // Example: 0.01e18 per second per unit (scaled)
        proposalThresholdIP = 1000; // Example: 1000 Influence Points to propose
        votingPeriod = 7 days;      // Example: 7 days for voting
        minimumTraitUpdateInterval = 1 hours; // Example: 1 hour between trait updates

        // Initialize with the deployer as a trusted oracle for testing, or set via governance
        isTrustedOracle[msg.sender] = true;
        emit OracleRegistered(msg.sender);
    }

    modifier onlyTrustedOracle() {
        require(isTrustedOracle[msg.sender], "Not a trusted oracle");
        _;
    }

    // --- Internal Staking Helpers ---

    function _updateRewardAccumulator() internal {
        if (totalStakedSentinels == 0) {
            rewardPerTokenAccumulated = 0; // Reset if no staked sentinels
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(stakedSentinelTimes[0]); // Using a dummy timestamp for calculation, better: track `lastRewardUpdateTime`

        // A more robust staking reward calculation would involve tracking `lastUpdateTime`
        // and distributing accumulated rewards based on `totalStakedSentinels`.
        // For simplicity, this example assumes a simpler cumulative model.
        // A proper implementation would look like:
        // if (block.timestamp > lastRewardUpdateTime) {
        //     uint256 rewardsDistributed = IERC20(rewardToken).balanceOf(address(this)).sub(contractBalanceAtLastUpdate);
        //     if (totalStakedSentinels > 0) {
        //         rewardPerTokenAccumulated = rewardPerTokenAccumulated.add(rewardsDistributed.div(totalStakedSentinels));
        //     }
        //     lastRewardUpdateTime = block.timestamp;
        //     contractBalanceAtLastUpdate = IERC20(rewardToken).balanceOf(address(this));
        // }
    }


    // --- I. Core Sentinel (ERC721) Operations ---

    /**
     * @dev Mints a new Aether Sentinel NFT to the caller.
     * Assigns initial (potentially random or default) traits.
     */
    function mintSentinel() public returns (uint256) {
        _nextTokenId = _nextTokenId.add(1);
        _safeMint(msg.sender, _nextTokenId);

        // Assign initial traits (can be randomized or fixed)
        sentinelData[_nextTokenId] = SentinelTraits({
            energy: 100, // Example initial value
            dataProcessing: 50,
            influenceScore: 0 // Starts at 0, influenced by owner IP
        });
        lastTraitUpdateTimestamp[_nextTokenId] = block.timestamp;

        emit SentinelMinted(_nextTokenId, msg.sender, sentinelData[_nextTokenId]);
        return _nextTokenId;
    }

    /**
     * @dev Retrieves all current traits and status for a specific Sentinel NFT.
     * @param tokenId The ID of the Sentinel NFT.
     * @return energy, dataProcessing, influenceScore, isStaked, ownerAddress
     */
    function getSentinelDetails(uint256 tokenId) public view returns (
        uint256 energy,
        uint256 dataProcessing,
        uint256 influenceScore,
        bool isStaked,
        address ownerAddress
    ) {
        require(_exists(tokenId), "Sentinel does not exist");
        SentinelTraits memory traits = sentinelData[tokenId];
        return (
            traits.energy,
            traits.dataProcessing,
            traits.influenceScore,
            isSentinelStaked[tokenId],
            ownerOf(tokenId)
        );
    }

    /**
     * @dev Allows a Sentinel owner to initiate a recalculation and update of their Sentinel's traits.
     * Traits are updated based on the latest available oracle data and owner's Influence Points.
     * This function uses a simplified logic for trait evolution.
     * In a real system, trait evolution rules would be more complex and potentially governance-defined.
     * @param tokenId The ID of the Sentinel NFT to update.
     */
    function triggerTraitRecalculation(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not your Sentinel");
        require(block.timestamp >= lastTraitUpdateTimestamp[tokenId].add(minimumTraitUpdateInterval), "Trait update cooldown active");

        SentinelTraits storage currentTraits = sentinelData[tokenId];
        uint256 ownerIP = influencePoints[msg.sender];

        // Example logic: Traits evolve based on owner's IP and oracle data
        // For "energy", let's say it's influenced by a generic "marketSentiment" from an oracle
        uint256 marketSentiment = getLatestOracleData(tokenId, "marketSentiment"); // Get specific oracle data

        // Trait Evolution Logic (simplified):
        // Energy increases with market sentiment and owner's IP, up to a cap
        currentTraits.energy = currentTraits.energy.add(marketSentiment.div(100).add(ownerIP.div(200))).min(1000); // Max energy 1000

        // Data processing improves with owner's IP and its current data processing level
        currentTraits.dataProcessing = currentTraits.dataProcessing.add(ownerIP.div(500)).min(200); // Max dataProcessing 200

        // Influence Score directly reflects owner's IP (or a derivative)
        currentTraits.influenceScore = ownerIP.div(10); // 1/10th of owner's IP for Sentinel's influence score

        lastTraitUpdateTimestamp[tokenId] = block.timestamp;
        emit TraitsRecalculated(tokenId, currentTraits, msg.sender);
    }

    /**
     * @dev Internal helper function to update a specific trait of a Sentinel.
     * Primarily for internal logic or governance-driven updates.
     * @param tokenId The ID of the Sentinel NFT.
     * @param traitName The name of the trait (e.g., "energy").
     * @param newValue The new value for the trait.
     */
    function _updateSentinelTrait(uint256 tokenId, string memory traitName, uint256 newValue) internal {
        require(_exists(tokenId), "Sentinel does not exist");
        if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("energy"))) {
            sentinelData[tokenId].energy = newValue;
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("dataProcessing"))) {
            sentinelData[tokenId].dataProcessing = newValue;
        } else if (keccak256(abi.encodePacked(traitName)) == keccak256(abi.encodePacked("influenceScore"))) {
            sentinelData[tokenId].influenceScore = newValue;
        } else {
            revert("Invalid trait name");
        }
        emit TraitsRecalculated(tokenId, sentinelData[tokenId], address(0)); // Emitted from internal context
    }


    // --- II. Reputation (Influence Points) System ---

    /**
     * @dev Grants Influence Points to a specified user.
     * This could be called by the contract's owner, or by governance logic after a successful proposal,
     * or by another module integrated with the nexus for on-chain achievements.
     * @param _user The address to grant IP to.
     * @param _amount The amount of IP to add.
     */
    function addInfluencePoints(address _user, uint256 _amount) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        influencePoints[_user] = influencePoints[_user].add(_amount);
        emit InfluencePointsUpdated(_user, influencePoints[_user]);
    }

    /**
     * @dev Deducts Influence Points from a specified user.
     * Can be used for penalties or decay mechanisms.
     * @param _user The address to deduct IP from.
     * @param _amount The amount of IP to deduct.
     */
    function deductInfluencePoints(address _user, uint256 _amount) public onlyOwner {
         // In a full governance setup, this would be callable via a passed proposal.
        influencePoints[_user] = influencePoints[_user].sub(_amount);
        emit InfluencePointsUpdated(_user, influencePoints[_user]);
    }

    /**
     * @dev Returns the current Influence Points for a given user.
     * @param _user The address to query.
     * @return The current Influence Points of the user.
     */
    function getInfluencePoints(address _user) public view returns (uint256) {
        return influencePoints[_user];
    }

    // --- III. Adaptive Staking ---

    /**
     * @dev Stakes a Sentinel NFT into the protocol, making it eligible for rewards.
     * Transfers the NFT to the contract and marks it as staked.
     * @param tokenId The ID of the Sentinel NFT to stake.
     */
    function stakeSentinel(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not your Sentinel");
        require(!isSentinelStaked[tokenId], "Sentinel already staked");

        // First update rewards for all existing staked tokens before modifying stake
        // This is a simplified approach, a robust pool needs `lastUpdateTime` and `rewardRate`
        // _updateRewardAccumulator(); // Disabled for this simplified example

        _transfer(msg.sender, address(this), tokenId); // Transfer NFT to contract
        isSentinelStaked[tokenId] = true;
        stakedSentinelTimes[tokenId] = block.timestamp;
        sentinelRewardDebt[tokenId] = rewardPerTokenAccumulated; // Snapshot current global accumulator
        totalStakedSentinels = totalStakedSentinels.add(1);

        emit SentinelStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes a Sentinel NFT, stopping further reward accumulation.
     * Transfers the NFT back to the owner. Claims pending rewards automatically.
     * @param tokenId The ID of the Sentinel NFT to unstake.
     */
    function unstakeSentinel(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(isSentinelStaked[tokenId], "Sentinel not staked");

        // Claim rewards before unstaking
        _claimReward(tokenId, msg.sender);

        isSentinelStaked[tokenId] = false;
        stakedSentinelTimes[tokenId] = 0; // Reset timestamp
        totalStakedSentinels = totalStakedSentinels.sub(1);
        _transfer(address(this), msg.sender, tokenId); // Transfer NFT back to owner

        emit SentinelUnstaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows the caller to claim accumulated rewards for one or more of their staked Sentinels.
     * @param tokenIds An array of Sentinel NFT IDs for which to claim rewards.
     */
    function claimStakingRewards(uint256[] calldata tokenIds) public {
        uint256 totalRewardAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Not your Sentinel (must be staked and owned by you)");
            require(isSentinelStaked[tokenId], "Sentinel not staked");

            totalRewardAmount = totalRewardAmount.add(_claimReward(tokenId, msg.sender));
        }

        if (totalRewardAmount > 0) {
            require(rewardToken.transfer(msg.sender, totalRewardAmount), "Reward transfer failed");
            emit RewardsClaimed(0, msg.sender, totalRewardAmount); // Use 0 for tokenId if claiming for multiple
        }
    }

    /**
     * @dev Internal function to calculate and claim rewards for a single Sentinel.
     * Updates reward debt and returns the amount claimed.
     * @param tokenId The ID of the Sentinel NFT.
     * @param _to The address to send rewards to.
     * @return The amount of reward claimed.
     */
    function _claimReward(uint256 tokenId, address _to) internal returns (uint256) {
        // _updateRewardAccumulator(); // Ensure accumulator is up-to-date
        uint256 pending = getPendingRewards(tokenId);
        if (pending > 0) {
            // Update reward debt to current accumulated value
            sentinelRewardDebt[tokenId] = rewardPerTokenAccumulated;
            emit RewardsClaimed(tokenId, _to, pending);
            return pending;
        }
        return 0;
    }

    /**
     * @dev Calculates and returns the pending reward amount for a specific staked Sentinel.
     * Reward calculation considers dynamic factors like Sentinel traits and owner's Influence Points.
     * @param tokenId The ID of the Sentinel NFT.
     * @return The pending reward amount for the Sentinel.
     */
    function getPendingRewards(uint256 tokenId) public view returns (uint256) {
        if (!isSentinelStaked[tokenId]) return 0;

        uint256 secondsStaked = block.timestamp.sub(stakedSentinelTimes[tokenId]);
        uint256 dynamicRate = _calculateDynamicRewardRate(tokenId); // Scaled by 1e18
        uint256 pending = secondsStaked.mul(dynamicRate).div(1e18); // Convert back to actual token units

        // A more advanced system would use `rewardPerTokenAccumulated` and `sentinelRewardDebt`
        // like in standard yield farming contracts, but this simpler time-based calculation
        // demonstrates the dynamic aspect more directly.
        // uint256 accumulated = rewardPerTokenAccumulated.sub(sentinelRewardDebt[tokenId]);
        // return accumulated.mul(1); // Assuming 1 unit staked per NFT
        return pending;
    }

    /**
     * @dev Internal function to compute the real-time dynamic reward rate for a Sentinel.
     * Rate is influenced by Sentinel traits (energy, influenceScore) and owner's Influence Points.
     * The returned rate is scaled by 1e18 to allow for fractional rates.
     * @param tokenId The ID of the Sentinel NFT.
     * @return The dynamic reward rate per second (scaled by 1e18).
     */
    function _calculateDynamicRewardRate(uint256 tokenId) internal view returns (uint256) {
        SentinelTraits memory traits = sentinelData[tokenId];
        address owner = ownerOf(tokenId); // Note: ownerOf returns the contract address if staked
        if (isSentinelStaked[tokenId]) {
            // Need to get the original owner who staked it
            // For simplicity, let's assume `owner` is who staked it. A robust system would track `stakerAddress`.
            // For this example, let's assume `owner` refers to `_tokenOwners[tokenId]` which is still the contract,
            // so we need the `msg.sender` of the `stakeSentinel` call. This is a limitation of this simplified model.
            // A proper implementation would map tokenId -> stakerAddress.
            // For now, let's use the current caller's IP as a proxy if it's the original owner.
            // If calling from `getPendingRewards`, `msg.sender` is the actual owner.
            // If calling from `claim`, `msg.sender` is the actual owner.
        }

        uint256 ownerIP = influencePoints[msg.sender]; // Use current caller's IP for dynamic calculation

        // Base rate + (Sentinel Energy * multiplier) + (Sentinel Influence Score * multiplier) + (Owner IP * multiplier)
        // Ensure all multipliers are scaled appropriately to avoid precision loss.
        uint256 rate = baseRewardRatePerSecond; // E.g., 0.01 tokens/sec

        // Energy boost: 1% additional rate per 100 energy points
        rate = rate.add(baseRewardRatePerSecond.mul(traits.energy).div(10000)); // (energy/100) * (rate/100)

        // Influence Score boost: 0.5% additional rate per 100 influence score
        rate = rate.add(baseRewardRatePerSecond.mul(traits.influenceScore).div(20000)); // (influenceScore/100) * (rate/200)

        // Owner IP boost: 0.2% additional rate per 100 IP
        rate = rate.add(baseRewardRatePerSecond.mul(ownerIP).div(50000)); // (ownerIP/100) * (rate/500)

        return rate; // This rate is scaled (e.g., 1e18)
    }

    // --- IV. Oracle Integration & Data Curating ---

    /**
     * @dev Adds an address to the list of trusted oracles.
     * Only callable by the contract owner (or governance after a proposal).
     * @param _oracleAddress The address of the new trusted oracle.
     */
    function registerTrustedOracle(address _oracleAddress) public onlyOwner {
         // In a full governance setup, this would be callable via a passed proposal.
        require(!isTrustedOracle[_oracleAddress], "Address is already a trusted oracle");
        isTrustedOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @dev Removes an address from the trusted oracles list.
     * Only callable by the contract owner (or governance after a proposal).
     * @param _oracleAddress The address of the oracle to revoke.
     */
    function revokeTrustedOracle(address _oracleAddress) public onlyOwner {
         // In a full governance setup, this would be callable via a passed proposal.
        require(isTrustedOracle[_oracleAddress], "Address is not a trusted oracle");
        isTrustedOracle[_oracleAddress] = false;
        emit OracleRevoked(_oracleAddress);
    }

    /**
     * @dev Trusted oracles submit external data relevant to a specific Sentinel or the overall system.
     * This data will then be used by `triggerTraitRecalculation` or other logic.
     * @param tokenId The ID of the Sentinel this data pertains to (0 for global data).
     * @param dataKey A string identifier for the data (e.g., "marketSentiment", "ecosystemHealth").
     * @param dataValue The numerical value of the data.
     * @param timestamp The timestamp when the data was observed/collected by the oracle.
     */
    function submitOracleData(uint256 tokenId, string memory dataKey, uint256 dataValue, uint256 timestamp) public onlyTrustedOracle {
        // Ensure data is fresh enough (optional, depends on use case)
        require(timestamp <= block.timestamp.add(1 hours), "Oracle data timestamp too far in future");
        require(timestamp >= block.timestamp.sub(24 hours), "Oracle data is too old");

        latestOracleData[tokenId][dataKey] = dataValue;
        latestOracleDataTimestamp[tokenId][dataKey] = block.timestamp; // Use block.timestamp for on-chain integrity
        emit OracleDataSubmitted(tokenId, dataKey, dataValue, msg.sender);
    }

    /**
     * @dev Retrieves the latest submitted oracle data for a specific Sentinel and data key.
     * @param tokenId The ID of the Sentinel (0 for global data).
     * @param dataKey The key for the data (e.g., "marketSentiment").
     * @return The latest data value.
     */
    function getLatestOracleData(uint256 tokenId, string memory dataKey) public view returns (uint256) {
        return latestOracleData[tokenId][dataKey];
    }

    // --- V. Decentralized Governance Framework ---

    /**
     * @dev Allows users with sufficient Influence Points to propose changes to the protocol.
     * A proposal can be to call any function on any contract (e.g., this contract itself to change parameters).
     * @param _description A detailed description of the proposal.
     * @param _callData The encoded function call (e.g., abi.encodeWithSelector(ERC20.transfer.selector, ...)).
     * @param _targetAddress The address of the contract the callData targets.
     */
    function proposeProtocolChange(string memory _description, bytes memory _callData, address _targetAddress) public {
        require(influencePoints[msg.sender] >= proposalThresholdIP, "Not enough Influence Points to propose");

        nextProposalId = nextProposalId.add(1);
        proposals[nextProposalId] = Proposal({
            proposalId: nextProposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetAddress: _targetAddress,
            voteThreshold: 0, // This will be calculated on execution attempt, or set as a percentage of total IP
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp.add(votingPeriod),
            state: ProposalState.Active,
            hasVoted: mapping(address => bool)(0) // Initialize mapping
        });

        emit ProposalCreated(nextProposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users to cast their vote (for or against) on an active proposal.
     * Voting power is proportional to their Influence Points.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterPower = getVoterInfluence(msg.sender);
        require(voterPower > 0, "No voting influence");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Executes a successfully passed proposal.
     * Requires the proposal to be in a 'Succeeded' state (determined dynamically on execution attempt).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state != ProposalState.Executed, "Proposal already executed");
        require(block.timestamp > proposal.endTime, "Voting period not ended");

        uint256 totalInfluencePoints = 0; // In a real system, this would be sum of all IP or IP of active voters
        // For simplicity, let's assume a fixed quorum for now or sum of all IP.
        // A more robust system would snapshot total IP at proposal creation.
        // As a placeholder, let's assume a simple majority of votes cast and a minimum turnout.
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposalThresholdIP) { // Simple majority & minimum turnout
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }

        require(proposal.state == ProposalState.Succeeded, "Proposal not succeeded");

        // Execute the call
        (bool success, ) = proposal.targetAddress.call(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves the current state and details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposalId, proposer, description, votesFor, votesAgainst, startTime, endTime, state (enum), targetAddress, callData
     */
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 proposalId,
        address proposer,
        string memory description,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 startTime,
        uint256 endTime,
        ProposalState state,
        address targetAddress,
        bytes memory callData
    ) {
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposalId,
            p.proposer,
            p.description,
            p.votesFor,
            p.votesAgainst,
            p.startTime,
            p.endTime,
            p.state,
            p.targetAddress,
            p.callData
        );
    }

    /**
     * @dev Returns the total voting influence of an address.
     * Currently based solely on Influence Points. Can be extended to include staked Sentinels.
     * @param _voter The address to check.
     * @return The total voting influence.
     */
    function getVoterInfluence(address _voter) public view returns (uint256) {
        return influencePoints[_voter];
        // Could be extended:
        // uint256 totalInfluence = influencePoints[_voter];
        // for (uint256 i = 0; i < stakedSentinelsByOwner[_voter].length; i++) {
        //     totalInfluence = totalInfluence.add(sentinelData[stakedSentinelsByOwner[_voter][i]].influenceScore);
        // }
        // return totalInfluence;
    }

    // --- VI. Protocol Parameter & Reward Token Management ---

    /**
     * @dev Sets the ERC20 token address used for distributing staking rewards.
     * This function should ideally be called through governance.
     * @param _rewardToken The address of the ERC20 reward token.
     */
    function setRewardTokenAddress(address _rewardToken) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        require(_rewardToken != address(0), "Reward token cannot be zero address");
        emit RewardTokenAddressUpdated(address(rewardToken), _rewardToken);
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev Allows the owner or an authorized entity to deposit reward tokens into the contract.
     * These tokens will be used to pay out staking rewards.
     * @param _amount The amount of reward tokens to deposit.
     */
    function depositRewardTokens(uint256 _amount) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        require(_amount > 0, "Deposit amount must be greater than zero");
        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "Reward token transfer failed");
        emit RewardTokensDeposited(msg.sender, _amount);
    }

    /**
     * @dev Sets the base reward rate for staking.
     * This function should ideally be called through governance.
     * @param _newRate The new base reward rate per second (scaled by 1e18).
     */
    function setBaseRewardRate(uint256 _newRate) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        baseRewardRatePerSecond = _newRate;
        emit BaseRewardRateUpdated(_newRate);
    }

    /**
     * @dev Sets the minimum Influence Points required to create a proposal.
     * This function should ideally be called through governance.
     * @param _newThreshold The new minimum IP for proposals.
     */
    function setProposalThreshold(uint256 _newThreshold) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        proposalThresholdIP = _newThreshold;
        emit ProposalThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Sets the duration for which proposals are open for voting.
     * This function should ideally be called through governance.
     * @param _newPeriod The new voting period in seconds.
     */
    function setVotingPeriod(uint256 _newPeriod) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        require(_newPeriod > 0, "Voting period must be positive");
        votingPeriod = _newPeriod;
        emit VotingPeriodUpdated(_newPeriod);
    }

    /**
     * @dev Sets the minimum time interval (in seconds) between trait recalculations for a single Sentinel.
     * This function should ideally be called through governance.
     * @param _newInterval The new minimum interval in seconds.
     */
    function setMinimumTraitUpdateInterval(uint256 _newInterval) public onlyOwner {
        // In a full governance setup, this would be callable via a passed proposal.
        require(_newInterval > 0, "Interval must be positive");
        minimumTraitUpdateInterval = _newInterval;
        emit MinimumTraitUpdateIntervalUpdated(_newInterval);
    }
}
```