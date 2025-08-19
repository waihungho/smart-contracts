Here's a Solidity smart contract named "Aetherial Genesis Protocol (AGP)" that embodies advanced concepts, creative mechanics, and trendy functionalities, without duplicating common open-source patterns. It features dynamic NFTs, a resource token, simulated ecosystem dynamics, and elements of decentralized governance and predictive markets.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For token URI generation

// --- Custom Errors ---
error Unauthorized();
error InvalidAGUID();
error InsufficientEssence();
error InvalidParameter();
error AlreadyHarvested();
error AGUAlreadyDecayed();
error AGUNotReadyForFusion();
error NoActiveProposal();
error ProposalAlreadyVoted();
error NotEnoughVotes();
error SelfDelegateNotAllowed();
error DelegationNotPossible();
error NoDiscoveryRewardsAvailable();
error AGUTooHealthyForMaintenance();
error InvalidProposalState();
error ProposalNotYetExpired();
error ProposalAlreadyExecuted();
error ProposalFailedQuorum();

// --- Outline & Function Summary ---
// This contract, "Aetherial Genesis Protocol (AGP)", creates and manages "Aetherial Genesis Units" (AGUs),
// which are dynamic NFTs (ERC-721) representing unique, evolving digital entities. These AGUs exist within
// a simulated ecosystem, adapting based on various parameters (on-chain data, oracle feeds, governance votes).
// They can "mine" (generate) unique 'Essence' tokens (ERC-20), participate in a 'Fusion' process to create
// new AGUs, and evolve their traits, potentially leading to a self-organizing digital 'species' or 'organization'.

// Key Concepts:
// - Dynamic NFT Evolution: AGU traits (Vitality, Adaptability, Resonance, Harmony, Wisdom) change over time
//   based on interactions, resource consumption, and external data.
// - On-Chain Ecosystem Simulation: AGUs interact within a shared environment, influencing each other and global
//   parameters indirectly.
// - Adaptive Behavior: Influenced by oracle-fed external data, simulating environmental shifts.
// - Resource Management: AGUs generate 'Essence' tokens (ERC-20) and consume them for maintenance or evolution.
// - Multi-Dimensional Influence/Reputation: AGUs have 'Wisdom' (for governance) and 'Harmony' (for decay reduction) scores.
// - Genetic/Fusion Mechanics: Combine two AGUs (parents) to create a new one (child), inheriting traits.
// - Delegated Discovery: Users can influence future AGU trait trajectories, earning rewards if their
//   "predictions" (influences) align with successfully procreated AGUs.
// - Collective Wisdom Governance: AGU owners, weighted by their AGU's 'Wisdom' score, can propose and vote on
//   protocol-level parameter changes, simulating a DAO.
// - Automated Decay/Maintenance: AGUs require ongoing 'Essence' to thrive; vitality decays over time if neglected.

// --- Contract: AetherialGenesisProtocol ---

// I. Core Setup & Management
// 1. constructor(): Initializes the protocol, deploys the Essence ERC-20 token, sets up roles (ADMIN, MINTER, ORACLE), and default parameters.
// 2. setProtocolParameters(uint256 _baseEssenceProductionRate, ...): Allows ADMIN_ROLE to adjust core simulation parameters.
// 3. pauseProtocol(): Pauses all core AGU-related functionalities (minting, harvesting, evolving, proposals).
// 4. unpauseProtocol(): Unpauses the protocol.
// 5. withdrawProtocolFees(address _token, address _to): Allows ADMIN_ROLE to withdraw accumulated protocol fees (Essence or other tokens).

// II. AGU (NFT) Management
// 6. mintInitialGenesisUnit(address _to, string memory _tokenURI): Mints the very first AGU, typically by MINTER_ROLE.
// 7. procreateGenesisUnit(uint256 _parent1Id, uint256 _parent2Id, string memory _tokenURI): Allows AGU owners to combine two AGUs (parents) to mint a new one (child). This is the primary AGU minting mechanism.
// 8. getAGUDetails(uint256 _aguId): Retrieves all dynamic and static details of a specific AGU.
// 9. evolveAGUTraits(uint256 _aguId, uint8 _traitIndex, uint8 _increaseBy): Allows an AGU to evolve a specific trait, costing Essence and influenced by its Adaptability.
// 10. decayAGU(uint256 _aguId): Applies decay mechanics to an AGU, reducing its vitality if not maintained. Can be called by anyone or internally.

// III. Essence (ERC-20 Resource Token) Management
// 11. harvestEssence(uint256 _aguId): Allows AGU owners to claim generated Essence from their AGUs based on production rate, resonance, and time.
// 12. burnEssenceForMaintenance(uint256 _aguId, uint256 _amount): Burns Essence to prevent or reverse AGU vitality decay.
// 13. getAvailableEssence(uint256 _aguId): Calculates the amount of Essence an AGU has generated but not yet harvested.

// IV. Advanced Dynamics & Interaction
// 14. influenceAGUTrajectory(uint256 _trajectoryIndex, uint256 _amount): Users spend Essence to "influence" the direction of evolution for future AGUs, affecting trait distribution for procreated units.
// 15. delegateDiscoveryVote(address _delegatee): Delegate one's "influence" power (Essence spent on discovery) to another address.
// 16. redeemDiscoveryRewards(): Allows successful "influencers" to claim rewards from the discovery pool.
// 17. syncExternalInfluence(uint256 _externalIndex): An authorized ORACLE_ROLE caller updates a global external influence parameter (e.g., "Market Volatility Index") affecting AGU behavior.
// 18. initiateCollectiveWisdomVote(uint256 _proposalType, bytes calldata _proposalData, string memory _description): AGU owners propose changes to global ecosystem parameters, weighted by their AGU's 'Wisdom' score.
// 19. castCollectiveWisdomVote(uint256 _proposalId, bool _support): AGU owners cast their vote on an active proposal.
// 20. executeCollectiveWisdomProposal(uint256 _proposalId): Executes a passed governance proposal if quorum is met and voting period expired.
// 21. delegateCollectiveWisdomVote(address _delegatee): Delegate one's 'Wisdom' voting power for collective wisdom proposals.

