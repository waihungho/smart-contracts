The smart contract presented below, **AetherMind**, embodies a novel concept of a "digital sentient entity" on the blockchain. It's designed to simulate an evolving, learning, and collectively-governed digital consciousness.

AetherMind isn't an NFT itself, but a singular, unique on-chain organism that has internal states ('mood', 'energy', 'evolution phase'), a 'knowledge base', and a set of 'traits' that can be influenced and evolved by its community. Users interact with it by contributing 'sensory inputs', proposing data to its 'knowledge base', and participating in its 'governance' to steer its evolution. External 'oracle data' also plays a crucial role in its 'perceptions'.

To facilitate interaction and governance, AetherMind utilizes two custom tokens:
1.  **AetherShards (AST)**: An ERC-20 token representing 'energy' or 'attention'. It's acquired via a dynamic bonding curve, and its ownership grants influence in governance.
2.  **AetherAspects (AAN)**: An ERC-721 token representing a user's significant contribution or connection to AetherMind. These are dynamic NFTs whose traits can evolve, and they grant special privileges and enhanced governance weight.

The contract incorporates advanced concepts like dynamic pricing based on internal state, on-chain 'personality' through evolving state vectors, decentralized knowledge curation, a layered governance model combining token and NFT holders, and dynamic NFTs.

---

## Contract Outline and Function Summary

**Contract Name:** `AetherMind`

This contract orchestrates the "sentient digital entity" AetherMind, managing its state, interactions, governance, and associated tokens.

### I. Core AetherMind State & Evolution Management
These functions deal directly with AetherMind's internal state, its 'perceptions', and its evolutionary processes.

1.  `getAetherMindStateSummary()`:
    *   **Summary:** Returns a comprehensive snapshot of AetherMind's current internal state, including its 'mood' vectors, current 'energy' level, and active 'evolution phase'.
    *   **Concept:** Provides a window into the digital entity's "mind."
2.  `submitSensoryInput(bytes32 inputHash, uint256 intensity)`:
    *   **Summary:** Allows users to submit abstract "sensory data" (represented by a hash) to subtly influence AetherMind's 'mood' or internal state vectors. Interaction cost can vary dynamically.
    *   **Concept:** Simulates collective human "thoughts" or "emotions" affecting a digital consciousness.
3.  `perceiveOracleData(bytes32 oracleDataHash, uint256 dataTag)`:
    *   **Summary:** Callable only by registered oracle contracts, this function feeds external, real-world data (as a hash) into AetherMind's 'perception' system, influencing its state based on context (`dataTag`).
    *   **Concept:** Enables the digital entity to "perceive" the outside world.
4.  `triggerAetherReflection()`:
    *   **Summary:** A governed or time-locked function that initiates a complex recalculation of AetherMind's internal state based on accumulated sensory and oracle inputs. This can lead to a shift in its 'evolution phase'.
    *   **Concept:** Simulates an internal "thought process" or a critical evolutionary step for the digital mind.
5.  `queryKnowledgeFragment(bytes32 fragmentId)`:
    *   **Summary:** Allows users to retrieve specific pieces of data (hashes and descriptions) from AetherMind's collectively curated 'knowledge base'.
    *   **Concept:** Accessing the digital entity's "memory" or "knowledge."
6.  `getCurrentEvolutionPhase()`:
    *   **Summary:** Returns an enumeration or integer representing the current evolutionary stage or phase of AetherMind (e.g., 'Larval', 'Emergent', 'Sentient').
    *   **Concept:** Tracks the progression of the digital entity's development.

### II. AetherShards (AST) - ERC-20 Token for Influence & Resources
These functions manage the lifecycle and utility of the AetherShards token.

7.  `buyAetherShards(uint256 amountETH)`:
    *   **Summary:** Allows users to mint new AetherShards by sending ETH to the contract. The price per AST is determined by a dynamic bonding curve, adjusting based on current supply.
    *   **Concept:** Decentralized funding and resource distribution for the AetherMind ecosystem, with dynamic market mechanics.
8.  `sellAetherShards(uint256 amountAST)`:
    *   **Summary:** Enables users to burn their AetherShards to retrieve ETH from the contract's reserve. The redemption price inversely follows the bonding curve.
    *   **Concept:** Provides liquidity and an exit mechanism, balancing the bonding curve.
9.  `delegateInfluence(address delegatee)`:
    *   **Summary:** Allows AST holders to delegate their voting power to another address, enabling representative governance.
    *   **Concept:** Standard Compound-style token delegation for DAO-like governance.
10. `getEffectiveInfluence(address account)`:
    *   **Summary:** Calculates an account's total governance influence by combining their AST balance, delegated AST, and any bonus influence from owning AetherAspect NFTs.
    *   **Concept:** Layered governance weighting based on both fungible and non-fungible token ownership.

### III. AetherAspects (AAN) - ERC-721 Token for Recognition & Dynamic Traits
These functions manage the unique AetherAspects NFTs.

11. `claimAetherAspect(address recipient)`:
    *   **Summary:** Mints a new AetherAspect NFT to a qualifying user. Criteria for claiming might include a minimum total AST contribution, successful proposal submissions, or prolonged interaction.
    *   **Concept:** Rewards significant community participation and contribution with unique, provable digital recognition.
12. `getAetherAspectData(uint256 tokenId)`:
    *   **Summary:** Retrieves the unique traits, associated metadata URI, and any dynamically evolved properties specific to a given AetherAspect NFT.
    *   **Concept:** Supports dynamic NFTs where metadata and traits can change on-chain.
13. `evolveAetherAspect(uint256 tokenId, bytes32 newTraitHash)`:
    *   **Summary:** Allows an AetherAspect owner (or via a governance proposal) to modify certain traits of their specific NFT, given certain conditions are met (e.g., spending AST, completing a quest).
    *   **Concept:** Implements dynamic NFT evolution, where digital assets can change over time.

