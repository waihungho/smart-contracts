Here's a smart contract in Solidity called "Aetherial Genesis". It introduces a dynamic NFT ecosystem where digital entities ("Aetherial Shards") can evolve, bond, and be influenced by a community-governed environment. The contract uses an associated utility token ("Genesis Energy") for interactions, governance, and rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary:
//
// AetherialGenesis: A Dynamic NFT Ecosystem with Adaptive Evolution and Community-Driven Influence.
// This contract introduces "Aetherial Shards" (ERC-721 NFTs) that possess a unique 'DNA' but
// can dynamically evolve their properties and visual representation over time and through
// user interaction. Their evolution is influenced by global "Environmental Parameters" that can be
// collectively governed by "Genesis Energy" (ERC-20 utility token) holders through a mini-DAO.
//
// I. Core Architecture & Interfaces:
//    - Inherits ERC721Enumerable for Aetherial Shard NFTs, enabling iteration over tokens.
//    - Inherits ERC20 for Genesis Energy utility token, serving as the ecosystem's currency.
//    - Inherits Ownable for administrative control over core parameters and initial token distribution.
//
// II. Aetherial Shard (NFT) Management:
//    1.  mintInitialShard(string memory _initialMetadataURI): Mints a new Aetherial Shard NFT to the caller,
//        requiring Genesis Energy tokens as a minting fee. The shard starts at stage 0.
//    2.  evolveShard(uint256 _tokenId): Triggers the evolution of a specific shard to its next stage
//        if sufficient nourishment, time delay, and environmental conditions are met.
//    3.  bondShards(uint256 _shardId1, uint256 _shardId2): Allows two unbonded Aetherial Shards to
//        form a synergistic bond, requiring a Genesis Energy fee. The bond provides benefits but
//        also introduces specific interaction rules.
//    4.  unbondShards(uint256 _shardId1, uint256 _shardId2): Dissolves an existing bond between two shards,
//        which can only be initiated by the "parent" shard's owner and costs Genesis Energy.
//    5.  getCurrentShardMetadataURI(uint256 _tokenId): Retrieves the dynamic metadata URI for a given shard,
//        which changes based on its current evolution stage. This is the implementation for ERC721's `tokenURI`.
//    6.  getShardProperties(uint256 _tokenId): Returns comprehensive immutable (DNA) and dynamic (stage, nourishment)
//        properties of a shard.
//    7.  burnShard(uint256 _tokenId): Allows a shard owner to permanently destroy their shard,
//        receiving a Genesis Energy reward from the contract's treasury.
//
// III. Genesis Energy (Utility Token) Management:
//    8.  distributeGenesisEnergy(address _to, uint256 _amount): Owner-only function to mint and
//        distribute Genesis Energy tokens, primarily for initial supply or specific rewards.
//    9.  nourishShard(uint256 _tokenId, uint256 _amountGE): Spends Genesis Energy tokens to
//        "nourish" a shard, accumulating internal "nourishment points" required for evolution.
//    10. stakeGenesisEnergyForVoting(uint256 _amount): Locks Genesis Energy tokens in the contract
//        to gain voting power for environmental proposals.
//    11. unstakeGenesisEnergy(uint256 _amount): Unlocks previously staked Genesis Energy tokens,
//        returning them to the owner.
//    12. claimEvolutionReward(uint256 _tokenId): Allows a shard owner to claim a one-time Genesis Energy
//        reward for reaching a specific evolution stage, preventing multiple claims for the same stage.
//
// IV. Evolution & Environmental Parameters (Community Governance):
//    13. updateCoreEvolutionParameters(string memory _paramName, uint256 _value): Owner-only function
//        to adjust fundamental evolution parameters like mint costs, nourishment rates, or bonding fees.
//    14. submitEnvironmentalProposal(string memory _parameterName, uint256 _newValue, uint256 _votingDuration):
//        Allows users with staked Genesis Energy to propose changes to global environmental parameters,
//        which influence shard evolution and ecosystem dynamics.
//    15. voteOnEnvironmentalProposal(uint256 _proposalId, bool _support): Allows staked Genesis Energy
//        holders to cast their votes (Yea/Nay) on active environmental proposals.
//    16. executeEnvironmentalProposal(uint256 _proposalId): Executes a proposal that has met its
//        quorum and majority requirements after the voting period ends, applying the proposed environmental change.
//
// V. Query & State Functions:
//    17. getEnvironmentalParameter(string memory _parameterName): Retrieves the current value of a
//        specified global environmental parameter.
//    18. getProposalDetails(uint256 _proposalId): Returns detailed information about a specific
//        environmental proposal, including its voting results and status.
//    19. getTotalStakedEnergy(): Returns the total amount of Genesis Energy currently staked across all users.
//    20. getShardEvolutionHistory(uint256 _tokenId): Returns a chronological list of timestamps
//        when a given shard successfully evolved to a new stage.
//    21. getPendingShardNourishment(uint256 _tokenId): Returns the current accumulated nourishment points
//        for a specific shard that are pending for its next evolution.
//    22. getShardBondStatus(uint256 _tokenId): Returns the bonding status of a shard, indicating if it's
//        bonded, with which shard, and if it's the parent of the bond.

