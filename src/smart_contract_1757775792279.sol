Here's a Solidity smart contract for a "Self-Evolving Decentralized Autonomous Ecosystem (SEDAE)" called **Chronos Protocol: Sentient Ecosystem Genesis (SEG)**. This contract implements a dynamic NFT (dNFT) system where "Sentients" (dNFTs) can evolve, mutate, replicate, and interact within a simulated ecosystem driven by an internal Energy Flux (EFL) token, a reputation-based governance model, and external oracle data.

This contract features over 20 unique and advanced functions, carefully designed to avoid direct duplication of existing open-source projects by combining elements of dNFTs, on-chain governance, resource management, and simulated environmental interaction into a cohesive, novel ecosystem.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For potentially generating tokenURI dynamically

// Outline for ChronosSentientGenesis.sol

// I. Core Infrastructure & Access Control
//    - Contract Initialization and Ownership Management.
//    - Basic NFT Minting for Genesis Seeds (the initial state of Sentient dNFTs).
//    - Oracle Registration and Management for external data input.

// II. Sentient Evolution & State Management (Dynamic NFTs)
//    - Functions governing the evolution, mutation, and progression of Sentients through different ranks.
//    - Mechanisms for Sentient replication (creating new dNFTs) and influence decay (wisdom reduction for inactivity).
//    - Internal tracking of Sentient traits, rank, and their dynamic state.

// III. Ecosystem Governance & Parameters
//    - A decentralized proposal and voting system for Sentient holders to influence ecosystem rules.
//    - Execution of approved governance proposals to update core ecosystem parameters.
//    - Integration with external oracles, allowing environmental data input to influence ecosystem dynamics.

// IV. Energy Flux (EFL) Token & Resource Economy
//    - An internal token (EFL) serving as the primary energy source for Sentient actions and ecosystem interactions.
//    - Mechanisms for claiming passively generated EFL, allocating it to Sentients, and synthesizing specialized resources.
//    - Advanced resource interaction including consumption for benefits and strategic 'siphoning' between Sentients.

// V. Wisdom & Reputation System
//    - A system for Sentients to earn and lose "Wisdom Score" (reputation) based on their actions and contributions.
//    - Mechanisms for challenging a Sentient's Wisdom Score (conceptual dispute resolution).
//    - Strategic "attunement" of Sentients to specific ecosystem zones for specialized roles and benefits.

// VI. View Functions
//    - Read-only functions to query detailed Sentient data, current ecosystem state, proposal details, and token balances.

// --- Function Summary ---

// I. Core Infrastructure & Access Control
// 1.  constructor(): Initializes the contract, sets the deployer as owner, and defines initial global ecosystem parameters.
// 2.  mintGenesisSeed(address _owner): Mints a new "Genesis Seed" (the initial, unevolved state of a Sentient dNFT) to the specified owner, assigning initial traits and wisdom.
// 3.  setOracleAddress(address _oracle): Grants a specific address the permission to submit oracle data to the contract. Callable only by the contract owner.
// 4.  renounceOwnership(): Standard OpenZeppelin Ownable function. Transfers ownership of the contract to the zero address, making it immutable (unowned).

// II. Sentient Evolution & State Management (Dynamic NFTs)
// 5.  evolveSentient(uint256 _tokenId): Triggers an evolution attempt for a specific Sentient. This action consumes Energy Flux (EFL) and its outcome (e.g., trait mutation, wisdom gain) depends on Sentient traits, current oracle data, and global ecosystem parameters.
// 6.  mutateSentientTrait(uint256 _tokenId, SentientTrait _trait, uint8 _newValue): Allows a Sentient's owner to attempt to mutate a specific trait towards a desired new value. This consumes resources or EFL, with success influenced by ecosystem rules and Sentient attributes.
// 7.  ascendSentientRank(uint256 _tokenId): Promotes a Sentient to a higher conceptual "rank" or "form" (e.g., from Seed to Sprout, then Pioneer) if it meets specific, predefined criteria such as wisdom score, trait thresholds, and resource requirements.
// 8.  decaySentientInfluence(uint256 _tokenId): A maintenance function that periodically reduces a Sentient's Wisdom Score if it has remained inactive (no major actions like evolution or resource consumption) for an extended period, designed to encourage continuous engagement.
// 9.  replicateSentient(uint256 _parentId, address _newOwner): An advanced function allowing a highly evolved and wise "Architect" Sentient to consume significant resources and EFL to "replicate" a new Genesis Seed for a chosen owner, fostering ecosystem expansion.

// III. Ecosystem Governance & Parameters
// 10. proposeEcosystemParameterChange(string memory _description, bytes32 _parameterKey, uint256 _newValue): Empowers Sentient holders with sufficient Wisdom Score to propose changes to global ecosystem parameters (e.g., evolution difficulty, EFL generation rates).
// 11. voteOnProposal(uint256 _proposalId, bool _support): Enables Sentient holders to cast their vote on an active governance proposal. Their voting power is directly weighted by their Sentient's accumulated Wisdom Score, promoting meritocratic governance.
// 12. executeProposal(uint256 _proposalId): Finalizes a proposal that has successfully met quorum requirements and passed the voting threshold. If successful, the proposed parameter changes are applied to the ecosystem.
// 13. submitOracleData(bytes32 _dataType, uint256 _value): Allows a registered oracle to submit external "environmental" data (e.g., "Cosmic Radiation Level", "Resource Scarcity Index"). This data directly influences various ecosystem mechanics and Sentient states.

// IV. Energy Flux (EFL) Token & Resource Economy
// 14. claimEnergyFlux(uint256 _tokenId): Allows a Sentient's owner to claim passively generated Energy Flux tokens that have accumulated over time due to their Sentient's existence and rank.
// 15. allocateEnergyToSentient(uint256 _tokenId, uint256 _amount): Transfers a specified amount of Energy Flux tokens from the caller's personal balance to a specific Sentient. This EFL can then be used by the Sentient for actions like evolution or resource synthesis.
// 16. synthesizeResource(uint256 _tokenId, ResourceType _resourceType, uint256 _amount): Allows a Sentient with specific prerequisite traits to convert Energy Flux into distinct "Synthesized Resources" (e.g., "Chronos Dust", "Bio-Essence"), which are essential for advanced actions.
// 17. consumeResourceForBenefit(uint256 _tokenId, ResourceType _resourceType): Enables a Sentient to consume one unit of a specific Synthesized Resource to gain a temporary boost, unlock a new ability, or progress in a unique way specific to that resource type.
// 18. siphonEnergyFromSentient(uint256 _siphonerId, uint256 _targetTokenId, uint256 _amount): An advanced, strategic, and potentially high-risk interaction where a high-rank Sentient (or its owner) can attempt to siphon Energy Flux from a lower-rank Sentient, subject to strict ecosystem rules, wisdom differences, and a chance of failure.