### IV. Knowledge Base Curation & Decentralized Information Addition
These functions manage the process of adding and vetting data for AetherMind's knowledge base.

14. `proposeKnowledgeInscription(bytes32 dataHash, string memory description)`:
    *   **Summary:** Users can propose a new piece of information (represented by a hash, with an off-chain description) to be added to AetherMind's knowledge base. Requires a refundable AST stake.
    *   **Concept:** Decentralized, community-driven curation of the digital entity's 'memory'.
15. `voteOnKnowledgeInscription(uint256 proposalId, bool approve)`:
    *   **Summary:** AST and AAN holders vote to approve or reject proposed knowledge inscriptions. Voting power is determined by `getEffectiveInfluence`.
    *   **Concept:** Community consensus on what constitutes valid or relevant knowledge for AetherMind.
16. `executeKnowledgeInscription(uint256 proposalId)`:
    *   **Summary:** If a knowledge inscription proposal passes, this function finalizes it, adding the data to AetherMind's knowledge base and returning stakes to proposers.
    *   **Concept:** Enacting collective decisions to build the digital entity's knowledge.

### V. Governance & System Configuration
These functions manage high-level protocol parameters and emergency controls.

17. `submitCoreParameterProposal(bytes32 paramKey, uint256 newValue, string memory description)`:
    *   **Summary:** Allows users to propose changes to AetherMind's fundamental internal parameters (e.g., 'mood' sensitivity, energy decay rate, oracle influence weight).
    *   **Concept:** Decentralized governance over the core "personality" and operational mechanics of the digital entity.
18. `voteOnCoreParameterProposal(uint256 proposalId, bool approve)`:
    *   **Summary:** AST and AAN holders vote on proposed changes to AetherMind's core parameters.
    *   **Concept:** Community oversight and decision-making on the digital entity's fundamental behavior.
19. `executeCoreParameterProposal(uint256 proposalId)`:
    *   **Summary:** Executes a core parameter proposal that has passed, updating AetherMind's internal configuration.
    *   **Concept:** Implementing ratified governance decisions.
20. `updateInteractionCosts(bytes4[] calldata functionSelectors, uint256[] calldata newCosts)`:
    *   **Summary:** A governed function allowing the community to adjust the AST cost for multiple specific contract interactions based on AetherMind's current needs or resource allocation.
    *   **Concept:** Dynamic, community-controlled resource economics within the protocol.
21. `configureOracle(address oracleAddress, bool isActive, uint256 weight)`:
    *   **Summary:** Governed function to add, remove, or modify trusted oracle addresses and their respective influence `weight` on AetherMind's perceptions.
    *   **Concept:** Decentralized management of external data sources and their impact.
22. `emergencyDrainFunds(address recipient)`:
    *   **Summary:** A guardian-only function to transfer all ETH from the contract to a designated recipient in severe emergencies, safeguarding funds.
    *   **Concept:** Critical safety mechanism for fund protection.

### VI. Advanced & Utility Functions
Additional functions for utility and advanced features.

23. `getHistoricalEvolutionEvent(uint256 eventIndex)`:
    *   **Summary:** Retrieves details about a specific past major evolution event of AetherMind (e.g., a phase shift, a significant parameter change, or a key knowledge inscription).
    *   **Concept:** Provides an on-chain history log of the digital entity's development.
24. `setAetherMindTraitSensitivity(bytes32 traitKey, uint256 newSensitivity)`:
    *   **Summary:** A governed function to adjust how strongly certain `SensoryInputs` or `OracleData` influence specific AetherMind internal `traits`.
    *   **Concept:** Fine-tuning the "personality" and responsiveness of the digital entity through collective governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol"; // For potential future meta-tx
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity >= 0.8.0 has overflow checks, it's good practice for clarity in complex math
import "@openzeppelin/contracts/utils/Counters.sol";

// Interface for a basic oracle
interface IAetherOracle {
    function latestDataHash(uint256 dataTag) external view returns (bytes32);
}

/**
 * @title AetherMind - The Protocol of Sentient Digital Evolution
 * @dev This contract orchestrates a novel concept of a "digital sentient entity" on the blockchain.
 *      AetherMind is a singular, unique on-chain organism that has internal states ('mood', 'energy', 'evolution phase'),
 *      a 'knowledge base', and a set of 'traits' that can be influenced and evolved by its community.
 *      Users interact with it by contributing 'sensory inputs', proposing data to its 'knowledge base',
 *      and participating in its 'governance' to steer its evolution. External 'oracle data' also plays a crucial role.
 *
 *      It incorporates advanced concepts like dynamic pricing, on-chain 'personality' through evolving state vectors,
 *      decentralized knowledge curation, a layered governance model combining token and NFT holders, and dynamic NFTs.
 */