contract AetherialGenesis is ERC721Enumerable, ERC20, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- NFT (Aetherial Shard) State ---
    Counters.Counter private _tokenIdCounter;

    struct AetherialShardData {
        uint256 dnaHash;             // Immutable base properties, determines initial traits
        uint256 lastEvolveTime;      // Timestamp of last successful evolution
        uint256 accumulatedNourishment; // GE-points accumulated for next evolution
        uint8 currentEvolutionStage; // Current evolution stage, 0 = initial
        uint256 bondedToShardId;     // 0 if not bonded, otherwise the ID of the bonded shard
        bool isBondedParent;         // True if this shard initiated the bond (for unbonding logic)
        string baseMetadataURI;      // Base URI for this specific shard's metadata (e.g., IPFS CID)
        uint256 creationTime;        // Timestamp of shard creation
    }

    mapping(uint256 => AetherialShardData) public shards;
    mapping(uint256 => uint256[]) public shardEvolutionHistory; // tokenId => list of timestamps for each evolution
    mapping(uint256 => mapping(uint8 => bool)) public claimedEvolutionStageRewards; // tokenId => stage => claimed?

    // --- Genesis Energy (GE) State ---
    mapping(address => uint256) public stakedGenesisEnergy;
    uint256 public totalStakedGenesisEnergy;

    // --- Evolution & Environmental Parameters ---
    struct EvolutionParameters {
        uint256 initialMintCostGE;              // Cost in GE to mint a new shard
        uint256 nourishCostPerPointGE;          // GE cost per nourishment point
        uint256[] evolutionNourishmentThresholds; // Nourishment needed for stages 1, 2, 3...
        uint256[] evolutionTimeDelays;          // Min time (seconds) between evolutions for stages 1, 2, 3...
        uint256 bondCostGE;                     // Cost in GE to bond two shards
        uint256 unbondCostGE;                   // Cost in GE to unbond two shards
        uint256 burnRewardGE;                   // GE reward for burning a shard
        uint256 evolutionRewardAmountGE;        // Base GE reward for completing an evolution stage
    }
    EvolutionParameters public evoParams;

    struct EnvironmentalParameter {
        string name;
        uint256 value; // Represents a factor (e.g., 100 for 100%, 50 for 50%)
        uint256 lastUpdated;
    }
    mapping(string => EnvironmentalParameter) public environmentalParameters;

    // --- Community Governance (Proposals) ---
    Counters.Counter private _proposalIdCounter;

    struct Proposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yeas;
        uint256 nays;
        bool executed;
        address proposer;
        mapping(address => bool) hasVoted; // Prevents double voting by a single address
    }
    mapping(uint256 => Proposal) public proposals;

    // --- Events ---
    event ShardMinted(uint256 indexed tokenId, address indexed owner, uint256 dnaHash);
    event ShardEvolved(uint256 indexed tokenId, uint8 newStage, uint256 timestamp);
    event ShardsBonded(uint256 indexed shardId1, uint256 indexed shardId2, address indexed initiator);
    event ShardsUnbonded(uint256 indexed shardId1, uint256 indexed shardId2);
    event ShardNourished(uint256 indexed tokenId, address indexed nourisher, uint256 amountGE, uint256 newNourishment);
    event GenesisEnergyStaked(address indexed staker, uint256 amount);
    event GenesisEnergyUnstaked(address indexed staker, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, string indexed parameterName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, string indexed parameterName, uint256 newValue);
    event EvolutionRewardClaimed(uint256 indexed tokenId, address indexed owner, uint256 amountGE, uint8 stage);
    event ShardBurned(uint256 indexed tokenId, address indexed burner, uint256 rewardGE);
    event EvolutionParameterUpdated(string indexed paramName, uint256 newValue);


    // --- Constructor ---
    /// @param _name The name for the Aetherial Shard NFT collection (e.g., "Aetherial Shards").
    /// @param _symbol The symbol for the Aetherial Shard NFT collection (e.g., "AES").
    /// @param _genesisEnergyName The name for the Genesis Energy token (e.g., "Genesis Energy").
    /// @param _genesisEnergySymbol The symbol for the Genesis Energy token (e.g., "GE").
    /// @param _initialOwner The initial owner address for the contract, receiving Ownable permissions.
    constructor(string memory _name, string memory _symbol, string memory _genesisEnergyName, string memory _genesisEnergySymbol, address _initialOwner)
        ERC721(_name, _symbol)
        ERC20(_genesisEnergyName, _genesisEnergySymbol)
        Ownable(_initialOwner)
    {
        // Initial evolution parameters (example values, can be adjusted by owner later)
        // Values are scaled by 10^decimals for Genesis Energy.
        evoParams.initialMintCostGE = 100 * (10 ** decimals()); // 100 GE
        evoParams.nourishCostPerPointGE = 1 * (10 ** decimals()); // 1 GE per nourishment point
        // Example thresholds for stages 1, 2, 3, 4
        evoParams.evolutionNourishmentThresholds = [200, 500, 1000, 2000];
        // Example min time delays (in seconds) for stages 1, 2, 3, 4
        evoParams.evolutionTimeDelays = [1 days, 3 days, 7 days, 14 days];
        evoParams.bondCostGE = 50 * (10 ** decimals());
        evoParams.unbondCostGE = 20 * (10 ** decimals());
        evoParams.burnRewardGE = 50 * (10 ** decimals());
        evoParams.evolutionRewardAmountGE = 25 * (10 ** decimals()); // 25 GE reward per evolution stage claimed

        // Initial environmental parameters (example values, can be changed by community governance)
        // Factors like 100 = 100% (neutral), 50 = 50% (halving effect), 200 = 200% (doubling effect)
        environmentalParameters["GlobalGrowthFactor"] = EnvironmentalParameter("GlobalGrowthFactor", 100, block.timestamp);
        environmentalParameters["ResilienceFactor"] = EnvironmentalParameter("ResilienceFactor", 100, block.timestamp);
        environmentalParameters["BondSynergyBoost"] = EnvironmentalParameter("BondSynergyBoost", 10, block.timestamp); // e.g., 10% boost for bonded shards
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /// @dev Generates a pseudo-random DNA hash for a new shard.
    ///      For a real-world application, consider Chainlink VRF or similar for stronger randomness.
    function _generateDnaHash() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _tokenIdCounter.current())));
    }

    // --- II. Aetherial Shard (NFT) Management ---

    /// @notice Mints a new Aetherial Shard NFT to the caller. Requires `initialMintCostGE` GE tokens.
    ///         The `_initialMetadataURI` serves as the base for the shard's dynamic metadata.
    /// @param _initialMetadataURI The base IPFS CID or URL for the shard's metadata files.
    function mintInitialShard(string memory _initialMetadataURI) public {
        require(balanceOf(msg.sender) >= evoParams.initialMintCostGE, "AG: Insufficient Genesis Energy for minting");
        // Transfer mint cost from caller to the contract treasury
        require(transfer(address(this), evoParams.initialMintCostGE), "AG: Failed to transfer mint cost");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        uint256 dna = _generateDnaHash();

        _safeMint(msg.sender, newTokenId);

        shards[newTokenId] = AetherialShardData({
            dnaHash: dna,
            lastEvolveTime: block.timestamp,
            accumulatedNourishment: 0,
            currentEvolutionStage: 0, // Starts at stage 0 (un-evolved)
            bondedToShardId: 0,
            isBondedParent: false,
            baseMetadataURI: _initialMetadataURI,
            creationTime: block.timestamp
        });

        emit ShardMinted(newTokenId, msg.sender, dna);
    }

    /// @notice Triggers the evolution of a specific shard to its next stage.
    ///         Requires the shard to have sufficient nourishment points and passed the required time delay.
    ///         Environmental parameters can implicitly affect evolution by changing thresholds via governance.
    /// @param _tokenId The ID of the Aetherial Shard to evolve.
    function evolveShard(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AG: Not owner or approved");
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");
        require(shard.currentEvolutionStage < evoParams.evolutionNourishmentThresholds.length, "AG: Shard is at max evolution stage");

        uint8 nextStage = shard.currentEvolutionStage + 1;
        uint256 requiredNourishment = evoParams.evolutionNourishmentThresholds[nextStage - 1];
        uint256 requiredTimeDelay = evoParams.evolutionTimeDelays[nextStage - 1];

        // Apply environmental factors (e.g., GlobalGrowthFactor could reduce required nourishment)
        uint256 growthFactor = environmentalParameters["GlobalGrowthFactor"].value; // e.g., 100 = 100%
        // If growthFactor is 200, required nourishment could be halved; if 50, it could be doubled.
        // For simplicity here, we'll assume it's a direct multiplier on cost or speed.
        // `requiredNourishment = requiredNourishment * 100 / growthFactor;` -- but this is a *cost*, so growth factor should reduce cost
        requiredNourishment = (requiredNourishment * 100) / growthFactor;


        require(shard.accumulatedNourishment >= requiredNourishment, "AG: Insufficient nourishment for evolution");
        require(block.timestamp >= shard.lastEvolveTime + requiredTimeDelay, "AG: Not enough time has passed since last evolution");

        shard.accumulatedNourishment -= requiredNourishment; // Consume nourishment points
        shard.currentEvolutionStage = nextStage;
        shard.lastEvolveTime = block.timestamp;

        shardEvolutionHistory[_tokenId].push(block.timestamp); // Record evolution event timestamp

        emit ShardEvolved(_tokenId, nextStage, block.timestamp);
    }

    /// @notice Allows two shards to be bonded together, creating a unique synergistic state.
    ///         Requires both shards to be unbonded and the caller to pay a GE fee.
    /// @param _shardId1 The ID of the first shard.
    /// @param _shardId2 The ID of the second shard.
    function bondShards(uint256 _shardId1, uint256 _shardId2) public {
        require(_shardId1 != _shardId2, "AG: Cannot bond a shard with itself");
        require(ownerOf(_shardId1) == msg.sender || ownerOf(_shardId2) == msg.sender, "AG: Caller must own at least one shard involved in the bond");

        // Ensure both shards exist and are not already bonded
        require(shards[_shardId1].dnaHash != 0, "AG: Shard 1 does not exist");
        require(shards[_shardId2].dnaHash != 0, "AG: Shard 2 does not exist");
        require(shards[_shardId1].bondedToShardId == 0, "AG: Shard 1 is already bonded");
        require(shards[_shardId2].bondedToShardId == 0, "AG: Shard 2 is already bonded");

        // Transfer bonding cost from caller to contract
        require(balanceOf(msg.sender) >= evoParams.bondCostGE, "AG: Insufficient Genesis Energy for bonding");
        require(transfer(address(this), evoParams.bondCostGE), "AG: Failed to transfer bond cost");

        // Establish the bi-directional bond and designate a parent
        shards[_shardId1].bondedToShardId = _shardId2;
        shards[_shardId2].bondedToShardId = _shardId1;
        shards[_shardId1].isBondedParent = true; // Designate _shardId1 as the parent for unbonding logic

        emit ShardsBonded(_shardId1, _shardId2, msg.sender);
    }

    /// @notice Dissolves an existing bond between two shards. Only the "parent" shard's owner can initiate.
    ///         Requires a Genesis Energy fee.
    /// @param _shardId1 The ID of the parent shard in the bond.
    /// @param _shardId2 The ID of the child shard in the bond.
    function unbondShards(uint256 _shardId1, uint256 _shardId2) public {
        require(_isApprovedOrOwner(msg.sender, _shardId1), "AG: Not owner or approved of parent shard");
        require(shards[_shardId1].bondedToShardId == _shardId2 && shards[_shardId2].bondedToShardId == _shardId1, "AG: Shards are not bonded to each other");
        require(shards[_shardId1].isBondedParent, "AG: Only the parent shard can initiate unbonding");

        // Transfer unbonding cost from caller to contract
        require(balanceOf(msg.sender) >= evoParams.unbondCostGE, "AG: Insufficient Genesis Energy for unbonding");
        require(transfer(address(this), evoParams.unbondCostGE), "AG: Failed to transfer unbond cost");

        // Break the bond
        shards[_shardId1].bondedToShardId = 0;
        shards[_shardId2].bondedToShardId = 0;
        shards[_shardId1].isBondedParent = false;

        emit ShardsUnbonded(_shardId1, _shardId2);
    }

    /// @notice Retrieves the current, dynamic metadata URI for a given shard.
    ///         The URI changes based on the shard's evolution stage, allowing for evolving visuals/data.
    /// @param _tokenId The ID of the Aetherial Shard.
    /// @return The full metadata URI for the shard's current state.
    function getCurrentShardMetadataURI(uint256 _tokenId) public view returns (string memory) {
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");

        // Example: ipfs://QmbF6tQ3vJ.../[dna_segment]/stage_[stage_number].json
        // This structure allows metadata to dynamically reflect evolution.
        // The baseMetadataURI can be unique per shard, and then the stage is appended.
        return string(abi.encodePacked(shard.baseMetadataURI, "/", shard.currentEvolutionStage.toString(), ".json"));
    }

    /// @notice Returns both immutable (DNA) and current dynamic properties of a shard.
    /// @param _tokenId The ID of the Aetherial Shard.
    /// @return dnaHash, lastEvolveTime, accumulatedNourishment, currentEvolutionStage, bondedToShardId, isBondedParent, creationTime.
    function getShardProperties(uint256 _tokenId)
        public
        view
        returns (
            uint256 dnaHash,
            uint256 lastEvolveTime,
            uint256 accumulatedNourishment,
            uint8 currentEvolutionStage,
            uint256 bondedToShardId,
            bool isBondedParent,
            uint256 creationTime
        )
    {
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");

        return (
            shard.dnaHash,
            shard.lastEvolveTime,
            shard.accumulatedNourishment,
            shard.currentEvolutionStage,
            shard.bondedToShardId,
            shard.isBondedParent,
            shard.creationTime
        );
    }

    /// @notice Allows a shard owner to permanently destroy their shard, receiving a GE reward.
    ///         Cannot burn a bonded shard; must unbond first.
    /// @param _tokenId The ID of the Aetherial Shard to burn.
    function burnShard(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AG: Not owner or approved");
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");
        require(shard.bondedToShardId == 0, "AG: Cannot burn a bonded shard. Unbond first.");

        // Transfer reward from contract treasury to burner
        require(balanceOf(address(this)) >= evoParams.burnRewardGE, "AG: Not enough GE in contract for reward");
        require(transfer(msg.sender, evoParams.burnRewardGE), "AG: Failed to transfer burn reward");

        _burn(_tokenId); // ERC721 internal burn function
        delete shards[_tokenId]; // Remove shard data
        delete shardEvolutionHistory[_tokenId]; // Clear evolution history
        // All claimedEvolutionStageRewards for this shard will effectively be inaccessible

        emit ShardBurned(_tokenId, msg.sender, evoParams.burnRewardGE);
    }

    // Override tokenURI to use dynamic metadata specific to AetherialGenesis
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getCurrentShardMetadataURI(_tokenId);
    }

    // --- III. Genesis Energy (Utility Token) Management ---

    /// @notice Owner function to mint and distribute Genesis Energy tokens to a specified address.
    /// @param _to The address to mint tokens to.
    /// @param _amount The amount of Genesis Energy tokens to mint.
    function distributeGenesisEnergy(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /// @notice Spends Genesis Energy tokens to "nourish" a shard, accumulating internal energy for its next evolution.
    ///         The amount of nourishment points gained is determined by `nourishCostPerPointGE`.
    /// @param _tokenId The ID of the Aetherial Shard to nourish.
    /// @param _amountGE The amount of Genesis Energy to spend.
    function nourishShard(uint256 _tokenId, uint256 _amountGE) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AG: Not owner or approved");
        require(_amountGE > 0, "AG: Nourishment amount must be positive");
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");

        uint256 actualNourishmentPoints = _amountGE / evoParams.nourishCostPerPointGE;
        require(actualNourishmentPoints > 0, "AG: Amount too small for any nourishment point");

        // Transfer GE from nourisher to contract treasury
        require(balanceOf(msg.sender) >= _amountGE, "AG: Insufficient Genesis Energy");
        require(transfer(address(this), _amountGE), "AG: Failed to transfer nourishment cost");

        shard.accumulatedNourishment += actualNourishmentPoints;

        emit ShardNourished(_tokenId, msg.sender, _amountGE, shard.accumulatedNourishment);
    }

    /// @notice Locks Genesis Energy tokens in the contract to gain voting power for environmental proposals.
    /// @param _amount The amount of Genesis Energy tokens to stake.
    function stakeGenesisEnergyForVoting(uint256 _amount) public {
        require(_amount > 0, "AG: Stake amount must be positive");
        require(balanceOf(msg.sender) >= _amount, "AG: Insufficient Genesis Energy to stake");

        // Transfer GE from staker to contract treasury
        require(transfer(address(this), _amount), "AG: Failed to transfer stake amount");

        stakedGenesisEnergy[msg.sender] += _amount;
        totalStakedGenesisEnergy += _amount;

        emit GenesisEnergyStaked(msg.sender, _amount);
    }

    /// @notice Unlocks previously staked Genesis Energy tokens, returning them to the owner.
    /// @param _amount The amount of Genesis Energy tokens to unstake.
    function unstakeGenesisEnergy(uint256 _amount) public {
        require(_amount > 0, "AG: Unstake amount must be positive");
        require(stakedGenesisEnergy[msg.sender] >= _amount, "AG: Not enough staked Genesis Energy");

        stakedGenesisEnergy[msg.sender] -= _amount;
        totalStakedGenesisEnergy -= _amount;

        // Transfer GE from contract treasury back to staker
        require(transfer(msg.sender, _amount), "AG: Failed to transfer unstake amount");

        emit GenesisEnergyUnstaked(msg.sender, _amount);
    }

    /// @notice Allows a shard owner to claim a one-time Genesis Energy reward for reaching a specific evolution stage.
    ///         Prevents multiple claims for the same stage.
    /// @param _tokenId The ID of the Aetherial Shard.
    function claimEvolutionReward(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "AG: Not owner or approved");
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");
        require(shard.currentEvolutionStage > 0, "AG: Shard has not evolved yet to earn a reward");
        require(!claimedEvolutionStageRewards[_tokenId][shard.currentEvolutionStage], "AG: Reward for this evolution stage already claimed");

        uint256 rewardAmount = evoParams.evolutionRewardAmountGE;

        require(balanceOf(address(this)) >= rewardAmount, "AG: Not enough GE in contract for reward");
        require(transfer(msg.sender, rewardAmount), "AG: Failed to transfer evolution reward");

        claimedEvolutionStageRewards[_tokenId][shard.currentEvolutionStage] = true;

        emit EvolutionRewardClaimed(_tokenId, msg.sender, rewardAmount, shard.currentEvolutionStage);
    }

    // --- IV. Evolution & Environmental Parameters (Community Governance) ---

    /// @notice Owner function to adjust core evolution parameters. This allows the game's economy and progression
    ///         to be fine-tuned.
    /// @param _paramName The string identifier of the parameter to update (e.g., "initialMintCostGE").
    /// @param _value The new value for the specified parameter.
    function updateCoreEvolutionParameters(string memory _paramName, uint256 _value) public onlyOwner {
        // Using keccak256 for string comparison to avoid storage issues with dynamic strings.
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("initialMintCostGE"))) {
            evoParams.initialMintCostGE = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("nourishCostPerPointGE"))) {
            evoParams.nourishCostPerPointGE = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("bondCostGE"))) {
            evoParams.bondCostGE = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("unbondCostGE"))) {
            evoParams.unbondCostGE = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("burnRewardGE"))) {
            evoParams.burnRewardGE = _value;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("evolutionRewardAmountGE"))) {
            evoParams.evolutionRewardAmountGE = _value;
        }
        // For array parameters like `evolutionNourishmentThresholds`, dedicated setter functions would be needed
        // to handle array modifications (e.g., addStageThreshold, updateStageThreshold).
        else {
            revert("AG: Invalid evolution parameter name or unsupported for direct update");
        }
        emit EvolutionParameterUpdated(_paramName, _value);
    }

    /// @notice Allows a user with staked Genesis Energy to propose a change to a global environmental parameter.
    ///         These parameters influence the overall ecosystem and shard evolution dynamics.
    /// @param _parameterName The name of the environmental parameter to change (must exist).
    /// @param _newValue The new value proposed for the parameter.
    /// @param _votingDuration The duration for which the proposal will be open for voting (in seconds).
    function submitEnvironmentalProposal(string memory _parameterName, uint256 _newValue, uint256 _votingDuration) public {
        require(stakedGenesisEnergy[msg.sender] > 0, "AG: Must have staked Genesis Energy to submit a proposal");
        require(_votingDuration > 0, "AG: Voting duration must be positive");
        require(environmentalParameters[_parameterName].name != "", "AG: Parameter does not exist for proposing");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.parameterName = _parameterName;
        newProposal.newValue = _newValue;
        newProposal.voteStartTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp + _votingDuration;
        newProposal.proposer = msg.sender;

        emit ProposalSubmitted(newProposalId, _parameterName, _newValue, msg.sender);
    }

    /// @notice Allows staked Genesis Energy holders to vote on active environmental proposals.
    ///         Voting power is proportional to the amount of GE staked.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'Yea' vote, false for 'Nay' vote.
    function voteOnEnvironmentalProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "AG: Proposal does not exist");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "AG: Proposal not in active voting period");
        require(stakedGenesisEnergy[msg.sender] > 0, "AG: Must have staked Genesis Energy to vote");
        require(!proposal.hasVoted[msg.sender], "AG: Already voted on this proposal");

        uint256 voterStake = stakedGenesisEnergy[msg.sender];
        if (_support) {
            proposal.yeas += voterStake;
        } else {
            proposal.nays += voterStake;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed proposal, applying the proposed change to the global environmental parameter.
    ///         Requires the voting period to have ended and the proposal to have met specific quorum and
    ///         majority thresholds.
    /// @param _proposalId The ID of the proposal to execute.
    function executeEnvironmentalProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "AG: Proposal does not exist");
        require(block.timestamp > proposal.voteEndTime, "AG: Voting period not ended");
        require(!proposal.executed, "AG: Proposal already executed");

        // Example quorum and majority logic:
        // 1. Minimum participation: 20% of total staked energy must have voted.
        // 2. Simple majority: More 'yea' votes than 'nay' votes.
        uint256 totalVotesCast = proposal.yeas + proposal.nays;
        uint256 minParticipationThreshold = (totalStakedGenesisEnergy * 20) / 100; // 20% of total staked GE

        require(totalVotesCast >= minParticipationThreshold, "AG: Proposal did not meet minimum participation threshold");
        require(proposal.yeas > proposal.nays, "AG: Proposal did not pass with a majority of 'yea' votes");

        environmentalParameters[proposal.parameterName].value = proposal.newValue;
        environmentalParameters[proposal.parameterName].lastUpdated = block.timestamp;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, proposal.parameterName, proposal.newValue);
    }

    // --- V. Query & State Functions ---

    /// @notice Retrieves the current value of a specified global environmental parameter.
    /// @param _parameterName The name of the environmental parameter (e.g., "GlobalGrowthFactor").
    /// @return The current value of the parameter.
    function getEnvironmentalParameter(string memory _parameterName) public view returns (uint256) {
        require(environmentalParameters[_parameterName].name != "", "AG: Parameter does not exist");
        return environmentalParameters[_parameterName].value;
    }

    /// @notice Returns comprehensive information about a specific environmental proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return parameterName, newValue, voteStartTime, voteEndTime, yeas, nays, executed, proposer.
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            string memory parameterName,
            uint256 newValue,
            uint256 voteStartTime,
            uint256 voteEndTime,
            uint256 yeas,
            uint256 nays,
            bool executed,
            address proposer
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalId != 0, "AG: Proposal does not exist");

        return (
            proposal.parameterName,
            proposal.newValue,
            proposal.voteStartTime,
            proposal.voteEndTime,
            proposal.yeas,
            proposal.nays,
            proposal.executed,
            proposal.proposer
        );
    }

    /// @notice Returns the total amount of Genesis Energy currently staked by all users for voting.
    /// @return The total staked amount.
    function getTotalStakedEnergy() public view returns (uint256) {
        return totalStakedGenesisEnergy;
    }

    /// @notice Returns a chronological history of evolution stages (timestamps) for a given shard.
    /// @param _tokenId The ID of the Aetherial Shard.
    /// @return An array of timestamps representing when the shard evolved.
    function getShardEvolutionHistory(uint256 _tokenId) public view returns (uint256[] memory) {
        require(shards[_tokenId].dnaHash != 0, "AG: Shard does not exist");
        return shardEvolutionHistory[_tokenId];
    }

    /// @notice Returns the accumulated nourishment points for a shard that are pending for its next evolution.
    /// @param _tokenId The ID of the Aetherial Shard.
    /// @return The current accumulated nourishment points.
    function getPendingShardNourishment(uint256 _tokenId) public view returns (uint256) {
        require(shards[_tokenId].dnaHash != 0, "AG: Shard does not exist");
        return shards[_tokenId].accumulatedNourishment;
    }

    /// @notice Returns the bonding status of a shard.
    /// @param _tokenId The ID of the Aetherial Shard.
    /// @return isBonded (true/false), bondedWithShardId (0 if not bonded), isParentOfBond (true/false if bonded).
    function getShardBondStatus(uint256 _tokenId) public view returns (bool isBonded, uint256 bondedWithShardId, bool isParentOfBond) {
        AetherialShardData storage shard = shards[_tokenId];
        require(shard.dnaHash != 0, "AG: Shard does not exist");
        return (shard.bondedToShardId != 0, shard.bondedToShardId, shard.isBondedParent);
    }
}
```