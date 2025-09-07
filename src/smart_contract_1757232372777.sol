This smart contract, **ChronosForge**, introduces an advanced, creative, and unique concept: an adaptive ecosystem for "Emergent Digital Lifeforms" called *Chronos Shards*. These NFTs are dynamic, evolving, and subject to environmental pressures (entropic decay). The ecosystem itself is governed by an on-chain adaptive algorithm and a decentralized Progenitor Council, allowing the 'Forge' parameters to evolve based on community interaction and simulated ecosystem health.

---

## ChronosForge: Adaptive Protocol for Emergent Digital Lifeforms

### Outline & Function Summary

**I. Core Concepts:**

*   **Chronos Shards (ERC-721):** Unique, dynamic NFTs representing digital lifeforms. They possess mutable traits, an evolutionary stage, and a resilience score, all of which can change over time and through user interaction.
*   **Essence (ERC-20):** The primary energy resource within the Forge. Users spend Essence to cultivate, mutate, and evolve their Shards. Essence is assumed to be an external ERC-20 token which users acquire and approve for the ChronosForge contract.
*   **Adaptive Forge Parameters:** Global parameters (e.g., mutation likelihood, essence costs, decay rates) that define the "environment" of the Forge. These parameters are not static; they adapt based on on-chain activity and can also be influenced by governance.
*   **Progenitor Score:** A non-transferable, reputation-based score awarded to active and positive contributors to the ChronosForge ecosystem, granting governance rights.
*   **Decentralized Governance:** A system where users with a sufficient Progenitor Score can propose and vote on changes to the Forge's adaptive parameters.
*   **Entropic Decay:** A time-based mechanism where Shards lose resilience if not cultivated, simulating environmental challenges.

**II. Contract Structure:**

*   **Roles:** Utilizes OpenZeppelin's `AccessControl` for `DEFAULT_ADMIN_ROLE`, `PROGENITOR_COUNCIL_ROLE` (for governance), and `CHRONOS_ORACLE_ROLE` (for triggering adaptive parameter changes).
*   **Data Structures:** `ChronosShard` struct for NFT properties, `Proposal` struct for governance.
*   **Errors & Events:** Custom errors for gas efficiency, detailed events for tracking all significant actions.

**III. Function Summary (25+ functions):**

1.  **`constructor()`**: Initializes the contract with `DEFAULT_ADMIN_ROLE` and sets initial Forge parameters.
2.  **`setEssenceToken(address _essenceToken)`**: Admin function to set the address of the ERC-20 Essence token.
3.  **`mintChronosShard(string memory _genesisTraitDescriptor)`**: Mints a new Chronos Shard, assigning it initial traits and consuming Essence.
4.  **`cultivateShard(uint256 _shardId, uint256 _essenceAmount)`**: Spends Essence to increase a Shard's resilience and reset its decay timer.
5.  **`attemptMutation(uint256 _shardId)`**: Initiates a probabilistic mutation attempt for a Shard, potentially changing its traits or evolutionary path, consuming Essence.
6.  **`evolveShard(uint256 _shardId)`**: Attempts to advance a Shard to its next evolutionary stage, if conditions (resilience, specific traits) are met, consuming Essence.
7.  **`triggerEntropicDecay(uint256 _shardId)`**: Allows anyone to trigger the decay process for an uncultivated Shard. If decay occurs, the caller receives a small Essence reward.
8.  **`getShardDetails(uint256 _shardId)`**: View function to retrieve all detailed information about a specific Chronos Shard.
9.  **`getChronosShardEvolutionStage(uint256 _shardId)`**: View function to get a Shard's current evolutionary stage.
10. **`getChronosShardTraits(uint256 _shardId)`**: View function to get a Shard's current traits.
11. **`getTotalShardsMinted()`**: View function returning the total number of Chronos Shards minted.
12. **`getShardOwner(uint256 _shardId)`**: View function to get the owner of a specific Shard.
13. **`getForgeParameter(bytes32 _parameterName)`**: View function to retrieve the current value of a global Forge parameter.
14. **`adaptForgeParameters()`**: Callable by `CHRONOS_ORACLE_ROLE`. Triggers the internal adaptive algorithm to adjust global Forge parameters based on recorded ecosystem metrics (simulated AI-driven response).
15. **`attestProgenitorContribution(address _recipient, uint256 _scoreIncrease)`**: `PROGENITOR_COUNCIL_ROLE` function to award Progenitor Score for positive contributions.
16. **`getProgenitorScore(address _user)`**: View function to get a user's current Progenitor Score.
17. **`proposeForgeParameterChange(bytes32 _parameterName, uint256 _newValue, string memory _description)`**: Allows users with a minimum Progenitor Score to propose changes to Forge parameters.
18. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows users with a minimum Progenitor Score to vote on an active proposal.
19. **`executeProposal(uint256 _proposalId)`**: `PROGENITOR_COUNCIL_ROLE` function to execute a passed proposal, applying the proposed parameter change.
20. **`getProposalDetails(uint256 _proposalId)`**: View function to retrieve information about a specific proposal.
21. **`setRoleMember(bytes32 _role, address _member, bool _grant)`**: `DEFAULT_ADMIN_ROLE` function to grant or revoke roles (e.g., `PROGENITOR_COUNCIL_ROLE`, `CHRONOS_ORACLE_ROLE`).
22. **`pauseForgeActivities(bool _pause)`**: `DEFAULT_ADMIN_ROLE` or `PROGENITOR_COUNCIL_ROLE` function to pause or unpause critical Forge activities (e.g., minting, mutations) for maintenance.
23. **`withdrawContractFunds(address _token, address _to, uint256 _amount)`**: `DEFAULT_ADMIN_ROLE` or `PROGENITOR_COUNCIL_ROLE` function to withdraw accidentally sent tokens or managed Essence.
24. **`getGlobalForgeMetrics()`**: View function to retrieve the current state of on-chain metrics used for adaptive parameter logic.
25. **`getMinProgenitorScoreForProposal()`**: View function for the minimum score required to propose.
26. **`getMinProgenitorScoreForVote()`**: View function for the minimum score required to vote.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Interfaces ---