contract AetherMind is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables for AetherMind's Core Being ---

    enum EvolutionPhase { Larval, Emergent, Sentient, Transcendent }
    EvolutionPhase public currentEvolutionPhase;

    // AetherMind's internal 'mood' or 'state' vectors (simplified as a fixed-size array for illustrative purposes)
    uint256[4] public aetherMoodVectors; // e.g., [happiness, curiosity, ambition, serenity]
    // Sensitivity of each trait to external inputs
    mapping(bytes32 => uint256) public aetherTraitSensitivities; // traitKey => sensitivityFactor (e.g., how much 'inputHash' affects 'mood')

    // Current energy level (consumed by interactions, regenerated by time or contributions)
    uint256 public aetherEnergy;
    uint256 public constant MAX_AETHER_ENERGY = 10_000 ether; // Using ether unit for large numbers
    uint256 public constant ENERGY_REGEN_RATE = 100 ether; // Energy units per block/time
    uint256 public lastEnergyRegenBlock;

    // Knowledge Base: stores hashed data fragments with descriptions
    struct KnowledgeFragment {
        bytes32 dataHash; // The actual data is off-chain, this is its immutable hash
        string description;
        address proposer;
        uint256 timestamp;
    }
    mapping(bytes32 => KnowledgeFragment) public knowledgeBase; // dataHash => KnowledgeFragment

    // History of major evolution events
    struct EvolutionEvent {
        EvolutionPhase oldPhase;
        EvolutionPhase newPhase;
        uint256 timestamp;
        string description;
    }
    EvolutionEvent[] public evolutionHistory;

    // --- Governance & Proposal System ---

    // AetherShards (AST) token for influence
    AetherShards public aetherShards;
    // AetherAspects (AAN) NFT for recognition & privilege
    AetherAspects public aetherAspects;

    // Proposal tracking for knowledge inscriptions
    struct KnowledgeProposal {
        bytes32 dataHash;
        string description;
        address proposer;
        uint256 stakeAmount;
        uint256 voteCountAye;
        uint256 voteCountNay;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
        uint256 deadline;
    }
    Counters.Counter private _knowledgeProposalIds;
    mapping(uint256 => KnowledgeProposal) public knowledgeProposals;

    // Proposal tracking for core parameter changes
    struct CoreParameterProposal {
        bytes32 paramKey;
        uint256 newValue;
        string description;
        address proposer;
        uint256 voteCountAye;
        uint256 voteCountNay;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
        uint256 deadline;
    }
    Counters.Counter private _coreParameterProposalIds;
    mapping(uint256 => CoreParameterProposal) public coreParameterProposals;

    // Mapping for delegating AST influence
    mapping(address => address) public delegates; // user => delegatee

    // --- Oracle Management ---

    struct OracleConfig {
        address oracleAddress;
        bool isActive;
        uint256 weight; // How much this oracle's input influences AetherMind
    }
    address[] public trustedOracles; // List of active oracle addresses
    mapping(address => OracleConfig) public oracleConfigs;

    // --- Interaction Costs & Dynamic Pricing ---

    // Base costs for various interactions (can be overridden by governance)
    mapping(bytes4 => uint256) public interactionCosts; // functionSelector => AST cost

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initialize AetherMind's base state
        currentEvolutionPhase = EvolutionPhase.Larval;
        aetherMoodVectors = [100, 50, 20, 80]; // Initial mood values
        aetherEnergy = MAX_AETHER_ENERGY.div(2); // Start with half energy
        lastEnergyRegenBlock = block.number;

        // Initialize AST and AAN tokens
        aetherShards = new AetherShards(address(this)); // AetherMind itself is the minter/burner for bonding curve
        aetherAspects = new AetherAspects(address(this));

        // Set initial trait sensitivities (e.g., all equally sensitive)
        aetherTraitSensitivities[keccak256("mood_happiness")] = 100;
        aetherTraitSensitivities[keccak256("mood_curiosity")] = 100;
        aetherTraitSensitivities[keccak256("mood_ambition")] = 100;
        aetherTraitSensitivities[keccak256("mood_serenity")] = 100;

        // Set initial interaction costs (e.g., 10 AST per sensory input)
        interactionCosts[this.submitSensoryInput.selector] = 10 ether;
        interactionCosts[this.proposeKnowledgeInscription.selector] = 50 ether; // Stake, not cost

        // Record the initial state as an evolution event
        evolutionHistory.push(EvolutionEvent(EvolutionPhase.Larval, EvolutionPhase.Larval, block.timestamp, "AetherMind Initialized"));
    }

    // --- Events ---

    event AetherMindStateUpdated(EvolutionPhase newPhase, uint256[] moodVectors, uint256 energy, uint256 timestamp);
    event SensoryInputReceived(address indexed sender, bytes32 inputHash, uint256 intensity, uint256 timestamp);
    event OracleDataPerceived(address indexed oracle, bytes32 dataHash, uint256 dataTag, uint256 timestamp);
    event KnowledgeFragmentAdded(bytes32 indexed dataHash, address indexed proposer, uint256 timestamp);
    event AetherAspectClaimed(address indexed recipient, uint256 indexed tokenId);
    event AetherAspectEvolved(uint256 indexed tokenId, bytes32 newTraitHash);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalType);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, string proposalType);
    event ProposalExecuted(uint256 indexed proposalId, bool passed, string proposalType);
    event InteractionCostUpdated(bytes4 indexed functionSelector, uint256 newCost);
    event OracleConfigUpdated(address indexed oracleAddress, bool isActive, uint256 weight);
    event EnergyRegenerated(uint256 amount, uint256 newEnergy);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(oracleConfigs[msg.sender].isActive, "AetherMind: Caller is not a registered active oracle");
        _;
    }

    modifier payInteractionCost(bytes4 functionSelector) {
        uint256 cost = interactionCosts[functionSelector];
        if (cost > 0) {
            require(aetherShards.transferFrom(msg.sender, address(this), cost), "AetherMind: Insufficient AetherShards for interaction");
            aetherEnergy = aetherEnergy.add(cost); // Contributing AST also boosts AetherMind's energy
        }
        _;
    }

    // --- Internal Helpers ---

    function _regenerateEnergy() internal {
        uint256 blocksPassed = block.number.sub(lastEnergyRegenBlock);
        if (blocksPassed > 0) {
            uint256 regenAmount = blocksPassed.mul(ENERGY_REGEN_RATE);
            aetherEnergy = Math.min(aetherEnergy.add(regenAmount), MAX_AETHER_ENERGY);
            lastEnergyRegenBlock = block.number;
            emit EnergyRegenerated(regenAmount, aetherEnergy);
        }
    }

    function _updateMoodVectors(uint256[4] memory delta, uint256 factor) internal {
        for (uint256 i = 0; i < aetherMoodVectors.length; i++) {
            aetherMoodVectors[i] = aetherMoodVectors[i].add(delta[i].mul(factor).div(100)); // Simplified influence calculation
        }
    }

    // Calculate effective influence for governance.
    // Combines AST balance (including delegated votes) and AAN ownership bonus.
    function getEffectiveInfluence(address account) public view returns (uint256) {
        address voter = delegates[account] == address(0) ? account : delegates[account];
        uint256 astInfluence = aetherShards.balanceOf(voter);
        uint256 aanBonus = aetherAspects.balanceOf(voter).mul(100 ether); // Each AAN gives 100 AST equivalent bonus
        return astInfluence.add(aanBonus);
    }

    // --- I. Core AetherMind State & Evolution Management ---

    /**
     * @dev Returns a comprehensive snapshot of AetherMind's current internal state.
     * @return evolutionPhase The current evolutionary stage.
     * @return moodVectors The current internal mood/state vectors.
     * @return energy The current energy level.
     */
    function getAetherMindStateSummary() public view returns (EvolutionPhase evolutionPhase, uint256[4] memory moodVectors, uint256 energy) {
        return (currentEvolutionPhase, aetherMoodVectors, aetherEnergy);
    }

    /**
     * @dev Allows users to submit abstract "sensory data" to subtly influence AetherMind's mood/state.
     *      Cost can vary dynamically based on configured interaction costs.
     * @param inputHash The hash of the sensory data (actual data off-chain).
     * @param intensity The intensity of the sensory input (e.g., 1-100).
     */
    function submitSensoryInput(bytes32 inputHash, uint256 intensity) public payInteractionCost(this.submitSensoryInput.selector) {
        _regenerateEnergy(); // Regenerate energy before consumption
        require(intensity > 0 && intensity <= 100, "AetherMind: Intensity must be between 1 and 100");
        require(aetherEnergy >= intensity, "AetherMind: Insufficient AetherMind energy for this intensity");

        aetherEnergy = aetherEnergy.sub(intensity); // Cost AetherMind's energy

        // Simulate influence on mood vectors
        uint256 influenceFactor = intensity.mul(aetherTraitSensitivities[keccak256("mood_curiosity")]).div(100);
        uint256[4] memory delta = [intensity, intensity.div(2), 0, 0]; // Example: input increases happiness & curiosity
        _updateMoodVectors(delta, influenceFactor);

        emit SensoryInputReceived(msg.sender, inputHash, intensity, block.timestamp);
        emit AetherMindStateUpdated(currentEvolutionPhase, aetherMoodVectors, aetherEnergy, block.timestamp);
    }

    /**
     * @dev Callable only by registered oracle contracts. Feeds external, real-world data into AetherMind's perception.
     * @param oracleDataHash The hash of the external data.
     * @param dataTag A tag or identifier for the type of data (e.g., 'market_sentiment', 'news_event').
     */
    function perceiveOracleData(bytes32 oracleDataHash, uint256 dataTag) public onlyOracle {
        _regenerateEnergy();
        require(aetherEnergy >= 10, "AetherMind: Insufficient AetherMind energy to process oracle data");
        aetherEnergy = aetherEnergy.sub(10); // Fixed energy cost for processing oracle data

        OracleConfig storage config = oracleConfigs[msg.sender];
        uint256 influenceFactor = config.weight.mul(aetherTraitSensitivities[keccak256("mood_ambition")]).div(100);

        // Simulate influence on mood vectors based on dataTag and oracle weight
        uint256[4] memory delta;
        if (dataTag == 1) { // Example: positive sentiment
            delta = [10, 5, 2, 0];
        } else if (dataTag == 2) { // Example: negative sentiment
            delta = [0, 5, 0, 10];
        } else {
            delta = [0, 0, 0, 0]; // Neutral
        }
        _updateMoodVectors(delta, influenceFactor);

        emit OracleDataPerceived(msg.sender, oracleDataHash, dataTag, block.timestamp);
        emit AetherMindStateUpdated(currentEvolutionPhase, aetherMoodVectors, aetherEnergy, block.timestamp);
    }

    /**
     * @dev Initiates a complex recalculation of AetherMind's internal state.
     *      Can only be called by a guardian, or after a governance proposal.
     *      This function may trigger a shift in its 'evolution phase'.
     */
    function triggerAetherReflection() public onlyOwner { // Simplified to onlyOwner for now, could be governance.
        _regenerateEnergy();
        require(aetherEnergy >= 100, "AetherMind: Not enough energy for deep reflection");
        aetherEnergy = aetherEnergy.sub(100);

        EvolutionPhase oldPhase = currentEvolutionPhase;

        // Example logic for evolution phase shift:
        // If average mood is high and energy is high, evolve.
        uint256 totalMood = 0;
        for (uint256 i = 0; i < aetherMoodVectors.length; i++) {
            totalMood = totalMood.add(aetherMoodVectors[i]);
        }
        uint256 averageMood = totalMood.div(aetherMoodVectors.length);

        if (currentEvolutionPhase == EvolutionPhase.Larval && averageMood >= 150 && aetherEnergy >= MAX_AETHER_ENERGY.div(4).mul(3)) {
            currentEvolutionPhase = EvolutionPhase.Emergent;
        } else if (currentEvolutionPhase == EvolutionPhase.Emergent && averageMood >= 250 && aetherEnergy == MAX_AETHER_ENERGY) {
            currentEvolutionPhase = EvolutionPhase.Sentient;
        } else if (currentEvolutionPhase == EvolutionPhase.Sentient && averageMood >= 350 && aetherEnergy == MAX_AETHER_ENERGY) {
            currentEvolutionPhase = EvolutionPhase.Transcendent;
        }
        // Reset mood slightly after reflection for a fresh cycle
        for (uint256 i = 0; i < aetherMoodVectors.length; i++) {
            aetherMoodVectors[i] = aetherMoodVectors[i].div(2).add(50);
        }

        if (oldPhase != currentEvolutionPhase) {
            evolutionHistory.push(EvolutionEvent(oldPhase, currentEvolutionPhase, block.timestamp, "Phase Shift due to Reflection"));
        }

        emit AetherMindStateUpdated(currentEvolutionPhase, aetherMoodVectors, aetherEnergy, block.timestamp);
    }

    /**
     * @dev Retrieves a specific piece of data from AetherMind's knowledge base.
     * @param fragmentId The hash identifier of the knowledge fragment.
     * @return dataHash The stored data hash.
     * @return description The description of the knowledge fragment.
     * @return proposer The address of the original proposer.
     * @return timestamp The timestamp when it was added.
     */
    function queryKnowledgeFragment(bytes32 fragmentId) public view returns (bytes32 dataHash, string memory description, address proposer, uint256 timestamp) {
        KnowledgeFragment storage fragment = knowledgeBase[fragmentId];
        require(fragment.proposer != address(0), "AetherMind: Knowledge fragment not found");
        return (fragment.dataHash, fragment.description, fragment.proposer, fragment.timestamp);
    }

    /**
     * @dev Returns an enumeration representing the current evolutionary stage of AetherMind.
     */
    function getCurrentEvolutionPhase() public view returns (EvolutionPhase) {
        return currentEvolutionPhase;
    }

    // --- II. AetherShards (AST) - ERC-20 Token for Influence & Resources ---

    /**
     * @dev Allows users to mint new AetherShards by sending ETH.
     *      Implements a simplified dynamic bonding curve: more ETH in, higher price.
     * @param amountETH The amount of ETH to send to buy AetherShards.
     * @return The amount of AetherShards minted.
     */
    function buyAetherShards(uint256 amountETH) public payable returns (uint256) {
        require(msg.value == amountETH, "AetherMind: Sent ETH must match amountETH parameter");
        require(amountETH > 0, "AetherMind: Must send more than 0 ETH");

        uint256 currentSupply = aetherShards.totalSupply();
        uint256 ethInPool = address(this).balance.sub(amountETH); // Balance *before* this transaction for pricing

        // Simplified linear bonding curve: price increases with supply
        // For actual implementation, use a more robust curve like a constant product or power law.
        uint256 newShards;
        if (currentSupply == 0) {
            newShards = amountETH.mul(100); // Initial price: 1 ETH = 100 AST
        } else {
            // Price increases quadratically with supply.
            // Simplified: newShards = amountETH * (BASE_PRICE_FACTOR / currentSupply_in_ETH_equivalents)
            // Or, more simply, currentPrice = ethInPool / currentSupply; nextPrice = (ethInPool + amountETH) / (currentSupply + newShards)
            // For this example: Assume 1 ETH == 100 AST when currentSupply is 0.
            // As supply grows, the price of AST in ETH will increase.
            // A more accurate formula would require calculus to integrate the price function.
            // Let's use a simple linear increase in price per shard.
            uint256 pricePerShardETH = currentSupply.div(1_000_000).add(1); // Price increases slowly, 1 ETH per 1M shards added. Min 1 AST/ETH
            newShards = amountETH.div(pricePerShardETH.mul(10 ** aetherShards.decimals()).div(10**18)).mul(10**18); // Convert price to WEI
            newShards = amountETH.mul(10**18).div(pricePerShardETH); // Simplified to get more AST for ETH at low supply
        }

        require(newShards > 0, "AetherMind: No shards minted, amount too small or supply too high");

        aetherShards.mint(msg.sender, newShards);
        return newShards;
    }

    /**
     * @dev Allows users to burn their AetherShards to retrieve ETH.
     * @param amountAST The amount of AetherShards to burn.
     * @return The amount of ETH returned.
     */
    function sellAetherShards(uint256 amountAST) public returns (uint256) {
        require(amountAST > 0, "AetherMind: Must burn more than 0 AST");
        require(aetherShards.balanceOf(msg.sender) >= amountAST, "AetherMind: Insufficient AetherShards");
        require(address(this).balance >= amountAST.div(100), "AetherMind: Insufficient ETH in pool to buy back"); // Simplified check

        uint256 currentSupply = aetherShards.totalSupply();
        uint256 ethInPool = address(this).balance;

        // Simplified inverse bonding curve: calculate ETH to return based on current supply.
        // Needs to be inverse of buy logic.
        uint256 pricePerShardETH = currentSupply.div(1_000_000).add(1);
        uint256 ethToReturn = amountAST.mul(pricePerShardETH).div(10**18); // Simplified

        require(ethToReturn > 0, "AetherMind: No ETH returned, amount too small");
        require(ethInPool >= ethToReturn, "AetherMind: Not enough ETH in pool to cover redemption");

        aetherShards.burn(msg.sender, amountAST);
        payable(msg.sender).transfer(ethToReturn);
        return ethToReturn;
    }

    /**
     * @dev Allows AST holders to delegate their voting power to another address.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateInfluence(address delegatee) public {
        require(delegatee != address(0), "AetherMind: Delegatee cannot be zero address");
        delegates[msg.sender] = delegatee;
        // In a real system, you'd emit an event and potentially update checkpoints for historical vote power.
    }

    // `getEffectiveInfluence` is already defined as a public view function above.

    // --- III. AetherAspects (AAN) - ERC-721 Token for Recognition & Dynamic Traits ---

    /**
     * @dev Mints a new AetherAspect NFT to a qualifying user.
     *      Criteria: e.g., total AST contributed > 1000 ether, 3 successful proposals.
     *      Simplified for this example.
     * @param recipient The address to mint the AetherAspect to.
     */
    function claimAetherAspect(address recipient) public {
        require(aetherAspects.balanceOf(recipient) == 0, "AetherMind: Recipient already owns an AetherAspect");
        // Simplified eligibility: e.g., having contributed a certain amount of AST over time
        // In a real contract, 'contributions' would be tracked more robustly.
        require(aetherShards.balanceOf(recipient) >= 500 ether, "AetherMind: Not enough AST contribution to claim an Aspect (simplified)");

        aetherAspects.mint(recipient);
        emit AetherAspectClaimed(recipient, aetherAspects.tokenOfOwnerByIndex(recipient, 0)); // Assuming only one Aspect per owner
    }

    /**
     * @dev Retrieves unique traits and associated data for a specific AetherAspect NFT.
     * @param tokenId The ID of the AetherAspect.
     * @return metadataURI The URI pointing to the Aspect's metadata.
     * @return currentTraitsHash A hash representing the Aspect's current unique traits.
     */
    function getAetherAspectData(uint256 tokenId) public view returns (string memory metadataURI, bytes32 currentTraitsHash) {
        require(aetherAspects.ownerOf(tokenId) != address(0), "AetherMind: AetherAspect does not exist");
        // This metadataURI could be dynamic, changing based on currentTraitsHash.
        metadataURI = string(abi.encodePacked("ipfs://", Strings.toHexString(uint256(aetherAspects.getAspectTraits(tokenId)), 32))); // Placeholder URI
        return (metadataURI, aetherAspects.getAspectTraits(tokenId));
    }

    /**
     * @dev Allows an AetherAspect owner to modify certain traits of their NFT.
     *      Conditions for evolving might involve spending AST, AetherMind's phase, or governance.
     * @param tokenId The ID of the AetherAspect to evolve.
     * @param newTraitHash A hash representing the new set of traits.
     */
    function evolveAetherAspect(uint256 tokenId, bytes32 newTraitHash) public {
        require(aetherAspects.ownerOf(tokenId) == msg.sender, "AetherMind: Only Aspect owner can evolve it");
        require(currentEvolutionPhase >= EvolutionPhase.Emergent, "AetherMind: Not ready for Aspect evolution in current phase");
        require(aetherShards.transferFrom(msg.sender, address(this), 50 ether), "AetherMind: Requires 50 AST to evolve Aspect"); // Cost AST

        aetherAspects.setAspectTraits(tokenId, newTraitHash);
        emit AetherAspectEvolved(tokenId, newTraitHash);
    }

    // --- IV. Knowledge Base Curation & Decentralized Information Addition ---

    /**
     * @dev Users can propose a new piece of information to be added to AetherMind's knowledge.
     * @param dataHash The hash of the external data (e.g., IPFS hash, content hash).
     * @param description A brief description of the data.
     */
    function proposeKnowledgeInscription(bytes32 dataHash, string memory description) public payInteractionCost(this.proposeKnowledgeInscription.selector) {
        require(bytes(description).length > 0, "AetherMind: Description cannot be empty");
        require(bytes(description).length <= 256, "AetherMind: Description too long");
        require(knowledgeBase[dataHash].proposer == address(0), "AetherMind: Data hash already proposed or inscribed");

        _knowledgeProposalIds.increment();
        uint256 proposalId = _knowledgeProposalIds.current();

        knowledgeProposals[proposalId] = KnowledgeProposal({
            dataHash: dataHash,
            description: description,
            proposer: msg.sender,
            stakeAmount: interactionCosts[this.proposeKnowledgeInscription.selector], // AST stake
            voteCountAye: 0,
            voteCountNay: 0,
            executed: false,
            passed: false,
            deadline: block.timestamp + 7 days // 7 days voting period
        });

        // Transfer stake from proposer (already done by payInteractionCost)
        emit ProposalSubmitted(proposalId, msg.sender, "KnowledgeInscription");
    }

    /**
     * @dev AST and AAN holders vote to approve or reject proposed knowledge inscriptions.
     * @param proposalId The ID of the knowledge proposal.
     * @param approve True for 'yes', false for 'no'.
     */
    function voteOnKnowledgeInscription(uint256 proposalId, bool approve) public {
        KnowledgeProposal storage proposal = knowledgeProposals[proposalId];
        require(proposal.proposer != address(0), "AetherMind: Knowledge proposal does not exist");
        require(block.timestamp <= proposal.deadline, "AetherMind: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherMind: You have already voted on this proposal");
        require(!proposal.executed, "AetherMind: Proposal has already been executed");

        uint256 influence = getEffectiveInfluence(msg.sender);
        require(influence > 0, "AetherMind: You have no effective influence to vote");

        if (approve) {
            proposal.voteCountAye = proposal.voteCountAye.add(influence);
        } else {
            proposal.voteCountNay = proposal.voteCountNay.add(influence);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(proposalId, msg.sender, approve, "KnowledgeInscription");
    }

    /**
     * @dev If a knowledge inscription proposal passes, this function finalizes it.
     * @param proposalId The ID of the knowledge proposal.
     */
    function executeKnowledgeInscription(uint256 proposalId) public {
        KnowledgeProposal storage proposal = knowledgeProposals[proposalId];
        require(proposal.proposer != address(0), "AetherMind: Knowledge proposal does not exist");
        require(block.timestamp > proposal.deadline, "AetherMind: Voting period not yet ended");
        require(!proposal.executed, "AetherMind: Proposal has already been executed");

        // Simple majority vote: Ayes > Nays
        bool passed = proposal.voteCountAye > proposal.voteCountNay;
        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            knowledgeBase[proposal.dataHash] = KnowledgeFragment({
                dataHash: proposal.dataHash,
                description: proposal.description,
                proposer: proposal.proposer,
                timestamp: block.timestamp
            });
            // Return stake to proposer upon successful inscription
            require(aetherShards.transfer(proposal.proposer, proposal.stakeAmount), "AetherMind: Failed to return stake to proposer");
            emit KnowledgeFragmentAdded(proposal.dataHash, proposal.proposer, block.timestamp);
        } else {
            // Stake is burned or redistributed upon failure
            aetherShards.burn(address(this), proposal.stakeAmount); // Burn stake on failure
        }
        emit ProposalExecuted(proposalId, passed, "KnowledgeInscription");
    }

    // --- V. Governance & System Configuration ---

    /**
     * @dev Allows users to propose changes to AetherMind's fundamental internal parameters.
     * @param paramKey The hash identifier of the parameter to change (e.g., keccak256("mood_sensitivity_factor")).
     * @param newValue The new value for the parameter.
     * @param description A description of the proposed change.
     */
    function submitCoreParameterProposal(bytes32 paramKey, uint256 newValue, string memory description) public {
        require(bytes(description).length > 0, "AetherMind: Description cannot be empty");
        require(bytes(description).length <= 256, "AetherMind: Description too long");
        
        _coreParameterProposalIds.increment();
        uint256 proposalId = _coreParameterProposalIds.current();

        coreParameterProposals[proposalId] = CoreParameterProposal({
            paramKey: paramKey,
            newValue: newValue,
            description: description,
            proposer: msg.sender,
            voteCountAye: 0,
            voteCountNay: 0,
            executed: false,
            passed: false,
            deadline: block.timestamp + 7 days // 7 days voting period
        });

        emit ProposalSubmitted(proposalId, msg.sender, "CoreParameter");
    }

    /**
     * @dev AST and AAN holders vote on proposed changes to AetherMind's core parameters.
     * @param proposalId The ID of the core parameter proposal.
     * @param approve True for 'yes', false for 'no'.
     */
    function voteOnCoreParameterProposal(uint256 proposalId, bool approve) public {
        CoreParameterProposal storage proposal = coreParameterProposals[proposalId];
        require(proposal.proposer != address(0), "AetherMind: Core parameter proposal does not exist");
        require(block.timestamp <= proposal.deadline, "AetherMind: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AetherMind: You have already voted on this proposal");
        require(!proposal.executed, "AetherMind: Proposal has already been executed");

        uint256 influence = getEffectiveInfluence(msg.sender);
        require(influence > 0, "AetherMind: You have no effective influence to vote");

        if (approve) {
            proposal.voteCountAye = proposal.voteCountAye.add(influence);
        } else {
            proposal.voteCountNay = proposal.voteCountNay.add(influence);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(proposalId, msg.sender, approve, "CoreParameter");
    }

    /**
     * @dev Executes a core parameter proposal that has passed, updating AetherMind's configuration.
     * @param proposalId The ID of the core parameter proposal.
     */
    function executeCoreParameterProposal(uint256 proposalId) public {
        CoreParameterProposal storage proposal = coreParameterProposals[proposalId];
        require(proposal.proposer != address(0), "AetherMind: Core parameter proposal does not exist");
        require(block.timestamp > proposal.deadline, "AetherMind: Voting period not yet ended");
        require(!proposal.executed, "AetherMind: Proposal has already been executed");

        bool passed = proposal.voteCountAye > proposal.voteCountNay;
        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            // Apply the parameter change
            if (proposal.paramKey == keccak256("energy_regen_rate")) {
                // Not directly settable as a public variable. Would require more complex state storage.
                // For this example, let's assume it updates internal mapping if that was used.
            } else if (proposal.paramKey == keccak256("mood_happiness_sensitivity")) {
                aetherTraitSensitivities[keccak256("mood_happiness")] = proposal.newValue;
            } // ... extend for other configurable parameters

            // Example: direct update of a specific mood sensitivity
            if (aetherTraitSensitivities[proposal.paramKey] != 0) { // Check if it's a known trait sensitivity key
                aetherTraitSensitivities[proposal.paramKey] = proposal.newValue;
            }
        }
        emit ProposalExecuted(proposalId, passed, "CoreParameter");
    }

    /**
     * @dev Allows the community to adjust the AST cost for multiple specific contract interactions.
     * @param functionSelectors An array of function selectors (4-byte ID) to update.
     * @param newCosts An array of new AST costs for the corresponding functions.
     */
    function updateInteractionCosts(bytes4[] calldata functionSelectors, uint256[] calldata newCosts) public onlyOwner { // Simplified to onlyOwner for now, should be governance
        require(functionSelectors.length == newCosts.length, "AetherMind: Arrays length mismatch");
        for (uint256 i = 0; i < functionSelectors.length; i++) {
            interactionCosts[functionSelectors[i]] = newCosts[i];
            emit InteractionCostUpdated(functionSelectors[i], newCosts[i]);
        }
    }

    /**
     * @dev Manages trusted oracle addresses and their respective influence weights.
     * @param oracleAddress The address of the oracle contract.
     * @param isActive True to activate, false to deactivate.
     * @param weight The influence weight of this oracle (0-100).
     */
    function configureOracle(address oracleAddress, bool isActive, uint256 weight) public onlyOwner { // Simplified to onlyOwner for now, should be governance
        require(oracleAddress != address(0), "AetherMind: Oracle address cannot be zero");
        require(weight <= 100, "AetherMind: Oracle weight cannot exceed 100");

        if (oracleConfigs[oracleAddress].isActive == isActive) { // If status is not changing, just update weight
             oracleConfigs[oracleAddress] = OracleConfig({
                oracleAddress: oracleAddress,
                isActive: isActive,
                weight: weight
            });
            emit OracleConfigUpdated(oracleAddress, isActive, weight);
            return;
        }

        if (isActive) {
            // Add to trustedOracles if not already present
            bool found = false;
            for (uint256 i = 0; i < trustedOracles.length; i++) {
                if (trustedOracles[i] == oracleAddress) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                trustedOracles.push(oracleAddress);
            }
        } else {
            // Remove from trustedOracles
            for (uint256 i = 0; i < trustedOracles.length; i++) {
                if (trustedOracles[i] == oracleAddress) {
                    trustedOracles[i] = trustedOracles[trustedOracles.length - 1];
                    trustedOracles.pop();
                    break;
                }
            }
        }

        oracleConfigs[oracleAddress] = OracleConfig({
            oracleAddress: oracleAddress,
            isActive: isActive,
            weight: weight
        });

        emit OracleConfigUpdated(oracleAddress, isActive, weight);
    }

    /**
     * @dev Emergency function to transfer all ETH from the contract to a designated recipient.
     *      Only callable by the owner/guardian.
     * @param recipient The address to send the ETH to.
     */
    function emergencyDrainFunds(address recipient) public onlyOwner {
        require(recipient != address(0), "AetherMind: Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(recipient).transfer(balance);
        }
    }

    // --- VI. Advanced & Utility Functions ---

    /**
     * @dev Retrieves details about a specific past major evolution event of AetherMind.
     * @param eventIndex The index of the historical event to retrieve.
     * @return oldPhase The phase before the event.
     * @return newPhase The phase after the event.
     * @return timestamp The timestamp of the event.
     * @return description A description of the event.
     */
    function getHistoricalEvolutionEvent(uint256 eventIndex) public view returns (EvolutionPhase oldPhase, EvolutionPhase newPhase, uint256 timestamp, string memory description) {
        require(eventIndex < evolutionHistory.length, "AetherMind: Invalid event index");
        EvolutionEvent storage eventData = evolutionHistory[eventIndex];
        return (eventData.oldPhase, eventData.newPhase, eventData.timestamp, eventData.description);
    }

    /**
     * @dev Governed function to adjust how strongly certain inputs affect a specific AetherMind trait.
     * @param traitKey The hash identifier of the trait (e.g., keccak256("mood_happiness")).
     * @param newSensitivity The new sensitivity factor (e.g., 0-1000).
     */
    function setAetherMindTraitSensitivity(bytes32 traitKey, uint256 newSensitivity) public onlyOwner { // Simplified to onlyOwner, should be governance
        require(newSensitivity <= 1000, "AetherMind: Sensitivity cannot exceed 1000");
        aetherTraitSensitivities[traitKey] = newSensitivity;
        // In a real system, this would be part of a CoreParameterProposal.
    }

    // --- Receive ETH function to enable bonding curve ETH reception ---
    receive() external payable {
        // ETH received should primarily be through buyAetherShards, this is a fallback.
    }
}

