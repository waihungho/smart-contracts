This Solidity smart contract, `ChronosynapseNexus`, introduces the concept of unique, dynamic, and evolving digital organisms as ERC721 NFTs. It integrates advanced concepts such as dynamic NFT traits, on-chain resource management, a decentralized governance model for evolution, simulated life cycles (decay, dormancy, replication), and a basic reputation system for user interactions. The goal is to create a living, adaptive protocol that changes and grows based on community engagement.

---

## Chronosynapse Nexus Protocol

### Outline:

1.  **Core Concepts:**
    *   **Nexus (ERC721 Token):** A unique, evolving digital entity, representing a digital organism within the Chronosynapse ecosystem.
    *   **DNA (Immutable Traits):** Fundamental characteristics (e.g., base resilience, max energy capacity) set at the Nexus's creation, defining its inherent nature. These traits remain constant throughout its life.
    *   **Evolvable Traits (Mutable):** Dynamic attributes (e.g., current energy, health, adaptation level) that change over time through various interactions, nourishment, and community-approved mutations.
    *   **Energy & Health:** Critical resources for a Nexus. They decline over time, requiring "nourishment" (ETH) to maintain vitality. Insufficient energy/health leads to a "dormant" state.
    *   **Mutations:** A decentralized governance mechanism where users can propose and vote on changes to a Nexus's Evolvable Traits, simulating adaptive evolution.
    *   **Replication:** The ability for mature and well-nourished Nexuses to "spawn" new offspring, inheriting a blend of their parents' DNA and starting a new generation.
    *   **Inter-Nexus Synapse:** A simulated, unique interaction between two Nexuses, potentially leading to trait boosts, energy transfers, or other collaborative outcomes.
    *   **User Reputation:** An on-chain system to track and reward users for positive contributions to the ecosystem (e.g., consistent nourishment, successful mutation proposals).
    *   **Protocol Governance:** A simplified DAO-like mechanism allowing Nexus owners (or a designated authority) to propose and vote on global protocol parameter changes (e.g., decay rates, mutation costs).

2.  **Data Structures:**
    *   `NexusDNA`: Struct containing immutable traits, defining the inherent capabilities and costs associated with a Nexus.
    *   `NexusEvolvableTraits`: Struct containing mutable traits, reflecting the current state and progress of a Nexus.
    *   `MutationProposal`: Struct detailing a proposed change to a Nexus's evolvable traits, including its voting status and outcome.
    *   `ProtocolChangeProposal`: Struct for proposals concerning global contract parameters.
    *   `TraitChallenge`: Struct for conceptual challenges related to Nexus traits, hinting at future oracle or off-chain data integration.

3.  **Events:** Comprehensive event logging for all significant state changes, enabling off-chain tracking and analysis of Nexus evolution and protocol activities.

4.  **Error Handling:** Robust `require` statements ensure valid function calls and maintain contract integrity.

---

### Function Summary (26 functions):

**I. Core Nexus Management (ERC721 & Custom):**

1.  `constructor()`: Initializes the contract, setting the ERC721 name and symbol, and the initial owner.
2.  `safeMintGenesisNexus(address recipient)`: Mints the very first, foundational Nexus NFT. This special mint is callable only once by the contract owner to seed the ecosystem.
3.  `getNexusDNA(uint256 tokenId)`: A view function to retrieve the immutable DNA traits of a specific Nexus.
4.  `getNexusEvolvableTraits(uint256 tokenId)`: A view function to retrieve the current mutable Evolvable Traits of a specific Nexus, showing its current state.
5.  `nourishNexus(uint256 tokenId) payable`: Allows users to provide ETH to a Nexus, increasing its `currentEnergy` and `currentHealth`, and updating its `lastNourishedTimestamp`.
6.  `reviveDormantNexus(uint256 tokenId) payable`: Enables users to revive a Nexus that has become dormant due to lack of nourishment, requiring a specified ETH fee.
7.  `proposeMutation(uint256 tokenId, int256 energyChange, int256 healthChange, int256 adaptationChange, string memory description)`: Allows a user to propose a mutation (change) to a Nexus's evolvable traits, requiring a small ETH deposit.
8.  `voteOnMutation(uint256 proposalId, bool support)`: Casts a vote (for or against) on an active mutation proposal.
9.  `executeMutation(uint256 proposalId)`: Executes a successfully voted-on mutation proposal, applying the proposed trait changes to the Nexus and potentially rewarding the executor.
10. `replicateNexus(uint256 parentTokenId1, uint256 parentTokenId2)`: Enables two mature Nexuses to "replicate," spawning a new Nexus (offspring) with inherited traits. This consumes energy from the parent Nexuses.
11. `initiateInterNexusSynapse(uint256 tokenIdA, uint256 tokenIdB)`: Simulates a unique interaction or "synapse" between two Nexuses, potentially boosting specific traits or facilitating energy transfers between them.
12. `getMutationProposal(uint256 proposalId)`: A view function to retrieve detailed information about a specific mutation proposal.
13. `getNexusHistoricalEnergyLog(uint256 tokenId)`: (Simplified for on-chain storage) Returns the timestamp of the Nexus's last nourishment. More detailed history would typically require off-chain indexing.

**II. Protocol Governance & Administration:**

