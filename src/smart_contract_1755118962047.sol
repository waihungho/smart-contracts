```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit safety, though Solidity 0.8+ has overflow checks

/*
    ChronoWeaver Genesis: Adaptive Algorithmic Entities Ecosystem

    Outline:
    ChronoWeaver Genesis is a decentralized ecosystem built around "ChronoWeavers" (ERC721 NFTs)
    and "Chronos" (ERC20 fungible tokens). ChronoWeavers are designed as dynamic, evolving digital
    entities whose properties (Essence) change based on user interactions, internal lifecycle,
    and global environmental factors. The system incorporates gamified mechanics, resource management,
    and a decentralized governance model through a "Nexus Pool."

    Core Concepts:
    1.  ChronoWeavers (ERC721): Unique NFTs with dynamic "Essence" (stats) that evolve. Their metadata
        is dynamic and influenced by on-chain actions and time.
    2.  Chronos (ERC20): The ecosystem's native currency, used for Weaver interactions (evolution, sustenance)
        and staking in the Nexus Pool. It acts as the "energy" or "data essence" for Weavers.
    3.  Dynamic Essence: Each Weaver has mutable stats (stability, agility, creativity, resonance, affinity, experience)
        that change over time or through specific actions. These stats determine their performance and outcomes.
    4.  Lifecycle Mechanics: Weavers can be "sustained" to prevent decay, "evolved" to improve stats,
        "bonded" to potentially create new Weavers (procreation), and can passively "generate" Chronos.
        Neglected Weavers can "decay."
    5.  Environmental Factors: Global parameters (e.g., evolution cost, decay rate) influenced by governance
        or external inputs, affecting all Weavers. These simulate an "ecosystem climate."
    6.  Nexus Pool: A staking mechanism for Chronos holders, granting voting power in governance proposals
        and enabling collective influence over the ecosystem's evolution. A portion of fees accrues here as rewards.
    7.  Advanced Functions: Includes "Temporal Lock" (pausing evolution and decay for a period),
        "Disperse Essence" (burning a Weaver for partial Chronos refund), "Attunement" (changing a Weaver's affinity),
        and on-chain "Lore" tracking for Weavers' historical events.

    Function Summary (28 functions):

    I. ChronoWeaver NFT (ERC721) Management:
    1.  `mintWeaver(address _to)`: Mints a new ChronoWeaver NFT to a specified address, initializing its Essence with
        pseudo-randomized base stats.
    2.  `getWeaverEssence(uint256 _tokenId)`: Retrieves the current dynamic Essence (stats) of a ChronoWeaver.
    3.  `evolveWeaver(uint256 _tokenId)`: Triggers the evolution of a Weaver, consuming Chronos and potentially
        improving its stats based on accumulated experience. Checks for temporal lock and applies decay first.
    4.  `sustainWeaver(uint256 _tokenId)`: Prevents a Weaver's decay and boosts its stability by consuming Chronos.
        Resets its decay timer.
    5.  `bondWeavers(uint256 _weaver1Id, uint256 _weaver2Id)`: Allows two Weaver owners to combine their NFTs
        (requiring approval) to potentially create a new Weaver based on their creativity stats and a success rate.
        Consumes Chronos.
    6.  `attuneWeaver(uint256 _tokenId, uint8 _newAffinity)`: Changes a Weaver's elemental affinity (e.g., Fire, Water, Aether)
        at a Chronos cost, influencing its properties and potential future interactions.
    7.  `initiateTemporalLock(uint256 _tokenId, uint256 _lockDuration)`: Places a Weaver in a "temporal lock,"
        pausing its decay and evolution for a specified period, offering stability at a Chronos cost.
    8.  `disperseEssence(uint256 _tokenId)`: Allows a Weaver owner to "disperse" (burn) their Weaver,
        reclaiming a portion of its essence as Chronos based on its stats and a refund rate.
    9.  `getWeaverLineage(uint256 _tokenId)`: Retrieves the parent Weaver IDs for a given Weaver, if it was created via bonding.
    10. `queryWeaverLore(uint256 _tokenId)`: Returns a history of significant events (evolution, sustenance, bonding, decay, etc.)
        that have occurred to a specific Weaver, serving as its on-chain "biography."
    11. `decayWeaver(uint256 _tokenId)`: Allows anyone to trigger the decay process for a neglected Weaver (not sustained
        within the decay threshold), reducing its stats and rewarding the caller a small amount of Chronos.
    12. `claimChronos(uint256 _tokenId)`: Allows a Weaver's owner to claim passively generated Chronos by their Weaver,
        based on its resonance and the time since the last claim. Accumulates experience for the Weaver.
    13. `tokenURI(uint256 _tokenId)`: (ERC721URIStorage Override) Placeholder for generating dynamic metadata URI for the Weaver.
    14. `transferFrom`, `approve`, `setApprovalForAll`, `balanceOf`, `ownerOf`, `supportsInterface`: Standard ERC721
        functions inherited and used for NFT transfer and approval mechanisms.

    II. Chronos Token (ERC20) Management:
    15. `mintInitialChronos(address _to, uint256 _amount)`: (Admin) Mints initial Chronos supply to a specific address,
        used for bootstrapping the ecosystem.
    16. `transfer`, `approve`, `transferFrom`, `balanceOf`, `totalSupply`: Standard ERC20 functions inherited for
        Chronos token management.

    III. Governance & Ecosystem Parameters:
    17. `updateEnvironmentalFactor(uint8 _factorType, uint256 _newValue)`: (Admin/Oracle) Updates a global environmental
        parameter that affects Weaver behavior or costs. Limited to non-governance parameters for direct admin control.
    18. `proposeParameterChange(string memory _description, uint8 _paramType, uint256 _newValue)`:
        Allows Nexus Pool stakers to propose changes to core ecosystem parameters, initiating a voting process.
    19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows Nexus Pool stakers to vote on active proposals
        using their staked Chronos as voting power.
    20. `executeProposal(uint256 _proposalId)`: Executes a successfully voted-on proposal, applying the proposed
        parameter change if quorum and majority conditions are met.
    21. `setEvolutionCost(uint256 _cost)`: (Admin/Governance) Sets the Chronos cost required for a Weaver to evolve.
        Can be controlled by admin or governance.
    22. `setBondingParameters(uint256 _cost, uint256 _successRate)`: (Admin/Governance) Sets the Chronos cost and
        success probability for Weaver bonding.
    23. `toggleGlobalFeature(uint8 _featureIndex, bool _enabled)`: (Admin/Governance) Enables or disables specific
        global features like decay or bonding, providing ecosystem adaptability and control.

    IV. Nexus Pool (Staking & Rewards):
    24. `contributeToNexusPool(uint256 _amount)`: Allows users to stake Chronos tokens into the Nexus Pool to gain
        voting power and earn rewards from collected ecosystem fees.
    25. `claimNexusPoolRewards()`: Allows stakers to claim their accrued Chronos rewards from the Nexus Pool,
        distributed proportionally to their stake and time.
    26. `withdrawFromNexusPool(uint256 _amount)`: Allows stakers to withdraw their staked Chronos from the Nexus Pool.

    V. System & Utility:
    27. `getSystemMetrics()`: Provides a quick overview of global ecosystem statistics (e.g., total Weavers,
        total Chronos supply, Nexus Pool balance).
    28. `emergencyPause()`, `emergencyUnpause()`: (Admin) Functions to pause/unpause critical contract functionalities
        in case of an emergency or maintenance.
*/

// --- Helper Structs and Enums ---

// Represents the dynamic attributes of a ChronoWeaver
struct ChronoWeaverEssence {
    uint8 stability;        // Resistance to decay, max 100
    uint8 agility;          // Speed of actions/efficiency, max 100
    uint8 creativity;       // Chance of unique outcomes in bonding/evolution, max 100
    uint8 resonance;        // Rate of Chronos generation/attraction, max 100
    uint8 affinity;         // Elemental type (e.g., 0:None, 1:Fire, 2:Water, 3:Earth, 4:Air, 5:Aether)
    uint256 lastSustainedBlock; // Block number when last sustained, for decay logic
    uint256 creationBlock;  // Block number when the Weaver was minted
    uint256 lastChronosClaimBlock; // Block number when Chronos was last claimed
    uint256 lineageParent1; // Token ID of parent 1 (0 if not bonded)
    uint256 lineageParent2; // Token ID of parent 2 (0 if not bonded)
    uint256 accumulatedExperience; // Points gained from interactions, used for evolution
    bool isTemporallyLocked; // True if under temporal lock
    uint256 temporalLockUntil; // Block number until which the Weaver is locked
}

// Represents an event in a Weaver's lore
struct WeaverLoreEvent {
    string eventType;   // e.g., "Mint", "Evolve", "Sustain", "Bond", "Attune", "Decay"
    uint256 timestamp;  // Block timestamp of the event
    string details;     // Additional details (e.g., "improved stability", "bonded with #XYZ")
}

// Represents a governance proposal
struct Proposal {
    string description;
    uint8 paramType;        // Enum for which parameter is being changed
    uint256 newValue;       // The proposed new value
    uint256 voteStartTime;
    uint256 voteEndTime;
    uint256 yesVotes;       // Total Chronos staked for 'yes'
    uint256 noVotes;        // Total Chronos staked for 'no'
    bool executed;
    mapping(address => bool) hasVoted; // User voting status
}

// Enum for types of environmental/governance parameters
enum ParameterType {
    EvolutionCost,
    DecayThreshold,
    ChronosGenerationRate,
    BondingCost,
    BondingSuccessRate,
    AttunementCost,
    TemporalLockCost,
    DispersalRefundRate,
    NexusPoolRewardRate, // Rate per block per unit of stake
    ProposalVoteDuration, // In blocks
    ProposalQuorumRate // Percentage of total Nexus Pool stake needed for a quorum (0-100)
}

// Enum for global features that can be toggled
enum GlobalFeature {
    WeaverDecay,
    WeaverBonding,
    WeaverEvolution,
    WeaverAttunement,
    WeaverTemporalLock,
    WeaverDispersal,
    WeaverChronosGeneration
}

contract ChronoWeaverGenesis is ERC721URIStorage, ERC20, Ownable, Pausable {
    using SafeMath for uint256; // Explicitly use SafeMath for all uint256 operations for clarity

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for ChronoWeaver NFTs

    // ChronoWeaver data
    mapping(uint256 => ChronoWeaverEssence) public weaverEssences;
    mapping(uint256 => WeaverLoreEvent[]) public weaverLore; // History of each Weaver

    // Ecosystem parameters (modifiable by governance or admin)
    mapping(uint8 => uint256) public environmentalFactors; // Using ParameterType enum as keys

    // Nexus Pool (Staking)
    mapping(address => uint256) public nexusStakes;
    mapping(address => uint256) public lastRewardClaimBlock; // Last block user claimed or staked
    uint256 public totalNexusStake; // Total Chronos staked in Nexus Pool
    uint256 public nexusPoolRewardsAccrued; // Chronos accumulated for distribution

    // Governance proposals
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;

    // Global Feature Toggles
    mapping(uint8 => bool) public globalFeaturesEnabled; // Using GlobalFeature enum as keys

    // --- Events ---
    event WeaverMinted(uint256 indexed tokenId, address indexed owner, uint256 creationBlock);
    event WeaverEvolved(uint256 indexed tokenId, address indexed owner, uint256 newExperience);
    event WeaverSustained(uint256 indexed tokenId, address indexed owner, uint256 currentStability);
    event WeaverBonded(uint256 indexed newWeaverId, uint256 indexed parent1Id, uint256 indexed parent2Id);
    event WeaverAttuned(uint256 indexed tokenId, uint8 oldAffinity, uint8 newAffinity);
    event WeaverTemporalLocked(uint256 indexed tokenId, uint256 lockUntilBlock);
    event WeaverEssenceDispersed(uint256 indexed tokenId, address indexed owner, uint256 chronosRefunded);
    event WeaverDecayed(uint256 indexed tokenId, address indexed trigger, uint256 newStability);
    event ChronosClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EnvironmentalFactorUpdated(uint8 indexed factorType, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event NexusContributed(address indexed contributor, uint256 amount);
    event NexusRewardsClaimed(address indexed claimant, uint256 amount);
    event NexusWithdrawn(address indexed withdrawer, uint256 amount);
    event GlobalFeatureToggled(uint8 indexed featureIndex, bool enabled);

    // --- Constructor ---
    constructor(address _initialOwner)
        ERC721("ChronoWeaver", "CWEAV")
        ERC20("Chronos", "CHRONOS")
        Ownable(_initialOwner)
        Pausable()
    {
        // Set initial environmental factors and feature states
        environmentalFactors[uint8(ParameterType.EvolutionCost)] = 100 ether; // 100 CHRONOS
        environmentalFactors[uint8(ParameterType.DecayThreshold)] = 100;      // Blocks until decay starts applying
        environmentalFactors[uint8(ParameterType.ChronosGenerationRate)] = 100000000000000000; // 0.1 CHRONOS per block per unit resonance
        environmentalFactors[uint8(ParameterType.BondingCost)] = 200 ether;   // 200 CHRONOS
        environmentalFactors[uint8(ParameterType.BondingSuccessRate)] = 70;   // 70%
        environmentalFactors[uint8(ParameterType.AttunementCost)] = 50 ether; // 50 CHRONOS
        environmentalFactors[uint8(ParameterType.TemporalLockCost)] = 150 ether; // 150 CHRONOS
        environmentalFactors[uint8(ParameterType.DispersalRefundRate)] = 50;  // 50%
        environmentalFactors[uint8(ParameterType.NexusPoolRewardRate)] = 1000000000000000; // 0.001 CHRONOS per block per staked ether
        environmentalFactors[uint8(ParameterType.ProposalVoteDuration)] = 1000; // Blocks
        environmentalFactors[uint8(ParameterType.ProposalQuorumRate)] = 20;     // 20% of total stake

        // Enable all features by default
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverDecay)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverBonding)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverEvolution)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverAttunement)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverTemporalLock)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverDispersal)] = true;
        globalFeaturesEnabled[uint8(GlobalFeature.WeaverChronosGeneration)] = true;
    }

    // --- ERC721 Overrides (from ERC721URIStorage) ---

    // @dev Returns the base URI for the token metadata.
    // In a production environment, this would typically point to an IPFS gateway or a dedicated metadata server
    // that generates JSON based on the dynamic essence of the Weaver.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://CHRONOWEAVER_METADATA_BASE_URI/";
    }

    // @dev Overrides the default tokenURI to allow for dynamic metadata based on Weaver Essence.
    // This function would likely be implemented by an off-chain service which reads `getWeaverEssence`
    // and crafts the JSON metadata, then hosts it. The URI here would just point to that service.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for non-existent token");
        // Example: "ipfs://CHRONOWEAVER_METADATA_BASE_URI/1" for token 1.
        // The actual metadata would be generated dynamically by a gateway at this URI
        // based on the Weaver's current essence.
        return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId)));
    }

    // --- Private / Internal Helpers ---

    /// @dev Generates initial random-like essence for a new ChronoWeaver.
    /// @notice This uses pseudo-randomness (block data) and is NOT cryptographically secure.
    /// For production, consider Chainlink VRF or similar verifiable randomness solutions.
    function _generateInitialEssence() private view returns (ChronoWeaverEssence memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _nextTokenId)));
        return ChronoWeaverEssence({
            stability: uint8(50 + (seed % 21)), // 50-70
            agility: uint8(50 + ((seed >> 8) % 21)),
            creativity: uint8(50 + ((seed >> 16) % 21)),
            resonance: uint8(50 + ((seed >> 24) % 21)),
            affinity: uint8(seed % 6), // 0-5 (0:None, 1:Fire, 2:Water, 3:Earth, 4:Air, 5:Aether)
            lastSustainedBlock: block.number,
            creationBlock: block.number,
            lastChronosClaimBlock: block.number,
            lineageParent1: 0,
            lineageParent2: 0,
            accumulatedExperience: 0,
            isTemporallyLocked: false,
            temporalLockUntil: 0
        });
    }

    /// @dev Adds an event entry to a Weaver's lore.
    function _addLoreEvent(uint256 _tokenId, string memory _eventType, string memory _details) private {
        weaverLore[_tokenId].push(WeaverLoreEvent({
            eventType: _eventType,
            timestamp: block.timestamp,
            details: _details
        }));
    }

    /// @dev Applies decay to a Weaver's stats if it hasn't been sustained.
    /// This is called internally by functions that interact with a Weaver's state.
    /// @param _tokenId The ID of the ChronoWeaver.
    function _applyDecay(uint256 _tokenId) internal {
        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        if (!globalFeaturesEnabled[uint8(GlobalFeature.WeaverDecay)] || essence.isTemporallyLocked) {
            return;
        }

        uint256 blocksSinceSustained = block.number.sub(essence.lastSustainedBlock);
        uint256 decayThreshold = environmentalFactors[uint8(ParameterType.DecayThreshold)];

        if (blocksSinceSustained > decayThreshold) {
            uint256 decayMagnitude = blocksSinceSustained.div(decayThreshold); // Every threshold period, decay happens
            
            uint8 oldStability = essence.stability;
            uint8 oldResonance = essence.resonance;

            essence.stability = oldStability >= decayMagnitude ? oldStability.sub(uint8(decayMagnitude)) : 0;
            essence.resonance = oldResonance >= decayMagnitude ? oldResonance.sub(uint8(decayMagnitude)) : 0;

            essence.lastSustainedBlock = block.number; // Reset after decay
            _addLoreEvent(_tokenId, "Decay", string(abi.encodePacked("Stability reduced to ", Strings.toString(essence.stability), ", Resonance to ", Strings.toString(essence.resonance))));
        }
    }

    // --- ChronoWeaver NFT Functions (ERC721) ---

    /// @notice Mints a new ChronoWeaver NFT to a specified address, initializing its Essence.
    /// @param _to The address to mint the Weaver to.
    /// @return The ID of the newly minted ChronoWeaver.
    function mintWeaver(address _to) public payable whenNotPaused returns (uint256) {
        require(_to != address(0), "ChronoWeaver: mint to zero address");

        uint256 tokenId = _nextTokenId;
        _nextTokenId = _nextTokenId.add(1);
        _safeMint(_to, tokenId);
        
        weaverEssences[tokenId] = _generateInitialEssence();
        _addLoreEvent(tokenId, "Mint", "Initial creation of ChronoWeaver.");

        emit WeaverMinted(tokenId, _to, block.number);
        return tokenId;
    }

    /// @notice Retrieves the current dynamic Essence (stats) of a ChronoWeaver.
    /// @param _tokenId The ID of the ChronoWeaver.
    /// @return The ChronoWeaverEssence struct containing all its dynamic stats.
    function getWeaverEssence(uint256 _tokenId) public view returns (ChronoWeaverEssence memory) {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        return weaverEssences[_tokenId];
    }

    /// @notice Triggers the evolution of a Weaver, consuming Chronos and potentially improving its stats.
    /// The evolution effect is proportional to accumulated experience and costs Chronos.
    /// @param _tokenId The ID of the ChronoWeaver to evolve.
    function evolveWeaver(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverEvolution)], "ChronoWeaver: Evolution is currently disabled.");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        require(!essence.isTemporallyLocked, "ChronoWeaver: Weaver is temporally locked.");
        
        _applyDecay(_tokenId); // Apply decay before evolution

        uint256 cost = environmentalFactors[uint8(ParameterType.EvolutionCost)];
        require(balanceOf(msg.sender) >= cost, "ChronoWeaver: Insufficient Chronos for evolution");
        
        _transfer(msg.sender, address(this), cost); // Transfer Chronos from user to contract
        nexusPoolRewardsAccrued = nexusPoolRewardsAccrued.add(cost.mul(90).div(100)); // 90% goes to Nexus Pool

        // Evolution logic: Improve stats based on accumulated experience (simple example)
        uint256 experienceFactor = essence.accumulatedExperience.div(1000); // Every 1000 exp, get a point
        uint8 statBoost = 1; // Base boost

        if (experienceFactor > 0) {
            statBoost = statBoost.add(uint8(experienceFactor.div(10))); // Larger boost for more experience
            essence.accumulatedExperience = 0; // Reset experience after evolution
        }

        essence.stability = essence.stability.add(statBoost) <= 100 ? essence.stability.add(statBoost) : 100;
        essence.agility = essence.agility.add(statBoost) <= 100 ? essence.agility.add(statBoost) : 100;
        essence.creativity = essence.creativity.add(statBoost) <= 100 ? essence.creativity.add(statBoost) : 100;
        essence.resonance = essence.resonance.add(statBoost) <= 100 ? essence.resonance.add(statBoost) : 100;
        
        _addLoreEvent(_tokenId, "Evolve", string(abi.encodePacked("Weaver evolved, stats boosted by ", Strings.toString(statBoost))));
        emit WeaverEvolved(_tokenId, msg.sender, essence.accumulatedExperience);
    }

    /// @notice Prevents a Weaver's decay and boosts its stability by consuming Chronos.
    /// @param _tokenId The ID of the ChronoWeaver to sustain.
    function sustainWeaver(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverDecay)], "ChronoWeaver: Decay is currently disabled, sustenance not needed.");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        require(!essence.isTemporallyLocked, "ChronoWeaver: Weaver is temporally locked.");

        uint256 cost = environmentalFactors[uint8(ParameterType.EvolutionCost)].div(2); // Half evolution cost for sustenance
        require(balanceOf(msg.sender) >= cost, "ChronoWeaver: Insufficient Chronos for sustenance");
        _transfer(msg.sender, address(this), cost); // Transfer Chronos

        essence.lastSustainedBlock = block.number;
        essence.stability = essence.stability.add(5) <= 100 ? essence.stability.add(5) : 100; // Small boost

        _addLoreEvent(_tokenId, "Sustain", "Weaver sustained, stability increased.");
        emit WeaverSustained(_tokenId, msg.sender, essence.stability);
    }

    /// @notice Allows two Weaver owners to combine their NFTs (requiring approval) to potentially create a new Weaver.
    /// Success probability is based on environmental factors and Weavers' creativity.
    /// @param _weaver1Id The ID of the first ChronoWeaver.
    /// @param _weaver2Id The ID of the second ChronoWeaver.
    function bondWeavers(uint256 _weaver1Id, uint256 _weaver2Id) public whenNotPaused {
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverBonding)], "ChronoWeaver: Bonding is currently disabled.");
        require(_exists(_weaver1Id) && _exists(_weaver2Id), "ChronoWeaver: non-existent token(s)");
        require(_weaver1Id != _weaver2Id, "ChronoWeaver: Cannot bond a Weaver with itself");

        address owner1 = ownerOf(_weaver1Id);
        address owner2 = ownerOf(_weaver2Id);
        require(owner1 == msg.sender || owner2 == msg.sender, "ChronoWeaver: Not owner of at least one Weaver");
        // Check approvals: if owners are different, current caller must be approved by the other owner.
        require(owner1 == owner2 || (getApproved(_weaver1Id) == msg.sender || isApprovedForAll(owner1, msg.sender)), "ChronoWeaver: _weaver1Id not approved for bonding by owner1");
        require(owner1 == owner2 || (getApproved(_weaver2Id) == msg.sender || isApprovedForAll(owner2, msg.sender)), "ChronoWeaver: _weaver2Id not approved for bonding by owner2");

        ChronoWeaverEssence storage essence1 = weaverEssences[_weaver1Id];
        ChronoWeaverEssence storage essence2 = weaverEssences[_weaver2Id];
        require(!essence1.isTemporallyLocked && !essence2.isTemporallyLocked, "ChronoWeaver: One or both Weavers are temporally locked.");

        uint256 cost = environmentalFactors[uint8(ParameterType.BondingCost)];
        require(balanceOf(msg.sender) >= cost, "ChronoWeaver: Insufficient Chronos for bonding");
        _transfer(msg.sender, address(this), cost); // Transfer Chronos
        nexusPoolRewardsAccrued = nexusPoolRewardsAccrued.add(cost); // Bonding fees go entirely to Nexus Pool

        // Bonding success calculation
        uint256 totalCreativity = uint256(essence1.creativity).add(essence2.creativity);
        uint256 successRate = environmentalFactors[uint8(ParameterType.BondingSuccessRate)]; // Base rate
        successRate = successRate.add(totalCreativity.div(10)); // Creativity adds to success rate (e.g., max 200 creativity adds 20%)

        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _weaver1Id, _weaver2Id))) % 100;

        if (randomness < successRate) {
            // Success: Mint new Weaver
            uint256 newWeaverId = _nextTokenId;
            _nextTokenId = _nextTokenId.add(1);
            _safeMint(msg.sender, newWeaverId);

            // New Weaver's essence attributes are averaged/influenced by parents
            weaverEssences[newWeaverId] = ChronoWeaverEssence({
                stability: uint8(uint256(essence1.stability).add(essence2.stability).div(2)),
                agility: uint8(uint256(essence1.agility).add(essence2.agility).div(2)),
                creativity: uint8(uint256(essence1.creativity).add(essence2.creativity).div(2)),
                resonance: uint8(uint256(essence1.resonance).add(essence2.resonance).div(2)),
                affinity: uint8(uint256(essence1.affinity).add(essence2.affinity).div(2) % 6), // Average affinity, modulo 6 to stay in range
                lastSustainedBlock: block.number,
                creationBlock: block.number,
                lastChronosClaimBlock: block.number,
                lineageParent1: _weaver1Id,
                lineageParent2: _weaver2Id,
                accumulatedExperience: 0,
                isTemporallyLocked: false,
                temporalLockUntil: 0
            });
            _addLoreEvent(newWeaverId, "Mint", string(abi.encodePacked("Created by bonding #", Strings.toString(_weaver1Id), " and #", Strings.toString(_weaver2Id))));
            _addLoreEvent(_weaver1Id, "Bond", string(abi.encodePacked("Bonded with #", Strings.toString(_weaver2Id), ", created new Weaver #", Strings.toString(newWeaverId))));
            _addLoreEvent(_weaver2Id, "Bond", string(abi.encodePacked("Bonded with #", Strings.toString(_weaver1Id), ", created new Weaver #", Strings.toString(newWeaverId))));

            emit WeaverBonded(newWeaverId, _weaver1Id, _weaver2Id);
        } else {
            // Failure: No new Weaver, but Chronos is still consumed.
            _addLoreEvent(_weaver1Id, "BondAttempt", string(abi.encodePacked("Failed to bond with #", Strings.toString(_weaver2Id))));
            _addLoreEvent(_weaver2Id, "BondAttempt", string(abi.encodePacked("Failed to bond with #", Strings.toString(_weaver1Id))));
            // Optionally, penalize or reduce stats slightly on failure, or refund partial Chronos.
        }
    }

    /// @notice Changes a Weaver's elemental affinity (e.g., Fire, Water, Aether) at a Chronos cost.
    /// @param _tokenId The ID of the ChronoWeaver to attune.
    /// @param _newAffinity The new affinity value (0-5).
    function attuneWeaver(uint256 _tokenId, uint8 _newAffinity) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverAttunement)], "ChronoWeaver: Attunement is currently disabled.");
        require(_newAffinity <= 5, "ChronoWeaver: Invalid affinity value (0-5 required)"); // 0 is "None"

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        require(!essence.isTemporallyLocked, "ChronoWeaver: Weaver is temporally locked.");
        require(essence.affinity != _newAffinity, "ChronoWeaver: Weaver already has this affinity");
        
        uint256 cost = environmentalFactors[uint8(ParameterType.AttunementCost)];
        require(balanceOf(msg.sender) >= cost, "ChronoWeaver: Insufficient Chronos for attunement");
        _transfer(msg.sender, address(this), cost); // Transfer Chronos

        uint8 oldAffinity = essence.affinity;
        essence.affinity = _newAffinity;
        
        _addLoreEvent(_tokenId, "Attune", string(abi.encodePacked("Affinity changed from ", Strings.toString(oldAffinity), " to ", Strings.toString(_newAffinity))));
        emit WeaverAttuned(_tokenId, oldAffinity, _newAffinity);
    }

    /// @notice Places a Weaver in a "temporal lock," pausing its decay and evolution for a specified period.
    /// @param _tokenId The ID of the ChronoWeaver to lock.
    /// @param _lockDuration The duration in blocks for which the Weaver will be locked.
    function initiateTemporalLock(uint256 _tokenId, uint256 _lockDuration) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverTemporalLock)], "ChronoWeaver: Temporal Lock is currently disabled.");
        require(_lockDuration > 0, "ChronoWeaver: Lock duration must be positive");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        require(!essence.isTemporallyLocked, "ChronoWeaver: Weaver is already temporally locked.");

        uint256 cost = environmentalFactors[uint8(ParameterType.TemporalLockCost)];
        require(balanceOf(msg.sender) >= cost, "ChronoWeaver: Insufficient Chronos for temporal lock");
        _transfer(msg.sender, address(this), cost); // Transfer Chronos

        essence.isTemporallyLocked = true;
        essence.temporalLockUntil = block.number.add(_lockDuration);
        
        _addLoreEvent(_tokenId, "TemporalLock", string(abi.encodePacked("Locked until block ", Strings.toString(essence.temporalLockUntil))));
        emit WeaverTemporalLocked(_tokenId, essence.temporalLockUntil);
    }

    /// @notice Allows a Weaver owner to "disperse" (burn) their Weaver, reclaiming a portion of its essence as Chronos.
    /// @param _tokenId The ID of the ChronoWeaver to disperse.
    function disperseEssence(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverDispersal)], "ChronoWeaver: Dispersal is currently disabled.");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        
        // Calculate refund based on essence values and a refund rate
        uint256 baseValuePerStatPoint = 1 ether; // 1 CHRONOS per stat point for calculation
        uint256 totalStatPoints = uint256(essence.stability).add(essence.agility).add(essence.creativity).add(essence.resonance);
        uint256 potentialRefund = totalStatPoints.mul(baseValuePerStatPoint);

        uint256 refundRate = environmentalFactors[uint8(ParameterType.DispersalRefundRate)]; // Percentage (0-100)
        uint256 actualRefund = potentialRefund.mul(refundRate).div(100);

        _addLoreEvent(_tokenId, "Disperse", string(abi.encodePacked("Essence dispersed, ", Strings.toString(actualRefund), " Chronos refunded.")));
        _burn(_tokenId); // Burn the NFT
        _mint(msg.sender, actualRefund); // Mint and refund Chronos to the user

        emit WeaverEssenceDispersed(_tokenId, msg.sender, actualRefund);
    }

    /// @notice Retrieves the parent Weaver IDs for a given Weaver, if it was created via bonding.
    /// @param _tokenId The ID of the ChronoWeaver.
    /// @return parent1 The ID of the first parent Weaver (0 if none).
    /// @return parent2 The ID of the second parent Weaver (0 if none).
    function getWeaverLineage(uint256 _tokenId) public view returns (uint256 parent1, uint256 parent2) {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        return (essence.lineageParent1, essence.lineageParent2);
    }

    /// @notice Returns a history of significant events that have occurred to a specific Weaver.
    /// @param _tokenId The ID of the ChronoWeaver.
    /// @return An array of WeaverLoreEvent structs.
    function queryWeaverLore(uint256 _tokenId) public view returns (WeaverLoreEvent[] memory) {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        return weaverLore[_tokenId];
    }

    /// @notice Allows anyone to trigger the decay process for a neglected Weaver, reducing its stats
    ///         and rewarding the caller a small amount of Chronos. This incentivizes maintenance.
    /// @param _tokenId The ID of the ChronoWeaver to decay.
    function decayWeaver(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverDecay)], "ChronoWeaver: Weaver Decay is currently disabled.");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        require(!essence.isTemporallyLocked, "ChronoWeaver: Weaver is temporally locked.");
        
        uint256 blocksSinceSustained = block.number.sub(essence.lastSustainedBlock);
        uint256 decayThreshold = environmentalFactors[uint8(ParameterType.DecayThreshold)];
        require(blocksSinceSustained > decayThreshold, "ChronoWeaver: Weaver not due for decay");

        _applyDecay(_tokenId);

        // Reward the caller for triggering decay (a small amount of Chronos)
        uint256 rewardAmount = 1 ether; // 1 Chronos
        if (balanceOf(address(this)) >= rewardAmount) {
            _transfer(address(this), msg.sender, rewardAmount);
        } else {
             // If contract doesn't have enough from fees, it means it's not self-sustaining for rewards.
             // In a more complex system, this might mint new tokens or draw from a separate fund.
             // For this example, we proceed without reward if funds are low.
        }

        emit WeaverDecayed(_tokenId, msg.sender, essence.stability);
    }

    /// @notice Allows a Weaver's owner to claim passively generated Chronos by their Weaver.
    /// @param _tokenId The ID of the ChronoWeaver.
    function claimChronos(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "ChronoWeaver: non-existent token");
        require(ownerOf(_tokenId) == msg.sender, "ChronoWeaver: not owner");
        require(globalFeaturesEnabled[uint8(GlobalFeature.WeaverChronosGeneration)], "ChronoWeaver: Chronos generation is currently disabled.");

        ChronoWeaverEssence storage essence = weaverEssences[_tokenId];
        uint256 blocksSinceLastClaim = block.number.sub(essence.lastChronosClaimBlock);
        
        if (blocksSinceLastClaim == 0) return; // Already claimed in this block or no time passed

        uint256 generationRatePerResonance = environmentalFactors[uint8(ParameterType.ChronosGenerationRate)]; // Per block per unit of resonance
        uint256 amountToMint = blocksSinceLastClaim.mul(generationRatePerResonance).mul(essence.resonance).div(100); // Normalize resonance by 100

        if (amountToMint > 0) {
            _mint(msg.sender, amountToMint);
            essence.lastChronosClaimBlock = block.number;
            essence.accumulatedExperience = essence.accumulatedExperience.add(blocksSinceLastClaim); // Gain experience from passive generation
            emit ChronosClaimed(_tokenId, msg.sender, amountToMint);
        }
    }

    // --- Chronos Token (ERC20) Management ---
    // ERC20 functions (transfer, approve, transferFrom, balanceOf, totalSupply) are inherited.

    /// @notice (Admin only) Mints initial Chronos supply to a specific address.
    /// @param _to The recipient address.
    /// @param _amount The amount of Chronos to mint.
    function mintInitialChronos(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // --- Governance & Ecosystem Parameters ---

    /// @notice (Admin/Oracle) Updates a global environmental parameter that affects Weaver behavior or costs.
    /// This function is intended for direct admin control over non-governance-critical parameters.
    /// For changes to parameters like vote duration or quorum, a governance proposal is required.
    /// @param _factorType The type of parameter to update (from ParameterType enum).
    /// @param _newValue The new value for the parameter.
    function updateEnvironmentalFactor(uint8 _factorType, uint256 _newValue) public onlyOwner whenNotPaused {
        require(_factorType < uint8(ParameterType.ProposalVoteDuration), "ChronoWeaver: Can only update basic environmental factors directly. Governance parameters require proposals.");
        environmentalFactors[_factorType] = _newValue;
        emit EnvironmentalFactorUpdated(_factorType, _newValue);
    }

    /// @notice Allows Nexus Pool stakers to propose changes to core ecosystem parameters.
    /// The proposal covers a parameter type and a new value.
    /// @param _description A description of the proposal.
    /// @param _paramType The type of parameter to change.
    /// @param _newValue The proposed new value.
    function proposeParameterChange(string memory _description, uint8 _paramType, uint256 _newValue) public whenNotPaused {
        require(nexusStakes[msg.sender] > 0, "ChronoWeaver: Must have Chronos staked in Nexus Pool to propose.");
        // Prevent direct proposal of governance-related parameters to avoid reentrancy/locking issues
        require(_paramType < uint8(ParameterType.ProposalVoteDuration), "ChronoWeaver: Only core parameters can be proposed for change via this function.");

        uint256 proposalId = nextProposalId;
        nextProposalId = nextProposalId.add(1);

        proposals[proposalId] = Proposal({
            description: _description,
            paramType: _paramType,
            newValue: _newValue,
            voteStartTime: block.number,
            voteEndTime: block.number.add(environmentalFactors[uint8(ParameterType.ProposalVoteDuration)]),
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });
        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /// @notice Allows Nexus Pool stakers to vote on active proposals.
    /// Voting power is based on the amount of Chronos staked in the Nexus Pool.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "ChronoWeaver: Proposal does not exist.");
        require(block.number >= proposal.voteStartTime && block.number <= proposal.voteEndTime, "ChronoWeaver: Voting period is not active.");
        require(!proposal.hasVoted[msg.sender], "ChronoWeaver: Already voted on this proposal.");
        require(nexusStakes[msg.sender] > 0, "ChronoWeaver: Must have Chronos staked in Nexus Pool to vote.");

        uint256 votePower = nexusStakes[msg.sender];
        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votePower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votePower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support, votePower);
    }

    /// @notice Executes a successfully voted-on proposal, applying the proposed parameter change.
    /// Requires that the voting period has ended, a quorum is met, and a majority voted 'yes'.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "ChronoWeaver: Proposal does not exist.");
        require(block.number > proposal.voteEndTime, "ChronoWeaver: Voting period has not ended.");
        require(!proposal.executed, "ChronoWeaver: Proposal already executed.");

        // Check quorum and majority
        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
        uint256 quorumThreshold = totalNexusStake.mul(environmentalFactors[uint8(ParameterType.ProposalQuorumRate)]).div(100);
        require(totalVotes >= quorumThreshold, "ChronoWeaver: Proposal did not meet quorum.");
        require(proposal.yesVotes > proposal.noVotes, "ChronoWeaver: Proposal did not pass by majority.");

        environmentalFactors[proposal.paramType] = proposal.newValue;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId);
        emit EnvironmentalFactorUpdated(proposal.paramType, proposal.newValue);
    }

    /// @notice (Admin/Governance) Sets the Chronos cost required for a Weaver to evolve.
    /// This is an example of an admin function that could also be part of governance.
    /// @param _cost The new evolution cost.
    function setEvolutionCost(uint256 _cost) public onlyOwner {
        environmentalFactors[uint8(ParameterType.EvolutionCost)] = _cost;
        emit EnvironmentalFactorUpdated(uint8(ParameterType.EvolutionCost), _cost);
    }

    /// @notice (Admin/Governance) Sets the Chronos cost and success probability for Weaver bonding.
    /// @param _cost The new bonding cost.
    /// @param _successRate The new success rate (0-100).
    function setBondingParameters(uint256 _cost, uint256 _successRate) public onlyOwner {
        require(_successRate <= 100, "ChronoWeaver: Success rate cannot exceed 100");
        environmentalFactors[uint8(ParameterType.BondingCost)] = _cost;
        environmentalFactors[uint8(ParameterType.BondingSuccessRate)] = _successRate;
        emit EnvironmentalFactorUpdated(uint8(ParameterType.BondingCost), _cost);
        emit EnvironmentalFactorUpdated(uint8(ParameterType.BondingSuccessRate), _successRate);
    }

    /// @notice (Admin/Governance) Enables or disables specific global features.
    /// @param _featureIndex The index of the feature (from GlobalFeature enum).
    /// @param _enabled True to enable, false to disable.
    function toggleGlobalFeature(uint8 _featureIndex, bool _enabled) public onlyOwner {
        require(_featureIndex <= uint8(GlobalFeature.WeaverChronosGeneration), "ChronoWeaver: Invalid feature index.");
        globalFeaturesEnabled[_featureIndex] = _enabled;
        emit GlobalFeatureToggled(_featureIndex, _enabled);
    }

    // --- Nexus Pool (Staking & Rewards) ---

    /// @notice Allows users to stake Chronos tokens into the Nexus Pool to gain voting power and earn rewards.
    /// Users' pending rewards are claimed automatically before stake is updated.
    /// @param _amount The amount of Chronos to stake.
    function contributeToNexusPool(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "ChronoWeaver: Amount must be greater than zero.");
        require(balanceOf(msg.sender) >= _amount, "ChronoWeaver: Insufficient Chronos balance.");

        claimNexusPoolRewards(); // Claim pending rewards before updating stake

        _transfer(msg.sender, address(this), _amount); // Transfer Chronos from user to contract

        nexusStakes[msg.sender] = nexusStakes[msg.sender].add(_amount);
        totalNexusStake = totalNexusStake.add(_amount);
        lastRewardClaimBlock[msg.sender] = block.number; // Update last claim block to current

        emit NexusContributed(msg.sender, _amount);
    }

    /// @notice Allows stakers to claim their accrued Chronos rewards from the Nexus Pool.
    /// Rewards are calculated based on the user's stake, time, and the total accumulated rewards.
    function claimNexusPoolRewards() public whenNotPaused {
        uint256 userStake = nexusStakes[msg.sender];
        if (userStake == 0) return;

        uint256 blocksSinceLastClaim = block.number.sub(lastRewardClaimBlock[msg.sender]);
        if (blocksSinceLastClaim == 0) return; // Already claimed in this block or no time passed

        uint256 rewardRate = environmentalFactors[uint8(ParameterType.NexusPoolRewardRate)]; // per block per ether staked
        
        // Calculate potential rewards based on user's share of total stake and reward rate
        // This distributes a portion of `nexusPoolRewardsAccrued` based on the user's proportional stake over time.
        // A more complex real system would need to ensure `nexusPoolRewardsAccrued` is dynamically topped up.
        uint256 potentialRewards = userStake.mul(blocksSinceLastClaim).mul(rewardRate).div(1 ether); // Normalize for 1 ether base unit

        if (potentialRewards > nexusPoolRewardsAccrued) { // Cap rewards to what's available in the pool
            potentialRewards = nexusPoolRewardsAccrued;
        }

        if (potentialRewards > 0) {
            nexusPoolRewardsAccrued = nexusPoolRewardsAccrued.sub(potentialRewards); // Deduct from pool
            _transfer(address(this), msg.sender, potentialRewards); // Transfer from contract to user
            emit NexusRewardsClaimed(msg.sender, potentialRewards);
        }
        lastRewardClaimBlock[msg.sender] = block.number; // Update last claim block
    }

    /// @notice Allows stakers to withdraw their staked Chronos from the Nexus Pool.
    /// Any pending rewards are automatically claimed before withdrawal.
    /// @param _amount The amount of Chronos to withdraw.
    function withdrawFromNexusPool(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "ChronoWeaver: Amount must be greater than zero.");
        require(nexusStakes[msg.sender] >= _amount, "ChronoWeaver: Insufficient staked Chronos.");

        claimNexusPoolRewards(); // Claim pending rewards before withdrawal

        nexusStakes[msg.sender] = nexusStakes[msg.sender].sub(_amount);
        totalNexusStake = totalNexusStake.sub(_amount);
        _transfer(address(this), msg.sender, _amount); // Transfer Chronos from contract to user

        emit NexusWithdrawn(msg.sender, _amount);
    }

    // --- System & Utility ---

    /// @notice Provides a quick overview of global ecosystem statistics.
    /// @return totalWeavers The total number of ChronoWeaver NFTs minted.
    /// @return totalChronosSupply The total supply of Chronos tokens.
    /// @return nexusPoolBalance The total Chronos staked in the Nexus Pool.
    function getSystemMetrics() public view returns (uint256 totalWeavers, uint256 totalChronosSupply, uint256 nexusPoolBalance) {
        return (totalSupply(), _totalSupply(), totalNexusStake);
    }

    // --- Pausable Overrides ---

    /// @notice Pauses critical contract functionalities. Only callable by the contract owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses critical contract functionalities. Only callable by the contract owner.
    function unpause() public onlyOwner {
        _unpause();
    }
}
```