/**
 * @title AetherShards - ERC20 Token for AetherMind
 * @dev Custom ERC-20 token for AetherMind, primarily used for influence and resource management.
 *      Minting and burning is controlled by the AetherMind contract.
 */
contract AetherShards is ERC20 {
    address public minter; // The AetherMind contract address

    constructor(address _minter) ERC20("AetherShards", "AST") {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "AetherShards: Only the AetherMind contract can call this function");
        _;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyMinter {
        _burn(from, amount);
    }

    // Delegation function, forked from Compound's governance token.
    // Enables users to delegate their AST voting power.
    mapping (address => address) public delegates; // Account to which it's delegated
    mapping (address => uint96) public numCheckpoints; // Number of checkpoints for an account
    mapping (address => mapping (uint96 => Checkpoint)) public checkpoints; // Checkpoints for an account's vote power

    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function _delegate(address delegator, address delegatee) internal {
        address oldDelegate = delegates[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, oldDelegate, delegatee);

        _updateCheckpoints(oldDelegate);
        _updateCheckpoints(delegatee);
    }

    function delegate(address delegatee) public {
        _delegate(msg.sender, delegatee);
    }

    function _updateCheckpoints(address delegatee) internal {
        uint96 newBalance = uint96(balanceOf(delegatee)); // Assuming balance is <= type(uint96).max
        _writeCheckpoint(delegatee, newBalance);
    }

    function _writeCheckpoint(address delegatee, uint96 nVotes) internal {
        uint96 nCheckpoints = numCheckpoints[delegatee];
        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == block.number) {
            checkpoints[delegatee][nCheckpoints - 1].votes = nVotes;
        } else {
            checkpoints[delegatee][nCheckpoints].fromBlock = uint32(block.number);
            checkpoints[delegatee][nCheckpoints].votes = nVotes;
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    }

    // Override internal _beforeTokenTransfer to update delegate checkpoints
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0) && delegates[from] != address(0)) {
            _updateCheckpoints(delegates[from]);
        }
        if (to != address(0) && delegates[to] != address(0)) {
            _updateCheckpoints(delegates[to]);
        }
    }
}