/**
 * @title IEssenceToken
 * @dev Interface for the external ERC-20 Essence token.
 */
interface IEssenceToken is IERC20 {
    // IERC20 already provides transferFrom, approve, balanceOf
}

// --- Custom Errors ---

error NotEnoughEssence(uint256 required, uint256 has);
error ShardNotFound(uint256 shardId);
error InvalidEssenceAmount();
error ShardNotOwnedByCaller(uint256 shardId);
error CannotEvolveShard(string reason);
error NoDecayNeeded(uint256 shardId);
error EvolutionStageMaxed(uint256 shardId);
error ShardAlreadyCultivatedRecently(uint256 shardId, uint256 cooldownEnds);
error ProposalNotFound(uint256 proposalId);
error ProposalAlreadyVoted(uint256 proposalId);
error InsufficientProgenitorScore(uint256 required, uint256 has);
error ProposalNotYetExecutable(uint256 proposalId);
error ProposalAlreadyExecuted(uint256 proposalId);
error ProposalFailed(uint256 proposalId);
error InvalidParameterValue();
error CannotMutateRecently(uint256 shardId, uint256 cooldownEnds);
error InvalidTraitDescriptor();
error ForgePaused();

/**
 * @title ChronosForge
 * @dev An adaptive protocol for emergent digital lifeforms (Chronos Shards),
 *      featuring dynamic NFTs, on-chain adaptive parameters, a reputation system,
 *      and decentralized governance.
 */