14. `proposeProtocolParameterChange(uint256 paramType, int256 newValue, string memory description)`: Allows a designated authority (currently `Ownable` owner, extensible to a DAO) to propose changes to global protocol parameters (e.g., `decayRate`, `mutationCost`).
15. `voteOnProtocolChange(uint256 proposalId, bool support)`: Casts a vote on an active global protocol parameter change proposal.
16. `executeProtocolParameterChange(uint256 proposalId)`: Executes a successfully voted-on protocol parameter change, updating the contract's fundamental behaviors.
17. `setProtocolParam(uint256 paramType, int256 newValue)`: A direct function for the contract owner to set specific protocol parameters, primarily used by `executeProtocolParameterChange` or for initial setup/emergency adjustments.
18. `withdrawProtocolFees()`: Allows the protocol's governance treasury (currently the owner) to withdraw accumulated ETH fees from sources like mutation proposal deposits and revival fees.

**III. User Reputation & External Integration (Conceptual):**

19. `getUserReputation(address user)`: A view function that retrieves a user's on-chain reputation score, which increases with positive contributions to the ecosystem.
20. `challengeNexusTrait(uint256 tokenId, uint256 traitIndex, bytes32 challengeDataHash)`: Initiates a conceptual challenge related to a Nexus's trait, potentially requiring off-chain proof or future oracle input for verification.
21. `resolveTraitChallenge(uint256 tokenId, uint256 traitIndex, bool success, uint256 challengeId)`: A function (currently callable by the owner) to resolve a trait challenge, applying trait adjustments and reputation changes based on the challenge outcome.

**IV. Inherited ERC721 & View Functions:**