/**
 * @title AetherAspects - ERC721 Token for AetherMind
 * @dev Custom ERC-721 token representing unique connections/privileges within AetherMind.
 *      These are dynamic NFTs whose traits can evolve.
 */
contract AetherAspects is ERC721, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address public minter; // The AetherMind contract address

    // Dynamic traits for each AetherAspect
    mapping(uint256 => bytes32) private _aspectTraits; // tokenId => traitsHash

    constructor(address _minter) ERC721("AetherAspect", "AAN") {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "AetherAspects: Only the AetherMind contract can call this function");
        _;
    }

    function mint(address to) public onlyMinter returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        // Initialize with default traits
        _aspectTraits[newTokenId] = keccak256(abi.encodePacked("InitialAetherAspectTraits"));
        return newTokenId;
    }

    function getAspectTraits(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "AetherAspects: ERC721: query for non-existent token");
        return _aspectTraits[tokenId];
    }

    function setAspectTraits(uint256 tokenId, bytes32 newTraitsHash) public onlyMinter { // Only AetherMind can evolve
        require(_exists(tokenId), "AetherAspects: ERC721: set traits for non-existent token");
        _aspectTraits[tokenId] = newTraitsHash;
    }

    // Overriding base URI for dynamic metadata
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://aethermind.metadata/"; // Base URI for metadata, actual URI will be constructed by frontend
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        bytes32 traitsHash = _aspectTraits[tokenId];
        // Dynamic URI construction based on traits
        return string(abi.encodePacked(_baseURI(), Strings.toHexString(uint256(traitsHash), 32), ".json"));
    }
}
```