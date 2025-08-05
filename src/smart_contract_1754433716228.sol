This is an ambitious and exciting request! To create something truly unique and advanced, we'll design a contract around the concept of "Dynamic, Reputational, and Curated Digital Assets" – let's call them **"Aether Shards"**.

This contract will combine elements of:
1.  **Dynamic NFTs:** Shards evolve based on user actions, time, and external data.
2.  **Reputation System:** User "Insight" score influences success rates and unlocks abilities.
3.  **DAO-like Curation:** Community proposes and votes on new "Shard Blueprints" (templates).
4.  **Gamified Mechanics:** Forging, refining, mutating, and questing.
5.  **Oracle Integration (Simulated/Placeholder):** External "Global Pulse" influences outcomes.
6.  **Soul-Bound & Tradable Dual Nature:** Shards can be bound to a wallet for reputation, or unbound for trade.
7.  **Economic Sink/Utility:** An associated ERC-20 "Essence" token used for operations and staking.

---

## **Elysian Forge: Aether Shard Protocol**

### **Outline & Function Summary**

**I. Core Setup & Administration**
*   `constructor()`: Initializes the contract with an admin, links to an Essence token, and sets initial parameters.
*   `pauseContract()`: Allows the owner to pause the contract for upgrades or emergencies.
*   `unpauseContract()`: Allows the owner to unpause the contract.
*   `setOracleAddress(address _newOracle)`: Sets the address of the trusted oracle.
*   `updateEssenceContract(address _newEssenceAddress)`: Updates the linked Essence token contract address.
*   `setBlueprintVoteThreshold(uint256 _newThreshold)`: Sets the minimum votes required for a blueprint to pass.

**II. Essence Token Integration (IERC20)**
*   `stakeEssence(uint256 _amount)`: Allows users to stake Essence tokens to earn potential rewards or boost reputation.
*   `unstakeEssence(uint256 _amount)`: Allows users to unstake their Essence tokens after a cool-down period.
*   `claimEssenceRewards()`: Allows stakers to claim accumulated Essence rewards.

**III. Aether Shard Management (ERC721 Extension)**
*   `forgeNewShard(uint256 _blueprintId)`: Mints a new Aether Shard based on an approved blueprint. Success chance is tied to Insight and Global Pulse.
*   `mutateShard(uint256 _shardId, bytes32 _mutationType)`: Evolves a Shard by changing some of its properties, potentially consuming Essence. Outcome influenced by Insight and Shard properties.
*   `refineShard(uint256 _shardId)`: Improves a Shard's base properties (e.g., power level) at a cost, with probabilistic success.
*   `bindShardToSoul(uint256 _shardId)`: Makes a Shard soul-bound to the current owner, granting Insight boosts but preventing transfer.
*   `unbindShard(uint256 _shardId)`: Makes a soul-bound Shard tradable again, requiring a significant Essence cost and potentially reducing Insight.
*   `getShardProperties(uint256 _shardId)`: Returns all properties of a specific Aether Shard.
*   `_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`: Internal ERC721 hook to enforce soul-bound restrictions. (Inherited & overridden)

**IV. Reputation & Insight System**
*   `getInsightScore(address _user)`: Returns the current Insight score of a user.
*   `earnInsight(address _user, uint256 _amount)`: Internal function to award Insight points.
*   `deductInsight(address _user, uint256 _amount)`: Internal function to deduct Insight points.

**V. Blueprint Curation & Governance**
*   `proposeShardBlueprint(string memory _name, string memory _description, bytes32[] memory _initialTraits)`: Allows users to propose new Aether Shard templates. Requires staked Essence.
*   `voteOnBlueprint(uint256 _blueprintId, bool _support)`: Allows staked Essence holders to vote for or against a proposed blueprint.
*   `executeBlueprintProposal(uint256 _blueprintId)`: Executes a passed blueprint proposal, making it available for forging.

**VI. Oracle Integration & Dynamic Traits**
*   `fulfillGlobalPulse(bytes32 _pulseHash)`: Callback function for the trusted oracle to update the global "pulse" data.
*   `triggerShardEvent(uint256 _shardId, bytes32 _eventType)`: A function (potentially permissioned to an oracle or admin) to trigger specific events for a Shard, affecting its properties based on external data.