// V. Wisdom & Reputation System
// 19. earnWisdomPoints(uint256 _tokenId, uint256 _points): Awards a specified amount of Wisdom Score points to a Sentient for achieving milestones, successful contributions (e.g., passing a vote), or active participation within the ecosystem.
// 20. challengeWisdomScore(uint256 _tokenId, string memory _reason): Initiates a formal challenge against a Sentient's Wisdom Score. This requires a financial stake and conceptually could lead to a community vote or oracle arbitration to verify the score's legitimacy.
// 21. attuneSentient(uint256 _tokenId, EcosystemZone _zone): Allows an owner to 'attune' a Sentient to a specific "Ecosystem Zone" (e.g., TemporalNexus). This attunement can alter its trait development, resource yields, or vulnerability to environmental factors based on that zone's unique parameters.

// VI. View Functions (Examples, a complete DApp would have more)
// 22. getSentientDetails(uint256 _tokenId): Returns comprehensive data for a specific Sentient, including its traits, rank, wisdom, last activity, energy balance, and attuned zone.
// 23. getEnergyFluxBalance(address _owner): Returns the total Energy Flux (EFL) token balance held by a specific user wallet.
// 24. getProposalDetails(uint256 _proposalId): Returns the full details of a specific governance proposal, including its description, status, voting results, and proposed changes.
// 25. getEcosystemParameter(bytes32 _parameterKey): Returns the current value of a specific global ecosystem parameter (e.g., "EvolutionSuccessChanceBase").
// 26. getTotalSupply(): Standard ERC721 function, returns the total number of minted Sentients.
// 27. tokenURI(uint256 _tokenId): Standard ERC721 function, returns the URI for a given Sentient's metadata (pointing to off-chain JSON).
// 28. balanceOf(address _owner): Standard ERC721 function, returns the number of Sentients owned by a given address.
// 29. ownerOf(uint256 _tokenId): Standard ERC721 function, returns the owner of a specific Sentient NFT.

// Custom error definitions for gas efficiency and clearer error handling
error SentientNotFound(uint256 tokenId);
error NotSentientOwner(uint256 tokenId, address caller);
error InsufficientEnergy(address caller, uint256 required, uint256 available);
error InvalidParameterKey(bytes32 parameterKey);
error InsufficientWisdom(uint256 tokenId, uint256 required, uint256 available);
error ProposalNotFound(uint256 proposalId);
error ProposalNotActive(uint256 proposalId);
error ProposalNotExecutable(uint256 proposalId);
error AlreadyVoted(uint256 proposalId, address voter);
error UnauthorizedOracle(address caller);
error InsufficientResource(uint256 tokenId, bytes32 resourceType, uint256 required, uint256 available);
error InvalidTraitValue(SentientTrait trait, uint8 value);
error SentientNotReadyForAscension(uint256 tokenId);
error SentientNotEligibleForReplication(uint256 tokenId);
error NotEnoughEFLForSiphon(uint256 targetTokenId, uint256 requested, uint256 available);
error SiphonConditionsNotMet(uint256 siphonerId, uint256 targetId);
error WisdomChallengeInProgress(uint256 tokenId); // For a more advanced challenge system
error InvalidEcosystemZone(EcosystemZone zone);
error SentientAlreadyAttuned(uint256 tokenId, EcosystemZone zone);