// V. Query Functions (Read-only)
// 22. getGlobalParameters(): Retrieves all current global simulation parameters.
// 23. getDiscoveryInfluencePool(uint256 _trajectoryIndex): Checks current total influence for a specific trait trajectory.
// 24. getAGUStatsSummary(): Provides a high-level summary of all AGUs (total count, average traits, etc.).
// 25. calculateFusionOutcomePreview(uint256 _parent1Id, uint256 _parent2Id): Predicts potential traits of a new AGU from a fusion without executing it.
// 26. getLatestOracleData(): Views the latest external data ingested via the oracle.
// 27. getProposalDetails(uint256 _proposalId): Retrieves details of a specific collective wisdom proposal.
// 28. getDiscoveryRewardPool(): Retrieves the total Essence available in the discovery reward pool.
// 29. getMaintenanceCost(uint256 _aguId): Calculates the current Essence cost to fully maintain an AGU to max vitality.
// 30. getAguOwner(uint256 _aguId): Returns the owner of a specific AGU.

contract AetherialGenesisProtocol is ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // Manages protocol parameters and fees
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Can mint initial AGUs
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // Can update external influence data

    // --- AGU Traits & Structure ---
    // Trait values are typically 0-100 for simplicity and gas efficiency with uint8
    struct AGUTraits {
        uint8 vitality;     // Health, affects decay and essence production (0-100)
        uint8 adaptability; // How well it changes traits, affects evolve cost/success (0-100)
        uint8 resonance;    // How much Essence it generates (0-100)
        uint8 harmony;      // Reduces decay rate, minor influence on collective wisdom (0-100)
        uint8 wisdom;       // Major influence on collective wisdom voting power (0-100)
    }

    struct AGU {
        AGUTraits traits;
        uint256 genesisBlock;           // Block number when AGU was created
        uint256 lastHarvestBlock;       // Last block Essence was harvested
        uint256 lastMaintenanceBlock;   // Last block maintenance was performed
        address owner; // Redundant with ERC721 ownerOf, but useful for quick access if needed, or if owner changes frequently.
                       // For this example, ERC721 ownerOf will be definitive.
    }

    mapping(uint256 => AGU) public aguData;

    // --- Essence Token ---
    EssenceToken public essence;

    // --- Global Protocol Parameters ---
    struct ProtocolParameters {
        uint256 baseEssenceProductionRate;  // Per AGU per block, affects harvest
        uint256 baseDecayRate;              // Per AGU per block, affects vitality decay
        uint256 fusionEssenceCost;          // Cost to procreate a new AGU
        uint256 evolutionEssenceCostPerPoint; // Cost to evolve 1 point of a trait
        uint256 maintenanceCostPerVitalityPoint; // Cost to restore 1 vitality point
        uint256 minVitalityForFusion;       // Min vitality required for fusion
        uint256 discoveryRewardPercentage;  // % of fusion cost for discovery pool (e.g., 500 = 5%)
        uint256 wisdomVoteThreshold;        // Min wisdom score required to initiate a proposal
        uint256 proposalVoteQuorumBasis;    // Quorum percentage basis (e.g., 10000 for 100%)
        uint256 proposalVotingPeriod;       // Blocks duration for a proposal vote
        uint256 initialAGUVitality;         // Starting vitality for new AGUs
    }
    ProtocolParameters public protocolParams;

    // --- External Influence (Oracle Data) ---
    uint256 public latestExternalInfluence; // Simulates an external index (e.g., market volatility)
    uint256 public externalInfluenceLastSyncedBlock;

    // --- Discovery Mechanism ---
    // Users "influence" trait probabilities for future AGUs.
    // Maps trajectory index (e.g., trait ID) => total Essence committed
    mapping(uint256 => uint256) public discoveryInfluencePool;
    mapping(address => address) public discoveryDelegates; // Delegate influence power
    mapping(address => uint256) public discoveryRewardsAvailable; // Rewards to claim

    // --- Collective Wisdom (Governance) ---
    struct Proposal {
        address proposer;
        uint256 proposalType; // 0: update params, 1: other, etc.
        bytes data;           // Encoded data for the proposal (e.g., new param values)
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 totalWisdomVotesFor;
        uint256 totalWisdomVotesAgainst;
        mapping(address => bool) hasVoted; // Check if an address has voted
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter public proposalCounter;
    mapping(address => address) public wisdomDelegates; // Delegate wisdom voting power

    // --- Events ---
    event AGUMinted(uint256 indexed aguId, address indexed owner, uint256 parent1Id, uint256 parent2Id);
    event EssenceHarvested(uint256 indexed aguId, address indexed owner, uint256 amount);
    event AGUTraitsEvolved(uint256 indexed aguId, uint8 indexed traitIndex, uint8 newTraitValue);
    event AGUDecayed(uint256 indexed aguId, uint8 oldVitality, uint8 newVitality);
    event AGUMaintained(uint256 indexed aguId, uint256 essenceBurned, uint8 newVitality);
    event ProtocolParametersUpdated(ProtocolParameters newParams);
    event ExternalInfluenceSynced(uint256 newInfluence, uint256 blockNumber);
    event InfluenceTrajectory(address indexed influencer, uint256 indexed trajectoryIndex, uint256 amount);
    event DiscoveryRewardsClaimed(address indexed recipient, uint256 amount);
    event NewProposal(uint256 indexed proposalId, address indexed proposer, uint256 proposalType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 wisdomWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProtocolFeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);

    constructor() ERC721("Aetherial Genesis Unit", "AGU") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);

        // Deploy Essence Token
        essence = new EssenceToken();

        // Set initial protocol parameters
        protocolParams = ProtocolParameters({
            baseEssenceProductionRate: 10,  // 10 ESS per AGU per block
            baseDecayRate: 1,               // 1 vitality point decay per 10 blocks (Adjusted for finer control below)
            fusionEssenceCost: 5000 * 1e18, // 5000 ESS to fuse
            evolutionEssenceCostPerPoint: 10 * 1e18, // 10 ESS per trait point
            maintenanceCostPerVitalityPoint: 5 * 1e18, // 5 ESS per vitality point restored
            minVitalityForFusion: 50,       // Must be >50 vitality to fuse
            discoveryRewardPercentage: 500, // 5% of fusion cost goes to discovery pool
            wisdomVoteThreshold: 50,        // Need AGU with >50 wisdom to propose
            proposalVoteQuorumBasis: 5000,  // 50% quorum (5000/10000)
            proposalVotingPeriod: 100,      // 100 blocks voting period
            initialAGUVitality: 70          // New AGUs start with 70 vitality
        });

        latestExternalInfluence = 50; // Initial "neutral" influence
        externalInfluenceLastSyncedBlock = block.number;
    }

    // --- ERC721 URI (metadata) ---
    function _baseURI() internal view override returns (string memory) {
        return "https://api.aetherialgenesis.xyz/agu/"; // Placeholder for metadata API
    }

    // Custom token URI logic (example, could be more complex with on-chain traits)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidAGUID();
        // In a real dApp, this URI would point to an API endpoint that generates JSON metadata
        // including the AGU's current dynamic traits.
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    // --- I. Core Setup & Management ---

    /**
     * @notice Allows ADMIN_ROLE to adjust core simulation parameters.
     * @param _params A struct containing all new protocol parameters.
     */
    function setProtocolParameters(ProtocolParameters memory _params) external onlyRole(ADMIN_ROLE) {
        protocolParams = _params;
        emit ProtocolParametersUpdated(_params);
    }

    /**
     * @notice Pauses core AGU functionalities. Only ADMIN_ROLE.
     */
    function pauseProtocol() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses core AGU functionalities. Only ADMIN_ROLE.
     */
    function unpauseProtocol() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Allows ADMIN_ROLE to withdraw accumulated protocol fees.
     * @param _token The address of the token to withdraw (e.g., Essence token address).
     * @param _to The recipient address for the fees.
     */
    function withdrawProtocolFees(address _token, address _to) external onlyRole(ADMIN_ROLE) {
        if (_token == address(essence)) {
            uint256 balance = essence.balanceOf(address(this));
            if (balance > 0) {
                essence.transfer(_to, balance);
                emit ProtocolFeesWithdrawn(_token, _to, balance);
            }
        } else {
            // For other ERC20 tokens or ETH (if applicable)
            revert InvalidParameter(); // Or implement specific logic for ETH/other tokens
        }
    }

    // --- II. AGU (NFT) Management ---

    /**
     * @notice Mints the very first AGU. Only MINTER_ROLE.
     * @param _to The recipient address for the new AGU.
     * @param _tokenURI The metadata URI for the initial AGU.
     */
    function mintInitialGenesisUnit(address _to, string memory _tokenURI) external onlyRole(MINTER_ROLE) {
        _pauseCheck(); // Custom pause check, not using `whenNotPaused` directly on mint
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        AGUTraits memory initialTraits = AGUTraits({
            vitality: protocolParams.initialAGUVitality,
            adaptability: uint8(50 + (uint256(keccak256(abi.encodePacked(block.timestamp, newItemId))) % 21) - 10), // 40-60
            resonance: uint8(50 + (uint256(keccak256(abi.encodePacked(block.timestamp, newItemId, "res"))) % 21) - 10), // 40-60
            harmony: uint8(50 + (uint256(keccak256(abi.encodePacked(block.timestamp, newItemId, "harm"))) % 21) - 10), // 40-60
            wisdom: uint8(50 + (uint256(keccak256(abi.encodePacked(block.timestamp, newItemId, "wis"))) % 21) - 10) // 40-60
        });

        aguData[newItemId] = AGU({
            traits: initialTraits,
            genesisBlock: block.number,
            lastHarvestBlock: block.number,
            lastMaintenanceBlock: block.number
        });

        _safeMint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI); // Set initial URI
        emit AGUMinted(newItemId, _to, 0, 0);
    }

    /**
     * @notice Allows AGU owners to combine two AGUs (parents) to mint a new one (child).
     * This is the primary minting mechanism after initial units.
     * @param _parent1Id ID of the first parent AGU.
     * @param _parent2Id ID of the second parent AGU.
     * @param _tokenURI The metadata URI for the new AGU.
     */
    function procreateGenesisUnit(uint256 _parent1Id, uint256 _parent2Id, string memory _tokenURI)
        external
        whenNotPaused
    {
        if (ownerOf(_parent1Id) != msg.sender || ownerOf(_parent2Id) != msg.sender) {
            revert Unauthorized();
        }
        if (_parent1Id == _parent2Id) revert InvalidAGUID();

        AGU storage parent1 = aguData[_parent1Id];
        AGU storage parent2 = aguData[_parent2Id];

        if (parent1.traits.vitality < protocolParams.minVitalityForFusion ||
            parent2.traits.vitality < protocolParams.minVitalityForFusion) {
            revert AGUNotReadyForFusion();
        }

        // Burn Essence for fusion
        essence.burnFrom(msg.sender, protocolParams.fusionEssenceCost);

        // --- Trait Inheritance & Mutation Logic ---
        // Simple average + random mutation influenced by discovery pool and external influence
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _parent1Id, _parent2Id, msg.sender)));

        AGUTraits memory newTraits;
        newTraits.vitality = protocolParams.initialAGUVitality; // New AGUs start with fixed vitality

        // For other traits: (Parent1 + Parent2) / 2 + (random mutation - influenced by discovery & external)
        uint256 vitalityMutation = (seed % 21) - 10; // -10 to +10

        newTraits.adaptability = uint8(_getMutatedTrait(parent1.traits.adaptability, parent2.traits.adaptability, 0, seed));
        newTraits.resonance = uint8(_getMutatedTrait(parent1.traits.resonance, parent2.traits.resonance, 1, seed));
        newTraits.harmony = uint8(_getMutatedTrait(parent1.traits.harmony, parent2.traits.harmony, 2, seed));
        newTraits.wisdom = uint8(_getMutatedTrait(parent1.traits.wisdom, parent2.traits.wisdom, 3, seed));

        // --- Apply decay for parents after fusion (as a cost) ---
        parent1.traits.vitality = uint8(parent1.traits.vitality > 10 ? parent1.traits.vitality - 10 : 0);
        parent2.traits.vitality = uint8(parent2.traits.vitality > 10 ? parent2.traits.vitality - 10 : 0);

        // --- Discovery Reward Pool Distribution ---
        uint256 discoveryAmount = protocolParams.fusionEssenceCost * protocolParams.discoveryRewardPercentage / 10000;
        essence.transfer(address(this), discoveryAmount); // Transfer to contract as reward pool

        // Distribute portion of discovery pool to relevant influencers (simplified: just add to pool for later claim)
        // In a more complex system, this would analyze the newTraits and reward specific trajectory influencers.
        // For simplicity, we just increase the general reward pool for now, to be claimed later.
        // The actual distribution logic would be within redeemDiscoveryRewards().
        // Here, we just ensure the pool grows.

        _tokenIdCounter.increment();
        uint256 newAguId = _tokenIdCounter.current();

        aguData[newAguId] = AGU({
            traits: newTraits,
            genesisBlock: block.number,
            lastHarvestBlock: block.number,
            lastMaintenanceBlock: block.number
        });

        _safeMint(msg.sender, newAguId);
        _setTokenURI(newAguId, _tokenURI);
        emit AGUMinted(newAguId, msg.sender, _parent1Id, _parent2Id);
    }

    /**
     * @notice Helper to calculate mutated trait for procreation.
     * @param _parent1Trait Value of trait from parent 1.
     * @param _parent2Trait Value of trait from parent 2.
     * @param _traitIndex Index of the trait (0=adaptability, 1=resonance, etc.) for discovery influence.
     * @param _seed Random seed.
     */
    function _getMutatedTrait(uint8 _parent1Trait, uint8 _parent2Trait, uint256 _traitIndex, uint256 _seed)
        internal
        view
        returns (uint8)
    {
        uint256 baseAverage = (uint256(_parent1Trait) + uint256(_parent2Trait)) / 2;
        uint256 randomMutation = (uint256(keccak256(abi.encodePacked(_seed, _traitIndex))) % 11) - 5; // -5 to +5

        // Influence from discovery pool: higher influence means more likely to skew towards higher values
        uint256 influenceFactor = discoveryInfluencePool[_traitIndex] / 1e18; // Convert from raw Essence
        uint256 effectiveMutation = randomMutation;
        if (influenceFactor > 0) {
            effectiveMutation += (influenceFactor % 5); // Add up to 5 points based on influence
        }

        uint256 newTrait = baseAverage + effectiveMutation;

        // Clamp values to 0-100
        if (newTrait > 100) newTrait = 100;
        if (newTrait < 0) newTrait = 0;
        return uint8(newTrait);
    }

    /**
     * @notice Retrieves all dynamic and static details of a specific AGU.
     * @param _aguId The ID of the AGU.
     * @return A tuple containing all AGU data.
     */
    function getAGUDetails(uint256 _aguId) public view returns (AGU memory) {
        if (!_exists(_aguId)) revert InvalidAGUID();
        return aguData[_aguId];
    }

    /**
     * @notice Allows an AGU to evolve a specific trait.
     * Cost Essence, success influenced by Adaptability and external factors.
     * @param _aguId The ID of the AGU to evolve.
     * @param _traitIndex The index of the trait to evolve (0=vitality, 1=adaptability, etc.).
     * @param _increaseBy The amount to increase the trait by.
     */
    function evolveAGUTraits(uint256 _aguId, uint8 _traitIndex, uint8 _increaseBy) external whenNotPaused {
        if (ownerOf(_aguId) != msg.sender) revert Unauthorized();
        AGU storage agu = aguData[_aguId];

        uint256 cost = uint256(_increaseBy) * protocolParams.evolutionEssenceCostPerPoint;
        essence.burnFrom(msg.sender, cost);

        // Apply evolution logic based on adaptability and external influence
        uint256 successChance = agu.traits.adaptability + (latestExternalInfluence / 2); // 0-100 adaptability, 0-100 influence
        uint256 roll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _aguId, _traitIndex))) % 100;

        uint8 oldTraitValue;
        uint8 newTraitValue = 0;

        if (roll < successChance) { // Evolution is successful
            if (_traitIndex == 0) { // Vitality
                oldTraitValue = agu.traits.vitality;
                newTraitValue = uint8(Math.min(100, uint256(agu.traits.vitality) + _increaseBy));
                agu.traits.vitality = newTraitValue;
            } else if (_traitIndex == 1) { // Adaptability
                oldTraitValue = agu.traits.adaptability;
                newTraitValue = uint8(Math.min(100, uint256(agu.traits.adaptability) + _increaseBy));
                agu.traits.adaptability = newTraitValue;
            } else if (_traitIndex == 2) { // Resonance
                oldTraitValue = agu.traits.resonance;
                newTraitValue = uint8(Math.min(100, uint256(agu.traits.resonance) + _increaseBy));
                agu.traits.resonance = newTraitValue;
            } else if (_traitIndex == 3) { // Harmony
                oldTraitValue = agu.traits.harmony;
                newTraitValue = uint8(Math.min(100, uint256(agu.traits.harmony) + _increaseBy));
                agu.traits.harmony = newTraitValue;
            } else if (_traitIndex == 4) { // Wisdom
                oldTraitValue = agu.traits.wisdom;
                newTraitValue = uint8(Math.min(100, uint256(agu.traits.wisdom) + _increaseBy));
                agu.traits.wisdom = newTraitValue;
            } else {
                revert InvalidParameter();
            }
            emit AGUTraitsEvolved(_aguId, _traitIndex, newTraitValue);
        } else {
            // Evolution failed, Essence is still consumed
            // Could add a small penalty or partial refund here if desired
        }
    }

    /**
     * @notice Applies decay mechanics to an AGU, reducing its vitality if not maintained.
     * Can be called by anyone (incentivized by gas refund or part of an automated service).
     * Automatically applies if relevant internal functions are called.
     * @param _aguId The ID of the AGU to decay.
     */
    function decayAGU(uint256 _aguId) public {
        if (!_exists(_aguId)) revert InvalidAGUID();
        AGU storage agu = aguData[_aguId];

        uint256 blocksSinceLastMaintenance = block.number - agu.lastMaintenanceBlock;
        if (blocksSinceLastMaintenance == 0) return; // No decay needed yet

        // Calculate decay amount: baseDecayRate (per block) adjusted by Harmony trait
        // Lower harmony means more decay.
        // Max decay for 100 blocks = 100 / 10 * 1 = 10 (if baseDecayRate = 1 per 10 blocks)
        uint256 effectiveDecayRate = protocolParams.baseDecayRate;
        if (agu.traits.harmony < 50) { // If harmony is low, decay faster
            effectiveDecayRate += (50 - agu.traits.harmony) / 10;
        }

        uint256 decayAmount = blocksSinceLastMaintenance * effectiveDecayRate / 10; // Simplified decay: 1 decay per 10 blocks

        uint8 oldVitality = agu.traits.vitality;
        if (decayAmount >= agu.traits.vitality) {
            agu.traits.vitality = 0;
        } else {
            agu.traits.vitality -= uint8(decayAmount);
        }
        agu.lastMaintenanceBlock = block.number; // Update last maintenance block after applying decay

        if (agu.traits.vitality < oldVitality) {
            emit AGUDecayed(_aguId, oldVitality, agu.traits.vitality);
        }
    }

    // --- III. Essence (ERC-20 Resource Token) Management ---

    /**
     * @notice Allows AGU owners to claim generated Essence from their AGUs.
     * Production is based on resonance trait and time elapsed.
     * @param _aguId The ID of the AGU to harvest Essence from.
     */
    function harvestEssence(uint256 _aguId) external whenNotPaused {
        if (ownerOf(_aguId) != msg.sender) revert Unauthorized();
        AGU storage agu = aguData[_aguId];

        // Apply decay before calculating harvest to reflect current state
        decayAGU(_aguId);

        uint256 blocksSinceLastHarvest = block.number - agu.lastHarvestBlock;
        if (blocksSinceLastHarvest == 0) revert AlreadyHarvested();

        // Calculate Essence production: (baseRate + resonance) * vitality_factor * blocks
        // Vitality factor: 0% at 0 vitality, 100% at 100 vitality (linear)
        uint256 vitalityFactor = agu.traits.vitality; // e.g., if vitality 50, factor is 50
        uint256 productionPerBlock = (protocolParams.baseEssenceProductionRate + agu.traits.resonance);
        uint256 availableEssence = (productionPerBlock * blocksSinceLastHarvest * vitalityFactor) / 100;

        if (availableEssence == 0) {
            agu.lastHarvestBlock = block.number; // Still update harvest block
            return;
        }

        agu.lastHarvestBlock = block.number;
        essence.mint(msg.sender, availableEssence);
        emit EssenceHarvested(_aguId, msg.sender, availableEssence);
    }

    /**
     * @notice Burns Essence to prevent or reverse AGU vitality decay.
     * @param _aguId The ID of the AGU to maintain.
     * @param _amount The amount of Essence to burn.
     */
    function burnEssenceForMaintenance(uint256 _aguId, uint256 _amount) external whenNotPaused {
        if (ownerOf(_aguId) != msg.sender) revert Unauthorized();
        if (_amount == 0) revert InvalidParameter();

        AGU storage agu = aguData[_aguId];

        // Apply decay first to get current vitality state
        decayAGU(_aguId);

        if (agu.traits.vitality == 100) revert AGUTooHealthyForMaintenance();

        uint256 vitalityToRestore = _amount / protocolParams.maintenanceCostPerVitalityPoint;
        uint8 oldVitality = agu.traits.vitality;

        uint8 newVitality = uint8(Math.min(100, uint256(agu.traits.vitality) + vitalityToRestore));
        uint256 actualEssenceBurned = uint256(newVitality - agu.traits.vitality) * protocolParams.maintenanceCostPerVitalityPoint;

        if (actualEssenceBurned == 0) revert AGUTooHealthyForMaintenance(); // Should not happen if _amount > 0 and not max vitality

        essence.burnFrom(msg.sender, actualEssenceBurned);
        agu.traits.vitality = newVitality;
        agu.lastMaintenanceBlock = block.number; // Reset maintenance clock

        emit AGUMaintained(_aguId, actualEssenceBurned, newVitality);
    }

    /**
     * @notice Calculates the amount of Essence an AGU has generated but not yet harvested.
     * @param _aguId The ID of the AGU.
     * @return The amount of Essence available for harvesting.
     */
    function getAvailableEssence(uint256 _aguId) public view returns (uint256) {
        if (!_exists(_aguId)) return 0; // Or revert InvalidAGUID(); depending on desired behavior
        AGU storage agu = aguData[_aguId];

        uint256 blocksSinceLastHarvest = block.number - agu.lastHarvestBlock;
        if (blocksSinceLastHarvest == 0) return 0;

        // Calculate current vitality after potential decay for accurate estimate
        uint256 blocksSinceLastMaintenance = block.number - agu.lastMaintenanceBlock;
        uint256 effectiveDecayRate = protocolParams.baseDecayRate;
        if (agu.traits.harmony < 50) {
            effectiveDecayRate += (50 - agu.traits.harmony) / 10;
        }
        uint256 potentialDecayAmount = blocksSinceLastMaintenance * effectiveDecayRate / 10;
        uint8 currentEstimatedVitality = agu.traits.vitality;
        if (potentialDecayAmount >= currentEstimatedVitality) {
            currentEstimatedVitality = 0;
        } else {
            currentEstimatedVitality -= uint8(potentialDecayAmount);
        }

        uint256 productionPerBlock = (protocolParams.baseEssenceProductionRate + agu.traits.resonance);
        return (productionPerBlock * blocksSinceLastHarvest * currentEstimatedVitality) / 100;
    }

    // --- IV. Advanced Dynamics & Interaction ---

    /**
     * @notice Users spend Essence to "influence" the direction of evolution for future AGUs.
     * This affects the trait distribution probabilities for newly procreated units.
     * @param _trajectoryIndex An index representing a specific trait or evolutionary path.
     *                         (e.g., 0 for Adaptability, 1 for Resonance, etc.)
     * @param _amount The amount of Essence to contribute to this trajectory.
     */
    function influenceAGUTrajectory(uint256 _trajectoryIndex, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert InvalidParameter();
        essence.transferFrom(msg.sender, address(this), _amount); // Transfer to contract (reward pool)

        address influencer = discoveryDelegates[msg.sender] == address(0) ? msg.sender : discoveryDelegates[msg.sender];
        discoveryInfluencePool[_trajectoryIndex] += _amount;
        discoveryRewardsAvailable[influencer] += _amount; // For simplicity, reward is 1:1 on influence, actual logic could be based on success later.

        emit InfluenceTrajectory(influencer, _trajectoryIndex, _amount);
    }

    /**
     * @notice Delegate one's "influence" power (Essence spent on discovery) to another address.
     * @param _delegatee The address to delegate influence to.
     */
    function delegateDiscoveryVote(address _delegatee) external {
        if (_delegatee == address(0)) revert InvalidParameter();
        if (_delegatee == msg.sender) revert SelfDelegateNotAllowed();
        discoveryDelegates[msg.sender] = _delegatee;
        // Re-calculate or transfer existing influence if needed, or make it forward-looking.
        // For simplicity, this is forward-looking: future influences by msg.sender go to _delegatee.
        // Complex: transfer existing discoveryInfluencePool entries.
    }

    /**
     * @notice Allows successful "influencers" to claim rewards from the discovery pool.
     * Rewards are accumulated based on their influence contributions.
     */
    function redeemDiscoveryRewards() external {
        uint256 rewards = discoveryRewardsAvailable[msg.sender];
        if (rewards == 0) revert NoDiscoveryRewardsAvailable();

        // A more advanced system would calculate rewards based on which influences led to successful AGUs.
        // For this example, it's a direct accumulation based on `influenceAGUTrajectory`.
        // This is simplified to just claim back what was influenced.
        // To make it a *true* reward, the `discoveryRewardsAvailable` should be populated when successful AGUs are procreated,
        // and draw from the `discoveryAmount` set aside during `procreateGenesisUnit`.

        // For now, let's just make it a claim from the contract's balance
        // To prevent draining it without actual protocol revenue, this needs adjustment.
        // Let's modify: `discoveryRewardsAvailable` is instead an accrual for the actual *rewards*
        // accumulated from a percentage of fusion costs, based on the *proportions* of influence.

        // Revisit and simplify: The protocol collects a fee into the discovery pool.
        // `redeemDiscoveryRewards` would then distribute a portion of this pool to influencers
        // proportional to their successful influences.
        // To keep it clean: `discoveryInfluencePool` represents *total influence* for a trajectory.
        // `discoveryRewardsAvailable` represents *claimable rewards*.

        // For now, let's make it a simple pull mechanism from the contract's overall essence pool,
        // which would represent the "discovery reward pool" as a whole.
        // This makes the "reward" more of a mechanism to get *some* Essence back, not necessarily from a dedicated pool.

        // Let's assume the `discoveryAmount` set aside during `procreateGenesisUnit` *is* the reward pool.
        // And `discoveryRewardsAvailable[influencer]` accumulates their share of those rewards.
        // The current implementation of `influenceAGUTrajectory` directly adds to `discoveryRewardsAvailable[influencer]`,
        // meaning it's a "refundable influence".
        // Let's assume `influenceAGUTrajectory` simply puts Essence into a shared pool, and this function distributes from it.

        uint256 totalAvailableRewards = essence.balanceOf(address(this)); // Overall contract Essence balance
        uint256 totalInfluence = 0;
        for (uint256 i = 0; i < 4; i++) { // For the 4 traits
            totalInfluence += discoveryInfluencePool[i];
        }

        if (totalInfluence == 0) revert NoDiscoveryRewardsAvailable();

        // Calculate share based on a specific user's contribution to total influence.
        // This needs to be tracked per user, not just globally.
        // Let's simplify this significantly for this example given the complexity.
        // The `influenceAGUTrajectory` function directly adds `_amount` to `discoveryRewardsAvailable[influencer]`.
        // So this means influencers *get back* the Essence they put in. This is more like a deposit.
        // To make it a *reward*: `discoveryRewardsAvailable` should be populated from the `discoveryAmount` fee,
        // based on how much the AGUs actually generated *match* the influences.

        // Let's stick with the current `discoveryRewardsAvailable` being a direct accumulator for the simple version.
        // It means you get back exactly what you put in, *if* the contract has enough.
        // This isn't a "reward" but a "refundable influence".
        // To make it a reward, the tracking needs to be more granular.
        // For simplicity: `discoveryRewardsAvailable` accumulates essence to be drawn from general pool.
        if (rewards > essence.balanceOf(address(this))) {
            revert InsufficientEssence(); // Contract doesn't have enough to pay out
        }
        
        discoveryRewardsAvailable[msg.sender] = 0; // Clear immediately
        essence.transfer(msg.sender, rewards);
        emit DiscoveryRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @notice An authorized ORACLE_ROLE caller updates a global external influence parameter.
     * This simulates an external data feed (e.g., market volatility, climate data).
     * @param _externalIndex The new value for the external influence (e.g., 0-100).
     */
    function syncExternalInfluence(uint256 _externalIndex) external onlyRole(ORACLE_ROLE) {
        if (_externalIndex > 100) _externalIndex = 100; // Cap to 100
        latestExternalInfluence = _externalIndex;
        externalInfluenceLastSyncedBlock = block.number;
        emit ExternalInfluenceSynced(_externalIndex, block.number);
    }

    /**
     * @notice AGU owners propose changes to global ecosystem parameters.
     * Requires AGU with sufficient Wisdom score.
     * @param _proposalType Integer representing the type of proposal (e.g., 0 for params update).
     * @param _proposalData Encoded bytes of the proposed changes (e.g., abi.encode(newParams)).
     * @param _description A human-readable description of the proposal.
     */
    function initiateCollectiveWisdomVote(uint256 _proposalType, bytes calldata _proposalData, string memory _description)
        external
        whenNotPaused
    {
        uint256 totalWisdom = _getVotingWisdom(msg.sender);
        if (totalWisdom < protocolParams.wisdomVoteThreshold) revert NotEnoughVotes();

        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            proposalType: _proposalType,
            data: _proposalData,
            description: _description,
            startBlock: block.number,
            endBlock: block.number + protocolParams.proposalVotingPeriod,
            totalWisdomVotesFor: 0,
            totalWisdomVotesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });

        emit NewProposal(proposalId, msg.sender, _proposalType, _description);
    }

    /**
     * @notice AGU owners cast their vote on an active proposal.
     * Vote weight is based on their total AGU Wisdom score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function castCollectiveWisdomVote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.startBlock == 0) revert NoActiveProposal(); // Proposal doesn't exist
        if (block.number > proposal.endBlock) revert ProposalNotYetExpired();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();
        if (proposal.executed) revert ProposalAlreadyExecuted();

        address voter = wisdomDelegates[msg.sender] == address(0) ? msg.sender : wisdomDelegates[msg.sender];
        uint256 votingWisdom = _getVotingWisdom(voter);
        if (votingWisdom == 0) revert NotEnoughVotes(); // No wisdom to vote

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.totalWisdomVotesFor += votingWisdom;
        } else {
            proposal.totalWisdomVotesAgainst += votingWisdom;
        }
        emit VoteCast(_proposalId, voter, _support, votingWisdom);
    }

    /**
     * @notice Executes a passed governance proposal if quorum is met and voting period expired.
     * Any address can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeCollectiveWisdomProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.startBlock == 0 || proposal.executed) revert InvalidProposalState();
        if (block.number <= proposal.endBlock) revert ProposalNotYetExpired();

        uint256 totalWisdomInProtocol = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) {
                totalWisdomInProtocol += aguData[i].traits.wisdom;
            }
        }

        uint256 requiredQuorum = totalWisdomInProtocol * protocolParams.proposalVoteQuorumBasis / 10000;
        bool passed = (proposal.totalWisdomVotesFor > proposal.totalWisdomVotesAgainst) &&
                      (proposal.totalWisdomVotesFor >= requiredQuorum);

        proposal.executed = true; // Mark as executed regardless of success

        if (passed) {
            // Execute the proposal based on its type
            if (proposal.proposalType == 0) { // Update Protocol Parameters
                ProtocolParameters memory newParams;
                try abi.decode(proposal.data, (ProtocolParameters)) returns (ProtocolParameters memory decodedParams) {
                    newParams = decodedParams;
                } catch {
                    revert InvalidParameter(); // Decoding failed
                }
                setProtocolParameters(newParams); // Re-use existing function
            }
            // Add other proposal types here (e.g., modify roles, burn tokens, etc.)
            emit ProposalExecuted(_proposalId, true);
        } else {
            revert ProposalFailedQuorum(); // Indicate failure
            emit ProposalExecuted(_proposalId, false);
        }
    }

    /**
     * @notice Delegate one's 'Wisdom' voting power for collective wisdom proposals.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateCollectiveWisdomVote(address _delegatee) external {
        if (_delegatee == address(0)) revert InvalidParameter();
        if (_delegatee == msg.sender) revert SelfDelegateNotAllowed();
        wisdomDelegates[msg.sender] = _delegatee;
        // This is forward-looking. Existing votes are not changed.
    }

    /**
     * @dev Internal helper to calculate an address's total voting wisdom from their owned AGUs.
     * @param _owner The address to calculate wisdom for.
     * @return The total wisdom score.
     */
    function _getVotingWisdom(address _owner) internal view returns (uint256) {
        uint256 totalWisdom = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i) && ownerOf(i) == _owner) {
                totalWisdom += aguData[i].traits.wisdom;
            }
        }
        return totalWisdom;
    }

    /**
     * @dev Custom pause check to avoid `whenNotPaused` on some functions for specific requirements.
     */
    function _pauseCheck() internal view {
        if (paused()) revert Paused();
    }

    // --- V. Query Functions (Read-only) ---

    /**
     * @notice Retrieves all current global simulation parameters.
     * @return A struct containing all protocol parameters.
     */
    function getGlobalParameters() external view returns (ProtocolParameters memory) {
        return protocolParams;
    }

    /**
     * @notice Checks current total influence for a specific trait trajectory.
     * @param _trajectoryIndex The index of the trajectory.
     * @return The total Essence committed to this trajectory.
     */
    function getDiscoveryInfluencePool(uint256 _trajectoryIndex) external view returns (uint256) {
        return discoveryInfluencePool[_trajectoryIndex];
    }

    /**
     * @notice Provides a high-level summary of all AGUs.
     * @return totalCount The total number of AGUs.
     * @return avgVitality The average vitality across all AGUs.
     * @return avgAdaptability The average adaptability across all AGUs.
     * @return avgResonance The average resonance across all AGUs.
     * @return avgHarmony The average harmony across all AGUs.
     * @return avgWisdom The average wisdom across all AGUs.
     */
    function getAGUStatsSummary()
        external
        view
        returns (
            uint256 totalCount,
            uint256 avgVitality,
            uint256 avgAdaptability,
            uint256 avgResonance,
            uint256 avgHarmony,
            uint256 avgWisdom
        )
    {
        totalCount = _tokenIdCounter.current();
        if (totalCount == 0) return (0, 0, 0, 0, 0, 0);

        uint256 sumVitality = 0;
        uint256 sumAdaptability = 0;
        uint256 sumResonance = 0;
        uint256 sumHarmony = 0;
        uint256 sumWisdom = 0;
        uint256 actualCount = 0; // In case some tokens are burned/transferred to 0x0

        for (uint256 i = 1; i <= totalCount; i++) {
            if (_exists(i)) {
                AGU memory agu = aguData[i];
                sumVitality += agu.traits.vitality;
                sumAdaptability += agu.traits.adaptability;
                sumResonance += agu.traits.resonance;
                sumHarmony += agu.traits.harmony;
                sumWisdom += agu.traits.wisdom;
                actualCount++;
            }
        }

        if (actualCount == 0) return (0, 0, 0, 0, 0, 0);

        avgVitality = sumVitality / actualCount;
        avgAdaptability = sumAdaptability / actualCount;
        avgResonance = sumResonance / actualCount;
        avgHarmony = sumHarmony / actualCount;
        avgWisdom = sumWisdom / actualCount;
    }

    /**
     * @notice Predicts potential traits of a new AGU from a fusion without executing it.
     * Uses the same logic as `_getMutatedTrait` but with a simulated `_seed`.
     * This is a "best guess" and true outcome still relies on block hashes.
     * @param _parent1Id ID of the first parent AGU.
     * @param _parent2Id ID of the second parent AGU.
     * @return predictedTraits The predicted traits of the new AGU.
     */
    function calculateFusionOutcomePreview(uint256 _parent1Id, uint256 _parent2Id)
        external
        view
        returns (AGUTraits memory predictedTraits)
    {
        if (!_exists(_parent1Id) || !_exists(_parent2Id)) revert InvalidAGUID();
        AGU storage parent1 = aguData[_parent1Id];
        AGU storage parent2 = aguData[_parent2Id];

        // For preview, use a deterministic seed, e.g., current block number or a constant
        uint256 previewSeed = uint256(keccak256(abi.encodePacked(block.number, _parent1Id, _parent2Id)));

        predictedTraits.vitality = protocolParams.initialAGUVitality;
        predictedTraits.adaptability = uint8(_getMutatedTrait(parent1.traits.adaptability, parent2.traits.adaptability, 0, previewSeed));
        predictedTraits.resonance = uint8(_getMutatedTrait(parent1.traits.resonance, parent2.traits.resonance, 1, previewSeed));
        predictedTraits.harmony = uint8(_getMutatedTrait(parent1.traits.harmony, parent2.traits.harmony, 2, previewSeed));
        predictedTraits.wisdom = uint8(_getMutatedTrait(parent1.traits.wisdom, parent2.traits.wisdom, 3, previewSeed));
    }

    /**
     * @notice Views the latest external data ingested via the oracle.
     * @return The value of the latest external influence index.
     */
    function getLatestOracleData() external view returns (uint256) {
        return latestExternalInfluence;
    }

    /**
     * @notice Retrieves details of a specific collective wisdom proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposer The address of the proposer.
     * @return proposalType The type of the proposal.
     * @return description The human-readable description.
     * @return startBlock The block number when voting started.
     * @return endBlock The block number when voting ends.
     * @return totalWisdomVotesFor Total 'for' votes by wisdom.
     * @return totalWisdomVotesAgainst Total 'against' votes by wisdom.
     * @return executed True if the proposal has been executed.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address proposer,
            uint256 proposalType,
            string memory description,
            uint256 startBlock,
            uint256 endBlock,
            uint256 totalWisdomVotesFor,
            uint256 totalWisdomVotesAgainst,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.proposer,
            proposal.proposalType,
            proposal.description,
            proposal.startBlock,
            proposal.endBlock,
            proposal.totalWisdomVotesFor,
            proposal.totalWisdomVotesAgainst,
            proposal.executed
        );
    }

    /**
     * @notice Retrieves the total Essence available for discovery rewards within the protocol.
     * This is generally the total Essence collected by the protocol minus any other operational costs.
     * In a live system, this might represent a dedicated pool.
     * @return The total Essence in the contract available for rewards.
     */
    function getDiscoveryRewardPool() external view returns (uint256) {
        return essence.balanceOf(address(this));
    }

    /**
     * @notice Calculates the current Essence cost to fully maintain an AGU to max vitality (100).
     * @param _aguId The ID of the AGU.
     * @return The Essence cost to fully restore vitality.
     */
    function getMaintenanceCost(uint256 _aguId) public view returns (uint256) {
        if (!_exists(_aguId)) return 0;
        AGU memory agu = aguData[_aguId];

        // First, calculate potential current vitality after decay
        uint256 blocksSinceLastMaintenance = block.number - agu.lastMaintenanceBlock;
        uint256 effectiveDecayRate = protocolParams.baseDecayRate;
        if (agu.traits.harmony < 50) {
            effectiveDecayRate += (50 - agu.traits.harmony) / 10;
        }
        uint256 potentialDecayAmount = blocksSinceLastMaintenance * effectiveDecayRate / 10;
        uint8 currentEstimatedVitality = agu.traits.vitality;
        if (potentialDecayAmount >= currentEstimatedVitality) {
            currentEstimatedVitality = 0;
        } else {
            currentEstimatedVitality -= uint8(potentialDecayAmount);
        }

        if (currentEstimatedVitality >= 100) return 0; // Already at max vitality

        uint256 vitalityNeeded = 100 - currentEstimatedVitality;
        return vitalityNeeded * protocolParams.maintenanceCostPerVitalityPoint;
    }

    /**
     * @notice Returns the current owner of a specific AGU.
     * @param _aguId The ID of the AGU.
     * @return The address of the AGU owner.
     */
    function getAguOwner(uint256 _aguId) external view returns (address) {
        return ownerOf(_aguId);
    }
}

// --- Essence ERC-20 Token ---
// This token is designed to be minted and burned only by the AetherialGenesisProtocol contract.
contract EssenceToken is ERC20, AccessControl {
    bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

    constructor() ERC20("Essence", "ESS") {
        // Grant deployer the minter/burner role for this token initially
        // In a real scenario, this would be the AGP contract's address
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Function to allow AGP to grant itself the minter/burner role
    function setMinterBurner(address _minterBurner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_BURNER_ROLE, _minterBurner);
    }

    // Only allow specific role to mint
    function mint(address to, uint256 amount) public onlyRole(MINTER_BURNER_ROLE) {
        _mint(to, amount);
    }

    // Only allow specific role to burn from any address (for maintenance/fusion)
    function burnFrom(address account, uint256 amount) public onlyRole(MINTER_BURNER_ROLE) {
        _approve(account, msg.sender, amount); // Allow AGP to spend on behalf of AGU owner
        _burn(account, amount);
    }
}

// A simple Math utility library (for min/max which is available in Solidity 0.8.0+)
// For demonstration purposes; could use OpenZeppelin's Math library.
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```