**VII. Quest & Challenge System**
*   `initiateQuest(string memory _questName, uint256 _rewardShardBlueprintId, uint256 _essenceReward, uint256 _deadline)`: Admin function to initiate a new quest or challenge.
*   `completeQuest(uint256 _questId, bytes32 _proof)`: Allows users to claim quest rewards upon providing on-chain proof (e.g., hash of actions, oracle verified).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces for potential external contracts (e.g., Chainlink VRF/Functions)
interface IOracle {
    function requestData(bytes32 key, uint256 callbackId) external returns (bytes32 requestId);
}

contract ElysianForge is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // --- Events ---
    event EssenceStaked(address indexed user, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 amount);
    event EssenceRewardsClaimed(address indexed user, uint256 amount);
    event ShardForged(address indexed owner, uint256 indexed shardId, uint256 blueprintId, bytes32 initialTrait);
    event ShardMutated(uint256 indexed shardId, bytes32 indexed mutationType, bool success, bytes32 newTrait);
    event ShardRefined(uint256 indexed shardId, bool success, uint256 newPowerLevel);
    event ShardBoundToSoul(uint256 indexed shardId, address indexed owner);
    event ShardUnbound(uint256 indexed shardId, address indexed owner);
    event InsightEarned(address indexed user, uint256 amount, string reason);
    event InsightDeducted(address indexed user, uint256 amount, string reason);
    event BlueprintProposed(uint256 indexed blueprintId, address indexed proposer, string name);
    event VoteCast(uint256 indexed blueprintId, address indexed voter, bool support);
    event BlueprintExecuted(uint256 indexed blueprintId, string name);
    event GlobalPulseUpdated(bytes32 indexed oldPulse, bytes32 indexed newPulse);
    event ShardEventTriggered(uint256 indexed shardId, bytes32 indexed eventType);
    event QuestInitiated(uint256 indexed questId, string questName, uint256 deadline);
    event QuestCompleted(uint256 indexed questId, address indexed completer);

    // --- Structs ---

    struct AetherShardProperties {
        uint256 blueprintId;
        uint256 powerLevel; // Can be refined
        bytes32 primaryTrait; // Can be mutated
        bytes32 secondaryTrait; // Can be mutated
        uint256 forgedTimestamp;
        uint256 lastMutationTimestamp;
        // Add more dynamic properties as needed
    }

    struct BlueprintProposal {
        string name;
        string description;
        bytes32[] initialTraits; // Traits a shard forged from this blueprint could have
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposerStake; // Essence staked by proposer
        address proposer;
        bool executed;
        bool exists; // To check if blueprintId is valid
    }

    struct Quest {
        string name;
        uint256 rewardShardBlueprintId; // If quest rewards a specific shard type
        uint256 essenceReward;
        uint256 deadline;
        bool active;
    }

    // --- State Variables ---

    IERC20 public essenceToken;
    address public oracleAddress; // Trusted address for oracle callbacks

    uint256 private _nextTokenId; // Counter for unique Aether Shard IDs
    uint256 private _nextBlueprintId; // Counter for unique Blueprint IDs
    uint256 private _nextQuestId; // Counter for unique Quest IDs

    mapping(uint256 => AetherShardProperties) public aetherShards;
    mapping(uint256 => bool) public isShardBoundToSoul; // True if soul-bound, cannot be transferred
    mapping(address => uint256) public insightScores; // User reputation score
    mapping(address => uint256) public stakedEssence; // Essence staked by user

    uint256 public constant ESSENCE_STAKE_FOR_PROPOSAL = 1000 * (10**18); // Example: 1000 Essence
    uint256 public blueprintVoteThreshold = 50 * (10**18); // Example: 50 staked Essence votes
    uint256 public essenceUnstakeCooldown = 7 days; // Cooldown period for unstaking
    mapping(address => uint256) public lastUnstakeRequestTime;

    mapping(uint256 => BlueprintProposal) public blueprintProposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedOnBlueprint; // blueprintId => voter => voted

    bytes32 public latestGlobalPulseHash; // Represents external market/environmental data from oracle
    uint256 public immutable GLOBAL_PULSE_VALIDITY_PERIOD = 1 days; // How long a pulse is considered 'fresh'
    uint256 public lastGlobalPulseUpdate;

    mapping(uint256 => Quest) public quests;
    mapping(uint256 => mapping(address => bool)) public hasCompletedQuest; // questId => user => completed

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the trusted oracle");
        _;
    }

    modifier onlyStaker() {
        require(stakedEssence[msg.sender] > 0, "Must have staked Essence to perform this action");
        _;
    }

    modifier onlyIfPulseFresh() {
        require(block.timestamp <= lastGlobalPulseUpdate + GLOBAL_PULSE_VALIDITY_PERIOD, "Global Pulse is stale, needs update");
        _;
    }

    // --- Constructor ---

    constructor(address _essenceTokenAddress, address _oracleAddress) ERC721("Aether Shard", "ASHARD") Ownable(msg.sender) Pausable() {
        require(_essenceTokenAddress != address(0), "Essence token address cannot be zero");
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        essenceToken = IERC20(_essenceTokenAddress);
        oracleAddress = _oracleAddress;
        _nextTokenId = 0;
        _nextBlueprintId = 0;
        _nextQuestId = 0;
        lastGlobalPulseUpdate = block.timestamp; // Initialize pulse as fresh
        latestGlobalPulseHash = keccak256(abi.encodePacked("initial_pulse", block.timestamp)); // Initial dummy pulse
    }

    // --- I. Core Setup & Administration ---

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function setOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    function updateEssenceContract(address _newEssenceAddress) public onlyOwner {
        require(_newEssenceAddress != address(0), "New Essence token address cannot be zero");
        essenceToken = IERC20(_newEssenceAddress);
    }

    function setBlueprintVoteThreshold(uint256 _newThreshold) public onlyOwner {
        require(_newThreshold > 0, "Threshold must be greater than zero");
        blueprintVoteThreshold = _newThreshold;
    }

    // --- II. Essence Token Integration ---

    function stakeEssence(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "Amount to stake must be positive");
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "Essence transfer failed");
        stakedEssence[msg.sender] += _amount;
        // Optionally, earn Insight for staking
        earnInsight(msg.sender, _amount / (10**18), "Staking Essence"); // 1 Insight per 1 Essence staked for example
        emit EssenceStaked(msg.sender, _amount);
    }

    function unstakeEssence(uint256 _amount) public whenNotPaused nonReentrant {
        require(_amount > 0, "Amount to unstake must be positive");
        require(stakedEssence[msg.sender] >= _amount, "Not enough staked Essence");
        
        uint256 availableTime = lastUnstakeRequestTime[msg.sender] + essenceUnstakeCooldown;
        if (lastUnstakeRequestTime[msg.sender] != 0 && block.timestamp < availableTime) {
             revert("Unstake cooldown in progress");
        }
        
        stakedEssence[msg.sender] -= _amount;
        require(essenceToken.transfer(msg.sender, _amount), "Essence transfer failed");
        lastUnstakeRequestTime[msg.sender] = block.timestamp; // Reset cooldown
        deductInsight(msg.sender, _amount / (10**18) / 2, "Unstaking Essence"); // Small Insight deduction for unstaking
        emit EssenceUnstaked(msg.sender, _amount);
    }

    function claimEssenceRewards() public whenNotPaused nonReentrant {
        // This is a placeholder for a more complex reward distribution system (e.g., based on staking duration, pool share)
        // For simplicity, let's assume a tiny passive reward based on time staked or a global pool.
        // In a real system, you'd calculate accrued rewards.
        uint256 rewards = (stakedEssence[msg.sender] / (10**18)) * 10 * (block.timestamp - lastGlobalPulseUpdate) / 1 days; // Example: 10 Essence per day per 1 staked Essence
        if (rewards > 0) {
            require(essenceToken.transfer(msg.sender, rewards), "Essence reward transfer failed");
            emit EssenceRewardsClaimed(msg.sender, rewards);
        } else {
            revert("No rewards to claim");
        }
    }

    // --- III. Aether Shard Management (ERC721 Extension) ---

    function forgeNewShard(uint256 _blueprintId) public whenNotPaused nonReentrant onlyIfPulseFresh returns (uint256) {
        BlueprintProposal storage blueprint = blueprintProposals[_blueprintId];
        require(blueprint.exists, "Blueprint does not exist");
        require(blueprint.executed, "Blueprint has not been executed");
        require(blueprint.initialTraits.length > 0, "Blueprint has no initial traits defined");

        // Cost to forge (e.g., 50 Essence)
        uint256 forgeCost = 50 * (10**18);
        require(essenceToken.transferFrom(msg.sender, address(this), forgeCost), "Essence payment for forging failed");

        // Probabilistic success chance based on Insight and Global Pulse
        uint256 insightBonus = insightScores[msg.sender] / 100; // 1% bonus per 100 Insight
        uint256 globalPulseInfluence = uint256(latestGlobalPulseHash) % 50; // 0-49% bonus/penalty
        uint256 successChance = 50 + insightBonus + globalPulseInfluence; // Base 50% + bonuses

        // Use a pseudo-random number based on block details for outcome
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextTokenId))) % 100;

        uint256 newShardId = _nextTokenId++;

        if (randomNumber < successChance) {
            // Success! Mint a new Shard
            _safeMint(msg.sender, newShardId);
            
            bytes32 chosenTrait = blueprint.initialTraits[newShardId % blueprint.initialTraits.length]; // Simple trait selection

            aetherShards[newShardId] = AetherShardProperties({
                blueprintId: _blueprintId,
                powerLevel: 100, // Initial power level
                primaryTrait: chosenTrait,
                secondaryTrait: bytes32(0), // No secondary trait initially
                forgedTimestamp: block.timestamp,
                lastMutationTimestamp: 0
            });
            isShardBoundToSoul[newShardId] = true; // Forged shards are soul-bound by default

            earnInsight(msg.sender, 50, "Successfully forged Aether Shard");
            emit ShardForged(msg.sender, newShardId, _blueprintId, chosenTrait);
            return newShardId;
        } else {
            // Failure! Return the Essence (or only a portion) but no Shard
            essenceToken.transfer(msg.sender, forgeCost / 2); // Return half cost on failure
            deductInsight(msg.sender, 20, "Failed to forge Aether Shard");
            revert("Forging failed: Critical energies dispersed!");
        }
    }

    function mutateShard(uint256 _shardId, bytes32 _mutationType) public whenNotPaused nonReentrant onlyIfPulseFresh {
        require(_exists(_shardId), "Shard does not exist");
        require(ownerOf(_shardId) == msg.sender, "Caller does not own this Shard");
        require(!isShardBoundToSoul[_shardId], "Soul-bound shards cannot be mutated directly, must unbind first."); // Example restriction

        AetherShardProperties storage shard = aetherShards[_shardId];

        uint256 mutateCost = 100 * (10**18);
        require(essenceToken.transferFrom(msg.sender, address(this), mutateCost), "Essence payment for mutation failed");

        uint256 insightBonus = insightScores[msg.sender] / 50; // 2% bonus per 100 Insight
        uint256 globalPulseInfluence = uint256(latestGlobalPulseHash) % 30; // 0-29% bonus
        uint256 successChance = 60 + insightBonus + globalPulseInfluence;

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, _shardId, msg.sender, _mutationType))) % 100;

        bool success = false;
        bytes32 newTrait = shard.primaryTrait; // Default to old trait

        if (randomNumber < successChance) {
            // Success! Mutate a trait
            if (_mutationType == keccak256(abi.encodePacked("ELEMENTAL"))) {
                newTrait = keccak256(abi.encodePacked("FIRE", randomNumber)); // Example new trait
            } else if (_mutationType == keccak256(abi.encodePacked("COSMIC"))) {
                newTrait = keccak256(abi.encodePacked("STAR", shard.powerLevel)); // Example new trait
            } else {
                revert("Invalid mutation type");
            }
            shard.primaryTrait = newTrait;
            shard.lastMutationTimestamp = block.timestamp;
            earnInsight(msg.sender, 75, "Successfully mutated Aether Shard");
            success = true;
        } else {
            // Failure! Refund some Essence
            essenceToken.transfer(msg.sender, mutateCost / 3); // Refund 1/3 on failure
            deductInsight(msg.sender, 30, "Failed to mutate Aether Shard");
        }
        emit ShardMutated(_shardId, _mutationType, success, newTrait);
    }

    function refineShard(uint256 _shardId) public whenNotPaused nonReentrant {
        require(_exists(_shardId), "Shard does not exist");
        require(ownerOf(_shardId) == msg.sender, "Caller does not own this Shard");

        AetherShardProperties storage shard = aetherShards[_shardId];

        uint256 refineCost = 75 * (10**18);
        require(essenceToken.transferFrom(msg.sender, address(this), refineCost), "Essence payment for refinement failed");

        uint256 insightBonus = insightScores[msg.sender] / 75;
        uint256 successChance = 70 + insightBonus; // Higher base chance for refinement

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, _shardId, msg.sender))) % 100;

        uint256 oldPowerLevel = shard.powerLevel;
        uint256 newPowerLevel = oldPowerLevel;
        bool success = false;

        if (randomNumber < successChance) {
            newPowerLevel = oldPowerLevel + (randomNumber % 10 + 1); // Increase power by 1-10
            shard.powerLevel = newPowerLevel;
            earnInsight(msg.sender, 25, "Successfully refined Aether Shard");
            success = true;
        } else {
            // No power change on failure, but Essence is still consumed
            deductInsight(msg.sender, 10, "Failed to refine Aether Shard");
        }
        emit ShardRefined(_shardId, success, newPowerLevel);
    }

    function bindShardToSoul(uint256 _shardId) public whenNotPaused {
        require(_exists(_shardId), "Shard does not exist");
        require(ownerOf(_shardId) == msg.sender, "Caller does not own this Shard");
        require(!isShardBoundToSoul[_shardId], "Shard is already soul-bound");

        isShardBoundToSoul[_shardId] = true;
        earnInsight(msg.sender, 100, "Bound Aether Shard to Soul");
        emit ShardBoundToSoul(_shardId, msg.sender);
    }

    function unbindShard(uint256 _shardId) public whenNotPaused nonReentrant {
        require(_exists(_shardId), "Shard does not exist");
        require(ownerOf(_shardId) == msg.sender, "Caller does not own this Shard");
        require(isShardBoundToSoul[_shardId], "Shard is not soul-bound");

        // Cost to unbind (e.g., 200 Essence)
        uint256 unbindCost = 200 * (10**18);
        require(essenceToken.transferFrom(msg.sender, address(this), unbindCost), "Essence payment for unbinding failed");

        isShardBoundToSoul[_shardId] = false;
        deductInsight(msg.sender, 50, "Unbound Aether Shard"); // Deduct Insight for unbinding
        emit ShardUnbound(_shardId, msg.sender);
    }

    function getShardProperties(uint256 _shardId) public view returns (uint256 blueprintId, uint256 powerLevel, bytes32 primaryTrait, bytes32 secondaryTrait, uint256 forgedTimestamp, uint256 lastMutationTimestamp, bool isSoulBound) {
        AetherShardProperties storage shard = aetherShards[_shardId];
        return (shard.blueprintId, shard.powerLevel, shard.primaryTrait, shard.secondaryTrait, shard.forgedTimestamp, shard.lastMutationTimestamp, isShardBoundToSoul[_shardId]);
    }

    // Override internal ERC721 transfer function to enforce soul-bound restriction
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Call parent
        if (from != address(0) && to != address(0)) { // Only check for actual transfers, not minting/burning
            if (isShardBoundToSoul[tokenId]) {
                revert("Cannot transfer a soul-bound Aether Shard.");
            }
        }
    }

    // --- IV. Reputation & Insight System ---

    function getInsightScore(address _user) public view returns (uint256) {
        return insightScores[_user];
    }

    function earnInsight(address _user, uint256 _amount, string memory _reason) internal {
        if (_user == address(0)) return;
        insightScores[_user] += _amount;
        emit InsightEarned(_user, _amount, _reason);
    }

    function deductInsight(address _user, uint256 _amount, string memory _reason) internal {
        if (_user == address(0)) return;
        if (insightScores[_user] < _amount) {
            insightScores[_user] = 0;
        } else {
            insightScores[_user] -= _amount;
        }
        emit InsightDeducted(_user, _amount, _reason);
    }

    // --- V. Blueprint Curation & Governance ---

    function proposeShardBlueprint(string memory _name, string memory _description, bytes32[] memory _initialTraits) public whenNotPaused nonReentrant onlyStaker returns (uint256) {
        require(bytes(_name).length > 0, "Blueprint name cannot be empty");
        require(_initialTraits.length > 0, "Blueprint must have at least one initial trait");
        require(stakedEssence[msg.sender] >= ESSENCE_STAKE_FOR_PROPOSAL, "Not enough staked Essence to propose");

        uint256 blueprintId = _nextBlueprintId++;
        blueprintProposals[blueprintId] = BlueprintProposal({
            name: _name,
            description: _description,
            initialTraits: _initialTraits,
            votesFor: stakedEssence[msg.sender], // Proposer's stake counts as a vote
            votesAgainst: 0,
            proposerStake: ESSENCE_STAKE_FOR_PROPOSAL,
            proposer: msg.sender,
            executed: false,
            exists: true
        });

        // Lock proposer's stake
        // This stake needs to be held until proposal passes/fails, then refunded or used
        // For simplicity, we just record it, a real system might use a separate escrow
        // For now, we assume this is just for reputation, not actual locked funds for this specific proposal.
        // It's effectively 'burned' from the general staking pool, or requires a dedicated mechanism.
        // Let's assume it's just a check for now, and the stake is managed by 'stakeEssence'
        
        // Deduct proposal cost from proposer's staked Essence
        stakedEssence[msg.sender] -= ESSENCE_STAKE_FOR_PROPOSAL;

        emit BlueprintProposed(blueprintId, msg.sender, _name);
        return blueprintId;
    }

    function voteOnBlueprint(uint256 _blueprintId, bool _support) public whenNotPaused nonReentrant onlyStaker {
        BlueprintProposal storage blueprint = blueprintProposals[_blueprintId];
        require(blueprint.exists, "Blueprint does not exist");
        require(!blueprint.executed, "Blueprint has already been executed");
        require(!hasVotedOnBlueprint[_blueprintId][msg.sender], "Already voted on this blueprint");

        uint256 voterStake = stakedEssence[msg.sender];
        require(voterStake > 0, "Voter must have staked Essence");

        if (_support) {
            blueprint.votesFor += voterStake;
            earnInsight(msg.sender, voterStake / (10**18) / 10, "Voted for Blueprint"); // Earn Insight for voting
        } else {
            blueprint.votesAgainst += voterStake;
            deductInsight(msg.sender, voterStake / (10**18) / 20, "Voted against Blueprint (less Insight)");
        }

        hasVotedOnBlueprint[_blueprintId][msg.sender] = true;
        emit VoteCast(_blueprintId, msg.sender, _support);
    }

    function executeBlueprintProposal(uint256 _blueprintId) public whenNotPaused nonReentrant {
        BlueprintProposal storage blueprint = blueprintProposals[_blueprintId];
        require(blueprint.exists, "Blueprint does not exist");
        require(!blueprint.executed, "Blueprint has already been executed");

        // Check if the proposal has passed the threshold and has more 'for' votes
        require(blueprint.votesFor >= blueprintVoteThreshold, "Proposal did not meet vote threshold");
        require(blueprint.votesFor > blueprint.votesAgainst, "Proposal has more 'against' votes or equal");

        blueprint.executed = true;
        // Refund proposer's stake (if it was locked beyond general staking)
        // For now, it was simply deducted, so no refund of the specific proposal stake here.
        // The general staking pool is still there.

        earnInsight(blueprint.proposer, 500, "Blueprint successfully executed"); // Big Insight for proposer
        emit BlueprintExecuted(_blueprintId, blueprint.name);
    }

    function getBlueprintDetails(uint256 _blueprintId) public view returns (string memory name, string memory description, bytes32[] memory initialTraits, uint256 votesFor, uint256 votesAgainst, address proposer, bool executed) {
        BlueprintProposal storage blueprint = blueprintProposals[_blueprintId];
        require(blueprint.exists, "Blueprint does not exist");
        return (blueprint.name, blueprint.description, blueprint.initialTraits, blueprint.votesFor, blueprint.votesAgainst, blueprint.proposer, blueprint.executed);
    }

    // --- VI. Oracle Integration & Dynamic Traits ---

    function fulfillGlobalPulse(bytes32 _pulseHash) public onlyOracle {
        bytes32 oldPulse = latestGlobalPulseHash;
        latestGlobalPulseHash = _pulseHash;
        lastGlobalPulseUpdate = block.timestamp;
        emit GlobalPulseUpdated(oldPulse, _pulseHash);
    }

    // Example of a function that could be triggered by an Oracle or Admin for dynamic changes
    function triggerShardEvent(uint256 _shardId, bytes32 _eventType) public whenNotPaused onlyOracle {
        require(_exists(_shardId), "Shard does not exist");
        AetherShardProperties storage shard = aetherShards[_shardId];

        if (_eventType == keccak256(abi.encodePacked("COSMIC_ALIGNMENT"))) {
            // Boost power level for cosmic alignment
            shard.powerLevel += 50;
            // Maybe change a trait based on the latest global pulse
            shard.secondaryTrait = bytes32(uint256(latestGlobalPulseHash) % 2 == 0 ? keccak256(abi.encodePacked("ALIGNMENT_POSITIVE")) : keccak256(abi.encodePacked("ALIGNMENT_NEGATIVE")));
            emit ShardEventTriggered(_shardId, _eventType);
        } else if (_eventType == keccak256(abi.encodePacked("ANTI_MATTER_FLUX"))) {
            // Decrease power level
            shard.powerLevel = shard.powerLevel > 20 ? shard.powerLevel - 20 : 0;
            emit ShardEventTriggered(_shardId, _eventType);
        } else {
            revert("Unknown event type");
        }
    }


    // --- VII. Quest & Challenge System ---

    function initiateQuest(string memory _questName, uint256 _rewardShardBlueprintId, uint256 _essenceReward, uint256 _deadline) public onlyOwner {
        require(bytes(_questName).length > 0, "Quest name cannot be empty");
        if (_rewardShardBlueprintId != 0) {
            require(blueprintProposals[_rewardShardBlueprintId].exists && blueprintProposals[_rewardShardBlueprintId].executed, "Reward blueprint must exist and be executed");
        }
        require(_deadline > block.timestamp, "Quest deadline must be in the future");

        uint256 questId = _nextQuestId++;
        quests[questId] = Quest({
            name: _questName,
            rewardShardBlueprintId: _rewardShardBlueprintId,
            essenceReward: _essenceReward,
            deadline: _deadline,
            active: true
        });
        emit QuestInitiated(questId, _questName, _deadline);
    }

    function completeQuest(uint256 _questId, bytes32 _proof) public whenNotPaused nonReentrant {
        Quest storage quest = quests[_questId];
        require(quest.active, "Quest is not active");
        require(block.timestamp <= quest.deadline, "Quest has expired");
        require(!hasCompletedQuest[_questId][msg.sender], "Quest already completed by this user");

        // This is where you'd implement actual on-chain proof verification or oracle call for complex quests.
        // For demonstration, let's just use a simple proof hash that passes if it matches a secret.
        // In a real dApp, _proof could be a transaction hash, an oracle callback, or a game state commitment.
        bytes32 requiredProof = keccak256(abi.encodePacked("SECRET_QUEST_PROOF_PHRASE", quest.name, msg.sender));
        require(_proof == requiredProof, "Invalid quest completion proof"); // Highly simplified!

        hasCompletedQuest[_questId][msg.sender] = true;

        // Distribute rewards
        if (quest.essenceReward > 0) {
            require(essenceToken.transfer(msg.sender, quest.essenceReward), "Failed to transfer quest Essence reward");
        }
        if (quest.rewardShardBlueprintId != 0) {
            uint256 newShardId = _nextTokenId++;
            _safeMint(msg.sender, newShardId);
            bytes32 chosenTrait = blueprintProposals[quest.rewardShardBlueprintId].initialTraits[newShardId % blueprintProposals[quest.rewardShardBlueprintId].initialTraits.length];
            aetherShards[newShardId] = AetherShardProperties({
                blueprintId: quest.rewardShardBlueprintId,
                powerLevel: 200, // Higher power for quest rewards
                primaryTrait: chosenTrait,
                secondaryTrait: keccak256(abi.encodePacked("QUEST_REWARD")),
                forgedTimestamp: block.timestamp,
                lastMutationTimestamp: 0
            });
            isShardBoundToSoul[newShardId] = true; // Quest rewards are soul-bound
            emit ShardForged(msg.sender, newShardId, quest.rewardShardBlueprintId, chosenTrait);
        }

        earnInsight(msg.sender, 200, "Completed Quest");
        emit QuestCompleted(_questId, msg.sender);
    }

    // --- Utility Views ---

    function getUserStakedEssence(address _user) public view returns (uint256) {
        return stakedEssence[_user];
    }

    function getLatestGlobalPulse() public view returns (bytes32, uint256) {
        return (latestGlobalPulseHash, lastGlobalPulseUpdate);
    }

    function getBlueprintCount() public view returns (uint256) {
        return _nextBlueprintId;
    }

    function getShardCount() public view returns (uint256) {
        return _nextTokenId;
    }

    function getQuestDetails(uint256 _questId) public view returns (string memory name, uint256 rewardBlueprintId, uint256 essenceReward, uint256 deadline, bool active) {
        Quest storage quest = quests[_questId];
        require(quest.active, "Quest does not exist or is inactive"); // Re-purpose 'active' to also mean 'exists' for simplicity here
        return (quest.name, quest.rewardShardBlueprintId, quest.essenceReward, quest.deadline, quest.active);
    }
}
```