contract ChronosSentientGenesis is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Enums and Structs ---

    // Define different dynamic traits a Sentient can possess
    enum SentientTrait {
        Adaptability, // Ability to respond to environmental changes
        Resilience,   // Resistance to negative influences or decay
        Curiosity,    // Drive for exploration, knowledge, and resource discovery
        Aggression,   // Influence on other sentients, or resource acquisition efficiency
        Empathy       // Cooperative potential, or resistance to aggressive acts
    }

    // Define the conceptual ranks/stages of a Sentient's evolution
    enum SentientRank {
        Seed,       // Initial, nascent state
        Sprout,     // Basic evolved state, showing first signs of specialization
        Pioneer,    // Intermediate state, capable of influencing local environment
        Sage,       // Advanced, wise state, significant influence and knowledge
        Architect   // Highest rank, capable of ecosystem-level actions like replication
    }

    // Define types of synthesized resources
    enum ResourceType {
        ChronosDust, // Used for wisdom boosts or time-related effects
        BioEssence,  // Used for trait mutations or growth
        AetherShard  // Used for energy boosts or unique abilities
    }

    // Define different conceptual zones within the ecosystem a Sentient can attune to
    enum EcosystemZone {
        TemporalNexus, // Zone focusing on time-based effects, wisdom, and data
        VibrantWilds,  // Zone focusing on resource generation, growth, and trait development
        AethericCore   // Zone focusing on energy manipulation, power, and influence
    }

    // Comprehensive structure for a Sentient dNFT
    struct Sentient {
        uint256 tokenId;
        // The actual owner is tracked by ERC721's ownerOf, but having it here can simplify logic
        address owner;
        SentientRank rank;
        uint256 wisdomScore;       // Reputation/Influence score
        uint256 lastActivityTime;  // Timestamp of last major interaction, for decay mechanics
        mapping(SentientTrait => uint8) traits; // Dynamic trait values (0-100)
        mapping(ResourceType => uint256) resources; // Quantities of synthesized resources held
        uint256 energyFluxBalance; // Internal EFL balance, can be allocated by owner
        EcosystemZone attunedZone; // The zone the sentient is currently attuned to
        bool isAttuned;            // Whether the sentient is actively attuned to a zone
    }

    // Structure for a governance proposal
    struct Proposal {
        uint256 id;
        string description;            // Description of the proposed change
        bytes32 parameterKey;          // Key for the ecosystem parameter to change
        uint256 newValue;              // The new value for the parameter
        uint256 startTime;             // Timestamp when the proposal started
        uint256 endTime;               // Timestamp when voting ends
        uint256 votesFor;              // Total wisdom score voting "for"
        uint256 votesAgainst;          // Total wisdom score voting "against"
        uint256 totalWisdomAtProposal; // Snapshot of total active wisdom for quorum calculation
        mapping(address => bool) hasVoted; // Tracks if an address (or its Sentient) has voted
        bool executed;                 // True if the proposal has been executed
        bool passed;                   // True if the proposal passed and was executed
    }

    // --- State Variables ---

    mapping(uint256 => Sentient) public sentients;        // Stores Sentient data by tokenId
    mapping(address => uint256) public energyFluxBalances; // EFL held by user wallets (external balance)
    mapping(bytes32 => uint256) public ecosystemParameters; // Global parameters influencing ecosystem mechanics
    mapping(uint256 => Proposal) public proposals;         // Stores active and historical governance proposals
    mapping(address => bool) public isOracle;              // Whitelisted addresses allowed to submit oracle data
    mapping(bytes32 => uint256) public oracleData;         // Latest external data submitted by oracles

    // Governance parameters (can be modified by governance proposals)
    uint256 public constant MIN_WISDOM_FOR_PROPOSAL = 1000;      // Minimum wisdom needed to create a proposal
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;     // Duration for voting on a proposal
    uint256 public constant QUORUM_PERCENTAGE = 20;              // 20% of total wisdom needed for a proposal to be valid
    uint256 public constant PASS_THRESHOLD_PERCENTAGE = 51;      // 51% 'for' votes needed for a proposal to pass

    // Sentient lifecycle and interaction parameters (can be modified by governance)
    uint256 public constant EVOLUTION_ENERGY_COST = 50;          // EFL cost for a Sentient to attempt evolution
    uint256 public constant REPLICATION_ENERGY_COST = 1000;      // EFL cost for an Architect Sentient to replicate
    uint256 public constant REPLICATION_WISDOM_THRESHOLD = 5000; // Minimum wisdom for replication
    uint256 public constant INACTIVITY_DECAY_PERIOD = 7 days;    // Time after which inactive Sentients start losing wisdom
    uint256 public constant DECAY_WISDOM_AMOUNT = 50;            // Amount of wisdom lost during decay
    uint256 public constant SIPHON_ENERGY_COST = 100;            // EFL cost for attempting to siphon energy
    uint256 public constant SIPHON_WISDOM_DIFFERENCE_THRESHOLD = 500; // Siphoner must be at least this much wiser
    uint256 public constant WISDOM_CHALLENGE_STAKE = 1 ether;    // Example stake required to challenge wisdom

    // --- Events ---

    event SentientMinted(uint256 indexed tokenId, address indexed owner, SentientRank initialRank);
    event SentientEvolved(uint256 indexed tokenId, SentientRank newRank, uint256 currentEnergy);
    event SentientTraitMutated(uint256 indexed tokenId, SentientTrait indexed trait, uint8 oldValue, uint8 newValue);
    event SentientRankAscended(uint256 indexed tokenId, SentientRank oldRank, SentientRank newRank);
    event SentientInfluenceDecayed(uint256 indexed tokenId, uint256 oldWisdom, uint256 newWisdom);
    event SentientReplicated(uint256 indexed parentId, uint256 indexed newSeedId, address indexed newOwner);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue, uint256 endTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 wisdomPower);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 parameterKey, uint256 newValue);
    event OracleDataSubmitted(bytes32 indexed dataType, uint256 value, address indexed sender);

    event EnergyFluxClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EnergyFluxAllocated(uint256 indexed tokenId, address indexed sender, uint256 amount);
    event ResourceSynthesized(uint256 indexed tokenId, ResourceType indexed resourceType, uint256 amount);
    event ResourceConsumed(uint256 indexed tokenId, ResourceType indexed resourceType);
    event EnergyFluxSiphoned(uint256 indexed siphonerTokenId, uint256 indexed targetTokenId, uint256 amount);

    event WisdomPointsEarned(uint256 indexed tokenId, uint256 amount, uint256 newTotal);
    event WisdomChallengeInitiated(uint256 indexed tokenId, address indexed challenger, string reason);
    event SentientAttuned(uint256 indexed tokenId, EcosystemZone indexed zone);

    // --- Modifiers ---

    /// @dev Ensures that the caller is the owner of the specified Sentient NFT.
    modifier onlySentientOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert NotSentientOwner(_tokenId, msg.sender);
        }
        _;
    }

    /// @dev Ensures that the caller is a registered oracle.
    modifier onlyOracle() {
        if (!isOracle[msg.sender]) {
            revert UnauthorizedOracle(msg.sender);
        }
        _;
    }

    // --- Constructor ---

    /// @notice Initializes the ChronosSentientGenesis contract.
    /// @dev Sets the deployer as the initial owner and defines base ecosystem parameters.
    constructor() ERC721("Chronos Sentient Genesis", "CSG") Ownable(msg.sender) {
        // Set initial ecosystem parameters, these can be changed via governance
        _setEcosystemParameter("EvolutionSuccessChanceBase", 50); // Base 50% chance for evolution success
        _setEcosystemParameter("EFLGenerationRate", 10);          // EFL generated per sentient per 'activity period' (simplified to daily in claim)
        _setEcosystemParameter("ReplicationResourceCost_ChronosDust", 100); // Cost in ChronosDust for replication
        _setEcosystemParameter("ReplicationResourceCost_BioEssence", 50);   // Cost in BioEssence for replication
        _setEcosystemParameter("WisdomDecayInterval", INACTIVITY_DECAY_PERIOD); // Interval for wisdom decay
        _setEcosystemParameter("SiphonSuccessChanceBase", 30);    // Base 30% chance for siphoning to succeed
        _setEcosystemParameter("TraitMutationCost", 20);          // Base EFL cost for mutating a trait
    }

    // --- Internal Utility Functions ---

    /// @dev Internal function to set an ecosystem parameter.
    /// @param _key The bytes32 key representing the parameter.
    /// @param _value The new value for the parameter.
    function _setEcosystemParameter(bytes32 _key, uint256 _value) internal {
        ecosystemParameters[_key] = _value;
    }

    /// @dev Internal function to get an ecosystem parameter.
    /// @param _key The bytes32 key representing the parameter.
    /// @return The current value of the parameter.
    function _getEcosystemParameter(bytes32 _key) internal view returns (uint256) {
        return ecosystemParameters[_key];
    }

    /// @dev Internal function to transfer Energy Flux tokens between user wallets.
    /// @param _from The sender's address.
    /// @param _to The recipient's address.
    /// @param _amount The amount of EFL to transfer.
    function _transferEnergyFlux(address _from, address _to, uint256 _amount) internal {
        if (energyFluxBalances[_from] < _amount) {
            revert InsufficientEnergy(_from, _amount, energyFluxBalances[_from]);
        }
        energyFluxBalances[_from] -= _amount;
        energyFluxBalances[_to] += _amount;
    }

    /// @dev Internal function to award wisdom points to a Sentient.
    /// @param _tokenId The ID of the Sentient to award points to.
    /// @param _amount The amount of wisdom points to award.
    function _awardWisdom(uint256 _tokenId, uint256 _amount) internal {
        sentients[_tokenId].wisdomScore += _amount;
        emit WisdomPointsEarned(_tokenId, _amount, sentients[_tokenId].wisdomScore);
    }

    /// @dev Internal function to consume resources from a Sentient.
    /// @param _tokenId The ID of the Sentient consuming resources.
    /// @param _resourceType The type of resource to consume.
    /// @param _amount The amount of resource to consume.
    function _consumeResource(uint256 _tokenId, ResourceType _resourceType, uint256 _amount) internal {
        if (sentients[_tokenId].resources[_resourceType] < _amount) {
            revert InsufficientResource(_tokenId, bytes32(uint256(_resourceType)), _amount, sentients[_tokenId].resources[_resourceType]);
        }
        sentients[_tokenId].resources[_resourceType] -= _amount;
    }

    /// @dev Generates a pseudo-random number for in-contract logic.
    /// @param _seed An additional seed to ensure better randomness (e.g., tokenId, block.number).
    /// @return A pseudo-random number between 0 and 99.
    function _generateRandomNumber(uint256 _seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, block.difficulty))) % 100; // Returns 0-99
    }

    /// @dev Internal function to check and potentially ascend a Sentient's rank.
    /// @param _tokenId The ID of the Sentient to check.
    function _checkAndAscendRank(uint256 _tokenId) internal {
        Sentient storage sentient = sentients[_tokenId];
        SentientRank oldRank = sentient.rank;

        if (oldRank == SentientRank.Seed && sentient.wisdomScore >= 500 && sentient.traits[SentientTrait.Adaptability] >= 40) {
            sentient.rank = SentientRank.Sprout;
        } else if (oldRank == SentientRank.Sprout && sentient.wisdomScore >= 1500 && sentient.traits[SentientTrait.Resilience] >= 60) {
            sentient.rank = SentientRank.Pioneer;
        } else if (oldRank == SentientRank.Pioneer && sentient.wisdomScore >= 3000 && sentient.traits[SentientTrait.Curiosity] >= 80) {
            sentient.rank = SentientRank.Sage;
        } else if (oldRank == SentientRank.Sage && sentient.wisdomScore >= 6000 && sentient.energyFluxBalance >= 500) {
            sentient.rank = SentientRank.Architect;
        }

        if (sentient.rank != oldRank) {
            _awardWisdom(_tokenId, 200); // Bonus wisdom for ascending
            emit SentientRankAscended(_tokenId, oldRank, sentient.rank);
        }
    }

    // --- I. Core Infrastructure & Access Control ---

    /// @notice Mints a new "Genesis Seed" (the initial state of a Sentient dNFT) to the specified owner.
    /// @dev Only the contract owner can mint new Genesis Seeds.
    /// @param _owner The address to which the new Genesis Seed will be minted.
    function mintGenesisSeed(address _owner) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_owner, newTokenId); // Mints the ERC721 token

        Sentient storage newSentient = sentients[newTokenId];
        newSentient.tokenId = newTokenId;
        newSentient.owner = _owner;
        newSentient.rank = SentientRank.Seed;
        newSentient.wisdomScore = 100; // Initial wisdom for a new seed
        newSentient.lastActivityTime = block.timestamp;
        newSentient.energyFluxBalance = 0;
        newSentient.isAttuned = false; // Not attuned initially

        // Set initial random traits for a Genesis Seed
        newSentient.traits[SentientTrait.Adaptability] = uint8(_generateRandomNumber(newTokenId * 1) % 20 + 10); // 10-29
        newSentient.traits[SentientTrait.Resilience] = uint8(_generateRandomNumber(newTokenId * 2) % 20 + 10);   // 10-29
        newSentient.traits[SentientTrait.Curiosity] = uint8(_generateRandomNumber(newTokenId * 3) % 20 + 10);    // 10-29
        newSentient.traits[SentientTrait.Aggression] = uint8(_generateRandomNumber(newTokenId * 4) % 10 + 5);    // 5-14
        newSentient.traits[SentientTrait.Empathy] = uint8(_generateRandomNumber(newTokenId * 5) % 10 + 5);       // 5-14

        emit SentientMinted(newTokenId, _owner, SentientRank.Seed);
    }

    /// @notice Grants an address the permission to submit oracle data to the contract.
    /// @dev Only the contract owner can register new oracle addresses.
    /// @param _oracle The address to grant oracle privileges.
    function setOracleAddress(address _oracle) public onlyOwner {
        isOracle[_oracle] = true;
    }

    // `renounceOwnership()` is inherited from OpenZeppelin's `Ownable` contract.

    // --- II. Sentient Evolution & State Management (Dynamic NFTs) ---

    /// @notice Triggers an evolution attempt for a specific Sentient.
    /// @dev This consumes Energy Flux, and its outcome is influenced by Sentient traits, current oracle data, and ecosystem parameters.
    /// @param _tokenId The ID of the Sentient to attempt evolution.
    function evolveSentient(uint256 _tokenId) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        if (sentient.energyFluxBalance < EVOLUTION_ENERGY_COST) {
            revert InsufficientEnergy(msg.sender, EVOLUTION_ENERGY_COST, sentient.energyFluxBalance);
        }

        sentient.energyFluxBalance -= EVOLUTION_ENERGY_COST;
        sentient.lastActivityTime = block.timestamp; // Update activity for decay mechanics

        uint256 evolutionChance = _getEcosystemParameter("EvolutionSuccessChanceBase");
        // Example: Adaptability trait increases success chance
        evolutionChance += sentient.traits[SentientTrait.Adaptability] / 2;

        // Example: Cosmic Radiation oracle data can influence evolution success
        uint256 cosmicRadiation = oracleData["CosmicRadiationLevel"]; // Fetch latest oracle data
        if (cosmicRadiation > 50) { // High radiation makes evolution harder
            evolutionChance = evolutionChance * 80 / 100; // 20% penalty
        } else if (cosmicRadiation < 20) { // Low radiation makes it easier
            evolutionChance = evolutionChance * 120 / 100; // 20% bonus
        }

        uint256 randomNumber = _generateRandomNumber(sentient.tokenId + block.number);

        if (randomNumber < evolutionChance) {
            _awardWisdom(_tokenId, 50); // Successful evolution grants wisdom

            // Example: Mutate one random trait upon successful evolution
            SentientTrait traitToMutate = SentientTrait(randomNumber % 5); // Randomly pick a trait
            uint8 oldTraitValue = sentient.traits[traitToMutate];
            // Increase trait value by 1-10, capped at 100
            uint8 newTraitValue = oldTraitValue + uint8(_generateRandomNumber(sentient.tokenId + block.number + 1) % 10 + 1);
            if (newTraitValue > 100) newTraitValue = 100;
            sentient.traits[traitToMutate] = newTraitValue;
            emit SentientTraitMutated(_tokenId, traitToMutate, oldTraitValue, newTraitValue);

            _checkAndAscendRank(_tokenId); // Check if eligible for rank ascension
            emit SentientEvolved(_tokenId, sentient.rank, sentient.energyFluxBalance);
        } else {
            // Failed evolution: Only consume energy, small wisdom gain for the attempt
            _awardWisdom(_tokenId, 10);
            emit SentientEvolved(_tokenId, sentient.rank, sentient.energyFluxBalance);
        }
    }

    /// @notice Allows a Sentient's owner to attempt to mutate a specific trait.
    /// @dev This action consumes Energy Flux, and its outcome (trait value change) is influenced by Sentient traits and ecosystem parameters.
    /// @param _tokenId The ID of the Sentient whose trait is to be mutated.
    /// @param _trait The specific SentientTrait enum to attempt to mutate.
    /// @param _newValue The desired target value for the trait. Actual change might vary based on success.
    function mutateSentientTrait(uint256 _tokenId, SentientTrait _trait, uint8 _newValue) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        uint256 mutationCost = _getEcosystemParameter("TraitMutationCost");
        if (sentient.energyFluxBalance < mutationCost) {
            revert InsufficientEnergy(msg.sender, mutationCost, sentient.energyFluxBalance);
        }
        if (_newValue > 100) revert InvalidTraitValue(_trait, _newValue);

        sentient.energyFluxBalance -= mutationCost;
        sentient.lastActivityTime = block.timestamp;

        uint256 mutationChance = 60; // Base chance
        // Curiosity trait can increase mutation success chance
        mutationChance += sentient.traits[SentientTrait.Curiosity] / 3;

        uint256 randomNumber = _generateRandomNumber(sentient.tokenId + uint256(_trait) + block.number);

        uint8 oldTraitValue = sentient.traits[_trait];
        uint8 actualNewValue = oldTraitValue;

        if (randomNumber < mutationChance) {
            // Successful mutation: Trait value moves towards _newValue
            if (_newValue > oldTraitValue) {
                actualNewValue = oldTraitValue + uint8(randomNumber % (_newValue - oldTraitValue + 1));
            } else if (_newValue < oldTraitValue) {
                actualNewValue = oldTraitValue - uint8(randomNumber % (oldTraitValue - _newValue + 1));
            }
            if (actualNewValue > 100) actualNewValue = 100;
            _awardWisdom(_tokenId, 25); // Reward for successful mutation
        } else {
            // Failed mutation: Small random deviation or no change
            actualNewValue = oldTraitValue + uint8(_generateRandomNumber(sentient.tokenId + block.number + 2) % 5 - 2); // -2 to +2 change
            if (actualNewValue > 100) actualNewValue = 100;
            if (actualNewValue < 0) actualNewValue = 0; // Ensure trait doesn't go below 0
        }

        sentient.traits[_trait] = actualNewValue;
        emit SentientTraitMutated(_tokenId, _trait, oldTraitValue, actualNewValue);
    }

    /// @notice Promotes a Sentient to a higher conceptual "rank" or "form" if it meets specific criteria.
    /// @dev Criteria typically include minimum wisdom score, specific trait thresholds, and potentially resource/EFL requirements.
    /// @param _tokenId The ID of the Sentient to evaluate for rank ascension.
    function ascendSentientRank(uint256 _tokenId) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        SentientRank oldRank = sentient.rank;

        if (oldRank == SentientRank.Architect) {
            revert SentientNotReadyForAscension(_tokenId); // Already at maximum rank
        }

        // Check conditions for ascension based on current rank
        if (oldRank == SentientRank.Seed && (sentient.wisdomScore < 500 || sentient.traits[SentientTrait.Adaptability] < 40)) {
            revert SentientNotReadyForAscension(_tokenId);
        } else if (oldRank == SentientRank.Sprout && (sentient.wisdomScore < 1500 || sentient.traits[SentientTrait.Resilience] < 60)) {
            revert SentientNotReadyForAscension(_tokenId);
        } else if (oldRank == SentientRank.Pioneer && (sentient.wisdomScore < 3000 || sentient.traits[SentientTrait.Curiosity] < 80)) {
            revert SentientNotReadyForAscension(_tokenId);
        } else if (oldRank == SentientRank.Sage && (sentient.wisdomScore < 6000 || sentient.energyFluxBalance < 500)) {
            revert SentientNotReadyForAscension(_tokenId);
        }

        // If conditions met, increment rank
        sentient.rank = SentientRank(uint8(oldRank) + 1);
        sentient.lastActivityTime = block.timestamp;
        _awardWisdom(_tokenId, 200); // Bonus wisdom for ascending
        emit SentientRankAscended(_tokenId, oldRank, sentient.rank);
    }

    /// @notice A maintenance function that periodically reduces a Sentient's Wisdom Score if it has been inactive for an extended period.
    /// @dev This function can be called by anyone, but only applies decay if conditions are met. Designed to encourage active participation.
    /// @param _tokenId The ID of the Sentient to check for influence decay.
    function decaySentientInfluence(uint256 _tokenId) public {
        Sentient storage sentient = sentients[_tokenId];
        if (sentient.tokenId == 0) revert SentientNotFound(_tokenId);
        uint256 decayPeriod = _getEcosystemParameter("WisdomDecayInterval");

        // Only decay if sufficient time has passed since last activity and sentient has wisdom
        if (block.timestamp - sentient.lastActivityTime < decayPeriod || sentient.wisdomScore == 0) {
            return;
        }

        uint256 oldWisdom = sentient.wisdomScore;
        // Decay by DECAY_WISDOM_AMOUNT, but not below 0
        sentient.wisdomScore = sentient.wisdomScore > DECAY_WISDOM_AMOUNT ? sentient.wisdomScore - DECAY_WISDOM_AMOUNT : 0;
        sentient.lastActivityTime = block.timestamp; // Reset activity timestamp to prevent immediate re-decay
        emit SentientInfluenceDecayed(_tokenId, oldWisdom, sentient.wisdomScore);
    }

    /// @notice Allows a highly evolved and wise Sentient to consume significant resources and Energy Flux to "replicate" a new Genesis Seed.
    /// @dev Only Architect-rank Sentients with high wisdom can perform replication. This expands the ecosystem.
    /// @param _parentId The ID of the parent Sentient initiating replication.
    /// @param _newOwner The address to which the newly replicated Genesis Seed will be minted.
    function replicateSentient(uint256 _parentId, address _newOwner) public onlySentientOwner(_parentId) {
        Sentient storage parentSentient = sentients[_parentId];

        // Check if parent Sentient meets replication criteria
        if (parentSentient.rank != SentientRank.Architect || parentSentient.wisdomScore < REPLICATION_WISDOM_THRESHOLD) {
            revert SentientNotEligibleForReplication(_parentId);
        }
        if (parentSentient.energyFluxBalance < REPLICATION_ENERGY_COST) {
            revert InsufficientEnergy(msg.sender, REPLICATION_ENERGY_COST, parentSentient.energyFluxBalance);
        }

        uint256 chronosDustCost = _getEcosystemParameter("ReplicationResourceCost_ChronosDust");
        uint256 bioEssenceCost = _getEcosystemParameter("ReplicationResourceCost_BioEssence");

        _consumeResource(_parentId, ResourceType.ChronosDust, chronosDustCost);
        _consumeResource(_parentId, ResourceType.BioEssence, bioEssenceCost);
        parentSentient.energyFluxBalance -= REPLICATION_ENERGY_COST;

        parentSentient.lastActivityTime = block.timestamp;
        _awardWisdom(_parentId, 500); // Significant wisdom bonus for successful replication

        _tokenIdCounter.increment();
        uint256 newSeedId = _tokenIdCounter.current();

        _safeMint(_newOwner, newSeedId); // Mint the new ERC721 token

        Sentient storage newSentient = sentients[newSeedId];
        newSentient.tokenId = newSeedId;
        newSentient.owner = _newOwner;
        newSentient.rank = SentientRank.Seed;
        newSentient.wisdomScore = 100; // Initial wisdom for new seed
        newSentient.lastActivityTime = block.timestamp;
        newSentient.energyFluxBalance = 0;
        newSentient.isAttuned = false;

        // New Sentient inherits some traits from the parent, simulating genetic inheritance
        newSentient.traits[SentientTrait.Adaptability] = parentSentient.traits[SentientTrait.Adaptability] / 2;
        newSentient.traits[SentientTrait.Resilience] = parentSentient.traits[SentientTrait.Resilience] / 2;
        newSentient.traits[SentientTrait.Curiosity] = parentSentient.traits[SentientTrait.Curiosity] / 2;
        newSentient.traits[SentientTrait.Aggression] = parentSentient.traits[SentientTrait.Aggression] / 2;
        newSentient.traits[SentientTrait.Empathy] = parentSentient.traits[SentientTrait.Empathy] / 2;

        emit SentientMinted(newSeedId, _newOwner, SentientRank.Seed);
        emit SentientReplicated(_parentId, newSeedId, _newOwner);
    }

    // --- III. Ecosystem Governance & Parameters ---

    /// @notice Allows Sentient holders with sufficient Wisdom Score to propose changes to global ecosystem parameters.
    /// @dev Proposing costs no EFL directly, but requires a Sentient with a minimum wisdom score.
    /// @param _description A string describing the purpose and impact of the proposal.
    /// @param _parameterKey The `bytes32` key of the ecosystem parameter intended for change (e.g., "EvolutionSuccessChanceBase").
    /// @param _newValue The new `uint256` value to be set for the specified parameter if the proposal passes.
    function proposeEcosystemParameterChange(
        string memory _description,
        bytes32 _parameterKey,
        uint256 _newValue
    ) public {
        // Find a Sentient owned by msg.sender with sufficient wisdom to propose
        uint256 proposerWisdom = 0;
        uint256[] memory ownedTokens = _tokensOfOwner(msg.sender); // Get all Sentients owned by caller
        if (ownedTokens.length == 0) revert InsufficientWisdom(0, MIN_WISDOM_FOR_PROPOSAL, 0);

        // Iterate to find a Sentient meeting the wisdom threshold
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            if (sentients[ownedTokens[i]].wisdomScore >= MIN_WISDOM_FOR_PROPOSAL) {
                proposerWisdom = sentients[ownedTokens[i]].wisdomScore;
                sentients[ownedTokens[i]].lastActivityTime = block.timestamp; // Mark Sentient as active
                _awardWisdom(ownedTokens[i], 100); // Reward Sentient for proposing
                break; // Found a suitable Sentient, exit loop
            }
        }
        if (proposerWisdom == 0) revert InsufficientWisdom(0, MIN_WISDOM_FOR_PROPOSAL, 0);

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            parameterKey: _parameterKey,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            votesFor: 0,
            votesAgainst: 0,
            totalWisdomAtProposal: _getTotalWisdomScore(), // Snapshot total wisdom for quorum calculation
            hasVoted: new mapping(address => bool)(), // Initialize a new empty mapping for votes
            executed: false,
            passed: false
        });

        emit ProposalCreated(proposalId, msg.sender, _parameterKey, _newValue, proposals[proposalId].endTime);
    }

    /// @notice Allows Sentient holders to cast their vote on an active governance proposal.
    /// @dev Voting power is weighted by the total Wisdom Score of all Sentients owned by the voter.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support `true` if voting "for" the proposal, `false` for "against".
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (block.timestamp > proposal.endTime) revert ProposalNotActive(_proposalId);
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

        uint256 voterWisdom = 0;
        uint256[] memory ownedTokens = _tokensOfOwner(msg.sender);
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            voterWisdom += sentients[ownedTokens[i]].wisdomScore;
            sentients[ownedTokens[i]].lastActivityTime = block.timestamp; // Mark Sentient as active
            _awardWisdom(ownedTokens[i], 5); // Small reward for voting participation
        }
        if (voterWisdom == 0) revert InsufficientWisdom(0, 1, 0); // Need at least 1 wisdom to vote

        if (_support) {
            proposal.votesFor += voterWisdom;
        } else {
            proposal.votesAgainst += voterWisdom;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, voterWisdom);
    }

    /// @notice Finalizes a proposal that has reached quorum and passed, applying the proposed parameter changes to the ecosystem.
    /// @dev This function can be called by anyone after the voting period ends.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (block.timestamp <= proposal.endTime) revert ProposalNotExecutable(_proposalId); // Voting period not over
        if (proposal.executed) revert ProposalNotExecutable(_proposalId); // Already executed

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorumThreshold = proposal.totalWisdomAtProposal * QUORUM_PERCENTAGE / 100;

        if (totalVotes < quorumThreshold) {
            proposal.executed = true; // Mark as executed but failed quorum
            proposal.passed = false;
            revert ProposalNotExecutable(_proposalId); // Proposal failed to reach quorum
        }

        // Check if 'for' votes meet the passing threshold
        if (proposal.votesFor * 100 / totalVotes >= PASS_THRESHOLD_PERCENTAGE) {
            _setEcosystemParameter(proposal.parameterKey, proposal.newValue); // Apply the parameter change
            proposal.passed = true;
            emit ProposalExecuted(proposal.id, proposal.parameterKey, proposal.newValue);
        } else {
            proposal.passed = false; // Proposal failed to pass
        }
        proposal.executed = true; // Mark as executed regardless of outcome
    }

    /// @notice Allows a registered oracle to submit external "environmental" data to the contract.
    /// @dev This data can influence various ecosystem mechanics, such as evolution chances or resource generation.
    /// @param _dataType A `bytes32` identifier for the type of data being submitted (e.g., "CosmicRadiationLevel", "ResourceScarcityIndex").
    /// @param _value The `uint256` value of the data.
    function submitOracleData(bytes32 _dataType, uint256 _value) public onlyOracle {
        oracleData[_dataType] = _value;
        emit OracleDataSubmitted(_dataType, _value, msg.sender);
    }

    // --- IV. Energy Flux (EFL) Token & Resource Economy ---

    /// @notice Allows a Sentient's owner to claim passively generated Energy Flux tokens that have accumulated for their Sentient.
    /// @dev EFL generation rate is influenced by ecosystem parameters and Sentient rank.
    /// @param _tokenId The ID of the Sentient from which Energy Flux will be claimed.
    function claimEnergyFlux(uint256 _tokenId) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        uint256 generationRate = _getEcosystemParameter("EFLGenerationRate");
        uint256 timeSinceLastActivity = block.timestamp - sentient.lastActivityTime;

        // Example: Generate EFL based on time, and Sentient's rank provides a bonus
        uint256 generatedAmount = timeSinceLastActivity * generationRate / 1 days; // Simplified: EFL per day
        generatedAmount += uint256(sentient.rank) * 5; // Higher rank Sentients generate more

        if (generatedAmount > 0) {
            sentient.energyFluxBalance += generatedAmount;
            sentient.lastActivityTime = block.timestamp; // Reset activity for decay and next claim calculation
            emit EnergyFluxClaimed(_tokenId, msg.sender, generatedAmount);
        }
    }

    /// @notice Transfers a specified amount of Energy Flux tokens from the caller's personal wallet balance to a specific Sentient's internal balance.
    /// @dev This powers the Sentient's actions or evolution attempts.
    /// @param _tokenId The ID of the Sentient to allocate Energy Flux to.
    /// @param _amount The amount of Energy Flux to allocate.
    function allocateEnergyToSentient(uint256 _tokenId, uint256 _amount) public onlySentientOwner(_tokenId) {
        if (energyFluxBalances[msg.sender] < _amount) {
            revert InsufficientEnergy(msg.sender, _amount, energyFluxBalances[msg.sender]);
        }
        energyFluxBalances[msg.sender] -= _amount;      // Deduct from owner's wallet balance
        sentients[_tokenId].energyFluxBalance += _amount; // Add to Sentient's internal balance
        sentients[_tokenId].lastActivityTime = block.timestamp;
        emit EnergyFluxAllocated(_tokenId, msg.sender, _amount);
    }

    /// @notice Allows a Sentient with specific traits to convert Energy Flux into distinct "Synthesized Resources".
    /// @dev Resource synthesis typically requires minimum trait values and consumes EFL.
    /// @param _tokenId The ID of the Sentient performing the synthesis.
    /// @param _resourceType The type of `ResourceType` to synthesize (e.g., ChronosDust, BioEssence).
    /// @param _amount The quantity of the resource to synthesize.
    function synthesizeResource(uint256 _tokenId, ResourceType _resourceType, uint256 _amount) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        uint256 energyCostPerUnit = 10; // Base EFL cost per unit of resource

        // Example: Specific trait requirements for synthesizing certain resources
        if (_resourceType == ResourceType.ChronosDust && sentient.traits[SentientTrait.Curiosity] < 30) {
            revert InvalidTraitValue(SentientTrait.Curiosity, sentient.traits[SentientTrait.Curiosity]);
        }
        // Additional checks for other ResourceTypes and their trait requirements could be added here.

        uint256 totalEnergyCost = energyCostPerUnit * _amount;
        if (sentient.energyFluxBalance < totalEnergyCost) {
            revert InsufficientEnergy(msg.sender, totalEnergyCost, sentient.energyFluxBalance);
        }

        sentient.energyFluxBalance -= totalEnergyCost;
        sentient.resources[_resourceType] += _amount;
        sentient.lastActivityTime = block.timestamp;
        _awardWisdom(_tokenId, _amount * 2); // Reward for creating resources
        emit ResourceSynthesized(_tokenId, _resourceType, _amount);
    }

    /// @notice Enables a Sentient to consume a specific Synthesized Resource to gain a temporary boost or unlock a new ability.
    /// @dev Consuming resources provides various in-game benefits.
    /// @param _tokenId The ID of the Sentient consuming the resource.
    /// @param _resourceType The `ResourceType` to consume.
    function consumeResourceForBenefit(uint256 _tokenId, ResourceType _resourceType) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];
        _consumeResource(_tokenId, _resourceType, 1); // Consume 1 unit of the resource

        // Example benefits based on the type of resource consumed
        if (_resourceType == ResourceType.ChronosDust) {
            _awardWisdom(_tokenId, 50); // Wisdom boost
        } else if (_resourceType == ResourceType.BioEssence) {
            sentient.traits[SentientTrait.Resilience] += 5; // Trait boost, capped at 100
            if (sentient.traits[SentientTrait.Resilience] > 100) sentient.traits[SentientTrait.Resilience] = 100;
        } else if (_resourceType == ResourceType.AetherShard) {
            sentient.energyFluxBalance += 50; // Energy boost
        }
        sentient.lastActivityTime = block.timestamp;
        emit ResourceConsumed(_tokenId, _resourceType);
    }

    /// @notice An advanced interaction where a high-rank Sentient (or its owner) can attempt to siphon Energy Flux from a lower-rank Sentient.
    /// @dev This action is subject to specific ecosystem rules, requires a wisdom difference, costs EFL for the attempt, and has a chance of success.
    /// @param _siphonerId The ID of the Sentient attempting to siphon energy.
    /// @param _targetTokenId The ID of the Sentient from which energy is to be siphoned.
    /// @param _amount The amount of Energy Flux to attempt to siphon.
    function siphonEnergyFromSentient(uint256 _siphonerId, uint256 _targetTokenId, uint256 _amount) public onlySentientOwner(_siphonerId) {
        Sentient storage siphoner = sentients[_siphonerId];
        Sentient storage target = sentients[_targetTokenId];

        // Pre-conditions for siphoning attempt
        if (siphoner.tokenId == target.tokenId) revert SiphonConditionsNotMet(_siphonerId, _targetTokenId);
        if (siphoner.rank <= target.rank) revert SiphonConditionsNotMet(_siphonerId, _targetTokenId); // Siphoner must be higher rank
        if (siphoner.wisdomScore < target.wisdomScore + SIPHON_WISDOM_DIFFERENCE_THRESHOLD) {
            revert SiphonConditionsNotMet(_siphonerId, _targetTokenId); // Siphoner must be significantly wiser
        }
        if (target.energyFluxBalance < _amount) revert NotEnoughEFLForSiphon(_targetTokenId, _amount, target.energyFluxBalance);
        if (siphoner.energyFluxBalance < SIPHON_ENERGY_COST) {
            revert InsufficientEnergy(msg.sender, SIPHON_ENERGY_COST, siphoner.energyFluxBalance); // Cost for attempt
        }

        siphoner.energyFluxBalance -= SIPHON_ENERGY_COST; // Cost for attempt
        siphoner.lastActivityTime = block.timestamp;

        uint256 siphonChance = _getEcosystemParameter("SiphonSuccessChanceBase");
        siphonChance += siphoner.traits[SentientTrait.Aggression] / 2; // Aggression trait boosts success
        siphonChance -= target.traits[SentientTrait.Resilience] / 3;   // Resilience trait resists siphoning

        uint256 randomNumber = _generateRandomNumber(_siphonerId + _targetTokenId + block.number);

        if (randomNumber < siphonChance) {
            // Successful siphon
            target.energyFluxBalance -= _amount;
            siphoner.energyFluxBalance += _amount;
            _awardWisdom(_siphonerId, _amount / 10); // Reward siphoner for success
            emit EnergyFluxSiphoned(_siphonerId, _targetTokenId, _amount);
        } else {
            // Failed siphon
            _awardWisdom(_siphonerId, 10); // Small wisdom for trying
            // Target gains resilience and wisdom for resisting a siphon attempt
            target.traits[SentientTrait.Resilience] += 1;
            if (target.traits[SentientTrait.Resilience] > 100) target.traits[SentientTrait.Resilience] = 100;
            _awardWisdom(_targetTokenId, 20);
        }
    }

    // --- V. Wisdom & Reputation System ---

    /// @notice Awards Wisdom Score points to a Sentient for successful contributions, active participation, or achieving milestones within the ecosystem.
    /// @dev This function is `public` so owners can interact with it directly if there are specific UI elements,
    ///      but in a fully automated ecosystem, it would often be called internally.
    /// @param _tokenId The ID of the Sentient to award points to.
    /// @param _points The amount of wisdom points to award.
    function earnWisdomPoints(uint256 _tokenId, uint256 _points) public onlySentientOwner(_tokenId) {
        _awardWisdom(_tokenId, _points);
        sentients[_tokenId].lastActivityTime = block.timestamp;
    }

    /// @notice Initiates a formal challenge against a Sentient's Wisdom Score, requiring a stake and potentially leading to a community vote or arbitration.
    /// @dev This is a conceptual implementation. A full system would involve more complex dispute resolution.
    /// @param _tokenId The ID of the Sentient whose Wisdom Score is being challenged.
    /// @param _reason A string description detailing why the Wisdom Score is being challenged.
    function challengeWisdomScore(uint256 _tokenId, string memory _reason) public payable {
        if (sentients[_tokenId].tokenId == 0) revert SentientNotFound(_tokenId);
        if (msg.value < WISDOM_CHALLENGE_STAKE) {
            revert InsufficientEnergy(msg.sender, WISDOM_CHALLENGE_STAKE, msg.value); // Requires a stake
        }
        // In a more complex system:
        // 1. msg.value (the stake) would be held in escrow.
        // 2. A new governance proposal for arbitration or an oracle call would be triggered.
        // 3. The stake would be released to the winner, and potentially the loser penalized.
        // For this example, we just emit an event to signify the challenge.
        emit WisdomChallengeInitiated(_tokenId, msg.sender, _reason);
    }

    /// @notice Allows an owner to 'attune' a Sentient to a specific "Ecosystem Zone".
    /// @dev Attuning can influence a Sentient's trait development, resource yields, or vulnerability based on the zone's properties.
    /// @param _tokenId The ID of the Sentient to attune.
    /// @param _zone The `EcosystemZone` enum to which the Sentient will be attuned.
    function attuneSentient(uint256 _tokenId, EcosystemZone _zone) public onlySentientOwner(_tokenId) {
        Sentient storage sentient = sentients[_tokenId];

        if (sentient.isAttuned && sentient.attunedZone == _zone) {
            revert SentientAlreadyAttuned(_tokenId, _zone); // Already attuned to this zone
        }

        // Example: Zone-specific trait requirements for attunement
        if (_zone == EcosystemZone.TemporalNexus) {
            if (sentient.traits[SentientTrait.Curiosity] < 50) {
                revert InvalidTraitValue(SentientTrait.Curiosity, sentient.traits[SentientTrait.Curiosity]);
            }
        }
        // Other zones could have different trait requirements (e.g., VibrantWilds needs high Resilience)

        sentient.attunedZone = _zone;
        sentient.isAttuned = true;
        sentient.lastActivityTime = block.timestamp;
        _awardWisdom(_tokenId, 100); // Reward for attunement
        emit SentientAttuned(_tokenId, _zone);
    }

    // --- VI. View Functions ---

    /// @notice Returns all relevant data for a specific Sentient.
    /// @param _tokenId The ID of the Sentient to query.
    /// @return Sentient's ID, owner, rank, wisdom score, last activity timestamp, energy flux balance, attuned zone,
    ///         attunement status, and values for all its traits and resources.
    function getSentientDetails(uint256 _tokenId)
        public
        view
        returns (
            uint256 tokenId,
            address owner,
            SentientRank rank,
            uint256 wisdomScore,
            uint256 lastActivityTime,
            uint256 energyFluxBalance,
            EcosystemZone attunedZone,
            bool isAttuned,
            uint8 adaptability,
            uint8 resilience,
            uint8 curiosity,
            uint8 aggression,
            uint8 empathy,
            uint256 chronosDust,
            uint256 bioEssence,
            uint256 aetherShard
        )
    {
        Sentient storage sentient = sentients[_tokenId];
        if (sentient.tokenId == 0) revert SentientNotFound(_tokenId);

        return (
            sentient.tokenId,
            ownerOf(_tokenId), // Use ERC721 ownerOf for canonical owner
            sentient.rank,
            sentient.wisdomScore,
            sentient.lastActivityTime,
            sentient.energyFluxBalance,
            sentient.attunedZone,
            sentient.isAttuned,
            sentient.traits[SentientTrait.Adaptability],
            sentient.traits[SentientTrait.Resilience],
            sentient.traits[SentientTrait.Curiosity],
            sentient.traits[SentientTrait.Aggression],
            sentient.traits[SentientTrait.Empathy],
            sentient.resources[ResourceType.ChronosDust],
            sentient.resources[ResourceType.BioEssence],
            sentient.resources[ResourceType.AetherShard]
        );
    }

    /// @notice Returns the Energy Flux token balance of a specific address in their external wallet.
    /// @param _owner The address to query the balance for.
    /// @return The EFL balance of the specified address.
    function getEnergyFluxBalance(address _owner) public view returns (uint256) {
        return energyFluxBalances[_owner];
    }

    /// @notice Returns the full details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal to retrieve.
    /// @return Detailed information about the proposal, including its status and voting outcomes.
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            uint256 id,
            string memory description,
            bytes32 parameterKey,
            uint256 newValue,
            uint256 startTime,
            uint256 endTime,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool passed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);

        return (
            proposal.id,
            proposal.description,
            proposal.parameterKey,
            proposal.newValue,
            proposal.startTime,
            proposal.endTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.passed
        );
    }

    /// @notice Returns the current value of a specific global ecosystem parameter.
    /// @param _parameterKey The `bytes32` key of the parameter to query.
    /// @return The current `uint256` value of the requested ecosystem parameter.
    function getEcosystemParameter(bytes32 _parameterKey) public view returns (uint256) {
        return ecosystemParameters[_parameterKey];
    }

    /// @dev Internal helper function to calculate the total wisdom score across all existing Sentients.
    /// @notice This function can be gas-intensive if there are many Sentients; in a production dApp,
    ///         this sum might be cached or updated incrementally.
    /// @return The sum of wisdom scores of all Sentients in the ecosystem.
    function _getTotalWisdomScore() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            total += sentients[i].wisdomScore;
        }
        return total;
    }

    /// @dev Internal helper function to retrieve all token IDs owned by a specific address.
    /// @notice Similar to `_getTotalWisdomScore`, this can be gas-intensive for large numbers of NFTs.
    /// @param _owner The address for which to retrieve owned token IDs.
    /// @return An array of `uint256` representing the token IDs owned by `_owner`.
    function _tokensOfOwner(address _owner) internal view returns (uint256[] memory) {
        uint256 count = balanceOf(_owner); // Get count from ERC721
        uint256[] memory ownedTokenIds = new uint256[count];
        uint224 counter = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current() && counter < count; i++) {
            if (ownerOf(i) == _owner) {
                ownedTokenIds[counter] = i;
                counter++;
            }
        }
        return ownedTokenIds;
    }

    // --- ERC721 Metadata & Base URI ---
    /// @dev Provides the base URI for Sentient NFT metadata.
    /// @notice In a full implementation, this would point to a decentralized storage (e.g., IPFS) gateway.
    /// @return A string representing the base URI.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://chronos.sentient.genesis.metadata/"; // Example IPFS base URI
    }
}
```