22. `balanceOf(address owner)`: Returns the number of tokens (Nexuses) owned by a given address. (Inherited from `ERC721Enumerable`)
23. `ownerOf(uint256 tokenId)`: Returns the address of the owner of the specified Nexus token. (Inherited from `ERC721Enumerable`)
24. `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a Nexus token from one address to another, with checks for recipient contract safety. (Inherited from `ERC721Enumerable`)
25. `approve(address to, uint256 tokenId)`: Approves another address to transfer a specific Nexus token on the owner's behalf. (Inherited from `ERC721Enumerable`)
26. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved to manage all of an owner's Nexus tokens. (Inherited from `ERC721Enumerable`)
    *(Note: Additional functions like `transferFrom`, `getApproved`, `setApprovalForAll`, `tokenURI`, `totalSupply`, `tokenOfOwnerByIndex`, `tokenByIndex`, and `supportsInterface` are also inherited from OpenZeppelin's `ERC721Enumerable` and `ERC721` contracts.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Explicit for clarity, 0.8+ handles overflow/underflow by default
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max operations

/**
 * @title ChronosynapseNexus
 * @dev A smart contract for an Evolving Digital Organism (EDO) NFT system.
 *      It features dynamic traits, energy-based lifecycle, community-driven
 *      mutations, replication, inter-entity interactions, and a reputation system.
 */
contract ChronosynapseNexus is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _mutationProposalCounter;
    Counters.Counter private _protocolChangeProposalCounter;
    Counters.Counter private _challengeCounter;

    // Enum for Nexus status
    enum NexusStatus { Active, Dormant }

    // Nexus Immutable DNA Traits: Set at minting, never changes.
    struct NexusDNA {
        uint256 baseResilience;       // Base health regeneration / decay resistance (higher is better)
        uint256 maxEnergyCapacity;    // Maximum energy level a Nexus can hold
        uint256 replicationCostFactor; // Multiplier for replication cost (higher means more expensive)
        uint256 mutationAdaptability; // Conceptual: how well it accepts mutations (1-100, higher is more adaptive)
        uint256 genesisTimestamp;     // Block timestamp of Nexus creation
    }

    // Nexus Evolvable (Mutable) Traits: Changes through interactions, nourishment, and mutations.
    struct NexusEvolvableTraits {
        int256 currentEnergy;          // Current energy level (can be negative during dormancy)
        int256 currentHealth;          // Current health level (can be negative during dormancy)
        uint256 adaptationLevel;      // Overall evolutionary progress / skill level
        uint256 lastNourishedTimestamp; // Last time nourishment was provided, used for decay calculation
        uint256 generation;           // Generational depth (0 for genesis, 1 for first offspring, etc.)
        uint256 mutationProgressCount;  // Number of successful mutations applied to this Nexus
        uint256 synapseCount;         // Number of successful inter-Nexus synapses
        NexusStatus status;           // Current status: Active or Dormant
    }

    // Mutation Proposal Details: For on-chain voting to alter Nexus traits.
    struct MutationProposal {
        uint256 tokenId;                  // The Nexus targeted by this proposal
        int256 proposedEnergyChange;       // Change to currentEnergy if successful
        int256 proposedHealthChange;       // Change to currentHealth if successful
        int256 proposedAdaptationChange;   // Change to adaptationLevel if successful
        string description;               // Description of the proposed mutation
        uint256 startTimestamp;           // Time when the voting period began
        uint256 endTimestamp;             // Time when the voting period ends
        uint256 votesFor;                 // Number of votes in favor
        uint256 votesAgainst;             // Number of votes against
        bool executed;                    // True if the proposal has been executed
        bool exists;                      // To validate if proposal ID is legitimate
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // Protocol Parameter Types (for governance): Enum for type-safe parameter changes.
    enum ProtocolParamType {
        DecayRatePerBlock,
        NourishmentValuePerEth,
        RevivalCostMultiplier,
        MutationProposalDeposit,
        MutationVotingPeriod,
        MutationSuccessThreshold,
        ReplicationEnergyCost,
        InterSynapseEnergyCost,
        MinReplicationAdaptationLevel,
        ProtocolVotingPeriod
    }

    // Protocol Change Proposal Details: For global contract parameter adjustments.
    struct ProtocolChangeProposal {
        ProtocolParamType paramType;      // Type of parameter being changed
        int256 newValue;                 // The new value for the parameter
        string description;               // Description of the proposed change
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool exists;
        mapping(address => bool) hasVoted;
    }

    // Trait Challenge Details: Conceptual mechanism for external verification/challenges.
    struct TraitChallenge {
        uint256 tokenId;
        uint256 traitIndex;              // An arbitrary index representing which trait is challenged (e.g., 1 for adaptationLevel)
        bytes32 challengeDataHash;       // Hash of off-chain proof data for verification
        address challenger;              // Address of the user who initiated the challenge
        bool resolved;                   // True if the challenge has been resolved
        bool success;                    // True if the challenger's claim was proven correct
        uint256 challengeTimestamp;      // Time when the challenge was initiated
    }

    // Mappings for storing Nexus data
    mapping(uint256 => NexusDNA) public nexusDNA;
    mapping(uint256 => NexusEvolvableTraits) public nexusEvolvableTraits;
    mapping(uint256 => MutationProposal) public mutationProposals;
    mapping(uint256 => ProtocolChangeProposal) public protocolChangeProposals;
    mapping(address => uint256) public userReputation; // Tracks user reputation scores
    mapping(uint256 => TraitChallenge) public traitChallenges;

    // Protocol Parameters (default values, modifiable via governance)
    uint256 public decayRatePerBlock = 1; // Energy/Health points lost per block
    uint256 public nourishmentValuePerEth = 1000; // Energy/Health points gained per ETH (1 ETH gives 1000 points)
    uint256 public revivalCostMultiplier = 2; // Multiplier for revival cost based on energy/health deficit
    uint256 public mutationProposalDeposit = 0.01 ether; // ETH required to propose a mutation
    uint256 public mutationVotingPeriod = 3 days; // Duration for mutation proposals to be voted on
    uint256 public mutationSuccessThreshold = 3; // Minimum 'for' votes for a mutation to pass
    uint256 public replicationEnergyCost = 5000; // Base energy needed from each parent for replication
    uint256 public interSynapseEnergyCost = 500; // Base energy needed from each Nexus for inter-Nexus synapse
    uint252 public minReplicationAdaptationLevel = 50; // Minimum adaptation level required for a Nexus to replicate
    uint256 public protocolVotingPeriod = 7 days; // Duration for global protocol parameter change proposals

    // Flag to ensure only one genesis Nexus is minted
    bool private _genesisMinted = false;

    // --- Events ---

    event NexusBorn(uint256 indexed tokenId, address indexed owner, uint256 generation);
    event NexusNourished(uint256 indexed tokenId, address indexed nourisher, uint256 amountEth, int256 newEnergy, int256 newHealth);
    event NexusDormant(uint256 indexed tokenId, int256 finalEnergy, int256 finalHealth);
    event NexusRevived(uint256 indexed tokenId, address indexed reviver, uint256 revivalCost);
    event MutationProposed(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer, string description);
    event MutationVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event MutationExecuted(uint256 indexed proposalId, uint256 indexed tokenId, bool success);
    event NexusReplicated(uint256 indexed newNexusId, uint256 indexed parent1Id, uint256 indexed parent2Id, address indexed owner);
    event InterNexusSynapseCompleted(uint256 indexed tokenIdA, uint256 indexed tokenIdB, int256 energyTransfer, int256 adaptationBoostA, int256 adaptationBoostB);
    event ProtocolParameterChangeProposed(uint255 indexed proposalId, ProtocolParamType indexed paramType, int256 newValue, string description);
    event ProtocolParameterChangeVoted(uint255 indexed proposalId, address indexed voter, bool support);
    event ProtocolParameterChangeExecuted(uint255 indexed proposalId, ProtocolParamType indexed paramType, int256 newValue, bool success);
    event TraitChallengeInitiated(uint256 indexed challengeId, uint256 indexed tokenId, uint256 traitIndex, address indexed challenger);
    event TraitChallengeResolved(uint256 indexed challengeId, uint256 indexed tokenId, uint224 traitIndex, bool success);
    event UserReputationUpdated(address indexed user, uint256 newReputation);

    // --- Constructor ---

    /**
     * @dev Initializes the ERC721 token with a name and symbol, and sets the contract owner.
     */
    constructor() ERC721("ChronosynapseNexus", "CSN") Ownable(msg.sender) {}

    // --- Modifiers ---

    /**
     * @dev Throws if `_tokenId` does not exist or `msg.sender` is not its owner.
     */
    modifier onlyNexusOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "Nexus does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "Caller is not Nexus owner.");
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates and applies energy/health decay to a Nexus based on time elapsed.
     *      Updates the Nexus's status to Dormant if energy or health drops to zero or below.
     * @param tokenId The ID of the Nexus to update.
     * @return The updated status of the Nexus.
     */
    function _updateNexusStatus(uint256 tokenId) internal returns (NexusStatus) {
        NexusEvolvableTraits storage traits = nexusEvolvableTraits[tokenId];
        uint256 timeElapsed = block.timestamp.sub(traits.lastNourishedTimestamp);
        int256 decayAmount = int256(timeElapsed.mul(decayRatePerBlock));

        if (traits.status == NexusStatus.Active && decayAmount > 0) {
            traits.currentEnergy = traits.currentEnergy.sub(decayAmount);
            traits.currentHealth = traits.currentHealth.sub(decayAmount / 2); // Health decays slower
            traits.lastNourishedTimestamp = block.timestamp;

            if (traits.currentEnergy <= 0 || traits.currentHealth <= 0) {
                traits.status = NexusStatus.Dormant;
                emit NexusDormant(tokenId, traits.currentEnergy, traits.currentHealth);
            }
        }
        return traits.status;
    }

    /**
     * @dev Generates pseudo-random DNA traits for a new Nexus.
     * @param seed A unique seed value for randomness (e.g., tokenId).
     * @return A NexusDNA struct with randomized values.
     */
    function _generateRandomDNA(uint256 seed) internal pure returns (NexusDNA memory) {
        // Using block.timestamp and msg.sender in `keccak256` for pseudo-randomness.
        // This is not truly decentralized randomness and should not be used for high-stakes games.
        return NexusDNA({
            baseResilience: (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % 100) + 1, // 1-100
            maxEnergyCapacity: (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, "energy")))) % 5000 + 1000, // 1000-6000
            replicationCostFactor: (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, "rep")))) % 5 + 1, // 1-5
            mutationAdaptability: (uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, "mut")))) % 100 + 1, // 1-100
            genesisTimestamp: block.timestamp
        });
    }

    /**
     * @dev Internal function to update a user's on-chain reputation score.
     * @param user The address whose reputation is to be updated.
     * @param amount The amount to add to the user's reputation.
     */
    function _updateUserReputation(address user, uint256 amount) internal {
        userReputation[user] = userReputation[user].add(amount);
        emit UserReputationUpdated(user, userReputation[user]);
    }

    // --- I. Core Nexus Management (ERC721 & Custom) ---

    /**
     * @dev Mints the very first Genesis Nexus. Can only be called once by the contract owner.
     * @param recipient The address that will receive the Genesis Nexus NFT.
     */
    function safeMintGenesisNexus(address recipient) public onlyOwner {
        require(!_genesisMinted, "Genesis Nexus already minted.");
        _genesisMinted = true;

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        _safeMint(recipient, newId);

        NexusDNA memory newDNA = _generateRandomDNA(newId);
        nexusDNA[newId] = newDNA;

        nexusEvolvableTraits[newId] = NexusEvolvableTraits({
            currentEnergy: int256(newDNA.maxEnergyCapacity), // Starts with full energy
            currentHealth: int256(newDNA.baseResilience.mul(10)), // Initial health based on resilience
            adaptationLevel: 10, // Initial adaptation level
            lastNourishedTimestamp: block.timestamp,
            generation: 0, // Genesis Nexus is generation 0
            mutationProgressCount: 0,
            synapseCount: 0,
            status: NexusStatus.Active
        });

        emit NexusBorn(newId, recipient, 0);
    }

    /**
     * @dev Retrieves the immutable DNA traits of a specific Nexus.
     * @param tokenId The ID of the Nexus.
     * @return A tuple containing all DNA traits.
     */
    function getNexusDNA(uint256 tokenId) public view returns (
        uint256 baseResilience,
        uint256 maxEnergyCapacity,
        uint256 replicationCostFactor,
        uint256 mutationAdaptability,
        uint256 genesisTimestamp
    ) {
        require(_exists(tokenId), "Nexus does not exist.");
        NexusDNA storage dna = nexusDNA[tokenId];
        return (
            dna.baseResilience,
            dna.maxEnergyCapacity,
            dna.replicationCostFactor,
            dna.mutationAdaptability,
            dna.genesisTimestamp
        );
    }

    /**
     * @dev Retrieves the current mutable Evolvable Traits of a specific Nexus.
     *      Includes a simulation of decay for the view function to reflect current state.
     * @param tokenId The ID of the Nexus.
     * @return A tuple containing all Evolvable Traits.
     */
    function getNexusEvolvableTraits(uint256 tokenId) public view returns (
        int256 currentEnergy,
        int256 currentHealth,
        uint256 adaptationLevel,
        uint256 lastNourishedTimestamp,
        uint256 generation,
        uint256 mutationProgressCount,
        uint256 synapseCount,
        NexusStatus status
    ) {
        require(_exists(tokenId), "Nexus does not exist.");
        NexusEvolvableTraits storage traits = nexusEvolvableTraits[tokenId];
        
        // Simulate decay for accurate view, but do not modify state
        uint256 timeElapsed = block.timestamp.sub(traits.lastNourishedTimestamp);
        int256 simulatedDecay = int256(timeElapsed.mul(decayRatePerBlock));

        int256 simEnergy = traits.currentEnergy;
        int256 simHealth = traits.currentHealth;
        NexusStatus simStatus = traits.status;

        if (traits.status == NexusStatus.Active && simulatedDecay > 0) {
            simEnergy = simEnergy.sub(simulatedDecay);
            simHealth = simHealth.sub(simulatedDecay / 2);
            if (simEnergy <= 0 || simHealth <= 0) {
                simStatus = NexusStatus.Dormant;
            }
        }

        return (
            simEnergy,
            simHealth,
            traits.adaptationLevel,
            traits.lastNourishedTimestamp,
            traits.generation,
            traits.mutationProgressCount,
            traits.synapseCount,
            simStatus
        );
    }

    /**
     * @dev Feeds a Nexus with ETH, increasing its energy and health.
     *      Also updates the last nourishment timestamp and potentially reactivates a dormant Nexus.
     * @param tokenId The ID of the Nexus to nourish.
     */
    function nourishNexus(uint256 tokenId) public payable {
        require(_exists(tokenId), "Nexus does not exist.");
        require(msg.value > 0, "Nourishment requires ETH.");

        _updateNexusStatus(tokenId); // Apply decay before nourishment
        NexusEvolvableTraits storage traits = nexusEvolvableTraits[tokenId];
        NexusDNA storage dna = nexusDNA[tokenId];

        uint256 nourishmentAmount = msg.value.mul(nourishmentValuePerEth);
        int256 addedEnergy = int256(nourishmentAmount);
        int256 addedHealth = int256(nourishmentAmount.div(2)); // Health bonus half of energy

        traits.currentEnergy = traits.currentEnergy.add(addedEnergy);
        traits.currentHealth = traits.currentHealth.add(addedHealth);

        // Cap energy and health at max capacity defined by DNA
        if (traits.currentEnergy > int256(dna.maxEnergyCapacity)) {
            traits.currentEnergy = int256(dna.maxEnergyCapacity);
        }
        if (traits.currentHealth > int256(dna.maxEnergyCapacity)) { // Using maxEnergyCapacity as health cap for simplicity
            traits.currentHealth = int256(dna.maxEnergyCapacity);
        }

        // If it was dormant and now has positive energy/health, reactivate
        if (traits.status == NexusStatus.Dormant && traits.currentEnergy > 0 && traits.currentHealth > 0) {
            traits.status = NexusStatus.Active;
        }

        traits.lastNourishedTimestamp = block.timestamp;
        _updateUserReputation(msg.sender, msg.value / 10**14); // Simple reputation based on ETH, 0.0001 ETH = 1 rep
        emit NexusNourished(tokenId, msg.sender, msg.value, traits.currentEnergy, traits.currentHealth);
    }

    /**
     * @dev Revives a Nexus that has entered a dormant state, requiring a fee based on its deficit.
     * @param tokenId The ID of the dormant Nexus to revive.
     */
    function reviveDormantNexus(uint256 tokenId) public payable {
        require(_exists(tokenId), "Nexus does not exist.");
        _updateNexusStatus(tokenId); // Ensure status is up-to-date
        NexusEvolvableTraits storage traits = nexusEvolvableTraits[tokenId];

        require(traits.status == NexusStatus.Dormant, "Nexus is not dormant.");
        // Revival requires currentEnergy and currentHealth to be <= 0.
        require(traits.currentEnergy <= 0, "Nexus still has positive energy.");
        require(traits.currentHealth <= 0, "Nexus still has positive health.");

        // Calculate revival cost based on absolute deficit
        uint256 energyDeficit = uint256(traits.currentEnergy * -1);
        uint256 healthDeficit = uint256(traits.currentHealth * -1);
        uint256 revivalCost = energyDeficit.add(healthDeficit).mul(revivalCostMultiplier);
        
        // Ensure a minimum revival cost to avoid tiny values
        if (revivalCost < 0.001 ether) revivalCost = 0.001 ether; 

        require(msg.value >= revivalCost, string(abi.encodePacked("Insufficient ETH to revive Nexus. Required: ", Strings.toString(revivalCost), " wei")));

        // Restore to a base positive state
        traits.currentEnergy = 100;
        traits.currentHealth = 100;
        traits.status = NexusStatus.Active;
        traits.lastNourishedTimestamp = block.timestamp;

        _updateUserReputation(msg.sender, revivalCost / 10**14);
        emit NexusRevived(tokenId, msg.sender, revivalCost);
    }

    /**
     * @dev Allows a user to propose a mutation (change) to a Nexus's evolvable traits.
     *      Requires an ETH deposit which is held by the contract.
     * @param tokenId The ID of the Nexus to propose a mutation for.
     * @param energyChange The proposed change to currentEnergy.
     * @param healthChange The proposed change to currentHealth.
     * @param adaptationChange The proposed change to adaptationLevel.
     * @param description A description of the mutation proposal.
     */
    function proposeMutation(
        uint256 tokenId,
        int256 energyChange,
        int256 healthChange,
        int256 adaptationChange,
        string memory description
    ) public payable {
        require(_exists(tokenId), "Nexus does not exist.");
        require(msg.value >= mutationProposalDeposit, "Insufficient deposit for mutation proposal.");
        require(bytes(description).length > 0, "Description cannot be empty.");

        uint256 proposalId = _mutationProposalCounter.current();
        _mutationProposalCounter.increment();

        mutationProposals[proposalId] = MutationProposal({
            tokenId: tokenId,
            proposedEnergyChange: energyChange,
            proposedHealthChange: healthChange,
            proposedAdaptationChange: adaptationChange,
            description: description,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(mutationVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            exists: true // Mark as existing
        });
        // The deposit ETH remains in the contract's balance, becoming part of its treasury.

        emit MutationProposed(proposalId, tokenId, msg.sender, description);
    }

    /**
     * @dev Casts a vote (for or against) on an active mutation proposal.
     * @param proposalId The ID of the mutation proposal.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnMutation(uint256 proposalId, bool support) public {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.exists, "Mutation proposal does not exist.");
        require(block.timestamp <= proposal.endTimestamp, "Voting period has ended.");
        require(!proposal.executed, "Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal.");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit MutationVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a successfully voted-on mutation proposal.
     *      Applies trait changes if the proposal meets the success threshold.
     * @param proposalId The ID of the mutation proposal to execute.
     */
    function executeMutation(uint256 proposalId) public {
        MutationProposal storage proposal = mutationProposals[proposalId];
        require(proposal.exists, "Mutation proposal does not exist.");
        require(block.timestamp > proposal.endTimestamp, "Voting period has not ended.");
        require(!proposal.executed, "Proposal already executed.");

        _updateNexusStatus(proposal.tokenId); // Ensure Nexus status is updated before mutation
        NexusEvolvableTraits storage traits = nexusEvolvableTraits[proposal.tokenId];

        bool success = false;
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= mutationSuccessThreshold) {
            // Mutation successful: apply changes to Nexus traits
            traits.currentEnergy = traits.currentEnergy.add(proposal.proposedEnergyChange);
            traits.currentHealth = traits.currentHealth.add(proposal.proposedHealthChange);
            // Ensure adaptation level doesn't go below 0, or add a specific floor
            traits.adaptationLevel = traits.adaptationLevel.add(uint256(proposal.proposedAdaptationChange));
            traits.mutationProgressCount = traits.mutationProgressCount.add(1);

            // Reward Nexus owner and the executor for successful mutation
            _updateUserReputation(ownerOf(proposal.tokenId), 50); 
            _updateUserReputation(msg.sender, 10); 
            success = true;
        } else {
            // Mutation failed or did not meet threshold.
            // Proposer's deposit is lost to the protocol treasury in this simple model.
        }

        proposal.executed = true;
        emit MutationExecuted(proposalId, proposal.tokenId, success);
    }

    /**
     * @dev Allows two active Nexuses to "replicate," spawning a new Nexus (offspring).
     *      Requires both parents to be active, have sufficient adaptation levels and energy.
     * @param parentTokenId1 The ID of the first parent Nexus.
     * @param parentTokenId2 The ID of the second parent Nexus.
     */
    function replicateNexus(uint256 parentTokenId1, uint256 parentTokenId2) public {
        require(_exists(parentTokenId1) && _exists(parentTokenId2), "One or both parent Nexuses do not exist.");
        require(ownerOf(parentTokenId1) == msg.sender || ownerOf(parentTokenId2) == msg.sender, "Caller must own at least one parent Nexus.");
        require(parentTokenId1 != parentTokenId2, "Cannot replicate with the same Nexus.");

        _updateNexusStatus(parentTokenId1);
        _updateNexusStatus(parentTokenId2);

        NexusEvolvableTraits storage traits1 = nexusEvolvableTraits[parentTokenId1];
        NexusEvolvableTraits storage traits2 = nexusEvolvableTraits[parentTokenId2];
        NexusDNA storage dna1 = nexusDNA[parentTokenId1];
        NexusDNA storage dna2 = nexusDNA[parentTokenId2];

        require(traits1.status == NexusStatus.Active && traits2.status == NexusStatus.Active, "Both parents must be active.");
        require(traits1.adaptationLevel >= minReplicationAdaptationLevel && traits2.adaptationLevel >= minReplicationAdaptationLevel, "Parents must have sufficient adaptation level to replicate.");

        // Calculate combined cost and check energy
        uint256 combinedReplicationCost = replicationEnergyCost.mul(dna1.replicationCostFactor.add(dna2.replicationCostFactor)).div(2);
        require(traits1.currentEnergy >= int256(combinedReplicationCost / 2) && traits2.currentEnergy >= int256(combinedReplicationCost / 2), "Insufficient energy in parents for replication.");

        // Consume energy from parents
        traits1.currentEnergy = traits1.currentEnergy.sub(int256(combinedReplicationCost / 2));
        traits2.currentEnergy = traits2.currentEnergy.sub(int256(combinedReplicationCost / 2));

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();
        address newNexusOwner = msg.sender; // Owner of new Nexus is the caller

        _safeMint(newNexusOwner, newId);

        // Simple inheritance: Average DNA traits, increment generation
        NexusDNA memory newDNA = NexusDNA({
            baseResilience: (dna1.baseResilience.add(dna2.baseResilience)).div(2),
            maxEnergyCapacity: (dna1.maxEnergyCapacity.add(dna2.maxEnergyCapacity)).div(2),
            replicationCostFactor: (dna1.replicationCostFactor.add(dna2.replicationCostFactor)).div(2),
            mutationAdaptability: (dna1.mutationAdaptability.add(dna2.mutationAdaptability)).div(2),
            genesisTimestamp: block.timestamp
        });
        nexusDNA[newId] = newDNA;

        nexusEvolvableTraits[newId] = NexusEvolvableTraits({
            currentEnergy: int256(newDNA.maxEnergyCapacity / 2), // Child starts with half energy
            currentHealth: int256(newDNA.baseResilience.mul(5)), // Child starts with base health
            adaptationLevel: (traits1.adaptationLevel.add(traits2.adaptationLevel)).div(2).div(2), // Child starts with lower adaptation than parents
            lastNourishedTimestamp: block.timestamp,
            generation: Math.max(traits1.generation, traits2.generation).add(1),
            mutationProgressCount: 0,
            synapseCount: 0,
            status: NexusStatus.Active
        });

        _updateUserReputation(msg.sender, 20); // Reward for facilitating replication
        emit NexusReplicated(newId, parentTokenId1, parentTokenId2, newNexusOwner);
    }

    /**
     * @dev Simulates a unique interaction (synapse) between two Nexuses.
     *      Consumes energy from both Nexuses and may boost their adaptation levels or transfer energy.
     * @param tokenIdA The ID of the first Nexus in the synapse.
     * @param tokenIdB The ID of the second Nexus in the synapse.
     */
    function initiateInterNexusSynapse(uint256 tokenIdA, uint256 tokenIdB) public {
        require(_exists(tokenIdA) && _exists(tokenIdB), "One or both Nexuses do not exist.");
        require(ownerOf(tokenIdA) == msg.sender || ownerOf(tokenIdB) == msg.sender, "Caller must own at least one Nexus.");
        require(tokenIdA != tokenIdB, "Cannot synapse with itself.");

        _updateNexusStatus(tokenIdA);
        _updateNexusStatus(tokenIdB);

        NexusEvolvableTraits storage traitsA = nexusEvolvableTraits[tokenIdA];
        NexusEvolvableTraits storage traitsB = nexusEvolvableTraits[tokenIdB];

        require(traitsA.status == NexusStatus.Active && traitsB.status == NexusStatus.Active, "Both Nexuses must be active.");
        require(traitsA.currentEnergy >= int256(interSynapseEnergyCost) && traitsB.currentEnergy >= int256(interSynapseEnergyCost), "Both Nexuses need energy for synapse.");

        // Consume energy for the interaction
        traitsA.currentEnergy = traitsA.currentEnergy.sub(int256(interSynapseEnergyCost));
        traitsB.currentEnergy = traitsB.currentEnergy.sub(int256(interSynapseEnergyCost));

        // Simulate positive outcome: small adaptation boost and potential energy transfer
        int256 energyTransfer = 0;
        if (traitsA.currentEnergy > traitsB.currentEnergy) {
            energyTransfer = (traitsA.currentEnergy - traitsB.currentEnergy) / 4; // Transfer 25% of difference
            traitsA.currentEnergy = traitsA.currentEnergy.sub(energyTransfer);
            traitsB.currentEnergy = traitsB.currentEnergy.add(energyTransfer);
        } else if (traitsB.currentEnergy > traitsA.currentEnergy) {
            energyTransfer = (traitsB.currentEnergy - traitsA.currentEnergy) / 4;
            traitsB.currentEnergy = traitsB.currentEnergy.sub(energyTransfer);
            traitsA.currentEnergy = traitsA.currentEnergy.add(energyTransfer);
        }

        traitsA.adaptationLevel = traitsA.adaptationLevel.add(1);
        traitsB.adaptationLevel = traitsB.adaptationLevel.add(1);
        traitsA.synapseCount = traitsA.synapseCount.add(1);
        traitsB.synapseCount = traitsB.synapseCount.add(1);

        _updateUserReputation(msg.sender, 5); // Reward for facilitating synapse
        emit InterNexusSynapseCompleted(tokenIdA, tokenIdB, energyTransfer, 1, 1);
    }

    /**
     * @dev Retrieves details about a specific mutation proposal.
     * @param proposalId The ID of the mutation proposal.
     * @return A tuple containing all details of the mutation proposal.
     */
    function getMutationProposal(uint256 proposalId) public view returns (
        uint256 tokenId,
        int256 proposedEnergyChange,
        int256 proposedHealthChange,
        int256 proposedAdaptationChange,
        string memory description,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool exists
    ) {
        MutationProposal storage proposal = mutationProposals[proposalId];
        return (
            proposal.tokenId,
            proposal.proposedEnergyChange,
            proposal.proposedHealthChange,
            proposal.proposedAdaptationChange,
            proposal.description,
            proposal.startTimestamp,
            proposal.endTimestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.exists
        );
    }

    /**
     * @dev Retrieves the timestamp of the last nourishment for a Nexus.
     *      This is a simplified "historical log" due to gas cost constraints of on-chain arrays.
     *      More complex history would require off-chain indexing.
     * @param tokenId The ID of the Nexus.
     * @return The timestamp of the last time the Nexus was nourished.
     */
    function getNexusHistoricalEnergyLog(uint256 tokenId) public view returns (uint256 lastNourishedTimestamp) {
        require(_exists(tokenId), "Nexus does not exist.");
        return nexusEvolvableTraits[tokenId].lastNourishedTimestamp;
    }

    // --- II. Protocol Governance & Administration ---

    /**
     * @dev Allows the contract owner (or a designated governance module) to propose changes
     *      to global protocol parameters.
     * @param paramType The type of parameter to change (from `ProtocolParamType` enum).
     * @param newValue The new value to set for the parameter.
     * @param description A description of the proposed change.
     */
    function proposeProtocolParameterChange(
        ProtocolParamType paramType,
        int256 newValue,
        string memory description
    ) public onlyOwner { // Currently onlyOwner, but can be expanded to Nexus token holder voting or a separate DAO.
        require(bytes(description).length > 0, "Description cannot be empty.");

        uint256 proposalId = _protocolChangeProposalCounter.current();
        _protocolChangeProposalCounter.increment();

        protocolChangeProposals[proposalId] = ProtocolChangeProposal({
            paramType: paramType,
            newValue: newValue,
            description: description,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(protocolVotingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            exists: true
        });

        emit ProtocolParameterChangeProposed(proposalId, paramType, newValue, description);
    }

    /**
     * @dev Casts a vote (for or against) on a global protocol parameter change proposal.
     * @param proposalId The ID of the protocol change proposal.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProtocolChange(uint256 proposalId, bool support) public {
        ProtocolChangeProposal storage proposal = protocolChangeProposals[proposalId];
        require(proposal.exists, "Protocol change proposal does not exist.");
        require(block.timestamp <= proposal.endTimestamp, "Voting period has ended.");
        require(!proposal.executed, "Proposal already executed.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this protocol change.");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProtocolParameterChangeVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a successfully voted-on protocol parameter change.
     *      Applies the new parameter value if the proposal meets the success threshold.
     * @param proposalId The ID of the protocol change proposal to execute.
     */
    function executeProtocolParameterChange(uint256 proposalId) public {
        ProtocolChangeProposal storage proposal = protocolChangeProposals[proposalId];
        require(proposal.exists, "Protocol change proposal does not exist.");
        require(block.timestamp > proposal.endTimestamp, "Voting period has not ended.");
        require(!proposal.executed, "Proposal already executed.");

        bool success = false;
        // Using mutationSuccessThreshold for protocol changes for simplicity
        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= mutationSuccessThreshold) {
            setProtocolParam(proposal.paramType, proposal.newValue); // Directly apply the change
            success = true;
        }

        proposal.executed = true;
        emit ProtocolParameterChangeExecuted(proposalId, proposal.paramType, proposal.newValue, success);
    }

    /**
     * @dev Directly sets a protocol parameter. Intended for use by `executeProtocolParameterChange`
     *      or for initial setup/emergency by the owner.
     * @param paramType The type of parameter to set.
     * @param newValue The new value for the parameter.
     */
    function setProtocolParam(ProtocolParamType paramType, int256 newValue) public onlyOwner {
        require(newValue >= 0, "Parameter value cannot be negative."); 

        if (paramType == ProtocolParamType.DecayRatePerBlock) {
            decayRatePerBlock = uint256(newValue);
        } else if (paramType == ProtocolParamType.NourishmentValuePerEth) {
            nourishmentValuePerEth = uint256(newValue);
        } else if (paramType == ProtocolParamType.RevivalCostMultiplier) {
            revivalCostMultiplier = uint256(newValue);
        } else if (paramType == ProtocolParamType.MutationProposalDeposit) {
            mutationProposalDeposit = uint256(newValue);
        } else if (paramType == ProtocolParamType.MutationVotingPeriod) {
            mutationVotingPeriod = uint256(newValue);
        } else if (paramType == ProtocolParamType.MutationSuccessThreshold) {
            mutationSuccessThreshold = uint256(newValue);
        } else if (paramType == ProtocolParamType.ReplicationEnergyCost) {
            replicationEnergyCost = uint256(newValue);
        } else if (paramType == ProtocolParamType.InterSynapseEnergyCost) {
            interSynapseEnergyCost = uint256(newValue);
        } else if (paramType == ProtocolParamType.MinReplicationAdaptationLevel) {
            minReplicationAdaptationLevel = uint256(newValue);
        } else if (paramType == ProtocolParamType.ProtocolVotingPeriod) {
            protocolVotingPeriod = uint256(newValue);
        }
        // No explicit event for direct setting, as governance proposals have their own events.
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated ETH fees from the contract's balance.
     *      These fees typically come from mutation proposal deposits and revival fees.
     */
    function withdrawProtocolFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw.");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Failed to withdraw ETH.");
    }

    // --- III. User Reputation & External Integration (Conceptual) ---

    /**
     * @dev Retrieves a user's on-chain reputation score.
     * @param user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    /**
     * @dev Initiates a conceptual challenge related to a Nexus's trait.
     *      This function is a placeholder for future integration with oracles or complex
     *      off-chain proof systems (e.g., ZK-proofs) to verify external data about a Nexus's traits.
     * @param tokenId The ID of the Nexus whose trait is being challenged.
     * @param traitIndex An arbitrary index representing the specific trait being challenged.
     * @param challengeDataHash A hash of off-chain proof data relevant to the challenge.
     */
    function challengeNexusTrait(uint256 tokenId, uint256 traitIndex, bytes32 challengeDataHash) public {
        require(_exists(tokenId), "Nexus does not exist.");
        // In a full implementation, there would be a challenge deposit and specific rules.

        uint256 challengeId = _challengeCounter.current();
        _challengeCounter.increment();

        traitChallenges[challengeId] = TraitChallenge({
            tokenId: tokenId,
            traitIndex: traitIndex,
            challengeDataHash: challengeDataHash,
            challenger: msg.sender,
            resolved: false,
            success: false,
            challengeTimestamp: block.timestamp
        });

        emit TraitChallengeInitiated(challengeId, tokenId, traitIndex, msg.sender);
    }

    /**
     * @dev Resolves a previously initiated trait challenge.
     *      This function would typically be called by an Oracle contract or the contract owner/governance
     *      after off-chain verification.
     * @param tokenId The ID of the Nexus involved in the challenge.
     * @param traitIndex The index of the trait challenged.
     * @param success The outcome of the challenge (true if challenger's claim is valid).
     * @param challengeId The ID of the challenge to resolve.
     */
    function resolveTraitChallenge(uint256 tokenId, uint256 traitIndex, bool success, uint256 challengeId) public onlyOwner { // Simplified to onlyOwner for resolution
        TraitChallenge storage challenge = traitChallenges[challengeId];
        require(challenge.tokenId == tokenId && challenge.traitIndex == traitIndex, "Challenge ID mismatch or invalid.");
        require(!challenge.resolved, "Challenge already resolved.");

        challenge.resolved = true;
        challenge.success = success;

        if (success) {
            NexusEvolvableTraits storage traits = nexusEvolvableTraits[tokenId];
            // Example: If a challenge on "adaptationLevel" (arbitrary index 1) is successful, boost it.
            if (traitIndex == 1) { 
                traits.adaptationLevel = traits.adaptationLevel.add(10);
                _updateUserReputation(challenge.challenger, 30); // Reward challenger
            }
        } else {
            // Optionally, penalize challenger by keeping their deposit or reducing reputation.
        }
        emit TraitChallengeResolved(challengeId, tokenId, traitIndex, success);
    }

    // --- IV. Inherited ERC721 & View Functions ---

    // 22. balanceOf(address owner) - inherited from ERC721Enumerable
    // 23. ownerOf(uint256 tokenId) - inherited from ERC721Enumerable
    // 24. safeTransferFrom(address from, address to, uint256 tokenId) - inherited from ERC721Enumerable
    // 25. approve(address to, uint256 tokenId) - inherited from ERC721Enumerable
    // 26. isApprovedForAll(address owner, address operator) - inherited from ERC721Enumerable
    // Other inherited: transferFrom, getApproved, setApprovalForAll, totalSupply, tokenOfOwnerByIndex, tokenByIndex, supportsInterface

    /**
     * @dev Overrides `tokenURI` to provide a dynamic URI for Nexus metadata.
     *      In a live deployment, this URI would point to an API endpoint that generates
     *      JSON metadata reflecting the Nexus's current dynamic traits.
     * @param tokenId The ID of the Nexus.
     * @return A string representing the URI for the token's metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // This example URI would point to an API that dynamically generates metadata
        // based on the Nexus's `NexusEvolvableTraits`.
        return string(abi.encodePacked("https://chronosynapsenexus.com/api/metadata/", Strings.toString(tokenId)));
    }
}
```