contract ChronosForge is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Roles ---
    bytes32 public constant PROGENITOR_COUNCIL_ROLE = keccak256("PROGENITOR_COUNCIL_ROLE");
    bytes32 public constant CHRONOS_ORACLE_ROLE = keccak256("CHRONOS_ORACLE_ROLE");

    // --- State Variables ---
    IEssenceToken private s_essenceToken;
    Counters.Counter private s_shardIdCounter;
    Counters.Counter private s_proposalIdCounter;

    // Paused state
    bool public paused;

    // Global Forge Parameters (dynamic and adaptive)
    mapping(bytes32 => uint256) public s_forgeParameters;

    // Progenitor Score (reputation)
    mapping(address => uint256) public s_progenitorScore;

    // Chronos Shard Data Structure
    struct ChronosShard {
        uint256 id;
        address owner;
        uint256[] traits; // Dynamic array of trait IDs (e.g., [1, 5, 10])
        uint256 resilience; // Health/energy of the shard
        uint8 evolutionaryStage; // 0-5, 0 being basic
        uint256 lastCultivatedTimestamp; // For decay and cultivation cooldown
        uint256 lastMutationTimestamp; // For mutation cooldown
        uint256 genesisTimestamp;
    }
    mapping(uint256 => ChronosShard) public s_chronosShards;

    // Governance Proposals
    struct Proposal {
        uint256 id;
        bytes32 parameterName;
        uint256 newValue;
        string description;
        address proposer;
        uint256 creationTimestamp;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted
        bool executed;
        bool passed; // True if proposal passed, false otherwise
    }
    mapping(uint256 => Proposal) public s_proposals;

    // Global Forge Metrics for adaptive parameter logic
    uint256 public s_totalEssenceSpentInCultivation;
    uint256 public s_totalMutationsAttempted;
    uint256 public s_totalShardsMinted;
    uint256 public s_lastAdaptiveRunTimestamp;

    // --- Events ---
    event EssenceTokenSet(address indexed _tokenAddress);
    event ChronosShardMinted(uint256 indexed shardId, address indexed owner, uint256[] traits, uint8 evolutionaryStage);
    event ChronosShardCultivated(uint256 indexed shardId, address indexed cultivator, uint256 essenceAmount, uint256 newResilience);
    event ChronosShardMutated(uint256 indexed shardId, uint256[] oldTraits, uint256[] newTraits);
    event ChronosShardEvolved(uint256 indexed shardId, uint8 oldStage, uint8 newStage);
    event ChronosShardDecayed(uint256 indexed shardId, uint256 oldResilience, uint256 newResilience);
    event ForgeParameterUpdated(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue, address indexed updater);
    event ProgenitorScoreUpdated(address indexed user, uint256 newScore);
    event ProposalCreated(uint256 indexed proposalId, bytes32 parameterName, uint256 newValue, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event ForgePausedStateChanged(bool newPausedState);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert ForgePaused();
        _;
    }

    /**
     * @dev Initializes the ChronosForge contract.
     * @param _admin The initial admin address.
     * @param _essenceTokenAddress The address of the ERC-20 Essence token.
     */
    constructor(address _admin, address _essenceTokenAddress) ERC721("ChronosShard", "CHRONS") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PROGENITOR_COUNCIL_ROLE, _admin); // Admin is also initially on the council
        _grantRole(CHRONOS_ORACLE_ROLE, _admin); // Admin is also initially the oracle handler

        // Set initial Forge parameters
        s_forgeParameters[keccak256("MINT_COST_ESSENCE")] = 100 * (10 ** 18); // 100 Essence
        s_forgeParameters[keccak256("CULTIVATION_COST_PER_RESILIENCE_ESSENCE")] = 1 * (10 ** 18); // 1 Essence per 1 resilience
        s_forgeParameters[keccak256("MUTATION_COST_ESSENCE")] = 50 * (10 ** 18); // 50 Essence
        s_forgeParameters[keccak256("EVOLUTION_COST_ESSENCE_BASE")] = 200 * (10 ** 18); // 200 Essence base
        s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")] = 10; // Lose 10 resilience per day
        s_forgeParameters[keccak256("MIN_RESILIENCE_FOR_MUTATION")] = 50;
        s_forgeParameters[keccak256("MIN_RESILIENCE_FOR_EVOLUTION")] = 100;
        s_forgeParameters[keccak256("CULTIVATION_COOLDOWN_SECONDS")] = 1 days; // Can cultivate once per day
        s_forgeParameters[keccak256("MUTATION_COOLDOWN_SECONDS")] = 3 days; // Can mutate once every 3 days
        s_forgeParameters[keccak256("MAX_EVOLUTION_STAGE")] = 5;
        s_forgeParameters[keccak256("DECAY_REWARD_ESSENCE")] = 10 * (10 ** 18); // Reward for triggering decay
        s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_PROPOSAL")] = 1000;
        s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_VOTE")] = 100;
        s_forgeParameters[keccak256("PROPOSAL_VOTING_PERIOD_SECONDS")] = 7 days;
        s_forgeParameters[keccak256("PROPOSAL_QUORUM_PERCENTAGE")] = 30; // 30% of total voters (simplified)
        s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")] = 60; // 60% chance to mutate

        // Initialize essence token
        s_essenceToken = IEssenceToken(_essenceTokenAddress);
        emit EssenceTokenSet(_essenceTokenAddress);
    }

    // --- Core Forge Mechanics & Shard Management (NFT focused) ---

    /**
     * @dev Sets the address of the ERC-20 Essence token.
     *      Only callable by an address with `DEFAULT_ADMIN_ROLE`.
     * @param _essenceToken The address of the Essence ERC-20 token.
     */
    function setEssenceToken(address _essenceToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        s_essenceToken = IEssenceToken(_essenceToken);
        emit EssenceTokenSet(_essenceToken);
    }

    /**
     * @dev Mints a new Chronos Shard for the caller.
     *      Requires payment in Essence token.
     * @param _genesisTraitDescriptor A string describing the initial trait or type (e.g., "Fire", "Water").
     *        This will be hashed to become a trait ID.
     */
    function mintChronosShard(string memory _genesisTraitDescriptor) external whenNotPaused {
        uint256 mintCost = s_forgeParameters[keccak256("MINT_COST_ESSENCE")];
        if (s_essenceToken.balanceOf(msg.sender) < mintCost) revert NotEnoughEssence(mintCost, s_essenceToken.balanceOf(msg.sender));
        
        // Transfer Essence to the contract
        s_essenceToken.transferFrom(msg.sender, address(this), mintCost);

        s_shardIdCounter.increment();
        uint256 newShardId = s_shardIdCounter.current();

        // Create initial trait from descriptor
        uint256 genesisTraitId = uint256(keccak256(abi.encodePacked(_genesisTraitDescriptor)));
        
        ChronosShard storage newShard = s_chronosShards[newShardId];
        newShard.id = newShardId;
        newShard.owner = msg.sender;
        newShard.traits.push(genesisTraitId); // Assign initial trait
        newShard.resilience = 100; // Starting resilience
        newShard.evolutionaryStage = 0; // Basic stage
        newShard.lastCultivatedTimestamp = block.timestamp;
        newShard.lastMutationTimestamp = 0; // Can mutate immediately after mint
        newShard.genesisTimestamp = block.timestamp;

        _safeMint(msg.sender, newShardId);
        s_totalShardsMinted++;

        emit ChronosShardMinted(newShardId, msg.sender, newShard.traits, newShard.evolutionaryStage);
    }

    /**
     * @dev Cultivates a Chronos Shard, increasing its resilience and resetting its decay timer.
     *      Requires payment in Essence token.
     * @param _shardId The ID of the Chronos Shard to cultivate.
     * @param _essenceAmount The amount of Essence to spend on cultivation.
     */
    function cultivateShard(uint256 _shardId, uint256 _essenceAmount) external whenNotPaused {
        if (ownerOf(_shardId) != msg.sender) revert ShardNotOwnedByCaller(_shardId);
        if (_essenceAmount == 0) revert InvalidEssenceAmount();
        
        ChronosShard storage shard = s_chronosShards[_shardId];
        if (shard.id == 0) revert ShardNotFound(_shardId);

        uint256 cultivationCooldown = s_forgeParameters[keccak256("CULTIVATION_COOLDOWN_SECONDS")];
        if (block.timestamp < shard.lastCultivatedTimestamp + cultivationCooldown) {
            revert ShardAlreadyCultivatedRecently(_shardId, shard.lastCultivatedTimestamp + cultivationCooldown);
        }

        if (s_essenceToken.balanceOf(msg.sender) < _essenceAmount) revert NotEnoughEssence(_essenceAmount, s_essenceToken.balanceOf(msg.sender));
        
        s_essenceToken.transferFrom(msg.sender, address(this), _essenceAmount);

        uint256 resilienceIncrease = _essenceAmount.div(s_forgeParameters[keccak256("CULTIVATION_COST_PER_RESILIENCE_ESSENCE")]);
        shard.resilience = shard.resilience.add(resilienceIncrease);
        shard.lastCultivatedTimestamp = block.timestamp;

        s_totalEssenceSpentInCultivation = s_totalEssenceSpentInCultivation.add(_essenceAmount);
        emit ChronosShardCultivated(_shardId, msg.sender, _essenceAmount, shard.resilience);
    }

    /**
     * @dev Attempts to mutate a Chronos Shard, potentially changing its traits.
     *      Requires payment in Essence and has a cooldown and minimum resilience requirement.
     *      Mutation is probabilistic.
     * @param _shardId The ID of the Chronos Shard to mutate.
     */
    function attemptMutation(uint256 _shardId) external whenNotPaused {
        if (ownerOf(_shardId) != msg.sender) revert ShardNotOwnedByCaller(_shardId);

        ChronosShard storage shard = s_chronosShards[_shardId];
        if (shard.id == 0) revert ShardNotFound(_shardId);

        if (shard.resilience < s_forgeParameters[keccak256("MIN_RESILIENCE_FOR_MUTATION")]) {
            revert CannotMutateRecently("Insufficient resilience for mutation");
        }

        uint256 mutationCooldown = s_forgeParameters[keccak256("MUTATION_COOLDOWN_SECONDS")];
        if (block.timestamp < shard.lastMutationTimestamp + mutationCooldown) {
            revert CannotMutateRecently(_shardId, shard.lastMutationTimestamp + mutationCooldown);
        }

        uint256 mutationCost = s_forgeParameters[keccak256("MUTATION_COST_ESSENCE")];
        if (s_essenceToken.balanceOf(msg.sender) < mutationCost) revert NotEnoughEssence(mutationCost, s_essenceToken.balanceOf(msg.sender));
        
        s_essenceToken.transferFrom(msg.sender, address(this), mutationCost);
        s_totalMutationsAttempted++;
        shard.lastMutationTimestamp = block.timestamp;

        uint256[] memory oldTraits = new uint256[](shard.traits.length);
        for(uint i=0; i<shard.traits.length; i++) {
            oldTraits[i] = shard.traits[i];
        }

        // Simulate probabilistic mutation
        uint256 mutationChance = s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")];
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 100;

        if (randomValue < mutationChance) {
            // Simple mutation: add a new trait based on current time/entropy
            uint256 newTrait = uint256(keccak256(abi.encodePacked(block.timestamp, _shardId, randomValue)));
            shard.traits.push(newTrait);
            // Optionally remove an old trait, or modify existing ones for more complex logic
            // e.g., if (shard.traits.length > 1) { shard.traits[randomValue % shard.traits.length] = newTrait; }
        } else {
            // No mutation, maybe a slight resilience boost or penalty
            shard.resilience = shard.resilience.add(mutationCost.div(s_forgeParameters[keccak256("CULTIVATION_COST_PER_RESILIENCE_ESSENCE")]).div(2)); // Small boost if no mutation
        }
        
        emit ChronosShardMutated(_shardId, oldTraits, shard.traits);
    }

    /**
     * @dev Attempts to advance a Chronos Shard to its next evolutionary stage.
     *      Requires meeting resilience thresholds and consumes Essence.
     * @param _shardId The ID of the Chronos Shard to evolve.
     */
    function evolveShard(uint256 _shardId) external whenNotPaused {
        if (ownerOf(_shardId) != msg.sender) revert ShardNotOwnedByCaller(_shardId);

        ChronosShard storage shard = s_chronosShards[_shardId];
        if (shard.id == 0) revert ShardNotFound(_shardId);

        uint8 maxStage = uint8(s_forgeParameters[keccak256("MAX_EVOLUTION_STAGE")]);
        if (shard.evolutionaryStage >= maxStage) {
            revert EvolutionStageMaxed(_shardId);
        }

        if (shard.resilience < s_forgeParameters[keccak256("MIN_RESILIENCE_FOR_EVOLUTION")]) {
            revert CannotEvolveShard("Insufficient resilience");
        }

        // Evolution cost scales with current stage
        uint256 evolutionCost = s_forgeParameters[keccak256("EVOLUTION_COST_ESSENCE_BASE")] * (shard.evolutionaryStage + 1);
        if (s_essenceToken.balanceOf(msg.sender) < evolutionCost) revert NotEnoughEssence(evolutionCost, s_essenceToken.balanceOf(msg.sender));
        
        s_essenceToken.transferFrom(msg.sender, address(this), evolutionCost);

        uint8 oldStage = shard.evolutionaryStage;
        shard.evolutionaryStage++;
        shard.resilience = shard.resilience.div(2); // Evolution is taxing, halves resilience
        // Evolution could also grant new traits or remove old ones
        
        emit ChronosShardEvolved(_shardId, oldStage, shard.evolutionaryStage);
    }

    /**
     * @dev Triggers entropic decay for a Chronos Shard if it hasn't been cultivated recently.
     *      Anyone can call this, and the caller receives an Essence reward if decay occurs.
     * @param _shardId The ID of the Chronos Shard to check for decay.
     */
    function triggerEntropicDecay(uint256 _shardId) external {
        ChronosShard storage shard = s_chronosShards[_shardId];
        if (shard.id == 0) revert ShardNotFound(_shardId);

        uint256 lastCultivated = shard.lastCultivatedTimestamp;
        uint256 decayRate = s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")];
        
        uint256 daysSinceCultivation = (block.timestamp - lastCultivated) / 1 days;

        if (daysSinceCultivation == 0 || decayRate == 0) revert NoDecayNeeded(_shardId);

        uint256 resilienceLoss = daysSinceCultivation.mul(decayRate);
        
        uint256 oldResilience = shard.resilience;
        if (shard.resilience <= resilienceLoss) {
            shard.resilience = 0; // Shard fully decays or becomes dormant
            // Potentially add more complex "death" or "dormancy" mechanics here
        } else {
            shard.resilience = shard.resilience.sub(resilienceLoss);
        }
        shard.lastCultivatedTimestamp = block.timestamp; // Reset timestamp to prevent repeated decay for same period

        // Reward the caller for triggering decay
        uint256 decayReward = s_forgeParameters[keccak256("DECAY_REWARD_ESSENCE")];
        if (s_essenceToken.balanceOf(address(this)) >= decayReward) {
            s_essenceToken.transfer(msg.sender, decayReward);
        }

        emit ChronosShardDecayed(_shardId, oldResilience, shard.resilience);
    }

    /**
     * @dev View function to retrieve all detailed information about a specific Chronos Shard.
     * @param _shardId The ID of the Chronos Shard.
     * @return A tuple containing all shard properties.
     */
    function getShardDetails(uint256 _shardId) 
        external 
        view 
        returns (
            uint256 id, 
            address owner, 
            uint256[] memory traits, 
            uint256 resilience, 
            uint8 evolutionaryStage, 
            uint256 lastCultivatedTimestamp, 
            uint256 lastMutationTimestamp,
            uint256 genesisTimestamp
        ) 
    {
        ChronosShard storage shard = s_chronosShards[_shardId];
        if (shard.id == 0 && _shardId != 0) revert ShardNotFound(_shardId); // Allow 0 to return default empty

        return (
            shard.id,
            shard.owner,
            shard.traits,
            shard.resilience,
            shard.evolutionaryStage,
            shard.lastCultivatedTimestamp,
            shard.lastMutationTimestamp,
            shard.genesisTimestamp
        );
    }

    /**
     * @dev View function to get a Shard's current evolutionary stage.
     * @param _shardId The ID of the Chronos Shard.
     * @return The evolutionary stage.
     */
    function getChronosShardEvolutionStage(uint256 _shardId) external view returns (uint8) {
        if (s_chronosShards[_shardId].id == 0) revert ShardNotFound(_shardId);
        return s_chronosShards[_shardId].evolutionaryStage;
    }

    /**
     * @dev View function to get a Shard's current traits.
     * @param _shardId The ID of the Chronos Shard.
     * @return An array of trait IDs.
     */
    function getChronosShardTraits(uint256 _shardId) external view returns (uint256[] memory) {
        if (s_chronosShards[_shardId].id == 0) revert ShardNotFound(_shardId);
        return s_chronosShards[_shardId].traits;
    }

    /**
     * @dev View function returning the total number of Chronos Shards minted.
     * @return The total count of shards.
     */
    function getTotalShardsMinted() external view returns (uint256) {
        return s_shardIdCounter.current();
    }

    /**
     * @dev View function to get the owner of a specific Shard.
     * @param _shardId The ID of the Chronos Shard.
     * @return The address of the owner.
     */
    function getShardOwner(uint256 _shardId) public view returns (address) {
        return ownerOf(_shardId);
    }

    // --- Essence Token Interaction (ERC20 focused) ---

    /**
     * @dev Returns the address of the Essence ERC-20 token contract.
     * @return The Essence token address.
     */
    function getEssenceTokenAddress() external view returns (address) {
        return address(s_essenceToken);
    }

    // --- Global Forge Parameters & Adaptation ---

    /**
     * @dev View function to retrieve the current value of a global Forge parameter.
     * @param _parameterName The keccak256 hash of the parameter's name (e.g., keccak256("MINT_COST_ESSENCE")).
     * @return The value of the parameter.
     */
    function getForgeParameter(bytes32 _parameterName) external view returns (uint256) {
        return s_forgeParameters[_parameterName];
    }

    /**
     * @dev Callable by `CHRONOS_ORACLE_ROLE`. Triggers the internal adaptive algorithm
     *      to adjust global Forge parameters based on recorded ecosystem metrics.
     *      This simulates an AI-driven response to ecosystem health.
     */
    function adaptForgeParameters() external onlyRole(CHRONOS_ORACLE_ROLE) {
        // Simple adaptive logic based on collected metrics
        // In a real advanced system, this could involve more complex calculations,
        // external oracle data, or even ZKP for off-chain AI computation verification.

        // Example Logic:
        // 1. If minting is slow, decrease mint cost.
        if (s_totalShardsMinted > 0 && s_totalShardsMinted < 100 && (block.timestamp - s_lastAdaptiveRunTimestamp > 7 days)) { // A week since last run, and low activity
            uint256 currentMintCost = s_forgeParameters[keccak256("MINT_COST_ESSENCE")];
            if (currentMintCost > 10 * (10 ** 18)) { // Don't go below a floor
                s_forgeParameters[keccak256("MINT_COST_ESSENCE")] = currentMintCost.mul(9).div(10); // Decrease by 10%
                emit ForgeParameterUpdated(keccak256("MINT_COST_ESSENCE"), currentMintCost, s_forgeParameters[keccak256("MINT_COST_ESSENCE")], msg.sender);
            }
        }

        // 2. If average resilience is too high, increase decay rate to add challenge.
        //    (Requires tracking average resilience, simplifying for this example)
        // For simplicity, let's assume high overall activity implies high resilience.
        if (s_totalEssenceSpentInCultivation > 1000 * (10 ** 18) && s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")] < 50) {
            uint256 currentDecayRate = s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")];
            s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")] = currentDecayRate.add(5);
            emit ForgeParameterUpdated(keccak256("DECAY_RATE_PER_DAY_RESILIENCE"), currentDecayRate, s_forgeParameters[keccak256("DECAY_RATE_PER_DAY_RESILIENCE")], msg.sender);
        }

        // 3. If mutations are too infrequent, increase mutation chance.
        //    (Requires tracking mutation frequency, simplifying for this example)
        if (s_totalMutationsAttempted < s_totalShardsMinted * 0.5 && s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")] < 90) {
             uint256 currentMutationChance = s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")];
             s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")] = currentMutationChance.add(5);
             emit ForgeParameterUpdated(keccak256("MUTATION_CHANCE_PERCENTAGE"), currentMutationChance, s_forgeParameters[keccak256("MUTATION_CHANCE_PERCENTAGE")], msg.sender);
        }

        s_lastAdaptiveRunTimestamp = block.timestamp;
        // Reset metrics for next adaptive period (optional, or use cumulative)
        // s_totalEssenceSpentInCultivation = 0;
        // s_totalMutationsAttempted = 0;
        // s_totalShardsMinted = 0; // If measuring activity *since* last adapt
    }

    // --- Progenitor Score & Governance (DAO/Reputation focused) ---

    /**
     * @dev Awards Progenitor Score to a user for positive contributions.
     *      Only callable by an address with `PROGENITOR_COUNCIL_ROLE`.
     * @param _recipient The address to award score to.
     * @param _scoreIncrease The amount of score to add.
     */
    function attestProgenitorContribution(address _recipient, uint256 _scoreIncrease) external onlyRole(PROGENITOR_COUNCIL_ROLE) {
        if (_recipient == address(0)) revert InvalidParameterValue();
        s_progenitorScore[_recipient] = s_progenitorScore[_recipient].add(_scoreIncrease);
        emit ProgenitorScoreUpdated(_recipient, s_progenitorScore[_recipient]);
    }

    /**
     * @dev View function to get a user's current Progenitor Score.
     * @param _user The address of the user.
     * @return The user's Progenitor Score.
     */
    function getProgenitorScore(address _user) external view returns (uint256) {
        return s_progenitorScore[_user];
    }

    /**
     * @dev Allows users with a minimum Progenitor Score to propose changes to Forge parameters.
     * @param _parameterName The keccak256 hash of the parameter name to change.
     * @param _newValue The new value for the parameter.
     * @param _description A description of the proposal.
     */
    function proposeForgeParameterChange(bytes32 _parameterName, uint256 _newValue, string memory _description) external whenNotPaused {
        uint256 minScore = s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_PROPOSAL")];
        if (s_progenitorScore[msg.sender] < minScore) {
            revert InsufficientProgenitorScore(minScore, s_progenitorScore[msg.sender]);
        }
        
        s_proposalIdCounter.increment();
        uint256 proposalId = s_proposalIdCounter.current();

        s_proposals[proposalId] = Proposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            description: _description,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            voteEndTime: block.timestamp + s_forgeParameters[keccak256("PROPOSAL_VOTING_PERIOD_SECONDS")],
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, _parameterName, _newValue, msg.sender);
    }

    /**
     * @dev Allows users with a minimum Progenitor Score to vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (block.timestamp > proposal.voteEndTime) revert ProposalNotYetExecutable(_proposalId); // Voting period ended
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted(_proposalId);

        uint256 minScore = s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_VOTE")];
        if (s_progenitorScore[msg.sender] < minScore) {
            revert InsufficientProgenitorScore(minScore, s_progenitorScore[msg.sender]);
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(s_progenitorScore[msg.sender]); // Weighted voting by score
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(s_progenitorScore[msg.sender]);
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed proposal, applying the proposed parameter change.
     *      Only callable by an address with `PROGENITOR_COUNCIL_ROLE`.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyRole(PROGENITOR_COUNCIL_ROLE) {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);
        if (block.timestamp <= proposal.voteEndTime) revert ProposalNotYetExecutable(_proposalId); // Voting period not over

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        // Simple quorum: at least 30% of max possible votes (simplified to say 30% of total voters has to have voted and the total score of those voters is > 0).
        // A more robust quorum would compare against total active eligible voters' score.
        // For simplicity: if some votes exist and enough score for 'for' votes
        
        bool passed = false;
        if (totalVotes > 0) { // Ensure at least some participation
            uint256 quorumPercentage = s_forgeParameters[keccak256("PROPOSAL_QUORUM_PERCENTAGE")];
            if (proposal.votesFor.mul(100).div(totalVotes) >= 50 && totalVotes > 0) { // Simple majority and quorum check
                 // The quorum check here is simplified. A real DAO would need total eligible voting power.
                 // For now, let's assume a "dynamic" quorum based on actual participation.
                 // A better quorum would be comparing totalVotes against a global "total progenitor score eligible to vote"
                passed = true;
            }
        }
        
        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            uint256 oldValue = s_forgeParameters[proposal.parameterName];
            s_forgeParameters[proposal.parameterName] = proposal.newValue;
            emit ForgeParameterUpdated(proposal.parameterName, oldValue, proposal.newValue, msg.sender);
        } else {
            revert ProposalFailed(_proposalId);
        }

        emit ProposalExecuted(_proposalId, passed);
    }

    /**
     * @dev View function to retrieve information about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) 
        external 
        view 
        returns (
            uint256 id, 
            bytes32 parameterName, 
            uint256 newValue, 
            string memory description, 
            address proposer, 
            uint256 creationTimestamp, 
            uint256 voteEndTime, 
            uint256 votesFor, 
            uint256 votesAgainst, 
            bool executed, 
            bool passed
        ) 
    {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);

        return (
            proposal.id,
            proposal.parameterName,
            proposal.newValue,
            proposal.description,
            proposal.proposer,
            proposal.creationTimestamp,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.passed
        );
    }

    // --- Maintenance & Administration ---

    /**
     * @dev Grants or revokes a role for a specific member.
     *      Only callable by an address with `DEFAULT_ADMIN_ROLE`.
     * @param _role The role to modify (e.g., `PROGENITOR_COUNCIL_ROLE`).
     * @param _member The address of the member.
     * @param _grant True to grant the role, false to revoke.
     */
    function setRoleMember(bytes32 _role, address _member, bool _grant) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_grant) {
            _grantRole(_role, _member);
        } else {
            _revokeRole(_role, _member);
        }
    }

    /**
     * @dev Pauses or unpauses critical Forge activities (e.g., minting, mutations).
     *      Only callable by `DEFAULT_ADMIN_ROLE` or `PROGENITOR_COUNCIL_ROLE`.
     * @param _pause True to pause, false to unpause.
     */
    function pauseForgeActivities(bool _pause) external onlyRole(DEFAULT_ADMIN_ROLE) { // Can be extended to PROGENITOR_COUNCIL_ROLE
        paused = _pause;
        emit ForgePausedStateChanged(_pause);
    }

    /**
     * @dev Withdraws accidentally sent tokens (ERC-20 or native ETH) from the contract.
     *      Only callable by `DEFAULT_ADMIN_ROLE` or `PROGENITOR_COUNCIL_ROLE`.
     * @param _token The address of the token to withdraw (address(0) for ETH).
     * @param _to The address to send the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawContractFunds(address _token, address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) { // Can be extended to PROGENITOR_COUNCIL_ROLE
        if (_token == address(0)) {
            // Withdraw ETH
            (bool success, ) = _to.call{value: _amount}("");
            require(success, "ETH transfer failed");
        } else {
            // Withdraw ERC-20
            IERC20(_token).transfer(_to, _amount);
        }
    }

    /**
     * @dev View function to retrieve the current state of on-chain metrics
     *      used for the adaptive parameter logic.
     * @return A tuple containing total essence spent, total mutations, total shards minted, and last adapt timestamp.
     */
    function getGlobalForgeMetrics() 
        external 
        view 
        returns (
            uint256 totalEssenceSpentInCultivation,
            uint256 totalMutationsAttempted,
            uint256 totalShardsMintedValue,
            uint256 lastAdaptiveRunTimestamp
        ) 
    {
        return (
            s_totalEssenceSpentInCultivation,
            s_totalMutationsAttempted,
            s_totalShardsMinted,
            s_lastAdaptiveRunTimestamp
        );
    }

    /**
     * @dev View function for the minimum Progenitor Score required to propose a change.
     * @return The minimum score.
     */
    function getMinProgenitorScoreForProposal() external view returns (uint256) {
        return s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_PROPOSAL")];
    }

    /**
     * @dev View function for the minimum Progenitor Score required to vote on a proposal.
     * @return The minimum score.
     */
    function getMinProgenitorScoreForVote() external view returns (uint256) {
        return s_forgeParameters[keccak256("MIN_PROGENITOR_SCORE_FOR_VOTE")];
    }
}
```